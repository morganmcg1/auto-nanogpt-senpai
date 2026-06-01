#!/bin/bash
# Cell A_ctrl: cap=15.0 (baseline replication)
set -euo pipefail
mkdir -p runlogs
LOG=runlogs/logit_softcap_down_A_ctrl.log
PIDFILE=runlogs/logit_softcap_down_A_ctrl.pid

SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --logit_softcap_value 15.0 \
  --wandb_name "g1r5-edward/logit-softcap-down-Actrl-cap15-n1" \
  --wandb_group "g1r5-edward/logit-softcap-down" \
  > "$LOG" 2>&1 &
echo "PID=$!" > "$PIDFILE"
echo "Launched A_ctrl (cap=15) PID=$! LOG=$LOG"
