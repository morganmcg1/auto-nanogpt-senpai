# H247 frieren — Terminal Eval Mechanism: Best-Checkpoint Restore vs Manifold-Projected EMA

**Hypothesis class**: eval-mechanism (43rd mechanism class, 2nd in eval-mechanism sub-class)
**Student**: frieren
**Cycle**: ~1100
**Cumulative campaign state**: 96 NULL/NEG across 42 mechanism classes, 6 PROGRAMME FINDINGS
**PROGRAMME FINDING #57 candidate context**: H240 established that linear EMA averaging of polar-projection trajectory destroys converged-point geometry by pulling the averaged params OFF the orthogonal manifold that MuonH-SI's NS5 polar projection targets. This finding motivates two distinct eval strategies that do not have this flaw.

---

## Hypothesis Statement

The baseline terminal eval runs on the raw live parameters at step 3325, which are the correct point on the optimization trajectory. However, two alternative terminal eval strategies may extract better-quality weights: (1) restoring the best-val-loss checkpoint seen during training (avoiding potential terminal-step overshoot in the cosine cooldown) and (2) applying a manifold-projected EMA at eval-time only — averaging a running FP32 EMA buffer but then re-projecting body weights back onto the unit-spectral-norm manifold before evaluation, which directly tests whether the orthogonal-manifold constraint identified in H240/PROGRAMME FINDING #57 can rescue EMA averaging as an eval technique. These two strategies are orthogonal: best-checkpoint is pure selection from the training trajectory; manifold-projected EMA is a post-hoc geometric correction. Together they close the three follow-up axes explicitly enumerated by H240.

---

## Mechanism Analysis

**Why best-checkpoint-on-val (arm_b) may help**: The cosine cooldown shape (H203, PROGRAMME FINDING) drives the MuonH body LR from peak down to near-zero over the final ~30% of training. In principle the loss is monotonically improving during cooldown, but in practice the terminal val loss (step 3325) and the minimum val loss during training may differ by a few tenths of a sigma if the cooldown overshoots or if the discrete val sampling (25-step grid in the final 10%) misses the true minimum. Best-checkpoint selection costs nothing at training time — it only stores a second copy of the state dict on CPU memory (one-time ~400 MB for a 124M param model). It is orthogonal to any optimizer change. The key implementation constraint is that best-checkpoint restore must happen BEFORE the terminal val loss is computed at step==train_steps, so that `val/loss` reflects the restored weights, and that `first_step_to_target` and `best_val_loss` are updated accordingly. The mechanism is orthogonal-manifold-safe because it restores an actual training-trajectory point rather than an average.

**Why manifold-projected EMA (arm_c) may help (or not)**: H240 PROGRAMME FINDING #57 showed that naive linear EMA of the training trajectory pulls averaged params off the NS5 orthogonal manifold. The natural fix is to re-project body weights back to unit spectral norm after averaging. Specifically: maintain a per-param FP32 EMA buffer (decay=0.999, updated every training step); at the terminal eval event, for each body param (ndim >= 2, in MuonH groups), compute the NS5 polar projection of the EMA buffer entry, load it into the model; for aux params (ndim < 2), use the EMA buffer directly without projection. This is tested at eval-time only — no change to training dynamics, so the training trajectory is bit-identical to CTRL. If this succeeds, it implies the orthogonal-manifold constraint rescues EMA as an eval technique and opens a class of manifold-aware averaging strategies. If it fails (val >= arm_a CTRL), it implies either (a) the EMA decay is too slow/fast, (b) the NS5 re-projection does not fully recover convergence quality, or (c) the information lost by averaging (late-training sharpening) outweighs the smoothing benefit.

