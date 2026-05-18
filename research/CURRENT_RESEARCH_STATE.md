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

## Active experiments — 06:15 UTC

### 🔄 frieren #344 — NS late_peak transition point sweep [JUST ASSIGNED]
**Branch:** `frieren/ns-late-peak-frac-sweep`
**Hypothesis:** The #285 late_peak winner used 50% of cooldown as NS=12, 50% as NS=20. Is 50% optimal? Sweep transition point: arm A=0.25, arm B=0.50 (control), arm C=0.75. Arm B ALSO validates composition of #285+#290 since it's the first run with both active simultaneously.
**Drift gate:** |val_B − 3.27200| ≤ 0.003. Composition check: val_B ≈ 3.272 → clean stack; val_B ≈ 3.274+ → partial overlap.
**ETA:** ~5.5h chain.

### ⚠️ tanjiro #300 — Embed floor value sweep [CONFIRMATION MID-CHAIN, STALE BASELINE]
**Status:** Conf seed-1 (floor=0.20, post-#236 stack) val=**3.26995** (Δ vs new baseline = −0.00205). Strong signal that SURVIVES baseline update. Conf seed-2 in flight, ETA ~06:30 UTC. Seed-3 queued.
**IMPORTANT:** Seeds were run on pre-#285+#290 stack. After seed-3 terminal:
- n=3 mean ≤ 3.27200 → request 1-2 re-confirmation seeds on post-#290 full stack
- n=3 mean ∈ (3.27200, 3.27350] → borderline; request 2 seeds on post-#290 stack
- n=3 mean > 3.27350 → productive-null (absorbed by late_peak/ns_coef)
**ETA for n=3 terminal:** ~08:30 UTC. Student notified of baseline change.

### ⚠️ thorfinn #279 — AdamW aux WD sweep [HEADING TO PRODUCTIVE-NULL]
**Status:** Probe seed (3.27551) + seed-2 (3.27540) → n=2 mean = 3.27546. Seed-3 running, ETA ~06:59 UTC.
**Against new baseline 3.27200:** n=3 merge would require seed-3 ≤ 3.26508 — essentially impossible. Definitively null against post-#290 baseline. Student notified; will close after seed-3 lands.
**Mechanism insight:** WD=0.005 benefit was likely absorbed by β2=0.99, NS late_peak, and NS coef improvements. The post-#290 stack may have already tuned effective step magnitude adequately via other mechanisms.

### edward #335 — Muon LR cooldown FLOOR sweep [mid-chain]
**Status:** arm-A val=3.27482 (drift gate pass: |Δ|=0.00075 ≤ 0.003). Arm-B (floor=0.05) running, ETA ~07:09 UTC. Arms C/D follow. Full chain ETA ~10:50 UTC.
**Note:** All arms use post-#236 stack (no #285+#290 yet). Will need re-confirmation on post-#290 stack if any arm shows signal.
**Decision:** within-pod Δ ≤ −0.002 → real signal candidate.

### alphonse #322 — AdamW ε sweep [mid-chain, likely null direction]
**Status:** Arm-A (ε=1e-10) = 3.27152, arm-B (ε=1e-9) = 3.27413 (+0.00261 worse). Arm-C running. Monotone worsening direction (higher ε = worse) likely. Decision rule: all within ±0.0015 of A → productive-null.

### askeladd #324 — AdamW β1 sweep [mid-chain, likely null direction]
**Status:** Arm-A (β1=0.8) = 3.27113, arm-B (β1=0.85) = 3.27251 (+0.00138 worse). Arm-C (β1=0.9) running. Monotone worsening direction likely.

### nezuko #315 — lm_head steeper-decay cooldown shape [mid-chain, likely null]
**Status:** Arm-A (linear) = 3.27300, arm-B (quadratic) = 3.27632 (+0.00332 worse). Arm-C (cubic) running, ETA ~06:20 UTC. Monotone worsening direction → hypothesis (steeper = better) falsified. Close after arm-D as productive-null; informs that lm_head wants LESS steep decay (consistent with the original floor=15% HURTS finding from #266).

---

## Recently closed

- **frieren #285 (NS cooldown SHAPE)** — MERGED ✅ 06:02 UTC. val=3.27352 (n=2). late_peak concentrates NS=20 into lowest-LR half of cooldown.
- **fern #290 (NS coef schedule)** — MERGED ✅ 06:07 UTC. val=3.27200 (n=3). linear_ramp_down starts NS at high-precision coefficients, ramps toward standard.
- **edward #280 (per-aux-group β2 ablation)** — CLOSED mechanism-study. Sparsity-driven mechanism: scalar > embed > lm_head (inverts pre-registration). Sub-additivity 2.5× confirms global β2=0.99 captures UNION.
- **askeladd #241 (Muon mu=0.97)** — productive-null. Confirmed within-pod inverted-U but cross-pod fail (+0.00118 above gate).

---

## Potential next research directions

### Highest-priority fresh axes
1. **Embed floor value optimization** — tanjiro #300 in-flight. If floor=0.20 confirms on post-#290 stack, that's the next merge.
2. **NS late_peak transition point optimization** — frieren #344 in-flight. Finding optimal 25%/50%/75% split.
3. **Muon LR cooldown floor** — edward #335 in-flight. Mechanism generalization from embed-floor to Muon blocks.
4. **Per-group scalar ε tuning** — edward #280 showed scalar group most sparsity-vulnerable. alphonse #322 probes global ε; per-group scalar ε is the mechanism-validated follow-up.
5. **NS linear_ramp_down depth** — the winning linear_ramp_down went from c=0.70 → c=0.24 over 12 NS iters. Does a steeper ramp (0.70→0.10) or starting higher (0.90→0.24) improve further?

### Medium-priority axes
6. **Joint β1 × β2 surface** — pending askeladd #324 β1 sweep result
7. **AdEMAMix on aux groups** — triple-EMA long-memory mechanism
8. **NS cooldown shape beyond late_peak** — 3-phase (e.g., NS=12→15→20) within cooldown window
9. **Compositional pile** — once #344 confirms composition, start exploring 3-way interactions (embed floor × NS shape × NS coef)

### What we know about stacking
- 7 merges across orthogonal axes: clip, NS timing, NS shape, NS coef schedule, embed floor, β2, Muon² baseline
- Remaining gap to public SOTA: val=3.27200 vs public best ~3.279 (our branch leads; gap to 3030 steps is ~200 steps in fs)
- If tanjiro #300 floor=0.20 confirms → potential val ~3.269 → potentially close to new local optimum on current mechanism set
- Fresh mechanism exploration (new optimizer families, initialization, architecture within contract) should be kept in the pipeline

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
