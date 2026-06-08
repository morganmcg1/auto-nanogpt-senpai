# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~07:30 UTC (launch day +4) — **fern H-BO Arm B CLOSED FALSIFIED at n=4=3.277438** (T3=3.281735 catastrophic seed-3, T1=3.274075 was a seed outlier, n=2 STRONG decayed to FALSIFIED at n=4) = **42nd saturated lever**; **thorfinn H-CX CLOSED** via force-push removing implementation commit (auto-closed by GitHub at 06:29:57 UTC), n=2 mean=3.277571 confirms FALSIFIED = **43rd saturated lever**; **fern reassigned H-DI (NorMuon beta2 sweep) as PR #2371** (Morgan-created manual PR, advisor added wip+branch labels at 07:24 UTC); **thorfinn reassigned H-DJ (Lookahead-on-Muon outer-loop weight-space EMA, k=5/10, α=0.5) as PR #2372** at 07:24 UTC. Live merge watches: **alphonse 2xhxl4z0 at step 3066/5780 val/ri=3.275951** (Δ=−0.000221 BELOW rank-1) — but on stale Arbor-base reference, γ-direction screen only; **frieren cwes9skt at step 4866/5780 val/ri=3.276213** (Δ=+0.000041 AT rank-1) ETA ~07:55 UTC; **tanjiro qq89qmbd at 5566/5780 val/ri=3.277220** (Δ=+0.001048) T2 terminal minutes away. Askeladd Arm A FALSIFIED trajectory (val/ri=3.277683 at 87%).
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (updated ~23:30 UTC 2026-06-07, PR #2349 merged)

**PR #2349 (frieren H-AY): NC × Arbor + EMA-Nesterov + RI + eps=1e-12 = 3.276172 at 2890 steps**
- Stack: Cautious-Muon (NC) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075) + **AdamW eps=1e-12** (tightened from 1e-10)
- W&B: `521ky42j`/`nbptdumy`. Contract margin: 0.007656.

**Previous rank-1**: PR #2317 (nezuko H-W) = 3.276193 (margin 0.007615). Delta: −0.000021.

## Decision gates (rank-1 = 3.276172)

- STRONG ≤ 3.275772 → n=4 confirm → MERGE
- (3.275772, 3.276172] → MERGE-eligible → n=4 confirm
- (3.276172, 3.276572) → INCONCLUSIVE → close axis
- ≥ 3.276572 → FALSIFIED → close axis
- **Variance gate**: |T0 − T1| > 0.0008 → mandatory n=4 before any merge

## 🚨 OPEN MERGE WATCHES (parallel)

1. **Frieren H-BW Arm B (γ=0.95 EN-on-AdamW)** — `cwes9skt` step 4866/5780 val/ri=3.276213 (Δ=+0.000041 essentially AT rank-1). T0 alone determinative. Terminal ETA ~07:55 UTC. Trajectory consistent with INCONCLUSIVE-band edge or potential MERGE-eligible if final dips ≤ 3.276172.
2. **Tanjiro H-BN Arm B (MUON_WD=0.050) n=4 confirm** — `qq89qmbd` step 5566/5780 val/ri=3.277220 (T2 trajectory). For n=4 MERGE-eligible, T3 ≤ 3.27429 needed; for INCONCLUSIVE T3 ≤ 3.27589 needed. T1 alone was 3.275799 → seed variance high; T3 watch decides.
3. **Alphonse H-V (γ ablation n=4 on stale base)** — `2xhxl4z0` step 3066/5780 val/ri=3.275951 — informative direction screen ONLY (stale Arbor base 3.27738 vs current rank-1 3.276172). Will likely not produce absolute MERGE but the γ-direction signal is useful for follow-up. ETA ~12:11 UTC.

