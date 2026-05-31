# Hypothesis: muon-mu-cooldown-schedule

**Slug**: `muon-mu-cooldown-schedule`
**Date**: 2026-05-30
**Student**: g1r5-tanjiro
**Status**: PROPOSED

---

## One-Sentence Summary

Schedule Muon momentum coefficient μ to decay linearly from 0.95 toward 0.75–0.85 during the 70% cooldown phase, making NS-orthogonalized updates more responsive to current gradient curvature precisely in the 2800–3050 step window where FFS crossings occur.

---

## Background and Motivation

After 65 closed R5 axes, μ=0.95 remains the only major Muon optimizer hyperparameter that has **never been scheduled**. Every other significant HP has been explored:

| HP | Scheduled? | Source |
|----|-----------|--------|
| lr (all groups) | Yes — cosine cooldown | R5 mandatory stack |
| weight_decay (Muon) | Yes — ramp_down schedule | PR #1351 |
| ema_eval_decay | Fixed 0.99 (tuned) | PR #1533 baseline |
| soap_beta2 | Fixed 0.90 | mandatory stack |
| ns_iter | Fixed 6 | mandatory stack |
| **Muon mu** | **NO — never touched** | **this hypothesis** |

The structural gap: in `set_hparams()` (lines 917–931 of `train_gpt_simple.py`), only `group["lr"]` and `group["weight_decay"]` are updated. `group["mu"]` is set once at optimizer creation and never mutated again despite being stored per param-group in the Muon optimizer and being read at every optimizer step.

### Mechanism

During cooldown (steps 975–3250, 70% of 3250 total), the LR is decaying. With μ=0.95 constant, each update is a weighted blend of 20 recent gradients (effective memory ≈ 1/(1−μ)). As LR → 0, this long-memory buffer carries significant stale gradient information from the pre-cooldown trajectory.

