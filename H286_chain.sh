#!/bin/bash
# H286 chain — Nesterov toggle on MuonH body update (74th class).
# 2-arm Pattern A binary test on post-H266 EMA baseline.
# arm_a CTRL (--muonh_nesterov 1) — Pattern A drift-FREE bit-id baseline (nesterov=True is the default in muon_update)
# arm_b NESTEROV_OFF (--muonh_nesterov 0) — classical heavy-ball, skip the grad lookahead lerp pre-NS5
set -u

unset WANDB_API_KEY
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
CHAIN_LOG="runlogs/H286_chain_${LOG_TS}.log"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H286_muonh_nesterov
)

run_arm () {
  local name="$1"; shift
  local arm_log="runlogs/H286_${name}_${LOG_TS}.log"
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} log=${arm_log} =====" | tee -a "$CHAIN_LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-edward/H286_${name}" > "$arm_log" 2>&1
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} =====" | tee -a "$CHAIN_LOG"
  if [ $rc -ne 0 ]; then
    echo "ARM ${name} FAILED rc=${rc} — see ${arm_log}" | tee -a "$CHAIN_LOG"
    return $rc
  fi
  return 0
}

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H286 CHAIN START =====" | tee -a "$CHAIN_LOG"

run_arm "arm_a_CTRL_NESTEROV_ON" --muonh_nesterov 1 || exit 10
sleep 10
run_arm "arm_b_NESTEROV_OFF" --muonh_nesterov 0 || exit 11

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H286 CHAIN COMPLETE =====" | tee -a "$CHAIN_LOG"
