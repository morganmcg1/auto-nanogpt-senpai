#!/bin/bash
# H382 outer_velocity reset at cooldown entry smoke gate.
# 125-step smokes verify:
#   - step-0 val=10.82583 EXACT on arm_a CTRL (Pattern A bit-id preserved).
#   - W&B config shows outer_reset_at_cooldown distinct per arm (0 / 1).
#   - Startup banner "H382 outer_reset_at_cooldown mode=1 ..." prints on arm_b.
#   - With train_steps=125 the resolved reset step is 100 (last 20% of training),
#     so arm_b will ALSO emit "Outer velocity RESET fired at train_step=100"
#     — confirms the dispatch + one-shot guard work end-to-end.
set -u
unset WANDB_API_KEY  # pod feedback: env key invalid; use /root/.netrc
cd "$(dirname "$0")"

ARM="${1:-all}"   # all | a | b

COMMON_ARGS=(
  --num_trials 1 --train_steps 125
  --muonh_mode scale_invariant
  --body_init orthogonal_fnorm_matched
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H382_outer_velocity_reset_smoke
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] SMOKE ARM ${name} START ====="
  printf '   ARG: %q\n' "$@"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-thorfinn/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] SMOKE ARM ${name} rc=${rc} ====="
  return $rc
}

# arm_a CTRL: outer_reset_at_cooldown=0 (H266 bit-id replicate, no reset).
if [[ "$ARM" == "all" || "$ARM" == "a" ]]; then
  run_arm "H382_smoke_arm_a_CTRL" \
    --outer_reset_at_cooldown 0
fi

# arm_b OUTER_RESET: outer_reset_at_cooldown=1 (reset ALL outer_velocity at cooldown entry).
if [[ "$ARM" == "all" || "$ARM" == "b" ]]; then
  run_arm "H382_smoke_arm_b_OUTER_RESET" \
    --outer_reset_at_cooldown 1
fi

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H382 SMOKE COMPLETE ====="
