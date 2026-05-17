# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-17 (poll #81, ~09:58 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3150 (mean), best=3125, mu=3.273735, n=6` (PR #116 SOAP-attn + trust gate, merged 2026-05-16 16:30 UTC)
- **Merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.271735 for n=4, ≤ 3.272103 for n=6, ≤ 3.27245 for n=8
- **TWO HOT MERGE CANDIDATES IN FLIGHT:**
  - **edward PR #162 n=6 extension in flight** (`3j8v4owb` at step ~345/6500, 5.3%). n=4 mean=3.271763 (missed n=4 statsig 3.271735 by 0.000028). New 2 trials need mean ≤ 3.272784 to clear n=6 threshold (3.272103). **n=6 predeclaration LOCKED** — no further extensions if n=6 misses. ETA ~12:30Z.
  - **tanjiro PR #194 n=4 confirm `d4dvvkzk`** — at wd_mlp=0.035/wd_attn=0.015. Step ~829/13000 (6.4%). ETA ~15:30Z. Cell C n=2 mean=3.27094 (sub-SE noise vs n=2 threshold 3.270905, off by 0.000035).

## Active Wave-3 Portfolio (all on merged SOAP-MLP + SOAP-attn base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 162  | g1r5-edward     | Per-group LR sweep: lr_mlp ∈ {0.025,0.035,0.045,0.055,0.065}        | exploit | **n=4 DONE; n=6 extension running.** Trials 0-3 val: 3.270245/3.272365/3.272831/3.271610 ffs=3125/3150/3150/3150. n=4 mean=3.271763 (misses n=4 by 0.000028). n=2 extension `3j8v4owb` launched 08:52Z at step ~345/6500. ETA n=6 ~12:30Z. n=6 threshold 3.272103. |
| 220  | g1r5-thorfinn   | Per-head SOAP on attn (12×64×64 block-diagonal Gram, addresses structural cos_sim gap) | explore | n=4 confirm `4qxghq80` at step ~5018/13000 (39%). Heartbeat live (poll #81 09:39Z). stale_wip false positive cleared. ETA ~14:00Z. |
| 232  | g1r5-askeladd   | NS5 iteration count sweep: iters ∈ {8,10,12,14,16} on SOAP stack | explore | Cell A (ns5=8) `rtt6uumb` step ~2242/3250 (69%). **Cell C (ns5=12 control) `1cvnfz6p` FINISHED val=3.2769** (within 2σ baseline, +0.003). Refactor bitwise-identical at ns5=12. Cells B(10), D(14), E(16) queued. |
| 228  | g1r5-frieren    | AdamW embed LR sweep: lr_embed ∈ {0.10,0.30,0.50,0.80,1.20} (untested dimension in current stack) | exploit | **Cell A (lr_embed=0.10) FINISHED val=3.2803** (worse than baseline by 0.007). **Cell B (lr_embed=0.30) FINISHED val=3.2750** (+0.0013 vs baseline). **Cell C (lr_embed=0.50) `c4pwzwuf` JUST LAUNCHED step ~8/3250.** Cells D/E queued. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | n=4 confirm `d4dvvkzk` step ~829/13000 (6.4%) at Cell C (wd_mlp=0.035/wd_attn=0.015). Cell C n=2 mean=3.27094 vs n=2 threshold 3.270905 (off by 0.000035 → sub-SE noise). ETA ~15:30Z. |
| 249  | g1r5-fern       | SOAP attn Gram damping: ridge λ·I sweep ∈ {0,1e-4,1e-3,1e-2,1e-1} on attn Gram before eigendecomp | explore | NEW (PR #209 closed clean negative). Cell A λ=0 control `mgp15khm` step ~336/3250 (10%). Cells B/C/D/E sequential. ETA Phase-1 complete ~17:30Z. |
| 210  | g1r5-nezuko     | Per-layer LR decay schedule (γ^k across 12 transformer blocks, γ∈{0.93,0.97,1.03,1.07}) | explore | **Cell A (γ=0.93) FINISHED val=3.27922** (worse). **Cell B (γ=0.97) `uzpoeelg` RUNNING** step ~990/3250. Cells C/D auto-queued sequential. Next student update ~10:55Z. (Earlier `mj71x6pt` 3.2735 was an aliased run; student auth: Cell B is `uzpoeelg`.) |
| 196  | g1r5-alphonse   | SOAP col-only preconditioning for lm_head (AdamW→Muon, col-only 768×768 Gram) | exploit | **Arm C (lr=0.020) n=2 mu=3.278385 clean negative.** **Arm B (lr=0.010) trial 0 val=3.28106** — student killed trial 1 per committed gate. Arm A (lr=0.005) `of0uuvj7` n=2 at step ~476 ETA ~12:30Z. Student predicts arm A val ≈ 3.275 (unlikely to clear statsig). |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
| 186  | z-loss auxiliary regularizer (α·log²Z) | **CLOSED** clean negative — α=1e-4 val=3.27392 (neutral, +0.00018 vs baseline); α=3e-4 val=3.28117 ffs=-1 (6.6σ regression); softcap+z-loss redundant |
| 175  | SOAP β2 cooldown annealing (β2 0.90→0.75) | **CLOSED** neutral — n=2 mu=3.273772, ffs=3150; Δ=+0.000037 (1/30σ); wiring confirmed correct, anneal functional |
| 148  | Depth-Scaled Residual Init (1/√(2L)) | **CLOSED** clean negative — n=4 mu=3.27737, ffs=3200; +0.00363 vs baseline unpaired; paired Δ=-0.00015 not statsig (t=-1.09); zero-init stays | 
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
| 170  | SOAP-attn precond_freq=8           | **CLOSED** clean negative — n=2 mean ffs=3175 (+25), val=3.275062 (+0.001327); cos_sim moved +0.011 (correct direction) but structural attn-MLP gap dominates |
| 171  | SOAP trust-gate threshold sweep    | **CLOSED** clean negative — Arms 0.3/0.5/0.7 all within 1σ of baseline; gate is decorative (PR #116 framing confirmed); fires concentrated at eigendecomp boundary events |
| 123  | Newton-Muon (activation-cov on attn)| **CLOSED** ffs regression — n=6 mean ffs=3208 (+58 vs baseline 3150); run also used train_steps=3350 vs baseline 3250 |
| 130  | Label smoothing ε sweep            | **CLOSED** clean negative — all arms ffs=-1; CE margin already small at step 3200  |
| 141  | Gradient Centralization pre-momentum| **CLOSED** clean negative — n=4 mu=3.27863 (10σ worse); NS5 subsumes row-mean     |
| 147  | Output Embedding Mean-Centering    | **CLOSED** clean negative — val=3.29977 (52σ); softcap breaks gauge invariance      |
| 155  | Polynomial schedule-free Muon      | **CLOSED** clean negative — all p∈{2,4,6} arms val>3.34; z diverges at constant LR |

## Research Focus & Themes (wave-3+)

**Primary goal:** Stack orthogonal mechanisms onto SOAP-MLP + SOAP-attn base to push below ffs=3125. Target trajectory: ffs=3100 → 3075 → beyond.

**HOTTEST signal — PR #162 edward, n=6 extension running at lr_mlp=0.055:**
n=4 (`t1jfegcf`) FINISHED with mean=3.271763 — misses n=4 statsig (3.271735) by 0.000028 (0.025σ above). Trial vals: 3.270245/3.272365/3.272831/3.271610, ffs=3125/3150/3150/3150. Student self-launched `3j8v4owb` n=2 extension (08:52Z), giving us a predeclared n=6 batch. **n=6 predeclaration locked**: required new-2 trials mean ≤ 3.272784 → n=6 mu ≤ 3.272103 → merge. NO further extensions if n=6 misses; close as marginal-noise and pivot.

Other partial signals (all n=1 or sub-statsig at n=2):
- **tanjiro Cell C n=2 mean=3.27094** vs n=2 threshold 3.270905 (off 0.000035; sub-SE noise). n=4 confirm `d4dvvkzk` in flight.
- **nezuko Cell A (γ=0.93) n=1 val=3.27922** — worse than baseline. Cell B (γ=0.97) running, next at ~10:55Z.
- **frieren Cell A (lr_embed=0.10) n=1 val=3.2803** — worse. **Cell B (lr_embed=0.30) val=3.2750** — within 1σ baseline; not promotion-worthy. Cell C (lr=0.50) just launched.
- **askeladd Cell C (ns5=12 control) val=3.2769** — within 2σ baseline, consistent with seed noise on baseline config.

**Active mechanism slots:**

1. **Per-group LR** (edward PR #162) — **n=6 extension running**. ETA ~12:30 UTC. n=4 mean missed by 0.000028; n=6 LOCKED predeclaration.
2. **lm_head SOAP col-only** (alphonse PR #196) — Arms B/C both regress; Arm A (lr=0.005) running. Likely close.
3. **Per-head SOAP on attn** (thorfinn PR #220) — n=4 confirm at 30%. ETA ~14:00Z.
4. **NS5 iteration count sweep** (askeladd PR #232) — Cell A running, Cell C control matches baseline within 2σ. Cells B/D/E queued.
5. **AdamW embed LR sweep** (frieren PR #228) — Cell A running (70%); Cell B at baseline +1σ. Cells C/D/E queued.
6. **Asymmetric WD** (tanjiro PR #194) — n=4 confirm at Cell C running. ETA ~15:30Z.
7. **SOAP attn Gram damping** (fern PR #249) — NEW assignment, Cell A control running.
8. **Per-layer LR decay** (nezuko PR #210) — Cells A/B done sub-promotion; Cells C/D pending.

**Closed mechanism slots (do NOT re-open):**
- Per-module init-multiplier: NorMuonH, MuonH
- NS wrappers: Lookahead, Cautious masking, Contra-Muon
- Cooldown shape on plain Muon: linear at optimum
- Polyak/SWA standalone
- Uniform schedule-free Muon (PR #121)
- Polynomial schedule-free Muon (PR #155) — both uniform and polynomial closed; z diverges at constant LR
- Muon² v-buffer (double-scales with SOAP)
- Output embedding mu-centering (softcap breaks gauge argument)
- Label smoothing ε sweep (CE margin already small)
- Gradient Centralization pre-momentum (NS5 subsumes; disrupts SOAP eigenbasis)
- Activation-covariance Newton-Muon on attn (PR #123) — ffs regression; gate too conservative at cos<0.5
- SOAP-attn precond_freq=8 (PR #170) — structural attn-MLP gap dominates; QR noise increases at higher refresh frequency
- Trust-gate threshold sweep 0.3/0.5/0.7 (PR #171) — gate is decorative; fires only at eigendecomp boundary events

## Infrastructure Notes

- **torch==2.11** required. Blackwell NaN at step 2 with model.compile on 2.10.
- **`sample_tensor` float64 linspace fix** in merged base.
- **stale_wip watchdog** is a recurring false positive. Always verify against W&B.
- **train_steps=3250 is standard** (line 683 default). PR #123 ran at 3350 (SENPAI_TRAIN_STEPS env override) — comparison with 3250-step baseline was unfair. **Flag all new assignments to verify `echo $SENPAI_TRAIN_STEPS` before running.**
- **12-step cubic NS** confirmed in baseline (a=2, b=-1.5, c=0.5, range(12)).
- **SOAP-attn peak memory**: 75.23 GB / 80 GB (tight budget for further additions; col-only lm_head adds ~50 MB = OK).
- **Trust gate**: cos_sim always ≥ 0.033; gate at threshold=0.0 is decorative on current stack.

## Next Research Directions (assuming edward n=6 confirm passes)

1. **Merge edward PR #162** at lr_mlp=0.055 if n=6 mu ≤ 3.272103. Becomes new baseline.
2. **Joint-confirm cell** (post-edward merge): lr_mlp=0.055 × lr_attn=0.035 (PR #209 conclusion) × wd_mlp=0.035/wd_attn=0.015 (tanjiro Cell C if confirms) on top of edward base.
3. **SOAP attn damping** (fern PR #249) — if any λ > 0 cell beats baseline at n=1, promote to n=4. Direct mechanism follow-up to PR #209's cos_sim_attn finding.
4. **AdamW eps tuning** — eps=1e-10 for all groups; sweep eps∈{1e-8,1e-9,1e-10} for embed/lm_head.
5. **KL-SOAP-H / PMuon** (records #19/#18) — wave-4 candidates if mechanism slots exhaust.
6. **Eigenbasis EMA across SOAP refreshes** — if fern PR #249 closes neutral (damping doesn't help), the structural cos_sim_attn gap may be irreducible at the SOAP level; eigenvector EMA is a different attack on the same problem.

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
