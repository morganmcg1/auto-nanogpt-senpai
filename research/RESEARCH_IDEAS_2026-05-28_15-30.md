# Research Ideas — 2026-05-28 15:30
# Wave: Post-Plateau, Second-Order / Joint-Coupling Tier
# Advisor branch: auto-nanogpt-1gpu-r4
# Baseline: val/loss=3.26310, FFS=3150 steps, n=3 (post-#1421)
# Primary metric: speedrun/final_first_step_to_target (FFS), lower is better
# Secondary: val_loss ≤ 3.28 threshold
# Statistical gate: (3.28 - mu) * sqrt(n) >= 0.004

## Context

At cycle 486, the R-buffer surface has been mapped along 9 confirmed catalog classes.
In-flight chains: #1538 (numerical-precision rsqrt vs pow), #1530 (warmstart α), #1543 (Tikhonov
diagonal regularization), #1567 (R-freeze), #1534 (cooldown-phase experiments).

Saturated axes (DO NOT REPEAT):
- α-power sweep: {0.333, 0.5, 0.667, 0.75} tested in #1360. NOT merged — α=0.25 and α=1.0 untested.
- Diagonal-only R: #1363 tested, confirmed NEG.
- Phase-split α (body vs cooldown): #1538 in-flight.
- Tikhonov γI floor: #1543 in-flight.
- R-freeze during cooldown: #1567 in-flight.
- Adaptive NS iteration count (spectral-residual): #1524 (nezuko wave prior) tested.
- Gradient noise throughout training: #1088 tested NEG.
- All prior wave 6 hypotheses (12 ideas): RULED OUT.
- All plateau13 hypotheses (6 ideas): RULED OUT.

Security constraint: Prime Intellect autonomous-run materials BANNED — no URLs under
primeintellect.ai/auto-nanogpt or github.com/PrimeIntellect-ai/experiments-autonomous-speedrunning.

---

## Hypothesis 1: R-Exponent Sweep — α=0.25 (Shampoo-like) and α=1.0 (Full Inverse)
**Slug:** NM-ALPHA-EXTENDED-SWEEP
**Student:** g1r4-fern

### Mechanistic story

Production Newton-Muon uses α=0.5, computing `R^{-0.5}` (symmetric square-root inverse). PR #1360
swept α ∈ {0.333, 0.5, 0.667, 0.75} but was NOT merged — the result file confirms these ran without
producing a winner. α=0.25 (quarter-power) and α=1.0 (full inverse) are genuinely untested.

α=0.25 is Shampoo-like: a weaker preconditioning that partially whitens inputs rather than fully
normalizing them. For modules where the input covariance eigenvalue spread is moderate (R_cond ~100-
1000), quarter-power preconditioning gives a softer step that may avoid over-correction in directions
where curvature estimates are noisy. This is the Shampoo exponent (Gupta et al. 2018, Anil et al.
2020) applied to the right factor only.

