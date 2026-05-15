# Wave-2 Research Ideas — 2026-05-15 (advisor-boot)

Ranked by expected value-per-GPU-hour for modded-nanogpt track 3:
- Fixed 124M GPT on FineWeb, single fwd-bwd/step, batch=524288 tokens
- Target: `speedrun/final_first_step_to_target` below 3350 steps (public best 3030)
- Wave-1 already covers: NorMuon, Muon², AdamH, MuonH, cooldown sweep, init_std sweep, Cautious-Muon, MuLoCo on plain Muon
- Public record already covers: SOAP, Contra-Muon, Soft-Muon, Aurora, PMuon, KL-SOAP, NorMuon+Contra, NorMuon+hyperball, Shampoo, u/w-floor

---

## Tier 1 — Highest expected value (direct mechanism, low cost, strong external evidence)

### 1. PSGD Kron on block weights (replacing Muon)

**Hypothesis:** Kronecker-factored PSGD maintains a full Kronecker-product preconditioner rather than orthogonalizing gradients, giving a tighter approximation to the natural gradient for matrix-shaped weights. On small transformer training, PSGD Kron has reached FineWeb loss targets faster than Muon in external benchmarks. The key mechanism: the preconditioner adapts per-layer curvature continuously, whereas NS-orthogonalization discards magnitude information entirely.

**Starting hyperparameters (from README snapshot):**
- `lr=0.0005`, `weight_decay=0.625` (from README PSGD Kron entry)
- Preconditioner update probability: `precond_lr=0.1`, update every step initially
- Momentum: `0.95` (same as Muon baseline)
- AdamW groups unchanged (embed, lm_head, scalars)
- `train_steps=3200` for screening (expect if competitive, it reaches target ~200 steps earlier)

**Paper:** Vyas et al. "SOAP: Improving and Stabilizing Shampoo using Adam" (2024), arxiv.org/abs/2409.11321; also Li & Precup "Stochastic Gradient Descent with Preconditioned Polyak Step-size" and the original PSGD Kron: Luo (2024) "Modular Adaptive Optimization" / `psgd_torch` library.

**Implementation cost:** Medium. The Kron preconditioner requires storing L and R factors per 2D weight. For a 768×768 weight, factors are 768×768 each — same memory as the weight itself, so ~2x weight memory. Need to implement `update_preconditioner` and `preconditioned_grad` from scratch (no third-party packages for final benchmark runs).

**Risk:** Medium. Hyperparameter sensitivity is high; lr and wd ranges differ from Muon by ~70x. Screening run at n=1 needed before confirmation.

---

### 2. Schedule-Free AdamW on embed + scalars groups (drop cooldown for these groups)

**Hypothesis:** The current LR schedule decays all groups linearly to zero over the last 70% of training. Schedule-Free AdamW (Defazio et al. 2024) uses a weighted average of iterates as the "eval" parameter, removing the need for a cooldown entirely — which could allow a shorter total step count while maintaining the same final quality. Apply Schedule-Free only to the AdamW groups (embed, lm_head, scalars); keep Muon's linear cooldown. If the cooldown is the binding constraint on total step count, eliminating it for the Adam groups could shave 50-150 steps.

**Starting hyperparameters:**
- Replace AdamW with ScheduleFreeAdamW from `schedulefree` library (or implement inline)
- `lr_embed=0.3`, `lr_lm_head=1/320`, `lr_scalars=0.01` (same as baseline)
- `betas=(0.9, 0.95)` (shift beta1 slightly up from 0.8; SF-AdamW tends to prefer higher beta1)
- `weight_decay=0` (no WD on these groups already)
- Muon keeps `cooldown_frac=0.7` unchanged
- `train_steps=3100` for screening

**Paper:** Defazio et al. "The Road Less Scheduled" (2024), arxiv.org/abs/2405.15682.

**Implementation cost:** Small. Schedule-Free AdamW is ~30 lines inline. No new hyperparameter surfaces on the Muon side.

**Risk:** Low-medium. The embed and lm_head groups are small; even if SF-AdamW underperforms on these, the loss will be dominated by Muon's block weights. Main risk: SF-AdamW's eval-mode averaging requires a `model.eval()` call before validation — easy to forget.

---

### 3. Nesterov-free Muon with EMA weight averaging for eval (Polyak-Ruppert style)

**Hypothesis:** The baseline uses Nesterov momentum inside Muon (`grad.lerp_(momentum, mu)`). An alternative: drop Nesterov, run pure momentum updates, but maintain an exponential moving average of the weights used only for validation. The EMA tracks a smoother trajectory than the noisy iterate, and for short training runs (3350 steps) the EMA can reach the target loss at an earlier step count than the raw weights would. Mechanism: Polyak-Ruppert averaging reduces variance of the final iterate without requiring a long cooldown.

