#!/bin/bash
# H335 3-arm sequential chain (single GPU)
# AUX adamw_eps VALUE micro-axis at H266 hardcoded baseline (PR #1968)
# arm_a CTRL    (eps=1e-6, EXACT H266 baseline — Pattern A drift-FREE reference)
# arm_b LOW     (eps=1e-7, 10× SMALLER — extends "fully-normalized momentum" regime)
# arm_c HIGH    (eps=1e-5, 10× LARGER  — extends "raw momentum" regime)

set -e
cd /workspace/senpai/target

mkdir -p chain_h335_logs

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
)

echo "=== chain_h335 START $(date -u +%FT%TZ) ==="

# --- arm_a CTRL eps=1e-6 ---
echo "--- $(date -u +%FT%TZ) launching arm_a CTRL eps=1e-6 ---"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --aux_adamw_eps 1e-6 \
  --wandb_name "g1r3-fern/H335_arm_a_CTRL" \
  --wandb_group "H335_aux_adamw_eps_value" \
  > chain_h335_logs/arm_a.log 2>&1
echo "--- $(date -u +%FT%TZ) arm_a finished ---"

# --- arm_b LOW eps=1e-7 ---
echo "--- $(date -u +%FT%TZ) launching arm_b LOW eps=1e-7 ---"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --aux_adamw_eps 1e-7 \
  --wandb_name "g1r3-fern/H335_arm_b_LOW" \
  --wandb_group "H335_aux_adamw_eps_value" \
  > chain_h335_logs/arm_b.log 2>&1
echo "--- $(date -u +%FT%TZ) arm_b finished ---"

# --- arm_c HIGH eps=1e-5 ---
echo "--- $(date -u +%FT%TZ) launching arm_c HIGH eps=1e-5 ---"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --aux_adamw_eps 1e-5 \
  --wandb_name "g1r3-fern/H335_arm_c_HIGH" \
  --wandb_group "H335_aux_adamw_eps_value" \
  > chain_h335_logs/arm_c.log 2>&1
echo "--- $(date -u +%FT%TZ) arm_c finished ---"

echo "=== chain_h335 COMPLETE $(date -u +%FT%TZ) ==="
