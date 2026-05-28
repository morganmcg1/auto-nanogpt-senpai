#!/usr/bin/env bash
# PP-promote chain for PR #1567 NM R-buffer freeze-after-K (K=2680 sweet spot).
# Spawns 5 new runs: Arm A (K=0 ctrl) × seeds {1,2} and Arm B (K=2680) × seeds {0,1,2}.
# Seed=0 ctrl is REUSED from prior chain (g3k4vm0r) — not re-spawned.
# Single H100, sequential. Group: g1r4-alphonse/nm-r-freeze-after-k-pp-promote.
set -uo pipefail
cd "$(dirname "$0")"

# (arm K seed name) tuples
RUNS=(
  "A 0 1 g1r4-alphonse-pp-armA-ctrl-seed1"
  "A 0 2 g1r4-alphonse-pp-armA-ctrl-seed2"
  "B 2680 0 g1r4-alphonse-pp-armB-k2680-seed0"
  "B 2680 1 g1r4-alphonse-pp-armB-k2680-seed1"
  "B 2680 2 g1r4-alphonse-pp-armB-k2680-seed2"
)

RUNNER_LOG="${1:-nm_r_freeze_pp_promote_runner.log}"

for entry in "${RUNS[@]}"; do
  read -r arm k seed name <<< "$entry"
  log="nm_r_freeze_pp_arm_${arm}-k${k}-seed${seed}.log"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '[%s] === arm %s K=%s seed=%s name=%s log=%s ===\n' \
    "$ts" "$arm" "$k" "$seed" "$name" "$log" >> "$RUNNER_LOG"
  NANOGPT_GRAD_CLIP=10.0 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_FREEZE_R_AFTER="${k}" \
  SENPAI_SEED="${seed}" \
  NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_name "${name}" \
    --wandb_group "g1r4-alphonse/nm-r-freeze-after-k-pp-promote" \
    >"${log}" 2>&1
  rc=$?
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '[%s] === arm %s seed %s DONE rc=%d log=%s ===\n' \
    "$ts" "$arm" "$seed" "$rc" "$log" >> "$RUNNER_LOG"
done

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '[%s] === PP-promote chain complete ===\n' "$ts" >> "$RUNNER_LOG"
