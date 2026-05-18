# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 22:45 UTC
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

### ✅ frieren #344 — NS late_peak transition point sweep — CLOSED 20:00 UTC productive-null
Pod-1 Δ=−0.00419 collapsed to n=3 pooled Δ=−0.000877 (79% shrinkage). Sign flipped on pod 2 (+0.00278). Per-arm seed spread (0.00401) larger than claimed signal. Midpoint (frac=0.50) confirmed optimal on post-#290 stack; NS late_peak transition POINT axis CLOSED.
**Follow-up**: frieren assigned #402 Gradient Centralization scope sweep.

### 🔄 frieren #402 — Gradient Centralization (GC) scope sweep [just assigned]
**Branch:** `g1r4-frieren/gradient-centralization`
**Hypothesis**: GC (Yong et al. 2020) subtracts mean gradient along non-output dims before optimizer step. Operates at gradient preprocessing abstraction layer — orthogonal to all per-group AdamW/NS/Muon/init work. Sweep by scope to map where GC helps.
| Arm | GC_ENABLED | GC_SCOPE | Interpretation |
|---|---|---|---|
| A | 0 | — | No GC, drift gate |
| B | 1 | all | GC on AdamW + Muon weights |
| C | 1 | adam | GC on embed + lm_head only |
| D | 1 | muon | GC on block weights only |

**ETA full chain:** ~7h.

### 🔥 alphonse #351 — Per-group SCALAR AdamW ε sweep — SENT BACK 15:34 UTC for paired confirmation
**Branch:** `g1r4-alphonse/scalar-eps-sweep` (next: `g1r4-alphonse/scalar-eps-confirm`)
**All four arms terminal — non-monotone "all-perturbations-help" pattern**:
| Arm | scalar_eps | val_loss | fs | Δ vs A | Δ vs baseline |
|---|---|---|---|---|---|
| A (control) | 1e-10 | 3.27528 | 3275 | — | +0.00328 (drift gate ✗) |
| B | 1e-12 | 3.27317 | 3250 | −0.00211 | +0.00117 |
| C | 1e-8 | 3.27372 | 3250 | −0.00156 | +0.00172 |
| D | 1e-6 | **3.27250** | 3250 | **−0.00278** | +0.00050 |

**Reading**: Non-monotone (B and D both help, C in between, A worst). All non-A arms have fs=3250 — uniform 25-step gap suggests A pod-luck. Most parsimonious read: arm-A drifted; arms B/C/D would be within ±0.0015 if A were on baseline.
**Path**: Paired-pod confirmation requested — 2 fresh pods × {A, D} back-to-back (with order flipped on pod 2). n=3 paired observations after combining with original A+D. Pre-staged: mean(D, n=3) ≤ baseline AND paired Δ ≤ −0.002 → real signal; otherwise → productive-null.
**ETA paired conf:** ~7h.

### ✅ askeladd #354 — Logit softcap value sweep — CLOSED 16:35 UTC productive-null
Valley shape: all 3 off-center arms regress (+0.0037–0.0051). C≈D plateau above softcap=20 (softcap linear in that regime). softcap=15 confirmed optimal on post-#290 stack.
**Follow-up**: askeladd assigned #388 NS iter count cooldown sweep.

### 🔄 askeladd #388 — NS_ITERS_COOLDOWN sweep at fixed NS_ITERS=12 [just assigned]
**Branch:** `g1r4-askeladd/ns-iters-cooldown`
**Hypothesis**: ns_cooldown=16 was set by #176 on pre-#290 stack; never retested with the new late_peak shape + linear_ramp_down coef schedule. Higher count → more precise orthogonalization in latter 15% of training.
| Arm | NS_ITERS_COOLDOWN | Peak iters (latter half of cooldown) |
|---|---|---|
| A | 16 | 20 (current, control) |
| B | 14 | 16 |
| C | 18 | 24 |
| D | 20 | 28 |

**ETA full chain:** ~7–8h (arm D wall-time slightly longer due to more NS iters/step).

