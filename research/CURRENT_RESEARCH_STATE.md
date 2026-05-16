# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 13:30 UTC (boot 29)
- **Most recent human-team directive:** None (no open GH issues).
- **Branch state:** PR #52 MuonH-SI MERGED. Baseline: val=3.27737, ffs=3275 (n=4, deterministic). Wave-3 cascade active — 8 students assigned.

## Current branch baseline (MuonH-SI, PR #52)

| Metric | Value |
|--------|-------|
| `val/loss` | **3.27737** (n=4 mean) |
| `ffs` | **3275** (n=4 mean = min = max — deterministic) |
| stat margin | `(3.28 - 3.27737) × √4 = 0.00526` ✓ |
| Optimizer | MuonH (lr=0.018, mu=0.95, wd=0, mode=scale_invariant, budget_mult=1.0) + aux AdamW(betas=(0.8, 0.95)) |
| Per-module init | attn.proj=0.026, mlp.proj=0.031, mlp.fc=0.031 |
| Cooldown | MuonH=1.0 (full linear), aux=0.4 |
| NS5 | 12 iterations, (a,b,c)=(2,-1.5,0.5) in bf16 |

## Active experiments (boot 29 status — 13:30 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#156** | alphonse | NS5 iteration count sweep {6, 8, 10, 14} | Newly assigned; #142 closed |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | All 3 smokes ✓; **screen advised, launching** |
| **#135** | tanjiro | NorMuon × MuonH-SI | NaN at step 3-20 in all smokes; debug diagnostics sent |
| **#136** | askeladd | MuonH lr sweep {0.015, 0.018, 0.022} | lr=0.015 screen step=3275 val=3.2834; 50 steps to finish; lr=0.022 smoke ✓ |
| **#107** | edward | Cautious-Muon × MuonH-SI | Smoke ✓ (val=4.50 step 300); pushed rebase |
| **#114** | frieren | MuLoCo × MuonH-SI | Smoke v2 ✓ (val=4.14 step 300); screen not started |
| **#152** | fern | MuonH-SI weight decay sweep {1e-5, 5e-5, 1e-4} | wd=5e-4 smoke ✓ (val=4.17); **screen advised** |
| **#153** | nezuko | Aux AdamW betas sweep {(0.9,0.99), (0.95,0.99), (0.9,0.98)} | (0.9,0.99) NaN at step 300 — code bug likely; diagnostic sent |

## Screen progress

- **Askeladd #136 lr=0.015 screen** at step 3275 val=3.2834 (running, ~50 steps to terminal). val=3.2834 is ABOVE baseline 3.27737 — likely won't beat baseline.
- No other g1r3 screens running yet; thorfinn and fern advised to launch.

## Key patterns discovered (boots 28-29)

1. **SI projection incompatibility with direction modifiers**: Both Contra (nezuko #134) and Soft-Muon (alphonse #142) NaN at any practical strength inside `muon_update`. The mechanism: SI's renormalization compounds small directional perturbations destructively. **Confirmed: element-wise gating (Cautious, edward #107) and outer-loop wrapping (MuLoCo, frieren #114) are compatible. Direction rotation inside muon_update is not.**

2. **budget_mult lever dead in SI mode** (#132 alphonse closed): per-module init calibrated for bm=1.0; ±20% NaN within 150 steps.

3. **AdamAtan2 magnitude mismatch** (#111 fern closed): atan2-saturated updates 100-1000x larger than AdamW; aux-lr calibration required but too costly to iterate.

## PRs closed this boot (boot 29)

- **#142 alphonse Soft-Muon × MuonH-SI**: a=0.85 AND a=0.95 NaN. Same incompatibility as Contra × SI. Pattern confirmed: direction-modifier × SI = NaN.

## Wave-3 hypothesis portfolio

### HP sweeps (active):
- **MuonH mu sweep** (thorfinn #133): Smokes ✓; screen launching
- **MuonH lr sweep** (askeladd #136): Screen lr=0.015 running (likely negative)
- **MuonH wd sweep** (fern #152): Smoke ✓; screen launching
- **Aux betas sweep** (nezuko #153): Code bug causing NaN — debugging

### Mechanism / structural:
- **NS5 iter count sweep** (alphonse #156): Newly assigned
- **NorMuon × MuonH-SI** (tanjiro #135): Debugging NaN at step 3-5
- **Cautious-Muon × MuonH-SI** (edward #107): Smoke ✓; screen expected soon
- **MuLoCo × MuonH-SI** (frieren #114): Smoke ✓; screen expected soon

## Incompatible mechanisms (do not retry these patterns)

- Contra rotation (Contra-Muon, CS=0.025) × SI
- Soft-Muon interpolation (alpha=0.95) × SI
- budget_mult ≠ 1.0 × SI

## Next-priority watch points

1. **Askeladd #136 lr=0.015 terminal** (~14:00 UTC): Final val. If > 3.277 → close as negative, lr=0.018 confirmed optimal.
2. **Thorfinn #133 mu screen** (~16:00 UTC): 3 arms × 3325 steps; best arm to n=4 confirm.
3. **Fern #152 wd screen** (~16:30 UTC): 3 arms × 3325 steps.
4. **Tanjiro #135 NorMuon debug** (~14:00 UTC): High-priority if clears — both NorMuon and MuonH-SI individually confirmed positive.
5. **Edward #107 screen** (~14:30 UTC): After smoke push.

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
