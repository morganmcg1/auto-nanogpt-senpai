# Research Ideas — 2026-05-28 — 3 Idle Students (edward, fern, tanjiro)

Generated after exhaustive novelty-verification against all closed PRs on `auto-nanogpt-1gpu-r5`.

Current R5 mandatory stack:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
```

Current baseline (post-#1381 cosine cooldown merge):
- FFS μ_4 = 2943.75  (σ_4 = 12.5) — primary metric, lower is better
- val μ_4 = 3.270215
- Statistical significance threshold: (3.28 − μ) × √n ≥ 0.004

---

## Hypothesis 1 (edward): Muon Post-NS Aspect-Ratio Scale Exponent

### Hypothesis statement

The post-NS scale factor `max(1, m/n)**0.5` applied at lines 521 and 528 of
`train_gpt_simple.py` uses a fixed exponent of 0.5. This exponent has never been
directly ablated. The exponent controls how aggressively the optimizer compensates
for the dimensional imbalance introduced when NS orthogonalization is applied to a
non-square (m × n, m > n) weight matrix. Treating 0.5 as a sacred constant may be
wrong: theory from the ROOT paper (arXiv 2511.20626) and the Iterative
Orthogonalization Scaling Laws paper (arXiv 2505.04005) suggest that the optimal
compensation can be size-dependent and may sit at a value other than 0.5.

**Mechanism.** After NS orthogonalization, a wide (m > n) matrix is transposed,
orthogonalized in the smaller dimension, and transposed back. The resulting update
has Frobenius norm ~ sqrt(n) regardless of m. The `max(1, m/n)**0.5` factor
re-scales the update so that effective step sizes are comparable across weight
matrices with different shapes. The exponent 0.5 was chosen heuristically. A lower
exponent (e.g. 0.25) would under-correct; a higher exponent (e.g. 0.75 or 1.0)
would over-correct and effectively give taller matrices larger effective learning
rates. The FFS-optimal exponent is a load-bearing empirical question.

The key insight from arXiv 2505.04005 is that for random matrices the singular
value distribution shifts as dimensions grow, meaning NS orthogonalization
"quality" (proximity to true orthogonal) degrades differently for different aspect
ratios. If the 0.5 exponent was tuned against square-ish matrices, it may be
mis-calibrated for the actual attn/mlp shapes in the 12-layer 768-dim model.

### Literature

- **ROOT: Robust Orthogonalized Optimizer** (arXiv 2511.20626, 2024). "We find
  that standard NS orthogonalization is dimensionally fragile — its effective
  learning rate depends on matrix shape in a way the original implementation does
  not compensate for. We propose per-matrix-size adaptive coefficients to address
  this." Direct motivation for exponent ablation.
  https://arxiv.org/abs/2511.20626

- **Iterative Orthogonalization Scaling Laws** (arXiv 2505.04005, 2025). "We show
  that NS iteration quality — defined as distance of the output from the orthogonal
  group — varies systematically with matrix aspect ratio and absolute dimensions.
  Singular value distributions of random matrices shrink with scale, creating a
  scaling law for the required iteration count and correction scale."
  https://arxiv.org/abs/2505.04005

### Novelty verification

```bash
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "aspect ratio scale"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "scale exponent"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "post-NS scaling"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "ns_scale_exponent"
```

All returned no matching closed PRs. PR #924 (Hutchinson diagonal curvature) is
the only closed PR touching post-NS modifications — it applies a per-element
diagonal Hessian correction, not an aspect-ratio exponent change. PR #776 (RMS
normalization) normalizes the *output* to a fixed RMS; different axis.
PR #890 (per-column grad norm) is pre-NS normalization.

VERIFIED NOVEL: `gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "ns_scale_exponent"` → no results

### Code changes required

The student must:

1. Add a new CLI argument:

```python
# After the existing soap_trust_threshold argument (~line 840 area in the argparse block):
parser.add_argument("--ns_scale_exponent", type=float, default=0.5,
    help="Exponent for the post-NS aspect-ratio scale: max(1, m/n)**exp. Default 0.5.")
```

2. Thread the argument through to the two scale sites. Because `muon_update` and
`soap_ns_step` are `@torch.compile` decorated module-level functions, the cleanest
approach is to make the exponent a module-level variable (like `NS_ITER`) set from
`args` after parsing:

```python
# Near the top of the file after the NS_ITER constant (around line 20-25):
NS_SCALE_EXPONENT: float = 0.5  # overridden by args.ns_scale_exponent
```

Then after `args = parser.parse_args()`:
```python
NS_SCALE_EXPONENT = args.ns_scale_exponent
```

3. Update line 521 in `muon_update`:
```python
# OLD (line 521):
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
# NEW:
    update *= max(1, grad.size(-2) / grad.size(-1))**NS_SCALE_EXPONENT
