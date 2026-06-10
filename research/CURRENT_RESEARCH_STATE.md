# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~04:35 UTC — **H-FG FALSIFIED/ABORT (#2428 closed). H-FW (nezuko, lm_head-only β₂ pulse step timing sweep) assigned (#2436). Fleet: 8/8 active.**

## Most important open signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 post-RI = 3.275785, Trial 1 @2890 post-RI = 3.275600
- Trial 1 first_step_to_target = **2825** (beats rank-1's 2850!)
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILS n=2 threshold 3.277172 but passes at step 2875 ≈ 3.276762)
- Embed-only Arm A: FALSIFIED (+0.0027 vs rank-1) — embed is NOT the signal source
- **β₂ pulse mechanism is primarily LMHEAD-driven**
- Two orthogonal follow-up axes now in flight: H-FQ (amplitude at lm_head), H-FW (timing at lm_head)

## Active fleet status (04:35 UTC):

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#2436** | **nezuko** | **H-FW lm_head-only β₂ pulse STEP TIMING sweep {620,720,920,1020}** | **Just assigned** |
| #2435 | frieren | H-FR lm_head + scalars combined β₂ pulse (embed stays fixed) | In flight |
| #2434 | alphonse | H-FU Newton-Schulz inner iteration count sweep (8/16 vs 12) | In flight |
| #2433 | edward | H-FQ lm_head-only β₂ amplitude sweep (0.997 / 0.999) | In flight |
| #2432 | tanjiro | H-FS lm_head AdamW LR ×1.5 pulse @ step 820 (100 steps) | In flight |
| #2431 | askeladd | H-FO Muon mu cooldown extension 100→200/300 | In flight |
| #2430 | thorfinn | H-FJ AdamW eps phase schedule 1e-10→1e-12 by step 820 | In flight |
| #2429 | fern | H-FN Muon mu warmup extension 300→500/1000 steps | In flight |

## Recently closed this cycle (03:00–04:35 UTC):

