#!/bin/bash
# H271 arm_b LA_OFF_AT_2300: Lookahead k=10 alpha=0.5 active 0-2299, OFF from step 2300.
set -e
cd /workspace/senpai/target
exec torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --lookahead_enabled 1 --lookahead_k 10 --lookahead_alpha 0.5 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --lookahead_deactivation_step 2300 \
  --wandb_project modded-nanogpt-senpai --wandb_group H271_lookahead_cooldown_gated \
  --wandb_name g1r3-edward/H271_arm_b_LA_OFF_AT_2300_v2
