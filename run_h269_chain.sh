#!/bin/bash
# H269 chain: body warmup fine-resolution LOWER-BOUND sweep
# arm_a CTRL warmup=100 (bit-id check) -> arm_b SHORTER warmup=25 -> arm_c ZERO warmup=0
# Trivially drift-FREE: argparse VALUE-only mutation on muonh_warmup_steps.
# 1 GPU sequential.
set -euo pipefail
cd /workspace/senpai/target

LOGDIR=logs_h269
mkdir -p "$LOGDIR"

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --wandb_project modded-nanogpt-senpai
  --wandb_group H269_body_warmup_lower_bound
)

echo "=== arm_a CTRL warmup=100 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 100 \
  --wandb_name g1r3-frieren/H269_arm_a_CTRL_warmup100 \
  2>&1 | tee "$LOGDIR/arm_a.log"
echo "=== arm_a CTRL done $(date -u) ===" | tee -a "$LOGDIR/chain.log"

echo "=== arm_b SHORTER warmup=25 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 25 \
  --wandb_name g1r3-frieren/H269_arm_b_SHORTER_warmup25 \
  2>&1 | tee "$LOGDIR/arm_b.log"
echo "=== arm_b SHORTER done $(date -u) ===" | tee -a "$LOGDIR/chain.log"

echo "=== arm_c ZERO warmup=0 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 0 \
  --wandb_name g1r3-frieren/H269_arm_c_ZERO_warmup0 \
  2>&1 | tee "$LOGDIR/arm_c.log"
echo "=== arm_c ZERO done $(date -u) ===" | tee -a "$LOGDIR/chain.log"

echo "=== H269 CHAIN COMPLETE $(date -u) ===" | tee -a "$LOGDIR/chain.log"
