# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~08:25 UTC (launch day +4) — **frieren H-BW CLOSED FALSIFIED at n=2 both arms** (Arm A γ=0.99 mean=3.277298, Arm B γ=0.95 mean=3.276654; EN-on-AdamW mechanism refuted = **45th lever**); **askeladd H-CA CLOSED FALSIFIED at n=2=3.276957** (T0=3.277683 + T1=3.276232; lm_head zero-warmup counterproductive = **46th lever**); **frieren reassigned H-DL** (EN lookahead_stepsize 0.15 vs 0.45, default 0.3) as **PR #2375**; **askeladd reassigned H-DK** (Arbor clamp_k 2.0 vs 5.0, default 3.0) as **PR #2374**. All 8 students assigned.
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

1. **Alphonse H-V (γ ablation n=4 on stale base)** — `2xhxl4z0` informative direction screen ONLY (stale Arbor base 3.27738 vs current rank-1 3.276172). ETA ~12:11 UTC. γ-direction signal informative for follow-up even if absolute won't beat rank-1.

## Active assignments (~08:25 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | n=4 confirm `2xhxl4z0` — informative γ-direction screen on stale Arbor base 3.27738. ETA ~12:11 UTC. |
| **#2369** | open2-edward | H-CY: NorMuon-lite — per-row update-norm EMA | Arm A n=2 LAUNCHED `nt5tpgem` confirmed pickup at ~07:34 UTC (smoke passed). CLI flag `--nor_beta2`. T0 evaluable ~10:12 UTC. **Optimizer-state mech.** |
| **#2373** | open2-tanjiro | H-CZ: EN rest_steps direction ablation | NEW PR #2373 (~08:00 UTC). Tests `--ema_nesterov_rest_steps` at 2400 (Arm A) vs 2890 never-disengage (Arm B). Awaiting pod pickup. |
| **#2371** | open2-fern | H-DI: SOAP_BETA2 sweep | Redirected to sweep `SOAP_BETA2` in train_gpt_simple.py (original PR had wrong file). Pod re-launching. |
| **#2375** | open2-frieren | **H-DL: EN lookahead_stepsize sweep (0.15 vs 0.45)** | **NEW PR #2375 (~08:25 UTC).** Ablates `EMA_NESTEROV_LOOKAHEAD` — never tested on rank-1 stack. Arm A=0.15 (−50%), Arm B=0.45 (+50%). Student adds `--ema_nesterov_lookahead` CLI flag. Awaiting pod pickup. |
| **#2374** | open2-askeladd | **H-DK: Arbor clamp_k sweep (2.0 vs 5.0)** | **NEW PR #2374 (~08:25 UTC).** Ablates `ARBOR_CLAMP_K` — never tested on rank-1 stack. Arm A=2.0 (tighter), Arm B=5.0 (looser). Student adds `--arbor_clamp_k` CLI flag. Awaiting pod pickup. |
| **#2370** | open2-nezuko | H-DH: SWA-EMA on AdamW dense params | Arm A n=2 running (launched ~07:27 UTC). Weight-space EMA on dense params, post-RI-capture tail. T0 ETA ~10:17 UTC. **Optimizer-state mech.** |
| **#2372** | open2-thorfinn | **H-DJ: Lookahead-on-Muon (k=5/α=0.5)** | Picked up pod at 07:40 UTC. Student self-adapted to train_gpt_simple.py (advisor green-lit 07:48 UTC). Smoke + Arm A n=2 launch expected ~08:15-08:30 UTC. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 08:20 | **#2364 (frieren H-BW)** | EN-on-AdamW EMA β sweep (γ=0.99 vs 0.95) | **CLOSED FALSIFIED** | Arm A n=2 mean=3.277298 (+0.001126), Arm B n=2 mean=3.276654 (+0.000482). EN adds no lift on AdamW path — AdamW's β₁=0.9 already provides equivalent smoothing. **45th saturated lever.** EN mechanism confirmed Muon-specific. |
| 2026-06-08 08:20 | **#2365 (askeladd H-CA)** | lm_head soft-warmup + higher target LR K=25 | **CLOSED FALSIFIED** | T0=3.277683, T1=3.276232, n=2 mean=3.276957 (+0.000785). High seed variance, no net improvement. **46th saturated lever.** Key finding: lm_head zero-warmup triggers bf16 sign-flip cascade → LR floor constraint added to invariants. |
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

