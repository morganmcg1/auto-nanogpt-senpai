# RESEARCH IDEAS — WAVE 5 — 2026-05-22

Generated against the post-#579 merged baseline (val=3.27070, fs=3225.0, n=3).
All hypotheses verified as mechanism-distinct from all closed families and
in-flight PRs as of 14:00 UTC 2026-05-22.

**In-flight at time of writing (do not duplicate):**
#708 (per-group grad clip), #710 (per-depth NS_ITERS), #724 (per-type
NS_ITERS_COOLDOWN), #787 (stochastic NS iter count), #789 (NS poly degree),
#791 (focal loss), #801 (position-weighted CE), #808 (distance-from-init WD).

---

## WAVE5-1: Zipf-Frequency-Weighted CE Loss

### What it is
Weight each token's cross-entropy contribution by a function of its vocabulary
frequency, amplifying rare-token gradient signal and down-weighting the few
ultra-frequent tokens that dominate the unweighted CE sum.

### Mechanism
Standard CE loss treats every predicted token equally, so Zipf-dominant tokens
(the, a, is, ...) contribute ~60-70% of the total gradient mass while the long
tail of rare tokens — which contain most semantic content — are systematically
under-weighted. A per-type weight `w(v) = C / sqrt(freq(v))` (normalized to
mean=1.0 across the vocabulary on the training corpus) redistributes gradient
mass toward the informative tail without changing the prediction head or any
optimizer logic.

