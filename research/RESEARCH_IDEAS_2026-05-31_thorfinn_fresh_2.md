# Hypothesis: EMA Eval Decay Cooldown Schedule (`ema-decay-cooldown`)

**Student**: g1r5-thorfinn
**Date**: 2026-05-31
**Status**: Fresh / unassigned

---

## One-sentence hypothesis

Schedule `ema_eval_decay` to ramp linearly from 0.99 down to ~0.95 across the LR cooldown window, so the EMA evaluation weights converge more tightly to the final trained weights precisely when every validation event directly determines whether FFS is alive.

---

## Mechanistic grounding

`ema_eval_decay = 0.99` keeps a long exponential tail: at step k the EMA weight is a geometric mixture of all prior iterates with half-life ≈ 69 steps. During the main training phase this long tail usefully averages over the high-variance SGD trajectory. But during the LR cooldown the iterates stop exploring — the weight trajectory compresses toward a low-noise convergence basin. A fixed long tail now lags behind that basin: the EMA model is being pulled toward points the optimizer has already left. Shortening the tail (lower decay = shorter memory) during cooldown lets the EMA weights snap forward to track the optimized basin tightly, making val_loss register the crossing of 3.28 at an earlier step and reducing FFS.

This is the mechanism studied in Morales-Brotons et al. (2024, §4): "EMA requires less learning rate decay ... since averaging naturally reduces noise. With averaging, the entire last phase of training can be spared." Their result implies that a fixed high-decay EMA overshoots the necessary tail length during the low-noise cooldown. We exploit that by adaptively shortening the tail exactly then.

**References**:
1. Morales-Brotons, Vogels, Hendrikx (2024). "Exponential Moving Average of Weights in Deep Learning: Dynamics and Benefits." arXiv:2411.18704. — Systematic study of EMA training dynamics; shows EMA requires less LR decay and that late-phase SGD iterates add noise that averaging must smooth, motivating shorter tails in low-LR regimes.
2. Izmailov, Podoprikhin, Garipov, Vetrov, Wilson (2018). "Averaging Weights Leads to Wider Optima and Better Generalization." arXiv:1803.05407. — Establishes that weight-space averaging finds flatter solutions; SWA uses a high-LR phase to generate diverse iterates before averaging, while low-LR phases are already near-convergent — the regime our proposal targets.

---

## Implementation sketch (~25 LOC)

Add one CLI arg and modify one code block. Total change: ~25 lines.

**Step 1 — Add CLI arg** (near line 100, alongside `--ema_eval_decay`):

```python
parser.add_argument("--ema_decay_cooldown_target", type=float, default=None,
    help="If set, linearly ramp ema_eval_decay from its base value down to this "
         "value across the LR cooldown window. None = no schedule (fixed decay).")
```

**Step 2 — Compute scheduled decay each step** (around line 1185–1195, inside the per-step EMA update block):

```python
# Existing code computes d = args.ema_eval_decay
# Replace with:
if (args.ema_decay_cooldown_target is not None
        and args.ema_eval_decay is not None
        and step >= int((1 - cooldown_frac) * train_steps)):
    # cooldown_x: 0 at cooldown start, 1 at final step
    cooldown_start = int((1 - cooldown_frac) * train_steps)
    cooldown_x = (step - cooldown_start) / max(1, train_steps - cooldown_start)
    d = (args.ema_eval_decay
         + (args.ema_decay_cooldown_target - args.ema_eval_decay) * cooldown_x)
else:
    d = args.ema_eval_decay

# Existing per-step EMA update (unchanged):
# ema_model <- d * ema_model + (1 - d) * model
```

Optionally log the scheduled decay value each step for diagnostics:
```python
per_group_metrics["ema/decay_scheduled"] = d
```

**Key implementation note**: `cooldown_frac` is already computed and available in the training loop from `set_hparams`. Read it from `args.cooldown_frac` or the local variable — confirm the variable name in context before submitting.

---

## Cells matrix

