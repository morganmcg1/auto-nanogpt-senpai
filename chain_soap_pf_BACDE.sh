#!/bin/bash
# PR #1279 — SOAP PRECOND_FREQ pruning sweep (g1r5-tanjiro)
# Order: B (primary) → A (ctrl) → C → D → E (falsifier)
# 5 cells × ~110 min = ~9 hours total
set -e

cd "$(dirname "$0")"
mkdir -p logs_soap_pf

GROUP="g1r5-tanjiro/soap-precond-freq-pruning"
COMMON=(--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055
        --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft
        --wandb_group "$GROUP")

run_cell () {
  local tag="$1"
  local freq="$2"
  local logf="logs_soap_pf/${tag}.log"
  echo "===== $(date -u +%FT%TZ) launching cell ${tag} freq=${freq} =====" | tee "$logf"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --soap_precond_freq "$freq" \
    --wandb_name "soap-pf-${tag}-n1" \
    2>&1 | tee -a "$logf"
  echo "===== $(date -u +%FT%TZ) finished cell ${tag} =====" | tee -a "$logf"
}

# B PRIMARY first — earliest FFS readout
run_cell "B-32-primary" 32
run_cell "A-16-ctrl" 16
run_cell "C-8" 8
run_cell "D-64" 64
run_cell "E-4-falsifier" 4

echo "===== $(date -u +%FT%TZ) ALL 5 CELLS COMPLETE =====" | tee -a logs_soap_pf/done.txt
