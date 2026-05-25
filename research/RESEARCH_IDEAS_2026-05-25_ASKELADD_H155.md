# H155 — MGUP-MuonH: Momentum-Gradient Alignment Selective Step-Size for Body

**Date:** 2026-05-25
**Student:** g1r3-askeladd
**Subsystem:** BODY (MuonH-SI weight matrices only)
**Status:** ASSIGNED

---

## Summary

Apply MGUP (Momentum-Gradient Alignment Update Policy, Da Chang & Yuan, NeurIPS 2025 Spotlight) to the MuonH-SI body optimizer. After NS5 spectral whitening computes the update direction, compute per-parameter cosine similarity between the EMA momentum and the current gradient. Assign lr_high to the top-k% most-aligned parameters and lr_low to the remainder. This operates entirely post-NS5, touching only scalar step-size assignment — mechanism-orthogonal to every closed family.

**Primary citation:** Da Chang, Ganzhao Yuan. "MGUP: A Momentum-Gradient Alignment Update Policy for Stochastic Optimization." NeurIPS 2025 Spotlight. Code: https://github.com/MaeChd/MGUP

---

## Motivation: The 7-Axis Mid-Training-Lead-Erosion Pattern

Seven independent cross-programme replications document the same failure mode:

1. H125 — µ variation under linear cooldown
2. H128 — body init under linear cooldown
3. H135 — body init under linear cooldown (confirmation arm)
4. H133-SQRT — cooldown-shape variation
5. H143 — µ under linear cooldown
6. H147 — β1 variation under linear cooldown (bilateral closure)
7. H146 — Look-Ahead body MuonH under linear cooldown (SEVERE NEG bilateral, just closed)

**Pattern:** The body mechanism builds +0.025 to +0.035 val/loss advantage over aux during the first ~2500 steps. LINEAR cooldown uniformly reduces LR for ALL body parameters, collapsing the accumulated advantage regardless of whether individual parameters are still making useful gradient progress.

**MGUP's direct answer:** During the stable-lead phase (steps 0–2500), most body parameters have high cosine(m_t, g_t) ≈ their momentum and gradient are pointing the same direction. During LINEAR cooldown, some body parameters maintain alignment (still contributing to the task) while others lose alignment (noise-dominated or converged). Uniform LR reduction treats both equally — MGUP does not. Well-aligned parameters retain up to lr_high step magnitude; misaligned parameters are further suppressed. This should preserve the +0.025 body advantage through cooldown rather than eroding it.

---

## Literature Review

### MGUP — Primary Reference

**Da Chang, Ganzhao Yuan. "MGUP: A Momentum-Gradient Alignment Update Policy for Stochastic Optimization." NeurIPS 2025 Spotlight.**

- Per-parameter cosine similarity: s_i = cos(m_i, g_i) = (m_i · g_i) / (||m_i|| · ||g_i|| + ε)
- Binary assignment: top-k% by score → lr_high = base_lr × (1 + α); bottom (1−k)% → lr_low = base_lr × β
- Tested variants: MGUP-AdamW, MGUP-Lion, **MGUP-Muon** — all outperform base optimizer on LLM pretraining
- Implementation: plug-in, ~40 LoC in optimizer step, no additional memory beyond existing momentum buffer
- Threshold k and ratio α/β are the key hyperparameters; paper reports robustness to k in [25%, 75%]
- Code: https://github.com/MaeChd/MGUP

### Modular Norm / Modular Dualization (Secondary, Deprioritized)

**Jeremy Bernstein. "Old Optimizer, New Norm." NeurIPS 2024, arXiv 2405.14813.**

- Architecture-aware natural norm showing Adam and Shampoo as special cases under modular dualization
- GPU-friendly spectral dualize function for linear layers
- ICLR 2025 follow-up "Steepest Descent in the Modular Norm" was **withdrawn** — concerning for production use
- Does not directly target cooldown erosion; secondary candidate only

### Stochastic Polyak / SPS (Deprioritized)

**SPSVRM (2025), SANIA (ICLR 2025):**

- Standard SPS requires f* lower bound; LLM training is non-interpolating, making f* approximation fragile
- SANIA adds scale invariance but still requires Polyak step oracle
- LoC burden and hyperparameter sensitivity too high for this programme

### RACS / Alice (Deprioritized)

**"Towards Efficient Optimizer Design for LLM via Structured Fisher Approximation with a Low-Rank Extension." ICLR 2026.**

- 2× faster than Adam on LLaMA pretraining via structured FIM approximation
- Too complex for 30–100 LoC constraint; memory overhead from Fisher factor storage
- Not body-subsystem compatible without significant architectural refactoring

---

## Orthogonality Justification

MGUP-MuonH is mechanism-orthogonal to every closed or in-flight family:

