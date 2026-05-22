# Hypothesis: Muon Update RMS Normalization
**Date:** 2026-05-22
**Student:** g1r5-askeladd
**Branch:** auto-nanogpt-1gpu-r5

---

## What it is

After Newton-Schulz (NS) orthogonalization and aspect-ratio scaling, normalize the Muon update matrix to a fixed target root-mean-square (RMS) value per matrix, making each layer's effective step size scale-invariant — decoupled from gradient magnitude, matrix shape, and NS convergence quality.

---

## Mechanism rationale

`zeropower_via_newtonschulz5` normalizes its **input** (spectral norm ≤ 1) before iterating but applies **no normalization to its output**. The output RMS depends on:
1. How close the input singular values are to the assumed near-isometric spectrum NS targets
2. The aspect ratio correction `max(1, rows/cols)**0.5` applied post-NS — this scales magnitude upward for tall matrices but doesn't fix RMS
3. Stochastic gradient magnitude at each step

The result is that post-NS update matrices have variable per-layer RMS across steps and across layers. The `lr` parameter must absorb all of this variance. Adding `update_rms_target > 0` replaces the implicit per-layer effective scale with an explicit one: the LR then purely controls the size of the step relative to a predictable update norm.

This is the Muon analogue of LARS/LAMB per-layer normalization for SGD/Adam: decouple update direction (handled by NS orthogonalization) from update magnitude (handled by RMS normalization). Both LARS and LAMB showed that this decoupling improves training stability and allows better LR transfer across layers, models, and batch sizes.

The same normalization should be applied in `soap_ns_step` for consistency — SOAP routes all body weights through its own NS step and the same scale ambiguity applies.

---

## Code changes required

**1. Modify `muon_update` (lines 491-496 in `train_gpt_simple.py`):**

```python
@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True, update_rms_target=0.0):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    update = zeropower_via_newtonschulz5(update)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    if update_rms_target > 0:
        current_rms = update.float().square().mean().sqrt().clamp_min(1e-8)
        update = update * (update_rms_target / current_rms)
    return update
```

**2. Modify `soap_ns_step` (lines 499-503):**

```python
@torch.compile
def soap_ns_step(nesterov_update, update_rms_target=0.0):
    update = zeropower_via_newtonschulz5(nesterov_update)
    update *= max(1, nesterov_update.size(-2) / nesterov_update.size(-1))**0.5
    if update_rms_target > 0:
        current_rms = update.float().square().mean().sqrt().clamp_min(1e-8)
        update = update * (update_rms_target / current_rms)
    return update
```

**3. Add argument to `parse_args()`:**

```python
parser.add_argument("--muon_update_rms_target", type=float, default=0.0,
    help="If >0, normalize post-NS Muon/SOAP update to this target RMS per matrix. 0=disabled (default).")
```

**4. Thread `args.muon_update_rms_target` through:**
- `Muon.__init__` stores it as `self.update_rms_target`
- Pass to `muon_update(...)` and `soap_ns_step(...)` calls inside `Muon.step()`

Note: `@torch.compile` on `muon_update` means `update_rms_target` must be a compile-time constant (passed as a Python float, not a tensor). The `if update_rms_target > 0:` branch will be compiled away in the `0.0` (control) case, adding zero overhead to the baseline.

---

## 5-cell sweep design