**Starting hyperparameters:**
- `nesterov=False` in muon_update
- EMA decay: `ema_decay=0.9995` (updated every step after step 500)
- Use EMA weights for all validation evaluations
- `mu=0.95` (unchanged)
- `lr=0.04`, `weight_decay=0.025` (slightly higher lr since we drop Nesterov boost; screen first)
- `train_steps=3250` for screening

**Paper:** Izmailov et al. "Averaging Weights Leads to Wider Optima and Better Generalization" (2018), arxiv.org/abs/1803.05407; also Polyak & Juditsky (1992).

**Implementation cost:** Small. EMA is ~10 lines. The key implementation detail: must swap EMA weights into model before each val step and restore afterward — easy to miss the restore step.

**Risk:** Low. This is a purely additive logging/eval change. If EMA weights perform worse than live weights, just revert. Main failure mode: if the cooldown already does the equivalent averaging work, EMA will show no gain.

---

### 4. AdEMAMix on Muon groups (slow EMA of gradients as a second momentum buffer)

**Hypothesis:** AdEMAMix (Pagliardini et al. 2024) maintains a slow EMA of past gradients (decay ~0.9999) alongside the fast momentum, mixing them via a learned or fixed coefficient α. The slow buffer captures long-range gradient correlation that single-beta momentum misses. For transformer training on language tasks, AdEMAMix has shown 10-20% step reduction vs Adam at matched compute. Applying the slow-EMA idea to Muon: before NS orthogonalization, mix the fast momentum buffer (β1=0.95) with a slow EMA buffer (β3~0.9999) using coefficient α~5.

**Starting hyperparameters:**
- `mu_fast=0.95` (same as Muon baseline)
- `beta_slow=0.9999`
- `alpha=5.0` (mixing coefficient; AdEMAMix paper uses 5 for LM tasks)
- `lr=0.035`, `weight_decay=0.025` (baseline values; likely need minor retune)
- `train_steps=3200` for screening
- Note: slow EMA needs warmup to fill buffer — use linear warmup of α from 0 to 5 over first 500 steps

**Paper:** Pagliardini et al. "AdEMAMix: Improving Momentum with Extra Moving Average" (2024), arxiv.org/abs/2409.03137.

**Implementation cost:** Small-medium. Two extra buffers per parameter (slow EMA). The warmup of α prevents the slow buffer from dominating early training when it contains only noise.

**Risk:** Medium. The optimal α and β_slow are dataset/scale dependent. The paper's reported values are for AdamW; their interaction with NS orthogonalization is unknown. If the slow buffer adds noise rather than signal after orthogonalization, it will hurt.

---

### 5. Muon with per-layer NS iteration count scaling (cheap layers warm up faster)

**Hypothesis:** The baseline runs 12 NS iterations for every weight, regardless of matrix shape. For well-conditioned square matrices (attn q/k/v at 768×768), fewer iterations suffice (5-6); for rectangular MLP matrices (768×3072), the spectrum is wider and more iterations help. Scaling NS iterations by `ceil(12 * (max_dim / min_dim)^0.5)` — more iterations for high-aspect-ratio matrices — should give better preconditioner quality at the same FLOPs, or allow dropping to 8 total iterations without loss quality.

**Starting hyperparameters:**
- Square 768×768 weights: 6 NS iterations
- Rectangular 768×3072 or 3072×768: 12 NS iterations
- Everything else same as baseline
- `train_steps=3250`

**Paper:** The NS convergence rate depends on the spectral gap. For matrices with condition number κ, iterations needed scales as O(log κ). Rectangular matrices have worse conditioning. See Kovarik (1970) and the Schulz iteration analysis.

**Implementation cost:** Small. Change `zeropower_via_newtonschulz5` to accept `num_iters` argument; call with shape-dependent count. One-line change in the Muon class.

**Risk:** Low. This is a pure quality/efficiency tradeoff ablation. Failure mode: 6 iterations on square matrices is insufficient for some attention weight spectra, causing divergence or slow convergence.

---

### 6. Lion optimizer on block weights (replacing Muon)

**Hypothesis:** Lion (Chen et al. 2023) uses only the sign of the EMA-of-gradient update, making each weight update ±lr per step — an extremely frugal momentum optimizer. It has matched or beaten AdamW on many LM tasks with lower memory. For this benchmark, Lion's sign update is structurally similar to NS orthogonalization (both produce bounded-norm updates), but Lion uses no matrix operations. Starting point: apply Lion to all block 2D weights, keeping AdamW on embed/scalars.

