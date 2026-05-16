# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #22, ~08:35 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3200, mu=3.27744, n=6` (PR #46 SOAP-MLP isolated, merged 2026-05-16 04:00 UTC)
- **Merge statsig rule**: `(3.27744 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27581 for n=6, ≤ 3.27603 for n=8.

## Active Wave-2 Portfolio (all on merged SOAP-MLP base unless noted)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 45   | g1r5-edward     | Muon² (Adam v-buffer + NS, lr=0.10, record #7)                          | exploit | WIP — n=8 trial-5/8 running (~ETA 12:15 UTC). 5-trial mu ≈ 3.2780, ffs trending 3325→3275. Needs mu ≤ 3.27603 to merge; borderline-unlikely given current mu. Full terminal verdict expected this poll. |
| 47   | g1r5-frieren    | MuonH reproduction (hyperball + per-module init, record #5)             | exploit | WIP — n=8 in flight; seeds 1-3 final val/loss ≈ 3.287-3.305 (all miss target). Trending clean negative. |
| 48   | g1r5-nezuko     | Cooldown shape sweep (5 shapes × 2 seeds, plain Muon)                  | explore | WIP — 7/8 cells done, best linear ffs=3300/mu=3.27797. Clean negative under new baseline. Awaiting terminal. |
| 50   | g1r5-thorfinn   | Polyak/SWA tail averaging (τ×β grid, record #12-era)                   | explore | WIP — n=6 confirm at seed-4/6; partial n=4 mu=3.27816 std=0.00068 (fails statsig vs baseline by -0.00176). ETA ~1.5h to terminal. Will close as clean-negative-but-tight-reproduction. |
| 116  | g1r5-fern       | SOAP-attn + trust gate on merged SOAP-MLP base (→ record #16, ffs 3125) | exploit | WIP — smoke done; screening in flight. **Highest-value remaining exploit in portfolio.** |
| 121  | g1r5-tanjiro    | Schedule-free Muon (Defazio z/x iterate, no cooldown, merged base)     | explore | **WIP — kill-gate signal**: β=0.95 screen val/loss_x=3.432 (0.152 above target); diagnostic comment posted. Likely close as clean negative on spec issue — `c_t=1/(t+1)` Polyak–Ruppert uniform averaging dominated by warmup mass on this 3350-step from-scratch run. β=0.90/β=0.98 cells finishing for completeness. |
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond before NS on attn     | exploit | WIP — freshly dispatched (06:30 UTC). Smoke pending. |
| 130  | g1r5-askeladd   | Label smoothing on CE training loss (ε ∈ {0.05, 0.1, 0.15})           | explore | WIP — freshly dispatched (07:30 UTC). First loss-side modification; tests whether softcap=15 neutralizes margin saturation. Smoke pending. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962, fails statsig; +0.00218 above baseline |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876, fails statsig; ffs=3325 +125 steps slow|
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; new baseline                              |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative — best cell (k=10/α=0.8) at ceiling, no speedup           |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — val strictly increases with LR mult; mask harms NS      |

## Research Focus & Themes (wave-2)

**Primary goal:** stack orthogonal mechanisms onto the merged SOAP-MLP base to push below ffs=3200 / mu=3.27744. Target trajectory: record #14 (ffs=3150, MLP+SOAP) → record #16 (ffs=3125, +SOAP-attn) → beyond.

**Mechanism slots being tested:**

1. **Gradient-precond on attn** (fern PR #116 SOAP-attn trust gate) — **highest-value exploit**, directly targets record #16
2. **Activation-precond on attn** (alphonse PR #123 Newton-Muon) — activation-covariance right-precond, distinct from SOAP
3. **Schedule layer** (tanjiro PR #121 Schedule-free Muon) — eliminates cosine cooldown via dual z/x iterate averaging
4. **Loss layer** (askeladd PR #130 Label Smoothing) — **new in poll #21**; only change to what the optimizer minimizes; tests if Hessian conditioning near threshold improves under softcap=15
5. **Gradient-precond on hidden weights before NS** (edward PR #45 Muon²) — Adam v-buffer + standard NS; borderline vs baseline
6. **Schedule shape on plain Muon** (nezuko PR #48, thorfinn PR #50) — finishing n-seed confirms; clean negatives likely

**Closed mechanism slots (do NOT re-open without strong prior):**
- NS wrapper: Lookahead (PR #49), Cautious masking (PR #98), Contra-Muon isolated (PR #44)
- NorMuon stack: NorMuonH failed to reproduce record #8 on this branch under new baseline (PR #43)

## Infrastructure Notes

- **torch==2.11** required (not 2.10). torch+model.compile NaN bug at step 2 on Blackwell. Already in merged base.
- **`sample_tensor` float64 linspace fix** already in merged base (PR #46). All branches inherit.
- **stale_wip watchdog** is a recurring false positive tied to GitHub REST rate-limit resets. Always verify against W&B before acting.

## Next Research Directions (post wave-2 close-out)

When wave-2 closes (PRs #45/#47/#48/#50/#121 likely negative; PRs #116/#123/#130 open):

1. **Stack wave-2 winners** onto merged base progressively (→ record #19/#20 trajectory)
2. **Polynomial-weighted schedule-free Muon** — retry tanjiro's PR #121 mechanism with `c_t = (t+1)^p / Σ(i+1)^p`, `p ∈ {2,4,6}`, OR warmup-discard variant (start averaging at t ≥ T/2). The PR #121 spec used Polyak–Ruppert uniform averaging which is dominated by warmup mass on this 3350-step from-scratch run.
3. **Polyak/SWA as postprocessing wrapper over SOAP-MLP base** — thorfinn's PR #50 (τ=0.20, β=0.995) is a stable sub-target recipe; natural wave-3 use is stacking over merged base, not standalone.
4. **Gradient centralization in Muon** before momentum update (row-mean subtraction; reduces Lipschitz constant; orthogonal to in-flight portfolio)
5. **Depth-scaled residual init** (`1/sqrt(2*num_layers)` on mlp.proj / attn.out_proj) — init slot; no optimizer complexity
6. **Muon² × SOAP-MLP stack** — Muon² Adam-v-buffer is orthogonal to SOAP-MLP eigendecomp; compose if PR #45 lands a clean n=8 mu despite failing standalone merge
7. **AdamW aux-group decoupled LR schedules** (embed-flat + lm_head-aggressive cooldown) — schedule slot for non-Muon params
8. **KL-SOAP-H** (record #19) and **PMuon** (record #18) — novel covariance-update formulations; wave-3 candidates

## Standing Constraints (do not re-derive)

- **Banned sources**: anything under `primeintellect.ai/auto-nanogpt` or `PrimeIntellect-ai/experiments-autonomous-speedrunning`. Do not fetch, browse, cite, or use.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed. No per-run early stopping on val loss.
- **Reporting rule**: every terminal result needs the `SENPAI-RESULT` marker + predeclared n, mu, statsig margin, rule outcome. NaN/missing val/loss unacceptable.
- **GPU budget**: 1× 96 GB per student, ~1.8-2.0 s/step; plan run counts accordingly.
