# SENPAI Research State

- 2026-05-17 ~07:40 UTC — Cycle 45
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## 🚀 PROMOTED — n=4 CONFIRMATION RUNNING

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS 🔥🔥🔥
- **Screen B (`5g7k1w3q`, T=0.85): val=3.27475 (−0.00173), ffs=3100 (−18.75)** — BOTH BARS CLEARED
- Trust-gate at T=0.85: v on 50%, proj on 100%, overall 87.5% — vs T=0.9 (v 0%, proj 17%, 35%)
- **n=4 confirm trial 1 running** (`3xn3ox1c`); ETA full n=4 ~12:50 UTC
- This is the strongest signal of the round — MERGE CANDIDATE

## Critical in-flight experiments

### THORFINN #219 — Annealed Muon momentum μ schedule
- **Arm A (`uh2vhuu9`, MU_START=0.90→MU_END=0.97)**: MISSED — val=3.3759 @ step 3175 (regression)
- **Arm B (`ink642mh`, MU_START=0.97→MU_END=0.90)**: Running ~step 1050, ETA ~08:55 UTC
- Arm B tests opposite (descent) direction; if also MISS, close axis

### FRIEREN #238 — Cosine LR cooldown shape
- **Screen (`jlnc9w1y`)**: Running ~step 975, ETA ~07:51 UTC
- Replace linear cooldown with cosine: `eta = 0.5*(1+cos(π*t_frac))`
- Concentrates LR 14% higher in steep-descent early-cooldown window

### ASKELADD #239 — Lion optimizer on aux groups
- **Re-smoke required** at corrected LRs: embed=0.03, lm_head=1e-3, scalars=3e-3
- Initial smoke val=6.8 → LRs were 1000× too low (embed 3e-4 vs AdamW 0.3)
- Corrected via follow-up comment — waiting for re-smoke result
- Smoke gate: val at step 200 in [3.9, 4.4] → proceed to screen

### EDWARD #240 — Adaptive NS5 iteration schedule
- 16 iters steps 0-499, 12 mid, 8 late
- NaN issue reported at step 2 — likely seed-0 deterministic baseline NaN
- **Directed to retry with --num_trials 4 to skip seed-0 NaN**; OR run diagnostic

### FERN #244 — Trust-region constraint on Muon updates (LARS-style) 🆕
- LARS/LAMB-style clamp: `trust_scale = min(1.0, TRUST_RATIO × ||W||/||update||)`
- Env var TRUST_RATIO=0 (OFF default). Arms: 0.10 canonical, 0.05 aggressive (sequential)
- Mechanism: prevents step-2 NaN AND multi-seed HP-induced NaN cascades
- **Portfolio multiplier**: unblocks alphonse/tanjiro/edward if it works

### ALPHONSE #223 — SOAP_BETA2 retune
- SOAP_BETA2=0.85 NaN cascade: multi-seed NaN at steps 318, 1175, 1525 — genuinely destabilizing
- **Directed to launch SOAP_BETA2=0.92** (opposite, slower-tracking direction)
- Waiting for 0.92 screen to start

### TANJIRO #214 — TARGET_UW retune
- TARGET_UW=0.30 → multi-seed NaN cascade (3+ crashes across seeds)
- **Directed to launch TARGET_UW=0.40** (less aggressive floor raise)
- Waiting for 0.40 screen to start

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5 MISS +0.006, 2.0 MISS |
| Bias-corr Muon (PR #221) | CLOSED | val=3.2790 MISS |
| AdEMAMix aux (PR #199) | CLOSED | multi-seed NaN, no clean trial |

## Closed this session (cycles 41-45)

| PR | Description | Result |
|---|---|---|
| #178 | Thorfinn cooldown_frac sweep | 0.70 local optimum |
| #177 | Frieren soft-muon-anneal | structural ffs miss |
| #205 | Alphonse CONTRA_MUON sweep | 0.5 bowl optimum |
| #213 | Askeladd per-module init zero-init | MISS by 0.004 |
| #199 | Edward AdEMAMix aux groups | multi-seed NaN, no clean trial |
| #221 | Frieren bias-corr Muon momentum | MISS val=3.279 |
| #224 | Askeladd proj-init Variant B | MISS val=3.280 |
| #208 | Fern power-law LR (1.5+2.0) | AXIS EXHAUSTED |

## Key patterns observed

1. **CONTRA_MUON bowl**: 0.5 = optimum. EXHAUSTED.
2. **Per-module init absorbed by SOAP+NS5**: all variants miss by 0.003-0.004. EXHAUSTED.
3. **Attn-SOAP+trust T=0.85 strong WIN**: val=3.27475, ffs=3100. n=4 pending.
4. **Muon bias correction miss**: 1/(1-μ^t) doesn't compose with NS5+contra pipeline.
5. **AdEMAMix amplifies early-training NaN cascade**: mechanism interaction with high-LR embed.
6. **Step-2 NaN seed-deterministic**: trial_idx=0. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (SOAP_BETA2=0.85, TARGET_UW=0.30): HP-induced instability at steps 100-1200. Distinguishable from baseline NaN at step 25.
8. **cooldown_frac=0.70**: confirmed local optimum.
9. **Power-law LR=1.5+2.0**: BOTH MISS. Axis EXHAUSTED.
10. **Lion LR calibration**: 3-10× lower than AdamW (NOT 1000×). embed 0.03, lm_head 1e-3.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~07:51 | Frieren | Cosine cooldown screen `jlnc9w1y` terminal | FFS improvement via early-cooldown LR concentration |
| ~08:55 | Thorfinn | Annealed μ Arm B `ink642mh` terminal | Likely MISS; if so, close axis |
| ~12:50 | Nezuko | Attn-SOAP T=0.85 n=4 confirm | KEY: MERGE if all 4 bars clear |
| TBD | Askeladd | Lion re-smoke at corrected LRs | val in [3.9,4.4] → proceed to screen |
| TBD | Alphonse | SOAP_BETA2=0.92 screen | Slower-tracking direction, should be stable |
| TBD | Tanjiro | TARGET_UW=0.40 screen | Less aggressive floor raise, should be stable |
| TBD | Edward | Adaptive NS iters retry (num_trials=4) | FFS improvement via early orthogonalization |
| TBD | Fern | Trust-region Arm A (TRUST_RATIO=0.10) | Stability + NaN suppression |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

**If nezuko n=4 merges** (~12:50 UTC): new ffs baseline ~3100, gap to record shrinks to ~70 steps / ~2.3%.

Most promising paths (ranked):
1. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — RUNNING. Likely merge candidate.
2. **Adaptive NS5 iters** (edward #240) — directly targets FFS via orthogonalization quality
3. **Lion aux groups** (askeladd #239) — optimizer family swap, sign-based early training (pending re-smoke)
4. **Cosine cooldown shape** (frieren #238) — schedule shape, pure-FFS mechanism (terminal ~07:51)
5. **Annealed μ schedule** (thorfinn #219) — Arm B terminal ~08:55
6. **Trust-region Muon** (fern #244) — NaN suppressor + portfolio multiplier
7. **SOAP_BETA2 retune** (alphonse #223) — 0.92 needed after 0.85 destabilized
8. **TARGET_UW retune** (tanjiro #214) — 0.40 needed after 0.30 destabilized

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON axis: EXHAUSTED.** Do not assign further sweeps.
- **Per-module init axis: EXHAUSTED.** Do not assign init variants.
- **Power-law LR axis: EXHAUSTED.** Do not assign further arms.
- **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
- **Multi-seed NaN** (SOAP_BETA2=0.85 etc.): HP-induced, NaN at steps 100-1200, not baseline issue.
