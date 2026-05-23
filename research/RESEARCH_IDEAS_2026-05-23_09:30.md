# Research Ideas — 2026-05-23 09:30

Ranked by expected value given the current SOAP+Muon-NS6+musoft+ramp-down-WD baseline
(μ=3.261221, σ_single=0.000593, n=4; n=4 merge gate μ≤3.259221).

Mandatory stack flags: `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down
--lr_scalars 0.03 --depth_init_mode musoft`

---

## ★ ADVISOR ADDENDUM (post-researcher review, 2026-05-23 ~09:35Z)

**Ideas 1 and 10 are MOOT — based on a researcher error.**

Verification from `records/track_3_optimization/train_gpt_simple.py` line 570:
```python
SOAP_MLP_SUFFIXES = (".mlp.fc.weight", ".mlp.proj.weight")
SOAP_ATTN_SUFFIXES = (".attn.q.weight", ".attn.k.weight", ".attn.v.weight", ".attn.proj.weight")
```

Line 587: `soap_suffixes = self.SOAP_MLP_SUFFIXES + (self.SOAP_ATTN_SUFFIXES if soap_attn else ())`

**SOAP is unconditionally enabled on MLP weights.** The `--soap_attn` flag only adds attn to the SOAP scope. With `--soap_attn` (mandatory baseline flag), SOAP is preconditioning ALL body 2D weights — MLP AND attn.

Therefore:
- **Idea 1 (SOAP on MLP path)**: already in baseline. Skip.
- **Idea 10 (AdaFactor on MLP)**: would replace SOAP on MLP rather than augment, but this is testing a *lighter* preconditioner against SOAP's own incumbency — likely strictly worse. Skip.

**Implication for #840 Cell E (MLP-only scope) winning over Cell B (all-scope):** The original "MLP lacks SOAP, so adding mechanism there is more productive" mechanism (advisor accepted from student in #840 review) is INCOMPLETE. Both paths have SOAP. The MLP-only advantage of dual-EMA injection must come from a different mechanism — possibly:
- (a) attn projections feed into softmax, making the attention pattern more sensitive to slow-EMA injection magnitudes (early training instability)
- (b) SOAP-on-attn has trust-gate (`--soap_trust_threshold`) that interacts with dual-EMA differently than SOAP-on-MLP's untrusted SOAP
- (c) Random variance in n=1 — Cell E might be a lucky seed; n=4 confirm in flight will resolve

Should not affect the n=4 confirm decision (E n=1 is below merge gate; if it replicates, mechanism interpretation is secondary to the empirical signal).

**Refined priority order (post-addendum):**

| Rank | Idea | Status |
|------|------|--------|
| 1 | Idea 4 — Muon WD sweep on body matrices | ★ Top — body matrices currently WD=0, fresh axis |
| 2 | Idea 2 — AdEMAMix β₃/α grid | Defer until #840 n=4 lands |
| 3 | Idea 3 — Nesterov pre-NS | High — formula change, no extra cost |
| 4 | Idea 5 — Per-column normalization pre-NS | High — clean mechanism |
| 5 | Idea 7 — Momentum reset at cooldown onset | Medium — schedule interaction (novel) |
| 6 | Idea 8 — Top-k sparsification pre-NS | Medium — gradient filtering |
| 7 | Idea 6 — Path-heterogeneous β₁ (mlp vs attn) | Medium — distinct from #800 depth-het |
| 8 | Idea 9 — Q/K/V consensus update | Lower — risky structural bet |
| — | Idea 1 — SOAP on MLP path | ✗ MOOT (already in baseline) |
| — | Idea 10 — AdaFactor factored preconditioner | ✗ MOOT (would replace SOAP, likely worse) |

---

## Idea 1 — SOAP Preconditioning on MLP Path

**Hypothesis:** Extending the Kronecker (SOAP) preconditioner from attention weights to MLP fc1/fc2 matrices will reduce the gradient-space distortion that Muon's NS step must correct, yielding a lower effective curvature landscape on the MLP path — the same path where AdEMAMix (PR #840 Cell E) already shows the programme's strongest post-#699 signal.

