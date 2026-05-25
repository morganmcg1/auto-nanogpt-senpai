#!/bin/bash
# AdaBelief aux groups sweep daemon — chains cells B → C → D → E after Cell A completes.
# Cell A is already running externally; this daemon waits for its PID to exit, then runs each cell sequentially.
# Each cell uses 3250 steps, ~6200s wall, ~1.7h. Total runtime: ~7h after A finishes.

set -u
LOG_DIR="/workspace/senpai/target/research/adabelief_aux_run_logs"
WORK_DIR="/workspace/senpai/target"
DAEMON_LOG="$LOG_DIR/sweep_daemon.log"
STATE_DIR="$LOG_DIR/state"
mkdir -p "$STATE_DIR"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: starting, pid=$$" >> "$DAEMON_LOG"
echo "$$" > "$LOG_DIR/sweep_daemon.pid"

cd "$WORK_DIR"

# Cell A PID — wait for it to exit
CELL_A_PID="${1:-337176}"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: waiting for cell A (pid=$CELL_A_PID)..." >> "$DAEMON_LOG"
while kill -0 "$CELL_A_PID" 2>/dev/null; do
    sleep 30
done
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: cell A exited" >> "$DAEMON_LOG"
echo "DONE" > "$STATE_DIR/cellA.state"

# Common torchrun args
COMMON="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-alphonse/adabelief-aux"

run_cell() {
    local cell="$1"; local label="$2"; local extra="$3"
    local logfile="$LOG_DIR/cell${cell}.log"
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: launching cell $cell ($label) -> $logfile" >> "$DAEMON_LOG"
    echo "RUNNING" > "$STATE_DIR/cell${cell}.state"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        $COMMON $extra \
        --wandb_group "$GROUP" \
        --wandb_name "g1r5-alphonse/adabelief_${cell}_${label}" \
        > "$logfile" 2>&1
    local rc=$?
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: cell $cell finished rc=$rc" >> "$DAEMON_LOG"
    echo "DONE rc=$rc" > "$STATE_DIR/cell${cell}.state"
}

# Cell B PRIMARY: AdaBelief eps=1e-10
run_cell "B" "belief_eps1e-10_primary" "--use_adabelief --adam_eps 1e-10"

# Cell C: AdaBelief eps=1e-16
run_cell "C" "belief_eps1e-16_paperdefault" "--use_adabelief --adam_eps 1e-16"

# Cell D: AdaBelief eps=1e-8
run_cell "D" "belief_eps1e-8_loose" "--use_adabelief --adam_eps 1e-8"

# Cell E FALSIFIER: AdamW eps=1e-16
run_cell "E" "adamw_eps1e-16_falsifier" "--adam_eps 1e-16"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') daemon: all cells complete" >> "$DAEMON_LOG"
touch "$STATE_DIR/all_done"
