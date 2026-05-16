# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 17:30 UTC (boot 43)
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

Same failure signature as r4-tanjiro (Issue #160). Holding all 3 assignments until GPU rotation. No human response on Issue #164 yet.

## ⚠ Operational gotcha: muonh_mode default is `clip`, not `scale_invariant`

The merged `--muonh_mode` argparse default is `clip` (line 45). Baseline was confirmed with `scale_invariant`. Active screens all use `--muonh_mode scale_invariant`.

## ⭐ WINNER CANDIDATE (boot 38) — frieren MuLoCo × MuonH-SI

**n=4 confirm IN PROGRESS** (run 22tmupqh): step 2000/3325 trial 1 of 4, val=3.50 (mid-training).
**Screen result (n=1)**: val=**3.27566**, ffs=3275. **Baseline**: val=3.27737, ffs=3275. **Δval**: **-0.00171** (better).

Config: muonh_lr=0.018, scale_invariant, budget_mult=1.0, muloco_outer_lr=0.7, muloco_outer_momentum=0.5, muloco_sync_interval=30.

**Expected confirmation**: ~21:00 UTC (3 more hours).

## Active experiments (boot 43 — 17:30 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | mu=0.90 ❌; mu=0.95 baseline-clone; **mu=0.98 RUNNING step 375/3325 val=4.034** (~2hr ETA) |
| **#114** | frieren | MuLoCo × MuonH-SI | **n=4 CONFIRM RUNNING step 2000/3325 trial 1** (~3hr ETA) |
| **#107** | edward | Cautious-Muon cs sweep {0.0, 0.1, 0.25} | cs=0.0 RUNNING step 1175/3325 val=3.663; cs=0.1 and cs=0.25 queued |
| **#152** | fern | MuonH wd sweep {1e-5, 5e-5, 1e-4} | wd=1e-5 baseline-clone; **wd=5e-5 RUNNING step 2988/3325 val=3.335 (final ~15 min)**; wd=1e-4 queued |
| **#174** | askeladd | NS5 polynomial coefficient sweep | **NEWLY ASSIGNED** — smoke A1 (3.4445,-4.7750,2.0315) then 3-arm screen |

## Closed this session (boot 43)

- **#136 askeladd lr sweep**: CLOSED NEGATIVE. All 3 arms: lr=0.015 ❌ (3.28156), lr=0.018 = baseline-clone (3.27833), lr=0.022 ❌ (3.28097). U-shape confirms lr=0.018 near-optimal.

## Earlier results (boot 30-43)

- **askeladd lr=0.015 SCREEN**: val=3.2816, ffs=-1 → **NEGATIVE** (lr too low)
- **askeladd lr=0.018 SCREEN**: val=3.27833, ffs=3300 → baseline-clone
- **askeladd lr=0.022 SCREEN**: val=3.28097, ffs=-1 → **NEGATIVE** (overshoots)
- **thorfinn mu=0.90 SCREEN**: val=3.29361, ffs=-1 → **NEGATIVE**
- **thorfinn mu=0.95 SCREEN**: val=3.27828, ffs=3300 → baseline-clone
- **fern wd=1e-5 SCREEN**: val=3.27850, ffs=3300 → baseline-clone (SI projection immune to light wd)
- **frieren MuLoCo screen**: val=3.27566, ffs=3275 → **POTENTIAL WIN** (n=4 confirm in progress)
- **edward cautious cs=0.5 SCREEN**: val=3.30450, ffs=-1 → **NEGATIVE** (too aggressive)
- **edward cautious cs=0.25 SMOKE**: val=4.256 @ step 300 → healthy

## Key patterns discovered (cumulative)

1. **SI projection incompatibility with direction modifiers**: Both Contra (cs=0.025) and Soft-Muon (a=0.95) NaN at any practical strength.
2. **Compatible mechanism patterns**: element-wise gating (Cautious, testing), outer-loop wrapping (MuLoCo, winner candidate), HP retuning, orthogonalization-depth tuning.
3. **budget_mult lever dead in SI mode** (per-module init calibrated for bm=1.0).
4. **`--muonh_mode` default is `clip`**: baseline uses scale_invariant. Gotcha caught at boots 30/38.
5. **AdamAtan2 magnitude mismatch**: atan2-saturated updates 100-1000x larger than AdamW.
6. **Pod heterogeneity**: 3 of 8 r3 pods broken. Holding all 3 idle per Issue #164 protocol.
7. **lr near-optimal**: lr=0.018 confirmed best in ±20% range (U-shape centered here, boot 43).
8. **Outer-loop wrappers work with SI**: MuLoCo outer Nesterov over MuonH-SI gives val=3.27566. Direction modifiers (Contra, Soft-Muon) NaN; outer wrappers (MuLoCo) work cleanly.

## Next-priority watch points

1. **Fern wd=5e-5 terminal** (~17:45 UTC): project NEGATIVE (val=3.335 @ step 2988). Then launch wd=1e-4.
2. **Thorfinn mu=0.98 terminal** (~19:30 UTC): if val < 3.277 → n=4 confirm. If baseline-clone → close #133.
3. **Edward cs=0.0 terminal** (~18:00 UTC): cs=0.0 is vanilla baseline-clone control. Then cs=0.1 and cs=0.25.
4. **Frieren n=4 confirm** (~21:00 UTC): If μ < 3.27737 → MERGE as new baseline.
5. **Askeladd NS5 coef smoke** (#174): A1=(3.4445,-4.7750,2.0315) smoke first, then 3-arm screen.

## Operational notes

- Active students (5): askeladd (#174, new), thorfinn (#133), fern (#152), frieren (#114), edward (#107).
- Idle (broken pods): tanjiro, nezuko, alphonse — awaiting infra rotation per Issue #164.
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
