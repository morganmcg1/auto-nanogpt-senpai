# Research Ideas — First Experiment Wave
Generated: 2026-05-15

Baseline: #20 (3030 steps, Contra-Muon + Soft-Muon interp + SOAP attn/MLP + lr schedule).
Calibration: ~0.0045 val-loss per 100 steps. Single run needs < 3.276; n=4 needs mean < 3.278.

---

## H1: Trapezoidal / Warmup-Stable-Decay LR Schedule with Longer Flat Phase

**Family:** Schedule

**Premise:** The baseline uses a "flat-then-linear-decay" schedule with `cooldown_frac=0.7`, meaning 30% of steps are flat and 70% are decaying. Recent LLM scaling work (MiniCPM, Hazy Research) found that the trapezoidal schedule (short warmup, long stable, short cosine/linear decay) with the decay lasting only 10-20% of total steps can reach lower loss at the same step count by spending more budget in the high-LR regime. The theoretical argument: the optimizer is most sample-efficient at high LR early on; a long decay is wasted once the model is already near the basin. The current 70% cooldown may be too conservative — too much time is spent annealing rather than exploring.

**What to implement:** Change `cooldown_frac` from 0.7 to 0.2 (80% stable, 20% decay). Add a short linear warmup of ~40 steps from 0 to full LR. Optionally test cosine vs linear decay. Keep all other hparams identical to #20.

**Concrete hparams:**
- `cooldown_frac = 0.2` (down from 0.7)
- Warmup: linear 0→lr over steps 0..39
- Decay: linear lr→0 over last 20% of steps
- `train_steps`: start at 3000 to match expected improvement ceiling from extra stable budget

**Run budget:** 2 seeds at 3000 steps for screening; 4 seeds if result is promising.

