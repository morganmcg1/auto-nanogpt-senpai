#!/usr/bin/env bash
# PR #1402 Arm A only — ctrl BETA=0.95 (production replication / drift gate).
set -uo pipefail

LOGDIR="beta_early_sweep_logs"
mkdir -p "$LOGDIR"
cd "$(dirname "$0")"

logf="$LOGDIR/A_ctrl-0.95.log"
echo "===== Arm A: BETA=0.95 (ctrl) =====" | tee -a "$logf"
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
NANOGPT_NEWTON_MUON_BETA=0.95 \
SENPAI_SEED=0 \
NANOGPT_TRAIN_STEPS=3350 \
torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-fern-nm-beta-early-arm-A-ctrl-0.95" \
    --wandb_group "g1r4-fern/nm-beta-early-sweep" \
    >>"$logf" 2>&1
rc=$?
date -u +"end_utc=%FT%TZ" | tee -a "$logf"
echo "exit_code=$rc" | tee -a "$logf"
exit $rc
