#!/usr/bin/env bash
# PR #1689 n=4 confirm of Cell B (--soap_b2_warmup_init 0.50 --soap_b2_warmup_steps 300).
# Single launch with --num_trials 4, following the post-#1381 EMA-eval n=4 confirm pattern.
set -uo pipefail

cd /workspace/senpai/target

LOG=research/soap_b2_warmup_n4_confirm_run_logs/n4_confirm_cell_B.log
STATUS=research/soap_b2_warmup_n4_confirm_run_logs/n4_confirm_cell_B.status

echo "RUN_START $(date -u +%FT%TZ)" > "$STATUS"
echo "==== n=4 CONFIRM Cell B START $(date -u +%FT%TZ) ====" | tee -a "$LOG"

SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --soap_b2_warmup_init 0.50 --soap_b2_warmup_steps 300 \
  --wandb_tags "pr1689,n4_confirm,soap_b2_warmup,cell_B" \
  --wandb_name "g1r5-alphonse/soap-gram-b2-warmup-n4-confirm" \
  --wandb_group "g1r5-alphonse/soap-gram-b2-warmup-n4-confirm" \
  >> "$LOG" 2>&1
rc=$?

echo "==== n=4 CONFIRM Cell B END $(date -u +%FT%TZ) rc=$rc ====" | tee -a "$LOG"
echo "RUN_END $(date -u +%FT%TZ) rc=$rc" >> "$STATUS"
exit "$rc"
