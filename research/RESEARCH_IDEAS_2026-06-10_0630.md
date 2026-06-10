# RESEARCH IDEAS — 2026-06-10 06:30 UTC

**Context of generation.** All in-flight experiments (H-FN, H-FO, H-FQ, H-FR, H-FS, H-FU, H-FW) are scanning small perturbations of the β₂ pulse manifold (amplitude, timing, grouping, combined). The n=2 step-2850 threshold (≤ 3.277172) is sharp enough that single-seed "strong signals" at 2890 (3.276–3.277) are almost certainly FALSIFIED when evaluated at the stricter step. Every major scalar around the β₂ pulse has been swept (amplitude 0.95–0.999, timing 620–1020, trajectory 4-cell ablation, group assignment embed/lm_head/scalars/combined, β₁ joint pulse, AMSGrad, EN γ anneal, NS5 whitening, SWA, adaptive CD). The local neighborhood is exhausted.

**Research mode for this wave: TIER SHIFT.** The new hypotheses below operate on different levels of abstraction: (1) post-training weight readout (RI variants), (2) lm_head optimizer second-moment geometry (Sophia-H, Adafactor factored), (3) sharpness-aware perturbation (SAM), (4) optimizer-state alignment (LARS per-group LR scaling), (5) cooldown weight-decay modulation, (6) NS5 polynomial coefficients, (7) two-stage RI, and (8) Heun-interpolated RI. Each targets a distinct failure mode.

