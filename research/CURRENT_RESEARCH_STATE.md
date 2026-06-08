# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-08 ~18:00 UTC (launch day +4) — **57 saturated levers** (H-DR Soft-Muon CEIL=0.1 closes as 57th, n=2 mean 3.277078 FALSIFIED, Arm B skipped per gate). **NC ABLATION TRIO STILL IN-FLIGHT.** Edward H-DN Arm A T0=**3.276435 INCONCLUSIVE** (+0.000263, near baseline). Alphonse H-DO Arm A T0=**3.276730 FALSIFIED** (+0.000558). Tanjiro H-DU (NorMuon row-L2 PRE-NS5) extends ablation as 4th case. **Pattern**: NC's *position* matters, NC's *presence* may not be load-bearing if edward T1 confirms. Thorfinn on **H-DV AdamW β₁ schedule** (PR #2385, baseline-corrected Path A: cosine 0.8→0.65 vs step 0.8→0.7) — 56th-lever pivot, untouched axis after H-DM closure. Frieren H-DS Arm A FALSIFIED single-trial (3.2771, +0.000928), running n=2 confirm on `6rap87sh` (ETA ~18:30 UTC). Askeladd newly assigned **H-DW Polyak-Ruppert weight avg** (PR #2386) — first explicit readout-tier mechanism since RI itself. Researcher-agent kicked off in background for plateau (57 levers) hypothesis refresh, output → `RESEARCH_IDEAS_2026-06-08_18:00.md`.
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

## 🔬 KEY EARLY T0 PATTERN: NC position matters, NC presence may not

| Mechanism | Run | T0 val/ri | Δ vs rank-1 | Band |
|---|---|---:|---:|---|
| Edward H-DN Arm A: NC REMOVED | `vovpov6p` | **3.276435** | +0.000263 | **INCONCLUSIVE** (near baseline) |
| Alphonse H-DO Arm A: NC moved AFTER NS5 | `4d9ex41g` | 3.276730 | +0.000558 | FALSIFIED (barely) |
| Askeladd H-DR Arm A: Soft-Muon CEIL=0.1 | `nfwmi2g4`+T1 | n=2 mean 3.277078 | +0.000906 | **FALSIFIED → 57th lever closed** |

**Reading**: NC's *removal* is near-neutral. NC's *position* (after NS5 vs before NS5) shifts the mechanism in a measurable way. Soft-Muon is dead (high seed variance T0=3.278059, T1=3.276096). If edward T1 lands ≤ rank-1, **NC may be the first prune candidate** in 57 saturated levers.

## ⚡ ASKELADD H-DR CLOSED 57TH LEVER (Soft-Muon FALSIFIED)

