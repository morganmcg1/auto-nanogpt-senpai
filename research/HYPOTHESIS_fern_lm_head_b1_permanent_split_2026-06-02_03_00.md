# fern — Aux Adam Per-Group Permanent β₁ Split for lm_head bilateral (fast 0.5 vs slow 0.95)

## Context

Baseline #1532: `speedrun/first_step_to_target` (sr) = **2875**, `val/loss_ema` = **3.262854**.

Merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

Current aux Adam configuration (lines ~800–803):
```python
optimizer1 = AdamW([
    dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
    dict(params=[model.proj.weight], lr=1/160, name="adam_lm_head"),
    dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.025, name="adam_scalars")],
    betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
```

All three groups share **the same β₁=0.8** (first-moment decay) and **β₂=0.95** (second-moment decay). The three groups have radically different gradient regimes:
- `adam_embed` (vocab × d_model): sparse lookup gradients, high variance per token
- `adam_lm_head` (d_model × vocab): dense projection from final hidden state to logits; LARGEST gradient magnitudes in the network (~3× attention weights)
- `adam_scalars` (RMSNorm gains, biases): low-dimensional, fast-converging

The aux Adam β₂ pulse @ step 975 (→0.99) was the WIN that established baseline #1532, demonstrating that the v-state (second moment) is differentially tunable across phases. The β₁ analog has been swept GLOBALLY (PRs #416, #230) but **never per-group from step 0**. The first moment for lm_head specifically — given its uniquely large gradient magnitude — has never been treated as a separable axis.

