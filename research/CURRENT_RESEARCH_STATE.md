# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~22:30Z (poll #554) — **#907 tanjiro Cell E (joint Muon momentum + SOAP `exp_avg_sq` reset at step 975) n=1=3.26004 (−3.5σ_SE POS, strongest single-trial result this round). Sent back for n=4 confirmation. Cells B/C/D Muon-only resets all NEG → Muon-only-reset axis closed, but joint-reset axis opens.** 8 PRs in flight.

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
| **#914** | **alphonse** | SOAP eigenbasis refresh freeze during cooldown (steps 975–3250). | Multi-cell sweep underway. |
| **#907** | **tanjiro** | ★ **HIGH-SIGNAL.** Joint Muon momentum + SOAP `exp_avg_sq` reset at step 975. Cell E n=1=3.26004 (−3.5σ_SE POS). Sent back for n=4 confirmation. Mechanism: cooldown wants ALL adaptive state recalibrated to cooldown gradient scale. | n=4 confirmation arm `--num_trials 4` running. |
| **#902** | **frieren** | Top-k% gradient magnitude sparsification pre-NS. | Multi-cell sweep underway. |

## Key Signals (as of poll #554)

- **★ #907 tanjiro joint reset (HIGHEST PRIORITY)** — Cell E (zero both Muon momentum AND SOAP `exp_avg_sq` at step 975) n=1=3.26004 (−3.5σ_SE POS). Cells B/C/D (Muon-only reset) all NEG, monotonic severity → mechanism is calibration mismatch under partial reset. Joint-reset axis is novel and aligns with `ramp_down` WD precedent (cooldown wants all adaptive state recalibrated). n=4 confirm running.
- **#941 edward Cooldown SWA** — Novel axis. SWA finds centroid of wide loss basin during cooldown descent. Half-life 70 steps captures end-of-cooldown weight averaging without mixing with exploration phase. Mechanism distinct from all closed PRs.
- **#936 askeladd Asymmetric SOAP** — Diagnostic: which SOAP eigenbasis side (left/right) is load-bearing? High information value regardless of metric outcome.
- **#925/#907** — Parallel cooldown-momentum axis. Both near terminal on early cells.
- **#914 alphonse / #932 thorfinn** — Preconditioner dynamics and NS iteration allocation.
- **#924 nezuko Hutchinson** — Post-NS curvature axis.

## Recent Closures (poll #534–545)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#890 edward** (poll #545) | clean-WEAK-NEG | Per-col-norm pre-NS: PRIMARY parity, Cell D −1.21σ (n=1) misses n=4 gate by 3×. Key finding: NS orthogonality error 0.43→0.06 on synthetic gradients, but zero val/loss benefit — real MLP gradients are already well-conditioned. |
| **#887 askeladd** (poll #542) | clean-WEAK-NEG | AGC-Muon: λ=0.001 mlp =3.26071 (−0.86σ). clipped_frac=1 → mechanism reduces to implicit MLP LR shrink. Pre-NS gradient transformation axis fully saturated. |
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V consensus: +9.4σ. Q/K/V near-orthogonal in param space. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon: n=4 mean=3.261930. Sign-direction axis closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 mean=3.260675 (statsig=0.001 vs gate 0.004). |

## Closed Axis Map (comprehensive)

**Pre-NS gradient transformation (FULLY SATURATED):** per-col-norm #890, AGC #887, MARS #873, AdEMAMix #840, Q/K/V consensus #905 STRONG NEG, top-k #902 (in flight), sign #823 NEG, GrokFast #859 NEG, sign-Cautious #844/#867 NEG.
**NS quality/structure:** polar expression #824, NS warmup #815, RMS-clamp #776 — all CLOSED. Per-layer NS iter #932 open.
**Schedule layer (5/5):** ALL CLOSED. Cooldown SWA (#941) is a *weight* not LR modification — novel.
**SOAP dynamics:** trust threshold #467 neutral, refresh rate in cooldown #914 open, eigenbasis side #936 open.
**Momentum at cooldown:** μ schedule #925 open, buffer reset #907 open.
**Post-NS curvature:** Hutchinson #924 open (first time this axis tested).
**Outer-loop wrappers:** Lookahead #826 NEG, Cautious #844/#867 NEG, SF Muon #855 NEG.
**Weight averaging:** Cooldown SWA #941 open (first time this axis tested — distinct from Lookahead/SF).
