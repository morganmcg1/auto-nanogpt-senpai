#!/usr/bin/env bash
# Chain runner for PR #1567 NM R-buffer freeze-after-K ablation.
# 4-arm sweep over NANOGPT_NEWTON_MUON_FREEZE_R_AFTER in {0, 500, 1675, 2680}.
# Single seed (SENPAI_SEED=0), post-#1421 production stack (UPDATE_PERIOD=2,
# MAX_D_IN=4096). 3350 train steps per arm. Sequential on 1 GPU.
set -uo pipefail
cd "$(dirname "$0")"

ARMS=(A B C D)
declare -A FREEZE_K
FREEZE_K[A]=0
FREEZE_K[B]=500
FREEZE_K[C]=1675
FREEZE_K[D]=2680

declare -A NAME
NAME[A]=g1r4-alphonse-armA-ctrl-freeze0
NAME[B]=g1r4-alphonse-armB-freeze500
NAME[C]=g1r4-alphonse-armC-freeze1675
NAME[D]=g1r4-alphonse-armD-freeze2680

RUNNER_LOG="${1:-nm_r_freeze_runner.log}"

for arm in "${ARMS[@]}"; do
  k="${FREEZE_K[$arm]}"
  name="${NAME[$arm]}"
  log="nm_r_freeze_arm_${arm}-k${k}.log"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '[%s] === arm %s freeze_r_after=%s name=%s log=%s ===\n' \
    "$ts" "$arm" "$k" "$name" "$log" >> "$RUNNER_LOG"
  NANOGPT_GRAD_CLIP=10.0 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_FREEZE_R_AFTER="${k}" \
  SENPAI_SEED=0 \
  NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "${name}" \
    --wandb_group "g1r4-alphonse/nm-r-freeze-after-k" \
    >"${log}" 2>&1
  rc=$?
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '[%s] === arm %s DONE rc=%d log=%s ===\n' "$ts" "$arm" "$rc" "$log" \
    >> "$RUNNER_LOG"
done

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '[%s] === chain complete ===\n' "$ts" >> "$RUNNER_LOG"
