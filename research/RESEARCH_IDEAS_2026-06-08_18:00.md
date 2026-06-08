# SENPAI Research Ideas — 2026-06-08 18:00

**Program:** Auto-nanoGPT Open-Context SOTA v2
**Current rank-1 baseline:** `val/ri_loss_gamma_neg0p0750` = 3.276172 (PR #2349, 2890 steps)
**MERGE threshold:** μ < 3.276172; **STRONG threshold:** μ ≤ 3.275772
**Statistical contract:** (3.28 − μ) × √n ≥ 0.004; single run needs loss < 3.276
**Fixed budget:** 2890 steps

---

## Standing constraints — do not violate

- Lookahead on any optimizer: CATASTROPHIC
- GC on Muon (raw gradient or momentum buffer): FALSIFIED
- Per-block depth-wise Muon LR: CATASTROPHIC
- Warm restarts touching [~1950, 2375] Muon LR window: CATASTROPHIC
- lm_head on Muon: CATASTROPHIC
- SOAP Kronecker preconditioner on MLP+V (H-DP): CATASTROPHIC abort at step 1000
- MUON_POWER_C hand-tune 3.317e-6 is in a narrow asymmetric basin — do not move it
- Soft-Muon (CEIL axis): FALSIFIED 57th lever — do not retest
- SWA / weight-space averaging on AdamW: FALSIFIED 51st lever
- Amsgrad replacement (H-DN Arm B): in flight — do not duplicate

**In-flight (do not duplicate):**
H-DV (AdamW β₁ schedule), H-DU (NorMuon pre-NS5), H-DT (RI capture_step later),
H-DS (Sinkhorn iter count), H-DQ (Contra-Muon coeff sweep), H-DO (NC after NS5),
H-DN (NC removed / Amsgrad), H-DW (Polyak-Ruppert weight avg on AdamW)

---

## H-1: MUD triangular whitening as NS5 replacement

**Title:** Replace Newton-Schulz 5-iteration polynomial with MUD (Momentum-based Unstable-free Decorrelation) triangular solve

**Mechanism:**
MUD (arxiv 2603.17970) replaces NS5's polynomial spectral orthogonalization with a single triangular whitening step. Given the Muon momentum buffer matrix M (shape [d_out, d_in]), MUD:
1. Row-normalizes M → Q
2. Computes Gram matrix G = QQ^T
3. Extracts lower triangle T = tril(G)
4. Forward-solves Q ← T^{-1} Q  (triangular solve, ~O(kd) not O(k^2 d) like SVD)
5. Re-normalizes rows → final row-orthonormal update

The theoretical motivation: NS5's polynomial approximates the matrix sign function over the spectrum of M, but it requires 5 iterations and can amplify outlier singular values when the spectrum is poorly conditioned. MUD's triangular solve produces exact row-orthogonality in one pass by exploiting the Gram structure. Per-step wall clock is ~12× lower FLOP count vs NS5 (MUD1: ~2.5k²d vs Muon5: ~30k²d). The LM-scale validation in the MUD paper shows per-step convergence comparable to or slightly better than Muon on the same learning rate, suggesting the orthogonalization quality is at least as good as NS5 under normal conditioning.

Why this might help here specifically: the current stack has EN (EMA-Nesterov) accumulating a slow-trajectory MUD buffer, and NC (Cautious-Muon) doing post-NS5 row×col L2 norm equalization. If NS5's 5-iteration polynomial leaves residual spectral asymmetry that NC's geometric mean is compensating for, replacing NS5 with MUD's exact triangular solve may reduce that residual — potentially making NC cheaper or even removable. The NC ablation trio (H-DN/H-DO/H-DU in flight) is the direct probe; MUD is the mechanism-level intervention that changes what NC is patching.

**Arms:**
- Arm A (direct swap): Replace `NewtonSchulz5` call in Muon optimizer with MUD triangular solve. Keep all other stack components (EN γ=0.99, NC row×col, Arbor iters=2 clamp_k=3.0, RI capture=2375 γ=−0.075, AdamW betas=(0.8,0.99) eps=1e-12). No hyperparameter changes. Muon lr=0.05 unchanged.
- Arm B (MUD + NC removed): If Arm A T0 ≤ 3.276572, run with NC disabled. Hypothesis: MUD's exact row-orthogonality makes NC's post-hoc equalization redundant. If NC is removable under MUD but not under NS5, this is the mechanism explanation for H-DN's near-neutral NC removal result.

**Implementation:**
```python
def mud_orthogonalize(M, eps=1e-12):
    # Row-normalize
    norms = M.norm(dim=1, keepdim=True).clamp(min=eps)
    Q = M / norms
    # Gram matrix
    G = Q @ Q.T  # [k, k]
    # Lower-triangular Cholesky-style solve
    T = torch.linalg.cholesky(G + eps * torch.eye(G.shape[0], device=G.device))
    # Forward triangular solve: T Q = Q_old → Q_new = T^{-1} Q
    Q = torch.linalg.solve_triangular(T, Q, upper=False)
    # Re-normalize rows
    Q = Q / Q.norm(dim=1, keepdim=True).clamp(min=eps)
    return Q
```
Note: `torch.linalg.solve_triangular` is available in PyTorch >= 1.11. If G is rank-deficient early in training (all-zero momentum at step 0), the eps regularization on the eye term catches it. The MUD paper uses p=1 (one whitening pass). Do NOT add multiple passes — that reintroduces NS5-like cost.

**Critical gotcha:** MUD paper trains from scratch; our stack has EN accumulating the momentum buffer. At step 0 the momentum buffer is zero-initialized, so G = 0. The eps*I regularizer handles this, but the first ~50 steps may produce near-identity updates. This is benign but means the early-training benefit of NS5's polynomial approximation is also lost. If T0 shows a slow-start pattern (train loss lagging baseline in first 200 steps), try increasing Muon LR by 2× for steps [0, 100] and reverting.

**Expected impact:** −0.0003 to −0.0010 if MUD's exact row-orthogonality reduces the spectral residual that NC currently patches. Possibly neutral if NS5 and MUD are equivalent in this regime.

**Risk:** Medium. Novel mechanism, no result yet on top of NC×Arbor×EN×RI×eps=1e-12 stack. The Gram matrix at step 0 can be ill-conditioned. The triangular solve may be slightly slower than NS5 in practice due to torch.linalg overhead on small matrices (gradient matrices are ~768×3072 at this scale — small enough that FLOP savings may not materialize in wall-clock time on H100).

**References:**
- "MUD: Momentum-based Unstable-free Decorrelation" (arxiv 2603.17970, 2026). Validates on LM tasks; per-step convergence ≥ Muon NS5.

---

## H-2: Lion (sign-based SGD) for AdamW dense parameter groups

**Title:** Replace AdamW with Lion optimizer for embed and lm_head dense parameter groups

**Mechanism:**
Lion (arxiv 2302.06675) updates parameters using only the sign of the exponential moving average of the gradient: `update = sign(β₁ * m + (1-β₁) * g)`, then updates `m = β₁ * m + (1-β₁) * g`. The sign constraint forces all updates to have uniform step magnitude, acting as an implicit form of adaptive learning rate normalization. Compared to AdamW, Lion uses only one momentum buffer (not two), has lower memory overhead, and applies weight decay on the pre-sign parameter rather than on the update direction.

Why this might help here: AdamW's second-moment estimate (β₂=0.99) is the main adaptive scaling mechanism for embed/lm_head. After 57 saturated levers, the only untouched dimension of the dense optimizer is the update-direction distribution. Lion replaces the scalar adaptive scaling with a uniform sign constraint, which is a qualitatively different inductive bias. In standard transformer pretraining, Lion has been shown to outperform AdamW at 1e-4 to 3e-4 LR range (Google Brain NLP benchmarks). Our AdamW LR is ~0.0031 (1/320 baseline) — a different regime — but the sign mechanism may interact favorably with the existing Muon update on the sharpness of the loss landscape near the optimum.

Critically: Lion must NOT be applied to Muon-group parameters. Only embed (wte) and lm_head. The lm_head invariant (LR ≥ 1/320 throughout, no LR floor drop) must be respected — Lion's effective LR is its raw lr × sign, so the lr value passed to Lion for lm_head should match the current AdamW lm_head lr (approximately lr_init/320 = baseline schedule value).

**Arms:**
- Arm A: Lion for embed (wte) + lm_head only. All other params unchanged. Lion β₁=0.9, weight_decay=0.1. LR for these groups: match current AdamW schedule for those groups exactly (same warmup/cooldown curve, same final LR values). Run n=1 T0 first.
- Arm B: If Arm A T0 ≤ 3.276572, extend to all AdamW dense params (embed + lm_head + any remaining dense params not on Muon). Same Lion hyperparams.

**Implementation:**
```python
class Lion(torch.optim.Optimizer):
    def __init__(self, params, lr=1e-4, betas=(0.9, 0.99), weight_decay=0.0):
        defaults = dict(lr=lr, betas=betas, weight_decay=weight_decay)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            for p in group['params']:
                if p.grad is None:
                    continue
                grad = p.grad
                beta1, beta2 = group['betas']
                state = self.state[p]
                if len(state) == 0:
                    state['exp_avg'] = torch.zeros_like(p)
                m = state['exp_avg']
                # Update: sign of interpolated momentum
                update = (beta1 * m + (1 - beta1) * grad).sign_()
                # Weight decay
                p.mul_(1 - group['lr'] * group['weight_decay'])
                p.add_(update, alpha=-group['lr'])
                # Momentum update
                m.mul_(beta2).add_(grad, alpha=1 - beta2)
```
Note: Lion's effective weight decay is `lr * wd`, so with lr ~3e-3 and wd=0.1, effective WD = 3e-4. Adjust wd if this over-decays embed rows. The `.sign_()` in-place is critical for correctness (avoids creating a new tensor).

**Critical gotcha:** The sign constraint makes Lion invariant to gradient scale — a gradient of magnitude 1e-6 and one of 1.0 produce the same update magnitude. This is ideal when grad scale is well-behaved but can cause instability early in training if the momentum buffer hasn't warmed up. Use the same LR warmup steps as AdamW to let the momentum stabilize first. Do NOT start Lion from step 0 with full LR.

**Expected impact:** Speculative. Lion has shown +1-3% perplexity improvement in some transformer setups but the effect is corpus- and scale-dependent. Expected range: −0.0005 to +0.0005. The sign mechanism is qualitatively different from anything in the current stack — this is a directional bet, not a hyperparameter tweak.

**Risk:** Medium-low for Arm A (embed+lm_head only — if it fails, loss from those groups alone is small). Medium-high for Arm B.

**References:**
- Chen et al., "Symbolic Discovery of Optimization Algorithms" (arxiv 2302.06675, 2023). Lion optimizer; validated on LM, CV, and diffusion.
- Zhu et al., "Lion Roars: Diagnosing and Correcting Bias in Adam-Based Optimizers" (2023).

---

## H-3: IFNSO pre-optimized NS coefficients (L=7 or L=5 with optimized weights)

**Title:** Replace hardcoded NS5 polynomial coefficients (3, -3, 1) with IFNSO offline-optimized coefficients for the same 5-iteration budget

**Mechanism:**
The current Muon NS5 uses `coeffs = (3.4445, -4.7750, 2.0315)` (or similar hand-tuned values from the KellerJordan repo) for its degree-5 odd polynomial approximation to the matrix sign function. IFNSO (arxiv 2602.02500) proposes learning these coefficients offline via gradient descent over a distribution of randomly conditioned matrices, targeting orthogonalization error rather than polynomial fit. The paper reports L=14 achieves ~12× lower error vs standard NS with ~4× fewer FLOPs using pre-optimized weights.

The key insight for us: the IFNSO approach applies to ANY fixed iteration count L. For L=5 (our current NS5), the paper's offline optimization can produce coefficients with lower residual orthogonalization error than the hand-tuned (3.4445, -4.7750, 2.0315) values. The FLOP count stays identical (same number of matrix multiplications), and no online optimization is needed — we simply swap the scalar coefficients.

Why this might help: after 57 saturated levers, the NS5 polynomial residual is the one component that hasn't been touched directly. NC's row×col equalization compensates for post-NS5 spectral asymmetry. Better-conditioned NS5 coefficients might reduce what NC is patching, or allow the same orthogonalization quality with fewer iterations (potentially ARBOR_ITERS reduction).

**Arms:**
- Arm A: Use IFNSO offline-optimized L=5 coefficients. From the paper's optimization procedure (Adam over random matrix distributions), the L=5 coefficients are approximately `w = [3.4445, -4.7750, 2.0315]` but the IFNSO variant optimizes over the iteration structure `Y_{l+1} = Y_l + w_l * (I - Y_l Y_l^T) * Y_{l-1}`. The student should implement a 200-epoch offline coefficient search over random 768×3072 matrices (matching our gradient shape) and use the resulting w_1, w_2, w_3 in the main training run. This is a one-time 5-minute precomputation, not online optimization.
- Arm B (L=7): If Arm A coefficients improve orthogonalization error by >10% vs L=5 standard (verify with `torch.dist(Y @ Y.T, I)` on test matrices), try L=7 iterations with optimized coefficients. Added cost: +40% iteration count, but potentially lower orthogonalization residual.

**Implementation notes:**
The offline search is straightforward:
```python
# Run offline, once, to find optimal coefficients for L=5
def ns_iter(Y, coeffs):
    for c in coeffs:
        Y = Y + c * (torch.eye(Y.shape[0]) - Y @ Y.T) @ Y
    return Y

# Optimize over random matrices
coeffs = torch.tensor([3.4445, -4.7750, 2.0315], requires_grad=True)
opt = torch.optim.Adam([coeffs], lr=0.01)
for _ in range(5000):
    M = torch.randn(16, 32)  # small proxy matrices
    M = M / M.norm()
    Y = ns_iter(M, coeffs)
    loss = (Y @ Y.T - torch.eye(16)).norm()
    opt.zero_grad(); loss.backward(); opt.step()
print(coeffs.detach())  # use these in main training
```
Then hardcode the optimized values into the training script. No online gradient required.

**Critical gotcha:** The IFNSO paper validates only on MNIST classification, not on LM tasks at our scale. The coefficient optimality depends on the singular value distribution of actual gradient matrices during training, which differs from random Gaussian. The precomputation should ideally use matrices sampled from the actual gradient distribution (run 100 steps, collect gradient matrices, fit coefficients to that distribution). This is more work but would give better-conditioned coefficients.

**Expected impact:** Modest. −0.0001 to −0.0004 if better orthogonalization reduces the NC compensation overhead. Possibly neutral if the current coefficients are already near-optimal for our gradient distribution.

**Risk:** Low for Arm A (same FLOP budget, scalar coefficient change only). The main risk is that the offline search overfits to Gaussian matrices and the resulting coefficients are actually worse for the heavy-tailed gradient distributions seen in transformer training.

**References:**
- "IFNSO: Iteration-Free Newton-Schulz Orthogonalization" (arxiv 2602.02500, 2026). L=14 validated on MNIST; coefficient optimization recipe in appendix.

---

## H-4: AdamW β₂ cosine decay schedule (start 0.999, decay to 0.99)

**Title:** Schedule AdamW β₂ from 0.999 (early training, long memory) to 0.99 (late training, current default) via cosine decay

**Mechanism:**
The current AdamW uses fixed β₂=0.99 throughout training. H-DV (in flight) is testing β₁ schedule, which is a distinct axis. The β₂ controls the second-moment EMA horizon — at β₂=0.99 the effective memory is ~100 steps, at β₂=0.999 it is ~1000 steps.

The hypothesis is that early in training (steps 0-1500) the gradient variance is high and rapidly shifting: a long memory (β₂=0.999) smooths over this noise and gives a better preconditioner estimate. Late in training (steps 1500-2890) the gradient variance is lower and the model is in a narrower basin: a shorter memory (β₂=0.99) is more responsive to the current curvature signal. This is the adaptive-to-phase intuition from the cosine-annealing-of-betas literature (e.g., used in Grokfast and several NLP tuning papers).

This is genuinely distinct from H-DV (β₁ schedule): β₁ affects the first-moment momentum direction; β₂ affects the adaptive step-size scaling. Both can be independently scheduled, and H-DV being in flight does not preclude testing β₂ schedule.

**Arms:**
- Arm A: β₂ cosine from 0.999 → 0.99, starting at step 0 and reaching 0.99 at step 1800 (before EN rest_steps at 1950). After step 1800: fixed β₂=0.99 (standard). No other changes.
- Arm B: β₂ linear from 0.999 → 0.99 over [0, 1500], then fixed. Simpler schedule, easier to analyze.

**Implementation:**
```python
# In AdamW parameter group update, each step:
step_frac = min(current_step / 1800, 1.0)
beta2 = 0.99 + (0.999 - 0.99) * 0.5 * (1 + math.cos(math.pi * step_frac))
# Use this beta2 in place of fixed 0.99
```
Log `train/adamw_beta2` as a telemetry scalar for diagnostics.

**Critical gotcha:** β₂ changes alter the effective learning rate through the denominator `1/(sqrt(v_hat) + eps)`. A higher β₂ early makes the denominator larger (smoother v), which reduces effective LR for embed/lm_head. If the lm_head LR invariant is tight (≥ 1/320), starting with β₂=0.999 may temporarily depress lm_head's effective LR below the floor. Monitor `train/lr/lm_head_effective` or proxy via `train/weight/lm_head_rms` in early steps. If lm_head weight growth lags baseline by >20% in steps [0, 500], abort Arm A and try Arm B with a smaller β₂ starting point (0.995 instead of 0.999).

**Expected impact:** −0.0002 to −0.0006. The β₂ schedule is a relatively well-established trick in language model training (used in Llama-3 optimizer tuning notes and several NeurIPS 2024 papers). The gain depends on whether AdamW's preconditioner is actually misfit in early training at our scale.

**Risk:** Low-medium. Scalar schedule change. H-BO (fixed β₁=0.85/β₂=0.98 sweep) was FALSIFIED, but that was a fixed value not a schedule. This is different in mechanism.

**References:**
- "AdamW with decaying β₂" — discussed in Llama-3 optimizer tuning notes (Meta, 2024).
- H-BO (fixed β₂=0.98 FALSIFIED, n=4 mean 3.277438): shows fixed β₂ reduction hurts, but schedule is different mechanism.

---

## H-5: Gradient stochastic dropping on Muon (stochastic NS5 identity pass)

**Title:** Randomly skip NS5 orthogonalization on a fraction of Muon steps, replacing with identity update (raw momentum)

**Mechanism:**
A stochastic variant of Muon that, with probability p=0.15 per step, skips the NS5 orthogonalization and applies the raw (un-orthogonalized) normalized momentum instead. The intuition is threefold:
1. NS5's orthogonalization imposes a hard spectrum constraint on every step. This is beneficial on average but may occasionally suppress descent directions that are well-conditioned and don't need re-orthogonalizing.
2. Stochastic identity passes introduce implicit regularization: the model occasionally receives a raw gradient step rather than the orthogonalized one, which has been shown in noise-injection literature to improve generalization in narrow basins.
3. At 2890 steps total, if NS5 is skipped 15% of the time, ~434 steps use raw momentum. This is similar in spirit to Dropout on the update path — a soft ensemble of orthogonalized and non-orthogonalized trajectories.

This is NOT Soft-Muon (H-DR, FALSIFIED 57th lever), which applied a CEIL to the NS5 output magnitude. This is stochastic skipping — zero NS5 on skipped steps, full NS5 on the remaining 85%.

**Arms:**
- Arm A: p=0.15 skip probability, uniform across all Muon steps. Single seed T0.
- Arm B (if Arm A T0 ≤ 3.276572): p=0.15 but only for steps [0, 1950] (warm phase). Steps [1950, 2890]: always apply NS5. This protects the EN slow trajectory and RI anchor from stochastic contamination in the critical window.

**Implementation:**
```python
# In Muon optimizer step:
if random.random() > skip_prob or current_step >= ns5_required_from_step:
    G_orth = newton_schulz5(G)
else:
    # Identity pass: just normalize the momentum
    G_orth = G / G.norm().clamp(min=1e-12)
```
Set `skip_prob=0.15`. Make it deterministic given a per-step seed derived from `current_step + run_seed` to allow reproducibility.

**Critical gotcha:** The stochastic skip changes the effective learning rate of the non-skipped steps through the EN EMA: when the raw (non-orthogonalized) momentum is fed into the EN buffer, the EN slow trajectory will accumulate a mix of orthogonalized and non-orthogonalized updates. This may cause the EN γ=0.99 trajectory to be noisier than expected, which could corrupt the RI anchor at step 2375. Monitor `val/ri_loss_gamma_neg0p0750` vs `val/loss` divergence carefully.

**Expected impact:** Speculative. −0.0002 to +0.0003. Stochastic update-path regularization has mixed empirical results; the benefit depends heavily on whether the current training regime is over-sharpened (benefits from noise injection) or already at the right sharpness.

**Risk:** Medium-high. Interaction with EN + RI is unclear. If the EN trajectory is corrupted by non-orthogonalized steps in the slow buffer, the RI anchor will be weaker, potentially neutralizing any orthogonalization benefit.

---

## H-6: RI gamma negative ramp (linear schedule from 0 to −0.075 over last 500 steps)

**Title:** Schedule RI gamma from 0 to −0.075 as a linear ramp over the final 500 steps instead of a single step switch at capture

**Mechanism:**
The current RI implementation captures the model at step 2375, then at inference (step 2890) applies a single interpolation: `w_final = (1 + γ) * w_2890 - γ * w_2375` with γ=−0.075. This is a step-function readout: no RI blending during training, full blend only at the very end.

A ramp variant would gradually interpolate the RI anchor into the optimization trajectory over the last 500 steps of training. Concretely: for steps [2390, 2890], at each step compute a running blend weight `α(t) = (t - 2390) / 500 * |γ|` and apply a partial RI blend to the eval weights (not the training weights): `w_eval = w_train - α(t) * (w_train - w_anchor)`. The training continues on w_train; only the eval weight is blended.

Why this might help: the step-function RI at the very end may miss some of the smoothing benefit if the trajectory from step 2375 to 2890 is noisy (high seed variance). A ramp spreads the anchor influence over more eval checkpoints, potentially reducing end-of-training noise sensitivity. This is distinct from SWA (FALSIFIED 51st lever) because: (a) SWA averages multiple eval checkpoints in weight space, (b) the RI anchor is a single fixed point chosen for its directional meaning (not a temporal average), (c) we are blending with a specific past checkpoint, not averaging a window.

**Arms:**
- Arm A: Linear γ ramp from 0 to −0.075 over steps [2390, 2890]. Eval-only blend (training weights unaffected). Capture step remains 2375. Single seed T0.
- Arm B: Same ramp but starting at step 2500 (shorter ramp, 390 steps instead of 500). Tests whether the ramp length matters or only the final blend value.

**Implementation:**
```python
# During eval at step t (after capture at 2375):
if t > capture_step:
    ramp_alpha = min((t - capture_step) / ramp_steps, 1.0) * abs(ri_gamma)
    # Use blended weights for eval only
    with torch.no_grad():
        for p_train, p_anchor in zip(model.parameters(), anchor_params):
            p_eval = (1 - ramp_alpha) * p_train + ramp_alpha * p_anchor
            p_train.copy_(p_eval)  # temporarily; restore after val
```
Note: the temporary copy/restore pattern is used in the existing RI code. The ramp just changes the blend weight α from constant to step-dependent.

**Critical gotcha:** The current RI code applies the interpolation once at the final step (or at each val step with a constant γ). If we make γ step-dependent, we must ensure the ramp is applied at EVERY validation step in [2390, 2890], not just the final one. If a val step is missed, the reported loss at intermediate steps will reflect different blend weights than intended. Ensure the ramp formula uses the step number at each val event, not a global end-of-run γ.

**Expected impact:** −0.0001 to −0.0004. The RI mechanism itself contributes ~−0.00032 to rank-1. A ramp that spreads the blend may recover some of the seed variance associated with the sharp end-of-training capture.

**Risk:** Low. The ramp only affects eval computation (not training weights). If the ramp is worse than the step function, we simply revert. The main failure mode is interaction with the EN slow trajectory: if EN's accumulated momentum from steps [2375, 2890] is qualitatively different from what the RI anchor captured, the ramp may introduce a conflicting signal.

---

## H-7: Muon NS5 spectral warm-start (scale input by singular value estimate before orthogonalization)

**Title:** Pre-scale the Muon gradient matrix by an EMA singular value estimate before NS5, improving NS5 convergence in the first few iterations

**Mechanism:**
NS5's polynomial convergence is fastest when the input matrix has singular values close to 1. The standard approach is to divide by the spectral norm (largest singular value) before NS5, which pins the largest singular value to 1. This is done in the existing code with `G /= G.norm()` (Frobenius norm proxy). The Frobenius-norm scaling is cheap but imprecise: if the singular value distribution is uneven (concentrated in a few large directions), the Frobenius scaling underestimates the spectral norm, leaving large singular values > 1 that slow NS5 convergence.

A spectral warm-start computes a running EMA estimate of the actual spectral norm (largest singular value) and divides by that instead. For 768×3072 matrices, an exact SVD is expensive, but a 5-step power iteration gives a spectral norm estimate in ~5 FLOP passes (each pass: 2 matrix-vector multiplications). The EMA smooths this estimate across steps, amortizing the cost.

This is a low-risk, mechanistically clear experiment: we are not changing the NS5 polynomial, only its input scaling. If the Frobenius-proxy scaling was already optimal, this experiment costs 5 matrix-vector multiplications per step and contributes nothing. If it was suboptimal, better spectral conditioning of the NS5 input reduces the orthogonalization residual without changing iteration count.

**Arms:**
- Arm A: 5-iteration power method for spectral norm, EMA with β=0.9 across steps. Replace `G /= G.norm()` with `G /= spectral_norm_ema`. Single seed T0.
- Arm B (skip if Arm A T0 > 3.276172): Same with β=0.99 (slower EMA). Tests whether the EMA timescale matters.

**Implementation:**
```python
# Initialize: state['spectral_norm_ema'] = 1.0, state['sv_vec'] = torch.randn(G.shape[1])

# Each Muon step:
v = state['sv_vec']
for _ in range(5):
    u = G @ v; u /= u.norm().clamp(min=1e-12)
    v = G.T @ u; v /= v.norm().clamp(min=1e-12)
sigma = (u @ (G @ v)).abs()
state['sv_vec'] = v  # warm-start next step
ema_beta = 0.9
state['spectral_norm_ema'] = ema_beta * state['spectral_norm_ema'] + (1 - ema_beta) * sigma.item()
G_scaled = G / (state['spectral_norm_ema'] + 1e-12)
G_orth = newton_schulz5(G_scaled)
```
Warm-starting the power iteration vector `v` across steps amortizes convergence cost significantly. After the first ~50 steps, the EMA-stabilized vector converges in 2-3 iterations instead of 5.

**Expected impact:** −0.0001 to −0.0003. The benefit is proportional to the gap between Frobenius-proxy and true spectral norm. If gradient matrices are approximately isotropic (even singular value distribution), the gap is small and this is neutral. If they are heavily concentrated (top-k dominated), the gap can be 5-10× and better scaling meaningfully accelerates NS5.

**Risk:** Low. Additive diagnostic cost only; no architectural or structural change. The EMA warm-start means the first few steps use a noisy estimate, but this is the same regime as cold-started NS5.

---

## H-8: Dual-buffer Muon (second EMA on post-NS5 update at shorter timescale than EN)

**Title:** Add a second fast EMA buffer on the post-NS5 Muon update (τ=0.9), blended with EN's slow buffer (τ=0.99) as a weighted sum

**Mechanism:**
The current EN (EMA-Nesterov) runs a slow buffer at γ=0.99 (~100-step effective memory). The hypothesis is that a second, faster buffer at γ=0.9 (~10-step memory) captures short-timescale curvature information that the slow EN buffer smooths away. The final update is a linear combination: `update = (1 - α) * fast_ema + α * slow_ema` where α=0.5 gives equal weight. This is loosely analogous to AMSGrad's dual-moment tracking or the fast/slow buffer decomposition in Laplacian Momentum.

Why this might help: EN's γ=0.99 was tuned to work with RI's anchor capture at step 2375. A faster buffer (γ=0.9) should be orthogonal to EN's trajectory — it captures transient gradient information that EN filters out. If the current plateau is partly due to EN over-smoothing (losing high-frequency gradient signal needed for late-training sharpening), the dual-buffer blend may recover it.

This is distinct from standard momentum (β₁=0.95 in Muon): Muon's β₁ runs BEFORE NS5 on the raw gradient. EN runs AFTER NS5 on the orthogonalized update. A second fast EMA running AFTER NS5 on the same path as EN is a new buffering level.

**Arms:**
- Arm A: Fast buffer γ_fast=0.9, blend weight α=0.3 (30% fast, 70% slow EN). Single seed T0.
- Arm B (if Arm A T0 ≤ 3.276572): α=0.5 (equal weight). Tests whether more fast-buffer weight helps or hurts.

**Implementation:**
```python
# After NS5 orthogonalization, before applying update:
fast_ema = state.get('fast_ema', torch.zeros_like(update))
fast_ema = gamma_fast * fast_ema + (1 - gamma_fast) * update
state['fast_ema'] = fast_ema

slow_ema = state['en_ema']  # existing EN buffer at gamma=0.99

blended_update = (1 - alpha_blend) * fast_ema + alpha_blend * slow_ema
# Apply blended_update instead of slow_ema for Muon step
```
The Nesterov lookahead in EN uses the slow buffer's lookahead. For the dual-buffer version, use the blended update for the actual parameter step. The fast buffer is additive — it does not replace the slow EN path, only supplements it.

**Critical gotcha:** The EN buffer feeds into the RI anchor at step 2375. If the blended update shifts the EN trajectory, the RI anchor location (and thus γ=−0.075 optimal value) may shift. Monitor `val/ri_loss_gamma_neg0p0750` closely — if it diverges from `val/loss` by more than +0.0004, the RI anchor is misaligned and the blend is corrupting the readout mechanism.

**Expected impact:** −0.0002 to −0.0008 if the fast buffer recovers short-timescale signal. Possibly neutral or negative if the fast buffer is just adding noise to the already well-tuned EN slow trajectory.

**Risk:** Medium. Interaction with EN + RI is the primary risk. The dual-buffer idea is mechanistically motivated but has not been tested on top of our full stack.

---

## Priority ordering and experiment decision tree

**Tier 1 (highest priority — mechanistically novel, LM-validated or structurally orthogonal to all in-flight):**
1. **H-1 (MUD)** — only paper with LM-scale validation showing per-step parity with Muon. Directly targets NS5 orthogonalization quality.
2. **H-4 (AdamW β₂ schedule)** — genuinely distinct axis from H-DV (β₁ schedule, in flight). Low risk, well-motivated, untested.

**Tier 2 (mechanistically interesting, higher uncertainty):**
3. **H-2 (Lion for dense params)** — qualitatively different dense-optimizer update rule. Speculative but orthogonal to everything tried.
4. **H-8 (Dual-buffer Muon)** — new buffering level after NS5, orthogonal to EN mechanism.

**Tier 3 (diagnostic / calibration value — moderate expected gain, clean ablation):**
5. **H-6 (RI gamma ramp)** — low-risk ramp variant of existing RI mechanism. Orthogonal to in-flight H-DT (capture step change).
6. **H-7 (NS5 spectral warm-start)** — pure diagnostic: tests whether Frobenius-proxy scaling is limiting NS5.
7. **H-3 (IFNSO coefficients)** — only MNIST-validated; coefficient optimization recipe is actionable.

**Tier 4 (interesting but higher execution risk or lower expected gain):**
8. **H-5 (stochastic NS5 skip)** — risky EN+RI interaction; try only after other tiers exhausted.

**Decision tree:**
- If H-1 (MUD) T0 ≤ 3.276172 → run Arm B (MUD + NC removed). If MUD+NC removed also ≤ 3.276172 → NC is patchwork; MUD closes the gap. If MUD+NC > MUD alone → NC is still load-bearing even under exact orthogonalization.
- If H-1 (MUD) T0 > 3.276172 → NS5 and MUD are equivalent at our scale; orthogonalization quality is not the bottleneck. Move focus to H-2/H-4.
- If H-4 (β₂ schedule) T0 ≤ 3.276172 → combine with H-DV result (β₁ schedule) for a joint β₁+β₂ schedule experiment.
- If H-4 (β₂ schedule) T0 > 3.276172 → AdamW second-moment axis is saturated. Close both β axes.
- If H-2 (Lion) Arm A T0 ≤ 3.276172 → Lion has better update geometry than AdamW for embed/lm_head. Combine with best-so-far Muon stack for n=4 confirmation.
- If H-6 (RI ramp) T0 ≤ 3.276172 → RI mechanism has headroom from ramp vs step-function. Consider combining with H-DT result (capture step later).

**Stop conditions:**
- H-1 MUD stop condition: Arm A T0 > 3.277200 (DEEP FALSIFIED). If this poor, MUD's Gram conditioning is failing on our gradient distribution; do not try further variants.
- H-5 stop condition: Arm A T0 > 3.277000 OR `val/ri_loss_gamma_neg0p0750` deviates from `val/loss` by > +0.0006 at any val step. Abort immediately — EN+RI contamination.

---

## Research state update

**Current best explanation for plateau:** The NC×Arbor×EN×RI×eps=1e-12 stack has converged to a tight local optimum where every major optimization axis (57 tested) is saturated. The remaining signal is likely in:
1. The quality of NS5 orthogonalization itself (MUD as replacement)
2. The per-step update geometry of AdamW (β₂ schedule, Lion)
3. Fine-grained RI readout blending (gamma ramp)

The NC ablation trio (H-DN/H-DO/H-DU in flight) is the most important diagnostic running right now: if NC removal is confirmed neutral, it opens the door to stack simplification and possibly a cleaner foundation for MUD or dual-buffer Muon.

**Evidence:** H-DN Arm A T0=3.276435 (near-neutral), H-DO Arm A T0=3.276730 (FALSIFIED), H-DU (NorMuon pre-NS5) in flight. Pattern suggests NC's position in the pipeline matters more than its presence.

**Ruled out:** SWA, Lookahead, SOAP Kronecker, Soft-Muon, per-block LR, all major EN timing variants, all MUON_POWER_C variants, Sophia-G, Amsgrad (in progress, likely FALSIFIED based on prior closed runs).

**Open uncertainties:**
1. Is the NS5 polynomial the binding constraint on orthogonalization quality, or is the Muon gradient matrix itself well-conditioned enough that NS5 residuals don't matter?
2. Does the AdamW second-moment estimate have meaningful room for improvement via scheduling, or is the β₂=0.99 fixed-point already optimal for the embed/lm_head parameter manifolds at 2890 steps?
3. Does the RI capture mechanism have seed-correlated variance that a ramp readout would reduce?
