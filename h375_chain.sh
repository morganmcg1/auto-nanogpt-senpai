#!/usr/bin/env bash
# H375: Schedule-Free AdamW AUX optimizer probe at H266 stack.
# 3-arm Pattern A drift-FREE bit-id chain:
#   arm_a CTRL:           --aux_schedulefree 0 --aux_cooldown_frac 0.4  (bit-id with H266 baseline)
#   arm_b SF_COSINE:      --aux_schedulefree 1 --aux_cooldown_frac 0.4  (SF + cosine cooldown, tests composition)
#   arm_c SF_NOCOSINE:    --aux_schedulefree 1 --aux_cooldown_frac 0.0  (SF replaces cosine cooldown)

set -u
cd "$(dirname "$0")"
mkdir -p h375_logs

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
  --wandb_group H375_schedule_free_aux
)

run_arm () {
  local arm_name="$1"; shift
  local arm_args=("$@")
  local logf="h375_logs/${arm_name}.log"
  echo "==== H375 ${arm_name} starting at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h375_logs/chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" \
    "${arm_args[@]}" \
    --wandb_name "g1r3-askeladd/H375_${arm_name}" \
    > "$logf" 2>&1
  local rc=$?
  echo "==== H375 ${arm_name} DONE rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h375_logs/chain.log
}

run_arm "arm_a_CTRL"          --aux_schedulefree 0 --aux_cooldown_frac 0.4
run_arm "arm_b_SF_COSINE"     --aux_schedulefree 1 --aux_cooldown_frac 0.4
run_arm "arm_c_SF_NOCOSINE"   --aux_schedulefree 1 --aux_cooldown_frac 0.0

echo "==== H375 chain COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ====" | tee -a h375_logs/chain.log
