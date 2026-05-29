# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-29 22:45 UTC**
- **Current baseline:** PR #1532 (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Canonical defaults (post #1614):** β₂ pulse fires automatically at step 975 in all new runs — no flag needed.
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## 🚧 PLATEAU PROTOCOL ENGAGED — body Muon scalar axes definitively closed; advancing to structural Tier-2 mechanisms

**Session NULLs extending the plateau:**
- alphonse #1637 (LR-UP ×1.25 seed-2) — NULL at n=2 aggregate
- thorfinn #1660 (NS polynomial coefficients bilateral) — NULL: both conservative-quintic and Jordan-aggressive degrade vs canonical cubic Newton
- tanjiro #1648 (per-group β₂ recipient axis) — bilateral NULL
- edward #1666 (body Muon β_cov pulse 0.95→0.99 bilateral, steps 975 + 2600) — NULL: cross-optimizer β-deepening hypothesis fails
- **frieren #1667 (pre-target aux β₂ spike 0.995/0.999 bilateral) — NULL: β₂-pulse mechanism COMPREHENSIVELY CLOSED**
- **nezuko #1680 (pre-target PMuon γ pulse 0.50/0.60 bilateral) — NULL: γ axis CLOSED**
- **edward #1709 (AdaShift temporal-lag aux Adam bilateral) — NULL: AdaShift FAMILY CLOSED via mechanistic root cause (sparse-grad + self-scaling failure modes)**

**Latest NULLs (this session):**
- **tanjiro #1697 (pre-target body Muon LR DROP bilateral ×{0.75, 0.50}) — CLOSED:** Arm A sr=2925 +2.04 mnat NULL; Arm B sr=2925 +3.02 mnat NULL. **Monotonic worsening** with deeper drop. Combined with alphonse #1637 LR-UP bilateral NULL, **uniform body-Muon LR axis BILATERALLY CLOSED in both directions**. Depth-asymmetric LR untested → tanjiro reassigned to per-block LR-mult burst.
- **fern #1693 (pre-target body Muon wd bilateral pulse {0.0, 0.05}) — CLOSED:** Arm A sr=2925 +1.88 mnat NULL; Arm B sr=2925 +3.32 mnat NULL. Clean asymmetric param-norm response confirms mechanism is real but **not load-bearing**. wd axis CLOSED; **all body Muon pre-target scalar pulse axes definitively exhausted**.
- **askeladd #1686 (pre-target body Muon μ transient pulse bilateral) — CLOSED:** Arm A μ=0.97 sr=2950 NULL; Arm B μ=0.99 sr=3200 CATASTROPHIC (+325 sr, +15.6 mnat). Deep momentum in pre-target window is actively destructive. **μ axis definitively closed across ALL temporal regimes** (step 975, step 2600 perm from #1604; pre-target window transient from this PR).

