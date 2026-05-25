#!/bin/bash
# Chains the SOAP eps B-E sweep AFTER the prior Cell A torchrun completes.
# Cell A torchrun PID is 295771 (started 19:06 UTC, prior Claude session).
set -uo pipefail
PID_TO_WAIT=${PID_TO_WAIT:-295771}
LOG_DIR="$(dirname "$0")"
echo "=== WAITER START at $(date -Iseconds) waiting for PID ${PID_TO_WAIT} ===" \
  | tee -a "${LOG_DIR}/chain.log"
while kill -0 "${PID_TO_WAIT}" 2>/dev/null; do
    sleep 30
done
echo "=== WAITER: PID ${PID_TO_WAIT} finished at $(date -Iseconds) ===" \
  | tee -a "${LOG_DIR}/chain.log"
sleep 60
echo "=== CHAIN: launching run_all.sh at $(date -Iseconds) ===" \
  | tee -a "${LOG_DIR}/chain.log"
exec bash "${LOG_DIR}/run_all.sh"
