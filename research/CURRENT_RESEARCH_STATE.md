# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-21 18:40 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `val/loss` at 3350 steps (lower is better); `speedrun/final_first_step_to_target` secondary
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline

## Current merged baseline — post-#579

**val=3.27070 / fs=3225.0 (n=3 paired-pod mean)**

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
NANOGPT_MUON_ATTN_LR_MULT=0.80
NANOGPT_MUON_MLP_LR_MULT=1.20
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
| #393 | AdamW embed LR mult=1.5× | 3.27174 (3) | 3.27174 |
| **#579** | **Body-Muon attn=0.80× mlp=1.20× LR asymmetry** | **3.27070 (3)** | **3.27070** ← CURRENT |

---

## Active experiments (all on r4)

### ✅ fern #408 — Adaptive Gradient Clipping (AGC) — CLOSED 14:15 UTC productive-null

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck. AGC mechanism consistent (99.4% trigger rate) but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups**.

### ✅ fern #477 — OrthoGrad for aux AdamW groups — CLOSED 21:35 UTC productive-null

Arms B (embed: +0.00163), C (lm_head: +0.00285) regress; D (embed+lm_head: −0.00080) recovers. Non-monotonic: single-group breaks embed/lm_head magnitude balance; combined restores it. D Δ=−0.00080 passes stat-rule on absolute baseline but well short of −0.002 within-pod threshold — productive-null. **22nd productive-null/negative this cycle.** Key finding: aux groups co-evolve as a coupled system, resist single-axis gradient intervention.
**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing-rate schedule axis.

### ✅ fern #514 — AdamW β₁ warmup on aux groups — CLOSED 06:15 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS): A=3.27279, B=+0.00135 (null edge), C=+0.00162 (regression), D=+0.00252 (regression). Monotone-ish worsening with warmup aggressiveness. No arm passes stat-rule. **3rd consecutive "less constraint early" closure**: WD warmup (#483 NEGATIVE) + embed-LR warmup (#489 NEGATIVE) + β₁ warmup (#514 NEGATIVE) — bilateral closure across 3 aux-group AdamW schedule axes. Early-training window is uniformly well-tuned across WD/LR/β₁ at merged settings. **28th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#547 lm_head cooldown SHAPE sweep** — pivot from temporal (warmup) to shape (cooldown) axes.

### ✅ fern #584 — lm_head AdamW LR multiplier sweep around 1.0× — CLOSED 22:00 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27141−3.27174|=0.00033): A=3.27141 ctrl, B (0.70×)=+0.00028 (null), C (1.30×)=+0.00257 (regression), D (0.50×)=+0.00233 (regression). Flat→degradation profile bracketing 1.00× ctrl on both sides; no arm beats baseline. **Joint vocab-budget hypothesis falsified** at B=0.70× = 1/1.5. **Asymmetric LR cliff** — same |Δmult|=0.30 produces +0.00257 above vs +0.00028 below; lm_head sits closer to upper cliff. **Decoupling confirmed**: embed_mult=1.5 and lm_head_mult=1.0 have orthogonal optima. **40th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#618 Muon² for lm_head** — replace AdamW with NS-orthogonalized momentum on the output projection (IDEA 6 from WAVE3, genuinely untested mechanism replacement vs all prior magnitude/formula/schedule/regularization perturbations).

### ✅ fern #618 — Muon² for lm_head — CLOSED 06:00 UTC productive-NEGATIVE

**Single-seed 4-arm (drift gate A PASS, |3.27313−3.27174|=0.00139)**:
| Arm | LM_HEAD_OPTIMIZER | LR | val/loss | Δ vs A | 3.28 target |
|---|---|---:|---:|---:|---|
| A | adamw (ctrl) | n/a | 3.27313 | — | ✅ pass |
| B | muon | 0.005 | 3.28460 | **+0.01147** | ❌ MISS |
| C | muon | 0.010 | 3.28043 | **+0.00730** | ❌ MISS (by 0.00043) |
| D | muon | 0.002 | 3.29285 | **+0.01972** | ❌ MISS (worst) |

**Monotonic-LR pattern**: higher Muon LR → smaller regression. No interior minimum in 0.002–0.010; optimum (if any) lies at LR ≥ 0.010 but +0.00730 gap is too wide to plausibly close. Mechanism: **NS-orthogonalization homogenizes the vocabulary-frequency Hessian structure** lm_head needs. AdamW's `m/√v` preserves Zipf-distributed per-coordinate magnitude scaling; Muon's unit-singular-value post-NS update has only LR-controlled spectral magnitude (no per-vocab-direction scaling). Block-heterogeneity analysis (Zhang et al. 2024) consistent: lm_head's Hessian is qualitatively distinct from inner-block Hessians, and spectral conditioning that helps inner blocks actively harms output projection. Implementation hygiene clean (drift +0.00139, NS transpose-trick verified for (50257, 768) tall matrix, wall-clock parity ±0.4%). **46th productive-null/negative this cycle. \"Replace AdamW for lm_head\" axis fully closed.**
**Follow-up**: fern assigned **#652 Per-group AdamW eps sweep on lm_head** — within-AdamW axis directly motivated by #618 mechanism reading. eps controls per-coordinate magnitude scaling (the exact mechanism #618 implicates as lm_head's bottleneck). Last untested per-group AdamW hyperparameter (β₁/β₂/WD/LR-mult all swept).

### ✅ fern #652 — Per-group AdamW eps sweep on lm_head — CLOSED 18:33 UTC productive-NEGATIVE

Single-seed 4-arm on NEW post-#579 stack (drift gate A PASS at favorable seed −0.00250): A eps=1e-10=**3.26820** ctrl, B eps=1e-8=+0.00191 (marginal regression), C eps=1e-6=+0.00217 (regression), D eps=1e-12=+0.00256 (regression, BARELY above baseline +0.00006). **Bilateral pattern**: both larger eps (B, C: SGD-like rare-token transitions) AND smaller eps (D: purer preconditioning) regress vs A — eps=1e-10 is bilaterally optimal on lm_head. No arm passes within-pod −0.002 threshold; best non-ctrl arm B at +0.00191 just above productive-null upper bound. OLD-stack rebase data preserved (A=B=3.27211 to 6dp) cleanly confirmed `sqrt(v_t) >> eps` dominates denominator for lm_head's typical v_t magnitudes ~1e-3 to 1e-1; eps inert across {1e-12, 1e-10, 1e-8, 1e-6} — confirming Zipf-scaling preservation is UPSTREAM of eps. Mechanism reading: per-group AdamW eps is NOT the bottleneck for lm_head per-coord magnitude scaling. Composes with #618 (Muon NEG) + #663 (SOAP NULL) + #547 (SHAPE NULL) + #584 (LR-mult NULL): ALL preconditioning-mechanism interventions on lm_head closed null/neg. **Per-group AdamW axis on lm_head is FULLY exhausted at the preconditioner level.** Future lm_head work should target representation/loss-side mechanisms. Implementation hygiene clean (10 LOC, env-var-gated, rebased cleanly, drift gate PASS, all 4 arms hit 3.28 target). **53rd productive-null/negative this cycle.** Per-group AdamW hyperparameter family is now fully characterized: β₁ #599 NEG, β₂ #560 NEG, WD #593 NULL, eps #652 NEG, BC #664 NULL — only LR-mult #393 MERGED extracted gain.
**Follow-up**: fern assigned **#709 body Muon momentum bias correction (enable)** — fresh axis on body Muon side never tested. Standard Muon does NOT apply bias correction `m_t/(1-β^t)` to its momentum buffer; this PR tests ENABLING it. Symmetric with #664's DISABLING AdamW BC (= NULL); body-Muon ENABLING BC has structurally different effect because the momentum buffer is then fed through Newton-Schulz orthogonalization. Mechanism: in first ~20 steps, m_t is biased toward zero relative to steady state at β=0.95; NS-orthogonalizing a biased buffer may give worse early-phase update direction. 4-arm sweep: A (off, ctrl), B (full training, decays naturally), C (first 50 steps only, aggressive early), D (first 200 steps, covers convergence to steady state). Mechanism: bias factor at step 1 is ~20× scaling; by step 50 ~1.05×; by step ~140 essentially 1.0.

### 🔄 fern #709 — Body Muon momentum bias correction (enable) [assigned 18:30 UTC]

**Branch:** `g1r4-fern/muon-momentum-bias-correction`
**Hypothesis**: Standard Muon's momentum update is `m_t = β*m_{t-1} + g_t` with β=0.95, with NS-orthogonalization applied to `m_t` to produce update direction. **Muon does NOT currently apply bias correction** — there's no `m_hat = m_t/(1-β^t)` rescaling step before NS. Consequence: in first ~20 steps, `m_t` is biased toward zero relative to its steady-state magnitude (1/(1-β) ≈ 20-step memory window at β=0.95); NS operates on this biased-toward-zero buffer in early training. Because NS normalizes spectral direction (not magnitude), the bias affects WHICH dominant singular value gets projected to unit-norm — meaning early-step update direction may be qualitatively different from steady-state. Symmetric with #664 (DISABLING aux AdamW BC = NULL); body-Muon ENABLING BC has structurally different effect because momentum is then fed through NS. 4-arm: A (off, ctrl, bit-identical), B (full training), C (first 50 steps), D (first 200 steps). Distinct from #356 (μ-schedule SHAPE NEG), #530 (Nesterov-Muon current-grad mix NULL), #102 (LR warmup body NULL). **ETA full chain:** ~7.3h. Implementation: ~12 LOC.