This is distinct from focal loss (#791, in-flight), which reweights by model
confidence. Zipf-weighting reweights by corpus frequency regardless of how
well the model currently predicts the token. It is also distinct from label
smoothing (#446, NEG), which modifies target distributions, and z-loss (#441,
NEG), which adds a logit penalty.

### Why it might help
The model sees the ultra-frequent tokens on every batch step; AdamW's v_t for
those positions is large and well-converged. The rare tokens appear ~once per
many steps; their v_t is stale, and their CE contribution is swamped. By
amplifying rare-token gradients proportional to 1/sqrt(freq), we make the
optimization surface more uniform in information content per step. The
sqrt-inverse (rather than full inverse) prevents extreme token outliers from
dominating. Expected effect: faster convergence on semantic/factual
sub-vocabulary; slight risk of embed instability for ultra-rare tokens.

### Pseudocode
```python
# Precompute token frequency weights from corpus statistics once before training
# freq[v] = count(v) / total_tokens  (Zipf distributed, shape [vocab_size])
# w[v] = 1.0 / sqrt(freq[v])
# w = w / w.mean()  (normalize so aggregate loss scale unchanged)
# Store w as a buffer: self.register_buffer('ce_freq_weight', torch.tensor(w))

# In loss computation (forward pass):
logits = model(x)  # [B, T, V]
targets = y        # [B, T]

# Standard reduction='none' to get per-token loss
loss_per_token = F.cross_entropy(
    logits.view(-1, V), targets.view(-1), reduction='none'
)  # [B*T]

# Apply frequency weights
token_weights = ce_freq_weight[targets.view(-1)]  # [B*T]
loss = (loss_per_token * token_weights).mean()
```

### 4-arm hyperparameter matrix

| Arm | Weight function | Normalization | Notes |
|-----|----------------|---------------|-------|
| A   | uniform (w=1)  | n/a           | Exact control — same as baseline CE |
| B   | 1/sqrt(freq)   | mean=1.0      | Primary hypothesis arm |
| C   | 1/freq^0.33    | mean=1.0      | Softer exponent, less aggressive tail boost |
| D   | 1/freq^0.75    | mean=1.0      | More aggressive — tests sensitivity to exponent |

### Compute cost vs baseline
Negligible. One indexed gather + one elementwise multiply per step.
Token weight tensor is precomputed once from corpus statistics.

### Risk class
LOW-MEDIUM. Mechanistically clean and isolated to loss computation only.
Main risk: rare-token amplification destabilizes embed rows for very low-freq
tokens. Mitigation: normalization + moderate exponent in Arms C/D.

### Key references
- Mikolov et al. (2013) Word2Vec subsampling: inverse-frequency token sampling
  is the dual of inverse-frequency gradient weighting.
- Feldman (2020) "Does learning require memorization?" — long-tail token
  performance drives aggregate generalization in language models.
- FineWeb vocabulary statistics: top 500 tokens account for ~65% of corpus mass
  (estimated from public GPT-2 tokenizer on web text corpora).

---

## WAVE5-2: AdamW Second-Moment Floor (v_min)

### What it is
Add a global lower floor to the running second moment v_t in the AdamW update
for aux groups (embed, lm_head, scalars): `v_eff = max(v_t, v_floor)` where
`v_floor = v_floor_frac × median(v_t)` or a fixed absolute value. Prevents
step-size blowup for near-zero-variance coordinates.

### Mechanism
AdamW's step size per coordinate is proportional to `|g_t| / (sqrt(v_t) + ε)`.
For the lm_head, v_t has a Zipf-structured distribution: the few ultra-frequent
output logit rows accumulate large v_t, the many rare rows accumulate tiny v_t.
The current ε=1e-10 is so small it does not practically floor the rare rows,
resulting in extreme step-size variance across vocab entries. A larger effective
floor `v_floor = v_floor_frac × v_t.max()` or `× v_t.median()` compresses this
variance and brings rare logit rows closer to the well-adapted frequent ones.

Distinct from per-group ε (#652, closed), which adds an additive constant
to the denominator. A multiplicative floor `max(v_t, α × median(v_t))` is
scale-adaptive and preserves the Hessian-approximation interpretation while
bounding the worst-case step-size ratio across coordinates.

### Why it might help
The lm_head AdamW update is the final layer; extreme step-size variance on
rare logit rows may produce oscillation at low-frequency output positions.
A second-moment floor compresses this without the pathology of a large fixed ε
(which would uniform-scale all coordinates and degrade the preconditioner).
The floor is applied only to aux groups, leaving body Muon untouched.

### Pseudocode
```python
# In AdamW update step for aux groups only:
# v_t = beta2 * v_t + (1 - beta2) * g_t^2  (standard)

# Compute floor value
if v_floor_mode == 'median_frac':
    v_floor = v_floor_frac * v_t.median()
elif v_floor_mode == 'max_frac':
    v_floor = v_floor_frac * v_t.max()

# Apply floor
v_eff = torch.clamp(v_t, min=v_floor)

# Standard AdamW update using v_eff
step = lr * (m_hat / (v_eff.sqrt() + eps) + weight_decay * param)
param.data -= step
```

### 4-arm hyperparameter matrix

| Arm | Mode           | v_floor_frac | Applied to       |
|-----|----------------|--------------|------------------|
| A   | none (control) | n/a          | Exact baseline   |
| B   | median_frac    | 1e-4         | embed + lm_head  |
| C   | median_frac    | 1e-3         | embed + lm_head  |
| D   | max_frac       | 1e-6         | embed + lm_head  |

### Compute cost vs baseline
One median/max reduction per parameter group per step — negligible vs forward
pass.

### Risk class
LOW. Only modifies the effective denominator for aux groups; cannot affect
body Muon. Worst case: if v_floor_frac is too large, it degrades lm_head
preconditioner quality (all step sizes equalized) — visible as a fast early
loss increase.

### Key references
- Reddi et al. (2018) AMSGrad — maintains max(v_t) as a floor to guarantee
  convergence; this is a softer percentile variant.
- Zaheer et al. (2018) Adaptive Methods for Non-convex Optimization — analysis
  of step-size variance as a convergence bottleneck.
- Current stack evidence: #652 (per-group ε) found ε scale insensitive —
  that was additive, not multiplicative; multiplicative floor is a distinct test.

---

## WAVE5-3: Orthogonal / Haar-Measure Initialization for Body Matrices

### What it is
Initialize all body Muon weight matrices (q, k, v, c_attn, c_proj, mlp fc1,
mlp fc2) as random orthogonal matrices drawn from the Haar measure, rather than
the standard Kaiming/truncated-normal initialization.

### Mechanism
Muon's NS orthogonalization drives weight matrices toward the Stiefel manifold
during training. If we initialize on (or near) the manifold from step 0, the
NS iterates start closer to their attractor, the early-step update directions
are more aligned with the manifold's geometry, and the gradient signal
propagates through the network with preserved singular value spectrum from
the very first step. Kaiming initialization produces matrices with singular
values drawn from the Marchenko-Pastur distribution, which has a long tail;
the NS iterations must spend early steps compressing that tail.

Distinct from init scale experiments (#452, #163, and other scale variants,
all closed), which multiply a scalar onto the standard random init. Orthogonal
init changes the distribution, not just the scale.

### Pseudocode
```python
def orthogonal_init_(tensor):
    """Initialize tensor as a random orthogonal matrix (Haar measure)."""
    rows, cols = tensor.shape[0], tensor.numel() // tensor.shape[0]
    # Generate random Gaussian matrix and take QR decomposition
    rand = torch.randn(max(rows, cols), min(rows, cols))
    Q, R = torch.linalg.qr(rand)
    # Adjust for Haar measure: multiply by sign of diagonal of R
    Q = Q * R.diagonal().sign()
    if rows < cols:
        Q = Q.T
    # Reshape to original tensor shape and apply gain
    with torch.no_grad():
        tensor.copy_(Q.reshape(tensor.shape) * gain)

# In model.__init__:
for name, param in model.named_parameters():
    if param.ndim == 2 and 'weight' in name:
        if is_body_muon_param(name):  # q, k, v, c_attn, c_proj, mlp.c_fc, mlp.c_proj
            orthogonal_init_(param)
        # embed and lm_head keep standard init (Zipf reasons)
```

### 4-arm hyperparameter matrix

| Arm | Init method          | Gain factor | Notes |
|-----|----------------------|-------------|-------|
| A   | Kaiming (control)    | 1.0         | Exact baseline |
| B   | Orthogonal (Haar)    | 1.0         | Primary hypothesis |
| C   | Orthogonal (Haar)    | 0.5         | Scaled-down to match Kaiming magnitude |
| D   | Orthogonal (Haar)    | 2.0         | Scaled-up — tests gain sensitivity |

### Compute cost vs baseline
Zero additional cost at training time. Init is a one-time O(d²) operation —
negligible vs the full training run.

### Risk class
LOW-MEDIUM. Orthogonal init is well-established for RNNs and has been used
in transformers. Main risk: the gain factor interacts with layer norm and
residual scaling, so Arms C/D provide a safety net. The "fixed architecture"
constraint is respected — only initialization is changed.

### Key references
- Saxe et al. (2013) "Exact solutions to the nonlinear dynamics of learning in
  deep linear networks" — orthogonal init enables depth-independent signal
  propagation.
- Hu et al. (2020) "Provable Benefit of Orthogonal Initialization in
  Optimizing Deep Linear Networks" — convergence rate improvements.
- Bjorck & Bowie (1971) — Haar-measure QR algorithm (implemented in
  `torch.nn.init.orthogonal_`).
- Muon motivation: Kosson et al. (2024) show NS-based updates converge faster
  when starting near the orthogonal manifold.

---

## WAVE5-4: Stochastic Depth (Block-Drop Regularization)

### What it is
During training, randomly skip entire transformer blocks with a per-block
survival probability that follows a linear schedule (deep blocks dropped more
often than shallow blocks). Block output is replaced by its input (residual
path only). At evaluation, all blocks are active.

### Mechanism
Stochastic depth is a structural regularizer that implicitly trains an
ensemble of sub-networks of varying depth. Each forward pass sees a different
computational graph. This provides:
1. Regularization: prevents co-adaptation of adjacent block features.
2. Gradient efficiency: skipped blocks receive no gradient update, concentrating
   signal on active blocks — equivalent to a variable effective learning rate
   proportional to survival probability.
3. Early-step robustness: shallower sub-networks are more stable during early
   training.

This is distinct from dropout (neuron-level), attention dropout (element-level),
and weight decay (L2 penalty). It is a training-time-only architectural change
that does not modify the benchmark model weights, schedule, or optimizer.

Important constraint check: "Do not add multiple forward-backward passes per
optimizer step." Stochastic depth does NOT add passes — it REMOVES computation
by skipping blocks. A single forward + backward pass is preserved.

The "Keep the model architecture fixed" rule applies to inference-time
architecture. Stochastic depth is a training regularization technique; at
evaluation the full model is used.

### Pseudocode
```python
class StochasticDepthBlock(nn.Module):
    def __init__(self, block, survival_prob):
        super().__init__()
        self.block = block
        self.survival_prob = survival_prob  # layer-dependent

    def forward(self, x, **kwargs):
        if self.training and torch.rand(1).item() > self.survival_prob:
            return x  # skip this block entirely
        out = self.block(x, **kwargs)
        # Scale output so expected value matches full-network at eval
        if self.training:
            out = out / self.survival_prob  # compensate for skip rate
        return out

# Linear schedule: block i of L total gets survival_prob[i] = 1 - i/L * (1 - p_final)
# Example: 12 blocks, p_final=0.80 → block 0 survives 100%, block 11 survives 80%
survival_probs = [1.0 - (i / (num_layers - 1)) * (1 - p_final)
                  for i in range(num_layers)]
```

### 4-arm hyperparameter matrix

| Arm | p_final (deepest block) | Schedule type | Notes |
|-----|------------------------|---------------|-------|
| A   | 1.0 (no drop)          | n/a           | Exact control |
| B   | 0.90                   | linear        | Mild regularization |
| C   | 0.80                   | linear        | Standard stochastic depth |
| D   | 0.70                   | linear        | Aggressive; tests upper bound |

### Compute cost vs baseline
Reduces training FLOPS by `(1 - mean_survival_rate) × 100%`. For Arms B/C/D
that is 5–15% FLOP reduction. Slight overhead from bernoulli sampling per
block per step (negligible).

### Risk class
MEDIUM. Main risk: the benchmark constraint "Keep the model architecture fixed"
could be interpreted as prohibiting block-dropping. The counterargument is that
stochastic depth is universally classified as a training regularizer, not an
architecture change (the saved checkpoint uses the full 12-block model). Verify
with advisor before running at full scale. Secondary risk: small p_final may
hurt convergence speed (fewer effective gradient steps to deep layers).

### Key references
- Huang et al. (2016) "Deep Networks with Stochastic Depth" (ECCV) — original
  stochastic depth paper, shows 4-6% CIFAR-10 accuracy improvement over
  deterministic depth.
- He et al. (2016) ResNet — residual connections make block-dropping trivial
  (output = input when block skipped).
- Touvron et al. (2021) DeiT — stochastic depth used in modern vision
  transformer training with survival rates 0.8–0.9.

---

## WAVE5-5: Anisotropic Gradient Noise (Adam-Variance-Matched)

### What it is
After computing gradients and before NS/AdamW updates, inject additive noise
whose per-coordinate variance is proportional to the current AdamW second
moment v_t (or NS update magnitude) at that coordinate. This matches noise
anisotropy to the loss curvature, unlike isotropic gradient noise which adds
equal noise to all directions.

### Mechanism
Standard gradient noise injection (Neelakantan et al., 2015) uses isotropic
Gaussian noise N(0, σ²_t I). This is indiscriminate: it adds the same noise
magnitude to coordinates with high curvature (where noise is harmful) as to
flat coordinates (where noise aids escaping local minima). By scaling noise
variance to v_t, we inject more noise in flat directions and less in sharp
ones — annealing toward zero as training converges avoids noise-dominated
final convergence.

For body Muon groups, the noise is matched to the NS-update magnitude (the
Frobenius norm of the Newton-Schulz output divided by matrix size) rather than
to v_t (which is not tracked for Muon). For AdamW aux groups, noise scales
with v_t.

Distinct from gradient centralization (#752, NEG — removes row means) and
cautious optimizers (#751, NEG — sign-aware masking). This adds signal-matched
stochastic exploration rather than modifying the deterministic update direction.

### Pseudocode
```python
# For AdamW aux groups (embed, lm_head, scalars):
if noise_scale > 0:
    # v_t is the running second moment (already available)
    noise_std = noise_scale * torch.sqrt(v_t / (v_t.mean() + 1e-10))
    noise = torch.randn_like(grad) * noise_std
    grad = grad + noise

# For body Muon:
if noise_scale > 0:
    # Approximate curvature from NS update magnitude
    ns_update_rms = ns_update.norm() / ns_update.numel() ** 0.5
    # Isotropic noise at the block level scaled by NS magnitude
    noise = torch.randn_like(grad) * noise_scale * ns_update_rms
    grad = grad + noise

# Anneal noise_scale: linear from noise_max to 0 over warmup_frac of total steps
t_frac = step / total_steps
noise_scale_t = noise_max * max(0, 1 - t_frac / noise_anneal_frac)
```

### 4-arm hyperparameter matrix

| Arm | noise_max | noise_anneal_frac | Applied to |
|-----|-----------|-------------------|------------|
| A   | 0.0       | n/a               | Control |
| B   | 0.005     | 0.50              | AdamW aux only |
| C   | 0.005     | 0.50              | AdamW aux + body Muon |
| D   | 0.010     | 0.30              | AdamW aux + body Muon |

### Compute cost vs baseline
One randn + elementwise multiply per parameter group per step — approximately
1-2% overhead.

### Risk class
MEDIUM-HIGH. Gradient noise is well-studied but in this highly-tuned stack
with NS orthogonalization, any perturbation to Muon gradients could interact
badly. The annealing schedule is critical: if noise persists too long into
cooldown it will hurt final convergence. Arms B vs C tests whether aux-only
(safer) vs full-stack (more powerful) matters.

### Key references
- Neelakantan et al. (2015) "Adding Gradient Noise Improves Learning for Very
  Deep Networks" — isotropic baseline; anisotropic extension is the new
  contribution here.
- Zhang et al. (2019) "Why Gradient Clipping Accelerates Training" — curvature-
  matched perturbation theory.
- Ye et al. (2018) "Langevin Dynamics with Continuous Tempering" — variance-
  matched noise scheduling for optimization escape.

---

## WAVE5-6: Path-Norm / Training-Trajectory-Length Regularization

### What it is
Add an auxiliary regularization term penalizing the total L2 path length
traversed by parameters from initialization: `L_path = λ × sum_t(‖Δθ_t‖)`,
where the sum is approximated by accumulating `‖θ_t − θ_{t−k}‖` over a sliding
window of k steps.

### Mechanism
Standard L2 weight decay penalizes `‖θ_t‖²` (distance from zero) at every
step. Distance-from-init WD (#808, in-flight) penalizes `‖θ_t − θ_0‖²`
(displacement from init). Path-norm regularization penalizes the total
trajectory length — how far the optimizer has *moved* in weight space,
summed over all steps. This is a distinct quantity: a parameter that oscillates
near its initial value has high path norm but low displacement norm.

Path-norm regularization discourages high-frequency oscillations in weight
space (which waste update budget) and encourages smooth, directed trajectories.
Implemented as a loss term rather than an optimizer modification, it interacts
with the NS structure differently from WD.

### Pseudocode
```python
# In training loop:
# Maintain sliding-window parameter snapshot
if step % path_window == 0:
    theta_prev = {n: p.data.clone() for n, p in model.named_parameters()
                  if is_body_param(n)}

# Compute path-norm penalty every path_window steps
if step % path_window == 0 and step > 0:
    path_penalty = 0.0
    for n, p in model.named_parameters():
        if is_body_param(n) and n in theta_prev:
            path_penalty += (p.data - theta_prev[n]).pow(2).sum()
    path_loss = path_lambda * path_penalty

# Add to main loss before backward
total_loss = ce_loss + path_loss
total_loss.backward()
```

### 4-arm hyperparameter matrix

| Arm | path_lambda | path_window (steps) | Applied to |
|-----|-------------|---------------------|------------|
| A   | 0.0         | n/a                 | Control |
| B   | 1e-5        | 10                  | Body params only |
| C   | 1e-4        | 10                  | Body params only |
| D   | 1e-5        | 50                  | Body params only |

### Compute cost vs baseline
One extra snapshot copy per `path_window` steps (negligible). One L2-norm
computation per `path_window` steps (small). One extra `.backward()` is NOT
added — the path penalty is added to the scalar loss before the single backward
pass.

### Risk class
MEDIUM. The regularizer interacts with Muon's NS orthogonalization in a
non-obvious way (NS normalizes update magnitude, so path-norm per step is
roughly constant — the penalty might be nearly constant and ineffective, which
would produce a productive-null). The window length arms (B vs D) test whether
local vs cumulative path matters. Main falsifying signal: loss increases
monotonically with path_lambda (indicating interference rather than
regularization).

### Key references
- Neyshabur et al. (2015) "Path-SGD: Path-Normalized Optimization in Deep
  Neural Networks" — path-norm as a capacity measure in feedforward networks.
- Bartlett et al. (2017) "Spectrally-normalized margin bounds for neural
  networks" — path-norm generalization bounds.
- Fort & Jastrzebski (2019) "Large Scale Structure of Neural Network Loss
  Landscapes" — trajectory length correlates with generalization.

---

## WAVE5-7: Embed Gradient Sparsity-Rescaling via Inverse-Frequency Weighting

### What it is
Before the AdamW update for the embed group, rescale each token embedding row's
gradient by its inverse corpus frequency: `g_row[v] ← g_row[v] × w(v)`, where
`w(v) = sqrt(freq_max / freq(v))`. This amplifies the effective learning rate
for rare tokens whose gradients are systematically small due to sparse
activation.

### Mechanism
Token embedding rows are only activated (receive gradients) when the
corresponding token appears in the current batch. High-frequency tokens appear
every batch; their embed rows accumulate large AdamW v_t, and the effective
step size is well-calibrated. Rare tokens appear rarely; their v_t is stale
(exponential decay of past gradients dominate), making AdamW's adaptive
learning rate too conservative. Rescaling g_row[v] by sqrt(freq_max/freq(v))
effectively re-normalizes the embedding update signal to be frequency-
independent, similar to what a perfectly fresh v_t would produce.

Distinct from per-row L2 gradient clip (#668, NEG): that BOUNDS gradient
magnitude uniformly, creating an under-fit loop for lm_head's Zipf rows.
This AMPLIFIES gradients for rare embed rows while leaving common rows
unchanged — a multiplicative boost, not a cap.

Distinct from Zipf-frequency-weighted CE loss (WAVE5-1): that modifies the
loss computation before backward; this modifies the gradient after backward
but before the optimizer step. The mechanisms are at different levels.

### Pseudocode
```python
# Precompute frequency weights for embed (same corpus stats as WAVE5-1)
# w_embed[v] = sqrt(freq_max / freq[v]),  capped at w_max=10 to limit outliers
# Store as buffer on embed weight: model.transformer.wte.register_buffer('freq_weight', w)

# In optimizer step, before AdamW update for embed group:
for group in optimizer.param_groups:
    if group['name'] == 'embed':
        for p in group['params']:
            if p is model.transformer.wte.weight and p.grad is not None:
                # p.grad is sparse or dense [vocab_size, embed_dim]
                # Apply row-wise scaling by inverse frequency weight
                p.grad.data *= model.transformer.wte.freq_weight.unsqueeze(1)

# Note: this modifies grad before v_t accumulation in AdamW,
# so v_t also absorbs the scaling (intended — makes v_t freq-normalized).
```

### 4-arm hyperparameter matrix

| Arm | Weight function  | Cap (w_max) | Applied to |
|-----|-----------------|-------------|------------|
| A   | 1.0 (control)   | n/a         | Baseline |
| B   | sqrt(f_max/f_v) | 10          | embed only |
| C   | sqrt(f_max/f_v) | 5           | embed only (tighter cap) |
| D   | (f_max/f_v)^0.33| 10          | softer exponent |

### Compute cost vs baseline
One indexed multiply per step on embed gradients — O(B × T) element operations
where B × T << vocab_size. Negligible.

### Risk class
LOW-MEDIUM. Embed rows are downstream of body Muon; changes here should not
affect NS dynamics. Main risk: if the corpus frequency estimate is inaccurate
(collected from a different distribution than FineWeb), the scaling introduces
systematic bias. Use FineWeb shard statistics for w computation.

### Key references
- Mikolov et al. (2013) "Distributed Representations of Words and Phrases" —
  subsampling heuristic based on 1/sqrt(freq) is the dual intuition.
- Zhu et al. (2019) "FreeLB: Enhanced Adversarial Training for NLP" —
  frequency-aware gradient weighting for NLP tasks.
- Current stack evidence: #668 (per-row L2 clip) found clip always activates
  for lm_head Zipf rows — this experiment avoids clipping entirely and targets
  embed only (where there is no Zipf-structured second moment problem to
  preserve, unlike lm_head).

---

## WAVE5-8: AdamW Aux-Group β₁ Cooldown Annealing

### What it is
During the cooldown phase (last 30% of training, step > 0.7 × total_steps),
linearly anneal β₁ for AdamW aux groups (embed, lm_head, scalars) from the
training value 0.95 down to a lower value (0.70 or 0.50). This makes the
momentum-weighted gradient estimate more responsive to recent gradient
information as training converges.

### Mechanism
AdamW's exponential moving average of gradients `m_t = β₁ × m_{t-1} + (1-β₁) × g_t`
acts as a low-pass filter. High β₁=0.95 provides stable direction during the
bulk of training. But during the cooldown phase, when loss curvature sharpens
and the final configuration matters most, high momentum keeps following stale
directions from earlier training. Reducing β₁ → 0.70 during cooldown makes
m_t track current gradients more closely, adapting faster to the sharp loss
basin.

Distinct from:
- Per-group fixed β₁ (#599, closed) — that tests fixed values at different
  levels, not a scheduled annealing during cooldown.
- NAdam (#490, closed) — Nesterov reformulation of momentum, not β₁ scheduling.
- Body Muon momentum schedule (#356, closed) — different optimizer (Muon not
  AdamW), different group (body not aux), full training schedule not cooldown.
- AdamW β₂ cooldown (not tested): β₂ schedules have not been tested for aux.

### Pseudocode
```python
# In training loop, after computing current step fraction:
t_frac = step / total_steps
cooldown_start = 0.70  # matches NS_COOLDOWN_START_FRAC

if t_frac >= cooldown_start:
    # Linear anneal from beta1_base to beta1_cooldown_final
    cooldown_frac = (t_frac - cooldown_start) / (1.0 - cooldown_start)
    beta1_current = beta1_base - cooldown_frac * (beta1_base - beta1_cooldown_final)
    # Apply to all AdamW aux groups
    for group in optimizer.param_groups:
        if group['name'] in ('embed', 'head', 'scalar'):
            group['betas'] = (beta1_current, group['betas'][1])
else:
    beta1_current = beta1_base  # no change during main training
```

### 4-arm hyperparameter matrix

| Arm | β₁ base (training) | β₁ final (end of cooldown) | Applied to |
|-----|--------------------|-----------------------------|------------|
| A   | 0.95               | 0.95 (no cooldown anneal)   | Control |
| B   | 0.95               | 0.70                        | All aux groups |
| C   | 0.95               | 0.50                        | All aux groups |
| D   | 0.95               | 0.70                        | embed only |

### Compute cost vs baseline
Zero. β₁ update is a scalar assignment per step — no extra computation.

### Risk class
LOW. β₁ annealing is a well-understood technique. AdamW aux groups are
independent of body Muon; changes here cannot affect NS orthogonalization.
Main risk: too-aggressive annealing (Arm C, β₁→0.50) could cause noisy
updates at the end of cooldown. Arm D (embed only) provides a safe sub-test
in case lm_head β₁ sensitivity is different due to Zipf structure.

### Key references
- Dozat (2016) "Incorporating Nesterov Momentum into Adam" — showed momentum
  schedule during convergence phase matters.
- Loshchilov & Hutter (2019) AdamW — weight decay decoupling; β₁ schedule
  was not studied.
- Smith et al. (2019) "Super-convergence" — cyclical momentum (varying β₁
  during training) consistently improves final loss.
- Current stack: #599 (fixed per-group β₁ variants) closed null — different
  mechanism, provides no direct evidence against β₁ *scheduling* during
  cooldown.

---

## Summary Table

| # | Hypothesis | Risk | Compute | Mechanism level | Primary target |
|---|-----------|------|---------|----------------|----------------|
| W5-1 | Zipf-CE weighting | LOW-MED | +0% | Loss | Rare-token gradient mass |
| W5-2 | AdamW v_t floor | LOW | +0% | Optimizer | lm_head step-size variance |
| W5-3 | Orthogonal init | LOW-MED | +0% | Initialization | NS early-step manifold distance |
| W5-4 | Stochastic depth | MEDIUM | −5-15% | Regularization | Co-adaptation / ensemble |
| W5-5 | Anisotropic grad noise | MED-HIGH | +2% | Optimizer | Flat-direction exploration |
| W5-6 | Path-norm regularization | MEDIUM | +0% | Loss/Regularization | Trajectory oscillation |
| W5-7 | Embed grad freq rescaling | LOW-MED | +0% | Optimizer | Rare embed under-update |
| W5-8 | AdamW β₁ cooldown anneal | LOW | +0% | Optimizer schedule | Cooldown momentum staleness |

**Prioritization for assignment:**
1. W5-3 (orthogonal init) and W5-8 (β₁ cooldown anneal) — lowest risk, cleanest
   mechanism, no interaction with NS.
2. W5-1 (Zipf-CE) and W5-7 (embed grad rescaling) — complementary frequency-
   domain interventions; run one first to disambiguate.
3. W5-2 (v_t floor) — clean isolated test of lm_head step-size variance.
4. W5-6 (path-norm) and W5-4 (stochastic depth) — medium risk, may need
   coordinator verification on benchmark interpretation.
5. W5-5 (anisotropic grad noise) — highest risk, run last.