### ✅ nezuko #356 — Muon μ schedule sweep — CLOSED 17:05 UTC productive-null
All 3 schedule arms missed 3.28 target entirely: B ramp_up +0.01381, C ramp_down +0.01035, D late_peak +0.06125 (catastrophic). Late_peak μ scheduling disastrous — cross-step gradient memory is different from within-step NS precision. Constant μ=0.95 confirmed optimal; Muon μ scheduling axis CLOSED.
**Follow-up**: nezuko assigned #393 per-group AdamW LR multiplier sweep.

### 🔥 nezuko #393 — Per-group AdamW LR multiplier sweep — STRONG WINNER CANDIDATE on arm-B
**Branch:** `g1r4-nezuko/pergroup-adamw-lr`
**Arms terminal so far (W&B verified)**:
| Arm | LR mult | val | fs | Δ vs A | Δ vs baseline | W&B |
|---|---|---|---|---|---|---|
| A (control) | all 1.0× | 3.27242 | 3250 | — | +0.00042 (drift ✓) | `oggbt72v` |
| **B (embed1p5)** | **embed=1.5×** | **3.27026** | **3225** | **−0.00216** | **−0.00174** ⭐ | `cgyyzpwe` |
| C (lmhead1p5) | lm_head=1.5× | running step ~1250 | - | - | - | `kwt7wjzi` |
| D (scalar1p5) | scalar=1.5× | pending | - | - | - | - |

**ARM-B SIGNAL**: Δ vs A=−0.00216 crosses real-signal threshold. Single-seed merge gate: (3.28 − 3.27026) × √1 = 0.00974 ≥ 0.004 ✓ PASSES. Posted ADVISOR directive 22:35 UTC: after D terminates, request **paired-pod confirmation for arm-B vs arm-A** (2 fresh pods, order-flipped).
**ETA full chain finish:** ~02:00 UTC.

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

### ✅ edward #374 — Embed init scale sweep — CLOSED 19:30 UTC productive-null
Clean flat result: all 4 arms within ±0.00027 of A (except B at −0.00061, still inside null band). RMSNorm + AdamW β2=0.99 + grad clip absorb embed magnitude — final norms converge to ~77k within 1.8% regardless of 4× init range. Embed init scale axis CLOSED.
**Follow-up**: edward assigned #399 AdEMAMix on AdamW groups.

### 🔄 edward #399 — AdEMAMix on AdamW groups [just assigned]
**Branch:** `g1r4-edward/ademamix-adamw`
**Hypothesis**: Adds slow gradient EMA (beta3=0.9999, ~10000-step memory window) alongside standard AdamW fast EMA. Sweep alpha_max ∈ {0, 2, 5, 8} (α=0 = vanilla AdamW control). Paper: Pagliardini et al. NeurIPS 2024.
| Arm | alpha_max | Interpretation |
|---|---|---|
| A | 0 (vanilla) | Control, drift gate |
| B | 2.0 | Mild AdEMAMix |
| C | 5.0 | Paper default |
| D | 8.0 | Aggressive |

**Note**: AdEMAMix uses Python loop (no fused=True) → ~10-20% slower step_avg_ms, but metric is first_step_to_target (step count), so comparison is fair.
**ETA full chain:** ~7.5h.

