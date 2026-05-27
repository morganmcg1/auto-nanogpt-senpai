#!/bin/bash
# PR #1326 scalars-decoupled-cooldown ablation — 5 cells sequential, n=1 each.
# A=shared (ctrl), B★=constant PRIMARY, C=early (cf=0.5), D=late (cf=0.85), E=anti (falsifier).
# All cells: 3250 steps, --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6
#            --depth_init_mode musoft --lr_scalars 0.03.
# Single-runner discipline: at most one train_gpt_simple at a time.
set -u
cd /workspace/senpai/target

LOG_DIR=logs
mkdir -p "$LOG_DIR"
STATE="$LOG_DIR/scalars_cooldown_state.txt"

log_state() { echo "$(date -Is) $*" | tee -a "$STATE"; }

launch_cell() {
  local NAME=$1
  local MODE=$2
  local LOG="$LOG_DIR/cell_${NAME}_scalars_cooldown.log"
  log_state "launching Cell $NAME (scalars_cooldown_mode=$MODE)"
  SENPAI_TRAIN_STEPS=3250 nohup torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 \
    --depth_init_mode musoft \
    --scalars_cooldown_mode "$MODE" \
    --wandb_name "askeladd-scalars-cooldown-${NAME}-${MODE}-n1" \
    --wandb_group "g1r5-askeladd/scalars-decoupled-cooldown" \
    > "$LOG" 2>&1 &
  local PID=$!
  echo "$PID" > "$LOG_DIR/scalars_cooldown_cell${NAME}.pid"
  log_state "Cell $NAME torchrun PID $PID"
  wait "$PID"
  local RC=$?
  local FINAL_VAL
  FINAL_VAL=$(grep -oP "step:3250/3250.*val_loss:\K[0-9.]+" "$LOG" | tail -1)
  log_state "Cell $NAME finished rc=$RC val_loss=$FINAL_VAL"
}

log_state "sweep_start"
launch_cell "A" "shared"
launch_cell "B" "constant"
launch_cell "C" "early"
launch_cell "D" "late"
launch_cell "E" "anti"
log_state "sweep_end"
