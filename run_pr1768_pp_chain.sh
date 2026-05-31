#!/usr/bin/env bash
# PR #1768 class 31 NM-NS-ITERS-COOLDOWN-INTENSITY — PP-confirm n=3 chain.
# Per c624 advisor send-back: 6-run interleaved pair-by-pair chain validating
# Arm C NS_ITERS_COOLDOWN=20 single-seed mild-FAV (Δ_CA=-0.00116).
#
# Pair order (matches c618/c621 PP-confirm protocol exactly):
#   1. PP-ctrl-s0 (seed=0, NS_ITERS_COOLDOWN=16) — Arm A bit-identical reproduce
#   1. PP-exp-s0  (seed=0, NS_ITERS_COOLDOWN=20) — Arm C bit-identical reproduce
#   2. PP-ctrl-s1 (seed=1, NS_ITERS_COOLDOWN=16) — fresh seed
#   2. PP-exp-s1  (seed=1, NS_ITERS_COOLDOWN=20) — fresh seed
#   3. PP-ctrl-s2 (seed=2, NS_ITERS_COOLDOWN=16) — fresh seed
#   3. PP-exp-s2  (seed=2, NS_ITERS_COOLDOWN=20) — fresh seed
#
# All other env-vars are the Arm A/C production stack from PR #1768 body
# (post-#1543 stack including Tikhonov γ=0.005). Group:
# g1r4-fern/nm-ns-iters-cooldown-pp-confirm.
set -uo pipefail
cd "$(dirname "$0")"

LOGDIR="/workspace/senpai/target/nm_ns_iters_cooldown_pp_logs"
mkdir -p "$LOGDIR"

run_pair_arm() {
    local seed="$1"
    local arm_label="$2"          # "ctrl" or "exp"
    local ns_cooldown="$3"        # 16 (ctrl) or 20 (exp)
    local short_name="pair${seed}-pp-${arm_label}-s${seed}-ns${ns_cooldown}"
    local wandb_name="g1r4-fern/pp-${arm_label}-s${seed}-ns${ns_cooldown}"
    local logf="$LOGDIR/${short_name}.log"
    echo "[$(date -Iseconds)] START $short_name SENPAI_SEED=$seed NS_ITERS_COOLDOWN=$ns_cooldown wandb=$wandb_name" \
        | tee -a "$LOGDIR/orchestrator.log"
    SENPAI_SEED="$seed" \
    NANOGPT_NEWTON_MUON=1 \
    NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 \
    NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
    NANOGPT_NEWTON_MUON_BETA=0.95 \
    NANOGPT_NEWTON_MUON_EPS=1e-4 \
    NANOGPT_NEWTON_MUON_TIKHONOV_GAMMA=0.005 \
    NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 \
    NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN="$ns_cooldown" NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --num_trials 1 \
      --wandb_group "g1r4-fern/nm-ns-iters-cooldown-pp-confirm" \
      --wandb_name "$wandb_name" \
      > "$logf" 2>&1
    local rc=$?
    echo "[$(date -Iseconds)] END   $short_name rc=$rc" | tee -a "$LOGDIR/orchestrator.log"
    return $rc
}

CHAIN_LOG="$LOGDIR/chain.log"
echo "[$(date -Iseconds)] ===== START PR1768 PP-confirm chain =====" >> "$CHAIN_LOG"

run_pair_arm 0 ctrl 16 || { echo "pair-0 ctrl-s0 failed" | tee -a "$CHAIN_LOG"; exit 1; }
run_pair_arm 0 exp  20 || { echo "pair-0 exp-s0  failed" | tee -a "$CHAIN_LOG"; exit 1; }
run_pair_arm 1 ctrl 16 || { echo "pair-1 ctrl-s1 failed" | tee -a "$CHAIN_LOG"; exit 1; }
run_pair_arm 1 exp  20 || { echo "pair-1 exp-s1  failed" | tee -a "$CHAIN_LOG"; exit 1; }
run_pair_arm 2 ctrl 16 || { echo "pair-2 ctrl-s2 failed" | tee -a "$CHAIN_LOG"; exit 1; }
run_pair_arm 2 exp  20 || { echo "pair-2 exp-s2  failed" | tee -a "$CHAIN_LOG"; exit 1; }

echo "[$(date -Iseconds)] ===== END PR1768 PP-confirm chain ALL 6 ARMS DONE =====" | tee -a "$CHAIN_LOG"
