#!/bin/bash
# AdEMAMix on AdamW aux — 5-cell n=1 sweep
# PR #1490 — g1r5-askeladd/ademamix-aux
#
# Cells:
#   A: control (no --use_ademamix) — baseline reproducer
#   B*: paper default (β3=0.9999, α=5.0) — PRIMARY
#   C: low α (β3=0.9999, α=2.0)
#   D: low β3 (β3=0.999, α=5.0)
#   E: falsifier (β3=0.99, α=5.0)
#
# Sequential on 1 GPU, ~1.7h per cell ≈ 8.5h total.

set -u
cd "$(dirname "$0")"

LOG_DIR="logs/ademamix_bcde"
mkdir -p "$LOG_DIR"

BASE_FLAGS=(
  --num_trials 1
  --ns_iter 6
  --soap_attn
  --lr_mlp 0.055
  --wd_schedule ramp_down
  --lr_scalars 0.03
  --depth_init_mode musoft
)

WANDB_GROUP="g1r5-askeladd/ademamix-aux"

run_cell () {
  local label=$1
  shift
  local name=$1
  shift
  local logfile="$LOG_DIR/cell_${label}.log"
  echo "=== Cell ${label}: ${name} === $(date -u +%FT%TZ)"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_FLAGS[@]}" \
    "$@" \
    --wandb_name "${name}" \
    --wandb_group "${WANDB_GROUP}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "=== Cell ${label} done rc=${rc} $(date -u +%FT%TZ) ==="
  return $rc
}

# A — control (no AdEMAMix)
run_cell A "ademamix-cellA-ctrl-n1" || exit 1
# B★ — paper default
run_cell B "ademamix-cellB-b30.9999-a5.0-n1" --use_ademamix --ademamix_beta3 0.9999 --ademamix_alpha 5.0 || exit 1
# C — low α
run_cell C "ademamix-cellC-b30.9999-a2.0-n1" --use_ademamix --ademamix_beta3 0.9999 --ademamix_alpha 2.0 || exit 1
# D — low β3
run_cell D "ademamix-cellD-b30.999-a5.0-n1"  --use_ademamix --ademamix_beta3 0.999  --ademamix_alpha 5.0 || exit 1
# E — falsifier
run_cell E "ademamix-cellE-b30.99-a5.0-n1"   --use_ademamix --ademamix_beta3 0.99   --ademamix_alpha 5.0 || exit 1

echo "ALL CELLS COMPLETE $(date -u +%FT%TZ)"
