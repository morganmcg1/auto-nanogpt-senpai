#!/usr/bin/env bash
# Usage: run_arm.sh <arm-letter>  where ARM in {A,B,C,D}
#   A => NANOGPT_NADAM_SCOPE=none   (AdamW control)
#   B => NANOGPT_NADAM_SCOPE=embed
#   C => NANOGPT_NADAM_SCOPE=lm_head
#   D => NANOGPT_NADAM_SCOPE=all_aux
set -euo pipefail
ARM="$1"

# Shared envs (merged stack from post-#393)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5

case "$ARM" in
  A) export NANOGPT_NADAM_SCOPE=none;    NAME_SUFFIX="A-control" ;;
  B) export NANOGPT_NADAM_SCOPE=embed;   NAME_SUFFIX="B-embed"   ;;
  C) export NANOGPT_NADAM_SCOPE=lm_head; NAME_SUFFIX="C-lmhead"  ;;
  D) export NANOGPT_NADAM_SCOPE=all_aux; NAME_SUFFIX="D-all-aux" ;;
  *) echo "unknown ARM: $ARM" >&2; exit 2 ;;
esac

cd /workspace/senpai/target

echo "=== Starting arm $ARM (NADAM_SCOPE=$NANOGPT_NADAM_SCOPE) at $(date -u +%FT%TZ) ==="

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r4-nezuko/nadam-aux-${NAME_SUFFIX}" \
  --wandb_group "g1r4-nezuko/nadam-aux"

echo "=== Finished arm $ARM at $(date -u +%FT%TZ) ==="
