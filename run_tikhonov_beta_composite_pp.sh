#!/usr/bin/env bash
# PP-promote n=3 chain for #1675 Arm C γ=0.008 × β=0.90.
# Reuses Arm A s0 (`inw0q026`) PP-ctrl-s0 and Arm C s0 (`omu30eiv`) PP-exp-s0.
# Launches 4 fresh sequential runs: PP-ctrl-s1, PP-exp-s1, PP-ctrl-s2, PP-exp-s2.
# Total ~10 GPU-h sequential @ ~145 min/arm.

set -u
LOGDIR=logs_tikhonov_beta_composite_pp
mkdir -p "$LOGDIR"

WB_GROUP="g1r4-askeladd/tikhonov-beta-composite-pp"
SCRIPT=_pr_tikhonov_beta_composite_train_gpt_simple.py

# Shared production-baseline env vars (post-#1543 stack)
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
)

run_arm() {
  local label="$1"; shift
  local logfile="$1"; shift
  local wb_name="$1"; shift
  local seed="$1"; shift
  local gamma="$1"; shift
  local beta="$1"; shift

  echo "[pp-chain] launching $label seed=$seed γ=$gamma β=$beta at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  env "${COMMON_ENV[@]}" \
    NANOGPT_NEWTON_MUON_BETA="$beta" \
    NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA="$gamma" \
    SENPAI_SEED="$seed" \
    torchrun --standalone --nproc_per_node=1 "$SCRIPT" \
      --wandb_group "$WB_GROUP" \
      --wandb_name "$wb_name" \
      --wandb_project modded-nanogpt-senpai \
      > "$LOGDIR/$logfile" 2>&1
  echo "[pp-chain] $label exited at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

# PP-ctrl s1 (γ=0.005, β=0.95)
run_arm "PP-ctrl s1" "pp_ctrl_s1.log" "A-tikho0.005-beta0.95-pp-ctrl-s1" 1 0.005 0.95
# PP-exp s1 (γ=0.008, β=0.90)
run_arm "PP-exp s1" "pp_exp_s1.log"  "C-tikho0.008-beta0.90-pp-exp-s1"  1 0.008 0.90
# PP-ctrl s2 (γ=0.005, β=0.95)
run_arm "PP-ctrl s2" "pp_ctrl_s2.log" "A-tikho0.005-beta0.95-pp-ctrl-s2" 2 0.005 0.95
# PP-exp s2 (γ=0.008, β=0.90)
run_arm "PP-exp s2" "pp_exp_s2.log"  "C-tikho0.008-beta0.90-pp-exp-s2"  2 0.008 0.90

echo "[pp-chain] ALL DONE at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
