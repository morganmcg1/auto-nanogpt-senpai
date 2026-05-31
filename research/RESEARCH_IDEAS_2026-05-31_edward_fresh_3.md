# Fresh Research Ideas — 2026-05-31 (edward, session 3)

Generated after reviewing 76 R5 closures, 7 in-flight axes, and literature search
across SOAP preconditioner frequency, Shampoo eigenbasis staleness, Newton-Schulz
stabilization, SOAP beta2 scheduling, adaptive preconditioner update, and Muon+SOAP
cooldown dynamics.

---

## Candidate 1 (TOP PICK): PRECOND_FREQ Cooldown Schedule

**One-sentence:** Reduce SOAP eigenbasis update interval from 16 to ~4 during
early cooldown (steps 975–1625) where gradient directions shift fastest and
SOAP-attn contributes ~50% of total FFS gain, to keep the preconditioner fresh
during the most sensitive optimization phase.

**Mechanism:** PRECOND_FREQ=16 is a global constant that has never been scheduled
or ablated across all 76 R5 closures. During LR cooldown the gradient covariance
eigenstructure shifts rapidly (large LR → small LR regime change). A stale
eigenbasis during this window under-rotates the update, missing the effective
curvature. The fix is a phase-aware schedule: high frequency (low PRECOND_FREQ)
during early cooldown, reverting to base outside that window.

**Literature support:**
- "Purifying Shampoo" (Eschenhagen et al., NeurIPS 2025 spotlight): adaptive
  eigenbasis update criterion based on warm-started QR convergence — directly
  motivates phase-conditional update frequency.
- SOAP (Vyas et al., ICLR 2025): explicitly documents that less-frequent
  eigendecomposition leads to performance degradation worsening with the interval.
- SPlus (Frans et al., NeurIPS 2025): shows stale matrix-inverse during rapid LR
  changes causes divergence; proposes bounded instantaneous normalization as fix.

**Distinctness:** SOAP-attn phase-gating family (#818, #914, #1707, #1860) toggled
the `--soap_attn` flag (enabling/disabling SOAP on attention entirely) — orthogonal
to modifying PRECOND_FREQ (the eigenbasis update stride). None of the 7 in-flight
axes touch PRECOND_FREQ. This is a clean, unexplored axis.

**Risk:** Extra SOAP eigenbasis computations add ~3–4x overhead during the ~650-step
early-cooldown window (~10% of total training steps), adding ~6–8% total wall-clock.
Acceptable given FFS is the target metric (not wall-clock). If FFS gain ≥ 25 steps,
ROI is strongly positive.

---

## Candidate 2: SOAP_BETA2 Cooldown Schedule

**One-sentence:** Ramp SOAP_BETA2 from 0.90 to ~0.95–0.99 during cooldown to
lengthen the EMA window of the gradient covariance matrix as the learning rate
decays, providing more stable eigenbasis estimates.

**Mechanism:** SOAP_BETA2=0.90 is a hardcoded global constant never ablated or
scheduled. As LR decays, gradient magnitudes shrink and SNR of the covariance
estimate drops. A higher beta2 during cooldown would average over more recent
samples, reducing eigenbasis noise.

**Risk:** Interacts with PRECOND_FREQ. Should be tested independently. May
conflict with Candidate 1 if both are in flight simultaneously.

**Distinctness:** None of 76 closures or 7 in-flight axes touch SOAP_BETA2 scheduling.

---

## Candidate 3: Spectral Radius Monitoring for Adaptive NS Polish Quality

**One-sentence:** Track spectral radius of the NS-polished matrix per step and
adaptively increase ns_iter when spectral radius deviates from 1.0 beyond a
threshold, accepting higher compute only when the matrix is far from Stiefel.

**Mechanism:** NS5 (ns_iter=6) applies fixed polynomial iterations regardless of
how close the current gradient matrix is to the Stiefel manifold. If gradient
matrices during early training are far from orthogonal, more iterations help; if
already near-orthogonal, extra iterations waste compute. An adaptive criterion
would dynamically allocate more iterations where needed.

**Risk:** Adaptive NS iter family was CLOSED (PR #1834, compute-NEG). The failure
mode was the compute overhead dominated. This variant adds a monitoring step
rather than blindly increasing iterations — but the key question is whether the
monitoring overhead itself is prohibitive. Likely too close to the closed family
to be worth assigning.

**Verdict:** Deprioritize — too close to closed NS-iter adaptive family.

---

## Candidate 4: KL-SOAP Preconditioner Reformulation

**One-sentence:** Replace SOAP's Euclidean gradient-covariance EMA with the KL-
divergence-motivated update from KL-Shampoo (Lin et al., ICLR 2026) for the
attention layers to get more principled eigenbasis estimates.

**Mechanism:** KL-Shampoo replaces the standard Kronecker-factor EMA with a
closed-form update derived from minimizing KL divergence between consecutive
Gaussian approximations of the posterior. Consistently outperforms SOAP in the
paper's experiments, especially on attention layers.

**Risk:** Requires non-trivial implementation changes to the SOAP block.
Implementation complexity is high. Possible to test on attention layers only
(where SOAP is already isolated via `--soap_attn`).

**Verdict:** High upside but high implementation complexity. Better suited to a
later wave after simpler hypotheses are exhausted.

---

## Candidate 5: Eigenbasis Warm Restart at Cooldown Entry

**One-sentence:** Force a full eigenbasis recompute (PRECOND_FREQ=1 for one step)
at the exact cooldown entry step to ensure the preconditioner starts cooldown
from a fresh state.

**Mechanism:** A lightweight version of Candidate 1. Instead of scheduling a
dense early-cooldown high-frequency window, perform a single forced recompute
at the cooldown boundary. This costs exactly one extra eigendecomposition and
directly addresses the "stale eigenbasis entering cooldown" failure mode.

**Risk:** Minimal — one-line change, negligible compute overhead. But effect may
be too small if the dominant issue is sustained staleness throughout cooldown
rather than just at the boundary.

**Verdict:** Can be combined with Candidate 1 (warm restart at cooldown + dense
early-cooldown schedule). Test Candidate 1 first; if it shows signal, this
ablation clarifies whether the boundary reset is sufficient.

---

## Summary Ranking

| Rank | Hypothesis | Expected FFS gain | Compute cost | Complexity |
|------|------------|------------------|--------------|------------|
| 1 | PRECOND_FREQ cooldown schedule | 15-40 steps | +6-8% wall-clock | Low |
| 2 | SOAP_BETA2 cooldown schedule | 5-20 steps | ~0 | Very low |
| 3 | Eigenbasis warm restart at cooldown | 3-10 steps | ~0 | Minimal |
| 4 | KL-SOAP reformulation | 20-50 steps | Medium | High |
| 5 | Adaptive NS iter (monitoring) | 0-10 steps | Low-medium | Medium |

**TOP PICK: Candidate 1 (PRECOND_FREQ cooldown schedule)**

References:
- Eschenhagen et al., "Purifying Shampoo", NeurIPS 2025 spotlight
- Vyas et al., "SOAP: Improving and Stabilizing Shampoo using Adam", ICLR 2025
- Frans, Levine, Abbeel, "SPlus: A Stable Whitening Optimizer", NeurIPS 2025
- Lin et al., "KL-Shampoo: A Principled Second-Order Optimizer", ICLR 2026
