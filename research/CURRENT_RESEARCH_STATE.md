# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #20, ~06:30 UTC)
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

## Wave-1 in-flight signal (poll #9; single-seed unless noted; **not** terminal)

Live W&B status as of 2026-05-15T21:35Z. All 8 students remain active. The
**explore side** (Lookahead, Polyak/SWA, cooldown-shape) has fully
screened: Lookahead is a clean negative, Polyak found one in-noise
single-seed signal at (τ=0.20, β=0.995), cooldown-shape so far has no
shape beating linear. The **exploit side** (NorMuonH, Contra-Muon,
SOAP-MLP, MuonH, Muon²) is mid-confirmation; clearest signal remains
alphonse NorMuonH with confirmed `ffs=3225` across two seeds, but
seeds 3 and 4 came in higher (`-1`, `3250`), softening the early signal.

### Best completed single-seed screens

| PR | Student  | Best completed screen        | val/loss    | `ffs`    | Note                                                  |
| -- | -------- | ---------------------------- | ----------- | -------- | ----------------------------------------------------- |
| 43 | alphonse | `normuonh-screen` (3250 st)  | 3.2785      | **3225** | matches record #8 ballpark (mu=3.2778 n=10)           |
| 44 | askeladd | `contra-muon-screening`      | 3.2784      | 3325     | isolated Contra-Muon ≈ baseline                       |
| 46 | fern     | `soap-mlp-screen`            | (seed-1)    | **3200** | faster than rec #14                                   |
| 48 | nezuko   | `cooldown-linear-seed42`     | 3.2784      | 3300     | linear ≈ baseline; other shapes worse                 |
| 49 | tanjiro  | `lookahead-k10-a0.8-seed0`   | **3.27963** | 3350     | best cell = ceiling, ≈ plain Muon baseline (clean neg)|
| 50 | thorfinn | `polyak-tau0.20-beta0.995`   | **3.2779**  | **3300** | best of 4-cell grid; n=6 confirmation in flight       |
| 50 | thorfinn | `polyak-tau0.30-beta0.995`   | 3.2786      | **3300** | tied with τ=0.20 on ffs; 0.0007 nats worse on val     |

### Active runs as of ~00:45 UTC (poll #12)

- **alphonse** `normuonh-confirm` at step ~17.4k (≈mid-seed-5+ of 8);
  seed history `[3225, 3225, -1, 3250, ...]` — strongest exploit-side
  signal, mild softening at seed-3. Continue through full n=8.
- **askeladd** `contra-muon-confirmation-n8-3350` at step ~23.7k
  (~88% complete, trial-8 of 8 in flight). **Per-trial recap (poll #18):**
  trial-1 val=3.27779 ffs=3300 ✓; trial-2 val=3.28068 ffs=-1 (narrow
  miss); trial-3 ffs=3325 ✓; trial-4 ffs=3325 ✓; trial-5 ffs=3300 ✓;
  trial-6 ffs=3300 ✓; trial-7 ffs=3325 ✓; trial-8 in flight at step
  ~23.7k. **6 of 7 completed trials hit target.** ffs cluster
  [3300, -1, 3325, 3325, 3300, 3300, 3325] — well above new baseline
  ffs=3200. Earlier "val=10.83 diverged" reading was a W&B sampling
  artifact; `grad/nonfinite_count=0` throughout, max grad scale stable.
  Won't merge but will land as clean n=8 reference for isolated
  Contra-Muon ≈ plain Muon.
- **fern** `soap-mlp-isolated` at step ~16.2k (≈mid-seed-5 of n); seed-1
  ffs=3200, latest val approaching 3.280 — high seed-to-seed variance.
- **frieren** `muonh-record5-repro-confirm-n8` at step ~11.7k (mid-seed-4
  of 8); seeds 1-3 final val/loss `[3.287, 3.301, 3.305]`, **none hit
  target**. Best is seed-1 at 3.287 (0.007 above target). Record #5
  mu=3.2782; frieren's three terminal val/losses are 0.009-0.027
  *above* record #5 mu — MuonH reproduction may be incomplete (mul
  pliers ×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc applied to default
  Kaiming init?). Run is clean (no NaNs, no crashes post torch 2.11);
  the "7 crashes" any surface W&B scan reports are all pre-torch-2.11
  stale smokes from earlier in the day, NOT active failures.