**torch.compile safety and bit-identity gate**: All new code must live in the validation section (lines 1070-1115 of train_gpt_simple.py) or as Python-level bookkeeping outside the compiled inner step. The compiled region is the inner optimizer step; the validation block and EMA buffer updates are plain Python/torch with no @torch.compile decoration. This mirrors H236 arm_a (branch OUTSIDE compile = FFS=3025 EXACT, no soft-drift). The bit-identity gate is `val/loss_fast`: log the raw live-parameter val loss for arm_c BEFORE loading EMA weights, then log the EMA val loss as `val/loss`. If arm_c's `val/loss_fast` matches arm_a CTRL within 2-3 sigma_H174, training is bit-identical and any EMA difference is attributable to the eval mechanism, not training contamination. This mirrors H240's key diagnostic.

---

## Arm Structure

### arm_a — CTRL (baseline reproduction)

**Argparse config**: all flags identical to H203 baseline. Two new flags default to `0` so arm_a is bit-identical.

```
--eval_best_ckpt 0
--eval_manifold_ema 0
```

**Expected result**: val ≈ 3.2678, FFS ≈ 3025 (reproduces H240 arm_a and H203 baseline). Confirms no soft-drift from torch.compile-retracing caused by new argparse branches. The new flags are simple integers parsed outside the compiled region, so no retracing is possible.

**W&B run name**: `frieren/h247-ctrl`

---

### arm_b — BEST_CKPT_VAL

**Argparse config**:

```
--eval_best_ckpt 1
```

**Mechanism**: At every val event where `val_loss_float < best_val_loss`, snapshot the full model state dict to CPU:

```python
# Inside val block, after computing val_loss_float, before the rank-0 metrics block:
if args.eval_best_ckpt and val_loss_float < best_val_loss:
    best_ckpt_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
    best_ckpt_step_recorded = step
```

At `step == train_steps`, restore before computing val_loss:

```python
# At the START of the val block, before model.eval() call, when step == train_steps:
if args.eval_best_ckpt and best_ckpt_state is not None:
    model.load_state_dict({k: v.to(device) for k, v in best_ckpt_state.items()})
    # Log the restored step for diagnostics
    best_ckpt_restored_step = best_ckpt_step_recorded
```

**W&B fields to add**:
- `eval/best_ckpt_restored`: 1 if restoration happened at terminal step, 0 otherwise
- `eval/best_ckpt_step`: the step of the restored checkpoint
- `eval/best_ckpt_val_loss`: the val/loss at that checkpoint step (for verification)

**Implementation notes**:
- `best_ckpt_state` is initialized to `None` before the training loop. Also initialize `best_ckpt_step_recorded = -1`.
- The snapshot at non-terminal val events is outside the compiled region (it is Python dict comprehension on `model.state_dict()`). No retracing possible.
- `model.load_state_dict()` at terminal step also outside compiled region (called before `model.eval()`).
- The outer MuLoCo step at `train_step < train_steps` already applied `p.data.copy_()` in-place, so the state_dict at each val event captures the correct post-MuLoCo params. The snapshot is valid.
- CPU clone costs ~400 MB memory (124M params × 4 bytes × safety factor). Acceptable on a 96 GB VRAM pod — but only keep one snapshot at a time (overwrite on improvement). Do not accumulate a deque of snapshots.
- After restoration, `best_val_loss` and `first_step_to_target` are updated based on the newly computed (post-restore) val_loss_float at step 3325, so `speedrun/final_first_step_to_target` is consistent with the restored params. This is correct: we are reporting the metric at the chosen eval point.

**Expected result**: If the cosine cooldown monotonically improves val loss all the way to step 3325, arm_b is exactly arm_a (identical params at terminal step = last improvement). If there is any terminal overshoot or non-monotonicity in the last ~100 steps, arm_b restores a slightly better checkpoint. Expected FFS = 3025 or better. Val loss: 3.264–3.268. A WIN would be val < 3.276 (n=1 stat rule) and FFS <= 3025.

**W&B run name**: `frieren/h247-best-ckpt`

---

### arm_c — MANIFOLD_EMA

