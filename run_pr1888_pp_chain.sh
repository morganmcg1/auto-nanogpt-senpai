#!/bin/bash
# PR #1888 — PP-confirm n=3 chain: K=200 vs K=100 ctrl, SENPAI_SEED=0/1/2.
# Per advisor c756 send-back; production stack identical to BASELINE.md #1702.
# Order: A0_ctrl_K100, B0_exp_K200, A1_ctrl_K100, B1_exp_K200, A2_ctrl_K100, B2_exp_K200.
# Each run: 3350 steps × ~2.5s/step ≈ 2.3h ⇒ chain ≈ ~14h sequential.
set -u
LOG_DIR="_logs/pr1888_pp"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local warmstart_k="$2"
  local seed="$3"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching $arm_name (K=$warmstart_k, SENPAI_SEED=$seed) logfile=$logfile"
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K="$warmstart_k" \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  SENPAI_SEED="$seed" NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "nm-r-adamw-warmstart-k-200-pp-confirm" \
    --wandb_name "g1r4-edward/${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #1888 PP-confirm n=3 chain (K=200 vs K=100 ctrl) starting"
run_arm A0-K100-ctrl 100 0
run_arm B0-K200-exp  200 0
run_arm A1-K100-ctrl 100 1
run_arm B1-K200-exp  200 1
run_arm A2-K100-ctrl 100 2
run_arm B2-K200-exp  200 2
echo "[$(date -Iseconds)] PR #1888 PP-confirm chain complete"
