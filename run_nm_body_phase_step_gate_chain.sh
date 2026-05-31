#!/usr/bin/env bash
# PR #1914: NM body-phase step-gate ablation 3-arm sequential chain
# Arm A: ctrl (NM throughout 0-3350) — BURST_END_STEP=0 sentinel disables gate
# Arm B: body-NM-ablation (NM frozen 0-2345, ambient PERIOD=2 resumes step 2345-3350)
# Arm C: late-cooldown-only (NM frozen 0-2700, ambient PERIOD=2 resumes step 2700-3350)
# All arms SENPAI_SEED=0 for c645 boundary-pair paired causal isolation.

set -u
LOGS_DIR=logs_nm_body_phase_step_gate
mkdir -p "$LOGS_DIR"

run_arm() {
  local arm_name="$1"
  local burst_start="$2"
  local burst_end="$3"
  local burst_period="$4"
  local logfile="$LOGS_DIR/arm_${arm_name}.log"
  echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] Launching Arm ${arm_name} burst=[${burst_start},${burst_end}) period=${burst_period} ===" \
    | tee -a "$LOGS_DIR/chain.log"

  NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 NANOGPT_ADAMW_BETA2=0.99 \
  NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
  NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
  NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
  NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
  NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
  NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
  NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
  NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
  NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART=1 NANOGPT_NEWTON_MUON_R_ADAMW_WARMSTART_K=100 \
  NANOGPT_NEWTON_MUON_BURST_START_STEP="${burst_start}" \
  NANOGPT_NEWTON_MUON_BURST_END_STEP="${burst_end}" \
  NANOGPT_NEWTON_MUON_BURST_PERIOD="${burst_period}" \
  SENPAI_SEED=0 \
  torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py \
    --wandb_project modded-nanogpt-senpai \
    --wandb_entity wandb-applied-ai-team \
    --wandb_group "g1r4-askeladd/nm-body-phase-step-gate-ablation" \
    --wandb_name "${arm_name}" \
    > "$logfile" 2>&1
  local rc=$?
  echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] Arm ${arm_name} EXIT rc=${rc} ===" | tee -a "$LOGS_DIR/chain.log"
  return $rc
}

# Arm A — ctrl: burst gate OFF
run_arm "armA-ctrl-s0"                "0" "0"    "1"     || echo "Arm A FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"
# Arm B — body-NM-ablation: freeze R refresh 0-2345 (NM frozen in body)
run_arm "armB-body-ablation-s0"       "0" "2345" "99999" || echo "Arm B FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"
# Arm C — late-cooldown-only NM: freeze R refresh 0-2700 (NM frozen body + early cooldown)
run_arm "armC-late-cooldown-only-s0"  "0" "2700" "99999" || echo "Arm C FAILED, continuing chain" | tee -a "$LOGS_DIR/chain.log"

echo "=== [$(date -u +%Y-%m-%dT%H:%M:%SZ)] CHAIN COMPLETE ===" | tee -a "$LOGS_DIR/chain.log"
