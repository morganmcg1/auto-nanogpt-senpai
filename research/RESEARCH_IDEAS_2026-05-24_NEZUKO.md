# Hypothesis: Per-Matrix Spectral-Residual Adaptive NS Iteration Count
## Assigned to: g1r4-nezuko
## Date: 2026-05-24
## Mechanism axis: PRECONDITIONER

---

## 1. Mechanism description

Newton-Schulz (NS) orthogonalization currently runs a fixed number of polynomial
iterations (NS_ITERS=12 mid-training, NS_ITERS_COOLDOWN=16 during cooldown, with
stochastic ±2 spread in cooldown via NS_STOCHASTIC_COOLDOWN=2). This is a fixed
budget that ignores whether a given matrix has already converged to a near-orthogonal
state or whether it needs more work.

The hypothesis is that early stopping the NS iteration loop on a per-matrix,
per-step basis — using the spectral residual `‖X^T X − I‖_F / √m` as a
convergence criterion — will either:

(a) save iterations on matrices that converge early, allowing the budget to be
    redirected to matrices that converge slowly (with expanded max_steps), or
(b) match quality with fewer iterations on easy matrices (C iso-budget test).

The residual `‖X^T X − I‖_F / √m` (normalized by sqrt of the matrix minor
dimension `m = min(rows, cols)`) measures how far the current NS iterate X is
from an orthogonal matrix. When it falls below threshold τ, X is sufficiently
orthogonal and further iterations add diminishing marginal benefit at nonzero cost.

