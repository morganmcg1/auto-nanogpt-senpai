# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~05:15 UTC — **STRONG NEW SIGNAL: fern H-FN Arm A trial 0 @ 2890 = 3.276316.** Awaiting trial 1 for n=2 verdict. Fleet: 8/8 active.

## TOP OPEN SIGNAL — fern H-FN Muon mu warmup 500 (trial 0 strong)

Fern H-FN Arm A (Muon mu_warmup 300→500, run `kqadlpxd`):
- Trial 0 @ step 2890 = **3.276316** (`speedrun/final_best_val_loss` from summary)
- Trial 0 `first_step_to_target` = **2850**
- Trial 1 in progress (train/step ~601/2890 at 05:12 UTC) — ETA ~06:25 UTC
- Decision: if n=2 mean @ 2850 ≤ 3.277172 → ESCALATE to n=4; if ≤ 3.278000 → INFORMATIVE
- **OPERATIONAL NOTE:** fern student loop dead since 02:24 UTC; training subprocess healthy. Will respawn pod after trial 1 finishes; may need advisor-side SENPAI-RESULT post.

## Second open signal — askeladd H-FO Muon mu cooldown 200 (borderline)

Askeladd H-FO Arm A (Muon mu_cooldown 100→200, run `ewtz1ftq`):
- Trial 0 @ step 2890 = **3.277430** (`speedrun/final_best_val_loss` from summary)
- Trial 0 `first_step_to_target` = **2850**
- Trial 1 in progress (train/step ~2251/2890) — ETA ~05:55 UTC
- Likely lands INFORMATIVE-NOT-MERGE; long-shot escalation if trial 1 outperforms trial 0.

## Prior strongest signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 post-RI = 3.275785, Trial 1 @2890 post-RI = 3.275600
- Trial 1 first_step_to_target = **2825** (beats rank-1's 2850!)
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILS n=2 threshold 3.277172 but passes at step 2875 ≈ 3.276762)
- Embed-only Arm A: FALSIFIED (+0.0027 vs rank-1) — embed is NOT the signal source
- **β₂ pulse mechanism is primarily LMHEAD-driven**
- Two orthogonal follow-up axes now in flight: H-FQ (amplitude at lm_head), H-FW (timing at lm_head)

## Active fleet status (05:15 UTC):

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#2429** | **fern** | **H-FN Muon mu warmup 500 (Arm A only)** | **TRIAL 0 STRONG (3.276316@2890); trial 1 in flight** |
| #2431 | askeladd | H-FO Muon mu cooldown 200 (Arm A) | TRIAL 0 borderline (3.277430@2890); trial 1 in flight |
| #2433 | edward | H-FQ lm_head-only β₂ amplitude sweep (Arm A 0.997 in flight, restart after `8qv7h8ck` crash → `bj2g9xkv` at step ~2100) | In flight |
| #2436 | nezuko | H-FW lm_head-only β₂ pulse STEP TIMING sweep {620,720,920,1020} | Arm A trial 1 ETA 06:09 UTC |
| #2435 | frieren | H-FR lm_head + scalars combined β₂ pulse (embed stays fixed) | Arm A in flight (`gj3zqbbk` step 1500) |
| #2434 | alphonse | H-FU Newton-Schulz inner iteration count sweep (8/16 vs 12) | Arm A in flight (`merl8y2r` step 1445, dup killed) |
| #2432 | tanjiro | H-FS lm_head AdamW LR ×1.5 pulse @ step 820 (100 steps) | Arm A in flight (`jtkqon4p` step 1950) |
| #2430 | thorfinn | H-FJ AdamW eps phase schedule 1e-10→1e-12 by step 820 | Arm A in flight (`0oy17382` step 2550) |

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
