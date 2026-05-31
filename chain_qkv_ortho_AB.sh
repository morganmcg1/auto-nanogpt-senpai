#!/bin/bash
# Chain script for QKV ortho init Cells A_ctrl + B*, sequential on 1 GPU.
# Cell A_ctrl: mandatory stack only, code-split sanity (no --qkv_ortho_init).
# Cell B*: same stack + --qkv_ortho_init (default mode qkv).
set -u
cd /workspace/senpai/target

LOGDIR=logs_qkv_ortho_v2
mkdir -p "$LOGDIR"
CHAIN_LOG="$LOGDIR/chain.log"

run_cell () {
    local label="$1"
    shift
    local name="g1r5-tanjiro/qkv-ortho-${label}-n1"
    local log="$LOGDIR/cell${label}.log"
    local pidfile="$LOGDIR/cell${label}.pid"
    echo "=== START cell $label $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$CHAIN_LOG"
    echo "extra args: $*" | tee -a "$CHAIN_LOG"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft \
        --lr_cooldown_shape cosine \
        --ema_eval_decay 0.99 \
        "$@" \
        --wandb_name "$name" \
        --wandb_group "g1r5-tanjiro/qkv-ortho-init" \
        > "$log" 2>&1 &
    local pid=$!
    echo "$pid" > "$pidfile"
    wait "$pid"
    local rc=$?
    echo "=== END   cell $label rc=$rc $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$CHAIN_LOG"
}

run_cell "A_ctrl"
run_cell "Bstar"  --qkv_ortho_init

echo "=== CHAIN COMPLETE $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$CHAIN_LOG"
