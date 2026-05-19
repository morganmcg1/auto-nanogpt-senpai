#!/bin/bash
# PR #423: Sequential WD peak sensitivity sweep for ramp_down (A→E, n=1 each).
# Cells D and E have early-kill gates at step 500.
set -u
cd /workspace/senpai/target

LOGDIR=/workspace/senpai/target/runs/g1r5-fern/wd-peak-sweep
mkdir -p "$LOGDIR"
WATCHER_LOG="$LOGDIR/watcher.log"
GROUP="g1r5-fern/wd-peak-sweep"

# Common args
COMMON="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down"

launch_cell() {
  # Args: cell_letter wd_value wandb_short kill_threshold (0 = no kill)
  local letter=$1
  local wd=$2
  local short=$3
  local kill_thresh=$4

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

  # If kill_thresh > 0, monitor step 500 val_loss
  if [[ "$kill_thresh" != "0" ]]; then
    local killed=0
    while kill -0 "$pid" 2>/dev/null; do
      sleep 60
      # Look for step:500 val_loss line
      local val=$(grep -oP 'step:500/3250 val_loss:\K[0-9.]+' "$log" | head -1)
      if [[ -n "$val" ]]; then
        echo "[$(date -u +%FT%TZ)] Cell $letter step:500 val_loss=$val (threshold=$kill_thresh)"
        if awk -v v="$val" -v t="$kill_thresh" 'BEGIN{exit !(v > t)}'; then
          echo "[$(date -u +%FT%TZ)] Cell $letter EARLY KILL: val_loss=$val > $kill_thresh"
          kill "$pid" 2>/dev/null
          sleep 5
          kill -9 "$pid" 2>/dev/null
          killed=1
        fi
        break
      fi
    done
    if [[ "$killed" == "0" ]]; then
      wait "$pid"
      echo "[$(date -u +%FT%TZ)] Cell $letter exited rc=$?"
    else
      echo "[$(date -u +%FT%TZ)] Cell $letter was early-killed."
    fi
  else
    wait "$pid"
    echo "[$(date -u +%FT%TZ)] Cell $letter exited rc=$?"
  fi
}

{
  echo "[$(date -u +%FT%TZ)] === WD peak sweep starting (A→E) ==="

  # Cell A: ctrl wd=0.025 peak=0.050
  launch_cell A 0.025  wd-peak-A-025-ctrl-n1  0

  # Cell B: wd=0.0125 peak=0.025
  launch_cell B 0.0125 wd-peak-B-0125-n1      0

  # Cell C: wd=0.0375 peak=0.075
  launch_cell C 0.0375 wd-peak-C-0375-n1      0

  # Cell D: wd=0.05 peak=0.100 - kill if val>3.290 at step 500
  launch_cell D 0.05   wd-peak-D-050-n1       3.290

  # Cell E: wd=0.075 peak=0.150 - kill if val>3.295 at step 500
  launch_cell E 0.075  wd-peak-E-075-n1       3.295

  echo "[$(date -u +%FT%TZ)] === WD peak sweep complete ==="
} >> "$WATCHER_LOG" 2>&1
