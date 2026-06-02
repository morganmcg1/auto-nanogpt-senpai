#!/usr/bin/env bash
# PR #2199 GRAD_CLIP_BODY 3-arm bracket: NANOGPT_GRAD_CLIP_BODY ∈ {10.0 ctrl, 5.0 tighter, 20.0 looser}
#
# Sequential 3-arm chain, full production stack. Same SEED=0 across all arms for paired Δ.
# All other env vars match the c790g production CTRL-cohort.
#
# NOTE: per W&B telemetry of CTRL-cohort anchors ws7mk8ul / 2qoqjwqv, body group L2 norm
# (||g||₂ over 72 Muon-managed attn+mlp matrices) is in 30000-150000 range — the clip
# is ACTIVE every step from step 1 onward. Bracket therefore varies body update SCALE
# by 0.5× / 1× / 2× via clip_scale = clip_threshold / body_group_norm.
#
# Usage: nohup bash launch_pr2199_chain_3arm.sh > logs_pr2199/chain_launcher.log 2>&1 &
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p logs_pr2199

CHAIN_LOG="logs_pr2199/chain.log"
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log_chain() { echo "[$(ts)] $*" | tee -a "$CHAIN_LOG"; }

# Race-window guard per [[chain-handoff-race-window-catalog]]
LOCKFILE="logs_pr2199/chain.lock"
exec 200>"${LOCKFILE}"
if ! flock -n 200; then
  log_chain "FATAL: another chain holds ${LOCKFILE} — aborting to avoid parallel launch"
  exit 1
fi

log_chain "PR#2199 chain_3arm starting (sequential arms A,B,C at GRAD_CLIP_BODY ∈ {10.0, 5.0, 20.0}; SEED=0; AUX clip held at 5.0)"

run_arm() {
  local ARM=$1
  local GCB=$2
  local TAG=$3
  local RUN_NAME="arm-${ARM}-grad-clip-body-${GCB}"
  local LOG="logs_pr2199/arm${ARM}.log"
  local PIDF="logs_pr2199/arm${ARM}.pid"
  log_chain "launching ARM=${ARM} GRAD_CLIP_BODY=${GCB} tag=${TAG} run_name=${RUN_NAME}"

  # Disk-state verification: GRAD_CLIP_BODY plumbing intact
  local GCB_COUNT
  GCB_COUNT=$(grep -c "NANOGPT_GRAD_CLIP_BODY" records/track_3_optimization/train_gpt_simple.py || true)
  log_chain "ARM=${ARM} disk-state NANOGPT_GRAD_CLIP_BODY count=${GCB_COUNT} (expect >=5: env decl + banner + wandb + apply-site + telemetry)"
  if [ "${GCB_COUNT}" -lt 5 ]; then
    log_chain "ARM=${ARM} FATAL: NANOGPT_GRAD_CLIP_BODY missing from train_gpt_simple.py disk state — aborting chain"
    exit 1
  fi

  CUDA_VISIBLE_DEVICES=0 \
  PYTHONUNBUFFERED=1 \
  WANDB_TAGS="${TAG}" \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_GRAD_CLIP_BODY="${GCB}" \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  SENPAI_SEED=0 \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-nezuko/${RUN_NAME}" \
    --wandb_group "nezuko-grad-clip-body-bracket" \
    > "${LOG}" 2>&1 &
  local pid=$!
  echo "${pid}" > "${PIDF}"
  log_chain "ARM=${ARM} PID=${pid} log=${LOG}"
  wait "${pid}"
  local rc=$?
  log_chain "ARM=${ARM} PID=${pid} exited rc=${rc}"
  # Belt-and-braces: ensure GPU released before next arm
  while pgrep -f "records/track_3_optimization/train_gpt_simple.py.*${RUN_NAME}" >/dev/null; do
    log_chain "ARM=${ARM} python still alive, sleeping 20s"
    sleep 20
  done
  log_chain "ARM=${ARM} GPU released"
}

run_arm A 10.0 "arm_A_ctrl"
run_arm B 5.0  "arm_B_tighter"
run_arm C 20.0 "arm_C_looser"

log_chain "PR#2199 chain_3arm complete (all 3 arms done)"
