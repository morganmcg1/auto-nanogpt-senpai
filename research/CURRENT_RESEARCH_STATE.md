# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 10:35 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## ⚠️ HOT WIN CANDIDATE — alphonse #1637 Arm A `ara5opnj` — seed-2 in flight

**Pre-target body Muon LR boost ×1.25 during steps 2750-2900**: val_ema=3.262770, sr=2875. **Clause 2 PASS by 0.084 mnat** (sub-noise margin, seed-1). Arm B (×1.5 boost) `ezukpl39` TERMINAL NULL (val_ema=3.2670, sr=2925) — Goldilocks confirms ×1.25 is the sharp optimum. **Seed-2 of Arm A `dvcemg0l` launched at 09:03 UTC, step ~375/3250, ETA terminal ~13:00 UTC.** If seed-2 confirms (val_ema < 3.262854 OR sr ≤ 2862.5) → MERGE WIN.

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1666 | edward | Body Muon `beta_cov` pulse 0.95→0.99 @ step 975/2600 | Arm A `l0fnwke6` NULL (sr=2925); Arm B `rb6wi7b6` step ~100/3250 | ~14:30 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25 Arm A WIN, ×1.5 Arm B NULL) | **⚠️ HOT WIN seed-2 `dvcemg0l` step ~375/3250** | ~13:00 UTC |
| #1686 | askeladd | Pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} @ 2750-2900 | JUST ASSIGNED | ~18:00 UTC |
| #1680 | nezuko | Pre-target PMuon γ pulse 0.4→{0.50, 0.60} @ steps 2750-2900 | Arm A `92tyetjn` step ~125 | ~13:30 UTC |
| #1646 | fern | Pre-target aux Adam LR boost (×1.25 Arm A NULL, ×1.5 Arm B) | Arm B `3darntgi` running | ~13:00 UTC |
| #1667 | frieren | Pre-target aux β₂ transient spike (0.99→0.995/0.999 @ 2750-2900) | Arm A `e1akroju` step ~2225/3250 | ~11:30 UTC |
| #1648 | tanjiro | Per-group aux Adam β₂ pulse (Arm A embed-only NULL; Arm B non-embed) | Arm B `oumooke5` step ~2225/3250 | ~12:30 UTC |
| #1660 | thorfinn | Pre-target NS coefficient pulse (conservative quintic vs Jordan-aggressive) | Arm A `g68ikq9z` step ~3200/3250 → trending NULL; Arm B pending | ~14:00 UTC |

## Research portfolio focus

**ONE ACTIVE HOT WIN CANDIDATE — seed-2 imminent**
- alphonse #1637 Arm A (×1.25 body Muon LR boost): val_ema=3.262770 (−0.084 mnat). Arm B confirmed NULL (Goldilocks). Seed-2 in flight (`dvcemg0l`).

**β₁ axis — BILATERALLY CLOSED (this session)**
- RAISE (#1592): 0.90 NULL, 0.95 NULL
- DROP (#1639): 0.70 NULL, 0.60 NULL (this session)
- β₁=0.80 unique local optimum. Aux Adam first-moment robustly invariant within ±0.20.

**β₂ pulse mechanism mapping — COMPLETE (all axes closed except per-group in-flight)**

| Axis | Status |
|---|---|
| Amplitude 0.99 (canonical) | ✅ WIN |
| Amplitude ≥0.995 (permanent) | ❌ NULL (diminishing returns) |
| Amplitude ≤0.90 (permanent) | ❌ NULL (monotone regression) |
| Timing step 975 (canonical) | ✅ WIN |
| Timing step 900 / step 1050 | ❌ NULL (bilateral) |
| β₁ RAISE (0.90, 0.95) | ❌ NULL bilateral (#1592) |
| β₁ DROP (0.70, 0.60) | ❌ NULL bilateral (#1639 this session) |
| Shape (discrete vs ramp) | ❌ Discrete unique (#1634 bilateral NULL) |
| Per-group recipient | Embed-only NULL (#1648 Arm A); non-embed in-flight |
| Pre-target transient spike 0.995/0.999 | In-flight (frieren #1667) |

**Pre-target window mechanisms (steepen descent before step 2925) — 6 axes in flight**

| Mechanism | Optimizer | Axis | Status |
|---|---|---|---|
| alphonse #1637 | body Muon | LR magnitude | ⚠️ HOT WIN (×1.25 seed-2 in flight) |
| fern #1646 | aux Adam | LR magnitude | Arm A NULL, Arm B in-flight |
| thorfinn #1660 | body Muon | NS polynomial coefs | Arm A trending NULL |
| frieren #1667 | aux Adam | β₂ depth (transient) | Arm A running |
| nezuko #1680 | body Muon | γ whitening exponent | Arm A early |
| **askeladd #1686** | **body Muon** | **μ momentum depth (transient)** | **JUST ASSIGNED** |

**Cross-optimizer / cross-moment-type / cross-temporal-regime matrix**

| Optimizer / moment | Step 975 permanent | Step 2600 permanent | Pre-target transient |
|---|---|---|---|
| Aux Adam β₂ (2nd moment) | ✅ WIN canonical #1532 | not tested | frieren #1667 in-flight |
| Aux Adam β₁ (1st moment) | ❌ NULL bilateral (#1592 RAISE, #1639 DROP) | not tested | untested |
| Body Muon μ (1st moment) | ❌ NULL (fern #1604) | ❌ NULL (fern #1604) | **askeladd #1686 ← just assigned** |
| Body Muon `beta_cov` (2nd moment) | ❌ NULL (edward #1666 Arm A) | Arm B in-flight | untested |

## Key closed findings (session)

- **#1639 askeladd NULL (bilateral DROP)**: β₁ axis FULLY bilaterally closed. β₁=0.80 unique optimum. First-moment EMA depth robustly invariant within ±0.20.
- **#1666 edward Arm A NULL**: body Muon `beta_cov` pulse @ step 975 NULL. The 2nd-moment-EMA-deepening WIN appears aux-Adam-specific at this timing.
- **#1648 tanjiro Arm A NULL**: per-group β₂ pulse on embed-only NULL. Canonical #1532 requires β₂ deepening across ALL 3 aux Adam groups.
- **#1634 nezuko NULL (bilateral)**: β₂ smooth-ramp shape axis fully closed. Discrete jump is load-bearing.
- **#1622 edward NULL (bilateral)**: Body Muon momentum reset/damp. Momentum is load-bearing, not stale.
- **#1605 frieren NULL (seed-2)**: β₂ timing step 1050 marginal WIN not confirmed. Timing axis fully closed.
- **#1607 tanjiro NULL (bilateral)**: β₂ amplitude axis FULLY CLOSED.
- **#1621 thorfinn NULL (bilateral)**: AGC linear-decay closed.
- **#1604 fern NULL (bilateral)**: Body Muon μ pulse doesn't generalize from aux Adam.
- **#1601 nezuko NULL (bilateral)**: v-buffer state-reset doesn't reproduce edward's pulse.
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude right-shoulder closed.
