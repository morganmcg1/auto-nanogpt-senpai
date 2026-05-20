#!/bin/bash
# Embed LR step-0 boost 4-arm sweep for PR #526.
# Chains A -> B -> C -> D sequentially on a single GPU.
#
# Shared envs match the post-#393 merged stack documented in the PR body.
# Arms vary NANOGPT_EMBED_LR_BOOST_MULT and NANOGPT_EMBED_LR_BOOST_FRAC only.
set -uo pipefail

cd "$(dirname "$0")"

export NANOGPT_GRAD_CLIP=10.0
export NANOGPT_NS_ITERS=12
export NANOGPT_NS_ITERS_COOLDOWN=16
export NANOGPT_NS_COOLDOWN_START_FRAC=0.7
export NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
export NANOGPT_ADAMW_BETA2=0.99
export NANOGPT_NS_COOLDOWN_SHAPE=late_peak
export NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
export NANOGPT_ADAMW_EMBED_LR_MULT=1.5

run_arm() {
    local label="$1"
    local mult="$2"
    local frac="$3"
    local name_suffix="$4"
    local log="embed_lr_step0_boost_arm_${label}.log"
    echo "[runner] starting arm ${label} (mult=${mult} frac=${frac}) at $(date -u +%H:%M:%S)" \
        | tee -a embed_lr_step0_boost_runner.log
    NANOGPT_EMBED_LR_BOOST_MULT=${mult} NANOGPT_EMBED_LR_BOOST_FRAC=${frac} \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r4-alphonse/embed-lr-step0-boost-${label}-${name_suffix}" \
      --wandb_group "g1r4-alphonse/embed-lr-step0-boost" \
      > "${log}" 2>&1
    local rc=$?
    echo "[runner] finished arm ${label} (mult=${mult} frac=${frac}) rc=${rc} at $(date -u +%H:%M:%S)" \
        | tee -a embed_lr_step0_boost_runner.log
    return $rc
}

# Arm A: control (boost disabled, mult=1.0 frac=0.0)
# Arm B: modest 2.0x boost, 3% window (~100 steps)
# Arm C: aggressive 2.5x boost, 3% window (~100 steps)
# Arm D: 2.0x boost, 6% window (~200 steps)
run_arm A 1.0 0.0 control
run_arm B 2.0 0.03 2.0x-3pct
run_arm C 2.5 0.03 2.5x-3pct
run_arm D 2.0 0.06 2.0x-6pct
echo "[runner] all arms finished at $(date -u +%H:%M:%S)" \
    | tee -a embed_lr_step0_boost_runner.log
