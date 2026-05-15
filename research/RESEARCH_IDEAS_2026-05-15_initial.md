# Research Ideas — auto-nanogpt-r2 Initial Wave
Generated: 2026-05-15

## Context and Constraints

- Benchmark: minimize optimizer steps to reach FineWeb val CE loss <= 3.28 on 12-layer,
  768-dim, ~125M param GPT.
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`; single run needs loss < 3.276.
- Current SOTA (public record #20): 3030 steps — Contra-Muon + Soft-Muon + SOAP-Muon stack.
- Baseline in training script: 3350 steps, plain Muon + AdamW.
- Key conversion: ~0.0045 val loss per 100 steps (from public history slope).
- Constraint: all optimizer code must be inline in the training script; no third-party
  optimizer packages for final claims.
- Constraint: no browsing upstream modded-nanogpt PRs, no Prime Intellect sources.
- One forward-backward per step; no per-run early stopping on val loss.

All ideas are scored as:
  - Priority: 1 (highest), 2, 3, 4 (lowest for this context)
  - Risk: low/medium/high
  - Estimated steps if it works: projected step target vs. 3030 SOTA

---

## IDEA 1 — Variance-Adapted Muon (adaptive-muon-var)

**Priority: 1. Risk: low.**

### Hypothesis

The Newton-Schulz5 (NS5) iterations normalize the gradient matrix spectrally (mapping
singular values toward 1) but do not adapt to per-row or per-column variance heterogeneity.
An ICLR 2026 matrix-whitening paper ("The Overlooked Ingredient") identifies variance
adaptation as the primary driver of SOAP's per-step gain over plain Muon — not the spectral
normalization itself. Adding cheap second-moment scaling (Adafactor-style row/col statistics)
before or after the NS5 step should capture most of SOAP's adaptive benefit at lower memory
and compute cost than running SOAP's full eigenbasis update.

### Mechanism

After the NS5 orthogonalization step, scale each row of the update matrix by the inverse
square root of its running EMA of squared row-norms. This is not new weight decay; it is a
per-row learning-rate-like scale that compensates for variance differences across parameter
"output neurons". Two variants:

- **Post-NS5 row scale**: apply after NS5, before the `max(1, rows/cols)^0.5` fan-out scale.
- **Pre-NS5 Adafactor**: apply Adafactor-style 2nd moment before NS5, so NS5 orthogonalizes
  the pre-conditioned gradient.

### Implementation sketch

```python
class MuonVarAdapt(torch.optim.Optimizer):
    def __init__(self, params, lr=0.035, weight_decay=0.025, mu=0.95,
                 var_beta=0.999, var_eps=1e-8, var_mode="post"):
        ...

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            for p in group["params"]:
                state = self.state[p]
                if len(state) == 0:
                    state["momentum"] = torch.zeros_like(p)
                    state["row_var"] = torch.ones(p.size(0), device=p.device)
                    state["step"] = 0
                state["step"] += 1
                beta2 = group["var_beta"]
                t = state["step"]

                # Nesterov momentum (same as Muon)
                momentum = state["momentum"]
                momentum.lerp_(p.grad, 1 - group["mu"])
                update = p.grad.lerp_(momentum, group["mu"])

                if group["var_mode"] == "pre":
                    # Pre-scale: compensate row variance before NS5
                    row_sq = update.square().mean(dim=1)  # (rows,)
                    state["row_var"].mul_(beta2).add_(row_sq, alpha=1 - beta2)
                    bc = 1 - beta2 ** t  # bias correction
                    row_scale = (state["row_var"] / bc + group["var_eps"]).rsqrt()
                    update = update * row_scale.unsqueeze(1)

                # NS5 orthogonalization
                update = zeropower_via_newtonschulz5(update)

                if group["var_mode"] == "post":
                    # Post-scale: adapt after NS5 (like per-row LR scaling)
                    row_sq = update.square().mean(dim=1)
                    state["row_var"].mul_(beta2).add_(row_sq, alpha=1 - beta2)
                    bc = 1 - beta2 ** t
                    row_scale = (state["row_var"] / bc + group["var_eps"]).rsqrt()
                    update = update * row_scale.unsqueeze(1)

                update *= max(1, p.size(-2) / p.size(-1))**0.5
                p.mul_(1 - group["lr"] * group["weight_decay"])
                p.add_(update, alpha=-group["lr"])
