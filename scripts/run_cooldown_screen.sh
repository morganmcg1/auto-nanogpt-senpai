#!/usr/bin/env bash
# Sequentially screen cooldown (shape, frac) configs at train_steps=3300, n=1.
# Skips configs already in logs/screen-summary.tsv (idempotent resume).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p logs

NPROC=$(nvidia-smi -L | wc -l)
SUMMARY="logs/screen-summary.tsv"
if [ ! -s "$SUMMARY" ]; then
  echo -e "idx\tshape\tfrac\tbest_val_loss\tfinal_val_loss\treached_3p28\twandb_run_id\tlog" > "$SUMMARY"
fi

# (shape frac wandb_name) — first two (already done) are recorded manually.
CONFIGS=(
  "cosine    0.7"
  "linear    0.7"
  "cosine    0.55"
  "linear    0.55"
  "cosine    0.4"
  "linear    0.4"
  "linear    0.85"
  "quadratic 0.7"
  "quadratic 0.55"
  "sqrt      0.7"
  "sqrt      0.55"
  "cube      0.7"
)

idx=0
for cfg in "${CONFIGS[@]}"; do
  idx=$((idx+1))
  shape=$(echo "$cfg" | awk '{print $1}')
  frac=$(echo "$cfg" | awk '{print $2}')
  tag="${shape}-${frac}"
  log="logs/screen-${tag}.txt"
  # Skip if already recorded.
  if awk -v t="${tag}" -F'\t' 'NR>1 && $2"-"$3==t {found=1} END{exit !found}' "$SUMMARY"; then
    echo "[${idx}/12] ${tag} already recorded; skipping"
    continue
  fi
  echo "=== [${idx}/12] shape=${shape} frac=${frac} -> ${log} ==="
  date
  torchrun --standalone --nproc_per_node=${NPROC} \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 1 \
    --train_steps 3300 \
    --cooldown_shape "${shape}" \
    --cooldown_frac "${frac}" \
    --wandb_name "r4-frieren/screen-${tag}" \
    --wandb_group "r4-frieren/cooldown-screen" \
    --wandb_tags "cooldown-sweep,screen" \
    > "${log}" 2>&1
  status=$?
  echo "exit=${status}"
  best=$(grep -oE "val_loss:[0-9.]+" "${log}" | sed 's/val_loss://' | sort -g | head -1)
  final=$(grep -oE "val_loss:[0-9.]+" "${log}" | sed 's/val_loss://' | tail -1)
  best=${best:-NA}
  final=${final:-NA}
  reached="false"
  if [ "$best" != "NA" ] && awk -v b="$best" 'BEGIN{exit !(b<=3.28)}'; then
    reached="true"
  fi
  run_id=$(grep -oE "View run at [^ ]+/runs/[A-Za-z0-9]+" "${log}" | head -1 | sed -E 's|.*/runs/||')
  run_id=${run_id:-NA}
  echo "result: best_val=${best} final_val=${final} reached=${reached} run_id=${run_id}"
  echo -e "${idx}\t${shape}\t${frac}\t${best}\t${final}\t${reached}\t${run_id}\t${log}" >> "$SUMMARY"
done
echo "=== screening complete ==="
date
