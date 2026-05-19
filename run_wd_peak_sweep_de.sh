#!/bin/bash
# PR #423: Resume Cells D and E after Cell C completes.
# Original watcher was killed because early-kill thresholds (3.290/3.295) were
# mismatched with step-500 val_loss (~3.82 across all cells). This resume
# script disables the early-kill entirely; both runs go to terminal so we
# capture the full peak sensitivity curve.
set -u
cd /workspace/senpai/target

LOGDIR=/workspace/senpai/target/runs/g1r5-fern/wd-peak-sweep
mkdir -p "$LOGDIR"
WATCHER_LOG="$LOGDIR/watcher_de.log"
GROUP="g1r5-fern/wd-peak-sweep"

COMMON="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down"

# Wait for Cell C torchrun to exit (PID 572215). If already dead, returns immediately.
wait_for_cell_c() {
  local cell_c_pid=572215
  echo "[$(date -u +%FT%TZ)] Waiting for Cell C torchrun pid=$cell_c_pid to exit..."
  while kill -0 "$cell_c_pid" 2>/dev/null; do
    sleep 60
  done
  echo "[$(date -u +%FT%TZ)] Cell C process is gone."
}

launch_cell() {
  local letter=$1
  local wd=$2
  local short=$3

  local log="$LOGDIR/cell${letter}.log"
  local pid_file="$LOGDIR/cell${letter}.pid"

  echo "[$(date -u +%FT%TZ)] === Cell $letter starting: wd=$wd peak=$(awk -v w=$wd 'BEGIN{print w*2.0}') ==="
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $COMMON \
    --wd_mlp $wd --wd_attn $wd \
    --wandb_name "g1r5-fern/$short" \
    --wandb_group "$GROUP" \
    > "$log" 2>&1 &
  local pid=$!
  echo "$pid" > "$pid_file"
  echo "[$(date -u +%FT%TZ)] Cell $letter launched PID=$pid log=$log"
  wait "$pid"
  echo "[$(date -u +%FT%TZ)] Cell $letter exited rc=$?"
}

{
  echo "[$(date -u +%FT%TZ)] === Resume D+E starting ==="

  wait_for_cell_c

  # Cell D: wd=0.05 peak=0.100 (no early-kill; original threshold 3.290 was wrong)
  launch_cell D 0.05  wd-peak-D-050-n1

  # Cell E: wd=0.075 peak=0.150 (no early-kill; original threshold 3.295 was wrong)
  launch_cell E 0.075 wd-peak-E-075-n1

  echo "[$(date -u +%FT%TZ)] === Resume D+E complete ==="
} >> "$WATCHER_LOG" 2>&1
