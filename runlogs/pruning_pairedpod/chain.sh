#!/bin/bash
# Paired-pod confirmation chain for PR #487 Arm B (drop NS_ITERS_COOLDOWN).
# Runs 3 pods × (Arm A control, Arm B treatment) = 6 runs total.
# Each pod uses a distinct seed; A and B within a pod share the same seed
# so within-pod Delta = val_B - val_A is paired (same init).

set -u
cd /workspace/senpai/target

run_one() {
  local pod="$1"            # 0, 1, 2
  local seed="$2"           # 0, 1, 2
  local arm="$3"            # A or B
  local cooldown_val="$4"   # 16 for A, 0 for B
  local tag="$5"            # control or NS_ITERS_COOLDOWN
  local name="pairedpod-pod${pod}-seed${seed}-arm${arm}"
  local logfile="runlogs/pruning_pairedpod/${name}.log"
  local pidfile="runlogs/pruning_pairedpod/${name}.pid"

  echo "[chain] Launching ${name} at $(date -u +%FT%TZ)"

  local env_pairs=(
    "SENPAI_SEED=${seed}"
    "SENPAI_ABLATION_DROPPED=${tag}"
    "NANOGPT_GRAD_CLIP=10.0"
    "NANOGPT_NS_ITERS=12"
    "NANOGPT_NS_ITERS_COOLDOWN=${cooldown_val}"
    "NANOGPT_NS_COOLDOWN_START_FRAC=0.7"
    "NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor"
    "NANOGPT_ADAMW_BETA2=0.99"
    "NANOGPT_NS_COOLDOWN_SHAPE=late_peak"
    "NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down"
    "NANOGPT_ADAMW_EMBED_LR_MULT=1.5"
  )

  echo "[chain] ${name} envs: ${env_pairs[*]}"

  env "${env_pairs[@]}" \
    nohup torchrun --standalone --nproc_per_node=1 \
      records/track_3_optimization/train_gpt_simple.py \
      --wandb_name "g1r4-tanjiro/cooldown-ns-pruning-${name}" \
      --wandb_group "g1r4-tanjiro/cooldown-ns-pruning-pairedpod" \
      --wandb_tags "ablation_dropped=${tag},pr487,pairedpod,pod${pod},seed${seed}" \
      > "${logfile}" 2>&1 &
  local pid=$!
  echo "${pid}" > "${pidfile}"
  echo "[chain] ${name} PID=${pid}"
  wait "${pid}"
  local exit_code=$?
  echo "[chain] ${name} done at $(date -u +%FT%TZ) exit=${exit_code}"
  sleep 30  # let GPU memory free up
}

# Pod 0: seed=0, Arm A then Arm B.
run_one 0 0 A 16 control
run_one 0 0 B 0  NS_ITERS_COOLDOWN

# Pod 1: seed=1, Arm A then Arm B.
run_one 1 1 A 16 control
run_one 1 1 B 0  NS_ITERS_COOLDOWN

# Pod 2: seed=2, Arm A then Arm B.
run_one 2 2 A 16 control
run_one 2 2 B 0  NS_ITERS_COOLDOWN

echo "[chain] All 6 paired-pod runs complete at $(date -u +%FT%TZ)"
