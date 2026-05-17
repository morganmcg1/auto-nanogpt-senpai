# SENPAI Research State

- 2026-05-17 00:05 UTC — Fern PR #125 (Aurora) closed FAIL, reassigned to PR #208 (Power-law LR). No human issues.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Statsig bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

(Previous baseline PR #78: mean=3.27760, ffs=3131.25)

## Critical in-flight experiments (priority order)

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 sweep 🔥
- Arm A: CONTRA_MUON=0.6 — run `fmx37tmr` at step ~400, val=3.898 (very early)
- Sequential 0.6 → 0.7 if 0.6 is borderline
- ETA screen terminal ~5h. Primary exploit path.

### THORFINN #178 — cooldown_frac retune (0.65/0.75 arms)
- 0.70 arm DONE: val=3.27536/ffs=3100 (single seed)
- 0.65 arm `lhmwiphi`: running at step ~125 (launched ~23:43 UTC)
- Real signal from non-default cooldown_frac in these arms

### TANJIRO #187 — PMuon screen `eafhrglu` — in cooldown
- Step ~2150/3175 val=3.425 at last pulse — entering cooldown
- ETA terminal ~00:45 UTC. Comparison target: val < 3.27648 AND ffs < 3118.75

### FRIEREN #177 — Soft-Muon annealing p=0.07 retry
- Screen `dhqwygng` FINISHED: val=3.27667/ffs=3125 (near-miss vs new baseline by 0.00019 val / 6.25 ffs)
- New retry `6j9nqglk` at step ~100, val=10.83 in warmup (no NaN this time)
- ETA new p=0.07 screen terminal ~01:30 UTC

### ASKELADD #181 — SFM c_const=0.01 fallback screen `k3wkjy84`
- Step ~2400/3175 val=4.687 — DIVERGED. Not converging toward 3.28.
- ETA terminal ~01:00 UTC — will close + reassign with pivot away from Schedule-Free direction
- c_const=0.1 and c_const=0.01 both diverged → SFM class is broken here

### NEZUKO #124 — Attn-SOAP + trust gate n=4 `790h1llo` — T3 running
- T0=3.27743/3125, T1=3.27750/3125, T2=3.27758/3125
- T3 at step 12478 val=3.296 — will hit 3.28 target, but mean=~3.277x fails new baseline 3.27648
- Close when SENPAI-RESULT posted; trust-gate mechanism sound but needs stronger base

### EDWARD #199 — AdEMAMix dual-EMA on aux groups — STUCK (systematic NaN)
- 4+ smoke runs ALL diverged with 148M nonfinite gradients — systematic config failure
- Debug guidance posted: check alpha=1.0 first, verify β3 warmup, check m2 initialization
- No screens until clean 400-step smoke

### FERN #208 — Power-law LR cooldown schedule (NEW) 🔥
- LR_POWER=1.5 then 2.0 sweep — one-line change, no variance risk
- Directly targeting record #20's "power-law LR" component
- Student picking up next poll cycle

## Key patterns observed

1. **CONTRA_MUON sweep works**: 0.4 → 0.5 improved both val AND ffs. Testing 0.6 → 0.7 next.

2. **Aurora high-variance**: T0/T2/T3 all beat new baseline individually, but T1 catastrophic miss → n=4 mean fails. Need n=8+ or variance-reduction wrap.

3. **SFM (Schedule-Free Muon) is broken**: Both c_t=uniform and c_const=0.01 diverge. Closed direction.

4. **Trust-gate variance suppression** (nezuko): variance ~0.00015 — lowest of any mechanism. Will stack on future baseline.

5. **Soft-Muon anneal near-miss** (frieren): p=0.10 → 3.27667/3125 (miss by 0.00019 val). p=0.07 retry in flight.

6. **Power-law LR** (fern): Orthogonal to all in-flight work, directly from record #20 structure. Low-variance.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~00:20 | Nezuko | T3 terminal → close PR #124 | MISS → close + reassign |
| ~00:45 | Tanjiro | PMuon screen terminal | Open — bilateral power preconditioning |
| ~01:00 | Askeladd | c_const=0.01 screen terminal | MISS → close + reassign (pivot away from SFM) |
| ~01:30 | Frieren | p=0.07 retry screen | Near-miss follow-up |
| ~02:00 | Thorfinn | 0.65 arm terminal | FFS signal |
| ~05:00 | Alphonse | 0.6 screen terminal | Key CONTRA_MUON trend test |
| TBD | Fern | Power-law LR smoke + screen | Low-variance schedule test |
| TBD | Edward | Debug AdEMAMix NaN | Need clean 400-step smoke first |

## Research programme direction

No human researcher directives this session.

Primary goal: beat record #20 (3030 steps). New baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

Progress this session: 3131.25 → 3118.75 (−12.5 steps in one merge).

Most promising next paths:
1. **CONTRA_MUON=0.6/0.7** (alphonse) — direct continuation of just-merged mechanism
2. **Power-law LR** (fern) — record #20 ingredient, orthogonal to everything
3. **Soft-Muon-anneal p=0.07** (frieren) — mechanism near-miss, one tweak from baseline
4. **Thorfinn cooldown_frac=0.65** — real signal from non-default cooldown
5. **Tanjiro PMuon** — bilateral power preconditioning, new mechanism class
6. **Nezuko trust-gate** — stack on future stronger baseline
7. **AdEMAMix fix** (edward) — aux-group path unexplored if NaN resolved

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient vs new baseline)
