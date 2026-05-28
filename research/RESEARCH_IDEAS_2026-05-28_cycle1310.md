# Research Ideas — Cycle 1310 (2026-05-28)
# Student: g1r3-tanjiro
# Hypothesis: H251

---

## H251: NS5 Polar Output Decomposition Ablation
**Mechanism class #47 — NS5 update-signal geometry: sign-only vs magnitude-only vs polar (CTRL)**

---

### One-Sentence Mechanism Label

Ablate whether the FFS gain from NS5 comes from its directional component (sign/orientation, Q-like orthogonal factor) or its magnitude component (Frobenius-norm scaling, Σ-like factor), by replacing the NS5 output with three mathematically clean alternatives and measuring which geometric property is load-bearing.

---

### Theoretical Grounding

**Background: what NS5 actually computes.**

`zeropower_via_newtonschulz5` approximates the polar factor Q = UVᵀ of the gradient matrix G = UΣVᵀ via a degree-5 Chebyshev-like matrix polynomial iteration. After convergence, the output X satisfies XᵀX ≈ I (columns approximately orthonormal) for a tall matrix. The spectral norm of X is bounded to ≤ 1 by the pre-normalization step.

The step then applies a scale factor `max(1, m/n)^0.5` where m, n are the weight dimensions. This is a fan-in-like RMS equalizer that re-scales the approximately-orthogonal update so that the expected RMS of the weight delta matches a fixed level regardless of matrix shape.

The standard NS5 output therefore mixes two distinct geometric signals:
1. **Directional signal**: the orientation of the weight-space update, encoded as the polar factor Q — this carries the "which subspace to move in" information.
2. **Magnitude-equalizer signal**: the `(m/n)^0.5` re-scaling, which normalizes effective step size across layers with different aspect ratios.

Critically, Programme Finding #51 establishes that *within-NS5 iteration mechanics are fully exhausted* — polynomial coefficients (a/b/c), iteration count, spectral-norm preconditioning, projection mode, and Schatten-p variants all closed. But this closes only the *quality* of the polar approximation. It does NOT close the question of whether the polar approximation is the right form of output signal at all.

**Why this is a fresh axis.**

The sign-only vs magnitude-only split is a decomposition of what the current NS5 output *means*, not a variation of how it's computed. It tests the hypothesis: "Is the polar factor load-bearing, or is MuonH's gain coming primarily from the magnitude-normalization effect alone?"

- If **sign_only wins**: the directional signal (Q) is doing the work, and NS5 is functioning as a learned preconditioner that finds the high-curvature subspace. This would suggest further investment in better preconditioners (e.g., approximate eigenvector directions, natural gradient).
- If **magnitude_only wins**: the equal-variance step-size normalization is doing the work, and the orthogonalization is noise or harmful. This would point toward simpler per-layer RMS normalizers (e.g., AdaFactor-style scale-free updates) as a cheaper replacement.
- If **neither wins (CTRL dominates)**: the joint effect is necessary — neither component alone is sufficient. This constrains future directions toward methods that preserve both properties simultaneously.

**Key references.**

- Björck & Bowie (1971) "An Iterative Algorithm for Computing the Best Estimate of an Orthogonal Matrix" — original motivation for polar decomposition via Newton iteration.
- Bernstein & Newhouse (2024) "Old Optimizer, New Norm" (arXiv:2409.20325) — connects sign-based updates (e.g., Signum, SignSGD) to orthogonal preconditioners. Directly relevant: they show that sign descent and polar-factor descent both approximate the same geometry in the symmetric case.
- Kosson et al. (2024) "Spectral Decoupled Training" — separates spectral norm from directional component in gradient updates for transformers.
- Vyas et al. "SOAP" (arXiv:2409.11321, 2024) — Shampoo-like optimizer that preconditions in the eigenbasis of the gradient outer product; a win for sign_only would suggest SOAP-family directions.
- Jordan et al. (2023) "MUON" blog post (kellerjordan.github.io) — direct ancestor; explicitly motivates NS5 as a sign-like preconditioner for matrix gradients.

---

### Experimental Design: 3-Arm Ablation

All arms use `--train_steps 3350`, `--num_trials 1` for screening. CTRL arm must pass the bit-identity gate before WIP runs are interpreted.

**Arm A — CTRL (polar, baseline-identical):**
`--ns5_output_mode polar`

This is bit-identical to the current baseline. Step-0 val MUST equal 10.82583.

**Arm B — sign_only:**
`--ns5_output_mode sign_only`

