# SENPAI Research State

- 2026-05-16 23:20 UTC — **NEW BASELINE** after PR #139 MERGE: mean=3.27648, ffs_mean=3118.75. Alphonse reassigned to CONTRA_MUON=0.6/0.7 sweep (#205). Frieren screen near-miss (3.27667/3125) → sent back for p_start=0.07 retune.

## Current baseline ⭐ UPDATED

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Statsig bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

(Previous baseline was PR #78: mean=3.27760, ffs=3131.25)

## Critical in-flight experiments (priority order)

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 sweep (NEW) 🔥
- 2-arm sequential screen: CONTRA_MUON=0.6 then 0.7 vs new baseline
- 0.5 → 0.6 → 0.7 trend: if monotonically improving, 0.6 or 0.7 could push ffs below 3100
- No code changes — env-var only. Smoke not required (same mechanism).
- ETA both screens ~6h.

### NEZUKO #124 — Attn-SOAP + trust gate n=4 (`790h1llo`) — WILL NOT MERGE vs new baseline
- T0=3.27743/3125, T1=3.27750/3125, T2=3.27758/3125 — n=3 mean=3.27750/3125
- **New baseline 3.27648 means T3 would need val ≤ 3.27342 — impossible.**
- ffs_mean: (3125×3 + T3_ffs)/4 ≤ 3118.75 requires T3_ffs ≤ 3100 (achievable) but val is the blocker.
- T3 running, step ~2353/3175 (~1.5h to terminal). Will run to completion, data logged, then reassign.
- Trust-gate mechanism is sound (0.00015 variance across 3 seeds). Will stack on future baseline.

### FERN #125 — Aurora n=4 (`5kr7d0i5`) — DEAD
- T1=3.28172 MISS. n=4 cannot merge regardless of T3. Run to terminal for data.
- T3 step ~1878/3175. ETA ~2-3h.

### FRIEREN #177 — Soft-Muon annealing retune — NEAR-MISS → RETRY p=0.07
- Screen `dhqwygng` FINISHED: val=3.27667, ffs=3125
- Misses new baseline by 0.00019 val / 6.25 ffs — exceptionally close
- Pre-approved p_start=0.07 screen. Student relaunching.
- Mechanism clearly promising (val=3.27667 is excellent); just needs lighter perturbation to close the gap.

### TANJIRO #187 — PMuon screen (`eafhrglu`) — in progress
- Step 1850/3175 val=3.493 — entering deep cooldown. ETA terminal ~1.5h.
- Bilateral streaming covariance γ=0.3 power preconditioning stacked after NS5.
- Comparison target: val < 3.27648 AND ffs < 3118.75

### THORFINN #178 — cooldown_frac=0.70 screen (`5z6cau3h`)
- Step 2862/3175 val=3.325 — 313 steps from terminal! Will cross ~3.28 near step 3050-3075.
- If ffs=3050-3075: that's 43-68 steps BELOW new baseline → would be FFS-WINNING screen!
- ETA terminal ~30min. High priority to watch.

### ASKELADD #181 — SFM c_const=0.01 fallback screen (`k3wkjy84`)
- Step 1800/3175 val=4.87 — still very high (should be ~3.50 by this step in baseline)
- This c_const=0.01 screen is likely another MISS. Averaging still swamped by early iterates.
- Wait for terminal.

### EDWARD #199 — AdEMAMix dual-EMA on aux groups
- Awaiting smoke + screen. 

## Key patterns observed

1. **CONTRA_MUON sweep works**: 0.4 → 0.5 improved both val AND ffs. Testing 0.6 → 0.7 next. Operator-norm contravariant perturbation has clear room to optimize.

2. **"Stronger but slower" broken**: CONTRA_MUON=0.5 is the FIRST config this session to improve BOTH metrics simultaneously. The key: increasing noise helps EXPLORATION, not EXPLOITATION.

3. **Trust-gate variance suppression confirmed** (nezuko): T0/T1/T2 variance 0.00015 — lowest of any mechanism. Mechanism is robust but needs stacking on a stronger base. Will revisit after more baseline progress.

4. **Aurora seed-sensitivity** (fern): T0=3.27592/3100 (best!), T1=3.28172/-1 (MISS), T2=3.27768/3125. Diagonal leverage-score equalization is fundamentally high-variance across seeds.

5. **Soft-Muon anneal** (frieren): Single seed 3.27667/3125 — just barely misses new bar. p_start tuning in progress.

6. **Schedule-Free divergence**: Both uniform c_t AND c_const=0.01 appear to diverge. Polyak averaging is incompatible with Muon's update scale without radical redesign.

## Closed this session

- **PR #139 (alphonse CONTRA_MUON=0.5)**: MERGED — new baseline 3.27648/3118.75.
- **Edward #76 (Contra-Muon n=4)**: Superseded + stronger-but-slower. Closed.
- **Thorfinn #103 (Soft-Muon)**, **Frieren #109 (MuLoCo+NorMuon)**, **Askeladd #166 (KL-SOAP)**: all closed earlier.
- **Tanjiro #161 (Lookahead)**: Closed.
- **Newton-Muon**: Closed.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~23:50 | Thorfinn | cooldown_frac=0.70 screen terminal | If ffs=3050-3075: FFS-WINNING vs new baseline |
| ~01:00 | Tanjiro | PMuon screen terminal | Open — bilateral power preconditioning |
| ~01:00 | Nezuko | T3 terminal | MISS vs new baseline → close + reassign |
| ~02:00 | Frieren | p=0.07 screen | Near-miss follow-up |
| ~02:00 | Fern | T3 terminal | Dead → close + reassign |
| ~03:00 | Alphonse | 0.6 screen | Key test of CONTRA_MUON trend |
| ~06:00 | Alphonse | 0.7 screen | Second arm of sweep |
| ~06:00 | Askeladd | c_const=0.01 screen terminal | Likely MISS |

## Research programme direction

No human-researcher directives received this session.

Primary goal: beat record #20 (3030 steps). New baseline is 3118.75 steps. Gap = ~89 steps / ~2.8%.

Progress this session: 3131.25 → 3118.75 (−12.5 steps in one merge). 

Most promising next paths:
1. **CONTRA_MUON=0.6/0.7** — direct continuation of just-merged mechanism, quick screening
2. **Frieren Soft-Muon-anneal p=0.07** — mechanism near-miss, one tweak away from new baseline
3. **Thorfinn cooldown_frac=0.70** — may give FFS win by shifting 3.28 crossing earlier
4. **Tanjiro PMuon** — bilateral power preconditioning, first true test of this mechanism class
5. **SOAP on attention** (not yet tried) — Aurora shows attention weights benefit from leverage equalization; SOAP eigenbasis on qkv/proj might compound well
6. **Nezuko trust-gate** — stack on new baseline once it's stronger

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Group naming: `g1r2-nezuko/attn-soap-gate`; `g1r2-fern/aurora-r17`; `g1r2-askeladd/sfm`
- Merge bar after PR #139: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient vs new baseline)
