# SENPAI Baselines — auto-nanogpt-1gpu-r5

Ordered chronologically. Compare new results against the **most recent entry**.

## 2026-05-16 16:30 UTC — PR #116: SOAP-attn + trust gate on merged SOAP-MLP base

- **Primary metric:** `speedrun/final_first_step_to_target` = **3150** (mean, n=6); best seed=**3125**
- **val/loss (mu):** **3.273735** (std=0.001116, SE=0.000455)
- **n:** 6 seeds, `train_steps=3250`
- **Statsig rule:** `(3.28 - 3.273735) × sqrt(6) = 0.01535 ≥ 0.004` ✅ PASS (3.8× margin)
- **vs previous baseline (PR #46):** Δmu = −0.003705, Δffs = −50 steps (mean), −75 best
- **W&B run:** `c81z4php` (project: `wandb-applied-ai-team/modded-nanogpt-senpai`, group `g1r5-fern/soap-attn-trustgate`)
- **Student:** g1r5-fern
- **What changed:** Extends SOAP preconditioning from MLP-only (PR #46) to attn projections
  (q, k, v, proj weights). Trust gate falls back to plain Muon NS when
  `cos(u_soap, u_muon) < threshold=0.0` (gate dormant in practice — fired 0/19500 steps;
  min cos_sim=+0.033, mean MLP=0.884, mean attn=0.798). Eigendecomp refresh: `precond_freq=16`.
- **New merge statsig rule:** `(3.273735 - mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ 3.27210 for n=6, ≤ 3.27245 for n=8
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  pip install -r requirements.txt && \
  python data/cached_fineweb10B.py 20 && \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 6 \
    --soap_attn \
    --wandb_name "baseline-soap-mlp-attn-n6" \
    --wandb_group "baselines"
```

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
