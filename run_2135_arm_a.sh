#!/usr/bin/env bash
# PR #2135 Arm A SEED=1: MLP-SOAP front=fast × proj-excluded 3-kind cross-axis structural compound
# Env-var translation per cherry-pick 8cb1c17/a812c8d:
#   MLP_SOAP_FRONT_HALF=1 → front half uses FAST (β2=0.85)
#   MLP_SOAP_BACK_HALF=0  → back half uses SLOW (β2=0.95)
# PR body says "fast"/"slow" but int() would fail; integer toggle is canonical.
set -euo pipefail
cd /workspace/senpai/target

export MLP_SOAP_PER_DEPTH_HALF_ENABLED=1
export MLP_SOAP_FRONT_HALF=1
export MLP_SOAP_BACK_HALF=0
export ATTN_SOAP_EXCLUSION_BITFIELD=8
export NS5_ITERS=14
export WD_AUX=0.001
export CONTRA_MUON=0.4
export MUON_LR=0.04
export EMBED_INIT_STD=0.1
export LOGIT_SOFTCAP=20.0
export MU_COOLDOWN_START=0.95
export MU_COOLDOWN_END=0.90
export ATTN_SOAP_TRUST_THRESHOLD=0.85
export MU_WARMUP_STEPS=200
export MU_WARMUP_START=0.85
export SEED=1

mkdir -p _runlogs
exec torchrun --standalone --nproc-per-node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --train_steps 3175 --num_trials 1 \
  --wandb_name "g1r2-fern/arm-a-mlp-soap-front-fast-x-proj-excluded-seed1" \
  --wandb_group "g1r2-fern-mlp-soap-front-fast-x-proj-excluded-cross-axis-structural-compound"
