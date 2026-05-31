#!/bin/bash
# PR #1888 — NM R-buffer v-warmstart K bracket — sequential 4-arm A->B->C->D
# K=100 (ctrl, production), K=50 (shorter), K=200 (2x), K=400 (4x)
# SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 num_trials=1 single GPU.
# Production stack identical to #1702 reproduce; only K varies per arm.
set -u
LOG_DIR="_logs/pr1888"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local warmstart_k="$2"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (WARMSTART_K=$warmstart_k) logfile=$logfile"
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K="$warmstart_k" \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_MUON_NOREJECT=1 \
  SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "nm-r-adamw-warmstart-k-bracket" \
    --wandb_name "g1r4-edward/${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #1888 NM R-buffer v-warmstart K bracket chain starting"
run_arm armA-ctrl-K100   100
run_arm armB-K50         50
run_arm armC-K200        200
run_arm armD-K400        400
echo "[$(date -Iseconds)] PR #1888 chain complete"