## Active assignments (~07:30 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | n=4 confirm `2xhxl4z0` step 3066/5780 val/ri=3.275951 (Δ=−0.000221) ETA ~12:11 UTC. Stale Arbor base 3.27738 — informative γ-direction screen only; absolute won't beat rank-1 3.276172. |
| **#2369** | open2-edward | H-CY: NorMuon-lite — per-row update-norm EMA | Arm A n=2 LAUNCHED `nt5tpgem` step 900/5780 ~07:01 UTC (smoke passed twice). RI capture at 2375; T0 evaluable ~step 5780. Reference: arxiv 2510.05491. **Optimizer-state mech.** |
| **#2360** | open2-tanjiro | H-BN: MUON_WEIGHT_DECAY sweep | **n=4 confirm `qq89qmbd` step 5566/5780 val/ri=3.277220** (T2 trajectory). T3 ETA imminent (<10 min). For MERGE-eligible n=4, T3 ≤ 3.27429 needed; for INCONCLUSIVE T3 ≤ 3.27589. Likely FALSIFIED based on T2. |
| **#2371** | open2-fern | H-DI: NorMuon beta2 sweep (Arm A=0.95, Arm B=0.85) | **NEW ASSIGNMENT (~07:11 UTC manual by Morgan, advisor added missing wip+branch labels 07:24 UTC).** Tests `normuon_defaults["beta2"]` (currently 0.9) — second-moment EMA timescale. **Optimizer-state mech.** Bit-exact at 0.9. Pod pickup pending. |
| **#2364** | open2-frieren | H-BW: EN-on-AdamW | Arm A n=2 FALSIFIED at 3.277298. **Arm B γ=0.95 `cwes9skt` step 4866/5780 val/ri=3.276213** (Δ=+0.000041 AT rank-1!). Terminal ETA ~07:55 UTC. Potential INCONCLUSIVE-band or MERGE-eligible if dips below. |
| **#2365** | open2-askeladd | H-CA: lm_head soft-warmup × higher target LR | Arm A n=2 `9hld96fr` step 5016/5780 val/ri=3.277683 (Δ=+0.001511) — FALSIFIED trajectory. Terminal ETA ~07:55 UTC. n=2 mean projection FALSIFIED unless T1 dips significantly. |
| **#2370** | open2-nezuko | H-DH: SWA-EMA on AdamW dense params | Arm A n=2 LAUNCHED `fv89ceu8` step 175/5780 ~07:27 UTC after orphan archival finished. Weight-space EMA on dense params, post-RI-capture tail. Reference: arxiv 1803.05407 (Izmailov 2018). **Optimizer-state mech.** |
| **#2372** | open2-thorfinn | **H-DJ: Lookahead-on-Muon (k=5/α=0.5 outer-loop weight-space EMA)** | **NEW ASSIGNMENT (~07:24 UTC).** Wraps Muon optimizer with Zhang 2019 Lookahead — slow weights φ ← φ + α(θ − φ) every k inner steps. Arm A k=5/α=0.5 canonical, Arm B k=10/α=0.5 slower. Bit-exact at k=0. Reference: arxiv 1907.08610. **Outer-loop optimizer-state mech** — orthogonal to H-CY (intra-update) and H-DH (AdamW SWA). Pod pickup pending. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 06:49 | **#2361 (fern H-BO)** | AdamW (β₁, β₂) sweep — β₁=0.85, β₂=0.98 | **CLOSED FALSIFIED** | n=4 mean 3.277438 (+0.001266 vs rank-1). T0=3.276597, T1=3.274075 (exceptional single seed), T2=3.277347, T3=**3.281735** catastrophic seed-3 (+0.005563). Decisive evidence n=2 STRONG was seed-1 outlier; n=4 confirm critical. **42nd saturated lever** — AdamW (β₁, β₂) shift does NOT productively beat canonical (0.8, 0.99). |
| 2026-06-08 06:29 | **#2366 (thorfinn H-CX)** | RI capture_step timing sweep (2250 vs 2500) | **CLOSED — auto-closed by force-push** | T0=T1=3.277571 (+0.001399 each, paired) confirms FALSIFIED. After T0 FALSIFIED guidance posted 06:25 UTC, student force-pushed branch to track advisor branch cleanly (removing implementation commit), GitHub auto-closed PR at 06:29:57 UTC. Run `lt5ggymy` continued regardless — training script doesn't care about git state. **43rd saturated lever** — RI capture earlier (2250) hurts trajectory by ~3.5× noise floor. RI timing axis closed for the EARLIER direction. |
| 2026-06-08 06:25 | **#2367 (nezuko H-DA)** | FINAL_LR_POWER sweep w/ recalibrated power_c | **CLOSED INFORMATIVE-NEGATIVE** | Arm S recal p=1.2 n=1=3.283095 (+0.006923, 7× threshold). Closed-form normalization `power_c = initial_lr / FINAL_SCHEDULE_STEPS^p` cannot reproduce the hand-tuned hardcoded power_c (implicit effective t_end ~2222 vs assumed 2980). **41st saturated lever — FINAL_LR_POWER axis closes for recalibration-style sweep.** Future work needs direct MUON_POWER_C sweep at fixed t_end. |
| 2026-06-08 05:55 | **#2356 (edward H-BJ)** | NS-iter × Muon LR coupling | **CLOSED FALSIFIED — both arms** | Arm A n=2=3.277806 (+0.001613, tight spread 0.000068). Arm B n=4=3.277618 (+0.001425, T0=3.280203 catastrophic seed-luck event; T1 alone=3.276022 MERGE-eligible single seed). Excellent variance escalation discipline caught false positive. **40th saturated lever — NS-iter × Muon LR coupling axis closed.** |
| 2026-06-08 03:30 | **#2358 (nezuko H-BL)** | Embed LR decoupling (0.20 vs 0.45) | **CLOSED — axis closed bidirectionally** | Arm A n=2 mean 3.276713 FALSIFIED (high variance 0.001626=2.0× thr). Arm B n=2 mean 3.276266 INCONCLUSIVE (tight 0.000324). **39th lever.** Novel finding: embed_lr=0.45 COMPRESSES seed-0/1 split, embed_lr=0.20 PRESERVES it. Direction-dependent seed-split behavior. |
| 2026-06-08 01:30 | #2362 (thorfinn H-BU) | Lookahead on AdamW groups | **CLOSED FALSIFIED** | Arm A T0=3.28440 CATASTROPHIC (+0.00823). Zero-init layers amplified by k=5 fast-weight steps. **38th lever.** |
| 2026-06-07 23:30 | #2349 (frieren H-AY) | AdamW eps=1e-12 | **🏆 MERGED** | n=4 Arm B confirm 3.276172 → new rank-1. eps tightened from 1e-10. |
| 2026-06-07 19:35 | #2351 (fern H-BC) | Spectral radius norm σ_target=1.0/0.7 | **CLOSED FALSIFIED** | Arm A n=2 mean 3.280025 (+0.004). **35th lever.** |
| 2026-06-07 19:30 | #2355 (tanjiro H-BI) | Depth-wise Muon LR decay=0.85 | **CLOSED FALSIFIED** | T0=3.29223 catastrophic. **34th lever.** |
| 2026-06-07 19:26 | #2354 (askeladd H-BH) | GC on Muon momentum buffer | **CLOSED FALSIFIED** | T0=3.284688 catastrophic. **33rd lever.** |

