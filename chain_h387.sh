#!/usr/bin/env bash
set -uo pipefail
cd /workspace/senpai/target
mkdir -p chain_h387_logs

run_arm () {
  local NAME="$1"
  local PERIOD="$2"
  local DECAY="$3"
  local LOG="chain_h387_logs/${NAME}.log"
  echo "=== START $(date -u +%FT%TZ) :: ${NAME} (period=${PERIOD}, decay=${DECAY}, steps=3325)" | tee -a chain_h387.log
  torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 --train_steps 3325 \
      --muonh_mode scale_invariant --muonh_cooldown_shape cosine \
      --muonh_warmup_steps 100 \
      --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
      --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
      --aux_adamw_eps 1e-6 \
      --aux_beta2_schedule constant --aux_beta2_start 0.99 \
      --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
      --body_init orthogonal_fnorm_matched \
      --polyak_ema_decay 0.05 \
      --outer_restart_period "${PERIOD}" --outer_restart_decay "${DECAY}" \
      --wandb_project modded-nanogpt-senpai \
      --wandb_group "g1r3-h387-outer-sgdr-warm-restarts" \
      --wandb_name "g1r3-fern/${NAME}" \
    >"${LOG}" 2>&1
  rc=$?
  echo "=== END   $(date -u +%FT%TZ) :: ${NAME} rc=${rc}" | tee -a chain_h387.log
  return $rc
}

run_arm h387-outer-sgdr-warm-restarts-arm_a-ctrl     0    0.0
run_arm h387-outer-sgdr-warm-restarts-arm_b-sgdr-500 500  0.0
run_arm h387-outer-sgdr-warm-restarts-arm_c-sgdr-1000 1000 0.0
echo "=== ALL DONE $(date -u +%FT%TZ)" | tee -a chain_h387.log
