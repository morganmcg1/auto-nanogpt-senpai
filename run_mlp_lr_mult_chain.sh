#!/bin/bash
# PR #2097 — Body-Muon MLP_LR_MULT fine bracket 3-arm sequential chain (N=1).
# Arms (log-symmetric ±12.5% around production 1.20):
#   A ctrl   MLP_LR_MULT=1.20  (production reference; expected baseline)
#   B down   MLP_LR_MULT=1.05  (conservative MLP step; NM-compensation hypothesis)
#   C up     MLP_LR_MULT=1.35  (aggressive MLP step; push MLP gradient signal)
#
# Pre-staged gates (see PR body):
#   G4 drift gate on A:     |val_A - 3.26118| <= 0.0015 (PASS) / >2σ_seed marginal-fail
#   NULL band:              |Δ_paired| <= 0.001 (within σ_seed envelope)
#   FAV-mild:               Δ_BA or Δ_CA <= -0.002 -> bracket extension follow-up
#   NEG-mild:               Δ_BA or Δ_CA >= +0.002 -> direction-incorrect, drop arm
set -uo pipefail
cd "$(dirname "$0")"

# Post-#1702 production stack (full 22 envs).
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=0.0001
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
# Default train_steps=3350 (script default; matches BASELINE production).
export PYTHONUNBUFFERED=1

# Single screening seed for within-pod paired N=1 comparison.
export SENPAI_SEED=0

run_arm () {
  local label="$1"
  local mlp_mult="$2"
  local wname="g1r4-thorfinn/muon-mlp-lr-mult-${label}-s0"
  local wgroup="thorfinn-muon-mlp-lr-mult-fine-bracket"
  local log="run_logs/mlp_lr_mult_arm_${label}.log"
  echo "=============================================="
  echo "ARM ${label}: MLP_LR_MULT=${mlp_mult} | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  env NANOGPT_MUON_MLP_LR_MULT="$mlp_mult" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "$wname" \
    --wandb_group "$wgroup" \
    >> "$log" 2>&1
  local rc=$?
  echo "Arm ${label} exit code: $rc | $(date -u +%FT%TZ)"
  return $rc
}

mkdir -p run_logs
CHAIN_LOG="run_logs/mlp_lr_mult_chain_runner.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START mlp-lr-mult 3-arm chain $(date -u +%FT%TZ) ====="

run_arm A 1.20 || { echo "armA failed"; exit 1; }
run_arm B 1.05 || { echo "armB failed"; exit 1; }
run_arm C 1.35 || { echo "armC failed"; exit 1; }

echo "===== END mlp-lr-mult 3-arm chain $(date -u +%FT%TZ) ====="
