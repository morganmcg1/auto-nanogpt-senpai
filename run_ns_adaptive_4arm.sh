#!/bin/bash
# PR #1031 — Per-matrix residual-stopping adaptive NS iteration.
# 4-arm sequential sweep (single seed):
#   A (ctrl):    NS_ADAPTIVE=0, NS_ITERS=12 / COOLDOWN=16             (drift gate)
#   B:           NS_ADAPTIVE=1, tau=0.05, MAX=16 / MAX_CD=20           (expanded budget)
#   C (iso):     NS_ADAPTIVE=1, tau=0.05, MAX=12 / MAX_CD=16           (allocation rebalance)
#   D:           NS_ADAPTIVE=1, tau=0.02, MAX=16 / MAX_CD=20           (tighter tau)
# Wall-clock est: ~104 min × 4 ≈ 7 hours.
set -uo pipefail
cd "$(dirname "$0")"

# Merged-stack envs locked across all 4 arms (post-#847 baseline).
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export SENPAI_SEED=0
export NANOGPT_TRAIN_STEPS=3350

LOG_DIR=logs_ns_adaptive_4arm
mkdir -p "$LOG_DIR"
CHAIN_LOG="$LOG_DIR/chain.log"

run_arm () {
  local arm="$1"
  local adaptive="$2"
  local tau="$3"
  local amax="$4"
  local amax_cd="$5"
  local label="$6"
  local wname="ns-adaptive-arm-${arm}-${label}"
  local log="$LOG_DIR/arm_${arm}_${label}.log"
  {
    echo "=============================================="
    echo "Arm $arm ($label): adaptive=$adaptive tau=$tau max=$amax max_cd=$amax_cd"
    echo "start $(date -u +%FT%TZ)"
    echo "Log: $log"
    echo "=============================================="
  } | tee -a "$CHAIN_LOG"
  NANOGPT_NS_ADAPTIVE="$adaptive" \
  NANOGPT_NS_ADAPTIVE_TAU="$tau" \
  NANOGPT_NS_ADAPTIVE_MIN=5 \
  NANOGPT_NS_ADAPTIVE_MAX="$amax" \
  NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN="$amax_cd" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-nezuko/$wname" \
    --wandb_group "g1r4-nezuko/ns-adaptive-residual-stopping" \
    >> "$log" 2>&1
  local rc=$?
  {
    echo "Arm $arm ($label) exit=$rc $(date -u +%FT%TZ)"
  } | tee -a "$CHAIN_LOG"
  return $rc
}

exec >>"$CHAIN_LOG" 2>&1

echo "===== START PR #1031 NS-adaptive 4-arm chain $(date -u +%FT%TZ) ====="

# Arm A control: bit-identical to baseline (NS_ADAPTIVE=0).
run_arm A 0 0.05 12 16 ctrl       || { echo "Arm A failed"; exit 1; }
# Arm B: expanded budget, default tau.
run_arm B 1 0.05 16 20 tau05-max16 || { echo "Arm B failed"; exit 1; }
# Arm C: iso-budget, default tau (load-bearing allocation test).
run_arm C 1 0.05 12 16 tau05-max12-iso || { echo "Arm C failed"; exit 1; }
# Arm D: tighter tau (sensitivity test vs B).
run_arm D 1 0.02 16 20 tau02-max16 || { echo "Arm D failed"; exit 1; }

echo "===== END PR #1031 NS-adaptive 4-arm chain $(date -u +%FT%TZ) ====="
