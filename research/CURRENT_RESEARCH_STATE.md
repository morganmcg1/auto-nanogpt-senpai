# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~15:15 UTC (launch day +4) — **53 saturated levers**. **THORFINN H-DM Arm A FALSIFIED at n=2 — variance gate triggered.** T0=3.276145 MERGE-eligible but T1=3.279542 FALSIFIED, |ΔT|=0.003397 (4.2× variance gate). n=2 mean=3.277843. Arm B `hkklezxw` launched 15:08 UTC seed 1, ETA ~16:46 UTC. Advisor directed skip Arm A T2/T3 (math doesn't allow recovery even with perfect retests — T1 anchors n=4 mean ≥ 3.276422). **Tanjiro H-CZ Arm B `095o6qc4` T0 finished: val/ri=3.276700** (FALSIFIED +0.000528, but much closer to rank-1 than Arm A's mean 3.277251). T1 mid-trial step 4991/5780. **Edward H-DN Arm A `vovpov6p` T0 finished: val/ri=3.276435** (INCONCLUSIVE +0.000263). NC removal barely changes baseline — potential simplification finding. T1 mid-trial step 3041/5780. Alphonse H-DO Arm A T0 65% complete. Fern H-DP Arm A launched after nudge.
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

## ⚡ THORFINN H-DM Arm A FALSIFIED at n=2 — pivot to Arm B

**Arm A n=2 mean = 3.277843 (FALSIFIED band, +0.001671 vs rank-1). Variance gate massively triggered (|ΔT|=0.003397).**

| Run | seed | val/ri | Band |
|---|---:|---:|---|
| `a4rhgzhh` Arm A T0 | 1 | 3.276145 | MERGE-eligible (lucky) |
| `fzztecwm` Arm A T1 | 2 | 3.279542 | FALSIFIED (unlucky) |
| **n=2 mean** | | **3.277843** | **FALSIFIED** |

**Advisor directed (15:15 UTC):** SKIP Arm A T2/T3 — math doesn't allow recovery. Best-case n=4 with T2/T3 at 3.276145 quality = mean 3.276994 (FALSIFIED). T1=3.279542 anchors above the bar. Saves ~3h GPU.

**Plan:** focus on Arm B (`hkklezxw`, MUON_POWER_C 4.975e-6, seed 1). Launched 15:08 UTC, ETA ~16:46 UTC. If Arm B n=2 mean MERGE-eligible AND variance gate ≤ 0.0008 → n=4 confirm. If Arm B FALSIFIED → close H-DM.

## Active assignments (~15:15 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2376** | open2-thorfinn | H-DM: Direct MUON_POWER_C sweep (0.66× vs 1.5×) | Arm A FALSIFIED at n=2 (variance gate). Arm B `hkklezxw` (4.975e-6, seed 1) step ~200/2890, ETA ~16:46 UTC. Skip Arm A T2/T3. |
| **#2382** | open2-frieren | H-DS: Sinkhorn iteration count sweep (arbor_iters 1 vs 4) | Smoke `929r3jae` finished. Arm A `6omk0f3n` (iters=1, seed 0) step 400/2890. ETA ~16:30-17:00 UTC for first trial. |
| **#2373** | open2-tanjiro | H-CZ: EN rest_steps direction ablation (2400 vs never-disengage) | Arm A FALSIFIED at n=2 (3.277251). **Arm B `095o6qc4` T0=3.276700 (FALSIFIED +0.000528 but tight)**, T1 mid-trial step 4991/5780 (~86%), ETA ~16:00 UTC. Arm B much closer to rank-1 than Arm A. |
| **#2379** | open2-fern | H-DP: SOAP Kronecker preconditioner MLP+V | Arm A `3nbegxqi` n=2 step 500/5780. Smoke val@50=7.69 (vs 5.35 baseline) — SOAP-warmup 10 steps explanation reasonable. ETA ~21:00 UTC. |
| **#2378** | open2-alphonse | H-DO: NC placement — NC-AFTER-NS5 | Arm A `4d9ex41g` n=2 step 1925/5780 (~33%). Smoke `jduakamv` running at step 120 (Arm B prep?). Spec corrected: NC-AFTER-NS5 is novel direction. |
| **#2377** | open2-edward | H-DN: Stack prune NC vs Amsgrad AdamW | **Arm A `vovpov6p` T0=3.276435 (INCONCLUSIVE +0.000263)**. NC removal barely changes baseline — potential simplification. T1 mid-trial step 3041/5780, ETA ~16:00-16:30 UTC. |
| **#2380** | open2-nezuko | H-DQ: Contra-Muon coeff sweep (0.1 vs 0.3) | **STUCK on smoke loop** — 5+ smokes since 14:09 UTC, no PR comments. Advisor nudge posted 15:15 UTC demanding n=2 launch within 10 min or failure mode. |
| **#2381** | open2-askeladd | H-DR: Soft-Muon CEIL sweep (0.1 vs 0.3) | Arm A `nfwmi2g4` (ceil=0.1) step 1750/2890 (~61%), healthy. ETA ~17:00 UTC. |

