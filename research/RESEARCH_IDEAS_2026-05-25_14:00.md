# Research Ideas — 2026-05-25 14:00

## Context

Target: modded-nanogpt track 3, `auto-nanogpt-1gpu-r2` advisor branch.
Merge bar: val_mean ≤ 3.26776 AND ffs_mean ≤ 3000 (n=2 mean).
Corpus size: 309 PRs reviewed for categorical novelty.
Student: g1r2-fern.
Constraint: 1 forward-backward pass per optimizer step. No architecture/data/batch changes.
Loss-side saturated — pivot to optimizer-body or initialization axis.

---

## Idea 1: MUON_POLAR_EXPRESS

### What it is

Replace NS5's fixed polynomial coefficients with minimax-optimal per-iteration coefficients precomputed OFFLINE via the Remez algorithm (Polar Express, Amsel et al. 2025).

### Mechanism

NS5 applies the degree-5 polynomial `X ← a*X + b*(X@X.T)@X + c*(X@X.T)@(X@X.T)@X` with static scalar coefficients (a=3.4445, b=-4.7750, c=2.0315 for all 14 iterations). These fixed coefficients are chosen for uniform convergence across the full eigenvalue domain [0, σ_max], which is suboptimal for matrices whose singular value distribution concentrates in a narrower band.

Polar Express (Amsel, Persson, Musco, Gower; ICLR 2026 Oral, arxiv:2505.16932) replaces these static coefficients with a lookup table of per-iteration triplets (a_t, b_t, c_t) that are the minimax-optimal Chebyshev polynomial coefficients for the specific iteration index t, computed offline by the Remez algorithm. The runtime cost is identical — the same matrix multiply structure `X ← aX + B@X where B = b*A + c*A@A, A = X@X.T` with floats substituted from the precomputed table. No additional compute at training time.

The convergence improvement is proven cubic vs NS5's quadratic (Theorem 4.3 in the paper). On FineWeb GPT-2, Muon-PolarExpress achieves val_loss=3.340 vs Muon with standard Jordan iteration 3.398, a substantial gap.

### Categorical-escape argument

All existing NS5 variation PRs in the 309-PR corpus sweep **static** coefficient values across all iterations (PRs #694, #295, #1011, #1025, #1057). PR #1019 bypasses NS entirely with exact SVD. PR #1025 adds more polynomial terms (NS7). None precomputes per-iteration-index minimax-optimal coefficients from Remez. This is a categorically different algorithm: adaptive coefficients that are index-dependent, not a scalar or polynomial-order tweak of a uniform formula.

### Citation

Amsel, Persson, Musco, Gower. "Polar Express: Optimal Polar Decomposition with Applications to Stiefel Optimization." arXiv:2505.16932, ICLR 2026 (Oral, top-1%).

### Proposed arms

- Arm A: `POLAR_EXPRESS_STEPS=14` — direct drop-in replacement for NS5_ITERS=14, same iteration count, optimal coefficients.
- Arm B: `POLAR_EXPRESS_STEPS=7` — cubic convergence may reach equivalent accuracy in half the iterations, freeing compute or demonstrating step efficiency.
- Baseline disabled-check: coefficient table replaced with NS5 static values (bytewise-inert at POLAR_EXPRESS=0).

### Predicted outcome

Arm A is the key test: if cubic convergence materially improves the polar factor quality per optimizer step, we expect val_loss ≤ 3.267 (at or below merge bar). Arm B tests whether fewer high-quality iterations equals 14 lower-quality ones — a potential ffs win. Risk: if the current NS5 at 14 iterations already converges adequately for the gradient magnitudes in this stack, additional per-iteration accuracy gains diminish. The paper's FineWeb result (3.340 vs 3.398 = −0.058 improvement from polar quality alone) suggests meaningful headroom exists.

---

## Idea 2: MUON_BODY_PSR

### What it is

Principal Spectral Regularization — add a loss-side penalty on the dominant singular values of the body weight matrices to encourage more isotropic weight spectra during training.

### Mechanism

Transformer body weight matrices (Q, K, V, MLP up/down) develop highly anisotropic singular value distributions during training, where a few dominant singular values carry disproportionate signal. PSR adds `λ * Σ_i σ_i(W)^2` for the top-k singular values to the training loss, computed using the power iteration estimate already available from the Muon optimizer's NS5 steps. This regularizes toward a more isotropic spectrum without clamping (which is destructive, per PR #1073's mechanism).