After the NS5 loop converges, the output X is an approximately-orthogonal matrix. In `sign_only` mode: further normalize each column of X to unit L2-norm (column-normalize X → X / ||X_col||). This strips out the Frobenius-norm magnitude information while preserving the orientation/direction. The `(m/n)^0.5` scale factor is still applied afterward to equalize step sizes across shapes.

Concretely: `X = F.normalize(X, dim=-2)` after the NS5 loop returns, before the `(m/n)^0.5` multiply. (Normalize along the row dimension of the tall-matrix-normalized form.)

**Arm C — magnitude_only:**
`--ns5_output_mode magnitude_only`

Skip the NS5 loop entirely. Instead, return the gradient pre-normalized to unit Frobenius norm: `X = G / (G.norm(dim=(-2,-1), keepdim=True) + 1e-7)` (same as the spectral-norm pre-normalization step, but returned directly), followed by the same `(m/n)^0.5` scale factor. This preserves the magnitude-equalization effect (uniform-ish step size across layers) but uses the raw gradient direction rather than the orthogonalized direction.

This is equivalent to a "normalized SGD with unit-Frobenius gradient" update — computationally cheaper since it skips the 12 NS5 iterations.

---

### Critical Implementation Notes: torch.compile Safety

**The constraint**: `muon_update` is decorated with `@torch.compile`. Any Python conditional inside a compiled function causes graph retrace on each evaluation with a new conditional branch value, producing soft-drift (~+25 FFS penalty confirmed in prior drift-class diagnostics).

**The correct implementation pattern**: Do NOT add a conditional branch inside `muon_update`. Instead, define THREE SEPARATE top-level compiled functions at module scope, one per mode:

```python
# --- NS5 polar output decomposition (H251) ---
# Three separate compiled functions, one per mode.
# Selection happens at Python scope (after argparse), BEFORE the training loop.
# No conditional branch inside any compiled region.

@torch.compile
def muon_update_polar(grad, momentum, mu=0.95, nesterov=True):
    """Standard baseline: NS5 polar factor output."""
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update

@torch.compile
def muon_update_sign_only(grad, momentum, mu=0.95, nesterov=True):
    """Sign-only: NS5 output column-normalized to unit L2, direction only."""
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    # Run NS5 to get approximately-orthogonal direction
    update = zeropower_via_newtonschulz5(update)
    # Strip magnitude: normalize columns (dim=-2 for tall-normalized form)
    update = torch.nn.functional.normalize(update, dim=-2)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update

@torch.compile
def muon_update_magnitude_only(grad, momentum, mu=0.95, nesterov=True):
    """Magnitude-only: skip NS5, use unit-Frobenius raw gradient direction."""
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    # Skip NS5 entirely; use raw gradient direction with Frobenius normalization
    update = update / (update.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update
```

Then, after argparse and BEFORE the training loop (at Python scope, outside any compiled region):

```python
# Bind the correct update function at Python scope based on args.
# This assignment is NOT compiled and incurs zero retrace penalty.
_NS5_OUTPUT_MODES = {
    "polar":          muon_update_polar,
    "sign_only":      muon_update_sign_only,
    "magnitude_only": muon_update_magnitude_only,
}
muon_update_fn = _NS5_OUTPUT_MODES[args.ns5_output_mode]
```

In `MuonH.step`, replace the call `muon_update(...)` with `muon_update_fn(...)`. Since `muon_update_fn` is a module-level name bound before training starts, `@torch.compile` sees a single fixed callable — no retrace.

**New argparse flag** (add after existing flags, before `args = parse_args()`):

```python
parser.add_argument("--ns5_output_mode", type=str,
                    default=os.environ.get("NS5_OUTPUT_MODE", "polar"),
                    choices=["polar", "sign_only", "magnitude_only"],
                    help="NS5 polar output decomposition mode. "
                         "'polar' (default) = standard NS5 polar factor, bit-identical to baseline. "
                         "'sign_only' = NS5 direction with columns L2-normalized (strips Frobenius magnitude). "
                         "'magnitude_only' = skip NS5 loop; use unit-Frobenius raw gradient direction only.")
```

**Note on `normalize` import**: `torch.nn.functional.normalize` is standard in the existing codebase. Confirm with `import torch.nn.functional as F` already present or use `torch.nn.functional.normalize` inline.

---

### Bit-Identity Gate

Before interpreting any arm results, run CTRL arm (`--ns5_output_mode polar`) and verify:
- Step 0 validation loss = **10.82583** (must match to 5 decimal places)
- Step 0 train loss = finite and in normal range (~10.7–11.0)
- No retrace warnings in torch.compile output

