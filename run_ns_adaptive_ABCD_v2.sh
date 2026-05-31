#!/usr/bin/env bash
# PR #1834 ns-adaptive-iter-residual (revised plan with relative residual):
#   A: ctrl --ns_iter 6 (baseline, fixed iter, no adaptive)
#   B: --ns_iter 8 --ns_adaptive_tol 0.1 (tight)
#   C: --ns_iter 8 --ns_adaptive_tol 0.2 (medium)
#   D: --ns_iter 8 --ns_adaptive_tol 0.3 (loose)
# Sequential chain; each cell ~3250 steps / ~110 min on 1xH100. Total ~7-8 h.
set -e
set -u
cd "$(dirname "$0")"

COMMON=(
  --num_trials 1
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

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell A (ctrl, ns_iter=6) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_iter 6 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellA-ctrl-iter6" \
  2>&1 | tee screen_logs/ns_adaptive_cellA_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell A DONE ==="

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell B (tol=0.1) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_iter 8 \
  --ns_adaptive_tol 0.1 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellB-tol0.1" \
  2>&1 | tee screen_logs/ns_adaptive_cellB_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell B DONE ==="

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell C (tol=0.2) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_iter 8 \
  --ns_adaptive_tol 0.2 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellC-tol0.2" \
  2>&1 | tee screen_logs/ns_adaptive_cellC_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell C DONE ==="

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell D (tol=0.3) START ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --ns_iter 8 \
  --ns_adaptive_tol 0.3 \
  --wandb_name "g1r5-nezuko/ns-adaptive-cellD-tol0.3" \
  2>&1 | tee screen_logs/ns_adaptive_cellD_v2.log
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Cell D DONE ==="

echo "=== ALL CELLS DONE ==="
