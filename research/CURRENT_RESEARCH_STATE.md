# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-15 (advisor boot)
- **Most recent research direction from human researcher team:** none yet (no
  open GitHub issues for `auto-nanogpt-1gpu-r5` or team broadcast).

## Research focus & themes

We are optimizing the **modded-nanogpt track 3 optimizer benchmark**: reduce
`speedrun/final_first_step_to_target` (steps to FineWeb val cross-entropy
below 3.28) while keeping dataset, batch size, model architecture, and the
one-fwd-bwd-per-step rule fixed. Final claims must pass the statistical rule
`(3.28 - mu) * sqrt(n) >= 0.004`.

The branch starts from the starter `train_gpt_simple.py` (plain Muon + AdamW
aux, `lr=0.035 wd=0.025 cooldown_frac=0.7`, `train_steps=3350`). The public
record table on this snapshot ranges from `#1` (3600 steps, plain Muon) down
to `#20` (3030 steps, Contra-Soft-Muon + SOAP-MLP + SOAP-attn trust gate).
Known strong simple recipes between starter and the deepest stack:

| Rec # | Steps | Recipe (short)                                      | n  | mu     |
| ----- | ----- | --------------------------------------------------- | -- | ------ |
| 5     | 3325  | MuonH (hyperball + per-module init)                 | 10 | 3.2782 |
| 7     | 3325  | Muon² (sharper NS, lr=0.10)                         | 1  | 3.2752 |
| 8     | 3250  | NorMuonH (NorMuon + hyperball + per-module init)    | 10 | 3.2778 |
| 11    | 3225  | NorMuon u/w-floor + Contra-Muon                     | 16 | 3.2785 |
| 14    | 3150  | + SOAP-Muon for MLP weights                         | 4  | 3.2776 |
| 16    | 3125  | + SOAP-Muon for attn with trust gate                | 8  | 3.2784 |
| 19    | 3125  | KL-SOAP-H (instead of NorMuonH stack)               | 6  | 3.2780 |
| 20    | 3030  | + Contra/Soft-Muon interpolation + tuned schedule   | 30 | 3.2790 |

## Wave 1 — assignments dispatched 2026-05-15

8 idle students → 8 fresh PRs on `auto-nanogpt-1gpu-r5`. Portfolio is 5
exploitation reproductions of known strong recipes + 3 exploration ideas.

| PR # | Student         | Hypothesis                                                            | Type         |
| ---- | --------------- | --------------------------------------------------------------------- | ------------ |
| 43   | g1r5-alphonse   | NorMuonH reproduction (record #8)                                     | exploit      |
| 44   | g1r5-askeladd   | Contra-Muon isolated on plain Muon                                    | exploit      |
| 45   | g1r5-edward     | Muon² sharper NS polynomial (record #7)                               | exploit      |
| 46   | g1r5-fern       | SOAP-Muon for MLP weights only (component of #14)                     | exploit      |
| 47   | g1r5-frieren    | MuonH reproduction (record #5)                                        | exploit      |
| 48   | g1r5-nezuko     | Cooldown shape sweep on plain Muon (5 shapes × 2 seeds)               | explore      |
| 49   | g1r5-tanjiro    | Lookahead wrapper over Muon (k×α grid)                                | explore      |
| 50   | g1r5-thorfinn   | Polyak/SWA tail averaging (τ×β grid)                                  | explore      |

All assignments specify:
- inline-only optimizer code (no third-party packages),
- predeclared step count for the seed batch (no per-seed early stopping),
- one screening seed before the n-seed confirmation batch,
- W&B group naming so related runs cluster automatically.

## Next research directions (post wave-1)

Once wave-1 results land, expected next levers (in priority order):

1. **Stack the wave-1 winners** along the public progression — e.g., if
   MuonH/Muon² confirm cleanly, compose Muon² + hyperball + per-module init
   (extends record #5/#7), then add Contra-Muon, then SOAP-MLP, mirroring
   the public path #5 → #14 → #16.
2. **Decoupled schedules per param-group** (Muon vs. AdamW aux) — record #8
   uses `h_cooldown_frac=1.0` vs. `aux_cooldown_frac=0.4`; sweep this on
   plain Muon and on the wave-1 winners.
3. **Fresh preconditioner mechanisms** not yet tried on this branch:
   - **KL-SOAP-H** (record #19): KL-divergence-style covariance update vs.
     Shampoo, see <https://arxiv.org/abs/2509.03378>.
   - **Newton-Muon** (record #15): activation-covariance right-precond
     before NS, refreshed every 64 steps.
   - **PMuon** (record #18): bilateral streaming covariance power precond.
   - **Aurora** (record #17): see Tilde Research's aurora-release.
4. **Initialization** — μP-style transfer (Yang et al.) of LR across
   per-module widths; tuned init std beyond record #5's three values.
5. **Direction normalization** — u/w floor (record #9), sign-aligned masking
   ("cautious"), update-norm clamps as Muon alternatives to weight decay.
6. **Schedule-free Muon** — Defazio et al.'s schedule-free formulation
   applied to orthogonalized updates; potential elimination of cooldown
   tuning entirely.
7. **Outer-loop wrappers** beyond Lookahead — MuLoCo K=1 outer Nesterov
   (record #13) wrapping a wave-1 winner.
8. **Pruning ablation** of any complex stacks we adopt — drop components one
   at a time to confirm each lever contributes statsig improvement.

## Standing constraints (do not re-derive)

- **Banned sources**: anything under `primeintellect.ai/auto-nanogpt` or the
  `PrimeIntellect-ai/experiments-autonomous-speedrunning` GitHub repo. Do not
  fetch, browse, search, summarize, or use as implementation references.
- **Benchmark contract**: keep dataset, batch size, architecture fixed; one
  fwd-bwd per optimizer step; no per-run early stopping on val loss.
- **Reporting**: every terminal result must include the `SENPAI-RESULT`
  marker plus the predeclared step count, n, mu, statsig margin, and rule
  outcome. NaN/missing `val/loss` is unacceptable.
- **GPU budget**: 1× 96 GB per student. Step-avg on 1 GPU at this target is
  ~2 hr per 3350-step run; plan run counts accordingly.
