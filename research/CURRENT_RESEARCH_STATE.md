# SENPAI Research State

- 2026-05-16 04:30 — Cycle 7 progress:
  - **Fern T3 @ step 3075/3175 reading 3.28396** — concerning (last 100 steps
    decide statsig outcome). T0-T2 mean=3.27751. Terminal expected in ~5 min.
  - **Askeladd T3 @ 47% (step 1550/3275)** — on-track. mean(T0-T2)=3.27785,
    T3 needs ≤ 3.27859 for statsig — easy bar. ETA T3 terminal ~3-4h.
  - **Edward T1 just started** (step 50/3225). T0=3.27750 still strong.
  - **Tanjiro T1 @ 20%** (step 664/3325). T0=3.27599 excellent. Re-run going well.
  - **Nezuko T3 @ 35%** (step 1175/3325). T0-T2 mean=3.27854. T3 needs
    ≤ 3.27638 to clear statsig — very hard. **Projecting non-statsig.**
  - **Alphonse screen `fg11eojr` @ 62%** (step 2025/3275, val=3.42561,
    mid-cooldown). Single-seed power-law LR p=1.2. Terminal ~1.5h.
  - **Frieren smoke `mti327gb` running**, just started (~04:32 UTC).
  - **Thorfinn p=0.05 screen `hz91ow2y` running** (step ~200/3325).
  NorMuon baseline (PR #71) at mean=3.27800 n=4 @ 3300. Advisor branch: `auto-nanogpt-1gpu-r2`.
- No human-researcher directives recorded.
- W&B `wandb-applied-ai-team/modded-nanogpt-senpai`, tag/group prefix
  `auto-nanogpt-1gpu-r2`.

## In-flight / recent results

- **g1r2-edward (Contra-Muon)** — n=4 conf `zsqazpmr` (3225): **T0=3.27750**
  (ffs=3175, terminal). T1 just started (step 50/3225). For n=4 statsig:
  T1+T2+T3 need mean ≤ 3.27817 — easy bar. Likely statsig, would beat NorMuon
  by ~50-80 ffs steps. ~14h to T3.

- **g1r2-fern (Contra+SOAP on MLP) ⚠️ T3 BORDERLINE** — `6bbhoxm1` at 3175:
  T0=3.27920, T1=3.27811, **T2=3.27522** (ffs=3100), **T3 @ step 3075/3175
  (97%) reading 3.28396** (still descending). mean(T0,T1,T2)=3.27751.
  Cooldown is ~96% complete in T3, so descent in final 100 steps will be
  small. Statsig outcomes:
    - T3 ≤ 3.27947 → statsig (mean ≤ 3.278). Requires ~0.005 drop in last 100 steps.
    - T3 in [3.27947, 3.281] → non-statsig but close.
    - T3 ≥ 3.281 → clear non-statsig.
  Terminal expected in ~5-10 min.

- **g1r2-alphonse (NorMuon + power-law LR)** — PR #71 merged (NorMuon baseline
  locked). **New PR #112** (branch `g1r2-alphonse/normuon-plawlr`): test
  power-law LR cooldown on NorMuon. Hypothesis: `lr * remaining^p` with p=1.2
  (record #20 schedule) may give 25-75 step gain. Plan: smoke → p=1.0 sanity
  → p=1.2 screen at 3275 → n=4 confirmation at best p. Student picking up
  next poll cycle.

- **g1r2-tanjiro (Newton-Muon)** — `cpoe66ut` (n=4 @ 3325): **T0=3.27599**
  (ffs=3250, terminal — excellent first trial, 0.003 below prior n=4's T0).
  T1 @ 20% (step 664/3325). For n=4 statsig: T1+T2+T3 need mean ≤ 3.27867 —
  comfortable. Recipe scales well with cooldown. ~13h to T3.

- **g1r2-askeladd (NorMuonH)** — `6rf3nerz` (n=4 @ 3275): T0=3.27781,
  T1=3.27777, **T2=3.27798**, T3 in progress. mean(T0-T2)=3.27785. Tight std
  ~0.0001. For statsig: T3 ≤ 3.27859 — easy bar. **Likely statsig win.**
  Projection: mean ≈ 3.27787, margin ≈ 0.00427. ~5h to T3.

- **g1r2-frieren (MuLoCo+NorMuon)** — PR #79 CLOSED (all 4 plain-Muon corners
  missed 3.28: 3.2829/3.2810/3.2815/3.2865). **New PR #109** (branch
  `g1r2-frieren/muloco-normuon`) assigned. Hypothesis: MuLoCo outer-Nesterov
  wrapping NorMuon (record #13 stack). Student picks up on next poll cycle.

- **g1r2-nezuko (Muon²)** — n=4 confirmation `7lxk02m6` at train_steps=3325:
  T0=3.27788, T1=3.27859, **T2=3.27915** (rising trend across all 3).
  mean(T0,T1,T2)=3.27854. For n=4 statsig: T3 needs ≤ 3.27638 — **very hard
  bar** (best individual trial in this run was T0=3.27788). T3 in progress
  (~35%, step ~1175/3325). **Projecting non-statsig.** If T3 lands ~3.279,
  mean ≈ 3.27873, margin ≈ 0.00254 — below 0.004.

- **g1r2-thorfinn (Soft-Muon isolated)** — PR #103. Initial screen `<earlier
  run>` at p=0.1 with annealed blend 0→0.8 MISSED at val/loss=3.28024 (just
  barely). Sent back to try lower softness: **p=0.05** with same annealed
  blend. New screen `hz91ow2y` running (step ~200/3325, ~6%, early descent).
  Hypothesis: Soft-Muon's spectral softness was slightly too aggressive at
  p=0.1; reducing to p=0.05 should preserve the smoothing benefit with less
  spectral distortion.

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

**Current active student assignments:**
- Thorfinn → Soft-Muon isolated (PR #103) — in progress.
- Alphonse → NorMuon + power-law LR cooldown (PR #112) — newly assigned.
- Tanjiro → Newton-Muon n=4 @ 3325 (`cpoe66ut`) — rebase PR #81 before submit.
- Frieren → MuLoCo+NorMuon (PR #109) — smoke done, screen pending.
- Askeladd → NorMuonH n=4 `6rf3nerz` T2 in progress.
- Nezuko → Muon² n=4 `7lxk02m6` T2 in progress.
- Fern → Contra+SOAP-MLP n=4 `6bbhoxm1` T2 in progress.
- Edward → Contra-Muon n=4 `zsqazpmr` T0 running (~16%); rebase PR #76 before submit.

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
