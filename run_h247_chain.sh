#!/bin/bash
# H247 chain: terminal-eval mechanism class - best-checkpoint + manifold-projected EMA
# arm_a CTRL (both flags 0, bit-id baseline)
#   -> arm_b BEST_CKPT_VAL (--eval_best_ckpt 1)
#   -> arm_c MANIFOLD_EMA (--eval_manifold_ema 1 --manifold_ema_decay 0.999)
# All 3 arms share the H203 baseline flag stack; only the H247 eval flags vary.
set -e
cd /workspace/senpai/target

LOG_DIR=logs_h247
mkdir -p "$LOG_DIR"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5
  --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
)

echo "[H247 chain] starting arm_a CTRL (eval_best_ckpt=0 eval_manifold_ema=0) at $(date -u +%H:%M:%S)"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --eval_best_ckpt 0 --eval_manifold_ema 0 \
  --wandb_mode online \
  --wandb_group "h247-eval-mechanism" \
  --wandb_name "g1r3-frieren/h247-ctrl" \
  2>&1 | tee "$LOG_DIR/arm_a_ctrl.log"
echo "[H247 chain] arm_a done at $(date -u +%H:%M:%S)"

echo "[H247 chain] starting arm_b BEST_CKPT_VAL (eval_best_ckpt=1) at $(date -u +%H:%M:%S)"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --eval_best_ckpt 1 --eval_manifold_ema 0 \
  --wandb_mode online \
  --wandb_group "h247-eval-mechanism" \
  --wandb_name "g1r3-frieren/h247-best-ckpt" \
  2>&1 | tee "$LOG_DIR/arm_b_best_ckpt.log"
echo "[H247 chain] arm_b done at $(date -u +%H:%M:%S)"

echo "[H247 chain] starting arm_c MANIFOLD_EMA (eval_manifold_ema=1 decay=0.999) at $(date -u +%H:%M:%S)"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_ARGS[@]}" \
  --eval_best_ckpt 0 --eval_manifold_ema 1 --manifold_ema_decay 0.999 \
  --wandb_mode online \
  --wandb_group "h247-eval-mechanism" \
  --wandb_name "g1r3-frieren/h247-manifold-ema" \
  2>&1 | tee "$LOG_DIR/arm_c_manifold_ema.log"
echo "[H247 chain] arm_c done at $(date -u +%H:%M:%S)"

echo "[H247 chain] ALL ARMS DONE at $(date -u +%H:%M:%S)"
