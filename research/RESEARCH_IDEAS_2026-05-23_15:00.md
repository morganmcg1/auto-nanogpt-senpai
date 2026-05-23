# Research Ideas — 2026-05-23 15:00

Generated for 2 idle students. All 5 ideas target mechanism axes NOT represented
in any of the 209 closed/in-flight PRs. Label smoothing (#901 closed), AdamW
denominator power (now in-flight), NORMUON_BETA2 (#828 closed), all schedule
axes, and NS5 coefficient/iter-count axes are explicitly excluded.

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

Source code: records/track_3_optimization/train_gpt_simple.py

---

## Idea 1: CONTRA Power-Iteration Count (for frieren)

**Student constraint:** avoid schedule-adjacent axes (frieren's last: MUON_LR_LATE_BOOST,
then ADAMW_DENOM_POWER in-flight)

**Mechanism class:** NorMuon internals — contra spectral-norm estimation quality

**Motivation:** The `scale_to_unit_operator_norm` function (line 493-504 of
train_gpt_simple.py) normalizes the gradient tensor to unit operator norm before
the contra-Muon subtraction step. Its power-iteration count is hardcoded at 5:

```python
for _ in range(5):  # HARDCODED — NEVER VARIED IN 209 PRs
    u = X @ v; u = u / torch.clamp(u.norm(), min=eps)
    v = X.mT @ u; v = v / torch.clamp(v.norm(), min=eps)
op_norm = torch.clamp((X @ v).norm(), min=eps)
return G / op_norm.to(G.dtype)
```

Power iteration converges to the largest singular value (operator norm) at a
rate that depends on the singular value gap (sigma_1 / sigma_2). For poorly
conditioned gradient matrices with a small singular value gap, 5 iterations
may give a materially inaccurate operator norm estimate, causing the contra
subtraction to use a mis-scaled reference. For well-conditioned matrices, even
3 iterations suffices. Shulgin et al. ("Beyond the Ideal Orthogonality", CPAL
2026) show that NS5 approximation quality couples with optimal momentum and LR
in Muon-style optimizers; the same principle applies to the contra normalization
step — imprecise normalization introduces noise into the contra gradient that
competes with the NS5 orthogonalization.

The contra subtraction is: `update = ns5_output - CONTRA_MUON * contra_normed`
where `contra_normed` is the SOAP-preconditioned gradient normalized by
`scale_to_unit_operator_norm`. If the operator norm estimate is off by even 5%,
the contra term is incorrectly weighted, and no amount of CONTRA_MUON tuning
(already closed via #806) can fully compensate.

This axis is completely orthogonal to all 209 closed/in-flight PRs: those axes
changed CONTRA_MUON scalar weight, NS5_ITERS, NS5 polynomial coefficients, and
SOAP preconditioner betas — none changed the power iteration count used inside
`scale_to_unit_operator_norm` for the contra normalization step.

**Expected impact:** Small to moderate. The failure mode is benign: if gradient
matrices in this training run are well-conditioned (large singular value gap),
5 vs 3 vs 8 iterations all converge to essentially the same operator norm, and
the effect is near-zero. That outcome is directly informative — it rules out
contra normalization precision as a bottleneck. If the floor cluster at
val=3.270 reflects accumulated normalization error across thousands of training
steps, tighter norm estimation could close the gap. Effect size: likely
0.001-0.004 nats if binding.

**Implementation:** In the `scale_to_unit_operator_norm` function, parameterize
the iteration count:

```python
CONTRA_POWER_ITER = int(os.environ.get("CONTRA_POWER_ITER", "5"))
# In scale_to_unit_operator_norm, replace:
#   for _ in range(5):
# With:
for _ in range(CONTRA_POWER_ITER):
```

Gate behind `CONTRA_POWER_ITER` env var (default 5 = current behavior,
fully backward-compatible). ~5 LOC total patch, zero architecture change,
zero compute overhead for the default.

**Compute cost note:** Each additional power iteration adds 2 matmuls over the
gradient matrix shape. For a typical MLP weight with shape (4*768, 768) the
overhead is negligible vs the NS5 iterations themselves. Going from 5 to 8
iterations adds ~0.1% wallclock.

**Arms (n=1 screening):**
- Arm A: `CONTRA_POWER_ITER=3` (underestimate — deliberately accepts noisier
  operator norm to test whether 5 is already overkill)
- Arm B: `CONTRA_POWER_ITER=8` (overestimate — tighter convergence; tests
  whether 5 iterations leave meaningful residual error)

If Arm B beats baseline at n=1, run n=2 confirmation before merge. If both miss
but show val in 3.267-3.272 range, try Arm C at `CONTRA_POWER_ITER=10` as
follow-up. If Arm A is not significantly worse than Arm B, the mechanism is
insensitive (valuable null result — deprioritize further iteration on this axis).

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** Shulgin et al. "Beyond the Ideal Orthogonality" CPAL 2026 —
shows NS approximation precision couples with momentum and LR sensitivity in
Muon-style optimizers. The power iteration inner loop is the analogous
approximation in the contra normalization pathway. Power iteration for operator
norm estimation: Golub & Van Loan "Matrix Computations" 4th ed. (2013),
Algorithm 9.3.1, convergence rate (sigma_1/sigma_2)^{2k} per k iterations.

---

## Idea 2: NorMuon Second-Moment Granularity (for nezuko)

**Student constraint:** avoid schedule-adjacent AND beta2 axes (nezuko's last:
NORMUON_BETA2, then NS5_INPUT_NORM_TYPE in-flight)

**Mechanism class:** NorMuon internals — second-moment buffer geometry

**Motivation:** The current NorMuon implementation stores a per-row (or
per-column for wide matrices) scalar second moment, not a per-element tensor.
From the optimizer state initialization (lines 672-680):

```python
if p.size(-2) >= p.size(-1):
    state["second_moment"] = torch.zeros((*p.shape[:-1], 1), ...)
else:
    state["second_moment"] = torch.zeros((*p.shape[:-2], 1, p.shape[-1]), ...)
```

For a weight matrix of shape (out_features, in_features), each row shares a
single scalar second-moment estimate. This is a coarser approximation than the
per-element second moment used by standard Adam, but coarser than the full
matrix second-moment used by Shampoo or full AdaGrad. The motivation for
per-row is computational efficiency and the insight that after NS5
orthogonalization, rows have similar gradient magnitudes.

However, AdaMuon (Li et al., arXiv 2507.11005, 2025) demonstrates that
element-wise second moments ON THE ORTHOGONALIZED gradient — i.e., after the
NS5 step, before the NorMuon normalization step — provide a materially better
adaptive signal than per-row scalars, particularly early in training when
different directions within a row have heterogeneous curvature. The paper
reports 0.003-0.006 nat improvements over per-row NorMuon on GPT-2-scale
language model pre-training.

In the current `contra_normuon_update` pipeline (lines 507-526), the second
moment update occurs AFTER the NS5 step:

```
pipeline order: NS5 → contra subtract → Frobenius renorm → aspect_ratio scale
                → per-row variance EMA normalize
```

The per-row EMA in the final step accumulates the variance of the full post-NS5
update per row, not per element. Upgrading to per-element shape changes the
buffer from `(*p.shape[:-1], 1)` to `p.shape`, i.e. from shape (out, 1) to
shape (out, in). This increases the optimizer state memory by roughly
`in_features / 1 = in_features` per parameter group — a 768x increase in
second_moment buffer size for model_dim=768 weights. At this model scale (12
layers, 768 dim) the absolute memory cost is modest: ~200 MB additional GPU
memory at float32, which is well within the 96 GB VRAM budget.

This axis is completely orthogonal to all 209 closed/in-flight PRs: NORMUON_BETA2
controls the EMA decay rate of the second moment (closed #828); this PR changes
the shape of what is being averaged. Changing the EMA decay of a scalar is
distinct from changing from a scalar to a per-element tensor.

**Expected impact:** Moderate. AdaMuon paper reports 0.003-0.006 nat improvements
in comparable settings. The current floor cluster at val=3.270 ± 0.003 is
0.001-0.003 nats above baseline, so this is a plausible lever. Failure mode:
the NorMuon row-normalization step already effectively normalizes across
elements within a row, so the marginal information in per-element second moments
may already be captured. If so, the effect is near-zero; that rules out
second-moment geometry as the bottleneck.

**Implementation:** In the optimizer state initialization block (lines 672-680),
add an env-gated branch:

```python
NORMUON_SM_GRANULARITY = os.environ.get("NORMUON_SM_GRANULARITY", "per_row")
# ...
if NORMUON_SM_GRANULARITY == "per_element":
    state["second_moment"] = torch.zeros(p.shape, dtype=torch.float32, device=p.device)
else:  # default: per_row (current behavior)
    if p.size(-2) >= p.size(-1):
        state["second_moment"] = torch.zeros((*p.shape[:-1], 1), ...)
    else:
        state["second_moment"] = torch.zeros((*p.shape[:-2], 1, p.shape[-1]), ...)
```

The EMA update and normalization step downstream automatically broadcasts
correctly for both shapes (per-row scalars already broadcast over the in_features
dimension; per-element tensors do not need broadcasting). Verify that the
division in the normalize step uses in-place ops that broadcast or expand
correctly — per-element should be a drop-in replacement if the code already
uses `.div_(second_moment.sqrt().add_(eps))` style. ~8-12 LOC total patch.

**Arms (n=1 screening):**
- Arm A: `NORMUON_SM_GRANULARITY=per_element` (full AdaMuon-style per-element
  second moment on the post-NS5 orthogonalized gradient)

Single-arm screening is justified because the default (per_row) is the fully
reproducible current baseline; there is no "other direction" to bracket against
that is distinct from the current behavior. If Arm A beats baseline at n=1,
run n=2 confirmation before merge.

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** Li et al. "AdaMuon: Adaptive Muon with Element-Wise Momentum"
arXiv 2507.11005 (2025) — demonstrates per-element second moment on
orthogonalized gradient directions in the Muon framework, Table 2 shows
0.003-0.006 nat improvements on GPT-2-scale LM pre-training vs per-row baseline.
NorMuon paper (Li et al., ICLR 2026) establishes the per-row design choice and
its motivation; AdaMuon extends it.

---

## Idea 3: Attention Scale Factor (architecture)

**Mechanism class:** Architecture — attention dot-product temperature

**Motivation:** The current code uses `scale=0.12` hardcoded in
`F.scaled_dot_product_attention` (line 386):

```python
y = F.scaled_dot_product_attention(
    q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2),
    scale=0.12, is_causal=True).transpose(1, 2)
```

The standard attention scale is `1 / sqrt(head_dim)`. With `head_dim = 768 / 6
= 128`, the standard scale is `1/sqrt(128) ≈ 0.0884`. The current 0.12 is
approximately 36% above the standard value. A higher scale value INCREASES
the effective logit temperature (softmax concentrates more sharply on the
highest-weight token), whereas a lower scale INCREASES entropy of the attention
distribution (more uniform mixing across positions).

The value 0.12 appears to have been tuned at some earlier stage of the research
programme but was NEVER bracketed or varied in any of the 209 closed/in-flight
PRs. This is an architecture axis that is directly accessible as a ~3 LOC
env-gated patch and has zero optimizer or data interactions. QK-normalization
(already present via `F.rms_norm` on q and k at line 383) means the dot products
are bounded regardless of scale, which actually INCREASES the sensitivity to
scale: without QK-norm, larger scale can cause softmax saturation and the
attention distribution adapts; WITH QK-norm, the magnitudes are fixed, so the
scale directly controls the temperature of the attention distribution.

The NTK literature (Yang et al. 2022, Tensor Programs) and muP
(maximal update parameterization) both identify attention temperature as a
training-stable hyperparameter that should be tuned relative to model width;
at model_dim=768 with num_heads=6, head_dim=128 is unusually large
(standard GPT-2 uses head_dim=64), which means the standard scale formula
understates the appropriate temperature and a value above 0.0884 is expected
to be optimal. However, whether 0.12 is the right value has never been tested.

This axis has never appeared in any of the 209 closed/in-flight PRs. It is
completely orthogonal to all optimizer, loss, and data axes.

**Expected impact:** Small to moderate. Attention temperature is a
well-established lever in transformer pre-training. The current value was set
empirically at an earlier stage; the question is whether the local optimum has
shifted as other components of the stack were improved over 209 PRs. A 5-10%
change in scale corresponds to a modest shift in attention sharpness. If binding,
effect size 0.002-0.006 nats is plausible based on similar studies.

**Implementation:**

```python
ATTN_SCALE = float(os.environ.get("ATTN_SCALE", "0.12"))
# In CausalSelfAttention.forward, replace:
#   scale=0.12
# With:
#   scale=ATTN_SCALE
```

Fully backward-compatible (default 0.12 = current behavior). ~3 LOC total.

**Arms (n=1 screening):**
- Arm A: `ATTN_SCALE=0.10` (closer to standard; less sharp attention;
  more uniform mixing — tests whether current 0.12 is too high)
- Arm B: `ATTN_SCALE=0.14` (sharper attention than current; tests whether
  0.12 is too low given the large head_dim=128 and QK-norm)

Symmetric bracket around current value. If Arm B beats baseline, try Arm C
at `ATTN_SCALE=0.16`. If Arm A beats baseline, try Arm C at `ATTN_SCALE=0.09`.

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** Yang et al. "Tensor Programs V: Tuning Large Neural Networks via
Zero-Shot Hyperparameter Transfer" arXiv 2203.03466 (2022) — attention temperature
is a key muP axis that scales with model width; head_dim=128 at this scale sits
in the regime where temperature matters. Wortsman et al. "Small-scale proxies for
large-scale Transformer training instabilities" arXiv 2309.14322 (2023) — shows
attention scale among the top instability-inducing hyperparameters in GPT training.

---

## Idea 4: RoPE Base Frequency (architecture)

**Mechanism class:** Architecture — positional encoding decay rate

**Motivation:** The Rotary Position Embedding (RoPE) in the current code uses
base frequency `1/1024` with half-truncation (line 354):

```python
angular_freq = (1 / 1024) ** torch.linspace(0, 1, steps=dim//4, dtype=torch.float32)
self.register_buffer("angular_freq", torch.cat([angular_freq, angular_freq.new_zeros(dim//4)]))
```

The original RoPE paper (Su et al. 2021) uses base `10000` (i.e., `1/10000`
raised to `2i/d`), which at `d=128` gives angular frequencies ranging from 1.0
(i=0) down to approximately `10000^{-1} ≈ 0.0001` for the highest index. The
current code uses `base=1024`, giving a much faster decay: frequencies range
from 1.0 down to `(1/1024)^1 ≈ 0.001`. A lower base frequency creates
LONGER-RANGE position sensitivity (angles rotate slowly, so positions far apart
still have meaningfully different dot products), while a higher base creates
SHORT-RANGE sensitivity (angles rotate faster, saturating quickly).

Crucially: the half-truncation (setting the second half of angular_freq to zero)
means only dim//4 = 32 of 128 dimensions carry positional information. This is
already an aggressive modification to standard RoPE. The combination of
half-truncation + base=1024 has never been bracketed along the base-frequency
axis in any of the 209 closed/in-flight PRs.

The context length in this training run is `T=1024` tokens. With base=1024, the
position angle at the final position for the lowest-frequency dimension is
`(1/1024)^1 * 1024 ≈ 1.0` radian — meaning positions 1 and 1024 are nearly
fully decorrelated in the slow dimension, which is the maximum useful range
for this context. Whether this is optimal or whether a base of 512 (shorter
range, more angular resolution per position) or 2048 (longer range, slower decay)
produces better language modeling is unknown.

This axis is completely absent from the 209 closed/in-flight PRs.

**Expected impact:** Small to moderate. RoPE base frequency is a standard
hyperparameter in all modern LLMs but has not been swept in this research
programme. The half-truncation design makes the sensitivity less predictable
than in standard RoPE; the non-zero dimensions carry all positional signal,
so the effective base matters only for those 32 dimensions. Effect size:
likely 0.001-0.005 nats if binding.

**Implementation:**

```python
ROPE_BASE = float(os.environ.get("ROPE_BASE", "1024"))
# In Rotary.__init__, replace:
#   angular_freq = (1 / 1024) ** torch.linspace(...)
# With:
angular_freq = (1 / ROPE_BASE) ** torch.linspace(0, 1, steps=dim//4, dtype=torch.float32)
```

Fully backward-compatible (default 1024 = current behavior). ~3 LOC.

**Arms (n=1 screening):**
- Arm A: `ROPE_BASE=512` (shorter effective range; faster rotation; stronger
  local position signal; tests whether context=1024 training benefits from
  denser positional coding)
- Arm B: `ROPE_BASE=2048` (longer effective range; slower rotation; weaker
  local signal; tests whether the model would benefit from more gentle positional
  decay matching longer-range dependency patterns)

Symmetric bracket around current value (1024 = midpoint between 512 and 2048
on a log scale). If Arm B beats baseline, try `ROPE_BASE=4096`. If Arm A beats
baseline, try `ROPE_BASE=256`.

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** Su et al. "RoFormer: Enhanced Transformer with Rotary Position
Embedding" arXiv 2104.09864 (2021) — original RoPE; base=10000 default.
Press et al. "Train Short, Test Long: Attention with Linear Biases Enables
Input Length Extrapolation" ICLR 2022 — position decay rate sensitivity.
Chen et al. "Extending Context Window of Large Language Models via Positional
Interpolation" arXiv 2306.15595 (2023) — shows base frequency directly
controls effective context range; this is the same axis though in a different
regime.

---

## Idea 5: Body Weight Initialization Scale (initialization)

**Mechanism class:** Initialization — non-embed/non-head weight scale

**Motivation:** The body weights (all weights not in embed, proj/lm_head, or
bias) use a fixed initialization formula (lines 884-898):

```python
elif "embed" in name:
    w.normal_(std=EMBED_INIT_STD)  # tuned: EMBED_INIT_STD=0.1 in stack
else:
    w.normal_(std=0.33**0.5 / w.size(-1)**0.5)  # FIXED — never varied
```

The formula `0.33^0.5 / sqrt(fan_in)` = `sqrt(0.33 / fan_in)` is a
fan-in-scaled normal initialization with variance 0.33/fan_in. Standard
Kaiming (He) init uses variance `2/fan_in` for ReLU (or `1/fan_in` for linear);
the constant 0.33 is approximately `1/3`, giving variance `1/(3*fan_in)` — a
factor of ~3 smaller than Kaiming and a factor of ~6 smaller than He. This
conservative initialization reduces the initial residual stream variance but
may also slow learning in early training if the gradient signal is too small
in the early steps.

EMBED_INIT_STD has been tuned (closed in earlier PRs). But the 0.33 constant
in the body initialization formula has NEVER been varied in any of the 209
closed/in-flight PRs. Adding a scalar multiplier `BODY_INIT_SCALE` changes the
initial weight standard deviation without altering the fan-in scaling law:

`w.normal_(std=BODY_INIT_SCALE * 0.33**0.5 / w.size(-1)**0.5)`

Values above 1.0 increase initial weight scale (larger initial activations,
faster early dynamics); values below 1.0 give more conservative initialization.
In the context of Muon optimization (which re-normalizes gradients via NS5),
the optimal initialization scale may differ from what standard SGD analysis
suggests — specifically, Muon's orthogonalization removes the scale of the
gradient, so the loss surface geometry near initialization matters more through
the second-moment normalization than through the gradient magnitude directly.

This axis has never appeared in any of the 209 closed/in-flight PRs.

**Expected impact:** Small. Initialization effects compound early in training
and decay as the optimizer adapts. At 10,000+ training steps, the memory of
initialization is largely washed out for standard optimizers. However, with
Muon's NS5 orthogonalization, early dynamics can establish structural patterns
in the weight matrices that persist: if the initial singular value structure of
the weights is poorly calibrated, NS5's convergence to the optimal rotation may
take longer. Effect size: likely 0-0.003 nats; highest probability of near-zero
effect, but the null result is informative (rules out initialization scale as a
remaining bottleneck).

**Implementation:**

```python
BODY_INIT_SCALE = float(os.environ.get("BODY_INIT_SCALE", "1.0"))
# In the initialization block, replace:
#   w.normal_(std=0.33**0.5 / w.size(-1)**0.5)
# With:
w.normal_(std=BODY_INIT_SCALE * (0.33**0.5) / w.size(-1)**0.5)
```

Fully backward-compatible (default 1.0 = current behavior). ~3 LOC.

**Arms (n=1 screening):**
- Arm A: `BODY_INIT_SCALE=0.8` (more conservative; smaller initial weights;
  tests whether current initialization is already too large relative to the
  Muon-optimized loss surface)
- Arm B: `BODY_INIT_SCALE=1.2` (slightly larger; tests whether current
  initialization is under-scaled given the small 0.33 constant)

If both arms are clearly worse than baseline, close. If one arm beats baseline,
run n=2 confirmation. If both are within 0.002 of baseline but neither beats
it, the axis is exhausted — close.

**Kill gates:** step 500 > 3.81, step 1000 > 3.66, step 2000 > 3.43.

**Reference:** He et al. "Delving Deep into Rectifiers" ICCV 2015 — Kaiming
init for ReLU networks. The relu^2 activation in the current MLP (line 400)
has a different variance propagation constant than standard ReLU, which may
affect the optimal fan-in scaling (variance of relu^2 output depends on fourth
moment of input). Yang & Hu "Feature Learning in Infinite-Width Neural Networks"
ICML 2021 — initialization scale as a muP axis.

---

## Priority Order

1. Idea 3 (ATTN_SCALE) — 3 LOC, architecture axis hardcoded at 0.12 for entire
   209-PR history, direct effect on attention distribution sharpness, QK-norm
   makes the temperature uniquely effective (magnitudes fixed), highest expected
   information gain per line of code.

2. Idea 1 (CONTRA_POWER_ITER) — 5 LOC, hardcoded power_iter=5 in
   scale_to_unit_operator_norm never varied, mechanically plausible path to
   the floor cluster, fully orthogonal to all 209 closed axes, Shulgin CPAL 2026
   provides theoretical grounding, tight failure mode (null result rules out
   contra normalization precision as a bottleneck).

3. Idea 2 (NORMUON_SECOND_MOMENT_GRANULARITY) — 8-12 LOC, AdaMuon paper
   shows per-element second moment on orthogonalized gradient is uniformly
   better than per-row at comparable scale, direct upgrade to current buffer
   geometry, memory cost modest at this scale, strong external evidence.

4. Idea 4 (ROPE_BASE) — 3 LOC, architecture axis completely untested in 209
   PRs, half-truncation makes base sensitivity non-obvious (could go either
   direction), diagnostic value high even for null result.

5. Idea 5 (BODY_INIT_SCALE) — 3 LOC, lowest expected effect size given
   10k+ training steps, but eliminates initialization scale as a remaining
   open uncertainty. Assign only when all other axes are exhausted.

---

## Axis Exclusion Record

The following axes were explicitly verified as closed before these ideas were
selected:
- NS5 polynomial coefficients: PRs #295 (Polar Express) + #811 — bilateral kills
- NS5_ITERS: closed at 14 — both lower and higher values refuted
- Z-loss: PRs #805, #313, #619, #851 — all closed
- CONTRA_MUON scalar: PR #806 — closed
- NORMUON_BETA2: PR #828 — closed, 0.95 local optimum confirmed
- NORMUON_ASPECT_RATIO_EXP: PR #910 — in-flight (Arm A=0.333)
- SOAP_BETA2: PR #836 — in-flight
- SOAP_PRECOND_FREQ: PR #837 — in-flight
- ATTN_SOAP_BETA2: PR #842 — in-flight
- ATTN_SOAP_PRECOND_FREQ: PR #894 — closed (60th refuted)
- NS5_INPUT_NORM_TYPE: PR #917 — assigned (spectral vs frobenius_scaled)
- Label smoothing: PR #901 — closed (58th refuted)
- ADAMW_DENOM_POWER: PR for frieren in-flight (0.25 and 0.375)
- All MUON_LR schedule axes: PRs #818, #828, #833, #843, MUON_LR_LATE_BOOST
- ADAMW_BETA1: PR #878 — closed (57th refuted)
- MU_WARMUP_STEPS: PR #882 — closed (59th refuted)
- QK-norm placement: ALREADY IN CODE at line 383 — cannot be an axis

---

## References

- Shulgin et al. "Beyond the Ideal Orthogonality" CPAL 2026 — NS5 precision
  couples with momentum/LR in Muon-style optimizers
- Li et al. "AdaMuon: Adaptive Muon with Element-Wise Momentum" arXiv 2507.11005
  (2025) — per-element second moment on orthogonalized gradient
- Yang et al. "Tensor Programs V" arXiv 2203.03466 (2022) — attention
  temperature as a muP axis, sensitivity to model width
- Wortsman et al. arXiv 2309.14322 (2023) — attention scale among top GPT
  training instability sources
- Su et al. "RoFormer" arXiv 2104.09864 (2021) — original RoPE, base=10000
- Chen et al. arXiv 2306.15595 (2023) — base frequency controls effective range
- He et al. ICCV 2015 — Kaiming initialization; relu^2 variance analysis
- Davis et al. arXiv 2512.04299 — nuclear-to-Frobenius ratio as Muon predictor
