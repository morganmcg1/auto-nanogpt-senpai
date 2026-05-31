#!/usr/bin/env bash
set -euo pipefail
# H336 3-arm sequential chain (train_steps=3325 each, ~1h 45min/arm):
#   arm_a CTRL          (β=0.0, η=1.0) — bit-id with H266 hard-replace baseline
#   arm_b BRAKE_LIGHT   (β=0.5, η=0.5) — 2D interior: half-step, light smoothing
#   arm_c BRAKE_HEAVY   (β=0.5, η=0.3) — 2D interior: 0.3× step, light smoothing
ARM="${1:?arm a|b|c required}"
case "$ARM" in
  a) BETA=0.0; ETA=1.0; SUFFIX="arm_a_CTRL";;
  b) BETA=0.5; ETA=0.5; SUFFIX="arm_b_BRAKE_LIGHT";;
  c) BETA=0.5; ETA=0.3; SUFFIX="arm_c_BRAKE_HEAVY";;
  *) echo "usage: $0 {a|b|c}" >&2; exit 2;;
esac
NAME="g1r3-edward/H336_${SUFFIX}"
LOG="runlogs/h336/${SUFFIX}.log"
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --outer_anchor_momentum "$BETA" --outer_anchor_lr "$ETA" \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H336_outer_anchor_brake_interior" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
