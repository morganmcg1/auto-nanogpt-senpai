# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 11:35 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## ⚠️ HOT WIN CANDIDATE — alphonse #1637 Arm A `ara5opnj` — seed-2 in flight

**Pre-target body Muon LR boost ×1.25 during steps 2750-2900**: val_ema=3.262770, sr=2875. **Clause 2 PASS by 0.084 mnat** (sub-noise margin, seed-1). Arm B (×1.5 boost) `ezukpl39` TERMINAL NULL (val_ema=3.2670, sr=2925) — Goldilocks confirms ×1.25 is the sharp optimum. **Seed-2 of Arm A `dvcemg0l` at step ~2125/3250, ETA terminal ~13:00 UTC.** If seed-2 confirms (val_ema < 3.262854 OR sr ≤ 2862.5) → MERGE WIN.

## Pre-target bottleneck — definitively body-Muon-side

**Same factor ×1.25, same window, different optimizers:**
- alphonse body Muon LR boost ×1.25: **HOT WIN** (sr=2875, val_ema=3.262770)
- fern aux Adam LR boost ×1.25: **NULL** (sr=2925, val_ema=3.263768)
- frieren aux β₂ spike 0.99→0.995: **NULL** (sr=2875, val_ema=3.263257)

The pre-target window mechanism is at the body-Muon side. Aux-side mechanisms (LR, β₂) are broadly NULL.

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1666 | edward | Body Muon `beta_cov` pulse 0.95→0.99 @ step 975/2600 | Arm A NULL; Arm B `rb6wi7b6` step ~1175 | ~14:30 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25 Arm A WIN, ×1.5 Arm B NULL) | **⚠️ HOT WIN seed-2 `dvcemg0l` step ~2125/3250** | ~13:00 UTC |
| #1686 | askeladd | Pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} @ 2750-2900 | Arm A `njbgdsep` step ~750/3250 (dupe killed) | ~17:00 UTC |
| #1680 | nezuko | Pre-target PMuon γ pulse 0.4→{0.50, 0.60} @ steps 2750-2900 | Arm A `92tyetjn` step ~1850/3250 (fastest descent) | ~13:30 UTC |
| #1693 | fern | Pre-target body Muon wd BILATERAL pulse 0.025→{0.0, 0.05} @ 2750-2900 | Arm A `i0s55pdw` step ~200/3250 | ~19:00 UTC |
| #1667 | frieren | Pre-target aux β₂ transient spike — Arm A NULL; Arm B `3mzqajdn` step ~1050 | running | ~14:30 UTC |
| **#1648** | **tanjiro** | **Per-group aux β₂ pulse — BILATERAL NULL (per-group axis closed)** | **AWAITING SENPAI-RESULT → close + reassign** | terminal |
| #1660 | thorfinn | Pre-target NS coefficient pulse — Arm A `g68ikq9z` NULL terminal; Arm B `eif52h8a` step ~1775 | running | ~14:00 UTC |

## Research portfolio focus

**ONE ACTIVE HOT WIN CANDIDATE — seed-2 ETA ~13:00 UTC**
- alphonse #1637 Arm A (×1.25 body Muon LR boost): val_ema=3.262770 (−0.084 mnat). Arm B confirmed NULL (Goldilocks). Seed-2 at step ~2125.

**Pre-target body Muon mechanism map (the WIN axis)**

| Mechanism | Optimizer | Axis | Status |
|---|---|---|---|
| alphonse #1637 | body Muon | **LR magnitude** | ⚠️ HOT WIN (×1.25) |
| nezuko #1680 | body Muon | **γ whitening exponent** | in-flight Arm A step ~1850 |
| askeladd #1686 | body Muon | **μ momentum depth** | in-flight Arm A step ~750 |
| thorfinn #1660 | body Muon | **NS polynomial coefs** | Arm A NULL terminal; Arm B in-flight |
| fern #1693 | body Muon | **weight_decay (regularization)** | in-flight Arm A step ~200 |
| frieren #1667 | aux Adam | β₂ depth (aux-side) | Arm A NULL, Arm B in-flight |
| fern #1646 (CLOSED) | aux Adam | LR magnitude (aux-side) | ❌ NULL bilateral |
| edward #1666 | body Muon | beta_cov (different timing) | Arm A NULL, Arm B in-flight |
| **NEXT: tanjiro** | **body Muon** | **LR DOWN direction (×0.75, ×0.50)** | **draft for reassignment** |

