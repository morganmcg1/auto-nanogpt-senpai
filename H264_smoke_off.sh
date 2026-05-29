#!/bin/bash
# H264 smoke (lookahead OFF): 80 steps. Verify step-0 val_loss = 10.82583 EXACT.
set -e
cd /workspace/senpai/target
exec torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 80 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --lookahead_enabled 0 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai --wandb_group H264_smoke \
  --wandb_name g1r3-edward/H264_smoke_off
