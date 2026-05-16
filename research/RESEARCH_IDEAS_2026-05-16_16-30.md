# Research Ideas for g1r5-fern and g1r5-nezuko — 2026-05-16 16:30

## Context

New baseline: PR #116 SOAP-attn + trust gate, ffs=3150/3125, mu=3.273735, n=6. Statsig rule:
`(3.273735 - mu) × sqrt(n) >= 0.004` → need mu <= 3.27210 at n=6, mu <= 3.27245 at n=8.

Architecture: 12-layer GPT, d_model=768, vocab=50304, train_steps=3250 (env-overridable).
SOAP is now active on ALL Muon-managed matrix params (MLP fc/proj + attn q/k/v/proj).
Global constants: `SOAP_BETA2=0.90`, `PRECOND_FREQ=16`.
Memory budget: 75.23 GB / 80 GB H100 — tight.

Active WIP (do NOT duplicate):
- PR #123 Newton-Muon activation-cov right-precond on attn
- PR #130 Label smoothing ε sweep
- PR #141 Gradient Centralization in Muon
- PR #148 Depth-Scaled Residual Init
- PR #155 Polynomial schedule-free Muon
- PR #162 Per-group LR sweep (lr_mlp sweep, wd fixed)

Closed negative directions (do NOT reopen without new evidence):
NorMuonH, MuonH, Cautious-Muon, Contra-Muon, cooldown shape on plain Muon,
Polyak/SWA, uniform schedule-free Muon c_t=1/(t+1), Muon² v-buffer, output embedding
mu-centering.

Key confirmed implementation fact: the 12-step cubic Newton-Schulz polynomial
(a=2, b=-1.5, c=0.5, range(12)) is already in the merged baseline as of PR #116.
Any hypothesis that proposes changing NS coefficients or iteration count is moot.

---

## Idea 1 (Top Pick — assign to fern): Adaptive precond_freq split — attn=8, MLP=16

### What it is

Split the SOAP preconditioner refresh rate by parameter group: refresh attn eigenbases
every 8 steps instead of 16, while keeping MLP at 16. No change to beta2 or any other
hyperparameter.

### Why it might help

The CURRENT_RESEARCH_STATE.md notes "attn cos_sim ~0.08 lower than MLP" — i.e., the
cosine similarity between the SOAP update and the plain-Muon update is systematically
lower for attn weights than for MLP weights. This means the attn eigenbases drift faster
relative to the momentum direction. Refreshing attn eigenbases twice as often
(precond_freq=8 instead of 16) keeps the projection basis more aligned with the current
loss landscape, which should reduce the lag between the preconditioner's eigendecomposition
and the actual curvature.

The cost is modest: each extra preconditioner update for attn does one eigendecomposition
per attn weight matrix per extra refresh step. The attn matrices are 768×768 (q/k/v) and
768×768 (proj) — small enough that doubling refresh rate adds ~3-5% wall-time overhead.
This is well within the acceptable budget for a mechanism that targets a specific observed
failure mode.

### Mechanism and failure mode targeted

Failure mode: preconditioner staleness for attn weights. When eigenbases are stale, the
projection `V diag(d^{-1/2}) V^T g` maps the gradient into outdated curvature coordinates,
which effectively introduces direction-dependent noise in the update. This is most harmful
during the stable phase (first 30% of training) when the loss is steepest and curvature
changes fastest. A fresher attn preconditioner means the SOAP update is a better
approximation of the Newton step, which should produce more consistent convergence behavior
across seeds.

### Orthogonality argument

PR #162 (per-group LR) varies lr_mlp while keeping wd fixed and does not touch
precond_freq. PR #123 (Newton-Muon) adds a new activation-cov right-preconditioner for
attn — the mechanism is different from adjusting the refresh rate of the existing
left+right Gram preconditioner. No other active PR touches SOAP_BETA2 or PRECOND_FREQ.

### Code change

Two modifications to `records/track_3_optimization/train_gpt_simple.py`:

1. Add CLI arg (after the existing `--soap_trust_threshold` arg, around line 48):
```python
parser.add_argument("--attn_precond_freq", type=int, default=PRECOND_FREQ,
                    help="SOAP preconditioner refresh frequency for attn weights (default: PRECOND_FREQ=16)")
```

