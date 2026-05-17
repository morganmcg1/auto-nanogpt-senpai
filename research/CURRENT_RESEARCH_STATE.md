# SENPAI Research State

- 2026-05-17 ~10:00 UTC — Cycle 50
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES (n=4 running)

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥🔥🔥
- **Single-seed screen** (`ink642mh`): val=**3.27550** (−0.00098), ffs=**3075** (−43.75) — BOTH BARS DECISIVELY CLEARED
- n=4 confirm running. ETA ~15:30 UTC.

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS
- Trial 1: val=3.2764/ffs=3125. Trial 2+ running. ETA ~12:50 UTC.

## Active in-flight experiments

### ASKELADD #239 — Lion optimizer on aux groups
- Re-smoke passed (val~4.54). **Lion screen (`gxxlpakh`) running**, step ~475/3175.

### ALPHONSE #223 — SOAP_BETA2=0.92 n=4
- `hx3jldki` running, trial 0 near completion. Waiting for trial 1+ results.

### FERN #245 — Trust-region constraint on Muon updates
- **Screen (`h5a8aapz`) running**, step ~1575/3175. Mid-run.

### EDWARD #251 — Lookahead optimizer wrapper on Muon
- Arms K=5 and K=10, alpha=0.5 (Zhang et al 2019)
- Awaiting student pickup.

### TANJIRO #252 — Decoupled embedding LR warmup
- Arms 50 and 150 steps. Addresses step-2 NaN at source.
- Awaiting student pickup.

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5 iterations 🆕
- Cast NS5 input to float32, run iterations, cast result back to bf16
- ~3 LoC change. Default OFF.
- Hypothesis: bf16 rounding error in 12-iter NS5 is source of NaN cascades AND variance
- Single-arm screen. Skip smoke.
- Awaiting student pickup.

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl |
| Adaptive NS5 (16 early) | FALSIFIED | 4/4 trials NaN multi-seed |
| Gradient noise injection | FALSIFIED | 4/4 NaN — NS5 amplifies noise |
| Cosine cooldown shape | CLOSED | val=3.2882, never hit 3.28 |
| Annealed μ Arm A (0.90→0.97) | MISSED | val=3.3759 regression |

## Key patterns observed

1. **Annealed μ (0.97→0.90) decisive WIN**: val=3.27550/ffs=3075 single-seed. HIGH priority merge.
2. **Attn-SOAP+trust T=0.85**: screen val=3.27475/ffs=3100. Trial 1 tight (3.2764/3125).
3. **Linear cooldown > cosine**: cosine never reached 3.28 target (3.2882 final).
4. **Gradient noise + NS5 = catastrophic**: noise amplified ×35 Frobenius by NS5. Never inject noise before NS5.
5. **More NS5 iters early = destabilizer**: 16-iter early multi-seed NaN cascade.
6. **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (HP-induced, steps 100-1200): SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter.
8. **Lion LR calibration**: 3-10× lower than AdamW. embed=0.03, lm_head=1e-3.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~10:30 | Alphonse | 0.92 trial 1 outcome | Confirms HP stability vs multi-seed NaN |
| ~11:00 | Askeladd | Lion screen progress | ~30% through |
| TBD | Fern | Trust-region terminal | NaN suppressor test |
| TBD | Edward | Lookahead Arm A screen | Slow-weights variance reduction |
| TBD | Tanjiro | Embed warmup Arm A screen | Source-level NaN suppression |
| TBD | Frieren | fp32-NS5 screen | Numerical precision improvement |
| ~12:50 | Nezuko | n=4 all trials | MERGE candidate |
| ~15:30 | Thorfinn | n=4 all trials | STRONGEST MERGE candidate |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**If thorfinn n=4 confirms** (~15:30): new ffs baseline ~3075. Gap to record = ~45 steps.
**Both nezuko AND thorfinn compounding**: mechanisms are orthogonal — both can be merged.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — strongest ever screen signal.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — tight but orthogonal to thorfinn.
3. **Lion aux groups** (askeladd #239) — sign-based optimizer family swap.
4. **Trust-region Muon** (fern #245) — NaN suppressor + portfolio multiplier.
5. **fp32 NS5** (frieren #254) — low-risk precision improvement, NaN portfolio multiplier.
6. **Lookahead on Muon** (edward #251) — slow-weights variance reduction.
7. **Decoupled embed warmup** (tanjiro #252) — step-2 NaN at source.
8. **SOAP_BETA2=0.92** (alphonse #223) — narrow HP retune.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
