---
student: g1r1-edward
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 20:45 UTC
directive_alignment: (b) per-layer / per-block optimizer behavior
---

# Hypothesis: Body-Muon per-block LR RAMP SHAPE bilateral — CONVEX (p=0.5) vs CONCAVE (p=2.0) vs baseline linear (p=1.0)

## Background

PR #2110 (thorfinn) confirmed late-higher block LR direction is load-bearing. PR #2171 (thorfinn, currently running) tests MAGNITUDE (spread=0.10 vs spread=0.30 vs baseline spread=0.20). Both of those address the linear-ramp parametrization — they vary the endpoints.

What has NEVER been tested is the SHAPE of the ramp. The baseline uses a linear interpolation from lo to hi across blocks 0–11:

```python
block_mults[i] = lo + (hi - lo) * (i / 11)   # linear, p=1.0
```

A power-law ramp generalizes this to any shape while keeping lo, hi, and mean LR fixed:

```python
block_mults[i] = lo + (hi - lo) * (i / 11)**p
```

- p=1.0 → linear (current baseline, straight ramp from block 0 to block 11)
- p<1.0 → CONVEX (concave-down / front-loaded): early blocks get disproportionately large LR boosts; the ramp rises steeply at first then flattens
- p>1.0 → CONCAVE (concave-up / back-loaded): late blocks get disproportionately large LR boosts; the ramp is flat early then rises steeply at the end

This shape parameter is fully orthogonal to the spread tested by thorfinn #2171 — it distributes the same total spread differently across the depth stack. The mechanism tests whether the GPT-2 residual stream has a non-linear depth-sensitive LR preference, or whether a plain linear ramp is optimal.

The baseline lo=0.90, hi=1.10, spread=0.20 is preserved in both arms. Only the shape changes.

## Hypothesis

If the residual stream gradient signal is dominated by the early layers (blocks 0–5), where the initial token representations are formed, a CONVEX ramp (p=0.5) should provide more LR differentiation where it matters most and outperform linear.

If the residual stream gradient signal is dominated by the late layers (blocks 6–11), which directly feed the lm_head, a CONCAVE ramp (p=2.0) that gives extreme boosts to block 10/11 should win.

If the linear allocation is already optimal → bilateral NULL closes the ramp-shape axis. Follow-up: try larger power contrasts (p=0.25 or p=4.0) or switch to block-group differentiation (early/mid/late triplets).

Asymmetric outcomes are most informative — they reveal whether the depth-LR preference is front-loaded or back-loaded and seed a follow-up.

## Implementation

**Add a new CLI flag** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument("--muon_block_lr_power", type=float, default=1.0,
                    help="Power exponent for per-block Muon LR ramp shape. "
                         "1.0 = linear (baseline). "
                         "0.5 = convex/front-loaded (ramp rises quickly then flattens). "
                         "2.0 = concave/back-loaded (ramp is flat then rises steeply). "
                         "Applies on top of --muon_block_lr_spread. "
                         "Active only when --muon_block_lr_pattern != 'none'. "
                         "Default 1.0 matches the merged baseline bit-exactly.")
```

**Modify the block_mults assignment** around the `late-higher` / `late-lower` block in `train_gpt_simple.py`. The existing linear line:

```python
block_mults = [lo + (hi - lo) * (i / (NUM_LAYERS - 1)) for i in range(NUM_LAYERS)]
```

should become:

```python
p = args.muon_block_lr_power
block_mults = [lo + (hi - lo) * (i / (NUM_LAYERS - 1))**p for i in range(NUM_LAYERS)]
```

For the `late-lower` pattern, the reversed sign of (hi - lo) means p > 1.0 will push the ramp *toward* block 0 (early blocks get the extreme LR reduction), which is consistent — power-law shape applies to the normalized position regardless of direction.

**Add sentinel logging at step 0** alongside existing `wandb.log(...muon_block_lr_mult/...)`:

```python
wandb.log({
    "optim/muon_block_lr_power": args.muon_block_lr_power,
    "optim/muon_block_0_lr_mult": block_mults[0],
    "optim/muon_block_5_lr_mult": block_mults[5],
    "optim/muon_block_11_lr_mult": block_mults[NUM_LAYERS - 1],
}, step=0)
```

The mid-point block_mults[5] is a useful diagnostic for shape: at p=1.0 it equals 0.9545; at p=0.5 it equals ~0.9714; at p=2.0 it equals ~0.9091.

**CRITICAL backward-compat check**: `--muon_block_lr_pattern late-higher --muon_block_lr_power 1.0` (or no flag at all) MUST reproduce the baseline trajectory bit-exactly. Run ~50 training steps and confirm loss matches baseline #1532 before launching the arms. This is the integrity guarantee for the experimental harness.

## Arms

### Arm A — CONVEX ramp (p=0.5, front-loaded)

Square-root shape. Early blocks get disproportionately large LR boosts; block 5 gets ~97.1% base LR (vs 95.5% for linear). Block 11 still gets 110%. The ramp concentrates most of its rise in the first 6 blocks then levels off.

Expected block_mults at key positions (lo=0.90, hi=1.10, p=0.5):
- Block 0: 0.900
- Block 3: ~0.977
- Block 5: ~0.996
- Block 8: ~1.053
- Block 11: 1.100

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_power 0.5 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-edward-block-lr-ramp-shape \
  --wandb_name g1r1-edward/block-lr-ramp-shape-convex-arm-a
```

