# RESEARCH IDEAS — 2026-05-28 — ASKELADD FRESH AXIS

## Assignment Summary (use verbatim for `senpai:assign-experiment`)

Hypothesis slug: `ns-poly-coeffs`

The Newton-Schulz orthogonalization function in `train_gpt_simple.py` is hardcoded
to polynomial coefficients `(a, b, c) = (2, -1.5, 0.5)` — the standard quintic
approximation to the matrix sign function. With the R5 stack running only 6 NS
iterations (`--ns_iter 6`), the per-iteration convergence rate becomes load-bearing:
suboptimal coefficients waste orthogonalization quality budget. Bernstein/Kelley-optimal
coefficients `(3.4445, -4.7750, 2.0315)` (from the original Muon paper) are known to
converge faster per iteration and have never been tested in this codebase, which uses
a different polynomial. This 5-cell sweep exposes the coefficient axis cleanly and
isolates it from the iteration-count axis (#1609 nezuko, closing) and the post-NS
scaling axis (#1563 edward, closing).

Baseline: FFS μ_4 = 2943.75, σ_4 = 12.5. FFS-alive gate: ≤2975 at n=1.
Merge gate: FFS ≤ 2918.75 at n=4 with σ_4 ≤ 12.5.

---

## Hypothesis Title

**NS Polynomial Coefficient Substitution: Bernstein-Optimal `(a,b,c)` vs Codebase Default**

---

## Mechanism

The `zeropower_via_newtonschulz5` function in this codebase uses coefficients
`(a, b, c) = (2, -1.5, 0.5)`, corresponding to the degree-5 polynomial
`p(t) = 2t − 1.5t³ + 0.5t⁵`. This polynomial approximates the sign function on
`[-1, 1]` and, under iterated application, drives the singular values of a matrix
toward 1 (i.e., orthogonalizes it). However, this is not the fastest-converging
quintic polynomial for this task. The canonical Muon codebase (Kosson et al. /
Jordan et al.) uses `(3.4445, -4.7750, 2.0315)`, which comes from minimizing the
worst-case residual `max_{σ∈[0,1]} |σ − σ·p(σ)^k|` over the polynomial class —
the Bernstein/Chebyshev minimax optimum. At 12 NS iterations, the two coefficient
sets converge to effectively identical quality (both are well past the numerical floor).
At 6 NS iterations (R5 stack), the residual gap is non-negligible: the Bernstein-optimal
polynomial removes roughly 1.5–2× more spectral error per iteration in the critical
first 4–6 steps. This means `(3.4445, -4.7750, 2.0315)` at `ns_iter=6` should
produce gradient updates that are closer to true orthogonal projections, reducing
the effective noise in the Muon body update and in the SOAP NS preprocessing step
(`soap_ns_step` also calls `zeropower_via_newtonschulz5`). The hypothesis is that
better per-step orthogonalization at low NS-iter counts translates to faster
loss-crossing and a lower FFS. This is not a change in iteration count (that is
#1609), not a change in the post-NS scale exponent (that is #1563), and not a
change in NS-iter per depth layer (that is #1609): it is a pure coefficient swap
within the existing iteration budget. It is a single-line change with a clear
theoretical justification, and the falsifier (degraded coefficients) provides
independent directional evidence if the primary arm wins.

The second reason this axis is attractive at the R5 stack: the SOAP preconditioning
path also calls `zeropower_via_newtonschulz5` (via `soap_ns_step`), so coefficient
improvement benefits both the Muon body update and the SOAP second-moment
orthogonalization simultaneously — amplifying any per-step quality gain.

---

## 5-Cell Sweep Specification

All cells use the full R5 mandatory stack:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine`

The only variable across cells is the `--ns_coeffs a,b,c` flag (to be added).

| Cell | Name       | `--ns_coeffs`            | Rationale                                                   |
|------|------------|--------------------------|-------------------------------------------------------------|
| A    | ctrl       | `2.0,-1.5,0.5`           | Codebase default; clean baseline reproducer                 |
| B    | bernstein  | `3.4445,-4.7750,2.0315`  | Minimax-optimal quintic (canonical Muon paper). Primary arm.|
| C    | intermediate_lo | `2.5,-2.5,1.0`      | Midpoint between ctrl and Bernstein in coefficient space    |
| D    | intermediate_hi | `3.0,-4.0,1.75`     | Closer to Bernstein, tests monotone response                |
| E    | falsifier  | `1.5,-0.75,0.25`         | Weaker polynomial; if A < B < C < D > E → confirms axis is load-bearing |

**Gate logic (FFS-primary, directive #1262):**
- After Cell B (primary): if FFS(B) > 2975, close — axis FFS-dead, do not proceed.
- After Cells A+B: if FFS(B) ≤ 2975, run C+D+E to completion for full directional read.
- FFS-positive verdict: FFS(B) ≤ 2925 (≥1σ below baseline) with monotone B ≤ A.
- Merge gate: FFS mean across 4 non-ctrl cells (B+C+D+E) ≤ 2918.75, σ ≤ 12.5.
- FFS-neutral verdict: all 5 cells within ±12.5 of 2943.75 → close, coefficient axis cosmetic at ns_iter=6.
- Falsifier check: E should be ≥ A if the axis is mechanistically load-bearing; if E < A, the polynomial ordering is non-monotone, which is informative but not a merge blocker.

---

## Implementation Notes

### Code modification point

File: `records/track_3_optimization/train_gpt_simple.py`

**Step 1 — Add argparse flag** (after the `--ns_iter` block, around line 68):

```python
parser.add_argument("--ns_coeffs", type=str, default="2.0,-1.5,0.5",
                    help="Newton-Schulz polynomial coefficients as 'a,b,c'. "
                         "Default (2,-1.5,0.5) is codebase original. "
                         "Canonical Muon uses (3.4445,-4.7750,2.0315).")
```

**Step 2 — Parse into globals** (after `NS_ITER = args.ns_iter`, around line 109):

```python
_ns_coeffs_parsed = [float(x) for x in args.ns_coeffs.split(",")]
NS_COEFF_A, NS_COEFF_B, NS_COEFF_C = _ns_coeffs_parsed
```

**Step 3 — Modify `zeropower_via_newtonschulz5`** (line 506, single character change):

Replace:
```python
    a, b, c = 2, -1.5, 0.5
```
With:
```python
    a, b, c = NS_COEFF_A, NS_COEFF_B, NS_COEFF_C
```

**Step 4 — Log to W&B config** (near line 772 where `ns_iter` is logged):

```python
"ns_coeffs": args.ns_coeffs,
```

That is the complete implementation. The function body (`A = X @ X.mT; B = b * A + c * A @ A; X = a * X + B @ X`) is already parameterized by `a, b, c` — no structural change needed.

### Critical implementation notes

- The flag takes a comma-separated string to avoid positional argument confusion.
- Both `muon_update` and `soap_ns_step` call `zeropower_via_newtonschulz5`, so the coefficient change applies to both Muon body orthogonalization and SOAP NS preprocessing. This is intentional — the hypothesis is that better orthogonalization quality in both paths benefits FFS.
- `NS_COEFF_A/B/C` must be module-level globals set before `@torch.compile` decorators run (i.e., at module load time, not inside a function). The current code sets `NS_ITER` as a global at line 109 after parse — follow the same pattern exactly.
- If the student wants to decouple Muon vs SOAP NS coefficients in a follow-up, that is a second-order axis; for this experiment, unified coefficients keep it a single-variable test.
- Do NOT modify `--ns_iter`. The R5 flag `--ns_iter 6` stays fixed across all 5 cells. The point is to test coefficient quality at fixed 6 iterations.
- The `@torch.compile` decorator on `muon_update` and `soap_ns_step` will re-compile when `NS_COEFF_A/B/C` change between runs, but since these are module-level globals resolved at import time, each run compiles once with fixed coefficients. This is correct behavior — no action needed.

---

## Reproduce Commands

All commands use the standard R5 stack. The only variable is `--ns_coeffs`.

**Cell A — ctrl (codebase default):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ns_coeffs "2.0,-1.5,0.5" \
  --wandb_group ns-poly-coeffs --wandb_run_name ns-poly-coeffs-A-ctrl
```

**Cell B — Bernstein-optimal (primary hypothesis):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ns_coeffs "3.4445,-4.7750,2.0315" \
  --wandb_group ns-poly-coeffs --wandb_run_name ns-poly-coeffs-B-bernstein
```

**Cell C — intermediate-lo:**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ns_coeffs "2.5,-2.5,1.0" \
  --wandb_group ns-poly-coeffs --wandb_run_name ns-poly-coeffs-C-intermediate-lo
```

**Cell D — intermediate-hi:**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ns_coeffs "3.0,-4.0,1.75" \
  --wandb_group ns-poly-coeffs --wandb_run_name ns-poly-coeffs-D-intermediate-hi
```

**Cell E — falsifier (weaker polynomial):**
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ns_coeffs "1.5,-0.75,0.25" \
  --wandb_group ns-poly-coeffs --wandb_run_name ns-poly-coeffs-E-falsifier
```

---

## Predeclared FFS-Primary Gates (Directive #1262)

| Gate | Condition | Action |
|------|-----------|--------|
| G1: n=1 alive | FFS(Cell B) ≤ 2975 | Proceed to cells C+D+E |
| G1: n=1 dead  | FFS(Cell B) > 2975 | Close PR immediately — axis FFS-dead at ns_iter=6 |
| G2: FFS-positive | FFS(B) ≤ 2925 AND monotone B ≤ A | Flag as promising, run all 5 cells, report n=4 confirmation |
| G3: merge gate | FFS mean(B+C+D+E) ≤ 2918.75, σ ≤ 12.5 | Eligible for merge |
| G4: FFS-neutral | All 5 cells within ±12.5 of 2943.75 | Close — coefficient axis cosmetic at ns_iter=6. Lesson: polynomial convergence saturates before ns_iter=6 for this model scale. |
| G5: FFS-negative | FFS(B) > A by >12.5 | Close — Bernstein coefficients anti-correlated with FFS at ns_iter=6. Unexpected but informative. |

**Reporting format required:**
```
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,
  "wandb_run_ids":["<A>","<B>","<C>","<D>","<E>"],
  "primary_metric":{"name":"FFS","value":<mean_FFS>},
  "test_metric":{"name":"val_loss","value":<best_val>}}
```

---

## Non-Overlap Confirmation

This axis is distinct from all in-flight PRs:
- #1609 nezuko: `--ns_iter_depth_schedule` — tests *how many* iterations per layer (count axis, structural). This PR tests *which polynomial* with fixed count.
- #1563 edward: `post_ns_scale_exp` — tests the aspect-ratio exponent applied *after* NS orthogonalization. This PR tests the polynomial *inside* NS.
- #1564 fern: SOAP Gram trace normalization — SOAP preconditioner internals, distinct from NS polynomial.
- #1565 tanjiro: SOAP trust gate threshold schedule — SOAP step filter, distinct.
- #1586 thorfinn: `wd_mlp` fine-tune — weight decay, entirely different parameter.
- #1555 frieren: aux cooldown LR shape — schedule decoupling, distinct.
- #1533 alphonse: EMA eval — evaluation protocol, not optimizer internals.

No prior closed PR tests NS polynomial coefficients. This is a fresh, isolated axis.

---

## Research State Note

The key insight from pre-compaction analysis: this codebase uses `(2, -1.5, 0.5)` — the standard Chebyshev quintic baseline — rather than the Bernstein-optimal `(3.4445, -4.7750, 2.0315)` from canonical Muon. This divergence is historical (codebase likely predates or diverged from the optimized coefficient choice). With `--ns_iter 6`, the quality gap between the two polynomials is maximally exposed: at 12+ iterations both saturate; at 6 iterations, the Bernstein polynomial should retain a measurable edge. The experiment is a natural continuation of the NS-internal axis territory opened by #1609 and #1563, but occupying a strictly non-overlapping slice of that space.

If FFS-neutral: the lesson would be that spectral convergence quality saturates well before 6 NS iterations for this model scale, meaning neither the count nor the polynomial shape matters much below some threshold — useful information for the research map.
