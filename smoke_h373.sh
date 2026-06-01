#!/bin/bash
# H373 LSUV INIT probe — 125-step smoke for arm_a CTRL + arm_b LSUV.
# arm_a CTRL body_init_lsuv=0 — safe-default short-circuit (verifies Pattern A bit-id)
# arm_b LSUV body_init_lsuv=1 target_std=1.0 — classical LSUV unit-variance rescaling
set -e

cd /workspace/senpai/target
mkdir -p /workspace/senpai/target/smoke_h373_logs

run_smoke() {
  local arm="$1"
  local lsuv_flag="$2"
  local lsuv_target="$3"
  local logfile="/workspace/senpai/target/smoke_h373_logs/smoke_${arm}.log"
  echo "=== SMOKE $arm: body_init_lsuv=$lsuv_flag target_std=$lsuv_target ===" | tee -a "$logfile"
  date | tee -a "$logfile"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 --train_steps 125 \
    --muonh_mode scale_invariant --muonh_cooldown_shape cosine \
    --muonh_warmup_steps 100 \
    --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
    --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
    --aux_beta2_schedule constant --aux_beta2_start 0.99 \
    --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
    --body_init orthogonal_fnorm_matched \
    --polyak_ema_decay 0.05 \
    --body_init_lsuv "$lsuv_flag" --body_init_lsuv_target_std "$lsuv_target" \
    --wandb_project modded-nanogpt-senpai \
    --wandb_group H373_lsuv_smoke \
    --wandb_name "g1r3-fern/H373_smoke_${arm}" 2>&1 | tee -a "$logfile"
  echo "=== SMOKE $arm DONE ===" | tee -a "$logfile"
  date | tee -a "$logfile"
}

run_smoke "arm_a_CTRL" 0 1.0
run_smoke "arm_b_LSUV" 1 1.0
echo "H373 smoke runs complete."
date
