#!/bin/bash
# H309 aux β2 mid-training schedule (PR #1851)
# 3-arm Pattern A Option C structural test:
#   arm_a CTRL constant β2=0.99 (replicates H266 baseline)
#   arm_b MID_RAMP_DOWN β2 0.99 -> 0.97 during pre-cooldown, hold 0.97 in cooldown
#   arm_c MID_RAMP_UP   β2 0.99 -> 0.995 during pre-cooldown, hold 0.995 in cooldown

set -u
cd /workspace/senpai/target

mkdir -p logs_h309
LOG=/workspace/senpai/target/logs_h309_chain.log

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H309_aux_beta2_mid_training_ramp
)

run_arm () {
  local ARM=$1
  shift
  echo "===== H309 $ARM launched at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
  local ARM_LOG="logs_h309/${ARM}.log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    "$@" \
    --wandb_name "g1r3-frieren/H309_${ARM}" 2>&1 | tee -a "$LOG" "/workspace/senpai/target/${ARM_LOG}"
  echo "===== H309 $ARM finished at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
}

run_arm arm_a_CTRL \
  --aux_beta2_schedule constant --aux_beta2_start 0.99

run_arm arm_b_MID_RAMP_DOWN \
  --aux_beta2_schedule mid_training_ramp --aux_beta2_start 0.99 --aux_beta2_end 0.97

run_arm arm_c_MID_RAMP_UP \
  --aux_beta2_schedule mid_training_ramp --aux_beta2_start 0.99 --aux_beta2_end 0.995

echo "===== H309 chain complete at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
