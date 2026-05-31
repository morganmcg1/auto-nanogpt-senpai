#!/usr/bin/env bash
# Run all 3 H344 arms sequentially: arm_a (CTRL) → arm_b (LIGHT) → arm_c (MEDIUM).
# Usage: H344_orchestrator.sh
set -u
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
ORCH_LOG="runlogs/h344/orchestrator_${LOG_TS}.log"
mkdir -p runlogs/h344

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H344 ORCH START =====" | tee -a "$ORCH_LOG"

for ARM in a b c; do
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] launching arm_${ARM} =====" | tee -a "$ORCH_LOG"
  bash H344_chain.sh "$ARM"
  RC=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] arm_${ARM} rc=${RC} =====" | tee -a "$ORCH_LOG"
  if [ $RC -ne 0 ]; then
    echo "arm_${ARM} FAILED rc=${RC} — aborting chain" | tee -a "$ORCH_LOG"
    exit $RC
  fi
  sleep 5
done

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H344 ORCH COMPLETE =====" | tee -a "$ORCH_LOG"
