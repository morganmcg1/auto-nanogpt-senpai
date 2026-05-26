#!/usr/bin/env bash
# Body Muon momentum bias correction PR #1231 — 4-arm screening chain.
# Sequential on 1 GPU. Each arm: 3350 steps, single seed (SENPAI_SEED=0).
set -u  # do not -e: we want to continue the chain if a single arm errors

cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/run_logs
mkdir -p "$LOG_DIR"
CHAIN_LOG="$LOG_DIR/chain.log"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) chain start" >> "$CHAIN_LOG"

BASE=(
  NANOGPT_GRAD_CLIP=10.0 NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350
)

run_arm () {
  local arm_name=$1 ; shift
  local arm_logfile="$LOG_DIR/${arm_name}.log"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$arm_name] START" >> "$CHAIN_LOG"
  env "${BASE[@]}" "$@" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "g1r4-thorfinn/body-muon-bias-correction" \
      --wandb_name "g1r4-thorfinn/body-muon-bias-${arm_name}" \
      > "$arm_logfile" 2>&1
  local rc=$?
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$arm_name] FINISH rc=$rc" >> "$CHAIN_LOG"
  return $rc
}

run_arm armA-ctrl \
  NANOGPT_BODY_MUON_BIAS_CORRECTION=0
run_arm armB-full \
  NANOGPT_BODY_MUON_BIAS_CORRECTION=1 \
  NANOGPT_BODY_MUON_BIAS_BETA=0.95 \
  NANOGPT_BODY_MUON_BIAS_WARMUP_STEPS=0
run_arm armC-warmup100 \
  NANOGPT_BODY_MUON_BIAS_CORRECTION=1 \
  NANOGPT_BODY_MUON_BIAS_BETA=0.95 \
  NANOGPT_BODY_MUON_BIAS_WARMUP_STEPS=100
run_arm armD-beta099 \
  NANOGPT_BODY_MUON_BIAS_CORRECTION=1 \
  NANOGPT_BODY_MUON_BIAS_BETA=0.99 \
  NANOGPT_BODY_MUON_BIAS_WARMUP_STEPS=0

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) chain end" >> "$CHAIN_LOG"
