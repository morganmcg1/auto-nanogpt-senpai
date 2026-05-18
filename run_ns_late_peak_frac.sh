#!/usr/bin/env bash
# PR #344: NS late_peak transition point sweep (NANOGPT_NS_LATE_PEAK_FRAC).
# Arms: A=0.25, B=0.50 (control), C=0.75. All use full post-#290 baseline recipe.
set -euo pipefail

cd /workspace/senpai/target
mkdir -p logs/ns344

SCRIPT=records/track_3_optimization/train_gpt_simple.py
NPROC=$(nvidia-smi -L | wc -l)

run_arm() {
  local arm="$1"          # A, B, C
  local frac="$2"         # 0.25, 0.50, 0.75
  local steps="${3:-}"    # optional NANOGPT_TRAIN_STEPS override (smoke)
  local suffix="${4:-}"   # optional wandb name suffix

  local logfile="logs/ns344/arm_${arm}${suffix}.log"
  echo "=== $(date -Is) launching arm ${arm}: NS_LATE_PEAK_FRAC=${frac} STEPS=${steps:-default} ==="

  if [[ -n "$steps" ]]; then
    export NANOGPT_TRAIN_STEPS="${steps}"
  else
    unset NANOGPT_TRAIN_STEPS
  fi

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
      --wandb_name "g1r4-frieren/ns-late-peak-frac-arm-${arm}${suffix}" \
      --wandb_group "g1r4-frieren/ns-late-peak-frac-sweep" \
      2>&1 | tee "$logfile"
  local exitcode=${PIPESTATUS[0]}
  echo "=== $(date -Is) arm ${arm}${suffix} done, exit=${exitcode} ==="
  return $exitcode
}

case "${1:-all}" in
  smoke) run_arm A 0.25 200 -smoke200 ;;
  A) run_arm A 0.25 ;;
  B) run_arm B 0.50 ;;
  C) run_arm C 0.75 ;;
  all)
    run_arm A 0.25
    run_arm B 0.50
    run_arm C 0.75
    ;;
  *) echo "usage: $0 [smoke|A|B|C|all]"; exit 2 ;;
esac