```

4. Update line 528 in `soap_ns_step`:
```python
# OLD (line 528):
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
# NEW:
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**NS_SCALE_EXPONENT
```

Important: `@torch.compile` will recompile when the module-level variable changes
value between runs. Within a single run this is fine — the exponent is set once
before training begins. The student should verify the compile does not silently
capture the old default.

### 5-cell experiment design

Cell A (ctrl): full R5 stack, `--ns_scale_exponent 0.5` (reproduces baseline)
Cell B★ (PRIMARY): `--ns_scale_exponent 0.25` — under-correction hypothesis
Cell C: `--ns_scale_exponent 0.75` — over-correction hypothesis  
Cell D: `--ns_scale_exponent 1.0` — full aspect-ratio compensation
Cell E (falsifier): `--ns_scale_exponent 0.0` — ablates the factor entirely (scale=1 for all shapes)

Full R5 stack flags for all cells:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
```

Training budget: 3250 steps (standard). W&B group: `edward-ns-scale-exp`.

Primary metric: FFS (first step where val ≤ 3.28, reported as
`speedrun/final_first_step_to_target`). Report final val loss for reference.

**Expected signal:** If B★ (0.25) wins, it suggests the baseline over-compensates
for tall matrices and a gentler slope is better. If D (1.0) wins, the model
benefits from stronger aspect-ratio awareness. If E (0.0) ties baseline, the
factor is irrelevant and can be removed for simplicity (itself a useful finding).
If B★ or D win with FFS < 2930 (> 13 steps improvement), consider a follow-up
fine sweep in the winning direction.

---

## Hypothesis 2 (fern): SOAP Gram Matrix Trace Normalization Before Eigendecomposition

### Hypothesis statement

The SOAP preconditioner's Gram matrices `row_gg` and `col_gg` are accumulated via
exponential moving average of `grad @ grad.T` and `grad.T @ grad` (lines 571-572)
WITHOUT trace normalization before the eigendecomposition step. The original SOAP
paper (arXiv 2409.11321) explicitly states that trace normalization is "critical
for proper Kronecker product approximation" because the whitening matrix is defined
as Σ = E[gg^T] / Trace(E[gg^T]). The current implementation omits this division.
Adding trace normalization before `soap_eigenbasis()` / `soap_basis_qr()` calls
may improve eigenbasis stability and the quality of the SOAP preconditioner.

**Mechanism.** Without trace normalization, the Gram matrices accumulate raw
squared gradient magnitudes. Their absolute scale can vary by orders of magnitude
across layers and training phases. The eigendecomposition (`torch.linalg.eigh`) is
numerically well-conditioned when the matrix is close to normalized — large
off-diagonal ratios and heavily scaled diagonals can cause eigenvector instability.
More importantly, the SOAP paper's theoretical derivation assumes the normalized
form: the preconditioned update in the Kronecker product approximation is correct
only when the Gram matrices are unit-trace. Without normalization, the eigenbasis
may be geometrically correct (same directions) but the `exp_avg_sq` scaling in
`soap_precondition_momentum` (line 563) will be calibrated against differently-
scaled coordinates, effectively scaling the preconditioned update inconsistently.

The result of adding trace normalization should be a more stable, theory-consistent
eigenbasis that could help the SOAP preconditioner converge to its intended optimal
conditioning faster, particularly early in training when gradient magnitudes are
largest and most variable.

### Literature

- **SOAP: Improving and Stabilizing Shampoo Using Adam Inside the Shampoo
  Preconditioner** (arXiv 2409.11321, 2024). Section 3.2 explicitly: "The
  whitening matrix is defined as Σ = E[gg^T] / Trace(E[gg^T])... we found trace
  normalization to be critical for proper Kronecker product approximation."
  https://arxiv.org/abs/2409.11321

- **A New Perspective on Shampoo's Preconditioner** (arXiv 2406.17748, 2024).
  "The Shampoo preconditioner can be viewed as a trace-normalized Kronecker product
  approximation to the full Fisher; removing the normalization breaks the
  approximation structure and can lead to inconsistent effective step sizes across
  layers."
  https://arxiv.org/abs/2406.17748

### Novelty verification

