#!/bin/bash
# H309 smoke gate: 125 steps for mid_training_ramp branch sanity
# Verifies step-0 val=10.82583 bit-id, finite step-125 val, W&B telemetry.

set -u
cd /workspace/senpai/target

mkdir -p logs_h309_smoke
LOG=/workspace/senpai/target/logs_h309_smoke.log

COMMON=(
  --num_trials 1 --train_steps 125
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
  --wandb_group H309_smoke_aux_beta2_mid_ramp
)

ARM="arm_b_MID_RAMP_DOWN_smoke"
echo "===== H309 SMOKE $ARM launched at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
ARM_LOG="logs_h309_smoke/${ARM}.log"
WANDB_MODE=offline torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --aux_beta2_schedule mid_training_ramp --aux_beta2_start 0.99 --aux_beta2_end 0.97 \
  --wandb_name "g1r3-frieren/H309_smoke_${ARM}" 2>&1 | tee -a "$LOG" "/workspace/senpai/target/${ARM_LOG}"
echo "===== H309 SMOKE $ARM finished at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
