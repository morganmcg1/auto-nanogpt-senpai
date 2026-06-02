#!/usr/bin/env bash
# H375 smoke test: arm_a CTRL + arm_b SCHEDULE_FREE at 125 steps.
# Verifies safe-default bit-id (arm_a) and step-0 = 10.82583 EXACT (both).
# Verifies arm_b runs without NaN/divergence and z != x after a few steps.
set -u
cd "$(dirname "$0")"
mkdir -p h375_logs

BASE_ARGS=(
  --num_trials 1
  --train_steps 125
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7
  --outer_momentum 0.5
  --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant
  --aux_beta2_start 0.99
  --muonh_mu_schedule linear
  --muonh_mu_start 0.95
  --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H375_schedule_free_aux_smoke
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h375_logs/${arm_name}.log"
  echo "==== H375 SMOKE ${arm_name} starting at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h375_logs/smoke_chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_name "g1r3-askeladd/H375_smoke_${arm_name}" \
    > "$logf" 2>&1
  local rc=$?
  echo "==== H375 SMOKE ${arm_name} DONE rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h375_logs/smoke_chain.log
}

run_arm "arm_a_CTRL"    --aux_schedulefree 0 --aux_cooldown_frac 0.4
run_arm "arm_b_SF"      --aux_schedulefree 1 --aux_cooldown_frac 0.4

echo "==== H375 smoke chain COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
  | tee -a h375_logs/smoke_chain.log
