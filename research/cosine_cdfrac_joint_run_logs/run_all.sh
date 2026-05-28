#!/bin/bash
# Sequential sweep for PR #1481 cosine × cooldown_frac joint sweep — 5 cells, n=1 each.
set -u
cd /workspace/senpai/target

LOG_DIR=research/cosine_cdfrac_joint_run_logs
mkdir -p "$LOG_DIR"

# Cells: (LETTER CDFRAC)
CELLS=(
    "A 0.7"
    "B 0.6"
    "C 0.5"
    "D 0.4"
    "E 0.3"
)

iso_now() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

for spec in "${CELLS[@]}"; do
    letter=$(echo "$spec" | awk '{print $1}')
    cdfrac=$(echo "$spec" | awk '{print $2}')
    log="${LOG_DIR}/cell_${letter}_cdfrac${cdfrac}.log"
    {
        echo "=== START Cell ${letter} (cosine cdfrac=${cdfrac}) at $(iso_now) ==="
        SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
            records/track_3_optimization/train_gpt_simple.py \
            --num_trials 1 \
            --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
            --lr_scalars 0.03 --depth_init_mode musoft \
            --lr_cooldown_shape cosine \
            --cooldown_frac "${cdfrac}" \
            --wandb_name "g1r5-alphonse/cosine-cdfrac-${cdfrac}-n1" \
            --wandb_group "g1r5-alphonse/cosine-cdfrac-joint"
        rc=$?
        echo "=== END Cell ${letter} (cosine cdfrac=${cdfrac}) rc=${rc} at $(iso_now) ==="
    } >> "$log" 2>&1
    sleep 30
done

echo "=== SWEEP COMPLETE at $(iso_now) ===" >> "${LOG_DIR}/sweep_done.txt"
