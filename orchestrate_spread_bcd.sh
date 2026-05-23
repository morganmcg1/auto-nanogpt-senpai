#!/bin/bash
# PR #883 — Orchestrate Arms B, C, D after Arm A completes.
# Arm A was launched manually by the advisor. This script waits for that PID,
# then runs B (spread=1), C (spread=4), D (spread=6) sequentially.
set -euo pipefail

cd "$(dirname "$0")"

ARM_A_PID="${1:?Usage: $0 <arm_a_pid>}"

echo "==> Waiting for Arm A (PID=${ARM_A_PID}) to finish..."
while kill -0 "${ARM_A_PID}" 2>/dev/null; do
  sleep 30
done
echo "==> Arm A finished at $(date -u +%FT%TZ)"

# Brief pause to let cleanup settle
sleep 10

echo "==> Launching Arm B (spread=1) at $(date -u +%FT%TZ)"
./run_arms_spread.sh B 1
echo "==> Arm B finished at $(date -u +%FT%TZ)"

sleep 10

echo "==> Launching Arm C (spread=4) at $(date -u +%FT%TZ)"
./run_arms_spread.sh C 4
echo "==> Arm C finished at $(date -u +%FT%TZ)"

sleep 10

echo "==> Launching Arm D (spread=6) at $(date -u +%FT%TZ)"
./run_arms_spread.sh D 6
echo "==> Arm D finished at $(date -u +%FT%TZ)"

echo "==> All arms complete at $(date -u +%FT%TZ)"
