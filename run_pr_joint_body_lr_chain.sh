#!/bin/bash
# PR #2141 — Joint body-LR DOWN composite: ATTN_LR_MULT × MLP_LR_MULT additivity test
# 2 arms sequential A->B, single-trial SENPAI_SEED=0, single GPU.
#   A: ctrl              -> ATTN_LR_MULT=0.80 MLP_LR_MULT=1.20 (production stack)
#   B: composite-DOWN    -> ATTN_LR_MULT=0.65 MLP_LR_MULT=1.05 (joint bracket-DOWN)
# Tests 3-axis CROSS-AXIS additivity of precond-ratio-LR-compensation mechanism.
# Production stack identical across arms apart from the two LR-mult knobs.
# Baseline (PR #1702 n=3 ctrl): val/loss μ=3.26118, FFS μ=3133.33, σ_seed=0.00161.
# flock guard at fd=200 prevents concurrent re-launch (chain-script dedup discipline).
set -u
LOCK_FILE="/tmp/run_pr_joint_body_lr_chain.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  echo "[$(date -Iseconds)] another chain instance already holds $LOCK_FILE — exiting"
  exit 1
fi

LOG_DIR="_logs/pr_joint_body_lr"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local attn_mult="$2"
  local mlp_mult="$3"
  local tags="$4"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (ATTN_LR_MULT=$attn_mult MLP_LR_MULT=$mlp_mult) logfile=$logfile"
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_MUON_ATTN_LR_MULT="$attn_mult" NANOGPT_MUON_MLP_LR_MULT="$mlp_mult" \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  SENPAI_SEED=0 \
  WANDB_TAGS="$tags" \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "nm-joint-body-lr-down-composite" \
    --wandb_name "g1r4-edward/${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #2141 joint body-LR DOWN composite chain starting"
run_arm arm-A-ctrl                 0.80 1.20 "arm_A_ctrl"
run_arm arm-B-joint-attn065-mlp105 0.65 1.05 "arm_B_composite_down"
echo "[$(date -Iseconds)] PR #2141 chain complete"
