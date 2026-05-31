#!/usr/bin/env bash
set -euo pipefail
# H336 smoke gate (125-step runs, two independent runs at most-aggressive
# interior point arm_c η=0.3 β=0.5):
#   pass criteria: step-0 val=10.82583 EXACT on BOTH (bit-id with H266)
#                  + finite step-125 + bounded anchor_drift_rms at outer-step 4
ARM="${1:-c1}"
case "$ARM" in
  a)  BETA=0.0; ETA=1.0; NAME="g1r3-edward/H336_smoke_arm_a_CTRL";        LOG="runlogs/h336/smoke_arm_a.log";;
  c1) BETA=0.5; ETA=0.3; NAME="g1r3-edward/H336_smoke_arm_c_BRAKE_HEAVY_run1"; LOG="runlogs/h336/smoke_arm_c_run1.log";;
  c2) BETA=0.5; ETA=0.3; NAME="g1r3-edward/H336_smoke_arm_c_BRAKE_HEAVY_run2"; LOG="runlogs/h336/smoke_arm_c_run2.log";;
  *)  echo "usage: $0 {a|c1|c2}" >&2; exit 2;;
esac
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --outer_anchor_momentum "$BETA" --outer_anchor_lr "$ETA" \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H336_outer_anchor_brake_interior_smoke" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
