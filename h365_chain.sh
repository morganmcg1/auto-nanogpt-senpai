#!/usr/bin/env bash
# H365: INVERSE per-layer BODY MuonH LR coupling via body_lr_init_fnorm_alpha < 0.
# 3-arm Pattern A bit-id chain at H266 anchor:
#   arm_a CTRL       : --body_lr_init_fnorm_alpha  0.0   (uniform LR; H266 bit-id)
#   arm_b NEG_SQRT   : --body_lr_init_fnorm_alpha -0.5   (sqrt suppression on high F-norm)
#   arm_c NEG_LINEAR : --body_lr_init_fnorm_alpha -1.0   (linear suppression on high F-norm)

set -u
cd "$(dirname "$0")"
mkdir -p h365_logs

BASE_ARGS=(
  --num_trials 1
  --train_steps 3325
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
  --wandb_group H365_inverse_body_lr_init_fnorm_coupling
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h365_logs/${arm_name}.log"
  echo "==== H365 ${arm_name} starting at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h365_logs/chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_name "g1r3-askeladd/H365_${arm_name}" \
    > "$logf" 2>&1
  local rc=$?
  echo "==== H365 ${arm_name} DONE rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h365_logs/chain.log
}

run_arm "arm_a_CTRL_alpha0p0"        --body_lr_init_fnorm_alpha 0.0
run_arm "arm_b_NEG_SQRT_alpha-0p5"   --body_lr_init_fnorm_alpha -0.5
run_arm "arm_c_NEG_LINEAR_alpha-1p0" --body_lr_init_fnorm_alpha -1.0

echo "==== H365 chain COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
  | tee -a h365_logs/chain.log
