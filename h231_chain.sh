#!/bin/bash
# H231 sequential chain: MuonH mode axis (post-step projection ablation).
# arm_a CTRL  --muonh_mode scale_invariant (current baseline, bit-identical path)
# arm_b CLIP_MODE  --muonh_mode clip (soft late-only projection, budget_mult=1.0)
# arm_c CLIP_LOOSE --muonh_mode clip --muonh_budget_mult 2.0 (very loose ball)
#
# Per PR #1511: zero code changes. Both modes already exist in argparse. Pure
# mechanism flip on existing infrastructure. ~108 min/arm, ~5.4h total.

set -e
mkdir -p logs/h231

wait_for_arm() {
    local logfile="$1"
    local label="$2"
    echo "[H231 CHAIN] waiting for ${label} via ${logfile}..."
    while true; do
        if [ -f "${logfile}" ]; then
            if grep -qE "step:3325/3325 val_loss|peak memory|Traceback \(most recent|CUDA out of memory|RuntimeError" "${logfile}"; then
                echo "[H231 CHAIN] ${label} terminal marker detected at $(date -u +%FT%TZ)"
                sleep 30
                return 0
            fi
        fi
        sleep 30
    done
}

echo "[H231 CHAIN] launching arm_a CTRL (--muonh_mode scale_invariant) bit-identical at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai \
  --wandb_name "g1r3-askeladd/H231_arm_a_CTRL_scale_invariant" \
  --wandb_group "H231" \
  > logs/h231/arm_a.log 2>&1 &
ARM_A_PID=$!
echo "[H231 CHAIN] arm_a PID=${ARM_A_PID}"

wait_for_arm "logs/h231/arm_a.log" "arm_a"

echo "[H231 CHAIN] launching arm_b CLIP_MODE (--muonh_mode clip, budget_mult=1.0) at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode clip \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai \
  --wandb_name "g1r3-askeladd/H231_arm_b_CLIP_MODE" \
  --wandb_group "H231" \
  > logs/h231/arm_b.log 2>&1 &
ARM_B_PID=$!
echo "[H231 CHAIN] arm_b PID=${ARM_B_PID}"

wait_for_arm "logs/h231/arm_b.log" "arm_b"

echo "[H231 CHAIN] launching arm_c CLIP_LOOSE (--muonh_mode clip --muonh_budget_mult 2.0) at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode clip \
  --muonh_budget_mult 2.0 \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --wandb_project modded-nanogpt-senpai \
  --wandb_name "g1r3-askeladd/H231_arm_c_CLIP_LOOSE" \
  --wandb_group "H231" \
  > logs/h231/arm_c.log 2>&1 &
ARM_C_PID=$!
echo "[H231 CHAIN] arm_c PID=${ARM_C_PID}"

wait_for_arm "logs/h231/arm_c.log" "arm_c"

echo "[H231 CHAIN] ALL ARMS COMPLETE at $(date -u +%FT%TZ)"
