#!/usr/bin/env bash
# PR #568 per-group cooldown_frac sweep — runs a single arm
# Usage: bash run_arm.sh <ARM>  where ARM in {A, B, C, D, DEBUG}
set -euo pipefail

ARM=${1:?"Usage: $0 <A|B|C|D|DEBUG>"}
cd /workspace/senpai/target

# Defaults: control values (Arm A — all 0.70)
EMBED_CF=0.70
BODY_CF=0.70
LM_HEAD_CF=0.70
SCALAR_CF=0.70
STEPS=3350

case "$ARM" in
  A)
    NAME="g1r4-nezuko/per-group-cooldown-frac-A-control"
    ;;
  B)
    EMBED_CF=0.80
    NAME="g1r4-nezuko/per-group-cooldown-frac-B-embed-0.80"
    ;;
  C)
    EMBED_CF=0.60
    NAME="g1r4-nezuko/per-group-cooldown-frac-C-embed-0.60"
    ;;
  D)
    BODY_CF=0.80
    NAME="g1r4-nezuko/per-group-cooldown-frac-D-body-0.80"
    ;;
  DEBUG)
    STEPS=50
    NAME="g1r4-nezuko/per-group-cooldown-frac-DEBUG"
    ;;
  *) echo "unknown arm: $ARM"; exit 2 ;;
esac

export NANOGPT_EMBED_COOLDOWN_FRAC="$EMBED_CF"
export NANOGPT_BODY_COOLDOWN_FRAC="$BODY_CF"
export NANOGPT_LM_HEAD_COOLDOWN_FRAC="$LM_HEAD_CF"
export NANOGPT_SCALAR_COOLDOWN_FRAC="$SCALAR_CF"

# Shared merged-stack env vars (post-#393)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_TRAIN_STEPS="$STEPS"

echo "=== Arm $ARM: embed_cf=$EMBED_CF body_cf=$BODY_CF lm_head_cf=$LM_HEAD_CF scalar_cf=$SCALAR_CF  STEPS=$STEPS  NAME=$NAME ==="
torchrun --standalone --nproc_per_node="$(nvidia-smi -L | wc -l)" \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "$NAME" \
  --wandb_group "g1r4-nezuko/per-group-cooldown-frac"
