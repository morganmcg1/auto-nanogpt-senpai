#!/usr/bin/env bash
# 5-cell AdaBelief-on-aux sweep for PR #1500.
# A=control (no AdaBelief), B=all, C=scalars, D=lm_head, E=embed.
# Each cell: n=1, 3250 steps, sequential.

set -uo pipefail
cd "$(dirname "$0")"

LOG_DIR="runs/g1r5-fern/adabelief-aux"
mkdir -p "$LOG_DIR"

run_cell () {
    local letter="$1"
    local scope_arg="$2"   # empty for control; otherwise "--use_adabelief --adabelief_scope X"
    local tag="$3"
    local log="$LOG_DIR/cell${letter}_${tag}.log"
    echo "=== Cell ${letter} (${tag}) → ${log} === $(date -Is)"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft \
        ${scope_arg} \
        --wandb_name "g1r5-fern/adabelief-cell${letter}-${tag}-n1" \
        --wandb_group "g1r5-fern/adabelief-aux" \
        > "$log" 2>&1
    local rc=$?
    echo "=== Cell ${letter} done rc=${rc} === $(date -Is)"
    return $rc
}

run_cell A ""                                          ctrl       || echo "cellA failed"
run_cell B "--use_adabelief --adabelief_scope all"     scope-all  || echo "cellB failed"
run_cell C "--use_adabelief --adabelief_scope scalars" scope-scalars || echo "cellC failed"
run_cell D "--use_adabelief --adabelief_scope lm_head" scope-lmhead || echo "cellD failed"
run_cell E "--use_adabelief --adabelief_scope embed"   scope-embed || echo "cellE failed"

echo "=== SWEEP COMPLETE === $(date -Is)"
