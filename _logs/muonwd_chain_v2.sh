#!/bin/bash
# Muon WD cooldown sweep chain (v2 — sequential execution).
#
# v1 bug: launch_arm() returned the child pid via stdout, but log() also
# tee'd to stdout. The caller captured the entire log output as the pid,
# so wait_for_pid received non-numeric junk and `kill -0` failed
# immediately, letting all 4 arms launch in parallel and OOM the GPU.
#
# v2 design: launch each arm and wait on the launcher pid directly.
# torchrun exits when its python child exits, so waiting on the launcher
# pid is equivalent to waiting on the run itself.
#
# Arms: A (control WD=0.025), B (WD ramp -> 0.010), C (WD ramp -> 0.005),
#       D (WD ramp -> 0.000). Each arm ~110 minutes single-GPU; ~7.5h total.

set -u

cd /workspace/senpai/target

SWEEP_LOG="_logs/muonwd_sweep_v2.log"
: > "$SWEEP_LOG"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$SWEEP_LOG"; }

run_arm() {
  local arm_label="$1"   # A | B | C | D
  local wd_final="$2"    # -1 | 0.010 | 0.005 | 0.000
  local short_name="$3"
  local run_name="muonwd-${arm_label}-${short_name}"
  local arm_log="_logs/muonwd_arm_${arm_label}_${short_name}_v2.log"

  : > "$arm_log"
  log "ARM ${arm_label}: NANOGPT_MUON_WD_COOLDOWN_FINAL=${wd_final} -> ${run_name}"
  log "ARM ${arm_label}: arm_log=${arm_log}"

  env \
    NANOGPT_MUON_WD_COOLDOWN_FINAL="$wd_final" \
    NANOGPT_GRAD_CLIP=10.0 \
    NANOGPT_NS_ITERS=12 \
    NANOGPT_NS_ITERS_COOLDOWN=16 \
    NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
    NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
    NANOGPT_ADAMW_BETA2=0.99 \
    NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
    NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
    NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
    torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r4-edward/${run_name}" \
      --wandb_group "g1r4-edward/muon-wd-cooldown" \
    > "$arm_log" 2>&1 &

  local launcher_pid=$!
  log "ARM ${arm_label}: launcher_pid=${launcher_pid}"

  wait "$launcher_pid"
  local rc=$?
  log "ARM ${arm_label}: exit=${rc}"
}

log "Muon WD cooldown sweep chain v2 start"

# arm_label : wd_final : short_name
for spec in \
  "A:-1:control" \
  "B:0.010:wd0p010" \
  "C:0.005:wd0p005" \
  "D:0.000:wd0p000" ; do
  IFS=":" read -r label wd shortname <<< "$spec"
  run_arm "$label" "$wd" "$shortname"
  sleep 15
done

log "Muon WD cooldown sweep chain v2 complete."
