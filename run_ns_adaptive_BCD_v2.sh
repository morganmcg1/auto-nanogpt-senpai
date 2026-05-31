#!/usr/bin/env bash
# PR #1834 ns-adaptive-iter-residual: Cells B (tol=0.1), C (tol=0.2), D (tol=0.3)
# Sequential chain — each ~90 min, ~270 min total
# Cap NS_ITER=8 (adaptive iterates to convergence with this cap)
set -e
set -u
cd "$(dirname "$0")"

COMMON=(
  --num_trials 1
  --ns_iter 8
  --soap_attn
  --lr_mlp 0.055
  --wd_schedule ramp_down
  --lr_scalars 0.03
  --depth_init_mode musoft
  --lr_cooldown_shape cosine
  --ema_eval_decay 0.99
  --wandb_group nezuko-adaptive-ns-iter-r5-v2
)

mkdir -p screen_logs

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell B (tol=0.1) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_adaptive_tol 0.1 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellB-tol0.1" \
  2>&1 | tee screen_logs/ns_adaptive_cellB_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell B DONE ==="

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell C (tol=0.2) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_adaptive_tol 0.2 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellC-tol0.2" \
  2>&1 | tee screen_logs/ns_adaptive_cellC_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell C DONE ==="

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell D (tol=0.3) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_adaptive_tol 0.3 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellD-tol0.3" \
  2>&1 | tee screen_logs/ns_adaptive_cellD_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell D DONE ==="

echo "=== ALL CELLS DONE ==="