If step-0 val does not match, there is a compile-graph change or init side-effect. Do NOT proceed to B/C arm comparison until CTRL is bit-identical.

---

### Diagnostic Telemetry

Add these metrics to the W&B telemetry block (in the `telemetry_interval` logging section):

1. **`train/ns5_cosine_to_grad`**: cosine similarity between the NS5 output (before scale factor) and the raw gradient direction, averaged over all MuonH body params. This quantifies how much NS5 is rotating the gradient direction. Expected near 1.0 early in training (gradient is nearly rank-1 in early layers), falling toward ~0.5 later. If `sign_only` matches CTRL on FFS, this metric tells us whether the rotation was cosmetic.

2. **`train/ns5_update_rms_cv`**: coefficient of variation (std/mean) of per-layer RMS update norms, over all MuonH body params. Should be lower for `polar` than `magnitude_only` if the scale equalization is working. A high CV means step sizes are highly variable across layers — diagnostic for whether the `(m/n)^0.5` factor is sufficient.

3. **`train/ns5_spectral_entropy`**: spectral entropy of the NS5 output matrix (computed as `-sum(s_i * log(s_i))` where s_i are normalized singular values of the update matrix), averaged over a sample of MuonH body params. Low entropy = update is effectively low-rank; high entropy = update is full-rank / spread across all singular value directions. Baseline polar factor has theoretically maximum entropy (all singular values equal ≈ 1/sqrt(min(m,n))). Log at `histogram_interval` to avoid overhead.

Implementation: these should be computed at Python scope on the `update` tensor immediately after the `muon_update_fn(...)` call, guarded by `if step % args.telemetry_interval == 0` to avoid every-step overhead.

---

### WIN Probability Assessment

Campaign base rate: ~10% (1 clear win per ~10 mechanism-class hypotheses tested).

For this ablation:
- **If sign_only = CTRL (Arm B ties Arm A)**: ~20% chance a cleaner pure-direction implementation yields +FFS. Evidence: Bernstein & Newhouse (2024) show sign-like updates often match or exceed polar-factor updates on transformers.
- **If magnitude_only = CTRL (Arm C ties Arm A)**: ~35% chance that a properly-tuned simpler normalizer (e.g., AdaFactor-style) replaces NS5 with FFS win. This would be a major finding pointing to a computationally cheaper architecture.
- **If polar dominates both (CTRL wins)**: the joint effect is confirmed as necessary — constrains the search space significantly. WIN = 0% for this hypothesis, but the research state update is high-value (rules out sign-only and magnitude-only lines).
- **If sign_only wins**: follow-up with column-norm vs row-norm vs spectral-norm normalization family yields another 2–3 hypotheses with elevated WIN probability.

Overall WIN probability on FFS: **~15–25%** above campaign base rate. The asymmetric information value (useful even on loss) makes this a high-priority diagnostic.

---

### Drift-Class Risk Assessment

**Risk: torch.compile soft-drift.**
- Mitigated by: separate module-level compiled functions per mode, bound at Python scope. No conditional inside compiled region.
- Residual risk: `F.normalize` (if imported differently) or shape-dependent branches in `normalize` implementation. Mitigate by checking torch.compile trace count in the early steps; should be exactly 1 trace per compiled function, not N>1.
- Severity if triggered: +25 FFS penalty (confirmed from H238/H242/H246 triangulation).

**Risk: Arm C (magnitude_only) gradient scale collapse.**
- `magnitude_only` removes all NS5 iterations. If raw gradient is near rank-1 (very low entropy) — common in early training — the unit-Frobenius normalization produces a very different effective preconditioner than polar. Could cause early-step instability.
- Mitigate: monitor `train/grad/global_norm` and `val/loss` at step 50; if training loss is >20% higher than CTRL at step 100, kill as crash.

**Risk: sign_only column-normalization on non-square matrices.**
- For tall matrices (more rows than columns), NS5 transposes internally. The `normalize(update, dim=-2)` call must normalize after the transpose is undone (i.e., on the final returned matrix in its original shape). The implementation above normalizes `dim=-2` which is correct for the tall form inside the NS5 internal loop BUT the transpose is undone before return. Verify the normalization dimension is consistent with the output shape.
- Safer implementation: normalize after NS5 returns, outside `zeropower_via_newtonschulz5`, on the output in its original orientation (shape = G.shape). Use `dim=-2` for tall (m>n) or `dim=-1` for wide — or just normalize across all elements via `F.normalize(update.reshape(m*n), dim=0).reshape(m, n)` which is shape-independent. The latter is equivalent to unit-Frobenius normalization and is simpler to reason about.

