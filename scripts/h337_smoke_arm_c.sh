#!/usr/bin/env bash
# H337 smoke gate at arm_c HIGH (β=0.7), 125 steps.
# Verifies: step-0 val=10.82583 EXACT bit-id, outer_velocity_rms bounded ~3x ratio vs arm_a delta envelope.
# Usage: h337_smoke_arm_c.sh <seed_suffix>
set -u
SEED_SUFFIX="${1:-s1}"
WORKDIR=/workspace/senpai/target
LOGDIR="$WORKDIR/logs_h337"
LOGFILE="$LOGDIR/smoke_arm_c_${SEED_SUFFIX}.log"
PIDFILE="$LOGDIR/smoke_arm_c_${SEED_SUFFIX}.pid"

cd "$WORKDIR"
nohup torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.7 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H337_smoke \
  --wandb_name "g1r3-alphonse/H337_smoke_arm_c_${SEED_SUFFIX}" \
  > "$LOGFILE" 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"
echo "[H337 smoke arm_c ${SEED_SUFFIX}] launched PID $PID at $(date -u +%FT%TZ); log=$LOGFILE"
