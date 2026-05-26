#!/bin/bash
# 5-cell wd_schedule pruning ablation (PR #1272)
# Each cell runs sequentially on the single GPU. Continues even if one cell fails.

set -u
LOG_DIR="/workspace/senpai/target/research/wd_schedule_pruning_run_logs"
cd /workspace/senpai/target

BASE_FLAGS="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --lr_scalars 0.03 --depth_init_mode musoft"

run_cell() {
    local letter="$1"
    local sched="$2"
    local name="wd-sched-${letter}-${sched}-n1"
    local log_path="$LOG_DIR/cell_${letter}_${sched}.log"
    echo "=== START Cell ${letter} (${sched}) at $(date -u +%FT%TZ) ===" >> "$LOG_DIR/chain.log"
    {
      echo "=== START Cell ${letter} (${sched}) at $(date -u +%FT%TZ) ==="
      SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        $BASE_FLAGS --wd_schedule "$sched" \
        --wandb_name "$name" \
        --wandb_group "g1r5-alphonse/wd-schedule-pruning"
      local rc=$?
      echo "=== END Cell ${letter} (${sched}) rc=$rc at $(date -u +%FT%TZ) ==="
    } >"$log_path" 2>&1
    local rc=$?
    echo "=== END Cell ${letter} (${sched}) rc=$rc at $(date -u +%FT%TZ) ===" >> "$LOG_DIR/chain.log"
    sleep 30
    return $rc
}

echo "[$(date -u +%FT%TZ)] Sweep started." >> "$LOG_DIR/chain.log"

run_cell A ramp_down
run_cell B constant
run_cell C ramp_up
run_cell D triangle
run_cell E cosine_updown

echo "[$(date -u +%FT%TZ)] Sweep complete." >> "$LOG_DIR/chain.log"
