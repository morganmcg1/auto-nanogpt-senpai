#!/usr/bin/env bash
# H345 sequential chain: arm_a CTRL → arm_b BODY_ONLY → arm_c AUX_ONLY.
set -u
WORKDIR=/workspace/senpai/target
LOGDIR="$WORKDIR/logs_h345"
CHAIN_LOG="$LOGDIR/chain.log"

log() { echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') $*" >>"$CHAIN_LOG"; }

# --- arm_a CTRL (polyak_ema_scope=all, H266 bit-id) ---
log "=== H345 arm_a CTRL START ==="
bash "$WORKDIR/scripts/h345_launch_arm_a.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_A_PID=$(cat "$LOGDIR/arm_a_CTRL.pid" 2>/dev/null | head -1)
log "arm_a pid=$ARM_A_PID"
while [ -n "$ARM_A_PID" ] && kill -0 "$ARM_A_PID" 2>/dev/null; do
    sleep 60
done
log "=== H345 arm_a CTRL END ==="

# --- arm_b BODY_ONLY (polyak_ema_scope=body) ---
log "=== H345 arm_b BODY_ONLY START ==="
bash "$WORKDIR/scripts/h345_launch_arm_b.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_B_PID=$(cat "$LOGDIR/arm_b_BODY_ONLY.pid" 2>/dev/null | head -1)
log "arm_b pid=$ARM_B_PID"
while [ -n "$ARM_B_PID" ] && kill -0 "$ARM_B_PID" 2>/dev/null; do
    sleep 60
done
log "=== H345 arm_b BODY_ONLY END ==="

# --- arm_c AUX_ONLY (polyak_ema_scope=aux) ---
log "=== H345 arm_c AUX_ONLY START ==="
bash "$WORKDIR/scripts/h345_launch_arm_c.sh" >>"$CHAIN_LOG" 2>&1
sleep 8
ARM_C_PID=$(cat "$LOGDIR/arm_c_AUX_ONLY.pid" 2>/dev/null | head -1)
log "arm_c pid=$ARM_C_PID"
while [ -n "$ARM_C_PID" ] && kill -0 "$ARM_C_PID" 2>/dev/null; do
    sleep 60
done
log "=== H345 arm_c AUX_ONLY END ==="

log "=== H345 CHAIN COMPLETE ==="
