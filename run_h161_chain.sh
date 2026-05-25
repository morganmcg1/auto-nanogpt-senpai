#!/bin/bash
# H161 nezuko 3-arm chain: late-training parameter noise probe.
# Arms run sequentially on 1×GPU to avoid GPU corruption (per memory).
set -euo pipefail
mkdir -p training_logs
ARMS=(arm_a arm_b arm_c)

common_args() {
  echo "--num_trials 1 --train_steps 3325 \
    --muonh_mode scale_invariant --muonh_cooldown_shape linear --muonh_warmup_steps 100 \
    --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
    --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
    --aux_adamw_eps 1e-6 --aux_beta2_schedule constant --aux_beta2_start 0.99 \
    --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
    --body_init orthogonal_fnorm_matched \
    --wandb_group g1r3-nezuko-h161-late-noise-probe"
}

per_arm_args() {
  local arm=$1
  case "$arm" in
    arm_a) echo "--late_noise_mode off --wandb_name g1r3-nezuko/h161-arm_a-ctrl" ;;
    arm_b) echo "--late_noise_mode pre_cooldown --late_noise_start_step 1500 --late_noise_sigma_rel 1e-4 --late_noise_interval 50 --wandb_name g1r3-nezuko/h161-arm_b-noise_pre_cooldown" ;;
    arm_c) echo "--late_noise_mode late_cooldown --late_noise_start_step 2992 --late_noise_sigma_rel 1e-4 --late_noise_interval 50 --wandb_name g1r3-nezuko/h161-arm_c-noise_late_cooldown" ;;
    *) echo "unknown arm: $arm" >&2; exit 1 ;;
  esac
}

for arm in "${ARMS[@]}"; do
  LOG=training_logs/h161_${arm}.log
  echo "=== H161 ${arm} starting $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a $LOG
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $(common_args) $(per_arm_args "$arm") 2>&1 | tee -a $LOG
  echo "=== H161 ${arm} finished $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a $LOG
done
echo "=== H161 chain complete $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
