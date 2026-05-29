# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 05:20 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## ⚠️ HOT WIN CANDIDATE — alphonse #1637 Arm A `ara5opnj`

**Pre-target body Muon LR boost ×1.25 during steps 2750-2900**: val_ema=3.262770, sr=2875. **Clause 2 PASS by 0.084 mnat** (sub-noise margin). Seed-2 required. Arm B (×1.5 boost) currently running (chain). When Arm B terminal → student posts combined SENPAI-RESULT → request seed-2 of the BETTER arm.

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1622 | edward | Muon momentum reset at pEMA refresh — scale=0.1 Arm B `veho0mwj` | Running (~step 2800) | ~06:00 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25 Arm A DONE, ×1.5 Arm B running) | **⚠️ HOT WIN Arm A** — Arm B chain running | ~08:00 UTC |
| #1639 | askeladd | Aux β₁ DROP pulse @ step 975 (0.70, 0.60) — Arm A `mqgtit8o` running | Running (~step 2375) | ~07:00 UTC |
| #1634 | nezuko | Aux β₂ smooth ramp (ramp_width=50 NULL; Arm B ramp_width=200 `yxediont` running) | Arm B running (~step 441) | ~08:00 UTC |
| #1646 | fern | Pre-target aux Adam LR boost (×1.25, ×1.5 @ steps 2750-2900) — Arm A `ffuy3nqy` | Running (~step 2125) | ~06:30 UTC |
| #1605 | frieren | β₂ timing step 1050 marginal WIN (−0.225 mnat); seed-2 `u4zmm04x` running | Seed-2 running (~step 2475) | ~06:00 UTC |
| #1648 | tanjiro | Per-group aux Adam β₂ pulse (embed-only vs non-embed) — Arm A `8jfrpc48` | Running (~step 1100) | ~10:00 UTC |
| #1660 | thorfinn | Pre-target NS coefficient pulse (conservative quintic vs Jordan-aggressive) | JUST ASSIGNED | ~12:00 UTC |

## Research portfolio focus

**TWO SUB-NOISE WIN CANDIDATES IN FLIGHT**
- frieren #1605 Arm B (step=1050): val_ema=3.262629 (−0.225 mnat). Seed-2 `u4zmm04x` ~06:00 UTC.
- alphonse #1637 Arm A (×1.25 body Muon LR boost): val_ema=3.262770 (−0.084 mnat). Combined SENPAI-RESULT pending Arm B.

**These two potential WINs are complementary, not redundant:**
- frieren: changes WHEN the canonical β₂ pulse fires (975 → 1050) — timing mechanism
- alphonse: boosts body Muon LR in pre-target window — magnitude mechanism
If both confirmed → STACK: step-1050 β₂ pulse + ×1.25 Muon LR boost. This would be the first compound WIN of the session.

**β₂ pulse mechanism mapping — COMPLETE**

| Axis | Status |
|---|---|
| Amplitude 0.99 (canonical) | ✅ WIN |
| Amplitude ≥0.995 | ❌ NULL (diminishing returns) |
| Amplitude ≤0.90 | ❌ NULL (monotone regression) |
| Timing step 975 (canonical) | ✅ WIN |
| Timing step 900 | ❌ NULL |
| Timing step 1050 | ⚠️ MARGINAL WIN (seed-2 confirming) |
| β₁ RAISE (0.90, 0.95) | ❌ NULL (moments asymmetry) |
| β₁ DROP (0.70, 0.60) | In-flight |
| Shape (discrete) | Canonical |
| Shape (ramp_width=50) | ❌ NULL |
| Shape (ramp_width=200) | In-flight |
| Per-group recipient | In-flight (tanjiro #1648) |

**Pre-target window mechanisms (steepen descent before step 2925)**
- alphonse #1637: body Muon LR boost ×1.25 ⚠️ HOT WIN
- fern #1646: aux Adam LR boost ×1.25/×1.5 — in-flight (~step 2125)
- thorfinn #1660: NS coefficient pulse — JUST ASSIGNED

**Phase-boundary state mechanisms**
- edward #1622: Muon momentum reset scale=0.1 — final arm running (~step 2800)
- AGC linear-decay: ❌ CLOSED bilateral (hard cutoff paradoxically better)

## Key closed findings (session)

- **#1607 tanjiro NULL (bilateral)**: β₂ amplitude axis FULLY CLOSED. 0.99 is the unique optimum.
- **#1621 thorfinn NULL (bilateral)**: AGC linear-decay closed. Hard cutoff is paradoxically better than smoothing; the discontinuity bump is local/recoverable.
- **#1604 fern NULL (bilateral)**: Body Muon momentum pulse fundamentally does not generalize from aux Adam. Optimizer-type AND moment-type specific.
- **#1592 askeladd NULL (bilateral RAISE)**: β₁ RAISE increases first-moment lag, β₁ axis DROP direction still open.
- **#1601 nezuko NULL (bilateral)**: v-buffer state-reset doesn't reproduce edward's pulse. Edward's mechanism is parametric-scheduling.
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude axis right-shoulder closed. 0.995, 0.999 both NULL.