```

### Hyperparameter starting points

- `lr`: 0.035 (same as Muon baseline), then try 0.028, 0.042
- `weight_decay`: 0.025 baseline; tune after lr is set
- `var_beta`: 0.999 (slow EMA, tracks long-horizon variance)
- `var_eps`: 1e-8
- `var_mode`: try "post" first (safer, doesn't change NS5 input); then "pre"

### Expected step target

If the ICLR 2026 mechanism is correct, this should close 30-50% of the gap from plain Muon
to SOAP-Muon (~100-150 fewer steps than baseline), landing around 3100-3200 steps
on the plain Muon base, or potentially 2950-3000 steps if stacked with the full SOTA stack.

### Screening budget

400-500 steps is enough to see whether val loss trajectory diverges favorably from plain
Muon. Full confirmation at 3350 steps with 1 seed; then 4 seeds if it beats 3030.

---

## IDEA 2 — AdEMAMix-Style Dual-Momentum Muon (adamamix-muon)

**Priority: 1. Risk: medium.**

### Hypothesis

AdEMAMix (NeurIPS 2024, Pagliardini et al.) demonstrated that maintaining a slow EMA of
gradients alongside the fast EMA dramatically improves sample efficiency: on a 1.3B model
trained on 101B tokens, it matched AdamW at 197B tokens (+95%). The key insight is that
gradient signal for dense Transformer parameters remains useful far longer than the standard
momentum window captures, and discarding it wastes signal.

Muon currently uses a single Nesterov EMA with mu=0.95 (effective memory ~20 steps). Muon
operates on the matrix gradient as a unit, so its "memory" is entirely spectral. A dual-EMA
variant would maintain:
- Fast buffer: mu_fast=0.95 (standard Muon momentum, ~20 steps memory)
- Slow buffer: mu_slow=0.999 (very long-horizon, ~1000 steps memory)

The combined update blends these with a scalar alpha (slow contribution weight, typically
alpha=0.5 in AdEMAMix) before passing to NS5. Unlike AdEMAMix for Adam, this variant is
applied to the full matrix before spectral normalization, so the blending must preserve
matrix structure.

### Implementation sketch

```python
class MuonDualEMA(torch.optim.Optimizer):
    def __init__(self, params, lr=0.035, weight_decay=0.025,
                 mu_fast=0.95, mu_slow=0.999, alpha=0.5,
                 warmup_slow=300):
        # alpha controls slow-EMA contribution; warmup_slow avoids bias at start
        ...

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            for p in group["params"]:
                state = self.state[p]
                if len(state) == 0:
                    state["m_fast"] = torch.zeros_like(p)
                    state["m_slow"] = torch.zeros_like(p)
                    state["step"] = 0
                state["step"] += 1
                t = state["step"]
                warmup = min(1.0, t / group["warmup_slow"])

                # Fast EMA (standard Muon momentum)
                state["m_fast"].lerp_(p.grad, 1 - group["mu_fast"])
                # Slow EMA
                state["m_slow"].lerp_(p.grad, 1 - group["mu_slow"])

                # Nesterov fast update
                update_fast = p.grad.lerp_(state["m_fast"], group["mu_fast"])
                # Slow contribution (only mixed in after warmup)
                alpha_eff = group["alpha"] * warmup
                update = update_fast + alpha_eff * state["m_slow"]

                # NS5 on the combined update
                update = zeropower_via_newtonschulz5(update)
                update *= max(1, p.size(-2) / p.size(-1))**0.5
                p.mul_(1 - group["lr"] * group["weight_decay"])
                p.add_(update, alpha=-group["lr"])
```

### Hyperparameter starting points

- `mu_fast`: 0.95 (unchanged from Muon)
- `mu_slow`: 0.999 (AdEMAMix default); try 0.9999 for longer runs
- `alpha`: 0.5; try 0.1, 0.3, 0.5, 1.0 in screening
- `warmup_slow`: 300 steps (prevent slow buffer bias early on)
- `lr`: 0.035 baseline; may need to reduce to 0.025 with stronger slow EMA

### Known risks and failure modes

- The slow EMA adds memory: one extra tensor per block weight (~2x Muon buffer memory).
  At 125M params this is tolerable.
- At very long training lengths the slow EMA dominates; at 3000-step runs the slow buffer
  only accumulates ~3 full decay cycles. This limits the signal available, so the effect
  may be smaller than the 100B-token results in AdEMAMix. However, even partial benefit
  is worth capturing.
- The "Connections" paper (ICLR 2026 under review) identifies that Simplified-AdEMAMix
  (a single EMA with alpha incorporated into the beta formula) may suffice and avoids a
  separate buffer. Worth trying as a simpler variant if the dual-buffer version is
  noisy.

### Expected step target

Modest improvement expected: 3000-3100 steps on plain Muon base. If stacked with SOTA
3030 base: potentially 2900-2980 steps.

### Screening budget

500 steps is sufficient to see whether the slow buffer helps. A clear upward or downward
divergence from baseline Muon at steps 1000-2000 would be diagnostic.

---

## IDEA 3 — PSGD Kron (psgd-kron-baseline)

**Priority: 1. Risk: low.**

### Hypothesis

PSGD (Preconditioned SGD, Liao 2024) uses a Kronecker-factored preconditioner with a
closed-form update rule (no eigendecomposition). Unlike SOAP or Shampoo, PSGD Kron
updates the preconditioner every step and uses a coordinate-descent rule that avoids
inversion. The modded-nanogpt README explicitly suggests it with lr=0.0005, wd=0.625.
This is a direct author suggestion backed by external evidence; it should be one of the
first new optimizer mechanisms tried.

PSGD Kron can replace Muon for the block 2D parameters. The preconditioner factors
(Q_a, Q_b for a matrix of shape (m, n)) are updated using:
  dQ = (G @ Q_b) @ (G @ Q_b)^T * Q_a - Q_a^{-T}
  (coordinate descent in Lie group representation)

The final update is: `(Q_a^T @ Q_a)^{-1} @ G @ (Q_b @ Q_b^T)^{-1}` which is the
full Kronecker-preconditioned gradient.

### Implementation sketch

The canonical PSGD Kron implementation is ~100 lines inline. Key pieces:

```python
def psgd_update_precond_kron(Q_a, Q_b, dF_dG, lr_precond=0.1):
    """One step of the coordinate-descent Kronecker preconditioner update."""
    # Q_a is (m, m) upper triangular, Q_b is (n, n) upper triangular
    # dF_dG is gradient (m, n)
    A = Q_a @ dF_dG @ Q_b.T        # (m, n) preconditioned direction hint
    # Update Q_a
    AAT = A @ A.T
    Q_a_update = AAT @ Q_a - torch.triu(torch.linalg.solve_triangular(
        Q_a.T, torch.eye(m, device=Q_a.device), upper=False).T)
    Q_a.sub_(lr_precond * Q_a_update)
    # Update Q_b (symmetric)
    ATA = A.T @ A
    Q_b_update = ATA @ Q_b - torch.triu(torch.linalg.solve_triangular(
        Q_b.T, torch.eye(n, device=Q_b.device), upper=False).T)
    Q_b.sub_(lr_precond * Q_b_update)
    # Return preconditioned gradient
    return Q_a.T @ Q_a @ dF_dG @ Q_b @ Q_b.T
