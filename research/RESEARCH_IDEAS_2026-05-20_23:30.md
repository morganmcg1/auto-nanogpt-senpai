# Research Ideas — 2026-05-20 23:30 — Frieren Next Assignment

Generated after closing body-Muon rank-1 mean transformation class in both sign directions (#553 subtraction NULL, #588 amplification NULL). The mechanistic lesson from those closures: NS whitening actively uses singular structure, so the safe transformation class is element-wise operations that compress outliers without disrupting the top singular vectors.

---

## Hypothesis 1 (Bold): Tanh-Squash Pre-NS Gradient Compression

**Mechanism.** Apply element-wise `g_sq = scale * tanh(g / scale)` to the body-Muon gradient before the Newton-Schulz polar step, where `scale` is a per-tensor rolling median or a fixed fraction of the gradient's Frobenius norm. Tanh-squash is a smooth, bounded compression that eliminates large-magnitude outlier entries while leaving the direction (and thus the top singular structure) nearly intact for small-to-moderate gradients. Unlike rank-1 mean operations (which inject or remove a structured additive bias across the entire column space), tanh-squash acts entry-wise and does not add or remove any particular singular direction — it only soft-clips the amplitude.

**Why safe relative to #553/#588.** The failure mode of both closed experiments was that the rank-1 mean is the dominant singular vector fed into NS; any rank-1 additive perturbation changes that vector. Tanh-squash preserves the sign pattern and relative magnitude ordering of all entries, so the top singular direction is unchanged for inputs where `|g_ij| << scale`. Only outlier entries are compressed. In the limit `scale → ∞`, it reduces to identity.

**Expected signal direction.** Heavy-tailed gradient distributions are a known source of NS iteration instability (the cubic approximation is best-conditioned near the unit circle). Squashing outliers should tighten the effective spectral radius entering NS and improve per-step quality, yielding Δsr < 0 (fewer steps to target). The effect is most likely visible in the first 500 steps where gradient variance is highest.

**Implementation complexity.** ~8 lines in the PMuon forward pass, before the NS call. `scale` is either a fixed constant (e.g. 1.0 in gradient L2-normalized space) or a rolling median tracked with a 1D EMA. Start with fixed scale.

**Rationale.** Kaggle-style empirical precedent: tanh normalization of gradient updates is used in Lion (Chen et al 2023) for exactly this reason — bounded update magnitudes without hard clipping discontinuities. Lion applies tanh via `sign(m)` to the full momentum; here we apply the smooth form to the pre-NS gradient. This is orthogonal to all 35 closed axes and untested on this stack.

**Arm structure.**
- Arm A: `scale = 0.5 * frob_norm(g)` per tensor (adaptive, moderate squash)
- Arm B: `scale = 1.0 * frob_norm(g)` per tensor (adaptive, mild squash)

Both arms use EMA-tracked norm with β=0.95 to avoid single-step scale instability. Run single seed first; if Arm A/B both show Δsr > +50 at step 500, abandon early.

---

## Hypothesis 2 (Medium): Winsorization Pre-NS (Clip to k·Median)

**Mechanism.** Hard-clip each gradient matrix entry to `[-k·median(|g|), +k·median(|g|)]` before NS, where the median is computed per-tensor. This is the classical robust statistics approach to outlier removal (Winsorization). Like tanh-squash, it is entry-wise and preserves the top singular vector as long as outliers are a minority of entries. Unlike tanh-squash, it introduces a hard threshold and requires computing a running per-tensor median.

**Expected signal direction.** Should have similar motivation to Hypothesis 1 but with a harder boundary. May be more effective if gradient outliers are sparse and extreme (kurtosis >> 3), or less effective if outliers are dense (clipping many entries changes singular structure). Expect Δsr 0 to -50 if outliers exist; risk of NULL or slight regression if distribution is already well-behaved.

**Implementation complexity.** ~5 lines. Per-tensor `torch.median(g.abs())` plus a clamp. Main cost: median computation adds ~2-3% step time. Can use approximate median (sorted-percentile from random 256-sample) to reduce overhead.

**Rationale.** Direct analogue of gradient clipping but relative to the local distribution rather than a global fixed threshold. The GC amplification experiment (#588) showed that amplifying the mean is harmful; Winsorization does the opposite — it attenuates the tails without touching the mean. Closes a clean axis distinct from tanh-squash (hard vs. soft outlier treatment).

**Arm structure.**
- Arm A: `k = 3.0` (moderate clip, allows 3× median outliers through)
- Arm B: `k = 6.0` (permissive clip, only extreme outliers removed)

Use per-tensor running median with EMA β=0.99 rather than per-step exact median for speed.

---

## Hypothesis 3 (Medium): Per-Block Gradient L2 Normalization Pre-NS

**Mechanism.** Before NS, normalize each transformer block's gradient by dividing by `||g||_F + ε`, where the norm is computed at the whole-block level (all parameters in a single TransformerBlock stacked into one flat vector, then norm computed over that). This equalizes the "energy" entering NS across all depth levels, regardless of how deep the block is or whether it received large or small backprop signal.

**Why different from closed axes.** Per-type LR partitions (closed #368/#376) scaled the learning rate *after* NS by parameter type. This operates *before* NS on the gradient magnitude at the block level — it changes what NS sees, not what scale it outputs. No overlap with any closed axis.

**Expected signal direction.** In deep transformers, late blocks often receive larger gradient norms than early blocks during early training due to residual stream accumulation. Normalizing per-block before NS removes this systematic depth-bias from the spectral computation. If this bias is harmful, expect Δsr -25 to -75 with most gain in early steps. If the depth bias is actually useful signal, expect NULL.

**Implementation complexity.** ~10 lines. Requires grouping parameters by block index (already accessible via named_parameters with block index in the name), computing per-block Frobenius norm, then dividing. Can be applied within the existing per-group loop in PMuon.

**Rationale.** Connects to the Layer-wise Adaptive Rate Scaling (LARS) and LAMB literature: both normalize per-layer before applying the update. The difference is those methods normalize the *update* post-optimizer; this normalizes the *gradient* pre-NS. The pre-NS position is novel in this codebase and untested.

**Arm structure.**
- Arm A: Per-block normalization applied to all body-Muon parameters
- Arm B: Per-block normalization applied only to MLP sublayers (attn blocks excluded, as attn gradients have different structure)

---

## Hypothesis 4 (Medium-Bold): Schedule-Free Optimizer on Aux (Defazio 2024)

**Mechanism.** Replace aux AdamW's explicit LR schedule (warmup + WSD cooldown) with the Defazio-Orabona schedule-free formulation: maintain a Polyak-Ruppert EMA of iterates (`z`) alongside the usual moment states, and use the weighted average `x = (1-c)*z + c*w` as the model's inference weights, where `c` is a schedule-free interpolation coefficient. This eliminates the need for any cooldown phase on the aux side entirely — the averaging *is* the cooldown.

**Expected signal direction.** Aux parameters (embed, lm_head, scalars) contribute meaningfully to early loss shaping. If the WSD cooldown is suboptimal for aux (different dynamics than body), schedule-free EMA may find a better convergence path. The active #606 (fern) is testing shorter cooldown fractions on the *global* schedule; this tests removing the cooldown concept from aux entirely, which is orthogonal. If #606 finds that shorter cooldown hurts, schedule-free aux would still be valid (it uses implicit averaging rather than explicit decay). Expected Δsr -25 to -100 if aux cooldown timing is suboptimal; NULL if aux is already well-converged before cooldown starts.

**Implementation complexity.** ~25 lines. PyTorch implementation of schedule-free Adam exists (pytorch-optimizer, Defazio 2024 repo). Key hyperparameters: `r` (EMA decay for z-update, default 0), `weight_lr_power` (default 2.0). The standard recipe uses `lr` matching the original optimizer's peak lr. Must store FP32 EMA state for aux to avoid BF16 rounding on embed weights (per memory note on β≥0.996 precision hazard — less critical here at c≈0.99 but worth being safe).

**Rationale.** Four consecutive NULL/NULL closures on aux update-rule mechanisms (AdaBelief, NadamW, AdEMAMix, AMSGrad) establish that changing the *update direction formula* for aux does nothing — aux gradients are noise-dominated and the optimizer differences are irrelevant. Schedule-free changes neither the direction formula nor the scalar step size; it changes the *trajectory averaging structure*. This is a different axis entirely and has external evidence of helping in language model training (Defazio 2024, Kimi-k1.5 uses schedule-free Adam in RLHF stage).

**Arm structure.**
- Arm A: Schedule-free Adam on aux only, body-Muon unchanged. `lr=0.025` (matches current scalar_lr), `weight_lr_power=2.0`, `r=0`
- Arm B: Same, but `weight_lr_power=1.0` (linear rather than quadratic averaging weight ramp)

Note: this requires aux to run without any explicit LR decay. The body-Muon + WSD schedule continues unchanged. The aux optimizer simply accumulates EMA iterates for its own convergence.

---

## Priority Ordering for Frieren Assignment

1. **Hypothesis 1 (tanh-squash)** — most novel mechanism, cleanest axis, explicit connection to Lion precedent, highest chance of revealing whether NS conditioning benefits from outlier removal
2. **Hypothesis 3 (per-block grad norm)** — low implementation risk, closes a clean untested axis at the block level, orthogonal to all prior partitioning work
3. **Hypothesis 4 (schedule-free aux)** — bold structural change, well-supported externally, closes the "aux schedule shape" axis orthogonal to the four dead update-rule axes
4. **Hypothesis 2 (Winsorization)** — close second to tanh-squash, run as follow-up if tanh-squash shows signal at one scale but not another

Assign Hypothesis 1 first. If early (step 200) Δsr > +75 on both arms, consider early-stopping and moving to Hypothesis 3 in parallel.
