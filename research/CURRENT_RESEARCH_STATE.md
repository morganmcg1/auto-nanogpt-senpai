# SENPAI Research State

- 2026-05-18 11:15 UTC — Cycle 55 (continued)
- No human researcher directives this session.
- ✅ **PR #288 MERGED** (08:35 UTC): Cooldown-only μ anneal 0.95→0.90 — NEW BASELINE. val=3.275350/ffs=3087.5. MU_START/MU_END deprecated; new stack is MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5.
- ✅ **FRIEREN #343 CLOSED** (11:15 UTC): AdamW β2 axis FALSIFIED in BOTH directions. β2=0.99 NaN at step 125; β2=0.90 grad explosion (grad_norm=115698) at step 275 (two consistent crashes). β2=0.95 is a stability window. Reassigned → #373 AdaMuon.
- ✅ **FERN #304 CLOSED** (10:45 UTC): SOAP_PRECOND_FREQ anneal FREQ_START=15→FREQ_END=7 FALSIFIED. n=4 mean val=3.27766/ffs=3125. FREQ=10 stays as stability window. Reassigned → #372 MuonEq-R.
- 🔥 **THORFINN #357 trial 0 STRONG**: MU_COOLDOWN_END=0.87 trial 0 val=**3.274062**, ffs=**3050** — beats baseline by −0.0013 val AND −37.5 ffs. ffs=3050 is below bimodal {3075,3100} norm. Trial 1 in progress.
- ⚠️ **ALPHONSE #359 Arm A FAIL**: MU_COOLDOWN_START=0.92→0.90 trial 0 val=**3.283822**, ffs=-1 — +0.0085 regression. Near-flat (0.02 gap) loses most of 0.95→0.90 benefit. Killing trial 1; Arm B (constant μ=0.90) queued.
- ⚠️ **EDWARD #341 Arm A MISS** (10:00 UTC): SOAP_FREEZE_STEP=1000 mean val=3.28082. Arm B (FREEZE=2000) at step ~1550/3175.
- ⚠️ **NEZUKO #339 trial 0 (Arm B)**: COOLDOWN_FRAC=0.8 OLD stack — val=3.275355 (ties baseline), ffs=3075. Trial 1 in progress.
- ⚠️ **TANJIRO #336 trial 0 (Arm B)**: TARGET_UW=0.50 — val=3.275692, ffs=3100. Marginally worse on both vs baseline. Trial 1 in progress.
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

### TANJIRO #336 — TARGET_UW sweep (Arm A: 0.25, Arm B: 0.50)
- First axis sweep of TARGET_UW (Muon u/w-floor implicit WD) since PR #78.
- With new cooldown-only μ schedule, u_fro dynamics may have changed.

### NEZUKO #339 — cooldown_frac sweep 0.6 and 0.8 (on OLD stack)
- Static since PR #71. Arm A: 0.6, Arm B: 0.8. Running on OLD stack (MU_START/MU_END set).
- Arm A FINISHED (08:21 UTC, `2ysep6xs`): val=3.27583 (T0=3.27723/3125, T1=3.27443/3075), ffs=3100. Ties OLD baseline val, worse ffs → MISS.
- Arm B (COOLDOWN_FRAC=0.8, `jmikalnz`) running, trial 1 in progress. ETA ~10:30 UTC.
- Comparison bar UPDATED: must clear NEW baseline val<3.275350 AND ffs<3087.5 to predeclare n=4 on NEW stack.

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

- **μ cooldown endpoint** (thorfinn #357): more aggressive decay to 0.87/0.85 — direct follow-up to merged PR #288
- **CONTRA_MUON rate** (askeladd #358): never swept since merge at 0.5
- **μ schedule shape** (alphonse #359): constant low μ vs linear decay ablation
- **SOAP eigenbasis freeze** (edward #341): resurrects inconclusive #277 with healthy pod
- **cooldown_frac** (nezuko #339): unchanged since PR #71
- **TARGET_UW** (tanjiro #336): unchanged since PR #78
- **MuonEq-R pre-NS5 row norm** (fern #372): fresh mechanism from arxiv 2603.28254; stateless, zero HPs; orthogonal to NorMuon
- **AdaMuon post-NS5 variance** (frieren #373): per-element EMA scaling of NS5 output; distinct from closed pre-NS5 PR #80
- **μ endpoint extension** (thorfinn #357): trial 0 STRONG (val=3.274062/ffs=3050); if Arm A confirms, extend to Arm B (MU_END=0.85)
- **Cooldown AdaMuon switch** (next frieren follow-up if #373 closes): AdaMuon activated only at cooldown boundary; stacks with PR #288 μ-anneal
- **Muon-VS** (arxiv 2601.14603): pre-NS5 gradient deviation variance; 1.36× step reduction on LLaMA-1.2B; save for next idle student
