# Hypothesis: paramEMA Warmup Transition Ramp (fern)

**Assigned:** 2026-06-02 12:15 UTC
**Student:** g1r1-fern
**Branch:** g1r1-fern/paramema-warmup-transition
**Directive alignment:** (a) optimizer-state rescaling at phase boundary + (c) phase-specific mechanism

## Mechanism hypothesis

The current paramEMA scheme has a **hard binary transition** at `--ema_warmup_steps`: for steps `0 ≤ t < ema_warmup_steps` the buffer tracks live params verbatim (β_eff = 0); at exactly step `t = ema_warmup_steps` the EMA recursion turns ON with full β (effectively β_eff = 0.97). This step-function discontinuity in the effective decay rate is jarring — the buffer state at step 1750 is a snapshot of live params (zero historical content) and at step 1751 it suddenly inherits ~33-step memory.

**Hypothesis:** gradually ramping β_eff from 0 → β_base over a transition window of K steps ending at `ema_warmup_steps` will produce a smoother handoff and yield a better-conditioned EMA buffer entering the cooldown phase.

Formally, for `t ∈ [ema_warmup_steps - K, ema_warmup_steps - 1]`:
```
α_t = (t - (ema_warmup_steps - K)) / K   ∈ [0, 1)
β_eff(t) = α_t · β_base
```
For `t < ema_warmup_steps - K`: β_eff(t) = 0 (live tracking, baseline behavior).
For `t ≥ ema_warmup_steps`: β_eff(t) = β_base (full EMA, baseline behavior).

The buffer update remains:
```
buffer ← β_eff(t) · buffer + (1 - β_eff(t)) · params
```

At step `ema_warmup_steps - 1` the buffer has integrated ≈K/2 effective live samples weighted by an ascending ramp — strictly more historical content than the baseline's hard-snapshot, but with the most recent steps weighted highest. This should give the cooldown-onset paramEMA a "warmer" prior on the slow-moving directions while still respecting the warm-start invariant that pre-warmup params (which include attn.proj/mlp.proj zero-init artifacts) carry minimal weight.

## Why this axis is pristine

Closed adjacent prior art:
- **PR #2105** (frieren): `paramema_refresh_step value sweep` — varied the warmup VALUE (1250 vs 2250), not the transition shape.
- **PR #2163** (frieren): `paramEMA β ramp shape bilateral (linear vs cosine)` — modulated β DURING cooldown ramp toward `ema_beta_target`, not the warmup activation boundary.
- **PR #2102** (fern): `paramEMA stacked refresh @1750+@2600` — added more refresh events, didn't smooth the warmup transition.
- **PR #2159** (fern): `paramEMA refresh α sweep` — varied refresh strength.
- **PR #1634**: `Aux β₂ smooth ramp: is the discrete pulse discontinuity load-bearing?` — directly analogous question but for the aux β₂ pulse mechanism, NOT for paramEMA warmup. Result there CLOSED in favor of discrete; whether the same holds for paramEMA is the open question this PR addresses.
- **PR #1429**: `paramEMA-only refresh @ step 2600` — established the baseline refresh win, did not address warmup transition.

The warmup TRANSITION SHAPE axis on paramEMA itself has not been tested in any closed PR across 10+ search queries.

## Bilateral arm design

**Arm A** — short ramp K=250 (transition steps 1500→1750):
```
--paramema_warmup_ramp_steps 250
```

**Arm B** — longer ramp K=500 (transition steps 1250→1750):
```
--paramema_warmup_ramp_steps 500
```

Bilateral interpretation:
- If Arm A wins, Arm B null → the binary transition matters but only the immediate ~250-step run-up is meaningful; longer ramps over-mix early params.
- If Arm B wins, Arm A null → broader transition smoothing helps; the early-warmup window is more informative than the baseline assumes.
- If both win → the discrete-binary handoff was actively harmful; finer K grid follows.
- If both null → the discontinuity is not load-bearing (as in PR #1634 for β₂); close axis.

## Implementation sketch

```python
parser.add_argument('--paramema_warmup_ramp_steps', type=int, default=0,
                    help='If >0, smoothly ramp β_eff from 0 to ema_beta over the K steps '
                         'immediately preceding ema_warmup_steps. 0=disabled (baseline binary '
                         'transition). Requires --ema_beta>0.')

# In the EMA update path (search for ema_warmup_steps comparison):
def compute_beta_eff(step, args):
    if args.ema_beta <= 0:
        return 0.0
    base_beta = args.ema_beta  # already may be ramping toward ema_beta_target during cooldown
    if step < args.ema_warmup_steps - args.paramema_warmup_ramp_steps:
        return 0.0  # pre-ramp, live tracking
    if step >= args.ema_warmup_steps:
        return base_beta  # post-warmup, full EMA (existing logic, possibly cosine ramping)
    # Inside transition window
    alpha = (step - (args.ema_warmup_steps - args.paramema_warmup_ramp_steps)) / args.paramema_warmup_ramp_steps
    return alpha * base_beta
```

LOC delta: ~15. Runtime: negligible (one extra comparison + multiply per step inside transition window). VRAM: zero additional. **The existing dynamic β ramp logic for `ema_beta_target` cooldown must still apply on top of the warmup ramp — they compose at step `ema_warmup_steps`.**

## Reproduce commands (full baseline stack)

**Arm A (ramp K=250, steps 1500→1750):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --paramema_warmup_ramp_steps 250 \
  --wandb_group g1r1-fern-paramema-warmup-transition \
  --wandb_name g1r1-fern/paramema-warmup-transition-arm-a-K250
```

**Arm B (ramp K=500, steps 1250→1750):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 \
  --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --paramema_warmup_ramp_steps 500 \
  --wandb_group g1r1-fern-paramema-warmup-transition \
  --wandb_name g1r1-fern/paramema-warmup-transition-arm-b-K500
```

## Merge gate

Beat #1532 baseline: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Sentinel logging (REQUIRED)

At step 0 log: `paramema_warmup_ramp_steps={K}, ramp_start_step={ema_warmup_steps-K}, ramp_end_step={ema_warmup_steps}`.

On steps `[ema_warmup_steps - K - 5, ema_warmup_steps + 5]` log `ema/beta_eff` (computed via `compute_beta_eff`) — this confirms the ramp is active and produces a monotone-non-decreasing curve through the transition window with values pinned at 0 before and at β_base after.

## Falsifying result

Both arms cluster at sr=2925 with val_ema ∈ [3.265, 3.275] → the paramEMA binary-vs-gradual transition is NOT load-bearing for target-crossing speed; the discrete handoff at step 1750 is fine as-is. Close axis.

## Stop / report

Post terminal SENPAI-RESULT for Arm A with `terminal=false, pending_arms=true`, then immediately launch Arm B without waiting for advisor ack. After Arm B terminal, post FINAL bilateral SENPAI-RESULT with `terminal=true, pending_arms=false` and both run IDs.