| Family | Mechanism | MGUP intersection |
|--------|-----------|-------------------|
| NS5 polynomial iteration | Spectral whitening of weight update direction | MGUP operates post-NS5, on step-size scalars only |
| Weight Lookahead (H139, H146) | Outer weight averaging across K inner steps | MGUP is intra-step scalar assignment, no weight buffering |
| EMA coefficient family (H144, H147) | β1 tuning for momentum accumulation | MGUP uses momentum as input signal, does not change how momentum is accumulated |
| LR cooldown shape (H133) | Schedule function applied uniformly | MGUP applies non-uniform per-parameter correction ON TOP of existing schedule |
| µ endpoint axis (H143) | Target LR magnitude at end of cooldown | MGUP changes effective LR per parameter, not the schedule endpoint |
| MuLoCo outer wrapper | Outer Nesterov SGDM sync | MGUP applies inside the inner MuonH step; outer sync unaffected |
| Schedule-Free (PR #265) | Replaces cooldown with iterate averaging | CLOSED; MGUP is compatible with any cooldown shape as a post-schedule correction |
| MARS body (PR #911 H92) | Variance reduction at gradient level (pre-optimizer) | CLOSED; MGUP is post-gradient, post-NS5 |
| SOAP/Shampoo (PRs #54, #700 H42) | Kronecker-factored full-matrix preconditioner | CLOSED; different preconditioner family entirely |
| Optimizer state reset at cooldown (PRs #636, #616) | Hard reset of momentum buffers | CLOSED; MGUP uses momentum buffer as signal, does not reset it |
| AGC (active maintenance) | Gradient norm clipping by layer | Applied before optimizer step; MGUP applies after NS5 inside optimizer step |

**Conclusion:** No mechanism overlap with any closed, ruled-out, or in-flight family. MGUP is a novel axis for this programme.

---

## PR Elimination Log

Full scan of 230 PRs on advisor branch `auto-nanogpt-1gpu-r3`:

- Keyword search: "MGUP", "momentum-gradient alignment", "alignment update policy", "cosine(m", "lr_high", "lr_low", "alignment score", "per-parameter lr", "per-param lr" — **ZERO matching PRs found**
- Keyword search: "schedule-free body" — PR #265 (CLOSED)
- Keyword search: "MARS body" — PR #911 (CLOSED)
- Keyword search: "state reset cooldown" — PRs #636, #616 (CLOSED)
- Keyword search: "SOAP body", "shampoo body" — PRs #54, #700 (CLOSED)
- Keyword search: "modular norm", "bernstein norm" — ZERO matching PRs
- Keyword search: "polyak step", "SPS body" — ZERO matching PRs

MGUP has never been tried in any form in this programme.

---

## 3-Arm Experiment Design

**Total wall-clock budget:** ~5.5h on 1×H100 (3 arms × ~105 min each at 3325 steps)

### ARM 1 — CTRL

Exact baseline MuonH-SI configuration. No MGUP. LINEAR cooldown schedule as in H133 (PR #1097, baseline 3.26547).

```
--optimizer muonh_si
--lr 0.003
--cooldown_type linear
--use_agc true
--agc_clip_val 0.05
```

### ARM 2 — MGUP-50-moderate

MGUP applied to body parameter group only. 50/50 split, moderate lr differential.

```
--optimizer muonh_si
--lr 0.003
--cooldown_type linear
--use_agc true
--agc_clip_val 0.05
--use_mgup true              # new flag
--mgup_k 0.50                # top-50% get lr_high
--mgup_alpha 0.5             # lr_high = lr * (1 + 0.5) = 1.5 * lr
--mgup_beta 0.5              # lr_low = lr * 0.5
```

Expected behavior: mild differentiation; well-aligned body params maintain ~1.5× effective step during cooldown; misaligned params suppressed to 0.5×.

### ARM 3 — MGUP-25-aggressive

Top-25% only get high lr; stronger asymmetry.

```
--optimizer muonh_si
--lr 0.003
--cooldown_type linear
--use_agc true
--agc_clip_val 0.05
--use_mgup true
--mgup_k 0.25                # top-25% only get lr_high
--mgup_alpha 1.0             # lr_high = lr * 2.0
--mgup_beta 0.75             # lr_low = lr * 0.75 (light suppression of rest)
```

Expected behavior: more aggressive focusing of update budget on most useful params; may show sharper cooldown loss curve.

---

## Implementation Sketch (~50 LoC)

The following is a conceptual sketch of where and how to add MGUP inside `train_gpt_simple.py`. The student should adapt to the actual MuonH optimizer class structure.

```python
# Inside MuonH optimizer step(), after NS5 whitening produces `update`:

if self.use_mgup and self.state[p].get('momentum_buffer') is not None:
    m = self.state[p]['momentum_buffer']   # EMA momentum buffer (already exists)
    g = grad                                # current gradient

    # Flatten for cosine computation
    m_flat = m.view(-1).float()
    g_flat = g.view(-1).float()

    # Per-element cosine alignment (row-wise for matrices is optional;
    # paper uses scalar per-parameter; simplest: one score per param tensor)
    cos_sim = F.cosine_similarity(m_flat.unsqueeze(0), g_flat.unsqueeze(0)).item()

    # Assign step-size scalar
    if cos_sim >= self.mgup_threshold:      # threshold = percentile computed across group
        step_scale = 1.0 + self.mgup_alpha
    else:
        step_scale = self.mgup_beta

    update = update * step_scale

# Continue with update application as normal
p.data.add_(update, alpha=-lr)
```

**Note:** The percentile threshold (mgup_k) should be computed per-step across ALL body parameters (not per-tensor), to maintain the intended top-k% semantics. Store per-tensor scores in a list, compute np.percentile, then apply. This adds ~5 LoC to the body parameter loop.

**LoC breakdown:**
- Alignment score computation per tensor: 8 LoC
- Collect scores across body group, compute threshold: 8 LoC
- Step-scale assignment and application: 10 LoC
- ArgParse flags (use_mgup, mgup_k, mgup_alpha, mgup_beta): 12 LoC
- Hyperparameter passing to optimizer init: 5 LoC
- W&B logging (mgup_step_scale histogram): 7 LoC
- **Total: ~50 LoC**

---

## Expected Telemetry Signatures

Log these W&B metrics to validate the mechanism is working:

1. `body_mgup_high_frac` — fraction of body params receiving lr_high each step. Should be ~k (e.g., 0.50 for ARM 2). If it drifts to 0 or 1, the cosine score distribution has collapsed.
2. `body_mgup_mean_cos` — mean cosine alignment across all body params per step. Should be high mid-training, may drop during cooldown — this is the signal MGUP is acting on.
3. `body_grad_norm_effective` — norm of (update × step_scale) before application. Should plateau longer into cooldown in MGUP arms vs CTRL.
4. `val/loss` gap at step 2500 vs step 3325 — the erosion gap. Target: narrow from ~0.030 (CTRL) to <0.015 (MGUP arms).

**Discriminating prediction:** If MGUP addresses the erosion mechanism, `body_mgup_mean_cos` should show a mid-training peak followed by decline during cooldown (confirming the alignment signal is informative). If `body_mgup_mean_cos` stays uniformly high or low throughout training, MGUP's premise is wrong for this regime and we should close the hypothesis.

---

## Win Threshold

- **Benchmark pass:** val/loss < 3.28 at 3325 steps (already met by baseline)
- **Programme baseline:** val/loss 3.26547 (PR #1097, H133 LINEAR cooldown, fern)
- **WIN threshold (statistical rule):** val/loss < 3.26547 − 0.008 = **3.25747** (n=1 arm, need (3.28−μ)·√1 ≥ 0.004 → μ < 3.276 for benchmark pass; beat baseline by stated 0.008 margin)
- **IMPROVEMENT threshold (merge):** val/loss < 3.26547 — any improvement merges

---

## Research State Context

**Current best explanation for plateau:** The 7-axis erosion pattern is real and structural. The body mechanism creates genuine mid-training advantage (+0.025–0.035 val/loss) that LINEAR cooldown uniformly destroys. No attempt to modify the cooldown shape (H133-SQRT), the LR endpoint (H143), the EMA coefficient (H147), or weight-averaging (H139/H146) has broken this pattern. The hypothesis is that uniform LR reduction is the structural cause — MGUP is the first attempt to introduce non-uniform, signal-conditioned step-size reduction as a countermeasure.

**Ruled-out axes (do not re-test):**
- Cooldown shape (linear vs sqrt vs cosine): H133 evidence
- µ endpoint: H143 bilateral NULL
- β1 terminal schedule: H147 bilateral NULL
- Weight lookahead on body: H139+H146 bilateral SEVERE NEG
- Schedule-Free for body: PR #265 CLOSED
- MARS for body: PR #911 CLOSED
- SOAP/Shampoo: PRs #54, #700 CLOSED

**Open uncertainties:**
1. Does the per-tensor cosine score have enough variance during cooldown to be informative, or do all body params lose alignment simultaneously?
2. Is the asymmetry ratio (α/β) sensitive? Paper suggests k robustness but does not explicitly test α/β sensitivity on Muon variants.
3. Does MGUP interact with AGC (which already does gradient-norm-based scaling)? May be complementary (AGC = norm-based; MGUP = direction-based) or may partially overlap.

**Stop condition:** Close if ARM 2 and ARM 3 both show val/loss > 3.270 at step 3325, or if `body_mgup_mean_cos` shows no variation throughout training (alignment signal is flat → premise is wrong).

---

## Confidence Assessment

**Mechanistic grounding:** Strong — MGUP-Muon tested on LLM pretraining in original paper; mechanism directly targets identified bottleneck (non-uniform cooldown response needed).

**Orthogonality:** Verified — zero prior programme PRs match MGUP mechanism; all 7 closed families confirmed non-overlapping.

**External evidence:** NeurIPS 2025 Spotlight — peer-reviewed, high-quality venue; explicit MGUP-Muon variant tested.

**Uncertainty:** The exact form of the cosine score distribution during MuonH-SI training under the specific FineWeb distribution is unknown. The erosion mechanism is documented, but MGUP's ability to counteract it at this scale and setting is speculative — this is a hypothesis, not a confirmed win.

**Overall confidence:** Moderate-high. Best available orthogonal option given exhausted prior families.
