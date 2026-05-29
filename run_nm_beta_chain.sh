#!/usr/bin/env bash
# PR #1631 NM β EMA-decay schedule axis: 4-arm sequential chain.
# All arms share production stack (post-#1421). Only NM β behavior differs.
# Single SENPAI_SEED=0 for N=1 screening. PP-promote to n=3 if any arm Δ_paired ≤ -0.0003.
#
# Arm A ctrl  : β=0.95 fixed (production)               (env unset → fallback to default)
# Arm B       : β=0.90 fixed (fresher R)                NANOGPT_NEWTON_MUON_BETA=0.90
# Arm C       : β=0.99 fixed (more stable R)            NANOGPT_NEWTON_MUON_BETA=0.99
# Arm D       : β linear ramp 0.90 → 0.99               NANOGPT_NEWTON_MUON_BETA_START=0.90 BETA_END=0.99
#
# Train file: records/track_3_optimization/_pr_nm_beta_train_gpt_simple.py
# Logs:      run_logs/nm_beta_arm_{A,B,C,D}.log
# W&B group: g1r4-thorfinn/nm-beta-ema-schedule
set -uo pipefail
cd "/workspace/senpai/target"

mkdir -p run_logs
CHAIN_LOG="run_logs/nm_beta_chain.log"
echo "[chain] start $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$CHAIN_LOG"

# Production stack (post-#1421). Unchanged across arms.
COMMON_ENV=(
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_EPS=1e-4
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  SENPAI_SEED=0
)

run_arm() {
  local arm="$1"; shift
  local wandb_name="$1"; shift
  local arm_env=("$@")
  local logf="run_logs/nm_beta_arm_${arm}.log"
  echo "[chain] === arm $arm start $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$CHAIN_LOG"
  echo "[chain] arm $arm env: ${arm_env[*]}" | tee -a "$CHAIN_LOG"
  echo "[chain] arm $arm wandb_name: $wandb_name" | tee -a "$CHAIN_LOG"
  env "${COMMON_ENV[@]}" "${arm_env[@]}" \
    torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/_pr_nm_beta_train_gpt_simple.py \
    --wandb_name "$wandb_name" \
    --wandb_group "g1r4-thorfinn/nm-beta-ema-schedule" \
    > "$logf" 2>&1
  local rc=$?
  echo "[chain] === arm $arm end $(date -u +%Y-%m-%dT%H:%M:%SZ) rc=$rc ===" | tee -a "$CHAIN_LOG"
  if [[ $rc -ne 0 ]]; then
    echo "[chain] ERROR: arm $arm failed (rc=$rc). Continuing chain anyway." | tee -a "$CHAIN_LOG"
  fi
  return $rc
}

# Arm A: production β=0.95 fixed (env vars unset → fallback to default 0.95). Drift gate baseline.
run_arm A "g1r4-thorfinn/A-beta0.95-ctrl" NANOGPT_NEWTON_MUON_BETA=0.95

# Arm B: β=0.90 fixed (fresher R).
run_arm B "g1r4-thorfinn/B-beta0.90-fresh" NANOGPT_NEWTON_MUON_BETA=0.90

# Arm C: β=0.99 fixed (more stable R).
run_arm C "g1r4-thorfinn/C-beta0.99-stable" NANOGPT_NEWTON_MUON_BETA=0.99

# Arm D: β linear ramp 0.90 → 0.99 (NANOGPT_NEWTON_MUON_BETA unset; START/END override).
run_arm D "g1r4-thorfinn/D-beta-ramp" \
  NANOGPT_NEWTON_MUON_BETA_START=0.90 \
  NANOGPT_NEWTON_MUON_BETA_END=0.99

echo "[chain] all arms complete $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$CHAIN_LOG"
