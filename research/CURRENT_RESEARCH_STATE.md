# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-17 (poll #108, ~19:49 UTC)
- **⭐⭐⭐ FRIEREN PHASE 2 ON TRACK — 2/4 trials TERMINAL, BOTH STRONG**:
  - Trial 0=3.270223 ffs=3125
  - **Trial 1=3.269885 ffs=3125** (BELOW n=4 threshold 3.269362 individually — single-best result in entire round!)
  - 2-trial mean=3.270054 (std=0.000239)
  - Trial 2/4 in-flight, ym6jprxe step 8514/13000 (~2013/3250 within trial, ~62% of trial 2)
  - Trial 3/4 pending (~110 min after t2 terminal)
  - ETA trial 2 terminal **~20:20Z** (~30 min); n=4 terminal **~22:10Z** (~2h20m)
  - For n=4 merge (mu ≤ 3.269362), trials 2+3 mean must be ≤ 3.268670 (tight but feasible — trial-to-trial std only 0.00024)
  - **POTENTIAL FIRST MERGE WINNER SINCE PR #162.** PR has `needs_rebase` — student warned at 17:35Z to prep rebase post-terminal.
- **NEW TERMINALS THIS POLL (2 cells):**
  - **EDWARD Cell C** (β2_init=0.50, warmup over 500) FINISHED **val=3.27154 ffs=3150** (Δ=+0.00018 vs baseline, ~0.15σ — best edward cell, ~baseline). **CORRECTION from poll #107**: my prior speculation that Cell C would fail 3.28 kill gate was wrong — the 3.28892 reading was mid-validation, final terminal=3.27154. Pattern: A(no warmup)=3.27266, B(50/200)=3.27340 (worst), **C(50/500)=3.27154 ⭐**. Longer warmup with low β₂ init helps. Cell D (0.70/200) running step 787. If Cell C holds at n=4, marginal merge candidate (~3.270 mu projected).
  - **TANJIRO Trial 1/4** at step 6501 of n=4 run: val=3.27195 ffs=3150 (already terminal). 2-trial mean=3.271755. For n=4 merge mu ≤ 3.269362, trials 2+3 mean must be ≤ 3.266969 — essentially impossible at trial std ~0.0002. **NOT a merge candidate**; let it finish for clean closure ~04:30Z.
- **NEAR-TERMINAL (~5-10 min):**
  - **askeladd** NS5 coeff Cell A `g1r5-askeladd/ns5-coeff-A` step 3031/3250 (~93%, ETA ~7 min). First terminal of NS5 coeff sweep imminent.
  - **alphonse** Cell D (eps=1e-7) step 3000/3250 (~92%, ETA ~8 min). val=3.2957 mid-eval. Likely closes sweep clean-neutral if D > 3.28 or marginal.
- **MID-FLIGHT (no action):**
  - **thorfinn** Cell D (α=0.7) step 1004/3250 (~31%).
  - **nezuko** Cell C (λ=0.03) step 1014/3250 (~31%).
  - **fern** SOAP Q/K shared Gram Cell A step 2095/3250 (~64%). ETA ~1h.
