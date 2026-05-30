# HYPOTHESIS — alphonse — Body PMuon momentum buffer SCALE at PRE-TARGET boundary step 2750

**Branch:** `g1r1-alphonse/pretarget-momentum-scale`
**Assigned:** 2026-05-30 14:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state rescaling at phase boundary + (c) short phase-specific mechanism + (d) momentum state handling

## Why this hypothesis

thorfinn #1797 tested body PMuon momentum buffer SCALE at COOLDOWN ONSET (step 975) — Arm A (×0.5) close-miss NULL sr=2925 (+0.246 mnat). The mechanism — momentum rescaling — produced a tight close-miss signal. But step 975 is structurally early in cooldown: momentum carries warmup-regime velocity which is mostly noise.

This PR tests the SAME mechanism (momentum buffer scale) at the **PRE-TARGET boundary step 2750**, where the momentum state is structurally different:
- pEMA refresh has fired at step 2600 (paramEMA reset to current weights)
- 1775 steps of cooldown LR decay have elapsed
- Momentum carries late-cooldown velocity which is structurally informed by stable cooldown gradient statistics
- Step 2750 is exactly 125 steps before the sr=2875 target-crossing window

**nezuko #1726 (CLOSED) tested cov-state (L_cov/R_cov) zero reset at step 2750** — bilateral NULL but Arm B was sr=2875 +1.07 mnat above gate (CLOSE-MISS). The pre-target boundary appears to be a structurally responsive state-intervention timing. This PR tests whether the close-miss pattern transfers from PRECONDITIONER state (cov) to MOMENTUM state at the same boundary.

**Mechanistic reasoning:**
- thorfinn #1797 @975: momentum buffer carries ~975 steps of warmup gradient memory. ×0.5 halves a buffer dominated by warmup-regime statistics. Discarding most of that should help, but at 975 the gradient distribution is still shifting (cooldown JUST started); the scaled momentum has no time to re-fill with cooldown gradients before passing through.
- This PR @2750: momentum buffer is mostly late-cooldown velocity. ×0.5 halves a well-informed late-cooldown momentum just before the target window. Effective late-cooldown LR drops (smaller momentum → smaller effective step). This is "pre-target velocity attenuation" — slowing the final approach to target may sharpen the descent.
- An alternative read: momentum at 2750 is already small (cooldown LR has decayed); halving it reduces a small quantity, modest effect. The signal lives in whether the small attenuation crosses a useful threshold.

## Distinct from in-flight and closed work

- **thorfinn #1797** (running): momentum SCALE @ step 975 — DIFFERENT boundary (cooldown onset vs pre-target)
- **askeladd #1730** (CLOSED): momentum hard ZERO RESET @ step 2750 — Arm A CRASHED, Arm B sr=2925 +3.70 mnat NULL. ZERO is too aggressive at this boundary; **partial scaling** is the untested primitive at this boundary.
- **nezuko #1726** (CLOSED): cov-state RESET @ step 2750 — close-miss Arm B sr=2875 +1.07 mnat. Different state (cov, not momentum). Mechanism for "why 2750 boundary matters" potentially transfers.
- **frieren #1780** (HOT, seed-2 pending): cov-state reset @ step 1100 — DIFFERENT boundary, DIFFERENT state.

## Experiment design

**Bilateral on SCALE FACTOR (boundary fixed at step 2750):**

- **Arm A — momentum buffer ×0.5 @ step 2750** (mild attenuation). Matches thorfinn's ×0.5 magnitude at this different phase boundary.
- **Arm B — momentum buffer ×0.25 @ step 2750** (aggressive attenuation). Tests stronger scaling.

Both arms preserve canonical β₂ pulse @ 975 and pEMA refresh @ 2600.

## Implementation guidance

If thorfinn #1797 added a flag like `--body_muon_momentum_scale_step` and `--body_muon_momentum_scale_factor`, **REUSE that flag** — only the firing step differs. If the flag doesn't exist, add:

```python
parser.add_argument(
    "--body_muon_momentum_scale_step", type=int, default=-1,
    help="Step at which to scale body PMuon momentum buffer (-1 = disabled)",
)
parser.add_argument(
    "--body_muon_momentum_scale_factor", type=float, default=1.0,
    help="Multiplicative factor for body PMuon momentum buffer at the pulse step",
)
```

In the training loop, AFTER `aux_b2_pulse` block, BEFORE `optimizer2.step()`:

```python
if (args.body_muon_momentum_scale_step > 0
        and step == args.body_muon_momentum_scale_step):
    n_scaled = 0
    for group in optimizer2.param_groups:
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is None:
                continue
            if "momentum" in state:
                state["momentum"].mul_(args.body_muon_momentum_scale_factor)
                n_scaled += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] body PMuon momentum SCALE "
               f"factor={args.body_muon_momentum_scale_factor:.4f} "
               f"(scaled {n_scaled} momentum tensors)", console=True)
        if wandb.run is not None:
            wandb.log({
                "body_momentum_scale/step": step,
                "body_momentum_scale/factor": args.body_muon_momentum_scale_factor,
                "body_momentum_scale/n_scaled": n_scaled,
            }, step=step)
```

This is the identical reset path thorfinn #1797 used — only the firing step + factor combinations differ. thorfinn's smoke confirmed 72 momentum tensors get scaled.

## Reproduce commands

**Arm A (×0.5 @ step 2750):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_scale_step 2750 --body_muon_momentum_scale_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-pretarget-momentum-scale \
  --wandb_name g1r1-alphonse/pretarget-mom-scale-0.5-armA
```

**Arm B (×0.25 @ step 2750):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_scale_step 2750 --body_muon_momentum_scale_factor 0.25 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-alphonse-pretarget-momentum-scale \
  --wandb_name g1r1-alphonse/pretarget-mom-scale-0.25-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Validation checklist

Smoke test with `--body_muon_momentum_scale_step 50 --body_muon_momentum_scale_factor 0.5` (100 steps):

1. Sentinel `[step 50] body PMuon momentum SCALE factor=0.5000 (scaled 72 momentum tensors)` fires once (72 tensors matches thorfinn #1797).
2. Train_loss continues monotone within ±0.5 mnat (momentum scaling is gentle).

## Anti-patterns

- **Do NOT change firing step from 2750** — pre-target boundary is the mechanism
- **Do NOT touch β₂ pulse, paramEMA refresh, or any other in-flight flags** — preserve all canonical interventions
- **Do NOT modify the cov state (L/R)** — that's frieren #1780's territory
- **Do NOT apply at step 975** — that's thorfinn #1797's territory
- **Do NOT zero the momentum** — askeladd #1730 already closed that. Partial scaling is the untested primitive.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (×0.5)** | Pre-target momentum attenuation is load-bearing; seed-2 confirm; orthogonal-to-thorfinn signal would suggest momentum scale at BOTH 975 + 2750 may compound. |
| **Arm B WIN merge gate (×0.25)** | Aggressive pre-target attenuation breaks the gate. Request seed-2; mechanism preferred deeper attenuation at this phase. |
| **Both NULL but close-miss (sr=2875 or 2925 with val_ema near 3.262854)** | Pre-target boundary IS responsive but momentum scaling doesn't quite cross. Frame as partial signal; close axis as bilateral close-miss. |
| **Both NULL deep (sr ≥ 2950)** | Momentum at 2750 is load-bearing; full or partial scaling at this boundary is destructive. Momentum SCALE axis CLOSED across both 975 (thorfinn #1797) + 2750 (this PR). |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
