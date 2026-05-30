#!/bin/bash
# H287 alphonse — NS5 polynomial coefficient FORM variants (75th mechanism class):
#   arm_a CTRL                  (--ns5_polynomial default;            (2,-1.5,0.5)   drift-FREE bit-id to H266 baseline)
#   arm_b TREATMENT BERNSTEIN   (--ns5_polynomial bernstein_newhouse; (3.4445,-4.7750,2.0315) Muon-paper tuned)
#   arm_c TREATMENT HALLEY      (--ns5_polynomial halley;             (3,-3,1)       classical Halley iteration)
# H287 tests whether alternative Newton-Schulz quintic polynomial coefficients
# improve FFS/val on the post-H266 EMA baseline. Sequential on 1xGPU, ~110min per
# arm, ~5h30m total. Outside PF#61 closed axes and PF#62 (this is a FORM choice,
# not a phase-gated/decoupling mechanism). H267 closed NS5 iter count; this closes
# the orthogonal NS5 polynomial coefficient FORM axis.
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
  --wandb_group H287_ns5_polynomial
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} ====="
  echo "----- CLI invocation (verbatim) -----"
  printf 'torchrun --standalone --nproc_per_node=1 \\\n  records/track_3_optimization/train_gpt_simple.py'
  for a in "${COMMON_ARGS[@]}" "$@" --wandb_name "g1r3-alphonse/${name}"; do
    printf ' \\\n    %q' "$a"
  done
  echo
  echo "-------------------------------------"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-alphonse/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} ====="
  return $rc
}

# arm_a CTRL — ns5_polynomial=default; (2.0,-1.5,0.5). Bit-identical (verified)
# to the original hardcoded (2,-1.5,0.5) baseline. step-0 val MUST equal 10.82583
# and FFS MUST match the post-H266 baseline (3000 EXACT or Pattern A ±25).
run_arm "H287_arm_a_CTRL_default" \
  --ns5_polynomial default

sleep 30

# arm_b TREATMENT BERNSTEIN_NEWHOUSE — (3.4445,-4.7750,2.0315). Published Muon-paper
# tuning for faster SV convergence; expected to overshoot SV=1 in bfloat16 regime.
run_arm "H287_arm_b_BERNSTEIN" \
  --ns5_polynomial bernstein_newhouse

sleep 30

# arm_c TREATMENT HALLEY — (3,-3,1). Classical Halley iteration. Sharper SV
# convergence near 1 (cubic order), more aggressive amplification at y=0 than default.
run_arm "H287_arm_c_HALLEY" \
  --ns5_polynomial halley

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H287 CHAIN COMPLETE ====="