**Argparse config**:

```
--eval_manifold_ema 1
--manifold_ema_decay 0.999
```

**Mechanism**: Maintain a per-param FP32 EMA buffer. Update after every training step (after optimizer step, before MuLoCo outer step so that MuLoCo-corrected params are tracked):

```python
# After outer MuLoCo step block (line ~1303), still in training section:
if args.eval_manifold_ema:
    with torch.no_grad():
        for n, p in model.named_parameters():
            if n not in manifold_ema_buf:
                manifold_ema_buf[n] = p.data.float().clone()
            else:
                manifold_ema_buf[n].mul_(args.manifold_ema_decay).add_(
                    p.data.float(), alpha=1.0 - args.manifold_ema_decay
                )
```

**Initialization**: `manifold_ema_buf: dict[str, torch.Tensor] = {}` before training loop. The first step initializes each entry in-place from `p.data.float()` (see code above — the `if n not in manifold_ema_buf` branch).

**MuonH body param set**: Need a set of parameter names that belong to MuonH body groups (ndim >= 2). Build this from the optimizer param_groups at init time:

```python
# After optimizers are built, before training loop:
if args.eval_manifold_ema:
    muonh_body_param_names = set()
    for pg in optimizers[0].param_groups:  # optimizers[0] is MuonH
        for p in pg['params']:
            for n2, p2 in model.named_parameters():
                if p2 is p and p2.ndim >= 2:
                    muonh_body_param_names.add(n2)
```

**Terminal eval**: At `step == train_steps`, BEFORE `model.eval()`:

```python
if args.eval_manifold_ema and manifold_ema_buf:
    # Step 1: log raw live-param val/loss_fast as bit-identity diagnostic
    model.eval()
    val_loss_fast = torch.zeros((), device=device)
    with torch.no_grad():
        for i in range(len(val_inputs) // mbs):
            val_loss_fast += model(val_inputs[i*mbs:(i+1)*mbs], val_targets[i*mbs:(i+1)*mbs])
    dist.all_reduce(val_loss_fast, op=dist.ReduceOp.SUM)
    val_loss_fast /= val_tokens
    val_loss_fast_float = float(val_loss_fast.item())
    model.train()

    # Step 2: save live params, load EMA params with manifold projection for body
    live_state = {k: v.clone() for k, v in model.state_dict().items()}
    with torch.no_grad():
        for n, p in model.named_parameters():
            ema_val = manifold_ema_buf[n].to(device)
            if n in muonh_body_param_names:
                # NS5 polar projection: exact zeropower_via_newtonschulz5 from
                # train_gpt_simple.py (a=2, b=-1.5, c=0.5, 12 iterations).
                # Verified from train_gpt_simple.py lines ~547-564.
                X = ema_val.bfloat16()
                if ema_val.shape[-2] > ema_val.shape[-1]:
                    X = X.mT
                X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
                a, b, c = 2, -1.5, 0.5
                for _ in range(12):
                    A = X @ X.mT
                    B = b * A + c * A @ A
                    X = a * X + B @ X
                if ema_val.shape[-2] > ema_val.shape[-1]:
                    X = X.mT
                p.data.copy_(X.to(p.dtype))
            else:
                p.data.copy_(ema_val.to(p.dtype))
    # model is now loaded with manifold-projected EMA params
    # The val block below will compute val/loss from these params
    # After val block completes, restore live params
```

After the standard val block runs (computing val_loss_float from the manifold-EMA params), restore:

```python
    # Restore live params after terminal val
    if args.eval_manifold_ema and live_state is not None:
        with torch.no_grad():
            model.load_state_dict(live_state)
        live_state = None
```

Log the bit-identity diagnostic alongside the EMA val metrics:

