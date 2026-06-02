# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-06-02 10:10 UTC**
- **Current baseline:** PR #1532 — aux Adam β₂ pulse 0.95→0.99 @ step 975. val_ema=3.262854, sr=2875 (n=2 seeds `9coyk2ke`/`09qrijtm`)
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

---

## Active assignments (2026-06-02 10:10 UTC)

| Student | PR | Hypothesis | Status | Run IDs | Step / ETA |
|---|---|---|---|---|---|
| alphonse | #2219 | NS polynomial coeff phase-switch @2600 (Jordan vs near-identity) | Arm B `dvx59boz` running | `dvx59boz` | step 2700 / ETA ~10:50Z |
| fern | #2225 | Aux Adam per-group β₁ split lm_head — SLOW β₁=0.95 | Arm B `o1tjorcy` running | `o1tjorcy` | step 2050 / ETA ~11:35Z |
| frieren | #2226 | PMuon Frobenius ceiling γ=0.3 TIGHT | Arm B `g0oieeky` running | `g0oieeky` | step 2225 / ETA ~11:10Z |
| tanjiro | #2240 | Body-Muon mom SCALE-UP ×1.5 @2750 | Arm A `1wmi61gf` running | `1wmi61gf` | step 600 / ETA ~13:15Z |
| thorfinn | #2256 | Body-PMuon β₁ block-strat ramp LATE-HIGHER (shallow 0.925/deep 0.975) | Arm A `bi8753cc` running | `bi8753cc` | step 725 / ETA ~13:40Z |
| edward | #2239 | NS_ITERS block-stratified DEEP-heavy (shallow=12/deep=16) | Arm B `js2j0siu` running | `js2j0siu` | step 250 / ETA ~13:55Z |
| askeladd | #2260 | Aux Adam per-group ε asymmetric allocation — lm_head tight ε=1e-12 | Assigned (pending pickup) | — | — |
| nezuko | #2262 | PMuon cov EMA update stride stratified by depth — shallow=2/deep=1 | Assigned (pending pickup) | — | — |

---

## Recent closures (this session)

