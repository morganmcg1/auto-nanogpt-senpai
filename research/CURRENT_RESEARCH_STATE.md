# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~06:15 UTC (launch day +3)
- **Tag:** `auto-nanogpt-open-sota-v2-20260604`
- **Branch:** `auto-nanogpt-open-sota-v2-20260604`
- **W&B project:** `wandb-applied-ai-team/modded-nanogpt-senpai`
- **Students (8):** open2-alphonse, open2-askeladd, open2-edward, open2-fern,
  open2-frieren, open2-nezuko, open2-tanjiro, open2-thorfinn

## 🏆 RANK-1 BASELINE (unchanged)

**PR #2317 (nezuko H-W): NC × Arbor + EMA-Nesterov + RI = 3.276193 at 2890 steps**
- Stack: Cautious-Muon (NC, always-on after PR #2325) + Sinkhorn Arbor + EMA-Nesterov (γ=0.99) + RI (capture=2375, γ=−0.075)
- W&B: `vk0jtb3z`. Contract margin: 0.007615.
- Constants: `MUON_LR=0.0375`, `MUON_WEIGHT_DECAY=0.025`, `EMA_NESTEROV_GAMMA=0.99`, NS12 iter count.

## Most recent human research-team directive

Mine the public `KellerJordan/modded-nanogpt` ecosystem (merged + open + closed) plus prior Senpai PR #1532/#1614, push the Track 3 fixed-step record below 2900.

## Active assignments (06:15 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~24h, pod 7t946p, human team not responded. |
| **#2341** | open2-nezuko | H-AR: EMA-Nesterov γ warmup (0.9→0.99 over 500 steps) | Just assigned 06:10 UTC. Pod pickup pending. |
| **#2334** | open2-frieren | H-AL: AdamW β₂ warmup 0.95→0.99 over 1000 steps | run 4eqgep8q at step ~4966/5780. T0 ri=3.27649 (within noise). T1 terminal ~06:50 UTC. |
| **#2335** | open2-tanjiro | H-AM: Cosine WD schedule for Muon (0.025→0 over training) | run tiprqsjf at step ~4366/5780. T0 ri=3.27688 (+0.00068, slight regression). T1 terminal ~07:10 UTC. |
| **#2331** | open2-askeladd | H-AI: NS polynomial quartic (3,−3,1) | **⭐ STRONG SIGNAL** — Arm B T0=3.276060 (−0.000133 BELOW rank-1). T1 run ym02d30j at step ~1575/2890. T1 terminal ~07:05 UTC. |
| **#2340** | open2-fern | H-AQ: AdamW β₁ warmup (0.5→0.8 over 500 steps) | Smoke nxa5o66l passed (50 steps, β₁ schedule correct). n=2 launch pending. |
| **#2337** | open2-edward | H-AO: Per-block Muon LR (early_mult=1.2, late_mult=0.8) | Arm A relaunched as 2au0tavg, step ~725/2890, healthy trajectory. |
| **#2339** | open2-thorfinn | H-AP: Move lm_head from AdamW to Muon (separate param group) | n=2 run ss0mtlyy at step ~775/2890, healthy. |

## Recent closures (chronological, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 06:10 | #2336 (nezuko H-AN) | Multi-anchor RI (2 captures: 2200+2375) | **CLOSED FALSIFIED** | T0=3.27754 = +0.00134 above rank-1. Anchors correlated (175-step gap near training end). 14th saturated lever. |
| 2026-06-07 05:35 | #2338 (fern H-AK') | Cautious-AdamW dense-only (embed bypass) | **CLOSED FALSIFIED** | Pre-mask-grad design bug: `exp_avg_sq` corrupted → compound amplification → divergence. Direction dead. |
| 2026-06-07 05:00 | #2323 (thorfinn H-AA) | Arbor warmup (skip Sinkhorn first N steps) | **CLOSED FALSIFIED** | N=500 n=4=3.27748 vs N=0=3.27745 (Δ=+0.00003). 13th saturated lever. |
| 2026-06-07 04:12 | #2332 (edward H-AJ) | z-loss aux on pre-cap logits | **CLOSED FALSIFIED** | Monotone-bad +0.004 to +0.013. 6th saturated lever. |
| 2026-06-07 04:11 | #2333 (fern H-AK) | Cautious-AdamW all groups | **CLOSED FAILED** | Sparse-row embed pathology (mask_mean=0.227 → 4.4× LR). 1st mechanism finding. |

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
| **NS quartic (3,−3,1) Arm B** | **−0.000133 at T0** | **⭐ IN FLIGHT — PROMISING** |
| **AdamW β₂ warmup** | TBD (T0=3.27649, within noise) | H-AL in flight (frieren) |
| **Muon WD cosine schedule** | TBD (T0=3.27688, slight regression) | H-AM in flight (tanjiro) |
| **Per-block Muon LR** | TBD (relaunched after crash) | H-AO in flight (edward) |
| **lm_head on Muon** | TBD | H-AP in flight (thorfinn) |
| **AdamW β₁ warmup** | TBD (smoke passed) | H-AQ in flight (fern) |
| **EN γ warmup (0.9→0.99)** | TBD | H-AR just assigned (nezuko) |

## Saturated levers (CLOSED — no need to retest)

1. RI γ axis (H-AD)
2. RI single-anchor capture × γ sweep (H-AE)
3. SWA tail averaging (H-AB)
4. Arbor without EN (H-Z)
5. NC without Arbor
6. Drop EN from NC×Arbor stack (H-Y)
7. **EMA-Nesterov γ (H-AH): γ=0.99 optimal (constant)**
8. **Muon LR ±20% (H-AG): LR=0.0375 optimal**
9. **NS iteration count NS10 vs NS12 (H-AF): indistinguishable**
10. **z-loss aux (H-AJ): monotone-bad**
11. **Cautious-AdamW uniform recipe (H-AK): sparse-row embed pathology**
12. **Cautious-AdamW dense-only (H-AK'): pre-mask-grad design corrupts `exp_avg_sq`**
13. **Arbor warmup-from-1 in N=(0,500) (H-AA): neutral**
14. **Multi-anchor RI at steps 2200+2375 (H-AN): correlated anchors, +0.00134 regression**

## Strategic note: ⭐ BREAK IN PLATEAU — askeladd quartic NS T0 sub-rank-1

After 14 saturated levers and 2 failed directions, **askeladd H-AI quartic (3,−3,1) shows the first sub-rank-1 result at T0**: 3.276060 vs rank-1 3.276193 = −0.000133 lift. T1 run ym02d30j at step ~1575/2890 — terminal expected ~07:05 UTC.

**Mechanism:** quartic polynomial `p(x) = x(3 - 3x + x²)` provides faster convergence at high singular values while maintaining stability. KJ5 polynomial was tuned for low-NS-iter regimes and regressed at NS12; the quartic was designed from scratch for NS12 operating point.

**If T1 confirms:** immediate n=4 launch (merge candidate). Plan B: assign follow-up near-quartic sweep (e.g. (3.1,−3.0,1.0), (3.0,−3.0,0.9)) to next idle student.

## Imminent terminals (next ~60 min)

- **~06:50 UTC** — Frieren H-AL T1 (step ~4966/5780). T0=3.27649 (within noise). n=2 mean needed.
- **~07:05 UTC** — Askeladd H-AI quartic Arm B T1 (step ~1575/2890). **MERGE CANDIDATE if T1 confirms.**
- **~07:10 UTC** — Tanjiro H-AM T1 (step ~4366/5780). T0=3.27688 (+0.00068, likely close as falsified if T1 confirms regression).

## Next-wave hypotheses (for next idle students)

1. **Quartic coefficient fine-sweep** — if H-AI T1 confirms, sweep nearby: (3.1,−3.0,1.0), (3.0,−3.0,0.9), etc.
2. **EMA-Nesterov prefill/rest schedule** — PREFILL_STEPS=300 and REST_STEPS=1950 fixed; scheduling them unexplored
3. **Gradient noise injection schedule** — small Gaussian noise to Muon gradients decayed to 0 (Neelakantan et al. 2015)
4. **AdamW eps schedule** — eps=1e-10 fixed; lower eps potentially sharpens later-training preconditioner
5. **If H-AP lm_head Muon lifts: combine with H-AI quartic** — potential stacking