```python
# In rank-0 metrics block at terminal step, add:
if args.eval_manifold_ema:
    metrics["val/loss_fast"] = val_loss_fast_float
    metrics["eval/manifold_ema_applied"] = 1
    metrics["eval/manifold_ema_decay"] = args.manifold_ema_decay
```

**Implementation constraint on NS5 variant**: The train_gpt_simple.py script uses a specific NS5 polynomial in the MuonH optimizer class. Locate the exact polynomial coefficients (a, b for each of the 5 steps) in the MuonH class and replicate them verbatim in the manifold projection code above. Do not use a different NS5 variant. If the MuonH optimizer uses `a=1.5, b=-0.5` for all 5 iterations, use exactly that. If it uses a polynomial schedule (different a/b per iter), replicate the schedule exactly. This matters: different NS5 variants project to different points on the Stiefel manifold, and a mismatch would confound the test.

**W&B fields**:
- `val/loss_fast`: raw live-param val/loss before EMA loading (bit-identity gate)
- `val/loss`: EMA+manifold-projected val/loss (the primary metric for this arm)
- `eval/manifold_ema_applied`: 1 at terminal step
- `eval/manifold_ema_decay`: 0.999

**Expected result**: If manifold-projected EMA rescues the geometry, val/loss < arm_a CTRL. More likely: partial improvement (1-3 sigma better than CTRL) or no improvement. A RESCUE (val < 3.276, FFS hits) is a strong result that opens a new class of manifold-aware averaging strategies. A NULL (val >= CTRL) constrains the hypothesis: either the decay is wrong, or NS5 re-projection doesn't fully recover quality. `val/loss_fast` should match arm_a's val ≈ 3.2678 within 2-3 sigma_H174 (= 0.0018–0.0027) to confirm bit-identical training.

**W&B run name**: `frieren/h247-manifold-ema`

---

## Argparse Flags to Add

Add to `parse_args()` in `train_gpt_simple.py`, after the existing `--body_init_bottom_layers` block (around line 111):

```python
parser.add_argument("--eval_best_ckpt", type=int, default=0,
                    help="If 1, snapshot best-val-loss checkpoint during training and restore at terminal eval. "
                         "0 = disabled (default, bit-identical to baseline).")
parser.add_argument("--eval_manifold_ema", type=int, default=0,
                    help="If 1, maintain FP32 EMA buffer of params and apply manifold-projected EMA at terminal eval only. "
                         "0 = disabled (default, bit-identical to baseline).")
parser.add_argument("--manifold_ema_decay", type=float, default=float(os.environ.get("MANIFOLD_EMA_DECAY", "0.999")),
                    help="EMA decay for --eval_manifold_ema (default 0.999).")
```

These are simple scalar/int flags parsed at module load time (before `args = parse_args()`). No conditional branches inside @torch.compile. No retracing possible.

---

## NS5 Polynomial — Verified from train_gpt_simple.py

The exact NS5 polar projection function in train_gpt_simple.py (lines ~547-564) is:

```python
def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = 2, -1.5, 0.5
    for _ in range(12):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X.to(G.dtype)
```

Key parameters: `a=2, b=-1.5, c=0.5`, **12 iterations**, bfloat16 dtype, spectral norm via `norm(dim=(-2, -1))`, transpose via `.mT`. The arm_c implementation code above already uses these exact values. Do NOT substitute any other polynomial (e.g. `3.4445, -4.7750, 2.0315` is a different variant) — use only what is in the actual training script.

---

## Predicted Outcomes

| Arm | Config | Expected val/loss | Expected FFS | Sigma vs H174 baseline (3.26830) |
|-----|--------|-------------------|--------------|-----------------------------------|
| arm_a CTRL | `--eval_best_ckpt 0 --eval_manifold_ema 0` | 3.2678 ± 0.0009 | 3025 | ≈ 0 (baseline reproduction) |
| arm_b BEST_CKPT | `--eval_best_ckpt 1` | 3.264–3.268 | 2925–3025 | -0.5 to -5 sigma (WIN if overshoot exists) |
| arm_c MANIFOLD_EMA | `--eval_manifold_ema 1 --manifold_ema_decay 0.999` | 3.264–3.280 | 2925–3025 or -1 | -0.5 to +14 sigma (uncertain) |

