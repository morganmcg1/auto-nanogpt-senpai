# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 12:40 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate)

## Current merged baseline — post-#290

**val=3.27200 / fs=3233.33 (n=3 mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
```

### Merged stack history

| PR | Change | val (n) | fs (n) | Cumulative baseline |
|----|--------|---------|--------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3275 | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3266.7 | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3258.3 | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3266.7 | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3266.7 | 3.27434 |
| #236 | AdamW β2=0.99 | 3.27407 (3) | 3258.3 | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3250 | 3.27352 |
| **#290** | **NS coef schedule=linear_ramp_down** | **3.27200 (3)** | **3233.33** | **3.27200** ← CURRENT |

### Mechanism landscape (8 merges, largely orthogonal axes)

1. **Muon² v-EMA** (#60): second-moment before NS orthogonalization
2. **Grad clip** (#165): embed effective-LR raise (8.4% → 16.9%)
3. **NS timing** (#176): more NS iters during precision-critical cooldown
4. **Embed LR floor** (#235): hold embed at 15% of peak through final 30% of training
5. **AdamW β2** (#236): longer second-moment memory (20 → 100 step) smooths step sizes
6. **NS cooldown SHAPE** (#285): NS=12→20 transition at midpoint of cooldown (late_peak)
7. **NS coef schedule** (#290): linear ramp-down of NS polynomial coefficients over training

---

## Active experiments — 12:40 UTC

### 🔥 frieren #344 — NS late_peak transition point sweep — PAIRED CONFIRMATION REQUESTED
**Branch:** `g1r4-frieren/ns-late-peak-frac-sweep`
**Sweep complete (n=1 each):**
| Arm | frac | val_loss | fs | Δ vs B | Δ vs baseline |
|---|---|---|---|---|---|
| A | 0.25 | **3.27095** | 3225 | **−0.00419** | −0.00105 |
| B | 0.50 | 3.27514 | 3275 | — (control) | +0.00314 (drift) |
| C | 0.75 | 3.27164 | 3225 | **−0.00350** | −0.00036 |

**Reading**: A and C both beat B (likely pod-unlucky on B, drift gate over by 0.00014). Strongest within-pod signal this cycle. A−C only −0.00069 apart, so true U-shape unlikely; most parsimonious read = "frac=0.25 is a real improvement; B was unlucky".
**Path:** Sent back 12:30 UTC for **paired confirmation**: 2 fresh pods × frac=0.25→frac=0.50 back-to-back per pod (4 runs total). Combined with original sweep → n=3 for both arms, paired Δ n=3. Merge if mean(frac=0.25)≤3.27200 AND paired Δ mean≤−0.002 AND stat-rule satisfied.
**ETA paired conf:** ~7h.

### 🔄 fern #345 — NS coef ramp_down DEPTH sweep [arm-D running]
**Branch:** `g1r4-fern/ns-coef-ramp-depth`
**Three of four arms in:**
| Arm | depth | val_loss | fs | Δ vs A |
|---|---|---|---|---|
| A (control) | 0.42 | **3.27276** | 3250 | — |
| B | 0.30 (shallower) | 3.27666 | 3300 | **+0.00390** (worse) |
| C | 0.55 (steeper) | 3.27398 | 3250 | +0.00122 (within null band) |

**Reading**: Interior optimum forming near depth=0.42 (current default). Asymmetric — shallower hurts more than steeper. arm-D (depth=0.70, much steeper) ETA ~13:52 UTC will close the picture.
**Likely outcome**: Productive-null with apex at 0.42 → confirms current default optimal. Close axis.

### 🔥 alphonse #351 — Per-group SCALAR AdamW ε sweep — SIGNAL CANDIDATE [arms C,D running]
**Branch:** `g1r4-alphonse/per-group-scalar-eps`
**Two of four arms in:**
| Arm | scalar_eps | val_loss | fs | Δ vs A |
|---|---|---|---|---|
| A (control) | 1e-10 | 3.27528 | 3275 | — |
| B | 1e-12 (lower) | **3.27317** | 3250 | **−0.00211** (signal candidate!) |

**Reading**: arm-B just past the −0.002 signal gate. Lower scalar ε helps — consistent with #280 per-group β2 finding (scalar group wants tighter normalization).
**Pre-staged decision tree**:
- C & D both worse → monotone-down → extend to 1e-14
- C better, D worse → interior optimum → finer grid
- All within ±0.0015 of A → arm-B was pod-lucky, close axis
**ETA full chain:** C ~13:25 UTC, D ~15:10 UTC.

### ⚠️ tanjiro #300 — Embed floor value sweep — LIKELY PRODUCTIVE-NULL [seed-2 finishing]
**Status:** Pre-stack n=3 mean=3.27184 (Δ=−0.00016). Re-conf on full post-#290 stack:
- seed-1 (vvndpgmx): val=**3.27521**, Δ=+0.00321 → REGRESS
- seed-2 (mr6za83o): in flight, ETA ~12:25 UTC

**Reading**: First post-#290 sample regresses by +0.00321. For n=2 mean ≤ 3.27300, seed-2 needs val ≤ 3.27079 (below every prior sample on this recipe). Probability low.
**Likely outcome**: Productive-null close — floor=0.20 absorbed by stacked late-cooldown precision levers (late_peak + linear_ramp_down + β2=0.99). The single-feature signal does NOT survive composition.

### 🔄 thorfinn #348 — Per-group AdamW WD sweep [arm-C running]
**Branch:** `g1r4-thorfinn/per-group-adamw-wd`
**Two of four arms in:**
| Arm | wd config | val_loss | Δ vs A |
|---|---|---|---|
| A (control) | all-zero | 3.27143 | — |
| B | lm_head WD=0.002 | 3.27396 | +0.00253 (worse) |

**Reading**: lm_head WD hurts (consistent with #279 closing global WD as null). arm-C (scalar WD=0.002) and arm-D (combo) remain.
**ETA full chain:** ~15:00 UTC.

### 🔄 askeladd #354 — Logit softcap value sweep [arm-B running]
**Branch:** `g1r4-askeladd/logit-softcap-value`
**One of four arms in:**
| Arm | softcap | val_loss | Δ vs baseline |
|---|---|---|---|
| A (control) | 15.0 | 3.27194 | −0.00006 (drift gate ✓) |

**ETA full chain:** ~17:30 UTC.

### 🔄 nezuko #356 — Muon μ schedule sweep [arm-B running]
**Branch:** `g1r4-nezuko/muon-mu-schedule`
**One of four arms in:**
| Arm | schedule | μ | val_loss | Δ vs baseline |
|---|---|---|---|---|
| A (control) | constant | 0.95 | 3.27048 | −0.00152 (drift gate ✓) |

**ETA full chain:** ~17:30 UTC.

### 🔄 edward #374 — Embed init scale sweep [implementation fixed, arm-A running]
**Branch:** `g1r4-edward/embed-init-scale`
**Implementation note**: Student caught a bug — the assignment's `__init__` placement would have been overwritten by the per-trial re-init loop at line 822. Student correctly placed `w.mul_(NANOGPT_EMBED_INIT_SCALE)` immediately after `w.normal_()` in that loop. Verified with `model.embed.weight.norm()` sanity print.
**ETA full chain:** ~7h.

---

## Recently closed

- **edward #335 (Muon LR cooldown floor)** — CLOSED 11:05 UTC productive-null. Monotonic worsening: A=3.27482 (+0), B=+0.001, C=+0.006, D=+0.017. Mechanism: embed-floor is embed-specific; Muon NS already controls update magnitude.
- **askeladd #324 (AdamW β1 sweep)** — CLOSED 08:35 UTC productive-null. β1=0.80 optimal, monotone-worse. Asymmetric with β2 finding.
- **nezuko #315 (lm_head steeper-decay cooldown)** — CLOSED 08:35 UTC productive-null. All steeper shapes regress +0.0031–0.0035. lm_head sweet spot is linear.
- **frieren #285 (NS cooldown SHAPE)** — MERGED ✅ 06:02 UTC. val=3.27352 (n=2). late_peak concentrates NS=20 into lowest-LR half of cooldown.
- **fern #290 (NS coef schedule)** — MERGED ✅ 06:07 UTC. val=3.27200 (n=3). linear_ramp_down starts NS at high-precision coefficients, ramps toward standard.
- **thorfinn #279 (AdamW WD=0.005)** — CLOSED 07:12 UTC productive-null. β2=0.99 absorbed standalone gain.
- **alphonse #322 (AdamW global ε)** — CLOSED 07:48 UTC productive-null. β2=0.99 smoothing already stabilizes denominator.

---

## Potential next research directions

### Active candidates with signal
1. **NS late_peak frac=0.25** — frieren #344. Within-pod Δ=−0.00419. Paired confirmation in flight. If confirmed → merge candidate.
2. **scalar AdamW ε=1e-12** — alphonse #351. Within-pod Δ=−0.00211 (single pair). Need C/D + paired confirmation.

### Currently null/marginal
3. **NS coef depth** — fern #345. Apex at depth=0.42 (control); D pending. Likely close as confirmed-optimal.
4. **Embed floor value** — tanjiro #300. Re-conf seed-1 regress on post-#290. Likely close productive-null.
5. **lm_head WD** — thorfinn #348 arm-B null. arms C/D outstanding.

### Fresh axes (early stage)
6. **Logit softcap value** — askeladd #354. Drift gate passed. Arms B/C/D outstanding.
7. **Muon μ schedule** — nezuko #356. Drift gate passed. Arms B/C/D outstanding.
8. **Embed init scale** — edward #374. Implementation fixed. Full sweep outstanding.

### Medium-priority unassigned axes (for next idle)
9. **NS coef mean sweep** — once fern #345 closes, sweep c_mean {0.45/0.49/0.53/0.57} at depth=0.42
10. **AdEMAMix on aux groups** — triple-EMA long-memory mechanism; compatible with β2=0.99
11. **Per-group μ ablation** — after nezuko #356 lands; per-group μ (parallels per-group β2 from #280)
12. **NS cooldown 3-phase** — extend late_peak to 3-phase (12→15→20 within cooldown window)
13. **Output proj init scale** — pairs with edward #374; proj has no RMSNorm so direct logit influence

### What we know about stacking
- 7 merges across orthogonal axes; gap to 3030 steps ~200 steps in fs
- Closed naive hparam sweeps (β1, global WD, global ε, lm_head steeper decay)
- Fresh mechanism exploration (schedule axes, init, output layer) remains the priority
- **Two live signal candidates** (#344 frieren, #351 alphonse) — current cycle's primary merge candidates

---

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape (global) | cosine, sqrt, quadratic, exp | #204 |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style BC in Muon² | BC + beta2=0.98 (bundled) | #115 |
| NS=8 floor test | constant NS=8 | #75 |
| NS high-early anneal | NS=14→8 | #185 |
| Uniform aux LR scaling | 0.5× / 1.5× embed/lm_head/scalar | #188 |
| Muon² eps floor | sweep 1e-9 to 1e-6 | #189 |
| Per-group Muon clip | per-group clip dispatch at clip=10 | #206 |
| AdamW β1 cooldown schedule | β1 linear decay schedule | #227 (null) |
| lm_head + scalar cooldown floor | floor=15% on non-embed aux | #266 (HURTS) |
| Muon mu=0.97 (constant) | within-pod Δ=−0.00289 but cross-pod fail | #241 (productive-null) |
| Muon LR cooldown floor | embed-floor mechanism on Muon | #335 (monotonic worsening) |
| AdamW β1 (constant) sweep | β1 ∈ {0.8, 0.85, 0.9, 0.95} | #324 (monotone) |
| lm_head steeper-decay shape | floor/steep alternatives | #315 (all worse) |
| NS cooldown SHAPE (frieren) | late_peak wins — MERGED #285 | — |
| NS coef schedule (fern) | linear_ramp_down wins — MERGED #290 | — |
