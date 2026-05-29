#!/bin/bash
# Sequential 5-cell sweep for PR #1721 SOAP Gram warm-init.
# Order: A (control identity) -> B (★ diag_grad_var x1) -> C (diag x0.5)
#     -> D (diag x2) -> E (orthogonal_random falsifier)
# Cell A first gives us a fresh baseline reproducer; KG2 step-200 comparison
# becomes immediate when B finishes.
set -u

cd /workspace/senpai/target

RUNDIR=runs/soap_gram_warm_init
mkdir -p "$RUNDIR"

GROUP="g1r5-fern/soap-gram-warm-init"

run_cell() {
    local label="$1"
    local mode="$2"
    local scale="$3"
    local logf="$RUNDIR/${label}.log"
    local pidf="$RUNDIR/${label}.pid"

    echo "===== $(date -u +%FT%TZ) launching cell $label (mode=$mode scale=$scale) =====" \
        | tee -a "$RUNDIR/runner.log"
    SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
        --lr_scalars 0.03 --depth_init_mode musoft \
        --lr_cooldown_shape cosine --ema_eval_decay 0.99 \
        --soap_warm_init_mode "$mode" --soap_warm_init_scale "$scale" \
        --wandb_name "g1r5-fern/soap-gram-warm-init-${label}" \
        --wandb_group "$GROUP" \
        > "$logf" 2>&1 &
    local pid=$!
    echo "$pid" > "$pidf"
    echo "    cell $label PID=$pid log=$logf" | tee -a "$RUNDIR/runner.log"
    wait "$pid"
    local rc=$?
    echo "===== $(date -u +%FT%TZ) cell $label finished rc=$rc =====" | tee -a "$RUNDIR/runner.log"
}

# Cell A — baseline reproducer (identity init, scale unused)
run_cell "A-ctrl-identity" "identity" "1.0"

# Cell B — primary hypothesis (diag_grad_var, matched scale)
run_cell "B-diag-x1p0" "diag_grad_var" "1.0"

# Cell C — conservative warm (half magnitude)
run_cell "C-diag-x0p5" "diag_grad_var" "0.5"

# Cell D — aggressive warm (double magnitude)
run_cell "D-diag-x2p0" "diag_grad_var" "2.0"

# Cell E — orthogonal_random falsifier (scale unused)
run_cell "E-orth-random" "orthogonal_random" "1.0"

echo "===== $(date -u +%FT%TZ) all 5 cells finished =====" | tee -a "$RUNDIR/runner.log"