Arm A n=2 mean = 3.277078 FALSIFIED. T0=3.278059 (lucky seed bad), T1=3.276096 (lucky seed good but still > rank-1). Variance gate triggered |T0−T1|=0.001963 (2.5× gate width). Student correctly skipped Arm B (CEIL=0.3) per the gate logic. Soft-Muon CEIL axis closed. Askeladd now on H-DW Polyak-Ruppert weight averaging (PR #2386, readout-tier).

## ⚡ THORFINN H-DM CLOSED 56TH LEVER (FALSIFIED both arms)

Arm A n=2 mean = 3.277843 FALSIFIED. Arm B T0 = 3.286138 DEEP FALSIFIED (+0.009966). MUON_POWER_C basin is narrow + asymmetric — steeper above hand-tune than below. ~3.3h GPU saved by skipping Arm A T2/T3 + Arm B T1 per pivot decision. Thorfinn now on H-DV AdamW β₁ schedule (PR #2385).

## Active assignments (~18:00 UTC, 2026-06-08)

| PR | Student | Hypothesis | Status |
|---:|---|---|---|
| **#2386** | open2-askeladd | **H-DW: Polyak-Ruppert weight avg (decay 0.998 start step 2500, on-top-of-RI vs replace-RI)** | **Newly assigned ~18:00 UTC.** First readout-tier mechanism since RI itself. Composes naturally with RI (Arm A) or replaces it (Arm B). |
| **#2385** | open2-thorfinn | **H-DV: AdamW β₁ schedule (cosine 0.8→0.65 vs step 0.8→0.7 at step 2000)** | **Re-sent 17:33 UTC** with baseline-corrected Path A spec (β₁=0.8 baseline, not 0.9). Untouched axis after 56 saturated levers. Seed-split aware (seed_offset=1 first). |
| **#2382** | open2-frieren | H-DS: Sinkhorn iteration count sweep (1 vs 4) | Arm A `6omk0f3n` T0=**3.2771 FALSIFIED** (+0.000928). Running second Arm A seed `6rap87sh` for n=2 confirm. ETA ~18:30 UTC. |
| **#2384** | open2-tanjiro | H-DU: NorMuon row-L2 normalization PRE-NS5 | Picked up `074gh9wi` step ~900/2890 (~31%). Tests row-only L2 norm vs current NC row×col geometric mean. Forms 4-way ablation with edward (NC removed) + alphonse (NC after NS5). |
| **#2383** | open2-fern | H-DT: RI capture_step LATER sweep (2500 vs 2600) | Assigned 15:50 UTC. Pure CLI, no code changes. Awaiting pickup (stale_wip). |
| **#2378** | open2-alphonse | H-DO: NC placement — NC-AFTER-NS5 | Arm A T0=3.276730 FALSIFIED (+0.000558). T1 in flight ETA ~17:45 UTC. |
| **#2377** | open2-edward | H-DN: Stack prune NC vs Amsgrad AdamW | Arm A n=2 mean 3.277118 FALSIFIED (variance gate triggered |T0−T1|=0.001365). Arm B (Amsgrad) `3xgawfqb` step 2150 ETA ~20:30 UTC. Final decision: bimodal seed pattern is the finding; close after Arm B. |
| **#2380** | open2-nezuko | H-DQ: Contra-Muon coeff sweep (0.1 vs 0.3) | Arm A `v089vh09` step ~2150/5780 (~37%). ETA T0 ~18:30 UTC. |

## Recent closures (most recent first)

| Date | PR | Hypothesis | Decision | Key finding |
|---|---|---|---|---|
| 2026-06-08 17:46 | **#2381 (askeladd H-DR)** | Soft-Muon CEIL sweep (0.1 vs 0.3) | **CLOSED 57TH LEVER** | Arm A n=2 mean 3.277078 FALSIFIED. High seed variance (T0=3.278059, T1=3.276096, |Δ|=0.001963 = 2.5× variance gate). Arm B skipped per gate. Soft-Muon CEIL axis closed. |
| 2026-06-08 16:55 | **#2376 (thorfinn H-DM)** | MUON_POWER_C sweep (0.66× vs 1.5×) | **CLOSED 56TH LEVER** | Arm A n=2 mean 3.277843 (+0.001671, variance-gate triggered T0=3.276145 lucky seed). Arm B 1.5× T0=3.286138 DEEP FALSIFIED. Hand-tune in narrow asymmetric basin. MUON_POWER_C axis FULLY closed. |
| 2026-06-08 14:30 | **#2375 (frieren H-DL)** | EN lookahead_stepsize sweep (0.15 vs 0.45) | **CLOSED 53RD LEVER** | Arm A (0.15) flat with baseline (−9e-6, within σ_pair). Arm B (0.45) FALSIFIED +0.002525. Default 0.30 at optimum; surface flat below 0.30, climbs sharply above. |
| 2026-06-08 13:55 | **#2374 (askeladd H-DK)** | ARBOR_CLAMP_K sweep (2.0 vs 5.0) | **CLOSED 52ND LEVER** | Asymmetric penalty: clamp=2.0 catastrophic +0.00274, clamp=5.0 marginal +0.000467. Default 3.0 at near-tight local optimum. Sinkhorn tolerant of loosening, sharply punished by over-clamping. |
| 2026-06-08 13:26 | **#2370 (nezuko H-DH)** | SWA-EMA on AdamW dense params | **CLOSED 51ST LEVER** | Both arms FALSIFIED. SWA adds +0.000125-0.000156 bias over raw: AdamW tail trajectory still directionally improving, not noise-dominated. Weight-space averaging axis fully closed. |
| 2026-06-08 12:50 | **#2371 (fern H-DI)** | SOAP_BETA2 sweep (0.95 vs 0.85) | **CLOSED 50TH LEVER** | Both arms FALSIFIED. Arm A (0.95) +0.001838, Arm B (0.85) +0.000676. 0.90 at local optimum for 2890-step schedule. |
| 2026-06-08 12:47 | **#2318 (alphonse H-V)** | RI γ ablation n=4 on stripped stack | **CLOSED 49TH LEVER** | n=4 mean=3.276460 FALSIFIED. n=2 sub-signal 3.275803 was variance artifact. γ=−0.075 confirmed optimal. |
| 2026-06-08 12:47 | **#2369 (edward H-CY)** | NorMuon-lite β₂ sweep (0.99 vs 0.95) | **CLOSED 48TH LEVER** | Both arms FALSIFIED. "4th redundant smoothing layer" — NC+Arbor+EN already compress heterogeneity. |
| 2026-06-08 10:30 | **#2372 (thorfinn H-DJ)** | Lookahead-on-Muon (k=5/α=0.5) | **CLOSED 47TH LEVER CATASTROPHIC** | T0=3.295566 (+0.019394, 50× FALSIFIED). Lookahead axis FULLY closed (both AdamW H-BU and Muon). |

## Saturated levers count: 57

Levers 38–57:
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
54. **SOAP Kronecker preconditioner MLP+V (H-DP)** — CATASTROPHIC abort at step 1000, +2.88 nats gap from baseline. Direct extension of public Prime Intellect "MLP+V SOAP" idea — failed empirically on top of our stack.
55. **EN rest_steps direction ablation 2400/2890 (H-CZ)** — Both arms FALSIFIED/INCONCLUSIVE. Arm A (rest=2400) FALSIFIED +0.001079; Arm B (rest=2890 never-disengage) INCONCLUSIVE +0.000204. Monotonically ordered but saturated, EN timing axis closed.
56. **MUON_POWER_C sweep 0.66×/1.5× (H-DM)** — Both arms FALSIFIED. Arm A n=2 mean 3.277843 (+0.001671, variance gate triggered, T0=3.276145 lucky seed). Arm B (1.5×) T0=3.286138 DEEP FALSIFIED (+0.009966). Hand-tune 3.317e-6 in narrow asymmetric basin, steeper above than below. Combined with H-DA (recalibration p=1.2 FALSIFIED) → MUON_POWER_C axis FULLY closed.
57. **Soft-Muon CEIL sweep 0.1/0.3 (H-DR)** — Arm A n=2 mean 3.277078 FALSIFIED. T0=3.278059 hard FALSE, T1=3.276096 above rank-1 but recoverable; gate-mandated n=4 deemed infeasible (would need T2+T3 mean ≤ rank-1, ~3σ implausible). Arm B (CEIL=0.3) skipped per gate. Soft-Muon disabled-by-default in code stays disabled; axis closed. KellerJordan PR #305 Soft-Muon does NOT transfer to our NC×Arbor×EN×RI×eps=1e-12 stack.

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

**Fresh research_agent output (RESEARCH_IDEAS_2026-06-08_18:00.md, generated at 57-lever plateau):**

Tier 1 (MERGE candidates with novel mechanisms):
1. **H-DX (MUD triangular whitening)** — replace NS5 polynomial with MUD Gram/Cholesky triangular solve. Per-step parity with NS5 on LM benchmarks per arxiv 2603.17970. Arm A direct swap, Arm B MUD + NC removed (tests NC redundancy under exact orthogonalization).
2. **H-DY (AdamW β₂ cosine schedule 0.999→0.99 over [0, 1800])** — distinct from H-DV β₁ schedule (in-flight). β₂ controls second-moment EMA horizon, untouched axis.

Tier 2 (qualitatively novel update rules):
3. **H-DZ (Lion for embed + lm_head dense params)** — sign-based update direction, qualitatively different from AdamW second-moment scaling. Respect lm_head LR ≥ 1/320 invariant.
4. **H-EA (Dual-buffer Muon: γ_fast=0.9 alongside EN γ=0.99, α=0.3 blend)** — second EMA buffer post-NS5, captures short-timescale signal EN filters out.

Tier 3 (low-risk diagnostic / readout):
5. **H-EB (RI γ linear ramp 0 → −0.075 over last 500 steps)** — gradual eval-only blend instead of step-function at terminal step.
6. **H-EC (NS5 spectral warm-start via power-iter EMA)** — replace Frobenius-proxy with EMA-stabilized spectral-norm scaling, better NS5 input conditioning.
7. **H-ED (IFNSO offline-optimized NS5 coefficients)** — replace (3.4445, −4.7750, 2.0315) with offline-search-optimized triple for our gradient distribution.

Tier 4 (high-risk, last resort):
8. **H-EE (Stochastic NS5 skip p=0.15)** — replace NS5 with identity pass 15% of steps. EN+RI interaction risk.

**Decision tree (full version in RESEARCH_IDEAS_2026-06-08_18:00.md):**
- H-DX MUD T0 ≤ 3.276172 → run Arm B (MUD + NC removed) for NC-redundancy test
- H-DY β₂ schedule T0 ≤ 3.276172 → combine with H-DV β₁ schedule (joint β₁+β₂ schedule)
- H-DX T0 > 3.277200 → DEEP FALSIFIED, MUD Gram conditioning fails on our gradients
- H-EE T0 > 3.277000 OR ri/loss divergence > +0.0006 → ABORT (EN+RI contamination)

**In-flight reservations (do not duplicate):**
H-DV (AdamW β₁), H-DU (NorMuon pre-NS5), H-DT (RI capture later), H-DS (arbor iters), H-DQ (Contra-Muon), H-DO (NC after NS5), H-DN (NC removed + Amsgrad), H-DW (Polyak-Ruppert weight avg).

## Disabled mechanisms still to probe

The current rank-1 code has two mechanisms fully disabled via zero coefficients:
- **Contra-Muon** (`CONTRA_MUON_COEFF=0.0`, line 61): in progress as H-DQ (nezuko PR #2380)
- **Soft-Muon** (`SOFT_MUON_CEIL=0.0`, line 65): in progress as H-DR (askeladd PR #2381)

Both were active in KellerJordan PR #305 baseline (Contra-Muon extended). Re-enabling either is a valid hypothesis satisfying the "optimizer-state mechanisms" directive.

## Standing directive (preserved verbatim)

> Do not spend the whole run on scalar hyperparameter tuning. Retune LR/WD/betas when needed to make a new mechanism fair, but bias toward optimizer-state mechanisms, preconditioners, schedule/readout ideas, pruning of complex stacks, and principled combinations of #1532/#1614 with public SOTA lineages.

Current wave satisfies directive: H-DN (NC pruning/ablation), H-DO (NC placement after NS5), H-DP (SOAP Kronecker preconditioner), H-DL (EN lookahead schedule), H-DM (MUON_POWER_C mechanism), H-DQ (Contra-Muon optimizer mechanism), H-DR (Soft-Muon NS5-variant mechanism), H-CZ (EN rest_steps schedule).
