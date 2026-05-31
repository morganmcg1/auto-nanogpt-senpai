#!/usr/bin/env bash
# H337 sequential chain: arm_a CTRL (0.5) → arm_b LOW (0.3) → arm_c HIGH (0.7)
set -u
WORKDIR=/workspace/senpai/target
LOGDIR="$WORKDIR/logs_h337"
CHAIN_LOG="$LOGDIR/chain.log"

log() { echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') $*" >>"$CHAIN_LOG"; }

# --- arm_a CTRL (β=0.5) ---
log "=== H337 arm_a CTRL START ==="
bash "$WORKDIR/scripts/h337_launch_arm_a.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_A_PID=$(cat "$LOGDIR/arm_a_CTRL.pid" 2>/dev/null | head -1)
log "arm_a pid=$ARM_A_PID"
while [ -n "$ARM_A_PID" ] && kill -0 "$ARM_A_PID" 2>/dev/null; do
    sleep 60
done
log "=== H337 arm_a CTRL END ==="

# --- arm_b LOW (β=0.3) ---
log "=== H337 arm_b LOW START ==="
bash "$WORKDIR/scripts/h337_launch_arm_b.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_B_PID=$(cat "$LOGDIR/arm_b_LOW.pid" 2>/dev/null | head -1)
log "arm_b pid=$ARM_B_PID"
while [ -n "$ARM_B_PID" ] && kill -0 "$ARM_B_PID" 2>/dev/null; do
    sleep 60
done
log "=== H337 arm_b LOW END ==="

# --- arm_c HIGH (β=0.7) ---
log "=== H337 arm_c HIGH START ==="
bash "$WORKDIR/scripts/h337_launch_arm_c.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_C_PID=$(cat "$LOGDIR/arm_c_HIGH.pid" 2>/dev/null | head -1)
log "arm_c pid=$ARM_C_PID"
while [ -n "$ARM_C_PID" ] && kill -0 "$ARM_C_PID" 2>/dev/null; do
    sleep 60
done
log "=== H337 arm_c HIGH END ==="

log "=== H337 CHAIN COMPLETE ==="
