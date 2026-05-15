# Baseline Metrics — auto-nanogpt-1gpu-r2

Target: `records/track_3_optimization/train_gpt_simple.py`, modded-nanogpt
optimizer speedrun track 3. Primary metric is
`speedrun/final_first_step_to_target` — the earliest step at which validation
cross-entropy on FineWeb reaches `<= 3.28`, lower is better. Final claims
require `(3.28 - mu) * sqrt(n) >= 0.004`.

## Current advisor-branch baseline (starter script, unchanged)

| Field | Value |
| --- | --- |
| `train_steps` | 3350 |
| Optimizer 2D | Muon (lr=0.035, wd=0.025, mu=0.95) on `model.blocks.parameters() ndim>=2` |
| Optimizer aux | AdamW: embed.weight lr=0.3; proj.weight lr=1/320; scalars (ndim<2) lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0 |
| Newton-Schulz | 12 iters, (a, b, c) = (2, -1.5, 0.5), bfloat16 |
| LR schedule | unified `cooldown_frac=0.7` (flat for first 30%, linear decay over last 70%) |
| Init | proj weights zeroed; embed `normal_()`; rest `normal_(std=0.33**0.5 / fan_in**0.5)`; gains 1; biases 0 |
| Batch (tokens) | 524288 (`8 * 64 * 1024`) per step |
| Val | 20 * 524288 ≈ 10.5M tokens |
| Model | GPT, 12 layers, model_dim=768, head_dim=128 (6 heads), vocab=50304, seq_len=1024 |

No runs in W&B for `auto-nanogpt-1gpu-r2` at launch. Treat the starter script
as the floor.

## Public modded-nanogpt track 3 records to beat (from `records/track_3_optimization/README.md`)

| # | Steps | Mean val loss (n) | Description |
| - | - | - | - |
| 1 | 3600 | 3.2777 (n=1) | Muon + aux Adam, lr=.02 wd=.01 |
| 2 | 5625 | 3.2790 (n=1) | AdamW lr=0.0015 wd=0.1 betas=(0.9, 0.95) warmup=250 |
| 3 | 3500 | 3.2767 (n=1) | Muon + aux Adam, lr=.025 wd=.0125 |
| 4 | 4875 | 3.2741 (n=5) | AdamH (Adam + hyperball) with per-module init std, lr=.018 |
| 5 | 3325 | 3.2782 (n=10) | MuonH (Muon + hyperball) with per-module init std, lr=.018 |
| 6 | 3375 | 3.2788 (n=20) | Muon + aux Adam, lr=.025 wd=.025 |
| 7 | 3325 | 3.2752 (n=1) | Muon² (Adam variance before NS), lr=.10 wd=.0125 β₂=.95 |
| 8 | 3250 | 3.2778 (n=10) | NorMuonH (NS + Adafactor row/col + hyperball) + per-module init, lr=.018 |
| 9 | 3250 | 3.2771 (n=8) | NorMuon + u/w-floor (wd-free), lr=.0375 |
| 10 | 3250 | 3.2789 (n=20) | NorMuon lr=0.035 wd=0.025, end 50 steps early |
| 11 | 3225 | 3.2785 (n=16) | Setup #9 + Contra-Muon |
| 12 | 3325 | 3.2790 (n=20) | Muon + aux Adam, lr=.035 wd=.025, end 25 steps early |
| 13 | 3210 | 3.2785 (n=10) | NorMuonH wrapped in MuLoCo-style outer Nesterov SGD (sync=30, outer_lr=0.7, outer_mom=0.5) |
| 14 | 3150 | 3.2776 (n=4) | Setup #11 + SOAP precond for MLP (freq=10, beta2=0.90) |
| 15 | 3275 | 3.2785 (n=15) | Newton-Muon: activation-cov right-preconditioning refresh every 64 steps |
| 16 | 3125 | 3.2784 (n=8) | Setup #14 + SOAP for attention with trust gate |
| 17 | 3175 | 3.2789 (n=20) | Setup #11 + Aurora |
| 18 | 3225 | 3.2776 (n=9) | PMuon: bilateral streaming covariance power preconditioning, γ=.3 β=.95 |
| 19 | 3125 | 3.2780 (n=6) | KL-SOAP + hyperball, precondition_frequency=1, lr=.018 beta1=.95 beta2=.9 |
| **20** | **3030** | **3.2790 (n=30)** | **Setup #16 + Contra-Muon ∪ Soft-Muon (annealed) + power-law LR. Current global best.** |
| 21 | 4100 | 3.2776 (n=4) | Shampoo(power=-1/4, lr=0.0015, betas=(.9,.95), wd=0.2, precond_freq=5) |

## Step-vs-loss conversion (from README)

200 fewer steps ≈ 0.0091 higher mean val loss (≈ 0.0045 per 100 steps). Use
this when comparing runs at different step counts for pairwise statsig.

## Reproduce command (on a single GPU)

```bash
cd target/
python data/cached_fineweb10B.py 20
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/<short-description>" \
  --wandb_group "<hypothesis-or-pr>"
```
