#!/bin/bash
# H272 chain: arm_a CTRL (eps=1e-6) → arm_b SMALLER_EPS (1e-8) → arm_c LARGER_EPS (1e-4)
# Trivially drift-FREE argparse VALUE-only chain — tests PF#61 continuous-axis.
set -uo pipefail

cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/h272_logs
mkdir -p "$LOG_DIR"

COMMON_ARGS="--num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai --wandb_group H272_aux_eps"

echo "=== H272 arm_a CTRL eps=1e-6 starting $(date -Is) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $COMMON_ARGS --aux_adamw_eps 1e-6 \
  --wandb_name g1r3-askeladd/H272_arm_a_CTRL_eps1e-6 \
  > "$LOG_DIR/arm_a.log" 2>&1
echo "=== H272 arm_a finished $(date -Is) exit=$? ==="

echo "=== H272 arm_b SMALLER_EPS eps=1e-8 starting $(date -Is) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $COMMON_ARGS --aux_adamw_eps 1e-8 \
  --wandb_name g1r3-askeladd/H272_arm_b_SMALLER_EPS_1e-8 \
  > "$LOG_DIR/arm_b.log" 2>&1
echo "=== H272 arm_b finished $(date -Is) exit=$? ==="

echo "=== H272 arm_c LARGER_EPS eps=1e-4 starting $(date -Is) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $COMMON_ARGS --aux_adamw_eps 1e-4 \
  --wandb_name g1r3-askeladd/H272_arm_c_LARGER_EPS_1e-4 \
  > "$LOG_DIR/arm_c.log" 2>&1
echo "=== H272 arm_c finished $(date -Is) exit=$? ==="
echo "=== H272 chain complete $(date -Is) ==="
