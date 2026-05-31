#!/bin/bash
# PR #1834 redesign smoke: verify relative residual ||XX^T-I||_F/sqrt(m) < 0.3 fires.
# Quick 100-step run to confirm the relative threshold is reachable before burning
# full Cell B/C/D budget.

set -e
cd /workspace/senpai/target
mkdir -p screen_logs/ns_adaptive

BASE_FLAGS="--soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99"
GROUP="nezuko-adaptive-ns-iter-r5"

echo "=== Smoke (rel-resid, tol=0.3) start at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=100 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --ns_iter 8 --ns_adaptive_tol 0.3 \
  $BASE_FLAGS \
  --wandb_name "g1r5-nezuko/ns-adaptive-smoke-relresid-tol0.3" \
  --wandb_group "$GROUP" \
  > screen_logs/ns_adaptive/smoke_relresid.log 2>&1
echo "=== Smoke done at $(date -u +%FT%TZ) ==="
