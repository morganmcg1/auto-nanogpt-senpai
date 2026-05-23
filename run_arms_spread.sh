#!/bin/bash
# PR #883 — Stochastic NS cooldown spread Goldilocks sweep
# 4 arms × seed=1 × 3350 steps × 1× H100
# Arms run sequentially (1 GPU available).
set -euo pipefail

cd "$(dirname "$0")"

LOGDIR=spread_logs
mkdir -p "$LOGDIR"

ARM_LABEL="$1"   # A | B | C | D
ARM_SPREAD="$2"  # 0 | 1 | 4 | 6

WANDB_NAME="g1r4-fern-spread-arm-${ARM_LABEL}"
LOGFILE="${LOGDIR}/arm_${ARM_LABEL}_spread_${ARM_SPREAD}.log"

echo "==> Launching Arm ${ARM_LABEL} (spread=${ARM_SPREAD}) -> ${LOGFILE}"

NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_GRAD_CLIP_BODY=10.0 \
NANOGPT_GRAD_CLIP_AUX=5.0 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 \
NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_MID=0 \
NANOGPT_NS_STOCHASTIC_COOLDOWN="${ARM_SPREAD}" \
NANOGPT_TRAIN_STEPS=3350 \
SENPAI_SEED=1 \
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  --wandb_group g1r4-fern/stochastic-ns-cooldown-spread \
  --wandb_name "${WANDB_NAME}" \
  >"${LOGFILE}" 2>&1
