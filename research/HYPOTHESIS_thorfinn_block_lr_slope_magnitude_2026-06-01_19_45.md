---
student: g1r1-thorfinn
branch: auto-nanogpt-1gpu-r1
assigned: 2026-06-01 19:45 UTC
directive_alignment: (b) per-layer / per-block optimizer behavior
---

# Hypothesis: Body-Muon per-block LR SLOPE MAGNITUDE bilateral — NARROWER (±0.05) vs WIDER (±0.15) vs baseline late-higher (±0.10)

## Background

Closed PR #2110 (thorfinn block_lr_pattern bilateral) just confirmed the late-higher direction is load-bearing:
- Arm A `late-lower` (reversed): sr=2925, val_ema=3.266509 (+3.66 mnat vs baseline)
- Arm B `none` (uniform): sr=2925, val_ema=3.264531 (+1.68 mnat vs baseline)
- Baseline `late-higher` (lo=0.90, hi=1.10, slope=0.20): sr=2875, val_ema=3.262854

Both alternative directions FAIL the merge gate, and the depth-asymmetric ramp does +1.68 mnat of real work even against the uniform pattern. Direction is settled — the question now is whether the **slope magnitude (0.20 total spread)** is well-tuned.

The baseline implementation at `records/track_3_optimization/train_gpt_simple.py:817-821` hard-codes `lo=0.90, hi=1.10` for `late-higher`, with `block_mults[i] = lo + (hi - lo) * (i / 11)`. The total LR spread between block 0 and block 11 is fixed at 0.20 (i.e. block 11 trains 22% faster than block 0). This 0.20 value has never been challenged — it was inherited from an earlier merge, not optimized.

Student's #1 follow-up suggestion from #2110's SENPAI-RESULT was explicitly to "vary the slope magnitude". This hypothesis tests that directly. Directive (b) — per-layer/per-block behavior.

## Hypothesis

If 0.20 is well-tuned → both narrower (0.10) and wider (0.30) underperform baseline → bilateral NULL closes slope-magnitude axis.

If late-higher is undertuned (deeper blocks want even MORE LR) → wider (0.30) wins, narrower (0.10) loses.

If late-higher is overtuned (deeper blocks already get enough LR via residual scaling) → narrower (0.10) wins, wider (0.30) loses.

Asymmetric outcomes are most informative — they reveal the optimum is on one side of 0.20 and seed a follow-up bracket.

## Implementation

**Add a new CLI flag** to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument("--muon_block_lr_spread", type=float, default=0.20,
                    help="Total spread of per-block Muon LR ramp from block 0 to block 11. "
                         "lo = 1.0 - spread/2, hi = 1.0 + spread/2. Mean LR preserved at 1.0. "
                         "Active only when --muon_block_lr_pattern != 'none'. "
                         "Default 0.20 matches the merged late-higher baseline (lo=0.90, hi=1.10).")
```

**Modify the `late-higher` / `late-lower` block** around `train_gpt_simple.py:817-820`:

```python
if args.muon_block_lr_pattern != "none":
    half = args.muon_block_lr_spread / 2.0
    if args.muon_block_lr_pattern == "late-higher":
        lo, hi = 1.0 - half, 1.0 + half
    elif args.muon_block_lr_pattern == "late-lower":
        lo, hi = 1.0 + half, 1.0 - half
    block_mults = [lo + (hi - lo) * (i / (NUM_LAYERS - 1)) for i in range(NUM_LAYERS)]
    ...
```

**Add sentinel logging at step 0** alongside the existing `wandb.log(...muon_block_lr_mult/...)`:

```python
wandb.log({
    "optim/muon_block_lr_spread": args.muon_block_lr_spread,
    "optim/muon_block_0_lr_mult": block_mults[0],
    "optim/muon_block_11_lr_mult": block_mults[NUM_LAYERS - 1],
}, step=0)
```

**CRITICAL backward-compat check**: `--muon_block_lr_pattern late-higher --muon_block_lr_spread 0.20` MUST reproduce the baseline trajectory bit-exactly. Verify by running ~50 training steps and confirming loss matches baseline #1532. This is the integrity guarantee for the experimental harness.

## Arms

### Arm A — NARROWER late-higher (spread=0.10, lo=0.95, hi=1.05)

Half the slope magnitude. Block 0 gets 95% of base LR, block 11 gets 105%. Total ramp 0.10.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher --muon_block_lr_spread 0.10 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-thorfinn-block-lr-spread \
  --wandb_name g1r1-thorfinn/block-lr-spread-narrow-arm-a
```

### Arm B — WIDER late-higher (spread=0.30, lo=0.85, hi=1.15)

1.5× the slope magnitude. Block 0 gets 85% of base LR, block 11 gets 115%. Total ramp 0.30.

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher --muon_block_lr_spread 0.30 \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-thorfinn-block-lr-spread \
  --wandb_name g1r1-thorfinn/block-lr-spread-wide-arm-b
```

## Baseline gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline #1532: n=2 mean sr=2875, val_ema=3.262854 (uses late-higher spread=0.20).

## Expected outcomes

- **Arm A WIN (narrower):** late-higher is overtuned — block 11 doesn't need +10% LR, just +5%. Follow-up: bracket between 0.05 and 0.15.
- **Arm B WIN (wider):** late-higher is undertuned — deeper blocks want MORE relative LR. Follow-up: bracket between 0.30 and 0.50.
- **Bilateral NULL:** 0.20 is well-tuned. Closes slope-magnitude axis. Pivot to non-linear ramp shapes (concave / convex per-block curves) or block-group differentiation (early/mid/late triplet).

## Chain rule

1. **Implement** `--muon_block_lr_spread` flag.
2. **Verify** `late-higher --muon_block_lr_spread 0.20` is bit-exact baseline (50-step smoke).
3. **Launch Arm A (narrower) first.**
   - Clear NULL (val_ema worse than baseline by >2 mnat at sr=2875+) → launch Arm B immediately.
   - WIN candidate → seed-2 of WIN before Arm B.
4. Both arms terminal → post terminal SENPAI-RESULT and stop. Do NOT chain into follow-up brackets without advisor approval.

## Why this aligns with directive (b)

The per-block LR ramp is the canonical "per-block optimizer behavior" knob in this codebase. PR #2110 closed the direction question (late-higher wins). This PR closes the magnitude question on the same axis. Together they fully characterize the linear-ramp design. Directive (b) asks for per-layer/per-block behavior — this is a direct, pristine, untested lever on that axis.

## Notes

- Mean LR stays at 1.0 across both arms (block_mults sum = 12.0 by symmetry of linear ramp around 1.0). Total compute is unchanged.
- Arm A's narrower spread should NOT hurt block 11's training much — it still gets +5%, just less. If Arm A even matches baseline, that suggests the depth asymmetry is doing structural work beyond the specific 0.10 magnitude.
- Arm B's wider spread could expose block 0 instability (it gets only 85% of base LR) — watch first-50-step loss for unusual slowness; if so, flag and stop early.
