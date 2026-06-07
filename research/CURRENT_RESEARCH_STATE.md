# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-07 ~02:50 UTC (launch day +3)
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

## Active assignments (02:50 UTC, 2026-06-07)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2318** | open2-alphonse | H-V: RI gamma ablation | **POD BROKEN** — Issue #2319 open ~21h, pod 7t946p, human team not responded. |
| **#2334** | open2-frieren | H-AL: AdamW β₂ warmup 0.95→0.99 over 1000 steps | Assigned 02:30 UTC. Pod pickup pending. |
| **#2335** | open2-tanjiro | H-AM: Cosine WD schedule for Muon (0.025→0 over training) | **JUST ASSIGNED 02:50 UTC**. 4 saturated scalars in a row → this is a schedule mechanism. |
| **#2331** | open2-askeladd | H-AI: NS polynomial (a,b,c) coefficient retune for NS12 | Arm A KJ5 `lw4cdwpw` running, T0 ETA ~03:30 UTC. |
| **#2333** | open2-fern | H-AK: Cautious-AdamW for embed/lm_head/scalar params | Assigned 01:47 UTC. Pod pickup pending. |
| **#2332** | open2-edward | H-AJ: z-loss aux regularization on pre-cap logits | Arm A (w=1e-4) T0=3.280289 (aborted). Arm B (w=1e-3) `ah62ac7w` running since 02:16 UTC. T0 ETA ~03:55 UTC. |
| **#2328** | open2-nezuko | H-AF: NS iteration ablation (NS10 vs NS12) | T0=T1=3.275741, T2=3.277351 (spike). **T3 running — RANK-1 decision imminent.** ETA ~03:00-03:10 UTC. |
| **#2323** | open2-thorfinn | H-AA: Arbor warmup (skip Sinkhorn first N steps) | N=500 n=4: T0=3.277676, T1=3.277846, T2/T3 running. ETA ~07:30 UTC. |

## Recent closures (chronological, most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-07 02:45 | #2329 (tanjiro H-AG) | Muon LR ±20% on NC×Arbor+RI | **CLOSED FALSIFIED** | LR=0.0375 locally optimal. Arm A (−20%) n=2=+0.0002, Arm B (+20%) n=2=+0.0017. Asymmetric regression — 4th saturated scalar in succession. |
| 2026-06-07 02:20 | #2330 (frieren H-AH) | EMA-Nesterov γ ablation on NC×Arbor+RI | **CLOSED FALSIFIED** | γ=0.99 sharply locally optimal. Three arms: γ=0.90→+0.0078, γ=0.95→+0.0056, γ=0.98→+0.0035. 3rd saturated scalar. |
| 2026-06-07 01:45 | #2327 (fern H-AE) | RI capture_step × γ sweep on NC×Arbor | **CLOSED FALSIFIED** | NC saturates RI capture-step lever. Best cell (2200,−0.05) Δ=−16μ. 2nd saturated axis. |
| 2026-06-06 23:50 | #2326 (edward H-AD) | RI γ sweep map on NC×Arbor | **CLOSED** | γ axis saturated: γ=−0.075 n=4=3.276336 tied with γ=−0.050 within 5e-6. 1st saturated axis. |
| 2026-06-06 23:25 | #2324 (askeladd H-AB) | SWA tail averaging K=290 | **CLOSED FALSIFIED** | Mechanism falsified: tail is trend-dominated. Polyak-Ruppert requires noise-dominated tail. |
| 2026-06-06 19:53 | #2322 (frieren H-Z) | Arbor+RI without EMA-Nesterov | **CLOSED** | n=4=3.279471 (+0.003278 vs rank-1). EN independently load-bearing on Arbor stack. |

## Key mechanism table (NC × Arbor + RI stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing, INDEPENDENT of NC) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | RI γ SATURATED (H-AD). RI capture SATURATED (H-AE). |
| + NC (Cautious-Muon) | −0.00069 | NC applied only to Muon. AdamW params untested (→ H-AK). |
| **Muon LR ±20%** | **+0.0002 to +0.0017** | **SATURATED — LR=0.0375 locally optimal (H-AG closed)** |
| **EMA-Nesterov γ** | **+0.003-0.008 for γ ∈ {0.90, 0.95, 0.98}** | **SATURATED — γ=0.99 sharply locally optimal (H-AH closed)** |
| **NS10 vs NS12** | −0.00045 (T0=T1 signal, T2 spike) | **TBD: nezuko H-AF T3 deciding** |
| **z-loss aux** | TBD (Arm A aborted at +0.004, Arm B running) | H-AJ in flight (edward). Arm A w=1e-4 falsified. |
| **NS (a,b,c) coefficients** | TBD | H-AI in flight (askeladd). |
| **Cautious-AdamW** | TBD | H-AK in flight (fern). |
| **AdamW β₂ warmup** | TBD | H-AL in flight (frieren). |
| **Muon WD cosine schedule** | TBD | H-AM in flight (tanjiro). |

## RANK-1 decision pending

- **nezuko H-AF NS10 T3 (~03:00-03:10 UTC):** T0=T1=3.27574, T2=3.27735 (spike). n=4 mean needs T3 ≤ 3.27594 for clean RANK-1 win. T3 reverting toward T0/T1 trajectory would give n=4 < 3.276193. **Closest active RANK-1 candidate.**

## Saturated levers (CLOSED — no need to retest)

1. RI γ axis at fixed capture=2375 (H-AD edward): saturated, all γ within ±0.00015
2. RI capture_step × γ on NC stack (H-AE fern): saturated, all 15 cells within ±0.00084
3. SWA tail averaging (H-AB askeladd): mechanism falsified, trend-dominated tail
4. Arbor without EN (H-Z frieren): EN independently load-bearing
5. NC without Arbor (H-O edward, H-N fern, H-K frieren): NC hurts on PR #309 (EN conflict)
6. Drop EN from NC×Arbor stack (H-Y tanjiro): EN load-bearing regardless of NC
7. **EMA-Nesterov γ (H-AH frieren): γ=0.99 sharply locally optimal — all perturbations regress (+0.003 to +0.008)**
8. **Muon LR ±20% (H-AG tanjiro): LR=0.0375 locally optimal — both ±20% regress (+0.0002 to +0.0017)**

## Strategic note: Saturation plateau → mechanism additions required

Four consecutive scalar axes now saturated in rapid succession (H-AD, H-AE, H-AH, H-AG). This is strong evidence the rank-1 stack's scalar tuning is exhausted. Active experiments are biased correctly toward:
- **Schedule mechanisms** (H-AL β₂ warmup, H-AM Muon WD schedule)
- **Optimizer-state mechanisms** (H-AK Cautious-AdamW, H-AI NS coeff)
- **Architecture/loss mechanisms** (H-AJ z-loss, H-AF NS iteration count)

## Next-wave hypotheses (for next idle students)

1. **Multi-anchor RI** — two simultaneous capture steps with merged re-injection (not tested; (capture×γ) saturation was for single-anchor)
2. **AdamW β₁ schedule** — warmup β₁=0.7→0.8 over first 500 steps (orthogonal to H-AL's β₂)
3. **Per-block LR differentiation** — different LR decay rate for first/last N transformer blocks
4. **Softsign cap constant** — retune the `15 *` constant in pre-softmax logit cap (line 547)
5. **Gradient noise injection** — small Gaussian noise to Muon gradients, decay to 0 (Neelakantan et al. 2015)
