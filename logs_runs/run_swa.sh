#!/usr/bin/env bash
# H17 SWA on aux AdamW (PR #555) — 3-arm screening chain.
#
# Arm 1 ctrl: aux_swa_start_frac=0.0 (SWA OFF, baseline reproducibility)
# Arm 2:      aux_swa_start_frac=0.9, aux_swa_every=1 (last 10%, every step, ~334 snapshots)
# Arm 3:      aux_swa_start_frac=0.8, aux_swa_every=2 (last 20%, every 2 steps, ~333 snapshots)
#
# Per-arm kill gates:
#   - step 250 val > 4.30 (or NaN) -> mark arm as gate-failed
#   - step 3000 val > 3.30 -> mark arm as gate-failed
# Chain-level abort: if 2+ arms hit a gate, abort the rest of the chain.

set -u
cd /workspace/senpai/target

STATE="logs_runs/swa_chain.state"
KILL_COUNTER=0
RUN_IDS=()
VAL_LOSSES=()
ITERATE_LOSSES=()
FFSES=()

date_iso() { date -Iseconds; }

log_state() {
    echo "[chain $(date_iso)] $1" >> "$STATE"
}

parse_step250() {
    local log="$1"
    # Step 250 always uses val_loss: format (SWA inactive at step 250)
    grep -E "^step:250/[0-9]+ val_loss:" "$log" | tail -1 | sed -E 's/.*val_loss:([0-9.]+).*/\1/'
}
parse_step3000() {
    local log="$1"
    grep -E "^step:3000/[0-9]+ val_loss:" "$log" | tail -1 | sed -E 's/.*val_loss:([0-9.]+).*/\1/'
}
parse_final_val() {
    local log="$1"
    # SWA-enabled arms log: val_loss(swa):X.XXXXX
    # SWA-off arms log:     val_loss:X.XXXXX
    local swa_v iter_v
    swa_v=$(grep -E "^step:3325/[0-9]+ val_loss\(swa\):" "$log" | tail -1 | sed -E 's/.*val_loss\(swa\):([0-9.]+).*/\1/')
    if [ -n "$swa_v" ]; then
        echo "$swa_v"
        return
    fi
    grep -E "^step:3325/[0-9]+ val_loss:" "$log" | tail -1 | sed -E 's/.*val_loss:([0-9.]+).*/\1/'
}
parse_iterate_val() {
    local log="$1"
    grep -E "^step:3325/[0-9]+ val_loss\(swa\):" "$log" | tail -1 | sed -E 's/.*val_loss\(iterate\):([0-9.]+).*/\1/'
}
parse_ffs() {
    local log="$1"
    grep -E "first_step_to_target" "$log" | tail -1 | sed -E 's/.*first_step_to_target:(-?[0-9]+).*/\1/'
}
parse_run_id() {
    local log="$1"
    grep -oE "runs/[a-z0-9]+" "$log" | head -1 | sed 's|runs/||'
}

run_arm() {
    local arm_idx="$1"
    local arm_name="$2"
    local swa_frac="$3"
    local swa_every="$4"
    local log="logs_runs/swa_arm${arm_idx}_${arm_name}.log"
    local wname="g1r3-askeladd/swa-${arm_name}"
    log_state "launching arm$arm_idx ($arm_name) -> $log (wandb_name=$wname swa_frac=$swa_frac swa_every=$swa_every)"
    torchrun --standalone --nproc_per_node=1 \
        records/track_3_optimization/train_gpt_simple.py \
        --num_trials 1 --train_steps 3325 \
        --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 \
        --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
        --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 \
        --aux_adamw_eps 1e-6 \
        --aux_swa_start_frac "$swa_frac" --aux_swa_every "$swa_every" \
        --wandb_name "$wname" \
        --wandb_group "g1r3-askeladd/aux-swa-cooldown" \
        > "$log" 2>&1
    local rc=$?
    log_state "arm$arm_idx exit=$rc"

    local s250 s3000 final iter ffs rid
    s250=$(parse_step250 "$log")
    s3000=$(parse_step3000 "$log")
    final=$(parse_final_val "$log")
    iter=$(parse_iterate_val "$log")
    ffs=$(parse_ffs "$log")
    rid=$(parse_run_id "$log")
    log_state "arm$arm_idx parsed: run_id=$rid s250=$s250 s3000=$s3000 final=$final iterate=$iter ffs=$ffs"

    RUN_IDS+=("$rid")
    VAL_LOSSES+=("$final")
    ITERATE_LOSSES+=("${iter:-na}")
    FFSES+=("$ffs")

    local gate_hit=0
    if [ -z "$s250" ]; then
        log_state "arm$arm_idx WARN: no step:250 line found (run may have crashed)"
        gate_hit=1
    else
        if awk -v v="$s250" 'BEGIN{exit !(v=="nan" || v=="NaN" || v+0>4.30)}'; then
            log_state "arm$arm_idx GATE-FAIL: step 250 val=$s250 > 4.30"
            gate_hit=1
        fi
    fi
    if [ -n "$s3000" ]; then
        if awk -v v="$s3000" 'BEGIN{exit !(v=="nan" || v=="NaN" || v+0>3.30)}'; then
            log_state "arm$arm_idx GATE-FAIL: step 3000 val=$s3000 > 3.30"
            gate_hit=1
        fi
    fi

    if [ $gate_hit -eq 1 ]; then
        KILL_COUNTER=$((KILL_COUNTER+1))
        log_state "arm$arm_idx KILL-COUNTER -> $KILL_COUNTER/2"
    fi

    if [ $KILL_COUNTER -ge 2 ]; then
        log_state "ABORT: kill counter reached 2 — terminating chain"
        return 99
    fi
    return 0
}

log_state "START SWA 3-arm screening chain (arm1 ctrl, arm2 10pct-every1, arm3 20pct-every2)"

# Arm 1: ctrl (SWA OFF)
run_arm 1 "ctrl"        "0.0" "1"
rc=$?
if [ $rc -eq 99 ]; then
    log_state "chain aborted at arm1 (gates failed)"
    exit 1
fi
log_state "arm1 complete, sleeping 15s before arm2"
sleep 15

# Arm 2: SWA last 10%, every step
run_arm 2 "10pct"       "0.9" "1"
rc=$?
if [ $rc -eq 99 ]; then
    log_state "chain aborted at arm2 (gates failed)"
    exit 1
fi
log_state "arm2 complete, sleeping 15s before arm3"
sleep 15

# Arm 3: SWA last 20%, every 2 steps
run_arm 3 "20pct-every2" "0.8" "2"
rc=$?
if [ $rc -eq 99 ]; then
    log_state "chain aborted at arm3 (gates failed)"
    exit 1
fi

log_state "CHAIN COMPLETE — all 3 arms terminal"
log_state "run_ids: ${RUN_IDS[*]}"
log_state "val_losses (swa): ${VAL_LOSSES[*]}"
log_state "iterate_losses:   ${ITERATE_LOSSES[*]}"
log_state "ffses: ${FFSES[*]}"
