#!/usr/bin/env bash
# Position-weighted CE 4-arm sweep (PR #801).
# A=uniform/0.0, B=linear_up/0.5, C=linear_down/0.5, D=linear_down/1.5.
set -uo pipefail

cd /workspace/senpai/target

LOG_DIR="/workspace/senpai/target/logs_pos_ce"
mkdir -p "$LOG_DIR"

BASE_ENVS=(
  NANOGPT_GRAD_CLIP=10.0
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
)

run_arm() {
  local arm_id="$1" shape="$2" alpha="$3"
  local name="g1r4-askeladd-pos-ce-arm-${arm_id}"
  local log="$LOG_DIR/arm-${arm_id}.log"
  echo "===== launching arm ${arm_id} shape=${shape} alpha=${alpha} at $(date -u +%FT%TZ) =====" \
    | tee -a "$LOG_DIR/runner.log"
  env "${BASE_ENVS[@]}" \
    NANOGPT_POS_LOSS_SHAPE="$shape" \
    NANOGPT_POS_LOSS_ALPHA="$alpha" \
    torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "$name" \
      --wandb_group "g1r4-askeladd/position-weighted-ce" \
      >"$log" 2>&1
  local rc=$?
  echo "===== arm ${arm_id} done at $(date -u +%FT%TZ) exit=${rc} =====" \
    | tee -a "$LOG_DIR/runner.log"
  return $rc
}

run_arm A uniform 0.0
run_arm B linear_up 0.5
run_arm C linear_down 0.5
run_arm D linear_down 1.5

echo "===== ALL ARMS DONE at $(date -u +%FT%TZ) =====" | tee -a "$LOG_DIR/runner.log"
