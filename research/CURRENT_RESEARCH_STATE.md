# SENPAI Research State

- 2026-05-16 05:45 — Cycle 8 (4 terminals + 2 anomalies):
  - **Fern T3=3.27787, n=4 MEAN=3.27760, MARGIN=0.00480 — STATSIG WIN** ✨
    First wave-1 stack to clear statsig. ffs_mean=3131.25, beats NorMuon-clean
    by 125 mean ffs steps. PR #78 in status:wip after send-back for rebase +
    workflow-note comment disambiguation. Merge pending fern's force-push.
  - **Askeladd T3=3.27860, n=4 MEAN=3.27804, MARGIN=0.00392 — NON-STATSIG**
    Painfully close. Recipe is real (σ~0.0004 across 4 trials) but mean misses
    by 0.00008. Need fresh n=4 at 3300 for cleaner statsig. ffs_mean=3237.5.
  - **Alphonse p=1.2 screen `fg11eojr` terminal at 3.28031, ffs=-1 (missed)**.
    Per predeclared branch decision (3.28 < val ≤ 3.280 → try p=1.5), student
    should auto-launch p=1.5 single-seed at 3275 next poll.
  - **Thorfinn screen `hz91ow2y` CRASHED at step 1575/3325**. p=0.05 Soft-Muon
    diverged or threw error mid-cooldown. Needs investigation.
  - **Frieren smoke `mti327gb` DIVERGED to NaN at step 400**. MuLoCo+NorMuon
    config has stability issues — outer Nesterov on NorMuon's noisy variance
    may have a learning-rate or sync-interval bug. Needs debugging.
  - Nezuko T3 still in progress (was @ 35%), edward/tanjiro T1 progressing.
  Advisor branch: `auto-nanogpt-1gpu-r2`. NorMuon baseline still locked (PR #71)
  pending fern merge. GH core rate limit exhausted until 06:19 UTC.
- No human-researcher directives recorded.
- W&B `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — n=4 conf `zsqazpmr` (3225): **T0=3.27750**
  (ffs=3175, terminal). T1 just started (step 50/3225). For n=4 statsig:
  T1+T2+T3 need mean ≤ 3.27817 — easy bar. Likely statsig, would beat NorMuon
  by ~50-80 ffs steps. ~14h to T3.

- **g1r2-fern (Contra+SOAP on MLP) ✨ STATSIG WIN — MERGE PENDING REBASE** —
  `6bbhoxm1` at 3175: T0=3.27920, T1=3.27811, T2=3.27522, **T3=3.27787**
  (ffs=3125). **n=4 mean=3.27760, margin=0.00480 ≥ 0.004 — PASSES**.
  ffs_mean=3131.25 vs NorMuon-clean 3256.25 = **−125 steps**. Student
  submitted SENPAI-RESULT, flipped to status:review. Merge blocked by:
  (1) merge conflicts with auto-nanogpt-1gpu-r2 (NorMuon merged), and
  (2) false-positive SENPAI-RESULT JSON parse on fern's WORKFLOW-NOTE comment.
  Sent back with explicit rebase + comment-edit instructions. Once rebased,
  this becomes the new advisor baseline.

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

- **g1r2-nezuko (Muon²)** — n=4 confirmation `7lxk02m6` at train_steps=3325:
  T0=3.27788, T1=3.27859, **T2=3.27915** (rising trend across all 3).
  mean(T0,T1,T2)=3.27854. For n=4 statsig: T3 needs ≤ 3.27638 — **very hard
  bar** (best individual trial in this run was T0=3.27788). T3 in progress
  (~35%, step ~1175/3325). **Projecting non-statsig.** If T3 lands ~3.279,
  mean ≈ 3.27873, margin ≈ 0.00254 — below 0.004.

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

**Confirmed dead (non-reproducible) on this setup:**
- PMuon (thorfinn): numerically unstable across all stabilization attempts.
- MuLoCo on plain Muon (frieren, 4 sweep corners all missed 3.28:
  3.2829/3.2810/3.2815/3.2865). si=60/lr=0.5 was the worst corner.
  Plain Muon's NS5 already smooths the gradient direction — outer Nesterov
  adds no value. MuLoCo DOES work on NorMuon (record #13), which is next.

**Current active student assignments:**
- Thorfinn → Soft-Muon isolated (PR #103) — p=0.05 screen CRASHED; iterating.
- Alphonse → NorMuon + power-law LR (PR #112) — p=1.2 screen MISSED; should launch p=1.5 per predeclared plan.
- Tanjiro → Newton-Muon re-run n=4 @ 3325 (`cpoe66ut`) — T1 in progress; rebase PR #81 before submit.
- Frieren → MuLoCo+NorMuon (PR #109) — smoke NaN; needs lower outer_lr or higher sync_interval.
- Askeladd → NorMuonH n=4 @ 3275 TERMINAL non-statsig (margin 0.00392); send back for n=4 @ 3300.
- Nezuko → Muon² n=4 `7lxk02m6` T3 in progress; projecting non-statsig.
- Fern → Contra+SOAP-MLP n=4 STATSIG WIN; PR #78 rebase + comment-edit blockers.
- Edward → Contra-Muon n=4 `zsqazpmr` T1 just started; rebase PR #76 before submit.

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
