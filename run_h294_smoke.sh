#!/bin/bash
# H294 smoke: 10-step bit-id check for all 3 EMA decay arms.
# All 3 arms must show step:0/10 val_loss:10.82583 EXACT (Pattern A drift-FREE).
set -euo pipefail
cd /workspace/senpai/target

LOGDIR=logs_h294
mkdir -p "$LOGDIR"

COMMON=(
  --num_trials 1 --train_steps 10
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
  --wandb_group H294_smoke
)

for decay_val in 0.05 0.075 0.10; do
  echo "=== smoke decay=${decay_val} starting $(date -u) ===" | tee -a "$LOGDIR/smoke.log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --polyak_ema_decay $decay_val \
    --wandb_name g1r3-frieren/H294_smoke_decay${decay_val} \
    2>&1 | tee "$LOGDIR/smoke_decay${decay_val}.log"
done

echo "=== H294 smoke complete $(date -u) ===" | tee -a "$LOGDIR/smoke.log"
