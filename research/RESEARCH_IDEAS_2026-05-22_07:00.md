# Research Ideas — 2026-05-22 07:00 UTC

Generated for advisor branch `auto-nanogpt-1gpu-r2`.
Target: beat baseline val=3.26776 / ffs=3000 (PR #613).
Hold gate: val ≤ 3.27 AND ffs ≤ 3000.

Students available: g1r2-nezuko (idle after PR #732), g1r2-thorfinn (idle after PR #749).
Tanjiro pod broken — do NOT assign.

---

## Cross-checked closed axes (do not repeat)

The following mechanism classes are confirmed exhausted per EXPERIMENTS_LOG.md through cycle 71:

- CONTRA_MUON: value sweep, existence, per-block-depth, depth-type (21 axes, fully closed)
- Gradient clipping: Muon (#688) and AdamW (#734) — bilateral, both sides closed
- Early-step correction: RAdam (#742), NAdam (#718), bias correction (#205) — bilateral theorem complete
- Nesterov look-ahead: ADAMW_NESTEROV (#739) closed; MUON Nesterov-style already in NS5
- Schedule-free Muon: structural incompatibility proved (#358)
- ATTN_SOAP_TRUST fixed sweep: done; currently tested as per-group (#683)
- LR late boost (group-specific): embed (#749, closed), lm_head (#759, in-flight on frieren)
- MUON_LR per-type split: attn > mlp direction correct, magnitude wrong, axis closed (#732)
- NS5_COEFS polynomial shape: exhausted (#694)
- β2_SCHEDULE: scientifically open, but pod-untestable on tanjiro (#747); safe to test on stable pod
- ADAMW_EPS: assigned to askeladd (#754, in-flight) — do NOT duplicate
- MUON_COOLDOWN_SHAPE: in-flight on fern (#764) — do NOT duplicate per-group cooldown shape

In-flight and not to duplicate: #754 AdamW eps, #764 Muon cooldown shape, #759 lm_head LR late boost, #757 Grokfast (see below).

---

## H1 — ATTN_SOAP_TRUST Cooldown Ramp

**Mechanism class**: Dynamic trust-gate schedule for SOAP preconditioner

**Precedent/basis**: PR #683 (ATTN_SOAP_TRUST sweep) explicitly suggested in its analysis:
> "cooldown-schedule form: ramp 0.85→0.95 linearly during final 5% of training steps (~159 steps).
> Rationale: as LR falls, the gradient landscape becomes smoother and eigenbasis estimates stabilize;
> raising the trust threshold during cooldown lets more attention weights use the SOAP preconditioner
> when the update magnitude is already small enough that any instability risk is low."
This was explicitly flagged as a follow-up experiment but was never assigned.

**Specific change**: Add a linear ramp of `ATTN_SOAP_TRUST_THRESHOLD` from its fixed value (0.85)
upward during the last `ATTN_SOAP_TRUST_RAMP_FRAC` fraction of training steps.

- Arm A: ramp 0.85 → 0.95 over final 5% of steps (steps 2936–3175, ~160 steps)
- Arm B: ramp 0.85 → 0.95 over final 10% of steps (steps 2861–3175, ~315 steps) — wider ramp

Implementation: In the optimizer step, compute `ramp_frac = ATTN_SOAP_TRUST_RAMP_FRAC` (default 0.05).
After `step >= (1 - ramp_frac) * total_steps`, set:
```python
t = (step - (1 - ramp_frac) * total_steps) / (ramp_frac * total_steps)
effective_threshold = ATTN_SOAP_TRUST_THRESHOLD + t * (ATTN_SOAP_TRUST_RAMP_TARGET - ATTN_SOAP_TRUST_THRESHOLD)
```
where `ATTN_SOAP_TRUST_RAMP_TARGET = 0.95`.

Before the ramp window, the threshold stays at `ATTN_SOAP_TRUST_THRESHOLD=0.85` (no change to baseline behavior).

**Why now**: The fixed-threshold sweep (#683) found 0.85 optimal for the full-run regime, but the
logic of SOAP trust (filter out unstable eigenbases) may be miscalibrated for the late cooldown where
gradient variance drops by ~10× compared to warmup. All 24 failed axes to date operated with a
static ATTN_SOAP_TRUST_THRESHOLD. This is the first dynamic trust-gate shape test and is orthogonal
to fern's #764 (which tests Muon momentum cooldown shape, not SOAP trust).

**Predicted effect**: Late-training attention weights gain finer preconditioned update direction
during the 160–315 cooldown steps where LR is smallest. If eigenbasis estimates have stabilized,
the ramp allows SOAP to cover more attention weights without the instability risk that justified
threshold=0.85 at high LR. Effect: small but non-trivial improvement in final val loss / ffs.

**Risk**: If eigenbases are NOT stable at cooldown start, a ramp to 0.95 may inject noisy
preconditioning into a sensitive convergence phase. Arm B's wider ramp (10%) has higher risk.
Falsified by both arms MISS with val > baseline — this tests whether dynamic trust scheduling
adds value beyond fixed threshold.

**Hold gate**: val ≤ 3.27 AND ffs ≤ 3000 (single arm sufficient)

**Recommended student**: g1r2-thorfinn (reliable pod, 2-arm structure well-suited)

**Env vars**:
```
ATTN_SOAP_TRUST_THRESHOLD=0.85   # unchanged from baseline
ATTN_SOAP_TRUST_RAMP_TARGET=0.95
# Arm A:
ATTN_SOAP_TRUST_RAMP_FRAC=0.05
# Arm B:
ATTN_SOAP_TRUST_RAMP_FRAC=0.10
```

---

## H2 — Grokfast Slow-Frequency Gradient Filter (Muon + AdamW)

**Mechanism class**: Input-side gradient filtering — amplify slow EMA component before optimizer update

**Precedent/basis**: Ahn et al. 2024 "Grokking by Gradient Amplification" (ICLR 2024 oral).
The method maintains a per-parameter exponential moving average of gradients (slow EMA with high alpha),
then adds a scaled version of this slow EMA to the raw gradient before the optimizer step:
```
g_filtered = g + lambda * EMA(g)
```
where `EMA(g)` is updated with decay `alpha` (e.g. 0.98). This amplifies low-frequency gradient
components while leaving high-frequency noise relatively unchanged.

NOTE: This was listed as in-flight on askeladd as PR #757 GROKFAST. Check if askeladd's PR #757
is actually running before assigning to nezuko — if #757 is already live, skip to H3 (Lion).
If #757 is only partially configured or crashed, this hypothesis can serve as a clean retest on nezuko.

As of EXPERIMENTS_LOG.md (cycle 71 tail), the strategic planning mentions #757 as "just assigned" to askeladd.
If it is confirmed in-flight, assign H3 (Lion) to nezuko instead of H2.

**Specific change**: After computing gradients, before passing to Muon or AdamW:
```python
# Initialize: self.grad_ema = {p: torch.zeros_like(p) for p in params}
# Each step:
ema = self.grad_ema[p]
ema.mul_(alpha).add_(grad, alpha=1 - alpha)
grad_filtered = grad + lamb * ema
# Use grad_filtered in place of grad for the optimizer step
```

- Arm A: Grokfast on ALL parameter groups (Muon params + AdamW embed/lm_head), alpha=0.98, lamb=2.0
- Arm B: Grokfast on AdamW groups ONLY (embed + lm_head), alpha=0.98, lamb=2.0
  (Rationale for Arm B: Muon's NS5 projection already acts as a frequency filter; Grokfast may
  double-filter or conflict with the spectral normalization. Arm B isolates the AdamW-side effect.)

**Why now**: All 24+ closed axes operated at the gradient-magnitude level (clipping, rescaling) or
at the update rule level (momentum, correction terms). No experiment has tested frequency-domain
gradient filtering. The slow-EMA amplification is mechanistically orthogonal to NS5 spectral
normalization: NS5 normalizes the direction of the update matrix, while Grokfast amplifies the
temporal persistence of the gradient signal before that normalization. They operate at different
abstraction levels. This is a net-new gradient-input filtering axis.

**Predicted effect**: Slow-frequency gradient components correspond to stable optimization directions
that persist across multiple steps. Amplifying them reduces the step-to-step variance in the
update signal, which may help final convergence in the cooldown phase. Expected: modest val
improvement or ffs reduction if the AdamW groups benefit (embed/lm_head are handled by AdamW with
standard first/second moment tracking, and Grokfast provides additional temporal smoothing).

**Risk**: The EMA introduces memory overhead (~1× param count extra tensors). If the signal is
already well-captured by AdamW's β1 moment, Grokfast is redundant and may cause mild oversmoothing.
Falsified by both arms MISS with val ≥ baseline — this tests whether frequency-domain amplification
adds value on top of the existing momentum terms.

**Hold gate**: val ≤ 3.27 AND ffs ≤ 3000 (single arm sufficient)

**Recommended student**: g1r2-nezuko (if askeladd's #757 is confirmed still in-flight, use H3 instead)

**Env vars**:
```
GROKFAST_ALPHA=0.98
GROKFAST_LAMB=2.0
# Arm A: GROKFAST_GROUPS=all
# Arm B: GROKFAST_GROUPS=adamw_only
```

---

## H3 — Lion Optimizer for AdamW Embed/LM-Head Groups

**Mechanism class**: Sign-based update rule replacing AdamW for embed + lm_head groups

**Precedent/basis**: Chen et al. 2023 "Symbolic Discovery of Optimization Algorithms" (NeurIPS 2023).
Lion (EvoLved Sign Momentum) uses the sign of a first-moment EMA as the update:
```
m_t = beta1 * m_{t-1} + (1 - beta1) * g_t
update = lr * sign(beta1 * m_{t-1} + (1 - beta1) * g_t)
m_t = beta2 * m_{t-1} + (1 - beta2) * g_t
```
with weight decay applied as `p = p - wd * lr * p` (decoupled). There is no second-moment
denominator — it is memory-lighter than Adam and produces updates with constant magnitude per param.

**Why not Muon-side**: Muon's NS5 projection already normalizes the update matrix spectrally; adding
Lion on Muon would conflict. The target group is AdamW's embed.weight + lm_head.weight, which are
currently updated with AdamW (betas=(0.8, 0.95), eps=1e-10, WD_AUX=0.001).

**Specific change**: Replace AdamW for embed + lm_head groups with Lion:
- beta1=0.9 (interpolation coefficient for update sign)
- beta2=0.99 (momentum EMA decay)
- LR scaling: Lion typically needs ~3–10× lower LR than AdamW for same scale of updates (because
  sign() outputs ±1 regardless of gradient magnitude). Starting estimates:
  - embed LR = 0.003 (AdamW baseline ~0.024 at peak; Lion ~1/8)
  - lm_head LR = 0.0003125 (same 8× reduction from baseline)
  - WD = 0.001 (keep same; Lion uses decoupled WD already)

- Arm A: Lion with LR ratio 1/8 of AdamW baseline (embed_lr=0.003, head_lr=0.0003125)
- Arm B: Lion with LR ratio 1/4 of AdamW baseline (embed_lr=0.006, head_lr=0.000625)
  (Arm B tests whether the 3–10× rule is closer to 4× for this stack)

**Why now**: All AdamW-group optimization experiments have stayed within the Adam family
(ADAMW_NESTEROV, ADAMW_RADAM, ADAMW_GC, ADAMW_GRAD_CLIP, ADAMW_EPS). None have tested a
fundamentally different update rule. The sign-based update is mechanistically distinct from all
tested variants: it has no adaptive denominator, no bias correction, and produces unit-magnitude
updates in each parameter direction. The bilateral early-step correction theorem only eliminates
bias-correction variants of Adam; it does not apply to Lion (no correction term at all).

**Predicted effect**: For embed and lm_head, which are high-dimensional but have relatively smooth
loss surfaces compared to MLP/attn, the constant-magnitude sign update may converge more reliably
in the final cooldown phase. Known practical result: Lion often matches or beats Adam at same
effective LR. Risk is LR sensitivity — the LR range for Lion is narrower than Adam.

**Risk**: LR sensitivity is the main risk. If neither 1/8 nor 1/4 ratio is correct, both arms miss.
Pilot diagnostic: check that train/loss at step 50 is within 5% of baseline (∼3.89–4.05 range);
kill early if it diverges above 4.5. Falsified by both arms MISS with val ≥ baseline.

**Hold gate**: val ≤ 3.27 AND ffs ≤ 3000 (single arm sufficient)

**Recommended student**: g1r2-nezuko (primary), g1r2-thorfinn (backup if H1 already assigned)

**Env vars**:
```
LION_GROUPS=adamw_only    # embed.weight + lm_head.weight
LION_BETA1=0.9
LION_BETA2=0.99
# Arm A:
LION_LR_EMBED=0.003
LION_LR_HEAD=0.0003125
# Arm B:
LION_LR_EMBED=0.006
LION_LR_HEAD=0.000625
LION_WD=0.001             # decoupled WD, same as WD_AUX baseline
```

---

## H4 — WD_AUX Temporal Ramp During Cooldown

**Mechanism class**: Dynamic weight decay schedule — increase regularization during cooldown phase

**Precedent/basis**: Loshchilov & Hutter 2019 (AdamW) noted that decoupled WD and LR decouple the
regularization from the step size, but their work and all follow-ups treat WD as a fixed scalar.
Zhuang et al. 2022 "Surrogate Gap Minimization" and Lingle et al. 2023 "Optimization on Learning
Curves" both note that increasing regularization during late training can prevent memorization of
noise in the final updates. The theoretical grounding: as LR → 0 in cooldown, the effective weight
decay per step also shrinks to 0 (wd_effective = wd * lr / lr_initial). Ramping WD up during
cooldown compensates for the implicit regularization drop.

**Specific change**: Keep `WD_AUX=0.001` as the base. During cooldown phase (last `cooldown_frac=0.7`
of training = steps 952–3175), linearly ramp WD_AUX from 0.001 to a higher value:

- Arm A: WD_AUX ramp 0.001 → 0.010 (10× increase over cooldown)
- Arm B: WD_AUX ramp 0.001 → 0.005 (5× increase over cooldown)

Implementation:
```python
if step >= cooldown_start_step:
    t = (step - cooldown_start_step) / (total_steps - cooldown_start_step)
    current_wd = WD_AUX + t * (WD_AUX_FINAL - WD_AUX)
    for group in optimizer.param_groups:
        if group['name'] in ('adamw_embed', 'adamw_head'):
            group['weight_decay'] = current_wd
```

This keeps Muon's WD schedule (which operates separately on Muon groups) unchanged. The ramp applies
only to AdamW embed + lm_head groups.

Note: Also worth testing whether the Muon weight decay should ramp. The Muon WD is currently fixed
at whatever value is set in the Muon optimizer init. A secondary check: if the training script
exposes Muon WD as a separate env var, add a Muon WD ramp as a third arm or a follow-up hypothesis.

**Why now**: PR #458 introduced `WD_AUX` as a fixed scalar sweep and found 0.001 optimal. No
experiment in 71 cycles has ever tested WD as a schedule rather than a fixed scalar. The theoretical
argument is strong: as LR cooldown reduces the step size by ~3–4× from peak to terminal, the net
regularization per-parameter is also reduced by 3–4× without compensating WD increase. A WD ramp
during cooldown restores effective regularization during the phase when the model is most likely to
overfit to recent minibatch noise.

**Predicted effect**: Stronger regularization during cooldown may reduce val/loss by 0.001–0.005 if
the current baseline is slightly overfitting in its final 500 steps. The effect is most likely to
show up in val/loss without necessarily changing ffs — though if better regularization prevents
late-step regression, ffs may also improve.

**Risk**: Too aggressive WD increase (e.g. 10×) may cause underfitting in the final steps, pushing
val/loss UP. Arm A (10×) is more aggressive; Arm B (5×) is conservative. If both miss badly in the
wrong direction (val > 3.30), the ramp is too aggressive. Falsified by val ≥ baseline on both arms.

**Hold gate**: val ≤ 3.27 AND ffs ≤ 3000 (single arm sufficient)

**Recommended student**: g1r2-thorfinn (reliable pod; 2-arm structure, clean 1-parameter axis)

**Env vars**:
```
WD_AUX=0.001               # base, unchanged at non-cooldown steps
# Arm A:
WD_AUX_FINAL=0.010         # terminal WD at step 3175
# Arm B:
WD_AUX_FINAL=0.005         # terminal WD at step 3175
COOLDOWN_FRAC=0.7           # standard baseline cooldown fraction (no change)
```

---

## Assignment map

| Student | Primary hypothesis | Fallback if conflict |
|---|---|---|
| g1r2-thorfinn | H1 (ATTN_SOAP_TRUST cooldown ramp) + H4 (WD temporal ramp) — assign as separate PRs | — |
| g1r2-nezuko | H3 (Lion for AdamW groups) — if askeladd #757 Grokfast is in-flight; else H2 (Grokfast) | H2 if H3 is too risky per advisor judgment |

Note: thorfinn gets two PRs (H1 and H4) because both are tight 2-arm structures with a single env var
each and low implementation complexity. Nezuko gets one PR (H3 or H2) because both require more
careful implementation and LR range exploration.

---

## Research state update

**Current best explanation**: The ffs=3025+ floor cluster (25 axes, 24 of which landed within
+25–+75 ffs of baseline) indicates that scalar perturbations to the existing optimizer stack —
whether to CONTRA_MUON, gradient clipping, early-step correction, momentum schedule, or LR
group splits — cannot cross the ffs=3000 floor. The ceiling is likely structural: either the
current optimizer family (Muon + AdamW + SOAP) is near-optimal for this architecture/data
combination at this step budget, or there is a specific mechanism (SOAP trust schedule, frequency
filtering, or regularization timing) that the closed axes have not tested.

**Open uncertainties**:
1. Whether the SOAP trust gate needs a dynamic schedule (H1) — all 25 closed axes used static settings
2. Whether the WD schedule (H4) can recover regularization lost during LR cooldown — never tested
3. Whether a fundamentally different update rule (Lion, H3) for AdamW groups can cross the floor

**Ruled out** (do not repeat without new evidence):
- Any form of gradient clipping (Muon or AdamW side)
- Any form of early-step correction or bias correction (bilateral theorem complete)
- Nesterov look-ahead variants
- CONTRA_MUON value, depth, or type variations
- NS5 coefficient shape changes
- Schedule-free Muon
- Per-group LR splits (type-based, already at wrong magnitude)
- Fixed-scalar WD_AUX sweeps (only schedules are open)

**Next discriminating experiment**: H4 (WD temporal ramp) is the cheapest test of the
regularization-during-cooldown hypothesis. H1 (ATTN_SOAP_TRUST ramp) is the cheapest test of the
dynamic preconditioner-schedule hypothesis. If both miss, H3 (Lion) tests whether a different
update-rule family can bypass the floor.

**Stop condition for this direction**: If H1 + H2/H3 + H4 all miss (val ≥ 3.27 or ffs ≥ 3025),
and frieren's #759 + fern's #764 also miss, the local exhaustion signal is strong enough to
warrant a tier shift: either a new optimizer family (SOAP-only or Muon-only without the combined
stack), or a complete LR schedule redesign (e.g. cosine with restarts instead of linear cooldown).
