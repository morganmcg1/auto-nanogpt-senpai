#!/usr/bin/env bash
# PR #1689 sequential 5-cell sweep for SOAP Gram-matrix β₂ warmup.
# Runs Cell A → B → C → D → E on the single available GPU.
set -uo pipefail

cd "$(dirname "$0")"

GROUP="g1r5-alphonse/soap-gram-b2-warmup"
COMMON=(
  --num_trials 1
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
  --lr_scalars 0.03 --depth_init_mode musoft
  --lr_cooldown_shape cosine
  --ema_eval_decay 0.99
  --wandb_group "$GROUP"
)

mkdir -p logs/pr1689

run_cell() {
  local name="$1"; shift
  local extra=( "$@" )
  local log="logs/pr1689/cell_${name}.log"
  local started_at
  started_at=$(date -u +%FT%TZ)
  echo "==== Cell ${name} START ${started_at} ====" | tee -a "$log"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" "${extra[@]}" \
    --wandb_name "g1r5-alphonse/soap-gram-b2-warmup-cell-${name}" \
    >>"$log" 2>&1
  local rc=$?
  local finished_at
  finished_at=$(date -u +%FT%TZ)
  echo "==== Cell ${name} END ${finished_at} rc=${rc} ====" | tee -a "$log"
  return $rc
}

# Cell A: ctrl (no warmup flags)
run_cell A
# Cell B: primary (aggressive)
run_cell B --soap_b2_warmup_init 0.50 --soap_b2_warmup_steps 300
# Cell C: mild
run_cell C --soap_b2_warmup_init 0.70 --soap_b2_warmup_steps 300
# Cell D: very mild
run_cell D --soap_b2_warmup_init 0.85 --soap_b2_warmup_steps 300
# Cell E: shorter ramp diagnostic
run_cell E --soap_b2_warmup_init 0.50 --soap_b2_warmup_steps 150

echo "==== ALL CELLS DONE $(date -u +%FT%TZ) ===="
