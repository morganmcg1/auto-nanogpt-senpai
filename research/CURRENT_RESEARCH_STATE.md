# SENPAI Research State

- 2026-05-17 ~11:15 UTC — Cycle 52
- No human researcher directives this session.
- ⚠️ GitHub REST API rate limit hit at 10:53 UTC; resets ~11:40 UTC.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES (n=4 in progress)

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 trial 1 running 🔥🔥🔥
- Trial 0 done: val=**3.2751**, ffs=**3075** (matches screen — confirmed)
- Trial 1: step 626/3175 (~20% into trial 1)
- ETA all 4 trials ~15:30 UTC

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 trial 3 finishing
- Trial 0: NaN (canonical seed-0)
- Trial 1: val=**3.2764**, ffs=**3125**
- Trial 2: val=**3.2761**, ffs=**3100**
- Trial 3: step ~2902/3175 (~91% — finishing in ~10 min)
- Interim n=2 mean: val=**3.27625**, ffs=**3112.5** → BOTH BARS CLEARED
- n=3 statsig bar: mean ≤ 3.27769 (need 0.00144 margin from current — comfortable)
- ETA terminal SENPAI-RESULT ~11:30 UTC

## Active in-flight experiments

### FERN #245 — Trust-region constraint Arm B
- Arm A `h5a8aapz` MISS: val=3.2999, ffs=-1
- Arm B `xwbr4pkn` (TRUST_RATIO=0.05) running, step 550/3175 (healthy descent)

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5
- Screen `mon2ndin` running, step 1700/3175, val=3.5262 (slightly behind pace; needs to drop 0.25 in next 1475 steps)

### EDWARD #251 — Lookahead optimizer wrapper on Muon
- Retry `s6uvyg4y` with num_trials=4 running (trial 0 NaN at step 125 expected — canonical seed-0)

### ASKELADD #239 — Lion optimizer on aux groups
- Arm A `gxxlpakh` MISS: val=3.2985, ffs=-1
- Re-run `39z55i7d` (same HPs) at step 325 — advisor commented to pivot to LR variation or close

### ALPHONSE #256 — SOAP_PRECOND_FREQ sweep
- `ukizq01t` num_trials=1 NaN'd at step 100 (canonical seed-0). May need num_trials=4 retry — per PR plan.

### TANJIRO ⚠️ IDLE — embed-warmup #252 falsified (need reassignment)
- Both Arm A (50) and Arm B (150) hit canonical seed-0 NaN at step 25
- Embed lr scaled correctly (verified telemetry) — NaN is NOT embedding-driven
- attn.proj.bias is the actual NaN trigger (confirmed by parameter signature)
- Reassignment pending (NS_ITERS sweep prepared at `/tmp/senpai-r2-bodies/tanjiro-ns-iters-sweep.md`)

## Closed axes (exhausted)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl |
| SOAP_BETA2 retune | EXHAUSTED ⛔ | 0.85 unstable, 0.92 multi-seed NaN, 0.90 = optimum |
| Adaptive NS5 (16 early) | FALSIFIED | 4/4 trials NaN multi-seed |
| Gradient noise injection | FALSIFIED | 4/4 NaN — NS5 amplifies noise ×35 |
| Cosine cooldown shape | CLOSED | val=3.2882, never hit 3.28 |
| Annealed μ Arm A (0.90→0.97) | MISSED | val=3.3759 regression |
| Muon bias correction (Adam-style) | CLOSED | val=3.27903/ffs=3150 MISS (PR #221) |
| Schedule-Free Muon | CLOSED | constant-LR diverges with NS5 |
| Soft-Muon-anneal p sweep | CLOSED | parameter-insensitive 0.07-0.10 |
| AdEMAMix aux groups | CLOSED | multi-seed NaN cascade |
| PMuon bilateral streaming | CLOSED | double-conditioning with SOAP-MLP |
| cooldown_frac sweep | CLOSED | 0.70 local optimum |
| KL-SOAP+hyperball | CLOSED | 0.018 MISS +0.0175 val |
| Lookahead Muon α=0.7 | CLOSED | MISS |
| Muon² (second-order) | CLOSED | non-competitive |
| Decoupled embed warmup | FALSIFIED | NaN-invariant across 60× lr variation (PR #252) |

## Key patterns observed

1. **Annealed μ (0.97→0.90) confirmed in n=4 trial 0**: val=3.2751/ffs=3075 trial 0 matches screen.
2. **Attn-SOAP+trust T=0.85 confirmed at n=2**: trials 1+2 mean val=3.27625/ffs=3112.5 BOTH BARS CLEARED.
3. **Linear cooldown > cosine**: cosine never reached 3.28 target.
4. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.
5. **More NS5 iters early = destabilizer**: 16-iter early multi-seed NaN cascade.
6. **Step-2 NaN at blocks.0.attn.proj.bias**: seed-0 deterministic, NOT embedding-driven (confirmed by tanjiro #252).
7. **Multi-seed NaN cascade**: HP-induced step 100-1200 (SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter).
8. **SOAP_BETA2 is a sharp bowl**: 0.85 unstable, 0.90 optimum, 0.92 multi-seed NaN.
9. **Schedule-Free Muon incompatible**: constant LR + NS5 = ‖y−z‖ diverges.
10. **Seed-0 NaN propagates to weight buffers**: Lookahead slow buffer, momentum accumulator all inherit NaN.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~11:30 | Nezuko | n=4 trial 3 terminal | **MERGE candidate** (n=3 statsig likely passes) |
| ~12:10 | Fern | Arm B terminal | Likely MISS (tighter than failed Arm A) |
| ~13:30 | Askeladd | Lion re-run terminal | Same MISS (advised to pivot) |
| TBD | Edward | Lookahead n=4 retry trials 1-3 | n=3 statsig check |
| TBD | Frieren | fp32-NS5 terminal | Trajectory uncertain |
| TBD | Alphonse | SOAP_PRECOND_FREQ retry | Needs num_trials=4 |
| TBD | Tanjiro | NS_ITERS reassignment | Pending PR creation |
| ~15:30 | Thorfinn | n=4 all trials | **STRONGEST MERGE candidate** |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**If nezuko n=3 merges** (~11:30): new ffs baseline ~3112.5. Gap to record = ~82 steps.
**If thorfinn n=4 merges** (~15:30): new ffs baseline ~3075. Gap to record = ~45 steps.
**Both compounding**: ffs ~3050. Gap to record = ~20 steps.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — strongest signal, trial 0 confirms screen.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — trials 1+2 cleared bars.
3. **fp32 NS5** (frieren #254) — numerical precision in NS5.
4. **NS_ITERS sweep** (tanjiro NEW) — orthogonal to fp32-NS5, same problem different angle.
5. **SOAP_PRECOND_FREQ=5** (alphonse #256) — tighter eigenbasis lag.
6. **Lookahead on Muon** (edward #251) — slow-weights variance reduction.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.27648 AND ffs_mean < 3118.75
- All n=4: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800 (necessary but not sufficient)
- All n=3 (1 trial NaN): `(3.28 − mean) × √3 ≥ 0.004` → mean ≤ 3.27769
- **Workflow**: Never commit state docs on student branch. Always commit on advisor branch directly.
- **Muon bias correction (PR #221)**: ALREADY TRIED AND CLOSED. Do not reassign. val=3.27903/ffs=3150.
- **Decoupled embed warmup (PR #252)**: ALREADY TRIED AND CLOSED. Do not reassign. NaN-invariant.
