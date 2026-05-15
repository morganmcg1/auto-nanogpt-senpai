# SENPAI Research State

- 2026-05-15 23:30 — wave 1 mid-flight; first terminal n=4 confirmation
  (askeladd NorMuonH) **non-statsig** at mean 3.27867 (margin 0.00267);
  several n=4 confirmations in progress; PMuon dead + Soft-Muon assigned;
  frieren MuLoCo si=15 sweep arm missed (3.2815); advisor-branch
  `sample_tensor` fix landed as commit `d3bf1a4`.
- No human-researcher directives recorded.
- Advisor branch: `auto-nanogpt-1gpu-r2`. W&B
  `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — n=4 confirmation `zsqazpmr` (num_trials=4,
  train_steps=3225) **running** at step ~425/3225 of T0. Student correctly
  relaunched with n=4 after killing the erroneous n=2 `dilwm92r`. Expected
  wall-clock ~21.5h for all 4 seeds. Single-seed screen `qxzuvfmm` was
  **val/loss=3.2746 @ 3275 / ffs=3200** (strongest in wave 1, margin 0.0054).

- **g1r2-fern (Contra+SOAP on MLP)** — n=4 confirmation `6bbhoxm1` at
  train_steps=3175. **T0 terminal: val/loss=3.2792, ffs=3150.** T1 in
  progress (step ~3526, T1 step ~351). T0 is 0.0037 above the screen's 3.2755
  — on the unlucky side of seed variance. Need T1–T3 to average ≤ 3.2776
  for n=4 statsig.

- **g1r2-alphonse (NorMuon)** — confirmation `8yocwc35` (n=4 @ 3300) in
  progress. T0=3.2761, T1=3.2780, T2=3.2791, **T3 in progress** at total
  step ~12453/13200. Mean(0–2)=3.27775 — at the n=4 statsig boundary.
  T3 needs val ≤ 3.27875 for n=4 statsig clearance. Outcome TBD.

- **g1r2-tanjiro (Newton-Muon)** — confirmation `xsb35b0m` (n=4 @ 3275) in
  progress. T0=3.27972, T1=3.27867, **T2 in progress** at total
  step ~9252/13100. Mean(0,1)=3.27920 — projecting non-statsig
  (would need T2+T3 average ≤ 3.276805, unlikely given T0/T1 at 3.279).

- **g1r2-askeladd (NorMuonH)** — first n=4 conf at 3250: mean 3.27867
  (non-statsig). New n=4 conf `6rf3nerz` at train_steps=3275, currently
  at total step ~1825 (T0 still in training phase, no terminal yet).

- **g1r2-frieren (MuLoCo on Muon)** — 3 out of 3 single-seed screens missed
  the 3.28 target: `bqfv4523`=3.2829, `q57yhybv`=3.2810, `ecohqy9o` (si=15,
  lr=0.7)=**3.2815 (terminal, reached=0)**. si=60/lr=0.5 corner NOT yet
  launched — frieren was about to launch it. Pivot decision pending that
  result. n=4 confirm `fxpwvh2w` was correctly killed (auto-launch before
  sweep plan was set). Advisor asked frieren to launch si=60/lr=0.5 next.

- **g1r2-nezuko (Muon²)** — screen `n18mqjfy` terminal at val/loss=**3.2773
  / ffs=3300** (margin 0.0027). n=4 confirmation `7lxk02m6` at predeclared
  train_steps=3325 running at total step ~1575 (T0 training phase).

- **g1r2-thorfinn (Soft-Muon isolated)** — PMuon closed (PR #82, all variants
  crashed). Now assigned **Soft-Muon isolated** (PR #103, branch
  `g1r2-thorfinn/soft-muon-isolated`). Student should be picking up the new
  PR on next poll cycle. Hypothesis: Soft-Muon polynomial `x^(1-p)` at p=0.1,
  annealed blend 0→0.8 from step 2500 to end, on plain Muon. Smoke then
  screen at train_steps=3325.

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
starter, and the current global best is record #20 (Contra+Soft-Muon, 3030
steps).

Five out of eight wave 1 students have produced single-seed results that cross
3.28 (all ✓ in leaderboard above). The critical question now is whether those
results reproduce statsig at n=4. First terminal n=4 (askeladd NorMuonH)
narrowly missed (mean 3.27867, need ≤ 3.278). Alphonse NorMuon T3 is right at
the boundary. The n=4 confirmation campaign continues.

**Confirmed dead (non-reproducible) on this setup:**
- PMuon (thorfinn): numerically unstable across all stabilization attempts.
- MuLoCo on plain Muon (frieren, 3 screens): break-even with starter, not an
  improvement.

**Next assignments queued:**
- Thorfinn → Soft-Muon isolated (PR #103) — in progress.
- After frieren si=60 screen: if both corners miss → pivot frieren to
  MuLoCo wrapping a confirmed inner optimizer (NorMuon or Contra-Muon if those
  clear n=4).

## Wave 1 assignments

| Student | Hypothesis family | PR | Status |
| --- | --- | --- | --- |
| g1r2-alphonse | NorMuon (clean Frobenius renorm) | #71 | n=4 conf T3 running |
| g1r2-askeladd | NorMuonH (NorMuon + hyperball + per-module init) | #74 | n=4 conf @3275 early |
| g1r2-edward | Contra-Muon (contra correction + u/w-floor) | #76 | n=4 conf @3225 running |
| g1r2-fern | Contra-Muon + SOAP on MLP | #78 | n=4 conf T1 running |
| g1r2-frieren | MuLoCo on Muon | #79 | sweep si=60 pending |
| g1r2-nezuko | Muon² (Adam var before NS) | #80 | n=4 conf @3325 running |
| g1r2-tanjiro | Newton-Muon (act-cov right-precond) | #81 | n=4 conf T2 running |
| g1r2-thorfinn | Soft-Muon isolated | #103 | **newly assigned** |

## Potential next research directions

- **KL-SOAP + hyperball** (record #19): queue after preconditioner results land.
- **Aurora** (record #17): orthogonal projector — queue after Contra-Muon
  baseline is confirmed.
- **Soft-Muon + NorMuonH combination** (record #20 core stack): natural follow-up
  once Soft-Muon isolated baseline is established.
- **Attention SOAP with trust gate** (record #16) after MLP-SOAP confirms.
- **Power-law LR schedule** (record #20 uses power=1.2) — try on simpler stacks.
- **MuLoCo wrapping confirmed inner optimizer** (NorMuon or Contra-Muon) — queue
  for frieren once wave 1 n=4 confirmations land.
- **Per-module LR/WD tuning** — Newton-Muon used 4 different Muon groups;
  may transfer to baseline Muon and NorMuon.

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
  A100 + torch 2.10 issue called out in the official track-3 README). Workaround:
  disable model compile (and the `@torch.compile` decorator on `muon_update`)
  on Blackwell pods. Slows per-step ~3×; benchmark metric is step-count not
  wall-clock, so this is acceptable.
