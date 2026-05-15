# Baseline — auto-nanogpt-r4

## Active baseline (in-repo reproducible)

- **Source:** `records/track_3_optimization/train_gpt_simple.py` as checked in to
  `auto-nanogpt-r4`.
- **Optimizer:** Muon (Newton–Schulz with Nesterov, mu=0.95) on block weights
  with `lr=0.035 weight_decay=0.025`, AdamW on embed/proj/scalars
  (`betas=(0.8, 0.95)`, lr=0.3/1/320/0.01 per group).
- **train_steps:** 3350. Cooldown: linear, `cooldown_frac=0.7`.
- **Init:** `nn.Linear` default normal for non-proj weights, `proj` zeros,
  `gains=1`, `bias=0`, embedding default torch normal.
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better,
  `-1` = never reached 3.28).
- **Status:** Single-trial starter; no in-repo confirmation yet. The starter is
  taken as our reproducible base. All R4 PRs compare against `train_steps=3350`
  with this Muon+Adam recipe.

## Statistical rule

`(3.28 - mu) * sqrt(n) >= 0.004` must hold across all non-cherry-picked runs at
the same predeclared step count. Single-run threshold ≤ 3.276; n=4 ≤ 3.278; n=8
≤ 3.2786; n=16 ≤ 3.2790.

## Public records to chase (read-only context)

From `records/track_3_optimization/README.md` (do not refresh, do not browse
external sources; these are the snapshot we work from):

| Steps | Mean loss (n) | Description | Record |
| - | - | - | - |
| 3030 | 3.2790 (n=30) | Setup #16 + Contra-Soft-Muon + tuned LR schedule | #20 |
| 3125 | 3.2780 (n=6) | KL-SOAP w/ hyperball, β1=.95 β2=.9 shampoo_β=.9 | #19 |
| 3125 | 3.2784 (n=8) | trustlight: #14 + SOAP attention with trust gate | #16 |
| 3150 | 3.2776 (n=4) | contra-muon + SOAP MLP | #14 |
| 3175 | 3.2789 (n=20) | #11 + Aurora | #17 |
| 3210 | 3.2785 (n=10) | NorMuonH wrapped in MuLoCo outer Nesterov | #13 |
| 3225 | 3.2785 (n=16) | NorMuon u/w-floor + Contra-Muon | #11 |
| 3225 | 3.2776 (n=9) | PMuon (bilateral streaming covariance preconditioning) | #18 |
| 3250 | 3.2789 (n=20) | NorMuon lr=.035 wd=.025 (end 50 early) | #10 |
| 3250 | 3.2778 (n=10) | NorMuonH (NorMuon + hyperball) | #8 |
| 3250 | 3.2771 (n=8)  | NorMuon u/w-floor (wd-free) | #9 |
| 3325 | 3.2752 (n=1)  | Muon² (Muon with squared NS) lr=.10 wd=.0125 | #7 |
| 3325 | 3.2782 (n=10) | MuonH (Muon + hyperball) lr=.018 | #5 |
| 3375 | 3.2788 (n=20) | Muon + aux Adam lr=.025 wd=.025 | #6 |
| 4875 | 3.2741 (n=5)  | AdamH (Adam + hyperball) lr=.018 | #4 |

## Update protocol

When an R4 PR lands a stat-sig improvement at a lower step count, this file is
updated to reflect the new active baseline (PR number, exact recipe, seed count,
final loss). Public-record column is a static snapshot for context only.
