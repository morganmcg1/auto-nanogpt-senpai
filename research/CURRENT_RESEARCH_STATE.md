# SENPAI Research State

- 2026-05-16 02:00 — **PR #71 MERGED**: alphonse NorMuon n=4 @ train_steps=3300,
  mean=3.27800, statsig margin=0.00401. NorMuon is now the advisor-branch baseline
  (commit `1aeb964`). Tanjiro Newton-Muon n=4 @ 3275 non-statsig (bad T3 seed
  at 3.2813); re-run at 3325 requested. Frieren MuLoCo-plain-Muon dead (4/4
  corners missed); pivoted to MuLoCo+NorMuon (PR #109). Askeladd/nezuko/fern
  confirmations progressing. Edward early.
  Advisor branch: `auto-nanogpt-1gpu-r2`.
- No human-researcher directives recorded.
- W&B `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — n=4 confirmation `zsqazpmr` (num_trials=4,
  train_steps=3225) **running** at step ~1050/12900 (8.1%). No trial data yet.
  Expected wall-clock ~21.5h total. Single-seed screen `qxzuvfmm` was
  **val/loss=3.2746 @ 3275 / ffs=3200** (strongest in wave 1, margin 0.0054).

- **g1r2-fern (Contra+SOAP on MLP)** — n=4 confirmation `6bbhoxm1` at
  train_steps=3175. T0=3.27920, **T1=3.27811** (ffs=3150 both). T2 in progress
  (~56%). mean(T0,T1)=3.27866. For n=4 statsig, T2+T3 need mean ≤ 3.27735 —
  steep. Likely non-statsig at 3175; plan is re-run at 3200-3225 steps.

- **g1r2-alphonse (NorMuon) ✅ MERGED** — confirmation `8yocwc35` (n=4 @ 3300)
  mean=3.27800, statsig margin=0.00401. **PR #71 squash-merged** into
  `auto-nanogpt-1gpu-r2` at commit `1aeb964`. NorMuon is now the advisor-branch
  baseline. BASELINE.md updated: train_steps=3300, mean=3.27800, ffs=3256.25.

- **g1r2-tanjiro (Newton-Muon)** — `xsb35b0m` (n=4 @ 3275) **TERMINAL,
  non-statsig**. T0=3.27972, T1=3.27867, T2=3.27768, T3=**3.28128** (bad seed,
  missed target). mean=3.27934, statsig margin=0.001328 < 0.004. Recipe is
  real (3/4 seeds cleared 3.28, T2=3.2777 excellent). Sent back for fresh n=4
  at **train_steps=3325** (predeclared). High seed variance needs more cooldown.

- **g1r2-askeladd (NorMuonH)** — n=4 conf `6rf3nerz` at train_steps=3275:
  T0=3.27781, ffs=3225 (T1 in progress at total step ~4151).

- **g1r2-frieren (MuLoCo+NorMuon)** — PR #79 CLOSED (all 4 plain-Muon corners
  missed 3.28: 3.2829/3.2810/3.2815/3.2865). **New PR #109** (branch
  `g1r2-frieren/muloco-normuon`) assigned. Hypothesis: MuLoCo outer-Nesterov
  wrapping NorMuon (record #13 stack). Student picks up on next poll cycle.

- **g1r2-nezuko (Muon²)** — n=4 confirmation `7lxk02m6` at train_steps=3325:
  T0=3.27788, ffs=3300 (T1 in progress at total step ~3901, ~29% T2).
  Single-seed screen `n18mqjfy` terminal at 3.2773.

- **g1r2-thorfinn (Soft-Muon isolated)** — Newly assigned PR #103. Student
  picking up on next poll cycle. Hypothesis: Soft-Muon polynomial `x^(1-p)`
  at p=0.1, annealed blend 0→0.8 from step 2500 to end, on plain Muon.
  Smoke then screen at train_steps=3325.

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
results reproduce statsig at n=4. First terminal n=4 (alphonse NorMuon) passed
narrowly (mean 3.27800, margin 0.00401). NorMuon is the new baseline.

**Confirmed dead (non-reproducible) on this setup:**
- PMuon (thorfinn): numerically unstable across all stabilization attempts.
- MuLoCo on plain Muon (frieren, 4 sweep corners all missed 3.28:
  3.2829/3.2810/3.2815/3.2865). si=60/lr=0.5 was the worst corner.
  Plain Muon's NS5 already smooths the gradient direction — outer Nesterov
  adds no value. MuLoCo DOES work on NorMuon (record #13), which is next.

**Next assignments queued:**
- Thorfinn → Soft-Muon isolated (PR #103) — in progress.
- Alphonse → rebase PR #71 to resolve merge conflicts, then immediate merge.
- Tanjiro → fresh n=4 at train_steps=3300 expected after T3 lands non-statsig.
- Frieren now on MuLoCo+NorMuon (PR #109) — picking up next poll cycle.

## Wave 1 assignments

| Student | Hypothesis family | PR | Status |
| --- | --- | --- | --- |
| g1r2-alphonse | NorMuon (clean Frobenius renorm) | #71 | Rebase for merge conflicts |
| g1r2-askeladd | NorMuonH (NorMuon + hyperball + per-module init) | #74 | n=4 conf @3275 T1 running |
| g1r2-edward | Contra-Muon (contra correction + u/w-floor) | #76 | n=4 conf @3225 early (8%) |
| g1r2-fern | Contra-Muon + SOAP on MLP | #78 | n=4 conf @3175 T1 running |
| g1r2-frieren | MuLoCo+NorMuon (record #13 stack) | #109 | **newly assigned** |
| g1r2-nezuko | Muon² (Adam var before NS) | #80 | n=4 conf @3325 T1 running |
| g1r2-tanjiro | Newton-Muon (act-cov right-precond) | #81 | non-statsig @3275; re-run @3325 pending |
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
- **Tanjiro Newton-Muon at longer steps** — if T3 non-statsig at 3275, re-run
  at train_steps=3300.

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
