# Hypothesis: Label Smoothing for FFS Plateau Breaking

**Date:** 2026-05-30  
**Student:** g1r5-thorfinn  
**Research mode:** Tier shift (loss-level intervention outside NS/SOAP cluster)  
**Novelty:** Confirmed — "label smoothing" does not appear in any of the 64 closed R5 PR titles or descriptions

---

## One-Sentence Summary

Add `label_smoothing=α` to the `F.cross_entropy` call so that the model cannot
become over-confident on any single target token, reducing gradient variance in
the main training phase and allowing Muon's orthogonal updates to push the
val/loss curve below 3.28 in fewer steps.

---

## Mechanism Prediction (specific and falsifiable)

The current loss is computed on hard one-hot targets. Muon's orthogonal gradient
updates are direction-optimal but not magnitude-gated; when the model has already
assigned very high probability to the correct token, the gradient becomes nearly
zero and the useful signal for other weights is washed out.

Label smoothing replaces the one-hot target distribution `p = [0,…,1,…,0]` with
a soft mixture `p_smooth = (1-α)·one_hot + α/V`, where `V = 50304` is the
vocabulary size. This adds a small uniform floor to every token probability,
preventing logit magnitudes from saturating the soft-capped output
(`15 * x * (x^2 + 15^2)^{-0.5}`) and keeping per-step gradients informative
throughout the main-phase plateau (steps ~2000–2800) where the current FFS
bottleneck lives.

Concretely: label smoothing does not change the FineWeb *evaluation* loss
(validation uses `label_smoothing=0` always), but it reshapes the *training*
loss landscape so that Muon takes better-directed steps during the mid-phase
compression of model error from ~3.4 to ~3.28. If the mechanism is real, we
expect:
- FFS_ema to decrease by 25–75 steps (bringing it from 2912.5 closer to 2875)
- val/loss curves to be smoother in the 3.30–3.32 region (less step-to-step
  variance) relative to the control
- train/loss to be slightly *higher* than the control at matching steps (expected:
  the smoothed objective is larger by approximately `α * log(V) ≈ 0.05 * 10.8 ≈ 0.54`
  nats, but this does NOT affect the val metric)

**Falsifier:** If `val/loss` is identical or worse at every checkpoint and the
FFS distribution fully overlaps with the control, the mechanism is inert and
the hypothesis is ruled out.

**Critical interaction:** The logit soft-cap (`15 * logits * (logits^2 + 15^2)^{-0.5}`)
already prevents extreme logit magnitudes. Label smoothing may therefore have a
*smaller* effect than in uncapped settings. This is a known risk; it means we
may need a slightly larger `α` than typical NLP baselines (which use 0.1) to
see a signal. The sweep plan accounts for this.

---

## Implementation Surface

**File:** `records/track_3_optimization/train_gpt_simple.py`

**Change 1 — argparse (~3 LOC):**  
Add to `parse_args()` (after the `--ema_eval_decay` argument):

```python
parser.add_argument("--label_smoothing", type=float, default=0.0,
                    help="Label smoothing coefficient for F.cross_entropy (0=off, 0.1=typical NLP). "
                         "Applied only to training loss; val loss always uses 0.")
```

**Change 2 — forward pass (~1 LOC):**  
In `GPT.forward()` at line 494, change:

```python
return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
```

to:

```python
return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1),
                       reduction="sum", label_smoothing=args.label_smoothing)
```

**Change 3 — validation path (CRITICAL — must not apply smoothing to val):**  
Confirm that the val loss call is separate. If `GPT.forward()` is used for both
train and val, the student MUST add a `training_mode: bool = True` parameter and
only apply `label_smoothing` when `training_mode=True`, OR pass
`label_smoothing=0.0` explicitly during the val forward pass.

Inspect the training loop to confirm: search for calls to `model(inputs, targets)`
and ensure the val call is either a separate code path or is protected.

**Total delta:** ~5 LOC in `parse_args` + ~2 LOC in forward. Clean, single-flag.

**No new dependencies.** `F.cross_entropy` in PyTorch >= 1.10 supports
`label_smoothing` natively.

---

## Sweep Plan (3–5 cells)

All cells run with the full R5 mandatory stack:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
--lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
--ema_eval_decay 0.99
```

`SENPAI_TRAIN_STEPS=3250`, `--num_trials 4` for all cells.

| Cell | `--label_smoothing` | Role | Expected FFS_ema |
|------|--------------------|----|-----------------|
| A | 0.0 (default) | CTRL — baseline replication | ~2912.5 (σ≈25) |
| B★ | 0.05 | Main hypothesis | ~2875 (target) |
| C | 0.1 | Standard NLP default | unknown — may overregularize near cap |
| D | 0.2 | Falsifier: too strong → signal loss | expected worse than ctrl |
| E | 0.02 | Fine-grained probe if B is alive | conditional on B |

**Run order:** A and B★ in parallel first. If B★ fails the alive-gate (FFS_ema
> 2975), report immediately and skip C/D. If B★ passes, run C and D together.
Run E only if B★ passes and C regresses — to narrow the optimal α.

**Wandb group:** `g1r5-thorfinn/label-smoothing-sweep`

---

## Gates

**FFS-alive gate (n=1 or n=4 at Cell B):**  
`FFS_ema ≤ 2975` — if Cell B★ exceeds this, the mechanism is inert; stop sweep.

**Promotion gate (n=4, comparing Cell B★ to baseline):**  
`FFS_ema ≤ 2875` OR `FFS_trainval ≤ 2900`

Note: the dual-metric seed-noise signature (FFS_ema=2875, FFS_trainval=2925) is
a known false positive pattern. Promotion requires BOTH metrics moving together OR
a clear distribution separation (e.g., all 4 seeds of B★ below 2912).

**Stop condition:**  
If Cell B★ gives FFS_ema > 2950 and the val/loss curves are visually identical
to the control, the mechanism is falsified — close immediately without running C/D.

---

## Commands

**Cell A (CTRL):**
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --label_smoothing 0.0 \
    --wandb_name "g1r5-thorfinn/label-smooth-ctrl-a0.0-n4" \
    --wandb_group "g1r5-thorfinn/label-smoothing-sweep"
```

