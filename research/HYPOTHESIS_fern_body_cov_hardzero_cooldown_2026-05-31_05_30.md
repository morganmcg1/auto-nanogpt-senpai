# HYPOTHESIS — fern — Body PMuon SIDE COVARIANCE HARD-ZERO @ cooldown onset step 975

**Branch:** `g1r1-fern/body-cov-hardzero-cooldown`
**Assigned:** 2026-05-31 05:30 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (a) optimizer-state resets/rescaling at phase boundaries; (d) preconditioner state handling changes; (c) short phase-specific mechanisms

## Why this hypothesis

Body PMuon performs bilateral whitening `L^{-γ} · g · R^{-γ}` where `L` and `R` are per-side covariance EMAs of `g·g^T` and `g^T·g`. These cov buffers are the body-side analog of aux Adam's `exp_avg_sq` (v) buffer — both accumulate stable-phase gradient statistics and both lag the post-cooldown gradient distribution.

**What's been tested on body cov:**
- #1666 (CLOSED): `β_cov` pulse (change the EMA rate at step 975) → bilateral NULL on EMA rate axis
- #1849 (CLOSED): per-side cov LR/magnitude scaling on the LR axis → bilateral NULL
- **HARD-ZERO of the cov state buffer values at any temporal boundary: NEVER TESTED**

**Mechanistic reasoning for cov hard-zero @ 975:**
- The aux Adam v-buffer analog is being investigated by askeladd #1912 (`adam_scalars` v×0.5/×0.25 @975, in flight) — that's a partial decay test, NOT hard zero.
- For body PMuon, a hard zero of L and R at step 975 forces the whitening operator to rebuild from scratch under the new cooldown LR regime. The first ~50 steps after the reset will use a near-unit whitening (effectively un-preconditioned NS5 projection); after that, the cov EMAs reaccumulate against the cooldown gradient distribution.
- If the stable-phase cov is materially miscalibrated for cooldown, a hard reset gives the optimizer a clean slate to refit. Mechanistically aligned with directive (a).

**Distinct from in-flight askeladd #1912:**
- askeladd #1912 tests **aux scalars v** at ×0.5 / ×0.25 (partial decay) on optimizer1
- This tests **body PMuon side cov L+R** at ZERO and ×0.5 (hard reset vs partial decay) on optimizer2
- Different optimizer, different state buffer, different mechanism family

## Distinct from in-flight and closed work

- **#1666 (CLOSED)**: body β_cov PULSE → EMA-rate axis NULL
- **#1849 (CLOSED)**: per-side cov LR axis NULL
- **#1797 / #1876 (CLOSED)**: body PMuon momentum state (NOT cov) → all NULL
- **askeladd #1912** (in flight): aux Adam scalars v-state, NOT body cov
- **No prior body PMuon side cov hard-zero or partial decay at ANY temporal boundary.** Cleanly novel.

## Experiment design

**Bilateral magnitude test on body PMuon side cov (axis: zero vs partial decay):**

- **Arm A — body PMuon side cov HARD-ZERO @ step 975:** Set both L and R buffers to zero for all body PMuon params at step 975. The whitening operator must rebuild from scratch under cooldown gradients.
- **Arm B — body PMuon side cov × 0.5 @ step 975:** Multiplicatively scale both L and R by 0.5 (partial decay). Tests whether half-reset preserves some useful prior while still admitting cooldown-distribution refit.

Both arms preserve all canonical interventions: aux β₂ pulse 0.95→0.99 @975, pEMA refresh @2600, late-higher block LR, ema_beta=0.97.

## Implementation guidance

**Step 1: Read the body PMuon optimizer class** in `records/track_3_optimization/train_gpt_simple.py` (or wherever body PMuon is defined). Identify the EXACT state-key names for the side covariances. Common naming patterns:
- `state["L"]`, `state["R"]` (per-param-tensor)
- `state["cov_L"]`, `state["cov_R"]`
- `state["left_cov"]`, `state["right_cov"]`
- Or a single packed dict `state["side_cov"]`

**You must inspect the code and use the actual key names.** Document them in your PR comment.

**Step 2: Add CLI flags:**

```python
parser.add_argument(
    "--body_muon_cov_reset_step", type=int, default=0,
    help="Step at which to scale body PMuon side covariance buffers L and R "
         "(0 disables; 1.0 factor is no-op).",
)
parser.add_argument(
    "--body_muon_cov_reset_factor", type=float, default=1.0,
    help="Multiplicative factor applied to both L and R cov buffers at "
         "body_muon_cov_reset_step. Use 0.0 for hard zero, 0.5 for partial decay.",
)
```

**Step 3: Apply cov reset** — BEFORE `optimizer2.step()`:

