#!/bin/bash
# PR #1393 — Newton-Muon MLP-LR fine-grained sweep on post-#1240 production stack.
# 4-arm sequential chain (N=1) localizing the LR_SCALE_MLP optimum following
# #1346 (productive-MARGINAL, MLP-boost direction-correct on pre-#1240 stack).
#
# Arms:
#   A ctrl   LR_SCALE_MLP=1.0  (post-#1240 baseline replication, drift-gate target 3.26339)
#   B        LR_SCALE_MLP=1.2  (#1346 Arm B retest on production stack)
#   C        LR_SCALE_MLP=1.4
#   D        LR_SCALE_MLP=1.6
#
# Pre-staged gates:
#   drift gate G4 on A:     |val_A - 3.26339| <= 0.003
#   merge candidate:        any arm val <= 3.26339 AND fs <= 3150 AND Δ_paired <= -0.0010
#   PP-promote:             best arm Δ_paired <= -0.0020 AND val <= 3.26339+0.0010
#   productive-MARGINAL:    best arm Δ_paired in [-0.002, -0.001] AND val > 3.26339
#   monotone:               Δ_D < Δ_C < Δ_B without saturation  -> follow-up {1.6, 1.8, 2.0}
#   saturation/peak:        one of B/C/D best, others worse -> triangulated optimum
#   productive-NULL:        all |Δ| <= 0.0015
#   ADVERSE:                all Δ >= +0.0015
#   catastrophic kill:      val(arm) - val(A) >= +0.10 at step 2500 -> abort

set -uo pipefail
cd "$(dirname "$0")"

# Post-#1240 merged production stack envs (baseline val 3.26339, fs=3150).
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
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001

# Newton-Muon post-#1240 production stack (period=5, max_d_in=4096).
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=5
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_LR_SCALE_ATTN=1.0
# LR_SCALE_MLP varies per arm.

export NANOGPT_TRAIN_STEPS=3350
export PYTHONUNBUFFERED=1

# Single screening seed for within-pod N=1 comparison.
export SENPAI_SEED=0

run_arm () {
  local label="$1"
  local lr_scale_mlp="$2"
  local wname="g1r4-thorfinn-nm-mlp-lr-arm-${label}-${lr_scale_mlp}"
  local wgroup="g1r4-thorfinn/nm-mlp-lr-sweep"
  local log="run_logs/nm_mlp_lr_arm_${label}_${lr_scale_mlp}.log"
  echo "=============================================="
  echo "ARM ${label}: LR_SCALE_MLP=${lr_scale_mlp} | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  env NANOGPT_NEWTON_MUON_LR_SCALE_MLP="$lr_scale_mlp" \
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
CHAIN_LOG="run_logs/nm_mlp_lr_chain_runner.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START nm-mlp-lr 4-arm chain $(date -u +%FT%TZ) ====="

run_arm A-ctrl 1.0 || { echo "armA failed"; exit 1; }
run_arm B      1.2 || { echo "armB failed"; exit 1; }
run_arm C      1.4 || { echo "armC failed"; exit 1; }
run_arm D      1.6 || { echo "armD failed"; exit 1; }

echo "===== END nm-mlp-lr 4-arm chain $(date -u +%FT%TZ) ====="
