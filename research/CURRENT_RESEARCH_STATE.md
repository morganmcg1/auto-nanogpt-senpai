# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~12:30 UTC (launch day +3)
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

## Active assignments (~12:30 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~31h, round-2 escalation posted. Human team not responded. |
| **#2341** | open2-nezuko | H-AR: EN γ warmup | Arm A FALSIFIED (n=2 mean 3.279476). Arm B (γ_start=0.95) `3vhyodcg` step 3866/5780 (~67%), T0=3.277508 **FALSIFIED**, T1 pending ~13:30 UTC. |
| **#2349** | open2-frieren | H-AY: AdamW eps sweep (1e-8 vs 1e-12) | **OPERATIONAL ISSUE**: zombie run `hh8ank8b` on closed h-as-grad-noise group, kill+launch order posted 12:22 UTC. Smoke `mj9ydkpo` already passed. |
| **#2343** | open2-askeladd | H-AT: Gradient Centralization on Muon | n=4 confirm running: `crhbqarp` step 1525/2890 (~53% of seed 2). Final n=4 result at ~14:00 UTC. Decision bands: ≤3.275793→STRONG merge; ≤3.276193→Promising merge; (3.276193,3.276593)→confirmed inconclusive; ≥3.276593→FALSIFIED. |
| **#2340** | open2-fern | H-AQ: AdamW β₁ warmup | Arm A FALSIFIED (n=2 mean 3.278438). Arm B (β₁=0.65) `q1rg6lwx` step 4066/5780 (~70%), T0=3.280502 **FALSIFIED**, T1 pending ~13:40 UTC. |
| **#2348** | open2-thorfinn | H-AZ: Lookahead wrapper on Muon | Smoke `oefw76xt`+`lzemh97u` passed. Full run `tjv3mars` (k=6, α=0.5) step ~400/2890 healthy. T0 ETA ~14:30 UTC. |
| **#2346** | open2-edward | H-AW: EN REST_STEPS timing sweep | Run `43ng08cg` (REST=2300, Arm A) step 3791/5780 (~65%), **T0=3.276414 PROMISING** (+0.000221, within noise). T1 pending ~13:30 UTC. |
| **#2347** | open2-tanjiro | H-AX: EN PREFILL_STEPS timing sweep | Run `306xu575` (PREFILL=100, Arm A) step 3116/5780 (~54%), T0=3.277027 **FALSIFIED**. T1 pending ~13:55 UTC. |

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
| **Muon gradient noise (σ_0=0.01)** | n=2 mean +0.001498 | **SATURATED (H-AS)** |
| **Gradient Centralization** | T0=+0.000136 (PROMISING) | H-AT T1 ~40% (askeladd) |
| **FINAL_LR_POWER sweep (0.9, renorm)** | T0=+0.004326 (8× noise floor) | **SATURATED (H-AV)** |
| **EN REST_STEPS timing** | TBD | H-AW just assigned (edward) |
| **EN PREFILL_STEPS timing** | TBD | H-AX just assigned (tanjiro) |

## Saturated levers count: 23 (+ 2 failed direction families)

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
22. FINAL_LR_POWER=0.9 with renormalized power_c (H-AV) — 8× noise floor, decay-tail shape axis saturated
23. Muon gradient noise σ_0=0.01 Neelakantan decayed (H-AS) — n=2 mean +0.001498, noise poisons NS orthogonalization

## Strategic context (deep plateau)

We are now 21 saturated levers and 2 failed direction families into a deep plateau. The rank-1 3.276193 stack (NC × Arbor × EN × RI) is highly optimized. 

**KEY PENDING**:
1. **askeladd H-AT GC n=4 confirm** running (`crhbqarp` step 1525/2890 ~53% of seed 2). Final at ~14:00 UTC. Only positive signal in last 11+ arms tested. n=2 mean had been 3.276584 (T0=3.276329, T1=3.276839, spread ≈ noise floor).
2. **edward H-AW REST=2300 PROMISING**: T0=3.276414 (+0.000221 vs rank-1, within noise band). T1 ETA ~13:30 UTC. If n=2 mean ≤ 3.276193 → n=4 confirm directed; (3.276193, 3.276593) inconclusive → try Arm B (REST=1600).
3. **Frieren operational issue**: zombie run on closed PR #2342 (h-as-grad-noise) — kill+launch order posted on PR #2349 12:22 UTC.

**EN window timing (H-AW/H-AX)** is a fresh direction class (never tested). EN is load-bearing (−0.0028); its PREFILL/REST boundaries are inherited from pre-composition tuning. H-AW Arm A (REST=2300) is **the only positive T0** among 3 timing arms.

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
