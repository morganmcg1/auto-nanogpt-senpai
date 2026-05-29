# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 13:05 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## 🚧 PLATEAU PROTOCOL ENGAGED — pre-target body Muon scalar mechanism family exhausted

**alphonse #1637 HOT WIN candidate REJECTED at n=2.** Sub-noise seed-1 (val_ema=3.262770, sr=2875, Δ=−0.084 mnat) was within seed variance: seed-2 came back val_ema=3.2658, sr=2925. Aggregate n=2 mean: val_ema=3.26428, sr=2900 — both gate clauses fail. **PR #1637 CLOSED.**

This was the only WIN candidate across 5+ pre-target body Muon mechanism axes. Combined with:
- thorfinn NS coefs Arm A NULL (sr=2925)
- edward beta_cov-975 NULL (sr=2925)
- nezuko γ pulse Arm A trending NULL (sr=2925)
- thorfinn NS coefs Arm B trending NULL (sr=2925)
- fern aux LR bilateral NULL (#1646)
- frieren aux β₂ Arm A NULL
- tanjiro per-group β₂ bilateral NULL

**Pattern: 8+ NULLs in pre-target/short-pulse scalar mechanism family.** Body Muon's update computation has been comprehensively probed at every scalar axis.

**Escalation**: move up a tier of abstraction. Next direction = **wrapper optimizers on body Muon** (parameter-level structural change, not scalar tune). First wrapper: **Lookahead** (alphonse #1701).

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1666 | edward | Body Muon `beta_cov` pulse @ step 975/2600 | Arm A NULL; Arm B `rb6wi7b6` step ~1975 | ~14:30 UTC |
| **#1701** | **alphonse** | **🆕 Lookahead-style outer optimizer wrapper on body Muon (k=5, k=10)** | **JUST ASSIGNED — plateau escalation** | **~21:00 UTC** |
| #1686 | askeladd | Pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} | Arm A `njbgdsep` step ~1300/3250 | ~17:00 UTC |
| #1680 | nezuko | Pre-target PMuon γ pulse 0.4→{0.50, 0.60} | Arm A `92tyetjn` step ~3050 (trending NULL sr=2925) | ~13:15 UTC |
| #1693 | fern | Pre-target body Muon wd BILATERAL pulse {0.0, 0.05} | Arm A `i0s55pdw` step ~1400/3250 | ~17:00 UTC |
| #1667 | frieren | Pre-target aux β₂ transient spike — Arm A NULL; Arm B `3mzqajdn` running | running | ~14:30 UTC |
| #1697 | tanjiro | Pre-target body Muon LR DROP bilateral ×{0.75, 0.50} | Pickup pending | ~19:00 UTC |
| #1660 | thorfinn | Pre-target NS coefficient pulse — Arm A NULL; Arm B `eif52h8a` step ~2950 (sr=2925 trending NULL) | running | ~14:00 UTC |

## Research portfolio focus

**TIER ESCALATION: from scalar mechanism pulses → wrapper optimizers**

| Direction | Mechanism class | Status |
|---|---|---|
| Tier 1: Scalar pulses (LR, γ, μ, wd, β₂, beta_cov, NS coefs) | Inner-state hyperparameters | 8+ NULLs — exhausted |
| **Tier 2: Wrapper optimizers (Lookahead, Slow Momentum, SOAP-style)** | **Outer-loop parameter dynamics** | **#1701 alphonse Lookahead (k=5, k=10)** |
| Tier 3: Architectural changes (block routing, weight tying, activation gating) | Structural | not yet engaged |
| Tier 4: Loss-level reformulation (z-loss, auxiliary losses) | Objective | not yet engaged |

**Body Muon pre-target axes — DEFINITIVELY MAPPED**

| Axis | Mechanism | Status |
|---|---|---|
| LR magnitude UP (×1.25, ×1.5) | alphonse #1637 | ❌ Sub-noise seed-1, n=2 NULL |
| LR magnitude DOWN | tanjiro #1697 | in flight |
| γ whitening exponent | nezuko #1680 | Arm A trending NULL |
| μ momentum depth | askeladd #1686 | in flight |
| NS polynomial coefs | thorfinn #1660 | Arm A NULL, Arm B trending NULL |
| weight_decay | fern #1693 | in flight |
| beta_cov pulse @ 975 | edward #1666 Arm A | ❌ NULL |
| beta_cov pulse @ 2600 | edward #1666 Arm B | in flight |
| Nesterov momentum | frieren #1605 | ❌ NULL bilateral |
| Schedule-free | tanjiro #1576 | ❌ NULL |

**β₁ axis — BILATERALLY CLOSED** (RAISE #1592 + DROP #1639 NULL). β₁=0.80 unique local optimum.

**β₂ pulse mechanism mapping — COMPREHENSIVELY CLOSED** (amplitude, timing, shape, β₁ pulse, per-group recipient all NULL except canonical 0.95→0.99 @ 975).

## Key closed findings (session)

- **#1637 alphonse CLOSED (n=2 NULL)**: pre-target body Muon LR ×1.25 sub-noise seed-1 (val_ema 3.262770, sr 2875) NOT confirmed by seed-2 (val_ema 3.2658, sr 2925). Aggregate fails gate. WIN was seed variance.
- **#1660 thorfinn Arm A NULL**: pre-target NS-coef conservative quintic NULL.
- **#1648 tanjiro NULL (bilateral)**: per-group β₂ at step 975 bilaterally NULL.
- **#1646 fern NULL (bilateral)**: aux-side pre-target LR boost NULL. Pre-target bottleneck definitively body-Muon-specific (... but body-Muon-side is also broadly NULL on scalar axes).
- **#1639 askeladd NULL (bilateral DROP)**: β₁ axis FULLY closed.
- **#1666 edward Arm A NULL**: body Muon `beta_cov` pulse @ step 975 NULL.
- **#1634 nezuko NULL (bilateral)**: β₂ smooth-ramp shape axis fully closed.
- **#1622 edward NULL (bilateral)**: Body Muon momentum reset/damp. Momentum is load-bearing.
- **#1605 frieren NULL (seed-2)**: β₂ timing axis fully closed.
- **#1607 tanjiro NULL (bilateral)**: β₂ amplitude axis FULLY CLOSED.

## Next directions queue (post-Lookahead)

If Lookahead NULL: pivot to other wrappers:
- **Slow Momentum** (Wang & Singer) — different averaging structure
- **SOAP / Shampoo-style preconditioner** for body Muon — replace bilateral whitening with full Kronecker
- **AdaShift** wrapper — variant of Adam with shifted moment estimation
- **Block-routing-aware gradient scaling** — gradient weighting by transformer block depth (architectural-ish)

If Lookahead Arm A or B WIN: sweep k and α to find Goldilocks; investigate stacking with EMA refresh.
