#!/bin/bash
# H333 chain: AUX β2 cooldown_ramp DOWN-from-baseline=0.99 dose-response.
# 3-arm Pattern A drift-FREE bit-id chain.
#   arm_a CTRL              : β2=0.99 constant (bit-identical baseline)
#   arm_b DOWN_MILD         : β2 0.99→0.98 (cooldown_ramp, aux_cooldown_frac=0.4 → ramps over steps [1995, 3325])
#   arm_c DOWN_AGGRESSIVE   : β2 0.99→0.97 (cooldown_ramp, aux_cooldown_frac=0.4 → ramps over steps [1995, 3325])
# Uses EXISTING cooldown_ramp schedule (no code changes). Mechanism-distinct from H325
# mid_training_ramp (which ramped over [0, 1995] then held).
# Sequential on 1 GPU, ~1h 50m per arm × 3 ≈ 5h 30m.

set -u
cd /workspace/senpai/target

mkdir -p logs_h333
LOG=/workspace/senpai/target/logs_h333_chain.log

declare -A SCHEDULE=(
  [arm_a_CTRL]="constant"
  [arm_b_DOWN_MILD]="cooldown_ramp"
  [arm_c_DOWN_AGGRESSIVE]="cooldown_ramp"
)

declare -A BETA2_END=(
  [arm_a_CTRL]=0.99
  [arm_b_DOWN_MILD]=0.98
  [arm_c_DOWN_AGGRESSIVE]=0.97
)

COMMON=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --polyak_ema_decay 0.05
  --wandb_project modded-nanogpt-senpai
  --wandb_group h333_aux_beta2_cooldown_ramp_down
)

for ARM in arm_a_CTRL arm_b_DOWN_MILD arm_c_DOWN_AGGRESSIVE; do
  SCHED=${SCHEDULE[$ARM]}
  B2END=${BETA2_END[$ARM]}
  ARM_LOG="logs_h333/${ARM}.log"
  echo "===== H333 $ARM (sched=$SCHED β2_end=$B2END) launched at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON[@]}" \
    --aux_beta2_schedule "$SCHED" --aux_beta2_end "$B2END" \
    --wandb_name "g1r3-frieren/H333_${ARM}" 2>&1 | tee -a "$LOG" "/workspace/senpai/target/${ARM_LOG}"
  echo "===== H333 $ARM finished at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
done

echo "===== H333 chain complete at $(date -u +%Y-%m-%dT%H:%M:%SZ) =====" | tee -a "$LOG"