```

Memory: two triangular factors per parameter matrix, O(m^2 + n^2). For 768x768 blocks
that's 2x768x768x4 bytes = ~4.5MB per block — manageable.

### Hyperparameter starting points

Per README suggestion:
- `lr`: 0.0005 (much lower than Muon; PSGD units are different)
- `weight_decay`: 0.625
- `lr_precond`: 0.1 (preconditioner update rate)
- Use the `cooldown_frac=0.7` linear decay schedule unchanged.

These README-suggested values should be taken seriously as a starting point.

### Expected step target

README implies competitive with or better than Muon. If the suggestion is correct,
this could land anywhere from 3000-3200 steps. The key unknown is whether the 4x bigger
preconditioner memory translates to meaningful per-step improvement at this scale.

### Screening budget

600-800 steps to see convergence direction. Full 3350 steps for confirmation.

---

## IDEA 4 — Lookahead Wrapper with Adaptive Sync Interval (lookahead-adaptive)

**Priority: 2. Risk: low.**

### Hypothesis

Lookahead (Zhang et al. 2019) interpolates "slow" weights toward "fast" weights every k
steps using a step size alpha (typically alpha=0.5, k=5-10). It has been shown to reduce
variance in Adam/SGD settings and can improve final convergence. Applied as a wrapper over
the full optimizer (Muon + AdamW), it adds no architectural change and is trivially
correct.

Lookahead has not been tried in the modded-nanogpt context (absent from the public record).
The risk is that Muon's NS5 step already provides a form of gradient smoothing, so Lookahead
may be redundant. However, the slow-weight interpolation is a different mechanism (parameter
space smoothing vs. gradient space smoothing), and the combination may improve stability
during the long cooldown phase.

An adaptive variant: start with k=5 during stable phase, switch to k=10 during cooldown
to encourage smoother convergence to the flat minimum.

### Implementation sketch

```python
class Lookahead(torch.optim.Optimizer):
    def __init__(self, base_optimizer, k=5, alpha=0.5):
        self.base_optimizer = base_optimizer
        self.k = k
        self.alpha = alpha
        self._step_count = 0
        # Store slow weights
        self.slow_params = []
        for group in base_optimizer.param_groups:
            slow_group = []
            for p in group["params"]:
                slow_group.append(p.data.clone())
            self.slow_params.append(slow_group)

    @torch.no_grad()
    def step(self):
        self.base_optimizer.step()
        self._step_count += 1
        if self._step_count % self.k == 0:
            for group_idx, group in enumerate(self.base_optimizer.param_groups):
                for p_idx, p in enumerate(group["params"]):
                    slow = self.slow_params[group_idx][p_idx]
                    slow.add_(p.data - slow, alpha=self.alpha)
                    p.data.copy_(slow)

    # Delegate param_groups to base optimizer
    @property
    def param_groups(self):
        return self.base_optimizer.param_groups
```

Wrap both optimizer1 and optimizer2:
```python
optimizer1 = Lookahead(AdamW(...), k=5, alpha=0.5)
optimizer2 = Lookahead(Muon(...), k=5, alpha=0.5)
```

### Hyperparameter starting points

- `k`: 5 (standard Lookahead); try 5, 10
- `alpha`: 0.5 (standard); try 0.3, 0.5, 0.8
- The wrapping is transparent; keep all Muon/AdamW hyperparameters at their current values.

### Expected step target

Conservative improvement: 3100-3250 steps on the plain Muon baseline. Small potential gain.

### Screening budget

500 steps is sufficient. If the val loss curve is not measurably below the unwrapped baseline
by step 1000, this direction is not promising.

---

## IDEA 5 — Power-Law Cooldown Schedule (powerlaw-cooldown)

**Priority: 1. Risk: low.**

### Hypothesis

The current schedule uses linear cooldown starting at step `(1-0.7)*train_steps = 30%` of
training and decaying over the remaining 70% (`eta = (1-progress)/cooldown_frac`). This is
a linear ramp from 1.0 to 0.0 over ~70% of steps.

Recent literature (e.g., cosine annealing with restarts, polynomial decay) suggests that the
exact shape of the cooldown curve interacts non-trivially with optimizer momentum states.
Power-law cooldown (`eta = ((1-progress)/cooldown_frac)^p` for p != 1) can be more or less
aggressive depending on p:

- p < 1 (e.g., 0.5): concave-up, fast initial drop, slow final convergence
- p > 1 (e.g., 2): convex, slow initial drop, aggressive final phase

The key hypothesis is that the optimal cooldown shape is not linear. In particular:
- p=0.5 (sqrt decay): front-loads the LR reduction, giving more "low-LR" time in the
  plateau phase. This often helps models that benefit from longer low-LR exploration.
- p=2.0 (quadratic): preserves high LR longer, then drops aggressively, useful when the
  model needs more time at high LR to escape suboptimal basins.

This is an isolated, cheap diagnostic experiment that touches no optimizer code at all.

### Implementation sketch

```python
def set_hparams(step, cooldown_frac=0.7, cooldown_power=0.5):
    progress = step / train_steps
    if progress < 1 - cooldown_frac:
        eta = 1.0
    else:
        frac_remaining = (1 - progress) / cooldown_frac  # linear from 1 to 0
        eta = frac_remaining ** cooldown_power  # power-law shape
    for opt in optimizers:
        for group in opt.param_groups:
            group["lr"] = group["initial_lr"] * eta
