#!/bin/bash
# Run the 4 arms of the Muon attn-vs-mlp LR asymmetry sweep sequentially.
# Each arm writes its log to logs_muon_attn_mlp_lr_asym/<arm>.log and produces a
# small summary file with the W&B run ID and val/loss for quick lookup.
set -uo pipefail

LOGDIR="logs_muon_attn_mlp_lr_asym"
mkdir -p "$LOGDIR"

run_arm() {
    local arm_letter="$1"
    local short_tag="$2"
    local attn_mult="$3"
    local mlp_mult="$4"
    local logf="$LOGDIR/${arm_letter}_${short_tag}.log"
    echo "===== Arm $arm_letter: attn_mult=$attn_mult mlp_mult=$mlp_mult =====" | tee -a "$logf"
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
    NANOGPT_MUON_ATTN_LR_MULT="$attn_mult" \
    NANOGPT_MUON_MLP_LR_MULT="$mlp_mult" \
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_name "g1r4-askeladd/muon-attn-mlp-lr-asym-${arm_letter}-${short_tag}" \
        --wandb_group "g1r4-askeladd/muon-attn-mlp-lr-asym" \
        >>"$logf" 2>&1
    local rc=$?
    date -u +"end_utc=%FT%TZ" | tee -a "$logf"
    echo "exit_code=$rc" | tee -a "$logf"
    return $rc
}

# Arm A (control): both multipliers 1.0 — bit-identical to single-group baseline.
run_arm A control     1.00 1.00 && \
# Arm B: attn LR -20%.
run_arm B attn80      0.80 1.00 && \
# Arm C: mlp LR +20%.
run_arm C mlp120      1.00 1.20 && \
# Arm D: compound (attn -20%, mlp +20%).
run_arm D attn80-mlp120 0.80 1.20

echo "All arms completed (or one failed)."
