# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~23:40Z (poll #560) — **#914 alphonse SOAP refresh freeze CLOSED clean-NEG (Cell C freeze +4.9σ NEG → SOAP eigenbasis carries useful curvature signal even during cooldown). alphonse → #966 cooldown weight rescaling (fresh weight-space axis, parallels #907 Cell E state-rescaling).** 8 PRs in flight.

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)

## Active WIP Portfolio (poll #554)

8 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#941** | **edward** | ★ **NEW poll #545.** Cooldown SWA: maintain weight EMA during cooldown (steps 975–3250), use EMA weights for eval. β=0.99 (half-life ~70 steps). Distinct from Lookahead (#826) and Schedule-Free (#855). Novel axis. | Just assigned. 5-cell: A ctrl, B β=0.99 ★, C β=0.999, D β=0.95, E late-start SWA (step 1625). |
| **#936** | **askeladd** | Asymmetric SOAP eigenbasis ablation — left-only (Q_col=I) vs right-only (Q_row=I) to reveal which side is load-bearing. | Just assigned. 5-cell: A ctrl, B left-only ★, C right-only, D left MLP-only, E right MLP-only. |
| **#932** | **thorfinn** | Per-layer NS iteration count scaled by transformer depth. depth_scale=0.5 → early=3..late=9, mean=6. Budget-neutral. | Cell A ctrl in progress. B-E queued. |
| **#925** | **fern** | Muon momentum coefficient μ schedule: drop 0.95→0.85 at cooldown onset. | Multi-cell sweep underway. |
| **#924** | **nezuko** | Free Hutchinson diagonal curvature scaling post-NS. EMA of gradient differences ≈ diagonal H. | Multi-cell sweep underway. |
| **#966** | **alphonse** | ★ **NEW poll #560.** Cooldown weight rescaling: one-shot uniform shrink of body matrix weights at step 975. Tests if weight norms need recalibration to cooldown regime, parallel to #907 Cell E state-rescaling mechanism. | Just assigned. 5-cell: A ctrl, B α=0.99 ★, C α=0.97, D α=0.95, E α=1.01 (falsifier). |
| **#907** | **tanjiro** | ★ **HIGH-SIGNAL.** Joint Muon momentum + SOAP `exp_avg_sq` reset at step 975. Cell E n=1=3.26004 (−3.5σ_SE POS). Sent back for n=4 confirmation. Mechanism: cooldown wants ALL adaptive state recalibrated to cooldown gradient scale. | n=4 confirmation arm `--num_trials 4` running. |
| **#962** | **frieren** | ★ **NEW poll #557.** NS polynomial coefficient ablation. (a,b,c)=(2,-1.5,0.5) ctrl vs cubic-conv (1.875,-1.25,0.375) ★, Muon-paper (3.4445,-4.775,2.0315), cubic-only (1.5,-0.5,0), high-amp (2.5,-2,0.5). Tests NS-internal axis: does the polynomial structure matter beyond iter count? | Just assigned. 5-cell sweep. |

## Key Signals (as of poll #554)

- **★ #907 tanjiro joint reset (HIGHEST PRIORITY)** — Cell E (zero both Muon momentum AND SOAP `exp_avg_sq` at step 975) n=1=3.26004 (−3.5σ_SE POS). Cells B/C/D (Muon-only reset) all NEG, monotonic severity → mechanism is calibration mismatch under partial reset. Joint-reset axis is novel and aligns with `ramp_down` WD precedent (cooldown wants all adaptive state recalibrated). n=4 confirm running.
- **#941 edward Cooldown SWA** — Novel axis. SWA finds centroid of wide loss basin during cooldown descent. Half-life 70 steps captures end-of-cooldown weight averaging without mixing with exploration phase. Mechanism distinct from all closed PRs.
- **#936 askeladd Asymmetric SOAP** — Diagnostic: which SOAP eigenbasis side (left/right) is load-bearing? High information value regardless of metric outcome.
- **#925/#907** — Parallel cooldown-momentum axis. Both near terminal on early cells.
- **#914 alphonse / #932 thorfinn** — Preconditioner dynamics and NS iteration allocation.
- **#924 nezuko Hutchinson** — Post-NS curvature axis.

## Recent Closures (poll #534–560)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#914 alphonse** (poll #560) | clean-NEG | SOAP refresh freeze: Cell C freeze +4.9σ NEG, B PRIMARY (cooldown_freq=64) baseline parity. Eigenbasis carries useful curvature signal during cooldown. |
| **#902 frieren** (poll #557) | clean-NEG | Top-k pre-NS: all treatments +2.2-2.5σ NEG, k=90% "near no-op" is WORST. Hard zeroing breaks NS regardless of fraction. **Closes pre-NS axis (9 PRs).** |
| **#890 edward** (poll #545) | clean-WEAK-NEG | Per-col-norm pre-NS: PRIMARY parity, Cell D −1.21σ (n=1) misses n=4 gate by 3×. NS orth error 0.43→0.06 on synthetic but zero val/loss benefit. |
| **#887 askeladd** (poll #542) | clean-WEAK-NEG | AGC-Muon: λ=0.001 mlp=3.26071 (−0.86σ). clipped_frac=1 → reduces to implicit MLP LR shrink. |
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V consensus: +9.4σ. Q/K/V near-orthogonal in param space. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon: n=4 mean=3.261930. Sign-direction axis closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 mean=3.260675 (statsig=0.001 vs gate 0.004). |

## Closed Axis Map (comprehensive)

**Pre-NS gradient transformation (FULLY SATURATED, 9/9 NEG):** per-col-norm #890, AGC #887, MARS #873, AdEMAMix #840, Q/K/V consensus #905 STRONG NEG, top-k #902 NEG, sign #823 NEG, GrokFast #859 NEG, sign-Cautious #844/#867 NEG.
**NS quality/structure:** polar expression #824, NS warmup #815, RMS-clamp #776 — all CLOSED. Per-layer NS iter #932 open. NS polynomial coefficients #962 open (first time tested).
**Schedule layer (5/5):** ALL CLOSED. Cooldown SWA (#941) is a *weight* not LR modification — novel.
**SOAP dynamics:** trust threshold #467 neutral, refresh rate in cooldown #914 NEG (freeze +4.9σ), eigenbasis side #936 open.
**Weight-space interventions at cooldown:** cooldown weight rescaling #966 open (first time this axis tested, parallel to #907 state-reset).
**Momentum at cooldown:** μ schedule #925 open, buffer reset #907 open.
**Post-NS curvature:** Hutchinson #924 open (first time this axis tested).
**Outer-loop wrappers:** Lookahead #826 NEG, Cautious #844/#867 NEG, SF Muon #855 NEG.
**Weight averaging:** Cooldown SWA #941 open (first time this axis tested — distinct from Lookahead/SF).
