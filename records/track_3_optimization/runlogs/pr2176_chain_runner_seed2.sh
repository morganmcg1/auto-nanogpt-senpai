#!/usr/bin/env bash
# PR #2176 - Tikhonov gamma=0.025 PP-confirm @ SEED=2 (n=3 cohort completion)
# 2-arm paired sequential chain on 1 GPU:
#   Arm A (ctrl): NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 (production)
#   Arm B (test): NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.025 (5x UP test)
# Both arms SEED=2; all other env vars from production stack (post-#1702).
# Advisor decision c790g-34: APPROVE SEED=2 chain — protocol completion for catalog promotion.
#
# flock(fd=200) prevents concurrent chain-runner invocations clobbering each other.

set -u
LOGDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_ROOT="$(cd "$LOGDIR/../../.." && pwd)"
LOCKFILE="$LOGDIR/pr2176_chain_seed2.lock"
STATE="$LOGDIR/pr2176_chain_seed2.state"
PIDFILE="$LOGDIR/pr2176_chain_runner_seed2.pid"

mark() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$STATE"; }

exec 200>"$LOCKFILE"
if ! flock -n 200; then
  mark "FLOCK_BUSY another instance holds $LOCKFILE; aborting"
  exit 99
fi
echo "$$" > "$PIDFILE"

cd "$REPO_ROOT"

COMMON_ENV=(
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
  SENPAI_SEED=2
)

run_arm() {
  local arm="$1"; local gamma="$2"; local tag="$3"
  local log="$LOGDIR/pr2176_seed2_arm${arm}_gamma${gamma}.log"
  mark "ARM_${arm}_START gamma=${gamma} tag=${tag} log=${log}"
  env "${COMMON_ENV[@]}" NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA="$gamma" \
    torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-tanjiro/gamma-0.025-pp-confirm-seed2-arm${arm}" \
    --wandb_group "g1r4-tanjiro-gamma-0.025-pp-confirm-seed2" \
    > "$log" 2>&1
  local rc=$?
  mark "ARM_${arm}_END rc=${rc}"
  return $rc
}

mark "CHAIN_START pid=$$ host=$(hostname)"
run_arm A 0.005 ctrl-prod || { mark "ARM_A_FAILED"; exit 1; }
run_arm B 0.025 test-5x   || { mark "ARM_B_FAILED"; exit 2; }
mark "CHAIN_DONE"
