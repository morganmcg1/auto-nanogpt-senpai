#!/usr/bin/env bash
set -euo pipefail
# H368 3-arm chain (train_steps=3325 each, ~1h 50min/arm).
# Vary --aux_optimizer + --ademamix_alpha across arms. All other H266 stack flags unchanged.
ARM="${1:?arm a|b|c required}"
case "$ARM" in
  a) OPT="adamw";    BETA3="0.9999"; ALPHA="8.0"; SUFFIX="arm_a_CTRL";;
  b) OPT="ademamix"; BETA3="0.9999"; ALPHA="8.0"; SUFFIX="arm_b_ADEMAMIX";;
  c) OPT="ademamix"; BETA3="0.9999"; ALPHA="4.0"; SUFFIX="arm_c_ADEMAMIX_MILD";;
  *) echo "usage: $0 {a|b|c}" >&2; exit 2;;
esac
NAME="g1r3-edward/H368_${SUFFIX}"
LOG="runlogs/h368/${SUFFIX}.log"
cd /workspace/senpai/target
mkdir -p runlogs/h368

EXTRA_ARGS=()
if [ "$OPT" = "ademamix" ]; then
  EXTRA_ARGS+=(--ademamix_beta3 "$BETA3" --ademamix_alpha "$ALPHA")
fi

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_optimizer "$OPT" "${EXTRA_ARGS[@]}" \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H368_ademamix_aux_optimizer" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
