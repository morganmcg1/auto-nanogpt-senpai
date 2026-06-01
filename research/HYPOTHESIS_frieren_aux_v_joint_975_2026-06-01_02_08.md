# Aux Adam v-state JOINT ×0.25 / ×0.10 @ step 975 (cooldown onset)

**Hypothesis owner:** frieren (idle after #1963 closure — aux v-state ×0.5 @step 200 seed-1 WIN not confirmed)
**Date:** 2026-06-01 02:08 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state resets at phase boundaries, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling. The aux Adam v-state (second moment buffer) manipulation matrix has produced one informative near-miss:

| op | scope | step | result | source |
|---|---|---|---|---|
| v×0.5 | scalar only | 975 | sr=2925 +3.52 mnat NULL | #1912 Arm A |
| v×0.25 | scalar only | 975 | sr=2875 **+0.88 mnat NEAR-MISS** | #1912 Arm B |
| v×0.5 | embed only | 975 | sr=2925 +2.45 mnat NULL | #1962 Arm A |
| v×0.5 | lm_head only | 975 | sr=2925 +2.9 mnat NULL | #1962 Arm B |
| **v×0.5 JOINT all groups** | **all** | **200** | **seed-1 sr=2875 val_ema -0.695 mnat WIN; seed-2 NOT CONFIRMING** | **#1963 Arm A** |
| v×0.5 embed | embed only | 200 | NULL | #1963 Arm B |
| v×0.5 JOINT | **all** | **975** | **UNTESTED** | — |
| v×0.25 JOINT | **all** | **975** | **UNTESTED** | — |

**Key observations:**
1. Scalar ×0.25 @975 was the CLOSEST near-miss of all per-group tests (+0.88 mnat from gate)
2. JOINT @200 ×0.5 showed seed-1 WIN (-0.695 mnat) — seed-2 did not confirm (noisy but signal exists)
3. Per-group (individual scope) consistently NULL at @975; JOINT scope @200 showed marginal signal
4. **JOINT @975 ×0.25 is completely untested** — combines the best factor from scalar tests with the JOINT scope that showed signal at @200

## Mechanism

At step 975 (cooldown onset), reduce all 3 aux Adam optimizer groups' second-moment buffers simultaneously:
- `optimizer1.state[p]["exp_avg_sq"].mul_(factor)` for embed, lm_head, scalar groups

JOINT manipulation tests whether the JOINT scope (all-group coherent recalibration) is stronger than per-group manipulation. The @975 boundary is the canonical window where β₂ pulse (#1532 WIN) and most other mechanisms succeed.

## Arms

**Arm A — JOINT v×0.25 @ step 975**
- At step 975, multiply v-state of ALL aux Adam groups (embed/lm_head/scalars) by 0.25
- Mirrors scalar ×0.25 best-of-class but extends to all groups
- Tests whether JOINT coherence improves on per-group near-miss

**Arm B — JOINT v×0.10 @ step 975**
- At step 975, multiply v-state of ALL aux Adam groups by 0.10
- Tests finer attenuation below ×0.25 (analogous to edward fine-sweep on shallow block decay)
- Probes whether ultra-sparse v-state at the cooldown boundary helps

## Implementation

Standard aux Adam state manipulation. Sentinel to verify:
```
[step 975] aux_v_joint_decay: n_params_decayed=<N> factor=<X>
```

## Reproduce commands

Full baseline stack required:

### Arm A — JOINT v×0.25 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_v_decay_step 975 \
  --aux_v_decay_scope joint \
  --aux_v_decay_factor 0.25 \
  --wandb_group g1r1-frieren-aux-v-joint-975 \
  --wandb_name g1r1-frieren/aux-v-joint-975-x0.25
```

### Arm B — JOINT v×0.10 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_v_decay_step 975 \
  --aux_v_decay_scope joint \
  --aux_v_decay_factor 0.10 \
  --wandb_group g1r1-frieren-aux-v-joint-975 \
  --wandb_name g1r1-frieren/aux-v-joint-975-x0.10
```

**Note:** These flags were implemented for #1963 (`aux_v_decay_step`, `aux_v_decay_scope`, `aux_v_decay_factor`). The code path is validated. No new implementation needed.

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` — seed-2 confirmation required for sr=2875 wins
- **Promising:** sr=2875 + val_ema improvement vs scalar ×0.25 near-miss (+0.88 mnat)
- **WIN candidate:** sr=2875 + val_ema < 3.262854 (request seed-2 immediately)
- NULL: sr ≥ 2900 OR val_ema > +1.0 mnat

## Risk

Low-medium. Code path validated from #1963. @975 boundary well-characterized. Factor ×0.25 is the scalar near-miss level (safe exploration zone).

## Expected outcomes

- **Arm A (×0.25 JOINT) better than scalar ×0.25 near-miss (+0.88 mnat):** JOINT scope captures embed+lm_head interaction → promising
- **Arm B (×0.10) better than Arm A:** Interior minimum below ×0.25 for JOINT scope — fine sweep needed
- **Both NULL:** JOINT scope @975 is no better than per-group — v-state axis CLOSED at @975
- **Either arm WIN:** Confirms JOINT v-state recalibration at cooldown onset as a reproducible mechanism
