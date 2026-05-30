# Research Hypothesis: gradient-centralization
## Generated: 2026-05-30 — for student g1r5-fern

---

## Slug
`gradient-centralization`

## One-sentence summary
Test whether subtracting the per-block gradient mean (gradient centralization, Yong et al. 2020) before the NS orthogonalization step reduces FFS by removing the DC component of gradients that Muon's singular-value normalization does not address.

---

## Hypothesis

### Problem statement

Muon applies Newton-Schulz orthogonalization (NS5, 6 iterations) to the gradient matrix before computing the parameter update. NS orthogonalization acts on the singular values of the gradient — it pushes the update toward an orthogonal matrix (equal singular values, near-unit Frobenius norm). What NS does NOT do is zero the mean of the gradient tensor. If a gradient block has a large mean (a "DC component"), NS will faithfully orthogonalize that gradient, including the mean-direction bias. The resulting update inherits this DC drift, introducing a systematic directional bias across training steps that neither NS nor Nesterov momentum corrects.

Gradient Centralization (GC, Yong et al. 2020, ECCV 2020) proposes a simple preprocessing step: subtract the mean along the output dimension of each gradient tensor before applying the optimizer. For a weight matrix W of shape [n_out, n_in], GC computes:

    g_centralized = g - mean(g, dim=0, keepdim=True)

This removes the "DC component" — the component of the gradient that is identical across all output features. The intuition is that the mean direction represents a bias shared by all outputs, which conflates the gradient signal for individual neurons and may cause correlated parameter drift. By zeroing this shared component, each output neuron's gradient becomes zero-mean across the input dimension, encouraging more diverse parameter updates.

GC is complementary to NS orthogonalization: NS acts on singular values (spectral structure), GC acts on the mean (translational structure). The two are structurally orthogonal. Applying GC before NS means NS operates on an already mean-centered gradient, potentially producing a cleaner orthogonalization.

### Why this is structurally distinct from all closed axes

