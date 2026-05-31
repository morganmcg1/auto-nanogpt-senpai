# Body PMuon momentum FRESH-START (m.copy_(p.grad)) @ step 2600 (pEMA refresh boundary) — bilateral by block scope

**Hypothesis owner:** nezuko (idle after #1946 γ-pulse bilateral NULL closure)
**Date:** 2026-05-31 19:30 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state resets at phase boundaries and (d) momentum/preconditioner state handling. The body-PMuon `momentum_buffer` axis has been bilaterally closed across HARD-ZERO and SCALE at multiple timings — except the **pEMA refresh boundary at step 2600**, which is uniquely the only phase boundary where the model's `paramema` buffer is re-seeded from current params (`--paramema_refresh_step 2600`). The body PMuon momentum buffer is NOT touched at this boundary; it continues to drag accumulated direction history through a paramEMA re-seed event.

## Mechanism

At step 2600 (pEMA refresh), the parameter EMA buffer is overwritten with current params. Simultaneously, the body PMuon `momentum_buffer` continues unchanged — accumulated direction from steps 1..2599 (weighted by μ=0.95, effective horizon ~20 steps). After re-seed, the EMA-tracked params and the live momentum buffer become misaligned: pEMA reflects current step's iterate state, but body momentum reflects the average direction OVER recent steps.

**FRESH-START** is the distinct third state-operation after HARD-ZERO (#1929 closed) and DECAY (#1797/#1836 closed). It replaces accumulated history with **current** gradient direction — re-seeding momentum from the iterate that pEMA just locked in.

Mechanistically: `m_t.copy_(p.grad)` at step 2600 makes the NS5 input on step 2601 equal to the freshest gradient (no historical averaging). This forces a one-step "raw gradient" update precisely at the boundary where pEMA captures the iterate snapshot, then natural μ=0.95 re-accumulation rebuilds the buffer with locally-current information across ~20 steps.

## Distinguishing from prior closures

| PR | mechanism | boundary | result |
|---|---|---|---|
| #1730 | momentum HARD-ZERO | 2750 (pre-target) | bilateral NULL |
| #1797 | momentum SCALE ×0.5/×0.25 | 975 (cooldown onset) | bilateral NULL |
| #1836 | momentum SCALE ×0.5/×0.25 | 2750 (pre-target) | bilateral NULL |
| #1929 | momentum HARD-ZERO BLOCKWISE | 975 (cooldown onset) | bilateral NULL |
| #1986 (in-flight) | momentum FRESH-START BLOCKWISE | 975 (cooldown onset) | pending |
| **this PR** | **momentum FRESH-START** | **2600 (pEMA refresh)** | — |

Mechanism is the same as alphonse #1986 (FRESH-START), but the boundary is unique — **the pEMA refresh boundary at step 2600 has never been tested for any body-momentum state operation**. This is the missing column in the (mechanism × boundary) matrix.

## Arms

**Arm A — JOINT all blocks**
- At step 2600, set `m.copy_(p.grad)` for ALL 72 body PMuon momentum buffers (12 blocks × 6 PMuon param groups)
- Mechanism: re-seed body momentum from current gradient at pEMA refresh boundary
- Tests aggregate effect across full model depth

**Arm B — DEEP blocks only (8-11)**
- At step 2600, set `m.copy_(p.grad)` for body PMuon momentum buffers in blocks 8-11 ONLY (24 buffers)
- Mechanism: localize the re-seed to late-higher-LR deep blocks (which already get amplified updates via late-higher block-LR pattern)
- Tests whether the late blocks (highest-LR, most-iterating) benefit asymmetrically from momentum re-seed

## Implementation

Code changes:
- Add CLI flags: `--muon_momentum_fresh_start_step` (default -1), `--muon_momentum_fresh_start_blocks` (default "all", or "deep" for 8-11)
- In training step loop, after backward but before optimizer.step, if `step == muon_momentum_fresh_start_step`:
  - Iterate body PMuon param groups, filter to selected blocks
  - For each param `p` with momentum state, set `state["momentum"].copy_(p.grad)`
  - Log count of buffers re-seeded
- Verification sentinel: `[step 2600] muon_momentum_fresh_start: copy_(grad) on N buffers (blocks={all|deep})`

State key is `state["momentum"]` (per #1730 implementation note).

## Reproduce commands

Full baseline stack required:

### Arm A — fresh-start ALL blocks @ step 2600
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_fresh_start_step 2600 \
  --muon_momentum_fresh_start_blocks all \
  --wandb_group g1r1-nezuko-body-mom-freshstart-2600 \
  --wandb_name g1r1-nezuko/body-mom-freshstart-2600-arm-a-all
```

### Arm B — fresh-start DEEP blocks (8-11) @ step 2600
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_fresh_start_step 2600 \
  --muon_momentum_fresh_start_blocks deep \
  --wandb_group g1r1-nezuko-body-mom-freshstart-2600 \
  --wandb_name g1r1-nezuko/body-mom-freshstart-2600-arm-b-deep
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` (with seed-2 confirmation for sr=2875 wins)
- Promising: sr=2875 ties baseline + val_ema improves marginally (request seed-2)
- NULL: sr ≥ 2900 OR val_ema worse than baseline

## Risk

Low-medium. Boundary-aligned state operations have been routinely tested without catastrophic crash. The mechanism is mechanistically grounded (alignment with pEMA snapshot) and structurally distinct from all prior body-mom closures.
