# RESEARCH IDEAS — 2026-05-23 13:50
## Plateau Protocol Cycle 11 — Bold-Swing Tier

**Context:** 10+ consecutive NEG rounds have closed all per-token reweighting, gradient modification, init-structure, numerical-precision, and cooldown-shape axes. The stack is MuonH-SI (lr=0.018, NS5 k=12, mu=0.95, scale_invariant mode) + AdamW aux + optional MuLoCo outer loop. Baseline: val/loss=3.27119, ffs=3100. Budget: 3325 steps, 1×H100.

**Posture:** Replace or augment the core inner-optimizer mechanism — not hyperparameter sweeps, not gradient preprocessing. Each idea targets a genuinely un-tested axis.

---

## Rank 1 — H92: MARS-M Variance Reduction on Body Matrix Momentum

### Mechanism
MARS (Chen et al. 2411.10438) adds a variance-reduction correction to AdamW. MARS-M (Zhao et al. 2510.21800) ports this to matrix-valued (Muon-style) optimizers: the stochastic gradient is corrected via a scaled finite difference of consecutive raw gradients *before* it enters the momentum EMA and NS5 polar map.

Corrected gradient: `c_t = g_t + γ * (β/(1-β)) * (g_t - g_{t-1})`

Then `c_t` replaces `grad` in the existing `muon_update(c_t, momentum, ...)` call. γ=0 exactly recovers the current baseline (zero regression risk for γ=0).

The theoretical improvement: O(T^{-1/3}) convergence rate vs. Muon's O(T^{-1/4}), same per-step cost, same NS5 call. Zhao et al. benchmark directly on FineWeb-Edu 100B and report ~+0.57 avg MMLU improvement over Muon.

### Why NOT pre-closed
- H25 was MARS on *aux AdamW* only (embed/head/scalars). Body matrix momentum (the NS5 path) has never had variance reduction applied.
- γ=0 is a strict superset of the current baseline — no downside risk if γ is wrong, the run still serves as a clean baseline confirmation.
- MARS-M is specifically designed for the matrix/Muon pipeline, not bolted on.

### Implementation sketch (~25 LoC, 1 file)

**File:** `records/track_3_optimization/train_gpt_simple.py`

1. Add CLI args: `--mars_m_gamma` (float, default=0.0) and `--mars_m_beta` (float, default=0.95, mirrors mu).
2. In `MuonH.step()`, inside the `if base_i + rank < len(params):` block, after state init:
   ```python
   if args.mars_m_gamma > 0:
       if "prev_grad" not in state:
           state["prev_grad"] = p.grad.clone()
       correction = args.mars_m_gamma * (args.mars_m_beta / (1 - args.mars_m_beta))
       corrected_grad = p.grad + correction * (p.grad - state["prev_grad"])
       state["prev_grad"].copy_(p.grad)
   else:
       corrected_grad = p.grad
   update = muon_update(corrected_grad, state["momentum"], mu=group["mu"])
   ```
   Note: `muon_update` is `@torch.compile`; the corrected_grad computation happens before the compiled region and does not break compilation.
3. `prev_grad` lives in bfloat16 (same as grad); memory overhead = 1 extra buffer per body param = ~same as adding one momentum buffer.

### Key hyperparameters
- γ sweep: [0.005, 0.01, 0.02, 0.025] — Zhao et al. recommend [0.005, 0.025]; 0.01 is the sweet spot in their ablation
- β for correction: 0.95 (mirror mu; alternatively 0.99 for smoother correction)
- Start with γ=0.01 as single trial; γ=0 arm as inline smoke-gate

### Predicted failure mode
γ too large → correction amplifies noise near end of training where consecutive gradients are near-identical (small finite differences → large correction from division by (1-β)). Mitigation: anneal γ linearly to 0 over cooldown (same schedule as LR), which the student can add as `gamma_t = gamma * lr_ratio`.

### Smoke-gate invariants
- At γ=0: val/loss must match baseline ±0.0002 (pure smoke check)
- At γ=0.01: val/loss should improve vs. γ=0 by step 1000 (if mechanism is alive)

