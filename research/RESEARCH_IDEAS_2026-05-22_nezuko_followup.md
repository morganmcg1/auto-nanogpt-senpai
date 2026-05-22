# Hypothesis: Muon-AdEMAMix — Dual Slow/Fast Momentum Inside Muon Before NS Orthogonalization

**Date:** 2026-05-22
**Target student:** g1r5-nezuko
**Track:** modded-nanogpt Track 3 (1-GPU optimizer speedrun, val CE < 3.28)
**Baseline:** PR #699 MERGED, μ=3.261221, σ=0.000593, n=4
**Merge gate:** n=4, μ ≤ 3.259221 (≈ −2σ_single, statistical significance delta = 0.004)

---

## Mechanism

Current Muon maintains a single Nesterov momentum buffer at μ=0.95 (half-life ≈ 14 steps). The gradient memory horizon is therefore short: information from step t−70 has weight < 0.02 by step t.

AdEMAMix (Pagliardini et al. 2024, arxiv 2409.03137) demonstrates that in LLM training, earlier gradients contain information that remains useful for tens of thousands of steps — a slow EMA (β₃ ≈ 0.9999, half-life ≈ 6,931 steps) mixed with a fast EMA at update time reduced token cost by ~51% vs AdamW on a 1.3B model. The key is that the slow EMA captures low-frequency gradient curvature that the fast buffer cannot.

**Proposed change:** before passing the Nesterov update into Newton-Schulz orthogonalization (`soap_ns_step`), mix it with a slow EMA buffer:

```
m_slow ← β₃ · m_slow + (1 − β₃) · grad        # new slow buffer
nesterov_input = raw_nesterov + α_slow · m_slow  # mix before NS
u = soap_ns_step(nesterov_input)                 # unchanged downstream
```

This gives the orthogonalizer a richer, lower-variance gradient signal — the spectral decomposition of a momentum-enriched update rather than a 14-step horizon update. The slow EMA acts as a low-frequency gradient prior that biases the NS update direction without changing the per-step normalization properties.

The interaction with NS orthogonalization is the novel part: AdEMAMix was designed for Adam-style preconditioned updates; here we ask whether the same dual-memory trick improves the *direction* fed to a spectral step rather than an adaptive diagonal step.

**Why now:** #785 alphonse's finding that α=0.50 (half the musoft init magnitude) is best at −2.43σ_single suggests the model is sensitive to the *scale* of gradient-like signals in the update path. A slow EMA mixed before NS orthogonalization is another form of gradient signal scaling with memory — thematically aligned but mechanistically distinct.

**Distinctness check:** Not a kernel mod, not an LR/schedule change, not per-group β/ε tuning, not embed/lm_head/RMSNorm init, not transform init magnitude, not RMS-clamp on Muon output, not adaptive-mu from cos-sim, not gradient clipping on Muon, not NS warmup, not Lookahead (which wraps the optimizer and interpolates weights), not SignMuon (which changes the update sign), not Polar Express (which changes NS iteration count with cosine schedule), not per-block mu_depth_scale (which scales μ by layer depth).

---

## 5-Cell P1 Design

| Cell | β₃ | α_slow | Scope | Role |
|------|-----|--------|-------|------|
| A | 0 (disabled) | — | All Muon groups | Control — baseline replication with mandatory flags |
| **B** | **0.99** | **0.3** | **All Muon groups (mlp + attn)** | **PRIMARY** |
| C | 0.999 | 0.3 | All Muon groups | Slower memory horizon |
| D | 0.99 | 1.0 | All Muon groups | Stronger slow signal |
| E | 0.99 | 0.3 | MLP groups only (no attn SOAP) | Isolate MLP benefit |

**Prediction order (best to worst):** B > C > D > E > A

Rationale: β₃=0.99 (half-life ≈ 69 steps) is a moderate slow horizon, well short of AdEMAMix's 0.9999 but much longer than Muon's existing 0.95. α_slow=0.3 is conservative enough not to dominate the fast Nesterov signal. MLP-only (E) may help since MLP weights dominate Muon's parameter count and are not SOAP-preconditioned by default.

---

## Kill Switches

1. **Early abort (cell B):** If val loss > 3.265 at step 1000 → stop cell B, close PR. Expected loss at step 1000 is approximately 3.28–3.30; a value above 3.265 at that point signals training instability or a bad interaction with SOAP preconditioning.

2. **Post-B gate (cells C/D):** If terminal ffs_mean(B) > ffs_mean(A) + 50 → B failed to improve; close PR without running C/D/E. Save GPU time.

3. **Per-cell:** Any cell that diverges (loss spike > 3.35 after step 500) → terminate that cell and continue to next.

---

## Implementation Notes

**New CLI args** (add to argparse with defaults that disable the feature):
- `--muon_slow_beta` (float, default=0.0 → disabled; set to 0.99 for cell B)
- `--muon_slow_alpha` (float, default=0.3)

**State buffer:** In the Muon optimizer step loop (around line 628), after `state["momentum"]` init, add:
```python
if "m_slow" not in state and group.get("slow_beta", 0) > 0:
    state["m_slow"] = torch.zeros_like(p.data)
```

**Mix point:** After computing `raw_nesterov` (line ~638), before calling `soap_precondition_momentum` or `soap_ns_step`:
```python
if group.get("slow_beta", 0) > 0:
    state["m_slow"].lerp_(p.grad, 1 - group["slow_beta"])
    raw_nesterov = raw_nesterov + group["slow_alpha"] * state["m_slow"]
```

**β₃ warmup:** AdEMAMix uses a warmup schedule for β₃ to avoid the slow buffer dominating early training. For a ~4500-step run, warmup β₃ linearly from 0 to target over first 500 steps (≈ 11% of training). This is important — skip it and early instability will mask any late-training benefit.

**Critical gotcha:** The slow EMA buffer `m_slow` uses the raw gradient (before Nesterov mixing), matching AdEMAMix's formulation. Do NOT use the Nesterov update itself as input to the slow EMA — that would create circular dependency.

**Memory cost:** One additional buffer per Muon parameter tensor. For the Track 3 model (12 layers, d_model=768), Muon covers ~24 weight matrices of shape approximately [768, 768] or [3072, 768]. Extra memory ≈ 24 × 768 × 3072 × 4 bytes ≈ ~225 MB. Well within 96 GB VRAM budget.

---

## Mandatory Flags (all cells)

```bash
--ns_iter 6 \
--soap_attn \
--lr_mlp 0.055 \
--wd_schedule ramp_down \
--lr_scalars 0.03 \
--depth_init_mode musoft
```

---

## ETA

~9 hours total (5 cells × ~1h 48m each, sequential on 1 GPU).

---

## References

1. **AdEMAMix** — Pagliardini et al. (2024). "The AdEMAMix Optimizer: Better, Faster, Older." arxiv 2409.03137. Introduces dual EMA for LLM training; 51% token savings at 1.3B scale; detailed ablations on β₃ and α schedules.

2. **Connections between Schedule-Free and AdEMAMix** — Defazio et al. (2025). arxiv 2502.02431. Shows Schedule-Free Adam can be viewed as a special case of AdEMAMix, clarifying the theoretical basis for long-memory gradient averaging.

3. **Muon optimizer** — Kosson et al. / Jordan et al. (2024). Newton-Schulz–based matrix gradient orthogonalization. Current baseline uses `ns_iter=6`, SOAP preconditioning on attn, `mu=0.95`.
