#!/usr/bin/env bash
# PR #1318 — Newton-Muon stack-compositionality smoke test (30 steps).
# Validates the compound arm (RESET_STEP=2345 OFF the smoke path, LATE_START_STEP=10
# triggers late window at step 11) so both mechanisms exercise their code paths
# inside a short run. Pure crash/regression smoke — NOT a scientific result.
set -u
set -o pipefail

cd /workspace/senpai/target

LOGDIR=/workspace/senpai/target/logs_pr1318_smoke
mkdir -p "$LOGDIR"

env \
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
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=1024 \
  NANOGPT_NEWTON_MUON_RESET_STEP=15 \
  NANOGPT_NEWTON_MUON_LATE_START_STEP=10 \
  NANOGPT_NEWTON_MUON_LATE_MAX_D_IN=4096 \
  SENPAI_SEED=0 \
  NANOGPT_TRAIN_STEPS=30 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_mode disabled \
    --wandb_group "g1r4-nezuko/nm-stack-compose-smoke" \
    --wandb_name "g1r4-nezuko-stackcompose-smoke" \
    >"$LOGDIR/smoke.log" 2>&1
rc=$?
echo "smoke rc=$rc"
exit $rc
