#!/bin/bash
# H180 multi-seed CONFIRMATION of H162 round-1 arm_b
# 3 sequential --num_trials 1 runs, identical config, independent random init.
# Config: calib=200, exp=0.5, recal=0 (the H162 round-1 arm_b that produced
# val/loss=3.262617, FFS=3125 single-trial).
# Each trial ~1.65-2h, total ~5-6h.
set -u

cd "$(dirname "$0")"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape linear --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --muonh_per_block_lr_exponent 0.5
  --muonh_per_block_calibration_step 200
  --muonh_per_block_recalibrate_interval 0
  --wandb_group g1r3-thorfinn-h180-per-block-lr-multiseed-confirm
)

run_trial () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} ====="
  echo "----- CLI invocation (verbatim) -----"
  printf 'torchrun --standalone --nproc_per_node=1 \\\n  records/track_3_optimization/train_gpt_simple.py'
  for a in "${COMMON_ARGS[@]}" "$@" --wandb_name "g1r3-thorfinn/${name}"; do
    printf ' \\\n    %q' "$a"
  done
  echo
  echo "-------------------------------------"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-thorfinn/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} ====="
  return $rc
}

# H180 3 trials — identical config, different random init from process state.
run_trial "h180-trial-0"

sleep 30

run_trial "h180-trial-1"

sleep 30

run_trial "h180-trial-2"

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H180 CHAIN COMPLETE ====="