For arm_b, the most likely scenario is that the cosine cooldown shape (H203 PROGRAMME FINDING) drives monotonic improvement to the very end, making arm_b ≡ arm_a (FFS=3025, val≈3.268). A WIN requires a non-trivial terminal overshoot.

For arm_c, the outcome distribution is bimodal: RESCUE (val < 3.276, EMA + manifold projection works) or NULL/NEG (val >= CTRL, manifold projection insufficient). A partial improvement of 2-3 sigma is also possible if the decay of 0.999 tracks the trajectory well.

---

## Statistical Rule Check

Target: `(3.28 − μ) × √n ≥ 0.004`, n=1 requires μ < 3.276.

- arm_a CTRL: 3.2678 → margin = 0.0122 ✓ (baseline)
- arm_b BEST_CKPT WIN scenario: val = 3.265 → margin = 0.015 ✓
- arm_c RESCUE scenario: val = 3.270 → margin = 0.010 ✓
- arm_c NULL scenario: val = 3.270+ → FFS may be -1 → no merge

For a WIN claim on arm_b or arm_c, the student must confirm n=1 result satisfies the statistical rule OR run n=4 seeds with mean < 3.278.

---

## Baseline Reproduction CLI

```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --eval_best_ckpt 0 \
  --eval_manifold_ema 0 \
  --wandb_name "frieren/h247-ctrl" \
  --wandb_group "h247-eval-mechanism"
```

arm_b:
```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --eval_best_ckpt 1 \
  --eval_manifold_ema 0 \
  --wandb_name "frieren/h247-best-ckpt" \
  --wandb_group "h247-eval-mechanism"
```

arm_c:
```bash
cd target/
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_warmup_steps 100 \
  --use_outer_optimizer 1 \
  --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 \
  --aux_agc_clip_ratio 0.05 \
  --muonh_agc_clip_ratio 0.05 \
  --aux_adamw_eps 1e-6 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --body_init orthogonal_fnorm_matched \
  --eval_best_ckpt 0 \
  --eval_manifold_ema 1 \
  --manifold_ema_decay 0.999 \
  --wandb_name "frieren/h247-manifold-ema" \
  --wandb_group "h247-eval-mechanism"
```

---

## Implementation Order (Student Checklist)

1. Locate `zeropower_via_newtonschulz5` (or equivalent) in train_gpt_simple.py — note exact polynomial coefficients and number of steps.
2. Add the three new argparse flags (`--eval_best_ckpt`, `--eval_manifold_ema`, `--manifold_ema_decay`) immediately after the `--body_init_bottom_layers` block.
3. Add `best_ckpt_state = None` and `best_ckpt_step_recorded = -1` initialization before the training loop (alongside existing `best_val_loss = float("inf")`).
4. Add `manifold_ema_buf: dict[str, torch.Tensor] = {}` before the training loop (only allocated if `args.eval_manifold_ema`).
5. After optimizers are built: if `args.eval_manifold_ema`, build `muonh_body_param_names` set by iterating `optimizers[0].param_groups`.
6. In the val block (line 1072 onwards): if `args.eval_best_ckpt and val_loss_float < best_val_loss`: snapshot state_dict to CPU. Do this AFTER computing `val_loss_float` but BEFORE updating `best_val_loss`.
7. At `step == train_steps` at the TOP of the val block (before `model.eval()`):
   - arm_b: if `args.eval_best_ckpt and best_ckpt_state is not None`: restore state_dict. Also initialize `live_state_restored = True` flag for logging.
   - arm_c: compute `val/loss_fast` (raw params), then load EMA params with NS5 projection for body params, save `live_state` for restoration. Set `eval_manifold_ema_applied = True`.
