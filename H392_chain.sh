#!/usr/bin/env bash
set -euo pipefail
# H392 3-arm sequential chain (train_steps=3325, n=1 per arm).
# Tests --muonh_cooldown_shape cosine_squared = (0.5*(1-cos(pi*c)))**2 against
# H266 cosine baseline. arm_c additionally probes interaction with shorter
# cooldown_frac=0.5 (steeper drain concentrated in last half of training).
#
#   arm_a CTRL   — --muonh_cooldown_shape cosine (H266 baseline bit-id sentinel)
#   arm_b COS2   — --muonh_cooldown_shape cosine_squared (default cooldown_frac=1.0)
#   arm_c COS2_CD0.5 — --muonh_cooldown_shape cosine_squared --muonh_cooldown_frac 0.5
ARM="${1:?arm a|b|c required}"
case "$ARM" in
  a) SHAPE=cosine;          CDFRAC=1.0; SUFFIX="arm_a_CTRL_cosine";;
  b) SHAPE=cosine_squared;  CDFRAC=1.0; SUFFIX="arm_b_cos2";;
  c) SHAPE=cosine_squared;  CDFRAC=0.5; SUFFIX="arm_c_cos2_cd0.5";;
  *) echo "usage: $0 {a|b|c}" >&2; exit 2;;
esac
TS="$(date -u +%Y%m%dT%H%M%SZ)"
NAME="g1r3-edward/H392_${SUFFIX}_${TS}"
mkdir -p runlogs/h392
LOG="runlogs/h392/${SUFFIX}.log"
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape "$SHAPE" \
  --muonh_cooldown_frac "$CDFRAC" \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H392_cosine_squared_cooldown" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
