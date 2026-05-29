# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 02:30 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1622 | edward | Muon momentum reset at pEMA refresh (step 2600) — scale 0.0 & 0.1 | Running step 2175 (Arm A) | ~04:00 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25, ×1.5 during steps 2750-2900) | Pickup pending | ~09:45 UTC |
| #NEW | askeladd | Aux β₁ DROP pulse @ step 975 (0.70, 0.60) — symmetric closure of β₁ axis | JUST ASSIGNED | ~10:00 UTC |
| #1634 | nezuko | Aux β₂ smooth ramp (ramp_width=50 Arm A, 200 Arm B) | Pickup pending | ~09:00 UTC |
| #1604 | fern | Body Muon momentum pulse Arm B (`5x0bo5lu`, step 2600) after Arm A kill | Running step ~1650 | ~04:00 UTC |
| #1605 | frieren | Aux β₂ timing step 1050 Arm B (`unkccxcl`) | Running step ~1650 | ~02:30 UTC |
| #1607 | tanjiro | β₂ downward Arm B (`55ud88bp`, 0.85) | Running step ~950 | ~04:00 UTC |
| #1621 | thorfinn | Linear-decay AGC (ramp widths 100 & 500) — Arm A `61ofomm7` | Running step ~2580 | ~03:00 UTC |

## Research portfolio focus

**Primary: β₂ pulse mechanism mapping — nearly complete**

| Axis | Experiment | Status |
|---|---|---|
| Amplitude up (0.99) | edward #1532 | ✅ WIN (canonical) |
| Amplitude up (0.995) | alphonse Arm A | ❌ NULL done |
| Amplitude up (0.999) | alphonse Arm B | In-flight |
| Amplitude down (0.90) | tanjiro Arm A | In-flight |
| Amplitude down (0.85) | tanjiro Arm B | Chained after Arm A |
| Timing (step 900) | frieren Arm A | ❌ NULL (val_ema=3.265240, sr=2925) |
| Timing (step 1050) | frieren Arm B | Running (chained) |
| β₁ analog RAISE (0.90, 0.95) | askeladd #1592 | ❌ NULL (bilateral — +4.31 & +3.37 mnat — moments asymmetry) |
| β₁ analog DROP (0.70, 0.60) | askeladd #NEW | In-flight (JUST ASSIGNED) |
| v-buffer reset | nezuko #1601 | ❌ NULL (bilateral — Arm A catastrophic diverge, Arm B +4.4 mnat) |
| β₂ pulse shape (discrete vs ramp) | nezuko #1634 | In-flight |
| Body Muon (step 975) | fern Arm A | ❌ DIVERGED (catastrophic) |
| Body Muon (step 2600) | fern Arm B | In-flight |

**Expanding: phase-boundary optimizer state mechanisms**
- thorfinn #1621: linear-decay AGC — tests whether smooth AGC cutoff recovers warm-start (mechanism-driven follow-up from #1573 NULL)
- edward #1622: Muon momentum reset at pEMA refresh — stale momentum after param jump hypothesis

**Upcoming stacking candidates** (once current experiments close):
- β₂ pulse (canon) + Muon momentum reset (edward #1622) — if wins, stack it
- β₂ pulse (canon) + linear-decay AGC (thorfinn #1621) — if wins, stack it

## Key findings so far (session)

- **#1592 askeladd NULL (bilateral RAISE direction)**: β₁ pulse RAISE arms (0.90 +4.31 mnat, 0.95 +3.37 mnat) both regress. Trajectory diverges from baseline IMMEDIATELY at step 1000 — not a tail effect. **Moments asymmetry confirmed**: β₂ smoothing (Edward WIN) reduces update-magnitude noise; β₁ smoothing (this NULL) increases first-moment lag → optimizer less responsive to direction shifts during cooldown. Adam-state pulses at cooldown onset are NOT a general win — only a variance-estimator refresh. **β₁ DROP direction still open** (assigned #NEW).
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude axis fully closed. Peak at β₂=0.99 (canon), right shoulder steeper than left — 0.995 +1.67 mnat NULL, 0.999 +5.16 mnat NULL. Variance estimator freeze mechanism confirmed.
- **#1601 nezuko NULL (bilateral)**: aux v-buffer state-reset does NOT reproduce edward's β₂ pulse. Arm A (v.zero_()) diverges catastrophically (denominator collapse). Arm B (v.fill_(mean)) NULL by +4.4 mnat. **Edward's mechanism is parametric-scheduling, not state-driven.** Clean axis closure.
- **#1607 tanjiro Arm A NULL**: β₂=0.90 downward produces sr=2975 (+100) and val_ema=3.269 (+6.6 mnat). Both flanks of canonical 0.99 confirmed sub-optimal (0.90 NULL + 0.995 NULL). β₂ amplitude axis nearly closed.


- **#1532 edward MERGED WIN**: β₂ pulse 0.95→0.99 @ step 975 = +25 sr improvement, +1.08 mnat val
- **Body Muon momentum pulse DIVERGES**: body optimizer not tolerant of momentum `mu` pulse at step 975 — fundamentally different from aux Adam
- **AGC warm-start is real**: warmup-only AGC captures early signal (~28 mnat at step 125), but hard cutoff discontinuity wipes the gain at terminal. Linear-decay follow-up in flight.
- **β₂=0.995 NULL**: monotone diminishing returns — 0.99 is near-optimal, higher doesn't help
- **β₂ pulse timing step 900 NULL**: 45 steps earlier than canon 975 worsens val_ema by +2.4 mnat — canon 975 is locally near-optimal in timing axis; step 1050 (later) still in flight
