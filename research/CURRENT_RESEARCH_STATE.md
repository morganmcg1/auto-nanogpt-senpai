# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~09:30 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged since H-W merge)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC, always-on after PR #2325) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.
- Constants: `MUON_LR=0.0375`, `MUON_WEIGHT_DECAY=0.025`, `EMA_NESTEROV_GAMMA=0.99`, NS12 iter count.

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, push the Track 3 fixed-step record below 2900.

## Active assignments (08:00 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~27h, round-2 escalation posted. Human team not responded. |
| **#2341** | open2-nezuko | H-AR: EN γ warmup (0.9→0.99 over 500 steps) | dynewpp5 T0=3.278301 (+0.00211, falsified). T1 step 1751/2890 (~61%). Let T1 finish for n=2. |
| **#2342** | open2-frieren | H-AS: Muon gradient noise (σ_0=0.01, Neelakantan 2015) | f50uw5jj T0=3.278573 (+0.00218, falsified). T1 step 651/2890 (~22%). Let T1 finish. |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon (Yong et al. 2020) | **PROMISING**: qwbvitns T0=3.276329 (+0.000136, PASSES n=1 gate by 0.000064). T1 step 876/2890 (~30%). Critical watch. |
| **#2344** | open2-tanjiro | H-AU: Muon LR warmup (0→0.0375 over 200 steps) | cuprgtht T0=3.281785 (+0.00559, 11× noise, FALSIFIED). Early-abort recommendation posted PR #2344. |
| **#2340** | open2-fern | H-AQ: AdamW β₁ warmup (0.5→0.8 over 500 steps) | m33ftkmq T0=3.278451 (+0.00226, falsified). T1 step 1851/2890 (~64%). Let T1 finish. |
| **#2337** | open2-edward | H-AO: Per-block Muon LR, Arm B (early_mult=0.8, late_mult=1.2) | n8avho0l step 2750/2890. T0 imminent (~140 steps). val 3.2939 pre-RI. |
| **#2345** | open2-thorfinn | H-AV: FINAL_LR_POWER sweep (renormalized) | Smoke both passed (1ala1e27 + cvw4wele). n=2 launched spn3b1w8 power=0.9 with renormalized power_c. T0 step 600/2890. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 08:00 | #2339 (thorfinn H-AP) | lm_head on Muon (mult=0.1) | **CLOSED FALSIFIED** | T0=3.291868 = +0.0157 above rank-1 (~31× noise floor). Early abort. 19th saturated lever. |
| 2026-06-07 07:10 | #2335 (tanjiro H-AM) | Muon WD cosine 0.025→0 | **CLOSED FALSIFIED** | n=2 mean 3.276455 > gate. T0/T1 spread 8× noise floor. 18th saturated lever. |
| 2026-06-07 07:05 | #2331 (askeladd H-AI) | NS quartic (3,−3,1) | **CLOSED FALSIFIED** | T0=3.276060 (lucky seed), T1=3.277055. n=2 mean 3.276558 > gate. NS polynomial axis saturated. 17th saturated lever. |
| 2026-06-07 06:45 | #2334 (frieren H-AL) | AdamW β₂ warmup 0.95→0.99 | **CLOSED FALSIFIED** | n=2 mean 3.276485 > gate. T0/T1 spread +0.002. 15th saturated lever. |
| 2026-06-07 06:10 | #2336 (nezuko H-AN) | Multi-anchor RI (steps 2200+2375) | **CLOSED FALSIFIED** | T0=3.27754 = +0.00134 above rank-1. Correlated anchors. 14th saturated lever. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| **Muon LR ±20%** | regresses | **SATURATED** |
| **EMA-Nesterov γ (constant)** | regresses | **SATURATED** |
| **NS10 vs NS12** | within noise | **SATURATED** |
| **z-loss aux** | +0.004 to +0.013 | **SATURATED** |
| **Cautious-AdamW (all groups)** | diverges | **FAILED** |
| **Cautious-AdamW dense-only** | diverges | **FAILED** |
| **Arbor warmup N=(0,500)** | within noise | **SATURATED** |
| **Multi-anchor RI (2200+2375)** | +0.00134 | **SATURATED** |
| **AdamW β₂ warmup** | n=2 mean +0.000292 | **SATURATED** |
| **NS quartic (3,−3,1)** | n=2 mean +0.000365 (T0 lucky) | **SATURATED** |
| **Muon WD cosine 0.025→0** | n=2 mean +0.000262 (high variance) | **SATURATED** |
| **lm_head on Muon (mult=0.1)** | T0=+0.0157 (catastrophic) | **SATURATED** |
| **Per-block Muon LR (Arm A early-boost)** | T0=+0.0078 (catastrophic) | Arm B late-boost TBD |
| **AdamW β₁ warmup** | TBD | H-AQ in flight (fern, T0 imminent) |
| **EN γ warmup (0.9→0.99)** | TBD | H-AR in flight (nezuko, T0 imminent) |
| **Muon gradient noise** | TBD | H-AS in flight (frieren) |
| **Gradient Centralization** | TBD | H-AT in flight (askeladd) |
| **Muon LR warmup 0→0.0375** | TBD | H-AU in flight (tanjiro) |
| **FINAL_LR_POWER sweep (0.9/1.5)** | TBD | H-AV just assigned (thorfinn) |

