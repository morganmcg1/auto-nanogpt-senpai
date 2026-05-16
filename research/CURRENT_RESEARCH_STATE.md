# SENPAI Research State

- 2026-05-16 13:40 — Cycle 18 (ALPHONSE 0.3 SCREEN FFS-COMPETITIVE — first such signal since merge):
  - **ALPHONSE #139 CONTRA_MUON=0.3 SCREEN PASS** 🎯 `hjsjscjy` terminal val=**3.27804**,
    ffs=**3150** at 3175 steps. Single seed only 19 ffs steps worse than merged baseline
    (3131.25). This is the FIRST FFS-COMPETITIVE result since baseline was set in cycle 9.
    Sent back: launch CONTRA_MUON=0.5 screen next, then predeclare n=4 at 3175 with winning arm.
  - **TANJIRO Option B MISSED & CRASHED**: `wzgya0cq` screen at 3175 final val=3.28893 (0.013
    above baseline!), ffs=-1. `yrsarj9b` crashed at step 0. Either config bug, step count
    too low for stack, OR Newton-Muon attn doesn't compose with SOAP-MLP. Sent back with
    diagnostic hypotheses + audit directive.
  - **FERN screen CRASHED TWICE**: `csj1tm5z` @1475, `isi6y97w` @575. New smoke `w2hlrhs0`
    running. Real-Aurora D update unstable past step ~500. Sent back with clamp suggestion
    `D.clamp_(1e-6, 1e6)`, pp_beta reduction option, non-square-only filter check.
  - **ASKELADD T1 = 3.27573!** (much better than I had cached). T0=3.27781, T1=3.27573,
    T2=3.27932, T3 at step 778/3300 running. Mean(T0-T2) = 3.27762, AT merged baseline mean.
    For n=4 statsig at 3300 (mean ≤ 3.278), need T3 ≤ 3.27869 — likely passes. But
    ffs ~3225-3250 > baseline 3131, won't be new baseline. ETA T3 ~14:30 UTC.
  - **EDWARD T1 = 3.27599!** strong. T0=3.27750 ffs=3175 already terminal. T1 at val=3.27599.
    T2 phase at step ~1802/3225. ETA full n=4 ~20:00 UTC.
  - **THORFINN T0=3.27400** ffs=3250 already known. T1 at step 2143/3325. ETA full n=4 ~18:00 UTC.
  - **NEZUKO `c5d01ezw`** at step 2550/3150 val=3.36 (mid-cooldown). ETA terminal ~13:50 UTC.
  - **FRIEREN T1** at step 2070/3175 — should terminal in ~30 min. T0=3.28240 missed.
  - **Two competing FFS strategies emerging**:
    1. Alphonse CONTRA_MUON=0.3 retune — single-seed FFS-competitive at 3175.
    2. Multiple recipes ('stronger but slower') with FFS 3225-3250 at higher step count.
    Strategy 1 is the only path to BEAT merged baseline. Strategy 2 results are
    side-grade confirmations but not winners.

- 2026-05-16 12:35 — Cycle 17 (frieren T0 missed, multiple runs progressing):
  - **FRIEREN #109 T0 MISSED**: `jzsue46n` T0 val=3.28240, ffs=-1 (never crossed 3.28).
    Frieren's honest analysis: MuLoCo wrapping DELAYS convergence ~50 steps on Contra+SOAP-MLP
    base. Screen at 3275 was 3.27688, but at 3175 (predeclared step) screen was 3.28353.
    T0 in line with that. Math: T1-T3 would need mean ≤3.27587 (~3σ below screen distribution)
    — extremely unlikely. Sent back: continue all 4 trials (no val-peeking), post SENPAI-RESULT,
    will pivot to outer_lr=0.5 OR close+reassign after T3 terminal (~17:30 UTC).
  - **EDWARD `zsqazpmr` NOT DEAD** — n=4 confirm started May 15 22:36 UTC, T0=3.27750 ffs=3175
    already logged, currently in T2 phase (_step=7740 = T0+T1+~step 1290). ETA full n=4 terminal
    ~20:00 UTC today. Blackwell compile-off so 6.0 s/step.
  - **ASKELADD `lw99ybyp`** T2 at step 2375/3300 (~72%), _step=8977. T0=3.27781 ffs=3225,
    T1=3.27777 ffs=3225 strong. ETA full n=4 ~14:30 UTC.
  - **THORFINN `6kjpjnvd`** T0 best_val=3.274 ffs=3250 (Soft-Muon p=0.05 working). T1 at step 394.
    n=4 ETA ~14:00 UTC for next trial completion.
  - **TANJIRO Option B STARTED** — `yrsarj9b` launched ~12:24 UTC on g1r2-tanjiro/newton-muon
    branch. Newton-Muon (attn-only) right-preconditioning on Contra+SOAP-MLP base. Still warming.
  - **FERN real-Aurora smoke** `u1tnpn3q` step 125/400. Diagonal leverage-score equalization
    algorithm with pp_iterations=2, pp_beta=0.5.
  - **ALPHONSE `hjsjscjy`** step 1950/3175 (val=3.4765 mid-cooldown). ETA screen terminal
    ~13:09 UTC. No CONTRA_MUON=0.5 screen launched yet.
  - **NEZUKO `c5d01ezw`** step 1375/3150 (val=3.577). ETA terminal ~13:30 UTC.
  - **Key insight**: The \"stronger but slower\" pattern continues. Recipes that beat baseline
    val at 3275+ steps don't beat baseline FFS at 3131. Future hypotheses must directly target
    FFS reduction (faster convergence), not just lower terminal val.

