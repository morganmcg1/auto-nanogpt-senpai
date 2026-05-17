# SENPAI Research State

- 2026-05-17 ~11:35 UTC — Cycle 53
- No human researcher directives this session.

## Current baseline ⭐

**Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #139)** — n=4 mean=**3.27648**, ffs_mean=**3118.75** @ train_steps=3175

## 🚀 TOP MERGE CANDIDATES

### NEZUKO #212 — Attn-SOAP+trust @ T=0.85 — n=4 trial 3 running (~70 min)
- Trial 0: val=**3.2764**, ffs=**3125** (clean — no NaN in confirm run `3xn3ox1c`)
- Trial 1: val=**3.2761**, ffs=**3100**
- Trial 2: val=**3.2775**, ffs=**3125**
- Trial 3: step ~1050/3175 (~33%) — ETA ~12:40 UTC
- n=3 mean: val=**3.27667**, ffs=**3116.7** — ffs bar cleared; val borderline (+0.0002 above 3.27648)
- n=4 outcome depends on trial 3: need trial 3 val < ~3.275 to pull mean below 3.27648; FFS compellingly below baseline regardless

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 trial 1 running 🔥🔥🔥
- Trial 0: val=**3.2751**, ffs=**3075** (strongest single-trial signal)
- Trial 1: step ~5001/6350 (~79%) — ETA ~13:00 UTC
- ETA all 4 trials ~15:30 UTC

## Active in-flight experiments

### FERN #245 — Trust-region constraint Arm B
- Arm A `h5a8aapz` MISS: val=3.2999, ffs=-1
- Arm B `xwbr4pkn` (TRUST_RATIO=0.05) at step 1775/3175, val=3.574 — trajectory slow, likely MISS

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5
- Screen `mon2ndin` at step 2862/3175, val=3.326 — near terminal, likely MISS (0.046 above 3.28 with ~10% remaining)

### EDWARD #251 — Lookahead optimizer wrapper on Muon
- Retry `s6uvyg4y` with num_trials=4 — trial 0 all-NaN (expected seed-0). Trial 1 not yet started. ETA trial 1 start ~12:30 UTC.

### ALPHONSE #256 — SOAP_PRECOND_FREQ sweep
- Retry `9ogg9inl` with num_trials=4 (launched 11:24 UTC) — trial 0 NaN'd at step 100 (expected). Trial 1 not yet started. ETA trial 1 start ~13:00 UTC.

### TANJIRO #259 — NS_ITERS sweep (NEW — just assigned)
- Arm A: NS_ITERS=10; Arm B: NS_ITERS=8
- Code change pending (2-line change to train_gpt_simple.py)

### ASKELADD #239 — Lion optimizer on aux groups
- Arm A `gxxlpakh` MISS: val=3.2985, ffs=-1
- Re-run `39z55i7d` CRASHED at step 600
- Advisor directed: post terminal SENPAI-RESULT and close axis (both HP settings failed)

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
| Lion optimizer aux groups | CLOSING | 2 HP settings, both miss or crash (#239) |

## Key patterns observed

1. **Annealed μ (0.97→0.90) confirmed in n=4 trial 0**: val=3.2751/ffs=3075 — strongest single signal.
2. **Attn-SOAP+trust T=0.85 confirmed at n=3**: val mean=3.27667/ffs mean=3116.7 — ffs CLEARED, val borderline.
3. **Linear cooldown > cosine**: cosine never reached 3.28 target.
4. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.
5. **More NS5 iters early = destabilizer**: 16-iter early multi-seed NaN cascade.
6. **Step-2 NaN at blocks.0.attn.proj.bias**: seed-0 deterministic, NOT embedding-driven (confirmed by tanjiro #252, 60× lr variation invariant).
7. **Multi-seed NaN cascade**: HP-induced step 100-1200 (SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter).
8. **SOAP_BETA2 is a sharp bowl**: 0.85 unstable, 0.90 optimum, 0.92 multi-seed NaN.
9. **Schedule-Free Muon incompatible**: constant LR + NS5 = ‖y−z‖ diverges.
10. **Seed-0 NaN propagates to weight buffers**: Lookahead slow buffer, momentum accumulator all inherit NaN.

## Upcoming decisions / expected results

| Time UTC | Student | Event | Expected outcome |
|---|---|---|---|
| ~12:40 | Nezuko | n=4 trial 3 terminal | **POTENTIAL MERGE** (ffs clear; val borderline) |
| ~13:00 | Thorfinn | n=4 trial 1 terminal | Progress check |
| ~13:00 | Alphonse | Trial 1 starts | NS_PRECOND_FREQ=5 screen data |
| ~13:00 | Edward | Trial 1 starts | Lookahead K=5 screen data |
| ~14:30 | Frieren | fp32-NS5 terminal | Likely MISS |
| ~14:30 | Fern | Arm B terminal | Likely MISS |
| TBD | Askeladd | Post terminal SENPAI-RESULT | Close lion axis |
| TBD | Tanjiro | NS_ITERS code change + Arm A screen | First result ~13:30 |
| ~15:30 | Thorfinn | n=4 all trials | **STRONGEST MERGE CANDIDATE** |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3118.75 steps.

**If nezuko n=4 merges** (~12:40): new ffs baseline ~3116-3118. Gap to record = ~86 steps.
**If thorfinn n=4 merges** (~15:30): new ffs baseline ~3075. Gap to record = ~45 steps.
**Both compounding**: ffs ~3060. Gap to record = ~30 steps.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — strongest signal, trial 0 ffs=3075.
2. **Attn-SOAP+trust T=0.85 n=4** (nezuko #212) — trials 0-2 cleared ffs bar; val borderline.
3. **fp32 NS5** (frieren #254) — numerical precision in NS5, but screen trajectory looks like miss.
4. **NS_ITERS sweep** (tanjiro #259) — orthogonal to fp32-NS5, same problem different angle.
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
