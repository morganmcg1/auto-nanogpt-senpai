# H248 edward — Post-NS5 Adaptive Preconditioning (44th Mechanism Class)

**Date:** 2026-05-28 (cycle ~1130)
**Hypothesis ID:** H248
**Student:** edward
**Mechanism class:** 44 — Post-NS5 diagonal EMA-g² preconditioning
**Baseline:** PR #1398 H203, val=3.26830, FFS=3025

---

## 1. Mechanism Class Selection

This is the **44th mechanism class** in the campaign and the **first post-NS5 preconditioning experiment** in campaign history.

The selection is grounded in a 3-leg closure on second-order body preconditioning that was applied _before_ NS5:

- **H92 MARS-M**: Pre-NS5 gradient correction with lookahead momentum. NULL/NEG.
- **H93 PSGD-Kron**: Kronecker/block-diagonal preconditioner `Q_L ⊗ Q_R`. NULL/NEG. Closed the entire family (SOAP, Shampoo, CASPR, ARFKE) under AGC-binding regime — all collapse to uniform scaling.
- **H98 Sophia-G**: Diagonal Hessian approximation via EMA-g² applied before NS5. NULL/NEG.

All three applied their curvature estimate **before** the NS5 polar projection step. None tested what happens when you apply a diagonal curvature correction **after** NS5 returns.

Post-NS5 preconditioning is structurally different for a precise reason: NS5 orthogonalizes the gradient matrix, projects it onto the Stiefel manifold (spectral norm ≈ 1), and erases magnitude information. The subsequent `update *= max(1, m/n)**0.5` step restores a global scaling factor based on shape, but every spatial direction in the matrix is treated identically. A post-NS5 EMA-g² denominator asks whether individual update directions — after orthogonalization — have systematically different RMS magnitudes across training, and if so whether correcting them accelerates convergence.

From a differential geometry perspective: NS5 projection maps the gradient onto a tangent vector of the Stiefel manifold S(m,n). The RMS of directions in this tangent vector may vary across coordinates. Post-NS5 preconditioning applies element-wise adaptive scaling within the tangent space of the manifold — a diagonal Riemannian metric on the Stiefel manifold. Pre-NS5 methods (H93, H98) operate in ambient gradient space before projection; this technique operates in projected tangent space. The distinction is non-trivial and has not been tested.

---

## 2. Hypothesis Statement

The NS5 polar projection in MuonH erases all magnitude information, projecting the gradient matrix onto a nearly-orthogonal frame. The subsequent global shape-correction scaling (`max(1, m/n)**0.5`) treats all update directions identically. We hypothesize that after projection, individual update directions have systematic EMA-g² variation that a diagonal adaptive denominator can correct — reducing the effective step-size noise per coordinate and accelerating convergence to the FFS=3.28 target. This post-NS5 adaptive scaling operates in the tangent space of the Stiefel manifold, making it geometrically distinct from all prior preconditioning attempts (H92, H93, H98) which operated in pre-projection gradient space. A fast EMA (β_v=0.99) adapts within-run, possibly tracking non-stationary curvature in the projected space. A slow EMA (β_v=0.999) provides a more stable baseline estimate of persistent directional variance. Because the injection point is outside `@torch.compile`, this experiment avoids the +25 FFS / +1.3σ_H174 retracing soft-drift class entirely.

---

## 3. Mechanism Analysis