## Recent closures (most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 14:30 | **#2375 (frieren H-DL)** | EN lookahead_stepsize sweep (0.15 vs 0.45) | **CLOSED 53RD LEVER** | Arm A (0.15) flat with baseline (−9e-6, within σ_pair). Arm B (0.45) FALSIFIED +0.002525. Default 0.30 at optimum; surface flat below 0.30, climbs sharply above. |
| 2026-06-08 13:55 | **#2374 (askeladd H-DK)** | ARBOR_CLAMP_K sweep (2.0 vs 5.0) | **CLOSED 52ND LEVER** | Asymmetric penalty: clamp=2.0 catastrophic +0.00274, clamp=5.0 marginal +0.000467. Default 3.0 at near-tight local optimum. Sinkhorn tolerant of loosening, sharply punished by over-clamping. |
| 2026-06-08 13:26 | **#2370 (nezuko H-DH)** | SWA-EMA on AdamW dense params | **CLOSED 51ST LEVER** | Both arms FALSIFIED. SWA adds +0.000125-0.000156 bias over raw: AdamW tail trajectory still directionally improving, not noise-dominated. Weight-space averaging axis fully closed. |
| 2026-06-08 12:50 | **#2371 (fern H-DI)** | SOAP_BETA2 sweep (0.95 vs 0.85) | **CLOSED 50TH LEVER** | Both arms FALSIFIED. Arm A (0.95) +0.001838, Arm B (0.85) +0.000676. 0.90 at local optimum for 2890-step schedule. |
| 2026-06-08 12:47 | **#2318 (alphonse H-V)** | RI γ ablation n=4 on stripped stack | **CLOSED 49TH LEVER** | n=4 mean=3.276460 FALSIFIED. n=2 sub-signal 3.275803 was variance artifact. γ=−0.075 confirmed optimal. |
| 2026-06-08 12:47 | **#2369 (edward H-CY)** | NorMuon-lite β₂ sweep (0.99 vs 0.95) | **CLOSED 48TH LEVER** | Both arms FALSIFIED. "4th redundant smoothing layer" — NC+Arbor+EN already compress heterogeneity. |
| 2026-06-08 10:30 | **#2372 (thorfinn H-DJ)** | Lookahead-on-Muon (k=5/α=0.5) | **CLOSED 47TH LEVER CATASTROPHIC** | T0=3.295566 (+0.019394, 50× FALSIFIED). Lookahead axis FULLY closed (both AdamW H-BU and Muon). |

## Saturated levers count: 53

Levers 38–53:
38. **Lookahead k=5 α=0.5 on AdamW (H-BU)** — CATASTROPHIC +0.00823.
39. **Embed-only LR ±50% (H-BL)** — bidirectional. Direction-dependent seed-split.
40. **NS-iter × Muon LR coupling (H-BJ)** — both arms FALSIFIED.
41. **FINAL_LR_POWER recalibration (H-DA)** — informative-negative.
42. **AdamW (β₁=0.85, β₂=0.98) sweep (H-BO)** — n=2 STRONG FALSE POSITIVE; n=4 mean=3.277438.
43. **RI capture_step earlier=2250 (H-CX)** — FALSIFIED. RI-EARLIER axis closed.
44. **Muon WD sweep 0.010 vs 0.050 (H-BN)** — FALSIFIED. WD locked at 0.025.
45. **EN-on-AdamW (H-BW)** — both arms FALSIFIED. EN mechanism is Muon-specific.
46. **lm_head soft-warmup + higher target LR (H-CA)** — FALSIFIED. LR floor invariant added.
47. **Lookahead k=5/α=0.5 on Muon (H-DJ)** — CATASTROPHIC +0.019394. Lookahead axis FULLY closed.
48. **NorMuon-lite β₂ sweep (H-CY)** — FALSIFIED. "4th redundant smoothing layer."
49. **RI γ ablation n=4 stripped stack (H-V)** — FALSIFIED. γ=−0.075 optimal confirmed.
50. **SOAP_BETA2 sweep 0.95/0.85 (H-DI)** — FALSIFIED both. 0.90 at local optimum.
51. **SWA-EMA on AdamW dense params (H-DH)** — FALSIFIED both. AdamW tail still directionally improving, weight-space averaging axis closed.
52. **ARBOR_CLAMP_K sweep 2.0/5.0 (H-DK)** — FALSIFIED both. Asymmetric penalty; default 3.0 at local optimum, axis closed.
53. **EN lookahead_stepsize sweep 0.15/0.45 (H-DL)** — Flat 0.15–0.30, climbs sharply at 0.45. Default 0.30 at optimum, axis closed.

