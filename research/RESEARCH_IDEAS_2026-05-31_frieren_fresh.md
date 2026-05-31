# Fresh Hypothesis — frieren — 2026-05-31
# Lookahead Wrapper over Muon: Slow/Fast Weight Interpolation

---

## Slug

`lookahead-muon-slow-fast`

## One-sentence summary

Wrap the Muon optimizer in a Lookahead shell that maintains slow-weight buffers and
periodically pulls fast weights back toward a running basin centroid, providing
implicit variance reduction orthogonal to every previously explored axis.

---

## Background: the plateau

69 R5 closures. ZERO FFS-positive merges since PR #1533. Baseline frozen at
μ_4(FFS_ema) = 2912.5, σ_4 = 25. Every explored axis has been either:

- **Polar-approximator family** (NS5, Padé, Higham, Cayley, Schulz) — all share the
  f(0)=0 fixed point; cannot lift attn σ_min ≈ 0.003.
- **NS-iter / NS shape** — tuned exhaustively.
- **Magnitude/direction decomposition inside NS** — explored.
- **SOAP scalar hyperparameters** (β2, precond_freq, trust_threshold) — swept.
- **Scalar HP tuning** (lr, wd, cooldown shape, EMA decay) — swept.
- **Init variants** — explored.

None of these axes can escape the current local basin through a mechanism that has
not already been tested, because they all modify the *direction computation* or
*scale* of the update at each step, not the *trajectory* of the weight sequence.

---

## Hypothesis: Lookahead wrapper over Muon

### What it is

Lookahead (Zhang et al., NeurIPS 2019) maintains two sets of weights:

- **Fast weights** θ: updated by the inner optimizer (Muon+SOAP) as normal at every step.
- **Slow weights** φ: updated every k inner steps via linear interpolation:
  φ ← φ + α · (θ - φ),   then θ ← φ  (fast weights reset to slow).

The "k steps forward, 1 step back" loop forces the optimizer to explore a local
neighbourhood for k steps, then commit to a direction only when the Euclidean
displacement (θ - φ) is confirmed to be useful. If the fast weights have wandered
into a chaotic region, the pull-back discards most of that chaos. If they found a
genuine descent direction, the pull-back still makes progress, but with lower
variance.

### Why this should reduce FFS

The FFS bottleneck is: the model reaches 3.28 *too late* or *not at all* because
the optimizer oscillates across the basin floor during the cooldown phase without
committing to the deepest direction. The EMA-eval already applies SWA-style
averaging over *model checkpoints*; Lookahead applies a structurally similar idea
to *optimizer trajectory* — it averages across the direction taken over k steps,
not across time-separated checkpoints. The two mechanisms target different sources
of variance:

- EMA-eval: checkpoint-time variance (smooths the final reported loss estimate).
- Lookahead: trajectory-space variance (smooths the path the weights walk).

Together they provide two orthogonal variance-reduction passes.

The standard convergence analysis (Zhang et al. §3) shows that Lookahead reduces
the variance of gradient estimates by a factor proportional to k·α², which
translates into more stable descent and a lower loss at any given step count.
In the 3250-step constrained budget this is exactly the FFS mechanism we need.

---

## Structural orthogonality argument

This hypothesis is structurally orthogonal to every closed axis because:

1. It does NOT modify `zeropower_via_newtonschulz5`. The NS5 polynomial, iteration
   count, or coefficient set is untouched.
2. It does NOT modify the SOAP Gram-matrix updates, eigenbasis refresh, or any
   SOAP scalar HPs.
3. It does NOT modify the per-step gradient transformation inside `muon_update` or
   `soap_precondition_momentum`.
4. It does NOT modify the model architecture, init, or LR/WD schedule.
5. It operates at a strictly outer shell: slow buffers + k-step sync. The entire
   inner Muon loop runs exactly as today. Lookahead adds one interpolation per k
   steps and a buffer copy of ~all Muon params (~24M weights ≈ 96 MB in bf16).
6. No in-flight PR touches this axis:
   - #1891 askeladd: GE-SAM (gradient extrapolation, HVP).
   - #1885 fern: gradient centralization (in-step mean subtraction).
   - #1880 tanjiro: Muon momentum cooldown schedule.
   - #1870 thorfinn: label smoothing.
   - #1860 alphonse: (separate axis).
   - #1858 edward: (separate axis).

