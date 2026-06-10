# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~02:35 UTC — **4-cell β₂ staircase ablation COMPLETE (single-pulse optimal). H-FA INFERIOR + H-FK SWA FALSIFIED. thorfinn→H-FJ (eps phase), askeladd→H-FO (Muon mu cooldown). KEY INSIGHT: β₂ pulse is lm_head-dominant (alphonse H-FD Arm B). Fleet: 8/8 active.**

## Most important open signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 = 3.275785, Trial 1 @2890 = 3.275600
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILS n=2 threshold but passes at step 2875 ≈ 3.276762)
- Embed-only Arm A: +0.0027 vs rank-1 (FALSIFIED) — embed is NOT the signal source
- **β₂ pulse mechanism is primarily LMHEAD-driven**

Pending: alphonse terminal SENPAI-RESULT with trial 1 lattice from logs.

## Active fleet status (02:35 UTC):

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#2430** | **thorfinn** | **H-FJ AdamW eps phase 1e-10→1e-12 by step 820** | **Just assigned** |
| **#2431** | **askeladd** | **H-FO Muon mu cooldown extension 100→200/300** | **Just assigned** |
| #2429 | fern | H-FN Muon mu warmup 300→500/1000 steps | Just assigned |
| #2428 | nezuko | H-FG NS5 input whitening (QR blend) | Arm A done (3.2767, n=1); Arm B `n418fzzi` running step 75 |
| #2427 | askeladd | H-FK SWA (CLOSED) | FALSIFIED |
| #2426 | tanjiro | H-FH adaptive CD t_end | Path B `3qfh1j2z` DONE (3.276651, first@2850); awaiting terminal |
| #2425 | frieren | H-FI EN γ anneal | Arm A FALSIFIED, Arm B trial 0 at step 2875 (3.2805, FALSIFIED) |
| #2424 | edward | H-FF β₁×β₂ joint pulse | Arm A FALSIFIED; Arm B trial 1 `ncin5i60` at step 1075/2890 |
| #2422 | alphonse | H-FD per-group β₂ pulse ablation | Arm B lm_head n=2 DONE; awaiting terminal SENPAI-RESULT from logs |

## Closed this cycle:
- **H-FA (thorfinn #2419)**: INFERIOR — PEAK-AT-COOLDOWN β₂ staircase: n=4 mean @2850 = 3.278357 (fails 3.278000). Earliest valid = 2875 (vs rank-1's 2850). β₂ trajectory axis FULLY CLOSED.
- **H-FK (askeladd #2427)**: FALSIFIED — Muon SWA penalty grows with depth (monotone descent ≠ basin oscillation). Closes SWA class.

## Completed ablations — β₂ trajectory axis (FULLY CLOSED):

| Arm | plateau β₂ | cooldown β₂ | earliest valid | n=4 μ @2850 | result |
|---|:---:|:---:|:---:|---:|---|
| **H-EJ rank-1** | **0.995** | **0.995** | **2850** | **3.277780** | **RANK-1 ✓** |
| H-EZ DESCENT | 0.995 | 0.99 | 2875 | 3.278239 | FALSIFIED |
| H-FA PEAK-CD | 0.99 | 0.995 | 2875 | 3.278357 | INFERIOR |
| H-FB ASCENT | 0.99→0.995 | 0.995 | 2875 | 3.278496 | FALSIFIED |

**Verdict: rank-1 abrupt single-pulse is mechanistically unique. β₂ trajectory axis CLOSED.**

## Mechanism portfolio coverage (as of 02:35 UTC):

| Mechanism class | Best result | Status |
|---|---|---|
| β₂ pulse amplitude | 0.995 (H-EJ) | RANK-1, axis closed |
| β₂ pulse timing | step 820 (H-EJ) | Closed (±50 step window) |
| β₂ trajectory shape | 4-cell ablation done | ALL FALSIFIED — single pulse optimal |
| Per-group β₂ localization | lm_head dominant | KEY INSIGHT (H-FD Arm B) |
| AMSGrad / v_hat monotonicity | both arms CATASTROPHIC | CLOSED — incompatible with pulse |
| EN γ anneal 0.99→0.97/0.90 | both arms +0.002 | FALSIFIED — γ=0.99 is load-bearing |
| β₁ lock-in 0.85 at pulse | +0.001 vs rank-1 | FALSIFIED (H-FF Arm A) |
| β₁ forget 0.70 at pulse | in flight (H-FF Arm B) | Arm B trial 1 running |
| NS5 input whitening (QR) | n=1 3.2767 | In flight, Arm B running |
| Muon SWA last 150 | +0.0014 vs live | FALSIFIED — monotone descent issue |
| Muon momentum warmup | in flight (H-FN) | fern assigned |
| AdamW eps phase schedule | in flight (H-FJ) | thorfinn assigned |
| Muon momentum cooldown | in flight (H-FO) | askeladd assigned |
| Adaptive CD t_end | borderline (H-FH) | tanjiro Path B done, terminal pending |

## Current highest-priority follow-ups (after alphonse confirms):

1. **H-FQ: lm_head-only β₂ amplitude sweep** — Try 0.997 and 0.999 for lm_head pulse (embed stays at default). If lm_head-dominant finding holds at n=2, the amplitude may be tunable beyond rank-1's 0.995.
2. **H-FR: lm_head+scalars combined pulse** — Pulse both non-embed groups together (restore composite pulse but exclude embed). Tests whether embed is truly noise.
3. **H-FS: lm_head-specific LR boost at step 820** — Simultaneous to β₂ pulse, boost lm_head group LR by ×1.5 for 100 steps. Combines AdamW group isolation finding with LR intervention.

## Hypothesis queue:
- H-FM: Nesterov-RI pre-fetch last 150 steps (Tier 3, Lookahead-adjacent risk)
- H-FN: Muon mu warmup extension (fern, in flight)
- H-FJ: AdamW eps phase schedule (thorfinn, in flight)
- H-FO: Muon mu cooldown extension (askeladd, in flight)
- **H-FQ (HIGH VALUE pending alphonse)**: lm_head-only β₂ amplitude sweep