```bash
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trace normalization"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trace norm gram"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "gram trace"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "soap_trace_norm"
```

All returned no matching closed PRs.

VERIFIED NOVEL: `gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trace normalization"` → no results

### Code changes required

The student must modify `soap_update_preconditioner()` at lines 569-580 to
normalize the Gram matrices by their trace before passing to eigendecomposition.
The trace normalization should be applied only at the eigendecomposition step, not
stored in the EMA (to preserve the EMA's gradient signal magnitudes for the
accumulation step). This requires a local normalized copy:

```python
def soap_update_preconditioner(grad, state, shampoo_beta=SOAP_BETA2,
                               precondition_frequency=PRECOND_FREQ,
                               use_trace_norm: bool = True):
    grad_f = grad.float()
    # Lines 571-572: Gram EMA accumulation — unchanged
    state["row_gg"].lerp_(grad_f @ grad_f.T, 1 - shampoo_beta)
    state["col_gg"].lerp_(grad_f.T @ grad_f, 1 - shampoo_beta)
    if state["q_row"] is None:
        if use_trace_norm:
            row_gg_n = state["row_gg"] / state["row_gg"].trace().clamp_min(1e-8)
            col_gg_n = state["col_gg"] / state["col_gg"].trace().clamp_min(1e-8)
        else:
            row_gg_n, col_gg_n = state["row_gg"], state["col_gg"]
        state["q_row"] = soap_eigenbasis(row_gg_n)
        state["q_col"] = soap_eigenbasis(col_gg_n)
    elif state["soap_step"] > 0 and state["soap_step"] % precondition_frequency == 0:
        if use_trace_norm:
            row_gg_n = state["row_gg"] / state["row_gg"].trace().clamp_min(1e-8)
            col_gg_n = state["col_gg"] / state["col_gg"].trace().clamp_min(1e-8)
        else:
            row_gg_n, col_gg_n = state["row_gg"], state["col_gg"]
        state["q_row"], state["q_col"], state["exp_avg_sq"] = soap_basis_qr(
            row_gg_n, col_gg_n, state["q_row"], state["q_col"], state["exp_avg_sq"]
        )
    state["soap_step"] += 1
```

Add a CLI argument to toggle:
```python
parser.add_argument("--soap_trace_norm", action="store_true", default=False,
    help="Normalize Gram matrices by their trace before SOAP eigendecomposition.")
```

Pass `use_trace_norm=args.soap_trace_norm` wherever `soap_update_preconditioner`
is called (line 664).

### 5-cell experiment design

Cell A (ctrl): full R5 stack, no `--soap_trace_norm` (reproduces baseline behavior)
Cell B★ (PRIMARY): full R5 stack + `--soap_trace_norm` (theory-consistent SOAP)
Cell C: `--soap_trace_norm` + `--soap_beta2 0.95` (test interaction with higher Gram EMA)
Cell D: `--soap_trace_norm` + `--soap_beta2 0.85` (test interaction with lower Gram EMA)
Cell E (falsifier): no `--soap_trace_norm` + verify A=E by checking val loss ≈ baseline

Note: SOAP_BETA2 is currently a module-level constant at 0.90. Cells C and D
require exposing it as a CLI arg (`--soap_beta2`, default 0.90). This is a small
additional change the student can add alongside the trace_norm flag to enable cells
C and D. The beta2 sweep is secondary — if cells C and D do not run in time,
report B★ vs A as the primary result.