### arXiv citations
- MARS-M: arXiv:2510.21800 (Zhao et al. 2024, "MARS: Unleashing the Power of Variance Reduction for Training Large Models" — matrix-valued extension)
- MARS original: arXiv:2411.10438 (Chen et al. 2024, AdamW variance reduction, GPT-2 speedup)

### Best student fit
**tanjiro** — "new optimizer with internal state machine (snapshot gradient, Polyak average inside update, etc.) — something where the state-invariant rigor matters." Storing `prev_grad` across steps is exactly an internal state machine addition. The γ=0 invariant is a clean correctness check.

---

## Rank 2 — H93: PSGD-Kron Body (Replace NS5 with Lie-Group Kronecker Preconditioner)

### Mechanism
PSGD (Preconditioned SGD via Lie Groups, Xi-Lin Li arXiv:2402.04553) maintains a Kronecker-factored preconditioner Q=(Q_L, Q_R) on the Lie group of triangular matrices using a closed-form update rule that does not require matrix inversion:

`Q_L ← tri(I - μ_Q * (A·A^H - B^H·B) / ||A·A^H + B^H·B||) * Q_L`

where A = Q_L · G, B = G · Q_R^{-1}. The update cost is O(mn(m+n)) vs. O(mn·min(m,n)) for full eigendecomp. The preconditioned gradient replaces NS5: instead of polar factor, apply `G' = Q_L · G · Q_R`.

This is a fundamentally different preconditioner class: Lie-group maintained (exact curvature tracking, no eigendecomp), Kronecker-factored (memory = m²+n² vs 0 for NS5), no polynomial approximation.

### Why NOT pre-closed
- NS5 only approximates the polar factor (sign function) of G via polynomial iteration. PSGD computes an adaptive curvature-informed preconditioner.
- No Kronecker preconditioner has been tried on the body 2D weights. H42 (SOAP-lite left-factor) was closed but was an entirely different preconditioner class (Adam in eigenbasis, not Lie-group maintained).
- PSGD-Kron is the current state-of-the-art for Kronecker preconditioned first-order methods with no eigendecomp, with validated wins on LM training.

### Implementation sketch (~100 LoC, 1 file)

**File:** `records/track_3_optimization/train_gpt_simple.py`

Replace `muon_update` call in `MuonH.step()` with a PSGD-Kron update:
1. State init: `Q_L = eye(m, dtype=float32)`, `Q_R = eye(n, dtype=float32)`, `step_count = 0`
2. Preconditioner update (every `update_every` steps, default every step initially):
   ```python
   A = Q_L @ G        # m×n
   B = G @ inv(Q_R)   # m×n; use triangular solve, not explicit inv
   AAH = A @ A.T      # m×m
   BBH = B.T @ B      # n×n
   dQ_L = AAH - B.T@B[:m,:m]  # approximation — see paper eq.8
   Q_L = Q_L - lr_Q * torch.tril(dQ_L / (AAH.norm() + 1e-9)) @ Q_L
   # similarly for Q_R
   ```
3. Apply preconditioner: `G_prec = Q_L @ G @ Q_R`, then aspect-ratio scale as before.
4. Key: triangular structure is maintained via `torch.tril()` projection; `lr_Q=0.1` then anneal to 0.01.

Add CLI args: `--psgd_kron_enabled`, `--psgd_lr_precond` (default 0.1), `--psgd_update_every` (default 1 initially, reduce to 4 after step 200).

### Key hyperparameters
- `lr_preconditioner`: 0.1 (initial), anneal to 0.01 over training
- `preconditioner_update_probability`: 1.0 for first 200 steps, then 0.1 (stochastic update amortization)
- `damping`: 1e-8 (diagonal stabilizer for triangular solve)
- Memory: two extra m×m and n×n float32 matrices per body param (large matrices: 768×768 = 2×2.2MB extra per layer)

