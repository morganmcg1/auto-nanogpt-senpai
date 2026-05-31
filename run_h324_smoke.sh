#!/usr/bin/env bash
# H324 — smoke arm_c WARMUP_LONG at 125 steps to verify:
#   - step-0 val = 10.82583 EXACT (Pattern A bit-id with H266 baseline)
#   - outer_lr_t telemetry at outer steps:
#       outer step 0 (train_step=30):  outer_lr_t = 0.0
#       outer step 1 (train_step=60):  outer_lr_t = 0.7 * (1/30) = 0.02333
#       outer step 2 (train_step=90):  outer_lr_t = 0.7 * (2/30) = 0.04667
#       outer step 3 (train_step=120): outer_lr_t = 0.7 * (3/30) = 0.07000
#   - step-125 val finite (~5.17 typical for 125-step runs)
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p logs_h324_smoke

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --outer_lr_schedule warmup_linear \
  --outer_lr_warmup_outer_steps 30 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H324_smoke_outer_lr_warmup \
  --wandb_name "g1r3-tanjiro/H324_smoke_arm_c_WARMUP_LONG" \
  2>&1 | tee logs_h324_smoke/arm_c.out

echo "=== smoke complete ==="
