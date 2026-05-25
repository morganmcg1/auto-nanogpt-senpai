#!/bin/bash
# n=4 confirmation orchestrator (resume): waits for active seed 1 train process to exit,
# then runs seed 2 and seed 3 sequentially. Same config as Cell C (AdaBelief eps=1e-16).
set -u
LOG_DIR="/workspace/senpai/target/research/adabelief_aux_run_logs"
WORK_DIR="/workspace/senpai/target"
DAEMON_LOG="$LOG_DIR/n4_resume_daemon.log"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: starting pid=$$" >> "$DAEMON_LOG"
echo "$$" > "$LOG_DIR/n4_resume_daemon.pid"
cd "$WORK_DIR"

SEED1_PID="${1:-385017}"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: waiting for seed1 pid=$SEED1_PID to exit" >> "$DAEMON_LOG"
while kill -0 "$SEED1_PID" 2>/dev/null; do
    sleep 30
done
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: seed1 exited" >> "$DAEMON_LOG"

BASE="--num_trials 1 --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="--wandb_group g1r5-alphonse/adabelief-aux-confirm-n4"

for SEED in 2 3; do
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: launching seed=$SEED" >> "$DAEMON_LOG"
  echo "=== Seed $SEED started $(date -u +%FT%TZ) ===" >> "$LOG_DIR/n4_orchestrator.log"
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py $BASE $GROUP \
    --use_adabelief --adam_eps 1e-16 --torch_manual_seed $SEED \
    --wandb_name "g1r5-alphonse/adabelief-C-confirm-n4-seed${SEED}" \
    > "$LOG_DIR/n4_seed${SEED}.log" 2>&1
  rc=$?
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: seed=$SEED rc=$rc" >> "$DAEMON_LOG"
  echo "=== Seed $SEED finished $(date -u +%FT%TZ) (rc=$rc) ===" >> "$LOG_DIR/n4_orchestrator.log"
done
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') resume daemon: all done" >> "$DAEMON_LOG"
echo "=== ALL DONE $(date -u +%FT%TZ) ===" >> "$LOG_DIR/n4_orchestrator.log"
