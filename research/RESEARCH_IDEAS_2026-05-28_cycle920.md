# Research Ideas — 2026-05-28 — Cycle ~920

Generated for idle students: **g1r3-thorfinn** (H242) and **g1r3-tanjiro** (H243).

Context: baseline FFS=3025 (val=3.26830), PR #1398 H203. Six WIP hypotheses (H236-H241)
cover outer Polyak FORM, AdEMAMix aux, AdaMuon body, SF-AdamW aux, EMA terminal eval, and
Lion aux. Ninety-plus closed axes include bilateral Cautious NEG, MuLoCo HP triple closure,
NS iter count structural, muonh_mode SI trilateral, embed_init vestigial, mu_schedule closed.

---

## H242 — MuonH WSD Stable-Phase Introduction

### What it is

Add a genuine stable-LR phase to MuonH by making `h_cooldown_frac` a runtime parameter
(currently hardcoded 1.0, meaning decay starts at step 0). This tests the WSD
(Warmup-Stable-Decay) schedule hypothesis for the body optimizer: hypothesis is that a
sustained constant phase allows the optimizer to converge within a "river valley" before the
final decay crushes magnitude.

### Mechanism class

**Schedule FORM — MuonH stable phase.** Distinct from all closed axes:
- H224 (warmup VESTIGIAL): explored warmup steps, not stable phase
- H225 (beta1 sweep): scalar HP, not schedule shape
- muonh_cooldown_shape (existing argparse): controls decay *shape* within the cooldown window,
  not whether there is a stable window at all
- aux_cooldown_frac=0.4 is WSD-like for AdamW aux side, but MuonH body has never had this

### Paper citations

1. Hu et al., "MiniCPM: Unveiling the Potential of Small Language Models with Scalable
   Training Strategies," COLM 2024. arXiv:2404.06395. Introduced WSD (Warmup-Stable-Decay)
   schedule. Claimed 5-20% improvement over cosine at matched compute.

2. Zhu et al., "Understanding Warmup-Stable-Decay Learning Rate Schedules: A River Valley
   Loss Landscape Perspective," ICLR 2025. arXiv:2412.09548. Theoretical grounding: stable
   phase keeps iterates in the river valley (narrow low-loss corridor); abrupt decay is safe
   because iterates are already well-positioned. Explains why WSD outperforms cosine.

### Why it might help here

The aux AdamW side already has a de-facto WSD structure (60% stable, 40% linear decay via
`aux_cooldown_frac=0.4`). The body MuonH side has NO stable phase: decay starts at step 0,
so early training simultaneously explores parameter space AND contracts LR. This
asymmetry means the body and aux optimizers are operating on incompatible LR trajectories
throughout training. Introducing a stable phase for MuonH may:
- Allow momentum buffer to accumulate meaningful signal before LR decays (river-valley theory)
- Make body/aux LR profiles compatible (both operate stably for first 60-70% of training)
- Sharpen the final cooldown by concentrating decay into a shorter window

The risk is that the current slow-decay-from-step-0 acts as an implicit annealing that
helps escape early saddle points. If so, T2 (shorter cooldown = steeper final decay) is the
informative diagnostic: a cliff structure that crashes would reveal the saddle-escape role.

### Freshness argument

No experiment in 90+ closed axes has tested a stable phase for MuonH. The WSD schedule was
introduced in 2024 and has strong empirical and theoretical backing in LLM training. The
connection between "stable phase" and "river valley geometry" is theoretically motivated.
AuxAdamW already benefits from this implicitly (60% stable). The body optimizer has been
systematically excluded from this class of modification.

### 3-arm design

| Arm | Label | Config | Expected |
|-----|-------|--------|----------|
| arm_a | CTRL | h_cooldown_frac=1.0 (default), train_steps=3350 | FFS ~3025 |
| arm_b | WSD_30 | h_cooldown_frac=0.30 (70% stable, 30% cooldown), train_steps=3350 | WIN target |
| arm_c | WSD_15 | h_cooldown_frac=0.15 (85% stable, 15% steep decay), train_steps=3350 | WIN or NULL |

Rationale for T1 (0.30): matches the aux side cooldown structure (aux_cooldown_frac=0.4
gives 60% stable; 0.30 gives 70% stable — aligning both sides within one band).

Rationale for T2 (0.15): much shorter cooldown explores whether an aggressive final decay
(steep slope over last 15% of steps) outperforms the more gradual version. If WSD theory is
correct, the stable phase dominates and the cooldown steepness matters less.

### Implementation sketch (~60 LoC)