**Why this experiment now.** The programme has achieved bilateral closure on every category of second-order body preconditioning that acts before the NS5 step. The 3-leg pre-NS5 closure (H92 + H93 + H98) is structurally complete — all Kronecker, diagonal-Hessian, and gradient-correction families applied before polar projection have been ruled null. The natural successor is to ask whether any benefit exists from preconditioning the output of NS5, not its input. This is not merely a variant of a prior closed class; it tests a different computational layer. The campaign has also closed the aux optimizer class (PROGRAMME FINDING #55) and the MuLoCo HP+FORM class (PROGRAMME FINDING #54), meaning two of the three major structural components are settled. The remaining open axis on the body optimizer is the NS5 output layer.

**What we learn WIN or NULL.** If ARM_B or ARM_C beats baseline (FFS < 3025): the diagonal RMS structure of the post-NS5 update is non-uniform and correction helps. This would motivate follow-up experiments varying ε_v, incorporating layer-wise scaling β_v, or moving to a 2nd-order Riemannian metric rather than a diagonal one. If both arms are NULL (+/-5 FFS, < 3σ_H174 effect): the post-NS5 update directions are effectively uniform in RMS after the shape-correction scaling, i.e., NS5 produces well-conditioned updates that need no further per-coordinate adjustment. This would close the post-NS5 diagonal preconditioning class and narrow the remaining open axes to: (a) LR schedule shape variations, (b) per-layer LR structure (H244 currently in flight), and (c) outer optimizer form (H246 LoCo-Adam, also in flight). If ARM_C beats ARM_B (fast EMA better than slow EMA), the post-NS5 RMS structure is non-stationary within a run — possibly tied to warmup or cooldown schedule transitions — and adaptive tracking is necessary. If ARM_B beats ARM_C (slow EMA better), the structure is persistent and stable, more like a per-coordinate scale factor than a dynamic curvature signal.

**Schmidhuber-style cross-disciplinary grounding.** The NS5 iteration is structurally a Riemannian gradient descent step toward the Stiefel manifold S(m,n). The resulting update lives in the tangent space T_X S(m,n). The EMA-g² denominator applied to elements of this tangent vector defines a diagonal Riemannian metric on the update tangent bundle — i.e., it is an online estimate of a diagonal preconditioner for the Riemannian gradient, not the ambient Euclidean gradient. This connects to the literature on natural gradient methods on matrix manifolds (Bonnabel 2013, Edelman-Arias-Smith 1998) but in a purely diagonal, computationally cheap form. From the random matrix theory perspective: NS5 maps a random gradient matrix through 12 iterations of a polynomial that converges to the polar factor. The singular value distribution of the output is nearly flat (all ≈ 1). If the element-wise squared magnitudes of the resulting matrix are not uniform — i.e., if the eigenvectors of the Gram matrix `X^T X` have direction-dependent projection weights — then the EMA-g² denominator corrects for this residual non-uniformity in the tangent-space metric. Marchenko-Pastur theory predicts that random rectangular matrices DO have direction-dependent RMS structure in their singular vectors, so there is a first-principles reason to expect the correction to be non-trivial, not cosmetic.

---

## 4. Three-Arm Structure

| Arm | Name | post_ns5_precond | β_v | ε_v | Purpose |
|-----|------|-----------------|-----|-----|---------|
| ARM_A | CTRL | False (disabled) | N/A | N/A | Bit-identity baseline, must reproduce FFS=3025, val=3.26830 |
| ARM_B | POST_NS5_SLOW | True | 0.999 | 1e-8 | Slow EMA — persistent directional variance estimate |
| ARM_C | POST_NS5_FAST | True | 0.99 | 1e-8 | Fast EMA — adaptive tracking of non-stationary curvature |

**Rationale for β_v choices.** β_v=0.999 is the standard AdamW second-moment decay used in the campaign's aux optimizer. It provides a stable estimate of persistent directional variance. β_v=0.99 is 10x faster — closer to the Sophia-G heuristic and suitable for detecting within-run non-stationarity. These two values bracket the interesting regime: outside this range (β_v > 0.9999 = too slow, β_v < 0.9 = too noisy) the mechanism is unlikely to function as intended. If one arm beats baseline, a follow-up can refine within the winning interval.

**Arm ordering and wallclock.** Sequential: ARM_A → ARM_B → ARM_C. Each arm ~1.7h wallclock on a single GPU. Total chain: ~5.1h. Budget: 8h. Margin: ~2.9h buffer for retrace warmup and W&B sync.

---

## 5. Implementation Instructions

### 5.1 Argparse flags to add

In the argparse section of `train_gpt_simple.py`, add three new flags (after the existing `--muonh_agc_eps` flag or in the MuonH hyperparameter group):

```python
# Post-NS5 adaptive preconditioning
parser.add_argument("--muonh_post_ns5_precond", action="store_true", default=False,
                    help="Enable diagonal EMA-g² preconditioning applied after NS5 polar projection.")
parser.add_argument("--muonh_post_ns5_beta", type=float, default=0.999,
                    help="EMA decay for post-NS5 squared update accumulator. Default 0.999 (slow/stable).")
parser.add_argument("--muonh_post_ns5_eps", type=float, default=1e-8,
                    help="Epsilon for post-NS5 adaptive denominator. Default 1e-8.")
```

Verification: grep for `muonh_agc_eps` to find the exact insertion line.

### 5.2 W&B config dict additions

In the `config = {...}` dict (lines ~818-853), add three new keys alongside the existing MuonH keys:

```python
"muonh_post_ns5_precond": args.muonh_post_ns5_precond,
"muonh_post_ns5_beta":    args.muonh_post_ns5_beta,
"muonh_post_ns5_eps":     args.muonh_post_ns5_eps,
```

These keys MUST be present in the W&B config pane for each arm so the advisor can distinguish CTRL vs ARM_B vs ARM_C at a glance. Absence of these keys in the config pane is a config audit failure.

### 5.3 MuonH optimizer group propagation

In the `MuonH.__init__` `defaults` dict, add the new HP keys:

```python
defaults = dict(lr=lr, weight_decay=weight_decay, mu=mu,
                hyperball=hyperball, budget_mult=budget_mult, mode=mode,
                post_ns5_precond=False, post_ns5_beta=0.999, post_ns5_eps=1e-8)
```

In the optimizer construction block where `optimizer2 = MuonH(...)` is called, pass the new flags:

```python
optimizer2 = MuonH([p for p in model.blocks.parameters() if p.ndim >= 2],
                   lr=args.muonh_lr, weight_decay=0.0, mu=0.95,
                   hyperball=True, budget_mult=args.muonh_budget_mult,
                   mode=args.muonh_mode,
                   post_ns5_precond=args.muonh_post_ns5_precond,
                   post_ns5_beta=args.muonh_post_ns5_beta,
                   post_ns5_eps=args.muonh_post_ns5_eps)
```

### 5.4 State initialization in MuonH.step()

Inside the `if len(state) == 0:` block in `MuonH.step()`, after the existing state initialization (momentum, hyperball_radius), add:

```python
if group.get("post_ns5_precond", False):
    state["post_ns5_ema_sq"] = torch.zeros_like(p)
```

This must be inside the `if len(state) == 0:` guard to avoid re-initialization on subsequent steps.

### 5.5 Post-NS5 preconditioning injection

After `update = muon_update(p.grad, state["momentum"], mu=group["mu"])` returns and **before** the `if hb and mode == "scale_invariant":` block, insert:

```python
# Post-NS5 diagonal EMA-g² preconditioning (outside @torch.compile)
if group.get("post_ns5_precond", False):
    beta_v = group.get("post_ns5_beta", 0.999)
    eps_v  = group.get("post_ns5_eps", 1e-8)
    v = state["post_ns5_ema_sq"]
    v.mul_(beta_v).addcmul_(update, update, value=1 - beta_v)
    update = update / (v.sqrt() + eps_v)
```

**Critical:** This block is entirely outside `@torch.compile`. The `muon_update` function is the ONLY compiled region. This placement avoids the +25 FFS / +1.3σ_H174 soft-drift class caused by argparse-conditional branches inside the compiled kernel. The `addcmul_` op is a standard in-place PyTorch op that avoids unnecessary temporary allocations.

**Critical:** After `update = update / (v.sqrt() + eps_v)`, the update has had its global scale substantially reduced (divided by its own RMS-like estimate). The existing `update *= max(1, grad.size(-2) / grad.size(-1))**0.5` shape correction still applies normally because it is computed inside `muon_update` before this block executes. The post-NS5 denominator re-scales the already shape-corrected update. The net effect is approximately: `update_effective ≈ update_ns5 / RMS(update_ns5)`, which normalizes per-coordinate, equivalent to adaptive step scaling within the tangent space.

**Note on scale and LR interaction:** Post-NS5 preconditioning will change the effective scale of the body update — similar to how Adam's ε controls effective step magnitude. The existing `muonh_lr=0.018` was tuned for un-preconditioned NS5 updates. For the first pass (ARM_B and ARM_C), use the same `muonh_lr=0.018` to isolate the directional correction effect. If results show a scale collapse (loss explodes or stalls), the follow-up should sweep LR jointly. The diagnostic telemetry (Section 5.6) will reveal if scale is the confound.

### 5.6 Diagnostic telemetry

At every `telemetry_due` step, on rank 0, after the optimizer step, add telemetry that characterizes the post-NS5 EMA state. This telemetry should only fire when `args.muonh_post_ns5_precond` is True:

```python
# Post-NS5 preconditioning telemetry (fires when feature is active)
if args.muonh_post_ns5_precond and telemetry_due and rank == 0:
    _scales = []
    for p in model.blocks.parameters():
        if p.ndim >= 2:
            _state = optimizer2.state.get(p, {})
            if "post_ns5_ema_sq" in _state:
                _v = _state["post_ns5_ema_sq"]
                _denom = (_v.sqrt() + args.muonh_post_ns5_eps)
                _scales.append(_denom.float())
    if _scales:
        _all_scales = torch.cat([s.flatten() for s in _scales])
        wandb.log({
            "train/muonh/post_ns5_scale_rms": _all_scales.pow(2).mean().sqrt().item(),
            "train/muonh/post_ns5_scale_min": _all_scales.min().item(),
            "train/muonh/post_ns5_scale_max": _all_scales.max().item(),
        }, step=step)
```

These three metrics reveal whether the EMA denominator has developed meaningful per-coordinate variation:
- `post_ns5_scale_rms`: if this grows significantly above `eps_v`, the EMA has accumulated non-trivial estimates.
- `post_ns5_scale_min` / `post_ns5_scale_max`: the ratio max/min reveals how much per-coordinate variation the mechanism is exploiting. If max/min ≈ 1.0 throughout training, the mechanism is essentially inactive (all denominators ≈ ε_v).

### 5.7 Bit-identity gate preservation on CTRL

ARM_A (CTRL) must NOT pass `--muonh_post_ns5_precond`. When this flag is absent (default False), the code path must be identical to the current baseline — no branches entered, no new state created, no telemetry fired. The existing `muon_update` call, shape-correction scaling, and weight update must execute identically.

Verification: step-0 val loss must equal **10.82583** (EXACT). If ARM_A step-0 val differs, do NOT proceed to ARM_B/C. Report immediately and investigate.

### 5.8 Full code patch summary (conceptual diff)

```
train_gpt_simple.py changes:

1. argparse section: +3 flags (muonh_post_ns5_precond, muonh_post_ns5_beta, muonh_post_ns5_eps)
2. W&B config dict: +3 keys (same names)
3. MuonH.__init__ defaults: +3 keys (same names, same defaults)
4. MuonH.__init__ call site: +3 kwargs (args.muonh_post_ns5_precond, args.muonh_post_ns5_beta, args.muonh_post_ns5_eps)
5. MuonH.step() state init: +if block initializing "post_ns5_ema_sq"
6. MuonH.step() step logic: +if block after muon_update, before weight update
7. Training loop telemetry: +if block at telemetry_due, firing only when precond=True
```

No changes to `zeropower_via_newtonschulz5`, `muon_update`, `Muon`, `AdamW`, `MuLoCo`, or any data/model/schedule code.

---

## 6. Predicted Outcomes

**Framing:** σ_H174 ≈ 0.00088 val/loss per σ. Baseline: FFS=3025, val=3.26830. Target for improvement: FFS < 3025.

| Arm | Predicted FFS | Predicted val | vs baseline (σ_H174) | Confidence |
|-----|--------------|---------------|----------------------|------------|
| ARM_A CTRL | 3025 (EXACT) | 3.26830 | 0σ (gate) | Must match — failure is a bug |
| ARM_B POST_NS5_SLOW (β_v=0.999) | 2975–3025 | 3.267–3.268 | -1 to 0σ (null likely) | Low-moderate. Mechanism is novel but asymptotic EMA may need many steps to warm up, limiting effect in a finite ~3000-step run. |
| ARM_C POST_NS5_FAST (β_v=0.99) | 2900–3025 | 3.265–3.268 | -3 to 0σ (interesting if -2σ) | Slightly higher than ARM_B. Faster EMA may show earlier directional correction, especially during LR warmup. |

**Best case (WIN scenario):** ARM_C shows FFS ≤ 2950 (vs 3025 baseline), val ≤ 3.265, ≥ +3σ_H174 improvement. This would be a clean mechanistic WIN indicating post-NS5 tangent-space directions are non-uniform and fast adaptive scaling helps.

**Null scenario (most likely):** Both arms show FFS within ±50 of 3025, val within ±1σ_H174. Closes post-NS5 diagonal class. Informs: either NS5 already produces well-conditioned updates, or ε_v=1e-8 is too small (denominator never leaves ε regime, effectively disabled). Diagnostic telemetry will distinguish these two sub-cases.

**Catastrophic failure scenario:** ARM_B or ARM_C shows val > 3.29 or loss diverges. Cause: the post-NS5 denominator suppresses the update too aggressively early in training (EMA starts at 0, denominators start near ε_v, but `update` magnitudes may be large early, causing initial over-scaling before EMA warms up). Mitigation: add a bias-correction term `v_hat = v / (1 - beta_v**(step+1))` in the denominator. This is a follow-up, not a first-pass change.

---

## 7. Statistical Rule Check

**Single-arm statistical rule:** `(3.28 - μ) × √n ≥ 0.004`

For n=1 (single seed): requires μ ≤ 3.276.
For n=4 (four seeds): requires μ ≤ 3.278.

At ARM_C best-case prediction (val ≈ 3.265): single-run margin = (3.28 - 3.265) × √1 = 0.015 >> 0.004. Comfortably passes statistical threshold.

At ARM_B predicted null (val ≈ 3.268): single-run margin = (3.28 - 3.268) × √1 = 0.012 >> 0.004. Also passes individually, but is not an improvement over baseline.

At baseline (val = 3.26830): (3.28 - 3.26830) × √1 = 0.01170 >> 0.004. Baseline passes.

**For final benchmark claims:** If ARM_B or ARM_C beats baseline, run n=4 seeds at the same step count to confirm. Required mean val ≤ 3.278 for statistical confidence.

---

## 8. Baseline Reproduction CLI

For all arms, use the full training script with W&B args. The `train_steps` should match the baseline (the script's default as used in PR #1398 H203):

**ARM_A (CTRL) — must exactly match baseline:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/h248-post-ns5-precond-ctrl" \
  --wandb_group "h248-post-ns5-precond"
# DO NOT pass --muonh_post_ns5_precond (default False = CTRL behavior)
```

**ARM_B (POST_NS5_SLOW, β_v=0.999):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/h248-post-ns5-precond-slow" \
  --wandb_group "h248-post-ns5-precond" \
  --muonh_post_ns5_precond \
  --muonh_post_ns5_beta 0.999 \
  --muonh_post_ns5_eps 1e-8
```

**ARM_C (POST_NS5_FAST, β_v=0.99):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/h248-post-ns5-precond-fast" \
  --wandb_group "h248-post-ns5-precond" \
  --muonh_post_ns5_precond \
  --muonh_post_ns5_beta 0.99 \
  --muonh_post_ns5_eps 1e-8
```

**W&B config audit checklist per arm (verify before reporting results):**
- ARM_A: `muonh_post_ns5_precond = False`, `muonh_post_ns5_beta = 0.999`, `muonh_post_ns5_eps = 1e-8`
- ARM_B: `muonh_post_ns5_precond = True`, `muonh_post_ns5_beta = 0.999`, `muonh_post_ns5_eps = 1e-8`
- ARM_C: `muonh_post_ns5_precond = True`, `muonh_post_ns5_beta = 0.99`, `muonh_post_ns5_eps = 1e-8`

If any arm shows `muonh_post_ns5_precond` absent from the config pane, the W&B config dict was not patched correctly. Do not report results until config keys are present.

---

## 9. Follow-ups if WIN

If ARM_B or ARM_C beats baseline (FFS < 3025):

**9.1 LR joint retune (highest priority).**
Post-NS5 preconditioning changes the effective step magnitude. The existing `muonh_lr=0.018` was tuned without it. Run a 3-arm LR sweep at the winning β_v: `muonh_lr` ∈ {0.012, 0.018, 0.024}. This is standard exploitation after a mechanism WIN.

**9.2 Bias correction for EMA denominator.**
Standard Adam-style bias correction: `v_hat = v / (1 - beta_v**(step+1))`. This corrects the denominator during warmup, preventing update suppression in early steps. Add as an optional flag `--muonh_post_ns5_bias_correct` and test.

**9.3 β_v sweep if ARM_C wins over ARM_B (fast preferred).**
If fast EMA beats slow, the non-stationarity is significant. Test β_v ∈ {0.95, 0.97, 0.99} to find the optimal decay. The crossover between "tracking" and "averaging" regimes is informative about the timescale of post-NS5 RMS variation.

**9.4 Layer-wise β_v.**
Different layers (early attention blocks vs late MLP blocks) may have different post-NS5 RMS dynamics. Test per-layer β_v as a heuristic: e.g., later layers get β_v=0.99, earlier layers get β_v=0.999. Couples naturally with H244 (per-layer LR, currently in flight).

**9.5 Beyond diagonal: block-diagonal post-NS5 preconditioner.**
If diagonal post-NS5 preconditioning wins, the next tier is a low-rank or block-diagonal estimate of the post-NS5 covariance within the tangent space. This is more expensive but has a clear mechanistic motivation if the diagonal version confirms non-uniformity.

---

## 10. Research State Update

**Current best explanation for what limits progress:** The body optimizer (MuonH) produces well-conditioned updates via NS5, but may have residual per-coordinate RMS variation in the tangent space that a diagonal adaptive denominator could correct. All pre-NS5 second-order approaches are closed. All aux optimizer replacements are closed (PROGRAMME FINDING #55). MuLoCo HP+FORM is closed (PROGRAMME FINDING #54). The remaining open axes on the body optimizer are: (1) post-NS5 scaling (this experiment), (2) per-layer LR (H244 in flight), (3) outer optimizer form (H246 in flight).

**Ruled-out paths:**
- Pre-NS5 second-order preconditioning: H92, H93, H98 all NULL/NEG. Do not repeat.
- Aux optimizer replacement: H225, H237, H239, H241 all bilateral NEG. PROGRAMME FINDING #55 CLOSED. Do not repeat.
- MuLoCo inner/outer momentum FORM replacement: H229, H236 bilateral NEG. PROGRAMME FINDING #54 CLOSED. Do not repeat.
- SF-AdamW aux replacement (H239): catastrophic. Closed.
- AdEMAMix aux replacement (H237): catastrophic. Closed.

**Open uncertainties:**
1. Whether post-NS5 update directions have meaningful per-coordinate RMS variation, or whether NS5 already produces near-uniform updates.
2. Whether per-layer LR (H244) and post-NS5 preconditioning (H248) are additive — if both WIN, do they compound?
3. Whether the outer optimizer form (H246 LoCo-Adam) interacts positively or negatively with post-NS5 preconditioning.

**Stop condition for H248 specifically:**
- If both ARM_B and ARM_C are NULL (FFS within ±50 of baseline, < 2σ_H174 effect), AND diagnostic telemetry shows `post_ns5_scale_max / post_ns5_scale_min ≈ 1.0` (denominator uniformly near ε_v throughout training), CLOSE the post-NS5 diagonal preconditioning class. NS5 already produces uniform-scale tangent-space updates.
- If ARM_B and ARM_C are NULL but `post_ns5_scale_max / post_ns5_scale_min >> 1.0` (real variation but no benefit), investigate whether ε_v is too large (denominator dominated by ε) or whether the scale normalization is removing useful signal (LR needs joint retune).

---

## 11. Taste Rubric

**Research mode:** Tier shift (new mechanism class — first post-NS5 preconditioning in campaign history)

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Mechanistic grounding | 4 | Pre-NS5 closure is precisely documented (H92/H93/H98). Differential geometry motivation (tangent space of Stiefel manifold) is specific and falsifiable. Injection point is confirmed outside @torch.compile. Code patch is exact. No prior campaign instance of this mechanism. |
| Research-state value | 4 | WIN closes the post-NS5 adaptive scaling question and opens LR joint retune + bias correction + layer-wise follow-ups. NULL + uniform scale telemetry closes the class cleanly. NULL + non-uniform scale telemetry identifies a new sub-problem (ε or LR confound). Three distinct outcomes all sharply update the research map. |
| Execution value | 3 | 3-arm sequential chain ~5.1h, well within 8h budget. Diagnostic telemetry enables causal interpretation of any result. Implementation requires no new dependencies. Slight ding: β_v values were chosen heuristically (borrowing from aux optimizer tuning); a bias-correction sweep might have been a cleaner second arm if ε dominance is expected. Overall high information per compute unit. |

**Overall: 11/12. Strong candidate for next assignment.**

---

## 12. Confidence Assessment

**Mechanistic grounding: Strong.**
The pre-NS5 closure is well-documented across 3 independent null results (H92, H93, H98). The injection point outside @torch.compile is confirmed by code reading. The differential geometry connection (tangent space of Stiefel manifold) is mathematically precise, not speculative analogy.

**Probability of WIN: Low-moderate (30-40%).**
Most new mechanism classes in this campaign have been null (95 NULL/NEG across 43 classes). However, the post-NS5 regime is genuinely unexplored and has a structurally distinct mechanism. The base rate of null for new mechanism classes in this campaign is ~90%. The mechanism has stronger-than-average prior motivation (pre-NS5 closed, tangent-space geometry argument, random matrix theory prediction of non-uniform singular vector weights). Estimated WIN probability 30-40%.

**Diagnostic value regardless of outcome: Very high.**
The telemetry (scale_rms, scale_min, scale_max) will directly reveal whether the mechanism is active or dormant. A null result with good telemetry is highly informative — it closes the class cleanly rather than leaving ambiguity about whether the implementation was correct.

**External evidence: Moderate.**
Post-NS5 preconditioning has not been tested in the literature on orthogonalizing optimizer variants. The closest analogues (Riemannian adaptive gradient methods, Riemannian Adam on Stiefel manifolds) are theoretically motivated but have not been validated in this exact setting. The idea is grounded but unvalidated outside this campaign.
