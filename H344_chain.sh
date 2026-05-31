#!/usr/bin/env bash
set -euo pipefail
# H344 3-arm sequential chain (train_steps=3325 each, ~1h 45min/arm):
#   arm_a CTRL   (k=0, α=0.5 ignored) — bit-id with H266 baseline
#   arm_b LIGHT  (k=5, α=0.5)         — tight inner cycle, half-step pullback
#   arm_c MEDIUM (k=10, α=0.5)        — medium inner cycle, half-step pullback
ARM="${1:?arm a|b|c required}"
case "$ARM" in
  a) K=0;  ALPHA=0.5; SUFFIX="arm_a_CTRL";;
  b) K=5;  ALPHA=0.5; SUFFIX="arm_b_LIGHT_k5";;
  c) K=10; ALPHA=0.5; SUFFIX="arm_c_MEDIUM_k10";;
  *) echo "usage: $0 {a|b|c}" >&2; exit 2;;
esac
NAME="g1r3-edward/H344_${SUFFIX}"
LOG="runlogs/h344/${SUFFIX}.log"
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --aux_lookahead_k "$K" --aux_lookahead_alpha "$ALPHA" \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H344_aux_lookahead_h266_rescreen" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