## Saturated levers count: 43

Recent levers (37-43):
37. **Cosine warm-restart Muon LR at step 2000 (H-BK)** — T0=3.287374 (+0.011, 22× noise floor). Invariant #5 confirmed.
38. **Lookahead k=5 α=0.5 on AdamW groups (H-BU)** — T0=3.2844 CATASTROPHIC (+0.0082). Zero-init layers amplified by k=5 fast-weight steps. Note: thorfinn's H-DJ Lookahead-on-Muon is a DIFFERENT mechanism (wraps Muon, not AdamW; no zero-init layers in Muon param groups).
39. **Embed-only LR ±50% (H-BL)** — bidirectional axis closure. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — both arms FALSIFIED.
41. **FINAL_LR_POWER recalibration (H-DA)** — informative-negative. Hand-tuned `power_c` not reproducible from closed-form.
42. **AdamW (β₁=0.85, β₂=0.98) sweep (H-BO)** — n=2 STRONG (3.275336) FALSE POSITIVE; n=4 confirm landed 3.277438 with T3 catastrophic. CRITICAL VARIANCE GATE WIN — saved from a bad merge.
43. **RI capture_step earlier=2250 (H-CX)** — n=2=3.277571 FALSIFIED. Earlier capture hurts. RI-EARLIER axis closed.

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline — cross-PR seed pattern complicates attribution |

## Cross-PR seed pattern observation

**Seed 0 / 1 split confirmed across H-AY (eps), H-BL Arm A (embed_lr=0.20), but BROKEN by H-BL Arm B (embed_lr=0.45) and by H-BO Arm B T1.**

| Arm | T0 (seed 0) | T1 (seed 1) | n=2 mean |
|---|---:|---:|---:|
| H-AY Arm A (eps=1e-8) | 3.277593 BAD | 3.275574 GOOD | 3.276584 INCONCL |
| H-AY Arm B (eps=1e-12) | 3.277014 BAD | 3.275707 GOOD | 3.276361 INCONCL |
| H-BL Arm A (embed_lr=0.20) | 3.277526 BAD | 3.275901 GOOD | 3.276713 BARELY FALSIFIED |
| H-BL Arm B (embed_lr=0.45) | **3.276104** | **3.276428** | 3.276266 (split BROKEN — compressed) |
| H-BO Arm B (β₁=0.85, β₂=0.98) | 3.276597 BAD | **3.274075 EXCEPTIONAL** | 3.275336 STRONG |

