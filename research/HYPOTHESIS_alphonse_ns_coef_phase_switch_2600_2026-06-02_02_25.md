# alphonse — NS Polynomial Coefficient Phase-Switch at pEMA Refresh Boundary (step 2600) bilateral (Jordan fast-convergence vs near-identity)

## Context

Baseline #1532: `speedrun/first_step_to_target` (sr) = **2875**, `val/loss_ema` = **3.262854**.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

Current Newton-Schulz5 polynomial: `a=1.5, b=-0.5, c=0.0` (cubic-Newton, PR #193, set globally at module level). The polynomial `a*X + b*X^3 + c*X^5` iterates `NS_ITERS=12` times in `Muon.step` and converges to a partial polar factor of the whitened gradient.

Adjacent axes CLOSED:
- Static NS coefficient scans (#250, #229, #226) — bilateral NULL across the cubic-Newton, Jordan, and quintic families
- NS_ITERS cooldown schedule (#2162) — bilateral NULL (12→8 sr=2925, 12→4 sr=2925)
- NS-burst (#1739) — closed
- Polar projection replaced entirely (#1703 ADOPT, #1752 Newton-Muon, #1771 ACProp) — all NULL

PRISTINE axis: **phase-adaptive NS coefficient switching at a known phase boundary**. The static scans tested whether the polynomial itself can be globally improved. The closure of NS_ITERS phase schedule (#2162) shows iteration count isn't the lever during cooldown. But the *polynomial coefficients themselves* have never been switched at the pEMA refresh boundary (step 2600).

## Hypothesis

At step 2600, the optimization landscape qualitatively shifts: paramEMA buffer is refreshed (overwriting EMA with live params), LR has decayed to ~24% of peak, and gradient magnitudes are correspondingly smaller. The whitened matrix `m_pre = (L_neg @ update.float()) @ R_neg` entering NS now has a different spectral distribution than early in training. The current cubic-Newton (a=1.5, b=-0.5, c=0.0) was tuned for the global average regime — it may be over- or under-projecting in the late-cooldown phase. Switching NS coefficients at step 2600 tests whether the polar map's convergence behavior in the final 650 steps is load-bearing for target-crossing speed.

Two opposing arms test the directional uncertainty:

- **Arm A (Jordan fast-convergence):** `a=3.4445, b=-4.7750, c=2.0315`. Quintic coefficients optimized for 5-iteration convergence in standard Muon. Late phase already has well-conditioned whitened matrices, so fast-convergence coefficients should produce tighter polar projections, maintaining update-direction quality in the final 650 steps.
- **Arm B (near-identity):** `a=1.0, b=-0.1, c=0.0`. Minimal projection strength. Allows the optimizer to take slightly non-orthogonal but potentially longer effective updates in the final phase, reducing polar projection's late-phase "drag".

Mechanistically distinct from #2162 (which scoped *iteration count* across phases at fixed coefficients) and from #1660 (which pulsed coefficients globally without phase boundary). Directive (a) optimizer-state rescaling at phase transitions + directive (c) phase-specific mechanism active only pre-target-crossing.

## Implementation

**File:** `records/track_3_optimization/train_gpt_simple.py`

### CLI flags

Add to argparser:

```python
parser.add_argument("--ns_phase_switch_step", type=int, default=-1,
                    help="Step at which to switch NS polynomial coefficients. -1 disables.")
parser.add_argument("--ns_a2", type=float, default=1.5,
                    help="NS coefficient 'a' after phase switch.")
parser.add_argument("--ns_b2", type=float, default=-0.5,
                    help="NS coefficient 'b' after phase switch.")
parser.add_argument("--ns_c2", type=float, default=0.0,
                    help="NS coefficient 'c' after phase switch.")
```

### Module-level globals

The NS coefficients are currently module-level globals (search for `NS_A`, `NS_B`, `NS_C` or whatever the existing names are — likely around lines 30-32). Reading from them inside `pmuon_update` (or wherever the polynomial is computed) is the access pattern.

### Phase-switch logic

In the training loop, BEFORE the optimizer step, add a conditional that mutates the module-level globals exactly once:

```python
if (args.ns_phase_switch_step > 0
        and step == args.ns_phase_switch_step):
    # Read whichever module-level names the current code uses.
    # The example below assumes `NS_A, NS_B, NS_C`. Adjust if the actual names differ.
    global NS_A, NS_B, NS_C
    old = (NS_A, NS_B, NS_C)
    NS_A = args.ns_a2
    NS_B = args.ns_b2
    NS_C = args.ns_c2
    print0(f"[step {step}] NS coef switch: {old} → ({NS_A}, {NS_B}, {NS_C})",
           console=True)
```

**IMPORTANT:** Verify the global variable names by reading the existing NS polynomial implementation. If the code uses `_NS_A`, `ns_a`, or a different scheme (e.g. `_ns_polynomial_coeffs` tuple), match it exactly. The print0 sentinel must show the actual values before and after — this is the only way to confirm the switch fired correctly.

### Telemetry

Log to W&B at standard cadence:

- `ns_phase_switch/active` (0/1) — whether feature is enabled
- `ns_phase_switch/step` (the step set)
- `ns_phase_switch/a_current`, `ns_phase_switch/b_current`, `ns_phase_switch/c_current` (the live coefficient values; flip at the switch step)

### Step 0 sanity

Print at step 0 a one-line summary:

```
[step 0] ns_phase_switch ENABLED: step=2600 a=3.4445 b=-4.7750 c=2.0315 (was a=1.5 b=-0.5 c=0.0)
```

### Backward-compat smoke test

With `--ns_phase_switch_step -1` (default), behavior MUST be bit-identical to the merged baseline. Run a 50-step debug with all baseline flags and `--ns_phase_switch_step -1` and confirm parity vs the merged baseline.

### Sentinel at the switch step

The switch step (2600) MUST emit a single print line confirming the actual coefficient values changed. If you don't see the print, the global mutation didn't take effect — the polynomial evaluator may have closed over the values rather than reading them live. Fix by ensuring `pmuon_update` reads the globals afresh each call.

## Reproduce commands

**Arm A (Jordan fast-convergence at step 2600):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_phase_switch_step 2600 --ns_a2 3.4445 --ns_b2 -4.7750 --ns_c2 2.0315 \
  --wandb_group g1r1-alphonse-ns-coef-phase-switch
```

**Arm B (near-identity at step 2600):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --ns_phase_switch_step 2600 --ns_a2 1.0 --ns_b2 -0.1 --ns_c2 0.0 \
  --wandb_group g1r1-alphonse-ns-coef-phase-switch
```

**Baseline smoke test parity (with --ns_phase_switch_step -1):**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

Use the chain script to run Arm A → Arm B sequentially. Stop and post terminal `SENPAI-RESULT` after each arm completes.

## Success criteria

- **Merge winner:** Either arm achieves `sr ≤ 2862.5` OR `sr = 2875 AND val_ema < 3.262854`.
- **Promising for follow-up:** `sr = 2875` and val_ema marginally above baseline (within 0.001), OR clear directional signal between Arm A (Jordan) and Arm B (near-identity) suggesting target coefficient region deserves a finer sweep.
- **Bilateral NULL:** Both arms `sr ≥ 2900`. Close and the NS-coefficient-phase-switch axis is exhausted at the pEMA boundary.

## Sentinels and verification

- **Step 0 sanity:** Print one-line ns_phase_switch enable summary showing the BEFORE coefficients (must read `(1.5, -0.5, 0.0)` to confirm baseline) and the AFTER coefficients.
- **Switch fired:** At step=2600, the sentinel print MUST appear in stdout and the W&B `ns_phase_switch/a_current` etc. must flip. If the print appears but coefficients don't propagate to NS iteration, the polynomial computation likely captured the original values at module load — fix by re-reading the globals inside `pmuon_update`.
- **Backward-compat:** With `--ns_phase_switch_step -1` (default), 50-step debug must match merged baseline bit-for-bit.
- **W&B verification:** `val/loss_ema` and `ema/*` group MUST appear in W&B. If absent, EMA is disabled — reproduce command is broken. Step 875 `val/loss` should be ~3.45, NOT ~3.69 (the latter indicates non-baseline trajectory).

## Expected gain

Tests whether the polar projection's convergence behavior is phase-sensitive in the cooldown regime. The static coefficient scans found no global optimum better than cubic-Newton, but they assumed one polynomial fits all training phases. The plateau analysis (RESEARCH_IDEAS 2026-06-02_00-30) identifies the late-cooldown regime (steps 3000–3250) as the binding window for val_ema convergence. If either arm beats the merge gate, the directional signal (Jordan tighter vs near-identity looser) tells us whether late-phase needs more or less polar projection strength — a structural insight that opens an entire coefficient-region for follow-up sweeps.

If both arms NULL, the polar projection at NS_ITERS=12 is robust to coefficient choice in the late phase and the bottleneck lies elsewhere (preconditioner input quality per Idea 1 Signum, or post-projection persistence per Idea 4 Update EMA).

## Estimated LOC delta

~14 LOC (4 CLI args + phase-switch conditional + telemetry + step-0 sentinel).
