# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-15 (post-dispatch poll #4, ~17:25 UTC)
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

## Wave-1 in-flight signal (poll #4; single-seed unless noted; **not** terminal)

Live W&B status as of 2026-05-15T17:25Z. 7 of 8 students continue to advance
their screening or confirmation matrices. Best completed single-seed screen
**`final_first_step_to_target`** numbers so far:

| PR | Student  | Best completed screen           | val/loss | `ffs`    | Note                                                      |
| -- | -------- | ------------------------------- | -------- | -------- | --------------------------------------------------------- |
| 43 | alphonse | `normuonh-screen` (3250 steps)  | 3.2785   | **3225** | matches record #8 ballpark (record #8 mu=3.2778 n=10)     |
| 44 | askeladd | `contra-muon-screening`         | 3.2784   | 3325     | isolated Contra-Muon ≈ baseline                           |
| 48 | nezuko   | `cooldown-linear-seed42`        | 3.2784   | 3300     | post-fix linear baseline; cosine seed now running         |
| 49 | tanjiro  | `lookahead-k5-a0.8-seed0`       | 3.282    | -1       | k=5,α=0.8 missed at full 3350 budget; k=10,α=0.5 running  |
| 50 | thorfinn | `polyak-tau0.10-beta0.999`      | 3.297    | -1       | tail EMA missed target; tau=0.20 now running              |

Active runs (no terminal verdict yet):
- alphonse `normuonh-confirm` running (confirmation seed in progress)
- askeladd `contra-muon-confirmation-n8-3350` at step ~3225, val/loss 3.285
- fern `soap-mlp-isolated` at step ~3125, val/loss 3.285 (clean grads)
- nezuko `cooldown-cosine-seed42` at step ~775, ramp phase
- thorfinn `polyak-tau0.20-beta0.999` at step ~1000, ramp phase
- tanjiro `lookahead-k10-a0.5-seed0` at step ~200, ramp phase
- frieren `muonh-screen3325-s1` **crashed at step ~600** — advisor comment
  posted requesting torch 2.11 confirmation + per-layer grad-norm trace
- edward — no post-correction runs yet; advisor follow-up posted (#45)
  pointing them at both the corrected Muon² mechanism AND the torch 2.11
  fix nezuko diagnosed

**Important:** all of the above are single-seed screening numbers. Treat
them as *signal that the recipe runs and approaches the target*, **not as
record claims**. Terminal verdicts wait for the predeclared n-seed
confirmation batches the PRs asked for.

**Most promising direction so far:** alphonse `NorMuonH` (record #8
reproduction). One-seed screen hit `ffs=3225` at 3250 steps, in line with
the record #8 mu=3.2778 across n=10. If the n=10 confirmation seed batch
holds, this is on track to match a known strong recipe and is the natural
backbone to start stacking Contra-Muon / SOAP-MLP onto in wave 2.

## Pre-existing starter bugs — fixed in-flight by wave-1 students

Two orthogonal infrastructure bugs were discovered and fixed by students
during wave-1; both will ride into the advisor branch via the squash merge
of the first winning wave-1 PR. Advisor comments acknowledging both fixes
posted on the relevant PRs.

1. **`sample_tensor` float32 rounding** (PRs #43, #44, #46 independently
   fixed; #48 documented root cause). In
   `records/track_3_optimization/train_gpt_simple.py` →
   `sample_tensor`, `torch.linspace(0, n-1, max_samples, dtype=float32,
   device='cuda').long()` rounds the last index *up* to `n` when `n >
   2^24`, which then triggers a CUDA `IndexKernel ... in` assertion in
   `log_histograms`. Fix: cast `linspace` through `float64`. Fires on
   the larger embed / proj weight tensors only, so smaller tensors mask
   the bug until those are histogrammed.

2. **`torch==2.10` + `model.compile` produces NaN at step 2** (diagnosed
   by g1r5-nezuko, PR #48). The starter README warns about this for A100;
   it reproduces on the Blackwell node too — grad/max_abs explodes to
   ~`bf16-max` at step 2 regardless of optimizer or seed. Fix:
   `pip install torch==2.11` (also update `requirements.txt`). nezuko
   verified clean training curves on 2.11. This is **the most likely
   cause of every student's ~147M-nonfinite smoke run** observed earlier;
   it is *not* a Muon² polynomial issue, not a MuonH init issue, not a
   SOAP-MLP issue — it is a torch/`model.compile` issue. Wall-clock cost
   ~3.0 s/step on 2.11 vs. ~1.9 s/step on 2.10 (still well inside the
   timeout). The advisor has informed edward (#45) and frieren (#47),
   both of whom may have been hitting this rather than recipe issues.

## Infrastructure note — rate-limit-induced polling stalls (recurring)

The GitHub REST core rate limit has been exhausted twice today during
wave-1 dispatch: a long window ~13:30–15:20 UTC and a second hit ~16:43
UTC (5000/5000 core used; reset ~16:59). Student heartbeat pollers
fail-closed on a 403 with "No assigned PRs or issues" and sleep 300s,
which causes the watchdog `stale_wip` flag to flip on PRs whose student
pods are in fact actively training. The advisor poll #3 watchdog listed
**all 7 of the still-WIP wave-1 PRs as `stale_wip`**, but W&B confirms 7
of 8 students have healthy live runs in progress (only edward on PR #45
is stuck, and that is a recipe-correction issue, not a polling-stall
issue). **Do not treat `stale_wip` as a real student stall during these
windows — verify against W&B first.** Limits recover on the natural reset
cadence; no advisor intervention needed beyond this note.

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
