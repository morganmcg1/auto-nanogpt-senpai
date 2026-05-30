# Research Hypothesis: ge-sam-gradient-extrapolation
## Generated: 2026-05-30 — for student g1r5-askeladd

---

## Slug
`ge-sam-gradient-extrapolation`

## One-sentence summary
Test whether adding a scaled finite-difference Hessian-vector product estimate to each gradient step — approximating the SAM sharpness perturbation at zero extra forward/backward cost — reduces FFS by biasing Muon/SOAP updates toward flatter loss regions, where EMA-eval benefits most.

---

## Hypothesis

### Problem statement

Sharpness-Aware Minimization (SAM, Foret et al. 2021) seeks flat minima by computing the gradient at a sharpness-perturbed parameter point: `g_sam = ∇L(θ + ε·g/‖g‖)`. This requires a second forward-backward pass per step — cost doubling that is forbidden by the Track 3 contract (one forward-backward per optimizer step, fixed). However, the SAM perturbation direction is a Hessian-vector product (HVP): `∇L(θ + ε·v) ≈ ∇L(θ) + ε·H·v`. The first-order HVP estimate `H·v ≈ (∇L(θ + ε·v) - ∇L(θ)) / ε` is expensive, but a free approximation exists: consecutive gradient differences. By the finite-difference identity:

    H·g_t ≈ (g_t - g_{t-1}) / Δθ

where `Δθ = θ_t - θ_{t-1}` is the previous step update. This gives a zero-extra-pass curvature estimate. The modified gradient is:

    g_eff = g_t + α · (g_t - g_{t-1})

where `α ≥ 0` is the extrapolation coefficient. When α > 0, the update moves in the direction of the gradient PLUS its recent change — i.e., it anticipates the curvature of the loss landscape without any extra computation. This is Gradient Extrapolation SAM (GE-SAM), an approximation of the SAM perturbation direction using stored gradient history alone.

For Muon/SOAP, this matters because: (1) EMA-eval is most sensitive to sharp minima — EMA trajectory averages over a window of parameters, and sharp minima diverge from the average faster than flat ones; (2) Muon's NS orthogonalization amplifies update directions without distinguishing flat from sharp dimensions; (3) the current 67-PR plateau suggests the optimizer is well-converged in its current attractor but may be stuck in a slightly-too-sharp local minimum reachable by a curvature-aware nudge.

### Why this is structurally distinct from all closed axes

