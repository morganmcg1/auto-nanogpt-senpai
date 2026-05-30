#!/usr/bin/env bash
# Orchestrator: Run Cells A (CTRL), B (Pade default), C (Pade fast) sequentially on 1 GPU.
set -euo pipefail

LOG_DIR=logs/pade_abc
mkdir -p "$LOG_DIR"

cd /workspace/senpai/target

COMMON="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 --ns_iter 6"

echo "=== Cell A: CTRL (NS5 polynomial baseline) ==="
date -u
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --wandb_name "g1r5-fern/pade-CTRL-n1" \
  --wandb_group "fern-pade-rational-ns-r5" \
  > "$LOG_DIR/cellA_ctrl.log" 2>&1 || echo "Cell A failed (exit $?)"

echo "=== Cell B: Pade default (alpha=3.0 beta=1.5 iter=3) ==="
date -u
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --ns_rational --ns_rational_alpha 3.0 --ns_rational_beta 1.5 --ns_rational_iter 3 \
  --wandb_name "g1r5-fern/pade-default-n1" \
  --wandb_group "fern-pade-rational-ns-r5" \
  > "$LOG_DIR/cellB_pade_default.log" 2>&1 || echo "Cell B failed (exit $?)"

echo "=== Cell C: Pade fast (alpha=4.0 beta=2.0 iter=2) ==="
date -u
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --ns_rational --ns_rational_alpha 4.0 --ns_rational_beta 2.0 --ns_rational_iter 2 \
  --wandb_name "g1r5-fern/pade-fast-n1" \
  --wandb_group "fern-pade-rational-ns-r5" \
  > "$LOG_DIR/cellC_pade_fast.log" 2>&1 || echo "Cell C failed (exit $?)"

echo "=== ABC orchestrator done ==="
date -u
