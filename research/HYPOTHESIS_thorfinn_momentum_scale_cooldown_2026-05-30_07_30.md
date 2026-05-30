# HYPOTHESIS — thorfinn — Body PMuon momentum buffer SCALE (partial fade) at cooldown onset step 975

**Branch:** `g1r1-thorfinn/muon-momentum-scale-cooldown`
**Assigned:** 2026-05-30 07:30 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries + (d) momentum/preconditioner state handling

## Why this hypothesis

Directive #1252 (a) specifies "optimizer-state resets/rescaling at phase boundaries". The **reset** half of this primitive (multiply by 0) has been heavily tested and definitively closed for body PMuon momentum:

- askeladd #1730 (CLOSED): body Muon momentum ZERO reset at pre-target step 2750 — Arm A CRASHED (destabilizing during late descent), Arm B NULL sr=2925 +3.70 mnat

The **rescaling** half (multiply by α ∈ (0, 1)) has NOT been tested. This is the mechanistically distinct primitive in the same directive.

**Mechanism hypothesis:** At step 975 — coincident with the β₂ pulse boundary (#1532 WIN), the canonical EMA warmup end, and the cooldown onset — three regime shifts happen simultaneously. The body PMuon momentum buffer accumulated during warmup encodes the gradient signal under conditions that no longer hold post-step-975:

- Warmup regime: high LR, low EMA β, "thin" L_cov/R_cov (still accumulating)
- Cooldown regime: declining LR, high EMA β, mature L_cov/R_cov (full memory horizon)

The momentum buffer at step 975 retains direction information that's still useful (the optimization manifold doesn't relocate at a phase boundary) but the **magnitude** is calibrated for warmup-regime LRs, not cooldown-regime LRs. **Partial fade preserves direction while letting the cooldown-regime gradients re-calibrate magnitude.**

