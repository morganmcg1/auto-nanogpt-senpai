# SENPAI Research State

- 2026-05-18 08:45 UTC — Cycle 55 (continued)
- No human researcher directives this session.
- ✅ **PR #288 MERGED** (08:35 UTC): Cooldown-only μ anneal 0.95→0.90 — NEW BASELINE. val=3.275350/ffs=3087.5. MU_START/MU_END deprecated; new stack is MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5.
- ✅ **ASKELADD #319 CLOSED**: Muon LR warmup FALSIFIED (both arms, 100-step and 50-step). NS5 at full LR from step 1 is load-bearing. Reassigned → #358 CONTRA_MUON sweep.
- ✅ **ALPHONSE #312 CLOSED**: AdamW lm_head WD no signal — n=4 p=0.57 (indistinguishable from baseline). Arm B skipped. Reassigned → #359 μ cooldown schedule ablation.
- ⚠️ **FRIEREN #343 Arm A NaN**: ADAMW_BETA2=0.99 shows NaN at step 125 in screen run. β2=0.99 incompatible with eps=1e-10 + current LR (slow EMA + tiny eps → denominator blowup early). Pivoting to Arm B (β2=0.90) with updated stack.

## POD INFRASTRUCTURE NOTE (cycle 54)

**Two r2 pods broken on torch 2.10.0+cu128 + mixed cu12/cu13 nvidia libs**:
- alphonse #303 — FIXED by in-place pip upgrade to torch 2.11.0+cu130. PR closed.
- fern #304 — same fix confirmed; running fine now.

Root cause: mixed cu12/cu13 NCCL/cuDNN with torch 2.10.0+cu128 causes optimizer kernel divergence at steps 2-24, producing full-attention-Gram NaN by first val checkpoint at step 125. Step-1 gradients are bit-identical to healthy peers.

**Operational lesson**: if a pod shows step-125 NaN on the merged baseline, check `torch.__version__` immediately. Peer healthy stack is torch 2.11.0+cu130 cu13-only.

## CRITICAL BUG FIXED (cycle 54)

`TRUST_THRESHOLD=0.85` was a **silent no-op** — the code reads `ATTN_SOAP_TRUST_THRESHOLD` (line 449). All advisor PRs and BASELINE.md corrected. All students on active PRs notified.

## Current baseline ⭐⭐ (PR #288 merged 08:35 UTC 2026-05-18)

