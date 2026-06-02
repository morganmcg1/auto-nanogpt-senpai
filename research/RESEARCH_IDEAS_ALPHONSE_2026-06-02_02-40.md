# Research Hypothesis: pos-loss-ramp

## Slug

`pos-loss-ramp`

## Hypothesis

The training script currently uses `F.cross_entropy(..., reduction="sum")` which assigns exactly equal weight to every token position in the 1024-token sequence context. Under causal language modeling, earlier tokens receive trivially short contexts (token 1 predicts with zero context, token 2 with one token, etc.) while later tokens must predict against nearly the full context window, providing richer and arguably harder gradient signal. Upweighting later positions through a learnable or scheduled linear ramp — assigning weight `1 + (alpha-1) * (t / (T-1))` to token at position `t` in a sequence of length `T` — should concentrate gradient mass on the harder predictions and push the optimizer to fit the harder, more informative tail of each sequence faster. This is mechanistically distinct from z-loss (which penalizes logit L2 norm), label smoothing (which softens target distributions), or per-layer LR decay (which modifies optimizer step sizes per depth layer). The ramp is static and requires zero learnable parameters, so it does not conflict with any optimizer axis, and it is applied before backprop so NS5 internals and pre-NS5 transforms are unaffected. The intuition is borrowed from curriculum learning and positional weighting in seq2seq training (e.g., downweighting initial BOS positions), and there are zero R5 PRs testing any form of sequence-position weighting on this codebase.

## Why It Might Be Alive

At R5 saturation, optimizer-side axes are exhausted. The loss formulation is a largely unexplored lever: z-loss (#2077) adds a regularizer on logit norms; label smoothing (#1870) softens targets. But the position dimension of the cross-entropy sum has never been modulated. Intuitively, if later tokens provide proportionally stronger supervision signal (longer context = more structural prediction challenge), reweighting the sum should shift gradient energy toward those tokens. If that bias correlates with FineWeb's actual difficulty gradient across positions, a small alpha (1.5–3.0) might shave off early convergence steps. The ramp is cheap, deterministic, and reversible.

## Novelty Proof (GH Search Results)

Search 1: `sequence position` — 0 hits (clean open axis)

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "sequence position"
(no results)
```

Search 2: `position weight` — 0 hits

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "position weight"
(no results)
```

Search 3: `causal weight` — 0 hits

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "causal weight"
(no results)
```

Search 4: `token weight` — 0 hits

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "token weight"
(no results)
```

Search 5: `loss weight` — PR #2077 (z-loss logit norm regularizer), PR #1942 (PaLM-style z-loss). Both are logit-norm regularizers, mechanistically distinct from position weighting.

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "loss weight"
#2077  z-loss  (logit norm penalty, NOT position weight)
#1942  z-loss  (PaLM variant, NOT position weight)
```

Search 6: `token frequency` — closed PRs (SOAP col-only, embed LR, AdamW WD schedule, aux LR warmup). None touch position-based weighting of the cross-entropy sum.

```
$ gh search prs --repo morganmcg1/modded-nanogpt-senpai --label auto-nanogpt-1gpu-r5 "token frequency"
#566 embed-lr, #xxxx aux-wd — all optimizer/LR axes, NOT position weighting
```

Conclusion: 0 R5 PRs test sequence-position-weighted cross-entropy loss. This axis is OPEN.

## Memory-Rule Compliance Check

| Memory Entry | Rule | Compliance |
|---|---|---|
| `r5_n1_to_n4_reversion_dual_metric_attractor.md` | n=1 on attractor {FFS_ema=2875, FFS_trainval=2925} → escalate to n=4 | COMPLIANT: protocol cells include n=4 escalation arm |
| `sgld_annealed_noise_pre_ns_family_neg_at_r5.md` | SGLD/noise/GC/μ-cooldown/GE-SAM family closed (pre-NS5 additive gradient modifiers) | COMPLIANT: position loss ramp is a loss-side change, not a gradient modifier |
| `ln_gain_init_below_one_ffs_neg_at_r5.md` | Reducing γ_init below 1.0 FFS-NEG | COMPLIANT: not touching LN/RMSNorm gains |
| `ns5_absorbs_2d_weight_init_perturbations_at_r5.md` | NS5 absorbs 2D init perturbations and post-NS5 per-block depth-LR scaling | COMPLIANT: no weight init or per-block depth-LR changes |
| `ns5_internal_eps_irrelevant_at_r5_gradient_scale.md` | NS5 internal ε does not affect R5 outcomes | COMPLIANT: not touching NS5 internals |
| `sf_polyak_cooldown_freeze_failure.md` | SF/Polyak cooldown-freeze fails: cooldown freezing | COMPLIANT: not touching cooldown averaging/freeze |
| `advisor_branch_commit_hygiene.md` | Commit advisor-owned docs on advisor branch only | COMPLIANT: this file stays on advisor branch |
| `warmup_mu_ramp_axis_closed_at_r5.md` | μ warmup axis closed at progress < 0.30 | COMPLIANT: not touching Muon momentum warmup |
| `adamw_aux_tetrad_fully_closed_at_r5.md` | All AdamW aux hyperparameter axes closed (β₁, β₂, eps, WD) | COMPLIANT: not touching AdamW hyperparameters |
| `pre_ns5_gradient_transformation_axis_saturated_at_r5.md` | Pre-NS5 gradient transforms comprehensively closed (PR #890) | COMPLIANT: position ramp is a forward-pass loss change, not a gradient modifier before NS5 |

ALL 10 MEMORY ENTRIES: COMPLIANT.

## Implementation Patch

Target file: `records/track_3_optimization/train_gpt_simple.py`

### 1. Add CLI argument (after line 109, before `args = parse_args()`)

```python
    # Inside parse_args(), after --mu_cooldown_target argument (line 108):
    parser.add_argument("--pos_loss_alpha", type=float, default=1.0,
                        help="Position-ramp loss weight: token at position t gets weight "
                             "1 + (alpha-1) * t/(T-1). alpha=1.0=uniform (default/control). "
                             "alpha>1 upweights later tokens; alpha<1 downweights them.")
```

### 2. Replace cross-entropy in GPT.forward (line 500)

Current line 500:
```python
        return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
```

Replace with (add at top of GPT.forward or pass alpha through — cleanest: use module-level reference to args):
```python
        # Position-ramp loss weight (pos_loss_alpha=1.0 = uniform = control)
        loss = F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="none")
        if args.pos_loss_alpha != 1.0:
            B, T = targets.shape
            t = torch.arange(T, device=targets.device, dtype=torch.float32)
            w = 1.0 + (args.pos_loss_alpha - 1.0) * t / max(T - 1, 1)  # shape [T]
            w = w.repeat(B) / w.mean()   # normalize so sum ≈ original scale
            loss = (loss * w).sum()
        else:
            loss = loss.sum()
        return loss
