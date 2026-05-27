#!/usr/bin/env bash
# PR #1402: NM β EARLY constant sweep — 4 arms sequential, A → B → C → D.
# Rebased on post-#1240 merged stack.
# Arm A ctrl: BETA=0.95 (production), Arm B: 0.90, Arm C: 0.97, Arm D: 0.99.
# NOTE: Do not override NANOGPT_NEWTON_MUON_EPS — use script default 1e-4.
set -uo pipefail

LOGDIR="beta_early_sweep_logs"
mkdir -p "$LOGDIR"
cd "$(dirname "$0")"

NPROC=$(nvidia-smi -L | wc -l)

run_arm() {
    local arm_letter="$1"
    local short_tag="$2"
    local beta="$3"
    local logf="$LOGDIR/${arm_letter}_${short_tag}.log"
    echo "===== Arm $arm_letter: BETA=$beta =====" | tee -a "$logf"
    date -u +"start_utc=%FT%TZ" | tee -a "$logf"
    NANOGPT_GRAD_CLIP=10.0 \
    NANOGPT_GRAD_CLIP_BODY=10.0 \
    NANOGPT_GRAD_CLIP_AUX=5.0 \
    NANOGPT_NS_ITERS=12 \
    NANOGPT_NS_ITERS_COOLDOWN=16 \
    NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 \
    NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    NANOGPT_MUON_ATTN_LR_MULT=0.80 \
    NANOGPT_MUON_MLP_LR_MULT=1.20 \
    NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
    NANOGPT_NEWTON_MUON=1 \
    NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
    NANOGPT_NEWTON_MUON_UPDATE_PERIOD=5 \
    NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
    NANOGPT_NEWTON_MUON_BETA="$beta" \
    SENPAI_SEED=0 \
    NANOGPT_TRAIN_STEPS=3350 \
    torchrun --standalone --nproc_per_node="${NPROC}" \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_name "g1r4-fern-nm-beta-early-arm-${arm_letter}-${short_tag}" \
        --wandb_group "g1r4-fern/nm-beta-early-sweep" \
        >>"$logf" 2>&1
    local rc=$?
    date -u +"end_utc=%FT%TZ" | tee -a "$logf"
    echo "exit_code=$rc" | tee -a "$logf"
    return $rc
}

# Sequential single-GPU chain. If any arm fails we still continue the chain
# so partial results are captured; rc per-arm is logged.
run_arm A ctrl-0.95   0.95
run_arm B faster-0.90 0.90
run_arm C slower-0.97 0.97
run_arm D much-slower-0.99 0.99

echo "[$(date -Is)] All beta-early arms complete." | tee -a "$LOGDIR/dispatcher.log"
