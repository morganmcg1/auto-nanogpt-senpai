# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-24 ~03:45Z (poll #574) — **#941 edward Cooldown SWA CLOSED clean-NEG with mechanism finding (`swa/live_vs_swa_dist` monotonic in β AND in regression magnitude → cooldown is DIRECTED DESCENT, not noisy oscillation; weight EMA always lags). Closes "trajectory averaging" axis 3/3 with #826 Lookahead and #855 Schedule-Free. edward → #994 SOAP simplification: drop Q_row from attn ONLY — the missing #936 per-scope config.** 8 PRs in flight.

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)

## Active WIP Portfolio (poll #574)

8 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#994** | **edward** | ★ **NEW poll #574.** SOAP simplification: drop Q_row from attn ONLY (missing #936 per-scope config). Tests additive cross-scope decomposition. If predicted ~+0.89σ holds, unlocks compute savings. | Just assigned. 5-cell (attn_side, mlp_side) sweep: A (both,both), **B (right,both) ★**, C (none,both), D (right,right), E (right,none). |
| **#993** | **askeladd** | ★ **NEW poll #573.** Gradient-norm-anomaly-driven Muon momentum reset. Track ||grad||_F EMA; when current norm > K × EMA, partial momentum reset. Magnitude-anomaly axis (distinct from #907 time, #925 schedule, #973 cos-direction). | Just assigned. 5-cell: A ctrl, B thresh=3 frac=0.5 ★, C thresh=2 (sensitive), D frac=1.0 (full reset), E thresh=5 (conservative). |
| **#979** | **thorfinn** | ★ **NEW poll #568.** SOAP exp_avg_sq scaling ablation. Tests whether Adam-in-basis component (per-element second-moment scaling in Q-basis) is load-bearing or vestigial. Mechanistically distinct from #936 (Q ablation) and #914 (Q refresh). | 5-cell: A ctrl, B skip exp_avg_sq ★, C also drop norm-preserve, D freeze exp_avg_sq=1, E instantaneous (no EMA). |
| **#973** | **nezuko** | ★ **NEW poll #566.** Cosine-gated adaptive Muon momentum: μ adapts per-step per-matrix based on cos(grad, momentum). cos=+1 → μ_max=0.99 (aligned, keep velocity); cos=−1 → μ_min=0.70 (opposed, reset to fresh gradient). Scalar whole-matrix cosine (avoids Hutchinson's per-element direction-warping failure). | 5-cell: A ctrl, B μ_min=0.70 μ_max=0.99 ★, C μ_min=0.50 μ_max=0.99, D μ_min=0.85 μ_max=0.99, E exploration-only (revert at step 975). |
| **#966** | **alphonse** | Cooldown weight rescaling: one-shot uniform shrink of body matrix weights at step 975. Tests if weight norms need recalibration to cooldown regime, parallel to #907 Cell E state-rescaling mechanism. | 5-cell sweep running: A ctrl, B α=0.99 ★, C α=0.97, D α=0.95, E α=1.01 (falsifier). |
| **#962** | **frieren** | NS polynomial coefficient ablation. (a,b,c)=(2,-1.5,0.5) ctrl vs cubic-conv (1.875,-1.25,0.375) ★, Muon-paper (3.4445,-4.775,2.0315), cubic-only (1.5,-0.5,0), high-amp (2.5,-2,0.5). Tests NS-internal axis: does the polynomial structure matter beyond iter count? | 5-cell sweep underway. |
| **#925** | **fern** | ★★ **Cell E n=1=3.258418 (−4.73σ POS).** Linear ramp μ=0.95→0.85 over cooldown. Step-switch variants (B/C/D) all NEG (PR #693 extension). Linear ramp rescues soft-μ-drop hypothesis by changing *timing* — μ tracks LR's freshness requirements. | **n=4 confirm arm running.** `--mu_stable 0.95 --mu_cooldown 0.85 --mu_linear_ramp --num_trials 4`. |
| **#907** | **tanjiro** | ★ **HIGH-SIGNAL.** Joint Muon momentum + SOAP `exp_avg_sq` reset at step 975. Cell E n=1=3.26004 (−3.5σ_SE POS). Cells B/C/D (Muon-only reset) all NEG, monotonic severity → mechanism is calibration mismatch under partial reset. | n=4 confirmation arm `--num_trials 4` running. |

