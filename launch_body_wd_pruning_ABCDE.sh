#!/bin/bash
set -uo pipefail

cd /workspace/senpai/target

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# All 5 cells share the same baseline stack (PR #699 musoft)
COMMON="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-edward/body-wd-pruning"

# Kill-gate thresholds from PR #1284.
# Step 500: catastrophic divergence (val > 5.0) → ABORT
# Step 2000 (E only): mid-trajectory check (val > 3.40) → KILL (over-shrinkage)
KILL_500_THRESHOLD=5.0
KILL_E_2000_THRESHOLD=3.40

mkdir -p runlogs

check_step_threshold() {
  local cell="$1"
  local log="$2"
  local step="$3"
  local threshold="$4"
  local label="$5"
  # Find val_loss at the requested step
  local val
  val=$(grep -E "step:${step}/[0-9]+.*val_loss" "$log" 2>/dev/null | head -1 | sed -E 's/.*val_loss:([0-9.]+).*/\1/')
  if [ -z "$val" ]; then
    # Step boundary may not have been reached (run still going) — treat as pass
    echo "[$(ts)] kill-gate $label for $cell: no step:${step} val_loss found yet"
    return 0
  fi
  if awk -v v="$val" -v t="$threshold" 'BEGIN{exit !(v > t)}'; then
    echo "[$(ts)] KILL_GATE $label TRIPPED on $cell: val_loss at step ${step} = $val > $threshold"
    return 1
  fi
  echo "[$(ts)] kill-gate $label PASS for $cell: val_loss at step ${step} = $val <= $threshold"
  return 0
}

check_nonfinite() {
  local cell="$1"
  local log="$2"
  local has_nonfinite
  has_nonfinite=$(grep -ciE "(nan|inf)\b" "$log" 2>/dev/null | head -1)
  if [ "${has_nonfinite:-0}" -gt 0 ]; then
    echo "[$(ts)] nonfinite detected in $cell log"
    return 1
  fi
  return 0
}

run_cell() {
  local cell="$1"
  local wd="$2"
  local desc="$3"
  local logname="body_wd_${cell}_${desc}.log"
  local wandb_name="body-wd-${cell}-${desc}-n1"
  echo "[$(ts)] Starting Cell ${cell}: wd_mlp=wd_attn=${wd} desc=${desc}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $COMMON \
    --wd_mlp "$wd" --wd_attn "$wd" \
    --wandb_name "$wandb_name" \
    --wandb_group "$GROUP" \
    > "runlogs/$logname" 2>&1
  local rc=$?
  echo "[$(ts)] Cell ${cell} exit=$rc log=runlogs/$logname"
  if [ "$rc" -ne 0 ]; then
    echo "[$(ts)] Cell ${cell} non-zero exit; continuing to next cell"
    return 1
  fi
  return 0
}

# Order: A (ctrl baseline) -> B ★ (PRIMARY, no WD) -> C (half) -> D (double) -> E (over-WD falsifier)
run_cell "A" "0.025"  "ctrl"
run_cell "B" "0.0"    "zero"
run_cell "C" "0.0125" "half"
run_cell "D" "0.05"   "double"
run_cell "E" "0.10"   "overwd"

echo "[$(ts)] All cells done."
