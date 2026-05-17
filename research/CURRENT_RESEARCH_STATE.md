# SENPAI Research State

- 2026-05-17 ~08:30 UTC — Cycle 47
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## 🚀 PROMOTED — n=4 CONFIRMATION RUNNING

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS 🔥🔥🔥
- **Screen B (`5g7k1w3q`, T=0.85): val=3.27475 (−0.00173), ffs=3100 (−18.75)** — BOTH BARS CLEARED
- **Trial 1 (`3xn3ox1c`) COMPLETE**: val=3.2764, ffs=3125
  - 4-trial run sequential in same W&B run — currently mid-trial-2 (step 4401/12700 total)
  - Val bar: trial 1 3.2764 < 3.27648 ✓ (borderline). ffs=3125 > 3118.75 → needs remaining trials ≤ 3116.7 avg
- ETA full n=4 ~12:50 UTC

## Critical in-flight experiments

### FRIEREN #238 — Cosine LR cooldown shape
- **Screen (`jlnc9w1y`)**: Running ~step 1750/3175, val=3.523. ETA terminal ~09:30-10:00 UTC.
- Normal descent trajectory — too early to call direction

### THORFINN #219 — Annealed Muon momentum μ schedule
- **Arm A (0.90→0.97)**: MISSED — val=3.3759 (regression)
- **Arm B (`ink642mh`, 0.97→0.90)**: Running ~step 1600/3175, val=3.533. ETA ~09:30 UTC.
  - Projected ~3.284 at terminal based on current slope — likely MISS. Close axis if Arm B also misses.

### ASKELADD #239 — Lion optimizer on aux groups
- **Re-smoke (corrected LRs) PASSED**: embed=0.03, lm_head=1e-3, scalars=3e-3
  - `g5d1b4tk` val=4.549, `8o8mellp` val=4.533 at step 200. Learning (init 10.83), no NaN.
- **Directed to proceed to 3175-step screen** (`g1r2-askeladd/lion-aux-screen-v2`)

### EDWARD #240 — Adaptive NS5 iteration schedule
- Threading confirmed correct
- **200-step diagnostic (`j3la5d4s`)** with `--num_trials 4` running, ~step 604/800
- If ≥3/4 trials clean → proceed to predeclared n=4 screen (3175 steps, num_trials=4)

### ALPHONSE #223 — SOAP_BETA2 retune
- 0.85: KILLED — confirmed multi-seed destabilizer
- 0.92: `klsnpomc` crashed step 225. **`hx3jldki` (n=4 run) running**, step ~450. Trial 0 NaN expected (seed-0). Waiting for trial 1 result to confirm it's not multi-seed.

### FERN #245 — Trust-region constraint on Muon updates (LARS-style)
- LARS/LAMB-style clamp: `trust_scale = min(1.0, TRUST_RATIO × ||W||/||update||)`
- Arms: 0.10 canonical, 0.05 aggressive (sequential). Awaiting student pickup.

### TANJIRO #246 — Annealed gradient noise injection 🆕
- Inject decaying Gaussian noise to gradients: `sigma_t = NOISE_BASE/(1+step)^0.55`
- Arms: GRAD_NOISE_BASE=0.01 (canonical), 0.05 (aggressive), with num_trials=4 each
- Smoke with num_trials=4 required first (verify NaN suppression effect)
- Awaiting student pickup.

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl; 0.30 multi-seed NaN, 0.40 seed-0 NaN |
| Bias-corr Muon (PR #221) | CLOSED | val=3.2790 MISS |
| AdEMAMix aux (PR #199) | CLOSED | multi-seed NaN, no clean trial |

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 = optimum. EXHAUSTED.
2. **Per-module init absorbed by SOAP+NS5**: all variants miss. EXHAUSTED.
3. **Attn-SOAP+trust T=0.85 strong WIN**: val=3.27475, ffs=3100. n=4 tight — trial 1 val=3.2764/ffs=3125.
4. **Muon bias correction miss**: 1/(1-μ^t) doesn't compose with NS5+contra pipeline.
5. **AdEMAMix amplifies early-training NaN cascade**: mechanism interaction with high-LR embed.
6. **Step-2 NaN seed-deterministic**: trial_idx=0. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (SOAP_BETA2=0.85, TARGET_UW=0.30): HP-induced instability steps 100-1200.
8. **TARGET_UW stability bowl**: 0.35 = stable optimum. Both 0.30 and 0.40 destabilize. EXHAUSTED.
9. **cooldown_frac=0.70**: confirmed local optimum.
10. **Power-law LR**: BOTH 1.5 and 2.0 MISS. Axis EXHAUSTED.
11. **Lion LR calibration**: 3-10× lower than AdamW (NOT 1000×). embed=0.03, lm_head=1e-3.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~08:45 | Edward | Diagnostic 4-trial complete | Verify 16-iter early-window stability |
| ~09:00 | Askeladd | Lion 3175-step screen starts | Screen run underway |
| ~09:30 | Frieren | Cosine cooldown terminal | FFS improvement? |
| ~09:30 | Thorfinn | Arm B terminal | Likely MISS → close axis |
| ~10:00 | Alphonse | SOAP_BETA2=0.92 n=4 trial 1 | If clean → proceed with n=4 |
| TBD | Fern | Trust-region pickup (#245) | NaN suppressor test |
| TBD | Tanjiro | Grad-noise smoke (4 trials) | NaN suppression verification |
| ~12:50 | Nezuko | n=4 all trials complete | MERGE if mean < 3.27648 AND ffs_mean < 3118.75 |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.
**If nezuko merges**: ffs baseline → ~3100-3125 range, gap shrinks.

Most promising paths (ranked):
1. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — Trial 1 tight, 3 more needed.
2. **Adaptive NS5 iters** (edward #240) — direct FFS mechanism, diagnostic running.
3. **Lion aux groups** (askeladd #239) — re-smoke passed, screen next.
4. **Cosine cooldown shape** (frieren #238) — terminal ~09:30.
5. **Trust-region Muon** (fern #245) — NaN suppressor + unblocks aggressive HP sweeps.
6. **Gradient noise injection** (tanjiro #246) — variance-reducing, NaN-escaping.
7. **SOAP_BETA2=0.92** (alphonse #223) — n=4 running, trial 1 status key.
8. **Annealed μ schedule** (thorfinn #219) — Arm B likely MISS, close axis soon.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON, per-module init, power-law LR, TARGET_UW: all EXHAUSTED.**
- **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
- **Multi-seed NaN**: HP-induced at steps 100-1200. Distinguishable from seed-0 NaN at step 25.
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
