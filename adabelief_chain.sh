#!/usr/bin/env bash
# 4-arm AdaBelief chain (#1210):
#   A ctrl                 : NANOGPT_ADABELIEF_GROUPS="" (bit-identical fallback)
#   B mech-lead            : NANOGPT_ADABELIEF_GROUPS=lm_head, β2=0.99 (primary)
#   C scope-expansion      : NANOGPT_ADABELIEF_GROUPS=lm_head,embed,scalars
#   D β2-sensitivity       : NANOGPT_ADABELIEF_GROUPS=lm_head, β2=0.95
# Each arm: SENPAI_SEED=0, NANOGPT_TRAIN_STEPS=3350, --num_trials 1.
set -euo pipefail
cd /workspace/senpai/target

# Stack envs (post-#847 merged baseline)
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export SENPAI_SEED=0
export NANOGPT_TRAIN_STEPS=3350
export NANOGPT_TELEMETRY_INTERVAL=25
export NANOGPT_ADABELIEF_EPS_S=1e-16
export STUDENT_NAME=g1r4-alphonse

WANDB_GROUP="g1r4-alphonse/adabelief-lm-head"

run_arm() {
  local arm="$1"
  local groups="$2"
  local b2_override="$3"
  local name="adabelief-arm-${arm}"
  local logfile="adabelief_arm_${arm}.log"
  echo "[$(date -u +%FT%TZ)] === arm $arm groups='$groups' β2_belief='$b2_override' ==="
  if [[ -n "$b2_override" ]]; then
    NANOGPT_ADABELIEF_GROUPS="$groups" \
    NANOGPT_ADABELIEF_BETA2="$b2_override" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "$WANDB_GROUP" \
      --wandb_name "$name" \
      --wandb_mode online \
      > "$logfile" 2>&1
  else
    NANOGPT_ADABELIEF_GROUPS="$groups" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "$WANDB_GROUP" \
      --wandb_name "$name" \
      --wandb_mode online \
      > "$logfile" 2>&1
  fi
  echo "[$(date -u +%FT%TZ)] === arm $arm DONE ==="
}

# Run sequentially: A → B → C → D
run_arm "A-ctrl"     ""                          ""
run_arm "B-lmhead"   "lm_head"                   ""
run_arm "C-allaux"   "lm_head,embed,scalars"     ""
run_arm "D-b2-095"   "lm_head"                   "0.95"

echo "[$(date -u +%FT%TZ)] === all arms complete ==="
