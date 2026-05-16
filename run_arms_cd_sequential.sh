#!/usr/bin/env bash
# Sequential launcher for muP LR sweep arms C/D on vanilla Muon (NANOGPT_USE_MUON2=0).
set -u

LOGDIR="${LOGDIR:-/workspace/senpai/target/run_arms_logs}"
mkdir -p "$LOGDIR"

run_arm() {
  local lr="$1"
  local name="$2"
  local log="$LOGDIR/arm-${name}.log"
  echo "[launcher] launching arm-${name} (lr=${lr}, USE_MUON2=0) at $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log"
  NANOGPT_USE_MUON2=0 NANOGPT_MUON_LR="$lr" torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-askeladd/mup-lr-arm-${name}-${lr/./p}-vanilla" \
    --wandb_group "g1r4-askeladd/mup-lr-sweep" >>"$log" 2>&1
  local rc=$?
  echo "[launcher] arm-${name} exited rc=$rc at $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log"
  return $rc
}

run_arm 0.035 c
sleep 20
run_arm 0.042 d

echo "[launcher] arms c/d complete at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
