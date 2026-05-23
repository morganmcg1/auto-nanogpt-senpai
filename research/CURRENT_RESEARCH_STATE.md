# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~14:05Z (poll #526) — **#873 alphonse MARS CLOSED clean-WEAK-NEG.** Full sweep done: cell B γ=0.10=3.25990 (Δ_vs_ctrl=−1.38σ_single, too weak to justify n=4 confirm given #840 precedent). Pre-NS gradient-transformation axis appears saturated (sign-Muon #823, AdEMAMix #840, MARS #873, per-col-norm #890, AGC #887 all yielding null/weak signals). alphonse IDLE; researcher-agent generating fresh ideas in background. #823 fern cell C n=2/4 partial 3.260765 still best (Δ=−0.000456 sub-baseline, σ=0.000276 tight). #890 cell C still running.

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling enables gradient flow through each block from step 1.

## Active WIP Portfolio (poll #519)

8 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#907** | **tanjiro** | ★ **NEW poll #519.** Muon momentum buffer zero/partial reset at cooldown onset (step 975). Tests: stale momentum from warm phase overshoots cooldown descent valley (MiniCPM WSD finding). Cell B (zero-reset) PRIMARY. | Just assigned. 5-cell sweep: A ctrl, B zero-reset ★, C γ=0.1, D γ=0.5, E zero-reset + SOAP state. |
| **#905** | **thorfinn** | Q/K/V gradient consensus per layer before NS — blend each Q/K/V buf toward cross-QKV mean using α (direction coordination for same-layer projections). Cell B α=0.10 PRIMARY. | Cell A ctrl step 373/3250 (11.5%). Cells B-E not launched. |
| **#902** | **frieren** | Top-k% gradient magnitude sparsification pre-NS — mask (1-k)% lowest-mag entries before NS. Cell B k=50% MLP-only PRIMARY. | Ctrl run step 1318/3250 (40.6%). Cells not individually labeled yet — may be sequential. |
| **#890** | **edward** | Per-column gradient normalization pre-NS — equalize per-neuron contribution to NS orthogonalization. Cell B (col-absorbed MLP-only) PRIMARY. | ★ **Cell A=3.2612, Cell B TERMINAL=3.2613 — PARITY (Δ+0.0001 < σ_single).** Cell C col-propagated step 222/3250 (~7%). Primary hypothesis fails; awaiting C/D/E to characterize directional signal. |
| **#887** | **askeladd** | AGC-Muon — adaptive gradient clipping pre-NS (NFNet ‖g‖_F/‖W‖_F ≤ λ). Cell B (λ=0.01 MLP-only) PRIMARY. | Cell A=3.26163 done, Cell B=3.26298 done (NEG), **Cell C λ=0.001 step 1022/3250 (31.5%).** Cells D/E queued. |
| **#873** | **alphonse** | MARS gradient variance reduction for Muon — g_vr = g + γ×(g − g_prev). | ★ **Cell A=3.26072, Cell B γ=0.10=3.25990 (−2.23σ_single, second-strongest n=1 post-#699!), Cell C γ=0.30=3.26193, Cell D γ=0.50=3.26606. Cell E (γ=0.30 MLP-only) step 1513/3250 (46.6%).** n=4 gate decision pending full sweep. |
| **#840** | **nezuko** | Muon-AdEMAMix n=4 confirm (β₃=0.99, α=0.3, MLP-only). | **Trial 1=3.261360, Trial 2=3.260956. n=2 mean=3.261158. Trial 3 step 8593/13003 (~66%). n=4 gate (μ≤3.259221) very unlikely based on n=2.** |
| **#823** | **fern** | SignMuon — sign-transform Nesterov momentum before NS. | Cell A n=4=3.26226 (parity), Cell B n=4=3.26153 (NEG). **Cell C (sign all) n=2/4 partial: T0=3.26057, T1=3.26096, μ=3.260765 (Δ=−0.000456 vs baseline, σ=0.000276 tight). Trial 3 in flight.** Falls short of n=4 gate but BEST n=2 signal in programme — sign-of-momentum on ALL body matrices pre-NS may help. |

## Key Signals (as of poll #519)

- **#873 cell B (MARS γ=0.10) = 3.25990** — Sub-baseline by 0.00132 (−2.23σ_single). If cell E also runs and full sweep terminal lands, assess for n=4 confirm. Mechanism candidate: MARS gradient-diff sharpens gradient estimate, reducing effective noise before NS.
- **#890 cell B (per-col-norm MLP PRIMARY) imminent terminal** — cell A ctrl=3.26121 (parity). If cell B beats ctrl significantly, this would be a fresh sub-baseline signal with clear geometric mechanism.
- **#840 n=4 confirm** — n=2 mean=3.261158, gate at 3.259221. Trials 3+4 must average ≤3.257284 to clear gate — extremely unlikely. Expect this to close clean-NEG once n=4 finishes.

## Recent Closures (poll #519)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#855 tanjiro** (poll #519) | clean-NEG | Schedule-Free Muon: U-shaped harm with sf_beta (A=3.26226 ctrl best, E=3.27411 worst). ramp_down LR makes terminal x_T the bottom of trajectory; z_T includes high-loss early iterates → z_T > x_T structurally. +25-29% step-time overhead. |
| **#867 thorfinn** (poll #516) | clean-NEG | Pre-NS Cautious Muon: best treatment cell E=3.26112 at parity with ctrl A=3.26094. SOAP eigenbasis already concentrates signal; residual sign-disagreement is structural not noise. Cautious family FULLY CLOSED (#844 post-NS destructive, #867 pre-NS null). |
| **#859 frieren** (poll #512) | clean-NEG | GrokFast-Muon: monotonic worsening with λ. NS extracts spectral signal optimally; τ≈50 steps too short for grokking. Frequency-domain pre-NS amplification axis closed. |

## Closed Axis Map (comprehensive)

**AdamW-kernel modifications (8/8):** ALL CLOSED.
**Schedule layer (5/5 dims):** ALL CLOSED (cosine, linear, warmup, cooldown, SF — #659/SF-AdamW CLOSED, #855/SF-Muon CLOSED).
**Per-group HPs (LR, β1, β2, ε):** ALL CLOSED.
**Init magnitude:** ALL CLOSED (lm_head zero-init, residual-proj musoft, embed subsumed, gains identity, transformations).
**NS polynomial + iterations:** CLOSED (#824 polynomial, #815 warmup schedule, #776 RMS-clamp).
**Outer-loop wrappers:** CLOSED (#826 Lookahead, #844/#867 Cautious).
**Frequency domain pre-NS:** CLOSED (#859 GrokFast).
**Sign direction:** CLOSED (#844 post-NS, #867 pre-NS). #823 sign-Muon pre-NS (different formulation) still in flight.

**Open pre-NS gradient-transformation portfolio:** top-k (#902), Q/K/V consensus (#905), per-col-norm (#890), AGC (#887), MARS (#873), AdEMAMix (#840).
**Open schedule-state portfolio:** momentum reset at cooldown onset (#907, NEW).