- **Closed polar-approximator family**: NS5/Padé/Higham/Cayley/Schulz all act on the singular value structure of the gradient. GC acts on the mean, a different structural property.
- **Closed per-head/per-shape NS reshape (#1821, #1839)**: These restructure the gradient matrix before NS. GC is a preprocessing step that modifies gradient values, not shape.
- **Closed μ schedule axes (#1720, cooldown family, #1880 in-flight)**: Momentum schedule, not gradient preprocessing.
- **Closed WD/LR axes**: Regularization and learning rate, not gradient transformation.
- **In-flight #1880 (tanjiro, Muon μ cooldown)**: Momentum schedule, completely orthogonal to gradient preprocessing.

GC is a genuinely new mechanism in this research program. It has NOT been tested in any closed or in-flight PR.

### Mechanism and expected observable

**Causal hypothesis**: The gradient matrices feeding Muon's NS step have a non-zero mean component that encodes a shared bias direction across all output channels. This shared direction does not distinguish between individual neurons and may cause correlated drift in the update direction across training steps. Removing it (GC) before NS allows the orthogonalization to operate on a more informative "AC component" of the gradient, producing updates that are more diverse across output neurons and better exploit the representational capacity of the model.

**Expected observable**: If the hypothesis is correct:
1. Gradient norms before and after GC should differ noticeably early in training (mean component is large relative to AC component in early training, less so late).
2. The val/loss trajectory should cross 3.28 at a strictly earlier step (lower FFS).
3. MLP layers are expected to benefit more than attention layers, since MLP matrices have larger output dimensions and the mean-removal operates over a more meaningful axis.

**Falsifying result**: If GC and control show identical FFS_ema (within 25 steps), the DC component is not load-bearing in this stack — either Muon's NS already implicitly suppresses mean drift, or the mean component is negligibly small in practice. Inspect gradient mean norms in W&B; if they are near zero throughout training, GC has nothing to remove.

### Why this might actually help

Four lines of support:

1. **Original GC paper (Yong et al. 2020)**: Demonstrated FFS-equivalent improvements in image classification and object detection on ResNets trained with SGD and Adam. The mechanism is well-validated in standard deep learning settings. The question is whether it transfers to transformer + orthogonalized optimizer.

2. **Structural complement to NS**: NS orthogonalization preserves the direction of any component that has unit singular value — including the mean. GC zeroes the mean before NS sees the gradient, so NS cannot amplify a shared-direction bias into the update. This is not a redundant operation.

3. **Muon updates are "DC-blind"**: By construction, Muon applies an isometric update (orthogonal matrix times a scalar). If the input gradient to NS has a large mean, the orthogonal output inherits that bias at the singular-value level. GC prevents this leakage.

4. **Cost is minimal**: GC is ~5 lines of code applied inside the Muon optimizer step, before the NS call. No additional forward or backward pass. Wall-clock overhead is negligible (one mean() and subtraction per gradient block).

### Structural risk

The main risk is that gradient means in the current stack are already near-zero. Muon's Frobenius pre-normalization divides the gradient by its Frobenius norm — this reduces the magnitude of the mean but does NOT zero it. If the mean direction is small relative to the total gradient energy, GC's effect will be below the noise floor. This is empirically testable by logging `train/grad_mean_norm` for each layer in the smoke run.

Secondary risk: GC may interact with the SOAP attention optimizer. SOAP uses a different preconditioner (Kronecker-factored eigenbasis); applying GC to attention gradients before SOAP's Kronecker factorization is a less-motivated extension. The hypothesis should be tested with GC on MLP groups only first, as a cleaner probe of the mechanism.

---

## Implementation

### Required code changes

The student must add GC as a preprocessing step inside the Muon optimizer, before the NS orthogonalization call. Changes are localized to ~15-20 lines:

1. **Add CLI flag** (in argument parsing section):
   ```python
   parser.add_argument('--grad_centralization', type=str, default='none',
       choices=['none', 'muon_all', 'muon_mlp_only'],
       help='Gradient centralization mode: none=disabled, muon_all=apply GC to all Muon groups, '
            'muon_mlp_only=apply GC only to MLP Muon groups')
   ```

2. **Add GC function** (near the NS helper or at the top of training script):
   ```python
   def centralize_gradient(g: torch.Tensor) -> torch.Tensor:
       """Gradient Centralization (Yong et al. 2020, ECCV).
       Subtracts the mean across all but the first (output) dimension.
       Only applied to matrices (2D+ tensors); scalars/1D tensors are skipped."""
       if g.ndim < 2:
           return g
       # Mean over all input dimensions, keeping output dim
       return g - g.mean(dim=tuple(range(1, g.ndim)), keepdim=True)
   ```

3. **Apply GC in the Muon optimizer step** (before the NS call — the exact location depends on the Muon implementation, but it will be just before `zeropower_via_newtonschulz5(g, ...)`):
   ```python
   # Inside muon.step() or equivalent, for each param group:
   if args.grad_centralization in ('muon_all', 'muon_mlp_only'):
       # For muon_mlp_only, check that this param group is MLP (not attn)
       is_mlp_group = 'mlp' in group.get('name', '') or not group.get('is_attn', False)
       if args.grad_centralization == 'muon_all' or is_mlp_group:
           g = centralize_gradient(g)
   # ... then: g = zeropower_via_newtonschulz5(g, steps=ns_iter)
   ```

4. **Add W&B logging** (in the first 20 steps, or as a periodic diagnostic):
   ```python
   # Log gradient mean norm before centralization (first 100 steps only, for diagnostics)
   if step < 100:
       for name, p in model.named_parameters():
           if p.grad is not None and p.grad.ndim >= 2:
               mean_norm = p.grad.mean(dim=tuple(range(1, p.grad.ndim)), keepdim=True).norm().item()
               wandb.log({f'diag/grad_mean_norm/{name}': mean_norm}, step=step)
   ```

### Implementation notes

- The `centralize_gradient` function must be applied BEFORE Frobenius normalization and BEFORE the NS call. Order matters: GC removes the mean from the raw gradient; Frobenius normalization then rescales the result.
- If the Muon optimizer uses a fused kernel or compiled function for NS, GC must be inserted before that call, not after.
- For `muon_mlp_only` mode, the student must identify how MLP vs. attention parameter groups are tagged in the existing optimizer group construction. Typically there is an `is_attn` flag or the group name contains 'attn'. Inspect the training script's optimizer initialization to confirm.
- SOAP handles attention parameters; GC should NOT be applied to SOAP groups. Only Muon-handled parameters are candidates for GC.
- For 1D parameters (biases, scalars), `centralize_gradient` returns the tensor unchanged (the `if g.ndim < 2: return g` guard). This is correct behavior.
- The mean is subtracted along `dim=tuple(range(1, g.ndim))`, which means across all input dimensions, preserving the output (first) dimension. This is the standard formulation from Yong et al. 2020.

---

## Sweep design

### Cell table

| Cell | grad_centralization | Description | Priority |
|------|-------------------|-------------|----------|
| A (CTRL) | none | R5 baseline, GC disabled | REQUIRED |
| B★ (primary) | muon_mlp_only | GC on MLP Muon groups only | HIGH |
| C | muon_all | GC on all Muon groups (MLP + any non-SOAP attn) | MEDIUM |
| D (diagnostic) | muon_mlp_only + log grad_mean_norm | Cell B + gradient mean norm logging | MEDIUM |

**Total recommended initial runs**: A + B + C (3 cells, n=1 each)

Cell D is a diagnostic arm: run it to determine whether gradient means are non-trivially large (grad_mean_norm > 0.01 × grad_norm). If grad_mean_norm is near zero throughout, GC has nothing to do and the mechanism is falsified regardless of FFS result. Cell D can be run in parallel with B and C.

### Baseline target

Current R5 baseline: μ_4(FFS_ema) = 2912.5, σ_4 = 25 (PR #1533)

FFS gates:
- KG_smoke gate: finite gradients, W&B logging working, GC applied (verify by checking that `diag/grad_mean_norm` is logged and non-zero for at least some layers in the first 20 steps)
- FFS-alive gate (n=1): FFS_ema ≤ 2975 AND FFS_trainval ≤ 2950
- Promote gate (n=1 → n=4): FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825
- Merge gate (n=4): μ_4(FFS_ema) ≤ 2887.5 (beats baseline by ≥25 steps)

### Dual-metric reporting requirement

All cells must report BOTH:
- `FFS_ema`: `speedrun/final_first_step_to_target` (EMA-smoothed val/loss)
- `FFS_trainval`: earliest step where raw `val/loss ≤ 3.28` (unsmoothed)

Do not promote a cell based on FFS_ema alone if FFS_trainval ≥ 2950.

---

## Execution plan

### Phase 1: KG_smoke (50-100 steps)

Run a 50-100 step smoke test of Cell B to verify code correctness:

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --grad_centralization muon_mlp_only \
  --train_steps 100 \
  --wandb_name "g1r5-fern/grad-centralization-smoke" \
  --wandb_group "fern-grad-centralization-r5"
```

KG_smoke pass criteria:
1. Finite loss at step 100 (val/loss < 3.5)
2. `diag/grad_mean_norm` logged and non-zero for at least one MLP layer in the first 20 steps
3. No NaN gradients
4. GC is visibly reducing gradient mean norms (compare `diag/grad_mean_norm` before and after — if the implementation is wrong and GC is not applied, mean norms will be unchanged)

### Phase 2: n=1 sweep (Cells A, B, C)

Run all three primary cells to full training:

**Cell A (CTRL):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --grad_centralization none \
  --wandb_name "g1r5-fern/grad-centralization-A-ctrl" \
  --wandb_group "fern-grad-centralization-r5"
```

**Cell B (primary — MLP only):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --grad_centralization muon_mlp_only \
  --wandb_name "g1r5-fern/grad-centralization-B-mlp-only" \
  --wandb_group "fern-grad-centralization-r5"
```

**Cell C (all Muon groups):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --grad_centralization muon_all \
  --wandb_name "g1r5-fern/grad-centralization-C-all-muon" \
  --wandb_group "fern-grad-centralization-r5"
```

### Phase 3: n=4 expansion (best cell only)

If exactly one cell passes the promote gate (FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825), run 3 additional seeds of that cell. If multiple cells pass, promote the one with the best FFS_trainval.

---

## Pre-mortems and stop conditions

### Pre-mortem 1: Gradient means near zero
If `diag/grad_mean_norm` < 0.001 for all MLP layers throughout training, GC has nothing to remove. Close as FFS-NEUTRAL with note: "gradient DC component negligibly small in this stack; mechanism does not apply." This is diagnosable from the smoke run alone.

### Pre-mortem 2: Effect below noise floor
If all cells B/C show FFS_ema within 25 steps of control (A) AND FFS_trainval ≥ 2925, the effect is below detectable threshold. Close as FFS-NEUTRAL.

### Pre-mortem 3: GC hurts (FFS regression)
If GC cells are worse (FFS > 2950), the mean component is informationally useful — removing it discards signal. Close as FFS-NEG with note: "gradient DC component carries optimization-relevant information in this stack."

### Stop condition
If smoke run shows grad_mean_norm near zero for all layers, close immediately — do not run full n=1 sweep. If n=1 sweep shows all cells with FFS_trainval ≥ 2925, close as FFS-NEUTRAL.

---

## Decision tree

```
Phase 0: KG_smoke (100 steps)
├─ FAIL (NaN/diverge): Fix implementation bug, re-smoke.
│   If unfixable in 1 attempt → close, notify advisor.
├─ DIAGNOSTIC: grad_mean_norm < 0.001 for ALL layers → CLOSE immediately
│   (GC has nothing to remove; mechanism falsified at diagnostic level)
└─ PASS (finite loss, grad_mean_norm > 0.001 for some layers)
    → Phase 2 (n=1 sweep, A+B+C)
        ├─ All cells: FFS_trainval ≥ 2925 AND FFS_ema ≥ 2850
        │   → CLOSE as FFS-NEUTRAL (DC component not FFS-load-bearing)
        ├─ Best cell: FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825
        │   → Phase 3 (n=4 expansion of best cell)
        │       ├─ μ_4(FFS_ema) ≤ 2887.5 → SUBMIT as WINNER (FFS-PRIMARY)
        │       └─ μ_4(FFS_ema) > 2887.5 → CLOSE as FFS-NEG (n1→n4 regression)
        └─ Borderline: FFS_trainval 2900-2925 (B better than C or vice versa)
            → Run Cell D (B config + extended grad_mean_norm logging) to confirm mechanism
                ├─ grad_mean_norm large (> 0.01) AND FFS_trainval ≤ 2900 → promote to n=4
                └─ grad_mean_norm small OR FFS_trainval ≥ 2925 → close FFS-NEUTRAL
```

---

## Research state context

- **Research programme status**: 66-closure plateau, ZERO FFS-positive merges since PR #1533. Plateau protocol active: must target genuinely new mechanisms, not scalar HP hill-climbing.
- **This hypothesis level**: Gradient preprocessing (DC component removal) — not a schedule, not an architecture change, not a singular-value manipulation. Structurally orthogonal to all closed axes.
- **Stack validity**: All R5 mandatory flags included. ns_iter=6 preserved (load-bearing per #1821). Frobenius normalization preserved (load-bearing per #1825/#1829). NS5 polynomial unchanged (post-NS polish structurally exhausted).
- **Taste score**: Mechanistic grounding = 3 (well-specified causal story, complementary to NS, direct external evidence from Yong et al. 2020, but untested in Muon+NS stack). Research-state value = 4 (either GC helps and we have a new optimization axis, or grad means are near-zero and we've structurally ruled out DC drift as a mechanism — sharply updates the research map either way). Execution value = 4 (smoke diagnostic catches near-zero grad means before full run; 3-cell sweep; ~15 LOC; no extra passes).
- **Confidence**: Moderate. The mechanism is sound and structurally open. The smoke-run diagnostic makes this a cheap, informative experiment regardless of FFS outcome.
- **Reference**: Yong, H., Huang, J., Hua, X., & Zhang, L. (2020). Gradient Centralization: A New Optimization Technique for Deep Neural Networks. ECCV 2020. https://arxiv.org/abs/2004.01461
