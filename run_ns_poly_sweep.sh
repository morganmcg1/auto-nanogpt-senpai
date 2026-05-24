#!/usr/bin/env bash
# Run all 5 cells of the NS polynomial coefficient sweep sequentially.
# Each cell logs to logs/ns_poly_<cell>.log and shares the same wandb group.

set -e
cd "$(dirname "$0")"

BASE="--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="--wandb_group g1r5-frieren/ns-poly-coefficient-sweep"

mkdir -p logs

# Cell A (ctrl): a=2.0, b=-1.5, c=0.5
echo "=== Starting Cell A (ctrl) at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
  --wandb_name ns_poly_ctrl \
  --ns_poly_a 2.0 --ns_poly_b -1.5 --ns_poly_c 0.5 \
  2>&1 | tee logs/ns_poly_ctrl.log

# Cell B (cubic-conv): a=1.875, b=-1.25, c=0.375
echo "=== Starting Cell B (cubic-conv) at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
  --wandb_name ns_poly_cubic_conv \
  --ns_poly_a 1.875 --ns_poly_b -1.25 --ns_poly_c 0.375 \
  2>&1 | tee logs/ns_poly_cubic_conv.log

# Cell C (Muon-paper): a=3.4445, b=-4.7750, c=2.0315
echo "=== Starting Cell C (Muon-paper) at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
  --wandb_name ns_poly_muon_paper \
  --ns_poly_a 3.4445 --ns_poly_b -4.7750 --ns_poly_c 2.0315 \
  2>&1 | tee logs/ns_poly_muon_paper.log

# Cell D (cubic-only): a=1.5, b=-0.5, c=0.0
echo "=== Starting Cell D (cubic-only) at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
  --wandb_name ns_poly_cubic_only \
  --ns_poly_a 1.5 --ns_poly_b -0.5 --ns_poly_c 0.0 \
  2>&1 | tee logs/ns_poly_cubic_only.log

# Cell E (high-amp): a=2.5, b=-2.0, c=0.5
echo "=== Starting Cell E (high-amp) at $(date -u +%FT%TZ) ==="
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
  --wandb_name ns_poly_high_amp \
  --ns_poly_a 2.5 --ns_poly_b -2.0 --ns_poly_c 0.5 \
  2>&1 | tee logs/ns_poly_high_amp.log

echo "=== All 5 cells finished at $(date -u +%FT%TZ) ==="
