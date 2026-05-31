#!/usr/bin/env bash
# PR #1965: NM R-buffer cooldown-phase FREEZE 3-arm sequential chain (single-seed SENPAI_SEED=0)
# Arm A: ctrl (NM throughout 0-3350) — BURST_END_STEP=0 sentinel disables gate
# Arm B: full cooldown FREEZE — BURST[2345, 3350) PERIOD=99999 (R-buffer frozen entire cooldown)
# Arm C: late-cooldown FREEZE — BURST[2700, 3350) PERIOD=99999 (R-buffer frozen last 650 cooldown steps)
# Production env block copied VERBATIM from #1918 Arm A HB-FINAL reproduce.

set -u
LOGS_DIR=logs_nm_r_buffer_cooldown_freeze
mkdir -p "$LOGS_DIR"

run_arm() {
  local run_name="$1"
  local burst_start="$2"
  local burst_end="$3"
  local burst_period="$4"
  local logfile="$LOGS_DIR/${run_name}.log"
  echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] Launching ${run_name} burst=[${burst_start},${burst_end}) period=${burst_period} ===" \
    | tee -a "$LOGS_DIR/chain.log"

  SENPAI_SEED=0 \
  NANOGPT_NEWTON_MUON=1 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
  NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_BETA=0.95 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_BURST_START_STEP="${burst_start}" \
  NANOGPT_NEWTON_MUON_BURST_END_STEP="${burst_end}" \
  NANOGPT_NEWTON_MUON_BURST_PERIOD="${burst_period}" \
  NANOGPT_NS_ITERS=12 \
  NANOGPT_NS_ITERS_COOLDOWN=16 \
  NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
  NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
  NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 \
  NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
  NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_GRAD_CLIP_BODY=10.0 \
  NANOGPT_GRAD_CLIP_AUX=5.0 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --wandb_project modded-nanogpt-senpai \
    --wandb_entity wandb-applied-ai-team \
    --wandb_group "g1r4-alphonse-nm-r-buffer-cooldown-freeze-bracket" \
    --wandb_name "g1r4-alphonse/${run_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] ${run_name} EXIT rc=${rc} ===" | tee -a "$LOGS_DIR/chain.log"
  return $rc
}

# Arm A — ctrl: burst gate OFF (BURST_END_STEP=0 sentinel)
run_arm "armA-ctrl-no-burst-s0"                                "0"    "0"    "1"     \
  || echo "Arm A FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"

# Arm B — full cooldown FREEZE: BURST[2345, 3350) PERIOD=99999
run_arm "armB-cooldown-freeze-burst2345-3350-period99999-s0"   "2345" "3350" "99999" \
  || echo "Arm B FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"

# Arm C — late-cooldown FREEZE: BURST[2700, 3350) PERIOD=99999
run_arm "armC-late-cooldown-freeze-burst2700-3350-period99999-s0" "2700" "3350" "99999" \
  || echo "Arm C FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"

echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] CHAIN COMPLETE ===" | tee -a "$LOGS_DIR/chain.log"
