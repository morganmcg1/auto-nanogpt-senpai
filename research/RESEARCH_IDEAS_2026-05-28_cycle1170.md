# H249 — Riemannian-norm body SI projection (45th mechanism class)
**Cycle ~1170 | Student: alphonse | Date: 2026-05-28**

---

## Summary

Replace the Frobenius norm in `scale_invariant_update_` with the canonical Stiefel Riemannian metric norm `‖g‖_Riem = ‖g − W·(W^T·g)/2‖_F`. The SI hyperball step currently uses `update.norm()` (Frobenius) to scale the step size. The NS5 polar projection guarantees `update` is near-orthogonal, which means `update` lives near the Stiefel manifold `St(n,k)`. On that manifold, the canonical Riemannian norm differs from the Frobenius norm by a projection correction involving the weight matrix `W`. Replacing the Frobenius norm with the Riemannian norm makes the step-size rescaling geometrically consistent with the manifold on which the weights actually evolve.

---

## Mechanism class

**45th mechanism class: post-NS5 step-size norm correction via Riemannian metric**

Sub-class: SI hyperball normalization geometry. Distinct from:
- H238 AdaMuon (per-element diagonal EMA-g² scaling — closed, NULL)
- H248 edward (diagonal EMA-g² preconditioning — 44th class, in-flight, different mechanism: accumulates statistics over time; H249 uses instantaneous geometry)
- Pre-NS5 second-order methods (H92, H93, H98 — closed, all pre-NS5)

---

## Theoretical grounding

### Primary: Brantner 2023 (updated July 2025)
**"Generalizing Adam To Manifolds For Efficiently Training Transformers"**
arxiv:2305.16901

Key result: global tangent space representation of Stiefel manifold enables manifold-respecting first- and second-order optimizer steps with transformer training speedups. Shows that using the Euclidean (Frobenius) norm for step-size scaling on a manifold introduces a geometry mismatch that causes suboptimal convergence. The canonical Riemannian metric on `St(n,k)` is `g_W(X,Y) = tr(X^T (I − WW^T/2) Y)`, giving Riemannian norm `‖g‖_Riem = ‖g − W·(W^T·g)/2‖_F`.

### Supporting: Kong et al. 2023 (ICLR 2023)
**"Momentum Stiefel Optimizer"**
arxiv:2205.14173

Key result: exactly-constraint-preserving manifold optimizer with momentum on Stiefel manifold. Shows that tangent bundle preservation (projecting both gradient AND step onto the tangent space at the current point) is load-bearing for convergence quality. Directly motivates using the Riemannian norm for step sizing.

### Programme context: Davis & Drusvyatskiy 2025
**"When do spectral gradient updates help?"**
arxiv:2512.04299

Explains Muon's advantage via nuclear-to-Frobenius ratio and low stable rank. The Riemannian correction term `W·(W^T·g)/2` has magnitude proportional to the overlap between the update direction `g` and the current column space of `W`. When `W` is near-orthogonal (NS5 ensures this), this overlap is non-trivial and the Riemannian norm systematically differs from the Frobenius norm by a geometry-dependent factor. This factor encodes information about how aligned the update is with the current weight's column space.

### Supporting: Abreu et al. 2025
**"Full Gauss-Newton method outperforms Muon"**
arxiv:2510.09378

Shows that 5.4x fewer iterations are needed with full Gauss-Newton vs Muon, and layerwise GN nearly matches full GN. Motivates post-NS5 second-order corrections. The Riemannian norm is a first-order manifold-consistent correction, not full second-order, but targets the same geometry mismatch at lower cost.

---

## Hypothesis

**H249**: Using the Riemannian norm (canonical Stiefel metric) rather than the Frobenius norm to scale the SI hyperball step improves optimization trajectory quality, reducing FFS from baseline H203=3025.

**Causal chain**: 
1. NS5 maps `update` near the Stiefel manifold (polar factor)
2. `scale_invariant_update_` uses `update.norm()` (Frobenius) to determine step magnitude
3. On the Stiefel manifold, the Frobenius norm overestimates the "true" step length for updates aligned with W's column space, underestimates for orthogonal updates
4. Using `‖g‖_Riem = ‖g − W·(W^T·g)/2‖_F` corrects this: updates aligned with W are rescaled up (the correction term reduces the denominator), orthogonal updates are less affected
5. This results in a more uniform effective step size in the intrinsic geometry, potentially improving convergence rate

**Falsifying observation**: If FFS in arm_b and arm_c are both >= arm_a CTRL at the primary metric endpoint, the hypothesis is falsified. A catastrophic FFS=-1 (never reaching target) rules out both variants entirely.

---

## Injection point analysis

**File**: `records/track_3_optimization/train_gpt_simple.py`

**Current code (line 648-656)**:
```python
def scale_invariant_update_(param, update, lr, eps=1e-10):
    p_norm = param.norm()
    u_norm = update.norm()                          # <-- FROBENIUS NORM HERE
    new_param = param - lr * update * p_norm / torch.clamp(u_norm, min=eps)
    new_norm = torch.clamp(new_param.norm(), min=eps)
    param.copy_(new_param / new_norm * p_norm)
```

