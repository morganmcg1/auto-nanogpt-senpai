# SENPAI Research State

- 2026-05-17 00:35 UTC — PR #124 (nezuko Attn-SOAP) + PR #181 (askeladd SFM) CLOSED. Reassigned: nezuko → PR #212 (Attn-SOAP on new base), askeladd → PR #213 (per-module init).

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## Critical in-flight experiments (priority order)

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 sweep 🔥
- CONTRA_MUON=0.6 screen `fmx37tmr` — early (step ~400 at last pulse, ETA terminal ~05:00 UTC)
- Sequential 0.6 → 0.7 if 0.6 borderline
- Primary exploit path; direct continuation of the mechanism that merged.

### THORFINN #178 — cooldown_frac retune (0.65/0.75 arms)
- 0.70 arm DONE (control): val=3.27536/ffs=3100 — single seed beats new baseline
- 0.65 arm `lhmwiphi`: running, step ~125 at last pulse
- Real signal from non-default cooldown_frac

### TANJIRO #187 — PMuon screen `eafhrglu` (stale_wip)
- Step ~2150/3175, val=3.425 at last pulse — entering cooldown
- ETA terminal ~01:00 UTC
- Stale_wip flag set by harness; run is healthy

### FRIEREN #177 — Soft-Muon annealing p=0.07 retry
- Screen `dhqwygng` (p=0.10): val=3.27667/ffs=3125 — near-miss by 0.00019 val / 6.25 ffs
- New retry `6j9nqglk` running at step ~100 at last pulse
- ETA terminal ~01:30 UTC

### EDWARD #199 — AdEMAMix dual-EMA on aux groups — STUCK (systematic NaN)
- 4+ smoke runs ALL diverged with 148M nonfinite gradients
- Debug guidance posted: try α=1.0, slower warmup, possibly halve aux LR
- No screens until clean 400-step smoke

### NEZUKO #212 — Attn-SOAP+trust on NEW baseline (NEW) 🔥
- Attn-SOAP+trust on CONTRA_MUON=0.5 base (composition test)
- Arm A: TRUST_THRESHOLD=0.9; Arm B: THRESHOLD=0.85 (activates v/proj)
- Projected: val ~3.276/ffs ~3106 if mechanisms compose additively

### ASKELADD #213 — Per-module weight init scaling (NEW) 🔥
- μP-inspired: embed std=0.02, zero-init MLP proj + attn proj + lm_head, fan_in-scaled for qkv/fc
- Records #4,5,8 all use this as key ingredient (50-100 FFS improvement each)
- Not yet combined with Contra+SOAP-MLP stack

### FERN #208 — Power-law LR cooldown schedule
- LR_POWER=1.5 then 2.0 sweep — one-line change
- Directly targeting record #20's "power-law LR" component
- Student picking up assignment

## Key patterns observed

1. **CONTRA_MUON sweep works**: 0.4 → 0.5 improved both val AND ffs. Testing 0.6 → 0.7 next.

2. **Aurora high-variance**: T0/T2/T3 beat new baseline individually, T1 catastrophic miss. n=4 fails. Needs n=8+ to use reliably.

3. **SFM (Schedule-Free Muon) CLOSED**: Fundamental incompatibility — Muon's O(1) spectral updates under constant LR means y-z diverges unboundedly. Linear cooldown is doing essential work.

4. **Trust-gate lowest variance**: nezuko T0-T2 had std=0.00015 — best stability of any mechanism. v/proj gate essentially always OFF at threshold=0.9. Lowering to 0.85 is the obvious next lever.

5. **Soft-Muon anneal near-miss** (frieren): p=0.10 → 3.27667/3125. p=0.07 retry in flight.

6. **Per-module init unexplored**: three records (#4,5,8) use it as a key ingredient. Default PyTorch init is suboptimal for this architecture.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~01:00 | Tanjiro | PMuon screen terminal | Open — bilateral power preconditioning |
| ~01:30 | Frieren | p=0.07 retry screen | Near-miss follow-up |
| ~02:00 | Thorfinn | 0.65 arm terminal | FFS signal from non-default cooldown |
| ~05:00 | Alphonse | 0.6 screen terminal | Key CONTRA_MUON=0.6 test |
| TBD | Nezuko | Attn-SOAP new base smoke + screen | High-EV composition test |
| TBD | Askeladd | Per-module init smoke + screen | Records #4,5,8 ingredient |
| TBD | Fern | Power-law LR smoke + screen | Record #20 schedule component |
| TBD | Edward | Debug AdEMAMix NaN | Need clean 400-step smoke first |

## Research programme direction

No human researcher directives this session.

Primary goal: beat record #20 (3030 steps). New baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

Progress this session: 3131.25 → 3118.75 (−12.5 steps via CONTRA_MUON=0.5).

Most promising next paths:
1. **CONTRA_MUON=0.6/0.7** (alphonse) — direct continuation of just-merged mechanism
2. **Attn-SOAP+trust on new base** (nezuko) — compositional gain, ~3.276/3106 projected
3. **Per-module init** (askeladd) — records #4,5,8 ingredient, unexplored on merged stack
4. **Power-law LR** (fern) — record #20 schedule component
5. **Soft-Muon-anneal p=0.07** (frieren) — near-miss retune
6. **Thorfinn cooldown_frac=0.65** — FFS signal from schedule tuning
7. **AdEMAMix** (edward) — aux-group path if NaN resolved

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