2. In `Muon.step()`, when calling `soap_update_preconditioner` (around line 565-572),
   pass the per-group frequency based on whether the param name is in SOAP_ATTN_SUFFIXES:

```python
# Before (current code, approximate):
soap_update_preconditioner(grad, state)

# After (per-group freq):
is_attn = any(name.endswith(s) for s in SOAP_ATTN_SUFFIXES)
freq = self.attn_precond_freq if is_attn else PRECOND_FREQ
soap_update_preconditioner(grad, state, precondition_frequency=freq)
```

The `Muon.__init__` stores `self.attn_precond_freq = attn_precond_freq` from the arg.
The `soap_update_preconditioner` function already accepts `precondition_frequency` as a
parameter (confirmed in code at lines 505-528).

The param `name` is already stored in `self.param_names` dict (keyed by `id(p)`).

Launch command:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --soap_attn \
  --attn_precond_freq 8 \
  --wandb_name "fern/attn-precond-freq8" \
  --wandb_group "pr-fern-attn-precond-freq"
```

Run seeds 1-2 as a fast screen. If both seeds show ffs <= 3150 (matches or beats baseline),
proceed to n=6. If mean_loss at n=2 > 3.279, close as negative.

### Expected effect size

Attn cos_sim is 0.08 lower than MLP. Doubling attn refresh rate should halve the
eigenbasis staleness for attn. Expected gain: 0.0004-0.0010 in mean_loss, roughly 1-2 ffs
steps. Conservative estimate: if attn staleness accounts for half the remaining gap above
the theoretical floor, a 0.0004 gain in mean_loss is plausible. The mechanism is specific,
the cost is low, and the signal (attn cos_sim < MLP cos_sim) is already measured.

### Kill gates

- If seed 1 ffs >= 3200 (worse than current baseline ffs=3150), pause and inspect W&B
  before seed 2.
- If n=2 mean_loss > 3.279, close as negative without proceeding to n=6.
- Full confirm target: n=6, mu <= 3.27210, ffs <= 3125.

---

## Idea 2 (Second Pick — assign to nezuko): SOAP beta2 annealing during cooldown

### What it is

Linearly decay the SOAP second-moment decay coefficient (beta2) from 0.90 to 0.75
during the cooldown phase (last 70% of training), while keeping the LR schedule unchanged.
No change to precond_freq, trust gate, or any other hyperparameter.

### Why it might help

SOAP's preconditioner uses an exponential moving average of the gradient outer product with
decay `beta2`. A high beta2 (0.90) accumulates statistics over a long history, which is
appropriate during the stable high-loss phase of training when the curvature structure is
changing rapidly. During the cooldown phase, as LR decays to zero, the gradient direction
stabilizes — the model is converging to a local minimum and the loss landscape is smoother.
At this point, a lower beta2 (shorter memory) makes the EMA more responsive to the current
curvature, which is more accurate because the landscape is no longer changing rapidly. This
is analogous to how Adam beta2 annealing (from 0.999 to 0.9) is known to improve
fine-tuning on LLMs — the same principle applies to the Shampoo/SOAP covariance EMA.

The annealing formula:
```
progress = step / train_steps
stable_end = 1.0 - 0.7  # = 0.3
if progress >= stable_end:
    cooldown_t = (progress - stable_end) / 0.7  # in [0, 1]
    soap_beta2 = 0.90 - 0.15 * cooldown_t       # anneals from 0.90 to 0.75
else:
    soap_beta2 = 0.90
```

### Mechanism and failure mode targeted

Failure mode: preconditioner over-smoothing during convergence. In the cooldown phase,
the EMA with beta2=0.90 keeps a heavy weight on old gradient statistics accumulated during
the stable phase. These old statistics reflect a different loss curvature (higher loss,
different gradient magnitudes). If the SOAP preconditioner is partially misaligned with
the current convergence-phase curvature, it introduces suboptimal effective step directions
during the final approach to the target loss. A lower beta2 during cooldown corrects this
by forgetting old statistics faster and tracking the actual final-phase curvature.

### Orthogonality argument

No active PR touches SOAP_BETA2. PR #162 varies LR, not beta2. PR #123 adds a new
right-preconditioner, not the beta2 of the existing left+right SOAP preconditioner.
The `set_hparams(step)` function is already called every step and updates optimizer group
LRs — it is the natural place to also propagate the annealed beta2 to the Muon optimizer.
The `Muon.step()` already reads from `self.beta2` (or passes it to soap functions); adding
a `soap_beta2` field to param groups that is updated by `set_hparams` is a minimal change.

### Code change

Three modifications to `records/track_3_optimization/train_gpt_simple.py`:

1. Add CLI arg:
```python
parser.add_argument("--soap_beta2_final", type=float, default=0.90,
                    help="Final SOAP beta2 at end of cooldown (0.90=no annealing, 0.75=recommended)")
