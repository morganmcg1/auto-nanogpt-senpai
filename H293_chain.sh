#!/bin/bash
# H293_chain.sh — outer_lr VALUE test (81st class).
# 3-arm Pattern A drift-FREE on post-H266 EMA baseline.
set -u
unset WANDB_API_KEY
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
CHAIN_LOG="runlogs/H293_chain_${LOG_TS}.log"
echo "H293 chain start: $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee "$CHAIN_LOG"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H293_outer_lr_value
)

run_arm () {
  local name="$1"; shift
  local arm_log="runlogs/H293_${name}_${LOG_TS}.log"
  echo "  arm start name=${name} t=$(date -u +%H:%M:%SZ) log=${arm_log}" | tee -a "$CHAIN_LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-edward/H293_${name}" > "$arm_log" 2>&1
  local rc=$?
  echo "  arm end   name=${name} t=$(date -u +%H:%M:%SZ) exit=${rc}" | tee -a "$CHAIN_LOG"
  return $rc
}

run_arm "arm_a_CTRL_outer_lr_0p7"  --outer_lr 0.7 || { echo "arm_a FAILED"; exit 10; }
sleep 10
run_arm "arm_b_LOWER_outer_lr_0p5" --outer_lr 0.5 || { echo "arm_b FAILED"; exit 11; }
sleep 10
run_arm "arm_c_HIGHER_outer_lr_0p9" --outer_lr 0.9 || { echo "arm_c FAILED"; exit 12; }

echo "H293 chain end: $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$CHAIN_LOG"
