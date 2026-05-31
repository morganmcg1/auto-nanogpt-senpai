#!/bin/bash
# Chain runner for PR #1971 NS_COOLDOWN_SHAPE post-NM validation bracket.
# 3-arm fresh-mechanism schedule-axis sweep at SENPAI_SEED=0 (single-seed chain).
# Arms: A=late_peak (production), B=step (constant NS=16), C=linear_ramp (12->20).
# Full production stack from BASELINE.md #1702 verbatim, only NS_COOLDOWN_SHAPE varies.

set -u
cd /workspace/senpai/target

CHAIN_STATE=records/track_3_optimization/runlogs/pr1971_chain.state
echo "chain_start_utc=$(date -u +%FT%TZ)" > "$CHAIN_STATE"

GROUP="g1r4-tanjiro-ns-cooldown-shape-post-nm"

run_arm() {
    local arm_label="$1"
    local shape="$2"
    local run_name="ns-shape-${shape}-s0"
    local log_name="records/track_3_optimization/runlogs/pr1971_arm${arm_label}_${shape}_s0.log"

    echo "[$(date -u +%FT%TZ)] launching ARM=${arm_label} SHAPE=${shape} -> ${log_name}" >> "$CHAIN_STATE"

    env -i HOME="${HOME}" PATH="${PATH}" \
        WANDB_API_KEY="${WANDB_API_KEY}" \
        WANDB_PROJECT="${WANDB_PROJECT}" \
        WANDB_ENTITY="${WANDB_ENTITY}" \
        WANDB_MODE="${WANDB_MODE}" \
        NANOGPT_NEWTON_MUON=1 \
        NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
        NANOGPT_NEWTON_MUON_BETA=0.95 \
        NANOGPT_NEWTON_MUON_EPS=1e-4 \
        NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
        NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
        NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
        NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
        NANOGPT_NS_ITERS=12 \
        NANOGPT_NS_ITERS_COOLDOWN=16 \
        NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
        NANOGPT_NS_COOLDOWN_SHAPE="${shape}" \
        NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
        NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
        NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
        NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
        NANOGPT_ADAMW_BETA2=0.99 \
        NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
        NANOGPT_MUON_ATTN_LR_MULT=0.80 \
        NANOGPT_MUON_MLP_LR_MULT=1.20 \
        NANOGPT_GRAD_CLIP_BODY=10 \
        NANOGPT_GRAD_CLIP_AUX=5 \
        SENPAI_SEED=0 \
        torchrun --standalone --nproc_per_node=1 \
            records/track_3_optimization/train_gpt_simple.py \
            --wandb_group "${GROUP}" \
            --wandb_name "g1r4-tanjiro/${run_name}" \
            > "${log_name}" 2>&1

    local rc=$?
    echo "[$(date -u +%FT%TZ)] ARM=${arm_label} SHAPE=${shape} finished rc=${rc}" >> "$CHAIN_STATE"
    sleep 30
    return $rc
}

# Arm A: late_peak (production control)
run_arm A late_peak || echo "[chain] ARM=A nonzero rc — continuing" >> "$CHAIN_STATE"
# Arm B: step (constant NS=16)
run_arm B step || echo "[chain] ARM=B nonzero rc — continuing" >> "$CHAIN_STATE"
# Arm C: linear_ramp (12 -> 20)
run_arm C linear_ramp || echo "[chain] ARM=C nonzero rc — continuing" >> "$CHAIN_STATE"

echo "[$(date -u +%FT%TZ)] chain complete" >> "$CHAIN_STATE"
