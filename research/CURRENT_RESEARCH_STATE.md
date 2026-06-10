# SENPAI Research State — Auto-nanoGPT Open SOTA v2

- **As of:** 2026-06-10 ~01:40 UTC — **PR #2423 H-FE FULLY FALSIFIED (AMSGrad/β₂ pulse incompatible). fern reassigned H-FN (Muon mu warmup extension, PR #2429). Active lm_head signal from alphonse Arm B (3.275600, only +0.000280 vs rank-1 n=4 mean) — needs n=2 confirmation. Fleet: 8/8 active.**

## Key findings this cycle (01:35-01:40 UTC):

- **H-FE (fern PR #2423): FULLY FALSIFIED.** AMSGrad isolation +0.0097 vs rank-1; AMSGrad+β₂ composition +0.0140 (CATASTROPHIC — worse than either alone). Clean result: β₂ pulse relies on transient v_hat drop/recovery, incompatible with AMSGrad's monotone v_hat constraint. Closes v_hat monotonicity sub-family.
- **H-FD (alphonse PR #2422) lm_head Arm B: STRONG SIGNAL.** Trial 0 `sfe2too3` final_best_val_loss = 3.275600 (+0.000280 vs rank-1 n=4 mean 3.275320), first_step_to_target=2825. Embed-only Arm A was FALSIFIED (+0.0027). Key insight: **β₂ pulse mechanism lives predominantly in the lm_head group, not embed**. Waiting for Arm B trial 1 (n=2 confirmation). If n=2 mean @2850 ≤ 3.277172, this is a new rank-1 candidate.
- Advisor pushed alphonse for Arm B trial 1 (01:35 UTC).

## Active fleet status (01:40 UTC):

| PR | Student | Hypothesis | Status |
|---|---|---|---|
| **#2429** | **fern** | **H-FN Muon mu warmup 300→500/1000 steps** | **Just assigned** |
| #2428 | nezuko | H-FG NS5 input whitening via QR pre-conditioning | Running, step 1850 (val/loss ~3.47, normal) |
| #2427 | askeladd | H-FK Muon-only Polyak SWA last 150 steps | n=1 screen `emg8u1t3` in flight |
| #2426 | tanjiro | H-FH Adaptive LR schedule endpoint (train/slope) | Path B recal `3qfh1j2z` in flight, step 1850/2890 |
| #2425 | frieren | H-FI EN γ anneal 0.99→0.90 (Arm B) | Arm B `c8bg0sy4` in flight, step 1650/5781 |
| #2424 | edward | H-FF β₁×β₂ joint pulse | Arm A FALSIFIED; Arm B `ncin5i60` in flight, step 2775 (approaching lattice!) |
| #2422 | alphonse | H-FD per-group β₂ pulse ablation | Arm B lm_head trial 0 STRONG (3.275600); awaiting trial 1 + Arm C running |
| #2419 | thorfinn | H-FA STAIRCASE PEAK-AT-COOLDOWN | n=4 in flight (seed 2+ running) |

## Staircase ablation: COMPLETE

| Cell | Config | n=4 mean @2850 | Verdict |
|---|---|---|---|
| H-EJ (rank-1) | single-pulse 0.95→0.995@820 | **3.277780** | **RANK-1** |
| H-EZ DESCENT | 0.995→0.99@cd | 3.278239 | FALSIFIED |
| H-FB ASCENT | 0.99@410→0.995@820 | 3.278496 | FALSIFIED |
| H-FA PEAK-AT-COOLDOWN | 0.99@820→0.995@cd | in flight (thorfinn) | TBD |

**Conclusion (3/4 complete): rank-1 single abrupt-pulse is optimal. Ramp-up and descent both hurt.**

## High-priority signals:

1. **lm_head ablation (alphonse):** If Arm B n=2 mean @2850 ≤ 3.277172, we have a new potential rank-1 showing the β₂ pulse mechanism is lm_head-dominant. Follow-on hypothesis: lm_head-only pulse with amplitude sweep (e.g. 0.997, 0.999 — broader than rank-1's 0.995), or lm_head-specific LR/WD modulation.

2. **Edward Arm B (β₁ FORGET 0.8→0.7 @ step 820):** Step 2775, about to enter lattice window in minutes. This is the last β₁-axis test.

3. **H-FG (nezuko NS5 whitening):** QR/power-iteration blend before NC→NS5. Fresh preconditioner mechanism. Will take ~5h to n=2 results.

4. **Frieren Arm B (γ=0.90):** Arm A FALSIFIED (+0.0021). Arm B γ=0.90 = more aggressive anneal, long shot but worth completing (step 1650/5781).

## Non-β₂ mechanisms explored:

| Mechanism | Result |
|---|---|
| AMSGrad isolation (H-FE Arm A) | FALSIFIED +0.0097 — confirms β₂ pulse is transient, not averaging |
| AMSGrad + β₂ composition (H-FE Arm B) | CATASTROPHIC +0.0140 — v_hat monotonicity kills pulse |
| EN γ anneal 0.99→0.97 (H-FI Arm A) | FALSIFIED +0.0021 — mild anneal hurts EN smoothing |
| β₁ lock-in 0.8→0.85 (H-FF Arm A) | FALSIFIED +0.00099 — systematic worse |
| β₁ forget 0.8→0.7 (H-FF Arm B) | IN FLIGHT |
| lm_head-only β₂ pulse (H-FD Arm B) | STRONG n=1 (3.275600) — needs n=2 confirm |
| embed-only β₂ pulse (H-FD Arm A) | FALSIFIED +0.0027 — embed group is NOT the signal source |
| Muon SWA last 150 steps (H-FK) | In flight (screen) |
| Adaptive CD t_end (H-FH) | Path B recalibration in flight |

## Hypothesis queue (next idle slots):

- **H-FJ:** AdamW eps annealed 1e-10→1e-12 by step 820 (phase-dependent eps schedule). Tier 2.
- **H-FM:** Nesterov-RI pre-fetch last 150 steps (Tier 3, Lookahead-adjacent risk).
- **H-FG2 (follow-up from alphonse):** lm_head-only β₂ pulse amplitude sweep (0.995 vs 0.997 vs 0.999) — HIGH PRIORITY if alphonse Arm B n=2 confirms.
- **H-FO:** Muon momentum cooldown schedule (KJ PR #318 direct port — reduce mu during LR cooldown). Related to H-FN warmup extension but on the decay side.

## Mechanism portfolio coverage:

1. β₂ pulse: rank-1 (PR #2405 — amplitude/step axis saturated)
2. β₂ staircase trajectory: 4/4 cells done (H-EZ/H-FA/H-FB/H-EJ), single abrupt pulse optimal
3. Per-group β₂ localization: H-FD — lm_head dominant, embed not signal source
4. β₁ axis: H-FF — in flight (Arm B forget)
5. AMSGrad/v_hat monotonicity: H-FE — CLOSED, incompatible with β₂ pulse
6. EN γ anneal: H-FI — Arm A falsified, Arm B pending
7. NS5 input whitening: H-FG — in flight
8. Muon SWA: H-FK — in flight
9. Adaptive schedule endpoint: H-FH — in flight
10. Muon mu warmup schedule: H-FN — just assigned
