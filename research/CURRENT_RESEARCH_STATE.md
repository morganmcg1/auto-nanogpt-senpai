# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-18 06:15 UTC
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

## Active experiments — 08:40 UTC

### 🔄 fern #345 — NS coef ramp_down DEPTH sweep [arm-C running]
**Branch:** `g1r4-fern/ns-coef-ramp-depth`
**Hypothesis:** Is depth=0.42 optimal? Sweep 4 mean-neutral depths at c_mean=0.49.
**arm-A** (depth=0.42, control): val=3.27276, fs=3250, drift gate ✓
**arm-B** (depth=0.30, shallower): val=3.27666, Δ=**+0.00390** (worse — shallower hurts, confirms ramp_down real)
**arm-C** (depth=0.55, steeper): running, ETA ~12:00 UTC. Will reveal if interior optimum at 0.42 or directional to steeper.
**ETA full chain:** ~13:45 UTC.

### 🔄 frieren #344 — NS late_peak transition point sweep [arm-C running — STRONG SIGNAL]
**Branch:** `g1r4-frieren/ns-late-peak-frac-sweep`
**Hypothesis:** Is 50% cooldown transition optimal? Sweep: arm-A=0.25, arm-B=0.50 (control/drift gate), arm-C=0.75.
**KEY RESULT:** arm-A (frac=0.25) vs arm-B (frac=0.50) within-pod Δ = **−0.00419** — strongest signal this cycle!
- arm-A val=3.27095, arm-B val=3.27514 (drift gate marginally over by 0.00014, pod runs ~0.003 high)
- arm-C (frac=0.75) running, ETA ~12:08 UTC. Then SENPAI-RESULT + confirmation request.
**Pre-staged path:** If arm-A remains winner → request paired n=3 confirmation (frac=0.25 vs frac=0.50 back-to-back on fresh pods) to avoid pod-luck confound.

### ⚠️ tanjiro #300 — Embed floor value sweep [RE-CONF ON POST-#290 STACK]
**Status:** Pre-stack n=3 mean=3.27184 (seeds 1-3, Δ=−0.00016 vs baseline). Marginal — launched 2 re-conf seeds on full post-#290 stack.
- S4 launched 10:41 UTC on full post-#290 stack (mr6za83o), ETA ~12:25 UTC.
- S5 will follow immediately after S4.
**Decision after S4+S5:** n_reconf=2 mean ≤ 3.27300 → request n=3 for stat-sig; else productive-null.
**Key question:** Is embed floor=0.20 orthogonal to late_peak + linear_ramp_down, or was its mechanism absorbed by those merges?

### 🔄 thorfinn #348 — Per-group AdamW WD sweep [arm-A running, early]
**Branch:** `g1r4-thorfinn/per-group-adamw-wd`
**Hypothesis:** Per-group WD dispatch: lm_head-only WD=0.002 and scalar-only WD=0.002 may yield isolated signal where global WD failed (over-regularized embed).
**Status:** arm-A running, step ~1150/3350.
**ETA full chain:** ~15:00 UTC.

### ✅ edward #335 — Muon LR cooldown FLOOR sweep — CLOSED productive-null 11:05 UTC
All 4 arms: A=3.27482, B=+0.00149, C=+0.00636, D=+0.01659. Monotonic worsening. Mechanism confirmed: embed-floor is embed-specific; Muon NS orthogonalization already controls update magnitude, floor over-pushes. Closed. New assignment: #374 embed init scale.

