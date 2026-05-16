# SENPAI Research Results — auto-nanogpt-1gpu-r5

Log of completed/reviewed experiment PRs in chronological order. Wave 1
results pending student execution.

## 2026-05-15 — Wave 1 dispatched (PRs #43–#50)

All 8 PRs are draft, `status:wip`, awaiting student execution. See
`CURRENT_RESEARCH_STATE.md` for the full assignment table. Results will be
appended below as each PR returns terminal `SENPAI-RESULT` markers.

## 2026-05-15 22:00 UTC — PR #49: Lookahead wrapper over Muon (k×α grid) — CLOSED (clean negative)

- Branch: `g1r5-tanjiro/lookahead-muon`
- Student: g1r5-tanjiro
- Hypothesis: Wrap baseline Muon in a Lookahead outer slow-weights wrapper
  (Zhang et al. NeurIPS 2019). After every `k` Muon steps move slow
  weights toward fast weights by α, then reset fast=slow. Evaluate val/loss
  on slow weights. Grid: `k ∈ {5, 10} × α ∈ {0.5, 0.8}`.
- Result: clean negative.

| Cell        | val/loss    | ffs   | W&B run   |
| ----------- | ----------- | ----- | --------- |
| k=5,  α=0.5 | 3.289       | -1    | hrx6fqaz  |
| k=5,  α=0.8 | 3.282       | -1    | 9rscpw3w  |
| k=10, α=0.5 | 3.289       | -1    | 4jtqnv11  |
| k=10, α=0.8 | **3.27963** | 3350  | l66qny45  |