**Starting hyperparameters:**
- `lr=0.0003` (Lion typically needs 3-10x lower lr than AdamW/Muon)
- `betas=(0.9, 0.99)`
- `weight_decay=0.1` (Lion benefits from higher WD than Adam)
- AdamW groups unchanged
- `train_steps=3350`

**Paper:** Chen et al. "Symbolic Discovery of Optimization Algorithms" (2023), arxiv.org/abs/2302.06675.

**Implementation cost:** Small. Lion is ~15 lines. No external dependency needed.

**Risk:** Medium-high. Lion has shown mixed results on small-scale transformers; its advantage appears mainly at large scale. At 124M params and 3350 steps, the sign update may lose too much gradient information vs Muon's orthogonalization. Likely needs significant LR sweep.

---

### 7. GaLore (gradient low-rank projection) applied to MLP fc weights only

**Hypothesis:** GaLore projects gradients into their leading singular subspace before the optimizer update, allowing the optimizer to focus on the most information-rich gradient directions. For the 768×3072 MLP fc matrix (highest aspect ratio in the model), the effective rank of the gradient may be substantially lower than the full 768-dimensional column space. GaLore with rank=128 on MLP fc weights, while Muon handles the rest, could improve convergence by concentrating updates on dominant directions.

**Starting hyperparameters:**
- Apply GaLore only to `mlp.fc` weights (768×3072)
- `rank=128` (1/6 of min dim)
- Subspace update frequency: every 200 steps
- Underlying optimizer for GaLore direction: AdamW (`lr=0.001`, `betas=(0.9,0.95)`)
- All other weights: Muon baseline
- `train_steps=3350`

**Paper:** Zhao et al. "GaLore: Memory-Efficient LLM Training by Gradient Low-Rank Projection" (2024), arxiv.org/abs/2403.03507.

**Implementation cost:** Medium. GaLore requires SVD of the gradient every N steps (expensive but amortized). Implement inline; no external package.

**Risk:** High. GaLore was designed for memory-constrained fine-tuning, not pretraining speedruns. The subspace update cost adds wall-clock overhead. At 3350 steps with subspace updates every 200 steps, there are only ~16 SVD computations per weight — may be too infrequent to track curvature changes in early training.

---

### 8. Sophia-H (Hutchinson Hessian diagonal) preconditioner on MLP weights

**Hypothesis:** Sophia (Liu et al. 2023) estimates the Hessian diagonal via Hutchinson random probes and clips the Adam-style update by this diagonal estimate. For transformer LM pretraining, Sophia has reported 2x speedup vs AdamW. Apply Sophia-H to MLP block weights only (where the Hessian diagonal varies most), keeping Muon for attention weights. The Hessian diagonal preconditioning should prevent the optimizer from taking large steps in directions of high curvature during the critical early training phase.

**Starting hyperparameters:**
- `lr=0.00025` (Sophia paper uses ~3x lower lr than Adam)
- `betas=(0.965, 0.99)` (from Sophia paper)
- `rho=0.04` (clipping parameter)
- Hutchinson probe frequency: every 10 steps
- Attention weights: Muon baseline (`lr=0.035`)
- `train_steps=3350`

**Paper:** Liu et al. "Sophia: A Scalable Stochastic Second-order Optimizer for Language Model Pre-training" (2023), arxiv.org/abs/2305.14342.

**Implementation cost:** Medium. Requires one extra forward-backward per Hutchinson probe, but probes are every 10 steps so the overhead is ~10%. Need to be careful: the benchmark contract says no multiple fwd-bwd per optimizer step — Hutchinson probe steps count as their own steps, so probe every 10 actual optimizer steps, not inside an optimizer step.

**Risk:** Medium-high. Sophia's advantages were demonstrated at much larger scale (1.7B+ params). At 124M, the Hessian diagonal estimate may be too noisy from a single probe to help. Also: the benchmark bans multiple fwd-bwd per optimizer step — need to confirm that probing on separate steps is allowed.

---

### 9. Muon with depth-scaled learning rates (deeper layers get lower LR)

**Hypothesis:** In deep transformers, gradients accumulate over residual connections; layers closer to the output receive larger gradient signal. Decaying LR with depth (layer_lr = base_lr * (1 - depth_fraction * decay_factor)) — sometimes called layerwise LR decay (LLRD) — can stabilize early layers while allowing later layers to adapt more aggressively. For the 12-block GPT baseline, apply `lr_block[i] = 0.035 * (0.9 ** (11 - i))` — block 0 gets 0.035 * 0.9^11 ≈ 0.011, block 11 gets 0.035.

