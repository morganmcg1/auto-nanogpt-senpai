#!/usr/bin/env bash
# PR #724 paired-pod n=3 confirmation chain.
# 6 runs total: pod0-A, pod0-D, pod1-A, pod1-D, pod2-A, pod2-D (interleaved).
#
# Arm A: NANOGPT_MUON_ATTN_NS_ITERS_COOLDOWN=16  NANOGPT_MUON_MLP_NS_ITERS_COOLDOWN=16 (control / current uniform)
# Arm D: NANOGPT_MUON_ATTN_NS_ITERS_COOLDOWN=12  NANOGPT_MUON_MLP_NS_ITERS_COOLDOWN=20 (compound attn-down + mlp-up)
#
# Same merged-stack envs as #579 baseline; only the two NS_ITERS_COOLDOWN per-type values change between arms.
# train_gpt_simple.py has no manual seeding, so each torchrun process gives a distinct effective seed
# from fresh RNG state (matches the run_muon_attn_mlp_lr_asym_paired_pod.sh convention used for the #579 merge).
set -uo pipefail
cd "$(dirname "$0")"

# Merged-stack envs (post-#579, locked across all 6 runs)
export NANOGPT_GRAD_CLIP=10.0
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

LOG_DIR=logs_pr724_paired_pod
mkdir -p "$LOG_DIR"
master_log="$LOG_DIR/chain_master.log"
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log_section() {
  {
    echo "=============================================="
    echo "$1"
    echo "=============================================="
  } | tee -a "$master_log"
}

run_arm () {
  local pod="$1"
  local arm_name="$2"
  local attn_ns="$3"
  local mlp_ns="$4"
  local wname="pod${pod}-arm${arm_name}-attn${attn_ns}-mlp${mlp_ns}"
  local log="$LOG_DIR/pod${pod}_arm${arm_name}.log"
  log_section "Pod $pod arm $arm_name attn_ns=${attn_ns} mlp_ns=${mlp_ns} start $(ts)"
  echo "Log: $log" | tee -a "$master_log"
  NANOGPT_MUON_ATTN_NS_ITERS_COOLDOWN="$attn_ns" \
  NANOGPT_MUON_MLP_NS_ITERS_COOLDOWN="$mlp_ns" \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-nezuko/$wname" \
    --wandb_group "g1r4-nezuko/per-type-ns-cooldown-paired-pod" \
    >> "$log" 2>&1
  local rc=$?
  log_section "Pod $pod arm $arm_name exit=$rc $(ts)"
  return $rc
}

log_section "START PR724 paired-pod chain $(ts)"

run_arm 0 A 16 16 || { echo "pod0-A failed" | tee -a "$master_log"; exit 1; }
run_arm 0 D 12 20 || { echo "pod0-D failed" | tee -a "$master_log"; exit 1; }
run_arm 1 A 16 16 || { echo "pod1-A failed" | tee -a "$master_log"; exit 1; }
run_arm 1 D 12 20 || { echo "pod1-D failed" | tee -a "$master_log"; exit 1; }
run_arm 2 A 16 16 || { echo "pod2-A failed" | tee -a "$master_log"; exit 1; }
run_arm 2 D 12 20 || { echo "pod2-D failed" | tee -a "$master_log"; exit 1; }

log_section "END PR724 paired-pod chain $(ts)"