```

Total lines changed: 12 LOC (6 for arg, 8 for forward). Under the 25 LOC budget.

Note: `w.mean()` normalization keeps the effective loss magnitude comparable to the uniform case, which preserves existing LR tuning.

## Experiment Cells

### Cell A: Control verification (alpha=1.0)

Verify the patch does not regress baseline when alpha=1.0 (reduction is identical to original sum).

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/pos-loss-ramp-ctrl-alpha1" \
  --wandb_group "pos-loss-ramp" \
  --pos_loss_alpha 1.0 \
  --num_trials 1
```

Expected: FFS_ema ≈ 2925 (identical to baseline single-seed). If this deviates by >50 steps, there is a bug in the normalization path.

### Cell B: Light upweight (alpha=2.0, n=1 screen)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/pos-loss-ramp-alpha2" \
  --wandb_group "pos-loss-ramp" \
  --pos_loss_alpha 2.0 \
  --num_trials 1
```

Expected: If on attractor {FFS_ema=2875, FFS_trainval=2925} → escalate to n=4 per memory rule.

### Cell C: Stronger upweight (alpha=4.0, n=1 screen)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/pos-loss-ramp-alpha4" \
  --wandb_group "pos-loss-ramp" \
  --pos_loss_alpha 4.0 \
  --num_trials 1
```

### Cell D: Best alpha × n=4 confirmation (run only after identifying best alpha from B/C)

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "alphonse/pos-loss-ramp-alpha<X>-n4" \
  --wandb_group "pos-loss-ramp" \
  --pos_loss_alpha <X> \
  --num_trials 4
```

Run at fixed 3250 steps; report all 4 seeds non-cherry-picked.

## Decision Tree

```
Cell A (alpha=1.0 control)
├── PASS (FFS_ema within ±50 of baseline): proceed to B+C in parallel
└── FAIL (FFS_ema drifts >50 or loss is non-finite): bug in normalization — fix w.mean() or B*T shape before proceeding

Cell B (alpha=2.0) + Cell C (alpha=4.0) — run in parallel after Cell A passes
├── Both FFS_ema > 2925 (regression): position ramp hurts — close axis; report FFS-NEG
├── alpha=2.0 FFS_ema < 2925, alpha=4.0 worse: use alpha=2.0 for Cell D
├── alpha=4.0 FFS_ema < 2925, alpha=2.0 worse: use alpha=4.0 for Cell D; consider alpha=3.0 screen
├── Both hit attractor {FFS_ema=2875}: escalate both to n=4 per memory rule (pick best for D)
└── Either < 2875 on n=1: high-signal — escalate that alpha to n=4 immediately (Cell D)

Cell D (n=4 confirmation at best alpha)
├── mu_4 ≤ 2862.5 OR val_loss ≤ 3.26507: MERGE (beats baseline)
├── 2862.5 < mu_4 ≤ 2875 (marginal): request 4 more seeds OR try intermediate alpha
└── mu_4 > 2875: close axis — position ramp is FFS-neutral or worse at R5
```

## Honest Predicted Outcomes

**Base rate**: At R5 saturation, most new axes are FFS-NEG or FFS-neutral. Estimate ~25% chance of positive signal.

**Most likely outcome** (probability ~45%): FFS-neutral. The model is already learning hard tokens well enough; the ramp shifts gradient mass but the optimizer adapts, and the net effect on steps-to-3.28 is within noise.

**Second most likely** (~30%): FFS-NEG at alpha=4.0 but FFS-neutral at alpha=2.0. Strong upweighting creates instability or slows early convergence enough to offset gains from harder-token focus.

**Positive outcome** (~25%): alpha=2.0 or 4.0 yields FFS_ema ≤ 2862.5 on n=4. The gradient redistribution helps cooldown-phase convergence on hard late-sequence tokens.

**Implementation failure mode**: If `targets.shape` is `(B*T,)` rather than `(B, T)`, the `B, T = targets.shape` will raise. Must verify the targets tensor shape at runtime. Safe fallback: `T = targets.numel() // B` where `B = logits.size(0)`.

**Normalization note**: Dividing by `w.mean()` keeps the mean token weight = 1.0, so the effective loss scale is preserved and no LR retuning is needed. Without normalization, alpha=4.0 would inflate the loss by ~2.5× and destabilize training.

## Current Baseline

- mu_4(FFS_ema) = 2875 steps
- Merge gate: FFS_ema ≤ 2862.5 OR val_loss ≤ 3.26507
- Statistical rule: `(3.28 - mu) * sqrt(n) >= 0.004` (n=4 needs mu ≤ 3.278)