**Why scaling, not resetting:**
- Zero reset at the SAME boundary (step 975) for L_cov/R_cov is frieren #1780 (in-flight) — covariance EMA buffers have NO direction content so zero is fine
- Zero reset for body Muon momentum at pre-target failed (#1730) — direction discard at late-cooldown is destructive
- At cooldown onset (step 975), the cooldown trajectory is just starting — there's MORE recovery time to re-converge than at pre-target. But the direction signal accumulated during warmup is still useful, so partial fade is safer than zero
- Partial fade ∈ (0.25, 0.5) is the structurally untested middle ground

**Why distinct from in-flight assignments:**
- frieren #1780: L_cov/R_cov ZERO reset at step 975 — DIFFERENT buffer (covariance EMA, not velocity momentum)
- nezuko #1770: aux Adam m/v ZERO reset at step 975 — DIFFERENT optimizer (aux AdamW, not body PMuon)
- alphonse #1788: per-block μ depth-asymmetric — momentum DECAY rate variation, not magnitude SCALING at a boundary
- askeladd #1773: paramEMA β step-drop at pre-target — different buffer entirely (pEMA inference weights, not optimizer momentum)
- This thorfinn assignment: body PMuon momentum SCALING (partial fade) at cooldown onset

**Untested in 329-PR history.** Body PMuon momentum buffer has only been touched as: (1) ZERO reset at pre-target (#1730, closed) and (2) constant μ tuning (closed bilateral on uniform μ shifts). Magnitude scaling at the cooldown-onset boundary is a structurally fresh axis.

## Experiment design

**Bilateral comparison on scale magnitude (cooldown-onset boundary fixed at step 975):**

- **Arm A — scale by 0.5** (moderate fade — 50% of warmup-accumulated velocity preserved). Tests whether mild warmup-history discounting yields a cleaner cooldown start.
- **Arm B — scale by 0.25** (aggressive fade — 25% of velocity preserved). Tests whether stronger fade compounds the directional preservation benefit, or instead loses too much signal.

Both arms fire ONCE at step 975 (immediately after the β₂ pulse, BEFORE that step's PMuon update). After scaling, momentum buffer continues accumulating normally under μ=0.95.

If both fade levels NULL with sr=2925, this closes the body PMuon momentum SCALING axis — combined with the ZERO RESET closure at pre-target (#1730), body Muon velocity-buffer state-handling at phase boundaries would be fully closed.

If Arm A WINS and Arm B doesn't, request seed-2 of Arm A. If Arm B is interesting but doesn't WIN, follow-up bilateral with α ∈ {0.1, 0.75}.

## Implementation guidance

Add CLI flag to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--body_muon_momentum_scale_step", type=int, default=-1,
    help="Step at which to scale body Muon momentum buffer (-1 = disabled)",
)
parser.add_argument(
    "--body_muon_momentum_scale_factor", type=float, default=1.0,
    help="Multiplicative factor applied to optimizer2 momentum at scale step (1.0 = no-op)",
)
```

In the training loop, BEFORE `optimizer2.step()` on the firing step:

```python
if (args.body_muon_momentum_scale_step > 0
        and step == args.body_muon_momentum_scale_step):
    n_scaled = 0
    for group in optimizer2.param_groups:
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is not None and "momentum" in state:
                state["momentum"].mul_(args.body_muon_momentum_scale_factor)
                n_scaled += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon momentum SCALE "
               f"factor={args.body_muon_momentum_scale_factor:.4f} "
               f"(scaled {n_scaled} momentum tensors)", console=True)
        if wandb.run is not None:
            wandb.log({
                "body_muon_momentum_scale/step": step,
                "body_muon_momentum_scale/factor": args.body_muon_momentum_scale_factor,
                "body_muon_momentum_scale/tensors_scaled": n_scaled,
            }, step=step)
```

Note: the body Muon optimizer's per-param state holds `state["momentum"]` (see `train_gpt_simple.py:598`); this is the velocity buffer to scale. Do NOT touch `state["L"]` or `state["R"]` (those are covariance EMAs — frieren #1780 handles those).

The scale must fire BEFORE `optimizer2.step()` on that step so the scaled momentum is used for the step's bilateral whitening + polar projection. Place it immediately before the optimizer step call in the training loop.

## Reproduce commands

**Arm A (scale factor=0.5):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_scale_step 975 --body_muon_momentum_scale_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-momentum-scale-cooldown \
  --wandb_name g1r1-thorfinn/momentum-scale-0.5-armA
```

**Arm B (scale factor=0.25):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_scale_step 975 --body_muon_momentum_scale_factor 0.25 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn-momentum-scale-cooldown \
  --wandb_name g1r1-thorfinn/momentum-scale-0.25-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before launching the full bilateral, run a 100-step smoke test with `--body_muon_momentum_scale_step 50 --body_muon_momentum_scale_factor 0.5`:

1. Sentinel `[step 50] body PMuon momentum SCALE factor=0.5000 (scaled 36 momentum tensors)` appears (36 = 12 blocks × 3 PMuon params per block)
2. Train_loss continues monotone immediately after step 50 (no spike)
3. W&B summary has `body_muon_momentum_scale/factor=0.5`
4. (Optional) momentum buffer Frobenius norm drops by ~2× at step 50 then resumes natural accumulation

If train_loss spikes >0.3 mnat at step 50, the scale is destabilizing even at a non-phase-boundary step — flag this in the PR comment but proceed with the bilateral since the production step is at the phase boundary (different conditions).

## Anti-patterns

- **Do NOT zero the L/R covariance buffers** — frieren #1780 owns that primitive at the same step
- **Do NOT scale aux Adam m/v** — nezuko #1770 owns that primitive at the same step
- **Do NOT change the scale step from 975** — the hypothesis is specifically about the phase-boundary alignment with β₂ pulse + warmup end + cooldown onset
- **Do NOT extend the scale to multiple steps (ramp/decay)** — single fire at step 975 only; a multi-step rescaling becomes a μ schedule change, which is a different mechanism
- **Do NOT change `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — the scale fires ON TOP of the β₂ pulse, both at step 975

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (factor=0.5)** | Moderate momentum fade at cooldown onset is load-bearing. Request seed-2 confirmation, merge if confirmed. Validates "partial state rescaling at phase boundary" as a mechanism class distinct from full reset. |
| **Arm B WIN merge gate (factor=0.25)** | Aggressive fade dominates the mechanism. Test α=0.1 follow-up to find magnitude floor. |
| **Arm A close-miss, Arm B WIN** | The mechanism scales with fade strength. Worth a depth study on α. |
| **Both NULL with sr=2925** | Body PMuon momentum scaling at cooldown onset is not load-bearing. Combined with #1730 ZERO reset closure at pre-target, **body PMuon velocity-buffer state-handling at phase boundaries is FULLY CLOSED**. Clean axis termination. |
| **Arm B diverges/crashes** | 0.25 fade discards too much warmup signal — α floor is between 0.25 and 0.5. Falls back to Arm A signal. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
