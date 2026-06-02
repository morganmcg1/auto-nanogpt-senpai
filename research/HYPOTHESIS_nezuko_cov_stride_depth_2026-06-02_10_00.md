# Hypothesis: PMuon Covariance EMA Update Stride Stratified by Block Depth (nezuko)

**Assigned:** 2026-06-02 10:00 UTC
**Student:** g1r1-nezuko
**Branch:** g1r1-nezuko/cov-stride-depth
**Directive alignment:** (b) per-layer/per-block optimizer behavior, (d) preconditioner state handling

## Mechanism hypothesis

PMuon computes the whitening preconditioner via bilateral covariance EMAs:
```
L_cov ← β_cov * L_cov + (1 - β_cov) * (G @ G.T)
R_cov ← β_cov * R_cov + (1 - β_cov) * (G.T @ G)
```
Currently all 12 transformer blocks update L_cov/R_cov at **every step** with the same β_cov=0.95.

The gradient distribution stationarity hypothesis: transformer blocks at different depths have qualitatively different gradient stationarity profiles during training:

- **Shallow blocks** (layers 0-5): Handle low-level syntactic/token-level features. Their gradient covariance structure stabilizes early and changes slowly thereafter. The marginal value of a fresh covariance estimate at step t+1 vs t is low.
- **Deep blocks** (layers 6-11): Handle high-level semantic representations that continue adapting throughout cooldown. Gradient covariance evolves faster, especially at cooldown onset (step 975) and pre-target window.

If true, updating L_cov/R_cov every step for shallow blocks is wasteful. Skipping updates for deep blocks during cooldown would leave the preconditioner stale at exactly the moment when rapid adaptation is needed.

**Proposed intervention**: Per-block covariance update stride — shallow blocks use stride=2 (update every other step), deep blocks use stride=1 (update every step). This asymmetry concentrates compute where gradient statistics are most dynamic.

Secondary prediction: Even if stride=2 for shallow is "free" in loss terms, it releases a mild regularization effect — the preconditioner at shallow layers uses a slightly older (smoother) covariance estimate.

## Why this axis is pristine

All prior β_cov experiments changed the EMA *rate* (β decay constant), not the *frequency of update*.

- β_cov=0.9 (PR #502, #129): All blocks update every step, older gradients forgotten faster
- β_cov depth-split (PR #1727): Shallow/deep blocks use different β_cov values, but BOTH groups update every step
- Cov-reset experiments: Zeroed accumulated state at phase boundaries; did not skip updates

No experiment has set stride > 1 for any block. The stride axis is orthogonal to the rate axis.

## Bilateral arm design

**Arm A** — shallow stride=2, deep stride=1 (theory-consistent, favors deep freshness):
```
--cov_stride_shallow 2 --cov_stride_deep 1
```

**Arm B** — shallow stride=1, deep stride=2 (inverted, contrastive condition):
```
--cov_stride_shallow 1 --cov_stride_deep 2
```

Block boundary: layers 0-5 = shallow, layers 6-11 = deep. Use `block_idx < num_blocks // 2`.

## Implementation sketch

```python
parser.add_argument('--cov_stride_shallow', type=int, default=1)
parser.add_argument('--cov_stride_deep', type=int, default=1)

# Inside PMuon per-block covariance update loop:
num_blocks = len(self.param_groups_body)
for block_idx, group in enumerate(self.param_groups_body):
    is_shallow = block_idx < num_blocks // 2
    stride = args.cov_stride_shallow if is_shallow else args.cov_stride_deep

    if self.state['step'] % stride == 0:
        G = group['grad_matrix']
        group['L_cov'].mul_(beta_cov).add_((1 - beta_cov) * (G @ G.T))
        group['R_cov'].mul_(beta_cov).add_((1 - beta_cov) * (G.T @ G))
    # else: skip cov update this step; use cached L_cov/R_cov

    # Whitening proceeds unconditionally using whatever L_cov/R_cov is current
    update = apply_whitening(group['momentum'], group['L_cov'], group['R_cov'], gamma)
    group['param'].add_(-lr * update)
```

LOC delta: ~35. Runtime: ~2-3% faster on stride=2 blocks (half the cov matmuls). Each arm: ~3.5h.

## Reproduce commands (full baseline stack)

**Arm A (shallow stride=2, deep stride=1):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --cov_stride_shallow 2 --cov_stride_deep 1 \
  --wandb_group g1r1-nezuko-cov-stride-depth \
  --wandb_name g1r1-nezuko/cov-stride-depth-arm-a-shallow2-deep1
```

**Arm B (shallow stride=1, deep stride=2):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --cov_stride_shallow 1 --cov_stride_deep 2 \
  --wandb_group g1r1-nezuko-cov-stride-depth \
  --wandb_name g1r1-nezuko/cov-stride-depth-arm-b-shallow1-deep2
```

## Merge gate

Beat #1532 baseline: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Sentinel logging (REQUIRED)

At step 0 log per block: `block {idx} ({shallow|deep}): cov stride = {stride}`. Then on step 1, log a brief confirmation that the conditional update path fired for the expected blocks.

## Falsifying result

Both arms match baseline (within noise) → gradient stationarity-by-depth is not a leverage point; consider stride=4 or stride=8 to find where staleness matters.

## Stop / report

Post terminal SENPAI-RESULT for Arm A with `terminal=false, pending_arms=true`, then immediately launch Arm B. After Arm B terminal, post FINAL bilateral SENPAI-RESULT.
