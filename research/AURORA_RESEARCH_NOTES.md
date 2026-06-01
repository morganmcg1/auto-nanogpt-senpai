# Aurora Optimizer: Research Notes
Date: 2026-06-01

---

## 1. What Aurora Is Mechanically

**Origin.** Aurora was introduced by Dewulf, Pai, Yang, Zhang, and Keigwin at Tilde Research (blog post: May 5, 2026). It is a drop-in replacement for Muon that adds diagonal equilibration to Muon's polar orthogonalization step in order to enforce uniform leverage scores across matrix rows.

**Problem class.** Muon computes a gradient update as `polar(G)`, then scales by the spectral aspect-ratio factor. For rectangular weight matrices (m × n with m ≠ n), the resulting polar factor has non-uniform row norms. This means some rows have disproportionately large influence on the column space — high leverage — which the Aurora authors link empirically to "neuron death" (dead rows with near-zero norm accumulating during training). Aurora addresses the LEFT singular space: it enforces that each row of the polar factor has norm `sqrt(n/m)` (the uniform target under a row-isometry constraint).

**State variables.** Aurora maintains exactly one persistent buffer per parameter, identical to standard Muon:
- `momentum`: Nesterov momentum accumulator (same as Muon).

The diagonal equilibration matrix `D` is NOT persistent across training steps. It is reinitialized fresh on every optimizer call from the current (momentum-updated) gradient's row norms and is then refined over K inner iterations within that single call. There is no cross-step EMA of `D`.

**Update rule (closed-form pseudocode, for tall G of shape m × n, m > n).**

```
# 1. Nesterov momentum update (standard Muon)
momentum = (1 - mu) * G + mu * momentum   # lerp in-place
update = mu * momentum + (1 - mu) * G     # Nesterov extrapolation

# 2. Diagonal equilibration (Aurora only, skipped when m == n)
G32 = update.to(float32)
target_row_sq = n / m                      # uniform target: each row norm^2 = n/m
D = 1.0 / row_norm(G32)                   # initialized fresh from current gradient

for k in range(pp_iterations):            # default pp_iterations = 2
    U = polar(D * G32)                    # NS orthogonalization of equilibrated G
    if k < pp_iterations - 1:
        row_sq = row_norm_sq(U).clamp(min=eps^2)
        D = D * (target_row_sq / row_sq)^pp_beta   # pp_beta = 0.5

# 3. Spectral aspect-ratio scaling (same as Muon)
update = U * sqrt(max(1, m/n))

# 4. Weight update with decoupled weight decay
W = W * (1 - eta * weight_decay) - eta * update
```

For **wide** matrices (m < n): transpose, apply the above, transpose back.
For **square** matrices (m == n): skip equilibration entirely, use plain `polar(update)`.

