#!/bin/bash
# LR schedule shape sweep — runs cells A, B, C, D, E serially on 1 GPU.
# Cell A first (refactor-neutrality), then B (cosine PRIMARY), C, D, E.
# Each cell writes its log to logs/lr_schedule_sweep/cell_<X>.log.
# State file logs/lr_schedule_sweep/state.txt records cell status.

set -u
cd /workspace/senpai/target
mkdir -p logs/lr_schedule_sweep

STATE=logs/lr_schedule_sweep/state.txt
LAUNCHER_LOG=logs/lr_schedule_sweep/launcher.log

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launcher start pid=$$" >> "$LAUNCHER_LOG"

BASE_FLAGS="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-askeladd/lr-schedule-shape-sweep"

run_cell() {
  local cell="$1"
  local sched="$2"
  local extra="$3"
  local name="$4"
  local log="logs/lr_schedule_sweep/cell_${cell}.log"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) START cell=${cell} schedule=${sched} name=${name}" >> "$STATE"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) cell=${cell} START schedule=${sched}" >> "$LAUNCHER_LOG"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $BASE_FLAGS \
    --lr_schedule "$sched" $extra \
    --wandb_group "$GROUP" \
    --wandb_name "$name" \
    > "$log" 2>&1
  local rc=$?
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) END   cell=${cell} schedule=${sched} rc=${rc} log=${log}" >> "$STATE"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) cell=${cell} END rc=${rc}" >> "$LAUNCHER_LOG"
  return $rc
}

# Cell A: linear (refactor-neutrality + baseline reproduction)
run_cell A linear ""                       "cell-A-lr-linear-ctrl"
# Cell B (PRIMARY ★): cosine
run_cell B cosine ""                       "cell-B-lr-cosine"
# Cell C: exponential
run_cell C exponential ""                  "cell-C-lr-exponential"
# Cell D: linear_to_floor with lr_floor=0.1
run_cell D linear_to_floor "--lr_floor 0.1" "cell-D-lr-linear-to-floor-0p1"
# Cell E: quintic
run_cell E quintic ""                      "cell-E-lr-quintic"

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launcher DONE" >> "$LAUNCHER_LOG"
echo "ALL DONE" >> "$STATE"
