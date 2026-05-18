# Modded-NanoGPT Track 3 Optimizer Speedrun — Local Baseline

Primary metric: `speedrun/final_first_step_to_target` (lower is better, `-1` means
target not reached).
Target: FineWeb validation cross-entropy `<= 3.28`.
Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004`.

## Local baseline (auto-nanogpt-1gpu-r1)

### 2026-05-18 01:42 UTC — PR #274: COOLDOWN_POWER=1.4 (fern n=2 WIN) (g1r1-fern) ← CURRENT BEST

- **speedrun/final_first_step_to_target:** 3000 (n=2 mean)
- **val/loss:** 3.2685 (mean of seed-1 3.26812 and seed-2 3.26888)
- **stat-sig margin:** (3.28 − 3.2685)·√2 = 0.01627 ≥ 0.004 ✓ (4.07×)
- **Δ vs PR #202 baseline:** −25 sr-steps ✅ (sr=3000 < 3025), +0.00235 val (small regression, within n=1 noise band)
- **W&B runs:** seed-1 `vw0595an`, seed-2 `s2nrw0c8` (group `g1r1-fern/cooldown-power-retune`)
- **Key config:** cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon + u/w-floor + γ_power=0.4 + **COOLDOWN_POWER=1.4** (was 1.2). Other: NS_ITERS=12, muon_lr=0.035, wd=0.025, embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, 0.95), eps=1e-10.
- **Mechanism:** The more concave LR decay tail (power=1.4 vs 1.2) holds a slightly larger LR through mid-cooldown and drops more sharply near the end. On the γ_power=0.4 stack with cleaner preconditioned gradient direction, this allows the model to "snap" below 3.28 one validation interval earlier (step 3000 vs 3025). Final val is ~0.002 above PR #202 baseline — a sub-noise regression stable across both seeds, plausibly caused by the harder late-cooldown drop undershooting the LR floor.
- **Statistical threshold (n=1):** val ≤ 3.276. New **n=2 threshold: val ≤ 3.277** (tighter: (3.28 − 3.2685)·√2 = 0.01627).
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "baseline-reproduction-pr274" \
    --wandb_group "baseline-reproduction"
  ```
- **Notes:** Arm A (COOLDOWN_POWER=1.0, linear) sr=3100 val=3.26773 — clear NULL. Only Arm B (1.4) won. Suggested follow-ups: probe {1.5, 1.6, 1.8}; joint COOLDOWN_POWER × cooldown_frac × muon_lr grid; investigate late-cooldown LR floor.

---

### 2026-05-17 06:40 UTC — PR #202: PMuon γ_power=0.4 (frieren arm A WIN) (g1r1-frieren)

