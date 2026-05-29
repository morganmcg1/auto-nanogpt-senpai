#!/bin/bash
# n=4 confirm of Cell E (wd_mlp=0.040) on R5 EMA-eval stack
# PR #1586 advisor-approved continuation (2026-05-29)
set -u
cd /workspace/senpai/target

LOG=/workspace/senpai/target/run_logs/wd_mlp_040_n4_emaval_confirm.log
mkdir -p "$(dirname "$LOG")"

echo "=== START n=4 confirm wd_mlp=0.040 at $(date -u +%FT%TZ) ===" | tee -a "$LOG"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --wd_mlp 0.040 --wd_attn 0.025 \
  --wandb_name "g1r5-thorfinn/wd-mlp-040-n4-emaval-confirm" \
  --wandb_group "g1r5-thorfinn/wd-mlp-fine-r5-confirm" \
  >> "$LOG" 2>&1
rc=$?
echo "=== END n=4 confirm rc=${rc} at $(date -u +%FT%TZ) ===" | tee -a "$LOG"
exit $rc
