#!/bin/bash
# H293_smoke.sh — 10-step smoke for each outer_lr arm. Verify step-0 val=10.82583 EXACT.
set -u
unset WANDB_API_KEY
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"

COMMON_ARGS=(
  --num_trials 1 --train_steps 10
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H293_smoke
)

for outer_lr_val in 0.7 0.5 0.9; do
  smoke_log="runlogs/H293_smoke_lr${outer_lr_val}_${LOG_TS}.log"
  echo "=== Smoke outer_lr=${outer_lr_val} → ${smoke_log} ==="
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" --outer_lr "$outer_lr_val" \
    --wandb_name "g1r3-edward/H293_smoke_lr${outer_lr_val}" \
    > "$smoke_log" 2>&1
  echo "  exit=$?"
  grep -E "step:0/10 val_loss" "$smoke_log" || echo "  WARN: no step:0 val_loss line in $smoke_log"
done