```

Three arms to screen:
1. `cooldown_power=0.5` (sqrt: aggressive early, gentle final)
2. `cooldown_power=1.0` (linear: current baseline)
3. `cooldown_power=2.0` (quadratic: gentle early, aggressive final)

Optionally add a fourth arm:
4. `cooldown_power=1.0` but start cooldown later at `cooldown_frac=0.5` (only 50% of
   steps in cooldown vs current 70%).

### Hyperparameter starting points

- `cooldown_power`: 0.5, 1.0 (baseline), 2.0
- `cooldown_frac`: 0.7 (unchanged to isolate the shape effect)
- All optimizer hyperparameters unchanged.

### Expected step target

The schedule shape could gain or lose 50-150 steps depending on the interaction with
momentum state. Since this is a zero-cost architectural change, the risk-reward ratio is
very favorable.

### Screening budget

Full 3350 steps needed (cooldown effects are not visible early). Run 3 arms in parallel,
each 1 seed. The best arm then gets 4 seeds for statsig confirmation.

---

## IDEA 6 — Stochastic Weight Averaging / Iterate Averaging (swa-muon)

**Priority: 2. Risk: low.**

### Hypothesis

Stochastic Weight Averaging (SWA, Izmailov et al. 2018) maintains a running average of
iterate checkpoints taken at regular intervals during training. It consistently improves
generalization by 1-2% on image tasks and was recently shown to help in language model
fine-tuning. The intuition is that the averaged iterate lies in a flat basin of the loss
landscape, which tends to generalize better than the endpoint of optimization.

In the speedrun context, the relevant question is whether the average iterate reaches 3.28
at an earlier step than the raw iterate. This is a form of "free" smoothing that costs
nothing except a buffer to store the running average. The SWA buffer is updated at every
val checkpoint (every 125 steps during main training, every 25 in the final 10%).

A simpler version is Polyak averaging (uniform running average from some start step), which
avoids choosing a snapshot interval.

### Implementation sketch

```python
# After model init, outside the training loop:
swa_model = {name: torch.zeros_like(p) for name, p in model.named_parameters()}
swa_count = 0
swa_start_frac = 0.5  # start averaging from 50% of train_steps

# In the validation section, before computing val loss:
if step / train_steps >= swa_start_frac:
    swa_count += 1
    for name, p in model.named_parameters():
        swa_model[name].mul_((swa_count - 1) / swa_count).add_(p.data / swa_count)

# For val loss computation, use swa_model weights:
# temporarily copy swa_model into model, compute val, then restore
if swa_count > 0:
    original_data = {}
    for name, p in model.named_parameters():
        original_data[name] = p.data.clone()
        p.data.copy_(swa_model[name])
    # ... compute val loss ...
    for name, p in model.named_parameters():
        p.data.copy_(original_data[name])
```

### Hyperparameter starting points

- `swa_start_frac`: 0.5 (start at halfway point); try 0.3, 0.5, 0.7
- `swa_interval`: every val step (simplest) or every 500 steps

### Expected step target

SWA is more likely to improve the final val loss quality than to reach 3.28 earlier.
Potential gain of 50-100 steps (~0.002-0.005 val loss at the endpoint) if the iterate
near the endpoint is noisy and the averaged model is smoother.

### Screening budget

Single full 3350-step run is the minimum; compare swa_val_loss vs raw val_loss at each
checkpoint.

---

## IDEA 7 — Improved Projection Layer Initialization (proj-init-tuning)

**Priority: 2. Risk: low.**

### Hypothesis

The current initialization zeroes all projection weights (`model.proj.weight`). This
includes both the output projection (lm_head) and attention output projections. Zero-init
for residual stream projections is a common practice for depth scaling stability.

However, the zero-init means the first gradient signal must "bootstrap" these weights from
zero, which can waste early training steps. An alternative is "small-scale random init"
(e.g., normal(0, 0.02/sqrt(num_layers)) as in GPT-2), which is equivalent to the approach
used in the Spectral Parameterization and muP literature.

Two sub-ideas:
1. Small random init for residual projections: `normal_(std=0.02 / num_layers**0.5)` for
   all `proj` weights instead of zero.
2. Per-layer geometric depth scaling: `normal_(std=C / (num_layers * depth_idx)**0.5)` where
   depth_idx is the layer index. This ensures deeper layers start smaller.

This is a pure initialization experiment — no optimizer changes.

### Implementation sketch

```python
for name, p in model.named_parameters():
    w = p.data
    if name.endswith("weight"):
        if "proj" in name:
            # Option 1: small random init with depth-aware scaling
            depth_match = re.search(r'blocks\.(\d+)', name)
            if depth_match:
                layer_idx = int(depth_match.group(1)) + 1
                std = 0.02 / (12 * layer_idx)**0.5  # depth-scaled
            else:
                std = 0.02 / 12**0.5  # for lm_head proj
            w.normal_(std=std)
        elif "embed" in name:
            w.normal_()
        else:
            w.normal_(std=0.33**0.5 / w.size(-1)**0.5)
