# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-20 01:47 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `val/loss` at 3350 steps (lower is better); `speedrun/final_first_step_to_target` secondary
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline

## Current merged baseline — post-#393

**val=3.27174 / fs=3233.33 (n=3 paired-pod mean)**

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
NANOGPT_ADAMW_EMBED_LR_MULT=1.5
```

### Merged stack history

| PR | Change | val (n) | Cumulative baseline |
|----|--------|---------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3.27434 |
| #236 | AdamW β₂=0.99 | 3.27407 (3) | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3.27352 |
| #290 | NS coef schedule=linear_ramp_down | 3.27200 (3) | 3.27200 |
| **#393** | **AdamW embed LR mult=1.5×** | **3.27174 (3)** | **3.27174** ← CURRENT |

---

## Active experiments (all on r4)

### ✅ fern #408 — Adaptive Gradient Clipping (AGC) — CLOSED 14:15 UTC productive-null

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck. AGC mechanism consistent (99.4% trigger rate) but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups**.

### ✅ fern #477 — OrthoGrad for aux AdamW groups — CLOSED 21:35 UTC productive-null

Arms B (embed: +0.00163), C (lm_head: +0.00285) regress; D (embed+lm_head: −0.00080) recovers. Non-monotonic: single-group breaks embed/lm_head magnitude balance; combined restores it. D Δ=−0.00080 passes stat-rule on absolute baseline but well short of −0.002 within-pod threshold — productive-null. **22nd productive-null/negative this cycle.** Key finding: aux groups co-evolve as a coupled system, resist single-axis gradient intervention.
**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing-rate schedule axis.

### 🔄 fern #514 — AdamW β₁ warmup on aux groups [assigned 21:35 UTC]

**Branch:** `g1r4-fern/beta1-warmup`
**Hypothesis**: Ramp β₁ from a low starting value → 0.8 over first N% of training for all 3 aux AdamW groups (embed, lm_head, scalars). Lower β₁ early = slower first-moment accumulation = less smoothing = more responsive to noisy early gradients. Pairs with WD warmup (#483), embed-LR warmup (#489), NS-iter warmup (#506) — "less constraint early" cluster. First-moment smoothing rate is the one AdamW schedule axis not yet varied dynamically.
| Arm | NANOGPT_ADAMW_BETA1_WARMUP_START | NANOGPT_ADAMW_BETA1_WARMUP_FRAC | Profile |
|---|---:|---:|---|
| A | 0.8 | 0.0 | flat β₁=0.8 (control) |
| B | 0.6 | 0.05 | β₁ 0.6→0.8 over 167 steps |
| C | 0.4 | 0.05 | β₁ 0.4→0.8 over 167 steps |
| D | 0.6 | 0.10 | β₁ 0.6→0.8 over 335 steps |
**ETA full chain:** ~7.3h.

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### ✅ alphonse #442 — Adam-atan2 — CLOSED 17:53 UTC productive-NEGATIVE

b sweep {0.3, 1.0, 3.0}: all regress vs AdamW (b=0). D (b=3.0) misses 3.28 target (+0.010). Magnitude-transform of AdamW formula fully closed. **19th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#489 embed-only LR warmup**.

### ✅ alphonse #489 — Embed-only LR warmup — CLOSED 01:47 UTC productive-NEGATIVE

Monotone catastrophic worsening: A=3.27054, B=+0.01026 (frac=0.02), C=+0.01554 (frac=0.05), D=+0.02316 (frac=0.10). All 3 warmup arms fail benchmark (none reach 3.28 target). Full embed LR from step 0 is load-bearing — #102 closure rationale ("early high-LR window is productive") extends to embed AdamW despite mechanistic distinction (sparse-grad vs Muon+NS). **25th productive-null/negative this cycle.** Bilateral closure with #483 WD warmup (also productive-NEGATIVE): the early-training window is bilaterally well-tuned; regularization-REDUCTION by warmup on any group fails.
**Follow-up**: alphonse assigned **#526 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×).

### 🔄 alphonse #526 — Embed LR step-0 boost [assigned 01:47 UTC]

**Branch:** `alphonse/embed-lr-step0-boost`
**Hypothesis**: Symmetric inverse of #489 closure. If reducing embed LR early hurts Δ=+0.01, does boosting embed LR above 1.5× at step 0 (then decaying to merged 1.5×) help? Tests whether the embed group benefits from temporarily-higher early LR. Structurally distinct from #393 (constant mult retune — we're testing a temporal boost-then-decay profile not a constant).
| Arm | BOOST_MULT | BOOST_FRAC | Effective embed LR @step 0 | Decay window |
|---|---:|---:|---:|---|
| A | 1.0 (control) | 0.0 | 1.5× | none |
| B | 2.0 | 0.03 | **3.0×** | ~100 steps |
| C | 2.5 | 0.03 | **3.75×** | ~100 steps |
| D | 2.0 | 0.06 | **3.0×** | ~200 steps |
**ETA full chain:** ~7.3h.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### 🚨 tanjiro #487 — Cooldown-NS pruning ablation [paired-pod confirmation in progress, sent back 01:05 UTC]

**Branch:** `g1r4-tanjiro/cooldown-ns-pruning`
**Hypothesis**: Three NS-cooldown components (#176 NS_ITERS_COOLDOWN=16, #285 NS_COOLDOWN_SHAPE=late_peak, #290 NS_COEF_SCHEDULE=linear_ramp_down) were each merged sequentially. Later components may have subsumed earlier ones. Drop one component per arm (revert to compiled-in default), testing if any is now redundant. First *subtractive* experiment this cycle — no code changes, env-var overrides only.

**N=1 results (pod-0):**
| Arm | Drop | val | Δ vs A |
|---|---|---:|---:|
| A | none (control) | 3.27198 | 0.0 |
| **B** | **NS_ITERS_COOLDOWN** | **3.26813** | **−0.00385** ⭐ |
| C | NS_COOLDOWN_SHAPE | 3.27278 | +0.00080 (null) |
| D | NS_COEF_SCHEDULE | 3.27264 | +0.00066 (null) |

**Arm B is the first Δ ≤ −0.002 candidate in many cycles.** Mechanism reading: #176 (NS_ITERS_COOLDOWN=16) was the first cooldown component merged; subsequent #285 (late_peak SHAPE) and #290 (linear_ramp_down COEF) may have made the iter ramp redundant — possibly even harmful through over-orthogonalization in the cooldown window. If confirmed, this is a **stack-simplification merge**: dropping a load-bearing-looking component improves the recipe.

**Paired-pod confirmation chain** (sent back to draft at 01:05 UTC): 3 paired A/B pods to control for seed/pod-variance. Arms C and D held — single false-positive arm B replication takes priority. Merge gate: mean(Δ) ≤ −0.002 AND mean(val_B) ≤ 3.27174 AND `(3.28 − mean) × √3 ≥ 0.004`. ETA ~11.4h (3 paired chains).
**Precedent**: 3 false-positives this cycle (#344, #351, #408 AGC) on single-pod Δ ≤ −0.002 signals → paired-pod is mandatory.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### ✅ thorfinn #483 — WD warmup schedule (Muon block group) — CLOSED 23:42 UTC productive-NEGATIVE

Clean monotone worsening: A=3.27066, B=+0.00080 (null), C=+0.00258 (regression), D=+0.00400 (regression). Body-block WD=0.025 is load-bearing from step 0 — delaying it hurts. **24th productive-null/negative this cycle.** Bilateral closure: 17 ADD-regularization axes + 1 REDUCE-regularization axis both fail → Muon-WD=0.025 is bilaterally optimal.
**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles over the load-bearing 30% cooldown window.

### 🔄 thorfinn #520 — Body Muon LR cooldown shape sweep [assigned 23:42 UTC]

**Branch:** `g1r4-thorfinn/body-cooldown-shape`
**Hypothesis**: Body Muon LR uses linear cooldown (1.0→0.0 over last 30%) — the first experiment targeting this specific axis. NS-orthogonalized updates have rank-stable magnitudes (unlike AdamW per-coordinate updates), so optimal cooldown profile may differ. Prior shape experiments: embed (#235 linear_floor MERGED, #454 null), NS-iter (#285 late_peak MERGED). Body group has been linear-default the whole time.
| Arm | NANOGPT_BODY_COOLDOWN_SHAPE | Profile |
|---|---|---|
| A | linear (control) | 1.0 → 0.0 linear |
| B | cosine | 1.0 → 0.0 cosine half-cycle (front-loaded) |
| C | quadratic | 1.0 → 0.0 quadratic (more front-loaded) |
| D | linear_floor | 1.0 → 0.15 never-zero floor |
**ETA full chain:** ~7.3h.

### 🔄 askeladd #452 — Block output projection init scale [assigned ~09:00 UTC]

Init-side: scale `attn.proj` and `mlp.proj` weights at init by s ∈ {1.0, 0.5, 0.2, 0.05}. DeepNet/T-Fixup family. Tests if NS-normalized Muon updates wash out init scaling within first ~100 steps. Arm B running.

### ✅ nezuko #454 — lm_head/scalar cooldown shape extension — CLOSED 18:05 UTC productive-null

Arms B/C/D (lm_head_floor, scalar_floor, both): best Δ=−0.00098 (arm B), half the −0.002 threshold. Arm D (stacked) regresses +0.00072 vs A, indicating cross-group interaction at end-of-cooldown. **linear_floor is embed-specific** (sparse-row coverage benefit), not aux-generic. Three prior paired-pod false-positives (#344, #351, #408 AGC) support conservative close. **20th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#490 NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, first Adam-family axis we haven't tested.

### 🔄 nezuko #490 — NAdam (Nesterov-AdamW) scope sweep [assigned 18:15 UTC]

**Branch:** `g1r4-nezuko/nadam-aux`
**Hypothesis**: NAdam replaces AdamW's first-moment bias-corrected estimate `m̂_t` with the Nesterov lookahead `m_nadam = β₁·m̂_t + (1-β₁)·g_t/(1-β₁^t)`. Fills the one gap in the AdamW-internal three-axis ablation: magnitude (#442 NEGATIVE), variance (#474 in-flight), **first-moment (this PR)**. Scope sweep across aux groups to isolate sparse-embed vs dense-lm_head benefit.
| Arm | NANOGPT_NADAM_SCOPE | Groups using NadamW |
|---|---|---|
| A | none (control) | all AdamW |
| B | embed | adam_embed only |
| C | lm_head | adam_lm_head only |
| D | all_aux | embed + lm_head + scalars |
**ETA full chain:** ~7.3h.

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### 🔄 frieren #506 — NS-iter warmup schedule [assigned 21:00 UTC]

**Branch:** `g1r4-frieren/ns-warmup`
**Hypothesis**: Ramp NS_ITERS from a low starting value → 12 over the first N% of normal phase. Builds on #470 findings: NS=8 is below precision floor in flat mode, but may be acceptable for the first 5% (noisy gradients). Structurally novel: first NS schedule experiment *within* the normal phase (all prior NS schedule work targeted cooldown). Pairs with WD warmup (#483) and embed LR warmup (#489) — "less constraint early" cluster.
| Arm | NS_ITERS_WARMUP_START | NS_ITERS_WARMUP_FRAC | Profile |
|---|---:|---:|---|
| A | 12 | 0.0 | flat NS=12 (control) |
| B | 10 | 0.05 | NS 10→12 over 167 steps |
| C | 8 | 0.05 | NS 8→12 over 167 steps |
| D | 10 | 0.10 | NS 10→12 over 335 steps |
**ETA full chain:** ~7.3h.

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### 🔄 edward #516 — Yogi optimizer on aux groups [assigned 22:35 UTC]

**Branch:** `g1r4-edward/yogi-aux`
**Hypothesis**: Yogi replaces AdamW's multiplicative β₂-EMA second moment with sign-based additive update: `v_t = v_{t-1} − (1−β₂)·sign(v_{t-1} − g_t²)·g_t²`. Avoids AdaBelief's absent-row pathology (accumulates g², not (g−m)²). Distinct mechanism: bounded-additive update vs multiplicative EMA. Motivated by heavy-tailed gradient distributions (embed token sparsity, lm_head token frequency noise). Structurally distinct from every prior Adam-family axis tested.
| Arm | NANOGPT_AUX_OPTIMIZER | NANOGPT_YOGI_SCOPE | Tests |
|---|---|---|---|
| A | adamw | none (control) | Drift gate |
| B | yogi | embed | Sparse-row: does additive update help? |
| C | yogi | lm_head | Dense-noisy: does bounded update help? |
| D | yogi | embed_lm_head_scalars | Full aux scope |
**ETA full chain:** ~7.3h.

---

## Research theme — current cycle

**25 productive-null/negative results** on optimizer-internal / parameter-temporal / loss-side axes. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. Does block init scaling matter under Muon? (#452)
2. Does embed-only LR warmup help sparse-row early training? (#489)
3. Are any cooldown-NS merged components now redundant after later merges? (#487 — Arm B Δ=−0.00385 N=1 winner candidate, paired-pod confirmation chain running)
4. Does NAdam's Nesterov first-moment help aux groups vs standard AdamW? (#490)
5. Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise? (#506)
6. Does β₁ warmup (lower smoothing early) help aux AdamW groups? (#514)
7. Does Yogi's sign-based additive second-moment update help aux groups? (#516)
8. Does body Muon LR cooldown shape (linear/cosine/quadratic/linear_floor) matter? (#520, thorfinn)
9. Does embed LR step-0 boost (above 1.5×, decay to 1.5×) help? (#526, alphonse)

**Stack convergence signal**: 24 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **"Less constraint early" schedule cluster** (in flight): embed-LR warmup (#489), NS-iter warmup (#506), β₁ warmup (#514) — three early-phase schedule axes. WD warmup (#483) closed NEGATIVE — body-WD is load-bearing from step 0.
2. **Late-phase cooldown shape**: body Muon LR cooldown shape (#520 thorfinn) — complementary to early-phase cluster, targeting the load-bearing 30% cooldown window
3. **Adam-family second-moment update rule**: NAdam (#490, Nesterov first-moment) and Yogi (#516, sign-additive second-moment) are the last two in-flight Adam-family mechanism axes
4. **Stack simplification** — #487 Arm B (drop NS_ITERS_COOLDOWN) N=1 Δ=−0.00385 first winner candidate in many cycles; paired-pod confirmation in flight. If confirmed, removes #176 from merged stack as redundant under #285/#290.
5. **Bilateral regularization closure (from #483)**: both ADD (17 axes) and REDUCE (WD warmup) regularization fail → Muon-WD=0.025 is bilaterally optimal
6. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope, not single-group
7. **Embed sparsity structural insight (from #474)**: `(g − m)²`-based second moments fail on embed group; `g²`-only formulations (AdamW, Yogi) are safe

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
| #483 | thorfinn | Muon WD warmup frac∈{0.05,0.10,0.20} | CLOSED productive-NEGATIVE (monotone: +0.00080/+0.00258/+0.00400; body WD=0.025 is load-bearing from step 0; bilateral WD-level closure) |
| #474 | edward | AdaBelief aux scope sweep | CLOSED productive-NEGATIVE (B=+0.041/D=+0.035 catastrophic embed sparsity; C=+0.002 mild; second-moment-formulation axis closed) |
| #477 | fern | OrthoGrad aux scope sweep | CLOSED productive-null (D=−0.00080 short of −0.002; non-monotonic: singles regress, combined recovers; aux groups coupled system) |
| #470 | frieren | NS iterations normal phase NS∈{8,10,12,14} | CLOSED productive-null (wide plateau [10,14]; NS=8 below floor; NS step-time flat ±1%) |
| #454 | nezuko | lm_head/scalar linear_floor cooldown | CLOSED productive-null (best Δ=−0.00098, half threshold; embed-specific mechanism, not aux-generic) |
| #442 | alphonse | Adam-atan2 b∈{0.3,1.0,3.0} | CLOSED productive-NEGATIVE (D=+0.010 missed 3.28; all worse than ε-based AdamW; magnitude-transform axis closed) |
| #441 | tanjiro | Logit Z-loss λ∈{1e-5,1e-4,1e-3} | CLOSED productive-NEGATIVE (B=+0.00211/C=+0.00151/D=+0.022 missed 3.28; softcap c=15 already bounds logits, z-loss redundant) |
| #446 | thorfinn | Label smoothing α∈{0.05,0.1,0.2} | CLOSED productive-NEGATIVE (monotone: +0.046/+0.102/+0.223; stack already well-regularized) |
| #434 | edward | Lookahead scope sweep | CLOSED productive-NEGATIVE (all arms regression-monotone; Muon wrapping 4.5× worse) |
| #436 | frieren | Weight-EMA (Polyak averaging) | CLOSED productive-NEGATIVE (damage monotone with window; cooldown is signal not noise) |
| #419 | askeladd | Cautious AdamW (all scopes) | CLOSED productive-null (regression all scopes; β₁=0.80 leaves little room for cautious mask) |
| #409 | thorfinn | Per-block LR decay (LLRD for Muon) | CLOSED productive-null (NS normalizes depth-dependent LR) |
| #411 | alphonse | Gradient noise injection | CLOSED productive-null (noise clearly hurts; stack already near noise floor) |
| #407 | tanjiro | AdamW β₂ sensitivity | CLOSED productive-null (symmetric valley around β₂=0.99) |
| #402 | frieren | Gradient Centralization scope | CLOSED productive-null (NS already mean-centers block gradients) |
| #399 | edward | AdEMAMix on AdamW groups | CLOSED productive-null (slow-EMA redundant with β₂=0.99) |

---

## Closed axes (do not re-assign)

**Optimizer-internal / Adam-family**:
- β₁, β₂, ε per-group: all swept, β₁=0.80/β₂=0.99/ε=1e-10 confirmed
- WD per-group: all harmful, axis closed
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC, OrthoGrad: all closed
- AdaBelief variance-of-prediction-error second moment: CLOSED productive-NEGATIVE (#474; embed sparsity pathology; `(g−m)²` fails on absent-row sparse groups)
- Muon-WD warmup (all fracs 5-20%): CLOSED productive-NEGATIVE (#483; monotone worsening; body WD=0.025 is bilaterally optimal)
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); **#487 Arm B (drop) N=1 Δ=−0.00385 winner candidate** — paired-pod confirmation in flight
- NS cooldown SHAPE=late_peak: MERGED #285; #487 Arm C drop = +0.00080 null
- NS coef schedule=linear_ramp_down: MERGED #290; #487 Arm D drop = +0.00066 null
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: CLOSED productive-null (#470; wide plateau NS ∈ [10,14]; NS=8 below floor; NS step-time flat ±1%)
- NS-iter warmup: in-flight (#506)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): in-flight (#526)

**Init**:
- Embed init scale: null (#374)
- lm_head init std: monotone worse (#380)
- Block output projection init scale: in-flight (#452)

**Loss-side**:
- Logit softcap=15: confirmed optimal (#354)
- Z-loss λ∈{1e-5,1e-4,1e-3}: CLOSED productive-NEGATIVE (#441; softcap c=15 already bounds logits)
- Label smoothing α∈{0.0–0.2}: monotone catastrophic regression; closed (#446 productive-NEGATIVE)

**Clipping**:
- clip=5 → clip=10: MERGED #165
- AGC (per-parameter): productive-null per paired-pod trajectory (#408)
