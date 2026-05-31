# Body PMuon momentum SCALE-UP (m *= 2.0 / m *= 4.0) @ step 975 (cooldown onset) — bilateral by magnitude

**Hypothesis owner:** askeladd (idle after #1962 aux v-decay per-group bilateral NULL closure)
**Date:** 2026-05-31 19:30 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (c) short phase-specific mechanisms and (e) schedules that steepen loss descent before step 2925. The body-PMuon momentum SCALE axis has been closed bilaterally for SCALE-DOWN (×0.5 and ×0.25 at both step 975 and step 2750) — but the **SCALE-UP direction has never been tested**. SCALE-DOWN attenuates accumulated momentum, hypothesizing that stale direction history hurts the cooldown transition. SCALE-UP amplifies it, hypothesizing that accumulated direction is **load-bearing** and the cooldown transition needs MORE inertia to compress the loss faster.

## Mechanism

At step 975 (cooldown onset), the LR begins linear decay from peak to 0. Without momentum amplification, the effective step size shrinks proportionally with LR. A one-shot momentum SCALE-UP at step 975 amplifies the per-step update temporarily, creating a "boost" right at the cooldown entry that the natural LR decay then absorbs over ~20-step momentum re-equilibration. This directly aligns with directive (e): steepening loss descent.

If the accumulated direction is correct, scaling up should steepen the descent for ~20 steps post-975, then natural μ=0.95 re-equilibration brings the buffer back to its normal magnitude. If the direction is noisy, scaling up will amplify the noise and destabilize. The bilateral result reveals which dominates.

## Distinguishing from prior closures

| PR | scale factor | boundary | result |
|---|---|---|---|
| #1797 | ×0.5, ×0.25 | 975 | bilateral NULL |
| #1836 | ×0.5, ×0.25 | 2750 | bilateral NULL |
| **this PR** | **×2.0, ×4.0** | **975** | — |

**SCALE-DOWN closes ×0.5/×0.25; SCALE-UP at ×2.0/×4.0 is the symmetric, untested half of the axis.** If both arms NULL, the body-momentum SCALE axis is bilaterally closed in both directions and the magnitude-modulation mechanism class is fully exhausted. If Arm A or B wins, the asymmetry (UP works but DOWN doesn't) tells us the accumulated direction IS load-bearing and amplification is beneficial.

## Arms

**Arm A — moderate amplification ×2.0**
- At step 975, set `m *= 2.0` for ALL 72 body PMuon momentum buffers (all 12 blocks × 6 PMuon param groups)
- Mechanism: doubles effective step magnitude for ~20 steps until natural μ=0.95 re-equilibration

**Arm B — heavy amplification ×4.0**
- At step 975, set `m *= 4.0` for ALL 72 body PMuon momentum buffers
- Mechanism: quadruples effective step magnitude, sharper transient
- Tests sensitivity: if ×2 helps and ×4 hurts, there's a sweet spot; if both null with same magnitude, mechanism is amplitude-saturated

## Implementation

Code changes:
- Add CLI flags: `--muon_momentum_scale_up_step` (default -1), `--muon_momentum_scale_up_factor` (default 1.0)
- In training step loop, if `step == muon_momentum_scale_up_step`:
  - Iterate body PMuon param groups
  - For each param with momentum state, `state["momentum"].mul_(scale_up_factor)`
  - Log count of buffers scaled and the factor
- Verification sentinel: `[step 975] muon_momentum_scale_up: x{factor} on N buffers`

State key is `state["momentum"]` (per #1730 implementation note).

## Reproduce commands

Full baseline stack required:

### Arm A — scale-up ×2.0 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_scale_up_step 975 \
  --muon_momentum_scale_up_factor 2.0 \
  --wandb_group g1r1-askeladd-body-mom-scale-up-975 \
  --wandb_name g1r1-askeladd/body-mom-scale-up-975-arm-a-x2
```

### Arm B — scale-up ×4.0 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_scale_up_step 975 \
  --muon_momentum_scale_up_factor 4.0 \
  --wandb_group g1r1-askeladd-body-mom-scale-up-975 \
  --wandb_name g1r1-askeladd/body-mom-scale-up-975-arm-b-x4
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` (with seed-2 confirmation for sr=2875 wins)
- Promising: Arm A improves but Arm B catastrophic — suggests sweet-spot scan needed
- NULL: both arms sr ≥ 2900 OR val_ema worse than baseline — closes magnitude-modulation mechanism bilaterally in both directions

## Risk

Medium. Amplifying momentum could destabilize cooldown trajectory at ×4. Arm A (×2) is the conservative arm. If Arm B (×4) diverges catastrophically (val_loss > 10 at terminal), expected and informative — sets the upper bound of the SCALE-UP axis.

## Expected outcomes

- **Both NULL**: body-mom SCALE axis bilaterally closed in both directions → momentum-magnitude modulation mechanism class fully exhausted at step 975; redirect to direction-modifying mechanisms next
- **Arm A WIN, Arm B NULL**: amplification helps at moderate magnitude; sweet-spot scan at ×1.5/×3 next
- **Both WIN**: rare but informative; mechanism is real and dose-insensitive in this range
