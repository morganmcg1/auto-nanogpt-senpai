#!/usr/bin/env bash
# 2-arm post-#1138 compositional confirmation chain (PR #1231)
# Arm A' ctrl: Newton-Muon active, bias correction OFF (post-#1138 baseline)
# Arm C' warmup100: Newton-Muon active + bias correction warmup100
# Sequential: 1 GPU. ETA ~3.7h total.
set -euo pipefail
cd /workspace/senpai/target

mkdir -p run_logs

# Shared post-#1138 stack env (must match advisor-specified BASE exactly).
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10
export NANOGPT_NEWTON_MUON_MAX_D_IN=1024
export SENPAI_SEED=0
export NANOGPT_TRAIN_STEPS=3350

GROUP="g1r4-thorfinn/body-muon-bias-post1138-confirm"
NPROC=$(nvidia-smi -L | wc -l)

# === Arm A' ctrl: bias correction OFF ===
export NANOGPT_BODY_MUON_BIAS_CORRECTION=0
export NANOGPT_BODY_MUON_BIAS_BETA=0.95
export NANOGPT_BODY_MUON_BIAS_WARMUP_STEPS=0

echo "[$(date -Is)] Launching Arm A' ctrl (BIAS_CORRECTION=0) NM=on" | tee -a run_logs/bias_post1138_chain.log
torchrun --standalone --nproc_per_node=$NPROC \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --wandb_group "$GROUP" \
  --wandb_name "g1r4-thorfinn-bias-post1138-armA-ctrl" \
  2>&1 | tee run_logs/bias_post1138_armA_ctrl.log
echo "[$(date -Is)] Arm A' ctrl finished" | tee -a run_logs/bias_post1138_chain.log

# === Arm C' warmup100: bias correction ON, β=0.95, warmup_steps=100 ===
export NANOGPT_BODY_MUON_BIAS_CORRECTION=1
export NANOGPT_BODY_MUON_BIAS_BETA=0.95
export NANOGPT_BODY_MUON_BIAS_WARMUP_STEPS=100

echo "[$(date -Is)] Launching Arm C' warmup100 (BIAS_CORRECTION=1 β=0.95 warmup=100) NM=on" | tee -a run_logs/bias_post1138_chain.log
torchrun --standalone --nproc_per_node=$NPROC \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --wandb_group "$GROUP" \
  --wandb_name "g1r4-thorfinn-bias-post1138-armC-warmup100" \
  2>&1 | tee run_logs/bias_post1138_armC_warmup100.log
echo "[$(date -Is)] Arm C' warmup100 finished" | tee -a run_logs/bias_post1138_chain.log

echo "[$(date -Is)] CHAIN COMPLETE" | tee -a run_logs/bias_post1138_chain.log
