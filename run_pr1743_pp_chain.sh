#!/bin/bash
# PR #1743 PP-confirm n=3 paired chain: NM PERIOD_LATE=1 SWITCH_STEP=3000
#
# 6 runs in pair-by-pair seed order (advisor c610 spec):
#   pair-1: PP-ctrl-s0 (PERIOD_LATE=0) -> PP-exp-s0 (PERIOD_LATE=1 SWITCH=3000)
#   pair-2: PP-ctrl-s1 -> PP-exp-s1
#   pair-3: PP-ctrl-s2 -> PP-exp-s2
#
# All 6 runs share the FULL post-#1702 production stack (baseline 3.26118).
# This script differs from run_nm_period_late_chain.sh in two ways:
#   1. Adds NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 K=100 (#1702 production-merge).
#   2. Replaces 3-arm SEED=0 sequential structure with 6-run paired n=3 PP chain.

set -uo pipefail
cd /workspace/senpai/target
mkdir -p run_logs

LOG_DIR=run_logs
GROUP="nm-period-late-pp-confirm-switch3000"

# Full post-#1702 production stack.
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=1e-4
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
# #1702 production-merge: v-warmstart K=100.
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100

export NANOGPT_TRAIN_STEPS=3350

run_pair_arm() {
  local seed="$1"
  local kind="$2"          # ctrl or exp
  local period_late="$3"
  local switch_step="$4"
  local name="g1r4-thorfinn/nm-period-late-pp-${kind}-s${seed}"
  local logfile="${LOG_DIR}/nm_period_late_pp_${kind}_s${seed}.log"

  echo "===== PP-${kind}-s${seed} starting at $(date -u +%FT%TZ): PERIOD_LATE=${period_late} SWITCH=${switch_step} =====" \
    | tee -a "${LOG_DIR}/nm_period_late_pp_chain.log"

  SENPAI_SEED="${seed}" \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD_LATE="${period_late}" \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD_SWITCH_STEP="${switch_step}" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_project modded-nanogpt-senpai \
      --wandb_group "${GROUP}" \
      --wandb_name "${name}" \
    > "${logfile}" 2>&1

  local rc=$?
  echo "===== PP-${kind}-s${seed} finished at $(date -u +%FT%TZ) rc=${rc} =====" \
    | tee -a "${LOG_DIR}/nm_period_late_pp_chain.log"
  return $rc
}

# Pair 1 (seed=0): ctrl -> exp
run_pair_arm 0 ctrl 0 0
run_pair_arm 0 exp 1 3000

# Pair 2 (seed=1): ctrl -> exp
run_pair_arm 1 ctrl 0 0
run_pair_arm 1 exp 1 3000

# Pair 3 (seed=2): ctrl -> exp
run_pair_arm 2 ctrl 0 0
run_pair_arm 2 exp 1 3000

echo "===== CHAIN COMPLETE at $(date -u +%FT%TZ) =====" \
  | tee -a "${LOG_DIR}/nm_period_late_pp_chain.log"
