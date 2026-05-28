#!/bin/bash
# PR #1516 — QKV orthogonal init 5-cell sweep (n=1 each)
# Cells: A=normal-ctrl, B=ortho-gain1.0-qkv, C=ortho-gain1.414-qkv,
#        D=ortho-gain0.5-qkv, E=ortho-gain1.0-qkv-and-proj
set -u
cd /workspace/senpai/target
mkdir -p screen_logs

GROUP="g1r5-nezuko/qkv-ortho-init-n1"
COMMON_ARGS="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft"

run_cell() {
    local label="$1"
    shift
    local logfile="screen_logs/qkv_ortho_${label}.log"
    echo "=== $(date -Iseconds) Starting cell ${label} ==="  | tee -a "$logfile"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        $COMMON_ARGS "$@" \
        --wandb_group "$GROUP" \
        --wandb_name "${label}" \
        >> "$logfile" 2>&1
    local status=$?
    echo "=== $(date -Iseconds) Finished cell ${label} status=${status} ==="  | tee -a "$logfile"
    return $status
}

run_cell "A-normal-ctrl"
run_cell "B-ortho-gain1.0-qkv"             --qkv_init_mode orthogonal --qkv_init_gain 1.0   --qkv_init_scope qkv_only
run_cell "C-ortho-gain1.414-qkv"           --qkv_init_mode orthogonal --qkv_init_gain 1.414 --qkv_init_scope qkv_only
run_cell "D-ortho-gain0.5-qkv"             --qkv_init_mode orthogonal --qkv_init_gain 0.5   --qkv_init_scope qkv_only
run_cell "E-ortho-gain1.0-qkv-and-proj"    --qkv_init_mode orthogonal --qkv_init_gain 1.0   --qkv_init_scope qkv_and_proj

echo "=== $(date -Iseconds) ALL CELLS DONE ===" | tee -a screen_logs/qkv_ortho_summary.log
