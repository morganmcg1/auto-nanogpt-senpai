# Research Ideas — 2026-05-29 14:15 UTC

## For: edward (immediate assignment after bilateral NULL on #1666)

---

## TOP RECOMMENDATION: AdaShift Temporal-Lag Second Moment on Aux Adam (n=1 vs n=2 bilateral)

### What it is

Replace the canonical PyTorch `AdamW` used for embedding/LM-head/scalar parameters (optimizer1) with a custom `AdaShiftAdamW` that computes the second moment using gradient **g_{t-n}** (a stale copy from n steps ago) instead of the current gradient g_t, eliminating the harmful correlation between the numerator and denominator of each Adam step.

### Mechanism class

Tier 2a — structural update-rule change to the aux optimizer. Not a scalar hyperparameter pulse.

### Novelty

Zero prior PRs on r1 that apply AdaShift or temporal-lag second-moment to aux Adam. PR #1354 on r2 is a different mechanism (time-lagged gradient for body Muon momentum, not aux Adam second moment) and a different branch. ADOPT-aux was closed on r1 after 2 attempts (as "ADOPT-aux (2)" in research state); AdaShift is a distinct mechanism that solves the same Adam bias problem via temporal shift rather than order-swap.

### Academic grounding

- **AdaShift (Xie et al., ICLR 2019, arxiv 1810.00143)**: Original paper proving that Adam's v_t = β₂·v_{t-1} + (1-β₂)·g_t² creates a step-size that is implicitly correlated with the sign of g_t, causing non-convergence in non-convex settings. Temporal shift by n steps (v_t ← β₂·v_{t-1} + (1-β₂)·g_{t-n}²) eliminates this correlation because g_{t-n} is independent of g_t when n ≥ 1. The resulting step is bounded and converges. Implementation requires only a small FIFO ring buffer of size n.
- **ADOPT (Taniguchi et al., NeurIPS 2024, arxiv 2411.02853)**: Solves the same Adam non-convergence problem via order-swap (normalize g_t by v_{t-1} before momentum accumulation). ADOPT is closed on aux in r1 after 2 attempts. AdaShift pre-dates ADOPT by 5 years and uses a different mechanism — it keeps the standard Adam structure but lags the denominator.

### Why it might help here

The canonical aux Adam β₂ pulse 0.95→0.99 @ step 975 is the ONLY confirmed WIN in the entire r1 session. Its mechanism is: inflating β₂ slows second-moment forgetting, reducing per-step denominator variance during cooldown, and producing more stable, larger effective steps. AdaShift is related but orthogonal: instead of inflating β₂ to stabilize v_t, it structurally decouples v_t from the current gradient by construction. This may produce a cleaner separation than pulse timing can achieve, especially for the embed/LM-head parameters where gradient variance is highest. The β₂=0.95 → 0.99 pulse is already confirmed to help — AdaShift's lag is an alternative structural version of the same intuition with formal convergence guarantees that the pulse approach lacks.

### Failure modes / honest caveats

- n=1 lag is essentially equivalent to a one-step ADOPT; the key question is whether the structural decoupling improves over the β₂ pulse or is redundant with it.
- The benefit may be absorbed entirely by the canonical β₂ pulse already present — they address the same root issue differently.
- The embed weight (shape ~50000×768, lr=0.3) and LM head (768×50000, lr=1/160) have high-variance gradients; the lag needs the buffer to stay warm from step 0.
- A ring buffer of size 3 adds ~3× gradient storage overhead for aux params — acceptable (~50MB at bf16).

---

## Experiment Design

### Hypothesis

Replacing aux AdamW's in-sample second moment with a temporally-lagged version (AdaShift, n=1 or n=2) reduces step-size bias during pre-cooldown and early cooldown training, producing a lower val_ema and/or earlier `sr` than the canonical baseline.

### Bilateral arms

| Arm | n (lag) | Expected behavior |
|-----|---------|------------------|
| Arm A | n=1 | Minimal ring buffer; structurally equivalent to one-step ADOPT-order-swap but via lag. Safest starting point. |
| Arm B | n=2 | Two-step lag; stronger decoupling but introduces more staleness. May hurt if lr-schedule changes faster than lag. |

### Implementation outline (~45 LOC)

Add a custom `AdaShiftAdamW` class that wraps the PyTorch AdamW step logic but maintains a deque of size n for past gradients. The key change is in the second moment update:

```python
from collections import deque

class AdaShiftAdamW(torch.optim.Optimizer):
    """AdamW with temporally-lagged second moment (AdaShift, Xie et al. ICLR 2019).
    
    v_t ← β₂·v_{t-1} + (1-β₂)·g_{t-n}²   (uses stale gradient from n steps ago)
    m_t ← β₁·m_{t-1} + (1-β₁)·g_t          (standard first moment, current gradient)
    θ_t ← θ_{t-1} - α_t · m̂_t / (√v̂_t + ε) (standard bias-corrected step)
    """
    def __init__(self, params, lr=1e-3, betas=(0.8, 0.95), eps=1e-10,
                 weight_decay=0, n_shift=1, fused=False):
        defaults = dict(lr=lr, betas=betas, eps=eps, weight_decay=weight_decay,
                        n_shift=n_shift)
        super().__init__(params, defaults)
    
    def step(self, closure=None):
        for group in self.param_groups:
            beta1, beta2 = group["betas"]
            n = group["n_shift"]
            lr = group["lr"]
            eps = group["eps"]
            wd = group["weight_decay"]
            for p in group["params"]:
                if p.grad is None:
                    continue
                g = p.grad.detach()
                state = self.state[p]
                # Init state
                if len(state) == 0:
                    state["step"] = 0
                    state["exp_avg"] = torch.zeros_like(p)
                    state["exp_avg_sq"] = torch.zeros_like(p)
                    # Ring buffer: pre-fill with zeros so v_t is valid from step 0
                    state["grad_buf"] = deque([torch.zeros_like(g)] * n, maxlen=n)
                state["step"] += 1
                t = state["step"]
                m = state["exp_avg"]
                v = state["exp_avg_sq"]
                buf = state["grad_buf"]
                # Lagged gradient for second moment (oldest item in the buffer)
                g_lag = buf[0]   # g_{t-n}
                buf.append(g.clone())  # push current gradient
                # Update moments
                m.mul_(beta1).add_(g, alpha=1 - beta1)           # standard first moment
                v.mul_(beta2).addcmul_(g_lag, g_lag, value=1 - beta2)  # lagged second moment
                # Bias correction
                bc1 = 1 - beta1 ** t
                bc2 = 1 - beta2 ** t
                m_hat = m / bc1
                v_hat = v / bc2
                # Weight decay (decoupled, AdamW style)
                if wd != 0:
                    p.data.mul_(1 - lr * wd)
                # Parameter update
                p.data.addcdiv_(m_hat, v_hat.sqrt().add_(eps), value=-lr)
```

