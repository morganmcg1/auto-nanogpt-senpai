#!/bin/bash
# Run the 4 arms of the Muon attn-vs-mlp momentum asymmetry sweep sequentially.
# Each arm writes its log to logs_muon_attn_mlp_momentum_asym/<arm>.log and produces a
# small summary file with the W&B run ID and val/loss for quick lookup.
set -uo pipefail

LOGDIR="logs_muon_attn_mlp_momentum_asym"
mkdir -p "$LOGDIR"

run_arm() {
    local arm_letter="$1"
    local short_tag="$2"
    local attn_mu="$3"
    local mlp_mu="$4"
    local logf="$LOGDIR/${arm_letter}_${short_tag}.log"
    echo "===== Arm $arm_letter: attn_mu=$attn_mu mlp_mu=$mlp_mu =====" | tee -a "$logf"
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
    NANOGPT_MUON_ATTN_MU="$attn_mu" \
    NANOGPT_MUON_MLP_MU="$mlp_mu" \
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_name "g1r4-edward/muon-attn-mlp-momentum-${arm_letter}-${short_tag}" \
        --wandb_group "g1r4-edward/muon-attn-mlp-momentum-asym" \
        >>"$logf" 2>&1
    local rc=$?
    date -u +"end_utc=%FT%TZ" | tee -a "$logf"
    echo "exit_code=$rc" | tee -a "$logf"
    return $rc
}

# Arm A (control): both mu=0.95 — bit-identical to merged baseline.
run_arm A control     0.95 0.95
# Arm B: attn faster-tracking (mu=0.90), mlp uniform (mu=0.95).
run_arm B attn090     0.90 0.95
# Arm C: attn uniform (mu=0.95), mlp slower-tracking (mu=0.99).
run_arm C mlp099      0.95 0.99
# Arm D: compound (attn=0.90, mlp=0.99).
run_arm D attn090-mlp099 0.90 0.99

echo "All arms completed."
