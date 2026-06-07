# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~02:30 UTC (launch day +3)
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

## Active assignments (02:30 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~20h, pod 7t946p, human team not responded. |
| **#2334** | open2-frieren | H-AL: AdamW β₂ warmup 0.95→0.99 over 1000 steps | **JUST ASSIGNED 02:30 UTC**. Motivated by H-AH: EMA windows load-bearing, β₂=0.99 constant never scheduled before. |
| **#2331** | open2-askeladd | H-AI: NS polynomial (a,b,c) coefficient retune for NS12 | Arm A KJ5 `lw4cdwpw` running, step ~1300+. T0 ETA ~03:30 UTC. |
| **#2333** | open2-fern | H-AK: Cautious-AdamW for embed/lm_head/scalar params | Assigned 01:47 UTC. Pod pickup pending. |
| **#2332** | open2-edward | H-AJ: z-loss aux regularization on pre-cap logits | Arm A z-loss=1e-4 `bgdn33vz` near step 2890. T0 imminent. |
| **#2329** | open2-tanjiro | H-AG: LR retune (Muon LR ±20%) | Arm A LR=0.030 inconclusive. Arm B LR=0.045 `agvlim5e` at step ~4766. T1 ETA ~02:30 UTC. |
| **#2328** | open2-nezuko | H-AF: NS iteration ablation (NS10 vs NS12) | T0=T1=3.275741, T2=3.277351 (seed variance spike). **T3 ETA ~02:40-03:00 UTC — RANK-1 decision.** |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup (skip Sinkhorn first N steps) | N=500 n=4: T0=3.277676, T1=3.277846. T2 ETA ~02:45 UTC. |

## Recent closures (chronological)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 02:20 | #2330 (frieren H-AH) | EMA-Nesterov γ ablation on NC×Arbor+RI | **CLOSED FALSIFIED** | γ=0.99 sharply locally optimal. Three arms: γ=0.90→+0.0078, γ=0.95→+0.0056, γ=0.98→+0.0035. Monotonic, ~100-step EMA window essential. Three T1s killed early. |
| 2026-06-07 01:45 | #2327 (fern H-AE) | RI capture_step × γ sweep on NC×Arbor | **CLOSED FALSIFIED** | NC saturates RI capture-step lever. Best cell (2200,−0.05) Δ=−16μ — within seed noise. Definitively closes (capture×γ) sweep family on this stack. |
| 2026-06-06 23:50 | #2326 (edward H-AD) | RI γ sweep map on NC×Arbor | **CLOSED** | γ axis saturated: γ=−0.075 n=4=3.276336 tied with γ=−0.050 within 5e-6. Uniform +0.000143 offset (seed variance). RI γ axis closed. |
| 2026-06-06 23:25 | #2324 (askeladd H-AB) | SWA tail averaging K=290 | **CLOSED FALSIFIED** | Mechanism falsified: tail is trend-dominated (val/loss 3.301→3.280 over SWA window). Polyak-Ruppert requires noise-dominated tail — not satisfied at 2890 steps. |
| 2026-06-06 19:53 | #2322 (frieren H-Z) | Arbor+RI without EMA-Nesterov | **CLOSED** | n=4=3.279471 (+0.003278 vs rank-1). EN independently load-bearing on Arbor stack. |
| 2026-06-06 18:43 | #2321 (tanjiro H-Y) | Drop EN from NC×Arbor+RI | **CLOSED** | n=4=3.278702 (+0.002509). EN load-bearing even with NC. |
| 2026-06-06 18:18 | #2325 (nezuko H-AC) | NC cleanup: always-on | **MERGED** | NC is now always-on default, `--nc` flag removed. |
| 2026-06-06 17:48 | #2320 (fern H-X) | Capture step ablation on Arbor-only | **CLOSED** | (2200,−0.05) sign-stable winner but only n=4 Δ=−0.000031 vs default — sub-threshold. H-AE follow-up assigned. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing, INDEPENDENT of NC) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | RI γ axis SATURATED (H-AD). Capture axis SATURATED (H-AE on NC stack). |
| + NC (Cautious-Muon) | −0.00069 | NC applied only to Muon. AdamW params untested (→ H-AK). |
| **NS10 vs NS12** | −0.00045 (T0=T1 signal, T2 reverted) | **TBD: nezuko H-AF T3 deciding** |
| **EMA-Nesterov γ** | **+0.003-0.008 for γ ∈ {0.90, 0.95, 0.98}** | **SATURATED — γ=0.99 sharply locally optimal (H-AH closed)** |
| **Muon LR ±20%** | ∓0.0002 to ∓0.0006 | LR=0.0375 appears locally optimal. H-AG closing. |
| **z-loss aux** | TBD | H-AJ in flight (edward). |
| **NS (a,b,c) coefficients** | TBD | H-AI in flight (askeladd). |
| **Cautious-AdamW** | TBD | H-AK in flight (fern). |
| **AdamW β₂ warmup** | TBD | H-AL in flight (frieren). |

## RANK-1 decision pending

- **nezuko H-AF NS10 T3 (~02:40-03:00 UTC):** T0=T1=3.27574, T2=3.27735. n=4 mean needs T3 ≤ 3.27594 to be a clean winner. T3 reversion toward T0/T1 trajectory would give n=4 < 3.276193. Close call.

## Saturated levers (CLOSED — no need to retest)

1. RI γ axis at fixed capture=2375 (H-AD edward): saturated, all γ within ±0.00015
2. RI capture_step × γ on NC stack (H-AE fern): saturated, all 15 cells within ±0.00084
3. SWA tail averaging (H-AB askeladd): mechanism falsified, trend-dominated tail
4. Arbor without EN (H-Z frieren): EN independently load-bearing
5. NC without Arbor (H-O edward, H-N fern, H-K frieren): NC hurts on PR #309 (EN conflict)
6. Drop EN from NC×Arbor stack (H-Y tanjiro): EN load-bearing regardless of NC
7. **EMA-Nesterov γ (H-AH frieren): γ=0.99 sharply locally optimal — all perturbations (+0.003 to +0.008) regress**

## Next-wave hypotheses (for next idle students)

1. **Decoupled Muon WD scheduling** — cosine-decay WD=0.025→0 over training; Adam WD follows same schedule
2. **Multi-anchor RI** — two capture steps with merged re-injection (e.g., capture at 2200+2375, add weighted snapshots)
3. **Gradient clipping schedule** — ramp clip threshold over training (generous early, tight late) to match gradient distribution shifts
4. **β₁ schedule for AdamW** — warmup β₁=0.7→0.8 or decay β₁=0.8→0.9 (orthogonal to H-AL's β₂ schedule)
5. **Softsign cap constant tuning** — `15 *` constant at line 547 may not be optimal with NC+EN on top
