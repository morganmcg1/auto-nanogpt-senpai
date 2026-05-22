# NS-WarmUp: Sequential Newton-Schulz Iteration Ramp-Up

## Hypothesis Name
NS-WarmUp

## One-Sentence Motivation
Start Newton-Schulz iterations at 2 and linearly ramp to the baseline 6 over the first 300–1000 training steps, reducing over-orthogonalization of noisy early-phase gradients so the optimizer takes larger effective steps during loss-landscape stabilization and arrives at the target val/loss sooner.

---

## Experiment Cells

All cells run with `SENPAI_TRAIN_STEPS=3250` (default). Cell A is the unmodified baseline (control). Cells B–E add `--ns_warmup_steps` and `--ns_warmup_start` only.

**Mandatory base flags for all cells:**
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft
```

### Cell A — Control (baseline replication)
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --wandb_group ns_warmup_sweep
```
Expected: matches PR #699 baseline μ=3.261221, ffs≈3025.

### Cell B — ns_warmup_steps=500, ns_warmup_start=2 (primary bet)
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --ns_warmup_steps 500 --ns_warmup_start 2 \
  --wandb_group ns_warmup_sweep
```
Ramp: 2 → 6 iterations over steps 0–500 (~15% of training).

### Cell C — ns_warmup_steps=300, ns_warmup_start=3 (fast ramp, gentler start)
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --ns_warmup_steps 300 --ns_warmup_start 3 \
  --wandb_group ns_warmup_sweep
```
Ramp: 3 → 6 over steps 0–300 (~9% of training). Less disruption if early-phase orthogonalization matters.

### Cell D — ns_warmup_steps=1000, ns_warmup_start=2 (slow ramp)
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --ns_warmup_steps 1000 --ns_warmup_start 2 \
  --wandb_group ns_warmup_sweep
```
Ramp: 2 → 6 over steps 0–1000 (~31% of training). Tests whether a longer low-orthogonalization phase is beneficial or harmful.

### Cell E — ns_warmup_steps=500, ns_warmup_start=1 (most aggressive)
```bash
python records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 \
  --wd_schedule ramp_down --lr_scalars 0.03 \
  --depth_init_mode musoft \
  --ns_warmup_steps 500 --ns_warmup_start 1 \
  --wandb_group ns_warmup_sweep
```
Ramp: 1 → 6 over steps 0–500. 1-iteration NS is nearly a raw gradient step scaled by the aspect-ratio factor — tests whether near-identity updates at initialization help.

---

## Mechanism

### Theoretical basis

The Newton-Schulz (NS) iteration applied in Muon computes an approximate matrix square root / polar factor of the gradient matrix. With `ns_iter=6` and the Chebyshev-optimal degree-5 polynomial `a=2, b=-1.5, c=0.5`, the iteration converges to the orthogonal polar factor of G, enforcing equal singular values across all directions. This fully-orthogonalized update is a strong spectral normalizer and prevents any single gradient direction from dominating — which is precisely why Muon outperforms Adam on weight matrices in the stable mid-to-late training phase.

However, at initialization the gradient landscape is highly noisy and the rank structure of gradient matrices changes rapidly as the loss drops from ~10 to ~5. In this phase, full orthogonalization may be counterproductive: it aggressively equalizes singular values that are legitimately different (high-signal vs. low-signal directions), effectively discarding curvature information the optimizer could exploit for faster early descent. Fewer NS iterations leave more of the original singular-value spread intact, which means the update more faithfully follows the gradient signal in the directions where the loss is steepest. The web-search-confirmed finding from the Muon convergence literature (see NanoGPT empirical work) states explicitly: "fewer iterations require a smaller step size and increased momentum" — conversely, at a fixed learning rate, fewer iterations can take a larger effective step in high-signal directions, which is what we want early in training when the loss is far from its target.

### Connection to SOAP and the current baseline

With `--soap_attn`, the SOAP preconditioner is active on attention projections. SOAP uses a Kronecker-factored Adagrad-style preconditioner that already adapts to per-direction curvature, so attention layers are less reliant on NS-driven spectral equalization than MLP layers. The MLP layers use plain Muon (`muon_mlp` group). The NS-WarmUp change will primarily affect the MLP group where full orthogonalization is most dominant. During warmup, the MLP group will receive gradient updates with preserved singular-value diversity, potentially allowing faster early loss descent. After warmup completes at step 300–1000, behavior is identical to the baseline — there is no late-training risk from this modification.

### Why this is distinct from all closed/in-flight axes

This is not a modification to the NS polynomial coefficients (those remain `a=2, b=-1.5, c=0.5`). It is not a change to Muon momentum (mu=0.95 throughout). It is not a schedule on LR, weight decay, or any existing parameter. It is not Cautious-Muon (no sign masking), not NorMuonH (no per-matrix LR normalization), not gradient centralization (no mean subtraction), not Muon² (no Adam v-buffer). The mechanism is purely: progressively increase the degree of spectral equalization applied to gradient matrices as training stabilizes, analogous to how LR warmup progressively increases step size as the optimizer finds its footing.

---

## CLI Flags and Code Paths

### New CLI arguments to add

In `records/track_3_optimization/train_gpt_simple.py`, add to the argument parser (near line 65 where `--ns_iter` is defined):

```python
parser.add_argument("--ns_warmup_steps", type=int, default=0,
    help="Linearly ramp ns_iter from ns_warmup_start to ns_iter over this many steps. 0 = disabled.")
