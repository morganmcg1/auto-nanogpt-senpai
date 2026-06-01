# Body NorMuon variance-estimator β₂ PULSE 0.9 → 0.99 / 0.95 @ step 975 (cooldown onset)

**Hypothesis owner:** nezuko (idle after #2024 body-mom FRESH-START @ 2600 bilateral NULL closure)
**Date:** 2026-06-01 06:55 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux Adam β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state at phase boundaries, (d) momentum/preconditioner state handling, and (e) schedules that steepen loss descent before step 2925. This is the **direct body-side analog of the aux Adam β₂ pulse mechanism that established the current baseline** (#1532), targeting a structurally distinct preconditioner that has never been touched at any phase boundary.

The body NorMuon optimizer maintains a low-rank Adafactor-style **second-moment variance estimator** (`second_momentum_buffer`) controlled by its own `beta2`. From `train_gpt.py:1727-1732`:

```python
normuon_defaults = dict(
    lr=0.023,
    momentum=0.95,
    beta2=0.9,      # ← variance estimator EMA, NEVER PULSED at any boundary
    weight_decay=1.2,
)
```

Update path (lines 875-884):
```
v_chunk = polar_express(grad_chunk, momentum_buffer, momentum_t)       # Nesterov + polar
v_chunk = _apply_normuon_variance_reduction(v_chunk, second_momentum_buffer, beta2, red_dim)  # Adafactor norm
```

The variance reduction step:
```
second_momentum_buffer.lerp_(v_mean, 1 - beta2)
step_size = second_momentum_buffer.clamp_min(1e-10).rsqrt_()
# update is then scaled by step_size (with norm-preserving correction)
```

At step 975 today: body NorMuon's `beta2=0.9` gives a ~10-step half-life. The aux Adam `β₂` is pulsed 0.95→0.99 (half-life ~20 → ~70 steps) at exactly the cooldown onset boundary — this is the canonical baseline WIN. **The body NorMuon variance estimator is denied the same cooldown smoothing treatment.** Mid-cooldown its denominator is a fast-tracking estimate that re-mixes warmup-tail squared updates with rapidly cooling cooldown updates, plausibly mis-calibrated relative to a longer-memory smoother that would lock in the stabler post-warmup variance regime.

## Why this isn't covered by past closures

| Prior PR | Buffer touched | Mechanism | Result |
|---|---|---|---|
| #1532 (baseline WIN) | **aux Adam exp_avg_sq** | β₂ pulse 0.95→0.99 @975 | **WIN** |
| #1666 / #1726 / #1780 / #1849 | body Muon `L_cov` / `R_cov` (legacy bilateral whitening cov-state) | reset / ×0.5 / per-side | bilateral NULL (across boundaries) |
| #1797 / #1836 / #1876 / #1929 / #1986 / #2024 | body NorMuon `momentum_buffer` | SCALE / HARD-ZERO / FRESH-START | bilateral NULL (all boundaries) |
| #1648 / #1697 / #1877 / #1742 / #1788 | body NorMuon LR / μ / per-block | scalar pulses | NULL across all axes |
| #1680 / #1831 / #1935 | polar γ (= NS exponent) | RELAX / SHARPEN | NULL across boundaries × depths |
| #1739 | polar projection iteration count | NS burst 12→14/16 pre-target | NULL (accuracy not bottleneck) |
| **this PR** | **body NorMuon `second_momentum_buffer` (variance estimator)** | **β₂ PULSE 0.9 → 0.99 / 0.95 @975** | **NEW AXIS** |

The legacy `L_cov`/`R_cov` closures were on a **prior code generation** that used bilateral whitening with two-sided covariance buffers. The current code uses **Polar Express + Adafactor-style low-rank variance reduction**, and that variance estimator's `beta2` has never been pulsed, scaled, reset, or otherwise perturbed at any phase boundary. It is a missing column in the (mechanism × buffer) matrix.

## Mechanism

At step 975 (cooldown onset), simultaneously with the canonical aux Adam β₂ pulse on the aux side, also pulse the body NorMuon `beta2` from 0.9 to a higher value. This forces the body NorMuon variance estimator to stop fast-tracking new squared updates and instead "lock in" the variance estimate accumulated through warmup-end + early-warmup-to-cooldown transition. Subsequent updates use a slower-moving denominator that should track the macroscopic cooldown trajectory more stably.

The structural parallel is precise:
- aux Adam: `exp_avg_sq.lerp_(grad².mean, 1-β₂)` — change β₂ at 975 → denominator memory extends
- body NorMuon: `second_momentum_buffer.lerp_(v_mean, 1-β₂)` — change β₂ at 975 → denominator memory extends

If the mechanism that made aux Adam's pulse load-bearing transfers to body NorMuon's variance estimator, this should produce an additive improvement (orthogonal axes, both improving cooldown calibration on their respective optimizers).

If body NorMuon's faster `beta2=0.9` is already optimal for the polar-projected update statistics (which differ from aux Adam's raw gradient statistics), the pulse will be NULL — but this is the FIRST test of that question on the current code generation.

## Arms

**Arm A — β₂ → 0.99 (matches aux pulse target exactly)**
- At step 975, set `p_cfg.beta2 = 0.99` for ALL NorMuon param configs (12 blocks × multiple groups)
- Mechanism: variance estimator half-life extends from ~10 → ~70 steps
- Tests the symmetric application of the canonical baseline mechanism

**Arm B — β₂ → 0.95 (intermediate, more conservative)**
- At step 975, set `p_cfg.beta2 = 0.95` for ALL NorMuon param configs
- Mechanism: variance estimator half-life extends from ~10 → ~20 steps
- Tests a milder version in case 0.99 over-locks an estimator that genuinely needs to track the cooldown's rapidly changing update magnitudes

If Arm A regresses but Arm B improves → "lock-in" is helpful but 0.99 is too long; intermediate optimal.
If both improve → variance estimator was under-smoothed throughout cooldown; pulse direction validated.
If both regress → body NorMuon variance estimator is correctly calibrated at 0.9; canonical baseline absorbed the available cooldown variance signal.

## Implementation

Code changes (small, no buffer manipulation):

```python
# CLI flags (add to args)
parser.add_argument("--normuon_b2_pulse_step", type=int, default=-1,
                    help="Step at which to pulse NorMuon beta2 (-1 disables)")
parser.add_argument("--normuon_b2_pulse_target", type=float, default=0.9,
                    help="Target beta2 value after the pulse")

# In training loop, between backward and optimizer.step:
if args.normuon_b2_pulse_step >= 0 and step == args.normuon_b2_pulse_step:
    pulse_count = 0
    for p, p_cfg in optimizer.param_cfgs.items():
        if p_cfg.optim == "normuon":
            p_cfg.beta2 = args.normuon_b2_pulse_target
            pulse_count += 1
    print(f"[step {step}] normuon_b2_pulse: beta2 {0.9} → {args.normuon_b2_pulse_target} on {pulse_count} param groups")
```

Verification sentinel in logs: `[step 975] normuon_b2_pulse: beta2 0.9 → 0.99 on N param groups` (where N is the total NorMuon param count, expected to match the 12-block × group structure).

The change is a single attribute update on each `ParamConfig`; no buffer manipulation, no compile-graph implications (beta2 is passed in as a scalar to `_apply_normuon_variance_reduction`).

## Reproduce commands

Full baseline stack required:

### Arm A — NorMuon β₂ pulse 0.9 → 0.99 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --normuon_b2_pulse_step 975 --normuon_b2_pulse_target 0.99 \
  --wandb_group g1r1-nezuko-normuon-b2-pulse-975 \
  --wandb_name g1r1-nezuko/normuon-b2-pulse-975-arm-a-099
```

### Arm B — NorMuon β₂ pulse 0.9 → 0.95 @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --normuon_b2_pulse_step 975 --normuon_b2_pulse_target 0.95 \
  --wandb_group g1r1-nezuko-normuon-b2-pulse-975 \
  --wandb_name g1r1-nezuko/normuon-b2-pulse-975-arm-b-095
```

Chain Arm B after Arm A terminates (single GPU). If Arm A near-miss (sr=2875 + val_ema within ~0.5 mnat of gate), chain a seed-2 of Arm A immediately for n=2 confirmation before launching Arm B.

## Expected outcomes

**Strong signal (sr ≤ 2862.5 OR sr=2875 with val_ema < 3.262854):** body NorMuon variance estimator is missing the cooldown-onset re-smoothing benefit, the mechanism is additive with aux β₂ pulse, and the WIN compounds. Merge candidate.

**Close near-miss (sr=2875, val_ema 0–1 mnat above gate):** mechanism is real but undersized; follow up with intermediate β₂ targets (0.97, 0.98) or per-group localization (embed-skipping NorMuon groups vs full pulse).

**Bilateral NULL (sr ≥ 2925, val_ema > 3.265):** body NorMuon variance estimator is structurally insensitive to β₂ pulse at this boundary — either its post-polar squared-update statistics are too different from aux Adam's raw gradient statistics, or `beta2=0.9` is already optimal across both warmup and cooldown. Axis CLOSED at @975; future work: same mechanism @200 (warmup-end) or @2600 (pEMA refresh).

**Crash / divergence:** unlikely given the change is a scalar EMA β₂ shift on an already-running running statistic (no buffer reset, no numerical edge case). If it happens, report the step and val_loss at crash, do not retry without diagnosis.

## Constraints

- Use the unmodified baseline stack (muon_lr=0.040, ema_beta=0.97, late-higher, paramEMA refresh @2600, aux β₂ pulse @975).
- Both arms must include the canonical aux β₂ pulse flags so we're testing the body NorMuon mechanism on top of the established WIN.
- Single-GPU chain; do not launch both arms concurrently.
- If Arm A produces a thin clause-2 PASS (val_ema < 3.262854 by <0.5 mnat), HOLD the merge and chain seed-2 of Arm A before launching Arm B — seed noise on thin margins has burned us repeatedly (#1605, #1637, #1850, #1780 Arm B).
- Post SENPAI-RESULT marker only after both arms terminate (or after Arm A wins decisively with n=2 confirmation).
