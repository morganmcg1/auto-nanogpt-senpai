# Research Ideas — 2026-05-25 17:00

Generated for cycle 71 mid-246 state. Baseline PR #613: val=3.26776, ffs=3000. Three idle students: g1r2-alphonse, g1r2-askeladd, g1r2-thorfinn. Three fresh hypotheses — all confirmed absent from the 311-PR corpus.

---

## Hypothesis 1 — g1r2-alphonse: ADOPT_AUX

### Mechanism name and class layer

**ADOPT_AUX** — adaptive optimizer convergence fix applied to the AdamW auxiliary parameter groups (embed, lm_head, scalars). Mechanism class: **non-Muon-routing second-moment update ordering**.

The key insight in ADOPT is that standard Adam's proof of convergence breaks because it divides the current gradient by the current second-moment estimate v_t^{1/2} — but v_t already incorporates today's gradient, creating a circular dependency that violates the theoretical convergence bound. ADOPT fixes this by using the *previous* second-moment estimate v_{t-1}^{1/2} when computing the normalized update, then updating v_t afterward. This achieves optimal O(1/√T) convergence with any β2 choice rather than requiring β2 → 1.

In practice this means: step 1 is a special case (no prior v available, falls back to normalized gradient); from step 2 onward the update uses v_{t-1} stale estimate, then v is updated to v_t, then momentum is accumulated. The resulting optimizer is a drop-in for AdamW on auxiliary groups with no architectural changes.

### arxiv reference

**ADOPT: Modified Adam Can Converge with Any β2 with the Optimal Rate**
Taniguchi, Harada, Minegishi, Oshima, Jeong, Nagahara, Iiyama, Suzuki (University of Tokyo / NTT)
NeurIPS 2024 — arxiv:2411.02853
https://arxiv.org/abs/2411.02853

Key result: ADOPT matches or slightly exceeds AdamW empirically across vision and language tasks, with the theoretical guarantee that any β2 is valid. The authors demonstrate that the second-moment delay is negligible in practice (β2=0.9999 is no longer degenerate) while fixing the mathematical pathology.

### Categorical novelty argument

Anti-duplication grep patterns — all confirmed zero matches across 311-PR corpus:

- `ADOPT` — no match
- `adopt_optimizer` / `ADOPT_OPTIMIZER` — no match
- `v_{t-1}` / `stale.*second.*moment` / `delayed.*second.*moment` — no match
- `previous.*second.*moment` / `second.moment.delay` — no match
- `taniguchi` / `2411.02853` — no match

Structural distinctness from prior closed PRs:

- **#817 NAdamW** (merged): Nesterov lookahead on first moment (momentum), no change to second-moment update ordering — orthogonal mechanism
- **#816 AdEMAMix** (Arm closed in cycle 70): Dual EMA blend adding slow exponential average alongside fast β1 momentum — different moment construction, not update ordering
- All AdamW sweeps in corpus (β1/β2/lr/wd): Vary hyperparameter values within standard Adam update rule, never alter the v_{t-1} vs v_t ordering itself
- ADOPT targets only the auxiliary groups — Muon handles body weights — so this is a pure aux-group intervention with zero interaction with the NS5 path

### Implementation sketch

File: `train_gpt_simple.py` — replace the auxiliary AdamW step function with ADOPT. Estimated ~25 LOC new code (one helper class or inline in the optimizer step).

```python
# ADOPT step — replaces AdamW on embed/lm_head/scalar groups
# Insert as a separate optimizer or override step() for aux param groups

def adopt_step(p, grad, state, lr, beta1, beta2, eps, weight_decay):
    if len(state) == 0:
        state['step'] = 0
        state['exp_avg'] = torch.zeros_like(p.data)
        state['exp_avg_sq'] = torch.zeros_like(p.data)

    exp_avg, exp_avg_sq = state['exp_avg'], state['exp_avg_sq']
    state['step'] += 1
    t = state['step']

    # Weight decay (decoupled, same as AdamW)
    p.data.mul_(1 - lr * weight_decay)

    if t == 1:
        # Step 1: no prior v available — use current v for normalization
        exp_avg_sq.mul_(beta2).addcmul_(grad, grad, value=1 - beta2)
        exp_avg.mul_(beta1).add_(grad, alpha=1 - beta1)
        update = exp_avg / (exp_avg_sq.sqrt().add_(eps))
    else:
        # Steps 2+: use STALE v_{t-1} for normalization, THEN update v_t
        update = exp_avg / (exp_avg_sq.sqrt().add_(eps))   # uses v_{t-1}
        exp_avg_sq.mul_(beta2).addcmul_(grad, grad, value=1 - beta2)  # now v_t
        exp_avg.mul_(beta1).add_(grad, alpha=1 - beta1)

    p.data.add_(update, alpha=-lr)
```

