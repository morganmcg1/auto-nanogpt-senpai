# Schedule-Free Muon: Polyak-Ruppert Iterate Averaging for the Muon Body Optimizer

## Hypothesis

The current Muon optimizer applies a cosine-cooldown LR schedule over 70% of training (steps 975–3250) to implicitly average late-trajectory iterates toward a good solution. Schedule-Free optimization (Defazio et al., 2024) replaces this implicit averaging with an explicit Polyak-Ruppert iterate average — maintaining a "base iterate" z that moves by gradient steps, and evaluating/updating a "primal iterate" x that is a weighted Polyak average of all z values seen. This decouples optimization speed (z) from solution quality (x), and has been shown empirically to match or exceed tuned LR schedules across a wide range of tasks including transformer language models. Adding SF averaging to Muon's body-parameter updates (MLP + attn weights) is orthogonal to: all 7 in-flight experiments, all 92 closed R5 experiments, and the existing EMA-eval trajectory — making it a clean, untested axis with a strong theoretical and empirical prior.

## Mechanism

Standard Muon per step: `p ← p - lr * NS5(Nesterov(grad, momentum))`

Schedule-Free Muon per step:
1. Gradient was computed at x = p (the Polyak average, which is what forward pass sees)
2. Apply gradient step to z (base iterate): `z ← (1 - lr*wd) * z - lr * NS5(Nesterov(grad, momentum))`
3. Update Polyak weights: `c_new = c_old + lr_t` (or `c_old + beta * lr_t` with momentum param)
4. Update x (what p holds): `x_new = (c_old * x_old + lr_t * z_new) / c_new`
5. Sync x across ranks via existing `dist.all_gather`

Key properties:
- z is purely local state (one rank owns each param) — no extra communication
- x (p.data) is what gets synced — same as baseline, zero additional comm cost
- Weight decay applies to z, not x (prevents over-shrinking the averaged iterate)
- Gradient evaluation point is x (the averaged iterate) — this is standard SF practice and matches the existing forward pass
- The existing EMA-eval lives outside this loop entirely — SF x-iterate and EMA are additive parallel structures, not competing

## Prior-Work Review: Confirming Axis is Open

Reviewed all 92 R5 closures and 7 in-flight experiments:

