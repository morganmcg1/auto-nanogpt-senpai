#!/bin/bash
# Sequential 4-arm AGC sweep on single GPU
# A: control (lambda=0, falls through to global clip=10.0)
# B: lambda=0.01 (conservative)
# C: lambda=0.03 (paper default)
# D: lambda=0.10 (loose)
set -uo pipefail

mkdir -p agc_logs

# Shared envs across all arms (post-#290 baseline stack)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_AGC_SCOPE=all
export STUDENT_NAME=g1r4-fern

run_arm() {
  local arm_name="$1"
  local lam="$2"
  local log="agc_logs/${arm_name}.log"
  echo "=== START arm $arm_name lambda=$lam at $(date -u +%H:%M:%S) ==="
  NANOGPT_AGC_LAMBDA="$lam" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r4-fern/${arm_name}" \
      --wandb_group "g1r4-fern/adaptive-grad-clip" \
      > "$log" 2>&1
  echo "=== END   arm $arm_name lambda=$lam at $(date -u +%H:%M:%S) exit=$? ==="
}

run_arm "agc-A-control"  "0.0"
run_arm "agc-B-lam0p01"  "0.01"
run_arm "agc-C-lam0p03"  "0.03"
run_arm "agc-D-lam0p1"   "0.1"

echo "=== ALL ARMS COMPLETE at $(date -u +%H:%M:%S) ==="
