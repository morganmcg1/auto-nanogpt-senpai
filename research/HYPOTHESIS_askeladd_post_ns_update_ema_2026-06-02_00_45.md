# askeladd — Body-PMuon post-NS update EMA bilateral (uniform α=0.3 vs block-varying α=0.1→0.5)

## Context

Baseline #1532: aux β₂ pulse 0.95→0.99 @ step 975 → `speedrun/first_step_to_target` (sr) = **2875**, `val/loss_ema` = **3.262854**.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

The recent plateau (5+ consecutive bilateral NULLs at sr=2925 on schedule-shape axes — paramEMA refresh α-blend, NS_ITERS cooldown, paramEMA β ramp shape, block-LR ramp shape, block-LR slope magnitude) suggests the next mechanism axis must be **structural**, not another scalar schedule sweep. The researcher's plateau diagnosis points to *insufficient update persistence in the late-cooldown regime (steps 3000–3250)*: the body-PMuon polar projection produces a fresh orthogonal direction every step with no temporal smoothing of the polar output itself.

This hypothesis tests **applying an EMA to the post-Newton-Schulz update**, decoupling the polar projection from update persistence. Aligns with directive #1252 (a) — optimizer-state rescaling at phase transitions — by introducing a new persistence buffer at the polar output. Avoids directive (e) — this is NOT a β/μ/EMA scalar sweep; it's a new state buffer at the post-polar update site.

## Hypothesis

A learnable persistence layer on the post-NS update — `update_ema ← α · update_ema + (1−α) · update_polar` — improves late-cooldown gradient descent by averaging directional noise of the polar projection across consecutive steps. Two arms test whether uniform-block smoothing or block-depth-varying smoothing is the right shape:

- **Arm A (uniform):** Single α applied to all body-PMuon parameters. Tests whether *any* update persistence beats zero persistence.
- **Arm B (block-varying):** α linearly interpolated by block depth, from `α_min=0.1` at block 0 to `α_max=0.5` at the deepest block. Tests whether late layers (which carry the high LR multiplier from the merged `late-higher` block-LR pattern) benefit from MORE smoothing than early layers (lower variance updates).

Mean α across blocks in Arm B equals Arm A's α=0.3, so they are matched on global smoothing strength.

## Implementation

**File:** `records/track_3_optimization/train_gpt_simple.py`

### CLI flags

Add to argparser (around line 67–80, alongside `--muon_block_lr_pattern`):

```python
parser.add_argument("--pmuon_update_ema_alpha_uniform", type=float, default=-1.0,
                    help="Uniform Post-NS update EMA α (Arm A). -1 disables.")
parser.add_argument("--pmuon_update_ema_alpha_min", type=float, default=-1.0,
                    help="Block-varying Post-NS update EMA α minimum at block 0 (Arm B). -1 disables.")
parser.add_argument("--pmuon_update_ema_alpha_max", type=float, default=-1.0,
                    help="Block-varying Post-NS update EMA α maximum at deepest block (Arm B). -1 disables.")
```

Validate: only one of `_uniform` or (`_min`,`_max`) may be enabled (assert).

### Per-param α mapping

In the same region where `param_lr_mults` is built (around line 812–836), build a sibling dict `param_update_ema_alphas` keyed by `id(p)`:

- Arm A (uniform): every body-PMuon p gets `α = args.pmuon_update_ema_alpha_uniform`.
- Arm B (block-varying): for each body-PMuon param p mapped to transformer block `idx ∈ [0, n_blocks-1]`, set `α = α_min + (α_max - α_min) * idx / (n_blocks - 1)`.

Attach to optimizer2: `optimizer2._param_update_ema_alphas = param_update_ema_alphas`.

Log per-block α at step 0 (similar to the existing `muon_block_lr_mult/block_*` logging at line 834).

### State init

In `Muon.step()` (lines 596–600), after the existing `state["momentum"]`/`state["L"]`/`state["R"]` init block:

```python
if "update_ema" not in state:
    state["update_ema"] = torch.zeros_like(p)
```

