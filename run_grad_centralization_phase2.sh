#!/bin/bash
# Phase 2 n=1 sweep for PR #1885 (Gradient Centralization, fern).
# Runs Cells A (none), B (muon_mlp_only), C (muon_all) sequentially at 3250 steps.
set -uo pipefail

cd "$(dirname "$0")"

CELLS=(
  "A-ctrl|none"
  "B-mlp-only|muon_mlp_only"
  "C-all-muon|muon_all"
)

for entry in "${CELLS[@]}"; do
  IFS='|' read -r tag mode <<< "$entry"
  log="logs/gc_${tag}.log"
  echo "[orchestrator] launching cell ${tag} (gc_mode=${mode}) → ${log}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --grad_centralization "${mode}" \
    --wandb_name "g1r5-fern/grad-centralization-${tag}" \
    --wandb_group "g1r5-fern/grad-centralization" \
    > "${log}" 2>&1
  rc=$?
  echo "[orchestrator] cell ${tag} finished with rc=${rc}"
  if [ "${rc}" -ne 0 ]; then
    echo "[orchestrator] ABORT — cell ${tag} returned rc=${rc}"
    exit "${rc}"
  fi
done

echo "[orchestrator] all 3 cells complete"