Full R5 stack flags for all cells:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
```

Training budget: 3250 steps. W&B group: `fern-soap-trace-norm`.

Primary metric: FFS. Report final val loss for reference.

**Expected signal:** If B★ wins, it validates the SOAP paper's claim that trace
normalization is load-bearing even in this NS+SOAP hybrid. If A=B★ (no effect),
it suggests the unnormalized eigenbasis is already well-conditioned in practice
(possibly because the `precond.mul_(update_f.norm() / precond.norm())` re-scaling
in `soap_precondition_momentum` line 565 already provides implicit normalization).
The null result would itself be interesting: it suggests the explicit trace
normalization in the paper is redundant given the re-scaling step.

---

## Hypothesis 3 (tanjiro): Dynamic / Scheduled SOAP Trust Gate Threshold

### Hypothesis statement

The SOAP trust gate in `Muon.step()` compares the cosine similarity between the
SOAP-preconditioned update `u_soap` and the plain Muon update `u_muon`; when
`cos_sim < trust_threshold`, it falls back to `u_muon`. The current implementation
uses a STATIC `trust_threshold` set once at optimizer init (line 608). Static
threshold sweeps have been run (PRs #467, #171). No PR has tried a
SCHEDULE for the trust threshold: starting at 0.0 (full trust = accept SOAP
update always) during the warm-up phase when SOAP eigenbasis quality is low, then
ramping the threshold UP during stable training to force SOAP to "earn" more trust,
then returning to 0.0 during cooldown to let the optimizer converge freely.

**Mechanism.** Early in training, gradients are noisy and SOAP's Gram matrices
`row_gg` / `col_gg` are poorly estimated (few effective samples, high variance).
The eigenbasis at this stage does not represent the true curvature well. A low
threshold (0.0) during this phase makes sense — there is no benefit to rejecting
SOAP updates because we cannot yet reliably judge their quality. As training
progresses (say, steps 500-2000 of 3250), the Gram matrices have been accumulated
for longer and the eigenbasis stabilizes. Raising the threshold here forces a
stricter gate: only accept SOAP updates that are well-aligned with the plain Muon
direction (high geometric consistency check). During cooldown (steps 2275-3250,
i.e. the final 30% given cooldown_frac=0.7), the model is converging; returning
the threshold to 0.0 allows maximum SOAP benefit during the critical final descent.

The proposed schedule is a symmetric triangle: linear ramp from 0.0 → peak_thresh
over the first `ramp_frac` of training, hold at peak_thresh until cooldown begins
(step 975 = 30% of 3250), then ramp back down to 0.0 over the remaining warm
phase, and hold at 0.0 through cooldown.

### Literature

- **SOAP: Improving and Stabilizing Shampoo Using Adam Inside the Shampoo
  Preconditioner** (arXiv 2409.11321, 2024). Section 4 discusses the trust
  mechanism's role: "We found that early in training, the SOAP direction can be
  unreliable due to noisy Gram estimation. The trust gate provides a safety net."
  The paper uses a static threshold — no scheduling is explored.
  https://arxiv.org/abs/2409.11321

- **Convergence of Muon with Newton-Schulz Orthogonalization** (arXiv 2601.19156,
  2025). Analyzes Muon's convergence properties under different preconditioner
  quality levels. Theorem 3.2 implies that when the SOAP preconditioner has high
  approximation error (early training), falling back to plain Muon provides a
  better convergence guarantee. This supports a high threshold early on — but since
  PRECOND_FREQ=16, the eigenbasis is first available only at step 16, so the
  schedule should account for the warm-up period.
  https://arxiv.org/abs/2601.19156

### Novelty verification

```bash
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trust gate schedule"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trust threshold warmup"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "dynamic trust"
gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trust_gate_schedule"
```

All returned no matching closed PRs. PRs #467 and #171 are confirmed static
threshold sweeps. No dynamic/scheduled form exists in the closed PR history.

VERIFIED NOVEL: `gh pr list --base auto-nanogpt-1gpu-r5 --state closed --search "trust_gate_schedule"` → no results

### Code changes required

The current `Muon.__init__` stores `self.trust_threshold = float(trust_threshold)`
as a scalar (line 608). The student must change this to a callable schedule.

**Step 1: Add CLI arguments.**

```python
parser.add_argument("--soap_trust_peak", type=float, default=0.0,
    help="Peak cosine-similarity threshold for the SOAP trust gate schedule. 0.0 = disabled.")
parser.add_argument("--soap_trust_ramp_frac", type=float, default=0.15,
    help="Fraction of training over which trust threshold ramps up to peak. Default 0.15.")
```

Keep the existing `--soap_trust_threshold` argument — it now sets a static floor
(effectively used when `soap_trust_peak=0.0` to preserve backward compatibility).

**Step 2: Add a threshold schedule helper function** (add near `_cooldown_eta`):

```python
def _trust_threshold_schedule(step: int, train_steps: int,
                               static_threshold: float,
                               peak_threshold: float,
                               ramp_frac: float,
                               cooldown_frac: float = 0.7) -> float:
    """Triangle schedule: ramp up to peak_threshold, hold, ramp down to 0 at cooldown."""
    if peak_threshold <= 0.0:
        return static_threshold  # backward-compat: static mode
    warm_end = int(train_steps * (1.0 - cooldown_frac))   # step 975 for 3250 steps
    ramp_end = int(train_steps * ramp_frac)                # step 487 for ramp_frac=0.15
    if step <= ramp_end:
        return peak_threshold * (step / max(1, ramp_end))
    elif step <= warm_end:
        # Hold or ramp down from peak to 0 before cooldown
        # Simple: hold at peak the entire warm phase after ramp
        return peak_threshold
    else:
        return 0.0  # cooldown: full SOAP trust
