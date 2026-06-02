# Hypothesis: Aux Adam Pre-Update Gradient EMA (alphonse)

**Assigned:** 2026-06-02 11:00 UTC
**Student:** g1r1-alphonse
**Branch:** g1r1-alphonse/aux-pre-grad-ema
**Directive alignment:** (c) phase-specific mechanism + (d) momentum/preconditioner state input handling

## Mechanism hypothesis

Apply a lightweight exponential moving average to the raw gradient BEFORE it is fed into aux AdamW's first and second moment accumulators:

```
g_smooth_t = α * g_smooth_{t-1} + (1 - α) * g_t
m_t = β₁ * m_{t-1} + (1 - β₁) * g_smooth_t     # uses g_smooth in place of g_t
v_t = β₂ * v_{t-1} + (1 - β₂) * g_smooth_t²
```

This decouples the temporal smoothing window for the first moment from β₁ itself. The pre-filter creates an effective two-stage IIR low-pass: the inner α-EMA suppresses high-frequency gradient noise before it propagates into the variance estimator, while the outer β₁/β₂ recursion preserves their canonical roles in momentum/variance estimation.

Crucially, this is structurally distinct from a β₁ sweep. Expanding the recursion:

```
m_t = β₁ * m_{t-1} + (1-β₁)(1-α) * g_t + (1-β₁)α * g_smooth_{t-1}
```

The third term gives the recursion an additional memory channel through `g_smooth_{t-1}` that no single β₁ value reproduces. It corresponds to a longer effective integration window with a different transfer function — not equivalent to merely tuning β₁.

The aux groups (embed, lm_head, scalars) ingest gradients with distinct statistical structure: embed sees Zipfian-frequency variance (rare tokens contribute sparse but noisy updates), lm_head sees output-logit variance, scalars see small batch-aggregated noise. A modest pre-filter (~3-5 step memory) should reduce the variance pollution in v_t for the noisy embed group without destroying responsiveness during the cooldown LR ramp.

## Why this axis is pristine

Adjacent prior art (CLOSED):
- PR #757 **GROKFAST** — amplifies slow gradient EMA via `g_eff = g + λ*EMA_slow(g)` then feeds `g_eff` to AdamW. This ADDS the slow component, preserving high-frequency content. The current hypothesis REPLACES g with the smoothed signal — structurally opposite (frequency removal vs frequency amplification).
- PR #989 MUON_GRAD_HIGH_PASS — body Muon gradient stream temporal high-pass. Body, not aux; high-pass, not low-pass.
- PR #1192 lm_head row-norm AdamW — magnitude rescaling on Zipfian rows, not gradient temporal filtering.
- PR #1592, #318, #796 — aux Adam β₁ sweeps/pulses/ramps. All change β₁ itself, none add a pre-filter stage.
- PR #1734 Cautious MuonH — pre-NS5 sign-mask (body Muon, sign-based, not EMA).
- PR #1187 MGUP — body gradient-momentum alignment scoring, not pre-filter.

The proposed mechanism — a low-pass pre-filter inserted BEFORE the aux AdamW accumulators — has zero matching closed PR titles across 9+ search rounds. The aux-side raw gradient input has never been pre-filtered.

## Bilateral arm design

**Arm A** — α=0.90 (lighter smoothing, ~10 step effective memory):
```
--aux_pre_grad_ema_alpha 0.90
```

**Arm B** — α=0.95 (stronger smoothing, ~20 step effective memory):
```
--aux_pre_grad_ema_alpha 0.95
```

Bilateral interpretation:
- If Arm A wins and Arm B is null → mild smoothing is the right operating point; the integration window matters.
- If Arm B wins and Arm A is null → stronger smoothing is needed; aux groups benefit from heavier pre-filtering.
- If both win → the pre-filter is a positive intervention regardless of strength; finer α grid follows.
- If both null → the β₁ accumulator already captures all useful smoothing for aux groups; close axis.

## Implementation sketch

```python
parser.add_argument('--aux_pre_grad_ema_alpha', type=float, default=0.0,
                    help='Pre-AdamW gradient EMA smoothing factor. 0.0 = disabled (baseline). '
                         'Active range typically [0.85, 0.95].')

# In the aux optimizer step path, before m_t/v_t update:
if args.aux_pre_grad_ema_alpha > 0.0:
    if 'g_smooth' not in state:
        state['g_smooth'] = torch.zeros_like(p.grad)
    state['g_smooth'].mul_(args.aux_pre_grad_ema_alpha).add_(
        p.grad, alpha=1.0 - args.aux_pre_grad_ema_alpha)
    g_input = state['g_smooth']
else:
    g_input = p.grad

# Then use g_input wherever the raw p.grad would have gone into m_t/v_t
exp_avg.mul_(beta1).add_(g_input, alpha=1.0 - beta1)
exp_avg_sq.mul_(beta2).addcmul_(g_input, g_input, value=1.0 - beta2)
```

**Important:** Only the aux AdamW path is modified. The body PMuon optimizer (optimizer2) is unchanged. The pre-filter applies uniformly across embed, lm_head, and scalar groups in this initial test.

LOC delta: ~25. Runtime: identical to baseline (one extra in-place tensor lerp per aux param per step). VRAM: +~1.5% (one extra state tensor per aux param, same shape as param).

## Reproduce commands (full baseline stack)

**Arm A (α=0.90):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_pre_grad_ema_alpha 0.90 \
  --wandb_group g1r1-alphonse-aux-pre-grad-ema \
  --wandb_name g1r1-alphonse/aux-pre-grad-ema-arm-a-alpha090
```

**Arm B (α=0.95):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_pre_grad_ema_alpha 0.95 \
  --wandb_group g1r1-alphonse-aux-pre-grad-ema \
  --wandb_name g1r1-alphonse/aux-pre-grad-ema-arm-b-alpha095
```

## Merge gate

Beat #1532 baseline: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Sentinel logging (REQUIRED)

At step 0 log: `aux_pre_grad_ema_alpha={α}, applies_to=[embed, lm_head, scalars]`

On the first 5 steps, log the L2 ratio `||g_smooth||_2 / ||g_raw||_2` for one embed and one lm_head param — this confirms the EMA state is being populated and the filter is active. Expected behavior: ratio starts near (1-α) at step 1, grows toward 1 over ~5/(1-α) steps as the EMA fills.

## Falsifying result

Both arms cluster at sr=2925 with val_ema ∈ [3.265, 3.275] → the β₁ momentum already captures all useful smoothing for aux gradients; pre-filtering provides no marginal benefit. Close aux pre-filter axis.

## Stop / report

Post terminal SENPAI-RESULT for Arm A with `terminal=false, pending_arms=true`, then immediately launch Arm B without waiting for advisor ack. After Arm B terminal, post FINAL bilateral SENPAI-RESULT with `terminal=true, pending_arms=false` and both run IDs.
