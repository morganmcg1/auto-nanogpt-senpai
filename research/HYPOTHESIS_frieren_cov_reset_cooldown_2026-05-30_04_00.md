# HYPOTHESIS — frieren — Body PMuon L_cov/R_cov hard ZERO RESET at cooldown onset (step 975)

**Branch:** `g1r1-frieren/cov-reset-cooldown`
**Assigned:** 2026-05-30 04:00 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directive:** (a) optimizer-state resets/rescaling at phase boundaries

## Why this hypothesis

Two facts motivate testing body PMuon cov-state reset AT STEP 975 specifically:

1. **The canonical aux Adam β₂ pulse at step 975 is a confirmed WIN (#1532).** Step 975 is the warmup-to-cooldown phase boundary where gradient geometry changes sharply. The β₂ pulse (0.95→0.99) converted that boundary into a productive aux-Adam-state intervention by clamping variance estimation. **The symmetric question is whether body PMuon's whitening covariance state also benefits from a phase-boundary intervention at the same step.**

2. **Pre-target cov-state reset is bilaterally CLOSED (#1726 nezuko).** That experiment tested L_cov/R_cov hard zero @ step 2750 — Arm A sr=2950 NULL, Arm B (with β_cov pulse) sr=2875 close miss val_ema=3.263927 NULL. **The pre-target boundary is not the right location for cov-state intervention. The cooldown-onset boundary (step 975) is structurally distinct:**
   - At step 2750, training is in a steady late-cooldown regime; whitening covariances are well-conditioned and load-bearing for the polar approximation accuracy
   - At step 975, the LR schedule is transitioning from warmup-up to cooldown-down (peak); the gradient distribution is shifting; the covariance estimates from warmup steps are conditioned on a sharply different gradient regime

**Mechanism hypothesis:** L_cov and R_cov estimates accumulated during warmup (steps 1-975) embed gradient statistics from a regime where the LR is rising and the loss landscape is being aggressively explored. Once cooldown begins (step 975+), the gradient distribution becomes narrower and more directional. **A hard reset of L_cov/R_cov at step 975 forces the whitening to re-estimate from cooldown-regime gradients only, removing stale warmup geometry from the polar approximation.**

This is the body-side analog of the aux-Adam β₂-pulse mechanism: at the phase boundary, clear the EMA buffer that encodes the prior regime's statistics, allowing the cooldown regime to dominate the optimizer's directional signal.

## Experiment design

**Bilateral comparison at the cooldown-onset boundary:**

- **Arm A — reset @ step 975** (matches canonical β₂ pulse step exactly): L_cov and R_cov zeroed for ALL body PMuon parameters at the precise warmup→cooldown transition step. Tests phase-boundary alignment with the known #1532 WIN.
- **Arm B — reset @ step 1100** (mid-cooldown): same intervention 125 steps into cooldown. Tests whether the timing is precisely at the boundary or anywhere early-cooldown works.

Both arms identical to PR #1532 baseline EXCEPT for the new flag.

## Implementation guidance

Add CLI flag to `records/track_3_optimization/train_gpt_simple.py`:

```python
parser.add_argument(
    "--body_muon_cov_reset_step",
    type=int,
    default=-1,
    help="Hard zero reset L_cov/R_cov of body PMuon at this step (-1 = disabled)",
)
```

In the training loop, after the step counter increments, before the body PMuon `step()` call:

```python
if args.body_muon_cov_reset_step > 0 and step == args.body_muon_cov_reset_step:
    n_reset = 0
    for p_group in optimizer2.param_groups:
        for p in p_group['params']:
            if p in optimizer2.state:
                st = optimizer2.state[p]
                if 'L_cov' in st:
                    st['L_cov'].zero_()
                    n_reset += 1
                if 'R_cov' in st:
                    st['R_cov'].zero_()
    sentinel = (
        f"[step {step}] body PMuon L_cov/R_cov ZERO RESET "
        f"(reset {n_reset} cov-state tensors)"
    )
    print(sentinel)
    if wandb.run is not None:
        wandb.run.summary[f"body_muon_cov_reset_step_{step}"] = n_reset
```

Note: this preserves the body-Muon **momentum** state and only zeroes the bilateral whitening covariances. The momentum buffer carries useful directional information across the boundary (per the #1730 askeladd closure — momentum-buffer-reset at 2750 was NULL because momentum was load-bearing).

## Reproduce commands

**Arm A (reset @ 975 — canonical phase-boundary step):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 975 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-cov-reset-cooldown \
  --wandb_name g1r1-frieren/cov-reset-cooldown-975-armA
```

**Arm B (reset @ 1100 — mid-cooldown):**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 1100 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-cov-reset-cooldown \
  --wandb_name g1r1-frieren/cov-reset-cooldown-1100-armB
```

Run **Arm A first**, then chain Arm B after Arm A's `train_gpt_simple.py` process exits.

## Validation checklist

Before launching the full bilateral, run a smoke test on Arm A with `--body_muon_cov_reset_step 50` and confirm the sentinel `[step 50] body PMuon L_cov/R_cov ZERO RESET` appears in the log AND `n_reset > 0`. The body PMuon optimizer initializes cov state lazily on the first `.step()` call, so `n_reset` at step 50 should equal the number of bilateral params in the body (~72 with 12 blocks × ~6 matmuls/block depending on architecture).

## Expected outcomes and merge logic

| Outcome | Interpretation |
|---|---|
| **Arm A sr ≤ 2862 OR sr=2875 with val_ema < 3.262854** | Cov-state reset at the phase boundary is a WIN. Request seed-2 confirmation, merge if confirmed. |
| **Arm A sr=2875 close miss; Arm B sr=2875 close miss** | Mechanism real, magnitude marginal. Request advisor consultation for n=2 confirmation. |
| **Arm A sr=2875, Arm B sr=2925** | The boundary is precisely at step 975; mid-cooldown is too late. Strong signal for the phase-boundary alignment mechanism. |
| **Both arms NULL (sr ≥ 2925)** | Cov-state at the cooldown boundary is NOT load-bearing in the same way aux Adam variance is. Closes body Muon cov-state-reset axis fully (pre-target + cooldown). |

## Anti-pattern checks

- **Do NOT also reset the body PMuon momentum buffer** at step 975 — #1730 closed momentum-reset at pre-target as NULL, and the consensus mechanism is that momentum carries useful direction across boundaries.
- **Do NOT skip the aux β₂ pulse flag** — `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99` MUST be present (matches #1532 baseline). The merge gate is against #1532, not a pre-#1532 config.
- **Do NOT extend the reset to multiple steps** — single-step hard zero is the cleanest signal. Multi-step variants can be tested in a follow-up if Arm A is promising.
- **Do NOT reset other body-Muon state** (Newton-Schulz polynomial coefficients, NS_ITERS counter, etc.) — those are not state in the sense the hypothesis targets; only L_cov/R_cov.

## Single-line SENPAI-RESULT marker (post when both arms terminal)

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
