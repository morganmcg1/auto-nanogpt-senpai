#!/bin/bash
# H294 chain: 3-arm Pattern A drift-FREE polyak_ema_decay VALUE sensitivity
#   arm_a CTRL                   polyak_ema_decay=0.05  (H266 baseline replicate)
#   arm_b DECAY_0p075            polyak_ema_decay=0.075 (~13-step half-life)
#   arm_c DECAY_0p10             polyak_ema_decay=0.10  (10-step half-life)
# 1 GPU sequential. 3325 steps per arm.
set -euo pipefail
cd /workspace/senpai/target

LOGDIR=logs_h294
mkdir -p "$LOGDIR"

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --wandb_project modded-nanogpt-senpai
  --wandb_group H294_polyak_ema_decay_value
)

echo "=== arm_a CTRL polyak_ema_decay=0.05 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --polyak_ema_decay 0.05 \
  --wandb_name g1r3-frieren/H294_arm_a_CTRL_decay_0p05 \
  2>&1 | tee "$LOGDIR/arm_a.log"

echo "=== arm_b DECAY_0p075 polyak_ema_decay=0.075 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --polyak_ema_decay 0.075 \
  --wandb_name g1r3-frieren/H294_arm_b_DECAY_0p075 \
  2>&1 | tee "$LOGDIR/arm_b.log"

echo "=== arm_c DECAY_0p10 polyak_ema_decay=0.10 starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --polyak_ema_decay 0.10 \
  --wandb_name g1r3-frieren/H294_arm_c_DECAY_0p10 \
  2>&1 | tee "$LOGDIR/arm_c.log"

echo "=== H294 chain complete $(date -u) ===" | tee -a "$LOGDIR/chain.log"
