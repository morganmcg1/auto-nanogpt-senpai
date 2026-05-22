## Hypothesis

PR #699 (your own musoft win) established that block residual-projection weights (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) should be initialized to N(0, σ_musoft) where σ_musoft = sqrt(0.33) / sqrt(fan_in × L) ≈ 0.006 for fan_in=768, L=12. The 1/√L depth scaling form is load-bearing — your P1 confirmed it beats both zero-init (worse), 1/L scaling (worse), depth-independent constant (worse), and applying the same scaling to non-residual weights (worse).

But **the multiplicative coefficient was never independently optimized.** The μP coefficient sqrt(0.33)≈0.574 was inherited from the literature, and α=1.0× was adopted as canonical without a magnitude sweep. The functional form (depth scaling) is confirmed correct; the scalar multiplier on that form remains a free axis.

**Mechanistic motivation for an interior optimum away from α=1.0:**
- At α=1.0 the residual projections start near their effective noise floor under SOAP. The L/R covariance estimator for a near-zero matrix converges slowly; the first ~200 steps may be preconditioner-noise-dominated.
- A modestly wider init (α=1.5) would give SOAP's covariance estimator a cleaner signal without saturating the residual stream.
- At α=2.0+ the residual stream may start dominating the embedding signal too early, creating a different kind of saturation.

This is an unambiguous fresh axis — no other PR sweeps the magnitude multiplier on the musoft form. frieren #748 sweeps a different init class (Q/K/V + fc_in transformation weights, NOT residual-proj). nezuko #706 sweeps embed init. edward #714 sweeps gain init. None test the multiplier on the depth-aware residual-proj std.

## Baseline to beat

**PR #699 baseline**: μ=3.261221, σ=0.000593, n=4, ffs_mean=3025.

**Mandatory flags** (every cell): `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03`

**Statsig rule (n=4):** `(3.261221 − μ) × √4 ≥ 0.004` → **n=4 merge gate: μ ≤ 3.259221**
**Clean-NEG cutoff:** μ > 3.261

## 5-Cell P1 Sweep

All cells: `--num_trials 1 --train_steps 3250 --depth_init_mode mualpha --wandb_group "g1r5-alphonse/resid-alpha-sweep"`

| Cell | `--resid_init_alpha` | σ (fan_in=768, L=12) | Role |
|:----:|:--------------------:|:---------------------:|:-----|
| A | 0.50 | ≈ 0.00299 | Half-scale anchor (sign-falsifier downward) |
| B | 0.75 | ≈ 0.00449 | Sub-canonical |
| C | 1.00 | ≈ 0.00598 | **Control — reproduces musoft baseline** |
| D | 1.50 | ≈ 0.00898 | Super-canonical (primary prediction) |
| E | 2.00 | ≈ 0.01196 | Double-scale anchor |

**Prediction**: D > C with val/loss in [3.257, 3.261]. Secondary: monotone A < B < C ≤ D, then E falls back. Falsifier: if A ≥ C the SOAP-warm-up interpretation is wrong; pivot to sub-canonical sweep.

## Implementation

Add a new mode `mualpha` and a new flag `--resid_init_alpha`. Changes in `records/track_3_optimization/train_gpt_simple.py`:

### 1. New CLI flag (add near other init args, ~after `--depth_init_mode`)

```python
parser.add_argument(
    "--resid_init_alpha",
    type=float,
    default=1.0,
    help="Multiplier on musoft residual-proj init std (active when --depth_init_mode mualpha). "
         "sigma = alpha × sqrt(0.33) / sqrt(fan_in × L).",
)
```

### 2. Add `"mualpha"` to `--depth_init_mode` choices

```python
choices=["ctrl", "musoft", "mumedium", "muall", "smallconst", "mualpha"],
```

### 3. Extend `_resid_proj_std` to accept `alpha`

