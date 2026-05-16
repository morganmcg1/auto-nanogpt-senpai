# SENPAI Baselines — auto-nanogpt-1gpu-r5

Ordered chronologically. Compare new results against the **most recent entry**.

## 2026-05-16 03:30 UTC — PR #46: SOAP-Muon for MLP weights only (isolated)

- **Primary metric:** `speedrun/final_first_step_to_target` = **3200** (all 6 seeds)
- **val/loss (mu):** **3.27744** (std=4.32e-4, SE=1.76e-4)
- **n:** 6 seeds, `train_steps=3250`
- **Statsig rule:** `(3.28 - 3.27744) × sqrt(6) = 0.00628 ≥ 0.004` ✅ PASS
- **W&B run:** `zj5hesz1` (project: `wandb-applied-ai-team/modded-nanogpt-senpai`)
- **Student:** g1r5-fern
- **What changed:** SOAP preconditioning applied to Muon-managed MLP weights only
  (`mlp.fc.weight`, `mlp.proj.weight`). Attn projections stay on plain Muon.
  AdamW aux unchanged. Inline eigendecomp with `precond_freq=16`, `beta2=0.90`.
  Also carries `sample_tensor` float64 fix and `torch==2.11` bump.
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  pip install -r requirements.txt && \
  python data/cached_fineweb10B.py 20 && \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 6 \
    --wandb_name "baseline-soap-mlp-n6" \
    --wandb_group "baselines"
```

## Pre-wave-1 Starter (reference)

- **Primary metric:** `speedrun/final_first_step_to_target` ≈ **3325–3350** (plain Muon)
- **val/loss (mu):** ~3.279 (public reference: record #12 mu=3.2790 n=20 at 3325 steps)
- **n:** not formally run on this branch; use peer wave-1 screening seeds as reference
- **What it is:** Starter `train_gpt_simple.py` — plain Muon + AdamW aux,
  `lr=0.035, wd=0.025, cooldown_frac=0.7, train_steps=3350`
