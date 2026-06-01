#!/usr/bin/env bash
set -euo pipefail
# H368 pre-launch smoke tests — arm_a CTRL + arm_b ADEMAMIX, 125 steps each
# Gate: step-0 val=10.82583 EXACT on both arms
# Run from /workspace/senpai/target so data/fineweb10B/ path resolves correctly.
cd /workspace/senpai/target
mkdir -p runlogs/h368

echo "=== H368 arm_a CTRL smoke (125 steps, adamw) ==="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_optimizer adamw \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H368_ademamix_aux_optimizer \
  --wandb_name g1r3-edward/H368_arm_a_CTRL_smoke 2>&1 | tee runlogs/h368/smoke_arm_a.log

echo ""
echo "=== H368 arm_b ADEMAMIX smoke (125 steps, ademamix beta3=0.9999 alpha=8.0) ==="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_optimizer ademamix --ademamix_beta3 0.9999 --ademamix_alpha 8.0 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H368_ademamix_aux_optimizer \
  --wandb_name g1r3-edward/H368_arm_b_ADEMAMIX_smoke 2>&1 | tee runlogs/h368/smoke_arm_b.log

echo ""
echo "=== Both smokes complete. Check val=10.82583 EXACT on step 0 for BOTH arms. ==="
