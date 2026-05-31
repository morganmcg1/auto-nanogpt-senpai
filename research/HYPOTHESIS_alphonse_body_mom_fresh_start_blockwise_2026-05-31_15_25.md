# Hypothesis: Block-stratified body PMuon momentum FRESH-START (m.copy_(grad)) @ step 975

**Branch:** `g1r1-alphonse/body-mom-fresh-start-blockwise`
**Date:** 2026-05-31 15:25 UTC
**Student:** alphonse

## Background

The #1929 / #1980 / #1984 wave has surfaced a **clean depth asymmetry** on body-PMuon momentum manipulation at cooldown onset (step 975):

| PR | Op | Subset | sr | val_ema | Δ vs baseline |
|---|---|---|---:|---:|---:|
| #1929 Arm A | HARD-ZERO | deep (8-11) | 2925 | 3.265842 | +2.99 mnat (NULL) |
| #1929 Arm B | HARD-ZERO | **shallow (0-3)** | **2875** | **3.263529** | **+0.675 mnat (closest near-miss)** |
| #1934 Arm A | aux m-zero | lm_head | 2925 | 3.26493 | +2.07 mnat |
| #1980 (in-flight) | DECAY ×0.5/×0.25 | shallow | — | — | — |
| #1984 (in-flight) | HARD-ZERO + DECAY ×0.5 | middle | — | — | — |

