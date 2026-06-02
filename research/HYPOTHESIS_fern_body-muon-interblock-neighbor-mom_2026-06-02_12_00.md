# HYPOTHESIS: Body Muon inter-block neighbor momentum averaging

**Student:** g1r1-fern
**Date:** 2026-06-02
**Directive alignment:** #1252 (b) per-layer/per-block optimizer behavior, (d) momentum/preconditioner state handling

---

## One-line summary

At each PMuon step, blend each transformer block's momentum buffer with a weighted average from its neighboring blocks, allowing gradient information to flow laterally across adjacent layers before the preconditioned update.

---

## Mechanism and motivation

**Current behavior:** Each of the 12 transformer blocks owns an independent PMuon momentum buffer. The per-block momentum evolves entirely from that block's local gradient history. No information crosses block boundaries during the optimizer step.

**Proposed change:** After computing the raw gradient for each block but before (or after) the momentum update, blend adjacent block momentum buffers. For block i:

```
m_i ← (1-α)·m_i + (α/2)·m_{i-1} + (α/2)·m_{i+1}
```

Boundary blocks use only the single available neighbor:
- Block 0: `m_0 ← (1-α)·m_0 + α·m_1`
- Block 11: `m_{11} ← (1-α)·m_{11} + α·m_{10}`

**Why this might help:** The late-higher block-LR WIN (PR baseline) shows the optimizer is sensitive to per-block asymmetry. Deep blocks and shallow blocks occupy different phases of feature transformation, but adjacent blocks share representational proximity — their effective loss landscapes are correlated at medium timescales. Sharing momentum laterally could reduce the variance in preconditioned update directions across neighboring blocks, stabilizing the training trajectory, and potentially allowing higher effective learning rates in the middle blocks where gradient signal accumulates noise.

This is a structural per-block mechanism (directive 1252-b, 1252-d), not a scalar sweep.

**Why it might not help:** If block gradients are already sufficiently decorrelated, averaging hurts by blurring distinct update signals. The per-block LR ramp already accounts for the depth asymmetry; adding momentum sharing could redundantly smooth what the LR differential is already supposed to differentiate.

**Falsification signal:** If val_ema worsens vs baseline for both arms at step 2925, the hypothesis is false — block gradient directions are decorrelated enough that sharing corrupts rather than stabilizes. If only the stronger blend (Arm B α=0.15) fails while Arm A (α=0.05) is NULL rather than regresses, the blend is too noisy but the mechanism might survive at α << 0.05.

---

## Prior art search

All searches confirmed this axis is pristine.

| Search query | Result count | Verdict |
|---|---|---|
| `"muon momentum interblock neighbor averaging"` | ~5 (0 matching) | PRISTINE |
| `"muon momentum twin block neighbor"` | 0 | CONFIRMED PRISTINE |
| `"inter-block momentum sharing"` | ~5 (0 matching) | PRISTINE |

