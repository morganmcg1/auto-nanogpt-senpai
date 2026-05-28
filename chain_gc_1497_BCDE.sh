#!/usr/bin/env bash
# PR #1497 (gradient-centralization-muon): Cells B/C/D/E sequential driver.
# Cell A is already in-flight using OLD code (= baseline reference).
# Single-runner discipline: only one torchrun active at any time.

set -u
set -o pipefail

PROBLEM_DIR="/workspace/senpai/target"
cd "$PROBLEM_DIR"

LOG_DIR="$PROBLEM_DIR/logs_gc_1497"
mkdir -p "$LOG_DIR"

DRIVER_LOG="$LOG_DIR/driver.log"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DRIVER START (PR #1497 BCDE)" >> "$DRIVER_LOG"

wait_for_clear() {
    local cell="$1"
    local waited=0
    while pgrep -f "train_gpt_simple" > /dev/null; do
        sleep 10
        waited=$((waited + 10))
        if [ $waited -gt 14400 ]; then
            echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $cell: timeout waiting for clear after ${waited}s" >> "$DRIVER_LOG"
            return 1
        fi
    done
    sleep 20  # settle window
    return 0
}

run_cell() {
    local cell_id="$1"; shift
    local short_name="$1"; shift
    local extra_flags="$1"; shift

    local log_file="$LOG_DIR/cell_${cell_id}_${short_name}.log"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] LAUNCH Cell $cell_id ($short_name): flags=[$extra_flags]" >> "$DRIVER_LOG"

    if pgrep -f "train_gpt_simple" > /dev/null; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ABORT: training process already running before Cell $cell_id" >> "$DRIVER_LOG"
        return 1
    fi

    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --ns_iter 6 --soap_attn \
        --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft \
        $extra_flags \
        --wandb_name "gc-cell${cell_id}-${short_name}-n1" \
        --wandb_group "g1r5-tanjiro/gradient-centralization-muon" \
        > "$log_file" 2>&1
    local rc=$?
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DONE Cell $cell_id ($short_name): rc=$rc" >> "$DRIVER_LOG"
    return $rc
}

# Wait for in-flight Cell A (OLD code, baseline) to finish first
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Waiting for in-flight Cell A to clear" >> "$DRIVER_LOG"
wait_for_clear "pre-B-wait"

# Smoke test: 50 steps of NEW code with --use_gc on, --gc_dim 0
# Goal: verify wiring doesn't crash; ratio/norm logging works; loss decreases.
# Logs to logs_gc_1497/smoke_B50.log; not a fail gate, just a sanity gate.
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] LAUNCH SMOKE B50 (50 steps, GC on)" >> "$DRIVER_LOG"
SENPAI_TRAIN_STEPS=50 timeout 600 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn \
    --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --use_gc --gc_dim 0 \
    --wandb_mode disabled \
    > "$LOG_DIR/smoke_B50.log" 2>&1
SMOKE_RC=$?
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SMOKE B50 done: rc=$SMOKE_RC" >> "$DRIVER_LOG"
if [ $SMOKE_RC -ne 0 ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ABORT: smoke failed" >> "$DRIVER_LOG"
    exit 1
fi
wait_for_clear "post-smoke"

# Cell B PRIMARY — paper-default row-mean centering (per-output, mean over fan-in)
# Implementation: gc_dim=0 maps to grad.mean(dim=1, keepdim=True) for shape (out, in)
run_cell "B" "row-dim0"  "--use_gc --gc_dim 0"
wait_for_clear "B"

# Cell C — col-mean centering (per-input, mean over fan-out) ablation
run_cell "C" "col-dim1"  "--use_gc --gc_dim 1"
wait_for_clear "C"

# Cell D — body + aux scope (row-mean, also applied to AdamW 2D aux: embed + lm_head)
run_cell "D" "row-aux"   "--use_gc --gc_dim 0 --gc_aux"
wait_for_clear "D"

# Cell E (FALSIFIER) — 10× over-correction on row-mean
run_cell "E" "row-x10"   "--use_gc --gc_dim 0 --gc_scale 10.0"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DRIVER END" >> "$DRIVER_LOG"
