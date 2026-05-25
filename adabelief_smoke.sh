#!/usr/bin/env bash
# Smoke test for AdaBelief implementation: 50-step debug run for both
# bit-identical fallback (NANOGPT_ADABELIEF_GROUPS="") and AdaBelief-on-lm_head.
# Verifies no crash, telemetry logged, and fallback path stable.
set -euo pipefail
cd /workspace/senpai/target

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
export NANOGPT_TRAIN_STEPS=50
export NANOGPT_TELEMETRY_INTERVAL=25
export STUDENT_NAME=g1r4-alphonse

stage="${1:-fallback}"
case "$stage" in
  fallback)
    export NANOGPT_ADABELIEF_GROUPS=""
    name="adabelief-smoke-fallback"
    ;;
  lmhead)
    export NANOGPT_ADABELIEF_GROUPS=lm_head
    export NANOGPT_ADABELIEF_EPS_S=1e-16
    name="adabelief-smoke-lmhead"
    ;;
  allaux)
    export NANOGPT_ADABELIEF_GROUPS="lm_head,embed,scalars"
    export NANOGPT_ADABELIEF_EPS_S=1e-16
    name="adabelief-smoke-allaux"
    ;;
  beta2-095)
    export NANOGPT_ADABELIEF_GROUPS=lm_head
    export NANOGPT_ADABELIEF_EPS_S=1e-16
    export NANOGPT_ADABELIEF_BETA2=0.95
    name="adabelief-smoke-beta2-095"
    ;;
  *) echo "unknown stage: $stage"; exit 1 ;;
esac

torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --wandb_group "g1r4-alphonse/adabelief-lm-head-smoke" \
  --wandb_name "${name}" \
  --wandb_mode online
