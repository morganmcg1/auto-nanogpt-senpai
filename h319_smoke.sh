#!/usr/bin/env bash
# H319 smoke gate: 125-step arm_b MID_RAMP_UP run to verify:
#  - step-0 val=10.82583 EXACT (Pattern A bit-id drift gate)
#  - W&B config-pane: aux_beta1_schedule=mid_training_ramp, aux_beta1_end=0.85
#  - step-125 val finite
#  - W&B telemetry: aux/beta1 = 0.85 at step 125 (past cooldown_start=75 for
#    125-step run with aux_cooldown_frac=0.4 → cooldown_start=int(0.6*125)=75)

set -euo pipefail
cd "$(dirname "$0")"
mkdir -p h319_logs

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_beta1_schedule mid_training_ramp --aux_beta1_start 0.8 --aux_beta1_end 0.85 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H319_smoke_aux_beta1_up \
  --wandb_name g1r3-askeladd/H319_smoke_arm_b_up \
  2>&1 | tee h319_logs/smoke_arm_b_up.log