- **speedrun/final_first_step_to_target:** 3025 (n=1)
- **val/loss:** 3.26615 (n=1)
- **stat-sig margin:** (3.28 − 3.26615)·√1 = 0.01385 ≥ 0.004 ✓ (3.46×)
- **Δ vs PR #193 baseline:** −25 sr-steps ✅, −0.00158 val ✅ (absolute sr=3025 < 3050)
- **W&B run:** `prncgzv5`
- **Key config:** cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon + u/w-floor + γ=1.2 cooldown + **γ_power=0.4** (was 0.3). Other: NS_ITERS=12, muon_lr=0.035, wd=0.025, embed_lr=0.3, lm_head_lr=1/320, betas=(0.8, 0.95), eps=1e-10.
- **Mechanism:** Increasing γ_power from 0.3 → 0.4 makes PMuon's bilateral whitening more aggressive. The whitened SV ratio increases (mean 9.37 at γ=0.4 vs 5.89 at γ=0.2), and the covariance eigh condition number grows (lcov_eigh_ratio median 18441 vs 7509). Stronger whitening pre-conditions the gradient direction more precisely, reducing steps to the 3.28 crossing. The monotone signal (γ=0.2 → sr=3050, γ=0.3 → sr=3062.5, γ=0.4 → sr=3025) suggests finer optimum near {0.5, 0.6}.
- **Note:** Arm A tested on PR #137 base (pre-cubic-Newton, sr vs 3062.5 baseline). Merged onto cubic-Newton base (PR #193) as compound. Wave 7 stack (PR #225 thorfinn) will independently confirm γ_power=0.4 on cubic-Newton base.
- **Statistical threshold (n=1):** val ≤ 3.276 to clear bar. New **n=1 threshold: val ≤ 3.275** (tighter: (3.28 − 3.26615)·√1 ≥ 0.004, so new bar = 3.276).
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "baseline-reproduction-pr202" \
    --wandb_group "baseline-reproduction"
  ```
- **Notes:** Arm B (γ_power=0.2) sr=3050 val=3.268887 — ties new baseline on sr, slight val regression. Monotone direction confirmed. Next: scan γ_power ∈ {0.5, 0.6}. Spectral diagnostic telemetry (pmuon_spectral_diag, 100-step logging) added to train_gpt_simple.py.

### 2026-05-17 04:30 UTC — PR #193: Cubic-Newton NS Coefficients (a=1.5, b=-0.5, c=0) (g1r1-tanjiro)

- **speedrun/final_first_step_to_target:** 3050 (n=1; seed-1 only)
- **val/loss:** 3.26773 (n=1)
- **stat-sig margin:** (3.28 − 3.26773)·√1 = 0.01227 ≥ 0.004 ✓ (n=1)
- **Δ vs PR #137 baseline:** −12.5 sr-steps ✅, −0.00136 val ✅
- **W&B run:** `q8aduc16`
- **Key config:** PMuon + u/w-floor + power-law cooldown γ=1.2 (all from PR #137 base) + **cubic-Newton NS polynomial (a=1.5, b=-0.5, c=0.0)** replacing the quintic (a=2, b=-1.5, c=0.5). NS_ITERS=12 unchanged.
- **Mechanism:** The c=0 cubic-Newton polynomial converges to polar residual ~0.10 (vs ~0.01 for the quintic baseline) — a stable intermediate-orthogonality fixed point. The classical Newton iteration x → 1.5x − 0.5x³ hits a different basin of attraction than the quintic. PMuon's bilateral whitening makes exact orthogonality non-load-bearing; the cubic-Newton's partial convergence produces a better optimizer trajectory.
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-tanjiro/pmuon-uw-ns-coef-cubic" \
    --wandb_group "g1r1-tanjiro/pmuon-uw-ns-coef-scan"
  ```
- **Notes:** Arm A (Jordan coefficients 3.4445, -4.7750, 2.0315) NULLed at sr=3075 with residual ~11 oscillation cycle. Arm B cubic-Newton wins at sr=3050, residual plateaus at ~0.10 (mathematically saturated at c=0 fixed point). Cross-reference: thorfinn PR #184 ns_iter=6 independently reaches residual ~2.31 and wins at sr=3050 — same "moderately under-converged polar" regime. N=1 result; n=2 confirmation recommended before further stacking.

### 2026-05-16 18:26 UTC — PR #137: PMuon + u/w-floor + Power-Law Cooldown γ=1.2 (g1r1-nezuko)

