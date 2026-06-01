#!/bin/bash
# PR #1883 PP-confirm n=3 paired-pod chain.
# Chain order A0 -> B0 -> A1 -> B1 -> A2 -> B2 (paired-by-seed, advisor c758).
# Each run ~150min, total ~15h.
set -e
LOGFILE="run_logs/pp_chain.log"
cd /workspace/senpai/target
mkdir -p run_logs

echo "PP-confirm chain start $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOGFILE"

run_arm() {
  local tag="$1" seed="$2" kind="$3" wname="$4"
  echo "Launching $tag (seed=$seed kind=$kind) at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
  bash run_pp_arm.sh "$tag" "$seed" "$kind" "$wname" >> "$LOGFILE" 2>&1
  local pid
  pid=$(cat "run_logs/pp_${tag}.pid")
  echo "$tag launched PID=$pid" >> "$LOGFILE"
  while kill -0 "$pid" 2>/dev/null; do sleep 60; done
  echo "$tag finished at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
}

run_arm A0 0 ctrl "g1r4-thorfinn/A0-ctrl-pp-confirm"
run_arm B0 0 exp  "g1r4-thorfinn/B0-burst2400-3000-pp-confirm"
run_arm A1 1 ctrl "g1r4-thorfinn/A1-ctrl-pp-confirm"
run_arm B1 1 exp  "g1r4-thorfinn/B1-burst2400-3000-pp-confirm"
run_arm A2 2 ctrl "g1r4-thorfinn/A2-ctrl-pp-confirm"
run_arm B2 2 exp  "g1r4-thorfinn/B2-burst2400-3000-pp-confirm"

echo "PP-confirm chain end $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
