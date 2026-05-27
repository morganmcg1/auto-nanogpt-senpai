#!/bin/bash
# H4 — Late-window NM coverage-only PP-PROMOTE protocol (PR #1286, cycle 363).
#
# Promotes Arm C (LATE_MAX_D_IN=4096 @ LATE_START_STEP=2400, period intentionally
# omitted since Arm B fenced period=5 NEG) to paired-pod n=3 confirmation.
#
# 6 runs interleaved s0-A → s0-C → s1-A → s1-C → s2-A → s2-C.
# Arm A_ctrl: no LATE_* envs (bit-identical fallback to post-#1138 baseline).
# Arm C_pp : LATE_MAX_D_IN=4096 + LATE_START_STEP=2400 (LATE_PERIOD omitted).
#
# W&B group: g1r4-fern/h4-late-coverage-pp
# Per-arm name: g1r4-fern/late-coverage-pp-s{seed}-{arm}
#
# Sequential 1xH100 wall ≈ 6×110min ≈ 11h.

set -u
cd "$(dirname "$0")"

LOG_DIR="h4_late_coverage_pp_logs"
mkdir -p "$LOG_DIR"
ORCH_LOG="$LOG_DIR/pp_orchestrator.log"
NPROC=$(nvidia-smi -L | wc -l)

log() { echo "[$(date -Is)] $*" | tee -a "$ORCH_LOG"; }

GROUP="g1r4-fern/h4-late-coverage-pp"
SCRIPT="records/track_3_optimization/train_gpt_simple.py"

log "=== H4 LATE-COVERAGE PP START NPROC=$NPROC ==="

run_pp() {
    local arm="$1"    # "A" or "C"
    local seed="$2"   # 0, 1, 2
    local logfile="$LOG_DIR/pp_arm_${arm}_seed_${seed}.log"
    local pidfile="$LOG_DIR/pp_arm_${arm}_seed_${seed}.pid"
    local name="g1r4-fern/late-coverage-pp-s${seed}-${arm}"

    log "==> arm=${arm} seed=${seed} START log=${logfile}"

    # Post-#1138 merged stack envs (identical across both arms).
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
      SENPAI_SEED=${seed}
    )

    # Per-arm late-window overrides.
    local arm_envs=()
    if [[ "$arm" == "C" ]]; then
        arm_envs+=(
          NANOGPT_NEWTON_MUON_LATE_MAX_D_IN=4096
          NANOGPT_NEWTON_MUON_LATE_START_STEP=2400
        )
        # LATE_PERIOD intentionally OMITTED (Arm B fenced period=5 NEG).
    fi

    env "${base_envs[@]}" "${arm_envs[@]}" \
      torchrun --standalone --nproc_per_node="$NPROC" "${SCRIPT}" \
        --wandb_name "${name}" \
        --wandb_group "${GROUP}" \
        > "${logfile}" 2>&1 &
    local pid=$!
    echo "${pid}" > "${pidfile}"
    log "    pid=${pid}"
    wait "${pid}"
    local rc=$?
    log "<== arm=${arm} seed=${seed} END rc=${rc}"
    return $rc
}

# Interleaved paired-pod order.
run_pp A 0 || log "arm A seed 0 failed but continuing"
run_pp C 0 || log "arm C seed 0 failed but continuing"
run_pp A 1 || log "arm A seed 1 failed but continuing"
run_pp C 1 || log "arm C seed 1 failed but continuing"
run_pp A 2 || log "arm A seed 2 failed but continuing"
run_pp C 2 || log "arm C seed 2 failed but continuing"

log "=== H4 LATE-COVERAGE PP COMPLETE ==="
touch "$LOG_DIR/pp_all_done.flag"
