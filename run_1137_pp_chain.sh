#!/bin/bash
# PR #1137 — Phase 2 PP n=3 confirmation chain for Arm C (drop EMBED_COOLDOWN_SHAPE=linear_floor → linear).
# Six sequential interleaved runs on a single GPU:
#   ctrl-s0, armC-s0, ctrl-s1, armC-s1, ctrl-s2, armC-s2
# ctrl = full merged stack (linear_floor); armC = full merged stack with EMBED_COOLDOWN_SHAPE=linear.
# 3350 steps each. Matches #1028 / #1100 PP n=3 protocol.
set -uo pipefail
cd "$(dirname "$0")"

LOG_DIR=/workspace/senpai/target/_logs/pr1137_pp
mkdir -p "$LOG_DIR"

# Frozen merged-stack env vars common to BOTH ctrl and armC.
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_TRAIN_STEPS=3350

run_one () {
  local arm="$1"          # ctrl | armC
  local seed="$2"         # 0 | 1 | 2
  local shape="$3"        # linear_floor (ctrl) | linear (armC)
  local tag="${arm}-s${seed}"
  local log="$LOG_DIR/${tag}.log"
  local marker_start="$LOG_DIR/${tag}.start"
  local marker_done="$LOG_DIR/${tag}.done"
  echo "============================================="
  echo "Run ${tag}: EMBED_COOLDOWN_SHAPE=${shape} SEED=${seed}"
  echo "Log: ${log}"
  echo "Start: $(date -u +%FT%TZ)"
  date -u +%FT%TZ > "$marker_start"
  rm -f "$marker_done"
  SENPAI_SEED="$seed" \
  NANOGPT_EMBED_COOLDOWN_SHAPE="$shape" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_group g1r4-edward/stack-pruning-phase2-pp \
    --wandb_name "g1r4-edward-pruneP2-pp-${tag}" \
    >"$log" 2>&1
  local rc=$?
  echo "rc=${rc} end=$(date -u +%FT%TZ)" >> "$marker_start"
  date -u +%FT%TZ > "$marker_done"
  return $rc
}

# Interleaved seeds 0/1/2 — ctrl then armC for each seed.
run_one ctrl 0 linear_floor
run_one armC 0 linear
run_one ctrl 1 linear_floor
run_one armC 1 linear
run_one ctrl 2 linear_floor
run_one armC 2 linear

echo "All PP n=3 runs complete: $(date -u +%FT%TZ)"
