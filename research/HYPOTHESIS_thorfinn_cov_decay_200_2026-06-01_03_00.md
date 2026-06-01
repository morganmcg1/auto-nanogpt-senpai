# Body PMuon L_cov / R_cov DECAY ×0.5 / ×0.25 @ step 200 (warmup-end)

**Hypothesis owner:** thorfinn (idle after #2003 bilateral NULL — body PMuon momentum ZERO/DECAY @ step 200)
**Date:** 2026-06-01 03:00 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state resets at phase boundaries, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling. The body PMuon **cov-state** (L_cov, R_cov — running side-covariance buffers used for bilateral whitening) has been thoroughly tested at later boundaries but is **untested at the warmup-end boundary (step 200)**:

| op | step | scope | result | source |
|---|---|---|---|---|
| HARD-ZERO + ×0.5 | 975 | bilateral | NULL +3.57/+3.69 mnat | #1930 fern |
| L-only / R-only ZERO | 1100 | per-side | NULL +1.928/+1.530 mnat | #1849 thorfinn |
| ZERO bilateral | 2750 | bilateral | sr=2950/+2.83 mnat NULL | #1726 nezuko Arm A |
| ZERO bilateral | 2750 | bilateral | sr=2875/+1.07 mnat NULL | #1726 nezuko Arm B |
| **PARTIAL DECAY ×0.5 / ×0.25** | **200** | **bilateral** | **UNTESTED** | — |

**Key observations:**
1. Cov-state perturbation has produced one close near-miss (#1726 Arm B at +1.07 mnat) but always at later boundaries.
2. The cov buffers accumulate over warmup steps (1-200) — the warmup-end boundary is where they first have meaningful values from the warming-up parameter trajectory.
3. The closer-to-zero attenuation (×0.25 in this PR) was the best factor in the analogous body PMuon **momentum** decay matrix (edward #1980 Arm B interior min +0.286 mnat at shallow ×0.25). Test whether the same factor preference holds for the cov axis.

The intuition: at step 200, the model has just exited warmup and the cov buffers carry "noisy warmup" history. Attenuating them slightly may force a faster re-accumulation from cleaner stable-phase gradients, reducing the contamination of late-phase whitening directions.

## Mechanism

At step 200 (warmup-end), apply `L_cov *= factor; R_cov *= factor` to all 12 transformer blocks' body PMuon side-covariance buffers simultaneously (24 buffers per arm). Two arms bracket the expected minimum:
- ×0.5 — replicates fern #1930 Arm B factor at the warmup-end boundary (cooldown-onset bilateral NULL)
- ×0.25 — analogous to edward #1980 best factor on momentum axis (interior minimum)

## Implementation

The cov-state decay flag `--body_muon_cov_zero_step` already exists from fern #1930 (PRs cov-state HARD-ZERO/×0.5 @975 closed). Set step=200 with `--body_muon_cov_zero_factor 0.5` / `0.25`:

Sentinel verification (already implemented):
```
[step 200] body PMuon cov DECAY (n_blocks=12, n_L=12, n_R=12, factor=<X>)
```

If the existing flag does NOT accept a `factor` (only HARD-ZERO), the student should add `--body_muon_cov_zero_factor` flag (small change, isolated). Check `train_gpt_simple.py` for the cov zero implementation block before launching.

## Distinguishing from prior closures

| PR | factor | step | scope | result |
|---|---|---|---|---|
| #1930 Arm A | 0.00 (HARD-ZERO) | 975 | bilateral | sr=2925, +3.57 mnat NULL |
| #1930 Arm B | 0.5 | 975 | bilateral | sr=2925, +3.69 mnat NULL |
| #1849 Arm A | 0.00 | 1100 | L-only | sr=2925, +1.928 mnat NULL |
| #1849 Arm B | 0.00 | 1100 | R-only | sr=2925, +1.530 mnat NULL |
| #1726 Arm B | 0.00 | 2750 | bilateral | sr=2875, **+1.07 mnat NULL (closest miss)** |
| **this PR Arm A** | **0.5** | **200** | **bilateral** | — |
| **this PR Arm B** | **0.25** | **200** | **bilateral** | — |

## Arms

**Arm A — Bilateral cov DECAY ×0.5 @ step 200**
- At step 200, `L_cov *= 0.5` AND `R_cov *= 0.5` for all 12 transformer blocks (24 buffers)
- Replicates fern #1930 Arm B factor at fresh warmup-end boundary

**Arm B — Bilateral cov DECAY ×0.25 @ step 200**
- At step 200, `L_cov *= 0.25` AND `R_cov *= 0.25` for all 12 transformer blocks (24 buffers)
- Tests deeper attenuation (analogous to edward #1980 momentum best factor)

## Reproduce commands

### Arm A — ×0.5 @ 200
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_zero_step 200 \
  --body_muon_cov_zero_factor 0.5 \
  --wandb_group g1r1-thorfinn-cov-decay-200 \
  --wandb_name g1r1-thorfinn/cov-decay-200-x0.5
```

### Arm B — ×0.25 @ 200
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_zero_step 200 \
  --body_muon_cov_zero_factor 0.25 \
  --wandb_group g1r1-thorfinn-cov-decay-200 \
  --wandb_name g1r1-thorfinn/cov-decay-200-x0.25
```

**Implementation note:** If `--body_muon_cov_zero_factor` flag doesn't exist in current train script (only HARD-ZERO supported), add it as a small isolated change (default=0.0 keeps existing behavior; non-zero scales L/R cov buffers by that factor instead of zeroing).

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` — seed-2 confirmation required for sr=2875 wins
- **Promising:** sr=2875 + val_ema improvement comparable to #1726 Arm B (+1.07 mnat) — closest cov-state near-miss
- **WIN candidate:** sr=2875 + val_ema < 3.262854 → request seed-2 immediately
- NULL: sr ≥ 2900 OR val_ema > +1.5 mnat

## Risk

Low-medium. Cov axis closed at later boundaries, but @200 is a genuinely fresh boundary where buffer accumulation is freshly minted from warmup gradients. Implementation reuses or minimally extends existing #1930 cov-zero infrastructure.

## Expected outcomes

- **Arm A (×0.5) better than fern #1930 @975 ×0.5 (+3.69 mnat):** Warmup-end is more receptive to cov manipulation than cooldown onset → promising
- **Arm B (×0.25) better than Arm A:** Interior minimum favoring deeper attenuation at @200 (consistent with momentum-axis pattern)
- **Both NULL:** Cov-state axis CLOSED at warmup-end too → axis fully exhausted across all 3 boundaries (200/975-1100/2750)
- **Either arm WIN:** First successful cov-state intervention; opens cov-axis exploration at warmup phase
