#!/bin/bash
# H276 fern: Gradient noise injection (Neelakantan annealed σ).
# 3-arm chain on post-H266 baseline.
set -euo pipefail
cd "$(dirname "$0")"

LOG_DIR=run_logs/h276
mkdir -p "$LOG_DIR"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --grad_noise_gamma 0.55
  --wandb_project modded-nanogpt-senpai
  --wandb_group H276_gradient_noise_injection
)

echo "=== H276 arm_a CTRL (sigma_0=0.0) ===" | tee -a "$LOG_DIR/chain.log"
date | tee -a "$LOG_DIR/chain.log"
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --grad_noise_sigma_0 0.0 \
  --wandb_name g1r3-fern/H276_arm_a_CTRL_sigma0 \
  > "$LOG_DIR/arm_a.log" 2>&1
echo "arm_a done $(date)" | tee -a "$LOG_DIR/chain.log"

echo "=== H276 arm_b LOW (sigma_0=0.01) ===" | tee -a "$LOG_DIR/chain.log"
date | tee -a "$LOG_DIR/chain.log"
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --grad_noise_sigma_0 0.01 \
  --wandb_name g1r3-fern/H276_arm_b_LOW_sigma01 \
  > "$LOG_DIR/arm_b.log" 2>&1
echo "arm_b done $(date)" | tee -a "$LOG_DIR/chain.log"

echo "=== H276 arm_c HIGH (sigma_0=0.05) ===" | tee -a "$LOG_DIR/chain.log"
date | tee -a "$LOG_DIR/chain.log"
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --grad_noise_sigma_0 0.05 \
  --wandb_name g1r3-fern/H276_arm_c_HIGH_sigma05 \
  > "$LOG_DIR/arm_c.log" 2>&1
echo "arm_c done $(date)" | tee -a "$LOG_DIR/chain.log"

echo "=== chain complete $(date) ===" | tee -a "$LOG_DIR/chain.log"
