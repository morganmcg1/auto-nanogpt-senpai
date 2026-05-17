# SENPAI Research State

- 2026-05-17 ~08:50 UTC — Cycle 48
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES (n=4 running)

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 LAUNCHED 🔥🔥🔥
- **Single-seed screen** (`ink642mh`): val=**3.27550** (−0.00098), ffs=**3075** (−43.75) — BOTH BARS DECISIVELY CLEARED
- Asymmetry: high μ early stabilizes warmup, low μ late lets Muon react sharply during cooldown
- n=4 confirm predeclared and launched (`g1r2-thorfinn/annealed-mu-confirm-n4`). ETA ~15:30 UTC.
- **STRONGEST SCREENING SIGNAL OF THE ROUND** (better ffs delta than nezuko screen)

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS
- Screen B: val=3.27475/ffs=3100 — both bars cleared
- Trial 1 done: val=3.2764/ffs=3125 (tight on val, missed ffs)
- Trial 2 mid-run (step 5651/12700). ETA full n=4 ~12:50 UTC.

## Critical in-flight experiments

### FRIEREN #238 — Cosine LR cooldown shape
- **Screen (`jlnc9w1y`)**: Step 3075/3175, val=3.2887 (above 3.28 target). ffs=-1 (target not yet reached).
- Slope projection: terminal val ~3.284 → likely **MISS** (won't beat val=3.27648 baseline)
- Cosine cooldown shape appears to hurt vs linear baseline. Will close if SENPAI-RESULT confirms.

### THORFINN #219 (above) — n=4 in progress

### ASKELADD #239 — Lion optimizer on aux groups
- Re-smoke at corrected LRs (embed=0.03, lm_head=1e-3, scalars=3e-3) passed
- **Lion screen (`gxxlpakh`) running**, step 475/3175, val=3.985. Looking healthy.

### EDWARD #240 — Adaptive NS5 iteration schedule
- **(16, 12, 8) schedule FALSIFIED**: 4/4 trials NaN'd in diagnostic. 16-iter early window is multi-seed destabilizer (HP-induced).
- **Redirected to test LATE-only reduction**: keep 12 iters early/mid, drop to 8 only after step 2000
- This isolates Component B (late savings) from falsified Component A (early increase)

### ALPHONSE #223 — SOAP_BETA2=0.92 n=4
- `hx3jldki` running, step 1675/12700 (trial 0 mid-run). NaN at last eval (likely trial 0 seed-0 NaN). Waiting for trial 1 outcome to confirm 0.92 stability across seeds.

### FERN #245 — Trust-region constraint on Muon updates
- **Screen (`h5a8aapz`) running**, step 1575/3175, val=3.588. Mid-run, normal trajectory.

### TANJIRO #246 — Annealed gradient noise injection
- Smoke runs `j9h4ig7p` (step 422) and `lfun9nyh` (step 0) launched — verifying NaN suppression with num_trials=4.

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl |
| Adaptive NS5 (16 early) | FALSIFIED | 4/4 trials NaN — multi-seed HP-induced |
| Annealed μ Arm A | MISSED | val=3.3759 (warmup direction) |

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 = optimum. EXHAUSTED.
2. **Per-module init absorbed by SOAP+NS5**: all variants miss. EXHAUSTED.
3. **Attn-SOAP+trust T=0.85**: val=3.27475/ffs=3100 screen; tight n=4 in progress.
4. **Annealed μ (0.97→0.90) decisive WIN**: val=3.27550/ffs=3075 single-seed; n=4 in progress.
5. **Muon bias correction miss**: 1/(1-μ^t) doesn't compose with NS5+contra pipeline.
6. **AdEMAMix amplifies early-training NaN cascade**.
7. **Step-2 NaN seed-deterministic**: trial_idx=0. Use `--num_trials 4`.
8. **Multi-seed NaN cascade** (SOAP_BETA2=0.85, TARGET_UW=0.30, ADAPTIVE_NS=1 16-iter early): HP-induced instability at steps 100-1200.
9. **TARGET_UW stability bowl**: 0.35 = stable optimum. Both 0.30 and 0.40 destabilize.
10. **cooldown_frac=0.70**: confirmed local optimum.
11. **Power-law LR**: BOTH 1.5 and 2.0 MISS.
12. **Lion LR calibration**: 3-10× lower than AdamW (NOT 1000×).
13. **More NS5 iters early IS destabilizing**: contradicts intuition. NS5 may be more sensitive than the literature suggests.
14. **High μ early + low μ late wins**: asymmetric momentum schedule beats both static and warmup-style.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~09:00 | Frieren | Cosine cooldown terminal | Likely MISS (val~3.284 projected) |
| ~09:30 | Alphonse | 0.92 trial 1 outcome | Confirms HP stability |
| ~10:00 | Edward | Late-only NS reduction launch | Test Component B independently |
| TBD | Askeladd | Lion 3175-step screen | Sign-based aux optimizer test |
| TBD | Fern | Trust-region terminal | NaN suppressor + portfolio multiplier |
| TBD | Tanjiro | Grad-noise smoke result | NaN suppression test |
| ~12:50 | Nezuko | n=4 all trials complete | MERGE candidate |
| ~15:30 | Thorfinn | n=4 all trials complete | STRONGEST MERGE candidate |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**Both nezuko (#212) and thorfinn (#219) screens beat the baseline decisively** — both n=4 confirmations in flight. If thorfinn n=4 confirms with mean ffs ~3075, gap to record = ~45 steps / ~1.5%.

**Compounding opportunity**: nezuko's Attn-SOAP+trust and thorfinn's annealed μ are orthogonal mechanisms. If both merge sequentially, ffs could go below 3070.

Most promising paths (ranked by signal strength):
1. **Annealed μ Arm B (0.97→0.90) n=4** (thorfinn #219) — strongest screen signal.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — tight but plausible.
3. **Lion aux groups** (askeladd #239) — screen running, optimizer family swap.
4. **Trust-region Muon** (fern #245) — defensive stabilizer + portfolio multiplier.
5. **Late-only NS5 reduction** (edward #240) — Component B isolation test.
6. **Gradient noise injection** (tanjiro #246) — variance-reducing.
7. **SOAP_BETA2=0.92 n=4** (alphonse #223) — narrow if 0.92 stable across seeds.
8. **Cosine cooldown** (frieren #238) — likely MISS, axis closure pending.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **Many axes EXHAUSTED**: CONTRA_MUON, per-module init, power-law LR, TARGET_UW, more-iters-early NS5
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
