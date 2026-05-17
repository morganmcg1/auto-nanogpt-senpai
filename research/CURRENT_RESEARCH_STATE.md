# SENPAI Research State

- 2026-05-17 ~05:55 UTC — Cycle 43
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## 🚀 PROMOTED — n=4 CONFIRMATION RUNNING

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS 🔥🔥🔥
- **Screen B (T=0.85, `5g7k1w3q`): val=3.27475 (−0.00173 from baseline), ffs=3100 (−18.75)**
- Both bars CLEARED. Trust-gate activation table:
  - T=0.9 → v on 0%, proj on 17%, overall 35%
  - T=0.85 → v on 50%, proj on 100%, overall 87.5%
- Lowering threshold activated SOAP on v and proj exactly as PR #124 row-cosine analysis predicted
- **n=4 confirm launched 05:26 UTC** (`3xn3ox1c` first trial); ETA ~12:50 UTC (~440 min)
- Trial 1 healthy: step 700, val=3.7561, no NaN
- This is the strongest signal of the round — if n=4 mean clears both bars, MERGE

## Critical in-flight experiments

### FRIEREN #221 — Adam-style Muon momentum bias correction 🔥
- `6qb399cr`: step 2350/3175 (~74%), val=3.4099 — HEALTHY, on Screen B trajectory
- ETA terminal ~06:17 UTC
- IF val WIN + ffs ≤ 3118 → predeclare n=4

### FERN #208 — Power-law LR (LR_POWER=2.0 arm)
- `rpws9fug` (LR_POWER=1.5, CM=0.5): **MISS** — val=3.28240, ffs=−1 (never reached 3.28)
- `ersqpsq2` (LR_POWER=1.5, CM=0.4 default — misconfigured): MISS (auxiliary data)
- LR_POWER=2.0 + CM=0.5 launched 05:24 UTC; ETA terminal ~07:15 UTC
- LR_POWER=1.5 hurt baseline by ~0.006 val units; 2.0 is opposite-direction (front-loaded cooldown)

### THORFINN #219 — Annealed Muon momentum μ schedule
- 4 smokes ran (all 200 steps, val ≈4.18, MU=0.95 baseline; smokes were per-suggestion at no-anneal)
- **Arm A `uh2vhuu9` (MU_START=0.90→MU_END=0.97)**: step 1575/3175 (~50%), val=3.5325
- ETA Arm A terminal ~07:30 UTC; Arm B will run sequentially after

### ASKELADD #224 — Per-module init Variant B (std=0.00221)
- Student asked clarification on std value; advisor confirmed Option B (0.00221, literal)
- Predeclared single-arm screen; awaiting launch (set CONTRA_MUON=0.5 explicit)

### ALPHONSE #223 — SOAP_BETA2 retune {0.85, 0.92} — TROUBLE
- BOTH single-seed runs at 0.85 NaN'd:
  - `67w5zyph` (duplicate process) NaN at step 318
  - `6gsl9ljw` (proper) NaN at step 1175
- num_trials=4 retry `grpcqmun` launched 05:28 UTC, NaN at step 636 (trial 1 = seed 0)
- HYPOTHESIS: SOAP_BETA2=0.85 may genuinely destabilize the merged stack
- WAIT for trial 1 NaN to roll over to trial 2 (~step 3175). If trials 2-3 also NaN, SOAP_BETA2=0.85 is unstable → skip directly to 0.92 arm

### TANJIRO #214 — TARGET_UW retune — TROUBLE
- 0.30 single-seed: 3+ NaN crashes (8mz9zmp9, 5am2pvfi, 79uiiqxd, 46cilwf8, opmeshmi)
- num_trials=4 retry `y3lccflx` launched 05:25 UTC, NaN at step 750 (trial 1 = seed 0)
- Per advisor: NaN is seed-deterministic; wait for trial 2 to start
- IF all 4 NaN → close 0.30 arm, try 0.40 next

### EDWARD #199 — AdEMAMix aux groups — TROUBLE
- num_trials=4 retry `q2un2m4y` started 04:43 UTC, NaN at step 1225 (trial 1)
- Second run `65edtfli` started 05:29 UTC at step 12703 (cumulative; needs investigation) with NaN
- Multiple seeds NaN-ing → AdEMAMix may be amplifying baseline instability
- Decision pending: if all 4 trials NaN by step 50, close per pre-authorized tree

