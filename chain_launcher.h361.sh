#!/bin/bash
# H361 MuonH AGC clip ratio axis sweep at H266 stack (BODY-side mirror of H353).
# Sequential single-GPU 3-arm Pattern A drift-FREE.
#
# Hypothesis: BODY-side MuonH AGC clip_ratio (Adaptive Gradient Clipping fraction
# of per-parameter weight norm applied to the inner MuonH gradient prior to
# Newton-Schulz orthogonalization) has never been screened at H266 stack as a
# value bracket. H361 probes 2× tighter (0.025, arm_b) and 2× looser (0.10,
# arm_c) clip ratios while holding aux_agc_clip_ratio fixed at 0.05, isolating
# the BODY gradient-magnitude gate.
#
# arm_a CTRL --muonh_agc_clip_ratio 0.05:  H266 bit-id replicate
# arm_b TIGHT --muonh_agc_clip_ratio 0.025: 2× tighter; more aggressive clipping
# arm_c LOOSE --muonh_agc_clip_ratio 0.10:  2× looser; less aggressive clipping
#
# Mechanism-distinct from H353 (AUX-side AGC) by axis (BODY vs AUX). Tests
# whether ADAMW-SECOND-MOMENT-NORMALIZATION-CANALIZATION-GATE generalizes to
# MuonH Newton-Schulz orthogonalization or is AdamW-specific. Zero code change
# required — flag --muonh_agc_clip_ratio already exists and is already in the
# wandb.init config dict (line 849 of train_gpt_simple.py).
set -u
unset WANDB_API_KEY  # pod feedback: env key invalid; use /root/.netrc
cd "$(dirname "$0")"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --body_init orthogonal_fnorm_matched
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group H361_muonh_agc_clip_ratio
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

# arm_a CTRL --muonh_agc_clip_ratio 0.05 (H266 anchor bit-id replicate).
run_arm "H361_arm_a_CTRL_0p05" \
  --muonh_agc_clip_ratio 0.05

# arm_b TIGHT --muonh_agc_clip_ratio 0.025 (2× tighter).
run_arm "H361_arm_b_TIGHT_0p025" \
  --muonh_agc_clip_ratio 0.025

# arm_c LOOSE --muonh_agc_clip_ratio 0.10 (2× looser).
run_arm "H361_arm_c_LOOSE_0p10" \
  --muonh_agc_clip_ratio 0.10

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H361 CHAIN COMPLETE ====="
