#!/bin/bash
set -uo pipefail

# Launcher for PR #1563 — NS post-NS aspect-ratio scale exponent ablation.
# Modifies max(1, m/n)**exp in muon_update (line 521) and soap_ns_step (line 528).
# 5 cells at n=1, single-seed, sequential.

cd /workspace/senpai/target

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

COMMON="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine"
GROUP="edward-ns-scale-exp"

echo "[$(ts)] ABCDE Launcher starting. PID=$$"

run_cell() {
  local cell="$1"
  local exp="$2"
  local desc="$3"
  local logname="ns_scale_exp_${cell}_${desc}.log"
  local wandb_name="g1r5-edward/ns-scale-exp-${cell}-${desc}-n1"
  echo "[$(ts)] Starting Cell ${cell}: ns_scale_exponent=${exp} desc=${desc}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $COMMON \
    --ns_scale_exponent "$exp" \
    --wandb_name "$wandb_name" \
    --wandb_group "$GROUP" \
    > "runlogs/$logname" 2>&1
  local rc=$?
  echo "[$(ts)] Cell ${cell} exit=$rc log=runlogs/$logname"
  return $rc
}

run_cell "A" "0.5"  "exp05-ctrl"
run_cell "B" "0.25" "exp025-primary"
run_cell "C" "0.75" "exp075"
run_cell "D" "1.0"  "exp10"
run_cell "E" "0.0"  "exp00-falsifier"

echo "[$(ts)] ABCDE launcher done."
