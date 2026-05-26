#!/usr/bin/env bash
set -u

LOGDIR="logs_h179"
mkdir -p "$LOGDIR"

run_arm() {
  local name="$1"
  shift
  local logfile="$LOGDIR/${name}.log"
  echo "=== START $name @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$logfile"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py "$@" 2>&1 | tee -a "$logfile"
  local rc=${PIPESTATUS[0]}
  echo "=== END   $name rc=$rc @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$logfile"
  return "$rc"
}

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape linear
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --muonh_per_block_recalibrate_interval 0
  --wandb_group "g1r3-tanjiro-h179-per-block-lr-calib25-bracket"
)

run_arm "arm_a-ctrl" "${COMMON[@]}" \
  --muonh_per_block_lr_exponent 0.0 \
  --muonh_per_block_calibration_step 200 \
  --wandb_name "g1r3-tanjiro/h179-arm_a-ctrl"
ARM_A_RC=$?

run_arm "arm_b-gentle-ultra-early" "${COMMON[@]}" \
  --muonh_per_block_lr_exponent 0.25 \
  --muonh_per_block_calibration_step 25 \
  --wandb_name "g1r3-tanjiro/h179-arm_b-gentle-ultra-early"
ARM_B_RC=$?

run_arm "arm_c-strong-ultra-early" "${COMMON[@]}" \
  --muonh_per_block_lr_exponent 1.0 \
  --muonh_per_block_calibration_step 25 \
  --wandb_name "g1r3-tanjiro/h179-arm_c-strong-ultra-early"
ARM_C_RC=$?

echo "=== CHAIN SUMMARY ==="
echo "arm_a rc=$ARM_A_RC"
echo "arm_b rc=$ARM_B_RC"
echo "arm_c rc=$ARM_C_RC"
