# Fresh Hypothesis — frieren — 2026-05-31
# AdamW Bias/LN-Gain Subgroup Separate LR Multiplier

---

## Slug

`bias-ln-lr-scale`

## One-sentence summary

Assign a dedicated, lower LR multiplier to the AdamW subgroup containing only biases and LayerNorm/RMSNorm gains, reducing oscillation in these scale-setting parameters during cooldown without touching the Muon/NS5/SOAP pipeline.

---

## Motivation and Mechanism

The mandatory stack routes weight matrices through Muon (with NS6 orthogonalization and SOAP preconditioner for attention). Biases, LN gains, embedding, and lm_head parameters travel through AdamW as a single group with one shared LR schedule. This bundling is convenient but ignores a well-documented fact: biases and normalization gains have systematically lower Hessian sharpness than weight matrices throughout pre-training.

The Sharpness Disparity Principle (Wang et al., ICML 2025) shows that different transformer parameter families exhibit different curvature early in training, and that assigning per-block/per-group learning rates based on this curvature difference achieves up to 2x speedup on GPT-2 and LLaMA pre-training. Their key finding: scale-setting parameters (those controlling output magnitude rather than direction) can tolerate much lower LR than direction-setting weight matrices, and forcing them onto the same schedule causes the weight LR to be a compromise that is too aggressive for biases and too conservative for weights.

In our stack specifically:
- Muon parameters: weight matrices in attn and MLP, normalized by NS6 before the update, so their effective step size is already bounded by orthogonality.
- SOAP parameters: attention weight matrices, further preconditioned.
- AdamW group: biases, LN gains, embedding rows, lm_head. These have no orthogonalization, and their curvature is much flatter. Applying the same LR that's tuned for embeddings (which are high-rank, high-sharpness) to biases (low-dimensional, flat loss landscape) over-drives the bias subgroup.

The hypothesis: splitting the AdamW group into two subgroups — (1) embedding + lm_head at the current LR, and (2) biases + LN gains at `lr_bias_scale * current_lr` where `lr_bias_scale ≈ 0.2–0.4` — will reduce oscillation in the normalization and bias parameters during the critical cooldown phase, allowing the main LR to be slightly more aggressive, compressing FFS.