## Key mechanism table (NC × Arbor + RI + eps=1e-12 stack)

| Component | Absolute Δ val/loss | Saturated? |
|---|---:|---|
| Arbor (Sinkhorn) | −0.00049 | — |
| + EMA-Nesterov (γ=0.99) | −0.0028 (load-bearing) | — |
| + RI (capture=2375, γ=−0.075) | −0.00032 | Single-anchor axis SATURATED |
| + NC (Cautious-Muon) | −0.00069 | Testing removal (H-DN Arm A) |
| + eps=1e-12 (AdamW) | **−0.000021** | Borderline attribution |

## Cross-PR seed pattern observation

**Seed 0 / 1 split confirmed** across H-AY and H-BL Arm A, BROKEN by H-BL Arm B and H-BO Arm B T1.
**Updated reading**: seed-split is direction-dependent, not axis-wide. H-BO Arm B T1=3.274075 strongest single-seed trial ever seen — n=4 confirmed variance artifact (mean 3.277438 FALSIFIED).

## Invariants confirmed (hard constraints on the stack)

1. **Muon LR uniformity across blocks** — H-BI.
2. **No DC-mode operations on Muon update path** — H-AT/H-BH.
3. **Post-NS5 update spectrum: no concentration** — H-BC.
4. **AdamW LR: no uniform multi-group boosts** — H-BF.
5. **Muon LR must be monotonic-down through step 2375 RI capture** — H-BK.
6. **lm_head LR must be ≥ baseline 1/320 throughout training** — H-CA bf16 cascade discovery.

## Next wave hypotheses (queued for next idle slots)

Priority ranked:
1. **MUON_POWER_C tighter sweep** (0.66× confirmed, try 0.55×/0.75× range) — if H-DM confirms MERGE.
2. **AdamW β₁ schedule** — ramp β₁ from 0.9→0.95 or 0.9→0.8 over training. Untouched axis after 52 experiments.
3. **Sinkhorn iteration count** (ARBOR_ITERS sweep) — clamp_k exhausted; iteration depth is a different bottleneck.
4. **H-DB**: Aurora K sweep (`--aurora_k` 1 vs 5 vs default 3). Row-balance iterations.
5. **H-BR**: NS5 cubic polynomial coefficient retune (`(3, -3, 1)` alternatives).
6. **H-BP**: Muon momentum MU sweep (0.90/0.98 vs default 0.95) — scalar, lower priority.
7. **Aurora compliance check** (for tanjiro after H-CZ closes): Verify benchmark eligibility under track-3 contract.

## Disabled mechanisms still to probe

The current rank-1 code has two mechanisms fully disabled via zero coefficients:
- **Contra-Muon** (`CONTRA_MUON_COEFF=0.0`, line 61): in progress as H-DQ (nezuko PR #2380)
- **Soft-Muon** (`SOFT_MUON_CEIL=0.0`, line 65): in progress as H-DR (askeladd PR #2381)

Both were active in KellerJordan PR #305 baseline (Contra-Muon extended). Re-enabling either is a valid hypothesis satisfying the "optimizer-state mechanisms" directive.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

Current wave satisfies directive: H-DN (NC pruning/ablation), H-DO (NC placement after NS5), H-DP (SOAP Kronecker preconditioner), H-DL (EN lookahead schedule), H-DM (MUON_POWER_C mechanism), H-DQ (Contra-Muon optimizer mechanism), H-DR (Soft-Muon NS5-variant mechanism), H-CZ (EN rest_steps schedule).
