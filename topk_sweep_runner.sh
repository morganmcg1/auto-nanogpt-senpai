#!/bin/bash
# Run all 5 cells for top-k pre-NS sparsification sweep, sequentially.
set -uo pipefail
cd /workspace/senpai/target

LOG_DIR=/workspace/senpai/target/topk_cell_logs
mkdir -p "$LOG_DIR"

MANDATORY="--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft"
GROUP="g1r5-frieren/top-k-sparsification-pre-ns"

# format: <cell_id>|<extra flags>|<wandb-name suffix>
CELLS=(
  "cellA||baseline-ctrl"
  "cellB|--topk_ratio 0.5 --topk_scope mlp|top50-mlp"
  "cellC|--topk_ratio 0.75 --topk_scope mlp|top75-mlp"
  "cellD|--topk_ratio 0.5 --topk_scope all|top50-all"
  "cellE|--topk_ratio 0.9 --topk_scope mlp|top90-mlp"
)

for cell_spec in "${CELLS[@]}"; do
  IFS='|' read -r cell flags name <<< "$cell_spec"
  log="${LOG_DIR}/${cell}.log"
  status="${LOG_DIR}/${cell}.status"
  echo "==== Running ${cell} (${name}): ${flags} ====" | tee "$log"
  date -u +"%Y-%m-%dT%H:%M:%SZ" | tee -a "$log"
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    $MANDATORY $flags \
    --wandb_name "g1r5-frieren/${name}" \
    --wandb_group "$GROUP" >> "$log" 2>&1
  rc=$?
  echo "rc=${rc}" > "$status"
  echo "==== ${cell} done (rc=${rc}): $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====" | tee -a "$log"
done
