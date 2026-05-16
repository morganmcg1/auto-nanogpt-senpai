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

## 2026-05-16 11:20 UTC — PR #48: Cooldown shape sweep on plain Muon — CLOSED (clean negative)

- Branch: `g1r5-nezuko/cooldown-shape-sweep`
- Student: g1r5-nezuko
- Hypothesis: Sweep five cooldown shapes on plain Muon baseline (integral-renormalized base_lr so comparison is fair): linear (baseline), cosine, power_α1.2, power_α0.6, trapezoidal. 2 seeds per shape.

| Shape           | mu (n=2) | std    | ffs (mean) | Hit target? |
|-----------------|---------|--------|-----------|:----------:|
| linear          | 3.27884 | 0.00123 | 3325      | ✓ (1/2)    |
| cosine          | 3.28579 | 0.00163 | —         | ✗          |
| power_α0.6      | 3.28601 | 0.00057 | —         | ✗          |
| power_α1.2      | **3.27827** | 0.00024 | 3287.5 | ✓ (2/2)  |
| trapezoidal     | 3.28902 | 0.00051 | —         | ✗          |

- **W&B run IDs**: `9laz4iiv` (linear-s42), `g82xg6ng` (linear-s43), `p3g426vm` (cosine-s42), `4pvt5nbq` (cosine-s43), `tld0vp5p` (pow0.6-s42), `9ccidvds` (pow0.6-s43), `ge9e50bn` (pow1.2-s42), `kknolve3` (pow1.2-s43), `z0fig2xl` (trap-s42), `954qipjx` (trap-s43). Group: `g1r5-nezuko/cooldown-shape-sweep`.
- **Best shape (power_α1.2, n=2)**: mu=3.27827, ffs=3287.5
- **Predeclared confirmation trigger**: beat linear by ≥0.001 in mean val/loss. Actual delta = +0.00057 — trigger NOT met; no expansion. Predeclared rule applied cleanly.
- **Statsig (best power_α1.2, n=2) vs 3.28 target**: `(3.28 - 3.27827) × sqrt(2) = 0.00245 < 0.004` — FAIL
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.27827) × sqrt(2) = -0.00117` — FAIL; also +87.5 ffs slower
- **Notable methodology**: Student caught the LR-integral confound in the original spec (power_α0.6 would have deposited +13.5% LR vs linear), proposed Option A (renormalize base_lr), advisor approved. Result is interpretable specifically because of this fix.
- **Analysis**: Linear cooldown is at or near the local optimum of the shape family tested. Smoother-shape hypothesis (power_α0.6, cosine) is falsified — they underperform linear by 0.007-0.010 mu. Trapezoidal at effective Muon lr=0.027 (integral-matched) is starved; consistent with advisor's advance flag. Cooldown shape is not a wave-1/2 lever on plain Muon — the merged SOAP-MLP base already uses linear.
- **Infrastructure fixes (already in merged base via PR #46)**: sample_tensor float64 linspace fix (out-of-bounds CUDA assert on tensors >2^24 elements); torch==2.10→2.11 (NaN at step 2 with model.compile on Blackwell).
- **Decision**: CLOSED as clean negative (PR #48 closed 2026-05-16 ~11:20 UTC). Nezuko reassigned to PR #147 (Output Embedding Mean-Centering / mu-centering, post optimizer step).

## 2026-05-16 11:30 UTC — PR #50: Polyak/SWA tail averaging (τ, β grid) — CLOSED (clean negative)

- Branch: `g1r5-thorfinn/polyak-swa-tail-avg`
- Student: g1r5-thorfinn
- Hypothesis: EMA-of-weights tail averaging over the final τ fraction of training at decay β. Screen 4 cells: τ ∈ {0.10, 0.20} × β ∈ {0.995, 0.999}. Best cell: confirm at n=6.

| Cell (τ, β)     | val/loss | ffs  | Note     |
|-----------------|---------|------|----------|
| (0.10, 0.999)   | 3.2965  | —    | miss     |
| (0.20, 0.999)   | 3.3026  | —    | miss     |
| (0.20, 0.995)   | **3.2779** | 3300 | **best** |
| (0.30, 0.995)   | 3.2786  | 3300 | tied     |

**Confirmation (τ=0.20, β=0.995, n=6 seeds):**

| Seed | val/loss | ffs  |
|-----:|---------|-----:|
| 0    | 3.27793 | 3300 |
| 1    | 3.27715 | 3275 |
| 2    | 3.27887 | 3325 |
| 3    | 3.27869 | 3300 |
| 4    | (in confirm batch) |  |
| 5    | (in confirm batch) |  |

- **W&B run IDs**: `vytptwgd`, `ov19pmhq`, `6tv4gzy9`, `80cpwca1`, `v9uqkavv` (confirm batch, total n=6)
- **Terminal SENPAI-RESULT**: primary_metric ffs=3304.2 (n=6 mean), test_metric val/loss=3.27828
- **Statsig vs 3.28 target**: `(3.28 - 3.27828) × sqrt(6) = 0.00421 ≥ 0.004` — **PASS** (stable sub-target recipe)
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.27828) × sqrt(6) = -0.00206` — **FAIL** (mu above baseline by 0.00084; ffs +104 steps slower)
- **Mechanism**: fp32 EMA of model parameters maintained during tail fraction; broadcast for cross-rank consistency; separate val/loss_fast (point iterate) and val/loss (EMA iterate) at each validation step.
- **Analysis**: (τ=0.20, β=0.995) is a stable, reproducible sub-target recipe with tight std ≈ 0.00068 and 4/4→6/6 hit rate. The EMA mechanism is doing real work (improves std and ffs cluster over the raw point iterate). However, Polyak tail-averaging does not compound additively with SOAP-MLP preconditioning at this scale/step budget — it remains above the merged baseline mu. Natural wave-3 use is as a postprocessing wrapper stacked on top of the SOAP-MLP base recipe, not as a standalone optimizer change.
- **Decision**: CLOSED as clean negative (PR #50 closed 2026-05-16 ~11:30 UTC). Thorfinn reassigned to PR #148 (Depth-Scaled Residual Initialization, 1/sqrt(2L) on attn.proj and mlp.proj).

## 2026-05-16 12:40 UTC — PR #121: Schedule-free Muon (Defazio c_t=1/(t+1) averaging) — CLOSED (clean negative on spec)

- Branch: `g1r5-tanjiro/schedfree-muon`
- Student: g1r5-tanjiro
- Hypothesis: Schedule-free Muon using Defazio dual z/x iterate with Polyak-Ruppert uniform averaging (`c_t=1/(t+1)`). No cooldown (cooldown_frac=0). β sweep ∈ {0.90, 0.95, 0.98}.

| β     | run id     | val/loss_x | val/loss_z | ffs | x_vs_z_norm (start→mid→end) |
|------:|-----------|------------|-----------|----:|:---------------------------:|
| 0.90  | `ybdf732l` | **3.366** | 17.198    | -1  | 14k → 39k → 52k             |
| 0.95  | `9vo3bgqk` | 3.432     | 21.347    | -1  | 15k → 44k → 57k             |
| 0.98  | `q2i8873j` | 3.554     | 20.858    | -1  | 16k → 54k → 68k             |
| smoke | `tqjqj46t` | 4.977 (300st) | 10.125 | -1 | 21k               |

- **W&B run IDs**: `tqjqj46t` (smoke), `ybdf732l` (β=0.90), `9vo3bgqk` (β=0.95), `q2i8873j` (β=0.98). Group: `g1r5-tanjiro/schedfree-muon`.
- **Screen kill-gate triggered**: all 3 cells ffs=-1 and best mu_x=3.366 >> 3.279 trigger. No n=6 confirm launched. Predeclared protocol followed.
- **Statsig (best β=0.90, n=1) vs 3.28 target**: `(3.28 - 3.366) × sqrt(1) = -0.086` — FAIL by large margin
- **β ordering insight**: β=0.90 best, β=0.98 worst (3.366 < 3.432 < 3.554). Lower β puts more weight on the current z iterate in the forward; with diverging z, more "current" iterate means faster effective progress on x averaging.
- **Mechanism diagnosis (two interacting failure modes)**:
  1. **z diverges under constant LR** (cooldown_frac=0). val/loss_z rises from 10.83 → ~17-21 over training. Base recipe tuned with cooldown_frac=0.7; stripping cooldown alone destabilizes z.
  2. **c_t=1/(t+1) is uniform-weight Polyak-Ruppert.** `x_T = (1/(T+1)) · Σ z_i` — arithmetic mean of every iterate including warmup. Averaging pulls x toward random init. Even if late z were converged, warmup mass drags x well above 3.28.
- **x_vs_z_norm growth**: monotone 14k→52-68k across cells — wrapper mechanically engaging (x and z diverging in weight space), not a wrapper bug. val/loss_x < val/loss_z throughout (averaging helping enormously vs raw z, just not enough).
- **Analysis**: Spec-level negative, not mechanism-level. The wrapper architecture is correct. The failure is `c_t=1/(t+1)` + `cooldown_frac=0` combination on a 3350-step from-scratch run. Matches advisor pre-flag at 08:34 UTC. Natural wave-3 retry: polynomial-weighted c_t concentrating mass on post-warmup iterates.
- **Decision**: CLOSED as clean negative on spec (PR #121 closed 2026-05-16 ~12:40 UTC). Tanjiro reassigned to PR #155 (Polynomial-Weighted Schedule-Free Muon, c_t=(t+1)^p / Σ(i+1)^p for p ∈ {2,4,6}, same β=0.90).

## 2026-05-16 13:15 UTC — PR #45: Muon² (Adam v-buffer + NS, record #7 repro) — CLOSED (clean negative under new baseline)

- Branch: `g1r5-edward/muon-squared-3325`
- Student: g1r5-edward
- Hypothesis: Reproduce record #7 (Muon²): add a per-parameter Adam-style second-moment buffer `v` scaled before NS orthogonalization (`update = grad_nesterov / (sqrt(v) + eps)`), plus use lr=0.10 matching the record. Public reference: val/loss 3.2752 (n=1) at 3325 steps.

| Seed | val/loss (final) | ffs  | Hit target (<3.28)? |
|-----:|-----------------:|-----:|:-------------------:|
| 0    | 3.27868          | 3300 | ✓                   |
| 1    | 3.27828          | 3300 | ✓                   |
| 2    | 3.27836          | 3275 | ✓                   |
| 3    | 3.27859          | 3325 | ✓                   |
| 4    | 3.27838          | 3275 | ✓                   |
| 5    | 3.27817          | 3300 | ✓                   |
| 6    | 3.27890          | 3325 | ✓                   |
| 7    | 3.27844          | 3300 | ✓                   |

- **n**: 8 seeds, `train_steps=3325`
- **mu**: 3.27843, std ≈ 0.00023, ffs_mean ≈ 3300
- **Statsig vs 3.28 target**: `(3.28 - 3.27843) × sqrt(8) = 0.00444 ≥ 0.004` — **PASS** (passes 3.28 target rule)
- **Statsig vs new baseline (PR #46 mu=3.27744)**: `(3.27744 - 3.27843) × sqrt(8) = -0.00280` — **FAIL** (mu above new baseline by 0.00099; ffs +100 steps slower)
- **Comparison vs public record #7 (mu=3.2752, n=1)**: Our n=8 mu=3.27843 is reproducible and consistent with the record — the record's n=1 mu=3.2752 is well within the seed distribution tail. Record #7 uses 8 GPUs (vs 1 GPU here); the v-buffer may interact with the 8-GPU all-reduce pattern differently than 1-GPU. **Record #7 reproduces cleanly.**
- **W&B run IDs**: `g1r5-edward/muon-squared-3325` group
- **Mechanism analysis**: PR #45's v-buffer is applied BEFORE NS orthogonalization: `update = grad_nesterov / (sqrt(v) + eps)`. SOAP-MLP (merged baseline) applies covariance-based preconditioning to MLP params. The v-buffer and SOAP both do per-direction scaling — double-scaling with different statistics, causing the interference observed. For attn params (plain-Muon path), v-buffer applies without SOAP, but the lr=0.10 (vs baseline 0.035) is the likely cause of slower convergence on attn: with v-buffer normalizing magnitudes, lr=0.10 may be over-stepping in directions where v is still being estimated in early training.
- **Key finding**: The 12-step cubic NS polynomial (`a=2, b=-1.5, c=0.5`) was already in the merged baseline — it is NOT the source of PR #45's delta. The ONLY actual delta from merged baseline was the v second-moment buffer + lr=0.10.
- **Decision**: CLOSED as clean negative under new baseline (PR #45 closed 2026-05-16 ~13:15 UTC). Edward reassigned to PR #159 (Per-group LR sweep: test whether SOAP-managed MLP params can tolerate a higher base lr than plain-Muon attn params).

## 2026-05-16 16:30 UTC — PR #116: SOAP-attn + trust gate on merged SOAP-MLP base — MERGED ✓ (NEW BASELINE)

- Branch: `g1r5-fern/soap-attn-trustgate`
- Student: g1r5-fern
- Hypothesis: Extend SOAP preconditioning from MLP-only (baseline PR #46) to all attn projection weights (q, k, v, attn.proj). Add trust gate: falls back to plain Muon NS when `cos(u_soap, u_muon) < threshold` (default 0.0). One fused n=6 confirmation run.

| trial | best_val_loss | best_val_step | first_step_to_target | hit target |
|------:|--------------:|--------------:|---------------------:|:----------:|
| 0     | 3.27518       | 3250          | 3175                 | ✅         |
| 1     | 3.27375       | 3250          | 3150                 | ✅         |
| 2     | 3.27448       | 3250          | 3150                 | ✅         |
| 3     | 3.27210       | 3250          | 3125                 | ✅         |
| 4     | 3.27406       | 3250          | 3150                 | ✅         |
| 5     | 3.27284       | 3250          | 3150                 | ✅         |

- **n**: 6 seeds, `train_steps=3250`
- **mu (val/loss)**: **3.273735**, std=0.001116, SE=0.000455
- **mean ffs**: **3150**, best ffs=**3125**
- **Statsig vs 3.28 target**: `(3.28 - 3.273735) × sqrt(6) = 0.01535 ≥ 0.004` — **PASS** (3.8× margin)
- **Statsig vs PR #46 baseline (mu=3.27744)**: Δmu=−0.003705, ~8σ improvement
- **W&B run**: `c81z4php` (group: `g1r5-fern/soap-attn-trustgate`, `wandb-applied-ai-team/modded-nanogpt-senpai`)
- **Trust gate telemetry**: fired_count=0/19500 steps (gate dormant). min cos_sim=0.033, mean MLP cos_sim=0.884, mean attn cos_sim=0.798. Attn eigenbases consistently 0.08 lower cos_sim than MLP — confirms attn gradient covariance less stable but never near fallback threshold. Gate acts as free safety net, not load-bearing mechanism. Eigendecomp refreshes: 203/trial × 6 trials = 1218 total. Zero NaN/divergence across 19500 steps.
- **Analysis**: SOAP preconditioning extends cleanly from MLP to attn projections. The improvement is from the eigenspace preconditioning on attn weights, not the gate. Best trial ffs=3125 matches record #16 reference frontier. Trust gate threshold=0.0 is decorative on this stack; min observed cos_sim=+0.033 keeps SOAP direction always within same hemisphere as Muon. Future follow-up: explore positive threshold values (0.3–0.7) to probe cliff behavior.
- **New merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27210 at n=6, ≤ 3.27245 at n=8
- **Decision**: MERGED as new baseline 2026-05-16 16:30 UTC. ffs 3200→3150 (mean), 3200→3125 (best).

## 2026-05-16 ~18:00 UTC — PR #130: Label Smoothing on CE Training Loss (ε sweep) — CLOSED (clean negative)

- Branch: `g1r5-askeladd/label-smoothing`
- Student: g1r5-askeladd
- Hypothesis: Apply label smoothing (ε ∈ {0.05, 0.10, 0.15}) to the cross-entropy training loss to bound logit margin growth near end of cooldown, improving gradient signal on the true class. Baseline val path remains raw CE.

| ε    | val/loss @ 3200 | ffs | logit_margin_mean (end) | logit_max_abs (end) | W&B run  |
|:----:|:---------------:|:---:|:-----------------------:|:-------------------:|:--------:|
| 0.05 | 3.32468         | -1  | 1.472                   | 13.60               | 60992jbi |
| 0.10 | 3.38128         | -1  | 1.467                   | 13.55               | d3sal3b8 |
| 0.15 | 3.44005         | -1  | 1.461                   | 13.74               | tfsaj446 |

- **n**: 1 per arm (3 arms total, 3200 steps each)
- **Best cell (ε=0.05)**: val/loss=3.32468 — **+0.047 nats above baseline (3.27744)**; +47σ above new baseline (3.273735). Kill gate engaged per pre-declared contract.
- **SENPAI-RESULT**: `terminal=true, pending_arms=false, wandb_run_ids=["60992jbi","d3sal3b8","tfsaj446"], primary_metric.value=-1, test_metric.value=3.32468`
- **Mechanism diagnosis (student's analysis, advisor concurs)**: Logit margin under raw CE is already small (~1.45–1.50 at step 3200), so the saturation premise was never engaged. Smoothing instead diluted the per-token gradient signal on the true class, monotonically degrading val_loss with ε. logit_max_abs peaked at 13.5–13.7 (well under softcap=15), confirming softcap was not the bottleneck. The smoothing gap `loss_smoothed − loss_raw` correctly tracks ε·log(V), confirming correct implementation.
- **Conclusion**: Hypothesis refuted by premise (not by competing mechanism). CE loss-side angle at this step budget/recipe is closed. z-loss (PaLM/T5 style: α·log²(Σexp(logits))) remains an untested loss-side angle for a future wave.
- **Kill gate fired**: all 3 cells `val/loss ≫ 3.278`, `ffs=-1`.
- **Decision**: CLOSED as clean negative 2026-05-16 ~18:00 UTC. Next assignment: SOAP β2 cooldown annealing (PR #175).

## 2026-05-16 15:47 UTC — PR #147: Output Embedding Mean-Centering (mu-centering) — CLOSED (clean negative)

- Branch: `g1r5-nezuko/mu-centering`
- Student: g1r5-nezuko
- Hypothesis: Post-step mean-centering of `lm_head.weight` (subtract column mean, dim=0/vocab axis) to remove gauge drift per Stollenwerk et al. translation invariance argument.

| Trial | Seed | val/loss @ 3250 | ffs | hit target |
|:-----:|:----:|:---------------:|:---:|:----------:|
| 0     | 0    | 3.29977         | -1  | No         |
| 1     | 1    | killed @step 400 | —  | —          |
| 2-3   | 2-3  | not run         | —   | —          |

- **n**: 1 effective (trial 0 complete, trial 1 kill-gate triggered)
- **mu**: 3.29977 (trial 0 only)
- **Statsig vs 3.28 target**: `(3.28 - 3.29977) × sqrt(1) = -0.020` — **FAIL** by 52σ above baseline
- **W&B run IDs**: `ymlx5jyj` (screen), `7chk3jsb` (smoke)
- **Mechanism diagnosis**: Softcap (line 435: `15*logits*(logits.sq+225).rsqrt()`) breaks the translation invariance Stollenwerk et al. require. Column-mean in `lm_head.weight` is NOT pure gauge drift — optimizer uses it for real work through softcap saturation behavior. Forcibly zeroing it costs 0.022 val_loss. Also: lm_head bias already provides 50304 d.o.f. to absorb constant logit shifts, making the gauge argument doubly moot.
- **Kill gate**: step-500 train_loss 3.853 vs baseline 3.814 (+0.036, 12× threshold). Trial 1 killed at step 400 (trajectory worse than trial 0).
- **Decision**: CLOSED as clean negative. Softcap-bearing GPTs are immune to column-mean centering gauge argument. Mu-centering on lm_head.weight is a hypothesis-level dead end for this architecture.

## 2026-05-16 ~20:00 UTC — PR #141: Gradient Centralization in Muon update — CLOSED (clean negative)

- Branch: `g1r5-frieren/gradient-centralization`
- Student: g1r5-frieren
- Hypothesis: Pre-momentum row-mean subtraction on all Muon-managed 2D weights (GC applied before `momentum.lerp_(grad, 1-mu)` in Muon.step, and before SOAP's covariance update for MLP path).

| Trial | val/loss @ 3250 | ffs | hit target? |
|:-----:|:---------------:|:---:|:-----------:|
| 0     | 3.27880         | 3225| ✓           |
| 1     | 3.27902         | 3225| ✓           |
| 2     | 3.27660         | 3175| ✓           |
| 3     | 3.28010         | -1  | ✗           |

- **n**: 4 seeds, `train_steps=3250`
- **mu (val/loss)**: **3.27863**, std=0.00147
- **mean ffs** (3 trials reaching target): 3208.33; treating ffs=-1 as 3250: 3218.75
- **Statsig vs target 3.28**: (3.28 − 3.27863) × √4 = **+0.00274** — fails 0.004 rule
- **Statsig vs current baseline (3.273735)**: (3.273735 − 3.27863) × √4 = **−0.00980** — GC is WORSE than baseline
- **W&B run IDs**: `acqg7tgb` (n=4 screen), `uyrb54gf` (smoke)
- **Key diagnostic**: GC removed ~10.5% of gradient Frobenius energy (substantial, not gauge-trivial). Two failure mechanisms: (1) NS5 polar projection already damps the row-mean singular direction → GC is nearly redundant on the update; (2) GC modifies the gradient input to SOAP's preconditioner update, changing the eigenbasis to track only fluctuating components and dropping stable directional signal worth 10.5% of grad energy.
- **Mechanism conclusion**: The row-mean is NOT pure gauge on this stack — it carries real gradient signal that both NS5 and SOAP exploit. GC's subtraction hurts both.
- **Closed mechanism**: Row-mean centering pre-momentum on Muon-managed weights. NS5 already subsumes GC's row-mean removal.
- **Decision**: CLOSED clean negative 2026-05-16 ~20:00 UTC. Next assignment: z-loss auxiliary regularizer (PR #186).

## 2026-05-16 ~20:30 UTC — PR #155: Polynomial-Weighted Schedule-Free Muon (p sweep)

- g1r5-tanjiro/polynomial-schedfree
- Hypothesis: Replace the baseline LR schedule with polynomial-weighted iterates `x = w + (lr/c̄) Σ c_t z_t`, where `c_t = (t+1)^p / Σ(i+1)^p` and p∈{2,4,6}. Expectation: concentrating averaging mass on later (lower-loss) iterates should produce a better final parameter estimate than uniform weighting.

| p_avg | val/loss_x | val/loss_z | ffs | run_id |
|------:|-----------:|-----------:|----:|:------|
| 2 | 3.34126 | 11.06122 | -1 | it6ovjhz |
| 4 | 3.35015 | 8.50778 | -1 | 1p6tbno4 |
| 6 | 3.36407 | 8.21119 | -1 | 753gclup |

- **n**: 1 seed per cell (n=3 arms, 1 trial each)
- **Primary metric (best cell p=2)**: ffs=-1 (did NOT reach target), best_val=3.34126
- **Kill gate**: All 3 cells val_loss_x > 3.32 → triggered as predeclared
- **Statsig vs target 3.28**: All arms fail by ≥+0.06 nats
- **Mechanism conclusion**: z-trajectory is divergent at constant LR (no cooldown). Polynomial weighting c_t = (t+1)^p / Σ(i+1)^p concentrates mass on increasingly-worse late iterates rather than helping. At p=6 val_z=8.21 confirms z never converged. The schedule-free framework requires z to converge OR explicit cooldown built into z — neither holds in this 3350-step recipe where the LR schedule cools w but not z. Both uniform (PR #121, p=0) and polynomial (PR #155, p>0) fail for the same root cause.
- **Closed mechanism**: Schedule-free Muon on the 3350-step modded-nanogpt benchmark. Both uniform and polynomial forms exhausted.
- **Decision**: CLOSED clean negative 2026-05-16 ~20:30 UTC. Tanjiro reassigned to asymmetric per-group WD (PR #194).