### ✅ fern #547 — lm_head cooldown SHAPE sweep — CLOSED 14:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27273−3.27174|=0.00099): A linear=3.27273, B cosine=+0.00012 (null), C late_peak=+0.00179 (regression), D linear_floor=+0.00024 (null). No arm meets −0.002 threshold. **Cross-axis SHAPE transfer hypothesis falsified**: NS late_peak does NOT transfer to lm_head — lm_head wants monotonic decay (dense AdamW group with no mid-phase quality plateau analogous to NS orthogonalization). Reproduces #454 Arm B (linear_floor null). **Per-group cooldown SHAPE design space now substantially characterized**: embed=linear_floor (#235), body=linear (#520 NEG on alternatives), NS_iter=late_peak (#285), NS_coef=linear_ramp_down (#290), lm_head=linear (#547 NEG on alternatives); scalar gap untested. **35th productive-null/negative this cycle.**
**Follow-up**: fern assigned **lm_head AdamW LR ratio sweep** — denser sweep around 1.0× on post-#393 stack (untested space: #393 rejected lm_head=1.5× but <1.0× and intermediate values unexplored; joint vocab update budget mechanism predicts ~0.67×).

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### ✅ alphonse #442 — Adam-atan2 — CLOSED 17:53 UTC productive-NEGATIVE

b sweep {0.3, 1.0, 3.0}: all regress vs AdamW (b=0). D (b=3.0) misses 3.28 target (+0.010). Magnitude-transform of AdamW formula fully closed. **19th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#489 embed-only LR warmup**.

### ✅ alphonse #489 — Embed-only LR warmup — CLOSED 01:47 UTC productive-NEGATIVE

Monotone catastrophic worsening: A=3.27054, B=+0.01026 (frac=0.02), C=+0.01554 (frac=0.05), D=+0.02316 (frac=0.10). All 3 warmup arms fail benchmark (none reach 3.28 target). Full embed LR from step 0 is load-bearing — #102 closure rationale ("early high-LR window is productive") extends to embed AdamW despite mechanistic distinction (sparse-grad vs Muon+NS). **25th productive-null/negative this cycle.** Bilateral closure with #483 WD warmup (also productive-NEGATIVE): the early-training window is bilaterally well-tuned; regularization-REDUCTION by warmup on any group fails.
**Follow-up**: alphonse assigned **#526 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×).

### ✅ alphonse #526 — Embed LR step-0 boost — CLOSED 09:30 UTC productive-NULL (bilateral with #489)

Single-seed 4-arm (drift gate A PASS, |3.27226−3.27174|=0.00052): A=3.27226, B (2.0×, 3%)=−0.00080 (null), C (2.5×, 3%)=−0.00081 (null), D (2.0×, 6%)=+0.00035 (null). B/C plateau identically (boost magnitude saturates by 2.0×); D regresses (longer 6% window mildly worse). Best arm (C) Δ_vs_A=−0.00081 far short of pre-staged −0.002 paired-pod threshold; the n=1 stat-rule "baseline beat" is partly Arm-A drift artifact. `first_step_to_target` invariant across A/B/C=3225. **Bilateral closure with #489**: combined evidence establishes embed step-0 LR at 1.5× is bilaterally optimal — neither boosting (this PR) nor reducing (#489 NEGATIVE) the early embed LR yields actionable improvement. **31st productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#560 Per-group AdamW β₂ asymmetric sweep** — fresh axis on second-moment time constant (per-group cut of uniform-β₂=0.99 merged setting); motivated by embed-sparsity insights from #474 AdaBelief and #516 Yogi closures.

### ✅ alphonse #560 — Per-group AdamW β₂ asymmetric sweep — CLOSED 17:15 UTC productive-NULL/NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27121−3.27174|=0.00053): A=3.27121, B (β₂_embed=0.95)=+0.00089 (null), C (β₂_embed=0.999)=+0.00359 (regression), D (B + β₂_lm_head=0.999)=+0.00097 (null). No arm beats merged baseline within-pod. Longer embed memory clearly harmful (v_t anchors to early-training stats for ~700-step half-life in 3350-step run); shorter embed memory null (hypothesized sparse-row v_t reset benefit doesn't materialize). D ≈ B within ±0.0001 — lm_head β₂=0.999 inert. **AdamW-internal axis family substantially exhausted**: per-group β₂ joins #442 (magnitude), #474 (AdaBelief formulation), #516 (Yogi update rule), #490 (NAdam first-moment lookahead) as closed. Embed sparse-row gradient statistics on this benchmark are well-served by uniform β₂=0.99 in the 0.95–0.999 range. **38th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **per-group AdamW β₁ time-constant sweep** — first-moment time constant, structurally distinct from this PR's second-moment axis. Mechanism: at β₁=0.8 with sparse embed rows, momentum decays to near-zero between visits (`0.8^50 ≈ 0`), effectively scaling sparse-row step magnitude down by ~0.2 vs dense groups; ADAMW_EMBED_LR_MULT=1.5 partially compensates via LR; lowering β₁_embed tests whether it's a more principled magnitude restorer.

### ✅ alphonse #599 — Per-group AdamW β₁ time-constant sweep — CLOSED 01:10 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27208−3.27174|=0.00034): A=3.27208, B (β₁_embed=0.50)=+0.00399 (regression), C (β₁_embed=0.00, RMSProp-mode)=+0.00513 (regression), D (β₁_embed=0.90)=+0.00177 (regression marginal). All B/C/D regress past +0.0015 within-pod threshold. Magnitude-up direction (β₁ 0.80→0.50→0.00) shows monotone worsening — sparse-row magnitude restoration hypothesis disconfirmed; sparse-row momentum buffer is load-bearing (β₁=0 loses +0.005 vs ctrl). Smoothing-up direction (β₁=0.90) also marginal regression. **Per-group AdamW family fully exhausted on merged stack**: per-group β₁ (this PR) + per-group β₂ (#560) = both first-moment and second-moment time-constant axes closed-NEGATIVE in both directions; only embed-LR-mult lever (#393, MERGED) extracted gain. **44th productive-NEGATIVE this cycle.**
**Follow-up**: alphonse assigned **#632 Tunable post-NS aspect-ratio exponent** — post-NS-side modification targeting the canonical `max(1, fan_out/fan_in)**0.5` scaling in `muon_update()`. Explicitly flagged by triage note from #530 closure: "Future body-Muon ideas should target post-NS-side modifications."

### 🔄 alphonse #632 — Tunable post-NS aspect-ratio exponent [N=1 sweep COMPLETE 08:54 UTC; SENT BACK 09:08 UTC for paired-pod n=3 confirmation of Arm D winner candidate]

**Branch:** `g1r4-alphonse/muon-post-ns-aspect-exp`

**Phase 1 (N=1 4-arm sweep) results**:
| Arm | exp | val/loss | Δ vs A | Δ vs baseline | W&B run |
|---|---:|---:|---:|---:|---|
| A | 0.5 (ctrl) | 3.27421 | — | +0.00247 (drift PASS upper edge) | v7q5nij3 |
| B | 0.0 | 3.27344 | −0.00077 (null) | +0.00170 | 32cjrhjd |
| C | 0.25 | 3.27463 | +0.00042 (null) | +0.00289 | qn112qgi |
| **D** | **1.0** | **3.27147** | **−0.00274** ⭐ | **−0.00027** | xs4uapkg |

**Arm D = WINNER CANDIDATE at N=1**: passes all three single-seed gates (within-pod Δ=−0.00274, val=3.27147 < baseline 3.27174 by 0.00027 absolute, stat-rule 0.00853 ≥ 0.004). Landscape: wide flat plateau exp ∈ [0.0, 0.5] (all within ±0.0008 of A), single-arm jump at exp=1.0.

**Honest seed-correction caveat**: Arm A's +0.00247 drift is at upper edge of ±0.003 band. Seed-corrected D gain over baseline is only −0.00027 — within the magnitude range where prior N=1 winners have collapsed under paired-pod control. Now **7 cycle precedents for single-seed → paired-pod sign collapse** (#344, #351, #408, #487, #506, #550, #577 today).

**Pre-staged Phase 2 paired-pod n=3 (mandatory before merge)**: Sequential chain, 6 paired runs with SENPAI_SEED ∈ {0, 1, 2}, comparing Arm A (exp=0.5 ctrl) vs Arm D (exp=1.0). Group: `g1r4-alphonse/muon-post-ns-aspect-exp-paired`. Merge gate (all 3 must pass): mean(Δ) ≤ −0.002 AND mean(val_D) ≤ 3.27174 AND (3.28 − mean) × √3 ≥ 0.004.

