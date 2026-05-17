# SENPAI Research State

- 2026-05-17 20:05 UTC — Cycle 54 (continued)
- No human researcher directives this session.

## CRITICAL BUG FIXED (cycle 54)

`TRUST_THRESHOLD=0.85` was a **silent no-op** — the code reads `ATTN_SOAP_TRUST_THRESHOLD` (line 449). All advisor PRs and BASELINE.md corrected. All students on active PRs notified.

## Current baseline ⭐ (UPDATED — PR #219 merged)

**Annealed μ (MU_START=0.97→MU_END=0.90) + Attn-SOAP+trust T=0.85 + CONTRA_MUON=0.5 (PR #219)**
- n=4 mean val/loss = **3.275835** | ffs_mean = **3087.5** @ train_steps=3175
- W&B run: `47bb0bf2` (n=4 confirmation)
- **New merge bar: mean val < 3.275835 AND ffs_mean < 3087.5** (STRICT — both required)
- **All new experiments must include**: `MU_START=0.97 MU_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`

## Active in-flight experiments

### THORFINN #288 — Annealed μ finer sweep
- Arm A: MU_START=0.97 MU_END=0.92 (tighter range). Trial 0: val=3.27801, ffs=3125 (miss). Trial 1: step ~3050/3175, val≈3.282 — **likely miss**. 2-trial mean will probably be ~3.280, not beating 3.275835.
- Arm B (planned): cooldown-phase-only anneal MU_COOLDOWN_START=0.95→0.90 from step 952. Expected next after Arm A confirmed miss.
- Expected outcome: Arm A closes with miss; Arm B is the more interesting test (does cooldown reactivity drive the PR #219 benefit?).

### TANJIRO #276 — Decoupled aux cooldown shape
- Arm A (cosine): val=3.2770, ffs=3100 — **misses both bars** (W&B `lkh6dlbz`)
- Arm B (none): step ~2700/3175 at 19:50 UTC, val_best=3.3557 — **tracking to miss badly**
- Expected: both arms miss. Likely axis closure soon.

### ASKELADD #286 — Polyak-Ruppert weight averaging (EMA)
- Smoke run `0pd69f50` (polyak-b999-s2000) started 19:46 UTC — in flight
- No terminal result yet. Implementation confirmed (pod active). Awaiting first result.

### EDWARD #281 — Per-head SOAP for attention weights
- Picked up 18:58 UTC. Architecture correction confirmed: 6 heads × 128 head_dim (Q.weight = 768×768 → 6× 128×128 Gram matrices). Implementing.
- No terminal result yet.

### NEZUKO #295 — Polar Express adaptive NS5 coefficients
- Original arms (3,-3,1) and (2.5,-2,0.75) had math bugs (sum≠1, period-2 oscillation). Pivoted to Polar Express adaptive scheme per student's math review.
- New arms: per-iteration adaptive (a,b,c) = [(8,-16,8), (4,-8,4), (3,-4,1.5), then (2,-1.5,0.5) for iters 4-12].
- Pod at 100% GPU, training in flight. No terminal result yet.

### FRIEREN #275 — MLP-SOAP trust gate
- Rebased onto PR #219 baseline. Implementation started 17:31 UTC.
- Pod at 100% GPU. No terminal result yet.

### FERN #304 — Annealed SOAP_PRECOND_FREQ (just assigned, NEW)
- Arm A: FREQ_START=15 → FREQ_END=7 (slower refreshes early, faster late)
- Arm B: FREQ_START=7 → FREQ_END=15 (faster refreshes early, slower late)
- Direct follow-up from #291 falsification: keeps β2=0.90 static (safe), tests the orthogonal anneal axis that respects the matching constraint `FREQ ≈ 1/(1-β2)`.

### ALPHONSE #303 — Pod diagnostic + clean baseline repro (OPERATIONAL — not training)
- All 8 prior runs NaN'd at step 25-125 including a no-freeze baseline diagnostic — pod-specific instability.
- Assigned: env fingerprint + hard reset to clean advisor branch + baseline repro. 
- No training experiment until pod health confirmed. If repro passes → fresh hypothesis assigned.

## Recently closed axes

| PR | Student | Status | Insight |
|---|---|---|---|
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN because β2=0.92 is already in instability zone |
| #277 | alphonse | CLOSED (untested) | Pod-specific instability; freeze mechanism NOT falsified, just untest-able on this pod |
| #276 | tanjiro | CLOSING SOON | Both cosine and none arms miss; decoupled aux cooldown axis spent |
| #268 | askeladd | FALSIFIED | Depth-LR scaling; SOAP already absorbs per-layer gradient structure |
| #273 | nezuko | FALSIFIED | Asymmetric QK/VO trust; V's low cos_row is TRUE signal, not false negative |
| #271 | fern | FALSIFIED | Decoupled SOAP freq MLP vs ATTN; refresh-freq optimum ≈ EMA horizon = 1/(1-β2) |

## Key patterns (updated cycle 54)

1. **Annealed μ (0.97→0.90) MERGED (PR #219)**: n=4 mean val=3.275835/ffs=3087.5. New baseline.
2. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement.
3. **Linear cooldown > cosine**: cosine never reached 3.28.
4. **SOAP_PRECOND_FREQ=10 = unique stability window**: both 5 AND 20 cause NaN.
5. **NS5 iter=12 = unique stable operating point**: 8, 10, 14, 16 all NaN cascade.
6. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.
7. **Lookahead fundamentally incompatible**: SOAP/NorMuon stateful preconditioners can't tolerate param rollback.
8. **Natural Muon update = 20-25% weight norm**: trust-ratio must be >> 0.10 to avoid cutting signal.
9. **Seed-0 NaN is attention-path driven** (NOT embedding-driven, confirmed PR #252).
10. **SOAP eigenbasis stability window**: FREQ=10 uniquely stable; 5 and 20 both fail via different mechanisms.
11. **NS5 iter=12 uniquely stable**: confirmed across multiple NaN investigations.
12. **SOAP_PRECOND_FREQ ≈ EMA horizon = 1/(1-β2)** (PR #271): refresh optimum coupled to β2. At β2=0.90, FREQ=10 ≈ 1/(1-0.90) = 10.
13. **V's low cos_row is TRUE signal** (PR #273): 12% on_fraction for V at T=0.85 reflects genuinely fast eigenbasis rotation; forcing SOAP on unstable V eigenbasis → +0.005 val degradation.
14. **μ-anneal works; β2-anneal doesn't** (PR #291): μ controls scalar momentum buffer (robust to rate changes); β2 controls Gram EMA matrix (eigenvectors highly sensitive to perturbations, especially when they haven't converged early in training). Additionally, β2 is coupled to FREQ via the matching constraint — changing β2 breaks the optimal FREQ=10 coupling.
15. **Pod-specific instability confirmed on alphonse pod**: all runs NaN at step 125 regardless of hypothesis (including no-freeze baseline control). Peer pods healthy on identical config. Pod diagnostic in progress.

## Research programme direction

**Primary goal**: beat val < 3.275835 (current n=4 mean) AND ffs < 3087.5.
Gap to record #20 (~3030 ffs steps): ~57.5 ffs steps.

**Most promising active paths**:
1. **Thorfinn #288 Arm B** (cooldown-only μ anneal) — isolates whether cooldown reactivity drives PR #219's win. High prior if Arm A confirms miss.
2. **Frieren #275** (MLP-SOAP trust gate) — symmetric extension of merged PR #212 win.
3. **Nezuko #295** (Polar Express adaptive NS5) — fresh axis; per-iteration adaptive coefficients.
4. **Edward #281** (per-head SOAP) — head-specific eigenbasis for attention weights.
5. **Fern #304** (annealed SOAP_PRECOND_FREQ) — orthogonal axis from #291, respects matching constraint.
6. **Askeladd #286** (Polyak-Ruppert EMA) — orthogonal post-processing; pure eval gain.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.275835 AND ffs_mean < 3087.5
- n=4 statsig: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- n=3 (1 NaN): mean ≤ 3.27769
- **Lookahead-on-Muon**: do not reassign — fundamentally incompatible.
- **Muon momentum bias correction**: CLOSED (PR #221). Do not reassign.
- **NorMuon EMA bias correction**: CLOSED (PR #263). Do not reassign.
- **SOAP_BETA2 < 0.90**: do not use. 0.92 causes multi-seed NaN; 0.85 breaks FREQ coupling.
- **Alphonse pod**: all runs NaN until pod diagnostic passes. Do not assign training hypothesis.