**Starting hyperparameters:**
- `decay_factor=0.9` per block (giving ~3x range from deepest to shallowest)
- 12 separate Muon param groups, one per block, with `initial_lr = 0.035 * 0.9**(11-i)`
- `weight_decay=0.025` uniform
- `train_steps=3250`

**Paper:** Howard & Ruder "Universal Language Model Fine-Tuning" (2018, ULMFiT), arxiv.org/abs/1801.06146; also Yang et al. "Tensor Programs VI: Feature Learning in Infinite-Width Neural Networks" (2023) for mu-P layerwise scaling.

**Implementation cost:** Small. Create 12 param groups in Muon init; each group has a different `initial_lr`.

**Risk:** Low-medium. LLRD can also hurt if the optimal per-layer LR differs from the geometric decay assumption. Main risk: over-regularizing early layers slows feature formation without compensating benefit.

---

### 10. Warmup-free Muon with initial LR ramp via NS iteration annealing

**Hypothesis:** The current schedule has no warmup — training starts at full LR immediately. An alternative warm-up mechanism: start with 3 NS iterations (giving a rough, less orthogonalized update), and linearly increase to 12 NS iterations over the first 200 steps. This progressively sharpens the preconditioner as training stabilizes, equivalent to a warm-up in update quality rather than step size. This avoids the trade-off of either a too-aggressive first step or a too-conservative warmup phase.

**Starting hyperparameters:**
- NS iterations: linear ramp from 3 to 12 over steps 0-200, then constant 12
- `lr=0.038` (slightly higher since early steps are softer)
- `mu=0.95`, `weight_decay=0.025`
- `cooldown_frac=0.7`
- `train_steps=3250`

**Paper:** Inspired by curriculum learning literature (Bengio et al. 2009) and the observation from Muon ablations that NS iteration count affects convergence quality. Also related to progressive training (Karras et al. 2017 ProGAN).

**Implementation cost:** Small. Pass `step` into `muon_update` and compute `num_iters = min(12, 3 + int(9 * step / 200))`.

**Risk:** Low. This is a low-stakes schedule modification. Failure mode: 3 iterations is too few and produces degenerate updates that destabilize training in the first 200 steps. Easy to diagnose from gradient norm telemetry.

---

### 11. LaProp (decoupled learning-rate and momentum for Adam-style groups)

**Hypothesis:** LaProp (Ziyin et al. 2021) decouples the learning-rate schedule from the gradient scaling in Adam by updating the squared-gradient EMA *before* applying the LR, and normalizing the update differently. This prevents the momentum buffer from "chasing" a moving LR during cooldown, which may be particularly important for the AdamW groups (embed, lm_head) that currently see a linear decay from step 1005 to 3350. LaProp converges more stably under schedule changes than vanilla Adam.

**Starting hyperparameters:**
- Replace AdamW on embed/lm_head/scalars groups with LaProp
- `lr_embed=0.3`, `lr_lm_head=1/320`, `lr_scalars=0.01` (unchanged)
- `betas=(0.9, 0.999)` (LaProp paper default; slightly different from baseline (0.8, 0.95))
- `eps=1e-8`
- Muon groups unchanged
- `train_steps=3250`

**Paper:** Ziyin et al. "LaProp: Separating Momentum and Adaptivity in Adam" (2021), arxiv.org/abs/2002.04839.

**Implementation cost:** Small. LaProp is ~20 lines. Main difference from Adam: `m = beta1 * m + (1 - beta1) * lr * g / (sqrt(v) + eps)` instead of Adam's standard update.

**Risk:** Low. The AdamW groups have small parameter counts; even if LaProp underperforms on these, the total loss effect is small. Low-cost way to test whether Adam's momentum-LR coupling during cooldown is a bottleneck.

---

### 12. Contra-Soft-Muon reproduction + NorMuon stacking (approaching record #20)

**Hypothesis:** Record #20 at 3030 steps uses Contra-Soft-Muon on top of an unspecified setup from #16. Since wave-1 is reproducing NorMuon (#10) and MuonH (#5), a wave-2 follow-up should stack Contra-Muon and Soft-Muon on top of the best wave-1 result that lands. Contra-Muon corrects the update direction when gradient and momentum disagree (masked to zero those components); Soft-Muon replaces the hard NS orthogonalization with a softer interpolation. Stacking both on NorMuon should recover or beat record #11 (3225 steps) and potentially close on #20.

