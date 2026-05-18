#!/bin/bash
# Phase 1 Muon weight decay sweep — 5 cells sequential n=1.
# Each cell: 3250 steps, --soap_attn --lr_mlp 0.055.
# Cells tie wd_mlp = wd_attn.
set -u  # No -e: keep going on cell failures.

mkdir -p logs

declare -a CELLS=(
  "A:0.000"
  "B:0.010"
  "C:0.025"
  "D:0.050"
  "E:0.100"
)

STATEFILE="logs/muon_wd_sweep_state.txt"
: > "$STATEFILE"
echo "sweep_start=$(date -Is)" >> "$STATEFILE"

for cell_spec in "${CELLS[@]}"; do
  IFS=':' read -r cell wd <<< "$cell_spec"
  log="logs/muon_wd_${cell}.log"
  echo "===== Cell $cell : wd=$wd =====" | tee -a "$STATEFILE"
  echo "cell_${cell}_start=$(date -Is)" >> "$STATEFILE"

  # Cell C is the control — omit wd flags so defaults (0.025) apply.
  if [ "$cell" = "C" ]; then
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 --soap_attn --lr_mlp 0.055 \
      --wandb_name "g1r5-askeladd/muon-wd-${cell}-025-ctrl-n1" \
      --wandb_group "g1r5-askeladd/muon-wd-sweep" \
      > "$log" 2>&1
  else
    # Format wd for the name: 0.000 → 000, 0.010 → 010, 0.050 → 050, 0.100 → 100
    wd_label=$(awk -v w="$wd" 'BEGIN { printf "%03d", w * 1000 }')
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 --soap_attn --lr_mlp 0.055 \
      --wd_mlp "$wd" --wd_attn "$wd" \
      --wandb_name "g1r5-askeladd/muon-wd-${cell}-${wd_label}-n1" \
      --wandb_group "g1r5-askeladd/muon-wd-sweep" \
      > "$log" 2>&1
  fi
  rc=$?
  echo "cell_${cell}_rc=$rc" >> "$STATEFILE"
  echo "cell_${cell}_end=$(date -Is)" >> "$STATEFILE"
done

echo "sweep_end=$(date -Is)" >> "$STATEFILE"
