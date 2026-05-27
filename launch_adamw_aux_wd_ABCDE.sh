#!/bin/bash
set -uo pipefail

# #1334 AdamW aux weight_decay pruning — 5-cell sweep
# Cells A=0.0 (ctrl), B=0.01 (PRIMARY), C=0.001, D=0.025, E=0.1 (falsifier)
# Sequential same-GPU. Cells B/D/E have early-kill gates (see train_gpt_simple.py).

cd /workspace/senpai/target

GROUP="g1r5-edward/adamw-aux-wd-pruning"
COMMON_FLAGS=(
  --ns_iter 6
  --soap_attn
  --lr_mlp 0.055
  --wd_schedule ramp_down
  --lr_scalars 0.03
  --depth_init_mode musoft
  --num_trials 1
)

LAUNCHER_LOG="runlogs/adamw_aux_wd_launcher.log"
mkdir -p runlogs
: > "${LAUNCHER_LOG}"

stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

run_cell() {
  local cell="$1"
  local wd="$2"
  local desc="$3"
  local log="runlogs/adamw_aux_wd_${cell}_${desc}.log"
  echo "[$(stamp)] Starting Cell ${cell}: adamw_aux_wd=${wd} desc=${desc}" | tee -a "${LAUNCHER_LOG}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    --adamw_aux_wd "${wd}" \
    --wandb_name "g1r5-edward/adamw-wd-${cell}-${desc}" \
    --wandb_group "${GROUP}" \
    > "${log}" 2>&1
  local code=$?
  echo "[$(stamp)] Cell ${cell} exit=${code} log=${log}" | tee -a "${LAUNCHER_LOG}"
}

# Cell A — control (hardcoded baseline wd=0)
run_cell A 0.0     ctrl
# Cell B ★ — PRIMARY pruning, small uniform WD
run_cell B 0.01    primary
# Cell C — very small WD
run_cell C 0.001   tinywd
# Cell D — match body WD
run_cell D 0.025   bodywd
# Cell E — falsifier, aggressive
run_cell E 0.1     overwd

echo "[$(stamp)] All cells done." | tee -a "${LAUNCHER_LOG}"
