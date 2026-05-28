#!/bin/bash
# H256 orchestrator: arm_a CTRL (constant) -> arm_b COOLDOWN_MATCHED -> arm_c WARMUP_THEN_CONST
# Each arm: ~110 min on 1xH100. Sequential total: ~5.5 h.
set -u
cd /workspace/senpai/target

# Workaround mirror of H241: prefer .netrc wandb key if available.
NETRC_WANDB_KEY=$(awk '/machine api.wandb.ai/{getline; getline; print $2}' ~/.netrc 2>/dev/null)
if [ -n "${NETRC_WANDB_KEY:-}" ]; then
  export WANDB_API_KEY="$NETRC_WANDB_KEY"
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG_DIR=runlogs/H256
mkdir -p "$LOG_DIR"

run_arm () {
  local name="$1"
  local script="$2"
  local log="${LOG_DIR}/${name}_${TS}.log"
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) start ${name} -> ${log}" | tee -a "${LOG_DIR}/chain_${TS}.log"
  bash "$script" >>"$log" 2>&1
  local rc=$?
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) finish ${name} rc=${rc}" | tee -a "${LOG_DIR}/chain_${TS}.log"
  return $rc
}

run_arm H256_arm_a_CTRL              H256_arm_a.sh || true
run_arm H256_arm_b_COOLDOWN_MATCHED  H256_arm_b.sh || true
run_arm H256_arm_c_WARMUP            H256_arm_c.sh || true

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) chain done" | tee -a "${LOG_DIR}/chain_${TS}.log"
