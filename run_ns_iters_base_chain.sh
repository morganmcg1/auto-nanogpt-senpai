#!/bin/bash
# PR #2125: NS_ITERS base fine bracket {10, 12 ctrl, 14}
# 3-arm sequential single-pod chain on auto-nanogpt-1gpu-r4.
# Only NANOGPT_NS_ITERS varies per arm; everything else = post-#1702 production stack.
set -uo pipefail

cd /workspace/senpai/target

LOGDIR="/workspace/senpai/target/logs_ns_iters_base_bracket"
mkdir -p "$LOGDIR"

# Production stack env vars (post-#1702, current best on auto-nanogpt-1gpu-r4)
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export SENPAI_SEED=0

run_arm() {
    local label="$1"
    local ns_iters="$2"
    local log="$LOGDIR/arm_${label}.log"

    echo "[$(date -u +%FT%TZ)] ARM ${label} START NS_ITERS=${ns_iters}" | tee -a "$LOGDIR/chain.log"

    NANOGPT_NS_ITERS="$ns_iters" \
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_project modded-nanogpt-senpai \
        --wandb_group "askeladd-ns-iters-base-bracket" \
        --wandb_name "g1r4-askeladd/ns-iters-base-${label}-ns${ns_iters}" \
        > "$log" 2>&1
    local rc=$?
    echo "[$(date -u +%FT%TZ)] ARM ${label} END exit=$rc" | tee -a "$LOGDIR/chain.log"
    return $rc
}

# Arm A: ctrl, NS_ITERS=12 (production)
run_arm "A_ctrl_ns12" 12
sleep 5

# Arm B: NS_ITERS=10
run_arm "B_ns10" 10
sleep 5

# Arm C: NS_ITERS=14
run_arm "C_ns14" 14

echo "[$(date -u +%FT%TZ)] CHAIN COMPLETE" | tee -a "$LOGDIR/chain.log"
