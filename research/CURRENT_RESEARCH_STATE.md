# SENPAI Research State

- 2026-05-17 ~17:20 UTC — Cycle 54 (continued)
- No human researcher directives this session.

## CRITICAL BUG FIXED (cycle 54)

`TRUST_THRESHOLD=0.85` was a **silent no-op** — the code reads `ATTN_SOAP_TRUST_THRESHOLD` (line 449). All advisor PRs and BASELINE.md corrected. Students on #271/#273/#275/#276/#277 notified. PR #281 (edward) uses correct var.

## Current baseline ⭐ (UPDATED — PR #219 merged)

**Annealed μ (MU_START=0.97→MU_END=0.90) + Attn-SOAP+trust T=0.85 + CONTRA_MUON=0.5 (PR #219)** — n=4 mean=**3.275835**, ffs_mean=**3087.5** @ train_steps=3175

Previous baseline (PR #212): val=3.27631, ffs=3112.5
- **New merge bar: mean val < 3.275835 AND ffs_mean < 3087.5**
- **All new experiments must include**: `MU_START=0.97 MU_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`

### THORFINN #288 — Annealed μ finer sweep (just assigned)
- Arm A: MU_START=0.97 → MU_END=0.92 (tighter range, less decay). Tests if warmup stabilization is the primary benefit.
- Arm B: cooldown-phase-only anneal MU_COOLDOWN_START=0.95 → MU_COOLDOWN_END=0.90 starting at step 952. Tests if cooldown reactivity is the primary benefit.
- Both arms run on FULL merged stack (MU_START + ATTN_SOAP_TRUST_THRESHOLD=0.85 + CONTRA_MUON=0.5).
- _THORFINN #219 (Annealed μ 0.97→0.90) MERGED ⭐_ — new baseline val=3.275835/ffs=3087.5 (+25 ffs steps vs PR #212).

## Active in-flight experiments

### ASKELADD #286 — Polyak-Ruppert weight averaging (EMA) for terminal eval
- Just assigned. Maintain EMA of weights starting at step ~2000, use EMA weights for terminal val/loss eval.
- Arm A: β=0.999, start=2000 (slow EMA, ~1000 step average). Arm B: β=0.99, start=2500 (fast EMA, cooldown only).
- Zero feedback to optimizer state → no NaN risk (unlike Lookahead). Pure post-processing → orthogonal to all in-flight mechanisms.
- _ASKELADD #268 (depth-LR scaling) FALSIFIED_ — both arms decisively miss. Arm A (up) starves early blocks (never hit 3.28); Arm B (down) starves late blocks (divergence at step 1350). SOAP per-shape preconditioning already absorbs per-layer gradient structure.

### ALPHONSE #277 — SOAP eigenbasis freeze after step K
- Just assigned. After step K, stop refreshing Q (rotation) but continue updating exp_avg_sq (scaling).
- Arm A: K=500 (stable phase), Arm B: K=952 (start of cooldown).
- _ALPHONSE #256 (SOAP_PRECOND_FREQ) FALSIFIED_ — both freq=5 and freq=20 cause multi-seed NaN at step 25. SOAP_PRECOND_FREQ=10 is the unique stability window.

### NEZUKO #273 — Asymmetric Attn-SOAP trust T per param-kind (QK vs VO)
- Implementing. Smoke test → 2-arm screen (T_QK=0.80,T_VO=0.90 vs T_QK=0.90,T_VO=0.80) → n=4 confirm.

### TANJIRO #276 — Decoupled aux cooldown shape (cosine vs none for AdamW groups)
- Just assigned. Muon stays on linear cooldown; aux groups (embed, lm_head, scalars) try cosine or no cooldown.
- _TANJIRO #259 (NS_ITERS sweep) CLOSED_ — multi-seed NaN cascade: NS_ITERS=10 leaves NS5 under-converged → catastrophic update → NaN. NS5 iter axis fully exhausted (also closed: fp32 NS5, 16-iter, and all {8,10,12,14,16} sweep).

### FERN #291 — Annealed SOAP β2 (0.95→0.85): adaptive Gram EMA
- Just assigned. Direct follow-up from #271 mechanistic insight (β2 is the primary control over eigenbasis dynamics, not refresh freq).
- Arm A: β2 anneal 0.95 → 0.85 (full range, ~20-step → ~7-step EMA horizon). Arm B: 0.92 → 0.88 (tight range).
- Composition with merged annealed-μ (#219): both anneals target the same stabilization-vs-reactivity tradeoff across training phases.
- _FERN #271 (decoupled SOAP freq MLP vs ATTN) FALSIFIED_ — Arm A val=3.27633/ffs=3100 (miss); Arm B val=3.27909/ffs=3150 (clear miss). Drift telemetry showed Gram already equilibrates by step 10 → refresh frequency optimum ≈ EMA horizon = 1/(1-β2).

### EDWARD #281 — Per-head SOAP for attention weights
- Just assigned. Split Q.weight (512×512 Gram) into n_head separate (64×64) Grams — one per head.
- Arm A: per-head on Q only. Arm B: per-head on Q/K/V/O all attn weights.
- Expected benefits: 67× faster QR, 8× less Gram memory, head-specific gradient structure captured.
- _EDWARD #267 (GC on Muon) FALSIFIED_ — row-centering makes gradient rank-deficient → NS5 polar-factor instability → NaN at step 25. GC fundamentally incompatible with NS5 polar-factor projection.

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
| NS_ITERS sweep (PR #259) | FALSIFIED | NS_ITERS=10 → multi-seed NaN (91% nonfinite at step 225). NS5 iter axis fully exhausted |
| SOAP_PRECOND_FREQ sweep (PR #256) | FALSIFIED | Both freq=5 AND freq=20 cause multi-seed NaN at step 25. Stability window is uniquely at freq=10 |
| Gradient Centralization on Muon (PR #267) | FALSIFIED | Row-centering → rank-deficient gradient → NS5 polar-factor instability → NaN at step 25 |
| Per-block-depth Muon LR scaling (PR #268) | FALSIFIED | Arm A starves early blocks (never hits 3.28); Arm B starves late blocks (divergence). SOAP per-shape preconditioning already absorbs per-layer gradient structure |
| Decoupled SOAP freq MLP vs ATTN (PR #271) | FALSIFIED | Arm A (freq=5): val=3.27633/ffs=3100 miss; Arm B (freq=20): val=3.27909/ffs=3150 clear miss. Drift telemetry: refresh-freq optimum ≈ EMA horizon = 1/(1-β2) ≈ 10 steps |

## Closed axes (full record)

| Axis | Status | Best |
|---|---|---|
| CONTRA_MUON | EXHAUSTED ⛔ | 0.5 = optimum |
| Per-module init | EXHAUSTED ⛔ | all variants miss by 0.003-0.004 |
| Power-law LR | EXHAUSTED ⛔ | 1.5+2.0 both MISS |
| TARGET_UW retune | EXHAUSTED ⛔ | 0.35 stability bowl |
| SOAP_BETA2 retune | EXHAUSTED ⛔ | 0.85 unstable, 0.92 multi-seed NaN, 0.90 = optimum |
| Adaptive NS5 (16 early) | FALSIFIED | 4/4 trials NaN multi-seed |
| NS_ITERS sweep {8,10,14,16} | FALSIFIED | multi-seed NaN. Only iters=12 is stable — narrow operating point |
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
10. **SOAP eigenbasis stability window**: SOAP_PRECOND_FREQ=10 is uniquely stable. Both 5 and 20 cause multi-seed NaN at step 25 via different mechanisms (too-early Gram vs too-long initial-eigenbasis exposure).
11. **NS5 iter count = 12 is the unique stable operating point**: iters in {8, 10, 14, 16} all cause NaN cascade; 12 is the convergence point for this stack's singular value distribution.
12. **SOAP_PRECOND_FREQ ≈ EMA horizon = 1/(1-β2)** (confirmed PR #271 drift telemetry): refresh frequency optimum is bounded below by Gram EMA equilibration time. At β2=0.90, freq=10 ≈ horizon — refreshing 4× more often only reduces Frobenius drift by ~6%. This couples β2 and freq axes: changing β2 should shift the optimal freq.

## Upcoming decisions

| Time UTC | Student | Event | Expected |
|---|---|---|---|
| ~14:30 | Alphonse | Trial 1 data | SOAP_PRECOND_FREQ=5 screening signal |
| ~15:00 | Tanjiro | Arm A terminal (NS_ITERS=10) | TBD |
| ~16:35 | Thorfinn | **MERGED** (n=4 val=3.275835/ffs=3087.5) | ✅ New baseline |
| ~16:00 | Frieren | Terminal SENPAI-RESULT (overdue) | MISS (close + reassign) |
| TBD | Edward | Per-head SOAP screen (#281) | First result ~3h |
| TBD | Askeladd | Polyak EMA implementation + screen (#286) | First result ~3h |
| TBD | Nezuko | Asymmetric trust telemetry → screen | First screen result ~2-3h |
| TBD | Fern | Annealed SOAP β2 implementation + screen (#291) | First result ~3h |

## Research programme direction

Primary goal: beat record #20 (3030 steps). Current baseline = 3112.5 steps.

**Thorfinn #219 MERGED** (~16:35): new ffs baseline 3087.5. Gap to record = ~57 steps.
**Compounding current in-flight axes**: best case ffs ~3050. Gap to record = ~20 steps.

Most promising paths (ranked):
1. **Annealed μ finer sweep** (thorfinn #288) — cooldown-only arm may unlock further +5-10 ffs. Direct follow-on from merged winner.
2. **MLP-SOAP trust gate** (frieren #275) — symmetric extension of merged PR #212 win.
3. **Asymmetric Attn-SOAP trust QK vs VO** (nezuko #273) — direct follow-up to merged win.
4. **SOAP_PRECOND_FREQ=5** (alphonse #256) — tighter eigenbasis.
5. **Annealed SOAP β2** (fern #291) — direct application of #219 anneal mechanism to SOAP eigenbasis dynamics.
6. **Decoupled aux cooldown shape** (tanjiro #276) — aux groups may benefit from cosine or no cooldown vs linear.
7. **GC on Muon** (edward #267) — removes low-rank mean from gradient before NS5.
8. **Polyak-Ruppert weight EMA** (askeladd #286) — post-processing, orthogonal to all optimizer mechanisms.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- **NEW** Merge bar: BOTH mean val < 3.275835 AND ffs_mean < 3087.5
- All n=4 statsig: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- All n=3 (1 NaN): mean ≤ 3.27769
- **All new experiments must include**: `MU_START=0.97 MU_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`
- **Lookahead-on-Muon**: do not reassign — fundamentally incompatible (state rollback problem).
- **Muon momentum bias correction**: CLOSED (PR #221). Do not reassign.
- **NorMuon EMA bias correction**: CLOSED (PR #263). Global EMA BC is a no-op due to Frobenius renorm. Any future BC attempt must be row-conditional.
