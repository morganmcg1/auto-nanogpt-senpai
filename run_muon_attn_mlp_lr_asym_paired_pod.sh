#!/bin/bash
# Muon attn/mlp LR asymmetry — paired-pod n=3 confirmation of compound Arm D.
# 6 runs total: pod0-A, pod0-D, pod1-A, pod1-D, pod2-A, pod2-D (interleaved).
# Arm A: attn_mult=1.00 mlp_mult=1.00 (control)
# Arm D: attn_mult=0.80 mlp_mult=1.20 (compound treatment)
# Same merged-stack envs as #393 baseline. No manual seed in train_gpt_simple.py,
# so each torchrun process gives a distinct effective seed from fresh RNG state
# (matches block_init paired-pod convention).
set -uo pipefail
cd "$(dirname "$0")"

# Merged-stack envs (from PR #579 instructions, locked across all 6 runs)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5

LOG_DIR=logs_muon_attn_mlp_lr_asym_paired_pod
mkdir -p "$LOG_DIR"

run_arm () {
  local pod="$1"
  local arm_name="$2"
  local attn_mult="$3"
  local mlp_mult="$4"
  local wname="muon-attn-mlp-paired-pod${pod}-${arm_name}"
  local log="$LOG_DIR/pod${pod}_arm${arm_name}.log"
  echo "=============================================="
  echo "Pod $pod arm $arm_name: attn=$attn_mult mlp=$mlp_mult | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  NANOGPT_MUON_ATTN_LR_MULT="$attn_mult" \
  NANOGPT_MUON_MLP_LR_MULT="$mlp_mult" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-askeladd/$wname" \
    --wandb_group "g1r4-askeladd/muon-attn-mlp-lr-asym-paired-pod" \
    >> "$log" 2>&1
  local rc=$?
  echo "Pod $pod arm $arm_name exit code: $rc | $(date -u +%FT%TZ)"
  return $rc
}

CHAIN_LOG="$LOG_DIR/chain.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START muon-attn-mlp paired-pod chain $(date -u +%FT%TZ) ====="

run_arm 0 A 1.00 1.00 || { echo "pod0-A failed"; exit 1; }
run_arm 0 D 0.80 1.20 || { echo "pod0-D failed"; exit 1; }
run_arm 1 A 1.00 1.00 || { echo "pod1-A failed"; exit 1; }
run_arm 1 D 0.80 1.20 || { echo "pod1-D failed"; exit 1; }
run_arm 2 A 1.00 1.00 || { echo "pod2-A failed"; exit 1; }
run_arm 2 D 0.80 1.20 || { echo "pod2-D failed"; exit 1; }

echo "===== END muon-attn-mlp paired-pod chain $(date -u +%FT%TZ) ====="
