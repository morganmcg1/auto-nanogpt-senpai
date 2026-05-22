# Research Ideas — 2026-05-22 10:15

Generated for the next 2-3 wakes of student assignments. All ideas target mechanism
axes NOT represented in the 187-PR history and NOT currently in-flight.

Mandatory stack for all experiments:
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85

Baseline: val=3.26776, ffs=3000 (PR #613, n=2 mean)

---

## Idea 1: MARS-M — Variance-Reduced Muon via Scaled Stochastic Recursive Momentum

**Mechanism class:** Variance reduction / gradient estimator correction

**Motivation:** MARS (arxiv 2411.10438) unifies preconditioned gradient methods
with variance reduction by adding a scaled control-variate correction to each
gradient before the preconditioner step. MARS-M (arxiv 2510.21800) applies this
specifically to Muon-style Newton-Schulz updates and proves the convergence rate
improves from O(T^{-1/4}) to O(T^{-1/3}). The close-miss cluster at ffs=3025
suggests the current Muon gradient estimate has residual noise that better
variance reduction could remove. The correction term is: g_t_corrected =
g_t + c_t * (g_t - g_{t-1}), where c_t is a scalar computed from the ratio of
consecutive gradient norms; this replaces the raw gradient entering Newton-Schulz.

**Expected impact:** The convergence-rate improvement is theoretical but the
mechanism is directionally correct for the observed symptom — a floor cluster
where loss is inconsistently 0.001-0.003 above target across seeds. Variance
reduction directly attacks gradient noise and should compress the seed-to-seed
spread in final val loss. Estimated ffs reduction: 25-50 steps if the noise
hypothesis is correct.

**Implementation complexity:** Requires storing g_{t-1} (one extra gradient-sized
buffer per Muon parameter group) and computing c_t each step; modifies the
existing Muon step method, not the NS5 kernel or SOAP path.

---

## Idea 2: Schedule-Free AdamW for Embed and lm_head Groups

**Mechanism class:** Schedule elimination / implicit weight averaging

**Motivation:** Schedule-Free AdamW (Defazio et al. 2024, arxiv 2405.15682)
replaces the explicit LR schedule with primal-dual averaging that implicitly
performs weight averaging; "Through the River" (Song et al. KAIST/MS Research
2025, arxiv 2507.09846) shows SF-AdamW navigates flat loss-landscape regions
without needing a manual cooldown phase. Currently optimizer1 applies standard
cosine-scheduled AdamW to embed.weight (lr=0.3) and proj.weight (lr=1/320);
replacing these groups with SF-AdamW removes the schedule sensitivity that makes
the embed and lm_head groups require separate hyperparameter tuning and may
improve the signal from the cooldown phase where ffs is currently determined.

**Expected impact:** The embed and lm_head groups receive a qualitatively
different update trajectory that no longer depends on manually tuned cooldown
fractions. If the 3025-floor reflects sub-optimal averaging of embed/head weights
at the end of training, SF-AdamW provides a principled fix. Implementation stays
within the two-optimizer structure; Muon body matrices are untouched.

**Implementation complexity:** Replace the AdamW optimizer1 groups with the
schedule-free variant from the reference implementation (schedule_free_adamw.py,
~50 LOC); requires calling optimizer.eval() before validation steps to return the
averaged iterate.

---

## Idea 3: Sophia-Style Diagonal Hessian Preconditioner on AdamW Groups

**Mechanism class:** Second-order / diagonal Hessian preconditioning

**Motivation:** Sophia (Hong Liu et al. Stanford, arxiv 2305.14342) uses a
periodically updated diagonal Hessian estimate (Gauss-Newton-Bartlett estimator
every K steps, clipped from below) in place of Adam's running second-moment;
on GPT-2 pretraining it achieved 2x step-count and wall-time speedup versus Adam
at comparable loss. The current stack already uses SOAP (Kronecker eigenbasis
preconditioner) on attention weights and Muon (spectral normalization) on body
matrices; the embed.weight and proj.weight groups in optimizer1 still use vanilla
Adam second moments which may be the weakest preconditioned link. Diagonal
Hessian preconditioning for these groups is a distinctly different mathematical
object from both SOAP and Muon.

**Expected impact:** The embed and lm_head weight matrices have very different
gradient curvature profiles than body matrices; a curvature-aware preconditioner
should reduce wasted steps on flat directions. If these groups are the binding
constraint for late-training convergence, this could move ffs from 3025 to 3000
or better. K=200 (compute Hessian every 200 steps) keeps overhead low.

**Implementation complexity:** Implement the GNB estimator (single Hessian sample
via grad * grad on a fresh micro-batch) and clipped division; ~80 LOC added to
the optimizer section; requires one extra forward-backward pass every K steps for
the Hessian sample, BUT this can be avoided using the curvature-from-gradients
trick: H_diag ≈ g^2 computed from the same backward pass.

---

## Idea 4: Cooldown-Phase Tail Weight Averaging (EMA/Polyak)

**Mechanism class:** Model averaging / implicit regularization

**Motivation:** Stochastic Weight Averaging (SWA, Izmailov et al. 2018) and
Polyak-Ruppert averaging are theoretically grounded methods for finding flatter
minima and reducing generalization gap; in LLM pretraining, maintaining an EMA
of weights during the final cooldown phase (where validation is evaluated) adds
negligible cost (one extra parameter copy) and can smooth noise in the iterate
path. The "Through the River" paper provides theoretical grounding for why weight
averaging is especially beneficial in the flat-river region that late-stage LLM
training traverses. Crucially, averaging only during cooldown avoids the known
failure mode of SWA slowing convergence during the rapid descent phase.

**Expected impact:** If ffs=3025 reflects the raw (non-averaged) checkpoint
landing just above 3.28 while the average weight is already below, tail averaging
converts close misses to hits without any change to the optimizer trajectory.
This is a direct attack on the close-miss floor with essentially zero training
overhead. Estimated ffs improvement: converts 3025 to 3000 if the hypothesis is
correct.

**Implementation complexity:** Maintain a shadow EMA parameter dict initialized
at cooldown start; accumulate ema_weights = decay * ema_weights + (1-decay) *
model_weights each step during cooldown; evaluate/report only ema_weights at
validation time; ~30 LOC; EMA decay = 0.9 or 0.99 is a sensible starting point.

---

## Idea 5: Depth-Dependent Muon LR Scaling

**Mechanism class:** Per-layer parameterization / depth-aware learning rate

**Motivation:** The Muon scalability paper (Moonshot AI, arxiv 2502.16982)
identifies "carefully adjusting per-parameter update scale" as one of two key
techniques for stable LLM training with Muon, and CompleteP (Cerebras 2025,
arxiv 2505.01618) shows that achieving both depth-wise HP transfer and non-lazy
learning requires per-depth LR scaling (12-34% compute efficiency gains). Current
implementation applies a single MUON_LR uniformly to all layer body matrices.
Early transformer layers learn low-level token statistics while late layers
encode high-level structure; forcing uniform step size treats these as
equivalent update targets.

**Expected impact:** Depth-differentiated scaling should allow early layers to
take smaller steps (preserving low-level representations) while late layers
converge faster, or vice versa, depending on gradient magnitude profiles. The
CompleteP result is the strongest external evidence for this direction; 12-34%
efficiency improvement in a comparable setting translates to meaningful ffs
reduction if even a fraction carries over.

**Implementation complexity:** In the Muon optimizer step, multiply each layer's
effective LR by f(depth_idx), e.g. `alpha * (layer_idx / num_layers) + (1-alpha)`
with alpha and sign as hyperparameters; requires passing layer_idx metadata to
the optimizer (currently not stored); ~40 LOC change to Muon class and
optimizer2 construction.

---

## Idea 6: AdaFactor Row-Column Factored Preconditioner for MLP Body Matrices

**Mechanism class:** Factored second-order preconditioning / memory-efficient

**Motivation:** AdaFactor (Shazeer & Stern 2018, arxiv 1804.04235) maintains
per-row and per-column second-moment factors rather than full per-element
second moments, achieving sublinear memory while matching Adam convergence on
Transformer training. Currently attention weights use SOAP (Kronecker eigenbasis)
and body matrices use Muon (Newton-Schulz spectral normalization); MLP matrices
are a distinct object (low-frequency gradient structure) that may benefit from
factored curvature information that Muon's spectral approach discards. This
creates a three-tier preconditioning stack: spectral (Muon) for all body,
Kronecker (SOAP) for attention, factored second-order (AdaFactor) for MLP only.

**Expected impact:** AdaFactor's factored curvature captures more gradient
structure than Muon's pure spectral normalization for matrices where row/column
gradients have heterogeneous scale, which MLP up/down projection matrices
typically do. The combination is novel in this setting. Expected impact: moderate
— this is a speculative direction but mechanistically distinct from all prior
axes.

**Implementation complexity:** Implement AdaFactor as an alternative Muon update
for the MLP parameter group (select by parameter name containing 'mlp'); ~80 LOC;
requires factoring the Adam-style second-moment estimate into row and column
vectors using outer product decomposition; can be implemented as a drop-in
update_fn alternative within the existing Muon class structure.

---

## Priority Order

1. Idea 4 (Cooldown Tail Averaging) — lowest implementation cost, direct attack
   on close-miss symptom, strong theoretical grounding, no new hyperparameters
   to tune.
2. Idea 1 (MARS-M Variance-Reduced Muon) — proven convergence rate improvement,
   tight connection to observed noise floor, moderate implementation cost.
3. Idea 2 (Schedule-Free AdamW) — eliminates schedule sensitivity for embed/head
   groups, well-supported by 2024-2025 literature.
4. Idea 5 (Depth-Dependent Muon LR) — strong external evidence from CompleteP
   and Muon scalability paper; requires metadata plumbing.
5. Idea 3 (Sophia Diagonal Hessian) — highest expected ceiling but requires
   careful curvature estimation; run after simpler ideas are exhausted.
6. Idea 6 (AdaFactor for MLP) — most speculative; try last or in parallel with
   a confirmed winner from ideas 1-4.

---

## References

- MARS: arxiv 2411.10438 (Yuan et al. 2024) — unified variance reduction for
  preconditioned optimizers
- MARS-M: arxiv 2510.21800 — MARS applied to Muon, O(T^{-1/3}) convergence
- Schedule-Free AdamW: arxiv 2405.15682 (Defazio et al. 2024)
- Through the River: arxiv 2507.09846 (Song et al. KAIST/MS Research 2025)
- Sophia: arxiv 2305.14342 (Hong Liu et al. Stanford 2023)
- SWA: Izmailov et al. 2018, ICML UAI
- AdaFactor: arxiv 1804.04235 (Shazeer & Stern 2018)
- CompleteP: arxiv 2505.01618 (Cerebras 2025)
- Muon Scalability: arxiv 2502.16982 (Moonshot AI 2025)
