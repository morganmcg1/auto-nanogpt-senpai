#!/usr/bin/env bash
set -eo pipefail

LOGDIR="logs_ns_iters_cooldown"
mkdir -p "$LOGDIR"

# Wait for arm-A (already running) to finish
ARMA_PID=$(cat "$LOGDIR/arm-A.pid")
echo "[$(date -u +%FT%TZ)] Waiting for arm-A pid=$ARMA_PID to finish" | tee -a "$LOGDIR/chain.log"
while kill -0 "$ARMA_PID" 2>/dev/null; do
  sleep 60
done
echo "[$(date -u +%FT%TZ)] arm-A finished" | tee -a "$LOGDIR/chain.log"

# Run remaining arms sequentially
for entry in "B 14 ns-iters-cd-B-14" "C 18 ns-iters-cd-C-18" "D 20 ns-iters-cd-D-20"; do
  read -r ARM NS NAME <<< "$entry"
  echo "[$(date -u +%FT%TZ)] Launching arm-$ARM ns_cooldown=$NS name=$NAME" | tee -a "$LOGDIR/chain.log"
  ./run_ns_iters_cooldown_sweep.sh "$ARM" "$NS" "$NAME"
  echo "[$(date -u +%FT%TZ)] arm-$ARM done" | tee -a "$LOGDIR/chain.log"
done

echo "[$(date -u +%FT%TZ)] All arms complete" | tee -a "$LOGDIR/chain.log"
