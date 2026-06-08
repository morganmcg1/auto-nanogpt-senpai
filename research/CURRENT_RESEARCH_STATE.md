# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~14:35 UTC (launch day +4) — **lever 53 CLOSED**: frieren H-DL EN lookahead_stepsize FALSIFIED (flat 0.15–0.30, climbs sharply at 0.45; default 0.30 at optimum). **53 saturated levers total.** New assignment: frieren → H-DS (ARBOR_ITERS sweep, PR #2382). **CRITICAL: thorfinn H-DM Arm A T0=3.276145 MERGE-ELIGIBLE (−0.000027 vs rank-1), T1 `fzztecwm` at step ~1500/2890, ETA ~15:10 UTC.**
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

## ⚡ CRITICAL WATCH: thorfinn H-DM (PR #2376)

**Arm A T0 = 3.276145 = MERGE-ELIGIBLE (−0.000027 below rank-1)**

0.66× MUON_POWER_C (2.189e-6 vs default 3.317e-6) shows genuine improvement. T1 `fzztecwm` launched 13:21:36 UTC, ETA ~14:42 UTC. Decision logic:
- If n=2 mean ≤ 3.276172 AND |T0−T1| ≤ 0.0008: MERGE-eligible, request n=4
- If |T0−T1| > 0.0008: variance gate triggers, n=4 mandatory before any merge
- If n=2 mean > 3.276172: INCONCLUSIVE, close Arm A, pivot Arm B

This is the strongest signal seen this round. Watch closely.

## Active assignments (~14:05 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2376** | open2-thorfinn | H-DM: Direct MUON_POWER_C sweep (0.66× vs 1.5×) | **⚡ CRITICAL** — T0=3.276145 MERGE-ELIGIBLE. T1 `fzztecwm` at step ~1500/2890, ETA ~15:10 UTC. |
| **#2382** | open2-frieren | H-DS: Sinkhorn iteration count sweep (arbor_iters 1 vs 4) | NEW — awaiting pod pickup. Tests whether 2-iter Sinkhorn is over/under-converged. Smoke gate first. |
| **#2373** | open2-tanjiro | H-CZ: EN rest_steps direction ablation (2400 vs never-disengage) | Arm A n=2 mean=3.277251 FALSIFIED. Arm B `095o6qc4` running, never-disengage rest=2890, ETA ~16:30 UTC. |
| **#2379** | open2-fern | H-DP: SOAP Kronecker preconditioner MLP+V | NEW — awaiting pod pickup. Arm A: SOAP on MLP (c_fc, c_proj). Arm B: extend to attn-V. Smoke gate first. |
| **#2378** | open2-alphonse | H-DO: NC placement — NC-AFTER-NS5 | NEW — awaiting pod pickup. Reversed: NC after NS-iter (normalize after Newton-Schulz, not before). Smoke gate first. Corrected from original spec inversion. |
| **#2377** | open2-edward | H-DN: Stack prune NC vs Amsgrad AdamW | Arm A: `--nc 0` (remove NC). Arm B: full stack + Amsgrad. Smoke gate active or in progress. |
| **#2380** | open2-nezuko | H-DQ: Contra-Muon coeff sweep (0.1 vs 0.3) | NEW — awaiting pod pickup. Re-enables disabled Contra-Muon mechanism (`CONTRA_MUON_COEFF=0.0`). Arm A: 0.1, Arm B: 0.3 conditional. |
| **#2381** | open2-askeladd | H-DR: Soft-Muon CEIL sweep (0.1 vs 0.3) | NEW — awaiting pod pickup. Re-enables disabled Soft-Muon mechanism (`SOFT_MUON_CEIL=0.0`). Late-training NS5-variant fade-in (steps 2500–3010). Arm A: 0.1, Arm B: 0.3 conditional. |

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
