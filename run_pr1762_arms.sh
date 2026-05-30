#!/usr/bin/env bash
# PR #1762 — NM γ-module-differentiated sweep (class 30).
# Arm A: uniform ctrl γ=0.005 (overrides=-1/-1 → bit-identity to prior production).
# Arm B: PRODUCTIVITY-AMPLIFY (MLP-proj γ=0.008, attn+MLP-fc γ=0.003).
# Arm C: PRODUCTIVITY-DAMP   (MLP-proj γ=0.003, attn+MLP-fc γ=0.008).
# All arms share the post-#1543 production stack; per-class γ env vars are the only delta.
set -u

mkdir -p logs_pr1762_arms

COMMON_ENV=(
  # — Production stack (BASELINE.md post-#1543) —
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
  # — Newton-Muon production (post-#1543) —
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  NANOGPT_NEWTON_MUON_BETA=0.95
  NANOGPT_NEWTON_MUON_EPS=1e-4
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
  # — Seed —
  SENPAI_SEED=0
)

run_arm() {
  local label="$1"
  local wandb_name="$2"
  shift 2
  local arm_env=("$@")
  local log="logs_pr1762_arms/${label}.log"
  echo "=== ${label} START $(date -u +%FT%TZ) ==="
  env "${COMMON_ENV[@]}" "${arm_env[@]}" \
    torchrun --standalone --nproc_per_node=1 \
      _pr1762_train_gpt_simple.py \
      --wandb_group "g1r4-frieren/nm-module-differentiated-gamma" \
      --wandb_name "${wandb_name}" \
      > "${log}" 2>&1
  local rc=$?
  echo "=== ${label} END $(date -u +%FT%TZ) rc=${rc} ==="
  return "${rc}"
}

# Arm A — uniform ctrl (per-class overrides off, bit-identity gate).
run_arm "A_ctrl_uniform_gamma" "g1r4-frieren/A-ctrl-uniform-gamma" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=-1.0 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=-1.0

# Arm B — PRODUCTIVITY-AMPLIFY: amplify γ on dominant MLP-proj (62%), damp on attn+MLP-fc (38%).
run_arm "B_amplify_mlp_proj" "g1r4-frieren/B-amplify-mlp-proj-0.008-attn-0.003" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=0.008 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=0.003

# Arm C — PRODUCTIVITY-DAMP: inverse — damp dominant MLP-proj, amplify attn+MLP-fc.
run_arm "C_damp_mlp_proj" "g1r4-frieren/C-damp-mlp-proj-0.003-attn-0.008" \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_MLP_PROJ=0.003 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA_ATTN_MLP_FC=0.008

echo "=== CHAIN COMPLETE $(date -u +%FT%TZ) ==="