8. After terminal val block, for arm_c only: restore `live_state`.
9. Add `eval/best_ckpt_restored`, `eval/best_ckpt_step`, `eval/best_ckpt_val_loss` to rank-0 metrics (terminal step only).
10. Add `val/loss_fast`, `eval/manifold_ema_applied`, `eval/manifold_ema_decay` to rank-0 metrics (terminal step only, arm_c).
11. Run arm_a CTRL first. Confirm FFS=3025, val≈3.268. Confirm no torch.compile retracing (step_avg should be stable, not inflated by retracing).
12. Run arm_b and arm_c after CTRL confirms baseline.

---

## Suggested Follow-ups If WIN

**If arm_b BEST_CKPT wins** (confirms terminal overshoot exists):
- H248: measure the size of the overshoot by plotting val/loss curve across all val events. If the best checkpoint is consistently earlier than step 3325, consider extending train_steps slightly (e.g., to 3400-3450) to let the cosine cooldown land at a better terminal point. This is a schedule shape question, not a checkpoint question.
- H248 alt: If overshoot is small (< 2 sigma), run 4 seeds to confirm statistical significance of best-ckpt benefit.

**If arm_c MANIFOLD_EMA wins** (confirms manifold-projected EMA is viable):
- H248: tune `manifold_ema_decay` — try {0.99, 0.995, 0.9999} to find the optimal smoothing window. Decay 0.999 weights recent steps heavily; 0.9999 creates a longer-horizon average.
- H248 alt: combine arm_b + arm_c (best-checkpoint of the manifold-EMA trajectory, not the live-param trajectory).
- H249: Apply manifold-projected EMA throughout training (SWA-style on the orthogonal manifold) rather than only at terminal eval. This is a training-mechanism change, not just an eval change, and must preserve the benchmark contract.

**If both win**:
- Run 4-seed confirmation on the better one immediately.

**If both NULL/NEG**:
- Constrains: terminal eval point is already near-optimal for this stack, and manifold projection does not rescue EMA. Next eval-mechanism axis: stochastic weight averaging using multiple checkpoints from the last 5% of training (steps 3150-3325), all projected back to the manifold.

---

## Research State Update (cycle ~1100)

