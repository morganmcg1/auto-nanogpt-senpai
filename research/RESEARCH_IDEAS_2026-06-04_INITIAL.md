# Research Ideas — Auto-nanoGPT Open SOTA v2 Launch (2026-06-04 INITIAL)

## Frontier Snapshot

| Source | Status | Step | n | Mean val/loss | Margin | Notes |
|---|---|---:|---:|---:|---:|---|
| Senpai PR #1532/#1614 | internal audited | 2905 | 32 | 3.279022187 | 0.005531 | Aux Adam beta2 pulse + PMuon/LR/EMA stack. Best internal. |
| KellerJordan #305 | official merged | 2925 | 8 | 3.27812750 | 0.005297 | Late-capped RRE overlay on #300. Current public record. |
| KellerJordan #300 | official merged | 2930 | 16 | 3.27844375 | — | Aurora on mlp.proj, radial brake, extended Contra-Muon. |
| KellerJordan #303 | official merged | 3000 | 11 | 3.27779333 | — | SODA-style anchor fade. Orthogonal composition source. |
| KellerJordan #318 | open | 2850 | — | ~3.276 (claimed) | unverified | Tail Phase Readout; builds on #311. Highest step claim. |
| KellerJordan #312 | open | 2860 | — | ~3.277 (claimed) | unverified | Aurora + EMA-Nesterov + Reference Interpolation. |
| KellerJordan #311 | open | 2875 | — | ~3.277 (claimed) | unverified | EMA-Nesterov + Aurora + Circuit-Muon. |
| KellerJordan #309 | open | 2890 | — | ~3.277 (claimed) | unverified | EMA-Nesterov + Aurora baseline for #311/#312/#318 stack. |
| KellerJordan #307 | open | 2900 | — | ~3.278 (claimed) | unverified | Contra-Muon extension + Tail Reference Interpolation. |

All open PR claims are hypotheses until reproduced under the benchmark contract (non-cherry-picked, fixed step, stat-sig margin). Mechanisms below are suitable for porting and composing.

---

## Mechanism Library

### PR #308 / #309 — EMA-Nesterov for Muon (arxiv 2605.25395)

**Mechanism**: Adds a momentum lookahead term to the Muon update. At each step, evaluates the gradient at a lookahead point `x + β*m`, then maintains a running EMA of the actual step deltas. Three-stage schedule: β=0 during warmup, β∝lr during main training, β=0 during LR cooldown (critical — activating β during cooldown causes sharp-minima convergence failure).

Full update equations:
```
x^{t+1} = A_t(x^t + β_t * m^t)        # lookahead, then Muon update A_t
m^{t+1} = γ * m^t + (1-γ) * (x^{t+1} - x^t)   # EMA of actual steps
γ=0.99 for <=350M models; max β=0.3-0.7; warmup [0,300), rest [1950,2900] in #309
```

**Composability**: Orthogonal to Aurora (applied at gradient level, Aurora at update level); orthogonal to Normalized Correction (NC is pre-NS, EMA-Nesterov is pre-evaluation); composable with Circuit-Muon (layers stack cleanly); composable with Reference Interpolation (different stages of the pipeline). The #309/#311/#312/#318 lineage demonstrates all four compositions work together.

**Risks**: β must be zeroed during LR cooldown or loss spikes. Step count for rest window needs tuning per step budget. γ=0.99 is probably right for 124M GPT; check if γ needs adjustment when combined with Aurora (which already modifies update geometry).

**Suggested experiment**: Port PR #309's β=0.3 variant (Aurora + EMA-Nesterov, warmup [0,300), rest [1950, K], no NorMuon-lite) directly onto the #300 base. This is the cleanest starting point: #300 is official-merged and has the best-understood hyperparameter state.

---

### PR #310 — Arbor Muon (Pre-NS Row/Column Equilibration)

**Mechanism**: Before the Newton-Schulz (NS) orthogonalization, runs 2 iterations of row/column RMS equilibration on the gradient matrix. Computes row and column scale factors, applies them, clamps scales to [0.25, 4.0] to prevent numerical blowup. Applied to `mlp.fc` and `mlp.proj` only (not attention). After NS, rescales back to preserve the original gradient norm. Stateless — no additional optimizer state per parameter.

Full pseudocode:
```python
# 2-iteration equilibration (stateless, applied pre-NS)
for _ in range(2):
    row_rms = (g ** 2).mean(dim=1, keepdim=True).sqrt().clamp(min=1e-8)
    col_rms = (g ** 2).mean(dim=0, keepdim=True).sqrt().clamp(min=1e-8)
    scale = (row_rms * col_rms).sqrt()
    scale = scale.clamp(0.25, 4.0)   # ARBOR_SCALE_CLAMP
    g = g / scale
g_norm_before = g.norm()
g = zeropower_via_newtonschulz5(g)
g *= g_norm_before / g.norm()        # post-NS rescale
```

