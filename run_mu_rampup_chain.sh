#!/bin/bash
# Chain run for PR #1345: mu cooldown rampup 5-cell sweep
# Cells A (ctrl 0.95), B★ PRIMARY (0.95->0.98), C (0.95->0.99), D (instant 0.98), E (0.95->0.999 falsifier)
# Sequential, n=1 per cell, total ~10h.

set -u
cd "$(dirname "$0")"
mkdir -p screen_logs

BASE="SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-nezuko/mu-cooldown-rampup"

run_cell() {
    local label="$1"
    local logfile="screen_logs/mu_rampup_cell_${label}.log"
    shift
    echo "=== $(date -u +%FT%TZ) Cell ${label} starting ===" | tee -a "$logfile"
    bash -c "$BASE $* --wandb_group $GROUP" 2>&1 | tee -a "$logfile"
    local rc=${PIPESTATUS[0]}
    echo "=== $(date -u +%FT%TZ) Cell ${label} finished (rc=${rc}) ===" | tee -a "$logfile"
    return $rc
}

# Cell A — ctrl: constant mu=0.95 (no flag = mu_active=False, baseline replicates)
run_cell A --wandb_name cell-A-mu095-ctrl-n1 || echo "Cell A failed but continuing"

# Cell B★ — PRIMARY: ramp 0.95 -> 0.98 during cooldown
run_cell B --mu_cooldown_target 0.98 --wandb_name cell-B-mu098-rampup-n1 || echo "Cell B failed but continuing"

# Cell C — ramp 0.95 -> 0.99 during cooldown (more aggressive)
run_cell C --mu_cooldown_target 0.99 --wandb_name cell-C-mu099-rampup-n1 || echo "Cell C failed but continuing"

# Cell D — instant jump to 0.98 at cooldown_start (mirror of #1294 Cell D)
run_cell D --mu_cooldown_target 0.98 --mu_cooldown_instant --wandb_name cell-D-mu098-instant-n1 || echo "Cell D failed but continuing"

# Cell E — falsifier: ramp 0.95 -> 0.999 (extreme smoothing, expect over-smooth)
run_cell E --mu_cooldown_target 0.999 --wandb_name cell-E-mu0999-falsifier-n1 || echo "Cell E failed but continuing"

echo "=== $(date -u +%FT%TZ) Chain complete ==="
