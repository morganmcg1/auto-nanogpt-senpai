#!/usr/bin/env bash
# PR #2143 NS_COOLDOWN_START_FRAC TIMING-axis bracket: 3 sequential arms
#
# Each arm launches its own torchrun process to completion before the next.
# All arms share the production stack; only NANOGPT_NS_COOLDOWN_START_FRAC varies.
#
# Arm A: START_FRAC=0.7  (ctrl / production; cooldown_start=step 2345/3350)
# Arm B: START_FRAC=0.5  (cooldown_start=step 1675/3350; +6.06% total NS work)
# Arm C: START_FRAC=0.85 (cooldown_start=step 2847/3350; -4.54% total NS work)
#
# All 3 arms share SEED=0 to isolate START_FRAC effect from seed variance.
#
# Logs go to logs_pr2143/arm{A,B,C}.log; PIDs to logs_pr2143/arm{A,B,C}.pid.
# Chain progress to logs_pr2143/chain.log.
#
# Usage: nohup bash run_pr_ns_cd_start_frac_chain.sh > logs_pr2143/chain_launcher.log 2>&1 &
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p logs_pr2143

CHAIN_LOG="logs_pr2143/chain.log"
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log_chain() { echo "[$(ts)] $*" | tee -a "$CHAIN_LOG"; }

# Parallel-launch race-window guard (per c787 #2022 askeladd resolved incident):
# atomic lockfile pattern. flock the chain.lock; abort if already held.
LOCKFILE="logs_pr2143/chain.lock"
exec 9>"${LOCKFILE}"
if ! flock -n 9; then
  log_chain "FATAL: another chain holds ${LOCKFILE} -- aborting to avoid parallel launch"
  exit 1
fi

log_chain "chain_3arm starting (sequential arms A,B,C at NS_COOLDOWN_START_FRAC in {0.7, 0.5, 0.85}; SEED=0)"

run_arm() {
  local ARM=$1
  local START_FRAC=$2
  local TAG=$3
  local RUN_NAME="arm-${ARM}-cdstart${START_FRAC}"
  local LOG="logs_pr2143/arm${ARM}.log"
  local PIDF="logs_pr2143/arm${ARM}.pid"
  log_chain "launching ARM=${ARM} START_FRAC=${START_FRAC} tag=${TAG} run_name=${RUN_NAME}"

  # Per-arm disk-state verification: NS_COOLDOWN_START_FRAC wired into script.
  # Expect >=5 occurrences: env decl + banner + wandb config + cooldown_start_step + get_ns_iters call.
  local FRAC_COUNT
  FRAC_COUNT=$(grep -c "NS_COOLDOWN_START_FRAC" records/track_3_optimization/train_gpt_simple.py || true)
  log_chain "ARM=${ARM} disk-state NS_COOLDOWN_START_FRAC count=${FRAC_COUNT} (expect >=5)"
  if [ "${FRAC_COUNT}" -lt 5 ]; then
    log_chain "ARM=${ARM} FATAL: NS_COOLDOWN_START_FRAC missing from train_gpt_simple.py disk state -- aborting chain"
    exit 1
  fi

  CUDA_VISIBLE_DEVICES=0 \
  PYTHONUNBUFFERED=1 \
  WANDB_TAGS="${TAG}" \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_EPS=0.0001 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_POWER=0.5 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC="${START_FRAC}" \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  SENPAI_SEED=0 \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-nezuko/${RUN_NAME}" \
    --wandb_group "nm-ns-cooldown-start-frac-bracket" \
    > "${LOG}" 2>&1 &
  local pid=$!
  echo "${pid}" > "${PIDF}"
  log_chain "ARM=${ARM} PID=${pid} log=${LOG}"
  wait "${pid}"
  local rc=$?
  log_chain "ARM=${ARM} PID=${pid} exited rc=${rc}"
  # Belt-and-braces: ensure any straggler python process has released the GPU.
  while pgrep -f "records/track_3_optimization/train_gpt_simple.py.*${RUN_NAME}" >/dev/null; do
    log_chain "ARM=${ARM} python still alive, sleeping 20s"
    sleep 20
  done
  log_chain "ARM=${ARM} GPU released"
}

run_arm A 0.7  "arm_A_ctrl"
run_arm B 0.5  "arm_B_early"
run_arm C 0.85 "arm_C_late"

log_chain "chain_3arm complete (all 3 arms done)"