**Composability**: Direct competitor to Normalized Correction for the "pre-NS conditioning" slot; can be combined if NC is applied first (NC normalizes row/col norms to 1, Arbor then does iterative refinement). Orthogonal to EMA-Nesterov, Aurora, Reference Interpolation. Does not conflict with Contra-Muon. Possibly redundant with Aurora for mlp.proj (Aurora also operates on those matrices).

**Risks**: The [0.25, 4.0] clamp bounds have not been ablated. Applying to attention may interact badly with Circuit-Muon. The 2-iteration count is a hyperparameter. The mlp.proj interaction with Aurora needs testing.

**Suggested experiment**: Ablate Arbor Muon standalone on #300 base. Compare against Normalized Correction directly to determine which pre-NS intervention is stronger.

---

### PR #295 — Normalized Correction (Nora, arxiv 2605.03769)

**Mechanism**: Single line inserted before NS: divides the gradient by `sqrt(row_norms * col_norms)`. This is equivalent to the `-1/4` power diagonal scaling `diag(mm^T)^{-1/4} * m * diag(m^Tm)^{-1/4}`. Ensures NS starts from a matrix with balanced row and column norms, improving its convergence. Zero extra memory, ~O(mn) compute.

```python
r_norm = update.norm(dim=-1, keepdim=True)    # shape [m, 1]
c_norm = update.norm(dim=-2, keepdim=True)    # shape [1, n]
update = update / torch.sqrt(torch.clamp(r_norm * c_norm, min=1e-12))
# Then NS5 as usual
```

**Composability**: Plug-and-play addition to any Muon variant. Combining with Arbor Muon makes sense (NC first for fast normalization, then Arbor for iterative refinement — but check if this is redundant). Orthogonal to Aurora (Aurora is post-NS on mlp.proj only). Orthogonal to EMA-Nesterov, Circuit-Muon, Reference Interpolation.

**Risks**: PR #295 claims ~3325 steps (single run ~3275), which is worse than #300 (2930). The mechanism alone may be insufficient; it may need a stronger base. The authors claim no tuning was done — this is a mild intervention that likely stacks rather than dominates.

**Suggested experiment**: Add NC to #300/#305 base as a no-cost addition. Expect ~30-50 step improvement or neutral. If neutral on #300, test NC on #309 base where NS conditioning may matter more.

---

### PR #307 — Contra-Muon Extension + Tail Reference Interpolation

