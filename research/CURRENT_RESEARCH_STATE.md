# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-16 (poll #39, ~17:30 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3150 (mean), best=3125, mu=3.273735, n=6` (PR #116 SOAP-attn + trust gate, merged 2026-05-16 16:30 UTC)
- **Merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27210 for n=6, ≤ 3.27245 for n=8

## Active Wave-3 Portfolio (all on merged SOAP-MLP + SOAP-attn base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 123  | g1r5-alphonse   | Newton-Muon: activation-covariance right-precond before NS on attn     | exploit | WIP — n=6 confirm running. 3 trials done: best_val=[3.27019, 3.27175, 3.27008], n=3 mu=3.270673. **Beats new baseline (3.273735)**. Likely merge candidate. ETA ~6h total. |
| 130  | g1r5-askeladd   | Label smoothing on CE training loss (ε ∈ {0.05, 0.1, 0.15})           | explore | WIP — ε=0.05 done val=3.325, ε=0.10 done val=3.381, ε=0.15 running. All arms well above target. Likely clean negative. |
| 141  | g1r5-frieren    | Gradient Centralization in Muon update (pre-momentum row-mean sub)     | explore | WIP — 2 trials done: best_val=[3.27880, 3.27902]. Both **above new baseline** 3.273735. Trending weak/negative. |
| 148  | g1r5-thorfinn   | Depth-Scaled Residual Init (replace zero-init with `1/sqrt(24)` Gaussian on residual output projections) | explore | WIP — trial 0 best_val=3.28093 (above target 3.28). Running n=4. Trending weak. |
| 155  | g1r5-tanjiro    | Polynomial-Weighted Schedule-Free Muon (c_t=(t+1)^p / Σ(i+1)^p, p∈{2,4,6}) | explore | WIP — arm 1 val=3.341, arm 2 running. Trending negative vs even old baseline. |
| 162  | g1r5-edward     | Per-group LR sweep: SOAP-managed MLP vs plain-Muon attn (lr_mlp ∈ {0.025,0.035,0.045,0.055}) | exploit | WIP — trial 0 (eabllnva) done: best_val=3.27569 ffs=3175 — above new baseline; trial 1 running. |
| 170  | g1r5-fern       | SOAP-attn precond_freq=8 (halve attn eigenbasis refresh period vs MLP=16) | exploit | WIP — newly assigned, awaits run start. |
| 171  | g1r5-nezuko     | SOAP trust-gate threshold sweep (0.3 / 0.5 / 0.7) on SOAP-attn base   | exploit | WIP — newly assigned, awaits run start. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 43   | NorMuonH (record #8)               | **CLOSED** clean negative — n=8 mu=3.27962; numerical failure                       |
| 44   | Contra-Muon isolated               | **CLOSED** clean negative — n=8 mu=3.27876; ffs=3325 +125 steps slow               |
| 45   | Muon² (Adam v-buffer + NS, lr=0.10)| **CLOSED** clean negative — n=8 mu=3.27843, +100 ffs slower than SOAP-MLP           |
| 46   | SOAP-MLP isolated                  | **MERGED ✓** — ffs=3200, mu=3.27744, n=6; former baseline                          |
| 47   | MuonH (record #5 reproduction)     | **CLOSED** clean negative — n=8 mu=3.28088                                          |
| 48   | Cooldown shape sweep (plain Muon)  | **CLOSED** clean negative — linear at local optimum                                  |
| 49   | Lookahead k×α over Muon            | **CLOSED** clean negative                                                             |
| 50   | Polyak/SWA tail averaging          | **CLOSED** clean negative — above baseline                                           |
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — mask harms NS                                           |
| 116  | SOAP-attn + trust gate             | **MERGED ✓** — ffs=3150/3125, mu=3.273735, n=6; **current baseline**               |
| 121  | Schedule-free Muon (uniform c_t)   | **CLOSED** clean negative — val_x=3.366; z diverges + warmup mass dominates        |
| 147  | Output Embedding Mean-Centering    | **CLOSED** clean negative — val=3.29977 (52σ); softcap breaks gauge invariance      |

## Research Focus & Themes (wave-3+)

**Primary goal:** Stack orthogonal mechanisms onto SOAP-MLP + SOAP-attn base to push below ffs=3125. Target trajectory: ffs=3100 → 3075 → beyond.

**Active mechanism slots:**

1. **Activation-precond on attn** (alphonse PR #123 Newton-Muon) — n=3 mu=3.270673 already beats new baseline. If n=6 confirms mu ≤ 3.27210, merge immediately.
2. **Pre-momentum transform** (frieren PR #141 GC) — trending weak, both trials above new baseline.
3. **Init** (thorfinn PR #148 depth-scaled) — trial 0 above 3.28 target, likely close.
4. **Schedule-free poly** (tanjiro PR #155) — all arms trending negative.
5. **Loss layer** (askeladd PR #130 label smooth) — all ε negative, close when ε=0.15 done.
6. **Per-group LR** (edward PR #162) — trial 0 done best_val=3.27569 (above new baseline).
7. **Attn precond_freq=8** (fern PR #170) — researcher-agent Idea 1.
8. **Trust-gate threshold sweep** (nezuko PR #171) — researcher-agent Idea 3.

**Closed mechanism slots (do NOT re-open):**
- Per-module init-multiplier: NorMuonH, MuonH
- NS wrappers: Lookahead, Cautious masking, Contra-Muon
- Cooldown shape on plain Muon: linear at optimum
- Polyak/SWA standalone
- Uniform schedule-free Muon
- Muon² v-buffer (double-scales with SOAP)
- Output embedding mu-centering (softcap breaks gauge argument)

## Infrastructure Notes

- **torch==2.11** required. Blackwell NaN at step 2 with model.compile on 2.10.
- **`sample_tensor` float64 linspace fix** in merged base.
- **stale_wip watchdog** is a recurring false positive. Always verify against W&B.
- **PR #148 reframe**: zero-init on all proj.weight; replace with depth-scaled Gaussian.
- **12-step cubic NS** confirmed in baseline (a=2, b=-1.5, c=0.5, range(12)).
- **SOAP-attn peak memory**: 75.23 GB / 80 GB (tight budget for further additions).
- **Trust gate**: cos_sim always ≥ 0.033; gate at threshold=0.0 is decorative on current stack.

## Next Research Directions (post PR #116 merge)

1. **Stack Newton-Muon on SOAP-attn base** (alphonse PR #123) — if n=6 mu ≤ 3.27210, merge immediately.
2. **Precond_freq=8 on attn only** — attn cos_sim 0.08 lower than MLP; eigenbases may drift faster. Low-cost (smoke + n=4).
3. **SOAP to lm_head.weight** — largest weight (currently AdamW). Memory at 75.23 GB; try precond_freq=32.
4. **KL-SOAP-H / PMuon** (records #19/#18) — wave-3/4 candidates.
5. **Asymmetric per-group WD** — wd_mlp vs wd_attn variation, orthogonal to LR sweep.
6. **Close weak WIP**: PR #130/#141/#148/#155 trending negative; close promptly when terminal.

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
