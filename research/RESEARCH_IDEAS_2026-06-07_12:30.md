# Research Ideas — 2026-06-07 12:30 UTC

**Context:** rank-1 baseline = 3.276193 (PR #2317: NC × Sinkhorn-Arbor × EMA-Nesterov γ=0.99 × RI capture=2375 γ=−0.075).
All proposed hypotheses are orthogonal to in-flight work (H-AT through H-AZ) and the 23 saturated levers.
4-tier gate for all hypotheses:
- T0 STRONG: ≤ 3.275793 → immediate merge
- T1 PROMISING: ≤ 3.276193 → merge, beats baseline
- T2 INCONCLUSIVE: (3.276193, 3.276593) → n=4 seed confirmation directed
- T3 FALSIFIED: ≥ 3.276593 → close

---

## H-BA — Sophia-G Diagonal Hessian on AdamW Parameters

**Motivation.**
The AdamW path (embed, lm_head, scalars) currently uses Adam's squared-gradient second-moment, which is a noisy proxy for curvature. Sophia-G (Liu et al., 2023) replaces this with a diagonal Gauss-Newton-Bartlett (GNB) estimate of the Hessian: every k steps, sample labels from the model's own softmax, compute the GNB gradient, and accumulate h_t = β₂·h_{t−1} + (1−β₂)·g_gnb². The update is then clipped to 1/max(γ·h_t, ε) rather than divided by √(v_t). Sophia is already beating AdamW on GPT-2 sized models at matched compute. The critical difference from Adam is that the denominator is a true curvature upper-bound, not a running squared-gradient; this prevents over-stepping along low-curvature directions. We implement only the Hutchinson variant (no model re-call required): draw a Rademacher vector v, compute (∂L/∂θ)·v via a single additional vector-Jacobian product using `torch.autograd.grad`, then h ≈ (g⊙Hv)/v ≈ g⊙v⊙Hv. This avoids the sampling-inside-optimizer constraint while keeping the Hessian signal.

**Specific code change.**

Add a `SophiaAdamW` class replacing `AdamW` for optimizer1. Key delta:

```python
# New CLI flags (add to argparse, no-op by default):
parser.add_argument("--sophia_k", type=int, default=0,
    help="Sophia Hessian update freq (0=disabled, suggested 10)")
parser.add_argument("--sophia_rho", type=float, default=20.0,
    help="Sophia clip threshold rho")
parser.add_argument("--sophia_beta2", type=float, default=0.99,
    help="Sophia Hessian EMA beta2")

# In optimizer1 group step (after grad is available, before weight update):
# Every sophia_k steps: compute Hutchinson hessian diagonal estimate
if sophia_k > 0 and (step % sophia_k == 0):
    v = torch.randint_like(p.grad, 2).float().mul_(2).sub_(1)  # Rademacher
    # Hvp: requires a second grad call — use the existing grad tape
    with torch.enable_grad():
        Hv = torch.autograd.grad(
            (p.grad * v).sum(), p, retain_graph=True
        )[0]
    state["hess"] = sophia_beta2 * state.get("hess", torch.zeros_like(p)) \
                  + (1 - sophia_beta2) * (v * Hv).abs()

# Replace Adam denominator:
# Standard Adam: update = m / (v.sqrt() + eps)
# Sophia: update = m / max(sophia_rho * state["hess"], eps).clamp_max(1.0)
```

Note: the Hutchinson estimator requires a second backward over the scalar `(g·v)`, which is cheap but requires `create_graph=True` on the first backward. Add `create_graph=(step % sophia_k == 0)` to the loss backward call.

**Arms (n=2).**
- Arm A: sophia_k=10, sophia_rho=20.0, sophia_beta2=0.99 (paper defaults)
- Arm B: sophia_k=5, sophia_rho=15.0, sophia_beta2=0.95 (faster Hessian refresh, lower threshold)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
SOPHIA_K=10 SOPHIA_RHO=20.0 SOPHIA_BETA2=0.99 \
python train_gpt_simple.py \
  --sophia_k 10 --sophia_rho 20.0 --sophia_beta2 0.99 \
  --wandb_group H-BA-sophia-g
```

**Implementation warnings.**
- The `create_graph=True` backward adds ~5–8% wall-time per step where it fires; with k=10 average overhead is <1%.
- If `retain_graph` is unavailable (gradient already freed), capture the Hvp before `.backward()` clears the graph.
- Sophia's h_t must be clipped to ≥ ε to prevent division by near-zero; use `clamp_min(1e-12)`.
- DO NOT apply Sophia to Muon params — Muon uses NS orthogonalization, not first/second moment division. Sophia is only for the AdamW (optimizer1) path.
- Sophia convergence can be brittle if rho is too large; if loss diverges at step ~200, halve rho first.

---

## H-BB — PSGD-Kron as SOAP Replacement on MLP Parameters

**Motivation.**
SOAP uses a Kronecker eigenbasis (row_gg/col_gg) updated by EMA and re-diagonalized every 10 steps. PSGD-Kron (Vyas et al., arXiv:2402.04553; Zhao et al., arXiv:2402.11858) instead maintains Lie-group preconditioners {L_i} via the constraint L L^T = (G G^T)^{−1} updated online by a rank-1 Newton step on each gradient. Unlike SOAP's eigendecomposition, PSGD-Kron never inverts a full matrix — it solves a small triangular system — and unlike Adam it adapts the full curvature tensor not just the diagonal. The key practical advantage: no damping hyperparameter (the update is self-regularizing through the Lie-group manifold constraint). In the current stack SOAP is active on all MLP params (SOAP_BLEND=1.0). Replacing it with PSGD-Kron tests whether a more principled Kronecker preconditioner can improve convergence beyond the SOAP plateau. Start from the reference implementation at github.com/lixilinx/psgd_torch.

**Specific code change.**

```python
# New CLI flags:
parser.add_argument("--psgd_kron", action="store_true", default=False,
    help="Replace SOAP with PSGD-Kron for MLP parameters")
parser.add_argument("--psgd_lr_scale", type=float, default=1.0,
    help="PSGD lr multiplier relative to Muon LR")

# In Muon.step(), replace the SOAP block for non-attn soap params:
if use_soap and not is_attn_soap and args.psgd_kron:
    # PSGD-Kron rank-1 preconditioner update (triangular, no eigendecomp)
    # state["Ql"], state["Qr"] = lower-triangular preconditioner factors
    if "Ql" not in state:
        state["Ql"] = torch.eye(p.size(0), device=p.device, dtype=torch.float32)
        state["Qr"] = torch.eye(p.size(1), device=p.device, dtype=torch.float32)
    G = momentum_update.float()
    # PSGD rank-1 Newton step: update Ql, Qr to satisfy QLG(QRG)^T = I
    # (simplified from github.com/lixilinx/psgd_torch/blob/master/psgd.py)
    A = state["Ql"] @ G @ state["Qr"].T
    invQlG = torch.linalg.solve_triangular(state["Ql"], G, upper=False)
    conjB = torch.linalg.solve_triangular(state["Qr"], G.T, upper=False)
    # rank-1 updates (lr_precond = 0.1 per PSGD paper)
    state["Ql"].sub_(0.1 * (A @ A.T - torch.eye(A.size(0), device=A.device)) @ state["Ql"])
    state["Qr"].sub_(0.1 * (A.T @ A - torch.eye(A.size(1), device=A.device)) @ state["Qr"])
    momentum_update = (state["Ql"].T @ state["Ql"] @ G @ state["Qr"].T @ state["Qr"]).to(momentum_update)
```

**Arms (n=2).**
- Arm A: psgd_kron=True, psgd_lr_scale=1.0, preconditioner lr=0.1 (paper default)
- Arm B: psgd_kron=True, psgd_lr_scale=0.8, preconditioner lr=0.05 (more conservative preconditioner, may be stabler)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
python train_gpt_simple.py \
  --psgd_kron --psgd_lr_scale 1.0 \
  --wandb_group H-BB-psgd-kron
```

**Implementation warnings.**
- PSGD-Kron memory cost: Ql is (d_out × d_out), Qr is (d_in × d_in). For MLP fc (768→4×768=3072): Ql=3072², Qr=768². This is ~11M + 589K float32 per layer × 12 layers = ~140M params overhead. May need to cap to Ql = I (scalar) for very wide layers or use PSGD-diagonal.
- If OOM: fall back to diagonal PSGD (state["h"] = EMA of diag(G^T G)).
- Do not zero out the NS orthogonalization — PSGD replaces SOAP's eigenbasis step but not NS. Keep the full muon_update pipeline.
- Preconditioner lr=0.1 is aggressive for a fixed-step regime. Monitor if Ql/Qr norms explode. Add a clamp: `state["Ql"].clamp_(-10, 10)`.

---

## H-BC — Spectral Radius Norm Targeting in muon_update

**Motivation.**
Line 918 of train_gpt_simple.py scales the NS-orthogonalized update by `max(1, rows/cols)**0.5`, a heuristic inherited from the original Muon paper to correct for asymmetry in rectangular matrices. This heuristic targets the Frobenius norm, not the operator norm (spectral radius). For the actual learning-rate meaning, what matters is the largest singular value of the update step — a matrix with large spectral norm moves parameters along their principal direction more aggressively than its Frobenius norm suggests. We propose replacing the fixed `rows/cols` heuristic with a power-iteration spectral norm estimate: 2–3 iterations of v → Gv/||Gv||, u → G^T u/||G^T u||, σ = u^T G v. This gives us a data-dependent scaling that normalizes the operator norm to a target σ_target (e.g. 1.0), rather than a shape-dependent heuristic. The overhead is minimal: two matrix-vector products per step, O(rows×cols) not O(rows²).

**Specific code change.**

```python
# New CLI flags:
parser.add_argument("--spec_norm_target", type=float, default=0.0,
    help="Spectral norm targeting in muon_update (0=disabled, suggest 1.0)")
parser.add_argument("--spec_norm_iters", type=int, default=3,
    help="Power iteration steps for spectral norm estimate")

# In muon_update(), replace line 918:
# OLD: update *= max(1, update.size(-2) / update.size(-1))**0.5
# NEW (when spec_norm_target > 0):
if spec_norm_target > 0:
    u = torch.randn(update.size(-2), device=update.device, dtype=update.dtype)
    u = u / u.norm()
    for _ in range(spec_norm_iters):
        v = update.mT @ u; v = v / v.norm().clamp_min(1e-8)
        u = update @ v;    u = u / u.norm().clamp_min(1e-8)
    sigma = (u @ update @ v).abs().clamp_min(1e-8)
    update = update * (spec_norm_target / sigma)
else:
    update *= max(1, update.size(-2) / update.size(-1))**0.5
```

**Arms (n=2).**
- Arm A: spec_norm_target=1.0, spec_norm_iters=3 (clean unit spectral-norm normalization)
- Arm B: spec_norm_target=0.7, spec_norm_iters=3 (slightly more conservative, matches approximate Frobenius-to-spectral ratio for near-orthogonal matrices)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
python train_gpt_simple.py \
  --spec_norm_target 1.0 --spec_norm_iters 3 \
  --wandb_group H-BC-spec-norm
```

**Implementation warnings.**
- Power iteration on a non-square update: ensure u has shape (rows,) and v has shape (cols,) for 2D matrices. For batched matrices (if any), use einsum or loop.
- The spectral norm estimate from 3 iterations is accurate to ~1% for matrices that aren't degenerate. Fewer iterations = faster but noisier scale.
- After applying the spectral target, the per-row second moment rescaling at lines 920-927 still runs. That rescaling is in Frobenius-norm space and remains valid — the spectral normalization just changes what the pre-SM update looks like.
- Do not combine with Arm B of H-BC if running alongside Aurora (which also rescales per D-diagonal). They conflict on the rescaling path.
- Quick smoke test: print `sigma` at step 0 for a few params; typical range for a 768×3072 matrix after NS should be 1.0±0.3.

---

## H-BD — Partial SAM on Muon Parameters Only (ρ=0.01)

**Motivation.**
Sharpness-Aware Minimization (SAM) finds flatter minima by perturbing weights toward the gradient ascent direction, computing the gradient at the perturbed point, then taking a descent step from the original weights. The standard concern here is 2× wall-time per step. We address this by applying SAM perturbation **only to Muon parameters** (12 blocks × 2 MLP weights + 4 attention weights = ~28 tensors, ~50M params out of ~87M total), skipping embed, lm_head, and scalars. The perturbation is applied in the gradient accumulation phase, reusing the existing distributed gradient communication. At ρ=0.01 the perturbation step is small enough that we do not expect numerical issues. This is a fixed-step benchmark (2890 steps), so what matters is flatness of the final basin relative to the per-step compute cost. Prior SAM literature shows the biggest gains on shorter-schedule overfit regimes — exactly our regime. We estimate ~35% wall-time overhead (not 2×) since AdamW params skip the perturb.

**Specific code change.**

```python
# New CLI flags:
parser.add_argument("--sam_rho", type=float, default=0.0,
    help="SAM perturbation radius on Muon params (0=disabled, suggest 0.01)")

# In training loop, replace:
#   loss.backward()
#   optimizer_ema.step()
# With (when sam_rho > 0):
loss.backward()
if sam_rho > 0:
    # Perturb Muon params toward gradient ascent
    muon_grads = {}
    for p in muon_params:
        g = p.grad.detach()
        g_norm = g.norm().clamp_min(1e-8)
        e_w = sam_rho * g / g_norm
        p.data.add_(e_w)
        muon_grads[id(p)] = (p.data.clone(), e_w)
    # Second forward-backward at perturbed point
    optimizer_ema.zero_grad()
    loss2 = model(inputs, targets)
    loss2.backward()
    # Restore Muon params, keep gradients from perturbed point
    for p in muon_params:
        _, e_w = muon_grads[id(p)]
        p.data.sub_(e_w)
optimizer_ema.step()
```

**Arms (n=2).**
- Arm A: sam_rho=0.01 (conservative, paper suggests 0.01–0.05 for language models)
- Arm B: sam_rho=0.005 (very small perturbation — reduces wall-time overhead, tests if signal survives at smaller ρ)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
python train_gpt_simple.py \
  --sam_rho 0.01 \
  --wandb_group H-BD-partial-sam
```

**Implementation warnings.**
- CRITICAL: SAM requires two forward-backward passes. Verify this does not violate the benchmark "no multiple forward-backward passes" contract. Read the benchmark rules before running. If the contract forbids it, H-BD must be skipped entirely.
- The gradient communication (all_reduce) must happen after the second backward, not the first. Wrap the perturb/second-backward inside the existing DDP no_sync context if applicable.
- `muon_params` = `[p for (n, p) in model.blocks.named_parameters() if p.ndim >= 2]` — exactly the Muon optimizer2 param set.
- Do not apply the SAM perturbation to SOAP-preconditioned params' state buffers — only the weights are perturbed, not the exp_avg_sq/row_gg/col_gg.
- Monitor wall-time per step in W&B. If overhead is >50%, reduce to Arm B only.
- If the benchmark contract forbids two forward passes, close this PR immediately and note the constraint.

---

## H-BE — EMA-Nesterov Lookahead Extended to AdamW Parameters

**Motivation.**
The EMA-Nesterov mechanism (−0.0028 contribution, the single largest lever) currently operates over ALL model parameters — embed, scalars, lm_head, and Muon weights — because `optimizer_ema = EMA_Nesterov([p for p in model.parameters()], ...)`. However, the lookahead_step and accum_lookahead functions reference ALL params in optimizer_ema.param_groups. The question is whether the EMA-Nesterov trajectory correction is *equally* beneficial for the AdamW path as it is for Muon. AdamW params have very different curvature structure: embed is a lookup table (sparse gradients), lm_head ties to embed, scalars are 1D. The EMA-Nesterov lookahead applies a momentum correction that assumes the inner optimizer's update direction is stable enough to extrapolate from. For sparse gradient params (embed), the EMA direction may be driven by frequent tokens and mislead on rare ones. This hypothesis tests whether **disabling** the EMA-Nesterov lookahead for AdamW params (only keeping it for Muon params) changes performance. If disabling it helps, it means the current lookahead is hurting AdamW convergence; if it hurts, it confirms that the mechanism is beneficial across all paths equally.

**Specific code change.**

```python
# New CLI flag:
parser.add_argument("--ema_muon_only", action="store_true", default=False,
    help="Apply EMA-Nesterov lookahead only to Muon params, skip AdamW params")

# In EMA_Nesterov.lookahead_step() and accum_lookahead():
# Add a param filter:
if ema_muon_only and p not in muon_param_set:
    continue  # skip embed, lm_head, scalars
```

The `muon_param_set` must be passed to `EMA_Nesterov.__init__` as an optional `restricted_params` argument. If `restricted_params` is not None, skip params not in that set during lookahead operations.

**Arms (n=2).**
- Arm A: ema_muon_only=True (Muon-only lookahead — diagnostic of whether AdamW coupling hurts)
- Arm B: Keep current (all params), but increase PREFILL_STEPS from 300 to 500 (give AdamW more warmup before lookahead kicks in — alternative view of the same concern)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
# Arm A:
python train_gpt_simple.py --ema_muon_only --wandb_group H-BE-ema-muon-only
# Arm B:
python train_gpt_simple.py --ema_prefill_steps 500 --wandb_group H-BE-ema-prefill-500
```

**Implementation warnings.**
- Arm A is a strict ablation/diagnostic: if it WINS, it means the EMA lookahead was hurting AdamW params all along. This would be a significant finding warranting follow-up on exactly which AdamW group (embed vs lm_head vs scalars) was the problem.
- Arm B changes PREFILL_STEPS from 300 to 500. Since REST_STEPS=1950, the active lookahead window shifts from [300, 2250] to [500, 2450]. This has a second-order effect on the RI capture step (capture=2375) — the lookahead state at capture changes. Flag this interaction in results.
- Do not change EMA_NESTEROV_GAMMA or EMA_NESTEROV_LOOKAHEAD in this experiment. Isolate the restriction to AdamW params only.

---

## H-BF — Gradient Signal-to-Noise Ratio Adaptive LR Scaling (SNR-Adam)

**Motivation.**
Current AdamW uses static per-group LR: embed=0.3, lm_head=1/320, scalars=0.01. These were tuned manually and have not been revisited since. Recent work (Kunstner et al., 2023; Cohen et al., 2022) shows that the gradient SNR — defined as ||E[g]||² / Var[g] per parameter — varies dramatically across training and across parameter groups. Parameters with low SNR (noisy gradients) benefit from LR reduction; parameters with high SNR can safely use higher LR. We implement a lightweight per-step SNR estimate using the existing second-moment state in AdamW: SNR_t = m_t² / (v_t − m_t²) (where m_t = first moment, v_t = second moment). A per-group adaptive LR multiplier is then: lr_effective = lr_base × clip(SNR_t.mean() / SNR_target, 0.1, 10.0). This is computed once per step, adds negligible overhead, and requires no additional state. The key insight: SNR-adaptive scaling orthogonally targets the *signal quality* of gradient estimates, which is separate from curvature (Sophia), geometry (PSGD/SOAP), or flatness (SAM).

**Specific code change.**

```python
# New CLI flags:
parser.add_argument("--snr_lr_scale", action="store_true", default=False,
    help="Adaptive LR scaling via gradient SNR for AdamW groups")
parser.add_argument("--snr_target", type=float, default=1.0,
    help="Target gradient SNR (default 1.0)")
parser.add_argument("--snr_clip", type=float, default=3.0,
    help="Max LR multiplier from SNR scaling")

# Inside AdamW step, after computing m_t and v_t, before weight update:
if snr_lr_scale:
    m_sq = exp_avg.square()
    bias_correction2 = 1 - beta2 ** step
    v_unbiased = exp_avg_sq / bias_correction2
    noise_var = (v_unbiased - m_sq).clamp_min(1e-10)
    snr = (m_sq / noise_var).mean().clamp(1e-4, 1e4)
    lr_multiplier = (snr / snr_target).sqrt().clamp(1/snr_clip, snr_clip)
    effective_lr = group["lr"] * float(lr_multiplier)
else:
    effective_lr = group["lr"]
# Use effective_lr in place of group["lr"] for this group's update
```

**Arms (n=2).**
- Arm A: snr_lr_scale=True, snr_target=1.0, snr_clip=3.0 (moderate adaptation)
- Arm B: snr_lr_scale=True, snr_target=0.5, snr_clip=5.0 (more aggressive scaling — allows larger LR when SNR is high)

**Decision gates.** Standard 4-tier as above.

**Reproduce command.**
```bash
python train_gpt_simple.py \
  --snr_lr_scale --snr_target 1.0 --snr_clip 3.0 \
  --wandb_group H-BF-snr-adam
```

**Implementation warnings.**
- SNR = m² / (v − m²) can blow up when v ≈ m² (near-deterministic gradients). The `clamp(1e-4, 1e4)` on snr prevents this. Early in training when m≈0, SNR≈0, so lr_multiplier → 1/snr_clip (minimum LR). This is correct behaviour — noisy early gradients should be conservative.
- Apply SNR scaling to each param group independently, not as a single scalar across all groups. Embed and lm_head have very different SNR profiles.
- Log `lr_multiplier` per group to W&B for diagnosis. If it stays near the clip boundary throughout training, the clipping range needs widening.
- This modifies the effective LR of optimizer1 (AdamW) groups only. Do NOT apply to Muon (optimizer2) — Muon uses NS orthogonalization, not first/second moment division, so SNR in the Adam sense is not defined there.
- If training diverges: the SNR estimate may be miscalibrated early. Add a warmup: only enable SNR scaling after step > 50.

---

## Summary of Priority Ranking

| Rank | ID | Mechanism | Expected impact | Risk | Wall-time overhead |
|------|-----|-----------|----------------|------|-------------------|
| 1 | H-BA | Sophia-G Hessian on AdamW | Replace noisy v_t with true curvature estimate | Medium (requires graph) | <1% with k=10 |
| 2 | H-BC | Spectral norm targeting in muon_update | Fix shape-heuristic with data-driven operator norm | Low (pure math change) | <1% (3 power iters) |
| 3 | H-BE | EMA-Nesterov scope diagnostic | Isolate whether AdamW lookahead hurts or helps | Low (ablation) | None |
| 4 | H-BF | SNR-adaptive LR scaling | Per-step per-group LR correction via gradient quality | Low (uses existing state) | Negligible |
| 5 | H-BB | PSGD-Kron replacing SOAP | More principled Kronecker preconditioner | High (memory risk) | ~3% per step |
| 6 | H-BD | Partial SAM (Muon only) | Flat minima via perturbation | High (contract risk, 35% overhead) | ~35% |
