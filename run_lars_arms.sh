#!/usr/bin/env bash
# Sequential 4-arm screening for PR #755: LARS-style trust-ratio LR scaling on body Muon.
# All other envs locked to the post-#579 merged stack. Seed via Python random_seed inside the script.
set -euo pipefail

cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/logs_lars
mkdir -p "$LOG_DIR"

WANDB_GROUP="g1r4-askeladd/lars-trust-ratio-muon"

run_arm() {
    local arm_label="$1"
    local enable="$2"
    local lo="$3"
    local hi="$4"
    local ema="$5"
    local log_file="${LOG_DIR}/arm_${arm_label}.log"

    echo "==== START arm=${arm_label} enable=${enable} lo=${lo} hi=${hi} ema=${ema} at $(date -Iseconds) ===="

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
    NANOGPT_LARS_MUON_ENABLE="${enable}" \
    NANOGPT_LARS_MUON_LO="${lo}" \
    NANOGPT_LARS_MUON_HI="${hi}" \
    NANOGPT_LARS_MUON_EMA="${ema}" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r4-askeladd/lars-arm-${arm_label}" \
      --wandb_group "${WANDB_GROUP}" \
      > "${log_file}" 2>&1

    echo "==== END arm=${arm_label} at $(date -Iseconds) ===="
}

# Arm A: control (LARS off — bit-identical to merged-stack baseline)
run_arm A 0 0.5 2.0 0.0
# Arm B: LARS-vanilla, moderate clamp [0.5, 2.0], no EMA
run_arm B 1 0.5 2.0 0.0
# Arm C: LARS-vanilla, wider clamp [0.25, 4.0], no EMA
run_arm C 1 0.25 4.0 0.0
# Arm D: LARS-EMA, moderate clamp [0.5, 2.0], β=0.9 smoothing
run_arm D 1 0.5 2.0 0.9

echo "==== ALL ARMS DONE at $(date -Iseconds) ===="
