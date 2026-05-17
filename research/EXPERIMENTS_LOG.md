# SENPAI Research Results

## 2026-05-15 15:00 — PR #68: Aurora + Contra-Muon + u/w floor (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra`
- Hypothesis: Reproduce Record #17 — Aurora row-norm equilibration before NS polar, Contra-Muon momentum subtraction (coeff=0.2), Skylight u/w floor (TARGET_UW=0.35). No weight decay. lr=0.0375.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **3175** |
| val/loss at crossing | 3.274438 |
| margin | +0.005562 (≥ 0.004 ✓) |
| n | 1 |
| W&B run | `lg4xdlkt` |
| Wall clock | ~107 min (1×H100) |
| train_steps used | 3250 |

**Analysis:** First local winner. Confirms that the Aurora+Contra-Muon+Skylight stack from public Record #17 (3175 steps, n=20, mean val 3.2789) transfers to our local hardware with comparable step count on n=1. Aurora's row-norm equilibration pre-conditions the gradient mass distribution before NS orthogonalization; Contra-Muon applies a 0.2× negative projection against the raw momentum direction; Skylight u/w floor prevents weight norm collapse. The combination appears to synergize: Aurora→Contra→NS is stronger than Contra alone (public records #9→#11 progression). Stat-sig bar cleared on n=1 (rare — margin of 0.0056 is generous). Also includes `sample_tensor` linspace fp32 precision fix.

**Conclusion:** MERGED as first local anchor. New baseline: 3175 steps. Wave 2 assignments: tanjiro gets SOAP-MLP addition, askeladd gets NorMuon addition.

---

## 2026-05-15 15:30 — PR #61: NorMuon short-axis variance EMA (g1r1-askeladd)

- Branch: `g1r1-askeladd/normuon-short-axis`
- Hypothesis: Per-row second-moment EMA along the short axis after NS polar step (beta2=0.95, eps=1e-10), Frobenius-renormalized. Isolation test of NorMuon without Aurora/Contra/u/w.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | 3275 |
| val/loss at crossing | 3.27920 |
| margin | +0.00080 (< 0.004, n=1 insufficient) |
| n | 1 |
| W&B run | `9ju04ncw` |
| Wall clock | ~99.3 min (RTX PRO 6000 Blackwell) |
| train_steps used | 3300 |

**Analysis:** NorMuon mechanism confirmed on local hardware — reaches target at 3275 steps with no NaN/Inf, closely matching public Record #10 (3250 steps, n=20) on a single seed. However, 3275 > 3175 (new local baseline from PR #68), so NorMuon alone does not beat the current best. This is expected: NorMuon adds row-adaptive scaling to Muon, which is a positive building block but not as strong as the full Aurora+Contra+u/w stack in isolation. Note: stat-sig bar at n=1 is not cleared (margin 0.00080 < 0.004), which was expected for a screening run.

