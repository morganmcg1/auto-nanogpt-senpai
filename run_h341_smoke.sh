#!/bin/bash
# H341 smoke gate: arm_c MEDIUM (λ=1e-4) at 125 steps. Verifies step-0
# val=10.82583 bit-id, no NaN/inf in spec_loss telemetry, body/spec_loss in
# target regime 1e-5 to 1e-2 at step 125 (comparable to H326 arm_c regularizer
# tax).
set -u
cd /workspace/senpai/target

mkdir -p logs_h341_smoke
LOG=/workspace/senpai/target/logs_h341_smoke.log
unset WANDB_API_KEY

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
  --body_spectral_penalty 1e-4 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H341_smoke_body_spectral_penalty \
  --wandb_name g1r3-frieren/H341_smoke_arm_c_MEDIUM 2>&1 | tee -a "$LOG"
