# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 03:40 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1622 | edward | Muon momentum reset at pEMA refresh (step 2600) — scale 0.0 & 0.1 | Arm A NULL; Arm B `veho0mwj` scale=0.1 running (~step 1100) | ~05:45 UTC |
| #1637 | alphonse | Pre-target body Muon LR boost (×1.25, ×1.5 during steps 2750-2900) | Arm A `m1sbva4z` picked up (step ~25 at 03:15 UTC) | ~09:45 UTC |
| #1639 | askeladd | Aux β₁ DROP pulse @ step 975 (0.70, 0.60) | Arm A `mqgtit8o` running (step ~1075 at 03:15 UTC) | ~07:30 UTC |
| #1634 | nezuko | Aux β₂ smooth ramp (ramp_width=50 Arm A, 200 Arm B) | Arm A `4y6529rb` running (~step 2200) | ~04:30 UTC |
| #1646 | fern | Pre-target aux Adam LR boost (×1.25, ×1.5 during steps 2750-2900) | Arm A `ffuy3nqy` running (step ~600 at 03:15 UTC) | ~08:00 UTC |
| #1605 | frieren | Aux β₂ timing step 1050 Arm B — MARGINAL WIN (−0.225 mnat); seed-2 `u4zmm04x` in flight | Seed-2 running (~step 675 at 03:15 UTC) | ~05:55 UTC |
| #1648 | tanjiro | Per-group aux Adam β₂ pulse (embed-only vs non-embed) — JUST ASSIGNED | Pickup pending | ~11:30 UTC |
| #1621 | thorfinn | Linear-decay AGC ramp=500 Arm B `6fauhz48` (Arm A ramp=100 NULL) | Running (~step 1584) | ~05:00 UTC |

## Research portfolio focus

**Primary: β₂ pulse mechanism mapping — NEARLY COMPLETE**

| Axis | Experiment | Status |
|---|---|---|
| Amplitude up (0.99) | edward #1532 | ✅ WIN (canonical) |
| Amplitude up (0.995) | alphonse | ❌ NULL done |
| Amplitude up (0.999) | alphonse | ❌ NULL done |
| Amplitude down (0.90) | tanjiro #1607 Arm A | ❌ NULL (sr=2975, +6.6 mnat) |
| Amplitude down (0.85) | tanjiro #1607 Arm B | ❌ NULL (sr=3050, +10.6 mnat) |
| Timing (step 900) | frieren Arm A | ❌ NULL (val_ema=3.265240, sr=2925) |
| Timing (step 1050) | frieren Arm B | ⚠️ MARGINAL WIN (−0.225 mnat) — seed-2 confirming |
| β₁ analog RAISE (0.90, 0.95) | askeladd #1592 | ❌ NULL (bilateral — moments asymmetry) |
| β₁ analog DROP (0.70, 0.60) | askeladd #1639 | In-flight |
| v-buffer reset | nezuko #1601 | ❌ NULL (bilateral) |
| β₂ pulse shape (discrete vs ramp) | nezuko #1634 | In-flight |
| Body Muon (any timing) | fern #1604 | ❌ NULL/DIVERGE (bilateral — axis CLOSED) |
| **β₂ amplitude axis** | tanjiro #1607 | **❌ BILATERALLY CLOSED** — 0.99 is clear amplitude optimum |
| **Per-group β₂ pulse recipient** | tanjiro #1648 | In-flight (JUST ASSIGNED) |

**β₂ amplitude axis FULLY CLOSED**: 0.99 canonical is the clear optimum. All deviations (0.85, 0.90 downward; 0.995, 0.999 upward) regress. Monotone-up signal from downward closure mirrors monotone-down from upward closure. Edward's mechanism confirmed as robust.

**Mechanism-attribution phase** (who is the beneficiary of edward's WIN?):
- tanjiro #1648: which aux group benefits from β₂ pulse (embed vs lm_head+scalars)?
- askeladd #1639: β₁ DROP direction tests if first-moment responsiveness is also relevant
- nezuko #1634: discrete vs ramp pulse shape tests if discontinuity is load-bearing

**Pre-target window** (steepen descent to move sr before step 2925):
- alphonse #1637: body Muon LR boost (×1.25, ×1.5 @ 2750-2900) — just picked up
- fern #1646: aux Adam LR boost (×1.25, ×1.5 @ 2750-2900) — just picked up
- Orthogonal complement: if both WIN → stack; if only one → identifies bottleneck parameter group

**Phase-boundary state mechanisms** (optimizer state at transitions):
- thorfinn #1621: linear-decay AGC ramp=500 — tests smooth vs hard cutoff
- edward #1622: Muon momentum reset at pEMA refresh — soft reset hypothesis

## Key closed findings (session)

- **β₂ amplitude axis BILATERALLY CLOSED**: 0.99 is the unique amplitude optimum. Downward regresses monotonically (+6.6, +10.6 mnat); upward beyond 0.99 NULLs (diminishing returns at 0.995, 0.999). Canonical is at the peak.
- **#1604 fern NULL (bilateral catastrophic)**: Body Muon momentum pulse does NOT generalize from aux Adam β₂ pulse. Axis fully closed. Pulse mechanisms are optimizer-type × moment-type specific.
- **#1592 askeladd NULL (bilateral RAISE)**: β₁ RAISE increases first-moment lag. Damage fires immediately at step 1000. Moments asymmetry confirmed.
- **#1601 nezuko NULL (bilateral)**: aux v-buffer state-reset doesn't reproduce edward's pulse. Edward's mechanism is parametric-scheduling, not state-driven.
- **#1605 frieren Arm B MARGINAL WIN**: β₂ timing step=1050 → val_ema=3.262629 (−0.225 mnat, within seed noise). Seed-2 `u4zmm04x` confirming. If confirmed, canonical timing shifts to 1050.
- **#1532 edward MERGED WIN**: β₂ pulse 0.95→0.99 @ step 975 = +25 sr improvement, canonical.