- **Most recent research direction from human researcher team:** none (no open GitHub issues for `auto-nanogpt-1gpu-r5`).
- **⭐ NEW BASELINE (2026-05-17 12:42Z):** `ffs=3141.67 (mean), best=3125, mu=3.271362, std=0.001181, n=6` — PR #162 per-group-lr lr_mlp=0.055 **MERGED**
- **NEW merge statsig rule**: `(3.271362 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ **3.269362** for n=4, ≤ **3.269729** for n=6, ≤ **3.269948** for n=8
- **IMPORTANT:** All in-flight sweeps were designed against old baseline (3.273735). None will merge vs new baseline at n=1. Continue to completion for relative comparisons; follow-ups should combine winning configs with lr_mlp=0.055.
- **tanjiro PR #194** notified: n=4 confirm unlikely to merge vs new baseline (trial 0=3.27040 → need trials 1-3 mean ≤ 3.269 → extremely tight). Collecting n=4 data for scientific value; reassigning to joint-confirm (lr_mlp=0.055 + wd tweaks) after completion.

## Active Wave-3 Portfolio (all on merged SOAP-MLP + SOAP-attn base)

| PR # | Student         | Hypothesis                                                              | Type    | Status                                               |
|------|-----------------|-------------------------------------------------------------------------|---------|------------------------------------------------------|
| 162  | g1r5-edward     | Per-group LR sweep: lr_mlp ∈ {0.025,0.035,0.045,0.055,0.065}        | exploit | **✅ MERGED 12:42Z** — n=6 mu=3.271362, ffs_mean=3141.67. New baseline. |
| 220  | g1r5-thorfinn   | Per-head SOAP on attn (12×64×64 block-diagonal Gram) | explore | **CLOSED 12:07Z** — trials 0/1 = 3.27368/3.28081. Per-head Grams have MORE eigenvec noise, not less. Clean negative. Reassigned PR #264 (eigvec EMA). |
| 210  | g1r5-nezuko     | Per-layer LR decay (γ^k across 12 transformer blocks) | explore | **CLOSED 16:00Z** clean negative — best Cell C (γ=1.03)=3.27433 Δ=+0.00297 vs new baseline. Doesn't stack with per-group LR. Reassigned PR #283 (AGC). |
| 264  | g1r5-thorfinn   | SOAP eigvec EMA: smooth attn eigenbasis across refreshes (α sweep 0,0.3,0.5,0.7,0.9) | explore | Cell A FINISHED val/loss=3.2750. **Cell B (α=0.3) `37w0mwla` step 1066/3250 (33%) val=3.6168.** Cells C/D/E sequential. |
| 270  | g1r5-edward     | SOAP beta2 cold-start warmup: ramp β₂ from low→0.90 over first K steps to fix early eigenvec noise | explore | **Cell A (ctrl, β₂=0.90 no warmup) FINISHED val/loss=3.2727** (+0.0014 above new baseline, 1.1σ within noise). Cell B (β₂_init=0.50/200) should auto-launch sequentially. |
| 262  | g1r5-alphonse   | AdamW eps sweep on embed/lm_head: eps ∈ {1e-10, 1e-9, 1e-8, 1e-7} | exploit | Cell A (1e-10) FINISHED 3.2738. **Cell B (1e-9) FINISHED 3.2739** (Δ=+0.0025). **Cell C (1e-8) `74bh7oal` step 173/3250 (5%) auto-launched.** Cell D queued. |
| 232  | g1r5-askeladd   | NS5 iteration count sweep: iters ∈ {8,10,12,14,16} on SOAP stack | explore | **CLOSED 19:00Z clean-neutral** — Cell B (iters=10) n=2 mean=3.27295 (Δ=+0.00159 vs new baseline). Default iters=12 stays. |
| 301  | g1r5-askeladd   | NS5 polynomial coeff sweep: (a,b,c) at fixed iters=12 | explore | **ASSIGNED 19:00Z**. Sweep: A=ctrl(2,-1.5,0.5), B=Muon-paper(3.4445,-4.775,2.0315), C=(2.5,-2.5,1.0), D=(1.7,-1.1,0.4), E=(4,-6,3). Phase 1 ETA ~5h, then n=4 Phase 2 if best cell ≤ 3.270. |
| 228  | g1r5-frieren    | AdamW embed LR sweep: lr_embed ∈ {0.10,0.30,0.50,0.80,1.20}; **Phase 2: n=4 confirm at D config** | exploit | Cells A(0.10)=3.2803, B(0.30)=3.2750, C(0.50)=3.2740, **D(0.80)=3.2707 ⭐**, E(1.20)=3.2715 ALL FINISHED. **⭐ Phase 2 n=4 `ym6jprxe` step 1897/13000 (14.6%) val=3.4589 (mid-train healthy).** ETA terminal ~8h. If mean ≤ 3.269362, NEXT MERGE. PR has merge conflicts — rebase before merging. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | **CLOSED 16:25Z clean-neutral vs new baseline.** n=4 mean=3.271133 ffs=3131.25. Δ=-0.000229 vs new baseline (0.11× statsig gate). WAS 1.30× statsig vs OLD baseline. Reassigned to PR #289 combo-confirm. |
| 289  | g1r5-tanjiro    | Combo-confirm: lr_mlp=0.055 (merged) + wd_mlp=0.035/wd_attn=0.015 (best WD corner) at n=4 | exploit | **ASSIGNED 16:30Z.** Tests additive composition of lr_mlp + asymm WD. Expected mu ~3.2688 if additive → below n=4 merge threshold 3.269362. ETA Phase-1 terminal ~23:30Z. |
| 249  | g1r5-fern       | SOAP attn Gram damping: ridge λ·I sweep ∈ {0,1e-4,1e-3,1e-2,1e-1} on attn Gram before eigendecomp | explore | **CLOSED 20:05Z clean-neutral**. All 5 cells regress: A=3.27518, **B=3.27300** (best), C=3.27493, D=3.27478, E=3.27380. Light damping (λ=1e-4) marginally best; none beat new baseline (Δ=+0.00164 for B). |
| 302  | g1r5-fern       | SOAP attn Q/K shared Gram preconditioner | explore | **ASSIGNED 20:05Z**. 2-cell screen: A=ctrl (separate Q/K Grams), B=shared Q/K Gram. Tests if doubling curvature signal + Q/K symmetry helps. Phase 2 n=4 confirm if Cell B ≤ 3.270. ETA Phase 1 ~2h. |
| 210  | g1r5-nezuko     | Per-layer LR decay schedule (γ^k across 12 transformer blocks, γ∈{0.93,0.97,1.03,1.07}) | explore | **CLOSED 16:00Z** clean negative — all 4 cells A=3.27922, B=3.27563, C=3.27433, D=3.27501 worse than new baseline (best C γ=1.03 Δ=+0.003). Per-layer LR doesn't stack with per-group LR meaningfully. Reassigned PR #283 (AGC). |
| 283  | g1r5-nezuko     | Adaptive Gradient Clipping (AGC, NFNets-style, λ ∈ {0,0.01,0.03,0.1,0.3}) | explore | **Cell A (λ=0 ctrl) `1j9tl8k9` step 1439/3250 (44%) val=3.5446.** ETA ~2.5h. Sequential cells B/C/D/E queued. |
| 196  | g1r5-alphonse   | SOAP col-only preconditioning for lm_head (AdamW→Muon, col-only 768×768 Gram) | exploit | **CLOSED 11:33Z** — all 3 LR arms regress vs old baseline. Vocab-row curvature is load-bearing for lm_head; Muon spectral norm is wrong inductive bias. Reassigned PR #262 (AdamW eps). |

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
| 98   | Cautious-Muon (sign-agreement mask)| **CLOSED** clean negative — mask harms NS. Note: PR #269 accidentally re-opened same idea; closed immediately upon detection.                                           |
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

**Primary goal:** Stack orthogonal mechanisms onto lr_mlp=0.055 base to push below ffs=3125. Target trajectory: ffs=3100 → 3075 → beyond.

**⭐ PR #162 (edward) MERGED 12:42Z — NEW baseline mu=3.271362, ffs_mean=3141.67.** New n=4 threshold = 3.269362. All prior in-flight sweeps vs old baseline will close as neutral; follow-ups combine with lr_mlp=0.055.

**Next signals to compile (all vs old baseline, report then close/reassign):**
- **tanjiro PR #194 n=4:** trial 0=3.27040. ETA ~15:30Z. Will close vs new baseline; reassign combo-confirm (lr_mlp=0.055 + wd tweaks).
- **askeladd NS5 sweep:** ns5∈{8,10,12,14,16}. Cells A=3.27444, B=3.2739, C=3.27687 at n=1 (all vs old baseline). Watch if ns5=8 wins screen.
- **frieren embed LR sweep:** Cells A/B/C done: 3.2803/3.2750/3.2740. Cell C (lr_embed=0.50) = best so far. Cell D running.
- **fern SOAP attn damping:** λ=0 ctrl=3.2752. Cell B (λ=1e-4) nearly done.
- **nezuko per-layer LR:** Cells A/B done (3.2792/3.2756). Cell C running.
- **NEW — thorfinn PR #264** SOAP eigvec EMA (just assigned); **NEW — alphonse PR #262** AdamW eps sweep (just assigned).

**Active mechanism slots (NEW baseline mu=3.271362):**

1. **Per-group LR** (edward PR #162) — **MERGED ✓** 12:42Z. lr_mlp=0.055 is new baseline.
2. **AdamW embed LR — PHASE 2 n=4** (frieren PR #228) — ⭐ HOTTEST. Phase 1 done: D(0.80)=3.2707 best, E(1.20)=3.2715. n=4 confirm `ym6jprxe` step 442/13000 (3.4%), ETA terminal ~22:30Z.
3. **SOAP eigvec EMA** (thorfinn PR #264) — Cell A α=0 ctrl FINISHED val/loss=3.2750 ffs=3175 (above new baseline Δ=+0.0036). Cell B (α=0.3) `37w0mwla` step 443/3250 auto-launched. C/D/E sequential.
4. **Combo-confirm** (tanjiro PR #289) — NEW 16:30Z. Tests lr_mlp=0.055 + wd_mlp=0.035 + wd_attn=0.015 at n=4. If additive, expected mu ~3.2688 → merges at n=4. PR #194 closed neutral. Student implementation note: WD-split code from PR #194 branch needs re-adding.
5. **NS5 iteration count sweep** (askeladd PR #232) — A(8)=3.27444, B(10)=3.27390 best, C(12)=3.27687, D(14)=3.27480 done. Cell E(16) `ra03b9q7` step 2249/3250 (69%). None beat new baseline.
6. **AdamW eps sweep** (alphonse PR #262) — A(1e-10)=3.2738 done. Cell B(1e-9) `ptcttsgd` step 1441/3250 (44%). C/D queued.
7. **SOAP beta2 cold-start warmup** (edward PR #270) — Cell A ctrl `z0xf0p9l` step 2591/3250 (79.7%) val=3.3714, ETA ~1h. B/C/D/E sequential.
8. **SOAP attn Gram damping** (fern PR #249) — A(λ=0)=3.2752, B(1e-4)=3.2730 best, C(1e-3)=3.2749 done. Cell D(1e-2) `muvrbbef` step 1552/3250 (48%). None beat new baseline.
9. **Adaptive Gradient Clipping** (nezuko PR #283) — Cell A λ=0 ctrl `1j9tl8k9` step 347/3250 (10.7%), ETA ~4.5h. NFNets-style per-param clipping. B/C/D/E queued.

**Closed this poll:** PR #210 (per-layer LR decay nezuko) — all 4 cells worse than new baseline.

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

## Next Research Directions (post lr_mlp=0.055 merge)

1. **⭐ Embed LR optimization (frieren PR #228)** — Cell D (lr_embed=0.80) = **3.2707** n=1, beats new baseline by Δ=-0.000662. STRONGEST signal in portfolio. Advisor comment posted directing n=4 confirm after Cell E (lr=1.20) completes (~30 min). If n=4 mean lands ≤ 3.269362, merge. **This is the most likely next merge.**
2. **Joint-confirm: lr_mlp=0.055 + wd_mlp=0.035/wd_attn=0.015** — once tanjiro n=4 closes (~16-18:00Z), reassign tanjiro to this joint-confirm. Expected Δ≈−0.001; n=6 statsig at ~3.269 is achievable.
3. **SOAP beta2 cold-start warmup** (edward PR #270) — NEW in flight. If β₂_init=0.50 wins, stacks with lr_mlp=0.055.
4. **SOAP attn damping** (fern PR #249) — Cell A=3.2752, B=3.2730 monotonic improvement. Cell C running. If any λ > 0 beats new baseline at n=1, promote.
5. **AdamW eps tuning** (alphonse PR #262) — Cell A control near done. If eps=1e-8/1e-7 wins, complements frieren's embed_lr signal (both attack embed/lm_head).
6. **SOAP eigvec EMA** (thorfinn PR #264) — Cell A control mid-run. Cell B crashed at step 0 (investigate).
7. **NS5 iters** (askeladd #232) — Cell summary A(8)=3.27444, B(10)=3.27390, C(12)=3.27687, D(14)=3.27480, E(16) running. B (10 iters) best n=1; no cell beats baseline.
8. **AGC** (nezuko PR #283) — NEW. Adaptive per-param clip. If helps, this stacks with all current mechanisms.
9. **Joint multi-axis confirm**: Ultimate goal = stack lr_mlp=0.055 + lr_embed=0.80 + best_wd + best_eps on n=6.
10. **Do NOT re-assign:** Cautious-Muon (PR #98), Lookahead (PR #49), SWA/Polyak (PR #50), Schedule-free Muon (PR #121/#155), Per-head SOAP (PR #220), Col-only SOAP lm_head (PR #196), z-loss (PR #186), depth-scaled init (PR #148), beta2 cooldown (PR #175 — note: edward PR #270 tests warmup which is opposite direction).

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