```

### Hyperparameter starting points

- `std_scale`: 0.02 / sqrt(12) ≈ 0.00577 for uniform; or geometric per-layer
- Compare: zero (current) vs small random vs geometric depth-scaled

### Expected step target

Uncertain. The early training steps may benefit, but the effect may wash out by step 500.
If the init matters, could gain 50-100 steps. If it hurts (by adding noise to the
residual stream), val loss would be worse early but possibly recover.

### Screening budget

300-500 steps to see the early trajectory; full 3350 for confirmation.

---

## IDEA 8 — Muon with Cosine-Scheduled Momentum Warmup (muon-momentum-warmup)

**Priority: 2. Risk: low.**

### Hypothesis

The Muon baseline uses fixed mu=0.95 throughout training. AdamW momentum beta1 is fixed at
0.8. There is no rationale in the codebase for why these values are constant, and the
optimization literature suggests that momentum warmup (ramping from 0 or 0.5 up to the
target value in the first N steps) can help prevent early divergence and improve the quality
of the initial momentum estimate.

The mechanism is: early gradients are noisy and highly variable; a low initial momentum
means the update responds quickly to the current gradient rather than being polluted by
stale gradient directions. As the model enters a more stable regime, higher momentum
allows longer-horizon gradient accumulation and smoother updates.

Variant A: Cosine ramp from mu=0 to mu=0.95 over the first 200 steps.
Variant B: Step-scheduled mu (0.5 -> 0.9 -> 0.95 at steps 100, 300).

### Implementation sketch

```python
def set_hparams(step, cooldown_frac=0.7, mu_warmup_steps=200):
    progress = step / train_steps
    if progress < 1 - cooldown_frac:
        eta = 1.0
    else:
        eta = (1 - progress) / cooldown_frac
    
    # Momentum warmup for Muon
    if step < mu_warmup_steps:
        mu_eff = 0.95 * (1 - math.cos(math.pi * step / mu_warmup_steps)) / 2
    else:
        mu_eff = 0.95
    
    for opt in optimizers:
        for group in opt.param_groups:
            group["lr"] = group["initial_lr"] * eta
            if "mu" in group:  # Only Muon groups have 'mu'
                group["mu"] = mu_eff
