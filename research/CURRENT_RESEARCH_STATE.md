# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-28 21:40 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1622 | edward | Muon momentum reset at pEMA refresh (step 2600) — scale 0.0 & 0.1 | JUST ASSIGNED | ~05:30 UTC |
| #1591 | alphonse | β₂ amplitude Arm B (β₂=0.999, `8sgxkbc6`) | Running step 850; needs_rebase after terminal | ~01:00 UTC |
| #1592 | askeladd | β₁ pulse Arm B (`0xfh1ftf`) | Running step 575 | ~02:00 UTC |
| #1601 | nezuko | Aux v-buffer mean-reset (`9lwnf7km`) | Running step 1425 | ~23:40 UTC |
| #1604 | fern | Body Muon momentum pulse Arm A (`ingv7i6m`) | **DIVERGING** (val_ema=4.663 @ step 2300) — told to KILL; Arm B (step 2600) will chain | ~04:00 UTC (Arm B) |
| #1605 | frieren | Aux β₂ timing step 900 Arm A (`el59buaq`) | Running step 2425, approaching terminal | ~22:45 UTC |
| #1607 | tanjiro | β₂ downward Arm A (`k56llb0t`, 0.90) | Running step 1850 | ~00:30 UTC |
| #1621 | thorfinn | Linear-decay AGC (ramp widths 100 & 500) | Pick-up pending | ~07:30 UTC |

## Research portfolio focus

**Primary: β₂ pulse mechanism mapping — nearly complete**

| Axis | Experiment | Status |
|---|---|---|
| Amplitude up (0.99) | edward #1532 | ✅ WIN (canonical) |
| Amplitude up (0.995) | alphonse Arm A | ❌ NULL done |
| Amplitude up (0.999) | alphonse Arm B | In-flight |
| Amplitude down (0.90) | tanjiro Arm A | In-flight |
| Amplitude down (0.85) | tanjiro Arm B | Chained after Arm A |
| Timing (step 900) | frieren Arm A | ~22:45 UTC terminal |
| Timing (step 1050) | frieren Arm B | Chained after Arm A |
| β₁ analog | askeladd Arm A | ❌ NULL (val=3.2683) |
| β₁ analog Arm B | askeladd Arm B | In-flight |
| v-buffer reset | nezuko | In-flight |
| Body Muon (step 975) | fern Arm A | ❌ DIVERGED (catastrophic) |
| Body Muon (step 2600) | fern Arm B | Pending after kill |

**Expanding: phase-boundary optimizer state mechanisms**
- thorfinn #1621: linear-decay AGC — tests whether smooth AGC cutoff recovers warm-start (mechanism-driven follow-up from #1573 NULL)
- edward #1622: Muon momentum reset at pEMA refresh — stale momentum after param jump hypothesis

**Upcoming stacking candidates** (once current experiments close):
- β₂ pulse (canon) + Muon momentum reset (edward #1622) — if wins, stack it
- β₂ pulse (canon) + linear-decay AGC (thorfinn #1621) — if wins, stack it

## Key findings so far (session)

- **#1532 edward MERGED WIN**: β₂ pulse 0.95→0.99 @ step 975 = +25 sr improvement, +1.08 mnat val
- **β₁ pulse NULL**: β₁ analog of β₂ pulse doesn't generalize (askeladd Arm A)
- **Body Muon momentum pulse DIVERGES**: body optimizer not tolerant of momentum `mu` pulse at step 975 — fundamentally different from aux Adam
- **AGC warm-start is real**: warmup-only AGC captures early signal (~28 mnat at step 125), but hard cutoff discontinuity wipes the gain at terminal. Linear-decay follow-up in flight.
- **β₂=0.995 NULL**: monotone diminishing returns — 0.99 is near-optimal, higher doesn't help
