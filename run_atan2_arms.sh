#!/bin/bash
# Sequential runner for Adam-atan2 sweep (PR #442).
# 4 arms: A=0.0 (control), B=1.0 (paper default), C=0.3, D=3.0.
# Single GPU; one arm at a time. Logs to atan2_arm_<X>.log.
# Shared envs include NANOGPT_ADAMW_EMBED_LR_MULT=1.5 (post-#393 baseline).

set -uo pipefail
cd /workspace/senpai/target

GROUP="g1r4-alphonse/adam-atan2"
SCRIPT="records/track_3_optimization/train_gpt_simple.py"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

run_arm() {
  local arm_id="$1"
  local atan2_b="$2"
  local short="$3"
  local logfile="atan2_arm_${arm_id}.log"

  echo "=== ARM ${arm_id^^} (atan2_b=${atan2_b}) start $(ts) ==="
  env \
    NANOGPT_GRAD_CLIP=10.0 \
    NANOGPT_NS_ITERS=12 \
    NANOGPT_NS_ITERS_COOLDOWN=16 \
    NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 \
    NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    NANOGPT_ADAMW_ATAN2_B="${atan2_b}" \
    torchrun --standalone --nproc_per_node=1 \
      "${SCRIPT}" \
      --wandb_name "g1r4-alphonse/atan2-${arm_id}-${short}" \
      --wandb_group "${GROUP}" \
    2>&1 | tee "${logfile}"
  local rc="${PIPESTATUS[0]}"
  echo "=== ARM ${arm_id^^} exit=${rc} at $(ts) ==="
  return "${rc}"
}

ARM="${1:-all}"
case "${ARM}" in
  a|A) run_arm a 0.0 control ;;
  b|B) run_arm b 1.0 b1 ;;
  c|C) run_arm c 0.3 b0p3 ;;
  d|D) run_arm d 3.0 b3 ;;
  bcd)
    run_arm b 1.0 b1   || exit 1
    run_arm c 0.3 b0p3 || exit 1
    run_arm d 3.0 b3   || exit 1
    ;;
  all)
    run_arm a 0.0 control || exit 1
    run_arm b 1.0 b1      || exit 1
    run_arm c 0.3 b0p3    || exit 1
    run_arm d 3.0 b3      || exit 1
    ;;
  *) echo "Usage: $0 [a|b|c|d|bcd|all]"; exit 2 ;;
esac
