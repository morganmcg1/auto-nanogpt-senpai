#!/bin/bash
# H286 smoke test — 50 steps for both arms. Confirms step-0 val = 10.82583
# (Pattern A drift-FREE on arm_a) and that nesterov=False code path doesn't
# crash (arm_b). Both arms must show step-0 val = 10.82583 EXACT since
# Nesterov-vs-classical only affects update direction starting from step 1.
set -u

unset WANDB_API_KEY
cd "$(dirname "$0")"

COMMON_ARGS=(
  --num_trials 1 --train_steps 50
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H286_muonh_nesterov_smoke
  --wandb_mode offline
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} ====="
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-edward/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} ====="
  return $rc
}

run_arm "H286_smoke_arm_a_CTRL_NESTEROV_ON" \
  --muonh_nesterov 1

sleep 10

run_arm "H286_smoke_arm_b_NESTEROV_OFF" \
  --muonh_nesterov 0

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H286 SMOKE COMPLETE ====="
