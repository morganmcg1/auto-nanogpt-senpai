# SENPAI Research State — auto-nanogpt-r4

- **Date:** 2026-05-15
- **Human researcher directives:** none received yet (no team issues open).
- **Target:** Reduce `speedrun/final_first_step_to_target` on the modded-nanogpt
  track 3 optimizer benchmark below the 3350-step starter. Public best is 3030
  steps (n=30) at PR #20; closing the gap is the long-term goal.

## Current research focus

Wave 1 is an **establishment wave** — we have zero in-repo runs and need to:

1. Stand up several optimizer recipes from the record list so future PRs can
   build on real, reproduced baselines instead of just the bare Muon starter.
2. Sweep cheap levers (schedule, init) on the simplest Muon recipe to expose
   sensitivities and produce diagnostic telemetry that informs later waves.
3. Plant one or two genuinely fresh optimizer ideas alongside the
   reproductions so the portfolio is not 100% retread.

### First-wave portfolio (assignments)

| Student | Hypothesis | Family |
| - | - | - |
| r4-alphonse | NorMuon (Adafactor-style row/col precond over Muon NS) | Reproduction of #10 |
| r4-askeladd | Muon² (squared Newton–Schulz) + confirmation seeds | Reproduction of #7 (n=1 → n≥4) |
| r4-edward | AdamH (Adam + hyperball constraint) | Non-Muon optimizer |
| r4-fern | MuonH (Muon + hyperball constraint) | Reproduction of #5 |
| r4-frieren | Cooldown-shape sweep on Muon baseline | Schedule lever |
| r4-nezuko | Per-module init_std sweep on Muon baseline | Init lever |
| r4-tanjiro | Cautious-Muon (sign-aligned update masking) | Fresh mechanism |
| r4-thorfinn | MuLoCo outer Nesterov wrap around plain Muon | Outer-loop wrap |

## Potential next research directions

Detailed brainstorm in `research/RESEARCH_IDEAS_2026-05-15_advisor-boot.md`.
The 13-idea list ranked by expected value/GPU-hour. Top candidates for wave 2,
contingent on wave-1 results:

- **PSGD Kron** (replaces Muon, lr=0.0005 wd=0.625 — independent optimizer
  family with high upside, medium implementation cost).
- **Contra-Muon + Soft-Muon stack on NorMuon**, contingent on alphonse's
  NorMuon landing (path toward record #20 territory).
- **AdEMAMix slow-EMA buffer inside Muon** (small, additive mechanism).
- **EMA weight averaging for eval** (low risk, purely additive, tests whether
  the cooldown is doing redundant work).
- **Schedule-Free AdamW on Adam groups only** (isolated risk; tests whether
  the embed/lm-head cooldown is a bottleneck).
- **Depth-scaled LR** (layerwise-LR-decay on Muon, very cheap).
- **NS-iteration count scaling** (cheaper compute, low risk).

Other candidates kept on the bench: Lion, GaLore-on-MLP-fc, Sophia-H,
LaProp on Adam groups, Adan. Wave-3+ material.

## Operating notes

- Statistical rule `(3.28 - mu) * sqrt(n) >= 0.004` enforced on all final
  claims. Screening at low n=1 is OK to triage; merges require terminal
  `SENPAI-RESULT` markers and meeting the stat-sig rule at the predeclared
  step count.
- Prime Intellect's autonomous-run materials are banned sources for this
  launch.
