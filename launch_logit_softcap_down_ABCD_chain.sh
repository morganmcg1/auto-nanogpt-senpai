#!/bin/bash
# Sequential chain: A_ctrl(15) -> B*(12.5) -> C(10) -> D(17.5)
# Each cell n=1, 3250 steps, ~1.8h each, ~7.2h total
set -euo pipefail
mkdir -p runlogs
CHAIN_LOG=runlogs/logit_softcap_down_ABCD_chain.log
PIDFILE=runlogs/logit_softcap_down_ABCD_chain.pid

run_cell() {
  local tag=$1 cap=$2 wname=$3
  local cell_log=runlogs/logit_softcap_down_${tag}.log
  echo "[$(date -u +%H:%M:%SZ)] Launching $tag cap=$cap" | tee -a "$CHAIN_LOG"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
    --logit_softcap_value "$cap" \
    --wandb_name "g1r5-edward/${wname}" \
    --wandb_group "g1r5-edward/logit-softcap-down" \
    > "$cell_log" 2>&1
  local rc=$?
  echo "[$(date -u +%H:%M:%SZ)] $tag finished rc=$rc log=$cell_log" | tee -a "$CHAIN_LOG"
}

(
  run_cell "A_ctrl"  "15.0"  "logit-softcap-down-Actrl-cap15-n1"
  run_cell "B"       "12.5"  "logit-softcap-down-Bstar-cap12.5-n1"
  run_cell "C"       "10.0"  "logit-softcap-down-C-cap10-n1"
  run_cell "D"       "17.5"  "logit-softcap-down-D-cap17.5-n1"
  echo "[$(date -u +%H:%M:%SZ)] CHAIN COMPLETE" | tee -a "$CHAIN_LOG"
) &
echo "PID=$!" > "$PIDFILE"
echo "Launched chain PID=$! log=$CHAIN_LOG"