This is structurally orthogonal to every closed family and all 7 in-flight axes:
- Not a Muon/NS-iter change (touches AdamW group only)
- Not a SOAP change (doesn't touch attention preconditioner)
- Not a polar approximator variant
- Not label smoothing, trajectory averaging, depth-init, or WD-schedule
- Not cooldown shape (shape is unchanged, just the magnitude for one subgroup)
- Not LR-MLP (that's the Muon MLP group; this is AdamW biases/gains)

---

## Published Precedent

**The Sharpness Disparity Principle in Transformers for Accelerating Language Model Pre-Training**
Wang et al., ICML 2025
- Demonstrates that different transformer blocks/parameter groups have different sharpness (Hessian trace) throughout training
- Proposes assigning per-block LRs inversely proportional to sharpness
- Reports up to 2x speedup on GPT-2 medium, LLaMA 3B pre-training
- Key finding: normalization/bias parameters have 3-10x lower sharpness than weight matrices in early training

Supporting work:
- **muP (Tensor Programs V, Yang et al., 2022):** Different parameter types require different LR scaling; biases and gains scale differently than weights under width scaling. While muP targets width scaling, the principle of per-type LR separation is the same.
- **Adam vs. AdamW on biases (Zhang et al., 2019):** Bias terms often benefit from lower effective LR because their gradients are more consistent (less noise) than weight matrices, which already suggests a lower ideal LR.
- **LLaMA 3 tech report (Meta, 2024):** Uses separate LR for embedding parameters, motivating the same split for biases/gains.

---

## Implementation

### Change surface: ≤ 30 LOC

In `train.py` (or wherever optimizer groups are assembled), split the current AdamW group into two:

```python
# BEFORE (single AdamW group):
# adamw_params = biases + ln_gains + embedding + lm_head
# optimizer = ... [muon_group, adamw_group]

# AFTER (two AdamW groups):
scale_params = []   # biases + LN/RMSNorm gains
embed_params = []   # embedding + lm_head

for name, p in model.named_parameters():
    if not p.requires_grad:
        continue
    if any(excluded in name for excluded in muon_excluded_names):
        # further split: scale vs embed
        if p.ndim == 1 and ('bias' in name or 'weight' in name and 'norm' in name.lower()):
            scale_params.append(p)
        else:
            embed_params.append(p)

# lr_bias_scale is a new CLI arg, default 0.3
adamw_scale_group = {
    'params': scale_params,
    'lr': base_lr_scalars * lr_bias_scale,   # reduced
    'betas': (0.9, 0.95),
    'weight_decay': 0.0,   # biases/gains should NOT be weight-decayed
}
adamw_embed_group = {
    'params': embed_params,
    'lr': base_lr_scalars,   # unchanged
    'betas': (0.9, 0.95),
    'weight_decay': wd,
}
```

Add `--lr_bias_scale` CLI argument (float, default 1.0 = no change = exact baseline).

The LR scheduler must then update both groups independently, scaling each by the same cosine cooldown factor. This is standard: most schedulers iterate over all param groups.

### Key gotcha: WD on bias/gain

LN gains and biases should have `weight_decay=0.0` regardless. If the current codebase already zeroes WD for these (common), no change needed there. If it applies global WD to all AdamW params, this split is an opportunity to fix that too — but it should be a separate flag to isolate the effect.

### Key gotcha: param group identification

The split must correctly identify LN/RMSNorm gains vs. other 1D tensors (e.g., some head biases). Use `'norm' in name.lower()` or check the module class. A wrong split (including embedding rows in the scale group) would conflate two effects. Log the param counts for each group in the run summary.

### Key gotcha: LR schedule update

When calling `scheduler.step()`, verify all three groups (muon, adamw_scale, adamw_embed) have their LR updated. If the scheduler was built with the optimizer's param_groups list, adding a group after construction may be silently ignored by some schedulers. Reconstruct or patch the scheduler after adding the group.

---

## Experimental Cells

### Cell A — Control (lr_bias_scale=1.0)
Baseline reproduction. Confirms the split itself (even at scale=1.0) introduces no regression. Should match μ_4(FFS_ema) = 2912.5 ± σ = 25.

CLI addition: `--lr_bias_scale 1.0`
Expected FFS: ~2912 (within 1σ of baseline)
Gate: must be within 2σ before proceeding.

### Cell B★ — lr_bias_scale=0.3
The primary bet. Biases and LN gains receive 30% of the main AdamW LR.

CLI addition: `--lr_bias_scale 0.3`
Expected FFS: 2800–2870 (1.5–4% improvement)
Gate: FFS < 2887 (1σ below baseline) to declare signal.

### Cell C — lr_bias_scale=0.1
More aggressive reduction. Tests whether the gains from lower bias/gain LR saturate early.

CLI addition: `--lr_bias_scale 0.1`
Expected FFS: 2820–2880

### Cell D — lr_bias_scale=0.5
Conservative reduction. If B★ is too aggressive and causes underfitting in normalization params.

CLI addition: `--lr_bias_scale 0.5`
Expected FFS: 2860–2900

### Recommended run order

Start with A (control) and B★ in parallel. If B★ beats baseline, run C and D to find the optimum. If B★ is within 1σ of baseline (no signal), close after A+B.

---

## Decision Tree

```
A (control, lr_bias_scale=1.0)
├── FFS within 2σ baseline → split is neutral, proceed
│   B★ (lr_bias_scale=0.3)
│   ├── FFS < 2887 (signal) → MERGE B★, run C and D to bracket optimum
│   │   C (0.1): if better → new best; if worse → 0.3 is optimum
│   │   D (0.5): if better → bracket between 0.3 and 0.5; if worse → 0.3 confirmed
│   └── FFS ≥ 2887 (no signal) → CLOSE, bias/LN-gain LR is not a bottleneck
└── FFS > 2σ above baseline → split has a bug (check param assignment); debug before B★
```

---

## Pre-mortem: Why This Might Not Work

1. **The bias/LN-gain LR is already not the bottleneck.** The current `lr_scalars=0.03` may already be conservative enough that further reduction adds no value. The Sharpness Disparity work was measured on standard AdamW for all parameters; our stack already separates Muon from AdamW, so the disparity within the AdamW group may be smaller.

2. **Underfitting in normalization.** If LN gains need to adapt quickly during early training (before the ramp_down WD schedule kicks in), reducing their LR could slow convergence in the first 1000 steps, pushing FFS in the wrong direction.

3. **Interaction with depth_init_mode=musoft.** The musoft init sets specific LN gain values; a lower LR might slow their adaptation away from init, conflicting with the intended effect of the init strategy.

4. **Param identification bugs.** If the split incorrectly classifies some weight matrices as scale params (or vice versa), the effective LR for those parameters changes in an uncontrolled way.

---

## Stop Conditions

- Close immediately if Cell A (control, lr_bias_scale=1.0) shows FFS > baseline + 3σ (split introduces a bug).
- Close after A+B★ if B★ FFS ≥ 2887 (no measurable signal, not worth bracketing).
- Merge and follow up with C/D if B★ FFS < 2887 (signal confirmed).

---

## Mandatory Stack Preservation

All runs must include:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03
--depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

The `--lr_scalars 0.03` flag controls the base LR for the AdamW group. The new `--lr_bias_scale` multiplier applies on top of this: effective bias/LN-gain LR = `0.03 * lr_bias_scale`.

---

## References

1. Wang et al. "The Sharpness Disparity Principle in Transformers for Accelerating Language Model Pre-Training." ICML 2025.
2. Yang et al. "Tensor Programs V: Tuning Large Neural Networks via Zero-Shot Hyperparameter Transfer." NeurIPS 2022.
3. Loshchilov & Hutter. "Decoupled Weight Decay Regularization." ICLR 2019. (AdamW — motivates separate WD treatment for bias/gain.)
4. Meta AI. "The Llama 3 Herd of Models." 2024. (Separate embedding LR.)
