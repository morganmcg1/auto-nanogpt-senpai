#!/bin/bash
# n=8 extension for PR #1105 Cell B (wd_aux=0.001) — Phase 3.
# n=4 came back borderline: mu_4 = 3.260020 in (3.259221, 3.260628].
# Advisor escalation: 4 additional independent trials for n=8 statistics.
#
# Seed convention: train_gpt_simple.py has NO explicit seeding (no
# torch.manual_seed anywhere). Each torchrun process starts with fresh
# non-deterministic CUDA RNG state, so relaunching --num_trials 4 yields
# 4 new independent samples (functional equivalent of "seeds 4-7").
#
# n=8 merge gate (predeclared): mu_8 <= 3.259807
#   statsig: (3.261221 - mu_8) * sqrt(8) >= 0.004
# If mu_8 > 3.259807 -> close clean-WEAK-NEG.
set -u
cd /workspace/senpai/target

LOG_DIR=logs
mkdir -p "$LOG_DIR"
STATE=logs/wd_aux_cellB_n8_state.txt
LOG=logs/cell_B_n8_extension_wd_aux_0.001.log

log_state() { echo "$(date -Is) $*" | tee -a "$STATE"; }

log_state "launching Cell B n=8 extension (wd_aux=0.001, num_trials=4, fresh process for new RNG)"
SENPAI_TRAIN_STEPS=3250 nohup torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 4 \
  --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --ns_iter 6 --lr_scalars 0.03 --depth_init_mode musoft \
  --wd_aux 0.001 \
  --wandb_name "cell-B-n8-extension-trials-4-7" \
  --wandb_group "g1r5-askeladd/adamw-aux-wd" \
  > "$LOG" 2>&1 &
PID=$!
echo "$PID" > logs/wd_aux_cellB_n8.pid
log_state "Cell B n=8 extension torchrun PID $PID logged to $LOG"
wait "$PID"
RC=$?
log_state "Cell B n=8 extension finished rc=$RC"

# Extract trial-final val_loss from the log
TRIALS=$(grep -oP "trial:\d+ best_val_loss:\K[0-9.]+" "$LOG" | tr '\n' ' ')
log_state "extension trial val_losses: $TRIALS"
log_state "n=8 extension complete (combine with prior n=4 [3.26013 3.25882 3.26235 3.25878] for mu_8)"
