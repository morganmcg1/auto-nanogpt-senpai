# SENPAI Research State

- 2026-05-18 12:15 UTC — Cycle 55 (continued)
- No human researcher directives this session (Issue #164 is on r3 branch, not r2).
- ✅ **PR #288 MERGED** (08:35 UTC): Cooldown-only μ anneal 0.95→0.90 — NEW BASELINE. val=3.275350/ffs=3087.5. MU_START/MU_END deprecated; new stack is MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5.
- ✅ **FRIEREN #343 CLOSED** (11:15 UTC): AdamW β2 axis FALSIFIED in BOTH directions. β2=0.99 NaN at step 125; β2=0.90 grad explosion. β2=0.95 is a stability window. Reassigned → #373 AdaMuon.
- ✅ **FERN #304 CLOSED** (10:45 UTC): SOAP_PRECOND_FREQ anneal FREQ_START=15→FREQ_END=7 FALSIFIED. n=4 mean val=3.27766/ffs=3125. FREQ=10 stays as stability window. Reassigned → #372 MuonEq-R.
- ✅ **NEZUKO #339 CLOSED** (12:10 UTC): cooldown_frac axis FALSIFIED. Arm A (0.6) val=3.27583/ffs=3100 fails both bars. Arm B (0.8) val=3.275640/ffs=3075 beats OLD val marginally, FAILS NEW val (+0.000290). cooldown_frac=0.7 stays. Reassigned → #375 Muon-VS.
- ✅ **TANJIRO #336 CLOSED** (12:10 UTC): TARGET_UW axis FALSIFIED in BOTH directions. Arm A (0.25) val=3.28570/ffs=-1 (kill-gated, +0.010 regression). Arm B (0.50) n=2 val=3.276335/ffs=3112.5 fails both bars. TARGET_UW=0.35 is local optimum. Reassigned → #376 Cooldown AdaMuon Switch.
- 🔥 **THORFINN #357 trial 0 STRONG**: MU_COOLDOWN_END=0.87 trial 0 val=**3.274062**, ffs=**3050** — beats baseline by −0.0013 val AND −37.5 ffs. ffs=3050 is below bimodal {3075,3100} norm. Trial 1 in progress.
- ⚠️ **ALPHONSE #359 Arm A FAIL**: MU_COOLDOWN_START=0.92→0.90 trial 0 val=**3.283822**, ffs=-1 — +0.0085 regression. Killing trial 1; Arm B (constant μ=0.90) queued.
- ⚠️ **EDWARD #341 Arm A MISS** (10:00 UTC): SOAP_FREEZE_STEP=1000 mean val=3.28082. Arm B (FREEZE=2000) running.
- ✅ **ASKELADD #319 CLOSED**: Muon LR warmup FALSIFIED. Reassigned → #358 CONTRA_MUON sweep.
- ✅ **ALPHONSE #312 CLOSED**: lm_head WD no signal. Reassigned → #359 μ cooldown ablation.

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

### FERN #372 — MuonEq-R: pre-NS5 row normalization (NEW, assigned 10:55 UTC)
- Fresh mechanism from arxiv 2603.28254 (MuonEq, 2026-03). Validated on FineWeb GPT2-small (PPL 25.23→24.88).
- Pre-NS5: normalize rows of momentum matrix by L2 norms before NS5, ensuring isotropic input.
- Orthogonal to NorMuon (post-NS5) and Contra-Muon (pre-momentum). Stateless, no new EMA buffers.
- Arm A: MUONEQ_R=1 MUONEQ_EPS=1e-8 (safe default)
- Arm B: MUONEQ_R=1 MUONEQ_EPS=1e-6 (coarser normalization)
- ~10 lines code change to `zeropower_via_newtonschulz5` function

### EDWARD #341 — SOAP eigenbasis freeze after step K (Arm A MISS, Arm B running)
- Resurrects PR #277 axis (closed INCONCLUSIVE due to pod NaN — pod now healthy on torch 2.11.0).
- Arm A: SOAP_FREEZE_STEP=1000 — `jt46ri0n` FINISHED 10:00 UTC, mean val=**3.28082** (+0.0055 over baseline) — MISS. Eigenbasis refresh past step 1000 IS load-bearing.
- Arm B: SOAP_FREEZE_STEP=2000 — `604ypwx2` started 10:09 UTC, step ~575/3175. Tests less aggressive freeze (allows refresh through early cooldown). ETA ~5h.
- Mechanism: Q eigenbasis rotation continues to update meaningfully through cooldown; freezing at step 1000 dropped 0.0055 val/loss.

### NEZUKO #375 — Muon-VS: pre-NS5 gradient deviation variance (NEW, assigned 12:15 UTC)
- Fresh mechanism from arxiv 2601.14603. Reported 1.36× optimizer step reduction on LLaMA-1.2B.
- Pre-NS5: Γ_t EMA of (M_{t-1} − G_t)⊙² with bias correction; scale momentum coords by 1/√(Γ̂_t+ε).
- Complementary to AdaMuon (PR #373) which scales POST-NS5 output. Muon-VS scales NS5 INPUT.
- Categorically distinct from closed PR #80 (Muon² used generic pre-NS5 Adam variance without (M_{t-1}−G_t)⊙² deviation signal).
- Arm A: MUON_VS=1 MUON_VS_BETA=0.95
- Arm B: MUON_VS=1 MUON_VS_BETA=0.90
- ~15 lines code: GDV buffer (`state["gdv"]`) + prev_momentum cache + pre-NS5 division.

### TANJIRO #376 — Cooldown-Phase AdaMuon Switch (NEW, assigned 12:15 UTC)
- Hybrid mechanism: AdaMuon post-NS5 variance scaling, but ONLY during cooldown phase (step ≥ ~2222).
- Stacks with PR #288 cooldown-only μ-anneal: μ-anneal acts on scalar momentum, variance scaling acts on per-element NS5 output. Orthogonal axes both activated at same boundary.
- Reference: arxiv 2507.11005 (AdaMuon), arxiv 2510.25000 (variance adaptation is SOAP's per-step advantage).
- Arm A: ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.95 ADAMUON_COOLDOWN_INIT=rms (RMS warm-start)
- Arm B: ADAMUON_COOLDOWN_ONLY=1 ADAMUON_BETA2=0.99 ADAMUON_COOLDOWN_INIT=ones (cold start)
- ~25 lines code: lazy buffer init at cooldown boundary, EMA update, RMS-preserving rescale.
- Complementary to FRIEREN #373 (full-training AdaMuon). Either outcome is informative.

### FRIEREN #373 — AdaMuon: post-NS5 per-element variance scaling (NEW, assigned 11:15 UTC)
- Mechanism: maintain EMA of squared NS5 outputs V_t = β2·V_{t-1} + (1-β2)·O_t², scale update by 1/√(V_t+eps) with RMS rescaling. Stacks on top of existing NorMuon (row-level) and Contra-Muon.
- Distinct from closed PR #80 (pre-NS5 Adam variance). Orthogonal to NorMuon (post-NS5, per-element vs per-row).
- Reference: arxiv 2507.11005 (AdaMuon). Prior work closed ~0.014 val gap vs vanilla Muon.
- Arm A: ADAMUON=1 ADAMUON_BETA2=0.95 (conservative EMA)
- Arm B: ADAMUON=1 ADAMUON_BETA2=0.99 (slow EMA, more stable variance)
- Requires ~30 lines code: `adamuon_v` state buffer added to Muon state init + EMA update in `contra_normuon_update`

## Recently closed axes (since session start)

| PR | Student | Status | Insight |
|---|---|---|---|
| **#288** | **thorfinn** | **MERGED ⭐** | **Cooldown-only μ anneal 0.95→0.90. val Δ−0.000485 (statsig 2.3×), ffs tied at 3087.5. Mechanism: μ-anneal localizes to cooldown phase.** |
| #339 | nezuko | FALSIFIED | cooldown_frac sweep 0.6/0.8 both miss NEW baseline. Arm B beats OLD val by −0.000195/−12.5 ffs (within noise); cooldown_frac=0.7 stays. PR #288 raised the bar past Arm B's reach. |
| #336 | tanjiro | FALSIFIED | TARGET_UW=0.35 is local optimum. Arm A (0.25) kill-gated at +0.010 regression; Arm B (0.50) fails both bars by +0.0005/+25. Floor's implicit WD remains load-bearing. |
| #319 | askeladd | FALSIFIED | Muon LR warmup both arms miss. NS5 at full LR from step 1 is load-bearing. |
| #312 | alphonse | NO SIGNAL | lm_head WD wd=0.01 p=0.57 vs baseline. n=1 win was seed noise. |
| #343 | frieren | FALSIFIED | AdamW β2 both directions crash: β2=0.99 NaN at step 125, β2=0.90 grad explosion step 275. β2=0.95 is stability window. |
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

- **μ cooldown endpoint** (thorfinn #357): more aggressive decay to 0.87/0.85 — direct follow-up to merged PR #288. Trial 0 STRONG (val=3.274062/ffs=3050).
- **CONTRA_MUON rate** (askeladd #358): never swept since merge at 0.5
- **μ schedule shape** (alphonse #359): constant low μ vs linear decay ablation. Arm A (near-flat) FAILED; Arm B (constant μ=0.90) queued.
- **SOAP eigenbasis freeze** (edward #341): resurrects inconclusive #277. Arm A (FREEZE=1000) MISS; Arm B (FREEZE=2000) running.
- **MuonEq-R pre-NS5 row norm** (fern #372): arxiv 2603.28254; stateless, zero HPs; orthogonal to NorMuon
- **AdaMuon post-NS5 variance** (frieren #373): per-element EMA scaling of NS5 output; arxiv 2507.11005
- **Muon-VS pre-NS5 gradient deviation** (nezuko #375): arxiv 2601.14603; complementary to AdaMuon (scales NS5 input vs output)
- **Cooldown-Phase AdaMuon Switch** (tanjiro #376): AdaMuon activated only at cooldown boundary; stacks with PR #288 μ-anneal
- **Cooldown shape (linear/cosine/poly)** [from nezuko #339 follow-up]: never directly compared post-PR #288; new candidate hypothesis
- **Diagnostic logging — uw_ratio_mean, uw_floor_fire_rate** [from tanjiro #336 follow-up]: cheap to add, decisive for future regularization-axis work; could be standalone PR
- **Per-optimizer cooldown** [from nezuko #339 follow-up]: split cooldown_frac across AdamW vs Muon param groups; untested