**Proposed change**: New function + flag-conditional dispatch in `scale_invariant_update_`:
```python
@torch.compiler.disable
def riemannian_norm_stiefel(update, W, eps=1e-10):
    """
    Canonical Stiefel Riemannian metric norm for near-orthogonal update.
    ‖g‖_Riem = ‖g - W*(W^T*g)/2‖_F
    
    W: current weight matrix (near-orthogonal after NS5, shape [n, k])
    update: post-NS5 update direction (shape [n, k])
    
    Cost: W^T @ update (k×k matmul) + W @ WTg (n×k matmul) + norm
    Same order as one NS5 iteration O(n*k*min(n,k)).
    
    Decorated @torch.compiler.disable to avoid torch.compile retracing
    soft-drift: this branch is argparse-conditional so it MUST be
    outside the compiled region (13+ known retracing instances in campaign).
    """
    WTg = W.T @ update          # shape: (k, k)
    correction = W @ WTg        # shape: (n, k)
    g_riem = update - 0.5 * correction   # tangential correction
    riem_norm = g_riem.norm()
    return torch.clamp(riem_norm, min=eps)

def scale_invariant_update_(param, update, lr, eps=1e-10, riemannian=False, riem_detach=False):
    p_norm = param.norm()
    if riemannian:
        W = param.detach() if riem_detach else param
        u_norm = riemannian_norm_stiefel(update, W, eps=eps)
    else:
        u_norm = update.norm()
    new_param = param - lr * update * p_norm / torch.clamp(u_norm, min=eps)
    new_norm = torch.clamp(new_param.norm(), min=eps)
    param.copy_(new_param / new_norm * p_norm)
```

Pass `riemannian=args.body_riemannian_norm` and `riem_detach=args.body_riem_detach` from the MuonH step dispatch.

---

## torch.compile boundary analysis

**CRITICAL**: The `--body_riemannian_norm` flag creates an argparse-conditional branch. There have been 13+ torch.compile retracing soft-drift instances in this campaign where argparse-conditional branches inside `@torch.compile` inflate step_avg by ~1.8 steps and shift FFS by +25 (~1.3σ_H174).

**Mitigation**: The `riemannian_norm_stiefel` function is decorated with `@torch.compiler.disable`. This ensures the Riemannian norm computation is never traced by torch.compile regardless of which code path is active.

The `scale_invariant_update_` function itself is called from `MuonH.step()`, which is decorated `@torch.no_grad()` but NOT inside `@torch.compile`. Verify this in the codebase — if it is inside a compiled region, add `@torch.compiler.disable` to `scale_invariant_update_` itself as well.

**Bit-identity gate (arm_a CTRL)**: arm_a must hit step-0 val=10.82583 EXACTLY. This confirms no accidental baseline contamination. arm_b and arm_c need not be bit-identical to arm_a (different norm computation), but their step-0 val should be 10.82583 as well (step-0 = forward pass before any optimizer step, so the first forward is identical across all arms).

---

## New argparse flags

```python
parser.add_argument("--body_riemannian_norm", action="store_true", default=False,
                    help="H249: Replace Frobenius norm in SI hyperball with Riemannian Stiefel norm. "
                         "Requires --muonh_mode=scale_invariant. "
                         "Cost: ~2 extra matmuls per MuonH step (O(nk) each).")
parser.add_argument("--body_riem_detach", action="store_true", default=False,
                    help="H249: Use param.detach() for W in Riemannian norm (no gradient through W). "
                         "Only active if --body_riemannian_norm is set.")
```

Add to the W&B config block alongside other body_ flags.

---

## 3-arm experiment design

All arms use the locked baseline stack:
- muonh_mode=scale_invariant (LOCKED)
- MuLoCo: outer_lr=0.7, outer_momentum=0.5, sync_interval=30 (LOCKED)
- Aux AdamW: β₁=0.8, β₂=0.99, eps=1e-6 (LOCKED)
- All other hyperparameters at their H203 baseline values

### arm_a: CTRL (bit-identity baseline)
```bash
python records/track_3_optimization/train_gpt_simple.py \
    --muonh_mode scale_invariant \
    --wandb_group H249_riemannian_norm
```
Expected: val=3.26830, FFS=3025 (H203 baseline)

### arm_b: TREATMENT_DEFAULT (Riemannian norm, current-step W)
```bash
python records/track_3_optimization/train_gpt_simple.py \
    --muonh_mode scale_invariant \
    --body_riemannian_norm \
    --wandb_group H249_riemannian_norm
```
Expected if hypothesis is correct: FFS < 3025

### arm_c: TREATMENT_VARIATION (Riemannian norm, detached W)
```bash
python records/track_3_optimization/train_gpt_simple.py \
    --muonh_mode scale_invariant \
    --body_riemannian_norm \
    --body_riem_detach \
    --wandb_group H249_riemannian_norm
```
Rationale: arm_b uses `param` directly in the norm computation; during backward this creates a gradient path through W. In practice MuonH.step() is `@torch.no_grad()` so this distinction only matters if there's a mixed-precision or gradient accumulation setup. arm_c explicitly uses `param.detach()` to be safe. Also slightly cheaper (one fewer tensor dependency in the DAG).

