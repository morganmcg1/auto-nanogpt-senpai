# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-06-02 12:35 UTC**
- **Current baseline:** PR #1532 — aux Adam β₂ pulse 0.95→0.99 @ step 975. val_ema=3.262854, sr=2875 (n=2 seeds `9coyk2ke`/`09qrijtm`)
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

---

## Active assignments (2026-06-02 12:35 UTC)

| Student | PR | Hypothesis | Status | Run IDs | Step / ETA |
|---|---|---|---|---|---|
| alphonse | #2269 | Aux Adam pre-update gradient EMA (α=0.90 vs α=0.95) | Assigned (pending pickup) | — | — |
| fern | #2275 | Body-Muon inter-block neighbor momentum avg (α=0.05 vs α=0.15) | Assigned (pending pickup) | — | — |
| frieren | #2276 | NS5 polynomial coef ATTN vs MLP role-split (Arm A MLP=Jordan, Arm B ATTN=Jordan) | Assigned (pending pickup) | — | — |
| tanjiro | #2240 | Body-Muon mom SCALE-UP ×1.5 @2750 | Arm A `1wmi61gf` running | `1wmi61gf` | step ~1750 / ETA ~13:15Z |
| thorfinn | #2256 | Body-PMuon β₁ block-strat ramp LATE-HIGHER (shallow 0.925/deep 0.975) | Arm A `bi8753cc` running | `bi8753cc` | step ~1750 / ETA ~13:40Z |
| edward | #2239 | NS_ITERS block-stratified DEEP-heavy (shallow=12/deep=16) | Arm B `js2j0siu` running | `js2j0siu` | step ~1250 / ETA ~13:55Z |
| askeladd | #2260 | Aux Adam per-group ε asymmetric allocation — lm_head tight ε=1e-12 | Arm A `oeto14li` running | `oeto14li` | step ~875 / ETA ~14:00Z |
| nezuko | #2262 | PMuon cov EMA update stride stratified by depth — shallow=2/deep=1 | Arm A `msudbd0c` running | `msudbd0c` | step ~875 / ETA ~14:10Z |

---

## Recent closures (2026-06-02)

### PR #2226 frieren — PMuon Frobenius ceiling by weight norm ❌ BILATERAL NULL
- Arm A (LOOSE γ=0.5) `c4jenl2b`: sr=3125 (+250 steps), val_ema=3.276481 (+13.6 mnat)
- Arm B (TIGHT γ=0.3) `g0oieeky`: sr=NEVER REACHED, val_ema=3.286966 (+24.1 mnat) — fire_rate=1.0 (all body params clipped every step)
- **Frobenius ceiling axis CLOSED. γ family FULLY EXHAUSTED.**

### PR #2225 fern — Aux Adam lm_head per-group β₁ split ❌ BILATERAL NULL
- Arm A (FAST β₁=0.5) `21ei4mc2`: sr=2925 (+50), val_ema=3.263988 (+1.13 mnat)
- Arm B (SLOW β₁=0.95) `o1tjorcy`: sr=2950 (+75), val_ema=3.268445 (+5.59 mnat)
- **Per-group β₁ split (lm_head granularity) CLOSED. Aux Adam β₁/β₂ per-group asymmetry EXHAUSTED.**

### PR #2219 alphonse — NS polynomial coeff phase-switch @2600 ❌ BILATERAL NULL
- **NS polynomial phase-switch axis CLOSED.**

### PR #2208 askeladd — POST-NS update EMA on body PMuon ❌ BILATERAL NULL
- **Entire paramEMA operator family EXHAUSTED.**

### PR #2210 nezuko — lm_head β₂ SECOND PULSE @2600 ❌ BILATERAL NULL
- **β₂ re-pulse @ late boundary axis CLOSED.**

### PR #2171 thorfinn — Block-LR slope MAGNITUDE ❌ BILATERAL NULL + seed-2 regression
- **Per-block LR (direction × magnitude) 2D subspace FULLY EXHAUSTED.**

### PR #2183 tanjiro — Aux Adam m-state HARD-ZERO RESET ❌ BILATERAL NULL
- **Aux Adam m-state HARD-ZERO CLOSED across all magnitudes, scopes, and temporal boundaries.**

### PR #2180 edward — Block-LR ramp shape ❌ BILATERAL NULL
- **Per-block LR ramp shape axis CLOSED.**

---

## Current research themes

### Tier-1: per-group/per-block structural mechanisms + aux Adam input quality

