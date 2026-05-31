#!/usr/bin/env bash
set -euo pipefail
# H344 smoke gate (125-step runs at most-aggressive interior arm_b k=5 α=0.5):
#   Two independent runs verifying step-0 val=10.82583 EXACT (bit-id) +
#   bounded aux_lookahead_slow_drift_rms.
#
# Usage: H344_smoke.sh {1|2}
RUN="${1:-}"
if [ -z "$RUN" ]; then echo "usage: $0 1|2" >&2; exit 2; fi
case "$RUN" in
  1) NAME="g1r3-edward/H344_smoke_arm_b_k5_run1"; LOG="runlogs/h344/smoke_run1.log";;
  2) NAME="g1r3-edward/H344_smoke_arm_b_k5_run2"; LOG="runlogs/h344/smoke_run2.log";;
  *) echo "usage: $0 {1|2}" >&2; exit 2;;
esac
cd /workspace/senpai/target
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 125 \
  --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05 \
  --aux_lookahead_k 5 --aux_lookahead_alpha 0.5 \
  --wandb_project modded-nanogpt-senpai \
  --wandb_group "H344_aux_lookahead_smoke" \
  --wandb_name "$NAME" 2>&1 | tee "$LOG"
