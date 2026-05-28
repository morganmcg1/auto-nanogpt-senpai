## Hypothesis (42nd NEW MECHANISM CLASS — LoCo-Adam: outer Adam replacing outer Nesterov SGD in MuLoCo)

**Does replacing MuLoCo's outer Nesterov SGD with outer Adam on the accumulated pseudo-gradient delta improve convergence, targeting FFS < 3025?**

This is the 42nd novel mechanism class in the campaign.

- MuLoCo HP closure (H222: outer_lr, H229: outer_momentum, H233: sync_interval) and MuLoCo FORM closure (H236: Outer Polyak FORM bilateral NEG) are complete. Per Programme Finding #54, future MuLoCo work must target **FORM replacements** — a different outer aggregation algorithm — not HP tuning or Polyak averaging variants.
- No prior hypothesis has changed the outer optimizer algorithm. The current implementation is Nesterov SGD: `v = momentum * v + delta; p = anchor - lr * (momentum * v + delta)`. This test replaces that with Adam moment tracking on the same delta signal.
- This is distinct from H244 (depth-scaled per-layer LR on MuonH body, PR #1580) and H245 (ADana log-time β schedule on aux AdamW, PR #1581).
- This is distinct from the aux-replacement triad (H225 β1, H237 AdEMAMix, H239 SF-AdamW, H241 Lion) — those replaced the **inner** aux AdamW; this replaces the **outer** aggregation step that wraps all params uniformly after every `sync_interval` inner steps.

## Why this might help

MuLoCo's outer Nesterov SGD applies a single scalar `outer_lr` and `outer_momentum` to accumulate velocity on the pseudo-gradient delta `Δ = anchor - param_post_sync`. The mechanism is momentum-only: it has no per-coordinate adaptive scaling.

The delta signal is not homogeneous across parameter groups. Body weights under NS5 polar projection and embed/lm_head weights under aux AdamW accumulate structured, non-isotropic deltas. An outer Adam step — maintaining per-coordinate first and second moment estimates of the delta — can adapt the effective outer step size per parameter, potentially allowing more aggressive outer steps on low-variance coordinates while staying conservative on high-variance ones.

There is direct theoretical and empirical support for this idea in federated learning under the FedOpt framework (Reddi et al. 2020): using Adam as the server/outer optimizer with SGD as the client/inner optimizer gives better convergence than server-side SGD in heterogeneous settings. MuLoCo is structurally equivalent to K=1 local SGD with a momentum-equipped outer step, so the FedOpt outer-Adam insight maps directly.

Critically, the convergence regime here is `sync_interval=30` — a moderate K that means the outer optimizer sees a delta that is the sum of 30 inner steps. Adam's second moment will estimate the variance of that accumulated signal, which scales differently than the variance of a single gradient. The outer Adam beta2 should therefore be set conservatively (e.g. 0.99) to track this slower-varying signal, matching the beta2 we use for aux AdamW.

## Paper references

- Reddi, Sashay, et al. "Adaptive federated optimization." ICLR 2021. arXiv:2003.00295. Introduces FedOpt, showing Adam as the outer/server optimizer with SGD clients. Ablations confirm server-Adam consistently outperforms server-SGD in heterogeneous settings — the exact structural analogue of replacing outer Nesterov with outer Adam in MuLoCo.
- Kosson et al. "Understanding Outer Optimizers in Local SGD: Learning Rates, Momentum, and Acceleration." 2025. arXiv:2509.10439. Theoretical analysis of the outer optimizer design space in local SGD frameworks (K-step local SGD). Proves that outer optimizer choice (SGD vs Adam vs accelerated methods) directly controls convergence rate and shows that adaptive outer optimizers reduce dependence on outer learning rate sensitivity.

## 3-arm design

| Arm | Name | Key changes | Expected outcome |
|-----|------|-------------|-----------------|
| arm_a | CTRL | Baseline — outer Nesterov SGD (`outer_lr=0.7`, `outer_momentum=0.5`) | FFS=3025, val≈3.268 — bit-identity check |
| arm_b | OUTER_ADAM | Outer Adam: `outer_optimizer=adam`, `outer_adam_lr=0.7`, `outer_adam_beta1=0.9`, `outer_adam_beta2=0.99`, `outer_adam_eps=1e-8` | FFS target <3025 |
| arm_c | OUTER_ADAM_LR | Outer Adam with re-tuned LR: `outer_optimizer=adam`, `outer_adam_lr=0.3`, `outer_adam_beta1=0.9`, `outer_adam_beta2=0.99`, `outer_adam_eps=1e-8` | FFS target <3025; tests whether Adam's effective step needs a smaller nominal LR than SGD |

**arm_b rationale:** Adam's effective update magnitude is approximately `lr / (1 - beta2)^0.5` near convergence, which at `lr=0.7, beta2=0.99` gives ~7.0 — similar to the SGD step of `outer_lr * (1 + outer_momentum) ≈ 1.05`. Starting with the same nominal lr=0.7 tests whether the adaptive curvature alone helps.

**arm_c rationale:** In practice outer Adam often needs a smaller nominal lr than outer SGD because the adaptive scaling already amplifies small-gradient directions. `lr=0.3` is a conservative first probe. If arm_b NEG and arm_c NEG, this is a clean bilateral NEG with mechanism evidence. If arm_c WIN and arm_b NEG, it reveals that Adam is beneficial but needs its own HP region — warranting a follow-up sweep.

## Asymmetric outcome bracket

- **Strong WIN (arm_b or arm_c < 3000 FFS):** outer Adam substantially improves on outer Nesterov. Confirms the FedOpt analogy. Opens outer Adam HP sweep (lr, beta2 range, eps, warmup-then-Adam vs cold-start).
- **Mild WIN (2975 < FFS < 3025):** outer Adam is directionally beneficial but sensitive to lr. Merge the winner; assign an outer Adam lr sweep as follow-up (e.g. 0.1, 0.2, 0.4).
- **NEG (FFS > 3050 both arms):** outer adaptive scaling is not beneficial in this K=30 regime. Closes the outer-algorithm substitution sub-axis. Future MuLoCo FORM replacements should target compressed inner-aggregation (e.g. LoCo-Adam async, gradient compression) rather than outer algorithm change.
- **CATASTROPHIC (FFS = -1 or >3200):** outer Adam destabilizes the outer loop — check delta variance explosion from eps or unconstrained second moment. Close and move to compressed LoCo-Adam or async cadence variants.

## Implementation sketch (~50 LoC)

**Step 1 — Add argparse flags (no-op vs baseline when outer_optimizer=sgd):**

```python
parser.add_argument("--outer_optimizer", type=str,
                    default=os.environ.get("OUTER_OPTIMIZER", "sgd"),
                    choices=["sgd", "adam"],
                    help="Outer MuLoCo optimizer. 'sgd' = baseline Nesterov SGD. "
                         "'adam' = Adam on accumulated delta.")
parser.add_argument("--outer_adam_lr", type=float,
                    default=float(os.environ.get("OUTER_ADAM_LR", "0.7")))
parser.add_argument("--outer_adam_beta1", type=float,
                    default=float(os.environ.get("OUTER_ADAM_BETA1", "0.9")))
parser.add_argument("--outer_adam_beta2", type=float,
                    default=float(os.environ.get("OUTER_ADAM_BETA2", "0.99")))
parser.add_argument("--outer_adam_eps", type=float,
                    default=float(os.environ.get("OUTER_ADAM_EPS", "1e-8")))
```

**Step 2 — Initialize outer Adam state alongside existing velocity dict (after broadcast):**

```python
use_outer = bool(args.use_outer_optimizer)
if use_outer:
    outer_anchor = {n: p.detach().clone() for n, p in model.named_parameters()}
    outer_velocity = {n: torch.zeros_like(p) for n, p in model.named_parameters()}
    # Adam state — only allocated when outer_optimizer == 'adam'
    if args.outer_optimizer == "adam":
        outer_adam_m = {n: torch.zeros_like(p) for n, p in model.named_parameters()}
        outer_adam_v = {n: torch.zeros_like(p) for n, p in model.named_parameters()}
        outer_adam_step = 0  # bias-correction counter
```

**Step 3 — Replace the outer sync block with a branch on outer_optimizer:**

```python
if use_outer and train_step % args.sync_interval == 0 and train_step < train_steps:
    with torch.no_grad():
        if args.outer_optimizer == "sgd":
            # --- existing Nesterov SGD path (unchanged) ---
            for n, p in model.named_parameters():
                delta = outer_anchor[n] - p.data
                outer_velocity[n].mul_(args.outer_momentum).add_(delta)
                p.data.copy_(outer_anchor[n] - args.outer_lr *
                             (args.outer_momentum * outer_velocity[n] + delta))
                outer_anchor[n].copy_(p.data)
        else:
            # --- outer Adam path ---
            outer_adam_step += 1
            b1 = args.outer_adam_beta1
            b2 = args.outer_adam_beta2
            eps = args.outer_adam_eps
            lr = args.outer_adam_lr
            bc1 = 1.0 - b1 ** outer_adam_step
            bc2 = 1.0 - b2 ** outer_adam_step
            for n, p in model.named_parameters():
                delta = outer_anchor[n] - p.data        # pseudo-gradient
                outer_adam_m[n].mul_(b1).add_(delta, alpha=1.0 - b1)
                outer_adam_v[n].mul_(b2).addcmul_(delta, delta, value=1.0 - b2)
                m_hat = outer_adam_m[n] / bc1
                v_hat = outer_adam_v[n] / bc2
                step_dir = m_hat / (v_hat.sqrt() + eps)
                p.data.copy_(outer_anchor[n] - lr * step_dir)
                outer_anchor[n].copy_(p.data)
```

**Implementation notes:**
- The `outer_velocity` dict is still initialized even for `outer_optimizer=adam` to keep the code structure clean — it is simply unused in the adam branch. Alternatively, skip it under `if args.outer_optimizer == "sgd"` to save memory (~20 MB total).
- Bias correction is required: without it, the first outer Adam step will be dominated by the zero-initialized second moment and produce a near-zero effective lr. `outer_adam_step` counts outer sync events, not inner train steps.
- The `delta = anchor - param` convention (positive = param moved away from anchor) is the pseudo-gradient sign convention matching the existing MuLoCo Nesterov update. Keep this sign in the Adam path — it means Adam is minimizing in the direction that restores toward the anchor, which is the correct outer-level objective.
- **Do NOT reset** `outer_anchor` after the outer step when `outer_optimizer=adam` — the existing code already copies `p.data` back to `outer_anchor` at the end of each sync, which is correct for both paths.
- Log `outer_adam_step` to W&B at each outer sync for debugging.

## Bit-identity gate (REQUIRED)

arm_a MUST reproduce `val/loss ≈ 3.26830` (±0.0005) and `speedrun/final_first_step_to_target = 3025` at `train_steps=3325`. Confirm this in your PR comment before reporting treatment arms. If arm_a drifts, add `--outer_optimizer sgd` to the command and check for argparse-conditional retracing (soft-drift class — 8 confirmed instances in campaign). The new argparse flags must be placed AFTER all existing args in `parse_args()` to minimize retracing surface.

The bit-identity check for arm_a uses `--outer_optimizer sgd` implicitly (it is the default). Confirm that adding the new flags to the script does not change arm_a output vs the baseline run. If there is drift, report the exact `val/loss` and `FFS` and flag as soft-drift before running treatment arms.

## W&B audit (REQUIRED)

For each arm, confirm and report:
1. `muloco_use_outer_optimizer: True` for all three arms.
2. `muloco_outer_lr: 0.7` logged for arm_a.
3. A new config key (e.g. `muloco_outer_optimizer`) logging `"sgd"` for arm_a, `"adam"` for arm_b/c.
4. `muloco_outer_adam_lr` logging `0.7` for arm_b and `0.3` for arm_c.
5. `speedrun/final_first_step_to_target` (the primary metric) is not `-1` for arm_a and preferably not `-1` for treatment arms.
6. No NaN or Inf in `train/loss` at any step for any arm.

Report all six W&B run IDs and the W&B config screenshot in your result comment.

## Exact CLI per arm

**arm_a CTRL** (bit-identity baseline, outer SGD default):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/h246-a-ctrl" \
  --wandb_group "H246-loco-adam" \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --outer_optimizer sgd \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched
```

**arm_b OUTER_ADAM** (outer Adam, nominal lr=0.7):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/h246-b-outer-adam" \
  --wandb_group "H246-loco-adam" \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --outer_optimizer adam \
  --outer_adam_lr 0.7 --outer_adam_beta1 0.9 --outer_adam_beta2 0.99 --outer_adam_eps 1e-8 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched
```

**arm_c OUTER_ADAM_LR** (outer Adam, re-tuned lr=0.3):
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/h246-c-outer-adam-lr" \
  --wandb_group "H246-loco-adam" \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --outer_optimizer adam \
  --outer_adam_lr 0.3 --outer_adam_beta1 0.9 --outer_adam_beta2 0.99 --outer_adam_eps 1e-8 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched
```

Note: `--outer_lr` and `--outer_momentum` remain in the arm_b/c commands because they are parsed by argparse even when `--outer_optimizer adam` is active. They are not used in the Adam branch but must still parse correctly.

## Baseline

PR #1398, H203. `speedrun/final_first_step_to_target = 3025`, `val/loss = 3.26830`.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched
```

## Expected wallclock

~1h48m per arm on 1 GPU × 3 arms = ~5h25m total, sequential. Start with arm_a (bit-identity), then arm_b, then arm_c.

## Programme context

**Current territory map (relevant axes):**
- MuLoCo HP closure COMPLETE: outer_lr H222 NEG, outer_momentum H229 bilateral NEG, sync_interval H233 asymmetric-structural NEG.
- MuLoCo FORM closure COMPLETE: outer Polyak H236 bilateral NEG. Per Programme Finding #54, future MuLoCo work must target FORM REPLACEMENTS.
- This is the first MuLoCo FORM REPLACEMENT experiment: replacing the outer aggregation algorithm (SGD → Adam) rather than the outer update formula (Nesterov → Polyak).
- Aux-replacement axis nearly closed: H225 NEG, H237 AdEMAMix NEG, H239 SF-AdamW bilateral NEG (just closed), H241 Lion in flight. This hypothesis is NOT in the aux-replacement class.
- Cumulative: 94 NULL/NEG, 7 WIP, 41 mechanism classes.
- **This is the 42nd novel mechanism class.**

**Mechanism freshness verification:**
- Not a scalar HP change (outer_lr, outer_momentum are not being tuned here — the mechanism is the optimizer algorithm change).
- Not aux-optimizer replacement (H225, H237, H239, H241).
- Not MuLoCo HP tuning (H222, H229, H233).
- Not MuLoCo Polyak FORM (H236).
- Not depth-scaled per-layer LR (H244).
- Not ADana log-time β schedule (H245).
- Not inner MuonH momentum structure changes (H229, H232).
- Not initialization (H148, H203's body init merge).
- Closest prior: H236 Outer Polyak — but Polyak is a different update formula (uniform averaging vs adaptive moment tracking). The failure mechanism there was NS5 polar projection geometry incompatibility with averaging. Adam does not average; it adapts step sizes per coordinate.