**Current best explanation**: The MuonH-SI + MuLoCo stack (H203 baseline, FFS=3025, val=3.2683) is structurally near-optimal for the current optimizer+schedule configuration. The campaign has spent 42 mechanism classes exhausting hyperparameter, schedule, and optimizer-replacement axes. The two most recent productive findings (PROGRAMME FINDING #56: aux schedule load-bearing; PROGRAMME FINDING #57: EMA destroys orthogonal manifold geometry) both point toward an understanding of WHY the current stack works, not toward obvious improvements. H247 tests whether the eval point itself can be improved.

**Evidence**: 96 NULL/NEG across 42 classes; H240 training trajectory bit-identical across 3 arms (val/loss_fast span 2.5 sigma); H236 arm_a torch.compile-safe pattern confirmed; all 4 aux optimizer replacements (H225, H237, H239, H241) bilateral NEG; outer MuLoCo HP+FORM closure complete (H222, H229, H236); cosine cooldown shape structurally load-bearing (H203 PROGRAMME FINDING).

**Ruled-out paths**: Aux optimizer replacement (AdEMAMix, Lion, SF-AdamW, Nesterov momentum changes); outer optimizer FORM replacement (Polyak) and momentum FORM (H229, H236); per-layer body LR; time-varying aux beta1/beta2; warmup on body is vestigial; schedule removal from aux is catastrophic.

**Open uncertainties**: (1) Is the terminal val point on a plateau or does the cosine cooldown overshoot? (2) Can manifold-aware averaging recover any quality from the training trajectory? (3) Is there a qualitatively different optimizer mechanism for the body that hasn't been tried (e.g., full matrix AdaGrad / Shampoo / Soap for the body rather than Muon)?

**Next discriminating experiment**: H247 arm_b and arm_c together — cheap (each is a single full run, no extra overhead beyond memory), and together they close the three H240 follow-up axes.

**Stop condition for this direction**: If both arm_b and arm_c are NULL/NEG and arm_a CTRL matches baseline (FFS=3025, val≈3.268), the eval-mechanism class is exhausted. Next direction should move to a qualitatively different optimizer mechanism for the body (e.g., Shampoo/Soap preconditioner replacing NS5 polar projection, or a full second-order update).

---

## Experiment Tree

```
H247 3-arm result
├── arm_a CTRL: FFS=3025, val≈3.268 (expected)
│   └── Confirms torch.compile safety of new flags
├── arm_b BEST_CKPT
│   ├── WIN (FFS < 3025 or val < 3.276):
│   │   → H248: tune terminal step count; run 4-seed confirmation
│   │   → Implies cosine cooldown overshoots; schedule shape experiment
│   └── NULL (FFS=3025, val≈3.268):
│       → Terminal eval point is already optimal (cosine cooldown monotone)
│       → Best-checkpoint as eval mechanism ruled out
└── arm_c MANIFOLD_EMA
    ├── RESCUE (val < 3.276):
    │   → H248: tune manifold_ema_decay {0.99, 0.995, 0.9999}
    │   → H249: SWA on orthogonal manifold during training
    │   → Opens manifold-aware averaging class
    ├── PARTIAL (3.276 ≤ val < arm_a):
    │   → H248: tune decay; try combining best-ckpt + manifold-EMA
    └── NULL/NEG (val ≥ arm_a):
        → Manifold-projected EMA does not rescue geometry
        → H240 PROGRAMME FINDING #57 confirmed: EMA fundamentally
          incompatible with polar-projection optimization trajectory
        → Next: Shampoo/Soap body preconditioner (44th mechanism class)
```

---

## Taste Rubric

**Research mode**: diagnostic (separating causes: is the terminal eval point sub-optimal? does manifold projection rescue EMA?)

| Criterion | arm_b BEST_CKPT | arm_c MANIFOLD_EMA |
|-----------|-----------------|---------------------|
| Mechanistic grounding | 4 — directly tests whether cosine cooldown overshoots; falsifiable (compare val at best-ckpt step vs step 3325) | 4 — directly tests H240 PROGRAMME FINDING #57 follow-up; precise mechanism (NS5 re-projection rescues geometry); falsifiable via val/loss_fast gate |
| Research-state value | 3 — WIN or NULL both sharply constrain the terminal-step schedule shape question | 4 — WIN or NULL both sharply update the orthogonal-manifold EMA hypothesis; diagnostic val/loss_fast provides bit-identity verification regardless of outcome |
| Execution value | 4 — ~50 LoC, one full run, minimal overhead, directly targets FFS/val | 3 — ~100 LoC, one extra forward pass at terminal step, moderate complexity; risk is NS5 polynomial mismatch if not verified |

---

## Confidence

**arm_b**: Strong. The mechanism is simple, the implementation is clear, and the only uncertainty is whether the cosine cooldown overshoots (empirically testable). The NULL outcome (no overshoot) is also informative. Implementation risk: low.

**arm_c**: Moderate. The mechanism is well-motivated by H240, but the outcome is genuinely uncertain. The implementation has one identified risk (NS5 polynomial mismatch if not replicated exactly). The val/loss_fast gate provides a clean bit-identity check regardless of outcome. Implementation risk: medium (NS5 coefficient verification is critical).

**arm_a CTRL**: Very high. Standard baseline reproduction. New flags default to 0 (disabled), so training path is bit-identical. Only risk is a torch.compile retracing from the new argparse branches, which is structurally impossible since all new code is in the validation section.