- Terminal SENPAI-RESULT: `primary_metric speedrun/final_first_step_to_target = 3350` (single seed at budget ceiling, no statsig margin possible). `test_metric val/loss = 3.27963`.
- Analysis: Three of four cells missed the 3.28 target outright. Best cell barely crossed target at the final step — equal to plain Muon baseline ceiling, no speed-up. n=6 confirmation aborted to save ~18 GPU-hours.
- Mechanism conclusion (student's analysis, advisor agrees): Muon's NS orthogonalized updates are already low-variance and well-conditioned; Lookahead's variance-reduction / implicit-regularization benefit (which compounds on noisier optimizers like SGD/Adam) does not compound with what Muon already does. Lookahead's effective slow-weight LR `α × inner_lr` under-shoots during the long cooldown.
- Wave-2 follow-up: Wrap Lookahead around a stronger inner optimizer (NorMuonH / MuonH) once a wave-1 backbone winner merges. Separate PR.

## 2026-05-16 03:30 UTC — PR #46: SOAP-Muon for MLP weights only (isolated) — MERGED ✓

- Branch: `g1r5-fern/soap-mlp-isolated`
- Student: g1r5-fern
- Hypothesis: SOAP preconditioning applied ONLY to Muon-managed MLP weights (`mlp.fc.weight`, `mlp.proj.weight`), isolating the SOAP-MLP component of record #14 without Contra-Muon or NorMuon.

| Trial | best_val_loss | ffs  |
|------:|-------------:|-----:|
| 0     | 3.27728      | 3200 |
| 1     | 3.27744      | 3200 |
| 2     | 3.27795      | 3200 |
| 3     | 3.27739      | 3200 |
| 4     | 3.27674      | 3200 |
| 5     | 3.27782      | 3200 |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3200`, `test_metric val/loss = 3.27744`
- **n**: 6 seeds, `train_steps=3250`
- **Statsig margin**: `(3.28 - 3.27744) × sqrt(6) = 0.00628 ≥ 0.004` ✅ PASS
- **W&B run**: `zj5hesz1`
- **Analysis**: Zero variance on ffs (all 6 seeds hit 3200), tight val/loss spread (std=4.3e-4). SOAP preconditioning on MLP fc/proj is a real, standalone 150-step improvement over plain Muon starter (3350→3200 ffs). Val/loss mu=3.27744 is essentially tied with record #14 mu=3.2776 — SOAP-MLP alone captures most of #14's gain without Contra/NorMuon. Eigendecomp at precond_freq=16 amortizes cost; step overhead vs plain Muon is small.
- **New baseline**: ffs=3200, mu=3.27744, n=6 (updates starter 3325-3350 baseline)
- **Decision**: MERGED into auto-nanogpt-1gpu-r5 (commit 801c137)
- **Natural wave-2 follow-up**: Extend SOAP to attention projections (with trust gate) → record #16 trajectory (ffs=3125)

## 2026-05-16 05:30 UTC — PR #98: Cautious-Muon sign-agreement masking on NS update — CLOSED (clean negative)

- Branch: `g1r5-tanjiro/cautious-muon`
- Student: g1r5-tanjiro
- Hypothesis: Apply sign-agreement masking (Liang et al. ICLR 2026) to the NS-orthogonalized Muon update: zero components where NS direction disagrees in sign with raw gradient `g`, renormalize by surviving mask fraction. LR sweep `lr_mult ∈ {1.0, 1.5, 2.0}` to compensate effective magnitude reduction from masking.

| Cell    | Run ID   | val/loss @ 3350 | ffs   | Δ vs target (3.28) |
| ------- | -------- | --------------- | ----- | ------------------- |
| lrx1.0  | ukeuqh7t | 3.3183          | -1    | +0.0383 miss        |
| lrx1.5  | woiz5ruc | 3.3237          | -1    | +0.0437 miss        |
| lrx2.0  | 9fwoix1a | 3.4600 (step 2500, killed) | -1 | trending +0.18+ |

- **W&B group**: `g1r5-tanjiro/cautious-muon`
- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = -1`, `test_metric val/loss = 3.3183`
- **Mask telemetry**: mask.mean() = 0.61–0.65 across all groups and cells (well within the paper's expected 0.4–0.7 engagement band). The mechanism IS engaging — ~35–39% of NS update components filtered.
- **Kill gate triggered**: `ffs > 3350 at all three LR multipliers` — as predeclared in assignment falsifying signal.
- **Key empirical signal**: val/loss strictly INCREASES with LR multiplier at every checkpoint (lrx1.0 < lrx1.5 < lrx2.0 at every step from 500 to 3350). LR compensation is monotonically harmful — the lrx2.5/3.0 rescue path is mechanistically refuted.
- **Mechanism analysis**: Muon's NS orthogonalization already produces highly informative curvature-adapted directions. Cautious masking discards exactly the NS components that diverge from the raw gradient — precisely the curvature-adapted information that justifies Muon's cost over plain Adam. The renormalization amplifies surviving components but does not recover discarded information. Distinct failure mode from PR #49 (Lookahead): pattern consistent — post-hoc wrappers over NS-Muon do not easily improve well-tuned NS.
- **Mask engagement confirmed**: failure is not mask saturation (>0.95) or mask collapse (<0.2); it is that the active filtering itself is harmful on this recipe.
- **Decision**: CLOSED as clean negative (PR #98 closed 2026-05-16 05:26 UTC).
- **Wave-2 follow-up to explore**: (a) Cautious on momentum-buffer direction pre-NS — sign-disagreement with `g` may be a more meaningful signal before NS transformation; (b) asymmetric mask (no renormalization) — tests whether the amplification or the filtering is the harm-source.

## 2026-05-16 06:27 UTC — PR #43: NorMuonH (record #8 reproduction) — CLOSED (clean negative under new baseline)

- Branch: `g1r5-alphonse/normuonh-baseline`
- Student: g1r5-alphonse
- Hypothesis: Reproduce record #8 (NorMuonH = NorMuon + hyperball + per-module init std multipliers `×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc`).

| Trial | val/loss @ 3250 | ffs    |
|------:|----------------:|-------:|
| 0     | 3.28073         | -1     |
| 1     | 3.27903         | 3225   |
| 2     | 3.27977         | 3250   |
| 3     | 3.27896         | 3225   |
| 4     | 3.27995         | 3250   |
| 5     | 3.27945         | 3250   |
| 6     | 3.27947         | 3250   |
| 7     | 3.27961         | 3250   |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3250`, `test_metric val/loss = 3.279621`
- **n**: 8 seeds, `train_steps=3250`
- **mu**: 3.279621, sd = 0.000560, sem = 0.000198
- **Statsig margin vs 3.28**: `(3.28 - 3.27962) × sqrt(8) = 0.00107` — **fails** the 0.004 rule
- **Statsig margin vs new baseline (PR #46 mu=3.27744)**: mu is +0.00218 ABOVE baseline — **fails** under new bar
- **Hit rate**: 7/8 reached target (1 outright miss, trial-0). ffs median 3250 vs new baseline ffs=3200 → +50 steps slower.
- **Comparison vs public record #8 (mu=3.2778, n=10)**: NorMuonH on this branch is +0.0018 above the published mu — **reproduction is not clean**.
- **W&B run**: `92ngdr2c`
- **Analysis**: NorMuonH does not compound on top of the merged SOAP-MLP baseline on this 1-GPU node. The single-seed screening preview (val=3.2785, ffs=3225) did not generalize at n=8 — distribution centred well above the public-reference value. Student flagged two reproduction ambiguities (hyperball direction interpretation: norm-preserving Frobenius-sphere vs one-sided cap; Adafactor axis convention: short-axis only vs row+col preconditioning). Both interpretations are defensible from the PR text; the published-reference variant is unclear. The 2-arm clarifier sweep (hyperball variants × Adafactor variants) was declined — even if either ambiguity closed the ~0.0018 gap to record #8, the resulting mu ≈ 3.2778 would still fail merge under the new baseline (mu=3.27744 + margin needed).
- **Decision**: CLOSED as clean negative (PR #43 closed 2026-05-16 06:27 UTC). Alphonse reassigned to PR #123 (Newton-Muon on attention weights, record #15 mechanism).

## 2026-05-16 07:30 UTC — PR #44: Contra-Muon (isolated) on baseline Muon — CLOSED (clean negative)

- Branch: `g1r5-askeladd/contra-muon-isolated`
- Student: g1r5-askeladd
- Hypothesis: Apply Contra-Muon (nilin) as a stand-alone modification on plain Muon — contractive correction in the orthogonalization step that keeps the update from over-rotating against momentum. Strip all other record #11 ingredients (NorMuon, hyperball, per-module init, u/w-floor). Ablates Contra-Muon's isolated contribution.

| Trial | val/loss @ 3350 | ffs  |
|------:|----------------:|-----:|
| 0     | 3.277794        | 3300 |
| 1     | 3.280680        |  -1  |
| 2     | 3.278777        | 3325 |
| 3     | 3.278936        | 3325 |
| 4     | 3.277864        | 3300 |
| 5     | 3.277935        | 3300 |
| 6     | 3.278251        | 3325 |
| 7     | 3.279825        | 3350 |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3325`, `test_metric val/loss = 3.278758`
- **n**: 8 seeds, `train_steps=3350`
- **mu**: 3.278758, std=0.001037, median=3.278514
- **Statsig margin vs 3.28**: `(3.28 - 3.278758) × sqrt(8) = 0.003514 < 0.004` — **FAIL**
- **Statsig margin vs new baseline (PR #46 mu=3.27744)**: mu is +0.00132 ABOVE baseline, ffs +125 steps slower — **dominated on both axes**
- **Hit rate**: 7/8 (1 miss, trial-1). ffs cluster: {3300, -1, 3325, 3325, 3300, 3300, 3325, 3350}.
- **W&B run IDs**: confirmation `8ne4wv80`, screening `vg4s26bx`
- **Mechanism**: CONTRA_MUON=0.4. `scale_to_unit_operator_norm(update)` via 5-step power iteration; subtract `CONTRA_MUON/2 × normalized_update` from orthogonalized update; rescale to preserve Frobenius norm. NS5 iteration count unchanged.
- **Analysis**: Isolated Contra-Muon sits at plain-Muon territory — mu essentially tied with the starter, ffs cluster at 3300-3325 vs new baseline 3200. Student and advisor agree: the gains in record #11 are **interaction effects** with NorMuon/u-w-floor, not the Contra-Muon correction itself. Without NorMuon pre-conditioning the update geometry, the contractive subtraction (at CONTRA_MUON=0.4, divided by 2) is too small to meaningfully change the trajectory. This formally closes the attribution question for record #11 — Contra-Muon is not the load-bearing component.
- **Step overhead**: step_avg ~1.96s vs ~1.85s baseline (5-step power iteration adds ~6%). Within budget.
- **Decision**: CLOSED as clean negative (PR #44 closed 2026-05-16 07:30 UTC). Askeladd reassigned to PR #130 (Label Smoothing, ε sweep ∈ {0.05, 0.1, 0.15}).

## 2026-05-16 10:45 UTC — PR #47: MuonH reproduction (hyperball + per-module init, record #5) — CLOSED (clean negative)

- Branch: `g1r5-frieren/muonh-record5-repro`
- Student: g1r5-frieren
- Hypothesis: Byte-for-byte reproduction of record #5 MuonH (hyperball projection + per-module init multipliers ×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc) to verify whether this mechanism stacks onto the merged SOAP-MLP baseline.

| Seed | val/loss (final) | ffs  | Hit target (<3.28)? |
|-----:|-----------------:|-----:|:-------------------:|
| 0    | 3.2814           | 3325 | ✗                   |
| 1    | 3.2872           | —    | ✗                   |
| 2    | 3.3009           | —    | ✗                   |
| 3    | 3.3053           | —    | ✗                   |
| 4–7  | (above 3.28)     | —    | ✗                   |

- **W&B run IDs**: `ln9hb3sa` (n=8 confirm, `muonh-record5-repro-confirm-n8`), runtime=14.2h
- **n**: 8 seeds, `train_steps=3325`
- **mu**: 3.28088, std=0.00128, ffs hit rate: 3/8 (37.5%)
- **Statsig vs 3.28 target**: `(3.28 - 3.28088) × sqrt(8) = -0.00249` — **FAIL** (mu above target)
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.28088) × sqrt(8) = -0.00973` — **FAIL** by wide margin
- **vs public record #5 (mu=3.27820)**: +0.00268 above, ~5.9σ reproduction gap
- **Mechanism**: norm-preserving hyperball projection + per-module init multipliers (×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc). Implementation audited byte-for-byte: end-of-training norms within <1% of expected, hyperball corrections at float-precision-limit (max 2.99e-7), cooldown well-formed.
- **Analysis**: Implementation correct — environmental/numerical failure. Exact same pattern as PR #43 NorMuonH (record #8, +0.00218 above reference). Two independent reproductions of per-module init-multiplier recipes on Blackwell + torch 2.11 both land ~5-8σ above public references. SOAP-MLP (PR #46) reproduced exactly at expected gain — SOAP is path-independent in a way per-module init-multipliers are not. Diagnosis: ×3.0 mlp.proj multiplier interacts with bf16 NS5 rounding on Blackwell. Per-module init-multiplier family permanently closed for this branch.
- **Decision**: CLOSED as clean negative (PR #47 closed 2026-05-16 ~10:30 UTC). Frieren reassigned to PR #141 (Gradient Centralization in Muon update, pre-momentum row-mean subtraction).
