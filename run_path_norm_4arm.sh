#!/bin/bash
# Path-norm body regularization (PR #933) — 4-arm screening sweep.
# Arm A: lambda=0.0           (control, bit-identical to post-#787 baseline)
# Arm B: lambda=1e-5 window=10 (mild penalty, 10-step velocity window)
# Arm C: lambda=1e-4 window=10 (moderate penalty, same window) — KILL CANDIDATE
# Arm D: lambda=1e-5 window=50 (same lambda as B, longer cumulative window)
# 4 runs total, sequential on 1 GPU. Post-#787 merged stack envs locked.
set -uo pipefail
cd "$(dirname "$0")"

# Post-#787 merged-stack envs, locked across all 4 arms.
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_TRAIN_STEPS=3350

LOG_DIR=logs_path_norm_4arm
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local lambda="$2"
  local window="$3"
  local wname="g1r4-nezuko/path-norm-arm${arm_name}-lambda${lambda}-w${window}"
  local log="$LOG_DIR/arm${arm_name}.log"
  echo "=============================================="
  echo "Arm $arm_name: LAMBDA=$lambda WINDOW=$window | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  NANOGPT_PATH_NORM_LAMBDA="$lambda" \
  NANOGPT_PATH_NORM_WINDOW="$window" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "$wname" \
    --wandb_group "path_norm_body_reg" \
    >> "$log" 2>&1
  local rc=$?
  echo "Arm $arm_name exit code: $rc | $(date -u +%FT%TZ)"
  return $rc
}

CHAIN_LOG="$LOG_DIR/chain.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START path-norm 4-arm chain $(date -u +%FT%TZ) ====="
echo "GPU: $(nvidia-smi -L)"
echo "Branch: $(git branch --show-current)"
echo "Commit: $(git log -1 --oneline)"

run_arm A 0.0 10
run_arm B 1e-5 10
run_arm C 1e-4 10
run_arm D 1e-5 50

echo "===== END path-norm 4-arm chain $(date -u +%FT%TZ) ====="
