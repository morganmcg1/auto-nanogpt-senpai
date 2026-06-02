# Research Hypothesis: ZCA Diagonal Gradient Whitening Pre-NS5
**For: g1r5-alphonse**
**Date: 2026-06-02 02:25Z**
**Researcher: deep-research-agent**

---

## 1. Slug

`zca-diag-grad-whitening-pre-ns5`

---

## 2. Mechanism

Newton-Schulz 5 orthogonalizes a gradient matrix G by iteratively approximating
the polar factor U such that G ≈ U Σ Vᵀ. The convergence speed and quality of
this five-step polynomial depend on the conditioning of G — specifically, the
distribution of singular values. When the column-wise variances of G differ by
orders of magnitude (some columns have large RMS, others small), the Frobenius
norm used to normalize G into the [-1.5, 1.5] interval that NS5 requires can be
dominated by a few high-variance columns, leaving low-variance columns
effectively zeroed out before orthogonalization begins.

ZCA (Zero-phase Component Analysis) diagonal whitening equalizes per-column
variance before NS5 sees the gradient. The implementation maintains a running
exponential moving average of the per-column squared gradient values. Before
calling `zeropower_via_newtonschulz5`, each column j of the gradient G is
divided by sqrt(v_j + eps), where v_j is the EMA of G[:,j]^2. This centers the
singular value distribution of the input to NS5 without introducing a rotation
(unlike full covariance ZCA), preserving the gradient's column directions while
equalizing their magnitudes.

The hypothesis is that more uniform singular value spread at NS5 input improves
the effective rank and quality of the resulting orthogonal factor, leading to
better per-step optimizer updates and therefore fewer steps to reach the 3.28
target. Concretely: the whitened gradient has a more favorable condition number
for the Newton-Schulz polynomial, so the five fixed iterations produce a closer
approximation to the true polar factor.

---

## 3. Novelty Proof

The following `gh search prs` commands were run with zero results on
`morganmcg1/modded-nanogpt-senpai`, label `auto-nanogpt-1gpu-r5`:

```
gh search prs --repo morganmcg1/modded-nanogpt-senpai \
  --label auto-nanogpt-1gpu-r5 "gradient whitening"
# → No results

gh search prs --repo morganmcg1/modded-nanogpt-senpai \
  --label auto-nanogpt-1gpu-r5 "ZCA"
# → No results

gh search prs --repo morganmcg1/modded-nanogpt-senpai \
  --label auto-nanogpt-1gpu-r5 "zca"
# → No results
```

The following mechanistically adjacent PRs are **distinct** from this proposal:

- **PR #890** (per-column scalar normalization): Divides each column by its
  current Frobenius norm — a one-shot, non-EMA, non-whitening normalization.
  This proposal uses a running second-moment EMA per column element (not per
  column as a whole), making it a proper diagonal covariance whitening step.

- **PR #1651** (per-row Frobenius normalization): Operates on rows, not
  columns; normalizes row L2 norms, not per-element running variance. Different
  axis and different estimator.

- **PR #1564** (SOAP Gram trace normalization): Operates on SOAP's Kronecker
  factor Gram matrix inside the SOAP preconditioner, not on the raw Muon
  gradient. Mechanistically unrelated.

- **PR #123** (activation-covariance right-preconditioner, alphonse's prior):
  Uses activation statistics from the forward pass to right-precondition the
  gradient. This proposal uses only gradient statistics (no activations) and
  applies them via diagonal whitening, not right-multiplication by a full
  covariance inverse.

- **"whitening" search**: Returned only PR #1564, which is the SOAP Gram trace
  normalization. Zero overlap with ZCA/diagonal gradient whitening pre-NS5.

---

## 4. Memory-Rule Compliance

Checking all 7 banned hypothesis types from the session:

| Rule | Check |
|------|-------|
| No AdamW aux hyperparameter schedule of any kind | PASS — does not touch AdamW eps, β₁, β₂, or WD |
| No μ ramp at progress < 0.30 | PASS — does not modify μ schedule at all |
| No NS5 ε modifications | PASS — NS5 internal ε unchanged; this adds an external whitening step before NS5 |
| No NS5 iteration count modifications | PASS — NS5 still runs exactly 5 iterations |
| No cooldown freeze semantics on EMA/Polyak/SF | PASS — no iterate averaging, no LR × weight accumulation |
| No logit cap value or schedule | PASS — does not touch lm_head or logit scaling |
| No per-aux-group clip variants | PASS — operates on Muon body matrices, not aux group clipping |

Memory entries checked:
- `sgld_annealed_noise_pre_ns_family_neg_at_r5.md`: covers additive pre-NS
  gradient modifiers (SGLD noise, GC, μ cooldown, GE-SAM) — multiplicative
  column whitening is not an additive modifier, distinct mechanism.
- `ns5_absorbs_2d_weight_init_perturbations_at_r5.md`: covers structural 2D
  weight init, post-NS5 per-block depth-LR scaling, and pre-NS5 additive
  gradient modifiers. Multiplicative whitening is not a structural init or
  additive modifier.
