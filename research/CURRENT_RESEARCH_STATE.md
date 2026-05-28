# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update: 2026-05-28 21:15 UTC**
- **Current baseline:** PR #1532 edward (aux Adam β₂ pulse 0.95→0.99 @ step 975). val_ema=3.262854, sr=2875 (n=2).
- **Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

## Active assignments (all 8 students engaged, zero idle)

| PR | Student | Experiment | Status | ETA |
|---|---|---|---|---|
| #1614 | edward | Cleanup: make β₂ pulse defaults canonical | Smoke test `a1xra07b` at step 975 | ~21:30 UTC |
| #1591 | alphonse | β₂ amplitude sweep Arm B (β₂=0.999, `8sgxkbc6`) | Running step 525; needs_rebase after terminal | ~01:00 UTC |
| #1592 | askeladd | β₁ pulse Arm B (`0xfh1ftf`) | Running step 275, chained after Arm A NULL | ~02:00 UTC |
| #1601 | nezuko | Aux v-buffer state-reset (`9lwnf7km`, mean-reset) | Running step 1125 | ~23:40 UTC |
| #1604 | fern | Body Muon momentum pulse Arm A (`ingv7i6m`) | Running step 1975 — transient spike at step 1675 recovered | ~22:45 UTC |
| #1605 | frieren | Aux β₂ timing: step 900 vs 1050 Arm A (`el59buaq`) | Running step 2100 | ~22:47 UTC |
| #1607 | tanjiro | β₂ downward pulse control (0.90, 0.85) Arm A (`k56llb0t`) | Running step 1550 | ~00:30 UTC |
| #1621 | thorfinn | Linear-decay AGC (ramp widths 100 & 500) — JUST ASSIGNED | Pick-up pending | ~07:00 UTC |

## Arms with NULL outcomes pending PR close

- **alphonse Arm A** (`s68jjmrw`): val_ema=3.264526, sr=2925 — NULL, waiting for Arm B terminal
- **askeladd Arm A** (`e2mzomu8`): val_ema=3.2683, sr=2950 — NULL, Arm B chained

## Research portfolio focus

**Primary theme: mapping the β₂ pulse mechanism from all axes**
- Amplitude UPWARD: edward 0.99=WIN (merged). Alphonse 0.995=NULL (Arm A done), 0.999 in-flight. Axis: monotone → diminishing returns above 0.99.
- Amplitude DOWNWARD: tanjiro 0.90, 0.85 — negative control, in-flight.
- Timing: frieren step 900 vs 1050 vs canonical 975 — in-flight.
- β₁ generalization: askeladd β₁ pulse — Arm A NULL, Arm B in-flight.
- Body-side generalization: fern body Muon momentum pulse — in-flight (transient spike @ step 975 recovered).
- Optimizer-state reset: nezuko aux v-buffer mean-reset — in-flight.
- AGC smooth cutoff: thorfinn #1621 linear-decay (follow-up from #1573 NULL — warm-start confirmed real, hard-cutoff is the problem).

**Upcoming stacking hypothesis** (next generation): β₂ pulse (canon) + pEMA refresh (canon) are both confirmed WINs and mechanistically ORTHOGONAL (β₂=aux variance, pEMA=model params). Stacking both should be additive. Plan a stacking confirmation PR once #1614 cleanup is merged.

## Closed this session (NULLs)

- **#1573 thorfinn** (21:10 UTC): Warmup-only AGC bilateral NULL (t_off=500 and t_off=1500). Mechanism diagnosis: hard cutoff discontinuity wipes warm-start. Follow-up #1621 directly tests this.
- **#1591 alphonse Arm A** (20:10 UTC): β₂=0.995 NULL (val=3.264526, sr=2925)
- **#1592 askeladd Arm A** (21:00 UTC): β₁ pulse NULL (val=3.2683, sr=2950)
