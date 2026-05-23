# Research Ideas — 2026-05-23 00:45

Generated for 2 idle students. Both ideas target mechanism axes NOT represented
in any of the 209 closed/in-flight PRs. NS5 coefficient variants (#295, #811),
z-loss (#805, #313, #619, #851), contra-muon ablation (#806), and all schedule
axes are explicitly excluded.

Mandatory stack for all experiments:
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85

Baseline: val=3.26776, ffs=3000 (PR #613, n=2 mean)
Merge bar: val_mean <= 3.26776 AND ffs_mean <= 3000

Kill gates (corrected per PR #811 retrospective — derived from actual baseline
trajectory at each step, not the shifted values used in earlier PRs):
  step 500:  val > 3.81 → kill
  step 1000: val > 3.66 → kill
  step 2000: val > 3.43 → kill

Note: The RESEARCH_IDEAS_2026-05-22_13:35.md file used incorrect kill gates at
steps 1000 (3.55) and 2000 (3.30) due to a row-shift error. These corrected
values are derived from actual reference run vwrqt4vt trajectory + noise margin.

---

## Idea 1: AdamW Denominator Fractional Power (for frieren)

**Student constraint:** avoid schedule-adjacent axes (frieren's last: MUON_LR_LATE_BOOST)

**Mechanism class:** Optimizer state geometry — AdamW second-moment denominator

**Motivation:** Standard AdamW divides the gradient by sqrt(v_t), i.e. raises the
second-moment estimate to the power 0.5. The AdamPower paper (Liu et al., arxiv
2505.24275, 2025) demonstrates that replacing sqrt(v_t) with v_t^alpha for alpha
in (0, 0.5) achieves faster convergence and better final loss on language model
pre-training. The intuition: the square root is a convention inherited from Adam's
original derivation, not a principled optimum. A fractional power alpha < 0.5
reduces the effective learning rate damping on large-curvature directions, letting
the optimizer take larger steps where the loss surface is steep and the gradient
signal is reliable. For alpha closer to 0 (denominator approaches 1), the update
becomes more gradient-like; for alpha=0.5 (current), it is full RMSprop scaling.
The AdamPower paper reports Pareto-optimal alpha values of 0.25-0.375 for
transformer LM pre-training on similar scale to this stack, with measured val-loss
improvements of 0.003-0.008 nats versus the alpha=0.5 default.

This axis is completely orthogonal to all 209 closed/in-flight PRs: those axes
tuned beta1, beta2, warmup, cooldown, LR multipliers, and second-moment EMA
coefficients — none changed the functional form of the denominator. The SOAP
preconditioner and NorMuon both affect the Muon branch; this change targets the
AdamW branch (embed + head + scalar params). The mechanism does not interact with
NS5, contra, or SOAP in any known way.

**Expected impact:** Moderate. The AdamPower paper shows 0.003-0.008 nat
improvements over AdamW with alpha=0.5 in comparable transformer pre-training
settings. The current plateau is ~0.001-0.003 above the floor cluster, so alpha
tuning is in the right ballpark. The failure mode: if the embed/head/scalar
parameters are already well-conditioned and the AdamW branch is not the binding
constraint, the effect will be near-zero. That outcome is informative — it rules
out AdamW geometry as the bottleneck and concentrates attention on the Muon branch.

**Implementation:** In the AdamW parameter update step (wherever `torch.sqrt(exp_avg_sq)`
or `exp_avg_sq.sqrt()` appears for the Adam denominator), replace with:

```python
ADAMW_DENOM_POWER = float(os.environ.get("ADAMW_DENOM_POWER", "0.5"))
# ...
# Replace: denom = exp_avg_sq.sqrt().add_(eps)
# With:
denom = exp_avg_sq.pow(ADAMW_DENOM_POWER).add_(eps)
```

Gate behind `ADAMW_DENOM_POWER` env var (default 0.5 = standard AdamW,
fully backward-compatible). No schedule changes, no architecture changes,
no other optimizer changes.

**Arms (n=1 screening):**
- Arm A: `ADAMW_DENOM_POWER=0.25` (AdamPower paper's lower Pareto bound —
  more aggressive denominator reduction, larger effective step sizes)
- Arm B: `ADAMW_DENOM_POWER=0.375` (AdamPower paper's median Pareto optimum —
  intermediate between current 0.5 and the more aggressive 0.25)

If Arm B beats baseline at n=1, run n=2 confirmation before merge. If Arm A
kills and Arm B survives, try Arm B at n=2. If both miss but show val below 3.270
(within 0.002 of floor), authorize Arm C at alpha=0.4 (smaller perturbation from
default) as a follow-up.

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** Liu et al. "AdamPower: Power Gradients for Faster LM Pre-Training"
arxiv 2505.24275 (2025). See Table 2 for Pareto-optimal alpha values on GPT-scale
transformer pre-training.

---

## Idea 2: Label Smoothing on Cross-Entropy (for nezuko)

**Student constraint:** avoid schedule-adjacent axes AND beta2 axes (nezuko's last:
NORMUON_BETA2 + MUON_LR_EARLY_BOOST)

**Mechanism class:** Loss-level regularization — target distribution softening

**Motivation:** Label smoothing replaces the one-hot target distribution with a
mixture: (1 - epsilon) on the correct class, epsilon/(V-1) distributed uniformly
over all other classes. This was introduced by Szegedy et al. (CVPR 2016) and is
standard in NLP pre-training (it is on by default in many T5, Llama, and
GPT-style training recipes at epsilon=0.0-0.1). The mechanistic effect is twofold:
(a) it prevents the model from driving logits to infinity for the correct token
(gradient shrinks as the predicted probability approaches (1-epsilon), not 1.0),
reducing logit-scale drift; and (b) it provides soft gradient signal for all
vocabulary tokens, which regularizes the embedding matrix and head weights.

The current stack already uses LOGIT_SOFTCAP=20.0 to cap logit magnitude, but
softcap clips gradients non-differentiably; label smoothing provides continuous
pressure via the loss signal. The mechanisms are compatible but target different
paths: softcap is architectural, label smoothing is loss-level. In the floor
cluster where seed-to-seed variance is 0.001-0.003, any mechanism that reduces
gradient noise through the output head is a plausible lever.

Critically: label smoothing has never been tried in any of the 209 PRs. The
cross-entropy call in `GPT.forward()` uses `reduction="sum"` with no smoothing.
This is a 1-parameter change to an existing `F.cross_entropy` call, requiring
~3 LOC, zero compute overhead, and no optimizer or architecture changes.

**Implementation:** In `GPT.forward()`, modify the cross-entropy call:

```python
LABEL_SMOOTHING = float(os.environ.get("LABEL_SMOOTHING", "0.0"))
# ...
loss = F.cross_entropy(
    logits.view(targets.numel(), -1),
    targets.view(-1),
    reduction="sum",
    label_smoothing=LABEL_SMOOTHING,
)
```

Gate behind `LABEL_SMOOTHING` env var (default 0.0 = current behavior,
fully backward-compatible). Note: `label_smoothing` with `reduction="sum"` is
supported in PyTorch >= 1.10. The smoothing is applied per-token before the sum.

**Arms (n=1 screening):**
- Arm A: `LABEL_SMOOTHING=0.05` (light smoothing — standard for NLP tasks;
  most T5-style models use 0.1 but at this plateau 0.05 is less likely to
  over-regularize and raise the loss floor)
- Arm B: `LABEL_SMOOTHING=0.10` (standard label smoothing used in T5, PaLM —
  provides stronger gradient pressure but risks raising the minimum achievable
  loss if the effective target entropy increases too much for this vocabulary)

Note on expected loss behavior: label smoothing artificially raises the reported
cross-entropy loss (the reported loss includes the smoothing term). This means
the raw `val/loss` metric will appear slightly higher than without smoothing. To
interpret fairly, compute the offset: at epsilon=0.05, the smoothing adds
approximately 0.05 * log(V) nats to the loss where V=50257; this is ~0.05 * 10.8
= 0.54 nats for full uniform smoothing, but after discounting by (1-epsilon)
probability placement on the correct token, the net offset is ~0.03-0.05 nats.
Compare Arm A vs baseline only after accounting for this offset, or compute the
NLL on the correct token separately. Alternatively: if val/loss with smoothing
beats baseline directly (i.e. the regularization benefit outweighs the smoothing
offset), that is a conservative strong result.

**Kill gates:** step 500 > 3.84 (widened by 0.03 to account for smoothing
inflation in early training), step 1000 > 3.69 (widened by 0.03), step 2000 >
3.46 (widened by 0.03). Widen because the reported loss includes the smoothing
term. If the label smoothing offset is later computed precisely, use corrected
gates; these widened values err on the side of not killing a valid run early.

**Reference:** Szegedy et al. "Rethinking the Inception Architecture" CVPR 2016
(introduced label smoothing). Müller et al. "When Does Label Smoothing Help?"
NeurIPS 2019 (calibration and generalization analysis). PyTorch docs for
`torch.nn.functional.cross_entropy` label_smoothing parameter.

---

## Priority Order

1. Idea 2 (Label Smoothing, nezuko) — 3 LOC, zero compute cost, completely
   untested in 209 PRs, direct gradient-pressure mechanism compatible with
   existing LOGIT_SOFTCAP, standard across NLP training recipes. Highest
   information-per-LOC of any remaining untested mechanism in this family.

2. Idea 1 (AdamW Denominator Power, frieren) — optimizer geometry axis,
   first denominator-form change in 209 PRs, strong external evidence from
   AdamPower paper on comparable transformer scale, moderate implementation
   complexity (~5 LOC), fully orthogonal to all closed axes.

---

## Axis Exclusion Record

The following axes were explicitly verified as closed before these ideas were
selected:
- NS5 polynomial coefficients: PRs #295 (Polar Express) + #811 (aggressive/soft)
  — both bilateral kills; standard cubic (2,-1.5,0.5) confirmed Goldilocks
- Z-loss: PRs #805, #313, #619 closed; PR #851 (alphonse) currently in-flight
- CONTRA_MUON=0 ablation: PR #806 closed
- All MUON_LR schedule axes: PRs #818, #828, #833, #843 recently closed/in-flight
- All NORMUON_BETA2 axes: PR #828 (nezuko) closed — 0.95 local optimum confirmed
- SOAP_BETA2: PR #836 (askeladd) in-flight
- SOAP_PRECOND_FREQ: PR #837 (fern) in-flight
- ATTN_SOAP_BETA2: PR #842 (thorfinn) in-flight

---

## References

- AdamPower: Liu et al. arxiv 2505.24275 (2025) — fractional denominator power
  in AdamW for LM pre-training, Table 2 shows Pareto-optimal alpha in 0.25-0.375
- Label Smoothing: Szegedy et al. CVPR 2016; Müller et al. NeurIPS 2019
- PyTorch cross_entropy label_smoothing: pytorch.org/docs/stable/generated/
  torch.nn.functional.cross_entropy.html