**Exhausted axes (definitively closed in r1):**
- **Pre-target body Muon scalars (ALL BILATERAL NULL):** LR-UP (#1637), **LR-DOWN (#1697 CLOSED bilateral)**, γ (#1680), **μ (#1686 CLOSED — all temporal regimes)**, NS-coefs (#1660), β₁ (#1592/#1639), β_cov pulse@975 (#1666 Arm A), β_cov pulse@2600 (#1666 Arm B), Nesterov, schedule-free, **weight_decay (#1693 CLOSED bilateral)**
- **Momentum buffer hard-reset untested → assigned to askeladd (#1730) as first structural state-discard experiment on first-moment buffer.**
- **β₂ pulse mechanism:** amplitude, timing, shape, per-group recipient, pre-target re-spike — ALL NULL except canonical 0.95→0.99 @ 975 (#1667 closes the re-spike variant)
- **Optimizer family replacements:** AdEMAMix, Lookahead (FULLY CLOSED), Sophia, Lion, Adan, GrokFast, AdaBelief, AMSGrad, ADOPT-aux, **AdaShift per-element (#1709 NULL with mechanistic closure)**
- **Covariance refresh:** L_cov/R_cov at steps 975/2275/2600/cooldown-start (#1666 closes) — soft-modulation via β_cov pulse closed. **Hard zero reset (nezuko #1726 Arm A NULL sr=2950; Arm B in flight).**
- **pEMA stacking:** stacked 2nd refresh at 2750/2850 (thorfinn #1704) — bilateral NULL. Canonical 2600 is a singular optimum. **pEMA design space EXHAUSTED.**
- **Depth-stratified β_cov continuous ramp ±0.01 (#1339 NULL).** Binary-split with ±0.025 large Δβ untested → assigned to edward (#1727).

**Tier escalation progress:**
- Tier 1 (scalar pulses): ≥14 NULLs — comprehensively exhausted across all body Muon scalar axes
- Tier 2a (wrapper optimizers): Lookahead FULLY CLOSED; AdaShift per-element FULLY CLOSED via mechanistic root cause; **ADOPT-style async whitening (#1703) IN FLIGHT — first novel Tier-2 wrapper still running**
- Tier 2a (structural state intervention): **Cov-state hard zero reset (#1726 nezuko) IN FLIGHT** + **Momentum buffer hard zero reset (#1730 askeladd) JUST ASSIGNED** — first-moment and second-moment buffer discard running in parallel; will reveal whether optimizer-state reset is broadly useful or buffer-class-specific
- Tier 2b (compounding + structural decoupling): pEMA stacking (#1704) IN FLIGHT; **depth-stratified β_cov binary-split (#1727 edward) JUST ASSIGNED**

## Active assignments (all 8 students engaged on r1)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1703 | alphonse | ADOPT async whitening on body PMuon | In flight `gjmywcji` step ~3125 sr=2950 | Terminal ~22:50 UTC |
| **#1749** | **thorfinn** | **AdEMAMix dual-EMA first moment on aux AdamW (Arm A α=0.5/β₃=0.999/T=500; Arm B α=0.75/β₃=0.9995/T=750)** | **Just assigned (22:45 UTC)** | **~02:30 / ~06:30 UTC** |
| #1730 | askeladd | Pre-target body Muon momentum buffer HARD ZERO RESET (Arm A crashed @ 1925; Arm B `uhrosnl0` step ~525) | Arm A crashed; Arm B in flight | ~00:30 UTC |
| #1739 | fern | Pre-target NS_ITERS burst {14, 16} @ 2750-2900 | Arm A `hfhcbony` step ~1575 | ~00:15 UTC |
| #1708 | frieren | Pre-target Skylight u/w floor pulse TARGET_UW 0.35→{0.45, 0.55} | Arm B `bstlsmqy` step ~2850 | ~23:20 UTC |
| #1742 | tanjiro | Pre-target body Muon depth-asymmetric per-block LR-mult burst ×1.5 (Arm A early-half) | Arm A `xdpfzmo9` step ~1250 | ~00:55 UTC |
| #1726 | nezuko | Pre-target PMuon L_cov/R_cov hard zero RESET — Arm A FINISHED NULL (sr=2950, val_ema 3.27093); Arm B `pyugggcd` fastaccum step ~500 | Arm B in flight | ~00:10 UTC |
| #1727 | edward | Depth-split β_cov binary group — Arm A FINISHED NULL (sr=2950, val_ema 3.27122); Arm B `mj8zysth` step ~500 | Arm B in flight | ~00:10 UTC |

**Recent closures (this session):**
- ❌ #1704 thorfinn (stacked pEMA refresh 2750/2850) — bilateral NULL (Arm A sr=2925, Arm B sr=2950; monotonic worsening). **pEMA-stacked-refresh axis CLOSED.** Canonical 2600 position is a singular optimum at cooldown_start_step regime boundary.
- ❌ #1726 nezuko Arm A `210d43l3` FINISHED NULL (sr=2950, val_ema 3.27093)
- ❌ #1727 edward Arm A `66yd8u3s` FINISHED NULL (sr=2950, val_ema 3.27122)
- ❌ #1704 thorfinn `z3676wa3` Arm B FINISHED NULL (sr=2950, val_ema 3.265423)

## Research portfolio focus

**Tier escalation: from scalar mechanism pulses → structural state interventions**

| Direction | Mechanism class | Status |
|---|---|---|
| Tier 1: Scalar pulses (LR, γ, μ, wd, β₂, β_cov, NS coefs) | Inner-state hyperparameters | ≥14 NULLs — comprehensively closed |
| Tier 2a: ADOPT async whitening (#1703) | Update-rule order swap (no in-sample bias) | First novel Tier-2 — in flight |
| Tier 2a: Cov-state hard zero RESET (#1726) | Discard-and-rebuild PMuon covariance state at phase boundary | **Just assigned (first structural state intervention)** |
| Tier 2b: pEMA stacking (#1704) | Compound confirmed WIN mechanism | First test — in flight |
| Tier 2b: Depth-split β_cov binary group (#1727) | Structural decoupling tied to merged late-higher LR pattern | **Just assigned (#1339 continuous-ramp ±0.01 NULL → binary-split ±0.025)** |
| Tier 3: Wrapper optimizers (Slow Momentum, SOAP-style) | Outer-loop parameter dynamics | queued if #1703 NULL |
| Tier 4: Architectural/loss changes | Structural | not yet engaged |

**Body Muon pre-target axes — DEFINITIVELY MAPPED**

| Axis | Status |
|---|---|
| LR UP (×1.25, ×1.5) | ❌ NULL (n=2 seed variance) |
| LR DOWN (×0.75, ×0.50) | ❌ NULL bilateral #1697 — axis CLOSED |
| **LR per-block depth-asymmetric burst (×1.5 early vs late)** | **tanjiro #TBD JUST ASSIGNED — first depth-asymmetric LR test (orthogonal to uniform LR closures)** |
| γ whitening exponent | ❌ NULL bilateral #1680 — axis CLOSED |
| μ momentum depth | in flight #1686 (Arm A trending NULL) |
| NS polynomial coefficients (BILATERAL) | ❌ NULL #1660 — axis fully closed |
| NS iteration count | not yet tested phase-specifically |
| weight_decay | ❌ NULL bilateral #1693 — axis CLOSED |
| **NS iteration count (burst @ pre-target)** | **#1739 JUST ASSIGNED — bilateral NS=14/16 vs canonical 12 (orthogonal to #1660 polynomial NULL)** |
| beta_cov pulse @ 975 | ❌ NULL #1666 Arm A |
| beta_cov pulse @ 2600 | ❌ NULL #1666 Arm B |
| **L_cov/R_cov HARD ZERO RESET (structural)** | **#1726 JUST ASSIGNED — first state-reset (vs modulation) experiment** |
| **β_cov depth-split binary group (large Δβ)** | **#1727 JUST ASSIGNED — orthogonal primitive vs #1339 continuous-ramp NULL** |
| ADOPT async whitening (update order) | #1703 in flight — first Tier-2 wrapper still running |
| Nesterov momentum | ❌ NULL bilateral |
| Schedule-free | ❌ NULL |
| β₁ axis | ❌ BILATERALLY CLOSED (#1592, #1639) |

**β₂ pulse mechanism mapping — COMPREHENSIVELY CLOSED** (amplitude, timing, shape, β₁ pulse, per-group recipient, pre-target re-spike all NULL except canonical 0.95→0.99 @ 975).

## Key closed findings (session)

- **#1709 edward AdaShift HIGH-INFORMATION CLOSURE:** Three-layer mechanistic root cause: (1) cold-start zero-grad bug, (2) sparse-gradient incompatibility on `embed.weight` (~99.5% row sparsity), (3) loss of self-scaling on non-stationary dense lm_head gradients → trajectory perturbation → body grads → L_cov ill-conditioning → eigh fragility or val divergence. Per-element AdaShift definitively closed. **Block-wise AdaShift** (scalar v_t per tensor) untested as separate axis. **Byproduct gain:** defensive eigh jitter retry + telemetry in `matrix_neg_power` (cherry-pick to advisor branch as hygiene).
- **#1680 nezuko γ bilateral NULL:** PMuon whitening exponent 0.5/0.6 vs canonical 0.4 both miss the gate; γ axis closed. Whitening *strength* not the limiting factor — underlying *state* (L_cov/R_cov) is the natural next target (now nezuko's #1726).
- **#1667 frieren β₂-spike bilateral NULL:** pre-target β₂ re-spike (0.995/0.999) closes the last open variant of the β₂-pulse axis. The aux β₂ mechanism is fundamentally a *destination* effect at step 975, not a *transient* effect.

## Next directions queue

After current wave of in-flight experiments:

1. ~~NS_ITERS burst at pre-target window~~ — assigned to fern #1739
2. **Slow Momentum (Wang & Singer)** — if async whitening (#1703) NULL, try different averaging structure
3. **Block-wise AdaShift** (scalar v_t per tensor, max(|g_{t-n}|)²) — reserved as separate PR; structurally orthogonal to #1709 per-element NULL
4. **Cov-state PARTIAL reset (early-only or late-only blocks)** — if nezuko's #1726 wins on full reset, narrow the mechanism
5. **β_cov depth-split tuning** — if edward's #1727 Arm A wins, tune split-point (3-vs-9 cutoff, 4-vs-8 cutoff) and Δβ amplitude (0.97/0.92 vs 0.965/0.925 vs 0.98/0.90)
6. **Body Muon SOAP-style preconditioner via off-diagonal L/R refresh** (fern #1654 on r1 separate branch)
