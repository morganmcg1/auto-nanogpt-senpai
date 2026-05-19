#!/usr/bin/env bash
set -eo pipefail

LOGDIR="logs_ns_iters_cooldown"
mkdir -p "$LOGDIR"

# Shared envs (all arms)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down

ARM="$1"
NS_COOLDOWN="$2"
NAME="$3"
LOGFILE="$LOGDIR/arm-${ARM}-ns${NS_COOLDOWN}.log"

echo "[$(date -u +%FT%TZ)] Starting arm-$ARM ns_cooldown=$NS_COOLDOWN name=$NAME" | tee "$LOGFILE"

NANOGPT_NS_ITERS_COOLDOWN="$NS_COOLDOWN" \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r4-askeladd/$NAME" \
  --wandb_group "g1r4-askeladd/ns-iters-cooldown" \
  2>&1 | tee -a "$LOGFILE"

echo "[$(date -u +%FT%TZ)] Finished arm-$ARM" | tee -a "$LOGFILE"