parser.add_argument("--ns_warmup_start", type=int, default=2,
    help="Starting ns_iter count for NS warmup ramp (must be < ns_iter).")
```

### Module-level mutable NS iter state

After line 95 (`NS_ITER = args.ns_iter`), add:

```python
# Mutable container for dynamic NS iter scheduling.
# Using a list so @torch.compile sees a Python object mutation, not an int rebind.
# Note: torch.compile will retrace when _NS_ITER[0] changes value.
_NS_ITER = [NS_ITER]
```

### Modify `zeropower_via_newtonschulz5` to use `_NS_ITER[0]`

Current (line 483–500):
```python
for _ in range(NS_ITER):
```

Change to:
```python
for _ in range(_NS_ITER[0]):
```

This makes the loop count dynamic. `@torch.compile` will retrace when `_NS_ITER[0]` changes, which happens at most `ns_iter - ns_warmup_start` times total (e.g., 4 retraces for start=2, target=6). After warmup completes the value is constant and no further retracing occurs.

### Helper function for NS iter schedule

Add after the argument parsing section (after line 95):

```python
def _get_ns_iter_for_step(step: int) -> int:
    """Return the NS iteration count to use at the given training step."""
    if args.ns_warmup_steps <= 0 or args.ns_warmup_start >= NS_ITER:
        return NS_ITER
    if step >= args.ns_warmup_steps:
        return NS_ITER
    frac = step / args.ns_warmup_steps
    return args.ns_warmup_start + round((NS_ITER - args.ns_warmup_start) * frac)
```

### Update `_NS_ITER[0]` in the training loop

At the start of the training loop body (after line 916 `for step in range(train_steps + 1):`), before `optimizer2.step()` is called:

```python
# Update NS iter for warmup schedule
new_ns_iter = _get_ns_iter_for_step(step)
if new_ns_iter != _NS_ITER[0]:
    _NS_ITER[0] = new_ns_iter
