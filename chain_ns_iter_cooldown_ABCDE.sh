#!/usr/bin/env bash
# Chain runner for PR #1010 NS-iter-by-time (cooldown) sweep.
# Runs A (control), B (primary 6->8 step), C (6->10 step),
# D (6->12 step / boundary), E (6->9 smooth ramp) sequentially on 1 GPU.
set -e -o pipefail

cd "$(dirname "$0")"

LOG_DIR=logs_ns_iter_cooldown
mkdir -p "$LOG_DIR"

COMMON_FLAGS=(
  --num_trials 1
  --soap_attn
  --lr_mlp 0.055
  --wd_schedule ramp_down
  --ns_iter 6
  --lr_scalars 0.03
  --depth_init_mode musoft
)

run_cell() {
  local name=$1
  shift
  local cell_log="$LOG_DIR/${name}.log"
  echo "[$(date -Iseconds)] starting cell $name" | tee -a "$LOG_DIR/chain.log"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    "$@" \
    --wandb_group "g1r5-tanjiro/ns-iter-by-time-cooldown" 2>&1 | tee -a "$cell_log"
  echo "[$(date -Iseconds)] finished cell $name" | tee -a "$LOG_DIR/chain.log"
}

# Cell A — control (baseline; ns_iter=6 throughout)
run_cell A --wandb_name "tanjiro-ns-iter-cd-A-ctrl"

# Cell B PRIMARY — step-jump 6 -> 8 at step 975
run_cell B --ns_iter_cooldown 8 --wandb_name "tanjiro-ns-iter-cd-B-jump8"

# Cell C — step-jump 6 -> 10 at step 975
run_cell C --ns_iter_cooldown 10 --wandb_name "tanjiro-ns-iter-cd-C-jump10"

# Cell D — step-jump 6 -> 12 (boundary probe)
run_cell D --ns_iter_cooldown 12 --wandb_name "tanjiro-ns-iter-cd-D-jump12"

# Cell E — smooth linear ramp 6 -> 9 over cooldown
run_cell E --ns_iter_cooldown 9 --ns_iter_cooldown_ramp --wandb_name "tanjiro-ns-iter-cd-E-ramp9"

echo "[$(date -Iseconds)] all cells finished" | tee -a "$LOG_DIR/chain.log"
