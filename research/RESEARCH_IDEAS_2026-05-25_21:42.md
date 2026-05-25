# Research Hypothesis: PSGD_KRON_AUX

**Date:** 2026-05-25 21:42
**Target student:** g1r2-thorfinn
**Track:** modded-nanogpt track 3 optimizer benchmark

---

## Name

`PSGD_KRON_AUX`

## Reference

Li & Mahoney, "Preconditioned Stochastic Gradient Descent" (2015, updated 2023). arXiv:1512.04202. The Kronecker-factored variant is described in sections 4–5 and the practical update rules for 2D weight matrices are given explicitly with damped Newton step updates on triangular preconditioner factors.

## Mechanism

AUX AdamW currently applies isotropic second-moment scaling independently per scalar parameter. For the embed matrix (vocab_size × d_model, shape ~50257×768) and lm_head (d_model × vocab_size, shape 768×50257), the gradient curvature is highly structured: the row and column subspaces have very different conditioning. PSGD Kronecker-factored whitening addresses this directly: instead of one diagonal second-moment vector, it maintains two triangular factor matrices L (left, shape m×m) and R (right, shape n×n) per 2D parameter, and applies the preconditioned update G' = L⁻¹ G R⁻ᵀ. The factors are updated via damped Newton steps on the Lie-group whitening objective: ΔL ∝ (G G^T L - L⁻ᵀ) / (||G G^T|| + λ), similarly for R. This whit-ens both row and column curvature simultaneously at O(m² + n²) cost rather than O(mn), amortized over preconditioner update frequency. For embed/lm_head, the dominant cost is the 50257-side factor — which is large — so in practice only the smaller d_model=768 side is tracked as a full triangular matrix and the large-vocab side uses a diagonal approximation (half-Kron), keeping cost manageable. The hypothesis is that the embed and lm_head gradient manifolds have structured low-rank curvature that AdamW's diagonal approximation systematically underexploits, and Kronecker whitening captures this at affordable cost by amortizing the Newton updates every K steps.

## Anti-duplication grep evidence

Searched 318-PR corpus (PRs #1–#1212) for:
- "PSGD" — 0 matches
- "KRON" — 0 matches  
- "kron" — 0 matches
- "whitening" (as standalone preconditioner mechanism) — 0 matches
- "kronecker" — 0 matches

Mechanically distinct from all currently in-flight axes:
- CAUTIOUS_MUON (#1190): sign-agreement mask on Muon momentum, not AUX
- MUON_PER_HEAD_NS5 (#1196): per-head NS5 decomposition, not AUX
- CAUTIOUS_AUX (#1205): sign-agreement mask on AdamW, not Kronecker whitening
- RIEMANNIAN_MUON_TRANSPORT (#1207): Stiefel transport on Muon momentum, not AUX
- RAND_SVD_MUON (#1212): pre-NS5 low-rank denoising on Muon body, not AUX

Distinct from all closed AUX-side families:
- ADOPT (#1194): second-moment update ordering, not factored whitening
- LION AUX (#772, #1012): pure sign update, not factored whitening
- ADAM_MINI (#1140): grouped diagonal second-moment, not Kronecker
- AMSGRAD (#1108): running max second-moment, not factored whitening
- SOPHIA (#797): Hessian diagonal estimate, not Kronecker factored
- SCHEDULE_FREE (#792): primal averaging, not factored whitening
- MARS (#576, #788): variance reduction, not factored whitening
- CAUTIOUS AdamW (#523): sign-agreement mask, not factored whitening

## Arm parameters

**Arm A** (conservative update frequency, light damping):
```
PSGD_KRON_AUX=1
KRON_PRECOND_FREQ=10
KRON_DAMPING=1e-4
```

**Arm B** (aggressive update frequency, heavier damping):
```
PSGD_KRON_AUX=1
KRON_PRECOND_FREQ=5
KRON_DAMPING=1e-3
```

Both arms use half-Kron (full triangular factor on the d_model=768 side, diagonal approximation on the vocab=50257 side) to keep memory and compute costs bounded.

## Kill gate

val/loss > 3.285 at step 2000 (both arms). If either arm breaches, close that arm. If both breach, close the PR.

## Implementation notes

- Gate with `if os.environ.get('PSGD_KRON_AUX', '0') == '0': return` at top of new class; disabled-check bytewise-inert
- Maintain per-param state: `L` (d_model × d_model triangular), `r_diag` (vocab-size diagonal vector)
- Newton step update at each preconditioner refresh step: `L_new = L - lr_kron * (G @ G.T @ L - torch.linalg.solve_triangular(L.T, eye)) / (torch.norm(G @ G.T) + damping)`
- Use `torch.linalg.solve_triangular` for O(m²) back-substitution, not full inverse
- Apply preconditioned gradient: `G_precond = torch.linalg.solve_triangular(L, G) / r_diag.unsqueeze(0)`
- Then feed `G_precond` into standard AdamW momentum/second-moment update (keep AdamW schedule, β1, β2, wd unchanged — only the gradient input is whitened)
- Approximately 50–70 LOC in a new `PSGDKronAUX` optimizer class replacing `torch.optim.AdamW` for the embed/lm_head param groups
- `KRON_PRECOND_FREQ` controls how often L and r_diag are refreshed (every K optimizer steps); between refreshes, use cached L, r_diag

## Expected LOC

~55 LOC in `train_gpt_simple.py` (new optimizer class + param group routing under env var gate).

---

*Proposal generated: 2026-05-25 21:42*
