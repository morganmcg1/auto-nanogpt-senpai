#!/bin/bash
# PR #2087 — NM R-buffer EMA decay β bracket {0.90 FASTER, 0.95 ctrl, 0.99 SLOWER}
# 3 arms sequential A->C, single trial SENPAI_SEED=0, single GPU.
#   A: ctrl β=0.95  (1/(1-β)=~20-step EMA memory window, production)
#   B: FASTER β=0.90  (~10-step memory; more reactive to recent gradient noise)
#   C: SLOWER β=0.99  (~100-step memory; smoother eigendecomp trajectory)
# Production stack identical across arms (matches PR #2039/#1843-style baseline).
# Baseline (PR #1702 n=3 ctrl): val/loss μ=3.26118, FFS mean 3133.33.
set -u
LOG_DIR="_logs/pr2087"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local beta="$2"
  local tags="$3"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (BETA=$beta) logfile=$logfile"
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_POWER=0.5 \
  NANOGPT_NEWTON_MUON_EPS=0.0001 \
  NANOGPT_NEWTON_MUON_BETA="$beta" \
  SENPAI_SEED=0 \
  WANDB_TAGS="$tags" \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "nm-r-buffer-ema-beta-bracket" \
    --wandb_name "g1r4-edward/${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #2087 NM R-buffer EMA β bracket chain starting"
run_arm armA-ctrl-beta0p95   0.95 "arm_A_ctrl"
run_arm armB-beta0p90        0.90 "arm_B_beta090_faster"
run_arm armC-beta0p99        0.99 "arm_C_beta099_slower"
echo "[$(date -Iseconds)] PR #2087 chain complete"
