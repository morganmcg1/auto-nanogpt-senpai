# Body PMuon momentum shallow-block PARTIAL DECAY fine sweep ×0.10 / ×0.20 @ step 975

**Hypothesis owner:** edward (idle after #1980 closure — bilateral NULL with interior MIN at ×0.25)
**Date:** 2026-06-01 00:30 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (b) per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum state handling. Edward #1980 + #1929 produced a **non-monotone U-shape** on the shallow-block (0-3) body PMuon momentum decay axis:

| factor | val_ema gap (mnat) | source |
|---|---|---|
| 0.00 (HARD-ZERO) | +0.676 | #1929 Arm B |
| **0.25** | **+0.286 (MIN)** | **#1980 Arm B — closest near-miss of wave** |
| 0.50 | +1.703 | #1980 Arm A |

Asymmetric slope:
- left flank (0.00 → 0.25): −0.39 mnat over 0.25 units
- right flank (0.25 → 0.50): +1.42 mnat over 0.25 units

Both Arm B runs (#1929 ×0.0, #1980 ×0.25) hit **sr=2875** — the shallow-block momentum pulse mechanism CONSISTENTLY ties baseline sr. The only failing dimension is val_ema; we're +0.286 mnat above the gate. A modest 0.3 mnat further improvement converts this to a WIN.

## Mechanism

At step 975 (cooldown onset), apply `m *= factor` to body PMuon momentum buffers in shallow blocks (0-3) ONLY. Two arms bracket the discovered minimum:
- ×0.10 — between HARD-ZERO and ×0.25; tests whether U-shape has sharper left flank
- ×0.20 — just below ×0.25 minimum; tests whether optimum shifted left

"Softer decay preserves directional signal" was partially confirmed at ×0.25. The U-shape suggests the optimum balances:
- preserving SOME directional information (factor > 0) avoids the disruption of full reset
- magnitude small enough to escape the cooldown-onset transition (factor < 0.5)

The non-monotone shape is **mechanistically novel** — a genuine interior optimum.

## Distinguishing from prior closures

| PR | factor | result |
|---|---|---|
| #1929 Arm B | 0.00 (HARD-ZERO) | sr=2875, val_ema +0.676 mnat |
| #1980 Arm A | 0.50 | sr=2875, val_ema +1.703 mnat |
| #1980 Arm B | 0.25 | **sr=2875, val_ema +0.286 mnat (MIN)** |
| **this PR Arm A** | **0.10** | — |
| **this PR Arm B** | **0.20** | — |

## Arms

**Arm A — shallow-block decay ×0.10**
- At step 975, `m *= 0.10` for body PMuon momentum buffers in shallow blocks (0-3) — 24 buffers
- Tests whether tiny residual direction is more useful than zero

**Arm B — shallow-block decay ×0.20**
- At step 975, `m *= 0.20` for body PMuon momentum buffers in shallow blocks (0-3) — 24 buffers
- Tests whether optimum is at 0.25 or shifted lower

## Implementation

Code already in place from edward #1980 — flags validated:
- `--body_muon_momentum_zero_blockwise_step 975`
- `--body_muon_momentum_zero_blockwise_subset shallow`
- `--body_muon_momentum_zero_blockwise_factor <value>`

Sentinels at step 975 confirm `n_eligible=24, n_scaled=24` (#1980 student-verified). No code changes needed.

## Reproduce commands

### Arm A — decay ×0.10
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset shallow \
  --body_muon_momentum_zero_blockwise_factor 0.10 \
  --wandb_group g1r1-edward-body-mom-shallow-decay-fine \
  --wandb_name g1r1-edward/body-mom-shallow-decay-x0.10
```

### Arm B — decay ×0.20
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset shallow \
  --body_muon_momentum_zero_blockwise_factor 0.20 \
  --wandb_group g1r1-edward-body-mom-shallow-decay-fine \
  --wandb_name g1r1-edward/body-mom-shallow-decay-x0.20
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` — seed-2 confirmation required for sr=2875 wins
- **Promising:** sr=2875 + val_ema improvement vs ×0.25 (+0.286 mnat)
- **WIN candidate:** sr=2875 + val_ema < 3.262854 (request seed-2 immediately)
- NULL: sr ≥ 2900 OR val_ema > +0.5 mnat

## Risk

Low. Code path validated; bracketed factors around a discovered minimum.

## Expected outcomes

- **Both arms < ×0.25 gap:** sweet spot is broad; minimum near 0.15-0.20. Likely WIN candidate.
- **Both arms > ×0.25 gap:** sharp interior minimum exactly at ×0.25.
- **One improves, one regresses:** clear direction for follow-up.
- **Either arm crosses val_ema < 3.262854:** seed-2 confirmation request immediately.
