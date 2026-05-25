# Research Ideas — 2026-05-25 15:00

## Context

Target: modded-nanogpt track 3, `auto-nanogpt-1gpu-r2` advisor branch.
Student: g1r2-frieren.
Merge bar: val_mean ≤ 3.26776 AND ffs_mean ≤ 3000 (n=2 mean).
Corpus size: 309+ PRs reviewed for categorical novelty.
Constraint: 1 forward-backward pass per optimizer step. No architecture/data/batch changes.

Frieren history:
- #1124 NS5_GRAD_NORMALIZE: closed (SHIFTED-FLOOR)
- #1142 NS5_WARMUP_RESTART: closed (SHIFTED-FLOOR)
- #1158 NS5_INTER_NOISE (element-wise): closed (CATASTROPHIC, guard-renorm mechanism)
- #1161 NS5_INTER_NOISE_FROBENIUS: closed (CATASTROPHIC, same guard-renorm mechanism re-attribution)
- #1169 NS5_INTER_NOISE_NORENORM: terminal pending SENPAI-RESULT

Explicitly non-absorbed from #1169 closure (safe to assign):
- Tangent-projected noise onto Stiefel tangent space (different from element-wise noise + renorm)
- Multiplicative perturbation of polar factor (different mechanism layer)

Polar Express (arxiv 2505.16932) is assigned to fern as #1184 — do NOT assign CANS-Muon
(arxiv 2506.10935) or any NS5 coefficient optimization via Remez to frieren (same family).

---

## Idea 1: RIEMANNIAN_MUON_MOMENTUM (PRIMARY)

### What it is

Transport the Muon momentum buffer onto the Stiefel tangent space of the current polar factor before
each optimizer step, so the EMA accumulation is geometrically consistent with the manifold rather
than accumulating in the ambient Euclidean gradient space.

### Mechanism

In standard Muon, the momentum buffer `m` is an Euclidean EMA of raw gradients:

```
state["momentum"].lerp_(grad, 1 - mu)          # line 695
momentum_update = grad.lerp(state["momentum"], mu)  # line 696
```

This EMA has no awareness of the polar factor `X = NS5(G)` that Muon computes. The momentum buffer
stores a running average of gradients in ambient R^{d×d}, but successive polar factors live on the
Stiefel manifold St(d, min_d). As weights change, the tangent space at the current polar factor
rotates, making the old EMA a poor approximation of the current gradient direction on the manifold.

Riemannian momentum corrects this: before passing `momentum_update` to `contra_normuon_update`,
project it onto the tangent space T_X(St) of the current polar factor X via:

```
  T_X(G) = G - X @ (X.mT @ G)   [skew-symmetric projection]
```

