#!/bin/bash
# PR #1883 PP-confirm chain individual arm launcher.
# Usage: run_pp_arm.sh <arm_tag> <seed> <ctrl|exp> <wandb_name>
#   arm_tag   : log/PID file tag (A0, B0, A1, B1, A2, B2)
#   seed      : 0|1|2 (SENPAI_SEED)
#   ctrl|exp  : ctrl disables burst gate, exp enables BURST[2400,3000) PERIOD=1
#   wandb_name: explicit W&B run name passed to torchrun
set -e
ARM_TAG="$1"
SEED="$2"
KIND="$3"
WANDB_NAME="$4"
LOGFILE="run_logs/pp_${ARM_TAG}.log"
PIDFILE="run_logs/pp_${ARM_TAG}.pid"

# Production stack env (c624 banner, matches advisor c758 PP-confirm spec)
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_GRAD_CLIP_BODY=10
export NANOGPT_GRAD_CLIP_AUX=5
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export SENPAI_SEED="$SEED"

# Default disable burst gate (ctrl); exp arms override below
unset NANOGPT_NEWTON_MUON_BURST_START_STEP
unset NANOGPT_NEWTON_MUON_BURST_END_STEP
unset NANOGPT_NEWTON_MUON_BURST_PERIOD

if [ "$KIND" = "exp" ]; then
  export NANOGPT_NEWTON_MUON_BURST_START_STEP=2400
  export NANOGPT_NEWTON_MUON_BURST_END_STEP=3000
  export NANOGPT_NEWTON_MUON_BURST_PERIOD=1
fi

echo "Launching $ARM_TAG kind=$KIND seed=$SEED wandb=$WANDB_NAME" > "$LOGFILE"
echo "  Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOGFILE"
echo "  burst_start=${NANOGPT_NEWTON_MUON_BURST_START_STEP:-0} burst_end=${NANOGPT_NEWTON_MUON_BURST_END_STEP:-0} burst_period=${NANOGPT_NEWTON_MUON_BURST_PERIOD:-1}" >> "$LOGFILE"

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$WANDB_NAME" \
  --wandb_group "nm-burst-2400-3000-pp-confirm" >> "$LOGFILE" 2>&1 &

echo $! > "$PIDFILE"
echo "Started PID $(cat $PIDFILE) for $ARM_TAG"
