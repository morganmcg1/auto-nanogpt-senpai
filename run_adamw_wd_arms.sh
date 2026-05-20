#!/usr/bin/env bash
# PR #593 — Per-group AdamW WD sweep, 4 sequential arms on single GPU.
# Arm A: ctrl (all WD=0)         — baseline reproduction
# Arm B: lm_head WD=0.01         — output projection regularization
# Arm C: scalar  WD=0.01         — LayerNorm γ/β fencepost
# Arm D: lm_head + scalar WD=0.01 — compound
# EMBED_WD stays 0 across all arms (#554 confirmed harmful direction).
set -uo pipefail

cd /workspace/senpai/target
mkdir -p run_logs/adamw_wd_arms

SCRIPT=records/track_3_optimization/train_gpt_simple.py
NPROC=$(nvidia-smi -L | wc -l)

run_arm() {
  local arm="$1"
  local embed_wd="$2"
  local lm_head_wd="$3"
  local scalar_wd="$4"

  local name="wd-${arm}"
  local log="run_logs/adamw_wd_arms/${arm}.log"
  echo "=== $(date -Is) launching arm ${arm} (embed=${embed_wd} lm_head=${lm_head_wd} scalar=${scalar_wd}) ===" | tee -a "$log"
  NANOGPT_ADAMW_EMBED_WD=${embed_wd} \
  NANOGPT_ADAMW_LM_HEAD_WD=${lm_head_wd} \
  NANOGPT_ADAMW_SCALAR_WD=${scalar_wd} \
  NANOGPT_GRAD_CLIP=10.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    torchrun --standalone --nproc_per_node=${NPROC} \
      "$SCRIPT" \
      --wandb_name "g1r4-frieren/${name}" \
      --wandb_group "g1r4-frieren/adamw-wd-per-group" \
      2>&1 | tee -a "$log"
  local rc=${PIPESTATUS[0]}
  echo "=== $(date -Is) arm ${arm} done, exit=${rc} ===" | tee -a "$log"
}

case "${1:-all}" in
  A) run_arm A 0.0 0.0  0.0  ;;
  B) run_arm B 0.0 0.01 0.0  ;;
  C) run_arm C 0.0 0.0  0.01 ;;
  D) run_arm D 0.0 0.01 0.01 ;;
  all)
    run_arm A 0.0 0.0  0.0
    run_arm B 0.0 0.01 0.0
    run_arm C 0.0 0.0  0.01
    run_arm D 0.0 0.01 0.01
    ;;
  *) echo "usage: $0 [A|B|C|D|all]"; exit 2 ;;
esac
