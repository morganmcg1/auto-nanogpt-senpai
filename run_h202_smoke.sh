#!/bin/bash
# H202 smoke test: 50 steps with SF on, --aux_cooldown_frac 0.0
# Verifies SF mechanism is live and no NaN/divergence.
set -euxo pipefail

cd "$(dirname "$0")"

export WANDB_PROJECT="modded-nanogpt-senpai"
export WANDB_ENTITY="wandb-applied-ai-team"
export STUDENT_NAME="g1r3-frieren"

LOG=logs_h202/smoke_$(date +%Y%m%d_%H%M%S).log

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 50 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape linear \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --aux_schedule_free --aux_cooldown_frac 0.0 \
  --wandb_name "g1r3-frieren/h202-smoke" \
  --wandb_group "g1r3-frieren-h202-sf-smoke" \
  2>&1 | tee "$LOG"