```python
if (args.body_muon_cov_reset_step > 0
        and step == args.body_muon_cov_reset_step
        and args.body_muon_cov_reset_factor != 1.0):
    scale = float(args.body_muon_cov_reset_factor)
    n_L_touched = 0
    n_R_touched = 0
    L_before_mean = 0.0
    L_after_mean = 0.0
    R_before_mean = 0.0
    R_after_mean = 0.0
    for group in optimizer2.param_groups:
        for p in group["params"]:
            state = optimizer2.state.get(p, None)
            if state is None:
                continue
            # REPLACE THESE WITH ACTUAL KEY NAMES FROM THE BODY PMuon CLASS
            L_buf = state.get("L", None)         # or state.get("cov_L"), etc.
            R_buf = state.get("R", None)         # or state.get("cov_R"), etc.
            if L_buf is not None:
                L_before_mean += float(L_buf.mean())
                L_buf.mul_(scale)
                L_after_mean += float(L_buf.mean())
                n_L_touched += 1
            if R_buf is not None:
                R_before_mean += float(R_buf.mean())
                R_buf.mul_(scale)
                R_after_mean += float(R_buf.mean())
                n_R_touched += 1
    if dist.get_rank() == 0:
        if n_L_touched > 0:
            L_before_mean /= n_L_touched
            L_after_mean /= n_L_touched
        if n_R_touched > 0:
            R_before_mean /= n_R_touched
            R_after_mean /= n_R_touched
        print0(
            f"[step {step}] body PMuon cov reset x{scale}: "
            f"L on {n_L_touched} params (mean {L_before_mean:.6e}->{L_after_mean:.6e}); "
            f"R on {n_R_touched} params (mean {R_before_mean:.6e}->{R_after_mean:.6e})",
            console=True,
        )
        if wandb.run is not None:
            wandb.log({
                "body_muon_cov_reset/step": step,
                "body_muon_cov_reset/factor": scale,
                "body_muon_cov_reset/n_L_touched": n_L_touched,
                "body_muon_cov_reset/n_R_touched": n_R_touched,
                "body_muon_cov_reset/L_mean_before": L_before_mean,
                "body_muon_cov_reset/L_mean_after": L_after_mean,
                "body_muon_cov_reset/R_mean_before": R_before_mean,
                "body_muon_cov_reset/R_mean_after": R_after_mean,
            }, step=step)
```

**CRITICAL:**
- `default=0` and `default=1.0` MUST be a no-op (preserves baseline for all existing runs).
- **Verify the state key names by reading the body PMuon class first.** Do not guess. Hard-zero with the WRONG key is silent — the sentinel will fire but with `n_L_touched=0, n_R_touched=0`. If you see zero touched, the keys are wrong. Stop, inspect, fix, retry.
- Apply to BOTH L and R for every body PMuon param tensor.
- Do NOT touch `momentum_buffer` (that's #1876).
- Do NOT touch aux Adam (optimizer1) state.
- Apply BEFORE `optimizer2.step()` so the very next update uses scaled cov.

## Smoke test (100 steps)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 50 --body_muon_cov_reset_factor 0.0
```

Assert:
1. Sentinel `[step 50] body PMuon cov reset x0.0: L on N params ... R on M params ...` fires.
2. `n_L_touched > 0` AND `n_R_touched > 0` — if either is zero, the state key names are wrong.
3. After-mean ≈ 0 for hard-zero (factor=0.0).
4. No NaN, no spike, no crash.
5. Confirm train loss continues descending after the reset (the cov rebuild from zero may briefly slow descent for 10-50 steps; that's expected behavior for a hard reset and not a bug).

## Reproduce commands

**Arm A — body PMuon side cov HARD-ZERO @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 975 --body_muon_cov_reset_factor 0.0 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-cov-reset \
  --wandb_name g1r1-fern/body-cov-hardzero-armA-zero
```

**Arm B — body PMuon side cov × 0.5 @ step 975:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --body_muon_cov_reset_step 975 --body_muon_cov_reset_factor 0.5 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-fern-body-cov-reset \
  --wandb_name g1r1-fern/body-cov-hardzero-armB-half
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT modify β_cov (EMA rate)** — #1666 covers that axis.
- **Do NOT modify cov LR or per-side magnitude on the LR axis** — #1849 covers that axis.
- **Do NOT touch momentum_buffer** — #1876 covers that (just closed).
- **Do NOT touch aux Adam state** — orthogonal axis.
- **Do NOT change the temporal boundary** — step 975 is the WIN-bearing cooldown onset.
- **Do NOT skip code inspection** — guessing state-key names produces silent zero-op runs.

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A (hard zero) WIN** | Body cov rebuild from scratch beats the EMA-carried stable-phase preconditioner during cooldown. Request seed-2; potential new merge candidate orthogonal to aux β₂ pulse. |
| **Arm B (×0.5) WIN, Arm A worse** | Partial preservation is better than full reset — some prior info is useful. Identifies the optimal decay range. |
| **Both WIN, Arm A deeper** | Bigger reset is better. Probe even more aggressive decay magnitudes. |
| **Both NULL** | Body PMuon cov state is invariant to perturbation magnitude at this boundary — combined with #1666 (EMA rate) and #1849 (LR axis), the body cov axis is fully closed at cooldown onset. Body PMuon mostly invariant to STATE-side changes regardless of magnitude or rate. |
| **Both regress significantly (Arm A more)** | Cov reset destroys load-bearing preconditioner state; body PMuon depends critically on the EMA-carried stable-phase cov. Strong negative result. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
