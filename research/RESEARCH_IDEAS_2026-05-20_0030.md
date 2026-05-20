# Research Ideas — 2026-05-20 00:30

**Baseline (PR #415 merged):** val/loss=3.273477, ffs_mean=3056.25, train_steps=3175
**Stack:** NS5_ITERS=14 + WD_AUX=0.001 + Contra-Muon=0.4 + SOAP(FREQ=10, β2=0.90) + Attn-SOAP-trust T=0.85 + cooldown-only μ anneal 0.95→0.90 + MU_WARMUP_STEPS=200 + MU_WARMUP_START=0.85
**Gate:** n=2 screen; advance to n=4 confirm only if ≥1 arm clears BOTH val < 3.271388 AND ffs_mean < 3025.

---

## Idea 1 — NAdamW: Nesterov Momentum on AdamW-path

**Mechanism:** Replace the standard Adam first-moment term in the AdamW update with Nesterov's look-ahead form. Specifically, replace `m_hat * step_size / (sqrt(v_hat) + eps)` with `(β1 * m_hat + (1-β1) * grad) * step_size / (sqrt(v_hat) + eps)`. This computes the effective gradient at the extrapolated point in parameter space, providing one step of momentum-direction correction per update. Applied only to the AdamW group (embed+lm_head+scalars); the Muon group is unaffected.

**Why it should beat baseline:** The AdamW group currently uses vanilla Adam momentum (β1=0.80), which lags one step behind the gradient direction. Nesterov's correction was shown by Dozat 2016 to consistently reduce validation loss in adaptive methods. On the embed/lm_head matrices — which see correlated gradient sequences due to token frequency distributions — the look-ahead step is especially likely to improve convergence because token embeddings update in structured directions predictable from current momentum. This is a direct, low-cost intervention on the AdamW-path, the priority axis since cycle 67.

**n=2 screen env-var flags:**
- Arm A: `NADAMW=1` (Nesterov enabled, β1=0.80 unchanged — pure mechanism test)
- Arm B: `NADAMW=1 ADAM_BETA1=0.85` (Nesterov + slightly higher β1 to compensate for lookahead; closer to PyTorch default 0.9)

**Falsification criteria:** Declare falsified if both arms yield val_loss ≥ 3.273477 at best checkpoint, or if Nesterov causes gradient explosion (loss spike > 3.40) within the first 100 steps.

**Risk level:** Low. ~8 LoC change to AdamW update loop (single line replace). No new buffers, no new hyperparameters in Arm A. Fully orthogonal to all Muon-path mechanisms.

**LoC estimate:** ~8

**Key references:** Dozat 2016, "Incorporating Nesterov Momentum into Adam," ICLR 2016 Workshop (openreview.net/pdf/OM0jvwB8jIp57ZJjtNEZ.pdf). Surveyed in arxiv 2002.10980 as part of the canonical Adam-variant family.

---

## Idea 2 — SOAP on lm_head: Shampoo-style Preconditioning for Output Projection

**Mechanism:** Extend the existing SOAP preconditioner infrastructure (already applied to attention matrices) to also cover the lm_head weight matrix (vocab_size × n_embd). Currently lm_head lives in the AdamW group and receives only diagonal (Adam-style) second-moment preconditioning. Moving lm_head to receive Shampoo-style left/right factor preconditioning exploits the low-rank structure of the output-projection gradient, which is determined by the small set of active token positions per batch. The existing SOAP implementation's eigenbasis refresh (FREQ=10) is reused with no architectural changes required — only the optimizer group assignment changes.

**Why it should beat baseline:** The output projection matrix (lm_head) operates in the dual role of token unembedding and softmax normalization. Its gradient at each step is a rank-≤batch_size outer product (active tokens × hidden states), making it structurally identical to the attention matrices for which SOAP already demonstrates benefit. The ATTN_SOAP_TRUST_THRESHOLD ablation (#420) showed SOAP contributes measurably on this stack — if that contribution is partially from lm_head being underserved by diagonal preconditioning, extending SOAP coverage closes that gap. This is a structural change (new optimizer group coverage), not an HP sweep. The mechanism is categorically distinct from prior lm_head experiments (#312 WD, #431 LR scaling) which adjusted regularization/LR, not preconditioning geometry.

**n=2 screen env-var flags:**
- Arm A: `LM_HEAD_SOAP=1 LM_HEAD_SOAP_FREQ=10` (same refresh frequency as attention SOAP)
- Arm B: `LM_HEAD_SOAP=1 LM_HEAD_SOAP_FREQ=5` (more frequent refresh; smaller matrices allow more frequent eigen-updates)

**Falsification criteria:** Declare falsified if both arms yield val_loss ≥ 3.273477, or if lm_head SOAP causes memory OOM or step-time regression > 15% (indicating Kronecker factor computation is prohibitively large for the vocab_size dimension).

**Risk level:** Medium. ~20-30 LoC to add lm_head to SOAP group or instantiate a second SOAP instance. Main risk: lm_head matrix dimension (vocab_size=50257 × n_embd) may be too large for practical Kronecker factor computation in the left-factor direction. Pre-screen: confirm vocab_size × n_embd fits in existing SOAP memory allocation before running; if the vocab_size factor is too large, the implementation should fall back to applying SOAP only to the n_embd × n_embd right factor (which is always tractable).

**LoC estimate:** ~25

**Key reference:** arxiv 2409.11321 (Vyas et al. 2024, "SOAP: Improving and Stabilizing Shampoo using Adam in its Eigenbasis"). Directly instantiates the same SOAP algorithm already deployed for attention matrices, now applied to lm_head.

---

## Idea 3 — SWA Tail Averaging at Eval

**Mechanism:** During the final N steps of the cooldown phase, maintain a uniform running average of model weights alongside the normal optimizer state. At the final validation checkpoint, substitute the uniform-average weights for the standard last-iterate weights. The training trajectory is completely unmodified — the SWA buffer is write-only during training and only read at eval time. Uniform average update: `w_swa = (w_swa * t + w_t) / (t+1)` at each step within the tail window. Implementation: track `swa_buffer` dict and `swa_count` counter; activate at step `(total_steps - SWA_WINDOW)`.

**Why it should beat baseline:** The cooldown phase (cooldown_frac=0.70 → ~2222 steps) terminates with the model on a sharp loss surface shaped by LR decay. The final steps of cooldown explore a narrow valley where the last iterate is sensitive to the stopping point. Uniform averaging over this tail moves the effective evaluation point to the geometric center of the late-cooldown trajectory, which SWA theory (Izmailov et al. 2018) proves lies in a flatter region of the loss surface with better generalization. This is directly analogous to the ffs bimodal variance problem: trials that stochastically stop at ffs=3025 vs ffs=3050 differ by ~25-step position along the cooldown; SWA averaging reduces this sensitivity by evaluating at the mean trajectory point rather than the terminal point. **Critical distinction from PR #286 (Polyak-Ruppert EMA, FALSIFIED):** PR #286 used exponential moving average (decaying weight to old iterates) applied throughout training as a separate parameter track. SWA uses uniform (non-decaying) averaging applied only to a fixed terminal window, substituted only at eval — these are mechanistically and temporally distinct operations and SWA is not covered by the PR #286 falsification.

**n=2 screen env-var flags:**
- Arm A: `SWA_EVAL=1 SWA_WINDOW=150` (average last 150 cooldown steps — ~7% of total training)
- Arm B: `SWA_EVAL=1 SWA_WINDOW=300` (wider averaging — ~13% of total training, higher smoothing)

**Falsification criteria:** Declare falsified if both arms yield val_loss ≥ 3.273477 or ffs is unchanged vs standard eval (indicating the ffs measurement already uses early checkpoints, not the terminal weight). Also declare falsified if the ffs measurement infrastructure does not read from the terminal eval weights but from intermediate validation checkpoints during training — in that case SWA cannot affect ffs and this mechanism should be re-scoped to val_loss only.

**Risk level:** Low. ~15 LoC. Zero impact on training trajectory (eval-only substitution). The only meaningful risk is if the cooldown tail window is too short for meaningful averaging, or if ffs is measured from intermediate validation checkpoints rather than the terminal weight, in which case SWA affects val_loss but not ffs.

**LoC estimate:** ~15

**Key reference:** arxiv 1803.05407 (Izmailov et al. 2018, "Averaging Weights Leads to Wider Optima and Better Generalization").

---

## Priority Order

1. **Idea 3 (SWA)** — lowest risk, zero training-trajectory cost, addresses the ffs variance problem directly. Run first.
2. **Idea 1 (NAdamW)** — low risk, ~8 LoC, directly on AdamW-path (the priority axis since cycle 67).
3. **Idea 2 (SOAP on lm_head)** — medium risk due to memory concerns on the vocab_size Kronecker factor; run after confirming Idea 1.

## Do Not Repeat

In addition to all previously falsified axes, also do NOT re-propose: Lookahead-AdamW (#459), Cooldown polynomial power (#464/#485), MU_WARMUP_START sweep (#462), TARGET_UW sweep (#498), AdamW β1 sweep (#488), grad-clip (#493), LM_HEAD_LR (#431), EMBED_LR (#449), SCALARS_LR (#456), AdamW β2 sweep (#343), AdEMAMix (#515, in-flight), Cautious AdamW (#523, in-flight).