- **edward** `muon-squared-3325-confirm` (run `ihc4lzo8`, n=8) at
  global step ~11.2k (trial-3 of 8 in flight; post-trial-2). Terminal
  trials so far: trial-0 val=3.2793 ffs=3325; trial-1 val=3.2777
  ffs=3300. Two-seed running mu ≈ 3.2785 — essentially at the new
  baseline mu=3.27744. **Under the new baseline, Muon² needs n=8
  mu ≤ ~3.27603 to merge** (`(3.27744 - mu) × sqrt(8) ≥ 0.004`).
  ffs cluster [3325, 3300] is materially slower than the new baseline
  ffs=3200; even a great mu wouldn't make Muon² beat the baseline on
  primary metric unless ffs comes in lower on later trials. Zero
  NaN/nonfinite. Status ack posted to PR #45 with this context (and
  flagged Muon² × SOAP-MLP as the natural wave-2 stack since the
  preconditioners are orthogonal). **Continue run as predeclared,
  no early stop.**
- **nezuko** (cooldown sweep): 7/8 cells terminal (1 more cell in flight).
  Aggregate **mu=3.28324, std=0.00418 — MISSES new baseline by +0.00580**.
  Best variants: `linear-seed42` val=3.27797 ffs=3300; `power_alpha1p2`
  val=3.27844 ffs=3300. `cosine` and `power_alpha0p6` miss target (ffs=-1).
  Linear cooldown is the strongest shape but still slower than new
  baseline ffs=3200. Clean negative on cooldown shape as a standalone
  wave-1 lever — but linear-cooldown is the recipe already used by the
  SOAP-MLP winner, so this is more "confirmation that nothing exotic on
  cooldown shape helps plain Muon" than a surprise.
