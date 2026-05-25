# Wave-3 Mechanism-Stack Hypotheses — auto-nanogpt-1gpu-r4
# Generated: 2026-05-16

## Context and constraint summary

- **Baseline**: 3275 steps, val=3.2766, n=2 (alphonse Muon² merged, PR #60)
- **Target**: `first_step_to_val<3.28` ≤ 3030 steps; stat-sig rule: (3.28 - mu)*sqrt(n) >= 0.004
- **Gap to close**: ~245 steps (~7.5% fewer optimizer steps); public record #20 is 3030
- **Plateau evidence**: 7 hyperparameter probes in wave 2 all landed +25–50 steps worse; local optimum confirmed
- **Strategy**: mechanism stacks, not hyperparameter sweeps
- **Hard constraints**: fixed data, batch size, architecture; 1 fwd/bwd per step; 1 GPU per node; ~7 hr per PR

---

## IDEA 1 — Polar Express polar decomposition for Newton-Schulz

### What it is

Replace the current NS=12 Newton-Schulz iteration in Muon² with the Polar Express algorithm (Amsel et al., ICLR 2026 Oral), which solves each step as a minimax optimization problem and converges faster both early and asymptotically.

### Mechanism

Newton-Schulz iterates the map `X ← 1.5*X - 0.5*X@X.T@X` (with scaling). This is a fixed-point iteration; it converges slowly early (gradient near I) and slow again late (near the polar factor). Polar Express avoids the fixed iteration by adaptively selecting the polynomial coefficients each step via a minimax saddle-point solve that minimizes the worst-case error given current spectral content. The result: same GPU kernel profile (only matmuls), but fewer iterations to reach the same orthogonality error. The paper reports 2–3× fewer iterations to a given approximation tolerance in transformer training.

### Why it might help here

NS=12 is load-bearing (NS=6 fails, tanjiro #75). That implies we are right at the iteration budget where quality degrades. Polar Express reaches better approximation quality at the same iteration count (or equal quality at lower count). Either way it improves the effective preconditioner quality per step, which should reduce steps to target. This is the most direct mechanism-quality improvement available for Muon without touching any other hyperparameters.

### Pseudocode sketch

```python
# Current NS iteration (simplified):
def newton_schulz_12(G):
    X = G / (G.norm() + 1e-7)
    for _ in range(12):
        A = X @ X.T
        X = 1.5 * X - 0.5 * A @ X
    return X * G.norm()

# Polar Express replacement:
def polar_express(G, iters=12):
    X = G / (G.norm() + 1e-7)
    for i in range(iters):
        # Solve alpha* = argmin_alpha max_sigma |alpha*f(sigma) - sigma|
        # f(sigma) = current polynomial applied to singular value sigma
        # Solution gives optimal (a, b) for next step: X <- a*X + b*X@X.T@X
        sigma_est = estimate_spectral_radius(X)  # cheap power iter or use norm
        a, b = polar_express_coefficients(sigma_est, step=i)
        A = X @ X.T
        X = a * X - b * A @ X
    return X * G.norm()

def polar_express_coefficients(sigma, step):
    # Closed-form from Amsel et al. Table 1, depends on current estimate
    # of singular value distribution; for uniform initialization use:
    a = 1.5 - 0.5 * sigma**2
    b = 0.5  # can be tuned per-step
    return a, b
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | Polar Express, iters=12 (drop-in, same budget) | Better preconditioner quality → fewer steps |
| B | Polar Express, iters=8 (lower budget) | Speed vs quality trade-off |
| C | Polar Express, iters=6 (same as failing NS=6) | Does better algorithm compensate? |
| D | Polar Express, iters=10, add spectral radius warm-start | Best quality with minor overhead |

### Compute cost vs baseline

Arm A: identical FLOP count, identical wall clock (same matmul ops). Arms B/C cheaper. Arm D adds ~3% for one power iteration per NS call. Within 7 hr budget for all 4 arms.

### Risk class

**Medium**. Strong theoretical grounding, drop-in replacement, no hyperparameter coupling. Risk: the closed-form coefficient table in the paper depends on initializing the singular value distribution estimate; approximation needed for a drop-in. Must implement correctly or falls back to NS behavior.

### Key references

- Amsel, Persson, Musco, Gower — "Polar Express: Navigating the Arctic of Optimization" (ICLR 2026 Oral). https://arxiv.org/abs/2503.01111
- Kosson et al. — "Analyzing and Improving the Training Dynamics of Diffusion Models" (NS iteration baseline discussion)

---

## IDEA 2 — SOAP preconditioning for AdamW auxiliary parameter groups

### What it is

Apply SOAP (Vyas et al., NeurIPS 2024) to the auxiliary parameter groups currently using vanilla AdamW (embed, lm_head, scalars). SOAP runs Adam in the slowly-rotating eigenbasis of the Shampoo preconditioner, achieving near-second-order preconditioning at a cost similar to Adam.

### Mechanism

Shampoo maintains Kronecker-factored curvature matrices L (left) and R (right) per weight matrix. Its update direction is L^(-1/2) G R^(-1/2). SOAP makes this tractable: maintain L and R with a slow update frequency (every K steps), compute their eigenbases via eigendecomposition (cheap when done infrequently), and run Adam in that rotated coordinate system. The result: Adam's cheap per-step cost but with gradient covariance-aware preconditioning. For lm_head and embed, whose gradients have strong cross-feature structure, this can substantially improve the effective conditioning compared to vanilla Adam.

### Why it might help here

The baseline uses Muon² for transformer blocks and vanilla AdamW for embed/lm_head. The gap to record #20 (3030) partly reflects better preconditioning of the aux groups. Block heterogeneity analysis (Zhang et al., NeurIPS 2024) shows lm_head and embed have dramatically different Hessian spectra than the inner blocks, so the single AdamW LR suboptimally serves them. SOAP targets precisely this weakness without touching Muon²'s NS pipeline.

### Pseudocode sketch

```python
class SOAPAux(torch.optim.Optimizer):
    def __init__(self, params, lr=1e-3, betas=(0.9, 0.999), precond_freq=50):
        super().__init__(params, dict(lr=lr, betas=betas))
        self.precond_freq = precond_freq

    def step(self):
        for group in self.param_groups:
            for p in group["params"]:
                g = p.grad
                state = self.state[p]
                if len(state) == 0:
                    state["step"] = 0
                    state["exp_avg"] = torch.zeros_like(p)
                    state["exp_avg_sq"] = torch.zeros_like(p)
                    # Shampoo factors (for 2D weights only)
                    if g.ndim == 2:
                        m, n = g.shape
                        state["L"] = torch.eye(m, device=g.device)
                        state["R"] = torch.eye(n, device=g.device)
                        state["Q_L"] = torch.eye(m, device=g.device)
                        state["Q_R"] = torch.eye(n, device=g.device)
                state["step"] += 1
                t = state["step"]
                b1, b2 = group["betas"]

                if g.ndim == 2 and t % self.precond_freq == 0:
                    # Update Shampoo factors
                    state["L"] = b2 * state["L"] + (1-b2) * g @ g.T
                    state["R"] = b2 * state["R"] + (1-b2) * g.T @ g
                    # Recompute eigenbases
                    _, state["Q_L"] = torch.linalg.eigh(state["L"])
                    _, state["Q_R"] = torch.linalg.eigh(state["R"])

                # Rotate gradient into eigenbasis
                if g.ndim == 2:
                    g_rot = state["Q_L"].T @ g @ state["Q_R"]
                else:
                    g_rot = g
                # Adam in rotated space
                state["exp_avg"] = b1 * state["exp_avg"] + (1-b1) * g_rot
                state["exp_avg_sq"] = b2*state["exp_avg_sq"] + (1-b2)*g_rot**2
                m_hat = state["exp_avg"] / (1 - b1**t)
                v_hat = state["exp_avg_sq"] / (1 - b2**t)
                update_rot = m_hat / (v_hat.sqrt() + 1e-8)
                # Rotate back
                if g.ndim == 2:
                    update = state["Q_L"] @ update_rot @ state["Q_R"].T
                else:
                    update = update_rot
                p.data -= group["lr"] * update
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | SOAP for embed+lm_head, precond_freq=50, lr=3e-4 | Standard SOAP config |
| B | SOAP for embed+lm_head, precond_freq=100, lr=3e-4 | Lower eigendecomp overhead |
| C | SOAP for embed+lm_head only, precond_freq=50, lr=1e-4 | Conservative LR |
| D | SOAP for embed+lm_head+scalars, precond_freq=50 | All aux groups |

### Compute cost vs baseline

Eigendecomposition of (d_model × d_model) = (768×768) every 50 steps: ~3% overhead. Arm D: ~5%. Within 7 hr budget for 3–4 arms.

### Risk class

**Medium-high**. SOAP is well-validated on standard benchmarks but not in the short-horizon speedrun setting. The precond_freq needs to be short enough to matter within 3000 steps. Key question: does aux-group preconditioning quality matter at this step budget?

### Key references

- Vyas, Morwani, Zhao, Shapira, Brandfonbrener, Janson, Kakade — "SOAP: Improving and Stabilizing Shampoo Using Adam" (NeurIPS 2024). https://arxiv.org/abs/2409.11321
- Zhang et al. — "Why Transformers Need Adam: A Hessian Perspective" (NeurIPS 2024). Block heterogeneity motivation.

---

## IDEA 3 — Contra-Soft momentum shaping on Muon² gradient

### What it is

Apply Contra-Soft momentum rescaling to the gradient before Muon²'s v-EMA computation. This rescales gradient directions by the inverse of recent conflict with accumulated momentum, suppressing oscillatory components without zeroing them.

### Mechanism

Standard EMA momentum accumulates all gradient components equally, including directions that conflict with the running average (negative inner product). Contra-Soft momentum (related to conflicting-gradient surgery) detects when the current gradient component conflicts with the current momentum direction and rescales that component by `(1 - conflict_score)^alpha`. This is softer than PCGrad (which projects out the conflicting component entirely) and thus preserves more gradient signal. Applied before NS orthogonalization, it means NS operates on a cleaner directional signal. This is different from gradient clipping (which controls magnitude, not direction conflict).

### Why it might help here

Record #20 on the public leaderboard explicitly names "Contra-Soft-Muon" as its first mechanism. This is strong empirical evidence that momentum direction shaping is valuable in this exact setting. The wave-2 plateau showed that tuning the magnitude (LR, clip) is exhausted; direction shaping targets a different axis of the update.

### Pseudocode sketch

```python
def contra_soft_momentum(grad, momentum, beta=0.95, alpha=1.0):
    """
    Rescale conflicting gradient components before EMA accumulation.
    grad: raw gradient G_t
    momentum: running EMA m_{t-1}
    Returns: modified gradient for EMA update
    """
    if momentum is None:
        return grad
    # Per-element conflict score in [-1, 1]
    # Positive = aligned, negative = conflicting
    conflict = (grad * momentum).sign()  # element-wise agreement sign
    # Rescale conflicting elements
    scale = torch.where(conflict < 0,
                        (1.0 - alpha * (-conflict).clamp(0, 1)),
                        torch.ones_like(grad))
    return grad * scale.clamp(min=0.0)

# In Muon² update:
# Before: momentum = beta * momentum + (1-beta) * grad
# After:
grad_shaped = contra_soft_momentum(grad, state["momentum"], alpha=0.5)
state["momentum"] = beta * state["momentum"] + (1-beta) * grad_shaped
# Then: NS orthogonalization proceeds on momentum as before
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | Contra-Soft alpha=0.5, applied to m before NS | Record #20 analogue |
| B | Contra-Soft alpha=1.0 (full suppression of conflict) | Stronger direction shaping |
| C | Contra-Soft alpha=0.25 (mild) | Conservative variant |
| D | Contra-Soft alpha=0.5 + apply to v-EMA also | Two-level shaping |

### Compute cost vs baseline

Elementwise operations only; <1% overhead. 4 arms comfortably within 7 hr.

### Risk class

**Medium-low**. Record #20 uses this explicitly (strong empirical prior). Main risk: exact implementation details not published; the pseudocode is a reconstruction from the mechanism description. May need an arm sweep to find the right alpha.

### Key references

- Yu et al. — "Gradient Surgery for Multi-Task Learning" (NeurIPS 2020). PCGrad, the hard version of gradient conflict resolution. https://arxiv.org/abs/2001.06782
- Liu et al. — "Conflict-Averse Gradient Descent for Multi-task Learning" (CAGrad, NeurIPS 2021). Soft variant with controllable conflict suppression.

---

## IDEA 4 — Lookahead meta-optimizer wrapping Muon²

### What it is

Wrap Muon² in Lookahead (Zhang et al., 2019): every k=5–10 inner steps, interpolate the fast weights toward the slow weights with alpha=0.5. This costs no extra forward/backward passes and is compatible with the 1 fwd/bwd constraint.

### Mechanism

Lookahead maintains a "slow" weight trajectory that takes exponential moving average steps in the direction the fast optimizer has been traveling. This stabilizes training in ravine-shaped loss surfaces — where Muon²'s aggressive NS updates cause oscillation across the ravine — while preserving the fast optimizer's exploration within each ravine. The outer loop adds a `slow = slow + alpha*(fast - slow)` correction every k steps with no gradient evaluation, so it is zero-overhead in terms of forward/backward count. Evidence: Lookahead consistently helps second-order and momentum-heavy optimizers on the same class of problems (Ranger = RAdam + Lookahead was competitive for 2–3 years).

### Why it might help here

Wave-2 results show Muon² overshoots slightly — all hyperparameter perturbations land worse, suggesting the optimizer is near but not quite at its best trajectory. Lookahead's interpolation step acts as a geometric regularizer on the weight path without changing the per-step update direction. Compatible with 1 fwd/bwd, no architecture changes. Previous assignment (askeladd, to be assigned) — verify this is not already in flight.

### Pseudocode sketch

```python
class LookaheadMuon(torch.optim.Optimizer):
    def __init__(self, fast_opt, k=5, alpha=0.5):
        self.fast_opt = fast_opt
        self.k = k
        self.alpha = alpha
        self._step = 0
        # Cache slow weights
        self.slow_weights = [
            [p.data.clone() for p in group["params"]]
            for group in fast_opt.param_groups
        ]

    def step(self):
        self.fast_opt.step()
        self._step += 1
        if self._step % self.k == 0:
            for group_idx, group in enumerate(self.fast_opt.param_groups):
                for p_idx, p in enumerate(group["params"]):
                    slow = self.slow_weights[group_idx][p_idx]
                    # Lookahead blend: slow += alpha * (fast - slow)
                    slow.add_(self.alpha * (p.data - slow))
                    # Sync fast weights back to slow checkpoint
                    p.data.copy_(slow)
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | k=5, alpha=0.5 (original paper defaults) | Reference config |
| B | k=10, alpha=0.5 | Slower slow-weight update |
| C | k=5, alpha=0.8 | More aggressive pull toward slow |
| D | k=6, alpha=0.5 (= every cooldown_frac/500 steps roughly) | Aligned with LR schedule |

### Compute cost vs baseline

Zero extra forward/backward. Copy ops every k steps: <0.5% overhead. 4 arms within 7 hr.

### Risk class

**Low-medium**. Lookahead is well-understood, widely validated, no hyperparameter interaction with NS. Main question: does it help this specific optimizer? If Muon² already has strong directional stability from NS, Lookahead may be neutral.

### Key references

- Zhang, Lucas, Ba, Hinton — "Lookahead Optimizer: k steps forward, 1 step back" (NeurIPS 2019). https://arxiv.org/abs/1907.08610
- Yong et al. — "Ranger: Synergistic combination of RAdam + Lookahead". Practical validation of Lookahead benefit with strong momentum optimizers.

---

## IDEA 5 — Per-block adaptive Newton-Schulz iteration budget

### What it is

Assign different NS iteration counts to different parameter blocks based on their gradient matrix aspect ratio and spectral properties, rather than using NS=12 uniformly for all Muon² blocks.

### Mechanism

Newton-Schulz convergence rate depends on the initial singular value distribution of the gradient matrix. For tall/narrow matrices (e.g., MLP in-projections), the gradient is often already closer to its polar factor than for wide/square matrices. Allocating NS=12 uniformly wastes iterations on blocks that converge in 6 and under-invests in blocks that need 15+. The `NANOGPT_NS_ITERS` env var (added in the merged baseline) already provides global control; extending it to per-block assignment is straightforward. The budget is chosen by the aspect ratio heuristic: `iters_block = max(6, min(16, 12 * (max(m,n)/min(m,n))^0.5))`.

### Why it might help here

Tanjiro #75 showed NS=6 fails globally and NS=8 is within noise. This means some blocks need ≥12 while others may be fine with 8. Uniform NS=12 over-invests in easy blocks and wastes compute that could be reallocated to the effective LR or step count. Per-block budgeting could improve average preconditioner quality at the same wall-clock cost (if easy blocks get fewer iters, hard blocks can get more within the same wall clock).

### Pseudocode sketch

```python
def ns_iters_for_shape(m, n, base=12):
    aspect = max(m, n) / min(m, n)
    # Taller matrices need more iters; wider less
    budget = int(base * (aspect ** 0.3))
    return max(6, min(18, budget))

# In Muon² update loop:
for name, param in model.named_parameters():
    if param.grad is None or param.ndim < 2:
        continue
    m, n = param.shape[-2], param.shape[-1]
    iters = ns_iters_for_shape(m, n)
    # Run NS with this many iters
    param_grad_orth = newton_schulz(param.grad, iters=iters)
    # ... rest of Muon² update
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | Per-block iters with aspect^0.3 scaling, base=12 | Reference |
| B | Per-block iters with aspect^0.5 scaling, base=10 | More aggressive differentiation |
| C | Fixed iters per block type: QKV=10, MLP=14, proj=12 | Manual assignment by known structure |
| D | Per-block + increase max to 20 (more budget for hard blocks) | Allow spending saved compute |

### Compute cost vs baseline

Net FLOP count may slightly decrease (easy blocks get fewer iters). Arm D adds ~10% FLOP but may reduce steps. Within 7 hr for 3 arms.

### Risk class

**Low**. Conservative change, no new hyperparameters to couple, grounded in known spectral theory. Risk: the aspect-ratio heuristic is an approximation of the true spectral convergence criterion; may need empirical calibration.

### Key references

- Bernstein, Newhouse — "Old Optimizer, New Norm" (2024). NS polynomial spectrum analysis. https://arxiv.org/abs/2409.20325
- Shazeer, Stern — "Adafactor" (ICML 2018). Adaptive matrix preconditioning motivation.

---

## IDEA 6 — Muon² applied to lm_head and embed (full unification)

### What it is

Apply Muon² (NS-orthogonalized momentum + v-EMA) to embed and lm_head, replacing their current AdamW group. This is the most radical unification — every parameter sees the same second-order-like update rule.

### Mechanism

Currently, only transformer block weight matrices (QKV, MLP, proj) are Muon²-trained; embed and lm_head use vanilla AdamW. This means the optimizer implicitly treats the output layer differently from all inner layers, even though lm_head (d_model × vocab_size) is a large matrix with similar gradient structure. The block heterogeneity analysis suggests lm_head has different Hessian structure, but it is still a matrix — NS orthogonalization could help or harm depending on whether the gradient polar factor is a good update direction for it. The experiment tests this directly.

### Why it might help here

Wave-1 experiment (thorfinn #77, Lion aux groups) showed Lion fails for aux groups. But Lion is not NS-based; it tracks momentum sign, not direction. Muon² applies NS, which preserves gradient rank structure differently. The theoretical argument: lm_head gradients are dominated by the vocabulary-frequency Hessian, which NS-normalization corrects for automatically. This is a distinct mechanism from what Lion tested.

### Pseudocode sketch

```python
# Current optimizer setup (simplified from train_gpt.py):
muon_params = [p for name, p in model.named_parameters()
               if p.ndim >= 2 and "embed" not in name and "lm_head" not in name]
adam_params  = [p for name, p in model.named_parameters()
               if p.ndim < 2 or "embed" in name or "lm_head" in name]

optimizer = Muon(muon_params, lr=0.035, ...)
aux_opt   = torch.optim.AdamW(adam_params, lr=3e-4, ...)

# Proposed: include embed and lm_head in Muon² group
# But: lm_head is vocab_size x d_model = 50257 x 768 — very tall matrix
# NS iteration on tall matrix: use transpose trick (operate on smaller dim)
muon_all = [p for name, p in model.named_parameters() if p.ndim >= 2]
scalar_params = [p for name, p in model.named_parameters() if p.ndim < 2]
optimizer = Muon(muon_all, lr=0.035, ...)
scalar_opt = torch.optim.AdamW(scalar_params, lr=3e-4)
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | Muon² for embed+lm_head, lr=0.035 (same as blocks) | Full unification |
| B | Muon² for embed+lm_head, lr=0.010 (lower for larger matrices) | Scale-corrected |
| C | Muon² for lm_head only, lr=0.020 | Incremental test |
| D | Muon² for lm_head only + separate lower LR, NS=8 (cheaper for tall matrix) | Budget-aware |

### Compute cost vs baseline

NS on vocab_size×d_model (50257×768): use transpose trick, operates on 768×768 Gram matrix — same cost as inner blocks. ~3–5% overhead for including two extra parameter groups. 4 arms within 7 hr.

### Risk class

**Medium-high**. thorfinn #77 showed aux group optimizer changes can fail badly (Lion failed). But the mechanism is different. Large vocab matrix may destabilize if NS normalizes away frequency-correcting scale; arm B/C provide fallback positions.

### Key references

- Kosson et al. — "Rotational Equilibrium: How Weight Decay Balances Learning Across Neural Networks" (ICLR 2024). Rotational invariance of inner blocks vs. non-invariance of embed. Explains why unification may or may not generalize.
- Jordan, Dimakis et al. — "Muon: Momentum + Newton-Schulz Orthogonalization" (2024, Karpathy's modded-nanogpt). Original Muon paper establishing aux group split.

---

## IDEA 7 — Gradient covariance warm-start via synthetic pre-step

### What it is

Before the first real training step, run 10–20 "ghost" forward/backward passes on a held-out batch to initialize Muon²'s v-EMA (second moment) to a better approximation of the true gradient covariance. This cold-start problem causes the first ~50 steps to use a poorly-initialized v (defaults to zero), which may misweight the NS input.

### Mechanism

Adam-style bias correction (#115, edward) addresses the cold-start denominator problem by rescaling v_hat. But bias correction is a scalar correction — it does not change the direction of v. If v is initialized at zero, the early EMA is dominated by whichever first gradient happens to come through, and v converges to its stationary value only after ~1/(1-beta2) ≈ 100 steps (for beta2=0.99). During those first 100 steps, NS is operating on a degraded second-moment estimate. A warm-start addresses the directionality problem that bias correction cannot.

### Pseudocode sketch

```python
# Before training loop:
model.train()
warmstart_steps = 15  # No weight updates, only accumulate v-EMA
for batch in islice(train_loader, warmstart_steps):
    x, y = batch
    with torch.no_grad():  # Or allow grad for v accumulation
        logits, loss = model(x, y)
    loss.backward()
    # Accumulate v-EMA without weight update
    for group in optimizer.param_groups:
        for p in group["params"]:
            if p.grad is not None:
                state = optimizer.state[p]
                beta2 = group.get("beta2", 0.99)
                if "v" not in state:
                    state["v"] = (1 - beta2) * p.grad.data**2
                else:
                    state["v"] = beta2 * state["v"] + (1-beta2) * p.grad.data**2
    optimizer.zero_grad()
# Now begin normal training — v is pre-warmed
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | 10 ghost steps, beta2=0.99 (baseline) | Minimal overhead |
| B | 20 ghost steps | Better covariance estimate |
| C | 50 ghost steps | Strong warm-start |
| D | 10 ghost steps + bias correction (complement to edward #115) | Stack with #115 |

### Compute cost vs baseline

Ghost steps are cheap — no weight update, only accumulate state. 15 steps ≈ 0.5% of total steps. Negligible. 4 arms within 7 hr. Note: step count for first_step_to_target metric counts training steps, not ghost steps — these must not be counted in the total.

### Risk class

**Low**. Minimal code change, easy to revert, addresses a theoretically clear cold-start problem. Main risk: the warm-start benefit may be captured already by bias correction (edward #115) — arm D distinguishes between them.

### Key references

- Reddi et al. — "On the Convergence of Adam and Beyond" (ICLR 2018). Cold-start analysis of Adam moment initialization. https://arxiv.org/abs/1904.09237
- Chen et al. — "Symbolic Discovery of Optimization Algorithms" (2023). Ghost-step warm-up used in Lion variants.

---

## IDEA 8 — Spectral norm regularization to stabilize high-rank NS updates

### What it is

Add a spectral norm penalty to the loss function for transformer block weight matrices during Muon² training. NS orthogonalization maximally spreads singular values — but if the gradient has a few dominant singular values, NS amplifies them before spreading, creating transient high-energy updates. A spectral penalty on W discourages singular value concentration.

### Mechanism

After NS, the update direction has orthogonal rows/columns and equal singular values — ideal for gradient flow. But the pre-NS gradient often has dominant singular values (e.g., from attention heads locking onto high-frequency vocabulary patterns). When NS amplifies these before normalizing, it creates large updates in the first ~50 steps. A spectral norm regularizer `lambda * ||W||_2` (the largest singular value) penalizes singular value concentration in the weight matrices themselves, creating a complementary pull toward well-conditioned weights that NS can update more smoothly. This is analogous to the relationship between weight decay (L2) and gradient conditioning.

### Pseudocode sketch

```python
# Compute spectral norm penalty for 2D weight matrices
def spectral_penalty(model, lambda_spec=1e-4):
    penalty = 0.0
    for name, p in model.named_parameters():
        if p.ndim == 2 and "embed" not in name:
            # Approximate largest singular value via power iteration (1 step)
            v = torch.randn(p.shape[1], device=p.device)
            v = v / v.norm()
            u = p @ v
            sigma_max = u.norm()
            penalty = penalty + sigma_max**2
    return lambda_spec * penalty

# In training loop:
loss = cross_entropy_loss(logits, targets)
loss = loss + spectral_penalty(model, lambda_spec=args.lambda_spec)
loss.backward()
optimizer.step()
```

### Hyperparameter arm matrix

| Arm | Change | Expected effect |
|-----|--------|----------------|
| A | lambda_spec=1e-5 | Mild regularization |
| B | lambda_spec=5e-5 | Moderate |
| C | lambda_spec=1e-4 | Stronger |
| D | lambda_spec=1e-5 + applied only to attn weights | Targeted |

### Compute cost vs baseline

Power iteration (1 step) per matrix per step: ~5–8% overhead. Arm D reduces to ~3%. 3 arms within 7 hr.

### Risk class

**Medium**. Spectral regularization is well-studied but the interaction with NS orthogonalization is novel. NS already spreads singular values in the update direction — if the weights are already reasonably conditioned, the penalty may compete with NS rather than complement it.

### Key references

- Yoshida, Miyato — "Spectral Norm Regularization for Improving the Generalizability of Deep Learning" (2017). https://arxiv.org/abs/1705.10941
- Miyato et al. — "Spectral Normalization for GANs" (ICLR 2018). Practical spectral norm for large matrices.

---

## Priority ranking and assignment recommendations

### Top-3 picks by expected-impact-per-implementation-cost

**1. Idea 3 — Contra-Soft momentum shaping** (highest impact/cost):
Record #20 names this mechanism explicitly. Implementation cost is minimal (elementwise ops in the momentum update). Tests a specific wave-2-diagnosed failure mode (direction vs magnitude). Even if the exact alpha value needs sweeping, arm A is a strong prior. Assign immediately as next wave-3 slot.

**2. Idea 1 — Polar Express polar decomposition** (high impact, medium cost):
Drop-in replacement for NS iterations with proven faster convergence. The only risk is implementing the coefficient table correctly. Same FLOP count as NS=12, so no budget concern. The fact that NS=12 is the load-bearing minimum (from tanjiro #75) means improving polar decomposition quality is directly on the critical path to fewer steps.

**3. Idea 2 — SOAP for AdamW aux groups** (medium-high impact, medium cost):
The gap between our 3275 and record #20's 3030 is partly attributable to better aux-group preconditioning. SOAP is the most principled improvement available here. Implementation is ~60 lines of new optimizer code, and precond_freq=50 gives enough updates within 3000 steps to matter.

### Decision tree for wave-3 assignments

```
If #115 (edward, bias correction) MERGES:
  → Assign Idea 3 (Contra-Soft) + can stack with Idea 7 (Arm D)
If #115 FAILS or CLOSES:
  → Assign Idea 7 (warm-start) as separate v-EMA diagnostic

If #117 (alphonse, trust-region) MERGES:
  → Assign Idea 1 (Polar Express) — both work on NS pipeline, stack cleanly
If #117 FAILS:
  → Assign Idea 5 (per-block NS budget) as cheaper NS diagnostic

When first idle student appears:
  → Assign Idea 3 (Contra-Soft) — lowest risk, highest empirical prior

When second idle student appears:
  → Assign Idea 1 (Polar Express) — strong theory, drop-in replacement

When third idle student appears:
  → Assign Idea 2 (SOAP aux groups) — targets aux group weakness

When fourth idle student appears:
  → Assign Idea 4 (Lookahead) — compatible wrapper, zero extra fwd/bwd

Hold Idea 6 (Muon for embed/lm_head) until after #77-failure context is better understood
  — check if bias-correction result changes the aux group story first

Hold Idea 8 (spectral penalty) for last — it tests an orthogonal mechanism
  and may compete with NS if weights are already well-conditioned
```

### Stop conditions

- If Contra-Soft (Idea 3) + Polar Express (Idea 1) both fail to beat 3275: revisit mechanism description of record #20 more carefully; the combination may require simultaneous application
- If SOAP (Idea 2) is neutral: aux-group preconditioning is not the bottleneck; focus entirely on Muon² main group improvements
- If Lookahead (Idea 4) is neutral or negative: stability is not the bottleneck; the plateau is structural, not oscillation-based
- If four mechanism experiments all fail: escalate to architecture-level changes (depth, width, attention mechanism, positional encoding) — these have not been probed at all in waves 1-3