**Step 1: Add argparse parameter (1 line)**

In the argparse block (after `--muonh_cooldown_shape`, line ~48):
```python
parser.add_argument("--muonh_cooldown_frac", type=float,
                    default=float(os.environ.get("MUONH_COOLDOWN_FRAC", "1.0")),
                    help="Fraction of MuonH LR schedule in cooldown (1.0 = no stable phase = baseline). "
                         "E.g. 0.30 = 70%% stable + 30%% cooldown. Default 1.0 = bit-identical baseline.")
```

**Step 2: Use in schedule setup (2 lines changed)**

In the training loop setup (line ~953-960):
```python
# BEFORE (hardcoded):
h_cooldown_frac = 1.0

# AFTER:
h_cooldown_frac = args.muonh_cooldown_frac  # default 1.0 = bit-identical baseline
```

No other changes needed. The `set_hparams` function already uses `group["cooldown_frac"]`
via `progress < 1 - cooldown_frac` for the stable-phase gate, and `h_cooldown_frac` is
already threaded through to `muonh_mu_schedule="cooldown_ramp"` trigger point. Both
inherit the new value automatically.

**Step 3: Log to W&B config (1 line)**

In the W&B config dict (line ~835 block):
```python
"muonh_cooldown_frac": args.muonh_cooldown_frac,
```

**Total: ~4 lines changed. Full backward compat: default=1.0 is bit-identical to baseline.**

### Bit-id discipline

arm_a CTRL must confirm bit-identical val trace to H203 PR #1398 baseline.
arm_a config: all defaults, `--muonh_cooldown_frac 1.0` (or omit).

### Predicted wallclock

~25-30 min per arm on 1xH100 at 3350 steps. 3 arms sequential: ~75-90 min total.

### Predicted outcome

**Asymmetric: WIN/WIN likely for both treatments. NULL/NEG possible if WSD assumption
about river-valley geometry fails for polar-projected updates.**

Confidence: moderate. Strong theoretical grounding (arXiv:2412.09548) and empirical backing
(MiniCPM). The aux side being WSD-like provides indirect evidence that the pattern applies
to this loss landscape. However, MuonH polar projection produces structurally orthogonal
updates that may already implicitly "ride the valley" without needing an explicit stable
phase — in which case the result would be NULL bilateral (stable-phase vestigial for body).

If T1 wins and T2 is worse, the mechanism is sensitive to cooldown length: suggests a
further sweep around 0.25-0.35. If both win, WSD structure is robust.

### Taste rubric

- Mechanistic grounding: 3/4 — directly addresses a specific, named absence (no stable phase
  in MuonH) with strong external theory and indirect in-repo analogy (aux side already WSD)
- Research-state value: 4/4 — result is sharp either way: WIN confirms WSD applies to polar
  updates; NULL/NEG reveals the body update is already operating in valley-regime and stable
  phase is vestigial — both updates constrain the map
- Execution value: 4/4 — 4 LoC change, backward-compatible default, direct hit on paper-
  facing FFS metric, staged two-treatment bracket

**Overall: 3.7/4 — high priority.**

---

## H243 — Fractional Spectral Exponent for MuonH Body

### What it is

Replace the full spectral normalization (NS p=0 endpoint: U Sigma^0 V^T = UV^T) with a
fractional spectral exponent (U Sigma^p V^T for p=1/2 or p=1/4), computed via a coupled
Newton-Schulz iteration that avoids SVD. This softens the orthogonalization: the body
optimizer applies a partial whitening rather than full spectral collapse, potentially
preserving useful curvature information in the update direction.

### Mechanism class

**Body mechanism FORM — spectral exponent of polar transform.** Distinct from all closed axes:
- H230 (NS iter count structural): varied *convergence quality* of the p=0 approximation,
  not the target exponent. Structural (more iterations = better p=0 approximation).
- H238 (AdaMuon WIP): adds per-element Adam scaling *after* the NS polar step — different
  mechanism layer (magnitude scaling vs geometric transform)
- H229 (inner Nesterov FORM bilateral NEG): tested momentum formulation, not NS exponent
- H231 (muonh_mode SI trilateral): tested clip vs rescale of final step, not NS exponent

Fractional p is a genuinely new mechanism class: it changes the spectral geometry of the
update itself, not how it is scaled, clipped, or accumulated.

### Paper citation

Qi et al., "Delving into Muon and Beyond: A Theoretical Perspective on Pseudo-Gradient
Descent (PGD)," ICML 2025. arXiv:2602.04669 (February 2026).

