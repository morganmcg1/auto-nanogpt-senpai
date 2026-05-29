# SENPAI Baselines — auto-nanogpt-1gpu-r5

Ordered chronologically. Compare new results against the **most recent entry**.

## 2026-05-29 — PR #1533: EMA-eval (SWA-style) with bias correction, d=0.99 (alphonse) — n=4 confirm — **FFS-PRIMARY MERGE**

- **Primary metric (FFS-primary per directive #1262):** `speedrun/final_first_step_to_target` (EMA-corrected) μ_4 = **2912.5** (σ_4 = 25.0; min/max = 2875/2925)
- **val/loss train-traj (μ_4):** **3.269600** (σ_4 = 0.001013)
- **val/ema_loss_corrected (μ_4):** **3.270113** (σ_4 = 0.001005)
- **Δ vs PR #1381 baseline (μ_4(FFS)=2943.75, σ_4=12.5):**
  - **ΔFFS = −31.25 steps** (2943.75 → 2912.5) — −1.06%
  - Within-run gain per trial: 0 / −25 / −50 / −25 steps (direction-consistent across all 4)
  - σ_4 inflates to 25 vs baseline 12.5 (structural: EMA-eval adds per-trial FFS variance on top of train FFS variance)
- **n:** 4 seeds (W&B run `axzk5hpf`, group `g1r5-alphonse/ema-eval-swa-confirm`)
- **Trial breakdown (all 4, no cherry-picking):**

  | Trial | FFS_ema_corr | FFS_train | val/loss_train | val/ema_corr |
  |------:|-------------:|----------:|---------------:|-------------:|
  | 0 | 2925 | 2925 | 3.26905 | 3.26957 |
  | 1 | 2925 | 2950 | 3.27039 | 3.27089 |
  | 2 | **2875** | 2925 | 3.26845 | 3.26897 |
  | 3 | 2925 | 2950 | 3.27051 | 3.27102 |
  | **μ_4** | **2912.5** | 2937.5 | **3.269600** | 3.270113 |

- **What changed:** Added `--ema_eval_decay 0.99` flag. During training, a bias-corrected EMA of the parameter trajectory is maintained (Option A: exact correction using stored `init_state` fp32 snapshot). At each val step, the corrected EMA params are swapped in for evaluation, recovering the `speedrun/first_step_to_target` crossing at the corrected EMA val. FFS is now measured on the EMA-eval trajectory. Mechanism: SWA-style averaging of cooldown-phase param iterates yields a val_loss systematically ~0.012–0.015 below the train-val near the 3.28 crossing, giving −25 mean within-run FFS gain. The cosine cooldown (#1381) already absorbed ~75% of the linear-cooldown stack's SWA signal (−100 steps on pre-#1381 stack → −25 on post-#1381).
- **New merge statsig rule (FFS-primary, EMA-eval as primary metric):** Future PRs must beat μ_4(FFS_ema) = 2912.5. Note σ_4(FFS_ema) = 25 (wider than prior σ_4=12.5 baselines due to structural EMA-FFS variance) — use pooled SE when evaluating significance.
- **W&B run:** `axzk5hpf` (group `g1r5-alphonse/ema-eval-swa-confirm`)
- **Student:** g1r5-alphonse
- **Mandatory stack now includes:** `--ema_eval_decay 0.99`
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --wandb_name "g1r5-alphonse/ema-eval-d0.99-n4-confirm-post1381" \
    --wandb_group "g1r5-alphonse/ema-eval-swa-confirm"
```

---

## 2026-05-28 09:11 UTC — PR #1381: Cosine cooldown LR-decay shape (alphonse) — n=4 confirm — **FFS-PRIMARY MERGE**

- **Primary metric (FFS-primary per directive #1262):** `speedrun/final_first_step_to_target` μ_4 = **2943.75** (σ_4 = 12.5; 4/4 trials FFS-alive ≤ 2950; min/max = 2925/2950)
- **val/loss (μ_4):** **3.270215** (σ_4 = 0.000272; min/max = 3.26993/3.27057)
- **Δ vs PR #699 baseline:**
  - **ΔFFS = −81.25 steps** (3025 → 2943.75) — −2.69%
  - Δval = +0.008994 (+15.17·σ_single) — structural Pareto cost confirmed by #1481 sweep across cdf ∈ {0.3, 0.4, 0.5, 0.6, 0.7}; FFS monotone-NEG with shorter cdf, no Pareto-dominant alternative exists
- **n:** 4 seeds (single W&B run `suc03s6j`, group `g1r5-alphonse/cooldown-lr-decay-shape`)
- **What changed:** Added `--lr_cooldown_shape cosine` to the mandatory R5 stack. Replaces the linear LR cooldown (default) with cosine `0.5·(1 + cos(π·x))` during the cooldown window (last cdf=0.7 of training). Mechanism: cosine front-loads the model into the low-LR regime — at x=0.857 cosine_eta=0.05 vs linear_eta=0.143 — advancing the 3.28 crossing (FFS) by ~80 steps but at the cost of fewer steps in mid-eta descent (val regresses ~+0.009).
- **Cross-PR mechanism corroboration:** fern #1385 Cell B (full-run cosine, n=1) hit FFS=2925 independently, matching alphonse #1381 Cell B (n=1) and confirming the cluster mechanism "directed descent through low-LR regime is FFS-load-bearing".
- **Closures crystallized by this merge:**
  - #1481 closed (32nd) — cooldown_frac axis Pareto-exhausted, cdf=0.7 locally optimal
  - Cosine FFS gain is jointly (shape × cdf=0.7), not portable to other cdf values
- **Statsig (FFS-primary regime):** ΔFFS = 81.25 steps with σ_4(FFS) = 12.5; effect size = 6.5·σ_4. Compare to baseline σ_4(FFS) = 0 (all 4 baseline trials at FFS=3025) → clean detection.
- **W&B run:** `suc03s6j` (group `g1r5-alphonse/cooldown-lr-decay-shape`)
- **Student:** g1r5-alphonse
- **Trial breakdown (all 4, no cherry-picking):**

  | Trial | FFS | val/loss@3250 |
  |------:|---:|---:|
  | 0 | 2950 | 3.27057 |
  | 1 | 2950 | 3.27010 |
  | 2 | 2925 | 3.26993 |
  | 3 | 2950 | 3.27026 |
  | **μ_4** | **2943.75** | **3.270215** |

- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --wandb_name "g1r5-alphonse/cd-shape-cosine-n4-confirm" \
    --wandb_group "g1r5-alphonse/cooldown-lr-decay-shape"
```

- **New merge statsig rule (FFS-primary):** Future PRs must beat μ_4(FFS) = 2943.75 with σ_4 ≤ ~12.5 — i.e., need μ_4(FFS) ≤ ~2918.75 with comparable spread for confident detection. Val/loss is secondary; regressions on the +15σ_single axis (from previous baseline 3.261221) are now in the "structural Pareto cost" regime per #1481.
- **First FFS-positive merge of R5** in 32 closure attempts. The mandatory stack now includes `--lr_cooldown_shape cosine`.

---

## 2026-05-22 10:27 UTC — PR #699: Depth-aware μP init for block residual paths (musoft) — n=4 confirm

- **Primary metric:** `speedrun/final_first_step_to_target` = **3025** (ALL 4 trials at ffs=3025; −18.75 steps vs PR #571)
- **val/loss (mu):** **3.261221** (sample std=0.000593, SE=0.000297)
- **n:** 4 seeds (P2 confirm run `zp6gvwv5`, all 4 trials in single torchrun, group `g1r5-alphonse/depth-aware-init-P2-confirm`)
- **Statsig:** `(3.263265 − 3.261221) × √4 = 0.002044 × 2 = 0.004088 ≥ 0.004` ✅ PASS (+0.000088 margin)
- **New merge statsig rule:** `(3.261221 − mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ **3.259221** for n=4, ≤ **3.259588** for n=6, ≤ **3.259807** for n=8
- **vs previous baseline (PR #571):** Δmu = −0.002044 (−1.82σ_single / −3.64σ_SE), Δffs = −18.75 steps
- **W&B run:** `zp6gvwv5` (group `g1r5-alphonse/depth-aware-init-P2-confirm`)
- **Student:** g1r5-alphonse
- **What changed:** Added `--depth_init_mode musoft` CLI flag. Block residual injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) initialized to N(0, std) with `std = sqrt(0.33) / sqrt(fan_in × L)` instead of the previous zero-initialization. At L=12, fan_in=768: std ≈ 0.006 (≪ other 2D weights at ~0.019). The μP 1/√L scaling provides each block a small non-zero starting signal that allows gradient flow through the residual path from step 1, without overpowering the trained directions. Zero-init remains for the lm_head (`model.proj.weight`) and all other non-block parameters. The mechanism is orthogonal to Muon's spectral direction: init sets the starting basin, Muon constrains the update direction.
- **Trial breakdown (all 4, no cherry-picking):**
  | Trial | step boundary | val/loss | ffs |
  |------:|:-------------:|---------:|----:|
  | 1 | 3250 | **3.260513** | 3025 |
  | 2 | 6501 | 3.261771 | 3025 |
  | 3 | 9752 | 3.261646 | 3025 |
  | 4 | 13003 | **3.260954** | 3025 |
  | **mean** | | **3.261221** | **3025** |
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --soap_attn \
    --lr_mlp 0.055 \
    --wd_schedule ramp_down \
    --ns_iter 6 \
    --lr_scalars 0.03 \
    --depth_init_mode musoft \
    --wandb_name "baseline-musoft-depthinit-n4" \
    --wandb_group "baselines"
```

---

## 2026-05-21 04:22 UTC — PR #571: lr_scalars=0.03 (RMSNorm gain LR 3× higher) — n=4 confirm

- **Primary metric:** `speedrun/final_first_step_to_target` = **3043.75** (mean, n=4); 3/4 trials at ffs=3050, 1/4 at ffs=3025
- **val/loss (mu):** **3.263265** (sample std=0.001123, SE=0.000562)
- **n:** 4 seeds (P2 confirm run `apz56jxx`, all trials in single torchrun)
- **Statsig:** `(3.266120 − 3.263265) × √4 = 0.005710 ≥ 0.004` ✅ PASS (+0.001710 margin, 1.43× headroom)
- **New merge statsig rule:** `(3.263265 − mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ 3.261265 for n=4, ≤ 3.261633 for n=6, ≤ 3.261852 for n=8
- **vs previous baseline (PR #497):** Δmu = −0.002855 (−1.63σ_single / −5.08σ_n=4 SE), Δffs = −43.75 steps (~1.4% faster)
- **W&B runs:** `apz56jxx` (P2 n=4 confirm, group `g1r5-askeladd/scalar-lr-P2-d-confirm`); standalone sweep in group `g1r5-askeladd/scalar-lr-sweep` (runs `aw6cq08g` ctrl, `xcxu2ziv` Cell D n=1)
- **Student:** g1r5-askeladd
- **What changed:** AdamW `adam_scalars` group LR raised from hardcoded 0.01 to `--lr_scalars 0.03` (3× increase). This group covers only ~20K params (RMSNorm gains across 12 layers). Historical lr=0.01 was under-tuned — at 3× higher, gains track optimal per-layer output scale faster during the main training phase. Asymmetric axis: lower direction (0.001/0.003) is catastrophic (+13σ/+7σ), upper direction peaks at 3× and regresses at 10×. Sample std (0.001123) is tighter than previous baseline σ=0.001747, indicating the configuration is slightly more stable. All 4 fresh seeds independently clear the n=4 gate.
- **Trial breakdown (all 4, no cherry-picking):**
  | Trial | val/loss | ffs |
  |-------|----------|-----|
  | 0 (apz56jxx) | 3.26347 | 3050 |
  | 1 (apz56jxx) | 3.26401 | 3050 |
  | 2 (apz56jxx) | 3.26162 | 3025 |
  | 3 (apz56jxx) | 3.26396 | 3050 |
  | **mean** | **3.263265** | **3043.75** |
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --soap_attn \
    --lr_mlp 0.055 \
    --wd_schedule ramp_down \
    --ns_iter 6 \
    --lr_scalars 0.03 \
    --wandb_name "baseline-lr-scalars-003-n4" \
    --wandb_group "baselines"
```

---

## 2026-05-20 06:55 UTC — PR #497: ns_iter=6 (Newton-Schulz iterations reduced) — n=6 confirm

- **Primary metric:** `speedrun/final_first_step_to_target` = **3087.5** (mean, n=6); 4/6 trials at ffs=3075
- **val/loss (mu):** **3.266120** (sample std=0.001747, SE=0.000713)
- **n:** 6 seeds across two torchrun invocations (n=4 base + n=2 extension)
- **Statsig:** `(3.267948 − 3.266120) × √6 = 0.001828 × 2.449 = 0.004478 ≥ 0.004` ✅ PASS (+0.000478 margin)
- **New merge statsig rule:** `(3.266120 − mu) × sqrt(n) ≥ 0.004`
  → need mu ≤ 3.264120 for n=4, ≤ 3.264488 for n=6, ≤ 3.264707 for n=8
- **vs previous baseline (PR #371):** Δmu = −0.001828 (−2.22σ), Δffs = −12.5 steps (mean)
- **W&B runs:** `ues3hmz1` (n=4 base, group `g1r5-askeladd/ns-iter-6-P2-n4`), `n0vch666` (n=2 extension, same group)
- **Student:** g1r5-askeladd
- **What changed:** Newton-Schulz orthogonalization iterations reduced from 12 (hardcoded) to 6 via `--ns_iter 6` CLI flag. In bfloat16 precision, 6 iterations saturates orthogonality; the previous 12-iteration default was over-iterating and adding unnecessary optimizer micro-step noise. Wall-clock: ~42 ms/step faster than ns_iter=12 (step time 1910 ms vs 1952 ms). The mechanism is consistent with the broader "less optimizer intensity in late phase" theme (PR #371 WD ramp_down to 0, stable_only WD pattern).
- **Trial breakdown (all 6, no cherry-picking):**
  | Trial | val/loss | ffs |
  |-------|----------|-----|
  | T1 (ues3hmz1) | 3.26566 | 3075 |
  | T2 (ues3hmz1) | 3.26957 | 3125 |
  | T3 (ues3hmz1) | 3.26493 | 3075 |
  | T4 (ues3hmz1) | 3.26498 | 3075 |
  | T5 (n0vch666) | 3.26611 | 3100 |
  | T6 (n0vch666) | 3.26547 | 3075 |
  | **mean** | **3.266120** | **3087.5** |
- **Reproduce:**

```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --soap_attn \
    --lr_mlp 0.055 \
    --wd_schedule ramp_down \
    --ns_iter 6 \
    --wandb_name "baseline-ns-iter-6-n4" \
    --wandb_group "baselines"
```

---

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
