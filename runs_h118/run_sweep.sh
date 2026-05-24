#!/bin/bash
set -u
cd /workspace/senpai/target

LOGDIR=runs_h118
mkdir -p "$LOGDIR"

BASE_CMD="torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99"

echo "=== arm_a CTRL (use_outer=1, muonh_lr=default) ===" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"
$BASE_CMD \
  --use_outer_optimizer 1 \
  --wandb_group g1r3-frieren-h118-no-outer-ablation \
  --wandb_name g1r3-frieren/H118_arm_a_ctrl 2>&1 | tee "$LOGDIR/arm_a.log"
echo "arm_a exit: ${PIPESTATUS[0]}" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"

echo "=== arm_b NO_OUTER (use_outer=0, muonh_lr=default) ===" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"
$BASE_CMD \
  --use_outer_optimizer 0 \
  --wandb_group g1r3-frieren-h118-no-outer-ablation \
  --wandb_name g1r3-frieren/H118_arm_b_no_outer 2>&1 | tee "$LOGDIR/arm_b.log"
echo "arm_b exit: ${PIPESTATUS[0]}" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"

echo "=== arm_c NO_OUTER_LR_BOOSTED (use_outer=0, muonh_lr=0.025) ===" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"
$BASE_CMD \
  --use_outer_optimizer 0 \
  --muonh_lr 0.025 \
  --wandb_group g1r3-frieren-h118-no-outer-ablation \
  --wandb_name g1r3-frieren/H118_arm_c_no_outer_lr_boost 2>&1 | tee "$LOGDIR/arm_c.log"
echo "arm_c exit: ${PIPESTATUS[0]}" | tee -a "$LOGDIR/sweep.log"
date | tee -a "$LOGDIR/sweep.log"

echo "ALL DONE" | tee -a "$LOGDIR/sweep.log"
