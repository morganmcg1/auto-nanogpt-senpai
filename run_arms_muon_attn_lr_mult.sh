#!/usr/bin/env bash
# Sequential 3-arm chain for PR #2093 — Body-Muon ATTN_LR_MULT fine bracket
# Arms: A=0.80 (ctrl), B=0.65 (further conservative), C=0.95 (less conservative)
# Single-seed SENPAI_SEED=0 across all 3 arms.
set -euo pipefail

LOGDIR="${LOGDIR:-muon_attn_lr_mult_fine_logs}"
mkdir -p "$LOGDIR"

run_arm() {
  local arm_label="$1"
  local attn_mult="$2"
  local short_desc="muon-attn-lr-mult-${arm_label}-s0"
  local log="${LOGDIR}/arm_${arm_label}.log"
  echo "===== START arm_${arm_label} attn_mult=${attn_mult} $(date -u '+%Y-%m-%dT%H:%M:%SZ') =====" | tee -a "$log"
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_EPS=0.0001 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_MUON_ATTN_LR_MULT="$attn_mult" \
  SENPAI_SEED=0 \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-fern/${short_desc}" \
    --wandb_group "fern-muon-attn-lr-mult-fine-bracket" \
    >> "$log" 2>&1
  echo "===== END   arm_${arm_label} attn_mult=${attn_mult} $(date -u '+%Y-%m-%dT%H:%M:%SZ') =====" | tee -a "$log"
}

run_arm A 0.80
run_arm B 0.65
run_arm C 0.95

echo "All 3 arms complete: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
