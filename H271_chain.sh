#!/bin/bash
# H271 chain: arm_a CTRL -> arm_b LA_OFF_AT_2300 -> arm_c LA_OFF_AT_2000.
# Runs sequentially on single GPU. Each arm: 3325 steps ~ 100 min.
# Post-H266 baseline (--polyak_ema_decay 0.05 baked into each arm script).
set -e
cd /workspace/senpai/target

LOG_DIR=runlogs
mkdir -p "$LOG_DIR"

ts() { date -u +%Y%m%dT%H%M%SZ; }

echo "[$(ts)] H271 chain starting"

# arm_a
arm_a_ts=$(ts)
echo "[$(ts)] launching arm_a"
bash ./H271_arm_a.sh > "$LOG_DIR/H271_arm_a_${arm_a_ts}.log" 2>&1 && \
  echo "[$(ts)] arm_a OK" || { echo "[$(ts)] arm_a FAILED"; exit 1; }

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
