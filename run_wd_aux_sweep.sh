#!/bin/bash
# 5-cell wd_aux sweep for PR #1105 (AdamW auxiliary weight decay).
# Cells: A=0.0 (ctrl), B=0.001 (PRIMARY), C=0.005, D=0.01, E=0.05.
# Single-runner discipline: sequential torchruns, each ~100 min on 1xH100.
set -u
cd /workspace/senpai/target

LOG_DIR=logs
mkdir -p "$LOG_DIR"
STATE=logs/wd_aux_state.txt

log_state() { echo "$(date -Is) $*" | tee -a "$STATE"; }

launch_cell() {
  local LETTER=$1
  local WD=$2
  local LOG="logs/cell_${LETTER}_wd_aux_${WD}.log"
  log_state "launching Cell $LETTER (wd_aux=$WD)"
  SENPAI_TRAIN_STEPS=3250 nohup torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft \
    --wd_aux ${WD} \
    --wandb_name "cell-${LETTER}-wd-${WD}" \
    --wandb_group "g1r5-askeladd/adamw-aux-wd" \
    > "$LOG" 2>&1 &
  local PID=$!
  echo "$PID" > "logs/wd_aux_cell${LETTER}.pid"
  log_state "Cell $LETTER torchrun PID $PID logged to $LOG"
  wait "$PID"
  local RC=$?
  local FINAL=$(grep -oP "step:3250/3250.*val_loss:\K[0-9.]+" "$LOG" | tail -1)
  log_state "Cell $LETTER finished rc=$RC val_loss=$FINAL"
}

# Run all 5 cells sequentially
launch_cell "A" "0.0"
launch_cell "B" "0.001"
launch_cell "C" "0.005"
launch_cell "D" "0.01"
launch_cell "E" "0.05"

log_state "wd_aux sweep complete (Cells A-E)"
