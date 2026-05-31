# Hypothesis: NS-Iter Cooldown Schedule (`ns-iter-cooldown`)

**Slug:** `ns-iter-cooldown`
**Student:** g1r5-tanjiro
**Date:** 2026-05-31
**File:** `RESEARCH_IDEAS_2026-05-31_tanjiro_fresh_3.md`

---

## One-Sentence Summary

Switch `ns_iter` (Newton-Schulz iteration count) from 12 to a smaller value at 75% training progress, reducing over-orthogonalization during the deep cooldown window when LR has already decayed ~70× and tight Stiefel projection may be interfering with fine-grained loss descent.

---

## Mechanism (3-4 sentences)

Newton-Schulz iteration count controls how tightly Muon projects gradients onto the Stiefel manifold: more iterations produce updates closer to true orthogonal matrices, which is optimal during high-LR exploration where gradient diversity matters. During the deep cooldown phase (steps 975–3250), the effective learning rate collapses ~100×, meaning each optimizer step moves weights by ~100× less; at this scale, the strict orthogonal constraint imposed by 12 NS iterations may over-constrain the update geometry relative to the local Hessian curvature, preventing fine-grained alignment that would help cross the 3.28 threshold. Reducing NS iterations from 12 to 6 (or 4) after step ~2438 (75% progress) relaxes the orthogonality constraint during the FFS crossing window, allowing updates that are "approximately orthogonal" rather than tightly orthogonal — which may better track curvature in the low-LR regime. The switch occurs after the fast-descent phase is complete, so the high-diversity exploration benefit of tight NS projection is preserved during the most weight-movement-critical early training.

---

## Distinctness from Prior Work