| Cell | Config | Purpose |
|------|--------|---------|
| A_ctrl | Mandatory stack, no `--ema_decay_cooldown_target` | Confirm baseline FFS reproducibility |
| B★ | Mandatory stack + `--ema_decay_cooldown_target 0.95` | Primary: moderate ramp 0.99→0.95 |
| C | Mandatory stack + `--ema_decay_cooldown_target 0.90` | Aggressive ramp 0.99→0.90 |
| D | Mandatory stack + `--ema_decay_cooldown_target 0.97` | Conservative ramp 0.99→0.97 |

**FFS-PRIMARY framing**: Run A_ctrl + B★ first (n=1 each). If B★ FFS ≤ 2975, escalate B★ to n=4 and run C and D as n=1 screens. If B★ FFS = -1 or > 3000, run C and D as n=1 screens before any escalation — aggressive ramp may be needed if 0.95 is too mild.

---

## Gates

**KG_smoke** (kill gate, first 200 steps):
- Loss finite and decreasing. EMA decay value logged and in [0.90, 0.99]. No CUDA errors.

**Signal gate** (n=1 screen):
- B★ FFS ≤ 2975 → escalate to n=4 and run C, D screens.
- B★ FFS between 2976–3100 → run C (more aggressive) as tie-breaker.
- B★ FFS = -1 or > 3100 → dead end for this target value; try C or D.

**Promote gate** (n=4 multi-seed):
- μ_4(FFS_ema) ≤ 2887.5 (baseline 2912.5 − 25) → merge candidate.
- Any single seed FFS = -1 in n=4 → do not promote, report full distribution.

**Stop condition**:
- All four cells (B★, C, D) show FFS = -1 on n=1 → close PR, EMA-decay-schedule family ruled out.
- Best cell achieves n=1 FFS ≤ 2900 → skip n=4 screen, go directly to n=4 confirmation.

---

## Distinctness argument

**Not additive gradient modifier** (closed): This modifies nothing in the gradient computation path; it only changes the EMA weight used for validation. The training iterate trajectory is identical.

**Not in any closed family**:
- LN/RMSNorm gain init (closed #1907): weight init, not EMA eval.
- SGLD noise, GC, μ cooldown, GE-SAM (closed): pre-NS gradient modifiers, not EMA eval.
- Forward-pass regularization (closed): training loss, not EMA eval.
- α-blended Schulz polish (closed): NS5 modifier, not EMA eval.
- Lookahead-Muon (closed): slow-weights for optimizer, not EMA eval.
- Higham/Pade polish (closed): NS5 modifier, not EMA eval.

**Not in any in-flight axis**:
- `adamw-eps-cooldown` (#1955 nezuko): AdamW epsilon schedule.
- `muon-depth-lr-scale` (#1941 alphonse): per-block LR depth scaling.
- `logit-z-loss` (#1942 askeladd): auxiliary loss term.
- `qkv-ortho-init` (#1937 tanjiro): weight initialization.
- `precond-freq-cooldown-schedule` (#1948 edward): SOAP preconditioner frequency.
- `bias-ln-lr-scale` (#1910 frieren): scalar parameter LR group.
- `cooldown_frac sweep` or `beta2 schedule` (various): none touch ema_eval_decay.

The EMA eval decay schedule is an untested lever that acts purely on the validation-phase weight materialization, orthogonal to all closed and in-flight axes.

---

## Taste rubric

**Research mode**: Frontier refinement — exploiting a specific untested knob in the mandatory stack with a mechanistic motivation grounded in the EMA dynamics literature.

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Mechanistic grounding | 3 | Morales-Brotons (2024) directly shows EMA tail length interacts with LR decay; the cooldown phase is exactly the low-LR, low-noise regime where shorter tails should help. Tied to specific code location (line ~1189). |
| Research-state value | 3 | Either the decay schedule moves FFS (confirming LR-EMA coupling is a real lever) or it does not (ruling out the EMA eval path entirely, tightening the map). Both outcomes are interpretable. |
| Execution value | 3 | ~25 LOC change, no new dependencies, cheap n=1 screen before any n=4 spend. Four cells (A/B/C/D) cover the useful range of target values. |

**Confidence**: Moderate. The mechanistic story is sound and the implementation is clean, but the effect size is uncertain — the EMA memory length may already be well-matched to the cooldown trajectory at 0.99, in which case even the aggressive ramp to 0.90 may be neutral. The n=1 screen cost is low enough to resolve this quickly.
