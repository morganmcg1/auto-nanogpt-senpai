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

### 🔄 fern #345 — NS coef ramp_down DEPTH sweep [arm-A terminal, arm-B running]
**Branch:** `g1r4-fern/ns-coef-ramp-depth`
**Hypothesis:** #290 established linear_ramp_down direction (c=0.70→0.28, depth=0.42). Is depth=0.42 optimal? Sweep 4 mean-neutral depths: arm-A=0.42 (control), arm-B=0.30 (shallower), arm-C=0.55 (steeper), arm-D=0.70 (much steeper). All arms anchored at c_mean=0.49 — pure shape sweep.
**arm-A result:** val=3.27276, fs=3250, drift gate |Δ|=0.00076 ≤ 0.003 ✓. arm-B running.
**Decision rule:** within-pod Δ ≤ −0.002 → signal candidate; all within ±0.0015 → productive-null.
**ETA full chain:** ~13:30 UTC.

### 🔄 frieren #344 — NS late_peak transition point sweep [arm-A running, ~3025/3350]
**Branch:** `g1r4-frieren/ns-late-peak-frac-sweep`
**Hypothesis:** Is 50% cooldown transition optimal? Sweep: arm-A=0.25, arm-B=0.50 (control/drift gate), arm-C=0.75. arm-B ALSO validates #285+#290 composition.
**Status:** arm-A (frac=0.25) at step ~3025/3350. arm-B (drift gate) and arm-C queued.
**ETA arm-A terminal:** ~08:30 UTC. Full chain ETA ~11:30 UTC.

### ⚠️ tanjiro #300 — Embed floor value sweep [CONFIRMATION MID-CHAIN]
**Status:** seed-3 in flight (step ~3000/3350, ETA ~08:35 UTC). Seeds were run on pre-#285+#290 stack.
- n=2 mean=3.27151 (seed-1=3.26995, seed-2=3.27310) — strong signal candidate. If n=3 mean ≤ 3.27200 → request 1-2 re-confirmation seeds on post-#290 full stack.
**Decision after seed-3:** n=3 mean determines path (merge if ≤ baseline, re-confirm on post-#290 stack, or close).

### 🔄 thorfinn #348 — Per-group AdamW WD sweep [arm-A running, early]
**Branch:** `g1r4-thorfinn/per-group-adamw-wd`
**Hypothesis:** Per-group WD dispatch: lm_head-only WD=0.002 and scalar-only WD=0.002 may yield isolated signal where global WD failed (over-regularized embed).
**Status:** arm-A running, step ~1150/3350.
**ETA full chain:** ~15:00 UTC.

### 🔄 edward #335 — Muon LR cooldown FLOOR sweep [arm-B terminal, arm-C running]
**Status:** arm-A val=3.27482 (drift gate ✓), arm-B (floor=0.05) val=3.27631 (+0.00149 vs A). Arm-C (floor=0.10) running at step ~1825/3350. Trending worse (floor helps Muon-side? still unclear).
**Note:** All arms use post-#236 stack (no #285+#290). Re-confirmation on post-#290 needed if signal found.
**ETA full chain:** ~10:50 UTC.

### 🔄 alphonse #351 — Per-group SCALAR AdamW ε sweep [arm-A running, early]
**Branch:** `g1r4-alphonse/per-group-scalar-eps`
**Hypothesis:** Global ε null (closed #322). Test scalar-specific ε ∈ {1e-12, 1e-10, 1e-8, 1e-6} while embed/lm_head stay at 1e-10.
**Status:** arm-A running, early.
**ETA full chain:** ~15:00 UTC.

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
