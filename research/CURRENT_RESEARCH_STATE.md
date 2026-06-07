# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~10:00 UTC (launch day +3)
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

## Active assignments (~10:00 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~29h, round-2 escalation posted. Human team not responded. |
| **#2341** | open2-nezuko | H-AR: EN γ warmup (0.9→0.99 over 500 steps) | dynewpp5 T0=3.278301 (+0.002108, FALSIFIED). T1 ~79%. Let T1 finish for n=2 report. |
| **#2342** | open2-frieren | H-AS: Muon gradient noise (σ_0=0.01) | f50uw5jj T0=3.278573 (+0.002380, FALSIFIED). T1 ~34%. Let T1 finish. |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon | **PROMISING**: qwbvitns T0=3.276329 (+0.000136, PASSES n=1 gate by 0.000064). T1 ~40% (~1200/2890). Critical watch. |
| **#2340** | open2-fern | H-AQ: AdamW β₁ warmup (0.5→0.8 over 500 steps) | m33ftkmq T0=3.278451 (+0.002258, FALSIFIED). T1 ~82%. T1 terminal imminent. |
| **#2345** | open2-thorfinn | H-AV: FINAL_LR_POWER=0.9 (renormalized power_c) | spn3b1w8 T0 at step ~1200/2890. |
| **#2346** | open2-edward | H-AW: EN REST_STEPS timing sweep (1950→2300 or 1600) | **Just assigned.** Pending pod pickup. |
| **#2347** | open2-tanjiro | H-AX: EN PREFILL_STEPS timing sweep (300→100 or 600) | **Just assigned.** Pending pod pickup. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 09:55 | #2337 (edward H-AO) | Per-block Muon LR (both arms) | **CLOSED FALSIFIED** | Arm A T0=+0.0078, Arm B T0=+0.006015. Both 12-16× noise floor. 21st saturated lever. |
| 2026-06-07 09:50 | #2344 (tanjiro H-AU) | Muon LR warmup 0→0.0375 over 200 steps | **CLOSED FALSIFIED** | T0=3.281785 = +0.005592. Early abort. 20th saturated lever. |
| 2026-06-07 08:00 | #2339 (thorfinn H-AP) | lm_head on Muon (mult=0.1) | **CLOSED FALSIFIED** | T0=3.291868 = +0.0157. 19th saturated lever. |
| 2026-06-07 07:10 | #2335 (tanjiro H-AM) | Muon WD cosine 0.025→0 | **CLOSED FALSIFIED** | n=2 mean 3.276455 > gate. High seed variance. 18th saturated lever. |
| 2026-06-07 07:05 | #2331 (askeladd H-AI) | NS quartic (3,−3,1) | **CLOSED FALSIFIED** | n=2 mean 3.276558 > gate. Lucky T0 seed. 17th saturated lever. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | — |
| **Muon LR ±20%** | regresses | **SATURATED (H-AG)** |
| **EMA-Nesterov γ (constant)** | regresses | **SATURATED (H-AH)** |
| **NS10 vs NS12** | within noise | **SATURATED (H-AF)** |
| **z-loss aux** | +0.004 to +0.013 | **SATURATED (H-AJ)** |
| **Cautious-AdamW (all groups)** | diverges | **FAILED (H-AK)** |
| **Cautious-AdamW dense-only** | diverges | **FAILED (H-AK')** |
| **Arbor warmup N=(0,500)** | within noise | **SATURATED (H-AA)** |
| **Multi-anchor RI (2200+2375)** | +0.00134 | **SATURATED (H-AN)** |
| **AdamW β₂ warmup** | n=2 mean +0.000292 | **SATURATED (H-AL)** |
| **NS quartic (3,−3,1)** | n=2 mean +0.000365 | **SATURATED (H-AI)** |
| **Muon WD cosine 0.025→0** | n=2 mean +0.000262 | **SATURATED (H-AM)** |
| **lm_head on Muon (mult=0.1)** | T0=+0.0157 | **SATURATED (H-AP)** |
| **Per-block Muon LR (both arms)** | T0 = +0.006 to +0.008 | **SATURATED (H-AO)** |
| **Muon LR warmup 0→0.0375** | T0=+0.0056 | **SATURATED (H-AU)** |
| **AdamW β₁ warmup** | T0=+0.00226 (FALSIFIED) | H-AQ T1 ~82% (fern) |
| **EN γ warmup (0.9→0.99)** | T0=+0.00211 (FALSIFIED) | H-AR T1 ~79% (nezuko) |
| **Muon gradient noise** | T0=+0.00218 (FALSIFIED) | H-AS T1 ~34% (frieren) |
| **Gradient Centralization** | T0=+0.000136 (PROMISING) | H-AT T1 ~40% (askeladd) |
| **FINAL_LR_POWER sweep (0.9)** | TBD | H-AV T0 in flight (thorfinn) |
| **EN REST_STEPS timing** | TBD | H-AW just assigned (edward) |
| **EN PREFILL_STEPS timing** | TBD | H-AX just assigned (tanjiro) |

## Saturated levers count: 21 (+ 2 failed direction families)

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
18. Per-block Muon LR Arm A early-boost (H-AO partial)
19. lm_head on Muon mult=0.1 (H-AP) — catastrophic
20. Muon LR warmup 0→0.0375 (H-AU) — catastrophic
21. Per-block Muon LR Arm B late-boost (H-AO complete) — both arms catastrophic

## Strategic context (deep plateau)

We are now 21 saturated levers and 2 failed direction families into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized. 

**KEY PENDING**: askeladd H-AT Gradient Centralization T0 = **3.2763288** — PASSES n=1 gate by 0.000064. This is the most interesting single result of the current wave. T1 at ~40%. Decision in ~60 min.

**EN window timing (H-AW/H-AX)** is a fresh direction class (never tested). EN is load-bearing (−0.0028); its PREFILL/REST boundaries are inherited from pre-composition tuning. Two students now assigned to sweep these axes.

**Plateau Protocol activated.** If EN window timing fails, escalate to:
- Sophia-G on AdamW path (2nd-order diagonal Hessian)
- AdamW eps sweep (H-AY, spec ready)
- Sharpness-Aware Minimization (SAM) wrapper
- PSGD / Shampoo preconditioner variants

## Next-wave hypotheses (queued for next idle students)

1. **H-AY: AdamW eps sweep** — spec ready at `/tmp/h-ay-spec-adamw-eps.md`; arms 1e-8 and 1e-12 vs default 1e-10. Fastest to implement (1-line change), quick to falsify.
2. **Sophia-G on AdamW path** — 2nd-order diagonal Hessian estimator; targets embed/lm_head path. More complex, bigger potential swing.
3. **Spectral radius normalization** — per-parameter spectral norm targeting (different from current SOAP).
4. **SAM wrapper** — Sharpness-Aware Minimization, 2× wall-time but fair in fixed-step regime.
