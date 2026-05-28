#!/bin/bash
set -uo pipefail

# PR #1502: Sophia-G (2nd-order GNB) on AdamW aux groups (Liu ICLR 2024)
# 5-cell n=1 sweep, sequential A->E single chain.

cd /workspace/senpai/target
mkdir -p runlogs

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Mandatory baseline-stack flags (DO NOT omit):
COMMON="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-edward/sophia-aux-n1-sweep"

echo "[$(ts)] Launcher starting. PID=$$"

# Cell A: AdamW baseline (no Sophia) — parity sanity check
echo "[$(ts)] Starting Cell A: AdamW ctrl"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --wandb_name "g1r5-edward/sophia-A-adamw-ctrl-n1" \
  --wandb_group "$GROUP" \
  > runlogs/sophia_A_adamw_ctrl.log 2>&1
echo "[$(ts)] Cell A exit=$?"

# Cell B*: Sophia rho=0.05 lr_scale=1.0 (paper defaults, primary)
echo "[$(ts)] Starting Cell B: sophia rho=0.05 lr_scale=1.0 (primary)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --use_sophia_aux --sophia_rho 0.05 --sophia_lr_scale 1.0 --sophia_k 10 \
  --wandb_name "g1r5-edward/sophia-B-rho0.05-lr1.0-primary-n1" \
  --wandb_group "$GROUP" \
  > runlogs/sophia_B_rho05_lr10.log 2>&1
echo "[$(ts)] Cell B exit=$?"

# Cell C: Sophia rho=0.10 lr_scale=1.0 (looser clip — more 2nd-order signal)
echo "[$(ts)] Starting Cell C: sophia rho=0.10 lr_scale=1.0 (looser clip)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --use_sophia_aux --sophia_rho 0.10 --sophia_lr_scale 1.0 --sophia_k 10 \
  --wandb_name "g1r5-edward/sophia-C-rho0.10-lr1.0-n1" \
  --wandb_group "$GROUP" \
  > runlogs/sophia_C_rho10_lr10.log 2>&1
echo "[$(ts)] Cell C exit=$?"

# Cell D: Sophia rho=0.05 lr_scale=0.5 (half LR)
echo "[$(ts)] Starting Cell D: sophia rho=0.05 lr_scale=0.5 (half LR)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --use_sophia_aux --sophia_rho 0.05 --sophia_lr_scale 0.5 --sophia_k 10 \
  --wandb_name "g1r5-edward/sophia-D-rho0.05-lr0.5-n1" \
  --wandb_group "$GROUP" \
  > runlogs/sophia_D_rho05_lr05.log 2>&1
echo "[$(ts)] Cell D exit=$?"

# Cell E: Sophia rho=0.05 lr_scale=2.0 (double LR)
echo "[$(ts)] Starting Cell E: sophia rho=0.05 lr_scale=2.0 (double LR)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $COMMON \
  --use_sophia_aux --sophia_rho 0.05 --sophia_lr_scale 2.0 --sophia_k 10 \
  --wandb_name "g1r5-edward/sophia-E-rho0.05-lr2.0-n1" \
  --wandb_group "$GROUP" \
  > runlogs/sophia_E_rho05_lr20.log 2>&1
echo "[$(ts)] Cell E exit=$?"

echo "[$(ts)] All 5 cells finished."
