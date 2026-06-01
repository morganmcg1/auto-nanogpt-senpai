# RESEARCH IDEAS — askeladd — 2026-06-01 20:30

## Hypothesis: `ns5-kj-coefficients`

**One-line statement:** Replace the hardcoded NS5 polynomial coefficients `(a, b, c) = (2.0, −1.5, 0.5)` in `zeropower_via_newtonschulz5` with Keller Jordan's empirically-optimized NanoGPT coefficients `(3.4445, −4.7750, 2.0315)`, and sweep two additional operating points to map the sensitivity of the loss surface to coefficient shape.

---

## Axis-exclusion table

| Axis | Prior experiment | Disposition | Orthogonality note |
|---|---|---|---|
| NS5 iteration count scheduling | tanjiro #2014 | Closed — FFS-NEUTRAL | That PR schedules `ns_iter` count; this PR changes polynomial coefficients `(a,b,c)` — fully orthogonal |
| NS5 per-group iteration depth | alphonse #2167 | WIP | That PR sets attn=7/mlp=5 iterations; does NOT modify `a, b, c` — fully orthogonal |
| Post-NS5 row normalization | frieren #2170 | WIP | That PR adds scaling after NS5 output; this PR changes NS5 internals — fully orthogonal |
| Pre-NS5 gradient modifiers | SGLD, GC, μ cooldown family | Closed — NS5-absorbed | Those are pre-NS5; we change the polynomial kernel itself |
| Post-NS5 per-block depth-LR scaling | Multiple | Closed — NS5-absorbed | Post-NS5 wrapper, not coefficient change |
| LN gain init, weight init perturbations | Multiple | Closed | Unrelated axis |
| mu shape, precond_freq cooldown | Multiple | Closed | Unrelated axis |

**No prior R5 experiment has touched `a, b, c` in `zeropower_via_newtonschulz5`.**

---

## Mechanism argument

Our codebase uses `(a, b, c) = (2.0, −1.5, 0.5)` — these are NOT Keller Jordan's published Muon coefficients. The KJ coefficients `(3.4445, −4.7750, 2.0315)` were derived empirically by optimizing NanoGPT validation loss at a fixed iteration budget. The CANS paper (arxiv:2506.10935) provides theoretical context: the polynomial ϕ(x) = ax + x(bx²+cx⁴) must maximize ϕ'(0) subject to |ϕ(x) − 1| ≤ δ on [1−δ, 1+δ] to maximize per-step convergence rate of singular values to 1 (the polar factor). Our current `(2, −1.5, 0.5)` does not satisfy this optimality condition. KJ's coefficients were specifically derived for `ns_iter` in the 5–12 range on NanoGPT, which matches our `--ns_iter 6` stack.

The NS5 update `X = aX + (bA + cA²)X` maps X toward the polar factor of G. Coefficient shape controls:
1. **Convergence radius**: whether the polynomial is contractive on [0.5, 1.5] (the likely singular value range of normalized Muon momentum tensors)
2. **Convergence rate**: derivative at the fixed point x=1 (should be 0 for stable convergence, but pre-convergence derivative at 0 governs early steps)
3. **Overshoot**: large `a` can push past the polar factor, requiring more iterations to stabilize

At `ns_iter=6`, our `(2, −1.5, 0.5)` polynomial is likely under-converged. KJ's `(3.4445, −4.7750, 2.0315)` polynomial achieves better approximation to the polar factor in the same number of steps, producing more orthogonal Muon updates, which translates directly to better conditioning of the effective learning rate scale.

**Expected observable:** FFS_ema should improve. The mechanism should be visible within 200–400 steps as the Muon update quality affects every gradient step.

**Falsifying result:** If B★ matches or exceeds baseline (FFS_ema ≤ 2862.5) while D is clearly worse, the mechanism is confirmed. If B★, C, and D all produce identical FFS_ema ≈ 2875, the polynomial shape is irrelevant at this iteration depth — either NS5 converges sufficiently with any contractive polynomial, or the SOAP trust gate is masking the effect.

---

## Code change (≤120 lines)

**File:** `target/records/track_3_optimization/train_gpt_simple.py`

### Step 1: Add module-level globals (after existing `NS_ITER` global, ~line 88)

```python
# NS5 polynomial coefficients (Muon orthogonalization)
# Default (2.0, -1.5, 0.5): current codebase values
# KJ-optimal (3.4445, -4.7750, 2.0315): Keller Jordan empirically-optimized for NanoGPT/Muon
NS_A: float = 2.0
NS_B: float = -1.5
NS_C: float = 0.5
```

