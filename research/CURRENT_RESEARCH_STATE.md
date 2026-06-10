# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~02:55 UTC — **H-FH CLOSED INCONCLUSIVE. H-FS (tanjiro, lm_head LR pulse) assigned. Alphonse 3rd nudge sent. KEY OPEN SIGNAL: lm_head-dominant β₂ pulse (alphonse H-FD Arm B). Fleet: 8/8 active.**

## Most important open signal: lm_head-dominant β₂ pulse (alphonse H-FD Arm B)

Alphonse H-FD Arm B (lm_head-only β₂ pulse, n=2 run `sfe2too3`):
- Trial 0 @2890 post-RI = 3.275785, Trial 1 @2890 post-RI = 3.275600
- Trial 1 first_step_to_target = **2825** (beats rank-1's 2850!)
- Estimated n=2 mean @2850 ≈ 3.278182 (FAILS n=2 threshold 3.277172 but passes at step 2875 ≈ 3.276762)
- Embed-only Arm A: FALSIFIED (+0.0027 vs rank-1) — embed is NOT the signal source
- **β₂ pulse mechanism is primarily LMHEAD-driven**
- Awaiting trial 1 lattice values from alphonse for official n=2 mean (3rd nudge sent)

## Active fleet status (02:55 UTC):

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#2432** | **tanjiro** | **H-FS lm_head LR ×1.5 pulse @ step 820 (100 steps)** | **Just assigned** |
| #2430 | thorfinn | H-FJ AdamW eps phase 1e-10→1e-12 by step 820 | Just assigned (no comments yet) |
| #2431 | askeladd | H-FO Muon mu cooldown extension 100→200/300 | Just assigned (no comments yet) |
| #2429 | fern | H-FN Muon mu warmup 300→500/1000 steps | Just assigned (no comments yet) |
| #2428 | nezuko | H-FG NS5 input whitening (QR blend) | Arm A done (3.2767, n=1); Arm B `n418fzzi` running |
| #2426 | tanjiro | H-FH adaptive CD t_end (**CLOSED**) | INCONCLUSIVE — slope-578 class exhausted |
| #2425 | frieren | H-FI EN γ anneal | Arm A FALSIFIED, Arm B trial 0 FALSIFIED; awaiting terminal |
| #2424 | edward | H-FF β₁×β₂ joint pulse | Arm A FALSIFIED; Arm B trial 1 at step ~1075/2890 |
| #2422 | alphonse | H-FD per-group β₂ pulse ablation | Arm B lm_head n=2 DONE; **awaiting terminal SENPAI-RESULT (URGENT)** |

## Closed this cycle:
- **H-FH (tanjiro #2426)**: INCONCLUSIVE-CLOSE — Path B (NEUTRAL, threshold=-0.0012) trivializes to rank-1 (no t_end mutation). Path A (STEEP, threshold=-0.001) misfires hurting +0.0037 @ step 2850. Bracket exhausted: slope-578 signal class closed for this stack.
- **H-FA (thorfinn #2419)**: INFERIOR — PEAK-AT-COOLDOWN β₂ staircase. β₂ trajectory axis FULLY CLOSED.
- **H-FK (askeladd #2427)**: FALSIFIED — Muon SWA monotone descent issue. SWA class closed.

## Completed ablations — β₂ trajectory axis (FULLY CLOSED):

| Arm | plateau β₂ | cooldown β₂ | earliest valid | n=4 μ @2850 | result |
|---|:---:|:---:|:---:|---:|---|
| **H-EJ rank-1** | **0.995** | **0.995** | **2850** | **3.277780** | **RANK-1 ✓** |
| H-EZ DESCENT | 0.995 | 0.99 | 2875 | 3.278239 | FALSIFIED |
| H-FA PEAK-CD | 0.99 | 0.995 | 2875 | 3.278357 | INFERIOR |
| H-FB ASCENT | 0.99→0.995 | 0.995 | 2875 | 3.278496 | FALSIFIED |

**Verdict: rank-1 abrupt single-pulse is mechanistically unique. β₂ trajectory axis CLOSED.**

## Mechanism portfolio coverage (as of 02:55 UTC):

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
| Adaptive CD t_end (slope-578) | INCONCLUSIVE | CLOSED — slope-578 class exhausted (H-FH) |
| **lm_head LR ×1.5 pulse @ 820** | **in flight (H-FS)** | **tanjiro just assigned** |

## Current highest-priority follow-ups (after alphonse confirms):

1. **H-FQ: lm_head-only β₂ amplitude sweep** — Try 0.997 and 0.999 for lm_head pulse (embed stays at default). If lm_head-dominant finding holds, amplitude may be tunable beyond rank-1's 0.995.
2. **H-FR: lm_head+scalars combined pulse** — Pulse both non-embed groups together. Tests whether embed is truly noise.
3. **H-FS: lm_head-specific LR boost at step 820** ← IN FLIGHT (tanjiro #2432) — Simultaneous to β₂ pulse, boost lm_head LR ×1.5 for 100 steps.

## Hypothesis queue:
- H-FM: Nesterov-RI pre-fetch last 150 steps (Tier 3, Lookahead-adjacent risk)
- H-FN: Muon mu warmup extension (fern, in flight)
- H-FJ: AdamW eps phase schedule (thorfinn, in flight)
- H-FO: Muon mu cooldown extension (askeladd, in flight)
- **H-FQ (HIGH VALUE pending alphonse)**: lm_head-only β₂ amplitude sweep 0.997/0.999
- **H-FR (pending alphonse)**: lm_head+scalars combined pulse