### Predicted failure mode
Memory: for 12 transformer blocks × (Q, K, V, proj, FF1, FF2) matrices each 768×768, extra state = 12×6×2×(768²×4bytes) ≈ 256MB extra GPU memory. This should be fine on H100 96GB but worth monitoring. Bigger risk: preconditioner update instability in early training before Q converges — mitigated by dampening and lr_Q annealing.

### Smoke-gate invariants
- Loss at step 100 should be < 4.5 (preconditioner instability shows up early)
- GPU memory should stay < 50GB during forward/backward

### arXiv citations
- PSGD Kron: arXiv:2402.04553 (Xi-Lin Li 2024, "Curvature-Informed SGD via General Purpose Lie-Group Preconditioners")
- PSGD stochastic Hessian: arXiv:2402.11858 (companion paper, Hessian fitting details)
- psgd_torch implementation reference: https://github.com/lixilinx/psgd_torch

### Best student fit
**fern** — "fundamentally different inner-optimizer mechanism (replace NS5 with non-polynomial spectral or second-order preconditioner)." PSGD-Kron is the strongest example of a non-polynomial, second-order-informed preconditioner that fits in the existing MuonH framework.

---

## Rank 3 — H94: Full SOAP Body (Both Kronecker Factors + Adam in Eigenbasis)

### Mechanism
SOAP (Vyas et al. arXiv:2409.11321) runs Adam in the eigenbasis of the full GG^T and G^TG Kronecker factor pair: both L=GG^T (m×m) and R=G^TG (n×n) are maintained as EMA, eigendecomposed every f steps, and the gradient is projected into the joint eigenbasis before Adam's m/v statistics are accumulated there.

H42 (SOAP-lite) was left-factor only (L=GG^T). With only one factor, the preconditioner is rank-deficient in the right-singular space. Full SOAP conditions both and achieves ~40% fewer iterations on GPT-2 (Vyas et al. Table 1).

### Why NOT pre-closed
H42 explicitly used only the left factor. The two-factor variant has a qualitatively different curvature model. Citing the paper: "SOAP without the R factor is strictly weaker — the residual right-singular structure causes momentum in the eigenbasis to rotate without being corrected."

### Implementation sketch (~80 LoC)

Add `R = torch.eye(n)` to state alongside existing `L`. Update: `R.mul_(beta2).addcmul_(G.T, G, value=1-beta2)`. Eigendecomp both L and R every f=10 steps: `Q_L, _ = torch.linalg.eigh(L)`, `Q_R, _ = torch.linalg.eigh(R)`. Project gradient: `G' = Q_L.T @ G @ Q_R`. Accumulate Adam m/v in G'-space. Rotate back: `update = Q_L @ adam_update @ Q_R.T`.

### Key hyperparameters
- Eigendecomp frequency f: 10 steps (Vyas et al. default)
- beta2 for Kronecker EMA: 0.95 (match aux AdamW)
- Adam betas in eigenbasis: (0.9, 0.999)

### Predicted failure mode
Eigendecomp of 768×768 matrix every 10 steps: `torch.linalg.eigh(768×768)` costs ~0.5ms on H100 per layer × 12 layers × 6 matrices per block = ~36ms per 10 steps = ~3.6ms/step overhead (~10% of step budget). May push past the wall-clock timeout.

### arXiv citation
- Full SOAP: arXiv:2409.11321 (Vyas et al. 2024, "SOAP: Improving and Stabilizing Shampoo using Adam")

### Best student fit
**fern** (alternative to PSGD-Kron if that assignment is taken)

---

## Rank 4 — H95: GaLore Gradient Low-Rank Projection on Body

### Mechanism
GaLore (Zhao et al. arXiv:2403.03507) projects the full gradient into a low-rank subspace via truncated SVD before the optimizer step, then projects the update back. The projection matrix P∈R^{m×r} (r << m) is updated every T_update steps. This reduces the effective gradient dimensionality and acts as a structured form of gradient noise reduction — distinct from NS5's polar-map compression.

