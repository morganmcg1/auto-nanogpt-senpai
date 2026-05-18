# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 15:00 UTC
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

## Active experiments — 15:00 UTC

### 🔥 frieren #344 — NS late_peak transition point sweep — PAIRED CONFIRMATION RUNNING
**Branch:** `g1r4-frieren/ns-late-peak-frac-sweep`
**Original sweep + paired retry seeds:**
| Run | arm | frac | val_loss | fs |
|---|---|---|---|---|
| qtj0tkzo | A1 | 0.25 | 3.27095 | 3225 |
| nhbgfpta | B1 | 0.50 | 3.27514 | 3275 |
| 0qybug8m | C1 | 0.75 | 3.27164 | 3225 |
| **5plbo04e** | **A2 retry** | **0.25** | **3.27496** | 3275 |
| 7hqwnf6b | B2 retry | 0.50 | running step 1150 | - |

**Variance signal**: arm-A retry came in at 3.27496 vs original 3.27095 — **seed-to-seed Δ=+0.00401, roughly equal to the original within-pod Δ=−0.00419 signal**. Strong evidence the original signal was substantially pod luck. Paired Δ analysis pending B2 + A3/B3.
**ETA paired conf:** ~14:00–16:00 UTC.

### 🔥 alphonse #351 — Per-group SCALAR AdamW ε sweep — MIXED SIGNAL [arm D running]
**Branch:** `g1r4-alphonse/scalar-eps-sweep`
**Three of four arms in:**
| Arm | scalar_eps | val_loss | fs | Δ vs A | Δ vs baseline |
|---|---|---|---|---|---|
| A (control) | 1e-10 | 3.27528 | 3275 | — | +0.00328 (drift gate ✗ by 0.00028) |
| B | 1e-12 | 3.27317 | 3250 | −0.00211 | +0.00117 |
| C | 1e-8 | 3.27372 | 3250 | −0.00156 | +0.00172 |
| D | 1e-6 | running step 2675, val=3.352 | - | - | - |

**Reading**: arm-A drifted +0.00328 vs merged baseline (just over drift gate), so within-pod Δs may be partly drift correction. Both B and C absolute vals (3.27317, 3.27372) sit ABOVE baseline (3.27200) — neither is currently better than baseline. If D shows U-shape with apex at B (1e-12), worth paired confirmation. If monotone-down (D<C<B), extend to 1e-14.

### 🔄 askeladd #354 — Logit softcap value sweep [arm-D running]
**Branch:** `g1r4-askeladd/logit-softcap-sweep`
**Three of four arms in:**
| Arm | softcap | val_loss | fs | Δ vs A |
|---|---|---|---|---|
| A (control) | 15.0 | 3.27194 | 3225 | — (drift gate ✓ by 0.00006) |
| B | 10.0 | 3.27708 | 3300 | +0.00514 (worse) |
| C | 20.0 | 3.27561 | 3275 | +0.00367 (worse) |
| D | 25.0 | running step 925 | - | - |

**Reading**: softcap=15.0 (default) winning so far. Both adjacent values regress materially. Pre-staged: if D also regresses → productive-null close axis (softcap=15 optimal).

### 🔄 nezuko #356 — Muon μ schedule sweep [arm-D running]
**Branch:** `g1r4-nezuko/muon-mu-schedule`
**Three of four arms in:**
| Arm | schedule | μ | val_loss | fs | Δ vs A |
|---|---|---|---|---|---|
| A (control) | constant | 0.95 | 3.27048 | 3225 | — (drift gate ✓ −0.00152) |
| B | ramp_up 0.90→0.99 | 3.28429 | -1 | +0.01381 (much worse) |
| C | ramp_down 0.99→0.90 | 3.28083 | -1 | +0.01035 (much worse) |
| D | late_peak 0.90→0.99 | running step 100 | - | - |

**Reading**: μ scheduling broadly hurts. Both B (ramp_up) and C (ramp_down) failed to hit target. Pre-staged: if D also regresses → productive-null. Constant μ=0.95 looks like a genuine optimum.

