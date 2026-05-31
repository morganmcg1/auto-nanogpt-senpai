#!/bin/bash
# PR #1834 Cell B (hypothesis): ns_iter=8 cap, ns_adaptive_tol=1e-3 adaptive termination.
# Cell A (CTRL, fixed iter=6) reference run: wdyvwruc from PR #1769 (FFS_ema=FFS_trainval=2925).

set -e
cd /workspace/senpai/target
mkdir -p screen_logs/ns_adaptive

BASE_FLAGS="--soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99"
GROUP="nezuko-adaptive-ns-iter-r5"

echo "=== Cell B start at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --ns_iter 8 --ns_adaptive_tol 1e-3 \
  $BASE_FLAGS \
  --wandb_name "g1r5-nezuko/ns-adaptive-cell-B-iter8-tol1e-3" \
  --wandb_group "$GROUP" \
  > screen_logs/ns_adaptive/cell_B.log 2>&1
echo "=== Cell B done at $(date -u +%FT%TZ) ==="
