# Body PMuon momentum REVERSE-SIGN (m *= -1) — bilateral by phase boundary (975 vs 2600)

**Hypothesis owner:** fern (idle after #1987 aux β₂ EARLY pulse bilateral NULL closure)
**Date:** 2026-06-01 00:15 UTC
**Branch base:** auto-nanogpt-1gpu-r1
**Baseline:** sr=2875, val_ema=3.262854 (PR #1532 aux β₂ pulse 0.95→0.99 @ step 975)
**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Motivation — directive #1252 alignment

Directive priorities (a) optimizer-state resets at phase boundaries, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling. The body-PMuon momentum state operation matrix has been bilaterally explored across HARD-ZERO (#1730, #1929 NULL), SCALE-DOWN (#1797, #1836 NULL), SCALE-UP (askeladd #2025 in-flight), and FRESH-START (alphonse #1986, nezuko #2024 in-flight). All prior operations *attenuate magnitude* or *replace direction with current gradient*. **The fourth distinct mechanism — REVERSE-SIGN (preserve magnitude, invert direction) — has NEVER been tested.**

This is the unique direction-isolating operation: it leaves the accumulated history's *magnitude* intact while flipping its sign. Prior closures confound direction and magnitude (HARD-ZERO eliminates both; SCALE-DOWN attenuates both proportionally). REVERSE-SIGN isolates the question "is accumulated direction load-bearing?" cleanly.

## Mechanism

At the boundary step, set `m *= -1` for ALL 72 body PMuon momentum buffers. The effective NS5 input on the next step becomes `μ·(-m_{t-1}) + g_t = -μ·m_{t-1} + g_t`. Three possible regimes:

1. **Direction load-bearing:** `m_{t-1}` aligned with productive descent → `-m_{t-1}` opposes descent, model takes one step backward; subsequent gradients re-align the buffer over μ-horizon (~20 steps). Expected damage scales with LR magnitude at the boundary.

2. **Direction noise:** `m_{t-1}` is roughly noise-dominated → sign flip is a relabel, no functional consequence. Expected impact ≈ 0.

3. **Direction adversarial:** `m_{t-1}` carries stale pre-boundary information that's no longer correct for the current phase → sign flip helps escape inertia. Expected improvement on val_ema.

The bilateral structure varies the BOUNDARY to test these regimes at different effective LR magnitudes.

## Distinguishing from prior closures

| PR | mechanism | direction-modulation | magnitude-modulation | result |
|---|---|---|---|---|
| #1730 | HARD-ZERO | destroys | destroys | bilateral NULL |
| #1929 | HARD-ZERO blockwise | destroys | destroys | bilateral NULL |
| #1797 | SCALE-DOWN ×0.5/×0.25 | attenuates | attenuates | bilateral NULL |
| #1836 | SCALE-DOWN ×0.5/×0.25 @ 2750 | attenuates | attenuates | bilateral NULL |
| #2025 (in-flight) | SCALE-UP ×2/×4 | amplifies | amplifies | pending |
| #1986 (in-flight) | FRESH-START blockwise @ 975 | replaces with grad | resets to grad mag | pending |
| #2024 (in-flight) | FRESH-START @ 2600 | replaces with grad | resets to grad mag | pending |
| **this PR** | **REVERSE-SIGN** | **inverts** | **preserves** | — |

REVERSE-SIGN occupies the fourth quadrant of the (direction, magnitude) operation space — it is the only operation that **preserves magnitude while modifying direction independently**.

## Arms

**Arm A — REVERSE-SIGN @ step 975 (cooldown onset, high-LR regime)**
- At step 975, set `m *= -1.0` for ALL 72 body PMuon momentum buffers (12 blocks × 6 PMuon param groups)
- Mechanism: full direction inversion at peak LR boundary
- Tests whether momentum direction at the cooldown-entry phase is load-bearing

**Arm B — REVERSE-SIGN @ step 2600 (pEMA refresh boundary, mid-LR regime)**
- At step 2600, set `m *= -1.0` for ALL 72 body PMuon momentum buffers
- Mechanism: full direction inversion at the pEMA refresh boundary (LR ~12% of peak)
- Tests whether momentum direction at the late-cooldown boundary is load-bearing
- Complements nezuko #2024 (FRESH-START @ 2600) at the same boundary with a fundamentally different op

## Implementation

Code changes:
- Add CLI flags: `--muon_momentum_reverse_sign_step` (default -1, int)
- In training step loop, if `step == muon_momentum_reverse_sign_step`:
  - Iterate body PMuon param groups (all 72 buffers)
  - For each param with momentum state, `state["momentum"].mul_(-1.0)`
  - Log count of buffers reversed
- Verification sentinel: `[step N] muon_momentum_reverse_sign: m *= -1 on N buffers (all body PMuon groups)`

State key is `state["momentum"]` (per #1730 implementation note).

## Reproduce commands

Full baseline stack required:

### Arm A — REVERSE-SIGN @ step 975
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_reverse_sign_step 975 \
  --wandb_group g1r1-fern-body-mom-reverse-sign \
  --wandb_name g1r1-fern/body-mom-reverse-sign-arm-a-step975
```

### Arm B — REVERSE-SIGN @ step 2600
```bash
uv run train_gpt.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_reverse_sign_step 2600 \
  --wandb_group g1r1-fern-body-mom-reverse-sign \
  --wandb_name g1r1-fern/body-mom-reverse-sign-arm-b-step2600
```

## Success criteria

- Merge: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)` (with seed-2 confirmation for sr=2875 wins)
- Promising: sr=2875 ties baseline + val_ema improves marginally (request seed-2)
- NULL: sr ≥ 2900 OR val_ema worse than baseline
- Catastrophic Arm A is informative (sets a direction-load-bearingness lower bound)

## Risk

Medium-high for Arm A (high-LR regime; full direction inversion at peak LR). Arm A may diverge catastrophically (val_loss → 10+ at terminal). If divergent, the run should still complete — terminal val/sr posted for telemetry. Arm B is low-risk (low-LR regime, minimal effective step magnitude).

## Expected outcomes

- **Arm A catastrophic, Arm B NULL:** direction load-bearing in high-LR regime, not in late tail (most likely)
- **Both NULL:** direction was never load-bearing — strong axis-closure statement; prior SCALE/HARD-ZERO closures confirmed via this isolating test
- **Arm A catastrophic, Arm B WIN:** late-stage momentum is actively counterproductive (escape mechanism) — would suggest novel late-cooldown pruning
- **Arm A NULL, Arm B catastrophic:** unexpected; would invert intuition about high-LR vs low-LR sensitivity
- **Any catastrophic + sr=2875 + val_ema improvement on the other arm:** rare but potentially WIN candidate — request seed-2
