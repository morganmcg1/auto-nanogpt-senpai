# SENPAI Baselines — auto-nanogpt-1gpu-r5

Ordered chronologically. Compare new results against the **most recent entry**.

## 2026-05-19 01:10 UTC — PR #371: Muon WD ramp_down schedule (n=4 confirm)

- **Primary metric:** `speedrun/final_first_step_to_target` = **3100** (ALL 4 trials); ffs_mean=3100
- **val/loss (mu):** **3.267948** (std=0.000823, SE=0.000412)
- **n:** 4 seeds (Phase 2 confirm run `okae8f06`), `train_steps=3250`
- **Statsig:** `(3.271362 − 3.267948) × √4 = 0.006828 ≥ 0.004` ✅ PASS (1.71× headroom)
- **New merge statsig rule:** `(3.267948 - mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ 3.265948 for n=4, ≤ 3.266316 for n=6, ≤ 3.266536 for n=8
- **vs previous baseline (PR #162):** Δmu = −0.003414 (−2.89σ), Δffs = −41.67 steps (mean), new ffs_best=3100
- **W&B runs:** `yh4fzyoe` (P1 Cell C trigger), `okae8f06` (P2 n=4 confirm, group `g1r5-fern/wd-schedule-sweep`)
- **Student:** g1r5-fern
- **What changed:** Muon WD (wd_mlp, wd_attn) follows a `ramp_down` schedule: starts at 0.05, linearly decays to 0.0 over the 3250-step run (time-average = 0.025 = old constant). High WD early regularizes the high-LR phase; zero WD late avoids competition with LR cooldown consolidation. Cell B (`ramp_up` 0→0.05) failed the target outright at +7.76σ, confirming the mechanism: WD must be frontloaded.
- **Trial breakdown (all 4, no cherry-picking):**
  | Trial | best_val_loss | ffs |
  |-------|---------------|-----|
  | 0 (okae8f06) | 3.26758 | 3100 |
  | 1 (okae8f06) | 3.26917 | 3100 |
  | 2 (okae8f06) | 3.26766 | 3100 |
  | 3 (okae8f06) | 3.26738 | 3100 |
  | **mean** | **3.267948** | **3100** |
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  pip install -r requirements.txt && \
  python data/cached_fineweb10B.py 20 && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --soap_attn \
    --lr_mlp 0.055 \
    --wd_schedule ramp_down \
    --wandb_name "baseline-wd-rampdown-n4" \
    --wandb_group "baselines"
```

---

## 2026-05-17 12:42 UTC — PR #162: Per-group LR: lr_mlp=0.055 (sweep + n=6 confirm)

- **Primary metric:** `speedrun/final_first_step_to_target` = **3141.67** (mean, n=6); best seed=**3125** (2/6 trials)
- **val/loss (mu):** **3.271362** (std=0.001181, SE=0.000482)
- **n:** 6 seeds, `train_steps=3250`
- **Statsig margin:** `(3.273735 − 3.271362) × √6 = 0.005813 ≥ 0.004` ✅ PASS (1.45× headroom)
- **New merge statsig rule:** `(3.271362 - mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ 3.269362 for n=4, ≤ 3.269729 for n=6, ≤ 3.269948 for n=8
- **vs previous baseline (PR #116):** Δmu = −0.002373, Δffs = −8.33 steps (mean)
- **W&B runs:** `t1jfegcf` (n=4 confirm, group `g1r5-edward/per-group-lr-confirm`), `3j8v4owb` (n=2 ext, same group)
- **Student:** g1r5-edward
- **What changed:** Per-group LR differentiation — `lr_mlp=0.055` for MLP-SOAP, `lr_attn=0.035` for attn-SOAP (both previously 0.035). Clean inverted-U peak at lr_mlp=0.055 in n=1 screen (A=3.278/3200, B=3.276/3175, C=3.271/3125, **D=3.270/3125**, E=3.272/3150). n=4 confirmed mean=3.271763, n=6 extension cleared with mean=3.271362.
- **Trial breakdown (all 6, no cherry-picking):**
  | Trial | best_val_loss | ffs |
  |-------|---------------|-----|
  | 0 (t1jfegcf) | 3.27025 | 3125 |
  | 1 (t1jfegcf) | 3.27237 | 3150 |
  | 2 (t1jfegcf) | 3.27283 | 3150 |
  | 3 (t1jfegcf) | 3.27161 | 3150 |
  | 4 (3j8v4owb) | 3.26978 | 3125 |
  | 5 (3j8v4owb) | 3.27133 | 3150 |
  | **mean**      | **3.271362** | **3141.67** |
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  pip install -r requirements.txt && \
  python data/cached_fineweb10B.py 20 && \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 6 \
    --soap_attn \
    --lr_mlp 0.055 \
    --wandb_name "baseline-per-group-lr-mlp055-n6" \
    --wandb_group "baselines"
```

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