### Integration into train_gpt_simple.py

1. Add `from collections import deque` at top of file (if not present).
2. Add `AdaShiftAdamW` class above the `Muon` class definition.
3. Add CLI argument `--aux_adashift_n` (int, default=0; 0 means disabled, use standard AdamW).
4. In optimizer construction block (line ~793), conditionally use `AdaShiftAdamW` instead of `AdamW` when `args.aux_adashift_n > 0`, passing `n_shift=args.aux_adashift_n`. Preserve all group params (betas, lr, eps, weight_decay) unchanged.
5. Log `aux_adashift/n_shift` in the W&B config dict.

Note: remove `fused=True` from the aux optimizer when using AdaShiftAdamW since the custom step is not fused. The embed/head/scalar groups are small enough that this is negligible.

### Recommended run configuration

```bash
# Arm A: n=1 (single-step lag)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/adashift-aux-n1" \
  --wandb_group "pr-1705-adashift-aux" \
  --aux_adashift_n 1 \
  --num_trials 2

# Arm B: n=2 (two-step lag)  
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "edward/adashift-aux-n2" \
  --wandb_group "pr-1705-adashift-aux" \
  --aux_adashift_n 2 \
  --num_trials 2
```

Both arms keep the canonical β₂ pulse (step 975, 0.99) — this stacks AdaShift's structural decoupling on top of the confirmed WIN rather than replacing it. The β₂ pulse will change betas in the group dict; the step function reads `group["betas"]` at each step, so the pulse fires correctly without any modification.

### ETA

~3.5h per arm on 1 GPU (2 seeds each = n=2 statistical reporting).

### Stop condition

If Arm A sr ≥ 2925 after 2 seeds and val_ema > 3.270, close as NULL — lag introduces staleness without benefit.

### Research state update

**Current best explanation for the plateau:** The pre-target body-Muon scalar space is exhausted. The aux Adam side has had only ONE confirmed structural win (β₂ pulse) across the entire session. The question is whether there are further structural improvements available on the aux side beyond timing/amplitude pulse variants.

**AdaShift tests the aux-side structural hypothesis directly.** If it NULLs, that rules out the "Adam denominator correlation" as a live improvement axis for aux Adam in this regime, and we escalate to Tier 3 wrapper optimizers (Slow Momentum) or Tier 4 architectural levers.

**If AdaShift wins:** compound with pEMA stacking (#1704 thorfinn) and async whitening (#1703 alphonse) results for combined Tier 2 stack test.

---

## SECONDARY IDEA (queue for next student, not edward)

### Muon NS_ITERS Phase Burst (12 → 14/16 during steps 2750-2900)

Not a NS coefficient change (axis closed by #1660) but a Newton-Schulz **iteration count burst** during the pre-target window. More NS iterations = tighter polar projection = more orthogonality of the update matrix. The 12-iteration default was set for compute budget, not for optimality at the critical pre-target window. A brief burst to 14 or 16 iterations for 150 steps adds ~17-33% compute for only 5% of total training.

- Axis status: NS_ITERS burst at specific phase = 0 prior PRs on r1 (listed as "not yet tested phase-specifically" in research state)
- Implementation: add `--ns_iters_burst` and `--ns_burst_start`/`--ns_burst_end` flags; inside `pmuon_update` check current step and switch `NS_ITERS` accordingly
- Suggested for thorfinn follow-up after #1704 results, per research state queue item 2

---

## TERTIARY IDEA (queue for later, lower priority)

### Muon Per-Block Depth-Stratified beta_cov Dispatch

Not beta_cov pulse at a single time (closed by #1666) but a static depth-stratified mapping: early transformer blocks (0-3) get a lower beta_cov (0.90) while late blocks (8-11) get a higher one (0.97), with middle blocks interpolating. The intuition is that early-block covariance matrices change faster during training (representations are more volatile) and benefit from faster EMA forgetting, while late-block covariance matrices are more stable and benefit from slower EMA. This is orthogonal to pulse timing.

- Axis status: depth-stratified beta_cov = 0 prior PRs on r1 (listed as "not yet tried as bilateral depth partition" in research state item 3)
- Implementation: add `--beta_cov_depth_lo` and `--beta_cov_depth_hi` flags; in Muon init, compute per-param beta_cov based on block index
- Lower priority than AdaShift; queue for after current wave resolves

---

*Prepared by researcher-agent, 2026-05-29 14:15 UTC*
*For edward's immediate assignment — PR #1705 (suggested)*
