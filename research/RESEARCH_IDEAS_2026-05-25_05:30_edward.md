# Edward Hypotheses — 2026-05-25 05:30

Baseline: PR #918, val=3.266394, sr=2925
Config: --muon_lr 0.040 --ema_beta 0.95 --ema_warmup_steps 1750 --ema_beta_target 0.99

Diversification constraint: away from schedule/EMA-buffer work (Edward's recent focus:
#1107 polar-interp, #1123 asym-gamma, cooldown/EMA PRs). Targeting NS5 internals,
preconditioner spectral properties, gradient processing.

---

## H1 — Spectral-scaling exponent scan (rows/cols exponent: 0.5 baseline)

**Mechanism.** After NS5 polar factorization the update is scaled by
`polar * (max(1, rows/cols)**0.5)`. This 0.5 exponent equates to the geometric mean of
isotropic and full spectral compensation and has NEVER been varied. The effective per-layer
LR scales as `muon_lr * exponent_factor`, so for a typical 768x3072 body weight
(ratio=0.25, scale=0.5) the exponent controls a ~30% multiplicative range at the update
level. Exponent=0.0 removes all aspect-ratio compensation; exponent=1.0 fully compensates;
exponent=0.5 is the current undiscovered default.

**Arms.**
- Arm A: exponent=0.0 — no aspect-ratio scaling, polar output enters at unit magnitude
- Arm B: exponent=1.0 — full spectral compensation (rows/cols direct scale)

Both arms keep all other hyperparameters at baseline. Change is 1 line:
`update = polar * (max(1, grad.size(-2) / grad.size(-1)) ** EXPONENT)`.

**Magnitude budget.** For the largest body weight (768x3072, ratio=0.25):
- Baseline (0.5): scale = 0.25^0.5 = 0.5; effective LR factor = 0.5
- Arm A (0.0): scale = 0.25^0.0 = 1.0; 2x relative to baseline
- Arm B (1.0): scale = 0.25^1.0 = 0.25; 0.5x relative to baseline

For square weights (ratio=1.0) all three are identical; only non-square layers differ.
No interaction with the u/w-floor: if `||update||/||weight|| < 0.35` after scaling,
floor fires and rescales — so the floor partially absorbs extreme exponents.

**Cross-axis check.** Closed-axes review: NS coefficient scan (#939, a/b/c ratio),
NS iter scan (#914, 5–20 iters), gamma scan (#908/#942), beta_cov scan (#971) — none
tested the post-polar spectral-scaling exponent. Clean axis.

**Prior (WIN / Marginal / NULL / Catastrophic): 25 / 30 / 40 / 5.**
Rationale: the exponent was chosen by analogy with random matrix theory without ablation;
either direction changes effective LR asymmetrically across layers, which could help or
create layer-wise imbalance. 40% NULL because the floor partially absorbs the change.

---

## H2 — beta_cov warmup from 0→0.95 over first 300 steps

**Mechanism.** The covariance EMAs L_cov, R_cov are initialized at zero and immediately
updated with `L_cov.mul_(beta_cov).add_(g32 @ g32.T)`. With beta_cov=0.95 fixed, the EMA
is cold-start-biased for the first ~1/(1-0.95)=20 steps, after which early gradients
receive disproportionate weight (recency bias inverted). A linear warmup from beta_cov=0
at step 0 to beta_cov=0.95 at step 300 replaces the implicit beta-bias correction with
an explicit schedule: at step 1 the EMA is just the raw outer product; by step 300 it
matches the steady-state smoothing. This is analogous to Adam's bias correction but
applied to the preconditioner covariance.

**Arms.**
- Arm A: linear warmup beta_cov: 0→0.95 over steps 1–300 (fast convergence to steady-state)
- Arm B: linear warmup beta_cov: 0→0.95 over steps 1–750 (slower, more conservative)

Implementation: ~8 LOC — add `beta_cov_schedule` to group defaults; in `step()` compute
`effective_beta = min(group["beta_cov"], step / warmup_steps * group["beta_cov"])`.
State tracking: add `step_count` to `state[p]` or derive from a shared group counter.

**Magnitude budget.** Early steps: beta_cov=0 means L_cov=g@g.T (raw gram, no EMA decay).
The `matrix_neg_power(L_cov, 0.4)` still runs via eigendecomp; very small eigenvalues are
clamped at eps=1e-12, so near-zero cov at step 1 produces large L_neg entries. The eps
clamp prevents explosion, and the NS5 polar step re-normalizes. Net effective-LR change
vs baseline: ~1.1–1.4x during warmup window only; steady-state identical. No interaction
with the u/w-floor other than early-step floor-fire rate changing.

**Cross-axis check.** Closed axes: beta_cov=0.80/0.90/0.95/0.99 scan (#971, static values
only), no schedule or warmup variant tried. Clean axis. Distinct from param-EMA warmup
(#918 merged) and from beta_cov final value.

**Prior: 30 / 30 / 35 / 5.**
Rationale: bias correction for Adam-style second moment is well-motivated; here the
covariance EMA is a slower-moving preconditioner so the cold-start effect persists longer.
The warmup addresses a real initialization asymmetry. Highest credence hypothesis.

---

## H3 — TARGET_UW floor scan (0.35 baseline)

**Mechanism.** The u/w-floor enforces `||update||_F / ||weight||_F >= TARGET_UW=0.35` by
rescaling the update upward when the polar output is small relative to weight norm. This
floor was introduced in the "skylight" PR and has NEVER been ablated. It acts as a
minimum effective-LR guarantee per layer. Reducing it (e.g., 0.20) lets the optimizer
follow the natural polar magnitude when it's small — potentially for well-converged layers
late in training. Increasing it (e.g., 0.50) forces larger steps on all layers.

**Arms.**
- Arm A: TARGET_UW=0.20 — lower floor, let small updates pass through
- Arm B: TARGET_UW=0.50 — higher floor, more aggressive minimum step

Implementation: 1 constant change. The `floor_fired_count` diagnostic already logged;
W&B metric `muon/floor_fired_frac` directly observes whether the floor is binding.

**Magnitude budget.** If floor fires on fraction f of params each step:
- Arm A (0.20): floor fires less often; params where ratio was 0.20–0.35 now pass through
  at natural magnitude (reduction ~0.6x for those params)
- Arm B (0.50): floor fires more often; params where ratio was 0.35–0.50 now forced up
  (increase ~1.4x for those params)
No change to params where floor is not binding. Net update magnitude change depends on
floor-fire rate, which the existing W&B diagnostic makes observable.

**Cross-axis check.** TARGET_UW value scan: never run. The floor mechanism itself was
introduced as a package deal in the skylight baseline merge; individual floor threshold
values have never been tested. Clean axis.

**Prior: 20 / 30 / 45 / 5.**
Rationale: the floor value was likely set by analogy rather than by ablation; it could be
suboptimal in either direction. NULL is most likely because 0.35 may already be well-
calibrated, but if the floor fires frequently on under-converged layers, 0.50 could help.

---

## H4 — mu (momentum decay) schedule during cooldown only

**Mechanism.** mu=0.95 (Nesterov momentum) is fixed throughout training. During the
cooldown phase (last ~20% of steps, where LR decays to 0), the EMA lookahead
`update = grad.lerp_(momentum, mu)` effectively averages over 1/(1-0.95)=20 past
gradients. Increasing mu to 0.97–0.99 during cooldown increases the effective window to
33–100 steps, acting as a form of late-stage gradient averaging. This exploits the
insight that near convergence, gradients are less noisy but more correlated — wider
averaging should smooth the final descent without the stochastic variance of a shorter
window.

**Arms.**
- Arm A: mu linearly ramps 0.95→0.97 over the last 20% of steps (cooldown window)
- Arm B: mu linearly ramps 0.95→0.99 over the last 20% of steps

Implementation: ~5 LOC. In `step()`: if `step > cooldown_start`, compute
`mu = 0.95 + (target_mu - 0.95) * (step - cooldown_start) / cooldown_len`.
Cooldown start is already tracked in the training loop.

**Magnitude budget.** mu controls momentum-vs-grad blend in the Nesterov update only.
No change to L_cov/R_cov, spectral scaling, or the u/w-floor. During cooldown with
mu=0.99, effective step approaches momentum (near-zero fresh gradient weight); the polar
step still normalizes, so the magnitude effect enters only through the direction passed to
NS5. Low magnitude perturbation.

**Cross-axis check.** Closed axes: mu=0.85/0.90/0.95 static scan (#930, all training);
QHM (additive Nesterov decomposition, closed); heavy-ball (closed). No cooldown-specific
mu schedule tried. Clean axis. Note: body-grad cosine ≈ 0.13–0.35 so gradients are
non-iid; widening the EMA window may help or may lag behind the signal shift at cooldown.

**Prior: 20 / 25 / 50 / 5.**
Rationale: the mechanism is sound but the effect size is likely small. The cooldown window
is short and the optimizer's polar step already imposes direction normalization; the
momentum schedule only affects the direction input, not its magnitude. NULL most likely,
but a 20% WIN probability justifies a fast arm.

---

## Ranking

H2 (beta_cov warmup) > H1 (spectral exponent) > H3 (TARGET_UW floor) > H4 (mu cooldown)

H2 targets a real initialization asymmetry that no prior PR has addressed and is
mechanistically tight. H1 has the largest potential effect size but is partially absorbed
by the floor. H3 and H4 are clean axes with smaller expected effect.
