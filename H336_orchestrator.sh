#!/usr/bin/env bash
# Wait for currently-running arm_a (PID stored in arg), then launch arm_b, then arm_c sequentially.
# Usage: H336_orchestrator.sh <arm_a_pid>
set -u
ARM_A_PID="${1:?arm_a PID required}"
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
ORCH_LOG="runlogs/h336/orchestrator_${LOG_TS}.log"
mkdir -p runlogs/h336

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H336 ORCH START waiting on arm_a PID=${ARM_A_PID} =====" | tee -a "$ORCH_LOG"

while kill -0 "$ARM_A_PID" 2>/dev/null; do sleep 30; done
echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] arm_a finished, launching arm_b =====" | tee -a "$ORCH_LOG"

bash H336_chain.sh b
RC_B=$?
echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] arm_b rc=${RC_B} =====" | tee -a "$ORCH_LOG"
if [ $RC_B -ne 0 ]; then
  echo "arm_b FAILED rc=${RC_B}" | tee -a "$ORCH_LOG"
  exit $RC_B
fi

sleep 10

bash H336_chain.sh c
RC_C=$?
echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] arm_c rc=${RC_C} =====" | tee -a "$ORCH_LOG"
if [ $RC_C -ne 0 ]; then
  echo "arm_c FAILED rc=${RC_C}" | tee -a "$ORCH_LOG"
  exit $RC_C
fi

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H336 ORCH COMPLETE =====" | tee -a "$ORCH_LOG"
