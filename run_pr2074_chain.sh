#!/bin/bash
# PR #2074: NM ambient UPDATE_PERIOD coverage bracket — 3-arm sequential chain.
# Arm A: UPDATE_PERIOD=2 (production ctrl)
# Arm B: UPDATE_PERIOD=3 (less coverage, ~33% fewer eigendecomps)
# Arm C: UPDATE_PERIOD=5 (much less coverage, ~60% fewer eigendecomps)
# SEED=0 fixed all 3 arms. ETA ~2-2.5h per arm (Arm A baseline).
# Env stack matches cited production baselines (7rv6w59o/490zzk6d/14yhwpw5/88ufv1qt/ezzg4pl4):
#   NS_ITERS_COOLDOWN=16, NS_STOCHASTIC_COOLDOWN=2, EMBED_INIT_ANCHOR_LAMBDA=0.001,
#   GRAD_CLIP=0 with BODY=10/AUX=5. These were missing from the PR Arm A spec block
#   but are present in all cited W&B baseline runs; using full prod stack so Arm A
#   bit-reproduces the cited baseline (flagged to advisor in PR comment).
set -uo pipefail
LOG_DIR=/workspace/senpai/target/logs_pr2074_nm_period_bracket
cd /workspace/senpai/target
mkdir -p "$LOG_DIR"
echo "$(date -Is) chain started" >> "$LOG_DIR/chain.log"

# Production stack (matches cited W&B refs). UPDATE_PERIOD set per-arm below.
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=0.0001
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_GRAD_CLIP=0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export SENPAI_SEED=0

run_arm () {
    local label="$1" period="$2"
    echo "$(date -Is) starting arm $label UPDATE_PERIOD=$period" >> "$LOG_DIR/chain.log"
    export NANOGPT_NEWTON_MUON_UPDATE_PERIOD="$period"
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --wandb_group g1r4-askeladd/nm-ambient-update-period-coverage-bracket \
        --wandb_name "g1r4-askeladd/nm-period-arm${label}-p${period}-s0" \
        > "$LOG_DIR/arm_${label}.log" 2>&1
    local rc=$?
    echo "$(date -Is) arm $label exit=$rc" >> "$LOG_DIR/chain.log"
    return $rc
}

# Sequential: A (PERIOD=2 ctrl) → B (PERIOD=3) → C (PERIOD=5)
run_arm "A" 2
sleep 5
run_arm "B" 3
sleep 5
run_arm "C" 5

echo "$(date -Is) chain complete" >> "$LOG_DIR/chain.log"
