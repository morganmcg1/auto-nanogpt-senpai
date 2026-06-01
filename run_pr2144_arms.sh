#!/bin/bash
# PR #2144 — NS_COOLDOWN_SHAPE 3-arm bracket
#   Arm A: late_peak (production ctrl)
#   Arm B: two_stage (piecewise 2-stage transition)
#   Arm C: linear_ramp (gradual linear interpolation)
# Single-GPU sequential chain. Uses untracked _pr2144_train_gpt_simple.py copy
# + flock guard to avoid entrypoint-branch-flip race and double-launch.
set -u
CHAIN_LOG=/workspace/senpai/target/logs_pr2144_arms_chain.log
LOG_DIR=/workspace/senpai/target/logs_pr2144_arms
TRAIN_SCRIPT=/workspace/senpai/target/_pr2144_train_gpt_simple.py
LOCK_FILE=/workspace/senpai/target/logs_pr2144_arms_chain.lock

mkdir -p "${LOG_DIR}"
cd /workspace/senpai/target

stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

run_arm() {
  local ARM_NAME=$1
  local SHAPE_VAL=$2
  local WANDB_NAME=$3
  local WANDB_TAGS=$4
  local LOG_FILE=$5

  echo "===== ARM ${ARM_NAME}: NS_COOLDOWN_SHAPE=${SHAPE_VAL} =====" | tee -a "$CHAIN_LOG"
  echo "Start: $(stamp)" | tee -a "$CHAIN_LOG"

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
  NANOGPT_NS_COOLDOWN_SHAPE="${SHAPE_VAL}" \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  SENPAI_SEED=0 \
  WANDB_TAGS="${WANDB_TAGS}" \
  torchrun --standalone --nproc_per_node=1 \
    "${TRAIN_SCRIPT}" \
    --num_trials=1 \
    --wandb_project=modded-nanogpt-senpai \
    --wandb_group="nm-ns-cooldown-shape-bracket" \
    --wandb_name="${WANDB_NAME}" \
    > "${LOG_FILE}" 2>&1
  local rc=$?
  echo "End:   $(stamp) rc=${rc}" | tee -a "$CHAIN_LOG"
  return $rc
}

# flock: only one chain instance may run at a time (PR-body requirement).
exec 200>"${LOCK_FILE}"
if ! flock -n 200; then
  echo "ERROR: chain already running (lock held on ${LOCK_FILE})" | tee -a "$CHAIN_LOG"
  exit 1
fi

echo "===== PR #2144 NS_COOLDOWN_SHAPE CHAIN START =====" | tee -a "$CHAIN_LOG"
echo "Start: $(stamp) pid=$$" | tee -a "$CHAIN_LOG"

run_arm A late_peak   "g1r4-frieren/arm-A-latepeak"   "arm_A_latepeak,pr2144"   "${LOG_DIR}/arm_A.log" \
  && run_arm B two_stage   "g1r4-frieren/arm-B-twostage"   "arm_B_twostage,pr2144"   "${LOG_DIR}/arm_B.log" \
  && run_arm C linear_ramp "g1r4-frieren/arm-C-linearramp" "arm_C_linearramp,pr2144" "${LOG_DIR}/arm_C.log"

echo "===== CHAIN COMPLETE =====" | tee -a "$CHAIN_LOG"
echo "End:   $(stamp)" | tee -a "$CHAIN_LOG"
