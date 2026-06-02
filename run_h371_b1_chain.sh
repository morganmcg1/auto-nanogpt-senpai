#!/bin/bash
# H371 β₁-axis chain: 3-arm sequential at LaProp eps=1e-8 anchor.
# arm_a CTRL          adamw   eps=1e-6 β₁=0.8  (Pattern A bit-id sentinel)
# arm_b LAPROP_B1_MID laprop  eps=1e-8 β₁=0.85 (mid-step toward LaProp paper β₁)
# arm_c LAPROP_B1_PAPER laprop eps=1e-8 β₁=0.9  (LaProp paper-recommended β₁)
set -euo pipefail
cd /workspace/senpai/target

mkdir -p logs_h371_b1

run_arm() {
  local arm_name="$1"
  local aux_optimizer="$2"
  local aux_adamw_eps="$3"
  local aux_beta1="$4"
  local wandb_name="$5"
  echo "=== ARM ${arm_name} (--aux_optimizer ${aux_optimizer} --aux_adamw_eps ${aux_adamw_eps} --aux_beta1 ${aux_beta1}) ==="
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 --train_steps 3325 \
    --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
    --aux_optimizer "${aux_optimizer}" \
    --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
    --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps "${aux_adamw_eps}" \
    --aux_beta1 "${aux_beta1}" \
    --aux_beta2_schedule constant --aux_beta2_start 0.99 \
    --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
    --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
    --wandb_project modded-nanogpt-senpai \
    --wandb_group H371_laprop_beta1_axis \
    --wandb_name "${wandb_name}" 2>&1 | tee "logs_h371_b1/${arm_name}.log"
}

run_arm "arm_a_CTRL"             "adamw"  "1e-6" "0.8"  "g1r3-frieren/H371_b1_arm_a_CTRL"
run_arm "arm_b_LAPROP_B1_MID"    "laprop" "1e-8" "0.85" "g1r3-frieren/H371_b1_arm_b_LAPROP_B1_MID"
run_arm "arm_c_LAPROP_B1_PAPER"  "laprop" "1e-8" "0.9"  "g1r3-frieren/H371_b1_arm_c_LAPROP_B1_PAPER"

echo "=== CHAIN COMPLETE ==="
