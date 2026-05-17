# SENPAI Research State

- 2026-05-17 ~09:30 UTC — Cycle 49
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES (n=4 running)

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥🔥🔥
- **Single-seed screen** (`ink642mh`): val=**3.27550** (−0.00098), ffs=**3075** (−43.75) — BOTH BARS DECISIVELY CLEARED
- n=4 confirm (`g1r2-thorfinn/annealed-mu-confirm-n4`) running. ETA ~15:30 UTC.

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS
- Trial 1: val=3.2764/ffs=3125. Trial 2 running. ETA ~12:50 UTC.

## Critical in-flight experiments

### ASKELADD #239 — Lion optimizer on aux groups
- Re-smoke passed. **Lion screen (`gxxlpakh`) running**, ~step 475/3175.

### ALPHONSE #223 — SOAP_BETA2=0.92 n=4
- `hx3jldki` running, trial 0 in progress. Waiting for trial 1 result to confirm stability.

### FERN #245 — Trust-region constraint on Muon updates
- **Screen (`h5a8aapz`) running**, step 1575/3175, val=3.588. Mid-run, normal.

### EDWARD #251 — Lookahead optimizer wrapper on Muon 🆕
- Wraps Muon with Polyak slow-weights (Zhang et al 2019)
- Arms: K=5 alpha=0.5 (canonical), K=10 alpha=0.5 (longer window)
- No smoke required. Awaiting student pickup.

### TANJIRO #252 — Decoupled embedding LR warmup 🆕
- Ramp embed LR from 0 → 0.3 over first EMBED_WARMUP_STEPS steps only
- Arms: 50 steps (gentle), 150 steps (longer ramp)
- Addresses step-2 NaN at the embedding source. Awaiting student pickup.

### FRIEREN #238 — Cosine LR cooldown shape (CLOSING)
- **MISS**: val=3.2882, never reached 3.28 target. ffs=-1.
- Cosine cooldown is WORSE than linear at cooldown_frac=0.70.
- Directed to post terminal SENPAI-RESULT. Will close + reassign.

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
| Annealed μ Arm B (0.97→0.90) | **WIN (n=4 running)** | val=3.27550/ffs=3075 screen |

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 = optimum. EXHAUSTED.
2. **Per-module init absorbed by SOAP+NS5**. EXHAUSTED.
3. **Annealed μ (0.97→0.90) decisive WIN**: val=3.27550/ffs=3075. Asymmetry: high μ early stabilizes warmup, low μ late lets Muon react sharply in cooldown.
4. **Attn-SOAP+trust T=0.85**: tight n=4 (trial 1 val=3.2764/ffs=3125, screen was 3.27475/3100).
5. **Gradient noise amplified by NS5 at step 0**: noise before NS5 gets ×35 Frobenius amplification → catastrophic. Injection must be post-NS5 if at all.
6. **More NS5 iters early = destabilizer**: 16-iter early multi-seed NaN. Counterintuitive.
7. **Linear cooldown > cosine**: at cooldown_frac=0.70, cosine shape failed to reach target (val=3.288). Linear baseline hits 3.27648.
8. **Cooldown shape axis**: linear is the clear winner. Cosine exhausted.
9. **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
10. **Multi-seed NaN cascade** (HP-induced, steps 100-1200): distinguishable from baseline seed-0 NaN at step 25.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~09:45 | Frieren | Post terminal SENPAI-RESULT | MISS confirmed → reassign |
| ~10:30 | Alphonse | SOAP_BETA2=0.92 trial 1 outcome | Confirms HP stability |
| TBD | Askeladd | Lion screen terminal | Sign-based aux optimizer test |
| TBD | Fern | Trust-region terminal | Stabilizer + NaN suppressor |
| TBD | Edward | Lookahead Arm A pickup | Slow-weights variance reduction |
| TBD | Tanjiro | Embed warmup screen | Step-2 NaN suppression at source |
| ~12:50 | Nezuko | n=4 all trials complete | MERGE candidate |
| ~15:30 | Thorfinn | n=4 all trials complete | STRONGEST MERGE candidate |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**If thorfinn n=4 confirms** (~15:30): new ffs baseline ~3075 → gap to record = ~45 steps.
**If nezuko n=4 also confirms**: compounding with attn-SOAP+trust → further reduction.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — strongest screen signal ever.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — tight but orthogonal to thorfinn.
3. **Lion aux groups** (askeladd #239) — sign-based optimizer family swap.
4. **Trust-region Muon** (fern #245) — defensive stabilizer + portfolio multiplier.
5. **Lookahead on Muon** (edward #251) — slow-weights variance reduction.
6. **Decoupled embed warmup** (tanjiro #252) — step-2 NaN at source.
7. **SOAP_BETA2=0.92** (alphonse #223) — HP retune, narrow band.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
- **Many axes EXHAUSTED**: CONTRA_MUON, per-module init, power-law LR, TARGET_UW, more-iters-early NS5, grad noise, cosine cooldown.
