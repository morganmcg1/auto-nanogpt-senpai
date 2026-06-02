## Hypothesis: Body-Muon momentum SCALE-UP pulse at step 2750 (tanjiro)

**Date:** 2026-06-02 05:55 UTC
**Student:** tanjiro (auto-nanogpt-1gpu-r1)
**Directive alignment:** #1252 (a) optimizer-state operations at phase boundaries + (d) preconditioner/momentum state handling

## Context

Tanjiro #2183 just closed bilateral NULL on aux Adam first-moment HARD-ZERO reset at both 1750 and 2750 boundaries (+2.24 / +2.44 mnat). Aux Adam m-state RESET axis is now exhausted across all magnitudes, scopes, and timestamps.

The natural complement is the OPPOSITE-direction intervention on body-Muon momentum at the SAME boundary (@2750). Prior body-Muon RESET work (#2115 HARD-ZERO @2750 sr=2925 NULL, +50 sr cost) established that ZEROING the body-PMuon momentum at @2750 is harmful. The SCALE-UP direction at the same boundary asks: **is the body-Muon momentum at step 2750 too SMALL?** That direction is pristine — never tested.

## Mechanism hypothesis

Step 2750 sits between cooldown onset (1750) and paramEMA refresh (2600), in the middle of the descending LR ramp. At this point:
- Block-LR multipliers are settled (late-higher pattern at ~1.1× / 0.9×)
- paramEMA has just refreshed at step 2600 — the EMA "target" parameter state has just been reset to the live state
- The body-Muon momentum buffer has been accumulating since step 0

Hypothesis: post-paramEMA-refresh the body-Muon momentum may be effectively too "stale" relative to the freshly-refreshed paramEMA target. A SCALE-UP pulse at step 2750 (150 steps post-refresh) AMPLIFIES the recent direction relative to incoming gradients, sharpening the descent ramp during the cooldown phase. If the late-cooldown descent benefits from stiffer momentum, sr decreases.

Two opposing predictions:
- **(A) Mild scale-up wins:** ×1.5 sharpens descent just enough without overshooting. Arm A wins.
- **(B) Aggressive scale-up wins:** ×2.0 produces a stronger directional bias that overcomes the late-cooldown LR contraction. Arm B wins.

Either outcome localizes the right amplitude for late-cooldown momentum amplification. Bilateral NULL closes the @2750 amplification direction (combined with @2750 reset NULL → momentum buffer at @2750 is structurally optimized in both directions).

## Bilateral arm design

- **Arm A (MILD scale-up):** body-Muon momentum buffer ×1.5 at step 2750
- **Arm B (AGGRESSIVE scale-up):** body-Muon momentum buffer ×2.0 at step 2750

Scope: body-PMuon params only (block.* params, ndim≥2). Aux Adam params untouched. Single one-shot multiplication of the `mom_buffer` state in-place.

## Implementation

Add a single CLI flag to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument("--body_muon_mom_scaleup_step", type=int, default=-1,
                    help="Step at which to multiply body-PMuon momentum buffer in-place. -1 = off.")
parser.add_argument("--body_muon_mom_scaleup_factor", type=float, default=1.0,
                    help="Multiplicative factor applied to body-PMuon momentum at scaleup_step.")
```

In `Muon.step` (around the body-PMuon momentum-buffer access region), add a one-shot scaling block at the right phase:

```python
# Inside Muon.step, before the gradient is blended into the momentum buffer:
if (args.body_muon_mom_scaleup_step >= 0
        and self._step_count == args.body_muon_mom_scaleup_step
        and args.body_muon_mom_scaleup_factor != 1.0):
    n_scaled = 0
    for group in self.param_groups:
        if group.get("which", "body") != "body":
            continue
        for p in group["params"]:
            if p in self.state and "mom" in self.state[p]:
                self.state[p]["mom"].mul_(args.body_muon_mom_scaleup_factor)
                n_scaled += 1
    print(f"[body_muon_mom_scaleup] step={self._step_count} factor={args.body_muon_mom_scaleup_factor} n_scaled={n_scaled}")
    wandb.log({
        "optim/body_muon_mom_scaleup_executed": 1,
        "optim/body_muon_mom_scaleup_n_buffers": n_scaled,
    }, step=self._step_count)
```

(If the codebase uses a different key than `"mom"` for the body-Muon momentum buffer state, use whatever key is created in the body-Muon update path. The `param_groups` `which` filter mirrors the existing per-group conventions in the codebase. Confirm the buffer name matches the Muon optimizer's stored state dict before launching.)

Add a single sentinel log at step 0:
```python
wandb.log({
    "optim/body_muon_mom_scaleup_step": args.body_muon_mom_scaleup_step,
    "optim/body_muon_mom_scaleup_factor": args.body_muon_mom_scaleup_factor,
}, step=0)
```

Delta: ~25 LOC + 2 CLI args.

## Reproduce commands

**Smoke test (baseline reproduction, scaleup off):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_mom_scaleup_step -1 --body_muon_mom_scaleup_factor 1.0 \
  --wandb_group g1r1-tanjiro-body-mom-scaleup \
  --wandb_name g1r1-tanjiro/body-mom-scaleup-baseline-smoke
```
Run ~50 steps and verify loss matches baseline. (Optional — only if you want bit-exact backward-compat check.)

**Arm A (MILD scale-up, factor=1.5 @ step 2750):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_mom_scaleup_step 2750 --body_muon_mom_scaleup_factor 1.5 \
  --wandb_group g1r1-tanjiro-body-mom-scaleup \
  --wandb_name g1r1-tanjiro/body-mom-scaleup-mild-arm-a
```

**Arm B (AGGRESSIVE scale-up, factor=2.0 @ step 2750):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_mom_scaleup_step 2750 --body_muon_mom_scaleup_factor 2.0 \
  --wandb_group g1r1-tanjiro-body-mom-scaleup \
  --wandb_name g1r1-tanjiro/body-mom-scaleup-aggressive-arm-b
```

## Chain rule

1. Implement flag + add scale-up block in `Muon.step`.
2. (Optional) Smoke-test with `--body_muon_mom_scaleup_step -1` (default off) to verify baseline bit-exactness.
3. Launch **Arm A (mild ×1.5)** first.
4. When Arm A is terminal, post intermediate SENPAI-RESULT (terminal=false, pending_arms=true), then launch Arm B.
5. Both arms terminal → post final SENPAI-RESULT (terminal=true, pending_arms=false) with bilateral verdict.

## Baseline / merge gate

Current best: baseline #1532 — n=2 mean sr=2875, val_ema=3.262854.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

Baseline reproduce:
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99
```

## Falsifying outcome

If both arms sr ≥ 2925 AND val_ema ≥ +1.5 mnat over baseline (i.e., both NULL), body-Muon momentum at step 2750 is structurally optimized in BOTH directions — combined with the @2750 HARD-ZERO closure (#2115), the @2750 boundary on body-PMuon momentum is fully exhausted. Closes the @2750 body-Muon momentum perturbation axis.

If one arm clearly wins, the load-bearing magnitude (mild vs aggressive amplification) localizes the right intervention strength, opening follow-up fine-grained sweeps (×1.25, ×1.75) and step-position sweeps (@2600, @2700, @2800).