**Mechanism:** The NS polar-decomposition step is a curvature-agnostic whitening operator: it normalises the gradient's singular-value spectrum but ignores per-direction curvature. SOAP's Kronecker-factor preconditioning (Shampoo-style A⊗B) estimates local curvature from gradient outer-products and pre-shapes the gradient so NS acts on a more isotropic landscape. Attention already benefits from this (`--soap_attn`). MLP fc1 (d_model×4d_model) and fc2 (4d_model×d_model) are large 2D matrices with potentially heterogeneous column spectra — exactly the setting where Kronecker preconditioners give the largest reduction in effective condition number. Key coupling: PR #840 Cell E showed MLP path is under-exploited; SOAP on MLP would add curvature awareness to that same path without any post-NS distortion.

**Sweep design (5 cells):**
- Cell A (ctrl): current stack, no MLP SOAP — establishes per-run baseline
- Cell B: SOAP on MLP fc1+fc2 only, soap_update_freq=10 (same as attn default), soap_precond_lr=0.01
- Cell C: SOAP on MLP fc1+fc2, soap_update_freq=4 (more frequent precond updates)
- Cell D: SOAP on MLP fc1+fc2, soap_update_freq=10, lr_mlp=0.06 (slight LR bump to test interaction with precond)
- Cell E: SOAP on MLP fc1+fc2 AND use AdEMAMix β₃=0.99/α=0.3 on MLP path (stack #840 Cell E on top of SOAP-MLP — highest EV stacked cell)

**Primary expected outcome:** Cell B/C/D should show val/loss below 3.260 (≥+1σ improvement over baseline). Falsifier: if all SOAP-MLP cells are within ±0.5σ of ctrl, MLP curvature is already sufficiently handled by NS and this axis is closed.

**Reference:** Vyas et al., "SOAP: Improving and Stabilizing Shampoo using Adam" (arXiv 2409.11321, 2024). SOAP applied to transformer MLP layers in Llama-scale experiments shows 10-20% step reduction over Adam. Modded-nanogpt already implements SOAP for attn; MLP extension is a near-zero-diff code change.

---

## Idea 2 — AdEMAMix β₃/α Grid Refinement on MLP Path (Follow-On to PR #840 Cell E)

**Hypothesis:** PR #840 Cell E (β₃=0.99, α=0.3, MLP-scope) is the programme's single strongest post-#699 signal at −2.74σ below baseline on n=1. A tight grid around that operating point will confirm the mechanism, find the optimum, and push the n=4 mean below the 3.259221 merge gate.

**Mechanism:** AdEMAMix's dual-EMA mixes a slow exponential buffer (β₃) with the current gradient before NS orthogonalization, increasing the effective momentum timescale while preserving the gradient direction that NS acts on. The pre-NS placement is essential (PR #844 post-NS Cautious was strongly negative; #840 pre-NS was strongly positive). The MLP-only scope is important because attn already has SOAP's curvature correction, making the slow-EMA signal less additive there. Two free parameters remain underexplored: β₃ (slow-EMA decay, currently 0.99) and α (mixing weight, currently 0.3).

**Sweep design (5 cells):**
- Cell A (ctrl): β₃=0.99, α=0.3 (exactly replicate #840 Cell E to confirm n=1 result)
- Cell B: β₃=0.995, α=0.3 (slower EMA — longer history horizon)
- Cell C: β₃=0.99, α=0.2 (less slow-EMA mixing)
- Cell D: β₃=0.99, α=0.4 (more slow-EMA mixing)
- Cell E: β₃=0.995, α=0.25 (joint optimum candidate based on B/C signals)

**Primary expected outcome:** Cell A should replicate #840 Cell E val≈3.2596. Best grid cell should hit val≤3.258, crossing the n=4 merge gate. Falsifier: if Cell A does not replicate (val>3.261), the n=1 result was seed-sensitive and the mechanism needs re-examination.

**Reference:** Pagliardini et al., "AdEMAMix Optimizer: Better, Faster, Older" (arXiv 2409.03137, 2024). Table 2 shows β₃ sensitivity is weak over 0.98–0.999 but α is more sensitive with optimum near 0.2–0.5 depending on model size.

---

## Idea 3 — Nesterov Look-Ahead Gradient Pre-NS (No Extra Forward Pass)

**Hypothesis:** Applying Nesterov's look-ahead correction to the gradient BEFORE NS orthogonalization — using only the existing momentum buffer — will tighten the spectral estimate that NS acts on, leading to a better-conditioned update direction without any additional forward-backward cost.

**Mechanism:** Standard Muon: NS(g_t). Nesterov-Muon: NS(g_t + β·(m_t − m_{t-1})) where the correction uses the finite difference of consecutive momentum states (no extra fwd pass). This effectively applies NS to a gradient that has already incorporated one step of momentum extrapolation, giving NS a "future" gradient direction that is more aligned with the true loss curvature. Nesterov momentum is theoretically optimal for convex problems and empirically beneficial in SGD/Adam variants (classical momentum → Nesterov is consistently a small-but-reliable win at no cost). The key question is whether the pre-NS placement preserves the benefit: unlike post-NS Cautious (#844, NEG), this modifies the INPUT to NS, not its output. Distinct from per-group β₁ (#691, closed as inconclusive P2): that explored depth-heterogeneous β₁; this adds a qualitatively different gradient correction formula.

**Sweep design (4 cells):**
- Cell A (ctrl): current Muon (standard momentum)
- Cell B: Nesterov-Muon on MLP path only, β₁=0.95 (default)
- Cell C: Nesterov-Muon on MLP+attn paths, β₁=0.95
- Cell D: Nesterov-Muon on MLP path only, β₁=0.90 (tighter momentum)

**Primary expected outcome:** Cell B should show val/loss below 3.260 if Nesterov correction improves gradient spectral quality pre-NS. Falsifier: if B−A < 0.3σ_single, Nesterov correction does not materially change the gradient seen by NS.

**Reference:** Sutskever et al., "On the importance of initialization and momentum in deep learning" (ICML 2013). Nesterov momentum as described in Sutton & Barto, Bengio et al. (2013). Also: Dozat (2016) "Incorporating Nesterov Momentum into Adam" — Nadam shows consistent +0.1–0.3% improvement over Adam on LM tasks.

---

## Idea 4 — Weight Decay on Muon-Managed Body Matrices

**Hypothesis:** Muon-managed MLP and attention body matrices currently have WD=0. Introducing a small nonzero weight decay on these 2D matrices — applied post-NS, as a multiplicative shrinkage analogous to decoupled WD — may regularize the singular-value spectrum and reduce late-training overfitting on FineWeb.

**Mechanism:** Decoupled WD (AdamW style) applies θ ← θ·(1−lr·wd) independently of the gradient update. For NS-orthogonalized Muon, the update direction is already normalized (singular values clipped to ≈1); the question is whether WD on the weight matrix itself helps. PR #649 closed the 5-dimensional WD axis for scalars/embed/lm_head groups (finding wd_scalars=0 optimal). But that PR did not include the Muon body matrices — those were and are WD=0. Rationale for trying: NS orthogonalization drives weights toward matrices with spectral norm ~1, but WD would push them toward smaller Frobenius norm. The interaction is nontrivial and unexplored. Small WD values (1e-4 to 1e-3) on the body matrices could act as a soft spectral regulariser complementary to NS.

**Sweep design (5 cells):**
- Cell A (ctrl): WD=0 for all Muon-managed matrices (current default)
- Cell B: WD=1e-4 on MLP fc1+fc2 only
- Cell C: WD=1e-3 on MLP fc1+fc2 only
- Cell D: WD=1e-4 on all Muon-managed matrices (MLP + attn body)
- Cell E: WD=5e-4 on MLP fc1+fc2, WD=1e-4 on attn body

**Primary expected outcome:** One of B/C/D/E should cross below 3.260. Falsifier: if all cells ≥ Cell A val, WD-for-Muon-matrices is either neutral (small wd) or harmful (large wd) and this axis is closed.

**Reference:** Loshchilov & Hutter, "Decoupled Weight Decay Regularization" (ICLR 2019). WD=0 for momentum-based optimizers applied to normalized matrices is standard practice (e.g., Muon paper), but the empirical effect at small wd values for NS-preconditioned updates has not been characterized in the public speedrun literature.

---

## Idea 5 — Per-Column Gradient Normalization Pre-NS (Neuron-Scale Equalization)

**Hypothesis:** Normalizing each column of the gradient matrix to unit L2 norm BEFORE passing it to NS orthogonalization will equalize the per-neuron (per-output-unit) scale heterogeneity that accumulates from depth_init and varying activation patterns, improving the quality of the polar decomposition on the MLP path.

**Mechanism:** NS computes an approximate polar factor W≈UV^T; its convergence rate depends on the condition number of the input matrix. If the columns of G have wildly different L2 norms (which is expected in deep networks — neurons with large activations produce large gradient columns), NS sees a poorly conditioned input and converges to a lower-quality approximation in 6 iterations. Normalizing columns before NS transforms G → G·diag(1/‖g_i‖₂) so all columns have unit norm, then scaling output back post-NS by the same factors: U·diag(‖g_i‖₂)·V^T (or absorbing the scale into the LR). This is distinct from post-NS RMS clamp (#776, NEG) because it preserves the spectral structure before, not after, polar decomposition. Analogous to layer normalization but for the gradient matrix rather than activations.

**Sweep design (4 cells):**
- Cell A (ctrl): current NS without column normalization
- Cell B: column-normalize gradient pre-NS, MLP path only, scale absorbed into update (pure direction change)
- Cell C: column-normalize gradient pre-NS, MLP path only, scale propagated to update magnitude (column-adaptive LR effect)
- Cell D: column-normalize gradient pre-NS, all Muon paths (MLP+attn)

**Primary expected outcome:** Cell B tests whether direction quality improves; Cell C tests whether per-neuron adaptive magnitude helps. Expected: B or C below 3.260. Falsifier: all cells within ±0.5σ of A (column scale heterogeneity does not materially affect NS quality at ns_iter=6).

**Reference:** Per-column normalization of gradient matrices appears in preconditioned gradient methods including LARS (You et al., 2017) and LAMB (You et al., 2019). The specific pre-NS application is novel in this speedrun context.

---

## Idea 6 — Path-Heterogeneous β₁: Separate Muon Momentum for MLP vs Attn Bodies

**Hypothesis:** MLP and attention body matrices traverse qualitatively different optimization landscapes (MLP has no SOAP; attn has SOAP preconditioning); assigning them different momentum decay rates β₁ may allow each path to use its optimal timescale rather than sharing a single global β₁.

**Mechanism:** PR #800 tested depth-heterogeneous β₁ (per-layer gradient, NEG — all cells in-band or worse). That experiment varied β₁ by depth (layer index). This is a PATH split: attn body group vs MLP body group, not a depth split. The SOAP preconditioner on attn already captures curvature; lower β₁ there could reduce interference from the accumulated slow history. The MLP path (no SOAP, only NS) might benefit from higher β₁ to build more useful momentum given #840's finding that slow-EMA history is valuable on MLP. Concretely: attn β₁=0.90, MLP β₁=0.95 (default) or MLP β₁=0.97.

**Sweep design (5 cells):**
- Cell A (ctrl): uniform β₁=0.95 for both MLP and attn Muon groups
- Cell B: MLP β₁=0.95, attn β₁=0.90 (tighter momentum on SOAP-preconditioned path)
- Cell C: MLP β₁=0.97, attn β₁=0.95 (stronger momentum on MLP path)
- Cell D: MLP β₁=0.97, attn β₁=0.90 (largest split)
- Cell E: MLP β₁=0.95, attn β₁=0.85 (aggressive attn tightening)

**Primary expected outcome:** D or C below 3.260. Falsifier: if B−A < 0.3σ and C−A < 0.3σ in either direction, path-β₁ split is not a meaningful lever at this scale.

**Reference:** PATH-heterogeneous β₁ is mechanistically motivated by the different preconditioners applied per path. No direct prior art found; the closest is per-group β in LAMB/LARS (layer-scale dependent LR) which shows consistent benefits for Transformer training.

---

## Idea 7 — Momentum State Reset at Cooldown Onset

**Hypothesis:** Zeroing (or partially decaying) the Muon momentum buffer at the start of the LR cooldown phase will eliminate stale momentum bias accumulated during the warmup+steady phase and allow the cooldown's high gradient-to-LR-ratio to drive a cleaner final descent.

**Mechanism:** WSD (Warmup-Stable-Decay) schedules have been shown empirically (Hu et al. 2024 "MiniCPM") to benefit from momentum reset at the transition to decay, because accumulated momentum from the stable phase tends to overshoot the valley that decay-phase small steps are trying to settle into. The ramp_down WD schedule already adjusts weight decay at cooldown onset; a momentum reset is the momentum-space complement. For Muon specifically: the NS step orthogonalizes the direction but does not prevent directional drift in m_t across thousands of steps. A hard zero-reset at cooldown onset discards this bias; a soft partial-reset (m_t ← γ·m_t, γ∈{0.5, 0.1}) is a milder intervention. This is implementable as a one-line conditional at the cooldown step boundary.

**Sweep design (4 cells):**
- Cell A (ctrl): no momentum reset (current behavior)
- Cell B: zero-reset Muon m_t at cooldown start (step = train_steps × (1 - cooldown_frac))
- Cell C: partial-reset m_t ← 0.1·m_t at cooldown start (strong partial decay)
- Cell D: partial-reset m_t ← 0.5·m_t at cooldown start (mild partial decay)

**Primary expected outcome:** B or C should show improved val/loss slope during cooldown. Falsifier: if val/loss at final step shows no improvement vs ctrl after cooldown (D−A > 0, C−A > 0, B−A > 0), momentum reset is not beneficial — cooldown LR is already small enough to self-correct any directional bias.

**Reference:** Hu et al., "MiniCPM: Scaling Large Language Models with Scalable Training Strategies" (2024) — demonstrates that momentum reset at decay-phase onset improves final loss in WSD schedules. Specific to language model pretraining with cosine/linear decay. The MiniCPM "model reuses" and "learning rate re-warming" experiments are the closest prior evidence.

---

## Idea 8 — Top-k Gradient Sparsification Pre-NS (Outlier Filtering Before Polar Decomposition)

**Hypothesis:** Masking the bottom (1−k) fraction of gradient entries by magnitude BEFORE NS orthogonalization — setting small-magnitude entries to zero — will remove gradient noise that degrades the polar decomposition's spectral estimate, effectively giving NS a higher-SNR input.

**Mechanism:** The gradient matrix G has a mixture of large-magnitude signal entries (high-curvature directions) and small-magnitude noise entries (low-SNR directions from stochastic minibatch sampling). NS orthogonalization computes the polar factor of G; with low-rank noise, the smaller singular values are dominated by noise rather than true curvature signal. Top-k sparsification (zeroing entries with |g_ij| < τ where τ is the k-th percentile) pushes G toward lower effective rank, concentrating the singular-value mass on the signal subspace. Post-NS update quality improves when NS acts on a cleaner input. Key distinction from post-NS interventions (#776 RMS-clamp, #844 Cautious): this preserves the NS computation's own spectral mechanics, unlike clamps applied after.

**Sweep design (5 cells):**
- Cell A (ctrl): no sparsification (k=100%, all entries retained)
- Cell B: top-70% pre-NS (mask bottom 30% by magnitude), MLP path only
- Cell C: top-50% pre-NS (mask bottom 50% by magnitude), MLP path only
- Cell D: top-70% pre-NS, all Muon paths (MLP+attn)
- Cell E: top-90% pre-NS (mild masking, mask bottom 10%), MLP path only — gentler intervention

**Primary expected outcome:** Cell E (mild masking) should show whether gentle outlier filtering helps. Cell B/C bracket the useful sparsity range. Falsifier: if E−A > 0 (mild masking hurts), gradient noise is not the bottleneck pre-NS and sparsification is harmful at all densities.

**Reference:** Lin et al., "Deep Gradient Compression" (ICLR 2018) for gradient sparsification mechanics. Ivanov et al., "Colossus" gradient compression in distributed training. The specific pre-NS application is novel. Note: threshold should be computed per-matrix per-step to avoid fixed-scale dependence.

---

## Idea 9 — Block-Coupled Q/K/V Gradient Averaging (Consensus Update for Shared-Input Matrices)

**Hypothesis:** Q, K, and V projection matrices all receive gradients from the same residual stream input; averaging their NS-updated directions (consensus update) before applying the weight step will exploit this structural correlation and reduce noise in each individual update direction.

**Mechanism:** In multi-head attention, Q, K, V ∈ R^{d×d} share the same input activation x; their gradients G_Q, G_K, G_V are independently computed but structurally correlated through x. NS(G_Q), NS(G_K), NS(G_V) individually orthogonalize each gradient but discard the cross-matrix structural similarity. Consensus averaging: Ū = (NS(G_Q) + NS(G_K) + NS(G_V)) / 3, then apply Ū (or a weighted combination) to each. This effectively averages out the independent minibatch noise components while preserving the shared curvature signal. Related to ensemble-of-gradients ideas (Recht & Re 2012 "Toward a Noncommutative Arithmetic-Geometric Mean Inequality") but applied within one optimizer step. Caveat: Q/K/V may have specialized roles that consensus would harm; a gating mechanism (add fraction α of consensus to each individual update) is safer.

**Sweep design (4 cells):**
- Cell A (ctrl): independent NS per Q/K/V (current default)
- Cell B: full consensus — Ū = mean(NS(G_Q), NS(G_K), NS(G_V)), apply Ū to all three
- Cell C: partial consensus — each matrix gets (1−α)·NS(G_i) + α·Ū with α=0.3
- Cell D: partial consensus, α=0.5

**Primary expected outcome:** Cell C (partial, α=0.3) below 3.260. Falsifier: if B shows clear degradation (B−A > 1σ), Q/K/V specialization is load-bearing and consensus is harmful. If C−A < 0.3σ, shared-input coupling is not a useful signal at this scale.

**Reference:** Zhang et al., "Lookahead Optimizer: k steps forward, 1 step back" (NeurIPS 2019) explores gradient averaging across time; related consensus ideas appear in federated learning (Li et al. 2020 "FedProx"). The structural Q/K/V correlation argument is novel in this context.

---

## Idea 10 — AdaFactor-Style Factored Row/Column Preconditioner for MLP Path (Lightweight SOAP)

**Hypothesis:** Replacing SOAP's full Kronecker A⊗B preconditioning for MLP matrices with AdaFactor's memory-efficient factored row/column preconditioner (r_t⊗c_t, where r_t and c_t are running averages of row/column squared-gradient norms) provides curvature adaptation on the MLP path at far lower memory and compute cost than full SOAP.

**Mechanism:** Full SOAP on large matrices (MLP fc1: d×4d = 768×3072) requires storing and inverting Kronecker factors A∈R^{d×d} and B∈R^{4d×4d}, which is memory-intensive (A alone is 768×768 = 590K floats). AdaFactor's factored preconditioner approximates the full 2nd-moment matrix V ≈ r_t·1^T + 1·c_t^T where r_t = V·1 (row sums) and c_t = 1^T·V (column sums), requiring only O(m+n) storage vs O(mn) for full Adam or O(m²+n²) for SOAP. Applied pre-NS: precondition G by the factored preconditioner, then pass to NS. This tests a Pareto-efficient point between no preconditioning (current MLP) and full SOAP (Idea 1).

**Sweep design (4 cells):**
- Cell A (ctrl): no MLP preconditioning (current)
- Cell B: factored AdaFactor-style preconditioner on MLP path, ε_factor=1e-30 (standard AdaFactor default)
- Cell C: factored preconditioner on MLP path, combined with AdEMAMix β₃=0.99/α=0.3 (#840 Cell E mechanism)
- Cell D: row-only preconditioner on MLP path (half the AdaFactor factorization — test which dimension matters more)

**Primary expected outcome:** Cell B below 3.260 if factored curvature adaptation helps MLP path. Cell C is the aggressive stacking cell (should beat B if mechanisms are additive). Falsifier: if B−A < 0.3σ_single, lightweight factored preconditioning is insufficient and full SOAP (Idea 1) is needed, or MLP curvature is genuinely flat enough that NS alone suffices.

**Reference:** Shazeer & Stern, "Adafactor: Adaptive Learning Rates with Sublinear Memory Cost" (ICML 2018). The combination of AdaFactor-style factored preconditioner + Muon-style NS step is novel and not tested in the speedrun literature.

---

## Rejected Directions

The following ideas were considered but excluded because they overlap closed experimental axes or have structural incompatibilities with the benchmark contract:

**1. Schedule-Free variants on Muon (e.g., SF-Muon, Polyak averaging on NS-updated weights)**
PR #659 ran all 5 cells of Schedule-Free AdamW with cooldown interactions — all cells 46–59σ above baseline. The cooldown + SF incompatibility is fundamental: cooldown relies on decaying LR to settle into a valley, while SF's Polyak averaging assumes no LR-directed annealing. Any schedule-free variant on Muon would face the same incompatibility with the current WSD training recipe.

**2. SAM (Sharpness-Aware Minimization) on Muon/SOAP matrices**
SAM requires a second forward-backward pass per optimizer step to compute the perturbed gradient at θ+ε·ĝ. The benchmark contract explicitly bans multiple forward-backward passes per step. This axis is structurally off-limits.

**3. Gradient centralization for Muon body matrices**
PR #756 tested gradient centralization (zero-mean columns) on the full MLP+attn body. All cells in-band; B−A = 0.0σ. Centralization is a pre-NS intervention and was already tested at the right level. The axis is closed.

---

## Summary Priority Table

| Rank | Idea | Primary lever | Mechanism type | EV estimate |
|------|------|--------------|---------------|-------------|
| 1 | SOAP on MLP | Preconditioning | Pre-NS curvature adaptation | Very high |
| 2 | AdEMAMix β₃/α grid | Slow-EMA refinement | Pre-NS slow momentum | Very high (follow-on to confirmed signal) |
| 3 | Nesterov pre-NS | Momentum formula | Pre-NS direction correction | High |
| 4 | Muon WD sweep | Regularization | Post-NS weight shrinkage | Medium-high |
| 5 | Per-column normalization | Scale equalization | Pre-NS condition number | Medium-high |
| 6 | Path-heterogeneous β₁ | Momentum timescale | Pre-NS path-specific | Medium |
| 7 | Momentum reset at cooldown | Schedule interaction | Mid-training state reset | Medium |
| 8 | Top-k sparsification pre-NS | Gradient filtering | Pre-NS SNR improvement | Medium |
| 9 | Q/K/V consensus update | Structural coupling | Post-NS consensus | Lower (risky) |
| 10 | AdaFactor factored preconditioner | Lightweight curvature | Pre-NS row/col adapt | Medium |

Ideas 1, 2, 3, 5, 8 are all pre-NS interventions — the productive zone confirmed by the experiment history. Ideas 4, 6, 7 test unexplored axes (WD=0, path β₁, cooldown reset). Ideas 9, 10 are more speculative structural bets.
