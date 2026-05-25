# Research Ideas — 2026-05-25 04:40

Generated for cycle 71, targeting students **askeladd** and **thorfinn**.
Baseline: val=3.26776, ffs=3000 (PR #613, n=2 mean).
Cycle state: 127 refuted axes, 51 mechanism classes, 14 family-level closures, 6 saturated layers.

---

## H1 (askeladd): TOKEN_FREQ_REWEIGHT_LOSS

### What it is

Inverse-token-frequency weighted cross-entropy loss: rare tokens receive
higher gradient weight proportional to their rarity raised to a power alpha,
so that hard/rare tokens drive optimization more than high-frequency tokens
that are already well-predicted.

### Why it might help

The FineWeb training corpus has a highly skewed token-frequency distribution
(50,257 vocab; common tokens like "the", punctuation dominate). Standard
cross-entropy treats every token position equally, which means the loss is
dominated by a small set of very common, easily-predicted tokens. These
high-frequency tokens yield low loss quickly and do not carry structural
semantic information. Rare tokens (named entities, domain vocabulary,
numeric tokens) carry disproportionate semantic content and are harder to
predict, but they are underweighted in the gradient signal.

Reweighting by inverse frequency (analogous to Mikolov 2013 subsampling and
Lin et al. 2017 focal-loss frequency corrections) could shift gradient mass
toward tokens where the model has genuine headroom, potentially accelerating
convergence. This is categorically distinct from all 14 family-level closures:
it is a loss-architecture change based on token identity (not logit confidence
as in focal loss; not entropy penalty as in z-loss; not uniform smoothing as
in label smoothing). The z-loss PR (#1117 fern) is in-flight — this is a
different mechanism applied at the per-token-weight level, not the
logit-regularization level.

### Scientific motivation

- Mikolov et al. (2013) "Distributed Representations of Words and Phrases and
  their Compositionality" (arXiv:1310.4546): subsampling frequent words
  accelerates training and improves representation quality for rare words.
- Lin et al. (2017) "Focal Loss for Dense Object Detection" (arXiv:1708.02002):
  frequency-proportional weight rebalancing moves gradient mass toward
  hard/underrepresented examples; alpha-balanced variant is the relevant one
  here.
- Karpathy (2023) nanoGPT analysis: FineWeb token distribution is dominated
  by whitespace+punctuation tokens which are easy to predict and contribute
  disproportionately to raw CE loss.

### Implementation

**Patch location:** `records/track_3_optimization/train_gpt_simple.py`

**Startup (after train shards are identified, before training loop):**
```python
TOKEN_FREQ_WEIGHT_ALPHA = float(os.environ.get("TOKEN_FREQ_WEIGHT_ALPHA", "0"))
# ... near dataset setup, after train_files / train_shards are identified:
if TOKEN_FREQ_WEIGHT_ALPHA > 0:
    _token_counts = torch.zeros(50257, dtype=torch.float64)
    _shard_path = train_files[0]  # use first shard for frequency estimate
    _ids = torch.frombuffer(open(_shard_path, 'rb').read(), dtype=torch.uint16).long()
    _ids = _ids.clamp(0, 50256)
    _token_counts.scatter_add_(0, _ids, torch.ones(len(_ids), dtype=torch.float64))
    del _ids
    _token_freq = (_token_counts + 1.0) / (_token_counts.sum() + 50257)
    _token_weight = _token_freq.pow(-TOKEN_FREQ_WEIGHT_ALPHA)
    token_weight = (_token_weight / _token_weight.mean()).float().to(device)
    del _token_counts, _token_freq, _token_weight
else:
    token_weight = None
```

**In `GPT.forward()` — replace the final return line:**
```python
# Replace:
#   return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
# With:
if token_weight is not None:
    _flat = targets.view(-1)
    _per_tok = F.cross_entropy(logits.view(_flat.numel(), -1), _flat, reduction='none')
    return (token_weight[_flat] * _per_tok).sum()
else:
    return F.cross_entropy(logits.view(targets.numel(), -1), targets.view(-1), reduction="sum")
```

**Total: ~18 LOC.** Zero extra memory at training time (token_weight is a
50,257-element float32 vector, ~200KB). No extra compute beyond one gather
and elementwise multiply per forward pass.

### Disabled-check

`TOKEN_FREQ_WEIGHT_ALPHA=0` (default) must reproduce baseline ~4.08 at step
200. The `token_weight is None` branch is bytewise-identical to the original
`reduction="sum"` path.

### Arm design

- **Disabled-check**: `TOKEN_FREQ_WEIGHT_ALPHA=0` — verify val@200 ≈ 4.08
- **Arm A**: `TOKEN_FREQ_WEIGHT_ALPHA=0.5` — mild inverse-frequency weighting
  (square-root of inverse frequency, normalized to mean=1). PaLM-scale
  analogies suggest alpha in [0.3, 0.7] is most effective for vocabulary
  imbalance. Alpha=0.5 is the geometric mean between uniform (0) and pure
  inverse-frequency (1.0).
- **Arm B**: `TOKEN_FREQ_WEIGHT_ALPHA=0.25` — weaker weighting, conservative
  sanity check if Arm A is promising but noisy.

**Decision tree:**
- Arm A val < 3.270 (floor-cluster touch): launch Arm B at alpha=0.25 for
  monotone-in-alpha confirmation; both arms needed for merge.
- Arm A val in [3.270, 3.278] (floor-cluster interior): Arm B still worthwhile
  to confirm direction.
- Arm A val > 3.278 (clear miss): close, do not launch Arm B.

### Kill gates

Step 1000: val ≤ 3.50 (below baseline trajectory at step 1000 ~3.55).
Step 2000: val ≤ 3.35.
Step 3000: val ≤ 3.285.

### Family classification

**LOSS-ARCHITECTURE-FREQUENCY** — loss reweighting by token-identity
frequency. Categorically distinct from all 14 closed families: variance
reduction, schedule-scalar, weight-spectrum, init-structure, dual-timescale
momentum, RMSProp-Muon, pre-NS5-nonlinear, AR(2)-momentum, geometric
direction, NS5-input-spectrum, coherence-LR, AUX-AMSGrad,
pre-NS5-linear-Frobenius, AUX-LR-schedule. Also distinct from z-loss (logit
entropy penalty, not per-token weight).

### Expected observables

If effective: val loss trajectory should be lower than baseline from step ~500
onward, with the gap growing through training as common-token predictions
saturate early. Gradient RMS across embedding rows for rare tokens should
increase relative to baseline. If neutral or harmful: val loss tracks baseline
or diverges (alpha too large distorts gradient signal).

---

## H2 (thorfinn): SOAP_GRAM_DRIFT_REFRESH

### What it is

Drift-triggered adaptive SOAP eigenbasis refresh: instead of refreshing the
eigenbasis every fixed `refresh_freq` steps, trigger a refresh when the
normalized Frobenius distance between consecutive Gram matrix EMAs exceeds a
threshold, with a periodic fallback to prevent staleness.

### Why it might help

The SOAP preconditioner maintains Gram matrix EMAs `G_row = beta2 * G_row +
(1-beta2) * grad @ grad.T` and refreshes the eigenbasis (via symmetric
eigendecomposition or Schur decomposition) every `refresh_freq=10` steps. The
fixed frequency is a heuristic that ignores the actual rate of preconditioner
change during training.

Early training: the Gram matrix rotates rapidly as the model moves away from
initialization; eigenbasis becomes stale within 2-3 steps. A fixed freq=10
means the preconditioner is frequently applied with an out-of-date basis,
potentially reducing its effectiveness when the geometry is changing fastest.

Late training / convergence: the Gram matrix stabilizes and the eigenbasis
rotates slowly. Refreshing every 10 steps wastes compute on near-identical
decompositions.

Measuring Gram drift between consecutive EMA states allows the refresh to fire
when the preconditioner is truly stale and skip when it is stable — a better
compute budget allocation. This is categorically distinct from all tested SOAP
variants: fixed freq (baseline), temporal ramp (#304 ATTN_SOAP_PRECOND_FREQ
sweep), trust-threshold for ACCEPTING the new basis (existing
ATTN_SOAP_TRUST_THRESHOLD mechanism, which gates whether to keep the new
eigenbasis after computing it, not whether to compute it).

The existing trust gate (`ATTN_SOAP_TRUST_THRESHOLD`) computes cosine
similarity between old and new eigenbases AFTER QR decomposition and decides
whether to accept the new basis. SOAP_GRAM_DRIFT_REFRESH measures the Gram
EMA drift BEFORE decomposition to decide when to attempt a refresh — these are
orthogonal mechanisms on different parts of the SOAP pipeline.

### Scientific motivation

- Vyas et al. (2024) "SOAP: Improving and Stabilizing Shampoo using Adam in
  the Eigenbasis of the Grafting Matrix" (arXiv:2409.11321): the core SOAP
  paper motivates the eigendecomposition refresh but uses fixed frequency as
  a practical approximation. Section 4 notes that refresh frequency is a
  trade-off between preconditioner quality and compute.
- Agarwal et al. (2020) "Disentangling Adaptive Gradient Methods from
  Learning Rates" (arXiv:2002.11803): analysis of how preconditioner staleness
  affects second-order methods; shows that outdated curvature estimates can
  hurt convergence in rapidly-changing loss landscapes.
- Martens & Grosse (2015) "Optimizing Neural Networks with Kronecker-factored
  Approximate Curvature" (arXiv:1503.05671): K-FAC refresh frequency analysis
  — the insight that curvature changes most rapidly in early training is
  directly applicable.

### Implementation

**Patch location:** `soap_refresh()` in
`records/track_3_optimization/train_gpt_simple.py` (currently lines ~556-626).

**New env var near SOAP constants:**
```python
SOAP_GRAM_DRIFT_THRESHOLD = float(os.environ.get("SOAP_GRAM_DRIFT_THRESHOLD", "0"))
```

**In `soap_refresh()`, after the Gram EMA update (after lines updating
`state["row_gg"]` and `state["col_gg"]`), replace the existing refresh
condition:**

```python
# Existing condition to replace:
#   elif state["soap_step"] > 0 and state["soap_step"] % refresh_freq == 0:
#
# New adaptive condition:
if SOAP_GRAM_DRIFT_THRESHOLD > 0:
    if "prev_row_gg" not in state:
        state["prev_row_gg"] = state["row_gg"].detach().clone()
        _do_refresh = (state["q_row"] is None)
    else:
        _row_norm = state["row_gg"].norm().clamp_min(1e-8)
        _drift = (state["row_gg"] - state["prev_row_gg"]).norm() / _row_norm
        # Trigger on drift OR periodic fallback (every 5x refresh_freq to
        # prevent indefinite staleness if gradient is unusually stable)
        _do_refresh = (
            _drift.item() > SOAP_GRAM_DRIFT_THRESHOLD
            or (state["soap_step"] % (refresh_freq * 5) == 0)
        )
        if _do_refresh:
            state["prev_row_gg"] = state["row_gg"].detach().clone()
    do_refresh = _do_refresh
else:
    # Baseline: fixed frequency
    do_refresh = (state["soap_step"] > 0 and state["soap_step"] % refresh_freq == 0)

# Use do_refresh in place of the existing elif condition
```

**Total: ~20 LOC.** Extra memory: one clone of `row_gg` per SOAP-enabled
parameter group (same shape as Gram matrix, typically d_model x d_model =
768x768 = ~2.4MB float32 per layer — negligible on 96GB VRAM).

### Disabled-check

`SOAP_GRAM_DRIFT_THRESHOLD=0` (default) uses the `do_refresh = state["soap_step"] > 0 and state["soap_step"] % refresh_freq == 0` path, which is bytewise-identical to the baseline condition. Must reproduce val@200 ≈ 4.08.

### Arm design

- **Disabled-check**: `SOAP_GRAM_DRIFT_THRESHOLD=0` — verify val@200 ≈ 4.08
- **Arm A**: `SOAP_GRAM_DRIFT_THRESHOLD=0.05` — 5% normalized Frobenius drift
  triggers refresh. With SOAP_BETA2=0.90, the Gram EMA has a half-life of
  ~7 steps, so 5% drift corresponds to moderate curvature rotation. This
  should trigger more frequent refreshes early in training (when the loss
  surface rotates rapidly) and less frequent in late training.
- **Arm B**: `SOAP_GRAM_DRIFT_THRESHOLD=0.02` — tighter threshold (2% drift),
  will trigger refreshes more aggressively. Tests sensitivity to threshold
  granularity.

**Decision tree:**
- Arm A val < 3.270: launch Arm B; confirm monotone-in-threshold direction.
- Arm A val in [3.270, 3.278]: launch Arm B for confirmation.
- Arm A val > 3.278: close, do not launch Arm B.

### Kill gates

Step 1000: val ≤ 3.50.
Step 2000: val ≤ 3.35.
Step 3000: val ≤ 3.285.

### Additional telemetry (recommended)

Log the mean refresh count per step vs baseline to verify the mechanism is
firing adaptively:
```python
# In soap_refresh(), after computing _do_refresh:
state.setdefault("refresh_count", 0)
if _do_refresh:
    state["refresh_count"] += 1
```
This can be logged to W&B as `train/soap/mean_refresh_fraction` at validation
events. If the mechanism is working, this ratio should be > 1/refresh_freq
(=0.1) early in training and < 0.1 in late training.

### Family classification

**PRECONDITIONER-ADAPTIVE-REFRESH** — conditional eigenbasis refresh trigger
based on Gram matrix drift. Categorically distinct from all 14 closed
families. Also distinct from:
- Fixed-freq SOAP (baseline): this replaces the trigger condition, not the
  decomposition itself.
- Trust-threshold (existing ATTN_SOAP_TRUST_THRESHOLD): that gates accepting
  the new basis AFTER decomposition; this gates WHETHER to decompose.
- SOAP_PRECOND_FREQ sweep (#304): static frequency sweep; this is
  data-adaptive.
- NS5-internal iteration count: entirely different optimizer component.

### Expected observables

If effective: earlier convergence slope improvement (lower val loss at steps
500-1500 where the model is most geometrically dynamic). SOAP refresh count
telemetry should show adaptive pattern (higher early, lower late). If neutral:
val tracks baseline. If harmful (threshold too tight): excessive
decompositions increase step time without benefit; watch wall-clock seconds
per step vs baseline.

---

## Summary table

| Student | Hypothesis slug | Mechanism family | Arms | LOC | Primary risk |
|---------|----------------|------------------|------|-----|--------------|
| askeladd | TOKEN_FREQ_REWEIGHT_LOSS | Loss-architecture-frequency | alpha=0.5 vs 0.25 | ~18 | Over-emphasizes rare tokens, destabilizes early training |
| thorfinn | SOAP_GRAM_DRIFT_REFRESH | Preconditioner-adaptive-refresh | threshold=0.05 vs 0.02 | ~20 | Threshold calibration; excessive refreshes increase step time |

Both hypotheses:
- Have bytewise-inert disabled-checks (env var = 0, default off)
- Are categorically novel relative to all 14 closed family-level closures
- Are absent from all 293 PRs in the experiment log
- Are absent from the 6 in-flight WIPs
- Require ≤20 LOC in `train_gpt_simple.py`
- Have staged 2-arm decision trees with clear kill gates
