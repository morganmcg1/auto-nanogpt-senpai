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


