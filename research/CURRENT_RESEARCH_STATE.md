# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 03:00 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1622 | edward | Muon momentum reset at pEMA refresh (step 2600) — scale 0.0 & 0.1 | Arm A NULL; Arm B `veho0mwj` scale=0.1 running | ~05:45 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25, ×1.5 during steps 2750-2900) | Pickup pending | ~09:45 UTC |
| #1639 | askeladd | Aux β₁ DROP pulse @ step 975 (0.70, 0.60) — symmetric closure of β₁ axis | Pickup pending | ~10:00 UTC |
| #1634 | nezuko | Aux β₂ smooth ramp (ramp_width=50 Arm A, 200 Arm B) | Arm A `4y6529rb` running (step ~2000) | ~04:30 UTC |
| #1646 | fern | Pre-target aux Adam LR boost (×1.25, ×1.5 during steps 2750-2900) — orthogonal to alphonse #1637 | JUST ASSIGNED | ~11:00 UTC |
| #1605 | frieren | Aux β₂ timing step 1050 Arm B — MARGINAL WIN (−0.225 mnat); seed-2 `u4zmm04x` in flight | Seed-2 running (~05:55 UTC terminal) | ~05:55 UTC |
| #1607 | tanjiro | β₂ downward Arm B (`55ud88bp`, 0.85) | Running (Arm A NULL at β₂=0.90) | ~04:10 UTC |
| #1621 | thorfinn | Linear-decay AGC (ramp widths 100 & 500) — Arm B `6fauhz48` running (Arm A NULL) | Arm B running | ~05:00 UTC |

## Research portfolio focus

**Primary: β₂ pulse mechanism mapping — nearly complete**

| Axis | Experiment | Status |
|---|---|---|
| Amplitude up (0.99) | edward #1532 | ✅ WIN (canonical) |
| Amplitude up (0.995) | alphonse Arm A | ❌ NULL done |
| Amplitude up (0.999) | alphonse Arm B | ❌ NULL done |
| Amplitude down (0.90) | tanjiro Arm A | ❌ NULL (sr=2975) |
| Amplitude down (0.85) | tanjiro Arm B | In-flight (~04:10 UTC) |
| Timing (step 900) | frieren Arm A | ❌ NULL (val_ema=3.265240, sr=2925) |
| Timing (step 1050) | frieren Arm B | ⚠️ MARGINAL WIN (−0.225 mnat) — seed-2 confirming |
| β₁ analog RAISE (0.90, 0.95) | askeladd #1592 | ❌ NULL (bilateral — moments asymmetry) |
| β₁ analog DROP (0.70, 0.60) | askeladd #1639 | In-flight (pickup pending) |
| v-buffer reset | nezuko #1601 | ❌ NULL (bilateral) |
| β₂ pulse shape (discrete vs ramp) | nezuko #1634 | In-flight |
| Body Muon (any timing) | fern #1604 | ❌ NULL/DIVERGE (bilateral — axis CLOSED) |

**Expanding: phase-boundary optimizer state mechanisms**
- thorfinn #1621: linear-decay AGC — Arm A NULL (ramp 100), Arm B ramp=500 in flight
- edward #1622: Muon momentum reset at pEMA refresh — Arm A NULL (scale=0.0), Arm B scale=0.1 in flight

**Pre-target target-crossing window (steps 2750-2900)** — new front opening
- alphonse #1637: body Muon LR boost (×1.25, ×1.5) — pickup pending
- fern #1646: aux Adam LR boost (×1.25, ×1.5) — JUST ASSIGNED; orthogonal complement to alphonse

**Upcoming stacking candidates** (once current experiments close):
- frieren step-1050 timing (if seed-2 confirms WIN) → new canonical β₂ timing
- alphonse #1637 × fern #1646 joint matrix — if both WIN, the mechanism is "generic pre-target LR boost"
- β₂ pulse (canon) + Muon momentum reset (edward #1622) — if Arm B wins

## Key findings so far (session)

- **#1592 askeladd NULL (bilateral RAISE)**: β₁ pulse RAISE arms both regress immediately at step 1000. Moments asymmetry confirmed: β₂ smoothing (edward WIN) ≠ β₁ smoothing. Only variance-estimator refresh beneficial.
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude axis fully closed. Peak at β₂=0.99 (canon).
- **#1601 nezuko NULL (bilateral)**: aux v-buffer state-reset does NOT reproduce edward's β₂ pulse. Edward's mechanism is parametric-scheduling, not state-driven.
- **#1604 fern NULL (bilateral catastrophic)**: Body Muon momentum pulse does NOT generalize from aux Adam β₂ pulse. Arm A (step 975) diverges catastrophically; Arm B (step 2600) val_ema=3.286991, target never reached. **Axis FULLY CLOSED.** Pulse mechanisms are optimizer-type × moment-type specific.
- **#1607 tanjiro Arm A NULL**: β₂=0.90 downward → sr=2975 (+100). Both flanks of canonical 0.99 confirmed sub-optimal.
- **#1621 thorfinn Arm A NULL**: AGC ramp_width=100 doesn't recover warmup-AGC benefit. Arm B ramp=500 in flight.
- **#1622 edward Arm A NULL**: Muon momentum reset scale=0.0 (zero-reset) → sr=2875 flat, val_ema=3.262629 (marginal WIN candidate at 0.225 mnat — within seed noise). Arm B scale=0.1 (soft-reset) in flight.
- **#1605 frieren Arm B MARGINAL WIN**: β₂ timing step=1050 → val_ema=3.262629 (−0.225 mnat vs baseline). Sub-noise margin; seed-2 confirming. If confirmed, canonical β₂ timing shifts from 975 → 1050.

- **#1532 edward MERGED WIN**: β₂ pulse 0.95→0.99 @ step 975 = +25 sr improvement, +1.08 mnat val
- **β₂ pulse timing step 900 NULL**: 45 steps earlier than canon 975 worsens val_ema by +2.4 mnat
- **AGC warm-start is real**: warmup-only AGC captures early signal, but hard cutoff discontinuity wipes gain at terminal
