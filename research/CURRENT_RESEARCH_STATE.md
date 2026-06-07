# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~07:20 UTC (launch day +3)
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

## Active assignments (07:20 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~25h, escalation comment left, human team not responded. |
| **#2341** | open2-nezuko | H-AR: EN γ warmup (0.9→0.99 over 500 steps) | run dynewpp5 at step ~100. Healthy. |
| **#2342** | open2-frieren | H-AS: Muon gradient noise (σ_0=0.01, Neelakantan 2015) | Just assigned. Pending pod pickup. |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon (Yong et al. 2020) | Just assigned. Pending pod pickup. |
| **#2344** | open2-tanjiro | H-AU: Muon LR warmup (0→0.0375 over 200 steps) | Just assigned. Pending pod pickup. |
| **#2340** | open2-fern | H-AQ: AdamW β₁ warmup (0.5→0.8 over 500 steps) | n=2 run m33ftkmq at step ~875/2890. Healthy. |
| **#2337** | open2-edward | H-AO: Per-block Muon LR (early_mult=1.2, late_mult=0.8) | Arm A relaunch 2au0tavg at step ~1325/2890. Healthy. |
| **#2339** | open2-thorfinn | H-AP: lm_head on Muon (separate param group) | 2 concurrent runs detected: ss0mtlyy (step ~1375) + h820m08l (step ~150). Advised to kill duplicate. |

## Recent closures (this session, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 07:10 | #2335 (tanjiro H-AM) | Muon WD cosine 0.025→0 | **CLOSED FALSIFIED** | n=2 mean 3.276455 > gate. T0/T1 spread 8× noise floor — high seed variance. 18th saturated lever. |
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
| **Per-block Muon LR** | TBD | H-AO in flight (edward) |
| **lm_head on Muon** | TBD | H-AP in flight (thorfinn) |
| **AdamW β₁ warmup** | TBD | H-AQ in flight (fern) |
| **EN γ warmup (0.9→0.99)** | TBD | H-AR in flight (nezuko) |
| **Muon gradient noise** | TBD | H-AS just assigned (frieren) |
| **Gradient Centralization** | TBD | H-AT just assigned (askeladd) |
| **Muon LR warmup 0→0.0375** | TBD | H-AU just assigned (tanjiro) |

## Saturated levers count: 18 (+ 2 failed direction families)

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
18. [Reserved]

## Strategic context (deep plateau)

We are now 18+ saturated levers and 2 failed direction families into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized. Current in-flight experiments cover:

**Gradient-level processing (new direction class):**
- H-AS gradient noise (frieren)
- H-AT gradient centralization (askeladd)

**Schedule axis:**
- H-AQ AdamW β₁ warmup (fern)
- H-AR EN γ warmup (nezuko) — EN is load-bearing component
- H-AU Muon LR warmup (tanjiro) — unexplored schedule axis

**Architecture migration:**
- H-AO per-block Muon LR (edward)
- H-AP lm_head on Muon (thorfinn)

**Plateau Protocol activated.** With 18 saturated levers, the next advisor cycle should use researcher-agent to identify mechanisms from physics, optimization, and ML that haven't been touched yet.

## Next-wave hypotheses (for next idle students)

1. **Power schedule exponent sweep** — FINAL_LR_POWER is fixed; sweeping may compound with existing stack
2. **Muon NS warm restart** — periodically reset NS iteration count to prevent stale Gram matrices
3. **EMA-Nesterov prefill/rest schedule** — PREFILL_STEPS=300 and REST_STEPS=1950 unexplored
4. **Spectral radius normalization** — per-parameter spectral norm targeting, different from current SOAP
5. **Sharpness-Aware Minimization (SAM) wrapper** — 2× wall-time but fair in fixed-step regime
