#!/bin/bash
# H385 pre-launch smoke gate — 3-arm 125-step Pattern A bit-id check
# arm_a CTRL (off) must be bit-id with baseline at step 0 and close at step 125
# arm_b DIRECT and arm_c INVERSE must run cleanly with non-trivial coupling_s_t
set -euo pipefail
cd /workspace/senpai/target

mkdir -p logs_h385_smoke

SHARED_FLAGS="--num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --aux_v_inject_anchor_step 50 --aux_v_inject_clamp 2.0 \
  --wandb_project modded-nanogpt-senpai --wandb_group H385_smoke"

echo "=== SMOKE arm_a CTRL (aux_v_inject_mode=off) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $SHARED_FLAGS --aux_v_inject_mode off \
  --wandb_name g1r3-frieren/H385_smoke_arm_a_CTRL 2>&1 | tee logs_h385_smoke/arm_a.log

echo "=== SMOKE arm_b DIRECT (aux_v_inject_mode=direct) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $SHARED_FLAGS --aux_v_inject_mode direct \
  --wandb_name g1r3-frieren/H385_smoke_arm_b_DIRECT 2>&1 | tee logs_h385_smoke/arm_b.log

echo "=== SMOKE arm_c INVERSE (aux_v_inject_mode=inverse) ==="
torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
  $SHARED_FLAGS --aux_v_inject_mode inverse \
  --wandb_name g1r3-frieren/H385_smoke_arm_c_INVERSE 2>&1 | tee logs_h385_smoke/arm_c.log

echo "=== SMOKE COMPLETE ==="
