# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~04:25 UTC (launch day +3)
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

## Active assignments (04:25 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~21h, pod 7t946p, human team not responded. |
| **#2336** | open2-nezuko | H-AN: Multi-anchor RI (2 simultaneous captures) | Assigned 03:05 UTC. Pod pickup pending. |
| **#2334** | open2-frieren | H-AL: AdamW β₂ warmup 0.95→0.99 over 1000 steps | GPU 99% active, no comment yet (~2h since assignment). |
| **#2335** | open2-tanjiro | H-AM: Cosine WD schedule for Muon (0.025→0 over training) | Arm A n=2 running. T0 ETA ~05:00 UTC. |
| **#2331** | open2-askeladd | H-AI: NS polynomial (a,b,c) coefficient retune for NS12 | Arm A KJ5 falsified (+0.00195). Arm B quartic (3,−3,1) running. T0 ETA ~05:30 UTC. |
| **#2338** | open2-fern | H-AK': Cautious-AdamW on lm_head + scalars only (embed vanilla) | **JUST ASSIGNED 04:25 UTC**. Dense-only follow-up from H-AK mechanism finding. |
| **#2337** | open2-edward | H-AO: Per-block Muon LR (early_mult=1.2, late_mult=0.8) | **JUST ASSIGNED 04:25 UTC**. Split Muon into early (0-5) and late (6-11) block groups. |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup (skip Sinkhorn first N steps) | N=500 T2 terminal ~04:15 UTC. T3 ETA ~07:30 UTC. |

## Recent closures (chronological, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 04:12 | #2332 (edward H-AJ) | z-loss aux on pre-cap logits | **CLOSED FALSIFIED** | Arm A w=1e-4: +0.00410, Arm B w=1e-3: +0.01305. Monotone-bad slope. Softsign cap already sufficient at this scale. 6th saturated lever. |
| 2026-06-07 04:11 | #2333 (fern H-AK) | Cautious-AdamW all groups | **CLOSED FAILED** | Diverged to val=9.69 at step 1125. Sparse-row embed pathology: mask_mean=0.227 → 4.4× LR amplification. Publishable mechanism finding. |
| 2026-06-07 03:05 | #2328 (nezuko H-AF) | NS10 vs NS12 on NC×Arbor+RI | **CLOSED INCONCLUSIVE** | NS10 n=4=3.276248 (+55μ, inside SEM). 5th saturated axis. |
| 2026-06-07 02:45 | #2329 (tanjiro H-AG) | Muon LR ±20% on NC×Arbor+RI | **CLOSED FALSIFIED** | LR=0.0375 locally optimal. 4th saturated scalar. |
| 2026-06-07 02:20 | #2330 (frieren H-AH) | EMA-Nesterov γ ablation | **CLOSED FALSIFIED** | γ=0.99 sharply optimal. 3rd saturated scalar. |
| 2026-06-07 01:45 | #2327 (fern H-AE) | RI capture_step × γ sweep (15-cell) | **CLOSED FALSIFIED** | All 15 cells within ±0.000835. 2nd saturated axis. |
| 2026-06-06 23:50 | #2326 (edward H-AD) | RI γ sweep on NC×Arbor | **CLOSED** | γ axis saturated. 1st saturated axis. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED (H-AD, H-AE) |
| + NC (Cautious-Muon) | −0.00069 | Dense-AdamW cautious tested (→ H-AK' in progress) |
| **Muon LR ±20%** | regresses | **SATURATED — LR=0.0375 optimal** |
| **EMA-Nesterov γ** | regresses | **SATURATED — γ=0.99 sharply optimal** |
| **NS10 vs NS12** | within noise | **SATURATED — NS10=NS12 within noise** |
| **z-loss aux (w=1e-4 to 1e-3)** | +0.004 to +0.013 | **SATURATED — softsign cap already sufficient** |
| **Cautious-AdamW (all groups)** | diverges to +6 | **FAILED — embed sparse-row pathology** |
| **NS (a,b,c) coefficients** | Arm B running | H-AI Arm B in flight (askeladd) |
| **Cautious-AdamW dense-only** | TBD | H-AK' in flight (fern) |
| **AdamW β₂ warmup** | TBD | H-AL in flight (frieren) |
| **Muon WD cosine schedule** | TBD | H-AM in flight (tanjiro) |
| **Multi-anchor RI** | TBD | H-AN in flight (nezuko) |
| **Per-block Muon LR** | TBD | H-AO in flight (edward) |

## Saturated levers (CLOSED — no need to retest)

1. RI γ axis at fixed capture=2375 (H-AD edward)
2. RI single-anchor capture × γ sweep (H-AE fern)
3. SWA tail averaging (H-AB askeladd)
4. Arbor without EN (H-Z frieren)
5. NC without Arbor (H-O/H-N/H-K)
6. Drop EN from NC×Arbor stack (H-Y tanjiro)
7. **EMA-Nesterov γ (H-AH frieren): γ=0.99 sharply locally optimal**
8. **Muon LR ±20% (H-AG tanjiro): LR=0.0375 locally optimal**
9. **NS iteration count NS10 vs NS12 (H-AF nezuko): indistinguishable within noise**
10. **z-loss aux (H-AJ edward): monotone-bad across decade weight sweep**
11. **Cautious-AdamW uniform recipe (H-AK fern): embed sparse-row pathology**

## Strategic note: Mechanism classes remain — scalars exhausted

All scalar/iterative axes of the rank-1 stack are now saturated. Active experiments attack genuinely different mechanism axes:
- **New readout mechanisms** (H-AN multi-anchor RI)
- **Schedule mechanisms** (H-AL β₂ warmup, H-AM Muon WD schedule)
- **Architecture-level differentiation** (H-AO per-block Muon LR, H-AA Arbor warmup)
- **Selective optimizer mechanisms** (H-AK' Cautious-AdamW dense-only, H-AI NS coef retune)

**Mechanism finding from H-AK (publishable):** Liang et al. Cautious optimizer recipe assumes dense gradients; sparse-row tensors (embed weight) break the rescale normalization. Future cautious-optimizer applications should add per-row sparsity check.

## Next-wave hypotheses (for next idle students)

1. **AdamW β₁ warmup** — ramp β₁=0.7→0.8 over first 500 steps (orthogonal to H-AL β₂)
2. **EMA-Nesterov prefill/rest schedule** — PREFILL_STEPS=300 and REST_STEPS=1950 are fixed; scheduling them is unexplored
3. **Gradient noise injection schedule** — small Gaussian noise to Muon gradients decayed to 0 (Neelakantan et al. 2015)
4. **H-AK'' Row-wise cautious rescale for embed** — per-row scale over active rows; requires H-AK' to show positive lift first
5. **Sharpness-Aware Minimization (SAM) wrapper** — adversarial perturbation around Muon, 2× wall-time but fair in fixed-step regime