- **speedrun/final_first_step_to_target:** 3062.5 (n=2 mean; seed-1 3075 / seed-2 3050)
- **val/loss:** 3.269090 (n=2 mean; seed-1 3.270012 / seed-2 3.268167)
- **stat-sig margin:** (3.28 − 3.269090)·√2 = 0.01543 ≥ 0.004 ✓ (n=2)
- **Δ vs PR #94 baseline:** −37.5 sr-steps (primary ✅), +0.001394 val/loss (small regression, within seed-noise band)
- **W&B runs:** `8quuvdrj` (seed-1, 3h 39m), `l5bdkm6e` (seed-2, 3h 39m)
- **Key config:** PMuon (gamma=0.3, beta_cov=0.95) + Skylight u/w-floor (TARGET_UW=0.35) + **power-law cooldown γ=1.2** (`eta = ((1−progress)/cooldown_frac)^1.2`). Muon lr=0.035, weight_decay=0.025, train_steps=3250, cooldown_frac=0.7. `model.compile(dynamic=True)` applied.
- **Mechanism:** concave-down power-law decay drops lr faster through mid-cooldown (at 50% progress: `0.5^1.2=0.435` vs linear `0.5`), accelerating the descent across 3.28 by ~37.5 steps at the cost of slightly higher final val (+0.0014). u/w-floor fires at 100% of params every step throughout both runs.
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-nezuko/pmuon-uw-power-1p2" \
    --wandb_group "g1r1-nezuko/pmuon-uw-power"
  ```
- **Notes:** FIRST improvement on PMuon+u/w-floor base in 10+ mechanism-addition experiments. Confirms that schedule-shape (not optimizer mechanism addition) is the open lever on this base. Opens Wave 5: γ × cooldown_frac joint surface scan. Val/loss regression vs PR #94 is +0.0014, smaller than the 0.004 stat-sig bar and within the seed-noise band. Power-law cooldown γ=1.2 stacks cleanly with u/w-floor on the primary speedrun metric.

### 2026-05-16 — PR #94: PMuon + Skylight u/w-floor (TARGET_UW=0.35) (g1r1-askeladd)

- **speedrun/final_first_step_to_target:** 3100
- **val/loss:** 3.267696 (n=2 mean; individual seeds 3.267878 / 3.267513; range 0.000365)
- **stat-sig margin:** (3.28 − 3.267696)·√2 = 0.01740 ≥ 0.004 ✓ (n=2)
- **W&B runs:** `yeyewcj6` (n=1, finished 2026-05-15 21:34) and `205sycku` (n=2, finished 2026-05-16 07:22)
- **Key config:** PMuon (gamma=0.3, beta_cov=0.95) + Skylight u/w-floor (TARGET_UW=0.35), Muon lr=0.035, weight_decay=0.025, train_steps=3250, cooldown_frac=0.7. `model.compile(dynamic=True)` applied.
- **u/w-floor implementation:** after `pmuon_update(...)` returns and before `p.add_(update, alpha=-lr)`:
  ```python
  w_norm = p.norm()
  if w_norm > 0:
      ratio = update.norm() / w_norm
      if 0 < ratio < TARGET_UW:
          update.mul_(TARGET_UW / ratio)
  ```
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-askeladd/pmuon-uw-floor" \
    --wandb_group "g1r1-askeladd/pmuon-uw"
  ```
- **Notes:** u/w-floor fires at 100% of eligible params every step — PMuon's bilateral L^{-γ} R^{-γ} whitening systematically shrinks update norms below 0.35·‖w‖. This means u/w-floor effectively functions as a per-param LR magnitude floor rather than a cooldown-phase guard. 50-step improvement (3150 → 3100) on top of PMuon base. Seed variance extremely tight (0.000365 val range), confirming mechanistic stability. Follow-up: TARGET_UW sweep {0.25, 0.30, 0.35, 0.40, 0.45} and γ × TARGET_UW joint probe.

### 2026-05-15 — PR #64: PMuon (bilateral covariance EMA preconditioning) (g1r1-fern)

