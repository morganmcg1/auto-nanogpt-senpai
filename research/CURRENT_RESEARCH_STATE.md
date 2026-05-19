# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-19 21:35 UTC
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

### 🔄 alphonse #489 — Embed-only LR warmup [assigned 17:53 UTC]

**Branch:** `g1r4-alphonse/embed-lr-warmup`
**Hypothesis**: Current stack has no LR warmup. Global warmup was closed (#102 negative: NS stabilizes early Muon body). But that closure doesn't apply to embed AdamW (sparse-row gradients, no NS). Embed-only LR warmup ramps embed LR from 0 → full over first N% while leaving Muon body + lm_head/scalar at full LR from step 0. First per-group LR schedule axis on embed group.
| Arm | NANOGPT_EMBED_LR_WARMUP_FRAC | Embed warmup window |
|---|---:|---|
| A | 0.0 (control) | none |
| B | 0.02 | ~67 steps |
| C | 0.05 | ~170 steps |
| D | 0.10 | ~335 steps |
**ETA full chain:** ~7.3h.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### 🔄 tanjiro #487 — Cooldown-NS pruning ablation [assigned 17:00 UTC]

**Branch:** `g1r4-tanjiro/cooldown-ns-pruning`
**Hypothesis**: Three NS-cooldown components (#176 NS_ITERS_COOLDOWN=16, #285 NS_COOLDOWN_SHAPE=late_peak, #290 NS_COEF_SCHEDULE=linear_ramp_down) were each merged sequentially. Later components may have subsumed earlier ones. Drop one component per arm (revert to compiled-in default), testing if any is now redundant. First *subtractive* experiment this cycle — no code changes, env-var overrides only.
| Arm | Drop | Env override |
|---|---|---|
| A | none (control) | full merged stack |
| B | NS_ITERS_COOLDOWN | NANOGPT_NS_ITERS_COOLDOWN=0 |
| C | NS_COOLDOWN_SHAPE | NANOGPT_NS_COOLDOWN_SHAPE=step |
| D | NS_COEF_SCHEDULE | NANOGPT_NS_COEF_SCHEDULE=constant |
**ETA full chain:** ~7.3h.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### 🔄 thorfinn #483 — WD warmup schedule (Muon block group) [assigned 15:40 UTC, spec clarified 15:48 UTC]

**Branch:** `g1r4-thorfinn/wd-warmup`
**Hypothesis**: WD warmup ramps WD linearly from 0 → full over first N% of training, then holds constant. Tests if early-phase over-regularization on body weights is hurting discovery. First regularization-REDUCTION test this cycle (all 17 prior axes ADDED regularization and failed).
**Spec correction (15:48 UTC)**: Student correctly flagged that AdamW WD=0 across all groups in the merged stack — the only nonzero WD is on Muon block weights (WD=0.025, line 846; decoupled WD applied at Muon.step():704). Warmup now applied to the Muon block group: `for g in optimizer2.param_groups: g['weight_decay'] = 0.025 * mult`. All other spec elements (arm sweep, decision rules, drift gate) unchanged.
| Arm | NANOGPT_WD_WARMUP_FRAC | Warmup window |
|---|---:|---|
| A | 0.0 (control) | none (constant WD) |
| B | 0.05 | ~170 steps |
| C | 0.10 | ~335 steps |
| D | 0.20 | ~670 steps |
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

### 🔄 edward #474 — AdaBelief for aux groups [assigned 13:45 UTC]

Replace AdamW's `v_t = β₂v_{t-1} + (1-β₂)g_t²` with AdaBelief's `s_t = β₂s_{t-1} + (1-β₂)(g_t-m_t)²` on aux groups. Scope sweep: B=embed only, C=lm_head only, D=all aux. Structurally distinct from all 15 productive-null/negative Adam-family axes tested this cycle. Arm A control about to launch.

---

## Research theme — current cycle

**22 productive-null/negative results** on optimizer-internal / parameter-temporal / loss-side axes. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. Does AdaBelief's variance-of-prediction-error second moment help aux groups? (#474)
2. Does block init scaling matter under Muon? (#452)
3. Does embed-only LR warmup help sparse-row early training? (#489)
4. Does WD warmup reduce early-phase over-regularization? (Muon-WD, #483)
5. Are any cooldown-NS merged components now redundant after later merges? (#487)
6. Does NAdam's Nesterov first-moment help aux groups vs standard AdamW? (#490)
7. Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise? (#506)
8. Does β₁ warmup (lower smoothing early) help aux AdamW groups? (#514, fern new)

**Stack convergence signal**: 22 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **Regularization REDUCTION / "less constraint early" cluster** (in flight): WD warmup (#483), embed-LR warmup (#489), NS-iter warmup (#506), β₁ warmup (#514) — four schedule axes simultaneously probing early-phase deregularization
2. **Adam-family reformulation**: AdaBelief (#474, variance), NAdam (#490, first-moment) complete the three-axis AdamW-internal ablation alongside atan2 (#442 NEGATIVE, magnitude)
3. **Stack simplification** if any pruning (#487) finds redundant components
4. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope, not single-group
5. **NS-iter compute finding (from #470)**: forward/backward is the bottleneck, not NS. Future NS decisions should be motivated by val/loss, not step-time

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
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
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); pruning ablation in-flight (#487 arm B)
- NS cooldown SHAPE=late_peak: MERGED #285; pruning ablation in-flight (#487 arm C)
- NS coef schedule=linear_ramp_down: MERGED #290; pruning ablation in-flight (#487 arm D)
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
