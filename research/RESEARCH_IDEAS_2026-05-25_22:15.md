# Research Ideas — 2026-05-25 22:15
# Researcher: frieren (g1r2-frieren)
# Corpus state: 319 PRs total | 16 merged | 217 ran | 92 never ran
# Frieren trajectory: 46 PRs closed (including 7-consecutive Riemannian/geometric closure wave)

---

## Research State Summary

### Current bottleneck diagnosis

The floor cluster [3.267, 3.273] has absorbed 40+ distinct optimizer variants without a merge-bar breach (val < 3.26776). The bottleneck is NOT:
- Scalar HP tuning (fully saturated — MUON_LR, WD_AUX, CONTRA_MUON, NS5_ITERS all fixed by stack)
- NS5 polynomial coefficient modification (closed — Amsel/Remez, adaptive, per-iter)
- Post-NS5 bilateral covariance preconditioning (PMuon #82/#187 — closed, val~3.2776)
- Riemannian/Stiefel geometry on momentum (closed — gradient polar projection, parallel transport)
- Lookahead slow-weight averaging (closed — cooldown interference)
- SOAP refresh frequency axis (closed — adaptive threshold degenerates to refresh every step)
- CONTRA mechanism (fully closed)
- AUX one-sided right-factor Shampoo on lm_head (#534 — closed by isotropy)

### Pre-NS5 transform taxonomy (from PR #1101)

Three classes of pre-NS5 gradient transforms, empirically established:
1. **Scalar/Frobenius rescaling** → NS5 σ_i→1 absorbs the scaling (scale-invariant) → floor cluster touch
2. **Per-element non-linear** (relu, signSGD, distortion) → rotates SVD basis → CATASTROPHIC kill
3. **Bilateral structured Kronecker preconditioner** (L^(-1/4) G R^(-1/4)) → changes BOTH U AND V of SVD before momentum lerp → **genuinely novel, 0 corpus hits**

Class 3 is the structural gap. The hypothesis below occupies it.

### NS5 renorm artifact (critical constraint from #1161)

During NS5 iterations, the Frobenius norm of X grows monotonically from 1 → ~27.7 (= √min(m,n) = √768 for body matrices 768×768). Any renorm by Frobenius norm during NS5 iteration resets this convergence progress. ALL implementations MUST apply the bilateral preconditioner to the raw gradient BEFORE handing off to Muon's momentum accumulation — never inside the NS5 loop.

---

## Hypothesis 1 (PRIMARY RECOMMENDATION): SHAMPOO_MUON_BODY

### What it is

Apply full bilateral Kronecker-factored Shampoo preconditioning (L_t^{-1/4} G_t R_t^{-1/4}) to the raw gradient of each body weight matrix BEFORE accumulating into Muon momentum. This is a pre-NS5, pre-momentum structural preconditioner that changes both U and V of the SVD decomposition of the effective gradient, placing it in class 3 of the pre-NS5 taxonomy — the only untested class.

### Mechanism

For each body weight W ∈ R^{m×n} with gradient G_t ∈ R^{m×n}:

1. Accumulate streaming Kronecker factors:
   - L_t = (1-α) L_{t-1} + α (G_t G_t^T)  ∈ R^{m×m}
   - R_t = (1-α) R_{t-1} + α (G_t^T G_t)  ∈ R^{n×n}
   where α = 1/shampoo_update_freq (EMA variant) or α=1 at update steps (batch variant)

2. Compute preconditioned gradient:
   - G_prec = (L_t + ε I)^{-1/4} G_t (R_t + ε I)^{-1/4}

3. Feed G_prec into Muon's momentum accumulation (replacing G_t):
   - m_t = β m_{t-1} + (1 - β) G_prec
   - Then NS5 is applied to m_t as normal

### Why this might work

The key insight: NS5 performs σ_i(m_t) → 1 (polar projection), collapsing all singular values to unit magnitude. If the raw gradient has badly distributed singular values (spectral ill-conditioning), NS5 still converges, but the *direction* of the polar factor it converges to depends on the singular vector structure. Pre-conditioning with L^{-1/4} G R^{-1/4} reshapes the gradient's singular vector distribution, providing NS5 with a better-conditioned input whose leading singular vectors more closely approximate the optimal update direction. In the Shampoo theory (Gupta 2018, Morwani 2024), the Kronecker factor approximation is exact when the gradient has Kronecker structure, and approximate otherwise — but approximate is sufficient to improve the condition number of the input to NS5.

PMuon (closed) applied bilateral covariance AFTER NS5 on the polar output — informationally equivalent to changing the direction of the already-collapsed update. Pre-NS5 application changes what direction NS5 collapses TO, which is mechanistically distinct.

### Anti-duplication grep verdict

Patterns checked against 319-PR corpus:
- `SHAMPOO|KRON_MUON|BILATERAL|MUON_BILAT` → 0 pre-NS5 body bilateral hits (PR #534 is one-sided AUX lm_head; PR #82/#187 are post-NS5 PMuon — both distinct and closed)
- `PRE.NS5.*SHAMPOO|SHAMPOO.*PRE.NS5|PRE.MOMENTUM.*KRON|KRON.*PRE.MOMENTUM` → 0 hits
- `BODY.*BILATERAL|BILATERAL.*BODY|L_FACTOR|R_FACTOR.*BODY|BODY.*L_FACTOR` → 0 hits
- `MUON_PRECOND|BODY_PRECOND|BODY_KRON|MUON_KRON|MUON_SECOND_ORDER|BODY_SECOND_ORDER` → 0 hits
- `BODY_SHAMPOO|MUON_SHAMPOO|GRADIENT.*SHAMPOO|SHAMPOO.*GRADIENT.*BODY` → 0 hits

**VERDICT: GENUINELY NOVEL. 0 hits across all relevant pattern variants in 319-PR corpus.**

### Key papers

- Gupta et al. 2018, "Shampoo: Preconditioned Stochastic Tensor Optimization", arXiv:1802.09568 — original Kronecker-factored preconditioner for matrix-shaped weights; L^{-1/4} G R^{-1/4} formulation
- Anil et al. 2020, "Scalable Second Order Optimization for Deep Learning", arXiv:2002.09018 — distributed/efficient Shampoo; inverse-p-th-root accumulation schedule
- Morwani et al. 2024, "A New Perspective on Shampoo's Preconditioner", arXiv:2406.17748 — establishes that Shampoo's Kronecker factor estimates converge to exact Fisher blocks under gradient Kronecker structure; links to Muon's NS5 polar projection theory

### Distinct from closed PRs

| Closed PR | Mechanism | Why distinct |
|---|---|---|
| #534 | Right-factor Shampoo on lm_head (AUX) | One-sided, AUX optimizer group, post-init, closed by isotropy |
| #82/#187 PMuon | Bilateral streaming covariance power preconditioning AFTER NS5 | Post-NS5 (changes polar output direction), val~3.2776, CLOSED |
| This proposal | Bilateral L^{-1/4} G R^{-1/4} BEFORE momentum lerp (pre-NS5) | Pre-NS5, pre-momentum, changes SVD input to NS5, class 3 taxonomy |

### Implementation notes

Critical: The Kronecker factor update and the p-th-root inverse computation are O(m^3) or O(n^3) per step if done naively. For body matrices 768×768, this is 768^3 ≈ 4.5×10^8 FLOPs per matrix per step — expensive. The standard mitigation is:
1. Update Kronecker factors L_t, R_t every step (cheap EMA, O(m^2) + O(n^2))
2. Recompute (L_t + ε I)^{-1/4} only every `shampoo_update_freq` steps (default 100)
3. Cache the inverse p-th-root between updates

For the pilot arms, use `shampoo_update_freq=50` (Arm A) vs `shampoo_update_freq=100` (Arm B) to test sensitivity to preconditioner staleness.

Damping ε must be set relative to the eigenvalue magnitude of L_t, R_t. A reasonable initial choice: ε = 1e-6 (standard Shampoo default). Too small → numerical instability from near-zero eigenvalues. Too large → collapses toward identity, losing preconditioner signal.

Do NOT apply Shampoo inside the NS5 loop. Apply to G_t before `m_t = β m_{t-1} + (1-β) G_prec`.

Watch for the renorm artifact: if code includes any `X /= X.norm()` inside NS5 iterations when processing the preconditioned momentum, it will reset convergence. NS5 should operate on m_t with its natural Frobenius norm growing from 1→27.7 through iterations.

### Arm definitions

- **Arm A** (primary): `shampoo_update_freq=50`, `shampoo_eps=1e-6`, all Muon body matrices (q/k/v/fc weights, 768×768 or 768×3072)
- **Arm B** (frequency sweep): `shampoo_update_freq=100`, `shampoo_eps=1e-6`, same scope

### Expected mechanism observable

If mechanism is alive: body weight singular value distribution becomes more uniform (condition number drops) across training. This can be measured via `torch.linalg.svdvals(W)` at checkpoints — the ratio σ_max/σ_min should shrink relative to baseline. If the floor cluster is broken, it will show in val/loss below 3.267 by step 2000+.

### Falsification condition

If both arms land in [3.267, 3.273] with no ffs improvement and σ_max/σ_min of body weights at step 3175 is within 5% of baseline, the mechanism is not providing useful conditioning signal beyond what NS5 already achieves. This would suggest the bottleneck is not spectral ill-conditioning of the gradient-to-NS5 input — i.e., NS5 is already converging to approximately the same polar factor regardless of input singular vector structure.

---

## Hypothesis 2: GRAFTING_MUON_AUX

### What it is

Grafting (Agarwal et al. ICLR 2022) applies the direction from one optimizer and the magnitude (global or layer-wise norm) from another. Here: take the update DIRECTION from NS5-Muon, scale its MAGNITUDE to match what AdamW would prescribe for the same parameter group. This is a post-NS5 magnitude calibration, not a pre-NS5 transform.

### Mechanism

For each body weight matrix W:
1. Compute Muon update direction: d_muon = NS5_polar(m_t)  (unit Frobenius norm ≈ 1/√n)
2. Compute Adam-style second-moment estimate: v_t = β2 v_{t-1} + (1-β2) G_t^2  (element-wise)
3. Compute Adam step direction and magnitude: d_adam = G_t / (√v_t + ε)
4. Graft: scale = ||d_adam||_F / ||d_muon||_F  (Frobenius grafting)
5. Apply: ΔW = -lr × scale × d_muon

The result: Muon's direction (which leverages the NS5 polar projection's spectral equalization) combined with Adam's per-parameter adaptive magnitude (which respects gradient heteroscedasticity across parameter dimensions).

### Anti-duplication grep verdict

- `GRAFTING|GRAFT|NORM_GRAFT|MAGNITUDE_ADAM|ADAM_MAGNITUDE|MUON_GRAFT|DIRECTION_MAGNITUDE` → 0 hits in 319-PR corpus
- **VERDICT: NOVEL.**

### Key papers

- Agarwal et al. 2022, "Disentangling Adaptive Gradient Methods from Learning Rates", arXiv:2202.00089 (ICLR 2022) — grafting framework; shows direction/magnitude decoupling is key to optimizer combination
- Vyas et al. 2024, "SOAP: Improving and Stabilizing Shampoo using Adam", arXiv:2409.11321 — SOAP as a modern version of grafting Shampoo direction + Adam diagonal magnitude; already in-stack but on AUX, not body

### Concern

SOAP is already in the stack for attention/MLP weights (AUX path). SOAP can be interpreted as Kronecker-factored direction + Adam-diagonal magnitude — a form of grafting. If SOAP is already covering the grafting mechanism for the relevant weight matrices, grafting Muon body weights with Adam magnitude may provide limited incremental signal. This is the primary uncertainty; the arm should be designed to distinguish "grafting as standalone mechanism" from "overlap with existing SOAP coverage."

### Ranking: SECONDARY (behind SHAMPOO_MUON_BODY)

Grafting is weaker mechanistically because the post-NS5 update already has Frobenius norm ≈ 1/√n (nearly constant per layer), so the "magnitude" grafted from Adam is primarily rescaling a nearly-uniform quantity — it may reduce to a glorified per-layer learning rate schedule, which is a scalar HP variant already saturated.

---

## Hypothesis 3: FIRA_MUON_BODY

### What it is

FIRA (Full-rank Information Residual Approximation, Chen et al. 2024) maintains a low-rank approximation of the gradient (rank-k SVD) and adds back the full-rank residual G_full - G_lowrank via a correction term, ensuring the update is full-rank while keeping the dominant directional information from the low-rank component. Applied pre-NS5 on body weight gradients.

### Mechanism

For each body weight W with gradient G_t:
1. Compute rank-k approximation: G_lr = U_k Σ_k V_k^T  (via randomized SVD, k=4 or k=8)
2. Compute residual: G_res = G_t - G_lr
3. Apply low-rank component to a separate momentum buffer: m_lr,t = β m_lr,{t-1} + G_lr
4. Add full-rank residual correction at each step: m_full,t = m_lr,t + G_res / ||G_res||_F
5. Feed m_full,t to NS5 (replacing standard momentum)

The rationale: low-rank momentum captures persistent directional structure (dominant singular vectors) while full-rank residual correction prevents momentum from becoming too low-rank (avoiding information loss in the higher singular modes that NS5 would still benefit from).

### Anti-duplication grep verdict

- `FIRA|FULL_RANK_RESIDUAL|FULL.RANK.RESIDUAL|RESIDUAL_CORRECTION|LOW_RANK_CORRECT` → 0 hits
- **VERDICT: NOVEL.**

### Key papers

- Chen et al. 2024, "FIRA: Can We Achieve Full-rank Training of LLMs Under Low-rank Constraint?", arXiv:2410.01623 — full-rank residual correction on GaLore/low-rank updates; shows +0.5-1.5% improvement on LM benchmarks over pure low-rank
- Zhao et al. 2024, "GaLore: Memory-Efficient LLM Training by Gradient Low-Rank Projection", arXiv:2403.03507 — underlying low-rank gradient projection baseline

### Concern

The FIRA mechanism is designed for memory-constrained settings (low-rank adapters). In our setting, memory is not constrained (96GB VRAM). The benefit of FIRA is the residual correction preventing information loss, but if NS5 is already a robust signal extractor from full-rank momentum, FIRA's residual correction may not improve what NS5 sees. The per-step randomized SVD also adds O(k × m × n) FLOPs.

### Ranking: TERTIARY (behind SHAMPOO and GRAFTING)

FIRA's mechanism is most compelling in low-rank-constrained settings. Without a memory constraint, the low-rank/residual split introduces complexity without a strong prior that momentum benefit from the decomposition structure in this specific NS5+Muon setting.

---

## Hypothesis 4: MARS_M (existing never-ran PR #788/#306)

### What it is

MARS-M applies STORM-style control variate variance reduction (Yuan et al. 2024) to the Muon gradient before momentum accumulation. The control variate corrects for the expected gradient shift between steps, reducing variance in the momentum signal fed to NS5.

### Status

PRs #788 and #306 exist in the corpus as "Never ran" entries. This hypothesis is not novel (assigned but never executed) but has not been empirically refuted. If frieren's slot is needed for a lower-risk alternative to SHAMPOO, MARS-M is the closest validated-from-literature never-ran option.

### Anti-duplication grep verdict

PRs #788/#306 exist but are "Never ran". The mechanism axis is assigned but unrefuted.

### Ranking: QUATERNARY (behind SHAMPOO, GRAFTING, FIRA)

Not novel (PR exists), but unrefuted. Better as a fallback if SHAMPOO fails rather than a primary assignment.

---

## Ranking Summary

| Rank | Hypothesis | Novel? | Mechanism class | Expected Δval | Risk |
|---|---|---|---|---|---|
| 1 | SHAMPOO_MUON_BODY | YES (0/319 hits) | Pre-NS5 bilateral structured (class 3) | -0.001 to -0.005 | Medium (compute overhead) |
| 2 | GRAFTING_MUON_AUX | YES (0/319 hits) | Post-NS5 magnitude calibration | -0.0005 to -0.002 | Medium (SOAP overlap) |
| 3 | FIRA_MUON_BODY | YES (0/319 hits) | Pre-NS5 momentum decomposition | -0.0005 to -0.002 | Higher (no strong prior for unconstrained) |
| 4 | MARS_M (#788/#306) | No (PR exists) | Pre-momentum variance reduction | Unknown | Lower (never ran) |

---

## PRIMARY RECOMMENDATION: SHAMPOO_MUON_BODY

**Hypothesis slug**: `shampoo-muon-body`

**Rationale for frieren specifically**: Frieren has closed the Riemannian/Stiefel geometry axis (7+ consecutive refutes), the NS5 coefficient axis, and the post-NS5 bilateral covariance axis (PMuon). The pre-NS5 bilateral structured class (Shampoo) is the only remaining class in the pre-NS5 transform taxonomy that is theoretically non-trivial AND empirically untested. This is not a minor variant of a closed axis — it is in a taxonomically distinct class confirmed by PR #1101. The mechanism operates BEFORE the momentum lerp, changing what direction NS5 converges to, not how NS5 converges.

**Structural pivot**: Frieren moves from post-NS5 geometry (Riemannian family, CLOSED) to pre-NS5 structured preconditioning (class 3 of #1101 taxonomy, NOVEL).

**Arms**:
- Arm A: `shampoo_update_freq=50`, `shampoo_eps=1e-6`
- Arm B: `shampoo_update_freq=100`, `shampoo_eps=1e-6`

**Kill gates** (derived from baseline trajectory, not absolute targets):
- Step 500: val > 3.81
- Step 1000: val > 3.66
- Step 1500: val > 3.55
- Step 2000: val > 3.43
- Step 2500: val > 3.36
- Step 3000: val > 3.29

**Stop condition**: If both arms land in [3.267, 3.273] AND body-weight condition number (σ_max/σ_min at step 3175) is within 5% of baseline, close SHAMPOO_MUON_BODY family and pivot to GRAFTING or MARS_M.

---

## Experiment Tree

```
SHAMPOO_MUON_BODY (Arm A: freq=50, Arm B: freq=100)
│
├── Both arms: val < 3.267, ffs ≤ 3000
│   → MERGE. Follow-up: SHAMPOO_MUON_BODY + eps sweep (1e-8 vs 1e-4)
│
├── One arm: val < 3.267, one arm: floor cluster
│   → MERGE winner. Close loser. Pivot on update_freq if mechanism alive.
│
├── Both arms: floor cluster [3.267, 3.273], better than baseline trend
│   → REQUEST CHANGES: try lower eps (1e-8) + higher freq (200) + apply to ALL body matrices
│
├── Both arms: floor cluster, no trend improvement
│   → Measure condition number σ_max/σ_min at step 3175
│   │
│   ├── Condition number improved ≥ 10% vs baseline
│   │   → Mechanism alive, conditioning not the binding constraint.
│   │   → Pivot to GRAFTING_MUON_AUX (post-NS5 magnitude, orthogonal axis)
│   │
│   └── Condition number within 5% of baseline
│       → NS5 is already achieving the conditioning benefit.
│       → Close SHAMPOO family. Assign GRAFTING or MARS_M.
│
└── Any arm: catastrophic (val > 3.29 at step 3000)
    → CLOSE immediately. Pre-NS5 bilateral rotates basis in a direction
      that destabilizes NS5 convergence. Pivot to GRAFTING (post-NS5, lower risk).
```

---

## Taste Rubric

**SHAMPOO_MUON_BODY**:
- Research mode: **tier shift** (new mechanism class, not incremental variant)
- Mechanistic grounding: **4** — mechanism is precise (pre-NS5 bilateral class 3 from #1101 taxonomy), falsifiable (condition number observable), tied to concrete corpus evidence (PMuon closed post-NS5, #1101 taxonomy, 0 pre-NS5 bilateral hits), and has strong theoretical foundation (Gupta 2018, Morwani 2024 Fisher-block theory)
- Research-state value: **4** — if it works, it confirms class-3 pre-NS5 as a productive axis with clear follow-on directions; if it fails with condition number measurement, it sharply constrains the NS5 bottleneck hypothesis and rules out spectral ill-conditioning as the binding factor
- Execution value: **3** — compute overhead (Kronecker factor updates + periodic inverse p-th-root) adds ~10-20% step time; staged via update_freq arms is appropriate; direct paper-facing metric (val/loss at 3175 steps)

**Overall: (4+4+3)/3 = 3.67** — strong tier shift with high research-state value.

---

## Confidence

Strong external evidence from multiple settings (Shampoo/distributed training literature, SOAP convergence theory, Morwani 2024 Fisher-block analysis). Mechanism is theoretically sound and taxonomically novel within this corpus. The primary uncertainty is whether the Kronecker factor estimates stabilize quickly enough (within ~200 warmup steps) to provide useful conditioning signal before NS5 already converges to approximately the same direction — this is testable via the condition number diagnostic. Medium-high confidence that the mechanism is informative even if it does not breach the merge bar.