- **H-FG (nezuko #2428)**: FALSIFIED/ABORT — NS5 input whitening (QR blend). Arm B (α=0.6) n=1 @2890 = 3.28024 > 3.279000 ABORT gate; Arm A (α=0.3) n=1 @2890 = 3.27669 INCONCLUSIVE but monotone Δ widening. NC pre-step (per-row × per-col L2) already conditions NS5 input adequately; QR blend interferes with normalization. NS5 input whitening axis CLOSED.
- **H-FI (frieren #2425)**: FALSIFIED — EN γ anneal 0.99→0.97/0.90 through cooldown. Both arms ≈+0.002 vs rank-1 @2850. γ=0.99 constant is load-bearing; EN γ axis CLOSED.
- **H-FF (edward #2424)**: FALSIFIED — β₁×β₂ joint pulse. Arm A (β₁→0.85, lock-in): +0.001 vs rank-1. Arm B (β₁→0.70, forget): final trial +0.003 vs rank-1. β₁ pulse direction CLOSED.
- **H-FD (alphonse #2422)**: CLOSED KEY-INSIGHT — per-group β₂ localization. Arm B (lm_head-only) achieves trial 1 first_step=2825; Arm A (embed-only) FALSIFIED; Arm C (scalars-only) abandoned. **Embed is noise; lm_head is the signal source.**

## Closed earlier this cycle:
- **H-FH (tanjiro #2426)**: INCONCLUSIVE-CLOSE — slope-578 class exhausted (adaptive CD t_end misfires)
- **H-FA (thorfinn #2419)**: INFERIOR — PEAK-AT-COOLDOWN β₂ staircase
- **H-FK (askeladd #2427)**: FALSIFIED — Muon SWA monotone descent issue; SWA class CLOSED

## Completed ablations — β₂ trajectory axis (FULLY CLOSED):

| Arm | plateau β₂ | cooldown β₂ | earliest valid | n=4 μ @2850 | result |
|---|:---:|:---:|:---:|---:|---|
| **H-EJ rank-1** | **0.995** | **0.995** | **2850** | **3.277780** | **RANK-1 ✓** |
| H-EZ DESCENT | 0.995 | 0.99 | 2875 | 3.278239 | FALSIFIED |
| H-FA PEAK-CD | 0.99 | 0.995 | 2875 | 3.278357 | INFERIOR |
| H-FB ASCENT | 0.99→0.995 | 0.995 | 2875 | 3.278496 | FALSIFIED |

**Verdict: rank-1 abrupt single-pulse is mechanistically unique. β₂ trajectory axis CLOSED.**

## Mechanism portfolio coverage (as of 04:35 UTC):

| Mechanism class | Best result | Status |
|---|---|---|
| β₂ pulse amplitude (whole-optimizer) | 0.995 (H-EJ) | RANK-1 |
| β₂ pulse timing (whole-optimizer) | step 820 (H-EJ) | Closed (±50 step window) |
| β₂ trajectory shape | 4-cell ablation done | ALL FALSIFIED — single pulse optimal |
| Per-group β₂ localization | lm_head dominant | KEY INSIGHT (H-FD Arm B); scalars being tested (H-FR) |
| β₂ pulse amplitude (lm_head-only) | in flight (H-FQ) | edward testing 0.997 / 0.999 |
| **β₂ pulse timing (lm_head-only)** | **in flight (H-FW)** | **nezuko testing {620,720,920,1020}** |
| lm_head+scalars combined β₂ pulse | in flight (H-FR) | frieren #2435 |
| AMSGrad / v_hat monotonicity | both arms CATASTROPHIC | CLOSED — incompatible with pulse |
| EN γ anneal 0.99→0.97/0.90 | both arms +0.002 | FALSIFIED — γ=0.99 is load-bearing; EN γ axis CLOSED |
| β₁ lock-in 0.85 / forget 0.70 at pulse | both arms FALSIFIED | CLOSED — β₁ pulse direction CLOSED |
| NS5 input whitening (QR) | both arms FALSIFIED/ABORT | CLOSED — NC pre-step adequate; QR blend interferes |
| Muon SWA last 150 | +0.0014 vs live | FALSIFIED — monotone descent issue; SWA class CLOSED |
| Muon momentum warmup | in flight (H-FN) | fern #2429 |
| AdamW eps phase schedule | in flight (H-FJ) | thorfinn #2430 |
| Muon momentum cooldown | in flight (H-FO) | askeladd #2431 |
| Adaptive CD t_end (slope-578) | INCONCLUSIVE | CLOSED — slope-578 class exhausted |
| lm_head LR ×1.5 pulse @ 820 | in flight (H-FS) | tanjiro #2432 |
| Muon NS inner iteration sweep | in flight (H-FU) | alphonse #2434 |

## Current highest-priority follow-ups (pending in-flight results):

1. **H-FQ (edward, in flight)**: lm_head-only β₂ amplitude sweep 0.997/0.999 — if lm_head-dominant, amplitude may be tunable beyond 0.995.
2. **H-FW (nezuko, just assigned)**: lm_head-only β₂ timing sweep — orthogonal to H-FQ. Together H-FQ+H-FW form a 2D probe of the lm_head pulse manifold.
3. **H-FR (frieren, in flight)**: lm_head+scalars combined pulse — tests whether scalars contribute additively.
4. **H-FS (tanjiro, in flight)**: lm_head LR ×1.5 simultaneous with β₂ pulse — first LR-modulation test on lm_head.

## Hypothesis queue (not yet assigned):
- **H-FT**: lm_head-only β₂ pulse + LR combined sweep (follows after H-FQ + H-FS land)
- **H-FV**: Amplitude 0.997 specifically for lm_head+scalars group (follows after H-FR)
- H-FM: Nesterov-RI pre-fetch last 150 steps (Tier 3, Lookahead-adjacent risk)
- H-FL: NS5 coefficient distribution-specific fit (Tier 2, offline phase required)
