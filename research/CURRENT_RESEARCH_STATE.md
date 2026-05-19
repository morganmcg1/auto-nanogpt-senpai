# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-19 14:20 UTC
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

### 🔄 thorfinn #446 — Label smoothing sweep [assigned 08:14 UTC]

Loss-side soft targets: α ∈ {0.0, 0.05, 0.10, 0.20}. Train on smoothed loss; val/loss reported un-smoothed. Arm C running.

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

**15 productive-null/negative results** on optimizer-internal / parameter-temporal axes. The strongest confirmed finding: **the cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts. This has been confirmed by:
- #436 weight-EMA → productive-NEGATIVE (damage scales with averaging window)
- #434 Lookahead → productive-NEGATIVE (regression-monotone, Muon wrapping 4.5× worse than AdamW)
- #399 AdEMAMix → productive-null (redundant with β₂=0.99)
- #419 Cautious AdamW → productive-null (regression on all scopes)

**Current open questions** (in-flight):
1. Is NS=12 during the normal phase at saturation or below precision floor? (#470)
2. Does AdaBelief's variance-of-prediction-error second moment help aux groups? (#474)
3. Does label smoothing help? (#446) / Does z-loss help? (#441)
4. Does block init scaling matter under Muon? (#452)
5. Does lm_head/scalar cooldown floor generalize from embed? (#454)
6. Is Adam-atan2 better than AdamW on aux? (#442)

**Stack convergence signal**: Most axes are converging to productive-nulls. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **Fresh mechanism families**: not optimizer-internal (so not AdaBelief scope, init, loss-side are the most promising)
2. **Precision interactions**: NS iteration count during normal phase (#470) is a clean unexplored 1D axis
3. **Stack tests** if multiple small signals confirm

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
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
- NS_ITERS_COOLDOWN: saturated (#388)
- NS cooldown SHAPE=late_peak: MERGED #285
- NS coef schedule=linear_ramp_down: MERGED #290
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
- Z-loss: in-flight (#441)
- Label smoothing: in-flight (#446)

**Clipping**:
- clip=5 → clip=10: MERGED #165
- AGC (per-parameter): productive-null per paired-pod trajectory (#408)