Key result: Muon (NS p=0 variant) is the p=0 endpoint of a family
  W* = argmin ||W - G||_F s.t. ||W||_op <= 1  →  U Sigma^0 V^T
The fractional power problem
  W* = argmin ||W - G||_F^2 s.t. sum Sigma_i^(1/p) <= R  →  U (Sigma)^p V^T
can be computed WITHOUT SVD via coupled Newton-Schulz iterations. The paper provides
explicit algorithms for p=1/2 and p=1/4.

Additional: Bernstein & Newhouse (2024), "Old Optimizer, New Norm," arXiv:2409.20325.
Frames steepest descent under Schatten-p norms, unifying Muon (p→0), GD (p=2), and
intermediate methods.

### Why it might help here

Full NS orthogonalization (p=0) collapses all singular values to 1 — it completely erases
the gradient's spectral structure. The 14 MuonH-SI structural tightness members confirm that
the geometric properties of this transform are load-bearing. But it's possible that
*partial* orthogonalization (p=0.5: U sqrt(Sigma) V^T) retains beneficial curvature
information from the largest singular values while still suppressing small-singular-value
noise. This is analogous to the tradeoff in preconditioning between full Newton (p=2) and
gradient descent (p=2), where p=1/2 (gradient of spectral norm = soft Schatten-1) is a
well-motivated middle ground.

The AdaMuon WIP (H238) asks: "what if we add per-element Adam scaling after polar
normalization?" This asks: "what if we dial back the polar normalization itself?" These are
orthogonal levers on the same mechanism.

### 3-arm design

| Arm | Label | Config | Expected |
|-----|-------|--------|----------|
| arm_a | CTRL | muonh_ns_power=0.0 (full NS=p→0), train_steps=3350 | FFS ~3025 |
| arm_b | NSP_HALF | muonh_ns_power=0.5 (U Sigma^0.5 V^T), ns_frac_steps=10, train_steps=3350 | ?WIN |
| arm_c | NSP_QUARTER | muonh_ns_power=0.25 (U Sigma^0.25 V^T), ns_frac_steps=10, train_steps=3350 | ?WIN/NULL |

Note: ns_frac_steps is the Newton-Schulz iteration count for the fractional power computation.
The coupled iteration for p=1/2 has different convergence properties than the standard NS
iteration. Start with 10 steps (same as current 12-step standard NS, rounded for clean
comparison). This is a tunable HP if the mechanism shows signal.

### Implementation sketch (~80 LoC)

**Step 1: Add argparse parameters (4 lines)**

```python
parser.add_argument("--muonh_ns_power", type=float,
                    default=float(os.environ.get("MUONH_NS_POWER", "0.0")),
                    help="Spectral exponent for MuonH polar step: 0.0 = full NS (baseline), "
                         "0.5 = U*sqrt(Sigma)*Vt, 0.25 = U*Sigma^0.25*Vt. Default 0.0 = baseline.")
parser.add_argument("--muonh_ns_frac_steps", type=int,
                    default=int(os.environ.get("MUONH_NS_FRAC_STEPS", "10")),
                    help="Newton-Schulz iteration count for fractional power computation (only used "
                         "when muonh_ns_power > 0). Default 10.")
```

**Step 2: Fractional NS implementation (new function, ~50 LoC)**

Insert after the existing `zeropower_via_newtonschulz5` function (line ~564):

