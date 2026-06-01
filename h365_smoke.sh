#!/usr/bin/env bash
# H365 pre-launch smoke: 125 steps with arm_b NEG_SQRT α=-0.5 to verify
# (a) non-divergence at step 125
# (b) Pattern A step-0 val=10.82583 EXACT bit-id
# (c) lr_mult range REVERSED: attn-proj layers (high init F-norm) get SMALLER lr_mult
# (d) lr_mult_min ~ 0.58 for α=-0.5 (sqrt suppression)
# (e) W&B config logs body_lr_init_fnorm_alpha=-0.5 correctly
set -u
mkdir -p /workspace/senpai/target/h365_logs
cd /workspace/senpai/target

torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --body_lr_init_fnorm_alpha -0.5 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H365_inverse_body_lr_init_fnorm_coupling \
  --wandb_name "g1r3-askeladd/H365_smoke_arm_b_NEG_SQRT_alpha-0.5_125steps" \
  > h365_logs/smoke_arm_b_125steps.log 2>&1
rc=$?
echo "==== H365 SMOKE DONE rc=$rc at $(date -u +%Y-%m-%dT%H:%M:%SZ) ===="
