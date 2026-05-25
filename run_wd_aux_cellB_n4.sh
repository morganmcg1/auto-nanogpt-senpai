#!/bin/bash
# n=4 confirmation for PR #1105 best cell (Cell B, wd_aux=0.001).
# Launched after the 5-cell n=1 sweep showed Cell B as the minimum
# (val_loss=3.25981, ffs=3025), passing the n=1 confirm gate (<= 3.260628)
# and showing the sweet-spot pattern (B < A, C/D/E > B).
#
# n=4 merge gate: mu <= 3.259221 (statsig (3.261221 - mu) * sqrt(n) >= 0.004)
set -u
cd /workspace/senpai/target

LOG_DIR=logs
mkdir -p "$LOG_DIR"
STATE=logs/wd_aux_cellB_n4_state.txt
LOG=logs/cell_B_n4_wd_aux_0.001.log

log_state() { echo "$(date -Is) $*" | tee -a "$STATE"; }

log_state "launching Cell B n=4 confirmation (wd_aux=0.001, num_trials=4)"
SENPAI_TRAIN_STEPS=3250 nohup torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 \
  --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft \
  --wd_aux 0.001 \
  --wandb_name "cell-B-n4-confirm-wd-0.001" \
  --wandb_group "g1r5-askeladd/adamw-aux-wd" \
  > "$LOG" 2>&1 &
PID=$!
echo "$PID" > logs/wd_aux_cellB_n4.pid
log_state "Cell B n=4 confirm torchrun PID $PID logged to $LOG"
wait "$PID"
RC=$?
log_state "Cell B n=4 confirm finished rc=$RC"

# Extract trial-final val_loss from the log
TRIALS=$(grep -oP "trial:\d+ best_val_loss:\K[0-9.]+" "$LOG" | tr '\n' ' ')
log_state "trial val_losses: $TRIALS"
log_state "n=4 confirmation complete"
