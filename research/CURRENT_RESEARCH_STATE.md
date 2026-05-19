# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-19 17:05 UTC
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

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck (pod-1 Δ=+0.00006, pod-2 Δ=+0.00071). AGC mechanism consistent (99.4% trigger rate across all 3 B runs), but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups** — gradient projection orthogonal to weight direction (structurally distinct from AGC magnitude clipping).

### 🔄 fern #477 — OrthoGrad for aux AdamW groups [assigned 14:20 UTC]

**Branch:** `g1r4-fern/orthograd-aux`
**Hypothesis**: Preprocess AdamW gradient by projecting out the weight-parallel component before AdamW first/second-moment accumulation: `g_perp = g_t − (g_t·w_t / ||w_t||²)·w_t`. Weight-parallel gradient just rescales parameter magnitude — removing it lets AdamW focus on direction signal. Applied only to 2D aux matrices (embed, lm_head); scalars degenerate. Structurally distinct from all 16 productive-null/negative axes this cycle — first gradient-direction-projection mechanism tested.
| Arm | NANOGPT_ORTHOGRAD_SCOPE | Tests |
|---|---|---|
| A | none (control) | Drift gate against baseline 3.27174 |
| B | embed | Sparse-gradient, large ||w||² (~770M) |
| C | lm_head | Dense-gradient, V×768 matrix |
| D | embed_lm_head | Both 2D aux weight matrices |
**ETA full chain:** ~7.3h.

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### 🔄 alphonse #442 — Adam-atan2 update rule [rebased 09:42 UTC, arm A terminal, arm B running]

Replace AdamW's `m/(√v + ε)` with `atan2(m, b·√v)` on aux groups. Arm A rebased (val=3.27213, drift +0.00039 ✓). Sweep b ∈ {0.0 ctrl, 0.3, 1.0, 3.0}. Arm B running.

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

### 🔄 nezuko #454 — lm_head and scalar cooldown shape extension [assigned 09:35 UTC]

Extend embed linear_floor mechanism to lm_head and scalars. Arms: B=lm_head_floor, C=scalar_floor, D=both. Arm B running.

### 🔄 frieren #470 — NS iterations NORMAL phase sweep [assigned 13:10 UTC]

NS_ITERS ∈ {8, 10, 12 ctrl, 14} during pre-cooldown training. First sweep of normal-phase NS precision — all prior NS work touched cooldown side. Arm A running.

### 🔄 edward #474 — AdaBelief for aux groups [assigned 13:45 UTC]

Replace AdamW's `v_t = β₂v_{t-1} + (1-β₂)g_t²` with AdaBelief's `s_t = β₂s_{t-1} + (1-β₂)(g_t-m_t)²` on aux groups. Scope sweep: B=embed only, C=lm_head only, D=all aux. Structurally distinct from all 15 productive-null/negative Adam-family axes tested this cycle. Arm A control about to launch.

---

## Research theme — current cycle

**18 productive-null/negative results** on optimizer-internal / parameter-temporal / loss-side axes. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. Is NS=12 during the normal phase at saturation or below precision floor? (#470)
2. Does AdaBelief's variance-of-prediction-error second moment help aux groups? (#474)
3. Does OrthoGrad (gradient ⊥ to weight) help AdamW aux groups? (#477)
4. Does block init scaling matter under Muon? (#452)
5. Does lm_head/scalar cooldown floor generalize from embed? (#454)
6. Is Adam-atan2 better than AdamW on aux? (#442)
7. Does WD warmup reduce early-phase over-regularization? (Muon-WD, #483 spec corrected)
8. Are any cooldown-NS merged components now redundant after later merges? (#487)

**Stack convergence signal**: 18 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **Regularization REDUCTION**: WD warmup (#483) tests the first deregularization axis this cycle
2. **Precision interactions**: NS iteration count during normal phase (#470) is a clean unexplored 1D axis
3. **Stack simplification** if any pruning (#487) finds redundant components
4. **Second-moment reformulation**: AdaBelief (#474), atan2 (#442) are last structurally-distinct Adam-family axes

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
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
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC: all closed
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); pruning ablation in-flight (#487 arm B)
- NS cooldown SHAPE=late_peak: MERGED #285; pruning ablation in-flight (#487 arm C)
- NS coef schedule=linear_ramp_down: MERGED #290; pruning ablation in-flight (#487 arm D)
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: in-flight (#470)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: in-flight (#454)
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
