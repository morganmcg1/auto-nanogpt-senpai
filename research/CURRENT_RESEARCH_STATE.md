# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-24 ~06:00Z (poll #579) — **#907 tanjiro joint Muon+SOAP reset CLOSED clean-NEG. n=1 POS (3.26004) was favorable-tail draw from distribution with σ_single 1.71× baseline. n=4 μ=3.261655 (+1.46σ_SE NEG). Discontinuities at step 975 inflate variance — important generalized lesson for #966 alphonse weight rescaling. tanjiro → #1010 NS-iter-by-time (boost NS quality during cooldown — novel axis vs #932 by-depth, #815 by-early-time both closed).** 8 PRs in flight.

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)

## Active WIP Portfolio (poll #579)

8 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#1010** | **tanjiro** | ★ **NEW poll #579.** NS-iter-by-time: boost NS quality during cooldown (lower LR regime has lower gradient SNR — cleaner orthogonalization may extract better directions). Novel axis vs #932 by-depth and #815 by-early-time, both closed. Cell E ramp tests whether smooth transition outperforms abrupt step-jump (generalizes #907 lesson). | Just assigned. 5-cell: A ctrl (ns=6), **B ns_cooldown=8 ★**, C ns_cooldown=10, D ns_cooldown=12 (boundary), E linear ramp 6→9. |
| **#994** | **edward** | ★ SOAP simplification: drop Q_row from attn ONLY (missing #936 per-scope config). Tests additive cross-scope decomposition. If predicted ~+0.89σ holds, unlocks compute savings. | 5-cell (attn_side, mlp_side) sweep: A (both,both), **B (right,both) ★**, C (none,both), D (right,right), E (right,none). |
| **#993** | **askeladd** | ★ Gradient-norm-anomaly-driven Muon momentum reset. Track ||grad||_F EMA; when current norm > K × EMA, partial momentum reset. Magnitude-anomaly axis. | 5-cell: A ctrl, B thresh=3 frac=0.5 ★, C thresh=2 (sensitive), D frac=1.0 (full reset), E thresh=5 (conservative). |
| **#979** | **thorfinn** | ★ SOAP exp_avg_sq scaling ablation. Tests whether Adam-in-basis component (per-element second-moment scaling in Q-basis) is load-bearing or vestigial. Mechanistically distinct from #936 (Q ablation) and #914 (Q refresh). | 5-cell: A ctrl, B skip exp_avg_sq ★, C also drop norm-preserve, D freeze exp_avg_sq=1, E instantaneous (no EMA). |
| **#973** | **nezuko** | ★ Cosine-gated adaptive Muon momentum: μ adapts per-step per-matrix based on cos(grad, momentum). cos=+1 → μ_max=0.99 (aligned); cos=−1 → μ_min=0.70 (opposed, fresh gradient). | 5-cell: A ctrl, B μ_min=0.70 μ_max=0.99 ★, C μ_min=0.50 μ_max=0.99, D μ_min=0.85 μ_max=0.99, E exploration-only (revert at step 975). |
| **#966** | **alphonse** | Cooldown weight rescaling: one-shot uniform shrink of body matrix weights at step 975. **WATCH FOR**: #907 closure showed step-975 discontinuities inflate σ_single 1.71× — alphonse may show similar variance inflation at n=4. | 5-cell sweep running: A ctrl, B α=0.99 ★, C α=0.97, D α=0.95, E α=1.01 (falsifier). |
| **#962** | **frieren** | NS polynomial coefficient ablation. (a,b,c)=(2,-1.5,0.5) ctrl vs cubic-conv (1.875,-1.25,0.375) ★, Muon-paper, cubic-only, high-amp. Tests NS-internal axis. | 5-cell sweep underway. |
| **#925** | **fern** | ★★ **Cell E n=1=3.258418 (−4.73σ POS).** Linear ramp μ=0.95→0.85 over cooldown. Step-switch variants (B/C/D) all NEG. **#907's n=4 confirm regressed (σ inflated 1.71× from abrupt discontinuity) — but #925 uses a SMOOTH ramp, distinct mechanism. Linear ramp may avoid the variance trap.** | **n=4 confirm arm running.** |

## Key Signals (as of poll #579)

- **★★ #925 fern Cell E linear μ ramp (HIGHEST-SIGNAL n=1, in n=4 confirm)** — val/loss=3.258418, ffs=2975, **−4.73σ_single POS** at n=1. Projected n=4 statsig 0.0056 ≥ 0.004 ✓. **Critically: #907 just closed clean-NEG at n=4 (σ_single inflated 1.71×). #925 uses a SMOOTH continuous ramp — distinct from #907's abrupt step-975 discontinuity. The smooth-vs-abrupt contrast becomes the live experimental question.**
- **Variance inflation lesson from #907 closure** — Instantaneous discontinuities at step 975 inflate σ_single 1.71× without improving mean. **Generalized warning for #966 alphonse cooldown weight rescaling** (another step-975 discontinuity — likely to show similar σ inflation at n=4 if Cell B shows n=1 POS).
- **Cooldown calibration cluster** — POS signal localizes to #925's SMOOTH ramp now that #907's abrupt reset closed NEG. #966 (weight rescale), #973 (cos-μ, smooth per-step), #993 (anomaly reset, conditional) are cluster siblings — the abrupt-vs-smooth divide is the key axis to watch.
- **#1010 tanjiro NS-iter-by-time** — Novel axis. Tests whether cooldown LR regime benefits from higher NS orthogonalization quality. Cell E (smooth ramp) directly tests the abrupt-vs-smooth lesson from #907.
- **#994 edward SOAP simplification** — Missing per-scope config from #936's matrix. Direct test of additive cross-scope decomposition.
- **#979 thorfinn SOAP exp_avg_sq** — Tests Adam-in-basis component necessity. Combined with #994, decomposes SOAP's remaining components systematically.
- **#962 frieren NS polynomial coefficients** — First test of NS-internal polynomial structure axis.

