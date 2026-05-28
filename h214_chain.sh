#!/bin/bash
# H214 sequential chain: pre-NS5 body spectral truncation.
# arm_a CTRL (keep=1.0)  bit-identical to H203 cosine baseline (expected FFS=3025)
# arm_b TRUNC_HALF (keep=0.5)
# arm_c TRUNC_TOP25 (keep=0.25)

set -e
mkdir -p logs/h214

wait_for_arm() {
    local logfile="$1"
    local label="$2"
    echo "[H214 CHAIN] waiting for ${label} via ${logfile}..."
    while true; do
        if [ -f "${logfile}" ]; then
            if grep -qE "step:3325/3325 val_loss|peak memory|Traceback \(most recent|CUDA out of memory|RuntimeError" "${logfile}"; then
                echo "[H214 CHAIN] ${label} terminal marker detected at $(date -u +%FT%TZ)"
                sleep 30
                return 0
            fi
        fi
        sleep 30
    done
}

echo "[H214 CHAIN] launching arm_a CTRL (keep_frac=1.0, bit-identical) at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-6 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --body_spectral_truncate 1.0 \
  --wandb_name "g1r3-askeladd/h214-arm_a-ctrl" \
  --wandb_group "H214" \
  > logs/h214/arm_a.log 2>&1 &
ARM_A_PID=$!
echo "[H214 CHAIN] arm_a PID=${ARM_A_PID}"

wait_for_arm "logs/h214/arm_a.log" "arm_a"

echo "[H214 CHAIN] launching arm_b TRUNC_HALF (keep_frac=0.5) at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-6 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --body_spectral_truncate 0.5 \
  --wandb_name "g1r3-askeladd/h214-arm_b-trunc-half" \
  --wandb_group "H214" \
  > logs/h214/arm_b.log 2>&1 &
ARM_B_PID=$!
echo "[H214 CHAIN] arm_b PID=${ARM_B_PID}"

wait_for_arm "logs/h214/arm_b.log" "arm_b"

echo "[H214 CHAIN] launching arm_c TRUNC_TOP25 (keep_frac=0.25) at $(date -u +%FT%TZ)..."
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-6 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --body_spectral_truncate 0.25 \
  --wandb_name "g1r3-askeladd/h214-arm_c-trunc-top25" \
  --wandb_group "H214" \
  > logs/h214/arm_c.log 2>&1 &
ARM_C_PID=$!
echo "[H214 CHAIN] arm_c PID=${ARM_C_PID}"

wait_for_arm "logs/h214/arm_c.log" "arm_c"

echo "[H214 CHAIN] all 3 arms complete at $(date -u +%FT%TZ)"
