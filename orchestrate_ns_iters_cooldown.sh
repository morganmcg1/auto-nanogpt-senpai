#!/usr/bin/env bash
# Orchestrator for PR #1768 — class 31 NM-NS-ITERS-COOLDOWN-INTENSITY.
# 3 arms sequential, N=1, SENPAI_SEED=0, group g1r4-fern/nm-ns-iters-cooldown-intensity.
#   Arm A: NS_ITERS_COOLDOWN=16 (ctrl = production stack)
#   Arm B: NS_ITERS_COOLDOWN=12 (pruning ablation = no cooldown boost)
#   Arm C: NS_ITERS_COOLDOWN=20 (intensity amplify)
set -uo pipefail

LOGDIR="/workspace/senpai/target/nm_ns_iters_cooldown_logs"
mkdir -p "$LOGDIR"

run_arm() {
    local short_name="$1"          # filesystem-safe log label
    local wandb_name="$2"           # full wandb name (with slash)
    local ns_cooldown="$3"
    local logf="$LOGDIR/${short_name}.log"
    echo "[$(date -Iseconds)] START $short_name NS_ITERS_COOLDOWN=$ns_cooldown wandb=$wandb_name" | tee -a "$LOGDIR/orchestrator.log"
    SENPAI_SEED=0 \
    NANOGPT_NEWTON_MUON=1 \
    NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
    NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
    NANOGPT_NEWTON_MUON_BETA=0.95 \
    NANOGPT_NEWTON_MUON_EPS=1e-4 \
    NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
    NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
    NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN="$ns_cooldown" NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "g1r4-fern/nm-ns-iters-cooldown-intensity" \
      --wandb_name "$wandb_name" \
      > "$logf" 2>&1
    local rc=$?
    echo "[$(date -Iseconds)] END   $short_name rc=$rc" | tee -a "$LOGDIR/orchestrator.log"
    return $rc
}

run_arm armA-ns_cooldown16-ctrl-s0       "g1r4-fern/armA-ns_cooldown16-ctrl-s0"       16
run_arm armB-ns_cooldown12-pruning-s0    "g1r4-fern/armB-ns_cooldown12-pruning-s0"    12
run_arm armC-ns_cooldown20-intensify-s0  "g1r4-fern/armC-ns_cooldown20-intensify-s0"  20

echo "[$(date -Iseconds)] ALL ARMS DONE" | tee -a "$LOGDIR/orchestrator.log"
