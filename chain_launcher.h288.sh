#!/bin/bash
# H288 thorfinn — Cooldown-localized Polyak-Ruppert EMA activation (76th class).
# Pattern A drift-FREE: argparse VALUE-only on new --polyak_ema_activation_step flag.
#
# Hypothesis: the H266 WIN signal (decay=0.05 EMA on full training) may be a
# COOLDOWN-PHASE phenomenon. EMA half-life is ~13.5 steps at decay=0.05; the
# buffer converges within 50-100 steps. If we activate EMA only during the last
# 25% of training (cooldown), 825 cooldown steps = 60x half-life, so the
# eval-time params are asymptotically identical to baseline H266. Testing
# whether pre-cooldown EMA updates contribute structurally or are wasted.
#
#   arm_a CTRL                activation_step=0     (H266 replicate, full-training EMA)
#   arm_b COOLDOWN_RAMP       activation_step=2500  (75% through, 825 cooldown steps)
#   arm_c COOLDOWN_AGGRESSIVE activation_step=2900  (87% through, 425 cooldown steps)
#
# Sequential on 1xGPU, ~110min per arm, ~5h30m total. WIN criterion (post-H266):
# arm_b OR arm_c FFS<3000 strict (val<3.276). TIE result FFS=3000 EXACT confirms
# cooldown-localized hypothesis. NEG FFS=3025+ suggests pre-cooldown EMA matters.
#
# Drift verification: arm_a CTRL with activation_step=0 must reproduce step-0
# val=10.82583 EXACT (bit-id with H266 init path; eval gate `step > 0` skips
# the substitute branch but EMA buffer == live params at init so val_loss is
# identical to H266 substitution behavior). arm_b/arm_c step-0 val also 10.82583
# (live params used since gate filters EMA out before activation_step).
set -u

# WANDB env key on this pod is stale/invalid; force netrc fallback.
unset WANDB_API_KEY

cd "$(dirname "$0")"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H288_cooldown_localized_ema
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} ====="
  echo "----- CLI invocation (verbatim) -----"
  printf 'torchrun --standalone --nproc_per_node=1 \\\n  records/track_3_optimization/train_gpt_simple.py'
  for a in "${COMMON_ARGS[@]}" "$@" --wandb_name "g1r3-thorfinn/${name}"; do
    printf ' \\\n    %q' "$a"
  done
  echo
  echo "-------------------------------------"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-thorfinn/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} ====="
  return $rc
}

# arm_a CTRL — activation_step=0; H266 replicate, EMA active from step 0.
# Pattern A drift check: step-0 val MUST be 10.82583 EXACT; terminal val/FFS
# should match the H266 baseline (val~3.26818, FFS=3000).
run_arm "H288_arm_a_CTRL_step0" \
  --polyak_ema_activation_step 0

sleep 30

# arm_b COOLDOWN_RAMP — activation_step=2500; EMA gated until 75% through
# training. Buffer reinitialized from live params at step 2500, then 825
# cooldown steps of EMA updates (~60x decay half-life => asymptotic convergence).
# If H266 WIN is purely cooldown-driven, expect arm_b ~ H266 baseline.
run_arm "H288_arm_b_COOLDOWN_step2500" \
  --polyak_ema_activation_step 2500

sleep 30

# arm_c COOLDOWN_AGGRESSIVE — activation_step=2900; EMA gated until 87% through.
# Only 425 cooldown steps of EMA updates (~31x half-life), still converged but
# shorter exposure. Tests dose-response of cooldown-only EMA duration.
run_arm "H288_arm_c_AGGRESSIVE_step2900" \
  --polyak_ema_activation_step 2900

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H288 CHAIN COMPLETE ====="
