#!/bin/bash
# H271 chain: arm_a CTRL -> arm_b LA_OFF_AT_2300 -> arm_c LA_OFF_AT_2000.
# Runs sequentially on single GPU. Each arm: 3325 steps ~ 100 min.
set -e
cd /workspace/senpai/target

LOG_DIR=runlogs
mkdir -p "$LOG_DIR"

ts() { date -u +%Y%m%dT%H%M%SZ; }

echo "[$(ts)] H271 chain starting"

# arm_a already launched separately — wait for arm_a pid file.
if [ -f /tmp/H271_arm_a.pid ]; then
  arm_a_pid=$(cat /tmp/H271_arm_a.pid)
  echo "[$(ts)] waiting for arm_a pid $arm_a_pid"
  while kill -0 "$arm_a_pid" 2>/dev/null; do sleep 30; done
  echo "[$(ts)] arm_a pid $arm_a_pid exited"
else
  echo "[$(ts)] no arm_a pid file; launching arm_a"
  arm_a_ts=$(ts)
  bash ./H271_arm_a.sh > "$LOG_DIR/H271_arm_a_${arm_a_ts}.log" 2>&1
fi

# arm_b
arm_b_ts=$(ts)
echo "[$(ts)] launching arm_b"
bash ./H271_arm_b.sh > "$LOG_DIR/H271_arm_b_${arm_b_ts}.log" 2>&1 && \
  echo "[$(ts)] arm_b OK" || echo "[$(ts)] arm_b FAILED"

# arm_c
arm_c_ts=$(ts)
echo "[$(ts)] launching arm_c"
bash ./H271_arm_c.sh > "$LOG_DIR/H271_arm_c_${arm_c_ts}.log" 2>&1 && \
  echo "[$(ts)] arm_c OK" || echo "[$(ts)] arm_c FAILED"

echo "[$(ts)] H271 chain done"
