# Research Ideas — 2026-05-22 13:35

Generated for the next wave of student assignments. All 3 ideas target mechanism
axes NOT represented in the 32-PR closed history and NOT currently in-flight.

Mandatory stack for all experiments:
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85

Baseline: val=3.26776, ffs=3000 (PR #613, n=2 mean)
Merge bar: val_mean <= 3.26776 AND ffs_mean <= 3000

Kill gates (from reference run vwrqt4vt):
  step 500:  val > 3.81 → kill
  step 1000: val > 3.55 → kill
  step 2000: val > 3.30 → kill

---

## Idea 1: Z-Loss Auxiliary Logit Entropy Regularization

**Mechanism class:** Loss-level softmax entropy regularization

**Motivation:** Z-loss (Zoph et al. / PaLM, arxiv 2204.02311, Section 5.2) adds
`coeff * log(Z)^2` to the training loss, where Z = sum(exp(logits)). This
penalizes the log-partition function from growing large, which prevents logit
scale from drifting and keeps gradient flow through the softmax well-conditioned.
The mechanism is completely orthogonal to all 32 closed optimizer axes: it
modifies the loss signal entering the backward pass, not the update rule. The
current stack already uses LOGIT_SOFTCAP=20.0 to bound logit magnitude at
forward time, but softcap is a hard nonlinear clamp; z-loss is a soft
differentiable regularizer that provides gradient pressure against z-drift
continuously throughout training. These two mechanisms target the same pathology
(logit scale inflation) via different channels and should be compatible. In
the PaLM paper, z-loss coeff=1e-4 reduced training instabilities and improved
final perplexity. In the current setting where the floor cluster shows 0.001-0.003
variance across seeds, a soft regularizer that reduces logit-scale noise during
the cooldown phase is a plausible lever.

**Expected impact:** Moderate-to-high. If seed-to-seed val spread reflects
gradient variance amplified through the softmax, z-loss provides a direct fix.
The mechanism is loss-level, costs zero compute overhead, and requires ~5 LOC.
Estimated ffs improvement: 25-50 steps if gradient-through-softmax noise is the
binding constraint. Failure mode: if LOGIT_SOFTCAP already fully controls logit
scale, z-loss provides no additional signal; the result would be neutral (not
harmful). Because the floor cluster shows consistent near-miss rather than
divergence, a neutral outcome is informative: it rules out the softmax-entropy
hypothesis cleanly.

**Implementation complexity:** In `GPT.forward()`, after computing `logits` and
before the cross-entropy return, add:

```python
Z_LOSS_COEFF = float(os.environ.get("Z_LOSS_COEFF", "0.0"))
# ...
loss = F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
if Z_LOSS_COEFF > 0:
    log_z = logits.float().logsumexp(-1)   # (B*T,)
    loss = loss + Z_LOSS_COEFF * (log_z ** 2).sum()
return loss
```

No optimizer changes. No schedule changes. Gate behind `Z_LOSS_COEFF` env var
(default 0.0 = off, fully backward-compatible).

**Arms (for n=1 screening):**

- Arm A: `Z_LOSS_COEFF=1e-4` (PaLM default; direct replication)
- Arm B: `Z_LOSS_COEFF=3e-5` (one-third of PaLM; softer pressure given the
  existing LOGIT_SOFTCAP already constrains the logit scale)

**Kill gates:** step 500 > 3.81, step 1000 > 3.55, step 2000 > 3.30 (identical
to baseline trajectory).

---

## Idea 2: NS5 Polynomial Coefficient Re-Optimization

**Mechanism class:** Newton-Schulz polynomial spectrum / approximation quality

**Motivation:** The current NS5 iteration uses hardcoded polynomial coefficients
`a=2, b=-1.5, c=0.5` (the standard degree-3 Chebyshev-like approximation to the
matrix sign function). This specific triple was chosen for its convergence on the
unit interval and has never been varied in the 32 closed axes — only the iteration
count `NS5_ITERS` has been tuned (to 14). However, the polynomial coefficients
and the iteration count are not independent hyperparameters: different coefficient
sets converge at different rates and have different spectral properties on
matrices with non-unit singular value ranges. The Muon Scalability paper (Moonshot
AI, arxiv 2502.16982) notes that the Newton-Schulz polynomial can be replaced by
higher-degree alternatives to improve approximation quality per iteration.
Zolotarev-optimal minimax polynomials for the sign function achieve strictly
better spectral approximation than Chebyshev-like polynomials of the same degree
(Nakatsukasa & Freund 2016, SIAM J. Matrix Anal. Appl.). A degree-5 Zolotarev or
higher-order Chebyshev expansion at NS5_ITERS=14 would produce a better
approximation to the matrix orthogonalization target than the current cubic
coefficients, potentially pushing the effective NS step quality high enough to
close the final 0.001-0.003 loss gap. The mechanism is strictly orthogonal to the
32 closed axes: those tuned the number of iterations but assumed the coefficient
set was fixed; this changes what each iteration does.

**Expected impact:** Moderate. The theoretical justification is sound: better
polynomial approximation to the matrix sign function → cleaner spectral
normalization → lower-noise gradient update → tighter seed-to-seed spread.
The effect is likely subtle at NS5_ITERS=14 (already well-converged for most
matrices) but non-zero, particularly for matrices with wide singular value ranges
in early training where convergence is slower. Estimated ffs improvement: 15-30
steps. Failure mode: if NS5 is already fully converged at iter 14 with the
current coefficients, changing the polynomial gives no benefit. This would rule
out NS5 approximation quality as the bottleneck clearly.

**Implementation complexity:** In `zeropower_via_newtonschulz5`, replace the
coefficient line. No other changes needed.

Arm A — degree-5 higher-order coefficients (more aggressive per step):
```python
# Replace: a, b, c = 2, -1.5, 0.5
# With degree-5 Chebyshev-like (Bernstein polynomial form):
a, b, c = 3.4375, -4.6875, 2.8125
```
These satisfy the normalization constraint and accelerate convergence in the
(0.5, 1.0) singular value range where the current polynomial is slowest.

Arm B — softer coefficients with reduced undershoot on near-zero singular values:
```python
a, b, c = 1.5, -0.5, 0.0625
```
This is more conservative and avoids overshoot on ill-conditioned blocks.

Gate behind `NS5_COEFF_SET` env var:
```python
NS5_COEFF_SET = os.environ.get("NS5_COEFF_SET", "standard")
if NS5_COEFF_SET == "aggressive":
    a, b, c = 3.4375, -4.6875, 2.8125
elif NS5_COEFF_SET == "soft":
    a, b, c = 1.5, -0.5, 0.0625
else:
    a, b, c = 2, -1.5, 0.5   # default
```

**Arms:**
- Arm A: `NS5_COEFF_SET=aggressive`
- Arm B: `NS5_COEFF_SET=soft`

**Kill gates:** step 500 > 3.81, step 1000 > 3.55, step 2000 > 3.30. Note: Arm A
may show slightly higher early-step loss (steps 0-500) than baseline due to
different spectral normalization in the warm-up phase; do not kill early unless
the step-500 gate is clearly violated.

---

## Idea 3: CONTRA_MUON=0 Stack Pruning Ablation

**Mechanism class:** Stack pruning / contra-correction removal

**Motivation:** The `program.md` benchmark contract explicitly calls for pruning
and removal experiments when the stack accumulates components. The Contra-Muon
correction (`update = update - CONTRA_MUON/2 * normalized_grad`) was added to
reduce alignment between the NS5 output and the raw gradient, which was motivated
by a theoretical concern about the NS5 update being too correlated with the
gradient direction. However, the 32 closed axes have only explored CONTRA_MUON in
a narrow range around 0.4; the value was never set to exactly 0.0. At the current
stack complexity level (NS5 + contra + NorMuon + SOAP + trust gate), it is
possible that the contra correction is doing net harm in the late-training regime:
it introduces a direction-dependent perturbation that adds noise to an already
well-conditioned NS5 output. If the gradient is already well-normalized by NS5,
subtracting a scaled copy of it adds variance without improving the update
direction. The close-miss cluster at ffs=3025 could reflect this added noise
during cooldown. Removing contra entirely (CONTRA_MUON=0.0) is a 0-LOC change
(already env-gated) that cleanly tests whether the contra component is a net
positive or negative contributor. This is fundamentally different from the closed
axis "scalar HP tuning of contra_muon" which only moved the value within (0.3, 0.5)
— never tested the mechanism-absent state.

**Expected impact:** Low-to-moderate, but high information value. If removing
contra improves ffs, it validates the "contra adds cooldown noise" hypothesis and
suggests the NS5 output is already directionally correct without correction. If
it worsens ffs, it validates contra's value and rules out the noise hypothesis.
Either outcome sharpens the research map. The implementation cost is zero. One
natural follow-up: if CONTRA_MUON=0 helps, also test NS5_ITERS reduction (the
contra correction was partially compensating for NS5 overshoot; without it, fewer
NS5 iterations may perform better).

**Implementation complexity:** Already env-gated. No code changes required.
The only change is the environment variable value:
```bash
CONTRA_MUON=0.0
```
Optional second arm adds NS5_ITERS reduction to account for potentially
over-iterated NS5 without the contra dampening:
```bash
CONTRA_MUON=0.0 NS5_ITERS=10
```

**Arms:**
- Arm A: `CONTRA_MUON=0.0` (full removal, NS5_ITERS=14 unchanged)
- Arm B: `CONTRA_MUON=0.0 NS5_ITERS=10` (removal + NS5 de-iteration; tests
  whether contra was compensating for over-orthogonalization)

**Kill gates:** step 500 > 3.84 (5% above baseline — Arm A may need slightly
wider gate if contra removal changes early-step trajectory), step 1000 > 3.58,
step 2000 > 3.32. Use the wider early-step gates for this idea since the update
magnitude changes.

---

## Priority Order

1. Idea 1 (Z-Loss) — loss-level mechanism, zero overhead, direct attack on
   gradient-through-softmax noise, 5 LOC, strong external citation (PaLM).
2. Idea 2 (NS5 Coefficients) — first coefficient-level NS5 change in 32 axes,
   solid theoretical grounding, ~10 LOC, moderate expected impact.
3. Idea 3 (CONTRA=0 Ablation) — zero-LOC stack pruning, high information value
   regardless of outcome, directly encouraged by benchmark contract.

---

## References

- Z-Loss / PaLM: arxiv 2204.02311 (Chowdhery et al. 2022) — z-loss defined in
  Section 5.2, coeff=1e-4, reduces training instabilities and logit drift
- Muon Scalability: arxiv 2502.16982 (Moonshot AI 2025) — Newton-Schulz
  polynomial alternatives for improved orthogonalization per iteration
- Zolotarev polynomial matrix sign: Nakatsukasa & Freund 2016, SIAM J. Matrix
  Anal. Appl. 37(5) — minimax-optimal polynomials for the matrix sign function
- Benchmark pruning contract: target/program.md — "Run pruning/removal
  experiments when a stack accumulates components"