### Step 2: Add CLI args (near existing `--ns_iter` arg, ~line 68)

```python
parser.add_argument("--ns_a", type=float, default=2.0,
    help="NS5 polynomial coefficient a. Default 2.0 (current codebase). "
         "KJ-optimal for Muon/NanoGPT: 3.4445.")
parser.add_argument("--ns_b", type=float, default=-1.5,
    help="NS5 polynomial coefficient b. Default -1.5 (current codebase). "
         "KJ-optimal for Muon/NanoGPT: -4.7750.")
parser.add_argument("--ns_c", type=float, default=0.5,
    help="NS5 polynomial coefficient c. Default 0.5 (current codebase). "
         "KJ-optimal for Muon/NanoGPT: 2.0315.")
```

### Step 3: Set globals from args (after `args = parser.parse_args()`, before optimizer construction)

```python
# Propagate NS5 coefficient CLI args to module globals
import records.track_3_optimization.train_gpt_simple as _self_module
_self_module.NS_A = args.ns_a
_self_module.NS_B = args.ns_b
_self_module.NS_C = args.ns_c
# Or equivalently, set via global statement in main():
global NS_A, NS_B, NS_C
NS_A, NS_B, NS_C = args.ns_a, args.ns_b, args.ns_c
```

### Step 4: Modify `zeropower_via_newtonschulz5` (~line 507)

```python
def zeropower_via_newtonschulz5(G: Tensor) -> Tensor:
    assert G.ndim >= 2
    X = G.bfloat16()
    if G.size(-2) > G.size(-1):
        X = X.mT
    X = X / (X.norm(dim=(-2, -1), keepdim=True) + 1e-7)
    a, b, c = NS_A, NS_B, NS_C  # <-- was: a, b, c = 2, -1.5, 0.5
    for _ in range(NS_ITER):
        A = X @ X.mT
        B = b * A + c * A @ A
        X = a * X + B @ X
    if G.size(-2) > G.size(-1):
        X = X.mT
    return X
```

**Total diff: ~10 lines changed, ~12 lines added. Well under the 120-line budget.**

Note: `soap_ns_step` also calls `zeropower_via_newtonschulz5` and will inherit the new coefficients automatically — correct behavior, as SOAP uses the same NS5 kernel.

---

## Cell design

| Cell | `--ns_a` | `--ns_b` | `--ns_c` | Role |
|---|---|---|---|---|
| **A_ctrl** | 2.0 | -1.5 | 0.5 | Baseline validation: must reproduce FFS_ema ≈ 2875 |
| **B★** | 3.4445 | -4.7750 | 2.0315 | Primary test: KJ-optimal coefficients |
| **C** | 2.72 | -3.13 | 1.27 | Midpoint between A and B: direction sensitivity check |
| **D** | 1.5 | -0.5 | 0.0 | Sub-optimal linear-only term (c=0 kills quartic); deliberate regression check |

Cell C uses arithmetic midpoint: a=(2.0+3.4445)/2=2.72, b=(−1.5+−4.775)/2=−3.1375≈−3.13, c=(0.5+2.0315)/2=1.2658≈1.27.

Cell D tests whether the quartic term (c·A²) is load-bearing: setting c=0 reduces NS5 to a quadratic polynomial, which should converge more slowly or to a worse fixed point.

**Run all 4 cells on n=1 seed first. If B★ shows FFS_ema < 2870 (promising signal below attractor), escalate to n=4. If B★ lands on attractor {2875, 2925}, close as FFS-NEUTRAL per the dual-metric attractor protocol.**

---

## Reproduce commands

```bash
# Mandatory stack (confirmed from alphonse #2167 / R5 standard):
BASE_FLAGS="--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft \
  --lr_cooldown_shape cosine --ema_eval_decay 0.99"

# A_ctrl — baseline validation (n=1)
python train_gpt_simple.py $BASE_FLAGS \
  --ns_a 2.0 --ns_b -1.5 --ns_c 0.5 \
  --wandb_group ns5-kj-coefficients --wandb_run_name kj-A-ctrl-s1

# B★ — KJ optimal (n=1, escalate to n=4 if FFS_ema < 2870)
python train_gpt_simple.py $BASE_FLAGS \
  --ns_a 3.4445 --ns_b -4.7750 --ns_c 2.0315 \
  --wandb_group ns5-kj-coefficients --wandb_run_name kj-B-star-s1

# C — midpoint (n=1)
python train_gpt_simple.py $BASE_FLAGS \
  --ns_a 2.72 --ns_b -3.13 --ns_c 1.27 \
  --wandb_group ns5-kj-coefficients --wandb_run_name kj-C-mid-s1

# D — falsifier (n=1)
python train_gpt_simple.py $BASE_FLAGS \
  --ns_a 1.5 --ns_b -0.5 --ns_c 0.0 \
  --wandb_group ns5-kj-coefficients --wandb_run_name kj-D-linear-s1
```

