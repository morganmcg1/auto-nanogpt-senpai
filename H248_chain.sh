#!/bin/bash
# H248 orchestrator: ARM_A CTRL -> ARM_B POST_NS5_SLOW -> ARM_C POST_NS5_FAST.
# Each arm: ~1.9 h on this GPU. Sequential total: ~5.7 h (budget 8 h).
set -u
cd /workspace/senpai/target

# Workaround: env WANDB_API_KEY observed as 401 in some pods; .netrc key authenticates.
NETRC_WANDB_KEY=$(awk '/machine api.wandb.ai/{getline; getline; print $2}' ~/.netrc 2>/dev/null)
if [ -n "${NETRC_WANDB_KEY:-}" ]; then
  export WANDB_API_KEY="$NETRC_WANDB_KEY"
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG_DIR=runlogs/H248
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

run_arm H248_arm_a_CTRL           H248_arm_a.sh || true
run_arm H248_arm_b_POST_NS5_SLOW  H248_arm_b.sh || true
run_arm H248_arm_c_POST_NS5_FAST  H248_arm_c.sh || true

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) chain done" | tee -a "${LOG_DIR}/chain_${TS}.log"
