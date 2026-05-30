# HYPOTHESIS — askeladd — Aux Adam β₁ INCREASE pulse synchronous with β₂ pulse @ step 975

**Branch:** `g1r1-askeladd/aux-adam-b1-joint-pulse`
**Assigned:** 2026-05-30 11:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state regime shift at phase boundaries + (c) short phase-specific mechanism + (d) momentum state handling

## Why this hypothesis

The canonical β₂ pulse 0.95→0.99 at step 975 is a CONFIRMED WIN (#1532). The mechanism: at cooldown onset, the variance estimator switches to a longer-memory regime, stabilizing the adaptive denominator through the cooldown.

But Adam's two moment estimators (m, v) are tightly coupled — the update is `m / (sqrt(v) + ε)`. The β₂ pulse changes how v accumulates, but m continues under its old β₁=0.8. This **asymmetric regime shift** means the m and v estimators run at structurally different timescales post-pulse.

The hypothesis: a **synchronous β₁ pulse** at the same step would make BOTH moment estimators jump to longer-memory regimes simultaneously. Both estimators then accumulate gradient information at compatible timescales through the cooldown, potentially compounding the #1532 WIN.

**Mechanistic reasoning:**
- At step 975, post-warmup, the gradient distribution shifts (cooldown LR begins decaying, paramEMA active). The "old" β₁=0.8 estimator has ~5-step effective horizon; β₂=0.99 post-pulse has ~100-step horizon.
- An update `m / sqrt(v)` computed with mismatched timescales mixes a high-noise direction estimate (short-horizon m) with a low-noise magnitude estimate (long-horizon v). The denominator is well-conditioned but the numerator carries warmup-regime noise into cooldown.
- A β₁ pulse synchronizes the timescales: m's horizon extends ~6× (0.8 → 0.95 takes m from ~5 to ~20 step horizon) or ~9× (0.8 → 0.9 takes m to ~10), making the direction estimate compatible with the post-pulse v denominator.

**Why distinct from prior β₁ work:**
- #1592/#1639 (askeladd's prior closures) tested **body Muon β₁** at pre-target window — this is **aux AdamW β₁** at cooldown onset (different optimizer, different boundary, different mechanism).
- nezuko #1770 (closed) tested aux Adam m+v ZERO reset (state discard), not a pulse (regime change).
- nezuko #1815 (running) tests m-only zero reset / v partial decay (asymmetric state interventions, not regime shifts).
- This PR is the only synchronous-β-pulse test on aux AdamW at the cooldown-onset boundary.

**Coverage gap closure:** if WIN, this compounds the #1532 WIN — both moment estimators' phase-boundary regime shifts confirmed load-bearing. If NULL, aux Adam moment-regime synchronization is closed (a fundamental coupling result).

## Distinct from in-flight assignments

- **nezuko #1815** (m-only reset, v partial decay @ 975): different mechanism (state intervention, not regime shift); orthogonal — could compound if both WIN
- **thorfinn #1797** (body PMuon momentum SCALE @ 975): different optimizer (PMuon)
- **frieren #1780** (L/R cov ZERO @ 975): different optimizer, different state
- **tanjiro #1787** (aux Adam eps pulse @ 975): denominator floor from the other side
- **edward #1785** (aux Adam block-wise AdaShift): different mechanism (per-tensor v_t)

## Experiment design

**Bilateral on β₁ pulse magnitude (cooldown-onset boundary fixed at step 975):**

- **Arm A — β₁ pulse 0.8 → 0.9** (modest jump, m horizon ~5 → ~10 steps). Tests whether a partial synchronization captures the compounding benefit.
- **Arm B — β₁ pulse 0.8 → 0.95** (aggressive jump, m horizon ~5 → ~20 steps, matches body PMuon μ=0.95). Tests whether full synchronization with the body-side momentum scale is the load-bearing shift.

Both arms fire at step 975, on top of the existing β₂ pulse 0.95→0.99. The β₁ pulse is a permanent step-change (held to terminal), same shape as the canonical β₂ pulse. **Implementation: change the optimizer's β₁ at step 975, not the m state — the state carries forward at the new rate.**

## Implementation guidance

Add CLI flags to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_b1_pulse_step", type=int, default=-1,
    help="Step at which to apply aux Adam β₁ pulse (-1 = disabled)",
)
parser.add_argument(
    "--aux_b1_pulse_target", type=float, default=0.0,
    help="Target β₁ value after pulse (0.0 = unused; 0.9 or 0.95 for production)",
)
```

In the training loop, immediately AFTER the existing `aux_b2_pulse` block and BEFORE `optimizer1.step()`:

```python
if (args.aux_b1_pulse_step > 0
        and step == args.aux_b1_pulse_step):
    n_groups = 0
    old_b1s = []
    for group in optimizer1.param_groups:
        old_b1 = group["betas"][0]
        old_b1s.append(old_b1)
        # AdamW expects betas as a tuple
        group["betas"] = (args.aux_b1_pulse_target, group["betas"][1])
        n_groups += 1
    if dist.get_rank() == 0:
        print0(f"[step {step}] aux Adam β₁ PULSE "
               f"target={args.aux_b1_pulse_target:.4f} "
               f"(applied to {n_groups} param groups, prior values={old_b1s})",
               console=True)
        if wandb.run is not None:
            wandb.log({
                "aux_b1_pulse/step": step,
                "aux_b1_pulse/target": args.aux_b1_pulse_target,
                "aux_b1_pulse/n_groups": n_groups,
            }, step=step)