---

## Telemetry requirements

Log per-step to W&B:
1. `body/riem_norm_mean` — mean Riemannian norm across all MuonH parameters per step
2. `body/frob_norm_mean` — Frobenius norm of post-NS5 update (for comparison)
3. `body/riem_frob_ratio_mean` — ratio `riem_norm / frob_norm` per parameter, then mean across params. Expected: <1.0 when update is aligned with W column space, ~1.0 when orthogonal
4. Standard FFS and val/loss telemetry

The `riem_frob_ratio` is the primary diagnostic: if it is uniformly ~1.0 across training, the Riemannian correction is negligible and the mechanism cannot help. If it shows systematic deviation (especially in early training when W drifts from its initialization), the correction is doing real work.

---

## Expected outcomes

| Outcome | Condition | Interpretation |
|---|---|---|
| FFS < 3025 (WIN) | Both arm_b and arm_c improve | Riemannian geometry correction is load-bearing |
| FFS < 3025 (arm_b only) | arm_c at CTRL | Gradient path through W matters; non-detached norm important |
| FFS < 3025 (arm_c only) | arm_b at CTRL | Detached norm cleaner; gradient contamination was hurting arm_b |
| FFS = 3025 ± 25 (TIES) | Both at baseline | Norm correction is negligible; riem_frob_ratio ≈ 1.0 |
| FFS = -1 (CATASTROPHIC) | Either arm never reaches target | Norm computation is numerically unstable or step-size explodes |

**Distinguish from H248 (edward)**: H248 tests EMA-g² preconditioning (accumulates statistics over time). If both H248 and H249 win, they are orthogonal and stack. If H248 wins but H249 is NULL, it suggests per-element statistics are load-bearing but geometry correction is not. If H249 wins but H248 is NULL, geometry is load-bearing but per-element variance is not.

---

## WIN probability estimate

Campaign base rate: ~10% (of ~248 hypotheses tested, FFS < 3025 by a meaningful margin)

H249 adjustment factors:
- (+) Strong theoretical grounding: Brantner 2023 shows manifold-respecting norms improve transformer optimization; this is the closest analogue to the SI hyperball setting
- (+) Structurally novel: no prior hypothesis in campaign tests the norm metric in SI projection specifically
- (+) Low compute overhead: ~2 extra matmuls per MuonH step (O(nk)), same order as one NS5 iteration
- (+) Orthogonal to in-flight H248: result is interpretable regardless of H248 outcome
- (-) The correction may be small in practice: if W^T @ update is near-zero (update mostly orthogonal to W column space), the Riemannian norm ≈ Frobenius norm and the mechanism is inert
- (-) NS5 already approximates the polar factor; the weights may already be sufficiently close to St(n,k) that geometry corrections are below the FFS-detectable threshold
- (-) Prior NULL results on post-NS5 diagonal scaling (H238 AdaMuon) suggest the NS5 output may already be near-optimal in magnitude distribution

**Estimated WIN probability: ~15%** (above campaign base rate due to theoretical grounding and structural novelty, tempered by risk that the correction is numerically small in this setting)

---

## Implementation checklist for student alphonse

1. Add `--body_riemannian_norm` and `--body_riem_detach` argparse flags (bool/store_true)
2. Implement `riemannian_norm_stiefel(update, W, eps)` decorated with `@torch.compiler.disable`
3. Modify `scale_invariant_update_` to accept `riemannian` and `riem_detach` kwargs, dispatch to Riemannian norm when `riemannian=True`
4. Pass flags from MuonH.step() call site at line 708
5. Add W&B telemetry: `body/riem_norm_mean`, `body/frob_norm_mean`, `body/riem_frob_ratio_mean`
6. Add new flags to the W&B config dict (alongside `muonh_mode`, `muonh_lr`, etc.)
7. Verify bit-identity gate: arm_a must hit step-0 val=10.82583 EXACTLY before running full arms
8. Run all three arms to completion; report FFS for each arm

**Watchouts**:
- The `riemannian_norm_stiefel` call uses `param` (the weight matrix W), NOT `p.grad` or `update`. Verify the shapes: W is [n, k] where n > k for hidden 2D weights. W^T @ update is [k, k], W @ (W^T @ update) is [n, k]. All correct.
- In torch.no_grad() context, the matmuls in `riemannian_norm_stiefel` should not create gradient nodes. The `@torch.compiler.disable` decorator additionally prevents tracing. Belt-and-suspenders is fine.
- If MuonH processes parameters in parallel across ranks (base_i + rank pattern), the `riemannian_norm_stiefel` call executes per-parameter on the responsible rank, which is correct.
- Do NOT apply Riemannian norm to the non-SI (mode="clip") branch — that path is not used (muonh_mode=scale_invariant is LOCKED) but the guard should still be explicit.