α=1.0 is the full Newton step: `R^{-1}` is the exact input-covariance inverse, making the precond
gradient equivalent to a natural gradient with respect to input distribution. This is aggressive —
condition numbers of 12K-2M (telemetry from #1538) mean the inverse amplifies small-eigenvalue
directions by up to 2M×. However, the EMA smoothing (β=0.95) and eigenvalue clamp (eps=1e-4) limit
blow-up. If the dominant bottleneck is under-conditioning in the low-eigenvalue directions (which
represent infrequent but informative input patterns), α=1.0 could accelerate convergence in those
directions.

The butterfly-effect mechanism (#1530) implies that even small changes to R^{-α} can compound into
large trajectory divergence. α=0.25 vs α=1.0 span a much larger range than the tested {0.333-0.75}
window, so signal is more likely even if the final outcome is NEG.

### Implementation

**One-line change in `_apply_newton_precondition`:**
```python
# Current (production):
inv_sqrt_vals = vals_clamped.rsqrt()   # α=0.5

# New: read env var at init time, store as self.newton_alpha
inv_sqrt_vals = vals_clamped.pow(-self.newton_alpha)
```

**In `Muon.__init__`:**
```python
self.newton_alpha = float(os.environ.get("NANOGPT_NEWTON_MUON_ALPHA", "0.5"))
```

**NOTE:** Per the #1538 numerical-precision finding, `pow(-α)` ≈ `exp(-α * log(x))` accumulates
2-3 ulp error vs rsqrt's 1 ulp. For the control arm (α=0.5), keep using `vals_clamped.rsqrt()`.
The α=0.25 and α=1.0 arms use `pow()` — this is intentional and consistent with the hypothesis.
If α=0.5-pow is desired as a cross-check, add it as an optional fifth arm.

### Arm design (4 arms)

**Arm A (Control):** Production stack. `NANOGPT_NEWTON_MUON_ALPHA` not set (uses rsqrt internally).
Verifies run-to-run stability against fleet mean.

**Arm B (α=0.25, Shampoo-like):**
```
NANOGPT_NEWTON_MUON_ALPHA=0.25
```
Quarter-power preconditioning. Weaker whitening — more conservative step in high-cond directions.

**Arm C (α=1.0, Full Inverse):**
```
NANOGPT_NEWTON_MUON_ALPHA=1.0
```
Full input-covariance inverse. Aggressive — relies on eps clamp and EMA smoothing to stabilize.

**Arm D (α=0.75, gap-fill from #1360):**
```
NANOGPT_NEWTON_MUON_ALPHA=0.75
```
#1360 included α=0.75 but did NOT merge — Arm D re-tests with current production stack (which has
β=0.95, period=2, attn/MLP LR mults, NS_ITERS_COOLDOWN=16, etc. that were not present in #1360).
Serves as bridge between old sweep and new.

### Expected outcome distribution

- Arm B (α=0.25): 40% NULL / 30% mild-FAV / 20% mild-NEG / 10% strong-FAV.
  Rationale: weaker preconditioning is known to work in Shampoo variants; lower risk of instability.
- Arm C (α=1.0): 30% NULL / 25% mild-NEG / 25% mild-FAV / 15% strong-NEG / 5% strong-FAV.
  Rationale: aggressive, high-variance. Could unlock large gain or catastrophic divergence.
- Arm D (α=0.75): 45% NULL / 30% mild-NEG / 15% mild-FAV / 10% strong-NEG.
  Rationale: #1360 found no winner here; expectation is neutral-to-NEG with current stack.

### Falsifying outcome

If all three non-control arms land NULL or NEG, conclude: the α-power axis is exhausted and further
search along this dimension is not warranted. The #1360 result (non-merge) + new arms covering the
full [0.25, 1.0] range would constitute comprehensive evidence.

### Reproduce commands (full production stack)

All arms share the same base stack from RESEARCH_IDEAS_2026-05-24_NEZUKO.md:
```bash
# Arm A (control):
NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
python records/track_3_optimization/train_gpt_simple.py

# Arm B (α=0.25): add NANOGPT_NEWTON_MUON_ALPHA=0.25
# Arm C (α=1.0): add NANOGPT_NEWTON_MUON_ALPHA=1.0
# Arm D (α=0.75): add NANOGPT_NEWTON_MUON_ALPHA=0.75
```

### Taste rubric

**Research mode:** frontier refinement (closing the sweep gap opened by #1360's non-merge).

| Criterion | Score | Justification |
|---|---|---|
| Mechanistic grounding | 4 | α=0.25 has Shampoo pedigree; α=1.0 is natural gradient; both have concrete mechanism tied to eigenvalue amplification and #1530 butterfly-effect evidence |
| Research-state value | 3 | Either extends the α-sweep evidence conclusively or opens a new winner axis; failure also closes this direction definitively |
| Execution value | 4 | One-line code change; staged from cheap 4-arm run; directly targets FFS primary metric |

---

## Hypothesis 2: Joint LR × R-Condition Coupling (Per-Module Adaptive LR)
**Slug:** NM-LR-RCOND-COUPLING
**Student:** g1r4-nezuko

### Mechanistic story

Production stack uses fixed per-group LR multipliers: attn=0.80, MLP=1.20. These were tuned without
any awareness of the actual preconditioning quality at each module. The R buffer computes R_cond
(max_eigenvalue / min_eigenvalue) at every eigendecomp step — this is already in the telemetry
(`state["_R_vals_clamped"]`) but is never used to modulate the learning rate.

Hypothesis: modules with high condition number have noisier R^{-0.5} estimates (small eigenvalues
are estimated with less precision, so the preconditioned gradient in those directions has more noise).
Reducing LR for high-cond modules should improve stability without sacrificing progress in
well-conditioned modules. This is analogous to the preconditioned gradient norm clipping in LAMB/LARS
but applied at the module level rather than the parameter level.

Conversely, modules with low condition number have highly reliable R^{-0.5} estimates and could
tolerate a higher LR. The coupling is: `lr_mult(module) = base_mult * (1 / (1 + γ * log10(R_cond)))`.

This is the first experiment in the catalog that creates a feedback loop between Newton-Muon
preconditioning quality (measured via R eigenstructure) and per-module step size. It is orthogonal to
all in-flight chains and all prior catalog classes.

The #1530 butterfly-effect result (step-25 R_cond: B=280.9 vs A=137.9, +103%) shows that R_cond
differences between runs are large and persistent. This makes R_cond a meaningful signal for LR
modulation — not just noise.

### Implementation

**In `Muon.step()` during the LR application stage:**
```python
# After computing g_precond via _apply_newton_precondition:
if self.nm_lr_cond_gamma > 0.0:
    r_vals = state.get("_R_vals_clamped")
    if r_vals is not None:
        cond = (r_vals.max() / r_vals.min().clamp(min=1e-8)).item()
        cond_scale = 1.0 / (1.0 + self.nm_lr_cond_gamma * math.log10(max(cond, 1.0)))
        # apply cond_scale as multiplicative adjustment to this parameter's lr contribution
        g_precond = g_precond * cond_scale
```

**In `Muon.__init__`:**
```python
import math
self.nm_lr_cond_gamma = float(os.environ.get("NANOGPT_NM_LR_COND_GAMMA", "0.0"))
```

**Key design choice:** `log10` of condition number is used rather than raw condition number to avoid
extreme compression when R_cond = 2M (log10(2e6) ≈ 6.3 — a 6× LR reduction at γ=1.0 vs 2000× raw).
The `1/(1+γ*log10)` form ensures the scale is always in (0, 1], never amplifying LR beyond base.

**Alternative formulation (Arm D):** Instead of multiplicative, use a soft clamp:
`cond_scale = min(1.0, (R_COND_TARGET / cond) ** 0.5)` where R_COND_TARGET is a hyperparameter.
This directly targets a condition number setpoint rather than a continuous penalty.

### Arm design (4 arms)

**Arm A (Control):** Production stack. `NANOGPT_NM_LR_COND_GAMMA=0.0`. Baseline comparison.

**Arm B (γ=0.3, mild coupling):**
```
NANOGPT_NM_LR_COND_GAMMA=0.3
```
At R_cond=1000 (log10=3): scale=1/(1+0.9)=0.526. At R_cond=100: scale=1/(1+0.6)=0.625.
At R_cond=10: scale=1/(1+0.3)=0.769. Moderate compression for high-cond modules.

**Arm C (γ=1.0, strong coupling):**
```
NANOGPT_NM_LR_COND_GAMMA=1.0
```
At R_cond=1000: scale=0.25. At R_cond=100: scale=0.33. At R_cond=10: scale=0.5.
Aggressive compression — tests whether tighter coupling to preconditioning quality helps.

**Arm D (setpoint formulation, R_COND_TARGET=1000):**
```
NANOGPT_NM_LR_COND_TARGET=1000
```
Uses `cond_scale = min(1.0, sqrt(1000/cond))`. Modules with cond < 1000 get no reduction;
modules with cond > 1000 get proportional reduction. Target of 1000 is motivated by typical
attn block R_cond in the 100-10000 range (telemetry from #1530).

### Expected outcome distribution

- Arm B (γ=0.3): 40% NULL / 30% mild-FAV / 20% mild-NEG / 10% strong-FAV.
  Rationale: mild coupling unlikely to destabilize; may improve cooldown stability (where R_cond
  is highest due to distribution shift).
- Arm C (γ=1.0): 35% NULL / 30% mild-NEG / 20% mild-FAV / 15% strong-NEG.
  Rationale: aggressive compression risks slowing convergence in body of training where R is
  reliably estimated.
- Arm D (setpoint): 40% NULL / 25% mild-FAV / 25% mild-NEG / 10% strong-FAV.
  Rationale: setpoint formulation is more interpretable but may be too conservative (most modules
  below target get no effect).

### Falsifying outcome

If γ=0.3 is mild-NEG and γ=1.0 is strong-NEG: conclude R_cond-based LR reduction degrades
convergence regardless of coupling strength. This would rule out the condition-number-as-LR-signal
hypothesis. If γ=0.3 is FAV but γ=1.0 is NEG: proceed with a γ=0.1 follow-up arm.

### Reproduce commands

```bash
# Arm A (control):
NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0 NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NEWTON_MUON=1 NANOGPT_NEWTON_MUON_BETA=0.95 NANOGPT_NEWTON_MUON_EPS=1e-4 \
NANOGPT_NEWTON_MUON_UPDATE_PERIOD=2 NANOGPT_NEWTON_MUON_MAX_D_IN=4096 \
NANOGPT_NM_LR_COND_GAMMA=0.0 \
python records/track_3_optimization/train_gpt_simple.py

# Arm B: add NANOGPT_NM_LR_COND_GAMMA=0.3
# Arm C: add NANOGPT_NM_LR_COND_GAMMA=1.0
# Arm D: add NANOGPT_NM_LR_COND_TARGET=1000 (uses setpoint branch, gamma ignored)
```

### Taste rubric

**Research mode:** tier shift (first feedback loop between Newton-Muon preconditioning quality and
per-module step size; no prior art in catalog classes 1-9).

| Criterion | Score | Justification |
|---|---|---|
| Mechanistic grounding | 3 | Mechanism targets specific observed failure — R_cond variability (#1530 +103% at step 25) as noisy precond signal; LR reduction as noise compensation. Connection to prior evidence is strong but the log10 formulation is somewhat heuristic. |
| Research-state value | 4 | Either opens a new axis (condition-adaptive LR) or closes it; result is interpretable either way; if FAV, γ-sweep follows naturally |
| Execution value | 3 | 4-arm run, moderate code addition (~15 lines), directly targets FFS; arm D tests an orthogonal formulation that could survive even if γ-arms fail |

---

## Hypothesis 3: AdamW Second-Moment Cold-Start for R Initialization
**Slug:** NM-R-ADAMW-WARMSTART
**Student:** (backup / next available)

### Mechanistic story

Current R initialization (`state["R"] = R_new.clone()` on first call) sets R to the first observed
X^T X. PR #1530 (tanjiro warmstart) tested replacing this with `α·I` (a scalar identity prior) and
found a MAJOR finding: α=0.001 gives NEG-monotone +0.00362 (12× larger than null forecast) via the
butterfly-effect-via-activations mechanism.

The α·I approach tests a scalar prior. A richer alternative: use the AdamW optimizer's second-moment
accumulator `v_t` for the corresponding parameter as the initial R. AdamW maintains `v_t = β2·v_{t-1}
+ (1-β2)·g_t²` — a running average of squared gradients. For a linear layer `W ∈ ℝ^{d_out × d_in}`,
`v_t ∈ ℝ^{d_out × d_in}` and the column-mean `v_t.mean(0) ∈ ℝ^{d_in}` is a diagonal approximation
of the input covariance (by the generalized Gauss-Newton equivalence between gradient second moments
and Fisher/GGN matrices).

Initializing R to `diag(v_t.mean(0))` rather than first-observed X^T X or α·I uses gradient history
as a warm start for the input-covariance buffer. Since AdamW has been running since step 0, by the
time Newton-Muon first calls `_apply_newton_precondition`, AdamW already has useful second-moment
estimates. This bridges the "cold R" problem from a data-driven direction rather than a scalar prior
direction.

This is orthogonal to #1530 (which tested scalar warmup α·I) and #1543 (Tikhonov γI floor).

### Implementation

```python
# In _apply_newton_precondition, when "R" not in state:
if "R" not in state:
    # Try to warm-start from AdamW second moment for this parameter
    adam_state = self._get_adamw_state_for(p)  # need to implement helper
    if adam_state is not None and "exp_avg_sq" in adam_state:
        v_t = adam_state["exp_avg_sq"].float()  # shape: d_out x d_in
        # Column-mean diagonal approximation of X^T X
        diag_approx = v_t.mean(0)  # shape: d_in
        diag_approx = diag_approx / (diag_approx.mean() + 1e-8)  # normalize to unit mean
        R_warm = torch.diag(diag_approx)  # d_in x d_in diagonal matrix
        state["R"] = R_warm.clone()
    else:
        state["R"] = R_new.clone()  # fallback to current behavior
```

**Challenge:** Muon and AdamW are separate optimizer instances. The helper `_get_adamw_state_for(p)`
requires either (a) passing the AdamW optimizer reference to Muon at construction, or (b) maintaining
a shared parameter-keyed dict. Option (b) is cleaner: add a class-level `_shared_adam_state` dict
populated by the AdamW step and read by Muon.

### Arm design (3 arms)

**Arm A (Control):** Production stack. Standard first-call initialization.

**Arm B (AdamW diagonal warmstart, normalized):**
```
NANOGPT_NM_R_ADAMW_WARMSTART=1
NANOGPT_NM_R_ADAMW_WARMSTART_SCALE=1.0
```
Uses diag(v_t.mean(0)) normalized to unit mean as R[0].

**Arm C (AdamW diagonal warmstart, unscaled):**
```
NANOGPT_NM_R_ADAMW_WARMSTART=1
NANOGPT_NM_R_ADAMW_WARMSTART_SCALE=0.0  # use raw v_t without normalization
```
Tests whether the absolute scale of AdamW second moments matters vs relative shape.

### Expected outcome distribution

- Arm B: 40% NULL / 30% mild-FAV / 20% mild-NEG / 10% strong-FAV.
- Arm C: 40% NULL / 30% mild-NEG / 20% mild-FAV / 10% strong-NEG.

---

## Hypothesis 4: Cooldown Gradient Noise Injection (Exploration Boost at Late Phase)
**Slug:** NM-COOLDOWN-GRAD-NOISE
**Student:** (backup / next available)

### Mechanistic story

PRs #176 and #185 established that cooldown is the critical phase — maximum loss-curve spread of
0.003 emerges at step 3000+, well after the body of training has converged. This suggests the model's
final basin is highly sensitive to the trajectory taken during cooldown. PR #1088 tested gradient
noise throughout training and found NEG. This hypothesis is strictly scoped to cooldown only.

During cooldown, the LR drops and the NS coefficient changes shape (late_peak). The model is
annealing toward a local minimum. Adding small Gaussian noise to the body Muon gradients before NS5
application effectively creates a warm simulated-annealing step — slightly perturbing the annealing
trajectory could help the model escape narrow local minima and settle in a flatter basin.

The noise is applied before NS5, so it is then orthogonalized (NS5 maps to the orthogonal group). The
NS5 Lipschitz invariance to input scale (proven in #176 analysis: ||g_ortho||_RMS = 0.0360 ±
0.000003 across noise arms) means the noise direction is preserved but its scale is normalized. This
is noise in the direction of the gradient manifold, not noise in the update magnitude.

This is distinct from #1088 (noise throughout training, likely destabilizing). The cooldown-scoping
is critical.

### Implementation

```python
# In Muon.step(), during body gradient processing, AFTER checking cooldown phase:
if self.cooldown_grad_noise > 0.0 and step_frac > NS_COOLDOWN_START_FRAC:
    noise_scale = self.cooldown_grad_noise * grad.float().norm() / (grad.numel() ** 0.5)
    grad = grad + torch.randn_like(grad) * noise_scale
```

**Env vars:**
```
NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.0    # default off
NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.01   # 1% noise
NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.05   # 5% noise
```

### Arm design (4 arms)

**Arm A (Control):** No noise. Production stack.
**Arm B:** `NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.01` (1% RMS noise during cooldown only).
**Arm C:** `NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.05` (5% RMS noise during cooldown only).
**Arm D:** `NANOGPT_COOLDOWN_GRAD_NOISE_SCALE=0.10` (10% RMS noise — likely too aggressive, tests upper bound).

### Expected outcome distribution

- Arm B (1%): 45% NULL / 30% mild-NEG / 15% mild-FAV / 10% strong-NEG.
  Rationale: very small noise unlikely to dominate NS5 orthogonalization, low signal.
- Arm C (5%): 35% NULL / 35% mild-NEG / 20% mild-FAV / 10% strong-NEG.
  Rationale: #1088 was NEG for full training; cooldown-only scoping improves prognosis modestly.
- Arm D (10%): 25% NULL / 45% mild-NEG / 20% strong-NEG / 10% mild-FAV.

### Falsifying outcome

If all three noise arms show NEG or NULL: conclude noise injection even scoped to cooldown does not
help, and the NS5 normalization washes out the exploration signal. Combine with #1088 to conclude:
gradient noise in the Muon path is not a productive axis regardless of timing.

---

## Hypothesis 5: Per-Module Rank-k R Truncation
**Slug:** NM-RANK-K-R-TRUNCATION
**Student:** (backup / next available)

### Mechanistic story

Current R_inv_sqrt uses all d_in eigenvalue/eigenvector pairs. For modules with d_in=4096, this is a
4096×4096 matrix operation at every eigendecomp step. If the input covariance is approximately
low-rank (top-k eigenvalues dominate), the remaining (d_in - k) eigenvectors correspond to directions
where X^T X has near-zero eigenvalue — these get amplified by `eps^{-0.5}` = 100× in R_inv_sqrt.

Hypothesis: truncating to top-k eigenvectors (setting `inv_sqrt_vals[:-k] = 0` before constructing
R_inv_sqrt) produces a rank-k preconditioner that:
1. Ignores noisy small-eigenvalue directions (reducing sensitivity to R estimation error).
2. Effectively concentrates the preconditioning on the directions where the input is richest.
3. Is equivalent to Tikhonov (#1543) in the limit but via hard truncation rather than soft diagonal
   floor — different spectral behavior, different regularization regime.

This connects to the #1543 Tikhonov experiment (in-flight): Tikhonov adds γI to eigenvalues
(shifting all up), rank-k truncation zeros out small ones. Complementary mechanisms.

### Implementation

```python
# In _apply_newton_precondition, after computing inv_sqrt_vals:
if self.newton_rank_k > 0 and len(inv_sqrt_vals) > self.newton_rank_k:
    # Zero out all but top-k inverse sqrt values (small eigenvalues → zero precond weight)
    inv_sqrt_vals_masked = inv_sqrt_vals.clone()
    inv_sqrt_vals_masked[:-self.newton_rank_k] = 0.0
    state["R_inv_sqrt"] = (vecs * inv_sqrt_vals_masked.unsqueeze(0)) @ vecs.T
else:
    state["R_inv_sqrt"] = (vecs * inv_sqrt_vals.unsqueeze(0)) @ vecs.T
```

**In `Muon.__init__`:**
```python
self.newton_rank_k = int(os.environ.get("NANOGPT_NEWTON_MUON_RANK_K", "0"))  # 0 = full rank
```

**Arm design:**
- Arm A: Control (full rank, k=0).
- Arm B: `NANOGPT_NEWTON_MUON_RANK_K=512` (top-512 of d_in=1024 for MLP, proportional for larger).
- Arm C: `NANOGPT_NEWTON_MUON_RANK_K=256` (top-256, more aggressive truncation).
- Arm D: `NANOGPT_NEWTON_MUON_RANK_K=128` (top-128, only dominant directions).

**Note:** For d_in=4096 (max), k=512 keeps 12.5% of directions — far fewer than current full-rank.
Consider a relative `NANOGPT_NEWTON_MUON_RANK_FRAC=0.25` (keep 25% of dims) as an alternative to
absolute k — more robust to varying d_in across layers.

---

## Hypothesis 6: Multi-Resolution R-Buffer (Attn Full / MLP Block-Diagonal)
**Slug:** NM-MULTI-RES-R-BUFFER
**Student:** (backup / next available)

### Mechanistic story

Current implementation applies the same full d_in × d_in R buffer to both attention and MLP
projections. However:

- **Attention Q/K/V/O projections**: d_in = n_embd. Inputs are token embeddings with rich positional
  and semantic covariance — the full d_in × d_in R is meaningful here.
- **MLP fc1/fc2 projections**: d_in = n_embd or 4×n_embd. After GELU activations, MLP inputs are
  sparser and more isotropic — a block-diagonal or even diagonal R may capture 90% of the
  preconditioning benefit at 1/B² of the cost.

Hypothesis: replacing the full R for MLP projections with a block-diagonal approximation (B blocks
of d_in/B × d_in/B) reduces eigendecomp cost quadratically in B while preserving attn's full-rank
preconditioning where it matters most. The efficiency gain enables either (a) a smaller B for more
frequent updates (period=1 for MLP vs period=2 for attn), or (b) no change in compute but a
structurally different inductive bias.

This is distinct from #1363 (diagonal-only R, which was NEG) — block-diagonal is strictly richer
than diagonal and can capture local covariance structure between adjacent embedding dimensions.

### Implementation

```python
# In _apply_newton_precondition, determine resolution based on parameter name:
def _get_r_resolution(self, param_name):
    if "mlp" in param_name.lower():
        return self.mlp_r_resolution  # "full", "block16", "block32", "diag"
    return "full"  # attn always full

# Block-diagonal R computation:
if resolution.startswith("block"):
    B = int(resolution[5:])  # e.g., "block16" -> B=16
    block_size = d_in // B
    R_block = torch.zeros(d_in, d_in, device=x.device, dtype=torch.float32)
    for i in range(B):
        s, e = i * block_size, (i + 1) * block_size
        R_block[s:e, s:e] = (x32[:, s:e].T @ x32[:, s:e]) / float(n)
    R_new = R_block
```

**Env vars:**
```
NANOGPT_NEWTON_MUON_MLP_RESOLUTION=full       # default (current behavior)
NANOGPT_NEWTON_MUON_MLP_RESOLUTION=block32    # 32 blocks
NANOGPT_NEWTON_MUON_MLP_RESOLUTION=block16    # 16 blocks
NANOGPT_NEWTON_MUON_MLP_RESOLUTION=diag       # fully diagonal (compare to #1363)
```

**Arm design:**
- Arm A: Control (`MLP_RESOLUTION=full`).
- Arm B: `MLP_RESOLUTION=block32` (32 blocks for d_in=1024: 32×32 per block).
- Arm C: `MLP_RESOLUTION=block16` (16 blocks for d_in=1024: 64×64 per block).
- Arm D: `MLP_RESOLUTION=diag` (fully diagonal — bridge to #1363 with current stack as sanity check).

---

## Priority Ranking for Student Assignment

1. **g1r4-fern → Hypothesis 1 (NM-ALPHA-EXTENDED-SWEEP)**
   Rationale: one-line implementation change, direct extension of #1360 sweep into untested territory,
   strong external evidence (Shampoo for α=0.25, natural gradient for α=1.0), highest mechanistic
   grounding score. #1360's non-merge means there is genuine signal to find here.

2. **g1r4-nezuko → Hypothesis 2 (NM-LR-RCOND-COUPLING)**
   Rationale: first feedback loop between preconditioning quality and step size — genuine novelty,
   no prior art in catalog classes 1-9. R_cond variability is empirically established (+103% at
   step 25, #1530). If FAV, creates a new tunable axis with direct mechanistic motivation.

3. Hypothesis 3 (NM-R-ADAMW-WARMSTART): next priority after current in-flight chains close.
4. Hypothesis 4 (NM-COOLDOWN-GRAD-NOISE): moderate priority, low prior probability given #1088.
5. Hypothesis 5 (NM-RANK-K-R-TRUNCATION): complements #1543 Tikhonov (in-flight), worth testing
   after #1543 closes.
6. Hypothesis 6 (NM-MULTI-RES-R-BUFFER): lowest priority due to implementation complexity, but
   highest potential efficiency gain if MLP is shown to not need full-rank R.

---

## Research State Update

**Current best explanation for plateau:** The local α-power, R-regularization, and phase-structure
axes have been extensively mapped. The remaining headroom requires either (a) extending the α sweep
into untested extremes (α=0.25, α=1.0), or (b) coupling Newton-Muon's preconditioning quality signal
to other aspects of the optimizer (LR, update frequency, rank) to unlock compound improvements.

**Evidence:** 18 merged PRs, 9 confirmed catalog classes, #1360 non-merge (α sweep), #1530
butterfly-effect finding (R_cond as meaningful signal), #1538 numerical-precision finding (precision
matters at α=0.5, constrains how aggressively we push α), #1543/#1567 in-flight (diagonal
regularization axis).

**Open uncertainties:**
1. Does the α=0.25/α=1.0 regime produce qualitatively different dynamics than the tested {0.333-
   0.75} range, or is the α axis fundamentally saturated at α=0.5?
2. Is R_cond a stable enough signal across runs to drive per-module LR adaptation, or does its
   +103% run-to-run variability (#1530) make it too noisy to use as a feedback signal?
3. Does the failure of #1088 (noise throughout training = NEG) generalize to cooldown-scoped noise,
   or is cooldown a genuinely different regime where exploration helps?

**Stop condition for this wave:** If both Hypothesis 1 and Hypothesis 2 return NULL or NEG, escalate
to architectural-level changes (rank-k truncation, multi-resolution R, AdamW warmstart).
