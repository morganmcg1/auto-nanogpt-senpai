#!/usr/bin/env bash
# H319 3-arm chain: AUX β1 mid-training SCHEDULE (re-anchored to baseline β1=0.8 per advisor Option A).
# arm_a CTRL            : β1 constant 0.8 (bit-id with H266 baseline; fused=True path)
# arm_b MID_RAMP_UP     : β1 0.8 → 0.85 across pre-cooldown, HOLD at 0.85 through cooldown
# arm_c MID_RAMP_DOWN   : β1 0.8 → 0.75 across pre-cooldown, HOLD at 0.75 through cooldown
#
# All arms use train_steps=3325 to match H266 baseline (FFS=3000, val=3.26818).
# Each arm ~1h50m on 1x RTX PRO 6000 Blackwell → total ~5h30m sequential.

set -euo pipefail
cd "$(dirname "$0")"
mkdir -p h319_logs

BASE_ARGS=(
  --num_trials 1
  --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7
  --outer_momentum 0.5
  --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant
  --aux_beta2_start 0.99
  --muonh_mu_schedule linear
  --muonh_mu_start 0.95
  --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h319_logs/${arm_name}.log"
  echo "=== H319 ${arm_name} starting at $(date -Iseconds) ==="
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_project modded-nanogpt-senpai \
    --wandb_name "g1r3-askeladd/h319-${arm_name}" \
    --wandb_group "H319_aux_beta1_mid_training_schedule" \
    2>&1 | tee "$logf"
  echo "=== H319 ${arm_name} finished at $(date -Iseconds) ==="
}

# arm_a CTRL: β1 constant 0.8 (bit-id with H266 baseline)
run_arm "arm_a_CTRL" \
  --aux_beta1_schedule constant \
  --aux_beta1_start 0.8

# arm_b MID_RAMP_UP: β1 ramps 0.8 → 0.85 across pre-cooldown, holds 0.85 through cooldown
run_arm "arm_b_MID_RAMP_UP" \
  --aux_beta1_schedule mid_training_ramp \
  --aux_beta1_start 0.8 \
  --aux_beta1_end 0.85

# arm_c MID_RAMP_DOWN: β1 ramps 0.8 → 0.75 across pre-cooldown, holds 0.75 through cooldown
run_arm "arm_c_MID_RAMP_DOWN" \
  --aux_beta1_schedule mid_training_ramp \
  --aux_beta1_start 0.8 \
  --aux_beta1_end 0.75

echo "=== H319 chain complete at $(date -Iseconds) ==="
