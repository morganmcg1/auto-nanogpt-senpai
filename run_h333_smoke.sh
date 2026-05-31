#!/bin/bash
# H333 smoke test: 125-step verification on arm_c (most aggressive DOWN endpoint).
# Confirms:
# - Step-0 val matches H266 baseline 10.82583 EXACT (bit-id with CTRL)
# - aux/beta2 = 0.99 EXACT at smoke steps (still pre-cooldown, ramp starts at step 1995)
# - No crashes/OOMs

set -u
cd /workspace/senpai/target

mkdir -p logs_h333_smoke
LOG=/workspace/senpai/target/logs_h333_smoke.log

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule cooldown_ramp --aux_beta2_start 0.99 --aux_beta2_end 0.97 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group h333_smoke \
  --wandb_name "g1r3-frieren/H333_smoke_arm_c" 2>&1 | tee "$LOG"

echo "===== H333 smoke complete at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====="