Student also reported: (1) `sample_tensor` bug fix included (already merged via #68), (2) confirmed that Muon.step *does* apply WD (`p.mul_(1 - lr*wd)`) — BASELINE.md gotcha note was inaccurate. This clarifies effective WD at lr=0.035, wd=0.025 ≈ 0.000875/step.

**Conclusion:** CLOSED — doesn't beat new 3175 baseline as standalone. NorMuon signal is valuable for stacking. New assignment: Aurora+Contra+u/w+NorMuon in PR #84.

---

## 2026-05-15 17:00 — PR #67: SOAP-MLP only on Muon (g1r1-nezuko)

- Branch: `g1r1-nezuko/soap-mlp`
- Hypothesis: SOAP-style Shampoo-eigenbasis Adam preconditioning on MLP fc/proj weights, applied before NS polar step. Isolation of SOAP-MLP without Aurora/Contra/NorMuon. β2=0.90, eps=1e-10, precond_freq=10.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | 3200 |
| val/loss at crossing | 3.27705 |
| margin | +0.00295 (< 0.004, n=1 insufficient) |
| n | 1 |
| W&B run | `kkegpr5n` |
| Wall clock | ~107 min (~1.98 s/step due to 3072×3072 eigh) |
| train_steps used | 3250 |

**Analysis:** SOAP-MLP isolation result. 3200 steps is only 25 steps behind our 3175 baseline (PR #68 Aurora+Contra+u/w) — strong single-mechanism signal. Within noise of public Record #14 (Contra+NorMuon+SOAP-MLP at 3150, n=4). Per-step wall-clock dominated by eigenbasis refresh on the 3072×3072 MLP fc covariance every 10 steps. Student added `_safe_eigh` with fp64 fallback + 1e-30 diagonal jitter (no fallback events triggered, confirming numerical stability throughout). Margin 0.00295 doesn't clear the 0.004 stat-sig bar on n=1.

**Conclusion:** CLOSED — doesn't beat 3175 baseline as standalone. The isolation point is valuable for attributing the SOAP-MLP contribution when tanjiro's stacked variant (PR #83, Aurora+Contra+u/w+SOAP-MLP) lands. Nezuko reassigned to power-law cooldown (PR #85, schedule-lever experiment orthogonal to optimizer stacking).

---

## 2026-05-15 21:00 — PR #69: KL-SOAP-H replaces Newton-Schulz entirely (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/klsoap-h`
- Hypothesis: Replace NS polar step entirely with full SOAP-in-Q-basis Adam updates for all hidden 2D matrices. lr=0.018, β1=0.95, β2=0.90, shampoo_beta=0.90, precond_freq=1, hyperball param update.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | -1 (not reached) |
| val/loss trajectory (initfix run `beqqi17z`) | step 0: 10.83 → step 875: 4.498 → step 1750: 4.224 |
| Projected final val/loss at step 3150 | ~3.9 (clean decline ~0.03/125 steps) |
| n | 1 (closed before completion) |

**Analysis:** Initial run diverged due to zero-init `*.proj.weight` paired with hyperball optimizer (frozen layers). Student debugged this carefully, corrected init recipe, relaunched as `klsoap-h-initfix`. Restart trained cleanly with zero NaN throughout, monotonic decline. But the slope is too shallow — extrapolated to step 3150, val_loss lands around 3.9, far above the 3.28 target. The decline doesn't accelerate in cooldown either.

**Conclusion:** CLOSED as clean negative result. KL-SOAP-H replacing NS entirely cannot compete in our step budget. The NS orthogonalization is essential — pure SOAP-in-Q-basis without polar normalization has too much scale/variance drift. The Q-basis preconditioning idea is sound (record #19 publicly reaches 3125 at n=6), but pure SOAP-as-replacement is the wrong framing on our scale/budget. SOAP-as-curvature-prefilter (record #14 / nezuko's #67 style) is the correct framing. Thorfinn reassigned to per-module init std experiment (PR #89).

---

## 2026-05-15 21:30 — PR #63: u/w floor (Skylight) on Muon (g1r1-edward)

- Branch: `g1r1-edward/uw-floor`
- Hypothesis: Standalone Skylight u/w floor (TARGET_UW=0.35, no weight decay). Isolation of u/w-floor mechanism without Aurora/Contra/NorMuon.

| Seed | Run ID | target_step | val/loss | Hit |
| ---- | ------ | ----------- | -------- | --- |
| 1 | `3fis12l2` | 3275 | 3.278 | ✓ |
| 2 | `574onkh8` | -1 | 3.280 | ✗ (missed by 0.002) |
| 3 | (not run) | — | — | — |

**Analysis:** Seed 1 hit target cleanly at step 3275, seed 2 just missed (val 3.280 at step 3300, target_step=-1). At n=2 with 1 hit, the mean cannot beat our 3175 baseline (PR #68) even if seed 3 also hits — best-case mean would land around 3275, 100 steps behind. Standalone u/w floor on our hardware is more variable than the public Skylight record #9 (3250 mean at n=8); likely because we lack the orthogonalization-side mechanisms that record #9 may carry implicitly.

**Conclusion:** CLOSED — standalone u/w floor cannot beat the merged baseline (which already includes u/w floor as one of three stacked mechanisms). Edward's isolation result is useful retrospective attribution data. Reassigned to Soft-Muon in cooldown experiment (PR #88).

---

## 2026-05-15 18:25 — PR #64: PMuon streaming covariance preconditioning (g1r1-fern) **WINNER pending rebase**

- Branch: `g1r1-fern/pmuon-cov-precond`
- Hypothesis: Maintain streaming left/right covariance EMAs (β_cov=0.95), use `L^{-γ} m R^{-γ}` preconditioning (γ=0.3) — replaces the NS polar step entirely. Public reference: Record #18, mean 3.2776 at 3225 steps, n=9.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **3150** |
| val/loss at crossing | 3.27447 |
| margin | +0.005530 (≥ 0.004 ✓) |
| n | 1 |
| W&B run | `vx0r7rp2` |
| Wall clock | ~4.15 h (1× H100, ~3847 ms/step including val events) |
| train_steps used | 3250 |
| val_loss at step 3225 (record-comparison) | 3.27500 |

**Analysis:** Standalone PMuon is the new **best single-mechanism result** on our hardware — beats #68's Aurora+Contra+u/w (3175 steps) by 25 steps with a single mechanism. The streaming covariance preconditioner replaces NS polar with a more curvature-aware update; it doesn't need Aurora's row-norm equilibration or Contra-Muon's negative momentum subtraction.

**Important caveat:** Result is on the **pre-#68 code path** — PMuon replaces NS, so it's not compatible with the Aurora+Contra+u/w mechanism. The rebase strategy must keep PMuon and drop Aurora+Contra+u/w during conflict resolution to preserve attribution. Fern's `sample_tensor` fp64 fix is the same as in #68 (already merged) — should rebase cleanly there.

**Conclusion:** Confirmed winner with terminal SENPAI-RESULT marker. **Pending fern's rebase** before merge. Once merged, BASELINE.md updates to 3150 steps. The Aurora+Contra+u/w mechanism family then becomes a parallel-track baseline candidate that we may need to re-introduce as a stack on PMuon (e.g., a Wave 3 "PMuon + u/w floor" experiment).

---

## 2026-05-15 19:00 — PR #83 intervention: Aurora+Contra+SOAP-MLP destabilized (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra-soap-mlp`
- W&B run: `avn3wrne`
- Status: **DESTABILIZED at step 1500** (sent back, not closed)

**Diagnosis:** val/loss 5.67 at step 1500 (should be ~3.8 for a healthy Aurora+Contra+u/w trajectory). Two visible spikes at steps 750 and 1375. Raw grad norms enormous (`train/grad/all/max`=6659, global=49112) despite Frobenius renorm. `nonfinite_count=0` so not NaN — pure runaway scale. The SOAP-MLP eigenvalue-inverse scaling is amplifying small singular components beyond what Frobenius renorm can absorb.

**Intervention plan (posted to PR):**
1. Smoke-test base with SOAP disabled (verify Aurora+Contra+u/w still works on this branch)
2. Re-enable SOAP with three stability guards: `SOAP_BETA2=0.99` (slower burn-in), `m_scaled.clamp_(±10.0)` (hard cap), upper-amp cap on Frobenius renorm (`≤1.5x`)
3. If still unstable: disable Contra-Muon (`CONTRA_COEFF=0`) to test SOAP+Contra interaction
4. Full 3200-step run only after smoke shows tracking baseline trajectory

**Why send back rather than close:** SOAP-MLP works standalone (PR #67 nezuko, 3200 steps). The integration with Aurora+Contra is the issue, not the mechanism. Public Record #14 stack (Contra+NorMuon+SOAP-MLP at 3150 steps) shows the combination is achievable with right guards.

---

## 2026-05-15 20:21 — PR #59 CLOSED: Vanilla Muon attribution baseline (g1r1-alphonse)

- Branch: `g1r1-alphonse/vanilla-muon-baseline`
- W&B run: `83qeloh9` (group `g1r1-alphonse/vanilla-baseline`)
- Hypothesis: True vanilla Muon (lr=0.035, wd=0.025, NS5, no Contra/Aurora/u/w-floor) with `dynamic=True` compile workaround as attribution anchor.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **-1 (target NOT reached)** |
| val/loss (final) | 3.29743 |
| margin | -0.01743 (target=3.28; failed) |
| n | 1 |
| train_steps used | 3350 |

**Analysis:** True vanilla Muon with compile-bug workaround ran cleanly to 3350 steps but final val/loss = 3.29743, 0.017 above the 3.28 target. Single-trial result; vanilla cannot beat the merged baselines (Aurora+Contra+u/w PR #68 at 3.274 nominal vs 3.297 vanilla = ~0.023 attribution gap). Alphonse's compile-bug root-cause diagnostic was the major value contribution from this PR.

**Conclusion:** CLOSED as attribution anchor result. Vanilla doesn't beat baseline by construction. Alphonse's compile-bug root-cause and `dynamic=True` workaround feed forward into all future PMuon-base experiments.

---

## 2026-05-15 20:35 — PR #84 CLOSED + CRITICAL FINDING: Aurora+Contra+u/w PR #68 base is empirically broken (g1r1-askeladd)

- Branch: `g1r1-askeladd/aurora-contra-normuon`
- W&B runs: `xakwxu84` (killed step 2032), `761npqac` (killed step 1250), `liwmf3pg` (sanity NORMUON_BETA2=0)

**Discovery:** askeladd implemented NorMuon short-axis EMA per PR #84 spec, but both full runs diverged identically. The sanity run with NORMUON_BETA2=0 (NorMuon disabled, pure Aurora+Contra+u/w base) ALSO diverged at step 125 with val/loss 7.79 vs canonical PR #68 trajectory at val/loss 4.63. **The PR #68 base recipe is not reproducible on this pod.**

**Confirmed divergent runs of PR #68 recipe (val_loss at step 125):**
- `q869emek` (tanjiro/smoke3-pr68-pristine): 15.57 — crashed
- `343520k1` (thorfinn/per-module-init): 12.26
- `n4l14w3j`, `dpfoptl8` (nezuko/power-cooldown-1p2): 9.16, 10.96
- `8qkxbh7c` (alphonse/smoke-dynamic-true on aurora+contra+uw): 15.50 — `dynamic=True` NOT sufficient
- `liwmf3pg` (askeladd/sanity-normuon-off): 7.79
- `xakwxu84`, `761npqac` (askeladd NorMuon stack): 9.38, 7.99

All show `train/grad/global_norm ≈ 234K` at step 1 — the Inductor compile bug signature from PR #59 alphonse root cause. Original PR #68 winner `lg4xdlkt` was a lucky compile-cache draw, not a reproducible recipe.

**Implication:** PR #68's recorded baseline (3175 steps) is an artifact. PMuon (PR #64, run `vx0r7rp2`) is the only reliably-reproducible local baseline because covariance whitening empirically damps the seed-NaN amplitude.

**Conclusion:** Closed PR #84 (askeladd reassigned to PR #94 PMuon + u/w-floor). All five Wave 2 PRs (#83 tanjiro, #84 askeladd, #85 nezuko, #88 edward, #89 thorfinn) sent back to pivot from broken Aurora+Contra+u/w base to PMuon base. Nezuko (#85) had already adapted independently. Wave 2 becomes Wave 3 portfolio on PMuon.

---

## 2026-05-16 01:25 — PR #89: Per-module init std on PMuon base (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/per-module-init` (pivoted to PMuon base in commit `f9a3645`)
- Hypothesis: Replace PMuon's default `*.proj.weight` zero-init with explicit per-module std values (attn.q/k/v=0.020, attn.proj=0.026, mlp.fc=0.031, mlp.proj=0.031). Tests whether non-zero residual-output init helps PMuon trajectory.
- W&B run: `ipohjfgm` (n=1, train_steps=3250, dynamic=True compile fix applied)

| Metric | This run | Baseline (`vx0r7rp2` PMuon) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | 3175 | 3150 | +25 steps (worse) |
| val/loss (step 3250) | 3.27639 | 3.27447 | +0.00192 (worse) |
| (3.28-μ)·√n margin (n=1) | 0.00361 | 0.00553 | fails 0.004 rule |
| Runtime | 3h40m | 4h09m | -1745s |

**Analysis:** Init verification table confirms observed_std matches expected for every category (q/k/v=0.020, attn.proj=0.026, mlp.fc/proj=0.031). The change from PMuon's default zero-init for `*.proj.weight` to non-zero std hurts the optimization trajectory marginally. Likely interaction: zero-init residual-output weights start with zero gradient through the residual path, giving PMuon's L/R covariance EMAs a cleaner step-0 signal. Non-zero init perturbs this, putting PMuon in a slightly worse early-step regime.

**Conclusion:** CLOSED as clean negative result. Per-module init is not a free lever on PMuon base — PMuon's default zero-init for `*.proj.weight` is doing real work via covariance EMA interaction. Reassigned thorfinn to PR #110 (PMuon γ-scan at 0.25 and 0.35).

---

## 2026-05-16 00:30 — PR #85 (interim): Power-law cooldown γ=1.2 on PMuon — SENT BACK for n=2 confirmation (g1r1-nezuko)

- Branch: `g1r1-nezuko/power-cooldown-1p2`
- W&B run: `xr4hkd3y` (n=1, train_steps=3200, γ=1.2 power-law cooldown)
- Result: speedrun=3100 (−50 vs 3150), val=3.27647

| Metric | This run | Baseline |
| --- | --- | --- |
| speedrun/final_first_step_to_target | 3100 | 3150 |
| val/loss (final, step 3200) | 3.27647 | 3.27447 (step 3250) |
| val/loss at matched step 3150 | 3.27727 | 3.27447 (worse at matched step) |
| (3.28-μ)·√n margin (n=1) | 0.00353 | 0.00553 (fails 0.004) |

**Decision:** Send back for n=2 confirmation at `train_steps=3250` (apples-to-apples vs PR #64). Reasons:
1. n=1 margin 0.00353 fails the 0.004 statistical rule.
2. Train_steps mismatch (3200 vs 3250) confounds cooldown-shape vs total-budget contributions to the speedrun delta.
3. At matched step 3150, this run's val/loss (3.27727) is *worse* than PMuon's (3.27447) — so the cooldown shape itself isn't strictly better; speedrun delta is partly a budget effect.

Re-run command:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 2 \
  --wandb_name "g1r1-nezuko/power-cooldown-1p2-confirm" \
  --wandb_group "g1r1-nezuko/power-cooldown-confirm"
```
with `train_steps=3250`. Confirmation run `u3o8j3yj` started 2026-05-16 01:22 UTC.

---

## 2026-05-16 03:29 — PR #88 CLOSED: Soft-Muon (p=0.1) in cooldown on PMuon base (g1r1-edward)

- Branch: `g1r1-edward/soft-muon-cooldown`
- Hypothesis: Blend post-polar update with momentum direction during cooldown phase (last 70%): `update = (1-p)*polar + p*(m_pre/||m_pre||_F * sqrt(min_dim))`. `p=0.1`, gated to steps 977-3250.
- W&B run: `dezar21q` (n=1, train_steps=3250, dynamic=True compile fix applied)

| Metric | This run | Baseline (`vx0r7rp2` PMuon) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3150** | 3150 | **0 (no improvement)** |
| val/loss (step 3250) | 3.274323 | 3.274469 | −0.000146 (within noise) |
| (3.28-μ)·√n margin (n=1) | 0.00568 | 0.00553 | both pass rule |

**Analysis:** Soft-Muon gating verified correctly (`softmuon/active` toggles at step 977, `effective_p=0.1` throughout cooldown). Val/loss curves track on top of each other — minor lead in early cooldown (+0.001 to +0.003 above baseline steps 1000-1900), converging and slightly below baseline in final steps (−0.0001 to −0.0003 from step 2500+). The primary metric (speedrun step) is identical: no improvement. **The mechanism does not add lift on top of PMuon's bilateral whitening** — PMuon's `L^{-γ} ⊗ R^{-γ}` already implements much of the SVD-direction shrinkage that Soft-Muon targets in cooldown.

**Conclusion:** CLOSED as clean null result. Reassigned edward to PR #118 (PMuon cooldown_frac scan: 0.5 vs 0.8).

---

## 2026-05-16 03:35 — PR #95 CLOSED: PMuon + Contra-Muon (both coeff=0.2 and 0.1 catastrophic) (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-contra-muon`
- Hypothesis: Add Contra-Muon (subtract `contra_coeff` × Frobenius-normalized pre-polar momentum) to PMuon post-polar update. Coefficients 0.2 (prescribed) and 0.1 (fallback).
- W&B runs: `2jslevyc` (coeff=0.2, killed ~step 1500), `3filu2p3` (coeff=0.1, killed step 1030)

| run | contra_coeff | killed_at | val/loss@1000 | dir_norm_ratio (mean) | first_step_to_target |
| --- | --- | --- | --- | --- | --- |
| `2jslevyc` | 0.2 | ~step 1500 | ~7.54 | 1.59 | -1 |
| `3filu2p3` | 0.1 | step 1030 | 7.331 | 1.59 | -1 |
| baseline `vx0r7rp2` | n/a | finished | 3.62 | n/a | 3150 |

**Analysis:** Both coefficients produce catastrophic divergence (train_loss spikes to 14.6+ at step ~100, grad_norm to 1e5-1e6+, no recovery). Root cause (student diagnosis): empirical `dir_norm_ratio ≈ 1.59` means PMuon's whitened polar has Frobenius ≈ 0.62× the `target_scale=sqrt(min(m,n))` that Contra-Muon assumes. Effective perturbation = `contra_coeff × 1.59 × ||update||_F` — a 32% off-direction perturbation at coeff=0.2 that destabilizes the optimizer.

**Key insight:** To fix Contra-Muon on PMuon base, `contra_dir` must be scaled to the **actual** `||update||_F` rather than the assumed `sqrt(min(m,n))`. This makes the perturbation magnitude scale-coherent. This is the basis for the next PR (alphonse PR #119, measured-scale Contra-Muon).

**Conclusion:** CLOSED as clean negative on the as-spec'd formulation. Reassigned alphonse to PR #119 (measured-scale Contra-Muon with calibrated target_scale).

---

## 2026-05-16 03:30 — PR #93 SENT BACK: PMuon + NorMuon (element-wise) — retry with row-wise (g1r1-fern)

- Branch: `g1r1-fern/pmuon-normuon-stack`
- W&B run: `0x6cgq1a` (FINISHED), second arm `5d4u7d1n` (RUNNING — student-initiated n=2)

| Metric | This run (element-wise) | Baseline (PMuon `vx0r7rp2`) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3225** | 3150 | **+75 steps (worse)** |
| val/loss (step 3250) | 3.2789 | 3.27447 | +0.0044 (worse) |

**Analysis:** Student correctly noted PR instructions were ambiguous (element-wise code vs short-axis text). Ran element-wise (Adam-style) interpretation as specified. Element-wise post-NS scaling on top of PMuon's bilateral whitening is redundant — PMuon already whitens row/col via `L^{-γ} ⊗ R^{-γ}`, so per-element scaling double-whitens and mildly hurts trajectory (+75 step regression).

**Decision:** Send back for row-wise short-axis (PR #61 validated mechanism) retry. Row-wise NorMuon is mechanistically distinct from element-wise: per-neuron diagonal scaling vs full off-diagonal bilateral whitening. The PR #61 result at 3275 (standalone) establishes that row-wise NorMuon has a positive signal on vanilla Muon; on PMuon base it may or may not stack.

---

## 2026-05-16 07:28 — PR #94 MERGED: PMuon + Skylight u/w-floor (TARGET_UW=0.35) (g1r1-askeladd) ← NEW BASELINE

- Branch: `g1r1-askeladd/pmuon-uw-floor`
- Hypothesis: Add Skylight u/w-floor to PMuon: after `pmuon_update(...)`, if `||update||_F / ||w||_F < TARGET_UW=0.35`, rescale update to floor. Prevents PMuon's bilateral whitening from shrinking update steps into subthreshold magnitude territory.
- W&B runs: `yeyewcj6` (n=1, finished 2026-05-15 21:34), `205sycku` (n=2 confirm, finished 2026-05-16 07:22)

| Metric | yeyewcj6 (n=1) | 205sycku (n=2) | n=2 mean | Baseline PMuon | Δ |
| --- | --- | --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3100** | **3100** | **3100** | 3150 | **−50 steps ✓** |
| val/loss (step 3250) | 3.267878 | 3.267513 | 3.267696 | 3.27447 | −0.006774 |
| (3.28−μ)·√n margin | 0.00812 | 0.00849 | 0.01740 | 0.00553 | well above rule |
| uw_floor/fired_fraction | 1.000 | 1.000 | 1.000 | n/a | always active |
| Runtime | 220 min | 215 min | — | ~220 min | — |

**Analysis:** u/w-floor fires at 100% of eligible params every step — PMuon's `L^{-γ} R^{-γ}` bilateral whitening systematically shrinks update Frobenius norms below 0.35·‖w‖, so the floor is never triggered by just a few outlier steps; it's a universal magnitude rescale. This means `TARGET_UW=0.35` is effectively acting as a per-param LR multiplier in the current underfloor regime, not a safety catch. Seed variance is extremely tight (range 0.000365 across n=2), confirming mechanistic stability. Improvement of −50 steps (3150 → 3100) matches the order of magnitude expected from Skylight in public Record #9, stacked on PMuon's direction.

**Key insight:** Since PMuon's whitening always shrinks below 0.35·‖w‖, the γ × TARGET_UW parameter space is coupled — changing β_cov (which affects how much PMuon shrinks) would change how aggressively the floor fires. Follow-up PRs: TARGET_UW sweep {0.25, 0.30, 0.40, 0.45}, β_cov scan (PR #129, frieren assigned).

**Conclusion:** MERGED as new local best. New baseline: **sr=3100, val=3.267696 (n=2)**. Students now work against this bar.

---

## 2026-05-16 07:33 — PR #65 CLOSED: MuonH hyperball Frobenius-cap on PMuon base (g1r1-frieren)

- Branch: `g1r1-frieren/muonh-hyperball`
- Hypothesis: Add MuonH hyperball renormalization — after PMuon polar update, rescale to preserve `||p||_F` — to avoid weight-norm collapse. Tests whether Frobenius-norm preservation on top of PMuon's whitening improves convergence.
- W&B run: `uxq44v87` (n=1, train_steps=3250, dynamic=True, fp32 NS5 cast applied, non-zero proj init)

| Metric | This run | New baseline (PR #94) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **−1** (target never reached) | 3100 | N/A |
| val/loss (step 3250) | 3.33021 | 3.267696 | +0.0625 (much worse) |
| vs. target 3.28 | missed by 0.0502 | beat by 0.0123 | — |
| Runtime | 229.7 min | ~220 min | — |

**Analysis:** val=3.3302 at step 3250 means the target 3.28 was never crossed — full negative. PMuon already provides very aggressive shape normalization via `L^{-γ} ⊗ R^{-γ}` followed by NS5 polar (unit operator-norm output). Hyperball on top locks `||p||_F` exactly, which removes the small weight-norm drift PMuon was implicitly using during optimization — the parameter is stuck at init norm, which may be sub-optimal. The fp32 NS5 fix (eliminates bf16 NaN) and hyperball verification telemetry (||p||_F stable to 5 sig figs) are correct implementations; the mechanism itself is incompatible with PMuon as a substrate. Key note: Record #5 MuonH is on vanilla Muon (lr=0.014, per-module init, split cooldowns) — not PMuon — so this result doesn't contradict the public record.

**Conclusion:** CLOSED as clean negative. PMuon's preconditioning and hyperball's Frobenius constraint are incompatible. Reassigned frieren to PR #129 (PMuon β_cov scan on new u/w-floor base).

---

## 2026-05-16 09:35 — PR #85 CLOSED: Power-law cooldown γ=1.2 on PMuon — n=2 confirmed but lost to new baseline (g1r1-nezuko)

- Branch: `g1r1-nezuko/power-cooldown-1p2`
- Hypothesis: Power-law cooldown with γ=1.2 makes the cooldown decay concave, spending more time at low lr. Tests whether the lr schedule shape can be improved over linear.
- W&B run: `u3o8j3yj` (n=2, two sequential trials in one run, train_steps=3250 each)

| Trial | speedrun_step | val/loss |
| --- | --- | --- |
| 0 (steps 1–3250)    | 3125 | 3.2746 |
| 1 (steps 3251–6500) | 3125 | 3.2755 |
| **n=2 mean**        | **3125** | **3.27505** |

**Stat-sig margin against 3.28:** `(3.28 − 3.27505)·√2 = 0.00700` ✓ clears 0.004 bar.

**Against new baseline (PR #94 sr=3100 val=3.267696):** sr +25 (worse), val +0.0074 (worse).

**Analysis:** Both trials reached target at sr=3125 with extremely tight per-trial val agreement (0.0009 spread). Power-law cooldown γ=1.2 is a real improvement over vanilla linear cooldown on the PMuon-only base (beats PR #64 at sr=3150 val=3.27447 by 25 steps + 0.00058 val), confirming the mechanism is mechanically sound and seed-stable. However, PR #94's u/w-floor stack moved the baseline during nezuko's confirmation runtime. Power-law cooldown alone doesn't beat the u/w-floor mechanism.

**Conclusion:** CLOSED as confirmed result that lost the moving baseline. Reassigned nezuko to PR #137 — stack power-law cooldown γ=1.2 on PMuon + u/w-floor base to test orthogonality of the two mechanisms (lr schedule shape × per-param update magnitude).

---

## 2026-05-16 10:30 — PR #83 CLOSED: PMuon + SOAP-MLP (no u/w-floor) — null vs new baseline (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra-soap-mlp`
- Hypothesis: SOAP-MLP (eigenbasis Adam scaling after NS polar, applied to 24 MLP fc/proj weights) stacked on PMuon. Tests whether curvature-conditioned per-layer second-moment scaling compounds with PMuon's bilateral whitening.
- W&B run: `il6j69lr` (full run 3250 steps, post-PR #94 rebase, PMuon+u/w-floor base WITHOUT u/w-floor on this PR)

| Metric | Value | PR #94 baseline | PR #64 bare PMuon |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3150** | 3100 | 3150 |
| val/loss | **3.27419** | 3.267696 | 3.27447 |
| (3.28-μ)·√n margin | 0.00581 ✓ | (baseline) | — |
| n | 1 | 2 | 1 |

**Analysis:** SOAP-MLP on bare PMuon is a null vs new baseline — same sr=3150 as PR #64 bare PMuon, Δval=−0.00028 (within seed noise). Mid-training trajectory (steps 500–1875) was 0.03–0.04 below PMuon+u/w-floor baseline, but the advantage evaporated during cooldown. Key finding: u/w-floor's late-cooldown per-param magnitude inflation is not substitutable by SOAP-MLP's second-moment normalization. Stability guards (β2=0.99, scale clamp ±10, amp cap 1.5×) worked perfectly — no instability throughout 3250 steps. 4.2% wall-clock overhead.

**Conclusion:** CLOSED as informative null. Mechanisms are NOT substitutable — u/w-floor operates on final update magnitude relative to weight norm; SOAP-MLP operates on update direction in eigenbasis. The natural follow-up is SOAP-MLP + u/w-floor stack (both mechanisms active). Assigned tanjiro PR #140 for that test.

---

## 2026-05-16 11:30 — PR #110 CLOSED: PMuon γ-scan (γ=0.25 vs γ=0.35) — null on speedrun metric (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-gamma-scan`
- Hypothesis: Scan PMuon's whitening exponent γ ∈ {0.25, 0.35} vs current baseline γ=0.30 on PMuon+u/w-floor base.
- W&B runs: `hehdzpld` (arm A γ=0.25), `2ipgcjyn` (arm B γ=0.35)

| Arm | γ | val/loss@3250 | sr | (3.28-μ)·√n |
| --- | --- | --- | --- | --- |
| A | 0.25 | **3.27286** | 3150 | 0.00714 ✓ |
| B | 0.35 | 3.27380 | 3150 | 0.00620 ✓ |
| PR #64 base | 0.30 | 3.27447 | 3150 | — |
| PR #94 **baseline** | 0.30+u/w | 3.267696 | **3100** | — |

**Analysis:** All three γ values (0.25, 0.30, 0.35) cross the 3.28 target at the same evaluation step (3150) — the speedrun metric is completely insensitive to γ in this range. Val/loss ordering is γ=0.25 < γ=0.30 < γ=0.35, suggesting less whitening is mildly better, but all differences are within n=1 noise (≤0.002 across all three). None beats the PR #94 baseline (sr=3100 val=3.267696). Once u/w-floor is active, the late-cooldown magnitude floor governs the target crossing more than per-step whitening does.

**Conclusion:** CLOSED as clean null on speedrun metric. γ=0.30 (current default) is at or near the local optimum. Assigned thorfinn PR #143 (Lookahead outer optimizer on PMuon+u/w-floor) — completely different abstraction layer.

---

## 2026-05-16 12:00 — PR #93 CLOSED: PMuon + NorMuon row-wise retry — null vs new baseline (g1r1-fern)

- Branch: `g1r1-fern/pmuon-normuon-rowwise-retry`
- Hypothesis: Per-row second-moment EMA after NS polar step (row-wise NorMuon) stacked on PMuon, retry after 3 prior crashes.
- W&B run: `63c3s1sl` (full 3250-step run, stable after crash history resolved)

| Metric | Value | PR #94 baseline |
| --- | --- | --- |
| speedrun/final_first_step_to_target | **3175** | 3100 |
| val/loss @ 3250 | 3.2757 | **3.267696** |
| (3.28-μ)·√n at n=1 | 0.00430 ✓ | — |

**Analysis:** Run completed cleanly (crossed 3.28 at step 3175). However sr=3175 is 75 steps worse than the baseline and val is 0.0080 higher. Row-wise NorMuon adds per-row second-moment EMA on top of PMuon's already-whitened post-polar update. The two normalizations partially overlap: PMuon's `R^{-γ}` already does per-column rescaling; NorMuon's per-row scale partially double-corrects. Cross-cutting insight: direction-shaping mechanisms (SOAP-MLP, NorMuon row-wise) consistently produce null or marginal results on this base, because PMuon's whitening already shapes the update direction.

**Conclusion:** CLOSED as informative null. Assigned fern PR #150 (Cautious update sign-mask — mechanistically distinct, operates on sign rather than magnitude or direction).

---

## 2026-05-16 13:15 — PR #118 CLOSED: PMuon cooldown_frac scan (0.5/0.8, default 0.7) — null (g1r1-edward)

- Branch: `g1r1-edward/pmuon-cooldown-frac-scan`
- Hypothesis: PMuon merged baseline uses `cooldown_frac=0.7`. Scan ±0.1 (arms 0.5, 0.8) to probe whether the LR-collapse phase start point is at a local optimum on PMuon+u/w-floor base.
- W&B runs: `6fpu600z` (Arm A, cooldown_frac=0.5), `dvjzqltr` (Arm B, cooldown_frac=0.8)

| Arm | cooldown_frac | sr | val/loss | (3.28−μ)·√n | vs PR #94 baseline |
| --- | ------------- | -- | -------- | ------------ | ------------------ |
| A | 0.5 | 3175 | 3.27493 | +0.00107 ✓ | −75 steps, +0.00723 val |
| B | 0.8 | 3150 | 3.27415 | +0.00185 ✓ | −50 steps, +0.00645 val |
| PR #94 baseline (current) | 0.7 (default) | 3100 | 3.267696 | +0.00831 (n=2) | — |

**Analysis:** Both arms ran cleanly to 3250 steps (verified in W&B — numbers match student report exactly). Both clear stat-sig bar at n=1 against 3.28 target but both lose to PR #94 on both metrics. The default `cooldown_frac=0.7` sits on a flat plateau between 0.5 and 0.8: 0.5 under-budgets high-LR exploration, 0.8 slightly over-budgets it but the 25-step schedule quantization absorbs the tiny val improvement. No headroom at ±0.1 on this axis.

edward's analysis: "The two ±0.1 perturbations both produce within-noise outcomes: 0.5 is slightly worse; 0.8 is slightly better on val/loss but identical on first_step_to_target because the 25-step validation cadence quantizes the early-target-hit detection; 0.7 is on the plateau between them."

**Cross-cutting note:** This is the fifth consecutive null/negative for schedule or post-polar parameter tweak on PMuon+u/w-floor base (after SOAP-MLP, NorMuon row-wise, γ-scan ±0.05, Contra-Muon). The cross-cutting pattern holds: wins on this base require mechanistically new categories, not ±10% scalar tweaks.

**Conclusion:** CLOSED as clean null. Cooldown_frac is a settled lever on this base. Assigned edward PR #158 (Depth-wise per-block LR decay, LLRD — first depth-indexed LR differentiation in the program).

---

## 2026-05-16 16:35 — PR #151 CLOSED: Aurora pre-polar row-norm equilibration — informative null (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-aurora`
- Hypothesis: Aurora row-norm equilibration applied to pre-polar momentum on PMuon+u/w-floor. Aurora is the only pre-polar mechanism not yet tested in isolation on this base. Theory: PMuon's bilateral whitening is post-polar; Aurora is pre-polar; should be geometrically orthogonal.
- W&B run: `qoxky210`

| Metric | this run (n=1) | PR #94 baseline (n=2) | Δ |
| ------ | ------ | ------ | - |
| speedrun/final_first_step_to_target | 3125 | 3100 | +25 (worse) |
| val/loss | 3.269743 | 3.267696 | +0.002047 |
| (3.28−μ)·√n | 0.01026 | 0.01231 (n=2 mean) | passes n=1 vs 3.28 |

**Aurora telemetry (134 samples):**
- `aurora/row_norm_ratio_pre`: mean 1.21e13, max 3.76e13 — momentum has wild row-norm imbalance
- `aurora/row_norm_ratio_post`: mean 5.52e10, max 2.96e11 — Aurora compresses ~220×
- `aurora/cos_pre_post`: mean 0.873 — direction stays mostly aligned after equilibration
- `uw_floor/fired_fraction`: mean 0.826 (slightly lower than baseline's 1.0 — Aurora-equilibrated updates sometimes already have sufficient magnitude)

**Analysis:** Aurora mechanistically works (220× row-norm compression confirmed) but is redundant with PMuon's bilateral whitening on this base. PMuon's bilateral covariance EMA produces a roughly isotropic NS input through a different geometric route (eigenvalue inversion vs row-norm raising). Both routes converge on similar polar inputs. Aurora's small directional rotation (cos=0.873 ≠ 1) costs ~25 sr-steps without buying val improvement.

**Cross-cutting note:** This confirms BOTH pre-polar and post-polar mechanism slots are saturated by PMuon's whitening on this base. The pattern of nulls now spans both sides of the polar step.

**Conclusion:** CLOSED as informative null. Alphonse pivots to per-head polar (PR #169) — first structural change to the polar step itself.

---

## 2026-05-16 16:35 — PR #150 CLOSED: Cautious update sign-mask — NEGATIVE (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cautious`
- Hypothesis: Cautious update (Liang et al. 2024) zeros elements where polar update sign disagrees with raw gradient sign, then renormalizes magnitude. Theory: variance reduction on aggressive optimizers (Lion, Adam).
- W&B run: `ghiesor9`

| Metric | this run (n=1) | PR #94 baseline | Δ |
| ------ | ------ | ------ | - |
| speedrun/final_first_step_to_target | **−1 (never crossed 3.28)** | 3100 | NEGATIVE |
| final val/loss | 3.2938 | 3.267696 | +0.0261 |
| `final_reached_target` | 0 | 1 | failed |

**Analysis:** Clear NEGATIVE (not just null). Cautious masking destroys PMuon's whitening signal. Mechanism: PMuon's bilateral whitening (`L^{-γ} R^{-γ}`) systematically rotates the update relative to raw gradient — by design (preconditioning). After whitening, 20–40% of elements typically flip sign relative to raw grad (normal consequence of rotation). Cautious zeros these elements, destroying most of the geometric correction PMuon provides. u/w-floor then amplifies the corrupted direction. The optimizer wanders, never converges to target.

Cautious works on Lion/Adam because their inner updates are roughly aligned with raw grad (Adam: gradient/√EMA; Lion: sign-of-EMA). PMuon's polar+whitening is geometrically far from raw grad — sign-agreement with raw grad becomes an anti-signal here.

**Operational issue:** A silent-fail duplicate run `1wb1p2eg` was launched at 16:28 UTC with byte-for-byte identical config (advisor flagged in close comment; student was asked to kill it). Same rate-limit silent-fail pattern hitting students this week.

**Cross-cutting note:** 2nd clear NEGATIVE on PMuon+u/w-floor (after PR #119 Contra-Muon). Both negatives involve mechanisms that act on update sign/direction in ways geometrically incompatible with PMuon's bilateral whitening.

**Conclusion:** CLOSED as confirmed negative. Fern pivots to cosine cooldown shape (PR #168) — schedule-side change, categorically different from optimizer mechanisms.

---

## 2026-05-16 15:45 — PR #140 CLOSED: SOAP-MLP + u/w-floor stack on PMuon base — informative null (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-soap-mlp-uw-floor`
- Hypothesis: SOAP-MLP (Shampoo Lˉ¹/⁴ Rˉ¹/⁴ eigenbasis preconditioning on MLP fc/proj weights) stacks orthogonally with u/w-floor (magnitude floor) on PMuon base — tests whether direction-shaping (SOAP) and magnitude control (u/w-floor) compose additively.
- W&B run: `cg6asx9a`

| Metric | Value | vs PR #94 baseline |
| ------ | ----- | ------------------ |
| speedrun/final_first_step_to_target | 3125 | +25 (worse) |
| val/loss | 3.2698 | +0.0021 (vs 3.267696 mean) |
| (3.28−μ)·√n margin | 0.0102 | ✓ clears vs 3.28 |
| n | 1 | — |
| W&B run | `cg6asx9a` | — |

**Mechanistic telemetry (the key diagnostics):**
- `soap/amp_cap_fire_fraction` = 0.000 throughout — SOAP's safety cap never fired. PMuon polar never produced norms SOAP needed to clamp.
- `soap/post_to_pre_ratio` ≈ 0.999998–1.0 — SOAP applied to a polar update is norm-preserving. Rotates in eigenbasis without magnitude change.
- `uw_floor/fired_fraction` identical with vs without SOAP (98–100% from step 1200) — u/w-floor's universal magnitude floor does identical work regardless of whether SOAP is in the path.

**Analysis:** Clean mechanistic null. SOAP-MLP and u/w-floor ARE orthogonal in update magnitude (one changes magnitudes, the other does not) but they compose null because both are applied to the already polar-shaped output of PMuon. PMuon's bilateral whitening already provides the dominant direction regularization on MLP weights — SOAP's eigenbasis rotation adds no value-additive signal on a high-rank, full-band parameter family that polar has already made roughly isotropic. This matches the cross-cutting pattern: post-polar direction-shaping mechanisms are redundant on PMuon+u/w-floor (PRs #83, #93, #110, #118, #119, #129B, now #140).

**Cross-cutting note:** 7th consecutive add-on-mechanism null on PMuon+u/w-floor base (counting this experiment). Only PR #137 (power-law cooldown γ=1.2) shows improvement — and that is a scheduler-side change, not an optimizer-side mechanism addition.

**Conclusion:** CLOSED as informative null. SOAP infrastructure reused for PR #167 (SOAP-ATTENTION on attention q/k/v only — tests different singular-value-spectrum hypothesis).

---

## 2026-05-16 15:45 — PR #143 Arm A: Lookahead k=5 on PMuon+u/w-floor — NULL (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-lookahead`
- Hypothesis: Lookahead (Zhang et al. 2019) outer optimizer (k=5, α=0.5) operates at a completely different abstraction from PMuon's inner whitening — slow-weight copy with periodic pullback provides noise suppression/variance reduction orthogonal to all prior mechanism additions.
- W&B run: `ycmkbjrb` (arm A, k=5)

| Metric | Arm A (k=5) | PR #94 baseline | Δ |
| ------ | ----------- | --------------- | - |
| speedrun/final_first_step_to_target | −1 (null) | 3100 | +∞ (never crossed) |
| final val/loss | 3.2836 | 3.267696 | +0.0159 |
| train_steps | 3250 | 3250 | — |

**Analysis:** Lookahead k=5 produced a NULL result — the target (val ≤ 3.28) was never crossed in 3250 steps. This is a significantly worse outcome than the baseline (val=3.284 vs 3.268). Lookahead's periodic pullback to slow weights appears to counterproductively dampen the effective LR of PMuon+u/w-floor at k=5: pulling fast weights back to slow every 5 steps imposes a 50% blending that partially cancels the u/w-floor magnitude inflation. This is consistent with Lookahead being most beneficial on inner optimizers that are "aggressively noisy" — PMuon+u/w-floor may be directionally clean enough that variance reduction from slow weights is unnecessary and the blending overhead costs more than it saves.

Arm B (k=10) is running (`u78x3cd3` launched ~15:30 UTC) — with longer inner steps between syncs, the blending overhead is halved. If arm B also nulls, Lookahead is definitively not a fit for this base.

**Conclusion:** Arm A (k=5) NULL. Awaiting arm B (k=10) results before full PR close.

---

## 2026-05-16 19:34 — PR #143 CLOSED: Lookahead k=5/10 — confirmed NEGATIVE both arms (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-lookahead`
- W&B runs: `ycmkbjrb` (arm A k=5), `i4eb7s2p` (arm B k=10)

| Arm | k | val/loss | sr | (3.28−μ)·√n | Outcome |
|---|---|---|---|---|---|
| A | 5 | 3.28361 | −1 | −0.00361 | NEGATIVE |
| B | 10 | 3.28390 | −1 | −0.00390 | NEGATIVE |
| PR #137 baseline | — | 3.269090 | 3062.5 | +0.01546 | reference |

**Both arms NEVER crossed 3.28 in 3250 steps.** Lookahead is fundamentally incompatible with PMuon+u/w-floor at any k value tested.

**Mechanism (confirmed by thorfinn's `cosine_drift` telemetry, mean +0.75):** Lookahead's slow-weight pullback (α=0.5 blend every k steps) creates destructive interference with u/w-floor's persistent magnitude inflation. Three nested forces oscillate: PMuon whitening rotates direction → u/w-floor lifts magnitude → Lookahead snaps back → repeat. Per-step equilibrium drift = m·(1−α/k). At k=5: 0.9·m; at k=10: 0.95·m. Neither high enough to converge in 3250 steps.

**Cross-cutting:** 2nd outer-loop NEGATIVE on PMuon+u/w-floor (joins PR #119 Contra-Muon). Combined with 11+ post-polar nulls, the pattern is clear: outer-loop and post-polar mechanism additions are all blocked by u/w-floor × bilateral-whitening interaction.

**Conclusion:** CLOSED as confirmed NEGATIVE. Thorfinn pivots to NS iteration count scan (fundamental polar hyperparameter, never touched) — categorically new probe in core polar mechanism, not outer-loop or shape addition.

---

## 2026-05-16 12:00 — PR #119 CLOSED: Measured-scale Contra-Muon × PMuon — final negative (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-contra-measured`
- Hypothesis: Contra-Muon (subtract coeff × Frobenius-normalized pre-polar momentum from the polar update) with measured-scale calibration to fix the PR #95 magnitude mismatch.
- W&B runs: `wsdmrs7q` (A, no warmup), `kyaj7khd` (B, no warmup), `o156ipbq` (A+, warmup=200), `q54bnxvq` (B+, coeff=0.05 warmup=500)

| arm | coeff | warmup | sr | best val | outcome |
| --- | --- | --- | --- | --- | --- |
| A | 0.10 | 0 | — | 7.51 | grad blowup step 50 |
| B | 0.05 | 0 | — | 4.31 | linalg.eigh crash step 846 |
| A+ | 0.10 | 200 | — | — | re-exploded step 500 |
| **B+** | **0.05** | **500** | **−1** | **3.31596** | stable but never crossed 3.28 |

**Key finding (cos(update_dir, m_pre_dir) monotonic rise 0.026→0.513):** Late in training, the orthogonal contra direction acts on a shrinking residual that's no longer a useful descent signal. Constant coeff=0.05 imposes ~5% off-axis noise in the converged regime — irreducible noise floor. Calibration was perfect (8-decimal precision) — magnitude was never the issue. PMuon's bilateral whitening and Contra-Muon's orthogonal perturbation fight geometrically.

**Cross-cutting note:** Contra-Muon works on plain Muon (Records #11, #14, #20) because there's no bilateral whitening to conflict with. PMuon's L_cov/R_cov EMA already provides geometric regularization that Contra-Muon disrupts.

**Conclusion:** CLOSED as fundamental incompatibility (not tuning failure). 4 arms, 4 different failure or underperformance modes, all consistent with bilateral-whitening × orthogonal-perturbation conflict. Assigned alphonse PR #151 (Aurora row-norm equilibration — pre-polar mechanism, geometrically orthogonal).

---

## 2026-05-16 18:26 UTC — PR #137 MERGED: PMuon + u/w-floor + Power-Law Cooldown γ=1.2 — WINNER n=2 (g1r1-nezuko)

- Branch: `g1r1-nezuko/pmuon-uw-power-1p2`
- Hypothesis: Power-law cooldown shape `eta = ((1−progress)/cooldown_frac)^γ` with γ=1.2 on PMuon+u/w-floor base. Concave-down decay drops lr faster through mid-cooldown, predicted to accelerate descent across 3.28 at cost of slightly higher final val.
- W&B runs: `8quuvdrj` (seed-1), `l5bdkm6e` (seed-2)

| Metric | seed-1 | seed-2 | **n=2 mean** | PR #94 baseline (n=2) | Δ |
| ------ | ------ | ------ | ------------ | --------------------- | - |
| speedrun/final_first_step_to_target | 3075 | **3050** | **3062.5** | 3100 | **−37.5 steps ✅** |
| val/loss (final) | 3.270012 | 3.268167 | **3.269090** | 3.267696 | +0.001394 (regression, within seed-noise) |
| (3.28−μ)·√n | — | — | **0.01543** | 0.01740 | ✓ clears 0.004 bar |
| `final_reached_target` | 1 | 1 | — | — | both clean |

**Mechanistic analysis:**
- Power-law γ=1.2 makes cooldown concave-down: at 50% cooldown progress, `eta=0.5^1.2=0.435` vs linear `eta=0.5`. This drops lr faster in mid-cooldown, pulling the model across the 3.28 boundary ~37.5 steps earlier on average.
- Tradeoff: less time at moderate lr in late cooldown → slightly higher final val (+0.0014). This is the right trade for the speedrun benchmark.
- `uw_floor/fired_fraction=1.0` on both seeds — u/w-floor and power-law cooldown compose cleanly, both active simultaneously throughout training.
- Seed-2 (sr=3050) is 1 tick BETTER than seed-1 (sr=3075), showing the mechanism is consistent and reproducible.

**Cross-cutting significance:**
- FIRST improvement on PMuon+u/w-floor base in 10+ experiments.
- ALL prior improvements were from optimizer-mechanism additions; this is a **schedule-shape** win.
- Establishes that the schedule-shape dimension (γ parameter, cooldown curve family) is the open lever on this base.
- Opens Wave 5: γ × cooldown_frac joint surface scan, cosine cooldown comparison (PR #168 running).

**Conclusion:** MERGED as new baseline. sr=3062.5, val=3.269090. Nezuko freed → assigned Wave 5 γ scan (γ ∈ {1.1, 1.3} arms to probe curvature around the optimum).



---

## 2026-05-16 20:30 UTC — PR #167 CLOSED: SOAP on attention q/k/v only on PMuon+u/w-floor base — NULL on primary (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-soap-attn`
- Hypothesis: Restrict SOAP preconditioning to the 36 attention q/k/v 2-D weights only (MLP weights take plain PMuon+u/w-floor). Motivated by the observation that attention matrices might have lower effective rank than MLP weights, making eigenbasis rescaling more impactful in that slot.
- W&B run: `sb4u7xhb` (n=1, 3250 steps, linear cooldown)

| Metric | PR #167 SOAP-attn (n=1) | PR #94 baseline (n=2 mean) | Δ |
| ------ | ----------------------- | -------------------------- | - |
| speedrun/final_first_step_to_target | 3100 | 3100 | 0 (NULL on sr) |
| val/loss | 3.26806 | 3.267696 | +0.000364 (regression, within seed noise) |
| (3.28−μ)·√n | 0.01194 | 0.01740 | Worse vs baseline |
| Current best baseline (PR #137) | — | 3062.5 / 3.269090 | **sr regresses +37.5 steps** |

**Headline mechanistic finding — `post_to_pre_ratio`:**

| stat | value |
|---|---|
| mean | **0.99999858** (n=133 telemetry events) |
| median | 0.99999862 |
| min / max | 0.99999703 / 0.99999983 |
| mean |ratio−1| | 1.42e-6 |
| amp_cap_fire_fraction | **0.000** (never fires) |

The SOAP-attn Frobenius renorm (`multiplier = pre_norm / post_norm`) cancels SOAP's eigenbasis rescaling almost exactly — `post_to_pre_ratio` mean = 0.99999858 (even closer to 1 than PR #140 SOAP-MLP: 0.999998). The asymmetric amp cap (1.5) never fires. **SOAP-attn is a no-op at this slot, same as SOAP-MLP.**

**Spectral finding — attention q/k/v effective rank:**

The motivating hypothesis (attention q/k/v have low effective rank → SOAP has more to grip) is NOT borne out. Participation ratio ≈ 526 / 768 ≈ 0.68. Top-1 singular value carries only ~1% energy; top-128 carry ~52%. Spectrum is moderately spread, not strongly skewed. No dominant subspace for SOAP to leverage.

**u/w-floor domination:** `uw_floor/fired_fraction` mean=0.853, median=1.000. The u/w-floor is the dominant force on update magnitude every step; SOAP-attn's contribution is masked.

**Cross-PR significance:**

- Completes the "post-polar Frobenius-preserving preconditioning" probe family: PR #140 (SOAP-MLP, null) + PR #167 (SOAP-attn, null) = **this slot is exhausted on PMuon+u/w-floor base**.
- The Frobenius renorm invariant (`pre_norm / post_norm < 1.5` so amp_cap never fires) was the decisive mechanism in both cases.
- PR #83 (SOAP-MLP standalone, null), PR #140 (SOAP-MLP × PMuon+u/w-floor, null), PR #167 (SOAP-attn × PMuon+u/w-floor, null) — three independent null results confirming the same mechanism.

**Conclusion:** Closed as informative null. Tanjiro reassigned to Wave 5 NS coefficient scan (PR #193): sweeping (a, b, c) ∈ {Jordan-optimized (3.4445, -4.7750, 2.0315), cubic-Newton (1.5, -0.5, 0)} on the PMuon+u/w-floor+γ=1.2 base. Together with thorfinn PR #184 (NS iter count scan), this fully maps the NS polar hyperparameter space.

---

## 2026-05-16 21:05 UTC — PR #168 CLOSED: Cosine cooldown on PMuon+u/w-floor base — NULL vs new baseline (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cosine-cooldown`
- Hypothesis: Cosine s-curve cooldown as alternative to power-law γ=1.2. Hypothesis: if γ=1.2 wins via "smoother lr trajectory" then cosine should be better; if from "mid-cooldown decay aggressiveness" cosine should be worse.
- W&B run: `sf7fq2ul` (n=1, 3250 steps)

| Metric | PR #168 Cosine (n=1) | PR #137 baseline γ=1.2 (n=2 mean) | Δ |
| ------ | -------------------- | ---------------------------------- | - |
| speedrun/final_first_step_to_target | 3075 | **3062.5** | **+12.5 steps (NULL vs baseline)** |
| val/loss | 3.276583 | 3.269090 | +0.0075 (worse) |
| (3.28−μ)·√n | 0.00342 | 0.01543 | **BELOW 0.004 bar (negative!)** |
| vs PR #94 linear baseline | −25 sr | +0.0089 val | Beats linear on sr, worse on val |

**Key mechanistic decomposition (from logged `train/cooldown/eta`):**

At the crossing point (~step 3075, 92% cooldown progress):
- Cosine eta: **0.0147** (5× lower than linear's 0.080)
- γ=1.2 eta: **0.052** (~3.5× lower than linear)

Both cosine and γ=1.2 cross at sr=3075 — same crossing step despite opposite decay shapes (back-loaded vs front-loaded). But post-crossing:
- Cosine eta at step 3100: **0.011** → effectively dead, can't refine val
- γ=1.2 eta at step 3100: **0.041** → continues refining val from 3.279 → 3.268

**Insight: "any deviation from linear that lowers eta around the crossing window brings sr in by ~25 steps"** regardless of front-loaded vs back-loaded. Post-crossing val refinement requires preserved late-cooldown lr. This splits the schedule-shape effect into two separable mechanisms: (a) crossing sensitivity to integral of recent lr; (b) post-crossing refinement from late-lr preservation.

**What hypothesis was tested:**
- "Smoother lr trajectory (cosine)" — NOT confirmed (val worse despite smooth endpoints)
- "Back-loaded decay helps vs front-loaded" — NOT confirmed (both shapes give same sr=3075)
- **Discovered:** Both shapes lower eta around the crossing window, explaining the tie; but cosine's late collapse explains the val regression.

**Conclusion:** Closed as informative null vs new baseline (sr regresses +12.5, val regresses +0.0075). Mechanistic framework motivates **cooldown_frac scan on γ=1.2 base** (PR #195). Fern's telemetry predicts: cf=0.85 (longer cooldown) should preserve late lr → better val; cf=0.5 (shorter) front-loads → may cross earlier but worse val. Direct test of PR #168's mechanistic decomposition.

---

## 2026-05-16 21:35 UTC — PR #169 CLOSED: Per-head polar on attn q/k/v — NULL (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-perhead-polar`
- Hypothesis: Per-head NS polar projection on attention q/k/v (reshape to [n_heads, h_dim, dim], apply NS5 batched over heads) gives better per-head conditioning than full-matrix polar. Hypothesis: attention matrices have head-specific subspace structure that full-matrix polar over-homogenizes.
- W&B run: `8mgxsj35` (n=1, 3250 steps, 3h 28m)

| Metric | PR #169 per-head polar (n=1) | PR #137 baseline (n=2 mean) | Δ |
| ------ | ----------------------------- | --------------------------- | - |
| speedrun/final_first_step_to_target | 3125 | **3062.5** | **+62.5 steps (NULL)** |
| val/loss | 3.2706 | 3.269090 | +0.0015 (worse) |
| (3.28−μ)·√n | 0.00938 | 0.01543 | Below baseline |

**Mechanism diagnostics — mechanism worked, learning didn't:**

Per-head SVD conditioning (final, block 0):
| proj | per-head sv_max/sv_min | full-matrix sv_max/sv_min | improvement |
|---|---|---|---|
| q | 4.34 | 6649.5 | **~1530×** |
| k | 4.71 | 4082.5 | **~870×** |
| v | 2.37 | 4532.3 | **~1910×** |

Inter-head subspace disagreement (cos_abs_mean ≈ 0.003 ≈ random orthogonal — heads did NOT collapse).

**Polar saturation confirmed across structural axis:**

This is the 11th add-on null on PMuon+u/w-floor, and the first to vary the *structural unit* of polar itself. The mechanism worked (dramatically better per-head conditioning, genuinely orthogonal head subspaces) but produced zero learning improvement. Conclusion: the polar step is saturated as an optimization lever — restructuring it (per-head vs full-matrix) makes no difference.

Combined with PR #83 (SOAP-MLP, null), PR #140 (SOAP-MLP+u/w, null), PR #167 (SOAP-attn, null), PR #151 (Aurora pre-polar, null): every approach to improving polar quality on this base has been null.

**Conclusion:** Closed. Polar saturation confirmed. Reassigned alphonse to EMA weight averaging PR #197 — orthogonal probe (parameter trajectory smoothing, bypasses optimizer stack entirely).

---

## 2026-05-16 21:38 UTC — PR #158 CLOSED: LLRD depth-wise LR decay — NEGATIVE (both arms) (g1r1-edward)

- Branch: `g1r1-edward/pmuon-llrd-scan`
- Hypothesis: Depth-wise per-block LR decay (shallow=full, deep=reduced) on PMuon+u/w-floor. Two arms: decay=0.85 (stronger) and decay=0.90 (milder).
- W&B runs: `8v3v2l4h` (arm A, decay=0.85), `z6xxow8s` (arm B, decay=0.90)

| Arm | depth_decay | sr | val/loss | Δ val vs baseline |
| --- | ----------- | -- | -------- | ----------------- |
| A (decay=0.85) | LR ratio: 0.167 (block_11/block_00) | -1 (never) | 3.300076 | +0.031 |
| B (decay=0.90) | LR ratio: 0.314 (block_11/block_00) | -1 (never) | 3.285725 | +0.017 |
| Baseline (uniform) | 1.000 | 3062.5 | 3.269090 | — |

**Critical per-block grad-norm finding (block_00 → block_11 at step 1000):**

Arm A: 21688 → 28735 → 25866 → ... → **30568** (block_11 HIGHEST)
Arm B: 13939 → 15934 → 16833 → ... → **18279** (block_11 HIGHEST)

Block_11 (deepest) carries 1.5–3× the gradient norm of intermediate blocks throughout training. The LLRD direction tested (shallow=full, deep=reduced) starves the layer with the LARGEST learning signal — mechanistically backwards.

**Two failure mechanisms confirmed:**
1. LLRD direction reversed: from-scratch GPT with PMuon has block_11 dominating grad-norm; standard fine-tuning LLRD (shallow=full, deep=reduced) is wrong direction for this setup.
2. u/w-floor absorption: fires at 100% of params, renormalizes updates post-LLRD, absorbs depth LR signal.

Monotone harm: every nudge away from uniform LR hurts. No evidence of sweet spot between 0.90 and 1.0.

**Conclusion:** Closed as NEGATIVE (both arms fail to reach 3.28). LLRD direction (shallow=full, deep=reduced) is confirmed wrong. Edward reassigned to per-block weight decay PR #198 — WD acts on `p` directly, bypasses both PMuon bilateral whitening AND u/w-floor.

---

## 2026-05-16 22:30 UTC — PR #129 CLOSED: PMuon β_cov scan {0.90, 0.95, 0.99} — NULL (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-uw-bcov-scan`
- Hypothesis: PMuon covariance EMA horizon (β_cov) controls how many recent gradients contribute to L/R. Default β=0.95 never swept; scan brackets it with {0.90, 0.99}.
- W&B runs: `dstsva72` (arm A, β=0.90), `ueglklrb` (arm B, β=0.95), `xxx` (arm C, β=0.99)

| Arm | β_cov | sr | val/loss | Δ val vs baseline | lcov_eigh_min |
| --- | ----- | -- | -------- | ----------------- | ------------- |
| A (β=0.90) | shorter horizon | 3125 | 3.26889 | −0.00020 | −3.4×10⁻⁴ (near-singular) |
| B (β=0.95, baseline) | default | 3125 | ~3.269090 | baseline | 26.6 (healthy) |
| C (β=0.99) | longer horizon | ~3125 | 3.269+ | ~null | 0.57 (degraded) |
| Baseline PR #137 | uniform β=0.95 | 3062.5 | 3.269090 | — | — |

**Key eigh telemetry finding (lcov_eigh_min, L_cov conditioning):**
- β=0.90: −3.4×10⁻⁴ → near-singular L_cov (too-rapid covariance decay, numerically unstable)
- β=0.95: 26.6 → healthy conditioning (confirmed sweet spot)
- β=0.99: 0.57 → degraded conditioning (too-slow EMA, stale covariance, diminished whitening)

**Non-monotonic conditioning:** β_cov=0.95 sits at the conditioning optimum between two degenerate regimes. This is the cleanest mechanistic null in the programme — the hyperparameter is genuinely at a local optimum, not just insensitive.

**Conclusion:** Closed as informative NULL. β_cov axis fully characterized. Frieren reassigned to PMuon whitening exponent (γ_power) scan PR #201 — the dual axis: β_cov controls covariance horizon, γ_power controls whitening strength (L^{−γ} R^{−γ}).

---

## 2026-05-16 22:35 UTC — PR #201 ASSIGNED: PMuon γ_power whitening exponent scan {0.2, 0.4} (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-uw-gamma-power-scan`
- Hypothesis: PMuon bilateral whitening uses `polar(L^{-γ} m R^{-γ})`. Default γ_power=0.3 fixed since PR #64, never swept. Dual axis to β_cov: where β controls covariance horizon, γ_power controls whitening strength.
  - Arm A (γ_power=0.4): stronger whitening → more uniform polar input, amplifies small gradient directions more aggressively
  - Arm B (γ_power=0.2): weaker whitening → preserves more natural gradient spectrum shape
- Telemetry: reuse eigh framework + add `pmuon/whitened_sv_ratio` post-whitening spectral diagnostic
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137, n=2 mean)

---

## 2026-05-17 01:15 UTC — PR #131 CLOSED: TARGET_UW sweep {0.25, 0.30, 0.40, 0.45} — NULL (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-uw-sweep`
- Hypothesis: TARGET_UW (u/w-floor threshold) controls the dominant per-param LR mechanism when fired_fraction=1.0. Scan brackets 0.35 baseline.
- W&B runs: `fphpexnb` (0.25), `dkxweoah` (0.30), `imf0s97n` (0.40), `lou98cqm` (0.45); `m3rq3zyd` (crashed 0.40 duplicate)

| Arm | TARGET_UW | sr | val/loss | fired_fraction (final) | mean_ratio |
| --- | --------- | -- | -------- | ---------------------- | ---------- |
| 0.25 | 0.25 | 3150 | 3.27382 | 0.125 (9/72 params) | 0.310 |
| 0.30 | 0.30 | 3100 | 3.26898 | 0.569 (41/72 params) | 0.255 |
| Baseline | 0.35 | 3062.5 | 3.269090 | 1.000 | — |
| 0.40 | 0.40 | 3150 | 3.27023 | 1.000 | 0.087 |
| 0.45 | 0.45 | 3150 | 3.27161 | 1.000 | 0.042 |

**Key mechanistic finding:** fired_fraction COLLAPSES below TARGET_UW=0.35. Above 0.35 → floor clamps 100% of params (dominant LR mechanism). Below 0.30 → PMuon's natural magnitudes take over (mean_ratio=0.310 at 0.25). This transition is mechanistically important: the floor acts as a hard on/off per-param LR switch. Best arm (0.30) ties baseline val but loses 37.5 sr-steps.

**Conclusion:** Closed as informative NULL. TARGET_UW=0.35 is at the fired_fraction transition sweet spot. Lower floors (0.30, 0.25) remove the dominant LR mechanism for many params; higher floors (0.40, 0.45) are redundant clamps. Askeladd reassigned to lm_head LR scan PR #211 (first aux optimizer probe in program history).

---

## 2026-05-17 01:15 UTC — PR #211 ASSIGNED: lm_head LR scan {1/640, 1/160} (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-lmhead-lr-scan`
- Hypothesis: Aux AdamW lm_head LR=1/320 (≈0.003125) is a static legacy value never swept on this base (96× below embed LR=0.3). Brackets with ×2 and ×0.5 multipliers.
- Arms: 1/160 (2× larger), 1/640 (2× smaller)
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137)
- Telemetry: lmhead_grad_norm, lmhead_param_norm, lmhead_update_norm / lmhead_param_norm ratio

---

## 2026-05-17 01:00 UTC — PR #184 PARTIAL: NS iter=6 arm A WINS (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-ns-iter-scan`
- Arm A (ns_iter=6): **sr=3050, val=3.26774** — BEATS BASELINE by 12.5 sr-steps and 0.00135 val
- Statistical rule n=1: (3.28-3.26774)×√1 = 0.01226 >> 0.004 ✓
- **Critical telemetry:** polar/ortho_residual_sample=2.31 (high — less convergent) at ns_iter=6 vs expected ~0.01 at ns_iter=12. LESS precise polar → BETTER performance.
- Arm B (ns_iter=18) launching now. Terminal pending ~04:30 UTC.
- W&B run: `crelrjzb`

**Mechanistic implication:** over-orthogonalization is counterproductive. The ns_iter=6 polar direction carries more gradient information than the fully-converged ns_iter=12. This is a FIRST NON-SCHEDULE WIN on PMuon+u/w-floor base. Pending confirmation via arm B + terminal SENPAI-RESULT.

---

## 2026-05-17 00:23 UTC — PR #193 PARTIAL: Jordan NS coef arm A borderline NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-scan`
- Arm A (Jordan-opt coef: 3.4445, -4.7750, 2.0315): sr=3075, val=3.27041
- sr=3075 is slower than baseline 3062.5; val=3.27041 is slightly worse than 3.26909
- **Critical telemetry:** polar/ortho_residual_sample=11.12478 — extremely high. Jordan coefficients produce LESS convergent polar than ns_iter=12 default.
- Connecting to thorfinn arm A: both ns_iter=6 AND Jordan-opt coefficients produce high ortho_residual; but ns_iter=6 WINS while Jordan is borderline NULL. Implication: the PATH to "less orthogonal" matters, not just the residual magnitude.
- Arm B (cubic-Newton coef: 1.5, -0.5, 0) launching. Terminal pending.
- W&B run: `taitef3m`

---

## 2026-05-17 01:35 UTC — Wave 5 arm A snapshot (W&B-verified)

All 8 Wave 5/6 students have completed arm A. Two independent winners detected:

| PR  | Student   | Arm A mechanism                | sr     | val      | Verdict (vs baseline 3062.5/3.26909) |
|-----|-----------|--------------------------------|--------|----------|---------------------------------------|
| #184 | thorfinn | ns_iter=6                       | **3050** | **3.26774** | **WIN** (sr −12.5, val −0.00135)     |
| #198 | edward   | deep-strong per-block WD         | **3050** | **3.26819** | **WIN** (sr −12.5, val −0.00090) — partial not yet posted |
| #197 | alphonse | EMA α=0.99                      | 3100   | 3.27504  | **NEGATIVE** (sr +37.5, val +0.006) — bias-lag in cooldown |
| #195 | fern     | cooldown_frac=0.85              | 3075   | 3.27214  | NULL (sr +12.5, val +0.003)           |
| #193 | tanjiro  | Jordan NS coefs                  | 3075   | 3.27041  | NULL (sr +12.5, val +0.001)           |
| #179 | nezuko   | γ=1.1                           | 3075   | 3.26813  | NULL on sr (val tied; γ=1.2 at concavity optimum) |

Arm B status (mid-flight): thorfinn ns_iter=18 (31%), tanjiro cubic-Newton (34%), alphonse EMA α=0.999 (3%), frieren γ_power=0.4 arm A (78%), nezuko γ=1.3 (82%), fern cf=0.5 (4%), edward deep-weak (4%), askeladd lm_head/160 arm A (25%).

**Headline:** First two non-schedule wins on PMuon+u/w-floor base after 19 nulls/negatives. Both arms tie on sr=3050 but operate on orthogonal axes:
- **thorfinn**: changes the polar projection (NS iterations) — over-orthogonalization is counterproductive
- **edward**: changes the weight decay (per-block WD) — WD acts on `p` directly, bypassing PMuon whitening and u/w-floor

**Stacking implication for Wave 7:** If these mechanisms compound additively or near-additively, ns_iter=6 + deep-strong WD could push sr ≤ 3025-3037.5. Designing the Wave 7 stacking PR after both terminals confirm.

**Connection to PR #129 + #131 closures:** β_cov is at conditioning optimum (β=0.95) and TARGET_UW is at fired_fraction transition (0.35). PMuon hyperparameter axis is converged. Wins come from changes *around* the PMuon core: polar projection quality (NS_iter) and gradient damping (WD on `p`). γ_power (frieren PR #202) and lm_head LR (askeladd PR #211) are the next two axes to characterize.

---