### 🔄 alphonse #351 — Per-group SCALAR AdamW ε sweep [arm-A running, early]
**Branch:** `g1r4-alphonse/per-group-scalar-eps`
**Hypothesis:** Global ε null (closed #322). Test scalar-specific ε ∈ {1e-12, 1e-10, 1e-8, 1e-6} while embed/lm_head stay at 1e-10.
**Status:** arm-A running, early.
**ETA full chain:** ~15:00 UTC.

### 🆕 edward #374 — Embed init scale sweep [JUST ASSIGNED]
**Branch:** `g1r4-edward/embed-init-scale`
**Hypothesis:** Embed uses N(0,1) default init (never tuned). Sweep multipliers {0.5, 1.0, 1.5, 2.0}. Mechanism: RMSNorm normalizes forward, but gradient back through RMSNorm's reciprocal-RMS factor IS scale-dependent. Interacts with clip=10 mechanism.
**ETA:** ~7h sequential.

### 🆕 askeladd #354 — Logit softcap value sweep [JUST ASSIGNED]
**Branch:** `g1r4-askeladd/logit-softcap-value`
**Hypothesis:** Hardcoded `15` in `GPT.forward` softcap (`logits = 15 * logits * (logits.square() + 15**2).rsqrt()`) has never been tuned. Fresh axis. 4 arms: A=15 (control), B=10 (softer), C=20 (harder), D=25 (much harder).
**Decision rule:** within-pod Δ ≤ −0.002 → signal; all within ±0.0015 → null; monotone direction → extend.
**ETA:** ~7h sequential.

### 🆕 nezuko #356 — Muon μ schedule sweep [JUST ASSIGNED]
**Branch:** `g1r4-nezuko/muon-mu-schedule`
**Hypothesis:** Muon momentum μ=0.95 constant; schedule it like NS coef linear_ramp_down won (#290). Mechanism: early training → low μ (responsive), late cooldown → high μ (stable). 4 arms: A=constant 0.95, B=ramp_up 0.90→0.99, C=ramp_down 0.99→0.90, D=late_peak 0.90→0.99.
**Decision rule:** within-pod Δ ≤ −0.002 → real signal; B wins + C loses → clean mechanism confirmation.
**ETA:** ~7h sequential.

---

## Recently closed

- **edward #335 (Muon LR cooldown floor)** — CLOSED 11:05 UTC productive-null. Monotonic worsening: A=3.27482 (+0), B=+0.001, C=+0.006, D=+0.017. Embed-floor mechanism doesn't generalize to Muon. New axis: embed init scale (#374).
- **askeladd #324 (AdamW β1 sweep)** — CLOSED 08:35 UTC productive-null. Monotone-worse direction: β1=0.80 optimal, arm-D (β1=0.95) +0.00599 worse. Asymmetric with β2 finding: direction non-stationary across batches, magnitude stationary. Wave-7 axis: logit softcap (#354).
- **nezuko #315 (lm_head steeper-decay cooldown)** — CLOSED 08:35 UTC productive-null. Hypothesis FALSIFIED — all steeper shapes regress +0.0031–0.0035. Linear is the lm_head sweet spot: neither floor nor steep decay help. Unified mechanism: lm_head is time-of-update-concentration sensitive. Wave-7 axis: Muon μ schedule (#356).
- **frieren #285 (NS cooldown SHAPE)** — MERGED ✅ 06:02 UTC. val=3.27352 (n=2). late_peak concentrates NS=20 into lowest-LR half of cooldown.
- **fern #290 (NS coef schedule)** — MERGED ✅ 06:07 UTC. val=3.27200 (n=3). linear_ramp_down starts NS at high-precision coefficients, ramps toward standard.
- **thorfinn #279 (AdamW WD=0.005)** — CLOSED 07:12 UTC productive-null. n=3 mean=3.27530 vs new baseline 3.27200 (+0.00330 above gate). β2=0.99 absorbed standalone gain.
- **alphonse #322 (AdamW global ε)** — CLOSED 07:48 UTC productive-null. All 3 treatment arms +0.0016-0.0031 worse than control ε=1e-10. β2=0.99 smoothing already stabilizes denominator.
- **edward #280 (per-aux-group β2 ablation)** — CLOSED mechanism-study. Sparsity-driven mechanism: scalar > embed > lm_head. Global β2=0.99 captures UNION.
- **askeladd #241 (Muon mu=0.97)** — productive-null. Within-pod inverted-U at mu=0.97 but cross-pod fail (+0.00118 above gate).

---

## Potential next research directions

### Highest-priority in-flight candidates
1. **Embed floor value optimization** — tanjiro #300 in-flight. Seed-3 ETA ~08:40 UTC. n=2 mean=3.27151 → strong candidate if n=3 mean ≤ baseline.
2. **NS late_peak transition point** — frieren #344. arm-A running (ETA ~08:30 UTC). arm-B is drift gate for composition validation.
3. **NS linear_ramp_down depth** — fern #345. arm-A=3.27276 (drift gate ✓), arm-B (depth=0.30) running.
4. **Muon LR cooldown floor** — edward #335. arm-B worse (+0.00149), arm-C running. Heading null-ish.
5. **Per-group scalar ε** — alphonse #351. arm-A early in training.
6. **Per-group WD** — thorfinn #348. arm-A early in training.

### Fresh axes just assigned
7. **Logit softcap value** — askeladd #354. First-ever tuning of output softcap (15.0). Full-stack sweep on post-#290.
8. **Muon μ schedule** — nezuko #356. Parallels NS coef linear_ramp_down mechanism. ramp_up(0.90→0.99) is the mechanism prediction.

### Medium-priority unassigned axes
9. **NS coef mean sweep** — once fern #345 fixes depth (0.30/0.42/0.55/0.70), sweep c_mean {0.45/0.49/0.53/0.57} at winning depth
10. **AdEMAMix on aux groups** — triple-EMA long-memory mechanism; compatible with β2=0.99 stack
11. **NS cooldown 3-phase** — extend late_peak to 3-phase (12→15→20 within cooldown window)
12. **Embed init scale** — N(0,1) default may be suboptimal; but RMSNorm normalizes immediately, lower priority
13. **Per-group μ ablation** — after nezuko #356 lands; per-group μ (parallels per-group β2 from #280)

### What we know about stacking
- 7 merges across orthogonal axes: clip, NS timing, NS shape, NS coef schedule, embed floor, β2, Muon² baseline
- Our branch leads public best: val=3.27200 vs public ~3.279; gap to 3030 steps ~200 steps in fs
- Closed β1 (monotone worse), lm_head steeper decay (all worse), global WD, global ε — post-#290 stack appears saturated on naive hparam sweeps
- Fresh mechanism exploration (schedule axes, init, output layer) remains the priority

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
| NS cooldown SHAPE (frieren) | late_peak wins — MERGED #285 | — |
| NS coef schedule (fern) | linear_ramp_down wins — MERGED #290 | — |
