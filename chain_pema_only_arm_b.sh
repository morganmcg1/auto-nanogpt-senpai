#!/bin/bash
set -u
LOG_DIR="/workspace/senpai/target/run_logs"
CHAIN_LOG="${LOG_DIR}/chain_pema_only_arm_b.log"
A_PID_FILE="${LOG_DIR}/pema_only_arm_a.pid"
B_PID_FILE="${LOG_DIR}/pema_only_arm_b.pid"
B_LOG="${LOG_DIR}/pema_only_arm_b.log"

echo "[chain] starting at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$CHAIN_LOG"

if [[ ! -f "$A_PID_FILE" ]]; then
    echo "[chain] no Arm A pid file at $A_PID_FILE — aborting" >> "$CHAIN_LOG"
    exit 1
fi

A_PID=$(cat "$A_PID_FILE")
echo "[chain] waiting on Arm A pid=$A_PID" >> "$CHAIN_LOG"

while kill -0 "$A_PID" 2>/dev/null; do
    sleep 30
done

echo "[chain] Arm A pid=$A_PID exited at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$CHAIN_LOG"

# Sanity gate — never launch Arm B while another train is running.
if pgrep -f 'train_gpt_simple\.py' > /dev/null; then
    echo "[chain] another train_gpt_simple is still running — aborting Arm B launch" >> "$CHAIN_LOG"
    exit 1
fi

cd /workspace/senpai/target

echo "[chain] launching Arm B at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$CHAIN_LOG"
nohup torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
    --muon_block_lr_pattern late-higher \
    --paramema_refresh_only --paramema_refresh_step 2600 \
    --wandb_name "g1r1-fern/pema-only-arm-b-step2600" \
    --wandb_group "g1r1-fern-pema-only-ablation" \
    > "$B_LOG" 2>&1 &

B_PID=$!
echo "$B_PID" > "$B_PID_FILE"
echo "[chain] Arm B pid=$B_PID launched, log=$B_LOG" >> "$CHAIN_LOG"
