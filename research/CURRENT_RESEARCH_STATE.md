# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~15:30Z (poll #534) — **#840 and #823 CLOSED. nezuko→#924 (Hutchinson post-NS), fern→#925 (μ schedule). 10 PRs in flight.** Pre-NS gradient-transformation axis saturated (sign-Muon, AdEMAMix, MARS, per-col-norm, AGC all weak/NEG). Opening post-NS curvature axis (#924 Hutchinson) and momentum-scheduling axis (#925 μ-drop, parallel to #907 zero-reset).

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling enables gradient flow through each block from step 1.

## Active WIP Portfolio (poll #534)

10 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#925** | **fern** | ★ **NEW poll #534.** Muon momentum coefficient μ schedule: drop from 0.95→0.85 at cooldown onset (step 975). Soft momentum damping complement to #907 zero-reset. Cell B μ_cd=0.85 PRIMARY. | Just assigned. 5-cell sweep: A ctrl, B μ_cd=0.85 ★, C μ_cd=0.80, D μ_cd=0.90, E linear ramp. |
| **#924** | **nezuko** | ★ **NEW poll #534.** Free Hutchinson diagonal curvature scaling post-NS — scale NS output by inverse EMA of gradient-difference magnitude per element (zero compute overhead). Post-NS axis, novel. Cell B hutch_alpha=0.5 mlp-only PRIMARY. | Just assigned. 5-cell sweep: A ctrl, B α=0.5 mlp ★, C α=0.25, D α=0.75, E all-scope. |
| **#914** | **alphonse** | SOAP eigenbasis refresh freeze during cooldown — slow/freeze preconditioner refresh during cooldown (steps 975–3250). | Cell A ctrl running step 1263/3250 (~39%). B-E queued. |
| **#907** | **tanjiro** | Muon momentum buffer zero/partial reset at cooldown onset (step 975). Cell B zero-reset PRIMARY. | Ctrl=3.261094, Cell B mu_reset_zero_975 running step 974/3250 (~30%). C-E queued. |
| **#905** | **thorfinn** | Q/K/V gradient consensus per layer before NS. Cell B α=0.10 PRIMARY. | Ctrl A=3.260773. Cell B α=0.10 running step 1957/3250 (~60%). C-E queued. |
| **#902** | **frieren** | Top-k% gradient magnitude sparsification pre-NS. Cell B k=50% MLP-only PRIMARY. | Ctrl=3.261079. Cell B top50-mlp step 2472/3250 (~76%). C-E queued. |
| **#890** | **edward** | Per-column gradient normalization pre-NS. Cell B (col-absorbed MLP-only) PRIMARY. | Cell A=3.2612, Cell B=3.2613 (PARITY), Cell C=3.3660 (STRONG NEG). Cell D col-abs-all step 1285/3250 (~40%). E queued. |
| **#887** | **askeladd** | AGC-Muon — adaptive gradient clipping pre-NS (NFNet ‖g‖_F/‖W‖_F ≤ λ). | Cell A=3.26163, Cell B=3.26298 (NEG), **Cell C λ=0.0001 mlp=3.260712 (−0.86σ, sub-baseline)**. Cell D attn lam=0.001 step 2632/3250 (~81%). Cell E queued. |

## Key Signals (as of poll #534)

- **#887 cell C AGC λ=0.0001 mlp=3.260712** — Sub-baseline by 0.000509 (−0.86σ_single). Cell D attn still running. If pattern holds across remaining cells, may indicate very weak AGC signal. No n=4 confirm expected unless a stronger cell emerges.
- **#905 thorfinn ctrl=3.260773** — Strong ctrl, slightly sub-baseline. Cell B α=0.10 treatment in mid-flight. If treatment beats ctrl, QKV consensus could be a real signal.
- **#902 frieren top50-mlp step 76%** — Treatment mid-flight. Pre-NS magnitude sparsification at 50% could discard noise or discard signal — result pending.
- **Pre-NS axis saturated.** sign-Muon #823 clean-NEG, AdEMAMix #840 clean-WEAK-NEG, MARS #873 clean-WEAK-NEG, per-col-norm #890 parity/NEG, AGC #887 weak signal. New axes: post-NS curvature (#924), μ schedule (#925), preconditioner dynamics (#914), cooldown momentum reset (#907).

## Recent Closures (poll #534)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#823 fern** (poll #534) | clean-NEG | SignMuon all-body-matrices: n=4 mean=3.261930 (+0.709σ above baseline). Early n=2 partial sub-baseline signal was downward fluctuation; T3/T4 degraded. Sign-direction axis comprehensively closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 confirm (Cell E mlp-only, β₃=0.99, α=0.3): n=4 mean=3.260675 (−0.92σ_single, statsig=0.00109 vs gate 0.004). First n=4 sub-baseline post-#699 but misses gate. n=8 extension unlikely to clear gate. |
| **#873 alphonse** (poll #526) | clean-WEAK-NEG | MARS gradient VR: Cell B γ=0.10=3.25990 (−1.38σ_single). Concave-up γ curve; P(n=4 gate clear) ~1-8%. Pre-NS transformation axis saturating. |
| **#855 tanjiro** (poll #519) | clean-NEG | Schedule-Free Muon: ramp_down LR + Polyak averaging structurally incompatible. z_T > x_T always. |

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