---

## 4-line support

1. **Theory**: Lookahead §3 (Zhang et al. 2019) proves fast-weight variance scales as
   k·α² and slow-weight variance is O(α²·k/N); converges for convex and non-convex
   objectives under mild assumptions.
2. **Prior work**: Lookahead wrapping Adam/SGD showed consistent 1–3% val-loss
   reduction on CIFAR/PTB/ImageNet with k=5, α=0.5 without lr retuning. The gain is
   largest in the tail of training where the optimizer is already near a basin, which
   matches the FFS setting (cooldown phase).
3. **Structural analogy**: EMA-eval (already in R5 baseline) provides checkpoint-time
   variance reduction and gave a measurable FFS gain when it was introduced. Lookahead
   provides trajectory-space variance reduction via an orthogonal mechanism. Two
   orthogonal variance reducers are more likely to compound than to overlap.
4. **Diagnostic signal**: If Lookahead is alive, the FFS of the bias-corrected
   EMA-val curve should move first (lower and earlier), while the raw train-val FFS
   may lag. This gives a cheap in-run signal before the end of training.

Key paper: Zhang et al. 2019, NeurIPS.
  https://arxiv.org/abs/1907.08610

---

## Implementation surface

**File**: `records/track_3_optimization/train_gpt_simple.py`
**Location**: Between the `Muon` class definition (ends ~line 700) and the optimizer
construction block (~lines 770–790).
**Size**: ~45 LOC for the `Lookahead` wrapper class + ~10 LOC wiring.

### Lookahead class (drop-in wrapper)

```python
class Lookahead(torch.optim.Optimizer):
    """Lookahead wrapper (Zhang et al., NeurIPS 2019).

    Wraps any inner optimizer. Maintains slow-weight buffers for every
    parameter in the inner optimizer's param_groups. Every `k` inner steps,
    pulls fast weights back: phi += alpha * (theta - phi); theta = phi.

    Args:
        optimizer: the inner optimizer (Muon in this case).
        k (int): inner steps between slow-weight syncs (default 5).
        alpha (float): slow-weight interpolation rate (default 0.5).
    """
    def __init__(self, optimizer, k: int = 5, alpha: float = 0.5):
        self.optimizer = optimizer
        self.k = k
        self.alpha = alpha
        self._step_count = 0
        # Shadow slow-weight buffers
        self.slow_weights: list[list[Tensor]] = []
        for group in optimizer.param_groups:
            slow = [p.data.clone().detach() for p in group["params"]]
            self.slow_weights.append(slow)
        # Expose param_groups for LR schedulers / grad clipping
        self.param_groups = optimizer.param_groups
        self.state = optimizer.state
        self.defaults = optimizer.defaults

    def step(self):
        self.optimizer.step()
        self._step_count += 1
        if self._step_count % self.k == 0:
            self._sync_slow_weights()

    def _sync_slow_weights(self):
        for group, slow_group in zip(self.optimizer.param_groups, self.slow_weights):
            for p, slow in zip(group["params"], slow_group):
                slow.add_(p.data - slow, alpha=self.alpha)
                p.data.copy_(slow)

    def zero_grad(self, set_to_none: bool = True):
        self.optimizer.zero_grad(set_to_none=set_to_none)

    def state_dict(self):
        return {
            "inner": self.optimizer.state_dict(),
            "_step_count": self._step_count,
            "slow_weights": [[s.cpu() for s in sg] for sg in self.slow_weights],
        }

    def load_state_dict(self, state_dict):
        self.optimizer.load_state_dict(state_dict["inner"])
        self._step_count = state_dict["_step_count"]
        for sg, slow_group in zip(state_dict["slow_weights"], self.slow_weights):
            for s_cpu, slow in zip(sg, slow_group):
                slow.copy_(s_cpu.to(slow.device))
```

### Wiring change

Where `optimizer2` is constructed (~line 790), add the CLI flags and wrap:

