#!/bin/bash
# Chain runner for PR #1871: NM update_period bidirectional bracket {1,2,3,4}.
# 4 arms with full production stack; only NANOGPT_NEWTON_MUON_UPDATE_PERIOD varies.
# Arm A (period=2, ctrl) -> Arm B (period=1) -> Arm C (period=3) -> Arm D (period=4).
# Stop after Arm A if drift gate fails (Arm A val/loss outside [3.2597, 3.2627]).

set -u
cd /workspace/senpai/target

CHAIN_STATE=records/track_3_optimization/runlogs/pr1871_chain.state
echo "chain_start_utc=$(date -u +%FT%TZ)" > "$CHAIN_STATE"

DRIFT_LO=3.2597
DRIFT_HI=3.2627

run_arm() {
    local arm_name="$1"          # e.g. A-ctrl-period2-s0
    local update_period="$2"     # 1 | 2 | 3 | 4
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
    # Grace period between arms for CUDA teardown
    sleep 30
    return $rc
}

check_arm_a_drift_gate() {
    local log_name="records/track_3_optimization/runlogs/pr1871_A-ctrl-period2-s0.log"
    local final_val_loss
    final_val_loss=$(grep -oE "best_val_loss:[0-9.]+" "$log_name" | tail -1 | sed 's/best_val_loss://')
    if [[ -z "$final_val_loss" ]]; then
        echo "[$(date -u +%FT%TZ)] drift_gate: NO val/loss found in $log_name (run likely crashed)" >> "$CHAIN_STATE"
        return 1
    fi
    echo "[$(date -u +%FT%TZ)] drift_gate: arm_A val/loss=$final_val_loss (gate [$DRIFT_LO, $DRIFT_HI])" >> "$CHAIN_STATE"
    # bc float comparison
    local in_gate
    in_gate=$(awk -v v="$final_val_loss" -v lo="$DRIFT_LO" -v hi="$DRIFT_HI" 'BEGIN { print (v >= lo && v <= hi) ? "1" : "0" }')
    if [[ "$in_gate" == "1" ]]; then
        echo "[$(date -u +%FT%TZ)] drift_gate: PASS — continuing to Arms B/C/D" >> "$CHAIN_STATE"
        return 0
    else
        echo "[$(date -u +%FT%TZ)] drift_gate: FAIL — stopping chain, HB needed" >> "$CHAIN_STATE"
        return 1
    fi
}

# Arm A (ctrl, period=2)
run_arm A-ctrl-period2-s0 2 || echo "[chain] Arm A nonzero rc — continuing for diagnostics" >> "$CHAIN_STATE"

# Drift gate check before launching remaining arms
if check_arm_a_drift_gate; then
    run_arm B-period1-s0 1 || echo "[chain] Arm B nonzero rc — continuing" >> "$CHAIN_STATE"
    run_arm C-period3-s0 3 || echo "[chain] Arm C nonzero rc — continuing" >> "$CHAIN_STATE"
    run_arm D-period4-s0 4 || echo "[chain] Arm D nonzero rc — continuing" >> "$CHAIN_STATE"
else
    echo "[$(date -u +%FT%TZ)] chain stopped after Arm A drift gate failure" >> "$CHAIN_STATE"
fi

echo "[$(date -u +%FT%TZ)] chain complete" >> "$CHAIN_STATE"
