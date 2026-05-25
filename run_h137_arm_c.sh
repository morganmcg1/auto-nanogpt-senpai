#!/bin/bash
# H137 arm_c FP16: internal NS5 iterations in fp16 (bf16 input/output).
# Tests whether bf16 is the binding precision threshold downward. fp16
# has the same throughput as bf16 but a much smaller dynamic range, so
# this probes whether NS5 needs bf16's range or fp16's mantissa is enough.
set -e
cd "$(dirname "$0")"
mkdir -p training_logs
LOG=training_logs/h137_arm_c_fp16_$(date +%Y%m%d_%H%M%S).log
echo "arm_c log: $LOG"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --muonh_ns5_iterations 12 \
  --muonh_ns5_dtype fp16 \
  --wandb_name "g1r3-nezuko/h137-arm_c-fp16" \
  --wandb_group g1r3-nezuko-h137-ns5-precision-sweep \
  --wandb_tags "h137,arm_c,fp16" 2>&1 | tee "$LOG"
echo "arm_c complete: $LOG"
