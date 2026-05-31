#!/usr/bin/env bash
# H345 arm_b BODY_ONLY — Polyak EMA scope=body (MuonH-orthogonalized 2D weights only).
set -u
WORKDIR=/workspace/senpai/target
LOGDIR="$WORKDIR/logs_h345"
LOGFILE="$LOGDIR/arm_b_BODY_ONLY.log"
PIDFILE="$LOGDIR/arm_b_BODY_ONLY.pid"

cd "$WORKDIR"
nohup torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --polyak_ema_scope body \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group H345_polyak_ema_scope_decoupling \
  --wandb_name g1r3-alphonse/H345_arm_b_BODY_ONLY \
  > "$LOGFILE" 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"
echo "[H345 arm_b BODY_ONLY] launched PID $PID at $(date -u +%FT%TZ); log=$LOGFILE"
