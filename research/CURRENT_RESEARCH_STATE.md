# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-15 (boot)
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Current best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate + u/w-floor)

## Current research focus and themes

The leaderboard is dominated by **matrix preconditioners stacked on Muon**:
Contra-Muon (correlation correction), Soft-Muon (smooth polar relaxation),
Aurora (leverage equilibration), Newton-Muon (activation-covariance right
precond), NorMuon (row/col variance), PMuon (bilateral covariance power),
SOAP / KL-SOAP (Shampoo-style with diagonal Adam in eigenbasis), hyperball
constraints, MuLoCo outer Nesterov.

The best recipe (#20) is a **complex stack** with multiple interpolation
schedules between mechanisms. This means three under-explored angles:

1. **Stack pruning / ablations** — which components in #20 are load-bearing?
2. **Clean novel optimizers** — Schedule-Free, sign-based (Lion), ADOPT,
   AdamMini, Sophia, AdaBelief, K-FAC / Shampoo variants, SWAN, Galore, etc.
3. **Schedules and initialization** — WSD cooldowns, momentum/WD schedules,
   spectral / structured init, μP-style parameterization.

## Potential next research directions

- **Exploit #20:** retune LR/WD around the soft-muon ceil and SOAP frequency.
- **Newton-Muon + KL-SOAP** as a simpler alternative to the Contra-Soft stack.
- **Pruning of #20** to find the minimal load-bearing core.
- **Schedule-Free Muon** (Defazio polynomial-averaging trick).
- **WSD cooldown shape variants** (sqrt, 1/(1+x), cosine).
- **Spectral / orthogonal init** for QKV matrices.
- **Sign-based optimizer for aux groups** (Lion-Adam hybrid).
- **AdamH / hyperball retune** at low step counts.

## Notes

- Banned during this launch: Prime Intellect autonomous-run materials
  (`https://www.primeintellect.ai/auto-nanogpt` and the
  `experiments-autonomous-speedrunning` repo).
- All matrix changes must keep dataset / batch size / architecture fixed.
- No multiple fwd/bwd passes per step (rules out SAM).
- No per-run val-loss early stopping.
