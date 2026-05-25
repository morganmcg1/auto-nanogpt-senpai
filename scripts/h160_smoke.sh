#!/usr/bin/env bash
# H160 smoke test: 50-step run on arm_b linear eps schedule. Verifies eps_t
# ramp plumbing, fused=False, and telemetry without burning the full budget.
set -u
cd "$(dirname "$0")/.."

mkdir -p logs_h160

logfile="logs_h160/smoke_arm_b.log"
echo "==========================================" | tee -a "$logfile"
echo "[H160] Starting smoke arm_b linear at $(date -u +%FT%TZ)" | tee -a "$logfile"
echo "==========================================" | tee -a "$logfile"

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
  --aux_adamw_eps 1e-6 --aux_adamw_eps_schedule linear --aux_adamw_eps_end 1e-4 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group g1r3-alphonse-h160-aux-eps-schedule \
  --wandb_name "g1r3-alphonse/H160_smoke_arm_b_linear" \
  >> "$logfile" 2>&1
rc=$?
echo "[H160] smoke arm_b finished rc=${rc} at $(date -u +%FT%TZ)" | tee -a "$logfile"
exit $rc
