# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-15 (post-dispatch poll #3, ~16:45 UTC)
- **Most recent research direction from human researcher team:** none yet (no
  open GitHub issues for `auto-nanogpt-1gpu-r5` or team broadcast).
- **Outstanding methodological adjustments:**
  - PR #48 (nezuko, cooldown shape sweep) — student caught that the
    original shape spec did not preserve total LR integral; sent back WIP
    to renormalize per-shape `base_lr` (multipliers: linear/cosine=1.000,
    power_α1.2=1.051, power_α0.6=0.881, trapezoidal=0.765). Cosine remains
    the cleanest single-arm comparison.
  - **PR #45 (edward, Muon²) — bad PR description by advisor.** Original
    instructions described Muon² as a sharper Newton–Schulz polynomial,
    but the reference recipe (record #7, `results/20260501_muonsq/`) keeps
    the **standard** NS coefficients `a,b,c=2,-1.5,0.5`, 12 iterations,
    and adds **Adam-style second-moment preconditioning of the momentum
    buffer before NS**. Correction comment posted on PR #45 at 16:34 UTC
    with the correct `muon_sq_update` mechanism (`v` buffer with
    `β₂=0.95, ε=1e-10`, divide update by `sqrt(v)+ε` *before* the
    unmodified NS) and hyperparameters (`lr=0.10, wd=0.0125, μ=0.95`).
    Sent back to `status:wip`. Edward burned ~10 NaN smoke runs trying to
    sharpen the NS polynomial in bf16 before the correction landed — that
    blow-up was a direct consequence of the bad description, not a
    student-side bug.

## Wave-1 in-flight signal (poll #3; single-seed unless noted; **not** terminal)

Live W&B status as of 2026-05-15T16:45Z. All 7 of 8 wave-1 students have
healthy live runs; only edward (Muon²) is still stuck pending the recipe
correction above.

| PR | Student  | Live run                                  | Step  | val/loss | Notes                                          |
| -- | -------- | ----------------------------------------- | ----- | -------- | ---------------------------------------------- |
| 43 | alphonse | `normuonh-confirm`                        | 2800  | 3.3466   | confirmation seed in progress                  |
| 44 | askeladd | `contra-muon-confirmation-n8-3350`        | 2050  | 3.4453   | confirmation seed in progress                  |
| 45 | edward   | `muon-squared-smoke` (latest)             | crash | —        | pre-correction smoke; correction posted 16:34  |
| 46 | fern     | `soap-mlp-isolated`                       | 1975  | 3.4530   | screening in progress                          |
| 47 | frieren  | `muonh-screen3325-s1`                     | 125   | 4.8532   | restarted with grad clip; clean grads          |
| 48 | nezuko   | `cooldown-linear-seed42`                  | 3015  | 3.3112   | post-fix linear baseline ~ on track            |
| 49 | tanjiro  | `lookahead-k5-a0.8-seed0`                 | 2409  | 3.3864   | second cell of k×α grid                        |
| 50 | thorfinn | `polyak-tau0.10-beta0.999`                | 3225  | 3.3018   | tail-EMA window now active                     |

Earlier single-seed screens from poll #2 still hold (alphonse NorMuonH
matched record #11; askeladd isolated Contra-Muon ≈ baseline; tanjiro
k=5/α=0.5 missed at step 3350). Each of those runs is now followed by a
confirmation or next-cell run as the screening matrix continues.

**Important:** all of the above are single-seed screening numbers. Treat
them as *signal that the recipe runs and approaches the target*, **not as
record claims**. Terminal verdicts wait for the predeclared n-seed
confirmation batches the PRs asked for.

## Pre-existing starter bug — `sample_tensor` / histogram telemetry

Three independent students (alphonse on PR #43, askeladd on PR #44, fern on
PR #46) hit and fixed the same crash in
`records/track_3_optimization/train_gpt_simple.py`: `sample_tensor` (used
by histogram logging) computed sample indices with a path that could
produce CUDA `IndexKernel ... in` assertion failures on the very first
histogram log. The fix is small and orthogonal to any optimizer
hypothesis. Cherry-pick the cleanest student bug-fix commit into the
advisor branch so it is no longer rediscovered by every wave-1 student.

## Infrastructure note — rate-limit-induced polling stalls

Between approximately 13:30 and 15:20 UTC the GitHub REST/GraphQL secondary
rate limits were exhausted (cross-fleet usage at burst peaks). Student
heartbeat pollers fail-closed on a 403 with "No assigned PRs or issues" and
sleep 300s. The `stale_wip` flag flips when the PR has no recent comment
during that window, even though the student pod is actively training a
prior screening run. Limits are recovering on the natural reset cadence;
do not treat `stale_wip` as a real student stall during this poll cycle.

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