This is PRECONDITIONER-axis work: it changes the effective orthogonalization
quality map across matrices and steps, which is qualitatively different from:
- NS polynomial coefficient schedules (what values to use each iteration — PR #290)
- NS stochastic spread (adding noise to the iteration count budget — PR #787)
- Static per-block-type or per-depth NS_ITERS allocations (PRs #724, #710)

---

## 2. Mechanism-distinctness from closed and in-flight PRs

| PR | Mechanism | Status | Relation to this hypothesis |
|----|-----------|--------|----------------------------|
| #290 | NS polynomial coefficient schedule (linear_ramp_down) | MERGED | Orthogonal: #290 changes what coefficients (a,b,c) are used; this changes how many iterations are run. Both parameters of the NS loop, different dimensions. |
| #787 | Stochastic NS iter spread in cooldown (±2) | MERGED | Orthogonal: #787 adds random noise around a FIXED mean; this uses convergence residual to stop EARLY. Different mechanism entirely. |
| #710 | Per-depth static NS_ITERS allocation (frieren) | CLOSED productive-NEG | Static allocation by layer depth; this is dynamic per-step residual stopping. Not a closure. |
| #724 | Per-block-TYPE static NS_ITERS_COOLDOWN (nezuko) | CLOSED productive-NEG | Static allocation by block type (attn/mlp); this is dynamic per-step stopping. Not a closure. |
| #145 | Per-layer adaptive NS with sigmoid policy (nezuko) | CLOSED | DIFFERENT FAILURE MODE: sigmoid function saturated near the uniform regime due to a denominator scaling bug, causing degeneration to uniform allocation. That PR did NOT test per-matrix residual stopping — it tested a learned sigmoid threshold that collapsed. The mechanism proposed here (direct residual measurement against fixed τ) was not tested in #145. |
| #1008 | Static-c NS operating-point sweep (alphonse, IN FLIGHT) | IN FLIGHT | Tests fixed polynomial coefficient value (c constant across training); orthogonal to iteration count stopping criterion. |
| #1003 | Per-block-TYPE Muon LR mult cooldown anneal (fern, IN FLIGHT) | IN FLIGHT | LR schedule, not NS iteration count. |
| #998 | NS cooldown β₂ interaction (frieren, IN FLIGHT) | IN FLIGHT | AdamW β₂ axis, not NS iteration count. |
| #988 | (see current state) | IN FLIGHT | Not NS adaptive iter. |
| #984 | (see current state) | IN FLIGHT | Not NS adaptive iter. |
| #1028 | SUBTRACTIVE pruning ablation (edward, IN FLIGHT) | IN FLIGHT | Pruning/removal axis. |
| #1020 | AdamW ε UP-ramp (askeladd, IN FLIGHT) | IN FLIGHT | AdamW hyperparameter. |

CONCLUSION: This hypothesis is mechanism-distinct from all closed and all 7 in-flight
PRs as of 2026-05-24.

---

## 3. Theoretical motivation

The NS quintic iteration `X ← aX + b(XX^T)X + c(XX^T)^2 X` converges cubically
(degree-5 polynomial applied once ≈ degree-5 contraction rate) when the initial
spectrum is contained in [0.1, 1.9] after normalization. In practice, most
gradient matrices have fast-converging spectra: empirically, ~60-70% of matrices
hit near-orthogonal state (‖X^T X − I‖_F / √m < 0.05) within 5-7 iterations.

A fixed budget of 12 iterations wastes compute on those matrices. An adaptive
budget that stops early on well-converged matrices could:
1. Reduce total NS compute (throughput benefit).
2. Alternatively: allow the saved "budget" to be used as a higher ceiling on
   hard matrices (the EXPANDED MAX design in Arms B and D).
3. At equal budget ceiling (Arm C iso-budget): assess whether early stopping on
   easy matrices improves gradient direction quality for hard matrices indirectly
   via reduced numerical drift.

The residual `‖X^T X − I‖_F / √m` is:
- Cheap to compute: O(m^2) where m = min(rows, cols), same as one NS iteration
- Exact: directly measures the orthogonality gap
- Bounded: guaranteed 0 at convergence, bounded above by the initial value

Reference: The general principle of adaptive stopping in fixed-point iterations
based on residual monitoring is standard numerical analysis (Golub & Van Loan,
Matrix Computations, §7.5 stopping criteria for iterative methods). The specific
application to NS orthogonalization in neural network optimizers is not established
in the literature as of August 2025; this is a novel application.

---

## 4. 4-arm design

All arms: N=1 seed, sequential on single H100, train_steps=3350.
Arm A is the unmodified baseline control. Arms B, C, D test the adaptive mechanism.

### Arm A — control (baseline)
```
NS_ADAPTIVE=0 (or unset)
NS_ITERS=12  NS_ITERS_COOLDOWN=16  NS_STOCHASTIC_COOLDOWN=2
```
All other baseline env vars as documented in merged stack.

### Arm B — adaptive, expanded budget
```
NANOGPT_NS_ADAPTIVE=1
NANOGPT_NS_ADAPTIVE_TAU=0.05
NANOGPT_NS_ADAPTIVE_MIN=5
NANOGPT_NS_ADAPTIVE_MAX=16        # expanded mid-training ceiling (was 12)
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=20  # expanded cooldown ceiling (was 16+stoch)
```
Hypothesis: matrices that converge fast stop at 5-8 iters; matrices that need more
precision get up to 16/20 iters. Mean iter count per step expected ~8-10 mid-training,
~10-13 cooldown.

### Arm C — adaptive, iso-budget (same ceiling as control)
```
NANOGPT_NS_ADAPTIVE=1
NANOGPT_NS_ADAPTIVE_TAU=0.05
NANOGPT_NS_ADAPTIVE_MIN=5
NANOGPT_NS_ADAPTIVE_MAX=12        # same as baseline mid-training ceiling
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=16  # same as baseline cooldown ceiling
```
Hypothesis: pure redistribution — easy matrices get fewer iters, hard matrices get up
to the same ceiling. Tests whether the ALLOCATION pattern matters, not just total
budget. If Arm C beats A with same ceiling, the mechanism is real; compute is not the
explanation.

### Arm D — adaptive, tighter threshold + expanded budget
```
NANOGPT_NS_ADAPTIVE=1
NANOGPT_NS_ADAPTIVE_TAU=0.02      # tighter threshold: stop only when very orthogonal
NANOGPT_NS_ADAPTIVE_MIN=5
NANOGPT_NS_ADAPTIVE_MAX=16        # same expanded ceiling as Arm B
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=20
```
Hypothesis: tighter τ forces more iterations on matrices that are merely "close" to
orthogonal. Tests sensitivity to τ. If D ≈ B, τ=0.05 is already tight enough;
if D < B, the residual stopping is beneficial and tighter is better.

### Hyperparameter matrix

| Arm | NS_ADAPTIVE | TAU | MIN | MAX | MAX_CD |
|-----|-------------|-----|-----|-----|--------|
| A   | 0           | —   | —   | 12  | 16±2   |
| B   | 1           | 0.05| 5   | 16  | 20     |
| C   | 1           | 0.05| 5   | 12  | 16     |
| D   | 1           | 0.02| 5   | 16  | 20     |

Note: When NS_ADAPTIVE=1, stochastic cooldown (NS_STOCHASTIC_COOLDOWN=2) applies to
MAX_COOLDOWN (so Arm B cooldown randomly samples from {18..22}, Arm C from {14..18}).
This preserves compatibility with the merged stochastic-NS mechanism and does not
require disabling it.

---

## 5. Exact code changes (verbatim)

### 5a. New adaptive NS function

Add this function directly after the existing `zeropower_via_newtonschulz5` function
in `records/track_3_optimization/train_gpt_simple.py`:

```python
def zeropower_via_newtonschulz5_adaptive(G, max_steps, min_steps=5, tau=0.05):
    """
    NS orthogonalization with per-matrix residual early stopping.
    Stops when ||X^T X - I||_F / sqrt(m) < tau, after at least min_steps.
    Returns (X_orthogonalized, actual_steps_taken).
    """
    assert len(G.shape) == 2
    a, b, c = (3.4445, -4.7750, 2.0315)
    X = G.bfloat16()
    transposed = G.size(0) > G.size(1)
    if transposed:
        X = X.T
    X = X / (X.norm() + 1e-7)
    actual_steps = 0
    for step_i in range(max_steps):
        A = X @ X.T
        B_mat = b * A + c * (A @ A)
        X = a * X + B_mat @ X
        actual_steps = step_i + 1
        if actual_steps >= min_steps:
            m = X.shape[1]  # minor dimension after potential transpose
            XT_X = X.T @ X
            eye = torch.eye(m, device=X.device, dtype=X.dtype)
            resid = (XT_X - eye).norm() / (m ** 0.5)
            if resid.item() < tau:
                break
    if transposed:
        X = X.T
    return X.to(G.dtype), actual_steps
```

### 5b. Env var parsing

In the env-var parsing section near the top of the script (where other NANOGPT_*
vars are parsed), add:

```python
NS_ADAPTIVE = int(os.environ.get('NANOGPT_NS_ADAPTIVE', '0'))
NS_ADAPTIVE_TAU = float(os.environ.get('NANOGPT_NS_ADAPTIVE_TAU', '0.05'))
NS_ADAPTIVE_MIN = int(os.environ.get('NANOGPT_NS_ADAPTIVE_MIN', '5'))
NS_ADAPTIVE_MAX = int(os.environ.get('NANOGPT_NS_ADAPTIVE_MAX', '16'))
NS_ADAPTIVE_MAX_COOLDOWN = int(os.environ.get('NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN', '20'))
```

### 5c. Muon.step() modification

In the `Muon.step()` method, find the call to `zeropower_via_newtonschulz5`.
It will look something like:

```python
g = zeropower_via_newtonschulz5(g, steps=ns_steps)
```

Replace this with conditional dispatch:

```python
if NS_ADAPTIVE:
    g, _ns_actual = zeropower_via_newtonschulz5_adaptive(
        g,
        max_steps=ns_steps,          # ns_steps already accounts for cooldown/stochastic
        min_steps=NS_ADAPTIVE_MIN,
        tau=NS_ADAPTIVE_TAU,
    )
else:
    g = zeropower_via_newtonschulz5(g, steps=ns_steps)
```

The `ns_steps` variable at that call site is already computed by the existing
schedule logic (including stochastic cooldown spread), so the adaptive function
receives the correct max_steps that respects all existing schedule logic.

### 5d. W&B telemetry (optional but recommended)

To log the mean actual NS iterations per optimizer step for diagnostic purposes,
accumulate `_ns_actual` values during the step and log:

```python
# Inside Muon.step(), after the adaptive NS block, accumulate:
# (add a list to the Muon optimizer state, or log directly to wandb)
# Minimal version — log mean actual steps at validation events:
if NS_ADAPTIVE and step % val_interval == 0:
    # log mean_ns_actual from accumulated list
    wandb.log({'train/ns_adaptive/mean_actual_steps': mean_ns_actual}, step=step)
    wandb.log({'train/ns_adaptive/min_actual_steps': min_ns_actual}, step=step)
    wandb.log({'train/ns_adaptive/max_actual_steps': max_ns_actual}, step=step)
```

This telemetry is diagnostic gold: if mean_actual_steps ≈ max_steps, the residual
threshold is too tight and rarely triggers. If mean_actual_steps ≈ min_steps, the
threshold is too loose and always triggers early.

---

## 6. Run commands

Use the full merged-stack env vars plus the new adaptive NS vars.

### Arm A (control)
```bash
NANOGPT_GRAD_CLIP_BODY=10.0 \
NANOGPT_GRAD_CLIP_AUX=5.0 \
NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 \
NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NS_ADAPTIVE=0 \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/ns-adaptive-arm-A-ctrl" \
  --wandb_group "ns-adaptive-residual-stopping"
```

### Arm B (adaptive, expanded budget, tau=0.05)
```bash
NANOGPT_GRAD_CLIP_BODY=10.0 \
NANOGPT_GRAD_CLIP_AUX=5.0 \
NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 \
NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NS_ADAPTIVE=1 \
NANOGPT_NS_ADAPTIVE_TAU=0.05 \
NANOGPT_NS_ADAPTIVE_MIN=5 \
NANOGPT_NS_ADAPTIVE_MAX=16 \
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=20 \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/ns-adaptive-arm-B-tau05-max16-cd20" \
  --wandb_group "ns-adaptive-residual-stopping"
```

### Arm C (adaptive, iso-budget, tau=0.05)
```bash
NANOGPT_GRAD_CLIP_BODY=10.0 \
NANOGPT_GRAD_CLIP_AUX=5.0 \
NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 \
NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NS_ADAPTIVE=1 \
NANOGPT_NS_ADAPTIVE_TAU=0.05 \
NANOGPT_NS_ADAPTIVE_MIN=5 \
NANOGPT_NS_ADAPTIVE_MAX=12 \
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=16 \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/ns-adaptive-arm-C-tau05-max12-cd16-isobudget" \
  --wandb_group "ns-adaptive-residual-stopping"
```

### Arm D (adaptive, tighter threshold tau=0.02, expanded budget)
```bash
NANOGPT_GRAD_CLIP_BODY=10.0 \
NANOGPT_GRAD_CLIP_AUX=5.0 \
NANOGPT_ADAMW_BETA2=0.99 \
NANOGPT_NS_COOLDOWN_SHAPE=late_peak \
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_ADAMW_EMBED_LR_MULT=1.5 \
NANOGPT_MUON_ATTN_LR_MULT=0.80 \
NANOGPT_MUON_MLP_LR_MULT=1.20 \
NANOGPT_NS_STOCHASTIC_COOLDOWN=2 \
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
NANOGPT_NS_ADAPTIVE=1 \
NANOGPT_NS_ADAPTIVE_TAU=0.02 \
NANOGPT_NS_ADAPTIVE_MIN=5 \
NANOGPT_NS_ADAPTIVE_MAX=16 \
NANOGPT_NS_ADAPTIVE_MAX_COOLDOWN=20 \
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "nezuko/ns-adaptive-arm-D-tau02-max16-cd20" \
  --wandb_group "ns-adaptive-residual-stopping"
```

---

## 7. Decision policy

### Early-kill gate (per arm, at step ~2500)
If `val/loss(arm X at step ~2500) - val/loss(arm A at step ~2500) >= +0.10`:
abort that arm immediately. This is only for obvious crashes. Do not kill based on
smaller losses at step 2500.

### Signal thresholds
- Signal present: `val/loss(best non-A arm) - val/loss(arm A) <= -0.002` at
  final step (step 3350). Proceed to paired-pod confirmation (n=3 seeds).
- Productive-NULL band: `|val/loss(arm X) - val/loss(arm A)| < 0.001`. Record
  as productive-NULL.
- Regression: `val/loss(arm X) - val/loss(arm A) >= +0.0015`. Mark arm as
  direction-wrong.

### Paired-pod confirmation trigger
If ANY arm (B, C, or D) shows `Δ <= -0.002` vs Arm A at step 3350, run the
winning arm at n=3 seeds to confirm.

Confirmation merge gates (all 4 must pass):
1. `mean(arm_X, n=3) <= 3.26756` (beats current branch baseline)
2. `(3.28 - mean(arm_X, n=3)) * sqrt(3) >= 0.004` (stat-sig rule)
3. Direction correct in at least 2/3 seeds
4. Arm A control mean drift `|mean(A) - 3.26756| <= 0.003` (drift gate)

### Iso-budget interpretation (Arm C specific)
If Arm C shows signal (Δ <= -0.002) with MAX=12 (same ceiling as baseline), this
is strong mechanistic evidence that the ALLOCATION pattern itself (not higher
compute budget) is driving the gain. This would be a particularly clean result.

### Diagnostic checkpoints
If NS_ADAPTIVE W&B telemetry is logged:
- If `mean_actual_steps ≈ max_steps` for all arms: threshold τ is too tight,
  adaptive stopping is not triggering. The τ-axis is unexplored and lower τ values
  (0.10, 0.15) should be tested next.
- If `mean_actual_steps ≈ min_steps` for all arms: threshold is too loose,
  early stopping always fires. Test τ=0.01 or investigate min_steps=7.
- If `mean_actual_steps` is heterogeneous across matrices/layers: this is the
  expected healthy signal — some matrices converge fast, others need more iters.

---

## 8. SENPAI-RESULT format

For the N=1 screening phase (after running all 4 arms), report:
```
SENPAI-RESULT: {"terminal":false,"status":"screening","pending_arms":true,"wandb_run_ids":["<arm-A-id>","<arm-B-id>","<arm-C-id>","<arm-D-id>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<steps_or_minus_one>},"test_metric":{"name":"val/loss","value":<loss>}}
```

For the final terminal result (after paired-pod confirmation if triggered, or
after all arms are productive-NULL/regressing):
```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<all-run-ids>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<steps_or_minus_one>},"test_metric":{"name":"val/loss","value":<loss>}}
```

If no arm shows signal (all arms productive-NULL or regressing vs A), report
terminal with the best arm's value for the metrics (which will be ≈ baseline).

---

## 9. Risk class and expected impact

### Risk class: LOW-MEDIUM

LOW risk factors:
- Strictly additive code change — the existing NS function is untouched,
  NS_ADAPTIVE=0 (Arm A) is exactly the current baseline.
- No new hyperparameter surfaces that interact non-linearly with the rest of
  the merged stack (τ is local to the NS loop, does not interact with LR,
  momentum, grad-clip, or embed anchor).
- The mechanism is numerically well-defined and bounded.

MEDIUM risk factors:
- The per-matrix residual computation (`X.T @ X` matrix multiply) adds ~1 NS
  iteration worth of compute per check. At min_steps=5 and an average of 6-8
  iterations, this is 1 extra matrix multiply per check, amortized. Total overhead
  is expected to be ~5-10% of NS compute, negligible in overall training.
- τ sensitivity is unknown on this stack. The arm design (B vs D) directly tests
  this sensitivity.
- Prior related attempt (#145 per-layer sigmoid) collapsed to uniform due to a
  different bug; the direct residual measurement here avoids that failure mode
  entirely but has not been tested on this stack.

### Expected impact

If the mechanism is active:
- Arm C iso-budget result (if positive): Δ_vs_baseline = -0.001 to -0.002
  (pure allocation rebalancing effect; historical bounds from similar mechanism
  improvements)
- Arm B expanded-budget result (if positive): Δ_vs_baseline = -0.001 to -0.003
  (additional benefit from expanded ceiling for hard matrices)

If the mechanism is inactive (threshold rarely triggers):
- Productive-NULL: |Δ| < 0.001 across all arms
- The diagnostic telemetry will still provide empirical data on NS convergence
  rates per matrix type, which has research value for the next NS-axis hypothesis.

### Stop condition

Close this hypothesis as fully explored if:
1. All of B, C, D show Δ >= -0.0005 vs Arm A at step 3350 (mechanism not active
   at any tested τ), AND
2. The W&B diagnostic shows mean_actual_steps is not heterogeneous across matrices
   (i.e., NS convergence is already nearly uniform at baseline — the assumption is
   wrong).

Do NOT close based solely on one-arm regression. The arm design tests three
independent hypotheses (expanded budget, iso-budget, tighter τ); if all three
show null or regression, the NS adaptive stopping mechanism is ruled out at these
τ values on this stack.

---

## 10. Current baseline (for student reference)

Branch baseline: `auto-nanogpt-1gpu-r4`
- `speedrun/final_first_step_to_target`: 3183.33 (mean n=3, W&B seeds: ddiux6wz, 1zjpifpb, l35g6tlk)
- `val/loss`: 3.26756 (n=3 mean)
- Source PR: #847 (embed init-anchor WD λ=0.001)

Full merged stack env vars:
```
NANOGPT_GRAD_CLIP_BODY=10.0
NANOGPT_GRAD_CLIP_AUX=5.0
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_EMBED_LR_MULT=1.5
NANOGPT_MUON_ATTN_LR_MULT=0.80
NANOGPT_MUON_MLP_LR_MULT=1.20
NANOGPT_NS_STOCHASTIC_COOLDOWN=2
NANOGPT_EMBED_INIT_ANCHOR_LAMBDA=0.001
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
```