---

## Falsifier

**The mechanism is falsified if:**

1. B★ (`ns_a=3.4445, ns_b=-4.7750, ns_c=2.0315`) gives FFS_ema ≥ 2875 across n=4 seeds (falls on attractor or worse) — polynomial coefficient shape is irrelevant at `ns_iter=6`.

2. B★ and D give indistinguishable FFS_ema — the polynomial shape does not matter at all, likely because SOAP dominates the update for MLP weights and the Muon path is marginal.

3. C and B★ show opposite ordering from what the KJ optimization predicts — suggests the NanoGPT coefficient optimization was stack-specific and does not transfer to our R5 configuration.

**The mechanism is confirmed if:** B★ < A_ctrl (FFS improvement) AND D ≥ A_ctrl (quartic term is beneficial). Full confirmation requires n=4 with μ_4(FFS_ema) ≤ 2862.5.

---

## NS5-absorption argument

The NS5-absorption rule (memory entry: `sgld_annealed_noise_pre_ns_family_neg_at_r5.md`) states: "Additive pre-NS5 gradient modifiers are absorbed by NS5 orthogonalization." This hypothesis is **not** in that family. We are modifying the NS5 polynomial kernel itself — the `(a, b, c)` triple that defines what polynomial is iterated. This is not a pre-NS5 modification; it changes the convergence properties of the orthogonalization operator. There is no absorption mechanism that can neutralize a change to the polynomial being applied.

The analogous rule for "post-NS5 absorption" also does not apply: we are not adding a wrapper around NS5 output, we are changing what NS5 computes.

The relevant analogy: changing the learning rate schedule is not "absorbed" by the optimizer update rule even though both affect parameter updates. Similarly, changing the NS5 polynomial is a fundamental change to what orthogonalization means in this optimizer.

---

## References

1. **Keller Jordan et al., "Muon: An optimizer for hidden layers in neural networks"** (2024). Introduces NS5-based Muon optimizer with empirically-optimized coefficients `(3.4445, −4.7750, 2.0315)` for NanoGPT. These are the B★ values. https://kellerjordan.github.io/posts/muon/

2. **Bernstein & Newhouse, "CANS: Chebyshev-Optimized Newton-Schulz for Communication-Efficient Distributed Optimization"** (2025). arxiv:2506.10935. Proves theoretically that NS5 coefficients should maximize ϕ'(0) subject to convergence constraints via the Remez algorithm; validates on NanoGPT (Figure 5). Confirms that coefficient choice matters materially at fixed iteration budget.

3. **Higham, "Functions of Matrices: Theory and Computation"** (2008), Ch. 8. Classical analysis of polynomial iteration for the polar decomposition — the mathematical foundation for why `(a, b, c)` must satisfy specific conditions for convergence.

4. **Our codebase baseline run:** W&B `fjyckuu1` — μ_4(FFS_ema)=2875.0, val/loss_mu4=3.27007. Merge gate: FFS_ema ≤ 2862.5.

---

## Research state update

**Current best explanation for plateau:** The optimizer's core orthogonalization polynomial has never been tested with anything other than an arbitrary default `(2, −1.5, 0.5)`. At `ns_iter=6`, the polynomial's convergence properties directly determine update quality for all Muon parameter groups. This is a fundamental untested axis.

**Ruled-out paths:** Pre-NS5 gradient modifiers (absorbed), post-NS5 wrappers (absorbed), NS5 iteration count scheduling, per-group iteration depth (orthogonal WIP), LN init, weight init perturbations, cosine-mu, rope-base, all cooldown shape variants.

**Open uncertainty:** Whether KJ's coefficients were overfit to a specific stack (their `ns_iter=5`, no SOAP, different LR schedule) and generalize to our `ns_iter=6` + SOAP stack.

**Next discriminating experiment after this:** If B★ wins, combine with alphonse's per-group iteration depth (KJ coefficients + attn=7/mlp=5) as a compound experiment. If B★ ties/loses, the polynomial shape axis is closed and we should move to a different level of abstraction (e.g., momentum β schedule or SOAP eigenbasis update frequency).

**Stop condition:** If all four cells A/B/C/D produce FFS_ema ∈ {2875±3}, close the coefficient-shape axis entirely. Do not escalate to CANS per-step varying coefficients without first confirming the static KJ point provides signal.