```

The Muon class already passes `group["mu"]` to `muon_update`, so this change requires
modifying `muon_update` to accept a variable mu, which the current code already supports.

### Hyperparameter starting points

- `mu_warmup_steps`: 100, 200, 400
- `mu_start`: 0 or 0.5 (start value before warmup)
- `mu_end`: 0.95 (unchanged)

### Expected step target

Small improvement: 3100-3300 steps. The effect is likely to be largest in the first 20%
of training and may or may not propagate to the final val loss.

### Screening budget

500 steps is diagnostic; focus on whether the training loss is lower at step 500 compared
to baseline.

---

## IDEA 9 — Newton-Schulz Coefficient Optimization (ns-coeff-tuning)

**Priority: 2. Risk: low.**

### Hypothesis

The current NS5 iteration uses coefficients (a=2, b=-1.5, c=0.5) that were empirically
determined in the modded-nanogpt original codebase. These coefficients define the quintic
polynomial `f(x) = ax + bx^3 + cx^5` that approximates the sign function. The published
speedrun record uses these exact values with 12 iterations.

Two questions remain unexplored in the track record:
1. Are the published coefficients truly optimal for this problem, or were they set for a
   different convergence criterion?
2. Can we reduce the number of iterations (e.g., from 12 to 8 or 6) while maintaining
   update quality, saving wallclock time per step?

The paper "Sketchy: Memory-efficient Adaptive Regularization" (Feinberg et al. 2023)
shows that approximate matrix square-root operations with fewer iterations can still be
effective if the approximation error is bounded. Similarly, "SOAP" (Vyas et al. 2024)
runs eigenbasis updates only every B steps (default B=10) without catastrophic degradation.

Variant A: Re-optimize NS5 coefficients using closed-form polynomial fitting on the
singular value distribution of actual gradients (can be done offline).
Variant B: Reduce iterations from 12 to 8; measure val loss penalty (likely small if
the singular values are concentrated).
Variant C: Use NS5 iterations but with adaptive step count: run until convergence check
`||X @ X^T - I||_F < tol` instead of fixed 12 steps.

### Implementation sketch (Variant B: reduced iterations)

```python
def zeropower_via_newtonschulz5(G: Tensor, n_iters=8) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(n_iters):  # was hardcoded 12
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X
```

Compare n_iters=8, 10, 12 (baseline), 16 arms.

### Hyperparameter starting points

- `n_iters`: 8, 10, 12 (baseline), 16
- Coefficient optimization: fit (a, b, c) to minimize `||f(S) - sign(S)||` where S is
  the empirical singular value distribution from a 200-step baseline run.

### Expected step target

Reduced iterations saves ~1.5-2ms per step at 768-dim (rough estimate), which translates
to ~5-8 seconds over 3000 steps. This is a wallclock speedup rather than a step count
speedup — not directly measured by the benchmark's step-count metric. More relevant is
whether fewer iterations noticeably hurts per-step quality. If not, it frees compute budget
for other refinements.

Coefficient optimization: unknown, but could be worth 10-50 steps if the current
coefficients are suboptimal for this gradient distribution.

### Screening budget

200-300 steps is enough to diagnose iteration count sensitivity. Coefficient optimization
requires an offline analysis pass on gradient statistics.

---

## IDEA 10 — Gradient Clipping for Muon (muon-grad-clip)

**Priority: 2. Risk: low.**

### Hypothesis

The training script currently uses no gradient clipping. The Muon NS5 step inherently
bounds the update direction (it's an approximate orthogonal matrix times a fan-out scale),
but large gradient magnitudes still affect the momentum buffer. If a single batch produces
an outlier gradient, the momentum EMA can be corrupted for tens of steps.

Adding per-parameter or global gradient clipping before the Muon momentum update could
reduce this corruption. However, the effect of clipping on Muon is different from Adam:
Muon doesn't scale by gradient magnitude (after NS5), so clipping primarily affects the
momentum buffer quality rather than the update step size.

Two variants:
A: Clip raw gradient before momentum update: `grad = grad / max(1, grad.norm() / clip_val)`
B: Clip momentum buffer after update: only allow momentum to grow by at most `max_growth`
   relative to its current norm.

This is a diagnostic for whether gradient spikes are limiting progress.

### Implementation sketch

In `muon_update`:
```python
@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True, grad_clip=1.0):
    if grad_clip > 0:
        g_norm = grad.norm()
        grad = grad / g_norm.clamp(min=grad_clip) * grad_clip
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update
```

### Hyperparameter starting points

- `grad_clip`: 1.0, 2.0, 5.0 (or disabled)
- The clip is applied per-parameter, not globally.

### Expected step target

Small potential gain or no change. This is primarily a diagnostic for gradient spike
pathologies. If val loss curves show sudden spikes that recover over many steps, clipping
is likely helpful. Without such evidence this is low-priority.

### Screening budget

400 steps, comparing clipped vs unclipped. Check W&B `train/grad/max_abs` and
`train/grad/global_norm` metrics to diagnose whether spikes are present.

---

## IDEA 11 — Schedule-Free AdamW for All Groups (schedule-free-all)

**Priority: 2. Risk: medium.**

### Hypothesis

Schedule-Free optimization (Defazio et al. 2024, NeurIPS 2024) eliminates the need for
explicit LR schedules by embedding a Polyak-averaged iterate and an implicit acceleration
schedule into the optimizer update rule. It has been shown to match or exceed Adam+cosine
on language model pretraining (Defazio reports results on 1B-token GPT-2 scale).

Wave 1 (r2-tanjiro) tests Schedule-Free AdamW only for the aux optimizer groups (embed,
lm_head, scalars) while keeping Muon's schedule intact. This idea extends the test to
apply Schedule-Free as the LR scheduler for the Muon blocks as well — effectively removing
all `set_hparams()` calls.

The challenge: Muon updates are not Adam updates, and Schedule-Free was designed for SGD
and Adam. Applying Schedule-Free's iterate averaging and LR state to Muon requires care.
One approach is to wrap Schedule-Free as an outer iterate-averaging shell, not touching
the optimizer's internal update rule.

### Implementation sketch

```python
# Schedule-Free wrapper for Muon
# Maintains a slow-weights buffer z and fast-weights x
# At each step: update x with Muon, interpolate z toward x (Polyak averaging)
# For forward pass: use interpolated weights

class ScheduleFreeWrapper:
    def __init__(self, base_optimizer, lr, warmup_steps=500, beta=0.9):
        self.base = base_optimizer
        self.beta = beta
        self.warmup_steps = warmup_steps
        self._step = 0
        # z: slow-moving average
        self.z = [{name: p.data.clone() for name, p in...}]

    def step(self):
        self._step += 1
        c = (self._step - 1) / self._step  # Polyak weight
        # Update fast weights with base optimizer
        self.base.step()
        # Update slow weights
        for group in self.base.param_groups:
            for p in group["params"]:
                z = self.z_for(p)
                z.lerp_(p.data, 1 - c)
```

This is complex to implement correctly and may interact poorly with Muon's distributed
all-gather pattern. Risk is medium.

### Hyperparameter starting points

- `warmup_steps`: 500
- `beta`: 0.9 for the Polyak averaging
- Keep Muon lr=0.035 but disable the `set_hparams` decay.

### Expected step target

If it works: potentially 2900-3100 steps by eliminating the suboptimal manual schedule.
If it fails: likely worse by 100-300 steps due to the manual schedule being better tuned.

### Screening budget

800 steps needed to see whether the Schedule-Free trajectory is competitive with the
cooldown-scheduled baseline. Do not kill before step 1000 just because the mid-training
loss is higher (the Polyak average catches up late).

---

## IDEA 12 — Heavy-Tailed Adam for Embed and LM Head (heavy-tail-adam)

**Priority: 3. Risk: low.**

### Hypothesis

The embedding layer uses AdamW with eps=1e-10, which is extremely small. Very small eps
increases sensitivity to the magnitude of the second moment denominator, which can produce
unstable updates when the gradient variance is very low (e.g., for rarely-seen tokens).
The lm_head weight uses lr=1/320 ≈ 0.003125, which is very low.

"Heavy-ball" Adam variants (adjusting beta2 and eps) for the embedding and lm_head may
improve training stability early in the run, when the embedding gradients are sparse and
highly variable. Options:

A: Increase eps from 1e-10 to 1e-8 for embed and lm_head groups.
B: Change beta2 from 0.95 to 0.99 (longer 2nd moment EMA) for embed group.
C: Change embed lr from 0.3 to 0.6 (the embed table is in bfloat16 and may underfit
   early given its size: 50304 x 768 = ~38M params vs 12 layers of ~7M params each).

### Implementation sketch

```python
optimizer1 = AdamW([
    dict(params=[model.embed.weight], lr=0.3, betas=(0.8, 0.99), eps=1e-8, name="adam_embed"),
    dict(params=[model.proj.weight], lr=1/320, betas=(0.8, 0.99), eps=1e-8, name="adam_lm_head"),
    dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.01, name="adam_scalars")],
    weight_decay=0, fused=True)
