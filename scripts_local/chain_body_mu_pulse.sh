#!/usr/bin/env bash
# PR #1456: body-Muon μ phase-window pulse chain.
# Sequentially run Arm A (μ=0.97 sticky) → Arm B (μ=0.93 reactive).
# Uses the NEW baseline config (PR #1429 merged 17:20 UTC May 27):
#   --paramema_refresh_only --paramema_refresh_step 2600
set -u
cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/run_logs
LOG_A="$LOG_DIR/body_mu_pulse_armA.log"
LOG_B="$LOG_DIR/body_mu_pulse_armB.log"
LOG_CHAIN="$LOG_DIR/body_mu_pulse_chain.log"
PIDFILE_A="$LOG_DIR/body_mu_pulse_armA.pid"
PIDFILE_B="$LOG_DIR/body_mu_pulse_armB.pid"

echo "$(date -u +%FT%TZ) chain start pid=$$ (new baseline w/ paramema_refresh)" >> "$LOG_CHAIN"

# Arm A — sticky μ=0.97 in window 2500-2924.
echo "$(date -u +%FT%TZ) launching Arm A (mu=0.97 sticky)" >> "$LOG_CHAIN"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --body_pretarget_mu 0.97 \
  --wandb_name "g1r1-thorfinn/body-mu-pulse-arm-a-mu0p97" \
  --wandb_group "g1r1-thorfinn-body-mu-pulse" \
  >> "$LOG_A" 2>&1 &
ARMA_PID=$!
echo "$ARMA_PID" > "$PIDFILE_A"
echo "$(date -u +%FT%TZ) Arm A pid=$ARMA_PID" >> "$LOG_CHAIN"
wait "$ARMA_PID"
ARMA_RC=$?
echo "$(date -u +%FT%TZ) Arm A exited rc=$ARMA_RC" >> "$LOG_CHAIN"

# Buffer + pgrep gate before Arm B.
sleep 30
if pgrep -f 'train_gpt_simple\.py' > /dev/null; then
  echo "$(date -u +%FT%TZ) BLOCKED before Arm B: another train_gpt_simple.py running" >> "$LOG_CHAIN"
  exit 1
fi

# Arm B — reactive μ=0.93 in window 2500-2924.
echo "$(date -u +%FT%TZ) launching Arm B (mu=0.93 reactive)" >> "$LOG_CHAIN"
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --body_pretarget_mu 0.93 \
  --wandb_name "g1r1-thorfinn/body-mu-pulse-arm-b-mu0p93" \
  --wandb_group "g1r1-thorfinn-body-mu-pulse" \
  >> "$LOG_B" 2>&1 &
ARMB_PID=$!
echo "$ARMB_PID" > "$PIDFILE_B"
echo "$(date -u +%FT%TZ) Arm B pid=$ARMB_PID" >> "$LOG_CHAIN"
wait "$ARMB_PID"
ARMB_RC=$?
echo "$(date -u +%FT%TZ) Arm B exited rc=$ARMB_RC" >> "$LOG_CHAIN"

echo "$(date -u +%FT%TZ) chain complete: armA=$ARMA_RC armB=$ARMB_RC" >> "$LOG_CHAIN"
