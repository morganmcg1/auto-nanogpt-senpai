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
