# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-06-02 11:10 UTC**
- **Current baseline:** PR #1532 — aux Adam β₂ pulse 0.95→0.99 @ step 975. val_ema=3.262854, sr=2875 (n=2 seeds `9coyk2ke`/`09qrijtm`)
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

---

## Active assignments (2026-06-02 11:10 UTC)

| Student | PR | Hypothesis | Status | Run IDs | Step / ETA |
|---|---|---|---|---|---|
| alphonse | #2269 | Aux Adam pre-update gradient EMA (α=0.90 vs α=0.95) | Assigned (pending pickup) | — | — |
| fern | #2225 | Aux Adam per-group β₁ split lm_head — SLOW β₁=0.95 | Arm B `o1tjorcy` running | `o1tjorcy` | step 2375 / ETA ~11:35Z |
| frieren | #2226 | PMuon Frobenius ceiling γ=0.3 TIGHT | Arm B `g0oieeky` running | `g0oieeky` | step 2625 / ETA ~11:10Z |
| tanjiro | #2240 | Body-Muon mom SCALE-UP ×1.5 @2750 | Arm A `1wmi61gf` running | `1wmi61gf` | step 1000 / ETA ~13:15Z |
| thorfinn | #2256 | Body-PMuon β₁ block-strat ramp LATE-HIGHER (shallow 0.925/deep 0.975) | Arm A `bi8753cc` running | `bi8753cc` | step 1000 / ETA ~13:40Z |
| edward | #2239 | NS_ITERS block-stratified DEEP-heavy (shallow=12/deep=16) | Arm B `js2j0siu` running | `js2j0siu` | step 500 / ETA ~13:55Z |
| askeladd | #2260 | Aux Adam per-group ε asymmetric allocation — lm_head tight ε=1e-12 | Arm A `oeto14li` running | `oeto14li` | step 125 / ETA ~14:00Z |
| nezuko | #2262 | PMuon cov EMA update stride stratified by depth — shallow=2/deep=1 | Arm A `msudbd0c` running | `msudbd0c` | step 100 / ETA ~14:10Z |

---

## Recent closures (this session, 2026-06-02)

### PR #2219 alphonse — NS polynomial coeff phase-switch @2600 ❌ BILATERAL NULL
- Arm A (Jordan 3.4445, -4.775, 2.0315) `wd0eshy6`: sr=2925, val_ema=3.265670 (+2.82 mnat)
- Arm B (near-identity 1.0, -0.1, 0.0) `dvx59boz`: sr=2925, val_ema=3.264005 (+1.15 mnat)
- **NS polynomial phase-switch axis CLOSED.** The pEMA refresh boundary at step 2600 does not generalize as a phase-switch lever for NS5 coefficients. Different from the aux β₂ WIN which is specific to v_t recalibration at cooldown onset.

### PR #2208 askeladd — POST-NS update EMA on body PMuon ❌ BILATERAL NULL
- Arm A (uniform α=0.3) `o6ir57sd`: sr=2925, val_ema=3.265610 (+2.76 mnat)
- Arm B (block-varying α=0.1→0.5) `dj15lanu`: sr=2925, val_ema=3.266502 (+3.65 mnat)
- **Entire paramEMA operator family EXHAUSTED.**

### PR #2210 nezuko — lm_head β₂ SECOND PULSE @2600 ❌ BILATERAL NULL
- Arm A (β₂=0.99 @2600) `0b52z10c`: sr=2925, val_ema=3.264499 (+1.65 mnat)
- Arm B (β₂=0.999 @2600) `swjk6518`: sr=2925, val_ema=3.265939 (+3.09 mnat)
- **β₂ re-pulse @ late boundary axis CLOSED.**

### PR #2171 thorfinn — Block-LR slope MAGNITUDE ❌ BILATERAL NULL + seed-2 regression
- **Per-block LR (direction × magnitude) 2D subspace FULLY EXHAUSTED.**

### PR #2183 tanjiro — Aux Adam m-state HARD-ZERO RESET ❌ BILATERAL NULL
- **Aux Adam m-state HARD-ZERO CLOSED** across all magnitudes, scopes, and temporal boundaries.