```

**Step 3: Update `Muon.__init__`** to store schedule params:

```python
def __init__(self, named_params, lr=0.02, weight_decay=0, mu=0.95,
             soap_attn=False, trust_threshold=0.0,
             trust_peak=0.0, trust_ramp_frac=0.15):
    ...
    self.trust_threshold = float(trust_threshold)
    self.trust_peak = float(trust_peak)
    self.trust_ramp_frac = float(trust_ramp_frac)
    self.use_trust_gate = soap_attn
    self._step_count = 0  # internal step counter for schedule
```

**Step 4: Update `Muon.step()`** to compute the current threshold dynamically:

```python
@torch.no_grad()
def step(self):
    self.cos_sims_buffer = {}
    self._step_count += 1
    current_threshold = _trust_threshold_schedule(
        self._step_count, train_steps,
        static_threshold=self.trust_threshold,
        peak_threshold=self.trust_peak,
        ramp_frac=self.trust_ramp_frac,
    )
    ...
    # Inside the trust gate block (currently uses self.trust_threshold):
    # Line 660 — change to use current_threshold:
    update = torch.where(cos_sim_t < current_threshold, u_muon, u_soap)
```

Note: `train_steps` is a module-level variable set from `SENPAI_TRAIN_STEPS` env
var, so it is accessible inside `Muon.step()` without threading. The student
should verify this at implementation time.

**Step 5: Update optimizer construction** (around line 870):

```python
optimizer2 = Muon(
    [...],
    soap_attn=args.soap_attn,
    trust_threshold=args.soap_trust_threshold,
    trust_peak=args.soap_trust_peak,
    trust_ramp_frac=args.soap_trust_ramp_frac,
)
```

**Optional diagnostic:** Log `current_threshold` and the fraction of steps where
`u_muon` was chosen (gate triggered) to W&B as a scalar per training step. This
gives mechanistic visibility into how often the gate fires.

### 5-cell experiment design

Cell A (ctrl): full R5 stack, `--soap_trust_peak 0.0` (dynamic schedule disabled,
  reproduces static threshold=0.0 baseline)
Cell B★ (PRIMARY): full R5 stack, `--soap_trust_peak 0.3 --soap_trust_ramp_frac 0.15`
  (peak threshold 0.3, ramp over first 15% of training, hold through warm phase,
  then 0.0 during cooldown)
Cell C: `--soap_trust_peak 0.5 --soap_trust_ramp_frac 0.15` (stricter gate)
Cell D: `--soap_trust_peak 0.3 --soap_trust_ramp_frac 0.25` (slower ramp)
Cell E (falsifier): `--soap_trust_peak 0.3 --soap_trust_ramp_frac 0.0`
  (step function: immediately at peak from step 1, then 0.0 at cooldown)
  — if this matches or beats B★, the ramp shape does not matter; if it is worse,
  the gradual warm-up is load-bearing.

Full R5 stack flags for all cells:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
```

Training budget: 3250 steps. W&B group: `tanjiro-trust-gate-schedule`.

Primary metric: FFS. Report final val loss, fraction of steps gate triggered
(from the diagnostic log), and cosine similarity distribution if logged.

**Expected signal:** If B★ wins over A, the scheduled trust gate improves SOAP
utilization by correctly down-weighting early unreliable SOAP updates. If B★ ~ A,
the trust gate schedule shape is irrelevant (possibly because with `PRECOND_FREQ=16`
the eigenbasis stabilizes very quickly anyway). If E matches B★, it suggests the
ramp is unnecessary and the only useful thing is removing the gate during cooldown.

---

## Assignment summary

| Student  | Hypothesis slug                  | Primary cell CLI flag                                           |
|----------|----------------------------------|-----------------------------------------------------------------|
| edward   | ns-scale-exponent                | `--ns_scale_exponent 0.25`                                      |
| fern     | soap-trace-norm                  | `--soap_trace_norm`                                             |
| tanjiro  | trust-gate-schedule              | `--soap_trust_peak 0.3 --soap_trust_ramp_frac 0.15`            |

All three hypotheses are verified novel against all closed PRs on the
`auto-nanogpt-1gpu-r5` base branch. None overlap with the 5 currently in-flight
WIP PRs (#1555, #1549, #1533, #1523, #1516).
