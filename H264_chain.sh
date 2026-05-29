#!/bin/bash
# H264 chain: wait for arm_a (PID $ARMA_PID) to finish, then sequentially run arm_b then arm_c.
# Each arm writes its own .log and .pid in runlogs/.
set -u
cd /workspace/senpai/target
mkdir -p runlogs

ARMA_PID="${ARMA_PID:-848410}"

stamp() { date -u +%Y%m%dT%H%M%SZ; }
log() { echo "[$(stamp)] $*"; }

# Wait for arm_a to exit
log "Waiting for arm_a PID $ARMA_PID to exit..."
while kill -0 "$ARMA_PID" 2>/dev/null; do
  sleep 30
done
log "arm_a PID $ARMA_PID has exited"

# Launch arm_b
log "Launching arm_b..."
nohup bash ./H264_arm_b.sh > runlogs/H264_arm_b.log 2>&1 &
ARMB_PID=$!
echo "$ARMB_PID" > runlogs/H264_arm_b.pid
log "arm_b launched with PID $ARMB_PID"

# Wait for arm_b
while kill -0 "$ARMB_PID" 2>/dev/null; do
  sleep 30
done
log "arm_b PID $ARMB_PID has exited"

# Launch arm_c
log "Launching arm_c..."
nohup bash ./H264_arm_c.sh > runlogs/H264_arm_c.log 2>&1 &
ARMC_PID=$!
echo "$ARMC_PID" > runlogs/H264_arm_c.pid
log "arm_c launched with PID $ARMC_PID"

# Wait for arm_c
while kill -0 "$ARMC_PID" 2>/dev/null; do
  sleep 30
done
log "arm_c PID $ARMC_PID has exited"
log "H264 chain complete"
