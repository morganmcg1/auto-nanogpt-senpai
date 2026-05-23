# SENPAI Research State — auto-nanogpt-1gpu-r5

- **Last updated:** 2026-05-23 ~17:45Z (poll #542) — **#887 askeladd AGC CLOSED clean-WEAK-NEG (Cell C λ=0.001 mlp=3.26071, −0.86σ, misses n=4 gate by 4×). askeladd → #936 Asymmetric SOAP eigenbasis ablation. 10 PRs in flight.**

## CURRENT BASELINE (PR #699 MERGED poll #378)

**μ=3.261221, σ=0.000593, n=4, ffs_mean=3025** (ALL 4 trials at ffs=3025)

- **Mandatory flags:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft`
- **Statsig rule:** `(3.261221 - μ) × √n ≥ 0.004`
- **n=4 gate: μ ≤ 3.259221** (merge) | **μ > 3.261** (close clean-NEG, tentative)
- *Gate requires ~2σ_single improvement — significantly harder than pre-#699 gate*

## Active WIP Portfolio (poll #542)

10 PRs in flight, all students active, no idle students.

| PR # | Student | Hypothesis | Phase / Status |
|:----:|:-------:|:-----------|:---------------|
| **#936** | **askeladd** | ★ **NEW poll #542.** Asymmetric SOAP eigenbasis ablation — test which side of SOAP's eigenbasis rotation (left=Q_row, right=Q_col) is load-bearing. If left-only matches full SOAP, output-space preconditioning is sufficient. Novel diagnostic experiment. | Just assigned. 5-cell: A ctrl, B left-only ★, C right-only, D left MLP-only, E right MLP-only. |
| **#932** | **thorfinn** | Per-layer NS iteration count scaled by transformer depth. depth_scale=0.5 → early=3 iters..late=9 iters, mean=6. Budget-neutral. | Just assigned. Cell A ctrl running. B-E queued. |
| **#925** | **fern** | Muon momentum coefficient μ schedule: drop from 0.95→0.85 at cooldown onset (step 975). | 5-cell sweep underway. |
| **#924** | **nezuko** | Free Hutchinson diagonal curvature scaling post-NS. EMA of gradient differences ≈ diagonal H. Cell B hutch_alpha=0.5 mlp-only. | 5-cell sweep underway. |
| **#914** | **alphonse** | SOAP eigenbasis refresh freeze during cooldown (steps 975–3250). | Cell A ctrl running. B-E queued. |
| **#907** | **tanjiro** | Muon momentum buffer zero/partial reset at cooldown onset (step 975). Cell B zero-reset. | Ctrl=3.261094, Cell B in progress. C-E queued. |
| **#902** | **frieren** | Top-k% gradient magnitude sparsification pre-NS. Cell B k=50% MLP-only. | Multi-cell running. |
| **#890** | **edward** | Per-column gradient normalization pre-NS. Cell D col-abs-all running. | A=3.2612 parity, B=3.2613 parity, C=3.3660 STRONG NEG. Cell D in progress. |

## Key Signals (as of poll #542)

- **#936 askeladd asymmetric SOAP** — Fresh diagnostic axis. Result will reveal whether SOAP's gain comes from left-eigenbasis (output-space curvature) or right-eigenbasis (input-space curvature) or both. High information value regardless of whether it beats baseline.
- **#932 thorfinn per-layer NS iter** — Tests NS iteration allocation across depth. Depth-scale=0.5 (early=3, late=9). Budget-neutral.
- **#925 fern μ-schedule / #907 tanjiro zero-reset** — Parallel cooldown-momentum axis. Complementary formulations of the same mechanism.
- **#924 nezuko Hutchinson post-NS curvature** — First post-NS curvature-conditioning axis.
- **#914 alphonse SOAP refresh freeze** — Preconditioner-dynamics axis.
- **#890 edward cell D** — Col-absorbed-all still running. Pattern so far: A/B parity, C strong NEG → likely axis is WEAK-NEG.

## Recent Closures (poll #534–542)

| PR | Close type | Key finding |
|:--:|:----------:|:------------|
| **#887 askeladd** (poll #542) | clean-WEAK-NEG | AGC-Muon: Cell C λ=0.001 mlp=3.26071 (−0.86σ, n=1). clipped_frac=1 → mechanism reduces to implicit MLP LR shrink. Confounded with already-tuned lr_mlp. Pre-NS gradient transformation axis fully saturated. |
| **#905 thorfinn** (poll #537) | clean-NEG | Q/K/V gradient consensus: Cell B α=0.10 = +9.4σ NEG. Q/K/V near-orthogonal in param space — blending destroys projection-specific information. |
| **#823 fern** (poll #534) | clean-NEG | SignMuon: n=4 mean=3.261930 (+0.709σ). Sign-direction axis closed. |
| **#840 nezuko** (poll #534) | clean-WEAK-NEG | AdEMAMix n=4 mean=3.260675 (−0.92σ, statsig=0.001 vs gate 0.004). |
| **#873 alphonse** (poll #526) | clean-WEAK-NEG | MARS VR: 3.25990 (−1.38σ at n=1). |

## Closed Axis Map (comprehensive)

**AdamW-kernel modifications (8/8):** ALL CLOSED.
**Schedule layer (5/5 dims):** ALL CLOSED.
**Per-group HPs (LR, β1, β2, ε):** ALL CLOSED.
**Init magnitude:** ALL CLOSED.
**NS polynomial + iterations:** CLOSED (#824, #815, #776). **Per-layer NS iter** open (#932).
**Outer-loop wrappers:** CLOSED (#826, #844/#867 Cautious).
**Frequency domain pre-NS:** CLOSED (#859 GrokFast).
**Sign direction:** FULLY CLOSED (#844, #867, #823).
**SOAP trust threshold:** CLOSED (#467, neutral).
**Pre-NS gradient transformation (fully saturated):** top-k (#902 in flight), per-col-norm (#890 in flight), AGC #887 WEAK-NEG, MARS #873 WEAK-NEG, AdEMAMix #840 WEAK-NEG, Q/K/V consensus #905 STRONG NEG, sign-Muon #823 NEG, GrokFast #859 NEG.

**Open novel axes (active):**
- Post-NS curvature conditioning (#924 Hutchinson)
- Momentum scheduling at cooldown (#925 μ-drop, #907 zero-reset)
- Preconditioner dynamics (#914 SOAP refresh freeze)
- Per-layer NS iteration allocation (#932 depth-scale)
- **SOAP eigenbasis side ablation (#936) — which side is load-bearing?**