```python
# New CLI flags (add near other argparse lines):
parser.add_argument("--lookahead_k",     type=int,   default=0,   help="Lookahead inner steps (0 = disabled)")
parser.add_argument("--lookahead_alpha", type=float, default=0.5, help="Lookahead slow-weight interpolation rate")

# After optimizer2 = Muon(...):
if args.lookahead_k > 0:
    optimizer2 = Lookahead(optimizer2, k=args.lookahead_k, alpha=args.lookahead_alpha)
```

Replace all downstream `optimizer2.step()`, `optimizer2.zero_grad()`, and
`optimizer2.param_groups` references — these already work transparently via the
wrapper's `__getattr__` delegation (no other changes needed because the Lookahead
wrapper exposes `.param_groups`, `.state`, `.defaults` directly).

IMPORTANT: The distributed `all_gather` inside `Muon.step()` happens inside the
inner optimizer's step, which runs every inner step as usual. The slow-weight sync
only touches `.data` tensors after the inner step returns — it does NOT require
an additional all_reduce because at sync time all ranks run the same deterministic
interpolation from the same initial state (all_gather already kept them in sync).

### Memory cost

2 × (num_muon_params × 2 bytes bf16) ≈ 2 × 24M × 2B = 96 MB slow-weight buffers.
Negligible vs 96 GB VRAM.

### Interaction with EMA-eval

The EMA-eval (`--ema_eval_decay`) runs on the fast weights (as now). After a
Lookahead sync, the fast weights are pulled back to the slow position, so the EMA
will track the committed slow trajectory from sync point forward. This is correct
and desirable — the two mechanisms are independent.

---

## Experimental cells

