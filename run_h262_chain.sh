#!/bin/bash
# H262 chain: arm_a CTRL warmup=100 -> arm_b LONGER warmup=250 -> arm_c SHORTER warmup=50.
# 1 GPU sequential. Zero code changes — argparse VALUE ablation on muonh_warmup_steps only.
set -euo pipefail
cd /workspace/senpai/target

LOGDIR=logs_h262
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
  --wandb_group H262_body_warmup_duration
)

echo "=== arm_a CTRL (muonh_warmup_steps=100) starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 100 \
  --wandb_name g1r3-frieren/H262_arm_a_CTRL_warmup100 \
  2>&1 | tee "$LOGDIR/arm_a.log"

echo "=== arm_b LONGER (muonh_warmup_steps=250) starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 250 \
  --wandb_name g1r3-frieren/H262_arm_b_LONGER_warmup250 \
  2>&1 | tee "$LOGDIR/arm_b.log"

echo "=== arm_c SHORTER (muonh_warmup_steps=50) starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --muonh_warmup_steps 50 \
  --wandb_name g1r3-frieren/H262_arm_c_SHORTER_warmup50 \
  2>&1 | tee "$LOGDIR/arm_c.log"

echo "=== CHAIN COMPLETE $(date -u) ===" | tee -a "$LOGDIR/chain.log"