## Closed this session (cycle 41-42)
- PR #178 (thorfinn cooldown_frac) — 0.70 local optimum
- PR #177 (frieren soft-muon-anneal) — structural ffs miss
- PR #205 (alphonse CONTRA_MUON sweep) — 0.5 confirmed bowl optimum
- PR #213 (askeladd per-module init zero-init) — MISS by 0.004

## New assignments (cycle 41-42)
- PR #219 (thorfinn annealed-μ) — Arm A running
- PR #221 (frieren bias-corr-muon) — ETA terminal in <30 min
- PR #223 (alphonse SOAP_BETA2 retune) — 0.85 destabilizing
- PR #224 (askeladd proj-init Variant B) — student about to launch

## CONTRA_MUON axis — EXHAUSTED ⛔
- 0.4 (PR #78): merged, beaten
- **0.5 (PR #139): current baseline**
- 0.6: rising shoulder, tied within noise
- 0.7: NaN at step 25 (catastrophic divergence)
- Do NOT sweep CONTRA_MUON further.

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 is local optimum. EXHAUSTED axis.

2. **Attn-SOAP+trust trust-gate sensitivity** (nezuko #212): T=0.85 activates v/proj SOAP; T=0.9 doesn't. ROW COSINES for v live at 0.85-0.89 — natural threshold landing zone.

3. **Soft-Muon-anneal closed**: structural ffs miss at 3125. p_start insensitive.

4. **Per-module init zero-init absorbed by SOAP+NS5**: Variant B (small non-zero) about to test.

5. **Step-2 NaN seed-deterministic**: trial_idx=0 deterministically NaN-s. Use `--num_trials 4` for screens where mechanism is uncertain.

6. **MULTI-seed NaN cascade** (new this cycle): some HP changes (SOAP_BETA2=0.85, possibly TARGET_UW=0.30, possibly AdEMAMix) NaN across MULTIPLE seeds, not just seed 0. These are not seed-stability artifacts — they're genuine HP instabilities.

7. **cooldown_frac=0.70 confirmed**: 0.65 and 0.75 both worse.

8. **Power-law LR (LR_POWER=1.5)**: hurts by ~0.006 val units. LR_POWER=2.0 testing inverse-shape hypothesis.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~06:17 | Frieren | Bias-corr-muon `6qb399cr` terminal | val WIN + ffs ≤ 3118? → predeclare n=4 |
| ~07:15 | Fern | LR_POWER=2.0 terminal | Likely MISS (1.5 missed by 0.006) |
| ~07:30 | Thorfinn | Annealed μ Arm A terminal | Mechanism-level early-training test |
| ~12:50 | Nezuko | Attn-SOAP T=0.85 n=4 terminal | MAYBE-MERGE candidate of the round |
| TBD | Alphonse | SOAP_BETA2=0.85 n=4 trial 2 status | If trial 2 also NaN → switch to 0.92 |
| TBD | Tanjiro | TARGET_UW=0.30 n=4 trial 2 status | If trial 2 also NaN → switch to 0.40 |
| TBD | Edward | AdEMAMix n=4 trial 2 status | If all NaN → close PR |
| TBD | Askeladd | Proj-init Variant B screen | ~+95 min after launch |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

**Top news this cycle**: Nezuko Screen B is a clear winner (val=3.27475, ffs=3100) — first FFS-winning result of the round. n=4 confirmation in flight, will know by ~13:00 UTC.

Most promising paths (ranked):
1. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — RUNNING. Likely merge candidate.
2. **Bias-corrected Muon momentum** (frieren #221) — terminal soon, healthy trajectory
3. **Annealed μ schedule** (thorfinn #219) — Arm A halfway
4. **SOAP_BETA2 retune** (alphonse #223) — 0.85 destabilizing; 0.92 may be safer
5. **TARGET_UW retune** (tanjiro #214) — 0.30 destabilizing; try 0.40
6. **AdEMAMix on aux groups** (edward #199) — multi-seed NaN; close likely
7. **Power-law LR** (fern #208) — 1.5 missed; 2.0 final check
8. **Proj-init Variant B** (askeladd #224) — about to launch

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON axis: EXHAUSTED.** Do not assign further CONTRA_MUON sweeps.
- **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
- **NEW: Multi-seed NaN cascade** (alphonse 0.85, possibly others): some HP changes destabilize across seeds, not just trial_idx=0. Distinguishable from seed-0 issue by checking whether NaN happens at step 25 (seed-0) vs step >100 (HP-induced).
- **Power-law LR axis**: 1.5 missed by 0.006; testing 2.0 as final check before closing axis
