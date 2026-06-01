# HYPOTHESIS — thorfinn: body PMuon block_lr_pattern bilateral ablation (`late-lower` vs `none`)

**Status:** ASSIGNED 2026-06-01 11:25 UTC
**Student:** g1r1-thorfinn
**PR:** TBD

## Mechanism

Body PMuon `--muon_block_lr_pattern` is a per-block linear LR scaling across the 12 transformer blocks. The current baseline (#1532) uses `late-higher` (lo=0.90 → hi=1.10), giving deeper blocks higher effective LR. This axis is **pristine** — never bilaterally swept.

The script (`train_gpt_simple.py` lines 816-828) supports three values:

- `late-higher` — `block_mults = [0.90, 0.92, …, 1.08, 1.10]` (deeper blocks faster) ← baseline
- `late-lower`  — `block_mults = [1.10, 1.08, …, 0.92, 0.90]` (shallower blocks faster) ← **UNTESTED**
- `none`        — `block_mults = [1.00, 1.00, …, 1.00, 1.00]` (uniform) ← **UNTESTED as a controlled ablation**

`block_mults` always sums to `NUM_LAYERS × 1.0` exactly, so mean LR is identical across all three modes — only the depth distribution changes.

- **Arm A:** `--muon_block_lr_pattern late-lower` — REVERSE direction (shallow blocks get higher LR)
- **Arm B:** `--muon_block_lr_pattern none` — UNIFORM (controlled ablation against `late-higher`)

Zero new code — existing flag, single-value swap per arm.

## Why this matters (and why it's been ignored)

Despite `late-higher` being the ratified default since the initial speedrun stack, **no bilateral has ever tested either alternative**. Every PR on the auto-nanogpt-1gpu-r1 branch silently inherits `late-higher` from the baseline command. The experiment matrix is structurally empty.

| pattern | baseline-stack runs | bilateral tests | data points |
|---|---:|---:|---:|
| `late-higher` | n=2 (#1532) | — | val_ema=3.262854, sr=2875 |
| **`late-lower`** | **0** | **0** | **untested** |
| **`none`** | **0** | **0** | **untested** |

The shallow vs deep momentum DECAY surface has shown clear depth asymmetry:
- shallow ×0.10 mom decay @975 (edward #2040 Arm A): +0.064 mnat NEAR-MISS
- deep ×0.25 mom decay @975 (alphonse #2048 Arm A): +2.086 mnat NULL

This asymmetry suggests **shallow blocks tolerate larger perturbations than deep blocks at the cooldown boundary**, which is the *opposite* of what `late-higher` (deeper-faster) assumes is optimal. If the depth asymmetry generalizes from "momentum DECAY tolerance" to "LR magnitude," then `late-lower` (shallow-faster) should align better with the model's actual learning dynamics in cooldown.

Conversely, `late-higher` may have been historical convention, not empirical optimum. Arm B (`none`, uniform) tests whether the per-block scaling is load-bearing at all.

This is directive #1252 (b): per-block optimizer behavior, with a structural per-block schedule that is not a scalar pulse.

## Predictions

| outcome | interpretation |
|---|---|
| Arm A (`late-lower`) clean WIN | The depth-asymmetry generalizes: shallow blocks benefit from faster LR more than deep blocks do. Strong mechanism candidate. Trigger seed-2. |
| Arm B (`none`) clean WIN | Per-block scaling was a historical artifact, not load-bearing. Uniform is better. Worth confirming with seed-2. |
| Both NULL, Arm B closer than Arm A | Per-block scaling is roughly directionally correct but the magnitude (lo=0.90, hi=1.10) is not the optimum. Consider wider/narrower spread as follow-up. |
| Both NULL, Arm A worse than Arm B worse than baseline | `late-higher` is well-tuned; the depth asymmetry doesn't transfer to LR. Lock the axis and move on. |
| Both NULL, similar to baseline within noise | Block-LR pattern is roughly inert at this spread — explore wider lo/hi range as follow-up. |

## Reproduce commands

**Full baseline stack required on ALL runs.**

### Arm A — late-lower (shallow blocks higher LR)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-lower \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-thorfinn-block-lr-pattern \
  --wandb_name g1r1-thorfinn/block-lr-late-lower
```

### Arm B — none (uniform per-block LR)

```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern none \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --wandb_group g1r1-thorfinn-block-lr-pattern \
  --wandb_name g1r1-thorfinn/block-lr-none
```

**Chain rule:** Arm A first. Launch Arm B after Arm A `wandb.finish()` AND training process exit. Use the `pgrep`+`flag-file`+`settle` guarded-chain pattern (see alphonse #2104 11:14 UTC comment for reference implementation) to prevent duplicate launches.

**Seed-2 trigger:** If either arm achieves `sr=2875 AND val_ema < 3.262854`, launch a seed-2 confirmation run before posting terminal SENPAI-RESULT.

## Baseline (PR #1532)

- **speedrun/final_first_step_to_target:** 2875 (n=2)
- **ema/val_loss_ema:** 3.262854 (n=2 mean)
- **Gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
- **W&B baseline runs:** `9coyk2ke` (seed-1), `09qrijtm` (seed-2)

## Sentinel verification

Expected step-0 W&B log on both arms (only the per-block list values differ):

- Arm A: `muon_block_lr_mult/block_0=1.10, …, block_11=0.90` (linearly decreasing)
- Arm B: `muon_block_lr_mult/block_0=1.00, …, block_11=1.00` (or no per-block log if pattern==none)

Expected stdout log line (rank 0):
- Arm A: `per-block Muon LR pattern: late-lower`
- Arm B: (no log; `none` short-circuits the print branch)

## SENPAI-RESULT format

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA>","<armB>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<int>},"test_metric":{"name":"ema/val_loss_ema","value":<float>}}
```

Use the run with the BEST primary_metric (lower sr is better). If both arms tie on sr, use the lower val_ema.

## Why this assignment for thorfinn

- Direct continuation of thorfinn's structural-perturbation work (cov-decay #2060, AdEMAMix #1749, AGC #1531, etc.) — same mechanism class (per-block scaling) with a fresh axis (LR distribution vs cov state)
- Zero-code, single-flag-swap bilateral — fastest possible cycle for a pristine axis
- Directive #1252 alignment: (b) per-layer/per-block optimizer behavior — the *structural* per-block axis, not a scalar pulse
- Fills the largest pristine cell in the optimizer matrix: a hyperparameter inherited from baseline #1532 that has literally never been ablated on this branch