```python
def _resid_proj_std(fan_in: int, mode: str, L: int, alpha: float = 1.0) -> float:
    base = (0.33 ** 0.5) / (fan_in ** 0.5)
    if mode == "musoft":
        return base / (L ** 0.5)
    elif mode == "mualpha":                      # ← new branch
        return alpha * base / (L ** 0.5)
    elif mode == "mumedium":
        return base / L
    elif mode == "muall":
        return base / (L ** 0.5)
    elif mode == "smallconst":
        return 1e-3
    else:
        raise ValueError(mode)
```

### 4. Pass `alpha` at the call sites

In the init loop (residual-proj branch):
```python
std = _resid_proj_std(w.size(-1), args.depth_init_mode, NUM_LAYERS,
                      alpha=args.resid_init_alpha)
```

And in the sanity print:
```python
_ex_resid_std = _resid_proj_std(768, args.depth_init_mode, NUM_LAYERS,
                                alpha=args.resid_init_alpha) \
                if args.depth_init_mode != "ctrl" else 0.0
print(f"[init] mode={args.depth_init_mode}  alpha={args.resid_init_alpha:.3f}  "
      f"L={NUM_LAYERS}  block_residual_attn.proj_std={_ex_resid_std:.6f}")
```

### 5. Log to W&B config

Add `"resid_init_alpha": args.resid_init_alpha` to the wandb.init config dict.

**Backward-compatibility**: `--depth_init_mode mualpha --resid_init_alpha 1.0` reproduces musoft (PR #699 baseline) exactly. This is the refactor-neutrality check — Cell C should land in the strong-ctrl band [3.260, 3.262] within σ_single=0.000593.

## Reproduce commands

```bash
# Cell A — alpha=0.50
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha 0.50 \
  --wandb_name "alphonse-resid-alpha-A-050-n1" \
  --wandb_group "g1r5-alphonse/resid-alpha-sweep"

# Cell B — alpha=0.75
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha 0.75 \
  --wandb_name "alphonse-resid-alpha-B-075-n1" \
  --wandb_group "g1r5-alphonse/resid-alpha-sweep"

# Cell C — alpha=1.00 (ctrl, reproduces musoft baseline)
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha 1.00 \
  --wandb_name "alphonse-resid-alpha-C-100-n1" \
  --wandb_group "g1r5-alphonse/resid-alpha-sweep"

# Cell D — alpha=1.50 (primary prediction)
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha 1.50 \
  --wandb_name "alphonse-resid-alpha-D-150-n1" \
  --wandb_group "g1r5-alphonse/resid-alpha-sweep"

# Cell E — alpha=2.00
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha 2.00 \
  --wandb_name "alphonse-resid-alpha-E-200-n1" \
  --wandb_group "g1r5-alphonse/resid-alpha-sweep"
```

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Cell C deviates from 3.261221 by > 0.001 | Implementation bug — check flag routing before B/D/E |
| Any cell val/loss ≤ 3.259221 (beat n=4 gate) | Flag immediately; proceed to P2 n=4 on best cell |
| Best cell ∈ (3.259221, 3.261] | Promising single-seed below baseline; request advisor decision on P2 |
| All 5 cells val/loss > 3.261 | Clean-NEG — magnitude axis exhausted at musoft |
| Non-monotone (A < C and E < C) | Two-sided optimum — flag for n=4 on both A and E |

## P2 command template (if any cell beats gate)

```bash
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
  --lr_scalars 0.03 \
  --depth_init_mode mualpha --resid_init_alpha <BEST_ALPHA> \
  --wandb_name "alphonse-resid-alpha-P2-n4" \
  --wandb_group "g1r5-alphonse/resid-alpha-P2-confirm"
```

P2 merge gate: μ_n=4 ≤ 3.259221.

## Reporting

Use sequential single-runner driver pattern from your #699 success (setsid-detached, smoke → A → B → C → D → E). Per-cell SENPAI-RESULT with `pending_arms:true` as each terminates. Final unified marker after E with all 5 W&B run_ids and per-cell val/loss table.

This is a tight axis — 5 cells × ~1.8h = ~9h to terminal. Carry on.
