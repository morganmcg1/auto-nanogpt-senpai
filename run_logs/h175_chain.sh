#!/usr/bin/env bash
# H175 chain: 3 arms sequential, 1 GPU.
# arm_a CTRL  (exp=0.0, calib=200, recal=0)
# arm_b GENTLE_EARLY (exp=0.25, calib=100, recal=0)
# arm_c HEAVY_EARLY  (exp=1.0,  calib=100, recal=0)

set -u
cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/run_logs
ARM_A_LOG="$LOG_DIR/h175_arm_a.log"
ARM_B_LOG="$LOG_DIR/h175_arm_b.log"
ARM_C_LOG="$LOG_DIR/h175_arm_c.log"

COMMON_FLAGS=(
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
)

echo "[chain] start $(date -u +%Y%m%dT%H%M%SZ)"

# ---- arm_a CTRL ----
echo "[chain] launch arm_a $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_A_LOG"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --muonh_per_block_lr_exponent 0.0 \
  --muonh_per_block_calibration_step 200 \
  --muonh_per_block_recalibrate_interval 0 \
  --wandb_name "g1r3-fern/h175-arm_a-ctrl" \
  --wandb_group "g1r3-fern-h175-per-block-lr-exp-sweep" \
  >> "$ARM_A_LOG" 2>&1
A_RC=$?
echo "[chain] arm_a exit=$A_RC $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_A_LOG"

# ---- arm_b GENTLE_EARLY ----
echo "[chain] launch arm_b $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_B_LOG"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --muonh_per_block_lr_exponent 0.25 \
  --muonh_per_block_calibration_step 100 \
  --muonh_per_block_recalibrate_interval 0 \
  --wandb_name "g1r3-fern/h175-arm_b-gentle-early" \
  --wandb_group "g1r3-fern-h175-per-block-lr-exp-sweep" \
  >> "$ARM_B_LOG" 2>&1
B_RC=$?
echo "[chain] arm_b exit=$B_RC $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_B_LOG"

# ---- arm_c HEAVY_EARLY ----
echo "[chain] launch arm_c $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_C_LOG"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --muonh_per_block_lr_exponent 1.0 \
  --muonh_per_block_calibration_step 100 \
  --muonh_per_block_recalibrate_interval 0 \
  --wandb_name "g1r3-fern/h175-arm_c-heavy-early" \
  --wandb_group "g1r3-fern-h175-per-block-lr-exp-sweep" \
  >> "$ARM_C_LOG" 2>&1
C_RC=$?
echo "[chain] arm_c exit=$C_RC $(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$ARM_C_LOG"

echo "[chain] done $(date -u +%Y%m%dT%H%M%SZ) rcs=$A_RC,$B_RC,$C_RC"