```

Or more conservatively, only change eps:
```python
dict(params=[model.embed.weight], lr=0.3, betas=(0.8, 0.95), eps=1e-8, name="adam_embed"),
```

### Hyperparameter starting points

- `eps`: 1e-10 (baseline), 1e-8, 1e-6 for embed/lm_head
- `beta2`: 0.95 (baseline), 0.99 for embed

### Expected step target

Small effect; primarily affects early training stability. Possible gain of 25-75 steps if
the embed group is a bottleneck.

### Screening budget

300-500 steps. Check W&B `train/weight_param/embed*` and `train/grad_param/embed*` metrics
to see whether the embed is behaving normally in the baseline.

---

## IDEA 13 — Muon with Per-Layer Learning Rate Decay (muon-depth-lr)

**Priority: 2. Risk: low.**

### Hypothesis

muP (Maximal Update Parameterization, Yang et al. 2022) and its successors assign
per-layer learning rates scaled by the layer's fan-in to ensure consistent activation
and gradient scale across depth. In the current script, all Muon-covered block weights
use the same LR regardless of depth.

A simpler variant: scale LR by `1 / sqrt(layer_depth)` or `1 / layer_depth` for blocks
deeper in the network, on the intuition that later layers should update more conservatively
once the representation is established. This is analogous to the "depth scaling" used in
the original GPT-2 paper and in various ResNet initialization schemes.

Alternative: layer-wise adaptive rate scaling (LARS/LAMB style) applied within Muon.

### Implementation sketch

```python
block_params_by_layer = []
for layer_idx, block in enumerate(model.blocks):
    layer_params = [p for p in block.parameters() if p.ndim >= 2]
    lr_scale = 1.0 / (1 + layer_idx)**0.5  # or 1.0 / num_layers**0.5 for deepest layer
    block_params_by_layer.append(
        {"params": layer_params, "lr": 0.035 * lr_scale, "weight_decay": 0.025}
    )

