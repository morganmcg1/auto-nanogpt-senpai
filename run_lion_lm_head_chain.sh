#!/usr/bin/env bash
# Lion lm_head 4-arm sequential chain: A (ctrl) -> B (LR=1e-3) -> C (LR=5e-4) -> D (cautious LR=1e-3).
# All arms: SENPAI_SEED=0, NANOGPT_TRAIN_STEPS=3350.
# Post-#1138 stack: Newton-Muon right-precond on body Muon is now part of baseline.
set -u
LOG_DIR="lion_lm_head_logs"
mkdir -p "$LOG_DIR"

# Shared base env (post-#1138 baseline stack).
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
# Newton-Muon (#1138) — new baseline component on body Muon. Mechanism-orthogonal
# to Lion lm_head (body vs aux), enabled for ctrl drift gate against the
# new 3.26614 baseline.
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10
export NANOGPT_NEWTON_MUON_MAX_D_IN=1024
export SENPAI_SEED=0
export NANOGPT_TRAIN_STEPS=3350
export STUDENT_NAME=g1r4-fern

clear_lion_env() {
  unset NANOGPT_LM_HEAD_LION NANOGPT_LM_HEAD_LION_LR \
        NANOGPT_LM_HEAD_LION_BETA1 NANOGPT_LM_HEAD_LION_BETA2 \
        NANOGPT_LM_HEAD_LION_WD NANOGPT_LM_HEAD_LION_CAUTIOUS
}

launch() {
  local arm_name="$1"
  local out="$LOG_DIR/${arm_name}.log"
  echo "[$(date -u +%FT%TZ)] starting arm=${arm_name}" | tee -a "$LOG_DIR/chain.log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 --wandb_group "g1r4-fern/lion-lm-head" \
    --wandb_name "g1r4-fern/lion-lm-head-${arm_name}" \
    > "$out" 2>&1
  local ec=$?
  echo "[$(date -u +%FT%TZ)] arm=${arm_name} exit=${ec}" | tee -a "$LOG_DIR/chain.log"
  return $ec
}

# Arm A: ctrl AdamW lm_head.
clear_lion_env
export NANOGPT_LM_HEAD_LION=0
launch "armA-ctrl"

# Arm B: Lion lm_head LR=0.001.
clear_lion_env
export NANOGPT_LM_HEAD_LION=1
export NANOGPT_LM_HEAD_LION_LR=0.001
export NANOGPT_LM_HEAD_LION_BETA1=0.9
export NANOGPT_LM_HEAD_LION_BETA2=0.99
export NANOGPT_LM_HEAD_LION_WD=0.0
export NANOGPT_LM_HEAD_LION_CAUTIOUS=0
launch "armB-lion001"

# Arm C: Lion lm_head LR=0.0005.
clear_lion_env
export NANOGPT_LM_HEAD_LION=1
export NANOGPT_LM_HEAD_LION_LR=0.0005
export NANOGPT_LM_HEAD_LION_BETA1=0.9
export NANOGPT_LM_HEAD_LION_BETA2=0.99
export NANOGPT_LM_HEAD_LION_WD=0.0
export NANOGPT_LM_HEAD_LION_CAUTIOUS=0
launch "armC-lion0005"

# Arm D: Lion-Cautious lm_head LR=0.001.
clear_lion_env
export NANOGPT_LM_HEAD_LION=1
export NANOGPT_LM_HEAD_LION_LR=0.001
export NANOGPT_LM_HEAD_LION_BETA1=0.9
export NANOGPT_LM_HEAD_LION_BETA2=0.99
export NANOGPT_LM_HEAD_LION_WD=0.0
export NANOGPT_LM_HEAD_LION_CAUTIOUS=1
launch "armD-lion-cautious"

echo "[$(date -u +%FT%TZ)] chain complete" | tee -a "$LOG_DIR/chain.log"
