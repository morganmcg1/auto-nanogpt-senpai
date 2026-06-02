#!/bin/bash
# PR #2204 — GRAD_CLIP_AUX 3-arm bracket {2.5, 5 ctrl, 10}
# Same SEED=0 across all 3 arms for bit-id step:0 + paired Δ comparison.
# Modern stack (post-#1702 NM v-warmstart × Tikhonov composite).
set -uo pipefail
cd "$(dirname "$0")"

# flock guard (per [[chain-handoff-race-window-catalog]])
exec 200>/tmp/pr2204_chain.lock
if ! flock -n 200; then
  echo "[CHAIN-GUARD] Another instance holds /tmp/pr2204_chain.lock — refusing to start." >&2
  exit 11
fi

# Pre-launch sanity check — match only python processes running the script
# (filter out the bash invoker which also contains the literal string).
existing_procs="$(ps -eo pid,comm,args | awk '$2 ~ /python/ && /train_gpt_simple\.py/' || true)"
if [[ -n "${existing_procs}" ]]; then
  echo "[PRE-LAUNCH] FAIL: existing train_gpt_simple python process detected:" >&2
  printf '%s\n' "${existing_procs}" >&2
  exit 12
fi
gpu_mib=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')
if [[ -n "$gpu_mib" && "$gpu_mib" -gt 200 ]]; then
  echo "[PRE-LAUNCH] FAIL: GPU shows ${gpu_mib} MiB used (>200 MiB threshold)" >&2
  nvidia-smi >&2
  exit 13
fi
echo "[PRE-LAUNCH] OK: no train_gpt_simple processes, GPU at ${gpu_mib:-unknown} MiB"

# Modern production stack envs (post-#1702, matches ws7mk8ul/2qoqjwqv anchors).
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_GRAD_CLIP_BODY=10.0
# NANOGPT_GRAD_CLIP_AUX set per-arm below.
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=1e-4
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export SENPAI_SEED=0
export PYTHONUNBUFFERED=1

mkdir -p run_logs
CHAIN_LOG="run_logs/grad_clip_aux_chain_runner.log"

GROUP="thorfinn-grad-clip-aux-bracket"

run_arm () {
  local label="$1"
  local clip="$2"
  local wname="$3"
  local log="run_logs/grad_clip_aux_arm_${label}.log"
  echo "==============================================" | tee -a "$CHAIN_LOG"
  echo "Arm ${label}: clip=${clip} | $(date -u +%FT%TZ)" | tee -a "$CHAIN_LOG"
  echo "  wandb_name=${wname}" | tee -a "$CHAIN_LOG"
  echo "  log=${log}" | tee -a "$CHAIN_LOG"
  echo "==============================================" | tee -a "$CHAIN_LOG"
  export NANOGPT_GRAD_CLIP_AUX="${clip}"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "${wname}" \
    --wandb_group "${GROUP}" \
    >> "${log}" 2>&1
  local rc=$?
  echo "Arm ${label} exit code: ${rc} | $(date -u +%FT%TZ)" | tee -a "$CHAIN_LOG"
  return $rc
}

echo "===== START PR2204 grad-clip-aux 3-arm chain $(date -u +%FT%TZ) =====" | tee -a "$CHAIN_LOG"

run_arm A 5.0  "g1r4-thorfinn/arm-A-grad-clip-aux-5"   || { echo "Arm A failed at $(date -u +%FT%TZ)" | tee -a "$CHAIN_LOG"; exit 21; }
run_arm B 2.5  "g1r4-thorfinn/arm-B-grad-clip-aux-2.5" || { echo "Arm B failed at $(date -u +%FT%TZ)" | tee -a "$CHAIN_LOG"; exit 22; }
run_arm C 10.0 "g1r4-thorfinn/arm-C-grad-clip-aux-10"  || { echo "Arm C failed at $(date -u +%FT%TZ)" | tee -a "$CHAIN_LOG"; exit 23; }

echo "===== END PR2204 grad-clip-aux 3-arm chain $(date -u +%FT%TZ) =====" | tee -a "$CHAIN_LOG"
