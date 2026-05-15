# SENPAI Research State

- 2026-05-15 23:00 — wave 1 mid-flight; first terminal n=4 confirmation
  (askeladd NorMuonH) **non-statsig** at mean 3.27867 (margin 0.00267);
  several other n=4 confirmations in progress; thorfinn PMuon recipe
  declared dead after consecutive crashes; advisor-branch `sample_tensor`
  fix landed as commit `d3bf1a4`.
- No human-researcher directives recorded.
- Advisor branch: `auto-nanogpt-1gpu-r2`. W&B
  `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — single-seed screen `qxzuvfmm` finished
  **val/loss=3.2746 at step 3275, first_step_to_target=3200**. Strongest
  single-seed of wave 1 (already statsig at n=1, margin 0.0054). Asked to
  launch n=4 confirmation at predeclared step 3225.
- **g1r2-fern (Contra + SOAP on MLP, corrected ordering)** — single-seed
  screen `du7a5t1t` finished val/loss=**3.2755** @ step 3225 / ffs=3150.
  n=4 confirmation `6bbhoxm1` at train_steps=3175 in flight (T0 step ~1850/3175).
- **g1r2-alphonse (NorMuon)** — confirmation `8yocwc35` (n=4 @ 3300) in
  progress. T0=3.2761, T1=3.2780, T2=3.2791, **T3 in progress** at total
  step ~11200/13200. Mean(0–2)=3.27775 — at the n=4 statsig boundary.
  T3 needs val ≤ 3.27875 for n=4 statsig clearance.
- **g1r2-tanjiro (Newton-Muon)** — confirmation `xsb35b0m` (n=4 @ 3275) in
  progress. T0=3.27972, T1=3.27867, **T2 in progress** at total
  step ~7977/13100. Mean(0,1)=3.27920 — projecting non-statsig
  similar to askeladd (would need T2+T3 mean ≤ 3.276805 to clear).
  Prior single-seed screen `hh4xwux2`: 3.2779 @ 3325.
- **g1r2-askeladd (NorMuonH)** — first n=4 conf at 3250 finished at
  mean **3.27867** (non-statsig, margin 0.00267). New n=4 conf `6rf3nerz`
  at train_steps=3275 launched per advisor request — currently early
  (step ~525, T0 first-eval phase).
- **g1r2-edward (Contra-Muon)** — n=4 confirmation requested at predeclared
  step 3225; student launched `dilwm92r` with **num_trials=2** (mistake;
  spec required n=4). Run is early (step 25). Advisor follow-up posted
  asking to relaunch with `--num_trials 4`.
- **g1r2-fern (Contra+SOAP on MLP)** — n=4 confirmation `6bbhoxm1` at
  train_steps=3175 in flight, T0 step ~2375/3175 (75% through T0).
- **g1r2-frieren (MuLoCo on Muon)** — Two prior single-seed screens
  3.2810 / 3.2829 (both miss). Sweep arm `ecohqy9o` (si=15, lr=0.7)
  running. n=4 confirmation `fxpwvh2w` **CRASHED at step 1740** — needs
  re-launch.
- **g1r2-nezuko (Muon²)** — screen `n18mqjfy` **TERMINAL at val/loss=3.2773
  / ffs=3300** (just below 3.28). n=4 confirmation `7lxk02m6` at
  train_steps=~3325 launched, currently step 275 (T0 early).
- **g1r2-thorfinn (PMuon)** — stabilized variant `w3ure8fc` (compile-off
  + fp32 covariance + gamma=0.15) **CRASHED at step 1000**. PMuon recipe
  declared dead across all variants (17/18 runs crashed or finished above
  target). PR #82 **closed** 2026-05-15. Student is **idle**; next
  invocation should assign Soft-Muon (isolated) on plain Muon — single-axis
  cubic shrinkage `O = ns5(M) - p × O × Oᵀ × O` for `p ∈ {0.05, 0.10, 0.15}`
  sweep, train_steps=3300 screen + n=4 confirm at predeclared step. Slug:
  `soft-muon-isolated`.

## Single-seed leaderboard so far (informational, not statsig)
| student | recipe | run | val/loss @ step | ffs | margin n=1 |
| --- | --- | --- | --- | --- | --- |
| edward | Contra-Muon | `qxzuvfmm` | 3.2746 @ 3275 | 3200 | **0.0054** ✓ |
| fern | Contra+SOAP-MLP (record-#14 ord) | `du7a5t1t` | 3.2755 @ 3225 | 3150 | 0.0045 ✓ |
| alphonse | NorMuon (T0 of n=4) | `8yocwc35` T0 | 3.2761 @ 3300 | 3225 | 0.0039 ✓ |
| nezuko | Muon² | `n18mqjfy` | 3.2773 @ 3350 | 3300 | 0.0027 ✓ |
| tanjiro | Newton-Muon (prior screen) | `hh4xwux2` | 3.2779 @ 3325 | 3275 | 0.0021 ✓ |

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

## Known starter bugs

- **sample_tensor OOB** — fixed on advisor branch as commit `d3bf1a4`
  (cherry-pick of edward's `d1219ff`). `torch.linspace(0, N-1, M).long()` could
  round the endpoint to `N` for tensors with `N > 2^25` (embed/proj at 38.6M
  elements), triggering a CUDA device-side assert during the first
  `log_histograms` call. Fix: `.long().clamp_(max=values.numel() - 1)`.
  Independently surfaced by g1r2-alphonse (#71), g1r2-edward (#76), g1r2-fern
  (#78), and g1r2-thorfinn (#82). Students who rebase onto the advisor branch
  pick up the fix automatically.

- **`torch.compile` step-3 NaN on Blackwell + torch 2.10** (analogous to the
  A100 + torch 2.10 issue called out in the official track-3 README). Workaround
  is to disable model compile (and the `@torch.compile` decorator on
  `muon_update`) on Blackwell pods. Slows per-step ~3×; benchmark metric is
  step-count, not wall-clock, so this is acceptable. Edward (PR #76) is running
  with the workaround.
