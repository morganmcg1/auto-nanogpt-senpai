#!/bin/bash
# PR #1549 aux LR warmup sweep — Cells A (ctrl), B (warmup=100), C (200), D (50), E (500).
# Each cell: n=1 seed, 3250 steps, baseline stack
# (--soap_attn --lr_mlp 0.055 --ns_iter 6 --wd_schedule ramp_down --lr_scalars 0.03
#  --depth_init_mode musoft --lr_cooldown_shape cosine).
# Updated 2026-05-28 per advisor poll ~925 to include --lr_cooldown_shape cosine (#1381 merged).
set -u

mkdir -p logs

declare -a CELLS=(
  "A:0:ctrl"
  "B:100:warmup100"
  "C:200:warmup200"
  "D:50:warmup50"
  "E:500:warmup500"
)

STATEFILE="logs/aux_warmup_sweep_state.txt"
: > "$STATEFILE"
echo "sweep_start=$(date -Is)" >> "$STATEFILE"

# W&B 401 confirmed still active 2026-05-28 09:19Z — run offline, sync later.
export WANDB_MODE=offline

for cell_spec in "${CELLS[@]}"; do
  IFS=':' read -r cell warmup label <<< "$cell_spec"
  log="logs/cell_${cell}_aux_warmup.log"
  echo "===== Cell $cell : aux_warmup_steps=$warmup =====" | tee -a "$STATEFILE"
  echo "cell_${cell}_start=$(date -Is)" >> "$STATEFILE"

  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 \
    --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --aux_warmup_steps "$warmup" \
    --wandb_name "g1r5-askeladd/aux-lr-warmup-cell${cell}-${label}-n1" \
    --wandb_group "g1r5-askeladd/aux-lr-warmup" \
    > "$log" 2>&1
  rc=$?
  echo "cell_${cell}_rc=$rc" >> "$STATEFILE"
  echo "cell_${cell}_end=$(date -Is)" >> "$STATEFILE"
done

echo "sweep_end=$(date -Is)" >> "$STATEFILE"
