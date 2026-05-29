# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 06:15 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## ⚠️ HOT WIN CANDIDATE — alphonse #1637 Arm A `ara5opnj`

**Pre-target body Muon LR boost ×1.25 during steps 2750-2900**: val_ema=3.262770, sr=2875. **Clause 2 PASS by 0.084 mnat** (sub-noise margin). Arm B (×1.5 boost) `gz7shnqe` currently running (~step 2725, just entering boost window). When Arm B terminal → post combined SENPAI-RESULT → request seed-2 of BETTER arm.

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1666 | edward | Body Muon `beta_cov` pulse 0.95→0.99 @ step 975/2600 | JUST ASSIGNED | ~14:00 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25 Arm A DONE, ×1.5 Arm B running) | **⚠️ HOT WIN Arm A** — Arm B running (~step 2725) | ~10:00 UTC |
| #1639 | askeladd | Aux β₁ DROP pulse @ step 975 (0.70, 0.60) — Arm A `mqgtit8o` running | Running | ~07:00 UTC |
| #1634 | nezuko | Aux β₂ smooth ramp (ramp_width=50 NULL; Arm B ramp_width=200 `yxediont` running) | Arm B running | ~08:00 UTC |
| #1646 | fern | Pre-target aux Adam LR boost (×1.25, ×1.5 @ steps 2750-2900) — Arm A `ffuy3nqy` | Running | ~06:30 UTC |
| #1667 | frieren | Pre-target aux β₂ transient spike (0.99→0.995/0.999 @ 2750-2900, revert after) | JUST ASSIGNED | ~14:00 UTC |
| #1648 | tanjiro | Per-group aux Adam β₂ pulse (embed-only vs non-embed) — Arm A `8jfrpc48` | Running | ~10:00 UTC |
| #1660 | thorfinn | Pre-target NS coefficient pulse (conservative quintic vs Jordan-aggressive) | Running | ~12:00 UTC |

## Research portfolio focus

**ONE ACTIVE HOT WIN CANDIDATE**
- alphonse #1637 Arm A (×1.25 body Muon LR boost): val_ema=3.262770 (−0.084 mnat). Arm B completing. Seed-2 pending best arm.

**β₂ pulse mechanism mapping — COMPLETE**

| Axis | Status |
|---|---|
| Amplitude 0.99 (canonical) | ✅ WIN |
| Amplitude ≥0.995 (permanent) | ❌ NULL (diminishing returns) |
| Amplitude ≤0.90 (permanent) | ❌ NULL (monotone regression) |
| Timing step 975 (canonical) | ✅ WIN |
| Timing step 900 | ❌ NULL |
| Timing step 1050 | ❌ NULL (seed-2 rejected) |
| β₁ RAISE (0.90, 0.95) | ❌ NULL (moments asymmetry) |
| β₁ DROP (0.70, 0.60) | In-flight (askeladd #1639) |
| Shape (discrete) | Canonical |
| Shape (ramp_width=50) | ❌ NULL |
| Shape (ramp_width=200) | In-flight (nezuko #1634) |
| Per-group recipient | In-flight (tanjiro #1648) |
| Pre-target transient spike 0.995/0.999 | In-flight (frieren #1667) |

**Pre-target window mechanisms (steepen descent before step 2925)**
- alphonse #1637: body Muon LR boost ×1.25 ⚠️ HOT WIN
- fern #1646: aux Adam LR boost ×1.25/×1.5 — in-flight
- thorfinn #1660: NS coefficient pulse — running
- frieren #1667: aux β₂ transient spike — JUST ASSIGNED (aux-side precision complement)

**Cross-optimizer / cross-moment-type matrix**

| Optimizer / moment | Step 975 | Step 2600 |
|---|---|---|
| Aux Adam β₂ (2nd moment) | ✅ WIN canonical #1532 | not tested |
| Aux Adam β₁ (1st moment) | ❌ NULL bilateral (#1592) | not tested |
| Body Muon μ (1st moment) | ❌ NULL (fern #1604) | ❌ NULL (fern #1604) |
| Body Muon `beta_cov` (2nd moment) | In-flight (edward #1666 Arm A) | In-flight (edward #1666 Arm B) |
| Body Muon momentum reset | n/a | ❌ NULL bilateral (edward #1622) |

**Phase-boundary state mechanisms**
- edward #1666: Muon `beta_cov` pulse — JUST ASSIGNED (completing 2nd-moment cross-optimizer matrix)
- AGC linear-decay: ❌ CLOSED bilateral (hard cutoff paradoxically better)

## Key closed findings (session)

- **#1622 edward NULL (bilateral)**: Body Muon momentum reset/damp at pEMA refresh. Momentum is load-bearing, not stale (iterate not relocated by `--paramema_refresh_only`).
- **#1605 frieren NULL (seed-2)**: β₂ timing step 1050 marginal WIN not confirmed. Timing axis fully closed; step 975 is robust optimal.
- **#1607 tanjiro NULL (bilateral)**: β₂ amplitude axis FULLY CLOSED. 0.99 is the unique optimum.
- **#1621 thorfinn NULL (bilateral)**: AGC linear-decay closed. Hard cutoff is paradoxically optimal.
- **#1604 fern NULL (bilateral)**: Body Muon momentum pulse fundamentally does not generalize from aux Adam. Moment-type AND optimizer-type specific.
- **#1592 askeladd NULL (bilateral RAISE)**: β₁ RAISE increases first-moment lag, β₁ axis DROP direction still open.
- **#1601 nezuko NULL (bilateral)**: v-buffer state-reset doesn't reproduce edward's pulse. Edward's mechanism is parametric-scheduling.
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude axis right-shoulder closed. 0.995, 0.999 both NULL.
