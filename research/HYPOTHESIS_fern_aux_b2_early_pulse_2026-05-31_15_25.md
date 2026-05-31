# Hypothesis: Aux Adam β₂ EARLY pulse 0.95→0.99 — timing sweep within pre-warmup-end zone (steps 100 / 200)

**Branch:** `g1r1-fern/aux-b2-early-pulse`
**Date:** 2026-05-31 15:25 UTC
**Student:** fern

## Background

The aux Adam β₂ pulse 0.95→0.99 at **step 975** is the canonical cooldown-onset mechanism that established the #1532 baseline (sr=2875, val_ema=3.262854).

The β₂ pulse **TIMING axis** has been explored in the **delayed** direction:
- **frieren #1915**: β₂ pulse @ step 1100 (Arm A `rw092z34` sr=2925 +2.77 mnat NULL) and @ step 1200 (Arm B `v2j1dqfu` sr=2925 +1.11 mnat NULL) — BILATERAL NULL. Monotonic interior trend: 1200 better than 1100, but neither beats 975. **Delayed timing CLOSED.**

The **EARLY** direction (pre-975 timing, especially in the warmup phase) has **not been tested at all**. Two cells of interest:
- **Step 100** — mid-warmup (warmup runs 0-200), β₂ transitions while LR is still ramping up
- **Step 200** — exactly at warmup-end, β₂ transitions as LR plateau begins

frieren's parallel work in #1963 tests aux **v-state ×0.5** @ step 200 — a state-buffer manipulation at warmup-end. This PR complements that by testing the **β-coefficient pulse** at the same boundary AND earlier. Together (#1963 + this PR), they map two distinct mechanism families at the warmup-end phase boundary.

## Hypothesis

The β₂ pulse 0.95→0.99 captures a **recalibration of the second-moment EMA decay rate** for the AdamW preconditioner. At step 975, this recalibration is timed to the cooldown-onset LR transition — the well-tuned baseline. But the mechanism may have **independent value earlier in training**, when:

- **Mid-warmup (step ~100)**: v statistics are noisy and still accumulating. A faster transition to β₂=0.99 might lock in a more stable EMA before the post-warmup acceleration begins.
- **Warmup-end (step 200)**: v statistics have stabilized through warmup. The β₂=0.99 transition coincides with the LR plateau, providing a clean preconditioning regime change at the same time as the optimization regime change.

Mechanistically, an EARLY β₂ transition means the entire post-warmup training (steps 200→3250) runs with β₂=0.99 rather than β₂=0.95 → switch @ 975 → 0.99. This is **closer to a static β₂=0.99 ablation but with the canonical warmup behavior preserved**.

Note: once β₂ transitions to 0.99, the canonical @975 pulse is a no-op (already at 0.99). So Arm A and Arm B effectively **replace** the @975 pulse with the earlier transition rather than stack.

## Arms

| Arm | β₂ pulse step | β₂ trajectory |
|---|---|---|
| A | **100** (mid-warmup) | 0.95 (steps 0-99) → 0.99 (steps 100-3250) |
| B | **200** (warmup-end) | 0.95 (steps 0-199) → 0.99 (steps 200-3250) |

Baseline #1532: β₂ 0.95 (steps 0-974) → 0.99 (steps 975-3250)

## Implementation

The existing `--aux_b2_pulse_step` flag (used in #1532, #1915, etc.) directly controls the pulse step. **No code changes are needed** — just set the flag value to 100 or 200 instead of 975.

Verify before launch that the existing pulse mechanism does not have a hardcoded cooldown-onset assumption that would prevent firing during warmup. If there is any such guard, remove it or raise a config error to confirm. Read `--aux_b2_pulse_step` handling in the train script to confirm fire-once behavior is preserved.

**SENTINEL: log β₂ values for all three aux groups BEFORE and AFTER the pulse step** to confirm the transition fired correctly during warmup:

```
[step 99]  β₂ before: adam_embed=0.95, adam_lm_head=0.95, adam_scalars=0.95
[step 100] β₂ after:  adam_embed=0.99, adam_lm_head=0.99, adam_scalars=0.99
[step 100] aux_b2_pulse fired @ step 100 (target=0.99, n_groups_updated=3)
```

If the warmup schedule modifies LR via the `lr_scheduler`, confirm that the β₂ pulse is independent of LR scheduling. The pulse should fire regardless of warmup state.

## Baseline stack

Always use the full #1532 baseline stack with `--aux_b2_pulse_step` replaced by the arm-specific timing:

```
--muon_lr 0.040 \
--ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
--muon_block_lr_pattern late-higher \
--paramema_refresh_only --paramema_refresh_step 2600 \
--aux_b2_pulse_target 0.99
```

Note: `--aux_b2_pulse_step` is set to the arm-specific value (100 or 200) per arm. All other baseline flags unchanged.

## Reproduce commands

**Arm A — β₂ 0.95→0.99 @ step 100 (mid-warmup):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 100 --aux_b2_pulse_target 0.99 \
  --wandb_group fern-aux-b2-early-pulse \
  --wandb_name fern-arm-a-b2-pulse-step-100
```

**Arm B — β₂ 0.95→0.99 @ step 200 (warmup-end):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 200 --aux_b2_pulse_target 0.99 \
  --wandb_group fern-aux-b2-early-pulse \
  --wandb_name fern-arm-b-b2-pulse-step-200
```

## Baseline

PR #1532: `sr=2875`, `val_ema=3.262854` (n=2)

## Merge gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Decision rules

- **WIN** both clauses → merge winner (best Pareto arm); EARLY β₂ pulse timing supersedes canonical @975
- **Near-miss** sr=2875, val_ema > 3.262854 → request seed-2 confirmation of the closer arm
- **Both NULL** → close EARLY β₂ pulse timing direction; canonical @975 confirmed as the unique optimum on both EARLY and DELAYED sides

## Directive alignment

Directive #1252 priorities:
- **(a) optimizer-state resets at phase boundaries** — warmup-end is an untested phase boundary
- **(c) short phase-specific mechanisms** — β₂ transition is the canonical short phase-mechanism
- **(e) schedules that steepen loss descent before step 2925** — earlier β₂=0.99 may improve descent through cooldown

Avoids: pure scalar sweeps (β₂ has known mechanism, this is a TIMING test); does not change scalar magnitudes vs baseline.

Complements frieren #1963 (aux v-state ×0.5 @ warmup-end step 200) — both probe the same boundary on **different aux Adam mechanisms** (state buffer vs β-coefficient).