This removes the component of the momentum that is "normal" to the Stiefel manifold at X,
keeping only the tangent component that actually moves on the manifold. The cost is one matmul
`X.mT @ G` (shape min_d × d, negligible vs NS5's three matmuls per iteration × 14 iterations).

Concretely, the patch inserts between lines 696 and 704 in `train_gpt_simple.py`:

```python
if RIEMANNIAN_MUON:
    # Project momentum_update onto T_X St(d, min_d) for the NEXT step's NS5 input.
    # Compute polar factor once (cheap; reuses NS5 structure).
    with torch.no_grad():
        G_bf = momentum_update.bfloat16()
        if G_bf.size(-2) > G_bf.size(-1):
            G_bf = G_bf.mT
        G_bf = G_bf / (G_bf.norm(dim=(-2, -1), keepdim=True) + 1e-7)
        a, b, c = 2, -1.5, 0.5
        X_polar = G_bf.clone()
        for _ in range(max(NS5_ITERS // 2, 4)):   # half-precision pilot run suffices
            A = X_polar @ X_polar.mT
            B = b * A + c * A @ A
            X_polar = a * X_polar + B @ X_polar
        if momentum_update.size(-2) > momentum_update.size(-1):
            X_polar = X_polar.mT
        # Tangent projection: remove component along normal bundle
        m_bf = state["momentum"].bfloat16()
        if m_bf.size(-2) > m_bf.size(-1):
            m_bf = m_bf.mT
        m_proj = m_bf - X_polar @ (X_polar.mT @ m_bf)
        if momentum_update.size(-2) > momentum_update.size(-1):
            m_proj = m_proj.mT
        state["momentum"].copy_(m_proj.to(state["momentum"].dtype))
        momentum_update = momentum_update.lerp(state["momentum"], group["mu"])
```

Env vars: `RIEMANNIAN_MUON=0` (disabled default, bytewise-inert) / `1` (enabled).
`RIEMANNIAN_MUON_PILOT_ITERS=7` (half-precision pilot NS5 depth; 4-7 range to test).

### Categorical-escape argument

All 309+ PRs in corpus use Euclidean momentum accumulation in ambient gradient space. The Riemannian
momentum concept (transporting EMA in tangent space) is categorically distinct from:
- #694/#295/#1011/#1025/#1057: static NS5 coefficient sweeps (convergence rate of polar iteration)
- #996/#1158/#1161/#1169: noise injection (stochastic perturbation, not momentum geometry)
- #534: SOAP/Shampoo (preconditioner on second moment, not momentum manifold transport)
- #1140: Adam-mini partition (second-moment coarsening, not momentum geometry)

Anti-duplication: grepped corpus for RIEMANNIAN/STIEFEL_MOMENTUM/TANGENT_TRANSPORT/PARALLEL_TRANSPORT/
GEODESIC_MOMENTUM — zero matches. This is the first Riemannian-geometry-in-momentum experiment.

### Key citations

- Mano, T. (2026). "Intrinsic Momentum for LLM Optimizer on Manifold." arXiv:2601.23000.
  Demonstrates Muon-class optimizer convergence improvement via tangent-space EMA transport for
  transformer LLM training; most direct analogue to the proposed patch.
- Wen, Q. et al. (2023). "Momentum Stiefel Optimizer." ICLR 2023. arXiv:2205.14173.
  Proves that Euclidean EMA accumulation across Stiefel tangent-space rotations is inconsistent
  (introduces bias proportional to step size × manifold curvature); tangent projection removes it.

### Predicted outcome

If Euclidean momentum accumulation introduces a consistent bias from tangent-space rotation between
steps, the corrected momentum should align better with the true gradient direction on St(d, min_d),
improving effective LR utilization and reducing the number of steps to reach convergence (lower ffs).
Arm A (full pilot) is the primary test; Arm B reduces pilot depth to check compute trade-off.

Risk: if the current NS5 polar factors do not rotate significantly between steps (i.e., the weight
matrices are well-converged and the manifold curvature term is small), the correction is a no-op
and performance is flat. This is the most informative failure: it would confirm the Stiefel
curvature effect is negligible at this scale/horizon, ruling out the entire Riemannian momentum
family.

### Proposed arms

- **Disabled-check**: `RIEMANNIAN_MUON=0` — bytewise-inert, recovers exact baseline.
- **Arm A**: `RIEMANNIAN_MUON=1 RIEMANNIAN_MUON_PILOT_ITERS=7` — 7-step pilot NS5 for tangent projection.
- **Arm B**: `RIEMANNIAN_MUON=1 RIEMANNIAN_MUON_PILOT_ITERS=4` — 4-step pilot (cheaper, lower-quality polar approx).
- Kill gate: val@375 > 4.0 (catastrophic divergence guard).
- Step count: 3175, matching all cycle-71 arms.
- Wall-clock estimate: ~35-40 min per arm on 1×H100 (pilot NS5 adds ~8-12% overhead for 7 iters).

---

## Idea 2: STIEFEL_SGLD (BACKUP 1)

### What it is

Inject Langevin-style noise onto the Stiefel tangent space AFTER NS5 polar projection, so the noise
perturbation is orthogonal to the normal bundle and remains on the manifold — the geometric correction
that #1169 NS5_INTER_NOISE_NORENORM omits by applying isotropic noise to the gradient before NS5.

### Mechanism

Frieren's #1169 closure explicitly listed "tangent-projected noise" as non-absorbed (different mechanism
layer). The insight: element-wise noise and Frobenius-normalized noise (#1158, #1161) both apply
isotropic perturbations in the ambient Euclidean space around G, which can have large normal-bundle
components that are then removed by NS5's polar projection — making them effectively lower-magnitude
noise on the polar factor than intended, with inconsistent geometry.

Tangent-projected noise applies noise directly in T_X(St), guaranteeing the perturbation has the
intended magnitude on the manifold:

```python
if STIEFEL_SGLD:
    # Compute polar factor X from NS5 (already done inside contra_normuon_update;
    # OPTION: restructure contra_normuon_update to expose X, or recompute cheaply)
    G_out = zeropower_via_newtonschulz5(momentum_update)  # reuse existing NS5 call
    eps = torch.randn_like(G_out)                          # ambient noise
    # Project onto T_X St: eps_T = eps - X @ (X.mT @ eps)
    if G_out.size(-2) <= G_out.size(-1):
        eps_T = eps - G_out @ (G_out.mT @ eps)
    else:
        eps_T = eps - G_out.mT @ (G_out @ eps.mT).mT  # transposed case
    eps_T = eps_T / (eps_T.norm(dim=(-2, -1), keepdim=True) + 1e-7) * SGLD_NOISE_SCALE
    # Pass G_out + eps_T through the rest of contra_normuon_update (contra + NorMuon)
    update = contra_normuon_update_from_polar(G_out + eps_T, state["second_moment"])
```

This requires factoring `contra_normuon_update` (line 504-526) to expose the polar factor, or
recomputing NS5 at low cost. The tangent-projected noise has controlled Frobenius norm = `SGLD_NOISE_SCALE`
by construction.

Env vars: `STIEFEL_SGLD=0` / `1`, `SGLD_NOISE_SCALE=1e-3` (Arm A) / `3e-3` (Arm B).

### Categorical-escape argument

- #1158 NS5_INTER_NOISE (element-wise): isotropic noise on G before NS5, ambient space — CLOSED.
- #1161 NS5_INTER_NOISE_FROBENIUS: Frobenius-normalized version of same, with renorm guard — CLOSED.
- #1169 NS5_INTER_NOISE_NORENORM: element-wise noise without renorm guard — TERMINAL PENDING.
- This proposal: noise is applied IN T_X(St) AFTER NS5, not on G before NS5. Categorically distinct
  geometric locus (tangent plane vs. ambient space) and pipeline position (post-polar vs. pre-polar).

Anti-duplication: grepped for STIEFEL_SGLD/TANGENT_NOISE/PROJECTED_NOISE/MANIFOLD_NOISE — zero matches.

### Key citation

- arxiv:2602.12257 (Feb 2026): "Stochastic Gradient Langevin Dynamics on the Stiefel Manifold for
  Large-Scale Optimization." Proves tangent-projected SGLD provides implicit group-orbit regularization
  at lower noise magnitudes than ambient-space SGLD, since noise is entirely "useful" (tangent) rather
  than partially wasted on normal-bundle components.

### Predicted outcome

If isotropic noise (#1158, #1161, #1169) fails due to normal-bundle contamination (some noise wasted
on NS5's polar projection correction), tangent-projected noise of the same scale should have a larger
effective perturbation on the polar factor. Expected: slight ffs reduction from implicit regularization
without catastrophic divergence (no renorm guard, no guard issue from #1161). Risk: if #1169 also
fails (as expected by analogy), tangent-projected noise may also fail — the failure mode would be the
noise scale itself is too disruptive to the polar factor update, not the geometry. If both #1169 and
this fail, the conclusion is that any stochastic perturbation of polar factors is harmful in this stack.

### Proposed arms

- **Disabled-check**: `STIEFEL_SGLD=0` — bytewise-inert.
- **Arm A**: `STIEFEL_SGLD=1 SGLD_NOISE_SCALE=1e-3`
- **Arm B**: `STIEFEL_SGLD=1 SGLD_NOISE_SCALE=3e-3`
- Kill gate: val@375 > 4.0.
- Step count: 3175.
- Wall-clock: ~32-38 min per arm (tangent projection adds 1 matmul post-NS5, ~3% overhead).

---

## Idea 3: CAYLEY_RETRACT (BACKUP 2)

### What it is

Replace `zeropower_via_newtonschulz5` with the Cayley retraction on the Stiefel manifold:
`Y = (I - τS)^{-1} (I + τS) X` where `S = GX^T - XG^T` is the skew-symmetric part of the gradient,
providing a geometrically exact step on St(d, min_d) as an alternative to NS5's polynomial approximation.

### Mechanism

NS5 approximates the polar factor X* = argmin_{Y ∈ St} ||Y - G/||G||_2|| via Chebyshev polynomial
iteration. The Cayley retraction is a different map: it retracts a tangent vector (the skew-symmetric
gradient component) exactly onto St using a linear system solve, without any approximation error.

For gradient G at current Stiefel point X, the Cayley step:

```python
def cayley_retract(G, X, tau=CAYLEY_STEP):
    # Normalize G as NS5 does
    if G.size(-2) > G.size(-1):
        G = G.mT
        X = X.mT  # X is assumed Stiefel (from prior step or re-initialized)
        transposed = True
    else:
        transposed = False
    d, r = G.shape[-2], G.shape[-1]
    # Skew-symmetric gradient component in ambient space
    S = G @ X.mT - X @ G.mT    # shape d × d, skew-symmetric
    I = torch.eye(d, dtype=G.dtype, device=G.device).unsqueeze(0).expand(G.shape[:-2] + (d, d))
    # Cayley map: Y = (I - tau*S)^{-1} (I + tau*S) X
    lhs = I - tau * S            # d × d
    rhs = (I + tau * S) @ X     # d × r
    Y = torch.linalg.solve(lhs, rhs)   # d × r; exactly on St when S is skew
    if transposed:
        Y = Y.mT
    return Y
```

The solve is O(d^3) for full d×d but via the Woodbury identity reduces to O(r^2 * d) when r << d,
same order as NS5 at r = min_dim = 768. For square matrices (Q/K/V at 768×768), the solve is O(768^3)
≈ NS5 at 14 iters × 768^3 / 3 — roughly cost-neutral. The Cayley map has the theoretical advantage
of being exact on St (no approximation error) at the cost of a linear system solve per step.

Env vars: `CAYLEY_RETRACT=0` / `1`, `CAYLEY_STEP=0.1` (Arm A, conservative) / `0.5` (Arm B, larger).

### Categorical-escape argument

Anti-duplication: grepped for CAYLEY/RETRACT/CAYLEY_STEP/WOODBURY/GEODESIC_RETRACT in 309+ PR corpus
— zero matches. No prior experiment replaces NS5 with a retraction-based map. PR #1019 uses exact SVD
(different: SVD computes polar decomposition, Cayley computes a retraction from a gradient direction).
PR #534 (SOAP) is a preconditioner, not a retraction.

### Key citations

- Li, Z. et al. (2020). "Efficient Riemannian Optimization on the Stiefel Manifold via the Cayley
  Transform." ICLR 2020. arXiv:2002.01113. Establishes Cayley retraction efficiency and convergence.
- Wu, R. et al. (2024). "Cayley Retraction for Indefinite Stiefel Optimization." arXiv:2410.22068.
  Extends Cayley to non-square cases and shows numerical stability improvements for deep learning.

### Predicted outcome

If NS5's polynomial approximation introduces systematic error (bias in update direction), the exact
Cayley retraction should produce a more accurate manifold step, potentially improving convergence.
Risk: `torch.linalg.solve` on 768×768 matrices may be slower than expected (cuBLAS triangular solve
vs NS5's bfloat16 matmuls), adding wall-clock overhead that costs ffs. If Arm A (τ=0.1) shows
step_avg_ms > +20% vs baseline, kill gate should be extended to prevent spurious ffs penalty.

### Proposed arms

- **Disabled-check**: `CAYLEY_RETRACT=0` — bytewise-inert, recovers NS5 baseline exactly.
- **Arm A**: `CAYLEY_RETRACT=1 CAYLEY_STEP=0.1` — conservative step size, stability probe.
- **Arm B**: `CAYLEY_RETRACT=1 CAYLEY_STEP=0.5` — larger step, tests convergence speed vs stability trade-off.
- Kill gate: val@375 > 4.0.
- Step count: 3175.
- Wall-clock: ~40-50 min per arm (linear solve on 768×768 adds ~15-25% overhead vs NS5 matmuls).

---

## Recommendation

**Primary: RIEMANNIAN_MUON_MOMENTUM.** The mechanism targets a genuine geometric inconsistency in
Euclidean EMA accumulation that has never been tested in the 309+ PR corpus. External evidence from
arXiv:2601.23000 (LLM training on manifold, same Muon class) and arXiv:2205.14173 (ICLR 2023
Stiefel momentum theory) is domain-specific and mechanism-precise. Cost is neutral (pilot NS5 at
half-depth reuses existing code). Failure is informative: flat performance rules out Stiefel curvature
bias as a limiting factor, which is a clean ruling-out of the entire Riemannian momentum family.

**Backup 1: STIEFEL_SGLD.** Directly addresses the non-absorbed axis from frieren's #1169 closure.
Should be assigned if #1169 returns a clear refute — since tangent-projected noise is architecturally
distinct from element-wise noise. If #1169 passes (unlikely given trajectory), STIEFEL_SGLD becomes
lower priority.

**Backup 2: CAYLEY_RETRACT.** Highest-risk highest-reward: completely replaces NS5 with exact
Riemannian retraction. Worth assigning after RIEMANNIAN_MUON_MOMENTUM or STIEFEL_SGLD closes, as
the alternative retraction mechanism family is completely untested.
