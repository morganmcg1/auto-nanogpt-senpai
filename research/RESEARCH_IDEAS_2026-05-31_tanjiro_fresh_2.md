# Fresh Hypothesis — tanjiro — 2026-05-31
# Orthogonal Initialization for Q/K/V Attention Weight Matrices

---

## Slug

`qkv-ortho-init`

## One-sentence summary

Replace the Gaussian initialization of attention Q/K/V weight matrices with orthogonal initialization at the same Frobenius norm, giving Muon/NS5 an exact Stiefel-manifold starting point and reducing the corrective work NS5 must perform at every early step.

---

## Freshness — Why This Is Structurally Distinct

### Distinction from the 74 closed families (key axes)

| Family | How it differs from qkv-ortho-init |
|---|---|
| `depth-init` (musoft/mumedium/muall/ctrl) | musoft scales residual projection std by 1/sqrt(L). Q/K/V are explicitly NOT touched by musoft — they use Gaussian std_base in the else branch (line 848). This hypothesis operates exclusively in that else branch. |
| `mu-decouple` (closed) | Separation of Muon vs AdamW parameter groups. Zero overlap with weight init. |
| `ns-iter` family | NS5 iteration count. Orthogonal init changes the _starting point_, NS-iter changes the _convergence speed of NS5 per step_. Orthogonal and orthogonal in design space. |
| `NS-polynomial replacement` | Different polynomial approximator for the zeropower map. This is pre-update init, not the polynomial. |
| `pre-NS normalization` | Normalizing gradients before NS5. This is weight init, not gradient normalization. |
| `SOAP phase-gating` | Preconditioner enable/disable schedule. No overlap with weight init. |
| `label-smoothing`, `EMA-eval`, `WD-schedule`, `LR-MLP`, `LR-scalars` | Entirely different mechanism levels. |

### Distinction from the 7 in-flight axes

| In-flight PR | Why orthogonal |
|---|---|
| #1858 edward: Schulz polish square α-blend | NS5 step quality at convergence, not init |
| #1880 tanjiro: mu-cooldown | Momentum schedule during cooldown phase, not init |
| #1885 fern: gradient centralization | Gradient preprocessing before the optimizer step |
| #1891 askeladd: GE-SAM extrapolation | Gradient extrapolation from previous step |
| #1897 nezuko: annealed gradient noise | Injected noise into gradients |
| #1903 alphonse: stochastic depth | Residual dropout at block level |
| #1907 thorfinn: ln-gain-init-small | LN/RMSNorm gain initialization (1D scalars, `gains` tensors). Q/K/V are 2D weight matrices. |

**Summary**: qkv-ortho-init touches exactly one code location — the `else` branch of the weight init loop for non-residual 2D blocks (line 848 of train_gpt_simple.py). No current family touches this branch for Q/K/V specifically.

---

## Motivation and Mechanism

### The structural argument

Muon applies NS5 (Newton-Schulz 5th-order polynomial) at every optimizer step to project the gradient update onto the Stiefel manifold — the set of matrices with orthonormal rows (or columns). The update is:

```
U_t = NS5(G_t)   where G_t = Nesterov momentum of the raw gradient
W_{t+1} = W_t - lr * U_t
```

NS5 is an iterative contraction toward the nearest orthogonal matrix. With `--ns_iter 6`, it runs 6 Newton-Schulz iterations per step. The convergence rate of NS5 depends on the singular value spread of the input: if the singular values of G_t are already clustered near 1 (i.e., G_t is already near-orthogonal), NS5 converges in far fewer effective iterations and the residual error is smaller.

The key insight: **the singular value spread of the gradient G_t at step t depends on the current weight matrix W_t**. Specifically, for self-attention:

- Q projection: `attn_output = softmax(Q K^T / sqrt(d)) V`, so Q's gradient contains `d_attn * K^T` terms
- The conditioning of W_Q at step 0 directly controls how coherent the gradient signal is at steps 0..~200
- If W_Q starts Gaussian (std_base ≈ 0.0207, heavily rank-deficient relative to the Stiefel manifold), NS5 must perform large corrections at every early step
- If W_Q starts orthogonal (singular values all equal, Frobenius norm preserved), NS5 at step 1 performs near-zero correction — it is already there

