# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #29, ~13:55 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3200, mu=3.27744, n=6` (PR #46 SOAP-MLP isolated, merged 2026-05-16 04:00 UTC)
- **Merge statsig rule**: `(3.27744 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27581 for n=6, ≤ 3.27603 for n=8.

## Active Wave-2/3 Portfolio (all on merged SOAP-MLP base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 116  | g1r5-fern       | SOAP-attn + trust gate on merged SOAP-MLP base (→ record #16, ffs 3125) | exploit | WIP — conf run at ~56% last check. **Highest-priority** gradient-precond test in wave-2. |
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond before NS on attn     | exploit | WIP — **STRONGEST SCREEN SIGNAL**: screen val=3.2714 (14-σ outlier). n=6 confirm running. Newton gate 8.3% active — mechanism uncertain. |
| 130  | g1r5-askeladd   | Label smoothing on CE training loss (ε ∈ {0.05, 0.1, 0.15})           | explore | WIP — ε=0.1 smoke done. 3-cell screen pending/in-flight. |
| 141  | g1r5-frieren    | Gradient Centralization in Muon update (pre-momentum row-mean sub)     | explore | WIP — freshly assigned poll #24. n=4 screen at 3200 steps. |
| 147  | g1r5-nezuko     | Output Embedding Mean-Centering (mu-centering) post optimizer step     | explore | WIP — freshly assigned poll #25. Post-step `lm_head.weight -= mean`. n=4 screen, 3200 steps. |
| 148  | g1r5-thorfinn   | Depth-Scaled Residual Init (1/sqrt(2L) on attn.proj + mlp.proj)       | explore | WIP — reframed poll #26: replace zero-init with depth-scaled Gaussian on residual output projections (zero-init was a no-op with the literal spec). n=4 screen, 3200 steps. |
| 155  | g1r5-tanjiro    | Polynomial-Weighted Schedule-Free Muon (c_t=(t+1)^p / Σ(i+1)^p, p∈{2,4,6}) | explore | WIP — freshly assigned poll #27. Wave-3 retry fixing the c_t=1/(t+1) uniform-averaging spec issue from PR #121. Fixed β=0.90, cooldown_frac=0, p sweep. 3-cell screen × n=1. |
| 162  | g1r5-edward     | Per-group LR sweep: SOAP-managed MLP vs plain-Muon attn (lr_mlp ∈ {0.025,0.035,0.045,0.055}) | exploit | WIP — assigned poll #29 (PR #159 auto-closed by branch-merge mistake; PR #162 is the active assignment). Tests whether SOAP's covariance preconditioner enables a higher base lr for the MLP group than lr=0.035 inherited from pre-SOAP record #12. Control cell B enforces identity check. 4-cell × n=2 screen. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962; environmental numerical failure         |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876; ffs=3325 +125 steps slow               |
| 45   | Muon² (Adam v-buffer + NS, lr=0.10, record #7) | **CLOSED** clean negative — n=8 mu=3.27843, ffs=3300; passes 3.28 target rule but +100 steps slower than SOAP-MLP baseline. 12-step cubic NS was already in merged base — only delta was v-buffer + lr=0.10. |
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; current baseline                          |
| 47   | MuonH (record #5 reproduction)     | **CLOSED** clean negative — n=8 mu=3.28088; per-module init-multiplier env failure  |
| 48   | Cooldown shape sweep (plain Muon)  | **CLOSED** clean negative — power_α1.2 best at mu=3.27827 n=2; linear at local optimum |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative — no speedup                                               |
| 50   | Polyak/SWA tail averaging          | **CLOSED** clean negative — n=6 mu=3.27828; stable sub-target, above baseline       |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — mask harms NS                                           |
| 121  | Schedule-free Muon (uniform c_t=1/(t+1)) | **CLOSED** clean negative on spec — best β=0.90 val_x=3.366; two failure modes: z diverges under constant LR + warmup mass dominates uniform Polyak-Ruppert averaging |

## Research Focus & Themes (wave-2/3)

**Primary goal:** stack orthogonal mechanisms onto the merged SOAP-MLP base to push below ffs=3200 / mu=3.27744. Target trajectory: ffs=3150 → 3125 → beyond.

**Active mechanism slots:**

1. **Gradient-precond on attn** (fern PR #116 SOAP-attn trust gate) — targets record #16 trajectory. Conf run ~56% last check.
2. **Activation-precond on attn** (alphonse PR #123 Newton-Muon) — STRONGEST SCREEN (val=3.2714, 14-σ). n=6 confirm running.
3. **Pre-momentum gradient transform** (frieren PR #141 Gradient Centralization) — `grad -= grad.mean(dim=-1)`. n=4 screen.
4. **Post-step embedding** (nezuko PR #147 mu-centering) — post-step `lm_head.weight -= mean`. n=4 screen.
5. **Init** (thorfinn PR #148 depth-scaled init) — reframed: replace zero-init with `1/sqrt(24)` Gaussian on residual outputs. n=4 screen.
6. **Schedule-free (polynomial c_t)** (tanjiro PR #155) — wave-3 retry with `c_t = (t+1)^p / Σ` concentrating weight on post-warmup iterates. p ∈ {2,4,6} sweep.
7. **Loss layer** (askeladd PR #130 label smoothing) — ε screen pending.
8. **Per-group LR exploitation** (edward PR #159) — FRESHLY ASSIGNED; tests whether SOAP-managed MLP params can use a higher base lr than the lr=0.035 inherited from pre-SOAP Muon.

**Closed mechanism slots (do NOT re-open without strong prior):**
- **Per-module init-multiplier family CLOSED**: NorMuonH (PR #43), MuonH (PR #47)
- NS wrappers: Lookahead (PR #49), Cautious masking (PR #98), Contra-Muon isolated (PR #44)
- Cooldown shape on plain Muon (PR #48): linear is at local optimum
- **Polyak/SWA as standalone** (PR #50): above baseline
- **Uniform schedule-free Muon (c_t=1/(t+1))** (PR #121): spec-level negative on this 3350-step from-scratch benchmark; wave-3 retry with polynomial c_t in progress (PR #155)
- **Muon² v-buffer (PR #45)**: passes 3.28 target but +100 ffs slower than SOAP-MLP baseline. v-buffer × SOAP double-scaling diagnosis confirmed. 12-step cubic NS was already in merged baseline.

## Infrastructure Notes

- **torch==2.11** required. Blackwell NaN at step 2 with model.compile on 2.10. In merged base.
- **`sample_tensor` float64 linspace fix** in merged base. All branches inherit.
- **stale_wip watchdog** is a recurring false positive tied to GitHub REST rate-limit resets. Always verify against W&B before acting.
- **PR #148 reframe**: modded-nanogpt zero-initializes all `proj.weight` tensors (Fixup-style residual-zero-init). Literal `weight.mul_(1/sqrt(2L))` on zero is a no-op. Correct interpretation: replace zero-init with `normal_(std=(0.33/d)^0.5 / sqrt(2L))` on residual output projections only.
- **12-step cubic NS confirmed in baseline**: `zeropower_via_newtonschulz5` in merged `train_gpt_simple.py` already uses `a=2, b=-1.5, c=0.5`, `range(12)`. The researcher-agent note about this being a Muon² addition was incorrect — it was already present before PR #45.

## Next Research Directions (post wave-2/3 close-out)

1. **Stack wave-2/3 winners** progressively onto merged base.
2. **Polynomial-weighted schedule-free Muon** (PR #155) — if p sweep shows val_x ≤ 3.30, promote to n=4 confirm.
3. **Per-group LR exploitation** (PR #159) — if lr_mlp > 0.035 beats control, merge and compound.
4. **Polyak/SWA stacking wrapper over SOAP-MLP base** (not standalone — PR #50 closed that path).
5. **KL-SOAP-H** (record #19) and **PMuon** (record #18) — wave-3/4 candidates.
6. **Selective v-buffer on plain-Muon attn path** — deferred; wait for PR #116 (fern SOAP-attn) result first to clarify the attn-path preconditioning landscape.

## Standing Constraints (do not re-derive)

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`. Do not fetch, browse, cite, or use.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig margin, rule outcome.
- **GPU budget**: 1× 96 GB per student, ~1.8-2.0 s/step.
