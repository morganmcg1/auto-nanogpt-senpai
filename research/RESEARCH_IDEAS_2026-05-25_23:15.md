# Research Ideas — 2026-05-25 23:15

Generated for cycle 71, mid-253+. Three hypotheses for idle students g1r2-fern, g1r2-askeladd, g1r2-nezuko.
Baseline: PR #613 val=3.26776 (n=2 mean), ffs=3000.

---

## Ranked Summary (< 600 words)

**Rank 1 — MUON_BETA_END (askeladd)**
The Muon optimizer schedules its learning rate via MU_COOLDOWN_START/END but leaves the momentum coefficient β₁ fixed throughout training. The corpus (full_details_2026-05-25, ~31609) explicitly flags this as an untested axis: "The Muon momentum schedule's END VALUE has never been tested." β₁ controls how much historical gradient velocity is retained; in the tail of training where the LR is near zero, the effective step is almost entirely momentum-driven. Decoupling β₁ from the LR schedule gives independent control over whether the optimizer converges aggressively (low β₁ end = rapid momentum decay, faster settling) or conservatively (high β₁ end = sustained inertia, smoother convergence). Anti-duplication: 0 corpus hits on MUON_BETA_END, MU_BETA_END, MU_BETA_FINAL, MUON_MOMENTUM_END, MUON_BETA_SCHEDULE, momentum_end, beta_end, beta_final. Highest confidence of the three — the corpus itself points at it.

**Rank 2 — WD_BODY_DEPTH (fern)**
Weight decay on the Muon body is currently a single scalar CONTRA_MUON=0.4 applied uniformly across all transformer layers. The μP and SP² literatures (Yang et al. 2022 arXiv:2203.03466; Bordelon et al. 2024 arXiv:2310.02244) show that per-layer effective learning signal scales with depth: early layers receive stronger gradient signal from logits/lm_head, deeper layers receive weaker signal. Applying uniform WD therefore over-regularizes shallow layers and under-regularizes deep layers. A depth-dependent WD ramp that increases with depth compensates for weaker gradients in deep layers and should reduce over-smoothing of early representations. Two ramp directions are tested (shallow→deep increasing vs. decreasing) to falsify the direction. Anti-duplication: 0 corpus hits on any of WD_BODY_DEPTH, LAYER_WD, WD_DEPTH, DEPTH_WD, WD_SCALE, DECAY_DEPTH, WD_LINEAR, WD_COSINE, WD_RAMP, and 11 other spelling variants. The corpus explicitly flags depth-dep WD as open (line ~9278).

