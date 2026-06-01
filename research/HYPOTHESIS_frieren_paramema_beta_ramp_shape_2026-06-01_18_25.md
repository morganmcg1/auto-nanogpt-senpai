---
student: g1r1-frieren
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 18:25 UTC
directive_alignment: (e) schedules that steepen loss descent before step 2925
---

# Hypothesis: paramEMA β-target RAMP SHAPE bilateral — LINEAR vs COSINE (vs baseline STEP)

## Background

PR #2105 (just closed, bilateral NULL) tested WHEN the β transition activates (ema_warmup_steps @1250 vs @2250 vs baseline @1750). Both alternatives are NULL — the warmup_step optimum is a sharp local maximum at @1750.

The CLOSED #2105 axis asks "when does β start moving toward 0.99?" The PRISTINE #2??? axis asks: "**once it starts moving at step 1750, HOW does it interpolate from 0.97 to 0.99?**"

Currently, the β schedule is a **STEP FUNCTION**:
- β = 0.97 for all steps 0 to 1749 (inclusive)
- β = 0.99 for all steps 1750 to 3250 (inclusive)

This instantaneous jump means the EMA immediately shifts from "fast" (decays at 3% per step) to "slow" (decays at 1% per step) — a sharp 3× slowdown in tracking speed. A **smooth ramp** would gradually decelerate the EMA tracking speed over [1750, 2600], giving the model time to adapt to the slowing EMA rather than experiencing an abrupt discontinuity.

The paramEMA β ramp SHAPE has **never been tested**. The baseline step function is an implicit choice that hasn't been challenged.

## Hypothesis

The abrupt step in β at step 1750 may be suboptimal:
- A **linear ramp** from 0.97 to 0.99 over [1750, 2600] gives a smooth, uniform deceleration — keeps EMA tracking "somewhat fast" throughout mid-cooldown, gradually slowing to baseline speed at the canonical refresh boundary.
- A **cosine ramp** over [1750, 2600] gives a slow-fast-slow deceleration (S-shaped) — holds β near 0.97 (fast tracking) a bit longer at the start, then rolls to 0.99 before the refresh.
- A **bilateral NULL** closes the ramp-shape axis and confirms the step function is robust.

Each ramp shape preserves the boundary conditions β(1750) = 0.97 and β(≥2600) = 0.99, making this a clean shape comparison without changing the endpoints.

## Implementation

**Add a single CLI flag**:

```python
parser.add_argument('--ema_beta_ramp_shape', type=str, default='step',
                    choices=['step', 'linear', 'cosine'],
                    help='Shape of paramEMA beta schedule from ema_beta (0.97) to ema_beta_target (0.99) '
                         'over the window [ema_warmup_steps, 2600]. '
                         '"step" = instantaneous jump at ema_warmup_steps (baseline). '
                         '"linear" = linear interpolation over [ema_warmup_steps, 2600]. '
                         '"cosine" = cosine interpolation over same window.')
```

**Modify the β update** (wherever the current β schedule is computed each step, typically near the EMA update):

```python
# Current logic (step function):
# if step >= args.ema_warmup_steps:
#     current_beta = args.ema_beta_target  # 0.99
# else:
#     current_beta = args.ema_beta         # 0.97

# New logic:
RAMP_START = args.ema_warmup_steps      # 1750
RAMP_END = args.paramema_refresh_step   # 2600 (canonical refresh boundary)
beta_start = args.ema_beta              # 0.97
beta_end = args.ema_beta_target         # 0.99

if args.ema_beta_ramp_shape == 'step' or step < RAMP_START:
    current_beta = beta_end if step >= RAMP_START else beta_start
elif args.ema_beta_ramp_shape == 'linear':
    if step >= RAMP_END:
        current_beta = beta_end
    else:
        t = (step - RAMP_START) / (RAMP_END - RAMP_START)  # in [0, 1]
        current_beta = beta_start + (beta_end - beta_start) * t
elif args.ema_beta_ramp_shape == 'cosine':
    if step >= RAMP_END:
        current_beta = beta_end
    else:
        import math
        t = (step - RAMP_START) / (RAMP_END - RAMP_START)  # in [0, 1]
        current_beta = beta_start + (beta_end - beta_start) * (1 - math.cos(math.pi * t)) / 2
```

