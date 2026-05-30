# HYPOTHESIS — fern — GrokFast slow-gradient amplification on whitened body PMuon updates during cooldown

**Branch:** `g1r1-fern/grokfast-whitened`
**Assigned:** 2026-05-30 05:10 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (c) short phase-specific mechanisms + (d) momentum/preconditioner state handling

## Why this hypothesis

GrokFast (Lee et al. 2024, arxiv 2405.20233) accelerates "grokking" in neural networks by separating gradient signal into a slow-EMA component (low-frequency) and fast-EMA component (high-frequency), then amplifying the slow component. The mechanism: `grad_amplified = grad + α · slow_ema_grad` where `slow_ema_grad = β · slow_ema_grad + (1-β) · grad` with very slow β (e.g. 0.98+). Effectively a high-pass-cut filter that boosts persistent gradient direction.

**Three reasons this is uniquely promising here:**

1. **Zero history matches** — no prior PR in this 329-PR research history has tested slow-gradient amplification on this benchmark. Genuinely fresh axis.

2. **The current bottleneck is val_ema in steps 3000-3250 (cooldown final 250 steps).** Two independent close-miss experiments (#1708, #1726) hit sr=2875 but missed val_ema by < 1.1 mnat. The cooldown phase is where the gradient direction stabilizes but magnitude shrinks (due to LR decay). Amplifying the persistent (slow-EMA) gradient component during cooldown is mechanistically targeted at this exact failure mode.

3. **Applied AFTER Newton-Schulz whitening, NOT on raw gradients.** Body PMuon does `g → NS5(L_cov^{-1/2} · g · R_cov^{-1/2})` to produce a polar-normalized update direction. Amplifying the slow EMA of THIS whitened update — not the raw pre-whitening gradient — preserves the polar normalization while compounding persistent directions. This is the structurally distinct innovation: GrokFast was designed for raw gradients on Adam, never tried in the whitened-gradient space of Muon.

**Why fern's NS_ITERS NULL motivates this:** Fern's just-closed PR #1739 demonstrated that polar projection accuracy is NOT the bottleneck — the residual was 3-5× tighter during burst without translating to better target-crossing. That isolates the failure mode: the polar projection delivers a clean direction, but the update MAGNITUDE in the slow-EMA component of that direction is insufficient during cooldown when LR is decaying. GrokFast amplification directly addresses the magnitude axis.

## Experiment design

**Bilateral comparison on amplification strength α:**

- **Arm A — α=0.5, β=0.98** (conservative): mild slow-EMA boost, β=0.98 → ~50-step memory. Tests whether any amplification benefits the cooldown trajectory.
- **Arm B — α=2.0, β=0.98** (aggressive paper default): direct GrokFast paper default. Tests the published amplification strength.

Both arms gate the amplification to the **cooldown window only** (steps 975 onward) — applying GrokFast during warmup would distort the polar normalization while the model is still discovering the loss landscape.

## Implementation guidance

Add CLI flags:

```python
parser.add_argument("--grokfast_start_step", type=int, default=-1,
                    help="Step to start GrokFast amplification (-1 = disabled)")
parser.add_argument("--grokfast_alpha", type=float, default=0.0,
                    help="GrokFast amplification factor: update += alpha * slow_ema")
parser.add_argument("--grokfast_beta", type=float, default=0.98,
                    help="GrokFast slow EMA decay")
```

In the body PMuon `step()` function, AFTER the Newton-Schulz polar approximation but BEFORE applying to the parameter:

```python
# After: update = NS5(L_cov^{-1/2} @ g @ R_cov^{-1/2}) and any per-block LR scaling

if (args.grokfast_start_step > 0
    and global_step >= args.grokfast_start_step
    and args.grokfast_alpha > 0):
    if 'grokfast_slow_ema' not in state:
        state['grokfast_slow_ema'] = torch.zeros_like(update)
    state['grokfast_slow_ema'].mul_(args.grokfast_beta).add_(
        update, alpha=1 - args.grokfast_beta)
    update = update + args.grokfast_alpha * state['grokfast_slow_ema']
    # Optional re-norm to preserve polar magnitude (test BOTH variants):
    # update = update * (orig_update_norm / update.norm().clamp_min(1e-12))

p.add_(update, alpha=-lr * group['lr_scale'])
```

**Critical: the slow_ema state is per-param, initialized lazily to zero at first activation.** It does NOT need to persist across the full training run if `grokfast_start_step >= 975` — initialization at zero ensures the first ~30 steps after activation are dominated by the fresh update, with slow_ema building gradually.

**Optional: re-normalize the amplified update to preserve polar magnitude.** This is a one-line addition. Test the un-renormalized variant first (paper default); if Arm A shows promise but spectral norm of updates drifts, consider re-norm in a follow-up.

## Reproduce commands

**Arm A (α=0.5, conservative — cooldown only):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --grokfast_start_step 975 --grokfast_alpha 0.5 --grokfast_beta 0.98 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-grokfast-whitened \
  --wandb_name g1r1-fern/grokfast-alpha0.5-armA
```

**Arm B (α=2.0, paper default — cooldown only):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --grokfast_start_step 975 --grokfast_alpha 2.0 --grokfast_beta 0.98 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-grokfast-whitened \
  --wandb_name g1r1-fern/grokfast-alpha2.0-armB
```

Run **Arm A first**, then chain Arm B.

## Validation checklist

Before launching bilateral:
1. Smoke 1100 steps with `--grokfast_start_step 1000 --grokfast_alpha 0.5`. Confirm:
   - Sentinel log `[step 1000] grokfast amplification enabled (alpha=0.5, beta=0.98)` appears
   - Train_loss continues monotone (no spike at step 1000 activation)
   - W&B logs `grokfast/slow_ema_norm` per step after activation — should grow from 0 to comparable magnitude with raw update norm over ~50 steps
2. If train_loss spikes >0.5 mnat at the GrokFast activation step, consider warm-starting the slow_ema with the current raw update before applying amplification (instead of cold-start zero) — but document this in your PR comment.

## Anti-patterns

- **Do NOT enable GrokFast during warmup (steps 0-975)** — slow-EMA would learn warmup-regime direction and over-amplify it through cooldown
- **Do NOT apply GrokFast to aux Adam params (embed/lm_head/scalars)** — only body PMuon
- **Do NOT omit `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99`** — merge gate is against #1532
- **Do NOT change β=0.98** in Arm A vs Arm B — keep β fixed, vary only α to isolate the amplification axis

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A WIN merge gate** | Mild slow-EMA amplification at α=0.5 is sufficient. Request seed-2 confirmation. Strong WIN — validates "magnitude in cooldown is the bottleneck" hypothesis. |
| **Arm A close miss, Arm B WIN** | Paper-default amplification strength is needed. Request seed-2 of Arm B. |
| **Arm A NULL, Arm B sr=2875 close miss** | Amplification mechanism real but α requires further tuning. Worth a follow-up on intermediate α ∈ {1.0, 1.5}. |
| **Both NULL with sr=2925** | Slow-EMA amplification of whitened updates doesn't compound during cooldown. Closes this axis cleanly. |
| **Arm B diverges** | α=2.0 is too aggressive on the whitened-gradient distribution. Focus on Arm A signal. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
