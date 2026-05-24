# Research Ideas — 2026-05-24 03:30 UTC
Generated for: g1r1-fern (idle after PR #943 SWA closure)
Baseline: sr=2925, val/loss=3.266394 (PR #918, n=2 mean)
Win condition: sr ≤ 2912.5 OR (sr=2925 AND val < 3.266394)

---

## Hypothesis 1 (RECOMMENDED): Schedule-Free Body-Muon (AMUSE-style)

### Title
Schedule-Free parameter averaging wrapped around body-Muon NS5 update, replacing WSD cooldown entirely.

### Mechanism
The WSD cooldown-erosion pattern has been confirmed in 4 independent instances (SGDR #690, QHM #697, β_cov schedule #686, Polyak EMA #695): optimizer advantages accumulate during stable phase but collapse to zero during the 2275-step cooldown. Schedule-Free optimization (Defazio et al., arxiv 2405.15682) eliminates cooldown by maintaining a weighted running average of iterates (x_t) alongside a "live" sequence (z_t), evaluating gradients at an interpolation point y_t = (1-β)z_t + βx_t. AMUSE (Kim et al., arxiv 2605.22432) specifically integrates Muon's NS orthogonalization with Schedule-Free parameter averaging, proving theoretically that Muon accelerates progress along the river valley but amplifies dominant-direction noise — and that Schedule-Free averaging damps exactly that oscillation. This attacks the cooldown bottleneck at its root: instead of LR decay compressing optimizer advantages away, the averaged iterate x_t directly accumulates properly weighted history, so the final model is the average rather than the terminal point.

### Implementation Sketch
```python
# In PMuon.__init__: add buffers
for p in body_params:
    state['z'] = p.data.clone()      # live iterate
    state['x'] = p.data.clone()      # schedule-free average
    state['lr_sq_sum'] = 0.0         # Σ γ²_i for c_t

# In PMuon.step: replace standard update
for p in body_params:
    state = self.state[p]
    lr = current_lr  # constant at 0.040, no cooldown decay
    
    # Evaluate gradient at interpolation point y_t
    y_t = (1 - beta_sf) * state['z'] + beta_sf * state['x']
    p.data.copy_(y_t)  # temporarily set params to y_t
    # (gradient already computed at y_t from forward/backward pass)
    
    # Apply NS5 Muon direction to get update
    g_ns = newton_schulz5(p.grad, nsteps=12)  # direction only, ||·||_F ≈ sqrt(min(m,n))
    state['z'] = state['z'] - lr * g_ns       # live step
    
    # Update schedule-free average: c_t = γ²_t / Σγ²_i
    state['lr_sq_sum'] += lr ** 2
    c_t = lr**2 / state['lr_sq_sum']
    state['x'] = (1 - c_t) * state['x'] + c_t * state['z']
    
    # Inference / return uses x_t
    p.data.copy_(state['x'])

# Remove cooldown from LR schedule: hold constant at 0.040 through step 3250
# (no WSD decay; Schedule-Free averaging IS the convergence mechanism)
```

### Magnitude Budget
- NS5 polar direction: ||g_ns||_F ≈ √min(m,n) (direction-only, unchanged from baseline)
- z-update per step: lr × ||g_ns||_F = 0.040 × √min(m,n) — identical to baseline body-Muon at peak LR
- x-update per step: c_t × (z_{t+1} - x_t) where c_t = lr²/Σlr²_i ≈ 1/t for constant lr
- Effective update to x at step t: ≈ (1/t) × 0.040 × √min(m,n) — diminishing but accumulates correctly weighted
- vs baseline body-Muon during cooldown: baseline decays to 0.040 × (t_decay/total)^1.4 → 0; Schedule-Free x continues accumulating but with decaying c_t — no collapse
- No magnitude pathology: NS5 absorbs drift, c_t weighting is normalized by construction

### Cross-Axis Check
- Aux Schedule-Free: PR #623 CLOSED — aux AdamW + Schedule-Free, NOT body-Muon. ORTHOGONAL.
- Body-Muon + Schedule-Free: NEVER TESTED. Clear.
- Edward #977 (dual-EMA momentum): EMA inside the optimizer's update direction (β_fast/β_slow on momentum buffer). Schedule-Free is parameter-space averaging outside the optimizer — different level of abstraction. ORTHOGONAL.
- SWA #943 CLOSED: stochastic weight averaging applied at cooldown-start only, not full-training parameter averaging. ORTHOGONAL.
- Shampoo #985 (body replacement): preconditioner replacement, no averaging. ORTHOGONAL.
- Cooldown schedule #969 (askeladd): tunes power exponent of WSD decay. Schedule-Free replaces decay entirely — different hypothesis. ORTHOGONAL.
- PMuon γ_pre temporal schedule #958 (frieren): modifies pre-NS scaling during training. ORTHOGONAL.

### Expected EV Ranking
**8/10** — directly attacks the confirmed cooldown-erosion bottleneck with fresh theoretical backing (AMUSE), orthogonal to all 99 closed axes and all 8 in-flight, tractable (~40 lines modifying PMuon and LR schedule), strong external evidence from Schedule-Free literature showing WSD replacement works at LLM scale (ScheduleFree+ arxiv 2605.19095 outperforms WSD by 31% at 1000 tok/param).

### Reference Papers
- Kim et al. (2026). **AMUSE: Anytime MUon with Stable gradient Evaluation**. arxiv:2605.22432. Directly integrates Muon NS5 with Schedule-Free averaging; proves oscillation-damping theorem in river-valley loss landscape.
- Defazio et al. (2024). **The Road Less Scheduled**. arxiv:2405.15682. Original Schedule-Free SGD framework; establishes z/x/y triplet and c_t weighting; proves convergence without LR schedule.
- Defazio et al. (2026). **ScheduleFree+: Scaling Schedule-Free Learning to Large Language Models**. arxiv:2605.19095. Outperforms WSD by 31% at 1000 tok/param; validates Schedule-Free at GPT scale. NOTE: ScheduleFree+ itself requires major API refactoring; use the original SF-SGD framework from arxiv:2405.15682 as the wrapper.

---

## Hypothesis 2: Sophia-H Diagonal Hessian for Embed (Aux)

### Title
Replace AdamW denominator for embed parameters with Hutchinson diagonal Hessian estimate (Sophia-H), exploiting curvature geometry inaccessible to gradient-variance-based denominators.

### Mechanism
The 21-axis aux Adam family is saturated by exhausting every variant of gradient-second-moment denominator. However, the gradient second moment (E[g²]) is a proxy for curvature only when the loss is locally quadratic — it carries no information about the true diagonal Hessian. Sophia-H (Liu et al., arxiv 2305.14342) replaces the gradient variance denominator with a Hutchinson stochastic trace estimate of the diagonal Hessian, updated every k=10 steps via random probe vectors v ~ {±1}^d. The aux gradient i.i.d. finding (cosine ≈ -0.05, ||Δg||/||g|| ≈ 1.45) rules out Δg-autocorrelation-dependent methods — but Sophia-H exploits CURVATURE STRUCTURE (Hessian), not gradient temporal autocorrelation, so the i.i.d. constraint does not apply. Embed rows encode token identity and have heterogeneous curvature profiles (frequent tokens: shallow curvature; rare tokens: steep); per-element Hessian scaling can correctly differentiate these, unlike AdamW which only sees gradient variance.

### Implementation Sketch
```python
# In SophiaEmbed optimizer (new class, embed params only)
def step(self):
    for p in embed_params:
        state = self.state[p]
        g = p.grad
        
        # Update gradient EMA
        state['m'] = beta1 * state['m'] + (1 - beta1) * g
        
        # Hutchinson diagonal Hessian estimate every k steps
        if step_count % k == 0:
            v = torch.randint_like(g, 2) * 2 - 1  # Rademacher ±1
            # Hessian-vector product via double backward
            Hv = torch.autograd.functional.hvp(loss_fn, p, v)[1]
            h_new = v * Hv  # diagonal estimate: E[v * Hv] = diag(H)
            state['h'] = beta2 * state['h'] + (1 - beta2) * h_new.abs()
        
        # Sophia update: clamp denominator at rho to prevent division explosion
        update = state['m'] / torch.clamp(state['h'], min=rho)
        p.data -= lr_embed * update

# Hyperparameters: k=10, beta1=0.9, beta2=0.99, rho=0.01
# Scope: embed ONLY. lm_head handled by #964 (Muon-as-aux) or #953 (SOAP).
```

### Magnitude Budget
- AdamW baseline embed: lr_embed × ||g||_F / sqrt(v_t + ε) ≈ lr_embed × ||g||_F / σ_g (element-wise)
- Sophia-H: lr_embed × ||m_t||_F / E[h_i]. For well-conditioned embeddings, E[h_i] ≈ O(var(g)) ≈ σ²_g, so Sophia magnitude ≈ lr_embed × ||g||_F / σ²_g — larger by factor 1/σ_g if σ_g < 1.
- Clipping at ρ=0.01 bounds maximum element: |update_i| ≤ |g_i|/ρ = 100 × |g_i|. May need lr_embed reduction (try 0.3× of AdamW lr) on first run to compensate.
- Rare-token rows: steep h → small update (Sophia naturally regularizes high-curvature directions)
- Frequent-token rows: shallow h → larger update (Sophia amplifies low-curvature directions that Adam suppresses)
- Net: different directional scaling than AdamW, but bounded by ρ clip. Not a magnitude pathology.

### Cross-Axis Check
- "Sophia/Hutchinson Hessian" explicitly listed as OPEN in CURRENT_RESEARCH_STATE.md open aux frontier.
- Closed 21-axis aux Adam family: all use gradient second moment (g²) as denominator — AdamW, AMSGrad, Adan, NAdam, RAdam, LARS, LAMB, Lookahead, etc. Sophia uses diagonal Hessian (Hv product). MECHANICALLY DISTINCT. CLEAR.
- #964 nezuko (Muon-as-aux lm_head): different param group (lm_head vs embed), different optimizer (Muon vs Sophia). ORTHOGONAL.
- #953 tanjiro (SOAP lm_head): different param group. ORTHOGONAL.
- No in-flight PR targets embed with non-Adam denominator. CLEAR.

### Expected EV Ranking
**6/10** — mechanically sound, explicitly listed as open, directly addresses curvature blind-spot of saturated Adam family. Lower than H1 because: (1) embed is smaller than body; curvature correction of embed alone may have limited impact on total loss; (2) requires HVP computation adding ~10-15% overhead per k steps; (3) no prior evidence this helps specifically in NanoGPT-scale embed settings.

### Reference Papers
- Liu et al. (2023). **Sophia: A Scalable Stochastic Second-order Optimizer for Language Model Pre-training**. arxiv:2305.14342. 2× speedup vs Adam on GPT training; establishes Hutchinson diagonal Hessian update rule and ρ clipping; ablations show β₂ sensitivity.

---

## Hypothesis 3 (Contingent on #985 alphonse closing): PSGD-Kron Body Preconditioner

### Title
Replace body-Muon (NS5 polar map) with PSGD-Kron Lie-group Kronecker preconditioner — a distinct second-order approach from in-flight Shampoo (#985).

### Mechanism
Shampoo (#985 alphonse, in-flight) replaces PMuon by accumulating gradient outer-product covariance matrices (L_cov ≈ Σ G G^T, R_cov ≈ Σ G^T G) and taking their matrix square roots as preconditioners. PSGD-Kron (Pooladzandi & Li, arxiv 2402.04553) takes a fundamentally different approach: it maintains Kronecker-structured preconditioner matrices Q_L, Q_R constrained to connected Lie groups (e.g., triangular, diagonal, or full GL(n)) and updates them by minimizing a curvature-based loss function using Hessian-vector products rather than gradient outer products. The Lie group invariance property means the preconditioner is equivariant under parameter reparameterization — eliminating the need for damping hyperparameters that Shampoo requires. If Shampoo (#985) shows a clear win, PSGD-Kron would compound it; if Shampoo fails (likely due to gradient outer-product covariance being a poor Hessian proxy at NS5 step sizes), PSGD-Kron's HVP-based curvature criterion may succeed where covariance fails.

### Implementation Sketch
```python
# PSGD-Kron body optimizer (replace PMuon entirely)
class PSGDKron:
    def __init__(self, body_params, lr=0.040, precond_lr=0.1, k_update=10):
        for p in body_params:
            m, n = p.shape  # weight matrix dimensions
            state['Q_L'] = torch.eye(m)   # left Kronecker factor (Lie group)
            state['Q_R'] = torch.eye(n)   # right Kronecker factor (Lie group)
    
    def step(self):
        for p in body_params:
            g = p.grad
            # Preconditioned gradient: G_pre = Q_L^T @ g @ Q_R
            g_pre = state['Q_L'].T @ g @ state['Q_R']
            
            # Update preconditioner every k steps via Lie group gradient
            if step_count % k_update == 0:
                # Hessian-vector product: hvp = H @ vec(g_pre)
                v = torch.randn_like(g_pre)
                hvp = hessian_vector_product(loss, p, Q_L @ v @ Q_R.T)
                # Lie group gradient step on Q_L, Q_R
                # (see arxiv 2402.04553 Algorithm 1 for exact update rule)
                update_lie_group_preconditioner(state['Q_L'], state['Q_R'], g, hvp, precond_lr)
            
            p.data -= lr * g_pre  # apply preconditioned step
            # Note: no NS5 polar map needed — PSGD normalization plays that role

# Hyperparameters: lr=0.040, precond_lr=0.1, k_update=10
# CONDITIONAL: only assign if #985 (Shampoo) closes without win.
```

### Magnitude Budget
- PSGD-Kron with converged Lie group preconditioner: ||Q_L g Q_R||_F ≈ ||g||_F when Q_L, Q_R are at curvature-optimal solution (property of Lie group normalization)
- Step magnitude: lr × ||g||_F ≈ 0.040 × ||g||_F vs baseline 0.040 × √min(m,n)
- If ||g||_F >> √min(m,n): PSGD magnitude inflates — monitor first 100 steps. If ||g||_F ≈ √min(m,n) (typical for body gradients): matched magnitude.
- Unlike Shampoo (which can inflate 27-55× per PR #940 diagnostics): Lie group constraint bounds Q_L, Q_R to preserve Frobenius norm of preconditioned gradient asymptotically. Lower risk of magnitude explosion than Shampoo.
- Recommended: add norm clip at 1.5× √min(m,n) as safety valve on first run.

### Cross-Axis Check
- Shampoo #985 (alphonse, in-flight): both are body preconditioner replacements but mechanically distinct (gradient covariance accumulation vs Lie group HVP-based curvature). MUST wait for #985 to close before assigning. CONDITIONAL CLEAR.
- NS5 polar map closed axes: PSGD-Kron replaces NS5 entirely (no pre/post-NS modifications). Not a pre/post-NS intervention — CLEAR.
- Body WD, PMuon scalars, body LR closed axes: PSGD-Kron does not touch these unless used as drop-in. ORTHOGONAL.

### Expected EV Ranking
**6/10** (conditional) — strong theoretical basis (Lie group invariance eliminates damping), distinct from Shampoo's mechanism, lower magnitude-explosion risk than Shampoo. Lower score due to: (1) conditional on #985 closing; (2) ~80-line implementation with HVP overhead; (3) no prior runs in this codebase; (4) k_update tuning sensitivity unknown.

### Reference Papers
- Pooladzandi & Li (2024). **Curvature-Informed SGD via General Purpose Lie-Group Preconditioners**. arxiv:2402.04553. Establishes PSGD-Kron Lie group update rule; proves invariance property eliminates damping; reports strong results on LM tasks.

---

## Summary for Advisor

**#1 Recommendation for fern: Hypothesis 1 — Schedule-Free Body-Muon**

The cooldown-erosion bottleneck is the most empirically confirmed failure mode in this research programme (4 independent confirmations). Schedule-Free wrapping of the NS5 Muon update eliminates cooldown via parameter averaging rather than LR decay, attacking this root cause directly. AMUSE (arxiv 2605.22432, May 2026) provides direct theoretical validation of the Muon+Schedule-Free combination. The implementation is ~40 lines modifying PMuon and removing the WSD cooldown decay — tractable for one student in one PR. The magnitude budget is clean (NS5 direction unchanged at 0.040×√min(m,n); averaging c_t is normalized by construction). The axis is orthogonal to all 99 closed experiments and all 8 in-flight PRs. No close competitor exists in the current queue. EV: 8/10.

**Assignment:** fern, `body-muon-schedule-free`, 40-line PMuon modification + LR schedule change, β_sf=0.9, constant lr=0.040, no cooldown. Reference AMUSE arxiv:2605.22432 and Defazio arxiv:2405.15682.
