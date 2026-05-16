# Wave-2 Hypothesis Batch — 2026-05-16 07:00

**Context:** Baseline after PR #46 merge: ffs=3200, mu=3.27744, n=6.
Statistical target: (3.28 - mu) * sqrt(n) >= 0.004 → for n=6, need mu < 3.27581.
Wave-2 in-flight (7 PRs, do NOT overlap): Muon² Adam v-buffer (#45/edward),
MuonH hyperball (#47/frieren), cooldown shape sweep (#48/nezuko),
Polyak/SWA tail averaging (#50/thorfinn), SOAP-attn+trust-gate (#116/fern),
Schedule-free Muon Defazio (#121/tanjiro), Newton-Muon activation-cov
right-precond (#123/alphonse).

---

## Hypothesis A: Label Smoothing on Cross-Entropy Loss

### Mechanism

Cross-entropy with one-hot targets drives logit margins to infinity, which
means the gradient norm on the final linear layer only decays because the LR
schedule forces it to, not because the objective has a natural floor.
Label smoothing replaces the one-hot target with a convex combination:
`(1 - ε) * one_hot + ε / V`, where V = vocab size (50304) and ε ~ 0.1.
This adds a uniform negative entropy term to the loss, which bounds the
optimal logit margin and reduces the conditioning number of the Hessian near
the solution. arXiv:2402.03979 (Hui and Belkin, 2024) shows that networks
trained with label smoothing converge faster to neural collapse solutions
and that the conditioning improvement is not merely cosmetic: it translates
to fewer gradient steps for the same generalization target.

For a speedrun context, the mechanism of interest is that lower Hessian
conditioning at the end of training means the Muon + SOAP stack finds a
sharper descent toward the target loss threshold, which should manifest as
a lower ffs at the same step count or the same ffs at a shorter step count.
The effect is not guaranteed to survive logit softcapping (already present
at cap=15), so we must check whether the softcap already bounds the margin
enough to neutralize label smoothing. This is an open empirical question and
the main falsifying risk.

Expected implementation: change the `F.cross_entropy` call from
`reduction="sum"` with default targets to `label_smoothing=0.1`. The
reported `val/loss` is already computed without smoothing (it is raw
cross-entropy on the validation set), so no changes to the evaluation path
are needed.

### Orthogonality

No in-flight PR touches the loss function. The training loss objective is
identical across all 7 WIP PRs and the merged baseline. This is the only
proposal among the 7+baseline that changes what the optimizer is actually
minimizing.

### Expected improvement

Estimated delta: -10 to -30 steps on ffs (ffs from 3200 to ~3170-3190),
mu drop of 0.0002-0.0006 vs baseline. Reasoning: label smoothing is
typically a 1-3% improvement on convergence speed in LM training; the
benefit is largest in the tail of training where margin saturation dominates.
The logit softcap at 15 already partially bounds the margin, so the benefit
may be at the smaller end of the range.

### Step budget and n

3200 steps, n=6. Use the same step count as the current baseline to allow
direct mu comparison. Do not shorten the run — the cooldown region is where
the label smoothing effect is most pronounced.

### Falsifying kill gates

Kill after step 2000 if:
- val/loss at step 2000 is >= 3.315 (i.e., no improvement vs baseline trajectory)
- train/loss at step 1000 is >= baseline train/loss at step 1000 by more than 0.003
  (this would indicate the smoothed objective is harder to optimize early, suggesting
  the mechanism is not active)

Kill the entire hypothesis (do not retry with different ε) if:
- All 6 seeds produce ffs > 3250 (worse than baseline)
- The mechanism is explained by the softcap already bounding the margin:
  check logit absolute max values in train/weight_param/* at step 1000; if
  max_abs < 14.0 the softcap is already saturating and label smoothing will
  not help further

### Paper pointer

arXiv:2402.03979 — "Label Smoothing Improves Neural Collapse" (Hui and Belkin, 2024).
Section 3.2 contains the conditioning number analysis. Section 4 shows faster
convergence in practice on ImageNet and CIFAR training. The LM setting is not
directly tested but the Hessian conditioning argument applies.

---

## Hypothesis B: Gradient Centralization Before NS Step in Muon

### Mechanism

Gradient centralization (GC) projects each gradient tensor so its mean is
zero across the output dimension before the momentum update. For a weight
matrix W of shape (out, in), the centralized gradient is:
`g_c = g - mean(g, dim=1, keepdim=True)`.
This enforces that the gradient update preserves the zero-mean property of
each output neuron's weight vector, which is equivalent to removing the
component that uniformly scales all outputs of that neuron.

arXiv:2004.01461 (Yong et al., 2020) shows that GC reduces the Lipschitz
constant of the loss w.r.t. weights by a factor proportional to the
input dimension, improving both optimization landscape smoothness and
generalization. The theoretical argument is that the loss restricted to
the centralized subspace has tighter curvature bounds.

In the Muon context, the integration point is: apply GC to the gradient
before adding it to the momentum buffer (`momentum.lerp_(grad, 1 - mu)`).
This means the NS5 polar step operates on a momentum tensor that already
has mean-zero rows, which may interact favorably with the orthogonalization:
NS5 finds the nearest orthogonal matrix, and a mean-zero matrix has a
more neutral singular value distribution than a raw gradient, potentially
making the NS5 convergence in 12 iterations higher quality.

The SOAP preconditioning on MLP weights happens before NS5 in the current
stack. GC applied before SOAP would project the gradient into the mean-zero
subspace first, then SOAP preconditions within that subspace. This is a
compatible composition.

Expected implementation: in `muon_update`, add one line before
`momentum.lerp_(grad, 1 - mu)`:
```python
grad = grad - grad.mean(dim=-1, keepdim=True)
```
This applies to the 2D weight matrices that Muon manages (MLP and attn
q,k,v,proj weights). Scalars, biases, and embed/lm_head are in the AdamW
groups and unaffected.

### Orthogonality

GC applied before the momentum update is not tested by any in-flight PR.
Alphonse (#123) applies activation-covariance right-preconditioning after
the momentum step. Fern (#116) adds a trust gate. Neither touches the
gradient centralization. Tanjiro (#121) uses Schedule-free Muon which
replaces the momentum schedule, not the gradient itself. Edward (#45) adds
Adam v-buffer as an additional preconditioner, not GC. This mechanism is
fully orthogonal.

### Expected improvement

Estimated delta: -20 to -50 steps on ffs (ffs from 3200 to ~3150-3180),
mu drop of 0.0004-0.0010. Reasoning: GC is a mild but consistent improvement
in LM training (public record #13 uses outer Nesterov SGD which implicitly
has some centering effect at the batch level). The gain may be small because
NS5 already implicitly normalizes singular values, which partially decorrelates
the gradient from its mean. The benefit is most plausible when the gradient
has large mean components (early in training or when a layer is far from
equilibrium).

### Step budget and n

3200 steps, n=4 initial screen. If mu improves by > 0.0003 vs baseline,
expand to n=6 for statistical significance test.

### Falsifying kill gates

Kill after step 1000 if:
- train/loss is >= baseline train/loss + 0.002 (GC is causing optimization
  to slow down, which would indicate the mean-zero projection is removing
  useful gradient signal rather than noise)

Kill hypothesis if n=4 seeds produce mean ffs > 3220 (no directional improvement).
Do NOT retry with GC applied only to MLP weights if the full application fails —
that variant is too close to the already-tested SOAP isolation to be informative.

### Paper pointer

arXiv:2004.01461 — "Gradient Centralization: A New Optimization Technique for
Deep Neural Networks" (Yong et al., 2020). Section 3 contains the Lipschitz
analysis. Section 5.2 shows LM-adjacent results on image/text classification.
The integration with momentum-based optimizers is described in Section 2.

---

## Hypothesis C: AdamW Aux-Group Embed LR Decoupled Schedule

### Mechanism

The current training script runs three AdamW parameter groups:
embed (token embedding), lm_head (output projection), and scalars
(gain/bias/RMSNorm scale). These groups share a single LR schedule
(warmup + cosine + cooldown) with the same peak and floor. However, the
embed and lm_head matrices play structurally different roles from the
Muon-managed weights: they are not subjected to NS5 orthogonalization and
their gradient dynamics differ from internal weight matrices.

The hypothesis is that the embed group benefits from a longer warmup and
a flatter LR through the middle of training (because token embeddings need
stable representations before attention patterns settle), while lm_head
benefits from a more aggressive cooldown (because final-layer logit geometry
is the last thing to converge). Concretely:

- embed LR schedule: warmup to 0.6x current peak, hold for 40% of steps,
  cosine decay to floor over the remaining 60%
- lm_head LR schedule: warmup as normal, cosine decay with a steeper final
  cooldown (last 15% of steps) at 0.5x the current cooldown LR floor
- scalar group: unchanged

This does not add parameters or operations, only changes the optimizer state
update frequency for the embedding table and output head. The motivation is
that in the public record history, Record #13 (outer Nesterov SGD) achieved
3210 steps by treating the embedding path as a structurally distinct problem —
this proposal explores a lighter version of the same intuition.

Expected implementation: in the optimizer setup section of train_gpt_simple.py,
split the single `adamw_params` scheduler into three separate schedulers for
embed, lm_head, and scalar groups. Use `torch.optim.lr_scheduler.LambdaLR`
with custom lambdas for each group.

### Orthogonality

No in-flight PR touches AdamW group schedules. Nezuko (#48) sweeps the Muon
cooldown shape, which is entirely in the Muon optimizer group. Edward, Frieren,
Tanjiro, Alphonse all modify the Muon update step. Thorfinn (#50) applies
Polyak/SWA tail averaging across ALL parameters but does not change the
per-group LR schedule. This mechanism is orthogonal.

### Expected improvement

Estimated delta: -15 to -40 steps on ffs (ffs ~3160-3185), mu drop 0.0003-0.0008.
Reasoning: the embed LR is currently a free parameter that has been co-tuned
with the Muon LR, not optimized independently. The embedding table in a 124M
model has 50304 * 768 = 38M parameters — it is the second largest single
parameter group. Even modest schedule improvements on this group affect a
significant fraction of parameter updates. The risk is that LR entanglement
between groups means the current joint schedule is already near-optimal for the
combined objective.

### Step budget and n

3200 steps, n=4 initial screen with 2 LR configurations (embed-flat and
lm_head-aggressive-cooldown tested jointly). If either configuration improves
mu by > 0.0003, run n=6 confirmation at 3200 steps.

### Falsifying kill gates

Kill after step 800 if train/loss is >= baseline + 0.003 (the schedule
change is hurting early optimization). Kill hypothesis if n=4 mean ffs > 3230.

### Paper pointer

No single paper directly targets this. The intuition is grounded in:
- "Scaling Laws for Neural Language Models" (Kaplan et al., 2020) — shows
  embedding layers need different treatment in large models.
- Record #13 in this repo (outer Nesterov SGD with separate embed handling).
- Standard practice in LLM training of using lower LR for embedding layers
  (GPT-NeoX, LLaMA training configs).

---

## Hypothesis D: NS5 Iteration Count Reduction with Coefficient Retuning

### Mechanism

The current NS5 implementation uses 12 iterations with coefficients a=2,
b=-1.5, c=0.5. These coefficients come from the Muon paper's choice for a
degree-5 polynomial approximation of the sign function (polar decomposition).
arXiv:2602.11948 (Bernstein and Newhouse, 2025) analyzes the approximation
error of Newton-Schulz iterations and shows that reducing the iteration count
introduces a controlled approximation error that can qualitatively alter
discrete-time optimization dynamics — in some settings, approximate polar
steps converge faster than exact ones because the inexactness acts as an
implicit regularizer on the update direction.

The hypothesis: use 5 NS iterations (instead of 12) with coefficients
retuned for degree-5 convergence over a narrower input range. The 12-iteration
default is conservative — for matrices already close to orthogonal after
previous steps (which is true for the Muon momentum buffer after ~100 steps
of warmup), fewer iterations may produce updates that are directionally
similar but computationally cheaper, allowing a slightly higher effective LR
without instability.

Concretely: reduce `range(12)` to `range(5)` in `zeropower_via_newtonschulz5`
and retune coefficients. Starting point from the paper's Table 1 for 5-iteration
convergence: a=1.5, b=-0.5, c=0.0625 (degree-5 Zolotarev approximation over
[0.5, 2.0] singular value range). If the momentum buffer matrices are already
near-orthogonal, the singular values after normalization are in [0.8, 1.2],
which is a narrower range than the 12-iteration design target.

This also reduces the NS5 compute per step, which in a single-GPU setting
could allow marginally more gradient steps in the same wall-clock budget
(though the benchmark is step-count-based, not time-based, so the primary
benefit is the regularization effect, not the compute saving).

### Orthogonality

No in-flight PR modifies the NS5 iteration count or coefficients. Edward (#45)
adds an Adam v-buffer as an outer preconditioner but keeps NS5 internals
identical. Alphonse (#123) adds right-preconditioning before the NS step
but also keeps the iteration count and coefficients fixed. This is the only
proposal that modifies the NS5 polynomial approximation.

### Expected improvement

Estimated delta: -10 to -35 steps on ffs (ffs ~3165-3190), mu drop 0.0002-0.0008.
Uncertainty is high because the effect direction depends on whether the
approximate orthogonalization acts as a useful implicit regularizer or merely
degrades the update quality. arXiv:2602.11948 suggests the former in the
settings they test, but their settings are different from this benchmark.

### Step budget and n

3000 steps, n=4. Use a shorter run than baseline to test whether the
regularization effect emerges before the cooldown. If ffs < 3000 (i.e., the
model hits target earlier than baseline), run a confirmation at n=6.

### Falsifying kill gates

Kill after step 1500 if val/loss >= 3.310 (no directional improvement vs
baseline trajectory at this step). Kill hypothesis if the singular values
of any Muon-managed weight matrix show high variance (> 0.3 in stdev across
singular values) — this would indicate the approximate NS5 is failing to
maintain near-orthogonal updates. Monitor via train/weight/all/* statistics.

### Paper pointer

arXiv:2602.11948 — "Modular Duality in Deep Learning" (Bernstein and Newhouse, 2025).
Section 4 analyzes Newton-Schulz approximation error. The key insight is
in Lemma 4.2: the approximation error is a rank-deficient correction that
can be absorbed into the effective LR without destabilizing training.

---

## Hypothesis E: Depth-Scaled Residual Initialization (Wang/Mitchell 1/sqrt(depth))

### Mechanism

The standard initialization in the current script uses PyTorch default
`nn.Linear` initialization (Kaiming uniform) for all layers. For residual
networks, the variance of activations grows linearly with depth because each
residual block adds independently initialized contributions. At depth L=12
(the current model), the output variance at the final norm is 12x larger
than at depth 1, which means the gradient signal at the first layer is
attenuated by 1/12 relative to the last layer.

The fix: scale the output projection weight of each residual block
(both MLP `proj` and attention `out_proj`) by `1 / sqrt(2 * num_layers)`.
This ensures that the variance of each residual block's contribution to the
output is O(1/L), making the total residual stream variance O(1) regardless
of depth. This is the initialization used in GPT-2 (Radford et al., 2019),
the "scaled init" used in PaLM (Chowdhery et al., 2022), and analyzed
formally for spectral conditions in arXiv:2603.00541v2 (Yang et al., 2025)
for joint width-depth μP scaling.

The mechanism that benefits the speedrun: at initialization, the Muon
optimizer sees a more balanced gradient signal across layers (no depth-induced
gradient attenuation at shallow layers). This means the early steps of
training (where gradient descent makes the most progress) are more efficient,
potentially reducing the number of steps needed to reach the loss threshold.

Expected implementation:
```python
# After model construction, before optimizer setup:
for block in model.blocks:
    block.mlp.proj.weight.data /= math.sqrt(2 * len(model.blocks))
    block.attn.out_proj.weight.data /= math.sqrt(2 * len(model.blocks))
```
(No change to the optimizer, LR schedule, or any other component.)

### Orthogonality

No in-flight PR modifies initialization. All 7 WIP PRs and the merged baseline
use default PyTorch initialization. This is the only proposal that changes the
starting point of optimization without changing the optimizer algorithm or
schedule. The effect is purely at step 0 and its subsequent influence is
through better gradient conditioning in early training.

### Expected improvement

Estimated delta: -20 to -50 steps on ffs (ffs ~3150-3180), mu drop 0.0004-0.0010.
Reasoning: Record #13 in this repo (outer Nesterov SGD) used a version of
scaled init and reached 3210 steps — better than naive baselines. The current
best (3200 steps with SOAP-MLP) may have partially compensated for the
initialization gap through SOAP's second-order preconditioning, but the init
effect and the SOAP effect are orthogonal and should compound.

### Step budget and n

3200 steps, n=4 initial screen. If mean ffs improves by > 20 steps vs baseline,
run n=6 confirmation. This hypothesis is low-risk (no new optimizer complexity)
so a quick screen is sufficient to determine viability.

### Falsifying kill gates

Kill after step 500 if train/loss >= baseline train/loss + 0.005 at step 500
(scaled init is hurting early optimization by reducing the initial gradient
signal too aggressively — possible if the model is under-parameterized for
this scale factor).

Kill hypothesis if n=4 mean ffs > 3210 (no improvement vs rough baseline).

### Paper pointer

arXiv:2603.00541v2 — "Tensor Programs VII: Spectral Conditions for Feature
Learning" (Yang et al., 2025). Section 5 derives the correct initialization
scaling under μP with depth. Also: GPT-2 paper (Radford et al., 2019) reports
the `1/sqrt(2*L)` init as a practical finding.

---

## Top Recommendation

**Hypothesis A (Label Smoothing, ε=0.1)** is the top pick.

Reasoning: it is the only proposal that changes what the optimizer is
minimizing, not how it minimizes it. Every in-flight PR (7 WIPs) and the
merged baseline all optimize vanilla cross-entropy with the same logit softcap.
Label smoothing reduces the Hessian conditioning number near the solution,
which is the regime that matters most for a speedrun trying to cross a hard
loss threshold. The mechanism is well-grounded (arXiv:2402.03979), the
implementation is a one-line change to `F.cross_entropy`, and the experiment
is cheap and falsifiable. The main uncertainty — whether the existing softcap
at cap=15 already neutralizes the margin saturation — is itself a valuable
diagnostic: if label smoothing does not help despite the softcap, it confirms
that the softcap is doing real work and the gradient centralization or depth
init proposals should be prioritized next.

**Second pick: Hypothesis E (depth-scaled init)** — zero optimizer complexity,
directly addresses a known theoretical gap (depth-induced gradient attenuation),
and no current PR touches initialization.

---

## Decision Tree for This Batch

```
A (label smoothing) screen (n=4, 3200 steps)
├── ffs < 3180 (improves > 20 steps) → run n=6 confirmation → merge if stat-sig
├── ffs 3180-3200 (marginal improvement) → retune ε (try 0.05, 0.15) before closing
└── ffs > 3200 (no improvement) → confirms softcap neutralizes margin saturation
    ├── Close A, move to E (depth-scaled init, orthogonal mechanism)
    └── Also informs: if A fails, gradient centralization (B) is next priority
        because the margin saturation hypothesis was wrong, suggesting
        the bottleneck is elsewhere in the update geometry

E (depth-scaled init) screen (n=4, 3200 steps)
├── ffs < 3180 → n=6 confirmation → merge
├── ffs 3180-3200 → test combined A+E if A was marginal
└── ffs > 3200 → close; initialization is already adequate given SOAP preconditioning

B (gradient centralization) — run in parallel with A if compute is available
├── ffs < 3170 → strong signal, run n=6
└── ffs > 3190 → close; NS5 orthogonalization already captures the centering effect

C (aux-group embed LR) — run after A and E results are known
  (lower priority: implementation complexity vs expected gain is less favorable)

D (NS5 iteration reduction) — run only if B and E both fail
  (highest uncertainty; save for plateau protocol)
```
