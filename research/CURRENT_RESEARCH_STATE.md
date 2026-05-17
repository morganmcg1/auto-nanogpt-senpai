# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-17 (poll #93, ~17:30 UTC)
- **⭐ HOTTEST SIGNAL: frieren Phase 2 n=4 confirm RUNNING** — `ym6jprxe` step 2205/13000 (17%) val=3.4201. ETA terminal ~7h. If n=4 mean ≤ 3.269362, **next merge**.
- **NEAR-TERMINAL THIS POLL:**
  - **fern Cell D `muvrbbef`** step 3247/3250 (99.9%) val=3.2752. Terminal NOW. Cell B(λ=1e-4) best at 3.2730 (1.4σ above baseline). None beat new baseline.
  - **alphonse Cell B `ptcttsgd`** step 3157/3250 (97%) val=3.2790. Terminal in <5 min. Cell C (eps=1e-8) needs to auto-launch.
- **PROGRESS:**
  - **edward Cell B auto-launched** `gf426fxo` (β₂_init=0.50, warmup=200) step 1030/3250 (32%).
  - **tanjiro PR #289** `v1mhx9f2` step 383/13000 (3%) — combo-confirm progressing.
  - **thorfinn Cell B** `37w0mwla` step 1386/3250 (43%).
  - **nezuko Cell A AGC** `1j9tl8k9` step 1749/3250 (54%).
- **AWAITING student terminal SENPAI-RESULTs**: edward Cell A=3.2727, askeladd 5-cell sweep complete.
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
| 262  | g1r5-alphonse   | AdamW eps sweep on embed/lm_head: eps ∈ {1e-10, 1e-9, 1e-8, 1e-7} | exploit | Cell A (eps=1e-10 ctrl) FINISHED val=3.2738. **Cell B (eps=1e-9) `ptcttsgd` step 2876/3250 (88%) val=3.3103.** ETA terminal ~15 min. Cell C/D queued. stale_wip false positive ack'd 16:55Z. |
| 232  | g1r5-askeladd   | NS5 iteration count sweep: iters ∈ {8,10,12,14,16} on SOAP stack | explore | **5-cell sweep COMPLETE**: A(8)=3.27444, B(10)=3.27390 best, C(12)=3.27687, D(14)=3.27480, **E(16)=3.27400 FINISHED**. None beat new baseline. Awaiting student terminal SENPAI-RESULT. |
| 228  | g1r5-frieren    | AdamW embed LR sweep: lr_embed ∈ {0.10,0.30,0.50,0.80,1.20}; **Phase 2: n=4 confirm at D config** | exploit | Cells A(0.10)=3.2803, B(0.30)=3.2750, C(0.50)=3.2740, **D(0.80)=3.2707 ⭐**, E(1.20)=3.2715 ALL FINISHED. **⭐ Phase 2 n=4 `ym6jprxe` step 1897/13000 (14.6%) val=3.4589 (mid-train healthy).** ETA terminal ~8h. If mean ≤ 3.269362, NEXT MERGE. PR has merge conflicts — rebase before merging. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | **CLOSED 16:25Z clean-neutral vs new baseline.** n=4 mean=3.271133 ffs=3131.25. Δ=-0.000229 vs new baseline (0.11× statsig gate). WAS 1.30× statsig vs OLD baseline. Reassigned to PR #289 combo-confirm. |
| 289  | g1r5-tanjiro    | Combo-confirm: lr_mlp=0.055 (merged) + wd_mlp=0.035/wd_attn=0.015 (best WD corner) at n=4 | exploit | **ASSIGNED 16:30Z.** Tests additive composition of lr_mlp + asymm WD. Expected mu ~3.2688 if additive → below n=4 merge threshold 3.269362. ETA Phase-1 terminal ~23:30Z. |
| 249  | g1r5-fern       | SOAP attn Gram damping: ridge λ·I sweep ∈ {0,1e-4,1e-3,1e-2,1e-1} on attn Gram before eigendecomp | explore | Cells A(λ=0)=3.2752, B(1e-4)=3.2730, C(1e-3)=3.2749 FINISHED. **Cell D (λ=1e-2) `muvrbbef` step 2984/3250 (92%) val=3.2984. ETA terminal ~10 min.** Cell B best n=1; non-monotonic. None beat new baseline. |
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