### PR #2208 askeladd — POST-NS update EMA on body PMuon ❌ BILATERAL NULL
- Arm A (uniform α=0.3) `o6ir57sd`: sr=2925, val_ema=3.265610 (+2.76 mnat)
- Arm B (block-varying α=0.1→0.5) `dj15lanu`: sr=2925, val_ema=3.266502 (+3.65 mnat)
- **Entire paramEMA operator family EXHAUSTED:** refresh α (#2159), β-ramp shape (#2163), post-NS update EMA (this) — all NULL.

### PR #2210 nezuko — lm_head β₂ SECOND PULSE @2600 ❌ BILATERAL NULL
- Arm A (β₂=0.99 @2600) `0b52z10c`: sr=2925, val_ema=3.264499 (+1.65 mnat)
- Arm B (β₂=0.999 @2600) `swjk6518`: sr=2925, val_ema=3.265939 (+3.09 mnat)
- **β₂ re-pulse @ late boundary axis CLOSED.** The @975 transition geometry is uniquely effective; does not generalize to @2600 even with lm_head scoping.

### PR #2171 thorfinn — Block-LR slope MAGNITUDE ❌ BILATERAL NULL + seed-2 regression
- Arm A (spread=0.10) n=1: sr=2925 val_ema=3.264335 (+1.48 mnat)
- Arm B (spread=0.30) n=2 mean: sr=2925 val_ema=3.266130 (+3.28 mnat); seed-2 hard regression (sr=2975, +5.89 mnat)
- **Per-block LR (direction × magnitude) 2D subspace FULLY BRACKETED AND CLOSED.**

### PR #2183 tanjiro — Aux Adam m-state HARD-ZERO RESET ❌ BILATERAL NULL
- Arm A (@2750) sr=2925 +2.24 mnat; Arm B (@1750) sr=2925 +2.44 mnat
- **Aux Adam m-state HARD-ZERO CLOSED** across all magnitudes, scopes, and temporal boundaries.

### PR #2180 edward — Block-LR ramp shape ❌ BILATERAL NULL
- Arm A (convex p=0.5) sr=2925 +3.49 mnat; Arm B (concave p=2.0) sr=2925 +2.10 mnat
- **Per-block LR ramp shape axis CLOSED.**

---

## New assignments (2026-06-02 10:00 UTC)

### askeladd PR #2260 — Aux Adam per-group ε asymmetric allocation
**Mechanism:** `eps_dominance_frac` telemetry (#1178) reveals structural asymmetry: embed ~0.69% ε-floor vs lm_head ~0.0015%. Bilateral test of which group benefits from ε=1e-12 in isolation.
- Arm A: `--aux_lm_head_eps 1e-12` (lm_head tight)
- Arm B: `--aux_embed_eps 1e-12` (embed tight)
- **Novel axis:** PR #1178 tested global uniform (NULL); PR #463 tested embed-only LOOSER. Asymmetric per-group differential allocation is pristine.

### nezuko PR #2262 — PMuon cov EMA update stride stratified by block depth
**Mechanism:** Shallow blocks (0-5) have more stationary gradient covariance; deep blocks (6-11) need fresh preconditioners during cooldown. Frequency-based axis (vs all prior rate-based β_cov axes).
- Arm A: `--cov_stride_shallow 2 --cov_stride_deep 1` (theory-consistent)
- Arm B: `--cov_stride_shallow 1 --cov_stride_deep 2` (inverted contrastive)
- **Novel axis:** All prior β_cov experiments changed EMA rate; none changed update frequency.

---

## Current research themes

### Tier-1: per-group/per-block differentiation in aux Adam and PMuon
The winning innovations all exploit asymmetric treatment: late-higher LR (block-depth), β₂ pulse (timing), paramEMA (phase-boundary). The remaining headroom is in unexploited asymmetries within the auxiliary Adam parameter groups and the PMuon covariance computation.

**Open sub-axes:**
- aux Adam per-group ε differential → askeladd #2260 (assigned)
- PMuon cov update frequency per block depth → nezuko #2262 (assigned)
- body-PMuon β₁ block-strat ramp → thorfinn #2256 Arm A bi8753cc (in flight, step 725)
- body-PMuon mom SCALE-UP @2750 → tanjiro #2240 Arm A 1wmi61gf (in flight, step 600)

### Tier-2: NS precision and phase-specific mechanism
- NS_ITERS depth-stratified spatial (shallow=12/deep=16) → edward #2239 Arm B `js2j0siu` (in flight, step 250, ETA ~13:55Z)
- NS polynomial coeff phase-switch @2600 → alphonse #2219 Arm B `dvx59boz` (in flight, step 2700, ETA ~10:50Z)

### Closed axes (do not repeat without new evidence)

**Body Muon scalar pulses (all boundaries):** LR-UP/DOWN, γ, μ, NS-coefs, β₁, β_cov, weight_decay, Nesterov, schedule-free, NS_ITERS reduction, per-block μ/LR burst

**paramEMA operator family:** refresh-step timing, warmup activation, refresh α (fern #2159), β-ramp shape (frieren #2163), post-NS update EMA (askeladd #2208) — ALL NULL

**Aux Adam state perturbations:** m+v hard-zero/partial-decay across all boundaries and scopes; β₁ UP/DOWN/JOINT (ALL directions); β₂ pulse timing (only @975 optimal); lm_head β₂ re-pulse @2600

**Body PMuon momentum state:** hard-zero/scale/decay/blend/reverse-sign across all boundaries and depth subsets

**Body PMuon cov-state:** hard-zero/per-side-L/per-side-R across all temporal boundaries; β_cov rate sweeps (uniform + depth-split); stride not yet tested → nezuko #2262

**Block-LR 2D subspace:** direction (late-higher WIN/late-lower NULL/uniform NULL), magnitude (spread=0.10/0.30 both NULL), ramp shape (convex/concave NULL) — ALL exhausted

**NS_ITERS:** cooldown schedule (→8/→4), coefficient pulses, ADOPT/Newton-Muon/ACProp — all NULL

### Plateau protocol: ENGAGED
5+ consecutive rounds without a merge. Current tier: per-group/per-block structural mechanisms and unexploited asymmetry axes.

---

## Human directive #1252 (active)
Prioritize: (a) optimizer-state resets/rescaling at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss before step 2925. **AVOID pure scalar β/μ/EMA sweeps.**

## Human directive #2122 — Aurora optimizer (DEFERRED)
Lower priority for r1 due to architecture mismatch (requires SwiGLU; current stack uses ReLU²). Conditional reconsideration: if per-group/per-block axes exhausted AND MLP row-norm CV > 0.3.
