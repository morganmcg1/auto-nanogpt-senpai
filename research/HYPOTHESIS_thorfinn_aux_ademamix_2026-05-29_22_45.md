# HYPOTHESIS — thorfinn AdEMAMix dual-EMA on aux AdamW

## Tier-2 classification
**Multi-timescale momentum state handling on the aux optimizer**, aligned with human directive #1252 (momentum/preconditioner state handling changes). The aux side has been minimally explored for state innovations — the only aux-state mutation in the winning baseline is the β₂ pulse at step 975 (#1532).

## Motivation

Aux AdamW (embeddings, lm_head, scalars) currently uses standard single-EMA first moments with β₁=0.8. The body PMuon has heavy state-handling sophistication (bilateral L/R cov, NS5 polar, paramEMA refresh, late-higher block LR pattern) — but the aux side is comparatively under-engineered.

AdEMAMix (Pagliardini et al., NeurIPS 2024, arXiv:2409.03137) introduces a **dual-EMA first moment**: blends a fast EMA (β₁≈0.9) with a slow EMA (β₃≈0.999). The slow EMA accumulates gradient information across a much longer horizon, which improves training in regimes where gradient direction signal is consistent over many thousands of steps. T_α warmup schedules the mixing weight from 0 to its target value, avoiding cold-start bias from the un-warmed slow EMA.

This is mechanistically different from every in-flight Tier-2 experiment (cov reset, depth-split β_cov, ADOPT order swap, momentum buffer reset, UW floor pulse, NS_ITERS burst, depth-asymmetric block LR burst) — those are all body-PMuon-side. AdEMAMix touches only the aux optimizer.

## Hypothesis

Replacing the aux AdamW first-moment EMA with an AdEMAMix dual-EMA (fast β₁ + slow β₃ blended via α with T_α warmup) accelerates aux embedding/scalar convergence enough to shift the target-crossing trajectory below baseline sr=2875 or beat val_ema 3.262854.

## Bilateral arms

Apply on aux Adam only (PMuon body unchanged). Both arms keep β₂=0.95 → 0.99 pulse at step 975 (canonical).

| Arm | α (target blend) | β₃ (slow EMA) | T_α (warmup steps) |
|---|---|---|---|
| **A: paper defaults** | 0.5 | 0.999 | 500 |
| **B: stronger slow component** | 0.75 | 0.9995 | 750 |

Symmetric arms isolate sensitivity to slow-EMA strength. Arm A uses the values from the AdEMAMix paper; Arm B doubles the long-horizon weight and extends T_α to compensate.

## Mechanistic separation from in-flight Tier-2

| in-flight Tier-2 | what it changes | this hypothesis |
|---|---|---|
| edward #1727 | depth-split **β_cov** on body PMuon | aux AdamW first-moment dual-EMA |
| nezuko #1726 | covariance-state hard zero **reset** on PMuon body | aux first-moment **architecture** change (no reset) |
| askeladd #1730 | momentum-buffer hard zero **reset** on body PMuon | aux first-moment dual-EMA (state-preserving) |
| fern #1739 | NS_ITERS burst on body PMuon polar projection | aux optimizer (no NS interaction) |
| alphonse #1703 | ADOPT update-rule **order swap** on body PMuon | aux first-moment **structure** change (no order swap) |
| tanjiro #1742 | depth-asymmetric **block LR burst** on body PMuon | aux global state structure (no per-block) |
| frieren #1708 | Skylight u/w floor pulse on body PMuon | aux Adam (no Skylight interaction) |

All in-flight Tier-2 hypotheses touch the body PMuon. This is the only fresh aux-side state mechanism in this batch.

## Implementation sketch

The existing aux AdamW path uses `torch.optim.AdamW`. Implement AdEMAMix as a custom optimizer or extend the existing aux path with a slow-EMA buffer per parameter:

```python
# In aux optimizer state
state['exp_avg']       # standard fast EMA, β₁ = current aux β₁ = 0.8
state['exp_avg_slow']  # NEW: slow EMA, β₃ = args.aux_ademamix_beta3

# In aux step
m_fast = state['exp_avg']   # bias-corrected with β₁
m_slow = state['exp_avg_slow']   # bias-corrected with β₃
alpha_t = args.aux_ademamix_alpha * min(1.0, step / args.aux_ademamix_t_alpha)
m_eff = m_fast + alpha_t * m_slow
# rest of AdamW update uses m_eff in place of m_fast
```

Add CLI flags:

```python
parser.add_argument('--aux_ademamix_alpha', type=float, default=0.0,
                    help='Target blend weight for slow EMA (0 = disabled, paper default 0.5)')
parser.add_argument('--aux_ademamix_beta3', type=float, default=0.999)
parser.add_argument('--aux_ademamix_t_alpha', type=int, default=500)
```

When `aux_ademamix_alpha > 0`, the aux optimizer uses AdEMAMix; when 0, it falls back to vanilla AdamW (canonical behavior).

**Smoke test:** Run with `--aux_ademamix_alpha 0.5 --aux_ademamix_beta3 0.999 --aux_ademamix_t_alpha 500` for 200 steps. Verify (a) no NaN/inf, (b) aux loss descent matches or exceeds baseline early curve, (c) telemetry confirms slow EMA state tensors are populated and bias-corrected, (d) alpha_t warmup schedule plots as expected.

## Reproduce command (single arm)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --aux_ademamix_alpha 0.5 --aux_ademamix_beta3 0.999 --aux_ademamix_t_alpha 500 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-thorfinn/aux-ademamix \
  --wandb_name g1r1-thorfinn/aux-ademamix-arm-a
```

Replace alpha/beta3/t_alpha with Arm B values (0.75/0.9995/750) for the bilateral.

## Telemetry to log

- `aux/m_fast_norm`, `aux/m_slow_norm` per step (mean / max)
- `aux/alpha_t` per step (verify warmup schedule)
- `aux/m_eff_minus_m_fast_norm` (magnitude of slow-EMA contribution)
- Console ENTER print confirming AdEMAMix active at step 0 if alpha > 0
- Existing val_loss_ema/val_loss_live/sr/target_margin

## Reporting contract (terminal SENPAI-RESULT)

After Arm A + Arm B both terminal at step 3250, post single bilateral marker (`terminal=true`, `pending_arms=false`):

```json
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<arm_a>","<arm_b>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<min_sr>},"test_metric":{"name":"val/loss_ema","value":<min_val_ema>}}
```

Include bilateral table (sr / val_ema / val_live / target_margin per arm vs baseline) and AdEMAMix audit (alpha_t at sentinel steps 250, 500, 1000, 2000, 3000; slow EMA norm trajectory).

## Baseline + merge gate

| metric | baseline #1532 (n=2) |
|---|---|
| `speedrun/final_first_step_to_target` | 2875 |
| `val/loss_ema` | 3.262854 |

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`. Bilateral fail → NULL closure; either arm pass → request seed-2 confirmation before merge.

## Risk note

- Cold-start slow EMA bias is the primary failure mode — mitigated by T_α warmup. If aux loss diverges in first 200 steps, increase T_α first.
- Slow EMA adds one tensor per aux parameter — extra VRAM ~36 MB (negligible).
- Aux Adam β₁=0.8 currently; AdEMAMix paper uses β₁=0.9. Keep β₁=0.8 (preserves canonical) to isolate the slow-EMA contribution.
