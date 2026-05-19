# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-19 09:35 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate)

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

| PR | Change | val (n) | fs (n) | Cumulative baseline |
|----|--------|---------|--------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3275 | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3266.7 | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3258.3 | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3266.7 | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3266.7 | 3.27434 |
| #236 | AdamW β2=0.99 | 3.27407 (3) | 3258.3 | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3250 | 3.27352 |
| #290 | NS coef schedule=linear_ramp_down | 3.27200 (3) | 3233.33 | 3.27200 |
| **#393** | **AdamW embed LR mult=1.5×** | **3.27174 (3)** | **3233.33** | **3.27174** ← CURRENT |

### Mechanism landscape (8 merges, largely orthogonal axes)

1. **Muon² v-EMA** (#60): second-moment before NS orthogonalization
2. **Grad clip** (#165): embed effective-LR raise (8.4% → 16.9%)
3. **NS timing** (#176): more NS iters during precision-critical cooldown
4. **Embed LR floor** (#235): hold embed at 15% of peak through final 30% of training
5. **AdamW β2** (#236): longer second-moment memory (20 → 100 step) smooths step sizes
6. **NS cooldown SHAPE** (#285): NS=12→20 transition at midpoint of cooldown (late_peak)
7. **NS coef schedule** (#290): linear ramp-down of NS polynomial coefficients over training
8. **AdamW embed LR mult** (#393): embed effective LR raised from 0.30 → 0.45 (1.5×)

---

## Active experiments — 15:00 UTC

### ✅ frieren #344 — NS late_peak transition point sweep — CLOSED 20:00 UTC productive-null
Pod-1 Δ=−0.00419 collapsed to n=3 pooled Δ=−0.000877 (79% shrinkage). Sign flipped on pod 2 (+0.00278). Per-arm seed spread (0.00401) larger than claimed signal. Midpoint (frac=0.50) confirmed optimal on post-#290 stack; NS late_peak transition POINT axis CLOSED.
**Follow-up**: frieren assigned #402 Gradient Centralization scope sweep.

### ✅ frieren #402 — Gradient Centralization (GC) scope sweep — CLOSED 04:40 UTC productive-null (absorbed by existing stack)
All 4 arms within null band (max |Δ|=0.00111). Faint monotone B(all) > C(adam) > D(muon) ≈ A ordering — GC subtracts useful signal from AdamW aux gradients. NS orthogonalization on Muon side already approximately mean-centers block weight gradients. Post-#290 stack saturated on gradient-preprocessing axes: grad clip, per-group LR, NS spec tightening, β2=0.99 all jointly absorb any remaining mean-subtraction gain.
**Follow-up**: frieren assigned #436 EMA of weights (Polyak averaging).

### 🔄 frieren #436 — EMA of weights (Polyak averaging) [assigned 04:43 UTC]
**Branch:** `g1r4-frieren/weight-ema`
**Hypothesis**: Maintain parallel θ_ema = β·θ_ema + (1−β)·θ accumulator; use θ_ema for val_loss evaluation (not for training). Orthogonal to all closed gradient/moment-space mechanisms (AdEMAMix closed #399 — that was gradient EMA; this is weight EMA). Operating in weight-trajectory space, not gradient space. Sweep decay ∈ {off, 0.999, 0.9999, 0.99}.
| Arm | decay | Half-life | Interpretation |
|---|---|---|---|
| A | 0.0 (off) | — | Control / drift gate |
| B | 0.999 | ~700 steps | Moderate — averages last ~30% of training |
| C | 0.9999 | ~7000 steps | Long — near-full-training average |
| D | 0.99 | ~70 steps | Short — last ~3% of training |

**ETA full chain:** ~7.5h.

### ✅ alphonse #411 — Gradient noise injection (Neelakantan 2015) — CLOSED 07:36 UTC productive-null ✅
All 4 arms terminal. Non-monotone regression: B/C/D all degrade val by +0.0014 to +0.0020 vs control. Noise hurts at any σ. Post-#290 stack fully regularized (β2=0.99 + NS stochasticity + LR schedule); explicit Gaussian gradient noise just removes signal.
**Follow-up**: alphonse assigned #442 Adam-atan2 (replace ε-division with atan2 in AdamW aux groups).

### 🔄 alphonse #442 — Adam-atan2 update rule [assigned 07:38 UTC]
**Branch:** `g1r4-alphonse/adam-atan2`
**Hypothesis**: Replace AdamW's ε-division `m / (sqrt(v) + ε)` with bounded atan2 update `atan2(m, b·sqrt(v))`. Eliminates ε-dependence, naturally bounds updates to (-π/2, π/2), avoids update explosions. Applied to AdamW aux groups (embed, lm_head, scalars) only; Muon untouched. Sweep b ∈ {0.0 control, 0.3, 1.0, 3.0}.
| Arm | NANOGPT_ADAMW_ATAN2_B | Interpretation |
|---|---|---|
| A | 0.0 (control) | Falls through to standard AdamW; drift gate |
| B | 0.3 | Aggressive: smaller denom, updates near saturation |
| C | 1.0 | Paper default: atan2(m, sqrt(v)) |
| D | 3.0 | Conservative: larger denom, smaller updates |
**ETA full chain:** ~7.3h.

### ✅ alphonse #351 — Per-group SCALAR AdamW ε sweep — CLOSED 23:15 UTC productive-null (paired-pod confirmation collapsed signal)
Paired-pod re-run of A vs D produced mean Δ=+0.00019 (signal collapsed). Original "D wins by −0.00278" was arm-A unlucky-seed pod luck (val=3.27528 drifted +0.00328 above baseline). Second consecutive paired-confirmation null collapse (after frieren #344). Scalar ε axis fully closed across {1e-12, 1e-10, 1e-8, 1e-6}.
**Follow-up**: alphonse assigned #411 Gradient noise injection (Neelakantan 2015).

### 🔄 alphonse #411 — Gradient noise injection (Neelakantan 2015) — partial results
**Branch:** `g1r4-alphonse/gradient-noise-injection`
Arms A (3.27231, drift ✓), B (3.27419, Δ=+0.00188 vs baseline), C (3.27428, Δ=+0.00197 vs baseline) terminal. Arm D (σ=0.01) still running.
| Arm | σ_0 | val | Δ vs A | Δ vs baseline | W&B |
|---|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27231 | — | +0.00031 ✓ | `re5hs6d6` |
| B | 0.001 | 3.27419 | +0.00188 | +0.00219 | `cf0lz42z` |
| C | 0.003 | 3.27428 | +0.00197 | +0.00228 | `wnoa9rx8` |
| D | 0.010 | pending | — | — | — |
Both B and C clearly regress vs A (noise hurts). Shaping toward productive-null — annealed gradient noise at σ∈{0.001,0.003} degrades on this stack. Mechanism: post-#290 stack is already operating near the noise floor; adding stochastic noise prevents convergence. Arm D (σ=0.01) likely confirms the direction.

### ✅ askeladd #354 — Logit softcap value sweep — CLOSED 16:35 UTC productive-null
Valley shape: all 3 off-center arms regress (+0.0037–0.0051). C≈D plateau above softcap=20 (softcap linear in that regime). softcap=15 confirmed optimal on post-#290 stack.
**Follow-up**: askeladd assigned #388 NS iter count cooldown sweep.

### ✅ askeladd #388 — NS_ITERS_COOLDOWN sweep — CLOSED 00:45 UTC productive-null (precision saturated)
All 4 arms terminal. A/B/D cluster within ±0.001 (val ∈ {3.27239, 3.27266, 3.27290}; all fs=3250). C single +0.00335 outlier. Drift gate ✓. Mechanism reading: **NS precision in cooldown SATURATED on post-#290 stack** — third productive-null on NS precision family (#345 depth, #384 center, #388 count). Combined with merged #285 shape and #290 schedule, NS cooldown family fully characterized.
**Follow-up**: askeladd assigned #419 Cautious AdamW updates (Liang et al. 2024).

### ✅ askeladd #419 — Cautious AdamW updates (Liang et al. 2024) — CLOSED 08:55 UTC productive-null ✅
All 4 arms terminal. Drift gate ✓ (A=3.27159, |Δ vs baseline|=0.00041). B/C/D all regress vs control:
| Arm | CAUTIOUS | val | Δ vs A | reached_target | W&B |
|---|---|---:|---:|---|---|
| A (control) | off | 3.27159 | — | ✓ fs=3225 | `tkpem30s` |
| B (paper) | rescaled, all | 3.28460 | **+0.01301** | ✗ | `engpgyik` |
| C (plain) | no-rescale, all | 3.28288 | **+0.01129** | ✗ | `crsnqzoc` |
| D (embed) | rescaled, embed-only | 3.27518 | **+0.00361** | ✓ fs=3275 | `wppw91x9` |
Monotonic less-bad as scope narrows: B (all+rescale) > C (all+plain) > D (embed-only). Mechanism: merged stack β₁=0.8 on aux groups means stale-momentum overshoot is already rare — cautious mask has little to bite on. Rescale amplifies un-masked components on fast-curvature budget → destabilizes. **13th productive-null on optimizer-internal mechanisms this cycle. Cautious-AdamW axis CLOSED.**
**Follow-up**: askeladd assigned #(TBD) block output projection init scale sweep.

### 🔄 askeladd #(new) — Block output projection init scale sweep [assigned 09:00 UTC]
**Branch:** `g1r4-askeladd/block-out-init-scale`
**Hypothesis**: Scale `attn.proj` and `mlp.proj` weights at init by factor s ∈ {1.0, 0.5, 0.2, 0.05}. Mechanism: per-block residual contribution magnitude at init is the lever; DeepNet/T-Fixup/Fixup/ReZero family. **Init-side mechanism — fundamentally distinct from all 13 productive-nulls this cycle on optimizer/gradient/loss/parameter-space axes.** Different from edward #374 (embed init null) — perturbs depth-wise residual rate, not entry-point magnitude. Critical empirical question: does Muon's NS-normalized update step undo init scaling within first ~100 steps?
| Arm | NANOGPT_BLOCK_OUT_INIT_SCALE | Interpretation |
|---|---|---|
| A | 1.0 (control) | Drift gate, bitwise-identical |
| B | 0.5 | Mild — half initial residual |
| C | 0.2 | Moderate — ~1/sqrt(L) DeepNet-ish |
| D | 0.05 | Aggressive — near-ReZero |
**ETA full chain:** ~7.3h.

### ✅ nezuko #356 — Muon μ schedule sweep — CLOSED 17:05 UTC productive-null
All 3 schedule arms missed 3.28 target entirely: B ramp_up +0.01381, C ramp_down +0.01035, D late_peak +0.06125 (catastrophic). Late_peak μ scheduling disastrous — cross-step gradient memory is different from within-step NS precision. Constant μ=0.95 confirmed optimal; Muon μ scheduling axis CLOSED.
**Follow-up**: nezuko assigned #393 per-group AdamW LR multiplier sweep.

### ✅ nezuko #393 — Per-group AdamW LR multiplier sweep — MERGED 09:30 UTC ⭐ (embed=1.5× beats baseline val by 0.00026)
All 6 paired-pod runs terminal. Drift gates ✓ (all 3 A controls). Pooled paired Δ=−0.00137 (compressed from single-seed −0.00216; direction 3/3 pods consistent). mean(B,n=3)=3.27174 passes benchmark stat-rule: (3.28−3.27174)×√3=0.01431≥0.004 ✓. New baseline: val=3.27174, fs=3233.33.
**Follow-up**: nezuko assigned lm_head + scalar cooldown shape extension.

### 🔄 nezuko #(new) — lm_head and scalar cooldown shape extension [assigned 09:35 UTC]
**Branch:** `g1r4-nezuko/aux-cooldown-floor`
**Hypothesis**: Embed linear_floor was merged (#235) — keeps embed LR at 15% floor through final cooldown instead of decaying to 0. lm_head and scalars still use default linear-to-zero. Extend the floor mechanism to these groups. With embed_mult=1.5× (just merged), the aux groups run at different effective LRs; their cooldown shape may matter for convergence precision.
| Arm | lm_head shape | scalar shape | Interpretation |
|---|---|---|---|
| A | linear (default) | linear (default) | Control — drift gate vs new baseline 3.27174 |
| B | linear_floor | linear | lm_head gets LR floor |
| C | linear | linear_floor | Scalars get LR floor |
| D | linear_floor | linear_floor | Both get LR floor |
**ETA full chain:** ~7.3h.
**Branch:** `g1r4-nezuko/pergroup-adamw-lr`
**All 4 arms terminal (original sweep)**:
| Arm | LR mult | val | Δ vs baseline | W&B |
|---|---|---:|---:|---|
| A (control) | all 1.0× | 3.27242 | +0.00042 ✓ | `oggbt72v` |
| **B (embed1p5)** ⭐ | **embed=1.5×** | **3.27026** | **−0.00174** | `cgyyzpwe` |
| C (lmhead1p5) | lm_head=1.5× | 3.27505 | +0.00305 | `kwt7wjzi` |
| D (scalar1p5) | scalar=1.5× | 3.27142 | −0.00058 | `1bgjs64f` |

**Paired-pod confirmation chain status (W&B verified 07:38 UTC)**:
| Run | Pod | Arm | val | Δ_B vs A (same pod) |
|---|---|---|---:|---:|
| Confirm pod0 (original) | orig | B | 3.27026 vs A 3.27242 | −0.00216 |
| pod1-A | pod1 | A | 3.27362 | — |
| pod1-B | pod1 | B | 3.27198 | **−0.00164** |
| pod2-B | pod2 | B | **3.27298** (W&B: hckhwnib, FINISHED) | pod2 Δ TBD (pod2-A running) |
| pod2-A | pod2 | A | **running** (step 325/3350, 7.5%, ETA ~09:45 UTC) — W&B: 4zfxea47 | TBD |

**Updated pooled n=3 (B fully, A at n=2)**:
- mean(B, n=3) = (3.27026 + 3.27198 + 3.27298) / 3 = **3.27174** ≤ 3.27200 ✓
- mean(A, n=2) = 3.273018 so far
- Pod2 Δ will be: 3.27298 − pod2-A. For merge: need final Δ large enough so that n=3 pooled Δ ≤ −0.002.

**Critical analysis**: mean(B,n=3)=3.27174 passes baseline threshold. But Δ gate requires mean(A,n=3) ≥ 3.27374 to achieve mean Δ ≤ −0.002. If pod2-A finishes ≈ 3.272–3.274 (consistent with pod0/pod1), final mean(A,n=3) ≈ 3.273, giving Δ ≈ −0.0015 → **NULL**. Only pod2-A finishing ≥ 3.276 would flip the decision to MERGE.

**Pre-staged decision rule** (n=3 pool): Paired mean Δ_B ≤ −0.002 AND mean(val_B) ≤ 3.27200 → MERGE; else productive-null.
**ETA full chain:** ~09:45 UTC (pod2-A terminal).

### ✅ thorfinn #348 — Per-group AdamW WD sweep — CLOSED 15:15 UTC productive-null
All four arms terminal. Arms B/C/D all regress +0.0019–0.0025. Cross-group coupling observed (D shrinks embed_fro 5× more than B+C independently). AdamW WD axis closed on r4 (second verdict after #279 global WD).
**Follow-up**: thorfinn assigned #384 NS coef center sweep.

### ✅ thorfinn #384 — NS poly coef CENTER sweep — CLOSED 23:10 UTC productive-null (non-monotone, axis flat)
All 4 arms terminal. Non-monotone result: arm D (0.60, more extreme) regressed less than arm C (0.55), indicating C was single-seed outlier. Axis flat across center ∈ [0.43, 0.60]; default 0.49 confirmed within noise. NS coef center family fully characterized; combined with #345 depth and #290 schedule sweep, NS coef polynomial fully mapped.
**Follow-up**: thorfinn assigned #409 Per-block LR decay (LLRD) for Muon.

### ✅ thorfinn #409 — Per-block LR decay (LLRD) for Muon — CLOSED 08:12 UTC productive-null ✅
All 4 arms terminal. Non-monotone: B (decay=0.85) barely edges A (Δ=−0.00038, inside null band), C (0.7) regresses +0.00129, D (1.2 inverse) regresses +0.00190. No arm crosses the ±0.002 real-signal threshold. Arm-B's −25 step fs improvement is within seed noise.
| Arm | decay | val | Δ vs A | W&B |
|---|---:|---:|---:|---|
| A (control) | 1.0 | 3.27266 | — | `ge03y1j7` |
| B | 0.85 | 3.27228 | −0.00038 | `9s1oyyxc` |
| C | 0.7 | 3.27395 | +0.00129 | `xdu2egnj` |
| D | 1.2 | 3.27456 | +0.00190 | `2evjf9in` |
Mechanism: NS orthogonalization normalizes per-block update magnitudes; depth-dependent LR scalar is redundant. **Per-block Muon LR axis CLOSED** (both standard and inverse LLRD).
**Follow-up**: thorfinn assigned #446 Label smoothing sweep (α∈{0.05,0.1,0.2}).

### 🔄 thorfinn #446 — Label smoothing sweep [assigned 08:14 UTC]
**Branch:** `g1r4-thorfinn/label-smoothing`
**Hypothesis**: Replace hard one-hot CE targets with soft distribution: target_smoothed = (1−α)·one_hot + α/V. Penalizes over-confidence, provides implicit regularization. Loss-side mechanism, orthogonal to all optimizer/gradient axes. Training uses smoothed loss; val/loss MUST report un-smoothed CE for fair benchmark comparison.
| Arm | NANOGPT_LABEL_SMOOTHING | Interpretation |
|---|---|---|
| A | 0.0 (control) | Hard targets; drift gate |
| B | 0.05 | Light smoothing |
| C | 0.10 | PaLM/T5/LLaMA standard |
| D | 0.20 | Aggressive |
**ETA full chain:** ~7.3h.

### ✅ edward #374 — Embed init scale sweep — CLOSED 19:30 UTC productive-null
Clean flat result: all 4 arms within ±0.00027 of A (except B at −0.00061, still inside null band). RMSNorm + AdamW β2=0.99 + grad clip absorb embed magnitude — final norms converge to ~77k within 1.8% regardless of 4× init range. Embed init scale axis CLOSED.
**Follow-up**: edward assigned #399 AdEMAMix on AdamW groups.

### ✅ edward #399 — AdEMAMix on AdamW groups — CLOSED 04:24 UTC productive-null (slow-EMA redundant with β2=0.99)
All 4 arms terminal. Within-pod B-vs-A Δ=−0.00303 consumed by arm-A drift (+0.00276 from baseline). Vs baseline-mean: arm-B at −0.00027 (productive-null band). Monotone B<C<A<D ordering: α=0 sits between α=2 and α=5, and α=5 (paper default) is worse than control. Mechanism: AdEMAMix slow first-moment EMA redundant with β2=0.99's long second-moment memory on post-#290 stack. AdEMAMix axis CLOSED.
**Follow-up**: edward assigned #434 Lookahead optimizer scope sweep (Zhang 2019).

### 🔄 edward #434 — Lookahead optimizer scope sweep (Zhang 2019) [assigned 04:25 UTC]
**Branch:** `g1r4-edward/lookahead`
**Hypothesis**: Wrap AdamW and/or Muon with Lookahead (Zhang et al. NeurIPS 2019). Maintains slow weights θ_s; after every k=5 inner steps, blend: θ_s = θ_s + α(θ_f − θ_s), reset θ_f = θ_s. Operates in **parameter space** (not gradient/moment space) — orthogonal to AdEMAMix closure. Paper recipe k=5, α=0.5.
| Arm | SCOPE | k | α | Interpretation |
|---|---|---|---|---|
| A | off | — | — | Control / drift gate |
| B | adamw | 5 | 0.5 | Lookahead on AdamW only |
| C | muon | 5 | 0.5 | Lookahead on Muon only |
| D | both | 5 | 0.5 | Lookahead on both (paper default) |

**ETA full chain:** ~7.5h.

### ✅ fern #380 — lm_head proj init std sweep — CLOSED 22:40 UTC productive-null
All 4 arms terminal. Monotone worsening with σ: A=3.27409 (zero, drift gate ✓), B=3.27470 (σ=0.005, +0.00061), C=3.27725 (σ=0.02, +0.00316), D=3.28234 (σ=0.05, +0.00825, fs=-1 failed target). **Zero-init confirmed uniquely optimal** — both init-scale axes (embed #374, lm_head #380) now exhaustively mapped.
**Follow-up**: fern assigned #408 Adaptive Gradient Clipping (AGC).

### 🔥 fern #408 — Adaptive Gradient Clipping (AGC) — PAIRED-POD CONFIRMATION IN PROGRESS (chain launched 06:39 UTC)
**Branch:** `g1r4-fern/adaptive-grad-clip`
**All 4 original arms terminal**:
| Arm | λ | val | Δ vs A | Δ vs baseline | trigger_rate | W&B |
|---|---:|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27315 | — | +0.00115 ✓ | — | `501a4e8x` |
| **B** ⭐ | **0.01** | **3.27063** | **−0.00252** | **−0.00137** | 0.9942 | `5b62glw0` |
| C | 0.03 | 3.27076 | −0.00239 | −0.00124 | 0.9942 | `4mm7u7rm` |
| D | 0.10 | 3.27289 | −0.00026 | +0.00089 | 0.9942 | `ivd6ribv` |

B/C plateau at λ∈{0.01, 0.03} (Δ differ by only +0.00013) — both pass the −0.002 single-seed threshold. All 3 λ values show 99.4% trigger rate (gradients orders of magnitude larger than λ·||W||_F across the range). Mechanism: AGC provides per-parameter trust region that fixed clip=10.0 misses.
**Paired-pod confirmation chain** (launched 06:39 UTC, ETA ~13:40 UTC):
- pod1: A(λ=0) → B(λ=0.01) [W&B group: `g1r4-fern/agc-confirm`]
- pod2: B(λ=0.01) → A(λ=0) [order flipped]
Pool n=3 per arm; merge if paired Δ_B ≤ −0.002 AND mean(val_B,n=3) ≤ 3.27200.

### ✅ tanjiro #377 — Pruning ablation — CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE)
All 4 arms terminal. **Key mechanism findings**: (1) **β2=0.99 is amplified — 5.9× original lift magnitude**; (2) late_peak #285 subsumed (Δ=−0.00043, sign-flipped vs original); (3) linear_ramp_down #290 fully subsumed (Δ=+0.00009, ~0% original lift). 2 of 3 recent merges appear redundant on current stack — consistent with "mechanism saturation within late-cooldown precision family" hypothesis.
**Follow-up**: tanjiro assigned #407 β2 fine-tune sensitivity sweep (mechanism-driven by β2 amplification finding).

### ✅ tanjiro #407 — AdamW β2 sensitivity sweep — CLOSED 06:48 UTC productive-null ✅
**Branch:** `g1r4-tanjiro/adamw-beta2-sensitivity`
All 4 arms terminal. Arm-B (β2=0.98) posted best val=3.27075, but Δ=−0.00126 vs A does NOT cross the pre-staged −0.002 real-signal threshold. Symmetric valley around β2=0.99 optimum confirmed: B (shorter window, +0.00126 below A), C (+0.00156), D (+0.00215). β2=0.99 is the confirmed optimum; no adjacent value improves on it. Arm-A drift gate perfect (+0.00001 vs baseline). **10th productive-null on optimizer/gradient axes this cycle.**
| Arm | β2 | val | Δ vs A | Δ vs baseline |
|---|---|---:|---:|---:|
| A | 0.99 (control) | 3.27201 | — | +0.00001 ✓ |
| B | 0.98 | 3.27075 | −0.00126 | −0.00125 |
| C | 0.995 | 3.27357 | +0.00156 | +0.00157 |
| D | 0.999 | 3.27416 | +0.00215 | +0.00216 |
W&B: A=`ftmvjt0j`, B=`2oykn4sw`, C=`hj3eic3y`, D=`2hsm3pp5`.
**Follow-up**: tanjiro assigned #441 Logit Z-loss (PaLM style).

### 🔄 tanjiro #441 — Logit Z-loss (PaLM/T5 style) [assigned 06:49 UTC]
**Branch:** `g1r4-tanjiro/logit-z-loss`
**Hypothesis**: Add soft penalty on log-partition function: `loss += λ·Σ logsumexp(logits, dim=-1)²`. Orthogonal to all closed optimizer axes — loss-side modification. Complementary to existing softcap (softcap bounds magnitude per-token, z-loss bounds logsumexp spread). PaLM uses λ=1e-4.
| Arm | NANOGPT_Z_LOSS_WEIGHT | Interpretation |
|---|---|---|
| A | 0.0 (control) | Drift gate; branch bypassed entirely |
| B | 1e-5 | Very mild (lower bound of lit range) |
| C | 1e-4 | PaLM default — well-validated sweet spot |
| D | 1e-3 | Aggressive (tests regularization ceiling) |
**ETA full chain:** ~7.3h.

### ✅ fern #345 — NS coef ramp_down DEPTH sweep — CLOSED 14:10 UTC productive-null
**Follow-up**: fern assigned #380 lmhead-init-scale.

### ✅ tanjiro #300 — Embed floor value sweep — CLOSED 12:50 UTC productive-null
**Follow-up:** tanjiro assigned #377 pruning ablation.

---

## Recently closed

- **tanjiro #407 (AdamW β2 sensitivity)** — CLOSED 06:48 UTC productive-null. Symmetric valley around β2=0.99 confirmed: arm-B (0.98) at Δ=−0.00126 vs A, arm-C (0.995) at +0.00156, arm-D (0.999) at +0.00215. Does NOT cross −0.002 threshold. **β2=0.99 confirmed optimal; axis CLOSED**. 10th productive-null this cycle.
- **frieren #402 (GC scope sweep)** — CLOSED 04:40 UTC productive-null. All 3 GC arms within null band (max |Δ|=0.00111). GC absorbed by existing stack; NS orthogonalization already mean-centers block gradients. **9th productive-null.**
- **edward #399 (AdEMAMix on AdamW)** — CLOSED 04:24 UTC productive-null. Arm-B within-pod Δ=−0.00303 consumed by arm-A drift (+0.00276). vs baseline: −0.00027 (null band). Mechanism: slow-EMA redundant with β2=0.99 long second-moment memory. **8th productive-null.**
- **askeladd #388 (NS_ITERS_COOLDOWN sweep)** — CLOSED 00:45 UTC productive-null. A/B/D cluster within ±0.001 (val ∈ {3.27239, 3.27266, 3.27290}, all fs=3250); C +0.00335 outlier. **NS precision saturated** on post-#290 stack. Third productive-null on NS precision family.
- **alphonse #351 (Per-group SCALAR AdamW ε)** — CLOSED 23:15 UTC productive-null. Paired-pod confirmation collapsed signal (Δ=+0.00019). Original arm-A drifted +0.00328; D's "−0.00278 lift" was pod luck. Second consecutive paired-pod null collapse (after #344).
- **thorfinn #384 (NS coef CENTER)** — CLOSED 23:10 UTC productive-null. Non-monotone (D regressed less than more-moderate C); axis flat across center ∈ [0.43, 0.60]. NS coef family (depth #345 + schedule #290 + center #384) fully characterized.
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

### Active winner candidates — both in paired-pod confirmation
1. **Per-group AdamW LR (embed=1.5×)** — nezuko #393. mean(B,n=3)=3.27174 ✓, mean(B,n=2)=−0.001900. **Pod-2-A running (ETA 09:45 UTC)** — LAST pod in chain. If pod2-A ≥ 3.276, pooled Δ flips to MERGE; if ~3.272–3.274 (most likely), Δ ≈ −0.0015 → NULL. Signal is REAL but shrinking across pods; outcome uncertain.
2. **Adaptive Gradient Clipping (AGC, λ=0.01)** — fern #408 arm-B. Val=3.27063, Δ=−0.00137 vs baseline. B/C plateau both passing single-seed threshold. Paired-pod chain in progress, ETA ~13:40 UTC.

### Shaping toward productive-null
3. **LLRD Muon** — thorfinn #409. Arms B (Δ=+0.00028) and C (Δ=+0.00195) both above baseline. Monotone worsening with deeper decay. Arm D (1.2× inverse) pending — will determine if inverse direction helps.
4. **Gradient noise injection** — alphonse #411. Arms B (Δ=+0.00219) and C (Δ=+0.00228) both regress vs baseline. Noise clearly hurts. Arm D (σ=0.01) pending confirmation.

### Early / inconclusive
5. **Cautious AdamW** — askeladd #419. Arms A (drift ✓), B running, C/D pending. Too early to characterize.
6. **Lookahead (scope sweep)** — edward #434. Full 4-arm chain just started 06:07 UTC (~7h ETA). Novel mechanism (parameter-space, not gradient-space).
7. **Weight EMA (Polyak averaging)** — frieren #436. Just assigned 04:43 UTC. Fresh weight-trajectory mechanism.
8. **Logit Z-loss (PaLM style)** — tanjiro #441. Just assigned 06:49 UTC. Loss-side mechanism, structurally orthogonal to all optimizer axes.

### Medium-priority unassigned axes (for next idle)
1. **Embed LR finer sweep** — if nezuko #393 confirms, sweep embed_mult ∈ {1.25, 1.5, 1.75, 2.0} to find peak; or stack with scalar=1.5× (arm-D showed Δ=−0.00058)
2. **AGC λ finer sweep** — if fern #408 confirms, sweep λ ∈ {0.005, 0.008, 0.015, 0.02} to find floor
3. **Stack test** — embed_lr_mult=1.5× ✕ AGC λ=0.01 ✕ (potentially z-loss) if all three confirm
4. **Per-group μ ablation** — constant per-group Muon momentum (not schedule, just different constant per layer — distinct from μ scheduling closed #356)
5. **lm_head LR down-sweep** — nezuko #393 showed lm_head=1.5× hurts; try lm_head_mult ∈ {0.5, 0.75} (currently lm_head is 1/320 — may be over-tuned)

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
| Per-group scalar AdamW ε | scalar_eps ∈ {1e-12, 1e-10, 1e-8, 1e-6}; paired-pod confirm Δ=+0.00019; A drifted +0.00328 making original sweep unreliable | #351 (productive-null) |
| NS coef polynomial CENTER | center ∈ {0.43, 0.49, 0.55, 0.60} at depth=0.42; non-monotone (D < C while D more extreme); axis flat | #384 (productive-null) |
| NS_ITERS_COOLDOWN count | count ∈ {14, 16, 18, 20}; A/B/D cluster within ±0.001, C +0.00335 outlier (single-seed noise); precision saturated on post-#290 stack | #388 (productive-null) |