Env vars:
- `ADOPT_BETA2` — controls β2 for ADOPT aux groups (float, default disabled=0 means use standard AdamW)
- `ADOPT_BETA1` — optional override for β1 (default 0.9 matching existing aux config)

Disabled-check: `ADOPT_BETA2=0` (or unset) must produce bytewise-identical output to baseline AdamW.

### Arm structure

**Arm A**: `ADOPT_BETA2=0.95` — lower β2, faster second-moment tracking, lower bias from stale v
**Arm B**: `ADOPT_BETA2=0.99` — higher β2, matches conventional AdamW β2 default, tests whether the convergence fix matters more than the β2 value

Both arms apply ADOPT only to auxiliary groups (embed, lm_head, scalars), leaving Muon on body weights unchanged.

Kill gate: val/loss > 3.35 at step 500 → kill arm early.

### Structural distinction from prior closures

ADOPT differs from all prior optimizer PRs on two axes simultaneously:

1. **Update ordering**: No prior PR in the 311-PR corpus changes the ordering of v update vs v use in the Adam step. All AdamW variants use simultaneous v_t update and normalization.
2. **Aux-group targeting**: The intervention is isolated to the non-Muon groups. This avoids any interaction with the NS5 path, making it a clean test of whether the auxiliary optimizer is a bottleneck.

The mechanism being tested is: "does the Adam convergence-proof pathology (using v_t to normalize the gradient that just updated v_t) degrade final loss on the auxiliary groups, and does ADOPT's correction recover headroom?"

---

## Hypothesis 2 — g1r2-askeladd: RAND_SVD_MUON

### Mechanism name and class layer

**RAND_SVD_MUON** — randomized SVD low-rank gradient denoising applied to the gradient matrix *before* the NS5 orthogonalization step in Muon. Mechanism class: **pre-NS5 gradient conditioning / low-rank signal extraction**.

The mechanism: gradient matrices at each step contain a mix of signal (low-rank structure aligned with the loss landscape curvature) and noise (high-frequency, diffuse variance from minibatch sampling). Randomized SVD reconstructs only the top-k singular vectors efficiently, discarding the noisy tail. The denoised low-rank reconstruction is then passed to NS5 for orthogonalization and the polar-factor update. This is different from momentum smoothing (which averages over time) — it acts in the spatial/spectral dimension of the gradient matrix.

PowerSGD (Vogels et al. 2019) demonstrated that low-rank gradient approximations can substantially reduce noise in distributed training. Here we repurpose the mechanism as a per-step gradient conditioner rather than a compression tool.

### arxiv reference

**PowerSGD: Practical Low-Rank Gradient Compression for Distributed Optimization**
Vogels, Karimireddy, Jaggi
NeurIPS 2019 — arxiv:1905.13727
https://arxiv.org/abs/1905.13727

Key result: rank-4 approximation captures >95% of gradient variance on transformer layers while discarding noisy tail, enabling faster convergence on communication-constrained settings. The randomized SVD via random projection + QR + small SVD is the core algorithmic primitive.

Supporting reference: **Randomized algorithms for matrices and data** (Halko, Martinsson, Tropp, 2011, SIAM Review) — the theoretical foundation for randomized power iteration used in the implementation.

### Categorical novelty argument

Anti-duplication grep patterns — all confirmed zero matches across 311-PR corpus:

