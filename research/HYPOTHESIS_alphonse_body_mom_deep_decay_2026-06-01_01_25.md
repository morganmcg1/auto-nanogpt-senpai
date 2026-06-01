# Body PMuon momentum DECAY DEEP BLOCKS (8-11) — bilateral ×0.25 / ×0.50 @ step 975

**Hypothesis owner:** alphonse (idle after #1986 closure — bilateral NULL on blockwise FRESH-START)
**Date:** 2026-06-01 01:25 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (b) per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum state handling. The wave of shallow-block momentum interventions has produced a clean interior minimum at DECAY ×0.25 (#1980 Arm B +0.286 mnat — closest near-miss of entire wave). Deep-block coverage is sparse:

| op | shallow (0-3) | deep (8-11) | source |
|---|---|---|---|
| HARD-ZERO | +0.675 mnat | +2.99 mnat | #1929 |
| FRESH-START | +6.15 mnat | +4.67 mnat | #1986 (this closure) |
| DECAY ×0.5 | +1.70 mnat | **untested** | #1980 (shallow) |
| DECAY ×0.25 | +0.286 mnat (MIN) | **untested** | #1980 (shallow) |

Asymmetric depth response:
- HARD-ZERO: shallow 4.4× better than deep (more decay tolerance in shallow)
- FRESH-START: deep is *less* worse than shallow — reversed asymmetry

Mirror the shallow fine-sweep on deep to complete the **depth × decay-factor matrix**. The shallow optimum is at ×0.25; deep may have an analogous minimum at a different factor (likely ×0.50 or higher given less decay tolerance under late-higher LR pattern).

## Mechanism

At step 975 (cooldown onset), apply `m *= factor` to body PMuon momentum buffers in deep blocks (8-11) ONLY — 24 buffers. Two arms bracket the expected minimum:
- ×0.25 — directly tests whether deep mirrors shallow's interior minimum
- ×0.50 — softer attenuation; tests whether deep prefers gentler decay (consistent with HARD-ZERO sensitivity)

## Distinguishing from prior closures

| PR | factor | subset | result |
|---|---|---|---|
| #1929 Arm A | 0.00 (HARD-ZERO) | deep (8-11) | sr=2925, +2.99 mnat |
| #1986 Arm A | FRESH-START | deep (8-11) | sr=2950, +4.67 mnat |
| #1980 Arm A | 0.50 | shallow (0-3) | sr=2875, +1.703 mnat |
| #1980 Arm B | 0.25 | shallow (0-3) | sr=2875, +0.286 mnat (MIN) |
| **this PR Arm A** | **0.25** | **deep (8-11)** | — |
| **this PR Arm B** | **0.50** | **deep (8-11)** | — |

## Arms

**Arm A — deep-block decay ×0.25**
- At step 975, `m *= 0.25` for body PMuon momentum buffers in deep blocks (8-11) — 24 buffers
- Tests whether deep has an interior minimum at the same factor as shallow

**Arm B — deep-block decay ×0.50**
- At step 975, `m *= 0.50` for body PMuon momentum buffers in deep blocks (8-11) — 24 buffers
- Tests softer decay; matches shallow ×0.5 to enable direct depth comparison

## Implementation

Code already in place from edward #1980 — flags validated. Set `subset=deep`:
- `--body_muon_momentum_zero_blockwise_step 975`
- `--body_muon_momentum_zero_blockwise_subset deep`
- `--body_muon_momentum_zero_blockwise_factor <value>`

Sentinels at step 975 should confirm `n_eligible=24, n_scaled=24` for deep blocks. No code changes needed.

## Reproduce commands

### Arm A — deep decay ×0.25
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset deep \
  --body_muon_momentum_zero_blockwise_factor 0.25 \
  --wandb_group g1r1-alphonse-body-mom-deep-decay \
  --wandb_name g1r1-alphonse/body-mom-deep-decay-x0.25
```

### Arm B — deep decay ×0.50
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset deep \
  --body_muon_momentum_zero_blockwise_factor 0.50 \
  --wandb_group g1r1-alphonse-body-mom-deep-decay \
  --wandb_name g1r1-alphonse/body-mom-deep-decay-x0.50
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` — seed-2 confirmation required for sr=2875 wins
- **Promising:** sr=2875 + val_ema improvement comparable to or better than shallow ×0.25 (+0.286 mnat)
- **WIN candidate:** sr=2875 + val_ema < 3.262854 (request seed-2 immediately)
- NULL: sr ≥ 2900 OR val_ema > +0.5 mnat

## Risk

Low. Code path validated; bracketed factors around plausible interior minimum.

## Expected outcomes

- **Both arms NULL:** deep blocks lack the interior-minimum structure of shallow — closes the depth × decay matrix
- **Arm A (×0.25) closer than Arm B (×0.50):** deep mirrors shallow's preference for stronger attenuation — surprising given HARD-ZERO is bad
- **Arm B (×0.50) better than Arm A (×0.25):** deep prefers gentler decay — consistent with late-higher LR pattern privileging deep blocks; suggests interior min for deep is at ~×0.50
- **Either arm crosses val_ema < 3.262854:** seed-2 confirmation request immediately
