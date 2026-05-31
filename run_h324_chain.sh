#!/usr/bin/env bash
# H324 — 3-arm sequential chain at 3325 steps each.
# arm_a CTRL          : outer_lr_schedule=constant (bit-id with H266 baseline)
# arm_b WARMUP_SHORT  : outer_lr_schedule=warmup_linear, N=10 outer steps (~9% of training)
# arm_c WARMUP_LONG   : outer_lr_schedule=warmup_linear, N=30 outer steps (~27% of training)
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p logs_h324

BASE_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
)

run_arm() {
  local arm_name="$1"; shift
  local wandb_label="$1"; shift
  local logfile="logs_h324/${arm_name}.out"
  echo "=== launching ${arm_name} -> ${logfile} ==="
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${BASE_ARGS[@]}" "$@" \
    --wandb_project modded-nanogpt-senpai \
    --wandb_group H324_outer_lr_warmup \
    --wandb_name "g1r3-tanjiro/${wandb_label}" \
    2>&1 | tee "${logfile}"
}

run_arm arm_a H324_arm_a_CTRL          --outer_lr_schedule constant      --outer_lr_warmup_outer_steps 0
run_arm arm_b H324_arm_b_WARMUP_SHORT  --outer_lr_schedule warmup_linear --outer_lr_warmup_outer_steps 10
run_arm arm_c H324_arm_c_WARMUP_LONG   --outer_lr_schedule warmup_linear --outer_lr_warmup_outer_steps 30

echo "=== chain complete ==="