**Updated reading**: seed-split is direction-dependent, not axis-wide. Some perturbations damp the spread, others amplify it. **H-BO Arm B T1=3.274075 is the strongest single-seed trial seen on this baseline** — n=4 confirm critical to disambiguate.

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH.
3. **Post-NS5 update spectrum: no concentration** — H-BC.
4. **AdamW LR: no uniform multi-group boosts** — H-BF.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK.
6. **(EMERGING) lm_head LR must be ≥ baseline 1/320 throughout training** — H-CA bf16 cascade discovery: warmup-from-zero silences embed gradient signal → bf16 sign-flip → NaN. Floor warmup needed.

## Queued hypotheses (next assignments for idle students)

- **(H-CY assigned to edward PR #2369)** NorMuon-lite — per-row update-norm EMA, post-NS5 OPTIMIZER-STATE MECHANISM.
- **(H-DH assigned to nezuko PR #2370)** SWA-EMA on AdamW dense params — weight-space EMA, READOUT pathway mechanism.
- **(H-DI assigned to fern PR #2371 by Morgan)** NorMuon beta2 sweep — second-moment EMA timescale.
- **(H-DJ assigned to thorfinn PR #2372)** Lookahead-on-Muon — outer-loop weight-space EMA on Muon params.
- **H-CZ** (tanjiro, post-H-BN close): **EN rest_steps earlier disable.** Flag `--ema_nesterov_rest_steps` (default 1950). H-AW tested 2300 (FALSIFIED). Test earlier: Arm A=1500, Arm B=1200. SCHEDULE.
- **H-DK** (next idle): **Per-block Frobenius normalization on Muon update** — different angle from H-AO per-block LR. Computes per-param ‖U‖_F and rescales by group baseline.
- **H-DL** (next idle): **Muon momentum-buffer ramp** — schedule the `normuon_defaults["momentum"]` from 0.7 → 0.99 over training (currently constant 0.95). SCHEDULE/READOUT mech.

## Longer-term hypotheses

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` sweep (never ablated vs rank-1 stack).
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BT**: Embed × lm_head joint LR ratio sweep. SCALAR — lower priority.
- **H-BV**: SWA on AdamW groups (checkpoints post step 2000, average before RI capture). MECHANISM.
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.
- **H-DC** (NEW post H-BL): **Embed-only beta ablation** — β₁_embed, β₂_embed independently from {lm_head, scalars}. Hold pending H-BO n=4 result. If fern's (0.85, 0.98) merges uniformly, per-group betas become next axis.

## Open Operational Items (~07:30 UTC)

- **Tanjiro H-BN Arm B n=4 confirm** (`qq89qmbd` seeds 2-3): step 5566/5780 val/ri=3.277220 (T2 trajectory). T3 ETA within ~10 min. For MERGE-eligible n=4, T3 ≤ 3.27429; for INCONCLUSIVE T3 ≤ 3.27589. Likely FALSIFIED.
- **Frieren H-BW Arm B γ=0.95** (`cwes9skt`): step 4866/5780 val/ri=3.276213 (Δ+0.000041 AT rank-1). Terminal ETA ~07:55 UTC. INCONCLUSIVE-band or MERGE-eligible possible.
- **Askeladd H-CA Arm A n=2** (`9hld96fr`): step 5016/5780 val/ri=3.277683 (Δ+0.001511). Terminal ETA ~07:55 UTC. FALSIFIED trajectory.
- **Edward H-CY Arm A n=2** (`nt5tpgem`): step 900/5780 — too early for RI eval, RI captures at step 2375.
- **Nezuko H-DH Arm A n=2** (`fv89ceu8`): step 175/5780 — just launched, too early.
- **Fern H-DI** (PR #2371): pod pickup pending — labels added 07:24 UTC, should pick up next poll.
- **Thorfinn H-DJ** (PR #2372): pod pickup pending — just assigned 07:24 UTC.
- **Alphonse H-V n=4** (`2xhxl4z0`): step 3066/5780 val/ri=3.275951 (Δ−0.000221 BELOW reference). Stale Arbor base, ETA ~12:11 UTC. γ-direction screen only.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

This cycle satisfies the directive: H-CA (lm_head warmup mechanism), H-CX (RI capture timing — schedule), H-BW (EN-on-AdamW — optimizer-state), H-CY (NorMuon — optimizer-state, JUST ASSIGNED), pending H-DH (SWA-EMA — weight-space optimizer-state, queued), H-CZ (EN rest_steps — schedule). Saturated H-DA (FINAL_LR_POWER — recalibration too disruptive, informative negative).
