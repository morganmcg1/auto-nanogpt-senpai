#!/bin/bash
# H385 chain: arm_a CTRL (off, sentinel bit-id) → arm_b DIRECT (s_t/s_anchor) → arm_c INVERSE (s_anchor/s_t).
# Cross-axis AUX→BODY coupling via AUX AdamW v_t (exp_avg_sq) modulating BODY MuonH effective lr each step.
# 1 GPU sequential. H266 stack (polyak_ema_decay=0.05).
set -euo pipefail
cd /workspace/senpai/target

LOGDIR=logs_h385
mkdir -p "$LOGDIR"

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --aux_v_inject_anchor_step 50
  --aux_v_inject_clamp 2.0
  --wandb_project modded-nanogpt-senpai
  --wandb_group H385_aux_v_inject_body_coupling
)

echo "=== arm_a CTRL aux_v_inject_mode=off starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --aux_v_inject_mode off \
  --wandb_name g1r3-frieren/H385_arm_a_CTRL \
  2>&1 | tee "$LOGDIR/arm_a.log"

echo "=== arm_b DIRECT aux_v_inject_mode=direct starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --aux_v_inject_mode direct \
  --wandb_name g1r3-frieren/H385_arm_b_DIRECT \
  2>&1 | tee "$LOGDIR/arm_b.log"

echo "=== arm_c INVERSE aux_v_inject_mode=inverse starting $(date -u) ===" | tee -a "$LOGDIR/chain.log"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  "${COMMON[@]}" \
  --aux_v_inject_mode inverse \
  --wandb_name g1r3-frieren/H385_arm_c_INVERSE \
  2>&1 | tee "$LOGDIR/arm_c.log"

echo "=== CHAIN COMPLETE $(date -u) ===" | tee -a "$LOGDIR/chain.log"
