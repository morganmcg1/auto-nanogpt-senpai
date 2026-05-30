#!/bin/bash
# H298 thorfinn — DEMON-style monotone µ→0 decay sweep (Pattern A VALUE-only).
#
# Tests DEMON hypothesis (Chen et al. 2019, arXiv:1910.04952): inner momentum
# decays linearly to ~0 by end of training, so terminal updates approach pure
# gradient descent and "track" the cooldown sharpening signal directly. This
# mirrors the H266 EMA "track-not-average" mechanism but at the gradient level
# rather than the parameter level.
#
#   arm_a CTRL         --muonh_mu_end 0.90  (H266 baseline replicate, bit-id)
#   arm_b DEMON_HALF   --muonh_mu_end 0.45  (intermediate regime)
#   arm_c DEMON_FULL   --muonh_mu_end 0.00  (literal DEMON formulation)
#
# Pattern A pure VALUE-only: --muonh_mu_start / --muonh_mu_end already CLI flags,
# no code change. arm_a CTRL must reproduce H266 step-0 val=10.82583 EXACT and
# terminal val~3.26818 FFS=3000 (single-axis VALUE change cannot perturb model
# init or the seed-0 forward pass). arm_b/c will diverge from arm_a after step 1
# because mu_t differs at every training step under the linear schedule.
#
# Sequential on 1xGPU, ~110min per arm, ~5h30m total.
set -u

# WANDB env key on this pod is stale/invalid; force netrc fallback.
unset WANDB_API_KEY

cd "$(dirname "$0")"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --body_init orthogonal_fnorm_matched
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine
  --muonh_mu_schedule linear --muonh_mu_start 0.95
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --aux_adamw_eps 1e-6
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05
  --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H298_demon_mu_decay
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

# arm_a CTRL — H266 baseline replicate, mu_end=0.90. Required drift-FREE check:
# step-0 val=10.82583 EXACT and terminal val~3.26818 FFS=3000.
run_arm "H298_arm_a_CTRL_mu90" \
  --muonh_mu_end 0.90

sleep 30

# arm_b DEMON_HALF — mu_end=0.45. Intermediate regime; mu trajectory crosses
# 0.7 at the mid-training point (~step 1662), so the second half of training
# operates with materially less momentum than the H266 baseline while early
# training still has full smoothing.
run_arm "H298_arm_b_DEMON_HALF_mu45" \
  --muonh_mu_end 0.45

sleep 30

# arm_c DEMON_FULL — mu_end=0.00, the literal DEMON formulation. mu trajectory:
# 0.95→0.0 linear; by cooldown entry (~step 3000) mu≈0.093, so the cooldown
# sharpening window is near-pure gradient descent inside the body. If the H266
# "track during cooldown" mechanism generalizes from EMA-on-params to mu-on-grads,
# this should WIN. Risk: NS5 polar projection wants monotone σ_max≤1 from below;
# zero-momentum updates could destabilize that approach.
run_arm "H298_arm_c_DEMON_FULL_mu0" \
  --muonh_mu_end 0.0

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H298 CHAIN COMPLETE ====="