- 2026-05-16 11:40 — Cycle 16 (W&B survey + GH rate-limit exhausted again):
  - **Frieren n=4 `jzsue46n` T0 step 2040/3175 (64%)** — val=3.4728 mid-cooldown.
    Expected terminal ~12:15 UTC. T2/T3 ended at step 400 (likely crashed seeds — only
    T0 currently active). Frieren autocope should relaunch failed seeds.
  - **Alphonse screen `o5w9cidj` CRASHED at step 850/3175** mid-cooldown! Relaunched as
    `hjsjscjy` at step 375 val=3.90 (~11:23). No CONTRA_MUON=0.5 screen launched yet.
    Crash pattern echoes prior thorfinn p=0.05 crashes — possibly Contra-Muon at lower
    coefficient has numerical instability. Need to wait for relaunch.
  - **Thorfinn T0 `6kjpjnvd` step 2185/3325 (66%)** — val=3.4573 mid-cooldown. T1
    `pzp8b4rq` was 3.2755 ffs=3250, T2 `78nqtrmr` was 3.2742 ffs=3225 (crashed at 3298
    but reached FFS). Strong pair so far. ETA T0 ~13:00 UTC.
  - **Edward `zsqazpmr` running step 7227 multi-epoch** — anomaly: step count exceeds
    3225 target. Concurrent g1r4 runs `swdz145t`/`jp2lhp3r`/`nit5n8jo` (muon2-bias-corr)
    FFS at 3250-3300, val 3.2749-3.2772. NOT his r2 assignment though.
  - **Askeladd `lw99ybyp` running step 7302 multi-epoch** — same anomaly. Concurrent
    g1r4/lookahead-sweep `cr1bq7ff` step 1394/3350 val=3.5448 (mid-training).
    Multi-round cross-talk likely.
  - **Tanjiro 2 new runs**: `cg6asx9a` (g1r1, step 50 warmup), `nneqbzma` (g1r3, step
    240 NaN val). Neither on PR #81 g1r2 branch — Option B not yet started.
  - **Nezuko `c5d01ezw` step 250 val=4.05** — early progress, on track.
  - **Fern `p31pn6u4` step 360 val=4.00** — appears to still be earlier run, not
    real-Aurora screen yet.
  - **GH rate limit EXHAUSTED again** (5001/5000, reset ~12:19 UTC). Student pods
    continue burning API quota. PR comment reads blocked until reset.
  - **No terminal results since 11:25 UTC.** Holding pattern; wakeup at 12:25 UTC to
    catch both frieren T0 terminal AND rate limit recovery.

- 2026-05-16 11:25 — Cycle 15 (multiple n=4 progressing, pattern emerging):
  - **Tanjiro #81 SENPAI-RESULT posted** — clean terminal (n=4 mean=3.27643, margin 0.00714).
    Awaiting tanjiro to start Option B (Newton-Muon on merged base) — directive from cycle 13.
  - **Askeladd T1 = 3.27574** — BEST INDIVIDUAL TRIAL seen across any n=4 run! T0=3.27772.
    T2 just started. If T2/T3 land in same range, n=4 mean ~3.276. But at 3300 steps, ffs=~3250.
  - **Thorfinn `78nqtrmr` screen step 3275 val=3.27416** (crashed at step 3298 mid-cooldown).
    Strong single seed; n=4 confirm `6kjpjnvd` now running cleanly (T0 step 1839/3325).
  - **Frieren n=4 `jzsue46n` T0 step 1700/3175** — 54% done. ETA T0 ~50min.
  - **Alphonse PR #139** CONTRA_MUON=0.3 smoke PASS, screen `o5w9cidj` at step 850/3175 (27%).
    Smart: skipping 0.5 smoke (identical code path). ETA ~70min to screen terminal.
  - **Fern PR #125** still on smokes — careful real-Aurora implementation in progress.
  - **Nezuko PR #124** screen `c5d01ezw` just launched 11:24 UTC after ~7 smoke iterations.
  - **PATTERN**: All strong screens/T0 results (tanjiro 3.27599, frieren 3.27688, thorfinn
    3.27416, askeladd T1 3.27574) are LOWER VAL but at MORE STEPS than merged baseline.
    Primary metric is FFS — merged baseline's FFS=3131 is its key advantage. Future
    experiments should target FFS reduction directly, not just val/loss reduction.

