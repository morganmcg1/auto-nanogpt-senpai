#!/usr/bin/env bash
# Orchestrate 3-arm sequential chain for PR #1943:
# MUON_ATTN_LR_MULT / MUON_MLP_LR_MULT bracket post-Newton-Muon.
# SENPAI_SEED=0 chain-internal paired-pod (causal isolated per c645).

set -euo pipefail

cd /workspace/senpai/target

LOG_DIR=muon_lr_mult_post_nm_logs
mkdir -p "$LOG_DIR"

NPROC=$(nvidia-smi -L | wc -l)

# Common env vars (post-#1702 production stack).
export SENPAI_SEED=0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100

run_arm () {
  local arm_id="$1"   # A, B, C
  local arm_tag="$2"  # ctrl, soften, harden
  local attn_mult="$3"
  local mlp_mult="$4"

  local log_file="$LOG_DIR/arm${arm_id}_${arm_tag}.log"
  local pid_file="$LOG_DIR/arm${arm_id}.pid"
  local wandb_name="g1r4-fern/muon-lr-mult-arm${arm_id}-${arm_tag}-s0"
  local wandb_group="g1r4-fern/muon-lr-mult-bracket-post-nm"

  echo "================================================================" | tee "$log_file"
  echo "[orchestrator] Arm ${arm_id} ${arm_tag}  attn=${attn_mult} mlp=${mlp_mult}" | tee -a "$log_file"
  echo "[orchestrator] launched $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log_file"
  echo "================================================================" | tee -a "$log_file"

  export NANOGPT_MUON_ATTN_LR_MULT="$attn_mult"
  export NANOGPT_MUON_MLP_LR_MULT="$mlp_mult"

  torchrun --standalone --nproc_per_node="$NPROC" \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "$wandb_name" \
    --wandb_group "$wandb_group" \
    >> "$log_file" 2>&1 &

  local pid=$!
  echo "$pid" > "$pid_file"
  echo "[orchestrator] arm${arm_id} pid=${pid}" | tee -a "$log_file"

  wait "$pid"
  local rc=$?
  echo "[orchestrator] arm${arm_id} exited rc=${rc} at $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$log_file"
  return "$rc"
}

run_arm A ctrl   0.80 1.20
run_arm B soften 0.90 1.10
run_arm C harden 0.70 1.30

echo "[orchestrator] All 3 arms complete at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
