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
