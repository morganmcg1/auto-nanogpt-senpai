#!/bin/bash
set -euo pipefail
cd /workspace/senpai/target
LOGDIR=research/adabelief_aux_run_logs
BASE="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="--wandb_group g1r5-alphonse/adabelief-aux-confirm-n4"

for SEED in 1 2 3; do
  echo "=== Seed $SEED started $(date -u +%FT%TZ) ===" >> "$LOGDIR/n4_orchestrator.log"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
    --use_adabelief --adam_eps 1e-16 --torch_manual_seed $SEED \
    --wandb_name "g1r5-alphonse/adabelief-C-confirm-n4-seed${SEED}" \
    > "$LOGDIR/n4_seed${SEED}.log" 2>&1
  echo "=== Seed $SEED finished $(date -u +%FT%TZ) (rc=$?) ===" >> "$LOGDIR/n4_orchestrator.log"
done
echo "=== ALL DONE $(date -u +%FT%TZ) ===" >> "$LOGDIR/n4_orchestrator.log"
