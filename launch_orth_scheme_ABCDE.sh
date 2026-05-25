#!/bin/bash
set -uo pipefail

cd /workspace/senpai/target

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

COMMON="--num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-edward/orth-scheme-comparison"

echo "[$(ts)] Launcher starting. PID=$$"

# Cell A: ctrl — nspoly_iter6 (current baseline; ~2.0s/step ≈ 1.8 hr)
echo "[$(ts)] Starting Cell A: nspoly_iter6 (ctrl)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --orth_scheme nspoly_iter6 \
  --wandb_name "edward-orth-A-nspoly_iter6-ctrl-n1" \
  --wandb_group "$GROUP" \
  > runlogs/orth_A_nspoly_iter6.log 2>&1
echo "[$(ts)] Cell A exit=$?"

# Cell B: PRIMARY — polar_svd_fp32 (exact polar factor; ~8s/step ≈ 7.2 hr)
echo "[$(ts)] Starting Cell B: polar_svd_fp32 (PRIMARY)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --orth_scheme polar_svd_fp32 \
  --wandb_name "edward-orth-B-polar_svd_fp32-primary-n1" \
  --wandb_group "$GROUP" \
  > runlogs/orth_B_polar_svd_fp32.log 2>&1
echo "[$(ts)] Cell B exit=$?"

# Cell C: schulz_iter5 (~2.2s/step ≈ 2.0 hr)
echo "[$(ts)] Starting Cell C: schulz_iter5"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --orth_scheme schulz_iter5 \
  --wandb_name "edward-orth-C-schulz_iter5-n1" \
  --wandb_group "$GROUP" \
  > runlogs/orth_C_schulz_iter5.log 2>&1
echo "[$(ts)] Cell C exit=$?"

# Cell D: schulz_iter8 (~2.4s/step ≈ 2.2 hr)
echo "[$(ts)] Starting Cell D: schulz_iter8"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --orth_scheme schulz_iter8 \
  --wandb_name "edward-orth-D-schulz_iter8-n1" \
  --wandb_group "$GROUP" \
  > runlogs/orth_D_schulz_iter8.log 2>&1
echo "[$(ts)] Cell D exit=$?"

# Cell E: nspoly_iter3 (degraded falsifier; ~1.8s/step ≈ 1.6 hr)
echo "[$(ts)] Starting Cell E: nspoly_iter3 (falsifier)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --orth_scheme nspoly_iter3 \
  --wandb_name "edward-orth-E-nspoly_iter3-falsifier-n1" \
  --wandb_group "$GROUP" \
  > runlogs/orth_E_nspoly_iter3.log 2>&1
echo "[$(ts)] Cell E exit=$?"

echo "[$(ts)] Launcher finished. Total elapsed sequential time."
