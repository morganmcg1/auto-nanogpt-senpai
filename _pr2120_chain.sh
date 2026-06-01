#!/bin/bash
# PR #2120 — NM_R_ADAMW_WARMSTART_K fine bracket {50, 100 ctrl, 200}.
# Arm A: K=100 ctrl (production stack reproduce, SEED=0).
# Arm B: K=50  (thin v-EMA warmstart, earlier NM engagement).
# Arm C: K=200 (mature v-EMA warmstart, later NM engagement).
# 8th R-buffer characterization axis (activation-step / warmstart-length).
# ZERO new code — env var only.
set -uo pipefail
cd /workspace/senpai/target

COMMON_ENV=(
  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0
  NANOGPT_ADAMW_BETA2=0.99 NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
  SENPAI_SEED=0
)

CMD=(torchrun --standalone --nproc_per_node=1
  records/track_3_optimization/train_gpt_simple.py
  --wandb_group alphonse-warmstart-k-bracket)

# ============ Arm A: K=100 ctrl (production reproduce) ============
echo "=== ARM A (WARMSTART_K=100, ctrl) ==="
env "${COMMON_ENV[@]}" \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  WANDB_TAGS=arm_A_k100_ctrl \
  "${CMD[@]}" --wandb_name "g1r4-alphonse/warmstart-k-armA-k100-s0" \
  >pr2120_arm_A.log 2>&1
echo "=== ARM A complete; tail: ==="
tail -25 pr2120_arm_A.log

# ============ Arm B: K=50 (thin v-EMA warmstart) ============
echo "=== ARM B (WARMSTART_K=50, thin) ==="
env "${COMMON_ENV[@]}" \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=50 \
  WANDB_TAGS=arm_B_k50_thin \
  "${CMD[@]}" --wandb_name "g1r4-alphonse/warmstart-k-armB-k50-s0" \
  >pr2120_arm_B.log 2>&1
echo "=== ARM B complete; tail: ==="
tail -25 pr2120_arm_B.log

# ============ Arm C: K=200 (mature v-EMA warmstart) ============
echo "=== ARM C (WARMSTART_K=200, mature) ==="
env "${COMMON_ENV[@]}" \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=200 \
  WANDB_TAGS=arm_C_k200_mature \
  "${CMD[@]}" --wandb_name "g1r4-alphonse/warmstart-k-armC-k200-s0" \
  >pr2120_arm_C.log 2>&1
echo "=== ARM C complete; tail: ==="
tail -25 pr2120_arm_C.log

echo "=== CHAIN DONE ==="