- `ns5_internal_eps_irrelevant_at_r5_gradient_scale.md`: confirms NS5 internal
  ε is irrelevant — this proposal does not change NS5 internal ε.
- `adamw_aux_tetrad_fully_closed_at_r5.md`: confirms AdamW aux tetrad closed —
  this proposal does not touch AdamW.
- `warmup_mu_ramp_axis_closed_at_r5.md`: confirms μ schedule axis closed — this
  proposal does not modify μ.

**Result: All memory rules satisfied. Hypothesis is eligible.**

---

## 5. Implementation Patch (≤ 25 LOC)

The core change is in the `Muon` optimizer's `step()` method in
`records/track_3_optimization/train_gpt_simple.py`. The relevant section is
where `zeropower_via_newtonschulz5` is called for each Muon parameter group.

```python
# --- ADD: ZCA diagonal whitening state and application ---
# In the Muon.step() loop, just before the NS5 call:

# Initialize per-param whitening EMA on first step
if 'zca_v' not in state:
    state['zca_v'] = torch.zeros_like(grad)

# Hyperparameter: zca_beta (default 0.99) — set via optimizer init
zca_beta = group.get('zca_beta', 0.99)

# Update running column-wise second moment
state['zca_v'].mul_(zca_beta).addcmul_(grad, grad, value=1.0 - zca_beta)

# Apply diagonal whitening: divide elementwise by sqrt(v + eps)
# Use a small eps to avoid division-by-zero on cold columns
zca_eps = group.get('zca_eps', 1e-8)
grad_w = grad / (state['zca_v'].sqrt() + zca_eps)

# Replace grad with whitened version for NS5
# (original grad is not modified; grad_w is local)
update = zeropower_via_newtonschulz5(grad_w, steps=group.get('ns_iter', 5))
```

Total new lines: ~12 (excluding comments). The whitened `update` replaces the
`grad` argument that was previously passed directly to `zeropower_via_newtonschulz5`.

**Memory overhead**: Each Muon parameter gets one additional tensor of identical
shape for `zca_v`. Body matrices are [768, 768] or [768, 3072] — at bf16,
roughly 1.1 MB total across all body matrices. Negligible.

**Note on rescaling**: After whitening, the gradient has unit per-element
variance. NS5 normalizes by Frobenius norm internally, so no explicit rescale is
needed before NS5. The output update from NS5 is LR-scaled identically to
baseline.

---

## 6. Experimental Cells

