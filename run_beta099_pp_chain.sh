#!/usr/bin/env bash
# PP-promote n=3 paired-pod chain for PR #1447: NM BETA=0.99 EARLY constant.
# 6 interleaved sequential runs: ctrl(BETA=0.95) and arm(BETA=0.99) for seeds 0,1,2.
set -euo pipefail

cd /workspace/senpai/target

LOG_DIR="/workspace/senpai/target/nm_beta099_pp_logs"
mkdir -p "$LOG_DIR"

# Production post-#1240 stack (identical for all 6 runs except BETA and SENPAI_SEED).
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=5
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_TRAIN_STEPS=3350

GROUP="g1r4-fern/nm-beta099-pp-promote"

run_one() {
    local seed="$1"
    local arm="$2"     # "ctrl" or "arm"
    local beta="$3"
    local logfile="$LOG_DIR/${arm}_beta${beta//./}_seed${seed}.log"
    local name="g1r4-fern-nm-beta099-pp-${arm}-beta${beta//./}-seed${seed}"
    echo "=========================================="
    echo "[$(date -u +%H:%M:%S)] Starting ${arm} seed=${seed} BETA=${beta}"
    echo "  log: ${logfile}"
    echo "  wandb name: ${name}"
    echo "=========================================="
    NANOGPT_NEWTON_MUON_BETA="$beta" \
    SENPAI_SEED="$seed" \
        torchrun --standalone --nproc_per_node=1 \
            records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
            --wandb_name "$name" \
            --wandb_group "$GROUP" \
            > "$logfile" 2>&1
    local exit_code=$?
    echo "[$(date -u +%H:%M:%S)] ${arm} seed=${seed} BETA=${beta} exit=${exit_code}"
    return $exit_code
}

# Interleaved 6-run chain: ctrl ↔ arm alternating across seeds 0,1,2.
run_one 0 ctrl 0.95
run_one 0 arm  0.99
run_one 1 ctrl 0.95
run_one 1 arm  0.99
run_one 2 ctrl 0.95
run_one 2 arm  0.99

echo "=========================================="
echo "[$(date -u +%H:%M:%S)] All 6 runs complete"
echo "=========================================="
