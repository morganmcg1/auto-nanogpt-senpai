#!/bin/bash
set -uo pipefail

cd /workspace/senpai/target

GROUP="g1r5-edward/soap-asymm-q-refresh-freq"
COMMON_FLAGS=(
  --ns_iter 6
  --soap_attn
  --lr_mlp 0.055
  --wd_schedule ramp_down
  --lr_scalars 0.03
  --depth_init_mode musoft
  --num_trials 1
)

run_cell() {
  local cell="$1"
  local qrow="$2"
  local qcol="$3"
  local log="runlogs/soap_asymm_q_${cell}_qrow${qrow}_qcol${qcol}.log"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting Cell ${cell}: qrow_freq=${qrow} qcol_freq=${qcol} -> ${log}"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    --soap_qrow_freq "${qrow}" \
    --soap_qcol_freq "${qcol}" \
    --wandb_name "g1r5-edward/soap-asymm-q-${cell}-qrow${qrow}-qcol${qcol}" \
    --wandb_group "${GROUP}" \
    > "${log}" 2>&1
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Cell ${cell} exit=$?"
}

# Cell B ★ PRIMARY: Q_row 4× less often than Q_col
run_cell B 64 16

# Cell A (ctrl): identity check — refactor-neutrality
run_cell A 16 16

# Cell C: milder Q_row slowdown
run_cell C 32 16

# Cell D: stronger Q_row slowdown
run_cell D 128 16

# Cell E (falsifier): inverse asymmetry — Q_col is load-bearing per #936/#994,
#                    so this should regress
run_cell E 16 64

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] All cells done."
