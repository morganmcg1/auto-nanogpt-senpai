#!/usr/bin/env bash
# Run cells 1-3 of the SF Muon y-interpolation hypothesis (PR #2030, advisor
# Option B + relaxed kill-gate). Each cell aborts early via the in-process
# kill-gate if val_loss at step 875 exceeds 3.88 (= baseline 3.6769 + 0.20
# margin; advisor-approved after the prior 3.40 gate killed a healthy run).
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p logs

run_cell() {
    local cell_id="$1"
    local sf_beta="$2"
    local sf_y_beta="$3"
    local sf_groups="$4"
    local short_name="$5"
    local logfile="logs/sf_muon_y_interp_${cell_id}.log"
    local pidfile="logs/sf_muon_y_interp_${cell_id}.pid"

    echo "=== START cell ${cell_id} (sf_beta=${sf_beta}, sf_y_beta=${sf_y_beta}, groups=${sf_groups}) at $(date -u +%H:%M:%SZ) ==="
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 \
        --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft \
        --lr_cooldown_shape cosine \
        --ema_eval_decay 0.99 \
        --sf_muon --sf_beta "${sf_beta}" --sf_y_beta "${sf_y_beta}" --sf_muon_groups "${sf_groups}" \
        --sf_kill_gate_step 875 --sf_kill_gate_threshold 3.88 \
        --wandb_name "g1r5-askeladd/${short_name}" \
        --wandb_group "g1r5-askeladd/sf-muon-y-interp" \
        >>"${logfile}" 2>&1 &
    local pid=$!
    echo "${pid}" >"${pidfile}"
    if wait "${pid}"; then
        echo "=== END cell ${cell_id} OK at $(date -u +%H:%M:%SZ) ==="
    else
        local rc=$?
        echo "=== END cell ${cell_id} FAIL rc=${rc} at $(date -u +%H:%M:%SZ) ==="
    fi
}

run_cell cell1 1.0 0.9 all "sf-muon-yint-cell1-relaunch-beta1.0-yb0.9-all"
# Cells 2 and 3 disabled per advisor 05:47Z: post-#1966 baseline shifted
# (mu_cooldown_target 0.80 merged); pause after cell 1 for advisor decision
# on whether to rebase + re-run on new baseline stack.
# run_cell cell2 1.0 0.9 mlp "sf-muon-yint-cell2-relaunch-beta1.0-yb0.9-mlp"
# run_cell cell3 0.98 0.9 all "sf-muon-yint-cell3-relaunch-beta0.98-yb0.9-all"

echo "Cell 1 done, cells 2/3 disabled pending advisor direction, at $(date -u +%H:%M:%SZ)"
