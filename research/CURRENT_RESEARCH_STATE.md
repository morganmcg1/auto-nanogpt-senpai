# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~16:30Z (poll #537) — **#905 thorfinn Q/K/V consensus CLOSED clean-NEG (Cell B α=0.10 = +9.4σ NEG). thorfinn → #932 per-layer NS iter by depth. 10 PRs in flight.**

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

**What changed in #699:** Block residual-injection paths initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling enables gradient flow through each block from step 1.

## Active WIP Portfolio (poll #537)

10 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#932** | **thorfinn** | ★ **NEW poll #537.** Per-layer NS iteration count scaled by transformer depth. Early layers (well-conditioned) fewer iters, late layers (ill-conditioned) more. `ns_iter_depth_scale` float param: 0.5→early=3..late=9, mean=6. Budget-neutral. | Just assigned. 5-cell sweep: A ctrl, B depth_scale=0.5 ★, C 1.0, D −0.5 (inverted), E 0.5 MLP-only. |
| **#925** | **fern** | ★ **NEW poll #534.** Muon momentum coefficient μ schedule: drop from 0.95→0.85 at cooldown onset (step 975). Soft momentum damping complement to #907 zero-reset. Cell B μ_cd=0.85 PRIMARY. | Just assigned at poll #534. 5-cell sweep: A ctrl, B μ_cd=0.85 ★, C μ_cd=0.80, D μ_cd=0.90, E linear ramp. |
| **#924** | **nezuko** | ★ **NEW poll #534.** Free Hutchinson diagonal curvature scaling post-NS — scale NS output by inverse EMA of gradient-difference magnitude per element (zero compute overhead). Post-NS axis, novel. Cell B hutch_alpha=0.5 mlp-only PRIMARY. | Just assigned at poll #534. 5-cell sweep: A ctrl, B α=0.5 mlp ★, C α=0.25, D α=0.75, E all-scope. |
| **#914** | **alphonse** | SOAP eigenbasis refresh freeze during cooldown — slow/freeze preconditioner refresh during cooldown (steps 975–3250). | Cell A ctrl running. B-E queued. |
| **#907** | **tanjiro** | Muon momentum buffer zero/partial reset at cooldown onset (step 975). Cell B zero-reset PRIMARY. | Ctrl=3.261094, Cell B mu_reset_zero_975 in progress. C-E queued. |
| **#902** | **frieren** | Top-k% gradient magnitude sparsification pre-NS. Cell B k=50% MLP-only PRIMARY. | Ctrl=3.261079. Cell B top50-mlp terminal imminent. Cell C top75-mlp recently launched. D-E queued. |
| **#890** | **edward** | Per-column gradient normalization pre-NS. Cell B (col-absorbed MLP-only) PRIMARY. | Cell A=3.2612, Cell B=3.2613 (PARITY), Cell C=3.3660 (STRONG NEG). Cell D col-abs-all running. E queued. |
| **#887** | **askeladd** | AGC-Muon — adaptive gradient clipping pre-NS (NFNet ‖g‖_F/‖W‖_F ≤ λ). | Cell C λ=0.0001 mlp=3.260712 (−0.86σ). Cell D attn lam=0.001 terminal imminent. Cell E queued. |

## Key Signals (as of poll #537)

- **#932 thorfinn per-layer NS iter** — Just assigned. Depth-axis hypothesis: late layers have higher NS condition numbers. If true, reallocating iter budget from early→late layers should improve orthogonalization quality at no compute cost. First test of NS-iteration allocation as an axis.
- **#925 fern μ-schedule / #907 tanjiro zero-reset** — Parallel momentum-at-cooldown axis. Both testing whether dampening momentum state at cooldown onset improves performance. Complementary formulations.
- **#924 nezuko Hutchinson post-NS curvature** — First post-NS curvature-conditioning axis. Novel mechanism: EMA of gradient differences approximates diagonal Hessian, scaling NS output by inverse curvature. Zero overhead.
- **#914 alphonse SOAP refresh freeze** — Preconditioner-dynamics axis: does slowing eigenbasis refresh during cooldown (when gradients are noisier) improve stability?
- **#887 cell C AGC λ=0.0001 mlp=3.260712** — Sub-baseline by 0.000509 (−0.86σ_single). Cell D attn still running. Weak signal pattern.
- **Pre-NS axis saturated.** sign-Muon #823 clean-NEG, AdEMAMix #840 clean-WEAK-NEG, MARS #873 clean-WEAK-NEG, per-col-norm #890 parity/NEG, AGC #887 weak, top-k #902 pending, Q/K/V consensus #905 STRONG NEG.

## Recent Closures (poll #534–537)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V gradient consensus: Cell B α=0.10 = +9.4σ NEG. Q/K/V projections are near-orthogonal in parameter space; consensus blend destroys per-projection information. Q/K/V independence is structurally load-bearing. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon all-body-matrices: n=4 mean=3.261930 (+0.709σ above baseline). Sign-direction axis comprehensively closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 confirm (Cell E mlp-only, β₃=0.99, α=0.3): n=4 mean=3.260675 (−0.92σ_single, statsig=0.00109 vs gate 0.004). First n=4 sub-baseline post-#699 but misses gate. |
| **#873 alphonse** (poll #526) | clean-WEAK-NEG | MARS gradient VR: Cell B γ=0.10=3.25990 (−1.38σ_single). Concave-up γ curve; P(n=4 gate clear) ~1-8%. |
| **#855 tanjiro** (poll #519) | clean-NEG | Schedule-Free Muon: ramp_down LR + Polyak averaging structurally incompatible. |

## Closed Axis Map (comprehensive)

**AdamW-kernel modifications (8/8):** ALL CLOSED.
**Schedule layer (5/5 dims):** ALL CLOSED (cosine, linear, warmup, cooldown, SF — #659/SF-AdamW CLOSED, #855/SF-Muon CLOSED).
**Per-group HPs (LR, β1, β2, ε):** ALL CLOSED.
**Init magnitude:** ALL CLOSED (lm_head zero-init, residual-proj musoft, embed subsumed, gains identity, transformations).
**NS polynomial + iterations:** CLOSED (#824 polynomial, #815 warmup schedule, #776 RMS-clamp). **Per-layer NS iter** open (#932).
**Outer-loop wrappers:** CLOSED (#826 Lookahead, #844/#867 Cautious).
**Frequency domain pre-NS:** CLOSED (#859 GrokFast).
**Sign direction:** FULLY CLOSED (#844 post-NS, #867 pre-NS, #823 sign-of-momentum pre-NS).
**Pre-NS gradient transformation axis (largely saturated):** top-k (#902 pending), per-col-norm (#890 parity/NEG), AGC (#887 weak), MARS (#873 weak-NEG), AdEMAMix (#840 weak-NEG), Q/K/V consensus (#905 STRONG NEG).

**Open axes (active):**
- Post-NS curvature conditioning (#924 Hutchinson)
- Momentum scheduling at cooldown (#925 μ-drop, #907 zero-reset — parallel)
- Preconditioner dynamics (#914 SOAP refresh freeze)
- Per-layer NS iteration allocation (#932 depth-scale)