```

2. In `set_hparams(step, cooldown_frac=0.7)`, after setting LRs, add:
```python
soap_beta2_initial = SOAP_BETA2  # = 0.90
soap_beta2_final = args.soap_beta2_final  # e.g. 0.75
stable_end = 1.0 - cooldown_frac  # = 0.30
if progress >= stable_end:
    cooldown_t = (progress - stable_end) / cooldown_frac
    current_soap_beta2 = soap_beta2_initial - (soap_beta2_initial - soap_beta2_final) * cooldown_t
else:
    current_soap_beta2 = soap_beta2_initial
for group in optimizer2.param_groups:
    group["soap_beta2"] = current_soap_beta2
```

3. In `Muon.step()`, when calling `soap_precondition_momentum` and
   `soap_update_preconditioner`, read the current beta2 from the param group:
```python
soap_beta2 = group.get("soap_beta2", SOAP_BETA2)
soap_precondition_momentum(update, state, beta2=soap_beta2)
soap_update_preconditioner(grad, state, shampoo_beta=soap_beta2, precondition_frequency=freq)
```

Both `soap_precondition_momentum` and `soap_update_preconditioner` already accept `beta2`
and `shampoo_beta` as keyword arguments (confirmed at lines 505-528 of the training script).

Launch command:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --soap_attn \
  --soap_beta2_final 0.75 \
  --wandb_name "nezuko/soap-beta2-anneal-075" \
  --wandb_group "pr-nezuko-soap-beta2-anneal"
```

Screen seeds 1-2 first. Consider also a 2-seed screen of `--soap_beta2_final 0.80` and
`--soap_beta2_final 0.70` in parallel on a single pod if the first screen is fast
(total: 6 seeds for 3 values). Choose best value for full n=6 confirmation.

### Expected effect size

Adam beta2 annealing literature (e.g., Zhai et al. "Scaling ViT", Wortsman et al. 2023)
reports gains of 0.2-0.5% perplexity from beta2 annealing during fine-tuning. At this
benchmark's scale, that maps to roughly 0.0003-0.0008 in mean_loss. The gain depends on
how much the stable-phase curvature statistics pollute the cooldown phase — if the gain
is real, it should be visible in lower val/slope/loss_per_step during the final 20% of
training.

### Kill gates

- If n=2 mean_loss > 3.279 for best beta2_final value, close as negative.
- If val/loss trajectory during cooldown is not steeper than baseline (inspect W&B
  val/slope), the annealing is having no effect — stop early.
- Full confirm target: n=6, mu <= 3.27210.

---

## Idea 3: Trust gate threshold activation (threshold=0.3)

### What it is

Change `--soap_trust_threshold` from 0.0 (decorative) to 0.3. No code change — this is a
single CLI arg change to an existing feature. When cos_sim between the SOAP update and the
plain-Muon update falls below 0.3, the update falls back to plain Muon for that parameter.

### Why it might help

