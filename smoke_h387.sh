#!/usr/bin/env bash
set -uo pipefail
cd /workspace/senpai/target
mkdir -p smoke_h387_logs

run_smoke () {
  local NAME="$1"
  local PERIOD="$2"
  local DECAY="$3"
  local STEPS="$4"
  local LOG="smoke_h387_logs/${NAME}.log"
  echo "=== START $(date -u +%FT%TZ) :: ${NAME} (period=${PERIOD}, decay=${DECAY}, steps=${STEPS})" | tee -a smoke_h387.log
  torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 --train_steps "${STEPS}" \
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
      --wandb_group "g1r3-h387-outer-sgdr-warm-restarts-smoke" \
      --wandb_name "g1r3-fern/${NAME}" \
    >"${LOG}" 2>&1
  rc=$?
  echo "=== END   $(date -u +%FT%TZ) :: ${NAME} rc=${rc}" | tee -a smoke_h387.log
  return $rc
}

# arm_a CTRL: period=0 → bit-id, must show step-0 val=10.82583
run_smoke smoke_h387_arm_a_CTRL 0 0.0 525
# arm_b SGDR_500: period=500, expect restart at train_step=510 (sync_interval=30 granularity)
run_smoke smoke_h387_arm_b_SGDR_500 500 0.0 525
# arm_c SGDR_1000: period=1000, no restart in 525 steps but verify bit-id pre-restart + path is wired
run_smoke smoke_h387_arm_c_SGDR_1000 1000 0.0 525
echo "=== ALL DONE $(date -u +%FT%TZ)" | tee -a smoke_h387.log
