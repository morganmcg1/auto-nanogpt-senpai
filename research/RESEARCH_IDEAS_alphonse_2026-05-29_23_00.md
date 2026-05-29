# Fresh Hypothesis Ideas for alphonse — 2026-05-29 23:00

**Context**: alphonse idle after PR #1703 ADOPT async whitening bilateral NULL.
**Baseline**: PR #1532 val_ema=3.262854, sr=2875 (n=2).
**Merge gate**: sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854).
**Directive #1252**: Prioritize (a) optimizer-state resets/rescaling at phase boundaries, (b) per-layer/per-block optimizer behavior, (c) short phase-specific mechanisms, (d) momentum/preconditioner state handling, (e) schedules that steepen loss descent before step 2925. Avoid pure scalar β/μ/EMA sweeps.

**Hard constraints for these hypotheses:**
- NS5 pipeline is triple-load-bearing (magnitude normalization, rank-deficiency clipping, null-space suppression). Confirmed catastrophically by Shampoo body-Muon PR #985: removing NS5 → rank-1 L_cov null eigenvalues amplified 1000× → weight norm 6.4M (baseline ~6,219) → val/loss ~4.62 at step 500. Any preconditioner hypothesis MUST work BEFORE or alongside NS5, never replacing it.
- All closed axes: μ pulse (all temporal regimes), cov-state hard zero at step 975 (#725), ADOPT async whitening (#1703), per-element AdaShift (#1709), AdEMAMix on aux (#305, #585, #846) AND body (#977), Shampoo body-Muon (#985), pEMA stacked-refresh (#1704), LR drop bilateral (#1697), wd bilateral (#1693), μ pulse (#1686), β_cov binary group Arm A (#1727), cov hard zero at 2750 Arm A (#1726).
- In-flight (do NOT duplicate): AdEMAMix dual-EMA aux #1749 (thorfinn), momentum hard-reset #1730 (askeladd), NS_ITERS burst {14,16} #1739 (fern), Skylight u/w floor pulse #1708 (frieren), depth-asymmetric LR-mult burst #1742 (tanjiro), cov hard-zero #1726 (nezuko Arm B), depth-split β_cov #1727 (edward Arm B).

---

## RANK 1 (TOP PRIORITY): Newton-Muon Right-Preconditioner

### What it is

Right-precondition the raw gradient G with the inverse square root of the per-layer activation Gram matrix (X^T X)^{-1/2} BEFORE feeding into the standard PMuon pipeline (momentum accumulation → NS5 → polar projection). NS5 is fully preserved and operates on the already activation-whitened gradient.

### Why it might help here

PMuon's L_cov and R_cov bilateral whitening operate on the momentum buffer m, not the raw gradient G. This leaves the activation-side curvature of each linear layer unaddressed: if two output neurons receive correlated activations, their gradient directions are not independent in G. Newton-Muon's X^T X Gram-matrix preconditioning removes this correlation before the optimizer even sees the gradient, making the NS5 → polar step operate on a curvature-normalized signal. The published result on the same FineWeb GPT benchmark (Muon 3.2793 → Newton-Muon 3.2611 at 3100 steps, single H100) provides direct external evidence that this mechanism has headroom on exactly this problem. This repo has NEVER tested Newton-Muon (confirmed by grep — zero matches). This is not the same as Shampoo (#985): Shampoo tried to REPLACE NS5 with its own matrix power; Newton-Muon keeps NS5 intact and adds activation curvature as a PRE-STEP.

**Directive alignment**: (d) preconditioner state handling change.

### Key paper

Newton-Muon (arXiv:2604.01472, 2026). Same-benchmark evidence: trains FineWeb GPT with Muon baseline 3.2793 → Newton-Muon 3.2611 at 3100 steps on single H100. Mechanism: replace standard Muon gradient G with `G (X^T X)^{-1/2}` using Gram matrix computed from forward activations X captured via backward hooks. NS5 + polar projection pipeline is unchanged.

### Implementation notes

For each linear layer W ∈ R^{m×n}, capture activation X ∈ R^{B×n} from the forward pass. Maintain a running EMA of the Gram matrix:

```python
# In forward hook per linear layer:
A_ema = beta_gram * A_ema + (1 - beta_gram) * (X.T @ X) / X.shape[0]

# Before PMuon update:
# Arm A (diagonal approximation):
scale = 1.0 / (diag(A_ema).sqrt() + eps_gram)   # shape [n]
G_precond = G * scale.unsqueeze(0)               # per-column scaling

# Arm B (full Gram matrix):
G_precond = G @ matrix_neg_power(A_ema, 0.5)    # full right-preconditioning
```

Then feed G_precond into the standard PMuon pipeline (m update → NS5 → polar). Key hyperparameters:
- beta_gram: EMA decay for X^T X, suggested 0.95 (same scale as beta_cov)
- eps_gram: numerical floor, suggested 1e-6
- The `matrix_neg_power` function already exists in the codebase (used for L_cov/R_cov); reuse it directly with niter=12.

**Critical implementation guard**: Gram matrix X^T X is n×n (activation dimension squared). For d_model=768 this is 768×768 = fine. Do NOT apply to embed or lm_head (they are covered by aux AdamW). Apply only to body MLP and attention projection layers.

**Common mistakes**:
- Do not confuse activation X (input to layer W) with weight gradient G. Hook must capture layer INPUT, not output.
- Do not mix up left vs right preconditioning: Newton-Muon specifies RIGHT preconditioning `G (X^T X)^{-1/2}`, not `(X^T X)^{-1/2} G`.
- Gram EMA must be maintained with `no_grad()` and stored as a buffer, not a parameter.
- Arm B (full matrix power) may be slower; profile step time vs baseline before running full training.

### Bilateral arm design

**Arm A — Diagonal approximation (safe)**
- Mechanism: `scale = 1 / (diag(A_ema).sqrt() + eps_gram)`, applied as per-column scaling of G before PMuon.
- Rationale: diagonal Gram is O(n) storage and O(1) application; tests whether activation-variance normalization alone helps without the full matrix inversion cost.
- Hyperparams: beta_gram=0.95, eps_gram=1e-6, all body linear layers.

**Arm B — Full Gram matrix right-preconditioning (hypothesis)**
- Mechanism: `G_precond = G @ matrix_neg_power(A_ema, 0.5, niter=12, eps=1e-6)`, then standard PMuon.
- Rationale: full off-diagonal Gram captures inter-neuron activation correlations; closer to the published Newton-Muon mechanism.
- Hyperparams: beta_gram=0.95, eps_gram=1e-6.

**Decision tree**: If Arm A shows >0.001 val_ema improvement → Arm B is likely worth full cost. If both NULL → pre-conditioning the PMuon gradient does not help at this convergence stage (note: published results were at 3100 steps, we are optimizing for step 2875 target).

### Suggested experiment design

1. Implement forward hooks that capture input activations for each body linear layer and maintain `A_ema` buffers (detached, no_grad).
2. In the PMuon optimizer step, before computing the momentum update, right-multiply G by the appropriate preconditioner.
3. Run Arm A first (diagonal, cheap) as a screening run at train_steps=3250.
4. If Arm A val_ema < 3.262 or sr < 2875, run Arm B.
5. If Arm A is already at merge gate, declare bilateral terminal on Arm A alone.

**Stop condition**: Both arms with val_ema ≥ 3.265 → Newton-Muon preconditioning does not combine with this stack's existing bilateral whitening.

### Taste rubric
- Research mode: **tier shift** (new mechanism, external same-benchmark evidence, completely untested)
- Mechanistic grounding: 4 — precise mechanism (right-precondition G with activation Gram inverse sqrt before NS5), external same-benchmark paper evidence, confirmed untested in this repo, does not conflict with any closed axis
- Research-state value: 4 — would either open a new improvement axis (activation curvature preconditioning orthogonal to bilateral gradient whitening) or close it definitively; result interpretable either way
- Execution value: 3 — Arm A (diagonal) is cheap and discriminating; Arm B adds cost but is motivated by external evidence; both map directly to paper-facing metric

---

## RANK 2: Block-wise AdaShift (Scalar v_t Per Tensor, Lag n)

### What it is

For each body parameter tensor, maintain a single scalar second-moment estimate `v_t = max(|g_{t-n}|)²` using the Frobenius norm of the gradient lagged by n steps. Use this scalar as a per-tensor step-size correction multiplied onto the PMuon update magnitude before applying.

### Why it might help here

Standard AdaShift (per-element) was explicitly closed in PR #1709 due to three failure modes: (1) cold-start zeros for embed, (2) sparse-embed incompatibility, (3) self-scaling loss on lm_head. The PR #1709 closure note explicitly reserved the block-wise scalar variant as "a separate hypothesis with different mechanism and different failure modes." Block-wise AdaShift sidesteps all three failure modes: there is no per-element zero cold-start (scalar norm is always non-zero after step n), no sparse incompatibility (tensor norm is dense regardless of sparsity), and no self-scaling pathology on lm_head (that layer is handled by aux AdamW, not PMuon). The temporal lag n provides a form of step-size adaptation that is phase-sensitive: during the cooldown phase, gradient norms shift as LR decays, and a lagged second moment can dampen over-damped steps or amplify under-damped ones.

**Directive alignment**: (c) short phase-specific mechanism, (d) state handling change (maintaining lag buffer).

### Explicit reservations from PR #1709 closure

The closure note at EXPERIMENTS_LOG line 120-121 reads: "Block-wise AdaShift (scalar v_t per tensor using max(|g_{t-n}|)²) untested but reserved as a separate hypothesis — different mechanism, different failure modes." This is a direct reservation for alphonse's use.

### Implementation notes

```python
# Per tensor buffer (stored alongside PMuon state):
grad_lag_buffer: deque of last n gradient Frobenius norms

# At each step for each body param tensor p:
g_norm_sq = (grad.norm(dtype=torch.float32) ** 2).item()
lag_buffer.append(g_norm_sq)
if len(lag_buffer) > n:
    lag_buffer.popleft()

# Use lagged norm as scalar second moment:
if len(lag_buffer) == n:
    v_t = lag_buffer[0]  # the oldest (lagged by n steps)
else:
    v_t = g_norm_sq  # warm-up: use current norm

# Apply as per-tensor scale on the PMuon update:
scale = 1.0 / (v_t ** 0.5 + eps_adashift)
update = muon_update * scale  # muon_update is post-NS5 polar result
p.data.add_(update * lr)
```

Key hyperparameters:
- lag n: Arm A = 3, Arm B = 5
- eps_adashift: 1e-6 (should be small since v_t is a norm squared, not per-element)
- Apply ONLY to body linear layers (same scope as PMuon), not embed/lm_head

**Common mistakes**:
- v_t should be the lagged gradient's squared Frobenius norm, not its current value (would degenerate to a scalar Adam without the shift benefit).
- The lag buffer must be stored in the optimizer state dict and survive checkpoint/resume.
- Do not mix lag with momentum buffer m — the lag buffer is over raw gradients, not the momentum-accumulated m.

### Bilateral arm design

**Arm A — Short lag n=3**
- Tests whether very recent gradient norm history provides a useful step-size signal.
- At batch_size=B and 3250 total steps, lag=3 corresponds to ~3 steps of gradient history.

**Arm B — Moderate lag n=5**
- Tests whether a slightly longer lag (5 steps) captures lower-frequency norm variation.

**Decision tree**: If Arm A shows improvement → explore longer lags (7, 10). If Arm B fails but Arm A was borderline → the lag length is not the discriminating variable, the scalar normalization itself is the mechanism. If both NULL → block-wise scalar AdaShift does not add signal on top of PMuon's existing bilateral whitening.

### Taste rubric
- Research mode: **frontier refinement** (explicitly reserved in prior closure, building on established gradient)
- Mechanistic grounding: 3 — mechanism targets specific observed failure modes from #1709 closure (per-element cold-start, sparse incompatibility), explicit reservation, clearly distinct implementation
- Research-state value: 3 — would either open scalar v_t as a new PMuon enhancement or close the AdaShift family entirely; either is a clean update to the research map
- Execution value: 3 — very cheap to implement (deque of norms), no matrix operations, no hooks needed; Arm A/B test the lag sensitivity cheaply

---

## RANK 3: Kronecker Pre-Conditioning + NS5 (SOAP-Aware Variant)

### What it is

Compute running Kronecker-factored curvature estimates (K_L ∈ R^{m×m}, K_R ∈ R^{n×n}) for each body weight matrix W ∈ R^{m×n} using gradient outer products. Apply `K_L^{-γ_k} G K_R^{-γ_k}` to pre-condition the raw gradient BEFORE entering the standard NS5 + PMuon pipeline. The critical distinction from Shampoo (#985): K_L and K_R are applied as a pre-conditioning step on G; NS5 operates afterward on the already pre-conditioned gradient. NS5 is never replaced.

### Why it might help here

PMuon's bilateral whitening L_cov and R_cov are computed from the EMA of the MOMENTUM buffer m, not the raw gradient G. Kronecker pre-conditioning captures the actual gradient curvature (outer products of gradient factors) rather than momentum-accumulated smoothed curvature. This provides a second, independent curvature correction signal that acts at a different timescale and from a different source. The SOAP paper (Vyas et al., 2024) showed that Kronecker pre-conditioning of Adam in the gradient's natural eigenbasis improves convergence on transformer language models — the analog here is using Kronecker curvature to pre-condition G before the polar pipeline acts on it. This approach is in the next-directions queue (#5 in the research state) and has never been tested in this repo.

**Critical constraint**: Shampoo (#985) catastrophically failed because it REPLACED the NS5 → polar pipeline with its own matrix power update. This hypothesis must not repeat that mistake. K_L and K_R pre-condition the input to NS5; they do not replace NS5.

**Directive alignment**: (d) preconditioner state handling change.

### Key papers

- SOAP: Improving and Stabilizing Shampoo using Adam in the Shampoo Eigenbasis (Vyas et al., 2024, arXiv:2409.11321). Shows Kronecker-factored preconditioning improves transformer LM training. Key insight: maintain K_L = EMA(g g_left^T), K_R = EMA(g_right^T g) from gradient factor outer products.
- Shampoo failure in this repo (PR #985): CATASTROPHIC when NS5 removed — confirms NS5 is triple-load-bearing and any Kronecker approach must preserve it.

### Implementation notes

For W ∈ R^{m×n}, gradient G ∈ R^{m×n}:

```python
# Maintain running Kronecker factor EMAs:
K_L = alpha_k * K_L + (1 - alpha_k) * (G @ G.T) / n   # m×m
K_R = alpha_k * K_R + (1 - alpha_k) * (G.T @ G) / m   # n×n

# Pre-condition G before PMuon:
G_precond = matrix_neg_power(K_L, gamma_k) @ G @ matrix_neg_power(K_R, gamma_k)

# Then feed G_precond into standard PMuon:
m = beta_m * m + G_precond          # momentum on pre-conditioned gradient
update = NS5(m) @ polar(...)        # standard NS5 + polar pipeline unchanged
```

Key hyperparameters:
- alpha_k: Kronecker EMA update rate (Arm A = 0.01, Arm B = 0.05)
- gamma_k: power for K_L^{-γ_k} (suggested 0.25, matching existing gamma_power=0.4 regime)
- Use same `matrix_neg_power` function from codebase (niter=12)
- Apply only to body linear layers (same scope as PMuon)

**Common mistakes**:
- K_L is m×m and K_R is n×n — for d_model=768 and intermediate_dim=3072 these can be expensive. Profile memory and step time before full run.
- Do NOT zero-initialize K_L and K_R as identity (would cause division by zero through matrix_neg_power). Initialize as identity matrix scaled by eps_k ≈ 1e-6, or as `(G @ G.T + eps I)` from first gradient.
- The pre-conditioning must happen BEFORE the momentum buffer update, so m accumulates pre-conditioned gradients, not raw gradients. (Alternative: apply K_L/K_R to m instead of G — different mechanism, separate hypothesis.)
- The Shampoo failure was specifically: L_cov rank-deficient at step 1 → null eigenvalues → 1000× amplification. K_L will also be rank-deficient early (rank(G@G.T) ≤ batch_size). Use eps regularization: `matrix_neg_power(K_L + eps*I, gamma_k)` with eps ≥ 1e-4 at early steps.

### Bilateral arm design

**Arm A — Lightweight rank-1 approximation, slow update rate (alpha_k=0.01)**
- Uses rank-1 outer product approximation instead of full m×m matrix: `K_L_approx = alpha_k * K_L_approx + (1-alpha_k) * g_left * g_left.T` where g_left = G.mean(dim=1). Storage O(m+n) instead of O(m²+n²).
- Slower update rate reduces instability risk at early steps.

**Arm B — Full Kronecker factors, moderate update rate (alpha_k=0.05)**
- Full K_L (m×m) and K_R (n×n) matrices maintained per body layer.
- Higher update rate captures gradient curvature more responsively.

**Decision tree**: If Arm A improves → full Kronecker (Arm B) is likely worth the memory cost. If both fail despite eps regularization → Kronecker curvature on raw G before NS5 is redundant with PMuon's bilateral whitening of m (the two signals may carry the same information through different paths).

### Taste rubric
- Research mode: **tier shift** (new curvature mechanism, queue item #5, untested in repo, well-grounded external evidence)
- Mechanistic grounding: 3 — mechanism is precise (Kronecker-factor pre-conditioning BEFORE NS5 to avoid Shampoo failure mode), external SOAP evidence on similar transformer LM training, critical constraint from PR #985 explicitly stated
- Research-state value: 4 — would either open Kronecker curvature as a new improvement axis for the stack OR definitively close the SOAP/Shampoo family (with the NS5-preserving version having been tried); sharp update either way
- Execution value: 2 — Arm A (rank-1) is reasonably cheap; Arm B (full K_L, K_R) may be memory-intensive and slow; requires careful profiling before committing to a full run

---

## RANK 4 (BORDERLINE): Cov-State Soft Partial Reset at Step 2750

### What it is

At step 2750 (pre-target window, NOT cooldown onset), multiply PMuon's bilateral covariance matrices L_cov and R_cov by a scalar α ∈ {0.4, 0.6} rather than zeroing them. This is a "soft decay" rather than a hard reset, intended to allow the optimizer to partially re-adapt curvature estimates to the lower-LR gradient regime in the final 175 steps before the target window.

### Why it might help here

PR #725 tested cov-state reset at step 975 (cooldown onset): 0.5× was worse than 0.0×. But the timing (step 2750 vs 975) and the context (deep in cooldown vs cooldown onset) are materially different. At step 2750, the model is 175 steps from the target window and the gradient landscape is already shaped by 1775 steps of cooldown decay. A soft partial reset at this late stage may let L_cov and R_cov re-align to the current gradient statistics without the full disruption of a hard zero. The in-flight PR #1726 (nezuko) tests a HARD ZERO at step 2750 — Arm A returned NULL sr=2950. A soft partial reset (α=0.4 or 0.6) is a distinct experiment: the research question is whether the softness of the reset matters, not just the timing.

**Risk**: Arm A of #1726 (hard zero at 2750) was NULL. The pre-target window may not tolerate ANY cov-state disruption. This is the borderline hypothesis — it should be assigned only if higher-priority ideas are already in flight.

**Directive alignment**: (a) optimizer-state rescaling at phase boundary.

### Bilateral arm design

**Arm A — α=0.6 (mild soft decay)**
- At step 2750: `L_cov *= 0.6; R_cov *= 0.6`
- Rationale: mild enough to preserve most accumulated curvature while allowing some re-adaptation.

**Arm B — α=0.4 (stronger soft decay)**
- At step 2750: `L_cov *= 0.4; R_cov *= 0.4`
- Rationale: stronger signal; tests whether the degree of softness matters.

**Decision tree**: If both NULL → cov-state disruption at 2750 is categorically unhelpful regardless of hardness (closes the 2750-reset axis definitively). If Arm A (α=0.6) shows improvement but Arm B NULL → mild softness is the key variable. If both improve → escalate with α=0.8.

**Stop condition**: If nezuko #1726 Arm B (hard zero) also returns NULL, that is strong evidence this axis is closed; do not run this hypothesis.

### Taste rubric
- Research mode: **diagnostic** (testing whether softness of reset at 2750 matters given #1726 Arm A hard-zero NULL)
- Mechanistic grounding: 2 — mechanism is plausible (soft decay vs hard reset), timing distinction from #725 is real, but Arm A of #1726 already NULL at same timing suggests the pre-target window is intolerant of cov-state disruption
- Research-state value: 3 — would close the soft-reset-at-2750 axis definitively or open a new signal; pairs well with #1726 results to fully characterize the 2750 cov-state space
- Execution value: 2 — trivial to implement but baseline risk is high given #1726 Arm A NULL; information value depends on #1726 Arm B outcome

---

## RECOMMENDATION FOR alphonse

**Assign Newton-Muon Right-Preconditioner (Rank 1).**

Rationale:
1. Same-benchmark external evidence (arXiv:2604.01472): Muon 3.2793 → Newton-Muon 3.2611 on the identical FineWeb GPT setup.
2. Confirmed completely untested in this repo (grep returns zero matches for Newton-Muon, activation preconditioning, Gram matrix in PMuon context).
3. Mechanism is precisely differentiated from all closed axes: adds activation curvature correction BEFORE NS5, not replacing NS5 (unlike catastrophic Shampoo #985), not operating on momentum m (unlike existing bilateral whitening), not a β/μ scalar sweep (unlike all closed Tier-1 axes).
4. Arm A (diagonal approximation) is cheap to screen and provides a discriminating first result.
5. Fully aligned with directive #1252 category (d): preconditioner state handling change.
6. Does not conflict with any in-flight student assignment.
