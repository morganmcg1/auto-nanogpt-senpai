# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-17 (poll #70, ~04:30 UTC)
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **Current baseline**: `ffs=3150 (mean), best=3125, mu=3.273735, n=6` (PR #116 SOAP-attn + trust gate, merged 2026-05-16 16:30 UTC)
- **Merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.271735 for n=4, ≤ 3.272103 for n=6, ≤ 3.27245 for n=8

## Active Wave-3 Portfolio (all on merged SOAP-MLP + SOAP-attn base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 162  | g1r5-edward     | Per-group LR sweep: lr_mlp ∈ {0.025,0.035,0.045,0.055,0.065}        | exploit | **STRONGEST SIGNAL — n=4 confirm RUNNING.** Trial 0 (`tysiwoqg`) val=**3.270245**, ffs=3125 (beats statsig at n=1). Combined n=4 job `t1jfegcf` step ~5415/13000 (~42% overall, trial 1 step ~2165/3250 ~67%). ETA ~08:40 UTC. Advisor approved expanding to n=6 if n=4 passes mu≤3.271735. |
| 220  | g1r5-thorfinn   | Per-head SOAP on attn (12×64×64 block-diagonal Gram, addresses structural cos_sim gap) | explore | NEW. Pod picked up assignment iter-37 at 04:28Z. Smoke launch imminent then n=4. |
| 175  | g1r5-askeladd   | SOAP β2 cooldown annealing (β2 0.90→0.75 over last 70% of training)   | exploit | WIP — full run `b5o53z6z` step ~4769/6500 (~73%). ETA ~05:15Z. SENPAI-RESULT pending. |
| 186  | g1r5-frieren    | z-loss auxiliary regularizer (α·log²Z on partition function, α∈{1e-4,3e-4,1e-3}) | explore | WIP — α=1e-4 run `2q5w7tek` finished (val 3.27392 ≈ baseline). α=3e-4 run `agn4is0t` step ~2836/3250 (~87%). ETA ~05:30Z. α=1e-3 launches sequential after. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | WIP — Cell A val=3.27791 (≈ baseline). Cell B `jq083ofi` finished recently. Cells C, D pending. |
| 209  | g1r5-fern       | Per-group lr_attn sweep: lr_attn ∈ {0.025,0.035,0.045,0.055}        | exploit | WIP — Phase 2 Cell A `j5i05ctb` lr_attn=0.025 full run in progress (advisor confirmed running via `vqjmay37` query). Cells C/D pending sequential. |
| 210  | g1r5-nezuko     | Per-layer LR decay schedule (γ^k across 12 transformer blocks, γ∈{0.93,0.97,1.03,1.07}) | explore | WIP — γ=0.93 full run `f3pabdl5` running. γ=0.97 next, then γ=1.03/1.07. |
| 196  | g1r5-alphonse   | SOAP col-only preconditioning for lm_head (AdamW→Muon, col-only 768×768 Gram) | exploit | WIP — Cell C running (`tsskmflu`). 4 prior crashes; current run past all failure points. |

## Closed PRs Summary

| PR # | Hypothesis                         | Outcome                                                                              |
|------|------------------------------------|--------------------------------------------------------------------------------------|
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

**HOTTEST signal — PR #162 edward, n=4 confirm running at lr_mlp=0.055:**
Cell E (lr=0.065) finished val=3.27236 (worse than D), ffs=3150. Inverted-U peak confirmed at lr_mlp=0.055. Cell D n=1: ffs=3125, val=**3.26987** — beats baseline by 0.00387 on val. Full n=1 screen monotonic A→D then reversion at E:
- A (lr=0.025): val=3.27769, ffs=3200
- B (lr=0.035): val=3.27569, ffs=3175 (control)
- C (lr=0.045): val=3.27131, ffs=3125
- **D (lr=0.055): val=3.26987, ffs=3125 (PEAK)**
- E (lr=0.065): val=3.27236, ffs=3150

n=4 confirm `t1jfegcf` running step ~605/3250 at lr_mlp=0.055 (started 01:23Z, ETA ~08:30 UTC).
Merge math n=4: need mu ≤ 3.271735. Cell D n=1 mu=3.26987 → slack 0.00187.
**Advisor approved expanding to n=6 if n=4 passes**, statsig n=6: mu ≤ 3.272103.

**Active mechanism slots:**

1. **Per-group LR** (edward PR #162) — **n=4 confirm at lr_mlp=0.055 running**. ETA ~08:30 UTC. If n=4 mu ≤ 3.271735, expand to n=6 then merge.
2. **lm_head SOAP col-only** (alphonse PR #196) — Cell C `vk1x1dno` step 1982/3250. 4 prior crashes; current run past failure point.
3. **Per-head SOAP on attn** (thorfinn PR #220) — 12×64×64 block-diagonal Gram replacing single 768×768. Addresses structural cos_sim gap from PR #170 closure. NEWLY ASSIGNED 04:00Z.
4. **SOAP β2 cooldown anneal** (askeladd PR #175) — full run `2br8i9ql` crashed at step 591 (external SIGTERM); restart smoke finished; full run relaunching.
5. **z-loss auxiliary** (frieren PR #186) — bf16 logsumexp fix applied; α=1e-4 run step ~1404, α=3e-4 run started 01:34Z.
6. **Asymmetric WD** (tanjiro PR #194) — Cell A val=3.27791 (≈ baseline); Cell B running step 1769; C/D pending.
7. **lr_attn sweep** (fern PR #209) — 4 smokes at lr_attn=0.045, no Phase-2 cells launched. **Advisor poking for status.**
8. **Per-layer LR decay** (nezuko PR #210) — γ=0.97 smokes done; γ=0.93 smoke running; full screen pending.

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

## Next Research Directions (assuming edward n=4/n=6 confirm passes)

1. **Merge edward PR #162** at lr_mlp=0.055 after n=6 confirm. Becomes new baseline at ffs≈3125, mu~3.270.
2. **2D grid (lr_mlp × lr_attn)** — if fern's lr_attn sweep also produces a winner, combine for n=4 confirm at joint optimum.
3. **lm_head SOAP col-only** (alphonse PR #196) — runs on existing SOAP-attn base.
4. **AdamW eps tuning** — eps=1e-10 for all groups; sweep eps∈{1e-8,1e-9,1e-10} for embed/lm_head.
5. **KL-SOAP-H / PMuon** (records #19/#18) — wave-4 candidates if mechanism slots exhaust.
6. **Close weak WIP**: Monitor PR #175 (askeladd β2 anneal — ETA 05:15Z), PR #186 (frieren z-loss — α=3e-4 in flight), PR #196 (alphonse lm_head) for kill-gate signals.
   - PR #148 (thorfinn depth-scaled init): CLOSED poll #69 as clean negative.

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
