#!/bin/bash
# H312 chain — MuonH inner momentum Adam-style 1/(1-Π μ_i) bias correction.
# Pattern A drift-FREE sequential chain. Tests INITIALIZATION-phase mechanism
# (first chain on this axis after 100+ steady-state mechanism chains).
#  arm_a CTRL                 — muonh_bias_correction=0, baseline µ schedule (bit-id H266)
#  arm_b BIAS_CORR            — muonh_bias_correction=1, baseline µ schedule
#  arm_c BIAS_CORR_HIGH_MU    — muonh_bias_correction=1, µ schedule shifted +0.02 (0.97→0.92)
set -u

unset WANDB_API_KEY
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
CHAIN_LOG="runlogs/H312_chain_${LOG_TS}.log"
mkdir -p runlogs

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H312_muonh_bias_correction
)

run_arm () {
  local name="$1"; shift
  local arm_log="runlogs/H312_${name}_${LOG_TS}.log"
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} log=${arm_log} =====" | tee -a "$CHAIN_LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-edward/H312_${name}" > "$arm_log" 2>&1
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} =====" | tee -a "$CHAIN_LOG"
  if [ $rc -ne 0 ]; then
    echo "ARM ${name} FAILED rc=${rc} — see ${arm_log}" | tee -a "$CHAIN_LOG"
    return $rc
  fi
  return 0
}

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H312 CHAIN START =====" | tee -a "$CHAIN_LOG"

# arm_a CTRL: baseline µ linear 0.95→0.90, NO bias correction (drift-FREE).
run_arm "bc_arm_a_CTRL" \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --muonh_bias_correction 0 || exit 10
sleep 10

# arm_b BIAS_CORR: baseline µ linear 0.95→0.90, WITH bias correction.
run_arm "bc_arm_b_BIAS_CORR" \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --muonh_bias_correction 1 || exit 11
sleep 10

# arm_c BIAS_CORR_HIGH_MU: µ schedule shifted +0.02 (linear 0.97→0.92), WITH bias correction.
run_arm "bc_arm_c_BIAS_CORR_HIGH_MU" \
  --muonh_mu_schedule linear --muonh_mu_start 0.97 --muonh_mu_end 0.92 \
  --muonh_bias_correction 1 || exit 12

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H312 CHAIN COMPLETE =====" | tee -a "$CHAIN_LOG"
