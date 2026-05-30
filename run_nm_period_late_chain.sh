#!/bin/bash
# Sequential SEED=0 3-arm chain for PR #1743: NM update-period late-window boost
# Arm A = ctrl (PERIOD_LATE=0 → no switch, bit-identical to current production)
# Arm B = PERIOD_LATE=1, SWITCH_STEP=2400
# Arm C = PERIOD_LATE=1, SWITCH_STEP=3000
#
# IMPORTANT: this script exports the FULL post-#1543 production stack so the
# SEED=0 ctrl reproduces the merged baseline (val ≈ 3.262-3.263, FFS=3150).
# Prior run with only the new env vars stripped the stack and drifted to
# val=3.27362 / FFS=3250 (see run_logs/nm_period_late_*.SHORT-STACK.log).

set -uo pipefail

cd /workspace/senpai/target
mkdir -p run_logs

LOG_DIR=run_logs
GROUP="nm-period-late-window-cooldown-freshness"

# Full post-#1543 production stack (matches run_nm_alpha_chain.sh + tikhonov_gamma).
export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_EPS=1e-4
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export SENPAI_SEED=0
export NANOGPT_TRAIN_STEPS=3350

run_arm() {
  local arm_id="$1"
  local period_late="$2"
  local switch_step="$3"
  local name="$4"
  local logfile="${LOG_DIR}/nm_period_late_${arm_id}.log"

  echo "=== Arm ${arm_id} starting at $(date -u +%FT%TZ): PERIOD_LATE=${period_late} SWITCH_STEP=${switch_step} ===" \
    | tee -a "${LOG_DIR}/nm_period_late_chain.log"

  NANOGPT_NEWTON_MUON_UPDATE_PERIOD_LATE="${period_late}" \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD_SWITCH_STEP="${switch_step}" \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_project modded-nanogpt-senpai \
      --wandb_group "${GROUP}" \
      --wandb_name "${name}" \
    > "${logfile}" 2>&1

  local rc=$?
  echo "=== Arm ${arm_id} finished at $(date -u +%FT%TZ) rc=${rc} ===" \
    | tee -a "${LOG_DIR}/nm_period_late_chain.log"
  return $rc
}

# Arm A: ctrl
run_arm A 0 0 "g1r4-thorfinn/nm-period-late-A-ctrl"

# Arm B: PERIOD_LATE=1 from step 2400
run_arm B 1 2400 "g1r4-thorfinn/nm-period-late-B-switch2400"

# Arm C: PERIOD_LATE=1 from step 3000
run_arm C 1 3000 "g1r4-thorfinn/nm-period-late-C-switch3000"

echo "=== Chain finished at $(date -u +%FT%TZ) ===" \
  | tee -a "${LOG_DIR}/nm_period_late_chain.log"
