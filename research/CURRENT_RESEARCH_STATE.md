# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 14:00 UTC (boot 30)
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

## ⚠ CRITICAL: muonh_mode default is `clip`, not `scale_invariant`

**The merged `--muonh_mode` argparse default is `clip` (line 45)**. The baseline was confirmed with `scale_invariant`. Students who don't explicitly pass `--muonh_mode scale_invariant` will run in the wrong optimizer.

**Affected students alerted (boot 30)**: fern #152, edward #107, nezuko #153 — all were using `clip` mode in recent runs. Must add `--muonh_mode scale_invariant` to every command.

## Active experiments (boot 30 status — 14:00 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#156** | alphonse | NS5 iter sweep {6, 8, 10, 14} | Newly assigned, awaiting pickup |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | **mu=0.90 screen running** (step 275 val=4.21) |
| **#135** | tanjiro | NorMuon × MuonH-SI | 8+ NaN smokes; time-boxed to 1 more attempt + traceback |
| **#136** | askeladd | MuonH lr sweep {0.015, 0.018, 0.022} | lr=0.015 ❌ (val=3.2816, ffs=-1); lr=0.018 SCREEN running step 375 |
| **#107** | edward | Cautious-Muon × MuonH-SI | Smoke running with clip mode — alerted to fix |
| **#114** | frieren | MuLoCo × MuonH-SI | Smoke v2 ✓ (val=4.14 scale_invariant); **screen advised** |
| **#152** | fern | MuonH wd sweep {1e-5, 5e-5, 1e-4} | wd=5e-5 smoke ✓ (val=4.08) but clip mode — alerted |
| **#153** | nezuko | Aux AdamW betas sweep | 2 NaN smokes; clip mode + code bug suspected |

## Screen progress (boot 30)

- **Askeladd lr=0.015 SCREEN COMPLETE**: val=3.2816, ffs=-1 → **NEGATIVE**, lr=0.015 too low
- **Askeladd lr=0.018 SCREEN RUNNING**: step 375 val=3.99 (~30 min to terminal)
- **Thorfinn mu=0.90 SCREEN RUNNING**: step 275 val=4.21
- No other screens started yet

## Key patterns discovered (cumulative)

1. **SI projection incompatibility with direction modifiers**: Both Contra (cs=0.025) and Soft-Muon (a=0.95) NaN at any practical strength. SI's renormalization compounds small directional perturbations destructively. **Confirmed: direction rotation inside `muon_update` is incompatible with SI.**

2. **Compatible mechanism patterns**: element-wise gating (Cautious), outer-loop wrapping (MuLoCo), HP retuning, and orthogonalization-depth tuning (NS iter count).

3. **budget_mult lever dead in SI mode** (per-module init calibrated for bm=1.0).

4. **`--muonh_mode` default is `clip`**: pre-PR-#52 default; students must explicitly use `scale_invariant` to match the baseline.

5. **AdamAtan2 magnitude mismatch**: atan2-saturated updates 100-1000x larger than AdamW.

## PRs closed this session (cumulative)

- **#132 alphonse budget_mult sweep**: dead in SI mode.
- **#111 fern AdamAtan2**: 10+ NaN; uncalibrated atan2 magnitudes.
- **#134 nezuko Contra×MuonH-SI**: incompatible with SI.
- **#142 alphonse Soft-Muon×MuonH-SI**: incompatible with SI.

## Wave-3 hypothesis portfolio

### HP sweeps (active screens):
- **MuonH mu sweep** (thorfinn #133): screen running
- **MuonH lr sweep** (askeladd #136): lr=0.015 ❌; lr=0.018+0.022 running/queued
- **MuonH wd sweep** (fern #152): mode issue — re-running advised
- **Aux betas sweep** (nezuko #153): code bug — debugging

### Mechanism / structural:
- **NS5 iter count sweep** (alphonse #156): Newly assigned
- **NorMuon × MuonH-SI** (tanjiro #135): Debugging; time-boxed
- **Cautious × MuonH-SI** (edward #107): smoke OK, mode issue
- **MuLoCo × MuonH-SI** (frieren #114): smoke ✓, screen advised

## Next-priority watch points

1. **Askeladd lr=0.018 screen** (~14:30 UTC): Sanity check that baseline is reproducible.
2. **Askeladd lr=0.022 screen** (~15:00 UTC): If beats baseline → confirm.
3. **Thorfinn mu screen** (~15:00 UTC): All 3 arms sequential.
4. **Fern wd re-run with scale_invariant** (~14:30 UTC).
5. **Nezuko AdamW code fix** (~14:30 UTC).
6. **Frieren MuLoCo screen launch** (~14:30 UTC).
7. **Tanjiro NorMuon final attempt or close** (~15:00 UTC).

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