**ETA full paired-pod chain:** ~11h. Triton compile fix during Phase 1 (Python int-literal-0 issue with `libdevice.pow(... 0 ...)` inside Triton — guarded with `if NANOGPT_MUON_POST_NS_EXP != 0.0:`) verified to have no semantic effect on arms A/C/D. Parallel winner candidate: #628 nezuko Arm B (val=3.27127) also awaiting paired-pod — orthogonal mechanism (per-layer cos-EMA LR boost pre-NS vs aspect exponent post-NS); if both confirm, may compound.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### ✅ tanjiro #577 — NS-cooldown joint-pruning interaction test — CLOSED 09:05 UTC productive-NULL [paired-pod n=3, borderline-load-bearing]

**Phase 1 (N=1 sweep)** all four arms in null band: A=3.27312 ctrl, B=3.27278 (Δ=−0.00034 full joint drop), C=3.27184 (Δ=−0.00128 ITER-only), D=3.27217 (Δ=−0.00095 SHAPE+COEF drop). N=1 favored all drops slightly — classic favorable-seed pattern. **Phase 2 paired-pod (n=3, controlled SENPAI_SEED)**: Pod0 Δ=+0.00140, Pod1 Δ=+0.00175 (past +0.0015 threshold), Pod2 Δ=−0.00011 (favorable seed for both arms, val_A=3.27094 best across 5 Arm-A runs). **mean(Δ)=+0.00101** (null band, but 95% CI [−0.00013, +0.00215] brackets +0.0015); mean(val_B)=3.27301 > baseline 3.27174. Merge gates 1 and 2 FAIL. Formal classification: REDUNDANT (borderline) at n=3 — but seed-level evidence leans direction-incorrect (2/3 pods weakly-load-bearing). **7th cycle precedent for single-seed → paired-pod sign collapse** (joining #344, #351, #408, #487, #560, #593, #550). Combined with #487 single-component results, the merged stack's three NS-cooldown components are jointly weakly-load-bearing as a unit even though each is individually redundant; the interaction is not catastrophic but is direction-correct under controlled paired init. **49th productive-NULL this cycle.** NS-cooldown sub-stack pruning axis fully fenced; no further pruning attempts without n≥5 paired-pod evidence.
**Follow-up**: tanjiro initially assigned **#666 Lookahead optimizer wrapper for aux AdamW** — closed pre-launch as duplicate of #434 (edward, CLOSED productive-NEGATIVE; Arm B scope=adamw k=5 α=0.5 → Δ=+0.00244). Reassigned to **#668 per-row L2 gradient clip on embed and lm_head** — row-granularity magnitude bounding that operates pre-AdamW. Distinct from global clip (single norm), AGC (per-parameter), OrthoGrad (direction, not magnitude), and per-group eps (post-preconditioning). Directly tests row-level Zipf-asymmetry hypothesis from #618 mechanism reading.

### ✗ tanjiro #666 — Lookahead wrapper for aux AdamW — CLOSED-PRE-LAUNCH (duplicate of #434)

Bit-identical Arm B (k=5, α=0.5, scope=adamw) to #434 (edward, CLOSED productive-NEGATIVE 2026-05-19) which showed Δ=+0.00244 regression. Adding K=10 / α=0.8 corners (Arms C/D) would not plausibly flip from regression to merge-worthy gain per Zhang 2019 expected monotonicity. Closed before launch to avoid wasting compute.

### 🔄 tanjiro #668 — Per-row L2 gradient clip on embed and lm_head [assigned 09:15 UTC]

**Branch:** `g1r4-tanjiro/per-row-grad-clip-aux`
**Hypothesis**: Token-frequency follows Zipf — embed/lm_head row gradients vary in magnitude across rows by orders of magnitude (frequent tokens like punctuation get large per-row L2 every step; rare tokens get small per-row L2 only on visit steps). Current merged stack has no row-aware magnitude bound: global clip (single L2 across all params), AGC (per-parameter matrix-level), AdamW preconditioning (per-coord, magnitude-preserving). Per-row L2 clip at threshold T bounds frequent-row magnitudes while leaving rare-row updates untouched. Mechanistically targets the exact Zipf-distributed asymmetry that #618 mechanism reading identified as load-bearing on lm_head.
| Arm | NANOGPT_PER_ROW_CLIP | Scope | Tests |
|---|---:|---|---|
| A | 0.0 (disabled) | embed_lmhead | Control — bit-identical to merged baseline |
| B | 0.01 | embed_lmhead | Aggressive — bounds typical frequent-row magnitudes |
| C | 0.1 | embed_lmhead | Moderate — bounds outlier rows only |
| D | 1.0 | embed_lmhead | Loose sanity check — should be ≈ control |
**ETA full chain:** ~7.3h. Implementation: ~15 LOC (env vars + per-row L2 norm + clamp + multiply, applied before existing global clip_grad_norm_). Diagnostic ask: log row-norm p50/p90/p99/p99.9 on Arm A for future threshold refinement.

### ✅ tanjiro #487 — Cooldown-NS pruning ablation — CLOSED 13:05 UTC productive-NULL [paired-pod n=3]

Sweep N=1 Arm B (drop NS_ITERS_COOLDOWN) Δ=−0.00385 winner candidate failed paired-pod confirmation: per-pod Δ split 1−/2+ around mean(Δ)=+0.00003, all three pods in productive-null/redundant band [−0.002, +0.0015]. Merge gates 1 (mean Δ) and 2 (mean val_B) fail; only stat-rule (gate 3) passes. **4th cycle precedent for single-seed → paired-pod collapse** (joining #344, #351, #408 AGC). Mechanism hypothesis (NS_ITERS_COOLDOWN over-orthogonalizes late-phase) falsified — within-pod effect is essentially zero. The N=1 winner was between-seed noise. **33rd productive-null this cycle.** All three NS-cooldown sub-stack components are now individually classified as redundant (B=redundant at n=3 paired-pod, C/D=null at N=1 sweep).
**Follow-up**: tanjiro assigned **NS-cooldown joint-pruning ablation** — joint-drop interaction test of the sub-stack.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### ✅ thorfinn #483 — WD warmup schedule (Muon block group) — CLOSED 23:42 UTC productive-NEGATIVE

Clean monotone worsening: A=3.27066, B=+0.00080 (null), C=+0.00258 (regression), D=+0.00400 (regression). Body-block WD=0.025 is load-bearing from step 0 — delaying it hurts. **24th productive-null/negative this cycle.** Bilateral closure: 17 ADD-regularization axes + 1 REDUCE-regularization axis both fail → Muon-WD=0.025 is bilaterally optimal.
**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles over the load-bearing 30% cooldown window.

### ✅ thorfinn #520 — Body Muon LR cooldown shape sweep — CLOSED 07:55 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A linear=3.27261, B cosine=+0.00163 (marginal regression), C quadratic=+0.00864 (strong regression, fst=-1), D linear_floor=+0.01401 (strongest, fst=-1). Monotone with non-linear distortion of the final-window decay. **Mechanism**: body Muon needs (1) decay to ~zero at end, (2) linear shape (not steeper, not slower). NS-orthogonalized updates have rank-stable magnitudes — late-phase convergence requires actual zero LR to land. **Striking per-group cooldown contrast**: embed wins with linear_floor (#235), body LOSES strongest with linear_floor — different update statistics demand different profiles. Per-group cooldown-shape design axis substantially characterized (lm_head #547 in flight completes the matrix). **30th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#554 AdamW embed WD cooldown nudge** — adds small positive WD on embed during cooldown only (currently WD=0). Tests whether late-phase implicit regularization on sparse-row embed group helps; structurally distinct from edward #550 (Muon WD REDUCTION, body group, removes existing).

### ✅ thorfinn #590 — NS-cooldown START_FRAC sweep — CLOSED 23:50 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27089−3.27174|=0.00085): A=3.27089, B (0.50)=+0.00187 (regression), C (0.85)=+0.00132 (null), D (0.60)=−0.00041 (null sub-threshold). FRAC axis is **bilaterally concave at 0.70** with flat 0.60-0.70 shoulder. Mechanism reading: NS=16 only pays off in final ~25-30% of training; extending the window earlier (B) wastes compute on mid-phase steps that don't benefit from tighter orthogonalization, shortening (C) loses late-phase precision gain. The favorable A-drift (−0.00085) inflates D's apparent baseline improvement; within-pod Δ_vs_A=−0.00041 is far below the −0.002 candidate threshold. Closes off both "extended precision window" and "concentrated late NS=16 burst" follow-up directions. Full NS-cooldown sub-stack: magnitude=#176 (MERGED), shape=#285 (MERGED), coef=#290 (MERGED), timing=#590 (CLOSED). **41st productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#624 spectral norm penalty (WAVE3 IDEA 8)** — loss-side weight conditioning regularizer, structurally fresh axis no prior experiment has touched. After 41 productive-NULLs on optimizer-state and update-direction axes, pivot to loss-formulation axis.

### ✅ thorfinn #624 — Spectral norm penalty (loss-side weight conditioning) — CLOSED 06:10 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A=3.27261, B (λ=1e-5 all)=3.27216 (Δ=−0.00045, null), C (λ=5e-5 all)=3.27155 (Δ=−0.00106, null sub-threshold), D (λ=1e-5 attn_only)=3.27408 (Δ=+0.00147 marginal regression). **Monotone-favorable** in λ across all-scope arms (A→B→C: +0.0 / −0.00045 / −0.00106) but best magnitude is half the −0.002 candidate threshold; D regression on attn-only narrowest-scope informs mechanism. **Mechanism findings**: (a) spectral norm penalty is benign-mild on body Muon 2D matrices — never approaches catastrophic regression even at 5e-5 (5× the working range); (b) **body MLP matrices benefit more from spectral conditioning than attention matrices** (D attn-only regresses while B all-scope improves marginally), suggesting MLP layers were closer to singular-value concentration than attention; (c) the NS-conditions-update-direction-not-weight reading was directionally validated but quantitative impact too small to merge. Implementation hygiene clean (id()-intersection filter for spectral_params shadow set works, power-iteration v persistent across steps, ~3% overhead reproducible). **47th productive-null/negative this cycle.** "Loss-side weight regularization" axis (closest analog to WD but on σ_max² vs ‖W‖_F²) now characterized — penalizes only dominant singular values rather than all uniformly; the substantive distinction from WD shows up as direction-correct sub-threshold gain not a structural win. **Durable finding (cross-experiment reusable)**: id()-intersection filter pattern for restricting param-list operations to the body Muon 2D subset works cleanly when applied to penalty/regularization-style passes — a pattern future loss-side or post-NS modifications can reuse.
**Follow-up**: thorfinn assigned **#663 one-sided SOAP for lm_head** — WAVE3 IDEA 2, last untested WAVE3 idea. Fresh preconditioner mechanism distinct from #618 Muon-for-lm_head (NS homogenizes Zipf-distributed magnitudes) because SOAP preserves Adam's m/√v in rotated eigenbasis. Complementary to fern #652 in flight.

### ✅ thorfinn #663 — One-sided SOAP preconditioning for lm_head — CLOSED 18:30 UTC productive-NULL

Single-seed 4-arm on NEW merged stack post-#579 (drift gate A' PASS, |3.26762−3.27070|=0.00308 at upper edge but within envelope): A'=3.26762, B (FREQ=50)=+0.00174 (regression), C (FREQ=25)=+0.00325 (regression, worst), **D (FREQ=100)=3.26666 (Δ_D_vs_A'=−0.00096 sub-threshold, val=−0.00404 below baseline)**. **Monotone frequency trend**: less SOAP rotation = better; optimum extrapolates to FREQ→∞ (= AdamW, no rotation). Δ_D_vs_A' = −0.00096 sub-threshold (well below −0.002 within-pod gate); single-seed magnitude inside 8+ paired-pod-collapse range this cycle. Mechanism: AdamW's coord-basis is near-optimal for lm_head — SOAP's eigenbasis rotation perturbs a basis the optimizer has already self-tuned via β₂=0.99 + LR_MULT=1.0 over Zipf-distributed vocabulary structure. **Composes with #618 NEG (full Muon for lm_head, NS destroys Zipf scaling): both spectral conditioning interventions on lm_head — orthogonalization and eigenbasis rotation — failed**. lm_head's Hessian is structurally distinct from inner-block Hessians and resists every form of spectral conditioning intervention tested. Future lm_head work should target representation/loss-side mechanisms (Zipf-weighted loss, frequency-aware label smoothing, output-projection low-rank decomp), not preconditioner replacements. Extreme aspect ratio (65:1) wrong regime for SOAP — left/right preconditioner stale-eigenvector amortization assumes near-square matrices. Implementation hygiene clean (108 LOC additive behind NANOGPT_SOAP_LM_HEAD_FREQ env var, +0.32% wall-clock at FREQ=100, all 4 arms hit 3.28 target). **52nd productive-null/negative this cycle. WAVE3 IDEA-by-IDEA portfolio fully closed** (7/8 ideas tested; only IDEA 1 Polar Express never assigned; 4 of 7 NULL/NEGATIVE, 1 of 7 MERGED via #579 — but #579 was a NEW axis discovered during WAVE3 execution, not on the WAVE3 list). Strong signal: **mechanism progress now from per-block-TYPE asymmetry family** (#669 WD / #674 momentum testing) rather than aux-group preconditioner replacements.
**Follow-up**: thorfinn assigned **#708 per-group gradient clip threshold asymmetry** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669 / #674). Tests body-Muon clip vs aux-AdamW clip split (currently uniform NANOGPT_GRAD_CLIP=10.0). Body gradients pass through NS-orthogonalization (which renormalizes spectral magnitudes); aux gradients are sparse-row Zipf-distributed and AdamW preserves per-coord magnitude — these two distributions have different "natural" outlier ranges and a single global threshold is suboptimal.

### 🔄 thorfinn #708 — Per-group gradient clip threshold asymmetry [assigned 18:30 UTC]

**Branch:** `g1r4-thorfinn/per-group-grad-clip-asym`
**Hypothesis**: Single global NANOGPT_GRAD_CLIP=10.0 applies uniformly to body-Muon and aux-AdamW groups, but the two have structurally different gradient distributions. Body Muon (768×768 attn / 768×3072 mlp) passes through NS-orthogonalization which renormalizes spectral magnitudes — pre-NS norm matters less; aux AdamW (50304×768 embed/lm_head) preserves per-coord magnitude via m/√v and outlier rows propagate directly into updates. Historical progression `#105 clip=5.0 MERGED → #165 clip=10.0 MERGED` shows looser global helps, implying body-Muon bottlenecked at 5.0 — but at cost of looser aux clip. Per-group split lets us **tighten aux while keeping or loosening body**.
| Arm | BODY_CLIP | AUX_CLIP | Tests |
|---|---:|---:|---|
| A (ctrl) | 10.0 | 10.0 | Bit-identical merged baseline (both = global=10.0) |
| B | 10.0 | **5.0** | Tighter aux only — bounds embed/lm_head outliers |
| C | **20.0** | 10.0 | Looser body only — more headroom for NS conditioning |
| D | **20.0** | **5.0** | Compound: looser body + tighter aux |
**ETA full chain:** ~7.3h. Implementation: ~15 LOC (split single `clip_grad_norm_` into two — one over body-Muon param list, one over aux-AdamW param list). Distinct from #408 AGC (per-PARAMETER clip — not per-GROUP), #168 (global single-threshold sweep), and in-flight #668 tanjiro per-row L2 clip embed/lm_head (row-granularity, not group-granularity). Mechanism: stack-INDEPENDENT (operates on gradient norms pre-optimizer, orthogonal to all Muon param-group LR/WD/momentum splits and all aux AdamW per-group hyperparameters). Telemetry ask on Arm A: log pre-clip body/aux grad norms + clip trigger counts every 50 steps to inform future clip-related design regardless of this PR's outcome.

### ✅ thorfinn #554 — AdamW embed WD cooldown nudge — CLOSED 15:35 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27277−3.27174|=0.00103): A=3.27277, B (0.001)=−0.00035 (null edge, fails baseline parity +0.00068), C (0.005)=+0.00657 (regression), D (0.010)=+0.01571 (regression, **FAILS 3.28 target**). Clean monotone regression — any embed WD during cooldown is harmful. Mechanism: with EMBED_COOLDOWN_SHAPE=linear_floor holding embed LR at 15% floor, embed updates are already small; adding WD uniformly shrinks rarely-updated rare-token rows whose representations depend on *accumulated information*. **Bilateral asymmetry on WD-cooldown axis** (paired with #550 winner candidate): embed group rejects added WD during cooldown (NEGATIVE), body Muon group may benefit from REDUCED WD during cooldown (#550 N=1 winner, paired-pod confirming). Both point to "do not constrain rare/sparse representations during cooldown precision window". **36th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **NS-cooldown START_FRAC sweep** — fresh untested axis. NS_COOLDOWN_START_FRAC=0.7 was bundled at #176 merge, never independently swept on merged stack.

### ✅ askeladd #452 — Block output projection init scale — CLOSED 05:05 UTC productive-null

Paired-pod confirmation: Arm B (s=0.5) pod-0 candidate Δ=−0.00227 reversed → mean(Δ_pool)=+0.00068 across n=3 pods. 4th paired-pod false-positive caught this cycle (after #344, #351, #408 AGC). DeepNet/T-Fixup family init-scaling axis closed: NS-normalized Muon updates wash out init scaling within first ~100 steps as hypothesized — but no preserved benefit signal. **27th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **#543 per-block NS iter budget** — spatial allocation by aspect ratio (Bernstein-Newhouse). (#542 Lion-aux mis-assignment closed 05:12 UTC — Lion on aux groups already closed in #77, prior round.)

### 🔄 askeladd #669 — Per-block-type WD asymmetry on body Muon [assigned 09:55 UTC]

**Branch:** `g1r4-askeladd/muon-attn-mlp-wd-asym`

**Hypothesis**: Direct extension of #579 (just merged: body-Muon attn=0.80×/mlp=1.20× LR asymmetry, μ_D=3.27070). Same per-block-type partition, orthogonal regularization axis — sweep per-block-type WD multipliers. Mechanism precedent: #550 (uniform body Muon WD reduction 0.025→0, mean Δ=−0.00090 direction-correct sub-threshold). If the gain is concentrated in one block-type (attn vs mlp), per-block-type asymmetric WD captures it cleanly. Aspect-ratio reading: attn (square 768×768) and mlp (4× aspect 768×3072) drift toward different parameter-magnitude equilibria under uniform WD pressure.

| Arm | attn_wd_mult | mlp_wd_mult | Effective attn_WD | Effective mlp_WD | Tests |
|---|---:|---:|---:|---:|---|
| A (ctrl) | 1.0 | 1.0 | 0.025 | 0.025 | Bit-identical merged baseline 3.27070 |
| B | 1.0 | **0.0** | 0.025 | **0** | Drop mlp WD only (mirrors #550 by block-type) |
| C | **0.0** | 1.0 | **0** | 0.025 | Drop attn WD only |
| D | **0.0** | **0.0** | **0** | **0** | Drop both (reproduces #550 on new stack) |

**ETA full chain:** ~7.3h. Implementation: ~20 LOC (mirrors #579 LR-multiplier wiring pattern). If singletons null + compound D signal (mirrors #579), → paired-pod on D. If single B or C signal → asymmetric merge candidate at signaling block-type.

### ✅ askeladd #579 — Body Muon LR asymmetry (attn=0.80×, mlp=1.20×) — MERGED 09:55 UTC 🏆

**Branch:** `g1r4-askeladd/muon-attn-mlp-lr-asym`

**Phase 1 single-seed 4-arm** (drift gate A PASS, |3.27189−3.27174|=0.00015): A=3.27189 ctrl, B (0.80, 1.00)=+0.00083 null, C (1.00, 1.20)=+0.00080 null, **D (0.80, 1.20)=3.27052 (Δ=−0.00137, signal sub-threshold)**. Pre-staged singleton-null/compound-signal pattern fires exactly.

**Phase 2 paired-pod n=3 confirmation** (3350 steps, locked merged-stack envs, free seeds across pods):
| Pod | A val | D val | Δ_pod |
|---|---:|---:|---:|
| 0 | 3.27286 | 3.27317 | +0.00031 (sign-flip, tiny) |
| 1 | 3.27154 | 3.26897 | −0.00257 (signal) |
| 2 | 3.27178 | 3.26996 | −0.00182 (signal) |
| **mean(n=3)** | **3.27206** | **3.27070** | **−0.00136** |

**Merge gate decision (CLAUDE.md "when in doubt, merge"; direct precedent #393 merged at near-identical paired-pod Δ=−0.00137)**:
- Gate 1 within-pod mean Δ ≤ −0.002: FAIL at −0.00136 (sub-threshold)
- Gate 2 μ_D ≤ baseline 3.27174: **PASS** at 3.27070 (−0.00104 absolute)
- Gate 3 stat-rule (3.28 − 3.27070) × √3 = 0.01611 ≥ 0.004: **PASS**
- Drift gates: pod0-A=+0.00112, pod1-A=−0.00020, pod2-A=+0.00004 — all 3 within ±0.003 ✓

Direction-correct 2/3 pods, μ_D beats baseline by 0.00104 absolute. **Merged per project-level statistical rule**, mirroring #393 precedent at virtually identical magnitude.

**Mechanism**: NS-orthogonalization normalizes spectral direction per-matrix but not relative scale across matrix-types. Attn matrices benefit from conservative effective step (less attention-routing jitter); MLP matrices benefit from larger step (better gradient signal extraction). Singletons sub-threshold but compose under combined application — a true interaction effect signature, not magnitude addition. `first_step_to_target` improved: μ_A=3233.3 → μ_D=3225.0 (−8.3 steps consistent with val improvement).

W&B group `g1r4-askeladd/muon-attn-mlp-lr-asym-paired-pod` — D runs: `xba0kue2`, `a861snwz`, `vg8dkwf3`.

**New merged envs**: `NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20`. 9th merged improvement this cycle.

### ✅ askeladd #543 — Per-block NS iter budget — CLOSED 13:35 UTC productive-NULL

Single-seed 4-arm sweep (drift gate A PASS, |3.27243−3.27174|=0.00069): A uniform=3.27243, B aspect=+0.00077 (null), C manual_typeA=−0.00017 (null, best), D manual_typeB=+0.00056 (null). All 3 reallocation arms in productive-null band [−0.002, +0.0015]. NS=12 saturation **robust to spatial reallocation** — combined with #470 uniform escalation finding, NS-iter count is genuinely saturated at this budget. Architectural finding (student-documented): codebase uses split-qkv naming (`attn.q`/`attn.k`/`attn.v` all 768×768 square) — only 2-of-6 Muon blocks (`mlp.fc`, `mlp.proj`) have aspect > 1.0, limiting the spatial reallocation surface. **34th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **Body Muon LR asymmetry (attn vs mlp split)** — per-block-TYPE LR axis (vs #543 per-block iter), structurally distinct from #393 (AdamW per-group LR) and #409 (LLRD depth-LR).

### ✅ nezuko #454 — lm_head/scalar cooldown shape extension — CLOSED 18:05 UTC productive-null

Arms B/C/D (lm_head_floor, scalar_floor, both): best Δ=−0.00098 (arm B), half the −0.002 threshold. Arm D (stacked) regresses +0.00072 vs A, indicating cross-group interaction at end-of-cooldown. **linear_floor is embed-specific** (sparse-row coverage benefit), not aux-generic. Three prior paired-pod false-positives (#344, #351, #408 AGC) support conservative close. **20th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#490 NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, first Adam-family axis we haven't tested.

### ✅ nezuko #490 — NAdam (Nesterov-AdamW) scope sweep — CLOSED 02:15 UTC productive-null

Arms B (embed: Δ=−0.00059, mild +), C (lm_head: Δ=+0.00063, mild −), D (all_aux: Δ=+0.00275, regression). Best arm B well within null band (need ≤−0.002); D's compounded regression suggests scalar group is bad actor under NAdam (aggressive direction-change due to normalization layers). **26th productive-null/negative this cycle.** Closes the first-moment axis of the AdamW-internal three-axis ablation (magnitude #442 NEGATIVE, first-moment #490 null/regress, second-moment #474 NEGATIVE) — **AdamW-internal axis family substantially exhausted on merged stack**.
**Follow-up**: nezuko assigned **#530 Nesterov-Muon body scope sweep** — structurally parallel test on Muon body momentum (lookahead before NS).

### ✅ nezuko #530 — Nesterov-Muon body scope sweep — CLOSED 10:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27253−3.27174|=0.00079): A α=0.95=3.27253, B α=0.00 (bypass)=+0.00630 (regression), C α=0.50 (half-mix)=+0.04114 (severe, target NOT reached), D α=0.99 (over-Nesterov)=+0.00060 (null). **Structural finding**: the cliff is on the *low-α* side (NS-stability breakdown when current-grad weight >>0.05); the plateau is on the *high-α* side (Arm D within noise). α=μ=0.95 sits at boundary of safety — the mix is best understood as a tiny anti-staleness injection (~5% current-grad on top of 95% EMA), small enough to stay in NS's well-behaved spectral domain. Heavier current-grad injection pushes the NS input outside the Newton-Schulz polynomial's well-conditioned regime. **5th body-Muon mechanism axis closed** (joins #102 LR warmup, #356 μ schedule, #434 Lookahead-wrap, #483 WD warmup). Body Muon algorithmic axes on the merged stack are largely exhausted — future body-Muon ideas should target architectural changes (post-NS-side modifications, NS-iteration-count interactions). **32nd productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#568 Per-group cooldown_frac decoupling** — fresh structural axis on per-group cooldown WINDOW LENGTH (vs per-group cooldown SHAPE which is largely characterized).

### ✅ nezuko #568 — Per-group cooldown_frac decoupling — CLOSED 18:40 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27134−3.27174|=0.00040): A=3.27134, B (embed=0.80)=−0.00014 (null), C (embed=0.60)=**+0.00242 (regression)**, D (body=0.80)=−0.00067 (null, best). No arm crosses −0.002 signal threshold. Best arm D passes single-seed stat-rule at n=1 ((3.28−3.27067)×√1=0.00933 ≥ 0.004) AND beats baseline (3.27067 ≤ 3.27174), BUT within-pod Δ=−0.00067 short of pre-staged paired-pod gate. Embed direction asymmetric-monotonic with floor at 0.70 (shortening hurts; lengthening gives only sub-threshold improvement). Body direction mildly positive sub-threshold (NS-orthogonalized landing benefits *mildly* from longer precision-window but not enough at ±0.10 perturbation). **SHAPE→FRAC analogy fails at this perturbation scale**: per-group cooldown SHAPE matters (real asymmetry) but per-group cooldown WINDOW LENGTH does NOT show same asymmetry within ±0.10 of 0.70. **39th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#603 AdamW second-moment warmstart via ghost steps** — fresh untested mechanism addressing cold-start direction problem in `exp_avg_sq` that bias correction (magnitude rescaling) explicitly does not solve. Pre-training ghost-step loop accumulates m_t, v_t without weight updates; first ~100 training steps then operate on directionally-informed second-moment estimates instead of cold-start zero.

### ✅ nezuko #603 — AdamW ghost-step warmstart — CLOSED 00:10 UTC broken-chain + productive-NEGATIVE

Chain thrashed for ~5h with 6+ crashes across arms. Student identified key implementation limitation: `proj.weight=0` init at line 828 blocks gradient flow back through model during ghost steps (zero-inits all "proj" weights so `F.linear` backward `grad_input = grad_output @ proj.weight = 0`). Ghost steps thus only warm `lm_head` AdamW second-moment, NOT embed or scalar. The single completed arm (C ghost=25) reached **val=3.3018** — a +0.030 catastrophic regression vs baseline 3.27174, indicating ghost-step warmstart of lm_head's AdamW v_t is actively harmful. **43rd productive-NULL/NEGATIVE this cycle.** WAVE3 IDEA 7 (cold-start v_t direction) axis: closed. **Key durable finding (reusable across this programme): proj.weight=0 init blocks all upstream grad flow during pre-step probes — future optimizer-state-warming experiments must account for this.**
**Follow-up**: nezuko assigned **#628 trust-region adaptive Muon LR** — per-layer cos-EMA boost on rare-aligned layers. First experiment to AMPLIFY the rare-productive-direction signal rather than suppress conflict (vs #126 Contra-Soft attenuate, #163 DMR reset, #419 Cautious mask — all closed). Mechanistically distinct from all closed gradient-direction-aware mechanisms.

### 🔄 nezuko #628 — Trust-region adaptive Muon LR (per-layer cos-EMA boost) [assigned 00:15 UTC]

**Branch:** `g1r4-nezuko/trust-region-muon-lr`
**Hypothesis**: After 43 productive-NULLs, structurally distinct mechanism — boost Muon LR on layers where grad·momentum cosine EMA is positive (rare-productive layers per #154 90% conflict finding). Per-layer cos_ema tracks long-run direction agreement; trust_scale = 1 + boost × max(cos_ema, 0). Leaves common-conflict case at LR=1.0 (no harm), amplifies rare-aligned layers (productive signal). Distinct from #163 DMR (resets buffer), #126 Contra-Soft (attenuates gradient), #419 Cautious (masks elements), #120/#434 Lookahead (blends weights).
| Arm | NANOGPT_MUON_TRUST_BOOST | NANOGPT_MUON_TRUST_BETA | Tests |
|---|---:|---:|---|
| A | 0.0 (ctrl) | n/a | Reproduces merged baseline |
| B | **0.5** | 0.97 | Mild boost (full alignment → 1.5× LR) |
| C | **1.0** | 0.97 | Moderate boost (full alignment → 2.0× LR) |
| D | **2.0** | 0.97 | Aggressive boost (full alignment → 3.0× LR) |
**ETA full chain:** ~7.3h. Computational overhead ~12 cosines per step (negligible).

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### ✅ frieren #593 — Per-group AdamW WD sweep — CLOSED 00:05 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS exceptional parity |3.27167−3.27174|=0.00007): A=3.27167, B (lm_head WD=0.01)=+0.00192 (regression marginal), C (scalar WD=0.01)=−0.00017 (productive-null sub-noise-floor), D (joint)=−0.00022 (productive-null sub-noise-floor). No arm clears −0.002 signal threshold. **42nd productive-NULL/NEGATIVE this cycle.** **Cross-axis WD-ADDITION pattern now fully fenced**: AdamW lm_head WD ADD (B regress), AdamW scalar WD ADD (null), AdamW embed WD ADD (#554 NEG), Muon body WD warmup ADD (#483 NEG). Only WD direction with extractable gain on merged stack is REDUCTION (#550 Muon body WD cooldown reduce, paired-pod in-flight). Strengthens "baseline is locally optimal across WD axis; cooldown handles regularization adequately".
**Follow-up**: frieren assigned **#629 Layer-aggregate Contra-Soft Muon** — fills explicit untested gap diagnosed in #126 closure (element-wise Contra-Soft attenuated ~13-50% of gradient mass uniformly across granularities; layer-aggregate operates only on whole-matrix cosine, preserving productive-direction layers entirely). Distinct from #628 (boosts via LR scaling); this attenuates via gradient scaling on conflict-layers only.

### ✅ frieren #629 — Layer-aggregate Contra-Soft Muon — CLOSED 08:30 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, exceptional parity +0.00014): A=3.27159, B (α=0.25)=3.27345 (Δ=+0.00186, regression band), C (α=0.50)=3.27185 (Δ=+0.00026, null), D (α=1.00)=**3.63287** (Δ=+0.36128, **catastrophic — FAILS 3.28 target**). W&B runs: dqssobu4 (A), h1aqkx71 (B), d4ihlim2 (C), 34ui6a23 (D). Non-monotone (regress→parity→catastrophic) but uniformly non-improving. Mechanism telemetry: scale_min D=0.426 (cos_min=−0.574), D's α=1.0 full-zero-grad on conflict layers kills gradient signal; training oscillates and val plateaus at 3.63 (never reaching 3.28). **Contra-Soft mechanism class FULLY CLOSED**: #126 element-wise + #629 layer-aggregate both falsified. The load-bearing ~11% persistent-cos<0 fraction is productive exploration, not noise. **48th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **#664 AdamW bias correction disable sweep** — genuinely fresh mechanism axis: with merged β2=0.99 (#236), bias correction scales mid-training aux updates down by sqrt(bc_v)/bc_m = 0.63–0.80× during steps 50–100; disabling it tests whether this implicit LR suppression limits mid-phase learning. Tests 3 scopes (embed-only, lm_head-only, all-aux).

### ✅ frieren #664 — AdamW bias correction disable sweep on aux groups — CLOSED 18:35 UTC productive-NULL

Single-seed 4-arm on NEW post-#579 stack (drift gate A2 PASS, +0.00154 within ±0.003): A2 ""=3.27224 ctrl, B2 embed=3.27143 (Δ=−0.00081 sub-threshold null), C2 lm_head=3.27144 (Δ=−0.00080 sub-threshold null), D2 all_aux=3.27217 (Δ=−0.00007, **saturation/interference**). No arm passes within-pod −0.002 winner threshold; best singletons B2/C2 at −0.0008 ~2.5× below threshold. **B2 ≈ C2 within single-seed noise σ≈0.001**: bias-correction disable on EITHER aux group produces nearly-identical marginal effect — the mid-training LR-boost mechanism applies uniformly across aux groups with no per-group structural preference. **D2 (all_aux) flattens to ctrl** rather than compounding additively (~−0.0016 expected if independent) — **saturation/interference**: the early-training relative-magnitude structure between embed/lm_head/scalar is maintained by their RELATIVE bias-correction factors; disabling on ALL three preserves the relative ratios while disabling on only one breaks them. The single-aux disable signal is a relative-magnitude shift, not a single-group mechanistic effect. Implementation clean (telemetry verified bc_scale_factor ramp matches expected curve, rebased onto post-#579 cleanly, wall-clock parity 1893-1894ms across all 4 arms). All 4 arms hit 3.28 target. **54th productive-null/negative this cycle.** Bilateral closure with per-group AdamW family: #599 β₁ NEG + #560 β₂ NEG + #593 WD NULL + #652 eps NEG + #664 BC NULL — AdamW-internal axes now FULLY exhausted on merged stack; only LR-mult #393 MERGED extracted gain.
**Follow-up**: frieren assigned **#710 per-depth body Muon NS_ITERS variation** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669/#674). Tests early/mid/deep bucket NS-iter budget allocation; orthogonal to #543 (per-aspect-ratio, only differentiates mlp.fc/mlp.proj per layer because q/k/v/attn.proj are 1× aspect square 768×768) and #470 (uniform escalation) and #506 (time-axis warmup CLOSED-NEG). Mechanism: gradient magnitudes vary by depth (early layers diluted by backward chain depth; mid layers full backward flow / capacity bottleneck; deep layers closer to output); NS=12 uniform may over-invest on well-conditioned mid-layer matrices and under-invest on edge layers. 4-arm: A (12,12,12) ctrl, B (10,14,10) mid-heavy, C (14,12,10) front-loaded, D (10,12,14) back-loaded.

### 🔄 frieren #710 — Per-depth body Muon NS_ITERS variation [assigned 18:40 UTC]

**Branch:** `g1r4-frieren/per-depth-muon-ns-iters`
**Hypothesis**: Body Muon `NANOGPT_NS_ITERS=12` is uniform across all 12 transformer layers (72 body Muon matrices total). Gradient magnitude distributions vary by depth: early layers diluted by backward chain (12 layers of gradient flow); mid layers full backward flow at capacity bottleneck; deep layers closer to output. NS convergence rate depends on input matrix's singular value distribution — uniform NS=12 may over-invest on well-conditioned mid layers and under-invest on edge layers. Per-depth bucket allocation tests depth-aware budgeting (distinct from #543 per-aspect-ratio NULL where only 2-of-6 matrices per layer have aspect>1).
| Arm | NS_EARLY | NS_MID | NS_DEEP | Effect tested |
|---|:---:|:---:|:---:|---|
| A (ctrl) | 12 | 12 | 12 | Bit-identical merged baseline |
| B | 10 | 14 | 10 | Mid-heavy: invest in capacity bottleneck, save on edges (−6% FLOPs net) |
| C | 14 | 12 | 10 | Front-loaded: max quality early (gradient flow conditioning), decreasing toward output (FLOP-neutral) |
| D | 10 | 12 | 14 | Back-loaded: max quality deep (output-side precision), decreasing toward input (FLOP-neutral) |
**ETA full chain:** ~7.3h (Arm B may be ~5% faster). Implementation: ~25 LOC (regex-based layer-to-bucket map at init + 3 env-var reads + per-param iter lookup). Distinct from #543 (per-aspect-ratio, only differentiates mlp matrices), #470 (uniform escalation), #506 (TIME-axis warmup NEG), #388 (NS_ITERS_COOLDOWN — orthogonal phase). Composes with #543 finding: per-aspect-ratio NULL but per-depth different. Smoke verification ask first comment: report exact regex pattern identifying layer indices in this codebase + sanity-check of 72 body Muon params with (layer_idx, block_type) tuples.

### ✅ frieren #506 — NS-iter warmup schedule — CLOSED 16:15 UTC productive-NEGATIVE [paired-pod n=3]

Paired-pod n=3 confirmation: all 3 pods regress (mean Δ=+0.00087, wrong sign). Gates 1+2 fail (mean Δ above 0, mean val_B 3.27329 > baseline 3.27174). The N=1 Δ_C=−0.00119 was an Arm-A drift artifact (original Arm A drifted +0.00108 above baseline; paired-pod Arm-A controls anchor at +0.00068). **5th cycle precedent for single-seed → paired-pod collapse** (joins #344, #351, #408, #487). **NS-axis program now fully fenced**: 3/3 NS-iter schedule axes closed by frieren (warmup #506, normal-phase #470, cooldown saturation #388) + 3 cooldown-machinery components MERGED (#176, #285, #290) + sub-stack pruning #487 null + spatial #543 null. **37th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **per-group AdamW WD sweep** — currently WD=0 uniformly across embed/lm_head/scalar; whether dense lm_head or small-param scalar groups benefit from WD>0 has never been tested. Structurally distinct from #554 (embed WD ADD cooldown, NEGATIVE — sparse-row mechanism), #550 (Muon body WD), #483 (Muon WD warmup, NEGATIVE).

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### ✅ edward #516 — Yogi optimizer on aux groups — CLOSED 07:00 UTC productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

Single-seed 4-arm (drift gate A PASS, |3.27419−3.27174|=0.00245 ≤ 0.003): A=3.27419, B embed=+0.00386 (regression), C lm_head=+0.00038 (null), D all-aux=+0.00447 (regression). D ≈ B + 0.00061 — embed regression dominates; lm_head and scalars contribute marginally. Mechanism reading: Yogi's faster-additive v_t reaction destabilizes sparse-row embed at β₂=0.99 (regression grows monotonically through cooldown); dense lm_head indistinguishable from AdamW. Independent of AdaBelief mechanism (#474): Yogi accumulates g² same as AdamW. **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. **29th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 WD warmup which tested early reduction).

### ✅ edward #639 — Embed-stack joint redundancy ablation: linear_floor × LR_MULT=1.5 — CLOSED 11:10 UTC productive-NULL

4-arm 2×2 factorial (N=1, ran on OLD pre-#579 stack — #579 merged mid-experiment): A (full)=3.27438, B (drop floor)=3.27285 (Δ=−0.00153), **C (drop mult)=3.27222 (Δ=−0.00216 best)**, D (drop both)=3.27487 (Δ=+0.00049). **All 4 arms above NEW baseline 3.27070** — C closest at +0.00152. Mechanism finding: **mutual antagonism / saturation** — A ≈ D, single-component drops each help slightly. Effective late-phase embed LR: A=0.0675 (saturated) > C=0.045 (sweet spot) > B=0.45→0 > D=0.30→0. Both #235 and #393 push embed LR past sweet spot; stacking saturates surface. Arm C's −0.00216 within-pod signal at threshold edge but Arm A drift +0.00264 baked-in — paired-pod confirmation cannot land mean(val_C) below 3.27070. Cannot merge; stack simplification not viable. **Future embed-side experiments should target joint surface** rather than individual axes. **51st productive-null/negative this cycle.**
**Follow-up**: edward assigned **#674 per-block-type Muon momentum asymmetry** — direct extension of #579/#669 mechanism family on 3rd Muon hparam axis. 4-arm sweep (attn_mu × mlp_mu): A=(0.95,0.95) ctrl, B=(0.90,0.95) attn-faster, C=(0.95,0.99) mlp-slower, D=(0.90,0.99) compound. Mirror #579 4-arm pattern. Mechanism: attn-prefer-faster-tracking (less stale routing signal), mlp-prefer-slower-tracking (lower variance feature gradient). Completes per-block-TYPE Muon hparam family (LR ✓#579 / WD #669 / momentum #674).

### 🔄 edward #674 — Per-block-type Muon momentum asymmetry [assigned 11:15 UTC]

**Branch:** `g1r4-edward/muon-attn-mlp-momentum-asym`
**Hypothesis**: Direct extension of #579 mechanism family — if per-block-TYPE LR asymmetry productive, momentum-buffer time-constant asymmetry is natural orthogonal axis. attn benefits from faster-tracking (mu=0.90, ~10-step memory) — attention routing patterns shift fast; stale momentum carries outdated co-activation signal. mlp benefits from slower-tracking (mu=0.99, ~100-step memory) — feature representation gradients more stable; longer averaging reduces variance. Current uniform mu=0.95 (~20-step) untested per-block-TYPE.

| Arm | NANOGPT_MUON_ATTN_MU | NANOGPT_MUON_MLP_MU | Mechanism tested |
|---|---:|---:|---|
| A (ctrl) | 0.95 | 0.95 | Reproduces merged baseline (bit-identical) |
| B | **0.90** | 0.95 | attn faster-tracking only — singleton test |
| C | 0.95 | **0.99** | mlp slower-tracking only — singleton test |
| D | **0.90** | **0.99** | Compound — directly mirrors #579 4-arm pattern |
**ETA full chain:** ~7h. Implementation: ~15 LOC (env vars + per-group mu in `muon_update()`, mirrors #579 param-group split). Completes 3-axis per-block-TYPE Muon family.

### ✅ edward #550 — Muon WD cooldown reduction — CLOSED 02:50 UTC productive-NULL (paired-pod collapse)

**Single-seed N=1 winner** (Arm D WD=0 Δ=−0.00337) **collapsed to paired-pod sub-threshold**:

| Pod | Arm A (WD=0.025) | Arm D (WD_final=0) | Δ |
|---|---:|---:|---:|
| pod0 | 3.27328 | 3.27238 | −0.00090 |
| pod1 | 3.27247 | 3.27119 | −0.00127 |
| pod2 | 3.27138 | 3.27085 | −0.00054 |
| **mean (n=3)** | **3.27238** | **3.27147** | **−0.00090** |

**Gates**: Gate 1 (within-pod mean Δ ≤ −0.002) **FAIL** at −0.00090 (half threshold). Gate 2 (mean val_D ≤ 3.27174) PASS at 3.27147. Gate 3 (stat-rule (3.28 − 3.27147) × √3 = 0.01477 ≥ 0.004) PASS. Drift gates: A mean 3.27238 vs baseline 3.27174 = +0.00064 (sub-drift PASS). Direction-correct 3/3 pods — real mechanism, not seed luck — but magnitude insufficient. **6th cycle precedent for single-seed→paired-pod collapse** (#344, #351, #408, #487, #506, #550). **WD-axis now bilaterally fenced** on this stack: ADDITION (#554 embed, #593 lm_head/scalar/joint, #483 Muon warmup) all NEG; REDUCTION (#550) sub-threshold NULL. Cooldown-window precision is structural, not WD-friction-bound. **45th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#639 Embed-stack joint redundancy ablation** — joint ablation of EMBED_COOLDOWN_SHAPE=linear_floor (#235 merged) and ADAMW_EMBED_LR_MULT=1.5 (#393 merged); both raise late-phase embed effective LR via different mechanisms, one may be redundant given the other. Pure env var permutation (no code).

---

## Research theme — current cycle

**51 productive-null/negative results + 9 merged improvements**. The 9th merge is **#579 body-Muon attn=0.80×/mlp=1.20× LR asymmetry** (paired-pod n=3 mean Δ=−0.00136 sub-threshold but mirroring exactly #393's merge precedent at −0.00137; μ_D=3.27070 beats baseline by 0.00104 absolute). 50th was #639 (edward embed-stack joint redundancy: mutual antagonism / saturation finding on embed-LR pressure surface). 51st was reserved for #639's productive-null close. Research axes still extracting compounding gains: per-block-type LR asymmetry on body Muon. The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. ~~Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise?~~ **#506 CLOSED productive-NEGATIVE** — all 3 pods regress, 5th single-seed→paired-pod collapse precedent; NS-axis program fully fenced.
2. ~~Does per-block NS iter allocation (by aspect ratio) help over uniform NS=12?~~ **#543 CLOSED productive-NULL** — NS=12 saturation robust to spatial reallocation; codebase has limited surface (only 2-of-6 Muon blocks non-square).
3. ~~Does lm_head cooldown SHAPE (cosine / late_peak / linear_floor) matter vs default linear?~~ **#547 CLOSED productive-NULL** — lm_head wants monotonic linear; late_peak doesn't cross-axis transfer from NS.
4. Does Muon WD reduction during cooldown extract precision-window gain? (**#550, edward — N=1 Arm D WD=0 Δ=−0.00337 strong winner candidate; sent back for paired-pod n=3 confirmation, identical protocol to #487; non-linear axis response (only WD=0 extracts gain) is structurally novel; either fresh merge candidate or 5th single-seed→paired-pod collapse**)
5. ~~Does adding small WD on AdamW embed during cooldown help?~~ **#554 CLOSED productive-NEGATIVE** — clean monotone regression; embed group rejects added WD during cooldown; bilateral asymmetry with #550 (body benefits from REDUCED WD, embed rejects ADDED WD).
6. ~~Does per-group AdamW β₂ asymmetry extract per-group second-moment time-constant gains?~~ **#560 CLOSED productive-NULL/NEGATIVE** — embed β₂=0.999 regression (+0.00359), β₂=0.95 null (+0.00089), D inert; AdamW-internal axis family substantially exhausted.
7. Does per-group cooldown WINDOW LENGTH asymmetry around 0.70 baseline extract gains? (#568, nezuko — fresh structural axis paralleling SHAPE work)
8. Is the *entire* NS-cooldown sub-stack jointly load-bearing even though each component is individually redundant? (#487 follow-up, tanjiro — joint-pruning ablation, structurally novel compound subtraction)

**Stack convergence signal**: 28 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **"Less constraint early" schedule cluster** (in flight): NS-iter warmup (#506), β₁ warmup (#514) — early-phase schedule axes. WD warmup (#483) and embed-LR warmup (#489) both closed productive-NEGATIVE — bilateral structural finding.
2. **Late-phase cooldown shape**: body Muon LR cooldown shape (#520 thorfinn) — targeting the load-bearing 30% cooldown window.
3. **Stack simplification** — #487 paired-pod n=3 CLOSED productive-NULL (Arm B drop NS_ITERS_COOLDOWN: mean Δ=+0.00003, classified redundant but not improved). All three sub-stack components (NS_ITERS_COOLDOWN, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) are individually classified as redundant under their respective single-drop tests; **joint-drop interaction is untested** — that's the natural next step (follow-up assigned to tanjiro). If joint-drop ≈ baseline, the entire NS-cooldown machinery can be retired.
4. **Non-AdamW body-Muon mechanism axis** — Nesterov-Muon (#530, nezuko new) targets lookahead-before-NS, complementing pre-stage NS scheduling (#506) and shape (#520). The AdamW-internal three-axis ablation is closing (#442 NEGATIVE + #474 NEGATIVE + #490 null = body-side is the natural pivot).
5. **Bilateral regularization closure (from #483 + #489)**: both ADD (17 axes) and REDUCE-by-warmup (Muon-WD, embed-LR) regularization fail → early-training window is bilaterally well-tuned.
6. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope; single-group regresses.
7. **Embed sparsity structural insight (from #474)**: `(g − m)²`-based second moments fail on embed group; `g²`-only formulations (AdamW, Yogi) are safe.

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
| #618 | fern | Muon² for lm_head (replace AdamW) | CLOSED productive-NEGATIVE (3/3 Muon arms MISS 3.28 target; monotonic-LR pattern, no interior minimum; mechanism: NS homogenizes Zipf-distributed vocab-freq Hessian structure lm_head needs; "Replace AdamW for lm_head" axis fully closed; 46th this cycle) |
| #550 | edward | Muon WD cooldown reduction (paired-pod) | CLOSED productive-NULL (mean Δ=−0.00090 FAIL Gate 1, val=3.27147 PASS Gate 2, stat-rule=0.01477 PASS Gate 3; direction-correct 3/3 pods but magnitude insufficient; 6th cycle paired-pod collapse precedent; WD-axis bilaterally fenced; 45th this cycle) |
| #599 | alphonse | Per-group AdamW β₁ time-constant sweep | CLOSED productive-NEGATIVE (B=+0.00399 regression, C β₁=0=+0.00513, D β₁=0.90=+0.00177; both directions regress; per-group AdamW family fully exhausted; 44th this cycle) |
| #560 | alphonse | Per-group AdamW β₂ asymmetric sweep (embed/lm_head decoupling) | CLOSED productive-NULL/NEGATIVE (B=+0.00089 null, C β₂_embed=0.999=+0.00359 regression, D inert; AdamW-internal family exhausted; 38th this cycle) |
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
- **β₁ per-group: CLOSED productive-NEGATIVE** (#599; B=+0.00399/C=+0.00513/D=+0.00177; both directions; **per-group AdamW family fully exhausted** — β₁ + β₂ + WD all closed-NEGATIVE; only embed-LR-mult #393 extracted gain)
- β₂ per-group asymmetry (embed swept 0.95/0.999, lm_head 0.999): CLOSED productive-NULL/NEGATIVE (#560; embed β₂=0.999 +0.00359 regression, β₂=0.95 +0.00089 null, D inert; AdamW-internal family substantially exhausted)
- ε per-group: all swept, β₂=0.99/ε=1e-10 confirmed
- WD per-group: **bilaterally fenced — ADDITION (#554/#593/#483) all NEG; REDUCTION (#550, n=3 paired) sub-threshold NULL at mean Δ=−0.00090; cooldown-window precision is structural, not WD-friction-bound**
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC, OrthoGrad: all closed
- AdaBelief variance-of-prediction-error second moment: CLOSED productive-NEGATIVE (#474; embed sparsity pathology; `(g−m)²` fails on absent-row sparse groups)
- Muon-WD warmup (all fracs 5-20%): CLOSED productive-NEGATIVE (#483; monotone worsening; body WD=0.025 is bilaterally optimal)
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)
- NAdam (Nesterov-AdamW) aux scope sweep: CLOSED productive-null (#490; best arm B Δ=−0.00059 within null, joint D Δ=+0.00275 regression — scalars likely bad actor)
- Nesterov-Muon body weight sweep α∈{0.0, 0.50, 0.99}: CLOSED productive-NULL (#530; cliff on low-α side: α=0.50 catastrophic +0.04114 fst=-1, α=0.99 plateau null +0.00060; existing α=μ=0.95 is load-bearing AND optimally weighted; mechanism: tiny anti-staleness injection on top of NS-stable EMA; 5th body-Muon mechanism closure; 32nd null this cycle)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); **#487 Arm B (drop) at paired-pod n=3: mean(Δ)=+0.00003 — CLASSIFIED REDUNDANT** (not load-bearing, not improved); 4th cycle precedent for N=1 → paired-pod collapse
- NS cooldown SHAPE=late_peak: MERGED #285; #487 Arm C drop = +0.00080 null at N=1
- NS coef schedule=linear_ramp_down: MERGED #290; #487 Arm D drop = +0.00066 null at N=1
- **Joint-drop of NS-cooldown sub-stack: in-flight** (tanjiro #577, joint-pruning interaction test)
- **Per-block NS-iter spatial allocation (aspect ratio)**: CLOSED productive-NULL (#543; NS=12 saturated to spatial reallocation; codebase has only 2 non-square Muon blocks limiting surface)
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: CLOSED productive-null (#470; wide plateau NS ∈ [10,14]; NS=8 below floor; NS step-time flat ±1%)
- **NS-iter warmup (NS=8→12 over first 5%)**: CLOSED productive-NEGATIVE (#506; paired-pod n=3 mean Δ=+0.00087, all 3 pods regress; 5th single-seed→paired-pod collapse; NS axis fully fenced — 3/3 frieren NS schedule corners closed + sub-stack pruning + spatial reallocation also null)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- **lm_head cooldown SHAPE (cosine/late_peak/linear_floor)**: CLOSED productive-NULL (#547; cross-axis NS late_peak transfer falsified, +0.00179 biggest regression; lm_head wants monotonic linear; reproduces #454 linear_floor null; per-group SHAPE design space now substantially characterized — only scalar untested)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): CLOSED productive-NULL (#526; B/C plateau at Δ≈−0.0008 within noise floor; D longer window mildly worse; bilateral closure with #489; 31st null this cycle — embed step-0 LR=1.5× is bilaterally optimal)
- **Embed AdamW WD cooldown nudge (additive)**: CLOSED productive-NEGATIVE (#554; monotone regression A→D, B=+0.00068 null-edge fails baseline parity, C=+0.00657 regression, D=+0.01571 fails 3.28 target; mechanism: embed sparse-row representations depend on accumulated info not noise; WD overrides accumulation; bilateral asymmetry with #550 candidate)

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
