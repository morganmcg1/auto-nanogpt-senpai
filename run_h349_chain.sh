#!/bin/bash
# H349 chain: M4a Top-K right-singular-subspace alignment penalty on BODY 2D
# weights at H266 stack. K=2 fixed, only λ varies across arms.
#   arm_a CTRL    : body_subspace_penalty=0.0  (H266 bit-id short-circuit)
#   arm_b LIGHT   : body_subspace_penalty=2e-6 (mirrors H326 fnorm_matched best dose)
#   arm_c MEDIUM  : body_subspace_penalty=2e-5 (10× LIGHT — dose-response)
# Sequential on 1 GPU, ~1h 50m per arm × 3 ≈ 5h 30m.

set -u
cd /workspace/senpai/target

mkdir -p logs_h349
LOG=/workspace/senpai/target/logs_h349_chain.log

declare -A PENALTY=(
  [arm_a_CTRL]=0.0
  [arm_b_LIGHT]=2e-6
  [arm_c_MEDIUM]=2e-5
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
  --body_subspace_k 2
  --wandb_project modded-nanogpt-senpai
  --wandb_group H349_body_subspace_alignment_m4a
)

for ARM in arm_a_CTRL arm_b_LIGHT arm_c_MEDIUM; do
  PEN=${PENALTY[$ARM]}
  ARM_LOG="logs_h349/${ARM}.log"
  echo "===== H349 $ARM (body_subspace_penalty=$PEN k=2) launched at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --body_subspace_penalty "$PEN" \
    --wandb_name "g1r3-frieren/H349_${ARM}" 2>&1 | tee -a "$LOG" "/workspace/senpai/target/${ARM_LOG}"
  echo "===== H349 $ARM finished at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
done

echo "===== H349 chain complete at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