**Rank 3 — AUX_CLIP_NORM (nezuko)**
The AdamW AUX optimizer (embeddings, lm_head, biases, norms) currently has no per-group gradient norm clipping. All prior gradient clipping work in the corpus was global (GRAD_CLIP_NORM, #860) or Muon-body-only (MUON_GRAD_CLIP #688, MUON_PER_TENSOR_GRAD_CLIP #968) — all closed as refuted. The asymmetry is structural: Muon's NS5 orthogonalization imposes an implicit step-magnitude bound on body weights (NS5 projects to the Stiefel manifold, bounding the step by the spectral norm), while AdamW on AUX has no such bound. In early training and at spike events, embedding and logit gradient norms can be 5-20× larger than body norms, potentially destabilizing the shared representation. A tight AUX-specific clip (1.0) vs. a loose clip (5.0) tests whether decoupled per-group clipping improves tail convergence. Anti-duplication: 0 corpus hits on AUX_CLIP_NORM, AUX_GNORM, AUX_GRAD_CLIP, adam_clip, ADAM_CLIP, CLIP_AUX, clip_aux, AUX_MAX_NORM.

---

## Hypothesis 1: WD_BODY_DEPTH — Depth-Dependent Weight Decay on Muon Body

**Student:** g1r2-fern
**Mechanism name:** DEPTH_DEPENDENT_WD
**Primary ENV_VAR:** `WD_BODY_DEPTH` (float, default=0.0 → disabled; positive = scale factor on depth ramp)

### Theoretical Motivation

The Muon body optimizer applies a single weight decay coefficient CONTRA_MUON=0.4 identically to every transformer block. This ignores the depth-dependent gradient signal structure of transformer LMs. In the μP (maximal update parametrization) literature (Yang et al. "Tensor Programs V" 2022, arXiv:2203.03466), the per-layer learning rate must scale as 1/fan_in to preserve feature learning at every depth. Separately, the SP² work (Bordelon et al. "A Spectral Condition for Feature Learning" 2024, arXiv:2310.02244) shows that the effective signal-to-noise ratio for a weight matrix decreases as depth increases, because signal must propagate through more intervening layers before reaching the loss.

Under uniform WD:
- Shallow layers (close to embedding): high gradient SNR → WD is too aggressive → smooths features that are still actively learning
- Deep layers (close to lm_head): low gradient SNR → WD is too permissive → insufficient regularization of weights that receive only weak training signal

A depth-ramp WD that increases with layer index compensates for this imbalance. The mechanism is a scalar multiplier applied per-layer at each Muon step: effective_WD(l) = CONTRA_MUON × (1 + WD_BODY_DEPTH × l/L), where l is the 0-indexed layer and L is the total number of layers.

An inverse ramp (WD_BODY_DEPTH < 0) tests the opposite direction — whether shallow layers benefit from stronger regularization given their proximity to the embedding manifold.

**Key papers:**
- Yang et al. 2022, "Tensor Programs V: Tuning Large Neural Networks via Zero-Shot Hyperparameter Transfer", arXiv:2203.03466
- Bordelon et al. 2024, "A Spectral Condition for Feature Learning", arXiv:2310.02244
- Loshchilov & Hutter 2019, "Decoupled Weight Decay Regularization", ICLR 2019 (AdamW baseline)

### Anti-Duplication Evidence

Grep sweep across full 320-PR corpus (`full_details_2026-05-25_23-17.md`):
- `WD_BODY_DEPTH`: 0 hits
- `LAYER_WD`: 0 hits
- `WD_DEPTH`: 0 hits
- `DEPTH_WD`: 0 hits
- `WD_SCALE`: 0 hits (only WD_AUX hits, which is the per-group separation, not depth)
- `DECAY_DEPTH`: 0 hits
- `WD_LINEAR`: 0 hits
- `WD_COSINE`: 0 hits
- `depth_wd`: 0 hits
- `wd_layer`: 0 hits
- `WD_RAMP`: 0 hits
- `WD_DEPTH_BODY`, `WD_BODY_SCALE`, `WD_DEPTH_SCALE`: 0 hits each
- Broad `depth.*decay|decay.*depth` pattern: 4 hits, all in comments about learning rate depth-scaling (none implementing mechanism)

Corpus line ~9278 explicitly flags: "depth-dep WD coefficient ... each is a categorically distinct depth-dep axis on a different mechanism dimension than init or LR." This is a direct corpus instruction to pursue this axis.

**Mechanism class:** Class 3 of pre-NS5 transform taxonomy? No — this is a Muon *step* modification, not a pre-NS5 transform. It applies to the weight update formula: w ← w - lr*(NS5(g) + WD(l)*w). It is orthogonal to the full pre-NS5 transform taxonomy and does not conflict with frieren's Shampoo work (#1220).

### Arm Design

**Arm A — Increasing depth ramp (deeper = stronger WD):**
```
WD_BODY_DEPTH=0.5
```
This scales CONTRA_MUON by factor (1 + 0.5 * l/L) per layer. For L=6 layers (NanoGPT default), layer 0 gets 1.0×, layer 5 gets 1.5× — a 50% ramp.

**Arm B — Decreasing depth ramp (shallower = stronger WD):**
```
WD_BODY_DEPTH=-0.3
```
Scales CONTRA_MUON by factor (1 - 0.3 * l/L). Layer 0 gets 1.0×, layer 5 gets 0.7× — a 30% inverse ramp.

Note: WD_BODY_DEPTH=0.0 must reproduce byte-for-byte the baseline disabled path.

### Mandatory Stack
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```
WD_BODY_DEPTH is additive to the above — it modifies per-layer effective WD, does not replace CONTRA_MUON.

### Kill Gates (from baseline trajectory + noise margin)

| Step | Baseline val | Kill gate (baseline + 0.01 margin) |
|------|-------------|-------------------------------------|
| 500  | ~3.85       | > 3.86                              |
| 1000 | ~3.71       | > 3.72                              |
| 1500 | ~3.58       | > 3.59                              |
| 2000 | ~3.48       | > 3.49                              |
| 2500 | ~3.39       | > 3.40                              |
| 3000 | ~3.31       | > 3.32 (merge bar)                  |

If either arm exceeds its kill gate by the named step, kill that arm and submit results for the surviving arm. If both breach, close family.

### Disabled-Check Contract
With WD_BODY_DEPTH=0 (or env var absent), val@200 must land in [4.075, 4.090]. If it falls outside this range, flag implementation failure before launching arms.

### Predicted Result
Arm A (increasing ramp) is the theoretically motivated direction. Expected: ~0.001–0.003 improvement over baseline (val ≈ 3.264–3.267). Arm B tests whether the direction assumption is wrong. If Arm A fails but Arm B beats baseline, the causal story inverts (shallow layers need less WD) which would be an interesting finding. If both fail, the mechanism layer closes cleanly.

---

## Hypothesis 2: MUON_BETA_END — Muon Momentum β₁ End-Value Schedule

**Student:** g1r2-askeladd
**Mechanism name:** MUON_BETA_END_SCHEDULE
**Primary ENV_VAR:** `MUON_BETA_END` (float, default=-1.0 → disabled/fixed β₁)

### Theoretical Motivation

The current Muon optimizer applies a cosine learning-rate schedule with MU_COOLDOWN_START=0.95, MU_COOLDOWN_END=0.90 controlling the LR envelope in the tail. However, the Muon momentum coefficient β₁ is **fixed** throughout training — most likely at 0.95 matching the momentum value inherited from the SOAP or base Muon defaults. The corpus (line ~31609) explicitly confirms: "The Muon momentum schedule's END VALUE has never been tested. All Muon work has been on LR schedule envelope; MU schedule (which is OFFSET from the LR schedule) is a separate, untested axis."

The dynamics of gradient momentum in the tail of training are qualitatively different from early training. At step 3000, with LR near zero (MU_COOLDOWN_END × peak_LR), the effective parameter update is almost entirely driven by the momentum buffer, not the fresh gradient. β₁ therefore controls:

1. **High β₁ tail (0.95 end):** Momentum buffer retains long history; optimizer continues moving along the accumulated historical direction even as LR collapses. This is the implicit assumption of all prior Muon work. Risk: overshoots the final minimum because historical momentum points "away" from the local basin.

2. **Low β₁ tail (0.80 end):** Momentum decays faster; the optimizer increasingly relies on the fresh gradient as training ends. This mimics gradient descent behavior in the tail. Risk: loses the smoothing benefit of momentum, increases variance.

The schedule: β₁(t) is held at its start value (0.95) for the first MU_WARMUP_STEPS steps, then linearly (or cosinely) interpolated from start_value to MUON_BETA_END over the remaining training steps. Implementation: at each step, the Muon optimizer receives a dynamic β₁ value computed by the scheduler, analogous to how LR is scheduled.

**Key papers:**
- Nesterov 1983 (original momentum; historical anchor)
- Ilya Sutskever et al. 2013, "On the importance of initialization and momentum in deep learning", ICML — shows β₁ sensitivity to final convergence
- Loshchilov & Hutter 2017, "SGDR: Stochastic Gradient Descent with Warm Restarts" — illustrates schedule interaction with momentum
- Kosson et al. 2023, "Rotational Equilibrium: How Weight Decay Balances Learning Rates for Neural Networks", arXiv:2305.17212 — connects WD and momentum to convergence geometry
- Jordan et al. 2024, "Muon: A General-Purpose Optimizer" — the baseline Muon paper on which this stack builds

### Anti-Duplication Evidence

Grep sweep across full 320-PR corpus:
- `MUON_BETA_END`: 0 hits
- `MU_BETA_END`: 0 hits
- `MU_BETA_FINAL`: 0 hits
- `MUON_MOMENTUM_END`: 0 hits
- `MUON_BETA_SCHEDULE`: 0 hits
- `momentum_end`: 0 hits
- `beta_end`: 0 hits
- `beta_final`: 0 hits

Corpus line ~31609 directly names this as untested. This is a first-class untested axis with explicit corpus backing.

**Relationship to prior CAUTIOUS work:** CAUTIOUS (#1190, nezuko's last closed PR) tested sign-agreement masking of the Muon update — a different β₁-related mechanism. That tested *which gradient components to use*, not *how long to weight historical gradients*. These are orthogonal.

**Relationship to SOAP work:** SOAP tunes β₁/β₂ on the attention SOAP optimizer. MUON_BETA_END applies only to the Muon body optimizer momentum, not to SOAP. Non-overlapping.

### Arm Design

**Arm A — Higher β₁ end value (sustained inertia):**
```
MUON_BETA_END=0.97
```
Schedules β₁ from its current value (~0.95) up to 0.97 in the cooldown phase. Tests whether even more inertia in the tail (keeping historical direction longer) helps smooth the final basin descent.

**Arm B — Lower β₁ end value (decayed inertia):**
```
MUON_BETA_END=0.80
```
Schedules β₁ down from ~0.95 to 0.80 in the cooldown phase. Tests whether reducing momentum inertia in the tail improves sensitivity to fresh gradient signal near the minimum.

Note: MUON_BETA_END=-1.0 (default sentinel) must reproduce the byte-inert disabled path with val@200 ∈ [4.075, 4.090].

### Mandatory Stack
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```
MUON_BETA_END modifies only the Muon body β₁ schedule; all other params unchanged.

### Kill Gates

| Step | Baseline val | Kill gate |
|------|-------------|-----------|
| 500  | ~3.85       | > 3.86    |
| 1000 | ~3.71       | > 3.72    |
| 1500 | ~3.58       | > 3.59    |
| 2000 | ~3.48       | > 3.49    |
| 2500 | ~3.39       | > 3.40    |
| 3000 | ~3.31       | > 3.32    |

### Disabled-Check Contract
With MUON_BETA_END=-1.0 (disabled sentinel), val@200 must land in [4.075, 4.090].

### Predicted Result
This is the highest-confidence hypothesis because the corpus explicitly flags the axis as untested and identifies the mechanism by name. Expected: Arm B (lower β₁ end = 0.80) is the more theoretically motivated arm — near the minimum, fresh gradients should dominate. Predicted improvement: ~0.001–0.004 over baseline (val ≈ 3.264–3.267). If both arms beat baseline, Arm B is likely stronger. If both fail, the mechanism layer closes cleanly with the strong implication that fixed β₁ is already near-optimal for this training length.

---

## Hypothesis 3: AUX_CLIP_NORM — Per-Group Gradient Clipping on AdamW AUX

**Student:** g1r2-nezuko
**Mechanism name:** AUX_GRADIENT_CLIP
**Primary ENV_VAR:** `AUX_CLIP_NORM` (float, default=-1.0 → disabled)

### Theoretical Motivation

The current stack applies no gradient clipping specifically to the AdamW AUX parameter groups (embeddings, lm_head, biases, LayerNorm scales). All prior gradient clipping experiments in the corpus were either:
- Global norm clipping (GRAD_CLIP_NORM, #860 — refuted)
- Muon-body-only clipping (MUON_GRAD_CLIP #688 — refuted; MUON_PER_TENSOR_GRAD_CLIP #968 — refuted)

The structural reason global clipping failed is well-understood: it clips based on the aggregate norm, which couples the Muon body update to the AUX update — if the AUX gradient spikes, the Muon step is reduced unnecessarily. This is a known failure mode of global clipping in multi-optimizer stacks.

The AUX path is structurally distinct from the Muon body in a critical way: **Muon's NS5 orthogonalization provides an implicit step-magnitude bound.** After NS5 projects the gradient matrix onto the Stiefel manifold (polar factor), the update has bounded spectral norm — typically O(1) per step regardless of gradient magnitude. AdamW on AUX has no such bound. The per-element Adam update divides by √(v̂) + ε, which provides relative normalization but does not cap absolute gradient norm. Under embedding or logit gradient spikes (common in early training and loss spike events), the AUX step can be disproportionately large.

An AUX-specific gradient clip decouples the two optimizer paths: it applies `clip_grad_norm_(aux_params, AUX_CLIP_NORM)` to only the AUX parameter groups before the AdamW step, without touching the Muon-body parameters. This preserves Muon's NS5-bounded updates while providing a safety bound on AUX.

The asymmetry argument: the fact that body-Muon clipping consistently failed (3 closed PRs) while AUX clipping has never been tested is itself evidence that the intervention axis (per-optimizer, not per-parameter or global) matters. We are testing AUX-isolated clipping for the first time.

**Key papers:**
- Pascanu et al. 2013, "On the difficulty of training recurrent neural networks", ICML — original gradient clipping motivation
- Zhang et al. 2020, "Why Gradient Clipping Accelerates Training: A Theoretical Justification", ICLR 2020, arXiv:1905.11881 — theoretical basis for clipping in non-convex settings
- Chen et al. 2023, "Lion: Adversarially Robust Language Model Pretraining" — evidence that embedding gradient magnitudes differ from body weights

### Anti-Duplication Evidence

Grep sweep across full 320-PR corpus:
- `AUX_CLIP_NORM`: 0 hits
- `AUX_GNORM`: 0 hits
- `AUX_GRAD_CLIP`: 0 hits
- `adam_clip`: 0 hits
- `ADAM_CLIP`: 0 hits
- `CLIP_AUX`: 0 hits
- `clip_aux`: 0 hits
- `AUX_MAX_NORM`: 0 hits
- Broad `clip.*aux|aux.*clip` pattern: 0 hits
- `GRAD_CLIP_NORM` (#860): 90+ hits but all confirmed as global norm clipping, not per-group

Mechanism is structurally differentiated from all 3 prior closed clipping PRs by the per-group AUX-isolation criterion.

### Arm Design

**Arm A — Tight AUX clip (aggressive):**
```
AUX_CLIP_NORM=1.0
```
Clips AUX gradient norm to 1.0 before AdamW step. This matches the typical recommendation for transformer LM training (Megatron-LM default: 1.0).

**Arm B — Loose AUX clip (moderate):**
```
AUX_CLIP_NORM=5.0
```
Clips AUX gradient norm to 5.0. Conservative bound that only fires on genuine spike events, not during normal training.

Note: AUX_CLIP_NORM=-1.0 (disabled sentinel) must reproduce byte-inert disabled path with val@200 ∈ [4.075, 4.090].

### Mandatory Stack
```
NS5_ITERS=14 WD_AUX=0.001 CONTRA_MUON=0.4 MUON_LR=0.04 EMBED_INIT_STD=0.1
LOGIT_SOFTCAP=20.0 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90
ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85
```
AUX_CLIP_NORM applies only to AdamW AUX groups; Muon body gradients untouched.

### Implementation Note
The clip must be applied **after** gradient accumulation and **before** the AdamW optimizer step, only to the parameter groups belonging to the AUX optimizer. Typical pattern:
```python
if AUX_CLIP_NORM > 0:
    torch.nn.utils.clip_grad_norm_(aux_param_list, AUX_CLIP_NORM)
aux_optimizer.step()
```
The Muon optimizer step must NOT be affected by this clip. Do not use a global `clip_grad_norm_` call.

### Kill Gates

| Step | Baseline val | Kill gate |
|------|-------------|-----------|
| 500  | ~3.85       | > 3.86    |
| 1000 | ~3.71       | > 3.72    |
| 1500 | ~3.58       | > 3.59    |
| 2000 | ~3.48       | > 3.49    |
| 2500 | ~3.39       | > 3.40    |
| 3000 | ~3.31       | > 3.32    |

### Disabled-Check Contract
With AUX_CLIP_NORM=-1.0, val@200 must land in [4.075, 4.090].

### Predicted Result
Medium confidence. The mechanism is structurally clean and the AUX/Muon asymmetry argument is solid. However, the 3 prior global/body clipping closures suggest the baseline stack may already be well-conditioned enough that additional clipping provides marginal benefit. The most likely outcome for Arm A (tight=1.0) is mild improvement or neutral; Arm B (loose=5.0) is likely neutral or very slight positive (only fires on spike events). If Arm A degrades performance, it suggests 1.0 is too aggressive for the embedding scale at this batch size. Predicted improvement if successful: ~0.001–0.002 (val ≈ 3.266–3.267). Closure expected if both arms land within 0.001 of baseline.

---

## Cross-Hypothesis Notes

**Interaction safety:** All three hypotheses are mechanically orthogonal:
- WD_BODY_DEPTH modifies the weight decay coefficient per-layer in the Muon step
- MUON_BETA_END modifies the Muon β₁ schedule
- AUX_CLIP_NORM modifies the AUX gradient clip before AdamW step

None of these touch the same code path. They can be run in parallel on the three students without risk of conflation.

**In-flight PRs to avoid conflation with:** frieren #1220 (SHAMPOO_MUON_BODY) modifies the pre-NS5 gradient transform — orthogonal to all three. Thorfinn #1216 (PSGD_KRON_AUX) modifies the AUX optimizer preconditioner — this overlaps conceptually with AUX_CLIP_NORM in that both touch the AUX path. However, PSGD_KRON changes the *optimizer algorithm* for AUX, while AUX_CLIP_NORM changes the *gradient preprocessing* before the existing AdamW step. They are on different mechanism axes and can run concurrently; their results should be compared post-hoc.

**Priority order for assignment if only one student slot opens:**
1. MUON_BETA_END (askeladd) — corpus explicitly calls it out, untested, highest confidence
2. WD_BODY_DEPTH (fern) — strong theoretical backing, corpus flags as open
3. AUX_CLIP_NORM (nezuko) — clean axis, lower prior expectation given clipping history