**Cell B★ (main hypothesis):**
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --label_smoothing 0.05 \
    --wandb_name "g1r5-thorfinn/label-smooth-B-a0.05-n4" \
    --wandb_group "g1r5-thorfinn/label-smoothing-sweep"
```

**Cell C (standard NLP default):**
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --label_smoothing 0.1 \
    --wandb_name "g1r5-thorfinn/label-smooth-C-a0.1-n4" \
    --wandb_group "g1r5-thorfinn/label-smoothing-sweep"
```

**Cell D (falsifier):**
```bash
cd "$PROBLEM_DIR" && \
  SENPAI_TRAIN_STEPS=3250 torchrun --standalone --nproc_per_node=1 \
    records/track_3_optimization/train_gpt_simple.py \
    --num_trials 4 \
    --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
    --lr_scalars 0.03 --depth_init_mode musoft \
    --lr_cooldown_shape cosine \
    --ema_eval_decay 0.99 \
    --label_smoothing 0.2 \
    --wandb_name "g1r5-thorfinn/label-smooth-D-a0.2-n4" \
    --wandb_group "g1r5-thorfinn/label-smoothing-sweep"
```

---

## Why This Targets FFS Specifically (Not Just val/loss)

The FFS bottleneck is in the crossing-step window: the model is near 3.30–3.32
for hundreds of steps before dropping below 3.28. During this phase, the hard
one-hot targets produce near-zero gradients for already-confident token positions.
Label smoothing keeps the gradient signal non-trivial even for high-confidence
predictions, which means Muon can continue making orthogonal progress on the
embedding-to-hidden signal compression that drives the final 0.05-loss reduction.

The EMA-eval further amplifies this: because the EMA trajectory lags behind the
instantaneous weights, a smoother gradient path during the late main phase means
the EMA parameters also arrive at the 3.28 boundary earlier. This is why the
FFS_ema metric — not just val/loss — should respond.

---

## Research State Update

**Current best explanation for FFS plateau:**
All 64 closed axes show that the NS/SOAP/schedule cluster is saturated. The
remaining headroom must come from loss-level (training objective) or
initialization changes, or from a completely different optimizer mechanism.
Label smoothing is the first loss-level intervention in R5 that has not been
closed.

**Ruled-out paths (do not repeat):**
- All NS polynomial variants, NS iter count, NS fp precision changes
- All SOAP scalar HPs (β₁, β₂, precond_freq, trust)
- All Muon body wrappers (AGC, QHM, GC, Lookahead, Cautious)
- All aux optimizer variants (AdaFactor, AdaGrad, Lamb, Adan)
- All schedule variants (trapezoidal, SGDR, cosine, linear)
- All init variants (muP, maximal update, zero-init attn)
- Spectral-norm pre-NS (catastrophic: Frobenius normalization is load-bearing)
- Higham polar Newton polish on square attn (catastrophic: σ_min≈0.003)
- Schulz polynomial polish on non-square MLP (FFS-neutral)
- Cayley map gradient orthogonalization (catastrophic)

**Open uncertainties:**
1. Whether the logit soft-cap (`tanh_softcap(x, 15)`) effectively nullifies
   label smoothing by already preventing logit saturation.
2. What the optimal α is for this vocabulary size and architecture with Muon
   (standard NLP uses 0.1, but the softcap may require larger α).
3. Whether the benefit, if real, comes from the training phase or from an
   indirect effect on the EMA parameter trajectory.

**Taste rubric:**
- Mechanistic grounding: 3 — mechanism is plausible and targets a specific
  observed failure mode (near-zero gradients on confident tokens during the
  crossing phase), though the softcap interaction is a real risk.
- Research-state value: 4 — the result cleanly separates "loss-level
  interventions are useful" from "they are inert" without confounding NS/SOAP
  state. Either outcome is informative.
- Execution value: 4 — single-flag, ~5 LOC, no new dependencies, runs on the
  same 4-seed confirm harness. Very cheap information per unit compute.

**Confidence in novelty:** High — "label smoothing" does not appear in any
closed PR title or description in the 64-axis R5 closure log.

**Confidence in mechanism:** Moderate — the theory is sound but the softcap
interaction introduces genuine uncertainty about effect size.
