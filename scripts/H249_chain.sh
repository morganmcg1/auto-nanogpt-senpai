#!/bin/bash
# H249 3-arm chain: arm_a CTRL, arm_b RIEMANNIAN_DEFAULT, arm_c RIEMANNIAN_DETACHED.
# Each arm runs 3325 steps with the H203 baseline configuration. Sequential
# dispatch so a single GPU runs them one after another.

set -u
mkdir -p logs_h249

COMMON_FLAGS=(
  --num_trials 1
  --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_mu_schedule linear
  --muonh_mu_start 0.95
  --muonh_mu_end 0.90
  --aux_beta2_schedule constant
  --aux_beta2_start 0.99
  --aux_adamw_eps 1e-6
  --muonh_agc_clip_ratio 0.05
  --aux_agc_clip_ratio 0.05
  --muonh_warmup_steps 100
  --body_init orthogonal_fnorm_matched
  --wandb_group H249_riemannian_norm
)

run_arm() {
  local name="$1"
  shift
  local logfile="logs_h249/${name}.log"
  echo "[$(date -Is)] launching ${name}" | tee -a logs_h249/chain.log
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    --wandb_name "g1r3-alphonse/${name}" \
    "$@" > "${logfile}" 2>&1
  local ec=$?
  echo "[$(date -Is)] ${name} exit=${ec}" | tee -a logs_h249/chain.log
  return $ec
}

run_arm h249-arm_a-ctrl
run_arm h249-arm_b-riemannian-default --body_riemannian_norm
run_arm h249-arm_c-riemannian-detached --body_riemannian_norm --body_riem_detach

echo "[$(date -Is)] chain complete" | tee -a logs_h249/chain.log