## Key Signals (as of poll #574)

- **★★ #925 fern Cell E linear μ ramp (NEW HIGHEST-SIGNAL n=1)** — val/loss=3.258418, ffs=2975, **−4.73σ_single POS** at n=1. Projected n=4 statsig 0.0056 ≥ 0.004 ✓. n=4 confirm in flight. Step-switch B/C/D all NEG (+5–8σ) — confirms #693's "accumulated buffer is dominant cooldown signal", but the *smooth ramp* rescues the soft-μ-drop hypothesis by changing timing.
- **★ #907 tanjiro joint reset (HIGH-SIGNAL n=1)** — Cell E (zero both Muon momentum AND SOAP `exp_avg_sq` at step 975) n=1=3.26004 (−3.5σ_SE POS). Cells B/C/D (Muon-only reset) all NEG. n=4 confirm running.
- **Cooldown calibration cluster** — Two parallel POS results now in n=4 confirm: #907 (instantaneous state reset) and #925 (continuous μ ramp). Both implement "cooldown wants smaller/fresher state" at different timescales. If both confirm, unified mechanism story is robust. Add #966 (weight rescale), #973 (cos-μ), #993 (anomaly reset) as cluster siblings.
- **#994 edward SOAP simplification** — Missing per-scope config from #936's matrix. Direct test of additive cross-scope decomposition. High information value: confirms compute-savings path OR reveals nonlinear cross-term interactions.
- **#979 thorfinn SOAP exp_avg_sq** — Tests Adam-in-basis component necessity. Orthogonal to #994 side-pruning. Combined, the two PRs decompose SOAP's remaining components systematically.
- **#962 frieren NS polynomial coefficients** — First test of NS-internal polynomial structure axis (beyond iter count).

## Recent Closures (poll #534–574)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
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
**NS quality/structure:** polar expression #824, NS warmup #815, RMS-clamp #776, per-layer NS iter by depth #932 — all CLOSED. Key finding from #932: early-layer NS quality is load-bearing (inverted schedule was second-best). NS polynomial coefficients #962 open (testing polynomial structure axis).
**Schedule layer (5/5):** ALL CLOSED.
**Trajectory averaging (3/3 CLOSED):** Lookahead #826, Schedule-Free #855, Cooldown SWA #941. **#941 finding:** cooldown trajectory is directed descent — weight averaging always lags. Closes the entire "average the path" family.
**SOAP dynamics:** trust threshold #467 neutral, refresh rate in cooldown #914 NEG (freeze +4.9σ), eigenbasis side #936 CLOSED clean-NEG (Q_col load-bearing for attn), exp_avg_sq scaling ablation #979 open, **per-scope side pruning #994 OPEN (the missing #936 config — drop Q_row from attn ONLY)**.
**Weight-space interventions at cooldown:** cooldown weight rescaling #966 open (first time this axis tested, parallel to #907 state-reset).
**Momentum at cooldown:** ★★ μ schedule #925 Cell E linear ramp POS (n=4 confirm), buffer reset #907 Cell E POS (n=4 confirm). Hard-switch μ drop #925 B/C/D NEG. Gradient-norm-anomaly reset #993 open (NEW magnitude-anomaly axis, complements time/schedule/geometry triggers).
**Post-NS curvature:** Hutchinson #924 NEG (per-element |dg| proxy biased; divides by noise scale). Closed. Cosine-gated adaptive μ #973 open (orthogonal — momentum buffer, not update magnitude).
**Outer-loop wrappers:** Lookahead #826 NEG, Cautious #844/#867 NEG.