## Saturated levers count: 19 (+ 2 failed direction families)

1. RI γ axis (H-AD)
2. RI single-anchor capture × γ sweep (H-AE)
3. SWA tail averaging (H-AB)
4. Arbor without EN (H-Z)
5. NC without Arbor
6. Drop EN from NC×Arbor stack (H-Y)
7. EMA-Nesterov γ constant sweep (H-AH)
8. Muon LR ±20% (H-AG)
9. NS iteration count NS10 vs NS12 (H-AF)
10. z-loss aux (H-AJ)
11. Cautious-AdamW uniform recipe (H-AK)
12. Cautious-AdamW dense-only (H-AK')
13. Arbor warmup-from-1 N=(0,500) (H-AA)
14. Multi-anchor RI steps 2200+2375 (H-AN)
15. AdamW β₂ warmup 0.95→0.99 (H-AL)
16. NS quartic (3,−3,1) (H-AI) — T0 lucky seed
17. Muon WD cosine 0.025→0 (H-AM) — high variance
18. Per-block Muon LR early-boost Arm A T0=+0.0078 (H-AO partial)
19. lm_head on Muon mult=0.1, T0=+0.0157 (H-AP) — catastrophic

## Strategic context (deep plateau)

We are now 19+ saturated levers and 2 failed direction families into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized. Current in-flight experiments cover:

**Gradient-level processing (new direction class):**
- H-AS gradient noise (frieren, f50uw5jj step ~1525)
- H-AT gradient centralization (askeladd, qwbvitns step ~1734)

**Schedule axis:**
- H-AQ AdamW β₁ warmup (fern, m33ftkmq step ~2525, T0 imminent)
- H-AR EN γ warmup (nezuko, dynewpp5 step ~2400, T0 imminent)
- H-AU Muon LR warmup (tanjiro, cuprgtht step ~950)
- H-AV FINAL_LR_POWER sweep (thorfinn, just assigned PR #2345)

**Architecture migration:**
- H-AO Arm B late-boost per-block LR (edward, n8avho0l running)

**Two T0 results expected within 15 minutes**: fern H-AQ and nezuko H-AR.

**H-AO per-block LR note:** Arm A (early-boost 1.2/0.8) badly falsified at T0=3.2840. Arm B (late-boost 0.8/1.2) now running. If Arm B also falsifies, per-block Muon LR axis is CLOSED entirely.

**Plateau Protocol activated.** With 19 saturated levers, the team should look at:
- Second-order information (Sophia-G, AdaHessian) on AdamW path
- Alternative preconditioners (PSGD, Shampoo variants)
- EMA-Nesterov window timing (PREFILL_STEPS/REST_STEPS unexplored)
- Spectral normalization targeting

## Next-wave hypotheses (for next idle students)

1. **EMA-Nesterov rest_steps timing** — REST_STEPS=1950 is fixed; extending (2300) or shortening (1600) the active EN window may interact productively with RI capture at 2375
2. **Sophia-G on AdamW path** — 2nd-order diagonal Hessian estimator via GNB, potentially 2× convergence speed in LM pretraining
3. **FINAL_LR_POWER sweep** — ASSIGNED to thorfinn (H-AV, power 0.9/1.5 vs default 1.2)
4. **Spectral radius normalization** — per-parameter spectral norm targeting, different from current SOAP
5. **Sharpness-Aware Minimization (SAM) wrapper** — 2× wall-time but fair in fixed-step regime
