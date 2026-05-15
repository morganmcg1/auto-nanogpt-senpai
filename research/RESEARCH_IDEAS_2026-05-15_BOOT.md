# Research Ideas — 2026-05-15 Boot

Generated from: full training script analysis, leaderboard records #1–#21, and web
searches covering Muon2, SOAP, Schedule-Free, Lion, Shampoo, and muP.

**Current best:** Record #20 — Contra-Soft-Muon + KL-SOAP, 3030 steps.
**Target:** Reduce `speedrun/final_first_step_to_target` below 3030.
**Statistical floor (single run):** val/loss < 3.276.

---

## Portfolio Summary

| # | Name | Category | Risk | Expected Gain |
|---|------|----------|------|---------------|
| H01 | Muon2 Preconditioned NS | New optimizer | Medium | High |
| H02 | Schedule-Free Muon | New optimizer | Medium | High |
| H03 | Ablate Contra-Soft from #20 | Ablation | Low | Diagnostic |
| H04 | Ablate KL-SOAP → vanilla SOAP | Ablation | Low | Diagnostic |
| H05 | muP-style Init Scaling | Init/parameterization | Low-Med | Medium |
| H06 | Zero-Skip Init (proj → small normal) | Init/parameterization | Low | Low-Med |
| H07 | Cosine Cooldown Schedule | Schedule | Low | Low-Med |
| H08 | Extended Warmflat (40%/60%) | Schedule | Low | Low-Med |
| H09 | Lion-for-Scalars | Single mechanism | Low | Low |
| H10 | Nesterov Momentum Sweep on Muon | Single mechanism | Low | Med |
| H11 | Fewer NS Iterations (6–8) | Single mechanism | Low | Med |
| H12 | Dual-Preconditioner Muon (Muon2 + KL-SOAP) | Bold swing | High | Very High |
| H13 | Weight-Decay Warmup Schedule | Schedule | Low | Low-Med |
| H14 | Adaptive Aspect-Ratio Scaling | Single mechanism | Low-Med | Med |
| H15 | Distributed Full-Matrix Shampoo on Blocks | New optimizer | High | High |
| H16 | Per-Layer LR via Gradient Norm Ratios | Parameterization | Med | Med |

---

## Detailed Hypotheses

---

### H01 — Muon2 Preconditioned NS

**Category:** New optimizer (not on leaderboard)
**Risk:** Medium | **Complexity:** Medium

**Mechanism:**
Muon2 (arXiv:2504.09967, Modor et al. 2025) applies an Adam-style second-moment
running average to the gradient BEFORE the Newton-Schulz orthogonalization step.
Specifically, the raw gradient G is element-wise scaled by 1/sqrt(v + eps) where
v is an EMA of G^2 (beta2=0.999 typically), then the scaled gradient is fed into
NS. This smooths the variance of matrix entries entering NS, reducing the number
of NS iterations needed for convergence from ~12 to ~7-8. The paper reports
consistent wins over Muon and Adam variants from 60M to 1.3B params.

**Motivation relative to leaderboard:**
The current stack already uses 12 NS iterations (a=2, b=-1.5, c=0.5). Muon2 is
conceptually orthogonal to KL-SOAP and Contra-Soft-Muon — it modifies what enters
NS, not what comes out. If it reduces NS iterations by 40% the per-step cost drops
noticeably (12→7), potentially saving wall time and enabling a slightly larger
train_steps budget within the same time envelope. More importantly, the
preconditioned gradient entering NS should be better-conditioned, giving NS fewer
spectral outliers to suppress.

**Starting hyperparameters:**
- Replace `muon_update` gradient → use EMA-preconditioned gradient
- Muon lr=0.035 (same as #20 baseline), weight_decay=0.025
- beta2_muon2=0.999 (standard Adam second moment)
- eps=1e-8
- NS iterations: reduce from 12 to 8 (test; can revert to 12 if worse)
- Nesterov mu=0.95 (unchanged)
- Keep all AdamW param groups unchanged

**Relationship to existing records:**
Not tested. Most similar: record #7 (Muon², which is a different naming for
momentum^2 in Nesterov, not second-moment preconditioning). Record #20 is base.

**Recommended train_steps:** 3350 (screening); run 1 seed first. If val/loss at
step 3350 < 3.276, run 3 more seeds for stat sig confirmation.

