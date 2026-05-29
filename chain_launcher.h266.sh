#!/bin/bash
# H266 thorfinn — Polyak-Ruppert EMA for eval-only weight averaging (62nd mechanism class):
#   arm_a CTRL                  (--polyak_ema_decay 0.0;   drift-FREE Pattern A bit-id to H203)
#   arm_b TREATMENT EMA_FAST    (--polyak_ema_decay 0.05;  ~20-step half-life)
#   arm_c TREATMENT EMA_SLOW    (--polyak_ema_decay 0.005; ~200-step half-life)
# H266 adds a per-step EMA of model parameters and swaps it into the model only for
# val/loss measurement. Training proceeds with the live weights. Sequential on 1xGPU,
# ~110min per arm, ~5h30m total.
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
  --wandb_project modded-nanogpt-senpai
  --wandb_group h266_polyak_ruppert_ema
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

# arm_a CTRL — polyak_ema_decay=0.0; drift-FREE Pattern A, polyak_ema_state stays
# None and every H266 code path short-circuits. step-0 val_loss MUST equal 10.82583
# and FFS MUST match the H203 baseline (3025 ± 25 by drift class).
run_arm "H266_arm_a_CTRL_ema_0p0" \
  --polyak_ema_decay 0.0

sleep 30

# arm_b TREATMENT EMA_FAST — polyak_ema_decay=0.05; ~20-step half-life. At cooldown
# end has accumulated ~100 steps of weighted history. Hypothesis: variance reduction
# at eval gives earlier reliable threshold crossing (lower FFS).
run_arm "H266_arm_b_EMA_FAST_0p05" \
  --polyak_ema_decay 0.05

sleep 30

# arm_c TREATMENT EMA_SLOW — polyak_ema_decay=0.005; ~200-step half-life. At
# cooldown end has accumulated over 600+ steps so averages substantial
# pre-cooldown trajectory too. Hypothesis: long average reduces noise harder
# at the cost of lagging behind live during cooldown LR decay.
run_arm "H266_arm_c_EMA_SLOW_0p005" \
  --polyak_ema_decay 0.005

echo "===== [$(date -u +'%Y-%m-%dT%H:%M:%SZ')] H266 CHAIN COMPLETE ====="
