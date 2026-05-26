#!/usr/bin/env bash
# H165 chain launcher: MGUP-on-AdamW-aux per-row (cross-family test of H155 cos(m,g) finding).
# Each arm has its OWN explicit --use_mgup_aux / --mgup_aux_k / --mgup_aux_alpha / --mgup_aux_beta.
# (Mirrors askeladd H155 PR #1187 arm structure.)
#
# Baseline: jg6p3l50 (H148 winner) val/loss=3.26364 ffs=3125 at train_steps=3325.
# WIN threshold (1.8sigma below baseline): val/loss < 3.26284
# CTRL noise envelope: mean ~3.26466, std ~0.001, range 0.00219
#
# arm_a CTRL          : use_mgup_aux=0                                  -> bit-id baseline
# arm_b MGUP_50_MOD   : use_mgup_aux=1 k=0.5  alpha=0.5  beta=0.5       -> mirrors askeladd arm_b
# arm_c MGUP_25_AGG   : use_mgup_aux=1 k=0.25 alpha=1.0  beta=0.75      -> mirrors askeladd arm_c
set -uo pipefail
cd /workspace/senpai/target

WANDB_GROUP="g1r3-frieren-h165-mgup-aux-adamw"

run_arm() {
    local arm_name="$1"
    shift
    echo "===== [$(date -u +%FT%TZ)] LAUNCHING ${arm_name} ====="
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 --train_steps 3325 \
        --muonh_mode scale_invariant --muonh_cooldown_shape linear --muonh_warmup_steps 100 \
        --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
        --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
        --aux_adamw_eps 1e-6 \
        --aux_beta2_schedule constant --aux_beta2_start 0.99 \
        --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
        --body_init orthogonal_fnorm_matched \
        "$@" \
        --wandb_group "${WANDB_GROUP}" \
        --wandb_name "g1r3-frieren/h165-${arm_name}" \
        2>&1 | tee "logs_h165/${arm_name}.log"
    local rc=${PIPESTATUS[0]}
    echo "===== [$(date -u +%FT%TZ)] ${arm_name} EXIT rc=${rc} ====="
    return $rc
}

# arm_a CTRL: bit-id baseline (use_mgup_aux=0, MGUP knobs are no-ops but set
# explicitly anyway so the per-arm overrides are unambiguous).
run_arm arm_a-ctrl \
  --use_mgup_aux 0 --mgup_aux_k 0.5 --mgup_aux_alpha 0.5 --mgup_aux_beta 0.5

sleep 30

# arm_b MGUP_50_MOD: k=0.5, alpha=0.5, beta=0.5 (moderate, mean-preserving on average).
run_arm arm_b-mgup-50-moderate \
  --use_mgup_aux 1 --mgup_aux_k 0.5 --mgup_aux_alpha 0.5 --mgup_aux_beta 0.5

sleep 30

# arm_c MGUP_25_AGG: k=0.25, alpha=1.0, beta=0.75 (aggressive, asymmetric focus on top-25%).
run_arm arm_c-mgup-25-aggressive \
  --use_mgup_aux 1 --mgup_aux_k 0.25 --mgup_aux_alpha 1.0 --mgup_aux_beta 0.75

echo "===== [$(date -u +%FT%TZ)] CHAIN COMPLETE ====="
