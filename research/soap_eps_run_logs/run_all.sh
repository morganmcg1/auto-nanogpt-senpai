#!/bin/bash
# Sequential runner for SOAP eps sweep (PR #1076) — Cells B-E
# Cell A (eps=1e-8 ctrl) already running in a prior session as `eps_A_1e-8_ctrl`.
# This chain picks up: B (1e-6 PRIMARY) → C (1e-4) → D (1e-10) → E (1e-2)
set -uo pipefail

cd "$(dirname "$0")/../.."

LOG_DIR="research/soap_eps_run_logs"

run_cell() {
    local label=$1
    local eps=$2
    local suffix=$3
    local logfile="${LOG_DIR}/cell_${label}_${eps}.log"
    echo "=== START Cell ${label} (eps=${eps}) at $(date -Iseconds) ===" | tee -a "${logfile}"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ns_iter 6 \
      --lr_scalars 0.03 --depth_init_mode musoft \
      --soap_eps "${eps}" \
      --wandb_name "eps_${label}_${eps}_${suffix}" \
      --wandb_group "g1r5-alphonse/soap-eps-sweep" >>"${logfile}" 2>&1
    local rc=$?
    echo "=== END Cell ${label} (eps=${eps}) rc=${rc} at $(date -Iseconds) ===" | tee -a "${logfile}"
    sleep 30
    return $rc
}

# Cell A (1e-8 ctrl) launched separately — skip here.
run_cell B 1e-6 primary
run_cell C 1e-4 loose
run_cell D 1e-10 tight
run_cell E 1e-2 extreme

echo "=== ALL CELLS DONE at $(date -Iseconds) ===" | tee -a "${LOG_DIR}/sweep.log"