**Key hyperparameters.**
- `pp_iterations=2` (inner refinement iterations; K=2 is the default in the release)
- `pp_beta=0.5` (damping exponent controlling how aggressively D adjusts)
- `mu=0.95` (Nesterov momentum coefficient)
- `eta=0.05` (learning rate in record #17 context; PR #284 used MUON_LR=0.0375)
- `weight_decay=0.025`
- `eps=1e-7`

**Compute overhead.** Approximately 6% over standard Muon with K=2 inner iterations.

**Scope of effect in GPT-2/nanoGPT architecture (d_model=768).**
- MLP up-projection (3072×768) and down-projection (768×3072): RECTANGULAR — Aurora applies non-trivial diagonal preconditioning.
- Attention Q/K/V/O projections (768×768): SQUARE — Aurora branches to plain `polar(update)`, identical to Muon. No equilibration occurs.

---

## 2. Comparison Table: Aurora vs. Current Production Stack

| Dimension | Aurora | Production Stack (NM, as of PR #1702) |
|-----------|--------|---------------------------------------|
| **What it preconditions** | LEFT singular space: row norms of gradient polar factor | RIGHT singular space: input activation covariance R = EMA(X^T X) |
| **State maintained** | Nesterov momentum buffer only | Nesterov momentum buffer + R-buffer (EMA of X^T X per layer) |
| **Cross-step persistence** | Momentum only; D is per-call ephemeral | R-buffer persists and accumulates across all training steps |
| **Preconditioning operation** | D scaling before NS polar: `polar(D * G)` | Right multiplication after gradient: `NS_polar(G * R^{-1/2})` |
| **Theoretical target** | Uniform row leverage scores (left isometry) | Whitened input activations (right covariance equalization) |
| **Scope (768-dim model)** | MLP weights only (rectangular); attention weights receive NO effect (square → skip) | All weights with d_in ≤ 4096 (configurable via MAX_D_IN), including attention |
| **Interaction with NS iterations** | D initialization is upstream of NS; more NS iters improve polar quality but not leverage directly | NS quality affects how well R-inverse is incorporated; late-peak cooldown shape exploits this |
| **Compute overhead** | ~6% over Muon (K=2) | ~5-10% over Muon (UPDATE_PERIOD=2 amortizes R computation) |
| **Orthogonality guarantee** | Alternating projections: jointly satisfies orthogonality + row-norm constraints | Orthogonality from NS; R-inverse applied pre-NS so final polar is over equilibrated G |
| **Known limitation** | No effect on attention weights (square); no cross-step memory of gradient distribution | R-buffer can be noisy early in training; Tikhonov γ=0.005 required for stability |
| **Record held** | Record #17: 3175 steps (with Contra-Muon + u/w-floor) | Production baseline: 3133.33 steps (PR #1702); Records #16, #19, #20 all post-date Aurora |
| **Relation to each other** | Mathematically orthogonal: Aurora targets rows of polar(G); NM targets columns via R^{-1/2} G | Mathematically orthogonal to Aurora |

**Summary verdict from the table.** The two approaches condition orthogonal spaces. They do not mechanistically overlap. However, the production stack already surpasses Aurora's best recorded result by 42 steps (3133 vs. 3175), and the current world record (Record #20, 3030 steps) does not use Aurora. There is no evidence from the public speedrun leaderboard that Aurora adds value on top of Newton-Muon.

---

## 3. Falsifiable Probe Proposal

**Hypothesis.** If Aurora's left-singular equalization and Newton-Muon's right-singular preconditioning are genuinely orthogonal and both useful, then composing them should yield additive or superadditive gains over either alone. Concretely: after NM applies `G_nm = G * R^{-1/2}`, Aurora's diagonal equilibration could be applied to `G_nm` before NS polar, giving `polar(D * G_nm)` where D is initialized from row norms of `G_nm`. This tests whether the remaining non-uniformity in row leverage of `G_nm` is a bottleneck.

**Mechanistic prediction.** Newton-Muon reduces variance in the right singular values of the update. It does NOT guarantee uniform row norms of the resulting polar factor — that depends on the left singular structure of `R^{-1/2} G`. If Aurora's contribution is purely about left-singular uniformity and NM does not incidentally equalize this, the composition should show a measurable gain. If NM already incidentally flattens row leverage (because whitening inputs tends to produce more balanced gradients), composition should yield no gain.

**Observable to check before a full run.** A cheap diagnostic: log `row_norm_std / row_norm_mean` (coefficient of variation of row norms of the polar update, per layer) for a baseline NM run vs. an Aurora-only run vs. a composed run. If NM already produces low CV (< 0.1), Aurora's left-singular equalization is redundant and the composition will not help. If NM produces high CV (> 0.3), equalization is potentially additive.

**Minimal experiment design.**
1. Instrument the current NM optimizer to log per-layer row-norm CV of the polar update at steps {100, 500, 1000, 2000, 3000}.
2. Compare: (a) baseline NM (no Aurora), (b) Aurora-only (no NM), (c) Aurora + NM composed.
3. If CV is low under NM in step 1, do not run (c). If CV is high, run (c) with pp_iterations=2, pp_beta=0.5, and otherwise identical hyperparameters to production stack.

**Falsifying result.** If (c) does not improve mean val/loss vs. production NM by at least 0.001 (roughly 10 steps at current scaling), Aurora equilibration is not adding value on top of NM and the composition hypothesis is ruled out.

**Scope constraint.** Remember that Aurora has no effect on square matrices (768×768 attention weights). Any composition benefit is MLP-only. This limits maximum possible gain.

---

## 4. Decision Recommendation

**Do not replace Newton-Muon with Aurora. Aurora is a low priority for immediate experimentation.**

The case for deprioritization rests on three independent facts. First, the production stack (3133.33 steps, PR #1702) already surpasses Aurora's best public result (3175 steps, Record #17) by 42 steps, and Records #14 through #20 on the public leaderboard were achieved without Aurora. Aurora as a standalone optimizer is not competitive with the current stack. Second, Aurora's diagonal equilibration is mechanistically orthogonal to Newton-Muon's right-preconditioning, which means adding Aurora on top of NM is a plausible incremental experiment — but the scope of that experiment is narrow: Aurora has no effect on the 768×768 attention weight matrices (square → no equilibration), so any potential gain is limited to MLP weights alone. Third, the compute overhead (~6% per step) must be weighed against the bounded scope of effect. Given that the research program currently has more impactful open directions (NS cooldown geometry, R-buffer axis extensions, LR multiplier tuning), the expected information gain per GPU-hour from an Aurora composition experiment is low.

If the current avenue of R-buffer axis experiments reaches a clear plateau and the MLP-layer row-norm coefficient of variation under NM is measured to be high (CV > 0.3), the composition probe described in Section 3 would become a reasonable low-cost diagnostic. That measurement costs essentially nothing and should gate any decision to run a full Aurora composition experiment.

**The one scenario where Aurora jumps priority:** if an analysis of current NM runs reveals that MLP layer polar updates have systematically high row-norm CV (neuron death signatures), this would be direct evidence that Aurora's left-singular mechanism addresses an active bottleneck. Until that measurement is made, the composition experiment remains speculative.

---

## 5. References

1. Dewulf, Pai, Yang, Zhang, Keigwin. "Aurora: Leverage-Aware Optimizer for Neural Networks." Tilde Research Blog, May 5, 2026. https://tilderesearch.com/blog/aurora

2. Tilde Research. `aurora-release` reference implementation. GitHub: https://github.com/tilde-research/aurora-release (see `src/aurora.py` for the authoritative source; D is ephemeral per-call, not cross-step EMA).

3. @liyang2019. "Contra-Muon + Aurora + u/w-floor" PR #284. KellerJordan/modded-nanogpt, merged 2026-05-10. Result: 20-run mean = 3.27885 steps (Record #17, 3175 steps). https://github.com/KellerJordan/modded-nanogpt/pull/284

4. Kosson, Wortsman et al. "NorMuon" (predecessor row-normalization approach discussed in Aurora blog for comparison). Aurora's alternating-projection approach avoids the ~0.06 precision defect that NorMuon introduces into the orthogonality constraint.
