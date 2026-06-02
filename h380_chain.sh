#!/usr/bin/env bash
# H380: Polar Express minimax-adaptive NS5 replacement for MuonH.
# Amsel, Persson, Musco & Gower (2025), arXiv:2505.16932.
# 3-arm Pattern A bit-id chain at H266 anchor:
#   arm_a CTRL  : --polar_express_mode ns5 (bit-id baseline)
#   arm_b PE12  : --polar_express_mode polar_express --polar_express_iters 12 (same iter budget as NS5)
#   arm_c PE8   : --polar_express_mode polar_express --polar_express_iters 8  (test faster convergence)

set -u
cd "$(dirname "$0")"
mkdir -p h380_logs

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
  --wandb_group g1r3-h380-polar-express
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h380_logs/${arm_name}.log"
  echo "==== H380 ${arm_name} starting at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h380_logs/chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_name "g1r3-askeladd/${arm_name}" \
    > "$logf" 2>&1
  local rc=$?
  echo "==== H380 ${arm_name} DONE rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
    | tee -a h380_logs/chain.log
}

run_arm "h380-arm-a-ctrl"           --polar_express_mode ns5
run_arm "h380-arm-b-polar-default"  --polar_express_mode polar_express --polar_express_iters 12 --polar_express_epsilon 1e-7
run_arm "h380-arm-c-polar-fewer"    --polar_express_mode polar_express --polar_express_iters 8  --polar_express_epsilon 1e-7

echo "==== H380 chain COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" \
  | tee -a h380_logs/chain.log
