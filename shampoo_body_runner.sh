#!/usr/bin/env bash
# Runner for PR #1132: Shampoo body — replace NS5 polar decomp with
# Kronecker-factored 2nd-order preconditioner (Anil 2018). 4-arm sequential sweep.
#
# Arms:
#   A ctrl       = NANOGPT_BODY_OPT=muon (NS5 polar decomp, baseline drift gate)
#   B mech-lead  = NANOGPT_BODY_OPT=shampoo, beta=0.95, period=200, lr_scale=0.5
#   C            = NANOGPT_BODY_OPT=shampoo, beta=0.95, period=200, lr_scale=1.0
#   D            = NANOGPT_BODY_OPT=shampoo, beta=0.95, period=50,  lr_scale=0.5
#
# Stack: post-#847 (clip body=10/aux=5, NS_ITERS=12+16 late_peak+stochastic=2,
# embed linear_floor, beta2=0.99, embed_lr_mult=1.5, muon attn=0.80/mlp=1.20,
# embed_init_anchor_lambda=0.001, NS_COEF=linear_ramp_down). All arms SENPAI_SEED=1.
set -u
set -o pipefail
cd /workspace/senpai/target

base_env() {
  export NANOGPT_GRAD_CLIP=10.0
  export NANOGPT_GRAD_CLIP_BODY=10.0
  export NANOGPT_GRAD_CLIP_AUX=5.0
  export NANOGPT_NS_ITERS=12
  export NANOGPT_NS_ITERS_COOLDOWN=16
  export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
  export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
  export NANOGPT_ADAMW_BETA2=0.99
  export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
  export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
  export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
  export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
  export NANOGPT_MUON_ATTN_LR_MULT=0.80
  export NANOGPT_MUON_MLP_LR_MULT=1.20
  export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
  export SENPAI_SEED=1
  export NANOGPT_TRAIN_STEPS=3350
}

GROUP="g1r4-alphonse/shampoo-body"

run_arm() {
  local arm_label="$1"
  local body_opt="$2"
  local shampoo_lr_scale="$3"
  local shampoo_period="$4"
  local wandb_suffix="$5"
  local logfile="$6"
  base_env
  export NANOGPT_BODY_OPT="${body_opt}"
  export NANOGPT_SHAMPOO_BETA=0.95
  export NANOGPT_SHAMPOO_LR_SCALE="${shampoo_lr_scale}"
  export NANOGPT_SHAMPOO_PERIOD="${shampoo_period}"
  # NOTE: rebuilt after #1132 initial divergence. Stable-Shampoo defaults:
  # eps=1e-6 (identity-init scale + absolute floor), ridge_rel=1e-6 (relative
  # ridge damping in matrix_inverse_root), GRAFT=1 (Frobenius-norm graft of
  # Shampoo direction onto NS5 reference magnitude = sqrt(d_out)). Old buggy
  # config used eps=1e-12 with no ridge and no graft → diverged at step 1.
  export NANOGPT_SHAMPOO_EPS=1e-6
  export NANOGPT_SHAMPOO_RIDGE_REL=1e-6
  export NANOGPT_SHAMPOO_GRAFT=1
  echo "=== ARM ${arm_label} | BODY_OPT=${body_opt} LR_SCALE=${shampoo_lr_scale} PERIOD=${shampoo_period} | $(date -u +%H:%M:%S) ===" | tee -a "${logfile}"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "${wandb_suffix}" \
    --wandb_group "${GROUP}" \
    >> "${logfile}" 2>&1
  local rc=$?
  echo "=== ARM ${arm_label} exit=${rc} | $(date -u +%H:%M:%S) ===" | tee -a "${logfile}"
  return $rc
}

run_arm A-ctrl     muon    1.0 200 g1r4-alphonse-arm-A-muon-ctrl        shampoo_body_arm_A.log
run_arm B-mechlead shampoo 0.5 200 g1r4-alphonse-arm-B-shampoo-lr05     shampoo_body_arm_B.log
run_arm C          shampoo 1.0 200 g1r4-alphonse-arm-C-shampoo-lr10     shampoo_body_arm_C.log
run_arm D          shampoo 0.5 50  g1r4-alphonse-arm-D-shampoo-period50 shampoo_body_arm_D.log

echo "=== ALL ARMS DONE | $(date -u +%H:%M:%S) ==="
