#!/bin/bash
# H253 askeladd: True Stiefel body initialization (orthogonal_qr, orthogonal_qr_mean_fnorm)
# Sequential chain of 3 arms. Logs to logs/h253/.
set -u

LOGDIR=logs/h253
mkdir -p "$LOGDIR"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --wandb_project modded-nanogpt-senpai
  --wandb_group H253_body_init_qr_stiefel
)
# NOTE: PR command listed --embed_init_std 1.0 but no such argparse flag exists
# in this branch (verified via grep + git log). Default torch nn.Embedding init is
# normal_(std=1.0), and the script uses w.normal_() for embed.weight (= std=1.0),
# so omitting the flag is identical to the intended setting. Logged for advisor
# in the chain-launch PR comment.

echo "=== H253 arm_a CTRL (orthogonal_fnorm_matched bit-identity) ==="
date -Iseconds
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --body_init orthogonal_fnorm_matched \
  --wandb_name "g1r3-askeladd/H253_arm_a_CTRL_fnorm_matched" \
  "${COMMON_ARGS[@]}" \
  2>&1 | tee "$LOGDIR/arm_a_ctrl.log"
echo "=== arm_a exit=$? ==="
date -Iseconds

echo "=== H253 arm_b QR_RAW (true Stiefel, no F-norm rescaling) ==="
date -Iseconds
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --body_init orthogonal_qr \
  --wandb_name "g1r3-askeladd/H253_arm_b_QR_RAW" \
  "${COMMON_ARGS[@]}" \
  2>&1 | tee "$LOGDIR/arm_b_qr_raw.log"
echo "=== arm_b exit=$? ==="
date -Iseconds

echo "=== H253 arm_c QR_MEAN (true Stiefel + global mean-F-norm scaling) ==="
date -Iseconds
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --body_init orthogonal_qr_mean_fnorm \
  --wandb_name "g1r3-askeladd/H253_arm_c_QR_MEAN" \
  "${COMMON_ARGS[@]}" \
  2>&1 | tee "$LOGDIR/arm_c_qr_mean.log"
echo "=== arm_c exit=$? ==="
date -Iseconds

echo "=== H253 chain complete ==="
