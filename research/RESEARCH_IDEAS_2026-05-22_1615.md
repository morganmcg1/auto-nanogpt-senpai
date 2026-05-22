# Research Ideas — 2026-05-22 16:15

Generated for student g1r1-fern (idle after PR #777 closed NULL).
Current baseline: PR #737, sr=2925, val=3.266926 (n=2).
Win threshold: sr ≤ 2912 OR (sr=2925 AND val < 3.266926).
In-flight (must not duplicate): #796, #780, #778, #741, #802, #803, #814.

---

## H1 (TOP PRIORITY): SOAP-style Adam-in-eigenbasis for body-Muon

### Mechanism

SOAP (Vyas et al., OPT 2024) shows that Shampoo is equivalent to Adafactor in the eigenbasis of its Kronecker-factor preconditioner, and that running full Adam (not Adafactor) in that same eigenbasis strictly dominates — because Adam's per-coordinate adaptive step survives the rotation whereas Adafactor's gradient scaling does not.

PMuon already computes the eigenbasis of L_cov and R_cov via `torch.linalg.eigh` inside `matrix_neg_power`. The SOAP insight is to maintain Adam's `m1` (first moment) and `m2` (second moment) in the rotated frame, apply the Adam update there, and rotate back. This replaces the NS polar-map step entirely.

The key difference from the existing PMuon stack: NS produces a unit-matrix-norm update (pure directional signal, magnitude from u/w-floor). SOAP-in-eigenbasis produces an adaptive-step update in the same eigen-space, where the per-coordinate second moment absorbs curvature variation not captured by the symmetric preconditioner. This should reduce the sensitivity to the u/w-floor threshold and improve late-cooldown performance where NS precision degrades.

### Implementation

In `pmuon_update` add two new state tensors per Muon param: `m1_rot` (shape=grad.shape, float32) and `m2_rot` (shape=grad.shape, float32). After computing `L_neg`, `R_neg` and the preconditioned gradient `m_pre`:

```python
# Project gradient into eigen-frame
g_rot = (eigvecs_L.T @ g32) @ eigvecs_R   # shape (d_out, d_in)

# Adam update in rotated frame
m1_rot.mul_(beta1).add_(g_rot, alpha=1 - beta1)
m2_rot.mul_(beta2).addcmul_(g_rot, g_rot, value=1 - beta2)
bc1 = 1 - beta1 ** step
bc2 = 1 - beta2 ** step
adam_rot = (m1_rot / bc1) / (m2_rot / bc2).sqrt().add_(eps)

# Rotate back
update = (eigvecs_L @ adam_rot) @ eigvecs_R.T
```

To get `eigvecs_L`, modify `matrix_neg_power` to return both the scaled result and the eigenvectors, or refactor to a helper that caches them for reuse.

The NS call (`zeropower_via_newtonschulz5`) is removed. The u/w-floor is kept to maintain the update-scale contract.

New hyperparameters: `soap_beta1=0.9, soap_beta2=0.999, soap_eps=1e-8`. The outer PMuon `mu` (momentum EMA for the preconditioned direction) is still used as the Nesterov-style first moment, so `m1_rot` replaces the current `momentum` buffer.

State dict change: drop `momentum`, add `m1_rot`, `m2_rot`. Backward-incompatible; fresh run only.

### Arm design

Arm A (default): SOAP body-Muon with `soap_beta1=0.9, soap_beta2=0.999`. Keep all other hyperparameters (lr=0.035, wd=0.025, COOLDOWN_POWER=1.4, EMA β=0.99, PMuon gamma=0.4 for L/R eigenbasis computation but eigenvalues not used for scaling — just eigenvectors).

Arm B: `soap_beta2=0.95` to match existing `beta_cov=0.95` timescale. Tests whether a faster second-moment matches the preconditioner update rate.

### Smoke test

Before full 3250-step run, run 200 steps: confirm loss decreases, no NaN, grad_to_weight_norm finite and in range [0.01, 10]. Check that `m2_rot` does not collapse to zero (pathological case: all eigenvalues vanish, no signal).

### Citation

Vyas, N., Morwani, D., Zhao, R., Shapira, I., Brandfonbrener, D., Janson, L., Kakade, S. (2024). SOAP: Improving and Stabilizing Shampoo using Adam. OPT 2024. https://arxiv.org/abs/2409.11321

### Risk

- Eigendecomposition is already the expensive step; adding Adam state and the rotated-frame Adam update adds ~3 tensors per param but no extra `eigh` calls.
- The eigenvectors need caching across the `m_pre` computation; a minor refactor to `matrix_neg_power` or `pmuon_update`.
- If the Adam second moment and the PMuon covariance EMA converge to the same curvature signal, there is no gain — but in this case Arm A should match baseline, not regress.
- Possible instability if eigenvectors are numerically degenerate (nearly-repeated eigenvalues). Mitigate with `eigvals.clamp_min(eps)` on the existing path (already present).

---

## H2 (HIGH PRIORITY): Kahan compensated weight accumulation for body-Muon

### Mechanism

BF16 has 7 mantissa bits, so a weight of magnitude ~1 cannot represent increments below ~2^{-7} ≈ 0.008. In late cooldown (step 2500–3250), the effective LR is `0.035 * (750/2275)^1.4 ≈ 0.035 * 0.23 ≈ 0.008`, so individual updates are already at the BF16 rounding floor. Once LR drops another factor of 2, effective updates are rounded to zero.

Kahan compensated summation maintains an FP32 error buffer `c` alongside each parameter. At each optimizer step:
```
y = update + c      # add compensation to the intended update
t = p + y           # apply to parameter
c = y - (t - p)     # recover the rounding error
```
This preserves accumulation accuracy to ~FP32 precision regardless of BF16 storage, at the cost of one extra FP32 buffer per parameter (same memory footprint as the EMA buffer already maintained).

The Polyak EMA buffer already stores FP32 copies of body-Muon params. Kahan adds a second FP32 buffer `c` per param. The EMA can use the same compensation pattern for its lerp accumulation.

### Implementation

In `Muon.step()`, after computing `update`:

```python
# Initialize compensation buffer (once)
if "kahan_comp" not in state:
    state["kahan_comp"] = torch.zeros_like(p, dtype=torch.float32)

comp = state["kahan_comp"]
# Apply weight decay in FP32
p_f32 = p.detach().float()
wd_correction = group["lr"] * group["weight_decay"] * p_f32
y = (-group["lr"] * update.float() - wd_correction) + comp
new_p = p_f32 + y
comp.copy_(y - (new_p - p_f32))
p.copy_(new_p.to(p.dtype))
state["kahan_comp"].copy_(comp)
```

This replaces the existing `p.mul_(1 - lr*wd); p.add_(update, alpha=-lr)` lines.

Weight decay is absorbed into the compensated update. The EMA buffer's lerp can optionally also use Kahan accumulation (small added benefit, worth including).

### Arm design

Arm A: Kahan compensation on body-Muon params only. Arm B: Kahan on body-Muon params + matching Kahan accumulation in EMA buffer lerp.

### Smoke test

None required — trivially backward-compatible (compensation buffer starts at zero). Run 200 steps and check that `val/loss` at step 200 matches baseline within 0.005 (confirming the compensation path does not introduce a bias).

### Citation

Kahan, W. (1965). Practical methods of Schwarz-Christoffel transformation. Specifically Kahan summation algorithm. Modern ML usage: Yang, G. et al. (2022) "Tensor Programs V: Tuning Large Neural Networks via Zero-Shot Hyperparameter Transfer" (Appendix), and multiple open-source implementations in BF16 training contexts. Also: https://en.wikipedia.org/wiki/Kahan_summation_algorithm

Practical modern context: Feinman R. (2024) "Kahan Summation for Neural Network Training in Low Precision" (various blog posts and implementations in nanogpt training context).

### Risk

- Memory cost: one FP32 tensor per body-Muon param. Same cost as EMA buffer. On 1 GPU for a 12-layer GPT this is ~50MB — acceptable.
- If BF16 precision is not the binding constraint in late cooldown, this will show val loss improvement only in the last 200 steps — a small but possibly statistically significant effect.
- The mechanism is independent of PMuon architecture and orthogonal to all 71 closed axes.

---

## H3: L_cov / R_cov Adam-style bias correction

### Mechanism

The current PMuon covariance EMAs are initialized to zero and accumulate without bias correction:
```python
L_cov.mul_(beta_cov).add_(g @ g.T)   # no (1 - beta_cov) denominator
```
At step t=1 with beta_cov=0.95: `L_cov = 0.05 * g@g.T`. At step t=20: `L_cov ≈ 0.64 * true_E[g@g.T]`. The preconditioner is severely under-estimated in early training (steps 0–50), biasing `matrix_neg_power` toward very large values (since L_cov is near-zero, its negative power is near-infinity, clamped by eps). This means the effective per-step scaling is dominated by the eps floor for the first ~50 steps, effectively disabling PMuon's preconditioner during warmup.

Adam-style bias correction: when computing `matrix_neg_power(L_cov, gamma, eps)`, pass `L_cov / (1 - beta_cov**step)` instead of raw `L_cov`. This rescales the cumulative EMA to be an unbiased estimate of `E[g@g.T]` at each step, making the preconditioner accurate from step 1.

This is fundamentally different from PR #686 (beta_cov schedule — varied beta_cov over time). Here beta_cov is fixed at 0.95 but the denominator rescaling corrects the initialization bias.

### Implementation

In `Muon.__init__`, add a `step_count` dict per param group (or per param). In `pmuon_update`:

```python
# Track step count for bias correction
if "step" not in state:
    state["step"] = 0
state["step"] += 1
t = state["step"]

L_cov_hat = state["L"] / (1 - beta_cov ** t)
R_cov_hat = state["R"] / (1 - beta_cov ** t)
L_neg = matrix_neg_power(L_cov_hat, gamma, eps)
R_neg = matrix_neg_power(R_cov_hat, gamma, eps)
```

The clamp_min eps in `matrix_neg_power` already handles near-zero eigenvalues. With bias correction, eigenvalues will be larger and better-conditioned from step 1, reducing the eps-clamping regime.

### Arm design

Arm A: Bias correction with beta_cov=0.95 (current value). Tests whether early-training preconditioner accuracy matters.

Arm B: Bias correction with beta_cov=0.98 (slower accumulation, better asymptotic estimate, needs bias correction more urgently). Tests whether slower covariance + correction is better than faster without.

### Smoke test

Log `L_cov.diagonal().mean()` at steps 1, 10, 50, 200 to confirm the bias-corrected version converges to ~true gradient second moment faster. Check that `val/loss` at step 100 is lower than baseline (early-training signal).

### Citation

Kingma, D. P. & Ba, J. (2014). Adam: A Method for Stochastic Optimization. ICLR 2015. Section 3: bias correction of moment estimates. https://arxiv.org/abs/1412.6980

The same bias correction appears in all modern Adam variants. Its application to Kronecker-factor covariance EMAs is a natural but untested extension in this codebase.

### Risk

- No memory cost change. Pure computational change: two scalar divisions per param per step.
- Potential instability at step 1 if `1 - 0.95^1 = 0.05` denominator makes eigenvalues too large. Mitigate by clamping denominator: `max(1 - beta_cov**t, 0.01)`.
- If early-training bias is already compensated by the u/w-floor (which scales up small updates), the benefit may be marginal. But u/w-floor has a different mechanism (ensures ||update|| / ||weight|| ≥ 0.35) and does not fix the eigenvector accuracy, only the eigenvalue magnitude.

---

## H4: SWA partial alpha-blend at cooldown_start

### Mechanism

PR #730 tested full SWA centroid replacement at step 975 (the cooldown start): at step 975 swap all params to the SWA running average and continue training from there. Result was NULL (within noise of baseline).

A partial alpha-blend is a distinct mechanism: instead of fully replacing the live params, blend them toward the SWA centroid using a small weight alpha (e.g., alpha=0.3). The live params then continue from `p.data = (1-alpha)*p.data + alpha*swa_p.data`. This acts as a single step of sharpness-aware implicit regularization toward the loss basin center, nudging the network into a flatter region without forcing a complete restart.

The rationale for partial over full: full replacement loses the sharp curvature information accumulated during the stable phase — the live params may be better adapted to the current learning rate. A 0.3-weighted blend is a soft nudge that preserves 70% of the trained state while incorporating the averaging benefit.

This is listed as explicitly untested in CURRENT_RESEARCH_STATE.md.

### Implementation

Add a SWA accumulation running from step 100 to 975 (start after first 100 steps to skip unstable early dynamics). At step 975, apply:

```python
alpha = 0.3  # ARM_A: 0.2, ARM_B: 0.3
if step == cooldown_start:
    for p, swa_p in zip(muon_params, swa_params):
        p.data.mul_(1 - alpha).add_(swa_p.data.to(p.dtype), alpha=alpha)
    # Reset SWA to current live params (no further accumulation)
```

SWA accumulation: in the training loop, after each optimizer step (steps 100–975), update: `swa_p.mul_(swa_count/(swa_count+1)).add_(p.detach().float(), alpha=1/(swa_count+1))`.

Memory cost: one FP32 buffer per body-Muon param (same as EMA buffer). Can share memory with EMA buffer by repurposing EMA buffer during steps 0–975.

### Arm design

Arm A: alpha=0.2 blend. Arm B: alpha=0.3 blend. The NULL result for full replacement (alpha=1.0) is the upper bound — we expect a monotone response in alpha.

### Smoke test

Confirm val loss does not spike at step 975 (blend application). A spike >0.05 would indicate the blend is too large.

### Citation

Izmailov, P., Podoprikhin, D., Garipov, T., Vetrov, D., Wilson, A. G. (2018). Averaging Weights Leads to Wider Optima and Better Generalization. UAI 2018. https://arxiv.org/abs/1803.05407

Prior relevant PR: #730 (full SWA replacement at cooldown_start, NULL). The partial-blend variant is the natural follow-up from that NULL result.

### Risk

- The NULL result for full replacement (alpha=1.0) suggests the SWA centroid itself is not clearly better than the live point at step 975. If the direction from live to SWA is not useful, partial blend is also NULL.
- Memory: one FP32 buffer shared with EMA buffer during warmup phase. Net zero additional memory if repurposed.
- Interaction with Polyak EMA: EMA warmup phase (steps 0–975) tracks live params. Blending live params at step 975 is immediately reflected in EMA since it copies live params during warmup. No change needed to EMA logic.

---

## H5: PSGD Kronecker-factor preconditioner as body-Muon alternative

### Mechanism

PSGD (Preconditioned SGD, Xi-Lin Li) maintains a preconditioner via Lie-group gradient descent on the preconditioner itself rather than via explicit eigendecomposition. For matrix parameters, a Kronecker-factor variant maintains `(Q_L, Q_R)` where the preconditioner is `Q_L^T @ Q_L ⊗ Q_R^T @ Q_R` (Kronecker product), and updates `Q_L`, `Q_R` online via a small gradient step on the preconditioner loss:

`L(Q) = tr(Q @ H @ Q^T) - log det(Q @ Q^T)`

This is minimized when `Q @ Q^T = H^{-1}` (inverse Hessian). Unlike Shampoo/PMuon which use gradient outer products to estimate the Hessian, PSGD uses actual gradient information (not the covariance) and the Lie-group constraint to maintain a valid preconditioner.

Key advantages over PMuon:
1. No eigendecomposition per step — updates are triangular matrix multiplications.
2. The preconditioner naturally adapts to non-symmetric curvature (gradients, not just gradient covariances).
3. Cheaper per-step than PMuon when covariance matrices are large (attention weight matrices are 768×768).

### Implementation

For each body-Muon param `g` of shape (m, n), maintain `Q_L` (m×m upper-triangular, float32) and `Q_R` (n×n upper-triangular, float32). Initialize to identity.

Each step:
```python
# Preconditioned gradient
g_pre = Q_L @ g32 @ Q_R.T   # or use Cholesky solve for numerical stability

# Preconditioner update (Lie-group gradient step)
# Gradient of L w.r.t. Q_L: (Q_L @ g32 @ g32.T - Q_L^{-T}) * lr_precond
# Use closed-form update for triangular factors
A = Q_L @ g32 @ g32.T @ Q_L.T          # shape (m, m)
I = torch.eye(m, device=g.device, dtype=torch.float32)
# dL/dQ_L = (A - I) @ Q_L (Lie-group update)
Q_L = Q_L - lr_precond * (A - I) @ Q_L
# Re-triangularize: Q_L = torch.linalg.qr(Q_L)[1] or just apply triu
Q_L = torch.triu(Q_L)

# Similarly for Q_R
B = Q_R.T @ g32.T @ g32 @ Q_R           # shape (n, n)
Q_R = Q_R - lr_precond * (B - I) @ Q_R
Q_R = torch.triu(Q_R)

# Momentum on preconditioned gradient
momentum.lerp_(g_pre, 1 - mu)
update = momentum
```

Remove NS call (not needed; PSGD preconditioner already provides orthogonalization-like effect). Keep u/w-floor.

Hyperparameters: `lr_precond=0.1` (preconditioner learning rate). This is the critical sensitivity parameter.

### Arm design

Arm A: `lr_precond=0.1`. Arm B: `lr_precond=0.01` (slower preconditioner, closer to Muon's slow covariance EMA).

### Smoke test

Run 200 steps. Check that `Q_L` stays well-conditioned (`Q_L.diagonal().min() > 1e-3`). If Q_L becomes near-singular, the preconditioned gradient explodes.

### Citation

Li, X.-L. & Pearlmutter, B. A. (2018). Preconditioned Stochastic Gradient Descent. IEEE Transactions on Neural Networks and Learning Systems. https://arxiv.org/abs/1512.04202

Li, X.-L. (2024). PSGD Fx: Practical Preconditioned Stochastic Gradient Descent. https://arxiv.org/abs/2211.04457 (updated 2024)

### Risk

- Significantly more complex implementation than other hypotheses. Triangular matrix representation requires careful numerics.
- `lr_precond` is a new critical hyperparameter with no prior tuning in this codebase.
- If the Kronecker factorization assumption is poor (which it may be for attention projections with highly coupled rows), the preconditioner can be worse than PMuon's symmetric treatment.
- High implementation risk; recommend smoke test before full run.

---

## H6: Decoupled covariance EMA timescale (beta_cov = 0.98)

### Mechanism

In PMuon, `mu=0.95` (momentum EMA timescale) and `beta_cov=0.95` (covariance EMA timescale) are coupled at the same value. These serve fundamentally different roles: momentum tracks the gradient direction over recent steps (~20 steps at 0.95), while covariance tracks the second-order landscape geometry which evolves much more slowly.

Using `beta_cov=0.98` (effective window ~50 steps) gives a more stable eigenvector estimate for the preconditioner without affecting momentum dynamics. This is different from PR #686 (which varied beta_cov on a schedule over time) — here it is fixed at a larger value.

The key test is whether the current `beta_cov=0.95` causes the covariance eigenvectors to chase fast gradient noise, resulting in an unstable preconditioner that partially explains the cooldown-erosion pattern. A slower covariance should produce more stable preconditioner geometry, especially when gradient statistics are changing rapidly at the warmup→cooldown transition.

### Implementation

Single hyperparameter change in Muon constructor:
```python
optimizer2 = Muon(..., beta_cov=0.98, ...)
```

No code changes to `pmuon_update` beyond passing the new value.

### Arm design

Arm A: `beta_cov=0.98`. Arm B: `beta_cov=0.99` (very slow covariance, approaches batch statistics over the full training window).

Note: PR #778 (in-flight) tests PMuon per-type gamma scan. This is `beta_cov`, not gamma — no duplication. PR #686 (closed) tested a schedule for beta_cov; this is a fixed different value — mechanistically distinct.

### Smoke test

None required — single scalar change. Run full 3250 steps.

### Citation

The decoupling motivation follows from the Adam paper (Kingma & Ba, 2014) recommendation to use different timescales for first and second moments (`beta1=0.9, beta2=0.999`). The same principle applies to PMuon's momentum/covariance separation. Also related: Loshchilov & Hutter (2019) AdamW — discussion of hyperparameter sensitivity of beta2 vs beta1.

### Risk

- Low implementation risk. Single constant change.
- If the covariance and momentum timescales are already well-matched at 0.95 for this problem, no benefit.
- In-flight PR #778 tests per-type gamma; if that shows gamma differences across param types, `beta_cov` may also benefit from per-type values — but that is a follow-up, not a conflict.

---

## H7: Frobenius-normalized NS output (post-NS scaling)

### Mechanism

The current NS output scaling is:
```python
update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)
```
This preserves aspect-ratio scaling (rectangular matrices are scaled up by sqrt(m/n)) but does not constrain the Frobenius norm of `polar` per element. For a well-conditioned input, NS converges to a near-orthogonal matrix with Frobenius norm ≈ min(m,n). But for ill-conditioned inputs, NS may converge to a rank-deficient result with smaller Frobenius norm — meaning the effective update magnitude is smaller than expected, partially defeated by the u/w-floor correction.

Post-NS Frobenius normalization ensures the per-element RMS of `polar` is exactly 1:
```python
polar_normed = polar / (polar.norm() / (polar.numel() ** 0.5) + 1e-7)
update = polar_normed * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)
```

This decouples the NS output magnitude from the conditioning of the input, making the u/w-floor the sole controller of update scale. The mechanism targets the hypothesis that for params with high-condition-number gradient matrices (likely attention Q/K/V projections), NS produces under-scaled outputs that interact poorly with the u/w-floor threshold.

### Implementation

In `zeropower_via_newtonschulz5`, after the main loop:
```python
# ... existing NS loop ...
if G.size(-2) > G.size(-1):
    X = X.mT
# Add Frobenius normalization
X = X / (X.norm(dim=(-2, -1), keepdim=True) / (X.shape[-2] * X.shape[-1]) ** 0.5 + 1e-7)
return X
```

Or equivalently in `pmuon_update`:
```python
polar = zeropower_via_newtonschulz5(m_pre.to(update.dtype), ...)
polar = polar / (polar.norm() / polar.numel() ** 0.5 + 1e-7)
update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** 0.5)
```

### Arm design

Arm A: Post-NS Frobenius normalization (element-wise RMS = 1). This replaces the aspect-ratio-only scaling.

Arm B: Post-NS Frobenius normalization applied only to the preconditioned gradient `m_pre` before NS (pre-normalization). This tests whether it is the NS input conditioning or the NS output conditioning that matters.

### Smoke test

Log `polar.norm() / polar.numel()^0.5` at steps 1, 100, 975, 2000, 3250 to confirm it varies before normalization (motivation) and is fixed after (implementation check).

### Citation

This is a design pattern implicit in the "unit update" philosophy of Muon (Kosson & Jaggi, 2024 and related work on steepest descent under matrix norms). The post-normalization variant is not explicitly proposed in any known paper but follows from the steepest-descent-under-Frobenius interpretation of NS polar maps. Related: Yang et al. (2022) µP — the principle that per-element RMS should be controlled at initialization and update time.

### Risk

- If NS already converges close to orthogonal for all params (which it should when input is well-conditioned), the normalization is a no-op and there is no benefit.
- If the normalization removes useful rank information from the NS output (partially-rank-deficient params should have smaller updates), this could harm parameters with rank deficit — particularly lm_head projection.
- The u/w-floor already provides a lower bound on update magnitude, partially addressing this concern. Post-NS normalization adds an upper bound and makes the floor less frequently active.

---

## H8: Gradient noise injection in stable phase only (pre-cooldown Langevin)

### Mechanism

PR #684 tested Langevin noise injection throughout training and was closed NULL. The key distinction here: noise is injected only during the stable phase (steps 0–975), removed exactly at cooldown_start. The rationale is twofold:

1. Early-phase basin exploration: PMuon's covariance EMA takes ~50 steps to warm up (at beta_cov=0.95). During steps 0–50, the preconditioner is near-identity with bias. Adding gradient noise during this cold-start phase helps explore the loss basin before the preconditioner is active, potentially landing in a flatter basin that is more amenable to cooldown compression.

2. No cooldown interaction: PR #684's NULL result may have been caused by noise *during* cooldown disrupting the LR→0 convergence. By removing noise at step 975, this variant tests the pure basin-exploration effect.

Noise schedule: additive isotropic Gaussian noise `epsilon * sigma * randn_like(grad)` where `sigma = sqrt(lr)` (Langevin scaling) and `epsilon` controls the noise temperature. Use `epsilon=0.01` (0.01× gradient magnitude).

### Implementation

In `pmuon_update` (or in the main training loop gradient accumulation), before the optimizer step:

```python
if step < cooldown_start and noise_eps > 0:
    for p in muon_params:
        if p.grad is not None:
            noise_scale = noise_eps * (current_lr ** 0.5)
            p.grad.add_(torch.randn_like(p.grad) * noise_scale)
```

`noise_eps=0.01` is the key hyperparameter.

### Arm design

Arm A: `noise_eps=0.01`. Arm B: `noise_eps=0.001` (weaker noise, less exploration risk).

### Smoke test

Confirm val loss at step 975 (noise removal point) does not spike. If val loss spikes or train loss is unstable during stable phase, reduce `noise_eps`.

### Citation

Welling, M. & Teh, Y. W. (2011). Bayesian Learning via Stochastic Gradient Langevin Dynamics. ICML 2011. https://arxiv.org/abs/1412.6980

Prior closed PR: #684 (Langevin noise throughout training, NULL). This variant restricts noise to pre-cooldown only — mechanistically distinct.

### Risk

- Prior PR #684 was NULL for throughout-training Langevin. If the NULL was due to insufficient noise (not cooldown disruption), pre-cooldown-only noise will also be NULL.
- Introduces training stochasticity beyond the seed, making reproducibility slightly harder to interpret.
- Low risk to implement; `noise_eps=0.001` should be effectively a no-op if mechanism is inactive.

---

## Priority Ranking

1. H1 (SOAP-in-eigenbasis): Highest mechanistic novelty, directly leverages existing eigenbasis computation, strongest external evidence from SOAP paper showing strict improvement over Shampoo/Adafactor. Risk: moderate implementation complexity.

2. H2 (Kahan compensated weights): Cheapest implementation, directly addresses identified cooldown precision loss mechanism, orthogonal to all 71 closed axes. Risk: low.

3. H3 (L_cov bias correction): Zero memory cost, targets early-training preconditioner accuracy, mechanistically different from closed beta_cov schedule (#686). Risk: very low.

4. H6 (Decoupled beta_cov=0.98): Single constant change, tests momentum/covariance coupling hypothesis. Risk: lowest of all hypotheses.

5. H7 (Post-NS Frobenius normalization): Targets u/w-floor interaction for ill-conditioned params. Risk: low if normalization is near-no-op for well-conditioned NS.

6. H4 (SWA partial alpha-blend): Prior full-replacement NULL constrains the alpha=1 endpoint; partial blend is genuinely different. Risk: moderate (depends on SWA direction being useful).

7. H8 (Pre-cooldown-only Langevin noise): Direct follow-up on closed PR #684 with mechanistic difference. Risk: moderate (prior NULL reduces confidence).

8. H5 (PSGD Kronecker preconditioner): Highest potential upside (entirely new optimizer family), highest implementation risk and complexity. Recommended as longer-term investment after simpler tests.
