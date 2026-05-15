# Auto-NanoGPT-r3 Research State

- **Date**: 2026-05-15
- **Advisor branch**: `auto-nanogpt-r3`
- **Research tag**: `auto-nanogpt-r3`
- **W&B**: `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8)**: r3-alphonse, r3-askeladd, r3-edward, r3-fern, r3-frieren,
  r3-nezuko, r3-tanjiro, r3-thorfinn — 8 GPUs each.

## Latest human-team direction

None received yet on this branch.

## Current research focus

Reduce `speedrun/final_first_step_to_target` on the fixed modded-nanogpt track 3
benchmark from the starter-script baseline (Muon lr=.035 wd=.025 at 3350 steps)
toward the public record floor of ~3030 steps. We will explore three orthogonal
levers in parallel:

1. **Foundation tuning of the current Muon recipe** — confirm what the in-repo
   baseline really achieves, sweep `train_steps`, cooldown fraction, and
   per-module initialization. These produce reference points and small but
   reliable step-count wins to merge as the new advisor baseline.
2. **Muon-family optimizer mechanisms** — add hyperball Frobenius-norm
   constraints (MuonH), Adafactor-style short-axis variance preconditioning
   (NorMuon/NorMuonH), Muon² double-NS, and Contra-Muon's "anti-momentum"
   correction. Each isolates a single, well-defined algorithmic change so we can
   measure its real contribution before stacking.
3. **Preconditioned Muon directions** — SOAP-style running Shampoo
   eigenbasis preconditioning before NS orthogonalization, starting with MLP
   weights only (cheapest, biggest precedent in record #14).

## Wave 1 portfolio (3 foundation + 5 algorithmic)

| Student | Hypothesis | Track |
| - | - | - |
| r3-alphonse | Muon lr=.035 wd=.025 step-count sweep (n=4 each at 3275/3300/3325/3350) | Foundation |
| r3-thorfinn | Cooldown-fraction sweep (Muon group ∈ {0.4,0.6,0.8,1.0}; aux=0.4) | Foundation |
| r3-tanjiro | Per-module init study (attn.proj ×1.25, mlp.proj ×3, mlp.fc ×1.5 on Kaiming) | Foundation |
| r3-askeladd | MuonH (hyperball constraint), lr=.018, h_cooldown_frac=1.0 | Optimizer mechanism |
| r3-fern | NorMuonH (Adafactor preconditioning + hyperball, per-module init) | Optimizer mechanism |
| r3-frieren | Muon² (double NS), lr=.10 wd=.0125 β₂=.95 | Optimizer mechanism |
| r3-edward | Contra-Muon on top of baseline Muon lr=.035 wd=.025 | Optimizer mechanism |
| r3-nezuko | SOAP-Muon preconditioning for MLP weights only | Preconditioning |

## Next research directions (post-Wave 1)

- **Stack winners cleanly.** If MuonH and NorMuonH both ship, NorMuonH likely
  dominates (it contains MuonH). If init ships, fold into all later experiments.
- **Schedule innovations.** Power-law cooldown (record #20 mentions PowerCool),
  separate cooldown for different param classes, late-stage embed lr decay.
- **AdamW-side improvements.** Embed lr / scalar lr / lm_head lr are currently
  fixed; sweep these, especially around the embed lr=0.3 which is unusually
  high.
- **SOAP variants.** KL-SOAP (record #19), MuLoCo wrap (record #13), Soft-Muon
  mix (record #20). Each needs careful per-group tuning of `precondition_frequency`,
  `shampoo_beta`, and the lr-shape it implies.
- **Pruning experiments.** When 2-3 components ship into a stacked recipe,
  ablate each to verify it still pulls weight.
- **Fresh angles.** Newton-Muon-style activation-covariance right-preconditioner
  (record #15), Aurora (record #17), PMuon bilateral power preconditioning
  (record #18). Lower-precedent → screen with shorter step budgets first.

## Process notes

- All PRs must target `auto-nanogpt-r3`. Branches check out from
  `auto-nanogpt-r3`. Winners squash-merge back into `auto-nanogpt-r3` and
  update `BASELINE.md`.
- Banned: Prime Intellect autonomous-speedrunning materials. Allowed: the
  in-repo `records/track_3_optimization/` snapshot — those logfiles ARE the
  documented public references and contain fully-reproducible code.
- Predeclare `train_steps` and seed count for confirmation runs. No per-run val
  cherry-picking. Final marker line:
  `SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,...}`.