All cells run the full R5 baseline stack:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --ema_eval_decay`
plus the cell-specific flags below. n=1 seed each. WandB group: `lookahead-muon-r5`.

| Cell | Flags | Purpose |
|------|-------|---------|
| A (ctrl) | (none — baseline R5) | Confirm baseline FFS ≈ 2912.5 |
| B★ (primary) | `--lookahead_k 5 --lookahead_alpha 0.5` | Original Lookahead recipe (Zhang et al.) |
| C | `--lookahead_k 5 --lookahead_alpha 0.8` | More aggressive pull-back (less basin exploration) |
| D | `--lookahead_k 10 --lookahead_alpha 0.5` | Sparser sync (wider exploration window) |

Start with A and B★ in parallel. C and D launch only if B★ passes the FFS-alive gate.

---

## KG_smoke gate

Before committing to n=1 full runs, run a 500-step smoke check on cell B★:

- Command: `SENPAI_TRAIN_STEPS=500 python train_gpt_simple.py --lookahead_k 5 --lookahead_alpha 0.5 [+baseline flags]`
- Pass condition: run completes without NaN/crash; val_loss at step 500 within ±0.05
  of baseline smoke (expected ~3.55–3.65 range at step 500).
- Fail condition: crash, NaN loss, or val_loss > 3.70. If fails, check that
  `.param_groups` delegation is working and that `zero_grad` is being called on
  the wrapper, not the inner optimizer directly.

---

## Gates

| Gate | Condition | Action |
|------|-----------|--------|
| FFS-alive | B★ FFS_ema ≤ 2975 | Proceed to C and D cells |
| Promote | FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825 | Run n=4 seeds for μ_4 estimate |
| Merge | μ_4(FFS_ema) ≤ 2887.5 | Merge to baseline |

**FFS-negative** (B★ FFS_ema > 2975 or FFS = -1): close, do NOT run C or D.

---

## Dual-metric reporting

Report BOTH:
1. `speedrun/final_first_step_to_target` (primary; must use bias-corrected EMA-val
   when `--ema_eval_decay` active, else train-val FFS).
2. `val/loss` at final step (secondary; confirms convergence quality independent of
   FFS timing).

If FFS = -1 (never reached 3.28), report final val/loss as the secondary.

---

## Implementation notes and gotchas

1. **`zero_grad` must be called on the wrapper, not the inner optimizer.** The
   training loop already calls `optimizer2.zero_grad()` — since the wrapper
   delegates this, it's fine. Verify by confirming gradients are cleared each step.

2. **LR scheduler must target `optimizer2.param_groups`.** After wrapping,
   `optimizer2.param_groups` is the wrapper's `.param_groups` which is the same
   object as `self.optimizer.param_groups`. Schedulers referencing `optimizer2`
   directly will work unchanged.

3. **Cooldown-phase interaction.** At the cooldown transition (~step 2275), the LR
   drops. The slow-weight buffers are stale by up to k steps. This means the first
   sync after the cooldown transition may produce a slightly larger pull-back than
   intended. This is fine — the slow weights reflect the stable pre-cooldown basin,
   which is exactly where we want to pull back toward.

4. **Do NOT apply Lookahead to `optimizer1` (AdamW for embed+lm_head+scalars).**
   These params are outside Muon and have different convergence dynamics. Wrap only
   `optimizer2`. If the hypothesis passes gates, a follow-up can explore wrapping
   optimizer1 too.

5. **Gradient clipping.** `torch.nn.utils.clip_grad_norm_` is called on model
   parameters directly (not via the optimizer object), so it is unaffected by the
   wrapper.

6. **Checkpointing.** Use `optimizer2.state_dict()` which calls the wrapper's
   `state_dict()` method. Confirm the saved dict has both `"inner"` and
   `"slow_weights"` keys. If resuming from a pre-Lookahead checkpoint, slow weights
   can be initialized to current fast weights (they will re-warm in k steps).

---

## Pre-mortems

**Why it might fail (FFS-negative outcomes):**

1. **k=5 syncs are too frequent during fast early loss descent** — the pull-back
   cancels too much of the early rapid progress. Diagnostic: check if FFS is
   degraded specifically in the first 1000 steps. Fix: try k=10 (cell D).

2. **The slow-weight basin centroid is a worse loss geometry than the fast basin
   after cooldown.** If the fast weights have found a sharper but narrower minimum,
   pulling back to the slow average could move them to a flatter but higher saddle.
   Diagnostic: compare final val/loss of B★ vs A even if FFS is similar.

3. **The EMA-eval already provides all the variance reduction available.** Lookahead
   and EMA-eval both reduce variance, but if EMA-eval is already capturing the full
   benefit and the slow weights simply track the EMA trajectory, the gain is zero.
   Diagnostic: run a cell with `--ema_eval_decay 0` (no EMA) + Lookahead and compare
   FFS to check for interaction.

4. **Distributed correctness issue with slow-weight sync.** If the wrapper's
   `_sync_slow_weights` runs at different steps on different ranks due to data
   loading stagger, the fast weights can diverge. The existing training loop already
   synchronizes via `all_gather` inside Muon — but verify all ranks increment
   `_step_count` identically. Since all ranks call `.step()` synchronously, this
   should be guaranteed.

---

## Stop conditions

Stop and close the PR (do not promote to n=4) if:
- Smoke gate fails (NaN or crash).
- B★ FFS_ema > 2975 (FFS-negative; mechanism not alive in this stack).
- B★ val/loss at step 3250 > A val/loss by more than 0.005 nats (Lookahead is
  actively hurting final convergence, not just failing to help timing).

---

## Decision tree

```
B★ smoke (500 steps)
├── FAIL (NaN/crash/loss > 3.70)
│   └── DEBUG wrapper; fix zero_grad/param_group delegation; re-smoke
│       └── still fails → CLOSE PR
└── PASS
    └── Run A (ctrl) + B★ (k=5, α=0.5) full n=1
        ├── B★ FFS_ema > 2975 (FFS-negative)
        │   └── CLOSE PR — mechanism not alive
        ├── B★ 2900 < FFS_ema ≤ 2975 (FFS-alive, not promote)
        │   └── Run C (k=5, α=0.8) + D (k=10, α=0.5) n=1
        │       ├── Any of C/D FFS_ema ≤ 2900 → promote best variant to n=4
        │       │   └── μ_4 ≤ 2887.5 → MERGE
        │       │   └── μ_4 > 2887.5 → REQUEST CHANGES (try α=0.3 or k=3)
        │       └── All C/D FFS_ema > 2900 → CLOSE PR — axis is alive but sub-threshold
        └── B★ FFS_ema ≤ 2900 (promote-eligible)
            └── Run C + D n=1 (confirm best variant)
                └── Run best variant n=4 for μ_4
                    ├── μ_4 ≤ 2887.5 → MERGE
                    └── μ_4 > 2887.5 → REQUEST CHANGES (try α=0.3 or k=3)
