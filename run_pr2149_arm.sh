#!/bin/bash
# PR #2149 single-arm runner: EMBED_COOLDOWN_SHAPE 3-arm bracket
# Usage: run_pr2149_arm.sh <arm-tag> <shape> <wandb-name>
#   <arm-tag>   short tag used for log/pid files (e.g. armA, armB, armC)
#   <shape>     EMBED_COOLDOWN_SHAPE value: linear_floor / linear / cosine
#   <wandb-name> full wandb run name (e.g. g1r4-thorfinn/arm-A-linearfloor)
set -e
ARM_TAG="$1"
SHAPE="$2"
WANDB_NAME="$3"
LOGFILE="run_logs/pr2149_${ARM_TAG}.log"
PIDFILE="run_logs/pr2149_${ARM_TAG}.pid"

cd /workspace/senpai/target

# Production stack env (post-#1702, full reproduce per PR body)
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=0.0001
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export SENPAI_SEED=0

# Per-arm SHAPE
export NANOGPT_EMBED_COOLDOWN_SHAPE="$SHAPE"

echo "Launching ${ARM_TAG} (EMBED_COOLDOWN_SHAPE=${SHAPE}, wandb=${WANDB_NAME})" > "$LOGFILE"
echo "  Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"

nohup torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --wandb_name "$WANDB_NAME" \
  --wandb_group "nm-embed-cooldown-shape-bracket" >> "$LOGFILE" 2>&1 &

echo $! > "$PIDFILE"
echo "Started PID $(cat $PIDFILE) for ${ARM_TAG}"
