#!/usr/bin/env bash
# PR #344 paired confirmation: NANOGPT_NS_LATE_PEAK_FRAC paired comparison.
# Pod 1: A2 (0.25) -> B2 (0.50); Pod 2: A3 (0.25) -> B3 (0.50).
# This pod is "frieren has 1 pod, so sequential": A2 -> B2 -> A3 -> B3.
set -euo pipefail

cd /workspace/senpai/target
mkdir -p logs/ns344

SCRIPT=records/track_3_optimization/train_gpt_simple.py
NPROC=$(nvidia-smi -L | wc -l)

run_arm() {
  local arm="$1"          # A2, B2, A3, B3
  local frac="$2"         # 0.25, 0.50
  local suffix="$3"       # 0p25 or 0p50 (wandb-friendly fraction)

  local logfile="logs/ns344/confirm_${arm}.log"
  echo "=== $(date -Is) launching ${arm}: NS_LATE_PEAK_FRAC=${frac} ==="

  unset NANOGPT_TRAIN_STEPS

  NANOGPT_GRAD_CLIP=10.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_LATE_PEAK_FRAC="${frac}" \
    torchrun --standalone --nproc_per_node=${NPROC} \
      "$SCRIPT" \
      --wandb_name "g1r4-frieren/late-peak-${arm}-${suffix}" \
      --wandb_group "g1r4-frieren/ns-late-peak-frac-sweep" \
      2>&1 | tee "$logfile"
  local exitcode=${PIPESTATUS[0]}
  echo "=== $(date -Is) ${arm} done, exit=${exitcode} ==="
  return $exitcode
}

case "${1:-all}" in
  A2) run_arm A2 0.25 0p25 ;;
  B2) run_arm B2 0.50 0p50 ;;
  A3) run_arm A3 0.25 0p25 ;;
  B3) run_arm B3 0.50 0p50 ;;
  pair1) run_arm A2 0.25 0p25 && run_arm B2 0.50 0p50 ;;
  pair2) run_arm A3 0.25 0p25 && run_arm B3 0.50 0p50 ;;
  all)
    run_arm A2 0.25 0p25
    run_arm B2 0.50 0p50
    run_arm A3 0.25 0p25
    run_arm B3 0.50 0p50
    ;;
  *) echo "usage: $0 [A2|B2|A3|B3|pair1|pair2|all]"; exit 2 ;;
esac
