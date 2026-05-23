#!/bin/bash
# Stochastic NS iter count (PR #787) — paired-pod n=3 confirmation of Arm C.
# 6 runs total: pod0-A, pod0-C, pod1-A, pod1-C, pod2-A, pod2-C (interleaved).
# Arm A: NANOGPT_NS_STOCHASTIC_MID=0  NANOGPT_NS_STOCHASTIC_COOLDOWN=0 (ctrl).
# Arm C: NANOGPT_NS_STOCHASTIC_MID=0  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 (treat).
# Post-#708 merged stack including per-group grad clip (BODY=10, AUX=5).
# Each pod sets SENPAI_SEED (0/1/2). The training script uses it ONLY to vary
# the stochastic-NS RNG draw across pods (no torch.manual_seed call — matches
# the existing paired-pod convention: fresh process RNG drives model init).
set -uo pipefail
cd "$(dirname "$0")"

# Post-#708 merged-stack envs, locked across all 6 runs.
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_TRAIN_STEPS=3350

LOG_DIR=stochastic_ns_paired_pod_logs
mkdir -p "$LOG_DIR"

run_arm () {
  local pod="$1"
  local arm_name="$2"
  local mid_spread="$3"
  local cd_spread="$4"
  local wname="g1r4-fern/stochastic-ns-paired-pod-${pod}-${arm_name}"
  local log="$LOG_DIR/pod${pod}_arm${arm_name}.log"
  echo "=============================================="
  echo "Pod $pod arm $arm_name: MID=$mid_spread CD=$cd_spread SENPAI_SEED=$pod | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  SENPAI_SEED="$pod" \
  NANOGPT_NS_STOCHASTIC_MID="$mid_spread" \
  NANOGPT_NS_STOCHASTIC_COOLDOWN="$cd_spread" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "$wname" \
    --wandb_group "g1r4-fern/stochastic-ns-iter-paired-pod" \
    >> "$log" 2>&1
  local rc=$?
  echo "Pod $pod arm $arm_name exit code: $rc | $(date -u +%FT%TZ)"
  return $rc
}

CHAIN_LOG="$LOG_DIR/chain.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START stochastic-ns paired-pod chain $(date -u +%FT%TZ) ====="

run_arm 0 A 0 0 || { echo "pod0-A failed"; exit 1; }
run_arm 0 C 0 2 || { echo "pod0-C failed"; exit 1; }
run_arm 1 A 0 0 || { echo "pod1-A failed"; exit 1; }
run_arm 1 C 0 2 || { echo "pod1-C failed"; exit 1; }
run_arm 2 A 0 0 || { echo "pod2-A failed"; exit 1; }
run_arm 2 C 0 2 || { echo "pod2-C failed"; exit 1; }

echo "===== END stochastic-ns paired-pod chain $(date -u +%FT%TZ) ====="