**Implementation note:**
Add `v` buffer to Muon state dict. In `muon_update`, accumulate
`v = beta2*v + (1-beta2)*g**2`, then pass `g / (v.sqrt() + eps)` to NS instead
of raw `g`. Do NOT apply second-moment to the KL-SOAP or AdamW groups.

---

### H02 — Schedule-Free Muon

**Category:** New optimizer (not on leaderboard)
**Risk:** Medium | **Complexity:** Medium-High

**Mechanism:**
Schedule-Free optimization (Defazio & Mishchenko, arXiv:2405.15682) eliminates
the need for a stopping-time schedule by maintaining a running Polyak-Ruppert
average of the iterates with a warmup-derived coefficient, equivalent to running
a momentum method at a constant LR with built-in averaging. Won MLCommons 2024
AlgoPerf Self-Tuning track. Applied to Muon: keep the NS orthogonalization step
but remove the LR decay schedule entirely; instead accumulate a weighted average
`z = (1-c)*z + c*w` alongside the parameter `w`, and evaluate on `z`. The key
insight is that this replaces the 70% linear cooldown with an implicit averaging.

**Motivation relative to leaderboard:**
The current 70% linear cooldown schedule is heuristic. If Schedule-Free averaging
is equivalent to a better-tuned decay, we might either reach 3.28 at a lower step
count (earlier crossover) or more reliably, without needing to retune cooldown
fraction. The 30% stable / 70% decay split is a degree of freedom that has been
implicitly inherited; Schedule-Free removes it as a tunable.

**Starting hyperparameters:**
- Muon lr=0.035 (constant, no decay), weight_decay=0.025
- Schedule-Free beta (averaging weight) = 0.9
- Warmup steps for c coefficient = 100 (same as current warmup logic)
- AdamW groups: also try Schedule-Free on embed and LM head (lr=0.3 embed, lr=1/320 lm_head, constant)
- Remove the `set_hparams` cooldown; replace with SF weighting update
- Evaluate on averaged iterate `z` at val steps

**Relationship to existing records:**
No schedule-free variant has been tried. Orthogonal to Muon2. Could be combined
later but test independently first.

**Recommended train_steps:** 3350 screening, 1 seed. If promising (val/loss < 3.282
at step 3350), run 3 more seeds.

**Implementation note:**
Schedule-Free has two update modes: "train mode" (use `w` for forward pass) and
"eval mode" (use `z`). The eval mode switch must happen before every val loss
computation and switch back after. In PyTorch, implement as: store `z` buffer per
parameter, update `c = 1 - (1 - 1/step)**r` where r controls polynomial warmup,
update `z = (1-c)*z + c*w` after each optimizer step. See Defazio's reference
implementation at github.com/facebookresearch/schedule_free.

---

### H03 — Ablate Contra-Soft-Muon Component from Record #20

**Category:** Ablation | **Risk:** Low | **Complexity:** Low

