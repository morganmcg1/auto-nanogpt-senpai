#!/bin/bash
# PR #1137 — stack-pruning Phase 2 4-arm subtractive sweep.
# Arms: A=ctrl (full stack), B=drop EMBED_LR_MULT (#393), C=drop EMBED_COOLDOWN_SHAPE (#235),
#       D=drop body Muon asymmetry (#579). Single GPU, SENPAI_SEED=0, 3350 steps each.
set -uo pipefail
cd "$(dirname "$0")"

LOG_DIR=/workspace/senpai/target/_logs/pr1137
mkdir -p "$LOG_DIR"

# Common (frozen merged stack) env vars — locked for all 4 arms unless the arm overrides.
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_TRAIN_STEPS=3350
export SENPAI_SEED=0

run_arm () {
  local arm="$1"             # A | B | C | D
  local desc="$2"            # short description for wandb_name
  local embed_lr_mult="$3"   # NANOGPT_ADAMW_EMBED_LR_MULT
  local embed_shape="$4"     # NANOGPT_EMBED_COOLDOWN_SHAPE
  local attn_mult="$5"       # NANOGPT_MUON_ATTN_LR_MULT
  local mlp_mult="$6"        # NANOGPT_MUON_MLP_LR_MULT
  local log="$LOG_DIR/arm-${arm}-${desc}.log"
  local marker_start="$LOG_DIR/arm-${arm}.start"
  local marker_done="$LOG_DIR/arm-${arm}.done"
  echo "============================================="
  echo "Arm ${arm} (${desc}): EMBED_LR_MULT=${embed_lr_mult} EMBED_SHAPE=${embed_shape} MUON attn=${attn_mult} mlp=${mlp_mult}"
  echo "Log: ${log}"
  echo "Start: $(date -u +%FT%TZ)"
  date -u +%FT%TZ > "$marker_start"
  rm -f "$marker_done"
  NANOGPT_ADAMW_EMBED_LR_MULT="$embed_lr_mult" \
  NANOGPT_EMBED_COOLDOWN_SHAPE="$embed_shape" \
  NANOGPT_MUON_ATTN_LR_MULT="$attn_mult" \
  NANOGPT_MUON_MLP_LR_MULT="$mlp_mult" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_group g1r4-edward/stack-pruning-phase2 \
    --wandb_name "g1r4-edward-pruneP2-arm-${arm}-${desc}" \
    >"$log" 2>&1
  local rc=$?
  echo "rc=${rc} end=$(date -u +%FT%TZ)" >> "$marker_start"
  date -u +%FT%TZ > "$marker_done"
  return $rc
}

# Arm A — ctrl (full merged stack, bit-identical baseline)
run_arm A "ctrl"             1.5  linear_floor  0.80  1.20

# Arm B — drop embed LR mult (#393)
run_arm B "drop-embed-lr-mult" 1.0  linear_floor  0.80  1.20

# Arm C — drop embed cooldown floor (#235)
run_arm C "drop-embed-floor"   1.5  linear         0.80  1.20

# Arm D — drop body Muon asymmetry (#579)
run_arm D "drop-muon-asym"     1.5  linear_floor  1.0   1.0

echo "All arms complete: $(date -u +%FT%TZ)"
