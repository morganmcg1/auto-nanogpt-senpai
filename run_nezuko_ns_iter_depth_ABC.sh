#!/usr/bin/env bash
# Chained Cells A -> B -> C for PR #1609 (depth-adaptive NS iter)
set -uo pipefail
cd "$(dirname "$0")"

TS=$(date -u +%Y%m%d-%H%M%S)
mkdir -p screen_logs

run_cell () {
  local cell_id="$1"; shift
  local extra_flags="$1"; shift
  local label="$1"; shift
  local logfile="screen_logs/nezuko-ns-depth-${cell_id}-${TS}.log"
  echo "[$(date -u +%H:%M:%S)] starting cell ${cell_id} (${label}) -> ${logfile}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
    ${extra_flags} \
    --wandb_name "nezuko-ns-depth-${cell_id}-${label}" \
    --wandb_group "nezuko-ns-iter-depth-r5" \
    > "${logfile}" 2>&1
  local rc=$?
  echo "[$(date -u +%H:%M:%S)] cell ${cell_id} exited rc=${rc}"
  return $rc
}

run_cell "cellA" "--ns_iter_schedule uniform" "uniform"
run_cell "cellB" "--ns_iter_schedule depth_up --ns_iter_delta 2" "up-delta2"
run_cell "cellC" "--ns_iter_schedule depth_down --ns_iter_delta 2" "down-delta2"

echo "[$(date -u +%H:%M:%S)] all cells done"
