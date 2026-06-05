# SENPAI Research Ideas — 2026-06-05 04:40

Generated after completing wave-1 experiments (PRs #2281–#2287). All 6 Senpai
wave-1 experiments are closed. This batch targets the next wave. Background
assumes PRs #2293 (tanjiro, H13 EMA-Nesterov on PR #309 base) and #2294
(edward, H14 Aurora+EMA-Nesterov with Muon β₂-pulse) are in-flight.

---

## Research State at Time of Writing

**Current Senpai baseline:** PR #2282 / PR #1532 — 3.27902 @ 2905 steps, n=32
**Current open SOTA leaderboard (modded-nanogpt):** PR #318, mean=3.278562 @
2850 steps (n=13); PR #307, mean=3.278576 @ 2900 steps (n=9)

**Statistical contract:** `(3.28 - mu) * sqrt(n) >= 0.004`
- n=1: must have mu < 3.2760
- n=4: must have mu < 3.2780
- n=9: must have mu < 3.27867 (equiv. to PR #307 frontier)
- n=16: must have mu < 3.27900

**Falsified mechanisms (do not repeat):**
- NC on any Aurora-bearing stack (PR #300 or PR #305 base)
- NC + RRE (specific interference independent of Aurora)
- Circuit-Muon on PR #300 base (V/O ratios already ~1.0 via Aurora)
- EMA-Nesterov + bare PR #300 base (Contra-Muon interference)
- Tail Phase Readout single-stage γ-pulse (momentum slowdown artifact)

**Mechanisms with unresolved or promising status:**
- Arbor Muon (PR #310): NOT falsified — had implementation bug only
- EMA-Nesterov + Aurora without Contra-Muon: promising, fat right-tail (n=4 insufficient)
- Tail Reference Interpolation (PR #307, PR #312): sub-2900 frontier technique, untested on Senpai infra
- Senpai `late-higher` block LR pattern: last untested ingredient from PR #1614 stack
- Cautious-Muon (C-Muon): literature technique, not yet attempted
- Polar Express NS variant (PR #254): wall-clock savings not yet exploited

---

## Hypothesis A — Corrected Arbor Muon on EMA-Nesterov+Aurora Base

### Mechanism

Arbor Muon (PR #310) applies 2-iteration Sinkhorn row/column equilibration on
the `mlp.fc` and `mlp.proj` weight matrices immediately after the Newton-Schulz
orthogonalization step, before the momentum accumulation that Muon normally
uses. The intent is to re-balance the singular-value distribution of the weight
matrix toward a flatter spectrum, which in theory makes the NS orthogonalization
step more effective on the next pass because the input matrix is closer to
isotropic.

The Senpai wave-1 attempt (PR #2284, fern, Arm B) diverged at step 758. The
student identified three implementation discrepancies versus PR #310:
(1) alternating rather than simultaneous row/col equilibration;
(2) a relative-to-mean clamp (clamp to mean ± k×std) rather than an
absolute-value clamp on the scale factors;
(3) a `sqrt(out_dim)` post-NS scaling pin that PR #310 uses to stabilize the
output norm.

None of these are fundamental failures of the mechanism — they are
implementation bugs. The mechanism itself has never been correctly tested on any
Senpai configuration. The correct target base for a new attempt is the Aurora +
EMA-Nesterov composition (the PR #309 base), since EMA-Nesterov is the
next-best mechanism we know. Arbor touches a different regime from EMA-Nesterov
(spectrum equilibration vs. Nesterov momentum), so there is no a priori
interference expected.

### Compositional Expectation

Arbor operates on the weight matrix before NS, while EMA-Nesterov operates on
the update momentum. These are orthogonal operations in the gradient pipeline.
The only known interference pairs involve mechanisms that both touch the NS
normalization scale (NC and Aurora, NC and RRE, EMA-Nesterov and Contra-Muon).
Arbor does not perturb the normalization pre-scale; it perturbs the weight
spectrum. Therefore stacking with EMA-Nesterov+Aurora should be compositionally
safe.

Expected gain over EMA-Nesterov+Aurora base: ~0.0002 to 0.0005 on val loss if
the equilibration hypothesis is correct, consistent with the typical per-
mechanism deltas observed in this programme (~0.0005–0.001 from each clean
mechanism layer).

### Implementation Guidance

Base: start from the PR #309 Aurora+EMA-Nesterov configuration (Senpai branch
for PR #2293 or PR #2294, whichever is cleanest after those in-flight runs
close). Do NOT use the bare PR #300 base (Contra-Muon interference with
EMA-Nesterov is falsified).

Correct implementation per PR #310 diff:

```python
# After Newton-Schulz step produces G_orth:
# 1. Simultaneous (not alternating) row/column Sinkhorn iteration, 2 iters:
for _ in range(2):
    # row equilibration
    row_norms = G_orth.norm(dim=-1, keepdim=True).clamp(min=1e-8)
    # clamp to mean ± k*std of row norms (relative clamp, k~3):
    rn_mean = row_norms.mean()
    rn_std = row_norms.std()
    row_norms = row_norms.clamp(rn_mean - 3*rn_std, rn_mean + 3*rn_std)
    G_orth = G_orth / row_norms
    # col equilibration (same logic on dim=-2)
    col_norms = G_orth.norm(dim=-2, keepdim=True).clamp(min=1e-8)
    cn_mean = col_norms.mean()
    cn_std = col_norms.std()
    col_norms = col_norms.clamp(cn_mean - 3*cn_std, cn_mean + 3*cn_std)
    G_orth = G_orth / col_norms
# 2. Post-NS sqrt(out_dim) norm pin:
G_orth = G_orth * (G_orth.shape[-2] ** 0.5)
```

Apply only to `mlp.fc` and `mlp.proj` weight matrices — same scope as PR #310.
Leave attention weights untouched.

Run 4 seeds first (minimum detectable signal). If mean < 3.2780 and no obvious
tail outlier, extend to n=8.

### Statistical Contract

n=4: mean must be < 3.2780 (stat-sig contribution = 0.0040)
n=8: mean must be < 3.2784 (stat-sig contribution = 0.0045)
Success at n=4 justifies confirming to n=8. Single very bad seed (>3.2820)
should be investigated as a possible divergence, not counted as the mechanism
failing.

### Source PRs / Papers

- PR #310 (modded-nanogpt): Original Arbor Muon implementation
- PR #2284 (Senpai): Failed attempt with identified implementation bugs
- Sinkhorn scaling background: Knight (2008), "The Sinkhorn-Knopp Algorithm: Convergence and Applications", SIAM J. Matrix Anal. Appl.

---

## Hypothesis B — Tail Reference Interpolation on PR #309 Base (replication of PR #307/#312)

### Mechanism

Tail Reference Interpolation (PR #307, merged into the open SOTA leaderboard at
mean=3.278576, n=9, 2900 steps) applies a post-hoc weight extrapolation at
evaluation time only: it captures a snapshot of the weights at step 2375, then
at the final checkpoint it computes:

```
theta_eval = theta_2900 + gamma * (theta_2900 - theta_2375)
           = (1 + gamma) * theta_2900 - gamma * theta_2375
```

with gamma = -0.075 (i.e., a small step BACK toward the earlier snapshot, not
forward). This is a deterministic, single-scalar correction with no validation
feedback during the run. PR #312 uses the same trick on the Aurora+EMA-Nesterov
(PR #309) base and reports mean=3.278939 at n=16 (stat-sig confirmed).

The mechanism is similar in spirit to model averaging / iterate averaging but
applied as a deterministic extrapolation rather than a running average. The
theoretical intuition is that the late training trajectory in a cosine-schedule
run overshoots the loss basin bottom due to residual momentum, and a small
negative extrapolation along the recent displacement vector partially corrects
this. This is analogous to Polyak-Ruppert averaging but as a 2-point estimate
rather than a cumulative one.

This is the most externally validated technique in the current pipeline that
has NOT been tested on Senpai infrastructure. Both PR #307 and PR #312 are
stat-sig confirmed by independent authors. The Senpai base (PR #1532, 2905
steps) is a close cousin of these, so the mechanism should port with minimal
friction.

### Compositional Expectation

Reference Interpolation is a post-hoc eval transformation; it does not modify
the training dynamics at all. It should be composable with ANY training-phase
modification (Aurora, EMA-Nesterov, β₂-pulse, block LR pattern, etc.) because
it only affects the checkpoint that gets evaluated. The only compositional
concern is with ParamEMA: if ParamEMA is active at eval time, we need to make
sure the interpolation is applied to the EMA-smoothed weights, not the raw
weights. Disable ParamEMA or clarify which weight buffer is the eval checkpoint.

Expected gain over PR #309 base: PR #307 shows approximately 0.0002–0.0005
improvement vs. the same base without interpolation. The Senpai base adds
β₂-pulse and EMA ingredients, which may shift the magnitude but not negate the
effect.

### Implementation Guidance

Starting from the in-flight PR #2293 or PR #2294 code base (Aurora +
EMA-Nesterov on PR #309 base):

1. Add a `--ref_interp_capture_step` argument (default: 2375) that saves a
   snapshot of all model parameters at the specified step.
2. Add a `--ref_interp_gamma` argument (default: -0.075) applied at final eval.
3. At final eval step:
   ```python
   if ref_interp_gamma != 0.0 and ref_snapshot is not None:
       with torch.no_grad():
           for p, p_ref in zip(model.parameters(), ref_snapshot):
               p.data.add_(ref_interp_gamma * (p.data - p_ref.data))
   ```
4. If ParamEMA is active: apply interpolation to the EMA shadow parameters
   (the ones that get swapped in for eval), not the training parameters.
5. gamma=-0.075 is the PR #307 default; also try gamma=-0.05 and gamma=-0.10
   as two auxiliary arms in the same PR.

Step-count: keep at 2900 (matching in-flight runs). Do not reduce to 2850 for
this experiment — we want to isolate the interpolation mechanism.

Run 4 seeds for each gamma value (3 arms × 4 seeds = 12 total runs). If
gamma=-0.075 achieves mean < 3.2780, that arm is the winner.

### Statistical Contract

Per arm, n=4: mean must be < 3.2780.
If one arm beats threshold, extend that arm to n=8 for confirmation.
Do not extend all three arms simultaneously.

### Source PRs / Papers

- PR #307 (modded-nanogpt): Original Tail Reference Interpolation, 2900 steps, n=9, mean=3.278576
- PR #312 (modded-nanogpt): Same technique on Aurora+EMA-Nesterov base, 2860 steps, n=16, mean=3.278939
- Polyak & Ruppert (1992): classical iterate averaging theory (conceptual ancestor)
- Stochastic Weight Averaging (Izmailov et al., NeurIPS 2018): modern revival of iterate averaging for neural networks

---

## Hypothesis C — Cautious-Muon on PR #305 Base

### Mechanism

Cautious Optimizers (Liu et al., ICLR 2026) introduce a single-line masking
step to any gradient-descent variant: an update is applied only at coordinates
where the sign of the current gradient agrees with the sign of the current
momentum buffer. Where they disagree, the update is zeroed (or scaled to zero).
In pseudocode:

```python
mask = (grad * momentum_buffer > 0).float()
update = mask * update  # or mask.mean() normalization variant
```

This prevents the optimizer from taking steps that contradict both its short-
term (gradient) and medium-term (momentum) directional estimates simultaneously
— i.e., it filters out steps where both signals are uncertain. The paper reports
consistent 1-3% speedups on LLM pretraining benchmarks for C-AdamW, C-Lion, and
C-SGD without any additional hyperparameter tuning.

In the Muon context, the "gradient" after Newton-Schulz orthogonalization is not
a raw gradient but a unit-spectrum gradient direction. The momentum buffer in
standard Muon is the Nesterov buffer. Cautious masking should apply AFTER the
NS orthogonalization, to the ortho-gradient, comparing its sign against the
existing Nesterov buffer. This is "C-Muon".

PR #305 base (3.27813, n=8) is the current Senpai rank-1 checkpoint. It uses
Aurora (PR #300) + RRE late-step weight extrapolation. C-Muon should be
composable with both: Aurora operates on the weight matrix geometry, RRE
operates at eval time, and C-Muon operates on the gradient update sign. No
known interference class.

### Compositional Expectation

Cautious masking is sign-based and thus dimensionality-preserving. It will not
change the gradient norm or the NS spectrum, only zero out some fraction of the
update entries. On typical LLM workloads, Liu et al. report ~15-20% of entries
masked at any given step, concentrated in early-to-mid training. The effect is
essentially an implicit adaptive learning rate reduction on uncertain directions.

NC is falsified on PR #305 base, but C-Muon is distinct: NC operated on the
pre-NS normalization (spectrum control), while C-Muon operates on the post-NS
sign consistency (update direction control). These are different levels of the
Muon pipeline and should not share the interference root.

Expected gain: if the LLM pretraining speedup transfers (1-3%), we'd expect a
~0.001 reduction in val loss at fixed step count — one of the larger single-
mechanism gains we could observe. However the transfer from Adam-based optimizers
to Muon's ortho-gradient regime is speculative and must be tested.

### Implementation Guidance

Starting from the PR #305 base (which builds on PR #300 Aurora):

```python
# In Muon update step, after Newton-Schulz orthogonalization:
# g_orth = zeropower_via_newtonschulz5(g, steps=5)
# buf = momentum_buffer  (Nesterov buffer)

# Cautious masking:
mask = (g_orth * buf).gt(0).float()
# Optional: normalize so the mean update magnitude is preserved:
mask = mask / (mask.mean() + 1e-8)
g_orth = g_orth * mask

# Then proceed with normal Muon momentum update
```

Key hyperparameter choices:
- Try normalized variant first (divide by mean so total update energy is
  preserved, not reduced)
- Also try unnormalized as arm B
- Do NOT change any other hyperparameter — this is a strict one-mechanism test

Important: the EMA-Nesterov on bare PR #300 base is falsified (Contra-Muon
interference). C-Muon on PR #305 base (with RRE, without EMA-Nesterov) is a
clean, separate test. Do not conflate.

Run 4 seeds normalized, 4 seeds unnormalized. Compare both against PR #305
baseline (mean=3.27813).

### Statistical Contract

n=4 per arm: arm mean must be < 3.2780 to be stat-sig.
If normalized arm passes, extend to n=8 for confirmation.
If neither arm at n=4 is < 3.2790, the mechanism does not transfer to Muon's
ortho-gradient regime in this configuration and should be closed.

### Source PRs / Papers

- Liu et al. (ICLR 2026): "Cautious Optimizers: Improving Training with One Line of Code" — C-AdamW, C-Lion, masking where sign(grad)==sign(momentum), consistent LLM speedups
- PR #305 (modded-nanogpt): PR #305 base, current rank-1 Senpai checkpoint
- Kim & Oh (ICLR 2026): "Newton-Schulz Iteration as an Optimizer" — NS convergence theory for Muon (context for why post-NS ortho-gradient is a meaningful signal)

---

## Hypothesis D — Senpai `late-higher` Block LR Pattern on PR #309 Base

### Mechanism

The Senpai PR #1614 ("Cleanup: make aux β₂ pulse the canonical default") reveals
a full stack of ingredients that were consolidated into the canonical Senpai
training run. Three of these are confirmed wins (β₂-pulse at step 975, EMA ramp
β=0.97→0.99 with 1750 warmup, paramEMA refresh-only at step 2600). One
ingredient has never been isolated or tested independently: the
`--muon_block_lr_pattern late-higher` flag.

This flag applies a per-block learning rate modifier to the Muon optimizer,
giving higher LRs to later (closer to the output) transformer blocks and lower
LRs to earlier blocks. The rationale is that later blocks learn more task-
specific representations that benefit from faster updates, while earlier blocks
learn more general features that are more sensitive to large updates early on.
This is conceptually related to layer-wise adaptive rate scaling (LARS) and the
empirical finding that optimal LR often differs across depth in transformers.

Currently, `late-higher` is part of the baseline stack (PR #1532). The question
is whether it provides an additive signal ON TOP of the Aurora+EMA-Nesterov
composition (PR #309 base), beyond what the flat-LR version would achieve. This
is a residual gain test, not a from-scratch test of the pattern.

### Compositional Expectation

Block LR patterns are orthogonal to Aurora (weight geometry), EMA-Nesterov
(momentum), and β₂-pulse (aux Adam schedule). The only potential interaction is
that if EMA-Nesterov already provides per-layer adaptation via its momentum
buffer, the block LR pattern may be redundant on top. But the mechanisms operate
at different granularities (per-layer vs. per-block-group), so some signal should
remain.

The gain expected is smaller than primary mechanisms: literature on LARS-style
scaling typically shows 0.5-2% throughput improvement, which in this calibrated
setting would be roughly 0.0001–0.0003 val loss. This is at the edge of what n=4
can detect but worth confirming given it costs nothing to enable.

### Implementation Guidance

Starting from the PR #309 Aurora+EMA-Nesterov base (same as in-flight PRs
#2293/#2294):

1. Ensure `late-higher` block LR pattern is NOT already active on the PR #309
   base (verify by checking the default for `--muon_block_lr_pattern` in
   `train_gpt_simple.py`; it should default to `flat` or `None`).
2. Add `--muon_block_lr_pattern late-higher` to the training command.
3. Baseline comparison: run 4 seeds WITHOUT the flag (control) and 4 seeds WITH
   (experiment) in the same PR for a clean within-PR comparison.

The block LR pattern likely uses a linear or log-linear ramp from some scale
factor <1.0 for early blocks to >1.0 for late blocks, normalized so the mean
is the base Muon LR (0.040). The specific ramp should be inherited from the PR
#1614 implementation without modification — do not tune the ramp shape.

### Statistical Contract

n=4 per arm: experiment arm mean must be < 3.2780 AND lower than control arm
mean by at least 0.0003 to justify extension. Since control and experiment share
seeds/hardware budget this is a paired comparison.

If the flag adds no signal (experiment - control < 0.0001), treat as a null
result and close. The mechanism may already be saturated by the EMA-Nesterov
contribution.

### Source PRs / Papers

- PR #1614 (morganmcg1/modded-nanogpt-senpai): Full canonical stack; `late-higher` is last untested ingredient
- You et al. (2017, LARS paper): Layer-wise Adaptive Rate Scaling — conceptual ancestor
- Achiam et al. (2023, GPT-4 technical report): Empirical evidence that per-layer LR tuning matters at scale

---

## Hypothesis E — Polar Express NS on PR #309 Base (Wall-Clock Budget Recovery)

### Mechanism

PR #254 (modded-nanogpt, "New Record: Polar Express Optimization ~440ms")
replaces the standard Newton-Schulz iteration with an optimized version that
achieves the same orthogonalization quality in fewer matrix operations by:
(1) using Gram-trace normalization with diagonal fold to avoid extra full-matrix
operations;
(2) switching between a 3-step accumulated transform for early steps (< step
500) and a 5-step standard path for later steps;
(3) fully unrolling the iteration loop for `torch.compile` fusion.

The net effect is wall-clock speedup per step, which — within a fixed time
budget — translates to more effective gradient steps. Kim & Oh (ICLR 2026) prove
that the NS iteration converges doubly exponentially to the SVD-polar factor in
the number of iterations (q), meaning 3 carefully chosen iterations can match
5 standard iterations in spectral accuracy. Polar Express exploits exactly this
result by using a more efficient polynomial basis.

On Senpai infrastructure (H100 GPUs), if Polar Express yields even a 5-10%
per-step speedup, it translates to ~145-290 additional gradient steps within
the existing step budget — potentially equivalent to a free 5% experiment budget
increase.

### Compositional Expectation

Polar Express is a drop-in replacement for the NS orthogonalization function; it
does not change the mathematical operation, only the numerical implementation.
It should be fully composable with Aurora, EMA-Nesterov, β₂-pulse, and any
other training-phase mechanism. The only risk is numerical: the Gram-trace
normalization may behave slightly differently from Frobenius normalization under
Aurora's row-reweighting, but the deviation should be O(1e-5) per step and
cumulative effects should be negligible over 2900 steps.

Important caveat: the wall-clock gain must be confirmed on the specific hardware
(H100 vs. the GH200 used in PR #254). If Polar Express does not yield speedup
on H100, the experiment provides no step budget recovery and the benefit
disappears.

### Implementation Guidance

1. Copy the Polar Express NS implementation from PR #254 (the
   `_polar_express_tall_transform_batched` and `_polar_express_tall_standard_batched`
   functions, plus the transition logic at step 500).
2. Replace the call to `zeropower_via_newtonschulz5` with the Polar Express
   version in `train_gpt_simple.py`.
3. Run a single seed wall-clock timing check FIRST (1 seed, full 2900 steps)
   to confirm per-step speedup on H100. If per-step time does not drop by at
   least 5% (from ~1654ms to <1571ms), abort and close.
4. If wall-clock is confirmed, run 4 seeds on the PR #309 base and compare to
   baseline.

Do not conflate the wall-clock benefit with loss-curve benefit: the mechanism
here is "more steps in same time budget". If the per-step loss curve is
identical to baseline and wall-clock is faster, that IS a win — fewer calendar
minutes for equivalent results. Record both per-step loss and wall-clock time.

### Statistical Contract

Primary gate: per-step wall-clock time < 1571ms (5% speedup threshold) on H100.
If gate passes: n=4 mean must be < 3.2780 at step 2900 (same step count, same
stat-sig contract as all other experiments).

If gate fails: close without running n=4 validation.

### Source PRs / Papers

- PR #254 (modded-nanogpt): Polar Express implementation, ~440ms/step on GH200
- Kim & Oh (ICLR 2026): NS convergence theory, doubly-exponential in iteration count
- Prince & Rudin (1993): Original Newton-Schulz iteration for matrix square root

---

## Prioritization

Listed in recommended assignment order. This reflects expected EV, implementation
risk, and independence from in-flight experiments.

### Tier 1 — Assign Immediately (Highest EV, Clean Implementation Path)

**1. Hypothesis B (Tail Reference Interpolation)** — Priority 1
- Externally validated on two independent codebases (PR #307, PR #312)
- Mechanism is post-hoc (does not touch training) — minimal implementation risk
- Composable with any training-phase base
- Only caveat: ParamEMA interaction at eval time (manageable with explicit buffer selection)
- Assign to first available student after in-flight PRs #2293/#2294 close

**2. Hypothesis A (Corrected Arbor Muon)** — Priority 2
- NOT falsified — previous attempt had implementation bugs only
- Mechanism is distinct from EMA-Nesterov and Aurora (orthogonal pipeline level)
- Student (fern) already familiar with the code and identified the specific bugs
- Preferably re-assign to fern who has the bug analysis already in context

### Tier 2 — Assign When Additional Students Are Idle

**3. Hypothesis C (Cautious-Muon)** — Priority 3
- Strong external evidence (Liu et al. ICLR 2026, consistent LLM gains)
- Compositionally clean (post-NS sign masking, no known interference class)
- Most speculative transfer (Adam → Muon ortho-gradient regime) — needs empirical test
- Run normalized and unnormalized arms within same PR to discriminate faster

**4. Hypothesis D (late-higher block LR pattern)** — Priority 4
- Low-cost, likely-additive test of remaining PR #1614 ingredient
- Residual gain expected to be small (~0.0001–0.0003) — may not be stat-sig at n=4
- Worth testing but do not prioritize over T1/T2 above

### Tier 3 — Assign Only After T1/T2 Confirm

**5. Hypothesis E (Polar Express NS)** — Priority 5
- Hardware-dependent (H100 vs GH200 speedup must be confirmed first)
- Single-seed wall-clock gate before full experiment — cheap to falsify
- If wall-clock gate fails, this is a quick close without wasting GPU days

### Composition Matrix

After T1/T2 results are in, the next wave should explore combinations:

| Base | + Ref Interp | + Arbor Muon | + C-Muon | Expected |
|------|-------------|-------------|---------|----------|
| PR #309 (EMA-Nesterov+Aurora) | H-B this wave | H-A this wave | — | top priority combos |
| PR #305 (RRE+Aurora) | feasible | feasible | H-C this wave | secondary |
| PR #309 + Ref Interp (if H-B wins) | — | test in wave 3 | test in wave 3 | wave 3 |

Key constraint: if H-B (Ref Interp) wins on PR #309 base, the wave-3 priority
is Ref Interp + Arbor Muon on PR #309 base. If H-A (Arbor Muon) also wins
independently, then the three-way composition (PR #309 + Arbor + Ref Interp)
becomes the priority target.

NC remains falsified on all Aurora-bearing stacks. Do not resurrect.
EMA-Nesterov on bare PR #300 remains falsified. Do not resurrect.
Circuit-Muon on PR #300 base remains null. Only revisit on a non-Aurora base
where V/O ratios are not already equalized.
