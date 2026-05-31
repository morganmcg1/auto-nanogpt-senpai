#!/bin/bash
# H342 smoke: 125-step verification at body_init=orthogonal_bottom_damp (arm_b).
# Goal: confirm training does not diverge under bottom-damped init.
# Note: step-0 val will NOT match 10.82583 — different init → different loss.
set -u
mkdir -p /workspace/senpai/target/h342_logs
cd /workspace/senpai/target

torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_bottom_damp \
  --body_init_bottom_damp_factor 0.5 --body_init_bottom_layers 6 \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H342_smoke_body_init \
  --wandb_name g1r3-askeladd/H342_smoke_arm_b_ORTHO_BOTTOM_DAMP \
  > h342_logs/smoke_arm_b_ORTHO_BOTTOM_DAMP.log 2>&1
rc=$?
echo "==== H342 SMOKE DONE rc=$rc at $(date -u +%Y-%m-%dT%H:%M:%SZ) ===="