### Why this matters for FFS

FFS measures the first step t where the EMA-smoothed validation loss crosses the target. The FFS distribution for this stack concentrates in the cooldown window (steps ~2800–3050). The cooldown phase is where the model's behavior is most sensitive to the quality of the optimization trajectory inherited from the warmup phase. A cleaner gradient signal in the first ~500 steps — when NS5's corrective work is reduced because W_Q/K/V already lie on the Stiefel manifold — compresses the loss descent trajectory and shifts the FFS crossing earlier.

This is not purely speculative: Saxe et al. (2014) showed that orthogonal weight initialization gives exact linear convergence in deep linear networks, with the convergence rate depending on how far the initial weights are from the Stiefel manifold. Nonlinear networks retain the qualitative benefit, especially in the early training phase where gradient directions are most coherent.

### Why NS5 specifically makes this relevant

In standard SGD, orthogonal init is a moderate benefit. In Muon+NS5, it is structurally motivated: NS5 is computing a Stiefel projection at every step. The initialization sets the starting point on (or near) the Stiefel manifold. The optimization landscape under Muon is effectively Riemannian (on the product of Stiefel manifolds for each weight matrix). Starting on the manifold rather than at a random point in ambient space removes a source of trajectory noise that is unique to this optimizer.

### Frobenius norm preservation

`torch.nn.init.orthogonal_` produces a matrix U with orthonormal rows (or columns): `‖U‖_F = sqrt(min(rows, cols))`. The Gaussian baseline gives `E[‖W‖_F^2] = rows * cols * std_base^2`, so `‖W‖_F ≈ std_base * sqrt(rows * cols)` in expectation. To preserve the same effective scale at step 0, we rescale after `orthogonal_`:

```
target_norm = std_base * sqrt(rows * cols)
W = U * (target_norm / ‖U‖_F)
```

For a square matrix (rows = cols = d): `‖U‖_F = sqrt(d)`, `target_norm = std_base * d`, so scale factor = `std_base * sqrt(d)`. For a non-square matrix (Q projection is often square in this config at d_model=768), same formula applies.

This ensures the activation magnitude at step 0 is identical between Gaussian and orthogonal init, so any observed FFS difference is attributable to the geometric structure of the initialization, not to a scale change.

---

## Implementation Surface

### Change surface: ≤ 15 LOC

**Step 1: Add CLI flag in `parse_args()` (lines 33–113)**

```python
parser.add_argument("--qkv_ortho_init", action="store_true",
    help="Initialize attn.q/k/v weight matrices with orthogonal init "
         "(same Frobenius norm as Gaussian baseline). Default: False (Gaussian).")
```

**Step 2: Add `import math` if not present** (it is already imported at line ~20 for the std computations; confirm before adding).

**Step 3: Modify init loop else-branch (lines 842–848)**

Current code:
```python
else:
    # non-residual 2D weights (block Q/K/V/fc and any others)
    std_base = (0.33 ** 0.5) / (w.size(-1) ** 0.5)
    if args.depth_init_mode == "muall" and _is_block_nonresidual_2d(name):
        w.normal_(std=std_base / (NUM_LAYERS ** 0.5))
    else:
        w.normal_(std=std_base)
```

New code:
```python
else:
    # non-residual 2D weights (block Q/K/V/fc and any others)
    std_base = (0.33 ** 0.5) / (w.size(-1) ** 0.5)
    _QKV_SUFFIXES = (".attn.q.weight", ".attn.k.weight", ".attn.v.weight")
    if args.qkv_ortho_init and any(name.endswith(s) for s in _QKV_SUFFIXES):
        # Orthogonal init: place W on Stiefel manifold, rescale to match Gaussian Frobenius norm
        torch.nn.init.orthogonal_(w)
        target_norm = std_base * math.sqrt(w.size(0) * w.size(1))
        w.mul_(target_norm / w.norm().clamp_min(1e-8))
    elif args.depth_init_mode == "muall" and _is_block_nonresidual_2d(name):
        w.normal_(std=std_base / (NUM_LAYERS ** 0.5))
    else:
        w.normal_(std=std_base)
```

