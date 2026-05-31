#!/usr/bin/env bash
# PR #1914: NM body-phase step-gate ablation 3-arm bracket
# Arm A: ctrl (NM throughout 0-3350)
# Arm B: body-NM-ablation (NM enabled cooldown-only step 2345-3350)
# Arm C: late-cooldown-only (NM enabled step 2700-3350 only)
#
# All arms use SENPAI_SEED=0 for c645 boundary-pair paired causal isolation.

set -euo pipefail

ARM="${1:?usage: $0 {A|B|C}}"
LOG_DIR="${LOG_DIR:-logs_nm_body_phase_step_gate}"
mkdir -p "$LOG_DIR"

# Production stack (post-#1702 merge, locked)
export NANOGPT_NEWTON_MUON=1
export NANOGPT_NEWTON_MUON_LR_SCALE=1.0
export NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2
export NANOGPT_NEWTON_MUON_MAX_D_IN=4096
export NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005
export NANOGPT_NEWTON_MUON_BETA=0.95
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1
export NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_NS_STOCHASTIC_COOLDOWN=2
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5
export NANOGPT_MUON_ATTN_LR_MULT=0.80
export NANOGPT_MUON_MLP_LR_MULT=1.20
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
export NANOGPT_GRAD_CLIP_BODY=10.0
export NANOGPT_GRAD_CLIP_AUX=5.0
export SENPAI_SEED=0

case "$ARM" in
  A)
    # Arm A — ctrl: burst gate OFF (BURST_END_STEP=0 sentinel)
    export NANOGPT_NEWTON_MUON_BURST_START_STEP=0
    export NANOGPT_NEWTON_MUON_BURST_END_STEP=0
    export NANOGPT_NEWTON_MUON_BURST_PERIOD=1
    RUN_NAME="armA-ctrl-s0"
    ;;
  B)
    # Arm B — body-NM-ablation: burst window 0-2345 freezes R refresh
    export NANOGPT_NEWTON_MUON_BURST_START_STEP=0
    export NANOGPT_NEWTON_MUON_BURST_END_STEP=2345
    export NANOGPT_NEWTON_MUON_BURST_PERIOD=99999
    RUN_NAME="armB-body-ablation-s0"
    ;;
  C)
    # Arm C — late-cooldown-only NM: burst window 0-2700 freezes R refresh
    export NANOGPT_NEWTON_MUON_BURST_START_STEP=0
    export NANOGPT_NEWTON_MUON_BURST_END_STEP=2700
    export NANOGPT_NEWTON_MUON_BURST_PERIOD=99999
    RUN_NAME="armC-late-cooldown-only-s0"
    ;;
  *)
    echo "Unknown arm: $ARM (expected A, B, or C)" >&2
    exit 1
    ;;
esac

LOG_FILE="$LOG_DIR/${RUN_NAME}.log"
echo "=== Launching $RUN_NAME -> $LOG_FILE ===" | tee -a "$LOG_FILE"
echo "BURST_START_STEP=$NANOGPT_NEWTON_MUON_BURST_START_STEP" | tee -a "$LOG_FILE"
echo "BURST_END_STEP=$NANOGPT_NEWTON_MUON_BURST_END_STEP" | tee -a "$LOG_FILE"
echo "BURST_PERIOD=$NANOGPT_NEWTON_MUON_BURST_PERIOD" | tee -a "$LOG_FILE"

NPROC=$(nvidia-smi -L | wc -l)
torchrun --standalone --nproc_per_node="$NPROC" \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_project modded-nanogpt-senpai \
  --wandb_entity wandb-applied-ai-team \
  --wandb_name "g1r4-askeladd/${RUN_NAME}" \
  --wandb_group "g1r4-askeladd/nm-body-phase-step-gate-ablation" \
  2>&1 | tee -a "$LOG_FILE"