**Closed axes (confirmed not SF-related):**
- μ cooldown (#1951, FFS-NEU): schedules the Muon momentum COEFFICIENT mu=0.95→lower; not Polyak averaging
- Muon mom reset (#1993, FFS-NEU): DISCRETE zero-reset of momentum buffer; not SF
- AUX-side cooldown family (4 closures: eps, ema-decay, β₁, shape): all AUX/AdamW side only
- WD-axis: magnitude/shape/direction closed; WD is applied to z in SF, not a new axis
- NS5 absorption family: perturbations inside NS5 or post-NS5 depth-LR — not SF
- LN gain init: initialization axis, orthogonal

**In-flight (confirmed not SF):**
- frieren #1966: mu RAMP (mu=0.80→0.95 during cooldown) — momentum coefficient schedule, not Polyak averaging
- edward #1948: SOAP precond_freq cooldown — second-order preconditioner frequency, not SF
- thorfinn #1994: SOAP state hard-reset at step 975 — state reset, not SF
- tanjiro #2014: NS5 iteration count cooldown ramp — polynomial iterations, not SF
- nezuko #2020: SOAP β₂ cooldown ramp — second-order EMA decay, not SF
- alphonse #1979: LR warm-restart pulse — LR schedule perturbation, not SF
- fern #2023: Lion as AUX optimizer — AUX side only, Muon body unchanged

**Conclusion:** Schedule-Free iterate averaging on the Muon body parameters has never been tested. The axis is fully open.

## External Evidence

- Defazio et al. (2024): "Schedule-Free Learning — A New Way to Train" — SF-AdamW won MLCommons 2024 AlgoPerf Self-Tuning track. On NanoGPT 124M trained to 1B tokens, SF-AdamW with β=0.98 matches well-tuned cosine-schedule AdamW. This is the closest external analogue to our setup.
- The mechanism transfers to any gradient-based optimizer — SF is a wrapper, not a replacement. SF-SGD, SF-Adam, SF-Lion have all been validated.
- Key empirical finding: SF averaging is most beneficial when the LR schedule would otherwise drop aggressively late in training. Our 70% cosine cooldown is exactly this regime.
- Defazio & Orabona (2023): theoretical analysis shows SF converges at the same rate as tuned schedules under standard assumptions, with better worst-case guarantees.

## Implementation Plan

### State Changes to `Muon.__init__`

For params in the Muon-only groups (non-SOAP), add to state init:
```python
if len(state) == 0:
    state["momentum"] = torch.zeros_like(p)
    if group.get("schedule_free", False):
        state["z"] = p.data.clone()      # base iterate, same dtype as p (bfloat16)
        state["sf_c_sum"] = 0.0          # float32 Polyak weight accumulator
```

### Modified `Muon.step()` — SF Branch (~30 LOC added)

Inside the distributed round-robin loop, after computing `update` via `muon_update`:

```python
# Current baseline path:
#   p.mul_(1 - group["lr"] * group["weight_decay"])
#   p.add_(update, alpha=-group["lr"])

if group.get("schedule_free", False) and "z" in state:
    z = state["z"]
    lr = group["lr"]
    wd = group["weight_decay"]
    # Step z (base iterate) — weight decay + gradient step
    z.mul_(1 - lr * wd)
    z.add_(update, alpha=-lr)
    # Polyak-Ruppert averaging into x (what p holds)
    sf_beta = group.get("sf_beta", 1.0)   # optional momentum param on c_t weight
    c_t = lr * sf_beta
    new_c_sum = state["sf_c_sum"] + c_t
    # x_new = (c_old/c_new)*x_old + (c_t/c_new)*z_new
    p.data.mul_(state["sf_c_sum"] / new_c_sum)
    p.data.add_(z, alpha=c_t / new_c_sum)
    state["sf_c_sum"] = new_c_sum
else:
    # Baseline path (unchanged)
    p.mul_(1 - group["lr"] * group["weight_decay"])
    p.add_(update, alpha=-group["lr"])
```

### CLI Flags to Add

```python
parser.add_argument("--sf_muon", action="store_true", default=False,
    help="Enable Schedule-Free iterate averaging for Muon body parameters")
parser.add_argument("--sf_beta", type=float, default=1.0,
    help="Polyak weight momentum: c_t = lr_t * sf_beta^step (1.0=standard)")
parser.add_argument("--sf_muon_groups", type=str, default="all",
    choices=["all", "mlp", "attn"],
    help="Apply SF averaging to: all Muon groups, MLP only, or attn only")
```

In optimizer creation:
```python
optimizer2 = Muon(
    [
        dict(named_params=mlp_named, lr=args.lr_mlp, weight_decay=args.wd_mlp,
             name="muon_mlp",
             schedule_free=args.sf_muon and args.sf_muon_groups in ("all", "mlp"),
             sf_beta=args.sf_beta),
        dict(named_params=attn_named, lr=args.lr_attn, weight_decay=args.wd_attn,
             name="muon_attn",
             schedule_free=args.sf_muon and args.sf_muon_groups in ("all", "attn"),
             sf_beta=args.sf_beta),
    ],
    soap_attn=args.soap_attn,
    trust_threshold=args.soap_trust_threshold,
)
```

### Critical Implementation Notes

1. **`muon_update` is `@torch.compile` — do NOT modify it.** The SF logic lives outside the compiled function, in the plain Python `step()` loop. This avoids recompilation and keeps the change surgical.

2. **SOAP params are excluded from SF.** SOAP maintains its own second-order state (exp_avg_sq, row_gg, col_gg) and trust-region logic. Layering SF on top of SOAP is a separate experiment. Default: SF only on plain-Muon params (MLP + attn when soap_attn=False; attn excluded from SF when soap_attn=True).

3. **Gradient evaluation point.** SF theory requires gradients computed at x (the primal/averaged iterate), not at z. Since p holds x and the forward pass uses p, this is automatically satisfied — no change needed to the training loop.

4. **Weight decay on z, not x.** Applying WD to the averaged iterate x would over-shrink it because x is already a mixture of past z values. Always apply WD to z only.

5. **`sf_c_sum` numerical stability.** After ~3250 steps with lr≈0.055, c_sum ≈ 0.055 * 975 (warmup) + integral of cosine cooldown ≈ ~70. Float32 is sufficient — no overflow or precision concern.

6. **EMA-eval interaction.** EMA-eval reads from `p` (which holds x, the Polyak average). This is BETTER than baseline where EMA reads from the raw gradient-step iterate. The Polyak average is already smoother, so EMA should be at least as good. No code change needed in the EMA update block.

7. **Checkpoint compatibility.** `state["z"]` is saved in the optimizer state dict. Resuming from a non-SF checkpoint requires adding the `--sf_muon` flag and letting z initialize fresh at the next step (cold start from current p). This is acceptable for screening — only mention it in results.

8. **LR schedule interaction.** The cooldown LR schedule still applies to both z-stepping (governs gradient step size) and the Polyak c_t weights (governs recency weighting). When LR drops to 0 at end of cooldown, z stops moving and x freezes — equivalent to early stopping on the best Polyak-average. This is a feature, not a bug.

## Experimental Design: 3-Cell Screen (n=1 each)

All cells use the mandatory R5 stack:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99`
`train_steps=3250` (default via SENPAI_TRAIN_STEPS)

**Baseline reference:** μ₄(FFS_ema)=2912.5, val_loss=3.269600

---

### Cell 1 (Standard SF, all Muon groups)

Hypothesis: SF averaging on all plain-Muon params (MLP + attn if SOAP is off for those) with c_t = lr_t improves FFS_ema vs baseline.

Note: with `--soap_attn`, attn weights use SOAP preconditioner. SF will apply to MLP weights only (which use plain Muon). This is the highest-impact group by parameter count.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r5-askeladd/sf-muon-all-beta1.0" \
  --wandb_group "sf-muon-screen" \
  --sf_muon \
  --sf_beta 1.0 \
  --sf_muon_groups all \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

Expected signal: FFS_ema in range 2800–2950. Kill if val/loss at step 1000 > 3.50 (clear divergence).

---

### Cell 2 (SF with recency bias: sf_beta=0.98)

Hypothesis: Giving more weight to recent z iterates (sf_beta=0.98 means c_t = lr_t * 0.98^(1-step/T) decay... simpler: use sf_beta as a discount: new_c_sum = sf_beta * c_old + c_t) improves convergence by down-weighting early (high-LR) iterates that may be far from the optimum.

Implementation variant: change Polyak update to `new_c_sum = sf_beta * state["sf_c_sum"] + c_t` — this gives exponentially decaying weight to old iterates, equivalent to an EMA of z values with α=1-sf_beta per step. This is the "momentum" variant of SF averaging.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r5-askeladd/sf-muon-all-beta0.98" \
  --wandb_group "sf-muon-screen" \
  --sf_muon \
  --sf_beta 0.98 \
  --sf_muon_groups all \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

---

### Cell 3 (SF MLP-only, sf_beta=1.0)

Hypothesis: Restricting SF averaging to MLP weights only (the dominant plain-Muon group) isolates the effect and avoids any unintended interaction with SOAP attn state.

```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "g1r5-askeladd/sf-muon-mlp-beta1.0" \
  --wandb_group "sf-muon-screen" \
  --sf_muon \
  --sf_beta 1.0 \
  --sf_muon_groups mlp \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

---

### Decision Tree After Screen

```
Cell 1 (beta=1.0, all):
  FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912  →  PROMOTE to n=4 (Cell 1 config)
  2862 < FFS_ema ≤ 2950                   →  Compare with Cell 2 and Cell 3
  FFS_ema > 2950 or -1                    →  Close unless Cells 2/3 show signal

Cell 2 (beta=0.98, all):
  FFS_ema ≤ 2862                          →  PROMOTE to n=4 (Cell 2 config)
  Better than Cell 1                      →  Prefer Cell 2 for n=4
  Worse than Cell 1                       →  Discount the recency-bias variant

Cell 3 (mlp-only, beta=1.0):
  Better than Cell 1                      →  SF benefit is MLP-specific (SOAP attn fights SF)
  Similar to Cell 1                       →  SF benefit is MLP-dominated (attn contributes little)
  Worse than Cell 1                       →  SF attn interaction adds value (SOAP+SF compatible)

If best cell beats 2862: Launch n=4 at that cell's config
If best cell in 2862-2912: Submit for advisor review; likely worth n=4 borderline
If all cells > 2912 or -1: Close; SF averaging absorbed by existing cosine schedule
```

## Signal Gates and Stop Conditions

**Promote to n=4:** FFS_ema ≤ 2862 OR FFS_trainval ≤ 2912 (50-step improvement over 2912.5 mean)
**Merge gate (n=4):** μ₄(FFS_ema) ≤ 2887.5 (stat sig: (3.28 - mu) * sqrt(4) >= 0.004)
**Early kill:** val/loss at step 1000 > 3.50 (divergence); or FFS_ema = -1 AND val/loss at end > 3.28 + 0.020 (clearly missed by large margin)
**Close direction:** all 3 cells FFS_ema > 2950 or all -1

## Pre-Mortem: 5 Risks

1. **The cosine cooldown already IS the schedule-free averaging, functionally.** The cooldown forces LR → 0, which implicitly weights late iterates heavily — similar to Polyak averaging. If SF and cosine are near-equivalent in this regime, SF adds nothing and FFS_ema stays ≈ 2912. Distinguishing test: if Cell 1 and baseline FFS_ema are within 20 steps, this risk materializes.

2. **Gradient evaluation at x conflicts with Muon's update magnitude.** NS5 orthogonalization normalizes the update to unit spectral norm. The Polyak-averaged x may have different gradient statistics than z, potentially causing update magnitudes to drift. The `max(1, m/n)^0.5` scale factor in `muon_update` compensates for shape but not for distribution shift. Monitor `train/grad/rms` and `train/weight/rms` for anomalies.

3. **SOAP attn params are excluded, limiting scope.** With `--soap_attn`, attn weights use SOAP preconditioner. SF logic applies only to MLP weights. If MLP weights are not the bottleneck (SOAP attn dominates convergence quality), the SF benefit is bounded. Cell 3 (MLP-only) will bound the ceiling.

4. **c_sum numerical instability in bfloat16.** The z iterate is bfloat16 (same as p). The Polyak blend `p = (c_old/c_new)*x + (c_t/c_new)*z` requires careful casting: do the arithmetic in float32, then cast back. If bfloat16 rounding accumulates, x may drift from the true Polyak average. Implementation must cast z to float32 before blending.

5. **sf_beta=0.98 may interact badly with LR schedule.** During cooldown, LR drops from 0.055 to 0. With sf_beta=0.98, c_t = lr * 0.98 ≈ 0 at end of training — the Polyak average stops updating entirely before training ends, effectively freezing at whatever x was ~100 steps before end. This could either help (early stopping on best average) or hurt (misses final z improvements). Monitor val/loss trajectory in Cell 2 vs Cell 1 during cooldown phase.

## Literature Citations

- Defazio, A., Yang, X., Mehta, H., Mishchenko, K., Khaled, A., & Cutkosky, A. (2024). "The Road Less Scheduled." arXiv:2405.15682. [Schedule-Free Adam/SGD; won MLCommons AlgoPerf 2024]
- Defazio, A., & Orabona, F. (2023). "Learning-Rate-Free Learning by D-Adaptation." ICML 2023. [Theoretical grounding for parameter-free optimization]
- Polyak, B.T., & Ruppert, D. (1992). "Acceleration of stochastic approximation by averaging." SIAM Journal on Control and Optimization. [Original iterate averaging theorem]
- Kovalev, D., Islamov, D., Safaryan, M., & Richtárik, P. (2024). "SGD with Large Step Sizes Learns Sparse Features." arXiv:2210.05337. [Large-step SGD + iterate averaging synergy]
- Kosson, A., Nikdan, M., & Vogels, T. (2023). "Muon: An Optimizer for Hidden Layers in Neural Networks." [Original Muon paper; confirms Nesterov + NS5 combination]