## Saturated levers count: 46

Recent levers (38-46):
38. **Lookahead k=5 α=0.5 on AdamW groups (H-BU)** — T0=3.2844 CATASTROPHIC (+0.0082). Zero-init layers amplified by k=5 fast-weight steps. Note: H-DJ Lookahead-on-Muon is DIFFERENT (Muon params, no zero-init layers).
39. **Embed-only LR ±50% (H-BL)** — bidirectional axis closure. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — both arms FALSIFIED.
41. **FINAL_LR_POWER recalibration (H-DA)** — informative-negative. Hand-tuned `power_c` not reproducible from closed-form.
42. **AdamW (β₁=0.85, β₂=0.98) sweep (H-BO)** — n=2 STRONG FALSE POSITIVE (3.275336); n=4 mean=3.277438. T3 catastrophic. VARIANCE GATE WIN.
43. **RI capture_step earlier=2250 (H-CX)** — n=2=3.277571 FALSIFIED. RI-EARLIER axis closed.
44. **Muon WD sweep 0.010 vs 0.050 (H-BN)** — Arm B n=4 mean=3.27674729 FALSIFIED. WD locked at 0.025. Seed-1 outlier 3.275799 confirmed FALSE POSITIVE at n=4. VARIANCE GATE WIN.
45. **EN-on-AdamW (H-BW)** — both arms FALSIFIED (γ=0.99 mean=3.277298, γ=0.95 mean=3.276654). EN mechanism is Muon-specific; AdamW's β₁=0.9 already provides equivalent smoothing.
46. **lm_head soft-warmup + higher target LR K=25 (H-CA)** — n=2 mean=3.276957 FALSIFIED. Zero-warmup → bf16 sign-flip cascade → LR floor constraint added to invariants.

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

All 8 students assigned. Queued for next idle slots:

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` extended range (0.1 vs 0.6) if H-DL 0.15/0.45 narrows down direction.
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.

## Longer-term hypotheses

- **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
- **H-BQ**: EN `lookahead_stepsize` sweep (never ablated vs rank-1 stack).
- **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
- **H-BT**: Embed × lm_head joint LR ratio sweep. SCALAR — lower priority.
- **H-BV**: SWA on AdamW groups (checkpoints post step 2000, average before RI capture). MECHANISM.
- **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95). SCALAR — lower priority.
- **H-DC** (NEW post H-BL): **Embed-only beta ablation** — β₁_embed, β₂_embed independently from {lm_head, scalars}. Hold pending H-BO n=4 result. If fern's (0.85, 0.98) merges uniformly, per-group betas become next axis.

## Open Operational Items (~08:25 UTC)

- **Frieren H-DL** (PR #2375): NEW — awaiting pod pickup. EN lookahead_stepsize 0.15 vs 0.45.
- **Askeladd H-DK** (PR #2374): NEW — awaiting pod pickup. Arbor clamp_k 2.0 vs 5.0.
- **Tanjiro H-CZ** (PR #2373): awaiting pod pickup. EN rest_steps Arm A=2400, Arm B=2890.
- **Thorfinn H-DJ** (PR #2372): pod picked up 07:40 UTC, self-adapted, smoke + Arm A n=2 expected ~08:15-08:30 UTC.
- **Fern H-DI** (PR #2371): redirected to correct SOAP_BETA2 sweep. Re-pick up expected soon.
- **Edward H-CY Arm A n=2** (`nt5tpgem`): T0 evaluable ~10:12 UTC.
- **Nezuko H-DH Arm A n=2**: launched ~07:27 UTC, T0 evaluable ~10:17 UTC.
- **Alphonse H-V n=4** (`2xhxl4z0`): stale Arbor base, γ-direction screen. ETA ~12:11 UTC.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

This cycle satisfies the directive: H-CA (lm_head warmup mechanism), H-CX (RI capture timing — schedule), H-BW (EN-on-AdamW — optimizer-state), H-CY (NorMuon — optimizer-state, JUST ASSIGNED), pending H-DH (SWA-EMA — weight-space optimizer-state, queued), H-CZ (EN rest_steps — schedule). Saturated H-DA (FINAL_LR_POWER — recalibration too disruptive, informative negative).
