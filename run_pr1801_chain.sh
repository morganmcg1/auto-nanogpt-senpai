#!/bin/bash
# PR #1801 — NM α-SWITCH-TIMING sweep (class 34)
# 3 arms sequential A->C, same seed (0), identical env except for
# NANOGPT_NEWTON_MUON_ALPHA_LATE / NANOGPT_NEWTON_MUON_ALPHA_SWITCH_STEP.
#   A: ctrl                       -> α=0.5 throughout                (SWITCH=0,    LATE=0.5)
#   B: pre-cooldown SWITCH=1500   -> α 0.5 -> 0.6 at newton-step 1500 (SWITCH=1500, LATE=0.6)
#   C: deep-cooldown SWITCH=3000  -> α 0.5 -> 0.6 at newton-step 3000 (SWITCH=3000, LATE=0.6)
# Production stack from PR body (post-#1702 merge):
#   ADAMW_BETA2=0.99, MUON_ATTN_LR_MULT=0.80, MUON_MLP_LR_MULT=1.20,
#   EMBED_COOLDOWN_SHAPE=linear_floor, EMBED_INIT_ANCHOR_LAMBDA=0.001,
#   ADAMW_EMBED_LR_MULT=1.5, NS_COOLDOWN_SHAPE=late_peak,
#   NS_STOCHASTIC_COOLDOWN=2, NS_COEF_SCHEDULE=linear_ramp_down,
#   NEWTON_MUON_UPDATE_PERIOD=2, MAX_D_IN=4096, TIKHONOV_GAMMA=0.005,
#   R_ADAMW_WARMSTART=1, WARMSTART_K=100.
# SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 num_trials=1 single GPU.
set -u
LOG_DIR="_logs/pr1801"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local switch_step="$2"
  local alpha_late="$3"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (ALPHA_SWITCH=$switch_step ALPHA_LATE=$alpha_late) logfile=$logfile"
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_ALPHA=0.5 \
  NANOGPT_NEWTON_MUON_ALPHA_LATE="$alpha_late" \
  NANOGPT_NEWTON_MUON_ALPHA_SWITCH_STEP="$switch_step" \
  SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "g1r4-edward_class34_alpha_switch_timing_s0" \
    --wandb_name "g1r4-edward/${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #1801 NM α-SWITCH-TIMING chain starting"
run_arm armA-ctrl-alpha0p5           0    0.5
run_arm armB-switch1500-alpha0p6     1500 0.6
run_arm armC-switch3000-alpha0p6     3000 0.6
echo "[$(date -Iseconds)] PR #1801 chain complete"
