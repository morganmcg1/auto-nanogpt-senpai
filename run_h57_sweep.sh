#!/bin/bash
# H57: MuonH inner momentum scheduling — 4 arms x 3325 steps.
#   arm_a (ctrl): schedule=0 (constant mu=0.95)
#   arm_b: schedule=1 mu 0.85 -> 0.95 -> 0.97 (default ramp, warm + cooldown)
#   arm_c: schedule=1 mu 0.90 -> 0.95 -> 0.97 (gentler warm)
#   arm_d: schedule=1 mu 0.85 -> 0.95 -> 0.95 (warm-only, no cooldown ramp)
# Common args mirror the PR's reproduce command (omits --train_steps; we set per-arm).
set -uo pipefail
cd /workspace/senpai/target
mkdir -p logs_h57

STEPS=3325
# Baseline flags from BASELINE.md PR #443 (val=3.27119). The PR-body's
# reproduce command was missing --muonh_mode scale_invariant,
# --muonh_cooldown_shape cosine, and --aux_agc_clip_ratio 0.05; without them
# the run uses defaults (mode=clip, cooldown=linear, no aux AGC) and lands at
# ~3.29, far above the cited noise floor. v1 arm_a confirmed the regression
# (val=3.29305, ffs=-1). This COMMON now matches BASELINE.md's reproduce.
COMMON=(
  --num_trials 1
  --train_steps "${STEPS}"
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_lr 0.018
  --aux_adamw_eps 1e-6
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --wandb_group "h57_muonh_inner_mu_schedule"
)

run_arm() {
  local TAG="$1"
  local NAME="$2"
  shift 2
  local LOG="logs_h57/${TAG}.log"
  : > "${LOG}"
  echo "=== ARM ${TAG} STARTED at $(date -u +%FT%TZ) ===" | tee -a "${LOG}"
  echo "args: $@" | tee -a "${LOG}"

  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --wandb_name "${NAME}" \
    "$@" \
    >> "${LOG}" 2>&1

  local EXIT=$?
  echo "=== ARM ${TAG} FINISHED at $(date -u +%FT%TZ) (exit=${EXIT}) ===" | tee -a "${LOG}"
}

run_arm "arm_a_ctrl" "g1r3-tanjiro/h57_arm_a_ctrl" \
  --muonh_mu_schedule 0

run_arm "arm_b_default_ramp" "g1r3-tanjiro/h57_arm_b_default_ramp" \
  --muonh_mu_schedule 1 --muonh_mu_start 0.85 --muonh_mu_mid 0.95 --muonh_mu_end 0.97

run_arm "arm_c_gentle_warm" "g1r3-tanjiro/h57_arm_c_gentle_warm" \
  --muonh_mu_schedule 1 --muonh_mu_start 0.90 --muonh_mu_mid 0.95 --muonh_mu_end 0.97

run_arm "arm_d_warm_only" "g1r3-tanjiro/h57_arm_d_warm_only" \
  --muonh_mu_schedule 1 --muonh_mu_start 0.85 --muonh_mu_mid 0.95 --muonh_mu_end 0.95

echo "=== ALL ARMS DONE at $(date -u +%FT%TZ) ===" | tee -a logs_h57/sweep_master.log