**Mechanism:**
Record #20 uses Contra-Soft-Muon + KL-SOAP. "Contra-Soft-Muon" is the
contrastive soft-clipping modification to Muon (from Aurora/record #17 lineage).
This ablation runs the exact #20 config but removes the Contra-Soft modification,
reverting to standard Muon momentum. Goal: determine if Contra-Soft is load-
bearing or parasitic overhead.

**Motivation relative to leaderboard:**
Record #19 (KL-SOAP alone) reaches 3125 steps. Record #20 adds Contra-Soft-Muon
and reaches 3030. But we do not know if Contra-Soft was carrying the gain or if
better LR tuning on the KL-SOAP component was responsible. If Contra-Soft adds
noise, removing it would simplify the stack and free up tuning budget.

**Starting hyperparameters:**
- Exact #20 config except: revert Muon to standard `muon_update` (no soft clipping)
- Keep KL-SOAP params identical to #20
- lr_muon=0.035, weight_decay=0.025 (same as #20)

**Relationship to existing records:** Direct ablation of #20. Compare against both
#19 (3125) and #20 (3030).

**Recommended train_steps:** 3350 (1 seed diagnostic run).

**Implementation note:**
Find the Contra-Soft modification in the current train_gpt_simple.py's Muon
block. Remove only that component. Do not touch KL-SOAP. Log val/loss trajectory
and compare to #20 run.

---

### H04 — Ablate KL-SOAP → Vanilla SOAP from Record #20

**Category:** Ablation | **Risk:** Low | **Complexity:** Low

**Mechanism:**
Record #20 uses KL-SOAP (hyperball-constrained KL-divergence SOAP variant).
Record #19 established that KL-SOAP alone gives 3125. This ablation replaces
KL-SOAP in the #20 stack with standard SOAP (no hyperball, standard preconditioner
update). Goal: determine if the KL divergence constraint is load-bearing.

**Motivation relative to leaderboard:**
SOAP appeared in records #19 and #20 with KL modifications. Standard SOAP
(Vyas et al. NeurIPS 2024) is the baseline from which KL-SOAP diverges. If
vanilla SOAP + Contra-Soft-Muon matches #20, the KL modification is complexity
without benefit. If performance drops, the KL constraint is confirmed valuable.

**Starting hyperparameters:**
- Exact #20 config except: replace KL-SOAP optimizer with vanilla SOAP
- SOAP: lr=1/320 (LM head), betas=(0.9, 0.99), preconditioner_update_freq=10
- Keep Contra-Soft-Muon from #20 unchanged

**Recommended train_steps:** 3350 (1 seed diagnostic).

**Implementation note:**
Vanilla SOAP maintains Shampoo eigenbasis factors L, R and runs Adam in that
basis. Reference: github.com/nikhilvyas/SOAP. Key param: `precondition_frequency`
— try 10 and 50.

---

### H05 — muP-Style Hidden Weight Init Scaling

**Category:** Init/parameterization | **Risk:** Low-Medium | **Complexity:** Low

**Mechanism:**
Maximal Update Parameterization (Yang et al. 2022, Tensor Programs V) scales
hidden weight init std by 1/sqrt(width) and LR by 1/width for hidden layers, so
that feature learning magnitude is width-independent. Current init uses
`std = sqrt(0.33 / fan_in)`, which is essentially the muP fan-in scaling already.
The muP LR prescription (lr ~ 1/width) differs from current lr=0.035 for Muon
on blocks (width=768). Under muP, Muon lr should be ~0.035 * (default_width /
768). Test: adjust Muon lr by `base_width / model_dim` ratio.

**Motivation relative to leaderboard:**
The 768-dim model may be in a regime where the Muon LR is slightly too large or
small relative to muP optimal. A clean muP-consistent scaling might find a better
basin in one tuning shot instead of a grid search. This is a cheap diagnostic.

**Starting hyperparameters:**
- Keep init std unchanged (already ~muP-compatible)
- Adjust Muon lr: try 0.035 * (256/768) = ~0.012 and 0.035 * (512/768) = ~0.023
  as lower bound checks vs 0.035 as upper
- Adjust AdamW embed lr proportionally: 0.3 * (256/768) = 0.1 as lower
- Or: just run LR sweep [0.020, 0.028, 0.035, 0.042] for Muon on #20 stack

**Relationship to existing records:** No explicit muP tuning in any record.

**Recommended train_steps:** 2000 (LR sweep, 4 configs × 1 seed each).

**Implementation note:**
The simplest version is a lr sweep, not a full muP reparameterization. Log
`train/lr/*` and `val/loss` at step 1500 to pick winner, then run winner at
3350 steps. Do NOT change init std or the fan-in formula — the current formula
is already span-consistent.

---

### H06 — Projection Layer Small-Normal Init (vs. Zero-Init)

**Category:** Init/parameterization | **Risk:** Low | **Complexity:** Very Low

**Mechanism:**
Current code zeros all "proj" weight tensors at init (`w.zero_()`). This includes
MHA output projection and MLP down-projection. Zero-init suppresses gradient flow
through projection layers early in training, acting as an implicit warmup. However
it may slow learning for the first ~100 steps. Alternative: initialize projections
with small normal `std = 1e-4 * sqrt(0.33 / fan_in)`, preserving near-zero init
while allowing non-degenerate gradients.

**Motivation relative to leaderboard:**
Initialization can shift the basin the optimizer finds. The zero-init convention
was carried forward from original nanoGPT/GPT-2 practice. Small-normal init is
used in some modern transformer variants (e.g., scaled init in PaLM). Given that
Muon's NS update orthogonalizes gradients, near-zero rather than exact-zero init
may converge more stably.

**Starting hyperparameters:**
- Change `w.zero_()` for proj layers to `w.normal_(std=0.02 * w.size(-1)**-0.5)`
  where 0.02 is the original GPT-2 residual init scale
- Alternative: `w.normal_(std=1e-3)` flat small
- Keep all other init unchanged
- Use exact #20 optimizer hyperparameters

**Recommended train_steps:** 3350 (1 seed screening run).

**Implementation note:**
Lines 569–583 in train_gpt_simple.py. Change only the `if "proj" in name` branch.
Also test: skip the zero-init entirely and use the default `w.normal_(std=0.33**0.5
/ w.size(-1)**0.5)` for proj layers too.

---

### H07 — Cosine Cooldown Schedule (Replacing Linear)

**Category:** Schedule innovation | **Risk:** Low | **Complexity:** Very Low

**Mechanism:**
Current schedule: 30% stable at eta=1.0, then 70% linear decay to 0. Replace the
linear decay segment with a cosine half-cycle: `eta = 0.5 * (1 + cos(pi * t))` 
where t goes from 0 to 1 over the cooldown window. Cosine decays more slowly at
first and more sharply at the end, giving the optimizer more time in mid-LR
territory where gradient updates are still meaningful but not noisy.

**Motivation relative to leaderboard:**
Linear cooldown was the original nanogpt baseline choice. Cosine annealing is
better-justified theoretically (approximates optimal decay for SGD in convex
settings) and empirically outperforms linear in most language model training
ablations reported in the LLaMA and GPT-NeoX literature. A cosine tail may let
the optimizer make more improvement during cooldown without requiring a longer run.

**Starting hyperparameters:**
- Keep 30% stable phase unchanged
- Replace linear decay with cosine: `eta = 0.5 * (1 + cos(pi * (step - warmflat_end) / cooldown_steps))`
- min_lr_multiplier = 0 (decay to zero, same as linear)
- All optimizer params identical to #20

**Recommended train_steps:** 3350 (1 seed screening). Compare val/loss curve shape
especially in the last 500 steps.

**Implementation note:**
Change `set_hparams` in lines 601–610. One-line change in the `else` branch.
Also test: cosine with min_lr = 0.05 (i.e., decay to 5% of peak, not zero) since
full decay-to-zero may be premature.

---

### H08 — Extended Stable Phase (40%/60% split)

**Category:** Schedule innovation | **Risk:** Low | **Complexity:** Very Low

**Mechanism:**
Change the stable phase from 30% to 40% of total steps, and cooldown from 70% to
60%. At 3350 steps: stable = 1340 steps (up from 1005), cooldown = 2010 steps
(down from 2345). This gives the optimizer more time in the high-LR flat phase
where large gradient steps can explore the loss landscape before decay locks in.

**Motivation relative to leaderboard:**
The 30/70 split was inherited from the original nanogpt baseline. Modern training
recipes (Chinchilla, Gemma, Llama 3) commonly use 20–30% warmup/stable and
60–70% decay for LLMs on standard datasets. However at this smaller model scale
and step count, more stable-phase time may help Muon's NS-orthogonalized updates
cover more of parameter space before the forced convergence.

**Starting hyperparameters:**
- cooldown_frac = 0.60 (was 0.70)
- All other params identical to #20
- Also test cooldown_frac = 0.50 as a 50/50 split

**Recommended train_steps:** 3350 (2 seeds, 2 configs: 0.60 and 0.50).

**Implementation note:**
Change `set_hparams(step, cooldown_frac=0.7)` default to 0.60. One-character
change. Can also test passing it as CLI arg.

---

### H09 — Lion Optimizer for Scalar/Embedding Groups

**Category:** Single mechanism | **Risk:** Low | **Complexity:** Low

**Mechanism:**
Lion (EvoLved Sign Momentum, Chen et al. 2023) uses the sign of a momentum
interpolation: `update = sign(beta1*m + (1-beta1)*g)`, `m = beta2*m + (1-beta2)*g`.
It is memory-efficient (only stores one momentum buffer) and uses ~3x smaller LR
than Adam for equivalent performance. Replace AdamW for the embed and LM-head
groups with Lion; keep Muon for block parameters. The sign update may help
embedding gradients which tend to be sparse and noisy.

**Motivation relative to leaderboard:**
Current embed group uses AdamW lr=0.3 with betas=(0.8, 0.95). Lion's sign update
on embedding gradients could reduce noise in sparse token updates. This is a
low-risk single-group substitution that isolates the effect.

**Starting hyperparameters:**
- Lion for embed group: lr=0.1 (3x smaller than current 0.3), beta1=0.9, beta2=0.99
- Lion for LM head group: lr=0.001 (3x smaller than 1/320 ≈ 0.00312)
- Keep Muon + KL-SOAP for block params as in #20
- Weight decay: 0 for embed (current), 0.01 for LM head (test)

**Recommended train_steps:** 3350 (1 seed screening).

**Implementation note:**
Implement Lion as a standalone optimizer class (single file, no external deps).
Core update is 4 lines. LR sensitivity: if val/loss stagnates early, double lr.
Do not apply Lion to the scalar group (gains, biases) — keep AdamW there.

---

### H10 — Muon Nesterov Momentum Sweep (mu=0.90–0.98)

**Category:** Single mechanism | **Risk:** Low | **Complexity:** Very Low

**Mechanism:**
Current Muon uses Nesterov momentum mu=0.95. The optimal momentum for NS-
orthogonalized updates may differ from standard SGD theory (which suggests 0.9
for convex). Test sweep: [0.90, 0.92, 0.95, 0.97, 0.98]. Higher mu accumulates
more history; lower mu is more responsive to current gradient. The interplay with
NS's spectral normalization is non-obvious — NS already removes scale information,
so momentum serves purely as a direction smoother.

**Motivation relative to leaderboard:**
Momentum has never been ablated systematically in any record. Record #20 inherits
mu=0.95 from the original Muon paper. A small change (mu=0.97) may be worth
30–50 steps based on typical AdamW beta1 sensitivity at this model scale.

**Starting hyperparameters:**
- Sweep: mu ∈ [0.90, 0.92, 0.95, 0.97, 0.98]
- All other params identical to #20 baseline
- 5 configs × 1 seed each, 2000 steps (screen on val/loss at step 1750)

**Recommended train_steps:** 2000 for sweep; 3350 for top-2 confirmation.

**Implementation note:**
Pass `mu` as a parameter to `Muon.__init__`. Current code hardcodes 0.95 inside
`muon_update`. Add `self.mu = mu` and pass through.

---

### H11 — Fewer NS Iterations (8 instead of 12)

**Category:** Single mechanism | **Risk:** Low | **Complexity:** Very Low

**Mechanism:**
Current code runs 12 NS iterations (hardcoded). The convergence threshold for
NS with a=2, b=-1.5, c=0.5 is typically reached within 6–8 iterations for
well-conditioned gradient matrices. Reducing to 8 iterations saves compute per
step (reduces ~33% of NS cost). If gradient matrices are already well-conditioned
after Muon momentum smoothing, 8 iterations may produce effectively the same
orthogonalized update as 12 at lower cost, enabling either faster throughput or
extra training steps within the same wall-time budget.

**Motivation relative to leaderboard:**
The 12-iteration count was tuned for a more general setting. Our specific
gradient distribution may converge faster, especially after Nesterov momentum
(mu=0.95) smooths the input. This is a pure compute efficiency test with a
diagnostic value: if loss is unchanged at 8 iterations, we have headroom for
further reduction. If worse, 12 was needed.

**Starting hyperparameters:**
- Set NS loop to 8 iterations (was 12)
- All other params identical to #20
- Also test 6 iterations

**Recommended train_steps:** 3350 (1 seed each for 8 and 6 iterations).

**Implementation note:**
In `zeropower_via_newtonschulz5`, the loop `for _ in range(12)` becomes `range(8)`.
One-number change. Also log `train/grad/global_norm` to check if orthogonalization
is less complete (higher norms would indicate the update is less orthogonalized).

---

### H12 — Dual-Preconditioner Muon (Muon2 Preconditioning + KL-SOAP + Contra-Soft)

**Category:** Bold swing | **Risk:** High | **Complexity:** High

**Mechanism:**
Combine Muon2's second-moment pre-scaling with the existing #20 stack in full:
1. Apply Adam second-moment preconditioning to gradient before NS (H01 mechanism)
2. Retain Contra-Soft-Muon momentum modification
3. Retain KL-SOAP for LM head group
4. Reduce NS iterations from 12 to 8 (H11, consistent with Muon2 paper)

This is a three-component stack: (Muon2 gradient preconditioning) + (Contra-Soft
momentum) + (KL-SOAP). Each component has a different target: Muon2 conditions
the gradient magnitude entering NS; Contra-Soft shapes the momentum direction;
KL-SOAP provides second-order preconditioned updates for the LM head.

**Motivation relative to leaderboard:**
Record #20 already stacks Contra-Soft-Muon + KL-SOAP and achieves 3030. If each
component of the stack is genuinely addressing a different bottleneck, adding
Muon2's orthogonal contribution could yield another step reduction. The risk is
interference: three preconditioners may over-condition and dampen learning.

**Starting hyperparameters:**
- Muon2 beta2=0.999, eps=1e-8 (second moment for gradient before NS)
- Contra-Soft params: same as #20
- KL-SOAP params: same as #20
- Muon lr=0.030 (slightly reduced from 0.035 to account for extra conditioning)
- NS iterations: 8
- Run at 3350 steps, 1 seed first; kill early if val/loss > 3.32 at step 1000

**Recommended train_steps:** 3350 (1 seed screening, full 3350; no early kill
unless diverged or val/loss > 3.35 at step 500).

**Implementation note:**
Implement H01 first as a clean standalone PR, confirm it works, then build H12
on top of a merged H01. Do not attempt H12 before H01 is validated. H12 requires
LR retuning — consider a mini-sweep [0.025, 0.030, 0.035] for Muon lr after
combining components.

---

### H13 — Weight-Decay Warmup Schedule

**Category:** Schedule innovation | **Risk:** Low | **Complexity:** Low

**Mechanism:**
Current weight decay is constant at 0.025 throughout training for Muon. Apply a
warmup: start at wd=0 for the first 10% of steps, linearly ramp to 0.025 by step
335 (10% of 3350), then hold constant. Weight decay early in training can penalize
useful directions the optimizer hasn't had time to find yet; deferring it gives
the optimizer more freedom early on.

**Motivation relative to leaderboard:**
No record has varied weight decay schedule. Weight decay is a strong regularizer
that can interfere with the initial rapid loss descent. Deferring it for the first
~300 steps may let Muon make faster initial progress, while still providing full
regularization during the critical final 70% of training.

**Starting hyperparameters:**
- wd warmup: 0 → 0.025 over steps 0–335 (linear)
- After step 335: wd = 0.025 (constant)
- All other params identical to #20
- Also test: wd warmup 0 → 0.025 over steps 0–100

**Recommended train_steps:** 3350 (1 seed).

**Implementation note:**
Add to `set_hparams`: `wd = 0.025 * min(1.0, step / 335)`. Apply to Muon param
group only. Log `train/weight_decay/muon` to verify warmup is active.

---

### H14 — Adaptive Aspect-Ratio Scaling for Muon

**Category:** Single mechanism | **Risk:** Low-Medium | **Complexity:** Low

**Mechanism:**
Current Muon applies a fixed aspect-ratio scale `max(1, m/n)**0.5` to the NS
output, where (m, n) are the matrix dimensions. This scales the update magnitude
for tall matrices. Alternative: use `(m * n)**0.25 / max(m, n)**0.5` which
normalizes by the effective rank of the orthogonalized matrix rather than just
its shape. For square matrices this is equivalent; for rectangular matrices it
adjusts differently. The motivation is that NS outputs a near-orthogonal matrix
with singular values ~1 for square matrices but the effective update scale for
rectangular matrices depends on both dimensions.

**Motivation relative to leaderboard:**
The aspect-ratio scaling was introduced to handle the QKV weight matrices
(typically 3*d × d or d × d shape). The current `max(1, m/n)^0.5` formula was
derived heuristically. An alternative scaling `sqrt(max(m,n))` (treating it as
normalizing the Frobenius norm of an orthogonal matrix projected to rank=min(m,n))
may be better-calibrated. This is a low-cost architectural diagnostic.

**Starting hyperparameters:**
- Change `update *= max(1, grad.size(-2) / grad.size(-1))**0.5` to
  `update *= (grad.size(-2) * grad.size(-1))**0.25 / max(grad.size(-2), grad.size(-1))**0.5`
- All other params identical to #20
- Muon lr may need retuning: try [0.028, 0.035, 0.042]

**Recommended train_steps:** 3350 (1 seed screening with lr=0.035).

**Implementation note:**
The update scale change is one line in `muon_update`. Log `train/grad/rms` to
verify updates are neither exploding nor collapsing versus baseline.

---

### H15 — Full-Matrix Shampoo on Transformer Blocks

**Category:** New optimizer | **Risk:** High | **Complexity:** High

**Mechanism:**
Replace Muon entirely with distributed full-matrix Shampoo (Anil et al. 2020,
"Scalable Second Order Optimization for Deep Learning"). Shampoo maintains L and R
Kronecker factor matrices (L=GG^T, R=G^TG) and applies L^{-1/4} G R^{-1/4} as
the preconditioned update. Unlike SOAP which runs Adam in the Shampoo eigenbasis,
this is the direct Shampoo update. For 768-dim matrices, L ∈ R^{768×768} and
R ∈ R^{768×768}: full inversion requires O(768^3) per update step but can be
amortized by updating preconditioner every K=50 steps.

**Motivation relative to leaderboard:**
Shampoo with full preconditioning provides the theoretically tightest second-order
approximation. SOAP (used in #19 and #20) is Shampoo's Kronecker factorization
approximated via eigenbasis Adam, which loses fidelity. Direct Shampoo may find
better preconditioned descent directions, especially in the final 30% of training
where curvature information matters most.

**Starting hyperparameters:**
- Shampoo for all block matrices (ndim >= 2)
- Learning rate: 0.01 (much smaller than Muon's 0.035 since Shampoo steps are larger)
- Preconditioner update freq: 50 steps
- Grafting: use SGD grafting (scale Shampoo step by SGD step norm) to stabilize
- beta1=0.9 momentum on Shampoo update
- Keep AdamW for embed and LM head groups

**Recommended train_steps:** 3350 (1 seed; expect slower wall time due to matrix
inversions, monitor GPU utilization).

**Implementation note:**
Implement Shampoo in-file (no external deps). Key: maintain `L` and `R` as bf16
buffers. Use `torch.linalg.eigh` for symmetric eigendecomposition. Amortize at
freq=50. Grafting is critical for stability at the start of training. Reference:
distributed-shampoo implementation at github.com/google-research/google-research.

---

### H16 — Per-Layer Learning Rate Scaling via Gradient Norm

**Category:** Parameterization | **Risk:** Medium | **Complexity:** Medium

**Mechanism:**
Scale each layer's effective LR by the ratio of its current gradient RMS to the
global gradient RMS, so that layers with small gradients get proportionally higher
LR and layers with large gradients get proportionally lower LR. This is a simple
online per-layer scale: `lr_layer = lr_base / (grad_rms_layer / global_grad_rms + eps)`.
Recompute scale every 50 steps (not every step to reduce overhead). This adapts
the Muon LR to account for layer-wise gradient magnitude heterogeneity that the
global lr cannot address.

**Motivation relative to leaderboard:**
In 12-layer transformers, early and late layers typically have different gradient
magnitudes. A single global Muon lr compromises between them. Per-layer scaling
is a lighter-weight alternative to full per-parameter Adam updates and orthogonal
to NS's per-matrix normalization.

**Starting hyperparameters:**
- Base lr=0.035, per-layer scale updated every 50 steps
- Scale clipped to [0.5, 2.0] (prevent runaway per-layer LR)
- All other params identical to #20

**Recommended train_steps:** 3350 (1 seed screening).

**Implementation note:**
Collect `grad.norm(2)` per parameter group in the Muon loop. Compute mean across
all block params. Scale each param group's lr individually. This adds one
all-reduce per 50 steps for the norm collection (already logged in telemetry).

---

## Priority Ordering and Decision Tree

### Tier 1: High priority, run immediately (clean mechanism, low risk)

1. **H01 — Muon2 Preconditioned NS**: Strongest external evidence, not on
   leaderboard, clean mechanism, directly targets Muon's NS conditioning. Run first.

2. **H03 — Ablate Contra-Soft**: Cheap diagnostic. Tells us if #20's main gain
   was the KL-SOAP component or the Contra-Soft modification. Critical for
   understanding the stack before building further.

3. **H07 — Cosine Cooldown**: One-line change, strong external evidence from LLM
   literature, directly tests whether the cooldown shape limits final loss descent.

4. **H02 — Schedule-Free Muon**: Won MLCommons AlgoPerf 2024, no schedule analog
   in leaderboard history. Moderate complexity but strong motivation.

### Tier 2: Medium priority, run after Tier 1 results

5. **H04 — Ablate KL-SOAP**: Pairs with H03. Together, H03+H04 fully decompose
   record #20 into its components.

6. **H08 — Extended Stable Phase**: Trivial change, tests schedule width hypothesis.

7. **H11 — Fewer NS Iterations**: Compute efficiency + diagnostic for gradient
   conditioning. If val/loss unchanged, we have optimization headroom.

8. **H10 — Momentum Sweep**: Never been done, low cost, may find 50-step gain.

### Tier 3: Run after Tier 2 validates mechanism landscape

9. **H05 — muP LR Sweep**: Run as LR tuning support if H01 or H03 changes the
   optimal LR.
10. **H13 — WD Warmup**: Low risk, try after baseline is re-established.
11. **H14 — Adaptive Aspect Ratio**: Interesting but requires LR retuning; run
    after momentum is characterized.
12. **H16 — Per-Layer LR**: More complex; run after simpler schedule ideas.
13. **H06 — Proj Init**: Run as a paired ablation if val/loss curve shows early
    training instability in any Tier 1/2 run.

### Tier 4: High-risk/high-reward, run after Tier 1–2 establish new baseline

14. **H09 — Lion for Embeddings**: Low risk but small expected gain; schedule when
    students have capacity.
15. **H15 — Full Shampoo**: Expensive, high complexity; only if Tier 1–2 plateau.
16. **H12 — Dual Preconditioner Stack**: Build only after H01 is confirmed.

---

## Decision Tree for Top Experiments

```
Run H01 (Muon2)
├── val/loss < 3.276 at 3350 → confirm 4 seeds, then build H12
├── val/loss 3.276–3.285 → run H10 sweep to find Muon2 optimal lr/mu
│   └── If retuned Muon2 hits <3.276 → confirm 4 seeds
└── val/loss > 3.285 → NS preconditioning not helping; do NOT pursue H12
    └── Run H03 instead (ablate Contra-Soft from #20)

Run H03 (Ablate Contra-Soft)
├── val/loss matches #20 (< 3.282) → Contra-Soft is not load-bearing;
│   simplify stack; run H04 to check KL-SOAP
├── val/loss > 3.28 → Contra-Soft is load-bearing; do NOT remove; run H04
└── val/loss < 3.276 → surprising improvement; confirm 4 seeds immediately

Run H07 (Cosine Cooldown) [parallel with H03]
├── val/loss < 3.276 → merge; test cosine + #20 stack (easy combination)
├── val/loss 3.276–3.285 → record for schedule meta-analysis; run H08
└── val/loss > 3.285 → linear cooldown is fine; do not pursue further
    schedule changes of this type

Run H02 (Schedule-Free Muon) [independent thread]
├── val/loss < 3.276 at 3350 → very strong signal; confirm seeds
├── val/loss 3.276–3.285 → try longer run (4000 steps) — SF may need
│   more steps to converge
└── val/loss > 3.285 → SF not working in this regime; close
```

---

## Ruled-Out Directions (from Records #1–#21)

- Standard AdamW for block params: dominated by Muon and variants since record #4
- LAMB optimizer: implicitly tested in SOAP/Shampoo variants, not promising
- Gradient clipping (hard): no evidence in current stack; not a bottleneck
- Mixed-precision FP32: already using bf16 correctly
- Batch size changes: fixed by benchmark contract
- Architecture changes: fixed by benchmark contract
- Per-step LR schedule from scratch (no warmup): always worse in LLM literature

---

## Open Uncertainties (Top 3)

1. **Is Contra-Soft-Muon load-bearing in #20 or was the gain mostly from
   KL-SOAP retuning?** — H03 and H04 answer this.

2. **Does the 12-NS-iteration count have slack?** — H11 answers this; impacts
   compute budget for every future experiment.

3. **Is the 30%/70% cooldown split optimal or merely inherited?** — H07 and H08
   together answer this and establish whether schedule is a remaining lever.