No closed PR covers adjacent-block momentum blending in the PMuon update. The closest related experiments are per-block LR magnitude (closed) and body-PMuon β₁ block-strat ramp (in-flight thorfinn #2256), but those are scalar hyperparameter differences — not structural momentum-state sharing.

---

## Implementation

**Target function:** `pmuon_update()` in `records/track_3_optimization/train_gpt_simple.py`, or the outer PMuon step loop that iterates over blocks.

**LOC delta:** ~20 lines.

### Step 1 — Add CLI flag

```python
parser.add_argument('--muon_interblock_mom_alpha', type=float, default=0.0,
                    help='Inter-block momentum sharing weight for PMuon. '
                         '0 (default) = no sharing. '
                         'Positive = blend each block momentum with neighbors: '
                         'm_i <- (1-alpha)*m_i + (alpha/2)*m_{i-1} + (alpha/2)*m_{i+1}.')
```

### Step 2 — Collect block momentum states before the update

The PMuon step iterates over optimizer2 param groups (one per block). Before processing any block, collect references to all momentum buffers:

```python
# Collect momentum buffer references for all body blocks
block_mom_states = []
for group in optimizer2.param_groups:
    # Each block may have multiple params; collect per-param or per-group aggregate
    # If using a single momentum buffer per block (common in per-block Muon), collect it
    for p in group['params']:
        if p.grad is not None:
            state = optimizer2.state[p]
            if 'momentum_buffer' in state:
                block_mom_states.append(state['momentum_buffer'])
```

### Step 3 — Apply inter-block blend after momentum update

After the standard Muon momentum update for all blocks, apply the blend:

```python
alpha = args.muon_interblock_mom_alpha
if alpha > 0.0 and len(block_mom_states) > 1:
    n = len(block_mom_states)
    # Clone to avoid in-place mutation affecting neighbors
    orig = [m.clone() for m in block_mom_states]
    for i, m in enumerate(block_mom_states):
        if i == 0:
            m.mul_(1 - alpha).add_(orig[1], alpha=alpha)
        elif i == n - 1:
            m.mul_(1 - alpha).add_(orig[n - 2], alpha=alpha)
        else:
            m.mul_(1 - alpha).add_(orig[i - 1], alpha=alpha / 2)
            m.add_(orig[i + 1], alpha=alpha / 2)
```

**Critical detail:** Clone before blending — do not update block i using the already-blended state of block i-1.

### Step 4 — Log blend alpha

```python
if args.rank == 0:
    wandb.log({'train/muon_interblock_alpha': args.muon_interblock_mom_alpha}, step=step)
```

---

## Two arms (bilateral)

Both arms use full baseline stack plus the inter-block sharing flag.

| Arm | Flag | Blend weight | Description |
|---|---|---|---|
| **A** | `--muon_interblock_mom_alpha 0.05` | α=0.05 | Light sharing — 5% of each block's momentum bleeds into neighbors |
| **B** | `--muon_interblock_mom_alpha 0.15` | α=0.15 | Moderate sharing — 15% blending |

---

## Baseline stack (required in all reproduce commands)

```
--muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
--muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600 \
--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

## Reproduce command (Arm A)

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_interblock_mom_alpha 0.05 \
  --wandb_name "fern/body-muon-interblock-mom-alpha0.05" \
  --wandb_group "body-muon-interblock-neighbor-mom"
```

## Reproduce command (Arm B)

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_interblock_mom_alpha 0.15 \
  --wandb_name "fern/body-muon-interblock-mom-alpha0.15" \
  --wandb_group "body-muon-interblock-neighbor-mom"
```

---

## Merge gate

**Current baseline (PR #1532):**
- `speedrun/final_first_step_to_target`: **2875** (n=2, seeds `9coyk2ke`/`09qrijtm`)
- `val/loss_ema`: **3.262854**
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

---

## Expected result and failure modes

- **WIN signal:** sr ≤ 2862.5 or val_ema < 3.262854 at n=2 seeds, indicating that cross-block momentum smoothing improves training trajectory.
- **NULL:** Both arms at sr=2925 with val_ema near baseline. Interpretation: block gradient directions are sufficiently decorrelated that blending adds no useful signal.
- **REGRESSION:** val_ema > 3.262854 + 0.004 at sr=2925. Interpretation: the blend corrupts block-specific preconditioned directions; reduces effective block diversity. **Close the axis** if both arms regress.
- **Arm A passes, Arm B fails:** Confirms mechanism is alive but α is sensitive — recommend follow-up at α=0.02 and α=0.08.

---

## Notes for student

1. The blend must happen using **cloned pre-blend states** — never let block i's already-updated momentum contaminate block i+1's blend.
2. The blend should happen at a consistent point in the step: either always before the NS5 polar projection or always after momentum EMA update but before NS application. Pick one and document which.
3. If block momentum buffers are not directly indexed (e.g., they are scattered per-param), collect them in block-order first by iterating param_groups in block order.
4. Run a quick 50-step debug to confirm `train/muon_interblock_alpha` appears in W&B and gradients are finite.
5. The 3250-step bilateral run is the standard confirmation length. Do not kill before step 2925.
