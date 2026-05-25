#!/bin/bash
# H142 chain launcher: arm_a (wd=0.0) -> arm_b (wd=1e-4) -> arm_c (wd=1e-3).
# Runs sequentially on the single GPU; sleeps 30s between arms to allow GPU
# state to settle (cf. nezuko H137 cycle 221 idle-gap incident).
set -e

cd /workspace/senpai/target

GROUP="g1r3-tanjiro-h142-embed-wd-sweep"
COMMON_FLAGS=(
  --num_trials 1
  --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape cosine
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7
  --outer_momentum 0.5
  --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant
  --aux_beta2_start 0.99
  --muonh_mu_schedule linear
  --muonh_mu_start 0.95
  --muonh_mu_end 0.90
)

run_arm() {
  local name="$1" wd="$2" logfile="$3"
  echo "[$(date -u +%FT%TZ)] launching ${name} (--embed_wd ${wd})" | tee -a "$logfile"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_FLAGS[@]}" \
    --embed_wd "$wd" \
    --wandb_name "g1r3-tanjiro/${name}" \
    --wandb_group "$GROUP" \
    >> "$logfile" 2>&1
  echo "[$(date -u +%FT%TZ)] ${name} done" | tee -a "$logfile"
}

run_arm h142_arm_a_wd0       0.0  logs_h142/arm_a.log
sleep 30
run_arm h142_arm_b_wd1e-4    1e-4 logs_h142/arm_b.log
sleep 30
run_arm h142_arm_c_wd1e-3    1e-3 logs_h142/arm_c.log

echo "[$(date -u +%FT%TZ)] H142 chain complete" | tee -a logs_h142/chain.log
