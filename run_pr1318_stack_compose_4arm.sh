#!/usr/bin/env bash
# PR #1318 — Newton-Muon cooldown-stack compositionality 2x2 factorial.
# 4-arm chain: A ctrl / B reset_only / C cov_only / D compound.
# Each arm: single seed=0, 3350 steps, num_trials=1.
# Total ~8-12h wall on 1x RTX Pro 6000.
set -u
set -o pipefail

cd /workspace/senpai/target

LOGDIR=/workspace/senpai/target/logs_pr1318_stack_compose
mkdir -p "$LOGDIR"

# Post-#1138 canonical NM stack — matches PR #1318 reproduce block.
COMMON_ENV=(
  NANOGPT_GRAD_CLIP=10.0
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10
  NANOGPT_NEWTON_MUON_MAX_D_IN=1024
  SENPAI_SEED=0
  NANOGPT_TRAIN_STEPS=3350
)

# Per-arm extra envs.
# Arm A ctrl: no extras (production NM stack, no extensions).
ARM_A_ENV=()
# Arm B reset_only: replicates #1281 H2 Arm B.
ARM_B_ENV=( NANOGPT_NEWTON_MUON_RESET_STEP=2345 )
# Arm C cov_only: replicates #1286 H4 Arm C.
ARM_C_ENV=(
  NANOGPT_NEWTON_MUON_LATE_START_STEP=2400
  NANOGPT_NEWTON_MUON_LATE_MAX_D_IN=4096
)
# Arm D compound: both mechanisms simultaneously.
ARM_D_ENV=(
  NANOGPT_NEWTON_MUON_RESET_STEP=2345
  NANOGPT_NEWTON_MUON_LATE_START_STEP=2400
  NANOGPT_NEWTON_MUON_LATE_MAX_D_IN=4096
)

run_arm() {
  local arm_label="$1"
  local wandb_suffix="$2"
  shift 2
  local logfile="$LOGDIR/arm_${arm_label}.log"
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Arm ${arm_label} starting ===" | tee -a "$logfile"
  env "${COMMON_ENV[@]}" "$@" \
    torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "g1r4-nezuko/nm-stack-compose" \
      --wandb_name "g1r4-nezuko-stackcompose-arm${arm_label}-${wandb_suffix}" \
      >>"$logfile" 2>&1
  local rc=$?
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) Arm ${arm_label} done rc=${rc} ===" | tee -a "$logfile"
  return $rc
}

# Sequential — 1 GPU.
run_arm A ctrl          "${ARM_A_ENV[@]}" || exit 1
run_arm B reset2345     "${ARM_B_ENV[@]}" || exit 1
run_arm C late4096      "${ARM_C_ENV[@]}" || exit 1
run_arm D compound      "${ARM_D_ENV[@]}" || exit 1

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) All 4 arms complete ===" | tee -a "$LOGDIR/chain.log"
