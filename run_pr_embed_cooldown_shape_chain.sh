#!/bin/bash
# PR #2149 EMBED_COOLDOWN_SHAPE 3-arm sequential chain:
#   Arm A (ctrl, linear_floor) -> Arm B (linear) -> Arm C (cosine)
# Flock-guarded so only one chain instance runs at a time (chain-handoff-race-window).
set -e

LOCKFILE="run_logs/pr2149_chain.lock"
LOGFILE="run_logs/pr2149_chain.log"
cd /workspace/senpai/target
mkdir -p run_logs

exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo "Another PR2149 chain is already running; exiting."
  exit 0
fi

echo "Chain start $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOGFILE"

run_arm() {
  local tag="$1"      # armA / armB / armC
  local shape="$2"
  local wandb_name="$3"
  echo "Launching ${tag} (${shape}) at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
  bash run_pr2149_arm.sh "$tag" "$shape" "$wandb_name" >> "$LOGFILE" 2>&1
  local pid
  pid=$(cat "run_logs/pr2149_${tag}.pid")
  echo "${tag} launched PID=${pid}" >> "$LOGFILE"
  while kill -0 "$pid" 2>/dev/null; do sleep 60; done
  echo "${tag} finished at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
}

# Arm A (ctrl, linear_floor)
run_arm armA linear_floor "g1r4-thorfinn/arm-A-linearfloor"

# Arm B (linear)
run_arm armB linear "g1r4-thorfinn/arm-B-linear"

# Arm C (cosine)
run_arm armC cosine "g1r4-thorfinn/arm-C-cosine"

echo "Chain end $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
