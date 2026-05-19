#!/usr/bin/env bash
# 4-arm sweep for PR #436 weight EMA (Polyak averaging).
# Holds the merged-stack env vars constant; varies NANOGPT_WEIGHT_EMA_DECAY only.
# Arm A = control (decay=0.0, EMA disabled).
# Arm B = decay=0.999 (~half_life 700)  -> averages last ~30% of training.
# Arm C = decay=0.9999 (~half_life 7000) -> averages essentially full run.
# Arm D = decay=0.99 (~half_life 70)    -> averages last ~3% of training.

set -uo pipefail
cd "$(dirname "$0")"

mkdir -p run_logs/weight_ema
SUMMARY=run_logs/weight_ema/summary.log
NGPU=$(nvidia-smi -L | wc -l)
GROUP="frieren_weight_ema"
TRAIN_SCRIPT=records/track_3_optimization/train_gpt_simple.py

# Merged stack env vars (do NOT change for this PR).
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down

# Guard: weight EMA plumbing must be present.
if ! grep -q "NANOGPT_WEIGHT_EMA_DECAY" "${TRAIN_SCRIPT}"; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ABORT: weight-EMA plumbing missing from ${TRAIN_SCRIPT}" | tee -a "${SUMMARY}"
  exit 11
fi

run_arm() {
  local label="$1"
  local decay="$2"
  local tag="weight-ema-${label}-$(echo "${decay}" | tr '.' 'p')"
  local log="run_logs/weight_ema/${tag}.log"
  echo "--- $(date -u +%Y-%m-%dT%H:%M:%SZ) start ${tag} (HEAD=$(git rev-parse --short HEAD)) ---" | tee -a "${SUMMARY}"
  NANOGPT_WEIGHT_EMA_DECAY="${decay}" \
  NANOGPT_WEIGHT_EMA_WARMUP=100 \
    torchrun --standalone --nproc_per_node="${NGPU}" \
      "${TRAIN_SCRIPT}" \
      --wandb_name "g1r4-frieren/${tag}" \
      --wandb_group "${GROUP}" \
      --wandb_tags "weight-ema,pr-436,arm=${label},decay=${decay}" \
      >>"${log}" 2>&1
  local rc=$?
  echo "--- $(date -u +%Y-%m-%dT%H:%M:%SZ) end   ${tag} rc=${rc} ---" | tee -a "${SUMMARY}"
}

# Sequential arms, single seed each.
run_arm A 0.0
run_arm B 0.999
run_arm C 0.9999
run_arm D 0.99

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] all arms complete" | tee -a "${SUMMARY}"
