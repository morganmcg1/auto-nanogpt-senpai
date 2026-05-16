# Research Ideas — 2026-05-16 10:30

## Context

Wave-2 hypotheses for student `g1r5-frieren` on advisor branch `auto-nanogpt-1gpu-r5`.
Frieren just closed PR #47 (MuonH reproduction — clean negative, val/loss=3.2814,
misses target by 0.00142, 5.9σ above public record #5, attributed to
Blackwell+torch 2.11 numerical-path differences).

Current baseline (PR #46, SOAP-MLP isolated):
  ffs = 3200, mu = 3.27744, n = 6, std = 4.3e-4

Statistical merge threshold (mu-based):
  n=6: mu ≤ 3.27581   n=8: mu ≤ 3.27603

In-flight WIP slots (must not overlap):
  PR #130 (askeladd):  label smoothing on CE loss
  PR #123 (alphonse):  Newton-Muon activation-covariance right-precond
  PR #121 (tanjiro):   schedule-free Muon (Defazio averaging)
  PR #116 (fern):      SOAP-attn + trust gate
  PR #50  (thorfinn):  Polyak/SWA tail averaging
  PR #48  (nezuko):    cooldown shape sweep (status:review)
  PR #45  (edward):    Muon^2 sharper NS polynomial

Permanently closed: per-module init multipliers (PR #43/NorMuon, PR #47/MuonH family).
Do NOT repeat NorMuon, MuonH, or any per-module scale-tuning recipe.

---

## TOP PICK: Hypothesis A

### Gradient Centralization in the Muon update (before momentum)

#### Mechanism

The Muon optimizer applies a Newton-Schulz NS5 orthogonalization step to
gradients of 2D weight matrices. This projects each gradient onto the
nearest orthogonal matrix in Frobenius norm. However, the gradient entering
that projection is not zero-mean: it retains a row-mean component that encodes
the average signal across all output neurons. Gradient Centralization (GC)
removes this component first:

  g_centered = g - g.mean(dim=-1, keepdim=True)

This projects the gradient onto the hyperplane of zero-row-mean matrices
before momentum accumulation and before the NS5 step. The motivation is
two-fold. First, Yong et al. (2020) show that GC reduces the Lipschitz
constant of the loss with respect to the weights by a factor of up to
(W - 1) / W (where W is the number of output features), making the loss
landscape smoother and convergence more stable. Second, the NS5 step is
a spectral normalization that operates on the full gradient matrix —
centering before NS5 means the orthogonalization acts on a signal that is
already translation-free in the output dimension, which could help the
polar decomposition find a more semantically meaningful rotation rather
than an uncentered one.

Implementation is one line added to the Muon update function in
train_gpt_simple.py, inside the `muon_update` closure, immediately before
the `momentum.lerp_(grad, 1 - mu)` call:

  grad = grad - grad.mean(dim=-1, keepdim=True)

This applies only to the weights managed by Muon (attn.qkv, attn.proj,
mlp.fc1, mlp.proj — all 2D). The AdamW groups (embed, lm_head, scalars)
are unaffected. No new hyperparameters are introduced.

A clean negative here is scientifically informative: it would tell us that
NS5 orthogonalization already subsumes the centering benefit (because the
polar decomposition of a full-rank matrix implicitly removes the mean
component in spectral space). That is a concrete mechanistic answer, not
just a miss.

#### Orthogonality

No in-flight PR touches the gradient before the momentum accumulation step.
The closed PRs (NorMuon, MuonH) operated on post-update weight matrix
norms, not on pre-momentum gradient statistics. SOAP-MLP (merged) operates
on a preconditioned gradient matrix but does not subtract the row mean.
Newton-Muon (#123) applies covariance right-preconditioning after the
gradient, which is mathematically orthogonal (right vs left, covariance vs
mean subtraction). This slot is free.

#### Expected improvement

Estimated ffs: 3150–3185 (delta: -15 to -50 steps).
Expected mu drop: 0.0004–0.0010.

Reasoning: GC has shown 1–3% training speed improvements on ResNets and
~0.5% on fine-tuning tasks in the original paper. In the Muon setting, the
gradient norm is already regulated by NS5, so the centering may have lower
marginal impact than in Adam — hence the conservative low end of -15 steps.
The upper end of -50 assumes the centering provides a meaningful signal
refinement to the NS5 step that currently mixes mean and principal-component
directions.

#### Step budget and n

3200 steps, n=4 initial screen.
If n=4 screen mu ≤ 3.2770 (improvement ≥ 0.00044 vs baseline mu=3.27744),
expand to n=6 for statistical significance test.

#### Kill gates

- Kill at step 1000 if train/loss ≥ baseline train/loss + 0.002 (centering
  is removing useful gradient signal and slowing optimization).
- Kill hypothesis if n=4 mean ffs > 3220 (no directional signal).
- Do NOT retry with GC applied only to MLP weights if the full application
  fails — that variant is too similar to the SOAP MLP isolation already run
  to yield independent signal.

#### Paper pointer

arXiv:2004.01461 — "Gradient Centralization: A New Optimization Technique
for Deep Neural Networks" (Yong et al., 2020). Section 3 provides the
Lipschitz analysis. The integration with momentum-based optimizers is
described in Section 2. Note: original paper results are on image/text
classification; the mechanism transfers to any gradient-based update but
the magnitude of effect in a Muon+NS5 context has not been empirically
validated.

---

## Hypothesis B

### Output Embedding Mean-Centering (mu-centering) after each optimizer step

#### Mechanism

The model's output logit distribution suffers from a gauge degeneracy
familiar from the softmax partition function: adding a constant c to all
logits does not change any probability, loss, or gradient signal. This
means the logit mean can drift freely during training. The existing logit
softcap at 15 constrains the absolute magnitude of individual logits, but
it does not fix the partition function degeneracy — it is a hard clamp, not
a centering operation.

The output embedding matrix (lm_head.weight, shared or not with the token
embedding) accumulates this mean drift over training. Mu-centering removes
it deterministically after each optimizer step:

  lm_head.weight.data -= lm_head.weight.data.mean(dim=0, keepdim=True)

This is a one-line post-step operation added after `optimizer.step()` in the
training loop. It has zero computational cost (the mean subtraction over
50304 vocab entries by 768 channels is trivial vs. the transformer forward
pass). No new hyperparameters are introduced.

The mechanism is distinct from label smoothing (PR #130/askeladd), which
operates on the target distribution. It is also distinct from z-loss (a
loss-term penalty on log Z), which the Embedding Centering paper (arXiv:
2601.02031) shows underperforms mu-centering across all model sizes from
16M to 221M parameters. The softcap already bounds individual logit values;
mu-centering addresses the different problem of partition function translation
drift. The two are complementary rather than redundant.

A clean negative here would tell us the existing softcap at 15 already
eliminates enough drift that the centering provides no benefit, or that the
mean drift is self-corrected by the AdamW weight decay on lm_head.weight.
Both are concrete mechanistic conclusions.

#### Orthogonality

No in-flight PR modifies the output embedding or adds a post-step embedding
operation. Label smoothing (#130) modifies the loss targets, not the
embeddings. Polyak/SWA (#50) averages weights at the tail but does not
center them. This slot is free.

#### Expected improvement

Estimated ffs: 3160–3190 (delta: -10 to -40 steps).
Expected mu drop: 0.0003–0.0007.

Reasoning: The original centering paper reports up to 10x reduction in
learning-rate sensitivity and consistent loss reduction at the 16M–221M
scale. The effect is likely smaller here because the logit softcap already
partially restricts drift, and the 3200-step training run is short enough
that partition-function drift may not be severe. The lower end (-10 steps)
is the skeptical estimate under the softcap-dominates hypothesis.

#### Step budget and n

3200 steps, n=4 initial screen.
If n=4 screen mu ≤ 3.2770, expand to n=6.

#### Kill gates

- Kill at step 500 if train/loss ≥ baseline train/loss + 0.003 (centering
  is disrupting early optimization by zeroing useful logit directions).
- Kill hypothesis if n=4 mean ffs > 3230.
- Do NOT try with mean subtracted over vocab dimension (dim=1) rather than
  channel dimension (dim=0) as a follow-up if this fails — that variant has
  no theoretical grounding.

#### Paper pointer

arXiv:2601.02031 — "Output Embedding Centering for Stable LLM Pretraining"
(2025). Section 4 provides the comparison of z-loss vs mu-loss vs
mu-centering. Table 2 shows mu-centering outperforming z-loss (lambda=0.1)
and mu-loss at every learning rate tested, across 16M–221M parameter models.
Section 3.2 gives the exact post-step operation. Results are on GPT-like
architectures trained on standard language modeling objectives, directly
comparable to the modded-nanogpt setting.

---

## TOP PICK RECOMMENDATION

**Assign Hypothesis A (Gradient Centralization) to frieren.**

GC is a single-line change with no new hyperparameters, operating in the
same part of the stack as frieren's previous work (the Muon update path)
and adding a clearly distinct mechanism (pre-momentum row-mean subtraction)
that has not been tried. It is fully orthogonal to all 7 in-flight PRs.
A clean negative would produce a sharp mechanistic conclusion — NS5
subsumes the centering benefit — which is itself a useful result for the
research map. Hypothesis B (mu-centering) is the natural follow-up if GC
succeeds or if Newton-Muon (#123) wins and the loss-side / embedding-side
slots are still open.
