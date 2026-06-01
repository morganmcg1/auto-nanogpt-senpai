---
student: g1r1-frieren
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 18:25 UTC
revised: 2026-06-01 19:30 UTC (corrected baseline description after student caught error)
directive_alignment: (e) schedules that steepen loss descent before step 2925
---

# Hypothesis: paramEMA β-target RAMP SHAPE bilateral — LR-DECOUPLED LINEAR vs LR-DECOUPLED COSINE (vs LR-COUPLED baseline)

## Background (CORRECTED)

The actual baseline `compute_ema_beta_t` at `records/track_3_optimization/train_gpt_simple.py` line 875 computes β as an **LR-coupled smooth ramp**, NOT a step function:

```python
beta_t = args.ema_beta + (args.ema_beta_target - args.ema_beta) * (1.0 - lr_mult)
```

With `COOLDOWN_POWER=1.4` and `cooldown_frac=0.7`, the baseline β trajectory is:
- Step 0-974: lr_mult=1.0 → β_t=0.97 (EMA buffer tracks live params per `--ema_warmup_steps 1750`)
- Step 1750 (EMA activation): lr_mult ≈ 0.566 → β_t ≈ 0.9787 (already partway up the ramp)
- Step 3250: lr_mult=0 → β_t=0.99

The EMA at step 1750 boots up with β ≈ 0.979 (NOT 0.97). The baseline shape is a power-law-shaped ramp following `1 - (1 - cooldown_progress)^1.4`.

PR #2105 (just closed, bilateral NULL) tested WHEN the EMA activates (warmup_step @1250 vs @2250 vs baseline @1750). Both alternatives are NULL — the warmup_step optimum is a sharp local maximum at @1750.

The CLOSED #2105 axis asks "when does the EMA activate?" The PRISTINE axis here asks: "**once the EMA activates at step 1750, what SHAPE should β follow from 0.97 → 0.99?**"

The LR-coupling of β to the LR cooldown power-law is an **implicit design choice that has never been challenged**. Alternative shapes that preserve the same endpoints {β(1750)=0.97, β(3250)=0.99} but use a different functional form (linear, cosine) might steepen descent before step 2925 if the LR-coupled shape isn't optimal.

## Hypothesis

If the LR-coupling IS load-bearing → linear/cosine should underperform baseline.
If LR-coupling is incidental → linear/cosine reach equivalent or better val_ema.
If the LR-coupled "fast-forward" start (β ≈ 0.979 at activation) is suboptimal → linear/cosine (which start at β=0.97 with fast tracking) outperform.

## Implementation

**Add a single CLI flag**:

```python
parser.add_argument('--ema_beta_ramp_shape', type=str, default='lr_coupled',
                    choices=['lr_coupled', 'linear', 'cosine'],
                    help='Shape of paramEMA beta schedule from ema_beta (0.97) to '
                         'ema_beta_target (0.99). Active over [ema_warmup_steps, train_steps]. '
                         '"lr_coupled" = baseline behavior (beta tracks 1-lr_mult, power-law shape). '
                         '"linear" = linear interpolation in step. '
                         '"cosine" = cosine interpolation in step.')
```

**Modify `compute_ema_beta_t`** to branch on shape:

```python
def compute_ema_beta_t(step):
    if args.ema_beta <= 0:
        return 1.0
    if args.ema_beta_target is None:
        return args.ema_beta

    beta_base = args.ema_beta            # 0.97
    beta_target = args.ema_beta_target   # 0.99
    lo = min(beta_base, beta_target)
    hi = max(beta_base, beta_target)

    if args.ema_beta_ramp_shape == 'lr_coupled':
        # EXISTING BASELINE BEHAVIOR — preserved bit-exactly
        lr_mult = compute_lr_mult(step)
        beta_t = beta_base + (beta_target - beta_base) * (1.0 - lr_mult)
        return max(lo, min(hi, beta_t))

    RAMP_START = args.ema_warmup_steps    # 1750
    RAMP_END = train_steps                # 3250

    if step <= RAMP_START:
        return beta_base
    if step >= RAMP_END:
        return beta_target

    t = (step - RAMP_START) / (RAMP_END - RAMP_START)  # in [0, 1]

    if args.ema_beta_ramp_shape == 'linear':
        beta_t = beta_base + (beta_target - beta_base) * t
    elif args.ema_beta_ramp_shape == 'cosine':
        import math
        beta_t = beta_base + (beta_target - beta_base) * (1 - math.cos(math.pi * t)) / 2

    return max(lo, min(hi, beta_t))
```

**CRITICAL**: `--ema_beta_ramp_shape lr_coupled` MUST reproduce the baseline trajectory bit-exactly. Verify with a smoke test (loss at first 50 steps matches baseline).

**Sentinel logging at step 1750**:
```python
if step == args.ema_warmup_steps:
    print(f"[step {step}] beta_ramp_shape={args.ema_beta_ramp_shape}: beta_t={compute_ema_beta_t(step):.5f}")
    if wandb.run:
        wandb.log({"optim/ema_beta_ramp_shape": args.ema_beta_ramp_shape,
                   "optim/ema_beta_at_warmup_start": compute_ema_beta_t(step)}, step=step)
```

Also log `optim/ema_beta_current` at every step (or every 50 steps) so the ramp trajectory is visible in W&B.

## Arms

### Arm A — LR-DECOUPLED LINEAR ramp [1750, 3250]

At step 1750: β_t = 0.97 (vs baseline's 0.979 — slower tracking initially)
At step 2500: β_t = 0.98 (vs baseline's ~0.987)
At step 3250: β_t = 0.99 (same as baseline)

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

### Arm B — LR-DECOUPLED COSINE ramp [1750, 3250]

At step 1750: β_t = 0.97 (same as linear at start)
Mid-window: β_t accelerates faster than linear (1-cos curve is convex)
At step 3250: β_t = 0.99 (same endpoint)

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

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (uses LR-coupled β).

## Expected outcomes

- **Arm A WIN (linear):** LR-decoupling AND/OR slower β start helps. Follow-up: bracket window endpoint (e.g., linear over [1750, 2600] for faster late-saturation).
- **Arm B WIN (cosine):** S-shaped ramp with delayed acceleration helps. Follow-up: explore other S-shapes.
- **Bilateral NULL:** LR-coupling is robust — the power-law shape is not the load-bearing factor. Closes β-ramp shape axis.

## Chain rule

1. **Implement + verify** `--ema_beta_ramp_shape lr_coupled` is bit-exact baseline.
2. **Launch Arm A (linear) first.**
   - Clear NULL → launch Arm B (cosine) immediately.
   - WIN candidate → seed-2 of WIN arm before Arm B.
3. Both arms terminal → post terminal SENPAI-RESULT.

## Why this aligns with directive (e)

The β shape during the EMA-active phase [1750, 3250] is a schedule that potentially steepens loss descent before step 2925. The baseline's LR-coupled shape "fast-forwards" β to ~0.979 at activation. A linear/cosine arm that starts at β=0.97 (fast tracking) and ramps slower gives the EMA more time to absorb recent gradient information when LR is still high. Directive (e) asks for schedules that steepen descent before step 2925 — testing the β shape is a direct lever.

## Revision history

- **2026-06-01 18:25 UTC**: Original assignment incorrectly described baseline as step function.
- **2026-06-01 19:30 UTC**: Corrected baseline description (LR-coupled power-law ramp) after student caught error on PR #2163. Arms revised to compare LR-coupled vs LR-decoupled linear/cosine over [1750, 3250] window.
