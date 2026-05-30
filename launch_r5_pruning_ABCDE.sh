#!/bin/bash
set -uo pipefail

# PR #1761: R5 stack pruning ablation — 5-cell leave-one-out, n=1, 3250 steps each.
# Cell A: full R5 stack (ctrl)
# Cell B★: drop --soap_attn (omit flag → store_true default False)
# Cell C: drop --ema_eval_decay 0.99 (omit flag → default None → EMA disabled)
# Cell D: drop --depth_init_mode musoft (omit flag → default "ctrl" = zero-init)
# Cell E: drop --wd_schedule ramp_down (omit flag → default "constant")

cd /workspace/senpai/target
mkdir -p runlogs

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Component-by-component build per Cell so leave-one-out is explicit (no $COMMON aliasing of the dropped flag).
SCALARS="--num_trials 1 --ns_iter 6 --lr_mlp 0.055 --lr_scalars 0.03 --lr_cooldown_shape cosine"
GROUP="g1r5-edward/r5-stack-pruning-ablation"

echo "[$(ts)] Launcher starting. PID=$$"

# ---------- Cell A: ctrl — full R5 stack as merged at PR #1533 ----------
echo "[$(ts)] Starting Cell A (ctrl): full R5 stack"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $SCALARS \
  --soap_attn \
  --wd_schedule ramp_down \
  --depth_init_mode musoft \
  --ema_eval_decay 0.99 \
  --wandb_name "r5-prune-A-ctrl" \
  --wandb_group "$GROUP" \
  > runlogs/r5_prune_A_ctrl.log 2>&1
echo "[$(ts)] Cell A exit=$?"
sleep 20

# ---------- Cell B★: drop --soap_attn (SOAP-MLP only via default) ----------
echo "[$(ts)] Starting Cell B (drop --soap_attn)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $SCALARS \
  --wd_schedule ramp_down \
  --depth_init_mode musoft \
  --ema_eval_decay 0.99 \
  --wandb_name "r5-prune-B-no-soap-attn" \
  --wandb_group "$GROUP" \
  > runlogs/r5_prune_B_no_soap_attn.log 2>&1
echo "[$(ts)] Cell B exit=$?"
sleep 20

# ---------- Cell C: drop --ema_eval_decay (EMA-eval disabled) ----------
echo "[$(ts)] Starting Cell C (drop --ema_eval_decay)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $SCALARS \
  --soap_attn \
  --wd_schedule ramp_down \
  --depth_init_mode musoft \
  --wandb_name "r5-prune-C-no-ema-eval" \
  --wandb_group "$GROUP" \
  > runlogs/r5_prune_C_no_ema_eval.log 2>&1
echo "[$(ts)] Cell C exit=$?"
sleep 20

# ---------- Cell D: drop --depth_init_mode musoft (default zero-init "ctrl") ----------
echo "[$(ts)] Starting Cell D (drop --depth_init_mode musoft → ctrl/zero-init)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $SCALARS \
  --soap_attn \
  --wd_schedule ramp_down \
  --ema_eval_decay 0.99 \
  --wandb_name "r5-prune-D-no-musoft-init" \
  --wandb_group "$GROUP" \
  > runlogs/r5_prune_D_no_musoft.log 2>&1
echo "[$(ts)] Cell D exit=$?"
sleep 20

# ---------- Cell E: drop --wd_schedule ramp_down (constant WD) ----------
echo "[$(ts)] Starting Cell E (drop --wd_schedule ramp_down → constant WD)"
SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  $SCALARS \
  --soap_attn \
  --depth_init_mode musoft \
  --ema_eval_decay 0.99 \
  --wandb_name "r5-prune-E-no-wd-rampdown" \
  --wandb_group "$GROUP" \
  > runlogs/r5_prune_E_no_wd_rampdown.log 2>&1
echo "[$(ts)] Cell E exit=$?"

echo "[$(ts)] Launcher done — all 5 cells finished."
