# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #24, ~11:00 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3200, mu=3.27744, n=6` (PR #46 SOAP-MLP isolated, merged 2026-05-16 04:00 UTC)
- **Merge statsig rule**: `(3.27744 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27581 for n=6, ≤ 3.27603 for n=8.

## Active Wave-2 Portfolio (all on merged SOAP-MLP base unless noted)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 45   | g1r5-edward     | Muon² (Adam v-buffer + NS, lr=0.10, record #7)                          | exploit | WIP — n=8 trial-6/8+ running. 5-trial mu ≈ 3.2780, borderline vs baseline. Needs mu ≤ 3.27603 to merge; unlikely given current trajectory but final 3 seeds determine eligibility. |
| 48   | g1r5-nezuko     | Cooldown shape sweep (5 shapes × 2 seeds, plain Muon)                  | explore | WIP — ~9/10 cells done at poll #23 (last cell trapezoidal-seed43 at 80%). Expected terminal shortly. Best linear ffs=3300. Trending clean negative under new baseline. |
| 50   | g1r5-thorfinn   | Polyak/SWA tail averaging (τ=0.20, β=0.995, record #12-era)            | explore | WIP — n=6 at seed-4/6 per poll #22 check. Partial n=4 mu=3.27816, std=0.00068, 4/4 hit target. Fails statsig vs new baseline (-0.00176). Will close as clean-negative-but-tight-reproduction. |
| 116  | g1r5-fern       | SOAP-attn + trust gate on merged SOAP-MLP base (→ record #16, ffs 3125) | exploit | WIP — smoke done; screening in flight. |
| 121  | g1r5-tanjiro    | Schedule-free Muon (Defazio z/x iterate, no cooldown, merged base)     | explore | WIP — **kill-gate signal** (poll #22): β=0.95 screen val/loss_x=3.432. Spec issue: `c_t=1/(t+1)` Polyak–Ruppert uniform averaging dominated by warmup mass. β=0.90/β=0.98 cells finishing for completeness. Likely close as clean negative. |
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond before NS on attn     | exploit | WIP — **STRONGEST SCREEN SIGNAL**: screen val/loss=**3.2714** (14-σ outlier). n=6 confirmation launched (seed-0 at ~51% at poll #24). Gate fallback 8.3%, cov_cond_max=1.37e8 (mechanism largely inactive). Disambiguates at n=6 confirm. |
| 130  | g1r5-askeladd   | Label smoothing on CE training loss (ε ∈ {0.05, 0.1, 0.15})           | explore | WIP — ε=0.1 smoke done. Full 3-cell screen (ε∈{0.05,0.10,0.15}, n=1 each, steps=3200) pending/in-flight. |
| 141  | g1r5-frieren    | Gradient Centralization in Muon update (pre-momentum row-mean sub)     | explore | **FRESHLY ASSIGNED** (poll #24). One-line change: `grad = grad - grad.mean(dim=-1, keepdim=True)` before `momentum.lerp_`. n=4 screen, train_steps=3200. Kill if step-1000 train/loss ≥ baseline+0.002. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962, fails statsig; +0.00218 above baseline |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876, fails statsig; ffs=3325 +125 steps slow|
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; new baseline                              |
| 47   | MuonH (record #5 reproduction)     | **CLOSED** clean negative — n=8 mu=3.28088, fails by wide margin; environmental numerical failure (same pattern as PR #43 — per-module init-multiplier family closed) |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative — best cell (k=10/α=0.8) at ceiling, no speedup           |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — val strictly increases with LR mult; mask harms NS      |

## Research Focus & Themes (wave-2)

**Primary goal:** stack orthogonal mechanisms onto the merged SOAP-MLP base to push below ffs=3200 / mu=3.27744. Target trajectory: record #14 (ffs=3150, MLP+SOAP) → record #16 (ffs=3125, +SOAP-attn) → beyond.

**Mechanism slots being tested:**

1. **Activation-precond on attn** (alphonse PR #123 Newton-Muon) — **STRONGEST SIGNAL**: screen val=3.2714 (14-σ outlier). n=6 confirm in flight. Gate firing only 8.3% — mechanism may be inactive; lucky seed or hook-induced regularization. Disambiguates at n=6.
2. **Gradient-precond on attn** (fern PR #116 SOAP-attn trust gate) — targets record #16 trajectory, screening in flight
3. **Pre-momentum gradient transform** (frieren PR #141 Gradient Centralization) — FRESHLY ASSIGNED; one-line `grad -= grad.mean(dim=-1)` before momentum accumulation + NS5. Orthogonal to all in-flight PRs.
4. **Loss layer** (askeladd PR #130 Label Smoothing) — ε ∈ {0.05, 0.1, 0.15}; smoke done, 3-cell screen pending.
5. **Schedule layer** (tanjiro PR #121 Schedule-free Muon) — kill-gate triggered on β=0.95 spec; β=0.90/β=0.98 finishing.
6. **Gradient-precond on hidden weights before NS** (edward PR #45 Muon²) — borderline vs baseline at partial 5/8 seeds.
7. **Schedule shape on plain Muon** (nezuko PR #48, thorfinn PR #50) — finishing n-seed confirms; clean negatives likely.

**Closed mechanism slots (do NOT re-open without strong prior):**
- NS wrapper: Lookahead (PR #49), Cautious masking (PR #98), Contra-Muon isolated (PR #44)
- **Per-module init-multiplier family PERMANENTLY CLOSED**: NorMuonH (PR #43 record #8), MuonH (PR #47 record #5) — both fail on Blackwell + torch 2.11 bf16 NS5 path. Two independent reproductions both land 5-8σ above public references.

## Infrastructure Notes

- **torch==2.11** required (not 2.10). torch+model.compile NaN bug at step 2 on Blackwell. Already in merged base.
- **`sample_tensor` float64 linspace fix** already in merged base (PR #46). All branches inherit.
- **stale_wip watchdog** is a recurring false positive tied to GitHub REST rate-limit resets. Always verify against W&B before acting.

## Next Research Directions (post wave-2 close-out)

When wave-2 closes (PRs #45/#48/#50/#121 likely negative; PRs #116/#123/#130/#141 open):

1. **Stack wave-2 winners** onto merged base progressively (→ record #19/#20 trajectory)
2. **Output Embedding Mean-Centering** (mu-centering): post-step `lm_head.weight -= lm_head.weight.mean(dim=0)`. Eliminates partition-function gauge drift; complements rather than duplicates label smoothing. Natural follow-up if GC succeeds or Newton-Muon wins.
3. **Polynomial-weighted schedule-free Muon** — retry tanjiro's PR #121 mechanism with `c_t = (t+1)^p / Σ(i+1)^p`, `p ∈ {2,4,6}`, OR warmup-discard variant (start averaging at t ≥ T/2).
4. **Polyak/SWA as postprocessing wrapper over SOAP-MLP base** — thorfinn's PR #50 is a stable sub-target recipe; wave-3 use is stacking over merged base.
5. **Gradient centralization on attn weights only** — if PR #141 Gradient Centralization close is a clean negative on all Muon params, attn-only application is NOT a valid follow-up (too close to SOAP-MLP isolation). Skip.
6. **AdamW aux-group decoupled LR schedules** (embed-flat + lm_head-aggressive cooldown) — schedule slot for non-Muon params
7. **KL-SOAP-H** (record #19) and **PMuon** (record #18) — novel covariance-update formulations; wave-3 candidates

## Standing Constraints (do not re-derive)

- **Banned sources**: anything under `primeintellect.ai/auto-nanogpt` or `PrimeIntellect-ai/experiments-autonomous-speedrunning`. Do not fetch, browse, cite, or use.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed. No per-run early stopping on val loss.
- **Reporting rule**: every terminal result needs the `SENPAI-RESULT` marker + predeclared n, mu, statsig margin, rule outcome. NaN/missing val/loss unacceptable.
- **GPU budget**: 1× 96 GB per student, ~1.8-2.0 s/step; plan run counts accordingly.