```

This is the complete change. No other code paths need modification. The `muon_update` and `soap_ns_step` compiled functions both call `zeropower_via_newtonschulz5`, which now reads `_NS_ITER[0]` rather than the frozen `NS_ITER` constant.

### Relevant code locations

| What | Line | Notes |
|------|------|-------|
| `--ns_iter` arg definition | ~65 | Add new args adjacent here |
| `NS_ITER = args.ns_iter` | 95 | Add `_NS_ITER = [NS_ITER]` after this |
| `zeropower_via_newtonschulz5` | 483–500 | Change `range(NS_ITER)` to `range(_NS_ITER[0])` |
| `muon_update` (compiled) | 502–508 | No change needed; calls NS function |
| `soap_ns_step` (compiled) | 511–515 | No change needed; calls NS function |
| Training loop start | 916 | Add `_NS_ITER[0]` update here |

---

## Risks and Kill-Switch

### Primary risks

1. **torch.compile retrace overhead.** Each unique value of `_NS_ITER[0]` triggers a graph retrace of `muon_update` and `soap_ns_step`. For Cell B (start=2, end=6) this means at most 4 retraces during the 500-step warmup. Retracing is slow (~seconds each) but happens once per distinct value. Total overhead: ~20–30 GPU-seconds across the run. Acceptable.

2. **Early instability from under-orthogonalized updates.** With `ns_warmup_start=1` (Cell E), the first update is essentially a scaled gradient step without spectral normalization. If initialization is unlucky, this could cause an early spike. The loss curve should be monitored in the first 100 steps; if val/loss is diverging (> 9.5 at step 125), abort Cell E and treat it as a failed arm.

3. **No benefit if early-phase SNR is high.** The hypothesis assumes early gradients are noisy enough that full orthogonalization hurts. If this is wrong (the model quickly learns stable gradient directions), NS-WarmUp will have no effect and all cells will match Cell A within noise.

4. **Interaction with SOAP.** SOAP on attention layers uses a separate NS application in `soap_ns_step`. The warmup affects both MLP and attention NS calls. If SOAP's preconditioner accuracy benefits from full orthogonalization at every step, early warmup could harm attention convergence. Monitoring attention layer gradient norms (if logged) can diagnose this.

### Kill-switch

If any warmup cell shows val/loss at step 500 worse than Cell A by more than 0.02 nats, that arm should be aborted early (do not wait for step 3250). The expected effect is either neutral or beneficial; a regression at the 500-step checkpoint is diagnostic of a fundamental incompatibility.

**Specific abort threshold:** val/loss > 3.32 at step 1000 for any cell → abort that arm. Cell A should be at approximately 3.35–3.38 at step 1000 based on typical loss curves in this codebase.

---

## Predicted Ranking

From most likely to improve FFS to least:

1. **Cell B (best bet):** ns_warmup_steps=500, start=2. The sweet spot — enough warmup to cover early noisy phase (~15% of training), not so long that it interferes with mid-training optimization. Predicted: ffs improvement of 25–75 steps over baseline (ffs ≈ 2950–3000), val/loss ≈ 3.259–3.261.

2. **Cell C:** ns_warmup_steps=300, start=3. Conservative variant — shorter ramp, higher start. Less orthogonalization change. May show modest FFS improvement or null result. Predicted: ffs ≈ 2990–3030.

3. **Cell A (control):** Matches baseline μ=3.261221, ffs≈3025. Reference point.

4. **Cell D:** ns_warmup_steps=1000, start=2. Long warmup covering 31% of training — may hurt mid-training convergence by delaying full spectral normalization into the critical loss-drop phase. Predicted: ffs ≈ 3025–3075 (neutral to slightly worse).

5. **Cell E (most aggressive):** start=1. Near-gradient updates at initialization. Highest variance — could produce the best or worst result. If early steps are sensitive to spectral normalization, this will diverge or stall. Predicted: ffs ≈ 2950–3100 (bimodal: either best or worst).

---

## Budget

- 5 cells × 1 seed each = 5 runs
- Each run: ~3250 steps on 1×H100, approximately 90–100 minutes per run
- Total estimated wall time: ~8–9 hours
- Within SENPAI_TIMEOUT_MINUTES budget

If Cell B shows clear improvement (val/loss < 3.259) at first result, run 3 additional seeds on Cell B only for the n=4 gate. Additional seeds: ~3 × 95 minutes ≈ 5 additional hours (secondary phase if primary gate is met).

---

## Research State Context

**Current baseline (PR #699 merged):** μ=3.261221, σ=0.000593, n=4, ffs_mean=3025  
**Gate to beat:** μ ≤ 3.259221 (statsig: (3.261221 − μ) × √4 ≥ 0.004)

**Why this direction is not exhausted:** All prior Muon modifications have targeted the update direction (Cautious-Muon), the momentum buffer (Muon²), per-matrix normalization (NorMuonH), the trust gate (in-flight #773), and the Nesterov momentum (MuonH). None have targeted the temporal schedule of spectral equalization strength. The NS iteration count is currently treated as a fixed hyperparameter; this experiment asks whether it should be a schedule.

**Falsification:** If all 4 warmup cells (B, C, D, E) fail to improve on Cell A, the hypothesis is falsified and NS iteration count should be treated as a static optimum at 6. This would also suggest that early-phase spectral equalization is beneficial (or neutral), not harmful.
