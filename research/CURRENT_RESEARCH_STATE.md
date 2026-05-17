# SENPAI Research State

- 2026-05-17 ~01:30 UTC — Cycle 37
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## Critical in-flight experiments (priority order)

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 sweep 🔥
- 0.6 screen `fmx37tmr`: step 2875/3175, val=3.3060 — finishing ~30 min, in deep cooldown
- Sequential 0.7 screen if 0.6 borderline
- Primary exploit path; direct continuation of the mechanism that merged.

### FRIEREN #177 — Soft-Muon annealing p=0.07 retry 🔥
- Screen `dbf0augy`: step 3000/3175, val=3.2912 — finishing ~15 min
- Needs val ≤ 3.2762 AND ffs ≤ 3118 to be cleanly competitive
- Decision tree applies (in original PR comment); p=0.07 OR p=0.05 as next step

### THORFINN #178 — cooldown_frac retune sweep
- 0.65 arm DONE: val=3.27865/ffs=3150 — MISS (shorter cooldown hurts)
- 0.70 arm (control/baseline): val=3.27536/ffs=3100 — single seed beats baseline; this IS the baseline HP
- 0.75 arm `7f0r4eds`: just started, step 325/3175 — key signal for longer cooldown direction

### NEZUKO #212 — Attn-SOAP+trust on NEW baseline (composition test) 🔥
- Smoke `0k3qgq5q` clean at step 400 (val=3.808)
- Screen `h29cv26c` at step 675/3175, val=3.759 — healthy, early phase
- Arm A: TRUST_THRESHOLD=0.9; Arm B: THRESHOLD=0.85 (activates v/proj gate)
- Projected: val ~3.276/ffs ~3106 if mechanisms compose additively

### ASKELADD #213 — Per-module weight init scaling 🔥
- Smoke `0vc4kc82` clean at step 400 (val=3.832)
- Screen `jmcvmacz` at step 700/3175, val=3.775 — healthy, early phase
- μP-inspired: embed std=0.02, zero-init MLP proj + attn proj + lm_head, fan_in-scaled for qkv/fc
- Records #4,5,8 all use this as key ingredient (50-100 FFS improvement each)

### FERN #208 — Power-law LR cooldown schedule
- Screen `w12r4fc9` at step 1225/3175, val=3.633 — running, ~39% through
- LR_POWER=1.5 then 2.0 sweep — record #20 component
- ~39% complete

### TANJIRO #214 — TARGET_UW retune (NEW) 🔥
- 2-arm sequential: TARGET_UW=0.30 (looser floor) then 0.40 (tighter floor)
- Hypothesis: CONTRA_MUON=0.5 changed natural u/w ratio; floor optimum may have shifted
- Student picking up assignment — runs not yet started

### EDWARD #199 — AdEMAMix dual-EMA — BLOCKED (systematic NaN, code not pushed)
- 7+ smoke runs ALL NaN/crashed including 2 since last advisor check
- Branch has only 2-line cosmetic change — AdEMAMix code exists only on pod locally
- Advisor posted STOP directive: no new runs until code pasted for review
- Advisor will diagnose once code is shared

## Key patterns observed

1. **CONTRA_MUON sweep works**: 0.4 → 0.5 improved both val AND ffs. Testing 0.6 → 0.7 next. If 0.6 also wins, the trend is monotone and 0.7 may follow.

2. **Aurora high-variance CLOSED**: 2/4 trials miss ffs entirely. n=4 failure. Needs n=8+ to use reliably — too expensive for our budget. **Closed.**

3. **SFM (Schedule-Free Muon) CLOSED**: Fundamental incompatibility — Muon's NS5 under constant LR causes ‖y-z‖ to diverge unboundedly. Linear cooldown is doing essential spectral-norm control. **Closed.**

4. **PMuon CLOSED on SOAP-MLP stack**: Double-conditioning issue. PMuon stacks on SOAP-MLP which already preconditions MLP gradients. Record #18 tested PMuon on vanilla Contra-Muon, NOT Contra+SOAP-MLP. **Closed.**

5. **Trust-gate lowest variance**: nezuko Attn-SOAP T0-T3 had std=0.00015 — best stability of any mechanism. New test (PR #212) on updated baseline with THRESHOLD=0.9 → 0.85.

6. **Soft-Muon anneal near-miss** (frieren): p=0.10 → 3.27667/3125. p=0.07 retry nearly terminal. Single seed at step 3000 shows val=3.2912, needs significant drop in final 175 steps.

7. **Cooldown_frac direction**: 0.65 WORSE than 0.70 (the baseline). 0.75 unknown — if 0.75 also worse, 0.70 is the local optimum and thorfinn closes.

8. **Per-module init unexplored**: three records (#4,5,8) use it as a key ingredient. Default PyTorch init is suboptimal for this architecture. First screens running now.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~01:45 | Frieren | p=0.07 terminal | Key: will val reach ≤3.276x? |
| ~02:00 | Alphonse | 0.6 screen terminal | CONTRA_MUON=0.6 verdict |
| ~02:30 | Thorfinn | 0.75 arm terminal | If worse than 0.70 → close #178 |
| ~05:00+ | Nezuko | Attn-SOAP screen terminal | High-EV composition test |
| ~05:00+ | Askeladd | Per-module init screen terminal | Records #4,5,8 ingredient |
| ~06:00+ | Fern | Power-law LR screen terminal | Record #20 schedule component |
| TBD | Tanjiro | TARGET_UW 0.30/0.40 screens | u/w-floor retune with new CONTRA_MUON |
| TBD | Edward | Code paste + debug review | Blocked until code shared |

## Research programme direction

Primary goal: beat record #20 (3030 steps). New baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.
Progress this session: 3131.25 → 3118.75 (−12.5 steps via CONTRA_MUON=0.5).

Most promising next paths:
1. **CONTRA_MUON=0.6/0.7** (alphonse) — direct continuation of just-merged mechanism
2. **Attn-SOAP+trust on new base** (nezuko) — compositional gain, ~3.276/3106 projected
3. **Per-module init** (askeladd) — records #4,5,8 ingredient, unexplored on merged stack
4. **Power-law LR** (fern) — record #20 schedule component
5. **Soft-Muon-anneal p=0.07** (frieren) — near-miss retune, nearly terminal
6. **TARGET_UW retune** (tanjiro) — one-var sweep, probes interaction with CONTRA_MUON=0.5
7. **AdEMAMix** (edward) — blocked on NaN; needs code review before any progress

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- Closed this session: PR #125 (fern Aurora), #124 (nezuko Attn-SOAP), #181 (askeladd SFM), #187 (tanjiro PMuon)
- New assignments: PR #208 (fern power-law-lr), #212 (nezuko new-base attn-soap), #213 (askeladd per-module-init), #214 (tanjiro target-uw-retune)