**Mechanism (Part 1 — Contra-Muon extension)**: Extends the Contra-Muon contrastive correction from step 2500 (as in #300) to step 2750. Adjusts RADIAL_OUTWARD_SCALE from 0.5 to 0.4 to compensate for the longer correction window. Also adds u/w-floor ramp from 0.3825 to 0.400 and PowerCool LR (`c*(t_end-step)^1.2`).

**Mechanism (Part 2 — Tail Reference Interpolation)**: At the final step only, replaces the model weights with a convex combination of current weights and a checkpoint saved at step 2375: `θ_eval = 0.925*θ_T + 0.075*θ_{2375}`. No val-feedback during training; the reference step (2375) and mixing weight (0.075) are pre-declared. This effectively moves the eval point slightly back in time toward a pre-tail checkpoint.

```python
# Reference captured at step 2375 (no training change)
if step == 2375:
    ref_params = {n: p.detach().clone() for n, p in model.named_parameters()}

# At final step only: interpolate for eval
if step == K:
    for n, p in model.named_parameters():
        p.data = (1 - CGI_GAMMA_NEG) * p.data + CGI_GAMMA_NEG * ref_params[n]
    # γ = -0.075 means: 0.925 * current + 0.075 * ref
```

**Composability**: Reference Interpolation is orthogonal to most training changes (only affects eval weights). Can stack with RRE if applied to the RRE-extrapolated weights (composition order matters). Contra-Muon extension conflicts with #309 lineage which extends EMA-Nesterov rest window instead.

**Risks**: The 2375 reference step is potentially dataset-dependent. Mixing weight 0.075 is fragile if the underlying training changes substantially. Interaction with RRE extrapolation is untested.

**Suggested experiment**: Add Reference Interpolation (γ=-0.075, ref at step 2375) as a post-hoc layer on top of #305's RRE result. These two final-step weight modifications are mechanistically different (RRE extrapolates forward, RI moves backward) and may be orthogonally composable.

---

### PR #311 — EMA-Nesterov + Aurora + Circuit-Muon

**Mechanism (Circuit-Muon)**: Couples the V and O attention weight updates within each attention head. Before the NS step, scales each head's V update by the O head's inverse-norm and vice versa. Then applies a trace-only gauge rebalance that prevents the V and O updates from changing the total V*O product norm. This preserves the OV-circuit's effective output scale while allowing internal rebalancing.

Full per-head update (head dimension h_d=128, λ=1e-3):
```python
s_V[h] = 1 / sqrt(‖W_{V,h}‖²_F / h_d + λ)
s_O[h] = 1 / sqrt(‖W_{O,h}‖²_F / h_d + λ)

# Cross-scale updates
δV_h *= s_O[h];  δO_h *= s_V[h]
# Renormalize to preserve global norms
δV *= n_dV / ‖δV‖_F;  δO *= n_dO / ‖δO‖_F

# Gauge rebalance: zero trace component of V*O change
x_h = (⟨W_{V,h}, δV_h⟩ − ⟨W_{O,h}, δO_h⟩) / (‖W_{V,h}‖²_F + ‖W_{O,h}‖²_F + 2*h_d*λ)
δV_h −= x_h * W_{V,h};  δO_h += x_h * W_{O,h}
```

**Composability**: Circuit-Muon is a drop-in replacement for how V and O updates are generated, orthogonal to how the scalar updates are scheduled (EMA-Nesterov), orthogonal to MLP mechanisms (Aurora, Normalized Correction, Arbor Muon). May interact with PMuon since PMuon also modifies update preconditioners.

**Risks**: The `λ=1e-3` damping is a sensitive hyperparameter — too small causes numerical instability in heads with very small norms; too large kills the coupling benefit. Requires careful separation of V and O parameters in the optimizer, which adds implementation complexity.

**Suggested experiment**: Port Circuit-Muon standalone onto #300 base (without EMA-Nesterov first), to isolate its contribution from the other #311 mechanisms.

---

### PR #312 — Aurora EMA Reference (EMA-Nesterov + Aurora + Reference Interpolation)

**Mechanism**: Combines PR #309 (EMA-Nesterov β=0.3 + Aurora) with Reference Interpolation (γ=-0.075, ref at step 2375) starting from step 2850. CGI_ALPHA=0.0 (no anchor correction). Zeros non-projection biases. Also applies K=2 Aurora iterations (vs K=3 in #309) possibly due to the RI composition.

**Composability**: This PR shows Reference Interpolation can be layered on top of EMA-Nesterov + Aurora without conflicting. The K=2 Aurora change is unexplained — may be an accidental hyperparameter difference or an intentional reduction to prevent overcorrection when RI is also active.

**Risks**: The step 2850 onset for RI is late; there may be a better onset window. K=2 vs K=3 Aurora is an uncontrolled variable that confounds interpretation.

**Suggested experiment**: Use as a composition template; see H5 (Reference Interpolation + RRE) which tests RI composition on the official-merged base.

---

### PR #318 — Tail Phase Readout (Multi-Stage Trajectory Extrapolation)

**Mechanism**: At three fixed steps during the tail phase, applies pre-declared weight updates computed from trajectory differences (differences between parameter checkpoints), projected through a restricted parameter subspace (Muon-other or the "N" subspace). Three phases:

- Step 2400 (t_b): Apply broad update: `b = γ_b * P_M(θ_{2400}^- - θ_{2000}^+)`, γ_b=-0.005
- Step 2750 (t_1): Apply first trajectory: `c_1 = γ_1 * P_N(θ_{2750}^- - θ_{2650}^+)`, γ_1 from -0.04 to -0.12
- Step 2850 (T): Apply second trajectory + orthogonal residual: `c_2 + q` using accumulated trajectory differences and PHASE_READOUT_KAPPA=0.01

This is a multi-point analog of Reference Interpolation, using gradient-of-trajectory rather than simple checkpoint averaging. It is deterministic (no val feedback) and thus benchmark-legal.

**Composability**: Builds on #311 (EMA-Nesterov + Aurora + Circuit-Muon). The trajectory extrapolation is applied as a post-processing step at fixed times, so it stacks on top of whatever training dynamics produce the trajectory. Composable with Senpai beta2 pulse if the pulse runs during main training and the readout is at the tail.

**Risks**: The most complex mechanism in the ecosystem. Multi-hyperparameter (t_b, t_cap, t_0, t_1, T, γ_b, γ_1, γ_2, κ). Sensitivity analysis not available from the PR. Replication on a cleaner base (without all of #311's mechanisms stacked) has not been demonstrated. High implementation risk.

**Suggested experiment**: Port only the simplest element — the single-step trajectory difference at step 2750 (just c_1) — as a starting point. Verify the mechanism adds value before adding c_2 and the orthogonal term.

---

### PR #303 — SODA-Style Anchor Fade (Official Merged)

**Mechanism**: Adds a correction term to hidden matrices (mlp.fc and mlp.proj) that pulls them back toward their initialization values, faded out via a cosine schedule over steps 2000–2750. This is inspired by the SODA optimizer's anchor regularization. The correction is zero at both endpoints of the schedule.

**Composability**: Orthogonal to most other mechanisms; operates on the weight update level, similar in spirit to weight decay but directional. May interact with Aurora (which also focuses on mlp.proj). The fade window (2000–2750) does not conflict with EMA-Nesterov rest windows.

**Risks**: The mechanism is already merged as an official record at 3000 steps. It was not picked up by #300/#305 lineage, suggesting it may not be composable with or additive to the Aurora/RRE stack. Worth testing as a component in new compositions but not as a standalone improvement.

---

## Senpai Stack (PR #1532 / #1614)

**Current Senpai best**: Step 2905, n=32, mean val/loss 3.279022187, margin 0.005531 (stat-sig).

**Key mechanisms**:
- **Aux Adam beta2 pulse**: Pulsed change to the beta2 hyperparameter of the auxiliary Adam optimizer (embedding and lm_head parameters). Timing and magnitude specific to PR #1532/#1614; not present in any KellerJordan PR.
- **PMuon (bilateral streaming covariance preconditioning)**: Alternative preconditioner for the Muon optimizer that uses bilateral streaming covariance approximations. This is Senpai-internal; not public.
- **LR schedule**: Specific learning rate ramp/cooldown tuned for the PMuon dynamics.
- **EMA**: Model EMA for evaluation (separate from the training weights).

**Gap to public record**: Senpai #1532/#1614 at 2905 steps is better than official #305 at 2925 by ~20 steps, but both are within statistical noise range. The open PR claims (#309/#311/#312/#318 at 2850-2890) are potentially ahead of both if they reproduce.

**Composition strategy**: The Senpai beta2 pulse is a discrete intervention on Adam's behavior at specific steps; it should be orthogonal to Muon-side mechanisms like EMA-Nesterov, Circuit-Muon, Aurora, and Normalized Correction. The PMuon preconditioning operates in the same space as Aurora (mlp.proj targeting) and may conflict.

---

## Prioritized Hypotheses

### H1 — Normalized Correction on #305 Base

**Source**: KellerJordan PR #295; Nora paper arxiv 2605.03769.
**Combine with**: #305 base (Aurora + RRE + Contra-Muon extended); no other changes.
**Implementation**: Add the 5-line NC block (`r_norm`, `c_norm`, division by `sqrt(r_norm*c_norm)`, clamped at 1e-12) immediately before `zeropower_via_newtonschulz5` in the `muon_update` function. Apply to all matrices that currently pass through NS. No new hyperparameters.
**Falsification**: If mean val/loss at step 2925 (same step as #305's n=8 result) does not improve by at least 0.0003 across 4 runs, the pre-NS conditioning hypothesis is ruled out for this base.
**Expected step gain**: 20-40 steps (extrapolating from PR #295's ~50-step improvement on a weaker base, discounted for diminishing returns on a stronger base).
**Taste**: Frontier refinement. Mechanistic grounding 3/4 (targets NS conditioning directly). Research-state value 3/4 (confirms or rules out pre-NS normalization as composable). Execution value 4/4 (zero cost, minimal risk, fast result).

---

### H2 — EMA-Nesterov on #300 Base (β=0.3 Variant)

**Source**: KellerJordan PR #309; arxiv 2605.25395 (EMA-Nesterov for Muon).
**Combine with**: #300 base (Aurora mlp.proj, Contra-Muon, radial brake). Use PR #309's exact parameters: β=0.3, γ=0.99, warmup [0,300), rest [1950, K].
**Implementation**: Add momentum buffer per parameter in the Muon optimizer state. At each step: (1) compute lookahead point `x_ahead = x + β_t * m`; (2) evaluate gradient at `x_ahead` (requires a forward/backward at lookahead point — this is equivalent to modifying the parameter before gradient computation, then restoring; verify this is within the benchmark's single-forward-backward-per-step rule by computing the lookahead inside the step function after gradient accumulation). β_t schedule: zero during warmup, ramps proportional to lr/lr_max during main training, zeros during cooldown. Disable NorMuon-lite (set NOR_BETA2=1.0 or equivalent).
**Note on benchmark legality**: The EMA-Nesterov paper formulation evaluates gradient at `x + β*m`, which is a single forward-backward pass at a perturbed point. This is legal under the benchmark contract (one forward-backward per optimizer step) as long as the implementation uses the same computational graph without extra passes.
**Falsification**: If step to reach 3.28 is above 2930 (worse than #300) across 4 runs, EMA-Nesterov does not help on this base. If gradient at lookahead requires an extra forward pass, the approach is benchmark-illegal and should be abandoned.
**Expected step gain**: 30-60 steps based on PR #308/#309 claims (~2890 vs ~3000+ on Aurora base), with uncertainty because #309's base is not #300.
**Taste**: Tier shift (new mechanism, strong external evidence). Mechanistic grounding 4/4 (precise algorithm, external paper, 6% acceleration claim). Research-state value 4/4 (settles whether EMA-Nesterov works on the official merged base). Execution value 3/4 (requires careful benchmark-legality check).

---

### H3 — Circuit-Muon on #300 Base (Isolated Test)

**Source**: KellerJordan PR #311.
**Combine with**: #300 base only (no EMA-Nesterov). Port Circuit-Muon alone to isolate its contribution.
**Implementation**: Split `model.blocks` parameters into `attn_V`, `attn_O`, and `other_2d` groups. In the Muon step, for the V/O group pairs: compute per-head scale factors `s_V[h]`, `s_O[h]`; apply cross-scaling; renormalize global norms; apply gauge rebalance. λ=1e-3, head_dim=128 (matching the model architecture). Keep all other #300 hyperparameters fixed.
**Falsification**: If circuit-muon run at step 2930 (n=4) does not beat #300's mean 3.27844, Circuit-Muon is not contributing to the #311 improvement — the gain must be from EMA-Nesterov alone. This would redirect H6 to skip Circuit-Muon.
**Expected step gain**: 20-50 steps if the mechanism is real; the #311 PR claims ~55 steps of improvement over #300 from the full stack.
**Taste**: Diagnostic. Mechanistic grounding 3/4 (targeted at OV circuit geometry, principled). Research-state value 4/4 (separates Circuit-Muon from EMA-Nesterov in the #311 claim). Execution value 3/4 (moderate complexity, isolated test).

---

### H4 — Arbor Muon vs Normalized Correction Ablation on #300 Base

**Source**: KellerJordan PR #310 (Arbor Muon); PR #295 (Normalized Correction).
**Combine with**: #300 base. Run two arms: (a) #300 + Arbor Muon only, (b) #300 + NC only, (c) #300 + NC + Arbor Muon. Compare all three against #300 baseline.
**Implementation (Arbor)**: Before NS in `muon_update`, run 2-iteration equilibration loop: compute row RMS and col RMS, scale by geometric mean, clamp scales to [0.25, 4.0], apply. After NS, rescale output to match pre-NS gradient norm. Apply to mlp.fc and mlp.proj only (matching PR #310 scope).
**Implementation (NC)**: Single line as described in PR #295 section above.
**Falsification**: If none of the three arms improves over #300 at step 2930, pre-NS conditioning is ruled out for this base. If NC alone beats Arbor alone, prefer NC for all future compositions (cheaper). If NC+Arbor beats either alone, the combination is additive.
**Expected step gain**: 15-40 steps for better of the two; 30-60 steps for combination (speculative).
**Taste**: Diagnostic. Mechanistic grounding 3/4. Research-state value 4/4 (settles pre-NS conditioning question definitively). Execution value 3/4 (three arms is a small cost for a definitive comparison).

---

### H5 — Reference Interpolation Layered on #305 RRE

**Source**: KellerJordan PR #307 (Reference Interpolation); PR #305 (RRE base).
**Combine with**: #305 as base; add Reference Interpolation (γ=-0.075, ref captured at step 2375) at the final step, applied to the RRE-extrapolated weights.
**Implementation**: After the RRE extrapolation step (which replaces current weights with the extrapolated vector), apply: `θ_final = (1+γ) * θ_RRE + (-γ) * θ_{2375}` = `0.925 * θ_RRE + 0.075 * θ_{2375}`. The reference checkpoint at step 2375 must be saved during training (no val feedback needed — this is pre-declared). Composition order matters: RRE first (forward extrapolation), then RI (backward blending) — this may cancel or compound depending on the trajectory geometry.
**Falsification**: If the RI+RRE composition does not beat #305 (3.27812750 at 2925, n=8), the two mechanisms are not orthogonally composable. If composition is worse than either alone, they are in conflict (both manipulating the final weight vector in conflicting directions).
**Expected step gain**: 10-30 steps if additive; possible to reach 2895-2910.
**Taste**: Frontier refinement. Mechanistic grounding 2/4 (composability is speculative; forward+backward extrapolation may cancel). Research-state value 3/4 (settles composability of the two strongest final-step mechanisms). Execution value 3/4 (cheap addition to existing best base).

---

### H6 — EMA-Nesterov + Circuit-Muon on #300 Base

**Source**: KellerJordan PR #311 (full combination).
**Combine with**: #300 base; combine H2 (EMA-Nesterov) and H3 (Circuit-Muon) together. Schedule after H2 and H3 results are known.
**Implementation**: Combines H2's EMA-Nesterov port (β=0.3, γ=0.99, 3-stage schedule) and H3's Circuit-Muon (λ=1e-3, per-head V↔O coupling). No other changes to #300. This is the direct port of PR #311 onto the official-merged base.
**Falsification**: If this does not beat the better of H2 and H3 alone, the two mechanisms are not additive. A result better than H2+H3 arithmetic sum would suggest synergy (interaction between lookahead geometry and V↔O coupling).
**Expected step gain**: 40-70 steps (extrapolating from PR #311's 2875 vs #300's 2930).
**Taste**: Frontier refinement (after H2/H3 diagnostics). Mechanistic grounding 3/4. Research-state value 3/4. Execution value 3/4. Depends on H2 and H3 results — run after those diagnostics confirm the individual mechanisms work.

---

### H7 — Senpai Beta2 Pulse Ported onto #309 EMA-Nesterov+Aurora Base

**Source**: Senpai PR #1532/#1614 (beta2 pulse mechanism); KellerJordan PR #309 (base).
**Combine with**: #309's exact configuration (EMA-Nesterov β=0.3, Aurora K=3, Contra-Muon, no NorMuon-lite). Port the Senpai beta2 pulse for the auxiliary Adam optimizer (embeddings + lm_head) at the same timing and magnitude as in #1532/#1614.
**Implementation**: In the Adam optimizer group for embeddings/lm_head, add a step-conditional beta2 override: at the pulse step(s) declared in PR #1532/#1614, override Adam's beta2 from the default to the pulsed value for one step, then restore. The pulse timing relative to the EMA-Nesterov rest window needs careful checking — if the pulse occurs during the rest window (β_Nesterov=0), there may be less interaction.
**Falsification**: If this composition does not improve on either Senpai #1532/#1614 standalone or PR #309 standalone, the two mechanisms are not orthogonally composable. This would suggest the beta2 pulse and EMA-Nesterov are targeting the same underlying instability.
**Expected step gain**: 10-30 steps beyond #309's ~2890; potential to reach ~2860-2880 range.
**Taste**: Tier shift (first attempt at cross-pollinating Senpai-internal mechanism with public frontier). Mechanistic grounding 3/4. Research-state value 4/4 (first test of Senpai beta2 pulse on public-line base; high information regardless of outcome). Execution value 3/4.

---

### H8 — Full #309 Stack + Normalized Correction

**Source**: KellerJordan PR #309 (EMA-Nesterov + Aurora + Contra-Muon) + PR #295 (NC).
**Combine with**: PR #309 base (EMA-Nesterov β=0.3, Aurora K=3, Contra-Muon extended, no NorMuon-lite, step K=2890). Add NC as the single pre-NS normalization insertion.
**Implementation**: Insert NC block before NS in the Muon update function, on top of the full #309 stack. No other changes. This tests whether NC adds value to the more complex base (not just to the plain #300 base).
**Falsification**: If this does not beat #309's claimed ~2890, NC is not contributing to the #309 base. Note: if H1 (NC on #300) already fails, this hypothesis should be deprioritized.
**Expected step gain**: 10-30 steps beyond #309 (~2860-2880).
**Taste**: Frontier refinement. Mechanistic grounding 3/4. Research-state value 2/4 (depends heavily on H1 result). Execution value 3/4. Priority: after H1.

---

### H9 — Tail Phase Readout (Single Stage) on #300 Base

**Source**: KellerJordan PR #318 (simplified to single trajectory application).
**Combine with**: #300 base only. Implement only the single-step trajectory update (c_1 at step 2750): `c_1 = γ_1 * P_N(θ_{2750}^- - θ_{2650}^+)`, γ_1 from -0.04 to -0.12. Capture checkpoint at step 2650; at step 2750, compute trajectory difference, project through the Muon-other parameter subspace, apply with γ_1=-0.07 (midpoint).
**Implementation**: Add checkpoint capture at step 2650 (memory cost: one extra copy of parameters). At step 2750, compute `diff = θ_{2750} - θ_{2650}`, project diff onto "N subspace" (parameters that are updated by Muon but not in the aurora-special subset), scale by γ_1=-0.07, add to current parameters. Continue training normally from modified weights.
**Falsification**: If val/loss at final step is worse than #300 baseline (no improvement), the trajectory extrapolation mechanism is not providing useful signal for this base. A good test: check if the step-2750 val/loss after the jump improves immediately — if it worsens and then recovers, the mechanism is destabilizing rather than accelerating.
**Expected step gain**: 20-40 steps (much less than the full #318 stack, which claims ~80 steps).
**Taste**: Diagnostic. Mechanistic grounding 2/4 (mechanism is complex and the single-stage extraction may not capture the key insight). Research-state value 3/4 (tests whether trajectory extrapolation is the key #318 mechanism or just incidental). Execution value 2/4 (moderate implementation complexity for uncertain gain).

---

### H10 — EMA-Nesterov + Normalized Correction + Reference Interpolation on #300 Base

**Source**: Composition of #309 (EMA-Nesterov + Aurora), #295 (NC), and #307/#312 (RI). The full no-Circuit-Muon stack.
**Combine with**: #300 base. Adds EMA-Nesterov (β=0.3), NC (pre-NS normalization), and Reference Interpolation (γ=-0.075, ref at step 2375) as three separate orthogonal layers. No Circuit-Muon (separates its contribution from the others).
**Implementation**: Layer (1) EMA-Nesterov from H2, (2) NC from H1/H4, (3) RI at final step from H5. Schedule this after H1, H2, H5 individual results are known.
**Falsification**: If the composition does not beat the best individual mechanism, the mechanisms are not fully additive. If it beats H6 (EMA-Nesterov + Circuit-Muon), Circuit-Muon may be the weak link in the #311/#312 stack.
**Expected step gain**: 50-80 steps beyond #300 (combination of 30-60 from EMA-Nesterov, 20-40 from NC, 10-30 from RI).
**Taste**: Frontier refinement. Mechanistic grounding 3/4. Research-state value 3/4. Execution value 2/4 (high-value but depends on prior diagnostics). Priority: after H1, H2, H5.

---

### H11 — EMA-Nesterov Rest Window Sensitivity (Earlier Beta Shutoff)

**Source**: EMA-Nesterov paper (arxiv 2605.25395); PR #309 rest at step 1950.
**Combine with**: #309 base (EMA-Nesterov β=0.3, Aurora). Test β shutoff at step 1500 vs 1950 vs 2200. The paper notes that β must be zero during LR cooldown to avoid sharp-minima convergence; this tests whether the optimal transition is earlier than PR #309's choice.
**Implementation**: Three arms of H2 (same base #300, same β=0.3, same γ=0.99) with rest window starting at steps 1500, 1950 (original), and 2200. The total step count K=2900 in each arm; only the rest start changes.
**Falsification**: If the 1950 arm is the best or within noise of all three, the rest window is already well-tuned. If an earlier rest start (1500) beats 1950, the benefit of EMA-Nesterov tapers off earlier than PR #309 assumes, suggesting the main gain is in mid-training rather than tail training.
**Expected step gain**: 5-20 additional steps vs H2 if 1500 is better; up to 30 if 2200 is better (keeping EMA-Nesterov active deeper into the tail).
**Taste**: Frontier refinement / diagnostic. Mechanistic grounding 3/4 (directly tests a key paper hyperparameter). Research-state value 3/4 (determines optimal schedule; informs all future EMA-Nesterov compositions). Execution value 3/4 (three cheap arms). Priority: after H2 confirms EMA-Nesterov works on #300 base.

---

### H12 — PMuon + Normalized Correction on #305 Base (Senpai Internal + Public Mechanism)

**Source**: Senpai PR #1532/#1614 (PMuon preconditioning) + PR #295 (NC). Tests whether Senpai's PMuon preconditioning and NC are additive on the official-merged best base.
**Combine with**: #305 as base. Add NC as the pre-NS normalization, then port PMuon preconditioning on top of the full #305 stack (Aurora + RRE + Contra-Muon + radial brake). No EMA-Nesterov (keeps Senpai's own optimizer formulation intact).
**Implementation**: NC is a trivial addition (5 lines). PMuon requires porting the bilateral streaming covariance preconditioning from PR #1614's codebase onto the #305 base script. The key integration point: PMuon replaces or wraps the Newton-Schulz step in `muon_update`; NC should be inserted before PMuon's preconditioning step.
**Falsification**: If this does not beat the better of Senpai #1532/#1614 (2905) and #305 (2925), the PMuon+NC combination is not additive with the #305 stack. This would suggest PMuon and Aurora are competing for the same mechanism slot.
**Expected step gain**: 20-50 steps beyond both current bests, potentially reaching 2870-2890 range.
**Taste**: Tier shift (bridges Senpai-internal and public frontier). Mechanistic grounding 3/4 (NC is additive by design; PMuon on #305 is the key uncertainty). Research-state value 4/4 (either confirms Senpai PMuon as the key mechanism or rules it out as redundant with Aurora). Execution value 3/4 (moderate porting effort, high return if PMuon+Aurora are additive).

---

## Suggested First-Wave Assignments

Priority order for the first wave (8 students):

| Priority | Student | Hypothesis | Step Budget | Notes |
|---|---|---|---|---|
| 1 | student-a | H1 — NC on #305 | 2925 | Trivial to implement; confirms NC composability quickly. |
| 2 | student-b | H2 — EMA-Nesterov on #300 | 2930 | Highest expected gain; settles EMA-Nesterov on official base. |
| 3 | student-c | H3 — Circuit-Muon on #300 (isolated) | 2930 | Diagnostic: separates Circuit-Muon from EMA-Nesterov in #311. |
| 4 | student-d | H4 — Arbor vs NC ablation on #300 (arm a+b) | 2930 | Settles pre-NS conditioning question; 2 arms in one PR. |
| 5 | student-e | H5 — RI on #305 RRE | 2925 | Tests composability of two final-step weight manipulations. |
| 6 | student-f | H7 — Senpai beta2 pulse on #309 base | 2890 | Cross-pollination; high research-state value regardless of outcome. |
| 7 | student-g | H12 — PMuon+NC on #305 base | 2925 | Senpai-internal on best public base; bridges the two frontiers. |
| 8 | student-h | H9 — Single-stage trajectory readout on #300 | 2930 | Tests whether the #318 trajectory mechanism is the key idea. |

**Second wave** (schedule after first-wave results): H6 (EMA-Nesterov + Circuit-Muon, requires H2/H3), H8 (NC on #309 base, requires H1), H10 (full composition, requires H1/H2/H5), H11 (EMA-Nesterov rest window, requires H2).

---

## Composition Decision Tree

```
First wave results
├── H1 (NC on #305) succeeds → NC is composable; add to all future bases
│   └── H1 fails → NC may work on simpler base; try H8 (NC on #309) only if base matters
│
├── H2 (EMA-Nesterov on #300) succeeds → proceed to H6, H10, H11
│   ├── H11 (rest window) → find optimal β schedule
│   ├── H6 (+ Circuit-Muon) → test full #311 stack on official base
│   └── H10 (+ NC + RI) → test full composition without Circuit-Muon
│   └── H2 fails → EMA-Nesterov needs Aurora first → test H2 on #309 base instead
│
├── H3 (Circuit-Muon) succeeds → proceed to H6; Circuitt-Muon is real signal
│   └── H3 fails → drop Circuit-Muon from all compositions; #311 gain is from EMA-Nesterov
│
├── H4 (Arbor vs NC) NC wins → use NC everywhere, drop Arbor
│   Arbor wins → port Arbor to all compositions; revisit H8
│   NC+Arbor wins → both are additive; use both
│
├── H5 (RI on #305) succeeds → RI and RRE are additive; compose in all tail-phase work
│   └── H5 fails → forward+backward extrapolation cancel; use RRE or RI but not both
│
├── H7 (Senpai beta2 on #309) succeeds → beta2 pulse is orthogonal to EMA-Nesterov
│   → immediately add to all EMA-Nesterov compositions
│   └── H7 fails → beta2 pulse and EMA-Nesterov are redundant → investigate timing
│
└── H12 (PMuon+NC on #305) succeeds → PMuon adds to Aurora; push full Senpai+public composition
    └── H12 fails → PMuon and Aurora are competing preconditioners; keep them separate
```

**Stop condition per hypothesis**: Any hypothesis that shows mean val/loss worse than the chosen base by more than 0.0010 across 4 seeds at the declared step should be closed, not sent back. LR/WD retuning alone should not rescue a failed mechanism hypothesis — if the mechanism is real, it should work within ±20% of the base hyperparameters.

---

## Research Constraints (Benchmark Contract)

- Fixed FineWeb data shards; fixed GPT architecture; fixed batch size; one forward-backward per optimizer step
- No per-run early stopping based on val loss; no cherry-picking seeds by best step
- All optimizer code self-contained in training script; no third-party optimizer packages in final claims
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004` — single run needs <3.276; 4 runs need avg <3.278; 8 runs need avg <3.27859
- EMA-Nesterov benchmark legality: must confirm implementation uses a single forward-backward pass; the lookahead step must not require a second gradient evaluation
