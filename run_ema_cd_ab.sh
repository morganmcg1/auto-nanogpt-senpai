#!/usr/bin/env bash
# PR #1957: ema-decay-cooldown-schedule
# Sequential n=1 driver: Cell A_ctrl (no-op) then Cell B* (target=0.95).
# Single GPU → cells run sequentially.

set -euo pipefail

cd /workspace/senpai/target
LOG_DIR=cell_logs/ema_decay_cd
mkdir -p "$LOG_DIR"

GROUP="g1r5-thorfinn/ema-decay-cooldown"

run_cell() {
    local cell_id="$1"
    local label="$2"
    local target_flag="$3"  # may be empty
    local logfile="$LOG_DIR/cell-$cell_id-$label.log"
    local sentinel="$LOG_DIR/cell-$cell_id-$label.done"

    if [[ -f "$sentinel" ]]; then
        echo "=== SKIP cell $cell_id ($label) — sentinel exists at $sentinel ==="
        return 0
    fi

    echo "=== START cell $cell_id ($label) at $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" \
        | tee -a "$LOG_DIR/sweep_driver.log"

    {
        echo "=== START cell $cell_id ($label) at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
        # shellcheck disable=SC2086
        SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
            records/track_3_optimization/train_gpt_simple.py \
            --num_trials 1 \
            --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
            --lr_scalars 0.03 --depth_init_mode musoft \
            --lr_cooldown_shape cosine \
            --ema_eval_decay 0.99 \
            $target_flag \
            --wandb_name "g1r5-thorfinn/ema-decay-cd-$cell_id-$label" \
            --wandb_group "$GROUP"
        echo "=== END cell $cell_id ($label) at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
    } >> "$logfile" 2>&1

    touch "$sentinel"
    echo "=== END cell $cell_id ($label) at $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" \
        | tee -a "$LOG_DIR/sweep_driver.log"
}

# Cell A_ctrl: code-path no-op (--ema_decay_cooldown_target unset → constant d=0.99)
run_cell A "ctrl-noop" ""

# Cell B*: primary screen at target=0.95
run_cell B "star-target0.95" "--ema_decay_cooldown_target 0.95"

echo "=== AB SWEEP COMPLETE at $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" \
    | tee -a "$LOG_DIR/sweep_driver.log"