optimizer2 = Muon(block_params_by_layer)
```

The Muon optimizer sorts params by size internally; this is compatible with per-group LR.

### Hyperparameter starting points

- `depth_scale_power`: 0.0 (uniform, baseline), 0.25, 0.5, 1.0
- `base_lr`: 0.035 (unchanged)
- Scale could apply to the deepest layer only (1/sqrt(12)) or gradually across all layers.

### Expected step target

Uncertain. Could be 50-150 steps if a layer-depth LR mismatch is present. Could also hurt
if the current uniform LR was implicitly optimal.

### Screening budget

400-600 steps. Look at the per-layer gradient norms (`train/grad_param/*`) in the baseline
first to understand whether there is a systematic depth gradient.

---

## IDEA 14 — MuLoCo-Style Outer Loop over Muon (muloco-outer)

**Priority: 2. Risk: medium.**

### Hypothesis

MuLoCo (Li et al. 2024) wraps a standard optimizer with an outer Nesterov SGD step that
takes a macro-step every K inner steps, using the difference between the current and
old weights as the "outer gradient". With K=1 and sync_interval=30, this is equivalent
to LocalSGD with Nesterov momentum. The modded-nanogpt README mentions it as a promising
direction.

The intuition: Muon's NS5 step orthogonalizes each parameter matrix independently.
MuLoCo's outer loop applies a global correction step that accumulates across the K inner
steps, acting as a second-order correction in parameter space. In the distributed setting
(8 GPUs), MuLoCo's outer sync step can replace or augment the all-reduce.

However, in the Muon setting, the distributed all-reduce already happens at every step
(each rank processes a subset of parameters, then all-gathers). MuLoCo in this context
would be an additional outer optimization over the standard inner step, not a replacement
for the all-reduce.

### Implementation sketch

```python
class MuLoCo:
    def __init__(self, inner_optimizer, outer_lr=0.9, K=5):
        self.inner = inner_optimizer
        self.outer_lr = outer_lr
        self.K = K
        self._step = 0
        self.old_params = {p: p.data.clone() for group in inner_optimizer.param_groups
                          for p in group["params"]}

    def step(self):
        self.inner.step()
        self._step += 1
        if self._step % self.K == 0:
            # Outer Nesterov step: params += outer_lr * (params - old_params)
            for group in self.inner.param_groups:
                for p in group["params"]:
                    delta = p.data - self.old_params[p]
                    p.data.add_(delta, alpha=self.outer_lr - 1)  # net: outer_lr * delta
                    self.old_params[p].copy_(p.data)
```

### Hyperparameter starting points

- `K`: 5 (outer step every 5 inner steps)
- `outer_lr`: 0.9, 1.0 (1.0 = no outer correction, equivalent to baseline)
- `inner_lr`: keep Muon's lr=0.035

### Expected step target

Uncertain, medium risk. Could gain 50-150 steps if the outer correction aligns with the
optimization landscape. Could hurt if it introduces oscillation.

### Screening budget

600-800 steps. Kill early if val loss diverges.

---

## IDEA 15 — Hyperball Constraint Isolated from MuonH Stack (hyperball-isolated)

**Priority: 2. Risk: low.**

### Hypothesis

The Hyperball constraint (from the MuonH / NorMuonH results in the public record) clamps
the ratio `‖update‖_F / ‖weight‖_F` to a minimum floor value (e.g., 0.35). This ensures
that even when the weight matrix has grown large (via weight accumulation), the per-step
update remains a meaningful fraction of the weight norm. It acts as an implicit per-layer
learning rate floor.

In the current SOTA stack (result #20, Contra-Muon + Soft-Muon), neither the hyperball
constraint nor NorMuon's variance adaptation is present. It was part of PR #11
(NorMuonH + Contra-Muon) which reached 3225 steps, inferior to the current SOTA.

Key question: was the hyperball constraint helpful or harmful when separated from the
NorMuon variance adaptation? The two were always combined in the public record. Testing
hyperball alone on the plain Muon baseline (or the SOTA 3030 stack) would answer this.

### Implementation sketch

```python
@torch.compile
def muon_update_hyperball(grad, momentum, weight, mu=0.95, nesterov=True,
                          hyperball_floor=0.35):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    
    # Hyperball constraint: ensure update/weight ratio >= floor
    w_norm = weight.norm()
    u_norm = update.norm()
    if w_norm > 0 and u_norm > 0:
        ratio = u_norm / w_norm
        if ratio < hyperball_floor:
            update = update * (hyperball_floor * w_norm / u_norm)
    return update
```

### Hyperparameter starting points

- `hyperball_floor`: 0.2, 0.35, 0.5
- Muon lr: 0.035 (unchanged)

### Expected step target

Unknown; previously was combined with NorMuon (+variance adaption). Isolated effect on
the plain Muon baseline could be 0-100 steps.

### Screening budget

400-600 steps. Compare against plain Muon. The primary diagnostic is whether the
weight/update ratio is actually below the floor in the baseline (check `train/weight/*`
and `train/grad/*` telemetry).

---

## Summary: Priority Stack

| Rank | Idea | Slug | Expected Step Target | Risk | Reasoning |
|------|------|------|---------------------|------|-----------|
| 1 | Variance-Adapted Muon | adaptive-muon-var | 3100-3200 alone; stackable | low | Directly targets ICLR 2026-identified bottleneck; clear mechanism; no extra params |
| 1 | PSGD Kron | psgd-kron-baseline | 3000-3200 | low | README-suggested with explicit hparams; fresh mechanism not in track record |
| 1 | Power-Law Cooldown | powerlaw-cooldown | 3100-3300 | low | Zero-cost schedule change; easy parallel screening |
| 1 | AdEMAMix Dual-Momentum Muon | adamamix-muon | 3000-3100 | medium | Strong NeurIPS 2024 external evidence; clear mechanism; higher memory cost |
| 2 | Lookahead Wrapper | lookahead-adaptive | 3100-3250 | low | Established technique; wraps transparently |
| 2 | Muon Per-Depth LR | muon-depth-lr | varies | low | Cheap and diagnostic; addresses possible systematic bias |
| 2 | Hyperball Isolated | hyperball-isolated | 0-100 gain | low | Disentangles previously confounded component |
| 2 | NS Coefficient Tuning | ns-coeff-tuning | diagnostic | low | Cheap; checks whether fixed coefficients are near-optimal |
| 2 | Schedule-Free All Groups | schedule-free-all | 2900-3100 | medium | Big upside; complex implementation |
| 2 | Momentum Warmup | muon-momentum-warmup | 50-150 gain | low | Easy to add; standard practice |
| 2 | SWA / Polyak Averaging | swa-muon | 50-100 gain | low | Free; tests iterate quality |
| 3 | Proj Layer Init Tuning | proj-init-tuning | 50-100 gain | low | Cheap diagnostic |
| 3 | Heavy-Tail Adam | heavy-tail-adam | 25-75 gain | low | Low upside; easy to try alongside others |
| 3 | Muon Gradient Clipping | muon-grad-clip | diagnostic | low | Mainly diagnostic value |
| 2 | MuLoCo Outer Loop | muloco-outer | 50-150 gain | medium | README-mentioned; needs careful implementation |

## Wave 2 Recommendation

Once Wave 1 returns its results:
1. If SOAP-Muon reproduction (r2-askeladd) confirms 3150 steps: immediately stack
   power-law cooldown and variance-adapted Muon on top of it.
2. If Contra-Muon reproduction (r2-alphonse) confirms 3030 steps: try AdEMAMix-Muon
   and PSGD Kron as independent alternatives.
3. Run NS coefficient tuning and hyperball isolation as fast diagnostics in parallel.
4. The schedule-free direction has medium risk but high potential — assign after the
   first Wave 1 result lands to avoid duplicate schedule work with r2-tanjiro and r2-fern.