| Family | Mechanism | Why This Differs |
|--------|-----------|-----------------|
| SGLD/additive-pre-NS5 (PR #1891, closed 76th) | Adds gradient noise before NS projection, absorbed by NS | This changes NS projection strength itself (iteration depth), not pre-NS content |
| GE-SAM (PR #1891, closed 76th) | SAM perturbation added before NS; absorbed | Same absorption failure mode — but this is the NS projection itself |
| GC (gradient centralization, closed family) | Centers gradient before NS; absorbed | Same — pre-NS modifier |
| μ cooldown (PR #1880, closed 74th) | Schedules Muon momentum coefficient | Changes momentum blend, not NS iteration count |
| QKV ortho init (PR #1937, closed 80th) | Orthogonal init at construction time; NS absorbs at step 1 | This is a runtime schedule of NS depth — not init-time |
| LN gain init (PRs #1903, #1907) | Reduces LayerNorm γ; double-counts variance suppression | Completely different axis — NS iteration count vs. normalization |
| ns_iter=6 baseline (current mandatory stack) | Reduces ns_iter uniformly from 12 to 6 throughout | This is a **schedule**: 12 early → reduced late; early NS strength preserved |
| PRECOND_FREQ cooldown (PR #1948, active) | Schedules how often SOAP preconditioner updates | SOAP preconditioner frequency vs. NS iteration depth — different optimizer component |
| EMA decay cooldown (PR #1957, active) | Schedules EMA decay coefficient during cooldown | EMA eval, not optimizer orthogonalization |
| muon-depth-lr-scale (PR #1941, active) | Per-layer LR scaling by depth in Muon | LR scaling, not NS iteration count |

**Key distinctions from the mandatory-stack ns_iter=6:**
The current mandatory stack already lowered ns_iter from 12 to 6 uniformly. This hypothesis asks whether the full 12-iteration orthogonality is beneficial during early high-LR exploration but harmful during late low-LR fine-tuning. The schedule (12→6 at 75% progress) is a distinct mechanism from a flat reduction.

---

## Prior Art and Theoretical Grounding

Newton-Schulz iteration convergence: the NS5 iteration converges to the orthogonal factor of the polar decomposition at a cubic rate. At ns_iter=12, the projection is essentially exact (error < 1e-10 for well-conditioned matrices). At ns_iter=6, there is residual non-orthogonality that effectively acts as a soft constraint. At ns_iter=4, the approximation is coarser but still directionally orthogonal.

Theoretical motivation: In the Muon optimizer paper (Kosson et al. 2024), the Stiefel projection is motivated by spectral efficiency during high-LR training — ensuring update directions are maximally diverse. During cooldown, however, the effective update magnitude is so small (~1e-4 × full-LR scale) that the orthogonality constraint's main effect may be to prevent the optimizer from following the locally optimal gradient direction when that direction projects weakly onto the Stiefel manifold.

Analogous evidence from other schedules: `lr_cooldown_shape` experiments (FFS improvements from cosine vs. linear cooldown) demonstrate that cooldown-phase optimizer geometry matters independently of LR magnitude. The `precond-freq-cooldown-schedule` PR (#1948) tests the same axis for SOAP. This tests it for Muon's NS component.

---

## Implementation Surface

### New CLI Arguments (add after line 70 of `train_gpt_simple.py`)

```python
parser.add_argument("--ns_iter_late", type=int, default=None,
    help="NS iteration count to switch to after ns_iter_switch_frac of training remains. "
         "None = no switch (ns_iter used throughout). E.g., 6 or 4.")
parser.add_argument("--ns_iter_switch_frac", type=float, default=0.25,
    help="Fraction of training REMAINING when ns_iter switches to ns_iter_late. "
         "Default 0.25 = switch at 75%% of total steps (step ~2438 for train_steps=3250). "
         "E.g., 0.50 = switch at 50%% (step ~1625).")
```

### New Globals (add after line 113, after `NS_ITER = args.ns_iter`)

```python
NS_ITER_LATE = args.ns_iter_late if args.ns_iter_late is not None else NS_ITER
```

### Late NS5 Function and Compiled Pairs (add after line 518, after `zeropower_via_newtonschulz5`)

```python
# Late-phase NS5 using NS_ITER_LATE as compile-time constant.
# Must be a separate function — torch.compile bakes in the loop bound.
def zeropower_via_newtonschulz5_late(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(NS_ITER_LATE):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X


@torch.compile
def muon_update_late(grad, momentum, mu=0.95, nesterov=True):
    """Late-phase Muon update using NS_ITER_LATE. Identical to muon_update except NS fn."""
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5_late(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update


@torch.compile
def soap_ns_step_late(nesterov_update):
    """Late-phase SOAP-NS step using NS_ITER_LATE."""
    update = zeropower_via_newtonschulz5_late(nesterov_update)
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
    return update
```

### Training Loop Modification (in the optimizer step loop, before or around line 1156)

The switch logic must be evaluated per step. The cleanest approach is to compute the switch step once before the loop and use a boolean flag per step:

```python
# --- Before the training loop (after train_steps is defined, ~line 800) ---
_ns_switch_step = (
    int(train_steps * (1.0 - args.ns_iter_switch_frac))
    if args.ns_iter_late is not None
    else train_steps + 1  # never switch if ns_iter_late not set
)
```

Then inside the training loop, before the optimizer `.step()` calls (around line 1183):

```python
# --- Inside training loop, before opt.step() calls ---
_use_late_ns = (step >= _ns_switch_step) and (NS_ITER_LATE != NS_ITER)
```

The Muon optimizer's `step()` function calls `muon_update` internally. To inject the late function, the Muon optimizer's step method needs to be parameterized. The simplest approach that avoids modifying the optimizer class: add a module-level mutable reference and patch the optimizer's NS function.

**Alternative (simpler, preferred): Monkey-patch via a mutable cell in the Muon step**

Add a single mutable reference at module level after the compiled pairs:

```python
# Mutable cell for the current NS function pair (patched at each step boundary)
_current_muon_update_fn = [muon_update]       # list so it's mutable
_current_soap_ns_step_fn = [soap_ns_step]     # list so it's mutable
```

In the Muon optimizer's `step` method, replace direct calls to `muon_update(...)` with `_current_muon_update_fn[0](...)` and `soap_ns_step(...)` with `_current_soap_ns_step_fn[0](...)`.

Then in the training loop:

```python
# NS function switching — evaluated once per training step
if step == _ns_switch_step and NS_ITER_LATE != NS_ITER:
    _current_muon_update_fn[0] = muon_update_late
    _current_soap_ns_step_fn[0] = soap_ns_step_late
    if master_process:
        print(f"[NS switch] step={step}: ns_iter {NS_ITER} → {NS_ITER_LATE}")
```

**W&B logging for the switch (add to telemetry around line 1120 area):**

```python
wandb.log({
    "train/ns_iter_current": NS_ITER_LATE if _use_late_ns else NS_ITER,
    "train/ns_iter_switched": float(step >= _ns_switch_step and NS_ITER_LATE != NS_ITER),
}, step=step, commit=False)
```

### Total Implementation Size

- New CLI args: ~8 LOC
- New global: ~1 LOC
- Late NS5 + compiled pairs: ~20 LOC
- Mutable cell + training loop switch: ~8 LOC
- W&B telemetry: ~5 LOC

**Total: ~42 LOC** (all additive, no deletions from existing code paths)

---

## Cells

### Cell A_ctrl — Baseline (no switch)

**Purpose:** Confirm current ns_iter=6 baseline is stable on this run.

**Command:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "tanjiro/ns-iter-cooldown-A-ctrl" \
  --wandb_group "ns-iter-cooldown" \
  --ns_iter 6 \
  --soap_attn \
  --lr_mlp 0.055 \
  --wd_schedule ramp_down \
  --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99
```

**Expected FFS:** ~3025 (baseline). If >3100 or never reaches target, flag before running B★.

---

### Cell B★ — NS-iter 12→6 at 75% (PRIMARY)

**Purpose:** Test whether reducing ns_iter from 12 to 6 at 75% progress improves FFS vs. baseline ns_iter=6 throughout.

**Command:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "tanjiro/ns-iter-cooldown-B-12to6-75pct" \
  --wandb_group "ns-iter-cooldown" \
  --ns_iter 12 \
  --ns_iter_late 6 \
  --ns_iter_switch_frac 0.25 \
  --soap_attn \
  --lr_mlp 0.055 \
  --wd_schedule ramp_down \
  --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99
```

**Expected FFS:** Target ≤2950 for signal. The mandatory-stack ns_iter=6 is already established as better than ns_iter=12 throughout — so B★ tests whether a hybrid (12 early, 6 late) beats both flat 12 and flat 6.

**Why this might improve over flat ns_iter=6:** Early training (steps 0–2438) benefits from full 12-iteration orthogonality for maximal gradient diversity. Late training (steps 2438–3250) switches to 6 iterations, matching the already-proven beneficial ns_iter=6 during cooldown. The hypothesis is that the early training is harmed by ns_iter=6 (too loose), while late training benefits from it.

---

### Cell C — NS-iter 12→4 at 75% (deeper reduction)

**Purpose:** Test whether even fewer NS iterations in the late phase improves FFS further.

**Command:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "tanjiro/ns-iter-cooldown-C-12to4-75pct" \
  --wandb_group "ns-iter-cooldown" \
  --ns_iter 12 \
  --ns_iter_late 4 \
  --ns_iter_switch_frac 0.25 \
  --soap_attn \
  --lr_mlp 0.055 \
  --wd_schedule ramp_down \
  --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99
```

**Run C only if B★ shows FFS_ema ≤ 2920.** If B★ is FFS-NEUTRAL, C is unlikely to differ.

---

### Cell D — NS-iter 12→6 at 50% (earlier switch)

**Purpose:** Test whether switching earlier (at 50% progress, step ~1625) during the cooldown onset improves FFS.

**Command:**
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "tanjiro/ns-iter-cooldown-D-12to6-50pct" \
  --wandb_group "ns-iter-cooldown" \
  --ns_iter 12 \
  --ns_iter_late 6 \
  --ns_iter_switch_frac 0.50 \
  --soap_attn \
  --lr_mlp 0.055 \
  --wd_schedule ramp_down \
  --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99
```

**Run D only if B★ shows FFS improvement but C does not improve further.** D tests whether the switch timing is the key variable rather than the target iteration count.

---

## Gates

### KG_smoke Gate (run before Cell B★)

Before running Cell B★, verify the implementation is correct by running a 50-step debug run:

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "tanjiro/ns-iter-cooldown-smoke" \
  --wandb_group "ns-iter-cooldown" \
  --ns_iter 12 \
  --ns_iter_late 6 \
  --ns_iter_switch_frac 0.99 \
  --soap_attn \
  --lr_mlp 0.055 \
  --wd_schedule ramp_down \
  --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99
```

`ns_iter_switch_frac=0.99` switches at step ~33 (= 3250 × 0.01). This forces the switch early in a short run.

**Smoke pass criteria:**
1. Training loss is finite (not NaN) at steps 1, 10, 50.
2. W&B logs show `train/ns_iter_current = 12` before switch step, then `= 6` after.
3. `train/ns_iter_switched = 1.0` after the switch step.
4. No CUDA errors, no OOM.
5. Both `muon_update` and `muon_update_late` compilation succeed (check for torch compile errors in logs).

**If smoke fails:** Do NOT proceed to B★. Diagnose the compilation or function-switching failure first.

### Signal Gate (after Cell B★ n=1)

**Proceed to Cell C or D** only if Cell B★ shows:
- `FFS_ema ≤ 2887` (early val estimate using EMA smoothing), OR
- `FFS_trainval ≤ 2900` (training-validation combined estimate)

**No-signal stop condition:**
If B★ FFS_ema > 2950 and FFS_trainval > 2975 → the 12→6 hybrid is no better than flat 12. This is FFS-NEUTRAL territory. Close the hypothesis. Do not run C or D. The mechanism is not alive.

**Attractor check:** If B★ lands on `{FFS_ema ≈ 2875, FFS_trainval ≈ 2925}` (the documented seed-noise attractor), escalate to n=4 before closing or promoting. Do NOT close on 1 seed if both metrics land on the attractor.

### Promote Gate (after B★ n=1 or n=4)

**FFS-PRIMARY trigger for n=4 escalation:**
- n=1 B★ result: FFS_ema ≤ 2875 AND FFS_trainval ≤ 2925 (attractor) → escalate to n=4
- n=1 B★ result: FFS_ema ≤ 2887 (below attractor) → escalate to n=4

**n=4 promote gate:**
- Mean FFS across 4 seeds ≤ 2950 AND mean val_loss ≤ 3.278 (satisfies `(3.28 - mu) * sqrt(4) >= 0.004`)

### Merge Gate

Merge if:
- n=4 mean FFS ≤ 2950 AND mean val_loss satisfies the statistical significance rule
- OR n=1 FFS ≤ 2875 with statistical margin `(3.28 - val_loss) >= 0.004`

---

## Pre-Mortems

### Pre-Mortem 1: NS_ITER_LATE is absorbed by the schedule gap

**Risk:** The mandatory stack already uses `ns_iter=6`. If the early benefit of ns_iter=12 is negligible (i.e., the first 75% of training doesn't differentially benefit from tighter orthogonalization), then B★ (12→6 hybrid) will be essentially identical to the flat ns_iter=6 baseline. The mechanism would be real but the effect size would be below measurement noise (~30 FFS steps at n=1).

**Distinguishing evidence:** Check W&B gradient norms during early training (steps 0–2438) for B★ vs. A_ctrl. If `train/grad/global_norm` is systematically higher in B★ early training (indicating more diverse gradient updates from tighter orthogonality), the mechanism is at least active even if FFS effect is small. If gradient norms are identical, the NS iteration count doesn't affect early-phase gradient diversity at the scales that matter.

**Mitigation:** If B★ shows gradient norm difference but not FFS improvement, the mechanism is real but the FFS window is dominated by late-phase dynamics. In that case, Cell D (earlier switch at 50%) may reveal the correct timing.

### Pre-Mortem 2: torch.compile recompilation on first switch step causes a stall or regression

**Risk:** The switch from `muon_update` to `muon_update_late` at step ~2438 may trigger a torch.compile cache miss or recompilation, causing:
- A multi-second pause at step ~2438 (visible as a gap in W&B step timestamps)
- A numerical discontinuity in the momentum state (the mutable cell patches the function but the optimizer's accumulated momentum is still from the 12-iteration phase)

**Mitigation 1 (timing):** If the smoke test shows step-timestamp gap at the switch step, this is expected. The compiled `muon_update_late` should already be warmed up by the first forward pass (since `@torch.compile` compiles on first call). Force both compilations in a warmup pass before the training loop:

```python
# Force compile both NS function pairs before training starts
if args.ns_iter_late is not None:
    _dummy_g = torch.randn(128, 128, dtype=torch.bfloat16, device='cuda')
    _dummy_m = torch.zeros_like(_dummy_g)
    _ = muon_update_late(_dummy_g, _dummy_m)
    _ = soap_ns_step_late(_dummy_g)
    del _dummy_g, _dummy_m
```

**Mitigation 2 (momentum discontinuity):** The momentum buffer accumulates under ns_iter=12 gradients for 2438 steps. At step 2438, the NS function changes but the momentum buffer is unchanged. This is intentional and expected — the hypothesis is that the gradient update direction changes, not that momentum is reset. The first few post-switch steps will use a momentum-blended update that is partly from the 12-iteration regime. This is acceptable and analogous to how LR schedule changes work.

**If stall is severe (>5% wall time penalty):** The compile warmup above resolves this. Report wall time per step before and after the switch in the results.

---

## Baseline for Comparison

Current mandatory-stack baseline (n=4 mean):
- `speedrun/final_first_step_to_target`: mean ~2912.5
- `val/loss`: ~3.274

Current best known single-seed FFS: ~2800 (approx, from research state)

Target for B★ signal: FFS_ema ≤ 2887 at n=1.

---

## Research State Implications

### Why this hypothesis is now

- The `qkv-ortho-init` (PR #1937, closed 80th) confirmed NS5 absorption for static weight modifications at step 0. This closes the static-init axis for NS-visible components.
- The `additive-pre-NS5` family (4 members, closed) confirms NS5 absorbs gradient-space modifiers with relative magnitude < O(0.1%). 
- The `precond-freq-cooldown-schedule` (PR #1948, active) is testing the cooldown-phase axis for SOAP. This tests the same axis for Muon's NS component.
- The mandatory ns_iter=6 (already better than default 12) implies the NS iteration depth matters, but the direction of improvement may be phase-dependent.

### Mechanism target

**Causal hypothesis:** The NS5 absorption failures in the additive-pre-NS5 family and qkv-ortho-init all operated on gradient content before or around NS projection. This hypothesis operates on the NS projection strength itself — specifically, reducing it during the cooldown window. It is not blocked by the absorption mechanism (which acts on what enters NS, not on NS's internal iteration depth).

### Failure mode that would rule this out

If B★ FFS is identical to A_ctrl flat ns_iter=6 (within ±30 FFS steps at n=1), this confirms that early-phase ns_iter=12 provides no differential benefit over ns_iter=6 for FFS. In that case, the NS iteration depth is not a schedule-able axis at R5 stack depth, and should be closed as FFS-NEUTRAL alongside the flat-ns_iter dimension already explored.

---

## Taste Rubric

**Research mode:** Frontier refinement (testing a schedule extension of an already-proven axis).

| Criterion | Score | Justification |
|-----------|-------|---------------|
| Mechanistic grounding | 3 | Mechanism targets the specific NS projection strength during cooldown; tied to concrete prior evidence (ns_iter=6 > ns_iter=12 flat, precond-freq-cooldown analog). Direct theoretical argument about LR decay reducing effective update magnitude and over-constraining Stiefel projection. |
| Research-state value | 3 | Either: (a) B★ beats A_ctrl → confirms phase-dependent NS strength scheduling is alive, opens timing and target-iter axes; or (b) B★ is FFS-NEUTRAL → closes the NS-iter-schedule axis and confirms NS iteration count is not a cooldown schedule lever. Both outcomes are informative. |
| Execution value | 3 | Smoke gate + n=1 screen design keeps cost low. Implementation is ~42 LOC additive. The signal gate is well-calibrated to distinguish the attractor from genuine improvement. The experiment terminates cheaply on null result. |

**Overall:** 3/4. Strong incremental hypothesis with clear mechanism, cheap to falsify, and directly analogous to an active experiment (PR #1948).

---

## Confidence

**Mechanistic basis:** Moderate-strong. The NS iteration count is a genuine degree of freedom in the optimizer. The mandatory-stack evidence (ns_iter=6 > ns_iter=12) establishes that lower NS iterations are beneficial at some scale. The schedule hypothesis (12 early → 6 late) is a natural extension with theoretical support from the LR collapse argument.

**Effect size expectation:** Low-to-moderate. The FFS crossing window is narrow (~200 steps). The NS switch occurs at step 2438, after most of the cooldown has already reduced LR dramatically. The effect may be small relative to seed noise (~30 FFS steps at n=1).

**Failure probability estimate:** ~50%. The mechanism is plausible but may be swamped by seed noise. The key test is whether the gradient norm differential is observable in W&B telemetry even if FFS doesn't move.

**Calibration note:** This is a "strong incremental" hypothesis, not a "tier shift." It is the right experiment to run when the local neighborhood has a clear open dimension (NS iteration scheduling) that hasn't been tested as a schedule.

---

## Hypothesis 2: `ns5-eps-cooldown` — Anneal the NS5 Normalization Stabilizer During Cooldown

### One-sentence claim

Linearly annealing the normalization stabilizer epsilon inside `zeropower_via_newtonschulz5` from `1e-7` down to `1e-9` during the cooldown phase lets NS5 process near-zero singular value directions that are currently clipped, potentially extracting fine-grained curvature signal in the FFS crossing window.

---

### Mechanism story (5 sentences)

The NS5 update contains the line `X = X / (X.norm(dim=(-2,-1), keepdim=True) + 1e-7)` where the additive `1e-7` stabilizer floors the denominator to prevent division by near-zero. During warmup and mid-training, gradient matrices are large enough that this epsilon is irrelevant — it is swamped by actual gradient norm. But in the cooldown phase, the learning rate decays roughly 100× (from `lr_mlp=0.055` to near zero), so effective gradient magnitudes approaching the NS5 normalization step shrink dramatically; for the smallest gradient matrices, the `1e-7` floor clips the normalization and causes NS5 to treat near-zero singular vectors as if they had norm `1e-7`, which is artificial. Reducing the epsilon as LR decays removes this artificial floor precisely when the model is making its finest adjustments, allowing NS5 to normalize even very small gradient matrices faithfully. This is structurally inside NS5 (not a pre-NS modifier, not NS_ITER count, not weight initialization) and has never been ablated in any of the 81 R5 closures — it is genuinely unexplored territory.

---

### Distinctness argument

| Axis | Prior coverage | This hypothesis |
|---|---|---|
| NS iteration count schedule | Hypothesis 1 (ns-iter-cooldown) | No — different internal parameter |
| Additive pre-NS gradient modifiers | 4-member family, all FFS-NEG | No — this is INSIDE NS5, not before it |
| NS5 normalization epsilon (constant) | Never tested | No prior coverage |
| NS5 normalization epsilon (schedule) | Never tested | This hypothesis — first test of this axis |
| Muon momentum / Nesterov blend | frieren #1966 in-flight | No — different component |
| AdamW ε cooldown | nezuko #1955 in-flight | No — different optimizer, different role |

The NS5 normalization epsilon has been `1e-7` in every single run since the R5 stack was established. This is not a hyperparameter that appears in the CLI — it is hard-coded inside the NS5 kernel. No sweep, no schedule, no ablation has ever touched it.

---

### Implementation footprint (~15 LOC additive)

**New CLI flag (1 line):**
```python
parser.add_argument("--ns5_eps_cooldown_target", type=float, default=None,
                    help="Anneal NS5 norm stabilizer from 1e-7 to this value during cooldown. None=disabled.")
```

**Module-level mutable cell (1 line):**
```python
_ns5_eps = [1e-7]  # mutable cell; patched each step during cooldown
```

**Helper function (~5 LOC):**
```python
def get_ns5_eps(step, warmup_steps, train_steps, cooldown_frac, target_eps):
    cooldown_start = int(train_steps * (1 - cooldown_frac))
    if step < cooldown_start or target_eps is None:
        return 1e-7
    frac = (step - cooldown_start) / max(1, train_steps - cooldown_start)
    return 1e-7 + frac * (target_eps - 1e-7)  # linear anneal
```

**Patch NS5 kernel to use the mutable cell (~3 LOC change inside `zeropower_via_newtonschulz5`):**
```python
# Change this line:
X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
# To:
X = X / (X.norm(dim=(-2, -1), keepdim=True) + _ns5_eps[0])
```

**Update cell at each optimizer step (~3 LOC in training loop):**
```python
if args.ns5_eps_cooldown_target is not None:
    _ns5_eps[0] = get_ns5_eps(step, warmup_steps, train_steps,
                               args.cooldown_frac, args.ns5_eps_cooldown_target)
```

**Total: ~14 LOC additive. No torch.compile concerns** — `_ns5_eps[0]` is a Python float read at kernel call time, not baked into the compiled graph. The compiled function sees it as a scalar argument each time.

---

### Experimental cells

| Cell | `--ns5_eps_cooldown_target` | Purpose |
|---|---|---|
| A_ctrl | None (1e-7 constant throughout) | Control — current behavior |
| B★ | `1e-9` | Primary signal: anneal 100× down |
| C | `1e-8` | Moderate anneal: 10× down |
| D | `1e-11` | Aggressive probe: 10,000× down; expected instability |

**Run order:** A_ctrl and B★ first. If B★ FFS_ema ≤ 2975 (FFS-PRIMARY gate), add C. D is a diagnostic probe for instability boundary, run last.

**KG_smoke verification (50 steps):** Confirm `_ns5_eps[0]` logs change from `1e-7` at step 1 to `< 5e-8` by step 40 with a W&B scalar `ns5_eps` logged each step.

---

### Signal gate

**Merge gate:** FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900 (n=4 confirm required if n=1 lands on {2875, 2925} attractor)

**Diagnostic observable:** Log `_ns5_eps[0]` as `train/ns5_eps` each step. If the anneal fires but FFS doesn't move, check W&B gradient norm at the NS5 input layer during cooldown — if gradient norm is consistently >> 1e-7, the epsilon is irrelevant and the mechanism is dead.

---

### Pre-mortems

**Pre-mortem 1 — epsilon irrelevant at R5 gradient scale:** Even during cooldown, actual gradient norms at the NS5 normalization step may be >> 1e-7 for all layers. The mechanism requires that gradient norm approaches `1e-7` in some layers during cooldown; if the minimum gradient norm is always > 1e-5, the anneal does nothing. Mitigation: log per-layer gradient norms at cooldown entry to verify the mechanism is active before running full experiments.

**Pre-mortem 2 — NS5 is torch.compiled but epsilon is Python scalar:** The mutable cell pattern `_ns5_eps[0]` reads a Python float each call. With `torch.compile`, the float will be treated as a dynamic scalar (not baked as a constant) if the function is not recompiled between steps. This is correct behavior and should work, but must be verified: in the KG_smoke run, confirm that the compiled NS5 function sees different epsilon values at different steps by checking that training doesn't crash and W&B shows a smoothly changing `ns5_eps` scalar.

**Pre-mortem 3 — too-small epsilon causes instability in cell D:** At `1e-11`, the normalization denominator is effectively zero for any gradient matrix with per-row or per-column norm below `1e-11`. This will cause NaN/Inf in the NS5 iterations for nearly-zero gradient matrices. Cell D is a probe, not a winner candidate; if it instability, that is expected and informative.

---

### Confidence and taste scores

**Research mode:** Diagnostic + frontier refinement

| Criterion | Score | Rationale |
|---|---|---|
| Mechanistic grounding | 3 | Mechanism is precise: LR × gradient decay during cooldown → epsilon floor becomes active. But the gradient scale claim is unverified — we don't know if R5 gradients actually approach 1e-7 at NS5 input. |
| Research-state value | 4 | Any result sharpens the map: positive = NS5 internal parameters are tunable; null = gradient norms remain large throughout cooldown (new fact). Never been tested in 81 closures. |
| Execution value | 4 | ~14 LOC additive, no architecture changes, no data changes, KG_smoke in 50 steps, full run in 3250 steps. Clean isolation of a single internal parameter. |

**Mechanistic basis:** Strong for the mechanism story, moderate for the scale claim. The `1e-7` value in NS5 was chosen as a default stabilizer and has never been questioned.

**Effect size expectation:** Low-to-moderate. The mechanism only activates if gradients approach the epsilon floor during cooldown. If gradients remain large, effect size is zero. If gradients are near the floor, the effect could be meaningful — well-conditioned final NS5 steps in the FFS crossing window.

**Failure probability estimate:** ~55%. Primarily because the gradient scale claim is unverified. If gradients are large, the experiment is a guaranteed null. The KG_smoke diagnostic should reveal this quickly.

**Calibration note:** This is a "diagnostic + incremental" hypothesis. The null result (epsilon irrelevant) is as valuable as a positive result, because it closes a previously untested internal parameter dimension of NS5.

---

## Hypothesis 3: `adamw-beta1-cooldown` — Anneal AdamW β₁ to Zero During Cooldown

### One-sentence claim

Linearly annealing AdamW β₁ from 0.9 down to 0.0 during the cooldown phase for 1D-parameter groups (biases, LN/RMSNorm gains, embed, lm_head) eliminates the momentum lag from early high-LR steps, making the AdamW update purely reactive to current gradients at the FFS crossing window.

---

### Mechanism story (5 sentences)

AdamW with β₁=0.9 accumulates a first-moment estimate `m_t = 0.9 × m_{t-1} + 0.1 × g_t`, so the update at any step is a weighted average of gradients over roughly the past 10 steps. In the cooldown phase (steps 975–3250), the effective LR decays ~100×, meaning that `m_t` entering the FFS crossing window (steps 2800–3050) is polluted by gradients computed at LR values 10–50× higher than the current LR — a momentum lag. Setting β₁→0 at the end of cooldown makes `m_t → g_t`, eliminating the lag and allowing AdamW to make precise, fully reactive updates in the final convergence window. This is structurally distinct from frieren #1966 (muon-momentum-schedule), which ramps the Muon Nesterov blend coefficient `mu` for 2D weights tracked by Muon, not the AdamW β₁ for 1D parameters. All 81 R5 closures used flat β₁=0.9; flat β₁ sweeps (e.g., β₁=0.95, β₁=0.85) are exhausted (#1601, #1962), but a cooldown schedule is a structurally different axis that reduces to a different effective optimizer at the end of training.

---

### Distinctness argument

| Axis | Prior coverage | This hypothesis |
|---|---|---|
| AdamW β₁ fixed sweep (0.85–0.95) | Multiple PRs exhausted (PRs #1601, #1962, ~10 more) | No — this is a schedule, not a fixed value |
| AdamW β₁ cooldown schedule | Never tested in 81 closures | This hypothesis — first cooldown schedule on β₁ |
| Muon Nesterov blend (mu) cooldown | frieren #1966 in-flight | No — different optimizer, different parameter |
| AdamW ε cooldown | nezuko #1955 in-flight | No — different AdamW parameter |
| AdamW β₂ (any) | Very few prior tests, not cooldown-scheduled | No — different moment |
| EMA decay cooldown schedule | thorfinn #1957 in-flight | No — evaluation EMA, not optimizer moment |

Flat β₁ sweeps are exhausted (the axis is closed for static values), but the cooldown-schedule form is genuinely new. The mechanism is different — it is about eliminating momentum lag at a specific phase of training, not about finding the globally optimal β₁.

---

### Implementation footprint (~18 LOC additive)

**New CLI flag (1 line):**
```python
parser.add_argument("--adamw_beta1_cooldown_target", type=float, default=None,
                    help="Anneal AdamW beta1 from 0.9 to this value linearly during cooldown. None=disabled.")
```

**Helper function (~6 LOC):**
```python
def get_adamw_beta1(step, train_steps, cooldown_frac, target_beta1, base_beta1=0.9):
    cooldown_start = int(train_steps * (1 - cooldown_frac))
    if step < cooldown_start or target_beta1 is None:
        return base_beta1
    frac = (step - cooldown_start) / max(1, train_steps - cooldown_start)
    return base_beta1 + frac * (target_beta1 - base_beta1)  # linear anneal to target
```

**Update AdamW param groups each step (~8 LOC in training loop):**
```python
if args.adamw_beta1_cooldown_target is not None:
    new_beta1 = get_adamw_beta1(step, train_steps, args.cooldown_frac,
                                 args.adamw_beta1_cooldown_target)
    for pg in adamw_optimizer.param_groups:
        old_b1, old_b2 = pg['betas']
        pg['betas'] = (new_beta1, old_b2)
```

**W&B logging (2 LOC):**
```python
if args.adamw_beta1_cooldown_target is not None:
    wandb.log({'train/adamw_beta1': new_beta1}, step=step)
```

**Total: ~17 LOC additive.** No torch.compile concerns — modifying optimizer param groups at runtime is standard PyTorch and does not interact with compiled model forward/backward.

---

### Experimental cells

| Cell | `--adamw_beta1_cooldown_target` | Purpose |
|---|---|---|
| A_ctrl | None (β₁=0.9 throughout) | Control — current R5 behavior |
| B★ | `0.0` | Primary signal: full anneal to pure gradient descent at end |
| C | `0.1` | Moderate anneal: retain small momentum residual |
| D | `0.5` | Weak anneal: diagnostic for schedule effect vs. constant β₁=0.5 |

**Run order:** A_ctrl and B★ first. If B★ FFS_ema ≤ 2975, add C. D is diagnostic.

**KG_smoke verification (50 steps):** Confirm β₁ logs start at 0.9 and trend downward in W&B `train/adamw_beta1`. Verify training does not crash at β₁=0.0 (pure gradient: `m_t = g_t`).

---

### Signal gate

**Merge gate:** FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900 (n=4 confirm required if n=1 lands on {2875, 2925} attractor)

**Diagnostic observable:** Log `train/adamw_beta1` each step. If the schedule fires and FFS doesn't move, compare the 1D parameter gradient norm trajectory in cooldown between A_ctrl and B★ — if the norm trajectory is identical, the 1D params are not a bottleneck.

---

### Pre-mortems

**Pre-mortem 1 — 1D params are not the FFS bottleneck:** The 1D params (biases, LN gains, scalars) may contribute negligibly to the loss in the FFS crossing window relative to the 2D params (attention, MLP weights) managed by Muon. In that case, even perfect β₁ annealing for 1D params would have no measurable effect on FFS. Mitigation: run a quick gradient norm comparison between 1D and 2D params at the FFS crossing window (W&B log `grad_norm_1d` vs. `grad_norm_2d`).

**Pre-mortem 2 — β₁ annealing destabilizes lm_head:** The lm_head has a large fan-out and may have noisy per-token gradients. Removing momentum at β₁=0 means the lm_head update in cell B★ is purely the batch gradient, which may be noisy enough to destabilize the final convergence. Mitigation: monitor val_loss trajectory in B★ — if it shows increased oscillation in the FFS crossing window, restrict β₁ anneal to biases and LN gains only (exclude embed and lm_head from the schedule).

**Pre-mortem 3 — Adam bias correction at β₁≈0:** When β₁ approaches 0, the bias correction factor `1 - β₁^t → 1` quickly, which is correct behavior. But the transition from `β₁=0.9` (bias correction ~0.65 at step 1) to `β₁→0` changes the effective magnitude of the first moment contribution mid-training. This should not cause instability but may cause a step change in update scale at cooldown entry. Monitor `train/loss` for discontinuities at the cooldown transition step.

---

### Confidence and taste scores

**Research mode:** Frontier refinement (scheduling a previously flat hyperparameter)

| Criterion | Score | Rationale |
|---|---|---|
| Mechanistic grounding | 3 | Mechanism is precise: β₁=0.9 in cooldown → momentum lag from high-LR steps → β₁ anneal removes lag. But 1D params may be a minor contributor to FFS, weakening the expected effect. |
| Research-state value | 3 | Positive = cooldown scheduling for AdamW moments is a live axis; null = 1D params are not a cooldown bottleneck (closes that question). Distinct from frieren's mu ramp result (different optimizer + parameter). |
| Execution value | 3 | ~17 LOC additive, no architecture changes, KG_smoke in 50 steps, full run in 3250 steps. Clean isolation. Slightly lower than H2 because 1D params are a smaller contributor than 2D params to the overall loss. |

**Mechanistic basis:** Moderate. The momentum lag argument is theoretically correct, but whether 1D params actually benefit from it in the FFS crossing window is uncertain.

**Effect size expectation:** Low-to-moderate. The 1D params represent a small fraction of total parameters and gradient energy relative to the 2D Muon-managed weights. Even if the mechanism is correct, the effect on FFS may be small relative to seed noise.

**Failure probability estimate:** ~60%. The mechanism is plausible but 1D params are not the primary driver of final convergence in this model.

**Calibration note:** This is a "frontier refinement" hypothesis that closes the cooldown-schedule axis for AdamW β₁, which has been tested only as a flat hyperparameter. The null result (1D params not a FFS bottleneck) is informative — it would suggest cooldown scheduling gains, if any, must come from Muon-side parameters (already explored in frieren #1966) or from NS5 internals (H2 above).
