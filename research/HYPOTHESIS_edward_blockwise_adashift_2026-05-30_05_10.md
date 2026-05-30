# HYPOTHESIS — edward — Block-wise AdaShift on aux AdamW (scalar v_t per tensor)

**Branch:** `g1r1-edward/blockwise-adashift`
**Assigned:** 2026-05-30 05:10 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directive:** (d) momentum/preconditioner state handling changes

## Why this hypothesis

The aux Adam variance estimator family has been explored along two completed axes:
1. **Per-element AdaShift (#1709)** — uses `g_{t-n}²` per element for v_t. CLOSED bilateral NULL.
2. **ACProp async (#1771)** — uses `g_{t-1}²` per element for v_t. CLOSED bilateral NULL (catastrophic on sparse-grad embed).

Both prior variants share the failure mode: **per-element second-moment estimation** on sparse-gradient embed where each step's active vocab tokens differ. The variance scalar at a particular embed index becomes uncorrelated with that index's actual gradient when only a subset of tokens activate.

**Block-wise AdaShift is mechanistically different:** instead of maintaining `|p|` independent v_t scalars (one per parameter element), maintain ONE scalar v_t per tensor (or per param group). The update is:

```
v_t = β₂ · v_{t-1} + (1 - β₂) · ||g_{t-n}||²    # scalar per tensor
update = lr * m_t / (sqrt(v_t) + eps)            # m_t per-element, v_t broadcast
```

**This sidesteps the sparse-grad failure mode entirely:** the scalar v_t aggregates over ALL elements of the tensor at each step, so even when only a subset of embed indices have non-zero gradients, the v_t still receives a meaningful signal from the active tokens via the L2 norm. The "AdaShift" stale-gradient delay (`g_{t-n}` instead of `g_t`) gives decorrelated variance estimation while keeping the magnitude tracking semantically valid across sparse steps.

**Cheaper too:** v_t becomes O(|tensors|) instead of O(|params|) — negligible memory and compute.

## Experiment design

**Bilateral comparison on stale-gradient delay n:**

- **Arm A — n=1** (one-step delay, most aggressive decorrelation): closest to ACProp's failure mode but with scalar aggregation. Tests whether scalar aggregation fixes the sparse-grad failure.
- **Arm B — n=10** (canonical AdaShift delay from the original paper): matches the original block-wise AdaShift paper's recommendation. Tests whether the longer delay is required for the decorrelation benefit.

Both arms identical to #1532 baseline EXCEPT for the new block-wise AdaShift implementation on the aux AdamW path (`optimizer1`).

## Implementation guidance

Add CLI flags to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--aux_blockwise_adashift_delay",
    type=int,
    default=0,
    help="Block-wise AdaShift stale-gradient delay (0=disabled, 1=ACProp-style scalar, "
         "10=canonical AdaShift)",
)
```

Create a new `AdamWBlockwiseAdashift` class in the same module as the existing `AdamWAsync` (from edward #1771), or inline a fork. Replace the per-element `exp_avg_sq` tensor with a scalar `v` per param:

```python
class AdamWBlockwiseAdashift(torch.optim.Optimizer):
    """AdamW variant with block-wise (scalar) AdaShift v_t per tensor.

    v_t = beta2 * v_{t-1} + (1 - beta2) * ||g_{t-n}||^2  (scalar)
    """
    def __init__(self, params, lr=1e-3, betas=(0.9, 0.999), eps=1e-8,
                 weight_decay=0.0, delay=10):
        defaults = dict(lr=lr, betas=betas, eps=eps,
                        weight_decay=weight_decay, delay=delay)
        super().__init__(params, defaults)

    @torch.no_grad()
    def step(self, closure=None):
        for group in self.param_groups:
            beta1, beta2 = group['betas']
            eps = group['eps']
            wd = group['weight_decay']
            lr = group['lr']
            delay = group['delay']
            for p in group['params']:
                if p.grad is None:
                    continue
                g = p.grad
                state = self.state[p]
                if len(state) == 0:
                    state['step'] = 0
                    state['exp_avg'] = torch.zeros_like(p)
                    # scalar v: zero-dim tensor for block-wise aggregation
                    state['v'] = torch.zeros((), dtype=p.dtype, device=p.device)
                    # circular buffer of past gradient L2 norms squared
                    state['g_norm_sq_history'] = [None] * (delay + 1)
                    state['hist_idx'] = 0

                # update gradient history buffer
                g_norm_sq = (g.float() ** 2).sum().to(p.dtype)
                hist = state['g_norm_sq_history']
                idx = state['hist_idx']
                stale_idx = (idx - delay) % (delay + 1)
                stale_g_norm_sq = hist[stale_idx]
                hist[idx] = g_norm_sq
                state['hist_idx'] = (idx + 1) % (delay + 1)

                # m_t (per element, standard)
                state['exp_avg'].mul_(beta1).add_(g, alpha=1 - beta1)

                # v_t (scalar): bootstrap to current g until history is filled
                effective_g_norm_sq = stale_g_norm_sq if stale_g_norm_sq is not None else g_norm_sq
                state['v'].mul_(beta2).add_(effective_g_norm_sq, alpha=1 - beta2)

                state['step'] += 1
                bias_correction1 = 1 - beta1 ** state['step']
                bias_correction2 = 1 - beta2 ** state['step']
                m_hat = state['exp_avg'] / bias_correction1
                v_hat = state['v'] / bias_correction2

                # broadcast scalar v_hat across all elements
                denom = v_hat.sqrt().add_(eps)
                if wd > 0:
                    p.mul_(1 - lr * wd)
                p.add_(m_hat / denom, alpha=-lr)
        return None
```

Apply this optimizer ONLY to the embed group (where the sparse-grad failure mode lives) by default. The lm_head and scalar groups stay on canonical AdamW (their gradients are dense). This is a key design choice: target the failure mode of the prior closures.

In the optimizer setup (around the existing `optimizer1` construction):

```python
if args.aux_blockwise_adashift_delay > 0:
    # Replace embed group with block-wise AdaShift
    embed_params = [m.embed.weight]
    embed_lr = args.embed_lr  # whatever the canonical value is — 0.3
    optimizer1_embed = AdamWBlockwiseAdashift(
        embed_params,
        lr=embed_lr,
        betas=(0.8, 0.95),
        eps=1e-10,
        weight_decay=0.0,
        delay=args.aux_blockwise_adashift_delay,
    )
    # Remove embed_params from canonical optimizer1, keep lm_head + scalars there
    print(f"[init] Block-wise AdaShift on embed group (delay={args.aux_blockwise_adashift_delay})")
```

## Reproduce commands

**Arm A (delay=1 — minimal stale-gradient):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_blockwise_adashift_delay 1 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-blockwise-adashift \
  --wandb_name g1r1-edward/blockwise-adashift-d1-armA
```

**Arm B (delay=10 — canonical AdaShift delay):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_blockwise_adashift_delay 10 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-edward-blockwise-adashift \
  --wandb_name g1r1-edward/blockwise-adashift-d10-armB
```

Run **Arm A first**, then chain Arm B after Arm A exits. Use a smoke test (`--aux_blockwise_adashift_delay 1` for 100 steps) first to confirm the scalar v_t evolves correctly and aux_b2 pulse @ 975 still propagates.

## Validation checklist

Before launching bilateral:
1. Smoke 100 steps with `--aux_blockwise_adashift_delay 1`, confirm:
   - `[init] Block-wise AdaShift on embed group` banner appears
   - No NaN/Inf in train_loss through step 100
   - W&B logs the scalar `v` summary stat (add: `wandb.log({"aux_embed_v_scalar": float(state['v'])}, step=step)` periodically)
2. Confirm aux_b2_pulse @ 975 fires on the block-wise AdaShift optimizer (it should — `param_groups[*]['betas']` is mutated identically)

## Anti-patterns

- **Do NOT apply block-wise AdaShift to lm_head or scalars** — those gradients are dense and don't have the failure mode; the change would be a regression on working groups
- **Do NOT omit `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — merge gate is against #1532
- **Do NOT use eps higher than 1e-10** — match canonical aux AdamW; the scalar v_t is already large (sum of |p| elements) so eps is only meaningful at machine precision

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A or B WIN merge gate** | Block-wise aggregation fixes the sparse-grad failure mode; AdaShift mechanism IS load-bearing for aux Adam when applied correctly. Request seed-2 confirmation. |
| **Arm A NULL, Arm B sr=2875 close miss** | Mechanism exists but canonical delay is required. Worth a follow-up bilateral on delay ∈ {5, 20}. |
| **Arm A diverges, Arm B trails** | Block-wise scalar aggregation still insufficient — even L2-norm aggregation of sparse grads carries the same staleness penalty. Closes the AdaShift-family entirely. |
| **Both NULL with sr=2925** | Variance decorrelation is not a load-bearing axis on aux Adam regardless of aggregation granularity. Strong directive to move on from aux-Adam-state-mutation. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
