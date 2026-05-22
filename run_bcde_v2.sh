#!/usr/bin/env bash
# Sequential runner for PR #773 adaptive-mu-cossim cells B → C → D → E.
# Assumes Cell A has already finished. Launches one cell at a time and
# captures the launching PID so we can `wait` on it safely.

set -uo pipefail
cd "$(dirname "$0")"

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
WATCHER_LOG="$LOG_DIR/bcde_v2_watcher.log"

log() {
    echo "[$(date -Is)] $*" | tee -a "$WATCHER_LOG"
}

run_cell () {
    local letter="$1"        # B, C, D, E
    local alpha="$2"         # 0.02, 0.05, 0.10, -0.05
    local tag="$3"           # B-alpha002 etc.
    local cell_log="$LOG_DIR/cell_${letter}_v2.log"
    local pidf="$LOG_DIR/cell_${letter}_v2.pid"

    log "=== Cell ${letter} alpha=${alpha} -> ${cell_log} ==="

    SENPAI_TRAIN_STEPS=3250 nohup torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --ns_iter 6 --lr_scalars 0.03 \
        --mu_adaptive_alpha "${alpha}" \
        --wandb_name "fern-adaptive-mu-${tag}-n1" \
        --wandb_group "g1r5-fern/adaptive-mu-cossim" \
        > "$cell_log" 2>&1 &
    local pid=$!
    echo "$pid" > "$pidf"
    log "Cell ${letter} torchrun pid=${pid}"

    # Wait for this specific PID to finish.
    wait "$pid"
    local rc=$?
    log "=== Cell ${letter} done rc=${rc} ==="
    return $rc
}

log "=== adaptive-mu B/C/D/E v2 watcher starting (Cell A already complete) ==="

run_cell B  0.02   B-alpha002              || log "cellB rc!=0 (continuing)"
run_cell C  0.05   C-alpha005-primary      || log "cellC rc!=0 (continuing)"
run_cell D  0.10   D-alpha010-large        || log "cellD rc!=0 (continuing)"
run_cell E  -0.05  E-alphaneg005-falsifier || log "cellE rc!=0 (continuing)"

log "=== adaptive-mu B/C/D/E v2 watcher all done ==="
