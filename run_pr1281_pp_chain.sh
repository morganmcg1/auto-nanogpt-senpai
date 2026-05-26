#!/bin/bash
# PR #1281 — H2 Cooldown-entry R-buffer refresh: PP n=3 paired-pod escalation.
# Frozen by advisor (cycle 355). Arm B (RESET_STEP=2345, exact cooldown_start)
# is the winning screening config (Δ_paired_val=−0.00225 vs ctrl, fs=3175).
# 6 sequential paired-pod runs, seeds 0/1/2 interleaved as s{seed}-A then s{seed}-B
#   A = ctrl  (RESET_STEP=0)
#   B = test  (RESET_STEP=2345)
# Stack identical to screening BASE (post-#1138 + #290 linear_ramp_down).
set -u
LOG_DIR="_logs/pr1281_pp"
mkdir -p "$LOG_DIR"

run_pp_arm () {
  local seed="$1"
  local arm_letter="$2"        # A or B
  local reset_step="$3"        # 0 for A ctrl, 2345 for B test
  local run_name="g1r4-edward-rrefresh-pp-s${seed}-${arm_letter}"
  local logfile="$LOG_DIR/s${seed}-${arm_letter}.log"
  echo "[$(date -Iseconds)] >>> Launching PP s${seed}-${arm_letter} seed=${seed} RESET_STEP=${reset_step} logfile=${logfile}"
  NANOGPT_GRAD_CLIP=10.0 NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10 NANOGPT_NEWTON_MUON_MAX_D_IN=1024 \
  NANOGPT_NEWTON_MUON_RESET_STEP=${reset_step} \
  SENPAI_SEED=${seed} NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "g1r4-edward/cooldown-entry-r-refresh-pp" \
    --wandb_name "${run_name}" \
    > "${logfile}" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< PP s${seed}-${arm_letter} exit=${rc}"
  return $rc
}

echo "[$(date -Iseconds)] PR #1281 PP n=3 chain starting (6 runs: s0-A s0-B s1-A s1-B s2-A s2-B)"
run_pp_arm 0 A 0
run_pp_arm 0 B 2345
run_pp_arm 1 A 0
run_pp_arm 1 B 2345
run_pp_arm 2 A 0
run_pp_arm 2 B 2345
echo "[$(date -Iseconds)] PR #1281 PP n=3 chain complete"