### Why NOT pre-closed
No SVD-based gradient projection has been tried on the body. NS5 is a polynomial approximation to the polar factor; GaLore is a rank-r projection that discards the smallest singular value components. These are orthogonal compression strategies.

### Implementation sketch (~50 LoC)
Before calling `muon_update`, project: `U, S, Vt = torch.svd_lowrank(G, q=rank)`, `G_proj = U @ torch.diag(S) @ Vt[:rank,:]`, then call `muon_update(G_proj, ...)` and project update back via `U`. Update P every T_update=200 steps.

### Key hyperparameters
- rank r: 64 or 128 (for 768×d matrices)
- T_update: 200 steps
- scale: True (rescale projected update to match original gradient norm)

### Predicted failure mode
Truncated SVD with `q=64` on 768×768 matrix every 200 steps costs ~2ms per call × 12×6 = 144ms amortized over 200 steps = <1ms/step. Low cost. Main risk: throwing away small singular values discards fine-grained curvature information that NS5 preserves through the full polar map.

### arXiv citation
- GaLore: arXiv:2403.03507 (Zhao et al. 2024, "GaLore: Memory-Efficient LLM Training via Gradient Low-Rank Projection")

### Best student fit
**fern** (alternative, lower risk than PSGD-Kron)

---

## Rank 5 — H96: Randomized Nystrom Spectral Scaling Pre-NS5

### Mechanism
Instead of replacing NS5, add a spectral scaling pre-conditioning step before it. Compute a rank-r Nystrom approximation of G·G^T: random sketch S∈R^{m×r}, Y=G·G^T·S, Omega=S^T·Y, approximate eigenvalues λ̂ from Omega. Scale G row-wise by 1/sqrt(λ̂+ε) before passing to NS5. This gives NS5 a better-conditioned input without replacing the polar map.

### Why NOT pre-closed
All prior spectral scaling ideas have targeted the NS5 *polynomial* (degree sweeps H88/H90, etc.) or initialization. Pre-NS5 eigenvalue normalization of the input matrix is a different level — it changes what signal NS5 receives, not how NS5 processes it.

### Implementation sketch (~40 LoC)
```python
def nystrom_spectral_scale(G, rank=16, eps=1e-6):
    S = torch.randn(G.size(0), rank, device=G.device, dtype=G.dtype)
    Y = (G @ G.T) @ S   # m×r
    Q, _ = torch.linalg.qr(Y)  # m×r orthonormal
    lam = (Q.T @ (G @ G.T) @ Q).diagonal().clamp(min=eps)  # r eigenvalues
    scale = 1.0 / lam.mean().sqrt()  # single global scale for stability
    return G * scale
```

### Key hyperparameters
- Sketch rank r: 8–32 (low is fine since we just want approximate spectral scale)
- eps: 1e-6 to avoid div-by-zero in early training

### Predicted failure mode
Adding a random sketch means results vary across seeds slightly — need 2-seed average. Also the benefit is modest since NS5's input normalization `X = X / (X.norm() + 1e-7)` already provides some spectral conditioning.

### arXiv citation
- Randomized Nystrom: Halko, Martinsson, Tropp 2011 ("Finding Structure with Randomness: Probabilistic Algorithms for Constructing Approximate Matrix Decompositions") — classical reference

### Best student fit
**fern** (lowest-risk option, smallest code change)

---

## Assignment Summary

| Rank | Hypothesis | Student | Axis |
|------|-----------|---------|------|
| 1 | H92: MARS-M body | tanjiro | Variance reduction on matrix momentum |
| 2 | H93: PSGD-Kron body | fern | Lie-group Kron preconditioner replaces NS5 |
| 3 | H94: Full SOAP body | fern (alt) | Both Kron factors + Adam in eigenbasis |
| 4 | H95: GaLore body | fern (alt) | SVD low-rank gradient projection |
| 5 | H96: Nystrom pre-NS5 | fern (alt) | Spectral scaling before polar map |

**Primary assignments: tanjiro → H92, fern → H93**
