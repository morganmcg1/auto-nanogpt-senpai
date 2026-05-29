#!/usr/bin/env bash
# 5-cell sweep for per-group EMA-eval decay decoupling (PR #1659).
# Cells: A (ctrl), B★ (primary, d_body=0.95), C (0.97), D (0.999), E falsifier (0.90).
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p logs/per-group-ema

COMMON=(--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055
        --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft
        --lr_cooldown_shape cosine --ema_eval_decay 0.99
        --wandb_group "g1r5-askeladd/per-group-ema-decay")

run_cell () {
  local cell="$1"; shift
  local name="$1"; shift
  local logfile="logs/per-group-ema/${cell}.log"
  echo "=== Cell ${cell}: ${name} ===" | tee -a "${logfile}"
  date | tee -a "${logfile}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --wandb_name "g1r5-askeladd/per-group-ema-${name}" \
    "$@" 2>&1 | tee -a "${logfile}"
  echo "=== Cell ${cell} DONE ===" | tee -a "${logfile}"
  date | tee -a "${logfile}"
}

# Cell A: ctrl - uniform 0.99 (no body decay)
run_cell A "cellA-ctrl"

# Cell B (primary): d_body=0.95 - body faster (~20 step window)
run_cell B "cellB-body095" --ema_eval_decay_body 0.95

# Cell C: d_body=0.97 - body slightly faster (~33 step window)
run_cell C "cellC-body097" --ema_eval_decay_body 0.97

# Cell D: d_body=0.999 - body slower (~1000 step window)
run_cell D "cellD-body0999" --ema_eval_decay_body 0.999

# Cell E (falsifier): d_body=0.90 - body extreme fast (~10 step window)
run_cell E "cellE-body090" --ema_eval_decay_body 0.90

echo "=== ALL CELLS COMPLETE ==="
date
