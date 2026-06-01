# HYPOTHESIS — tanjiro: body Muon momentum HARD-ZERO RESET @ step 2750 (pre-target boundary)

**Status:** ASSIGNED 2026-06-01 12:30 UTC
**Student:** g1r1-tanjiro
**PR:** TBD

## Mechanism

The body Muon μ-pulse axis is bilaterally closed: fern #1604 (perm μ pulse step 975/2600 NULL) + askeladd #1686 (transient μ pulse 0.97/0.99 @ 2750-2900 NULL). But this closes only the *decay-modulation* mechanism. **The momentum buffer hard-reset mechanism (discarding the buffer entirely vs adjusting its EMA decay) at the pre-target boundary @ step 2750 has never been tested.**

This is the FIRST-moment analog of the cov-state hard-reset axis (#1726/#1849/#1930/#2060 — all CLOSED bilaterally). Both ask the same structural question for different state primitives: **at the pre-target phase boundary, is the optimizer state buffer itself a load-bearing object** (where rebuilding the buffer beats carrying forward stale state)?

Mechanism:
1. By step 2750, body Muon's per-parameter momentum buffer has accumulated ~2750 steps of direction history weighted by μ=0.95. Effective averaging window ~20 steps deep with decaying tails.
2. At the pre-target window, the loss landscape becomes nearly flat — the optimizer may benefit from fresh locally-faithful gradient direction, not a time-averaged direction estimate biased by mid-training curvature.
3. A hard zero reset at step 2750 discards the accumulated state, forcing the next ~20 steps to operate on raw gradient direction (effectively μ=0 transiently), then natural re-accumulation rebuilds the buffer with locally-current information.

**Distinction from μ pulse (closed):**
- μ pulse: modulates how existing buffer state is consumed (slower/faster EMA decay → re-weights stale state vs new gradients).
- Hard reset: discards the buffer entirely → next step's update direction = raw gradient, not stale-EMA + gradient blend.

**Distinction from alphonse #2104 (in-flight depth-stratified DECAY ×0.10 @2750):**
- alphonse: depth-stratified ×0.10 DECAY (keeps 10% of mom, depth subsets).
- This PR: HARD-ZERO (full reset, all body Muon params).
- HARD-ZERO is structurally more aggressive than ×0.10 DECAY. They test different points on the decay-magnitude axis at the same boundary.

**Distinction from prior @975 boundary mom transforms (all closed):**
- @975 is cooldown ONSET (LR starts decreasing). @2750 is PRE-TARGET (deep into cooldown, close to baseline sr=2875 target crossing).
- The two boundaries probe different optimizer-state semantics: @975 tests "rebuild for cooldown trajectory," @2750 tests "rebuild for target-crossing fine alignment."

This is directive #1252 (a) state-at-phase-boundary, (c) short phase-specific mechanism, (d) momentum/preconditioner state handling.

## Bilateral arm design

Both arms apply hard momentum reset at step 2750. They differ in whether the reset is paired with a transient lower-μ (fresher updates) window.

- **Arm A** (pure reset): Zero momentum buffer at step 2750. μ stays canonical 0.95. Natural re-accumulation. Tests whether buffer discard alone is mechanistically sufficient.
- **Arm B** (reset + fresh-momentum window): Zero momentum buffer at step 2750. Set μ=0.85 transient for steps 2750-2900 (the 150-step pre-target window), revert to μ=0.95 at step 2900. Tests whether keeping the buffer "fresh-tracking" through the pre-target window (rather than slow-rebuilding to μ=0.95 over ~20 steps) is the load-bearing piece.

Arm A is the cleanest test of the reset mechanism alone. Arm B compounds it with the "fresher updates" direction that was the only untested μ direction (askeladd #1686 follow-up suggestion).

## Predictions

| outcome | interpretation |
|---|---|
| Arm A clean WIN | Reset alone is load-bearing. Strong mechanism candidate, trigger seed-2. The buffer-as-stale-direction story is correct. |
| Arm B clean WIN, Arm A NULL | The fresh-μ window is the load-bearing piece, not the reset. Reset only enables re-accumulation under fresher μ. |
| Both WIN | Both mechanisms contribute; Arm B better if compounding. Confirm both with seed-2. |
| Both NULL | Pre-target momentum state is not the bottleneck — the optimizer's existing buffer at @2750 is already "good enough" or the bottleneck is elsewhere. Adds momentum-reset @2750 to the closed-axis matrix. |

## Implementation sketch

In `train_gpt_simple.py`, add three CLI flags and pulse logic inside the per-step training loop. **IMPORTANT — verify exact state key name before coding.** Look at the Muon optimizer class definition (likely in the same file) and confirm whether the momentum buffer key is `'momentum_buffer'` (standard PyTorch convention) vs `'mom'` vs `'buf'` vs something custom. Match what the optimizer's `step()` method reads from.

```python
# CLI flags
parser.add_argument('--muon_momentum_reset_step', type=int, default=-1,
                    help='Step to hard-zero body Muon momentum buffer. -1 disables.')
parser.add_argument('--muon_momentum_reset_mu_target', type=float, default=-1.0,
                    help='If >0, set mu to this value after reset until --muon_momentum_reset_mu_end.')
parser.add_argument('--muon_momentum_reset_mu_end', type=int, default=-1,
                    help='Step to revert mu back to canonical 0.95 after reset window.')

# In step loop, after existing pulse logic, before optimizer.step():
if args.muon_momentum_reset_step > 0 and step == args.muon_momentum_reset_step:
    n_zeroed = 0
    for group in optimizer2.param_groups:
        for p in group['params']:
            state = optimizer2.state.get(p, {})
            if 'momentum_buffer' in state:
                state['momentum_buffer'].zero_()
                n_zeroed += 1
    print0(f"[step {step}] muon_momentum_reset: zeroed {n_zeroed} momentum buffers", console=True)
    if args.muon_momentum_reset_mu_target > 0.0:
        old_mu = optimizer2.param_groups[0]["mu"]
        for g in optimizer2.param_groups:
            g["mu"] = args.muon_momentum_reset_mu_target
        print0(f"[step {step}] muon_momentum_reset: mu {old_mu} -> {args.muon_momentum_reset_mu_target}", console=True)

if (args.muon_momentum_reset_mu_end > 0 and step == args.muon_momentum_reset_mu_end
        and args.muon_momentum_reset_mu_target > 0.0):
    for g in optimizer2.param_groups:
        g["mu"] = 0.95
    print0(f"[step {step}] muon_momentum_reset: mu reverted to 0.95", console=True)
```

Adapt the optimizer reference (`optimizer2`) and the μ-parameter key name to whatever the current `train_gpt_simple.py` uses for body Muon.

## Reproduce commands

**Full baseline stack required on both arms.**

### Arm A — pure reset @ 2750

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_reset_step 2750 \
  --wandb_group g1r1-tanjiro-muon-mom-hardzero-2750 \
  --wandb_name g1r1-tanjiro/muon-mom-hardzero-2750-arm-a-pure
```

### Arm B — reset + fresh-μ window (2750→2900)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --muon_momentum_reset_step 2750 \
  --muon_momentum_reset_mu_target 0.85 \
  --muon_momentum_reset_mu_end 2900 \
  --wandb_group g1r1-tanjiro-muon-mom-hardzero-2750 \
  --wandb_name g1r1-tanjiro/muon-mom-hardzero-2750-arm-b-fresh-mu
```

**Chain rule:** Arm A first. Launch Arm B after Arm A `wandb.finish()` AND training process exit. Use the `pgrep`+`flag-file`+`settle` guarded-chain pattern.

**Seed-2 trigger:** If either arm achieves `sr ≤ 2875 AND val_ema < 3.262854`, launch a seed-2 confirmation run before posting terminal SENPAI-RESULT.

## Baseline (PR #1532)

- **speedrun/final_first_step_to_target:** 2875 (n=2)
- **ema/val_loss_ema:** 3.262854 (n=2 mean)
- **Gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **W&B baseline runs:** `9coyk2ke` (seed-1), `09qrijtm` (seed-2)

## Sentinel verification

Expected stdout log lines (rank 0):
- Arm A @ step 2750: `[step 2750] muon_momentum_reset: zeroed N momentum buffers` (N matches body Muon param count, typically ~72 weight tensors)
- Arm B @ step 2750: same N-zeroed line + `[step 2750] muon_momentum_reset: mu 0.95 -> 0.85`
- Arm B @ step 2900: `[step 2900] muon_momentum_reset: mu reverted to 0.95`

Also expect a brief loss bump at step 2750 (~5-15 steps) as buffer rebuilds from zero on Arm A. Arm B should show smaller bump due to fresher-μ tracking.

## SENPAI-RESULT format

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA>","<armB>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<int>},"test_metric":{"name":"ema/val_loss_ema","value":<float>}}
```

Use the run with the BEST primary_metric (lower sr is better). If both arms tie on sr, use the lower val_ema.

## Why this assignment for tanjiro

- Direct continuation of tanjiro's mom-state work (#2061 BLEND-with-grad NULL, #1697 pre-target LR DROP, #1648 cooldown-onset interventions) — same mechanism class (momentum state transforms) at a structurally distinct phase boundary (@2750 not @975)
- Pristine axis: zero prior bilaterals on momentum HARD-ZERO at any pre-target boundary
- Complements alphonse #2104 in-flight (depth-stratified ×0.10 DECAY @2750) without overlap — HARD-ZERO is the magnitude=0 endpoint of that DECAY axis
- Directive (a)+(c)+(d) triple-aligned