The trust gate mechanism (PR #116) was designed to prevent SOAP from taking a step in a
direction materially different from the Muon direction. At threshold=0.0, it never fires
because cos_sim is always >= 0.033. At threshold=0.3, it will fire on the lower-cos_sim
attn params (where cos_sim can be ~0.1-0.2 based on the logged values) and not fire on the
high-cos_sim MLP params (cos_sim typically 0.3-0.5). This is effectively a confidence
filter: use the richer SOAP preconditioned direction when SOAP agrees well with momentum,
fall back to the momentum-only Muon step when the preconditioner would push in a materially
different direction.

The hypothesis is that there exist attn weight directions where the SOAP preconditioner's
eigendecomposition is stale or poorly conditioned, causing it to occasionally prescribe
updates that diverge from the momentum direction. These outlier updates hurt convergence.
The trust gate at 0.3 filters them out without affecting MLP weights where SOAP is
consistently well-aligned.

### Mechanism and failure mode targeted

Failure mode: occasional SOAP direction divergence for attn params with stale or noisy
eigenbases. The gate fires only when cos_sim < 0.3, which empirically corresponds to attn
params with the lowest preconditioner quality. For those params on those steps, falling back
to plain Muon avoids a potentially harmful update.

### Orthogonality argument

This tests a different property from PR #141 (GC, which modifies the input to NS) and
PR #123 (Newton-Muon, which adds a right-preconditioner before NS). The trust gate selects
between two completed update directions at the output of SOAP; it does not modify the SOAP
algorithm itself.

### Code change

Zero code change. Just change the CLI arg:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --soap_attn \
  --soap_trust_threshold 0.3 \
  --wandb_name "<student>/trust-gate-03" \
  --wandb_group "pr-<student>-trust-gate"
```

Also screen threshold=0.2 and threshold=0.4 in the same batch (3 seeds per value = 9 total
seeds for the screen, choose best for n=6 confirmation).

### Expected effect size

Low risk, low-to-medium upside. If the gate rarely fires (cos_sim > 0.3 most of the time
for most params), the effect will be minimal. If it fires ~5-15% of the time for the
lowest-cos_sim attn params, the expected gain is 0.0002-0.0006 in mean_loss. The experiment
is essentially free: no code changes, no memory overhead, and the existing cos_sim logging
in W&B will show the gate activation rate directly.

### Kill gates

- If gate fires on > 50% of attn steps (visible in W&B cos_sim histogram), the threshold
  is too high and is effectively disabling SOAP for attn — try lower threshold.
- If n=2 mean_loss > 3.279, close as negative.

---

## Idea 4: SOAP to lm_head.weight (col-only, precond_freq=32)

### What it is

Move lm_head (`model.proj.weight`, 50304×768) from AdamW (lr=1/320) into the Muon+SOAP
optimizer, but use only the col-side Gram matrix (768×768) rather than the row-side
(50304×50304 — computationally infeasible). Use precond_freq=32 to limit memory overhead.

### Why it might help

lm_head.weight is the largest parameter (50304×768 ≈ 38.6M params, ~37.1 MB bfloat16) and
maps the final hidden state to logit space. It currently uses AdamW with scalar adaptivity
per element — no structural second-order information about how different hidden dimensions
correlate in their contribution to vocabulary logits. SOAP on the col-side (768×768 Gram
for the hidden dimension) would give the optimizer knowledge of the covariance structure
among hidden dimensions as they project to vocabulary space. This is orthogonal to the
row-side covariance (vocabulary-space covariance, which would be 50304×50304).

### Memory concern

The col-side Gram matrix for lm_head is 768×768 × float32 = 2.36 MB. This is negligible.
The row-side would be 50304×50304 ≈ 9.6 GB — clearly infeasible. The col-only SOAP mode
needs to be implemented explicitly in the `soap_update_preconditioner` function by skipping
the row-side eigendecomposition when `m > col_threshold` (e.g., col_threshold=4096).

### Code changes (moderate complexity)

1. Add `model.proj.weight` to the Muon optimizer instead of AdamW:
```python
# Move from optimizer1 (AdamW) to optimizer2 (Muon) param group
# Remove dict(params=[model.proj.weight], lr=1/320, name="adam_lm_head") from optimizer1
# Add model.proj.weight to Muon params with special col-only flag
```

2. Add col-only mode to `soap_update_preconditioner`:
```python
def soap_update_preconditioner(grad, state, shampoo_beta=SOAP_BETA2,
                                precondition_frequency=PRECOND_FREQ, col_only=False):
    m, n = grad.shape[-2], grad.shape[-1]
    # If col_only or m is too large, skip row_gg and only maintain col_gg
    if col_only or m > 4096:
        # Only update col_gg (n×n) — skip row_gg
        ...
```

3. In `soap_precondition_momentum`, when row_gg is missing (col-only mode), only project
   along the column eigenbases.

4. Set initial lr for lm_head in Muon group to match existing effective lr ~= 1/320 / eta
   at step 0. A reasonable starting point: lr=0.01 (Muon), tuned to match prior AdamW lr
   effective scale, with wd=0.01.

### Risk and recommendation

This is higher complexity than ideas 1-3. The col-only SOAP path requires new code in the
preconditioner functions. Memory budget is already 75.23/80 GB — adding lm_head to Muon
SOAP state adds ~50 MB total (col_gg + eigendecomposition buffers), which is acceptable.
The risk is that the new code path introduces a bug, or that lm_head does not benefit from
col-only SOAP (vocab-dimension correlations are what matter for lm_head, not hidden-dim
correlations). Recommend running as a wave-4 idea, after wave-3 confirms or closes.

---

## Idea 5: KL-divergence loss / PMuon (records #19/#18 wave-3/4 candidates)

### What it is

Two related ideas from the CURRENT_RESEARCH_STATE wave-3/4 candidate list:

**KL-SOAP-H**: Replace the cross-entropy training loss with a KL-divergence formulation
against a smoothed target distribution, using the SOAP preconditioner to align the gradient
geometry with the KL loss manifold rather than the CE loss manifold.

**PMuon**: A momentum-preconditioned variant of Muon that uses the accumulated momentum
buffer as a proxy for the Hessian diagonal, providing a low-cost curvature estimate without
maintaining explicit covariance matrices.

These are wave-4 candidates — their specifications are less developed and require more
preliminary literature research before assignment. Do not assign until wave-3 closes or
the current portfolio thins out.

---

## Idea 6: Asymmetric per-group weight decay (wd_mlp vs wd_attn)

### What it is

Split Muon param groups by SOAP suffix membership and tune weight decay separately:
`wd_mlp` for SOAP_MLP_SUFFIXES params and `wd_attn` for SOAP_ATTN_SUFFIXES params.
Active PR #162 sweeps lr_mlp but keeps wd fixed at baseline — this is orthogonal.

### Why it might help

SOAP preconditioning changes the effective update scale per parameter direction. For
MLP params, SOAP amplifies low-curvature directions — these directions have large effective
updates relative to their raw gradient. L2 weight decay acts on the raw parameter values,
not the effective update scale. This means the effective regularization strength per
direction is inversely proportional to curvature for SOAP params. For plain-Muon attn
params, the effective update scale is more uniform across directions (no per-direction
curvature correction), so the weight decay is more evenly applied. Separate wd tuning
allows matching regularization to the actual update scale in each group.

### Mechanism and failure mode targeted

Failure mode: suboptimal regularization. If wd_mlp is too high relative to the large
SOAP update scale for low-curvature MLP directions, it creates a net restoring force that
competes with the optimizer's direction. If wd_attn is slightly off, it affects plain-Muon
attn params directly. The expected gain is modest (wd is a relatively weak lever once the
optimizer is well-tuned), but the experiment is low-cost and orthogonal to PR #162.

### Code change

Split optimizer2 Muon param group into two:
```python
mlp_params = [(n, p) for n, p in model.blocks.named_parameters()
              if p.ndim >= 2 and any(n.endswith(s) for s in SOAP_MLP_SUFFIXES or ...)]
attn_other_params = [(n, p) for n, p in model.blocks.named_parameters()
                     if p.ndim >= 2 and not (n, p) in mlp_params]
optimizer2 = Muon(mlp_params + attn_other_params, ...)
# ... with separate group config for wd_mlp and wd_attn
```

Suggested screen: fix lr=0.035 for both groups, sweep:
- `wd_mlp in {0.015, 0.025, 0.035}` (baseline=0.025)
- `wd_attn in {0.015, 0.025, 0.035}` (baseline=0.025)
Run 2-seed screen on {0.015, 0.025, 0.035}^2 = 9 combinations (18 seeds). Choose best
for n=6 confirmation. Close without n=6 if best 2-seed mean_loss > 3.279.

---

## Recommended Assignment

**fern → Idea 1: Adaptive precond_freq split (attn=8, MLP=16)**
- Directly motivated by measured attn cos_sim gap
- Minimal code change (2 function arguments + 1 CLI arg)
- High mechanistic grounding, low risk

**nezuko → Idea 2: SOAP beta2 annealing during cooldown (0.90 → 0.75)**
- Motivated by beta2 annealing literature in LLM training
- Clean 3-line change to set_hparams + 2 argument passes
- Orthogonal to all active WIPs

Ideas 3-6 are wave-3/4 candidates for the next idle student slots.
Priority order after ideas 1-2: Idea 3 (trust gate, zero code change), Idea 6
(asymmetric wd, low complexity), Idea 4 (SOAP lm_head, moderate complexity),
Idea 5 (KL/PMuon, requires more spec work).