### Arm B — CONCAVE ramp (p=2.0, back-loaded)

Quadratic shape. Late blocks get disproportionately large LR boosts; block 5 gets only ~90.9% base LR (vs 95.5% for linear). Block 11 still gets 110%. The ramp is nearly flat through the first 6 blocks then rises sharply at blocks 9–11.

Expected block_mults at key positions (lo=0.90, hi=1.10, p=2.0):
- Block 0: 0.900
- Block 3: ~0.917
- Block 5: ~0.941
- Block 8: ~1.012
- Block 11: 1.100

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --muon_block_lr_power 2.0 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-edward-block-lr-ramp-shape \
  --wandb_name g1r1-edward/block-lr-ramp-shape-concave-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (uses late-higher linear spread=0.20, power=1.0).

## Expected outcomes

- **Arm A WIN (convex p=0.5):** The LR gradient signal in the early residual layers is more important — front-loading LR differentiation is better than back-loading it. Follow-up: bracket between p=0.25 and p=0.75.
- **Arm B WIN (concave p=2.0):** The LR gradient signal is dominated by the final pre-lm_head layers — giving blocks 9–11 an extreme boost matters more than gradual differentiation. Follow-up: bracket between p=1.5 and p=3.0.
- **Bilateral NULL:** The linear ramp is optimal for this shape degree. Closes the power-law ramp-shape axis for p=0.5/2.0. Pivot to non-power-law shapes (sigmoid-shaped ramp, U-shaped dip, skip-layer differentiation) or close the entire per-block ramp sub-axis and move to directive (c).

## Chain rule

1. **Implement** `--muon_block_lr_power` flag.
2. **Verify** `--muon_block_lr_pattern late-higher --muon_block_lr_power 1.0` is bit-exact baseline (50-step smoke).
3. **Launch Arm A (convex, p=0.5) first.**
   - Clear NULL (val_ema worse than baseline by >2 mnat at sr=2875+) → launch Arm B immediately.
   - WIN candidate → seed-2 of WIN before Arm B.
4. Both arms terminal → post terminal SENPAI-RESULT and stop. Do NOT chain into follow-up brackets without advisor approval.

## Why this aligns with directive (b)

The per-block LR ramp is the canonical "per-layer/per-block optimizer behavior" knob in this codebase. PR #2110 closed the direction question (late-higher wins). PR #2171 (thorfinn, in flight) tests the magnitude (spread). This PR tests the third and final free parameter of the power-law ramp: its shape. Together the three PRs fully characterize the parameterized ramp space.

Shape and magnitude are fully orthogonal: thorfinn varies spread with p=1.0 fixed; edward varies p with spread=0.20 fixed. Even if thorfinn finds a different optimal spread, the shape results here will transfer — a better spread + better shape stack cleanly.

Directive (b) asks for per-layer/per-block behavior — this is a direct, pristine, untested lever on that axis.

## Notes

- Mean LR is NOT exactly preserved at 1.0 when p ≠ 1.0 with a symmetric lo/hi. For lo=0.90, hi=1.10, p=0.5: mean block_mult ≈ 1.0133 (slightly above 1.0). For p=2.0: mean block_mult ≈ 0.9867 (slightly below 1.0). The deviation is ~1.3% and is unlikely to matter, but worth logging via the sentinel at step 0. If this is a concern, the lo/hi can be re-centered to preserve the exact mean — but that would conflate shape and scale, so leave it uncorrected for a clean shape-only test.
- For Arm A (p=0.5), blocks 6–11 all get LR multipliers above 1.0 (ranging from ~1.004 to 1.10), just with a front-loaded rise. This should NOT cause instability since the late blocks are close to the linear baseline.
- For Arm B (p=2.0), blocks 0–7 all get LR multipliers below 1.0 (ranging from 0.90 to ~0.993). Watch first-50-step loss for unusual slowness in early training — if the early blocks are severely under-trained, flag and stop early.
- The `(i / (NUM_LAYERS - 1))**p` formula is well-defined for all p > 0 and all i in [0, NUM_LAYERS-1]. Edge blocks i=0 and i=11 are always exactly lo and hi regardless of p (since 0**p = 0 and 1**p = 1 for any p > 0).
