#!/bin/bash
# H283 fern — Label smoothing on CE training loss (67th mechanism class):
#   arm_a CTRL                  (--label_smoothing 0.0;  drift-FREE Pattern A bit-id to post-H266 baseline)
#   arm_b TREATMENT LOW         (--label_smoothing 0.05; mild smoothing)
#   arm_c TREATMENT MID         (--label_smoothing 0.1;  Szegedy 2016 canonical value)
# H283 swaps F.cross_entropy(...) for F.cross_entropy(..., label_smoothing=alpha) for the
# training loss only. With alpha=0.0 the kwarg is documented-identical to omitting it
# (drift-FREE CTRL). Sequential on 1xGPU, ~110min per arm, ~5h30m total.
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
  --wandb_group H283_label_smoothing
)

run_arm () {
  local name="$1"; shift
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] STARTING ${name} ====="
  echo "----- CLI invocation (verbatim) -----"
  printf 'torchrun --standalone --nproc_per_node=1 \\\n  records/track_3_optimization/train_gpt_simple.py'
  for a in "${COMMON_ARGS[@]}" "$@" --wandb_name "g1r3-fern/${name}"; do
    printf ' \\\n    %q' "$a"
  done
  echo
  echo "-------------------------------------"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    --wandb_name "g1r3-fern/${name}"
  local rc=$?
  echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FINISHED ${name} rc=${rc} ====="
  return $rc
}

# arm_a CTRL — label_smoothing=0.0; F.cross_entropy with label_smoothing=0.0 is
# documented-identical to omitting the kwarg. step-0 val_loss MUST equal 10.82583
# (validates the Pattern A bit-id gate) and FFS MUST match the post-H266 baseline
# 3000 ± 25 by drift class.
run_arm "H283_arm_a_CTRL_ls_0p0" \
  --label_smoothing 0.0

sleep 30

# arm_b TREATMENT LOW — label_smoothing=0.05; mild smoothing. The (1-alpha) cap on
# correct-class probability is 0.95. Option B chosen for implementation (forward()
# kwarg default 0.0), so val/loss is computed with the standard CE (no smoothing)
# to preserve benchmark semantics (target val/loss<=3.28 is defined under std CE).
# Smoke confirmed step-0 val=10.82583 EXACT for arm_b too (val path bypasses
# smoothing); step-10 val=9.34825 vs CTRL 9.28991 confirms smoothing IS active
# during training (the training-path divergence — exactly what we want).
run_arm "H283_arm_b_LOW_ls_0p05" \
  --label_smoothing 0.05

sleep 30

# arm_c TREATMENT MID — label_smoothing=0.1; Szegedy 2016 canonical value. The
# (1-alpha) cap on correct-class probability is 0.9. More aggressive smoothing
# than arm_b; if WIN curve is U-shaped we expect arm_c's worst-case to be a
# slight regression vs arm_b but still informative on the smoothing axis.
# val/loss path uses std CE (Option B, see arm_b comment) so step-0 val MUST be
# 10.82583 EXACT (bit-id gate for the val path) and val/loss<3.276 is the WIN
# criterion vs the std CE benchmark target.
run_arm "H283_arm_c_MID_ls_0p1" \
  --label_smoothing 0.1

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H283 CHAIN COMPLETE ====="
