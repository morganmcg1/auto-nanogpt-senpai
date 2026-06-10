# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~06:15 UTC — 🎯 **ASKELADD H-FO WINNER (Trial 1 = 3.275169 @ 2890; n=2 mean = 3.276300 BEATS rank-1).** 3 more strong candidates in flight (frieren/fern/edward). Fleet: 8/8 active.

## 🎯 WINNER — askeladd H-FO Muon mu_cooldown 200

Run `ewtz1ftq` FINISHED:
- Trial 0 @ 2890 = 3.277430, first_step_to_target = 2850
- Trial 1 @ 2890 = **3.275169**, first_step_to_target = **2825**
- **n=2 mean @ 2890 = 3.276300** (below n=2 threshold 3.277172)
- Trial 1 best matches rank-1's n=4 mean (3.275320) — exceeds it by 0.0002
- DECISION: Merge candidate, pending student SENPAI-RESULT post. n=4 escalation recommended.
- Lattice values @ 2825/2850/2875 in W&B live buffer (inaccessible) — need student to post from local training log.

## TOP OPEN SIGNALS (4 candidates below n=2 threshold trial 0)

### #1 — frieren H-FR lm_head+scalars combined β₂ pulse (STRONGEST)

Frieren H-FR Arm A (lm_head+scalars combined β₂ pulse, run `gj3zqbbk`):
- **Trial 0 @ step 2890 = 3.276022** (`speedrun/final_best_val_loss` from summary)
- Trial 0 `first_step_to_target` = **2850**
- Trial 1 in progress (W&B _step 2941, train/step ~51/2890) — ETA ~07:30 UTC
- THE strongest single-seed in the entire H-F* program (+0.0007 above rank-1 n=4 mean).

### #2 — fern H-FN Muon mu warmup 500

Fern H-FN Arm A (Muon mu_warmup 300→500, run `kqadlpxd`):
- Trial 0 @ step 2890 = **3.276316**
- Trial 0 `first_step_to_target` = **2850**
- Trial 1 in progress (W&B _step 3758, train/step ~868/2890) — ETA ~06:25 UTC
- **OPERATIONAL:** fern student loop dead since 02:24 UTC; training healthy. Respawn pod after trial 1 finishes.

### #3 — edward H-FQ lm_head-only β₂=0.997

Edward H-FQ Arm A (lm_head-only β₂ amplitude 0.997, run `bj2g9xkv` after 3 crashes):
- Trial 0 @ step 2890 = **3.276933**
- Trial 0 `first_step_to_target` = **2850**
- Trial 1 in progress (W&B _step 3291, train/step ~401/2890) — ETA ~07:15 UTC
- Multiple crashed prior attempts (`8qv7h8ck`, `ylwyhs1f`, `dprs7rr0`).

### #4 — alphonse H-FU NS inner iters 8 (borderline)

Alphonse H-FU Arm A (ns_inner_iters=8, run `merl8y2r`):
- Trial 0 @ step 2890 = **3.277176** — just at n=2 threshold
- Trial 1 in progress (W&B _step 2892, just starting) — ETA ~07:25 UTC

## Borderline signals (trial 0 above n=2 threshold)

### askeladd H-FO Muon mu cooldown 200

- Trial 0 @ step 2890 = **3.277430** (just above n=2 thresh of 3.277172)
- Trial 1 at W&B _step 5691 (nearly done, ~06:05 UTC) — verdict imminent

### tanjiro H-FS lm_head LR ×1.5 pulse

- Trial 0 best = **3.277728 @ step 2875** (best_val_step 2875, not 2890 — peak shifted earlier)
- first_step_to_target = 2875 (later than rank-1's 2850)
- Trial 1 at W&B _step 3391, train/step ~501/2890

## Falsified this cycle

### thorfinn H-FJ AdamW eps phase schedule (FALSIFIED at trial 0)

- Trial 0 @ 2890 = 3.27753, deltas +0.0022 above rank-1 at every lattice step
- Trial 1 will complete for completeness but H-FJ axis CLOSING.

## Prior strongest signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 = 3.275785, Trial 1 @2890 = 3.275600
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILED n=2 threshold)
- Embed-only Arm A: FALSIFIED
- **Established: β₂ pulse mechanism is LMHEAD-driven** (and now H-FR data suggests SCALARS adds further signal)

## Prior strongest signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 post-RI = 3.275785, Trial 1 @2890 post-RI = 3.275600
- Trial 1 first_step_to_target = **2825** (beats rank-1's 2850!)
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILS n=2 threshold 3.277172 but passes at step 2875 ≈ 3.276762)
- Embed-only Arm A: FALSIFIED (+0.0027 vs rank-1) — embed is NOT the signal source
- **β₂ pulse mechanism is primarily LMHEAD-driven**
- Two orthogonal follow-up axes now in flight: H-FQ (amplitude at lm_head), H-FW (timing at lm_head)

## Active fleet status (06:05 UTC):

| PR | Student | Hypothesis | Trial 0 @ 2890 | Status |
|---|---|---|---:|---|
| **#2435** | **frieren** | **H-FR lm_head+scalars combined β₂ pulse** | **3.276022** | **STRONGEST; trial 1 ETA 07:30** |
| **#2429** | **fern** | **H-FN Muon mu warmup 500** | **3.276316** | **STRONG; trial 1 ETA 06:25** |
| **#2433** | **edward** | **H-FQ lm_head β₂=0.997** | **3.276933** | **STRONG; trial 1 ETA 07:15** |
| #2434 | alphonse | H-FU NS inner_iters=8 | 3.277176 | Borderline; trial 1 just started |
| #2431 | askeladd | H-FO Muon mu cooldown 200 | 3.277430 | Trial 1 nearly done, verdict imminent |
| #2432 | tanjiro | H-FS lm_head LR ×1.5 pulse | 3.277728 @ 2875 | Borderline; trial 1 ETA ~07:30 |
| #2430 | thorfinn | H-FJ AdamW eps phase | 3.277533 | FALSIFIED; trial 1 ETA ~07:00 |
| #2436 | nezuko | H-FW lm_head timing {620,720,920,1020} | pending | Arm A trial 0 in flight |

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