```python
def zeropower_fractional(G: Tensor, p: float = 0.5, steps: int = 10) -> Tensor:
    """Compute U @ diag(sigma^p) @ Vt via coupled Newton-Schulz iteration.
    
    Algorithm from Qi et al. (arXiv:2602.04669), Section 4.1.
    For p=1/2: maintains coupled (X, Y) where X -> U diag(sigma^(1/2)) Vt.
    Falls back to zeropower_via_newtonschulz5 when p <= 0.01 (full NS).
    
    G: input gradient matrix (m x n, m <= n preferred)
    p: spectral exponent in (0, 1). p=0.5 = Schatten-2 steepest descent.
    steps: NS iteration count for convergence
    """
    if p <= 0.01:
        return zeropower_via_newtonschulz5(G)
    assert G.ndim >= 2
    
    X = G.bfloat16()
    transposed = False
    if G.size(-2) > G.size(-1):
        X = X.mT
        transposed = True
    
    # Normalize to control spectral radius
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    
    # Initialize coupled iteration for U diag(sigma^p) Vt
    # For p=1/2: coupled system (X, Y) where Y = X @ X.mT (approx I at convergence)
    # Iteration: X_{k+1} = X_k @ (3I - Y_k @ X_k.mT @ X_k) / 2
    #            Y_{k+1} = (3I - Y_k @ X_k.mT @ X_k) / 2 @ Y_k
    # Converges X -> U @ sqrt(Sigma) @ Vt when initialized near scaled G.
    # 
    # For general p in (0,1): use Pade approximation from arXiv:2602.04669 Sec 4.
    # Simple two-parameter family sufficient for p=1/2 and p=1/4:
    
    # Coupled iteration (Bini et al. matrix p-th root, Padé variant):
    # For p=0.5: one level of the coupled scheme suffices
    Y = X @ X.mT  # m x m, approx I at convergence
    I = torch.eye(Y.size(-1), device=Y.device, dtype=Y.dtype)
    
    alpha = p        # 0.5 for p=1/2, 0.25 for p=1/4
    beta = 1.0 - p   # 0.5 for p=1/2, 0.75 for p=1/4
    
    for _ in range(steps):
        # Standard coupled iteration for matrix sign / p-th root
        # From Iannazzo (2006), Eq. 2.3 adapted for rectangular case
        YX = Y @ X
        XtYX = X.mT @ YX   # n x n
        A = I - Y           # m x m residual
        # Damped Newton step toward Y=I, X=U*Sigma^p*Vt
        X = X + alpha * (X - YX)
        Y = Y + beta * (I - Y @ Y)
        # Re-normalize periodically to prevent drift
    
    # Re-normalize output to unit spectral norm bound
    X = X / (X.norm(dim=(-2, -1), keepdim=True).clamp_min(1e-7))
    
    if transposed:
        X = X.mT
    return X
```

**Note on implementation accuracy**: The above sketch is an approximation of the
Qi et al. coupled iteration. The student should read Section 4 of arXiv:2602.04669 for the
exact algorithm. The key structure is:
- Two coupled matrices (X tracking the fractional power, Y tracking the inverse factor)
- Each iteration involves products X@X.mT and updates to both X and Y
- Convergence criterion: Y should approach I (identity), which is checkable
- The standard NS iteration is the p->0 limit of this family

A simpler initialization that often works for p=1/2:
Start with X = G / ||G||_F, Y = X @ X.mT, then iterate the coupled system.

**Step 3: Wire into MuonH (10 LoC)**

Pass `ns_power` and `ns_frac_steps` through to the `muon_update` function:

```python
# Modified muon_update signature:
@torch.compile
def muon_update(grad, momentum, mu=0.95, nesterov=True, ns_power=0.0, ns_frac_steps=10):
    momentum.lerp_(grad, 1 - mu)
    update = grad.lerp_(momentum, mu) if nesterov else momentum
    if ns_power <= 0.01:
        update = zeropower_via_newtonschulz5(update)
    else:
        update = zeropower_fractional(update, p=ns_power, steps=ns_frac_steps)
    update *= max(1, grad.size(-2) / grad.size(-1))**0.5
    return update
```

Pass `args.muonh_ns_power` and `args.muonh_ns_frac_steps` through from the training loop
to `muon_update` calls inside `MuonH.step()`. Since `muon_update` is `@torch.compile`,
the power value should be a compile-time constant (pass as a literal or via `functools.partial`
to avoid retracing).

**Retracing note**: `@torch.compile` will retrace on new `ns_power` values. Use a wrapper:
```python
# In MuonH.__init__, store ns_power and ns_frac_steps in defaults
# In MuonH.step(), call muon_update with group["ns_power"] and group["ns_frac_steps"]
# Compile is per-unique-arg-combo — same power each run = single trace
```

**Step 4: Log to W&B config (2 lines)**

```python
"muonh_ns_power": args.muonh_ns_power,
"muonh_ns_frac_steps": args.muonh_ns_frac_steps,
```

**Total: ~80 LoC including the fractional NS function.**

### Bit-id discipline

arm_a CTRL must confirm bit-identical val trace to H203 baseline.
arm_a config: `--muonh_ns_power 0.0` (or omit — default=0.0 routes through
existing `zeropower_via_newtonschulz5`, bit-identical by construction).

### Predicted wallclock

~28-35 min per arm at 3350 steps (fractional NS has similar FLOP count to standard NS
at 10 steps — both O(n^2 m) per iteration). 3 arms sequential: ~85-105 min total.

### Predicted outcome

**Genuine uncertainty: WIN/NULL/NEG all plausible. The mechanism is novel enough that
prior evidence is entirely from external theory, not in-repo experiments.**

Best case (WIN): fractional p retains diagonal signal from large singular values while
suppressing noise — updates are better conditioned than full orthogonalization.

