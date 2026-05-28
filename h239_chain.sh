#!/bin/bash
# H239 sequential chain: Schedule-Free AdamW on aux side.
# arm_a CTRL  adamw            (bit-identical baseline; step-0 val=10.82583 EXACT)
# arm_b SF_LR_03  sf_adamw lr=0.3   (constant LR = current aux peak, no schedule)
# arm_c SF_LR_015 sf_adamw lr=0.15  (half-peak constant LR, no schedule)
# All preserve betas=(0.8, 0.99), eps=1e-6, weight_decay=0.

set -e
mkdir -p logs/h239

wait_for_arm() {
    local logfile="$1"
    local label="$2"
    echo "[H239 CHAIN] waiting for ${label} via ${logfile}..."
    while true; do
        if [ -f "${logfile}" ]; then
            if grep -qE "step:3325/3325 val_loss|peak memory|Traceback \(most recent|CUDA out of memory|RuntimeError" "${logfile}"; then
                echo "[H239 CHAIN] ${label} terminal marker detected at $(date -u +%FT%TZ)"
                sleep 30
                return 0
            fi
        fi
        sleep 30
    done
}

echo "[H239 CHAIN] launching arm_a CTRL (aux_optimizer=adamw, bit-id) at $(date -u +%FT%TZ)..."
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
  --aux_optimizer adamw \
  --wandb_name "g1r3-askeladd/H239-arm_a-CTRL" \
  --wandb_group "H239" \
  > logs/h239/arm_a.log 2>&1 &
ARM_A_PID=$!
echo "[H239 CHAIN] arm_a PID=${ARM_A_PID}"

wait_for_arm "logs/h239/arm_a.log" "arm_a"

echo "[H239 CHAIN] launching arm_b SF_LR_03 (aux_optimizer=sf_adamw, aux_sf_lr=0.3) at $(date -u +%FT%TZ)..."
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
  --aux_optimizer sf_adamw --aux_sf_lr 0.3 \
  --wandb_name "g1r3-askeladd/H239-arm_b-SF_LR_03" \
  --wandb_group "H239" \
  > logs/h239/arm_b.log 2>&1 &
ARM_B_PID=$!
echo "[H239 CHAIN] arm_b PID=${ARM_B_PID}"

wait_for_arm "logs/h239/arm_b.log" "arm_b"

echo "[H239 CHAIN] launching arm_c SF_LR_015 (aux_optimizer=sf_adamw, aux_sf_lr=0.15) at $(date -u +%FT%TZ)..."
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
  --aux_optimizer sf_adamw --aux_sf_lr 0.15 \
  --wandb_name "g1r3-askeladd/H239-arm_c-SF_LR_015" \
  --wandb_group "H239" \
  > logs/h239/arm_c.log 2>&1 &
ARM_C_PID=$!
echo "[H239 CHAIN] arm_c PID=${ARM_C_PID}"

wait_for_arm "logs/h239/arm_c.log" "arm_c"

echo "[H239 CHAIN] all 3 arms complete at $(date -u +%FT%TZ)"