- **Closed polar-approximator family (NS5/Padé/Higham/Cayley/Schulz)**: These all modify HOW NS computes the approximate polar factor from the gradient — they act on the singular-value representation of a single gradient tensor. GE-SAM modifies WHICH gradient enters NS by incorporating cross-step curvature information. The operation precedes NS entirely.
- **Closed μ schedule axes (#1880 tanjiro in-flight)**: Muon momentum coefficient schedule. GE-SAM does not touch µ; it modifies the raw gradient before momentum accumulation begins.
- **Closed WD/LR scalar HP axes**: Regularization and step-size scaling. GE-SAM is a gradient transformation, not a scalar multiplier on the update.
- **Closed init axes (4/4)**: Weight/momentum buffer initialization. GE-SAM is applied at every step; it uses gradient state, not parameter initialization.
- **In-flight #1885 (fern, gradient centralization)**: GC subtracts the mean of the gradient (DC removal). GE-SAM adds a forward-difference curvature term — these are linearly independent additive modifications to the gradient and commute in principle. GE-SAM is not a mean-subtraction.
- **In-flight #1860 (alphonse, SOAP-attn cooldown gate)**: A phase-gating mechanism for SOAP's eigenbasis update frequency. Orthogonal to gradient computation.
- **In-flight #1858 (edward, Schulz polish on square attn)**: Post-NS polish, modifies the output of NS. GE-SAM modifies the input to NS.
- **Spectral-norm pre-NS scaling (#1829, closed)**: A scalar per-matrix rescaling before NS. GE-SAM is a cross-step additive perturbation, not a scalar.

GE-SAM has NOT been tested in any closed or in-flight PR in this programme. It operates on the gradient history dimension, which is a structurally new axis.

### Mechanism and expected observable

**Causal hypothesis**: The current R5 Muon+SOAP optimizer converges to a well-characterized local minimum (stable FFS around 2912) but has no curvature-awareness at the gradient level. The loss Hessian has sharp directions (low-sensitivity eigenvectors of flat minima are exponentially easier for EMA-eval to exploit). By adding `α·(g_t - g_{t-1})` to each gradient before SOAP preconditioning and NS orthogonalization, the effective gradient includes a first-order HVP estimate pointing away from curvature-amplified directions. This biases the optimizer toward flatter descent directions within each step, improving the EMA-eval quality of the converged point.

**Expected observable**: If the hypothesis is correct:
1. Early training (steps < 500): g_eff and g_t should diverge visibly in direction; log cosine similarity `diag/ge_sam_cos_sim` between `g_t` and `g_t - g_{t-1}`. If they are near-orthogonal, extrapolation adds maximal new information. If near-parallel, the momentum term is already capturing this.
2. Mid training (steps 1000–2500): val/loss should cross 3.28 strictly earlier than control — the optimizer reaching the flat-basin attractor faster because it is avoiding sharp attractors.
3. EMA-eval should benefit disproportionately vs raw val/loss: flat-minima EMA averaging gains are well-documented (Izmailov et al. 2018 SWA; Wilson et al. 2017).

**Falsifying result**: If FFS_ema and FFS_trainval are both within 25 steps of control for all α values tested, the finite-difference HVP term is either too noisy (consecutive gradients are near-uncorrelated in this setting), or the curvature-aware direction is already captured by Nesterov momentum (mu=0.95 already provides lookahead). Check `diag/ge_sam_cos_sim`: if it is < 0.05 throughout training, gradient directions are too uncorrelated for the HVP approximation to be meaningful — close with that diagnostic as evidence.

### Why this might actually help

Four lines of support:

1. **SAM's flat-minima benefit is empirically robust, especially for EMA-based eval**: Foret et al. 2021 and subsequent work (Du et al. 2022 Efficient SAM; Zhuang et al. 2022 Surrogate Gap) show consistent generalization improvement across settings. The EMA-eval in Track 3 (`ema_eval_decay=0.99`) is precisely the evaluation regime where flat-minima optimization is most beneficial — EMA averaging drifts away from sharp minima faster than from flat ones, so converging to a flatter basin should directly improve FFS_ema.

2. **Zero-cost HVP via gradient differences is theoretically grounded**: The finite difference `(g_t - g_{t-1}) / h` converges to `H·Δθ_{t-1}` as `h → 0`. For fixed learning rate and bounded gradients, this approximates the true curvature direction. Liu et al. 2022 (GSAM — Surrogate Gap Guided SAM) and Andriushchenko & Flammarion 2022 both analyze the regime where approximate HVP is sufficient — they find the direction matters more than the magnitude. GE-SAM gets the direction right (gradient difference) at zero compute cost.

3. **Nesterov momentum is NOT equivalent**: Muon uses Nesterov correction `g_eff = g_t.lerp(momentum, mu)` which is a weighted average of current gradient and momentum buffer. This is a different operation from `g_t + α·(g_t - g_{t-1})`. The Nesterov term blends past gradients; GE-SAM amplifies the CHANGE in gradient direction, which is a curvature signal. At `mu=0.95`, Nesterov smooths away the curvature signal; GE-SAM reinstates it after momentum.

4. **SOAP preconditioning benefits from curvature-aligned inputs**: SOAP's Kronecker-factored eigenbasis aligns with the Hessian structure. Feeding a curvature-aware gradient into SOAP means the preconditioner and the input gradient have aligned curvature information — the preconditioner should achieve its target (whitening the gradient in Hessian eigenbasis) more accurately when the input gradient already contains Hessian-aligned signal.

### Structural risk

**Risk 1 — gradient noise dominance**: Consecutive minibatch gradients are stochastic. The difference `g_t - g_{t-1}` mixes true curvature signal with noise from minibatch variance. For small batch sizes, noise dominates and the HVP estimate is garbage. Track 3 uses a fixed batch schedule (B=512 with gradient accumulation — verify exact effective batch); if the batch is large enough, gradient variance is low enough for the finite difference to be meaningful. The smoke run's `diag/ge_sam_cos_sim` diagnostic will reveal this immediately.

**Risk 2 — interaction with SOAP's eigenbasis update**: SOAP updates its Kronecker-factored preconditioner using the raw gradient (not g_eff). If GE-SAM only modifies the gradient used for the momentum update but not the preconditioner update, the preconditioner may not align with the curvature-aware gradient. Implementation must verify: does `soap_update_preconditioner(p.grad, state)` (line 668) use the original p.grad or g_eff? It uses `p.grad` — so the preconditioner update is unmodified. This is actually correct: we want the preconditioner to track the raw gradient distribution, while the momentum path uses the curvature-aware g_eff.

**Risk 3 — interaction with Muon's Frobenius normalization in NS**: NS5 normalizes by `‖G‖_F` before polynomial iteration. GE-SAM scales g_eff up by `(1 + α)` roughly. This means NS sees a larger-magnitude input, but Frobenius normalization cancels this. The direction of the input changes (curvature-aware), but normalization ensures magnitude does not diverge.

---

## Implementation

### Required code changes

The student must implement GE-SAM as a gradient preprocessing step inside `Muon.step()` in `records/track_3_optimization/train_gpt_simple.py`. Changes are localized to approximately 20–25 LOC.

**1. Add CLI flag** (argument parsing section, ~line 100):
```python
parser.add_argument('--ge_sam_alpha', type=float, default=0.0,
    help='GE-SAM gradient extrapolation coefficient. 0 = disabled. '
         'Effective gradient: g_eff = g + alpha*(g - g_prev). '
         'Recommended range: 0.02–0.15.')
```

**2. Add state initialization** (inside `Muon.step()`, in the `if len(state) == 0:` block, ~line 645):
```python
if len(state) == 0:
    state["momentum"] = torch.zeros_like(p)
    state["prev_raw_grad"] = None   # GE-SAM: stores g_{t-1} for HVP estimate
    if use_soap:
        ...  # existing SOAP state init unchanged
```

**3. Apply GE-SAM before the SOAP momentum path** (inside `Muon.step()`, ~line 654, before momentum lerp):

The critical implementation detail is that with `--soap_attn` (mandatory R5 flag), ALL block 2D weights (MLP fc, MLP proj, AND attn qkv/proj) are in `self.soap_params`. The non-SOAP path at line 670 is NOT reached for any block 2D param in the R5 config. GE-SAM must therefore be inserted in the SOAP path, modifying `p.grad` before `state["momentum"].lerp_(p.grad, ...)`:

```python
if use_soap:
    # --- GE-SAM: apply gradient extrapolation before SOAP momentum update ---
    if group.get("ge_sam_alpha", 0.0) > 0.0 and state["prev_raw_grad"] is not None:
        delta = p.grad.sub(state["prev_raw_grad"])
        p.grad = p.grad.add(delta, alpha=group["ge_sam_alpha"])
    # Store raw gradient AFTER reading, BEFORE momentum (use clone to avoid aliasing)
    state["prev_raw_grad"] = p.grad.detach().clone()
    # --- end GE-SAM ---
    state["momentum"].lerp_(p.grad, 1 - group["mu"])
    raw_nesterov = p.grad.lerp(state["momentum"], group["mu"])
    precond_nesterov = soap_precondition_momentum(raw_nesterov, state)
    ...  # rest of SOAP path unchanged
```

Note: `soap_update_preconditioner(p.grad, state)` at line 668 uses `p.grad` for preconditioner statistics. After GE-SAM modifies `p.grad`, the preconditioner receives the curvature-aware gradient. Whether this is desirable is an open question — variant D tests preconditioner-bypass. For the primary cell, this is fine: the preconditioner adaptation is robust to small directional perturbations.

**4. Add optimizer group pass-through** (in optimizer group construction, ~lines 861–877):
```python
# When constructing the Muon optimizer, add ge_sam_alpha to each group:
muon = Muon(
    mlp_named + attn_named,
    lr=args.lr_mlp, mu=args.mu, weight_decay=args.wd,
    ge_sam_alpha=args.ge_sam_alpha,  # pass through
    ...
)
# The Muon.__init__ must accept and store ge_sam_alpha in each param group.
# Add to Muon.__init__ param_groups defaults:
#   group["ge_sam_alpha"] = ge_sam_alpha
```

**5. Add W&B diagnostic logging** (inside `Muon.step()`, conditioned on step < 200):
```python
# Log GE-SAM diagnostics: cosine similarity between g_t and delta = g_t - g_{t-1}
if group.get("ge_sam_alpha", 0.0) > 0.0 and state["prev_raw_grad"] is not None:
    g_flat = p.grad.float().view(-1)
    delta_flat = (p.grad - state["prev_raw_grad"]).float().view(-1)
    cos_sim = (g_flat @ delta_flat) / (g_flat.norm() * delta_flat.norm() + 1e-8)
    self.ge_sam_cos_sims_buffer[self.param_names[id(p)]] = cos_sim.item()
```
Then log `diag/ge_sam_cos_sim_mean` as the mean across all SOAP params in the training loop.

### Implementation notes

- **CRITICAL — p.grad aliasing**: After `p.grad = p.grad.add(delta, alpha=alpha)`, the tensor stored in `p.grad` is a new tensor. Subsequent reads of `p.grad` within the same step (including `soap_update_preconditioner`) will see the modified gradient. This is intentional for the primary hypothesis but creates a variant: "GE-SAM on momentum path only, raw grad for preconditioner." Implement variant D by storing the original `p.grad` before modification and passing it explicitly to `soap_update_preconditioner`.
- **Memory**: Storing `state["prev_raw_grad"]` adds one gradient-sized buffer per parameter — same memory footprint as the momentum buffer. This is acceptable for one GPU / 12-layer GPT.
- **Step 0 guard**: At step 0, `state["prev_raw_grad"] is None`. GE-SAM skips and acts as identity for the first step only. This is correct.
- **Non-SOAP path (line 670)**: With `--soap_attn`, this path is not reached for any block 2D param. But for completeness (and correctness if `soap_attn` is ever disabled), GE-SAM should also be applied before `muon_update(p.grad, state["momentum"], ...)` with the same p.grad modification pattern. The `muon_update` function is `@torch.compile` — modifying `p.grad` BEFORE calling it (not inside) avoids recompilation.
- **α sensitivity**: Based on GE-SAM analogues in the literature (GSAM, LookSAM), α in [0.02, 0.15] is the empirically productive range. α > 0.3 tends to amplify noise. Test α=0.05 as primary.
- **Do NOT modify `zeropower_via_newtonschulz5` or `muon_update`**: GE-SAM operates upstream of NS, not inside it. Keeping NS untouched preserves the existing `@torch.compile` optimization.

---

## Sweep design

### Cell table

| Cell | ge_sam_alpha | Description | Priority |
|------|-------------|-------------|----------|
| A (CTRL) | 0.0 | R5 baseline, GE-SAM disabled | REQUIRED |
| B★ (primary) | 0.05 | GE-SAM α=0.05, SOAP path only | HIGH |
| C | 0.02 | GE-SAM α=0.02, lower extrapolation | MEDIUM |
| D | 0.10 | GE-SAM α=0.10, higher extrapolation | MEDIUM |

**Total recommended initial runs**: A + B + C + D (4 cells, n=1 each). Cell B★ is the primary bet; C and D bracket it from below and above.

### Baseline target

Current R5 baseline: μ_4(FFS_ema) = 2912.5, σ_4 = 25 (PR #1533, last merged winner)

FFS gates:
- **KG_smoke gate**: Finite gradients at step 100 (val/loss < 3.5); `diag/ge_sam_cos_sim_mean` is logged and > 0.05 (confirming gradient changes are not random noise); no NaN gradients or optimizer state.
- **FFS-alive gate** (n=1): FFS_ema ≤ 2975 AND FFS_trainval ≤ 2950
- **Promote gate** (n=1 → n=4): FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825
- **Merge gate** (n=4): μ_4(FFS_ema) ≤ 2887.5 (beats baseline by ≥ 25 steps)

### Dual-metric reporting requirement

All cells must report BOTH:
- `FFS_ema`: `speedrun/final_first_step_to_target` (EMA-smoothed val/loss)
- `FFS_trainval`: earliest step where raw `val/loss ≤ 3.28` (unsmoothed)

Do not promote a cell based on FFS_ema alone if FFS_trainval ≥ 2950.

---

## Execution plan

### Phase 1: KG_smoke (100 steps)

Run a 100-step smoke test of Cell B★ to verify code correctness and diagnostic logging:

```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --ge_sam_alpha 0.05 \
  --train_steps 100 \
  --wandb_name "g1r5-askeladd/ge-sam-smoke" \
  --wandb_group "askeladd-ge-sam-r5"
```

KG_smoke pass criteria:
1. Finite loss at step 100 (val/loss < 3.5)
2. `diag/ge_sam_cos_sim_mean` is logged and > 0.05 in the first 100 steps (confirms gradient changes carry curvature signal, not pure noise)
3. No NaN gradients in any parameter group
4. `state["prev_raw_grad"]` is non-None after step 1 (implementation sanity)

### Phase 2: n=1 sweep (Cells A, B★, C, D)

Run all four primary cells to full training:

**Cell A (CTRL):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --ge_sam_alpha 0.0 \
  --wandb_name "g1r5-askeladd/ge-sam-A-ctrl" \
  --wandb_group "askeladd-ge-sam-r5"
```

**Cell B★ (primary — α=0.05):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --ge_sam_alpha 0.05 \
  --wandb_name "g1r5-askeladd/ge-sam-B-alpha005" \
  --wandb_group "askeladd-ge-sam-r5"
```

**Cell C (α=0.02):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --ge_sam_alpha 0.02 \
  --wandb_name "g1r5-askeladd/ge-sam-C-alpha002" \
  --wandb_group "askeladd-ge-sam-r5"
```

**Cell D (α=0.10):**
```bash
torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  records/track_3_optimization/train_gpt_simple.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --ge_sam_alpha 0.10 \
  --wandb_name "g1r5-askeladd/ge-sam-D-alpha010" \
  --wandb_group "askeladd-ge-sam-r5"
```

### Phase 3: n=4 expansion (best cell only)

If exactly one cell passes the promote gate (FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825), run 3 additional seeds of that cell. If multiple cells pass, promote the one with the best FFS_trainval. If a non-primary α wins, also note whether a finer α search (e.g., midpoint between B and D) is warranted before n=4.

---

## Pre-mortems and stop conditions

### Pre-mortem 1: Cosine similarity near zero (gradient noise dominates)
If `diag/ge_sam_cos_sim_mean` < 0.05 throughout the smoke run, consecutive minibatch gradients are near-orthogonal — the finite-difference approximation is pure noise. The HVP estimate is garbage in this regime. Close immediately as FFS-NEUTRAL with note: "Consecutive gradient directions uncorrelated in this batch regime; GE-SAM HVP estimate is noise; mechanism does not apply." This is diagnosable from the 100-step smoke run.

### Pre-mortem 2: Effect below noise floor
If all cells B/C/D show FFS_ema within 25 steps of control (A) AND FFS_trainval ≥ 2925, the effect is below detectable threshold even if `ge_sam_cos_sim_mean` was healthy. Close as FFS-NEUTRAL with note: "Curvature signal present but FFS-inert; extrapolation direction not FFS-load-bearing in current stack."

### Pre-mortem 3: Regression at all α values (GE-SAM hurts)
If all cells B/C/D are worse (FFS_ema > 2950), the curvature-aware gradient perturbation is moving the optimizer away from the attractor basin of the current configuration. This may indicate the current basin IS the flattest reachable one, or that the finite-difference HVP is pointing in the wrong direction (anti-correlated with true curvature). Close as FFS-NEG.

### Pre-mortem 4: α=0.10 best, suggests larger α needed
If Cell D (α=0.10) is clearly best but FFS_trainval is borderline (2900–2920), consider a Cell E at α=0.20 before committing to n=4. Large α implies a stronger curvature signal — the mechanism is alive but needs a larger nudge.

### Stop condition
If smoke run fails KG_smoke gate (gradient noise diagnosis), close immediately. If n=1 sweep shows all cells with FFS_trainval ≥ 2925, close as FFS-NEUTRAL.

---

## Decision tree

```
Phase 0: KG_smoke (100 steps, Cell B★ only)
├─ FAIL (NaN/diverge): Fix implementation bug. If unfixable in 1 attempt → close.
├─ DIAGNOSTIC: ge_sam_cos_sim_mean < 0.05 throughout
│   → CLOSE immediately (gradient directions near-orthogonal; HVP estimate is noise)
└─ PASS (finite loss, ge_sam_cos_sim_mean > 0.05)
    → Phase 2: n=1 sweep (A, B★, C, D), full training
        ├─ All cells: FFS_trainval ≥ 2925 AND FFS_ema ≥ 2850
        │   → CLOSE as FFS-NEUTRAL (curvature term not FFS-load-bearing)
        ├─ At least one cell: FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825
        │   → Identify best cell (lowest FFS_trainval)
        │   → Phase 3: n=4 expansion of best cell
        │       ├─ μ_4(FFS_ema) ≤ 2887.5 → SUBMIT as WINNER (FFS-PRIMARY)
        │       └─ μ_4(FFS_ema) > 2887.5 → CLOSE as FFS-NEG (n1→n4 regression)
        ├─ Borderline: best cell FFS_trainval 2900–2920
        │   ├─ If best cell is D (α=0.10): run Cell E at α=0.20 before n=4
        │   │   ├─ Cell E FFS_trainval ≤ 2900 → expand E to n=4
        │   │   └─ Cell E FFS_trainval ≥ 2920 → close FFS-NEUTRAL
        │   └─ If best cell is B or C: promote to n=4 (borderline is within shot)
        │       └─ Apply μ_4 merge gate
        └─ Regression: all cells FFS_ema > 2950
            → CLOSE as FFS-NEG (mechanism hurts in current stack)
```

---

## Research state context

- **Research programme status**: 67-closure plateau (per commit log), ZERO FFS-positive merges since PR #1533. Plateau protocol active: must target genuinely new mechanisms, not scalar HP hill-climbing.
- **This hypothesis level**: Cross-step curvature injection (SAM approximation via gradient finite difference) — not a schedule, not a singular-value manipulation, not a mean subtraction, not an initialization scheme. Structurally orthogonal to all 67 closed axes and all 7 in-flight assignments.
- **Stack validity**: All R5 mandatory flags included verbatim. `ns_iter 6` preserved. `soap_attn` preserved (critical: means GE-SAM must target the SOAP code path at lines 654–668, not the non-SOAP path at line 670). `ema_eval_decay 0.99` preserved (directly relevant — flat-minima hypothesis targets EMA-eval improvement).
- **Implementation surface**: `train_gpt_simple.py`, lines 645–668 (state init + SOAP momentum path). ~20–25 LOC. No changes to NS5, `muon_update`, SOAP preconditioner structure, or model architecture.
- **Taste score**:
  - Mechanistic grounding = 4 (precise mechanism: finite-difference HVP approximates SAM perturbation; direct link to EMA-eval flat-minima benefit; specific code insertion point identified; no collisions with closed axes).
  - Research-state value = 4 (smoke diagnostic resolves noise-dominance question cheaply; either the HVP is correlated and we have a new axis, or it is noise and we rule out curvature-aware gradient injection as a mechanism — either result sharply updates the map).
  - Execution value = 3 (4-cell sweep is slightly heavier than 3-cell, but α-bracketing is needed for a continuous HP; smoke run resolves the noise question before full training cost).
- **Confidence**: Moderate-to-high on mechanism, moderate on magnitude. SAM's flat-minima benefit is robust across settings; whether the finite-difference approximation is accurate enough in the current batch+optimizer regime is the primary empirical uncertainty. The smoke diagnostic answers the key mechanistic question (correlated vs. noise) before spending full training budget.
- **Key references**:
  - Foret et al. (2021). Sharpness-Aware Minimization for Efficiently Improving Generalization. ICLR 2022. https://arxiv.org/abs/2010.01412
  - Du et al. (2022). Efficient Sharpness-Aware Minimization for Improved Training of Neural Networks. ICLR 2022. https://arxiv.org/abs/2110.03141 (LookSAM: approximates SAM using gradient history — closely related mechanism)
  - Zhuang et al. (2022). Surrogate Gap Guided Sharpness-Aware Minimization. ICML 2022. https://arxiv.org/abs/2203.08065 (GSAM: analyzes quality of HVP approximations)
  - Izmailov et al. (2018). Averaging Weights Leads to Wider Optima and Better Generalization. UAI 2018. https://arxiv.org/abs/1803.05407 (SWA: motivation for why flat minima improve EMA-eval)
