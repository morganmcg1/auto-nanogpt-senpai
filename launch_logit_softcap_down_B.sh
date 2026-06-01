#!/bin/bash
# Cell B★: cap=12.5 (primary tighter test)
set -euo pipefail
mkdir -p runlogs
LOG=runlogs/logit_softcap_down_B.log
PIDFILE=runlogs/logit_softcap_down_B.pid

SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
  --logit_softcap_value 12.5 \
  --wandb_name "g1r5-edward/logit-softcap-down-Bstar-cap12.5-n1" \
  --wandb_group "g1r5-edward/logit-softcap-down" \
  > "$LOG" 2>&1 &
echo "PID=$!" > "$PIDFILE"
echo "Launched B★ (cap=12.5) PID=$! LOG=$LOG"