All cells use baseline flags: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03`
All cells: `--num_trials 1 --train_steps 3250`

| Cell | `--muon_update_rms_target` | Purpose |
|------|---------------------------|---------|
| A    | 0.0 (disabled, ctrl)       | Confirms baseline still holds; establishes σ reference |
| B    | 0.25                       | Weak normalization — tests if even mild scale-fixing helps |
| C    | 0.50                       | Moderate normalization — expected interior optimum region |
| D    | 1.00                       | Normalize to unit RMS — most principled / theoretically motivated |
| E    | 2.00                       | Strong normalization — tests upper bound; should require LR retune |

**Expected ranking if mechanism is alive:** C or D < B < A < E (interior optimum between 0.25–1.00; Cell E may diverge or stall due to large effective step sizes without LR compensation)

**LR note:** Cell E with `rms_target=2.0` effectively doubles the update magnitude relative to Cell D. This may require `lr_mlp` reduction for numerical stability. If Cell E diverges, it is informative (not a run failure) — it confirms the mechanism is alive and the optimum is below 2.0.

---

## What each cell falsifies

- **Cell B (0.25) beats A:** Scale normalization helps even weakly; NS output magnitude is not already well-calibrated at the current baseline LR
- **Cell C (0.50) beats B:** Interior optimum above 0.25; moderate normalization is better than weak
- **Cell D (1.00) beats C:** Unit RMS is the optimum; theoretical prior (LARS/LAMB) holds in this setting
- **Cell C beats D:** Optimum is at 0.50 (not unit); NS output has some useful scale structure the normalization destroys when targeting 1.0
- **All B/C/D beat A:** The open axis is real; RMS normalization strictly helps the Muon step
- **A beats all:** The mechanism is dead; NS output magnitude is already effectively calibrated, or the baseline LR has implicitly absorbed all scale variance

---

## Orthogonality to closed and in-flight axes

**vs. in-flight experiments (must not duplicate):**

- **#699 depth-aware μP init (alphonse):** Init magnitude of residual-proj weights. That affects initial gradient statistics; this normalizes the already-computed post-NS update at every step regardless of init.
- **#706 embed init (nezuko):** Init of embedding weights. Affects Adam-updated params, not Muon-updated ones. Zero overlap.
- **#714 RMSNorm gain init (edward):** Init of scalar gains. Affects AdamW-updated scalars, not Muon body weights.
- **#748 Q/K/V + MLP fc_in init magnitude (frieren):** Init of the weights whose gradients feed into Muon. RMS normalization operates on the post-NS *update*, not the parameter or gradient values at init.
- **#756 gradient centralization on Muon body (tanjiro):** Subtracts row/column mean from raw `p.grad` *before* it enters the NS computation. This experiment normalizes the *output* of NS, after GC (if enabled) would have acted. The two form an ordered pipeline: GC → NS → RMS normalization. Orthogonal.
- **#773 signal-driven adaptive Muon mu (frieren):** Adjusts the global momentum scalar based on gradient cosine similarity. This is a direction-selection mechanism that changes which nesterov blend enters NS. RMS normalization then acts on whatever NS produces from that blend. Orthogonal.
- **#691 per-group AdamW β1:** Affects Adam embed/scalars/lm_head groups only, not Muon.

**vs. closed axes:**

- **NS_iter (#461/#497/#665):** NS_iter controls quality/convergence of the spectral orthogonalization. RMS normalization acts on the scale of the output, not the convergence of the iteration. Orthogonal by layer of abstraction.
- **AGC (#283):** AGC clips raw gradients before they enter momentum accumulation; this normalizes the post-NS output. Different pipeline stage, different signal (raw gradient magnitude vs. update matrix RMS).
- **Per-block LR (#648):** Those experiments apply static LR multipliers per depth layer. RMS normalization is a dynamic per-step per-matrix normalization applied before the LR multiply. They commute algebraically but test different hypotheses (depth-sensitivity vs. scale-invariance).
- **Muon mu schedule (#693, closed clean-NEG):** Momentum schedule modulates direction averaging; this modulates magnitude post-NS.
- **SOAP params (trust_threshold, precond_freq, β2):** Those tune SOAP's internal preconditioner. RMS normalization operates on SOAP's final NS output, after all SOAP internal updates.
- **AdamW kernels (Lion, Lookahead, AdEMAMix, etc.):** All affect the Adam path (embed, lm_head, scalars). Zero overlap with Muon body updates.

---

## Predicted mechanism if it works

The post-NS update matrix RMS currently varies across steps in a correlated way with gradient magnitude. When loss is high (early training), gradients are large, the pre-NS input has higher norm, and the output (after normalization clamp) has higher RMS. When gradients are small (late training or near convergence), output RMS drops. This creates implicit LR warmup/cooldown coupling between gradient scale and effective step size — but the current LR schedule is separate and cannot compensate perfectly.

RMS normalization decouples these, making the LR schedule purely a schedule (not schedule × implicit-scale-schedule). This should improve late-training convergence (the cooldown phase can actually hit its intended step size) and reduce the sensitivity of optimal LR to gradient scale drift during training.

---

## Failure modes and stop conditions

- **All cells cluster within 0.1σ of Cell A:** The mechanism is dead in this stack. The NS output is already well-calibrated enough that explicit normalization adds no information. Close clean-NEG.
- **Cell E only fails, B/C/D cluster near A:** Weak evidence. The optimal rms_target may be near 0 (i.e., the current implicit scale is near-optimal for the baseline LR). Close with note that rms_target < 0.25 region unexplored.
- **All cells diverge (loss NaN/inf):** Implementation bug — check bfloat16 clamp, check that `update.float()` cast is correct before norm, check `clamp_min(1e-8)` is present.
- **Gate met (any cell ≤ 3.261265):** Proceed to P2 n=4 confirmation at the winning rms_target value. Gate: μ_n=4 ≤ 3.261265 → merge; μ > 3.262 → close clean-NEUTRAL.

---

## Launch command (per cell)

```bash
# Cell A (control)
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/muon-rms-norm-A-ctrl" \
  --wandb_group "muon-update-rms-norm" \
  --num_trials 1 --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 \
  --muon_update_rms_target 0.0

