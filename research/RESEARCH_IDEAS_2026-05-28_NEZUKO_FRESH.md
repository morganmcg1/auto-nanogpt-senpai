# Hypothesis: Per-Block NS Iteration Scheduling (Depth-Adaptive Whitening)

**Assigned to:** nezuko
**Date:** 2026-05-28
**Axis:** Newton-Schulz iteration count varied by transformer block depth (fresh — not in 228-PR history; PR #932 was proposed but never ran)

---

## What it is

Instead of applying a single global `NS_ITER=6` to every parameter in every block, assign a per-block Newton-Schulz iteration count that increases with depth. Early blocks (0–3) receive fewer NS iterations (e.g., 4), mid blocks (4–7) receive the current baseline (6), and late blocks (8–11) receive more iterations (e.g., 8). The deepest layers closest to the output — where gradient signal is most structured and where musoft init has already applied stronger down-scaling — receive the most precise whitening.

This is a targeted modification to `zeropower_via_newtonschulz5` and the `Muon` optimizer's parameter dispatch, with no changes to learning rates, weight decay, architecture, or the SOAP preconditioner path.

---

## Why it might help

The Newton-Schulz iteration count controls how closely the gradient update approximates a true orthogonal matrix (the Gram matrix of the gradient). Fewer iterations give a coarser approximation; more iterations converge closer to the true polar decomposition. The current global choice of 6 is a single compromise across all 12 transformer blocks.

There is a systematic asymmetry between early and late blocks: early blocks have smaller effective rank (the gradient lives in a lower-dimensional subspace due to fewer accumulated composition steps), while late blocks have higher effective rank and more structured curvature. Depth_init_mode=musoft already acknowledges this asymmetry by applying stronger weight scale suppression to later blocks via `1/sqrt(L)`. Applying more NS iterations to late blocks aligns whitening precision with the part of the network where (a) the gradient signal is most reliable and (b) the optimizer update direction matters most for the final loss.

The FFS bottleneck mechanism: the model needs to cross `val/loss = 3.28` at an earlier step. Late-block parameters determine the final logit distribution most directly. If their gradient updates are currently under-whitened (6 iterations vs. the convergence limit ~12), giving them 8 iterations provides a more orthogonal update direction — effectively a better-conditioned gradient step for the parameters with the highest direct impact on the loss. This is mechanistically distinct from the global ns_iter=6 confirmation (#497) and from per-group LR tuning.

---

## Code Changes

All changes are confined to `records/track_3_optimization/train_gpt_simple.py`.

### 1. Argparse — add argument near line 70 (after `--ns_iter`):

```python
parser.add_argument("--ns_iter_schedule", type=str, default="uniform",
                    help="NS iteration schedule by block depth: 'uniform' (all=NS_ITER), "
                         "'depth_up' (early=NS_ITER-2, late=NS_ITER+2), "
                         "'depth_down' (early=NS_ITER+2, late=NS_ITER-2). "
                         "Used to assign per-block NS iter counts in Muon.")
```

### 2. Modify `zeropower_via_newtonschulz5` (line 497) — add `ns_iter` parameter:

Current (line 497–514):
```python
def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(NS_ITER):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X
```

Replace with:
```python
def zeropower_via_newtonschulz5(G: Tensor, ns_iter: int = NS_ITER) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(ns_iter):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X
```

### 3. Modify `muon_update` (line 516) — add `ns_iter` passthrough:

Current:
```python
@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update
```

Replace with:
```python
@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True, ns_iter: int = NS_ITER):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update, ns_iter=ns_iter)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update
```

### 4. Modify `soap_ns_step` (line 525) — add `ns_iter` passthrough:

Current:
```python
@torch.compile
def soap_ns_step(nesterov_update):
    update = zeropower_via_newtonschulz5(nesterov_update)
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
    return update
```

Replace with:
```python
@torch.compile
def soap_ns_step(nesterov_update, ns_iter: int = NS_ITER):
    update = zeropower_via_newtonschulz5(nesterov_update, ns_iter=ns_iter)
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
    return update
```

### 5. Modify `Muon.__init__` (line 587) — build per-param NS iter mapping:

After the existing line `self.param_names = {id(p): n for n, p in all_named}` (around line 606), add:

```python
# Build per-param NS iteration map from block depth.
# Parameter names in model.blocks are "<block_idx>.<type>.<matrix>".
# Non-block params (embeddings, scalars) use global NS_ITER.
num_blocks = 12  # fixed GPT config
ns_schedule = getattr(args, "ns_iter_schedule", "uniform")
def _block_ns_iter(param_name: str) -> int:
    parts = param_name.split(".")
    try:
        block_idx = int(parts[0])
    except (ValueError, IndexError):
        return NS_ITER
    if ns_schedule == "depth_up":
        if block_idx < 4:
            return max(1, NS_ITER - 2)
        elif block_idx < 8:
            return NS_ITER
        else:
            return NS_ITER + 2
    elif ns_schedule == "depth_down":
        if block_idx < 4:
            return NS_ITER + 2
        elif block_idx < 8:
            return NS_ITER
        else:
            return max(1, NS_ITER - 2)
    else:  # "uniform"
        return NS_ITER
self.param_ns_iters = {id(p): _block_ns_iter(n) for n, p in all_named}
```

Note: `args` is available at module scope since `Muon.__init__` is called after `args = parser.parse_args()`. Alternatively, pass `ns_iter_schedule=args.ns_iter_schedule` as a constructor argument if preferred.

### 6. Modify `Muon.step()` (line 628) — use per-param ns_iter:

In the step loop, after `use_soap = p in self.soap_params`, add lookup:

```python
ns_iter = self.param_ns_iters.get(id(p), NS_ITER)
```

Then pass `ns_iter` through:
- SOAP path: `soap_ns_step(precond_nesterov, ns_iter=ns_iter)` (and `soap_ns_step(raw_nesterov, ns_iter=ns_iter)` for trust gate)
- Muon path: `muon_update(p.grad, state["momentum"], mu=group["mu"], ns_iter=ns_iter)`

---

## Important: `@torch.compile` behavior with int arguments

`torch.compile` re-specializes on distinct Python int values seen at trace time. With `NS_ITER=6`, the schedule `depth_up` will produce ns_iter values of {4, 6, 8} — three specializations per function. This is expected and safe. The first call for each value will trigger a short recompilation; subsequent calls with the same value use the cached specialized kernel. There is no correctness issue. The compile overhead is a one-time cost per value per function (~3 recompilations at startup).

---

## 5-Cell Sweep Design

All cells use the full R5 mandatory stack:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine`

| Cell | Flag | NS iter by block | Role |
|------|------|-----------------|------|
| A | `--ns_iter_schedule uniform` | 6/6/6 (0–3/4–7/8–11) | Control (reproduces R5 baseline exactly) |
| B★ | `--ns_iter_schedule depth_up` | 4/6/8 | Primary target: more whitening for late blocks |
| C | `--ns_iter_schedule depth_down` | 8/6/4 | Reverse: more whitening for early blocks (mechanistic falsifier) |
| D | (depth_up variant) | 5/6/7 | Softer depth_up signal if B shows directional gain |
| E | (depth_up extreme) | 3/6/9 | Stronger depth_up signal; expected either to amplify B's gain or show diminishing returns |

**Implementation note for Cells D and E:**
Cells D and E use the same `--ns_iter_schedule depth_up` flag but require modifying the `_block_ns_iter` thresholds. The simplest approach: add a `--ns_iter_delta` argument (default=2 for depth_up) that controls the ±offset:

```python
parser.add_argument("--ns_iter_delta", type=int, default=2,
                    help="NS iter delta for depth_up/depth_down schedules. "
                         "depth_up: late=NS_ITER+delta, early=NS_ITER-delta.")
```

Then Cell D: `--ns_iter_schedule depth_up --ns_iter_delta 1`
Cell E: `--ns_iter_schedule depth_up --ns_iter_delta 3`

This keeps Cells A-E structurally coherent. If the delta parameter is too much added complexity, Cells D/E can be hardcoded in separate if-branches.

---

## Mechanistic Expectations by Cell

**Cell B (depth_up, delta=2):** Late blocks (8–11) get 8 NS iterations — closer to the convergence limit of the quintic NS polynomial. The gradient update for these params is more orthogonal, meaning each optimizer step travels further in the loss landscape with less wasted curvature. If the FFS bottleneck is in late-block convergence speed, this directly addresses it.

**Cell C (depth_down):** Early blocks (0–3) get more whitening. If the bottleneck is actually in representation learning at the input side, Cell C should outperform Cell B. If Cell C is worse than A, the "depth_up helps" causal story is strengthened.

**Cell D (delta=1):** Softer version of B. If B wins but D loses, the effect requires a full ±2 shift. If D wins but B loses, the effect is real but non-monotone.

**Cell E (delta=3):** Late blocks get 9 NS iterations (only 3 more than the convergence limit estimate). This tests whether more iterations beyond 8 help further or saturate. If ns_iter=9 is already near full convergence of the polynomial, the marginal gain over 8 should be small.

---

## Pass/Fail Criteria (FFS-Primary Directive)

- **n=1 alive gate**: Cell B★ FFS ≤ 2975 before proceeding to n=4 confirmation
- **n=4 strict gate**: FFS mu_4 ≤ 2918.75, sigma_4 ≤ 12.5
- **Val secondary**: Report val loss but FFS gates all decisions
- **Stop condition at n=1**: If Cell B FFS > 2975, close. Check Cell C before closing if B fails — Cell C failing too closes the whole depth-adaptive whitening axis permanently.

---

## Pre-Mortems

**Pre-mortem 1: Cell B matches Cell A (FFS within 25 steps)**

The NS polynomial for the quintic used here (`a=2, b=-1.5, c=0.5`) converges within 4–5 iterations for well-conditioned gradients. If the gradient matrices in late blocks are already effectively orthogonalized at 6 iterations, adding 2 more iterations does nothing geometrically — the extra iterations multiply by a near-identity matrix. This is the most likely failure mode.

Diagnostic: Log `(X @ X.mT - I).norm()` at iteration 6 and 8 inside `zeropower_via_newtonschulz5` for late-block parameters. If the off-diagonal residual at iter 6 is already < 0.01, the axis is inert for this reason. If it is > 0.1, there is room for 8 iterations to help.

If B matches A: close. The NS polynomial is already converged at 6 iterations regardless of depth.

**Pre-mortem 2: Cell C outperforms Cell B (depth_down wins)**

This would indicate the bottleneck is in early-block feature extraction, not late-block output mapping. It would reverse the mechanism story but confirm that depth-adaptive whitening is directionally live. In this case: do not close. Instead, run n=4 on Cell C, and explore whether an extreme depth_down (delta=3 early blocks) pushes further.

**Pre-mortem 3: All cells match A within noise**

The FFS metric at 6 iterations may already be at the convergence floor of the NS polynomial for ALL blocks. In this case the entire ns_iter axis (both uniform and depth-adaptive) is exhausted. This is consistent with the global ns_iter sweep presumably already exploring values around 6 (the merged #497 tested ns_iter=6 as a winner over some alternative). If the convergence floor is reached, the axis is fully closed.

**Pre-mortem 4: `@torch.compile` recompilation causes training instability or incorrect gradients**

If torch.compile specializes incorrectly on the int argument — possible if the argument is passed as a tensor or if compilation happens before the value is resolved — the function may silently use a wrong ns_iter count. Diagnostic: log `ns_iter` values per block to W&B at step 0 to confirm the schedule is applied as intended.

---

## Suggested W&B Group

`--wandb_group nezuko-ns-iter-depth-r5`

---

## References

- Kosson et al. 2023, "Muon: An optimizer for hidden layers in neural networks" — original Newton-Schulz preconditioner in the Muon optimizer; confirms NS convergence properties for gradient matrices
- PR #497 (merged): ns_iter=6 global confirmation — establishes 6 as the current optimal global value, which this PR uses as the baseline per-group (uniform schedule = Cell A)
- PR #932 (never ran): "Per-layer NS iteration count scaled by transformer depth" — the original proposal for this axis; confirmed as open and unrun in experiment history
- PR #699 (merged): depth_init_mode=musoft — the prior depth-aware change that motivated looking at block depth as a structurally meaningful axis