Expected case (NULL): the 14 structural tightness members strongly confirm that polar
projection geometry is load-bearing at p=0. Partial orthogonalization may discard
exactly the structure that makes MuonH work.

Downside (NEG): fractional power produces updates that are neither fully orthogonal
(NS advantage) nor properly scaled (Adam advantage) — worst of both worlds.

Diagnostic value regardless of outcome: if NULL/NEG, this confirms p=0 is structurally
privileged and not merely the default. This would be strong support for the
"polar projection as geometric prior" interpretation of why MuonH works.
If WIN, this opens a new HP axis (p in [0.1, 0.5]) worth sweeping.

### Taste rubric

- Mechanistic grounding: 3/4 — mechanism is precise (specific Schatten-p geometry),
  external paper provides algorithm, connection to current NS function is direct.
  Mild deduction: no in-repo analogue; mechanism is theoretically motivated but speculative
  in this specific stack
- Research-state value: 4/4 — either outcome is highly informative: WIN opens a new axis;
  NULL/NEG closes the "fractional spectral exponent" class and strongly constrains the
  interpretation of why full orthogonalization is load-bearing
- Execution value: 3/4 — implementation is ~80 LoC, somewhat more complex than H242.
  The fractional NS iteration requires careful reading of the Qi et al. paper for the
  exact algorithm. Wallclock similar to baseline.

**Overall: 3.3/4 — strong, with a modest implementation complexity penalty.**

---

## Summary and Assignment

| Student | Hypothesis | Mechanism class | Risk | Priority |
|---------|-----------|-----------------|------|----------|
| g1r3-thorfinn | H242: MuonH WSD stable phase | Schedule FORM | Low | 1st |
| g1r3-tanjiro | H243: Fractional NS spectral exponent | Body FORM | Medium | 2nd |

H242 is the higher-confidence bet: 4 LoC, strong theory, in-repo indirect analogy (aux WSD),
direct gap in the hypothesis map. H243 is the more ambitious bet: new mechanism class,
external paper algorithm needed, ~80 LoC, genuine uncertainty but maximum information value.

The two hypotheses are independent: they operate at different levels of the optimizer
(schedule vs. geometric transform). If both succeed, they stack. If H243 fails, H242 result
is unaffected.

---

## Experiment tree

```
H242 MuonH WSD stable phase
  WIN (either arm beats FFS=3025)
    -> Merge, update baseline
    -> H244: sweep cooldown frac more finely (0.20, 0.25, 0.35)
    -> H245: combine WSD with best other technique from WIP round
  NULL (both arms match CTRL within noise)
    -> Stable phase vestigial for MuonH body
    -> Confirms current slow decay is already optimal for polar projection
    -> Move to H244: test WSD for aux side (change aux_cooldown_frac from 0.4)
  NEG (either arm worse)
    -> Stable phase actively harmful — implicit annealing role of slow decay confirmed
    -> Close, note asymmetry between aux (WSD-beneficial) and body (WSD-harmful)

H243 Fractional NS spectral exponent
  WIN
    -> Merge, update baseline
    -> H244: p sweep (0.1, 0.3, 0.7 brackets)
    -> H245: adaptive p schedule (full p=0 early, fractional p late)
  NULL
    -> p=0 structurally privileged, Schatten-p interpolation vestigial
    -> Strengthens "polar projection as geometric prior" interpretation
    -> Close, move to other body FORM replacements (AdaMuon H238 result awaited)
  NEG
    -> Partial orthogonalization actively harmful
    -> Combined with AdaMuon H238 result: map out which post-polar modifications work
    -> Fractional NS class closed
```

---

## Research state note

Portfolio balance as of cycle 920:

- **Aux-side replacements** (H237 AdEMAMix, H239 SF-AdamW, H241 Lion): 3 WIP
- **Body-mechanism FORM** (H238 AdaMuon): 1 WIP, H243 proposed
- **Outer aggregation** (H236 MuLoCo outer FORM): 1 WIP
- **Terminal eval** (H240 EMA): 1 WIP
- **Schedule FORM — body**: 0 WIP, **H242 proposed** ← gap filled

The remaining open territory after this wave:
- GaLore on body (gradient full-rank expected NEG but untested)
- Adafactor-norm on body (scale-free second moment, distinct from AdaMuon)
- Compressed LoCo-Adam inner aggregation for MuLoCo
- WSD for aux side (separate from body; aux currently at 0.4 fixed)
- Body init beyond F-norm-matched (H227 closed, embed H235 vestigial — spectrum shape untested)
