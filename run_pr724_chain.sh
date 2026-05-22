#!/usr/bin/env bash
# 4-arm sequential chain for PR #724: per-block-TYPE NS_ITERS_COOLDOWN
# Same shared envs across all arms; only NANOGPT_MUON_{ATTN,MLP}_NS_ITERS_COOLDOWN differs.
set -u

mkdir -p logs_pr724_chain
master_log="logs_pr724_chain/chain_master.log"
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log_section() {
  {
    echo "=============================================="
    echo "$1"
    echo "=============================================="
  } | tee -a "$master_log"
}

log_section "START PR724 chain $(ts)"

declare -A arms
arms[A]="16 16"
arms[B]="20 16"
arms[C]="16 20"
arms[D]="12 20"

for arm in A B C D; do
  read -r attn_ns mlp_ns <<< "${arms[$arm]}"
  arm_log="logs_pr724_chain/arm_${arm}.log"
  log_section "Arm $arm attn_ns=${attn_ns} mlp_ns=${mlp_ns} start $(ts)"
  echo "Log: $arm_log" | tee -a "$master_log"
  NANOGPT_GRAD_CLIP=10.0 \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_MUON_ATTN_NS_ITERS_COOLDOWN="${attn_ns}" \
  NANOGPT_MUON_MLP_NS_ITERS_COOLDOWN="${mlp_ns}" \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-nezuko/arm${arm}-attn${attn_ns}-mlp${mlp_ns}" \
    --wandb_group "g1r4-nezuko/per-type-ns-cooldown" \
    > "$arm_log" 2>&1
  ec=$?
  log_section "Arm $arm exit=$ec $(ts)"
  if [[ $ec -ne 0 ]]; then
    echo "Arm $arm FAILED with exit code $ec; aborting chain" | tee -a "$master_log"
    exit $ec
  fi
done

log_section "END PR724 chain $(ts)"