Closed paramEMA axes (fern's recent territory):
- TIMING (#2105 warmup, #2102 refresh-step) — bilateral NULL
- OPERATOR (#2159 refresh α-blend) — bilateral NULL
- SHAPE (#2163 frieren β-ramp linear/cosine) — bilateral NULL

This assignment is a **tier shift** away from paramEMA shape/timing/operator (axes now exhausted) into the aux Adam per-group structural configuration — a directive (b) per-layer/per-group mechanism that does NOT overlap with any closed scalar β/μ/EMA sweep.

## Hypothesis

The global β₁=0.8 first-moment decay was inherited from the original training recipe and never re-tuned after the aux groups were split into embed/lm_head/scalars. The lm_head is unique: its gradients carry the strongest signal-to-noise ratio (dense matmul against the loss gradient, no sparsity, no normalization scaling). A β₁ value optimal for the noisy/sparse embed gradients or the low-dim scalar gradients may be suboptimal for lm_head.

Two opposing arms test the directional uncertainty:

- **Arm A (FAST β₁=0.5):** lm_head Adam first moment decays faster than global. Effective averaging window ~2 steps. Hypothesis: lm_head gradients are already smooth and reliable (loss gradient is dense and well-conditioned); heavy smoothing wastes signal. A fresher m-state lets the optimizer respond to local descent direction in the final phase where each step matters.
- **Arm B (SLOW β₁=0.95):** lm_head Adam first moment decays slower than global. Effective averaging window ~20 steps. Hypothesis: lm_head gradients are dominated by per-batch noise even in late training (full vocab cross-entropy has high variance); aggressive smoothing reduces noise and enables finer late-phase convergence.

Both arms hold β₂=0.95 unchanged for lm_head (the existing β₂ pulse @975 → 0.99 applies normally — already part of baseline). Embed and scalars retain global β₁=0.8.

Mechanistically distinct from:
- PR #1592 (β₁ DROP pulse, all groups, schedule perturbation) — bilateral NULL
- PR #1666 (β_cov pulse on body Muon) — different mechanism
- PR #2086 (aux β₂ embed-only pulse) — same param-group-decomposition spirit but on β₂, not β₁
- PR #2102/#2159/#2163 (paramEMA shape/operator) — paramEMA is a model-side buffer, distinct subsystem

Directive (b) per-layer/per-block optimizer behavior. Directive (d) preconditioner state handling (Adam first moment is a preconditioner state).

## Implementation

**File:** `records/track_3_optimization/train_gpt_simple.py`

### CLI flag

```python
parser.add_argument("--lm_head_b1", type=float, default=-1.0,
                    help="Per-group β₁ override for the adam_lm_head group. "
                         "-1 (default) = use global β₁=0.8 (baseline behavior). "
                         "0.5 = fast first-moment decay; 0.95 = slow first-moment decay.")
```

### Optimizer construction (lines ~800–803)

```python
# Determine lm_head β₁: per-group override if specified, else global default
_lm_head_b1 = args.lm_head_b1 if args.lm_head_b1 > 0 else 0.8

optimizer1 = AdamW([
    dict(params=[model.embed.weight], lr=0.3, name="adam_embed"),
    dict(params=[model.proj.weight], lr=1/160, name="adam_lm_head",
         betas=(_lm_head_b1, 0.95)),  # per-group β₁ override; β₂ unchanged
    dict(params=[p for p in model.parameters() if p.ndim < 2], lr=0.025, name="adam_scalars")],
    betas=(0.8, 0.95), eps=1e-10, weight_decay=0, fused=True)
```

**Note:** PyTorch's fused AdamW respects per-group `betas` overrides when set in the param-group dict before construction. The β₂ pulse @ step 975 (existing baseline behavior) modifies `group["betas"]` in-place mid-training; that pulse will still see `group["betas"][1]` for ALL groups (including lm_head with overridden β₁) and switch it to 0.99 — preserving baseline β₂ behavior.

### Verification of pulse compatibility

When the existing β₂ pulse fires at step 975, it executes:
```python
for group in optimizer1.param_groups:
    group["betas"] = (group["betas"][0], args.aux_b2_pulse_target)
```
This preserves `group["betas"][0]` — so the lm_head group keeps its overridden β₁ across the pulse. β₁ stays at the assigned value for the entire run; only β₂ pulses at step 975 (as in baseline).

### Sentinel logging at step 0

```python
if step == 0 and dist.get_rank() == 0:
    for group in optimizer1.param_groups:
        print0(f"[step 0] aux Adam group {group.get('name','?')}: "
               f"lr={group['lr']:.6f}, betas={group['betas']}",
               console=True)
    if wandb.run:
        wandb.log({
            "optim/lm_head_b1": _lm_head_b1,
            "optim/aux_embed_b1": 0.8,
            "optim/aux_scalars_b1": 0.8,
        }, step=0)
```

Also log `optim/lm_head_b1_at_step_0` once at step 0 (so the value is trivially distinguishable across W&B runs).

### CRITICAL: bitwise-baseline check

`--lm_head_b1 -1.0` (default) MUST reproduce baseline trajectory exactly. The conditional `args.lm_head_b1 > 0` falls through to global β₁=0.8, which is what `AdamW(betas=(0.8, 0.95))` already assigns by default. Verify first 50 loss values match a known baseline run (e.g., compare to a prior PR's recent baseline reproduce).

## Baseline reproduce (always include full stack)

```bash
# Arm A — FAST β₁ on lm_head (0.5)
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --lm_head_b1 0.5 \
  --wandb_group g1r1-fern-lm-head-b1-split \
  --wandb_name g1r1-fern/lm-head-b1-fast-arm-a

# Arm B — SLOW β₁ on lm_head (0.95)
uv run records/track_3_optimization/train_gpt_simple.py \
  --muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target 0.99 \
  --muon_block_lr_pattern late-higher \
  --paramema_refresh_only --paramema_refresh_step 2600 \
  --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 \
  --lm_head_b1 0.95 \
  --wandb_group g1r1-fern-lm-head-b1-split \
  --wandb_name g1r1-fern/lm-head-b1-slow-arm-b
```

## Chain rule

1. Implement flag + sentinel. Smoke-verify `--lm_head_b1 -1.0` reproduces baseline (first 50 train losses bit-for-bit match a known baseline run).
2. **Launch Arm A (FAST β₁=0.5) first.**
   - Clear NULL (sr ≥ 2925, val_ema ≥ 3.265): launch Arm B (SLOW β₁=0.95) directly.
   - WIN candidate (sr ≤ 2875, val_ema near baseline): run seed-2 of Arm A first before Arm B.
3. Both arms terminal → post:

```markdown
SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["<a-id>","<b-id>"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":<sr>},"test_metric":{"name":"val/loss_ema","value":<val_ema>}}
```

## Expected outcomes

| Outcome | Meaning | Follow-up |
|---|---|---|
| Arm A WIN (FAST 0.5) | lm_head gradients are smooth — fresh m-state helps late phase | Bracket β₁ ∈ {0.3, 0.7} on lm_head |
| Arm B WIN (SLOW 0.95) | lm_head gradients are noisy — heavy smoothing helps final convergence | Bracket β₁ ∈ {0.9, 0.98} on lm_head; consider per-group β₁ for embed too |
| Both NULL | Global β₁=0.8 is already optimal for lm_head, or lm_head dynamics are dominated by other factors | Close lm_head β₁-split axis at this granularity |
| Asymmetric near-miss | One direction measurably closer to baseline than the other | Narrow bracket on the winning side |

## Why this might break the plateau

The aux Adam β₂ pulse @ step 975 (→0.99) gave us baseline #1532 — proof that aux Adam state per-group recalibration matters. The first moment for lm_head specifically has the highest information density (dense projection, largest gradient magnitude) and is the most likely place for a global β₁=0.8 to be miscalibrated. If lm_head benefits from a different β₁ from step 0, we get a FREE structural improvement: no schedule, no pulse, no phase-boundary coordination — just an optimizer-construction-time change. Even a small WIN compounds with the existing β₂ pulse and the rest of the baseline stack.

## Falsifying outcome

Both arms sr ≥ 2900 or significantly worse: lm_head β₁ is not a differentiating factor — either Adam's first moment for lm_head is already near-optimal at β₁=0.8, or the lm_head dynamics are dominated by the LR schedule + β₂ pulse, leaving no room for first-moment tuning. Close direction.

## Files to touch

- `records/track_3_optimization/train_gpt_simple.py` (CLI arg + optimizer1 construction + sentinel logging)

No other files. Delta: ~6 LOC.

## Per-arm GPU usage estimate

Single trial per arm, full 3250-step run. ~3.5–4h per arm wall-clock on 1×H100. Total expected: ~7–8h for bilateral.
