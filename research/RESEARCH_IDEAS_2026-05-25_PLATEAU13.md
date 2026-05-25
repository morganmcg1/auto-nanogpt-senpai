# Research Ideas — Plateau Escalation Wave (Cycle 249+)
# Generated: 2026-05-25
# Context: 13 consecutive no-merge closures since PR #847 (baseline 3.26756, n=3)
# Mode: PLATEAU PROTOCOL ESCALATION — tier-4 family-replacement and structural ideas only

---

## Hypothesis 1: Newton-Muon — Input Second-Moment Right Preconditioning for Body

### What It Is
Replace the bare NS5 polar decomposition in Muon with Newton-Muon: apply right preconditioning by the input activation second moment before orthogonalization. Update rule: `W ← W − η · msgn(G · (ZZᵀ)⁻¹)` where ZZᵀ is the exponential moving average of input outer products per layer.

### Mechanism Distinctness
All prior body Muon work (WD fence, noise injection, momentum schedule, LookAhead, NS-iter count, Nesterov, AggMo-in-flight) acts on the gradient signal entering NS5 or on post-update magnitude. Newton-Muon acts on the *channel covariance* of the input activations — a fundamentally different geometric object. The NS5 Lipschitz invariance finding (||g_ortho||_RMS = 0.0360 ± 0.000003 across all noise arms) proves that NS5 is blind to input scale; Newton-Muon breaks that invariance by injecting input geometry before msgn normalization. Mechanism-distinct from Shampoo (#1132 in-flight) because Shampoo factors the gradient Gram matrix on both sides; Newton-Muon uses only the right factor (input activations, not output gradients).

### Predicted Outcome
6% step reduction and 4% wall-clock improvement reported in the original paper on modded-nanoGPT at similar scale. Given our baseline of ~3175 steps to target, expect ~2975–3025 steps to target. This is the highest-evidence external result for our exact problem class.

### Key Papers
- Du & Su, "Newton-Muon: A Second-Order Extension of Muon", arXiv:2604.01472, April 2026. Direct modded-nanoGPT benchmark; ablates ZZᵀ EMA decay β_Z and right-preconditioning vs. no preconditioning.

### Implementation Sketch
Maintain a per-layer EMA `Z2` of input outer product `Xᵀ X` (updated at each step with decay β_Z ≈ 0.95). Before passing gradient to NS5, right-multiply: `G_precond = G @ inv(Z2 + ε·I)`. Use Neumann series or Cholesky for inversion — at hidden dim d=768 this is 768×768 solve, fast. Apply NS5 to G_precond as before. 4 arms: A=ctrl (no preconditioning), B=β_Z=0.95 mechanism-lead, C=β_Z=0.99, D=β_Z=0.90.

### Taste Rubric
- Research mode: Tier shift (family-replacement of NS5 geometric framework)
- Mechanistic grounding: 4 — direct modded-nanoGPT numbers, mechanism matches the NS5 Lipschitz invariance structural finding precisely
- Research-state value: 4 — both success and failure would sharply update: success confirms input-geometry is the missing signal; failure constrains preconditioning type
- Execution value: 4 — per-layer 768×768 Cholesky adds ~5% compute overhead, single H100 fits easily, directly tied to primary metric

---

## Hypothesis 2: SOAP for Aux AdamW Groups — Adam in Shampoo Eigenbasis

### What It Is
Replace standard AdamW for the embed and lm_head groups with SOAP: maintain Shampoo-style Kronecker factors (L, R) for the second moment, but run Adam's m/v accumulators in the slowly-rotating eigenbasis of those factors. Update: decompose L and R periodically (every K=50–200 steps), project gradient into eigenbasis, run standard Adam updates there, project back.

### Mechanism Distinctness
All closed aux axes (β₁/β₂/WD/ε/schedule/GaLore-lm_head-in-flight) either tune scalar hyperparameters of AdamW or reduce gradient rank. SOAP changes the *second-moment geometry* — instead of diagonal per-element variance, it captures low-dimensional directions of highest curvature via Kronecker factoring. GaLore (#1120 in-flight) projects gradients into a fixed low-rank subspace; SOAP maintains a *rotating* full-rank eigenbasis and accumulates second moments there. Completely different mechanism despite surface similarity.

### Predicted Outcome
Vyas et al. (NeurIPS 2024) report 3–4% step improvement over AdamW on language model training at comparable scale. For lm_head (51M parameters, Zipfian-heavy), Kronecker factoring captures the dominant singular value structure that row-magnitude normalization (#1045 LION finding) and GaLore both hint at but do not directly exploit.

### Key Papers
- Vyas et al., "SOAP: Improving and Stabilizing Shampoo using Adam", arXiv:2409.11321, NeurIPS 2024 Workshop. Clean ablation against Shampoo and AdamW; reports sensitivity to eigendecomp period K.

### Implementation Sketch
For lm_head (shape V×d, V=50257, d=768): factor into L (V×V, rank-r approximation) and R (d×d). Eigendecomp R every K steps (cheap: 768×768). Project: `G_rot = Q_Lᵀ G Q_R`. Run Adam on G_rot with separate m_rot, v_rot. Project back: `update = Q_L · (m_rot / (√v_rot + ε)) · Q_Rᵀ`. For embed (same shape): apply analogously. 4 arms: A=ctrl, B=K=100 mechanism-lead, C=K=50, D=K=200.

### Taste Rubric
- Research mode: Tier shift (second-moment geometry replacement)
- Mechanistic grounding: 3 — strong external evidence; connection to lm_head Zipfian structure is motivated by LION-aux finding but speculative
- Research-state value: 3 — would distinguish whether aux group curvature geometry matters beyond scalar AdamW tuning
- Execution value: 3 — eigendecomp overhead modest; GaLore in-flight provides partial separation but different enough mechanism

---

## Hypothesis 3: MARS-AdamW for Aux — Variance Reduction via Scaled Recursive Momentum

### What It Is
Replace AdamW in aux groups with MARS-AdamW: augment the Adam gradient estimate with a STORM-style variance reduction term `cₜ(gₜ − gₜ₋₁)` scaled by the per-element gradient ratio `c_t = ‖gₜ‖/‖gₜ − gₜ₋₁‖`. This gives an asymptotically unbiased gradient estimate with reduced variance, then passed to standard Adam update.

### Mechanism Distinctness
All closed aux scalar tuning axes (β₁/β₂/WD/ε/Adan/schedule) modify the update rule parameters but keep the same biased stochastic gradient. MARS adds a *variance reduction correction* to the gradient estimator itself. This is a different level of abstraction: instead of tuning how Adam uses the gradient, MARS changes what gradient Adam sees. Mechanism-distinct from Schedule-Free (#1127 in-flight) which replaces the LR schedule with iterate averaging; MARS replaces the gradient signal.

### Predicted Outcome
Yuan et al. (arXiv:2411.10438) report 2–3% perplexity improvement over AdamW on GPT-2-scale language modeling. For our 3350-step run, variance reduction in the aux groups (which handle embed and lm_head — the two highest-gradient-variance parameter classes) could provide a meaningful step count reduction.

### Key Papers
- Yuan et al., "MARS: Unleashing the Power of Variance Reduction for Training Large Models", arXiv:2411.10438, Nov 2024. GPT-2 nanoGPT benchmark with MARS-AdamW, MARS-Lion, MARS-Shampoo; ablates cₜ scaling.

### Implementation Sketch
Keep body Muon unchanged. For embed + lm_head groups: store previous gradient `g_prev`. Each step: `c_t = ||g_t|| / (||g_t - g_prev|| + ε)`; `mars_grad = g_t + c_t * (g_t - g_prev)`. Clip c_t at [0, c_max=10]. Feed mars_grad into standard AdamW update. Update g_prev. 4 arms: A=ctrl, B=c_max=10 mechanism-lead, C=c_max=5, D=MARS applied to embed only.

### Taste Rubric
- Research mode: Tier shift (gradient estimator class replacement)
- Mechanistic grounding: 3 — external GPT-2/nanoGPT results; theoretical variance reduction motivation is clean
- Research-state value: 3 — separates gradient-estimator variance from optimizer-update geometry; clean enough to interpret
- Execution value: 3 — minimal overhead (one extra tensor per group); staged aux-only application reduces risk

---

## Hypothesis 4: Scion — LMO Norm-Constrained Update Replacing Body Muon

### What It Is
Replace the body Muon optimizer entirely with Scion (Stochastic Conditional Gradient Norm-constrained Iterates), an optimizer that computes the linear minimization oracle (LMO) over a norm ball. For matrix parameters, the LMO over the nuclear norm ball is a rank-1 update `σ₁ u₁ v₁ᵀ` (top singular vector outer product). The update is memory-efficient: half-precision weights + grads only.

### Mechanism Distinctness
Muon (NS5 + SGD-like) produces updates with bounded operator norm; Scion produces updates with bounded *nuclear norm* (sum of singular values). These are dual norms. Scion's LMO structure means each update concentrates all signal in the top spectral direction, while Muon distributes it across all directions via orthogonalization. This is a fundamentally different geometric constraint — not a modification of Muon but a replacement with a different geometric prior. Completely outside the NS5 framework.

### Predicted Outcome
Pethick et al. (arXiv:2502.07529) demonstrate Scion matching or beating Muon on nanoGPT language modeling. Memory savings are a secondary benefit on H100 but could allow larger effective batch or lookahead. The nuclear norm constraint may be better suited to the Zipfian-like weight spectral distributions seen in transformer body parameters.

### Key Papers
- Pethick et al., "Scion: Norm-Constrained Optimizer for Large Language Models", arXiv:2502.07529, Feb 2025. LIONS-EPFL. GitHub: https://github.com/LIONS-EPFL/scion. Direct nanoGPT comparison with Muon.

### Implementation Sketch
For each body weight W (shape m×n): at each step, compute SVD of gradient G to get top singular vectors u₁, v₁ and value σ₁. LMO step: `W ← W − η · r · u₁ v₁ᵀ` where r is the nuclear norm constraint radius. In practice: approximate with 1 power iteration for u₁/v₁ (cheap). Set η and r via LR schedule analogous to current body Muon LR. 4 arms: A=ctrl (body Muon), B=Scion rank-1 mechanism-lead, C=Scion rank-3 (sum of top-3 singular triplets), D=Scion rank-1 with nuclear norm constraint r tuned.

### Taste Rubric
- Research mode: Tier shift (complete body optimizer family replacement)
- Mechanistic grounding: 4 — direct nanoGPT comparison in paper; nuclear vs. operator norm duality is precise; GitHub implementation available for reference
- Research-state value: 4 — either Scion beats Muon (confirms nuclear norm prior) or loses (confirms operator norm / Muon's distributional update is better); clear interpretation either way
- Execution value: 3 — power iteration overhead small; SVD rank-1 is faster than NS5 per step; risk is LR retuning required

---

## Hypothesis 5: Muon++ — Principled μP Spectral Control via Update-Level Scaling

### What It Is
Apply Muon++ scaling rules: at initialization, scale weight matrices by 1/√d (fan-in-based) matching μP spectral norms; during training, scale the NS5 orthogonalized update by √(d_out/d_in) to maintain spectral norms of weight matrices proportional to 1/√d throughout training. This replaces ad-hoc LR tuning with a principled per-layer scale derived from spectral theory.

### Mechanism Distinctness
All prior LR/WD tuning acts on global or per-group scalar schedules. Muon++ introduces *per-layer* update scaling derived from the weight matrix's spectral geometry (fan-in/fan-out ratio). The current stack uses a single body Muon LR for all body parameters regardless of layer shape — Muon++ makes this shape-adaptive. Distinct from Shampoo (#1132 in-flight) which adapts to curvature; Muon++ adapts to initialization geometry.

### Predicted Outcome
Zhao (arXiv:2601.01306) shows that maintaining μP spectral conditions throughout training prevents gradient explosion at deeper layers and allows higher LR. For our 12-layer model, the effect may be modest but the interaction with the 3350-step trajectory (where later layers show greater WD sensitivity — see #1091 findings) could compound.

### Key Papers
- Zhao, "Principled Muon under Maximal Update Parameterization", arXiv:2601.01306, Jan 2026. Spectral stability analysis; ablates per-layer scaling vs. global scalar.

### Implementation Sketch
At init: for each W of shape (d_out, d_in), initialize with std = 1/√d_in (μP init). During optimizer step: after NS5 orthogonalization gives g_ortho, scale: `g_scaled = g_ortho * sqrt(d_out / d_in)`. Apply weight update as before. This adds zero overhead beyond the scale multiply. 4 arms: A=ctrl, B=μP init + √(d_out/d_in) update scaling mechanism-lead, C=μP init only (no update scaling), D=update scaling only (current init unchanged).

### Taste Rubric
- Research mode: Frontier refinement with structural basis (parameterization class)
- Mechanistic grounding: 3 — clean theoretical motivation; paper covers nanoGPT-class models but not our exact 3350-step regime
- Research-state value: 3 — arm C vs D decomposition is a clean diagnostic separating init effect from update-scaling effect
- Execution value: 4 — zero overhead, trivial implementation, 4-arm design is self-ablating and informative regardless of outcome

---

## Hypothesis 6: Stochastic Rounding + BF16 Gradient Accumulation for Embedding and lm_head

### What It Is
Apply stochastic rounding (SR) when accumulating gradients and optimizer states for the embed and lm_head groups in BF16 precision, while keeping master weights in FP32. SR replaces round-to-nearest with probabilistic rounding that is unbiased in expectation, recovering the missing 8 mantissa bits of BF16 at no numerical overhead beyond a random draw.

### Mechanism Distinctness
All closed precision-adjacent axes involved fixed-point mixed precision or weight normalization. Stochastic rounding is a quantization correction to the gradient accumulation signal — it makes the BF16 gradient statistically equivalent to FP32 in expectation, recovering gradient signal lost to truncation error. For lm_head (50257×768, highest-variance gradient class), BF16 truncation error is ~10⁻³ per element, which is on the order of our NULL band (|Δ|<0.001). This is a qualitatively different intervention from all optimizer axes.

### Predicted Outcome
SR has been shown to be critical for convergence in LLM training at scale (Wen et al., 2023; Gupta et al., 2015). For our regime where we are ~0.008 above the theoretical floor with 13 no-merge cycles, recovering gradient fidelity in the high-variance lm_head could close part of that gap. Effect size is uncertain — this is a diagnostic bet.

### Key Papers
- Gupta et al., "Deep Learning with Limited Numerical Precision", ICML 2015. Original SR analysis.
- Wen et al., "Overcoming Oscillations in Quantization-Aware Training", ICML 2023. LLM-scale SR analysis.

### Implementation Sketch
Custom CUDA kernel or PyTorch implementation: `x_sr = (x + torch.rand_like(x) * torch.finfo(x.dtype).eps).to(dtype)`. Apply in `optimizer.step()` when casting gradients for embed/lm_head. Keep body weights in FP32 (unchanged). 4 arms: A=ctrl, B=SR on lm_head only mechanism-lead, C=SR on embed only, D=SR on both.

### Taste Rubric
- Research mode: Diagnostic (numerical precision class)
- Mechanistic grounding: 2 — mechanism is sound but connection to our specific 0.008 gap is speculative; no prior arm tested this
- Research-state value: 3 — if SR helps, it constrains gradient precision as a bottleneck; if not, rules out truncation error as a plateau cause
- Execution value: 3 — cheap to implement; staged aux-only design limits risk; directly interpretable

---

## Research State Update

### Current Best Explanation for the Plateau
The body Muon optimizer has reached its local optimum within the NS5+SGD framework: the NS5 polar decomposition is Lipschitz-invariant to input perturbations (proven), WD is optimally zero (4-direction fence), and momentum is optimally constant (3-direction fence). The aux AdamW groups have been tuned to scalar optimality. The remaining gap (~0.008 from theoretical baseline floor) is structural — it requires either a different geometric prior for body updates (Newton-Muon, Scion, Shampoo), a different second-moment geometry for aux groups (SOAP, MARS), or a parametrization change (Muon++, SR).

### Ruled-Out Paths
- Any modification to NS5 input signal (gradient noise, gradient centering, WD, momentum schedule, LookAhead)
- Any scalar tuning of AdamW β₁/β₂/WD/ε for aux groups
- Any loss-side reweighting or token-level weighting
- Alternative single-optimizer replacements that don't address geometric structure (AdaBelief, Cautious, AdEMAMix, OrthoGrad, AGC, Polyak EMA)

### Open Uncertainties
1. Whether the NS5 Lipschitz invariance implies the *direction* distribution of updates is already optimal, or merely that scale perturbations don't help (Newton-Muon addresses this via input covariance, not scale)
2. Whether the aux groups are the bottleneck or the body groups — in-flight escalations (#1120/#1127) target aux; #1122/#1132 target body; no clean separation evidence yet
3. Whether the remaining gap is addressable at all within the fixed architecture/dataset/batch constraint, or is near-irreducible Bayes error

### Priority Order for Assignment
1. Newton-Muon (highest external evidence, directly addresses proven structural finding)
2. Muon++ (zero overhead, self-ablating 4-arm design)
3. Scion (complete family replacement, cleanest interpretation)
4. SOAP (aux group geometry, complements in-flight GaLore)
5. MARS-AdamW aux (variance reduction, orthogonal to SOAP)
6. Stochastic Rounding (diagnostic, low prior but cheap)
