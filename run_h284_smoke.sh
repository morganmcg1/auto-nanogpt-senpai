#!/usr/bin/env bash
# H284 smoke test — verifies drift-FREE Pattern A for both flags.
# arm_a CTRL (z=0, ns5=12) MUST produce step-0 val = 10.82583 EXACT.
# arm_b/arm_c also should produce 10.82583 EXACT because:
#   - z_loss is added to training loss only (forward defaults z_loss_weight=0 in eval path)
#   - ns5_num_iterations affects MuonH update, not the step-0 val measurement
# Step-0 val is computed BEFORE any optimizer step, so model weights are at init.
set -euo pipefail

cd /workspace/senpai/target

mkdir -p logs_h284

COMMON_FLAGS=(
  --num_trials 1
  --train_steps 10
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7
  --outer_momentum 0.5
  --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant
  --aux_beta2_start 0.99
  --muonh_mu_schedule linear
  --muonh_mu_start 0.95
  --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_mode disabled
)

echo "=== H284 smoke: arm_a CTRL (z=0, ns5=12) — step-0 val MUST be 10.82583 EXACT ==="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --z_loss_weight 0.0 \
  --ns5_num_iterations 12 \
  --wandb_name "g1r3-frieren/H284_arm_a_smoke" \
  --wandb_group "H284_smoke" 2>&1 | tee logs_h284/smoke_arm_a.log

echo "=== H284 smoke: arm_b 2-STACK (z=1e-5, ns5=16) — step-0 val should be 10.82583 EXACT ==="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --z_loss_weight 1e-5 \
  --ns5_num_iterations 16 \
  --wandb_name "g1r3-frieren/H284_arm_b_smoke" \
  --wandb_group "H284_smoke" 2>&1 | tee logs_h284/smoke_arm_b.log

echo "=== H284 smoke: arm_c 2-STACK-HIGHER-Z (z=3e-5, ns5=16) — step-0 val should be 10.82583 EXACT ==="
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON_FLAGS[@]}" \
  --z_loss_weight 3e-5 \
  --ns5_num_iterations 16 \
  --wandb_name "g1r3-frieren/H284_arm_c_smoke" \
  --wandb_group "H284_smoke" 2>&1 | tee logs_h284/smoke_arm_c.log

echo "=== H284 smoke complete. Step-0 val check (must all be 10.82583): ==="
grep -h "step:0/10 val_loss" logs_h284/smoke_arm_*.log