Only initialize if EMA is enabled for this p (i.e., `param_update_ema_alphas is not None and id(p) in param_update_ema_alphas`).

### Apply EMA at the update site

In `Muon.step()` (line 613, AFTER the `pmuon_update(...)` call returns `update`, BEFORE the floor mechanism at line 614):

```python
param_update_ema_alphas = getattr(self, "_param_update_ema_alphas", None)
if param_update_ema_alphas is not None:
    alpha = param_update_ema_alphas.get(id(p), None)
    if alpha is not None and alpha > 0.0:
        # update_ema ← α · update_ema + (1-α) · update
        state["update_ema"].lerp_(update, 1.0 - alpha)
        update = state["update_ema"].clone()
```

Use `.clone()` so the subsequent in-place `update.mul_(TARGET_UW / ratio)` floor rescaling does not mutate the persistent EMA buffer.

### Telemetry

Log to W&B at the same cadence as other PMuon diagnostics:

- `pmuon_update_ema/active` (0/1)
- `pmuon_update_ema/alpha_block_0`
- `pmuon_update_ema/alpha_block_11`
- `pmuon_update_ema/alpha_mean`
- `pmuon_update_ema/buffer_norm_sample` — Frobenius norm of one sampled `state["update_ema"]` (the same one the polar diagnostic samples)

## Reproduce commands

**Arm A (uniform α=0.3):**
```bash
torchrun --nproc-per-node=1 records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.025 --muon_block_lr_pattern late-higher \
  --aux_b2_pulse_step 975 --aux_b2_warmup 250 --aux_b2_target 0.99 --aux_b2_init 0.95 \
  --paramema_refresh_step 2600 --paramema_refresh_alpha 1.0 \
  --pmuon_update_ema_alpha_uniform 0.3 \
  --wandb_group g1r1-askeladd-post-ns-ema
```

**Arm B (block-varying α: 0.1 → 0.5):**
```bash
torchrun --nproc-per-node=1 records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.025 --muon_block_lr_pattern late-higher \
  --aux_b2_pulse_step 975 --aux_b2_warmup 250 --aux_b2_target 0.99 --aux_b2_init 0.95 \
  --paramema_refresh_step 2600 --paramema_refresh_alpha 1.0 \
  --pmuon_update_ema_alpha_min 0.1 --pmuon_update_ema_alpha_max 0.5 \
  --wandb_group g1r1-askeladd-post-ns-ema
```

Use the chain script to run Arm A → Arm B sequentially. Stop and post terminal `SENPAI-RESULT` after each arm completes.

## Success criteria

- **Merge winner:** Either arm achieves `sr ≤ 2862.5` OR `sr = 2875 AND val_ema < 3.262854`.
- **Promising for follow-up:** `sr = 2875` and val_ema marginally above baseline (within 0.001), OR clear directional signal (e.g., Arm B materially differs from Arm A in val_ema trajectory) suggesting block-varying α deserves a finer sweep.
- **Bilateral NULL:** Both arms `sr ≥ 2900`. Close and escalate to the next structural axis.

## Sentinels and verification

- **Step 0 sanity:** Print `pmuon_update_ema ENABLED: mode=uniform alpha=0.3` (Arm A) or `mode=block-varying alpha=[0.1, ..., 0.5]` (Arm B) at step 0. Confirm in stdout.
- **Backward-compat:** With all three flags at default (-1.0), the new EMA branch is gated off and behavior must be bit-identical to baseline. Run a 50-step debug to confirm parity vs the merged baseline.
- **Buffer growth:** `pmuon_update_ema/buffer_norm_sample` should be non-zero from step ~5 onward (EMA warms quickly at α=0.3).

## Expected gain

Plateau-breaking. The TOP-ranked researcher idea for the current diagnosed bottleneck. If neither arm hits the merge gate, the *direction of update persistence* axis is closed and we escalate to update-clipping / cross-block alignment / signum-PMuon next.

## Estimated LOC delta

~30 LOC (flag parsing + per-param dict + state init + 5-line EMA apply + telemetry).