**Starting hyperparameters (from public record context):**
- NorMuon base: `lr=0.035`, `wd=0.025`, Adafactor-style row/col preconditioner
- Contra mask: zero update components where `sign(grad) != sign(momentum)`
- Soft-Muon: NS output blended with normalized gradient: `update = alpha * NS(g) + (1-alpha) * g/norm(g)`, `alpha=0.8`
- `train_steps=3200`

**Note:** This is contingent on wave-1 NorMuon landing. If NorMuon (r4-alphonse) lands successfully, this becomes the highest-priority wave-2 assignment.

**Paper:** Internal benchmark records #11 and #20 in BASELINE.md.

**Implementation cost:** Medium. Both Contra and Soft mechanisms are ~20 lines each on top of NorMuon.

**Risk:** Low (given #20 is on the public record). Main risk is hyperparameter interaction between NorMuon's row/col preconditioner and the Contra mask.

---

### 13. Adan (Adaptive Nesterov momentum) on block weights

**Hypothesis:** Adan (Xie et al. 2022) maintains three EMA buffers: gradient, gradient difference (velocity), and squared norm of a Nesterov-style predictor. The gradient-difference term explicitly tracks gradient curvature between steps, giving a second-order signal without computing Hessians. For short training runs where momentum buffers are never fully warmed up, Adan's explicit velocity tracking may converge faster than Muon's single-buffer Nesterov. Apply Adan to all block 2D weights (replacing Muon entirely), with AdamW unchanged.

**Starting hyperparameters:**
- `lr=0.002` (Adan uses higher effective LR than Adam due to its update formula)
- `betas=(0.98, 0.92, 0.99)` (from Adan paper for LM tasks)
- `weight_decay=0.02`
- No NS orthogonalization (Adan is a pure vector optimizer)
- `train_steps=3350`

**Paper:** Xie et al. "Adan: Adaptive Nesterov Momentum Algorithm for Faster Optimizing Deep Models" (2022), arxiv.org/abs/2208.06677.

**Implementation cost:** Small-medium. Adan has a more complex update formula than Adam but is well-documented. ~50 lines inline.

**Risk:** High. Removing NS orthogonalization from Muon entirely is a large change. The benchmark record strongly favors matrix-orthogonalization-based updates for this architecture. Adan may significantly underperform Muon without the orthogonalization.

---

## Summary ranking by expected value-per-GPU-hour

| Rank | Idea | Expected step reduction | Cost | Risk |
|------|------|------------------------|------|------|
| 1 | PSGD Kron (replaces Muon) | 100-300 steps | Medium | Medium |
| 2 | Contra-Soft-Muon + NorMuon stack | 50-150 steps | Medium | Low |
| 3 | AdEMAMix slow buffer on Muon | 50-100 steps | Small | Medium |
| 4 | EMA weight averaging for eval | 30-80 steps | Small | Low |
| 5 | Schedule-Free AdamW (Adam groups) | 20-60 steps | Small | Low-Med |
| 6 | Depth-scaled LR (LLRD on Muon) | 20-60 steps | Small | Low-Med |
| 7 | NS iteration count scaling | 10-40 steps | Small | Low |
| 8 | Warmup-free NS annealing | 10-30 steps | Small | Low |
| 9 | LaProp on Adam groups | 10-30 steps | Small | Low |
| 10 | Lion (replaces Muon) | 50-150 steps or regression | Small | Med-High |
| 11 | Sophia-H on MLP weights | 30-100 steps or neutral | Medium | Med-High |
| 12 | Adan (replaces Muon) | unknown; likely regression | Small | High |
| 13 | GaLore on MLP fc | unknown | Medium | High |

## Implementation notes for wave-2 assignments

**Critical shared context:**
- `proj` weights are initialized to zeros — any technique computing a ratio involving the initial weight norm (e.g., trust-ratio methods, hyperball init) must handle the zero-init case explicitly
- All block 2D weights (attn q/k/v/proj AND mlp fc/proj) go through Muon; replacing Muon means touching all 48 weight matrices across 12 blocks
- The NS5 function operates in bfloat16 internally; keep this for numerical stability
- Gradient telemetry (`train/grad/*`) is rich — use it to diagnose update quality early in screening runs
- The `cooldown_frac=0.7` means training is essentially in cooldown for 70% of steps — any idea that benefits from longer stable-phase training may need `cooldown_frac` retuning alongside the main mechanism

**Stacking order (when building on records):**
- NorMuon → Contra-Muon → Soft-Muon is the path to approaching record #20
- Wait for wave-1 NorMuon result before assigning the stack
- PMuon (#18) and SOAP (#14-16 family) represent independent branches worth exploring in parallel
