#!/bin/bash
# Per-block-DEPTH body Muon LR asymmetry — 4-arm screening for PR #753.
# Each arm runs once on top of the merged-stack baseline (post-#579).
# Arm A: control uniform (1.0/1.0/1.0).
# Arm B: front-loaded (early=1.20, mid=1.00, deep=0.80) — primary winner candidate.
# Arm C: back-loaded  (early=0.80, mid=1.00, deep=1.20) — directional control.
# Arm D: mid-heavy    (early=0.90, mid=1.20, deep=0.90) — directional control.
set -uo pipefail

LOGDIR="_logs/g1r4-edward-per-depth-lr"
mkdir -p "$LOGDIR"

run_arm() {
    local arm_letter="$1"
    local early_mult="$2"
    local mid_mult="$3"
    local deep_mult="$4"
    local logf="$LOGDIR/arm-${arm_letter}.log"
    echo "===== Arm $arm_letter: early=$early_mult mid=$mid_mult deep=$deep_mult =====" | tee -a "$logf"
    date -u +"start_utc=%FT%TZ" | tee -a "$logf"
    NANOGPT_GRAD_CLIP=10.0 \
    NANOGPT_NS_ITERS=12 \
    NANOGPT_NS_ITERS_COOLDOWN=16 \
    NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 \
    NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    NANOGPT_MUON_ATTN_LR_MULT=0.80 \
    NANOGPT_MUON_MLP_LR_MULT=1.20 \
    NANOGPT_MUON_EARLY_LR_MULT="$early_mult" \
    NANOGPT_MUON_MID_LR_MULT="$mid_mult" \
    NANOGPT_MUON_DEEP_LR_MULT="$deep_mult" \
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_name "g1r4-edward/per-depth-lr-arm-${arm_letter}" \
        --wandb_group "g1r4-edward/per-depth-muon-lr" \
        >>"$logf" 2>&1
    local rc=$?
    date -u +"end_utc=%FT%TZ" | tee -a "$logf"
    echo "exit_code=$rc" | tee -a "$logf"
    return $rc
}

run_arm A 1.00 1.00 1.00
run_arm B 1.20 1.00 0.80
run_arm C 0.80 1.00 1.20
run_arm D 0.90 1.20 0.90

echo "All arms completed (or one failed)."
