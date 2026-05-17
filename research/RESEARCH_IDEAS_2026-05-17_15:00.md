# Research Ideas — 2026-05-17 15:00

## Context snapshot

- Baseline: MuLoCo × MuonH-SI, val/loss = 3.27585 (n=4, ffs=3275)
- Stack: inner=MuonH-SI (lr=0.018, mu=0.95, NS5 12-iter bf16), outer=MuLoCo
  (outer_lr=0.7, outer_momentum=0.5, sync_interval=30), aux=AdamW for
  embed/lm_head/scalars, WSD with h_cooldown_frac=1.0 (full linear from step 0).
- Statistical bar: (3.28 - mu) * sqrt(n) >= 0.004; single run needs < 3.276.
- In-flight (do NOT duplicate): AGC clip=0.05 on aux AdamW (#257 fern, ~WIN),
  cosine cooldown on MuonH (#243 frieren, ~WIN), schedule-free MuonH (#265 nezuko),
  outer_momentum sweep (#260 tanjino).
- Hard constraints: 1 GPU, 1 fwd-bwd/step, no arch/data/batch changes, ~3325 steps.

---

## Hypothesis 1 — NS5-Orthogonalized MuLoCo Outer Velocity

### Mechanism

Apply the NS5 orthogonalization pass to the outer velocity direction before it
is used to pull parameters, so the MuLoCo outer correction lives in the same
"unit-spectral-norm update" space as the MuonH inner steps.

### Why it might help

The outer velocity accumulates raw `delta = anchor - p` sums. These deltas are
plain differences in weight space, which means the outer correction's direction
is dominated by the parameters with the largest absolute norm (embed, lm_head
have far larger norms than block matrices). MuonH inner steps, by contrast, are
NS5-normalized so no single parameter dominates. This mismatch means MuLoCo's
outer pull is applied in a heterogeneous direction space relative to where inner
learning is happening. Normalizing the per-matrix velocity block via NS5 before
the outer pull would make the outer correction directionally consistent with the
inner optimizer's geometry, potentially improving the signal-to-noise of the
outer step. Analogous to gradient preconditioning in Shampoo/K-FAC — the outer
momentum benefits from a curvature-aware direction.

### Going-in prediction

If outer velocity direction matters and the current mismatch creates interference,
orthogonalizing the outer velocity should tighten val/loss by 0.001–0.003 at
equivalent step count. Plausible single-run terminal near 3.273–3.275 vs baseline
3.27585. Effect may interact positively with outer_lr and outer_momentum retuning.

### Implementation effort

- Lines of code: ~20 LOC change inside the outer step block (lines 946–957).
- New state: zero (outer_velocity already exists; apply NS5 in-place before the
  pull step without storing the normalized version).
- New compute: 12 NS5 matrix-multiply iterations × number of 2D block parameters
  fired every sync_interval=30 inner steps. Overhead per outer step is
  O(d_model^2 * num_layers) / 30 ≈ negligible (<0.5% wall-clock).
- Critical detail: NS5 expects a 2D tensor. Scalars, biases, gains (ndim < 2)
  and 1D parameters must be skipped — apply only to p.ndim >= 2 params. The
  embed (50304×768) and lm_head (768×50304) are large; transposing to short-axis
  orientation first (same as muon_update) is required to avoid OOM.
- The aspect-ratio scale correction `max(1, m/n)**0.5` used in muon_update should
  be applied to outer_velocity after NS5 for dimensional consistency.

### CLI flag proposal

```
--outer_orthogonalize_velocity 1
```

Default=0 (disabled) to preserve backward compat. The flag activates NS5
normalization of outer_velocity[n] for ndim>=2 parameters at each outer step.

---

## Hypothesis 2 — SWA / Polyak-EMA Tail Averaging at Validation Time

### Mechanism

Maintain an exponential moving average (EMA) of all parameters throughout
training, initialized from the broadcast weights at step 0. At each validation
event, swap to the EMA parameters for the forward pass, then swap back. The EMA
is not used for gradient steps; it is purely an inference-time model.

### Why it might help

Stochastic Weight Averaging and Polyak-Ruppert averaging are theoretically
grounded: SGD iterates oscillate around a basin; their average sits closer to
the geometric center with lower curvature and better generalization. In
language-model training on finite data this effect is empirically strong (SWA
and Uniform Soup / Model Soups literature). The current stack has no averaging
at all: validation uses live weights at their latest SGD iterate, which is
noisier than the mean trajectory. WSD's full linear cooldown already compresses
the iterate toward the center of the WSD basin, but it does not average across
the final phase. Adding EMA averaging with a long decay (alpha near 0.999)
would smooth the late-training iterate at zero training cost.

Key insight: the EMA is computed on the live weights AFTER the MuLoCo outer
step fires. This means the EMA tracks the outer-corrected trajectory, not the
noisy inner iterates. MuonH-SI holds param norms constant, so the EMA of SI
weights still lies on the same Frobenius sphere as the individual iterates
(the sphere is convex).

### Going-in prediction

Expected effect 0.001–0.003 loss improvement at the same step count, consistent
with SWA gains in similar transformer language-model settings. Low variance
across seeds because averaging is deterministic. Plausible terminal single-run
near 3.273–3.275.

### Implementation effort

- Lines of code: ~30 LOC total.
  - Init: `ema_params = {n: p.detach().clone() for n, p in model.named_parameters()}` after broadcast.
  - Per-step update (every step, after optimizer steps and outer step): `ema_params[n].lerp_(p.data, 1 - ema_decay)` for all params.
  - Validation swap: copy ema_params into model before val forward pass; copy live params back after.
  - Or simpler: swap model.state_dict in/out at validation time.
- New state: one full copy of model weights (768M params, ~1.5 GB fp32 or 0.75 GB bf16). Fits easily on 96 GB VRAM.
- New compute: one lerp per step (O(param_count)) per step — negligible.
- Critical detail: EMA must be kept in fp32 to avoid accumulation error; the model runs in bf16/fp32 mixed. A common mistake is to EMA in bf16 and lose signal.
- Warmup: EMA is uninformative for the first ~200 steps; either start EMA after step 200 or use a short initial burn-in period before including in validation.
- The `--ema_decay` flag should default to 0.999 (or equivalently ema_halflife_steps = 693 steps). Exploration range 0.995–0.9995.

### CLI flag proposal

```
--ema_decay 0.999
```

Default=0.0 (disabled). Value > 0 enables EMA tracking and validation swap.

---

## Hypothesis 3 — Per-Layer Depth-Scaled MuonH Learning Rate

### Mechanism

Multiply the effective MuonH learning rate for each block by a factor that
increases with layer index (deeper layers get higher LR, earlier layers get
lower LR), following a sqrt-depth or linear-depth schedule derived from muP /
depth-scaling theory.

### Why it might help

The current MuonH optimizer applies a single global lr=0.018 across all 12
transformer blocks. However, residual-stream dynamics are depth-dependent:
shallower layers process lower-level features with higher gradient signal
(shorter backprop path, less gradient dilution), while deeper layers operate on
richer representations that can absorb larger updates. In muP theory the optimal
per-layer LR scales with sqrt(fan_in), but for depth-indexed layers in a uniform
architecture the additional depth factor accounts for the effective learning
signal reaching each block. Several recent works (e.g. depth-scaled Adam,
Gradients Are Not All You Need for Transformers) show that deeper layers
systematically benefit from higher LRs. The per-layer depth scaling is NOT
currently present on the r3 branch (only global aspect-ratio scaling
`max(1, m/n)**0.5` exists in `muon_update`), making this a clear untested lever.

This is a r3-specific opportunity: r2 has a per-layer depth scaling PR in-flight
(#268) but it has NOT been ported to r3.

### Going-in prediction

Expected 0.001–0.003 improvement if depth heterogeneity is a real bottleneck.
May interact with the existing global lr baseline: the optimal global lr may
shift slightly after depth scaling is applied. Start with a global lr correction
factor to preserve mean-LR.

### Implementation effort

- Lines of code: ~25 LOC.
  - Instead of a single MuonH group for all block params, create 12 separate
    param groups (one per layer), each with `lr = base_lr * depth_scale(i)`.
  - `depth_scale(i) = ((i+1) / num_layers) ** 0.5` or linear `(i+1) / num_layers`.
    To preserve mean LR: normalize so `mean(depth_scale) = 1.0`.
  - The cooldown schedule must be applied to each group's `initial_lr`; the
    `set_hparams` function already iterates over all groups so this is free.
  - The `all_gather` pass in MuonH.step() works per-group already, so 12 groups
    with world_size=1 just means 12 sequential processing windows — no
    distributed correctness issue.
- New state: zero (just reorganize existing param groups).
- New compute: zero (only adds group bookkeeping overhead).
- Gotcha: the current MuonH init sorts params by size: `params = sorted(params, key=lambda x: x.size(), reverse=True)`. When passing per-layer groups, this sorting reorders within each group but not across groups — correct behavior.
- Must keep `all_gather` padded correctly per group. With world_size=1, this is trivial.

### CLI flag proposal

```
--depth_lr_scale_mode none|sqrt|linear
```

Default=none (disabled). `sqrt` applies `((layer_idx+1)/num_layers)**0.5`
scaling per block, normalized to preserve mean LR. `linear` applies
`(layer_idx+1)/num_layers` linear variant.

---

## Hypothesis 4 — Trust-Region Clip on MuLoCo Outer Update Magnitude

### Mechanism

Before applying the MuLoCo outer correction `delta_velocity = outer_lr *
(mu * v + delta)`, clip the per-parameter RMS of the outer update to a maximum
fraction `outer_clip_frac` of the current parameter's RMS, preventing the outer
step from dominating a single inner step's worth of movement.

### Why it might help

The outer Nesterov velocity accumulates momentum across many inner steps. With
outer_momentum=0.5 and sync_interval=30, the velocity can carry energy from
hundreds of past inner steps. When the trajectory curves (schedule cooldown
onset, learning rate changes), the accumulated outer velocity can overshoot and
partially undo the inner optimizer's recent progress. This is an adaptive
gradient clipping idea applied at the outer level — it is the MuLoCo-outer
analogue of the AGC that already confirmed ~WIN on the aux AdamW groups.

The outer clip operates on the final correction direction, not the raw delta,
so it is compatible with MuonH-SI's scale-invariant projection: the outer pull
may shift the parameter off the SI sphere but the next inner MuonH step
re-projects it, and that re-projection is bounded. A trust-region outer clip
limits the distance that pull can take the parameter before the next
re-projection.

Compared to simply reducing outer_lr: this is adaptive — it clips only when the
outer velocity has accumulated disproportionately, leaving small corrections
unconstrained. This is strictly more expressive than a single outer_lr tuning.

### Going-in prediction

If the outer momentum overshoot mechanism is real, this should improve loss by
0.001–0.003 at equivalent step count. Effect likely visible as reduced variance
across seeds (more stable late-training trajectory). Plausible n=4 mean near
3.274–3.277. May interact weakly with outer_lr; recommend checking outer_lr=0.7
first before sweeping together.

### Implementation effort

- Lines of code: ~15 LOC added inside the outer step block (lines 946–957).
- Algorithm: compute `update_rms = update.float().norm() / sqrt(update.numel())`.
  Compute `param_rms = p.data.float().norm() / sqrt(p.numel())`. Then
  `clip_scale = min(1, outer_clip_frac * param_rms / max(update_rms, eps))`.
  Apply `update *= clip_scale` before the copy-back.
- This is the Adaptive Gradient Clipping (AGC) formula applied to the outer
  update rather than the gradient.
- New state: zero (all tensors are temporaries).
- New compute: two norm calls per parameter per outer step, fired every
  sync_interval=30 inner steps — negligible.
- Gotcha: scalars, biases, gains (ndim < 2) have very small norms; they should
  either be skipped or use a more forgiving clip fraction. Recommend applying
  only to ndim >= 2 parameters initially.
- Starting value: outer_clip_frac = 0.05 (same value that confirmed ~WIN for
  AGC on AdamW in PR #257). Range to sweep: 0.02, 0.05, 0.1.

### CLI flag proposal

```
--outer_clip_frac 0.0
```

Default=0.0 (disabled). Value > 0 activates trust-region clipping on the outer
Nesterov update. Recommended first trial: 0.05.

---

## Hypothesis 5 — Warm Restarts (Cosine Annealing With Restarts) on MuonH

### Mechanism

Replace the full-linear-from-step-0 cooldown on MuonH with a cosine-with-warm-
restarts schedule (SGDR / cosine annealing with T_mult=1 or T_mult=2), keeping
the final restart's down-leg aligned with the total training budget so the last
phase still reaches near-zero LR.

### Why it might help

The current h_cooldown_frac=1.0 schedule is a single monotone linear decay that
starts at step 0 and ends at step train_steps. This means MuonH never has a
stable high-LR phase: LR is already decaying from the first step. SGDR
theory (Loshchilov & Hutter 2016) shows that warm restarts allow the optimizer
to escape sharp minima found during the down-leg and explore new basins during
the up-leg. For a 3325-step budget with T_mult=2, a natural split is:
restart 1 ends at step ~470, restart 2 at ~940, restart 3 at ~1880, final
phase at ~3325 — each restart doubles the cycle length. The final phase (steps
1880–3325) uses a standard cosine down-leg and provides the same late-training
benefit as the current linear cooldown. The intermediate restarts allow
exploration at moderate LR. Note: the cosine cooldown in-flight (#243 frieren)
replaces linear with cosine on the single down-leg but does NOT add restarts.
This hypothesis adds the restart structure on top.

The interaction with MuLoCo is favorable: outer momentum naturally smooths
the restart jumps since outer_velocity does not reset at restart boundaries.

### Going-in prediction

Effect is uncertain since the current single-pass linear schedule already
converges well. But if the model is converging into a marginally sub-optimal
basin early in training, restarts provide cheap escapes. Going-in estimate:
0.001–0.004 improvement. If frieren (#243) confirms cosine > linear on the
single pass, this provides the next natural experiment.

### Implementation effort

- Lines of code: ~30 LOC in `set_hparams`.
- Algorithm: compute cycle boundaries `T_cur, T_i` via SGDR formula. Within
  each cycle, `eta = 0.5 * (1 + cos(pi * T_cur / T_i))`. Final cycle must be
  long enough to provide a full cooldown; schedule the final restart so the last
  down-leg covers at least the last 30% of training.
- The WSD "warmup" phase is already absent (h_cooldown_frac=1.0 means no warmup).
  For restarts, set each up-leg to a short linear warmup (e.g. 10% of cycle) to
  avoid loss spikes at restart boundary.
- Per-group cooldown_frac is not directly applicable when using restarts; the
  flag can be repurposed as "minimum LR fraction" (eta_min).
- The AdamW aux groups (aux_cooldown_frac=0.4) should NOT be restarted — only
  MuonH groups get the restart schedule.
- Starting config: T0=470, T_mult=2 (4 restarts for 3325 steps), eta_min=0.0,
  short 10% linear warmup per cycle. Alternative: T0=1662, T_mult=1 (2 equal
  cycles of 1662 steps each — simpler and likely safer first trial).

### CLI flag proposal

```
--muonh_schedule cosine_restarts
--muonh_restart_t0 1662
--muonh_restart_t_mult 1
```

Default schedule=linear (existing behavior). First experiment: T0=1662, T_mult=1
(two equal half-period cosine cycles). Second trial: T0=470, T_mult=2 if first
fails.

---

## Summary of hypotheses

| # | Idea | Expected delta | Effort | CLI entry-point |
|---|------|----------------|--------|-----------------|
| 1 | NS5-orthogonalized MuLoCo outer velocity | -0.001 to -0.003 | ~20 LOC | `--outer_orthogonalize_velocity 1` |
| 2 | EMA tail averaging at validation (SWA-lite) | -0.001 to -0.003 | ~30 LOC | `--ema_decay 0.999` |
| 3 | Per-layer depth-scaled MuonH LR | -0.001 to -0.003 | ~25 LOC | `--depth_lr_scale_mode sqrt` |
| 4 | Trust-region clip on MuLoCo outer update (AGC-outer) | -0.001 to -0.003 | ~15 LOC | `--outer_clip_frac 0.05` |
| 5 | Cosine warm restarts on MuonH (SGDR) | -0.001 to -0.004 | ~30 LOC | `--muonh_schedule cosine_restarts` |

### Priority ordering

1. **Hypothesis 4 (AGC-outer / trust-region clip)**: Mechanistically tightest.
   AGC at the outer level is the direct analogue of the confirmed ~WIN for AGC
   on aux AdamW (#257). The failure mode is clear and the fix is precise.
   Lowest implementation risk.

2. **Hypothesis 2 (EMA tail averaging)**: Theoretically cleanest, no training-
   time cost, strong external evidence from SWA/Model Soups. Pure inference-time
   change so it cannot harm training dynamics.

3. **Hypothesis 3 (depth-scaled MuonH LR)**: Only untested on r3 (r2 has it
   in-flight). Direct portability of a known promising direction.

4. **Hypothesis 1 (NS5-outer velocity)**: More speculative geometry argument,
   but if the outer-inner direction mismatch is real, the fix is precise and
   cheap. May compound with AGC-outer.

5. **Hypothesis 5 (SGDR restarts)**: Highest risk/reward. More useful if
   frieren (#243) confirms cosine > linear, providing a foundation for restarts.
   Run after frieren closes.

### Decision tree

```
Run Hyp 4 (AGC-outer clip=0.05) [n=1 screen, 3325 steps]
  |
  +-- val/loss < 3.276 (beats single-run bar) --> promote to n=4 confirmation
  |     --> Run Hyp 2 (EMA) in parallel
  |
  +-- 3.276 <= val/loss < 3.278 (marginal) --> try outer_clip_frac in {0.02, 0.1}
  |
  +-- val/loss >= 3.278 (no gain) --> run Hyp 2 (EMA) next, AGC-outer ruled out

Run Hyp 2 (EMA decay=0.999) [n=1 screen]
  |
  +-- val/loss < 3.276 --> n=4 confirmation
  |     --> Run Hyp 3 (depth LR) in parallel
  |
  +-- marginal --> try ema_decay in {0.995, 0.9995}
  |
  +-- no gain --> run Hyp 3 (depth LR) next

Run Hyp 3 (depth LR, sqrt mode) [n=1 screen]
  |
  +-- val/loss < 3.276 --> n=4 confirmation
  |     --> Run Hyp 1 (NS5-outer velocity) in parallel
  |
  +-- marginal --> try linear mode, adjust global lr by ±10%
  |
  +-- no gain --> run Hyp 1 (NS5-outer velocity)

Run Hyp 5 (SGDR) [after frieren #243 closes]
  |
  +-- frieren confirms cosine > linear --> run SGDR T0=1662 T_mult=1
  |
  +-- frieren negative --> SGDR less motivated, deprioritize
```

### Stop conditions

- Hyp 4: abandon if n=1 val/loss > 3.278 and direction is wrong at multiple
  clip_frac values.
- Hyp 2: abandon if EMA with decay 0.999 gives val/loss > 3.277 (EMA should be
  nearly free so marginal cases are worth confirming at n=4).
- Hyp 3: abandon if n=1 val/loss > 3.278 at both sqrt and linear modes.
- Hyp 1: abandon if n=1 val/loss > 3.278 (geometry argument may be wrong in
  this regularized setting).
- Hyp 5: deprioritize if frieren cosine closes as negative.

### External evidence notes

- SWA (Izmailov et al. 2018), Model Soups (Wortsman et al. 2022): strong
  evidence for tail averaging improving generalization on language tasks.
- SGDR (Loshchilov & Hutter 2017): cosine warm restarts for better exploration.
- AGC (Brock et al. 2021): adaptive gradient clipping scales well; confirmed here
  in PRs #257 (aux AdamW) and #237 (edward's clip experiments).
- NS5 in update space (Black et al. 2024, Muon): the direction argument for
  Hypothesis 1 extends naturally from the Newton-Schulz spectral geometry used
  inside MuonH inner steps.
- Per-layer LR scaling: supported by muP theory (Yang et al. 2022) and depth-
  aware learning rate works in transformer literature.
