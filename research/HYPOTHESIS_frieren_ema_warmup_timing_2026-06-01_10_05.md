# HYPOTHESIS — frieren: paramEMA warmup activation step SWEEP (--ema_warmup_steps)

**Status:** ASSIGNED 2026-06-01 10:05 UTC
**Student:** g1r1-frieren
**PR:** TBD

## Mechanism

Shift the step at which paramEMA becomes active (`--ema_warmup_steps`), testing whether EARLIER or LATER EMA activation improves the pre-target descent.

Baseline: `--ema_warmup_steps 1750` (EMA live-tracks params through step 1749, starts smoothing at step 1750).

- **Arm A:** `--ema_warmup_steps 1250` — EMA activates 500 steps EARLIER (during late-warmup phase, before the LR peak)
- **Arm B:** `--ema_warmup_steps 2250` — EMA activates 500 steps LATER (mid-cooldown, well into the descent)

Zero new code — existing flag, single-value swap per arm.

## Why this matters

The paramEMA mechanism controls when the model's parameter snapshot switches from live-tracking to exponential smoothing. The β ramp (`ema_beta → ema_beta_target`) is coupled to the LR decay: `beta_t = ema_beta + (ema_beta_target - ema_beta) * (1 - lr_mult)`.

Key unknowns:
1. **Earlier activation (Arm A @1250):** EMA starts smoothing 500 steps before baseline. The 1250–1750 window is post-warmup but pre-cooldown — smoothing during this "stable plateau" phase might preserve a better convergence trajectory into the cooldown descent.
2. **Later activation (Arm B @2250):** EMA stays live-tracking for 500 extra cooldown steps (1750–2250). This "live parameter mode" during the active descent phase means val_ema reflects a fresher parameter estimate at the exact point where the loss is dropping fastest. Potentially allows val_ema to respond faster to the final descent and cross the 3.28 gate before step 2925.

Arm B is the higher-variance hypothesis — later activation means the final 1000 steps of smoothing (2250–3250) need to be enough. But if the descent is steep enough in 1750–2250, live-tracking during that window might capture more of it.

Complementary to fern's #2102 (paramEMA REFRESH boundary ablation) which tests WHEN `ema_p` is overwritten with live params; this PR tests WHEN EMA smoothing begins.

## Predictions

| outcome | interpretation |
|---|---|
| Arm B (later @2250) WIN | EMA was over-smoothing the live descent 1750–2250; later activation captures more of the steepest descent. |
| Arm A (earlier @1250) WIN | EMA smoothing in 1250–1750 preserves a better reference trajectory; counterintuitive. |
| Both arms NULL, Arm B closer to gate | Signal: later activation is directionally better but 500-step shift insufficient — test @2000 or @2500 as follow-up. |
| Both arms NULL, similar to baseline | ema_warmup_steps is not a load-bearing schedule parameter in the tested range. |

## Reproduce commands

**Full baseline stack required on ALL runs.**

### Arm A — ema_warmup_steps 1250 (EARLIER activation)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1250 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-frieren-ema-warmup-timing \
  --wandb_name g1r1-frieren/ema-warmup-1250
```

### Arm B — ema_warmup_steps 2250 (LATER activation)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 2250 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-frieren-ema-warmup-timing \
  --wandb_name g1r1-frieren/ema-warmup-2250
```

**Chain rule:** Arm A first. Launch Arm B after Arm A `wandb.finish()` AND training process exit.

**Seed-2 trigger:** If either arm achieves `sr=2875 AND val_ema < 3.262854`, launch a seed-2 confirmation run before posting terminal SENPAI-RESULT.

**Note on Arm B:** Log `ema/active` — it should be 0 for steps 0–2249 and 1 from step 2250 onwards. This confirms the flag fired correctly.

## Baseline (PR #1532)

- **speedrun/final_first_step_to_target:** 2875 (n=2)
- **ema/val_loss_ema:** 3.262854 (n=2 mean)
- **Gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **W&B baseline runs:** `9coyk2ke` (seed-1), `09qrijtm` (seed-2)

## SENPAI-RESULT format

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA>","<armB>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<int>},"test_metric":{"name":"ema/val_loss_ema","value":<float>}}
```
