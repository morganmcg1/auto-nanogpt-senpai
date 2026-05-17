# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-17 (poll #85, ~14:20 UTC)
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
| 264  | g1r5-thorfinn   | SOAP eigvec EMA: smooth attn eigenbasis across refreshes (α sweep 0,0.3,0.5,0.7,0.9) | explore | WIP — no runs visible in W&B yet (possibly different group name). Cells not started per W&B. |
| 270  | g1r5-edward     | SOAP beta2 cold-start warmup: ramp β₂ from low→0.90 over first K steps to fix early eigenvec noise | explore | **NEW ASSIGNED ~14:10Z** — 5 cells: ctrl + {0.50/200, 0.50/500, 0.70/200, 0.30/200}. ETA Phase-1 ~23:00Z. |
| 262  | g1r5-alphonse   | AdamW eps sweep on embed/lm_head: eps ∈ {1e-10, 1e-9, 1e-8, 1e-7} | exploit | **NEW ASSIGNED** — follows PR #196 (col-only SOAP closed). Tests if rare-token v-buffer underflow drives instability. Cell A control starting. ETA Phase-1 ~17:00Z. |
| 232  | g1r5-askeladd   | NS5 iteration count sweep: iters ∈ {8,10,12,14,16} on SOAP stack | explore | Cells A(8)=3.27444, B(10)=3.2739, C(12)=3.27687 FINISHED. **Cell D(14) running ~step 1032.** Cell E(16) queued. All vs old baseline — none beat new baseline 3.271362. |
| 228  | g1r5-frieren    | AdamW embed LR sweep: lr_embed ∈ {0.10,0.30,0.50,0.80,1.20} | exploit | Cells A/B/C FINISHED: 3.2803/3.2750/3.2740. **Cell D (lr=0.80) `uaczok17` running ~60%.** Cell E queued. Best so far Cell C (lr_embed=0.50). All above new baseline 3.271362. |
| 194  | g1r5-tanjiro    | Asymmetric per-group WD: wd_mlp vs wd_attn sweep ({0.015,0.035}² corners) | exploit | n=4 `asym-wd-C-confirm-0035-0015-n4` RUNNING at step ~7687 (trial 1-2 of 4 in progress). Trial 0 FINISHED val=3.27040. Cell D `asym-wd-D-0035-0035-n2` heartbeat 4.4h stale (likely dead — just comparison arm). ETA n=4 complete ~16:00Z. |
| 249  | g1r5-fern       | SOAP attn Gram damping: ridge λ·I sweep ∈ {0,1e-4,1e-3,1e-2,1e-1} on attn Gram before eigendecomp | explore | Cell A (λ=0) FINISHED val=3.275183 (vs new baseline Δ+0.0038). Cell B (λ=1e-4) FINISHED val=3.272995 (Δ+0.0016, sub-statsig). Cell C (λ=1e-3) CRASHING+relaunching. Cells D/E queued. Advisory comment left. |
| 210  | g1r5-nezuko     | Per-layer LR decay schedule (γ^k across 12 transformer blocks, γ∈{0.93,0.97,1.03,1.07}) | explore | Cells A(0.93)=3.27922, B(0.97)=3.27348, C(1.03)=3.27433 FINISHED. **Cell D (γ=1.07) started at step ~12.** All cells worse than new baseline 3.271362. |
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
2. **SOAP beta2 cold-start warmup** (edward PR #270) — NEW, sweep β₂_init ∈ {ctrl, 0.50/200, 0.50/500, 0.70/200, 0.30/200}. Started ~14:10Z. ETA Phase-1 ~23:00Z.
3. **AdamW eps sweep** (alphonse PR #262) — Cell A (eps=1e-10 ctrl) running at ~step 275. 3 more cells queued.
4. **SOAP eigvec EMA** (thorfinn PR #264) — No W&B runs visible yet; assigned ~12:00Z, may be starting Cell A.
5. **NS5 iteration count sweep** (askeladd PR #232) — A=3.27444, B=3.2739, C=3.27687 done. Cell D(14) running ~step 1032.
6. **AdamW embed LR sweep** (frieren PR #228) — No W&B runs visible in default group. Possibly using different run names. Cell D was running per prior poll.
7. **Asymmetric WD** (tanjiro PR #194) — n=4 confirm running at ~step 7687 (trial 1-2 in flight). ETA ~16:00Z.
8. **SOAP attn Gram damping** (fern PR #249) — Cell A=3.275183, Cell B(λ=1e-4)=3.272995. Cell C crashing. Cells D/E queued.
9. **Per-layer LR decay** (nezuko PR #210) — A=3.27922, B=3.27348, C=3.27433 done. Cell D(1.07) just started.

**Closed this poll:** PR #269 (Cautious-Muon) — duplicate of PR #98 (clean negative "mask harms NS"), closed immediately.

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

1. **Joint-confirm: lr_mlp=0.055 + wd_mlp=0.035/wd_attn=0.015** — once tanjiro n=4 closes (~16:00Z), reassign tanjiro to this joint-confirm. Expected Δ≈−0.001; n=6 statsig at ~3.269 is achievable.
2. **SOAP beta2 cold-start warmup** (edward PR #270) — NEW in flight. If β₂_init=0.50 wins, this stacks with lr_mlp=0.055 immediately.
3. **SOAP attn damping** (fern PR #249) — Cell C crashing; if any λ > 0 beats new baseline, promote n=4 immediately.
4. **AdamW eps tuning** (alphonse PR #262) — Cell A running. If eps=1e-8/1e-7 wins, stack immediately.
5. **SOAP eigvec EMA** (thorfinn PR #264) — no runs visible yet. First cell should appear soon.
6. **Embed LR optimization** (frieren PR #228) — best cell so far C(lr_embed=0.50)=3.2740; all cells worse than new baseline. Follow-up: stack winner with lr_mlp=0.055 in a joint confirm.
7. **NS5 iters** (askeladd #232) — B(10) is best n=1 at 3.2739; if any cell beats new baseline, stack. Otherwise data suggests 10 iters is optimal direction.
8. **KL-SOAP-H / PMuon** (records #19/#18) — wave-4 candidates if current mechanism slots exhaust.
9. **Joint multi-axis confirm**: Ultimate goal = stack lr_mlp=0.055 + best_wd + best_eps + best_eigvec on n=6. Design this confirm run once individual components have non-null signals.
10. **Do NOT re-assign:** Cautious-Muon (PR #98 closed), Lookahead (PR #49), SWA/Polyak (PR #50), Schedule-free Muon (PR #121/#155).

## Standing Constraints

- **Banned sources**: `primeintellect.ai/auto-nanogpt`, `PrimeIntellect-ai/experiments-autonomous-speedrunning`.
- **Benchmark contract**: dataset, batch size, architecture, one fwd-bwd per step all fixed.
- **Reporting rule**: every terminal result needs SENPAI-RESULT marker + predeclared n, mu, statsig.
- **GPU budget**: 1× H100 (~80 GB) per student, ~1.93 s/step.
