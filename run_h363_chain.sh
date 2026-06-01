#!/bin/bash
set -e
cd /workspace/senpai/target

LOGDIR=logs_h363
mkdir -p "$LOGDIR"

BASE_CMD=(
  torchrun --standalone --nproc_per_node=1
  records/track_3_optimization/train_gpt_simple.py
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H363_muonh_mu_start_value_bracket
)

echo "=== arm_a CTRL muonh_mu_start=0.95 linear 0.95->0.90 (H266 bit-id) ==="
"${BASE_CMD[@]}" \
  --muonh_mu_start 0.95 \
  --wandb_name "g1r3-frieren/H363_arm_a_CTRL" \
  2>&1 | tee "$LOGDIR/arm_a.log"

echo "=== arm_b LOWER muonh_mu_start=0.90 linear 0.90->0.90 (constant) ==="
"${BASE_CMD[@]}" \
  --muonh_mu_start 0.90 \
  --wandb_name "g1r3-frieren/H363_arm_b_LOWER" \
  2>&1 | tee "$LOGDIR/arm_b.log"

echo "=== arm_c HIGHER muonh_mu_start=0.98 linear 0.98->0.90 (steeper) ==="
"${BASE_CMD[@]}" \
  --muonh_mu_start 0.98 \
  --wandb_name "g1r3-frieren/H363_arm_c_HIGHER" \
  2>&1 | tee "$LOGDIR/arm_c.log"

echo "=== H363 chain DONE ==="
