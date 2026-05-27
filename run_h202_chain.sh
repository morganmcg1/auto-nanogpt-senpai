#!/bin/bash
# H202 3-arm chain: arm_a CTRL → arm_b SF_NO_COOLDOWN → arm_c SF_KEEP_COOLDOWN
# Total wall-clock ≈ 5.05h (3 × ~1.7h). Within 5.5h budget.
set -euo pipefail

cd "$(dirname "$0")"

export WANDB_PROJECT="modded-nanogpt-senpai"
export WANDB_ENTITY="wandb-applied-ai-team"
export STUDENT_NAME="g1r3-frieren"

GROUP="g1r3-frieren-h202-schedule-free-aux"
COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape linear
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
)

run_arm() {
  local name="$1"
  shift
  local log="logs_h202/${name}_$(date +%Y%m%d_%H%M%S).log"
  echo "=== H202 ${name} START $(date -Iseconds) ==="
  echo "LOG: $log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" \
    "$@" \
    --wandb_group "$GROUP" \
    2>&1 | tee "$log"
  echo "=== H202 ${name} END $(date -Iseconds) ==="
}

mkdir -p logs_h202

# arm_a CTRL: standard AdamW + cooldown 0.4
run_arm "arm_a-ctrl" \
  --aux_cooldown_frac 0.4 \
  --wandb_name "g1r3-frieren/h202-arm_a-ctrl"

# arm_b SF_NO_COOLDOWN: Schedule-Free + no cooldown
run_arm "arm_b-sf-nocool" \
  --aux_schedule_free \
  --aux_cooldown_frac 0.0 \
  --wandb_name "g1r3-frieren/h202-arm_b-sf-nocool"

# arm_c SF_KEEP_COOLDOWN: Schedule-Free + cooldown 0.4
run_arm "arm_c-sf-keepcool" \
  --aux_schedule_free \
  --aux_cooldown_frac 0.4 \
  --wandb_name "g1r3-frieren/h202-arm_c-sf-keepcool"

echo "=== H202 ALL ARMS COMPLETE $(date -Iseconds) ==="