All cells use the mandatory baseline stack. The `--mu_cooldown_target 0.80`
default is already baked in (PR #2071).

### Cell A — Debug / sanity (200 steps, 1 seed)
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --zca_beta 0.99 --zca_eps 1e-8 \
  --train_steps 200 \
  --wandb_name "alphonse/zca-diag-debug-200" \
  --wandb_group "zca-diag-grad-whitening-pre-ns5"
```
**Pass criteria**: finite loss throughout, `train/grad/global_norm` stays below
10× baseline at step 200, `val/loss` plausible (< 3.60 at step 200).

### Cell B — β sweep (500 steps, 3 seeds × 3 β values = 9 runs)
Test `zca_beta` ∈ {0.95, 0.99, 0.999}. The 0.95 case adapts fastest (high
discount, recent gradient statistics dominate), 0.999 is a very slow-moving
prior. Baseline FFS_ema at 500 steps is not informative (baseline needs ~2875
steps), so rank by `val/loss` at step 500.

```bash
for BETA in 0.95 0.99 0.999; do
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 \
    --wd_schedule ramp_down --lr_scalars 0.03 \
    --depth_init_mode musoft --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --zca_beta $BETA --zca_eps 1e-8 \
    --train_steps 500 \
    --wandb_name "alphonse/zca-diag-beta${BETA}-500" \
    --wandb_group "zca-diag-grad-whitening-pre-ns5"
done
```
**Selection rule**: pick β with lowest mean `val/loss` at step 500. If any β
diverges (loss > 4.0) at step 200, kill that run.

### Cell C — Confirmation at full steps (n=2, best β from Cell B)
```bash
for SEED in 1 2; do
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 \
    --wd_schedule ramp_down --lr_scalars 0.03 \
    --depth_init_mode musoft --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --zca_beta <BEST_BETA> --zca_eps 1e-8 \
    --wandb_name "alphonse/zca-diag-confirm-seed${SEED}" \
    --wandb_group "zca-diag-grad-whitening-pre-ns5"
done
```
**Pass criteria**: mean FFS_ema ≤ 2875 across both seeds. If mean FFS_ema <
2862.5, proceed to Cell D.

### Cell D — Statistical claim (n=4, mandatory if Cell C passes merge gate)
```bash
for SEED in 1 2 3 4; do
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 \
    --wd_schedule ramp_down --lr_scalars 0.03 \
    --depth_init_mode musoft --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --zca_beta <BEST_BETA> --zca_eps 1e-8 \
    --wandb_name "alphonse/zca-diag-n4-seed${SEED}" \
    --wandb_group "zca-diag-grad-whitening-pre-ns5"
done
```
**Statistical claim check**: `(3.28 - mu_4) * sqrt(4) >= 0.004` → requires
mean val/loss ≤ 3.278.

---

## 7. Decision Tree

```
Cell A (200 steps, debug)
├── FAIL (non-finite loss or grad norm > 10×) → 
│     Check zca_eps; if ZCA denominator collapsing, increase zca_eps to 1e-6.
│     If still failing, add a grad clamp: grad_w = grad_w.clamp(-10, 10) after whitening.
│     If still failing → KILL (mechanism broken, NS5 cannot tolerate whitened gradient).
└── PASS → proceed to Cell B

Cell B (500 steps, β sweep)
├── All 3 β values converge to val/loss ≥ baseline + 0.005 → 
│     Mechanism is not alive at 500 steps. But do NOT kill yet: NS5 benefits
│     may only manifest near convergence (late cooldown). Proceed to Cell C
│     with β=0.99 as default.
└── At least one β has val/loss < baseline_500 → pick best β → proceed to Cell C

Cell C (full steps, n=2, best β)
├── Both seeds FFS_ema ≤ 2875 AND mean FFS_ema ≤ 2862.5 → 
│     Strong signal. Proceed to Cell D.
├── Mean FFS_ema ≤ 2875 but > 2862.5 →
│     Marginal. Report as FFS-NEUTRAL unless val/loss shows improvement.
│     Option: rerun with LR sweep (try lr_mlp 0.06–0.07) before declaring neutral.
└── Mean FFS_ema > 2875 (worse than baseline) → KILL.
     Label FFS-NEG if strictly worse; FFS-NEUTRAL if at attractor 2875.

Cell D (n=4 statistical claim)
├── (3.28 - mu_4) * sqrt(4) >= 0.004 → MERGE
└── Fails statistical rule → REQUEST CHANGES: try lr_mlp retune with whitening
    active, or reduce zca_beta to 0.95 for faster adaptation.
```

---

## 8. Predicted Outcomes

**Optimistic case (probability ~25%)**: NS5 is conditioning-sensitive enough
that diagonal whitening reduces variance in the singular value distribution of
the input, giving the five-step polynomial a materially better starting point.
Expected FFS_ema gain: 25–75 steps (1–3% improvement), enough to cross the
merge gate.

**Null case (probability ~60%)**: NS5's internal Frobenius normalization already
handles the dominant effect of column variance imbalance. The whitened gradient
produces similar-quality orthogonal factors. FFS_ema attractor: 2875 (canonical
FFS-NEUTRAL). This is the expected outcome based on the NS5 absorption pattern
observed across adjacent pre-NS5 modifier experiments.

**Negative case (probability ~15%)**: ZCA whitening amplifies gradient noise in
low-signal columns (those with very small running variance), destabilizing NS5
input. FFS_ema > 2875 or non-finite loss. Early kill from Cell A.

**Mechanism test value regardless of outcome**: This experiment directly tests
whether NS5 is sensitive to its input's singular value distribution. A null
result (+/- 0 steps at attractor) closes the gradient-conditioning-for-NS5
axis. A negative result confirms the NS5 absorption pattern extends to
multiplicative gradient rescaling. Either result adds to the closed-axis
inventory.

---

## Literature Support

Diagonal whitening as gradient preprocessing has roots in the AdaGrad/RMSprop
literature (Duchi et al. 2011; Tieleman & Hinton 2012), where per-element
second moment estimates are used to scale gradient updates. The ZCA variant
(Bell & Sejnowski 1997, as applied to activations in deep learning by Desjardins
et al. 2015 "Natural Neural Networks") generalizes this to full covariance
equalization; the diagonal version is the computationally tractable
approximation.

The application specifically to the input of a polar-factor approximation
(NS5) is novel. The closest adjacent work is Shampoo (Gupta et al. 2018), which
applies Kronecker-factor-based preconditioning before gradient updates — but
Shampoo does not compose with a downstream Newton-Schulz orthogonalization step.
SOAP (Vyas et al. 2023) is the modern descendant and is already part of the
baseline stack; this proposal adds a lightweight diagonal stage before the
NS5 body-matrix path.

---

## Summary

**Hypothesis**: Apply diagonal ZCA whitening (running per-column second moment
EMA) to Muon body matrix gradients immediately before NS5 orthogonalization.
Test `zca_beta` ∈ {0.95, 0.99, 0.999}. Primary question: does equalizing
column-wise gradient variance improve NS5 orthogonalization quality and
reduce FFS_ema below 2875?

**Why this might help**: NS5's five-step polynomial is applied after Frobenius
normalization of the gradient. When column variances differ substantially, the
normalization is dominated by high-variance columns; ZCA pre-normalization
creates a more uniform singular value distribution for NS5 to orthogonalize.

**Expected outcome**: 60% null (FFS-NEUTRAL at 2875 attractor), 25% positive
(FFS_ema < 2862.5), 15% negative (early kill from Cell A).

**Research state value**: Either way, this cleanly closes or opens the
gradient-conditioning-for-NS5 axis with a direct mechanism test.
