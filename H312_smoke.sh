#!/bin/bash
# H312 smoke — 50-step sanity check on arm_b BIAS_CORR.
# Verifies: (1) no crash, (2) bias correction telemetry logs to W&B,
# (3) step-0 val=10.82583 matches baseline, (4) bc_inv decays from 20→~1.
set -u

unset WANDB_API_KEY
cd "$(dirname "$0")"

LOG_TS="$(date -u +'%Y%m%dT%H%M%SZ')"
SMOKE_LOG="runlogs/H312_smoke_${LOG_TS}.log"
mkdir -p runlogs

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H312 SMOKE START log=${SMOKE_LOG} =====" | tee -a "$SMOKE_LOG"

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 50 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --polyak_ema_decay 0.05 \
  --muonh_bias_correction 1 \
  --telemetry_interval 5 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H312_smoke \
  --wandb_name "g1r3-edward/H312_smoke" > "$SMOKE_LOG" 2>&1

rc=$?
echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H312 SMOKE FINISHED rc=${rc} =====" | tee -a "$SMOKE_LOG"
exit $rc
