# RESEARCH IDEA — nezuko 2026-06-02 01:30Z

## Hypothesis: `logit-cap-cooldown-schedule`

Schedule the **logit softcap value** during cooldown. Currently hardcoded as `cap=15` at line 499 of `train_gpt_simple.py`. Test whether the optimal cap value shifts across progress, by linearly ramping `cap` from 15 to a target value across the cooldown phase (steps ~975-3250).

## Mechanism

The forward pass applies a tanh-like saturation: `logits = 15 * logits * (logits.square() + 15**2).rsqrt()` at line 499. This caps the absolute magnitude of pre-softmax logits to approximately ±15, acting as a smooth regularizer on output confidence.

Static cap-value sweep is CLOSED (PR #2080 + #2118):

| cap | 10 | 12.5 | **15** | 17.5 | 30 | 50/∞ |
|---|---:|---:|---:|---:|---:|---:|
| FFS_ema | 2975 | 2875 | **2875** | 2925 | 3050 | 3050 |
| Δval | +0.00564 | +0.00172 | **0** | +0.00227 | +X | +X |

The static basin is asymmetric: wide-flat on the down-side (12.5-15 both at attractor), tightening on the up-side (17.5 already +50 FFS).

**But the question of whether cap=15 is also the optimum AT EVERY PROGRESS step has never been tested.** Specifically: during cooldown, the model becomes increasingly confident — peak logit magnitudes naturally grow toward the cap. The optimal cap MIGHT shift:
- **Loosening** (cap→20) during cooldown: gives the model room to express the legitimate high-confidence predictions it has earned. Could accelerate FFS by reducing saturation-induced gradient damping when most predictions are correct.
- **Tightening** (cap→10) during cooldown: enforces conservative outputs as model converges, prevents overconfidence-driven memorization. Analogous to wd_schedule ramp_down (merged) — regularization grows during cooldown.

This is structurally analogous to the merged mu_cooldown_target ramp (PR #1966): a static U-shape local optimum can still benefit from a progress-dependent schedule when the underlying mechanism shifts across training phases.

## Novelty verification (zero prior R5 hits)

- `gh search prs ... "logit cap schedule"`: 0 hits
- `gh search prs ... "softcap cooldown"`: 0 hits
- `gh search prs ... "dynamic logit"`: 0 hits
- `gh search prs ... "tau schedule"`: 0 hits

Logit softcap **value** sweep is closed (#2080 static {15,30,50}; #2118 static {15,12.5,10}), but **schedule** axis is untouched.

## Memory-rule compliance (passes all 8 closed families)

1. `[[warmup_mu_ramp_axis_closed_at_r5]]` — operates ONLY during cooldown (progress ≥ 0.30 once `cooldown_frac` triggers), not in NS5-absorbed regime. ✓
2. `[[adamw_aux_tetrad_fully_closed_at_r5]]` — touches forward pass / loss-side, not AdamW. ✓
3. `[[ns5_absorbs_2d_weight_init_perturbations_at_r5]]` — not weight init, not pre-NS5, not post-NS5. Loss-side mechanism downstream of all gradient-history. ✓
4. `[[sgld_annealed_noise_pre_ns_family_neg_at_r5]]` — not additive pre-NS5. ✓
5. `[[sf_polyak_cooldown_freeze_failure]]` — not Polyak/SF/averaging. ✓
6. `[[ns5_internal_eps_irrelevant_at_r5_gradient_scale]]` — touches forward-pass logit magnitude, not NS5 internal ε. ✓
7. `[[ln_gain_init_below_one_ffs_neg_at_r5]]` — not LN gain. ✓
8. `[[r5_n1_to_n4_reversion_dual_metric_attractor]]` — design includes n=4 escalation cell E. ✓

## Code site and implementation (~12 LOC)

**File:** `records/track_3_optimization/train_gpt_simple.py`

Current code (line 499):
```python
logits = 15 * logits * (logits.square() + 15**2).rsqrt()
```

### Step 1 — argparse flag (~2 LOC)
```python
parser.add_argument("--logit_cap_cooldown_target", type=float, default=None,
    help="If set, linearly ramp logit softcap from 15 to this value across cooldown. "
         "None = constant cap=15 (default).")
```

### Step 2 — make cap a model attribute (~2 LOC in GPT.__init__)
```python
self.cap = 15.0  # default; updated by set_hparams if scheduled
```

### Step 3 — replace hardcoded 15 in forward (line 499)
```python
logits = self.cap * logits * (logits.square() + self.cap**2).rsqrt()
```

### Step 4 — schedule block in set_hparams() (~8 LOC, after existing cooldown blocks ~line 948)
```python
if args.logit_cap_cooldown_target is not None:
    if progress < 1 - cooldown_frac:
        cap_sched = 15.0  # stable phase: unchanged
    else:
        x = (progress - (1 - cooldown_frac)) / cooldown_frac
        cap_sched = 15.0 + (args.logit_cap_cooldown_target - 15.0) * x
    model.cap = cap_sched
```

Note: `set_hparams()` already receives `model` reference for similar attribute updates; if not, pass it in.

### Step 5 — W&B log (~3 LOC, in telemetry block)
```python
if args.logit_cap_cooldown_target is not None:
    wandb.log({"train/logit_cap": model.cap}, step=step, commit=False)
```

**Total: ~15 LOC including telemetry. Zero torch.compile concerns** — the logits computation is dynamic shape-friendly.

## Experimental cells (5 cells)

Use `--wandb_group nezuko/logit-cap-cooldown-schedule` for all runs.

Mandatory baseline stack (do NOT change these flags):
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
--ema_eval_decay 0.99
```
(`mu_cooldown_target=0.80` is the code default per PR #2071 cleanup.)

### Cell A — control (no schedule, mandatory baseline replication)
No new flag. Expected: FFS_ema ≈ 2875, FFS_trainval ≈ 2925, ema_val ≈ 3.270 (canonical attractor).

### Cell B★ (PRIMARY) — tighten cap during cooldown 15→10
```
--logit_cap_cooldown_target 10
```
Tests "regularize harder during convergence" hypothesis. Static cap=10 was FFS=2975 (worse); does cooldown-only application rescue?

### Cell C — loosen cap during cooldown 15→20
```
--logit_cap_cooldown_target 20
```
Tests "give confident model headroom" hypothesis. Static cap=17.5 was FFS=2925 (slightly worse); does cooldown-only application unlock confident-prediction-driven FFS?

### Cell D — aggressive tighten 15→7.5
```
--logit_cap_cooldown_target 7.5
```
Mechanism extreme. Tests where the response breaks.

### Cell E — n=4 confirm on best of B/C/D
Only run if any of B/C/D shows FFS_ema ≤ 2862.5 OR monotone-better ema_val at every probe step (1000, 1500, 2000, 2500, 3000, 3250) with FFS_trainval departure from canonical 2925.

## Merge gates (mandatory)

- **FFS-win:** μ_4(FFS_ema) ≤ 2862.5
- **Val-win at canonical FFS:** μ_4(FFS_ema) = 2875 ∧ μ_4(ema_val) ≤ 3.26507 (≥ 5×σ_4 below baseline 3.27007)

## Decision tree

After all 4 single-seed cells terminal:
1. If ANY cell hits FFS_ema ≤ 2862.5 OR shows dual-metric departure (FFS_trainval ≠ 2925 AND monotone-better ema_val): run Cell E n=4 confirm at that target.
2. If ALL cells canonical {2875, 2925, ema_val ∈ [3.270 ± 0.001]}: close as FFS-NEUTRAL, schedule axis flat.
3. Mechanism note: report W&B `train/logit_cap` trajectory and final-step peak `|logits|` magnitudes — informs whether the cap ever bites.

## Predicted outcomes

- **Most likely (60%):** FFS-NEUTRAL across all cells (static U-shape extends to schedule axis, model converges identically). Closes 114th R5 axis with mechanism note: logit cap is progress-invariant.
- **Plausible (25%):** Cell C (loosen 15→20) shows dual-metric departure — model exploits confidence headroom in cooldown. Triggers n=4 confirm. Possible val-win.
- **Possible (10%):** Cell B/D (tighten) shows departure via regularization mechanism analogous to wd_schedule ramp_down.
- **Surprise (5%):** Reveals an unexpected confidence-saturation interaction.

Either way, the closure is mechanism-rich: this is the first probe of progress-dependent loss-side regularization at R5.