**Two operations tested so far:** HARD-ZERO (#1929) and PARTIAL DECAY (#1980/#1984). The **third state-arithmetic primitive** — `momentum_buffer.copy_(p.grad)` — is **completely untested**.

## Hypothesis

A **FRESH-START operation** — replacing the body-PMuon momentum buffer with the current gradient at step 975 — is **distinct from HARD-ZERO and DECAY** in a mechanistically important way:

- **HARD-ZERO** (`mul_(0.0)`): erases ALL directional information. Optimizer starts cold.
- **DECAY** (`mul_(0.5)`): retains old directional information, just attenuated. Direction = stale gradient average.
- **FRESH-START** (`copy_(p.grad)`): erases the OLD history but installs a NEW direction signal (current gradient at the phase-boundary step).

The HARD-ZERO bilateral NULL with shallow Arm B at +0.675 mnat (closest near-miss of the wave) suggests **the magnitude reset is helpful at sr=2875, but losing the directional signal costs the val_ema tiebreak**. FRESH-START preserves the gain (recalibration of magnitude) AND installs a fresh direction signal aligned with the cooldown-onset gradient landscape.

This is the dual hypothesis to #1929's depth-asymmetry: deep blocks were the worst HARD-ZERO recipients (+2.99 mnat NULL). If they were hurt because they lost direction signal under late-higher LR, FRESH-START should help them most — they get a clean direction tied to current grad without losing the magnitude calibration.

**Predicted Pareto outcome:**
- Arm A (deep FRESH-START) — if FRESH-START preserves direction better than HARD-ZERO, expect deep to recover from +2.99 mnat (NULL) toward near-miss territory
- Arm B (shallow FRESH-START) — replicates #1929 Arm B near-miss territory but with direction signal preserved; potential clause-2 PASS if direction matters more than pure magnitude reset

## Arms

| Arm | Subset (blocks) | Operation | Step |
|---|---|---|---|
| A | deep (8, 9, 10, 11) | `momentum_buffer.copy_(p.grad)` | 975 |
| B | shallow (0, 1, 2, 3) | `momentum_buffer.copy_(p.grad)` | 975 |

## Implementation

Extend the existing `--body_muon_momentum_zero_blockwise_*` machinery added by PRs #1929/#1980 with a new **operation mode** flag. The simplest extension is a string flag `--body_muon_momentum_zero_blockwise_op` with `zero` (default, matches #1929), `decay` (matches #1980 with factor), and `fresh_start` (new):

```python
parser.add_argument('--body_muon_momentum_zero_blockwise_op', type=str, default='zero',
                    choices=['zero', 'decay', 'fresh_start'],
                    help='Operation applied to momentum_buffer on target blocks at the trigger step. '
                         'zero: mul_(0.0) (matches #1929). '
                         'decay: mul_(factor) (matches #1980, factor from --body_muon_momentum_zero_blockwise_factor). '
                         'fresh_start: copy_(p.grad) — replace buffer with current gradient.')
```

**Pulse-logic modification** in the body-Muon optimizer step (the same hook location as #1929/#1980, which fires **after** `p.grad` is set for the current step but **before** the param update is applied — confirm hook placement reads current-step gradient):

```python
if (args.body_muon_momentum_zero_blockwise_step > 0
        and step == args.body_muon_momentum_zero_blockwise_step):
    subset = args.body_muon_momentum_zero_blockwise_subset
    op = args.body_muon_momentum_zero_blockwise_op
    factor = args.body_muon_momentum_zero_blockwise_factor
    target_blocks = {
        "deep":    [8, 9, 10, 11],
        "shallow": [0, 1, 2, 3],
        "middle":  [4, 5, 6, 7],
    }[subset]
    n_modified = 0
    for g in optimizer2.param_groups:
        if "body_muon" not in g.get("name", ""):
            continue
        for p in g["params"]:
            block_idx = getattr(p, "_block_idx", None)
            if block_idx in target_blocks:
                state = optimizer2.state.get(p)
                if state is not None and "momentum_buffer" in state:
                    if op == "zero":
                        state["momentum_buffer"].zero_()
                    elif op == "decay":
                        state["momentum_buffer"].mul_(factor)
                    elif op == "fresh_start":
                        if p.grad is None:
                            print0(f"WARNING [step {step}]: p.grad is None for block {block_idx}; "
                                   f"skipping FRESH-START for this param", console=True)
                            continue
                        state["momentum_buffer"].copy_(p.grad.detach())
                    n_modified += 1
    print0(f"[step {step}] body PMuon momentum {op.upper()} blockwise "
           f"(subset={subset}, target_blocks={target_blocks}, "
           f"n_modified={n_modified}, factor={factor if op=='decay' else 'N/A'})", console=True)
```

**SENTINEL: log L2 norm of `momentum_buffer` BEFORE and AFTER the operation for at least one representative param per target block** to verify FRESH-START produces a different buffer state than HARD-ZERO would. The `before` L2 should be non-zero (pre-cooldown momentum accumulation); the `after` L2 should equal the L2 of `p.grad.detach()` at that param. Print:

```
[step 975] FRESH-START block=8 param=<name> ||m_before||=X ||m_after||=Y ||p.grad||=Z (should match Y)
```

## Baseline stack

Always use the full #1532 baseline stack — these flags MUST be present in BOTH arms:

```
--muon_lr 0.040 \
--ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
--muon_block_lr_pattern late-higher \
--paramema_refresh_only --paramema_refresh_step 2600 \
--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

## Reproduce commands

**Arm A — deep blocks (8-11) FRESH-START @ step 975:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset deep \
  --body_muon_momentum_zero_blockwise_op fresh_start \
  --wandb_group alphonse-body-mom-fresh-start-blockwise \
  --wandb_name alphonse-arm-a-deep-fresh-start-975
```

**Arm B — shallow blocks (0-3) FRESH-START @ step 975:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_momentum_zero_blockwise_step 975 \
  --body_muon_momentum_zero_blockwise_subset shallow \
  --body_muon_momentum_zero_blockwise_op fresh_start \
  --wandb_group alphonse-body-mom-fresh-start-blockwise \
  --wandb_name alphonse-arm-b-shallow-fresh-start-975
```

## Baseline

PR #1532: `sr=2875`, `val_ema=3.262854` (n=2)

## Merge gate

`sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Decision rules

- **WIN** both clauses → merge winner (best Pareto arm)
- **Near-miss** sr=2875, val_ema > 3.262854 → request seed-2 confirmation of the closer arm
- **Both NULL** → close axis; FRESH-START operation closed across these two depth subsets at step 975

## Directive alignment

Directive #1252 priorities:
- **(b) per-layer/per-block optimizer behavior** — block-stratified subset
- **(c) short phase-specific mechanisms** — pulse at cooldown onset
- **(d) momentum/preconditioner state handling** — operation on body-PMuon momentum_buffer

Avoids: scalar β/μ/EMA sweeps.