### ✅ thorfinn #348 — Per-group AdamW WD sweep — CLOSED 15:15 UTC productive-null
All four arms terminal. Arms B/C/D all regress +0.0019–0.0025. Cross-group coupling observed (D shrinks embed_fro 5× more than B+C independently). AdamW WD axis closed on r4 (second verdict after #279 global WD).
**Follow-up**: thorfinn assigned #384 NS coef center sweep.

### 🔄 thorfinn #384 — NS poly coef CENTER sweep at depth=0.42 [just assigned]
**Branch:** `g1r4-thorfinn/ns-coef-center`
**Hypothesis**: the polynomial center (average c over iterations) has never been independently swept. merged linear_ramp_down (#290) has center=0.49 (average of 0.70 and 0.28). fern #345 found depth=0.42 optimal; now sweep center at that depth.
| Arm | center | start | end | Interpretation |
|---|---|---|---|---|
| A | 0.49 | 0.70 | 0.28 | current default (control) |
| B | 0.43 | 0.64 | 0.22 | gentler polynomial average |
| C | 0.55 | 0.76 | 0.34 | more aggressive average |
| D | 0.60 | 0.81 | 0.39 | extreme aggressive |

**ETA full chain:** ~7h.

### 🔄 edward #374 — Embed init scale sweep [arm-B running, near terminal]
**Branch:** `g1r4-edward/embed-init-scale`
**Two of four arms in:**
| Arm | init scale | val_loss | fs | Δ vs A |
|---|---|---|---|---|
| A (control) | 1.0 | 3.27421 | 3250 | — (drift gate ✓ +0.00221) |
| B | 0.5 | running step 2680, val=3.354 | - | - |

**ETA full chain:** 2 more arms after B terminal.

### 🔄 fern #380 — lm_head proj init std sweep [arm-A running]
**Branch:** `g1r4-fern/lmhead-init-scale`
**Setup verified:** student code edit present (`M records/track_3_optimization/train_gpt_simple.py`).
| Arm | init_std | val_loss | step | notes |
|---|---|---|---|---|
| A (control) | 0.0 | running step 1250, val=3.57 | 1250 | reproducing zero-init baseline |

**ETA full chain:** ~6h (4 arms).

### 🔄 tanjiro #377 — Pruning ablation [arm-A retry #5 running]
**Branch:** `g1r4-tanjiro/pruning-ablation`
**Status:** student has hit 4 crashes on arm-A control before getting a clean run going. Latest: a6gl5pm2 running step 670+. Config verified correct in W&B — crashes appear infrastructure-related (control arm = exact merged baseline stack).
**Advisor action 14:55 UTC:** posted supportive comment asking for crash cause notes; control config confirmed correct.
**ETA full chain (if no more crashes):** ~7h.

### ✅ fern #345 — NS coef ramp_down DEPTH sweep — CLOSED 14:10 UTC productive-null
**Follow-up**: fern assigned #380 lmhead-init-scale.

### ✅ tanjiro #300 — Embed floor value sweep — CLOSED 12:50 UTC productive-null
**Follow-up:** tanjiro assigned #377 pruning ablation.

---

## Recently closed

- **edward #335 (Muon LR cooldown floor)** — CLOSED 11:05 UTC productive-null. Monotonic worsening: A=3.27482 (+0), B=+0.001, C=+0.006, D=+0.017. Mechanism: embed-floor is embed-specific; Muon NS already controls update magnitude.
- **askeladd #324 (AdamW β1 sweep)** — CLOSED 08:35 UTC productive-null. β1=0.80 optimal, monotone-worse. Asymmetric with β2 finding.
- **nezuko #315 (lm_head steeper-decay cooldown)** — CLOSED 08:35 UTC productive-null. All steeper shapes regress +0.0031–0.0035. lm_head sweet spot is linear.
- **frieren #285 (NS cooldown SHAPE)** — MERGED ✅ 06:02 UTC. val=3.27352 (n=2). late_peak concentrates NS=20 into lowest-LR half of cooldown.
- **fern #290 (NS coef schedule)** — MERGED ✅ 06:07 UTC. val=3.27200 (n=3). linear_ramp_down starts NS at high-precision coefficients, ramps toward standard.
- **fern #345 (NS coef depth sweep)** — CLOSED 14:10 UTC productive-null. depth=0.42 confirmed optimal. Asymmetric plateau: steep side flat, shallow side regresses +0.00390.
- **tanjiro #300 (embed floor=0.20)** — CLOSED 12:50 UTC productive-null. floor=0.20 absorbed by late_peak + linear_ramp_down. embed-floor ⊆ late-cooldown-precision family. 9 seeds total.
- **thorfinn #279 (AdamW WD=0.005)** — CLOSED 07:12 UTC productive-null. β2=0.99 absorbed standalone gain.
- **alphonse #322 (AdamW global ε)** — CLOSED 07:48 UTC productive-null. β2=0.99 smoothing already stabilizes denominator.

---

## Potential next research directions

### Active candidates with signal
1. **NS late_peak frac=0.25** — frieren #344. Paired-confirm in flight; A2 retry (val=3.27496) showed +0.00401 vs original A1 (3.27095) → original signal likely substantially pod luck. Wait for B2 + A3/B3.
2. **scalar AdamW ε=1e-12** — alphonse #351. Within-pod ΔB=−0.00211, ΔC=−0.00156, but arm-A drifted +0.00328 above baseline (just over drift gate). Absolute B (3.27317) and C (3.27372) both ABOVE baseline (3.27200). D pending — interpret cautiously, may need paired confirmation.

### Productive-null shaping up
3. **Logit softcap value** — askeladd #354. softcap=15 (default) winning. B (10) and C (20) both regress materially. D (25) pending.
4. **Muon μ schedule** — nezuko #356. μ scheduling broadly hurts. Both ramp_up and ramp_down arms didn't hit target. D (late_peak μ schedule) pending.
5. **Per-group AdamW WD** — thorfinn #348. CLOSED 15:15 UTC. All arms regress +0.0019–0.0025. AdamW WD axis closed on r4 (2nd consecutive verdict).
6. **Embed init scale** — edward #374. Arm-A drift gate ✓. Arm-B running.

### Fresh axes (early stage)
7. **lm_head proj init std** — fern #380. Arm-A (zero-init control) running. Sweep σ ∈ {0.0, 0.005, 0.02, 0.05}. Fresh init axis.
8. **Pruning ablation** — tanjiro #377. Arm-A retry #5 after 4 control crashes. Once stable, drop one of {late_peak, linear_ramp_down, β2=0.99}.
9. **NS coef center** — thorfinn #384. Sweep center ∈ {0.43, 0.49, 0.55, 0.60} at depth=0.42 (apex from fern #345). Polynomial aggressiveness axis never tested.

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
- **Both live signal candidates weakened on 2nd-seed data**: #344 frieren A-retry showed +0.00401 variance (≈ original signal magnitude); #351 alphonse arm-A drifted above gate making within-pod Δs harder to interpret.
- **Most current arms shaping toward productive-null** — likely cycle's outcome is mechanism-mapping rather than new merges.

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
| NS coef depth (fern) | depth=0.42 confirmed apex, asymmetric plateau | #345 (productive-null) |
| AdamW WD (global) | global WD=0.005 absorbed by β2=0.99 | #279 (null) |
| AdamW WD (per-group) | per-group WD=0.002 on lm_head, scalar, or both — all harmful | #348 (harmful) |
