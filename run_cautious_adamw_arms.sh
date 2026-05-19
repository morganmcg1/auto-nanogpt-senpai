#!/bin/bash
# Sequential runner for cautious-AdamW 4-arm sweep (PR #419, Liang et al. 2024).
# All arms use the current merged baseline stack; only cautious env vars vary.
# Arms A/B/C/D x ~1h45m each on 1 GPU ≈ 7h wall clock.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs_cautious

# Merged-baseline stack (matches BASELINE.md through PR #290, val/loss=3.27200)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=20
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99

run_arm () {
    local arm="$1"; shift
    local name="$1"; shift
    local logfile="logs_cautious/arm_${arm}.log"
    echo "===== START arm $arm $(date -u +%FT%TZ) =====" | tee -a "$logfile"
    echo "CAUTIOUS_ADAMW=$NANOGPT_CAUTIOUS_ADAMW RESCALE=$NANOGPT_CAUTIOUS_RESCALE SCOPE=$NANOGPT_CAUTIOUS_SCOPE" | tee -a "$logfile"
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "$name" \
      --wandb_group "askeladd_cautious_adamw" >> "$logfile" 2>&1
    local rc=$?
    echo "===== END arm $arm rc=$rc $(date -u +%FT%TZ) =====" | tee -a "$logfile"
    return $rc
}

# Arm A: control (cautious off)
NANOGPT_CAUTIOUS_ADAMW=0 NANOGPT_CAUTIOUS_RESCALE=1 NANOGPT_CAUTIOUS_SCOPE=all \
  run_arm A "g1r4-askeladd/cautious-A-off"

# Arm B: paper default (rescaled mask, full scope)
NANOGPT_CAUTIOUS_ADAMW=1 NANOGPT_CAUTIOUS_RESCALE=1 NANOGPT_CAUTIOUS_SCOPE=all \
  run_arm B "g1r4-askeladd/cautious-B-all-rescale"

# Arm C: plain mask (no rescale; smaller effective step)
NANOGPT_CAUTIOUS_ADAMW=1 NANOGPT_CAUTIOUS_RESCALE=0 NANOGPT_CAUTIOUS_SCOPE=all \
  run_arm C "g1r4-askeladd/cautious-C-all-plain"

# Arm D: embed-only cautious (orthogonality probe)
NANOGPT_CAUTIOUS_ADAMW=1 NANOGPT_CAUTIOUS_RESCALE=1 NANOGPT_CAUTIOUS_SCOPE=embed \
  run_arm D "g1r4-askeladd/cautious-D-embed"

echo "ALL ARMS DONE $(date -u +%FT%TZ)"