**Body Muon axes covered in pre-target window: LR-UP (alphonse WIN), γ, μ, NS coefs (Arm A NULL), wd, beta_cov-late. Next axis to add: LR-DOWN direction (Goldilocks confirmation).**

**β₁ axis — BILATERALLY CLOSED**
- RAISE (#1592): 0.90 NULL, 0.95 NULL
- DROP (#1639): 0.70 NULL, 0.60 NULL
- β₁=0.80 unique local optimum.

**β₂ pulse mechanism mapping — COMPREHENSIVELY CLOSED**

| Axis | Status |
|---|---|
| Amplitude 0.99 (canonical) | ✅ WIN |
| Amplitude ≥0.995 (permanent) | ❌ NULL |
| Amplitude ≤0.90 (permanent) | ❌ NULL |
| Timing step 975 (canonical) | ✅ WIN |
| Timing step 900 / step 1050 | ❌ NULL (bilateral) |
| β₁ RAISE/DROP | ❌ NULL bilateral |
| Shape (discrete vs ramp) | ❌ Discrete unique |
| Per-group recipient (embed-only) | ❌ NULL (#1648 Arm A) |
| Per-group recipient (non-embed) | ❌ NULL (#1648 Arm B) |
| Pre-target transient spike 0.995 | ❌ NULL (#1667 Arm A) |
| Pre-target transient spike 0.999 | in-flight (#1667 Arm B) |

**Cross-optimizer / cross-moment-type / cross-temporal-regime matrix**

| Optimizer / moment | Step 975 permanent | Step 2600 permanent | Pre-target transient |
|---|---|---|---|
| Aux Adam β₂ (2nd moment) | ✅ WIN canonical | not tested | ❌ NULL Arm A; Arm B in-flight |
| Aux Adam β₁ (1st moment) | ❌ NULL bilateral | not tested | untested |
| Body Muon μ (1st moment) | ❌ NULL | ❌ NULL | askeladd #1686 in-flight |
| Body Muon beta_cov (2nd moment) | ❌ NULL Arm A | Arm B in-flight | untested |

## Key closed findings (session)

- **#1660 thorfinn Arm A NULL**: pre-target NS-coef conservative quintic NULL.
- **#1648 tanjiro NULL (bilateral)**: per-group β₂ at step 975 bilaterally NULL — canonical #1532 requires ALL 3 aux Adam param groups simultaneously.
- **#1646 fern NULL (bilateral)**: aux-side pre-target LR boost NULL. Pre-target bottleneck definitively body-Muon-specific.
- **#1639 askeladd NULL (bilateral DROP)**: β₁ axis FULLY closed.
- **#1666 edward Arm A NULL**: body Muon `beta_cov` pulse @ step 975 NULL.
- **#1634 nezuko NULL (bilateral)**: β₂ smooth-ramp shape axis fully closed.
- **#1622 edward NULL (bilateral)**: Body Muon momentum reset/damp. Momentum is load-bearing.
- **#1605 frieren NULL (seed-2)**: β₂ timing axis fully closed.
- **#1607 tanjiro NULL (bilateral)**: β₂ amplitude axis FULLY CLOSED.
- **#1621 thorfinn NULL (bilateral)**: AGC linear-decay closed.
- **#1604 fern NULL (bilateral)**: Body Muon μ pulse doesn't generalize from aux Adam.
- **#1601 nezuko NULL (bilateral)**: v-buffer state-reset NULL.
- **#1591 alphonse NULL (bilateral)**: β₂ amplitude right-shoulder closed.