Decaying μ during cooldown reduces the effective gradient memory at the same rate as LR reduction, keeping the ratio of signal-to-inertia stable and allowing finer curvature tracking when it matters most. This is analogous to the β1/β2 dissociation principle observed in AdamW (PR #1321: β1=0.8 short memory + β2=0.95 long second moment), applied here to the first-moment accumulation in Muon.

FFS crossings empirically occur between steps 2800–3050 — deep in cooldown (step 2800 = 86% of 3250 = progress x=0.74 into cooldown). At that point with default μ=0.95, the update is dominated by gradients from steps ~2640–2800. With μ=0.75, it is dominated by gradients from ~2790–2800. Lower mu → more localized, present-tense update.

### Mechanism Uncertainty

**Honest uncertainty** (medium confidence, ~40% hit rate):

1. NS orthogonalization may already flatten the momentum's stale-gradient problem by projecting onto the current Stiefel manifold at each step. If NS orthogonalization is the dominant source of curvature adaptation, μ scheduling provides marginal additional signal.
2. The effective memory argument assumes gradient directions change significantly during cooldown. If the gradient direction is nearly constant in cooldown (the model is converging), lowering μ mainly adds noise.
3. SOAP-attn parameters use `group["mu"]` for their momentum lerp (lines 655–656). Those parameters already have a second-order preconditioner — μ reduction could interact non-trivially with SOAP's eigenbasis tracking, potentially destabilizing rather than helping.
4. Very aggressive decay (μ→0.60) may cause non-monotone per-step loss that trips the EMA crossing check backward.

**Falsification signal**: if all three scheduled-mu cells (B/C/D) perform within ±50 FFS steps of CTRL at n=1, the mechanism is neutral and this axis is closed.

---

## Implementation

**File**: `records/track_3_optimization/train_gpt_simple.py`
**Total new lines**: ~30 LOC

### Change 1: Add argument (lines ~130–200, after existing args)

```python
# After the --ema_eval_decay argument:
parser.add_argument("--mu_cooldown_end", type=float, default=None,
                    help="If set, linearly decay Muon mu from its initial value "
                         "to this target during the cooldown phase. "
                         "Default None means mu is held constant at 0.95.")
```

### Change 2: Store initial_mu after optimizer creation (lines ~861–890)

After the existing block that stores `group["initial_lr"]` and `group["initial_wd"]`:

```python
# After: group["initial_wd"] = group.get("weight_decay", 0.0)
# Add:
for opt in optimizers:
    for group in opt.param_groups:
        if "mu" in group:
            group["initial_mu"] = group["mu"]
```

### Change 3: Schedule mu in set_hparams() (lines ~917–931)

Append inside `set_hparams()`, after the existing lr/wd scheduling loop:

```python
# Muon mu cooldown schedule (if enabled)
if getattr(args, "mu_cooldown_end", None) is not None:
    for opt in optimizers:
        if isinstance(opt, Muon):
            for group in opt.param_groups:
                if "initial_mu" in group:
                    if progress < 1 - cooldown_frac:
                        group["mu"] = group["initial_mu"]
                    else:
                        # x is normalized cooldown progress: 0 → 1
                        group["mu"] = group["initial_mu"] + (
                            args.mu_cooldown_end - group["initial_mu"]
                        ) * x
```

Note: `x` is already computed as `(progress - (1 - cooldown_frac)) / cooldown_frac` earlier in `set_hparams()`. Reuse it.

### Change 4: Log mu to W&B telemetry (optional but strongly recommended)

In the existing metrics logging block (around the `train/lr/*` and `train/weight_decay/*` logging), add:

```python
# Log Muon mu per group
for opt in optimizers:
    if isinstance(opt, Muon):
        for group in opt.param_groups:
            if "name" in group and "mu" in group:
                log_dict[f"train/mu/{group['name']}"] = group["mu"]
```

This lets the advisor verify μ is actually being scheduled and diagnose any interaction with SOAP-attn.

---

## Sweep Plan

All cells use the **R5 mandatory stack**:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine
--ema_eval_decay 0.99
```

**Phase 1 (n=1 screening, 4 cells in parallel if possible)**:

| Cell | --mu_cooldown_end | Expected FFS | Hypothesis |
|------|------------------|--------------|-----------|
| A (CTRL) | (none) | ~3025 | Baseline confirmation |
| B | 0.85 | 2875–2975 | Mild decay, SOAP-safe |
| C | 0.75 | 2850–2950 | Moderate decay |
| D | 0.60 | 2800–2975 or WORSE | Aggressive decay, may destabilize |

**FFS-ALIVE gate**: at least one scheduled-mu cell must achieve FFS_ema ≤ 2975.

If gate passes: advance best-performing cell to n=4.
If gate fails on all cells: close this axis, return to research state log.

**Phase 2 (n=4 promotion, best cell only)**:

Promotion gate: n=4 mean FFS_ema ≤ 2887.5 (FFS-PRIMARY rule from issue #1262).

---

## Exact Bash Commands

**Cell A — CTRL (n=1)**:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --wandb_name "tanjiro/muon-mu-cooldown-ctrl" \
  --wandb_group "muon-mu-cooldown-schedule"
```

**Cell B — mu_cooldown_end=0.85 (n=1)**:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --mu_cooldown_end 0.85 \
  --wandb_name "tanjiro/muon-mu-cooldown-0.85" \
  --wandb_group "muon-mu-cooldown-schedule"
```

**Cell C — mu_cooldown_end=0.75 (n=1)**:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --mu_cooldown_end 0.75 \
  --wandb_name "tanjiro/muon-mu-cooldown-0.75" \
  --wandb_group "muon-mu-cooldown-schedule"
```

**Cell D — mu_cooldown_end=0.60 (n=1)**:
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --mu_cooldown_end 0.60 \
  --wandb_name "tanjiro/muon-mu-cooldown-0.60" \
  --wandb_group "muon-mu-cooldown-schedule"
```

**Phase 2 — best surviving cell, n=4 (example for Cell C)**:
```bash
# Run 4 independent seeds (default seed randomization via torch.manual_seed from run index)
for trial in 1 2 3 4; do
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
    records/track_3_optimization/train_gpt_simple.py \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --mu_cooldown_end 0.75 \
    --wandb_name "tanjiro/muon-mu-cooldown-0.75-seed${trial}" \
    --wandb_group "muon-mu-cooldown-schedule-n4"
done
```

---

## Evaluation Criteria

**Primary metric**: `speedrun/final_first_step_to_target` (FFS, lower is better)
**Current baseline**: FFS=2875 (PR #1533 EMA-eval, n=4 μ=2912.5)

**Screening gate (Phase 1)**:
- At least 1 of {B, C, D} must achieve FFS_ema ≤ 2975
- If CTRL (Cell A) is far from 3025, flag as seed variance issue, do not promote

**Promotion gate (Phase 2)**:
- n=4 mean FFS_ema ≤ 2887.5
- Statistical rule: `(3.28 - mu_loss) * sqrt(4) >= 0.004`

**Stop conditions**:
- All three scheduled-mu cells within ±50 FFS of CTRL → mechanism neutral, close axis
- Cell D significantly better than C and B → suspect non-linear mu-FFS relationship, follow up with 0.50 or non-linear schedule
- Loss diverges or becomes non-finite during cooldown → aggressive mu decay destabilizes SOAP-attn, close D, keep B/C

---

## Decision Tree

```
Phase 1 (n=1 screening)
├── Any of {B,C,D} achieves FFS_ema ≤ 2975?
│   ├── YES: take best performing cell
│   │   ├── Run Phase 2 (n=4) on best cell
│   │   │   ├── n=4 mean FFS ≤ 2887.5?
│   │   │   │   ├── YES → MERGE, report to advisor
│   │   │   │   │   └── Follow-up: test mu cooldown shape (cosine decay vs linear)
│   │   │   │   └── NO (2888–2975) → promising, try n=8 or try finer value
│   │   │   │       └── Or: test combining with other in-flight ideas
│   │   └── If Cell D significantly worse than C, don't test D at n=4
│   └── NO (all B/C/D ≥ 2975): CLOSE axis
│       └── Advisor note: "mu scheduling neutral; NS orthogonalization
│            likely absorbs stale momentum effect"
├── CTRL (Cell A) deviates >150 FFS from 3025?
│   └── YES: flag high seed variance, do not promote any cell based on this run alone
│       └── Rerun CTRL with second seed before promoting
```

---

## Suggested Follow-Ups (Conditional on Results)

**If mild decay wins (Cell B=0.85 best)**:
- Test cosine-shaped mu decay (slow start, fast finish) vs linear
- Test starting mu decay earlier (at 50% of training instead of 70%)

**If moderate decay wins (Cell C=0.75 best)**:
- Test 0.70 and 0.80 to pin the optimum
- Test applying mu schedule only to muon_mlp group (not muon_attn, which uses SOAP)

**If aggressive decay wins (Cell D=0.60 best)**:
- Surprising — mu may want to approach SGD-like behavior at end
- Test 0.50 and non-linear (exponential) decay
- Investigate whether SOAP-attn interaction is different from plain-Muon groups

**If mechanism is neutral**:
- Consider mu WARMUP instead (start lower μ=0.80, ramp to 0.95) — different mechanism targeting early training
- Consider separate mu per param group (mlp vs attn)

---

## Research State Relevance

**Current bottleneck**: 65 closed axes, FFS plateau at 2875 (n=4 μ=2912.5) since PR #1533. Plateau protocol active.

**Why this is not a repeat**:
- PR #1321 tested AdamW β2 schedule (different optimizer, different parameter)
- PR #1322 tested NS iteration count schedule (different mechanism entirely)
- No closed axis touches Muon's μ parameter in any form

**Risk classification**: LOW implementation risk (30 LOC, no architectural change), MEDIUM hypothesis risk (~40% prior probability of FFS improvement given mechanism uncertainty).

**Compute budget**: Phase 1 = 4 × 1 GPU training runs (~4 × 30 min). Phase 2 (conditional) = 4 more. Total ≤ 8 runs.