**Rank-1 stack (PR #2405, H-EJ, step=2850, n=4 mean=3.277780):**
NC (per-row × per-col L2 pre-NS5) × Sinkhorn Arbor × EMA-Nesterov (EN, γ=0.99) × RI (γ=−0.075, capture_step=2375) × AdamW eps=1e-12 × β₂ pulse (0.95→0.995 @ step 820) × Muon momentum schedule (warmup=300, cooldown=100, mu_min=0.85, mu_max=0.95) × Aurora K=3, β=0.25.

**Decision gates (all hypotheses):**
- n=2 mean @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 mean @ step 2850 ≤ 3.278000 → INFORMATIVE (run still useful for understanding)
- n=2 mean @ step 2850 > 3.278000 → FALSIFIED (close)
- Single-seed n=1 abort gate: val/loss @ step 2890 > 3.279000 after any arm → ABORT that arm immediately

**Do NOT duplicate:**
- β₂ trajectory shape (4-cell ablation CLOSED), β₁ pulse direction (CLOSED), AMSGrad (CATASTROPHIC), EN γ anneal (CLOSED), NS5 input whitening / QR blend (CLOSED), Muon SWA (CLOSED), Lookahead on any optimizer (CATASTROPHIC), ARBOR_CLAMP_K, SOAP MLP+V, v-reset/warm-restart class, embed-only LR ±50%, all H-DX through H-FO axes, all whole-optimizer β₂ amplitude/timing/group work already assigned.

---

## Hypothesis H-FY — TWO-STAGE REFERENCE INTERPOLATION (double-capture RI)

### Mechanism

The current RI mechanism captures weights at a single anchor step (capture_step=2375) and interpolates the final weights toward that anchor with γ=−0.075 (negative = interpolate BEYOND the anchor, in the "training direction"). This is a single-chord extrapolation. The intuition is that the late training trajectory tends to overshoot the loss minimum due to optimizer momentum, and RI corrects the overshoot.

A generalization is a TWO-STAGE RI: capture two anchors at different steps (e.g., step_1=2200, step_2=2375) and apply two successive interpolation steps, each with a small γ. This is equivalent to computing a quadratic extrapolation in weight space rather than a linear one: the two-point direction estimate gives information about whether the trajectory is accelerating or decelerating toward the minimum, and the Heun-style correction can better land at the bottom of the loss bowl.

Mathematically: w_final = w_T + γ₁(w_T − w_a1) + γ₂(w_T − w_a2), which is a linear combination of two RI steps and collapses to standard RI when γ₁=0. Setting γ₁ and γ₂ to different signs tests whether the first or second anchor contributes more signal.

This is directly analogous to Heun's method (Runge-Kutta order 2) applied to the weight-space trajectory: use both the departure slope (from step_1→T) and the arrival slope (from step_2→T) to estimate where the minimum lies.

**Source:** Analogous to SWA + SWA-extrapolation ("Stochastic Weight Averaging as Optimal Relaxation," Izmailov et al., 2018) and the LAWA (latest weight averaging) technique (Kaddour et al., 2022, https://arxiv.org/abs/2209.14981). The rank-1 RI mechanism is a direct descendant of PR #309 / #1532 in the KellerJordan lineage.

### Hypothesis

Adding a second early-capture RI interpolation step (capture at step 2200, small γ₁=−0.025) BEFORE the primary RI step (capture at step 2375, γ=−0.075) gives a better quadratic approximation to the loss bowl and improves n=4 mean at step 2850 by ~0.0004–0.0010 below rank-1.

### Implementation sketch

```python
# In the post-training readout section, AFTER the run completes:
# Existing: w_out = w_T + gamma * (w_T - w_anchor2375)
# New: w_step1 = w_T + gamma1 * (w_T - w_anchor2200)  # light first stage
#       w_out  = w_step1 + gamma2 * (w_step1 - w_anchor2375)  # main second stage

# Implementation: add --ri_gamma_1 (default 0.0) and --ri_capture_step_1 (default -1)
# If ri_capture_step_1 > 0, save an additional checkpoint at that step
# At readout: apply two-pass interpolation in sequence
# All existing RI logic (capture_step=2375, gamma=−0.075) remains unchanged as the second pass
```

**Arms:**
- Arm A: capture_step_1=2200, γ₁=−0.025 (light pre-stage; main RI unchanged at capture_step=2375, γ=−0.075)
- Arm B: capture_step_1=2100, γ₁=−0.050 (earlier/stronger pre-stage; same main RI)
- Screen: both arms at n=1 (2 seeds), pick best for n=2 confirmation

**Key implementation notes:**
- The ADDITIONAL checkpoint at step 2200 or 2100 costs one extra save. Verify `--save_checkpoint_at_step` flag exists or add it. If checkpoint storage is an issue, save the state dict to a separate file.
- Apply the first RI pass on a copy of the weights, then the second pass on the result.
- The two passes are NOT independent: the second pass uses the output of the first as its "current weights." This means γ₂ is applied to a partially-interpolated weight, not to the raw final weights.
- Guard: if γ₁ and γ₂ are both negative (both extrapolate in training direction), there is a risk of double-overshoot. Start with |γ₁| ≤ 0.03.

**Decision gate:**
- n=1 @ 2890 ≤ 3.276000 for any arm → proceed to n=2 @ step 2850
- n=1 @ 2890 > 3.279000 → ABORT (double-RI destabilizes readout)
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED

**ETA:** ~5h screening (n=1 per arm) + ~5h confirmation (n=2 best arm). Total ~10h.

**Tier: 3 (Diagnostic + Tier Shift).**
Mechanistically grounded in the RI overshoot-correction model. Two-stage RI is a natural generalization that has not been tried. External analogy: Heun's method in ODEs, LAWA weight averaging. Cheap first pass (one extra checkpoint save). Falsifiable at n=1.

---

## Hypothesis H-FZ — PER-GROUP RI LOCALIZED TO lm_head ONLY

### Mechanism

The current RI mechanism interpolates ALL model weights toward the anchor: embed, MLP, attention, lm_head. The key finding from H-FD (alphonse, closed with KEY-INSIGHT) is that the β₂ pulse mechanism is **lm_head-dominant**: embed-only β₂ pulse is FALSIFIED (+0.0027 vs rank-1), while lm_head-only β₂ pulse achieves a first_step_to_target of 2825 (earlier than rank-1's 2850).

By analogy, the RI mechanism may also be lm_head-dominant. If the overshoot that RI corrects lives primarily in lm_head (the "readout" layer that maps hidden states to vocab), then applying RI to ALL weights dilutes the signal with noise from earlier layers (which may have already converged). Restricting RI capture+interpolation to lm_head.weight only would give a cleaner correction signal.

This is testable independently of the β₂ pulse work, because it tests the RI mechanism itself rather than the optimizer state.

**Source:** Inspired by the H-FD per-group localization finding (PR #2422, June 2026, closed KEY-INSIGHT) and general intuition from the lottery-ticket and layer-wise learning-rate literature that final-layer weights behave differently from earlier layers.

### Hypothesis

Restricting RI to lm_head.weight only (γ=−0.075, capture_step=2375, all other weights use raw final values) improves n=4 mean at step 2850 by localizing the overshoot correction to the layer where it matters most.

### Implementation sketch

```python
# In the RI readout logic, gate the interpolation by parameter name:
for name, param in model.named_parameters():
    if 'lm_head' in name:
        param.data = param.data + gamma * (param.data - anchor_params[name])
    # else: leave param.data unchanged (no RI for non-lm_head params)
```

**Arms:**
- Arm A: lm_head-only RI (γ=−0.075, capture_step=2375) — other params get NO RI
- Arm B: lm_head-only RI with slightly stronger γ=−0.100 (since we're now concentrating the correction on fewer parameters, slightly larger γ may be optimal)
- Arm C (optional if Arm A/B both informative): lm_head + final_layer_norm RI (tests whether normalization layer just before lm_head also contributes to overshoot)

**Key implementation notes:**
- Verify what the lm_head parameter is named in this codebase. In nanoGPT it is typically `transformer.lm_head.weight` or similar. Check with `{name for name, _ in model.named_parameters() if 'head' in name}`.
- The anchor checkpoint still captures ALL weights at capture_step=2375 — the filter is applied only at interpolation time.
- lm_head.weight may be tied to the embedding — check the codebase for `weight_tying` or `tie_weights`. If tied, RI on lm_head modifies the embedding too; this would need to be handled carefully (untie before RI if tied, or test both behaviors).

**Decision gate:**
- n=1 @ 2890 ≤ 3.276000 for Arm A or B → proceed to n=2
- n=1 @ 2890 > 3.278500 → ABORT (localization hurts rather than helps — RI signal is NOT lm_head-only)
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED (but provides useful mechanistic data: RI is whole-model, not layer-local)

**ETA:** ~5h screening + ~5h n=2 confirmation. Total ~10h.

**Tier: 3 (Diagnostic).**
Directly tests the "lm_head-dominance" hypothesis in the RI mechanism using the same logic that H-FD applied to the β₂ pulse. The result is informative either way: if it helps, it confirms lm_head-dominance in RI; if it doesn't, it rules out that the whole-model RI can be improved by localization.

---

## Hypothesis H-GA — SOPHIA-H DIAGONAL HESSIAN FOR lm_head

### Mechanism

The rank-1 stack uses AdamW for the auxiliary optimizer (lm_head and scalars parameter groups). AdamW uses a diagonal second-moment estimate of the **gradient** (v_t = β₂ v_{t-1} + (1−β₂) g²) as a preconditioner. This is an approximation to the Fisher information matrix, not the Hessian.

Sophia (Liu et al., 2023, "Sophia: A Scalable Stochastic Second-order Optimizer for Language Model Pre-training," https://arxiv.org/abs/2305.14342) uses a diagonal estimate of the **Hessian** (h_t = β_H g² + (1−β_H) h_{t-1}) instead, where the Hessian diagonal is estimated via Hutchinson's estimator (random probe vectors). The key advantage: in regions of high curvature (like the final layers of a language model during late training), the Hessian preconditioning adapts better than gradient variance.

The β₂ pulse mechanism (rank-1) works by widening the second-moment window at step 820 — this is a crude adjustment to AdamW's curvature estimate. Sophia's Hessian diagonal is a more principled curvature estimate, and **may make the β₂ pulse unnecessary or allow for a better interaction**.

For this experiment, we do NOT replace all AdamW groups with Sophia. We ONLY replace the AdamW optimizer for the lm_head group (the β₂-pulse-dominant group) with Sophia-H. This minimizes risk (Muon and the rest of AdamW are unchanged) and tests the hypothesis cleanly.

**Source:** Sophia (Liu et al., 2023, https://arxiv.org/abs/2305.14342). Sophia-H (Hutchinson estimator variant, Section 3.2 of the paper). PyTorch implementation available at https://github.com/Liuhong99/Sophia. The lm_head-dominant insight comes from H-FD (PR #2422, closed KEY-INSIGHT).

### Hypothesis

Replacing AdamW on the lm_head parameter group with Sophia-H (Hutchinson Hessian diagonal, rho=0.05, beta_H=0.99, update_period=10) with the β₂ pulse retained yields a better n=4 mean at step 2850 than AdamW because Sophia's Hessian preconditioning better handles the high-curvature late training dynamics that the β₂ pulse attempts to address.

### Implementation sketch

```python
# Sophia-H lm_head group — replace the AdamW lm_head optimizer group with:
class SophiaH(torch.optim.Optimizer):
    # Minimal implementation needed:
    # State: m (first moment), h (Hessian diagonal estimate)
    # Every update_period steps: estimate Hessian via Hutchinson (random z ~ N(0,I), backprop g·z·z)
    # Update rule: step = m / max(rho * h, clip_min) (no sqrt, unlike Adam)
    # Weight decay: decoupled (same as AdamW)

# Key hyperparameters to sweep:
# rho (clipping threshold): {0.01, 0.05, 0.10} — Sophia paper uses 0.01–0.05 for LMs
# update_period: {5, 10, 20} — frequency of Hessian re-estimation
# beta_H (Hessian EMA): 0.99 (follow paper default)
# lr: same as current lm_head AdamW lr (or tune ±30%)

# Keep β₂ pulse on the lm_head Sophia group if the interface allows;
# otherwise test with and without the pulse.
```

**Arms:**
- Arm A: Sophia-H lm_head, rho=0.05, update_period=10, β₂ pulse retained as a beta_H schedule
- Arm B: Sophia-H lm_head, rho=0.02, update_period=5 (more frequent, more aggressive)
- If Arm A/B both FALSIFIED: run Arm C (Sophia-H + NO β₂ pulse on lm_head) — tests whether Sophia makes the pulse unnecessary

**Key implementation notes:**
- The Hutchinson estimator requires a SECOND backward pass every update_period steps to compute the Hessian-vector product. This increases VRAM usage and step time. Profile step time before committing to n=4.
- A common alternative that avoids the second backward: use the SQUARED GRADIENT as a Hessian approximation (Sophia-G variant). This is cheaper but less accurate. If Sophia-H is too slow, fall back to Sophia-G.
- The Sophia optimizer was designed for large models (GPT-3 scale); this codebase is smaller. Sensitivity to rho may be different — sweep rho.
- Weight decay and gradient clipping: keep consistent with AdamW baseline. Do not change weight decay for this experiment.
- Reference implementation: https://github.com/Liuhong99/Sophia (MIT license, ~200 LOC)

**Decision gate:**
- n=1 @ 2890 ≤ 3.276500 for any arm → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT arm
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED; note whether removing the β₂ pulse (Arm C) recovers performance
- Step time budget: if Sophia-H step >20% slower than AdamW → switch to Sophia-G variant

**ETA:** ~5h screening + ~5h n=2. Total ~10h. Note Hutchinson-backward may add 5–15% to per-step time.

**Tier: 3 (Tier Shift).**
Strong external evidence that Hessian-preconditioned optimizers outperform Adam-family optimizers on language model final layers. The lm_head-dominance finding from H-FD directly motivates targeting this layer. Result is informative either way: success argues for curvature-aware second-order methods in the readout layer; failure constrains whether the β₂ pulse mechanism is truly about curvature or something else.

---

## Hypothesis H-GB — ADAFACTOR ROW/COLUMN FACTORED SECOND MOMENT FOR lm_head

### Mechanism

AdamW maintains a full per-element second moment v_t for every parameter. For lm_head.weight (shape [vocab_size, hidden_dim], typically ~50,000 × 768 = 38M entries), this is a very large tensor. Adafactor (Shazeer & Stern, 2018, "Adafactor: Adaptive Learning Rates with Sublinear Memory Cost," https://arxiv.org/abs/1805.09843) replaces the full v_t with a row-column factored approximation: V_t ≈ r_t × c_t^T, where r_t is a per-row scale and c_t is a per-column scale. This reduces memory from O(rows × cols) to O(rows + cols) and, crucially, CHANGES the effective preconditioning geometry.

The factored approximation implicitly performs a form of rank-1 preconditioning: it assumes curvature is separable across rows and columns, which may be more appropriate for the lm_head weight matrix (which maps hidden representations to vocabulary tokens) than the isotropic per-element assumption of AdamW.

Unlike Sophia-H, this does not require a second backward pass and is essentially zero extra cost compared to AdamW.

The key question: does the factored second moment provide a BETTER curvature estimate for lm_head than the full AdamW second moment, particularly late in training when the β₂ pulse is active?

**Source:** Adafactor (Shazeer & Stern, 2018, https://arxiv.org/abs/1805.09843). Used in T5, Llama-3 (via Adafactor variant), and PaLM. PyTorch implementation: `transformers.optimization.Adafactor` (HuggingFace, MIT license).

### Hypothesis

Replacing AdamW on the lm_head parameter group with Adafactor (factored second moment, no full v_t, learning_rate from rank-1 lm_head LR, no relative_step decay) with the β₂ pulse retained yields a better n=4 mean at step 2850 because the row/column factorization better captures the separable curvature structure of the lm_head weight matrix.

### Implementation sketch

```python
# Adafactor for lm_head group only:
from transformers.optimization import Adafactor

lm_head_optimizer = Adafactor(
    [p for n, p in model.named_parameters() if 'lm_head' in n],
    lr=lm_head_lr,           # use same LR as rank-1 AdamW lm_head group
    beta1=0.9,               # first moment (same as AdamW beta1)
    eps=(1e-30, 1e-3),       # (eps1 for numerical stability, eps2 for relative scale)
    clip_threshold=1.0,      # gradient clipping in Adafactor
    decay_rate=-0.8,         # second-moment decay: if >0, uses relative step decay; set -1 to disable and use fixed lr
    relative_step=False,     # MUST set False to use fixed lr
    scale_parameter=False,   # MUST set False to use fixed lr
    warmup_init=False,
    weight_decay=rank1_wd,   # same weight decay as rank-1
)
# Keep β₂ pulse: implement as a beta2_t schedule on the Adafactor eps2 parameter (or skip and test without pulse first)
```

**Arms:**
- Arm A: Adafactor lm_head, fixed lr (same as rank-1 lm_head AdamW lr), β₂ pulse applied via `eps` schedule (eps2: 1e-3 → 1e-8 @ step 820, analogous to β₂ pulse on second moment)
- Arm B: Adafactor lm_head, fixed lr, NO pulse (test whether factored second moment alone is sufficient)

**Key implementation notes:**
- `relative_step=False` and `scale_parameter=False` are CRITICAL — without these, Adafactor uses its own internal LR schedule which overrides the externally supplied lr.
- Adafactor's `clip_threshold=1.0` does NOT correspond to AdamW gradient clipping. It's an internal step-size normalization. Keep the existing global gradient clipping from the codebase.
- The `beta1` parameter controls the first moment. Adafactor paper recommends beta1=None for memory savings, but we want to keep a first moment for compatibility with EN (EMA-Nesterov). Use beta1=0.9.
- For very large vocab_size, the row sum r_t has shape [vocab_size] — this is 50K floats, fine.
- The factored second moment means the effective β₂ is not a fixed scalar but varies per-element (it depends on both r_t and c_t). This is a fundamentally different preconditioning from AdamW. Do not apply the β₂ pulse in the same way — instead, test Arm B (no pulse) first.
- HuggingFace Adafactor is battle-tested; prefer it over a custom implementation to reduce bugs.

**Decision gate:**
- n=1 @ 2890 ≤ 3.276500 → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED

**ETA:** ~5h screening + ~5h n=2. Total ~10h. Very low step-time overhead vs AdamW.

**Tier: 3 (Tier Shift).**
Strong theoretical basis (Adafactor factored second moment is well-studied and used in production LLM training). Connection to this codebase is indirect (we are applying it to only one parameter group), but the lm_head-dominance finding from H-FD directly motivates this experiment. The factored second moment changes the preconditioning geometry in a way that is mechanistically distinct from the β₂ pulse, and the two could be orthogonal and combinable.

---

## Hypothesis H-GC — SAM ONE-STEP PERTURBATION ON lm_head ONLY

### Mechanism

Sharpness-Aware Minimization (SAM, Foret et al., 2021, "Sharpness-Aware Minimization for Efficiently Improving Generalization," https://arxiv.org/abs/2010.01412) modifies the optimizer to minimize loss at a perturbed weight point w + ε·g/||g|| (a one-step ascent in gradient direction to the sharpest nearby point), then computes gradients at that perturbed point and uses them for the actual update. This finds flatter minima and improves generalization.

Standard SAM doubles the per-step compute cost (two gradient computations per step). However, applying SAM ONLY to lm_head (the dominant-signal layer per H-FD) dramatically reduces this overhead: the perturbation gradient computation is localized to one parameter group, so the extra cost is proportional to lm_head size relative to total model size. In this architecture (lm_head is roughly 38M/124M ≈ 30% of total params), this means approximately 30% overhead per SAM step, not 100%.

Late in training, the β₂ pulse (rank-1) is an implicit curvature adaptation. SAM is a more direct mechanism: it explicitly penalizes sharp directions. If the loss landscape near rank-1's minimum has a sharp lm_head subspace (consistent with lm_head needing special curvature handling), SAM on lm_head directly addresses this.

**Source:** SAM (Foret et al., 2021, https://arxiv.org/abs/2010.01412). ESAM/M-SHARPNESS for efficient variants. Kaggle community has repeatedly found SAM/ASAM gives 0.1–0.3% improvements on language-generation leaderboards through better flatness. Recent LLM SAM work: "SAM as an Optimal Relaxation of Bayes" (Möllenhoff & Khan, 2023) argues SAM implicitly does Bayesian averaging, suggesting better generalization.

### Hypothesis

Applying SAM with perturbation ONLY on lm_head parameters (ρ=0.05, one forward+backward per step) with the β₂ pulse retained yields a better n=4 mean at step 2850 because it finds a flatter minimum in the lm_head subspace that generalizes better than the sharp minimum found by AdamW alone.

### Implementation sketch

```python
# SAM perturbation applied only to lm_head before the main optimizer step:
# 1. Forward pass to get loss L(w)
# 2. Backward pass to get g = ∇_{lm_head} L(w)
# 3. Perturb only lm_head: w_lm_head += rho * g / ||g||   (e-hat step)
# 4. Forward pass again (full model) to get L(w + epsilon * e-hat)
# 5. Backward pass for FULL model to get gradients at perturbed point
# 6. Restore lm_head: w_lm_head -= rho * g / ||g||
# 7. Apply optimizer step using gradients from step 5

# Alternatively (cheaper): gradient surgery version
# Only perturb lm_head in step 3; do the full forward+backward in step 4-5
# This is ~30% overhead if lm_head is 30% of params

# rho sweep: {0.02, 0.05, 0.10} — SAM paper uses 0.05 for vision; LLM settings may prefer smaller

# Optionally apply SAM only during the LAST K steps (e.g., last 500 steps):
# This avoids SAM overhead during early training where flatness may not matter
```

**Arms:**
- Arm A: SAM lm_head-only, ρ=0.05, all training steps, β₂ pulse retained
- Arm B: SAM lm_head-only, ρ=0.02, last 500 steps only (from step 2390 onwards, matching RI timing)

**Key implementation notes:**
- The double-forward-pass requirement means step time will increase. Estimate: if lm_head backward is ~25% of total backward time, Arm A adds ~25% wall time. This must stay within the training time budget.
- Use the "closure" pattern for SAM: wrap the loss computation in a closure that is called twice.
- Gradient accumulation (if any): SAM must perturb before the accumulation step completes. Verify the codebase's gradient accumulation logic.
- The perturbation must be applied to the optimizer's parameter storage, not to a copy of the weights. After restoring, the parameter values are identical to before the perturbation.
- ASAM (Kwon et al., 2021) is an adaptive-ρ variant that may work better with AdamW. Consider ASAM as a cheaper Arm C if both arms are FALSIFIED.

**Decision gate:**
- n=1 @ 2890 ≤ 3.276500 → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT
- Step time overhead > 40% vs baseline → downgrade to Arm B (last-500-steps SAM only)
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED

**ETA:** ~5–6h screening (note step overhead) + ~5h n=2. Total ~11h.

**Tier: 3 (Tier Shift).**
Well-evidenced external literature for SAM improving generalization in language models. The lm_head-dominant finding motivates localizing SAM to lm_head specifically. The result clearly tests whether flatness-seeking in lm_head adds independent signal on top of AdamW + β₂ pulse.

---

## Hypothesis H-GD — DECOUPLED WEIGHT DECAY DURING COOLDOWN (WD=0 DESCENT)

### Mechanism

The rank-1 stack uses AdamW (AdamW = Adam + decoupled weight decay). Weight decay acts as an L2 regularizer: w_{t+1} = w_t − lr·step_direction − lr·wd·w_t. During the LR cooldown phase (the final ~30% of training), the LR drops from ~1.0 to near-0. The WEIGHT DECAY term does NOT drop proportionally — it is decoupled from the Adam update, so as LR decreases, the weight-decay L2 pull becomes RELATIVELY stronger compared to the gradient signal.

This asymmetry means the final weights are pulled toward the L2 ball by an increasingly dominant weight-decay term, even as the gradient direction becomes weaker. This is potentially suboptimal: if the model has already converged to a well-shaped minimum, the final weight decay pulls away from it.

Setting WD=0 during the cooldown phase means the final weights are positioned solely by the gradient descent trajectory without additional L2 contraction. This gives the model maximum freedom to reach the minimum the optimizer is converging toward, rather than having the minimum compromised by weight decay's L2 pull.

**Source:** Analogous to "decoupled weight decay schedules" in recent LLM training recipes (e.g., Chinchilla scaling law experiments). The observation that AdamW weight decay interacts differently from SGD weight decay during LR cooldown is documented in "Decoupled Weight Decay Regularization" (Loshchilov & Hutter, 2019, https://arxiv.org/abs/1711.05101). Recent nanoGPT training recipes (KellerJordan) use fixed WD throughout; this axis has not been tested in this codebase.

### Hypothesis

Setting AdamW weight_decay=0 for all parameter groups during the LR cooldown phase (from cd_start to end of training) while retaining wd=0.1 during the warmup and constant LR phase improves n=4 mean at step 2850 because it removes the L2 contraction bias during the critical final descent.

### Implementation sketch

```python
# In the optimizer step or LR scheduler:
# At each step, check if we are in the cooldown phase (lr < lr_max):
step_frac = step / total_steps
in_cooldown = step_frac > (1.0 - cooldown_frac)  # cooldown_frac=0.30

# Apply WD only outside cooldown:
for group in optimizer.param_groups:
    if in_cooldown:
        group['weight_decay'] = 0.0
    else:
        group['weight_decay'] = base_wd  # rank-1 default (0.1 or similar)

# Alternative: linear taper of WD during cooldown:
#   wd_t = base_wd * (1 - step_frac_within_cooldown)
# This is a softer version of the full WD=0 step.

# Flag: --wd_cooldown_mode {zero, taper, constant}  default: constant (rank-1)
```

**Arms:**
- Arm A: WD=0 at cooldown start (hard step-off), all param groups
- Arm B: WD linearly tapered 0.1→0 over cooldown (softer version)
- Both arms use β₂ pulse and all other rank-1 flags unchanged

**Key implementation notes:**
- Verify the rank-1 weight_decay value. In nanoGPT it is often `weight_decay=0.1` for non-embedding params and `weight_decay=0.0` for embeddings. Apply WD taper/zero only to groups that currently have WD > 0.
- The cooldown_frac=0.30 means cd_start is at step ~2023 for the current 2890-step budget. WD=0 applies for the last ~867 steps.
- This change interacts with the β₂ pulse (step 820 fires during the CONSTANT LR phase, before WD taper starts). These two mechanisms are roughly orthogonal.
- Interaction with RI: RI capture at step 2375 is INSIDE the cooldown (cd_start ≈ 2023). WD=0 during cooldown means RI anchor weights are captured from a WD-free trajectory — the anchor may be at a different position than with constant WD. This could compound RI's signal positively (if WD was pulling the anchor away from the minimum) or negatively (if WD was providing useful regularization). Watch for this interaction.

**Decision gate:**
- n=1 @ 2890 ≤ 3.276500 for either arm → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED
- Compare Arm A vs Arm B: if Arm B (taper) outperforms Arm A (hard zero), this suggests partial WD is beneficial during cooldown onset.

**ETA:** ~5h screening + ~5h n=2. Total ~10h.

**Tier: 2 (Frontier refinement).**
Mechanistically grounded in the known AdamW decoupling asymmetry during LR cooldown. The hypothesis is specific and falsifiable. Risk: wd=0 may allow weight growth that degrades generalization (the point of weight decay). The taper arm mitigates this. External evidence is limited for this specific setting, but the mechanism is well-understood theoretically.

---

## Hypothesis H-GE — NS5 POLYNOMIAL COEFFICIENT DISTRIBUTION-SPECIFIC FIT

### Mechanism

The NS5 coefficients (a, b, c) = (3.4445, −4.7750, 2.0315) used in rank-1 are the canonical values that minimize the worst-case convergence bound for a Schulz polynomial iteration with degree-5 polynomial applied to matrices with singular values in [0.01, 1.0]. This is the GENERIC minimax-optimal solution.

However, the actual singular value distribution of Muon's momentum gradient matrices is NOT uniform in [0.01, 1.0]. It is specific to this model, dataset, and training stage. If the singular values are concentrated in a narrower range (e.g., [0.1, 0.9] at most steps), then a polynomial fit optimized for THAT specific interval would converge faster in those 5 iterations and provide a better orthogonalization.

This can be measured: log the singular value histograms of the Muon momentum matrices at several training steps (e.g., steps 400, 800, 1200, 1600, 2000, 2400) for each parameter group. Use the observed min/max percentiles (e.g., 1st and 99th percentile) as the actual optimization interval for the Schulz polynomial. Compute new (a, b, c) coefficients offline via scipy.optimize.minimize on the worst-case error over the observed interval.

**Source:** Original NS5 coefficients from Kovarik (2023) / KellerJordan modded-nanoGPT PR #305 (https://github.com/KellerJordan/modded-nanoGPT/pull/305). The optimization criterion for Schulz polynomial coefficients is well-documented in numerical linear algebra (cf. Björck & Hammarling, 1983). The idea of fitting polynomial iterations to the actual spectrum of the target matrix class is standard in domain-specific preconditioning literature (see e.g., "Polynomial preconditioning," Saad, 1985).

### Hypothesis

Computing NS5 polynomial coefficients (a, b, c) optimized for the OBSERVED singular value range of Muon momentum matrices in this training run (rather than the generic [0.01, 1.0] minimax bound) improves convergence of the 5-step Schulz iteration, yielding a better orthogonalization and a lower n=4 mean at step 2850.

### Implementation sketch

**Phase 1 — Measurement (offline, 1 training run):**
```python
# Add a logging hook to the Muon optimizer's NS5 step:
# At each of steps {400, 800, 1200, 1600, 2000, 2400}:
#   for each param group in Muon:
#     G = momentum matrix (before NS5)
#     sv = torch.linalg.svdvals(G)  # or approx via power iteration for large matrices
#     log sv.min(), sv.max(), sv.quantile(0.01), sv.quantile(0.99), sv.mean()
# Save these to W&B or a local file. This logging run need not be a full training run.
```

**Phase 2 — Coefficient optimization (offline computation, ~10 min Python):**
```python
from scipy.optimize import minimize
import numpy as np

def schulz5_error(coeffs, sv_range):
    a, b, c = coeffs
    sv = np.linspace(sv_range[0], sv_range[1], 10000)
    X = sv.reshape(-1, 1)
    # Schulz iteration: X_{k+1} = a*X_k + b*X_k^3 + c*X_k^5
    # For degree-5 poly: Y = a*X + b*X^3 + c*X^5
    Y = a*X + b*X**3 + c*X**5
    # After 5 iterations starting from identity-scaled X:
    # Convergence criterion: |Y - 1/X| for singular values of the final output
    return np.max(np.abs(Y.flatten() - 1.0))  # error on target X @ Y = I

result = minimize(schulz5_error, x0=[3.4445, -4.7750, 2.0315],
                  args=([sv_min_observed, sv_max_observed],),
                  method='Nelder-Mead')
a_opt, b_opt, c_opt = result.x
```

**Phase 3 — Training run with optimized coefficients:**
- Add flags `--ns5_a {a_opt} --ns5_b {b_opt} --ns5_c {c_opt}` to override the hardcoded NS5 coefficients
- Run n=1 screening, then n=2 confirmation

**Arms:**
- Arm A: Coefficients fit to observed [p1, p99] singular value range (moderate fit)
- Arm B: Coefficients fit to [p5, p95] range (tighter fit, more aggressive)
- Arm C (diagnostic): Coefficients fit to [p1, p99] but evaluated on a DIFFERENT training step to test whether the optimal range is stable across training

**Key implementation notes:**
- The NS5 polynomial must converge to the matrix inverse square root for ANY singular value in the targeted range. If the range is set too tight and a singular value falls outside it, NS5 diverges badly. Always check that the optimized polynomial has no roots in [0, sv_max] × (0, 1) before committing to a training run.
- The polynomial degree-5 Schulz iteration is applied iteratively (5 times). The coefficient optimization above is for a SINGLE iteration — the multi-iteration analysis is more complex. Use the gradient-descent-based optimization from the original NS5 paper (minimize the final ||X^T X − I||_F after 5 iterations, not a single-step bound).
- If singular values vary substantially across training stages, consider using DIFFERENT coefficients for early vs late training (add a step-dependent schedule).
- Check the current codebase to confirm whether (a, b, c) are hardcoded or parameterized.

**Decision gate:**
- Phase 1 must complete before Phase 3 runs — include measurement code as a quick 200-step sampling run (not full training).
- n=1 @ 2890 ≤ 3.276500 → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT (distribution-specific fit hurts NS5 stability)
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED (generic coefficients are robust, not suboptimal)

**ETA:** ~1h Phase 1 (measurement run) + ~2h Phase 2 (offline) + ~5h Phase 3 (screening) + ~5h n=2. Total ~13h. This is longer than a standard run — assign to a student who can implement Phase 1+2 quickly.

**Tier: 3 (Diagnostic + Tier Shift).**
High mechanistic precision: the hypothesis is directly about whether the NS5 coefficients are suboptimal for the actual spectrum of this problem. The measurement phase provides useful diagnostic data regardless of outcome (reveals whether singular values are well-conditioned). External evidence from numerical linear algebra is strong. Risk: the multi-iteration optimization is harder than the single-step analysis; make sure the implementation is correct.

---

## Hypothesis H-GF — LARS-STYLE PER-GROUP LR SCALING (LAYER-WISE ADAPTIVE RATE SCALING)

### Mechanism

Layer-wise Adaptive Rate Scaling (LARS, You et al., 2017, "Large Batch Training of Convolutional Networks," https://arxiv.org/abs/1708.03888) adjusts the effective learning rate for each parameter group by the ratio ||weights|| / ||gradients||. The intuition: layers where the gradient is small relative to the weight magnitude should use a larger effective LR (they need bigger steps to move meaningfully), and vice versa. LARS was designed for large-batch SGD but the same principle applies to Adam-family optimizers.

The rank-1 stack uses fixed per-group LRs (Muon LR for transformer blocks, separate AdamW LR for embed, lm_head, scalars). These ratios are set by hand and have been swept (H-BL for embed, H-FS for lm_head LR pulse). However, they are FIXED throughout training, which means:
1. Early in training: large weight norms, small gradient norms → LR is "too small" for large layers
2. Late in training: weight norms may shift dramatically, especially after β₂ pulse → fixed LR becomes increasingly miscalibrated

LARS-style ONLINE per-group LR adjustment would recompute the scaling factor at each step and would naturally handle this drift. A minimal implementation: compute the LARS trust ratio η = λ||w|| / (||g|| + ε||w||) at each step for each param group and multiply the effective LR by min(η, 1.0) (clamped at 1 to avoid amplifying groups that are already getting large updates).

**Source:** LARS (You et al., 2017, https://arxiv.org/abs/1708.03888). LAMB (You et al., 2020, "Large Batch Optimization for Deep Learning: Training BERT in 76 minutes," https://arxiv.org/abs/1904.00962) applies the same idea to Adam. The key insight from LAMB that applies here: the ratio-based LR scaling works well for layers with very different update magnitudes, which is exactly the situation with lm_head vs transformer blocks.

### Hypothesis

Applying LARS-style per-group LR scaling (trust ratio clamped at [min_trust=0.1, max_trust=1.0]) to the AdamW auxiliary optimizer groups (embed, lm_head, scalars) while leaving Muon unchanged improves n=4 mean at step 2850 by better adapting the per-group effective LRs as the weight distribution shifts during late training.

### Implementation sketch

```python
# LARS trust ratio computation for AdamW parameter groups:
LARS_LAMBDA = 0.001  # trust coefficient (λ in LARS paper), sweep {0.001, 0.005, 0.01}
MIN_TRUST = 0.1      # minimum trust ratio (prevent excessive LR reduction)

# In the AdamW optimizer step (or as a wrapper):
for group in aux_optimizer.param_groups:
    if group.get('use_lars', False):
        # Compute per-group weight norm and gradient norm
        w_norm = torch.norm(torch.stack([p.norm() for p in group['params'] if p.grad is not None]))
        g_norm = torch.norm(torch.stack([p.grad.norm() for p in group['params'] if p.grad is not None]))
        if g_norm > 0 and w_norm > 0:
            trust_ratio = LARS_LAMBDA * w_norm / (g_norm + LARS_LAMBDA * w_norm)
            trust_ratio = max(trust_ratio.item(), MIN_TRUST)
        else:
            trust_ratio = 1.0
        # Scale the effective LR for this step:
        effective_lr = group['lr'] * trust_ratio
        group['lr_this_step'] = effective_lr  # use effective_lr in update formula
```

**Arms:**
- Arm A: LARS on AdamW groups (embed, lm_head, scalars), λ=0.001, min_trust=0.1
- Arm B: LARS on lm_head group ONLY (not embed, not scalars), λ=0.005 (stronger trust, since lm_head is the dominant group per H-FD)

**Key implementation notes:**
- LARS was designed for SGD; with AdamW, the effective step direction is already scaled by 1/√v̂_t (Adam denominator). LARS trust ratio should be applied to the LEARNING RATE, not to the raw gradient, to avoid double-scaling.
- The trust ratio changes every step — this increases optimizer state computation slightly (norms must be computed). For large models this matters; for nanoGPT scale it is negligible.
- Verify that the LARS trust ratio doesn't fight with the β₂ pulse: the pulse changes v_t (and thus the effective step size) at step 820. The LARS ratio will naturally adapt to the new step size post-pulse. This interaction is actually DESIRED — LARS should re-calibrate after the pulse.
- The existing H-FS (lm_head LR ×1.5 pulse) applies a fixed multiplier at step 820. LARS is different: it is dynamic and continuous, not a one-time fixed step. Do not confuse these mechanisms.
- Do NOT apply LARS to Muon groups — Muon already has a sophisticated trust mechanism built into the Newton-Schulz orthogonalization. Applying LARS to Muon would double-adapt the step size.

**Decision gate:**
- n=1 @ 2890 ≤ 3.276500 → proceed to n=2
- n=1 @ 2890 > 3.279000 → ABORT
- n=2 @ step 2850 ≤ 3.277172 → ESCALATE to n=4
- n=2 @ step 2850 > 3.278000 → FALSIFIED

**ETA:** ~5h screening + ~5h n=2. Total ~10h.

**Tier: 2 (Frontier refinement).**
Mechanistically well-grounded in the LARS/LAMB literature. The connection to this codebase is plausible: fixed per-group LRs that were sweep-optimized may become suboptimal as the weight distribution shifts during late training. However, the existing lm_head LR sweep (H-FS) partially covers this space, so the incremental gain may be smaller than for the other hypotheses above.

---

## Priority ranking for assignment wave

The following priority order is recommended based on mechanistic novelty, research-state information value, and expected ESCALATE probability given the n=2 threshold of 3.277172:

1. **H-GC (SAM lm_head)** — Most novel tier shift; directly targets the sharpness in the dominant-signal layer. External evidence strong. Step-time overhead manageable.
2. **H-FZ (per-group RI lm_head)** — Direct analogue of the H-FD key insight applied to RI. High information value either way. Zero extra cost.
3. **H-FY (two-stage RI)** — Quadratic generalization of RI. Clean mechanism, cheap to implement (one extra checkpoint). Heun analogy strong.
4. **H-GA (Sophia-H lm_head)** — Highest mechanistic differentiation. Requires careful implementation (second backward). Strong external evidence.
5. **H-GE (NS5 coefficient fit)** — Highest precision, but requires two-phase execution. Assign to an experienced student.
6. **H-GB (Adafactor lm_head)** — Easy to implement via HuggingFace. May be dominated by H-GA mechanistically.
7. **H-GD (decoupled WD cooldown)** — Lower risk, lower expected gain. Good diagnostic value for understanding AdamW's role in cooldown.
8. **H-GF (LARS per-group)** — Incremental refinement. Partially covered by H-FS already.

For the 3 idle students (askeladd, thorfinn, fern), assign **H-GC, H-FZ, H-FY** in that order of priority.
