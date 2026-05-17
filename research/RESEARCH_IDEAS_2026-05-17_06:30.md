# Research Ideas — 2026-05-17 06:30

Generated for idle students: frieren, askeladd, edward
Base stack: Contra+SOAP-MLP+NS5 (PR #139), mean val=3.27648, ffs_mean=3118.75 @ train_steps=3175

---

## Hypothesis 1: `cosine-cooldown-shape` (for frieren)

### Mechanism
Replace the linear LR decay in the cooldown window with a cosine curve. The current schedule:
```
eta = (1 - progress) / cooldown_frac   # linear decay to 0
```
becomes:
```
t_frac = (progress - (1 - cooldown_frac)) / cooldown_frac
eta = 0.5 * (1 + cos(pi * t_frac))    # cosine decay to 0
```
This is a pure schedule-shape change — no new hyperparameters, no new memory, no changes to optimizer logic. The duration of the cooldown (cooldown_frac=0.70) remains fixed.

### Why it might help
The linear and cosine schedules have the same start (eta=1.0) and end (eta=0.0), but cosine concentrates LR at the beginning of the cooldown window and decelerates more steeply near the end. The validation loss curve descends steeply in the first ~100 steps of the cooldown; cosine shape keeps LR higher during that phase and reduces it faster in the final steps where the gradient signal is small. If the 3.28 threshold is crossed during early-to-mid cooldown (steps ~1000-1800), a cosine-shaped schedule will push FFS earlier than linear — exactly the metric that matters. PR #178 exhausted the cooldown_frac axis (duration); this tests the orthogonal axis of decay shape.

### Code change sketch (~5 lines in set_hparams)
```python
import math

def set_hparams(step, cooldown_frac=0.7):
    progress = step / train_steps
    if progress < 1 - cooldown_frac:
        eta = 1.0
    else:
        t_frac = (progress - (1 - cooldown_frac)) / cooldown_frac
        eta = 0.5 * (1 + math.cos(math.pi * t_frac))
    for opt in optimizers:
        for group in opt.param_groups:
            group["lr"] = group["initial_lr"] * eta
```
No other changes required.

### Risk
Very low. Pure schedule-shape swap. No new optimizer state, no new memory allocation, no numerical instability risk. Cannot cause NaN cascade (no changes to gradient computation). cooldown_frac=0.70 is proven stable.

### Decision criteria
Single-seed screen at train_steps=3175. Target: val ≤ 3.278 and FFS ≤ 3100 (matches NEZUKO Screen B performance). If val ≤ 3.277 → predeclare n=4. Compare FFS specifically against baseline 3118.75 — this hypothesis is FFS-targeted. If FFS is worse than baseline despite competitive val, hypothesis is falsified.

---

## Hypothesis 2: `lion-aux-groups` (for askeladd)

### Mechanism
Replace `torch.optim.AdamW` on all three auxiliary parameter groups (embed.weight, lm_head/proj.weight, scalar gains/biases) with a minimal Lion optimizer. Lion computes:
```
update = sign(beta1 * m + (1 - beta1) * g)
m = beta2 * m + (1 - beta2) * g
```
The key property is that Lion applies a sign-normalized update regardless of gradient magnitude — it is a different update family from Adam's second-moment-normalized updates. The MLP/attention 2D weights remain on Muon unchanged; this is a targeted swap of the auxiliary optimizer only.

### Why it might help
The embed.weight (50304×768) and lm_head/proj.weight (768×50304) have sparse, magnitude-variable gradients driven by token frequency distributions. AdamW normalizes these via a per-coordinate second-moment EMA, but the EMA takes time to warm up and tracks magnitude history that may be irrelevant to the current training regime. Lion's sign normalization is uniformly aggressive across all gradient magnitudes from step 1 — embedding rows that receive rare tokens get the same effective step size as frequent-token rows. This can accelerate early embedding specialization and push FFS down by shortening the initial loss descent. Scalar parameters (gains, biases) are low-dimensional and unlikely to matter, but Lion on them is harmless. LR must be calibrated: Lion typically converges at 3-10x lower absolute LR than Adam.

### Code change sketch (~25 lines)
```python
class Lion(torch.optim.Optimizer):
    def __init__(self, params, lr=1e-4, betas=(0.9, 0.99), weight_decay=0.0):
        defaults = dict(lr=lr, betas=betas, weight_decay=weight_decay)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self):
        for group in self.param_groups:
            b1, b2 = group["betas"]
            lr = group["lr"]
            wd = group["weight_decay"]
            for p in group["params"]:
                if p.grad is None:
                    continue
                g = p.grad
                state = self.state[p]
                if len(state) == 0:
                    state["m"] = torch.zeros_like(p)
                m = state["m"]
                update = (b1 * m + (1 - b1) * g).sign_()
                if wd != 0:
                    p.mul_(1 - lr * wd)
                p.add_(update, alpha=-lr)
                m.mul_(b2).add_(g, alpha=1 - b2)

# Replace optimizer1 with:
optimizer1 = Lion([
    dict(params=[model.embed.weight],   lr=3e-4,  name="lion_embed"),
    dict(params=[model.proj.weight],    lr=3e-5,  name="lion_lm_head"),
    dict(params=[p for p in model.parameters() if p.ndim < 2], lr=1e-2, name="lion_scalars")],
    betas=(0.9, 0.99), weight_decay=0)
```
Run a 200-step smoke first to verify finite loss and reasonable val trajectory (~4.0-4.2 at step 200 indicates healthy training). If embed loss diverges, reduce lion_embed LR to 1e-4.

### Risk
Medium. The primary risk is LR miscalibration — Lion's effective step is larger than it appears since sign() discards magnitude. The suggested LRs (3e-4 for embed, 3e-5 for lm_head) are derived from the Lion paper's 3-10x reduction heuristic applied to current AdamW LRs (0.3 and 1/320). If the smoke run shows divergence, halve the embed/lm_head LRs. The scalars group at lr=1e-2 is safe since those are small parameters with slow dynamics. No multi-seed NaN risk — Lion is sign-based and cannot amplify second-moment instability.

### Decision criteria
200-step smoke mandatory (val ≈ 4.0-4.2 = healthy; val ≥ 5.0 or NaN = abort and retune LR). Full screen at train_steps=3175. Target: val ≤ 3.278 and FFS improvement vs baseline. If FFS ≥ baseline ffs_mean=3118.75 despite good val, hypothesis is falsified (Lion on aux groups buys no early-training acceleration). If FFS clearly better, predeclare n=4.

---

## Hypothesis 3: `adaptive-ns-iters` (for edward)

### Mechanism
Vary the Newton-Schulz iteration count in `zeropower_via_newtonschulz5` based on the current training step. Rather than fixed 12 iterations throughout training, use more iterations early (when momentum matrices are maximally ill-conditioned) and fewer iterations late (when momentum is well-aligned and approximate spherization suffices). Proposed schedule:
- Steps 0-499:   16 iterations (maximum precision during initial loss descent)
- Steps 500-1999: 12 iterations (current behavior, stable phase)
- Steps 2000+:    8 iterations (late cooldown, momentum nearly converged)

The theoretical basis is that NS5 with polynomial (a,b,c=2,-1.5,0.5) converges quadratically to the unitary polar factor once the input is close to isometric; early in training the momentum buffer has large spectral spread and may need more iterations to reach the isometric regime, while late training the momentum is already well-conditioned.

### Why it might help
FFS is primarily determined by the quality of the first ~1000 steps of loss descent. Muon's fundamental operation is spherization of the gradient/momentum matrix via NS5 — the better the spherization, the more equal the step sizes across singular value directions, the faster descent in poorly-conditioned loss landscapes. Fixed 12 iterations was tuned as a global average; 16 iterations early costs ~33% more NS5 compute for the first 15% of training (trivial wall-clock, ~4-8 extra small matmuls per step) but may improve FFS by 20-50 steps by reducing the variance in effective step size across parameter subspaces during early descent. Late-phase reduction to 8 saves minor compute with negligible quality impact since the exponential moving average of momentum has already converged toward a well-conditioned subspace.

### Code change sketch (~12 lines, minimal refactor)
```python
def zeropower_via_newtonschulz5(G: Tensor, iters: int = 12) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1): X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(iters):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1): X = X.mT
    return X

# In Muon class, add:
def set_step(self, step: int):
    self._current_step = step

# In Muon.step(), replace the NS5 call with:
step = getattr(self, '_current_step', 0)
ns_iters = 16 if step < 500 else (12 if step < 2000 else 8)
update = zeropower_via_newtonschulz5(momentum_update, iters=ns_iters)

# In training loop, before optimizer2.step():
optimizer2.set_step(step)
```
Thread through `contra_normuon_update` if NS5 is called inside it: add `iters` parameter and pass `ns_iters` through.

### Risk
Low. More iterations early → tighter orthogonality, marginally reduces NaN risk vs current. Fewer late → slight approximation but empirically NS5 reaches singular values within 1% of unity by iteration 8 for well-conditioned inputs. No new optimizer state, no change to momentum EMA, no change to learning rate. Cannot cause multi-seed NaN cascade (same numerical range as current 12-iter).

### Decision criteria
Single-seed screen at train_steps=3175. Primary signal: FFS vs baseline 3118.75 — this hypothesis is purely FFS-targeted with val impact expected to be secondary (≤0.001 difference). If FFS ≥ baseline with no val improvement, hypothesis is falsified (iteration count does not matter in this regime). If FFS improves by ≥ 30 steps, predeclare n=4. Also log NS5 convergence diagnostics: add a `||X @ X.T - I||_F` check at iteration 8, 12, 16 at step 100 to verify that early training does have higher spectral spread (supports mechanism) or not (falsifies mechanism).

---

## Summary table

| Slug | Student | Mechanism axis | Risk | FFS hypothesis |
|---|---|---|---|---|
| `cosine-cooldown-shape` | frieren | LR decay shape (not duration) | Very low | Earlier 3.28 crossing in early cooldown |
| `lion-aux-groups` | askeladd | Aux optimizer family (sign-based vs moment-based) | Medium | Faster embed/lm_head specialization step 0-500 |
| `adaptive-ns-iters` | edward | NS5 iteration schedule (not fixed) | Low | Better spherization quality in step 0-500 |

All three target FFS through step 0-500 early-training quality, which is the primary gap (89 steps / 2.8%) from record #20 at 3030 steps. None modifies CONTRA_MUON (exhausted), cooldown_frac (exhausted), SOAP_BETA2 (being tested), or TARGET_UW (being tested).
