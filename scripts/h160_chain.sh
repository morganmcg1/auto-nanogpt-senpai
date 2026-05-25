#!/usr/bin/env bash
# H160 aux AdamW eps schedule: arm_a CTRL constant 1e-6, arm_b LINEAR 1e-6→1e-4,
# arm_c COOLDOWN_LINEAR 1e-6→1e-4 (cooldown-confined). Sequential chain, 1 GPU
# per arm, ~1.75h each (~5.3h total). Bit-id with H148 baseline at arm_a constant.
set -u
cd "$(dirname "$0")/.."

mkdir -p logs_h160

base_cmd=(
  torchrun --standalone --nproc_per_node=1
  records/track_3_optimization/train_gpt_simple.py
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape linear
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
)

run_arm() {
  local arm_label="$1"; shift
  local wandb_name="$1"; shift
  local logfile="logs_h160/${arm_label}.log"
  echo "==========================================" | tee -a "$logfile"
  echo "[H160] Starting ${arm_label} ($wandb_name) at $(date -u +%FT%TZ)" | tee -a "$logfile"
  echo "[H160] Args: $*" | tee -a "$logfile"
  echo "==========================================" | tee -a "$logfile"
  "${base_cmd[@]}" "$@" \
    --wandb_project modded-nanogpt-senpai \
    --wandb_group "g1r3-alphonse-h160-aux-eps-schedule" \
    --wandb_name "g1r3-alphonse/${wandb_name}" \
    >> "$logfile" 2>&1
  local rc=$?
  echo "[H160] ${arm_label} finished rc=${rc} at $(date -u +%FT%TZ)" | tee -a "$logfile"
  return $rc
}

# arm_a CTRL: bit-id baseline (constant eps=1e-6, fused=True)
run_arm arm_a H160_arm_a_ctrl_const_1e-6 \
  --aux_adamw_eps 1e-6 --aux_adamw_eps_schedule constant --aux_adamw_eps_end 1e-6 \
  || { echo "arm_a FAILED" | tee -a logs_h160/chain.log; exit 1; }

sleep 30

# arm_b LINEAR: full-trajectory eps ramp 1e-6 → 1e-4 (fused=False)
run_arm arm_b H160_arm_b_linear_1e-6_to_1e-4 \
  --aux_adamw_eps 1e-6 --aux_adamw_eps_schedule linear --aux_adamw_eps_end 1e-4 \
  || { echo "arm_b FAILED" | tee -a logs_h160/chain.log; exit 1; }

sleep 30

# arm_c COOLDOWN_LINEAR: cooldown-confined eps ramp 1e-6 → 1e-4 (fused=False)
run_arm arm_c H160_arm_c_cooldown_linear_1e-6_to_1e-4 \
  --aux_adamw_eps 1e-6 --aux_adamw_eps_schedule cooldown_linear --aux_adamw_eps_end 1e-4 \
  || { echo "arm_c FAILED" | tee -a logs_h160/chain.log; exit 1; }

echo "[H160] All arms finished at $(date -u +%FT%TZ)" | tee -a logs_h160/chain.log