# Cell B
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/muon-rms-norm-B-0p25" \
  --wandb_group "muon-update-rms-norm" \
  --num_trials 1 --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 \
  --muon_update_rms_target 0.25

# Cell C
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/muon-rms-norm-C-0p50" \
  --wandb_group "muon-update-rms-norm" \
  --num_trials 1 --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 \
  --muon_update_rms_target 0.50

# Cell D
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/muon-rms-norm-D-1p00" \
  --wandb_group "muon-update-rms-norm" \
  --num_trials 1 --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 \
  --muon_update_rms_target 1.00

# Cell E
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --wandb_name "askeladd/muon-rms-norm-E-2p00" \
  --wandb_group "muon-update-rms-norm" \
  --num_trials 1 --train_steps 3250 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 \
  --muon_update_rms_target 2.00
```

---

## Statistical gate

- **P1 merge trigger:** Any single cell ≤ 3.261265 (current n=4 gate μ < 3.261265)
- **P2 confirmation:** Run winning cell with `--num_trials 4`, pre-declared step count 3250. Gate: `(3.28 - mu_4) * sqrt(4) >= 0.004` → `mu_4 ≤ 3.278`; for merge claim: `mu_4 ≤ 3.261265`
- **Baseline to beat:** PR #571 baseline μ=3.263265, σ=0.001123, n=4

---

## Taste rubric

**Research mode:** Diagnostic / frontier refinement — tests a specific untested axis (output scale of NS) at the current frontier.

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| Mechanistic grounding | 3 | Mechanism is precise: NS output scale is uncontrolled, RMS normalization fixes it. Analogy to LARS/LAMB is well-established. Directly tied to code (lines 491-503). |
| Research-state value | 3 | Either confirms NS output scale is already well-calibrated (closes axis) or surfaces a new degree of freedom. Either outcome is interpretable. |
| Execution value | 3 | Cheap (5 × 3250-step single-seed runs). Implementation is minimal (6 lines of code). No LR retune needed for cells A–D; Cell E is informative as a boundary probe. |

**Confidence:** Moderate. The LARS/LAMB analogy is strong but those target SGD/Adam, not an orthogonalization-based update. The NS output scale may already be well-calibrated by the aspect-ratio correction and gradient magnitude, making this a clean negative. Even a clean negative is useful: it closes the output-scale axis and confirms the baseline LR is optimally set relative to NS output statistics.