- 2026-05-16 10:30 — Cycle 14 (screens landing, alphonse reassigned, multiple n=4 in-flight):
  - **PR #112 CLOSED** — alphonse p=1.5 NEW-base NULL (3.2775 ≈ baseline mean). Reassigned
    to **PR #139: Contra-Muon coefficient retune** (CONTRA_MUON ∈ {0.3, 0.5} vs 0.4).
  - **Frieren `akwwpkv3` screen 3.27688 ffs=3225 at 3275 steps** — predeclared n=4 at 3175
    steps launched now. ~6.75h to terminal. KEY test: can MuLoCo+NorMuon beat merged baseline
    on FFS at same step count?
  - **Tanjiro Newton-Muon n=4 terminal** — mean=3.27643 (LOWEST n=4 mean achieved!), margin
    0.00714, BUT ffs=3256 > merged 3131. Sent back to stack Newton-Muon (attn) on merged
    Contra+SOAP-MLP base.
  - **Thorfinn Soft-Muon p=0.05 n=4 `78nqtrmr` running** — T0 near-terminal at val~3.2742,
    ffs=3225. Remarkable trajectory. ~8-9h to T4.
  - **Edward Contra-Muon T0=3.2760 ffs=3175**, T1 running.
  - **Askeladd NorMuonH T0=3.2777 ffs=3250 at 3300**, T1 running.
  - Nezuko: smoke complete, new run started. Fern: smoke passed, screen launching.

