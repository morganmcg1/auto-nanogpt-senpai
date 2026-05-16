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
