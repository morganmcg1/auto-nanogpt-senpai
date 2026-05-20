#!/usr/bin/env bash
# PR #568 per-group cooldown_frac chain: waits for the currently-running Arm A
# (pid passed as arg), then launches B → C → D sequentially.
# Each arm logs to logs/per_group_cooldown_frac/arm_<N>.log.
set -uo pipefail

ARM_A_PID=${1:?"Usage: $0 <pid-of-current-armA>"}
cd /workspace/senpai/target
LOGDIR=/workspace/senpai/target/logs/per_group_cooldown_frac
mkdir -p "$LOGDIR"

echo "[$(date -u +%FT%TZ)] chain: waiting for Arm A pid=$ARM_A_PID to finish" \
  >> "$LOGDIR/chain.log"
while kill -0 "$ARM_A_PID" 2>/dev/null; do
  sleep 30
done
echo "[$(date -u +%FT%TZ)] chain: Arm A finished" >> "$LOGDIR/chain.log"

for arm in B C D; do
  echo "[$(date -u +%FT%TZ)] chain: launching Arm $arm" >> "$LOGDIR/chain.log"
  bash /workspace/senpai/target/run_arm.sh "$arm" \
    >"$LOGDIR/arm_${arm}.log" 2>&1
  rc=$?
  echo "[$(date -u +%FT%TZ)] chain: Arm $arm finished rc=$rc" \
    >> "$LOGDIR/chain.log"
  if [[ $rc -ne 0 ]]; then
    echo "[$(date -u +%FT%TZ)] chain: aborting on non-zero rc" \
      >> "$LOGDIR/chain.log"
    exit "$rc"
  fi
done
echo "[$(date -u +%FT%TZ)] chain: all arms complete" >> "$LOGDIR/chain.log"
