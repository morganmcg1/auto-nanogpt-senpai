#!/bin/bash
# H382 outer_velocity reset at cooldown entry — 3-arm sequential chain.
# Single H100, Pattern A drift-FREE on the H266 baseline stack.
#
# Hypothesis: zero MuLoCo outer_velocity buffer once at cooldown entry
# (resolved train_step = train_steps - int(0.2*train_steps) = 2660 for
# train_steps=3325; PR cites "~2663"). Mechanism-distinct from prior closures:
# this is a BUFFER STATE intervention (not form, magnitude, schedule, or
# per-group allocation). Direct analog to H170 AUX v_t reset at cooldown entry.
#
# arm_a CTRL --outer_reset_at_cooldown 0:  H266 bit-id (safe-default replicate).
# arm_b OUTER_RESET --outer_reset_at_cooldown 1:  reset ALL outer_velocity.
# arm_c OUTER_RESET_BODY --outer_reset_at_cooldown 2:  reset only BODY
#                                       (block ndim>=2) outer_velocity.
set -u
unset WANDB_API_KEY  # pod feedback: env key invalid; use /root/.netrc
cd "$(dirname "$0")"

ARM="${1:-all}"  # all | a | b | c

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
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
  --wandb_group H382_outer_velocity_reset_at_cooldown
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] CHAIN ARM ${name} START ====="
  printf '   ARG: %q\n' "$@"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-thorfinn/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] CHAIN ARM ${name} rc=${rc} ====="
  return $rc
}

# arm_a CTRL: outer_reset_at_cooldown=0 (H266 bit-id replicate).
# Pattern A expectation: step-0=10.82583 EXACT, FFS=3000 or +25 envelope.
if [[ "$ARM" == "all" || "$ARM" == "a" ]]; then
  run_arm "H382_arm_a_CTRL" \
    --outer_reset_at_cooldown 0
fi

# arm_b OUTER_RESET: reset all outer_velocity at cooldown entry (train_step=2660).
if [[ "$ARM" == "all" || "$ARM" == "b" ]]; then
  run_arm "H382_arm_b_OUTER_RESET" \
    --outer_reset_at_cooldown 1
fi

# arm_c OUTER_RESET_BODY: reset only block-body outer_velocity, preserve aux velocity.
if [[ "$ARM" == "all" || "$ARM" == "c" ]]; then
  run_arm "H382_arm_c_OUTER_RESET_BODY" \
    --outer_reset_at_cooldown 2
fi

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H382 CHAIN COMPLETE ====="
