#!/bin/bash
# Chain runner for NS iter schedule sweep (PR #665). 5 cells x 3250 steps n=1 each.
# Runs sequentially on a single GPU. Logs each cell to a separate file.
set -u  # no -e so we proceed past a single-cell failure
mkdir -p logs_ns_iter

BASE="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 --lr_scalars 0.03"
GROUP="g1r5-tanjiro/ns-iter-schedule-sweep"

run_cell() {
  local cell="$1"
  local schedule="$2"
  local ns_iter_end="$3"
  local wname="$4"
  local logf="logs_ns_iter/${cell}.log"
  echo "[chain] $(date -u +%FT%TZ) START Cell $cell schedule=$schedule end=$ns_iter_end" | tee -a logs_ns_iter/chain.log
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $BASE \
    --ns_iter_schedule "$schedule" --ns_iter_end "$ns_iter_end" \
    --wandb_name "$wname" \
    --wandb_group "$GROUP" \
    > "$logf" 2>&1
  rc=$?
  echo "[chain] $(date -u +%FT%TZ) END   Cell $cell rc=$rc" | tee -a logs_ns_iter/chain.log
}

# Cell A — const ns_iter=6 (control)
run_cell A const 3 "tanjiro-ns-iter-A-const6-n1"

# Cell B — linear_decay 6->3
run_cell B linear_decay 3 "tanjiro-ns-iter-B-decay6to3-n1"

# Cell C — linear_growth 3->6
run_cell C linear_growth 3 "tanjiro-ns-iter-C-growth3to6-n1"

# Cell D — step_at_cooldown 6->3
run_cell D step_at_cooldown 3 "tanjiro-ns-iter-D-step-6to3-at-cooldown-n1"

# Cell E — linear_decay_aggressive 6->2
run_cell E linear_decay_aggressive 2 "tanjiro-ns-iter-E-decay6to2-aggressive-n1"

echo "[chain] $(date -u +%FT%TZ) ALL DONE" | tee -a logs_ns_iter/chain.log
