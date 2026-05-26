#!/bin/bash
# H4 — Late-window NM coverage+period tune (PR #1286).
#
# 2x2 mini-factorial across late-window coverage AND period axes, gated by
# NEWTON_MUON_LATE_START_STEP=2400. All arms use the post-#1138 merged stack
# (NANOGPT_NEWTON_MUON=1, ANCHOR, attn/mlp asym, stochastic NS cooldown, etc.).
#
# Arm A ctrl           : (no LATE_* envs)
# Arm B late_period_5  : LATE_PERIOD=5
# Arm C late_maxd_4096 : LATE_MAX_D_IN=4096
# Arm D late_compound  : LATE_PERIOD=5 + LATE_MAX_D_IN=4096
#
# Single seed (SENPAI_SEED=0), 3350 steps. ~7-8h sequential on 1xH100.

set -u
cd "$(dirname "$0")"

LOG_DIR="h4_late_window_logs"
mkdir -p "$LOG_DIR"
ORCH_LOG="$LOG_DIR/orchestrator.log"
NPROC=$(nvidia-smi -L | wc -l)

echo "=== H4 CHAIN START $(date -Is) NPROC=$NPROC ===" | tee -a "$ORCH_LOG"

run_arm() {
    local arm="$1"
    local late_period="$2"
    local late_max_d="$3"
    local late_start="$4"
    local variant="$5"
    local logfile="$LOG_DIR/arm_${arm}_${variant}.log"

    echo "=== START arm $arm ($variant): LATE_PERIOD=$late_period LATE_MAX_D=$late_max_d LATE_START=$late_start $(date -Is) ===" \
        | tee -a "$ORCH_LOG"

    # Post-#1138 merged stack envs.
    local base_envs=(
      NANOGPT_GRAD_CLIP_BODY=10.0
      NANOGPT_GRAD_CLIP_AUX=5.0
      NANOGPT_NS_ITERS=12
      NANOGPT_NS_ITERS_COOLDOWN=16
      NANOGPT_NS_COOLDOWN_START_FRAC=0.7
      NANOGPT_NS_COOLDOWN_SHAPE=late_peak
      NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
      NANOGPT_NS_STOCHASTIC_COOLDOWN=2
      NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
      NANOGPT_ADAMW_BETA2=0.99
      NANOGPT_ADAMW_EMBED_LR_MULT=1.5
      NANOGPT_MUON_ATTN_LR_MULT=0.80
      NANOGPT_MUON_MLP_LR_MULT=1.20
      NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
      NANOGPT_NEWTON_MUON=1
      NANOGPT_NEWTON_MUON_LR_SCALE=1.0
      NANOGPT_NEWTON_MUON_UPDATE_PERIOD=10
      NANOGPT_NEWTON_MUON_MAX_D_IN=1024
      NANOGPT_TRAIN_STEPS=3350
      SENPAI_SEED=0
    )

    # Per-arm late-window overrides (only set when not "0"/unset).
    local arm_envs=()
    if [[ "$late_period" != "0" ]]; then
        arm_envs+=("NANOGPT_NEWTON_MUON_LATE_PERIOD=$late_period")
    fi
    if [[ "$late_max_d" != "0" ]]; then
        arm_envs+=("NANOGPT_NEWTON_MUON_LATE_MAX_D_IN=$late_max_d")
    fi
    if [[ "$late_start" != "0" ]]; then
        arm_envs+=("NANOGPT_NEWTON_MUON_LATE_START_STEP=$late_start")
    fi

    env "${base_envs[@]}" "${arm_envs[@]}" \
      torchrun --standalone --nproc_per_node="$NPROC" \
        records/track_3_optimization/train_gpt_simple.py \
        --wandb_name "g1r4-fern/h4-late-window-nm-tune-arm${arm}-${variant}" \
        --wandb_group "g1r4-fern/h4-late-window-nm-tune" \
        > "$logfile" 2>&1

    local rc=$?
    echo "=== END arm $arm exit=$rc $(date -Is) ===" | tee -a "$ORCH_LOG"
    return $rc
}

# Arm A: ctrl (no LATE_* envs → all 3 args "0" sentinel → no late effect).
run_arm A 0    0    0    ctrl
# Arm B: LATE_PERIOD=5 only.
run_arm B 5    0    2400 late_period_5
# Arm C: LATE_MAX_D_IN=4096 only.
run_arm C 0    4096 2400 late_maxd_4096
# Arm D: compound (both).
run_arm D 5    4096 2400 late_compound

echo "=== H4 CHAIN COMPLETE $(date -Is) ===" | tee -a "$ORCH_LOG"
touch "$LOG_DIR/all_arms_done.flag"
