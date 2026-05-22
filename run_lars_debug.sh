#!/usr/bin/env bash
# Tiny debug: 150 steps with LARS enabled to verify code path + telemetry.
set -euo pipefail

cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/logs_lars
mkdir -p "$LOG_DIR"

NANOGPT_TRAIN_STEPS=150 \
NANOGPT_GRAD_CLIP=10.0 \
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
NANOGPT_LARS_MUON_ENABLE=1 \
NANOGPT_LARS_MUON_LO=0.5 \
NANOGPT_LARS_MUON_HI=2.0 \
NANOGPT_LARS_MUON_EMA=0.0 \
WANDB_MODE=offline \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r4-askeladd/lars-debug" \
  --wandb_group "g1r4-askeladd/lars-debug" \
  > "$LOG_DIR/debug.log" 2>&1

echo "EXIT=$?"
tail -40 "$LOG_DIR/debug.log"
