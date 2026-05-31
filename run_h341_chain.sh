#!/bin/bash
# H341 chain: BODY 2D spectral-norm² penalty M2 mechanism test bisecting
# H326 closure narrowing. Pattern A 3-arm Option B sentinel-constant.
#   arm_a CTRL   : --body_spectral_penalty 0.0  (bit-id with H266; flag default
#                  short-circuits the entire spec block)
#   arm_b LIGHT  : --body_spectral_penalty 1e-5 (mild σ_max suppression)
#   arm_c MEDIUM : --body_spectral_penalty 1e-4 (10× heavier, dose-response)
# Sequential on 1 GPU, ~1h 50m per arm × 3 ≈ 5h 30m.
#
# Smoke gate already passed (run vbxwz4se): step-0 val=10.82583 EXACT,
# body/spec_loss=0.00018, body/spec_sigma_sq_mean=1.83 at step 125 — all in
# target regime, no NaN/inf, Pattern A bit-id confirmed.

set -u
cd /workspace/senpai/target

mkdir -p logs_h341
LOG=/workspace/senpai/target/logs_h341_chain.log

declare -A LAMBDA=(
  [arm_a_CTRL]=0.0
  [arm_b_LIGHT]=1e-5
  [arm_c_MEDIUM]=1e-4
)

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H341_body_spectral_penalty
)

for ARM in arm_a_CTRL arm_b_LIGHT arm_c_MEDIUM; do
  LAM=${LAMBDA[$ARM]}
  ARM_LOG="logs_h341/${ARM}.log"
  echo "===== H341 $ARM (body_spectral_penalty=$LAM) launched at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --body_spectral_penalty "$LAM" \
    --wandb_name "g1r3-frieren/H341_${ARM}" 2>&1 | tee -a "$LOG" "/workspace/senpai/target/${ARM_LOG}"
  echo "===== H341 $ARM finished at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
done

echo "===== H341 chain complete at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
