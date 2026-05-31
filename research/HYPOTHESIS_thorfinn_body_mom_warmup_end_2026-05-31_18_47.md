# Hypothesis: Body PMuon momentum HARD-ZERO vs DECAY ×0.5 @ warmup-end step 200 (joint, all 12 blocks)

**Branch:** `g1r1-thorfinn/body-mom-warmup-end`
**Date:** 2026-05-31 18:47 UTC
**Student:** thorfinn

## Background

The body-Muon `momentum_buffer` pulse axis has been tested **only at cooldown onset (step 975)** so far:

| PR | Op | Subset | Step | sr | val_ema | Verdict |
|---|---|---|---|---:|---:|---|
| #1876 fern | HARD-ZERO | joint (all) | 975 | 2925 | — | NULL (early closure) |
| #1929 Arm A | HARD-ZERO | deep (8-11) | 975 | 2925 | 3.2658 | NULL |
| #1929 Arm B | HARD-ZERO | shallow (0-3) | 975 | **2875** | 3.2635 | **closest near-miss** |
| #1980 (in flight) | DECAY ×0.5/×0.25 | shallow (0-3) | 975 | — | — | — |
| #1984 (in flight) | HARD-ZERO + DECAY ×0.5 | middle (4-7) | 975 | — | — | — |
| #1986 (in flight) | FRESH-START copy_(grad) | deep / shallow | 975 | — | — | — |

The **EARLIER phase boundary at step 200 (warmup-end → stable-LR transition)** is **completely untested** for body PMuon momentum state — yet this is the **same boundary** where frieren #1963 just achieved the programme's first WIN-candidate in many rounds (aux Adam v×0.5 @ step 200 joint, sr=2875, val_ema=3.262159, -0.7 mnat, pending seed-2).

## Hypothesis

The warmup phase (steps 0-200, LR ramping 0→peak) accumulates body PMuon `momentum_buffer` under a progressively increasing gradient-scale regime. The buffer at step 200 is over-weighted toward the recent (high-LR) updates relative to the stable-LR regime that follows. A **state reset / decay** at step 200 recalibrates the momentum direction at the warmup→stable LR transition — a regime boundary as sharp as cooldown onset but with the opposite asymmetry (gradient-scale ramping UP, not LR decaying DOWN).

This is mechanistically analogous to frieren's WIN-candidate on aux v-state at the same step:
- frieren #1963: aux Adam `exp_avg_sq` (v-state) ×0.5 @ step 200, joint → val_ema 3.262159 (-0.7 mnat)
- **THIS**: body PMuon `momentum_buffer` HARD-ZERO or DECAY ×0.5 @ step 200, joint → ?

If the mechanism is **"recalibrate optimizer state at warmup-end across both optimizers"**, then the body-Muon side should also produce signal. If only aux-Adam responds, the warmup-end recalibration is specific to second-moment (v) statistics rather than first-moment direction.

**Predicted outcomes:**
- Arm A HARD-ZERO @ 200 — most aggressive reset; if directional info from warmup is hurting, this wins
- Arm B DECAY ×0.5 @ 200 — preserves direction but attenuates magnitude; if magnitude matters more than direction at this boundary, this wins
- Bilateral NULL — body Muon momentum is insensitive to warmup-end recalibration; mechanism is specific to aux Adam v-state (frieren's WIN remains the unique step-200 lever)

This experiment is **orthogonal to frieren #1963** (different optimizer, different state type) and to all in-flight body-Muon momentum PRs (#1980/#1984/#1986 all @ step 975).

## Arms

| Arm | Subset (blocks) | Operation | Step |
|---|---|---|---|
| A | **all** (joint, 0-11) | `momentum_buffer.zero_()` (HARD-ZERO) | 200 |
| B | **all** (joint, 0-11) | `momentum_buffer.mul_(0.5)` (DECAY ×0.5) | 200 |

## Implementation

The `--body_muon_momentum_zero_blockwise_*` infrastructure (added by #1929 / #1980 / #1986) already supports `op={zero, decay, fresh_start}` and `subset={deep, shallow, middle}`. **One-line addition**: extend the `subset` choices with `"all"` (alias `"joint"` if preferred) which targets all 12 blocks:

```python
target_blocks = {
    "deep":    [8, 9, 10, 11],
    "shallow": [0, 1, 2, 3],
    "middle":  [4, 5, 6, 7],
    "all":     list(range(12)),    # NEW — joint scope, all 12 blocks
}[subset]
```

Also extend `choices` in the argparse declaration:

```python
parser.add_argument('--body_muon_momentum_zero_blockwise_subset', type=str, default='deep',
                    choices=['deep', 'shallow', 'middle', 'all'],
                    help='Block subset for body-PMuon momentum operation. all = all 12 blocks (joint scope).')
```

**SENTINEL: log L2 norm of `momentum_buffer` BEFORE and AFTER the operation across all 12 blocks**, confirming the buffer was reset/decayed for every block:

```
[step 200] body PMuon momentum {ZERO|DECAY} blockwise (subset=all, target_blocks=[0..11], n_modified=N, factor=0.5)
[step 200] block=0 ||m_before||=X ||m_after||=Y (Y/X should be ~0.0 for ZERO, ~0.5 for DECAY)
[step 200] block=11 ||m_before||=X ||m_after||=Y
```

Confirm the hook fires AFTER `p.grad` is set for that step but BEFORE the param update, matching the placement in #1929/#1980/#1986.

## Baseline stack

Always use the full #1532 baseline stack — these flags MUST be present in BOTH arms:

```
--muon_lr 0.040 \
--ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
--muon_block_lr_pattern late-higher \
--paramema_refresh_only --paramema_refresh_step 2600 \
--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

## Reproduce commands

**Arm A — HARD-ZERO @ step 200, all blocks:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 200 \
  --body_muon_momentum_zero_blockwise_subset all \
  --body_muon_momentum_zero_blockwise_op zero \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group thorfinn-body-mom-warmup-end \
  --wandb_name thorfinn-body-mom-warmup-end-armA-zero
```

**Arm B — DECAY ×0.5 @ step 200, all blocks:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 200 \
  --body_muon_momentum_zero_blockwise_subset all \
  --body_muon_momentum_zero_blockwise_op decay \
  --body_muon_momentum_zero_blockwise_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group thorfinn-body-mom-warmup-end \
  --wandb_name thorfinn-body-mom-warmup-end-armB-decay-half
```

## Baseline

PR #1532: `sr=2875`, `val_ema=3.262854` (n=2)

## Merge gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Decision rules

- **WIN both clauses** → merge winner (best Pareto arm); thorfinn closes the warmup-end body-Muon lever
- **Near-miss sr=2875 with val_ema improvement <0.5 mnat** → request seed-2 confirmation of the closer arm
- **Both NULL** → close axis; body PMuon momentum @ warmup-end CLOSED; warmup-end recalibration is aux-Adam-v-state-specific (frieren #1963 only)

## Directive alignment (#1252)

- **(a) optimizer-state resets at phase boundaries** — warmup-end step 200 is a phase boundary
- **(c) short phase-specific mechanisms** — single-step pulse
- **(d) momentum/preconditioner state handling** — direct momentum_buffer manipulation
- **(e) schedules that steepen loss descent before step 2925** — earlier recalibration may steepen post-warmup descent

Avoids: scalar β/μ/γ sweeps (state-arithmetic only); does not touch LR/wd schedules. Body-Muon analog of the most promising current lead (frieren #1963 WIN-candidate at the same boundary on aux Adam).
