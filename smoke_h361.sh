#!/bin/bash
# H361 pre-launch smoke gate per advisor instructions.
# Verifies arm_b TIGHT --muonh_agc_clip_ratio 0.025 (a) does not diverge in 125 steps
# and (b) W&B config reflects the correct treatment value (per
# feedback_chain_launch_verification_gate).
set -u
unset WANDB_API_KEY  # use /root/.netrc (env key on this pod is stale)
cd "$(dirname "$0")"

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H361 SMOKE arm_b TIGHT 0.025 START ====="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant \
  --body_init orthogonal_fnorm_matched \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.025 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H361_muonh_agc_clip_ratio \
  --wandb_name g1r3-thorfinn/H361_SMOKE_arm_b_TIGHT_0p025
rc=$?
echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H361 SMOKE arm_b TIGHT 0.025 rc=${rc} ====="
exit $rc