## Recent Closures (poll #534–579)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#907 tanjiro** (poll #579) | clean-NEG (high info) | Joint Muon+SOAP reset at step 975: n=1 Cell E POS (3.26004, −3.5σ_SE) was favorable-tail draw from distribution with **σ_single 1.71× baseline**. n=4 μ=3.261655 (statsig −0.000868, FAIL). **Generalized lesson: instantaneous discontinuities at step 975 inflate variance — watch #966 alphonse weight rescale similarly.** Closes full mu_reset_* axis. |
| **#941 edward** (poll #574) | clean-NEG (high info) | Cooldown SWA: `swa/live_vs_swa_dist` monotonic in β AND in regression magnitude. **Cooldown is directed descent, not noisy oscillation.** Weight EMA always lags. **Closes "trajectory averaging" axis 3/3** (#826 Lookahead, #855 SF, #941 SWA). |
| **#936 askeladd** (poll #573) | clean-NEG (high info) | Asymmetric SOAP: B left-only (drop Q_col) +14.07σ vs ctrl. **B−C contrast +12.25σ** → Q_col (input-side) load-bearing for attn, Q_row (output-side) largely redundant for attn. MLP weights more symmetric. |
| **#932 thorfinn** (poll #568) | clean-NEG | Per-layer NS iter by depth: B (depth_scale=0.5) +0.012 NEG, C (depth_scale=1.0) diverged, D **inverted=SECOND-BEST** → refutes "late layers need more NS"; early-layer NS quality is load-bearing. NS_ITER<3 is hard floor. |
| **#924 nezuko** (poll #566) | clean-NEG | Hutchinson diagonal curvature: Cell B (α=0.5) +0.00950 NEG, Cell D (α=0.75) diverged. `\|dg\|` proxy is biased (mixes H·Δθ + gradient noise); divides by noise scale not curvature. **Closes post-NS curvature axis.** |
| **#914 alphonse** (poll #560) | clean-NEG | SOAP refresh freeze: Cell C freeze +4.9σ NEG, B PRIMARY (cooldown_freq=64) baseline parity. Eigenbasis carries useful curvature signal during cooldown. |
| **#902 frieren** (poll #557) | clean-NEG | Top-k pre-NS: all treatments +2.2-2.5σ NEG, k=90% "near no-op" is WORST. Hard zeroing breaks NS regardless of fraction. **Closes pre-NS axis (9 PRs).** |
| **#890 edward** (poll #545) | clean-WEAK-NEG | Per-col-norm pre-NS: PRIMARY parity, Cell D −1.21σ (n=1) misses n=4 gate by 3×. NS orth error 0.43→0.06 on synthetic but zero val/loss benefit. |
| **#887 askeladd** (poll #542) | clean-WEAK-NEG | AGC-Muon: λ=0.001 mlp=3.26071 (−0.86σ). clipped_frac=1 → reduces to implicit MLP LR shrink. |
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V consensus: +9.4σ. Q/K/V near-orthogonal in param space. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon: n=4 mean=3.261930. Sign-direction axis closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 mean=3.260675 (statsig=0.001 vs gate 0.004). |

## Closed Axis Map (comprehensive)

**Pre-NS gradient transformation (FULLY SATURATED, 9/9 NEG):** per-col-norm #890, AGC #887, MARS #873, AdEMAMix #840, Q/K/V consensus #905 STRONG NEG, top-k #902 NEG, sign #823 NEG, GrokFast #859 NEG, sign-Cautious #844/#867 NEG.
**NS quality/structure:** polar expression #824, NS warmup #815, RMS-clamp #776, per-layer NS iter by depth #932 — all CLOSED. Key finding from #932: early-layer NS quality is load-bearing. NS polynomial coefficients #962 open. **NS-iter-by-time #1010 OPEN** (boost ns_iter during cooldown — novel axis vs by-depth and by-early-time both closed).
**Schedule layer (5/5):** ALL CLOSED.
**Trajectory averaging (3/3 CLOSED):** Lookahead #826, Schedule-Free #855, Cooldown SWA #941. **#941 finding:** cooldown trajectory is directed descent — weight averaging always lags. Closes the entire "average the path" family.
**SOAP dynamics:** trust threshold #467 neutral, refresh rate in cooldown #914 NEG (freeze +4.9σ), eigenbasis side #936 CLOSED clean-NEG (Q_col load-bearing for attn), exp_avg_sq scaling ablation #979 open, **per-scope side pruning #994 OPEN (the missing #936 config — drop Q_row from attn ONLY)**.
**Weight-space interventions at cooldown:** cooldown weight rescaling #966 open (first time this axis tested, parallel to #907 state-reset).
**Momentum at cooldown:** ★★ μ schedule #925 Cell E linear ramp **SMOOTH** POS (n=4 confirm running), buffer reset #907 Cell E **ABRUPT** CLOSED clean-NEG (σ inflated 1.71×). Hard-switch μ drop #925 B/C/D NEG. **Smooth-vs-abrupt is now the live axis**: smooth interventions may avoid the variance trap that abrupt ones fall into. Gradient-norm-anomaly reset #993 open (magnitude-anomaly axis).
**Post-NS curvature:** Hutchinson #924 NEG (per-element |dg| proxy biased; divides by noise scale). Closed. Cosine-gated adaptive μ #973 open (orthogonal — momentum buffer, not update magnitude).
**Outer-loop wrappers:** Lookahead #826 NEG, Cautious #844/#867 NEG.
