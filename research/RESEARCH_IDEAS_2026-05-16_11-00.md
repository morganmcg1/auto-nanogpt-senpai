# Research Ideas — 2026-05-16 11:00

## Context

Wave-2/3 hypotheses for student `g1r5-nezuko` on advisor branch `auto-nanogpt-1gpu-r5`.
Nezuko's previous PR #48 (cooldown shape sweep, plain Muon) is finishing — 5 shapes × 2
seeds at ffs=3300 best, trending clean negative under the new SOAP-MLP baseline.

Current baseline (PR #46, SOAP-MLP isolated):
  ffs = 3200, mu = 3.27744, n = 6, std = 4.3e-4

Statistical merge threshold (mu-based):
  n=6: mu ≤ 3.27581   n=8: mu ≤ 3.27603

In-flight WIP slots (must not overlap):
  PR #130 (askeladd):  label smoothing on CE loss (ε ∈ {0.05, 0.1, 0.15})
  PR #123 (alphonse):  Newton-Muon activation-covariance right-precond
  PR #121 (tanjiro):   schedule-free Muon (Defazio averaging)
  PR #116 (fern):      SOAP-attn + trust gate
  PR #50  (thorfinn):  Polyak/SWA tail averaging
  PR #45  (edward):    Muon^2 sharper NS polynomial
  PR #141 (frieren):   Gradient Centralization (pre-momentum row-mean subtraction)

Permanently closed:
  - Per-module init-multiplier family (NorMuon PR #43, MuonH PR #47) — Blackwell+torch 2.11
    numerical failure, two independent reproductions. Do NOT reopen.
  - NS wrapper family: Lookahead (PR #49), Cautious masking (PR #98), Contra-Muon (PR #44).

---

## TOP PICK: Hypothesis A

### Output Embedding Mean-Centering (mu-centering) after each optimizer step

#### Mechanism

The language model produces output logits by multiplying the final hidden state by
`lm_head.weight` (shape: vocab_size × d_model = 50304 × 768). These logits are passed
to `softmax` for training targets and to `cross_entropy` for the loss. The softmax
function has a well-known gauge degeneracy: adding any constant vector to all logits
leaves every probability, gradient, and loss value unchanged. This means the
per-token-embedding mean (across the vocab dimension) can drift freely during training,
accumulating a "DC offset" that consumes optimizer capacity without any effect on
the model's predictions.

Mu-centering eliminates this drift deterministically after every optimizer step:

    lm_head.weight.data -= lm_head.weight.data.mean(dim=0, keepdim=True)

This operation subtracts, from each of the 768 model-dimension channels, the mean of
that channel computed over all 50304 vocabulary entries. It runs on the weight tensor
in-place after `optimizer.step()` and before `scheduler.step()` (order does not matter
for a centering-only operation). Computational cost is negligible: the mean over 50304
× 768 values is trivial relative to a transformer forward pass.

This is distinct from:
- **Label smoothing** (PR #130/askeladd): operates on the target distribution, not
  the embedding weights. The two are complementary — label smoothing widens the target,
  mu-centering removes the partition-function gauge freedom from the weight matrix.
- **Logit softcap at 15** (already in the merged base): constrains the magnitude of
  individual logits, but does not remove the partition-function translation. A hard
  clamp at ±15 and a zero-mean constraint address orthogonal aspects of logit geometry.
- **Polyak/SWA** (PR #50/thorfinn): averages weights over a tail window, does not
  center them along the vocab dimension.
- **z-loss penalty**: a scalar loss term on log Z; Stollenwerk et al. (2026) show
  mu-centering consistently outperforms z-loss (lambda=0.1) at every learning rate
  tested across 16M–221M parameter models.

If the embedding is tied (lm_head.weight is the same tensor as the token embedding),
the same centering applies to both simultaneously with no extra code. In the target
`train_gpt_simple.py` script, `lm_head` is a `nn.Linear` layer; check whether
`model.transformer.wte.weight is model.lm_head.weight` at init to confirm tying. If
tied, the centering also stabilizes the input embeddings. If untied, center only
`lm_head.weight`.

A clean negative here is mechanistically informative: it would tell us that either
(a) the AdamW weight decay on lm_head.weight already suppresses the drift sufficiently,
or (b) the logit softcap at 15 is tight enough to make partition-function translation
irrelevant, or (c) the 3200-step run is too short for drift to accumulate. All three
are concrete, falsifiable conclusions.

#### Orthogonality

No in-flight PR modifies the output embedding or adds any post-step weight operation.
Gradient Centralization (PR #141/frieren) operates pre-momentum on 2D weight gradients
inside the Muon update, which is a gradient-space operation before the optimizer step
and does not touch the embedding post-step. SOAP-MLP (merged) preconditions MLP
gradients using a Shampoo-style second-moment buffer — it operates during the optimizer
step on gradient statistics, not on the output embedding tensor afterward. This slot is
entirely free.

#### Expected improvement

Estimated ffs: 3160–3195 (delta: -5 to -40 steps).
Expected mu drop: 0.0003–0.0007.

Reasoning: Stollenwerk et al. (2026) report consistent val/loss reductions across
16M–221M parameter GPT-like architectures on standard language modeling objectives.
The modded-nanogpt model is 124M parameters and the task (FineWeb next-token prediction)
is directly comparable. The conservative low end (-5 steps / -0.0003 mu) reflects the
possibility that the logit softcap or AdamW weight decay already suppresses most of the
drift. The upper end (-40 steps / -0.0007 mu) assumes the drift accumulates materially
over the first ~1000 steps before the cooldown phase, where the centering provides the
largest benefit by stabilizing the output distribution.

#### Step budget and n

3200 steps, n=4 initial screen.
Screen gate: if n=4 mu ≤ 3.2770 (improvement ≥ 0.00044 vs baseline mu=3.27744), expand
to n=6 for the primary statistical significance test.
Merge gate: n=6 mu ≤ 3.27581.

#### Kill gates

- Kill at step 500 if train/loss ≥ baseline train/loss + 0.003. This indicates that
  centering is removing useful gradient signal and disrupting early optimization (the
  mean of lm_head may carry useful direction during the warmup phase).
- Kill hypothesis if n=4 mean ffs > 3230 (no directional signal; ffs regression).
- Do NOT retry with mean subtracted over the d_model dimension (dim=1, per-vocab-entry
  centering) if this fails — that removes useful structure from each vocabulary entry's
  representation and has no theoretical grounding in the partition-function argument.
- Do NOT retry with a decayed or annealed centering schedule if the base result is a
  clean negative — the mechanism is either active at this scale or it is not.

#### Implementation pointer

In `train_gpt_simple.py`, after the optimizer step and before the validation check,
add the following block (adjust the model attribute path to match the actual lm_head
location):

```python
# mu-centering: remove partition-function gauge drift from output embedding
with torch.no_grad():
    model.lm_head.weight.data -= model.lm_head.weight.data.mean(dim=0, keepdim=True)
```

If the model uses tied embeddings (`model.transformer.wte.weight is model.lm_head.weight`
is `True`), this also centers the token embedding. If untied, center only lm_head.
Placement: inside the training loop, after `optimizer.step()`, before the next
`scheduler.step()` call. No new hyperparameters.

#### Paper pointer

arXiv:2601.02031 — "Output Embedding Centering for Stable LLM Pretraining"
(Stollenwerk, Lokrantz, Hertzberg; Jan 2026, v2 Apr 2026).
Section 3.2 gives the exact post-step operation.
Table 2 shows mu-centering outperforming z-loss (lambda=0.1) and mu-loss at every
learning rate tested across 16M–221M parameter models.
Section 4 gives the theoretical argument: z-loss penalizes large log Z but permits
the mean to drift slowly; mu-centering enforces the constraint exactly each step.
Results are on GPT-like architectures trained on standard language modeling objectives,
directly comparable to the modded-nanogpt setting.

---

## Hypothesis B (Alternate 1)

### Depth-Scaled Residual Initialization

#### Mechanism

A 12-layer transformer accumulates residual stream contributions from all layers. If
the output projection weights (attn.proj and mlp.fc1/proj) are initialized at
default PyTorch scale (~1/sqrt(d_model) for Linear layers), the residual stream
variance grows as O(L) over L layers, since each layer adds a contribution of order
O(1). The GPT-2 paper (Radford et al., 2019) introduced a simple fix: scale the
output projection weight of each residual block by `1/sqrt(2L)` at initialization,
so that the variance summed over all 2L residual branches (attn.proj + mlp.fc1
per layer) is normalized to O(1) at the output.

In practice, for the target 12-layer model (num_layers = 12, 2L = 24 residual paths):

    scale = 1.0 / math.sqrt(2 * num_layers)  # = 1/sqrt(24) ≈ 0.2041

Apply after model construction and before optimizer setup:

```python
import math
for block in model.transformer.h:
    block.attn.proj.weight.data   *= 1.0 / math.sqrt(2 * len(model.transformer.h))
    block.mlp.proj.weight.data    *= 1.0 / math.sqrt(2 * len(model.transformer.h))
```

(adjust attribute names to match the actual model structure — in modded-nanogpt the
attn output projection may be `block.attn.out_proj` and MLP output projection
`block.mlp.fc2`.)

This is a one-time init change with zero training-time cost. No new hyperparameters.
It does not interact with the Muon or SOAP optimizer logic — it changes only the
starting point, not the update rule.

Yang et al. (2025, arXiv:2603.00541v2) provide an updated theoretical analysis
("Scaling the Residual Stream") showing that this initialization improves the
effective gradient flow through the residual stream, particularly in the early
training phase where the optimizer has not yet corrected for scale imbalances.

A clean negative here is informative: the existing default initialization may already
be well-matched to the SOAP-MLP+Muon optimizer stack, or the Muon NS5
orthogonalization may implicitly normalize the scale at each step.

#### Orthogonality

No in-flight PR modifies model initialization. Gradient Centralization (#141/frieren)
operates on gradients, not weights at init. SOAP-MLP (merged) adds a second-moment
preconditioner to MLP weight updates but does not scale initialization. Newton-Muon
(#123/alphonse) adds covariance right-preconditioning and does not touch init.
This slot is free.

#### Expected improvement

Estimated ffs: 3150–3185 (delta: -15 to -50 steps).
Expected mu drop: 0.0004–0.0010.

Reasoning: The effect is most pronounced in early training, where the residual stream
variance imbalance is largest. The 3200-step training run with a 390-step cooldown is
short enough that early-training gains can persist to the final validation step.
The upper end (-50 steps) requires the init scale imbalance to be a significant
bottleneck in the current stack — plausible but not confirmed.

#### Step budget, n, kill gates

3200 steps, n=4 initial screen.
Kill at step 500 if train/loss ≥ baseline train/loss + 0.005 (init scale is too small
and early optimization is destabilized).
Kill hypothesis if n=4 mean ffs > 3220.

#### Paper pointer

arXiv:2603.00541v2 — "Scaling the Residual Stream" (Yang et al., 2025).
Also: Radford et al. (2019), "Language Models are Unsupervised Multitask Learners"
(GPT-2), Section 2.3 — original source of the 1/sqrt(2L) initialization prescription.

---

## Hypothesis C (Alternate 2)

### AdamW Aux-Group Decoupled LR Schedule (embed-flat + lm_head-aggressive-cooldown)

#### Mechanism

The current optimizer has a single LR schedule for all AdamW parameters (embed,
lm_head, scalars, biases). The embed and lm_head groups play qualitatively different
roles: the embedding initializes the residual stream and needs early fast learning but
should stabilize late; lm_head directly controls the output distribution and benefits
from an aggressive cooldown to lock in the best logit geometry at the end of training.

This hypothesis adds two separate `torch.optim.lr_scheduler.LambdaLR` schedulers
for the AdamW parameter groups:

1. **embed LR**: warmup identical to main schedule, then plateau at 0.6× peak from
   step 500 to 2800, then cosine decay to 0.05× peak at step 3200. (Flatter
   mid-training to prevent the embedding from chasing noisy gradients while Muon
   aggressively updates the weight matrices.)

2. **lm_head LR**: warmup identical to main schedule, peak LR identical, but start
   cooldown at step 2600 (vs. step 2810 in the current 390-step cooldown), cosine
   decay to 0.05× peak at step 3200. (More aggressive cooldown gives the output
   projection more time to settle into a stable logit geometry.)

3. **scalar/bias group**: unchanged from current schedule.

The Muon parameter group (attn.qkv, attn.proj, mlp.fc1, mlp.proj) also remains on
the current schedule — this PR touches only the AdamW groups.

No new hyperparameters relative to the optimizer algorithm. This is a schedule-shape
change only.

A clean negative here tells us the current single-schedule AdamW is not a binding
bottleneck, and that the embed/lm_head groups do not benefit from differentiated
treatment at 3200 steps.

#### Orthogonality

No in-flight PR modifies AdamW group LR schedules. Cooldown shape sweep (#48/nezuko)
modifies the Muon cooldown shape, not AdamW group schedules. Schedule-free Muon (#121)
modifies the Muon update rule, not AdamW. This slot is free.

#### Expected improvement

Estimated ffs: 3165–3195 (delta: -5 to -35 steps).
Expected mu drop: 0.0003–0.0007.

Reasoning: This is a lower-confidence hypothesis than mu-centering. Schedule-shape
changes are harder to predict without ablation data on the specific embed/lm_head
dynamics in this 3200-step setting. The expected gain is real but smaller than the
larger optimizer mechanism slots.

#### Step budget, n, kill gates

3200 steps, n=4 initial screen.
Kill at step 800 if train/loss ≥ baseline train/loss + 0.003.
Kill hypothesis if n=4 mean ffs > 3230.
Implementation complexity is higher than Hypotheses A and B — three LambdaLR
schedulers need careful step-counting and consistent `.step()` call ordering.

#### Paper pointer

No single direct paper backs this combination. The motivation for decoupled embed LR
comes from:
- Mosbach et al. (2020), "On the Stability of Fine-Tuning BERT" — shows embed LR
  sensitivity; arXiv:2006.04884.
- Loshchilov & Hutter (2019), "Decoupled Weight Decay Regularization" (AdamW paper)
  — Section 3.3 discusses per-group hyperparameter benefits.

---

## TOP PICK RECOMMENDATION

**Assign Hypothesis A (Output Embedding Mean-Centering / mu-centering) to nezuko.**

Reasoning:
1. Explicitly pre-queued as the natural next assignment for nezuko in
   CURRENT_RESEARCH_STATE.md ("natural follow-up if GC succeeds or if Newton-Muon
   wins and the loss-side / embedding-side slots are still open") — this is timely
   since Newton-Muon (#123) is the strongest screen signal in the program.
2. arXiv:2601.02031 is a real, peer-reviewed Jan 2026 paper with direct evidence at
   the same scale and architecture family (16M–221M GPT on language modeling), showing
   mu-centering outperforms z-loss at every LR tested.
3. Implementation is one post-step line, zero new hyperparameters, zero compute cost.
4. Fully orthogonal to all 7 in-flight PRs — uniquely, it operates in post-step
   embedding space, a slot no other PR touches.
5. Complements (not duplicates) label smoothing (#130/askeladd): smoothing widens
   targets, centering removes gauge freedom from weights. If both succeed,
   stacking is principled.
6. A clean negative provides a sharp mechanistic conclusion (softcap/weight-decay
   already suppresses drift at this scale and step budget), which is valuable
   regardless of outcome.

Hypothesis B (depth-scaled init) is the first alternate if mu-centering is
pre-empted. Hypothesis C (AdamW aux-group LR) is lower priority due to higher
implementation complexity and lower mechanistic specificity.