**Log for W&B transparency:** Add a sanity print after the init loop:

```python
if args.qkv_ortho_init:
    print0("[init] qkv_ortho_init=True: Q/K/V weights initialized orthogonally (Frobenius-norm-matched)", console=True)
```

### Key gotchas

**Gotcha 1: `name` vs block-level name.** The init loop iterates over `model.named_parameters()`. Block-level Q/K/V weights have names like `blocks.0.attn.q.weight`, `blocks.11.attn.k.weight`, etc. The suffix check `name.endswith(".attn.q.weight")` correctly matches these and does NOT match `lm_head` or `embed` weights.

**Gotcha 2: Non-square matrices.** In this config, Q, K, V projections map from d_model=768 to d_head*n_heads=768 (square). `torch.nn.init.orthogonal_` handles this correctly for square matrices (produces exactly orthogonal U). If the architecture ever uses rectangular Q/K projections, orthogonal_ still works but produces a semi-unitary matrix (orthonormal rows for tall matrices, orthonormal columns for wide matrices).

**Gotcha 3: Do NOT extend to `.mlp.fc.weight`.** The fc weight is not processed by NS5 (it is in the Muon group but gets standard Muon, not SOAP). Including fc in the ortho init would bundle two effects. Keep the scope to Q/K/V only for Cell B★.

**Gotcha 4: muall interaction.** If `--depth_init_mode muall` is active (it is not in the mandatory stack, which uses `musoft`), the muall branch would be skipped for Q/K/V when `--qkv_ortho_init` is set. This is correct behavior: orthogonal init takes precedence. But since the mandatory stack uses `musoft`, this interaction is irrelevant for the actual runs.

**Gotcha 5: `torch.nn.init.orthogonal_` is in-place.** It modifies `w` in place. The subsequent `w.mul_(...)` is also in-place. No temporary tensor needed.

---

## Experimental Cells

### KG_smoke gate

Before any full run, add a quick deterministic smoke test: run 3 optimizer steps with `--debug` or equivalent minimal config and confirm that Q/K/V weight matrices after orthogonal init have singular values clustered near a constant (verify with `torch.linalg.svdvals(w)`). The ratio max_sv / min_sv should be ≤ 1.001 immediately after init (exact orthogonality). This confirms the init code is correct before spending a full GPU slot.

### Cell A_ctrl — Gaussian baseline (control)

Confirm the split code path (with `--qkv_ortho_init` absent) matches baseline FFS.

```
python train.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --wandb_group qkv-ortho-init
```

Expected FFS_ema: ~2912 (within 2σ = 50 steps of baseline μ_4=2912.5)
Gate: FFS_ema ∈ [2862, 2962] to confirm no regression from the code split itself. If outside this range, debug the else-branch logic before running B★.

### Cell B★ — qkv-ortho-init (primary bet)

```
python train.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --qkv_ortho_init \
  --wandb_group qkv-ortho-init
```

Expected FFS_ema: 2840–2890 (1–3% improvement, 25–75 steps)
Gate for signal: FFS_ema ≤ 2887 (1σ below baseline) OR FFS_trainval ≤ 2900

### Cell C — Q/K only (ablation)

Tests whether the benefit is driven by the key projections (Q, K control the attention pattern) vs the value projection (V controls what is aggregated).

```python
# Modified suffix set for Cell C:
_QKV_SUFFIXES = (".attn.q.weight", ".attn.k.weight")  # V excluded
```

```
python train.py \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --ema_eval_decay 0.99 \
  --qkv_ortho_init \
  --wandb_group qkv-ortho-init
```

(Requires a separate code variant or a `--qkv_ortho_mode {qkv,qk,v}` flag — see implementation note below.)

Add `--qkv_ortho_mode` flag with choices `["qkv", "qk", "v"]`, default `"qkv"`, to enable this ablation without separate code branches.

Expected FFS_ema: 2850–2900 (intermediate effect if V also matters)

### Cell D — conditional, broader ortho (fc weight)

