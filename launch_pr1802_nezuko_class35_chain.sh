#!/usr/bin/env bash
# PR #1802 class 35 NS_COOLDOWN_START_FRAC TIMING-axis 3-arm sequential chain
# Arms: A ctrl (NS_COOLDOWN_START_FRAC=0.7, production baseline = step 2345)
#       B earlier (NS_COOLDOWN_START_FRAC=0.6, step 2010, +335 steps at intensity)
#       C later (NS_COOLDOWN_START_FRAC=0.8, step 2680, -335 steps at intensity)
# All seeds=0 paired. No code edits required; only env-var differs across arms.
set -uo pipefail

cd /workspace/senpai/target

LOG_DIR="logs_pr1802_nm_ns_cooldown_start_frac_timing"
mkdir -p "$LOG_DIR"
LAUNCHER_LOG="logs_pr1802_3arm_launcher.log"

TRAIN_SCRIPT="records/track_3_optimization/train_gpt_simple.py"

COMMON_ENV=(
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  NANOGPT_NEWTON_MUON_BETA=0.95
  NANOGPT_NEWTON_MUON_EPS=1e-4
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
  SENPAI_SEED=0
  NANOGPT_TRAIN_STEPS=3350
)

WANDB_GROUP="g1r4-nezuko-ns-cooldown-start-frac-timing"

run_arm () {
  local arm_name="$1"; shift
  local wandb_name="$1"; shift
  local arm_log="$LOG_DIR/${arm_name}.log"
  local t0
  t0="$(date -u +%FT%TZ)"
  echo "===== ${t0} START ${arm_name} ($*) =====" | tee -a "$LAUNCHER_LOG"
  (
    env "${COMMON_ENV[@]}" "$@" \
      torchrun --standalone --nproc_per_node=1 \
        "$TRAIN_SCRIPT" --num_trials 1 \
        --wandb_group "$WANDB_GROUP" \
        --wandb_name "$wandb_name"
  ) >> "$arm_log" 2>&1
  local rc=$?
  local t1
  t1="$(date -u +%FT%TZ)"
  echo "===== ${t1} END ${arm_name} rc=${rc} =====" | tee -a "$LAUNCHER_LOG"
}

# Arm A ctrl: NS_COOLDOWN_START_FRAC=0.7 (production baseline, cooldown-onset step 2345)
run_arm "armA-ctrl-frac-0.7" "g1r4-nezuko/armA-ctrl-frac-0.7" \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7

# Arm B earlier: NS_COOLDOWN_START_FRAC=0.6 (cooldown-onset step 2010, +335 steps at intensity)
run_arm "armB-earlier-frac-0.6" "g1r4-nezuko/armB-earlier-frac-0.6" \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.6

# Arm C later: NS_COOLDOWN_START_FRAC=0.8 (cooldown-onset step 2680, -335 steps at intensity)
run_arm "armC-later-frac-0.8" "g1r4-nezuko/armC-later-frac-0.8" \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.8

echo "===== $(date -u +%FT%TZ) ALL 3 ARMS COMPLETE =====" | tee -a "$LAUNCHER_LOG"
