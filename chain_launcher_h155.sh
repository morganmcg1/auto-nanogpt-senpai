#!/bin/bash
# H155 askeladd MGUP-MuonH 3-arm sequential chain (1xGPU)
# arm_a = CTRL (use_mgup=0), arm_b = MGUP_50_MODERATE, arm_c = MGUP_25_AGGRESSIVE
set -u
cd "$(dirname "$0")"

LOGDIR=logs
mkdir -p "$LOGDIR"

COMMON_FLAGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape linear
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
)

GROUP="g1r3-askeladd-h155-mgup-muonh"

run_arm() {
  local arm_label="$1"; shift
  local logfile="$LOGDIR/h155_${arm_label}.log"
  echo "=========================================="
  echo "[H155 chain] $(date -u +%FT%TZ) START arm=$arm_label"
  echo "=========================================="
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    "$@" \
    --wandb_group "$GROUP" \
    > "$logfile" 2>&1
  local ec=$?
  echo "[H155 chain] $(date -u +%FT%TZ) END arm=$arm_label exit=$ec"
  if [[ $ec -ne 0 ]]; then
    echo "[H155 chain] arm=$arm_label FAILED — aborting chain"
    return $ec
  fi
}

run_arm "arm_a_ctrl" \
  --use_mgup 0 \
  --wandb_name "g1r3-askeladd/h155-arm_a-ctrl" \
  || exit 1

run_arm "arm_b_mgup_50_moderate" \
  --use_mgup 1 --mgup_k 0.5 --mgup_alpha 0.5 --mgup_beta 0.5 \
  --wandb_name "g1r3-askeladd/h155-arm_b-mgup-50-moderate" \
  || exit 1

run_arm "arm_c_mgup_25_aggressive" \
  --use_mgup 1 --mgup_k 0.25 --mgup_alpha 1.0 --mgup_beta 0.75 \
  --wandb_name "g1r3-askeladd/h155-arm_c-mgup-25-aggressive" \
  || exit 1

echo "[H155 chain] $(date -u +%FT%TZ) ALL ARMS COMPLETE"
