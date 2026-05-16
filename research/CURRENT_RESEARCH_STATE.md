# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 14:35 UTC (boot 33)
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

## Active experiments (boot 33 status — 14:35 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | **mu=0.90 SCREEN step 2175/3325 val=3.453** |
| **#136** | askeladd | MuonH lr sweep {0.015, 0.018, 0.022} | **lr=0.018 SCREEN step 2250/3325 val=3.443** |
| **#114** | frieren | MuLoCo × MuonH-SI | **SCREEN step 360/3325 val=4.19** |
| **#107** | edward | Cautious-Muon × MuonH-SI | **SCREEN step 175/3325 val=5.24** |
| **#152** | fern | MuonH wd sweep | **wd=1e-5 SCREEN step 1400/3325 val=3.60**; wd=5e-4 smoke healthy |

## Screen progress (boot 33)

- **askeladd lr=0.018 SCREEN**: step 2250/3325 val=3.443 — on baseline trajectory, ~25 min to terminal
- **thorfinn mu=0.90 SCREEN**: step 2175/3325 val=3.453 — slightly behind baseline trajectory, ~28 min to terminal
- **fern wd=1e-5 SCREEN**: step 1400/3325 val=3.604 — on track, ~52 min to terminal
- **frieren MuLoCo SCREEN**: step 360/3325 val=4.19 — early, ~75 min to terminal
- **edward cautious-muon SCREEN**: step 175/3325 val=5.24 — early, ~85 min to terminal

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

1. **Askeladd lr=0.018 screen** (~15:00 UTC): Sanity check baseline reproducibility on her pod.
2. **Askeladd lr=0.022 screen launch** (~15:00 UTC): Critical — IF beats baseline → confirm.
3. **Thorfinn mu=0.90 screen** (~15:05 UTC): Then mu=0.98 arm.
4. **Fern wd=1e-5 screen** (~15:30 UTC): then wd=5e-5, wd=1e-4 arms.
5. **Edward cautious-muon screen** (~16:00 UTC): mechanism stack.
6. **Frieren MuLoCo screen** (~15:50 UTC): mechanism stack.

## Operational notes

- 5 of 8 students have active healthy WIP PRs (askeladd, thorfinn, fern, frieren, edward).
- 3 students (tanjiro, nezuko, alphonse) on hold pending infra rotation per Issue #164.
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
