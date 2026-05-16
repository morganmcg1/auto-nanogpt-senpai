# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #25, ~11:45 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3200, mu=3.27744, n=6` (PR #46 SOAP-MLP isolated, merged 2026-05-16 04:00 UTC)
- **Merge statsig rule**: `(3.27744 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27581 for n=6, ≤ 3.27603 for n=8.

## Active Wave-2/3 Portfolio (all on merged SOAP-MLP base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 45   | g1r5-edward     | Muon² (Adam v-buffer + NS, lr=0.10, record #7)                          | exploit | WIP — n=8 trial-6/8+ running. 5-trial mu ≈ 3.2780, borderline vs baseline. Needs mu ≤ 3.27603 to merge; unlikely given current trajectory. |
| 116  | g1r5-fern       | SOAP-attn + trust gate on merged SOAP-MLP base (→ record #16, ffs 3125) | exploit | WIP — conf run `c81z4php` at step ~11258 (~56%), healthy. **Highest-priority gradient-precond test in wave-2.** |
| 121  | g1r5-tanjiro    | Schedule-free Muon (Defazio z/x iterate, no cooldown, merged base)     | explore | WIP — β=0.95 finished (3.4322, kill-gate confirmed), β=0.90 finished (3.3661), β=0.98 at step 1725/3350 (~51%), ETA ~1h. Pre-decision: clean negative on uniform Polyak-Ruppert spec. |
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond before NS on attn     | exploit | WIP — **STRONGEST SCREEN SIGNAL**: screen val=3.2714 (14-σ outlier). n=6 confirm in flight. Gate 8.3% active, cov_cond_max=1.37e8. Highest-value confirm in portfolio. |
| 130  | g1r5-askeladd   | Label smoothing on CE training loss (ε ∈ {0.05, 0.1, 0.15})           | explore | WIP — ε=0.1 smoke done. Full 3-cell screen (ε∈{0.05,0.10,0.15}, n=1 each) pending/in-flight. |
| 141  | g1r5-frieren    | Gradient Centralization in Muon update (pre-momentum row-mean sub)     | explore | WIP — freshly assigned poll #24. One-line `grad -= grad.mean(dim=-1)` before `momentum.lerp_`. n=4 screen at 3200 steps. |
| 147  | g1r5-nezuko     | Output Embedding Mean-Centering (mu-centering) post optimizer step     | explore | **FRESHLY ASSIGNED** (poll #25). Post-step `lm_head.weight -= lm_head.weight.mean(dim=0)`. Zero new hyperparameters. n=4 screen, 3200 steps. |
| 148  | g1r5-thorfinn   | Depth-Scaled Residual Init (1/sqrt(2L) on attn.proj + mlp.proj)       | explore | **FRESHLY ASSIGNED** (poll #25). One-time init change: scale residual output projections by `1/sqrt(24) ≈ 0.204`. n=4 screen, 3200 steps. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962, fails statsig; +0.00218 above baseline |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876, fails statsig; ffs=3325 +125 steps slow|
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; new baseline                              |
| 47   | MuonH (record #5 reproduction)     | **CLOSED** clean negative — n=8 mu=3.28088; per-module init-multiplier env failure  |
| 48   | Cooldown shape sweep (plain Muon)  | **CLOSED** clean negative — best shape power_α1.2 mu=3.27827 n=2; below confirmation trigger; linear is at local optimum |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative — no speedup                                               |
| 50   | Polyak/SWA tail averaging          | **CLOSED** clean negative — n=6 mu=3.27828, ffs=3304; stable sub-target but above baseline |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — val strictly increases with LR mult; mask harms NS      |

## Research Focus & Themes (wave-2/3)

**Primary goal:** stack orthogonal mechanisms onto the merged SOAP-MLP base to push below ffs=3200 / mu=3.27744. Target trajectory: record #14 (ffs=3150) → record #16 (ffs=3125) → beyond.

**Active mechanism slots:**

1. **Gradient-precond on attn** (fern PR #116 SOAP-attn trust gate) — targets record #16 trajectory, conf run at ~56%. **Highest-priority** gradient-precond test.
2. **Activation-precond on attn** (alphonse PR #123 Newton-Muon) — STRONGEST SCREEN (val=3.2714, 14-σ). n=6 confirm running. Newton gate 8.3% active — may be lucky seed or hook-induced regularization. Disambiguates at n=6.
3. **Pre-momentum gradient transform** (frieren PR #141 Gradient Centralization) — one-line `grad -= grad.mean(dim=-1)`. Screen n=4 at 3200 steps.
4. **Post-step embedding** (nezuko PR #147 mu-centering) — post-step `lm_head.weight -= mean`. Zero hyperparams. Screen n=4 at 3200 steps.
5. **Init** (thorfinn PR #148 depth-scaled init) — one-time `1/sqrt(24)` scale on attn.proj+mlp.proj. Screen n=4 at 3200 steps.
6. **Loss layer** (askeladd PR #130 label smoothing) — ε ∈ {0.05,0.10,0.15}; smoke done, screen pending.
7. **Schedule layer kill-gate** (tanjiro PR #121 Schedule-free Muon) — finishing β=0.98 cell (~1h); clean negative on uniform Polyak-Ruppert spec, queued wave-3 retry with polynomial weighting.
8. **Gradient-precond before NS** (edward PR #45 Muon²) — borderline at partial 5/8; final 3 seeds determine merge eligibility.

**Closed mechanism slots (do NOT re-open without strong prior):**
- **Per-module init-multiplier family PERMANENTLY CLOSED**: NorMuonH (PR #43), MuonH (PR #47) — Blackwell+torch 2.11 bf16 NS5 path interaction
- NS wrappers: Lookahead (PR #49), Cautious masking (PR #98), Contra-Muon isolated (PR #44)
- **Cooldown shape on plain Muon** (PR #48): linear is at local optimum. Cosine/power_α0.6/trapezoidal fail materially.
- **Polyak/SWA as standalone** (PR #50): stable sub-target, does not beat SOAP-MLP baseline

## Infrastructure Notes

- **torch==2.11** required (not 2.10). Blackwell NaN at step 2 with model.compile on 2.10. In merged base.
- **`sample_tensor` float64 linspace fix** in merged base. All branches inherit.
- **stale_wip watchdog** is a recurring false positive tied to GitHub REST rate-limit resets. Always verify against W&B before acting.

## Next Research Directions (post wave-2/3 close-out)

When current wave closes:

1. **Stack wave-2/3 winners** progressively onto merged base.
2. **Polynomial-weighted schedule-free Muon** — retry tanjiro's PR #121 with `c_t = (t+1)^p / Σ(i+1)^p`, `p ∈ {2, 4, 6}`, or warmup-discard (start averaging at t ≥ T/2). Closes the spec issue from PR #121.
3. **Polyak/SWA as stacking wrapper over SOAP-MLP base** — (τ=0.20, β=0.995) on top of merged base, not standalone. Natural wave-3 after thorfinn PR #148.
4. **KL-SOAP-H** (record #19) and **PMuon** (record #18) — novel covariance-update formulations; wave-3/4.
5. **AdamW aux-group decoupled LR schedules** (embed-flat + lm_head-aggressive cooldown) — low priority vs current portfolio.

## Standing Constraints (do not re-derive)

- **Banned sources**: anything under `primeintellect.ai/auto-nanogpt` or `PrimeIntellect-ai/experiments-autonomous-speedrunning`. Do not fetch, browse, cite, or use.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig margin, rule outcome. NaN/missing val/loss unacceptable.
- **GPU budget**: 1× 96 GB per student, ~1.8-2.0 s/step.
