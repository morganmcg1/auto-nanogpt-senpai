# SENPAI Research State

- 2026-05-15 — fresh launch, no experiments completed yet.
- No human-researcher directives recorded.
- Advisor branch: `auto-nanogpt-1gpu-r2`. W&B
  `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## Current research focus

The starter script implements Muon + aux Adam at lr=0.035, wd=0.025,
`cooldown_frac=0.7`, `train_steps=3350` — close to public record #10 (3250
steps). The public history shows roughly 320 steps of headroom above the
starter, and the current global best is record #20 (Contra-Soft Muon, 3030
steps).

The big jumps in the public record come from compounding three orthogonal
families: (a) preconditioning before/after Newton-Schulz (NorMuon, Newton-Muon,
PMuon, SOAP, KL-SOAP), (b) update-direction corrections (Contra-Muon,
Soft-Muon), and (c) norm/scale handling (hyperball constraint, u/w-floor,
per-module init std). Wave 1 spreads students across these families so we can
isolate which axes are reproducible on our single-GPU setup before stacking.

## Wave 1 (initial assignments)

| Student | Hypothesis family | Target step count |
| --- | --- | --- |
| g1r2-alphonse | NorMuon (clean, Frobenius renorm) | ~3250 |
| g1r2-askeladd | NorMuonH (NorMuon + hyperball + per-module init std) | ~3250 |
| g1r2-edward | Contra-Muon (operator-norm contra correction + u/w-floor) | ~3225 |
| g1r2-fern | Contra-Muon + SOAP on MLP weights | ~3175 |
| g1r2-frieren | MuLoCo outer Nesterov SGD wrapper on baseline Muon | ~3225 |
| g1r2-nezuko | Muon² (Adam variance before Newton-Schulz) | ~3325 |
| g1r2-tanjiro | Newton-Muon (activation-covariance right-preconditioning) | ~3275 |
| g1r2-thorfinn | PMuon (bilateral streaming covariance power preconditioning) | ~3225 |

## Potential next research directions

- **KL-SOAP + hyperball** (record #19): not in wave 1; queue after first
  preconditioner results land.
- **Aurora** (record #17): orthogonal projector — queue after Contra-Muon
  baseline is confirmed.
- **Soft-Muon kernel ablations** independent of Contra-Muon — the Soft-Muon
  shrinkage polynomial is a separate axis that can be combined with NorMuonH.
- **Attention SOAP with trust gate** (record #16) after MLP-SOAP confirms.
- **Power-law LR schedule** (record #20 uses power=1.2) — try on simpler
  stacks.
- **Per-module LR/WD tuning** (Newton-Muon used four different muon groups —
  may transfer to baseline Muon and NorMuon).
- **Predeclared seed-count confirmation runs** at the winning step count once
  any wave 1 idea beats starter at single-seed.

## Operational notes

- All runs must use `--wandb_group` (or `WANDB_RUN_GROUP`) so the advisor can
  aggregate seeds.
- For statsig at a single step count, seed counts of n=4 give a 3.278 mean
  ceiling; n=8 gives 3.2786 ceiling. Final claims must report all
  non-cherry-picked runs.
- Early-kill is permitted only for crashes, non-finite losses, or hopeless
  smoke tests — never as val-peeking.