- **tanjiro** (PR #98 **CLOSED 2026-05-16 05:26 clean negative**):
  Student took Option A as recommended. All three cells miss: lrx1.0
  val=3.3183, lrx1.5 val=3.3237, lrx2.0 killed at step 2600 trending
  worse. Val strictly increases with LR mult (LR compensation
  mechanistically refuted). Mask engaged (0.61–0.65); failure is
  NS curvature-filtering itself being harmful, not mask degeneration.
  **Tanjiro reassigned to PR #121 (Schedule-free Muon, dispatched 05:30).**
- **thorfinn** (Polyak/SWA PR #50): n=6 confirmation on (τ=0.20, β=0.995)
  3/6 terminal on the pure confirm cell (prior 4/6 count contaminated
  the β=0.999 arms). **Pure n=3 mu=3.27798 std=0.00086** — seeds all
  cleanly sub-3.28, tight variance. But mu=3.27798 is +0.00054 ABOVE the
  new baseline mu=3.27744 — Polyak (τ=0.20, β=0.995) does not beat
  SOAP-MLP. Projected n=6 margin vs 3.28 target ≈ 0.00494 (will pass),
  but vs new baseline: `(3.27744 - 3.27798) × sqrt(6) = -0.00132` (fails
  merge rule). Status ack posted. Awaiting n=6 terminal SENPAI-RESULT.
  **Will close as "doesn't beat baseline, but clean n=6 reference for
  Polyak (τ=0.20, β=0.995) recipe."** Natural wave-2 use: stack as
  postprocessing wrapper onto merged SOAP-MLP base (not standalone).

### Forming wave-1 verdicts (post-baseline-update; all candidates must beat ffs=3200 mu=3.27744)

| PR | Hypothesis             | Direction so far                                                                      |
| -- | ---------------------- | ------------------------------------------------------------------------------------- |
| 43 | NorMuonH               | **CLOSED (clean negative)** 2026-05-16 06:27: n=8 mu=3.27962, fails statsig (margin=0.00107); +0.00218 above new baseline mu; ffs median 3250 vs baseline 3200; reproduction also failed vs public record #8 mu=3.2778 |
| 44 | Contra-Muon isolated   | n=8 nearly done (7/8): ffs cluster [3300, -1, 3325, 3325, 3300, 3300, 3325] — won't beat new baseline ffs=3200; clean negative |
| 45 | Muon²                  | n=8 at trial-3/8; trial-0/1 val=[3.2793, 3.2777] ffs=[3325, 3300]; running mu ≈ 3.2785 ≈ new baseline mu; needs mu ≤ 3.27603 to merge under new bar |
| 46 | SOAP-MLP isolated      | **MERGED ✓** ffs=3200 mu=3.27744 n=6; new baseline; all 6 seeds hit target            |
| 47 | MuonH reproduction     | n=8 in flight; seeds 1-3 final val/loss [3.287, 3.301, 3.305] all miss target — possible incomplete reproduction; unlikely to beat new baseline |
| 48 | Cooldown shape sweep   | **clean negative**: 7/8 cells done, aggregate mu=3.28324 misses by +0.0058; linear is best shape but ffs=3300 still ≥ new baseline ffs=3200 |
| 49 | Lookahead k×α          | **CLOSED (clean negative)**: best cell (k=10/α=0.8) = baseline ceiling; PR #49 closed 2026-05-15 22:00 |
| 50 | Polyak/SWA τ×β         | n=6 at 4/6: partial mu=3.28892 — well above new baseline; best arms (τ=0.20/0.30 β=0.995) at ffs=3300; trending clean negative |
| 98 | Cautious-Muon (wave-2) | **trending to clean negative**: lrx1.0=3.3183/-1, lrx1.5=3.3237/-1, lrx2.0 mid-cooldown val≈3.46; mask engages (0.60–0.65) but recipe loses |
| 116| SOAP-attn + trust gate | smoke done (val=3.908 step 300 — expected warmup); screen pending; aims for record #16 ffs=3125 trajectory |

The explore-side outcome is becoming clear: Lookahead is a clean
negative; Polyak has one in-noise screening cell that needs n=6 to
disambiguate; cooldown-shape sweep is trending negative. None of the
explore levers will independently produce a wave-1 winner; they remain
candidates for wave-2 stacking onto an exploit-side backbone (e.g.,
Polyak/SWA τ-tail over NorMuonH).

**Important:** all of the above are single-seed screening or
partial-confirmation numbers. Treat them as *signal that the recipe runs
and approaches the target*, **not as record claims**. Terminal verdicts
wait for the predeclared n-seed confirmation batches the PRs asked for.

## 🏆 Wave-1 Winner — PR #46: SOAP-MLP isolated (MERGED 2026-05-16 04:00 UTC)

**New baseline**: `ffs=3200, mu=3.27744, n=6, train_steps=3250`
- Statsig margin = 0.00628 (>> 0.004 threshold)
- All 6 seeds hit ffs=3200 — zero variance on primary metric
- SOAP preconditioning on MLP fc/proj only; no Contra/NorMuon needed
- Merged as commit 801c137; BASELINE.md created

**Fern (PR #116)** immediately reassigned to wave-2 follow-up: SOAP-attn + trust gate (→ record #16 trajectory, target ffs ≤ 3175).

**Remaining wave-1 candidates** must now beat ffs=3200 / mu=3.27744 to be merge-eligible:
- edward Muon² (PR #45): ffs=[3325, 3300] so far — tied/marginally slower than new baseline; needs n=8 mu to come in low enough
- alphonse NorMuonH (PR #43): ffs=[3225, 3225, -1, 3250, ...] — 3225 beats new baseline; watch n=8 mu
- thorfinn Polyak (PR #50): ffs=3300 so far (1 seed) — tied with new baseline; unlikely to produce a merge-eligible result

**Most promising direction going forward:** Stacking SOAP-attn (PR #116) + NorMuonH + Contra-Muon progressively toward record #16 → #20 trajectory.

**Watch list for next poll:**
- **fern PR #116 SOAP-attn + trust gate** — screen at step 3049 val=3.293 (mid-cooldown); **only remaining high-value wave-2 exploit toward record #16 trajectory**
- edward Muon² n=8 mu PR #45 — at trial-3/8; running mu ≈ new baseline; needs mu ≤ 3.27603 to merge; likely borderline close
- askeladd Contra-Muon n=8 PR #44 — run FINISHED at 8/8 trials but student hasn't posted terminal SENPAI-RESULT; nudge posted; expect ffs cluster 3300-3350 won't beat baseline
- frieren MuonH n=8 PR #47 — 6/8 done; hit rate 2/6 (much worse than published 10/10); trending clean negative; awaiting terminal
- nezuko cooldown shape PR #48 — 7/8 cells done, 8th in flight; clean negative; awaiting terminal
- thorfinn Polyak n=6 PR #50 — 3/6 done; pure-cell mu=3.27798; won't beat baseline; awaiting terminal
- tanjiro Schedule-free Muon PR #121 — freshly dispatched; smoke pending
- alphonse Newton-Muon attn PR #123 — freshly dispatched; smoke pending

**Expected close-out cadence (next 2-4 polls):** PRs #44, #48, #50, #98 should all terminate as clean negatives under the new baseline within 4-6 hours. PR #45 (Muon²) and PR #43 (NorMuonH) are the two remaining wave-1 candidates that could conceivably merge, but both are running mu near the new baseline bar — likely to land as borderline-statsig closes too. **The wave-1 winner field is essentially decided in favor of PR #46 SOAP-MLP.** Focus shifts to PR #116 SOAP-attn (exploit) and to wave-2 stacks of merge candidates onto the SOAP-MLP backbone.

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

| PR # | Student         | Hypothesis                                                            | Type    | Status       |
| ---- | --------------- | --------------------------------------------------------------------- | ------- | ------------ |
| 43   | g1r5-alphonse   | NorMuonH reproduction (record #8)                                     | exploit | WIP (confirm)|
| 44   | g1r5-askeladd   | Contra-Muon isolated on plain Muon                                    | exploit | WIP (confirm)|
| 45   | g1r5-edward     | Muon² sharper NS polynomial (record #7)                               | exploit | WIP (screen) |
| 46   | g1r5-fern       | SOAP-Muon for MLP weights only (component of #14)                     | exploit | WIP (confirm)|
| 47   | g1r5-frieren    | MuonH reproduction (record #5)                                        | exploit | WIP (confirm)|
| 48   | g1r5-nezuko     | Cooldown shape sweep on plain Muon (5 shapes × 2 seeds)               | explore | WIP (screen) |
| 49   | g1r5-tanjiro    | Lookahead wrapper over Muon (k×α grid)                                | explore | **CLOSED** (clean negative) |
| 50   | g1r5-thorfinn   | Polyak/SWA tail averaging (τ×β grid)                                  | explore | WIP (confirm in flight)|

## Wave 2 — assignments dispatched 2026-05-15 (tanjiro freed from PR #49)

| PR # | Student         | Hypothesis                                                   | Type    | Status |
| ---- | --------------- | ------------------------------------------------------------ | ------- | ------ |
| 98   | g1r5-tanjiro    | Cautious-Muon: sign-agreement mask on NS update (lr sweep)   | explore | **CLOSED** (clean negative, val strictly worse with LR mult) |
| 116  | g1r5-fern       | SOAP-attn + trust gate on merged SOAP-MLP base (→rec #16)    | exploit | WIP (smoke done; screen pending) |
| 121  | g1r5-tanjiro    | Schedule-free Muon: Defazio averaging on merged SOAP-MLP base | explore | WIP (dispatched 05:30) |
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond on attn (record #15) | exploit | **WIP (dispatched 06:30)** |

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
