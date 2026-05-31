#!/bin/bash
# Resume chain for PR #1871: Arms B (period=1), C (period=3), D (period=4).
# Arm A already complete (val/loss=3.26323, BORDERLINE drift accepted by advisor c707).
# Uses full production stack from BASELINE.md; only NANOGPT_NEWTON_MUON_UPDATE_PERIOD varies.

set -u
cd /workspace/senpai/target

CHAIN_STATE=records/track_3_optimization/runlogs/pr1871_bcd_chain.state
echo "chain_start_utc=$(date -u +%FT%TZ)" > "$CHAIN_STATE"
echo "resume_after=A-ctrl-period2-s0 (terminal val/loss=3.26323, BORDERLINE per advisor c707)" >> "$CHAIN_STATE"

run_arm() {
    local arm_name="$1"
    local update_period="$2"
    local log_name="records/track_3_optimization/runlogs/pr1871_${arm_name}.log"

    echo "[$(date -u +%FT%TZ)] launching $arm_name (period=$update_period) -> $log_name" >> "$CHAIN_STATE"

    env -i HOME="${HOME}" PATH="${PATH}" \
        WANDB_API_KEY="${WANDB_API_KEY}" \
        WANDB_PROJECT="${WANDB_PROJECT}" \
        WANDB_ENTITY="${WANDB_ENTITY}" \
        WANDB_MODE="${WANDB_MODE}" \
        NANOGPT_NEWTON_MUON=1 \
        NANOGPT_NEWTON_MUON_UPDATE_PERIOD="$update_period" \
        NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
        NANOGPT_NEWTON_MUON_BETA=0.95 \
        NANOGPT_NEWTON_MUON_EPS=1e-4 \
        NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
        NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
        NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
        NANOGPT_GRAD_CLIP_BODY=10.0 \
        NANOGPT_GRAD_CLIP_AUX=5.0 \
        NANOGPT_NS_ITERS=12 \
        NANOGPT_NS_ITERS_COOLDOWN=16 \
        NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
        NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
        NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
        NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
        NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
        NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
        NANOGPT_ADAMW_BETA2=0.99 \
        NANOGPT_MUON_ATTN_LR_MULT=0.80 \
        NANOGPT_MUON_MLP_LR_MULT=1.20 \
        NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
        SENPAI_SEED=0 \
        torchrun --standalone --nproc_per_node=1 \
            records/track_3_optimization/train_gpt_simple.py \
            --wandb_group "g1r4-tanjiro-nm-update-period-bracket" \
            --wandb_name "$arm_name" \
            > "$log_name" 2>&1

    local rc=$?
    echo "[$(date -u +%FT%TZ)] $arm_name finished rc=$rc" >> "$CHAIN_STATE"
    sleep 30
    return $rc
}

run_arm B-period1-s0 1 || echo "[chain] Arm B nonzero rc — continuing" >> "$CHAIN_STATE"
run_arm C-period3-s0 3 || echo "[chain] Arm C nonzero rc — continuing" >> "$CHAIN_STATE"
run_arm D-period4-s0 4 || echo "[chain] Arm D nonzero rc — continuing" >> "$CHAIN_STATE"

echo "[$(date -u +%FT%TZ)] chain complete" >> "$CHAIN_STATE"