**Note**: `args.paramema_refresh_step` (default 2600) is used as the natural ramp end because it's the canonical phase boundary that everything synchronizes with. If `paramema_refresh_step` is changed, the ramp window shifts accordingly — this is the correct behavior.

**Sentinel logging at step 1750 (RAMP_START)**:
```python
if step == RAMP_START:
    print(f"[step {step}] beta_ramp_shape={args.ema_beta_ramp_shape}: beta at this step={current_beta:.5f}")
    if wandb.run:
        wandb.log({"optim/ema_beta_ramp_shape": args.ema_beta_ramp_shape,
                   "optim/ema_beta_at_warmup_start": current_beta}, step=step)
```

Also log `optim/ema_beta` as a constant at each checkpoint-relevant step (or at a sample cadence) so the ramp trajectory is visible in W&B:
```python
# In the per-step logging block (wherever train/loss is logged):
if wandb.run and step % 50 == 0:
    wandb.log({"optim/ema_beta_current": current_beta}, step=step)
```

**CRITICAL**: Verify `--ema_beta_ramp_shape step` reproduces the baseline trajectory exactly (same losses at steps 0-3250).

## Arms

### Arm A — LINEAR ramp (0.97 → 0.99 over [1750, 2600])

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ema_beta_ramp_shape linear \
  --wandb_group g1r1-frieren-paramema-beta-ramp \
  --wandb_name g1r1-frieren/paramema-beta-linear-arm-a
```

### Arm B — COSINE ramp (0.97 → 0.99 over [1750, 2600])

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ema_beta_ramp_shape cosine \
  --wandb_group g1r1-frieren-paramema-beta-ramp \
  --wandb_name g1r1-frieren/paramema-beta-cosine-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (uses `ema_beta_ramp_shape=step`).

## Expected outcomes

- **WIN (either arm):** β ramp SHAPE IS load-bearing. A smooth transition avoids the abrupt tracking-speed discontinuity at step 1750, improving EMA quality during [1750, 2600]. Most paper-narrative-grade finding: "the EMA update schedule shape during the paramEMA accumulation window matters." Follow-up: test the winning shape at different ramp widths.
- **Partial (one arm better):** One shape more favorably interacts with the cosine LR decay and pEMA refresh dynamics. Follow-up: explore hybrid shapes.
- **NULL (both arms):** Step function is robust — the EMA doesn't care about smooth vs abrupt β transition. Closes the β-ramp-shape axis. Combined with warmup_step (#2105) and refresh_step (#2102) both NULL, the paramEMA schedule TIMING and SHAPE parameters are confirmed as robust defaults.

## Chain rule

1. **Implement + verify** `--ema_beta_ramp_shape step` is exact baseline first.
2. **Launch Arm A (linear) first.** 
   - Clear NULL → launch Arm B (cosine) immediately.
   - WIN candidate → seed-2 Arm A first before Arm B.
3. Both arms terminal → post terminal SENPAI-RESULT.

## Why this aligns with directive (e)

The β ramp SHAPE is a schedule parameter that controls how quickly the EMA "tightens" during the paramEMA accumulation phase. A slower β approach (staying near 0.97 longer) keeps the EMA sensitive to recent gradient information while LR is still relatively high — potentially steepening descent before step 2925 by preventing premature EMA smoothing. A cosine shape front-loads the slow-β period most aggressively. Directive (e) asks for "schedules that steepen loss descent before step 2925" — a well-designed β ramp that keeps EMA tracking faster for longer during cooldown directly addresses this.
