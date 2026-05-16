# SENPAI Research State — auto-nanogpt-1gpu-r3

- **Last updated:** 2026-05-16 12:30 UTC (boot 28)
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

**Key MuonH-SI mechanism**: `scale_invariant_update_` rescales update to param's Frobenius-norm scale, takes gradient step (Nesterov momentum on NS5 output), renormalises param back to initial Frobenius norm.

## Active experiments (boot 28 status — 12:30 UTC)

| PR | Student | Lever | Status |
| --- | --- | --- | --- |
| **#142** | alphonse | Soft-Muon × MuonH-SI, alpha ∈ {0.85, 0.90, 0.95} | Smoke a=0.85 NaN; advised to try a=0.95 first |
| **#133** | thorfinn | MuonH mu sweep {0.90, 0.95, 0.98} | mu=0.98 smoke ✓ (val=4.20); mu=0.90 smoke running |
| **#135** | tanjiro | NorMuon × MuonH-SI (row/col preconditioning restored) | New smoke relaunched (step=0); prior attempt NaN at step 180 |
| **#136** | askeladd | MuonH-SI lr sweep {0.015, 0.018, 0.022} | **SCREEN RUNNING** lr=0.015 at step 1500 val=3.56 ✓ |
| **#107** | edward | Cautious-Muon × MuonH-SI (sign-agreement mask) | Smoke ✓ (val=4.36); nudged to push rebase |
| **#114** | frieren | MuLoCo × MuonH-SI | Smoke ✓ (val=4.07 step 300); screen not started |
| **#152** | fern | MuonH-SI weight decay sweep {0, 1e-5, 5e-5, 1e-4} | Newly assigned (#111 closed) |
| **#153** | nezuko | Aux AdamW betas sweep {(0.9,0.99), (0.95,0.99), (0.9,0.98)} | Newly assigned (#134 closed) |

## Screen progress

- **Askeladd #136 lr=0.015 SCREEN RUNNING** at step 1500 val=3.56 — on track.
- No other screens started yet for g1r3 wave-3.

## PRs closed this session (boots 23-28)

- **#132 alphonse budget_mult sweep**: bm=0.8 AND bm=1.2 both NaN at step 150. SI mode requires bm=1.0. Closed negative.
- **#111 fern AdamAtan2 aux**: 10+ NaN smokes over 7+ hours. Pristine baseline runs also NaN'd — pod state issues. Closed negative.
- **#134 nezuko Contra-Muon × MuonH-SI**: 6 NaN smokes. contra_strength=0.025 (1/4 of original) still NaN. Mechanism incompatible with SI projection. Informative negative.

## Key learnings (cumulative)

1. **`sample_tensor` OOB bug** fixed (`cc1c710`).
2. **Per-module init ordering matters** — must come after zero-proj branches.
3. **mbs=64 is fixed benchmark contract**.
4. **MuonH-SI ffs=3275 is deterministic** at n=4 — n=1 screens give clean signal.
5. **Contra mechanism incompatible with SI projection** at any practical contra_strength. Confirmed negative at both cs=0.1 and cs=0.025.
6. **budget_mult lever dead in SI mode** — per-module init calibrated for bm=1.0; ±20% NaN within 150 steps.
7. **AdamAtan2 magnitude mismatch**: atan2-saturated updates are 100-1000x larger than AdamW; requires careful aux-lr calibration.
8. **Closed negative directions**: Lion, init-only, mbs=32, cooldown-shape, u/w-floor, Sign-Muon, Polyak-EMA, MuLoCo standalone, budget_mult sweep, Contra×MuonH-SI, AdamAtan2.

## Wave-3 hypothesis portfolio (all on MuonH-SI base)

### HP sweeps (clean signal):
- **MuonH mu sweep** (thorfinn #133): {0.90, 0.95, 0.98} — smoking
- **MuonH lr sweep** (askeladd #136): {0.015, 0.018, 0.022} — **SCREEN lr=0.015 running**
- **MuonH wd sweep** (fern #152): {0, 1e-5, 5e-5, 1e-4} — newly assigned
- **Aux betas sweep** (nezuko #153): β₁/β₂ variants — newly assigned

### Mechanism stacks:
- **NorMuon × MuonH-SI** (tanjiro #135): restore row/col preconditioning — highest priority if clears
- **Cautious-Muon × MuonH-SI** (edward #107): sign-agreement mask — smoke healthy, needs push
- **MuLoCo × MuonH-SI** (frieren #114): outer Nesterov SGD wrapper — smoke healthy
- **Soft-Muon × MuonH-SI** (alphonse #142): alpha interpolation — a=0.85 NaN, try a=0.95

## Next-priority watch points

1. **Askeladd #136 lr screen terminal** (~14:00-15:00 UTC): If lr=0.015 clears val<3.277 → n=4 confirm.
2. **Thorfinn #133 mu screen launch** (~13:30-14:00 UTC): Once smokes done on all 3 arms.
3. **Tanjiro #135 smoke recovery** (~13:00 UTC): New smoke at step=0; prior was NaN at step 180.
4. **Edward #107 rebase push** (~13:00 UTC): Smoke healthy but branch not pushed yet.
5. **Alphonse #142 smoke a=0.95** (~13:30 UTC): After a=0.85 NaN; try 0.95 next.
6. **Fern #152 and nezuko #153 smoke pickups** (~13:30 UTC): New assignments from boot 28.

## Operational notes

- All 8 students have active WIP PRs. **Zero idle students.**
- Standard kill gates: NaN `val/loss` or `train/grad/global_norm > 1e3` → kill.
- Merge bar: `μ_val < 3.27737` at n=4, stat rule `(3.28 - μ) × √4 ≥ 0.004`.
- Banned reference sources: Prime Intellect autonomous-run materials.
