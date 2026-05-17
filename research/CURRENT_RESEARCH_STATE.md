# SENPAI Research State

- 2026-05-17 ~13:00 UTC — Cycle 54
- No human researcher directives this session.

## Current baseline ⭐ (UPDATED — PR #212 merged)

**Attn-SOAP+trust T=0.85 + Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #212)** — n=4 mean=**3.27631**, ffs_mean=**3112.5** @ train_steps=3175

Previous baseline (PR #139): val=3.27648, ffs=3118.75

## 🚀 TOP MERGE CANDIDATE

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 trial 2 running 🔥🔥🔥
- Trial 0: val=**3.2751**, ffs=**3075** (strongest single-trial signal)
- Trial 1: val=**3.2770**, ffs=**3100**
- Trial 2: step ~1125/3175 (35%) — ETA ~13:00 UTC (trial 2) + ~100 min (trials 3+)
- n=2 mean: val=**3.2761**, ffs=**3087.5** — BOTH BARS CLEARED vs new baseline
- ETA all 4 trials ~15:30 UTC

## Active in-flight experiments

### ALPHONSE #256 — SOAP_PRECOND_FREQ=5 screen n=4
- Trial 0 NaN'd (expected seed-0). Trial 0 at step ~2500/3175. Trial 1 starts ~13:30 UTC.

### TANJIRO #259 — NS_ITERS sweep (Arm A = NS_ITERS=10, n=4)
- Student launched, Arm A running.

### FERN #263 — NorMuon variance EMA bias correction
- Student just assigned. Awaiting implementation + smoke test.

### EDWARD #267 — Gradient Centralization on Muon (Yong et al 2020)
- Student just assigned. Awaiting implementation.

### ASKELADD #268 — Per-block-depth Muon LR scaling
- Student just assigned. Awaiting implementation.

### FRIEREN #254 — fp32 precision in NS5 (FINISHED, awaiting student SENPAI-RESULT)
- Run `mon2ndin` FINISHED: val=3.2769, ffs=3125
- **MISS vs new baseline**: val=3.2769 > 3.27631; ffs=3125 > 3112.5
- Student has not yet posted terminal SENPAI-RESULT

## Closed axes this session

| Axis | Status | Notes |
|---|---|---|
| Decoupled embed warmup (PR #252) | FALSIFIED | NaN-invariant 60× lr variation — attn path is real trigger |
| Trust-region Muon (PR #245) | CLOSED | Monotonic worsening; Muon update = 20-25% weight norm, cannot be clamped at 5-10% |
| Lookahead on Muon (PR #251) | CLOSED | Periodic param rollback breaks 3-layer stateful preconditioner SOAP/NorMuon/Muon |
| Lion aux groups (PR #239) | CLOSED | Monotonic miss; AdamW second-moment is essential in cooldown for aux groups |

## Closed axes (full record)

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
| Muon bias correction (momentum) | CLOSED | val=3.27903/ffs=3150 MISS (PR #221) |
| Schedule-Free Muon | CLOSED | constant-LR diverges with NS5 |
| Soft-Muon-anneal p sweep | CLOSED | parameter-insensitive 0.07-0.10 |
| AdEMAMix aux groups | CLOSED | multi-seed NaN cascade |
| PMuon bilateral streaming | CLOSED | double-conditioning with SOAP-MLP |
| cooldown_frac sweep | CLOSED | 0.70 local optimum |
| KL-SOAP+hyperball | CLOSED | 0.018 MISS +0.0175 val |
| Lookahead Muon α=0.7 | CLOSED | Lookahead fundamentally incompatible (state rollback) |
| Muon² (second-order) | CLOSED | non-competitive |
| Decoupled embed warmup | FALSIFIED | NaN-invariant across 60× lr variation (PR #252) |
| Trust-region Muon | CLOSED | monotonic worsening; natural update = 20-25% weight norm |
| Lion optimizer aux groups | CLOSED | 0.022 miss; AdamW EM is better in cooldown |

## Key patterns

1. **Annealed μ (0.97→0.90) at n=2**: val=3.2761/ffs=3087.5 — STRONGEST current signal, both bars cleared vs new baseline.
2. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement over PR #139.
3. **Linear cooldown > cosine**: cosine never reached 3.28 target.
4. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.
5. **Lookahead fundamentally incompatible**: SOAP/NorMuon stateful preconditioners can't tolerate param rollback.
6. **Natural Muon update = 20-25% weight norm** (confirmed by fern trust-region telemetry): trust-ratio must be >> 0.10 to avoid cutting signal.
7. **Seed-0 NaN is attention-path driven** (NOT embedding-driven, confirmed PR #252). 123,701,376 nonfinite at blocks.0.attn.proj.bias.
8. **Multi-seed NaN cascade**: HP-induced step 100-1200 (SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter).

## Upcoming decisions

| Time UTC | Student | Event | Expected |
|---|---|---|---|
| ~13:15 | Alphonse | Trial 1 starts | SOAP_PRECOND_FREQ=5 screening data |
| ~13:30 | Frieren | Student posts SENPAI-RESULT | MISS (val=3.2769, ffs=3125) |
| ~15:00 | Tanjiro | Arm A terminal (NS_ITERS=10) | TBD |
| ~15:30 | Thorfinn | n=4 all trials | **STRONG MERGE CANDIDATE** |
| TBD | Edward | GC implementation + screen | First result in ~3h |
| TBD | Askeladd | Depth-LR implementation + screen | First result in ~3h |
| TBD | Fern | NorMuon BC smoke + screen | First result in ~4h |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3112.5 steps.

**If thorfinn n=4 merges** (~15:30): new ffs baseline ~3075-3090. Gap to record = ~45 steps.
**Compounding thorfinn + new axes**: ffs ~3050. Gap to record = ~20 steps.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — n=2 mean ffs=3087.5 — outstanding.
2. **NS_ITERS sweep** (tanjiro #259) — pure computation/precision axis, orthogonal.
3. **SOAP_PRECOND_FREQ=5** (alphonse #256) — tighter eigenbasis, screening data ~13:15.
4. **GC on Muon** (edward #267) — removes low-rank mean from gradient before NS5.
5. **Depth LR scaling** (askeladd #268) — per-block LR structure.
6. **NorMuon BC** (fern #263) — variance EMA cold-start bias correction.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- **NEW** Merge bar: BOTH mean val < 3.27631 AND ffs_mean < 3112.5
- All n=4 statsig: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- All n=3 (1 NaN): mean ≤ 3.27769
- **All new experiments should include `TRUST_THRESHOLD=0.85` to run on new baseline**
- **Lookahead-on-Muon**: do not reassign — fundamentally incompatible (state rollback problem).
- **Muon momentum bias correction**: CLOSED (PR #221). Do not reassign.
