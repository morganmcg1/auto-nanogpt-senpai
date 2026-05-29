#!/usr/bin/env bash
# PR #1631 NM β EMA-decay PP-promote n=3 chain.
# Promoting Arm C β=0.99 stable (STRONG-FAV N=1 Δ_paired=-0.00166) to n=3.
# Reuse:
#   PP-ctrl-s0 = Arm A `eqwdajvx` (β=0.95, SENPAI_SEED=0) — bit-identity from chain c548
#   PP-exp-s0  = Arm C `gkq44e98` (β=0.99, SENPAI_SEED=0) — bit-identity from chain c548
# Fresh runs in this chain (4 runs, ~9-10h total):
#   PP-ctrl-s1 (SENPAI_SEED=1, β=0.95)
#   PP-ctrl-s2 (SENPAI_SEED=2, β=0.95)
#   PP-exp-s1  (SENPAI_SEED=1, β=0.99)
#   PP-exp-s2  (SENPAI_SEED=2, β=0.99)
#
# Train file: records/track_3_optimization/_pr_nm_beta_train_gpt_simple.py
# Logs:      run_logs/nm_beta_pp_{ctrl,exp}_s{1,2}.log
# W&B group: g1r4-thorfinn/nm-beta-ema-schedule-pp
set -uo pipefail
cd "/workspace/senpai/target"

mkdir -p run_logs
CHAIN_LOG="run_logs/nm_beta_pp_chain.log"
echo "[pp-chain] start $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$CHAIN_LOG"

# Production stack (post-#1421). Unchanged across all runs. SEED set per-run.
COMMON_ENV=(
  NANOGPT_GRAD_CLIP_BODY=10.0
  NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_ADAMW_BETA2=0.99
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_MUON_ATTN_LR_MULT=0.80
  NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_NS_ITERS=12
  NANOGPT_NS_ITERS_COOLDOWN=16
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_NEWTON_MUON=1
  NANOGPT_NEWTON_MUON_EPS=1e-4
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096
)

run_pp() {
  local tag="$1"; shift          # e.g. ctrl_s1
  local wandb_name="$1"; shift   # e.g. g1r4-thorfinn/PP-ctrl-s1
  local seed="$1"; shift          # SENPAI_SEED value
  local beta="$1"; shift          # NM β value
  local logf="run_logs/nm_beta_pp_${tag}.log"
  echo "[pp-chain] === $tag start $(date -u +%Y-%m-%dT%H:%M:%SZ) seed=$seed beta=$beta ===" | tee -a "$CHAIN_LOG"
  echo "[pp-chain] $tag wandb_name: $wandb_name" | tee -a "$CHAIN_LOG"
  env "${COMMON_ENV[@]}" \
      SENPAI_SEED="$seed" \
      NANOGPT_NEWTON_MUON_BETA="$beta" \
    torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/_pr_nm_beta_train_gpt_simple.py \
    --wandb_name "$wandb_name" \
    --wandb_group "g1r4-thorfinn/nm-beta-ema-schedule-pp" \
    > "$logf" 2>&1
  local rc=$?
  echo "[pp-chain] === $tag end $(date -u +%Y-%m-%dT%H:%M:%SZ) rc=$rc ===" | tee -a "$CHAIN_LOG"
  if [[ $rc -ne 0 ]]; then
    echo "[pp-chain] ERROR: $tag failed (rc=$rc). Continuing chain anyway." | tee -a "$CHAIN_LOG"
  fi
  return $rc
}

# Order matches advisor c548 mandate: ctrl_s1 → ctrl_s2 → exp_s1 → exp_s2.
# 1) PP-ctrl-s1 (β=0.95)
run_pp ctrl_s1 "g1r4-thorfinn/PP-ctrl-s1-beta0.95" 1 0.95
# 2) PP-ctrl-s2 (β=0.95) — full n=3 ctrl envelope after this
run_pp ctrl_s2 "g1r4-thorfinn/PP-ctrl-s2-beta0.95" 2 0.95
# 3) PP-exp-s1 (β=0.99) — first paired Δ at s1 after this
run_pp exp_s1  "g1r4-thorfinn/PP-exp-s1-beta0.99"  1 0.99
# 4) PP-exp-s2 (β=0.99) — full n=3 paired matrix after this (+ reused s0)
run_pp exp_s2  "g1r4-thorfinn/PP-exp-s2-beta0.99"  2 0.99

echo "[pp-chain] all runs complete $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$CHAIN_LOG"
