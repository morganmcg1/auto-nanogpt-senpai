# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 13:50 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## 🚧 PLATEAU PROTOCOL ENGAGED — deep exhaustion of pre-target window mechanisms

**Session NULLs extending the plateau:**
- alphonse #1637 (LR-UP ×1.25 seed-2) — NULL at n=2 aggregate
- thorfinn #1660 (NS polynomial coefficients bilateral) — NULL: both conservative-quintic and Jordan-aggressive degrade vs canonical cubic Newton
- tanjiro #1648 (per-group β₂ recipient axis) — bilateral NULL

**Exhausted axes:**
- **Pre-target body Muon scalars (ALL NULL):** LR-UP, LR-DOWN (in flight), γ, μ (in flight), NS-coefs, β₁, β₂, β_cov pulse@975 (NULL), weight_decay (in flight), Nesterov, schedule-free
- **β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient — ALL NULL except canonical 0.95→0.99 @ 975
- **Optimizer family replacements:** AdEMAMix (17 closed), Lookahead (10+ closed, FULLY CLOSED), Sophia (7), Lion (10+), Adan (8+), GrokFast (2), AdaBelief (8+), AMSGrad (2), ADOPT-aux (2)
- **Covariance refresh:** L_cov/R_cov at steps 975/2275/2600/cooldown-start — all NULL

**Tier escalation progress:**
- Tier 1 (scalar pulses): ≥12 NULLs — exhausted
- Tier 2a (wrapper optimizers): Lookahead FULLY CLOSED in r1. **ADOPT-style async whitening (#1703) — FIRST NOVEL TIER-2 TEST**
- Tier 2b (pEMA compounding): Second paramEMA refresh (#1704) — test stacking the confirmed WIN

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| **#1703** | **alphonse** | **ADOPT async whitening on body PMuon (identity-init vs zeros-warmup50)** | **Just assigned** | **~21:30 UTC** |
| **#1704** | **thorfinn** | **Stacked 2nd pEMA refresh at step 2750 vs 2850** | **Just assigned** | **~21:30 UTC** |
| #1686 | askeladd | Pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} | Arm A `njbgdsep` running | ~17:00 UTC |
| #1680 | nezuko | Pre-target PMuon γ pulse 0.4→{0.50, 0.60} | Arm A `92tyetjn` running | ~13:30 UTC |
| #1693 | fern | Pre-target body Muon wd BILATERAL pulse {0.0, 0.05} | Arm A `i0s55pdw` running | ~17:00 UTC |
| #1667 | frieren | Pre-target aux β₂ transient spike 0.99→{0.995, 0.999} | Arm B `3mzqajdn` running | ~14:30 UTC |
| #1697 | tanjiro | Pre-target body Muon LR DROP ×{0.75, 0.50} | Pickup pending | ~19:00 UTC |
| #1666 | edward | Body Muon beta_cov pulse 0.95→0.99 @ step 975/2600 | Arm B `rb6wi7b6` running | ~14:30 UTC |

## Research portfolio focus

**Tier escalation: from scalar mechanism pulses → structural/compounding mechanisms**

| Direction | Mechanism class | Status |
|---|---|---|
| Tier 1: Scalar pulses (LR, γ, μ, wd, β₂, beta_cov, NS coefs) | Inner-state hyperparameters | ≥12 NULLs — exhausted |
| **Tier 2a: ADOPT async whitening (#1703)** | Update-rule order swap (no in-sample bias) | **FIRST TEST — just assigned** |
| **Tier 2b: pEMA stacking (#1704)** | Compound confirmed WIN mechanism | **FIRST TEST — just assigned** |
| Tier 3: Wrapper optimizers (Slow Momentum, SOAP-style) | Outer-loop parameter dynamics | queued if #1703 NULL |
| Tier 4: Architectural/loss changes | Structural | not yet engaged |

**Body Muon pre-target axes — DEFINITIVELY MAPPED**

| Axis | Status |
|---|---|
| LR UP (×1.25, ×1.5) | ❌ NULL (n=2 seed variance) |
| LR DOWN (×0.75, ×0.50) | in flight #1697 |
| γ whitening exponent | in flight #1680, Arm A trending NULL |
| μ momentum depth | in flight #1686 |
| NS polynomial coefficients (BILATERAL) | ❌ NULL #1660 — axis fully closed |
| NS iteration count | not yet tested phase-specifically |
| weight_decay | in flight #1693 |
| beta_cov pulse @ 975 | ❌ NULL #1666 Arm A |
| beta_cov pulse @ 2600 | in flight #1666 Arm B |
| ADOPT async whitening (update order) | #1703 — NOVEL, 0 prior PRs |
| Nesterov momentum | ❌ NULL bilateral |
| Schedule-free | ❌ NULL |
| β₁ axis | ❌ BILATERALLY CLOSED (#1592, #1639) |

**β₂ pulse mechanism mapping — COMPREHENSIVELY CLOSED** (amplitude, timing, shape, β₁ pulse, per-group recipient all NULL except canonical 0.95→0.99 @ 975).

## Key closed findings (session)

- **#1660 thorfinn BILATERAL NULL**: NS polynomial profile (conservative quintic + Jordan-aggressive) at fixed NS_ITERS=12 in pre-target window. Canonical cubic Newton (1.5, -0.5, 0.0) is robustly optimal. NS precision-axis definitively closed.
- **#1701 alphonse CLOSED (redundant)**: Lookahead wrapper was 10+ prior NULLs; closed before pod pickup. Lookahead family FULLY CLOSED in r1.

## Next directions queue

After current wave of in-flight experiments:

1. **Slow Momentum (Wang & Singer)** — if async whitening (#1703) NULL, try different averaging structure
2. **NS_ITERS burst at pre-target window** (12→14/16 during 2750-2900) — thorfinn follow-up if #1704 result is informative
3. **Per-block-depth beta_cov dispatch** — depth-stratified covariance EMA (not yet tried as bilateral depth partition)
4. **Body Muon SOAP-style preconditioner via off-diagonal L/R refresh** (fern #1654 on r1 separate branch)
5. **Pre-target UW floor PULSE** (researcher-agent suggestion): raise `TARGET_UW` from 0.35 to {0.45, 0.55} transiently during steps 2750-2900, then revert. #1269 (phase-gated 2500-3250) was NULL but a 150-step pre-target pulse is distinct. NEXT thorfinn assignment after #1704 results.
6. **AdaShift wrapper** — variant of Adam with shifted moment estimation for aux side
