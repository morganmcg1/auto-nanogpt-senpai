#!/bin/bash
# Embed init-anchor paired-pod n=3 RE-RUN on POST-#787 stack (PR #847 send-back from advisor 11:57 UTC 2026-05-23).
# Three sequential runs on Arm B (NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001) with
# NANOGPT_NS_STOCHASTIC_COOLDOWN=2 ADDED to match new merged stack post-#787.
# Each pod uses SENPAI_SEED=0/1/2 to get independent stochastic-NS draws,
# matching the convention that established new baseline val=3.26944 (fern #787 paired-pod).
#
# Pre-staged gates (frozen against new baseline 3.26944, per advisor 11:57 UTC):
#   1. mean(n=3) <= 3.26944 -> merge eligibility
#   2. (3.28 - mean) * sqrt(3) >= 0.004  (project stat rule)
#   3. >=2/3 seeds direction-correct vs 3.26944
#   4. no seed > 3.275 (catastrophic floor)
#   5. drift sanity +/-0.0010 vs current Arm B mean 3.26930 (mechanism preserved across stack composition)
#
# Pre-staged outcomes:
#   mean <= 3.26944 AND >=2/3 dir-correct vs new -> MERGE
#   mean in (3.26944, 3.27036]                   -> productive-NULL (closed)
#   mean > 3.27036                                -> NEG (closed)
set -uo pipefail
cd "$(dirname "$0")"

# Post-#708 merged-stack envs (frozen across all 3 seeds; matches the PR #787 paired-pod
# convention that established new baseline 3.26944).
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
# Arm B treatment + post-#787 stack additions
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_TRAIN_STEPS=3350
export PYTHONUNBUFFERED=1

run_seed () {
  local seed_idx="$1"
  local wname="embed-init-anchor-arm-B-rebased-seed-${seed_idx}"
  local log="embed_init_anchor_rebased_paired_pod_seed${seed_idx}.log"
  echo "=============================================="
  echo "Seed ${seed_idx}: SENPAI_SEED=${seed_idx} EMBED_INIT_ANCHOR=0.001 NS_STOCHASTIC_COOLDOWN=2 | $(date -u +%FT%TZ)"
  echo "Log: $log"
  echo "=============================================="
  SENPAI_SEED="$seed_idx" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "g1r4-alphonse/${wname}" \
    --wandb_group "g1r4-alphonse/embed-init-anchor-rebased" \
    >> "$log" 2>&1
  local rc=$?
  echo "Seed ${seed_idx} exit code: $rc | $(date -u +%FT%TZ)"
  return $rc
}

CHAIN_LOG="embed_init_anchor_rebased_paired_pod_runner.log"
exec >>"$CHAIN_LOG" 2>&1

echo "===== START embed-init-anchor REBASED paired-pod chain $(date -u +%FT%TZ) ====="

run_seed 1 || { echo "seed1 failed"; exit 1; }
run_seed 2 || { echo "seed2 failed"; exit 1; }
run_seed 3 || { echo "seed3 failed"; exit 1; }

echo "===== END embed-init-anchor REBASED paired-pod chain $(date -u +%FT%TZ) ====="
