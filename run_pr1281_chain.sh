#!/bin/bash
# PR #1281 — H2 Cooldown-entry R-buffer refresh: single-shot reset
# 4 arms sequential A->D, each at SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350
# A=ctrl reset=0, B=reset2345 (cooldown_start), C=reset2400 (cooldown+55),
# D=reset2200 (cooldown-145).
#
# NOTE: BASE env adds NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down (#290) which
# the PR template omitted. Without it the chain would compare against a
# pre-#290 stack and fail the Arm A drift gate vs production baseline 3.26614.
set -u
LOG_DIR="_logs/pr1281"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local reset_step="$2"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (RESET_STEP=$reset_step) logfile=$logfile"
  NANOGPT_GRAD_CLIP=10.0 NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10 NANOGPT_NEWTON_MUON_MAX_D_IN=1024 \
  NANOGPT_NEWTON_MUON_RESET_STEP=$reset_step \
  SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "g1r4-edward/cooldown-entry-r-refresh" \
    --wandb_name "g1r4-edward-rrefresh-${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #1281 chain starting"
run_arm armA-ctrl       0
run_arm armB-reset2345  2345
run_arm armC-reset2400  2400
run_arm armD-reset2200  2200
echo "[$(date -Iseconds)] PR #1281 chain complete"