**Success criterion:** Mean val loss < 3.278 at ≤ 3000 steps (pairwise statsig vs #20 requires meaningful step reduction or loss improvement).

**Failure mode:** Training becomes unstable without the long cooldown — loss plateaus or diverges in final phase, indicating the optimizer depends on slow annealing to settle sharp minima.

---

## H2: Cosine-with-Restarts (SGDR) Applied to Muon LR

**Family:** Schedule

**Premise:** Loshchilov & Hutter (2017) showed that cosine-with-restarts (SGDR) can escape sharp minima by periodically re-raising the LR. In optimizer step-count benchmarks, restarts trade within-cycle convergence for the ability to land in flatter, more generalizable basins. The current flat+linear schedule has no restart mechanism. At step scale ~3000, 2-3 cycles with a warmup restart ratio of 2x could find a better basin than a single long linear decay. The recent "Warmup-Stable-Decay" literature suggests the restart helps when combined with a final long-decay terminal cycle.

**What to implement:** Replace the linear decay with 2 cosine half-cycles (T=600 steps, T_mult=2), followed by a final linear cooldown over last 300 steps. The restart mechanism only applies to the Muon lr group; Adam aux groups retain the existing flat schedule.

**Concrete hparams:**
- Muon: T_0=600, T_mult=2, eta_min=0.005*initial_lr, terminal linear decay last 10%
- AdamW aux groups: keep existing flat+linear schedule
- `train_steps = 3050` (slightly shorter than #20 to be a meaningful test)

**Run budget:** 2 seeds at 3050 for screening.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps.

**Failure mode:** Restarts cause late-training instability or the model re-enters a poor local basin after each restart, increasing final loss variance.

---

## H3: Schedule-Free Muon (Defazio et al. 2024)

**Family:** Schedule + Optimizer Mechanism

**Premise:** Defazio et al. (2024, "Schedule-Free Learning — A New Way to Train") showed that a Polyak-Ruppert–averaged iterate combined with a specific momentum-on-the-primal-iterate trick can match or exceed tuned cosine/linear schedules without any explicit LR schedule. The key insight is that learning-rate decay is equivalent (in some regimes) to iterate averaging: instead of decaying LR, you maintain a weighted running average of iterates where the weights increase over time. Applied to Muon: replace the linear decay with a schedule-free wrapper. The implicit averaging may produce a better final iterate than linear cooldown, especially for sharp loss landscapes. This is theoretically motivated by the online-to-batch conversion in stochastic optimization.

**What to implement:** Wrap the Muon update in a schedule-free primal-dual momentum scheme. The primal iterate `z` is updated via Muon; the returned `x = (1-c)*x + c*z` where `c` increases over time (Polyak-style). Use a constant LR throughout. Keep Adam aux groups as-is with their own schedule.

**Concrete hparams:**
- Muon LR: 0.035 (constant, no decay)
- Schedule-free beta: 0.95 (controls Polyak weighting speed)
- c_init = 0.01, c_final = 0.5 (linear ramp of mixing weight)
- Adam groups: keep existing schedule
- `train_steps = 3050`

**Run budget:** 2 seeds at 3050 for screening; if within 3.278, run 4 seeds.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps without any explicit decay schedule.

**Failure mode:** Without the long cooldown, the primal iterate doesn't converge to a sharp enough minimum in this loss landscape — schedule-free requires more steps to compensate, negating the step-count benefit.

---

## H4: Nesterov Momentum Correction in Muon (Extrapolation Before Orthogonalization)

**Family:** Optimizer Mechanism

**Premise:** The current Muon applies Nesterov momentum by blending `grad` and `momentum` before NS orthogonalization: `update = grad.lerp_(momentum, mu)`. This computes the Nesterov "lookahead" in the raw gradient space and then orthogonalizes the result. An alternative is to extrapolate in parameter space first (the classical Nesterov formulation), compute the gradient at the extrapolated point, and only then orthogonalize. The two are not equivalent when orthogonalization is nonlinear (as NS is). Extrapolation before orthogonalization is closer to Nesterov's original geometric interpretation of momentum as a second-order correction. This may improve convergence rate by a constant factor because the gradient used for the preconditioned update is evaluated at a more accurate future-point estimate.

**What to implement:** Before the optimizer step, temporarily update parameters to `p_lookahead = p - lr * mu * momentum_matrix` (in orthogonal update space), compute the gradient there, then run the standard NS + update. This requires storing the momentum in matrix form and one extra forward-backward pass per step — but wait, extra fwd-bwd is banned. Instead: implement the "dual form" of Nesterov for Muon where the momentum blending is done after NS, not before: `update = NS(grad); momentum = lerp(momentum, update, 1-mu); final = update + mu * momentum`. This is Nesterov on the orthogonal update rather than the raw gradient.

**Concrete hparams:**
- mu=0.95 (unchanged)
- Apply "post-NS Nesterov" to Muon blocks
- LR: 0.035, WD: 0.025
- `train_steps = 3050`

**Run budget:** 2 seeds at 3050.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps OR visible improvement in training loss slope vs baseline.

**Failure mode:** The post-NS Nesterov formulation is less stable than the pre-NS version because momentum accumulates in the orthogonalized space, amplifying noise.

---

## H5: Adaptive Newton-Schulz Iterations (Fewer/More NS Steps Based on Gradient Rank)

**Family:** Optimizer Mechanism / Preconditioner

**Premise:** The baseline runs 12 NS iterations regardless of layer size or spectral properties. Smaller or more isotropic gradient matrices converge to the polar factor faster and need fewer iterations; ill-conditioned matrices may benefit from more. This is analogous to how Chebyshev polynomials converge faster when eigenvalues are clustered. If we can identify which parameter groups are already well-conditioned (e.g., attention QKV projections) and reduce their NS iteration count, we save compute and potentially reduce the over-orthogonalization noise for well-conditioned layers. Conversely, the MLP weights which are empirically more anisotropic may benefit from more iterations. This is "adaptive orthogonalization" — matching computational budget to per-layer preconditioning need.

**What to implement:** For each parameter group, compute the spectral norm convergence residual after NS and decide iteration count adaptively. In practice: set different `ns_steps` per group type (attn: 6 iterations, mlp: 12 iterations, proj: 8 iterations). Ablation: compare 6/12/8 vs the uniform 12. Also test 5 iterations for all layers as a compute-matched speedup.

**Concrete hparams:**
- Attn (q,k,v): ns_steps=6
- MLP fc/proj: ns_steps=12
- Residual projections: ns_steps=8
- LR: 0.035, WD: 0.025
- `train_steps = 3050`

**Run budget:** 2 seeds at 3050 for the layerwise split; 1 seed at 3050 for uniform-5 ablation.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps, or same loss at ≤ 2800 steps.

**Failure mode:** Fewer iterations for attention causes convergence degradation visible in training loss — the polar factor approximation for those layers is poor enough to hurt the update quality.

---

## H6: ADOPT (Tamaki et al. 2024) as Auxiliary Optimizer for Embed and LM Head

**Family:** Optimizer (Aux groups)

**Premise:** ADOPT (2024, Tamaki et al.) proves that Adam's convergence in non-convex settings is violated when the second-moment estimator `v_t` is computed with the current gradient rather than a delayed gradient. ADOPT fixes this by using `v_{t-1}` to compute the adaptive learning rate for `g_t`, restoring the convergence guarantee without changing the algorithm's spirit. In the current setup, the auxiliary Adam groups (embed, lm_head, scalars) use standard AdamW with fused=True. Replacing these with ADOPT costs zero extra memory and one minor code change, but may improve the effective LR adaptation for the embedding and projection matrices where the gradient distribution is less stationary (large vocabulary size, sparse updates). This is a principled fix to a known theoretical flaw in Adam.

**What to implement:** Implement ADOPT in-place of AdamW for the three auxiliary param groups. ADOPT: `m_t = beta1*m_{t-1} + (1-beta1)*g_t / max(v_{t-1}^0.5, eps)`, `v_t = beta2*v_{t-1} + (1-beta2)*g_t^2`, `p -= lr * m_t`. Keep Muon identical.

**Concrete hparams:**
- ADOPT betas: (0.9, 0.95) matching existing AdamW
- ADOPT eps: 1e-6 (slightly larger than 1e-10 — ADOPT is less sensitive to epsilon)
- embed lr: 0.3, lm_head lr: 1/320, scalars lr: 0.01 (unchanged)
- Muon: lr=0.035, wd=0.025 (unchanged)
- `train_steps = 3050`

**Run budget:** 2 seeds at 3050.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps; or match #20 with meaningfully reduced variance (tighter seed distribution).

**Failure mode:** The embed matrix has very sparse gradient updates (few tokens per batch relative to vocab=50304), and ADOPT's delayed denominator may not track the gradient scale well enough for sparse embeddings, causing the embed group to underfit.

---

## H7: MuLoCo-Style Outer Lookahead Directly on #20 Stack (Sync Interval Sweep)

**Family:** Meta-Optimizer / Outer Wrapper

**Premise:** Record #13 showed MuLoCo (outer Nesterov SGD over inner optimizer, sync every K=30 steps) on NorMuonH gave 3210 steps. Record #20 is on a stronger base (#16+Contra/Soft-Muon+tuned LR). Applying MuLoCo's outer step directly to #20's stack has not been tried. Lookahead-style methods (Zhang et al. 2019, Lookahead Optimizer) and MuLoCo both achieve similar effects: the outer SGD step "slow-walks" toward regions of lower loss variance, which can be interpreted as implicit SWA (Stochastic Weight Averaging) during training. At the current SOTA scale, even a small Lookahead improvement compounds via the pairwise significance formula. The key tuning question is sync_interval: shorter = more outer steps = more SWA effect but also more disruption to inner optimizer momentum.

**What to implement:** Wrap the full #20 optimizer stack with a Lookahead outer loop: every `sync_interval` steps, move all parameters toward the slow weights: `w_slow = w_slow + alpha * (w_fast - w_slow)`. Reset fast weights to slow weights. Try sync_interval in {20, 30, 50} and alpha in {0.5, 0.7}.

**Concrete hparams:**
- sync_interval: screen 30 first (matches #13's winning value), then 20 and 50
- alpha: 0.5 (start), 0.7 if underpowered
- Inner optimizer: exact #20 stack untouched
- `train_steps = 3050`

**Run budget:** 3 seeds at 3050 for sync=30 alpha=0.5; if promising, 3 more for best alt setting.

**Success criterion:** Val loss < 3.278 at ≤ 2980 steps (beat #20 by 50 steps).

**Failure mode:** The inner optimizer's Contra/Soft-Muon direction already incorporates a form of momentum correction that conflicts with the outer lookahead — the slow weights pull in a direction that degrades the inner preconditioner, causing training instability in the first 200 steps after each sync.

---

## H8: Per-Layer Learning Rate Scaling via muP-Inspired Width Initialization

**Family:** Parameterization / Initialization

**Premise:** Maximal Update Parameterization (muP, Yang et al. 2022) provides a principled prescription: as model width increases, learning rates for hidden layers should scale as 1/width to keep activations and gradients in a stable regime independent of model size. The current baseline uses a fixed LR of 0.035 for all Muon blocks regardless of layer shape. muP predicts that the attention QKV matrix (shape 768×768, fan_in=fan_out) should have a different LR than the MLP fc matrix (shape 768×3072). Specifically, for square matrices, muP predicts LR ∝ 1/d; for rectangular matrices LR ∝ fan_in/fan_out (or similar depending on the muP variant). Concretely, with model_dim=768 and mlp_dim=3072, the MLP weights should have ~4x lower LR than the attention weights in the standard muP prescription. The scaling factor `max(1, m/n)^0.5` in the current NS update partially addresses this (the "output scaling"), but not the full muP prescription.

**What to implement:** Add per-parameter-group LR scaling factors in the Muon optimizer, computed at init from parameter shapes. Use two groups: one for all "square-ish" params (attn: QKV, O proj), one for "wide" params (MLP fc, gate). Apply muP scaling: `lr_attn = base_lr`, `lr_mlp = base_lr * (768/3072)^0.5 = base_lr * 0.5`. Also retune `base_lr` since the overall effective LR changes.

**Concrete hparams:**
- `base_lr` sweep: {0.035, 0.04, 0.045}
- `lr_mlp = base_lr * 0.5`
- `lr_attn = base_lr`
- WD: 0.025
- `train_steps = 3050`

**Run budget:** 3 seed-1 screening runs across lr sweep; 4 seeds for best lr.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps; ideally pairwise statsig vs #20.

**Failure mode:** The NS orthogonalization already implicitly equalizes the effective learning rate across parameter shapes (by normalizing the update to have spectral norm ~1), so the muP LR scaling is partially redundant. The result may be no better than careful scalar LR retuning.

---

## H9: Ablation — Remove Contra-Muon, Keep Soft-Muon + SOAP (Simpler #20 Stack)

**Family:** Ablation / Stack Simplification

**Premise:** Record #20 stacks three novel mechanisms on top of SOAP-attn/MLP (#16): Contra-Muon (contrastive gradient direction), Soft-Muon (smooth interpolation between Contra and standard Muon), and a tuned LR schedule inherited from another source. The README notes p=0.34 for #16 vs #14 and marginal statsig for many stack components. When a stack accumulates components, there is risk of fragile interactions — any one component may be harmful under slightly different conditions, or two components may be partially redundant. This ablation identifies whether Contra-Muon's contribution is still positive on top of the current full stack. If Contra-Muon is removable, the simpler code reduces the chance of bugs and makes the next mechanism easier to test cleanly.

**What to implement:** Take the #20 script. Remove only the Contra-Muon component (set Contra interpolation weight to 0.0, keeping only Soft-Muon + SOAP). Keep all other hparams identical. Compare step count and loss to #20.

**Concrete hparams:**
- Contra-Muon interpolation: 0.0 (effectively standard Muon direction)
- Soft-Muon: kept as-is
- SOAP for attn + MLP: kept as-is
- LR schedule: kept as-is from #20
- `train_steps = 3050`

**Run budget:** 6 seeds at 3050 (needed for pairwise statsig detection).

**Success criterion:** If val loss >= #20 at equal steps, Contra-Muon is confirmed useful. If comparable or better without it, the stack is simpler and Contra-Muon is removed from future compositions.

**Failure mode (of the hypothesis, not training):** The ablation is inconclusive — the signal-to-noise ratio is too low to distinguish Contra-Muon's contribution at n=6, requiring a much larger seed count to reach pairwise statsig.

---

## H10: Eigenvalue-Normalized Weight Decay (Spectral WD)

**Family:** Regularization / Optimizer Mechanism

**Premise:** Standard weight decay penalizes the Frobenius norm of weights uniformly. For Muon-updated matrices, the relevant geometry is the spectral/nuclear norm (since the update lives on the Stiefel manifold after NS). Spectral weight decay — decaying weights proportionally to their current singular value spectrum — is a form of nuclear norm regularization. It preferentially decays large singular values, reducing effective rank and improving generalization. This connects to work on implicit regularization of gradient descent in matrix factorization (Gunasekar et al. 2017) and to the "spectral norm regularization" of Yoshida & Miyato (2017). In practice, spectral WD can be implemented cheaply using a power iteration estimate of the top singular value: `w = w - lr * swd * sigma_1 * u v^T` (the rank-1 update in the direction of the dominant singular pair). This is different from standard WD which decays all singular values equally.

**What to implement:** Replace the standard `w.mul_(1 - lr*wd)` Muon weight decay with spectral WD: compute the top singular vector pair via 1-2 power iterations, then apply `w -= lr * swd * sigma_1 * outer(u, v)`. This is cheap (2 matrix-vector products per step). Tune `swd` to be equivalent to the current WD in effect on average.

**Concrete hparams:**
- Spectral WD strength: sweep {0.025, 0.05, 0.1} (converted from Frobenius-equivalent)
- Power iteration steps: 2 (sufficient for a good rank-1 estimate)
- Muon LR: 0.035
- `train_steps = 3050`

**Run budget:** 2 seeds at 3050 for each of 3 swd values = 6 screening runs; best swd gets 4 seeds.

**Success criterion:** Val loss < 3.278 at ≤ 3000 steps; or statsig loss improvement at same steps vs #20.

**Failure mode:** Power iteration is noisy at batch level and provides an unstable rank-1 estimate that introduces high gradient variance, causing worse convergence than uniform WD. The theoretical benefit requires the weight matrices to be approximately low-rank, which may not hold in a 12-layer GPT at this scale.

---

## Summary Table

| # | Family | Mechanism | Expected Impact | Run Budget |
|---|--------|-----------|-----------------|------------|
| H1 | Schedule | Shorter cooldown (20%), warmup | Medium | 2 seeds × 3000 |
| H2 | Schedule | SGDR cosine restarts | Medium | 2 seeds × 3050 |
| H3 | Schedule+Opt | Schedule-Free Muon | Medium-High | 2 seeds × 3050 |
| H4 | Optimizer | Post-NS Nesterov | Low-Medium | 2 seeds × 3050 |
| H5 | Preconditioner | Adaptive NS iterations per layer | Low-Medium | 3 seeds × 3050 |
| H6 | Optimizer (aux) | ADOPT for embed/head/scalars | Low | 2 seeds × 3050 |
| H7 | Meta-Optimizer | MuLoCo/Lookahead on #20 stack | Medium-High | 3 seeds × 3050 |
| H8 | Parameterization | muP-style per-layer LR scaling | Medium | 3+4 seeds × 3050 |
| H9 | Ablation | Remove Contra-Muon from #20 | Diagnostic | 6 seeds × 3050 |
| H10 | Regularization | Spectral weight decay | Low-Medium | 6+4 seeds × 3050 |