Mechanistic distinction from the existing stack:
- PR #1073 caps σ_max on the UPDATE direction (gradient-space constraint, not weight-space).
- PSR penalizes the dominant singular values of the WEIGHT MATRICES in the loss — a loss-side regularizer on the learned weight geometry.
- LOGIT_SOFTCAP=20 already prevents logit explosion; PSR targets intermediate weight spectra before the logit layer.

### Categorical-escape argument

No PR in the 309-PR corpus applies a spectral penalty to the body weight matrices in the training loss. PR #1073 is the closest but operates on the update tensor, not the weight tensor. The logit-magnitude-penalty family (closed at #1117 Z_LOSS) is on scalar logit magnitude, not weight matrix singular values. This is a categorically new axis: loss-side regularization on intermediate layer weight spectra.

Efficient computation: approximate σ_max(W) via one power iteration (x ← Wx / ‖Wx‖, σ ≈ ‖Wx‖) requires one extra matvec per layer per step — O(d²) same as the forward pass. For 12-layer GPT-2: 12 blocks × 4 matrices × 1 matvec = 48 matvecs at d=768, equivalent to ~6% overhead. Alternatively, reuse the polar factor U already computed by NS5 (σ_max(W) ≈ ‖W - U‖_F + 1 bounds it from above).

### Citation

Partial motivation: "Enhancing LLM Training via Spectral Clipping and Momentum" (arxiv:2603.14315, 2025) — shows spectral control of weight matrices during LLM training improves convergence and generalization. PSR is a softer regularization variant (penalty vs clipping) avoiding the discontinuous gradient of hard clipping.

### Proposed arms

- Arm A: `PSR_LAMBDA=1e-4` — gentle probe, penalty contributes ~1% of CE loss magnitude.
- Arm B: `PSR_LAMBDA=1e-3` — stronger probe; monotone-in-λ diagnostic.
- Scope: body weight matrices only (Q, K, V, MLP up/down), not embedding or lm_head.
- Disabled-check: PSR_LAMBDA=0 recovers exact baseline (bytewise-inert).

### Predicted outcome

If dominant singular values are limiting generalization by over-concentrating gradient signal, PSR should compress ffs (fewer steps to good loss) or lower terminal val_loss. Risk: the loss-side additive term may interfere with LOGIT_SOFTCAP=20's logit geometry management (analogous to logit-space-additive failures in Z_LOSS #1117 and LOGIT_ADJUSTMENT #1147). Monitor for WRONG-DIRECTION-MONOTONE signature (stronger λ → worse val_loss) which would confirm the logit-geometry interference failure mode. The penalty magnitude bound λ * k * σ_max² must stay < 5% CE at convergence to avoid dominating gradient direction.

---

## Recommendation

**Primary: MUON_POLAR_EXPRESS.** External evidence from the same optimization domain (Muon + FineWeb) is direct, the mechanism is well-understood, runtime cost is neutral, and it is a clean single-change test. The Polar Express paper's FineWeb result (−0.058 val_loss vs Jordan iteration) is a strong external signal.

**Secondary: MUON_BODY_PSR.** Novel loss-side axis with clear categorical distinction from all 27 closed families. Higher risk due to known failure modes of loss-additive terms in this stack — but if Polar Express is assigned to fern, PSR is a natural complementary assignment for a second student.