Only if B★ shows strong signal. Extends orthogonal init to `.mlp.fc.weight` as well (also a Muon-tracked matrix). This is a separate effect and should not be bundled with B★ in the primary experiment.

```python
_ORTHO_SUFFIXES = (".attn.q.weight", ".attn.k.weight", ".attn.v.weight", ".mlp.fc.weight")
```

Run only after B★ confirms FFS_ema < 2887.

### Recommended run order

Run A_ctrl and B★ in parallel (they share the same stack, differ only by `--qkv_ortho_init`). If B★ beats baseline, run C to separate Q/K from V effects. Run D only if both B★ and C show improvement and the direction seems saturatable.

---

## Gates and Stop Conditions

| Gate | Threshold | Action |
|---|---|---|
| KG_smoke | Singular value ratio max/min ≤ 1.001 at init | Pass before running A_ctrl or B★ |
| FFS-alive (n=1 screen) | FFS_ema ≤ 2975 AND FFS_trainval ≤ 2950 | Required before n=4 promote |
| Signal gate | B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900 | Run C and D |
| Promote (n=4) | FFS_trainval ≤ 2900 OR FFS_ema ≤ 2825 | Run n=4 for merge consideration |
| Merge | μ_4(FFS_ema) ≤ 2887.5 | Submit for merge |
| Stop — no signal | B★ FFS_ema ≥ 2887 AND FFS_trainval ≥ 2900 | Close after A_ctrl + B★ |
| Stop — A_ctrl regression | A_ctrl FFS_ema > 2962 (>2σ above baseline) | Debug code split before B★ |
| Stop — both metrics at noise attractor | FFS_ema ≈ 2875 AND FFS_trainval ≈ 2925 | Seed noise, not real signal — require BOTH to move before promote |

**Seed-noise attractor note**: The documented attractor at {FFS_ema=2875, FFS_trainval=2925} is a known trap. If B★ lands here, it does NOT qualify for promotion. Both FFS_ema must be below 2825 OR FFS_trainval must be below 2900, not just one metric sitting at the attractor.

---

## Decision Tree

```
KG_smoke: singular values clustered near constant?
├── NO → debug init code (orthogonal_ call or rescale formula)
└── YES → proceed

A_ctrl (Gaussian, no flag) || B★ (--qkv_ortho_init) [parallel]
│
├── A_ctrl FFS_ema > 2962 → code split bug, debug else-branch
│
├── B★ FFS_ema ≤ 2887 OR FFS_trainval ≤ 2900 (signal)
│   ├── Run C (Q/K only, not V)
│   │   ├── C FFS_ema ≤ B★ FFS_ema → Q/K init is primary driver; V is neutral
│   │   └── C FFS_ema > B★ FFS_ema → V init also contributes; keep Q/K/V ortho
│   │
│   ├── If B★ at promote threshold: run n=4 for B★
│   │   └── μ_4(FFS_ema) ≤ 2887.5 → MERGE B★
│   │
│   └── Run D (broader ortho incl. fc.weight) only if C confirms Q/K/V benefit
│
└── B★ FFS_ema ≥ 2887 AND FFS_trainval ≥ 2900 (no signal)
    └── CLOSE — orthogonal QKV init is not a meaningful lever in this stack
```

---

## Pre-mortems: Why This Might Not Work

**1. NS5 absorption neutralizes the init advantage.**
NS5 is idempotent on already-orthogonal matrices: if W is exactly orthogonal at step 0, NS5(gradient) at step 1 still receives the gradient of a loss with respect to W — not W itself. The gradient is not generally orthogonal even when W is. NS5 is re-projecting the gradient update, not the weight. So the "warm start" argument applies only indirectly: the gradient of an orthogonally-initialized weight may happen to have better singular value spread (because the attention pattern is more uniform initially), but this is a second-order effect, not a guarantee.

**2. The FFS bottleneck is in cooldown, not early training.**
FFS crossings happen at steps 2800–3050 — very late relative to the ~6000-step total training. The orthogonal init effect is maximal in steps 0–500 (early training). If the optimization trajectory converges to the same basin regardless of init after step 500, the cooldown phase FFS is unaffected. Evidence: the depth-init family (musoft/mumedium) showed diminishing returns in the FFS window despite modifying residual projection scales.

