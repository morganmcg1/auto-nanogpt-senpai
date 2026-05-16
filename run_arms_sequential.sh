#!/usr/bin/env bash
# Sequential launcher for muP LR sweep arms B/C/D.
# Waits for arm-a PID to exit, then runs each remaining arm one at a time.
set -u

ARM_A_PID="${ARM_A_PID:?must set ARM_A_PID env var}"
LOGDIR="${LOGDIR:-/workspace/senpai/target/run_arms_logs}"
mkdir -p "$LOGDIR"

echo "[launcher] waiting for arm-a PID $ARM_A_PID to exit..."
while kill -0 "$ARM_A_PID" 2>/dev/null; do
  sleep 60
done
echo "[launcher] arm-a PID $ARM_A_PID exited at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
# Brief settle period for GPU memory reclaim before next launch.
sleep 20

run_arm() {
  local lr="$1"
  local name="$2"
  local log="$LOGDIR/arm-${name}.log"
  echo "[launcher] launching arm-${name} (lr=${lr}) at $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log"
  NANOGPT_MUON_LR="$lr" torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-askeladd/mup-lr-arm-${name}-${lr/./p}" \
    --wandb_group "g1r4-askeladd/mup-lr-sweep" >>"$log" 2>&1
  local rc=$?
  echo "[launcher] arm-${name} exited rc=$rc at $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log"
  return $rc
}

run_arm 0.030 b
sleep 20
run_arm 0.035 c
sleep 20
run_arm 0.042 d

echo "[launcher] all arms complete at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
