# Auto-NanoGPT-r3 Baseline

## Current best (advisor branch `auto-nanogpt-r3`)

- **PR**: starter baseline (in-repo `records/track_3_optimization/train_gpt_simple.py`)
- **Optimizer**: Muon (lr=0.035, wd=0.025, mu=0.95, NS iters=12) on block 2D weights;
  AdamW (lr=0.3 embed, lr=1/320 lm_head, lr=0.01 scalars, betas=(0.8, 0.95),
  eps=1e-10, weight_decay=0) on aux params.
- **Schedule**: stable-then-decay, `cooldown_frac=0.7` for all groups.
- **Init**: proj weights zeroed; embed `normal()`; other matrices `normal(std=sqrt(0.33)/sqrt(fan_in))`.
- **`train_steps`**: 3350.
- **Primary metric**: `speedrun/final_first_step_to_target` (lower is better).
- **Stat-sig rule**: `(3.28 - mu) * sqrt(n) >= 0.004` — n=1 needs mu < 3.276, n=4 needs mu < 3.278.

The default script's hparams mirror public record #12 (Muon lr=.035 wd=.025), which
attained `mu=3.2790 (n=20)` at 3325 steps after ending 25 steps early. With our
`train_steps=3350`, expected mean is in the same neighborhood. Treat 3300–3325 as
the credible step-count target for an in-domain replication.

## Public record snapshot (read-only context)

Top in-repo records from `records/track_3_optimization/README.md`:

| # | Steps | Evidence | Idea |
| - | - | - | - |
| 20 | 3030 | 3.2790 (n=30) | Contra-Muon → Soft-Muon interpolation + SOAP attn (MLP+V) + tuned schedule |
| 19 | 3125 | 3.2780 (n=6) | KL-SOAP w/ hyperball, precond_freq=1, lr=.018 |
| 16 | 3125 | 3.2784 (n=8) | NorMuonH + SOAP attn trust gate (PR283) |
| 14 | 3150 | 3.2776 (n=4) | Contra-Muon + SOAP-Muon MLP precond |
| 13 | 3210 | 3.2785 (n=10) | NorMuonH inside MuLoCo outer Nesterov (K=1, sync=30) |
| 11 | 3225 | 3.2785 (n=16) | Setup #9 + Contra-Muon |
| 10 | 3250 | 3.2789 (n=20) | NorMuon lr=.035 wd=.025, end 50 steps early |
|  9 | 3250 | 3.2771 (n=8)  | NorMuon + u/w-floor=0.35, lr=.0375 |
|  8 | 3250 | 3.2778 (n=10) | NorMuonH per-module init, lr=.018, end 25 steps early |
|  7 | 3325 | 3.2752 (n=1)  | Muon² (NS twice) lr=.10 wd=.0125 β₂=.95 |
|  6 | 3375 | 3.2788 (n=20) | Muon lr=.025 wd=.025 |
|  5 | 3325 | 3.2782 (n=10) | MuonH per-module init, lr=.018, h_cooldown=1.0 |
|  4 | 4875 | 3.2741 (n=5)  | AdamH (Adam + hyperball) per-module init |

Full reproducible code for each is in
`records/track_3_optimization/results/<dir>/*.txt`. Use those as implementation
references when an idea claims to inherit a previous record's machinery.

## Constraint reminders

- Dataset, batch size, architecture FIXED. Only optimizer, hparams, schedules,
  and initialization may change.
- ONE forward-backward per optimizer step. No grad accum on top of the
  multi-microbatch loop.
- All optimizer code must be inlined in the training script (no third-party
  optimizer packages for benchmark claims).
- No per-run early stopping based on val loss. Predeclare `train_steps` and seed
  count and report all non-cherry-picked runs.
- Final claims must include a `SENPAI-RESULT` marker line and report
  `(3.28 - mu)*sqrt(n) >= 0.004`.
