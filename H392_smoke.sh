#!/usr/bin/env bash
# H392 smoke gate: 125 steps on all 3 arms to verify the new code path runs
# cleanly AND step-0 val=10.82583 EXACT (Pattern A bit-id sentinel).
#   smoke_a: --muonh_cooldown_shape cosine (CTRL = H266 baseline)
#   smoke_b: --muonh_cooldown_shape cosine_squared (default cooldown_frac=1.0)
#   smoke_c: --muonh_cooldown_shape cosine_squared --muonh_cooldown_frac 0.5
# All three must report step-0 val=10.82583 EXACT (cooldown machinery only
# affects LR scheduling, step-0 fires before any cooldown logic per advisor).

set -euo pipefail
cd "$(dirname "$0")"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUNLOGS="runlogs"
mkdir -p "${RUNLOGS}"
SCRIPT="records/track_3_optimization/train_gpt_simple.py"

COMMON_FLAGS=(
  --num_trials 1 --train_steps 125
  --wandb_project modded-nanogpt-senpai
  --wandb_group H392_cosine_squared_cooldown_smoke
)

# smoke_a: CTRL cosine
LOG_A="${RUNLOGS}/H392_smoke_a_${TS}.log"
echo "[H392] launching smoke_a CTRL cosine -> ${LOG_A}"
torchrun --standalone --nproc_per_node=1 "${SCRIPT}" \
  --muonh_cooldown_shape cosine \
  --wandb_name "g1r3-edward/H392_smoke_a_ctrl_cosine_${TS}" \
  "${COMMON_FLAGS[@]}" 2>&1 | tee "${LOG_A}"

# smoke_b: cosine_squared (default cooldown_frac=1.0)
LOG_B="${RUNLOGS}/H392_smoke_b_${TS}.log"
echo "[H392] launching smoke_b cosine_squared -> ${LOG_B}"
torchrun --standalone --nproc_per_node=1 "${SCRIPT}" \
  --muonh_cooldown_shape cosine_squared \
  --wandb_name "g1r3-edward/H392_smoke_b_cos2_${TS}" \
  "${COMMON_FLAGS[@]}" 2>&1 | tee "${LOG_B}"

# smoke_c: cosine_squared + cooldown_frac=0.5
LOG_C="${RUNLOGS}/H392_smoke_c_${TS}.log"
echo "[H392] launching smoke_c cosine_squared+cd0.5 -> ${LOG_C}"
torchrun --standalone --nproc_per_node=1 "${SCRIPT}" \
  --muonh_cooldown_shape cosine_squared \
  --muonh_cooldown_frac 0.5 \
  --wandb_name "g1r3-edward/H392_smoke_c_cos2_cd0.5_${TS}" \
  "${COMMON_FLAGS[@]}" 2>&1 | tee "${LOG_C}"

echo "[H392] smokes done. step-0/125 val:"
for L in "${LOG_A}" "${LOG_B}" "${LOG_C}"; do
  echo "--- ${L} ---"
  grep -E '^step:(0|125)/' "${L}" || true
done