---

### Decision Criteria Matrix

| Result | Conclusion | Next Step |
|--------|------------|-----------|
| sign_only FFS < CTRL by >25 steps | Directional signal load-bearing, magnitude is noise | Follow-up: pure row-norm vs col-norm vs spectral-norm normalization; Gram-Schmidt vs QR vs NS5 direction |
| magnitude_only FFS < CTRL by >25 steps | Magnitude equalization load-bearing, direction is noise | Follow-up: AdaFactor-style update (skip NS5, cheaper); per-layer RMS normalization sweep |
| sign_only ≈ CTRL (within 25 steps), magnitude_only >> CTRL | Both direction AND equalization needed, but sign normalization variant worth tuning | Follow-up: sign_only + LR re-tune (this arm ran with CTRL LR; sign_only may have different optimal LR) |
| All arms ≈ CTRL (within noise band ~50 steps) | Joint polar effect robust; neither ablation is an improvement | CLOSE: both sign_only and magnitude_only confirmed NULL; polar projection confirmed jointly necessary |
| magnitude_only catastrophic (FFS=-1) | NS5 orthogonalization is critical for stability, not just performance | CLOSE magnitude_only line; investigate whether spectral norm alone (without orthogonalization) is viable |

Decision threshold: "significantly better" = FFS improvement > 1.5x stdev of CTRL noise band (sigma ≈ 90 steps based on H203 baseline; threshold ≈ 135 step improvement for significance).

---

### Exact Reproduce Commands

**Arm A (CTRL, bit-identity gate first):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-tanjiro/h251-ns5-decomp-ctrl" \
  --wandb_group "h251-ns5-output-decomp" \
  --train_steps 3350 \
  --ns5_output_mode polar
```

**Arm B (sign_only):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-tanjiro/h251-ns5-decomp-sign-only" \
  --wandb_group "h251-ns5-output-decomp" \
  --train_steps 3350 \
  --ns5_output_mode sign_only
```

**Arm C (magnitude_only):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r3-tanjiro/h251-ns5-decomp-magnitude-only" \
  --wandb_group "h251-ns5-output-decomp" \
  --train_steps 3350 \
  --ns5_output_mode magnitude_only
```

Run CTRL first. Verify step-0 val = 10.82583. Then run B and C.

---

### Research State Update

**Current best explanation for what limits FFS**: The NS5 + MuonH stack is near the local optimum for all currently-parameterized degrees of freedom (Programme Findings #51/#55). The next lever is the geometric structure of the NS5 output signal itself — specifically, whether the polar-factor decomposition is the right representation of the gradient update direction.

**Evidence supporting this target**: H243 (tanjiro, fractional NS / Schatten-p) closed the iteration-count/polynomial-order space → the computation quality of NS5 is saturated. H249 (alphonse, Riemannian metric) attempts to reframe the geometry at the projection level. H251 attacks the OUTPUT side: after NS5 converges, is the full polar factor necessary?

**Ruled-out paths (do not repeat)**:
- NS5 polynomial coefficients (a/b/c) — Finding #51
- NS5 iteration count — H243 CLOSED
- NS5 Schatten-p exponent — H243 CLOSED
- AdaMuon / outer-optimizer form — Finding #55
- β1 cross-optimizer transfer — Finding #49
- All aux AdamW FORM replacements

**Open uncertainties**:
1. Whether NS5's value is primarily geometric (orthogonalization as preconditioner) or algebraic (magnitude equalization as per-layer normalization).
2. Whether a cheaper alternative to NS5 (e.g., just normalize gradient to unit Frobenius) achieves equivalent FFS at lower per-step compute cost.
3. Whether the `(m/n)^0.5` scale factor alone is the source of cross-layer training stability.

**Next discriminating experiment**: H251 itself — the sign_only vs magnitude_only decomposition is the cheapest ablation that separates the two hypotheses above.

**Stop condition**: If all three arms land within 1 sigma of each other (all within ~90 steps of CTRL FFS=3025), the decomposition is non-informative and we should move to a structurally different mechanism class (e.g., Riemannian geometry of the Stiefel manifold, spectral regularization on weight matrices, or GradNorm-style loss reweighting at the optimizer level).

---

*Proposal author: researcher-agent, cycle 1310, 2026-05-28*
*Mechanism class: #47 (NS5 output-signal geometry decomposition)*
*Assigned to: g1r3-tanjiro*