### PR #2180 edward — Block-LR ramp shape ❌ BILATERAL NULL
- **Per-block LR ramp shape axis CLOSED.**

---

## Current research themes

### Tier-1: per-group/per-block differentiation and aux Adam input quality

The winning innovations all exploit asymmetric treatment: late-higher LR (block-depth), β₂ pulse (timing), paramEMA (phase-boundary). Current frontier: per-group ε asymmetry and PMuon covariance frequency, plus a new vector — the quality of what enters the aux Adam accumulators before β₁/β₂ process it.

**Open sub-axes:**
- aux Adam pre-update gradient EMA → alphonse #2269 (assigned, pending pickup)
- aux Adam per-group ε differential → askeladd #2260 Arm A `oeto14li` (step 125)
- PMuon cov update frequency per block depth → nezuko #2262 Arm A `msudbd0c` (step 100)
- PMuon Frobenius ceiling TIGHT γ=0.3 → frieren #2226 Arm B `g0oieeky` (step 2625, terminal ~11:10Z)
- aux Adam β₁ split lm_head SLOW 0.95 → fern #2225 Arm B `o1tjorcy` (step 2375, terminal ~11:35Z)
- body-PMuon β₁ block-strat ramp → thorfinn #2256 Arm A `bi8753cc` (step 1000, ETA ~13:40Z)
- body-PMuon mom SCALE-UP @2750 → tanjiro #2240 Arm A `1wmi61gf` (step 1000, ETA ~13:15Z)

### Tier-2: NS precision
- NS_ITERS depth-stratified spatial (shallow=12/deep=16) → edward #2239 Arm B `js2j0siu` (step 500, ETA ~13:55Z)

### Closed axes (do not repeat without new evidence)

**Body Muon scalar pulses (all boundaries):** LR-UP/DOWN, γ, μ, NS-coefs, β₁, β_cov, weight_decay, Nesterov, schedule-free, NS_ITERS reduction, per-block μ/LR burst

**NS5 phase switches:** polynomial coeff switch @2600 (alphonse #2219 just closed), NS_ITERS cooldown schedule (#2162), NS5 coefficient pulses — EXHAUSTED at all tested phase boundaries

**paramEMA operator family:** refresh-step timing, warmup activation, refresh α (fern #2159), β-ramp shape (frieren #2163), post-NS update EMA (askeladd #2208) — ALL NULL

**Aux Adam state perturbations:** m+v hard-zero/partial-decay across all boundaries and scopes; β₁ UP/DOWN/JOINT (ALL directions); β₂ pulse timing (only @975 optimal); lm_head β₂ re-pulse @2600

**Body PMuon momentum state:** hard-zero/scale/decay/blend/reverse-sign across all boundaries and depth subsets

**Body PMuon cov-state:** hard-zero/per-side-L/per-side-R across all temporal boundaries; β_cov rate sweeps (uniform + depth-split)

**Block-LR 2D subspace:** direction (late-higher WIN), magnitude (0.10/0.30 NULL), ramp shape (convex/concave NULL) — ALL exhausted

**PMuon γ ALL AXES:** uniform values, cooldown ramp, pre-target pulse, block-stratified, depth-split, attn vs MLP role-split — ALL NULL. Currently testing: Frobenius ceiling (frieren #2226).

---

## Plateau protocol: ENGAGED

5+ consecutive rounds without a merge. Strategy: per-group/per-block structural mechanisms + aux Adam input quality (pre-filter before β₁/β₂ accumulation). Next escalation if these close: NS5 spectral structure and schedule-free body Muon.

---

## Human directive #1252 (active)
Prioritize: (a) optimizer-state resets/rescaling at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss before step 2925. **AVOID pure scalar β/μ/EMA sweeps.**

## Human directive #2122 — Aurora optimizer (DEFERRED)
Lower priority for r1 due to architecture mismatch (requires SwiGLU; current stack uses ReLU²). Conditional reconsideration: if per-group/per-block axes exhausted AND MLP row-norm CV > 0.3.
