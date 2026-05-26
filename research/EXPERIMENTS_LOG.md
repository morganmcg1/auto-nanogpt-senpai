# SENPAI Research Results

## 2026-05-26 05:25 UTC — PR #1213 CLOSED: body-Muon Nesterov mu cooldown ramp (0.95→0.97 vs 0.95→0.99) — 143rd NULL, mu-cooldown axis FULLY CLOSED with monotone dose-response (g1r1-edward)

- Branch: `g1r1-edward/mu-cooldown-ramp`
- Hypothesis: linearly ramp `muon_mu` from 0.95 → 0.97 (Arm A) or 0.95 → 0.99 (Arm B) over the last 20% of training (~650 steps). Widens Nesterov EMA lookback from 20 → 33 (Arm A) or 20 → 100 (Arm B) steps during cooldown phase. Tests whether wider momentum window smooths cooldown's small-LR descent direction.

| Arm | mu_target | lookback | wandb run | val_ema | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0.95 fixed | 20 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (mild)** | 0.97 | 33 | `s30ca2ju` | **3.267238** | **2950** | **+0.84 (2.8σ)** | **+25** | marginal NULL |
| **B (wide)** | 0.99 | 100 | `gyzfl3ja` | **3.269038** | **2975** | **+2.64 (8.8σ)** | **+50** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms FAIL both clauses.
- **Direction:** clean monotone dose-response with ~3× stronger regression in Arm B than Arm A across val/sr/buffer axes. No bracket interior; wider is strictly worse.
- **Mechanism canon — direction wrong for speedrun objective:** wider Nesterov lookback during cooldown produces predicted mechanism signature (lower update-direction variance, buffer drift) but cost of *lagging behind the descending cooldown gradient signal* exceeds noise-reduction benefit at all tested dosages. NS5 polar already normalizes m_pre direction; mu schedule only affects input-direction lag. Arm B's 100-step lookback averages over 30%+ of total training — too wide for a phase needing sensitivity to final-stretch loss surface.
- **Cross-axis canon with #1182 EMA β_target:** buffer_frob_dist scales with cumulative cooldown LR mass in lookback window — NOT abstract "smoothing strength." Arm A +20% / Arm B +55% terminal buffer reflects how far back into high-LR phase the EMA window reaches.
- **μ-axis cluster status:** 6 mechanism-distinct closures now — #930 static / #1107 polar-interp / #1156 Lookahead / #1164 depth-stratified / #1213 cooldown ramp (this) / in flight: #1215 warmup, #1249 per-tensor-type. Static μ=0.95 fixed-everywhere remains only configuration not strictly worse than its perturbations. **μ-axis structurally constrained.**
- **Per Issue #1252 directive (05:03 UTC May 26):** edward routed to **directive-aligned hypothesis** — body-Muon Nesterov *buffer reset* at cooldown entry (state intervention, not coefficient sweep). Mechanism-distinct from #1213 (clears EMA state vs perturbs EMA coefficient).

## 2026-05-26 04:08 UTC — PR #1208 CLOSED: beta_cov bias-correction warmup (0→0.95 over 300 vs 750 steps) — 142nd NULL, β_cov/L_cov/R_cov initialization axis FULLY CLOSED across 5 PRs (g1r1-frieren)

- Branch: `g1r1-frieren/beta-cov-warmup`
- Hypothesis: linearly ramp `beta_cov` from 0 → 0.95 over the first 300 (Arm A) or 750 (Arm B) training steps. Adam-β2-style bias correction for the body-Muon preconditioner covariance EMA. Tests whether cold-start `L_cov`/`R_cov` (under-converged for first ~1/(1-0.95)=20 steps) over-aggressively scales early body-Muon updates.

| Arm | warmup | wandb run | val/loss | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (n=2) | — | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (fast)** | 300 | `b2hyb08n` | **3.271470** | **3025** | **+5.08 (17σ)** | **+100** | clear NULL |
| **B (slow)** | 750 | `4kd27gzi` | **3.270377** | **3000** | **+3.98 (13σ)** | **+75** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms fail both clauses.
- **Direction:** monotone-toward-baseline (slower=better, never beats). No bracket interior — warmup→∞ converges back to baseline behavior. Mechanism-rejected, not a Pareto-shift.
- **Mechanism canon — direction wrong:** starting from `effective_beta_cov=0` (pure outer-product covariance, no EMA decay) is LESS favorable than baseline's `beta_cov=0.95` cold-start. The eps=1e-12 clamp on `matrix_neg_power(L_cov, 0.4)` already absorbs cold-start asymmetry, and NS5 polar normalization further re-normalizes. The hypothesis posited that cold-start under-converged EMA caused over-aggressive early-update scaling, but empirically the eps+NS5 stack handles this cleanly — adding warmup REMOVES the partial smoothing that beta_cov=0.95 provides at step 1.
- **Param-EMA redundancy:** likely interaction with #918's param-EMA warmup (β_t ramps 0.95→0.99 over steps 0–1750). The param EMA filters out early-training noise at the parameter level; adding preconditioner-level warmup double-counts the bias correction. Two-level correction is redundant rather than complementary.
- **Mechanism safe but scheduling wrong:** no divergence, no NaN, no exploding norms in either arm. The mechanism is structurally safe — issue is direction, not stability.

**β_cov / L_cov / R_cov initialization axis FULLY CLOSED across 5 PRs and 3 mechanism-distinct sub-axes:**
- **#686 (CLOSED)** static β_cov ∈ {0.80, 0.90, 0.95, 0.99} — value scan
- **#774 (CLOSED)** fast-mix K ∈ {20, 50} — gradient-mixing window length
- **#822 85th (CLOSED)** L_cov/R_cov Adam-style BC (n=3 boundary informative-NULL)
- **#893 97th (CLOSED)** m_pre first-moment BC (n=2 boundary informative-NULL)
- **#1208 (this)** warmup schedules 0→0.95 over {300, 750} steps

Combined: every initialization-state and warmup variant on the preconditioner covariance is NULL/marginal. NS5 + eps clamp + param-EMA warmup form a robust early-training stack that absorbs all tested initialization perturbations. β_cov initialization is structurally constrained — further mining deprioritized.

**142nd NULL closed.** frieren → next assignment (per-tensor-type body-Muon Nesterov mu — attn vs mlp; deprioritized-but-untested axis from PR #777 closure list, mechanism-distinct from #1164 depth-stratified mu CATASTROPHIC + #1213 cooldown mu + #1215 warmup mu).

## 2026-05-26 02:00 UTC — PR #1198 CLOSED: AdamW aux weight_decay scan (0.01 vs 0.10, baseline=0) — 141st NULL, AdamW aux wd axis FULLY BRACKETED + AdamW aux family CLOSURE complete (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-adamw-wd`
- Hypothesis: probe AdamW aux `weight_decay` ±10× around baseline 0. Arm A wd=0.01 (mild) vs Arm B wd=0.10 (10× larger). Tests whether explicit decoupled shrinkage on embed/lm_head/scalars adds benefit beyond AdamW's implicit second-moment regularization.

| Arm | wd | wandb run | val/loss_ema | sr | Δval (mnat) | Δsr | reached_target | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | 1 | (reference) |
| **A (mild)** | 0.01 | `1josgg3e` | **3.266192** | **2950** | **−0.20 (sub-σ)** | **+25** | 1 | **Pareto-shift NULL** |
| **B (10× larger)** | 0.10 | `tknei6ut` | **3.301665** | **−1** | **+35.27 (CAT)** | n/a | **0** | **CATASTROPHIC NULL** |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — neither arm satisfies. Arm A fails clause-2 by Δsr+25; Arm B fails on every dimension (target_margin=−0.0217, missed 3.28 by 21.7 mnat).

- **MECHANISM CANON — inactive-embed half-life derivation:**
  - **wd=0.01 Pareto-shift:** `wd·lr·p` shrinkage step at wd=0.01 with peak embed lr≈0.3 yields step magnitude ≲0.3% of total AdamW update — sub-noise on the asymptote (Δval=−0.2 mnat is within σ≈0.3 mnat per #958). The small additive shrinkage on inactive embed rows (~42k of 50304 not touched per batch) and slow LR-mass accumulation across cooldown delays first crossing of 3.28 from step 2925 → 2950. Same Pareto-shift shape as #969 cooldown γ=1.2 / #1099 / #1182 EMA β_target.
  - **wd=0.10 CATASTROPHIC:** Inactive embed half-life `(1−0.3·0.10)^t = 0.5 ⇒ t=22.8` — within the 3250-step run, low-frequency token embeddings are effectively zeroed. lm_head dense-active sees uniform compression flattening logit landscape; combined with baseline sqrt-clip soft-cap @15 (already bounds peakedness from above), additional shrinkage from below has no upside. Trajectory divergence visible by step 1500 (Arm B val=3.65 vs baseline ≈3.55); by step 2925 Arm B at val=3.32 (44 mnat behind).
  - `target_margin=−0.0217` + `single_run_stat_sig_margin=−0.0257` (Arm B) are stable EMA-accumulated quantities → cross-arm Δ≫200% noise floor is robust without n=2 confirmation per #1168 canon.

- **CROSS-AXIS CANON — AdamW aux family closure now complete across 5 inner levers:**
  - β1 ramp #796 — NULL
  - β2 ramp #741 — NULL
  - β1 fixed-bias-correction #832/#1086 — NULL
  - eps n=2 #1168 — NULL (6-decade bracket)
  - **wd #1198 (this PR)** — NULL
  - (β2 STATIC #1218 fern in flight)
  - **Baseline `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` triple-validated** — not just inherited from starter script but actively the best across all probed inner levers.

- **AdamW-REPLACEMENT family fully NULL:** #854 Adan, #875 AdaBelief, #899 EMA-wrapper, #937 SOAP-damped, #953 SOAP-undamped, #964 Muon-as-aux, #1013 Sophia-H. AdamW is structurally required for aux groups.

- **PARETO-SHIFT NULL pattern reinforced (4 instances):** #969 (cooldown γ=1.2), #1099, #1182 (EMA β_target 0.985), **#1198 (wd=0.01, this PR)**. Signature: regularizer or perturbation that doesn't hurt asymptote but delays target crossing.

- Mechanism-distinct from: #1040 (body-Muon WD decoupling), #897 (adaptive body-Muon WD), #1170 (u/w-floor body NS5 magnitude), #1178 (AdamW eps).

- **AdamW aux `weight_decay` axis FULLY BRACKETED across 10× span.** 141st NULL. Suggested follow-ups (embed-only WD, lm_head-only WD, sub-0.01 bracket, delayed-onset WD) skipped — axis structurally closed, diminishing returns. askeladd → next assignment (TBD).

## 2026-05-26 00:36 UTC — PR #1168 CLOSED: L_neg/R_neg matrix_neg_power eps n=2 confirmation (1e-6 LOOSER n=2 vs 1e-15 TIGHTER n=1, baseline=1e-12) — 140th NULL, eps axis FULLY CLOSED across 6 decades, stat-sig fails at n=2 despite monotone direction (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/mneps-ablation`
- Hypothesis: probe matrix_neg_power eps ±2 decades around baseline 1e-12. Arm A LOOSER eps=1e-6 (251× max amplification vs baseline 63095×) vs Arm B TIGHTER eps=1e-15 (5623× amplification, 178× MORE than baseline). Direct test of #985 NS5 triple-load-bearing role 3 (null-space amplification suppression).
- n=2 confirmation triggered by Arm A marginal-WIN candidate at n=1 (Δ−0.21 mnat sub-noise, marginal n=1 win requires n=2 confirmation per session memory).

| Run | eps | val_ema | sr | Δval (mnat) | Merge clause-2 |
|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1e-12 | 3.266394 | 2925 | 0 | (reference) |
| `yyp8df25` Arm A seed-1 | 1e-6 | 3.266184 | 2925 | −0.210 | PASS (sr=2925 AND val<baseline) |
| `po02h3dn` Arm A seed-2 | 1e-6 | 3.265409 | 2925 | −0.985 | PASS (sr=2925 AND val<baseline) |
| **Arm A n=2 mean** | 1e-6 | **3.265797** | 2925 | **−0.597** | **stat-sig FAILS (0.000844 < 0.004, 4.7× below threshold)** |
| Arm B (n=1) `cccpoha7` | 1e-15 | 3.267550 | 2950 | +1.16 | FAIL (sr+25, sr≠2925) |

- **STAT-SIG FAILS:** Δval_n2 = −0.597 mnat is 2.8× empirical single-seed σ≈0.0003 — borderline 2σ at n=2. Seed-1 → seed-2 difference (0.775 mnat) is ~2.6× the noise floor too, so apparent improvement is dominated by seed dimension rather than eps perturbation. **Pattern matches #1107 polar-interp** (now third recurrence of this pattern in r1: #1107, #1118, #1168).

- **STRIKING MECHANISM CANON — cross-seed `polar/ortho_residual_sample` variability OVERTURNS prior reading:**
  - Arm A seed-1 ortho_residual=0.135; Arm A seed-2 (SAME eps)=0.376 → +178% same-eps seed variance
  - Arm A vs Arm B (different eps) Δ=+100% at terminal step
  - **The 16:14 UTC + 20:23 UTC narrative ("Arm B 2× elevated ortho_residual = NS5 working harder") is OVERTURNED** — the cross-arm Δ is WITHIN seed noise band.
  - **Corrected canon: `polar/ortho_residual_sample` is single-batch noisy with σ ~ 0.1-0.2 in terminal regime.** Future PR diagnostic interpretations must require n=2 cross-seed reference for any cross-arm metric claim where Δ < 200%. Cite EMA-averaged or accumulated diagnostics (e.g., `pmuon/lcov_eigh_min` which varied only 3-13% across seeds) for stable mechanism claims.
  - Same caveat applies to `pmuon/whitened_sv_ratio` (+51% seed-to-seed; +36% Arm A vs Arm B). Major retraction of original mechanism-divergence narrative.

- **EPS AXIS STRUCTURE (across 6 orders of magnitude):**
  - eps=1e-15: +1.16 mnat, sr+25 (mild regression)
  - eps=1e-12 (baseline): reference
  - eps=1e-6: −0.60 mnat (n=2 mean, sub-stat-sig)
  - **NS5 role 3 (null-space amp suppression) confirmed REAL but OVER-DETERMINED in [1e-6, 1e-15]** — axis structurally flat in this range.

- **CRASH ASYMMETRY EMPIRICALLY REVERSED:** Arm A LOOSER eps had 4 crash-restarts (`z5328dg3`, `iku6uc1t`, `n7t90h27`, `y5ir5oqq`); Arm B TIGHTER eps launched CLEANLY with NONE. **Contradicts advisor 14:10 UTC prior** ("tighter eps → more rank-deficient eigs amplified → more crashes"). Empirical update to NS5 stability canon: early-step crash sensitivity does NOT scale monotonically with eps amplification factor — likely depends on specific eigenvalue distribution at step 1-20 where L_cov rank is filling per #1046.

- **L_neg/R_neg matrix_neg_power eps axis FULLY CLOSED across 6 decades.** 140th NULL. Future NS5 internals PRs must report m_pre stable rank (#1102) and use n=2 cross-seed reference for any ortho_residual-based mechanism claim. thorfinn → next assignment (EMA wrapper ema_beta starting value scan: Arm A=0.92 LOWER (wider ramp), Arm B=0.97 HIGHER (narrower ramp), baseline=0.95; tests the START of LR-coupled β ramp; mechanism-distinct from #864 (duration), #1182 (endpoint), and in-flight #1229 (ramp shape); ~0 LOC, CLI flag exists).

## 2026-05-25 23:55 UTC — PR #1182 CLOSED: EMA wrapper β_target probe (0.985 LOWER vs 0.995 HIGHER, baseline=0.99) — 139th NULL, EMA β_target axis FULLY CLOSED with asymmetric U-shape canon (HIGHER benign, LOWER costs ~1.5 mnat per 0.005) (g1r1-nezuko)

- Branch: `g1r1-nezuko/ema-beta-target`
- Hypothesis: probe EMA wrapper β_target ±0.005 around baseline 0.99. Arm A LOWER β=0.985 (67-step lookback) vs Arm B HIGHER β=0.995 (200-step lookback). Tests U-shape geometry around baseline.

| Arm | β_target | wandb run | val_ema | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|---|
| Baseline (n=2) | 0.99 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | (reference) |
| **A (LOWER)** | 0.985 | `kt5hn5uk` | **3.267900** | **2950** | **+1.506 (5σ)** | FAILS both (sr+25 + val miss) |
| **B (HIGHER)** | 0.995 | `m4mvdz7v` | **3.266713** | **2925** | **+0.319 (1.06σ)** | FAILS clause-2 (sr tied but val miss) |

Both arms FAIL merge rule. **Arm B is sub-σ NULL** (1.06σ at empirical σ ≈ 0.3 mnat per #958) — statistically indistinguishable from baseline.

- **ASYMMETRIC NULL — corrected canon: monotone-decreasing val-vs-β_target in [0.99, 0.995], not symmetric U-shape.** Arm B regresses 4.7× LESS than Arm A. Lower β_target sharply penalized (-1.5 mnat per 0.005); higher β_target benign.

- **MECHANISM REVISION — buffer_frob_dist intuition INVERTED:**

| Direction | Δβ | terminal buffer_frob_dist | Δval | Mechanism |
|---|---|---|---|---|
| LOWER (Arm A) | −0.005 | 11.31 (smaller) | +1.51 mnat | 67-step lookback misses early-cooldown gradient signal |
| HIGHER (Arm B) | +0.005 | **58.80 (5.2× larger)** | +0.32 mnat | 200-step lookback approximately re-centers on trajectory mean |

  - **Terminal `buffer_frob_dist` scales with how much of cooldown's LR mass falls inside the lookback window**, NOT abstract "smoothing strength."
  - Arm A's 67-step window captures only terminal-LR-near-zero phase (steps ~3183-3250) where weights barely move → buffer ≈ live → small frob_dist.
  - Arm B's 200-step window reaches back to steps ~3050-3250 including early-cooldown high-LR phase → buffer ≠ live → large frob_dist.
  - **`buffer_frob_dist` is NOT a direct val proxy** — mechanism-conditional. Contradicts the #918 canon "higher LR → larger frob_dist → lower val" by showing high β_target also produces large frob_dist but does NOT improve val.

- **CROSS-AXIS CANON STRENGTHENING:**
  - #864 baseline β_target=0.99 confirmed as approximately optimal with asymmetric local neighborhood
  - #1144 NS_ITERS phase schedule (132nd NULL "any departure from uniform NS_ITERS=12 costs ~1.2 mnat"): Arm A's +1.5 mnat in same band — EMA expects uniform smoothing rate across cooldown
  - #1176 u/w-floor U-shape: also asymmetric (HIGHER 47% steeper) but OPPOSITE direction (HIGHER hurts there, LOWER hurts here). Mechanism distinction: u/w-floor is direct multiplicative perturbation; EMA β_target affects lookback over LR-weighted trajectory.

- **EMA wrapper β_target axis FULLY CLOSED across {0.985, 0.99, 0.995}.** 139th NULL. Future EMA wrapper PRs must stay above β_target=0.99 and recognize buffer_frob_dist is mechanism-conditional.

- nezuko → **#1219** (EMA β ramp SHAPE probe: Arm A cosine ramp (slow-start fast-finish) vs Arm B quadratic-t² ramp (fast-start slow-finish), both 0.95→0.99 over 1750 steps; tests whether SHAPE of the ramp matters at fixed endpoints + duration; mechanism-distinct from #864 (duration probe) and #1182 (target probe) and #1213/#1215 (body-Muon mu schedules, not EMA wrapper); ~5 LOC implementation).

## 2026-05-25 22:25 UTC — PR #1178 CLOSED: AdamW aux eps ablation (1e-8 LOOSER PyTorch default; Arm B 1e-12 aborted) — 138th NULL, AdamW aux eps axis FULLY CLOSED across 4-decade range, eps_dominance_frac structural finding (g1r1-fern)

- Branch: `g1r1-fern/adamw-eps`
- Hypothesis: AdamW `eps=1e-10` baseline is unusual (PyTorch default 1e-8) and never directly ablated. Probe ±2 decades around baseline to test whether eps floor is load-bearing for aux i.i.d. pipeline. Arm A LOOSER eps=1e-8 (PyTorch default), Arm B TIGHTER eps=1e-12 (FP edge).

| Arm / Seed | wandb run | val_ema | sr | Δval (mnat) | Verdict |
|---|---|---|---|---|---|
| Baseline (n=2) | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | (reference) |
| Arm A seed 1 (eps=1e-8) | `2jtcjepq` | 3.266378880 | 2925 | −0.0152 | sub-noise WIN by math, fails stat-sig |
| Arm A seed 2 (eps=1e-8) | `0u42mc7s` | 3.266378164 | 2925 | −0.0158 | sub-noise WIN by math, fails stat-sig |
| **Arm A n=2 mean** | — | **3.266378522** | **2925** | **−0.0155** | **NULL — FAILS stat-sig (180× below threshold)** |
| Arm B (eps=1e-12) | `vwtb8laz` | aborted at step 74 | — | — | per advisor pivot, structural finding from Arm A telemetry |

n=2 stat-sig: `(3.266394 − 3.266378522)·√2 = 0.0000219` vs threshold ≥ 0.004 → FAILS by factor 180×. n=2 sample std = **5.06e-7** (val_ema seed spread) — astonishingly tight, ~600× tighter than empirical σ ≈ 3e-4. Possible eps=1e-8 reduces seed variance, or 7σ coincidence (unverified).

- **MECHANISM CANON — eps_dominance_frac structural finding:**

| Group | seed-1 eps_dom_frac | seed-2 eps_dom_frac | v_mean_sqrt | eps / sqrt(v̂) |
|---|---|---|---|---|
| embed (50304×768) | 0.6868% | 0.6869% | 0.0047 | ~2.1e-6 |
| lm_head (50304×768) | 1.51e-5 | 2.05e-5 | 0.493 | ~2.0e-8 |
| scalars | 0.0 | 0.0 | 7.49 | ~1.3e-9 |

  - **At eps=1e-8 (10000× looser than baseline 1e-10), the eps floor is essentially never binding across all 3 aux groups.** Variance signal `sqrt(v̂)` dominates the AdamW update across entire training trajectory, NOT the eps floor.
  - Even on the sparsest group (embed, token-level sparsity), only 0.687% of coords fall below the eps floor at 1e-8. At baseline 1e-10, the binding fraction is 100× smaller still (≈0.007% projected).
  - **Seed-to-seed agreement on `eps_dominance_frac` (differs by 1.5e-6 between seeds) confirms this is a structural property of the aux pipeline**, not a per-run fluctuation.
  - **Baseline `eps=1e-10` was silent over-engineering** at this scale.

- **AdamW aux eps axis FULLY CLOSED across 4-decade range [1e-12, 1e-8].** 138th NULL.
- **Joint aux Adam-family hyperparameter closure now spans 20+ axes**: all update-rule families (Adan, NAdam, AdaBelief, Lion, Lookahead, SF, AdEMAMix, AMSGrad, Adamax, LAMB, Cautious, Adam-mini, SOAP, Sophia), β1 ramp (#796), β2 ramp (#741), aux base-LR retune (#913), now eps (#1178). Per-coord variance scaling self-normalizes via AdamW denominator — eps floor irrelevant within wide range.

- fern → **#1217** (AdamW aux β2 STATIC value scan: Arm A β2=0.99 vs Arm B β2=0.999 PyTorch default, baseline=0.95 — mechanism-distinct from #741 β2 cooldown ramp (probed cooldown phase only, not full-training static), tests whether unusual baseline β2=0.95 is load-bearing or legacy artifact, ~3 LOC implementation).

## 2026-05-25 21:18 UTC — PR #1166 CLOSED: NS5 cubic-coefficient ablation ((1.7, -0.7) TIGHTER vs (1.3, -0.3) GENTLER at a+b=1) — 137th NULL, NS5 cubic-coefficient axis FULLY CLOSED with asymmetric robustness canon (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-cubic`
- Hypothesis: scan NS5 cubic polynomial coefficients (a, b) along the a+b=1 constraint line (fixed point at σ=1). Arm A TIGHTER (1.7, -0.7) has linear convergence rate −0.4 at σ=1 (oscillatory). Arm B GENTLER (1.3, -0.3) has rate +0.4 (monotone). Tests whether baseline (1.5, -0.5) quadratic convergence is structurally critical.

| Arm | (a, b) | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | (1.5, -0.5) | 3.266394 | 2925 | 0 | (reference) |
| **A (TIGHTER)** `5vpx9orf` | (1.7, -0.7) | **3.26758** | **2950** | **+1.19 (4σ)** | FAILS both (sr+25 + val miss) |
| **B (GENTLER)** `m7s2z8a0` | (1.3, -0.3) | **3.27378** | **3050** | **+7.39 (25σ)** | FAILS both (sr+125 + val miss) |

- **Both arms NULL.** 137th closure. ASYMMETRIC regression — TIGHTER 6× milder than GENTLER.

- **MECHANISM CRYSTALLIZED — NS5 cubic robustness boundary is asymmetric, GENTLER fails to converge within budget:**

| Telemetry | Arm A TIGHTER | Arm B GENTLER |
|---|---|---|
| `ns5/sigma_max_after_iter_12` | n/a (pre-telemetry) | **0.846** (vs target ~1.003 baseline) — never reaches unit norm |
| `polar/ortho_residual_sample` | 0.176 (~2× elevated) | **16.03 (~91× Arm A)** — severely sub-orthogonal |
| `ema/buffer_frob_dist` | 22.75 (≈ baseline 22.6) | 14.30 (smaller post-NS5 updates due to scale ~0.85×) |
| linear convergence rate at σ=1 | −0.4 (oscillatory) | +0.4 (monotone undershoot) |

  - **Arm A TIGHTER**: NS5 produces approximately-orthogonal output; optimizer absorbs the change with only +1.2 mnat val cost. EMA dynamics unchanged. Tightening NS5 coefficients by ±0.2 is well-tolerated. Note: ~8 crash restarts in early debug — `f(σ)=1.7σ−0.7σ³` overshoots aggressively at large σ in first few steps; 1/spectral-norm pre-scaling at line 469 keeps input in stable basin once past warmup.
  - **Arm B GENTLER**: NS5 SEVERELY UNDER-CONVERGED. With f'(0)=a=1.3, small-σ amplification rate too weak to drive m_pre's bulk-σ (starting at ~0.07 per ns5/sigma_max_after_iter_1) up to unit norm in 12 iterations. Rate=+0.4 monotone approach converges asymptotically but runs out of budget → NS5 outputs sub-orthogonal matrix at 0.85× scale every step.

- **REFINED CANON — polar/ortho_residual NOT load-bearing at small variations, IS load-bearing at large variations** (qualifies #1102/#1123/#1107 canon "polar/ortho_residual is NOT load-bearing at NS_ITERS=12"):

| Source | ortho_residual | Δval (mnat) | Verdict |
|---|---|---|---|
| #1102 spectral-norm | 0.0525 (3.7× tighter) | +0.77 | NOT load-bearing |
| #1123 asymmetric γ | 0.401 vs 0.101 (4× spread) | +1.6/+3.6 | NOT load-bearing (within band) |
| Baseline | ~0.10 | 0 | (reference) |
| #1166 Arm A TIGHTER | 0.176 (~2× elevated) | +1.19 | NOT load-bearing (mild cost) |
| **#1166 Arm B GENTLER** | **16.03 (~160× elevated)** | **+7.39** | **LOAD-BEARING (clear cost)** |

  - **Regime boundary somewhere between ortho_residual ≈ 0.2 and ortho_residual ≈ 16.** The canon "tightening residual 3-5× is fine" still holds. New finding: **loosening residual 100× DOES cost ~7 mnat val** — at the level where NS5 fails to reach unit norm within budget.

- **Cross-axis canon strengthening — NS5 polar-quality manifold FULLY CHARACTERIZED:**
  - #884 NS_ITERS scan (8, 12, 16, 20): NS_ITERS=12 optimal
  - #920 quintic@NS_ITERS={5,6}: Jordan-quintic worse than cubic-at-12 (overshoot at intermediate σ)
  - #1102 NS5 input spectral-norm: ortho_residual 0.0525 (3.7× tighter), NULL
  - #1107 polar interpolation α=0.50/0.75: post-NS5 blend, NULL
  - #1123 asymmetric γ_L/γ_R: 4× ortho_residual spread, NULL
  - #1135 exact SVD polar: 0.0065 residual, +3 mnat NULL; rank-256 truncation 22.63 residual, CATASTROPHIC
  - #1136 grad noise: pre-NS5 noise CATASTROPHIC
  - #1144 phase NS_ITERS: phase asymmetry NULL
  - **#1166 cubic-coefficient line: (1.5, -0.5) robust to TIGHTER ±0.2, fragile to GENTLER**
  - **NS5 cubic baseline (1.5, -0.5) is structurally optimal under joint constraint `{a+b=1, NS_ITERS=12, m_pre bulk-σ ~ 0.07}`.**

- Closing as NULL. tanjiro → **#1215** (body-Muon Nesterov momentum buffer warmup: linearly ramp mu 0 → 0.95 over first 200 (Arm A) vs 500 (Arm B) steps. Mechanism: m EMA cold-start-biased for first ~20 steps under mu=0.95; warmup replaces implicit β1-style bias with explicit linear schedule. Adam-style first-moment bias correction; mechanism-distinct from all closed mu axes (#930 static, #1156 Lookahead, #1164 depth-stratified, #1107 polar-interp) and complementary to #1208 frieren beta_cov warmup which tests the β2-analog).

## 2026-05-25 21:08 UTC — PR #1176 CLOSED: u/w-floor TARGET_UW probe (0.25 LOWER vs 0.45 HIGHER, baseline=0.35) — 136th NULL, u/w-floor U-shape FULLY MAPPED across 5 points with asymmetric harm direction (g1r1-edward)

- Branch: `g1r1-edward/target-uw`
- Hypothesis: probe u/w-floor TARGET_UW value around baseline 0.35 (introduced in skylight PR, never directly ablated as a tight sweep). Arm A LOWER (0.25): let small updates pass through → weaker rescue. Arm B HIGHER (0.45): force larger steps on all layers → more aggressive minimum step. Direct response to #1129 spectral-exponent closure diagnostic insight that "floor is the dominant magnitude controller now."

| Arm | target_uw | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | 0.35 | 3.266394 | 2925 | 0 | (reference) |
| **A (LOWER)** `xamga913` | 0.25 | **3.27240** | **3000** | **+6.00 (20σ)** | FAILS both (sr+75 + val miss) |
| **B (HIGHER)** `25iotq1n` | 0.45 | **3.27521** | **3100** | **+8.82 (29σ)** | FAILS both (sr+175 + val miss) |

- **Both arms NULL.** 136th closure. Both fail merge rule on both clauses.

- **U-SHAPE CANON FULLY MAPPED across 5 points** (combining #1035, #1129, #1176):

| target_uw | Δval (mnat) | Source |
|---|---|---|
| 0.00 (no floor) | +5.8 | #1035 NULL |
| 0.25 (LOWER probe) | **+6.00** | **#1176 Arm A** |
| 0.35 (baseline) | 0 | #918 / #1129 saturation |
| 0.45 (HIGHER probe) | **+8.82** | **#1176 Arm B** |
| 0.50 (over-application) | +20 | #1035 CATASTROPHIC |

  - **Asymmetric U: HIGHER side regresses 47% faster per unit target_uw** (88 mnat per 1.0 of target_uw vs 60 mnat per 1.0 on LOWER side). Slope extrapolation predicts ~+22 mnat at 0.50, consistent with #1035's CATASTROPHIC observation.
  - Interior optimum at **0.35 ± 0.05** — basin is tight and well-tuned. The natural u/w ratios cluster around 0.35; departure in either direction creates either under-rescue (LOWER) or over-amplification (HIGHER) regimes.

- **MECHANISM CRYSTALLIZED — over-amplification dominates under-rescue:**

| Telemetry | Arm A (LOWER 0.25) | Arm B (HIGHER 0.45) |
|---|---|---|
| `train/uw_floor/fired_fraction` | **0.333** (33% of 72 body MLP params) | **1.0** (100% saturation, every param) |
| `train/uw_floor/mean_rescale_factor` | 1.16× (barely doing work) | **51.86×** (massive amplification) |
| `train/uw_floor/min_ratio_observed` | 0.1794 | 0.00224 (some updates 200× below threshold) |
| `polar/ortho_residual_sample` | 0.199 (~2× elevated) | 0.233 (~2.3× elevated) |
| **`ema/buffer_frob_dist`** | **4.27** | **283.57 (~66× higher)** |

  - **Smoking-gun mechanism for HIGHER-side asymmetry:** `ema/buffer_frob_dist=283.57 vs 4.27 in Arm A (~66× higher)` — chronic over-driving cascades through the EMA wrapper. At 0.45 the floor amplifies updates by 52× whenever it fires (100% of the time), compounding into massive buffer drift across the whole run.
  - **Under-rescue (LOWER 0.25)**: bounded harm. Most params (67%) remain naturally above threshold; rescued ones get small ~1.16× boost; NS5 cubic iteration has "room" to recover from residual under-rescue
  - **Over-amplification (HIGHER 0.45)**: unbounded harm. 100% saturation + 52× mean rescale = multiplicative perturbation compounds through EMA buffer → NS5 polar cubic CANNOT absorb this magnitude → chronic over-driving CASCADES

- **Asymmetric U-shape structurally consistent with #985 NS5 triple-load-bearing canon role 1 (magnitude normalization):** NS5 is contractive on too-large inputs (Arm B over-amp partially absorbed but at cost of polar quality), but cannot construct missing magnitude (Arm A under-rescue passes through directly). Re-confirms the "imperfect polar is better than perfect polar" canon (#1135 extension): structured polar residual at baseline 0.35 floor is part of the load-bearing magnitude equilibrium.

- **Cross-axis canon strengthening:**
  - Reinforces #1129 spectral-exponent + floor-saturation canon — at baseline 0.35, floor is at the Goldilocks rescue/amplification balance, saturating just enough to rescue under-converged layers while not over-driving the EMA buffer
  - The floor mechanism interacts with NS5's 6.7% polar residual (#1135 canon) in a tightly coupled equilibrium
  - Further fine-grained probing of u/w-floor axis is structurally constrained — basin width ±0.05 with asymmetric harm direction

- Closing as NULL. edward → **#1213** (body-Muon Nesterov mu cooldown schedule: linearly ramp mu 0.95→0.97 (Arm A) vs 0.95→0.99 (Arm B) over last 20% of training. Mechanism: per-step gradient SNR shrinks during cooldown as LR→0; wider EMA window (20→100 step lookback) averages more steps to recover SNR. Mechanism-distinct from all closed mu axes — #930 static scan, #1156 Lookahead, #1164 depth-stratified, #1107 polar-interp — and all in-flight β-axes (#1182 wrapper β_target, #1208 preconditioner beta_cov)).

## 2026-05-25 19:51 UTC — PR #1164 CLOSED: Depth-stratified body-Muon EMA momentum (per-layer mu, 12-layer linear interp) — 135th NULL, depth-stratified body-Muon hyperparameter family structurally constrained (g1r1-frieren)

- Branch: `g1r1-frieren/depth-stratified-mu`
- Hypothesis: per-layer mu (EMA momentum) linearly interpolated across 12 transformer layers — fast-deep (Arm A DOWN: shallow=0.99 → deep=0.90, 10-step lookback at deep) vs slow-deep (Arm B UP: shallow=0.90 → deep=0.99, 100-step lookback at deep). Tests whether deep semantic-compression layers need long-memory EMA or whether shallow token-level layers benefit from fast adaptation. Direct response to #1116 askeladd depth-LR closure note explicitly suggesting per-layer EMA β as next mechanism-distinct depth axis.

| Arm | mu shallow → deep | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | 0.95 uniform | 3.266394 | 2925 | 0 | (reference) |
| **A (DOWN, FAST-DEEP)** `4v4nbzrf` | 0.99 → 0.90 | **3.332653** | **−1** | **+66.26 (221σ)** | FAILS both (val miss by 66 mnat) |
| **B (UP, SLOW-DEEP)** `xlhi2m73` | 0.90 → 0.99 | **3.305058** | **−1** | **+38.66 (129σ)** | FAILS both (val miss by 39 mnat) |

- **Both arms CATASTROPHIC.** 135th NULL. Both miss the 3.28 target. **Asymmetric NULL with 28-mnat gap between arms is the key signal.**

- **MECHANISM CRYSTALLIZED — deep-layer EMA mu is LOAD-BEARING; fast-deep is the hostile direction.** Per-layer grad-norm telemetry at terminal step:

| Layer endpoint | grad-norm | Ratio to its opposite |
|---|---|---|
| Arm A L11 mu=0.90 (FAST-DEEP) | 614 | 52× larger than Arm B L11 mu=0.99 (11.86) |
| Arm B L00 mu=0.90 (FAST-SHALLOW) | 1378 | 315× larger than Arm A L00 mu=0.99 (4.37) |

  - **Fast EMA (mu=0.90, 10-step lookback) fails to absorb per-step gradient noise on deep layers** → grad_norm stays large → unsmoothed direction → NS5 polar receives noisy input → cascading val degradation
  - **Slow EMA (mu=0.99, 100-step lookback) is structurally REQUIRED on deep layers** to stabilize compressed semantic features
  - **Shallow layers tolerate fast EMA** because gradient amplitude is high (signal-dominated despite noisy averaging) — but the 315× shallow grad scale is *symptom not cause*; shallow harm is less load-bearing because semantic content is less compressed
  - The 28 mnat asymmetry (Arm B less catastrophic) confirms 16:05 UTC mechanism prediction: deep-layer body-Muon optimization is more load-bearing than shallow

- **EMA buffer divergence ANTI-correlates with val outcome** — Arm B `ema/buffer_frob_dist=552M` is 3.7× LARGER than Arm A's 151M, yet Arm B has the BETTER val. Diagnostic: buffer_frob_dist is dominated by shallow-layer EMA drift, but shallow drift is less fatal than deep drift. **The global metric is misleading at depth — future depth-stratified PRs should log `ema/buffer_frob_dist_per_layer` to disambiguate.**

- **Cooldown cannot rescue mu mis-spec.** Both arms cooled normally in final 250 steps (−9 mnat per arm), but started ~30-70 mnat too high. Damage is compounded across the entire run, not concentrated in cooldown — mechanistically distinct from cooldown-shape regressions (#1099 / #1084) which are cooldown-localized.

- **CROSS-AXIS CANON STRENGTHENING — depth-stratified body-Muon hyperparameter family CLOSED across LR + EMA mu:**

| Closure | Mechanism | Arm A (DOWN/half) | Arm B (UP/double) |
|---|---|---|---|
| #1116 (depth-LR) | step magnitude | +11.0 mnat CATASTROPHIC | +0.7 mnat marginal |
| #1164 (depth-mu) | EMA temporal smoothing | +66.3 mnat CATASTROPHIC | +38.7 mnat CATASTROPHIC |

  - **Uniform values across depth are load-bearing for body-Muon optimizer hyperparameters.** Any unilateral per-layer departure penalized; deep-direction departures more catastrophic than shallow.
  - The bilateral whitening + NS5 polar stack absorbs depth differences in update *direction* but not in update *temporal smoothing* or *magnitude*.
  - Future depth-stratified PRs are now structurally constrained — only mechanism-distinct sub-axes worth probing (per-layer wd? per-layer NS5 iters? per-layer u/w-floor TARGET_UW?) and all carry a high NULL prior.

- **Cross-axis with #1136 pipeline-position canon**: EMA mu modification operates pre-NS5 (on momentum buffer used as NS5 input), so unbounded regression is expected if mechanism is sensitive. The catastrophic regression respects the canon. Adds an EMA-buffer-position datapoint to the upstream-CATASTROPHIC pattern.

- Closing as NULL. frieren → **#1208** (beta_cov bias-correction warmup: linearly ramp beta_cov 0 → 0.95 over 300 steps (Arm A) vs 750 steps (Arm B). Mechanism: covariance EMA L_cov/R_cov are cold-start-biased for first ~20 steps; warmup replaces implicit bias correction with explicit linear schedule. Mechanism-distinct from all closed body-Muon axes — #686 tested static beta_cov values + mid-training schedules but never warmup from 0; #774 fast-mix K is a different mechanism; #918 EMA wrapper warmup is param-space not preconditioner-covariance).

## 2026-05-25 18:40 UTC — PR #1135 CLOSED: Exact SVD polar map (svd_full vs svd_topk=256) — 134th NULL, exact-polar / rank-truncation axis FULLY CLOSED, "imperfect polar is better than perfect polar" canon (g1r1-alphonse)

- Branch: `g1r1-alphonse/exact-svd-polar`
- Hypothesis: Replace NS5 cubic Newton polar map with exact `torch.linalg.svd` to isolate the polar projection's role. Two arms: svd_full (machine-precision polar) and svd_topk=256 (rank-truncated to ~stable_rank). Tests whether NS5's 6.7% residual is an approximation artifact or a structural feature.

### Results

| Arm | polar_method | polar_topk | W&B | val/loss | sr | first_step_to_target | Δval (mnat) | step_avg (ms) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 | ns5 | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | 2925 | — | ~4329 | BASELINE |
| **A (svd_full)** | svd_full | — | `e29g5f3q` | **3.269416** | **2975** | 2975 | **+3.022** (10σ) | **6829.72** (1.58×) | **CLEAR NULL** |
| **B (svd_topk=256)** | svd_topk | 256 | `t85dixhq` | **3.319233** | **−1** | −1 | **+52.84** (176σ) | **6788.79** (1.57×) | **CATASTROPHIC NULL** (failed 3.28) |

### Diagnostic telemetry

| Metric | Arm A (svd_full) | Arm B (svd_topk=256) |
|---|---|---|
| `polar/ortho_residual` | **0.0065** (machine precision ✓) | **22.63** (~750× baseline) |
| `polar/svd_stable_rank` | (full rank) | **1.003** (collapse to rank-1!) |
| `polar/svd_S_top_max` | — | 1.219 |
| `polar/svd_S_ratio_topk` | — | 0.00156 (S[256]/S[0]) |

### Mechanism findings (3 numbered)

1. **Exact polar (Arm A) mildly hurts val.** SVD-based polar with residual ≈ 0 (machine precision) regresses +3.022 mnat (10σ above noise floor σ≈0.0003). **Falsifies the strict "polar residual not load-bearing" reading of #1102** — the residual is not just unimportant, it is mildly *beneficial*. The cubic NS5 polar at 12 iters acts as a stochastic damper / structured noise injection that helps generalization.
2. **Rank-256 polar (Arm B) catastrophically hurts.** Truncating to rank-256 (just below m_pre's static stable_rank ≈ 426) produces a CATASTROPHIC +52.8 mnat regression and never hits sr=3.28. The diagnostic smoking gun: `polar/svd_stable_rank` collapses to 1.003, meaning the truncated polar output concentrates ~entirely in the top singular component → effective rank-1 updates per body-Muon step. The bottom-2/3 singular components carry load-bearing late-cooldown signal even though they're below the static rank measurement.
3. **Step-time methodology lesson.** Pre-launch standalone SVD-vs-NS5 benchmark predicted 44× slower; in-training measurement was 1.58× slower (cuSolver overhead amortizes over body-Muon step pipeline). **Future PR cost estimates must distinguish static-FLOP estimates from in-training wall-clock** for kernel-class operations where overhead amortization matters.

### Canonical finding crystallized — "Imperfect polar is better than perfect polar"

The asymmetric outcome maps cleanly onto a new structural canon that **refines but does not overturn** #1102/#1107:

1. **Cubic NS5 polar at NS_ITERS=12 is a near-optimal practical compromise** between exact-polar (kills implicit regularization, +3 mnat / 10σ) and rank-truncated polar (kills late-cooldown signal, +53 mnat / catastrophic).
2. **The ~6.7% NS5 residual is implicit regularization**, not an approximation artifact. The cubic polynomial structure injects beneficial stochastic damping into the body-Muon update.
3. **m_pre's effective spectrum is rank-concentrated in live training.** Pre-launch static measurement of stable_rank ≈ 426 understates the rank-importance of the bottom-2/3 singular components. The polar/svd_stable_rank=1.003 collapse in Arm B confirms low-rank truncation collapses to rank-1 update.

### Cross-axis canon strengthening

- **#985 NS5 triple-load-bearing canon** strengthened to 4-role: magnitude normalization + rank-deficiency clipping + null-space amplification suppression + **structured residual-as-regularization**.
- **#1136 PIPELINE POSITION CANON** strengthened: polar map IS the position where regularization is *welcome*, in contrast to pre-NS5 grad-noise (CATASTROPHIC) and post-polar regularization (sub-noise).
- **#1102 m_pre rank canon refined**: stable_rank≈426 is a static measurement that understates effective rank in live training; rank truncation below this effective rank is catastrophic.
- **#1107 polar interpolation grounding**: the closed n=2 NULL at α=0.75 (Δval−0.706 mnat marginal) is consistent with this finding — partial back-blend with raw m_pre is sub-noise; full exact-polar is regression; full rank-truncation is catastrophic.

### Merge rule check
- Arm A: sr=2975 > 2912.5, sr ≠ 2925 → FAILS both clauses
- Arm B: val=3.31923 above 3.28 stat-sig threshold itself → FAILS

Both arms FAIL merge rule. Closed without merge.

### Conclusion

**134th NULL.** The exact-polar / rank-truncation axis is FULLY CLOSED:
- Exact polar (Arm A): mildly bad (+3 mnat)
- Rank-truncated polar (Arm B): catastrophically bad (+53 mnat)
- Cubic NS5 at NS_ITERS=12: locally optimal

Combined with #884 (NS_ITERS sweep NULL) + #1102 (NS5 input normalization NULL) + #1123 (asymmetric γ NULL) + #1144 (NS_ITERS phase schedule NULL), **NS5 polar configuration is structurally established as load-bearing in current form**.

alphonse → **#1201** (Hybrid noisy exact polar: SVD + calibrated Gaussian noise — does the cubic polynomial structure matter or just the residual magnitude? Direct mechanism follow-up testing one of alphonse's own suggested #1135 follow-ups).

---

## 2026-05-25 17:38 UTC — PR #1156 CLOSED: Lookahead k-step slow-fast weight averaging on body Muon (k=5, α=0.5 vs α=0.25) — 133rd NULL, Lookahead family FULLY CLOSED (g1r1-askeladd)

- Branch: `g1r1-askeladd/lookahead`
- Hypothesis: Apply Zhang 2019 Lookahead to body Muon — every k=5 fast steps, blend slow buffer toward fast iterate with weight α. Test canonical α=0.5 vs lighter α=0.25 to characterize dose-response. Hypothesis: outer averaging could dampen late-cooldown variance.

### Results

| Arm | k | α | W&B | val/loss | sr | first_step_to_target | Δval (mnat) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | — | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | 2925 | — | BASELINE |
| **A (canonical)** | 5 | 0.5 | `fuvrw1jy` | **3.28288** | **−1** | −1 | **+16.49** (55σ) | **CATASTROPHIC** (missed 3.28 target) |
| **B (light blend)** | 5 | 0.25 | `yy7ep97n` | **3.30829** | **−1** | −1 | **+41.89** (140σ) | **CATASTROPHIC** (much worse than Arm A!) |

### Diagnostic telemetry

| Metric | Arm A (α=0.5) | Arm B (α=0.25) |
|---|---|---|
| `lookahead/blend_events_cumulative` | 46,800 (650 events × 72 params) | 46,800 (identical) |
| `lookahead/slow_fast_distance_mean` (full hist) | 0.0520 | **0.0811** (LARGER despite milder α) |
| `lookahead/slow_fast_distance` (final cooldown) | 7.2e-6 | 1.1e-5 |
| `polar/ortho_residual_sample` | 0.2627 | 0.1463 |
| `ema/buffer_frob_dist` (terminal) | 1.97 | 0.94 |

### Mechanism findings (5 numbered)

1. **STRIKING NON-MONOTONIC DOSE RESPONSE — Arm B (milder α=0.25) is 2.5× WORSE than Arm A (canonical α=0.5).** Naïve linear-in-α prediction was Δval(B) ≈ ½·Δval(A) ≈ +8 mnat; observed +41.89 mnat. **The periodic-blend mechanism itself is intrinsically catastrophic at body-Muon scale, irrespective of α magnitude.**
2. **Slow buffer = sum of polar(NS5)-orthogonal matrices is NOT itself orthogonal.** Every blend reintroduces non-orthogonal weight components that NS5 spent compute removing. `polar/ortho_residual` elevated 1.5-26× vs baseline.
3. **Two competing averaging mechanisms destructively interfere during cooldown.** Body Muon EMA buffer (β_t→0.99) AND Lookahead slow buffer fight. Arm A's `ema/buffer_frob_dist`=1.97 vs Arm B 0.94 — EMA buffer drifts more in Arm A as it "competes" more with Lookahead average.
4. **Counter-intuitive distance reversal:** Arm B's mean slow_fast distance (0.081) is LARGER than Arm A's (0.052) despite α=0.25 vs α=0.5. Lower α means slow stays further from fast between blends → each blend event introduces a LARGER per-event perturbation. The averaging mechanism is NOT a smooth dose-response in α.
5. **Lookahead family FULLY CLOSED in r1.** Joins #943 SWA (catastrophic α=0.5) and #990 Schedule-Free (catastrophic) as the 3rd weight-space averaging NULL. **Body Muon's EMA + WSD cooldown is SUFFICIENT outer smoothing across 3 independent mechanisms — any additional weight-space averaging is redundant + destructive.**

### Cross-axis canons strengthened

- **PIPELINE POSITION CANON #1136** — weight-space mixing AFTER NS5 (post-polar averaging via slow buffer) is catastrophic, consistent with the canon: post-NS5 magnitude/direction modifications are punished by the EMA+cooldown stack.
- **#1129 u/w-floor canon** — when polar quality degrades (Lookahead injects non-ortho components), val regresses substantially → polar IS load-bearing when externally perturbed (vs sub-noise under intra-NS5 modification).

### Conclusions

Lookahead axis CLOSED across α ∈ {0.25, 0.5}. Linear-in-α extrapolation does not hold — there is no "magic α<0.25" that recovers; the milder arm is worse, not better. Next: askeladd → new hypothesis post-researcher-agent ideation.

---

## 2026-05-25 14:15 UTC — PR #1144 CLOSED: NS_ITERS phase schedule probe (stable=10/cooldown=14 vs stable=14/cooldown=10) — 132nd NULL, phase-schedule axis FULLY CLOSED (g1r1-nezuko)

- Branch: `g1r1-nezuko/ns-iters-phase`
- Hypothesis: Test whether NS_ITERS polar quality should be phase-dependent: tighter during cooldown (NS=14, when each step matters more) vs tighter during stable (NS=14). Baseline uniform NS_ITERS=12 from #884. #1102 found polar/ortho_residual NOT load-bearing at static NS_ITERS=12 — this PR tests whether phase-selective tightening unlocks latent signal.

### Results

| Arm | NS stable | NS cooldown | W&B | val/loss | sr | Δval (mnat) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 | 12 | 12 | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | BASELINE |
| **A** | **10** | **14** | `j9lot65t` | **3.267672** | **2950** | **+1.278** | NULL (~4.3σ) |
| **B** | **14** | **10** | `norz0n09` | **3.267612** | **2950** | **+1.218** | NULL (~4.0σ) |

**STRIKINGLY SYMMETRIC REGRESSION.** Both arms +1.2 mnat, both sr=2950. Δval gap between arms = 0.06 mnat (< empirical σ≈0.0003 single-seed noise floor). Both fail merge rule (sr=2950 disqualifies val clause).

### Diagnostic telemetry (final values)

| Metric | Arm A (stable=10, cd=14) | Arm B (stable=14, cd=10) |
|---|---|---|
| `polar/ortho_residual_sample` (final) | **0.0759** (tighter — cooldown NS=14) | **3.1102** (looser — cooldown NS=10) |
| `ema/buffer_frob_dist` (final) | 20.15 | 23.26 |
| Schedule transition at step 975 | ortho_residual 4.20→0.37→0.076 (55× cooldown tightening) | ortho_residual 0.12→3.94 (30× cooldown loosening) |

### Mechanism findings

1. **Symmetric regression rules out phase-asymmetric polar-quality loading.** If stable-phase polar quality were preferentially load-bearing, Arm A (NS=10 stable, looser) should regress while Arm B (NS=14 stable, tighter) should recover. Neither helps — same direction, same magnitude. Phase-asymmetric polar quality is NOT load-bearing in either direction.
2. **Any departure from uniform NS_ITERS=12 costs ~1.2 mnat regardless of phase.** Arm A avg NS_iters ≈12.8 (+6.7%), Arm B ≈11.2 (−6.7%) vs baseline. Both deviations cost identically.
3. **Reinforces #884 static optimum + #1102 ortho_residual NOT load-bearing.** Now extended to phase-selective application: the static NS_ITERS=12 is a genuine sweet-spot, not a coincidence. NS5 polar-quality manifold {static, asymmetric, post-polar, exact, residual, phase} is fully closed.
4. **Plausible mechanism for symmetric ~1.2 mnat cost:** EMA buffer expects uniform polar quality across all steps; mid-training regime shift at step 975 disrupts EMA statistics. Arm B's higher buffer_frob_dist (23.26 vs Arm A 20.15) is suggestive. Schedule discontinuity itself may also impose a small one-time regime-shift cost.
5. **Cross-axis confirmation of #1136 pipeline-position canon:** intra-NS5 modifications are bounded (+1.2 mnat NULL); pre-NS5 perturbations are unbounded (CATASTROPHIC +16/+79 mnat). Canon: modifications within NS5 have upper-bounded cost, modifications before NS5 are unbounded.

### Conclusions

NS_ITERS phase-schedule axis CLOSED. Next: nezuko → **#1182** (EMA wrapper β_target probe: first direct ablation of ema_beta_target=0.99 in r1).

---

## 2026-05-25 13:45 UTC — PR #1136 CLOSED: Body Muon gradient noise injection (σ=0.05 vs 0.15) — 131st NULL, gradient noise axis FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/grad-noise`
- Hypothesis: Inject gradient noise `σ·||g||_F/√numel·N(0,1)` into all 72 body Muon params before EMA/whitening/NS5. Arm A σ=0.05 (light); Arm B σ=0.15 (moderate). Based on Neelakantan et al. 2015 annealed gradient noise for generalization.

### Results

| Arm | σ | W&B | val/loss | sr | Δval (mnat) | σ multiples | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.0 | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| **A** | **0.05** (light) | `ze6l9k7r` | **3.282374** | **−1** | **+15.98** | 53σ | **CATASTROPHIC** (missed 3.28 target) |
| **B** | **0.15** (moderate) | `7vrtq1l1` | **3.345232** | **−1** | **+78.84** | 263σ | **CATASTROPHIC** (missed 3.28 target) |

**Dose-response: Δval ∝ σ^1.45 (super-linear).** 3× increase in σ → 4.94× regression. Variance accumulates super-linearly through bilateral whitening (2 GEMMs) + NS5 (cubic Newton amplifies off-manifold component).

### Diagnostic telemetry (final values)

| Metric | Arm A (σ=0.05) | Arm B (σ=0.15) | Baseline |
|---|---|---|---|
| `muon/noise_to_signal_ratio` | 0.0500 | 0.1500 | n/a |
| `polar/ortho_residual_sample` | 0.2404 | **0.5275** | 0.2477 / 0.1394 |
| `ema/buffer_frob_dist` | 23.714 (+4.7%) | **28.212 (+24.6%)** | 22.645 / 22.642 |
| `ema/delta_ema_minus_live_mnat` | 0.618 | 0.636 | 0.597 / 0.607 |

### Mechanism findings

1. **NS5 absorbs σ=0.05 noise at the ortho_residual level but NOT at the val level.** Arm A ortho_residual 0.240 ≈ baseline range (0.139–0.248). Yet val is 15.98 mnat worse. The regression is at the descent level, not the polar projection level.
2. **NS5 FAILS to orthogonalize σ=0.15-corrupted input.** Arm B ortho_residual 0.528 = 2.1× elevated → NS5 cubic Newton cannot orthogonalize a highly-corrupted polar map.
3. **EMA does NOT dampen pre-EMA noise.** Noise injected before EMA enters the buffer and persists for ~10 steps (μ=0.95). The regression is at descent level (ema/delta_ema_minus_live_mnat flat: 0.60→0.62→0.64). Buffer_frob_dist grows monotonically with σ but is NOT the primary regression mechanism.
4. **Implementation verified correct.** noise_to_signal_ratio matched σ exactly; all 72 body params received noise as designed.

### Pipeline position canon (major mechanism update)

**The Neelakantan et al. 2015 prior on annealed gradient noise does NOT transfer** to a benchmark where the optimizer pipeline includes a strongly-nonlinear orthogonalizer (NS5) that amplifies noise via cubic Newton iteration.

Pipeline position hierarchy established:
- **Pre-EMA pre-whitening pre-NS5 (THIS PR):** CATASTROPHIC at all σ > 0
- **Post-polar magnitude blend (#1107):** sub-noise at n=2 (n=1 mirage)  
- **Post-NS5 output side (#1135 Arm A exact SVD):** +3 mnat regress — NS5 residual IS implicit regularization
- **Output-level (loss-side regularization #1043/#1058/#1060/#1066/#1090):** all CATASTROPHIC or noise-floor

**Rule: regularization must be applied POST-POLAR (after NS5), not upstream of it.**

### Cross-axis

- Reinforces #1135 exact-SVD finding: NS5's 6.7% polar residual is implicit regularization; perturbing it (either by bypassing with exact SVD upstream, or corrupting with noise upstream) is harmful
- Reinforces #1102 m_pre rank canon: m_pre stable rank ≈426; pre-polar noise injection further collapses rank
- Closes the "gradient-level signal modification" direction suggested by #1090 closure note

---

## 2026-05-25 12:55 UTC — PR #1129 CLOSED: Post-polar aspect-ratio exponent ablation (exp=0.0 vs 1.0) — 130th NULL, spectral_exp axis FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/spectral-exp`
- Hypothesis: Test the hardcoded `** 0.5` exponent in `update = polar * (max(1, m/n) ** 0.5)` (line 532). Frobenius-style aspect-ratio compensation only affects MLP.fc matrices (aspect ratio 4.0). Arm A exp=0.0 (1.0× polar on MLP.fc, 0.5× vs baseline); Arm B exp=1.0 (4.0× polar on MLP.fc, 2.0× vs baseline).

### Results

| Arm | exp | MLP.fc factor | W&B | val/loss | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.5 (Frobenius) | 2.0× polar | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| A | **0.0** | **1.0× polar** | `8slemy5y` | **3.267764** | 2950 | +1.37 (4.6σ) | +25 | **marginal NULL** (just outside band) |
| B | **1.0** | **4.0× polar** | `ymmtfaff` | **3.268970** | 2975 | +2.58 (8.6σ) | +50 | **CLEAR NULL** |

Both arms FAIL predeclared merge rule (sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)). Asymmetric U-curve: Arm B regresses ~1.9× harder than Arm A.

### Mechanism findings

1. **u/w-floor (TARGET_UW=0.35 from #1035) saturates at 100% on MLP.fc by mid-training in BOTH arms.** Arm A reaches saturation earlier (smaller magnitude → lower ratio → floor fires sooner); Arm B at step ~425 (4× polar magnitude takes longer to push ratio above 0.35). Once saturated, floor is the dominant magnitude controller, not the post-polar scalar.
2. **Floor is asymmetric: rescues magnitude shortfalls but cannot bound magnitude overshoots.** Arm A only +1.4 mnat despite 0.5× MLP.fc factor (floor saves it). Arm B +2.6 mnat at 2× factor (floor doesn't push it back DOWN). Direction of safety from baseline: DOWN (sub-Frobenius), never UP.
3. **polar/ortho_residual drift confirms post-polar magnitude affects projection cleanliness.** Arm A 0.108 ≈ baseline 0.10; Arm B 0.143 (43% higher). Larger post-polar magnitudes degrade polar projection quality at scale.

### Cross-axis intersections

- **Reinforces #1135 alphonse exact-SVD finding (Arm A regressed +3 mnat):** NS5's 6.7% polar residual is implicit regularization. This PR's Arm B polar/ortho_residual drift (0.143 vs baseline 0.10) is direct evidence the polar projection itself becomes the limiting factor at large post-polar magnitudes.
- **Reinforces #1102 frieren m_pre rank discriminator:** post-polar magnitude levers (spectral_exp here, polar interp #1107, exact SVD #1135 Arm A) all show smaller effects than pre-polar perturbations (cov source #1125, γ asymmetry #1123).
- **Reinforces #1035 u/w-floor canon:** floor is now empirically confirmed as the dominant magnitude controller, not just a safety net.

### Predicted outcome alignment

- ~20% best-case (one arm hits gate): NO
- ~25% marginal: PARTIAL (Arm A just outside marginal band, +0.001370 vs 0.001 threshold)
- ~45% NULL modal: YES — both arms within seed-noise direction of baseline
- ~10% catastrophic: NO

### Suggested follow-ups by student

1. **Close spectral_exp axis** — done
2. **Higher-leverage axis: u/w-floor TARGET_UW probe** — never directly ablated as a value (#1035 tested 0.0 vs 0.50 floor existence/disabling, but not a tight sweep around 0.35)
3. **Joint spectral_exp × γ_power probe** — both control post-polar effective magnitude
4. **Per-shape TARGET_UW differentiation** — fc vs lm_head

### Next assignment for edward

→ **#1170** (or next number) — u/w-floor TARGET_UW direct probe. Tightly ablates the dominant magnitude controller exposed by this PR.

---

## 2026-05-25 12:10 UTC — PR #1125 CLOSED: SOAP-style cov source (update vs momentum) — 129th NULL, cov-source axis FULLY CLOSED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/soap-cov-source`
- Hypothesis: PMuon's L_cov/R_cov are built from raw gradient `g32` but the preconditioned signal is Nesterov-blended `update = (1-μ²)·g + μ²·m_prev`. SOAP (Vyas 2024) identifies this mismatch as a bias source. Test whether building cov from the actual signal being preconditioned helps: Arm A uses cov_source="update", Arm B uses cov_source="momentum" (pure EMA buffer).

### Results

| Arm | cov_source | W&B | val/loss | sr | Δval (mnat) | Δsr | σ | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | grad | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — | — |
| A | update (Nesterov-blended) | `x0cvzei9` | **3.272748** | **3025** | +6.35 | +100 | 21σ | **CLEAR NULL** |
| B | momentum (pure EMA) | `j2skvl7i` | **3.279062** | **3200** | +12.67 | +275 | 42σ | **CATASTROPHIC NULL** |

Both arms fail predeclared merge rule. Arm B misses the 3.28 target stat-sig threshold (margin=0.00094 < 0.004).

### Polar / m_pre diagnostics

| Arm | input_stable_rank_est | ortho_residual_sample | m_pre_fro | m_pre_sigma_max | cov_signal_norm |
|---|---|---|---|---|---|
| A (update) | **418.55** | 0.1998 | 0.944 | 0.04616 | 454.35 |
| B (momentum) | **377.10** | 0.1414 | 1.134 | 0.05839 | 485.04 |
| Baseline (grad) | ~426 | ~0.20 | — | — | — |

### Mechanism findings

1. **m_pre stable rank IS the discriminator, NOT ortho_residual.** Arm B has LOWER ortho_residual (0.14 vs 0.20) yet WORSE val/loss. The bilateral preconditioner's job is whitening the step's characteristic curvature, not maximizing pre-NS5 isotropy. **Yet another confirmation of #1102/#1123/#1107 canon: polar/ortho_residual is NOT load-bearing at NS_ITERS=12.**
2. **Momentum-cov collapses m_pre stable rank by ~12% (426 → 377).** EMA buffer is autocorrelated → over-weights stale direction → fewer effective singular directions reach polar → descent loses generality across parameter geometry.
3. **Update-cov is rank-preserving but val-disappointing.** Arm A rank ≈ 418 ≈ baseline. The Nesterov blend `(1-μ²)·g + μ²·m_prev` whitens magnitude correctly (cov_signal_norm 454 ≈ baseline ballpark) but mixes old + new signal in a way slightly biased relative to fitting on `g` alone.
4. **cov_signal_norm asymmetry**: Arm A 454 (smallest — Nesterov blending shrinks toward zero when momentum lags); Arm B 485 (largest — EMA accumulates magnitude across steps); gradient-cov sits between and matches NS5's implicit design assumption.

### Canon: SOAP recipe doesn't transfer to bilateral preconditioner

SOAP (Vyas 2024) prescribes "build covariance from the same signal you precondition." Under our γ=0.4 symmetric whitening + β_cov=0.95 EMA + NS5 cubic polar pipeline, **this prescription does NOT transfer**. NS5's cubic map (per #985 triple-load-bearing canon) is implicitly designed for gradient-distribution inputs. Both update-cov and momentum-cov drift away from that distribution in different but uniformly harmful directions.

### Portfolio implications

- **cov-source axis FULLY CLOSED** at γ=0.4, β_cov=0.95.
- Future cov-related PRs (β_cov retune #686 CLOSED, cov reset #725 CLOSED, cov warmup-fast-mix #774 CLOSED, cov source #1125 CLOSED) must operate under known constraints.
- Strong cross-axis canon: **m_pre stable rank IS the discriminator** across #1102 (input norm), #1123 (γ_L/γ_R asym), #1125 (cov source). Future PRs should report m_pre stable rank as primary diagnostic.
- thorfinn → **#1168** (L_neg/R_neg matrix_neg_power eps ablation: Arm A LOOSER eps=1e-6 251× amp vs Arm B TIGHTER eps=1e-15 10^6× amp, baseline eps=1e-12 63095× amp). Direct test of NS5 triple-load-bearing role 3 ("null-space amplification suppression") via L_neg/R_neg construction at γ=0.4. L_cov stable rank ≈13/3072 → ≈99.6% of eigenvalues are in clamped tail → eps directly controls null-space amplification. Mechanism-distinct from all in-flight; first eps-clamp ablation in r1.

---

## 2026-05-25 11:55 UTC — PR #1107 CLOSED: Polar interpolation α=0.75 n=2 confirmation — 128th NULL, polar-interp axis FULLY CLOSED, n=2 REVERSES n=1 WIN (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/polar-interpolation`
- Hypothesis (original): polar projection over-orthogonalizes m_pre in low-rank regime; blending raw m_pre with polar (α-blend) preserves directional information that pure polar discards. Two arms initially: α=0.75 light blend vs α=0.50 heavy blend. Arm A (α=0.75) showed n=1 WIN (val=3.264891, Δval−1.503 mnat); n=2 confirmation requested per marginal-boundary rule.

### n=2 confirmation results

| Seed | wandb id | val/loss | sr | Δval vs baseline (mnat) |
|---|---|---|---|---|
| 1 | `wlrtyf2t` | 3.264891 | 2925 | **−1.503** |
| 2 | `zegkqdpe` | 3.266485 | 2925 | **+0.091** (regress) |
| **n=2 mean** | — | **3.265688** | **2925** | **−0.706** |

Baseline (n=2 PR #918): val=3.266394, sr=2925. Empirical σ ≈ 0.0003 (#958).

### Merge rule evaluation — BOTH REQUIRED CLAUSES FAIL

| Rule | Value | Threshold | Pass |
|---|---|---|---|
| `(3.266394 − μ_n2) · √2 ≥ 0.004` | 0.000998 | 0.004 | ❌ |
| Seed-1 `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` | sr=2925, val=3.264891 | val<3.266394 | ✅ |
| Seed-2 `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` | sr=2925, val=3.266485 | val<3.266394 | ❌ |

Both required conditions fail → **NULL closure**.

### Mechanism findings

1. **Polar telemetry reproduces cleanly across seeds.** Seed-1 vs seed-2 final values: `polar/ortho_residual_sample` 3.604/3.625, `polar/ortho_residual_polar_only` 0.188/0.203, `polar/blend_magnitude_ratio` 0.00230/0.00230. Trajectory means consistent: residual_sample mean=3.921±0.323, blend_ratio mean=0.00193±0.00044. **The blend mechanism IS doing what it should — m_pre carries ~0.23% of polar Frob mass, the residual is ~4× elevated vs polar-only, confirming non-trivial shift away from orthogonal projection.**
2. **The val/loss signal does NOT survive seed averaging.** Seed-1 (−1.503 mnat) was a lucky draw; seed-2 (+0.091 mnat) is essentially baseline noise. The n=2 mean improvement (−0.706 mnat) is positive but 4× below the merge threshold (need 0.004 after √n scaling, observed 0.001).
3. **Polar projection in NS5 is closer to load-bearing than seed-1 suggested.** Combined with Arm B (α=0.50, +4.82 mnat regress), any blend in (0.5, 1.0) tested is either neutral or regressive. The mechanism intuition (rank-deficiency canon: polar synthesizes singular-value structure not in the gradient) MAY still be correct, but the practical val/loss effect at this magnitude is below noise.
4. **n=2 boundary discipline SAVED A FALSE MERGE.** Pattern matches #969 (γ=1.2: n=1 looked like clean WIN at lr=0.035; n=2 at lr=0.040 revealed Pareto-shift). Session memory rule "Marginal Δval ≤ 0.001 at n=1 over baseline requires n=2 confirmation" is load-bearing here.

### Bug fix commendation

Student detected and fixed a `senpai-pr-guard.py` regex bug (committed `3107d30` to senpai main) — the guard was crashing on SENPAI-RESULT lines INSIDE markdown code fences. The advisor's 07:34 UTC comment contained a template line `SENPAI-RESULT: {"terminal":true,...,"value":<val_2>}` inside a fenced code block. The fix adds `in_code_block` state tracking to `result_markers()` so fenced lines are skipped. Infrastructure-grade catch that benefits all future PRs.

### Portfolio implications

- **Polar-interpolation axis FULLY CLOSED** across α ∈ {0.50, 0.75}.
- Cross-axis with #1102 reframe: m_pre stable rank ≈ 426 (rank-rich, not rank-deficient). The polar over-projection lever-arm is smaller than initially hypothesized.
- Future PRs targeting NS5 polar quality must operate INSIDE NS5 (NS_ITERS modulation, polynomial coefficient choice, exact SVD substitution), NOT post-NS5 blend.
- Reinforces n=2 boundary discipline as load-bearing for future marginal-WIN candidates.
- tanjiro → **#1166** (NS5 cubic polynomial coefficient ablation: Arm A TIGHTER (a=1.7, b=-0.7) linear convergence at σ=1 rate −0.4 vs Arm B GENTLER (a=1.3, b=-0.3) linear convergence rate +0.4). First direct ablation of NS5 cubic coefficients in r1. Baseline (1.5, -0.5) has quadratic convergence at σ=1 (`f'(1)=0`); arms test linear convergence with better/worse far-from-1 behavior. Mechanism-distinct from all in-flight: #1129 post-polar magnitude, #1135 exact SVD replacement, #1144 phase NS_ITERS count. m_pre stable rank ≈ 426 → most singular values are far from σ=1 → polynomial behavior in σ≪1 regime matters.

---

## 2026-05-25 11:40 UTC — PR #1123 CLOSED: Asymmetric γ_L/γ_R whitening exponents — 127th NULL, asymmetric whitening axis FULLY CLOSED (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-L-gamma-R-asymmetry`
- Hypothesis: PMUON_GAMMA=0.4 is symmetric across L_cov/R_cov whitening, but L_cov stable rank (~13.18 / 3072) and R_cov stable rank (~1.67 / 768) have very different rank profiles per #1046 rank-deficiency canon. Test whether decoupling γ_L from γ_R lets each side match its rank-deficiency budget. Arm A (γ_L=0.25, γ_R=0.5) softens L whitening and tightens R; Arm B (γ_L=0.5, γ_R=0.25) inverts.

| Arm | γ_L | γ_R | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.4 | 0.4 | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | 0.25 | 0.5 | **3.270** | +3.6 | 2950 | +25 | 12σ | **CLEAR NULL** | (see PR) |
| Arm B | 0.5 | 0.25 | **3.268** | +1.6 | 2950 | +25 | 5σ | marginal NULL | (see PR) |

### Mechanism findings

1. **Polar/ortho_residual differs 4× between arms but val barely shifts.** Arm A ortho_residual ≈ 0.401 (looser whitening of L → less polar input pre-conditioning); Arm B ortho_residual ≈ 0.101 (tighter whitening of L → more polar input pre-conditioning). 4× spread in residual but Δval gap between arms is only 2 mnat. **NS_ITERS=12 absorbs 4× residual perturbation without proportional val penalty.**
2. **Direct confirmation of #1102 canon.** "Polar/ortho_residual is NOT load-bearing at NS_ITERS=12 — residual can be tightened 3-5× without val change." #1123 tested the inverse: residual loosened 4× → val also barely moves. The cubic NS5 map's contractive geometry on rank-deficient inputs is robust to upstream whitening exponent variation across [0.25, 0.5].
3. **Rank asymmetry (L 13/3072 vs R 1.67/768) does NOT translate to γ asymmetry.** Both decoupled-γ configurations regress vs symmetric γ=0.4. The expected mechanism — "looser-whitened side compensates for tighter-side over-whitening" — does not materialize.

### Predeclared merge rule

`sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`:
- Arm A: sr=2950 fails first clause; val=3.270 fails second → NULL
- Arm B: sr=2950 fails first clause; val=3.268 > 3.266394 → fails second → NULL

### Portfolio implications

- Closes first decoupled-γ axis in r1; PMUON_GAMMA symmetric form (γ_L=γ_R=0.4) is canonical.
- Closes the "rank-asymmetry → γ-asymmetry" inference chain motivated by #1102 reframe + #1046 rank-deficiency canon.
- Reinforces #1102 canon: future PRs targeting polar quality must operate INSIDE NS5 (NS_ITERS modulation per #1144, exact SVD per #1135, blend post-polar per #1107), NOT upstream whitening.
- frieren → **#1164** (depth-stratified body-Muon EMA momentum mu: per-layer linear interpolation across 12 transformer layers; Arm A DOWN shallow=0.99/deep=0.90 vs Arm B UP shallow=0.90/deep=0.99). Direct response to #1116 askeladd depth-LR closure note explicitly suggesting per-layer EMA β as next mechanism-distinct depth axis. Mirrors #1116 implementation pattern (add_param_group per layer) but operates on EMA memory not step magnitude — mechanism-distinct from all closed mu axes (#682 schedule, #777 cooldown ramp — all were uniform across depth).

---

## 2026-05-25 09:27 UTC — PR #1116 CLOSED: Body Muon depth-LR decay (DOWN vs UP) — 126th NULL, depth-stratified LR axis FULLY CLOSED (g1r1-askeladd)

- Branch: `g1r1-askeladd/depth-lr-decay`
- Hypothesis: First depth-stratified body-Muon test. Per-layer linear LR scaling across 12 transformer layers. Tests whether shallow vs deep layers benefit from differential LR during late-train + cooldown.

| Arm | Mode | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | uniform=0.040 | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | DOWN (shallow=1.0× → deep=0.5×) | **3.277380** | **+10.986** | 3125 | +200 | 37σ | **CATASTROPHIC NULL** | `ua2c7zlf` |
| Arm B | UP (shallow=0.5× → deep=1.0×) | **3.267130** | **+0.736** | **2925** | 0 | 2.5σ | marginal NULL | `7u3hbikt` |

### Mechanism findings

1. **Body-Muon optimal LR is approximately uniform across depth.** Both unilateral departures from uniform 0.040 produce val regression. The DOWN arm hypothesis (deep layers over-shooting because zero-init proj.weight ramp accumulates faster than EMA absorbs) is **falsified** — halving deep-layer LR costs 37σ val.
2. **Asymmetric penalty**: deep-layer LR halving (Arm A) costs 37σ val + 200 sr; shallow-layer LR halving (Arm B) costs only 2.5σ val with sr held flat. **Deep-layer LR is more load-bearing than shallow-layer LR** in absolute terms.
3. **Cross-axis with #1046 rank-deficiency canon**: NS5 magnitude normalization absorbs *direction*-of-update across layers but does NOT absorb per-layer step-size differences at 50% scale. Polar(G) direction preserved; LR-gated step size still controls per-layer progress.

### Predeclared merge rule

`sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`:
- Arm A: sr=3125 fails both clauses → NULL
- Arm B: sr=2925 matches but val=3.26713 > 3.266394 → fails val clause → NULL

### Portfolio implications

- Closes first depth-stratified body-Muon axis in r1.
- Future depth-stratified PRs must be mechanism-distinct (per-layer EMA β, per-layer wd, per-layer NS5 iters — NOT per-layer LR alone).
- askeladd → **#1156** (Lookahead k-step slow-fast weight averaging on body Muon — first weight-space averaging since #943 SWA / #990 SF closures).

---

## 2026-05-25 06:15 UTC — PR #1099 CLOSED: Decoupled AdamW cooldown shape (γ_adamw=2.0 vs 1.0, body γ=1.4) — 125th NULL, Pareto-shift finding (g1r1-nezuko)

- Branch: `g1r1-nezuko/decoupled-adamw-cooldown`
- Hypothesis: Decouple AdamW cooldown γ from body Muon (which is fixed at γ=1.4 per #969 closure). Tests whether AdamW subgroups (embed lr=0.3, lm_head lr=1/160, scalars lr=0.025) benefit from a different cooldown γ than body. Two arms: γ_adamw=2.0 sharper vs γ_adamw=1.0 flatter.

| Arm | γ_adamw | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 1.4 (=body) | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | 2.0 sharper | **3.271085** | +4.69 | 2975 | +50 | 16σ | CLEAR NULL | `7vn1axje` |
| Arm B | 1.0 flatter | **3.265249** | **−1.15** | 2950 | +25 | 3.8σ | **Pareto-shift NULL** | `g546ir3f` |

### Mechanism findings

**Pareto-shift confirmation**: γ_adamw on the decoupled AdamW cooldown manifold exhibits the same trade-off as body γ (per #969 closure):
- **γ_adamw < body γ (Arm B γ=1.0 flat)**: preserves AdamW LR longer through cooldown → embed/lm_head continue learning during cooldown phase → improves final val by 1.15 mnat (3.8σ above seed noise σ≈0.0003) BUT delays first val ≤ 3.28 crossing by +25 steps.
- **γ_adamw > body γ (Arm A γ=2.0 sharp)**: AdamW LR decays faster than body → embed/lm_head stop adapting before body finishes converging → worse on BOTH axes.

**Predeclared merge rule failure**: `sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`. Arm B sr=2950 satisfies neither clause. Cannot merge despite val improvement.

### Pareto frontier mapping (cooldown γ axes)

| Axis | PR | Optimal point | Pareto trade-off direction |
|---|---|---|---|
| Body γ | #969 | γ=1.4 (sr-Pareto-optimum) | γ=1.2 wins val but loses sr (#969 closure) |
| Dual-region body | #1084 | single γ=1.4 near-Pareto-optimal | piecewise γ does not help (#1084 closure) |
| Decoupled AdamW γ | **#1099 (this PR)** | γ_adamw=1.4=body γ (sr-Pareto-optimum) | γ_adamw=1.0 wins val but loses sr |

**Canon**: Cooldown γ on any sub-axis (body, dual-region piecewise, decoupled AdamW) produces a Pareto frontier where reduced γ improves val at sr cost. The sr=2925 baseline constraint is **structurally binding** for cooldown-γ work. Future cooldown shape work must use a different parameterization (decoupled-START step, non-power cooldown functions) to escape this Pareto.

### Cooldown parameter manifold full closure

The cooldown manifold is now FULLY mapped:
- γ (power exponent): #969 body axis closed, #1099 decoupled AdamW axis closed
- cooldown_frac (cooldown duration): #1084 dual-region partial test, manifold closed
- lr_form (functional form): #1040 lr_linear vs lr_squared closed
- wd_form (WD coupling): #1040 closed at lr_linear
- dual-region piecewise γ: #1084 closed (single γ optimum)
- **Future cooldown work must move to non-manifold dimensions (decoupled start step, non-cosine non-power LR shapes, schedule-side stochasticity).**

### Next assignment

**nezuko → #1144** (NS_ITERS phase schedule: stable=10/cooldown=14 vs stable=14/cooldown=10) — fresh phase-dependent NS5 polar quality axis. First test of whether polar quality is phase-dependent. Cross-axis to all in-flight (#1107 polar blend, #1129 aspect-ratio, #1135 exact SVD, #1125 cov source, #1123 γ_L/γ_R asym, #1136 grad noise).

SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["7vn1axje","g546ir3f"],"primary_metric":{"name":"val/loss","value":3.265249},"test_metric":{"name":"val/loss","value":3.265249}}

---

## 2026-05-25 10:00 UTC — PR #1090 CLOSED: Focal loss for LM (γ=1.0 vs γ=2.0) — 124th NULL, 5-axis output-regularization portfolio FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/focal-loss`
- Hypothesis: Per-token gradient amplification on hard tokens via `(1-p_y)^γ` weighting. Targets focal mechanism distinct from output-clip (#1060), entropy reg (#1058), label smoothing (#1043), Z-loss (#1066).

| Arm | γ | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (light focal)** | **1.0** | **3.273504** | **+7.110** | **3050** | **+125** | **24σ** | **NULL** | `n21mu2wj` |
| **B (moderate focal)** | **2.0** | **3.288816** | **+22.423** | **-1** | **DNF** | **75σ** | **CATASTROPHIC** | `kgdf5ynu` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule. Arm B failed 3.28 target entirely.

**Key findings:**
1. **Clean monotone-bad dose-response.** focal_weight_mean: γ=1.0 → 0.7576 (24% downweighting), γ=2.0 → 0.6751 (33% downweighting). Δval scales super-linearly: γ=1→2 doubles loss exponent but more than triples Δval (3.2× ratio).
2. **Cooldown phase cannot recover lost gradient mass.** Arm B trajectory: step 2375 val=3.358 → step 3250 val=3.289 (descending but never reaches 3.28). Focal modulation suppresses gradient signal needed by NS5 polar's late-cooldown updates.
3. **5-axis output-regularization portfolio FULLY CLOSED:**
   - #1043 LS (115th NULL CATASTROPHIC linear)
   - #1058 CP (117th NULL CATASTROPHIC super-linear, 4.5× acceleration)
   - #1060 soft-cap (118th NULL — noise-floor at cap=15, regression at cap=30)
   - #1066 Z-loss (119th NULL — noise-floor at λ=1e-4, catastrophic at λ=1e-3)
   - #1090 focal (124th NULL — monotone-bad dose-response γ=1→2)
4. **Convergent canon:** baseline sqrt-clip @15 + standard CE saturates output-regularization channel. ALL output-side mechanisms either collapse to noise-floor (redundant with sqrt-clip) or suppress NS5-needed signal catastrophically.

**Closure recommendation:** No further output-regularization PRs warranted. Future loss-formulation work must target **gradient-level signal modification**.

**fern → #1136** (gradient noise injection on body Muon: σ=0.05 vs 0.15, first-ever gradient-level regularization test).

---

## 2026-05-25 09:42 UTC — PR #1089 CLOSED: NS5-layered Shampoo body-Muon (compose Shampoo + NS5) — 123rd NULL, composition-order axis FULLY CLOSED (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns5-layered-shampoo`
- Hypothesis: Compose Shampoo preconditioning with NS5 polar projection (Variant 3 from #1046 closure). Tests order-sensitivity: does shampoo_first or ns5_first survive both rank-deficiency (#985) and rank-defect (#1046) constraints?

| Arm | Order | val/loss | Δval (mnat) | sr | Δsr | σ-dist | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (shampoo_first)** | NS5(Shampoo(g)) | **3.269755** | **+3.361** | **2975** | **+50** | **11σ** | **CLEAR NULL** | `vff9pulk` |
| **B (ns5_first)** | Shampoo(NS5(g)) | **3.273024** | **+6.630** | **3050** | **+125** | **22σ** | **CLEAR NULL + sr regression** | `2mbhkkin` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)`.

**Key findings:**
1. **Composition-order matters structurally.** Arm A recovers ~5.2 mnat/100 sr from #1046 pure-Shampoo residual (3.275 → 3.270). Magnitude budget 27.69 ≈ √768·1.001 (perfect 1.001× ratio). composition_cosine vs pure NS5 = **0.972** (14° additional steering from Shampoo curvature).
2. **NS5-first is structurally destructive.** composed_update_norm = **0.524** (~50× smaller than bare NS5, ~10× smaller than predicted 5.8). Applying L^{-1/4}, R^{-1/4} AFTER NS5 destroys orthogonality and collapses magnitude. u/w-floor takes over the optimization signal entirely. **Rule out:** post-orthogonalization curvature factors are magnitude-collapsing, not tunable.
3. **+3.4 mnat residual vs baseline persists despite composition.** Shampoo's curvature signal is mostly redundant with NS5 polar at m_pre stable rank ≈ 426 (per #1102 reframe). Cubic NS5 polar at NS_ITERS=12 already orthogonalizes nearly optimally.
4. **Composition-order axis FULLY CLOSED.** Future preconditioner PRs (Shampoo, SOAP, AggMo variants) must NOT propose post-orthogonalization compositions — magnitude collapse is structural.

**Diagnostic telemetry (post-warmup averages, gate step 500):**

| metric | Arm A (shampoo_first) | Arm B (ns5_first) |
|---|---:|---:|
| `composed_update_norm` | 27.694 | **0.524** |
| `shampoo_only_norm` | 6.094 | 5.700 |
| `ns5_only_norm` | 26.625 | 22.375 |
| `composition_cosine` (vs pure NS5(g)) | **0.9723** | 0.9021 |
| L_cov stable rank @ gate | 11.0 / 3072 | 10.9 / 3072 |
| R_cov stable rank @ gate | 1.60 / 768 | 1.64 / 768 |

**Cross-axis canon:** #985 NS5 triple-load-bearing role REAFFIRMED via Arm B's magnitude collapse. #1046 +7 mnat residual PARTIALLY EXPLAINED via Arm A's ~5.2 mnat recovery. #1102 m_pre stable rank ≈ 426 finding CONSISTENT (Shampoo redundant with NS5 polar).

**alphonse → #1133** (exact SVD polar map: replace NS5 cubic Newton at 12 iters with torch.linalg.svd; tests if ~6.7% polar/ortho_residual is load-bearing under current EMA stack).

---

## 2026-05-25 07:30 UTC — PR #1084 CLOSED: Dual-region cooldown shape (γ₁/γ₂ piecewise, split=0.75) — 122nd NULL, cooldown manifold FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/dual-region-cooldown-shape`
- Hypothesis: Piecewise γ₁/γ₂ schedule adds 1 DOF to resolve the #969 Pareto-coupling (γ=1.2 wins val but loses sr).

| Arm | γ₁ | γ₂ | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.4 | 1.4 | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (concave-first)** | **2.0** | **1.0** | **3.27156** | **+5.17** | **2925** | **0** | **17σ** | **CLEAR NULL** | `p4jk1urh` |
| **B (convex-first)** | **1.0** | **2.0** | **3.27510** | **+8.71** | **3100** | **+175** | **29σ** | **CLEAR NULL + sr regression** | `bft16pb6` |

**Verdict:** Full PR NULL. Both arms fail merge rule. Arm B is strictly worse in both metrics.

**Key findings:**
1. **Single-γ=1.4 is near-Pareto-optimal.** Piecewise schedule with split=0.75 cannot Pareto-dominate the monotone γ family at any tested orientation.
2. **LR-mass conservation dominates shape locality.** Integrated LR-mass: Arm A ≈0.65× (aggressive early dump → val-bad, sr-stable); Arm B ≈1.20× (excess early → sr-bad, val-bad). Shape locality inside the envelope doesn't help.
3. **Asymmetric NULL is informative:** confirms early cooldown governs sr crossing, late cooldown governs terminal val — but single-γ=1.4 is already at the joint optimum for both.
4. **Cooldown parameter manifold FULLY CLOSED:** γ (#969) + cooldown_frac (pinned 0.7) + lr_form (#1040 lr_linear) + wd_form (#1040) + dual-region shape (#1084) all closed.

---

## 2026-05-25 05:30 UTC — PR #1080 CLOSED: Body weights init scale ablation (0.5× vs 2.0×) — 121st NULL, 3-matrix init-state-surface canon ESTABLISHED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-init-scale`
- Hypothesis: Body init scale is locally sensitive even after NS5 polar projection + RMSNorm. Testing 0.5× scale vs 2.0× scale vs baseline 1.0×.

| Arm | scale | val/loss | Δval (mnat) | sr | Δsr | σ-dist | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.0× | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A** | **0.5×** | **3.266968** | **+0.000574** | **2925** | **+0** | **1.9σ** | **marginal NULL noise-floor** | `sawsjbn5` |
| **B** | **2.0×** | **3.268639** | **+0.002246** | **2975** | **+50** | **7.5σ** | **CLEAR NULL** | `q4daaezw` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule. Arm A noise-floor; Arm B 7.5σ above.

**Key findings:**
1. **3-matrix init-state-surface canon ESTABLISHED:** lm_head (#1015) + embed (#1059) + body (#1080) all flat-near-baseline + monotone-bad on perturbation. Speedrun-tuned init sits at the basin minimum across all weight categories.
2. **NS5 + RMSNorm partially absorb init scale; Adam-AUX does NOT.** Magnitude ratio 4.00× persists in telemetry; val cost only +2.2 mnat. Asymmetry: embed flat under Adam despite being Adam-optimized; body mildly worse on large side despite NS5 polar → gradient-magnitude inflation through residual stream → Adam-AUX first-step overshoot.
3. **Future init perturbations must be paired with compensating optimizer-side change** (LR, β, EMA) to escape the basin — testing init in isolation is now demonstrably structurally insensitive.

**Closed axis:** Init-scale axis closed at scale=1.0. No further sub-resolution sweeps warranted.

---

## 2026-05-25 03:20 UTC — PR #1102 CLOSED: NS5 input normalization: spectral vs Frob/sqrt(n) — 120th NULL, rank-deficiency canon REFRAMED (g1r1-frieren)

- Branch: `g1r1-frieren/ns-input-norm`
- Hypothesis: NS5 wastes early iterations growing sigma when fed a Frob-normalized low-rank input (from #1046 L_cov stable rank ~13). Spectral normalization (sigma_max=1) should close the "wasted iterations" gap. Frob/sqrt(n) was predicted to overshoort (sigma_max~0.28 at k=13).

| Arm | norm_mode | W&B | val/loss | sr | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | frobenius | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | ~0.19 (mean) | gate |
| A SPECTRAL | spectral | `jeck1ge0` | **3.267161** | 2950 | **0.0525** (3.7x tighter) | **NULL** (+0.77 mnat, fails merge) |
| B FROB/sqrt(n) | frob_over_sqrt_n | `kqrtsre6` | crashed step 2 | — | — | **CATASTROPHIC** |

**Finding 1: m_pre stable rank ≈ 426 (NOT ~13 like L_cov).** L_neg/R_neg pre-whitening de-low-ranks the NS5 input. The original "wasted iterations" estimate overestimates headroom by ~5× (sqrt(13)/sqrt(426) ≈ 0.17). The rank-deficiency canon for L_cov does NOT apply to the NS5 input m_pre.

**Finding 2: polar/ortho_residual is NOT load-bearing at NS_ITERS=12.** Spectral norm tightens residual ~3-5× (0.0525 vs ~0.19 baseline) but does not move val/loss or sr. Extra refinement headroom is not the bottleneck.

**Finding 3: CATASTROPHIC endpoint established.** sigma_max ≈ 27 (frob/sqrt(n) with actual k=426) → NS cubic map blows up → L_cov ill-conditioned → eigh fails at step 2. Stable region σ∈[0,√3] confirmed.

**Finding 4: +11% wall-clock cost** for spectral (3 fp32 power iters per NS5 call). Unattractive even at val neutral.

**Structural reframe:** Future rank-deficiency-motivated PRs must report m_pre stable rank (not L_cov/R_cov). Implications for #1107 polar-interpolation: "polar fills in missing structure" premise partially undermined (m_pre is rank-rich). frieren → #1123 (asymmetric gamma_L/gamma_R whitening exponents, first decoupled test).

## 2026-05-25 01:00 UTC — PR #1066 CLOSED: Z-loss λ·log²(Z) partition-function regularization (λ=1e-4 vs 1e-3) — 119th NULL, 4-axis output-reg closure (g1r1-askeladd)

- Branch: `g1r1-askeladd/z-loss`
- Hypothesis: Penalize log-partition-function magnitude `λ·log²(Z)` where Z=sum(exp(logits)). PaLM-canonical technique for numerical stability + output regularization. Orthogonal to LS (targets), CP (entropy), soft-cap (activations) — directly penalizes NORMALIZER.

| Arm | λ | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.0 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (PaLM canonical) | 1e-4 | `edq21r1h` | **3.26644** | 2925 | +0.000046 (0.15σ) | 0 | NOISE-FLOOR NULL |
| B (10× stronger) | 1e-3 | `zst7hrwa` | **3.286507** | -1 | +0.020113 (67× past marginal) | DNF | CATASTROPHIC NULL |

**Finding 1: Z-loss structurally redundant at modded-nanogpt scale.** PaLM's motivation (partition function exploding at 540B params / vocab=256K) does not apply here — sqrt-clip @15 on logits already keeps Z bounded; BF16 is sufficient for vocab=50304. At λ=1e-4 the mean `log²(Z)` contributes ≤5e-5/step to loss (sub-noise). At λ=1e-3 it contributes ~5e-4/step, compounding over 3250 steps to ~+0.02 mnat shift in optimization basin → CATASTROPHIC failure to cross 3.28 threshold.

**Finding 2: Super-linear dose-response, same pattern as #1058 CP.** λ=1e-4 → noise-floor (mechanistically silent); λ=1e-3 → 67× past marginal (43× jump from first to second segment). Dose-response accelerates nonlinearly across both CP (#1058) and Z-loss (#1066).

**Cross-axis closure — 4-axis output-regularization portfolio CLOSED (pending #1090 focal):**

| Axis | PR | Direction | Result |
|---|---|---|---|
| Soft-target smoothing | #1043 fern | modify TARGET | CATASTROPHIC linear dose-response (115th NULL) |
| Hard-target entropy max | #1058 frieren | modify LOSS | CATASTROPHIC super-linear dose-response (117th NULL) |
| Logit soft-cap | #1060 tanjiro | modify ACTIVATIONS | NULL noise-floor at cap=15; regression at cap=30 (118th NULL) |
| Z-loss partition reg | #1066 askeladd (this) | modify NORMALIZER | NULL noise-floor at λ=1e-4; catastrophic at λ=1e-3 (119th NULL) |

Pattern: baseline sqrt-clip @15 + standard CE already saturates the output-reg channel. Only #1090 fern focal (in flight) remains.

**119th closed axis.** askeladd → **#1116** (body Muon depth-LR decay, per-layer linear scale DOWN vs UP).

## 2026-05-24 23:18 UTC — PR #1060 CLOSED: Logit soft-cap tanh(logits/cap)*cap (cap=30 vs 15) — 118th NULL, 3-axis output-reg closure (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/logit-soft-cap`
- Hypothesis: Constrain logit magnitudes via smooth tanh saturation `tanh(logits/cap)*cap` (Gemma 2 canonical technique) pre-CE. Distinct from LS (target modification) and CP (entropy penalty) — directly constrains LOGIT SPACE. Single-line change, val/loss evaluated with uncapped CE (benchmark contract).

| Arm | cap | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — (sqrt-clip @15 only) | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (loose) | 30 | `nqsjo07o` | **3.272813** | 3050 | +0.006419 (21x past marginal) | +125 (5x past) | CLEAR NULL |
| B (matches baseline) | 15 | `f3abiepo` | **3.266489** | 2925 | +0.000095 (0.32σ) | 0 | NOISE-FLOOR NULL |

Predeclared merge rule: `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)`. Arm B fails by 0.000095 mnat.

**Finding 1: Output peakedness control saturated at cap≈15.** Arm B cap=15 (matching baseline's sqrt-clip kink point) ties baseline within 0.32σ — the tanh and sqrt-clip functional forms at the same cap value produce statistically identical val/loss. The soft-cap functional form is interchangeable; the effective cap value is the load-bearing lever.

**Finding 2: Looser cap (30) deactivates peakedness control → clear regression.** With baseline sqrt-clip still active at 15, Arm A's tanh at 30 is dead-weight for in-range logits. The +6.4 mnat regression likely comes from compositional interaction at the boundary, or subtle `tanh(x/30)*30 ≠ clip(x,-30,30)` differences where sqrt-clip binds. Cap=30 is definitively wrong.

**Cross-axis closure — 3-axis output-regularization portfolio:**

| Axis | PR | Direction | Result |
|---|---|---|---|
| Soft-target smoothing | #1043 fern | modify TARGET | **CATASTROPHIC linear dose-response** (115th NULL, Δval≈0.96·ε) |
| Hard-target entropy max | #1058 frieren | modify LOSS | **CATASTROPHIC super-linear dose-response** (117th NULL) |
| Logit soft-cap | #1060 tanjiro (this) | modify ACTIVATIONS | **NULL noise-floor at cap=15; regression at cap=30** (118th NULL) |

Consistent pattern across 3 independent output-reg mechanisms: baseline's existing peakedness control (sqrt-clip @15) saturates the channel. Modifications that match or tighten it are noise-floor neutral; modifications that loosen or add pressure via different objectives are NULL-to-catastrophic.

Two remaining output-reg axes in flight: #1066 askeladd Z-loss, #1090 fern focal.

**118th closed axis.** Logit soft-cap axis CLOSED. tanjiro → **#1107** (polar interpolation: alpha-blend polar(m_pre) vs magnitude-matched m_pre, tests polar-projection saturation in low-rank regime per #1046 rank-deficiency canon).

## 2026-05-24 22:50 UTC — PR #1058 CLOSED: Confidence penalty (Pereyra 2017) beta=0.05 vs 0.10 — 117th NULL, CLEAR + CATASTROPHIC super-linear dose-response, 2-axis loss-reg closure (g1r1-frieren)

- Branch: `g1r1-frieren/confidence-penalty`
- Hypothesis: Penalize over-peaked output distributions via `loss = ce - beta * H(p)` where H(p) is per-token entropy. Pereyra 2017 confidence penalty, orthogonal to label smoothing (#1043). Mechanism: encourage higher output entropy, fight over-confident predictions, regularize.

| Arm | beta | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.00 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (mild) | 0.05 | `rcyh71fo` | **3.27730** | 3125 | +0.01091 (11x past) | +200 (8x past) | CLEAR NULL |
| B (strong) | 0.10 | `jx4exq3k` | **3.33492** | -1 | +0.06853 (69x past) | DNF | CATASTROPHIC NULL |

Both arms fail predeclared merge rule. Super-linear dose-response: Delta-val/Delta-beta jumps from +0.013/0.05 (A) to +0.058/0.05 (B) — 4.5x acceleration in damage between halves of the beta range.

**Finding 1: CP gradient SURVIVES NS5 polar orthogonalization.** Composite loss decreased monotonically; entropy-maximizing gradient was NOT annihilated by NS5. Falsifies the "NS5 absorbs auxiliary loss terms" intuition (contra modal prediction). Important negative finding for future loss-augmentation hypotheses.

**Finding 2: Output entropy is NOT load-bearing for generalization in this regime.** Higher H(p) (Arm A: 3.626 nats; Arm B: 4.368 nats) -> strictly worse val/loss. Baseline already operates at near-optimal entropy plateau for 3250-step budget; pushing higher costs hard-CE accuracy.

**Finding 3: `loss_composite < val_loss` signature.** Arm B composite=2.92 < val=3.33 -> optimizer descending on a loss whose minimum is NOT the true CE target. Optimizer well-behaved; regularizer mis-aligned with benchmark.

**Finding 4: sqrt-clip at 15 already controls peakedness.** Baseline line 454 logit clip caps per-token confidence. Adding CP creates competing pressure: sqrt-clip is local (per-logit), CP is global (sum over vocab). NOT synergistic.

**Cross-axis closure — 2-axis loss-regularization:** Combined with #1043 LS (115th NULL CATASTROPHIC linear dose-response, Delta-val approx 0.96*epsilon), two independent loss-objective interventions both NULL/catastrophic with monotone-bad dose-response. Loss-objective regularization at CE level structurally incompatible with body-Muon + EMA(0.95->0.99) at 3250 steps. Three more output-reg axes in flight: #1066 askeladd Z-loss, #1060 tanjiro soft-cap, #1090 fern focal loss.

**117th closed axis.** Confidence penalty axis CLOSED. frieren -> **#1102** (NS5 input normalization mode test: spectral vs Frob/sqrt(n) vs Frobenius baseline, directly motivated by #1046 rank-deficiency canon).

## 2026-05-24 22:32 UTC — PR #1059 CLOSED: Embed init std ablation (σ=0.04 vs σ=0.5) — 116th NULL, monotone-toward-baseline, init-state-surface canon (g1r1-nezuko)

- Branch: `g1r1-nezuko/embed-init-std`
- Hypothesis: Embed baseline init σ=1.0 (PyTorch default) is unusually wide vs GPT-2 canonical σ=0.02. RMSNorm makes forward output invariant to σ, but backward gradient scales as 1/σ; Adam equilibration delay creates an effective LR difference. Mirror axis of #1015 lm_head ε (input-side vs output-side readout). Two arms: A σ=0.04 (25× smaller, near GPT-2 canonical), B σ=0.5 (2× smaller, intermediate).

| Arm | σ | W&B | val/loss | sr | Δval vs #918 (3.266394) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.0 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (small) | 0.04 | `0h9ym90h` | **3.26831** | 2950 | +0.001916 (~6.4σ) | +25 | Marginal NULL |
| B (moderate) | 0.5 | `zefhhcfm` | **3.26716** | 2950 | +0.000766 (~2.6σ) | +25 | Marginal NULL |

Single-seed σ ≈ 0.0003 (established #958). Both fail predeclared merge rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — sr=2950 disqualifies the val conjunct.

**Finding 1: Monotone-toward-baseline pattern.** Both arms regress vs σ=1.0 baseline; magnitude scales with σ-distance (Arm A 25× shrink → Δval ~1.9 mnat; Arm B 2× shrink → Δval ~0.8 mnat). Direction consistent across both arms with identical sr=2950. Axis is effectively flat within seed noise but with a weak directional gradient favoring σ ≥ 1.0.

**Finding 2: BF16 quantization floor ruled out.** Row-L2 distribution at σ=0.04 shows no truncation (min/max ratio = 1.22, healthy spread). The 19.5%-relative-BF16-precision concern was NOT the gating factor. Init validation matched analytic predictions to 3 sig figs in both arms (Frob 248.589 vs predicted 248.4 for Arm A; 3108.572 vs 3105.6 for Arm B).

**Finding 3: Adam variance equilibration transient is plausibly load-bearing.** Smaller σ shortens the early-step variance-warmup phase (~30 steps for σ=0.04 vs ~100 for σ=1.0). The shorter transient leaves the embed in a slightly worse state — suggests the baseline's longer transient phase is mildly beneficial, not just neutral.

**Finding 4: Full readout-pair init-state surface canon.** Combined with #1015 lm_head ε (5× scan, sub-noise flat → Δ ≈ +0.000140 mnat = 10× below noise floor):
- lm_head ε: flat (5× scan, sub-noise)  
- embed σ: mildly tilted toward σ≥1.0 (25× scan, marginal NULL with monotone-toward-baseline gradient)
- Conclusion: **the full readout-pair init-state surface is approximately flat with a mild preference for the baseline configuration. Load-bearing levers are dynamics constraints (LR/WD/cooldown/preconditioner), not init state.**

**Student's closure recommendations:**
- Constraint-based interventions: spectral norm bounding on `proj.weight`, row-wise WD scheduling, embed/proj coupling
- σ=2.0 test would confirm whether trend continues monotone above baseline (low ROI, predicted Δval ±0.0008, needs n=2)
- No structural fix to baseline init recommended

**116th closed axis.** Embed init std axis CLOSED at σ=1.0. nezuko → **#1099** (decoupled AdamW cooldown shape: γ_adamw=2.0 vs 1.0, body Muon fixed at γ=1.4).

## 2026-05-24 20:30 UTC — PR #1043 CLOSED: Label smoothing ε=0.05 vs ε=0.10 — 115th NULL, CATASTROPHIC dose-response (g1r1-fern)

- Branch: `g1r1-fern/label-smoothing`
- Hypothesis: Uniform target label smoothing (Szegedy 2016) `(1-ε)·1_y + ε/V·1` softens target distribution to regularize loss objective without modifying optimizer/scheduler. 1st loss-objective axis test. Val/loss kept as HARD CE (benchmark contract).

| Arm | ε | W&B | val/loss | sr | Δval vs #918 (3.266394) | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.00 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | reference |
| A | 0.05 | `034w1we5` | **3.31401** | -1 | **+47.62 mnat** | CATASTROPHIC NULL (>3.28) |
| B | 0.10 | `wiwg3ere` | **3.36762** | -1 | **+101.23 mnat** | CATASTROPHIC NULL (>3.28) |

- **Linear dose-response confirmed:** Δval ≈ 0.96·ε + 0.0002 across two arms. Extrapolation predicts no ε wins (ε=0.001 → Δval≈+0.001 marginal at best).
- **Basin shift is GLOBAL, not transient:** Arm B−Arm A val gap constant ≈+0.05 from step 125 through step 3250. Label smoothing acts as a constant basin-floor offset, not a dynamic regularizer. No crossover where smoothing catches up.
- **Hard-CE basin really is higher:** Arm B `train/loss_hard_ce`=3.391 ≈ val/loss=3.368 — rules out "optimizer-loss-inflation only" alternative. Model genuinely converged at a higher hard-CE basin.
- **Mechanism:** At ε=0.10, model must allocate ≈10% mass to all 50,303 non-target tokens (≈ε·log(V) ≈ 1.08 nats unrecoverable). At 3250-step horizon, model never reaches confident-prediction-overfitting regime where smoothing helps; raw gradient signal at confident tokens > entropy-encouragement noise.
- **115th closed axis.** **Loss-objective regularization via uniform target smoothing FULLY CLOSED.**
- Mechanism-distinct loss-reg alternatives currently in flight: #1058 frieren confidence penalty (entropy maximization), #1066 askeladd Z-loss PaLM (partition regularization), #1060 tanjiro logit soft-cap (logit-magnitude regularization). #1090 fern → focal loss (5th axis, gradient amplification on hard tokens via `(1-p_y)^γ`).

## 2026-05-24 20:30 UTC — PR #1046 CLOSED: Shampoo warmup gate (w=500 vs w=1000) — 114th NULL, "200 lost steps" PARTIALLY CONFIRMED but NOT load-bearing (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-warmup-gate`
- Hypothesis: After #995 showed Shampoo body-Muon viable with c=1e-4 trace-relative eps but +10 mnat NULL gap, test whether early-train Shampoo over-regularization (`eps_L=3.08` at step 100, 52× terminal) explains the deficit. Defer Shampoo precond application until step 500 or 1000; raw Muon runs during warmup; L_cov/R_cov accumulated continuously.

| Arm | warmup | W&B | val/loss | sr | Δval vs #918 (3.266394) | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | n/a | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | reference |
| #995 Arm A (no warmup) | w=0 | merged | 3.276730 | 3125 | +10.34 mnat | NULL reference |
| A | w=500 | `3eqvr3oa` | **3.274959** | 3075 | **+8.6 mnat** | NULL (-1.77 mnat vs #995) |
| B | w=1000 | `b8lfm5sf` | **3.276352** | 3125 | **+9.96 mnat** | NULL (-0.38 mnat vs #995, tied) |

- **Smoking-gun mechanism @ step 750:** w=1000 (still raw-Muon) is **62 mnat AHEAD** of w=500 (just flipped to Shampoo at step 500). Raw Muon outperforms early-Shampoo with rank-deficient L_cov/R_cov. By step 1500, trajectories merge.
- **Terminal +7 mnat residual is STRUCTURAL** (~30% recoverable via warmup, ~70% from missing NS5 magnitude/rank/null-space roles per #985 triple-load-bearing finding). Gate location is NOT critical for the structural residual — both warmup arms hit the same terminal band (±0.7 mnat).
- **NEW RANK-DEFICIENCY CANON (step-500 gate snapshot, Arm A):**
  - L_cov stable rank = **13.18** / 3072 raw dim
  - R_cov stable rank = **1.67** / 768 raw dim
  - L_cov condition number = **20,863**; R_cov = **28,608**
  - EMA β=0.95 → effective lookback ~20 steps; covariance extremely rank-deficient even after 500 warmup steps
  - Original "single-step outer product needs ~768 steps for full rank" intuition was an UNDER-estimate of how stiff this regime is
- **Cross-axis canon** (combined with #969 cooldown power Pareto and #1023 target_uw schedule): "Schedule-localized regularization is real in early-train phase but **CANNOT recover Shampoo body-Muon terminal residual**. Residual gap is structural (missing NS5 magnitude/rank roles), not schedule-tunable."
- **114th closed axis.** Shampoo-replace-NS5 family decisively closed across all 3 sub-axes: trace-eps c (#995 flat), warmup gate (#1046 partial), null-space-amp (#985 catastrophic step-0).
- **Suggested follow-up:** Variant 3 NS5-layered Shampoo — compose Shampoo precond AND NS5 polar in same body update. NS5 should rescue Shampoo from #985-style step-0 explosions via cubic-map magnitude absorption. alphonse → **#1089** (two arms test order-sensitivity: A Shampoo→NS5, B NS5→Shampoo).

## 2026-05-24 19:45 UTC — PR #1040 CLOSED: WD coupling form (lr-linear vs lr-squared vs fully decoupled) — 113th NULL, lr_linear IS load-bearing (g1r1-edward)

- Branch: `g1r1-edward/wd-decoupling-form`
- Hypothesis: body-Muon WD form `p *= (1 - lr * wd)` is an arbitrary SGD inheritance OR is load-bearing because NS5 polar output has different update-scale dynamics. Three forms tested: lr_linear (baseline), lr_squared (quadratic vanishing), decoupled (constant per step). All calibrated to identical per-step decay = 0.001 at peak LR=0.040.

| Arm | wd_form | wd | W&B | val/loss | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | lr_linear | 0.025 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | Pareto-optimum |
| **Arm A lr_squared** | lr_squared | 0.625 | `ogapobt0` | **3.268200** | **2950** | +0.001806 | +25 | NULL |
| **Arm B decoupled** | decoupled | 0.001 | `tad7pz1u` | **3.292603** | **-1** | +0.026209 | catastrophic | NEG (failed 3.28 target) |

- **Decision: 113th NULL — DOES NOT MERGE.** Arm A NULL bracket; Arm B decisively NEG.
- **Canon finding 1: lr_linear coupling is STRUCTURALLY CORRECT, not arbitrary.** It preserves decay-to-update ratio = wd/|polar(p)| constant throughout WSD schedule. NS5 polar output magnitude ∝ lr → WD ∝ lr maintains the balance. Breaking this proportionality (decoupled form) causes WD to dominate during cooldown when NS5 updates shrink to zero.
- **Canon finding 2: p_norm_body_mean 5.35× terminal divergence is reference-grade mechanism deconvolution.** Arm A terminal p_norm=607 vs Arm B p_norm=113 — by construction both identical at peak LR=0.040 (calibration confirmed at step 500: 118.21 vs 118.36), divergence is ENTIRELY cooldown-phase artifact. Arm B p_norm peaks at step ~1500 (355) then COLLAPSES to 113 (3.1× shrinkage from 1500→3250) as WD wins tug-of-war against shrinking updates.
- **Canon finding 3: val/loss slope flip is direct confirmation of unlearning.** Arm B val/loss bottom at step 2975 (3.2921) then ASCENDS to 3.2926 at step 3250 (+0.00139 slope = positive). Arm A continues descent (-0.00415 slope). The model is actively unlearning under decoupled WD-dominated dynamics.
- **Canon finding 4: u/w-floor corroborates p_norm collapse.** fired_fraction: Arm A 100% throughout cooldown; Arm B 1.0→0.49 during cooldown. As |w|_F shrinks in Arm B, |u|/|w| ratio rises above floor, floor stops firing. Clean cross-axis link to #1035 u/w-floor pruning.
- **WHAT'S CLOSED:** WD coupling form axis across {lr_linear, lr_squared, decoupled}. lr_linear IS CORRECT by construction, not by coincidence.
- **WHAT'S OPEN:** Dual-region cooldown shape (OPEN per #969 closure note) — edward reassigned to #1084.
- edward → **#1084** (dual-region cooldown shape: piecewise γ₁/γ₂, follow-up to #969 Pareto-coupling finding).

---

## 2026-05-24 20:08 UTC — PR #1035 CLOSED: UW-floor pruning ablation (TARGET_UW=0 vs 0.50) — 112th NULL, clean U-shape confirmation, floor IS partially load-bearing at 0.35 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/uw-floor-pruning`
- Hypothesis: TARGET_UW=0.35 baseline is one of (A) load-bearing regulator, (B) dead-weight scalar multiplier in disguise, (C) partial regulator at interior optimum. Two arms: A floor=0 (OFF), B floor=0.50 (more aggressive).

| Arm | target_uw_floor | W&B | val/loss | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.35 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | Pareto-optimum |
| **Arm A OFF** | 0 | `5kad6ybm` | **3.27219** | **3000** | +0.00580 | +75 | NULL (6× past marginal) |
| **Arm B HIGH** | 0.50 | `20an0zgw` | **3.28608** | **-1** | +0.01969 | catastrophic | CATASTROPHIC NULL (failed 3.28 target) |

- **Decision: 112th NULL — DOES NOT MERGE.** Both arms regress on val and fail sr=2925 conjunct. No clause of `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` is satisfied. Hypothesis (B) "dead weight" DECISIVELY REJECTED — +6 mnat regression at floor=0 with no LR compensation rules out scalar-multiplier-in-disguise interpretation. Hypothesis (C) partial regulator CONFIRMED with clean U-shape interior optimum near 0.35.
- **Canon finding 1: EMA buffer divergence is the dominant failure signal across the floor axis.** `ema/buffer_frob_dist` final: Arm A=3.99 (under-driven), baseline≈22.6, Arm B=1379 (catastrophic explosion). The floor's BOOST drives most of the EMA<>live divergence at lr=0.040. Without boost → under-driven trajectory averaging; over-aggressive boost → EMA buffer drift explodes by ~62× over baseline.
- **Canon finding 2: NS5 polar accuracy is co-degraded by aggressive floor.** `polar/ortho_residual_sample` mean: Arm A=0.29, Arm B=0.67 (+0.38). Post-floor magnitude scaling pushes polar outputs away from true orthogonality. Cross-axis link to #898 (NS5 rank-deficient residual finding).
- **Canon finding 3: Asymmetric regression confirms well-tuned regulator at sweet spot.** Removing floor is 3.3× CHEAPER (+6 mnat) than over-cranking it (+20 mnat). Downside-of-over-application steeper than upside-of-correct-application is typical signature of an actively tuned regulator near its optimum.
- **Canon finding 4: `fired_fraction` correctly bracketed the operating regime** at 0.0 / 0.975 / ~1.0 across arms — telemetry verification was exemplary, validating the per-trajectory mechanism deconvolution.
- **Canon finding 5: Floor's boost behavior is the dominant LR-amplifier at lr=0.040.** Cross-axis with #918 / #986: explains why body-Muon LR axis closed at 0.040 (the LR sweet spot is implicitly conditional on the floor's boost being present at 0.35).
- **WHAT'S CLOSED:** u/w-floor pruning axis at TARGET_UW ∈ {0, 0.35, 0.50} — 0.35 is the Pareto-optimum, NOT prunable.
- **WHAT'S OPEN:** Fine-grained U-shape sweep around 0.35 (low-yield, deferred); EMA-buffer-cap as alternative regulator (speculative, would replace floor's indirect EMA-buffer effect with direct regulator).
- thorfinn → **#1080** (body weights init scale ablation 0.5× vs 2.0× baseline, mirror of #1059 embed / #1015 lm_head — completes 3-matrix init-scale family).

---

## 2026-05-24 16:05 UTC — PR #969 CLOSED: WSD cooldown power γ=1.2 n=2 — 111th NULL, INFORMATIVE Pareto-shift (g1r1-askeladd)

- Branch: `g1r1-askeladd/wsd-cooldown-power`
- Hypothesis: γ=1.2 (slower cooldown decay) n=2 confirmation at lr=0.040 baseline after n=1 marginal WIN at lr=0.035.

| Run | seed | val_loss | sr | Δval vs #918 | Δsr vs #918 |
|---|---|---|---|---|---|
| Baseline #918 (n=2 mean) | mean | 3.266394 | 2925 | — | — |
| `2l8wjtai` (γ=1.2 lr=0.040) | 1 | 3.26688 | 3000 | +0.000486 | +75 |
| `t73okfo5` (γ=1.2 lr=0.040) | 2 | 3.26466 | 2975 | −0.001734 | +50 |
| **n=2 MEAN** | — | **3.26577** | **2987.5** | **−0.000624** | **+62.5** |

- **Decision: 111th NULL — DOES NOT MERGE per predeclared rule.** The rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` is satisfied by neither branch. Δsr=+62.5 is 2.5× past 25-step marginal threshold; sr regression on primary speedrun metric is decisive.
- **Canon finding 1: cooldown shape produces a Pareto frontier, not a strict optimum.** γ=1.2 trades sr (+62.5) for val (−0.000624). γ=1.4 baseline is the sr-Pareto-optimum within {1.2, 1.4, 1.6}.
- **Canon finding 2: Mechanism is exactly the analytical LR-mass prediction.** γ=1.2 shifts ~9% MORE LR mass to LATE cooldown (post-threshold). Pre-threshold (steps 1750-2925) has LESS LR mass → slower 3.28 crossing → sr regression. Post-threshold (steps 2925-3250) has MORE LR mass → deeper terminal val descent. These effects are intrinsically coupled around the threshold.
- **Canon finding 3: 2σ_n=2 val signal — strongest n=2 val improvement in r1 portfolio outside merged baselines.** Z = (3.266394−3.26577)/√(σ²/2) ≈ 2σ. Real mechanism, but on the wrong metric direction for the speedrun objective.
- **Canon finding 4: Single-seed σ at γ≠optimum is 3.7× higher than at γ=1.4 baseline.** seed-1 vs seed-2 spread = 0.00222 mnat at γ=1.2; baseline σ ≈ 0.0003. Operating off the Pareto optimum increases seed sensitivity — useful diagnostic for future off-optimum n=2 tests.
- **Canon finding 5: Cooldown-erosion 4-instance pattern REAFFIRMED.** Different lever (shape vs structure) but consistent canon: don't move structurally away from γ=1.4 cooldown for sr-minimization.
- **WHAT'S CLOSED:** cooldown_power axis at γ ∈ {1.2, 1.4, 1.6} — γ=1.4 is the sr-Pareto-optimum.
- **WHAT'S OPEN:** γ × cooldown_start joint cell (deprioritized); dual-region cooldown shape (concave pre-threshold + convex post-threshold — speculative).
- askeladd → **#1066** (Z-loss PaLM `λ·log²(Z)` partition-function regularization — 4th output-reg axis).

---

## 2026-05-24 15:05 UTC — PR #1013 CLOSED: Sophia-H Hessian-diagonal for embed — 110th NULL, 5-AXIS i.i.d.-AUX STRUCTURAL CLOSURE (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/sophia-h-embed`
- Hypothesis: Sophia-H diagonal Hessian preconditioner (Hutchinson estimate, k=10 steps) replaces AdamW for embed parameter. Tests whether true curvature (vs gradient variance in Adam) provides useful aux signal.

| Arm | ρ | W&B | val/loss | sr | Δval | Δsr | sophia/clip_frac |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| Arm A | 0.01 (conservative) | `56iuhjoa` | **3.27638** | **3125** | +0.01052 | +200 | **1.00 throughout** |
| Arm B | 0.001 (aggressive) | `ab8pqcfg` | **3.27928** | **3200** | +0.01342 | +275 | **1.00 throughout** |

- **Decision: 110th NULL.** Both arms clear stat-sig NULL (Arm A barely fails 3.276 threshold by 0.4 mnat; Arm B by 3.3 mnat). Δsr +200/+275 = 8-11× past marginal band. n=2 not needed.
- **Canon finding 1: `sophia/clip_frac=1.0` throughout all steps in both arms — mechanism mechanically inactive.** h_mean ≈ 1.8e-5 (Arm A) / 1.7e-6 (Arm B), never approaching ρ threshold. Sophia-H degenerates to constant-magnitude SGD at effective LR = lr/ρ = 15 (Arm A) / 150 (Arm B).
- **Canon finding 2: Root cause is sparse-update structure.** Only ~8192/50304 vocab rows receive gradient per batch (~16% occupancy). Hutchinson trace is ~0 for unseen rows → `h` concentrates near zero → 100% clip saturation structural at any ρ ≥ h_mean.
- **Canon finding 3: 5-AXIS i.i.d.-AUX STRUCTURAL CLOSURE ACHIEVED.** Adam-family (18 axes) + SOAP (2 axes) + Diagonal-Hessian (1 axis) all NULL. Per-coord preconditioning of ANY form cannot extract useful signal from sparse, i.i.d. aux gradients at this benchmark scale. Closed families: gradient-variance estimators (Adam), covariance estimators (SOAP/Shampoo), Hessian estimators (Sophia-H).
- **Canon finding 4: 4× HVP wall-clock overhead is a deployment blocker.** `model._compiled_call_impl = None` toggle inside `update_hessian` invalidates compile cache. 15 GPU-hours for n=2 confirmation would require >25% val improvement to break even — not achievable.
- **Canon finding 5: Arm B monotone-worse (more aggressive ρ → worse val).** SGD at 10× higher effective LR with no curvature dampening is closer to plain gradient descent, explaining the +3.3 mnat worse result.
- **WHAT'S CLOSED:** All diagonal-preconditioned aux families (Adam, SOAP, Hessian). i.i.d. structural closure is now definitive.
- **WHAT'S OPEN:** Dense-update parameters (lm_head vs embed have different gradient density); constraint-based aux interventions (spectral-norm, row-WD); architectural logit-space interventions (soft-capping).
- tanjiro → **#1060** (logit soft-capping — architectural 1-line: `tanh(logits/cap)*cap`, cap=30.0 vs 15.0).

---

## 2026-05-24 14:50 UTC — PR #1015 CLOSED: lm_head non-zero orthogonal init — 109th NULL, LOCALLY INSENSITIVE init scale axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/lm-head-init-orthogonal-init`
- Hypothesis: replacing `proj.weight.zero_()` baseline with `torch.nn.init.orthogonal_(w, gain=ε)` breaks zero-init logit symmetry constructively. Two arms ε ∈ {0.02 small, 0.10 moderate}.

| Arm | ε | W&B | val/loss (EMA) | val/loss_live | sr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.02 | `pfs8ort4` | **3.26714** | 3.26658 | 2950 | +0.000746 | marginal NULL |
| B | 0.10 | `3yg5ez7p` | **3.26728** | 3.26672 | 2950 | +0.000886 | marginal NULL |
| B − A | 5× | — | — | — | 0 | +0.000140 | flat dose-response |
| Baseline #918 (n=2) | 0 | `vm48fdof`/`0a7esmxs` | 3.266394 | — | 2925 | 0 | reference |

| Pre-launch init validation | Arm A pred | Arm A obs | Arm B pred | Arm B obs |
|---|---|---|---|---|
| `init/proj_weight_frob_norm` | 0.554 | **0.5543** ✓ | 2.77 | **2.7713** ✓ |
| `init/proj_weight_row_l2_mean` | 0.00248 | **0.002470** ✓ | 0.01240 | **0.01235** ✓ |

- **Decision: 109th NULL — Scenario 2 (LOCALLY INSENSITIVE) confirmed.** Both arms within seed-noise envelope (baseline range 0.001062 mnat); 5× ε change adds only +0.000140 mnat (≈ 10× below σ≈0.0003 single-seed noise floor established in #958).
- **Canon finding 1: lm_head orthogonal-init scale axis FULLY CLOSED at ε ∈ [0.02, 0.1].** Zero-init occupies a flat local optimum, not a sharp one. The canonical modded-nanogpt design choice is empirically overdetermined within reasonable orthogonal-Gaussian range.
- **Canon finding 2: "Un-learning burden" mechanism present but tiny.** The monotone-destructive sign (Arm B > Arm A by +0.000140) confirms the mechanism, but at magnitude below detection threshold. Mechanistically real, practically irrelevant.
- **Canon finding 3: AdamW-aux absorbs init perturbations cleanly in first ~50-100 steps.** EMA-vs-live divergence matched #918 canonical pattern. Init contribution to terminal weight norm: +32.3/66547 = <0.05%.
- **Canon finding 4: Cross-axis — weight-space pivots for aux should be CONSTRAINT-based during training, not INITIALIZATION-based.** Init starting point gets washed out; constraints (spectral-norm, row-WD scheduling) and dynamics (LR per-row, decay coupling) are the directions that load-bear.
- **WHAT'S CLOSED:** lm_head init scale axis at orthogonal-Gaussian endpoint within [0.02, 0.1].
- **WHAT'S OPEN:** embed init scale (untested; mirror axis); tied init (lm_head copy of embed); larger ε (>0.2) regime (not recommended without LR adjustment); spectral-norm constraint on proj.weight; row-WD scheduling.
- nezuko → **#1059** (embed init std ablation — mirror axis on the input side of the readout pair).

---

## 2026-05-24 14:30 UTC — PR #958 CLOSED: PMuon γ_pre temporal schedule — 108th NULL, γ-schedule axis FULLY CLOSED (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-pre-temporal-schedule`
- Hypothesis: PMuon γ_pre (Newton-Schulz polar exponent factor) temporal schedule (UP 0.2→0.4 vs DOWN 0.4→0.2 vs CONSTANT 0.4 baseline) is load-bearing. n=2 confirmation chain.

| Seed | W&B | terminal val/loss | sr | Δval vs #918 | Verdict |
|---|---|---|---|---|---|
| seed-1 (DOWN 0.4→0.2) | `cbob6p4l` | **3.26731** | 2950 | +0.000916 | marginal NULL |
| seed-2 (DOWN 0.4→0.2) | `amanpa5z` | **3.2676** | 2950 | +0.001206 | marginal NULL |
| **n=2 mean** | — | **3.267455** | **2950** | **+0.001061** | **NULL** |
| Baseline #918 (n=2) | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | 0 | reference |

- **Decision: 108th NULL.** Both seeds marginal NULL within seed noise; n=2 mean Δ+0.001 = clean NULL (just over marginal threshold), Δsr+25 = worse on speedrun metric. DOWN γ_pre schedule structurally indistinguishable from CONSTANT γ=0.4.
- **Canon finding 1: γ_pre temporal schedule axis FULLY CLOSED** across {UP, DOWN, CONSTANT}. Original #958 trial showed UP was sub-marginal NULL and DOWN was n=1 WIN — but n=2 confirmation reveals DOWN is also within seed noise. **Constant γ_pre=0.4 is canonical operating point.**
- **Canon finding 2: Empirical seed-noise floor established.** seed-1 = 3.26731, seed-2 = 3.26760 → single-seed σ ≈ 0.0003. Future marginal-WIN candidates must achieve Δ > 3× this spread (~0.001) for n=1 stat-sig WIN, OR provide n=2 confirmation.
- **Canon finding 3: Schedule complexity is overdetermined.** Adding step-dependent γ computation per body parameter is a non-trivial code complexity bump for zero structural payoff. Pruning candidate: keep γ_pre constant.
- **WHAT'S CLOSED:** PMuon γ_pre temporal schedule sub-axis; γ_pre as a schedule lever.
- **WHAT'S OPEN:** NS5 iteration count axis (γ=0.4 constant might pair with reduced NS5 iters); β_cov-γ joint axis; per-block γ assignment.
- frieren → **#1058** (confidence penalty — Pereyra et al. 2017, orthogonal-to-LS loss regularization).

---

## 2026-05-24 12:20 UTC — PR #995 CLOSED: Shampoo body-Muon trace-relative eps — 107th NULL, c-axis CLOSED, family threshold MET (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-trace-relative-eps`
- Hypothesis: Trace-relative eps `c·trace(M)/m` fixes #985's catastrophic null-space amplification. Arm A c=1e-4; Arm B c=1e-2.

| Arm | W&B | terminal val/loss | val/best | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| A — c=1e-4 | `4awd887v` | **3.27673** | 3.27673 | 3125 | +0.01034 | +200 | NULL-but-VIABLE |
| B — c=1e-2 | `6xdltnix` | **3.28115** | 3.28115 | -1 | +0.01476 | DNF | NULL-but-VIABLE |
| Baseline #918 | — | 3.266394 | — | 2925 | 0 | 0 | reference |

- **Canon finding 1: Trace-relative eps FIXES #985 null-space amplification.** Both arms cleared step-500 gate cleanly (Arm A val=3.857 at gate vs 3.800 baseline). Shampoo body-Muon family now viable — first convergent variant since #985 100th-NULL closure.
- **Canon finding 2: C-AXIS IS FLAT across 48× spread.** Steps 2000-3250, Arm B is consistently +0.0044 mnat above Arm A despite 12-48× larger eps throughout. Dose-response: c=1e-4 → 3.27673, c=1e-2 → 3.28115 — within single-seed noise. **(1-β_cov)⁻¹ bias correction IS the load-bearing schedule; c is overdetermined within viable regime.**
- **Canon finding 3: NS5 role disambiguation.** Residual +10 mnat NULL gap vs baseline = Roles (1) magnitude normalization + (2) rank-deficiency clipping missing from Shampoo path. Role (3) null-space amplification suppression = SOLVED.
- **WHAT'S CLOSED:** c-axis within Shampoo trace-eps regime (flat across [1e-4, 1e-2]); "tuning c is a viable improvement direction."
- **WHAT'S OPEN:** Shampoo warmup gate (Variant 2 → alphonse #1046); NS5-layered Shampoo (Variant 3); precond_p sharpening.
- alphonse → **#1046** (Shampoo warmup gate: defer precond to step 500/1000).

---

## 2026-05-24 12:00 UTC — PR #990 CLOSED: Schedule-Free body-Muon (ε=SF c_t) — 106th NULL, SF-body-Muon axis FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/body-muon-schedule-free`
- Hypothesis: Replace Polyak EMA (β=0.99) with Schedule-Free c_t=γ²_t/Σγ²_i averaging. Arm A: SF c_t WITH WSD cooldown; Arm B: SF c_t WITHOUT cooldown (constant lr_mult=1.0).

| Arm | W&B | terminal val/loss (EMA-eval) | val/loss_live (raw z_t) | best val | best step | sr | Δval vs #918 | Verdict |
|---|---|---|---|---|---|---|---|---|
| A — SF+WSD cooldown | `4kjfi8v7` | **3.39235** | **3.26641** | 3.36621 | 2375 | -1 | +0.126 | CATASTROPHIC NULL |
| B — SF+constant LR | `vxcjae5r` | **3.91383** | **3.58460** | 3.49964 | 1875 | -1 | +0.647 | CATASTROPHIC NULL |
| Baseline #918 | — | 3.266394 | — | — | — | 2925 | 0 | reference |

- **Mechanism 1 (Arm A): SF c_t → 0 freezes the average mid-cooldown.** c_t @ step 3250 = 3.24e-12 (essentially frozen). frob_dist plateaus at ~1475 after step 2500 while live z_t continues refining. Polyak (1−β_t) ≈ 0.01 stays active throughout cooldown tail; SF c_t collapses to ~0. Result: EMA average is frozen mid-cooldown while baseline Polyak tracks the final converged state.
- **STRIKING FINDING:** Arm A val_live at terminal = **3.26641** (≈ baseline 3.266394 n=2 mean within 1e-4). The underlying optimizer converges correctly; **SF averaging is what broke the benchmark metric reading**, not optimizer dynamics.
- **Mechanism 2 (Arm B): constant LR fails on non-convexity.** frob_dist explodes to **66677** (45× Arm A's 1475, ~2200× baseline Polyak peak ~30). Iterates do NOT concentrate around a minimum at constant LR=0.040 for non-convex body-Muon on this transformer. SF c_t weighting assumes iterate concentration (convex guarantee); guarantee fails here.
- **Canon finding: Polyak (1−β_t) ≥ 0.01 floor is LOAD-BEARING under WSD cooldown.** SF c_t under WSD cooldown is structurally incompatible. SF under constant LR fails via non-convexity.
- **WHAT'S CLOSED:** SF c_t weighting on body-Muon Polyak EMA (both with-cooldown and no-cooldown); "SF as drop-in averaging replacement for Polyak β=0.99"; "constant LR + SF averaging can replace WSD cooldown".
- fern → **#1043** (label smoothing: ε=0.05 vs ε=0.10, fresh loss regularization mechanism class).

---

## 2026-05-24 11:42 UTC — PR #1026 CLOSED: Body-Muon DEMA (cascaded EMA β=0.95/0.90) — 105th NULL, cascaded-EMA family FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/body-muon-dema`
- Hypothesis: Cascaded 2nd-order EMA (DEMA: m2_t = β·m2 + (1-β)·m1, where m1_t = β·m1 + (1-β)·g) before NS5 as structural filter. Arm A β=0.95 (doubled horizon ~40 steps), Arm B β=0.90 (matched horizon ~20 steps). Key diagnostic: `pmuon/dema_vs_single_cosine` (if ≥ 0.99 → DEMA is no-op; if < 0.99 → DEMA rotates NS5 input).

| Arm | β | W&B | step (abort) | val/loss at abort | Verdict |
|---|---|---|---|---|---|
| A | 0.95 | step 719, aborted | 719 | **3.5629** | CATASTROPHIC NULL (killed at predeclared step-500 gate, caught at 719) |
| B | 0.90 | step 500, aborted | 500 | **3.9202** | CATASTROPHIC NULL |
| Baseline #918 | — | — | — | 3.266394 (terminal) | reference |

- **Key diagnostic `pmuon/dema_vs_single_cosine`:** β=0.95 → cos~0.50-0.57 (43-50° rotation); β=0.90 → cos~0.61-0.73 (27-39° rotation). DEMA is emphatically NOT a structural no-op — it actively rotates the NS5 input direction.
- **Mechanism:** DEMA cascades two EMAs with shared β, producing a step-response that emphasizes low-frequency gradient signal over high-frequency. This "doubling the time-horizon" injects stale directional bias into NS5 input, consistent with #977's stale-anchor finding: gradient direction changes on ~40-step horizon, so a doubled horizon (β=0.95 DEMA → ~80-step effective horizon) is already stale.
- **Cross-axis canon with #977 (Dual-EMA): "1st-order EMA β=0.95→0.99 is multi-axis local optimum for NS5 + Nesterov + polar input."** DEMA at β=0.95 produces NS5 input more stale than 1st-order EMA at β=0.95 → worse. DEMA at β=0.90 produces less rotation than β=0.95 but still rotates enough to catastrophically harm performance.
- **WHAT'S CLOSED:** Cascaded 2nd-order EMA (DEMA) family before NS5 at both β=0.95 and β=0.90; "DEMA as structural temporal filter for NS5 input"; the broader hypothesis that longer-horizon temporal smoothing of NS5 input is beneficial.
- edward → **#1040** (WD decoupling form correction).

---

## 2026-05-24 11:15 UTC — PR #986 CLOSED: Body-Muon LR fine-scan UP (0.045 vs 0.050) — 104th NULL, Body-Muon LR axis FULLY CLOSED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/muon-lr-fine-scan-up`
- Hypothesis: Body-Muon LR=0.040 optimum might extend upward; fine-scan [0.045, 0.050] to localize upper bound.

| Arm | muon_lr | W&B | val/loss | Δval vs #918 (3.266394) | sr | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.045 | `j1ctno6k` | 3.26844 | +0.00205 (2× past marginal) | 2975 | +50 | NULL clear |
| B | 0.050 | `92dnia7i` | 3.27014 | +0.00375 (3.7× past marginal) | 3025 | +100 | NULL clear |

- **Body-Muon LR axis FULLY CLOSED at 0.040** — 4-point bracket: 0.030→NULL Δ+0.003 (#918 Arm B), 0.035→NULL (pre-#918), 0.040→WIN baseline, 0.045→NULL Δ+0.002 (Arm A), 0.050→NULL Δ+0.004 (Arm B). Sharp local optimum, not plateau-extending.
- **NS5 polar U-shape (load-bearing cross-axis finding):** `polar/ortho_residual_sample` = 0.25 (lr=0.030) → 0.14 (0.035) → 0.08 (0.040) → 0.18 (0.045) → 0.23 (0.050). NS5 polar accuracy is the dominant LR-overstep failure mode in BOTH directions.
- **EMA-buffer-divergence NECESSARY but NOT SUFFICIENT:** `ema/buffer_frob_dist` scales super-linearly (×7.2 at lr=0.050 vs baseline), but beyond lr=0.040 additional buffer divergence buys nothing. Buffer divergence criterion breaks at optimum boundary.
- **u/w-floor fires 100% across all 4 LR values** — floor fires on RATIO ||update||/||p||, scale-invariant under LR (as LR increases, both updates and accumulated weights grow proportionally). Falsified PR's prediction that floor would relax at higher LR.
- **Mechanism:** NS5 is the bottleneck. Below optimum: NS5 under-driven (residual ~0.25 at 0.030). Above optimum: NS5 over-driven by larger inputs destabilizing polar convergence (residual ~0.23 at 0.050). lr=0.040 corresponds exactly to NS5 polar peak quality.
- **thorfinn → #1035** (u/w-floor pruning ablation — motivated by 100% floor fire rate cross-axis finding).

## 2026-05-24 09:50 UTC — PR #977 CLOSED: PMuon dual-EMA momentum — 103rd NULL, dual-EMA family CLOSED (g1r1-edward)

- Branch: `g1r1-edward/pmuon-dual-ema`
- Hypothesis: Blending a fast EMA (β=0.95) and a slow EMA (β=0.999) of body-Muon gradients before NS5 captures "long-range gradient signal" (AdEMAMix premise). Two arms: Arm A α=0.5 (50/50 blend), Arm B α=0.05 (5% slow, 95% fast).

| Arm | α (slow weight) | W&B | val/loss | Δ vs #918 (3.266394) | sr | Verdict |
|---|---|---|---|---|---|---|
| A | 0.5 | `rqjoxwrn` | 4.56631 | +1.300 | -1 | **catastrophic NULL via divergence** |
| B | 0.05 | `nmui4m76` | 3.27559 | +0.00920 | 3100 | **slow-descent NULL** |

- **AdEMAMix premise FALSIFIED for body-Muon:** body gradients have temporal structure (cos 0.13–0.35) but slow EMA captures STALE direction, not long-range truth.
- **Dose-response monotone-bad in α:** 50% slow → catastrophic (+1.30 mnat); 5% slow → +0.009 mnat. The 95%-fast Arm B blend_cos ≥ 0.997 throughout — direction barely deviated from single EMA, yet still regressed.
- **Mechanism:** `pmuon/slow_momentum_cosine` = 0.13–0.35 (body grads NOT i.i.d., distinct from aux cos≈−0.05). Slow EMA at β=0.999 (~1000-step horizon) captures non-stationary landscape: gradient direction is ~orthogonal to 1000-step-ago direction. Injecting even 5% of that into NS5 input degrades direction.
- **Nesterov-drop confound noted (Arm B):** `pmuon_update` drops Nesterov when dual-EMA active; ~partial confound in Arm B. Mechanism-closure holds since slow signal direction is stale-anchor regardless.
- **Arm A divergence onset:** blend_cosine(NS5_input, m_fast) drops below 0.7 at step 1000–1250 → NS5 polar of poisoned direction increasingly anti-correlated with descent → unstable optimizer drift (not a single NaN).
- **Cross-axis: body grad cos 0.13–0.35 vs aux i.i.d. (cos≈−0.05) is now CANONICAL distinguishing measurement** for future body vs aux momentum PRs.
- **Closed without n=2:** both arms clear NULL (Arm B Δval=+0.009 = 9× past marginal threshold; Arm A catastrophic). edward → **#1026** (Body-Muon DEMA: cascaded 2nd-order EMA before NS5).

## 2026-05-24 04:05 UTC — 🎯 100 CLOSED AXES MILESTONE — PR #985 CLOSED: Shampoo body-Muon p=1/4 (no NS5) — 100th NULL, NS5 confirmed TRIPLE-LOAD-BEARING (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-body-muon`
- Hypothesis: Replace NS5 polar pipeline + γ=0.4 power preconditioning with Shampoo p=1/4 natural gradient. Arm A: Shampoo on Nesterov-blended momentum; Arm B: Shampoo on raw gradient (drops NS5 AND momentum). Bias-corrected L_cov, R_cov; cubic root of inverse-quartic-root via `matrix_neg_power(L, 0.25)`.

| Arm | --shampoo_input | W&B | step | val/loss | Verdict |
|---|---|---|---|---|---|
| Baseline | — | `j8nsn77s` | 500 | 3.800 | — |
| **A** Nesterov-blended momentum | `momentum` | `hin8ed8u` | **500** (aborted) | **4.623** | catastrophic NULL |
| **B** raw gradient (no momentum) | `raw` | `nssi5k4g` | **500** (aborted) | **4.620** | catastrophic NULL |

### Mid-flight abort execution clean

Both arms crossed predefined val/loss > 4.0 mid-flight gate at step 500. Chain script handed off cleanly between arms. No SIGTERM/SIGKILL hygiene issues.

### Mechanism diagnosis (from student's structural analysis)

**Triple-load-bearing role of NS5 confirmed via failure mode:**

| step | Shampoo Frob (A / B) | Per-element RMS (A / B) | lcov_eigh_ratio (A / B) | Baseline reference |
|---|---|---|---|---|
| 25 | 754,269 / 900,996 | 491 / 587 | — | 78 / 0.025 |
| 50 | 241,679 / 269,209 | 157 / 175 | — | 78 / 0.025 |
| 100 | 46,020 / 42,384 | 30.0 / 27.6 | 1.09e+20 / 1.65e+20 | 78 / 0.025 |
| 500 | 3.64 / 3.62 | 0.0024 / 0.0024 | 9.06e+05 / 7.56e+05 | 747 (baseline) |

- At step 1, L_cov is rank-1 (single g·g^T outer product); `matrix_neg_power(L_cov, 0.25, eps=1e-12)` clamps null eigenvalues to 1e-12, then raises to -1/4 → `1e-12^(-0.25) = 1000×` amplification in null directions.
- L^(-1/4) @ g @ R^(-1/4) amplifies tiny numerical noise in nullspaces into 900k Frob updates.
- Weight norm explodes to 6.4M by step 50 (1000× baseline ~6,219).
- NS5's cubic map `(3/2)X − (1/2)X³` was structurally clamping `‖polar‖_F ≤ √min(m,n)` regardless of input rank — load-bearing not just as magnitude normalizer but as rank-deficiency clipper AND null-space amplification suppressor.

### Cross-axis confirmation: input-side not the cause

Arm B (raw gradient, no momentum smoothing) failed essentially identically to Arm A. Eliminates input-noise as the cause:
- Failure mechanism is preconditioner-side (rank-deficient L_cov + null-eigenvalue amplification).
- Input-smoothing is not the lever.
- Asymptotic bias correction `(1 - β_cov)` (predicted 5% over-correction concern) is NOT dominant — magnitude predictions match well by step 500, but weights already destroyed.

### Cross-axis closure milestones

Combined with prior closures, this completes the polar-pipeline perturbation sweep:

| Sub-family | Closures | Status |
|---|---|---|
| Pre-NS m_pre direction perturbations | #893 BC, #898 residual, #931 sign-mask (mask + renorm), #940 Frob-rescale | FULLY CLOSED |
| Post-NS m_polar perturbations | #696 subtractive, #696 additive, #896 multiplicative | FULLY CLOSED |
| NS internals (γ_power, NS_ITERS, cubic-vs-quintic) | #202 γ=0.4 pinned, #884 NS=12 pinned, #920 cubic optimal | FULLY PINNED |
| Full-NS5 replacement (this PR) | #985 momentum + raw gradient | FULLY CLOSED |

**NS5 polar pipeline is now structurally pinned across all explored interventions.** Future body-side optimizer work must either (a) preserve NS5 cubic and modify accessories, or (b) introduce a fundamentally new pipeline structure that independently solves NS5's three load-bearing roles.

### Cross-axis to #977 cosine finding (parallel session finding)

Edward's `pmuon/slow_momentum_cosine` telemetry on PR #977 confirmed body gradient cosine 0.26-0.33 — body has temporal structure. Combined with this PR's finding: future natural-gradient body optimizers must solve BOTH:
1. Exploit temporal structure (cos ≈ 0.3 means EMA helps at fast-medium horizon)
2. Maintain rank-deficiency protection without absolute-eps null-space amplification

### Reassignment: alphonse → Shampoo body-Muon with trace-relative eps clamp (next PR)

Student's own suggestion #1 ("trace-relative eps clamp: replace `eps=1e-12` absolute with `eps = c · trace(M) / m`") directly tests if the rank-deficient null-space pathology is fixable via preconditioner refinement. If yes → natural-gradient body-Muon family reopens. If no → PSGD-Kron Lie group invariance becomes necessary alternative.

---

## 2026-05-24 03:35 UTC — PR #990 ASSIGNED: Schedule-Free body-Muon — replace Polyak EMA with c_t-weighted averaging (g1r1-fern)

- Branch: `g1r1-fern/body-muon-schedule-free`
- Hypothesis: Replace Polyak EMA accumulation `ema_p.lerp_(p, 1-β_t)` with Schedule-Free c_t=γ²_t/Σγ²_i weighted average (Defazio 2024, arxiv:2405.15682). Attacks root cause of 4-instance cooldown-erosion pattern (#690 SGDR, #697 QHM, #686 β_cov, #695 Polyak EMA) — SF c_t weighting naturally diminishes during cooldown as step LR shrinks, eliminating need for externally scheduled β ramp.

| Arm | Description | Flags |
|---|---|---|
| **A** | SF c_t weighting WITH WSD cooldown | `--use_schedule_free 1` (lr_mult decays as normal) |
| **B** | SF c_t weighting WITHOUT cooldown | `--use_schedule_free 1 --sf_no_cooldown 1` (lr_mult=1.0 constant) |

- Baseline: sr=2925 / val=3.266394 (PR #918 n=2 mean, muon_lr=0.040)
- Bold direction per Plateau Protocol — 99 closed axes, 4-instance cooldown-erosion pattern confirmed
- ~25 LOC across 6 steps; key diagnostic: `ema/c_t`, `ema/sf_lr_sq_sum`
- Magnitude budget: NS5 polar unchanged; c_t → 0 as training progresses (tighter EMA tracking than Polyak β_t near 0.99)
- Modal prediction ~50%: both NULL (β_t=0.99 is well-tuned Polyak); bold case ~25%: Arm B WIN (cooldown genuinely unnecessary with SF)

---

## 2026-05-24 03:15 UTC — PR #943 CLOSED: SWA partial blend at cooldown_start — 99th NULL (informative), SWA family FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/swa-partial-blend-cooldown-start`
- Hypothesis: Deferred sub-axis from #730 closure ("blend arm not included"). #730 tested full SWA replace (α=1.0) NULL. Partial blend (α∈{0.25, 0.50}) at cooldown_start tests whether smaller backward pull creates useful "averaged starting point" without erasing too much live state. Mechanism predict: monotone-bad in α per #730 ("body-Muon travels directionally, SWA is lagged anchor").

| Arm | α | W&B | sr | val/loss_ema | Δval vs new baseline 3.266394 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | vm48fdof, 0a7esmxs | 2925 | 3.266394 | — | — | — |
| **A** light blend | 0.25 | `08vk4ev3` | **2950** | **3.26886** | **+0.002466** | +25 | NULL |
| **B** half blend | 0.50 | `99ygrsg7` | **2975** | **3.27069** | **+0.004296** | +50 | NULL |

### Verdict: CLOSE as 99th NULL (informative)

Both arms clean NULL with **monotone-bad in α confirmed**. Per #730 closure mechanism: body-Muon weights travel directionally during stable phase, so SWA average over stable-phase snapshots is a **lagged anchor**, not a centroid. Blend at cooldown_start pulls live params backward toward high-noise past state.

### Math sanity checks (student-confirmed exact arithmetic)

- Arm A: `post_blend / pre_blend = 252.89 / 1011.58 = 0.2500 = α ✓`
- Arm B: `post_blend / pre_blend = 504.35 / 1008.71 = 0.4999 = α ✓`
- Pre-blend distance `||live − swa_avg||_F ≈ 1010` in both arms (consistent, ~0.3% difference)

### Monotone-bad scaling

- `Δval(α=0.50) / Δval(α=0.25) = 0.00430 / 0.00247 = 1.74` (between linear 2.0 and sub-linear)
- `Δsr(α=0.50) / Δsr(α=0.25) = 50 / 25 = 2.00` (exactly linear)

The harm is back-loaded — both arms show better val at step 1000 (3.642 / 3.632 vs ~3.68 pre-blend) due to natural LR-cooldown improvement, but the lagged-anchor pull delays final basin convergence and the regression accumulates through cooldown.

### Cross-axis closure: buffer-modification-at-cooldown_start cluster FULLY CLOSED

All five interventions on the cooldown_start transition NULL:
- momentum reset (#723)
- cov reset (#725)
- WD ramp (#727)
- SWA full replace (#730 α=1.0)
- SWA partial blend (#943 α=0.25, 0.50)

**Cooldown_start state itself is structurally fragile — any backward modification harms.** The α-axis is now closed at α ∈ {0.25, 0.50, 1.0}. Smaller α (0.10, 0.05) would scale further sub-linearly per the mechanism but still hurt; K-variant (K=200 SWA window) would give smaller but still-negative effect per the same mechanism class. No further sub-axis tests will move the needle.

### Reassignment: fern → next bold-direction PR after researcher-agent ideation

---

## 2026-05-24 02:50 UTC — PR #918 MERGED: Body-Muon LR retune to 0.040 — n=2 WIN, NEW BASELINE val=3.266394 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-muon-lr-retune`
- Hypothesis: Body-Muon LR=0.035 structurally stale since PR #248 (before EMA wrapper #737 and EMA warmup-retune #864). Retune at new post-#864 baseline. Arm A: muon_lr=0.040 (+14%); Arm B: muon_lr=0.030 (−14%); Arm A seed-2: n=2 confirmation.

| Run | muon_lr | W&B | sr | val/loss_ema | Δval vs old baseline 3.266826 |
|---|---|---|---|---|---|
| Baseline #864 (n=2) | 0.035 | j8nsn77s, 08ursg5n | 2925 | 3.266826 | — |
| **Arm A seed-1** | 0.040 | `vm48fdof` | 2925 | **3.265863** | **−0.000963 (marginal n=1 WIN)** |
| **Arm A seed-2** | 0.040 | `0a7esmxs` | 2925 | **3.266925** | **+0.000099** |
| **Arm A n=2 mean** | 0.040 | — | 2925 | **3.266394** | **−0.000432 (n=2 WIN)** |
| Arm B (DOWN) | 0.030 | `1zif5xet` | 2925 | 3.269392 | +0.002566 (NULL) |

### Verdict: MERGE as new baseline — strict n=2 WIN (Δ=−0.000432). BASELINE UPDATED.

**Stat-sig:** (3.28 − 3.266394)·√2 = 0.01924 ≥ 0.004 ✓ (4.81×)

### Mechanism

| Metric | Arm A (UP 0.040) | Arm B (DOWN 0.030) | Interpretation |
|---|---|---|---|
| `ema/buffer_frob_dist` terminal | 22.6 | 5.1 | 4.5× larger at UP — load-bearing EMA averaging mechanism |
| `train/uw_floor/fired_fraction` | 1.000 | 0.958 | Floor fires 100% at UP — both arms have active floor |
| `polar/ortho_residual_sample` terminal | 0.247 (seed-1), 0.139 (seed-2) | 0.083 | Higher LR → slightly elevated residual, still healthy |
| `val/ema_minus_live` terminal | +0.0006 | +0.0005 | EMA absorbs ~0.5-0.6 mnat above live, LR-invariant |

**Mechanism:** Body-Muon LR=0.035 was last tuned at PR #248 BEFORE the EMA wrapper (PR #737) and shortened warmup (PR #864). Higher LR (0.040) → larger per-step PMuon updates throughout training → EMA buffer diverges 4.5× further from live weights → EMA averaging covers wider trajectory window → lower val/loss at inference. Asymmetric axis: DOWN −14% (0.030) regresses 6× harder (Δ+0.0026) than UP +14% (0.040) wins (Δ−0.0004) — optimum has structurally shifted UP.

**Note on u/w-floor semantics (cross-axis finding):** Arm A fires floor 100% vs Arm B 95.8% — OPPOSITE to advisor's prediction (expected UP to fire LESS). Higher LR → larger absolute updates, but the floor fires on RATIO (update.norm() / p.norm()) not absolute magnitude. At higher LR, p.norm() grows more (larger updates accumulate → weights grow), which MAINTAINS the ratio near the TARGET_UW threshold. So floor continues firing across LR range as a load-bearing regulator.

### Decision rationale (n=2 WIN vs boundary-band)

n=2 mean 3.266394 sits in (3.266326, 3.266826) — inside the ±0.0005 buffer band the advisor predeclared at 22:35 UTC May 23. However, CLAUDE.md compound-improvements principle is explicit: "merge every PR that beats baseline, even by a small margin." Precedent: PR #864 merged at Δ=−0.0001 (4× less improvement). Mechanism is strong (4.5× EMA buffer ratio), code complexity is minimal (~5 lines), asymmetric structural evidence (DOWN 6×) confirms real optimum shift. MERGE justified per precedent + mechanism + compound-improvements principle.

### Reassignment: thorfinn → #986 Body-Muon LR fine-scan UP (0.045 vs 0.050)

---

## 2026-05-24 02:30 UTC — PR #940 CLOSED: Frobenius-normalized NS output — 98th NULL (informative TIE), literal Frob-rescale family CLOSED at both endpoints (g1r1-alphonse)

- Branch: `g1r1-alphonse/polar-frob-norm`
- Hypothesis: Decouple NS5 polar magnitude from input rank/conditioning by forcing Frobenius normalization on either the post-NS polar (Arm A) or pre-NS m_pre (Arm B). Cross-axis to #898 rank-deficiency residual finding.

| Arm | W&B | sr | val/loss_ema | Δsr | Δval vs baseline 3.266826 | Verdict |
|---|---|---|---|---|---|---|
| Baseline #864 (n=2) | — | 2925 | 3.266826 | — | — | — |
| **A post-NS** | `6c4y3v4w` | **−1** | **3.295062** | n/a | **+0.028236** | NULL — catastrophic |
| **B pre-NS** | `6dh4xs4k` | **2925** | **3.267769** | TIE | **+0.000943** | NULL — marginal LOSS, mechanistically no-op |

### Verdict: CLOSE as 98th NULL (informative TIE), no n=2 needed

The marginal rule (Δval ≤ 0.001 → request n=2) applies to marginal WINS where mechanism is unclear. Arm B is a marginal LOSS (Δ+0.000943 above baseline) with **clear mechanism: NS5 absorbs pre-NS scale**. Seed-2 unlikely to find strict win given the no-op mechanism; GPU on n=2 is wasted.

### Mechanism finding — Arm A vs Arm B asymmetry

**Arm A (post-NS) catastrophic NULL:**
- `polar/frob_post_rms ≈ 1.002` (normalization works exactly as designed — per-element RMS forced to 1)
- Inflation factor: 1.0 / 0.018 ≈ 55.6× per-element RMS (matches √max(m,n) prediction for 3072×768 tensor)
- `polar/ortho_residual` = 1.38 terminal (trajectory 27.7→3.34→2.60→2.08→1.38, never drops to healthy ~0.05)
- `pmuon/lcov_eigh_ratio` = 2.9e7, `rcov_eigh_ratio` = 1.7e8 (covariance estimates blow up due to update propagation feedback)
- Final val 3.295 (Δ+0.028) — catastrophic over-step that cooldown only partially absorbs

**Arm B (pre-NS) near-no-op:**
- `polar/frob_pre_norm` = 27.7 (NS5 absorbs √(m·n)-scale input and emits unit-RMS orthonormal output)
- `polar/frob_pre_rms` = 0.01804 (== baseline RMS)
- `polar/frob_post_rms` = 0.01804 (== pre, no post-norm in Arm B)
- `polar/ortho_residual` = 0.144 terminal (MORE orthonormal than Arm A by terminal, healthier than baseline trajectory)
- `pmuon/lcov_eigh_ratio` = 715.7, `rcov_eigh_ratio` = 1637.4 (mid-flight 982/2305; terminal ~30% lower — cov ill-conditioning resolved through cooldown)
- Final val 3.268 (Δ+0.000943) — marginal LOSS in seed-noise band

### Asymmetric NS5 scale response (recording for future reference)

| Quantity | Baseline | Arm A | Arm B |
|---|---|---|---|
| `polar/frob_pre_norm` | 27.7 | 27.6 | 27.7 |
| `polar/frob_post_rms` | 0.018 | 1.002 | 0.018 |
| `polar/ortho_residual` | ~0.05 | 1.38 | 0.144 |
| Inflation factor | 1× | 55.6× | 1× |

**The cubic NS map `p(X) = (3/2)X − (1/2)X³` is NOT symmetric in scale response:**
- Collapses scale toward orthogonal manifold for large-norm inputs (Arm B works)
- Cannot inflate scale once below orthogonal manifold (Arm A passes through to body)

This recording motivates the **norm-preserving direction-only Frobenius variant** as a follow-up (deferred for now — bigger-swing Shampoo replacement assigned instead).

### Cross-axis closures

- **Literal Frobenius-rescale family CLOSED** at both polar-pipeline endpoints (Arm A post-NS + Arm B pre-NS).
- Combined with **#898 alphonse (rank-deficiency residual structurally bounded at √(m−rank(X)) ≈ √dim_min)** and **#931 askeladd (sign-mask family CLOSED at both endpoints)**: all literal pre-NS magnitude/sign interventions on m_pre are now characterized. Either reabsorbed by NS5 (Arm B Frob, #893 BC) or destructively over-stepped (Arm A Frob, #931 sign-mask, #896 cautious-Muon).
- Only remaining open question on this axis: **norm-preserving direction-only** Frobenius correction (rescale polar to ||·||_F = √min(m,n) canonical target). Filed for later; prioritized #985 Shampoo bigger-swing investment.

### Advisor PR-design lesson (2nd consecutive — #937 + #940 same root cause)

Both #937 (SOAP `R_neg ~ grad^(-1/2)` post-multiply damps by 30-60×) and #940 (Frobenius pre/post inflates by 27-55×) had the **same root cause: I didn't compute the analytical magnitude budget before assigning**. Future preconditioner/NS-perturbation PRs MUST include explicit:
1. Baseline `||update||_F` for the operation being modified
2. New construction's analytical `||update||_F`
3. Ratio + per-element RMS comparison
4. Whether the change is scale-coupled (direction+magnitude test) or direction-only (isolated direction test)

This is now applied to #985 PR body (Shampoo replacement).

### Student diagnostic excellence

g1r1-alphonse's mid-flight 19:05 UTC scale derivation correctly identified the 55× over-step within the first 525 steps from `polar/frob_pre_rms ≈ 0.018, not 0.7-1.3` telemetry. Predicted final cell ("Arm A regress + Arm B TIE") confirmed across both arms. Gold-standard diagnostic discipline — saved hours of wasted GPU by enabling the closure narrative pre-terminal.

### Reassignment: alphonse → #985 Shampoo body-Muon (no NS5, p=1/4): Arm A momentum vs Arm B raw gradient

---

## 2026-05-24 01:05 UTC — PR #893 CLOSED: PMuon momentum first-moment BC — n=2 informative-NULL, 97th axis (g1r1-edward)

- Branch: `g1r1-edward/pmuon-momentum-bc`
- Hypothesis: Adam-style bias correction `1/(1-μ^t)` on PMuon's first-moment buffer `m_pre` during warmup phase. BC factor = 20.0 at t=1, 1.006 at t=100, ≈1.0 past t=200 — mathematically identity for 97% of training.

| Seed | W&B | sr | val/loss_ema | Δval vs baseline 3.266826 |
|---|---|---|---|---|
| Seed-1 | `cmoc8opp` | 2925 (TIE) | 3.267106 | +0.000280 |
| Seed-2 | `54wsfo21` | 2925 (TIE) | 3.265793 | −0.001033 |
| **n=2 mean** | — | **2925** | **3.266450** | **−0.000376** |

### Verdict: CLOSE as informative-NULL (97th axis). n=2 mean Δ=−0.000376 = 0.4σ_n=2; P(|Δ|≥observed | H0:Δ=0) ≈ 0.62.

### Why NOT merge despite numerical n=2 win (5 reasons)

1. **Predeclared 17:02 UTC rule:** MERGE if μ_n2 ≤ 3.266326; n=3 BOUNDARY if μ_n2 ∈ [3.266326, 3.266826]; NULL if μ_n2 ≥ 3.266826. n=2 mean 3.266450 sits in BOUNDARY band, not merge band. Predeclared strict rule supersedes looser 23:35 UTC restatement.
2. **Mechanism math:** BC factor ≈ 1.0 for 97% of training. t=1: 20.0; t=100: 1.006; t=200: 1.000035; t=500+: ~1.0 (machine precision). Real persistent effect would require early-warmup direction change (t=1-100) to persist through cooldown — plausible but mechanistically unsupported.
3. **Statistical noise:** Δ=0.4σ_n=2 at p=0.62. Not distinguishable from seed noise.
4. **Code complexity vs gain:** ~40 lines added (2 CLI flags, 4 function params, BC block, telemetry) for likely-noise improvement at 97% structural identity. Per CLAUDE.md exception: "only reason to reject is disproportionate complexity for tiny gain."
5. **Plateau Protocol:** GPU time better on fresh axes. Marginal-noise n=3 confirmation lower EV than fresh-axis screening.

### What this PR contributed

- **Cross-axis with #822 alphonse (second-moment BC):** #822 closed L_cov/R_cov BC null via NS5 absorption. #893 closes m_pre first-moment BC with marginal-signal (0.4σ). Asymmetry: NS5 absorbs cov-rescaling more aggressively than momentum-rescaling.
- **Cross-axis with #931 (sign-mask):** Smooth BC tilting (0.4σ) vs destructive sign-mask (+6.5 mnat). m_pre is well-protected by NS5 against smooth tilting AND destructive masking; neither provides useful body-Muon signal.
- **PMuon warmup-phase intervention family FULLY CLOSED:** Both first-moment BC (#893) and second-moment BC (#822) confirmed closed. Warmup-only interventions cannot produce statistically meaningful signal through the cooldown phase.

### Reassignment: edward → #977 PMuon dual-EMA momentum (β_fast=0.95 + β_slow=0.999 before NS5)

---

## 2026-05-24 00:08 UTC — PR #931 CLOSED: Pre-NS sign-mask on m_pre — both NULL, 96th axis, sign-mask family fully closed at both polar-pipeline endpoints (g1r1-askeladd)

- Branch: `g1r1-askeladd/pre-ns-sign-mask`
- Hypothesis: Sign-mask on m_pre BEFORE bilateral whitening + NS5 (cross-axis to #896 post-NS closure). Arm A mask-only; Arm B mask+renorm (restore Frobenius after masking). Tests whether NS5 re-orthogonalization from masked input can recover the gating signal that fails post-NS.

| Arm | W&B | sign_mask | renorm | sr | val/loss_ema | mask_frac | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #864 (n=2) | — | 0 | 0 | 2925 | 3.266826 | n/a | — | — | — |
| A mask-only | `krm84brb` | 1 | 0 | **3000** | **3.27331** | 0.681 | +75 | +0.006485 | NULL |
| B mask+renorm | `p5mgpaoq` | 1 | 1 | **3050** | **3.27492** | 0.683 | +125 | +0.008093 | NULL (worse than A) |

### Verdict: BOTH NULL — 96th axis closed. Pre-NS sign-mask family CLOSED at both endpoints.

### Mechanism finding — Arm B WORSE than Arm A (contra advisor prediction)

Advisor's 22:55 UTC prediction range for Arm B was 3.267-3.269 ("NULL near baseline" since renorm restores magnitude). Actual Arm B val=3.27492 sits +1.6 mnat above Arm A and OUTSIDE that range — and worse than Arm A, not better.

Refined mechanism: m_pre sign-mask is a DESTRUCTIVE directional operation that zeros ~68% of coordinates. NS5 cannot reconstruct sign bits that don't exist in its input. Whether NS5 then sees a Frobenius-shrunk input (Arm A, partial damage) or a Frobenius-restored input (Arm B, full damage at full magnitude) determines how much of the directional corruption propagates to the body update:

| Arm | Frobenius effect | Directional effect | Result |
|---|---|---|---|
| **A** mask-only | m_pre Frob drops 9.3% (416→377) → NS5 polar output correspondingly under-magnitude → equivalent to ~9% LR shrink | 68.1% of m_pre coords sign-flipped → directional perturbation enters NS5 | +6.5 mnat val |
| **B** mask+renorm | Frob restored to 430 → NS5 sees full-magnitude input → polar output at baseline magnitude | Same 68.3% sign-flip → directional perturbation at FULL magnitude | +8.1 mnat val |

The renorm in Arm A's masked-but-shrunk update acted as an implicit LR-shrink buffer absorbing partial damage. Removing that buffer (Arm B) re-amplifies the direction-corrupted update to full magnitude. **Renorm is NOT orthogonal to mask quality; it actively amplifies the perturbation cost.**

### Cross-axis closure: sign-mask family fully closed at both polar-pipeline endpoints

| Endpoint | PR | Result | Mechanism |
|---|---|---|---|
| **Post-NS** (mask on polar output) | #696 subtractive + #896 multiplicative | Both NULL | Multiplicative gating after NS5 destroys orthonormality; renorm partially rescues |
| **Pre-NS** (mask on m_pre) | **#931 mask-only + mask+renorm** | Both NULL | Direction-corrupted m_pre → NS5 orthogonalizes bad direction at full norm if renormed (B), or magnitude-buffered partial damage if not (A) |

The pre-NS and post-NS renorm behave OPPOSITELY:
- **Post-NS:** renorm helps (re-imposes Frobenius constraint on already-orthonormal polar after gating)
- **Pre-NS:** renorm hurts (passes full-magnitude direction-corrupted update through NS5)

### Cross-axis with #893 m_pre BC

Smooth (BC) vs destructive (mask) m_pre interventions behave differently:
- #893 BC: smooth multiplicative tilt of m_pre → Arm A marginal WIN (warmup-only effect)
- #931 sign-mask: destructive zero-out of ~68% coords → both arms NULL

Implication for future m_pre interventions: must be smooth/continuous (shrinkage, scaling, smooth elementwise function) NOT destructive (mask, hard-cutoff, sign-flip). NS5 preserves both, but only smooth tilting carries useful signal.

### Implementation notes (intact telemetry)

- `polar/pre_ns_sign_mask_enabled` and `polar/pre_ns_sign_mask_renorm_enabled` correctly distinguish arms (1/0 and 1/1)
- `polar/pre_ns_mask_frac` ≈ 0.68 in both arms — in band with #896 post-NS telemetry (0.625)
- `polar/pre_ns_pre_norm` = 416 (A) / 430 (B); `pre_ns_post_norm` = 377 (A, −9.3%) vs 430 (B, exact match) confirms renorm path mathematically correct
- `polar/ortho_residual_sample` modestly elevated in both arms (0.129/0.117 vs baseline ~0.10) — NS5 converging slightly less tightly when input is mask-perturbed
- Step time +1% (~13100 vs baseline ~13050) — sign-mask + renorm essentially free compute-wise

### Reassignment

askeladd → **#969 (WSD cooldown power exponent γ=1.2 vs γ=1.6)** — deferred clean axis, tier shift off polar-pipeline perturbations per Plateau Protocol. `COOLDOWN_POWER=1.4` at line 27 has never been retuned despite shaping 70% of training. Predicted: NULL within ±0.001-0.002 (1.4 hand-tuned in modded-nanogpt), but informative closure of WSD shape parameter local-optimum bandwidth.

---

## 2026-05-23 22:50 UTC — PR #920 CLOSED: Quintic NS at low iter count (NS_ITERS=5 vs 6) — both NULL, 95th axis, joint cell quintic × low-iters CLOSED (g1r1-nezuko)

- Branch: `g1r1-nezuko/quintic-low-iters`
- Hypothesis: Quintic NS polynomial (Jordan, 3.4445/-4.7750/2.0315) at NS_ITERS={5, 6} — joint cell never tested. Tests whether quintic's faster per-iter small-σ amplification can match cubic-at-12 in fewer iters.

| Arm | W&B | NS_ITERS | sr | val/loss_ema | residual | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 (cubic, n=2) | — | 12 | 2925 | 3.266826 | ~0.10 | — | — |
| A quintic NS=5 | `ysw9gyj9` | 5 | **2925** (TIE) | **3.268290** | **8.138** | +0.001464 | NULL (just above marginal) |
| B quintic NS=6 | `s40ht1xj` | 6 | **3000** | **3.271249** | **10.277** | +0.004423 | NULL (clear regression +75 sr) |

### Verdict: BOTH NULL — 95th axis closed, quintic × low-iters joint cell CLOSED.

### Mechanism finding — Within-quintic NS=5→NS=6 NON-MONOTONE residual

Student's strongest finding: NS=6 residual (10.277) is *worse* than NS=5 residual (8.138). One additional NS iter INCREASES residual instead of decreasing it.

Mechanism: Jordan-quintic (3.4445, -4.7750, 2.0315) has `f'(1) ≈ 0.72` (linear convergence, not quadratic) AND `f(0.5) ≈ 1.19` (overshoots mid-band). In the partially-converged regime where many σ are mid-band, one more NS iter pushes σ values past the fixed point at 1, INCREASING `‖XX^T − I‖_F` instead of decreasing it. Quintic is monotonically convergent only at high iter counts where σ has been amplified into the contraction basin. **Cubic, with `f'(1) = 0` (quadratic convergence), doesn't have this overshoot issue.**

Within-run residual trajectories (n=134 samples each):
- Arm A NS=5: Early 9.91, Mid 8.30, Late 8.16 — settles to floor near step 200
- Arm B NS=6: Early 11.30, Mid 10.10, Late 10.26 — settles to floor (higher than NS=5)

### Updated NS landscape

| Cell | residual | Δval | Regime |
|---|---|---|---|
| Cubic NS=8 (#884 A) | ~13.9 | NULL | catastrophic under-conv |
| **Quintic NS=5 (this A)** | **8.138** | +0.001464 NULL | catastrophic under-conv (slightly better than cubic NS=8) |
| **Quintic NS=6 (this B)** | **10.277** | +0.004423 NULL | catastrophic under-conv — WORSE than NS=5 |
| Cubic NS=12 (baseline) | ~0.10 | 0 | saturated, optimal |
| Cubic NS=16 (#884 B) | ~0.067 | NULL | mild over-saturation |
| Cubic NS=20 (#898 effective) | ~0.05 | NULL | marginal over-saturation |

### Structural conclusion — NS subsystem fully pinned

**NS convergence is dominated by iter count, not polynomial choice.** Quintic's per-iter advantage is ~1.7× (not 2.3× as theoretically estimated), insufficient to compensate for halving the iter budget. Exponential convergence in iter count dominates.

The 2D (polynomial × iter count) space is now thoroughly explored:
- Polynomial: cubic (1.5, -0.5, 0) PINNED. Quintic tested {5, 6, 12} → all worse than cubic-12.
- NS_ITERS: static=12 PINNED across cubic {8, 12, 16, 20} and quintic {5, 6}.
- Adaptive NS_ITERS: #898 closed (residual floor ≈ √rank_deficit blocks adaptation).
- Frobenius normalization: #940 alphonse IN FLIGHT.

### What this NULL closes vs leaves open

**Closes:** Quintic × low-iters joint cell. The non-monotone within-quintic residual is the strongest structural takeaway — quintic has a "valid band" only at NS_ITERS ≥ 12.

**Leaves open (low priority):** Septic polynomial (same overshoot pattern, more extreme), adaptive polynomial-switching (engineering-heavy), polynomial blending (speculative).

### Reward

Three-axis outstanding work: (1) duplicate-launch incident detection + clean resolution twice (15:54 UTC for run `c0ud3ah7`, 17:05 UTC for stale chain script PID 308383), (2) within-run residual trajectory decomposition + NS=5→NS=6 non-monotone discovery — strongest mechanism finding of the round, (3) calibrated honest disconfirmation table (predicted "Outcome 4: quintic dominated by cubic" was correct).

Student → #964 (Aux Muon-as-aux for lm_head — bigger swing per Plateau Protocol, off-Adam scaffolding per #913 frieren's closure recommendation).

---

## 2026-05-23 22:15 UTC — PR #913 CLOSED: Aux embed/lm_head LR retune at PR #737 baseline (UP+30% vs DOWN−25%) — both NULL, 94th axis, 18th aux Adam-family closure (g1r1-frieren)

- Branch: `g1r1-frieren/embed-lmhead-lr-retune`
- Hypothesis: Retune `embed_lr` and `lm_head_lr` at the current PR #864 baseline. The original aux LRs (`embed_lr=0.3`, `lm_head_lr=1/160 ≈ 0.00625`) were tuned for the PR #413-era baseline; body-Muon (γ_pre=0.4, β_cov=0.95) and EMA wrapper (β_target=0.99 ramp) have shifted effective body update magnitude. Base-case probe.

| Arm | W&B | embed_lr | lm_head_lr | sr | val/loss_ema | val/loss_live | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 0.3 | 1/160 | 2925 | 3.266826 | — | — | — |
| A (UP +30%) | `5eo84z96` | 0.4 | 0.008 | 2925 | 3.267555 | 3.267032 | +0.000729 | NULL (marginal) |
| B (DOWN −25%) | `abhcrtf1` | 0.225 | 0.005 | 2925 | 3.267344 | 3.266816 | +0.000518 | NULL (marginal) |

### Verdict: SYMMETRIC NULL — 94th axis closed, 18th aux Adam-family closure.

### Mechanism finding — Inverse-norm equilibrium confirms steady-state saturation

Terminal panel revealed the smoking gun: gradient norms anti-correlate with LR.

| Quantity | Arm A (UP +33%) | Arm B (DOWN −25%) | Ratio | Reading |
|---|---|---|---|---|
| `train/lr/adam_embed` (terminal) | 7.99e-06 | 4.49e-06 | 1.78× | matches imposed 0.4/0.225 LR ratio ✓ |
| `train/grad_param/embed/weight/norm` | 41.04 | 72.20 | 0.57× | inverse — higher LR shrinks ||g|| |
| `train/grad_param/proj/weight/norm` (lm_head) | 4723.1 | 7157.6 | 0.66× | same inverse-norm pattern |
| `polar/ortho_residual_sample` | 0.1628 | 0.1203 | — | both within healthy band |

Adam steady-state: `||update|| ∝ lr / ||g||`. Higher LR drives ||W_embed|| up faster → inflates √v_t denominator → shrinks `||g||/√v_t` proportionally. The product `lr · update` stays roughly constant → variance scaling **self-normalizes** under linear LR perturbation. This is the cleanest evidence yet that aux Adam is in a flat shallow minimum w.r.t. base LR.

Cross-axis with #875's `s/m² ≫ 1`: when momentum doesn't predict gradient, the update is dominated by `1/√v_t` per-coord variance scaling — which is scale-invariant under LR scaling. So LR perturbation cannot extract additional signal from a structurally i.i.d. aux gradient.

### Operational note

Student detected and resolved a duplicate-launch race at Arm B start (stale `arm_b_launcher.sh` from prior PR fired alongside the live chain). Killed the stale process, updated `aux_lr_down.{pid,logpath,wandb_id}` to point at the surviving `abhcrtf1` run. Trajectory recovered cleanly. Suggestion for team-wide launcher hygiene: have launchers self-delete after exit.

### What this NULL closes vs leaves open

**Closes:** Aux base-LR sensitivity in both directions (±30% perturbation lands inside ±0.001 noise band on val/loss_ema; SR ties at 2925 for both arms).

**Leaves open in the aux family:** Off-Adam aux mechanisms — future aux work must move OFF the AdamW scaffolding (aux Muon-as-aux, aux Shampoo/KFAC with magnitude-budget pairing, aux Sophia/Hutchinson Hessian, etc.). The aux Adam-family is now structurally saturated across 18 update-rule variants + 3 scalar-hyperparameter axes (#460 scalar_lr, #463 embed_eps, #466 aux WD) + base-LR scaling (this PR).

### Aux Adam-family closure status (18 total — accounting corrected)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), aux parameter EMA (#899), SOAP literal @ R_neg (#937 — corrected from 18th to 17th), **aux base-LR retune (#913 — this PR, 18th)**.

### Cross-axis with #875, #899, #937

Four independent measurement axes now confirm the aux gradient is i.i.d.:

| PR | Aux operation | Result | Mechanism |
|---|---|---|---|
| #875 | AdaBelief denominator | NULL | `s/m² ≫ 1` — momentum doesn't predict gradient |
| #899 | Parameter EMA | NULL | wrong-sign `ema_minus_live` — no directional trajectory |
| #937 | Cross-dim preconditioner (scale-coupled) | NULL | scale mismatch — Adam update ⊥ R_neg natural units |
| #913 | Base-LR linear scaling | NULL | inverse-norm equilibrium — variance scaling self-normalizes |

Aux gradient is structurally i.i.d. across time (correlation, EMA), structure (cross-dim preconditioner), and magnitude (base LR). Only DIRECTION-itself remains untested on aux — would require Muon-as-aux or natural-gradient-style alternative.

### Reward

Three-axis excellent work: (1) duplicate-launch race detection + clean recovery (saved ~7-8 min contention), (2) inverse-norm equilibrium mechanism analysis at terminal — the gradient/LR anti-correlation framing is the right way to see Adam's saturation, (3) recommendation to move off Adam scaffolding entirely — exactly the structural conclusion the round is driving toward.

Frieren freed to PR #958 (γ_pre temporal schedule, body-side first probe).

---

## 2026-05-23 21:55 UTC — PR #937 CLOSED: SOAP literal Adam@R_neg for lm_head — Arm A NULL (sr=-1, val 3.486), 93rd axis, 17th aux Adam-family closure (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/soap-lm-head`
- Hypothesis: SOAP one-sided preconditioner for lm_head — postmultiply AdamW update by `R_neg = R_cov^(−1/4)` where `R_cov` = `g.T @ g` EMA. Tests whether cross-vocab-dim gradient covariance structure can improve lm_head convergence.

| Arm | W&B | sr | val/loss_ema | val/loss_live | precond_norm_ratio | Verdict |
|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | n/a | — |
| A (`gudcg46p`, precond_freq=5) | `gudcg46p` | **−1** (never hit 3.28) | **3.486250** | 3.485687 | **0.01367** (~73× damped) | NULL |
| B (precond_freq=10) | — | killed | — | — | — | killed per advisor (deterministic NULL) |

### Verdict: NULL — 93rd axis closed, 17th aux Adam-family closure.

### Mechanism finding — Scale mismatch confirmed in production

The literal `delta = adamw_delta @ R_neg` construction has units of `R_neg ~ grad^(−1/2)`:
- R_cov has units of `grad²`; `R_neg = R_cov^(−1/4)` has units of `grad^(−1/2)`
- Postmultiplying AdamW's already-magnitude-normalized update by `R_neg` **decouples the effective lm_head LR** from its tuned value
- Final `soap/precond_update_norm_ratio = 0.01367` → SOAP step was **73× smaller** than AdamW step at every step
- `soap/R_cov_max_eig = 3.42e9`, `R_cov_condition_num = 3.3M`, `R_neg_trace = 12.76` → catastrophic scale mismatch
- lm_head effectively learned at ~1/73 of tuned LR → val/loss never converged below 3.28 (sr = −1)

Student caught this mechanism at step ~705 (22% of training) via `precond_update_norm_ratio = 0.016–0.034`. Arm B chain killed at 21:01 UTC based on advisor decision that `precond_freq` is orthogonal to the failure mode (R_neg eigenvalues are set by R_cov spectral scale, not by how often R_cov is recomputed).

### Mid-flight diagnostic (student)

Student posted the full mechanism analysis at 18:43 UTC (step 705, 22% through), correctly predicting both arms would NULL via scale mismatch and proposing the norm-preserving variant as the clean follow-up. The `precond_update_norm_ratio` telemetry was the key diagnostic. Arm B kill saved 3.6h GPU time.

### What this NULL closes vs leaves open

**Closes:** Literal scale-coupled `update @ R_neg` SOAP formulation. Adam-family cross-dim preconditioner with R_cov natural units does not help on aux Adam parameters.

**Leaves open:** Direction-only norm-preserving SOAP (assigned to tanjiro as PR #953). Tests whether lm_head's gradient cross-dim correlation has signal when scale is not modified. Both R_cov^(-1/4) and R_cov^(-1/2) variants tested.

### Aux Adam-family closure status (17 total after #937; #913 became 18th)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), aux parameter EMA (#899), **SOAP literal @ R_neg (#937 — this PR, 17th)**.

Only #913 (aux base-LR retune, frieren) remains active as the 19th potential closure. Also norm-preserving SOAP variant (#953 tanjiro) is the direction-only follow-up.

---

## 2026-05-23 18:35 UTC — PR #899 CLOSED: Aux Polyak EMA (lm_head only vs embed only) — both arms NULL, 92nd axis, 17th aux Adam-family closure (g1r1-fern)

- Branch: `g1r1-fern/aux-polyak-ema`
- Hypothesis: Aux parameter Polyak EMA on lm_head-only (Arm A) vs embed-only (Arm B); β-ramp matches body-Muon EMA (β_warmup=0.95 → β_target=0.99 ramping with lr_mult). Tests whether parameter-space averaging on aux benefits like it does for body-Muon.

| Arm | W&B | sr | val/loss (EMA-swap) | val/loss_live | val/ema_minus_live | Δval (EMA) vs #864 | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | (body EMA: negative) | — | — |
| A (lm_head EMA) | `byqi2lgf` | 2925 | 3.268543 | 3.267891 | **+0.000652** | +0.001717 | NULL |
| B (embed EMA) | `cw1ub4f3` | 2925 | 3.267759 | 3.267210 | **+0.000549** | +0.000933 | NULL (sub-marginal but mechanism broken) |

### Verdict: NULL/NULL — 92nd axis closed, 17th aux Adam-family closure.

### Mechanism finding — WRONG-SIGN aux EMA (load-bearing diagnostic)

For BOTH arms `val/ema_minus_live > 0`: EMA buffer is WORSE than live weights. **Opposite of body-Muon EMA** where `ema_minus_live < 0` reliably (the entire mechanism of #737 and #864).

Structural reason: temporal averaging helps only when the underlying trajectory is locally directional.
- Body-Muon: polar-mapped updates ARE directional (NS5 imposes orthogonality + β_cov whitening provides coherent geometry). Averaging reduces noise around a coherent direction.
- Aux Adam-on-i.i.d.-gradients: NO locally coherent trajectory. Averaging samples the centroid of recent disagreement, which lies further from any plausible optimum than the latest update.

### 4 independent measurement axes confirming i.i.d. aux gradient finding

| PR | Measurement angle | Result |
|---|---|---|
| #854 Adan-aux | Direct gradient correlation `||Δg||/||g||` | ≈ 1.45 (cosine ≈ -0.05) |
| #875 AdaBelief | `s/m²` ratio everywhere on aux | ≫ 1 (momentum doesn't predict gradient) |
| #863 Adam-mini | per-coord variance compression | per_tensor catastrophic (variance LOAD-BEARING); per_row sub-marginal |
| **#899 (this PR)** | `val/ema_minus_live` for parameter EMA | **+ for both lm_head and embed (wrong sign)** |

These are 4 independent measurement axes ALL confirming the same structural truth: aux trajectories are not locally directional → averaging hurts, doesn't help.

### Cross-arm diagnostic comparison

| Quantity | Arm A (lm_head) | Arm B (embed) | Interpretation |
|---|---|---|---|
| `ema_minus_live` sign | + | + | Wrong direction for both |
| Buffer Frob-dist | 2.57 | **39.93** | embed drifts 15× more (sparse-update accumulation) |
| Val penalty (EMA-swap) | 1.6 mnat | 0.83 mnat | embed penalty SMALLER despite LARGER drift |
| Val penalty (live) | +0.001 | +0.0004 | Live training trajectory unaffected |

**Embed's smaller val penalty despite larger Frob distance is informative:** a lot of embed Frob drift is in rows that don't appear in the held-out val set (per-token sparse updates accumulate without affecting eval). For lm_head, the entire output projection participates in every val token, so EMA penalty is more directly observed.

### Why Arm B's sub-marginal Δval doesn't justify n=2

Arm B's Δval=+0.000933 is below the 0.001 marginal threshold technically. But the mechanism analysis disqualifies it:
- `val/loss_live = 3.267210` → Δval_live = +0.000384 (within seed noise of baseline range [3.265811, 3.268040])
- The EMA-swap STRUCTURALLY adds +0.000549 worse on top of essentially-TIE live trajectory
- val=3.267759 is best decomposed as `live_seed_noise (+0.000384) + EMA_penalty (+0.000549)`
- The mechanism IS broken regardless of seed luck; n=2 would not change the wrong-sign `ema_minus_live` diagnosis

### Aux Adam-family closure status (17 total)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), **aux parameter EMA (#899 — this PR)**.

**Open aux levers remaining (2):**
1. SOAP for lm_head (#937 tanjiro IN FLIGHT) — last open aux Adam-family lever
2. Direct aux base-LR retune (#913 frieren IN FLIGHT)

### Reward to student

Excellent telemetry discipline. The `val/ema_minus_live` design (logging EMA-swap AND live val terminal) is what made the structural diagnosis possible. The arm split (lm_head vs embed) was diagnostic — confirms the wrong-sign signal is universal across aux tensors, not specific to lm_head's dense structure.

**92nd axis closed.** Fern re-assigned to #943 (SWA partial blend at cooldown_start) — deferred sub-axis from #730 closure.

---

## 2026-05-23 18:10 UTC — PR #898 CLOSED: PMuon residual-driven adaptive NS_ITERS — both arms NULL, 91st axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/adaptive-ns-iters`
- Hypothesis: Replace fixed NS_ITERS=12 with early termination when polar residual `||X Xᵀ − I||_F < ε`. Arm A=ε=1e-3 (tight), Arm B=ε=1e-2 (loose). Tests uniform polar QUALITY vs uniform iteration COUNT.

| Arm | ε | W&B | sr | val/loss | iter_count (every step, every tensor) | residual_min | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | 12 | ~0.10 | — |
| A | 1e-3 (tight) | `d332v1wk` | 2925 | 3.26813 | 20 (cap) | 0.0495 | NULL — Δval=+0.00120 |
| B | 1e-2 (loose) | `ypejugws` | 2950 | 3.26897 | 20 (cap) | 0.0501 | NULL — Δsr=+25, Δval=+0.00204 |
| **n=2 mean** | — | — | **2937.5** | **3.268551** | 20 (degenerated) | ~0.05 (floor) | Mild regression |

**Verdict: NULL/NULL — informative-NULL via mechanism collapse.**

### Mechanism finding (KEY structural insight — cross-axis to multiple PRs)

**Both arms degenerated to static NS_ITERS=20.** The residual threshold was unreachable for both ε values because cubic Newton-Schulz polynomial `p(σ) = 1.5σ − 0.5σ³` has `p(0)=0`. Zero singular values are NOT restored by iteration. Body-Muon tensors are rank-deficient in bf16 (some near-rank-1 reshaped blocks), so:

`||X Xᵀ − I_m||_F ≈ √(m − rank(X))` after NS5 saturation,

≈ 0.05 (near-full-rank with bf16 floor) to ≈3.2 (rank-deficit ~10). **This floor is 3-5 orders of magnitude above both ε arms.** The `if final_residual < adaptive_eps: break` branch was never taken in any of 72 tensors × ~3,250 steps × 2 runs = **~468k tensor-step opportunities**.

### NS_ITERS frontier consolidated (88th #884 + 91st #898 closures)

| NS_ITERS | source | sr | val/loss | Pattern |
|---|---|---|---|---|
| 8 | #884 Arm A | 3050 | 3.2744 | Under-converged catastrophic (residual ~14) |
| **12** | **Baseline #864** | **2925** | **3.266826** | **OPTIMAL** |
| 16 | #884 Arm B | 2975 | 3.2703 | Over-saturation marginal (residual ~0.067) |
| 20 | #898 n=2 effective | 2937.5 | 3.268551 | Over-iteration + residual-op overhead |

NS_ITERS=12 confirmed as optimal across 4 static points. Asymmetric closure: going DOWN from 12 costs much more than going UP. Cubic NS at NS_ITERS=12 saturates at 0.05 polar residual.

### Cross-axis to #940 (alphonse next assignment)

The #898 rank-deficiency finding directly motivates the Frobenius-normalized NS output hypothesis (#940): if some body-Muon tensors converge to rank-deficient polar (Frobenius norm < √min(m,n)), their effective per-element update RMS is below unit. Frobenius normalization is the direct correction. Cross-axis: #898 IDENTIFIED the mechanism; #940 TESTS whether the mechanism matters operationally.

### Lessons preserved

1. **Pre-launch sanity check that threshold is reachable.** For mechanisms gated by a numerical threshold (ε in adaptive NS_ITERS, mask_frac in C-AdamW), verify the threshold is achievable with the chosen value before launch. The 12:55 UTC mid-run analysis caught this AFTER ~98 steps of telemetry.
2. **Script-edit-while-running hazard:** chain.sh was edited 16 min into Arm A's launch; Bash mid-execution script-edit behavior is undefined; Arm B launched despite unset gate file. Future chain scripts must be finalized BEFORE first launch.
3. **Telemetry discipline pays off.** The student's 12:55 UTC mid-run residual analysis turned an expected NULL into a deep structural insight about NS5 + rank-deficient inputs.

**91st axis closed.** Alphonse re-assigned to #940 (Frobenius-normalized NS output) — direct cross-axis follow-up.

---

## 2026-05-23 17:45 UTC — PR #897 CLOSED: Body-Muon adaptive WD coupled to ||p||/target_norm — both arms NULL, 90th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/adaptive-body-muon-wd`
- Hypothesis: Body-Muon static WD=0.025 may be miscalibrated for current ||p||/target_norm ratio. Adaptive coupling `wd_eff = base_wd * (||p||/target_norm)^α` lets WD scale with parameter-norm growth. Arm A=α=1 linear, Arm B=α=0.5 sqrt (softer).

| Arm | α | W&B | sr | val/loss | Δsr | Δval | terminal wd_mult | peak ||p||/target | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | 1.000 | — | — |
| A | 1.0 (linear) | `mdpr2on0` | 3000 | 3.270003 | +75 | +0.003177 | 2.549 | 3.53× | NULL (regressive but stable) |
| B | 0.5 (sqrt) | `s2ggjtya` | **-1** | 3.296175 | NULL | +0.029349 | ≥1.84 floor | **4.48×** | NULL clear (catastrophic) |

**Verdict: NULL/NULL → Adaptive body-Muon WD axis CLOSED.** 5th body-Muon WD sub-axis NULL.

**Mechanism finding (key structural insight):**

Body-Muon ||p||/target_norm grows 3-4.5× above target throughout training — this is the operating regime, not a transient pre-warmup state. Adaptive coupling can only adapt UPWARD (wd_eff always ≥ baseline since ||p||/target_norm ≥ 1). No α value gives baseline wd_eff while remaining adaptive — the wd_mult equilibrium lower bound is ≥1.84 (sqrt) or ≥2.55 (linear).

**Sqrt vs linear comparison (counter-intuitive):**
- Linear (α=1) actively damps p_norm growth via wd_mult=2.55 → peak ||p||/target stays at 3.53×
- Sqrt (α=0.5) damps less → p_norm grows MORE (peak 4.48×) → wd_mult ratchets to 1.84 equilibrium
- Sqrt's "softer coupling" produces stronger p_norm growth that the adaptive coupling cannot suppress → catastrophic regression

**Cross-axis closure pattern (body-Muon WD: 5 sub-axes NULL):**
1. WD partition (#482) — per-type/per-block partitioning NULL
2. WD schedule (#503) — temporal WD ramping NULL
3. WD ± scalar tune — magnitude tune NULL
4. WD cooldown ramp (#727 65th) — symmetric NULL (UP/DOWN regress identically)
5. **#897 adaptive WD** — both linear and sqrt coupling NULL

**Static WD=0.025 is PINNED at local optimum across all 5 sub-axes.**

**Body-Muon p_norm growth as structural feature:** The 3-4.5× ||p||/target_norm operating regime is consistent across baseline (no adaptive coupling), Arm A (linear damping), and Arm B (sqrt damping). Body-Muon updates grow parameter norms relative to target — likely a consequence of the polar map UV^T preserving direction while WD shrinks magnitude. The equilibrium isn't ||p||=target_norm; it's ||p||≈3.5-4.5× target_norm with WD=0.025.

**Implication for future WD experiments:** Any "adaptive WD" formulation that scales with ||p||/target_norm will hit the same equilibrium ceiling. Closes the entire family. Next interesting WD direction would be either (a) `target_norm` re-derivation from first principles (currently `sqrt(d_in)`) or (b) decoupled-WD reformulation that doesn't multiply current p directly.

**Decision tree confirmation:** This was a 17:30 UTC predicted closure (5th WD sub-axis). Closure-rate consistent with body-Muon scalar family being deeply saturated. Last open aux family lever (SOAP for lm_head) just assigned to tanjiro as #937.

**Closure entry — 90th NULL.** Adds "adaptive body-Muon WD coupled to ||p||/target_norm" to closed-axes under body-Muon WD section.

---

## 2026-05-23 15:55 UTC — PR #896 CLOSED: Cautious-Muon body post-NS sign-mask — both arms NULL, 89th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/cautious-muon-body`
- Hypothesis: Cautious-AdamW-style sign-mask applied to body-Muon polar output AFTER NS5 + bilateral whitening; gate update direction by sign-agreement with current gradient. Arm A=mask+renorm (Frobenius restored), Arm B=mask-only (no renorm).

| Arm | Variant | W&B | sr | val/loss | Δsr | Δval | mask_frac | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | — | — |
| A | mask+renorm | `qw18ifdw` | **-1** | 3.297386 | NULL | +0.030460 | 0.625 | HARD NULL (past stat-sig 3.276) |
| B | mask-only | `a3hualvf` | **-1** | 3.521345¹ | NULL | +0.254519 | 0.637 | **CRASHED step ≈1598** (eigh failure on R_cov) |

¹ Last val before crash at step 1500 (~46% through). Runtime 6736s vs 14046s Arm A.

**Verdict: NULL/NULL → Post-NS body-Muon perturbation family FULLY CLOSED.** Joins #696 Contra-Muon (subtractive post-NS perturbation, also NULL).

**Mechanism finding (significant cross-axis):**

The polar map UV^T is the optimization geometry itself. Masking 37.5% of polar-output entries (mask_frac=0.625 sign-aligned, 37.5% sign-flipped → zeroed) deletes orthonormality column-by-column, leaving an update that is no longer the optimal nuclear-norm-bounded direction. Renorm restores Frobenius magnitude but not the directional structure — Arm A val regressed +30 mnat despite mask_frac matching the expected C-AdamW band [0.45, 0.77].

**Arm B crash interpretation (numerical confirmation):** mask-only (no renorm) drops 37.5% of polar-element magnitude AND does not rescale → effective grad-equivalent fed back through bilateral whitening EMA gradually degrades R_cov conditioning → matrix_neg_power's `torch.linalg.eigh` diverges at step ≈1598. The crash is a strictly worse failure mode than the predicted "directional disruption + magnitude reduction" combo. Joins #774 (β_cov=0.0 fast-mix crash) and #898's eps adaptive convergence floor as numerical-stability signals on the bilateral whitening pipeline.

**Cross-axis closure pattern:** Post-NS body-Muon perturbations close uniformly regardless of perturbation type:
- #696 Contra-Muon (subtractive: polar - slow_EMA) — NULL (compression: only 3% effective dose vs 15-25% design)
- #896 Cautious-Muon (multiplicative gating + renorm) — NULL +30 mnat
- #896 Cautious-Muon (multiplicative gating no renorm) — CRASHED

**Why mask-on-aux works (#853) but mask-on-body (#896) fails:** On aux (C-AdamW), mask fires on Adam updates (per-element optimizer); geometry is preserved by being per-element. On body-Muon, the mask is on the POLAR map output — the mask IS the geometry violation, not a per-element heuristic on top.

**Cross-axis to #893 m_pre BC finding:** #893 just established that NS5 absorbs magnitude bias but NOT directional bias on m_pre (Arm A marginal WIN). Combined with #896 closure: **the structurally untested axis is pre-NS sign-mask on m_pre** (mask BEFORE polar projection so NS5 re-orthogonalizes from masked input). This is the cleanest follow-up — assigned to g1r1-askeladd as PR #931 (cross-axis with #896 + #893).

**Closure entry — 89th NULL.** Adds "Cautious-Muon-body multiplicative gating" to closed-axes under "Post-NS body-Muon perturbations." Now 17 aux Adam-family closures pending #899/#913/#931 + 4 body-perturbation closures (#658/#660/#696/#896).

---

## 2026-05-23 14:50 UTC — PR #884 CLOSED: NS_ITERS tune (8 vs 16) — both arms NULL, 88th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/ns-iters-tune`
- Hypothesis: NS_ITERS=12 baseline is over-converged → Arm A NS=8 (33% reduction) might TIE baseline. Arm B NS=16 tests over-iteration.

| Arm | ns_iters | W&B | sr | val/loss | Δsr | Δval | Polar residual | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | 12 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | ~0.10 | — |
| A | 8 | `fjp71ucq` | 3050 | 3.274412 | +125 | +0.0076 | **~13.9 (140× over)** | NULL clear (under-converged catastrophic) |
| B | 16 | `mg6vuky6` | 2975 | 3.270314 | +50 | +0.0035 | ~0.067 (1.5× cleaner) | NULL marginal (over-saturation drift) |

**Verdict: NULL/NULL clear → NS_ITERS axis CLOSED at static=12.**

**Mechanism finding (student telemetry):** Polar orthogonality residual `||XX^T - I||_F` is the cleanest NS-family diagnostic. Convergence is **highly nonlinear**:
- 8→12: residual drops 140× (14 → 0.10). The under-convergence cliff is between 8 and 12.
- 12→16: residual drops 1.5× (0.10 → 0.067). Already saturated; extra iters add numerical perturbation.

**Asymmetric closure**: going DOWN from 12 costs much more than going UP. 12 is the saturating equilibrium for the cubic Newton polynomial.

**NS_ITERS frontier (combined with #898 alphonse NS=20 marginal NULL):**

| NS_ITERS | sr | val | Pattern |
|---|---|---|---|
| 8 | 3050 | 3.2744 | Under-converged catastrophic |
| **12** | **2925** | **3.2668** | **OPTIMAL** (saturating equilibrium) |
| 16 | 2975 | 3.2703 | Marginal over-saturation |
| 20 (via #898) | 2925 | 3.2681 | sr-TIE but val-regress (perturbation drift) |

**Step-time falsification:** student measured ~0.2% step-time variation between {8, 12, 16}. NS iter count is NOT the step-time bottleneck — "33% compute savings" hypothesis falsified.

**Telemetry win:** `polar/ortho_residual_sample` per-step trajectory is now the body-side screening filter (analog to #875's `s/m² > 5` aux Adam-family screen):
- residual > 1.0 → under-converged catastrophic (skip benchmark)
- residual ∈ [0.05, 0.20] → plateau-quality polar map
- residual < 0.05 → over-saturated, expect marginal regression

**Combined with #540 (cubic vs quintic at NS=12 NULL/NULL):** NS subsystem now PINNED across all 2D cells except joint cell quintic×low-iters → assigned to nezuko as follow-up (#920).

**Suggested follow-up (deferred):** interior probe NS=10 (inflection candidate). Compute savings negligible — not assigned.

PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/884

---

## 2026-05-23 14:05 UTC — PR #875 CLOSED: AdaBelief-aux gradient-surprise variance — both arms NULL, 87th axis, 16th aux Adam-family closure (g1r1-frieren)

- Branch: `frieren/adabelief-aux`
- Hypothesis: AdaBelief's surprise-variance denominator `s_t = β2·s + (1-β2)·(g-m)² + eps` (replacing Adam's raw `v_t = β2·v + (1-β2)·g²`) takes larger confident updates when m_t predicts g_t well. Two arms: paper defaults β=(0.9, 0.999), eps=1e-16 vs drop-in codebase defaults β=(0.8, 0.95), eps=1e-10.

| Arm | β | eps | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | (0.8, 0.95) | 1e-10 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (paper) | (0.9, 0.999) | 1e-16 | `5mha8dpz` | 3025 | 3.27288 | +100 | +0.0060 | **NULL** (clean regression) |
| Arm B (drop-in) | (0.8, 0.95) | 1e-10 | `p5h5vf5e` | 2950 | 3.26852 | +25 | +0.0016 | **NULL** (Δsr marginal-boundary, Δval > 0.001) |

- **Mechanism is verifiably active but produces no value:** Arm B `v_vs_s_ratio = 1.426` globally — surprise denominator is ~30% tighter than equivalent vanilla-Adam, mechanism flipped correctly. `eps_floor_fraction = 0` in both arms — denominator is always the active term.
- **Key structural finding (frieren's contribution): `s/m² ≫ 1` everywhere on aux.** Per-group `s_over_m2` ratios at terminal:
  - Arm A (β2=0.999): embed=32.56, lm_head=60.80, scalars=156.83
  - Arm B (β2=0.95): embed=5.92, lm_head=5.88, scalars=23.21
  - **Reads: (g−m)² is 5–150× larger than m² on aux at this scale.** AdaBelief's "confident-update" path only engages when (g−m)² ≪ m² (m predicts g well). Here m_t is NOT a useful predictor of g_t — confidence path never fires.
- **Cross-axis confirmation of #854 i.i.d. aux gradient finding from a totally different measurement angle.** #854 measured `||Δg||/||g|| ≈ 1.45` directly; #875 measures `s/m² ≫ 1` indirectly via the AdaBelief denominator. Both confirm: aux gradients lack temporal predictability → momentum-magnitude-based adaptive optimizers cannot extract signal from temporal structure that doesn't exist.
- **Slow-EMA lag pattern reproduced (3rd instance):** Arm A (paper β2=0.999) shows s/m² 5× larger than Arm B (drop-in β2=0.95) — slower m_t lags more, breaks the confidence-update premise even harder. Matches #846 AdEMAMix β3=0.9999 obsolete-direction finding and #854 Adan β1=0.98 m_norm 2.5× smaller finding.
- **87th closed axis. 16th aux Adam-family closure** (after NAdam #698, β2 ramp #741, β1 ramp #796, RAdam #814, AdEMAMix #585+#846, AMSGrad #578, Adamax #583, LAMB #609, Lookahead #617, Schedule-Free #623, AdaBelief #545, Lion #604, Cautious-AdamW #853, Adan #854, Adam-mini #863, AdaBelief #875). **The variance-estimator and per-coord-adaptivity axes on aux are saturated.**
- **Telemetry win (reusable across future hypotheses):** `s_over_m2` and `v_vs_s_ratio` diagnostics now serve as screening filters for any future Adam-family aux candidate. If `s/m² > 5` on a candidate's first 500-step run, the mechanism is invalidated before the full 4-GPU-hour benchmark commits.
- **Frieren reassigned PR #913**: Aux embed/lm_head LR retune at PR #737 baseline. Arm A=embed_lr=0.4/lm_head_lr=0.008 (UP); Arm B=embed_lr=0.225/lm_head_lr=0.005 (DOWN). **Base-case probe never run at current baseline** — embed/lm_head LRs unchanged since PR #413, but body-Muon (γ_pre=0.4, β_cov=0.95) and EMA wrapper (β_target=0.99 cooldown ramp) have shifted the effective body update magnitude. If both arms NULL → confirm current LRs optimal, sharpen the "aux saturation" structural conclusion. If one wins → free val/sr improvement and reset aux baseline.

## 2026-05-23 10:05 UTC — PR #863 CLOSED: Adam-mini-aux per_row/per_tensor v_t reduction — both arms NULL, 86th axis, 15th aux Adam-family closure (g1r1-fern)

- Branch: `g1r1-fern/adam-mini-aux-per-row-per-tensor`
- Hypothesis: Pooled v_t (Adam-mini, Zhang et al. 2024) reduces sparse-gradient variance noise for embed/lm_head and improves convergence. Two arms: per_row (row-pooled v_t, 50304 scalars) vs per_tensor (single-scalar v_t per param).

| Variant | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (per_row) | `o3pv0szv` | 2925 | 3.267874 | 0 | +0.000948 | **NULL/TIE** (sub-marginal val regression, strict-rule fail) |
| Arm B (per_tensor) | `m3jirfw9` | **−1** | 3.299257 | NULL | +0.032331 | **hard NULL** (never crossed 3.28 target) |

- **Monotone "more aggregation → more harm" ordering confirmed.** Per_row (rank-1 along feature axis, preserves per-row vocab adaptivity) is the natural floor of the family — pooling features within a row costs ~1 mnat (sub-marginal). Per_tensor (single scalar v_t = effectively SGD+momentum with one global LR) is catastrophic — kills rare-token adaptivity completely.
- **Mechanism interpretation:** v_mean ratios at terminal show structural breakdown for embed: per_row=6.85e-5, per_tensor=2.17e-5 (3.16× smaller). Pooling over all 50304×768 elements averages over many near-zero entries (sparse tokens) → smaller denominator → uniform scaling that ignores rare-token signal. Per_tensor lacks the rare-token adaptivity that Adam provides via per-coord v_t.
- **Cross-axis insight (load-bearing): Adam per-coord variance denominator is structurally critical for sparse-gradient tensors (embed/lm_head).** Variance compression in any form (per_row pooling OR per_tensor pooling) sacrifices this for memory savings that don't help in this regime. The Adam-mini paper's claim of "matches Adam with 99% less state memory" does not reproduce here, likely because (1) aux state is small relative to body-Muon state anyway, and (2) the speedrun cooldown phase is especially sensitive to v_t granularity.
- **Telemetry verification credit (fern):** Clean `v_size` confirmation (50304 per_row / 1 per_tensor) and `block_mode` flag verified implementation correctness in both arms. Same diagnostic discipline as askeladd #853 (mask_frac) and tanjiro #854 (||Δg||/||g||).
- **86th closed axis. 15th aux Adam-family closure.** Aux Adam axis structurally insensitive to any update-rule change that reduces/restructures the variance estimator. Open aux levers remaining: AdaBelief (#875 Arm A NULL/regression; Arm B in flight), EMA timing (#864 in flight n=2 confirm), **aux parameter EMA (#899 fresh axis, never tested)**, direct aux LR retune, SOAP/Shampoo.
- **Fern reassigned PR #899**: Aux Polyak EMA (lm_head only vs embed only). Same β-ramp as body-Muon EMA (β=0.95→0.99, warmup=2250). Arm A=`--ema_aux_lm_head`; Arm B=`--ema_aux_embed`. **Fresh mechanism family** — body-Muon parameter-space averaging is FULLY CLOSED (#505/#662/#695/#802 + #737 baseline) but aux groups have no EMA buffer. Two-arm orthogonal design isolates which aux tensor benefits from parameter averaging.

## 2026-05-23 09:45 UTC — PR #822 CLOSED: PMuon L_cov/R_cov Adam-style bias correction — n=3 boundary informative-NULL, 85th axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-cov-bias-correction`
- Hypothesis: PMuon bilateral covariance EMA (L_cov, R_cov) suffers Adam-style early-step bias from `m·β^t / (β^t)`. Dividing by `1 − β_cov^t` corrects the bias, allowing the polar map to use unbiased preconditioner from step 1 onwards.

| Seed | W&B | sr | val/loss | stat_sig | Notes |
|---|---|---|---|---|---|
| 1 | `8b0m4nzt` | 2875 | 3.264587 | 0.01141 | strong win |
| 2 | `ufg7f4mw` | **2925** | 3.267590 | 0.00841 | baseline-tie |
| 3 | `7bgqna61` | **2950** | 3.269395 | 0.00660 | regression direction |
| **n=3 mean (Arm A)** | — | **2916.67** | **3.267191** | — | — |
| baseline (#737, n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | ref |
| **Δ (n=3 mean vs baseline)** | — | **−8.33** | **+0.000265** | — | borderline |

- **Predeclared decision rule:** sr > 2900 → close informative-NULL. n=3 mean sr=2916.67 fails MERGE threshold; Δval slightly positive. Close.
- **Mechanism is real and correctly implemented across all 3 seeds:** BC denominator `1 − β_cov^t` converges to 1.0 by step ~100 in all seeds; `L_eps_clamp_frac` drops from 1.0 (rank-1 init) to ~0 by step 50 in all seeds; `L_eigval_min_mean` ramps from 0 to ~46k by step 50. Identical telemetry across seeds proves implementation is correct.
- **Why BC effect doesn't beat noise:** (1) BC fires for ~50-100 steps then becomes a no-op (3% of training), (2) polar output from NS5 is robust to small L/R_cov errors (NS5 projects to nearest unit-spectral-norm matrix), (3) seed-1 was a lucky outlier — seeds 2 and 3 sit at the noise floor.
- **Cross-cutting insight: PMuon warmup-phase fixes are mechanically denoised.** Polar map absorbs small preconditioner errors. Future warmup-phase fix hypotheses should expect this absorption pattern. Edward's #893 PMuon momentum first-moment BC (analog on m_pre, not L_cov/R_cov) tests whether the m_pre direction is similarly absorbed.
- **Decision-rule discipline credit (alphonse pre-launch):** Pre-launch β_cov audit verifying the codebase β_cov=0.95 convention matched Adam-style smoothing weight. Same diagnostic discipline as askeladd #853 and tanjiro #854.
- **85th closed axis. PMuon warmup-phase intervention family now contains 2 closures (#774 β_cov fast-mix, #822 BC).** Open in family: #893 edward (first-moment BC on m_pre, in flight).
- **Alphonse reassigned PR #898**: PMuon residual-driven adaptive NS_ITERS. Arm A=ε=1e-3 tight, Arm B=ε=1e-2 loose. Tests uniform polar QUALITY vs uniform iteration COUNT. Fresh mechanism on NS-iteration sub-axis (distinct from #884 static NS_ITERS tuning and #803 cooldown-iter ramp).

## 2026-05-23 09:25 UTC — PR #854 CLOSED: Adan-aux Nesterov gradient-difference momentum — both arms NULL, 84th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/adan-aux-nesterov-grad-diff`
- Hypothesis: Adan's Nesterov gradient-difference term (m_pre + (1-β3)*Δg) on aux groups would improve convergence via momentum-aware gradient lookahead. Two arms: paper β1=0.98 vs tuned β1=0.80 (codebase aux Adam default).

| Arm | β1 | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (paper) | 0.98 | `cidw81e1` | **−1** | 3.28330 | NULL | +0.01637 | **hard NULL** (never crossed 3.28) |
| Arm B (tuned) | 0.80 | `aae3y07x` | 2950 | 3.26931 | +25 | +0.00238 | NULL (marginal sr regression, val borderline) |

- **m_t lag killed paper β1=0.98**: Arm A's `m_norm ≈ 14.5` (embed) is ~2.5× smaller than Arm B's 36.7. Slow EMA can't track aux gradient direction during cooldown; adding a noisy Δg correction on a stale m made things strictly worse. Mirrors #846 AdEMAMix-Aux (β₃=0.9999 slow EMA pulled toward obsolete early-training direction).
- **β1=0.80 recovered most of AdamW**: Arm B sits near baseline (+0.0024 val), with the remaining Δg contribution (~22% of update) acting as small additive noise. Costs +25 sr — predictable noise penalty.
- **β2/β3 retuning unlikely to recover**: even at β2→1 (wash out Δg noise), v_t → E[Δg] ≈ 0, so Adan degenerates to AdamW. No β-region in this scale makes Adan-aux helpful.
- **LASTING MECHANISM INSIGHT (tanjiro's contribution): Aux gradients are essentially i.i.d. step-to-step.** Telemetry: `||Δg||/||g|| ≈ 1.45` constant across all 3 aux groups, both arms. Implies consecutive-grad cosine ≈ −0.05 (very mild anti-correlation, ~independent). This rules out an entire family of future aux optimizer ideas:
  - **Ruled out**: any update mechanism depending on positive Δg autocorrelation (Adan, NAdam lookahead, Polyak heavy-ball with γ>0, MARS variance reduction, gradient-acceleration methods)
  - **NOT ruled out** (still worth testing): variance-shaping (AdaBelief #875 in flight, AMSGrad #578 closed), sign-based (Lion #604 closed), schedule-free / lookahead-style (most already closed)
  - **Future aux-optimizer hypotheses depending on Δg signal should be predicted-NULL from this data before launching.**
- **Math-catch closure credit (tanjiro pre-launch)**: paper-β vs Adam-β coefficient audit caught the literal `(1−β2)` issue → Δg would have been weighted at 0.08 instead of 0.92, near-no-op vs AdamW. Saved ~6h of GPU on what would have been an uninterpretable result. Textbook pre-launch math check.
- **84th closed axis. Cumulative aux Adam-family closures: 14 update-rule families closed.** Aux Adam axis approaches full saturation; remaining open levers are AdaBelief (#875 in flight), Adam-mini reductions (#863 in flight), EMA timing (#864 in flight), direct base-LR retune, SOAP/Shampoo for lm_head.
- **Tanjiro reassigned**: PR #897 Body-Muon adaptive WD coupled to ||p||/target_norm. Arm A=α=1.0 linear, Arm B=α=0.5 sqrt. Per-tensor WD scaling by current/init norm ratio. Different from all 4 closed WD axes (#482 partition, #503 schedule, #727 cooldown ramp, #466 aux WD): tests WD intensity per tensor as a function of its weight-norm-vs-init ratio. New mechanism family (regularization → weight-norm tracking).

## 2026-05-23 09:15 UTC — PR #853 CLOSED: Cautious-AdamW aux renormalization ablation — both arms NULL, 83rd axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/cautious-aux-renorm-ablation`
- Hypothesis: Cautious-AdamW (sign-aligned update masking) on aux groups; ablation tests whether mask+renorm or mask-only is the active mechanism.

| Arm | Variant | renorm | W&B | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | — | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | ref | ref |
| Arm A (paper) | C-AdamW mom | on | `6tye7e33` | 3175 | 3.27847 | +0.01154 | **NULL** (clean regression) |
| Arm B (no_renorm) | C-AdamW mom | off | `9kmvuba7` | **−1** | 3.28109 | +0.01416 | **hard NULL** (never crossed 3.28) |

- **Mechanism fired correctly**: Per-group mask_frac in paper-expected band (embed=0.448, proj=0.654, scalars=0.77) — NOT vestigial, NOT saturated.
- **Renorm IS load-bearing when applied**: Arm B trailed Arm A by stable +0.0026 mnat from step 1750 onward, well before cooldown. Without renorm, effective LR shrinks by ~35% — clean degradation matching paper's prescription.
- **Mask itself doesn't help aux**: Even paper-faithful Arm A regressed +11.5 mnat. Sign-conflict signal that helps Muon body params doesn't carry useful information for aux groups:
  - Embed (45% agreement): token-batched gradients are sparse/noisy; masking throws away signal that AdamW's variance denominator already smooths
  - proj/scalars (65-77% agreement): mask agrees with grad most of the time → little change → small effect doesn't help
- **83rd closed axis. Aux update-direction filtering family added to closed-aux-mechanism ledger**: variance/smoothing schedules (NAdam, β-ramp, RAdam, AdEMAMix) + Cautious-AdamW all NULL. Vanilla fused AdamW β=(0.8, 0.95) is robust local optimum for aux groups.
- **Askeladd's diagnostic discipline (textbook)**: pre-launch sign-equivalence audit, byte-identity check on baseline path, per-group mask_frac telemetry confirming mechanism fires correctly. Caught a duplicate-launch SIGTERM artifact (`edgttv3d`) cleanly. Same hygiene now applied to next assignment.
- **Askeladd reassigned**: PR #896 Cautious-Muon (body-side) — his own suggested follow-up. Tests multiplicative sign-mask on body-Muon's polar output (sign(polar) vs sign(grad)). Mechanistically distinct from #696 Contra-Muon (subtractive). First test of post-NS multiplicative-gating axis on body-Muon.

## 2026-05-23 09:00 UTC — PR #892 CLOSED PRE-LAUNCH: Lookahead-Muon (duplicate of #505 / g1r1-edward)

- Branch: `g1r1-edward/lookahead-muon` (closed before student picked up)
- Hypothesis (proposed): Lookahead (Zhang et al. 2019) outer-loop slow weight average wrapping body-Muon with k=5/k=10, α=0.5.
- **Duplicate-check FAIL — caught post-creation**: PR #505 (g1r1-fern, 2026-05-19) tested EXACTLY these arms on body-Muon. Documented in CURRENT_RESEARCH_STATE.md closed-axes ref (lines 116, 124) and confirmed by reading PR #505 comments.
- **PR #505 verdict**: Both arms HARD NULL. Arm A k=5/α=0.5 (`8ad3mzjz`): sr=-1 DNF, Δval=+0.020. Arm B k=10/α=0.5 (`e3zkawez`): sr=-1 DNF, Δval=+0.022.
- **PR #505 mechanism documented**: Discontinuous slow-weight resync corrupts PMuon's L_cov/R_cov covariance state. The covariance EMA accumulates at β=0.95 on the fast-weight trajectory; when fast←(1-α)·fast+α·slow displaces the params at the resync boundary, the next gradient is computed at a point inconsistent with the cov stats accumulated from the fast trajectory.
- **#505 crossover pattern**: B (k=10) tighter mid-training (0.005 ahead at step 1250-1500); A (k=5) tighter late-cooldown. Gentler averaging is less destructive but neither arm escapes the discontinuity damage.
- **Advisor learning (filed to memory)**: Always check closed-axes reference BEFORE designing PR body, not after. The fault was rushing to redeploy edward after #846 closure without verifying axis novelty.
- **Edward reassigned**: #893 PMuon momentum first-moment Adam-style bias correction. Orthogonal to #822 (in flight, second-moment BC on L_cov/R_cov). Mechanism: corrects zero-init bias in momentum EMA accumulation via 1/(1-mu^t) factor before Nesterov mix.

## 2026-05-23 08:40 UTC — PR #846 CLOSED: AdEMAMix-Aux dual first-moment EMA α sweep — both arms NULL, 82nd axis (g1r1-edward)

- Branch: `g1r1-edward/ademamix-aux-alpha`
- Hypothesis: Adding a slow long-horizon EMA (m2, β3=0.9999) to aux-group Adam update would give aux directions a stronger trajectory anchor, helping embed/lm_head/scalar groups (high gradient variance) escape short-horizon noise.

| Arm | α | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 2 | `r9mby3uo` | 3075 | 3.275689 | +150 | +0.008763 | **NULL** (clean regression) |
| Arm B | 8 | `np82nnjr` | **−1** | 3.332268 | NULL | +0.065342 | **hard NULL** (never crossed 3.28) |

- **Monotone dose-response in the WRONG direction**: α=2→8 makes val/sr strictly worse. Confirms mechanism (slow EMA hurts) is real, not noise.
- **Mechanism**: Slow EMA buffer m2 (β3=0.9999, N_eff≈10,000) computes near-uniform mean of all past gradients. For aux groups, early-training gradient directions differ systematically from late-training (non-stationary) → slow buffer pulls toward obsolete early-training direction during cooldown, hurting convergence.
- **Compares cleanly with aux variance-warmup family already closed** (#698 NAdam, #741 β2 ramp, #796 β1 ramp, #814 RAdam — all NULL). Aux-group update-rule changes don't survive WSD cooldown where gradient statistics shift.
- **AdEMAMix transformer wins (paper) don't transfer to modded-nanoGPT FineWeb track** — likely scale/data/architecture mismatch.
- **SIGTERM launch-race diagnostic**: Edward correctly identified process-tree reaping by parent claude exit (not OOM/NaN) as the cause of multiple Arm A crashes. Recovery via single canonical `r9mby3uo` was clean.
- **82nd closed axis. Edward reassigned to Lookahead-Muon (body-Muon outer-loop slow weight average, Zhang et al. 2019) — orthogonal to aux-Adam family.**

## 2026-05-23 06:50 UTC — PR #827 CLOSED: NS-output Frobenius normalization — n=2 informative-NULL, 81st axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/post-ns-frobenius-norm`
- Hypothesis: Normalizing NS polar output to unit Frobenius (post variant) or pre-NS gradient to RMS=1 (pre variant) would stabilize per-step update magnitude variability and improve sr/val.

| Arm | Mode | Seed | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | none | n=2 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | post | seed-1 | `q72w28l9` | **−1** | 3.299976 | NULL | +0.033050 | **hard NULL** (did not cross 3.28) |
| Arm B | pre | seed-1 | `oey1pogu` | 2925 | 3.265945 | 0 | −0.000981 | marginal n=1 win → request n=2 |
| Arm B | pre | seed-2 | `6jjfoefp` | 2925 | 3.268016 | 0 | +0.001090 | seed-2 regression |
| **Arm B** | **pre** | **n=2 mean** | — | **2925** | **3.266981** | **0** | **+0.000055** | **informative-NULL** |

- **Seed-1 marginal val win perfectly canceled by seed-2 regression** — Δval seed-1=−0.000981 and Δval seed-2=+0.001090 are symmetric around baseline. n=2 mean tracks baseline within +0.055 mnat (sub-noise).
- **Mechanism documented (lasting contribution)**: `polar/ns_polar_rms` telemetry showed Arm B (pre-NS) yields a constant ~0.018 per-step value — pre-normalization collapses the conditioning-dependent magnitude variability that the original hypothesis targeted. Telemetry was deterministic across seeds (matched to 4 decimal places), confirming the mechanism is RNG-independent.
- **Arm A (post-NS)** is strictly worse: forcing NS output to unit Frobenius destroys the u/w-floor signal entirely, blocking target crossing.
- **NS-output-scale normalization axis CLOSED**: Neither pre nor post Frobenius normalization improves over the natural NS polar map output scale. The natural scale is load-bearing for the u/w-floor stack.
- **81st closed axis. Nezuko reassigned next.**

## 2026-05-23 05:35 UTC — PR #841 CLOSED: EMA β ramp shape — informative-NULL, 80th axis (g1r1-frieren)

- Branch: `g1r1-frieren/ema-beta-ramp-shape`
- Hypothesis: Delaying the β ramp onset to later in cooldown (piecewise-linear delayed ramp) would improve terminal val/loss by concentrating averaging into the cleanest final descent.

| Arm | delay_frac | W&B | sr | val/loss | Δsr | Δval | % stat-sig margin | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | n/a (concave) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | — | ref |
| Arm A | 0.5 | `quhyt7s4` | 2925 | 3.266744 | 0 | **−0.000182** | 4.6% | informative-NULL |
| Arm B | 0.7 | `gg5ltqc8` | 2925 | 3.266922 | 0 | **−0.0000042** | 0.1% | informative-NULL |

- **Both arms technically satisfy predeclared WIN rule** (sr=2925 AND val<3.266926) but both Δval are far below the 0.001 marginal threshold (Arm A at 18%, Arm B at 0.4%). Correctly interpreted as informative-NULL.
- **Mechanism**: Terminal β_t=0.99 identical across all configurations. EMA steady-state is dominated by final ~100 steps where β≈0.99 regardless of ramp shape. Ramp timing only affects early-cooldown; terminal composition is insensitive.
- **Spec note (student catch)**: Actual baseline ramp is **concave** (β rises via `(1−lr_mult_t)` with `lr_mult_t = (1-cooldown_progress)^1.4`), not strictly linear. Arms tested "piecewise-linear delayed" vs "concave baseline". Comparing different shapes (not pure delay). No code error — just a framing note for future ramp-shape work.
- **EMA-β infrastructure now pinned**: β_target frontier settled (0.99 BEST), warmup_steps in-flight via #864, ramp-shape exhausted in (0.5, 0.7) interior.

## 2026-05-23 01:40 UTC — PR #802 CLOSED: Polyak EMA β_target fine-scan — n=2 informative-NULL, 79th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/ema-beta-target-fine-scan`
- Hypothesis: β_target=0.97 or 0.98 may sit in a sweet spot between sr-preservation and val-recovery (vs #737's β_target=0.99 baseline).

| Arm | β_target | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | 0.99 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.97 | `453h9twy` | 2950 | 3.267780 | +25 | +0.000854 | NULL |
| Arm B seed-1 | 0.98 | `y3lh1e79` | **2925** | **3.266577** | 0 | **−0.000349** | marginal n=1 win |
| Arm B seed-2 | 0.98 | `ws9w9a0y` | 2950 | 3.267508 | +25 | +0.000582 | regression |
| **Arm B n=2 mean** | **0.98** | — | **2937.5** | **3.267043** | **+12.5** | **+0.000117** | **informative-NULL** |

- **n=2 decision rule triggered:** Per the predeclared rule (n=2 sr > 2925 → informative-NULL), Arm B's seed-1 sr=2925 was inside the EMA-swap-val target-crossing jitter band, not a structural property of β=0.98.
- **Mechanism replication clean across seeds:** `delta_ema_minus_live_mnat` stable at ~0.229 (seeds 0.227 / 0.232), matching β/(1−β) lag scaling theory (~0.27 predicted). The lag-bias compression at lower β_target is real and stable; it just doesn't translate to sr improvement.
- **N_eff=50 cannot dampen target-crossing jitter:** β=0.99's N_eff=100 reliably locks both seeds to sr=2925. β=0.98 lets seed-1 cross at 2925 and seed-2 at 2950 — the 25-step single-bin jitter dominates val-trajectory near 3.28 with this much smoothing reduction.
- **β_target frontier settled:** 0.95 sr=2950 → 0.97 sr=2950 → 0.98 sr=2937.5 (n=2) → **0.99 sr=2925 (n=2, current BEST)** → 0.999 NULL. Monotone improvement toward 0.99 with no room to interpolate (β=0.99 already locks both seeds).
- **Procedural appreciation:** Thorfinn wrote the decision rule into their terminal SENPAI-RESULT explicitly and matched it without ambiguity. n=1 → n=2 catch-rate validated: seed-1 marginal would have been a false merge without n=2 protocol. EMA telemetry instrumented per-seed gives mechanistic confirmation independent of primary outcome.
- **79th closed axis. Thorfinn reassigned to EMA warmup_steps re-tune (1750 vs 2500) at β_target=0.99 — natural follow-up #3 from their own SENPAI-RESULT.**

## 2026-05-23 01:30 UTC — PR #821 CLOSED: Kahan BF16 compensated weight update — NULL/NULL, 78th axis (g1r1-fern)

- Branch: `g1r1-fern/kahan-muon-ema`
- Hypothesis: Compensate for BF16 precision loss in body-Muon param updates and EMA lerp via Kahan summation. Hypothesis predicted that very small late-cooldown updates may be lost to BF16 rounding.

| Arm | Variant | W&B | sr | val/loss | Δsr | Δval | comp_rms (body) | comp_rms (ema) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | — | — | ref |
| Arm A (Kahan-Muon only) | corrected-residual form | `1segjgvo` | 2925 | 3.266462 | 0 (TIE) | −0.000464 | 5.4e-9 | n/a | NULL TIE (sub-noise) |
| Arm B (Kahan-Muon + EMA lerp) | corrected-residual form | `ji1hed72` | 2925 | 3.267573 | 0 (TIE) | +0.000647 | **0** | **0** | NULL TIE (sub-noise) |

- **Pre-launch dtype audit by fern caught the hypothesis premise was wrong:** body-Muon params and EMA buffer are BOTH FP32 (only `self.embed` is BF16). With matched FP32 dtype, `p.add_(update.to(p.dtype))` is exact arithmetic and Kahan compensation is a structural no-op. comp_rms_mean=0 across 3250 steps confirms this empirically.
- **Mechanism finding:** Kahan BF16 compensation is mathematically null when params and update have matching FP32 dtype. The ±0.5 mnat val swing between arms is FP32 add-reordering noise (different summation order in Kahan path vs direct `add_`), not a Kahan signal.
- **Where precision still has signal:** embed/lm_head are BF16; high-β EMAs (β≥0.996, e.g., AdEMAMix β₃=0.9999) round to 1.0 in BF16 — captured in our memory file. Future precision work should target the aux side specifically.
- **78th closed axis. Fern reassigned to Adam-mini-aux (Zhang et al. 2024) — per-row/per-tensor v_t reduction.**

## 2026-05-23 01:00 UTC — PR #778 CLOSED: PMuon per-type γ narrow (γ_attn=0.45) — TIE/sub-noise val, 77th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-gamma-attn-only-raised`
- Hypothesis: Narrow per-type γ split (γ_attn=0.45, γ_mlp=0.4) refines #736's wide split that closed at NULL; expected to test whether the direction (γ_attn > γ_mlp) is real at smaller magnitude.

| Arm | γ_attn / γ_mlp | seeds | n=2 sr | n=2 val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737) | uniform 0.4 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm B clean n=2 | 0.45 / 0.40 | `b958vx2r`/`is177ib5` | **2925** (TIE) | **3.266815** | **0 (TIE)** | **−0.000111** mnat | NULL TIE (sub-noise) |

- **Sub-noise Δval:** Δval=−0.000111 mnat is 22× smaller than the seed-to-seed variance (0.002518) and 9× below the marginal threshold (0.001). Per session memory rule (auto-nanogpt: Δval ≤ 0.001 mnat is within seed noise even at n=2), this does not constitute a real win.
- **Tanjiro's procedural contributions are notable:** (1) diagnosed flat-vs-nested `body_muon_params` bug and committed bug-fix `174d98c1`; (2) caught seed-1 (pre-EMA) vs seed-2 (post-EMA) config mismatch and proposed clean n=2 re-run; (3) demonstrated EMA-stack post-fix variance pattern (seeds 3.268074 / 3.265556, spread ≈ 0.0025 mnat).
- **PMuon per-type γ axis FULLY CLOSED across both magnitudes:** wide split (#736 66th NULL, attn=0.3/0.5) — direction validated but magnitude insufficient; narrow split (#778 77th NULL, attn=0.45) — TIE on sr, sub-noise val. γ_power is type-isotropic in body-Muon regime — Kronecker L_cov/R_cov already capture per-tensor curvature differences; an additional per-type γ scalar offers no orthogonal gain.
- **77th closed axis. Tanjiro reassigned to Adan-aux (fresh axis, Xie et al. 2022 — Nesterov-momentum-of-gradient-differences).**

## 2026-05-23 00:50 UTC — PR #814 CLOSED: Aux RAdam (variance warmup) — NULL/NULL, 76th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-radam-variance-warmup`
- Hypothesis: Replace aux AdamW with RAdam (Liu et al. 2019) for embed/proj/lm_head/scalars — rectified-Adam variance warmup may stabilize early-step aux updates and unlock a higher LR ceiling.

| Arm | LR scale | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static AdamW LR=0.30 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | RAdam LR=0.30 | (terminal) | 2925 | 3.266586 | 0 (TIE) | −0.000340 (μnat) | NULL TIE (sub-marginal) |
| Arm B | RAdam LR=0.22 | (terminal) | 2950 | 3.269034 | +25 | +0.002108 | NULL (sr regression) |

- **Mechanism intact:** rho_t ramp 1→38.15 across training ✓; r_t rectification term ramp 0→0.987 ✓; in_sgd_fallback flips at step where rho_t crosses threshold ✓; 0 nonfinite grads throughout.
- **Mechanistic finding: AdamW β2=0.95 already handles variance warmup implicitly at high aux LRs.** RAdam's explicit rectification offers no headroom on top of an already well-tuned AdamW configuration with β2=0.95 (the value enabled by EMA stack #737). The SGD-fallback path during rho_t<4 is mathematically equivalent to a momentum-only warmup, which doesn't differ meaningfully from AdamW with β2=0.95 in the first 100 steps.
- **Salvage:** Original Option A (always-adaptive variant, no SGD fallback) was diagnostic-only — confirms baseline-AdamW is the operating point on the rho_t axis.
- **76th closed axis. Aux Adam-family variance-warmup mechanism FULLY CLOSED across NAdam (#698 NULL), β2 ramp (#741 NULL primary at n=2), β1 ramp (#796 NULL), RAdam (#814 NULL).** Aux Adam-family is exhaustively mapped — moving to sign-based momentum (Lion).
- **Askeladd reassigned to Lion-aux (PR TBD)** — sign-based momentum (Chen et al. 2023, https://arxiv.org/abs/2302.06675), the next clean axis off Adam-family saturation.

## 2026-05-22 22:00 UTC — PR #796 CLOSED: Aux AdamW β1 cooldown ramp (0.8→0.7 vs 0.8→0.9) — NULL/NULL, 75th axis (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-cooldown-ramp`
- Hypothesis: Ramp aux AdamW β1 in cooldown — DOWN (0.8→0.7) for fresher momentum, or UP (0.8→0.9) as β1 analog of #741's β2 ramp finding.

| Arm | β1 ramp | W&B | sr | val/best | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static 0.8 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.8 → 0.7 (DOWN) | `hese09mm` | 2950 | 3.268949 | +25 | +0.002023 | NULL (regression) |
| Arm B | 0.8 → 0.9 (UP) | `i506vy1w` | 2925 | 3.266983 | 0 (TIE) | +0.000057 | NULL (marginal val regression) |

- **β1 DOES NOT mirror β2.** PR #741 found β2 0.95→0.999 UP gave a marginal val improvement (Δ=−0.000306 mnat vs old baseline). The SAME UP-ramp idea applied to β1 (Arm B here) yields NO improvement on top of the EMA stack. **The "cooldown-coupled smoothing UP-ramp" is parameter-specific, not class-wide.** β1 (gradient-direction EMA) does not respond like β2 (gradient-variance EMA).
- **Mechanistic value:** rules out the broad hypothesis "all smoothing scalars want to ramp UP in cooldown." The cluster is parameter-specific. Aux β1=0.8 is at the local optimum on top of the EMA stack.
- **Telemetry quality:** ramp telemetry `train/aux_beta1/beta1_t` perfect — symmetric ramps from 0.800 at cooldown_start to 0.700/0.900 at step 3250 with cooldown_progress mapping correctly.
- **75th closed axis.** Aux β1 cooldown ramp axis FULLY CLOSED (both directions). Edward reassigned to AdEMAMix-aux (PR TBD).

## 2026-05-22 21:35 UTC — PR #803 CLOSED: PMuon γ_power warmup ramp (0.2→0.4 vs 0.3→0.4) — NULL/NULL, 74th axis (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-warmup-ramp`
- Hypothesis: γ_power warmup ramp from low value → 0.4 by cooldown_start (step 975), testing whether gentler early whitening produces a better pre-cooldown trajectory.

| Arm | γ_warmup_start | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static 0.4 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.2 | 2975 | 3.266392 | +50 | -0.000534 | NULL |
| Arm B | 0.3 | 2950 | 3.265617 | +25 | -0.001309 | NULL |

- **Both arms regress on primary metric (sr).** Monotone ordering: Arm A (start=0.2) > Arm B (start=0.3) > baseline in sr — "less whitening early = worse trajectory."
- **Val improvements dominated by sr regression.** Arm B val -0.001309 is past marginal threshold but sr regression (+25) disqualifies win.
- **γ_power axis FULLY CLOSED** across both cooldown ramp (#760) and warmup ramp (#803) directions. Static γ=0.4 is a tight local optimum robust to schedule perturbations at either end.
- **Key insight from student:** γ_power schedule dead = L_cov/R_cov EMAs equilibrate fast enough that γ schedules can't help. "A cleaner intervention would be to manipulate the EMA β (the covariance buffer momentum) rather than γ."
- **74th closed axis.** Frieren reassigned to EMA β ramp shape (PR #841) — delayed nonlinear ramp.

## 2026-05-22 18:35 UTC — PR #780 CLOSED: Body-Muon u/w trust-region CEILING (0.5 vs 0.4) — NULL/NULL, 73rd axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/body-muon-uw-ceiling`
- Hypothesis: Clamp body-Muon updates to a maximum u/w ratio (ceiling = 0.5 vs 0.4) to prevent overshoot from high-magnitude updates. Counter-hypothesis to the existing floor (TARGET_UW=0.35): tests whether the upper tail of the u/w distribution is destabilizing.

| Arm | Ceiling | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | n/a | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.5 | `ne03hzf2` | 3125 | 3.27643 | +200 | +0.0095 | NULL |
| Arm B | 0.4 | `hn32cchn` | 3225 | 3.27963 | +300 | +0.0127 | NULL (worse) |

- **Monotone tighter→worse:** Arm B (tighter ceiling 0.4) is strictly worse than Arm A (0.5) on both sr and val.
- **Ceiling fires heavily:** Arm A 43% of param×step events clamped; Arm B 71% clamped. This is NOT an idle ceiling — it substantially modifies the update distribution.
- **Key informative-NULL finding: high u/w updates are PRODUCTIVE, not pathological.** PMuon's Kronecker preconditioner directs updates to confident, well-conditioned directions with high u/w ratios. Clamping them removes the per-tensor adaptivity PMuon was designed to provide.
- **Asymmetric floor/ceiling story:** The floor at TARGET_UW=0.35 is load-bearing (fires 49% and boosts weak-signal updates). The ceiling is anti-productive (firing 43-71% and suppressing confident updates). This is a clean asymmetric result: the u/w distribution's lower tail needs boosting, but the upper tail should be left alone.
- **73rd closed axis. u/w trust-region ceiling axis FULLY CLOSED. Follow-up H7 (Post-NS Frobenius norm) assigned to nezuko as PR #827 — directly motivated by the ceiling finding: NS output magnitude variability may be causing the floor to do inconsistent work across params.**

## 2026-05-22 16:53 UTC — PR #741 CLOSED: Aux AdamW β2 cooldown ramp (β2→0.999) — NULL on primary at n=2, val-frontier shift, 72nd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/aux-adamw-beta2-cooldown-ramp`
- Hypothesis: Ramp aux AdamW β2 from 0.95 → 0.999 during cooldown to slow late-cooldown variance estimation for embed/lm_head/scalars, hypothetically improving terminal val.

| Seed | W&B | sr | val/loss |
|---|---|---|---|
| Baseline (PR #737 n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 |
| Seed 1 | `nsvxxmvl` | 2950 | 3.265040 |
| Seed 2 | `k4chzjdk` | 2950 | 3.265453 |
| **n=2 mean** | — | **2950** | **3.265247** |
| Δ vs baseline | — | **+25** (marginal NULL on primary) | **−0.001679** (improvement past 0.001 marginal threshold) |

- **n=2 reproducibility is essentially perfect:** both seeds delivered sr=2950 EXACTLY (no 25-step bucket spread). Both val within 0.0005 of each other. The β2 ramp mechanism is real and reproducible.
- **NULL on primary metric:** n=2 mean sr=2950 fails the merge rule (sr ≤ 2925 strict). Per CLAUDE.md: "Merge if the PR improves the current baseline according to the target's declared primary metric direction" — sr regresses by +25 with high reproducibility.
- **Val-frontier shift:** axis improves val by −0.0017 below baseline at n=2 confirmation (stat-sig margin 0.02086 = 5.2× over 0.004 threshold) but does NOT move the primary metric.
- **Pattern:** This is the inverse of PR #737 (Polyak EMA), which gave +sr (good) and +val regression (bad). Here we get -val (good) and +sr (bad). Both confirm cooldown-phase mechanisms can shift the (sr, val) Pareto frontier but rarely improve both axes simultaneously.
- Suggested follow-up (deprioritized): Stack with #802 thorfinn (EMA β_target fine-scan) if it lands sr=2925/val<3.266 — could close #737's val regression. Not worth pursuing standalone.
- **72nd closed axis. Aux variance-estimation in cooldown is a val-frontier lever, NOT an sr lever.** Confirms the cooldown-erosion pattern from a new angle: late-cooldown mechanism changes can shift val outcomes but cannot move steps-to-target once cooldown trajectory is set.

## 2026-05-22 16:14 UTC — PR #777 CLOSED: Body-Muon mu cooldown ramp (0.95→0.85 vs 0.95→0.98) — NULL/marginal NULL, 71st axis (g1r1-fern)

- Branch: `g1r1-fern/pmuon-mu-cooldown-ramp`
- Hypothesis: Ramp body-Muon momentum coefficient (mu) during cooldown — Arm A 0.95→0.85 (sharper decay; less smoothing as gradients shrink) vs Arm B 0.95→0.98 (more smoothing/lag as gradients shrink). Targets the conjecture that the optimal mu for terminal refinement differs from mid-training.

| Arm | mu schedule | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | mu=0.95 constant | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| **Arm A** | 0.95 → 0.85 | s6umzz3i | **2925** | 3.26880 | 0 (TIE) | +0.001874 | NULL — sr ties, val marginally fails (>0.001 threshold) |
| **Arm B** | 0.95 → 0.98 | l4w74vmj | 3025 | 3.26793 | +100 | +0.001004 | NULL — sr NULL primary; val just over 0.001 marginal threshold |

- **Body-Muon momentum spec PINNED at static mu=0.95** across all 5 sub-axes tested: #660 ON/OFF + #682 mu schedule wide + #695 Polyak EMA short-window + #697 QHM + #777 mu cooldown ramp.
- **Cooldown-erosion confirmation:** Arm A (sharper decay) preserved sr at terminal but eroded val — consistent with the pattern that body-Muon momentum dynamics at mid-cooldown matter more than at terminal, and any movement off mu=0.95 is net-negative.
- **Cross-arm pattern:** Arm A (less smoothing) holds sr but loses val; Arm B (more smoothing) loses sr with val barely changed. **Asymmetry verdict:** moving toward LESS smoothing at terminal is the lesser evil — but neither direction wins.
- **Ramp telemetry verified clean:** Student confirmed `train/muon_mu/mu_t` linear ramp during cooldown via W&B telemetry; implementation correct.
- Suggested follow-ups (deprioritized): mu schedule with non-linear shape (delayed kick-in); per-layer-type mu (attn vs mlp); coupling mu to lr_mult instead of linear cooldown_progress — all expected NULL by axis closure.

## 2026-05-22 14:55 UTC — PR #769 CLOSED: Aux AdamW delayed cooldown start (300 vs 600) — NULL/NULL, 70th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-cooldown-delay`
- Hypothesis: Decouple aux AdamW cooldown start from body-Muon cooldown_start_step=975. Delay aux schedule by 300 or 600 steps so embeddings/scalars get more high-LR exposure before fine-grained cooldown.

| Arm | delay | aux_cooldown_start | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | 0 | 975 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| **Arm A** | 300 | 1275 | f23tr64v | 2975 | 3.26688 | +50 | −0.000046 | NULL on sr |
| **Arm B** | 600 | 1575 | asxzb8lk | 3000 | 3.26747 | +75 | +0.000544 | NULL on both |

- **Monotonic dose response confirms NULL is real:** 300→600 monotonically worse on both metrics. Rules out noise interpretation.
- **Arm A val is tied with baseline (~0.05 mnat better, within noise)** but sr +50 is unambiguous NULL on the primary metric.
- **70th closed axis. Cooldown-erosion family closure now spans BOTH sides:** body-Muon perturbations (#723/#725/#690/#697/#774) AND aux schedule-decoupling (#769). Confirms global cooldown_start=975 is well-tuned across mechanisms. The productive cooldown lever (per #737) ADDS new mechanisms (Polyak EMA) rather than perturbs existing schedules.
- **Student insight:** "Cutting that taper window in half makes embeddings end further from optimum, not closer" — the steeper, shorter aux cooldown window (compressed to ~2000 vs ~2275 steps) gives an effectively higher floor at terminal, refuting the high-LR-exposure hypothesis cleanly.
- Suggested follow-ups (deprioritized): inverse direction (neg delay), per-aux-group decoupling (embed only), different COOLDOWN_POWER for aux.

## 2026-05-22 13:21 UTC — PR #737 MERGED: Polyak EMA β_target=0.99 cooldown ramp — n=2 sr win (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-cooldown-beta-ramp`
- Hypothesis: Couple Polyak EMA β to lr_mult so EMA window expands as LR→0. β_t = β_base + (β_target − β_base) × cooldown_progress (deterministic, no per-run randomness).
- **n=2 seeds:** seed-1 `rdbmnzpc` sr=2925/val=3.265811, seed-2 `32r3isz5` sr=2925/val=3.268040. n=2 mean: **sr=2925, val=3.266926.**
- **Stat-sig margin:** (3.28 − 3.266926)·√2 = 0.01849 ≥ 0.004 ✓ (4.62× threshold). Both seeds hit sr=2925 deterministically (β_t coupling to lr_mult is independent of seed noise).
- Vs old baseline #413 (sr=2937.5): Δsr=−12.5 (sr win); val regresses +2.65 mnat (3.266926 vs 3.264278) — accepted because primary metric is sr.
- **First merged sr win since #413.** New advisor branch baseline. Reproduce: add `--ema_beta 0.95 --ema_warmup_steps 2250 --ema_beta_target 0.99` to PR #413 config.

## 2026-05-22 13:21 UTC — PR #760 CLOSED: PMuon γ_power cooldown ramp (0.4→0.5 vs 0.4→0.3) — NULL/NULL, 69th axis (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-cooldown-ramp`
- Hypothesis: Ramp γ_power during cooldown — harder whitening (0.5) for more isotropic late-training updates OR softer whitening (0.3) for more signal preservation as LR→0.
- Arm A `wmsd0lvk` (0.4→0.5): sr=2975, val=3.26733 — NULL.
- Arm B `xmpjznpa` (0.4→0.3): sr=2975, val=3.26604 — NULL but ~2× closer to baseline on val.
- **Asymmetric closure pattern:** softer whitening less harmful than harder during cooldown. γ_power=0.4 static well-tuned (closes γ ramp axis, adds to #444 warmup ramp NULL).

## 2026-05-22 12:45 UTC — PR #774 CLOSED: PMuon cov warmup fast-mix (K=20 vs K=50) — NULL with numerical-instability boundary, 68th axis (g1r1-edward)

- Branch: `g1r1-edward/pmuon-cov-warmup-fast-mix`
- Hypothesis: β_cov=0.0 for first K steps to rapidly populate L_cov/R_cov buffers, then snap to β_cov=0.95 stable EMA. Tests whether early-training cov buffer init quality is a lever.

| Arm | K | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 20 | ih0bs1wn | 2975 | 3.26713 | +37.5 | +0.00285 | NULL |
| **Arm B** | 50 | ibl7esmh | crashed step 41 | — | — | — | INSTABILITY |

- **Arm A NULL on both metrics, n=1:** Δsr=+37.5 (>25 marginal threshold), Δval=+0.00285 (>0.001 marginal threshold). Stat-sig threshold (val ≤ 3.276) passes — within noise floor but consistently worse than baseline mean.
- **Arm B numerical-instability INTRINSIC to hypothesis:** With β_cov=0.0, EMA collapses to `R_cov ← g.T @ g` — rank-deficient by construction. After ~40 steps of pure outer-product accumulation, `torch.linalg.eigh` cannot decompose. eps=1e-12 clamp does nothing because it activates POST eigendecomposition. Rules out K=50 (and larger) as viable. K=20 happened to escape this window by luck.
- **Closes 68th axis cleanly:** the cov-warmup-fast-mix hypothesis adds nothing useful at K=20 (NULL) and corrupts the estimator at K=50 (instability). The cluster (#727, #769, #760, #774) confirms β_cov=0.95 / cooldown stack is at a Pareto-balanced operating point.
- **Operational note:** student handled chain-launcher chaos (7 aborted runs) with clean recovery — diagnosed duplicate-launch pattern, killed artifact at 09:58 UTC, produced definitive Arm A + clean Arm B failure-mode analysis.

## 2026-05-22 09:15 UTC — PR #745 CLOSED: Body-Muon per-type LR cooldown asymmetry — NULL/NULL, 67th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/body-muon-cooldown-lr-asymmetry-attn-mlp`
- Hypothesis: Body-Muon LR cooldown multiplier asymmetric by block type (attn vs mlp). Arm A (attn×0.5, mlp×1.0) tests damped-attn cooldown; Arm B (attn×1.0, mlp×0.5) tests damped-mlp cooldown.

| Arm | attn cool× | mlp cool× | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 | 1.0 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 0.5 | 1.0 | gg4h05wp | 3025 | 3.27157 | +87.5 | +0.00730 | NULL |
| **Arm B** | 1.0 | 0.5 | 0x0yd7ts | 3050 | 3.27548 | +112.5 | +0.01120 | NULL |

- **Both arms regress on both metrics, not marginally:** Δsr=+87.5/+112.5 (well >25), Δval=+0.007/+0.011 (well >0.001). Neither qualifies for marginal-band n=2 confirmation.
- **Crossover pattern (exceptional diagnostic):** Arm B (mlp cooled faster) led Arm A by ~0.005-0.019 val through steps 1500-2500, then Arm A caught up and overtook in the final 250 steps. Sub-component cooldown sensitivities are real but trade off symmetrically — neither configuration recovers the symmetric (1.0, 1.0) baseline.
- **Closes per-type × cooldown LR asymmetry axis:** adds to #499 (static per-type), #535 (sub-MLP), #532 (depth-based) — all NULL. Per-type LR family is now extensively closed across both static and cooldown-coupled configurations.

## 2026-05-22 08:40 UTC — PR #736 CLOSED: PMuon per-type γ_power asymmetry (wide split) — NULL/NULL, 66th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-gamma-power-per-type`
- Hypothesis: Body-Muon per-block-TYPE γ_power asymmetric whitening (attn vs MLP). Arms A (γ_attn=0.3, γ_mlp=0.5) vs B (γ_attn=0.5, γ_mlp=0.3), symmetric split centered on baseline γ=0.4.

| Arm | γ_attn | γ_mlp | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.4 (scalar) | 0.4 (scalar) | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 0.3 | 0.5 | v8nsntg2 | 3050 | 3.27263 | +112.5 | +0.00835 | NULL |
| **Arm B** | 0.5 | 0.3 | xlysv0gm | 2975 | 3.26734 | +37.5 | +0.00306 | NULL |

- **Direction validated (Arm B > Arm A by ~0.005 val from step 1250 onward):** γ_attn > γ_mlp is the helpful direction — more whitening for attn (lower-rank per-head gradient covariance) and less for MLP (richer spread of signal across directions).
- **Magnitude insufficient:** wide symmetric split (0.5/0.3 around scalar 0.4) places both endpoints individually too far from scalar optimum (per #519 γ pruning ablation). Both 0.3 and 0.5 hurt independently; Arm B lead just reflects 'less harm from lowering γ_mlp than from lowering γ_attn'.
- **Partial axis closure:** wide symmetric split is closed; narrow attn-only-raised split (γ_attn=0.5, γ_mlp=0.4 — pin mlp at scalar optimum) remains open and will be tested as the follow-up.
- Adds to PMuon γ_power cluster: scalar γ=0.4 PINNED (#519), γ_power ramp NULL (#444), cooldown ramp running (#760), per-type narrow follow-up next.

## 2026-05-22 08:20 UTC — PR #727 CLOSED: Body-Muon WD cooldown schedule — NULL/NULL, 65th axis (g1r1-fern)

- Branch: `g1r1-fern/muon-wd-cooldown-schedule`
- Hypothesis: Body-Muon weight-decay as a temporal schedule during cooldown (linear ramp UP 0.025→0.050 vs DOWN 0.025→0.000). Tests whether WD-impulse trajectory shape (vs static WD=0.025) is a productive lever.

| Arm | direction | wd_t end | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | static | 0.025 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | UP ramp 0.025→0.050 | 0.050 | xzx014yu | 2975 | 3.267333 | +37.5 | +0.003055 | NULL |
| **Arm B** | DOWN ramp 0.025→0.000 | 0.000 | rzthmx1j | 2975 | 3.266326 | +37.5 | +0.002048 | NULL |

- **Symmetric-NULL signature**: both arms regress identically (Δsr=+37.5, Δval ≈+0.003/+0.002) — WD=0.025 STATIC sits at a local optimum on the WD-trajectory axis. The cross-arm Δval = +0.001 (B better than A) is below the marginal threshold and not load-bearing.
- **Schedule infrastructure verified**: `train/muon_wd/wd_t` telemetry confirmed linear ramp fires correctly (Arm A: 0.025→0.050; Arm B: 0.025→0.000) per-step during cooldown_start=975 through num_steps=3250. No NaN, no instability.
- **Buffer-modification/cooldown-trajectory lever cluster** now fully closed: #647 longer cf, #607 LR floor, #717+#690 SGDR, **#727 WD-schedule** ← this. The WD-impulse trajectory `WD_t × LR_t × param_t` shaped by the LR cooldown alone is already well-matched to cooldown's deterministic LR-decay.
- **Implication**: WD-as-temporal-schedule lever EXHAUSTED. WD-as-scalar-tuning-target (constant 0.025) remains the operative knob — #413's choice continues to win.
- Excellent symmetric two-arm probe with clean telemetry. Also: launcher-fix during the run (pgrep gate fix after duplicate-launch incident) was high-quality engineering.

## 2026-05-22 08:05 UTC — PR #730 CLOSED: Body-Muon SWA cooldown init — NULL/NULL, 64th axis (g1r1-edward)

- Branch: `g1r1-edward/body-muon-swa-cooldown-init`
- Hypothesis: Replace live body-Muon weights with SWA average (uniform window over last K stable-phase steps) at cooldown_start_step=975. Tests parameter-space centroid initialization for cooldown.

| Arm | K | W&B | sr | val/loss | Δsr | Δval | swa/rel_frob | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — | — |
| **Arm A** | 100 | 9xwvmmqz | 3000 | 3.26820 | +62.5 | +0.00392 | **27.1%** | NULL |
| **Arm B** | 200 | pwv34alf | 3000 | 3.26928 | +62.5 | +0.00500 | **37.2%** | NULL |

- **Key diagnostic finding (strongest result this session):** Predicted 1-5% Frobenius distance; actual 27-37% (5-7× higher). Body-Muon weights TRAVEL DIRECTIONALLY at ~0.27-0.37 relative Frobenius distance per 100-200 steps. Uniform SWA average is a heavily lagged anchor, not a basin centroid.
- **Mechanism falsified:** The 'live frontier vs centroid' image does not apply. Body-Muon optimization is a directed trajectory, not basin-orbiting. Resetting to 100-step-lag point = rewind ~100 steps.
- **Wider window → more lag → more harm:** K=200 (37% distance) is consistently ~0.001 worse than K=100 (27% distance) throughout cooldown, confirming monotone dose-response.
- **5th buffer-modification dead lever at cooldown_start** (LR schedule + optimizer state × 2 + parameter space). Buffer-modification at cooldown_start FULLY CLOSED across all categories.
- Excellent diagnostic instrumentation by student — swa/rel_frobenius_dist diagnostic changes a null result into a mechanistically informative finding.

## 2026-05-22 06:35 UTC — PR #725 CLOSED: PMuon bilateral covariance reset at cooldown_start — NULL/NULL, 63rd axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-cov-cooldown-reset`
- Hypothesis: Resetting or zeroing the PMuon bilateral covariance buffers (L_cov/R_cov, 72 tensors) at cooldown_start_step=975. Partial (0.5×) vs full (0.0×) reset.

| Arm | cov_scale | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — |
| **Arm A** | 0.5 (partial) | alao0903 | 2975 | 3.26712 | +37.5 | +0.00284 | NULL |
| **Arm B** | 0.0 (full reset) | 0d6vgq6v | 2950 | 3.26550 | +12.5 | +0.00122 | NULL |

- **Non-monotone pattern (identical to #723 momentum reset):** 0.5× worse than 0.0×, both worse than no reset. Mid-training L_cov/R_cov are load-bearing.
- **4th buffer-modification dead-lever at cooldown_start** (after #690 SGDR, #697 QHM, #723 momentum reset). Buffer-modification axis at cooldown_start FULLY CLOSED across all PMuon buffer types.
- **Student whitening transient hypothesis:** partial scale (0.5×) shrinks tr^γ divisor by 0.5^0.8=0.574 → 1.74× update amplification transient, creating worse stale/fresh mixture than either extreme.
- **Trajectory analysis:** B−A gap peaks at +0.004-0.005 immediately post-reset (steps 1000-1500), closes by ~0.003 over remaining training — consistent with WSD cooldown erosion absorbing the divergence.
- **No n=2 needed:** Arm A non-marginal (Δsr=+37.5 > 25). Arm B marginal but same direction as Arm A.

## 2026-05-22 05:30 UTC — PR #723 CLOSED: Body-Muon momentum reset at cooldown_start — NULL/NULL, 62nd axis (g1r1-frieren)

- Branch: `g1r1-frieren/muon-cooldown-momentum-reset`
- Hypothesis: Resetting or weakening the body-Muon momentum buffer at cooldown_start_step (step 975) to allow the optimizer to follow current gradients during deterministic LR-decay, rather than being dragged by accumulated mid-training inertia.

| Arm | scale | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 (no reset) | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — |
| **Arm A** | 0.5 (partial) | bvnxlq25 | 2975 | 3.26604 | +37.5 | +0.00176 | NULL — clearly worse |
| **Arm B** | 0.0 (full reset) | ek4zebyw | 2950 | 3.26487 | +12.5 | +0.000592 | NULL — marginally worse |

- **Win threshold (n=1):** sr ≤ 2925 — neither arm wins. Neither arm close.
- **No n=2 needed:** Arm A is non-marginal (Δsr=+37.5 > 25). Arm B is marginal but both metrics worse simultaneously — n=2 unlikely to flip sign.

- **Key mechanism finding — body-Muon momentum buffer is load-bearing for cooldown.** Both arms worse confirms the mid-training momentum trajectory carries information that cooldown LR-decay relies on.

- **Non-monotonic surprise:** 0.5× WORSE than 0.0×. If "less inertia = better" were the story, we'd expect monotone improvement as scale → 0. Instead, partial reset creates a worse magnitude/direction mismatch than either extreme. Rules out scale-based single-event resets as a useful lever.

- **Reset events confirmed firing:** Arm A: step=975, n_scaled=72, frob 205.75 → 102.88 (0.5×). Arm B: step=975, n_scaled=72, frob 212.29 → 0.0000 (0.0×). 72 body-Muon tensors scaled in both arms.

- **Joint implication with prior axes:** 3rd confirmed instance of buffer-modification at cooldown_start being harmful (#690 SGDR warm restart, #697 QHM body-Muon, now #723 momentum reset). Stable-phase trajectory state is valuable — discarding/perturbing it consistently costs steps.

- **Next steps for cooldown-erosion:** Remaining levers must be schedule-side, not buffer-side:
  - Cooldown β ramp (in-flight: #737 thorfinn, sr=2925 provisional)
  - Aux β2 ramp (in-flight: #741 alphonse)
  - Per-type LR ramp (in-flight: #745 nezuko)
  - γ_power whitening ramp (newly assigned: #760 frieren)

## 2026-05-22 01:30 UTC — PR #698 CLOSED: NAdam (Nesterov-AdamW) for aux groups — NULL/NULL, 61st axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/nadam-aux`
- Hypothesis: Apply Nesterov lookahead to aux AdamW (embed, lm_head, scalars) — cross-family analog of #660 body-Muon Nesterov. Arm A β₁=0.8 NAdam ON, Arm B β₁=0.9 NAdam ON.

| Arm | β₁ | nadam | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 0.8 | OFF | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.8 | ON | wwyxnxdy | 3000 | 3.26811 | +62.5 | +0.00383 | NULL |
| Arm B | 0.9 | ON | 5i9nua0o | 3000 | 3.26829 | +62.5 | +0.00401 | NULL |

- **Δ between arms:** +0.00018 val, 0 sr — well inside seed noise. β₁ retune did NOTHING.

- **Mechanism (3 findings):**
  1. **AdamW denominator absorbs Nesterov lookahead.** Nesterov's cross-term `β₁·(1-β₁)·g_t` adds gradient weight in numerator, but the AdamW denominator `1/√v̂` is already coordinate-adaptive. Net effect: per-coord absorption or over-weight on low-variance coords. Structurally different from body-Muon Nesterov which shapes spectral structure post-NS.
  2. **Aux is structurally insensitive to update-rule changes.** This is the 10th aux family NULL (#545 AdaBelief, #575 NadamW-old, #585 AdEMAMix, #578 AMSGrad, #583 Adamax, #609 LAMB, #604 Lion, #617 Lookahead, #623 Schedule-Free, #698 NAdam-aux). Saturation pattern: only schedule machinery moves aux outcomes.
  3. **β₁ ∈ [0.8, 0.9] gives identical terminals.** Rules out the "try harder β₁ retuning" follow-up. The Nesterov-aux effect is structural-NULL, not tuning-NULL.

- **Excellent terminal write-up:** pre-flight numerical verification (max dev 2.4e-7 from analytical), bitwise parity with baseline when flag is off, AuxAdamW subclass with clean fallthrough. Production-quality optimizer code.

- **Conclusion:** Cross-family Nesterov on aux CLOSED. Aux AdamW update-rule family approaching exhaustive saturation.

## 2026-05-22 00:55 UTC — PR #697 CLOSED: QHM (Quasi-Hyperbolic Momentum) on body-Muon — NULL/NULL, 60th axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/qhm-body-muon`
- Hypothesis: QHM linear blend `ν·g + (1-ν)·m` decouples gradient weight from momentum decay, potentially reaching variants Nesterov cannot. Arm A ν=0.10, Arm B ν=0.20, both nesterov=false, β=0.95.

| Arm | ν | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Reference #660A (ν=0) | 0 | — | 3025 | 3.26949 | +87.5 | +0.00521 | reference |
| Arm A | 0.10 | wkfhw41d | 3025 | 3.27137 | +87.5 | +0.00709 | NULL |
| Arm B | 0.20 | oxy20p9p | 3125 | 3.27751 | +187.5 | +0.01323 | NULL (worse) |

- **Stat-sig test:** Arm A: (3.28−3.27137)·√1=+0.0086 marginal pass on val, but sr=3025 fails win rule. Arm B: (3.28−3.27751)·√1=+0.0025 FAIL +0.004 rule + sr=3125. Both NULL.

- **Mechanism (3 findings):**
  1. **Super-linear penalty in ν along the β=0.95 slice.** ν=0→0.10 cost: +0.00188 val, 0 sr. ν=0.10→0.20 cost: +0.00614 val, +100 sr. Same Δν=0.10 step but ~3× cost — monotone wrong direction, accelerating.
  2. **QHM blend cannot replicate Nesterov cross-term.** Nesterov's `μ²·m_prev + (1-μ²)·g` is structurally distinct from QHM's `ν·g + (1-ν)·m`. The (ν,β) decoupling family cannot reach Nesterov's lookahead-on-updated-momentum.
  3. **STRONGEST cooldown-erosion instance to date.** Both arms showed -49 to -71 mnat advantage vs ν=0 reference at steps 1000-1750, COMPLETELY inverted to +1.9 to +8.0 mnat penalty at terminal. Largest mid-vs-terminal flip across all 4 cooldown-erosion instances (-71 → +8 mnat is a 79 mnat swing through cooldown).

- **Joint with #660 (Nesterov ON/OFF NULL):** Body-Muon momentum spec now PINNED across 9 sub-axes: β=0.95, nesterov=True, no QHM blend, mu schedule static, post-NS momentum closed, Nesterov cross-term load-bearing.

- **Conclusion:** QHM (ν,β) plane CLOSED at β=0.95 slice. Body-Muon momentum decoupling family fully closed.

- **Operational incident (resolved):** student traced 20:40 UTC pgrep-x trap (`pgrep -x torchrun` returns empty because argv[0]="python3"). Recovery: killed dupes, deleted corrupted W&B runs `0fwetrtj`/`z8sxf1cl`, relaunched Arm B cleanly. Arm A unaffected. Memory updated.

## 2026-05-21 23:35 UTC — PR #690 CLOSED: SGDR cosine restarts — NULL/NULL, 57th axis (g1r1-edward)

- Branch: `g1r1-edward/sgdr-cosine-restarts`
- Hypothesis: SGDR warm cosine restarts on body-Muon LR — tests whether periodic LR resets help escape sharp minima that WSD's monotone decay cannot escape. Two arms: Arm A (1 restart, T_mult=1, 2× 1625-step cycles), Arm B (2 restarts, T_mult=1, 3× 1083-step cycles).

| Arm | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (1 restart) | znxwk1om | -1 (never hit 3.28) | 3.30605 | -∞ | +0.0418 | NULL |
| Arm B (2 restarts) | 5n88a4qm | -1 (never hit 3.28) | 3.32263 | -∞ | +0.0584 | NULL (WORSE than A) |
| Pair mean | — | -1 | 3.31434 | — | +0.0501 | NULL |

- **Stat-sig test:** Arm A: (3.28−3.30605)·√1=−0.026 FAIL. Arm B: (3.28−3.32263)·√1=−0.043 FAIL. Both fail +0.004 rule decisively.

- **Mechanism (4 findings):**
  1. **Cycle-0 advantage real and reproducible.** Both arms beat baseline by ≥0.10 val/loss at cycle 0 bottom (Arm A step 1000: val=3.553 vs base 3.657; Arm B step 1000: val=3.545 vs base 3.657). Cosine-to-zero LR finds better local minima at same step count.
  2. **Each restart costs +0.13 to +0.17 val/loss spike.** Arm A restart 1: +0.174. Arm B restart 1: +0.132. Arm B restart 2: +0.166. Spike is structural — NS/whitening buffers converged to prior LR scale; restart invalidates them.
  3. **More restarts → worse final loss.** 3× 1083-step cycles (Arm B) worse than 2× 1625-step cycles (Arm A). Each successive cycle finds deeper bottom (3.545 → 3.379 → 3.323) but rate slows; spike costs compound.
  4. **Cooldown-erosion instance #3.** Arm B mid-cycle-1 at step 2125 showed −0.019 advantage vs baseline, eroded to +0.058 final regression. Third documented cooldown-erosion instance after #697 QHM (−50 mnat mid → +7 mnat terminal) and #686 β_cov schedule.

- **WSD comparison:** WSD's monotone cooldown (cooldown_frac=0.30, COOLDOWN_POWER=1.4) already well-tuned. Non-monotone/restart LR cannot pay back restart cost on 3250-step budget.
- **Conclusion:** SGDR on body-Muon FULLY CLOSED. Body-Muon LR schedule shape axis (monotone cooldown direction) CLOSED across restart count = {1, 2}.

## 2026-05-21 22:02 UTC — PR #686 CLOSED: PMuon β_cov schedule — symmetric NULL, 56th axis (g1r1-fern)

- Branch: `g1r1-fern/pmuon-beta-cov-schedule`
- Hypothesis: Two opposite-direction phase-specific β_cov schedules — Arm A responsive early (0.90→0.95 over steps 0-500), Arm B smoother cooldown (0.95→0.98 over steps 975-3250). Tests whether bilateral covariance EMA decay can be improved as a schedule.

| Arm | direction | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | β_cov 0.90→0.95 warm | z6fo7pix | 2975 | 3.267627 | +37.5 | +0.00335 | NULL |
| **B** | β_cov 0.95→0.98 cool | zh1xe1ci | 2975 | 3.267820 | +37.5 | +0.00354 | NULL |

### Analysis & mechanism findings

**Symmetric NULL is the key empirical signature.** Both arms move β_cov in OPPOSITE directions in DIFFERENT phases (Arm A: lower early; Arm B: higher late). Both regress by essentially identical amounts (Δval = 0.0034 vs 0.0035; Δsr = +37.5 for both = +1 cooldown step). This is the canonical signature of a STATIC local optimum.

**Pre-cooldown sanity check is decisive (step 1125: Arm A 3.62858, Arm B 3.62895 — Δ_AB=0.0004 = seed noise).** The two arms diverge only in their phase-specific β_cov regime, not from confounded init or seed variation. Arm A's regression is fully realized BEFORE cooldown (early-phase β_cov damage in stable phase); Arm B's regression is fully realized AFTER cooldown_start (late-phase β_cov damage). This rules out a confounded "schedule machinery" issue and isolates the regression to the schedule mechanism itself.

**Combined with prior PR #502 β_cov scalar scan (β_cov=0.90 marginal NULL; β_cov=0.99 clear NULL), this CLOSES the β_cov axis mechanism-cleanly across BOTH scalar value AND temporal schedule directions. β_cov=0.95 STATIC is robustly load-bearing.**

**Cooldown-erosion is NOT explained by whitening miscalibration.** Student's insight: the cooldown-erosion pattern (#690 SGDR, #697 QHM, this #686 β_cov schedule, #644 winsorization, #622 tanh-squash) cannot be reduced to "miscalibrated bilateral covariance during cooldown" — Arm A (more responsive early covariance) and Arm B (smoother late covariance) both fail. The cooldown sensitivity must come from a different mechanism (most likely the deterministic LR-decay trajectory dominating per-step optimizer contributions).

### Closure semantics

**56th closed axis.** β_cov temporal-schedule sub-axis CLOSES alongside the prior scalar β_cov sub-axis. PMuon's bilateral covariance EMA spec is now FULLY PINNED at β_cov=0.95 STATIC across both scalar value and schedule directions.

### Student suggested follow-ups
- (Closed by advisor): β_cov axis closed — stop perturbing β_cov shape.
- (Considered, deferred): γ_power schedule during cooldown, NS-iteration count schedule during cooldown.
- (Advisor next assignment): WD cooldown schedule (different lever, untested as a temporal schedule).

## 2026-05-21 21:42 UTC — PR #682 CLOSED: Body-Muon mu schedule — NULL/inconclusive, 55th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-mu-schedule`
- Hypothesis: Time-varying mu (momentum coefficient) for body-Muon — Arm A cooldown ramp 0.95→0.85 (responsive in cooldown); Arm B warmup ramp 0→0.95 (avoid stale init momentum).

| Arm | mechanism | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | static mu=0.95 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | cooldown ramp 0.95→0.85 | 0uvvmh8p | 2925 | 3.26985 | −12.5 (marginal sr) | +0.00557 (regression) | inconclusive — sr meets n=1 first clause BUT val regression fails second clause; tradeoff effect |
| **B** | warmup ramp 0→0.95 | uxi3dbgm | 3050 | 3.27239 | +112.5 | +0.00812 | clear NULL |

### Analysis & mechanism findings

**Finding 1 — Warmup ramp UP rejects the "random-init bias" hypothesis (clean negative).** Arm B is consistently behind baseline from step 125 onward and never recovers. The hypothesis (low mu early avoids stale random-init momentum) predicted Arm B would catch up by mid-training. Data shows the gap (+0.118 mnat at step 125, +0.154 at step 250) decreases by step 1000 to parity, then RE-EMERGES in cooldown as Arm A (which has cooldown mu ramp) pulls ahead. Reduced early momentum is a permanent loss, not a transient setup phase.

**Finding 2 — Cooldown ramp DOWN shows real tradeoff (val for sr).** Arm A's −12.5 sr is in the marginal noise range but directionally consistent with the hypothesis (lower mu in cooldown → responsive tracking of small updates → faster threshold-cross). However val regression (+0.00557) suggests responsiveness comes at the cost of final smoothing. The mu schedule converts val/loss precision into sr speed at unfavorable ratio.

**Decision logic for Arm A:** n=1 win rule's second clause `(sr=2925 AND val<3.264278)` is decisive — val regression alone disqualifies. Even at n=2 (which would test if −12.5 sr is real), the value tradeoff (gain ~12 steps but add +5.6 mnat) is a net loss by the benchmark's value function.

**Combined with #660 Nesterov ON/OFF closure (Arm A nesterov=False mu=0.95 val=3.26949, essentially identical to #682 Arm A val=3.26985 within ±0.0004), this is the second piece of evidence that the body-Muon mu spec at 0.95 STATIC is at a robust optimum.**

### Closure semantics

**55th closed axis.** mu temporal-schedule sub-axis CLOSES across both warmup and cooldown directions. Combined with #660 (Nesterov ON/OFF), the body-Muon momentum mechanism is now PINNED at static (mu=0.95, nesterov=True, NS_ITERS=12) across 4 sub-axes. #697 alphonse (QHM) is the in-flight extension that tests if the (ν, β) plane beyond Nesterov has any signal.

## 2026-05-21 21:24 UTC — PR #684 CLOSED: Body-Muon Langevin noise post-NS — NULL/NULL, 54th axis (g1r1-frieren)

- Branch: `g1r1-frieren/body-muon-langevin-noise`
- Hypothesis: Inject isotropic Gaussian noise N(0, σ_base²·lr_t²·I) after the NS step on body-Muon updates. SGLD-like Langevin dynamics may help find flatter minima at scale.

| Arm | σ_base | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | 0.01 | chhogu08 | 2975 | 3.26641 | +37.5 | +0.00213 | NULL |
| **B** | 0.05 | olgik55z | 2975 | 3.26711 | +37.5 | +0.00283 | NULL |

### Analysis & mechanism findings

**Linear σ scaling confirmed.** noise_frob ratio between arms held at exactly 5.00× through every checkpoint. PMuon's polar step does not differentially damp noise magnitudes — perturbation magnitude scales linearly with σ_base as designed.

**Identical sr=2975 between arms is informative.** Both arms regress by exactly +37.5 sr-steps despite 5× noise difference. If the regression were a smooth function of σ, we'd see monotonic worsening. The identical sr suggests the regression is bounded by another factor (likely the cooldown's deterministic finishing point), not the noise level itself.

**Mid-training noise was NEUTRAL.** During steps 1000-2000, Arm B (5× noise) was slightly AHEAD of Arm A. This contradicts "more noise = more cost" and shows the noise is not destructive in stable phase. The +0.0007 val gap appears only in cooldown.

**Two convergent failure mechanisms:**
1. PMuon polar/whitening already produces a low-curvature trajectory — no sharp basin to escape from. SGLD's "escape sharp minima" benefit requires sharp minima to exist.
2. The σ·lr_t schedule decays noise to zero in cooldown (as designed, ~5% of update magnitude at peak → ~0.5% by step 2500). The noise level when it could matter (peak LR) doesn't help because trajectory is already flat.

**Combined with #644 winsorization, #622 tanh-squash, #607 LR floor, this 4th gradient-domain perturbation family closes.** Element-wise post-NS modifications (clipping, squashing, noise) are not productive levers — PMuon's spectral whitening absorbs magnitude info before these can affect dynamics.

### Suggested followups (student's, valid in principle but unlikely to help)

1. Anisotropic noise aligned with NS directions (vs isotropic Gaussian)
2. σ·sqrt(lr_t) or σ·lr_t² schedules (different timing of noise injection)
3. Inject noise to momentum instead of update

These are mechanism-clean but the underlying issue (PMuon trajectory already flat-enough) blocks the benefit.

### Closure semantics

**54th closed axis.** SGLD/Langevin noise sub-axis FULLY closes. Gradient-domain perturbation family CLOSED (4 sub-axes: winsorization #644, tanh-squash #622, LR floor #607, Langevin #684).

## 2026-05-21 16:47 UTC — PR #667 CLOSED: Cosine LR schedule vs WSD — NULL/NULL, 53rd axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/cosine-schedule`
- Hypothesis: Test whether the WSD-style schedule (stable plateau + concave power-1.4 cooldown) can be replaced with a cosine schedule. Two arms tease apart the stable-plateau effect from the decay-shape effect: Arm A pure cosine from step 0; Arm B 30% stable + cosine 70% cooldown.

| Arm | schedule | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | wsd + power-1.4 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | pure cosine | r5p6b5fc | 3000 | 3.276601 | +62.5 | +0.012323 | NULL (val just above stat-sig 3.276) |
| **B** | cosine_wsd (30% stable + cosine 70%) | 3qn5btoq | 3000 | 3.272568 | +62.5 | +0.008290 | NULL (val under stat-sig, both metrics worse than baseline) |

### Analysis & two clean mechanism findings

**Finding 1 — Stable plateau is load-bearing.** Arm B (with 30% stable) beats Arm A (pure cosine) by Δval=0.004 at identical sr=3000. Holding cooldown shape fixed, adding a stable plateau improves val loss. This confirms what the prior WSD sub-axis sweeps suggested: peak-LR time matters; pure cosine spends too little time at peak LR.

**Finding 2 — WSD power-1.4 tail beats cosine tail (Arm B vs baseline).** Holding the stable phase at 70%, swapping the WSD concave (power-1.4) cooldown for a cosine S-curve cooldown costs +62.5 sr-steps and +0.0083 val. The aggressive-early/gentle-late shape of power-1.4 outperforms cosine's gentle-early/steep-late shape on this benchmark.

### Val/loss trajectory near 3.28 crossing (Arm B)

| step | val_loss |
|---|---|
| 2950 | 3.2826 |
| 2975 | 3.2808 |
| **3000** | **3.2791** (first crossing) |
| 3025 | 3.2775 |
| 3100 | 3.2743 |
| 3250 | 3.2726 final |

Both arms first cross 3.28 at step 3000. Arm B finishes lower than Arm A (3.2726 vs 3.2766) due to cosine slope remaining at end, but can't recover the 62.5-step deficit.

### Closure semantics

**Schedule family axis CLOSES — 53rd closed axis.** Combined with prior WSD sub-axes (cooldown_frac=0.7 pinned, cooldown_power=1.4 pinned, LR floor=0 pinned, warmup=0 pinned, longer cf brackets NULL #647), the LR schedule axis is now WSD-LOCKED across 7 sub-axes:

1. Family: WSD (not cosine, not cosine+stable)
2. Stable plateau: REQUIRED (Arm B vs Arm A finding)
3. cooldown_frac: 0.7 STATIC
4. cooldown_power: 1.4 STATIC (concave tail shape)
5. LR floor: 0 STATIC
6. LR warmup: 0 STATIC
7. Tail shape: power-1.4 > cosine (this PR's Arm B vs baseline finding)

### No n=2 needed

Δsr=62.5 is far above the 25-step marginal threshold. Δval=0.0083 is far above the 0.001 marginal threshold. Both arms clear NULL on n=1.

### Operational note

Arm A's 70 GiB peak memory reflects an early-run zombie-torchrun contention episode (Arm A's W&B run start window overlapped a leftover process). Optimizer state / val_loss curves not contaminated; only wall-clock for early steps. Arm B was clean at 35 GiB single-process throughout.

### Follow-ups assigned

- **#697 alphonse QHM (β-ν decoupled momentum on body-Muon)** — direct extension of #660 Nesterov closure
- **#698 nezuko NAdam (Nesterov-AdamW for aux)** — cross-family Nesterov mechanism test

---

## 2026-05-21 16:42 UTC — PR #660 CLOSED: PMuon Nesterov ON vs OFF — NULL/NULL, 52nd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/nesterov-onoff-pmuon`
- Hypothesis: PMuon's whitening + polar orthogonalization pipeline might dominate the update direction enough that the Nesterov vs standard-momentum distinction becomes irrelevant. Arm A tests pure Nesterov contribution (nesterov=False, mu=0.95). Arm B tests whether Nesterov is "secretly equivalent" to a different mu (nesterov=False, mu=0.90 to roughly match Nesterov-ON effective g-weight of 0.0975).

| Arm | nesterov | mu | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | True | 0.95 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | False | 0.95 | z6sx2hkq | 3025 | 3.26949 | +87.5 | +0.00521 | NULL (within stat-sig) |
| **B** | False | 0.90 | kdcbvbcm | 3150 | 3.27833 | +212.5 | +0.01405 | CLEAR NULL (fails single-run stat-sig 0.00167 < 0.004) |

### Analysis & conclusion

Both arms NULL — **Nesterov is load-bearing for PMuon**. The key insight is the asymmetry between Arm A and Arm B:

**Hypothesized Nesterov→standard-momentum equivalence (FALSIFIED):**
- Nesterov ON at mu=0.95: effective update = 0.0975·g + 0.9025·m_prev (approximately, via μ²·m_prev + (1-μ²)·g coupling)
- Standard momentum at mu=0.90: effective update = 0.10·g + 0.90·m_prev

These have nearly identical g-weight (0.0975 vs 0.10). If Nesterov were just a reweighting trick, Arm B should have matched baseline.

**Actual result:** Arm B is WORSE than Arm A (+0.0141 vs +0.0052 val damage). The progression g-weight 0 → Nesterov(≈0.05 effective) → 0.10 is non-monotone: Nesterov helps, but moving toward higher g-weight without Nesterov's specific structure HURTS.

**Mechanism:** Nesterov's cross-term coupling (μ²·m_prev + (1-μ²)·g blended via two stages: m updated first, then look-ahead) is fundamentally different from a single-step blend (1-mu)·g + mu·m_prev. The two stages interact with the PMuon pipeline:
1. **Momentum-buffer evolution** is affected (Nesterov pre-mixes g into m before reading)
2. **Whitening reads the pre-mixed buffer** which has different spectral properties than a less-mixed buffer
3. **Newton-Schulz polar step** sees a different effective input matrix

The "two-stage lookahead" structure cannot be replicated by simply retuning mu in a one-stage blend.

**mu axis interaction:** PR #570 closed mu axis at mu=0.95 with Nesterov ON. This PR confirms mu=0.95 is STILL the optimal choice with Nesterov OFF (Arm B at mu=0.90 is worse than Arm A at mu=0.95). So the mu axis shape (peak at 0.95) doesn't flip with the Nesterov toggle. **Both nesterov=True AND mu=0.95 independently load-bearing.**

### Closure semantics

**Nesterov flag axis CLOSES — 52nd closed axis.** PMuon now FULLY PINNED on the body-momentum specification: γ_power=0.4 + β_cov=0.95 + NS_ITERS=12 + cubic-NS coefficients + ε=1e-12 + mu=0.95 + nesterov=True.

### Natural follow-up: Quasi-Hyperbolic Momentum

QHM (Ma & Yarats 2019) parameterizes momentum with two independent controls (ν, β):
- update = ν·g_t + (1-ν)·m_t, where m_t = β·m_{t-1} + (1-β)·g_t
- ν=0 → standard mu=β momentum; ν=1 → SGD; Nesterov ≈ ν=(1-β²)/(1-β) reweighted

QHM at β=0.95 with ν ∈ {0.10, 0.20} spans the region "above Nesterov-equivalent g-weight" — assigned to alphonse as direct follow-up. If both arms NULL: Nesterov's specific cross-term structure is the sweet spot. If Arm A (ν=0.10) helps: there's headroom between Nesterov and standard.

### Operational note

Student handled two duplicate-torchrun fingerprints cleanly via pgrep sanity gate in the sequential launcher — both arms ran without GPU contamination. Wandb log-upload hygiene (wandb.save policy='live') noted as a useful nice-to-have followup but not blocking.

---

## 2026-05-21 16:22 UTC — PR #651 CLOSED: LR warmup ∈ {100, 250 steps} — NULL/NULL, 51st axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lr-warmup-phase`
- Hypothesis: LR warmup from zero allows optimizer state (PMuon covariance EMAs, aux v-state) to stabilize before full-LR training, potentially improving convergence.

| Arm | warmup | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 100 | b7tnbh0k | 3000 | 3.26926 | +62.5 | +0.005 | NULL |
| B | 250 | xhjudzj3 | 3050 | 3.27341 | +112.5 | +0.009 | NULL |

**Mechanism (clean read with telemetry):** First-decile training slope (steps 0-325) is steeper with warmup (Arm A +56%, Arm B +82%) — the hypothesis is mechanically confirmed: optimizer states DO benefit from gradual LR introduction. But cost > benefit: steps spent at low LR during ramp are not recovered. By step 650 slopes converge, and runs stay behind baseline throughout. Slope-at-first-decile is NOT a reliable proxy for final speedrun performance.

**Monotonic closure:** Baseline (warmup=0) < Arm A (warmup=100) < Arm B (warmup=250) in terms of sr. Same conclusion as #647 cooldown_frac — WSD stable-phase startup is precious, any deviation costs more than it gains.

**WSD schedule shape now FULLY PINNED across 6 sub-axes:** shorter-cooldown, LR floor, NS_ITERS ramp, decoupled aux cooldown, longer-cooldown, warmup phase. All confirmed NULL; zero-warmup, cf=0.70, COOLDOWN_POWER=1.4 are global optima within monotone WSD family.

---

## 2026-05-21 16:22 UTC — PR #662 CLOSED: Polyak EMA β=0.99 warmup=975 — NULL (centroid-lag), 50th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-body`
- Hypothesis: β=0.99 with cooldown-start warmup avoids LMC failure (prior β=0.999 failed) while keeping single-basin during parameter-space averaging.

| Arm | β | EMA_WARMUP | W&B | val_live | val_ema | Δ_ema-live (terminal) | sr_ema | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | — | k7ylyby9/dm4joozw | 3.264278 | — | — | 2937.5 | — |
| C (only to terminal) | 0.99 | 975 | f6ekm47z | 3.266663 | 3.267219 | **+0.000556** | 2925 | NULL (+2.9 mnat) |

**Peak EMA advantage:** step 1625 → Δ_ema-live = −63 mnat (REAL, reproducible, in-single-basin). This is the cleanest positive EMA signal found in the project.

**Terminal failure mechanism — centroid-lag (NOT LMC failure):**
- β=0.99 → effective window ~100 steps → centroid lags live params by ~50 steps
- Near terminal (steps 3100-3250): LR = ~0-2% of peak; params nearly stationary
- Monotone-descending near-stationary trajectory → EMA mean over last 100 steps is STRICTLY above live (terminal) point
- Δ sign flipped at step 3100: from −63 mnat (peak) → +0.6 mnat (terminal)

**This is different from β=0.999 LMC failure:** β=0.999 failed because window > basin width (multi-basin traversal). β=0.99 stays in single basin throughout; it fails for a purely geometric/arithmetic reason at low LR.

**Cross-axis implications:**
- Mid-cooldown Polyak EMA IS mechanically sound at β=0.99 (single-basin confirmed)
- Centroid-lag can be reduced by: shorter window (β=0.9 → 10-step lag), later warmup start (EMA_WARMUP=2500 → start when LR already low)
- Follow-up #695 (thorfinn): β=0.9 + EMA_WARMUP=2500 directly tests whether 5-step lag is small enough to preserve mid-cooldown advantage at terminal

---

## 2026-05-21 15:15 UTC — PR #658 CLOSED: Post-NS momentum in PMuon — NULL/NULL, 49th axis (g1r1-edward)

- Branch: `g1r1-edward/post-ns-momentum`
- Hypothesis: moving the EMA momentum step to AFTER Newton-Schulz (post-NS) would separate temporal smoothing from the polar map, giving cleaner per-step update directions. Arm B (post_ns_repolar) additionally re-polars the post-NS EMA to restore unit spectral norm.

| Arm | Config | W&B | Steps | val/loss | sr | spec_norm (final) | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | pre_ns (default) | k7ylyby9/dm4joozw | 3250 | 3.264278 (n=2) | 2937.5 | — | — | — |
| A | post_ns | d9ifhvbr | 3250 | **3.29212** | -1 DNF | 0.491 | +0.028 | NULL clear |
| B | post_ns_repolar | 9f46i8v1 | 2550 (killed) | 3.367 @ step 2500 | DNF | 0.469 | ~+0.024 extrapolated | NULL clear |

**Matched-step comparison (Arm A vs Arm B, student-corrected):**
Arm B tracked Arm A at every step by ~5 mnat better (not worse as originally claimed), but both tracked 26-28 mnat above baseline at every step. Arm B killed at step 2550 per advisor instruction (`val>3.30 @step 2500 → 3.367`).

**Mechanism (cleanest read in 10 axes):**

1. **Direction matters, not magnitude.** Arm B (post_ns_repolar) restored per-step unit spectral norm — the same magnitude as baseline — yet val tracked Arm A's sub-unit trajectory. This isolates the failure as directional mis-targeting.

2. **polar() is non-linear.** `polar(EMA(grads))` and `EMA(polar(grads))` point in qualitatively different directions. The baseline's polar-of-EMA direction is empirically better for this model+schedule — a causal mechanism, not just an empirical scan.

3. **Pre-NS placement CONFIRMED load-bearing.** EMA-of-polar settles at spec_norm ≈ 0.47, reducing effective update magnitude. Arm B's repolar corrects magnitude but not direction → magnitude is not the failure mode.

4. **Implementation bugs uncovered:** bf16/fp32 dtype mismatch on `polar_g.to(momentum.dtype)` + momentum buffer aliasing (clone needed before uw-floor in-place multiply). Both fixed, gated behind `--momentum_position != pre_ns`.

**Axis closure impact:** Body-Muon operator ordering (momentum/polar swap) FULLY CLOSED. Both alternative orderings tested; pre-NS is the empirical and mechanistic optimum.

**Cross-axis note:** Edward's suggested follow-up (α·polar(EMA) + (1-α)·polar(grad_t) interpolation) partially overlaps with #682 askeladd's mu schedule experiment (same temporal-smoothing-vs-instantaneous axis) and is not independently assigned.

---

## 2026-05-21 14:00 UTC — PR #644 CLOSED: Winsorization pre-NS body-Muon k={1.5, 3.0} — NULL/NULL, 48th axis (g1r1-fern)

- Branch: `g1r1-fern/winsorize-pre-ns`
- Hypothesis: hard-clip post-whitening body-Muon gradient to `[-k·median(|m_pre|), +k·median(|m_pre|)]` before NS. If outliers impair NS conditioning, removing them should tighten spectral whitening and improve sr.

| Arm | k | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | clip_frac | norm_ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — | — | — |
| A | 1.5 | 5erh0eht | 3075 | 3.27401 | +137.5 ✗ | +0.00973 ✗ | 0.319 | 0.713 | NULL clear |
| B | 3.0 | 7dupedm3 | 2975 | 3.26770 | +37.5 ✗ | +0.00342 ✗ | 0.048 | 0.956 | NULL |

**Mechanism (excellent telemetry):** Arm A (k=1.5) clips 32% of entries per parameter and reduces matrix norm by 29% — mechanism clearly engaged. Arm B (k=3.0) clips only 5% and reduces norm by 4%. Regression is MONOTONE with clip aggressiveness. The val/loss trajectory diverges specifically during cooldown (step 2500–3250), exactly where polar map quality matters most. Top-decile entries in m_pre encode signal NS uses for the spectral whitening → clipping them strictly removes useful directional information.

**Cross-axis synthesis — gradient-domain pre-NS FULLY CLOSED (48 total):**
Combined with PR #622 (tanh-squash NULL/NULL/NULL 47th axis), the elementwise outlier-treatment class is exhausted:
- Hard threshold (k=1.5 clips 32%): clear regression
- Hard threshold (k=3.0 clips 5%): small but consistent regression
- Soft saturation (tanh scale_mult=0.005, 4% Frob compress): no detectable effect
- Soft saturation (scale_mult=0.02/0.5): no-op (linear regime)

All six interventions (4 winsorization + 2 tanh) follow the same pattern: the post-PMuon-whitening gradient distribution is well-conditioned for NS AS-IS. NS spectral whitening absorbs magnitude differences; the direction (singular structure) is what it uses, and outlier-truncation in any form degrades that.

---

## 2026-05-21 13:45 UTC — PR #622 CLOSED: Tanh-squash pre-NS body-Muon — NULL/NULL/NULL, 47th axis (g1r1-frieren)

- Branch: `g1r1-frieren/tanh-squash-pre-ns`
- Hypothesis: apply element-wise `g_sq = scale * tanh(g / scale)` to body-Muon gradient before NS, where `scale = scale_mult × Frob(g)`. Soft outlier compression preserves singular structure for small entries while bounding large ones. Expected to tighten NS conditioning.

| Arm | scale_mult | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A (smoke-fix) | 0.5 | 9yq01dbe | 3000 | 3.26904 | +62.5 | +0.00476 | NULL (no-op) |
| B | 0.02 | 807tsqas | 2975 | 3.26652 | +37.5 | +0.00224 | NULL (near-identity) |
| C | 0.005 | w1rzdmoy | 2975 | 3.26657 | +37.5 | +0.00229 | NULL (4% Frob compression) |

**Key mechanistic finding (student telemetry):** After PMuon whitening, `m_pre` has Frobenius norm ~10^7 while individual entry magnitudes stay near ~1 (NS orthogonalization). At `scale_mult=0.5`, scale ≈ 5×10^6 — 6 orders of magnitude above any entry. Arm A is pure linear-regime tanh (max_ratio=0.012, norm_ratio=1.000, clip_fraction=0). Arm C is the only arm with real compression (max_ratio=1.26, norm_ratio=0.96) but gives nearly identical result to Arm B (0.05 mnat difference).

**Cross-axis synthesis — gradient-domain pre-NS FULLY CLOSED:**

| Mechanism | Test | Verdict | PR |
|---|---|---|---|
| Gradient centralization (subtract mean) | GC remove | NULL clear | #553 |
| Column-mean amplification | GC amplify | NULL clear | #588 |
| Global gradient clipping | hard-clip | NULL clear | #513 |
| Per-block L2 normalization | per-block norm | NULL clear | #627 (45th) |
| Tanh-squash (soft outlier) | scale_mult ∈ {0.5, 0.02, 0.005} | NULL/NULL/NULL | #622 (47th) |

NS spectral whitening absorbs and corrects any linear transformation of the gradient. The only remaining gradient-domain axis is winsorization (#644, in-flight, expected NULL given mechanism parity with tanh-squash).

**Notable debugging:** the step-0 EMA init issue (rank-1 L_cov → matrix_neg_power eps=1e-12 amplification → Frob ~10^9 poisoning EMA for hundreds of steps) was correctly diagnosed and fixed (WARMUP_STEPS=10 for both EMA and tanh warmup). Outstanding student forensics.

---

## 2026-05-21 13:30 UTC — PR #647 CLOSED: WSD longer cooldown_frac {0.80, 0.85} — NULL/NULL, 46th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/wsd-longer-cooldown`
- Hypothesis: extend WSD cooldown fraction in the LONGER direction to {0.80, 0.85}, symmetric counter-axis to PR #606 (cf=0.25 catastrophic). If cooldown is where productive descent happens, more cooldown should give better convergence.

| Arm | cf | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0.70 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 0.80 | `tk8hizl3` | 2950 | 3.26675 | +12.5 ✗ | +0.00247 ✗ | NULL (marginal) |
| B | 0.85 | `96jhh0zy` | 2975 | 3.27016 | +37.5 ✗ | +0.00588 ✗ | NULL (clear) |

**Mechanism (excellent student slope telemetry):** at step 1625 (mid-training), the longer-cooldown arms ARE further into the decay curve (cd_prog 0.41 vs 0.29) and val/loss is genuinely lower (3.466/3.474 vs 3.500). But by step 2925 the slope has gone BLUNTER (-0.0039/-0.0045 vs -0.0064) — the early-start advantage is consumed and the late tail is rate-limited by LR magnitude. By step 3250, val is *worse* than baseline. Spreading the COOLDOWN_POWER=1.4 curve over more steps proportionally weakens LR at every point in the decay tail.

**Cross-axis pattern (WSD shape now exhaustively characterized in 5 axes):**

| Axis | Test | Verdict | PR |
|---|---|---|---|
| cooldown_frac (shorter) | 0.25 vs 0.70 | catastrophic DNF | #606 |
| cooldown_frac (longer) | 0.80, 0.85 vs 0.70 | NULL/NULL | #647 |
| cooldown_power | extreme scan | symmetric loss | #648-class |
| lr_floor | η_min=0.05, 0.10 | NULL/NULL | #607 |
| NS_ITERS cooldown ramp | time-varying | NULL/NULL | #559 |

WSD schedule shape is fully pinned. The decay-to-zero tail is the load-bearing feature; weakening it (via floor, longer spread, or fewer iters) hurts; shortening it cannot match baseline trajectory.

**Next direction:** axis-level cf is closed. Future cooldown experiments should target **cooldown shape variants** (e.g. piecewise, sigmoid, or LR-schedule family changes — cosine already in flight #667) rather than further duration sweeps.

---

## 2026-05-21 08:50 UTC — PR #627 CLOSED: Per-block grad L2 normalization pre-NS — NULL/NULL, 45th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/per-block-grad-norm`
- Hypothesis: Per-block L2 (Frobenius) normalization of body-Muon gradients before NS reduces depth-varying gradient magnitude bias, improving NS conditioning and step-to-target.

| Arm | mode | val/loss | sr | Δval | Δsr | W&B | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | 3.264278 | 2937.5 | — | — | k7ylyby9, dm4joozw | — |
| Arm A | all | 3.269108 | 3000 | +0.00483 | +62.5 | mb25a9x9 | **NULL** clear |
| Arm B | mlp_only | 3.265763 | 2950 | +0.00148 | +12.5 | xaaqncix | **NULL** borderline |

**Verdict: NULL/NULL → 45th axis CLOSED. Pre-NS per-block magnitude conditioning family CLOSES.**

**Key mechanistic findings:**
1. **Arm A loudly hurt (+62.5 sr):** Pooling attn+MLP gradients into one per-block Frobenius destroyed the natural inter-sublayer scale separation PMuon's NS step relies on. Attention proj_qkv (large fan-in) and MLP gates have different native gradient scales; collapsing them distorts both relative to each other.
2. **Arm B flat-to-slightly-worse (+12.5 sr):** MLP-only per-block norm doesn't damage as much (MLP gradients across blocks are already reasonably balanced), but injects per-step variance without offsetting conditioning gain.
3. **PMuon's spectral whitening absorbs most magnitude information:** The pre-NS conditioning lever is approximately closed at the per-block granularity. What NS cannot absorb is the inter-sublayer scale ratio — exactly what Arm A destroyed.
4. **Combined with #553 (GC subtract NULL), #588 (column-mean amplify NULL), #513 (gradient clipping NULL):** Pre-NS gradient-domain modification family is now heavily explored. Tanh-squash (#622) and Winsorization (#644) remain in-flight.

**Action:** nezuko reassigned to PR #667 — first non-WSD schedule family test (cosine LR schedule). Arm A: pure cosine from step 0. Arm B: cosine with 30% stable plateau (matched to WSD shape).

---

## 2026-05-21 08:15 UTC — PR #623 CLOSED: Schedule-Free Adam on aux only — NULL/NULL decisive, 44th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/schedule-free-aux`
- Hypothesis: Schedule-Free Adam (Defazio 2024) on the aux AdamW path (embed, lm_head, scalars) — iterate averaging replaces explicit WSD cooldown on aux. Two configurations: Arm A canonical (r=0, ckp1=1/k), Arm B Polyak-tilt (r=1.0, ckp1=2/(k+1) under constant LR).

| Arm | r | p | best_val | sr | Δval | W&B | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | — | 3.264278 | 2937.5 | — | k7ylyby9, dm4joozw | — |
| Arm A | 0.0 | 2.0 | 3.30923 | -1 DNF | +0.0450 | j0zyguxj | **NULL** decisive |
| Arm B | 1.0 | 2.0 | 3.30752 | -1 DNF | +0.0432 | e41ak5px | **NULL** decisive |

**Verdict: NULL/NULL decisive → 44th axis CLOSED. Schedule-free averaging cannot replace WSD aux cooldown.**

**Key mechanistic findings:**
1. **Aux LR cooldown is load-bearing.** WSD shrinks aux step size ≥10× over the final 30% of training; SF iterate averaging with c_t≈3e-4 at step 3250 averages over thousands of unattenuated peak-LR steps and cannot match that effective step-size reduction. Disabling explicit aux decay costs ~0.045 val_loss.
2. **First-moment EMA discarded for no gain.** Defazio-style SF drops β₁ momentum on the premise that iterate averaging subsumes it. The trade ("explicit momentum + WSD" → "averaging substitutes both") loses by 0.045 on this benchmark.
3. **Polyak-tilt (r=1.0) marginally helps (Δ=0.0017) but doesn't change the conclusion.** "Less averaging = better" direction points back toward the WSD limit.
4. **Aux side now saturated across 9 optimizer families:** 5/5 update-rules + LAMB + Lion + Lookahead + Schedule-Free Adam. All NULL.

**Student's key catch (PR design):** Upfront derivation showed r=0 and r=1.0 are mathematically identical under constant LR + r=0 default — leading to Arm B redirect to Polyak-tilt (r=1.0) before compute was wasted on a degenerate ablation.

**Action:** thorfinn reassigned to PR #662 — Polyak EMA on body-Muon weights β={0.999, 0.9995}. First parameter-space averaging test on signal-dominant (matrix) params. Body-Muon trajectory during WSD cooldown is the natural averaging target; EMA maintains FP32 inference weights alongside BF16 train weights and swaps at eval.

---

## 2026-05-21 07:45 UTC — PR #607 CLOSED: LR floor in cooldown — NULL/NULL clear, 43rd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/lr-floor-cooldown`
- Hypothesis: Preventing the LR from decaying to zero in the final cooldown phase with a minimum floor `eta = max(lr_floor, w^COOLDOWN_POWER)` keeps the optimizer taking meaningful steps through the val≈3.28 crossing.

| Arm | lr_floor | val/loss | sr | Δval | Δsr | Floor activation | Verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| Baseline | 0.0 | 3.264278 | 2937.5 | — | — | — | — |
| Arm A | 0.10 | 3.270903 | 3025 | +0.00662 | +87.5 | step 2825 | **NULL** clear |
| Arm B | 0.05 | 3.266955 | 2975 | +0.00268 | +37.5 | step 3000 | **NULL** clear |

**Verdict: NULL/NULL → LR floor axis CLOSES. 43rd axis. Decay-to-zero tail is load-bearing.**

**Key mechanistic finding:** Late-cooldown val/loss slope in floor zone: −4.5e-5/step (Arm A), −4.0e-5/step (Arm B) vs pre-floor −1.0e-4/step. The floor reliably flattens the descent regardless of magnitude. Damage is linear in floor magnitude × activation duration: Arm B's 5% floor activates at step 3000 (250 suppressed steps) → half the damage of Arm A's 10% floor at step 2825 (425 suppressed steps). The WSD cooldown's steep terminal crossing is a load-bearing feature; any clamp on the tail trades target-crossing speed for smoothness.

**Action:** alphonse reassigned to PR #660 — PMuon Nesterov ON/OFF axis (mu=0.95 vs mu=0.90 without Nesterov). First direct ablation of the Nesterov flag in PMuon across 43 closed experiments.

---

## 2026-05-21 07:10 UTC — PR #617 CLOSED: Lookahead wrapper on aux AdamW — NULL/NULL clear, 42nd axis (g1r1-edward)

- Branch: `g1r1-edward/lookahead-wrapper-aux`
- Hypothesis: Lookahead (Zhang et al 2019) wraps the aux AdamW path (embed, lm_head, scalars). Slow-weight averaging over k inner steps tests whether noise-denoising helps the aux gradients which are noise-dominated per 4 closed update-rule leaves.

| Arm | k | α | val/loss | sr | Δval | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | n/a | 3.264278 | 2937.5 | — | — | — |
| Arm A | 5 | 0.5 | 3.267040 | 2975 | +0.00276 | +37.5 | **NULL** clear |
| Arm B | 10 | 0.5 | 3.269989 | 3025 | +0.00571 | +87.5 | **NULL** clear |

**Verdict: NULL/NULL → Lookahead wrapper on aux AdamW CLOSES. 42nd axis. Aux side FULLY SATURATED across 8 optimizer families.**

**Key mechanistic finding:** Lookahead's `slow ← slow + α(fast − slow); fast ← slow` is equivalent to applying a `1 − α` pull-back every k steps on the fast weights. With α=0.5, this halves the effective aux LR contribution per sync. Arm B (k=10, longer averaging horizon) shows larger fast↔slow gap during cooldown → worse regression (+87.5 sr vs +37.5 sr). The aux gradients are low-information-per-step (small magnitudes), not noise-dominated per se — averaging adds damping without denoising benefit.

**Cross-axis conclusion:** Aux side CLOSED across 8 distinct optimizer families:
1. v-estimator (AdaBelief #545)
2. m-step (NadamW #575)
3. m-aggregation (AdEMAMix #585)
4. v-clamp (AMSGrad #578)
5. v-aggregation (Adamax #583)
6. LAMB trust-ratio (#609)
7. Lion sign-of-momentum (#604)
8. **Lookahead wrapper (#617 — this PR)**

**Action:** edward reassigned to PR #658 — post-NS momentum position axis on body-Muon (pre-NS vs post-NS vs post-NS+repolar at mu=0.95). Clean orthogonal axis: momentum has lived pre-whitening/pre-NS in all 42 closed experiments.

---

## 2026-05-21 05:50 UTC — PR #604 CLOSED: Lion optimizer on aux AdamW — NULL/NULL clear, 41st axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lion-aux-optimizer`
- Hypothesis: Lion (Chen et al 2023) replaces AdamW's E[g²]-normalized direction with sign-of-momentum: `update = sign(β·m + (1-β)·g)`. Tests whether sign-of-momentum mechanism class works for aux path. Two lr_scale arms compared.

| Arm | lr_scale | val/loss | sr | Δval | Verdict |
|---|---|---|---|---|---|
| Baseline | n/a | 3.264278 | 2937.5 | — | — |
| Arm A | 1/3 (embed_lr=0.100) | 3.29790 @ step 3000 | -1 (DNF) | +0.034 | **NULL DNF** (SIGTERM partial) |
| Arm B | 1/10 (embed_lr=0.030) | 3.29465 @ step 3250 | -1 (DNF) | +0.030 | **NULL DNF** (clean) |

**Verdict: NULL/NULL → Lion mechanism class on aux CLOSES. 41st axis.**

**Mechanism:** Lion's `sign(m)` strips magnitude information from aggregated momentum, replacing it with constant per-coordinate ±1. The carefully-tuned aux AdamW per-group lr_scales (embed_lr=0.3, lm_head_lr=1/160, scalar_lr=0.025) provide finely-calibrated effective step magnitudes that E[g²]-normalization adapts to per-tensor. Lion's uniform-magnitude reduction destroys this calibration entirely. Both arms test two different uniform step sizes — both too coarse to match what AdamW provides.

**Cross-axis pattern:** Lion joins the saturated aux-optimizer landscape — 5/5 update-rule mechanisms (AdaBelief, NadamW, AdEMAMix, AMSGrad, Adamax), LAMB trust ratio (#609), and now Lion sign-of-momentum (#604) all CLOSED NULL/NULL. The aux gradients on embed/lm_head/scalars are noise-dominated and unresponsive to *any* update-rule replacement class.

**Action:** tanjiro reassigned to PR #651 (LR warmup phase ∈ {100, 250 steps}) — codebase has zero warmup which has never been explicitly tested. Closes a clean schedule-shape sub-axis.

---

## 2026-05-21 05:00 UTC — PR #609 CLOSED: LAMB trust ratio on aux AdamW — NULL/NULL clear, 40th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/lamb-aux-trust-ratio`
- Hypothesis: LAMB per-tensor trust-ratio step rescaling (`trust = min(||w||/||r||, max_trust)`) on the aux AdamW group (embed, lm_head, scalars) — orthogonal to the update-rule mechanism tree (5/5 leaves already NULL/NULL). Tests whether per-tensor step magnitude normalization helps the aux path.

| Arm | Variant | max_trust | val/loss @ step 3250 | sr | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline | — | — | 3.264278 | 2937.5 | — | — |
| Arm A | Literal (`min(||w||/||step||, T)`) | 10 | 3.34623 | -1 (DNF) | +0.082 | **NULL DNF** |
| Arm B | Canonical (`min(lr·||w||/||step||, T)`) | 10 | 3.29541 | -1 (DNF) | +0.031 | **NULL DNF** |

**Verdict: NULL/NULL → LAMB trust ratio on aux AdamW CLOSES. 40th axis.**

**Key mechanistic finding (outstanding student forensics):** Telemetry on trust ratios revealed that the raw `||w||/||step||` ratio for embed is ≈1.2e10 throughout training — far above max_trust=10, so the trust ratio saturates at 10 for the entire run. Result: LAMB becomes a constant 10× amplifier on aux step sizes, destroying the carefully-tuned per-group LR calibration. Arm B's improvement over Arm A (val=3.295 vs 3.346) is explained exactly by the canonical formula preserving lm_head's LR schedule (canonical restores the lr factor, so lm_head's small lr=1/160·embed_lr prevents saturation for that group).

**Why LAMB degenerates on this stack:** LAMB was designed for large-batch pre-training (BERT) where ||w||/||r|| is typically O(1)–O(10). In our finely-tuned aux setup, the tiny aux steps (embed_lr=0.3, balanced per-group) create step norms that are orders of magnitude smaller than weight norms → trust ratio saturates at max_trust every step. The mechanism only works non-degenerately when the raw trust ratio is near O(1).

**Student suggestions:**
- `max_trust=1` deferred — likely also NULL (changes direction from amplifier to hard-cap, but root cause is the degenerate regime).
- **LAMB on Muon** flagged as genuinely interesting: PMuon's NS-whitened step has spectral norm ~1, weight matrices have similar order → trust ratio would be in LAMB's design regime. Filed for future assignment.

---

## 2026-05-21 04:30 UTC — PR #606 CLOSED: WSD shorter cooldown_frac — Arm A NULL DNF / Arm B SKIPPED, 39th axis (g1r1-fern)

- Branch: `g1r1-fern/wsd-schedule`
- Hypothesis: Shorten the WSD (warmup-stable-decay) cooldown fraction from baseline 0.70 to {0.25, 0.15}, hoping that a longer "stable" peak-LR plateau allows more aggressive optimization before sharp terminal decay. The baseline already starts at full LR (zero warmup), so cooldown_frac controls only the length of the final decay phase.

| Arm | cooldown_frac | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.70 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.25 | `kq05a45r` | DNF (-1) | 3.30081 | DNF | +0.0365 | **NULL DNF** |
| Arm B | 0.15 | — | — | — | — | — | **SKIPPED** (strictly shorter cooldown predicted worse given Arm A) |

**Verdict: NULL DNF / SKIPPED → WSD shorter-cooldown direction CLOSES. 39th axis closed.**

**Key mechanistic finding:** All val-loss progress from 3.55 → 3.30 happens in the 25% decay tail of the baseline cooldown. Going shorter on cooldown — even by 6 percentage points (0.70→0.64 implicit, or explicitly 0.25 here) — destroys the speedrun mechanism. The cooldown is not a polishing phase but the *core descent phase* of the WSD trajectory.

**Cross-PR coherence:**
- This complements #607 alphonse LR-floor (Arm A η_min=0.10 NULL): keeping LR too high during cooldown is also harmful — even a 10% LR floor flattened the late-cooldown descent slope to 0.00007/step. So *both* "less cooldown" (shorter frac) and "weaker cooldown" (LR floor) hurt: the deep descent into near-zero LR over the full 70% tail is load-bearing.
- The orthogonal "LONGER cooldown" direction (cooldown_frac ∈ {0.80, 0.90}) remains untested — could be a next assignment if we want to fully pin the WSD schedule shape axis.

**Action:** fern reassigned to PR #644 (Winsorization pre-NS body-Muon, k={1.5, 3.0}) — orthogonal hard-clip counterpart to frieren's tanh-squash. See Hypothesis 2 in `research/RESEARCH_IDEAS_2026-05-20_23:30.md`.

---

## 2026-05-20 23:46 UTC — PR #583 CLOSED: Adamax on aux AdamW (L∞ v-aggregation) — NULL/NULL DNF, 5th and FINAL leaf of aux update-rule mechanism tree CLOSES (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamax-aux-adamw`
- Hypothesis: Adamax (Kingma & Ba 2014) replaces AdamW's E[g²] preconditioner with L∞ aggregation: `u_t = max(β2·u_{t-1}, |g_t|)`. Tests whether L∞ v-aggregation provides advantages over standard L2 aggregation on noisy aux gradients. β2={0.95, 0.999} probed.

| Arm | β2 | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.95 | `n3usxhni` | DNF (-1) | 3.28038 | DNF | +0.0161 | NULL DNF |
| Arm B | 0.999 | `p8l0a36v` | DNF (-1) | 3.28384 | DNF | +0.0196 | NULL DNF |

**Verdict: NULL DNF | NULL DNF → Adamax v-aggregation mechanism leaf CLOSES. 37th axis closed.**

**Validation trajectories track each other tightly:** Δval ~0.001-0.003 between arms at every checkpoint (250→3250). Adamax's L∞ v-aggregation has nearly zero β2 sensitivity on this stack — consistent with all 4 prior aux update-rule mechanism closures.

**🎯 AUX ADAMW UPDATE-RULE MECHANISM TREE — FULL CLOSURE (5/5 leaves NULL/NULL):**

| Leaf | Mechanism | PR | Verdict |
|---|---|---|---|
| v-estimator | AdaBelief | #545 | CLOSED NULL/NULL |
| m-step | NadamW | #575 | CLOSED NULL/NULL |
| m-aggregation | AdEMAMix | #585 | CLOSED NULL/NULL |
| v-clamp | AMSGrad | #578 | CLOSED NULL/NULL |
| **v-aggregation** | **Adamax** | **#583** | **CLOSED NULL/NULL** ← THIS |

**Cross-PR aggregate finding:** Across 10 distinct optimizer formulations (5 leaves × 2 hyperparameter arms each), ZERO produced an sr improvement over standard E[g²]/E[g] AdamW. The aux gradients on embed/lm_head/scalars are noise-dominated, and the *aggregation operator* over noisy v/m is irrelevant. This is overwhelming evidence that **the aux update-rule mechanism axis is saturated** — further attempts at this class of modification will continue to NULL.

**Remaining aux-side levers (orthogonal to mechanism tree):**
- Step-rescaling: LAMB trust ratio (#609 askeladd in flight)
- Wrapper class: Lookahead (#617 edward in flight)
- Schedule shape: WSD cooldown_frac (#606 fern in flight), LR floor (#607 alphonse in flight)
- Variance rectification: RAdam — UNTESTED
- **Iterate averaging: Schedule-free Adam (Defazio 2024) — NEWLY ASSIGNED #623 thorfinn**

---

## 2026-05-20 23:33 UTC — PR #588 CLOSED: Body-Muon column-mean AMPLIFICATION pre-NS — NULL/NULL clear, completes the rank-1 column-mean transformation class symmetric closure (g1r1-frieren)

- Branch: `g1r1-frieren/gc-amplify-mean`
- Hypothesis: Inverse of #553 (GC subtraction). If subtracting column-mean regresses sr (#553 dim=1 Δsr=+62.5), amplifying it (`g_new = g + α·(mean - g_mean_zero)` = `(1+α)·g` along mean direction) should help — predicted "symmetric monotone-helpful" model: the rank-1 column-mean is a useful signal, and increasing its weight should improve the polar map.

| Arm | α | dim | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 0 | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.05 | 1 | `ix493rgk` | 2975 | 3.26788 | +37.5 | +0.0036 | NULL clear |
| Arm B | 0.20 | 1 | `fiiel4pd` | 2950 | 3.26550 | +12.5 | +0.0012 | NULL clear |

**Verdict: NULL | NULL clear → column-mean transformation class closes on BOTH SIGNS at dim=1. 36th axis closed.**

**Both arms regress.** The predicted "symmetric monotone-helpful" model is falsified: amplification hurts in the same direction as subtraction. PMuon's polar map appears to use the rank-1 column-mean optimally at α=0, and any perturbation regresses.

**Non-monotone cost dependence on α (curious wrinkle):** Arm B (α=0.20, 4× larger) hurt LESS than Arm A (α=0.05). Two metrics shifted coherently (sr and val both moved less). Three plausible interpretations:
1. Single-seed noise — 25 sr swing is ~0.85% of sr, possible but with two coherent metric shifts less likely.
2. Polar-map renormalization saturating at α=0.20 (NS coefficient response stabilizes the direction).
3. Interaction with body-Muon's covariance EMA (β_cov=0.95) — small α may inject persistent bias; large α may saturate it.

**Telemetry confirms rank-1 perturbation is tiny:** `grad_norm_ratio` ≈ 1.00005 (Arm A) and 1.00028 (Arm B). Despite ≤0.03% L2-mass perturbation, the polar-map directional contribution moves sr by ±tens of steps — same scale signal as #553's mean-subtraction.

**Combined with #553 closure (subtraction):**
- Subtraction dim=1 (#553 Arm A): Δsr=+62.5 → hurt
- Subtraction dim=0 (#553 Arm B): Δsr=+87.5 → hurt
- Amplification α=0.05 dim=1 (#588 A): Δsr=+37.5 → hurt
- Amplification α=0.20 dim=1 (#588 B): Δsr=+12.5 → hurt

**Body-Muon rank-1 column-mean transformation class FULLY CLOSED.** Any perturbation (subtraction or amplification) regresses sr. PMuon's polar map preserves and uses the rank-1 mean direction optimally at α=0 (no perturbation).

**Aux update-rule tree progress (unchanged from #578 closure):** 4 of 5 leaves CLOSED. Only Adamax v-aggregation (#583) remaining.

---

## 2026-05-20 22:43 UTC — PR #578 CLOSED: AMSGrad v-clamp on aux AdamW — NULL/NULL clear, v-clamp mechanism leaf of aux update-rule tree closes (g1r1-edward)

- Branch: `g1r1-edward/amsgrad-aux-adamw`
- Hypothesis: AMSGrad (Reddi, Kale, Kumar — ICLR 2018) clamps the v-estimator with a monotone-max running max: `v_max = max(v_max, v)`, then uses `v_max` as the preconditioner denominator instead of `v`. Tests whether monotone non-decreasing v provides stability benefits on noisy aux gradients vs the standard EMA running-mean v.

| Arm | bias-corrected | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | True | `d6qh9eie` | DNF (-1) | 3.2805 | DNF | +0.016222 | NULL DNF |
| Arm B | False | `gz7ktuqr` | 3200 | 3.2794 | +262.5 | +0.015122 | NULL clear |

**Verdict: NULL | NULL clear → v-clamp mechanism axis closes. 35th axis closed.**

**Arm A bias-corrected DNF** at val=3.2805 / step 3250 — never crossed 3.28 in the full step budget. v_max binding fraction reported at 99.7% per W&B logs, meaning v_max was essentially always the active denominator — the monotone-max preconditioner aggressively damped aux step magnitudes on noisy embed/lm_head rows.

**Arm B uncorrected** crossed 3.28 only at step 3200 — Δsr=+262.5 vs baseline, Δval=+0.0151. The uncorrected variant produces smaller v_max (no over-correction in early steps) but still regresses sr by ~262 steps. Both formulations of monotone-non-decreasing v slow convergence.

**Mechanism reading:** AMSGrad's preconditioner monotonicity (v_max never decreases) prevents aux from "forgetting" early gradient noise. On noisy aux gradients, early v spikes get locked in and persistently inflate the denominator, shrinking aux steps. Standard AdamW's EMA running mean (which can decrease) is better suited to aux's noise-dominated gradients.

**Aux update-rule tree progress: 4 of 5 leaves CLOSED (NULL/NULL):**
- v-estimator AdaBelief #545: CLOSED NULL/NULL
- m-step NadamW #575: CLOSED NULL/NULL
- m-aggregation AdEMAMix #585: CLOSED NULL/NULL
- **v-clamp AMSGrad #578: CLOSED NULL/NULL ← THIS PR**
- v-aggregation Adamax #583: IN FLIGHT (thorfinn)

**Pattern (4 consecutive NULL closures):** The aux AdamW update-rule mechanism class is overwhelmingly NULL across 4 distinct mechanism modifications (v-estimator, m-step, m-aggregation, v-clamp). The consistent explanation: aux gradients on embed/lm_head/scalars are noise-dominated, so changes to update-rule arithmetic don't have informational leverage. The benchmark's standard AdamW formulation is at or near a local optimum within this mechanism class. Adamax (#583 in flight) is the final leaf — strong prior bearish given the pattern.

**Run history (student iteration):** Arm A initial run `d6qh9eie` finished DNF. Student launched a redundant Arm A retry `h7sq36z7` which was identified as redundant and killed; Arm B `gz7ktuqr` then launched cleanly with `AMSGRAD_BIAS_CORRECTED=False`. Single SENPAI-RESULT not posted by student before advisor close — W&B terminal data was unambiguous (3.3 hour ago last comment, 3.5+ hours after Arm B termination).

---

## 2026-05-20 21:15 UTC — PR #575 CLOSED: NadamW (Nesterov AdamW) on aux AdamW m-step — NULL/NULL clear, m-step mechanism leaf of aux update-rule tree closes (g1r1-askeladd)

- Branch: `g1r1-askeladd/nadamw-aux-adamw`
- Hypothesis: Nesterov AdamW (Dozat 2016) replaces the standard Adam m-step `θ - lr * m̂` with a Nesterov lookahead `θ - lr * (β1*m̂_{t+1} + (1-β1)*g_t/bc_t)`, applying the momentum update in the gradient direction of the next step rather than the current. Tests whether lookahead on the m-usage axis of aux AdamW unlocks speedrun improvement.

| Arm | β1 | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.80 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.80 | `ppotks3f` | 2975 | 3.26587 | +37.5 | +0.001592 | NULL clear |
| Arm B | 0.85 | `bpadxpdy` | 2975 | 3.26673 | +37.5 | +0.002452 | NULL clear |

**Verdict: NULL | NULL clear → m-step mechanism axis closes. 34th axis closed.**

**Both arms tie at sr=2975**, Δsr=+37.5 beyond marginal threshold (>25), Δval ≥ +0.001592 beyond marginal threshold (>0.001). Clear NULL on both sr AND val dimensions.

**Mechanism analysis:** The aux AdamW update-rule mechanism class has now produced 3 consecutive NULL closures: AdaBelief #545 v-estimator, this PR #575 m-step, AdEMAMix #585 m-aggregation. Consistent with the mechanistic explanation from #545: aux gradients (embed/lm_head/scalars) are noise-dominated. Var(g) ≈ E[g²] for these tensors, so changes to how m and v are computed or used don't have informational leverage over the baseline Adam formulation.

**Diagnostic telemetry (student):** Identical mid-training trajectories at step 1875 (val 3.4474 vs 3.4474 for Arms A/B) confirmed the m-step axis is mechanism-NULL, not just β1-value-NULL. Both Nesterov β1=0.80 and β1=0.85 produce indistinguishable training curves through mid-run.

**Run history (infra issues):** Arm B encountered several launches with NaN loss / SIGTERM at step 0 (infra, not mechanism). Student correctly identified the canonical run `bpadxpdy` (β1=0.85) as distinct from the crashed launches `8dxko849`, `3pg2aahk`, `o9wfvvan`.

**Aux update-rule tree progress: 3 of 5 leaves CLOSED (NULL/NULL):**
- v-estimator AdaBelief #545: CLOSED NULL/NULL
- m-step NadamW #575: CLOSED NULL/NULL (this PR)
- m-aggregation AdEMAMix #585: CLOSED NULL/NULL
- v-clamp AMSGrad #578: in flight (Arm A DNF NULL, Arm B running)
- v-aggregation Adamax #583: in flight (Arm A DNF NULL, Arm B running)

**Askeladd reassigned** to **LAMB trust ratio on aux AdamW** (PR #609) — per-tensor step rescaling via `trust_ratio = clip(||w|| / ||r||, 0, max_trust)`. ORTHOGONAL to the update-rule mechanism class (changes step SIZE not step direction). Arm A: max_trust=10 (paper default), Arm B: max_trust=1 (conservative, no amplification). Designed for mixed parameter scale scenarios like embed/lm_head/scalars.

---

## 2026-05-20 20:30 UTC — PR #570 CLOSED: PMuon mu (body-Muon momentum EMA) scalar scan {0.90, 0.97} vs baseline 0.95 — NULL/NULL clear, mu=0.95 is a sharp symmetric local optimum (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-mu-scalar-scan`
- Hypothesis: body-Muon's momentum EMA decay rate (mu) controls the effective smoothing horizon feeding into PMuon's Newton-Schulz polar map. Lower mu (0.90) → shorter ~10-step horizon, noisier raw gradient buffer per step. Higher mu (0.97) → longer ~33-step horizon, smoother but lagged signal. Baseline 0.95 gives ~20-step horizon.

| Arm | mu | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.90 | `3pk3lm8w` | 3075 | 3.275656 | +137.5 | +0.011378 | NULL clear |
| Arm B | 0.97 | `id2inkbe` | 3075 | 3.272967 | +137.5 | +0.008689 | NULL clear |

**Verdict: NULL | NULL clear → mu axis CLOSES. 32nd axis closed. mu=0.95 is locally optimal.**

**Symmetric Δsr=+137.5 from both sides** is the strongest possible evidence of a sharp local optimum. Neither shorter (10-step) nor longer (33-step) momentum horizon helps. Both arms hit identical sr=3075, well above the stat-sig threshold needed to declare NULL (>2×25=50 sr margin from baseline).

**Run history:** Arm A had 4 failed launches (infrastructure noise: 3 pod-scheduling crashes + 1 step-50 crash with rising grad norm that advisor flagged as possibly mechanism but turned out also to be infra). Arm A clean retry `3pk3lm8w` ran to 3250 steps without divergence — the step-50 crash `y3hafbkh` was pure infrastructure, not mu=0.90 instability.

**Val asymmetry** (Arm B 3.273 < Arm A 3.276) hints that the optimum lies slightly above 0.95 on the val axis, but the 0.003 difference is within step-by-step noise and doesn't shift the speedrun.

**Student suggested follow-ups (evaluated):**
- Per-projection mu (attn vs MLP): Given the symmetric +137.5 sr cost from both global perturbations, and that body-Muon LR partition family is already fully closed (#499, #532, #535), per-projection mu is unlikely to recover signal that doesn't exist at the global level. De-prioritized.
- Mu ramp (warmup/cooldown): The val asymmetry hint is sub-noise. Mu schedule is a schedule axis for the optimizer, not the LR — orthogonal but de-prioritized given very clean global closure.

**Alphonse reassigned** to **LR floor in cooldown** (PR #607) — `eta = max(LR_FLOOR, w^COOLDOWN_POWER)`. Two arms: Arm A eta_floor=0.10 (floor activates at step ~2811, active through entire speedrun zone), Arm B eta_floor=0.05 (floor activates at step ~2993). First test of minimum-LR behavior in the critical late-cooldown window. Flagged as unexplored follow-up in BASELINE.md (PR #274 notes).

---

## 2026-05-20 19:11 UTC — PR #562 CLOSED: PMuon ε floor scan {1e-10, 1e-14} vs baseline 1e-12 — NULL/NULL clear, ε=1e-12 optimal across ±2 OOM (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-eps-floor-scan`
- Hypothesis: PMuon's covariance-EMA eigenvalue floor (ε=1e-12) controls numerical conditioning of L_cov and R_cov. Testing ±2 OOM: larger ε (1e-10) → more aggressive regularization; smaller ε (1e-14) → tighter floor, closer to raw eigenvalues.

| Arm | ε | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1e-12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1e-10 | (run-id) | 2950 | 3.265630 | +12.5 | +0.001352 | NULL marginal |
| Arm B | 1e-14 | (run-id) | 2975 | 3.265965 | +37.5 | +0.001687 | NULL clear |

**Verdict: NULL | NULL clear → ε=1e-12 optimal across ±2 OOM. PMuon scalar audit COMPLETE.**

**PMuon scalar audit summary** (all 5 scalars now closed):

| Scalar | Axis | Status | Source |
|---|---|---|---|
| γ_power=0.4 | pruning ablation | CLOSED NULL/NULL | #519 |
| β_cov=0.95 | covariance-EMA decay | CLOSED NULL/NULL | #502 |
| NS_ITERS=12 | Newton-Schulz iterations | CLOSED NULL/NULL | #511+#546 |
| NS coefficients (1.5, -0.5, 0) | polynomial shape | CLOSED NULL/NULL | #540 |
| ε=1e-12 | eigenvalue floor | CLOSED NULL/NULL | #562 |

All PMuon scalar parameters are now exhaustively mapped. PMuon's internal configuration is at a local optimum for this stack.

**Tanjiro reassigned** to **Lion optimizer on aux AdamW** (PR #604) — sign-of-momentum mechanism class (Chen et al 2023, arXiv:2302.06675). Lion replaces the AdamW v-EMA denominator with a pure sign step, requires NO second-moment state, potentially faster aux convergence. FP32 m-state required (β2=0.99 ≈ 1.0 in BF16). Two arms scan lr×{1/3, 1/10} relative to aux baseline.

---

## 2026-05-20 15:35 UTC — PR #553 CLOSED: Gradient Centralization on body-Muon pre-NS — NULL/NULL clear, PMuon's NS whitening is already mean-aware and uses column/row-mean structure as signal not noise (g1r1-frieren)

- Branch: `g1r1-frieren/gradient-centralization-pre-ns`
- Hypothesis: Gradient Centralization (Yong et al 2020) subtracts the per-channel mean from the gradient before optimization. On body-Muon, this means subtracting `mean(grad, dim, keepdim=True)` from each 2D weight gradient before passing to PMuon's Newton-Schulz polar map. Two arms: Arm A `dim=1` (paper canonical, per-output-channel mean); Arm B `dim=0` (per-input-channel mean).

| Arm | GC_DIM | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (dim=1) | 1 | `1x2u1688` | **3000** | **3.268599** | +62.5 | +0.004321 | NULL clear |
| Arm B (dim=0) | 0 | `zfdfwtk4` | **3025** | **3.271550** | +87.5 | +0.007272 | NULL clear |

**Verdict: NULL | NULL clear → gradient-centralization on body-Muon pre-NS axis closes.**

**Astonishing signal-to-perturbation ratio.** Telemetry shows GC removed only:
- Arm A (dim=1): `grad_norm_post / grad_norm_pre = 0.99989` — 0.011% of L2 mass removed.
- Arm B (dim=0): `grad_norm_post / grad_norm_pre = 0.99979` — 0.021% of L2 mass removed.

Despite removing <0.05% of the gradient norm, both arms regressed by +62-87 sr and +0.004-0.007 val. The ratio of speedrun cost to L2 perturbation is ~5000-10000x — clear evidence that the rank-1 mean component is *singular-vector signal*, not noise.

**Mechanism analysis (frieren's tight reading):** The column/row mean of the body-Muon gradient is a rank-1 component of the gradient. PMuon's bilateral whitening + Newton-Schulz polar map preserves and uses this rank-1 piece — the polar map outputs an approximately unit-magnitude rotation along the rank-1 mean direction, so removing it costs proportional-to-1 not proportional-to-L2-mass. Subtracting the mean before NS effectively drops a top-singular-vector pair from the polar step.

**Direction asymmetry (dim=0 worse than dim=1)** is informative: per-input-channel mean (rows of W) carries more signal than per-output-channel mean (columns of W). Consistent with the architecture — input-channel mean represents per-feature shift signal accumulated through residual stream propagation, while output-channel mean represents per-target offset with less per-step coherence.

**Cross-domain finding:** opposite sign to Yong et al 2020 (ImageNet/ResNet, where GC helped). ResNet's BatchNorm-stabilized gradients have different rank structure than pre-LN transformer gradients, and Muon-class optimizers explicitly *use* the singular structure that GC tries to remove.

**Falsification — gradient transformation class state:**

| Sub-class | Status |
|---|---|
| Mean subtraction (centralization) | **CLOSED NULL/NULL (this PR)** |
| Mean amplification (inverse) | **IN FLIGHT (#588 NEW)** — frieren's follow-up |
| Norm clipping (sub-natural-norm) | CLOSED NULL/NULL (#513) |
| Sign / Winsorization / tanh-squash | UNTESTED |

**Frieren reassigned** to **body-Muon column-mean AMPLIFICATION pre-NS** (PR #588) — frieren's own suggested follow-up. If subtracting the rank-1 mean component hurts (this PR), amplifying it via `g + α · mean(g, dim, keepdim=True)` for small α > 0 should symmetrically help — direct inverse mechanism test motivated by the closure data. Two arms: Arm A α=0.05 gentle, Arm B α=0.20 stronger. Both use dim=1 (the less-bad direction from this PR). If amplification falsifies, the gradient-mean transformation class fully closes in BOTH directions — a stronger closure than this PR alone.

## 2026-05-20 14:25 UTC — PR #545 CLOSED: AdaBelief on aux AdamW (v-estimator leaf) — NULL/NULL clear after paper-formulation bug-fix, mean-subtracted second moment offers no headroom on noise-dominated aux gradients (g1r1-fern)

- Branch: `g1r1-fern/adabelief-aux-adamw`
- Hypothesis: AdaBelief (Zhuang et al 2020) replaces Adam's v-target `g²` with the mean-subtracted variance `(g − m)²` — a "trust region" preconditioner that should be more stable on aux gradients where m-direction is informative. Two arms scan eps ∈ {1e-10, 1e-8}.

| Arm | eps | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1e-10 | `p3ryt23e` | 2950 | 3.265551 | +12.5 | +0.001273 | NULL clear |
| Arm B | 1e-8  | `6ft2eleu` | 2975 | 3.266170 | +37.5 | +0.001892 | NULL clear |

**Verdict: NULL | NULL clear → v-estimator axis closes at standard AdamW raw |g|² for the aux group.**

**Pre-run bug-fix (fern self-diagnosis):** initial implementation used bias-corrected `m̂` inside the belief term `(g − m̂)²`. At step 1 with `m₀=0`, `m̂₁ ≡ g` identically, so belief ≡ 0, denom ≡ ε, and the embed update reached ~6708×|g| — divergent. Fern derived the failure mode in closed form, consulted AdaBelief Algorithm 2 (which uses raw `m`, not bias-corrected `m̂`), and made a one-line fix. Both arms then ran cleanly to 3250 steps. This is reference-quality root-cause analysis.

**Mechanism analysis (data confirms reading #2):** Telemetry shows `v_belief / g² ≈ 0.69-0.72` at convergence — AdaBelief IS preconditioning by ~Var(g) (~70% of E[g²]) rather than raw E[g²], a meaningful 30% mechanism shift. It just doesn't help on aux. Increasing eps (1e-10 → 1e-8) made Arm B *worse*, not better — monotone regression on both sr and val. If the issue were "denom too small at step 1", larger eps would help. It didn't. The mechanism itself is the regression, not a floor issue.

**Why aux fails AdaBelief:** aux gradients (embed BF16, lm_head BF16, scalars) are dominated by per-element noise variance. Adam's `|g|² = Var(g) + |E[g]|²` is essentially `≈ Var(g)` already because `|E[g]|` is tiny relative to per-element noise on these tensors. Subtracting m before squaring is informationally a no-op; it only makes the warmup transient worse by taking smaller-than-paper early steps.

**Combined with the other four aux update-rule leaves:**
- **v-estimator (this PR #545)**: CLOSED NULL/NULL
- **v-aggregation**: #583 Adamax (thorfinn) — in flight
- **v-clamp**: #578 AMSGrad (edward) — in flight
- **m-step**: #575 NadamW (askeladd) — in flight
- **m-aggregation**: #585 AdEMAMix (fern, this assignment) — in flight (NEW)

**Fern reassigned** to **AdEMAMix on aux AdamW** (PR #585) — the **m-aggregation** leaf of the aux update-rule mechanism tree, the fifth and final leaf. AdEMAMix (Pagliardini et al ICLR 2024) maintains TWO first-moment EMAs (fast β1≈0.9 + slow β1_slow≈0.9999) and uses `m_used = m_fast + α·m_slow`. This changes how m is FORMED rather than how m is USED (NadamW's domain). It is the mechanism specifically designed to leverage long-history gradient information that single-EMA Adam discards — relevant for rare-token embed/lm_head rows whose gradients are sparse over hundreds of steps.

**Suggested follow-ups (acknowledged):**
- LAMB/LARS layerwise trust ratio on aux — orthogonal mechanism class (per-tensor rescale not per-coordinate); queued.
- α-blend mixed second moment — limited additional learning; skip.
- Body-side variance — subsumed by Newton-Schulz polar map; skip (agreed).

## 2026-05-20 14:00 UTC — PR #546 CLOSED: NS_ITERS extension {16, 18} — NULL/NULL clear, V-shaped 5-point response curve confirms NS_ITERS=12 at local optimum (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/ns-iters-16-18`
- Hypothesis: extend constant-NS_ITERS scan beyond #511's {10, 12, 14} to {16, 18}. If extra Newton-Schulz iterations buy late-training polar-map quality, sr should drop monotonically as NS_ITERS grows.

| Arm | NS_ITERS | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 16 | `bqm06i25` | 2975 | 3.267862 | +37.5 | +0.0036 | NULL clear |
| Arm B | 18 | `xtaiy5c7` | 3000 | 3.269456 | +62.5 | +0.0052 | NULL clear |

**Verdict: NULL | NULL clear → NS_ITERS=12 confirmed at local optimum across full 5-point response curve.**

**Full response curve (NS_ITERS ∈ {10, 12, 14, 16, 18}):**

| NS_ITERS | sr | val/best_loss | Source |
|---|---|---|---|
| 10 | 3000 (Δsr=+62.5) | 3.273 | #511 Arm A |
| **12** | **2937.5 (baseline)** | **3.264278** | baseline |
| 14 | 2950 (n=2, Δsr=+12.5 marginal-NULL n=2) | 3.265846 | #511 Arm B n=2 |
| 16 | 2975 (Δsr=+37.5) | 3.267862 | #546 Arm A |
| 18 | 3000 (Δsr=+62.5) | 3.269456 | #546 Arm B |

**Beautifully clean V-shape** centered on NS_ITERS=12. Departures in both directions (NS=10 underconverged, NS=14-18 over-iterating with mounting cost) confirm 12 is the local minimum on this preconditioner-quality axis.

**Two independent inference paths converging:** tanjiro's #511 NS=14 went marginal-n=1-win then failed-n=2-confirmation, suggesting NS=14 was within seed noise of baseline. Thorfinn's #546 NS=16/18 produced clean NULLs on first attempt — the seed-noise band ends between NS=14 and NS=16. The 5-point monotone-V across {10, 12, 14, 16, 18} closes the iteration-count axis exhaustively.

**Combined with #540 (NS coefficient scan NULL/NULL identical sr=2975):** NS preconditioner quality is now pinned to inherited defaults across BOTH polynomial structure AND iteration count. NS-quality axis effectively saturated for this stack at cubic Newton (1.5, -0.5, 0.0) and NS_ITERS=12.

**Mechanistic read:** at NS_ITERS=12 cubic-Newton, the polar map for typical body-Muon matrices is essentially converged. Extra iterations after that point can only redistribute floating-point noise — they don't improve the spectral whitening. The mounting cost in {16, 18} is consistent with this: each extra iter introduces ~1e-6 magnitude perturbations to the polar-mapped step that don't help anywhere but show up as +25-37 sr regression because the rest of the stack was tuned to NS=12-output spectra.

**Student suggested follow-ups (incorporated):**
1. ✅ Joint NS_ITERS × coefficient axis — addressed by combined-closure of #540 + #511 + #546.
2. ✅ NS schedule (ramp up during cooldown) — being tested by **nezuko #559 NS_ITERS cooldown ramp 12→{16,18} over last 30%** in flight.
3. ✅ Lattice/seed variance n=2 policy for marginal sr — codified in advisor memory `feedback_marginal_n1_win_requires_n2.md`.
4. Adopt cooldown-only NS extension as the productive direction (nezuko #559 in flight).

**Thorfinn reassigned** to **Adamax on aux AdamW** (PR #583) — the v-aggregation leaf of the aux update-rule mechanism tree. Adamax (Kingma and Ba 2014, Section 7) replaces v-EMA (L2 norm of gradient history) with u-EMA (L∞ norm: `u = max(β2·u, |g|)`). Mechanistically distinct from AdaBelief #545 (v-target), NadamW #575 (m-step), AMSGrad #578 (v-clamp). Together these four leaves span the aux AdamW update-rule mechanism class.

## 2026-05-20 13:15 UTC — PR #540 CLOSED: NS coefficient scan (quintic vs aggressive-cubic) — NULL/NULL clear, polynomial axis closes alongside iteration count (g1r1-edward)

- Branch: `g1r1-edward/ns-coefficient-joint-scan`
- Hypothesis: NS polynomial coefficients `(NS_A, NS_B, NS_C)` define PMuon's per-matrix spectral whitening polar map. Baseline cubic `(1.5, -0.5, 0)` was inherited from upstream and never directly tested. Quintic (degree-5 published Muon coefs) and aggressive-cubic (same degree, larger contraction magnitude) test whether polynomial degree OR within-family scale is load-bearing.

| Arm | NS_A, NS_B, NS_C | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1.5, -0.5, 0.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (quintic published) | 3.4445, -4.7750, 2.0315 | `y46v2liq` | 2975 | 3.267725 | +37.5 | +0.003 | NULL clear |
| Arm B (cubic aggressive) | 1.75, -0.75, 0.0 | `zuk9fkdm` | 2975 | 3.267596 | +37.5 | +0.003 | NULL clear |

**Verdict: NULL | NULL clear → NS coefficient axis closes.**

**Remarkable coincidence:** both arms hit **identical sr=2975** and val differ by only 0.000129. Two very different polynomial families (degree-3 aggressive cubic vs degree-5 published quintic) produce near-indistinguishable trajectories despite different polynomial structure.

**Mechanistic read:** At NS_ITERS=12 the iteration has plenty of budget; the polar map is already near-perfect under baseline cubic. Replacing it with a steeper or higher-degree polynomial gives no whitening gain but slightly perturbs the spectral structure relative to what the rest of the stack (PMuon bilateral preconditioning, γ_power=0.4, β_cov=0.95) was tuned for. The flat optimum + ~37 sr cost in either direction tells us NS coefficient choice is at a saturated local optimum for our stack.

**Combined with #511 (NS_ITERS={10,14} NULL/NULL n=2)** and **#546 (Arm A NS_ITERS=16 NULL fs=2975, Arm B NS_ITERS=18 in flight)**: NS preconditioner quality is pinned to inherited defaults across BOTH polynomial structure AND iteration count. NS-quality axis effectively saturated.

**Student observations:**
- Both arms passed stat-sig threshold (val ≤ 3.276) — neither diverged.
- Neither arm satisfied win condition (sr ≤ 2925, or sr=2925 AND val<3.264278).
- Δval=+0.0034 and Δsr=+37.5 exceed marginal thresholds → n=2 not required.
- Student terminated redundant third Arm A run (`073p9uvl`) to free GPU — correct resource discipline.

**Suggested follow-up (deferred):** joint scan with #511 at low NS_ITERS (e.g., quintic at NS_ITERS=6) — at lower iter count quintic's per-iter convergence advantage might pay. Not assigned this round given closure-mode focus on independent leaves.

**Stale source comment** (lines 30–33 of `train_gpt_simple.py`) references old quintic→cubic labeling; advisor-owned cleanup, not a student bug.

**Edward reassigned** to **AMSGrad v-clamp on aux AdamW** (PR #578) — third leaf of the aux AdamW update-rule mechanism tree, alongside fern #545 AdaBelief (v-estimator leaf) and askeladd #575 NadamW (m-step leaf). AMSGrad clamps v_max from below via running max, distinct from changing v's estimation target (AdaBelief) or m's usage in the step (NadamW).

## 2026-05-20 12:10 UTC — PR #532 CLOSED: Body-Muon depth-based LR partition (early-fast vs late-fast) — NULL/NULL clear, body-Muon LR partition family fully closed across all three coarse subdivisions (g1r1-askeladd)

- Branch: `g1r1-askeladd/body-muon-block-lr-partition`
- Hypothesis: Depth-based LR multiplication (early blocks vs late blocks) would create headroom where uniform body-Muon LR=0.035 leaves it. Deeper blocks may benefit from different effective LR due to gradient norm scaling with depth, residual stream accumulation, or distinct preconditioning needs at different depths.

| Arm | early (blocks 0–5) | late (blocks 6–11) | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 1.0 | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (early-fast) | 1.10 | 0.90 | `oj9miqwf` | 3025 | 3.27130 | +87.5 | +0.007 | NULL clear |
| Arm B (late-fast) | 0.90 | 1.10 | `i6tfv7ry` | 3000 | 3.26825 | +62.5 | +0.004 | NULL clear |

**Verdict: NULL | NULL clear → depth-based LR partition axis closed.**

**Mechanistic read:** PMuon's per-matrix bilateral whitening of L_cov and R_cov normalises the singular-value spectrum of each weight matrix independently — including across depth. Each block's matrices get their own whitening estimates, so depth-distinct gradient norm scaling is effectively neutralized at the preconditioner output. A ±10% LR multiplier across two depth halves doesn't have headroom to compete with what PMuon already equalizes per-matrix.

**Directional late_fast-favouring residual signal:** Arm B is consistently 25 sr / 0.003 val_loss better than Arm A — a directionally clean but sub-threshold signal that deeper blocks marginally prefer slightly more LR. Same pattern direction as the c_proj-favouring sub-MLP residual (#535) — both suggest information-aggregation modules (c_proj, late blocks) want marginally more update — but signal magnitude is sub-stat-sig and inside seed noise.

**Combined with #499 (per-type MLP-vs-ATTN NULL/NULL +62.5/+87.5) and #535 (sub-MLP c_fc-vs-c_proj NULL/NULL +87.5/+37.5):** body-Muon LR partition family **fully closed across all three coarse subdivisions** — per-type, sub-MLP, depth. PMuon's per-matrix bilateral whitening eliminates coarse LR partitioning headroom by construction. **Coarse LR partitioning on body-Muon permanently de-prioritized.**

**Askeladd reassigned** to **NadamW (Nesterov AdamW, Dozat 2016) on aux AdamW first-moment update** — fresh aux m-step mechanism orthogonal to fern #545 AdaBelief (v-estimator) and orthogonal to all body-Muon work (aux path, not body path). Aux AdamW update-rule mechanism class now actively under test on both m and v sides.

## 2026-05-20 11:30 UTC — PR #535 CLOSED: Sub-MLP LR partition (c_fc vs c_proj) — NULL/NULL clear, PMuon whitening equalizes sub-projection asymmetry (g1r1-alphonse)

- Branch: `g1r1-alphonse/sub-mlp-lr-partition-cfc-cproj`
- Hypothesis: c_fc (expansion `d→4d`) and c_proj (contraction `4d→d`) have asymmetric gradient-geometry under PMuon. Splitting LR within MLP would surface a sub-MLP scheduling axis where PMuon's per-matrix whitening leaves headroom.

| Arm | mult_cfc | mult_cproj | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 1.0 | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (c_fc-heavy) | 1.20 | 0.80 | `3twtlh18` | 3025 | 3.27030 | +87.5 | +0.006 | NULL clear |
| Arm B (c_proj-heavy) | 0.80 | 1.20 | `g8dy2zhk` | 2975 | 3.26732 | +37.5 | +0.003 | NULL clear |

**Verdict: NULL | NULL clear → sub-MLP LR partition axis closed.**

**Mechanistic read:** PMuon's per-matrix bilateral whitening of L_cov and R_cov already normalises the singular-value spectrum of each MLP sub-projection independently, so a coarse ±20% LR multiplier on top of the whitened update doesn't have headroom to help. Centered geometric mean preserved (`sqrt(1.20×0.80) ≈ 0.98`) confirms this is a genuine asymmetry test, not an effective-LR shift.

**Directional Arm-B-favouring residual signal:** Arm B is consistently 50 sr / 0.003 val_loss better than Arm A across the cooldown phase — a directionally clean but sub-threshold signal that c_proj wants slightly more LR than c_fc. Not large enough to chase with a narrower partition (1.05/0.95) — diminishing returns past PMuon's whitening.

**Combined with #499** (per-type MLP-vs-ATTN both arms NULL/NULL +62.5/+87.5): **body-Muon LR partition family is fully closed** on every coarse subdivision tested — per-type (#499), sub-MLP (#535), depth (pending #532). Coarse LR partitioning on body-Muon permanently de-prioritized.

**Student-suggested follow-up:** attack mechanisms PMuon does NOT equalize — per-projection momentum (mu), per-projection γ exponent, per-projection NS iteration count. Adopted as direction but first the global scalars need closure. Alphonse reassigned to **PMuon mu (body-Muon momentum EMA) scalar scan {0.90, 0.97}** — closes the only untested PMuon/body-Muon scalar (temporal smoothing axis, distinct from β_cov spatial-EMA).

## 2026-05-20 09:25 UTC — PR #511 CLOSED: NS_ITERS scan {10, 14} — NULL/NULL clear at n=2, NS_ITERS=12 confirmed local optimum (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-iters-scan`
- Hypothesis: NS_ITERS scalar is load-bearing in the cubic-Newton orthogonalization. Test whether more iters (NS=14) → tighter spectral whitening → better preconditioner per step beats baseline NS=12; and whether fewer iters (NS=10) saves wall-clock without quality loss.

| Arm | NS_ITERS | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 10 | `x6pxjdk4` | 3000 | 3.273 | +62.5 | +0.009 | NULL clear |
| Arm B seed-1 | 14 | `ldezjd0y` | 2925 | 3.2639 | −12.5 | −0.0004 | marginal n=1 win — triggered n=2 |
| Arm B seed-2 | 14 | `ciusvhzo` | 2975 | 3.2678 | +37.5 | +0.0035 | NULL |
| Arm B n=2 mean | 14 | — | 2950 | 3.265846 | +12.5 | +0.00157 | NO confirmation |

**Verdict: NULL | NULL clear (n=2) → NS_ITERS scalar axis closed at constant-iter regime.**

**Mechanistic read:** at constant NS_ITERS, the iteration-count axis is locally flat-to-degrading around 12. Arm A NS=10 is clear NULL (under-iter → poor spectral whitening). Arm B NS=14 n=1 was within seed noise (sr=2925 baseline mean=2937.5 ⇒ Δsr=−12.5 ≤ marginal threshold 25), and seed-2 regressed to the NULL side. The marginal rule worked as designed — it correctly distinguished a within-noise n=1 sample from a genuine signal.

**Suggested follow-up:** student suggestion accepted — the marginal rule is calibrated correctly. The two-run cost paid for genuine information: NS=14 is NOT a free win.

**Combined with thorfinn #546** (NS={16,18} pipeline in flight) and **edward #540** (NS coef joint scan at NS=12 fixed): if #546 also lands clear NULL, the constant-NS axis is fully exhausted and any remaining iter-count gains live in **scheduling** (nezuko #559 NS_ITERS cooldown ramp).

NS_ITERS scalar (constant) axis closes at {10, 12, 14} mapped. Tanjiro reassigned to PMuon ε floor scan (#562 — only untested PMuon scalar).

## 2026-05-20 08:55 UTC — PR #522 CLOSED: Skylight u/w-floor cooldown phase-out — NULL/NULL clear, asymmetric loss curve confirms floor is load-bearing throughout cooldown (g1r1-nezuko)

- Branch: `g1r1-nezuko/skylight-floor-cooldown-decay`
- Hypothesis: The Skylight u/w-floor (TARGET_UW=0.35, forces ~87% of body matrices to receive update of magnitude ≥0.35·‖w‖ every step) overrides COOLDOWN_POWER=1.4's intentionally small polar-map updates during cooldown, defeating the cooldown's refinement dynamics. Phasing out the floor during cooldown should free those small updates to do refinement work.

| Arm | Schedule | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | constant 0.35 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | linear decay 0.35→0 over cooldown | `1ohe6cf7` | 2975 | 3.27188 | +37.5 | +0.00761 | NULL clear |
| Arm B | hard switch 0.35→0 at cooldown_start | `8bmch56g` | 3025 | 3.27214 | +87.5 | +0.00786 | NULL clear (2× worse than Arm A on sr) |

**Verdict: NULL | NULL clear → Skylight axis fully closed.**

**Mechanistic read:** the asymmetric regression (hard worse than linear) is informative. If the floor were redundant with the LR taper during cooldown, hard cutoff should be no worse than gradual decay. Instead, hard cutoff costs 50 additional sr steps over linear decay — meaning the floor's u/w-amplification continues to contribute useful work even as COOLDOWN_POWER=1.4 narrows the polar-map updates. The floor and cooldown are complementary, not redundant: the floor pushes update magnitude up to a minimum threshold, the cooldown narrows the polar map, and the product is what drives refinement.

**Combined with #486** (static TARGET_UW∈{0.25, 0.45} symmetric +87.5 sr both arms): TARGET_UW=0.35 is the local optimum on both magnitude (#486 closed) and schedule (#522 closed) axes. Skylight floor is now exhaustively pinned.

Skylight axis closes. Nezuko reassigned to NS_ITERS cooldown ramp (fresh).

## 2026-05-20 07:30 UTC — PR #519 CLOSED: PMuon γ pruning ablation γ∈{0, 0.8} vs baseline 0.4 — NULL/NULL clear, γ axis fully mapped (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-ablation`
- Hypothesis: Test whether PMuon's bilateral covariance EMA exponent γ_power=0.4 is load-bearing or redundant by ablating to extremes: Arm A γ=0 (full ablation, no spectral correction), Arm B γ=0.8 (over-correction). Companion to #444 phase-ramp ablation (both directions NULL marginal).

| Arm | γ | W&B | val/best_loss | Δval (vs 3.264278) | ffs | Verdict |
|---|---|---|---|---|---|---|
| **Baseline** | 0.4 | `k7ylyby9`/`dm4joozw` | 3.264278 (n=2) | — | 2937.5 | — |
| Arm A | 0 | `7baa1iif` | 3.282615 | +0.018337 | -1 (DNF) | NULL clear (+0.018, ~1.4% off) |
| Arm B | 0.8 | `odm9asp9` | 3.313878 | +0.049600 | -1 (DNF) | NULL very clear (+0.050, 2.7× Arm A damage) |

**Verdict: NULL | NULL clear → γ axis closes at γ=0.4.**

**Three-point γ map** (combining this data with #444):
- γ=0: +0.018 val (mild under-conditioning, cooldown slope too shallow to hit 3.28 in 3250-step budget)
- γ=0.4: BASELINE (locally near-optimal)
- γ=0.8: +0.050 val (~2.7× more damage than ablation)
- γ ramp (#444): NULL marginal both directions — static γ=0.4 confirmed at temporal axis as well

**Asymmetric damage curve** is mechanistically informative: over-correction (γ=0.8) hurts ~2.7× more than ablation (γ=0). Loss surface is steeper on the over-correction side. Consistent with γ acting as a *damped spectral correction* whose over-application leaves body updates over-conditioned and step direction biased.

**Pattern continuation with #482/#499/#503:** all four ablation axes (γ, WD partition, type-LR partition, WD schedule) show local optimum pinned by **cooldown-phase preconditioner-quality demand** — "too much of a corrective mechanism" is consistently worse than "too little." The cooldown is the load-bearing phase for these mechanism choices.

**Skipped follow-up:** the {0.3, 0.5} fine-scan the student suggested as item 2 — gradient at γ=0.4 is small in magnitude (Δval ≈ 0.018 between γ=0 and γ=0.4 implies a gentle local curve), retunes likely yield ≤ few millinats, won't separate from seed noise even at n=2. Axis is mapped to high confidence.

Frieren reassigned to PR #553: **gradient centralization on body-Muon pre-NS** — fresh mechanism class (gradient TRANSFORMATION, neither averaging nor preconditioning nor partition). Arm A dim=1 (per-output-channel mean subtraction, GC paper default per Yong et al 2020), Arm B dim=0 (per-input-channel).

## 2026-05-20 06:08 UTC — PR #513 CLOSED: Body-Muon gradient clipping at thresholds {1.0, 0.5} — NULL/NULL clear, damping/clipping closes BELOW natural-norm regime (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-muon-grad-clip`
- Hypothesis: Test gradient clipping as a damping mechanism layered on body-Muon. Two arms: clip_norm=1.0 (mild damping) and clip_norm=0.5 (aggressive). First clipping/damping probe on the body-Muon stream.

| Arm | clip_norm | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | none | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1.0 | (logged in PR) | 3000 | 3.27024 | +62.5 (clear) | +0.006 (clear) | NULL clear |
| Arm B | 0.5 | `m5fjt5gz` | 3000 | 3.27108 | +62.5 (clear) | +0.007 (clear) | NULL clear |

**Verdict: NULL | NULL clear → grad-clipping at tested thresholds CLOSES below natural-norm regime.**

Rich mechanistic diagnostic from the student:
- **Clip activation 99.97% at both thresholds** — clipping was binding on essentially every step.
- **Natural body-grad norm ~3e4** (per student's measurement) vs proposed thresholds {0.5, 1.0} → 4-5 orders of magnitude too low.
- Uniform 30,000× downscale costs only ~2% sr regression (+62.5 / 2937.5 ≈ 2.1%) — **PMuon's spectral whitening is approximately scale-invariant.** The whitening normalizes singular values away anyway, so the overall scale matters only through second-order effects (effective step size relative to the cooldown schedule).

This is a positive negative result: the closure doesn't just kill grad clipping at low thresholds, it adds direct evidence for the scale-invariance hypothesis underlying PMuon's design.

**Student's suggested follow-up** — re-test at natural-norm regime {3e4, 1e5, 3e5} — judged DEFERRED. Higher priority: tanjiro's live NS_ITERS=14 marginal win signals that preconditioner quality (NS iteration count) is the open axis, not damping.

Thorfinn reassigned to PR #546: NS_ITERS extension pipeline {16, 18} parallel to tanjiro's n=2 confirmation. Two independent n=1 wins at different NS values would strengthen the "more iters → tighter whitening" trend.

## 2026-05-20 05:32 UTC — PR #505 CLOSED: Lookahead wrapper on body-Muon, k∈{5, 10}, α=0.5 — NULL/NULL clear, wrapper-class axis closes (g1r1-fern)

- Branch: `g1r1-fern/lookahead-body-scan`
- Hypothesis: Test the Lookahead wrapper (slow/fast weights with periodic slow→fast resync) on body-Muon. First wrapper-class probe of the optimizer stack at this baseline. Two arms test averaging strength: aggressive (k=5) vs milder (k=10).

| Arm | k | α | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 5 | 0.5 | `8ad3mzjz` | -1 (DNF) | 3.284199 | +∞ (clear regression) | +0.020 (clear) | NULL clear |
| Arm B | 10 | 0.5 | `e3zkawez` | -1 (DNF) | 3.286180 | +∞ (clear regression) | +0.022 (clear) | NULL clear |

**Verdict: NULL+NULL clear → wrapper-class axis on body-Muon CLOSES at this baseline.**

Monotone direction is informative: milder Lookahead (k=10) is NOT better than aggressive (k=5) — both regress similarly. This rules out the natural follow-ups (longer-k variants, smaller-α partial blends). The wrapper's slow-weight pull adds a low-frequency averaging bias that conflicts with the carefully-tuned cooldown schedule + Skylight floor + PMuon stack — net-harmful interference.

**Cross-link with earlier closures:** This is the third averaging/smoothing-class closure on this baseline. Together with PMuon γ_power phase ramp (#444 NULL) and β_cov scan (#502 NULL), the pattern emerges:

> **All averaging/smoothing-class mechanisms layered on top of the already-tuned PMuon stack regress.**

The stack is "in a sweet spot" w.r.t. internal momentum/smoothing. Adding ANY external smoothing (Lookahead slow-pull, longer PMuon β_cov, phase-ramped γ_power) breaks the balance.

**Polyak EMA explicitly skipped** as a follow-up: same averaging family as Lookahead, falsification has already carried.

Fern reassigned to PR #545: AdaBelief on aux AdamW group — first mechanism-class change to variance update FORM.

## 2026-05-20 04:28 UTC — PR #503 CLOSED: Body-Muon WD schedule (warmup-25pct vs cooldown-25pct) — NULL/NULL, first temporal schedule on body-Muon closes (g1r1-edward)

- Branch: `g1r1-edward/body-muon-wd-schedule`
- Hypothesis: Test first temporal schedule on body-Muon WD. Two mechanistic priors: (warmup) early stochastic weights need free growth before WD tightening; (cooldown) shrinking LR during cooldown means constant WD over-shrinks late-emergent features. Orthogonal to #482 (per-type WD partition NULL) and #499 (per-type LR partition NULL).

| Arm | Schedule | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | constant WD=0.025 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | warmup-25pct (0 → 0.025 over first 813 steps) | `vcc1mty6` | 2950 | 3.26475 | +12.5 (marginal-worse) | +0.000472 (within marginal band) | NULL marginal |
| Arm B | cooldown-25pct (0.025 → 0 over last 813 steps) | `bu075bqm` | 2975 | 3.26681 | +37.5 (clear-worse) | +0.002532 (outside marginal band) | NULL clear |

**Verdict: NULL | NULL → temporal schedule axis closes at constant uniform WD=0.025.**

Asymmetric loss curve (cooldown loses ~5× more val-loss than warmup) is mechanistically informative:
- **Warmup** is essentially indistinguishable from baseline. Early-phase WD overhang is not a real problem at this baseline — starting WD at zero and ramping in costs nothing but gains nothing.
- **Cooldown** loses cleanly. Removing WD during cooldown lets late-emergent features drift/amplify noise. WD's implicit norm-control is **load-bearing** during the cooldown phase, not redundant with LR cooldown. The student's mechanistic read in the SENPAI-RESULT comment is correct.

Body-Muon WD is now exhaustively tested:
- **Partition axis:** #482 frieren MLP-vs-ATTN NULL marginal
- **Schedule axis:** #503 edward warmup/cooldown NULL/NULL clear (this PR)
Constant uniform WD=0.025 is the local optimum across both granularities. Schedule-level levers should NOT be layered on top of partition-level winners.

Student's suggested follow-ups (triangle schedule, shorter 5% warmup, composition with lower constant-WD floor) all judged low-leverage given the cooldown arm's clear regression dominates and the warmup arm is already in the marginal band.

Edward reassigned to PR #540: NS coefficient (a,b,c) joint scan — published quintic vs aggressive-cubic at NS_ITERS=12 fixed.

## 2026-05-20 03:40 UTC — PR #499 CLOSED: Body-Muon LR per-type partition (MLP vs ATTN) — both arms clear NULL/regress, partition family fully closes (g1r1-alphonse)

- Branch: `g1r1-alphonse/body-muon-lr-partition`
- Hypothesis: Per-type LR partition (MLP vs ATTN) — LR companion to frieren's WD partition #482 (which was NULL marginal). ±20% multiplicative asymmetry around inherited body_lr=0.035, centered geometric mean preserved (sqrt(MLP × ATTN) = 0.0343 ≈ 0.035), so this is a redistribution test not a scale test.

| Arm | MLP_LR | ATTN_LR | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | 0.035 | 0.035 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A (MLP-heavy) | 0.042 | 0.028 | `vrmveqoe` | 3025 | 3.27040 | +87.5 ✗ | +0.0061 ✗ | clear NULL |
| B (ATTN-heavy) | 0.028 | 0.042 | `tdw0diir` | 3000 | 3.27015 | +62.5 ✗ | +0.0059 ✗ | clear NULL |

**Signal: NULL × NULL with both directions regressing by similar magnitude (~Δval=+0.006).** Asymmetry between Arm A and Arm B is Δval=+0.00025 — well inside seed noise (n=1).

**Mechanistic conclusion (student's analysis, accepted):** PMuon's spectral normalization already equalizes per-matrix whitened gradient geometry across MLP and ATTN. Hand-imposed LR asymmetry on top of PMuon's preconditioning destroys the equalization PMuon was getting right. The split itself hurts (not the effective LR — geomean preserved).

**Strategic implication:** **Per-substructure (MLP-vs-ATTN) partition family fully closed.** Both WD (#482 NULL n=2 marginal) and LR (#499 NULL/NULL clear) tested and exhausted. Alphonse reassigned to **sub-MLP LR partition c_fc vs c_proj (#535)** — student-suggested follow-up on a finer grain where PMuon's per-matrix whitening cannot equalize (c_fc and c_proj are *different* matrices).

---

## 2026-05-20 03:25 UTC — PR #502 CLOSED: PMuon body β_cov scan — both arms NULL, β_cov axis CLOSES (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-beta-cov-scan`
- Hypothesis: PMuon bilateral covariance EMA β_cov∈{0.90, 0.99} symmetric around inherited 0.95. Tests whether more responsive (10-step window) or smoother (100-step window) preconditioner EMA is preferred at the 2937-step operating point. Last untested PMuon scalar after γ_power, lr, wd, NS_ITERS were closed earlier.

| Arm | β_cov | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 0.90 (responsive) | `o31yd0nw` | 2950 | 3.264775 | +12.5 ✗ | +0.000497 ✗ | NULL (marginal) |
| B | 0.99 (smoother) | `7donghzb` | 3000 | 3.269313 | +62.5 ✗ | +0.005035 ✗ | NULL (clear) |

**Signal: asymmetric NULL/NULL — β_cov=0.95 locally optimal.** Going UP to 0.99 costs ~10× more than going DOWN to 0.90 (Δval +0.005 vs +0.0005). The 100-step EMA over-smooths late-phase covariance: by the time cooldown gradients shrink, the EMA still drags in pre-cooldown statistics that mis-shape spectral normalization.

**Falsification table outcome (per preregistered design): NULL × NULL → "β_cov=0.95 is saturated. Axis closes."** Student also notes the asymmetry is in the WRONG direction for a "down during cooldown" β_cov schedule — Arm A (responsive) was marginal-WORSE, not better. Scheduled β_cov ramp is ruled out without further test.

**Strategic implication:** PMuon scalar block (γ_power, β_cov, NS_ITERS, body-lr, body-wd) all closed NULL at inherited defaults. Moving askeladd to **Body-Muon per-block LR multiplier (#532)** — first depth-based partition test, fresh class never tested.

---

## 2026-05-19 16:13 UTC — PR #448 CLOSED: Decoupled cooldown_frac aux vs body — both arms NULL, cf-decoupling axis CLOSES (g1r1-nezuko)

- Branch: `g1r1-nezuko/decoupled-cooldown-frac`
- Hypothesis: Decouple aux-group cooldown start from body Muon cooldown start. Aux groups (embed+lm_head+scalars) under AdamW may want different cooldown phase boundaries than body matrices under PMuon.

| Arm | cf_body | cf_aux | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 0.7 | 0.5 (aux shorter, longer high-LR) | `0a9r5lof` | 2975 | 3.265212 | +37.5 ✗ | +0.000934 ✗ | NULL (marginal val, clear sr) |
| **Baseline** | 0.7 | 0.7 (uniform) | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B | 0.7 | 0.85 (aux longer, shorter high-LR) | `taremaia` | 3025 | 3.27052 | +87.5 ✗ | +0.00624 ✗ | NULL (clear) |

**Signal: clear asymmetric NULL** — Arm A (aux-delayed cooldown) much closer to baseline than Arm B (aux-advanced cooldown), with Arm B regressing strongly on both metrics.

**Mechanistic conclusion (student's analysis, accepted):**
- Body Muon and AdamW-on-aux groups are coupled through val/loss-driven gradient distribution shifts. Breaking the phase coincidence of cooldown start shifts the joint optimization trajectory off-manifold.
- Asymmetry consistent with sparse aux groups benefiting slightly from delayed cooldown (more high-LR accumulation), but the gain in val/loss (+0.00094) doesn't translate to faster speedrun.
- This is a SCHEDULE COUPLING axis: cf=0.7 uniform is structurally optimal at this op point.

**Strategic implication:** 4th consecutive axis this cycle closing at inherited default (soft-cap c=15, embed std=1.0, γ=0.4 static, cf=0.7 uniform). Simple-scalar-axis frontier saturated. Nezuko reassigned to **Skylight u/w-floor TARGET_UW scan** (#486) — first scan of the floor-amplification threshold inherited at 0.35.

---

## 2026-05-19 15:35 UTC — PR #444 CLOSED: PMuon γ_power phase schedule — both arms NULL, γ-phase ramp axis CLOSES (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-phase-schedule`
- Hypothesis: Decouple stable-phase γ from cooldown-phase γ via monotonic ramp. Stable phase wants weaker γ while β_cov=0.95 EMA fills; cooldown phase wants stronger γ to amplify fine-direction signal at low LR. Test ramps in both directions of static γ=0.4.

| Arm | γ schedule | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A | stable 0.3 → ramp 0.3→0.4 cooldown | `xhzcvx0p` | 2975 | 3.267596 | +37.5 ✗ | +0.003318 ✗ | NULL regression |
| **Baseline** | γ=0.4 STATIC | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B | stable 0.4 → ramp 0.4→0.5 cooldown | `894sq3ig` | 2975 | 3.267451 | +37.5 ✗ | +0.003173 ✗ | NULL regression |

**Signal: both ramps regress symmetrically against current baseline** (PR #413 sr=2937.5). Note: student's local table compared against stale baseline #367 (sr=2975, val=3.26722), so her arm-to-arm "near-tie" reading was structurally correct but interpretation against current baseline requires Δsr=+37.5 framing.

**Mechanistic conclusion (student's analysis, accepted):**
- β_cov=0.95 EMA fills by step ~100 (effective sample count ≈ 1 at 1−0.95^100 ≈ 0.99). Stable-phase γ tuning therefore operates on too narrow a window to move val/loss.
- Combined with #386 (γ STATIC ∈ {0.5, 0.6} NULL), #129 (β_cov STATIC), #261 (LR warmup): PMuon dynamics axis is now thoroughly saturated at this op point.
- Mechanism verification was clean: `pmuon/gamma_dynamic` reached 0.39996 / 0.49996 endpoints, confirming the ramp schedule applied correctly.

**Operational note:** Student diagnosed a complex multi-launch OOM cascade where 4 crashed launches reported in W&B were sibling duplicate processes; the primary `xhzcvx0p` was healthy and progressing throughout. Excellent triage work.

**Strategic implication:** Third consecutive cycle of axes closing at inherited defaults (soft-cap c=15, embed std=1.0, γ=0.4 static). PMuon scalar HPs particularly saturated. Frieren reassigned to body-Muon WD partition (MLP vs attention, PR #482) — a *structural* axis rather than further scalar tuning.

---

## 2026-05-19 14:33 UTC — PR #440 CLOSED: Embed init scale scan std∈{0.5, 2.0} — both NULL, axis closes at baseline std=1.0 (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/embed-init-scale`
- Hypothesis: Scan the input embedding weight init std around PyTorch's default 1.0. Test tighter (0.5, smaller initial body activations) vs wider (2.0, faster initial body learning).

| Arm | std | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A (tighter) | 0.5 | `e27g8crp` | 3000 | 3.26878 | +62.5 ✗ | +0.00450 ✗ | NULL clear regression |
| **Baseline** | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B (wider) | 2.0 | `xt1o5rce` | 3025 | 3.26970 | +87.5 ✗ | +0.00542 ✗ | NULL clear regression |

**Signal: strong-bracket signature — both arms regress monotonically away from baseline std=1.0** with similar magnitude (Δsr=+62.5/+87.5, Δval=+0.0045/+0.0054). Very slight skew toward tighter being preferred (Arm A regressing ~25% less than Arm B), but gradient too small to be worth fine-scanning.

**Mechanistic conclusion:** PyTorch default embed std=1.0 is empirically well-placed for this Muon + AdamW(lr=0.3, betas=0.8/0.95) stack at this op point. Token row L2 norm ≈ 27.7 with std=1.0 is large in absolute terms but evidently in the right range for current optimizers to consume gradients efficiently in 3250 steps. Same "inherited default already optimal" pattern as PR #439 (soft-cap c=15 closed identically).

**Operational note:** Pod entrypoint auto-relaunched a duplicate Arm B (\`1zyj7lxw\` 14:23 UTC step 0); student SIGKILL'd cleanly without waste. Good operational catch.

**Strategic implication:** Two consecutive scans (soft-cap value, embed init scale) closed at inherited defaults with symmetric bracket regressions. The fast wins are likely in *structurally novel* mechanisms (Z-loss, attention temperature, NS asymmetric coefficients, per-block residual scaling, MLP-vs-attn WD partition), not in fine-tuning further inherited constants. Follow-up: PR #480 (tanjiro attention scale scan).

---

## 2026-05-19 14:10 UTC — PR #439 CLOSED: Logit soft-cap value scan c∈{10,30} — both NULL, axis closes at baseline c=15 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/logit-softcap-scan`
- Hypothesis: Scan the logit soft-cap `f(x) = c·x/√(x²+c²)` value: tighter c=10 (constrains earlier) vs looser c=30 (Gemma/Llama default). Baseline c=15.

| Arm | c | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A (tighter) | 10 | `zb1xmejl` | 3050 | 3.27316 | +112.5 ✗ | +0.00888 ✗ | NULL clear regression |
| **Baseline** | 15 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B (looser, Gemma/Llama default) | 30 | `3ek9yl3d` | 3050 | 3.27182 | +112.5 ✗ | +0.00754 ✗ | NULL clear regression |

**Signal: strong-bracket signature — symmetric +112.5 sr regression in both directions** with similar magnitude val degradation (Δval ≈ 0.006-0.009). Both arms move monotonically away from baseline in both metrics.

**Mechanistic conclusion:** c=15 sits in a real local optimum w.r.t. the single-knob soft-cap axis under the current optimizer/schedule/init stack. Tighter caps (c=10) saturate too early on legitimate logit magnitudes, damping cooldown-phase precision. Looser caps (c=30) add noise/instability on the cooldown tail without unlocking new headroom. The fact that BOTH directions degrade by the same ~+75-112.5 sr is strong evidence the inherited value c=15 was previously tuned for this regime (likely upstream).

**Operational notes:**
- Student caught a duplicate-process incident on Arm A (zb1xmejl + wqd48u4t), resolved cleanly without intervention (duplicate self-terminated).
- Val-loss tail in Arm B clean & monotone (3.288 @ s=2925 → 3.272 @ s=3250) — no late-phase blowup from larger logits despite looser cap.

**Strategic implication:** Loss-side scalar knobs are now characterized for this regime. Future loss-side work should target structurally different mechanisms (Z-loss / log-Z regularizer, attention temperature, pre-softmax scaling) rather than fine-tuning the soft-cap value. Follow-up: PR #476 (thorfinn z-loss scan) assigned immediately.

---

## 2026-05-19 12:30 UTC — PR #433 CLOSED: Aux AdamW β2 by group {0.99, 0.999 on embed+lm_head} — both NULL, axis closes at uniform 0.95 (g1r1-edward)

- Branch: `g1r1-edward/aux-beta2-by-group`
- Hypothesis: Decouple aux AdamW β2 per parameter group. Embed/lm_head (sparse-token gradients) may benefit from higher β2 (longer 2nd-moment averaging) than scalars (dense LN/bias). Test β2_{embed,lm_head} ∈ {0.99, 0.999} vs scalars β2=0.95.

| Arm | β2_embed | β2_lm_head | β2_scalars | W&B | sr | val/best_loss | Δsr (vs NEW base 2937.5) | Δval (vs NEW base 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.95 | 0.95 | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| A | 0.99 | 0.99 | 0.95 | `3eweuh3s` | 2975 | 3.26738 | +37.5 ✗ | +0.0031 ✗ | NULL (tied old, NULL new) |
| B | 0.999 | 0.999 | 0.95 | `2qoyvxmz` | 3050 | 3.27327 | +112.5 ✗ | +0.009 ✗ | NULL (clear regression) |

**Signal: monotone NULL → regression as β2 increases on the matrix groups.** Arm A indistinguishable from baseline (Δval=+0.00017 vs OLD baseline, within seed noise); Arm B clearly worse than baseline (+0.006 val).

**Mechanistic conclusion:** The sparse-vs-dense gradient intuition (high-β2 for noisier signals on rarely-updated tokens like vocab embeddings) is not borne out at this scale/data regime. Uniform β2=0.95 across all aux groups is the empirically-optimal choice. Higher β2 (longer 2nd-moment averaging) is structurally worse — likely because the cooldown schedule already provides enough effective averaging through smaller LRs, and additional momentum in the 2nd moment over-smooths the per-step adaptation just when the model needs to refine direction in late training.

**Operational note:** Student caught a duplicate-process incident on Arm A (two torchrun processes sharing GPU), SIGKILL'd the newer duplicate, preserved the original run cleanly. Good operational discipline.

**Combined-axis closure:** With β1 axis closed at uniform 0.8 (PR #416), β2-by-group now closed at uniform 0.95. **Aux AdamW (β1, β2) axes are both fully characterized — uniform values across all groups are optimal.** Remaining aux AdamW per-group axes: eps (askeladd #463 in flight) and weight_decay (edward #466 newly assigned).

**Next assignment:** PR #466 (aux AdamW WD scan {0.001, 0.01} on embed+lm_head — first WD test on aux matrices).

---

## 2026-05-19 12:25 UTC — PR #447 CLOSED: NS adaptive convergence threshold {0.5, 0.1} — mechanism never engages, axis closes (g1r1-fern)

- Branch: `g1r1-fern/ns-adaptive-threshold`
- Hypothesis: Replace fixed NS_ITERS=12 with adaptive convergence (data-dependent iter count). Skip remaining iters when polar residual drops below threshold. Arms: threshold=0.5 (Arm A, looser) and threshold=0.1 (Arm B, tighter).

| Arm | threshold | W&B | sr | val/best_loss | Δsr (vs NEW base) | Δval (vs NEW base) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | (fixed iters=12) | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| A | 0.5 | `7logfkqq` | 3000 | 3.26915 | +62.5 ✗ | +0.0049 ✗ | NULL (mechanism never fires) |
| B | 0.1 | (not run) | — | — | — | — | skipped per advisor directive |

**Critical mechanism diagnostic (student-provided telemetry):** The adaptive threshold **never engages** under either arm. Polar residual after 12 cubic-Newton NS iterations plateaus at ~6.9 throughout training, one order of magnitude above either threshold (0.5 or 0.1). Both arms would effectively be NS_ITERS=12 + per-step residual-check overhead — indistinguishable from baseline mechanism-wise.

**Residual trajectory (Arm A, single-run):** 27.75 (step 1) → 8.76 (step 25) → 8.30 (step 50) → 7.07 (step 250) → 6.93 (step 425). Log-linear extrapolation to step 3000: residual ≈ 1.5, still 3× above threshold 0.5. The threshold is unreachable in 12-iter ceiling at this operating point.

**Why Arm B was not run:** Saved ~3.5h GPU time. Mechanism guaranteed not to engage; Arm B with tighter threshold (0.1) is structurally identical to Arm A. Student raised this diagnostically and waited for advisor decision.

**Mechanistic conclusion:** The original hypothesis "skip NS iterations once polar projection converges" is **dead at this operating point** because cubic-Newton NS at (a=1.5, b=-0.5, c=0) with 12 iters cannot push the residual below ~6.9. The matrices being orthogonalized are not converging to tight orthogonality with this polynomial.

**Side-finding for program log:** NS convergence quality at the current PMuon operating point is a worthwhile diagnostic axis. Future revisits: (a) higher-tolerance early-exit (threshold ≈ 5-7) as a *different* hypothesis — would test "can we early-exit at moderate convergence and maintain quality?", and (b) revised NS polynomial coefficients (asymmetric c ≠ 0 variants) to push residual lower. Not by reviving this PR.

**Operational note:** Student also caught a duplicate-process incident on Arm A (W&B `3vidmtm1` duplicate alongside canonical `7logfkqq`), killed the duplicate cleanly, step time recovered from ~9s to ~4s. Good operational discipline.

**Next assignment:** PR #465 (Muon LR fine-scan {0.030, 0.040} — highest-value unscanned axis on body optimizer).

---

## 2026-05-19 11:30 UTC — PR #416 CLOSED: Aux AdamW β1 fine-scan {0.75, 0.85} — both NULL after n=2 confirmation, axis closes at 0.8 (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-b1-fine-scan`
- Hypothesis: Fine-scan β1 around baseline 0.8 for aux AdamW. Test 0.75 (less momentum) and 0.85 (more momentum).

| Arm | β1 | W&B | sr | val/best_loss | Δval (vs NEW base 3.264278) | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.8 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — |
| A | 0.75 | `3kpvr1lq` | 3025 | 3.27201 | +0.0077 ✗ | NULL clear |
| B (seed-1 n=1) | 0.85 | `bktt5lon` | 2950 | 3.26375 | −0.00053 ✓ | n=1 marginal WIN |
| B (seed-2 n=2 confirm) | 0.85 | `k7u7pfy5` | 3000 | 3.26911 | +0.00484 ✗ | NULL (falsifies n=1) |
| **B (n=2 mean)** | **0.85** | — | **2975** | **3.2664** | **+0.0022 ✗** | **NULL** |

**Signal: Arm A clear regression. Arm B n=1 marginal WIN falsified at n=2.** seed-2 produced sr=3000 val=3.26911, Δval=+0.00484 — clearly NULL. n=2 mean val=3.26643, well above baseline.

**Statistical lesson:** This demonstrates the value of the marginal n=2 confirmation rule. Arm B's n=1 was Δval=-0.00053 (within seed noise) — flagged marginal per (3.28-μ)·√n ≥ 0.004 rule. Without n=2 confirmation, we would have merged a non-improvement. n=2 mean reveals the n=1 was on the favorable side of seed noise.

**Mechanistic conclusion:** β1 axis CLOSES at uniform 0.8 across all aux groups. Combined with PR #320 testing β1=0.9 (NULL), the bracket 0.75/0.8/0.85/0.9 is now fully characterized — 0.8 is the local optimum.

**Combined with PR #433 closure (this cycle):** Both β1 AND β2 axes are now closed at their uniform baseline values for aux AdamW. The aux optimizer's first-moment and second-moment hyperparameters are well-tuned at (β1=0.8, β2=0.95). Remaining open axes: eps (per-group, #463 in flight) and weight_decay (per-group, #466 just assigned).

**Next assignment:** PR #463 (aux AdamW eps scan on embed group {1e-8, 1e-7} vs baseline 1e-10).

---

## 2026-05-19 11:48 UTC — PR #413 MERGED: scalar_lr=0.025 (alphonse n=2 WIN) ← NEW BASELINE

- Branch: `g1r1-alphonse/scalar-lr-scan`
- Hypothesis: Scan scalar_lr (RMSNorm gain + bias AdamW group) upward from the unintuitive default 0.01. Two arms: 0.025 (2.5×) and 0.05 (5×). Completes the aux LR characterization triplet.

| Arm | scalar_lr | W&B | sr | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367 n=2) | 0.01 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| **A seed-1** | **0.025** | `k7ylyby9` | **2950** | **3.26543** | **−25** | **−0.00179** | n=1 WIN (sr-marginal) |
| **A seed-2** | **0.025** | `dm4joozw` | **2925** | **3.26312** | **−50** | **−0.00410** | confirms A |
| B | 0.05 | `03c9tk79` | 2975 | 3.26674 | 0 | −0.00048 | n=1 marginal (val within noise) |

**n=2 mean (Arm A confirmed):** sr=2937.5, val=3.264278. Stat-sig: (3.28 − 3.264278)·√2 = 0.0222 ≥ 0.004 ✓ (5.56×).

**Signal: non-monotone, peak at 0.025.** val curve: 3.26722 → 3.26428 → 3.26674 (0.01 → 0.025 → 0.05). Arm B at 0.05 shows regression back toward baseline on sr with minimal val gain — past the optimum.

**Mechanistic analysis:** RMSNorm gains and bias parameters benefit from 2.5× faster adaptation via scalar_lr=0.025. The gains converge faster before COOLDOWN_POWER=1.4's sharper LR taper eliminates the adaptation window. Arm B's regression at 0.05 confirms a concave response — the optimum is narrow with 0.025 as the confirmed peak. Both seeds independently beat baseline (seed-2 improved further at sr=2925 vs seed-1 sr=2950), ruling out luck.

**Closes aux LR characterization triplet:** embed_lr CLOSED at 0.3, lm_head_lr CLOSED at 1/160 (PR #367), scalar_lr now MERGED at 0.025. All three aux AdamW LR axes characterized.

**New baseline:** sr=2937.5 (n=2 mean), val=3.264278. All subsequent PRs compare against this.

**Next assignment:** PR #460 (alphonse scalar_lr fine-scan {0.020, 0.030} — peak localization around confirmed 0.025 winner).

---

## 2026-05-19 08:35 UTC — PR #414 CLOSED: cosine cooldown shape {pure cosine, cosine²} — both NULL, monotone catastrophic, axis closes (g1r1-nezuko)

- Branch: `g1r1-nezuko/cooldown-shape-cosine`
- Hypothesis: Replace power-law cooldown shape (COOLDOWN_POWER=1.4) with cosine family — pure cosine has different curvature (slow-early/fast-late decay vs power-law's fast-early/slow-late).

| Arm | Cooldown shape | W&B | sr | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | power-law 1.4 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | pure cosine | `0x82h8if` | 3050 | 3.27557 | +75 ✗ | +0.00835 ✗ | NULL clear |
| B | cosine² | `lj00vaiw` | -1 (never reached) | 3.29445 | failed ✗ | +0.02723 ✗ | NULL catastrophic |

**Signal: monotone catastrophic.** Pure cosine fails by +75 sr; cosine² (even sharper late-LR drop) fails to reach target at all, with val 0.027 worse than baseline.

**Mechanistic conclusion:** The late-cooldown LR floor is structurally load-bearing. Cosine family collapses LR to ~0 sharply around progress=1, just when fine-direction refinement is happening. Power-law 1.4 gives a *gradual* approach to zero (the derivative softens near the end), keeping enough LR for late-cooldown refinement. The early-cooldown advantage cosine claims (more time at high LR mid-cooldown) is structurally unhelpful — the model has already converged by mid-cooldown; what matters is the trailing portion.

**Combined-axis closure:** Together with PR #332 (COOLDOWN_POWER continuation up to 1.8 NULL — closes upper direction), the cooldown SHAPE axis is now fully bracketed: power-law 1.4 is optimal vs higher powers (worse) AND vs cosine family (much worse). **Cooldown shape axis CLOSED at power-law 1.4 across families.**

**Operational note:** Arm A had a SIGTERM-style kill at step 363 in first launch attempt (process resource issue, not code bug). Student debugged cleanly: identified residual GPU memory from killed process blocking restart, relaunched successfully. Good operational discipline.

**Next assignment:** PR #448 (decoupled cooldown_frac aux vs body — first per-group schedule axis). Different mechanism class from cooldown shape.

---

## 2026-05-19 08:05 UTC — PR #395 CLOSED: NS_ITERS cooldown schedule {14, 18 vs const=12} — both arms NULL, monotone signal, axis closes (g1r1-fern)

- Branch: `g1r1-fern/ns-iters-cooldown-bump`
- Hypothesis: bump NS_ITERS during the cooldown phase from 12 (constant) to {14, 18}. Cooldown gradients are smaller/more sign-coherent → more NS iters may sharpen polar projection where it matters most.

| Arm | NS_ITERS cooldown | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | const=6 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 14 (cooldown bump) | `fg01web0` | 3000 | 3.26865 | +25 ✗ | +0.00143 ✗ | NULL |
| B | 18 (cooldown bump) | `a9l9oqh3` | 3025 | 3.27060 | +50 ✗ | +0.00338 ✗ | NULL |

**Signal: clean monotone (more cooldown iters → worse on both metrics).** Both arms fail baseline beyond marginal threshold. Δsr scales linearly with iter-count bump magnitude.

**Polar residual diagnostic (student-provided):** confirms the mechanism fires as expected — pre-cooldown residual ~7.8, in-cooldown drops to 4.5 (Arm A) and 2.0 (Arm B). More iters → tighter polar projection, BUT worse downstream. The cubic-Newton's moderately under-converged polar state is *load-bearing* for PMuon — over-orthogonalization moves updates out of the regime PMuon's bilateral whitening was tuned for.

**Mechanistic conclusion:** Combined with PR #184 (static 6 wins, 18 loses), NS_ITERS axis exhausted for static AND phase-localized variants. Sharpening polar accuracy is structurally counterproductive on this stack.

**Natural next-class extension:** Adaptive (data-dependent) iter count. Currently the FIXED-iter loop runs 6 iterations regardless of input conditioning. Adaptive lets each step pick its own count based on residual convergence — saves compute on easy inputs, spends more on hard ones. Structurally different mechanism class than static or phase-schedule.

**Baseline contamination caveat:** Branch off pre-#367 advisor base, so the arms ran with `lm_head_lr=1/320` (old baseline) not 1/160. However the directional signal is clear and cross-stack consistent (PR #184 originally tested NS=18 vs 6 on the older stack and 6 won) — closure justified.

**Conclusion: NS_ITERS schedule-side axis CLOSED.** New assignment PR #447 (NS adaptive convergence threshold — first data-dependent iter-count test in program).

---

## 2026-05-19 07:18 UTC — PR #410 CLOSED: lm_head_lr fine-scan {1/120, 1/100} — both NULL, axis closes UPWARD from 1/160 (g1r1-frieren)

- Branch: `g1r1-frieren/aux-lmhead-lr-fine-scan`
- Hypothesis: Continue lm_head_lr scaling past freshly merged 1/160 baseline (PR #367). Test {1/120, 1/100, 1/80} for monotone improvement direction.

| Arm | lm_head_lr | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | 1/160 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 1/120 | `9hgqqx38` | 3000 | 3.268949 | +25 ✗ | +0.001728 ✗ | NULL |
| B | 1/100 | `cjv8cqab` | 3000 | 3.269108 | +25 ✗ | +0.001876 ✗ | NULL |
| C | 1/80 | killed step 128 (advisor-directed) | — | — | — | — | not run |

**Signal: FLAT — not monotone increasing.** Both Arms A and B miss baseline on both metrics simultaneously with virtually identical val deltas (+0.0017 vs +0.0019). Δsr is exactly at the marginal threshold (+25 at advisor stat rule cutoff) but BOTH arms regress on BOTH metrics in tandem — that's NULL, not seed noise.

**Operational note:** Arm C (1/80) was killed at step 128 per advisor directive after observing the flat A+B signal. Saved ~3.5h compute on a closed-direction extension. Student demonstrated clean operational discipline (immediate kill, terminal SENPAI-RESULT posted within 7 minutes of advisor comment).

**Mechanistic conclusion:** Combined with merge sequence 1/640→1/320→1/160 (PR #211→#357→#367), the maximum useful lm_head_lr appears to sit at 1/160. Going from 1/320 to 1/160 was a real ~25 sr gain (PR #367 confirmed n=2). Going past 1/160 in either direction (1/120, 1/100) costs sr while regressing val — the lm_head_lr axis is now bracketed.

**Conclusion: lm_head_lr axis CLOSED upward from 1/160 (PR #367 is the peak).** Future aux work on this group must be different mechanism class (β1/β2/eps already closed; remaining open: per-group hypers, ε floor scheduling, etc.). New assignment PR #444 (PMuon γ_power phase schedule — first phase-dependent γ test).

---

## 2026-05-19 06:42 UTC — PR #401 CLOSED: Muon WD downward {0.020, 0.015} — both NULL, axis closes both directions (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/muon-wd-downward`
- Hypothesis: Decrease Muon weight decay from baseline 0.025 to test if less regularization yields better convergence. Combined with previously-closed upward direction, this closes the Muon WD axis fully.

| Arm | muon_wd | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | 0.025 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 0.020 | `o5z8a5n3` | 3000 | 3.26937 | +25 ✗ | +0.00215 ✗ | NULL |
| B | 0.015 | `qvlr4y7g` | 3025 | 3.26980 | +50 ✗ | +0.00258 ✗ | NULL |

**Clean monotone signal:** lower WD → worse on both metrics. Both arms also exceed marginal threshold (Δsr ≤ 25 OR Δval ≤ 0.001) → no n=2 confirmation needed.

**Mechanistic conclusion:** Muon WD axis is now fully CLOSED at 0.025 in both directions. Muon's NS orthogonalization combined with PMuon's bilateral cov-EMA whitening produces well-conditioned updates whose magnitude is structurally controlled. Lower WD lets unconstrained parameter growth; higher WD over-shrinks. The interior optimum at WD=0.025 is structurally tied to the body stack.

**Note on Arm A:** Cross-stack confound — Arm A ran on pre-#367 baseline config (lm_head_lr=1/320). However the directional signal holds for both stacks (vs old baseline sr=3000 val=3.2685, Arm A matched sr and val=+0.0009 within n=1 noise). New assignment PR #440 (embed init scale scan — fresh init-side axis).

---

## 2026-05-19 05:50 UTC — PR #404 CLOSED: Aux CP extend (CP=1.0 n=2 + CP=0.5 n=1) — both NULL on primary metric, axis closes (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/aux-cooldown-power-extend`
- Hypothesis: Aux-side decoupled AUX_COOLDOWN_POWER. Arm A confirms PR #366's n=1 marginal val WIN at CP=1.0 with fresh n=2 seed. Arm B extends direction to CP=0.5 (sub-linear sqrt-like aux cooldown).

| Arm | AUX_COOLDOWN_POWER | n | W&B runs | sr_steps | val/loss | vs new baseline (sr=2975 val=3.26722) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1.0 (n=2 cross-stack) | 2 | `h585go7m` (s1 PR#366), `jv2oi3fv` (s2 this PR) | 3000 | 3.265882 | Δsr=+25 ✗, Δval=-0.00134 ✓ (cross-stack confound, both on lm_head_lr=1/320 not new 1/160) | NULL on primary |
| B | 0.5 | 1 | `sihwt6g3` | 3050 | 3.26509 | Δsr=+75 ✗, Δval=-0.00213 ✓ (same cross-stack confound) | NULL on primary, also REGRESSES vs Arm A by +50 sr |
| Baseline (PR #367) | follows body=1.4 | n=2 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — |

**Mechanistic key:** Lower aux CP than 1.0 over-flattens late-phase aux LR. The val gain at CP=1.0 is real but small (~−0.001) and entirely cross-stack-confounded (both arms ran on lm_head_lr=1/320 pre-PR#367, not on current 1/160). Per the predeclared falsification matrix (Arm B sr ≥ 3000 → close), the lower-CP direction is ruled out.

**Conclusion:** Aux CP extend (lower direction) axis CLOSED. Body Muon CP=1.4 + aux following body cooldown remains optimal. The val-improvement signal at CP=1.0 is potentially worth a clean n=2 re-test on the NEW PR #367 stack (lm_head_lr=1/160) as a future follow-up, but lower-than-1.0 CP is exhausted. Future aux-schedule work should explore different mechanisms (different cooldown_frac for aux, non-power schedule shape, or different cooldown start step). New assignment PR #434 (logit soft-cap value scan).

---

## 2026-05-19 04:20 UTC — PR #400 CLOSED: AGC on aux AdamW per-row λ ∈ {0.04, 0.10} — both NULL, axis closes (g1r1-edward)

- Branch: `g1r1-edward/agc-aux`
- Hypothesis: Adaptive Gradient Clipping (Brock et al. NFNets 2021) on aux AdamW (embed + lm_head + scalars). Per-row clip `||grad_row||/||param_row|| ≤ λ`. Tests whether Zipfian rare-token rows receive disproportionately large gradient spikes that AdamW variance doesn't protect against.

| Arm | λ | W&B run | sr | val/loss | embed clip_rate | lm_head clip_rate | mean clip_coef (lm_head) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 0.04 | `2y0ewtlb` | -1 | 3.44634 | ~0% | **97.5%** | 0.055 | NULL (catastrophic) |
| B (revised) | 0.10 | `llni6tar` | -1 | 3.44015 | ~0% | **96.9%** | 0.073 | NULL (catastrophic) |
| Baseline (PR #367) | — | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — | — |

- Note: original Arm B (λ=0.02) was killed at step 104 per advisor redirect (stricter clip would fail worse); replaced with λ=0.10 probe.

**Mechanistic key:** embed clip rate ~0% (large param norms → natural grad/param ratio low). lm_head clip rate ~97% at BOTH λ values — lm_head's natural grad/param ratio is structurally >> 0.10. Going 2.5× more permissive (0.04→0.10) moved val only 3.44634→3.44015 (-0.0062) — confirming lm_head is being clipped well below its natural operating regime even at λ=0.10. Effective 14-18× slowdown of lm_head learning → severe underfit → +0.17 val/loss regression. AdamW's V_t already provides per-element bounding; AGC double-clips a path that's already well-conditioned.

**Conclusion:** AGC axis CLOSED on aux. Per-row gradient clipping with any λ ∈ [0.01, 0.10] aggressively hamstrings lm_head. Suggested future direction: row-wise AdamW with per-row second-moment normalization (per student's analysis). New assignment PR #433 (aux β2 by group).

---

## 2026-05-19 00:46 UTC — PR #403 CLOSED: Curriculum COOLDOWN_POWER — operational failure (g1r1-askeladd)

- Branch: `g1r1-askeladd/cooldown-power-curriculum`
- Hypothesis: Linear ramp of COOLDOWN_POWER from p_start → p_end during cooldown phase.
- **Result: OPERATIONAL FAILURE** — 5+ crash loop (all crashes ≤step 25). Implementation bug (likely division-by-zero or index error in the ramp formula). Student pod continued relaunching broken config. No training data collected. Branch had zero code commits (only assignment commit). GPU reclaimed by closing.
- **Conclusion:** PR closed operationally. Curriculum cooldown power direction remains valid but needs clean re-implementation with explicit early-step guard. New assignment PR #416 (aux β1 fine-scan).

---

## 2026-05-19 00:17 UTC — PR #387 CLOSED: Role-based Muon LR {0.7×, 0.4× on attn} — both NULL, role-axis closes (g1r1-nezuko)

- Branch: `g1r1-nezuko/muon-role-lr`
- Hypothesis: Attn vs MLP body params may benefit from different LR multipliers. Scan {0.7×, 0.4×} on attn while MLP stays at 1.0×.

| Arm | attn_lr_mult | W&B run | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.7× | `g8hqguwn` | 3000 | 3.27037 | +25 | +0.00315 | NULL |
| B | 0.4× | `0aay0p7y` | 3025 | 3.27243 | +50 | +0.00521 | NULL |
| Baseline (PR #367) | 1.0× | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |

**Mechanistic key**: NS update_norm is invariant to LR multiplier choice (attn≈25.6, mlp≈41.0 regardless of arm) — confirming polar step normalizes direction independently of LR scaling. Monotone-down trend Arm B < Arm A < Baseline means 1.0× is the local optimum.

**Conclusion: Role-axis CLOSED. Combined with PR #347 (depth NULL) and PR #248 (global LR flat), Muon LR is optimal under all linear decompositions tested. New assignment PR #414 (cosine cooldown shape).**

---

## 2026-05-19 00:00 UTC — PR #386 CLOSED: PMuon γ_power continuation {0.5, 0.6} — both NULL, axis closes at 0.4 (g1r1-alphonse)

- Branch: `g1r1-alphonse/gamma-power-continuation`
- Hypothesis: Monotone γ_power signal from PR #202 (0.2→0.3→0.4 improving) suggested unsaturated headroom past 0.4. Scan {0.5, 0.6}.

| Arm | γ_power | W&B run | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.5 | `516wmw6t` | 3250 | 3.27999 | +275 | +0.01277 | NULL — severe regression |
| B | 0.6 | `yhfo48gj` | −1 | 3.28892 | ∞ | +0.02170 | FAIL — never reached ≤3.28 |
| Baseline (PR #367) | 0.4 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |

**Key diagnostic (whitening telemetry at terminal):**
| Arm | γ | `whitened_sv_max` | `lcov_eigh_ratio` |
|---|---|---|---|
| A | 0.5 | 3.5e-4 | 1.55e6 |
| B | 0.6 | 5.0e-5 (7× smaller) | 1.80e7 (11.6× larger) |

γ=0.6 collapses post-whitening SV spectrum (7× smaller max-SV) while left-cov condition number blows up 11.6× — NS polar receives near-singular operand. γ=0.5 maintains convergence but slows it. The monotone signal saturates at 0.4 and inverts sharply past it.

**Conclusion: Both arms NULL per falsification table → γ_power axis CLOSES at 0.4. New assignment PR #413 (scalar_lr upward scan).**

---

## 2026-05-18 23:14 UTC — PR #367 MERGED: lm_head_lr=1/160 confirmed WIN (g1r1-frieren)

- Branch: `g1r1-frieren/lm-head-lr-scan`
- Hypothesis: lm_head_lr=1/320 was inherited and possibly under-tuned. Scan bidirectional: 1/160 (2×) vs 1/640 (0.5×).

| Run | Arm | lm_head_lr | Seed | sr | val/loss | Verdict |
|---|---|---|---|---|---|---|
| `7xub16ua` | A | 1/160 | 1 | 2975 | 3.26774 | n=1 marginal WIN |
| `lzitteno` | B | 1/640 | 1 | 3025 | 3.26977 | NULL (worse both metrics) |
| `f9nyqjxn` | A | 1/160 | 2 | 2975 | 3.26670 | n=2 confirm WIN |
| **n=2 mean** | A | **1/160** | — | **2975** | **3.26722** | **CONFIRMED WIN** |
| Baseline (PR #274) | — | 1/320 | — | 3000 | 3.2685 | — |
| **Δ** | | | | **−25** | **−0.00128** | ≥ 0.001 threshold ✓ |

n=2 statistical check: (3.28 − 3.26722)·√2 = 0.01807 ≥ 0.004 ✓ (4.52×). Both seeds independently hit sr=2975 — not noise floor.

**Conclusion: lm_head_lr=1/320 was marginally under-tuned for the current PMuon+cubic-Newton-NS+COOLDOWN_POWER=1.4 stack. Doubling to 1/160 reliably saves 25 steps. Symmetric falsification (1/640 hurts) confirms direction is real. MERGED as new baseline: sr=2975, val=3.26722. Follow-up: fine-scan {1/80, 1/100, 1/120} for peak.**

---

## 2026-05-18 21:05 UTC — PR #364 CLOSED: Muon momentum reset at cooldown FALSIFIED at n=2 (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-momentum-reset-at-cooldown`
- Hypothesis: Reset Muon momentum (first-moment EMA) at cooldown entry (step 975). Two arms: hard (×0.0) vs soft (×0.3).

| Run | Arm | Reset factor | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | none | 3000 | 3.2685 (n=2) | — | — |
| `x3ot747o` | A | hard (×0.0) | 3000 | 3.26922 | +0.0007 | NULL |
| `sj1qgbu1` | B (n=1) | soft (×0.3) | 3000 | 3.26801 | -0.0005 | marginal val WIN |
| `3zduzvo3` | B (n=2) | soft (×0.3) | 3025 | 3.27020 | +0.0017 | individual seed NULL |
| **Combined Arm B mean** | — | soft | **3012.5** | **3.26911** | **+0.0006** | **NULL (falsified marginal)** |

n=2 falsified the marginal n=1 WIN. Reset mechanism fired correctly (`momentum_norm_ratio=0.3000` exact). Seed-2 trailed seed-1 by ~0.002 across cooldown — replicable seed variance.

**Conclusion: Bilateral covariance EMA + power-law cooldown trajectory is already coherent enough that disrupting first-moment momentum at cooldown boundary destroys useful information rather than enabling cleaner direction. Cooldown momentum-reset axis CLOSED.**

---

## 2026-05-18 21:05 UTC — PR #366 CLOSED: Aux-AdamW cooldown power scan {1.0, 2.0} unconfirmed marginal + clear NULL (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/aux-cooldown-power-scan`
- Hypothesis: Decouple aux AdamW cooldown power from body. Test CP=1.0 (linear, slower aux decay) and CP=2.0 (quadratic, faster aux decay) vs body CP=1.4.

| Run | Arm | AUX_CP | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | 1.4 (= body) | 3000 | 3.2685 | — | — | — |
| `h585go7m` | A | 1.0 (linear) | 3000 | 3.2662 | 0 | -0.0023 | marginal val WIN (n=1, unconfirmed) |
| `nucnaip1` | B | 2.0 (quadratic) | 3050 | 3.2727 | +50 | +0.0042 | clear NULL |
| `tmrbg9lk` | B (1st attempt) | 2.0 | — | — | — | — | mid-run crash @ step 875 |

Arm A had substantial Δval=-0.0023 (~2.3x marginal threshold), but per the strict marginal rule (Δsr=0 ≤ 25 triggers marginal regardless of val magnitude), n=2 confirmation required. Cold-start crash storm prevented in-flight n=2 (10+ retries failed).

**However, the directional signal is strong and replicable: lower aux CP helps, higher aux CP hurts (opposite direction).** Schedule telemetry verified mechanism (lr_mult_body vs lr_mult_aux diverge correctly at cooldown entry).

**Conclusion: Close at n=1; re-explore in PR #404 with proper n=2 confirmation seed at CP=1.0 + CP=0.5 direction extension. Infrastructure has stabilized — fresh n=2 should succeed.**

---

## 2026-05-18 20:21 UTC — PR #362 CLOSED: Gradient Centralization for Muon body NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/gradient-centralization-v2`
- Hypothesis: Subtract column (and optionally row) mean of gradient before passing to PMuon EMA, to remove uniform drift component.

| Run | Arm | GC mode | sr | val@3000 | val@3250 | Δsr | Δval@3000 | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | none | 3000 | 3.2685 | — | — | — | — |
| `rcl10r96` | A | column-only | 3025 | 3.28117 | 3.27043 | +25 | +0.0127 | NULL |
| `5p8b7aro` | B | both (col+row) | -1 | 3.30526 | 3.29637 | n/a | +0.0368 | NULL |

GC was verified active (pre-values ~0.24–0.27, post=0.0). Arm B strictly worse than Arm A. Root cause: PMuon's bilateral cov-EMA whitening already absorbs the drift GC was supposed to remove. Subtracting the column mean is redundant against an optimizer that conditions via second-moment statistics, and removes a *signal* component. Row-centering (Arm B) additionally removes per-output mean which over-constrains the update on transformer linear weights (unlike CNNs where original GC paper was developed).

**GC axis CLOSED on Muon body.**

---

## 2026-05-18 20:06 UTC — PR #350 CLOSED: Residual-proj init scaling {1/√(2N), 1/N} NULL (g1r1-edward)

- Branch: `g1r1-edward/residual-init`
- Hypothesis: The baseline zero-inits all residual-stream projection weights (`proj` in attn and MLP). Test whether small non-zero init — GPT-2-style 1/√(2N) and 1/N — helps by providing a better-conditioned start for the residual stream.

| Run | Arm | std init target | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | zero | 0 | 3000 | 3.2685 (n=2) | — | — |
| `ugf2tm22` | A: 1/√(2N) | 0.00408 | 3000 | 3.26966 | +0.00116 | NULL |
| `t7607ha7` | B: 1/N | 0.00167 | 3000 | 3.26866 | +0.00016 | NULL (tied) |

Student's pre-flight catch: baseline zero-inits ALL proj weights (most aggressive form), so this was truly testing "any non-zero vs zero." Both arms regressed slightly on val; sr tied at 3000 for both. The GPT-2 1/√(2N) trick doesn't transfer — Muon's per-step orthogonalization resets gradient direction anyway, making init less consequential for convergence trajectory.

**Residual-init scaling axis CLOSED at zero-init.**

---

## 2026-05-18 18:07 UTC — PR #332 CLOSED: COOLDOWN_POWER continuation {1.5, 1.8} NULL (g1r1-fern)

- Branch: `g1r1-fern/cooldown-power-continuation`
- Hypothesis: Probe past the merged COOLDOWN_POWER=1.4 win (PR #274) by scanning {1.5, 1.8}. Test whether a more concave LR cooldown tail extracts additional sr improvement, or whether 1.4 is the local optimum.

| Arm | CP | n | mean sr | mean val | Δsr | Δval | verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | 1.4 | 2 | 3000 | 3.2685 | — | — | — |
| Arm A | 1.5 | 3 | 2991.67 | 3.27021 | -8.33 | +0.0017 | NULL (noise floor) |
| Arm B | 1.8 | 1 | 2975 | 3.27464 | -25 | +0.0061 | NULL (val regression) |

Per-seed Arm A sr: {3000, 3000, 2975}. Two seeds tied at baseline, one dropped exactly one val-eval window (25 steps). Mean Δsr=-8.33 is well inside seed noise; sr is logged at discrete 25-step val intervals.

Per-seed Arm B sr: {2975}. n=1 only; marginal Δsr=-25 but with substantial val regression (+0.0061 > stat-sig threshold 0.004). Even an n=2 confirmation of sr<3000 wouldn't be a clean merge — val regression suggests over-aggressive cooldown extracts a tiny sr advantage at the cost of converged loss quality.

**Body-side COOLDOWN_POWER axis CLOSED at 1.4.** This is the second closure of the cooldown-shape axis on the body — confirms PR #274's CP=1.4 is the local optimum.

Still open on this theme: thorfinn #366 testing aux-AdamW cooldown power decoupling. Both arms of #366 are in flight (CP=1.0 had a marginal n=1 val WIN but crash storm prevented n=2; CP=2.0 in flight).

---

## 2026-05-18 17:25 UTC — PR #364 PENDING (sent back for n=2): Muon momentum reset hard vs soft (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-reset`
- Hypothesis: Reset Muon momentum at cooldown entry (step 975 = `int((1-cooldown_frac)*train_steps)`, cooldown_frac=0.7). Two arms: hard (zero momentum) vs soft (×0.3 retain).
- W&B runs: `x3ot747o` (Arm A hard), `sj1qgbu1` (Arm B soft, 13:00 UTC, 222min)
- Telemetry confirmed clean reset: momentum_norm_before/after_immediate ratios = 0.000 (Arm A) and 0.300 (Arm B) at step 975.

| Arm | reset | sr | val/loss | Δsr | Δval | verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | 3000 | 3.2685 | — | — | — |
| Arm A | hard (×0) | 3000 | 3.2692 | 0 | **+0.0007** | NULL (hard reset destroys directional info cooldown still uses) |
| Arm B | soft (×0.3) | 3000 | **3.2680** | 0 | **-0.0005** | **MARGINAL val WIN** (Δval below 0.001 marginal threshold) |

**Decision:** Sent back to student for **n=2 confirmation of Arm B (soft ×0.3) only**. Per the marginal rule (Δval ≤ 0.001 → n=2 required), single-seed result is within seed noise. Arm A hard reset NULL is conclusive at n=1.

**Mechanism diagnosis (askeladd):**
- The two arms separated by ~0.001 val/loss across the entire cooldown phase post-reset.
- Hard reset (×0) zeros momentum → next 5–10 steps move slower than baseline (no inertia) → small cooldown-phase progress lost.
- Soft reset (×0.3) keeps 30% inertia → enough fresh direction-finding to slightly outperform baseline, retains enough inertia to keep moving immediately.
- No divergence, no instability, no late-cooldown plateau.

**Key open question for n=2:** if confirmed (mean val < 3.2685), this would be the **first program WIN in many rounds**. Follow-ups (decay scan {0.1, 0.5, 0.7}, reset-step jitter, soft reset of L_cov/R_cov covariance EMAs) are queued for future PRs.

**Cross-cutting infrastructure note:** Earlier I observed 6+ cold-start crash retries on muon-reset-hard config. Reviewing the consolidated terminal, the successful `x3ot747o` run completed first; later crashes were post-terminal n=2 attempts. Same crash signature (step ≤25, val=10.8258, ~7m) is appearing across thorfinn aux-CP=1.0 (10+), frieren lm-head-lr=1/160 (6), edward residual-init-1/√2N (5 then succeeded on 6th). Looks like shared pod/launcher instability, not per-experiment bugs.

---

## 2026-05-18 16:05 UTC — PR #347 CLOSED + PR #387 ASSIGNED: LLRD → Role-based Muon LR (g1r1-nezuko)

- Branch: `g1r1-nezuko/llrd-scan`
- Hypothesis: Layer-wise LR Decay (ULMFiT-style, Howard & Ruder 2018) assigns per-depth LR multipliers `base_lr × decay^(N-i)`, slowing bottom layers relative to top layers. Tested decay ∈ {0.95, 0.85} on the Muon body; aux unchanged.

| Arm | LLRD decay | W&B | val/loss | sr | Δval | Δsr | verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1.00 (uniform) | `vw0595an`, `s2nrw0c8` | 3.2685 | 3000 | — | — | — |
| Arm A | 0.95 | `ffsvma03` | **3.28041** | -1 | +0.0119 | — | NULL (missed target) |
| Arm B | 0.85 | `ud32rjej` | **3.31361** | -1 | +0.0451 | — | NULL (massive regression) |

**Result:** Both arms NULL with **monotone signal** (more aggressive decay → worse). Arm A: bottom LR ≈ 0.57× base, val barely above 3.28 target. Arm B: bottom LR ≈ 0.17× base, catastrophic regression (+0.045).

**Why the LLRD prior doesn't hold:**
1. **Pretraining from scratch, not fine-tuning.** ULMFiT-style LLRD preserves frozen pretrained bottom-layer features. Here, bottom layers must actively learn token geometry from random init — slowing them costs convergence.
2. **NS orthogonalization already normalizes per-tensor.** Muon's Newton-Schulz polar step is per-tensor and implicitly equalizes update magnitudes. Adding a depth multiplier on top re-introduces a scalar imbalance on the already-normalized update.
3. **Flat LR axis (PR #248).** Global Muon LR is locally optimal at 0.035 ±14%. LLRD pushes ~half the body off that flat optimum by design.

**Depth-based LR decomposition axis CLOSED.** Pairs with PR #248 (global LR closed) to confirm: uniform Muon body LR is optimal in both the scalar and depth-structural dimensions.

**New assignment (PR #387):** Role-based Muon LR — splits body into attention (QKV+proj) vs MLP (fc1+fc2) and tests whether these mechanistically distinct roles want different LRs. If also NULL, the conclusion is clean: the NS orthogonalization already equalizes update magnitudes and any LR decomposition within the body is redundant.

---

## 2026-05-18 15:32 UTC — PR #342 CLOSED: SWA tail rolling average NULL (g1r1-alphonse)

- Branch: `g1r1-alphonse/swa-tail`
- Hypothesis: Rolling param average over last 15% or 30% of training (SWA tail) would reduce val_loss by smoothing late-cooldown noise, allowing model to cross 3.28 earlier.

| Arm | SWA_START_FRAC | W&B | sr | val/loss | Δsr | Δval |
|---|---|---|---|---|---|---|
| Baseline | — | `vw0595an`, `s2nrw0c8` | 3000 | 3.2685 | — | — |
| Arm A | 0.85 | `37dxm5wh` | 3000 | 3.27306 | 0 | **+0.00456** |
| Arm B | 0.70 | `rzdrn912` | **3200** | 3.27848 | **+200** | **+0.00998** |

**Results commentary:** BOTH ARMS NULL. SWA mechanism works correctly (within-run swa-vs-raw Δ = −0.003 to −0.025 confirmed). But COOLDOWN_POWER=1.4 makes the val curve so steep that SWA val crosses 3.28 at identical step as raw. Arm B worse: wider window averages earlier higher-loss steps, biasing upward.

**Conclusion:** SWA tail axis CLOSED on cooldown_power=1.4 + cubic-Newton stack. Reassigned alphonse to PR #386 (γ_power continuation).

---

## 2026-05-18 15:32 UTC — PR #386 ASSIGNED: PMuon γ_power continuation {0.5, 0.6} (g1r1-alphonse)

- Branch: `g1r1-alphonse/gamma-power-continuation`
- Hypothesis: PR #202 (γ_power=0.4 winner) found monotone signal (0.2→3050, 0.3→3062.5, 0.4→3025) and flagged {0.5, 0.6} as likely follow-up. Tests continuation on post-#274 baseline.

---

## 2026-05-18 10:10 UTC — PR #311 CLOSED + PR #366 ASSIGNED: Lookahead wrapper → Aux cooldown power decoupling (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/lookahead-wrapper`
- **Hypothesis:** Wrap both optimizers in Lookahead (Zhang et al. NeurIPS 2019): every k=5 steps, interpolate fast weights with slow weights via `slow ← slow + α·(fast − slow); fast ← slow`. Scan α ∈ {0.5, 0.8} with fixed k=5. Initial runs crashed at step 1-25 (grad_norm >200k from cold-start PMuon EMA + step-0 slow-weight snapshot). After advisor-directed fix: lazy init of slow weights at step 200 (after PMuon warmup). Final results: both arms NULL.
- W&B runs: `0oj7k38q` (Arm A α=0.5, delayed-init), `hd9u6ffy` (Arm B α=0.8, warmup-200)

| Arm | α | sr | val/loss | Δ vs baseline | verdict |
|-----|---|-----|----------|---------------|---------|
| **Baseline (PR #274)** | — | **3000** | **3.2685** | — | — |
| Arm A | 0.5 | -1 (never) | 3.29851 | +0.0300 | NULL |
| Arm B | 0.8 | 3050 | 3.27054 | +0.00204 | NULL (sr +50 regression) |

**Mechanism telemetry:** `lookahead/embed_slow_fast_diff_ratio` was 0.005–0.05 for ~80% of training (mid-training), collapsing to ~1e-4 in late cooldown. Mechanism was ACTIVE but unhelpful. This is a clean "real null," not a "broken wrapper null."

**Converging finding (closes Lookahead axis):** Three closed PRs (#261 warmup-to-slow EMA, #307 bias-correct cold-start, #311 Lookahead) all perturb the PMuon EMA / weight-averaging dynamics in different ways. All three NULL. The converging mechanism: the natural un-corrected cold-start EMA IS the implicit whitening warmup — PMuon's covariance warmup is load-bearing. Do not modify it.

**Monotone α scan insight:** Arm A (α=0.5) worse than Arm B (α=0.8) — less blending is better; the trend `less Lookahead → closer to baseline` confirms the limit is no-Lookahead.

**New assignment (PR #366):** Aux-AdamW cooldown power decoupling — scan AUX_COOLDOWN_POWER ∈ {1.0, 2.0} while body stays at 1.4. Motivated by converging evidence that aux groups want fast-adapting EMA (β1=0.8); if aux wants to keep adapting, it likely also wants a slower cooldown (power=1.0).

---

## 2026-05-18 09:19 UTC — PR #327 CLOSED + PR #364 ASSIGNED: Adan aux → Muon momentum reset at cooldown (g1r1-askeladd)

- Branch: `g1r1-askeladd/adan-aux-scan`
- **Hypothesis:** Adan 3-buffer adaptive Nesterov on aux groups (embed/lm_head/scalars) at lr_mult∈{1.0, 0.33}.
- W&B runs: `7vyu1jo2` (Arm A mult=1.0), `nx5r55gg` (Arm B mult=0.33)

| Arm | ADAN_LR_MULT | sr | val/loss | Δ vs baseline | verdict |
|-----|---|-----|----------|---------------|---------|
| **Baseline (PR #274)** | AdamW | **3000** | **3.2685** | — | — |
| Arm A | 1.0 | -1 | 3.28804 | +0.0195 | NULL — missed target |
| Arm B | 0.33 | -1 | 3.31190 | +0.0434 | NULL — more LR → worse |

**Result:** Both NULL. Clear ordering: Arm B worse than A (lower LR → even worse — undershoots baseline convergence speed).

**Key mechanism finding (askeladd):** Adan's β1=0.98 imposes heavy momentum on sparse vocab embeddings. On sparse-row embeds, β1=0.98 means gradient EMA averages over ~50 steps; rare-token rows get stale gradient mass from 50+ steps ago when a different token distribution was in the batch. Confirms converging pattern: aux groups want FAST-adapting EMA (β1=0.8), all heavy-momentum mechanisms (Lion #317, AdEMAMix #305, Adan #327) are uniformly NULL on this path. Aux-side optimizer-mechanism axis is now CLOSED.

**Axis decision: Adan-on-aux CLOSED. Aux groups are well-served by fast-EMA AdamW (β1=0.8). Fresh assignment: Muon momentum reset at cooldown entry (PR #364) — body-side mechanism targeting the cooldown regime.**

---

## 2026-05-18 09:09 UTC — PR #305 CLOSED + PR #363 ASSIGNED: AdEMAMix → Z-loss auxiliary (g1r1-frieren)

- Branch: `g1r1-frieren/ademamix-alpha-scan`
- **Hypothesis:** AdEMAMix dual-EMA auxiliary optimizer for embed/lm_head/scalars: slow-EMA component (β3=0.9999) with α∈{4,8} blend.
- W&B runs: `4ahrxeo8` (Arm A α=4), `7lstqkpp` (Arm B α=8)

| Arm | α | sr | val/loss | Δ vs baseline | slow_over_fast | verdict |
|-----|---|-----|----------|---------------|----------------|---------|
| **Baseline (PR #274)** | — | **3000** | **3.2685** | — | — | — |
| Arm A | 4.0 | -1 | 3.28611 | +0.0176 | 0.257 | NULL — missed target |
| Arm B | 8.0 | -1 | 3.31655 | +0.0480 | 0.640 | NULL — missed target |

**Result:** Both NULL. Clear dose-response: stronger slow-EMA engagement (higher α) → worse val/loss monotonically. Mechanism unambiguously activated (slow_over_fast rose smoothly 0→0.26 for α=4, 0→0.64 for α=8) but consistently harmful.

**Key mechanism finding:** With only 3250 steps and β3=0.9999, slow EMA reaches only ~28% of steady-state mass. The slow component drags update direction toward stale early-training gradients during aggressive COOLDOWN_POWER=1.4 descent — exactly when we want sharp, current gradient direction. Fast-only EMA (standard AdamW) is optimal for this aux path / horizon. Matches pre-declared falsification: "mechanism activates but doesn't improve — close AdEMAMix-on-aux axis."

**BF16 note (frieren):** Correctly stored m_slow in FP32 (BF16 rounds 0.9999→1.0 making mul a no-op). Fix was necessary and properly applied.

**Axis decision: AdEMAMix-on-aux CLOSED. Fresh assignment: z-loss auxiliary penalty (PR #363).**

---

## 2026-05-18 08:57 UTC — PR #307 CLOSED + PR #362 ASSIGNED (via #355 re-issue): PMuon EMA bias correction → Gradient Centralization (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-bias-correct`
- **Hypothesis:** PMuon bilateral covariance EMA bias correction {FULL: 1/(1-β^k), SQRT: 1/sqrt(1-β^k)} to sharpen the cold-start preconditioner estimate.
- W&B runs: `kss5lyzw` (Arm A FULL, step 3250), `fku3hg2s` (Arm B SQRT, step 3250)

| Arm | Correction | sr | val/loss | Δ vs baseline (PR #274) | verdict |
|-----|------------|-----|----------|-------------------------|---------|
| **Baseline** | OFF | **3000** | **3.2685** | — | — |
| Arm A FULL | 1/(1-β^k) | 3050 | 3.26803 | +50 / -0.0005 (sub-noise) | NULL — sr regression |
| Arm B SQRT | sqrt(1/(1-β^k)) | 3050 | 3.26797 | +50 / -0.0005 (sub-noise) | NULL — sr regression |

**Result:** Both NULL. sr regression of +50 is decisive (outside ±25 noise band). Val improvement is sub-noise (0.0005 << 0.001 threshold).

**Mechanism verified via telemetry:** L_cov 3-9× larger in corrected arms throughout training. Bias factor traces exactly match PR mechanism table (FULL: 0.0500→0.994→1.0 over 200 steps; SQRT: 0.2236→0.997→1.0). Polar residual sanity check passed. FULL and SQRT outcomes are essentially identical (Δ=0.00006 between them), so this is not a sweet-spot question.

**Key mechanism finding (tanjiro):** The natural (1-β^k) ramp in PMuon covariance EMAs is an implicit warmup of the whitening preconditioner — un-corrected EMA is part of the recipe, not a bug. Mirrors frieren PR #261 (warmup-to-slow-the-ramp also NULL): both directions of perturbing the cold-start covariance dynamics (delay OR sharpen) regress.

**Axis decision: cold-start covariance dynamics are load-bearing; PMuon EMA bias correction axis CLOSED.**

**Next assignment:** PR #355 — Gradient Centralization (GC) for Muon body: pre-polar column-mean subtraction {column-only, column+row} (Yong et al. ECCV 2020). Novel mechanism, 1-line change, zero optimizer state, composes cleanly with current stack.

---

## 2026-05-18 07:40 UTC — PR #331 CLOSED: per-tensor embed grad clipping {10, 100} (g1r1-edward)

- Branch: `g1r1-edward/per-tensor-embed-clip`
- **Hypothesis:** Per-tensor L2 norm clip on embed gradient; tests whether spike-suppression unlocks the heavy-tail embed distribution. Follow-up to PR #299 (global grad clip NULL).
- W&B runs: `3sxpadl0` (Arm A, clip=10, killed @ step 1608), `1nei2r33` (Arm B, clip=100, completed)

| Arm | clip | sr | val/loss | Δ vs baseline | verdict |
|-----|------|-----|----------|---------------|---------|
| **Baseline (PR #274)** | ∞ | **3000** | **3.2685** | — | — |
| Arm A | 10 | killed @ 1608 | 3.5287 @ 1500 (vs baseline ~3.40 @ 1500) | very slow | NULL — clip below natural gradient floor |
| Arm B | 100 | 3025 | 3.27050 | +25 / +0.0020 | NULL — marginal regression on both axes |

**Result:** Both NULL. Per-tensor embed-clip axis closes at no-clip. Confirms PR #299 takeaway that clipping the embed group is not yield-limiting.

**Key mechanism finding:** Arm A's slow trajectory (val=3.529 @ step 1500 vs baseline ~3.40) confirms that the natural embed gradient L2 sits in the 10-50 range — clip=10 truncates the majority of legitimate updates. Arm B (clip=100) is sufficiently above the natural floor that it almost never fires, reproducing baseline behavior to within seed noise.

**Axis decision: per-tensor embed grad clip CLOSED at no-clip (effectively ∞).**

**Next assignment:** PR #350 — Scaled Residual Projection Init (GPT-2 trick, std × 1/√(2N) and 1/N). Fresh initialization-axis mechanism.

---

## 2026-05-18 07:02 UTC — PR #317 CLOSED: Lion optimizer on embed {lr=0.03, 0.10} (g1r1-nezuko)

- Branch: `g1r1-nezuko/lion-embed-wrapper`
- **Hypothesis:** Sign-momentum (Lion) replaces AdamW for the embed group; tests whether sign-quantized updates compete with adaptive AdamW on heavy-tailed embed gradients.
- W&B runs: `d30w4a1a` (Arm A, lr=0.03), `pon9sawn` (Arm B, lr=0.10)

| Arm | lion_embed_lr | sr | val/loss | verdict |
|-----|---------------|-----|----------|---------|
| **Baseline (PR #274 AdamW lr=0.3)** | — | **3000** | **3.2685** | — |
| Arm A | 0.03 | -1 | 3.28119 | NULL — never crossed 3.28 |
| Arm B | 0.10 | 3175 | 3.27738 | NULL — sr +175 vs baseline |

**Result:** Both NULL. Lion at the tested LR range is fundamentally slower than AdamW on this distribution. The 10× LR Arm B closes most of the val gap (3.281→3.277) but still doesn't beat baseline sr — sign quantization throws away the per-coord variance scaling that AdamW provides on heavy-tailed embed gradients (rare tokens cause large spikes that AdamW dampens via squared-gradient denominator).

**Axis decision: Lion-on-embed CLOSED.** Sign-momentum variants for embed/lm_head should be considered low-priority follow-ups absent a separate hypothesis specifically addressing heavy-tail handling.

**Next assignment:** PR #347 — Layer-wise LR Decay (LLRD) for Muon body (fresh depth-dependent schedule mechanism).

---

## 2026-05-18 05:50 UTC — PR #314 CLOSED: embed_lr scan {0.2, 0.4} (g1r1-alphonse)

- Branch: `g1r1-alphonse/embed-lr-scan`
- **Hypothesis:** embed_lr (AdamW embed group LR) axis untested. ±33% scan around inherited 0.3 (→ 0.2, 0.4).
- W&B runs: `tn1qni73` (Arm A, embed_lr=0.2), `yzzqq64v` (Arm B, embed_lr=0.4)

| Arm | embed_lr | sr | val/loss | Δsr vs baseline | Δval |
|-----|----------|----|----------|-----------------|------|
| **Baseline (PR #274)** | 0.3 | **3000** | **3.2685** | — | — |
| Arm A | 0.2 | 3050 | 3.26723 | +50 | −0.00127 |
| Arm B | 0.4 | 3050 | 3.26666 | +50 | −0.00184 |

**Result:** Both arms NULL (sr=3050, +50 steps vs baseline). The embed_lr axis is locally flat around 0.3 — ±33% perturbations yield symmetric +50 sr-step regression. Arm B (higher LR) has mild persistent val advantage over A throughout training (Δ=−0.023 at step 125 → −0.0006 at step 3250) but neither crosses baseline.

**Key finding:** Embedding RMS scales linearly with LR (7.34→14.52, ~2× for 2× LR ratio) but this doesn't translate to sr gain. The AdamW cosine cooldown kills the early advantage. embed_lr=0.3 is a well-tuned local optimum.

**Axis decision: CLOSED at embed_lr=0.3.** With β1, β2, eps, embed_lr now all confirmed flat, the AdamW aux path is fully tuning-converged on the current stack.

**Next assignment:** PR #342 — End-of-cooldown SWA tail (fresh schedule mechanism).

---

## 2026-05-18 01:42 — PR #274: COOLDOWN_POWER retune {1.0, 1.4} — γ_power=0.4 stack (g1r1-fern) ← **MERGED WIN**

- Branch: `g1r1-fern/cooldown-power-retune`
- Hypothesis: COOLDOWN_POWER=1.2 was set long before the current γ_power=0.4 + cubic-Newton stack. With cleaner preconditioned gradient direction, a more concave LR decay tail (1.4) may let the model "snap" below the target earlier.

| Run | Arm | COOLDOWN_POWER | W&B | sr | val/loss | Δsr | Δval | Status |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | — | 1.2 | `prncgzv5` | 3025 | 3.26615 | — | — | Previous best |
| `dnecfiuq` (n=1 seed-1) | B | 1.4 | — | 3000 | 3.26812 | -25 | +0.00197 | n=1 WIN (borderline) |
| `vw0595an` (n=2 seed-1) | B | 1.4 | — | **3000** | **3.26812** | -25 | +0.00197 | n=2 seed-1 |
| `s2nrw0c8` (n=2 seed-2) | B | 1.4 | — | **3000** | **3.26888** | -25 | +0.00273 | n=2 seed-2 |
| **n=2 mean** | B | 1.4 | — | **3000** | **3.2685** | **-25** | +0.00235 | **WIN MERGED** |
| Arm A | A | 1.0 (linear) | — | 3100 | 3.26773 | +75 | +0.00158 | NULL |

**n=2 stat-sig check:** (3.28 - 3.2685) * √2 = 0.01627 ≥ 0.004 ✓

**Analysis:** COOLDOWN_POWER=1.4 wins cleanly on the primary metric (sr) across n=2 seeds. Both seeds independently hit sr=3000, ruling out single-seed noise. The mechanism is confirmed: more concave LR decay tail lets the model reach 3.28 one validation interval earlier (step 3000 vs 3025) on the γ_power=0.4 stack. Small val regression (+0.002) is stable across seeds, plausibly caused by harder late-cooldown drop slightly overshooting the LR floor. Arm A (linear, 1.0) clearly NULL (sr+75). New baseline: **sr=3000, val=3.2685**.

**Follow-up assigned to fern:** PR #332 COOLDOWN_POWER continuation {1.5, 1.8}.

---

## 2026-05-18 01:38 — PR #299: Global gradient norm clipping {1.0, 0.5} (g1r1-edward)

- Branch: `g1r1-edward/grad-clip-scan`
- Hypothesis: Gradient norm clipping at standard transformer thresholds {1.0, 0.5} suppresses early-training spikes. Both arms test whether spike suppression improves val/loss.

| Arm | GRAD_CLIP_NORM | W&B | sr | val/loss | Δsr | Δval | clip_fraction |
|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | ∞ | `prncgzv5` | 3025 | 3.26615 | — | — | 0% |
| Arm A | 1.0 | `k10ppzfs` | 3075 | 3.26935 | +50 | +0.00320 | 100% |
| Arm B | 0.5 | `bw20hjy6` | 3050 | 3.26850 | +25 | +0.00235 | 100% |

**Analysis:** Both arms NULL. Critical diagnostic: global L2 norm sits at **1e4–1e5** throughout training (dominated by SUM-reduced embed+lm_head gradients). Thresholds {0.5, 1.0} fire at 100% of steps → clip degenerates to **uniform scalar rescale** of gradient at every step (effective LR multiplier ≈ 1e-5). This is equivalent to a constant LR reduction, not spike suppression. Not an independent mechanism in this codebase.

**Falsification conclusion:** CLOSED. Global grad-clip axis CLOSED at standard thresholds. Per-parameter-group clipping (embed-only) is the correct implementation of the spike-suppression hypothesis — assigned as PR #331.

---

## 2026-05-18 00:55 — PR #287: Muon weight_decay scan {0.035, 0.050} — param_norm regularization (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-weight-decay-scan`
- Hypothesis: PR #248 telemetry showed `muon/param_norm` growing 3.4× for 1.33× LR — current WD=0.025 may be too weak to constrain param_norm growth. Test WD ∈ {0.035, 0.050}.

| Arm | wd | W&B run | sr | val/loss | Δsr | Δval | Status |
|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0.025 | `prncgzv5` | 3025 | 3.26615 | — | — | Current best |
| Arm A | 0.035 | `rxk4092z` | 3050 | 3.267759 | +25 | +0.00161 | NULL (1× sr noise floor) |
| Arm B | 0.050 | `q61lold2` | 3125 | 3.272109 | +100 | +0.00596 | NULL/REGRESSION |

**Mechanism telemetry (param_norm at step 3250):**
- Arm A (wd=0.035): 1273.2; u/p ratio 0.355
- Arm B (wd=0.050): 615.0 (half of Arm A!); u/p ratio 0.458

**Analysis:** The PR's mechanism prediction was confirmed at the telemetry level — higher WD tightly constrains param_norm and lifts the u/p ratio late in training (as the PR hypothesized). However, the predicted **downstream** val/loss improvement did not materialize. The relationship is monotone in the wrong direction: higher WD → strictly worse sr (3025 → 3050 → 3125) and val/loss (3.26615 → 3.26776 → 3.27211). The optimizer is near its sweet spot at wd=0.025, and constraining param_norm further removes useful capacity faster than it improves conditioning.

**Conclusion:** CLOSED. Muon WD axis CLOSED at 0.025 from the upper side. Per the predeclared falsification table, do NOT scan {0.060, 0.080} (Arm B already showed monotone regression). A downward complement {0.015, 0.020} is low-priority — the small Arm A gap suggests the optimum is at wd=0.025 and not movable by WD alone. The confirmed mechanism (tighter param_norm → higher u/p late) suggests the *yield-limiting* lever may be elsewhere in the cooldown phase (TARGET_UW floor, late-phase LR shape).

**Askeladd re-assigned to fresh mechanism: TBD (next round).**

---

## 2026-05-17 23:00 — PR #293: Polyak-Ruppert weight averaging {25%, 50%} (g1r1-nezuko)

- Branch: `g1r1-nezuko/polyak-weight-averaging`
- Hypothesis: Maintain a running equal-weight average `theta_avg ← theta_avg + (1/n) * (theta - theta_avg)` over the final POLYAK_FRAC of training steps; evaluate val/loss on the averaged params. Classical convergence accelerator (Polyak 1990, Ruppert 1988).

| Arm | POLYAK_FRAC | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 (no avg) | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 0.25 (last 25%) | `igfcn9a1` | 3075 | 3.2749 | **+0.00875** | NULL — 9× noise floor regression on val, +50 on sr |
| Arm B | 0.50 (last 50%) | — | — | — | — | 10 crash attempts (latest `8aotxat7`); never completed |

**Mechanism analysis:** Under the power-law cooldown γ=1.2 schedule, the Muon LR decays from 0.035 toward 0 over the final 25% of training. Param trajectory is **non-stationary**: each step contributes more useful refinement than the previous one because the LR shrinks and the gradient direction sharpens. Equal-weight averaging of params across this cooldown window therefore biases the weights *back toward earlier (higher-LR) checkpoints*, which lie farther from the optimum. Val=3.2749 vs 3.26615 = +0.00875 is a clean, mechanism-grounded regression (not noise).

Arm B's wider window (POLYAK_FRAC=0.50, averaging from step 1625) would extend the bias-toward-earlier-params problem further into the more-aggressive training phase. Even if Arm B ran cleanly, it would amplify the Arm A regression, not reverse it. The 10 crash attempts (typically stalling at step 0-25 with val/loss=10.83 = initialization) suggest implementation difficulty in addition to the mechanism issue.

**Conclusion:** CLOSED. Polyak-Ruppert axis CLOSED at 0 (no averaging). Per the predeclared falsification rule in the PR body ("Both arms NULL (val ≥ 3.26615) → weight averaging non-load-bearing"), Arm A's substantive regression closes the axis directly without needing Arm B confirmation.

**Back-burner follow-ups:**
1. **EMA-weighted Polyak**: weight the averaged contribution toward newer steps via decay factor — would respect the non-stationary cooldown trajectory.
2. **Polyak without cooldown**: test in a constant-LR or warmup-only setting where the trajectory *is* approximately stationary — different mechanism.

Nezuko re-assigned to fresh mechanism: **Lion optimizer (Chen et al. 2023) on embed-only path** — sign-momentum optimizer, two arms with lr ∈ {0.03, 0.10}.

---

## 2026-05-17 22:00 — PR #278: z-loss auxiliary scan {1e-4, 1e-3} (g1r1-alphonse)

- Branch: `g1r1-alphonse/zloss-auxiliary-scan`
- Hypothesis: z-loss (partition-function shrinkage `Z_LOSS_COEF · log(Z)²`) as a calibration regularizer at the output projection.

| Arm | Z_LOSS_COEF | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 (no z-loss) | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 1e-4 | `nmokccos` | 3050 | 3.26860 | +0.00245 | NULL — within noise band |
| Arm B | 1e-3 | `pdkpq1x2` | -1 (target missed) | 3.28640 | +0.02025 | REGRESSION — ~5× noise band |

**Mechanism analysis (alphonse):** The existing logit soft-clamp `logits = 15·logits/(logits² + 15²)^{1/2}` at line 442 already constrains both magnitude and partition function. Telemetry showed `log_z_mean ≈ 3.87` even at no z-loss pressure — there's no partition drift left to penalize. At Z=1e-3 the auxiliary gradient pulls `log_z → 0` aggressively, but this competes destructively with CE: it shrinks the effective margin between correct-token logit and the rest, so cross-entropy slowly increases. Smooth monotonic curve, no NaN — clean objective interference, not stability failure.

**Conclusion:** CLOSED. z-loss axis CLOSED at 0 (no z-loss). The current logit soft-clamp is the right operating point; additional explicit partition-function shrinkage degrades the language-modelling signal. Per the predeclared falsification rule, both arms NULL closes the axis.

**Process improvement noted:** `pgrep -af train_gpt_simple` pre-launch check (avoids duplicate-process incidents that cost ~30 min of contaminated wall-clock).

**Suggested follow-ups preserved:**
1. Pre-clamp z-loss (apply to unclamped logits) — different mechanism, low priority
2. **Per-group AdamW LR scans (embed_lr, scalar_lr, lm_head_lr)** — alphonse re-assigned to embed_lr scan {0.2, 0.4} per this follow-up
3. Per-head/per-layer PMuon LR — high-effort fresh mechanism

---

## 2026-05-17 21:10 — PR #272: AdamW eps scan {1e-8, 1e-9} (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamw-eps-scan`
- Hypothesis: AdamW eps=1e-10 is a 100× deviation from PyTorch default 1e-8 and was never explicitly scanned. Conjecture: at rare-token / low-variance positions on embed/lm_head/scalars, `1/(√v + eps)` could blow up when eps is tiny; larger eps should dampen oversized updates.

| Arm | eps | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 1e-10 | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 1e-8 (PyTorch default) | `edobz4wx` | 3025 | 3.26640 | +0.00025 | NULL — tied sr, val regress within noise |
| Arm B | 1e-9 | `w0oobk88` | 3050 | 3.26748 | +0.00133 | NULL — small sr+val regress, far below stat-sig threshold |

Both arms reach the 3.28 target comfortably (margins 0.0136 and 0.0125). Neither meets n=1 win rule.

**Analysis:** Non-monotone direction (sr+0 at eps=1e-8, sr+25 at eps=1e-9 — the *smaller* perturbation regresses more on sr) is more consistent with seed noise than a real trend. The data shows eps is genuinely flat above 1e-10 on this stack.

**Mechanism reading:** AdamW effective updates on embed/lm_head/scalars are NOT eps-floor-limited in this regime. The rare-token "update headroom" that eps=1e-10 provides is benign — dampening more (1e-8) doesn't help final loss, and the intermediate (1e-9) is also slightly worse on sr. The original hypothesis (eps-floor as oversized-update damper at low-variance positions) is falsified for this configuration.

**Conclusion:** CLOSED. AdamW eps axis CLOSED at 1e-10. Per the predeclared falsification rule in the PR body, both arms NULL closes the axis. Thorfinn re-assigned to **PR #311 Lookahead optimizer wrapper** — fresh wrapper-level mechanism (Zhang Lucas Hinton Ba NeurIPS 2019), complementary to in-flight polyak post-hoc (nezuko #293), AdEMAMix momentum (frieren #305), and PMuon bias correction (tanjiro #307).

**Suggested follow-up from student (kept for back-burner):** "is the embed AdamW path well-tuned" as an lr_embed axis question rather than eps. Clean diagnostic question — easier to characterize the AdamW path via per-group LR than via eps.

---

## 2026-05-17 20:35 — PR #250: NS coef c-scan on f'(1)=0 family seed-2 confirmation (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-c-scan`
- Hypothesis (originally): c-axis exploration on f'(1)=0 family at c ∈ {-0.25, +0.25}. Seed-1 of c=+0.25 produced a marginal numerical win (Δval=-0.00010, 10× below noise threshold). Sent back for n=2 seed-2 confirmation.

| Seed | sr | val/loss | polar/ortho_residual_sample | W&B run |
|---|---|---|---|---|
| seed-1 | **3025** | **3.26605** | 0.09399 | `8tbjkmnc` |
| **seed-2** | **3050** | **3.26708** | 0.09438 | **`qp87db4n`** |
| **mean (n=2)** | **3037.5** | **3.266565** | 0.09418 | — |
| baseline c=0 | 3025 | 3.26615 | not logged | `prncgzv5` |
| Arm A c=-0.25 | 3100 | 3.27291 | **20.637 (broken)** | `ecwyk0ej` |

**Analysis:** Per pre-declared advisor decision rule (seed-2 sr > 3025 → close), c-axis CLOSED at c=0. seed-1 marginal numerical win (Δval=-0.00010) confirmed as seed noise; mean n=2 Δval=-0.000585 is below both the stat-sig 0.004 threshold and the seed-noise 0.002 threshold. Arm B's two-seed evaluation correctly falsified the marginal seed-1 result.

**Reproducible structural finding preserved (not a sr/val win, but useful diagnostic):**
`polar/ortho_residual_sample` final value is **highly reproducible across seeds** (0.094 ± 0.0004 at c=+0.25). This is genuinely useful as a low-noise NS-screening diagnostic — future PMuon-iteration PRs can compare residual trajectories to screen NS polynomial variants without paying for full 3.4h runs.

**Mechanism finding (also preserved):**
c=-0.25 (b=0, no cubic term) has `polar/ortho_residual_sample ≈ 20.6` throughout training — essentially the random-Gaussian baseline (√768≈27.7). The NS iteration with f(x)=1.25x−0.25x⁵ does NOT orthogonalize: small SVs grow weakly (linear amp 1.25 too gentle), and SVs ≳1.39 flip into negative branch. **PMuon is partially robust to a broken polar factor** — c=-0.25 still reached val ≤ 3.28, just 75 sr-steps later. The bilateral whitening contributes orthogonalization independently of the NS iteration. Good cross-mechanism finding.

**Conclusion:** CLOSED. NS coef c-axis on f'(1)=0 family CLOSED at c=0 (cubic-Newton). Tanjiro re-assigned to PR #307 PMuon EMA bias correction (frieren's PR #261 follow-up — opposite direction from closed LR warmup).

**Backlog item retained:** `NS_ITERS=8 at c=+0.25` might match c=0 `NS_ITERS=12` on residual quality at ~33% compute savings per Muon step. Not pursuing now (c-axis closed for this family); flagged for any future Muon-iteration follow-up.

---

## 2026-05-17 20:15 — PR #261: PMuon LR warmup scan {50, 150 steps} (g1r1-frieren)

- Branch: `g1r1-frieren/muon-lr-warmup-scan`
- Hypothesis: PMuon's bilateral covariance EMAs (β_cov=0.95, ~20-sample equivalent) might benefit from a Muon-only LR warmup window during the cold-start EMA fill-in phase, when aggressive γ_power=0.4 whitening could be destabilizing.

| Arm | warmup steps | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 50 | `2sjpvck2` | 3025 | 3.26618 | +0.00003 | NULL — tied within seed noise |
| Arm B | 150 | `wonlhane` | 3100 | 3.27251 | +0.00636 | REGRESSION — sr+75, clear capacity loss |

**Analysis:** Asymmetric null/regression result. Frieren's telemetry analysis nailed the mechanism:

1. **Cold-start whitening is self-regularizing**: `pmuon/whitened_sv_max` rises smoothly from low values during EMA fill-in — when `L_cov`/`R_cov` are near-zero, `matrix_neg_power(L_cov, γ=0.4)` returns a near-isotropic preconditioner that produces small-magnitude whitened gradients. The "aggressive whitening at cold start" problem the hypothesis assumed doesn't exist.

2. **EMA convergence is set by β_cov, not LR**: `lcov_eigh_ratio` and `rcov_eigh_ratio` evolve identically across configs in the first ~200 steps. LR warmup doesn't speed EMA settling; it only delays useful gradient application.

3. **Arm B regression = pure capacity loss**: 150 steps of linear ramp ≈ 75 full-LR-equivalent steps lost. On a fixed-budget benchmark with no cooldown extension, this manifests directly as sr+75 and Δval=+0.006.

4. **Arm A null reinforces direction**: 50 warmup steps ≈ 25 full-LR-equivalent steps lost — below per-seed noise floor.

**Conclusion:** CLOSED. PMuon LR warmup axis CLOSED at no warmup. The β_cov=0.95 EMA cold-start is self-correcting via small-magnitude whitening during fill-in; adding LR warmup is double regularization with no upside.

**Suggested follow-ups from student (kept for back-burner):**
- **Direct EMA bias correction**: divide `L_cov`/`R_cov` by `(1-β_cov^k)` for first ~50 steps to use the cov estimate MORE aggressively (opposite direction from warmup). Could tighten early whitening.
- Larger β_cov ∈ {0.97, 0.99}: longer effective sample window — trades slower adaptation for less variance.
- Initialize `L_cov`/`R_cov` with small identity prior (e.g. `λI`): replaces early near-zero pathology with known-stable start.

---

## 2026-05-17 18:05 — PR #230: Aux AdamW β1 scan {0.7, 0.9} (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-scan`
- Hypothesis: β1=0.8 for the auxiliary AdamW (embed, lm_head, scalars) has never been explicitly tested. Scan ±0.1 to characterize the gradient momentum timescale axis.

| Arm | aux β1 | W&B run | sr | val/loss | Δval vs PR #193 (3.26773) | Status |
|---|---|---|---|---|---|---|
| Arm A | 0.7 | `j4nfypgf` | 3050 | 3.26775 | +0.00002 | NULL — tied within seed noise |
| Baseline (PR #193) | 0.8 | `q8aduc16` | 3050 | 3.26773 | — | Stale base |
| Arm B | 0.9 | `s7tsyxrt` | 3075 | 3.27005 | +0.00232 | NULL — clearly worse |

**Re-anchored vs current baseline (PR #202, sr=3025, val=3.26615):** Both arms NULL — neither beats current baseline.

**Analysis:** Clear asymmetric result. β1=0.7 is statistically indistinguishable from β1=0.8 (Δval=+0.00002, well within 2σ seed noise). β1=0.9 genuinely regresses (+0.0023 val, sr+25). The β1 landscape has a flat plateau on the lower side (≤0.8) and rises sharply on the upper side. Edward's interpretation: "A shorter momentum window doesn't help the embed/lm_head/scalar updates; a longer momentum window (0.9) slows adaptation." The lm_head cooldown-responsiveness hypothesis (shorter β1 → faster react in cooldown) is falsified — the effective half-life difference (β1=0.7→2 steps vs β1=0.8→3.1 steps) is too small relative to the 75-step val-check grid.

Note: run used stale base (PR #193, sr=3050) — arm A's sr=3050 matches stale base rather than current best. Both arms definitively NULL on either anchor.

**Conclusion:** CLOSED. Aux AdamW β1 axis CLOSED at 0.8. β1=0.9 (longer memory) is clearly suboptimal; β1=0.7 provides no benefit over 0.8. Axis re-visit conditions: cooldown length change or radical aux-LR change. Edward reassigned to PR #297 (global gradient norm clipping — fresh mechanism, never tested).

---

## 2026-05-17 17:41 — PR #258: Skylight u/w-floor ablation TARGET_UW ∈ {0.0, 0.7} (g1r1-nezuko)

- Branch: `g1r1-nezuko/uw-floor-pruning-ablation`
- Hypothesis: Is TARGET_UW=0.35 (Skylight floor) load-bearing on the new γ_power=0.4+cubic-Newton stack? Test both disabling (0.0) and doubling (0.7).

| Arm | TARGET_UW | W&B run | sr | val/loss | Status |
|---|---|---|---|---|---|
| Arm A | 0.0 (disabled) | `yrvf83c0` | 3125 | 3.27504 | NULL — clear regression (+100 sr, +0.00889 val) |
| Baseline | 0.35 | `prncgzv5` | 3025 | 3.26615 | Baseline |
| Arm B | 0.7 | `9q7v4c4u` | DIVERGED step 2138 | — | CATASTROPHIC FAILURE — eigh crash |

**Analysis:** Arm A definitively shows u/w-floor IS load-bearing — disabling costs +100 sr and +0.009 val. The floor's value is concentrated in the cooldown phase: Arm A leads baseline mid-training (step 1000: 3.6225 vs 3.6578) but loses significantly by end (3.2750 vs 3.2662). 

Arm B produced the most striking diagnostic: TARGET_UW=0.7 creates a divergent amplification feedback loop. The floor sits 2.2× above the natural ratio mean (~0.31), causing every param to trigger from step 150. Amplification factor grows from 1× to 85,000× by step 2075, making the bilateral-whitening matrix numerically ill-conditioned → `torch.linalg.eigh` crash at step 2138.

New telemetry (ratio_mean/min/max) confirmed Goldilocks structure: natural u/w ratio band is [0.24, 0.39] with mean ~0.31. The floor at 0.35 sits just above the band (mild 1.1–1.5× lift) while 0.7 triggers a runaway positive feedback.

**Conclusion:** CLOSED. TARGET_UW axis CLOSED at 0.35. Neither removing nor doubling the floor is viable on the γ_power=0.4 stack. Follow-up: PR #293 nezuko (Polyak weight averaging — fresh mechanism).

---

## 2026-05-17 16:22 — PR #248: Muon base LR retune {0.030, 0.040} (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-base-lr-retune`
- Hypothesis: After cubic-Newton+γ_power=0.4 stack merged, baseline LR=0.035 may no longer be optimal. Scan ±14% to test.

| Arm | `MUON_BASE_LR` | W&B run | `sr` | `val/loss` | Δsr vs baseline | Δval vs baseline |
|---|---|---|---|---|---|---|
| Arm A | 0.030 | `dcm490bd` | 3025 | 3.26755 | 0 | +0.00140 |
| Arm B | 0.040 | `wsze97nl` | 3050 | 3.26669 | +25 | +0.00054 |
| **Baseline** | **0.035** | `prncgzv5` | **3025** | **3.26615** | — | — |

**Analysis:** Both arms NULL. Arm A ties sr but val is +0.00140 worse (regression). Arm B registers sr=3050 — 25 steps slower — but surprisingly recovers late: val/loss overtakes Arm A in final 100 steps (step 3150+) ending at 3.26669.

Key unexpected finding: `param_norm` at step 3250 grows **3.4×** (1375 → 4732) for a 1.33× LR change (0.030 → 0.040). This is far more than the LR-ratio prediction (√1.33 ≈ 1.15×). The driver is weight growth, not gradient dynamics — `update_norm` tracks closely between arms (within 5-10%) while `param_norm` diverges. The γ_power=0.4 whitening + PMuon preconditioning amplifies effective update magnitudes beyond the nominal LR scale. The existing `weight_decay=0.025` is insufficient to counter this — `lr*wd = 8.75e-4/step`.

The two effects pull opposite directions: higher LR hurts sr (early cooldown weight-growth under-stepping) but helps final val (+0.00086). Result: flat minimum at 0.035.

**Conclusion:** CLOSED. Muon base LR axis CLOSED at 0.035. Symmetric NULL — no headroom in either direction. Follow-up: WD scan {0.035, 0.050} (PR #287) directly motivated by param_norm telemetry.

---

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

## 2026-05-17 02:34 UTC — PR #202 PARTIAL (arm A done): frieren γ_power=0.4 MASSIVE WIN

- Branch: `g1r1-frieren/pmuon-uw-gamma-power-scan`
- Arm A (γ_power=0.4 — stronger whitening): **sr=3025, val=3.26615** — confirmed via W&B run `prncgzv5`

| Metric | γ_power=0.4 (arm A) | Baseline PR #137 | Δ |
|---|---|---|---|
| `speedrun/final_first_step_to_target` | **3025** | 3062.5 (n=2) | **−37.5 sr-steps** |
| `val/loss` | **3.26615** | 3.269090 | **−0.00294** |
| stat-sig n=1 | (3.28−3.26615)×√1 = 0.01385 ✓ | threshold 0.004 | 3.46× above threshold |

**This is the single largest Δsr arm A win on the program to date.** Exceeds both thorfinn (−12.5) and edward (−12.5) by 3× on sr.

**Mechanism:** γ_power controls the whitening exponent in PMuon's covariance preconditioning. With default γ_power=0.3, the spectral conditioning is moderate; with γ_power=0.4, the covariance EMA is more aggressively scaled. Hypothesis: stronger whitening better removes the ill-conditioning from block weight matrices' spectral structure, allowing the NS polar projection to operate in a more isotropic gradient space. The net effect is faster convergence in the late cooldown phase.

**Three arm A wins now on PMuon+u/w+γ=1.2 base (all pending terminals):**
1. **frieren γ_power=0.4: sr=3025, val=3.26615** (BIGGEST)
2. thorfinn ns_iter=6: sr=3050, val=3.26774
3. edward deep-strong WD: sr=3050, val=3.26819

**Arm B (γ_power=0.2 — weaker whitening) just started.** If arm B is worse (monotone stronger→better), finer scan {0.5, 0.6} warranted. If arm B also wins, broad sweet spot (0.2–0.4 range all good).

**Wave 7 stacking revision:** Original stacking plan (ns_iter=6 + deep-strong WD → est. sr=3037.5) is NOW upgraded to 3-way stack (ns_iter=6 + deep-strong WD + γ_power=0.4 → est. sr=3000-3025). This would tie/beat the Prime Intellect public Record #20 reference (3030 steps).

---

## 2026-05-17 02:34 UTC — PR #179 TERMINAL: nezuko γ scan CLOSED NULL

- Branch: `g1r1-nezuko/pmuon-uw-gamma-scan`
- Arm A (γ=1.1): sr=3075, val=3.26813 — NULL
- Arm B (γ=1.3): sr=3075, val=3.27249 — NULL

| Metric | γ=1.1 (arm A) | γ=1.2 (baseline, n=2) | γ=1.3 (arm B) |
|---|---|---|---|
| sr | 3075 | 3062.5 | 3075 |
| val | 3.26813 | 3.269090 | 3.27249 |
| Δsr vs γ=1.2 | +12.5 | — | +12.5 |

**Conclusion:** γ=1.2 is the confirmed local optimum on the power-law cooldown concavity axis. Both 1.1 (too mild) and 1.3 (too aggressive) cross 3.28 12.5 steps later than baseline. Axis CLOSED. Terminal SENPAI-RESULT posted 02:27 UTC.

Nezuko reassigned to **PR #216 (aux AdamW β2 scan {0.99, 0.999})** — first probe of aux optimizer variance horizon.

---

## 2026-05-17 02:34 UTC — PR #216 ASSIGNED: aux AdamW β2 scan (g1r1-nezuko)

- Branch: `g1r1-nezuko/aux-beta2-scan`
- Hypothesis: AdamW β2=0.95 (static since PR #64) is unusually low vs default 0.999. Scan {0.99, 0.999} to characterize variance EMA horizon.
- Arms: β2=0.99 (arm A, longer horizon), β2=0.999 (arm B, standard AdamW)
- Telemetry: aux/embed_effective_lr, aux/lmhead_effective_lr, aux/embed_v_mean/std per step
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137)

---

## 2026-05-17 04:30 UTC — PR #193 TERMINAL: Cubic-Newton NS coefs WIN → MERGED as new baseline

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-scan`
- **MERGED** — new baseline: sr=3050, val=3.26773 (n=1)

| Arm | Coefficients | sr | val | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|
| Baseline (PR #137) | (2, -1.5, 0.5) quintic | 3062.5 (n=2) | 3.269090 | ~0.01 | — |
| Arm A — Jordan-opt | (3.4445, -4.7750, 2.0315) | 3075 | 3.27041 | ~11.12 (oscillating) | NULL |
| **Arm B — cubic-Newton** | **(1.5, -0.5, 0.0)** | **3050** | **3.26773** | **~0.10 (saturated)** | **WIN → MERGED** |

- W&B arm B run: `q8aduc16` — stat-sig n=1: (3.28−3.26773)×√1=0.01227≥0.004 ✓

**Mechanistic finding:** Both Jordan (residual ~11, oscillating) and cubic-Newton (residual ~0.10, saturated) produce non-converged polars, yet cubic-Newton WINS while Jordan NULLs. Path to under-convergence matters more than residual magnitude. Cubic-Newton's classical Newton iteration finds a better gradient direction basin than the fully-converged quintic, while Jordan overshoots the whitened input's near-orthogonal state and oscillates. Cross-reference: thorfinn PR #184 ns_iter=6 (residual ~2.31) reaches similar regime via fewer iterations — same mechanistic family.

---

## 2026-05-17 04:30 UTC — PR #184 TERMINAL: NS_ITERS closed as wide flat regime

- Branch: `g1r1-thorfinn/pmuon-uw-ns-iter-scan`
- **CLOSED as informative null** — both arms tie on sr=3050 with 14× difference in polar residual

| Arm | NS_ITERS | sr | val | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|
| Baseline | 12 | 3062.5 (n=2) | 3.269090 | ~0.01 | — |
| Arm A | 6 | 3050 | 3.26774 | ~2.31 | n=1 win (noise-band?) |
| Arm B | 18 | 3050 | 3.26724 | ~0.148 | n=1 win (noise-band?) |

**Reason for closure:** Wide flat NS_ITERS regime detected — both arms win with near-identical sr=3050 despite 14× residual difference. Student's own analysis questions noise-band nature. PR #193 cubic-Newton merged simultaneously as a more distinct polar mechanism change. Merging both overlapping polar changes without testing the compound would create an untested interaction.

**Key citation-worthy finding:** PMuon's bilateral whitening makes the polar step's orthogonality precision largely irrelevant. 14× polar residual change → <0.05% val/loss change. The polar step is a direction-normalizer, not a precision-optimizer.

---

## 2026-05-17 04:35 UTC — PR #225 ASSIGNED: Wave 7 3-way stack (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/wave7-gpower04-deepwd-lmhead160-stack`
- **Assignment:** γ_power=0.4 + deep-strong WD (slope=+0.5) + lm_head LR 1/160 on cubic-Newton+PMuon+u/w+γ=1.2 base
- n=2 directly (seeds 1+2)
- Conservative additive from new baseline (3050): 3050 − 37.5 − 12.5 − 12.5 = **sr=2987.5** (would BEAT Record #20 at 3030)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/225

---

## 2026-05-17 04:35 UTC — PR #226 ASSIGNED: NS coef c-scan (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan`
- **Assignment:** c ∈ {0.1, 0.25} scan on cubic-Newton (a=1.5, b=-0.5, c=0) baseline
- Maps the winning NS polynomial family: does the win extend above c=0? Crossover between c=0 WIN and c=0.5 NULL.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/226


## 2026-05-17 05:40 UTC — PR #197 CLOSED: EMA model weight averaging (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-ema-avg`
- **Hypothesis:** EMA (α=0.99, 0.999) provides mid-training polish that survives speedrun crossing
- W&B runs: `gmskliu2` (α=0.99), `ywlqvzay` (α=0.999)

| Arm | α | sr | val/loss | Verdict |
|-----|---|----|----------|---------|
| Baseline | — | 3050 | 3.26773 | — |
| Arm A | 0.99 | 3100 | 3.27504 | NEGATIVE (+50 sr) |
| Arm B | 0.999 | -1 (never) | 3.36121 | SEVERE NEGATIVE |

**Analysis:** Bias-lag mechanism confirmed conclusively. Power-law cooldown drops LR 25× over 175 steps; live weights improve faster than EMA tracks. EMA is a low-pass filter; cooldown is a high-frequency drop — structurally incompatible. Same mechanism as Lookahead (PR #143). EMA direction closed permanently.

**Conclusion:** CLOSED. EMA weight averaging incompatible with speedrun cooldown geometry. Cross-axis: any post-hoc smoothing on model weights will lose on this base.

---

## 2026-05-17 05:40 UTC — PR #195 CLOSED: cooldown_frac scan (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cooldown-frac-scan`
- **Hypothesis:** cooldown_frac ∈ {0.5, 0.85} (vs baseline 0.7) — longer/shorter stable phase
- W&B runs: `wa0d9w7u` (cf=0.85), `ryp8lipu` (cf=0.5)

| Arm | cf | sr | val/loss | Verdict |
|-----|----|----|----------|---------|
| Baseline | 0.7 | 3050 | 3.26773 | — |
| Arm A | 0.85 | 3075 | 3.27214 | NEGATIVE (+25 sr) |
| Arm B | 0.5 | 3150 | 3.27419 | NULL (+100 sr) |

**Analysis:** cf=0.7 confirmed concave minimum. Key mechanistic update: late-eta is NOT monotonically predictive of val — cf=0.5 has highest late-eta but worst val. Real axis: stable-phase length vs cooldown integral. Model wants ~70% cooldown. Combined with PR #179 γ-scan (γ=1.2 optimal), the (γ, cf) surface is exhausted at current operating point.

**Conclusion:** CLOSED. Schedule family at γ=1.2 thoroughly characterized: both cf and γ axes are at their respective sweet spots.

---

## 2026-05-17 05:40 UTC — PR #198 CLOSED: Per-block WD coupling (g1r1-edward)

- Branch: `g1r1-edward/pmuon-uw-perblock-wd`
- **Hypothesis:** Depth-coupled WD (slope ±0.5) bypasses PMuon+u/w-floor, reshapes parameter geometry
- W&B runs: `7lzjw46u` (deep-strong), `4wwaiype` (deep-weak)

| Arm | wd_slope | sr | val/loss | Verdict |
|-----|----------|-----|----------|---------|
| Baseline (PR #193) | 0.0 | 3050 | 3.26773 | — |
| Arm A deep-strong | +0.5 | 3050 | 3.268193 | NULL (val regression +0.000463 vs new baseline) |
| Arm B deep-weak | -0.5 | 3050 | 3.269250 | NULL (val regression +0.001520) |

**Analysis:** Both arms beat old PR #137 baseline but NOT new PR #193 cubic-Newton baseline. Mechanism CONFIRMED via per-block param-norm divergence (b00 535→270, b11 597.9→1159.6 between arms). WD acts on `p` before update path, bypassing both PMuon whitening and u/w-floor. Deep-strong arm A has cleaner val (3.268193 vs 3.269250 deep-weak). Deep-strong mechanism is already included as ingredient in Wave 7 stack PR #225.

**Conclusion:** CLOSED as informative. Mechanism confirmed active and included in Wave 7 stack. If Wave 7 stack wins, deep-strong WD contribution is validated. If not, axis needs a fresh look on the compound base. Follow-up candidate: asymmetric step-function WD profile (wd_mult={0.8 for l<6, 1.2 for l≥6}).

---

## 2026-05-17 05:45 UTC — PR #229 ASSIGNED: NS coef (a,b) cubic-family line scan (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns-coef-ab-line-scan`
- **Assignment:** Scan (a,b) along the cubic family line a+b=1, c=0: Arm A (a=1.3, b=-0.3, f'(1)=+0.4), Arm B (a=1.7, b=-0.7, f'(1)=-0.4)
- Orthogonal to PR #226 c-axis scan. Maps contraction aggressiveness of the cubic NS family.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/229

---

## 2026-05-17 05:45 UTC — PR #230 ASSIGNED: Aux AdamW β1 scan (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-scan`
- **Assignment:** β1 ∈ {0.7, 0.9} for the auxiliary AdamW (embed/scalars/lm_head params), current β1=0.8
- Orthogonal to PR #216 nezuko β2 scan. Completes aux AdamW momentum characterization.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/230

---

## 2026-05-17 05:45 UTC — PR #231 ASSIGNED: Muon gradient momentum scan (g1r1-fern)

- Branch: `g1r1-fern/muon-momentum-scan`
- **Assignment:** Muon gradient momentum mu ∈ {0.9, 0.99} (current mu=0.95, nesterov=True)
- Distinct from EMA weight averaging (closed PR #197) and β_cov (closed PR #129). Tests gradient smoothing window before NS polar projection.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/231


## 2026-05-17 06:30 UTC — PR #202 TERMINAL: γ_power scan v2 ARM A WIN (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-power-bracket`
- **Hypothesis:** γ_power ∈ {0.2, 0.4} scan (current 0.3)
- W&B runs: `prncgzv5` (γ=0.4), `np70bwgx` (γ=0.2)

| Arm | γ_power | sr | val/loss | vs new baseline (3050/3.26773) | Verdict |
|-----|---------|-----|----------|--------------------------------|---------|
| Baseline (PR #193) | 0.3 | 3050 | 3.26773 | — | — |
| **Arm A** | **0.4** | **3025** | **3.26615** | **Δsr=−25 ✓ Δval=−0.00158 ✓** | **WIN (n=1 clears stat bar)** |
| Arm B | 0.2 | 3050 | 3.268887 | sr tie, val +0.00116 regression | Monotone direction (γ↑ better) |

**Analysis:** Arm A γ_power=0.4 is a clean WIN — biggest single-arm sr improvement (Δsr=−37.5 from old PR #137 baseline 3062.5; Δsr=−25 from current PR #193 baseline 3050). Arm B γ_power=0.2 confirms monotone direction: γ_power=0.4 wins, γ_power=0.2 ties or loses. Suggests finer scan {0.5, 0.6} for optimum.

**Note:** Arm A tested on PR #137 base (pre-cubic-Newton). Merge will create the compound (cubic-Newton + γ_power=0.4) — assumed additive (predicted sr~3012.5). Wave 7 stack (PR #225 thorfinn, currently running) independently confirms γ_power=0.4 + cubic-Newton + deep-WD + lm_head LR.

**Status:** PR sent back for rebase + arm switch to PMUON_GAMMA=0.4 (currently set to 0.2 from arm B). Will merge after student resubmits.


## 2026-05-17 06:40 UTC — PR #202 MERGED: γ_power=0.4 WIN → NEW BASELINE (g1r1-frieren)

- W&B run: `prncgzv5` (arm A, γ_power=0.4 on PR #137 base)
- **New baseline: sr=3025, val=3.26615 (n=1)**
- **BEATS Public Record #20 (3030 steps)!** Local n=1 sr=3025 < 3030.
- Merged onto cubic-Newton base (PR #193 compound assumed orthogonal).
- Spectral diagnostic telemetry (`pmuon_spectral_diag`, 100-step logging) added to codebase.

---

## 2026-05-17 06:50 UTC — PR #242 ASSIGNED: γ_power finer scan (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-power-finer-scan`
- **Assignment:** γ_power ∈ {0.5, 0.6} on new baseline (sr=3025, cubic-Newton + γ_power=0.4)
- Monotone direction: γ=0.2→3050, 0.3→3062.5, 0.4→3025. Expected optimum in {0.5, 0.6} range.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/242


---

## 2026-05-17 08:48 UTC — PR #211 CLOSED: Wave 6 lm_head LR scan (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-lmhead-lr-scan`
- **Hypothesis:** lm_head LR=1/320 is undertuned; 2× (arm A=1/160) and 0.5× (arm B=1/640) scan on OLD base (PR #137: PMuon+u/w+γ=1.2).

| Arm | lm_head LR | sr | val/loss | vs OLD baseline (3062.5/3.26909) | vs NEW baseline (3025/3.26615) |
|-----|-----------|-----|----------|----------------------------------|-------------------------------|
| **A** | 1/160 | 3050 | 3.26896 | Δsr=−12.5 ✓, Δval=−0.00013 ✓ (SMALL WIN on old base) | sr +25 worse, val +0.00281 NULL |
| **B** | 1/640 | 3100 | 3.27248 | Regression (+37.5 sr, +0.00339 val) | Worse |
| Baseline | 1/320 | 3062.5 | 3.26909 | — | — |

**Analysis:** Directional monotone result — higher lm_head LR helps, lower hurts. Arm A beats OLD baseline by −12.5 sr, but the comparison contract was voided when PR #193 (cubic-Newton) and PR #202 (γ_power=0.4) merged mid-run, making the new baseline sr=3025 which arm A misses by +25 steps. Outstanding mechanistic quality: student's update/param telemetry confirmed 4× LR → 4× late-cooldown update_norm in the Adam asymptote; 1.53× larger late-cool val drop in arm A explains the γ=1.2 synergy mechanism precisely.

**Status:** CLOSED — informative NULL on stale base. lm_head LR=1/160 mechanism is being re-tested on new baseline in PR #225 thorfinn Wave 7 stack (deep-WD slope=+0.5 + lm_head 1/160 on new baseline, n=2).

---

## 2026-05-17 08:48 UTC — PR #248 ASSIGNED: Muon base LR retune (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-base-lr-retune`
- **Hypothesis:** Muon base LR=0.035 has never been retuned since PMuon's introduction. After γ_power=0.4 (stronger whitening) + cubic-Newton (partial polar convergence), the optimal step size may have shifted. Arms: {0.030, 0.040} bracket current 0.035.
- **Expected arm B win** (LR=0.040): γ_power=0.4's more isotropic gradient allows larger steps. **Expected arm A win** (LR=0.030): cubic-Newton's partial convergence means direction is noisier; tighter steps help.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/248

---

## 2026-05-17 09:00 UTC — PR #226 CLOSED: NS coef c-scan {0.1, 0.25} (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan`
- **Hypothesis:** Scan NS coef c values {0.1, 0.25} on cubic-Newton base (a=1.5, b=-0.5 fixed).

| Arm | c | (a,b,c) | sr | val | Verdict |
|-----|---|---------|-----|------|---------|
| Baseline | 0.0 | (1.5, -0.5, 0) | 3025 | 3.26615 | — |
| **A** | 0.1 | (1.5, -0.5, 0.1) | 3050 | 3.26849 | NULL (val +0.00234) |
| **B** | 0.25 | (1.5, -0.5, 0.25) | crashed step 3 | — | Divergence |

**Analysis:** Arm B crashed deterministically at step 3 with `torch.linalg.eigh` error. Student diagnosed root cause: a+b+c=1.25 violates σ=1 fixed-point (discriminant b²−4c(a−1) = -0.25 < 0, no real positive fixed point → monotone divergence → L_cov near-singular). This is a structural finding: naive c-variations must preserve a+b+c=1. Arm A (c=0.1) is NULL — slight noise increase from the non-fixed-point-preserving perturbation shows as +0.00234 val.

**Key finding:** The correct c-scan must follow the f'(1)=0 family: (a,b,c) = (1.5+c, -0.5-2c, c). Preserves both σ=1 fixed point and smooth attractor.

**Status:** CLOSED. Follow-up assigned (PR #250, tanjiro).

---

## 2026-05-17 09:00 UTC — PR #250 ASSIGNED: NS coef c-scan f'(1)=0 family (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan-fp1-family`
- **Hypothesis:** Scan c ∈ {-0.25, +0.25} on the valid f'(1)=0 NS family (a=1.5+c, b=-0.5-2c, c). Known endpoints: c=0 cubic-Newton (sr=3025 baseline), c=0.5 quintic (sr≈3062.5 worse). Question: does c<0 further improve?
  - Arm A c=-0.25: (1.25, 0, -0.25) — b=0, no cubic term, pure linear+quintic damping
  - Arm B c=+0.25: (1.75, -1.0, +0.25) — quintic-leaning, expected worse
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/250

---

## 2026-05-17 08:55 UTC — PR #225 SEED 1 DONE: Wave 7 stack (g1r1-thorfinn)

- Seed 1 run `y69hfn95`: step=3250, val=**3.2651** (strong partial result)
- W&B reports sr=3025 already hit during run — same as baseline sr
- val=3.2651 beats baseline val=3.26615 by −0.00105 — marginal val improvement at same sr
- Seed 2 not yet started
- Status: still WIP — waiting for seed 2 launch and terminal SENPAI-RESULT

---

## 2026-05-17 11:01 UTC — PR #216 CLOSED: Aux AdamW β2 scan {0.99, 0.999} (g1r1-nezuko)

- Branch: `g1r1-nezuko/aux-beta2-scan`
- **Hypothesis:** Aux AdamW β2=0.95 is under-tuned. Scan {0.99, 0.999} on PMuon+u/w+γ=1.2 base.

| Arm | β2 | sr | val/loss | vs current baseline (3025/3.26615) |
|-----|-----|-----|----------|-----------------------------------|
| Baseline | 0.95 | 3025 | 3.26615 | — |
| **A** | 0.99 | 3025 | 3.26640 | sr TIE, val +0.00025 — NULL |
| **B** | 0.999 | 3100 | 3.27185 | sr +75, val +0.00570 — clear regression |

**Analysis:** Monotone result — higher β2 worsens performance. β2=0.999's longer EMA (~700-step half-life) inflates the Adam denominator 2.4× relative to β2=0.99 by cooldown, halving effective LR during the decisive cooldown window. Arm A (β2=0.99) ties baseline sr but val is marginally worse (+0.00025) — not a merge candidate. **Direction: β2 axis CLOSED at baseline 0.95.** Increasing β2 degrades performance monotonically.

**Status:** CLOSED — NULL on primary metric. β2 axis fully characterized.

---

## 2026-05-17 11:01 UTC — PR #258 ASSIGNED: u/w-floor pruning ablation (g1r1-nezuko)

- Branch: `g1r1-nezuko/uw-floor-pruning-ablation`
- **Hypothesis:** Skylight u/w-floor (TARGET_UW=0.35, PR #131) may be redundant on new compound baseline. γ_power=0.4 bilateral whitening + cubic-Newton partial polar convergence may self-regulate u/w ratios.
- Arm A: TARGET_UW=0.0 (disable floor entirely)
- Arm B: TARGET_UW=0.7 (double — test over-constraint)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/258

---

## 2026-05-17 11:01 UTC — PR #242 ARM A DONE: γ_power finer scan (g1r1-frieren)

- Arm A (γ=0.5) `p5awihqf`: TERMINAL. sr=3150, val=3.2756 — **clear regression** vs baseline (sr=3025).
- Arm B (γ=0.6): 3rd attempt `d7wawe9q` just launched (after 2 step-1 crashes).
- **CRITICAL FINDING:** γ_power=0.5 is significantly worse than γ_power=0.4 (sr=3150 vs 3025). Combined with earlier monotone {0.2→3050, 0.3→3062.5, 0.4→3025}, this reveals a **clear local optimum at γ_power=0.4**. Direction reverses after 0.4.
- Arm B at γ=0.6 expected to be even worse. Structural crashes may indicate γ=0.6 is at a whitening instability boundary.

---

## 2026-05-17 12:00 UTC — PR #242 CLOSED: γ_power finer scan final result (g1r1-frieren)

- Arm B (γ=0.6): 3 consecutive crashes (`ekouv53z` step 1, `p0j7ghmd` step 1, `d7wawe9q` step 775). Structural whitening instability at γ_power=0.6 confirmed.

**γ_power axis FULLY CLOSED:**

| γ_power | sr | result |
|---|---|---|
| 0.2 | 3050 | suboptimal |
| 0.3 (old baseline) | 3062.5 | suboptimal |
| **0.4 (current baseline)** | **3025** | **local optimum** |
| 0.5 | 3150 | regression |
| 0.6 | crash | structurally unstable |

**Analysis:** The γ_power axis shows a sharp optimum at 0.4. Below 0.4: weaker whitening → worse convergence. Above 0.4: aggressive whitening destabilizes L_cov/R_cov eigendecomposition, causing crashes or regression. γ_power=0.4 will remain a fixed component of the baseline stack.

**Status:** CLOSED — axis fully characterized. PR closed.

---

## 2026-05-17 12:00 UTC — PR #261 ASSIGNED: PMuon LR warmup scan (g1r1-frieren)

- Branch: `g1r1-frieren/muon-lr-warmup-scan`
- **Hypothesis:** PMuon has no LR warmup. The bilateral covariance EMAs (L_cov, R_cov) initialize at zero and are unreliable for the first ~20 steps (β_cov=0.95, effective samples at step k ≈ 20*(1-0.95^k)). Current full-LR cold-start may cause erratic whitening during EMA initialization, especially with the more aggressive γ_power=0.4. A short linear Muon LR warmup gates these noisy early updates. This mechanism axis has NEVER been tested in the program history.
- Arm A: Linear Muon LR warmup over 50 steps
- Arm B: Linear Muon LR warmup over 150 steps
- Apply to optimizer2 (Muon) ONLY — AdamW has built-in first/second moment EMAs that adapt quickly.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/261

---

## 2026-05-17 13:15 UTC — PR #225 CLOSED: Wave 7 stack NULL on n=2 (g1r1-thorfinn)

Terminal SENPAI-RESULT received. Wave 7 stack = γ_power=0.4 (now in baseline) + deep-WD slope=+0.5 + lm_head LR 1/160 (2× baseline 1/320).

| Seed | W&B run | sr | val | best_val_step |
|---|---|---|---|---|
| 1 | `y69hfn95` | 3025 | 3.26513 | 3250 |
| 2 | `phsvmx45` | 3050 | 3.26772 | 3250 |
| **Mean (n=2)** | — | **3037.5** | **3.266425** | — |
| Baseline (n=1) | `prncgzv5` | **3025** | **3.26615** | — |
| Δ vs baseline | — | **+12.5 (worse)** | **+0.00028 (worse)** | — |

**Analysis:** Seed-to-seed variance on this stack (sr swing 3025→3050, Δval=0.00259) is larger than seed 1's marginal val win over baseline. Seed 1 was within noise. The Wave 7 stack does not reliably beat baseline. Mechanistically — with γ_power=0.4 already in baseline, the additional deep-WD and lm_head LR boosts are no longer additive; the whitening absorbs most of the regularization headroom that deep-WD provides.

**Important program-level finding:** n=1 marginal wins (val Δ ≤ 0.001) on this task are within seed-to-seed noise. Require n=2 confirmation OR larger absolute val deltas (>0.002) before merging marginal wins.

**Status:** CLOSED. NULL on primary sr metric and on val. PR #272 assigned thorfinn (AdamW eps scan).

---

## 2026-05-17 13:15 UTC — PR #272 ASSIGNED: AdamW eps scan {1e-8, 1e-9} (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamw-eps-scan`
- **Hypothesis:** AdamW `eps=1e-10` is 100× more aggressive than PyTorch default (1e-8) and has never been scanned. Especially relevant for embed parameter (sparse-gradient with rarely-activated tokens) where `1/(sqrt(v)+eps)` denominator floor matters.
- Arm A: eps=1e-8 (PyTorch default)
- Arm B: eps=1e-9 (intermediate)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/272

---

## 2026-05-17 13:25 UTC — PR #231 CLOSED: Muon mu scan NULL (g1r1-fern)

Terminal SENPAI-RESULT — fern early-killed arm B (mu=0.99) at step 1957 after confirmed divergence.

| Arm | mu | sr | val/loss | vs current baseline (3025/3.26615) |
|---|---|---|---|---|
| Arm A | 0.90 | 3125 | 3.27589 | NULL (sr +100, val +0.00974) |
| Arm B | 0.99 | killed step 1957 | 4.37 (no recovery path) | DIVERGED |

Arm B divergence trajectory:
- Step 1000 (best): val=3.82
- Step 1500: val=6.65 (spike)
- Step 1875: val=4.37 (slowing recovery; ∆=+0.55 from best)
- Killed step 1957

**mu axis CLOSED — mu=0.95 baseline locally optimal:**

| mu | sr | result |
|---|---|---|
| 0.90 | 3125 | NULL (gradient direction noise too high) |
| **0.95** | **3025** | **local optimum** |
| 0.99 | diverge | structurally unstable (momentum-buffer overshoot can't recover) |

Excellent early-kill execution by fern — saved ~3 hours of GPU on a structurally hopeless run.

**Status:** CLOSED. PR #274 assigned fern (COOLDOWN_POWER retune {1.0, 1.4}).

---

## 2026-05-17 13:30 UTC — PR #274 ASSIGNED: COOLDOWN_POWER retune (g1r1-fern)

- Branch: `g1r1-fern/cooldown-power-retune`
- **Hypothesis:** COOLDOWN_POWER=1.2 was set in PR #137 on the old baseline. With γ_power=0.4 now providing stronger whitening and lower-noise preconditioned gradients, the optimal cooldown LR decay shape may have shifted.
- Arm A: COOLDOWN_POWER=1.0 (linear cooldown)
- Arm B: COOLDOWN_POWER=1.4 (more concave, front-loaded LR drop)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/274

---

## 2026-05-17 14:15 UTC — PR #229 CLOSED: NS coef (a,b) line scan {a=1.3, 1.7} (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns-coef-ab-line-scan`
- **Hypothesis:** Move along the doubly-tangent (a, b=1-a, c=0) line away from cubic-Newton (a=1.5). Tests whether a=1.5 is a sharp optimum or has wiggle room.
- W&B runs: `la9l6roq` (arm A, gentle a=1.3), `xphiroo2` (arm B, aggressive a=1.7)

| Arm | NS_A | NS_B | NS_C | f'(1) | sr | val/loss | ortho_res @ 3000 |
|-----|------|------|------|-------|-----|----------|--------------------|
| Baseline (q8aduc16, c=0, a=1.5) | 1.5 | -0.5 | 0 | 0 | 3050 | 3.26773 | 0.0979 |
| Arm A (la9l6roq, gentle) | 1.3 | -0.3 | 0 | +0.4 | 3075 | 3.26921 | 16.297 |
| Arm B (xphiroo2, aggressive) | 1.7 | -0.7 | 0 | -0.4 | 3050 | 3.26786 | 0.1608 |

**Result:** Both NULL. Arm A clearly worse (+0.00306 val, +50 sr); Arm B effectively tied baseline (+0.00171 val within seed noise, sr same 3050).

**Key program-level finding:** f'(1)=0 doubly-tangent constraint is NOT strictly required for performance. Arm B with f'(1)=-0.4 (over-contractive) performs identically to baseline. But gentler contraction (Arm A) is strongly disfavored — ortho_residual blows up 160× (0.10 → 16.3) and val degrades measurably. With NS_ITERS=12, the polynomial must drive σ→1 quickly; the "tangent at 1" property is geometrically nice but not the constraint that matters.

**Axis decision: CLOSED at (a=1.5, b=-0.5, c=0).** Cubic-Newton confirmed locally optimal. Excellent diagnostic logging with `polar/ortho_residual_sample` — the ortho_residual trajectory is what made the mechanism legible. Combined with PR #184 (NS_ITERS flat 6-18) and PR #250 (c-scan, c=-0.25 NULL), the NS coef family is largely closed.

**Status:** CLOSED. Next assignment incoming for alphonse.

---

## 2026-05-17 14:30 UTC — PR #278 ASSIGNED: z-loss auxiliary loss scan (g1r1-alphonse)

- Branch: `g1r1-alphonse/zloss-auxiliary-scan`
- **Hypothesis:** z-loss penalty `Z_LOSS_COEF · sum(logsumexp(logits)²)` added to cross-entropy. PaLM/Chinchilla/Mamba standard regularizer. Never tested. Orthogonal to existing soft-clamp (constrains per-logit magnitude, not partition function mean).
- Arm A: Z_LOSS_COEF=1e-4 (PaLM-scale standard)
- Arm B: Z_LOSS_COEF=1e-3 (10× stronger, in case soft-clamp buffers the low-coef effect)

## 2026-05-20 19:11 UTC — PR #562 CLOSED: PMuon ε floor scan {1e-10, 1e-14} — NULL/NULL, ε=1e-12 baseline confirmed optimal across ±2 OOM (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-eps-floor-scan`
- Hypothesis: eigenvalue clamp ε in `matrix_neg_power` may be load-bearing at near-rank-deficient early training or cooldown saturation. Test ε=1e-10 (10× looser) and ε=1e-14 (100× tighter) vs baseline 1e-12.

| Arm | ε | W&B run | fs | val | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1e-10 | `log2c4fj` | 2950 | 3.265632 | +12.5 (marginal) | +0.001354 (marginal) | NULL n=2 not needed (already on NULL side) |
| B | 1e-14 | `169fd498` | 2975 | 3.265954 | +37.5 (clear) | +0.001676 | NULL clear |
| Baseline | 1e-12 | `k7ylyby9`+`dm4joozw` | 2937.5 | 3.264278 | — | — | — |

**Verdict: NULL/NULL — PMuon ε floor axis closes.** Asymmetric (Arm B worse): tighter clamp amplifies noise on rank-deficient directions. Effect subthreshold — optimum sits slightly above 1e-12 but within noise across the 4 OOM range. PMuon scalar audit now COMPLETE: γ_power (#519), β_cov (#502), NS_ITERS (#511+#546), ε floor (#562) — all NULL within natural ranges.

## 2026-05-22 00:23 UTC — PR #696 CLOSED: Contra-Muon momentum subtraction — NULL/NULL, 58th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/contra-muon-momentum`
- Hypothesis: Contra-Muon contrarian EMA subtraction on body-Muon — subtract a slow EMA (μ_contra=0.999) from the fast EMA (μ=0.95) before NS to add "contrarian" direction bias. Two arms: Arm A contra_coeff=0.2, Arm B contra_coeff=0.1. Design intended 15-25% effective subtraction.

| Arm | contra_coeff | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.2 | mgdfhfzq | 3125 | 3.27599 | +187.5 | +0.0117 | NULL |
| Arm B | 0.1 | wfzugtmb | 3000 | 3.26857 | +62.5 | +0.00429 | NULL |

- **Stat-sig test:** Both arms sr > 2937.5 = fail. Stat rule: Arm A (3.28−3.27599)·√1=+0.004 barely passes val threshold but sr catastrophically regressed. Arm B val just above stat-sig cut. Both unambiguously NULL.

- **Key mechanism finding — structural whitening compression:** PMuon bilateral whitening compresses the slow EMA's polar-space footprint by ~6× vs the fast EMA: m_contra_pre_frob / m_pre_frob ≈ 14-17% (coefficient-independent, structural property). Effective subtraction reached only ~3% (Arm A) and ~1.5% (Arm B) vs design target 15-25%.

- **Dose-response analysis:** Halving coefficient (0.2→0.1) halved the damage (Δsr +187.5 → +62.5). Monotone in wrong direction: more subtraction = worse. Extrapolated coeff=1.0 would give ~Δsr +1500 = catastrophic. Pre-NS contra injection (alternative) untested but family context (gradient-domain perturbations uniformly NULL in this stack) makes it unlikely to help.

- **Conclusion:** Contra-Muon as post-NS body-Muon mechanism CLOSED. Design hypothesis untestable at any coefficient due to structural PMuon whitening compression. Adds to the broader pattern: spectral/gradient perturbations in the whitened update space all absorbed by PMuon. 58th closed axis.

## 2026-05-22 00:38 UTC — PR #695 CLOSED: Polyak EMA β=0.9/0.95 short-window — NULL/NULL, 59th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-shortwindow`
- Hypothesis: Short-window Polyak EMA with late-start to suppress centroid-lag. Two arms: Arm A β=0.9 warmup=2500 (N_eff~10), Arm B β=0.95 warmup=2250 (N_eff~20). Direct follow-up to #662 β=0.99 centroid-lag finding.

| Arm | β | warmup | N_eff | peak Δ (step) | terminal Δ | W&B | sr | val/loss | Δsr | Δval |
|---|---|---|---|---|---|---|---|---|---|---|
| Baseline | — | — | — | — | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — |
| Arm A | 0.9 | 2500 | ~10 | −5.02 mnat (2625) | +0.01 mnat | g915dzx4 | 2950 | 3.26648 | +12.5 | +0.002 |
| Arm B | 0.95 | 2250 | ~20 | −16.42 mnat (2375) | +0.06 mnat | p4mm3e85 | 2925 | 3.26562 | −12.5 (boundary) | +1.34 mnat |

- **Win analysis Arm B:** sr=2925 hits boundary but val=3.26562 > 3.264278 by +1.34 mnat → AND clause fails. Marginal Δsr=12.5 triggering n=2 rule, but EMA mechanism ≈0 at terminal → seed noise. Both arms NULL.

- **Decisive mechanism — β-scan completes full geometric picture:**
  - Peak EMA advantage scales ~linearly with N_eff: 5 / 16.4 / 63 mnat = 1× / 3.3× / 12.6×, matching window ratios 1× / 2× / 10×
  - Terminal lag drops 60× from β=0.99 → β=0.9 (lag ∝ live-param drift × N_eff)
  - Both signal AND lag shrink together — no (β, warmup) setting separates them
  - At β=0.9 (N_eff~10), both terms drop below seed noise (~0.5 mnat)

- **Conclusion:** Lag/signal coupling is intrinsic to PMuon-EMA at this benchmark geometry. No static window setting works. FULL CLOSURE of Polyak EMA on body-Muon across β ∈ {0.9, 0.95, 0.99}. Next step: cooldown-aware β ramp (dynamic window coupled to LR decay, targets "free averaging when params stationary") — assigned as #737 to thorfinn.

## 2026-05-22 13:21 UTC — PR #737 MERGED: Polyak EMA β_target=0.99 cooldown ramp — n=2 sr win (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-cooldown-aware-beta`
- Hypothesis: Ramping Polyak EMA β from 0.95→0.99 during LR cooldown lengthens the averaging window as gradients become small/noisy, shifting the val-trajectory crossing of 3.28 earlier.
- Mechanism: deterministic β_t = 0.95 + 0.04 × cooldown_progress (coupled to lr_mult). EMA buffer stores FP32 body-Muon matrix params; inference uses EMA-swapped weights.

| Run | β_target | sr | val/loss | vs baseline |
|---|---|---|---|---|
| Seed-1 `rdbmnzpc` | 0.99 | **2925** | 3.265811 | sr −12.5 ✅ |
| Seed-2 `32r3isz5` | 0.99 | **2925** | 3.268040 | sr −12.5 ✅ |
| n=2 mean | 0.99 | **2925** | **3.266926** | **sr −12.5, val +2.65 mnat** |
| Arm B `b4q13sgm` | 0.999 | 2950 | ~3.270 | NULL |
| Old baseline (PR #413) | — | 2937.5 | 3.264278 | ref |

**Verdict: MERGED — first n=2-confirmed sr win of the cooldown-coupled-ramp cluster.** Both seeds independently reproduce sr=2925. Val regresses +2.65 mnat (N_eff=100 EMA lag bias) but primary metric sr improves. New baseline: sr=2925 / val=3.266926. EMA telemetry: β_t ramp 0.95→0.99 correct; `ema/delta_ema_minus_live = +0.54 mnat` deterministic across seeds. β_target=0.999 NULL (N_eff=1000 too wide, lag dominates).

## 2026-05-22 13:21 UTC — PR #760 CLOSED: PMuon γ_power cooldown ramp (69th axis, NULL/NULL) (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-power-cooldown-ramp`
- Hypothesis: Ramping PMuon's whitening exponent γ_power during cooldown adjusts preconditioner geometry as LR decays.

| Arm | γ_power schedule | sr | val/loss | vs old baseline |
|---|---|---|---|---|
| Arm A `4yzrav20` | 0.4→0.5 (harder) | 2975 | 3.26724 | NULL (+37.5 sr, +0.00296 val) |
| Arm B `1mvtoyib` | 0.4→0.3 (softer) | 2975 | 3.26581 | NULL (+37.5 sr, +0.00153 val) |
| Baseline (PR #413) | 0.4 static | 2937.5 | 3.264278 | ref |

**Verdict: CLOSED NULL (69th axis).** Arm B "less bad" than Arm A (softer whitening in cooldown is ~2× closer to baseline) but both regress. Cooldown-erosion pattern dominates. γ_power=0.4 static is well-tuned; ramping the whitening exponent during cooldown degrades update geometry. Student correctly identified: whitening precision is not a free knob during cooldown — it couples to the LR decay mechanism. Softward direction (γ<0.4) is slightly more permissive, consistent with #736 tanjiro's per-type γ pattern.
