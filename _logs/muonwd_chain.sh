#!/bin/bash
# Muon WD cooldown sweep chain: launch arms A (control, WD constant 0.025),
# B (WD ramp 0.025->0.010), C (WD ramp 0.025->0.005), D (WD ramp 0.025->0.000)
# sequentially. Each arm ~110 minutes; total ~7.5h.
# Logs land in _logs/muonwd_arm_<label>_<short>.log; sweep status to _logs/muonwd_sweep.log.

set -u

cd /workspace/senpai/target

SWEEP_LOG="_logs/muonwd_sweep.log"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$SWEEP_LOG"; }

launch_arm() {
  local arm_label="$1"      # A | B | C | D
  local wd_final="$2"       # -1 (disabled) | 0.010 | 0.005 | 0.000
  local short_name="$3"     # used in wandb name and log path
  local run_name="muonwd-${arm_label}-${short_name}"
  local log="_logs/muonwd_arm_${arm_label}_${short_name}.log"
  local pid_file="_logs/muonwd_arm_${arm_label}.pid"

  rm -f "$log" "$pid_file"
  log "ARM ${arm_label}: NANOGPT_MUON_WD_COOLDOWN_FINAL=${wd_final} -> ${run_name}"
  log "ARM ${arm_label}: log=${log}"

  nohup env \
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
    >"$log" 2>&1 &

  local launcher_pid=$!
  echo "$launcher_pid" > "$pid_file"
  sleep 20
  local child_pid
  child_pid=$(pgrep -P "$launcher_pid" -f "train_gpt_simple.py" | head -1)
  if [ -z "$child_pid" ]; then
    child_pid=$(pgrep -f "g1r4-edward/${run_name}" | grep -v "$launcher_pid" | head -1)
  fi
  log "ARM ${arm_label}: launcher_pid=${launcher_pid} child_pid=${child_pid:-unknown}"
  echo "${child_pid:-$launcher_pid}"
}

wait_for_pid() {
  local pid="$1"
  local arm_label="$2"
  log "ARM ${arm_label}: waiting for pid=${pid}"
  while kill -0 "$pid" 2>/dev/null; do
    sleep 30
  done
  log "ARM ${arm_label}: pid=${pid} no longer running"
}

log "Muon WD cooldown sweep chain start"

# arm_label : wd_final : short_name
for spec in \
  "A:-1:control" \
  "B:0.010:wd0p010" \
  "C:0.005:wd0p005" \
  "D:0.000:wd0p000" ; do
  IFS=":" read -r label wd shortname <<< "$spec"
  child_pid=$(launch_arm "$label" "$wd" "$shortname")
  wait_for_pid "$child_pid" "$label"
  sleep 30
done

log "Muon WD cooldown sweep chain complete."
