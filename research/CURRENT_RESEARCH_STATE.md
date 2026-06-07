# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~03:10 UTC (launch day +3)
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

## Active assignments (03:10 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~22h, pod 7t946p, human team not responded. |
| **#2336** | open2-nezuko | H-AN: Multi-anchor RI (2 simultaneous captures) | **JUST ASSIGNED 03:05 UTC**. Single-anchor saturated → test if 2 captures encode orthogonal gradient directions that compound. |
| **#2334** | open2-frieren | H-AL: AdamW β₂ warmup 0.95→0.99 over 1000 steps | Assigned 02:30 UTC. Pod pickup pending. |
| **#2335** | open2-tanjiro | H-AM: Cosine WD schedule for Muon (0.025→0 over training) | Assigned 02:50 UTC. Pod pickup pending. |
| **#2331** | open2-askeladd | H-AI: NS polynomial (a,b,c) coefficient retune for NS12 | Arm A KJ5 `lw4cdwpw` running. T0 ETA ~03:30 UTC. |
| **#2333** | open2-fern | H-AK: Cautious-AdamW for embed/lm_head/scalar params | Assigned 01:47 UTC. Pod pickup pending. |
| **#2332** | open2-edward | H-AJ: z-loss aux regularization on pre-cap logits | Arm A (w=1e-4) T0=3.280289 (aborted). Arm B (w=1e-3) `ah62ac7w` running. T0 ETA ~03:55 UTC. |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup (skip Sinkhorn first N steps) | N=500 n=4: T0=3.277676, T1=3.277846, T2/T3 running. ETA ~07:30 UTC. |

## Recent closures (chronological, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 03:05 | #2328 (nezuko H-AF) | NS10 vs NS12 on NC×Arbor+RI | **CLOSED INCONCLUSIVE** | NS10 n=4=3.276248 (+55μ above rank-1, inside SEM). NS10=NS12 within noise. NS iter axis saturated at 10-12. 5th saturated axis. |
| 2026-06-07 02:45 | #2329 (tanjiro H-AG) | Muon LR ±20% on NC×Arbor+RI | **CLOSED FALSIFIED** | LR=0.0375 locally optimal. Both ±20% arms regress (+0.0002 and +0.0017). 4th saturated scalar. |
| 2026-06-07 02:20 | #2330 (frieren H-AH) | EMA-Nesterov γ ablation | **CLOSED FALSIFIED** | γ=0.99 sharply optimal. All perturbations regress (+0.003 to +0.008). 3rd saturated scalar. |
| 2026-06-07 01:45 | #2327 (fern H-AE) | RI capture_step × γ sweep (15-cell) | **CLOSED FALSIFIED** | NC saturates single-anchor capture axis. All 15 cells within ±0.000835. 2nd saturated axis. |
| 2026-06-06 23:50 | #2326 (edward H-AD) | RI γ sweep on NC×Arbor | **CLOSED** | γ axis saturated (all within 5μ). 1st saturated axis. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED (H-AD, H-AE) |
| + NC (Cautious-Muon) | −0.00069 | AdamW params untested (→ H-AK) |
| **Muon LR ±20%** | regresses +0.0002 to +0.0017 | **SATURATED — LR=0.0375 optimal** |
| **EMA-Nesterov γ** | regresses +0.003 to +0.008 | **SATURATED — γ=0.99 sharply optimal** |
| **NS10 vs NS12** | +0.000055 (within noise) | **SATURATED — NS10=NS12 within noise** |
| **z-loss aux** | Arm A (w=1e-4) aborted (+0.004), Arm B running | H-AJ in flight (edward) |
| **NS (a,b,c) coefficients** | TBD | H-AI in flight (askeladd), T0 ETA ~03:30 UTC |
| **Cautious-AdamW** | TBD | H-AK in flight (fern) |
| **AdamW β₂ warmup** | TBD | H-AL in flight (frieren) |
| **Muon WD cosine schedule** | TBD | H-AM in flight (tanjiro) |
| **Multi-anchor RI** | TBD | H-AN in flight (nezuko) |

## Saturated levers (CLOSED — no need to retest)

1. RI γ axis at fixed capture=2375 (H-AD edward)
2. RI single-anchor capture × γ sweep (H-AE fern): all 15 cells within ±0.000835
3. SWA tail averaging (H-AB askeladd): trend-dominated tail, mechanism falsified
4. Arbor without EN (H-Z frieren): EN independently load-bearing
5. NC without Arbor (H-O/H-N/H-K): NC hurts on PR #309 without Arbor
6. Drop EN from NC×Arbor stack (H-Y tanjiro): EN load-bearing regardless
7. **EMA-Nesterov γ (H-AH frieren): γ=0.99 sharply locally optimal**
8. **Muon LR ±20% (H-AG tanjiro): LR=0.0375 locally optimal**
9. **NS iteration count NS10 vs NS12 (H-AF nezuko): indistinguishable within noise**

## Strategic note: 5 consecutive saturated axes

Five consecutive experiments (H-AD, H-AE, H-AH, H-AG, H-AF) all saturated the scalar/iterative axes of the rank-1 stack. This is a clear signal that the optimization landscape has been thoroughly explored in the scalar neighborhood of rank-1. Active experiments are correctly biased toward:

- **New readout mechanisms** (H-AN multi-anchor RI)
- **Schedule mechanisms** (H-AL β₂ warmup, H-AM Muon WD schedule)
- **Optimizer-state mechanisms** (H-AK Cautious-AdamW, H-AI NS coefficients, H-AJ z-loss)
- **Architecture-adjacent** (H-AA Arbor warmup)

The next RANK-1 candidate will come from one of these mechanism classes, not from further scalar perturbation.

## Next-wave hypotheses (for next idle students)

1. **AdamW β₁ warmup** — ramp β₁=0.7→0.8 over first 500 steps (orthogonal to H-AL β₂); Arm A cosine, Arm B linear
2. **Per-block LR differentiation** — different LR decay rate for early/late transformer blocks (attention + MLP blocks can have different optimization dynamics)
3. **Softsign cap constant retune** — `15 *` constant at line 547; cap=10 (tighter) vs cap=20 (looser)
4. **Gradient noise injection schedule** — small Gaussian noise to Muon gradients decayed to 0 (Neelakantan et al. 2015); optimizer-state mechanism
5. **EMA-Nesterov prefill/rest schedule** — current `EMA_NESTEROV_PREFILL_STEPS` and `EMA_NESTEROV_REST_STEPS` are fixed; scheduling them is unexplored
