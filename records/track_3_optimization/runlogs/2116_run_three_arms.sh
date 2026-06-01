#!/usr/bin/env bash
# PR #2116 — NM_TIKHONOV_GAMMA fine bracket. Runs 3 arms sequentially on 1 GPU:
#   Arm A: NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005  (production CTRL reference)
#   Arm B: NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.001  (5x DOWN, less regularization)
#   Arm C: NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.025  (5x UP, more regularization)
# All other env vars match the post-#1702 production stack.

set -e
cd "$(dirname "$0")/../../.."

run_one() {
  local arm_letter="$1" gamma="$2" tag="$3"
  local stamp="$(date +%Y%m%d_%H%M%S)"
  local log="records/track_3_optimization/runlogs/2116_arm${arm_letter}_${stamp}.log"
  echo "===== [$(date -u +%FT%TZ)] Launching arm ${arm_letter} (TIKHONOV_GAMMA=${gamma}) → ${log}" | tee -a records/track_3_optimization/runlogs/2116_wrapper.log
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA="${gamma}" \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  SENPAI_SEED=0 \
  WANDB_TAGS="${tag}" \
  STUDENT_NAME=g1r4-tanjiro \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-tanjiro/2116-arm${arm_letter}-gamma${gamma}-s0" \
    --wandb_group "g1r4-tanjiro-tikhonov-gamma-bracket" \
    >"${log}" 2>&1
  local rc=$?
  echo "===== [$(date -u +%FT%TZ)] Arm ${arm_letter} (gamma=${gamma}) exit=${rc}" | tee -a records/track_3_optimization/runlogs/2116_wrapper.log
  return $rc
}

run_one A 0.005 arm_A_ctrl
run_one B 0.001 arm_B_down
run_one C 0.025 arm_C_up
echo "===== [$(date -u +%FT%TZ)] All 3 arms complete." | tee -a records/track_3_optimization/runlogs/2116_wrapper.log