### ✅ fern #380 — lm_head proj init std sweep — CLOSED 22:40 UTC productive-null
All 4 arms terminal. Monotone worsening with σ: A=3.27409 (zero, drift gate ✓), B=3.27470 (σ=0.005, +0.00061), C=3.27725 (σ=0.02, +0.00316), D=3.28234 (σ=0.05, +0.00825, fs=-1 failed target). **Zero-init confirmed uniquely optimal** — both init-scale axes (embed #374, lm_head #380) now exhaustively mapped.
**Follow-up**: fern assigned #408 Adaptive Gradient Clipping (AGC).

### 🔄 fern #408 — Adaptive Gradient Clipping (AGC) [just assigned]
**Branch:** `g1r4-fern/adaptive-grad-clip`
**Hypothesis**: Replace fixed clip=10.0 with per-parameter AGC (Brock et al. 2021, NFNets) — clip threshold = λ × ||W||_F. Scales with parameter magnitude. Sweep λ ∈ {0 control, 0.01, 0.03, 0.1}.
| Arm | AGC_LAMBDA | Interpretation |
|---|---|---|
| A | 0 (control) | Falls through to fixed clip=10.0, drift gate |
| B | 0.01 | Conservative AGC (tight clip) |
| C | 0.03 | Paper default (moderate AGC) |
| D | 0.1 | Loose AGC (rarely clips) |

**ETA full chain:** ~7h.

### ✅ tanjiro #377 — Pruning ablation — CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE)
All 4 arms terminal. **Key mechanism findings**: (1) **β2=0.99 is amplified — 5.9× original lift magnitude**; (2) late_peak #285 subsumed (Δ=−0.00043, sign-flipped vs original); (3) linear_ramp_down #290 fully subsumed (Δ=+0.00009, ~0% original lift). 2 of 3 recent merges appear redundant on current stack — consistent with "mechanism saturation within late-cooldown precision family" hypothesis.
**Follow-up**: tanjiro assigned #407 β2 fine-tune sensitivity sweep (mechanism-driven by β2 amplification finding).

### 🔄 tanjiro #407 — AdamW β2 sensitivity sweep [just assigned]
**Branch:** `g1r4-tanjiro/adamw-beta2-sensitivity`
**Hypothesis**: Pruning ablation revealed β2=0.99 is amplified 5.9× over original lift. Optimum may have drifted on post-#290 stack. Sweep β2 ∈ {0.98, 0.99, 0.995, 0.999} to test sensitivity.
| Arm | β2 | EMA window | Interpretation |
|---|---|---|---|
| A | 0.99 (control) | ~100 steps | Current baseline; drift gate |
| B | 0.98 | ~50 steps | Shorter; faster adaptation |
| C | 0.995 | ~200 steps | Longer; more smoothing |
| D | 0.999 | ~1000 steps | Very long; high-noise-floor smoothing |

**ETA full chain:** ~7h.

### ✅ fern #345 — NS coef ramp_down DEPTH sweep — CLOSED 14:10 UTC productive-null
**Follow-up**: fern assigned #380 lmhead-init-scale.

### ✅ tanjiro #300 — Embed floor value sweep — CLOSED 12:50 UTC productive-null
**Follow-up:** tanjiro assigned #377 pruning ablation.

---

## Recently closed

- **tanjiro #377 (Pruning ablation)** — CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE). β2=0.99 amplified 5.9× original lift (load-bearing); late_peak (#285) and linear_ramp_down (#290) appear subsumed on current stack.
- **fern #380 (lm_head init std)** — CLOSED 22:40 UTC productive-null. Monotone worsening with σ; zero-init uniquely optimal. Init-scale axis closed across both embed (#374) and lm_head (this PR).
- **nezuko #356 (Muon μ schedule)** — CLOSED 17:05 UTC productive-null. All 3 schedule arms miss target by 7–41× null band. Late_peak μ catastrophic (+0.06125). Constant μ=0.95 confirmed optimal; μ scheduling axis closed.
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
1. **Per-group AdamW LR (embed=1.5×)** — nezuko #393 arm-B. Val=3.27026, Δ vs A=−0.00216, Δ vs baseline=−0.00174, fs=3225 (−8.33). Single-seed merge gate PASSES. Awaiting arms C and D, then paired-pod confirmation requested.
2. **Gradient Centralization scope** — frieren #402. Fresh mechanism (gradient preprocessing). Scope sweep: all, adam-only, muon-only. Orthogonal to all closed axes.
2. **scalar AdamW ε** — alphonse #351. SENT BACK 15:34 UTC for paired confirmation. Original sweep non-monotone (arm-A drift makes within-pod Δs unreliable). Paired arm-D (1e-6) vs arm-A (1e-10) on 2 fresh pods with flipped order to disambiguate pod luck from real signal.

### Productive-null shaping up
3. **Logit softcap value** — askeladd #354. CLOSED 16:35 UTC. softcap=15 confirmed optimal (valley shape). Axis closed.
4. **Muon μ schedule** — nezuko #356. CLOSED 17:05 UTC productive-null. All 3 arms miss target (B +0.01381, C +0.01035, D +0.06125). Late_peak μ catastrophic. Constant μ=0.95 confirmed; axis CLOSED.
5. **Per-group AdamW WD** — thorfinn #348. CLOSED 15:15 UTC. All arms regress +0.0019–0.0025. AdamW WD axis closed on r4 (2nd consecutive verdict).
6. **Embed init scale** — edward #374. CLOSED 19:30 UTC productive-null. RMSNorm + AdamW absorb magnitude; embed init scale axis CLOSED.
7. **NS late_peak transition POINT** — frieren #344. CLOSED 20:00 UTC productive-null. Pod-1 Δ=−0.00419 shrank to pooled Δ=−0.000877 (79%), sign flip on pod 2. Midpoint confirmed optimal; axis CLOSED.
8. **Pruning ablation (#236, #285, #290)** — tanjiro #377. CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE). β2 amplified 5.9×; late_peak/linear_ramp_down appear subsumed.
9. **lm_head init std** — fern #380. CLOSED 22:40 UTC productive-null. Monotone worsening with σ; zero-init uniquely optimal.

### Fresh axes (early stage)
10. **NS coef center** — thorfinn #384. Sweep center ∈ {0.43, 0.49, 0.55, 0.60} at depth=0.42 (apex from fern #345). Polynomial aggressiveness axis never tested.
11. **NS_ITERS_COOLDOWN count** — askeladd #388. Sweep cooldown count ∈ {14, 16, 18, 20} at fixed NS_ITERS=12. ns_cooldown=16 was set on pre-#290 stack.
12. **AdEMAMix on AdamW** — edward #399. Fresh slow-EMA mechanism (NeurIPS 2024). Sweep alpha_max ∈ {2, 5, 8} vs control. Mechanism orthogonal to all per-group hyperparameter work.
13. **Gradient Centralization** — frieren #402. Gradient preprocessing layer (Yong et al. 2020). Scope sweep: all, adam, muon. Fresh mechanism abstraction layer.
14. **AdamW β2 sensitivity** — tanjiro #407. Mechanism-driven by #377 pruning finding (β2 amplified 5.9×). Test {0.98, 0.99, 0.995, 0.999} for optimum drift.
15. **Adaptive Gradient Clipping (AGC)** — fern #408. Per-parameter clip threshold based on ||W||_F (Brock et al. 2021, NFNets). Replaces fixed clip=10.0 with adaptive per-tensor threshold.

### Medium-priority unassigned axes (for next idle)
1. **AdEMAMix on aux groups** — triple-EMA long-memory mechanism; compatible with β2=0.99
2. **NS cooldown 3-phase** — extend late_peak to 3-phase (12→15→20 within cooldown window)
3. **Output proj init scale** — pairs with edward #374; proj has no RMSNorm so direct logit influence
4. **Per-group μ ablation** — with μ scheduling closed (#356), per-group constant μ remains worth testing (distinct from scheduling)
5. **Scalar LR finer sweep** — if nezuko #393 arm-D wins, follow-up {1.25, 1.5, 2.0, 2.5}×

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
| Logit softcap value | softcap=15 confirmed optimal, valley shape | #354 (productive-null) |
| AdamW WD (global) | global WD=0.005 absorbed by β2=0.99 | #279 (null) |
| AdamW WD (per-group) | per-group WD=0.002 on lm_head, scalar, or both — all harmful | #348 (harmful) |
| Muon μ schedule | ramp_up/ramp_down/late_peak — all miss target; late_peak +0.06125 catastrophic | #356 (harmful) |
| Embed init scale | scale ∈ {0.5, 1.0, 1.5, 2.0}; all within ±0.00061 null band; RMSNorm/AdamW absorb magnitude | #374 (productive-null) |
| NS late_peak transition POINT | frac ∈ {0.25, 0.50, 0.75}; pod-1 Δ=−0.00419 collapsed 79% to pooled Δ=−0.000877; sign flip pod 2; midpoint confirmed optimal | #344 (productive-null) |
| lm_head init std | σ ∈ {0.0, 0.005, 0.02, 0.05}; monotone worsening; zero-init uniquely optimal; σ=0.05 fails target | #380 (productive-null) |
| Pruning ablation (#236, #285, #290) | β2=0.99 load-bearing & 5.9× amplified; #285 late_peak appears subsumed; #290 linear_ramp_down fully subsumed; mechanism probe only | #377 (productive-null) |
