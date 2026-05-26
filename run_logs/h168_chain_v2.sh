#!/bin/bash
# H168 chain v2 launcher (cycle ~290 advisor-approved patch): arm_b_v2 then arm_c_v2.
# Re-runs AdaBelief arms with --aux_adabelief_eps 1e-16 (paper transformer default).
# arm_a CTRL (9kox3eg1, val_loss 3.26733) is already done; no re-run.
# Sequential runs on a single GPU.
set -uo pipefail
cd /workspace/senpai/target

LOGROOT="run_logs/h168_chain_v2"
mkdir -p "$LOGROOT"

COMMON_ARGS=(
  --num_trials 1 --train_steps 3325
  --muonh_mode scale_invariant
  --muonh_cooldown_shape linear
  --muonh_warmup_steps 100
  --use_outer_optimizer 1
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30
  --aux_agc_clip_ratio 0.05
  --muonh_agc_clip_ratio 0.05
  --aux_adamw_eps 1e-6
  --aux_beta2_schedule constant --aux_beta2_start 0.99
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90
  --body_init orthogonal_fnorm_matched
  --aux_adabelief_eps 1e-16
  --wandb_group g1r3-fern-h168-adabelief-aux
)

run_arm() {
  local arm_name="$1"; shift
  local arm_logfile="$LOGROOT/${arm_name}.log"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] START $arm_name" | tee -a "$LOGROOT/chain.log"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] CMD: torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py ${COMMON_ARGS[*]} $*" | tee -a "$LOGROOT/chain.log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    "${COMMON_ARGS[@]}" "$@" \
    > "$arm_logfile" 2>&1
  local rc=$?
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] END   $arm_name rc=$rc" | tee -a "$LOGROOT/chain.log"
  return $rc
}

# arm_b_v2 ADABELIEF_LM_HEAD (eps=1e-16): AdaBelief on proj.weight.
run_arm "arm_b_v2-adabelief-lm_head-eps1e16" \
  --use_adabelief 1 --adabelief_target lm_head_only \
  --wandb_name "g1r3-fern/h168-arm_b_v2-adabelief-lm_head-eps1e16"

# arm_c_v2 ADABELIEF_EMBED (eps=1e-16): AdaBelief on embed.weight.
run_arm "arm_c_v2-adabelief-embed-eps1e16" \
  --use_adabelief 1 --adabelief_target embed_only \
  --wandb_name "g1r3-fern/h168-arm_c_v2-adabelief-embed-eps1e16"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] CHAIN COMPLETE" | tee -a "$LOGROOT/chain.log"
