---
student: g1r1-fern
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 18:00 UTC
directive_alignment: (a) optimizer-state at phase boundaries
---

# Hypothesis: paramEMA refresh OPERATOR alpha-blend — bilateral HALF-BLEND vs OVER-INJECT

## Background

PR #2102 just CLOSED the paramEMA refresh-step TIMING axis bilateral within `[1750, 2250]` window (both NULL with the in-window monotone gradient suggesting @2600 is a sharp local maximum). Combined with #1378 NULL @2275 and #1429 WIN @2600, the paramEMA refresh-step optimum is now firmly localized at @2600 with sharp falloff in both temporal directions.

This closes the TIMING axis but leaves the **refresh OPERATOR SHAPE** axis completely pristine. The current refresh implementation at step 2600 performs an unconditional, full-magnitude overwrite: `params.copy_(ema)`. Equivalently, with a blend factor: `params := (1 - α)·params + α·ema` with α=1.0.

**The α=1.0 choice has never been tested as a tunable parameter.** We have only ever verified that "refresh happens at step 2600" beats "refresh doesn't happen at step 2600". We have NOT verified that "full overwrite (α=1.0) is optimal over partial blend (α<1) or extrapolation (α>1)".

This is the pristine knob this hypothesis tests.

## Hypothesis

The refresh operator at step 2600 might be:
- **Over-aggressive** (α=1.0 wipes too much live training drift) → α < 1 (partial blend) should improve val_ema.
- **Under-aggressive** (α=1.0 fails to fully drag params back onto the EMA-smoothed trajectory) → α > 1 (extrapolation past EMA) should improve val_ema.
- **Robust** (α=1.0 is a flat local optimum) → bilateral NULL, axis closed.

A bilateral test pinpoints which of the three regimes the optimizer is currently in. The result has high information value regardless of outcome because every prior paramEMA mechanism has assumed unconditional full overwrite at 2600.

## Implementation

Add a single new CLI flag:
- `--paramema_refresh_alpha` (float, default `1.0`, range `[0.0, 2.0]`)

Modify the refresh operator at step `paramema_refresh_step` (currently 2600) — currently a `params.copy_(ema)` or equivalent. Replace with:

```python
# Current (equivalent to): params := ema   (α = 1.0)
# New: params := (1 - α) * params + α * ema
if args.paramema_refresh_alpha == 1.0:
    params.copy_(ema)  # preserve exact existing behavior at α=1.0
else:
    alpha = args.paramema_refresh_alpha
    params.mul_(1.0 - alpha).add_(ema, alpha=alpha)
```

This is mathematically valid for α > 1.0 (extrapolation through ema, away from current). Negative-coefficient torch ops handle this fine.

**Critical**: The default `α=1.0` MUST reproduce the existing baseline behavior bit-exactly. Verify with a smoke test that an `--paramema_refresh_alpha 1.0` run matches the baseline (#1532) trajectory within float epsilon.

Sentinel logs:
- Print at step `paramema_refresh_step`: `[step <s>] paramEMA refresh alpha=<v>: params drift before=<norm before>, after=<norm after>, ema_norm=<norm ema>`
- Log `optim/paramema_refresh_alpha` as a constant at step 0 to wandb.
- Log `optim/paramema_refresh_params_norm_before` and `optim/paramema_refresh_params_norm_after` at the refresh step.

## Arms

### Arm A — HALF BLEND (α=0.5)

Mechanism: refresh applies HALF the overwrite — params land at the midpoint between current live trajectory and EMA-smoothed trajectory. Preserves live optimizer drift; tests whether the current full-overwrite is too disruptive.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --paramema_refresh_alpha 0.5 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-fern-paramema-refresh-alpha \
  --wandb_name g1r1-fern/paramema-refresh-alpha-0.5-arm-a
```

### Arm B — OVER-INJECT (α=1.5)

Mechanism: refresh extrapolates PAST the EMA — params land 50% beyond EMA in the direction away from current live trajectory. Treats the recent live drift as something to actively REMOVE from the smoothed trajectory; tests whether α=1.0 is itself under-aggressive at scrubbing residual drift.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --paramema_refresh_alpha 1.5 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-fern-paramema-refresh-alpha \
  --wandb_name g1r1-fern/paramema-refresh-alpha-1.5-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (uses implicit α=1.0).

## Expected outcomes

- **WIN scenario (most informative):** One arm produces sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854). Mechanism interpretation:
  - Arm A WIN → α=1.0 over-corrects toward EMA; preserving some live drift helps. Follow-up: bracket α ∈ {0.25, 0.50, 0.75} to find optimum.
  - Arm B WIN → α=1.0 under-corrects; aggressive removal of live drift helps. Follow-up: bracket α ∈ {1.25, 1.50, 1.75, 2.0}.
  Either WIN is a directive (a) story — the refresh operator's strength at the phase boundary is itself a tunable lever.

- **NULL scenario:** Both arms sr ≥ 2925 with val_ema ≥ 3.263. The refresh OPERATOR at α=1.0 is robust within ±0.5 of the canonical full-overwrite point. Closes the alpha-blend axis at ±0.5 granularity. Natural follow-up: tighter granularity (α ∈ {0.75, 1.25}) only if there is an asymmetric near-miss signal between Arm A and Arm B.

- **PARTIAL scenario:** Both arms NULL but one measurably closer to baseline than the other → directional signal warrants a wider perturbation on the winning side (e.g. Arm A near-miss → try α=0.25; Arm B near-miss → try α=2.0).

## Chain rule

- Run Arm A (α=0.5, HALF BLEND) first. If clear NULL (sr ≥ 2925 with val_ema ≥ 3.265 — no near-miss), launch Arm B (α=1.5) directly.
- If Arm A WIN candidate (sr ≤ 2875 with val_ema near or below baseline), run seed-2 of Arm A first to confirm before Arm B.
- If Arm A near-miss (sr=2875 AND val_ema in [3.262854, 3.263354]), launch Arm B per schedule and request seed-2 of Arm A simultaneously if compute permits.
- Both arms terminal → post SENPAI-RESULT marker on PR with both run IDs.

## Compute budget

Standard 3250-step run × 2 arms ≈ 6h wall-clock total. Alpha-blend modification adds zero compute overhead (single scalar multiply + add at one step). Implementation is ~10 lines of code change.

## Why this aligns with the directive

Directive (a): "optimizer-state at phase boundaries." The paramEMA refresh AT step 2600 is the canonical phase boundary in the cooldown trajectory. The refresh OPERATOR is the state-mixing rule applied at that boundary. Every prior paramEMA test has implicitly assumed α=1.0 — this is the first time we expose that assumption as a tunable. A WIN here is a paper-narrative-grade finding ("the refresh operator shape matters as much as its position"). A NULL here is itself a clean closure of a pristine axis.
