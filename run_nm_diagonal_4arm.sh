#!/usr/bin/env bash
# PR #1363 — NM diagonal-only vs full-R structural ablation.
# Sequential 4-arm chain: A(full,UP5) -> B(diag,UP5) -> C(diag,UP1) -> D(diag,UP3).
set -u
cd /workspace/senpai/target

LOG_DIR="logs_nm_diagonal_4arm"
mkdir -p "$LOG_DIR"

run_arm() {
    local arm_name="$1"
    local nm_diag="$2"
    local up_period="$3"
    local wandb_name="$4"
    local logfile="$LOG_DIR/${arm_name}.log"
    echo "===== $(date -u +%FT%TZ) START $arm_name (DIAG=$nm_diag UP=$up_period) =====" | tee -a "$logfile"
    NANOGPT_GRAD_CLIP=10.0 NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
    NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_ADAMW_BETA2=0.99 \
    NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
    NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
    NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_LR_SCALE=1.0 \
    NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
    NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-8 \
    NANOGPT_NEWTON_MUON_DIAGONAL="$nm_diag" \
    NANOGPT_NEWTON_MUON_UPDATE_PERIOD="$up_period" \
    SENPAI_SEED=0 NANOGPT_TRAIN_STEPS=3350 \
    torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
      --wandb_group "g1r4-nezuko/nm-diagonal-ablation" \
      --wandb_name "$wandb_name" >>"$logfile" 2>&1
    local rc=$?
    echo "===== $(date -u +%FT%TZ) END $arm_name rc=$rc =====" | tee -a "$logfile"
    return $rc
}

run_arm "armA-ctrl-full-up5"   0 5 "g1r4-nezuko-diag-armA-ctrl"
run_arm "armB-diag-up5"        1 5 "g1r4-nezuko-diag-armB-diag-up5"
run_arm "armC-diag-up1"        1 1 "g1r4-nezuko-diag-armC-diag-up1"
run_arm "armD-diag-up3"        1 3 "g1r4-nezuko-diag-armD-diag-up3"

echo "===== $(date -u +%FT%TZ) CHAIN COMPLETE ====="