- `RAND_SVD` / `RSVD` / `randomized.*svd` / `randomized_svd` — no match
- `powersgd` / `PowerSGD` / `power_sgd` — no match
- `low.rank.*gradient` / `gradient.*denoise` / `gradient.*low.rank` — no match
- `vogels` / `1905.13727` — no match
- `random.*projection.*gradient` / `grad.*rank` — no match

Structural distinctness from prior closed PRs:

- **#1139 GaLore** (closed): Projects *parameters* into a permanent low-rank subspace for memory savings — not a per-step gradient filter, fundamentally different purpose and mechanism
- **#972 MUON_GRAD_POWER** (merged): Element-wise power transform on gradient values g → sign(g)|g|^p — spectral domain intervention but operates element-wise, not via SVD decomposition
- **#987 MUON_GRAD_CG_DECORRELATE** (closed): Decorrelates gradient from prior momentum via conjugate-gradient-style subtraction — temporal decorrelation, not spatial low-rank projection
- All NS5 coefficient work (#1184 Polar Express, prior coefficient sweeps): Modify the NS5 iteration itself, not the input gradient

### Implementation sketch

File: `train_gpt_simple.py` — insert denoising function before NS5 call in Muon step. Estimated ~30 LOC.

```python
def rand_svd_denoise(grad, rank):
    """Low-rank reconstruction of gradient via randomized SVD (Halko et al.)."""
    m, n = grad.shape
    # Random projection to reduce from n cols to rank
    omega = torch.randn(n, rank, device=grad.device, dtype=grad.dtype)
    Y = grad @ omega               # (m, rank) — random projection
    Q, _ = torch.linalg.qr(Y)     # (m, rank) — orthonormal basis for column space
    B = Q.mT @ grad                # (rank, n) — small matrix in projected space
    # Small SVD on rank×n matrix (cheap: rank << n)
    Uhat, S, Vh = torch.linalg.svd(B, full_matrices=False)
    U = Q @ Uhat                   # (m, rank) — lift back to full space
    # Reconstruct top-rank approximation
    return (U[:, :rank] * S[:rank].unsqueeze(0)) @ Vh[:rank, :]

# In Muon.step, before calling zeropower_via_newtonschulz5:
rsvd_rank = int(os.environ.get('RSVD_RANK', '0'))
if rsvd_rank > 0 and grad.ndim == 2:
    grad = rand_svd_denoise(grad, rsvd_rank)
update = zeropower_via_newtonschulz5(grad, steps=ns5_steps)
```

Env vars:
- `RSVD_RANK` — rank k for low-rank reconstruction (0=disabled, baseline bytewise identity)
- Disabled-check: `RSVD_RANK=0` must be bytewise identical to baseline.

Wall-clock note: randomized SVD on 768×768 with rank 4 or 8 is cheap (random matmul + QR on small matrix + tiny SVD). Expected overhead < 2% step time.

### Arm structure

**Arm A**: `RSVD_RANK=4` — aggressive denoising, retains only top-4 singular components
**Arm B**: `RSVD_RANK=8` — moderate denoising, retains top-8 singular components (captures more gradient structure, less noise reduction)

Both arms apply to all 2D weight matrices in the Muon parameter group (body weights: QKV, proj, MLP).

Kill gate: val/loss > 3.35 at step 500, or NaN gradient → kill arm early.

### Structural distinction from prior closures

RAND_SVD_MUON differs on two axes:

1. **Spatial vs temporal**: Gradient denoising via SVD acts in the matrix spectral dimension (per-step), whereas momentum acts in the temporal dimension (across steps). These are orthogonal signal extraction strategies.
2. **Pre-NS5 input conditioning**: The intervention happens before NS5 sees the gradient. NS5 then orthogonalizes the already-denoised low-rank-reconstructed gradient. This is distinct from modifying NS5's coefficients, adding noise between NS5 iterations, or modifying the post-NS5 output.

The mechanism being tested is: "does the noisy tail of the gradient matrix (beyond top-k singular components) harm NS5's orthogonal polar-factor approximation, and does discarding it before NS5 improve final convergence?"

---

## Hypothesis 3 — g1r2-thorfinn: SWD_MUON

### Mechanism name and class layer

**SWD_MUON** — spectral weight decay applied to Muon body weight matrices *after* the NS5 update, subtracting a rank-1 spectral shrinkage term proportional to the dominant singular value. Mechanism class: **post-NS5 weight regularization via spectral radius reduction**.

Standard weight decay (L2 / Frobenius) shrinks all singular values isotropically by a factor (1 - wd). Spectral weight decay instead targets only the dominant singular direction: after the Muon step applies the polar-factor update, SWD subtracts `wd_spec * σ_max * u1 @ v1^T` from the weight matrix, where u1, v1 are the top left/right singular vectors. This selectively reduces the spectral radius (largest singular value) without touching the remaining spectrum.

Motivation: neural network weight matrices in transformers tend to develop large dominant singular values that concentrate representational capacity and can destabilize training dynamics (Yunis et al. 2024 showed spectral dynamics govern generalization in deep networks). Reducing σ_max per-step after the Muon update creates a soft spectral norm constraint that counteracts this growth without the full computational cost of spectral normalization.

### arxiv references

**Primary — spectral dynamics motivation:**
**Approaching Deep Learning through the Spectral Dynamics of Weights**
Yunis, Garg, Frankle, Ma (2024) — arxiv:2408.11804
https://arxiv.org/abs/2408.11804
Key result: dominant singular values of weight matrices drive generalization; controlling spectral radius improves training stability.

**Secondary — spectral normalization foundation:**
**Spectral Normalization for Generative Adversarial Networks**
Miyato, Kataoka, Koyama, Yoshida (ICLR 2018) — arxiv:1802.05957
https://arxiv.org/abs/1802.05957
Key result: dividing by σ_max enforces Lipschitz continuity; the power iteration method for efficient σ_max estimation.

**Note on efficiency**: Full SVD on each 768×768 weight matrix each step is expensive. Implementation should use a single power iteration step to estimate u1, σ_max, v1 rather than full SVD. Power iteration converges for the top singular pair in 1-3 steps starting from warm-started vectors.

### Categorical novelty argument

Anti-duplication grep patterns — all confirmed zero matches across 311-PR corpus:

- `SWD` / `SWD_MUON` / `spectral_wd` / `spectral.weight.decay` / `spectral.*decay` — no match
- `sigma_max` / `sigma.max` / `dominant.*singular` / `spectral.*shrink` — no match
- `rank.1.*subtract` / `u1.*v1` / `rank1.*spectral` — no match
- `miyato` / `1802.05957` / `yunis` / `2408.11804` — no match
- `spectral.norm.*weight.decay` / `sn_wd` — no match

Structural distinctness from prior closed PRs:

- **#601 FROBENIUS_WD** (never-ran PR): Isotropic L2 weight decay on all singular values equally — SWD is rank-1 targeted at σ_max only, not isotropic
- **#76/#78 Contra-Muon** (merged): Operator-norm-normalized full weight contraction — applies a scalar multiplier to the full weight matrix based on the operator norm, not a rank-1 spectral direction subtraction
- **#972 MUON_GRAD_POWER** (merged): Acts on gradient before optimizer step, not on weight after update — different intervention point
- **#1186 RIEMANNIAN_MUON_MOMENTUM** (in-flight): Modifies momentum geometry on the Stiefel manifold — pre-step manifold-geometry intervention vs post-step weight-space regularization
- All NS5 modifications: Act inside the orthogonalization step, not on the weight matrix post-update

### Implementation sketch

File: `train_gpt_simple.py` — add spectral WD function, call after each Muon body-weight update. Estimated ~25 LOC.

```python
# Warm-started power iteration for top singular pair — cheap (1-3 steps)
_swd_u_cache = {}  # keyed by param id, stores (u, v) from previous step

def spectral_wd_rank1(weight_data, wd_spec, param_id, n_power_iter=2):
    """Subtract wd_spec * sigma_max * u1 @ v1^T from weight in-place."""
    m, n = weight_data.shape
    # Warm-start from previous step's singular vectors
    if param_id in _swd_u_cache:
        u, v = _swd_u_cache[param_id]
    else:
        u = torch.randn(m, 1, device=weight_data.device, dtype=weight_data.dtype)
        u = u / u.norm()
        v = torch.randn(n, 1, device=weight_data.device, dtype=weight_data.dtype)
        v = v / v.norm()
    # Power iteration to estimate top singular pair
    for _ in range(n_power_iter):
        v = weight_data.mT @ u; v = v / v.norm()
        u = weight_data @ v;    u = u / u.norm()
    sigma_max = (u.mT @ weight_data @ v).item()
    _swd_u_cache[param_id] = (u.detach(), v.detach())
    # Rank-1 spectral shrinkage
    weight_data -= wd_spec * sigma_max * (u @ v.mT)

# In Muon.step, after applying update to each 2D param:
swd_spec = float(os.environ.get('SWD_SPEC', '0'))
if swd_spec > 0 and p.data.ndim == 2:
    spectral_wd_rank1(p.data, swd_spec, id(p))
```

Env vars:
- `SWD_SPEC` — spectral weight decay coefficient (0=disabled, baseline bytewise identity)
- `SWD_POWER_ITER` — number of power iteration steps (default 2, optional override)
- Disabled-check: `SWD_SPEC=0` must produce bytewise-identical output to baseline.

Wall-clock note: warm-started power iteration (2 steps) on 768×768 is ~2× matmul overhead per weight matrix per step. Expected overhead 3-6% step time — acceptable.

### Arm structure

**Arm A**: `SWD_SPEC=1e-4` — light spectral shrinkage, minimal disturbance to weight geometry
**Arm B**: `SWD_SPEC=1e-3` — moderate spectral shrinkage, actively suppresses σ_max growth each step

Both arms apply to all 2D weight matrices in the Muon parameter group (body QKV, proj, MLP weights).

Kill gate: val/loss > 3.35 at step 500, or σ_max diverging (> 100) → kill arm early.

### Structural distinction from prior closures

SWD_MUON differs from all prior regularization PRs on two axes:

1. **Rank-1 targeted vs isotropic**: Standard weight decay shrinks all singular values. SWD subtracts only the dominant rank-1 component, leaving the remaining spectrum untouched. This is a spectral-selective intervention.
2. **Post-NS5 weight-space regularization**: The intervention happens after Muon's polar-factor update has already been applied to the weight matrix. It is not a modification of the update direction (gradient or momentum) nor of the NS5 step itself — it acts on the weight matrix as a post-update correction.

The mechanism being tested is: "does the dominant singular value of Muon body weight matrices grow during training in a way that accumulates representational pathology, and does a rank-1 post-step spectral correction each step reduce final validation loss?"

---

## Anti-duplication summary

| Hypothesis | Key grep patterns | Corpus matches |
|---|---|---|
| ADOPT_AUX | ADOPT, adopt_optimizer, stale.*second.*moment, taniguchi, 2411.02853 | 0 |
| RAND_SVD_MUON | RAND_SVD, RSVD, powersgd, PowerSGD, low.rank.*gradient, 1905.13727, vogels | 0 |
| SWD_MUON | SWD, spectral_wd, spectral.*decay, sigma_max, dominant.*singular, miyato, 1802.05957, yunis, 2408.11804 | 0 |

All three hypotheses confirmed absent from the 311-PR corpus as of 2026-05-25.

## Mechanism class coverage

| Hypothesis | Mechanism class | Layer |
|---|---|---|
| ADOPT_AUX | Non-Muon aux optimizer convergence fix | Second-moment update ordering |
| RAND_SVD_MUON | Pre-NS5 gradient conditioning | Spatial/spectral low-rank denoising |
| SWD_MUON | Post-NS5 weight regularization | Spectral radius reduction |

All three are structurally distinct from the six saturated mechanism layers (NS5-coefficient, NS5-inter-noise, loss-side multiplicative reweighting, logit-space additive bias, LM-head routing, QKV fusion) and from the three in-flight axes (CAUTIOUS_MUON, RIEMANNIAN_MUON_MOMENTUM, MUON_POLAR_EXPRESS).
