# nezuko — Lm_head SECOND aux Adam β₂ pulse at pEMA refresh boundary (step 2600) bilateral (β₂=0.99 vs β₂=0.999)

## Context

Baseline #1532: aux β₂ pulse 0.95→0.99 @ step 975 → `speedrun/first_step_to_target` (sr) = **2875**, `val/loss_ema` = **3.262854**.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

The plateau diagnosis (RESEARCH_IDEAS 2026-06-02_00-30) identifies the late-cooldown regime (steps 3000–3250) as the binding window: val_ema is not converging fast enough in the final 250 steps. The aux Adam β₂ pulse @ step 975 (PR #1532 confirmed WIN) recalibrates the Adam denominator's v-state at the cooldown onset phase boundary. PR #2086 (askeladd) tested *per-group decomposition of the @975 pulse* (Arm A embed-only, Arm B lm_head-only) → bilateral NULL: the @975 pulse needs all aux groups together.

This hypothesis tests a **second phase-boundary pulse** at step 2600 (the paramEMA refresh boundary) targeting **only the lm_head** Adam group. Mechanistically distinct from #2086 because:

- #2086 sweeps which groups receive the EXISTING @975 pulse (timing fixed, scope varied)
- This hypothesis ADDS a NEW PULSE at a NEW timing (step 2600 = paramEMA refresh boundary) for ONE group (lm_head) — directive (a) optimizer-state rescaling at phase transitions, directive (c) phase-specific mechanisms active only pre-target-crossing, directive (b) per-layer behavior

The lm_head receives the largest gradient signal in the network (~3× attention weights) due to the cross-entropy loss. At step 2600, LR has decayed to ~24% of peak, so absolute gradient magnitudes have shrunk substantially. The lm_head's Adam v-state still carries long-horizon gradient-squared estimates from the high-LR regime, leaving its denominator mis-calibrated to the current (late-cooldown) gradient scale. A targeted β₂ recalibration at the pEMA refresh boundary tests whether lm_head v-state freshness in the final 650 steps is load-bearing for target-crossing speed.

## Hypothesis

A SECOND β₂ pulse at step 2600, applied ONLY to the `adam_lm_head` parameter group, improves val_ema convergence in the final 250 steps by maintaining a denominator that tracks the current (late-cooldown) gradient scale rather than retaining the long-horizon estimate. Two arms test how aggressive that recalibration should be:

- **Arm A** (`lm_head_b2_pulse_target=0.99`): match the @975 pulse value (effective window ~100 steps from step 2600). Conservative — same "tight β₂" semantics as the confirmed @975 pulse, applied at the new phase boundary.
- **Arm B** (`lm_head_b2_pulse_target=0.999`): aggressive recalibration (effective window ~1000 steps). Maximum late-phase denominator sensitivity to recent gradient squared, trading bias for variance reduction in the final 650 steps.

The arms test "match @975" vs "even tighter than @975" for the second pulse semantics.

## Implementation

**File:** `records/track_3_optimization/train_gpt_simple.py`

### CLI flags

Add to argparser (alongside `--aux_b2_pulse_step` / `--aux_b2_pulse_target`):

```python
parser.add_argument("--lm_head_b2_pulse_step", type=int, default=-1,
                    help="Step at which to repulse β₂ on adam_lm_head group only. -1 disables.")
parser.add_argument("--lm_head_b2_pulse_target", type=float, default=0.99,
                    help="β₂ target value for the lm_head-only repulse.")
```

### Pulse application

In the training loop where the existing `aux_b2_pulse` is applied (search for `aux_b2_pulse_step` — should be in the per-step pre-step setup section, around the area where β₂ is updated for the aux Adam group), add a second conditional:

```python
if (args.lm_head_b2_pulse_step > 0
        and step == args.lm_head_b2_pulse_step):
    for group in optimizer1.param_groups:
        if group.get("name") == "adam_lm_head":
            old_b2 = group["betas"][1]
            group["betas"] = (group["betas"][0], args.lm_head_b2_pulse_target)
            print0(f"[step {step}] lm_head_b2_pulse: β2 {old_b2} → {args.lm_head_b2_pulse_target}",
                   console=True)
            break
```

**IMPORTANT:** The aux Adam group naming. Verify by reading the optimizer construction section — the lm_head group must be named exactly `"adam_lm_head"` (or whatever the existing code uses). If the existing param-group split into adam_embed / adam_lm_head / adam_scalars uses different naming, match it. Print a sentinel at step 0 listing all aux Adam group names so a mismatch is caught early.

### Telemetry

Log to W&B at standard cadence:

- `lm_head_b2_pulse/active` (0/1)
- `lm_head_b2_pulse/step` (the step set)
- `lm_head_b2_pulse/target` (the β₂ target)
- `lm_head_b2_pulse/triggered_at` (1 starting at step=pulse_step, 0 before; verifies the pulse actually fired)

### Step 0 sanity

Print at step 0 a one-line summary:

```
[step 0] lm_head_b2_pulse ENABLED: step=2600 target=0.99 group=adam_lm_head
```

Confirm in stdout that the group name matches the actual `optimizer1.param_groups` naming. Print all aux Adam group names so any naming mismatch is visible immediately.

### Backward-compat smoke test

With `--lm_head_b2_pulse_step -1` (default), behavior must be bit-identical to the merged baseline. Run a 50-step debug with all baseline flags and `--lm_head_b2_pulse_step -1` and confirm parity vs the merged baseline run.

## Reproduce commands

**Arm A (target=0.99, match @975 semantics):**
```bash
torchrun --nproc-per-node=1 records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.025 --muon_block_lr_pattern late-higher \
  --aux_b2_pulse_step 975 --aux_b2_warmup 250 --aux_b2_target 0.99 --aux_b2_init 0.95 \
  --paramema_refresh_step 2600 --paramema_refresh_alpha 1.0 \
  --lm_head_b2_pulse_step 2600 --lm_head_b2_pulse_target 0.99 \
  --wandb_group g1r1-nezuko-lmhead-b2-repulse-2600
```

**Arm B (target=0.999, aggressive late-phase v-state):**
```bash
torchrun --nproc-per-node=1 records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.025 --muon_block_lr_pattern late-higher \
  --aux_b2_pulse_step 975 --aux_b2_warmup 250 --aux_b2_target 0.99 --aux_b2_init 0.95 \
  --paramema_refresh_step 2600 --paramema_refresh_alpha 1.0 \
  --lm_head_b2_pulse_step 2600 --lm_head_b2_pulse_target 0.999 \
  --wandb_group g1r1-nezuko-lmhead-b2-repulse-2600
```

Use the chain script to run Arm A → Arm B sequentially. Stop and post terminal `SENPAI-RESULT` after each arm completes.

## Success criteria

- **Merge winner:** Either arm achieves `sr ≤ 2862.5` OR `sr = 2875 AND val_ema < 3.262854`.
- **Promising for follow-up:** `sr = 2875` and val_ema marginally above baseline (within 0.001), OR clear directional signal between Arm A (0.99) and Arm B (0.999) suggesting target β₂ deserves a finer sweep around the winning direction.
- **Bilateral NULL:** Both arms `sr ≥ 2900`. Close and the lm_head-second-pulse axis is exhausted at the pEMA boundary.

## Sentinels and verification

- **Step 0 sanity:** Print one-line lm_head_b2_pulse enable summary including the actual `optimizer1.param_groups` group names so a name mismatch (e.g., `adam_lm_head` vs `lm_head_adam`) is caught.
- **Pulse fired:** `lm_head_b2_pulse/triggered_at` telemetry must flip 0→1 at step 2600. If it stays 0, the group name didn't match — fix and relaunch.
- **Backward-compat:** With `--lm_head_b2_pulse_step -1` (default), 50-step debug must match merged baseline bit-for-bit.

## Expected gain

Frontier refinement of a confirmed WIN at a new phase boundary. The plateau diagnosis identifies the late-cooldown regime as the binding window; this hypothesis tests whether the lm_head's v-state denominator is the specific component that needs refreshing at the pEMA refresh boundary. If neither arm hits the merge gate, the second-pulse-at-pEMA-boundary axis is closed and we move to either NS coefficient phase-adaptation (Idea 6) or cross-block alignment (Idea 8).

## Estimated LOC delta

~12 LOC (2 CLI args + pulse conditional + telemetry + step-0 sentinel).
