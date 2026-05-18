#!/usr/bin/env bash
# PR #345 NS coef linear_ramp_down DEPTH sweep — sequential 4-arm chain.
# Arms vary NANOGPT_NS_COEF_RAMP_DEPTH on the full post-#290 stack.
#   A: depth=0.42  (control; reproduces #290 winner c=0.70 -> 0.28)
#   B: depth=0.30  (shallower; c=0.64 -> 0.34)
#   C: depth=0.55  (steeper;   c=0.765 -> 0.215)
#   D: depth=0.70  (much steeper; c=0.84 -> 0.14)
# Mean c=0.49 in all arms — pure SHAPE sweep, mean-neutral.
set -u
cd "$(dirname "$0")"
mkdir -p ns_coef_ramp_depth_logs

ORCH_LOG=ns_coef_ramp_depth_logs/orchestrator.log
echo "[$(date -Is)] orchestrator pid=$$ starting" | tee -a "${ORCH_LOG}"

NPROC=$(nvidia-smi -L | wc -l)
SCRIPT=records/track_3_optimization/train_gpt_simple.py

# Full post-#290 stack (shared across all arms).
export NANOGPT_GRAD_CLIP="${NANOGPT_GRAD_CLIP:-10.0}"
export NANOGPT_NS_ITERS="${NANOGPT_NS_ITERS:-12}"
export NANOGPT_NS_ITERS_COOLDOWN="${NANOGPT_NS_ITERS_COOLDOWN:-16}"
export NANOGPT_NS_COOLDOWN_START_FRAC="${NANOGPT_NS_COOLDOWN_START_FRAC:-0.7}"
export NANOGPT_EMBED_COOLDOWN_SHAPE="${NANOGPT_EMBED_COOLDOWN_SHAPE:-linear_floor}"
export NANOGPT_ADAMW_BETA2="${NANOGPT_ADAMW_BETA2:-0.99}"
export NANOGPT_NS_COOLDOWN_SHAPE="${NANOGPT_NS_COOLDOWN_SHAPE:-late_peak}"
export NANOGPT_NS_COEF_SCHEDULE="${NANOGPT_NS_COEF_SCHEDULE:-linear_ramp_down}"

run_arm() {
  local name="$1"
  local depth="$2"
  local log="ns_coef_ramp_depth_logs/${name}.log"
  echo "[$(date -Is)] launching ${name} NANOGPT_NS_COEF_RAMP_DEPTH=${depth}" \
    | tee -a "${ORCH_LOG}"
  NANOGPT_NS_COEF_RAMP_DEPTH="${depth}" \
    torchrun --standalone --nproc_per_node="${NPROC}" \
    "${SCRIPT}" \
    --wandb_name "g1r4-fern/${name}" \
    --wandb_group "g1r4-fern/ns-coef-ramp-depth" \
    > "${log}" 2>&1
  local rc=$?
  echo "[$(date -Is)] ${name} rc=${rc}" | tee -a "${ORCH_LOG}"
  return $rc
}

run_arm "depth-A-0p42" "0.42"
sleep 15
run_arm "depth-B-0p30" "0.30"
sleep 15
run_arm "depth-C-0p55" "0.55"
sleep 15
run_arm "depth-D-0p70" "0.70"

echo "[$(date -Is)] orchestrator finished arms A/B/C/D" | tee -a "${ORCH_LOG}"
