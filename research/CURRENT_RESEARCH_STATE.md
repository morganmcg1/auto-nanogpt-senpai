# SENPAI Research State

- 2026-05-17 ~08:00 UTC — Cycle 46
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175
Merge bar (n=4): BOTH mean < 3.27648 AND ffs_mean < 3118.75

## 🚀 PROMOTED — n=4 CONFIRMATION RUNNING

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 IN PROGRESS 🔥🔥🔥
- **Screen B (`5g7k1w3q`, T=0.85): val=3.27475 (−0.00173), ffs=3100 (−18.75)** — BOTH BARS CLEARED
- **Trial 1 (`3xn3ox1c`) COMPLETE**: val=3.2764, ffs=3125. Needs trials 2-4 for mean assessment.
  - Val bar: 3.2764 < 3.27648 ✓ (barely). ffs=3125 > 3118.75 ✗ → mean needs trials 2-4 ≤ 3116.7 ffs avg
- Trials 2-4 expected to launch sequentially. ETA full n=4 ~12:50 UTC.
- **MERGE CANDIDATE** but result is tighter than screen suggested.

## Critical in-flight experiments

### FRIEREN #238 — Cosine LR cooldown shape
- **Screen (`jlnc9w1y`)**: Running ~step 1325/3175, val=3.630. ETA terminal ~08:30 UTC.
- Replace linear cooldown with cosine: `eta = 0.5*(1+cos(π*t_frac))`

### THORFINN #219 — Annealed Muon momentum μ schedule
- **Arm A (`uh2vhuu9`, 0.90→0.97)**: MISSED — val=3.3759 (regression)
- **Arm B (`ink642mh`, 0.97→0.90)**: Running ~step 1600/3175, val=3.533. ETA ~09:30 UTC.
  - Projected terminal ~3.28+ based on current slope → likely MISS. Will close axis if Arm B also misses.

### ASKELADD #239 — Lion optimizer on aux groups
- **Both smokes failed** — LRs were 1000× too low (advisor calibration error)
- **Re-smoke directed** at corrected LRs: embed=0.03, lm_head=1e-3, scalars=3e-3
- PR sent back to wip with corrected LR schedule and re-smoke instructions
- Smoke gate: val at step 200 in [3.9, 4.4] → proceed to 3175-step screen

### EDWARD #240 — Adaptive NS5 iteration schedule
- Threading confirmed correct: `Muon.step → contra_normuon_update → zeropower_via_newtonschulz5`
- NaN in prior runs was seed-0 baseline NaN (not an ADAPTIVE_NS bug)
- **200-step diagnostic running** with `--num_trials 4` to verify 16-iter early window stability
- If ≥3/4 trials pass step 200 cleanly → proceed to predeclared n=4 screen (3175 steps, num_trials=4)

### FERN #245 — Trust-region constraint on Muon updates (LARS-style)
- LARS/LAMB-style clamp: `trust_scale = min(1.0, TRUST_RATIO × ||W||/||update||)`
- Arms: 0.10 canonical, 0.05 aggressive (sequential)
- Awaiting student pickup

### ALPHONSE #223 — SOAP_BETA2 retune
- SOAP_BETA2=0.85 KILLED — confirmed multi-seed destabilizer (NaN steps 75-1175)
- SOAP_BETA2=0.92 NaN at step 125 was canonical seed-0 baseline NaN (147M nonfinite fingerprint)
- **Directed: retry SOAP_BETA2=0.92 with --num_trials 4** to skip seed-0

### TANJIRO #214 — TARGET_UW retune
- TARGET_UW=0.30 KILLED — multi-seed NaN cascade (seeds 0 AND 1, NaN at steps 175-219)
- **Directed: kill y3lccflx, launch TARGET_UW=0.40 single screen**

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| Bias-corr Muon (PR #221) | CLOSED | val=3.2790 MISS |
| AdEMAMix aux (PR #199) | CLOSED | multi-seed NaN, no clean trial |

## Closed this session (cycles 41-46)

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
3. **Attn-SOAP+trust T=0.85 strong WIN**: val=3.27475, ffs=3100. n=4 trial 1 val=3.2764/ffs=3125.
4. **Muon bias correction miss**: 1/(1-μ^t) doesn't compose with NS5+contra pipeline.
5. **AdEMAMix amplifies early-training NaN cascade**: mechanism interaction with high-LR embed.
6. **Step-2 NaN seed-deterministic**: trial_idx=0. Use `--num_trials 4` for uncertain mechanisms.
7. **Multi-seed NaN cascade** (SOAP_BETA2=0.85, TARGET_UW=0.30): HP-induced instability steps 100-1200. Distinguishable from baseline NaN at step 25.
8. **cooldown_frac=0.70**: confirmed local optimum.
9. **Power-law LR**: BOTH 1.5 and 2.0 MISS. Axis EXHAUSTED.
10. **Lion LR calibration**: 3-10× lower than AdamW (NOT 1000×). embed 0.03, lm_head 1e-3.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~08:30 | Frieren | Cosine cooldown terminal | FFS improvement? |
| ~08:45 | Edward | 200-step diagnostic (4 trials) | Verify 16-iter stability |
| ~09:30 | Thorfinn | Arm B terminal | Likely MISS → close axis |
| ~10:00 | Alphonse | SOAP_BETA2=0.92 n=4 | Skip seed-0 NaN with 4 trials |
| ~10:00 | Tanjiro | TARGET_UW=0.40 screen | Less aggressive floor raise |
| TBD | Askeladd | Lion re-smoke v2 (embed=0.03) | val in [3.9,4.4] → screen |
| TBD | Fern | Trust-region Arm A pickup (#245) | NaN suppressor test |
| ~12:50 | Nezuko | n=4 confirm full 4 trials | MERGE if mean < 3.27648 AND ffs_mean < 3118.75 |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps. Gap = ~89 steps / ~2.8%.

**If nezuko n=4 merges** (~12:50 UTC): new ffs baseline ~3100±, gap to record shrinks to ~70 steps.

Most promising paths (ranked):
1. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — Trial 1 done, trials 2-4 running.
2. **Adaptive NS5 iters** (edward #240) — diagnostic running; low NaN risk, directly targets FFS.
3. **Lion aux groups** (askeladd #239) — re-smoke at corrected LRs underway.
4. **Cosine cooldown shape** (frieren #238) — terminal ~08:30, direct FFS mechanism.
5. **Trust-region Muon** (fern #245) — NaN suppressor + portfolio multiplier, assigned.
6. **SOAP_BETA2=0.92** (alphonse #223) — num_trials=4 retry underway.
7. **TARGET_UW=0.40** (tanjiro #214) — redirected, launch imminent.
8. **Annealed μ schedule** (thorfinn #219) — Arm B terminal ~09:30, likely MISS.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- **CONTRA_MUON axis: EXHAUSTED.** Do not assign further sweeps.
- **Per-module init axis: EXHAUSTED.** Do not assign init variants.
- **Power-law LR axis: EXHAUSTED.** Do not assign further arms.
- **Step-2 NaN**: seed-0 deterministic. Use `--num_trials 4` for uncertain mechanisms.
- **Multi-seed NaN** (SOAP_BETA2=0.85, TARGET_UW=0.30): HP-induced, NaN at steps 100-1200.
- **Workflow note**: Never commit to a student branch and FF back to advisor. Always commit state docs on advisor branch directly.