- 2026-05-16 09:25 — Cycle 12 (research integrity catch + n=4 progress):
  - **PR #125 (fern Aurora) SPEC ERROR CAUGHT** — fern flagged that my PR pseudocode was
    GaLore/FLORA-style randomized SVD projection, NOT record #17 Aurora (which is
    diagonal leverage-score equalization inside NS5). Sent back with corrected
    algorithm: `D = 1/||G_i:||`, iterative `polar(D · G)` with `pp_iterations=2`,
    `pp_beta=0.5`. Apply to non-square weights (MLP fc/proj). Stack on Contra+SOAP-MLP.
  - **Tanjiro n=4 `cpoe66ut` near-terminal** — T0=3.27599, T1=3.27720, T2=3.27610,
    T3 at step 3139/3325 (94%). n=3 mean=3.27643 — well below 3.278 statsig threshold.
    But predeclared step count is 3325 with ffs ~3200-3250, vs merged baseline ffs=3131
    at 3175 steps. Likely PASS statsig but NOT BEAT merged baseline on ffs.
  - **Edward n=4 `zsqazpmr` T1 progressing** — step 2851/3225 of T1. T0=3.27750 ffs=3175.
    Same likely outcome: pass statsig at 3225 steps, but ffs > merged 3131.
  - **Askeladd n=4 `lw99ybyp` T0 done** — T0=3.27770 at 3300 steps. 3 trials remaining.
  - **Thorfinn n=4 `78nqtrmr` LAUNCHED** at 08:27 UTC after my send-back. Soft-Muon
    p=0.05 confirmation, train_steps=3325, single invocation `--num_trials 4`.
  - **Alphonse p=1.5 NEW-base** at step 1700/3275 (~52%, val=3.5065 mid-descent).
    Expected terminal ~10:06 UTC. Likely misses (alphonse's own prior).
  - **Nezuko PR #124** smoke `1f616e9q` completed at val=3.806 (smoke baseline). New
    run `l7lwkmj6` launched 09:25 UTC. Had ~10 min stall from gh API rate limit;
    recovered.
  - **Frieren PR #109** MuLoCo+NorMuon `akwwpkv3` at step 1775/~3275 (~54%).
  All 8 r2 students productive. Multiple n=4 confirmations within 10-15h of terminal.

- 2026-05-16 07:30 — Cycle 10 (post-restructure tick — wait state):
  - Survey: 8 r2 PRs WIP, 0 review-ready, no human issues, rate limit healthy.
  - Pod check: all 8 r2 pods Running. 4 at 100% GPU (edward, tanjiro, thorfinn, alphonse).
    4 at 0% GPU spinning up cycle-9 instructions (askeladd, frieren rebasing; nezuko
    and fern just picked up their NEW assignments #124 and #125).
  - No actionable advisor work this cycle — all students executing cycle-9 directives.
  - Next wakeup scheduled in ~25 min to check rebase landings, p=1.5 progress, and
    new nezuko/fern training kickoffs.

- 2026-05-16 06:45 — Cycle 9 (PR #78 merged, major portfolio restructure):
  - **PR #78 (fern Contra+SOAP-MLP) MERGED** ✨ commit `718dd3f`. New baseline:
    mean=3.27760, ffs_mean=3131.25 @ 3175 steps. Beats NorMuon-clean by 125 steps.
  - **Askeladd n=4 @ 3275 non-statsig by 0.00008** → sent back for n=4 @ 3300.
    Rebase + predeclared n=4 run needed. Explained merge contingency vs new baseline.
  - **Nezuko Muon² n=4 @ 3325 non-statsig (mean 3.27839, margin 0.00322)** →
    PR #80 CLOSED. Pivoted to PR #124 Attention SOAP with trust gate (record #16
    stack on Contra+SOAP-MLP base).
  - **Alphonse p=1.2 screen MISSED (3.28031)** → advised to kill p=1.2 re-run,
    launch p=1.5 per predeclared plan + rebase.
  - **Thorfinn p=0.05 crashed 2× mid-cooldown** → advised to try p=0.075 + add
    NaN guard + rebase.
  - **Frieren debug smoke clean (3.84938, no NaN)** → advised to rebase + proceed
    to full screen at 3275 steps with si=30/outer_lr=0.7 (record #13 HPs).
  - Edward Contra-Muon T1-T3 in progress; tanjiro Newton-Muon T1-T3 in progress.
  New baseline: Contra+SOAP-MLP mean=3.27760 ffs_mean=3131.25 (PR #78 = `718dd3f`).
- No human-researcher directives recorded.
- W&B `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — n=4 conf `zsqazpmr` (3225): **T0=3.27750**
  (ffs=3175, terminal). T1 just started (step 50/3225). For n=4 statsig:
  T1+T2+T3 need mean ≤ 3.27817 — easy bar. Likely statsig, would beat NorMuon
  by ~50-80 ffs steps. ~14h to T3.

- **g1r2-fern (Aurora orthogonal projection) — PR #125 NEW ASSIGNMENT** —
  Contra+SOAP-MLP (PR #78) MERGED as new baseline. Fern pivoted to **Aurora**:
  low-rank orthogonal projector applied to Contra-Muon path (non-SOAP weights)
  before NS5. Target: beat 3131.25 ffs_mean by ~25-50 steps (→ ~3075-3100).
  Aurora complements SOAP (SOAP corrects eigenbasis curvature; Aurora removes
  noisy gradient components). PR #125 assigned. Student picks up next poll.

- **g1r2-alphonse (NorMuon + power-law LR p=1.2) — screen MISSED** —
  `fg11eojr` terminal at val=3.28031, ffs=-1 (didn't cross 3.28) at
  train_steps=3275 single seed. Per predeclared branch decision, student
  should auto-launch p=1.5 single-seed at 3275. If p=1.5 also > 3.280,
  close PR with negative evidence (power-law LR not additive on top of
  NorMuon at our setup).

- **g1r2-tanjiro (Newton-Muon)** — `cpoe66ut` (n=4 @ 3325): **T0=3.27599**
  (ffs=3250, terminal — excellent first trial, 0.003 below prior n=4's T0).
  T1 @ 20% (step 664/3325). For n=4 statsig: T1+T2+T3 need mean ≤ 3.27867 —
  comfortable. Recipe scales well with cooldown. ~13h to T3.

- **g1r2-askeladd (NorMuonH) ⚠️ TERMINAL NON-STATSIG** — `6rf3nerz` (n=4 @
  3275): T0=3.27781, T1=3.27777, T2=3.27798, **T3=3.27860** (ffs=3250).
  **n=4 mean=3.27804, margin=0.00392 — MISSES 0.004 by 0.00008**. Recipe is
  real (σ~0.0004) but T3 was unlucky. Action: send back for predeclared n=4
  at train_steps=3300 (one cycle of cooldown headroom should push mean ≤
  3.2775 reliably). Once fern merges, askeladd's NorMuonH at 3300 would
  still be merit-worthy: would beat NorMuon-clean by mean and ffs at same
  step count. Pending GH API recovery to send back.

- **g1r2-frieren (MuLoCo+NorMuon) ⚠️ SMOKE DIVERGED** — Smoke `mti327gb`
  produced NaN val/loss at step 400. MuLoCo outer Nesterov wrapping NorMuon
  has stability issues — likely outer_lr=0.7 is too high when wrapping
  NorMuon's already-variance-noisy update direction. Needs investigation:
  try outer_lr=0.5 or sync_interval=60 first. Student should iterate
  on next poll.

- **g1r2-nezuko (Attention SOAP + trust gate) — PR #124 NEW ASSIGNMENT** —
  Muon² PR #80 CLOSED: n=4 @ 3325 mean=3.27839, margin=0.00322, non-statsig.
  Nezuko pivoted to **Attention SOAP with trust gate** (record #16 stack): extend
  fern's MLP-SOAP to qkv+proj attention weights with cosine-similarity trust gate.
  Target: beat new baseline (3.27760 @ 3175) by ~25 steps → ~3125 ffs. PR #124
  assigned, student picks up next poll.

- **g1r2-thorfinn (Soft-Muon isolated) ⚠️ p=0.05 SCREEN CRASHED** — `hz91ow2y`
  crashed at step 1575/3325 (47%, mid-cooldown). Previous p=0.1 screen
  MISSED at 3.28024. Now p=0.05 crashed before finishing — possibly NaN
  or numerical instability in Soft-Muon's `x^(1-p)` polynomial at lower p
  values. Needs debugging: check for stable polynomial coefficients or
  consider p=0.075 as midpoint. Student should iterate on next poll.

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
results reproduce statsig at n=4.

**Statsig outcomes so far:**
- alphonse NorMuon: n=4 mean=3.27800 @ 3300, margin=0.00401 → **MERGED** (PR #71 = new baseline).
- fern Contra+SOAP-MLP: n=4 mean=3.27760 @ 3175, margin=0.00480 → **STATSIG WIN, merge pending rebase** (PR #78).
- askeladd NorMuonH: n=4 mean=3.27804 @ 3275, margin=0.00392 → **NON-STATSIG by 0.00008**, needs n=4 @ 3300.
- tanjiro Newton-Muon (prior): n=4 mean=3.27934 @ 3275, margin=0.00132 → NON-STATSIG, re-running @ 3325.
- nezuko Muon²: T0-T2 mean=3.27854 @ 3325 → projecting non-statsig.
- edward Contra-Muon @ 3225: T1 just started.
- tanjiro Newton-Muon @ 3325 (re-run): T1 just started.

**Confirmed dead (non-competitive) on this setup:**
- PMuon (thorfinn, earlier): numerically unstable. Now testing Soft-Muon.
- MuLoCo on plain Muon (frieren, 4 sweep corners all missed 3.28).
- Muon² (nezuko, PR #80): n=4 mean=3.27839 @ 3325, non-statsig. Even with
  more steps, ffs_mean ~3300 cannot beat new baseline 3131.25.

**Current active student assignments:**
- Thorfinn → Soft-Muon isolated (PR #103) — p=0.05 crashed 2×; try p=0.075 + NaN guard + rebase.
- Alphonse → NorMuon + power-law LR (PR #112) — p=1.2 missed; launch p=1.5 + rebase.
- Tanjiro → Newton-Muon re-run n=4 @ 3325 (`cpoe66ut`) — T1 in progress; rebase PR #81 before submit.
- Frieren → MuLoCo+NorMuon (PR #109) — debug smoke clean; rebase + proceed to screen @ 3275.
- Askeladd → NorMuonH n=4 @ 3275 non-statsig (margin 0.00392); n=4 @ 3300 predeclared, rebase first.
- Nezuko → Attention SOAP + trust gate (PR #124, NEW) — newly assigned, student picks up next poll.
- Fern → Aurora orthogonal projection (PR #125, NEW) — newly assigned.
- Edward → Contra-Muon n=4 `zsqazpmr` T1 in progress; rebase PR #76 before submit.

## Wave 1 assignments

| Student | Hypothesis family | PR | Status |
| --- | --- | --- | --- |
| g1r2-alphonse | NorMuon + power-law LR cooldown | #112 | **newly assigned** |
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
