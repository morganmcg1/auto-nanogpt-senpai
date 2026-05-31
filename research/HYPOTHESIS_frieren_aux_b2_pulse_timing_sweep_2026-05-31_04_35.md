# HYPOTHESIS — frieren — Aux Adam β₂ pulse TIMING SWEEP: delay primary pulse from step 975 → 1100 or 1200

**Branch:** `g1r1-frieren/aux-b2-pulse-timing-sweep`
**Assigned:** 2026-05-31 04:35 UTC
**Baseline target:** PR #1532, sr=2875, val_ema=3.262854 (n=2)
**Merge gate (strict):** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`
**Directives:** (c) short phase-specific mechanisms; (e) schedules that steepen loss descent before step 2925

## Why this hypothesis

The canonical β₂ pulse (0.95→0.99 @ step 975) is the baseline WIN mechanism (#1532). The step 975 timing was chosen to coincide with the **stable/cooldown phase boundary** (`stable_steps = int(0.3 × 3250) = 975`). However, this is a heuristic: the regime transition is not instantaneous, and the optimal pulse timing for aligning the v-buffer integration scale with the cooldown LR trajectory may not be the first step of cooldown.

**The open question:** Is step 975 the optimal β₂ pulse timing, or would a pulse triggered slightly **after** the LR schedule has already begun decaying (e.g., step 1100 or 1200) produce a stronger alignment effect?

**Mechanistic reasoning for a LATER pulse:**
- At step 975, the LR has just started decaying. The gradient magnitude distribution is still approximately "stable-phase" calibrated.
- By step 1100–1200, the LR has decayed by ~10-15%, the training dynamics have adapted to the new regime, and the v-buffer is integrating a gradient magnitude distribution more representative of the actual cooldown phase.
- A pulse at this point may produce better long-term v-buffer alignment with the cooldown trajectory.

**What's been tested:**
- β₂ pulse amplitude at 975: 0.97 (Arm A, NULL) vs 0.99 (Arm B, WIN) — timing fixed
- β₂ pulse per-group localization at 975: embed-only (NULL), lm_head-only (NULL) — timing fixed
- β₂ "pre-target re-spike" at step ~2750: NULL — tested a second pulse at the wrong boundary
- **β₂ pulse timing sweep (975 vs 1100 vs 1200): NEVER TESTED**

## Experiment design

**Bilateral primary-pulse TIMING test:**

- **Arm A — β₂ pulse @ step 1100 (0.95→0.99):** Step 1100 is ~125 steps into cooldown; LR is ~12% below peak; still within the narrow "high-priority" cooldown window before training spends significant steps with the new β₂ regime.
- **Arm B — β₂ pulse @ step 1200 (0.95→0.99):** Step 1200 is ~225 steps into cooldown. Tests whether more LR decay context is better, or whether 1100 is already too late.

Both arms preserve all canonical interventions EXCEPT `--aux_b2_pulse_step` (which changes from 975 to 1100 or 1200). All other flags: pEMA refresh @ 2600, late-higher block LR, ema_beta=0.97.

**NOTE:** Both arms run WITHOUT `--aux_b2_pulse_step 975` (no pulse at 975). They instead fire at 1100 or 1200. This directly tests whether the timing matters or whether any timing is equivalent.

## Implementation guidance

**No code changes needed** — `--aux_b2_pulse_step` is an existing CLI flag from the baseline. Just change the step value.

**Arm A:** `--aux_b2_pulse_step 1100 --aux_b2_pulse_target 0.99`  
**Arm B:** `--aux_b2_pulse_step 1200 --aux_b2_pulse_target 0.99`

No new flags, no new code. Canonical baseline training script.

## Reproduce commands

**Arm A — β₂ pulse @ step 1100:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 1100 --aux_b2_pulse_target 0.99 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-aux-b2-timing-sweep \
  --wandb_name g1r1-frieren/aux-b2-timing-armA-step1100
```

**Arm B — β₂ pulse @ step 1200:**

```bash
pgrep -f 'train_gpt_simple\.py' && echo 'BLOCKED' && exit 1
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 1200 --aux_b2_pulse_target 0.99 \
  --seed 1 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r1-frieren-aux-b2-timing-sweep \
  --wandb_name g1r1-frieren/aux-b2-timing-armB-step1200
```

Run **Arm A first**, then chain Arm B after Arm A exits.

## Anti-patterns

- **Do NOT fire the pulse at step 975** — this is precisely what we're sweeping away from. Use ONLY `--aux_b2_pulse_step 1100` (Arm A) or `--aux_b2_pulse_step 1200` (Arm B).
- **Do NOT change `--aux_b2_pulse_target`** — keep 0.99 (confirmed WIN amplitude).
- **Do NOT try step 975 again** — baseline is already there; comparing against baseline IS the comparison.
- **Do NOT try a second pulse** at a later step on top of the primary — keep it clean (single pulse, different timing).

## Expected outcomes

| Outcome | Interpretation |
|---|---|
| **Arm A (1100) WIN** | Later β₂ pulse better aligns with cooldown LR trajectory. Step 1100 is the new canonical pulse timing. Request seed-2; merge. |
| **Arm B (1200) WIN deeper than Arm A (1100)** | Even more delay helps. Optimum is in the 1100-1200 range; probe further. |
| **Both NULL, within 2 mnat of gate** | Timing has low sensitivity — 975 is approximately optimal. Confirms that the β₂ pulse timing is not a key lever. |
| **Both NULL or regress significantly** | Step 975 (phase boundary) is the optimal trigger — the mechanism requires firing exactly at the regime transition, not with a delay. Timing axis CLOSED. |

## SENPAI-RESULT marker

```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<armA-id>","<armB-id>"],"primary_metric":{"name":"ema/val_loss_ema","value":<float>},"test_metric":{"name":"speedrun/final_first_step_to_target","value":<int>}}
```
