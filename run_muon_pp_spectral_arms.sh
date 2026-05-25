#!/usr/bin/env bash
# 4-arm runner for PR #1172 — Muon++ μP spectral control.
# Arms: A ctrl (PP_INIT=0, PP_SCALE=0), B full (1,1), C init-only (1,0), D scale-only (0,1).
# Single GPU, sequential. Each arm: 3350 steps, SENPAI_SEED=1, matches advisor PR spec.
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

run_arm() {
  local arm_label="$1"   # A, B, C, D
  local pp_init="$2"     # 0 or 1
  local pp_scale="$3"    # 0 or 1
  local arm_descr="$4"   # 'ctrl' / 'full' / 'init-only' / 'scale-only'
  local logfile="$5"

  echo "[muon-pp] launching arm ${arm_label} (${arm_descr}): PP_INIT=${pp_init} PP_SCALE=${pp_scale} -> ${logfile}"
  base_env
  export NANOGPT_MUON_PP_INIT="${pp_init}"
  export NANOGPT_MUON_PP_SCALE="${pp_scale}"

  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --wandb_name "g1r4-alphonse-muon-pp-arm-${arm_label}-${arm_descr}" \
    --wandb_group "g1r4-alphonse/muon-pp-spectral" \
    > "${logfile}" 2>&1
  local rc=$?
  echo "[muon-pp] arm ${arm_label} exit=${rc}"
  return $rc
}

# Sequential 4-arm execution
run_arm A 0 0 ctrl       muon_pp_arm_A.log
run_arm B 1 1 full       muon_pp_arm_B.log
run_arm C 1 0 init-only  muon_pp_arm_C.log
run_arm D 0 1 scale-only muon_pp_arm_D.log

echo "[muon-pp] all 4 arms complete"
