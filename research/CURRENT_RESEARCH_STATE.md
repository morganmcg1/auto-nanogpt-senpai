# SENPAI Research State

- 2026-05-17 ~14:30 UTC — Cycle 54 (continued)
- No human researcher directives this session.

## Current baseline ⭐ (UPDATED — PR #212 merged)

**Attn-SOAP+trust T=0.85 + Contra+SOAP-MLP + CONTRA_MUON=0.5 (PR #212)** — n=4 mean=**3.27631**, ffs_mean=**3112.5** @ train_steps=3175

Previous baseline (PR #139): val=3.27648, ffs=3118.75

## 🚀 WATCH: THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 2/4 complete

- Screen trial (standalone): val=**3.2755**, ffs=**3075**
- n=4 confirmation (W&B 47bb0bf2): 2/4 trials done, best val=3.27697, best ffs=3100
- **Caution**: n=4 launched before PR #212 merge — running WITHOUT TRUST_THRESHOLD=0.85
- ETA all 4 trials ~16:30-17:00 UTC
- If n=4 mean val < 3.27631 AND ffs < 3112.5 → merge. If val barely misses, rerun with TRUST_THRESHOLD=0.85 for proper compounding test.

## Active in-flight experiments

### NEZUKO #273 — Asymmetric Attn-SOAP trust T per param-kind (QK vs VO)
- Just assigned. Smoke test → 2-arm screen (T_QK=0.80,T_VO=0.90 vs T_QK=0.90,T_VO=0.80) → n=4 confirm.
- Motivated by merged PR #212 win — tests whether a single T=0.85 for all attn params is suboptimal.
- Per-kind telemetry (q/k/v/proj cos_row/col) already in optimizer — will give diagnostic data even on miss.

### ALPHONSE #256 — SOAP_PRECOND_FREQ=5 screen n=4
- Trial 0 NaN'd (expected seed-0). Trial 1 running ~step 2500+. Screening data expected soon.

### TANJIRO #259 — NS_ITERS sweep (Arm A = NS_ITERS=10, n=4)
- Running. Terminal ~15:00 UTC.

### FERN #271 — Decoupled SOAP eigenbasis refresh freq: MLP vs ATTN
- Just assigned. Arm A: SOAP_PRECOND_FREQ_ATTN=5; Arm B: SOAP_PRECOND_FREQ_ATTN=20.

### EDWARD #267 — Gradient Centralization on Muon (Yong et al 2020)
- Awaiting implementation + smoke test. First result ~3h.

### ASKELADD #268 — Per-block-depth Muon LR scaling
- Awaiting implementation + smoke test. First result ~3h.

### FRIEREN #275 — MLP-SOAP trust gate (just assigned)
- Just assigned. Adds trust gate to MLP-SOAP (symmetric extension of merged PR #212's attn trust gate).
- Two arms: T_mlp=0.85 and T_mlp=0.90. Telemetry-first: MLP cos_row/col data will inform arm selection.
- ~5-line code change using existing soap_refresh infrastructure.

_FRIEREN #254 (fp32 NS5) CLOSED_ — MISS (val=3.2769, ffs=3125 vs new baseline 3.27631/3112.5). NS5 precision axis exhausted.

## Closed axes this session

| Axis | Status | Notes |
|---|---|---|
| Decoupled embed warmup (PR #252) | FALSIFIED | NaN-invariant 60× lr variation — attn path is real trigger |
| Trust-region Muon (PR #245) | CLOSED | Monotonic worsening; Muon update = 20-25% weight norm, cannot be clamped at 5-10% |
| Lookahead on Muon (PR #251) | CLOSED | Periodic param rollback breaks 3-layer stateful preconditioner SOAP/NorMuon/Muon |
| Lion aux groups (PR #239) | CLOSED | Monotonic miss; AdamW second-moment is essential in cooldown for aux groups |
| NorMuon bias correction (PR #263) | CLOSED | Fern's analysis: Frobenius renorm (lines 501-504) cancels global scalar prefactor — BC is a no-op; any EMA BC must be row-conditional or modify the renorm step itself |

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
| NorMuon EMA bias correction | CLOSED | mathematical no-op due to Frobenius renorm (PR #263) |

## Key patterns

1. **Annealed μ (0.97→0.90) at n=2**: val=3.2761/ffs=3087.5 — STRONGEST current signal, both bars cleared vs new baseline.
2. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement over PR #139.
3. **Linear cooldown > cosine**: cosine never reached 3.28 target.
4. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.
5. **Lookahead fundamentally incompatible**: SOAP/NorMuon stateful preconditioners can't tolerate param rollback.
6. **Natural Muon update = 20-25% weight norm** (confirmed by fern trust-region telemetry): trust-ratio must be >> 0.10 to avoid cutting signal.
7. **Seed-0 NaN is attention-path driven** (NOT embedding-driven, confirmed PR #252). 123,701,376 nonfinite at blocks.0.attn.proj.bias.
8. **Multi-seed NaN cascade**: HP-induced step 100-1200 (SOAP_BETA2=0.85, TARGET_UW=0.30, adaptive-NS 16-iter).
9. **Frobenius renorm scrubs scalar prefactors** (confirmed PR #263): any EMA bias-correction on NorMuon must be row-conditional or modify the renorm step itself.

## Upcoming decisions

| Time UTC | Student | Event | Expected |
|---|---|---|---|
| ~14:30 | Alphonse | Trial 1 data | SOAP_PRECOND_FREQ=5 screening signal |
| ~15:00 | Tanjiro | Arm A terminal (NS_ITERS=10) | TBD |
| ~15:30 | Thorfinn | n=4 all trials | **STRONG MERGE CANDIDATE** |
| ~16:00 | Frieren | Terminal SENPAI-RESULT (overdue) | MISS (close + reassign) |
| TBD | Edward | GC implementation + screen | First result ~3h |
| TBD | Askeladd | Depth-LR implementation + screen | First result ~3h |
| TBD | Nezuko | Asymmetric trust telemetry → screen | First screen result ~2-3h |
| TBD | Fern | Decoupled SOAP freq screen | First result ~3h |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3112.5 steps.

**If thorfinn n=4 merges** (~15:30): new ffs baseline ~3075-3090. Gap to record = ~45 steps.
**Compounding thorfinn + new axes**: ffs ~3050. Gap to record = ~20 steps.

Most promising paths (ranked):
1. **Annealed μ Arm B n=4** (thorfinn #219) — n=2 mean ffs=3087.5 — outstanding.
2. **Asymmetric Attn-SOAP trust QK vs VO** (nezuko #273) — direct follow-up to merged win.
3. **NS_ITERS sweep** (tanjiro #259) — pure computation/precision axis, orthogonal.
4. **SOAP_PRECOND_FREQ=5** (alphonse #256) — tighter eigenbasis, screening data soon.
5. **Decoupled SOAP freq MLP vs ATTN** (fern #271) — orthogonal to attn trust gating.
6. **GC on Muon** (edward #267) — removes low-rank mean from gradient before NS5.
7. **Depth LR scaling** (askeladd #268) — per-block LR structure.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- **NEW** Merge bar: BOTH mean val < 3.27631 AND ffs_mean < 3112.5
- All n=4 statsig: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- All n=3 (1 NaN): mean ≤ 3.27769
- **All new experiments should include `TRUST_THRESHOLD=0.85` to run on new baseline**
- **Lookahead-on-Muon**: do not reassign — fundamentally incompatible (state rollback problem).
- **Muon momentum bias correction**: CLOSED (PR #221). Do not reassign.
- **NorMuon EMA bias correction**: CLOSED (PR #263). Global EMA BC is a no-op due to Frobenius renorm. Any future BC attempt must be row-conditional.
