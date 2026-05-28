#!/bin/bash
# PR #1534 — NM R-buffer stochastic token subsampling
# 4 arms sequential A->D, NANOGPT_NEWTON_MUON_R_SUBSAMPLE_RATIO in {1.0, 0.5, 0.25, 0.1}
# SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 num_trials=1 single H100
# All other env vars match the production stack from BASELINE.md row #1421:
#  - Newton-Muon (period=2, max_d_in=4096, beta=0.95, eps=1e-4)
#  - NS stack (iters=12, cooldown=16 @ 70% frac, late_peak shape, stochastic=2)
#  - Embed (init-anchor lambda=0.001, linear_floor cooldown, AdamW embed lr mult=1.5)
#  - Body (Muon attn 0.80, mlp 1.20)
#  - AdamW beta2=0.99
#  - Grad clip body=10.0, aux=5.0
set -u
LOG_DIR="_logs/pr1534"
mkdir -p "$LOG_DIR"

run_arm () {
  local arm_name="$1"
  local ratio="$2"
  local logfile="$LOG_DIR/${arm_name}.log"
  echo "[$(date -Iseconds)] >>> Launching arm $arm_name (R_SUBSAMPLE_RATIO=$ratio) logfile=$logfile"
  NANOGPT_GRAD_CLIP=10.0 NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_R_SUBSAMPLE_RATIO=$ratio \
  SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --wandb_group "g1r4-edward/nm-r-token-subsample" \
    --wandb_name "g1r4-edward-nm-rsub-${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "[$(date -Iseconds)] <<< Arm $arm_name exit=$rc"
  return $rc
}

echo "[$(date -Iseconds)] PR #1534 NM R-buffer token subsample chain starting"
run_arm A-1.0  1.0
run_arm B-0.5  0.5
run_arm C-0.25 0.25
run_arm D-0.1  0.1
echo "[$(date -Iseconds)] PR #1534 chain complete"
