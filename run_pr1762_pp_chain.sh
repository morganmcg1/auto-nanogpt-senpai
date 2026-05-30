#!/usr/bin/env bash
# PR #1762 — n=3 PP-confirm chain on Arm C (per-module-γ INVERSE direction).
# Spec from advisor c618: 6-run interleaved pair-by-pair seed order (s0/s1/s2)
# pairing ctrl (uniform γ=0.005 via overrides=-1.0) vs exp
# (MLP-proj γ=0.003, attn+MLP-fc γ=0.008).
#
# REBASED onto post-#1702 advisor branch (NM v-warmstart K=100 × Tikhonov γ=0.005
# composite); NEW baseline 3.26118 (#1702). Production stack inherits the
# v-warmstart flags so PP-ctrl reproduces the same #1702 baseline that the
# absolute-frame G1/G7 gates compare against.
#
# Order rationale: alternate ctrl/exp within each seed (s0 ctrl → s0 exp → s1 ctrl
# → s1 exp → s2 ctrl → s2 exp) so each pair shares fresh pod state — no pod-level
# contamination drift between paired (ctrl, exp) measurements.
#
# Uses worktree-isolated _pr1762_pp_train_gpt_simple.py to avoid chain race
# conditions if the entrypoint flips branch mid-run.

set -u

mkdir -p logs_pr1762_pp

COMMON_ENV=(
  # — Production stack (BASELINE.md post-#1702) —
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  # — Newton-Muon post-#1543 + post-#1702 composite —
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  NANOGPT_NEWTON_MUON_BETA=0.95
  NANOGPT_NEWTON_MUON_EPS=1e-4
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
)

run_arm() {
  local label="$1"
  local wandb_name="$2"
  shift 2
  local arm_env=("$@")
  local log="logs_pr1762_pp/${label}.log"
  echo "=== ${label} START $(date -u +%FT%TZ) ===" | tee -a logs_pr1762_pp/master.log
  env "${COMMON_ENV[@]}" "${arm_env[@]}" \
    torchrun --standalone --nproc_per_node=1 \
      _pr1762_pp_train_gpt_simple.py \
      --wandb_group "g1r4-frieren/nm-module-differentiated-gamma-pp" \
      --wandb_name "${wandb_name}" \
      > "${log}" 2>&1
  local rc=$?
  echo "=== ${label} END $(date -u +%FT%TZ) rc=${rc} ===" | tee -a logs_pr1762_pp/master.log
  return "${rc}"
}

# Pair 1: seed 0 — fresh-pod (ctrl, exp) measurement, decouples from prior single-seed Arm A drift.
run_arm "pp_ctrl_s0" "g1r4-frieren/PP-ctrl-s0" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=-1.0 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=-1.0 \
  SENPAI_SEED=0

run_arm "pp_exp_s0" "g1r4-frieren/PP-exp-s0" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=0.003 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=0.008 \
  SENPAI_SEED=0

# Pair 2: seed 1 — fresh seed, fresh pair.
run_arm "pp_ctrl_s1" "g1r4-frieren/PP-ctrl-s1" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=-1.0 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=-1.0 \
  SENPAI_SEED=1

run_arm "pp_exp_s1" "g1r4-frieren/PP-exp-s1" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=0.003 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=0.008 \
  SENPAI_SEED=1

# Pair 3: seed 2 — fresh seed, fresh pair.
run_arm "pp_ctrl_s2" "g1r4-frieren/PP-ctrl-s2" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=-1.0 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=-1.0 \
  SENPAI_SEED=2

run_arm "pp_exp_s2" "g1r4-frieren/PP-exp-s2" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=0.003 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=0.008 \
  SENPAI_SEED=2

echo "=== CHAIN COMPLETE $(date -u +%FT%TZ) ===" | tee -a logs_pr1762_pp/master.log