**Cooldown-only μ anneal (MU_COOLDOWN_START=0.95→MU_COOLDOWN_END=0.90) + Attn-SOAP+trust T=0.85 + CONTRA_MUON=0.5 (PR #288)**
- n=4 mean val/loss = **3.275350** | ffs_mean = **3087.5** @ train_steps=3175
- W&B run: `qceklszn` (n=4 confirmation, T0=3.27437/3075, T1=3.27600/3100, T2=3.27586/3100, T3=3.27517/3075)
- **Merge bar: mean val < 3.275350 AND ffs_mean < 3087.5** (STRICT — both required)
- **All new experiments must include**: `MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`
- **NOTE**: MU_START and MU_END env vars are DEPRECATED — do NOT use in new assignments
- ffs is bimodal {3075, 3100} — to beat ffs bar requires ≥3 of 4 trials hitting 3075 (mean ≤ 3081.25)

## Active in-flight experiments

### THORFINN #357 — MU_COOLDOWN_END sweep 0.87/0.85 (NEW, just assigned 08:45 UTC)
- Follow-up to merged PR #288: if 0.90 > 0.95 endpoint, maybe 0.87 or 0.85 is better.
- Arm A: MU_COOLDOWN_END=0.87 (keep START=0.95, steeper drop)
- Arm B: MU_COOLDOWN_END=0.85
- Mechanism: more aggressive μ decay at end of cooldown → more Muon reactivity → more trials hit ffs=3075
- Pure env-var change, no code needed

### ASKELADD #358 — CONTRA_MUON sweep 0.4/0.6 (NEW, just assigned 08:45 UTC)
- CONTRA_MUON=0.5 was set at merge, never swept. Axis completely unexplored.
- Arm A: CONTRA_MUON=0.4 (reduce correction 20%)
- Arm B: CONTRA_MUON=0.6 (increase correction 20%)
- If one arm wins clearly, extend to 0.3 or 0.7 in same PR

### ALPHONSE #359 — μ cooldown schedule shape ablation (NEW, just assigned 08:45 UTC)
- Tests whether linear DECAY from 0.95→0.90 is necessary, or whether a flat low μ suffices.
- Arm A: MU_COOLDOWN_START=0.92 MU_COOLDOWN_END=0.90 (nearly flat, small drop)
- Arm B: MU_COOLDOWN_START=0.90 MU_COOLDOWN_END=0.90 (constant μ=0.90, no decay)
- If constant μ=0.90 works: confirms benefit is from LOW ENDPOINT, not decay trajectory; next step: try μ=0.87 constant

### FERN #304 — Annealed SOAP_PRECOND_FREQ ⭐ (Arm A n=4 confirm at ~70%, ETA ~10:30 UTC)
- Arm A: FREQ_START=15 → FREQ_END=7. n=2 near-miss val=3.275851/ffs=3087.5 (Δ+0.000016 on val, tied on ffs).
- **⚠️ STACK NOTE**: fern's n=4 is on OLD stack (MU_START=0.97 MU_END=0.90 at launch time). Now comparing vs NEW baseline val=3.275350. Very unlikely to clear new tighter bar; predeclared close if n=4 mean ≥ 3.275350.
- W&B run (n=4 confirm): `xzwpijuo` at step ~8877/12700 at 08:30 UTC
- After n=4: run Arm B (FREQ_START=7 END=15) on NEW stack if Arm A closes

### EDWARD #341 — SOAP eigenbasis freeze after step K (screen at ~23%, ETA ~5h from 05:20 UTC)
- Resurrects PR #277 axis (closed INCONCLUSIVE due to pod NaN — pod now healthy on torch 2.11.0).
- Arm A: SOAP_FREEZE_STEP=1000 (freeze pre-cooldown). Running: `jt46ri0n` at step 1475 (08:30 UTC).
- Arm B: SOAP_FREEZE_STEP=2000 — queued after Arm A.
- Mechanism: Q eigenbasis rotation refreshes in stable/cooldown phase may add noise without improving preconditioner; freeze may free compute and stabilize SOAP updates.

### TANJIRO #336 — TARGET_UW sweep (Arm A: 0.25, Arm B: 0.50)
- First axis sweep of TARGET_UW (Muon u/w-floor implicit WD) since PR #78.
- With new cooldown-only μ schedule, u_fro dynamics may have changed.

### NEZUKO #339 — cooldown_frac sweep 0.6 and 0.8
- Static since PR #71. Arm A: 0.6 (shorter stable phase), Arm B: 0.8 (longer stable phase).
- Directly affects ffs bimodal boundary: shorter cooldown → earlier ffs candidates.

### FRIEREN #343 — AdamW β2 sweep (Arm A KILLED — NaN, pivoting to Arm B)
- Arm A: ADAMW_BETA2=0.99 → NaN at step 125 (denominator blowup: slow EMA + eps=1e-10). KILLED.
- Arm B: ADAMW_BETA2=0.90 → launching now on NEW stack (MU_COOLDOWN_START/END).
- Note: baseline AdamW β2=0.95 (betas=(0.8, 0.95)). Arm B tests FASTER variance EMA (β2=0.90) vs baseline.

## Recently closed axes (since session start)

| PR | Student | Status | Insight |
|---|---|---|---|
| **#288** | **thorfinn** | **MERGED ⭐** | **Cooldown-only μ anneal 0.95→0.90. val Δ−0.000485 (statsig 2.3×), ffs tied at 3087.5. Mechanism: μ-anneal localizes to cooldown phase.** |
| #319 | askeladd | FALSIFIED | Muon LR warmup both arms miss. NS5 at full LR from step 1 is load-bearing. |
| #312 | alphonse | NO SIGNAL | lm_head WD wd=0.01 p=0.57 vs baseline. n=1 win was seed noise. |
| #316 | nezuko | FALSIFIED | NorMuon β2 cooldown anneal; n=2 mean val=3.278405/ffs=3125. β2 variance buffer ≠ μ. |
| #333 | frieren | FALSIFIED | AdamW eps — both 1e-8 and 1e-12 NaN. eps=1e-10 is a stability window. |
| #313 | frieren | CLOSED (bug) | Z-loss — NaN smokes, code never pushed. |
| #309 | tanjiro | FALSIFIED | AdamW β1 anneal — no AdamW equivalent of NS5 safety net. |
| #295 | nezuko | MISS | Polar Express adaptive NS5 — no benefit at 12-iter budget. |
| #286 | askeladd | FALSIFIED | Polyak-Ruppert EMA — averaging pre-cooldown weights hurts. |
| #276 | tanjiro | FALSIFIED | Decoupled aux cooldown shape — linear optimal for all groups. |
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN. |
| #281 | edward | FALSIFIED | Per-head SOAP — cross-head gradient covariance lost in block-diagonal. |
| #340 | frieren | FALSIFIED | Embed init std=0.5 NaN at step 25. Init scale load-bearing under adam_embed lr=0.30. |
| #268 | askeladd | FALSIFIED | Depth-LR scaling — SOAP absorbs per-layer structure. |
| #273 | nezuko | FALSIFIED | Asymmetric QK/VO trust — V low cos_row is TRUE signal. |
| #271 | fern | FALSIFIED | Decoupled SOAP freq MLP vs ATTN — refresh-freq optimum ≈ EMA horizon. |
| #275 | frieren | FALSIFIED | MLP-SOAP trust gate — MLP precond robust to rotation noise. |
| #277 | alphonse | CLOSED (infra) | SOAP eigenbasis freeze — pod NaN, NOT falsified. Resurrected as #341. |

## Key patterns (updated cycle 55)

1. **Cooldown-only μ anneal MERGED (PR #288)**: val=3.275350/ffs=3087.5. Mechanism: cooldown reactivity is the driver, NOT warmup stabilization. MU_COOLDOWN_START/END replaces MU_START/MU_END.
2. **Annealed μ (0.97→0.90) MERGED (PR #219)**: Superseded by PR #288's cleaner mechanism.
3. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement.
4. **ffs quantization**: bimodal {3075, 3100}, 25-step granularity. To beat ffs bar, need ≥3/4 trials at 3075.
5. **Linear cooldown > cosine**: cosine on Muon (r1) val=3.2882; cosine on aux alone (PR #276) falsified.
6. **SOAP_PRECOND_FREQ=10 = stability window**: both 5 AND 20 NaN.
7. **NS5 iter=12 = unique stable operating point**: 8, 10, 14, 16 all NaN cascade.
8. **Muon NS5 orthogonalization at full LR from step 1 is load-bearing**: any LR warmup delays early-training convergence (#319 falsified both arms).
9. **Stability windows (don't touch)**: FREQ=10, NS5_iter=12, SOAP_β2≥0.90, AdamW eps=1e-10.
10. **Lookahead incompatible**: SOAP/NorMuon stateful preconditioners can't tolerate param rollback.
11. **Gradient noise + NS5 = catastrophic**: ×35 Frobenius amplification.

## Open axes with potential

- **μ cooldown endpoint** (thorfinn #357): more aggressive decay to 0.87/0.85 — direct follow-up to merged PR #288
- **CONTRA_MUON rate** (askeladd #358): never swept since merge at 0.5
- **μ schedule shape** (alphonse #359): constant low μ vs linear decay ablation
- **SOAP eigenbasis freeze** (edward #341): resurrects inconclusive #277 with healthy pod
- **cooldown_frac** (nezuko #339): unchanged since PR #71
- **TARGET_UW** (tanjiro #336): unchanged since PR #78
- **SOAP annealed FREQ** (fern #304): near-miss on old baseline; may close on new tighter baseline
- **AdamW β2=0.90** (frieren #343 Arm B): fast variance EMA vs baseline 0.95