The winning innovations all exploit asymmetric treatment: late-higher LR (block-depth), β₂ pulse (timing), paramEMA (phase-boundary). Current frontier: per-group ε asymmetry, PMuon covariance frequency, lateral momentum state mixing (NEW — fern #2275), NS5 coefficient role differentiation (NEW — frieren #2276), and pre-filter quality before β₁/β₂ accumulation.

**Active open sub-axes:**
- **fern #2275** — Body-Muon inter-block NEIGHBOR MOMENTUM averaging (α=0.05 vs 0.15) — pending pickup — directive (b)+(d), pristine structural state-mixing
- **frieren #2276** — NS5 coef role-split ATTN vs MLP (MLP-Jordan vs ATTN-Jordan) — pending pickup — directive (b)+(d), pristine vs all prior NS5 role work
- **alphonse #2269** — Aux Adam pre-update gradient EMA (α=0.90/0.95) — pending pickup — directive (a)+(d)
- **tanjiro #2240** — body-Muon mom SCALE-UP @2750 bilateral ×1.5/×2.0 — ETA ~13:15Z
- **thorfinn #2256** — body-PMuon β₁ block-strat ramp late-higher/late-lower — ETA ~13:40Z
- **edward #2239** — NS_ITERS depth-stratified DEEP-heavy (shallow=12/deep=16) — ETA ~13:55Z
- **askeladd #2260** — aux Adam per-group ε asymmetric lm_head ε=1e-12 — ETA ~14:00Z
- **nezuko #2262** — PMuon cov EMA stride depth-stratified shallow=2/deep=1 — ETA ~14:10Z

### Tier-2: NS precision / spectral quality
- NS_ITERS depth-stratified spatial → edward #2239 (ETA ~13:55Z)
- NS5 coefficient per-role (attn vs mlp) → frieren #2276 (pending)

### Closed axes (do not repeat without new evidence)

**Body Muon scalar pulses (all boundaries):** LR-UP/DOWN, γ, μ, NS-coefs, β₁, β_cov, weight_decay, Nesterov, schedule-free, NS_ITERS reduction, per-block μ/LR burst

**NS5 phase switches:** polynomial coeff switch @2600 (alphonse #2219 closed), NS_ITERS cooldown schedule (#2162), NS5 coefficient pulses — EXHAUSTED at all tested phase boundaries

**paramEMA operator family:** refresh-step timing, warmup activation, refresh α (fern #2159), β-ramp shape (frieren #2163), post-NS update EMA (askeladd #2208) — ALL NULL

**Aux Adam state perturbations:** m+v hard-zero/partial-decay across all boundaries and scopes; β₁ UP/DOWN/JOINT (ALL directions); β₂ pulse timing (only @975 optimal); lm_head β₂ re-pulse @2600; per-group β₁ split (fern #2225 closed)

**Body PMuon momentum state:** hard-zero/scale/decay/blend/reverse-sign across all boundaries and depth subsets

**Body PMuon cov-state:** hard-zero/per-side-L/per-side-R across all temporal boundaries; β_cov rate sweeps (uniform + depth-split)

**Block-LR 2D subspace:** direction (late-higher WIN), magnitude (0.10/0.30 NULL), ramp shape (convex/concave NULL) — ALL exhausted

**PMuon γ ALL AXES:** uniform values, cooldown ramp, pre-target pulse, block-stratified, depth-split, attn vs MLP role-split, Frobenius ceiling (frieren #2226 closed) — ALL NULL. γ family FULLY EXHAUSTED.

---

## Plateau protocol: ENGAGED

6+ consecutive rounds without a merge. Strategy: per-group/per-block STRUCTURAL mechanisms (state-mixing, not just scalar differentiation), aux Adam input quality (pre-filter before β₁/β₂ accumulation), and NS5 coefficient spatial role differentiation. Next escalation if these close: consider NS5 spectral structure (polynomial shapes beyond Jordan/cubic-Newton), schedule-free body Muon, or DEFERRED Aurora with MLP row-norm CV gate check.

---

## Human directive #1252 (active)
Prioritize: (a) optimizer-state resets/rescaling at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss before step 2925. **AVOID pure scalar β/μ/EMA sweeps.**

## Human directive #2122 — Aurora optimizer (DEFERRED)
Lower priority for r1 due to architecture mismatch (requires SwiGLU; current stack uses ReLU²). Conditional reconsideration: if per-group/per-block axes exhausted AND MLP row-norm CV > 0.3.
