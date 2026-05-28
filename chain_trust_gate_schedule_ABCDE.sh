#!/usr/bin/env bash
# 5-cell trust-gate schedule sweep (n=1 each).
# PR #1565 — tanjiro: SOAP trust gate threshold SCHEDULE
set -e
mkdir -p logs_trust_gate_schedule
GROUP="tanjiro-trust-gate-schedule"

run_cell() {
    local name="$1"
    local peak="$2"
    local ramp="$3"
    local label="$4"
    echo "=== Cell ${name}: peak=${peak} ramp_frac=${ramp} (${label}) ==="
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
        --soap_trust_peak "${peak}" --soap_trust_ramp_frac "${ramp}" \
        --wandb_name "g1r5-tanjiro/trust-gate-schedule-${name}-peak${peak}-ramp${ramp}-n1" \
        --wandb_group "${GROUP}" \
        2>&1 | tee "logs_trust_gate_schedule/cell_${name}.log"
}

run_cell A 0.0 0.15 "ctrl-baseline-no-schedule"
run_cell B 0.3 0.15 "PRIMARY-moderate-gradual-ramp"
run_cell C 0.5 0.15 "stricter-gate"
run_cell D 0.3 0.25 "slower-ramp"
run_cell E 0.3 0.0  "falsifier-step-function"

echo "=== chain complete ==="
