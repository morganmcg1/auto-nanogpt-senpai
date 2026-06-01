---
student: g1r1-alphonse
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 18:15 UTC
directive_alignment: (c) short phase-specific mechanisms + (d) preconditioner state handling
---

# Hypothesis: Body PMuon NS_ITERS COOLDOWN SCHEDULE bilateral — 12→8 vs 12→4

## Background

Body PMuon's polar projection (orthogonalization of momentum buffer) runs Newton-Schulz5 (NS5) for `NS_ITERS=12` iterations at EVERY optimizer step. This 12-iteration count is fixed across the entire 3250-step run — warmup, mid-training, and cooldown all use the same precision.

NS5 with 12 iterations is **overprecise**: numerical analysis of NS5 polynomial coefficients shows convergence to the polar factor is geometric with rate ~1/3 per iteration, meaning by iteration 8 the residual is already ~10⁻⁴, and by iteration 4 it is ~10⁻². During cooldown (steps 975→3250), the model is in fine-tuning regime where:
1. Gradients have smaller magnitudes (cosine LR has decayed below peak)
2. The optimizer is converging to the local minimum's flat region
3. Per-step precision of the orthogonal projection matters LESS than overall step direction

**Reducing NS_ITERS during cooldown is a phase-specific mechanism that has NEVER been tested.** Adjacent axes already closed:
- NS5 polynomial COEFFICIENT changes (#1660 body PMuon NS-coefs pulse) — bilateral NULL
- NS5 polar projection completely OFF / replaced (#1703 ADOPT, #1752 Newton-Muon, #1771 ACProp aux) — all NULL
- Scalar precision sweep (uniformly higher NS_ITERS or lower) — never tested

The pristine angle is: **PRECISION SCHEDULE across phases**. Baseline NS_ITERS=12 throughout. Hypothesis: reducing NS_ITERS during cooldown lets the gradient direction have more direct influence (less orthogonal-projection drag), potentially steepening descent before step 2925.

## Hypothesis

The body PMuon orthogonal projection at full NS_ITERS=12 may be **over-regularizing** during cooldown. Either:
- **Arm A modest reduction (NS_ITERS=8):** drops ~2 orders of magnitude of polar-projection error during cooldown → slightly less over-projection, slight gradient-direction preservation. Tests if the polar projection has SLACK headroom (less precision is just as good).
- **Arm B aggressive reduction (NS_ITERS=4):** drops ~4 orders of magnitude of polar-projection error during cooldown → significantly noisier orthogonalization, but gradient direction less suppressed. Tests if NS5 precision is the BOTTLENECK during cooldown.
- **Bilateral NULL:** the polar projection IS already at the right precision level for cooldown; precision-schedule axis closed.

Each outcome is directive (c) information: it tells us whether per-step whitening precision is load-bearing in the cooldown phase.

## Implementation

**Add a single CLI flag** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument('--cooldown_ns_iters', type=int, default=0,
                    help='If >0, override NS_ITERS to this value for body PMuon polar projection '
                         'at step >= cooldown_ns_iters_start_step (default: 975, cooldown onset). '
                         '0 = use baseline NS_ITERS unchanged.')
parser.add_argument('--cooldown_ns_iters_start_step', type=int, default=975,
                    help='Step at which the reduced NS_ITERS takes effect. Defaults to 975 (cooldown onset).')
```

**Modify the body PMuon polar-projection call** (locate where `NS_ITERS` constant or `ns_iters=12` argument is used in the PMuon update step). Replace the constant with a step-aware value:

```python
# Where the Newton-Schulz polar projection is currently invoked:
if args.cooldown_ns_iters > 0 and step >= args.cooldown_ns_iters_start_step:
    effective_ns_iters = args.cooldown_ns_iters
else:
    effective_ns_iters = NS_ITERS  # baseline 12

# pass effective_ns_iters to the polar projection function
m_orth = newton_schulz5_polar(m, n_iters=effective_ns_iters)  # or whatever the actual call is
```

**Critical**: ensure default `--cooldown_ns_iters 0` reproduces the existing baseline trajectory bit-exactly. Verify with a smoke test by comparing the first 50 loss values to a known baseline.

**Sentinel logging**: at the cooldown onset step (e.g., step 975), log:
```python
if step == args.cooldown_ns_iters_start_step:
    print(f"[step {step}] NS_ITERS schedule: pre-cooldown={NS_ITERS}, cooldown={effective_ns_iters}")
    if wandb.run:
        wandb.log({"optim/ns_iters_pre_cooldown": NS_ITERS,
                   "optim/ns_iters_cooldown": effective_ns_iters,
                   "optim/cooldown_ns_iters_start_step": args.cooldown_ns_iters_start_step}, step=step)
```

Also log `optim/cooldown_ns_iters` as a constant at step 0 so the wandb config-set is trivial to filter.

## Arms

### Arm A — MODEST REDUCTION (12→8)

Mechanism: NS_ITERS=12 during warmup+main-training (steps 0-974), NS_ITERS=8 during cooldown (steps 975-3250).

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --cooldown_ns_iters 8 \
  --wandb_group g1r1-alphonse-ns-iters-cooldown \
  --wandb_name g1r1-alphonse/ns-iters-cooldown-8-arm-a
```

### Arm B — AGGRESSIVE REDUCTION (12→4)

Mechanism: NS_ITERS=12 during warmup+main-training, NS_ITERS=4 during cooldown (significantly noisier polar projection, gradient direction more pristine).

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --cooldown_ns_iters 4 \
  --wandb_group g1r1-alphonse-ns-iters-cooldown \
  --wandb_name g1r1-alphonse/ns-iters-cooldown-4-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (NS_ITERS=12 throughout).

## Expected outcomes

| Outcome | Meaning | Follow-up |
|---|---|---|
| **Arm A WIN (NS_ITERS=8)** | NS5 has precision slack during cooldown — saving 4 iterations per step is "free" or improves convergence | Bracket {6, 8, 10}; explore per-block NS_ITERS schedule |
| **Arm B WIN (NS_ITERS=4)** | Polar projection at 12 is over-regularizing during cooldown — gradient direction matters more than orthogonality | Bracket {2, 4, 6}; test full NS_ITERS=1 (pure normalization) |
| **Arm A NULL, Arm B WORSE** | NS_ITERS=8 is robust slack but =4 is too aggressive — sweet spot in middle | Bracket {6, 7, 8, 10} |
| **Both NULL within margin** | NS5 precision is robust at the cooldown schedule level; either 8 or 4 is acceptable | Close axis |
| **Both NULL, Arm B catastrophic** | NS_ITERS=4 destroys orthogonality, projection precision matters; NS_ITERS=8 still null says baseline precision is right | Close axis |

## Chain rule

1. **Implement flag + sentinel first.** Verify default `--cooldown_ns_iters 0` reproduces baseline trajectory.
2. **Launch Arm A (NS_ITERS=8) first.**
   - If Arm A clear NULL (sr ≥ 2925, val_ema ≥ 3.265): launch Arm B (NS_ITERS=4) directly.
   - If Arm A WIN candidate (sr ≤ 2875 with val_ema near/below baseline): run seed-2 of Arm A first.
3. **If Arm B diverges or fails to reach target**, that itself is data (precision is structurally required) — post terminal SENPAI-RESULT with the failure.
4. Both arms terminal → post terminal `SENPAI-RESULT` with both run IDs.

## Compute budget

Standard 3250-step run × 2 arms ≈ 6h wall-clock total. NS_ITERS reduction REDUCES per-step compute slightly (about 4-8 NS iterations × ~tiny matmul each saved per body PMuon step). Net effect: ~5% step-time reduction in cooldown for Arm A, ~10% for Arm B. Implementation is ~10 lines.

## Why this aligns with directive

- **(c) short phase-specific mechanisms**: NS_ITERS reduction is active ONLY during the cooldown phase (steps 975-3250 = 70% of the run). The mechanism is silent during warmup/main-training.
- **(d) momentum/preconditioner state handling**: NS5 polar projection IS the preconditioner update operation. Adjusting its precision schedule is direct preconditioner state handling.

A WIN here is a **paper-narrative-grade finding** — "the bilateral whitening's polar-projection precision is NOT load-bearing during cooldown" or "polar projection precision is LIMITING during cooldown" are both publishable observations about Muon-family optimizers. A NULL closes a pristine axis (NS_ITERS-precision schedule).
