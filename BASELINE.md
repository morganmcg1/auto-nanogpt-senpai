# Baseline — auto-nanogpt-r5

## Current best (starter script)

- **Source**: `records/track_3_optimization/train_gpt_simple.py` (HEAD of `auto-nanogpt-r5`).
- **Optimizer**: Muon (lr=0.035, wd=0.025, mu=0.95, 12 NS iterations) + aux AdamW (embed lr=0.3, lm_head lr=1/320, scalars lr=0.01; betas=(0.8, 0.95), eps=1e-10, wd=0).
- **Schedule**: stable then linear cooldown, `cooldown_frac=0.7` over `train_steps=3350`.
- **Init**: proj weights zeroed, others `normal_(std=0.33**0.5 / fan_in**0.5)`; embed default normal.
- **Architecture**: 12 layers, dim 768, head_dim 128, RMSNorm gains, Linear biases. Fixed.
- **Tokens**: 524,288 per step (8×64×1024). Fixed.

## Target

- Primary: `speedrun/final_first_step_to_target` (lower-is-better; -1 = not reached).
- Statistical contract: `(3.28 - mu) * sqrt(n) >= 0.004`.

## Reference benchmark history

Public records in `records/track_3_optimization/README.md` (these are external evidence, not yet reproduced on this advisor branch — beat them locally and we have a winner):

| # | Steps | Mean (n) | Method |
| - | -     | -        | -      |
| 12 | 3375 | 3.2790 (n=20) | Muon lr=.035 wd=.025 (≈ our starter) |
| 5 | 3325 | 3.2782 (n=10) | MuonH (hyperball) + per-module init |
| 8 | 3250 | 3.2778 (n=10) | NorMuonH |
| 9 | 3250 | 3.2771 (n=8) | NorMuon + u/w-floor |
| 11 | 3225 | 3.2785 (n=16) | Contra-Muon |
| 13 | 3210 | 3.2785 (n=10) | MuLoCo + NorMuonH |
| 18 | 3225 | 3.2776 (n=9) | PMuon |
| 14 | 3150 | 3.2776 (n=4) | Contra + SOAP-Muon (MLP) |
| 16 | 3125 | 3.2784 (n=8) | TrustLight |
| 19 | 3125 | 3.2780 (n=6) | KL-SOAP + hyperball |
| 20 | **3030** | **3.2790 (n=30)** | Contra-Soft-Muon (current public SOTA) |

## Reproduce baseline

```bash
cd /workspace/senpai/target
pip install -r requirements.txt
python data/cached_fineweb10B.py 20
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$STUDENT_NAME/<short-description>" \
  --wandb_group "<hypothesis-or-pr>"
```

## Winning bar

Beat the starter script's mean val loss at the predeclared step count, satisfying the statistical rule. Even small improvements compound.
