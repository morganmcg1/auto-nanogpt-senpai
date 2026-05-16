# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 15:55 UTC (boot 38)
- **Most recent human-team directive:** None.
- **Branch state:** PR #52 MuonH-SI MERGED. Baseline: val=3.27737, ffs=3275 (n=4, deterministic).

## Current branch baseline (MuonH-SI, PR #52)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27737** (n=4 mean) |
| `ffs` | **3275** (deterministic) |
| Optimizer | MuonH (lr=0.018, mu=0.95, wd=0, **mode=scale_invariant**, budget_mult=1.0) + aux AdamW(betas=(0.8, 0.95)) |
| Per-module init | attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5) in bf16 |

## INFRA ESCALATION: 3 broken pods (Issue #164)

**3 of 8 student pods (37.5%) are broken** with deterministic NaN-cascade on the unmodified merged baseline:

- **g1r3-tanjiro** (node ge29808, PR #135 closed) — 10+ NaN smokes, grad=0 throughout
- **g1r3-nezuko** (node ge2b558, PR #153 closed) — screen NaN'd at step 125, grad=0
- **g1r3-alphonse** (node ge2b5f0, 4 restarts in 5h59m, PR #156 closed) — both smokes NaN at step 25

Same failure signature as r4-tanjiro (Issue #160): bit-identical step 1 with healthy pods, then `grad_norm=0` + NaN at every event after. Holding all 3 assignments until GPU rotation.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

The merged `--muonh_mode` argparse default is `clip` (line 45). Baseline was confirmed with `scale_invariant`. Boot 30 alerts went to fern #152, edward #107, nezuko #153 (closed). Active screens all use `--muonh_mode scale_invariant`.

## ⭐ WINNER CANDIDATE (boot 38) — frieren MuLoCo × MuonH-SI

**Screen result (n=1)**: val=**3.27566**, ffs=3275 (run g3fpjabh)
**Baseline**: val=3.27737, ffs=3275
**Δval**: **-0.00171** (better)

**n=4 confirm requested** at 15:55 UTC. Expected ~5 hours. Config: muonh_lr=0.018, scale_invariant, budget_mult=1.0, muloco_outer_lr=0.7, muloco_outer_momentum=0.5, muloco_sync_interval=30.

## Active experiments (boot 38 status — 15:55 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | mu=0.90 ❌ (val=3.29361, ffs=-1); **mu=0.95 SCREEN step 1925/3325 val=3.51** |
| **#136** | askeladd | MuonH lr sweep {0.015, 0.018, 0.022} | lr=0.015 ❌; lr=0.018 ✓ baseline-clone (val=3.27833); **lr=0.022 SCREEN step 2150/3325 val=3.49** |
| **#114** | frieren | MuLoCo × MuonH-SI | **SCREEN ✓ val=3.27566 < baseline → CONFIRM n=4 requested** |
| **#107** | edward | Cautious-Muon × MuonH-SI | SCREEN ❌ (val=3.30450, ffs=-1) → cs threshold sweep suggested |
| **#152** | fern | MuonH wd sweep | wd=1e-5 ❌ baseline-clone (val=3.27850); **wd=5e-5 SCREEN step 1150/3325 val=3.66** |

## Screen progress (boot 38)

- **askeladd lr=0.018 TERMINAL**: val=3.27833, ffs=3300 → baseline-clone (within seed variance)
- **askeladd lr=0.022 RUNNING**: step 2150/3325 val=3.491 (~25 min to terminal)
- **thorfinn mu=0.90 TERMINAL**: val=3.29361, ffs=-1 → **NEGATIVE**
- **thorfinn mu=0.95 RUNNING**: step 1925/3325 val=3.510 (~30 min to terminal, baseline-clone)
- **fern wd=1e-5 TERMINAL**: val=3.27850, ffs=3300 → baseline-clone (no effect from light wd in SI)
- **fern wd=5e-5 RUNNING**: step 1150/3325 val=3.66 (~60 min to terminal)
- **frieren MuLoCo TERMINAL**: val=3.27566 → **POTENTIAL WIN** (n=4 confirm requested)
- **edward cautious-muon TERMINAL**: val=3.30450, ffs=-1 → **NEGATIVE** (cs threshold sweep suggested)

## Earlier results (boot 30-32)

- **askeladd lr=0.015 SCREEN**: val=3.2816, ffs=-1 → **NEGATIVE** (lr too low)
- **fern wd=5e-5 smoke**: val=4.08 (clip mode, re-running at scale_invariant)
- **frieren MuLoCo smoke v2**: val=4.14 scale_invariant ✓

## Key patterns discovered (cumulative)

1. **SI projection incompatibility with direction modifiers**: Both Contra (cs=0.025) and Soft-Muon (a=0.95) NaN at any practical strength.
2. **Compatible mechanism patterns**: element-wise gating (Cautious), outer-loop wrapping (MuLoCo), HP retuning, and orthogonalization-depth tuning (NS iter count).
3. **budget_mult lever dead in SI mode** (per-module init calibrated for bm=1.0).
4. **`--muonh_mode` default is `clip`**: pre-PR-#52 default; students must explicitly use `scale_invariant`.
5. **AdamAtan2 magnitude mismatch**: atan2-saturated updates 100-1000x larger than AdamW.
6. **Pod heterogeneity**: 3 of 8 r3 pods (tanjiro, nezuko, alphonse) fail at the merged baseline. Diagnostic — `grad/global_norm=0` from step 25, bit-identical step 1 with healthy pods. Same signature as r4-tanjiro (Issue #160).

## PRs closed this session (cumulative)

- **#132 alphonse budget_mult sweep**: dead in SI mode.
- **#111 fern AdamAtan2**: 10+ NaN; uncalibrated atan2 magnitudes.
- **#134 nezuko Contra×MuonH-SI**: incompatible with SI.
- **#142 alphonse Soft-Muon×MuonH-SI**: incompatible with SI.
- **#135 tanjiro NorMuon×MuonH-SI**: pod-infra-broken, inconclusive.
- **#153 nezuko aux betas**: pod-infra-broken, inconclusive.
- **#156 alphonse NS5 iter**: pod-infra-broken, inconclusive.

## Held hypotheses (awaiting healthy pods)

- **g1r3-tanjiro**: NS5 polynomial coefficient sweep (alternative to NS iter count)
- **g1r3-nezuko**: aux cooldown_frac sweep
- **g1r3-alphonse**: NS5 iter sweep (resume on healthy pod)

## Next-priority watch points

1. **Frieren n=4 confirm** (~21:00 UTC): If μ < 3.27737 → MERGE as new baseline (val=3.275 territory)
2. **Askeladd lr=0.022 terminal** (~16:20 UTC): If val < 3.27737 → confirm. May supersede frieren.
3. **Thorfinn mu=0.95 terminal** (~16:25 UTC): baseline-clone validation.
4. **Fern wd=5e-5 terminal** (~16:50 UTC): then wd=1e-4 arm.
5. **Edward cs threshold sweep** (~17:00 UTC if launched): cautious-muon variants.

## Operational notes

- 5 of 8 students have active healthy WIP PRs (askeladd, thorfinn, fern, frieren, edward).
- 3 students (tanjiro, nezuko, alphonse) on hold pending infra rotation per Issue #164.
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
