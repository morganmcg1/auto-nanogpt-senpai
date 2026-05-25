#!/bin/bash
# n=4 confirmation orchestrator v2 (resume): waits for seed 2 to exit, then runs seed 3.
# Same config as Cell C (AdaBelief eps=1e-16). seed1 already finished (gmqu5cnq).
set -u
LOG_DIR="/workspace/senpai/target/research/adabelief_aux_run_logs"
WORK_DIR="/workspace/senpai/target"
DAEMON_LOG="$LOG_DIR/n4_resume_daemon_v2.log"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: starting pid=$$" >> "$DAEMON_LOG"
echo "$$" > "$LOG_DIR/n4_resume_daemon_v2.pid"
cd "$WORK_DIR"

SEED2_PID="${1:-391574}"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: waiting for seed2 pid=$SEED2_PID to exit" >> "$DAEMON_LOG"
while kill -0 "$SEED2_PID" 2>/dev/null; do
    sleep 30
done
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: seed2 exited" >> "$DAEMON_LOG"

# Small grace period for GPU memory to free
sleep 15

BASE="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="--wandb_group g1r5-alphonse/adabelief-aux-confirm-n4"

for SEED in 3; do
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: launching seed=$SEED" >> "$DAEMON_LOG"
  echo "=== Seed $SEED started $(date -u +%FT%TZ) ===" >> "$LOG_DIR/n4_orchestrator.log"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
    --use_adabelief --adam_eps 1e-16 --torch_manual_seed $SEED \
    --wandb_name "g1r5-alphonse/adabelief-C-confirm-n4-seed${SEED}" \
    > "$LOG_DIR/n4_seed${SEED}.log" 2>&1
  rc=$?
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: seed=$SEED rc=$rc" >> "$DAEMON_LOG"
  echo "=== Seed $SEED finished $(date -u +%FT%TZ) (rc=$rc) ===" >> "$LOG_DIR/n4_orchestrator.log"
done
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon v2: all done" >> "$DAEMON_LOG"
echo "=== ALL DONE $(date -u +%FT%TZ) ===" >> "$LOG_DIR/n4_orchestrator.log"
