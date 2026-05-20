# Research Ideas — 2026-05-20 15:30

## H-STORM: STORM Variance Reduction on Aux AdamW Groups

### Hypothesis

Replace the standard first-moment EMA in the aux AdamW groups (embed, lm_head, scalars) with the STORM recursive gradient estimator (Cutkosky & Orabona, NeurIPS 2019). The NorMuon groups are unchanged — Polar Express + Nesterov already handles their gradient variance. This is purely an aux-group intervention.

**Paper**: Cutkosky & Orabona, "Momentum-Based Variance Reduction in Non-Convex SGD", NeurIPS 2019, arXiv:1905.10018.

**STORM+ extension**: Levy, Kavis & Cevher, "STORM+: Fully Adaptive SGD with Momentum for Nonconvex Optimization", NeurIPS 2021 (fully parameter-free variant, also worth considering).

---

### Mechanism

Current aux AdamW first-moment update:

```
m_t = beta1 * m_{t-1} + (1 - beta1) * g_t
```

STORM recursive estimator (replaces the above):

```
# Initialization: d_0 = g_0, prev_g_0 = g_0
d_t = g_t + (1 - alpha_t) * (d_{t-1} - prev_g_{t-1})
prev_g_t = g_t
```

Then pass `d_t` as the effective gradient into the existing AdamW update in place of `g_t`. The second moment `v_t` accumulates `d_t**2` instead of `g_t**2`.

STORM achieves O(T^{-1/3}) convergence for non-convex SGD without requiring large batches. The recursive correction `(d_{t-1} - prev_g_{t-1})` acts as a control variate that tracks the drift between the previous estimator and the previous raw gradient, progressively reducing variance.

`alpha_t` is the decay rate of the correction. Setting `alpha_t` to a fixed constant works well empirically. Schedule: can be set constant or decayed (alpha_t = alpha_0 / sqrt(t)).

---

### Why This Could Win on THIS Stack

1. **eps=1e-6 makes second-moment noise the floor, not the ceiling.** The aux AdamW uses eps=1e-6, which means the preconditioner `1/sqrt(v_t + eps)` has a meaningful noise floor baked in. The remaining variance bottleneck is the first moment estimation. STORM's recursive correction targets exactly this — it does not touch the second moment or the preconditioner, it improves the signal quality of the gradient estimate fed into the existing update rule.

2. **beta1=0.8 short memory exposes raw gradient noise.** The aux groups use beta1=0.8, which is fast-adapting but also fast-forgetting. Standard EMA with beta1=0.8 discards 80% of the previous estimate each step, leaving the first moment highly noisy on small aux groups (embed dim 768, lm_head). STORM's estimator provides bias-corrected directional signal that compensates for this short memory without requiring a longer EMA window.

3. **Aux groups are NOT orthogonalized — raw gradient variance is highest here.** The NorMuon + Polar Express pipeline orthogonalizes the projection matrices. The embed, lm_head, and scalar parameters receive raw gradients with no geometric conditioning at all. This is precisely where variance reduction has the most room to improve signal quality. STORM is additive, not structural — it is a drop-in correction that does not conflict with MuLoCo's outer SGDM wrapper or AGC.

---

### Implementation (~25 LoC)

In `class NorMuonAndAdam`, inside the `step()` method for aux AdamW groups:

```python
# Per param, maintain: state["storm_d"] (STORM estimator), state["storm_prev_g"] (prev raw grad)
# alpha is a scalar hyperparameter (0.05 to 0.2)

for group in self.aux_groups:
    alpha = group.get("storm_alpha", 0.1)
    for p in group["params"]:
        if p.grad is None:
            continue
        g = p.grad.data
        state = self.state[p]
        
        if "storm_d" not in state:
            state["storm_d"] = g.clone()
            state["storm_prev_g"] = g.clone()
        else:
            d_prev = state["storm_d"]
            g_prev = state["storm_prev_g"]
            # STORM recursive update
            d_new = g + (1 - alpha) * (d_prev - g_prev)
            state["storm_d"] = d_new.clone()
            state["storm_prev_g"] = g.clone()
            # Override gradient for AdamW update
            p.grad.data.copy_(d_new)
        
        # Existing AdamW update proceeds with modified p.grad
```

This slots into the existing aux AdamW update path. No changes to NorMuon, Polar Express, MuLoCo, or AGC.

---

### Experimental Arms

| Arm | storm_alpha | Notes |
|-----|-------------|-------|
| A   | 0.05        | Very slow decay of correction — high memory |
| B   | 0.10        | Default STORM recommendation |
| C   | 0.20        | Fast decay, closer to vanilla EMA but variance-corrected |

Run each arm to step 3100 with identical hyperparameters to baseline (lr, wd, betas, eps, AGC clip_ratio). Compare val/loss at step 3100.

**Baseline target**: val/loss < 3.27039 (current merge bar)

---

### Mechanism Distinctness from In-Flight PRs

- **MARS (PR #582, askeladd)**: MARS uses `c_t = g_t + gamma*(beta1/(1-beta1))*(g_t - g_{t-1})` — a lookahead correction scaled by the momentum ratio. Targets Adam's first-moment bias specifically via a single-step lookback. STORM uses a full recursive estimator `d_t = g_t + (1-alpha)*(d_{t-1} - g_{t-1})` that accumulates the estimator history — distinct dynamics, distinct convergence guarantee.
- **AdEMAMix (PR #567, fern)**: Multi-timescale EMA mixture (slow + fast EMA). Structural change to first moment. STORM is a variance-reduction wrapper, not a timescale mixture.
- **outer_momentum ramp (PR #563, nezuko)**: Operates on the MuLoCo outer SGDM level. STORM operates on the aux AdamW inner level.

---

### Predicted Win Condition

Arms B or C (alpha 0.1 or 0.2) reduce val/loss by 0.001–0.003 relative to baseline at step 3100. The win is most likely visible in the embed and lm_head groups where raw gradient variance is highest. If alpha=0.05 (arm A) diverges or degrades, the correction is over-accumulating stale signal — increase alpha. If all arms underperform by < 0.5% relative, the variance bottleneck is not in the first moment and the second-moment preconditioner floor (eps=1e-6) is the true limiter.

---

### Stop Condition

Close if all three arms show val/loss >= 3.272 (worse than baseline by >= 0.001). The mechanism is falsified for this stack if the embed/lm_head first-moment noise is not the bottleneck.