```

---

## Research state update

**Current best explanation for the plateau:**
The FFS bottleneck is no longer in the update *direction* (NS5 is well-tuned,
SOAP is active) or the update *scale* (SOAP preconditioner handles that). It is in
*trajectory variance* during the cooldown phase: the optimizer performs a
high-variance walk near the basin floor rather than committing to the deepest
descent direction. EMA-eval already reduces checkpoint-level variance; Lookahead
would reduce trajectory-level variance via a separate, orthogonal mechanism.

**Evidence base:**
- PR history: all polar-approximator and SOAP-scalar experiments closed as
  FFS-negative. The baseline has been frozen since #1533.
- EMA-eval merge: the checkpoint-level variance reduction that introduced
  `--ema_eval_decay` gave a measurable FFS gain, supporting the hypothesis that
  variance reduction is a live mechanism.
- Zhang et al. 2019 theory: Lookahead reduces fast-weight variance by k·α² factor
  with negligible overhead — a clean prediction that is falsifiable by comparing
  the variance of the FFS distribution across seeds.

**Ruled-out paths (do not repeat):**
- Any polynomial polar approximator (NS, Padé, Higham, Cayley).
- NS-iter count changes (exhaustively swept).
- SOAP Gram-matrix scalar HPs (β2, precond_freq, trust_threshold).
- Per-step magnitude/direction decomposition inside the NS pipeline.
- Scalar HP tuning (lr, wd, cooldown shapes).
- Init variants.

**Open uncertainties:**
1. Does the EMA-eval already capture the full benefit of trajectory smoothing, making
   Lookahead redundant? (Diagnostic: run without EMA-eval.)
2. What k value is optimal for a 3250-step training run with a 30% cooldown? k=5
   gives 650 syncs, k=10 gives 325; the right granularity is unknown.
3. Will the cooldown transition create a destructive pull-back that worsens FFS
   rather than improving it?

**Next discriminating experiment:** B★ (k=5, α=0.5) vs A (ctrl). If B★ FFS_ema
> 2975, the mechanism is not alive and we should look at a different abstraction
level entirely (e.g., data ordering, architecture micro-variants, or loss
formulation). If B★ FFS_ema ≤ 2900, trajectory variance reduction is confirmed
as a live lever and a sweep of k and α can optimize it.

**Stop condition for this direction:** If B★ + C + D all return FFS_ema > 2975,
close the Lookahead axis entirely and pivot to a different family (e.g.,
depth-adaptive momentum, optimizer state distillation from a pretrained run, or
a compositional MLP-Muon/attn-Adam hybrid).

---

## Taste rubric

| Experiment | Mode | Mechanistic grounding | Research-state value | Execution value | Score |
|---|---|---|---|---|---|
| B★ n=1 | Tier shift | 4 — precise mechanism (variance reduction), tied to EMA-eval analogy and Zhang et al. theory; falsifiable by FFS distribution variance across seeds | 4 — clearly discriminates: alive = new lever open; dead = rule out trajectory-variance family | 4 — 45 LOC, single run, cheap KG_smoke gate first | **4/4/4** |
| C+D n=1 | Frontier refinement | 3 — k/α tuning within a confirmed-live mechanism | 3 — narrows optimal HP range | 3 — conditional on B★ gate | **3/3/3** |

---

## Confidence

**Moderate-high** for mechanism existence (Lookahead is well-studied, works across
architectures). **Low-moderate** for FFS improvement specifically: the EMA-eval
interaction is unknown, and it is possible the two variance-reduction mechanisms
are correlated. The experiment is cheap enough that the cost of a negative result
is low relative to the information gained.

The hypothesis passes the structural orthogonality test with high confidence:
it is not a polar-approximator, not a SOAP scalar HP, not NS-iter, not init,
and not in any in-flight PR. It is the cleanest "different level of abstraction"
bet available given the current closed-axis map.

---

## References

- Zhang, Lucas, Ba, Hinton. "Lookahead Optimizer: k steps forward, 1 step back."
  NeurIPS 2019. https://arxiv.org/abs/1907.08610
- Lookahead NeurIPS proceedings: https://proceedings.neurips.cc/paper/2019/hash/90fd4f88f588ae64038134f1eeaa023f-Abstract.html