```

**Critical:** the β₁ pulse changes the GROUP'S β₁ parameter (controlling future m updates), NOT the m state itself. The accumulated m carries forward seamlessly; only the EMA decay rate changes from step 975 onward.

## Reproduce commands

**Arm A (β₁ pulse 0.8 → 0.9 @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_b1_pulse_step 975 --aux_b1_pulse_target 0.9 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-aux-adam-b1-joint-pulse \
  --wandb_name g1r1-askeladd/b1-pulse-0.9-armA
```

**Arm B (β₁ pulse 0.8 → 0.95 @ 975):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_b1_pulse_step 975 --aux_b1_pulse_target 0.95 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-askeladd-aux-adam-b1-joint-pulse \
  --wandb_name g1r1-askeladd/b1-pulse-0.95-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before launching the full bilateral, run a 100-step smoke test with `--aux_b1_pulse_step 50 --aux_b1_pulse_target 0.9`:

1. Sentinel `[step 50] aux Adam β₁ PULSE target=0.9000 (applied to N param groups, prior values=[0.8, ...])` appears (N=number of optimizer1 groups, typically 4)
2. Train_loss continues monotone immediately after step 50 (no spike >0.5 mnat — Adam β changes should be essentially silent at the step boundary)
3. W&B summary has `aux_b1_pulse/target=0.9`
4. (Optional) Sentinel logging `optimizer1.param_groups[0]["betas"][0]` should show 0.8 at step ≤ 49 and 0.9 at step ≥ 50.

If train_loss spikes >0.5 mnat at the smoke-test pulse step, investigate before launching production — Adam β changes should NOT produce visible loss discontinuities.

## Anti-patterns

- **Do NOT touch the β₂ pulse** — `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99` MUST be present in both arms; the joint pulse only works when β₂ is also being pulsed.
- **Do NOT zero or scale the m state** — nezuko #1815 owns that mechanism. This PR changes the β₁ HYPERPARAMETER only, not the state.
- **Do NOT change the firing step from 975** — synchronous with β₂ pulse is the entire mechanism.
- **Do NOT pulse β₁ to >0.95** — that crosses into territory where the m accumulation becomes too slow for the cooldown's rapid LR decay, and the m direction estimate becomes stale.
- **Do NOT modify body Muon β₁ or μ** — different optimizer; #1592/#1639 already closed that axis.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate (β₁=0.9)** | Modest synchronization is the WIN; request seed-2 confirmation. Validates the β₁/β₂ joint pulse mechanism. |
| **Arm B WIN merge gate (β₁=0.95)** | Aggressive synchronization is the WIN. Request seed-2. Follow-up: test β₁=0.99 (matching β₂). |
| **Both NULL, similar trajectory** | Asymmetric β₁/β₂ timescales were not the bottleneck; aux Adam moment-regime synchronization CLOSED. Confirms #1532's β₂-only pulse is structurally optimal. |
| **Arm A NULL near-baseline, Arm B WIN** | The mechanism scales with synchronization strength; depth study warranted. |
| **Either arm crashes/diverges** | Cooldown trajectory is destabilized by sudden m-horizon extension; investigate (unlikely given how silent β-changes usually are). |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```

Post a brief milestone comment when Arm A passes step ~975 (so we can confirm the pulse fired) and at ~50%/80% of Arm B to keep the harness from flagging stale_wip.
