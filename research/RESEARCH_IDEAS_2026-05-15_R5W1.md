# Research Ideas — Track 3 Optimization, Wave 1 (auto-nanogpt-r5)

**Generated**: 2026-05-15
**Branch**: auto-nanogpt-r5
**Baseline**: `records/track_3_optimization/train_gpt_simple.py` — plain Muon (lr=0.035, wd=0.025, mu=0.95) + aux AdamW, 3350 steps, linear cooldown_frac=0.7.

Earlier researcher-agent ideas assumed the SOTA stack (Contra-Soft-Muon + SOAP) was already in `train_gpt_simple.py`. It is not. The starter is the bare public-baseline Muon. The hypotheses below build the proven public stacks first and explore fresh mechanisms in parallel.

## Wave-1 portfolio (8 students)

| Slug | Student | Type | Builds on | Target |
| ---- | ------- | ---- | --------- | ------ |
| `muonh-baseline` | r5-alphonse | EXPLOIT/REPRO | Reference `train_gpt_simple_muonh.py` | 3325 steps, mean < 3.278 (n=4) |
| `normuon-h` | r5-askeladd | EXPLOIT/REACH | NorMuon (arxiv 2510.05491) + hyperball | 3250 steps regime |
| `cooldown-shape-sweep` | r5-edward | EXPLORE-cheap | Plain Muon baseline | Better than linear cooldown |
| `lookahead-muon` | r5-fern | EXPLORE | Plain Muon baseline + Lookahead wrapper | Lower val, smoother |
| `ns-iter-sweep` | r5-frieren | EXPLORE-tune | Plain Muon baseline | Free win if 8/16/20 iters better |
| `muon-squared` | r5-nezuko | EXPLORE | Sharper NS poly (result #7) | 3325 steps regime |
| `soap-muon-mlp` | r5-tanjiro | EXPLORE-bold | SOAP-Muon paper for MLP weights | 3150 steps regime |
| `polyak-tail-avg` | r5-thorfinn | EXPLORE | Polyak/SWA averaging over training tail | Cheap free win on top of any optimizer |

## H1 — muonh-baseline (r5-alphonse)

**Hypothesis**: Reproducing MuonH (public result #5, 3325 steps, mean 3.2782 n=10) on our infra establishes the hyperball-constrained Muon foundation. The reference implementation lives at `records/track_3_optimization/results/20260430_muonh/train_gpt_simple_muonh.py`. Per-module init multipliers (×1.25 for attn.proj, ×3.0 for mlp.proj, ×1.5 for mlp.fc) plus the Frobenius-norm-preserving update make WD unnecessary.

**Method**: Replace the current `Muon` class in `train_gpt_simple.py` with `MuonH` per the reference. Apply the per-module init multipliers. Set MuonH lr=0.018, mu=0.95, no WD. Set per-group cooldown_frac (h=1.0, aux=0.4). `train_steps=3325`.

**Step budget**: 4 seeds at 3325 steps.

**Risk**: low (drop-in reproduction of a public result).

## H2 — normuon-h (r5-askeladd)

**Hypothesis**: NorMuonH (Adafactor-style row/col 2nd-moment preconditioning before NS, wrapped in hyperball) hit 3.2778 (n=10) at 3250 steps publicly. Per-axis variance normalization gives free curvature info without changing direction quality.

**Method**: Start from the MuonH reference. Inside `muon_update`, maintain row-variance EMA `r ∈ R^m` and column-variance EMA `c ∈ R^n` of the gradient with `beta2=0.95`. Before NS, divide grad by `sqrt(outer(r, c) + eps)`. Per-module init same as MuonH. lr=0.018.

**Step budget**: 2-arm screening at 1500 steps to verify finite gradients, then 8 seeds at 3250 steps.

**Risk**: implementation correctness of row/col EMA + correctness of division (numerical stability).

## H3 — cooldown-shape-sweep (r5-edward)

**Hypothesis**: The starter uses stable+linear cooldown with `cooldown_frac=0.7`. Schedule shape interacts with optimizer dynamics; a cosine or power-law cooldown may close the loss faster.

**Method**: Hold all of the baseline; only modify `set_hparams`. Test:
  - Linear, cooldown_frac=0.7 (baseline reference).
  - Cosine cooldown: `eta = 0.5*(1+cos(pi*(progress-(1-frac))/frac))` for the same 70% region.
  - Power-law, `eta = ((1-progress)/frac) ** alpha` for `alpha ∈ {1.2, 1.5, 2.0}`.
  - Trapezoidal: 5% warmup, 60% stable, 35% linear cooldown.

**Step budget**: each shape, 2 seeds at 3350 steps. Top shape → 4 more seeds confirmation.

**Risk**: low.

## H4 — lookahead-muon (r5-fern)

**Hypothesis**: Lookahead (Zhang et al. 2019, arXiv 1907.08610) maintains slow weights `phi = phi + alpha*(theta - phi)` every k inner steps. The smoother trajectory often yields better generalization at no inner-cost. Never tried on this benchmark.

**Method**: Wrap both AdamW and Muon optimizers. Every k=5 inner steps, push slow weights toward fast (or vice versa) with alpha=0.5. Implement by snapshotting `phi` per param before each inner cycle and interpolating after k steps. Build on plain Muon baseline.

**Step budget**: 1 seed at 1500 steps (smoke), then 4 seeds at 3350 steps if loss curve healthy. Optional: sweep k ∈ {3, 5, 10} and alpha ∈ {0.3, 0.5, 0.7} if first variant beats baseline.

**Risk**: Lookahead may help less when optimizer is already orthogonalized like Muon. Falsifiable in <2h.

## H5 — ns-iter-sweep (r5-frieren)

**Hypothesis**: Newton-Schulz iteration count = 12 was chosen "not optimizing for wallclock". Step-count benchmark doesn't care about wallclock, so the optimum may be 16-20 iterations (better orthogonalization → cleaner update direction → fewer steps to target). Conversely, 8 iterations might be enough.

**Method**: Vary `for _ in range(N)` inside `zeropower_via_newtonschulz5` over N ∈ {6, 8, 10, 12, 16, 20}. Baseline lr=0.035 wd=0.025. 1500-step screening per N, then 4-seed confirmation at 3350 steps for the best 2.

**Risk**: very low.

## H6 — muon-squared (r5-nezuko)

**Hypothesis**: Muon² (arxiv 2604.09967) uses a sharper sign-of-singular-values polynomial than the (2, -1.5, 0.5) iteration. Result #7 attained 3.2752 (n=1) at 3325 steps with lr=0.10, wd=0.0125, β2=0.95, ε=1e-10. A faithful Muon² implementation may match or beat Muon at the same step count.

**Method**: Replace the inner NS polynomial in `zeropower_via_newtonschulz5` with the Muon² coefficients from the paper (degree-5 polynomial with sharper transition). Keep number of iterations the same. Use lr=0.10, wd=0.0125 (paper-recommended) on Muon. Aux Adam unchanged but with `β2=0.95, ε=1e-10`.

**Step budget**: 2 seeds at 1500 (smoke), 4 seeds at 3325 steps for confirmation.

**Risk**: Coefficient correctness — the polynomial must keep operator norm ≤ 1 to avoid divergence. Falsifiable quickly.

## H7 — soap-muon-mlp (r5-tanjiro)

**Hypothesis**: SOAP-Muon (Vyas et al.) applied to MLP weights only attained 3.2776 (n=4) at 3150 steps publicly (result #14). SOAP rotates gradients into the Shampoo eigenbasis before Muon's NS step, exploiting second-order structure. MLP `fc` and `proj` weights are the largest tensors, so even a partial application produces strong gains.

**Method**: Add SOAP preconditioning before NS for `mlp.fc.weight` and `mlp.proj.weight` only. Maintain left and right Gram matrices `L ∈ R^{m×m}`, `R ∈ R^{n×n}` with EMA β=0.95. Every `precond_freq=10` steps, eigendecompose `L` and `R`, rotate the grad into the eigenbasis, run Muon NS, rotate back. Keep aux AdamW unchanged. lr=0.035, wd=0.025.

**Step budget**: 1 seed at 1500 (smoke), then 4 seeds at 3300 steps for confirmation.

**Risk**: Implementation complexity. Numerical stability of eigendecomp. Document SOAP precondition cycle.

## H8 — polyak-tail-avg (r5-thorfinn)

**Hypothesis**: SWA / Polyak averaging over the last 10-20% of training is a free improvement orthogonal to optimizer choice. Maintain `phi_avg = (1-mu)*phi_avg + mu*phi` for the last `frac=0.15` of training and evaluate with `phi_avg`. Cheap, never tried here.

**Method**: After step `(1-frac)*train_steps`, accumulate an EMA of model parameters at every step with mu ∈ {1/k, 1/(k+1), ...} (uniform tail average) and at validation evaluate using the EMA shadow. Build on baseline Muon. Test frac ∈ {0.1, 0.2, 0.3}, k variants.

**Step budget**: 1 seed at 1500 (smoke + EMA logging), then 3 seeds × 3 fracs at 3350 steps.

**Risk**: low. The benchmark predeclares step count and reports loss at that step, so SWA-style evaluation is legal as long as the EMA decision is made before training.

---

## Wave-2 reserve (after first results)

Pending wave-1 outcomes:
- Contra-Muon on Muon stack (if MuonH lands, layer Contra on top).
- MuLoCo outer Nesterov wrap.
- PSGD-Kron preconditioner.
- Schedule-free Muon (Polyak weight averaging baked into LR scaling).
- Per-parameter-type momentum/lr coupling.
- u/w-floor hyperball variant (skylight001 setup).