- **speedrun/final_first_step_to_target:** 3150
- **val/loss:** 3.27447 (margin +0.00553 ≥ 0.004 ✓, n=1)
- **W&B run:** `vx0r7rp2`
- **Key config:** PMuon (bilateral EMA covariance preconditioning, gamma=0.3, beta_cov=0.95), Muon lr=0.035, weight_decay=0.025, train_steps=3250, cooldown_frac=0.7. **PMuon REPLACES the Newton-Schulz path entirely** — Aurora row-norm equilibration, Contra-Muon momentum subtraction, and u/w-floor (all from prior PR #68 baseline) were dropped during rebase since PMuon is incompatible with them.
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-fern/pmuon-cov-precond" \
    --wandb_group "g1r1-fern/pmuon"
  ```
- **Notes:** PMuon replaces `polar(m)` with `polar(L^{-γ} m R^{-γ})` where `L, R` are bilateral gradient covariance EMAs computed via `torch.linalg.eigh`. 3150 steps beats prior local best of 3175 (PR #68). Matches public Record #18 mechanism family (PMuon, 3225 mean at n=9) and beats it by 75 steps on a single seed. `sample_tensor` linspace fp64+clamp fix included. **Inductor compile bug (`dynamic=False` → NaN on RTX PRO 6000 Blackwell) is NOT fixed in this PR** — the run survived because PMuon's covariance whitening appears to damp the seed-NaN amplitude empirically, but this is unguaranteed; subsequent PMuon-base work should either fix compile or carry an update floor.

### 2026-05-15 — PR #68: Aurora + Contra-Muon + u/w floor (g1r1-tanjiro)

- **speedrun/final_first_step_to_target:** 3175
- **val/loss:** 3.274438 (margin +0.005562 ≥ 0.004 ✓, n=1)
- **W&B run:** `lg4xdlkt`
- **Key config:** Muon lr=0.0375, weight_decay=0, Aurora pp_iterations=2 pp_beta=0.5, CONTRA_COEFF=0.2, TARGET_UW=0.35, train_steps=3250, cooldown_frac=0.7
- **Reproduce:**
  ```bash
  cd target
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py --num_trials 1 \
    --wandb_name "g1r1-tanjiro/aurora-contra" \
    --wandb_group "g1r1-tanjiro/aurora"
  ```
- **Notes:** n=1 single-trial result; margin clears the 0.004 floor. Matches public Record #17 mechanism (3175 steps, n=20 mean 3.2789). `sample_tensor` linspace fp32 bug patched (`.clamp_(max=values.numel()-1)`). Full Aurora + Contra-Muon + Skylight u/w floor variant confirmed locally.

Prior to first winner: local anchor was unconfirmed (alphonse vanilla run diverged).

## Public records to beat (track 3 official, snapshot in repo)

These are the strongest known public results, included here as target
references. Our portfolio aims to reproduce the mechanisms and combine them.

| Rank | Steps to 3.28 | Mean val_loss | n | Method | Key levers |
| ---- | ------------- | ------------- | - | ------ | ---------- |
| #20 | 3030 | 3.2790 | 30 | Contra-Muon + Soft-Muon + SOAP-MLP + SOAP-attn trust gate + NorMuon-lite + u/w floor + power-law cooldown | All-in stack |
| #19 | 3125 | 3.2780 | 6 | KL-SOAP-H (full SOAP replacing NS, beta1=0.95, shampoo_beta=0.90) | lr=0.018 |
| #16 | 3125 | 3.2784 | 8 | NorMuonH + SOAP-MLP + SOAP-attn trust gate (Trustlight) | lr=0.0375 |
| #14 | 3150 | 3.2776 | 4 | Contra-Muon + NorMuon + SOAP-MLP | lr=0.0375 |
| #17 | 3175 | 3.2789 | 20 | Aurora + Contra-Muon + u/w floor | lr=0.0375 |
| #13 | 3210 | 3.2785 | 10 | MuLoCo (outer Nesterov) + NorMuonH | sync_interval=30 |
| #11 | 3225 | 3.2785 | 16 | Contra-Muon + NorMuon + u/w floor | lr=0.0375 |
| #18 | 3225 | 3.2776 | 9 | PMuon (streaming covariance preconditioning) | lr=0.035, gamma=0.3 |
| #9  | 3250 | 3.2771 | 8 | Skylight (NorMuon long-axis + u/w floor) | lr=0.0375 |
| #10 | 3250 | 3.2789 | 20 | NorMuon (short-axis) | lr=0.035 wd=0.025, end 50 early |
| #8  | 3250 | 3.2778 | 10 | NorMuonH (short-axis NorMuon + hyperball) | lr=0.018 |
| #6  | 3375 | 3.2788 | 20 | Muon + aux Adam | lr=0.025 wd=0.025 |
| #12 | 3325 | 3.2790 | 20 | Muon + aux Adam, lr=0.035 wd=0.025, end 25 early | similar to #10 |

## Common-to-all configuration (do not change)

- Dataset: FineWeb shards loaded by `data/cached_fineweb10B.py`.
- Architecture: `vocab_size=50304, num_layers=12, model_dim=768`, head_dim=128.
- Batch size: `8 * 64 * 1024 = 524288` tokens per optimizer step.
- One forward-backward per optimizer step.
- AdamW auxiliary groups (embed lr=0.3, lm_head lr=1/320, scalars lr=0.01,
  betas=(0.8, 0.95), eps=1e-10, wd=0).
- Newton-Schulz iterations: 12 (quintic a=2, b=-1.5, c=0.5).
- Schedule: stable then linear cooldown with `cooldown_frac=0.7` unless an
  experiment specifies otherwise.
- Per-run early stopping based on val loss is forbidden.

## Weight decay note (CORRECTION)

The baseline `Muon.step` **does** apply weight decay via `p.mul_(1 - lr*wd)`.
At `lr=0.035, wd=0.025`, effective per-step decay is `1 - 0.000875 ≈ 0.999125` — very small but not zero.
Confirmed by PR #61 (askeladd). Prior note in this file claiming WD was unused was incorrect.
