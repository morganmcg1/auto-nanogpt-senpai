#!/usr/bin/env bash
# H342: BODY INITIALIZATION axis sweep at H266 stack.
# 3-arm chain:
#   arm_a CTRL: --body_init orthogonal_fnorm_matched (H266 bit-id)
#   arm_b ORTHO_BOTTOM_DAMP: --body_init orthogonal_bottom_damp (bottom 6 layers × 0.5)
#   arm_c DEFAULT: --body_init default (original normal_ random)

set -u
cd "$(dirname "$0")"
mkdir -p h342_logs

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
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H342_body_init_value
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h342_logs/${arm_name}.log"
  echo "==== H342 ${arm_name} starting at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h342_logs/chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_name "g1r3-askeladd/H342_${arm_name}" \
    > "$logf" 2>&1
  local rc=$?
  echo "==== H342 ${arm_name} DONE rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h342_logs/chain.log
}

run_arm "arm_a_CTRL_orthogonal_fnorm_matched" --body_init orthogonal_fnorm_matched
run_arm "arm_b_ORTHO_BOTTOM_DAMP"             --body_init orthogonal_bottom_damp --body_init_bottom_damp_factor 0.5 --body_init_bottom_layers 6
run_arm "arm_c_DEFAULT"                       --body_init default

echo "==== H342 chain COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h342_logs/chain.log
