# Research Ideas: 2026-05-26 03:00

Generated after reviewing 204 PRs (16 merged, 130 ran not merged, 61 never ran).
Baseline: val/loss=3.26614, first_step_to_target=3175.00 (Newton-Muon, PR #1138 merged).
Saturated/banned clusters: MAGNITUDE-PRESERVING-DENOMINATOR-MODIFIERS (#1100, #1155, #1153, #1175, #1210 all NULL), MAGNITUDE-EQUALIZING-ACROSS-ROWS (#1192 catastrophic).
Active in-flight: #1240 (Newton-Muon 2x2 factorial), #1231, #1236, #1203, #1232.

---

## Hypothesis 1: MUON2-PRE-NS5-ADAPTIVE

**Axis tag:** PRECONDITIONERS-NEW-AXIS / MUON-VARIANT

**Mechanism summary:**
Apply element-wise adaptive scaling to the momentum buffer M_t BEFORE Newton-Schulz 5 orthogonalization, not after. Accumulate per-element second moment V_t = β2·V_{t-1} + (1-β2)·(G_t ⊙ G_t), then compute the pre-conditioned momentum M̃_t = M_t ⊘ (√V_t + ε), then feed M̃_t into NS5. The scaling normalizes gradient magnitude variance across entries before the polar decomposition, so NS5 operates on a more isotropic matrix. The factorized variant Muon2-F approximates V̂_t using outer product r_t·c_t^T (row-norms × col-norms) to reduce memory to O(m+n) per layer.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster (MARS, AdaBelief, v_min, CAUTIOUS-MASK, AdaBelief) all modify the POST-NS5 output or the denominator of an Adam-style update in the aux track. Muon2 acts PRE-NS5 on the body Muon track. Newton-Muon (merged #1138) uses the right-preconditioner R = EMA(X^T X) — a matrix derived from input activations — applied as M·R^{-1/2}. Muon2 uses element-wise gradient second moments on M directly. These are fully orthogonal operations: one uses activation statistics for right-preconditioning, the other uses gradient statistics for entry-wise rescaling before the orthogonalization step.

**Key references:**
- "Muon2: Adaptive Muon Optimizer" (arxiv:2604.09967, 2026). Reduces NS iterations by ~40%, GPT-2 perplexity improvement on par with AdamW tuning.

**Implementation sketch:**
New env vars:
```
NANOGPT_MUON2=1                     # enable Muon2 pre-NS5 scaling
NANOGPT_MUON2_BETA2=0.95            # second-moment EMA decay
NANOGPT_MUON2_EPS=1e-8              # denominator floor
NANOGPT_MUON2_FACTORIZED=0          # 0=full, 1=Muon2-F row/col approx
```

Implementation pseudocode (in the body Muon update, before `ns5` call):
```python
# Before: orth_grad = zeropower_via_newtonschulz5(buf, steps=5)
# After inserting Muon2:
if muon2:
    v = beta2 * v_state + (1 - beta2) * (buf ** 2)
    v_state.copy_(v)
    buf_scaled = buf / (v.sqrt() + eps)
    orth_grad = zeropower_via_newtonschulz5(buf_scaled, steps=5)
else:
    orth_grad = zeropower_via_newtonschulz5(buf, steps=5)
```

**4-arm screen design:**
- Arm A (ctrl): baseline Newton-Muon, no Muon2 (`NANOGPT_MUON2=0`)
- Arm B: Muon2 full, β2=0.95 (`NANOGPT_MUON2=1 NANOGPT_MUON2_BETA2=0.95`)
- Arm C: Muon2 full, β2=0.99 (`NANOGPT_MUON2=1 NANOGPT_MUON2_BETA2=0.99`)
- Arm D: Muon2-F factorized, β2=0.95 (`NANOGPT_MUON2=1 NANOGPT_MUON2_FACTORIZED=1 NANOGPT_MUON2_BETA2=0.95`)

All arms: 3350 steps, same arch/data/batch. Report val/loss and first_step_to_3.28.

**Expected signal direction:**
Lower val/loss and reduced first_step_to_target. Muon2 paper shows ~40% reduction in NS iterations required; even if we keep 5 iterations the better-conditioned input matrix should produce a tighter orthogonalization per step.

---

## Hypothesis 2: NAMO-D-POST-NS5-COLUMN

**Axis tag:** PRECONDITIONERS-NEW-AXIS / MUON-VARIANT

**Mechanism summary:**
After Newton-Schulz 5 produces the orthogonalized matrix O_t, right-multiply by a diagonal scaling matrix D_t whose j-th entry is derived from the per-column second moment of G_t:
  d_j = clamp( ||[G_t]_j|| / (sqrt(v_hat_tj) + eps), d_min, d_max )
  Theta_t = Theta_{t-1} - eta * O_t * D_t

This preserves the orthogonal geometry of O_t while re-introducing column-wise scale information that NS5 discards. Different columns correspond to different "output neurons" — this lets columns with historically high-gradient outputs grow faster.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster operates on denominator/masking of the AUXILIARY (AdamW) track. NAMO-D operates exclusively on the BODY Muon track via post-NS5 right-multiplication. Newton-Muon (merged) uses activation-based right-precond; NAMO-D uses gradient-norm-based column scaling. These are complementary and in principle stackable (though the 4-arm design tests NAMO-D alone first).

**Key references:**
- "Adam Improves Muon for Minimizing Tensor Loss Functions" (arxiv:2602.17080, 2026). NAMO-D: GPT-2 124M val perplexity 3.0246 vs Muon baseline 3.0435 (~0.6% improvement). Ablations confirm per-column (not per-element) scaling is optimal; full AdamW post-NS5 hurts.

**Implementation sketch:**
```
NANOGPT_NAMO_D=1                    # enable NAMO-D column scaling
NANOGPT_NAMO_D_BETA2=0.95           # column second-moment EMA
NANOGPT_NAMO_D_EPS=1e-8
NANOGPT_NAMO_D_CLAMP_MIN=0.1        # d_j clamp range
NANOGPT_NAMO_D_CLAMP_MAX=10.0
```

Pseudocode (after `zeropower_via_newtonschulz5` returns O):
```python
if namo_d:
    # G is the raw gradient, shape (d_out, d_in)
    col_norm = G.norm(dim=0)                    # shape (d_in,)
    v_col = beta2 * v_col_state + (1 - beta2) * (col_norm ** 2)
    v_col_state.copy_(v_col)
    d = (col_norm / (v_col.sqrt() + eps)).clamp(d_min, d_max)
    update = O * d.unsqueeze(0)                 # broadcast along rows
else:
    update = O
param.data.add_(update, alpha=-lr)
```

**4-arm screen design:**
- Arm A (ctrl): baseline Newton-Muon only
- Arm B: NAMO-D, β2=0.95, clamp [0.1, 10.0]
- Arm C: NAMO-D, β2=0.99, clamp [0.1, 10.0]
- Arm D: NAMO-D + Newton-Muon stacked (both enabled): right-precond input activation AND column-wise post-NS5 scale

**Expected signal direction:**
Arm B or C should improve on baseline. Arm D tests whether the two preconditioners are orthogonal and stackable.

---

## Hypothesis 3: TOKEN-FREQ-AWARE-WD

**Axis tag:** TOKEN-FREQUENCY-AWARE-WD / LM-HEAD-REGULARIZATION

**Mechanism summary:**
Standard weight decay on lm_head applies uniform L2 shrinkage to every token embedding row, which disproportionately penalizes rare tokens (their rows carry the most gradient signal per update but get shrunk equally). Inverse-frequency row scaling lets rare-token rows decay less:
  WD_k = wd_base * (freq_k / freq_max)^gamma      # gamma in [0.3, 0.7]
This is implemented as a per-row multiplicative mask on the WD term, applied only to lm_head, while all other AdamW parameters keep standard WD.

**Why mechanism-distinct from saturated cluster and #1192:**
PR #1192 (catastrophic) equalized row L2 NORMS via explicit normalization — it destroyed the Zipfian magnitude structure entirely. This hypothesis does the opposite: it preserves Zipfian magnitude structure (high-freq rows stay large, low-freq rows stay smaller) while only reducing the WD coefficient for low-freq rows. The mechanism is in the regularization schedule, not the parameter values.

**Key references:**
- "The Fair LM Paradox" (arxiv:2410.11985, 2025): Shows standard WD creates a fairness–perplexity tradeoff for rare tokens. Inverse-frequency WD scaling preserves rare-token representation without hurting aggregate perplexity.
- Zipfian token distribution in natural language (Zipf 1935 / Mandelbrot 1953): ~80% of tokens are in the bottom 20% by frequency; uniform WD makes ~80% of lm_head rows under-represented.

**Implementation sketch:**
```
NANOGPT_TF_WD=1                     # enable token-frequency WD scaling
NANOGPT_TF_WD_GAMMA=0.5             # exponent; 0=uniform, 1=full inverse scaling
NANOGPT_TF_WD_BASE=0.1              # base WD (same as current AdamW WD)
```

Pseudocode (in AdamW update for lm_head):
```python
if tf_wd and param_name == 'lm_head.weight':
    freq = token_frequencies  # precomputed from FineWeb, shape (vocab,)
    freq_norm = freq / freq.max()
    wd_mask = (freq_norm ** gamma).unsqueeze(1)  # (vocab, 1)
    param.data.mul_(1 - lr * wd_base * wd_mask)
else:
    param.data.mul_(1 - lr * weight_decay)
```

Note: token_frequencies must be computed once from the FineWeb tokenizer distribution and stored as a buffer. Use `tiktoken` to tokenize a 10M sample and compute counts.

**4-arm screen design:**
- Arm A (ctrl): standard WD on all params (baseline)
- Arm B: TF-WD on lm_head only, gamma=0.3
- Arm C: TF-WD on lm_head only, gamma=0.5
- Arm D: TF-WD on lm_head only, gamma=0.7

**Expected signal direction:**
Small improvement in val/loss driven by better calibration of rare-token representations. Primary signal may be in per-token perplexity distribution (rare-token perplexity improves while common-token perplexity is unchanged).

---

## Hypothesis 4: ADEMAMIX-AUX-SLOW-MOMENTUM

**Axis tag:** DUAL-MOMENTUM / AUX-OPTIMIZER

**Mechanism summary:**
Replace AdamW on the auxiliary track (embed, lm_head, scalars) with AdEMAMix, which adds a slow EMA of gradients m2 (β3=0.999) mixed into the numerator:
  θ(t) = θ(t-1) - η · ((m̂1(t) + α·m2(t)) / (√ν̂(t) + ε) + λ·θ(t-1))
The slow EMA accumulates gradient history over ~1000+ steps, improving convergence on parameters that change slowly (like embeddings). α controls the blend; at α=0 this reduces to standard AdamW.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster tested MARS (gradient correction), AdaBelief (variance-sensitive denominator), Cautious masking, v_min floor — all single-momentum modifications. AdEMAMix uses a fundamentally different structure: two separate momentum streams operating at different timescales. The slow stream m2 acts as a long-range gradient memory, not a variance estimator or gradient correction.

**Key references:**
- "AdEMAMix Optimizer" (arxiv:2409.03137, 2024, Pagliardini et al. ICLR 2025): 2x speedup vs Adam on C4 pre-training. β3=0.999 variant works on shorter training horizons.

**Implementation sketch:**
```
NANOGPT_ADEMAMIX_AUX=1              # enable AdEMAMix on aux track only
NANOGPT_ADEMAMIX_BETA3=0.999        # slow EMA decay
NANOGPT_ADEMAMIX_ALPHA=5.0          # blend weight for slow EMA
NANOGPT_ADEMAMIX_ALPHA_SCHEDULE=1   # linear warmup of alpha (0->alpha) over first 500 steps
```

Critical: α must be warmed up over the first ~500 steps (not applied at full value from step 0), otherwise the cold slow EMA m2 introduces high-variance updates early. Linear warmup from α=0 to α=5 over 500 steps is sufficient.

Pseudocode:
```python
# aux param update
m1 = beta1 * m1 + (1 - beta1) * grad
m2 = beta3 * m2 + (1 - beta3) * grad    # slow EMA
v  = beta2 * v  + (1 - beta2) * grad**2
m1_hat = m1 / (1 - beta1**t)
v_hat  = v  / (1 - beta2**t)
alpha_t = alpha * min(1.0, t / alpha_warmup_steps)
update = (m1_hat + alpha_t * m2) / (v_hat.sqrt() + eps)
param.data.add_(-(lr * update + lr * wd * param.data))
```

**4-arm screen design:**
- Arm A (ctrl): standard AdamW on aux
- Arm B: AdEMAMix, β3=0.999, α=3, 500-step warmup
- Arm C: AdEMAMix, β3=0.999, α=5, 500-step warmup
- Arm D: AdEMAMix, β3=0.999, α=8, 500-step warmup

**Expected signal direction:**
Improvement in embed/lm_head convergence, visible as lower val/loss at 3350 steps. Risk: 3350 steps may be too short for the slow EMA to accumulate enough signal (β3=0.999 → ~1000-step effective horizon = 30% of run). Monitor early steps for divergence.

---

## Hypothesis 5: NORMUON-ROW-NORM-POST-NS5

**Axis tag:** MUON-VARIANT / POST-NS5-NORMALIZATION

**Mechanism summary:**
After Newton-Schulz 5 produces the orthogonalized update O_t, normalize each row of O_t by its historical L2 norm estimate (computed as an EMA of per-row norms). This keeps per-neuron update magnitude stable across layers with different weight scales:
  norm_i(t) = EMA(||[O_t]_i||, t)
  Ô_t[i] = O_t[i] / (norm_i(t) + eps)
Unlike #1192 which normalized the PARAMETER rows, this normalizes the UPDATE rows — a fundamentally different target.

**Why mechanism-distinct from saturated cluster and #1192:**
#1192 normalized lm_head PARAMETER rows to equal norms — it destroyed the learned magnitude structure. NorMuon normalizes the UPDATE (O_t), not the parameters. The parameters retain their Zipfian structure; only the step sizes are equalized per neuron. Distinct from Muon2 (which acts pre-NS5 element-wise) and NAMO-D (column-wise post-NS5).

**Key references:**
- "NorMuon: Normalized Muon" (arxiv:2510.05491, 2025): Row-wise normalization of the NS5 output using per-neuron second moment tracking. Validated on GPT-2 scale.

**Implementation sketch:**
```
NANOGPT_NORMUON=1                   # enable NorMuon post-NS5 row normalization
NANOGPT_NORMUON_BETA=0.95           # EMA decay for row norm estimates
NANOGPT_NORMUON_EPS=1e-8
```

```python
if normuon:
    row_norms = O.norm(dim=1, keepdim=True)        # (d_out, 1)
    norm_ema = beta * norm_ema_state + (1 - beta) * row_norms
    norm_ema_state.copy_(norm_ema)
    O = O / (norm_ema + eps)
param.data.add_(O, alpha=-lr * scale)
```

**4-arm screen design:**
- Arm A (ctrl): Newton-Muon baseline
- Arm B: NorMuon only (no Newton-Muon), β=0.95
- Arm C: NorMuon + Newton-Muon stacked, β=0.95
- Arm D: NorMuon only, β=0.99

**Expected signal direction:**
Arm C (stacked) is the primary bet: NorMuon stabilizes per-neuron step sizes while Newton-Muon provides activation-aware right-preconditioning. If the two complement each other, Arm C should be lower than Newton-Muon baseline.

---

## Hypothesis 6: SCHEDULE-FREE-ADAMW-AUX

**Axis tag:** SCHEDULE-FREE-OPTIMIZER

**Mechanism summary:**
Replace the AdamW + cosine-annealing schedule on the auxiliary track with Schedule-Free AdamW (Defazio, 2024), which eliminates the LR schedule via primal-dual iterate averaging. The optimizer maintains two iterate sequences: the standard descent iterates z_t and the averaged iterates x_t (used for evaluation and loss computation):
  z_{t+1} = z_t - η · adam_update(z_t)
  x_{t+1} = (1 - c_{t+1}) · x_t + c_{t+1} · z_{t+1}
where c_t = 1/(t^β) (polynomial averaging). No warmup, no decay, no schedule.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster modified gradient corrections or denominator terms (all within the optimizer update rule). Schedule-Free operates at the iterate level, not the gradient processing level. The fundamental change is that LR is constant and convergence is driven by averaging trajectory, not decay schedule.

**Key references:**
- "Schedule-Free Learning: A New Paradigm" (arxiv:2405.15682, Defazio et al. 2024): Won AlgoPerf 2024 self-tuning track. Consistent improvement over cosine schedule on NLP and vision tasks.

**Implementation sketch:**
```
NANOGPT_SF_AUX=1                    # enable Schedule-Free AdamW on aux track
NANOGPT_SF_AUX_BETA=0.9             # averaging momentum (c_t parameter)
NANOGPT_SF_AUX_WARMUP=200           # linear warmup steps (Schedule-Free still benefits from LR warmup)
```

Key implementation note: Schedule-Free requires switching the model to "eval mode" by calling `optimizer.eval()` before any validation forward pass, which activates x_t (averaged weights) instead of z_t. Forgetting this is the most common failure mode — validation will measure suboptimal z_t weights.

**4-arm screen design:**
- Arm A (ctrl): AdamW + cosine schedule on aux (baseline)
- Arm B: Schedule-Free AdamW on aux, β=0.9, lr_sf=same as current aux_lr_max
- Arm C: Schedule-Free AdamW on aux, β=0.95, lr_sf=0.8x current aux_lr_max
- Arm D: Schedule-Free AdamW on aux, β=0.9, lr_sf=1.2x current aux_lr_max (wider exploration since no decay floor)

**Expected signal direction:**
Schedule-free on aux may improve embed/lm_head convergence by eliminating schedule mismatch. Aux params converge on a different timescale than body params; removing the shared schedule constraint is theoretically beneficial.

---

## Hypothesis 7: GRADIENT-CENTRALIZATION-PRE-NS5

**Axis tag:** GRADIENT-CENTRALIZATION / MUON-VARIANT

**Mechanism summary:**
Before feeding the momentum buffer M_t to Newton-Schulz 5, subtract row means to enforce zero-row-mean constraint:
  M̃_t[i] = M_t[i] - mean(M_t[i])   (for each row i)
  O_t = NS5(M̃_t)
Gradient centralization (GC) was introduced for CNNs as a geometric constraint that projects gradients onto a hypersphere subspace. In the Muon context, applying GC pre-NS5 means the orthogonalization acts on centered rows, which may reduce the bias toward high-norm momentum directions.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster operated on denominator terms or masking in Adam updates. GC is a pre-NS5 geometric transformation on the body Muon momentum. Distinct from Muon2 (element-wise pre-NS5 scaling vs row-mean subtraction). PR #944 was listed as "never ran" — this is a completely untested direction.

**Key references:**
- "Gradient Centralization" (Yong et al., ECCV 2020, arxiv:2004.01461): Zero-mean row constraint improves training stability and convergence in CNNs and transformers. Drop-in, zero overhead.
- Interaction with NS5: GC makes the momentum matrix more "centered" which may improve the condition number of the input to NS5 (NS5 converges faster on matrices closer to orthogonal structure).

**Implementation sketch:**
```
NANOGPT_GC_PREMUON=1                # enable gradient centralization pre-NS5
NANOGPT_GC_PREMUON_DIM=rows         # which dim to center: 'rows', 'cols', or 'both'
```

```python
if gc_premuon:
    if gc_dim in ('rows', 'both'):
        buf = buf - buf.mean(dim=1, keepdim=True)
    if gc_dim in ('cols', 'both'):
        buf = buf - buf.mean(dim=0, keepdim=True)
orth_grad = zeropower_via_newtonschulz5(buf, steps=5)
```

**4-arm screen design:**
- Arm A (ctrl): no GC (baseline Newton-Muon)
- Arm B: GC row-centering only
- Arm C: GC column-centering only
- Arm D: GC both (doubly-centered = full centering)

**Expected signal direction:**
Row-centering (Arm B) is the most theoretically grounded and likely to help. Column-centering may hurt by removing useful column-scale information. Arm D is exploratory.

---

## Hypothesis 8: SOPHIA-HESSIAN-AUX

**Axis tag:** CURVATURE-AWARE / AUX-OPTIMIZER

**Mechanism summary:**
Replace AdamW on the auxiliary track with Sophia (Liu et al. 2023), which uses a diagonal Hessian estimate as the denominator instead of the squared gradient:
  h_t = Hutchinson_estimate(H_t)      (estimated every K=10 steps)
  theta_{t+1} = theta_t - eta * clip( m_hat_t / (gamma * h_t + eps), 1 )
The Hutchinson estimator uses a random unit vector u ~ N(0,I) and computes u^T H u via two backward passes (one for gradient, one for gradient-vector product), giving an unbiased diagonal Hessian estimate at K-step intervals.

**Why mechanism-distinct from saturated cluster:**
All saturated cluster experiments modified gradient first/second moments (MARS, AdaBelief) or masking (Cautious). Sophia uses the actual curvature (Hessian diagonal) as the denominator, not gradient variance. On embed and lm_head, curvature differs substantially from gradient variance due to frequency imbalance — Sophia's Hessian estimate should be better calibrated for these layers.

**Key references:**
- "Sophia: A Scalable Stochastic Second-Order Optimizer for Language Model Pre-Training" (arxiv:2305.14342, Liu et al. 2023): 2x training speedup vs AdamW on GPT-2 pre-training benchmarks. Published in ICML 2024.

**Implementation sketch:**
```
NANOGPT_SOPHIA_AUX=1                # enable Sophia on aux track
NANOGPT_SOPHIA_K=10                 # Hessian update interval (steps)
NANOGPT_SOPHIA_GAMMA=0.01           # Sophia scale factor (typical: 0.01-0.05)
NANOGPT_SOPHIA_RHO=0.04             # clip threshold
```

Critical implementation note: Sophia requires computing `grad_vec_product = torch.autograd.grad(grads, params, grad_outputs=u)` for the Hutchinson estimate. This requires retaining the computational graph every K steps. The training loop must call `loss.backward(retain_graph=True)` on Sophia-Hessian update steps — this must be conditionally enabled only when step % K == 0. Failure to retain graph on Hutchinson steps causes a runtime error.

**4-arm screen design:**
- Arm A (ctrl): AdamW on aux (baseline)
- Arm B: Sophia-AUX, K=10, gamma=0.01, rho=0.04
- Arm C: Sophia-AUX, K=20, gamma=0.01, rho=0.04
- Arm D: Sophia-AUX, K=10, gamma=0.05, rho=0.04

**Expected signal direction:**
K=10 (Arm B) should show cleaner convergence on embed and lm_head. If gamma is too small (Arm B), Sophia degenerates to AdamW; if too large (Arm D), clipping triggers excessively. K=20 (Arm C) reduces overhead.

---

## Hypothesis 9: GHOST-STEPS-V0-WARMSTART

**Axis tag:** INITIALIZATION / SECOND-MOMENT-WARMSTART

**Mechanism summary:**
Before the first real training step, run K "ghost passes" through synthetic/real data batches to accumulate the AdamW second moment v_0 without updating parameters. This eliminates the cold-start bias in Adam where v_0 = 0 causes artificially large steps in early training — the bias correction 1/(1-β2^t) partially compensates but doesn't correct for the true data distribution. After K ghost steps, v_0 is already well-estimated and training begins from a more calibrated gradient scale.

**Why mechanism-distinct from saturated cluster:**
All saturated cluster ideas modified ongoing optimizer dynamics. Ghost steps act at initialization only — they change the initial state of the optimizer, not the update rule. After ghost steps, training is standard AdamW. Distinct from v_min floor (#1175, NULL): that hypothesis added a hard floor to v at every step; ghost steps only affect initialization.

**Key references:**
- "Warmstarting Second Moments in Adam" (arxiv:2412.02153, 2024): Ghost steps reduce the Adam cold-start bias measurably on transformer pre-training. PR #603 in this repo was never run.

**Implementation sketch:**
```
NANOGPT_GHOST_STEPS=50              # number of pre-training ghost steps
NANOGPT_GHOST_BETA2=0.999           # use high beta2 to accumulate v aggressively
```

```python
# Before training loop:
if ghost_steps > 0:
    model.eval()
    with torch.no_grad():
        for _ in range(ghost_steps):
            batch = next(data_iter)
            with torch.enable_grad():
                loss = model(batch)
                grads = torch.autograd.grad(loss, aux_params)
            for p, g in zip(aux_params, grads):
                optim_state[p]['v'] = ghost_beta2 * optim_state[p]['v'] + (1 - ghost_beta2) * g**2
    model.train()
    # Reset param update counters but keep v state
    for p in aux_params:
        optim_state[p]['step'] = 0
        optim_state[p]['m'] = torch.zeros_like(p)
```

**4-arm screen design:**
- Arm A (ctrl): no ghost steps
- Arm B: K=50 ghost steps on aux params only
- Arm C: K=100 ghost steps on aux params only
- Arm D: K=50 ghost steps on ALL params (aux + body Muon v state)

**Expected signal direction:**
Reduction in val/loss at early checkpoints (steps 500-1000), persisting to the end. If ghost steps eliminate early instability, first_step_to_target may improve even if terminal val/loss difference is small.

---

## Hypothesis 10: ORTHOGRAD-LMHEAD-EMBED

**Axis tag:** GRADIENT-ORTHOGONALIZATION / WEIGHT-ORTHOGONAL-PROJECTION

**Mechanism summary:**
Before the AdamW update on lm_head and embed, project the gradient to be orthogonal to the current weight vector (per row):
  g_orth[i] = g[i] - (g[i] · w[i] / ||w[i]||^2) * w[i]
This ensures updates move the weights tangentially along their hypersphere rather than toward/away from origin, preventing the optimizer from "shrinking" or "growing" the embedding norm. Different from weight decay (which shrinks toward zero) and from row normalization (which normalizes the parameter directly).

**Why mechanism-distinct from saturated cluster and #1192:**
#1192 normalized the parameter rows — catastrophic because it destroyed Zipfian magnitude distribution. OrthoGrad normalizes the GRADIENT direction, not the parameter. The parameters change in norm naturally through training; OrthoGrad only prevents the gradient from having a radial (norm-changing) component. Distinct from GC (row-mean subtraction) and from any saturated cluster mechanism.

**Key references:**
- "OrthoGrad: Orthogonal Gradient Descent" (arxiv:2506.04487, 2025): Optimizer-agnostic projection, consistent improvement on LLM fine-tuning. PR #477 in this repo was never run.

**Implementation sketch:**
```
NANOGPT_ORTHOGRAD_AUX=1             # enable OrthoGrad on aux params
NANOGPT_ORTHOGRAD_EPS=1e-8          # denominator floor
```

```python
def orthograd_project(grad, param):
    # Project grad orthogonal to param direction (row-wise)
    # grad, param: (vocab, d_model) for lm_head
    w_norm_sq = (param * param).sum(dim=1, keepdim=True)  # (vocab, 1)
    proj = (grad * param).sum(dim=1, keepdim=True) / (w_norm_sq + eps)
    return grad - proj * param

# Before AdamW update:
if orthograd_aux:
    for name, p in model.named_parameters():
        if name in ('lm_head.weight', 'transformer.wte.weight') and p.grad is not None:
            p.grad.data = orthograd_project(p.grad.data, p.data)
```

**4-arm screen design:**
- Arm A (ctrl): standard AdamW on aux
- Arm B: OrthoGrad on lm_head only
- Arm C: OrthoGrad on embed (wte) only
- Arm D: OrthoGrad on both lm_head and embed

**Expected signal direction:**
Arm B (lm_head) is the primary bet — lm_head rows have the most Zipfian structure and the most to lose from radial gradient components. Improvement in val/loss and potentially large improvement in rare-token perplexity.

---

## Hypothesis 11: ADAGO-GLOBAL-NORM-LR-MUON

**Axis tag:** ADAPTIVE-LR / GLOBAL-GRADIENT-NORM

**Mechanism summary:**
Replace the fixed Muon body LR schedule with AdaGO: an AdaGrad-style global scalar accumulation of gradient norms. At each step, compute the global gradient norm ||G_t||, accumulate v_t² = v_{t-1}² + min(||G_t||², γ²), and use LR = max(ε, η·min(||G_t||, γ) / v_t). This adaptively reduces the LR when gradients are large and consistently large, preventing overshooting, while maintaining high LR during gradient spikes (exploration). γ clips extreme norms.

**Why mechanism-distinct from saturated cluster:**
The saturated cluster operated on ELEMENT-WISE or per-parameter denominator modifications. AdaGO uses a single global scalar, making it O(1) overhead and a completely different adaptive axis. No per-parameter state beyond the global v scalar.

**Key references:**
- "AdaGO: Adaptive Global Optimizer" (arxiv:2509.02981, 2025): Tested on CIFAR-10 and regression; not yet tested on LLM pre-training. The mechanism is general and the LLM application is genuinely novel.

**Implementation sketch:**
```
NANOGPT_ADAGO_MUON=1                # enable AdaGO LR scaling on Muon body
NANOGPT_ADAGO_GAMMA=1.0             # gradient norm clip threshold
NANOGPT_ADAGO_EPS=1e-8
```

```python
# Replace Muon body LR computation:
if adago_muon:
    g_norm = sum(p.grad.norm()**2 for p in body_params).sqrt()
    v_adago = (v_adago**2 + min(g_norm, gamma)**2).sqrt()
    lr_eff = max(eps, lr_base * min(g_norm, gamma) / v_adago)
else:
    lr_eff = lr_schedule[step]
# Apply lr_eff to Muon body update
```

**4-arm screen design:**
- Arm A (ctrl): standard Muon body LR schedule
- Arm B: AdaGO, γ=1.0
- Arm C: AdaGO, γ=0.5
- Arm D: AdaGO, γ=2.0

**Expected signal direction:**
If gradient norms fluctuate during training (check W&B `grad_norm` trace), AdaGO should reduce instability and improve final convergence. Arm B or C is most likely to help.

---

## Hypothesis 12: MUON-PERIOD-ADAPTIVE-SCHEDULER

**Axis tag:** LAYERWISE-MUON-VARIANTS / ADAPTIVE-PRECONDITIONING-SCHEDULE

**Mechanism summary:**
The Newton-Muon preconditioner R = EMA(X^T X) is currently updated every PERIOD=10 steps (fixed). Instead, update R adaptively: trigger an R recompute whenever the cosine similarity between consecutive body gradients drops below a threshold, signaling a "regime change" that invalidates the current R. This avoids staleness after learning rate cooldown (when gradients change direction rapidly) while reducing overhead during stable phases. This is related to the adaptive preconditioner update frequency literature (SOAP, CASPR).

**Why mechanism-distinct from saturated cluster:**
This is a meta-level modification to the Newton-Muon preconditioning schedule itself — not a modification to any optimizer denominator, gradient masking, or weight decay. It has no analog in any prior PR. The factorial sweep in #1240 tests discrete PERIOD values; this tests an adaptive trigger condition.

**Key references:**
- "SOAP: Improving and Stabilizing Shampoo using Adam in the Projected Space" (arxiv:2409.11321, 2024): Introduces adaptive preconditioning update frequency.
- "CASPR" (arxiv:2501.03458, 2025): Cost-adaptive preconditioner update scheduling.

**Implementation sketch:**
```
NANOGPT_NEWTON_MUON_ADAPTIVE_PERIOD=1    # enable adaptive period (overrides PERIOD)
NANOGPT_NEWTON_MUON_COSIM_THRESHOLD=0.9  # trigger R update when grad cosim < threshold
NANOGPT_NEWTON_MUON_MIN_PERIOD=5         # minimum period (hard lower bound)
NANOGPT_NEWTON_MUON_MAX_PERIOD=50        # maximum period (hard upper bound)
```

```python
# Compute cosine similarity between current and previous gradient
if adaptive_period:
    cosim = F.cosine_similarity(G_flat, G_prev_flat, dim=0)
    should_update_R = (cosim < cosim_threshold) or (steps_since_R_update >= max_period)
    if steps_since_R_update < min_period:
        should_update_R = False
else:
    should_update_R = (step % period == 0)
```

**4-arm screen design:**
- Arm A (ctrl): Newton-Muon PERIOD=10 (current baseline)
- Arm B: Adaptive period, cosim_threshold=0.9, min=5, max=50
- Arm C: Adaptive period, cosim_threshold=0.95, min=5, max=30
- Arm D: Adaptive period, cosim_threshold=0.8, min=10, max=100

**Expected signal direction:**
Reduced stale preconditioning during cooldown phase, better tracking of curvature changes. Arm B is the primary bet. If the W&B traces from #1138 show gradient direction changes correlating with loss spikes, this is highly motivated.

---

## Priority Ranking

Ranked by: mechanism distinctness + external evidence strength + implementation feasibility + risk-adjusted expected gain.

1. **Muon2-Pre-NS5-Adaptive** (H1): Strong external evidence (arxiv:2604.09967 with ablations), clean mechanism, moderate implementation complexity. Top pick.
2. **NAMO-D-Post-NS5-Column** (H2): Strong evidence (GPT-2 124M 0.6% improvement in paper), direct LLM validation, stackable with Newton-Muon (Arm D tests stacking). Top pick.
3. **Schedule-Free-AdamW-Aux** (H6): Won AlgoPerf 2024 self-tuning track, zero added complexity over current setup, clear mechanism for aux track.
4. **Gradient-Centralization-Pre-NS5** (H7): Zero overhead, theoretically grounded, PR #944 never ran — low cost, may have been overlooked.
5. **Token-Freq-Aware-WD** (H3): Mechanism-distinct from catastrophic #1192, strong theoretical basis (Zipfian structure preservation), implementable with precomputed frequency buffer.
6. **OrthoGrad-LmHead-Embed** (H10): PR #477 never ran, direct application to the layers with most Zipfian structure, optimizer-agnostic.
7. **NorMuon-Row-Norm** (H5): Arm C (stacked with Newton-Muon) is a natural complementary extension, but risk of interaction effects.
8. **AdEMAMix-Aux-Slow-Momentum** (H4): Strong prior results but designed for longer training; β3=0.999 + scheduling mitigates risk.
9. **Ghost-Steps-V0-Warmstart** (H9): PR #603 never ran, theoretically clean, diagnostic value high (does cold-start explain early instability?).
10. **Sophia-Hessian-Aux** (H8): Strongest theoretical grounding (true curvature), but implementation requires retain_graph which adds memory overhead.
11. **AdaGO-Global-Norm-LR** (H11): Novel for LLMs, no prior LLM evidence, but O(1) overhead and fully reversible.
12. **Muon-Period-Adaptive-Scheduler** (H12): Builds directly on Newton-Muon (merged #1138), but #1240 is already running the factorial, so wait for #1240 results before assigning this.