**3. Gaussian init is already nearly orthogonal in expectation for this scale.**
For d_model=768, the Gaussian init with std=0.0207 gives a matrix with expected singular value spread approximately uniform (by random matrix theory for Gaussian matrices with iid entries). The deviation from orthogonality is O(1/sqrt(d)), which for d=768 is about 3.6%. This is small enough that NS5 corrects it in 1–2 iterations even with ns_iter=6. The marginal benefit of exact orthogonality may be below the FFS noise floor (σ=25).

**4. Scale mismatch if rescaling formula is wrong.**
If the Frobenius norm rescaling is implemented incorrectly, the effective LR for Q/K/V changes. A too-large norm → exploding gradients in early steps. A too-small norm → underfitting in early attention pattern formation. The formula `target_norm = std_base * sqrt(rows * cols)` must be verified against the Gaussian expectation.

**5. Interaction with SOAP preconditioning.**
SOAP preconditions attention weights using an eigenbasis estimated from gradient history. If Q/K/V start orthogonal, the initial SOAP eigenbasis estimate (which is gradient-based) is computed from a gradient at a more structured starting point. This could either help (better initial eigenbasis estimate) or hurt (SOAP's initial eigenbasis is adapted to Gaussian init, and a different starting structure may cause SOAP to converge to a suboptimal preconditioner in the first few hundred steps).

---

## Taste Rubric

**Research mode: Diagnostic** — tests a specific structural property of the optimization loop (NS5 warm start via init) that is theoretically motivated but has not been ruled out by any prior experiment in the 74-family closed set.

| Criterion | Score | Rationale |
|---|---|---|
| Mechanistic grounding | 3 | The mechanism (Stiefel starting point → reduced NS5 corrective work → cleaner early gradient signal) is specific and tied to the NS5 codebase. The connection to FFS is one step removed (early convergence → better cooldown trajectory). Pre-mortem 1 gives a precise falsifying scenario. |
| Research-state value | 3 | Either confirms that QKV init geometry matters under Muon (a new lever for future exploration of other weight families), or rules out init-quality as a lever (which is itself informative given NS5's Stiefel projection is applied at every step). |
| Execution value | 4 | ≤15 LOC change, directly testable in one GPU slot, completely orthogonal to all 7 in-flight axes. The KG_smoke gate catches implementation errors before spending a full training run. Very high information per compute unit. |

---

## References

1. **Saxe et al. "Exact solutions to the nonlinear dynamics of learning in deep linear networks." ICLR 2014.** Proves that orthogonal init gives exact linear convergence in deep linear networks; the singular value structure of the init is preserved through training in the linear case, motivating the geometric argument.

2. **Kosson et al. "Rotational Equilibrium: How Weight Decay Balances Learning Across Neural Networks." NeurIPS 2022.** Shows that Muon-style optimizers maintain approximate orthogonality of weight matrices through training; this means that non-orthogonal init is a transient state that is eventually corrected, but at the cost of optimization steps.

3. **Bernstein & Newhouse. "Old Optimizer, New Norm: An Anthology." 2024 (arXiv:2409.20325).** Frames Muon as steepest descent under the spectral norm; the optimal step direction in spectral norm is the nearest orthogonal matrix — directly motivating orthogonal init as the "on-manifold" starting point for this optimizer family.

4. **Jordan et al. "Muon: An Optimizer for Hidden Layers in Neural Networks." 2024.** The primary Muon reference; notes that NS5 projects gradients to the Stiefel manifold, which is the geometric motivation for this hypothesis.

5. **Pennington et al. "Resurrecting the sigmoid in deep learning through dynamical isometry: theory and practice." NeurIPS 2017.** Demonstrates that orthogonal init combined with nonlinear networks preserves singular value spread through layers, a property that is directly relevant to Q/K/V's role in controlling attention logit magnitude.

---

## Mandatory Stack

All runs must include:
```
--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03
--depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99
```

The `--qkv_ortho_init` flag is additive on top of this stack. No mandatory flag is removed or modified.
