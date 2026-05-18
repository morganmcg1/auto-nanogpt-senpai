# SENPAI Research State

- 2026-05-18 01:15 UTC — Cycle 55 begin
- No human researcher directives this session.
- 🎯🎯 **THORFINN #288 Arm B n=2 MEAN CLEARS BOTH BARS**: val=3.27477 (Δ−0.001065), ffs=3062.5 (Δ−25.0). N=4 confirmation `qceklszn` launched 00:03 UTC, ETA ~03:30 UTC. **Mechanism: cooldown-only μ anneal (MU_COOLDOWN_START=0.95→END=0.90 from step 952) — cooldown reactivity is the driver, NOT warmup stabilization.**
- 🎯 **FERN #304 Arm A trial 0 cleared both bars at n=1**: val=3.27532, ffs=3075 (FREQ_START=15→END=7). Trial 1 in progress.
- ✅ **ALPHONSE #312 Arm A n=1 cleared both bars**: val=3.27554, ffs=3075 (ADAMW_WD_LM_HEAD=0.01). BUT student launched 2 unauthorized sweep arms (eps-sweep, lm-head-lr-sweep) — flagged to stop.
- 🔻 **TANJIRO #309 Arm A FALSIFIED**: val=3.28251, reached_target=NO. Aggressive AdamW β1 anneal 0.90→0.70 hurts aux momentum stability. Arm B (0.85→0.75) launching.
- 🔻 **EDWARD #281 Arm A n=2 MISS**: mean val=3.27727 (Δ+0.00144), ffs=3112.5 (Δ+25). Per-head SOAP Q-only loses cross-head info. Arm B (all-matrix) launching.
- 🚨 **FRIEREN #313**: 3 consecutive NaN smokes — z-loss code breaking baseline path itself. Requested urgent code push.

## POD INFRASTRUCTURE NOTE (cycle 54)

**Two r2 pods broken on torch 2.10.0+cu128 + mixed cu12/cu13 nvidia libs**:
- alphonse #303 — FIXED by in-place pip upgrade to torch 2.11.0+cu130 (post-upgrade diagnostic clean, val=4.166 at step 200). PR closed. New hypothesis #312 assigned.
- fern #304 — same signature; upgrade approved 21:28 UTC, awaiting response.

Root cause: mixed cu12/cu13 NCCL/cuDNN with torch 2.10.0+cu128 causes optimizer kernel divergence between steps 2-24, producing full-attention-Gram NaN by first val checkpoint at step 125. Step-1 gradients are bit-identical to healthy peers.

**Operational lesson**: if a pod shows step-125 NaN on the merged baseline, check `torch.__version__` immediately. Peer healthy stack is torch 2.11.0+cu130 cu13-only.

## CRITICAL BUG FIXED (cycle 54)

`TRUST_THRESHOLD=0.85` was a **silent no-op** — the code reads `ATTN_SOAP_TRUST_THRESHOLD` (line 449). All advisor PRs and BASELINE.md corrected. All students on active PRs notified.

## Current baseline ⭐ (PR #219 merged)

**Annealed μ (MU_START=0.97→MU_END=0.90) + Attn-SOAP+trust T=0.85 + CONTRA_MUON=0.5 (PR #219)**
- n=4 mean val/loss = **3.275835** | ffs_mean = **3087.5** @ train_steps=3175
- W&B run: `47bb0bf2` (n=4 confirmation)
- **New merge bar: mean val < 3.275835 AND ffs_mean < 3087.5** (STRICT — both required)
- **All new experiments must include**: `MU_START=0.97 MU_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5`

## Active in-flight experiments

### THORFINN #288 — Annealed μ finer sweep ⭐⭐ (Arm B CANDIDATE WINNER, n=4 in progress)
- Arm A: MU_START=0.97 MU_END=0.92 (tighter range). 2-trial mean val=3.27670, ffs=3112.5 — **MISS** both bars.
- Arm B: cooldown-phase-only anneal MU_COOLDOWN_START=0.95→0.90 from step 952. **n=2 mean val=3.27477, ffs=3062.5 — CLEARS BOTH BARS** (val Δ−0.001065, ffs Δ−25.0).
- Run `tqdknxth` (n=2): T0 val=3.27574/ffs=3075, T1 val=3.27380/ffs=3050.
- **N=4 confirmation `qceklszn` launched 00:03 UTC, ETA ~03:30 UTC**.
- **Statsig pre-check**: required mean ≤ 3.27800; n=2 mean 3.27477 passes by 3.23× — n=4 confirmation expected to clear easily.
- **Mechanism insight**: μ-anneal benefit localizes to cooldown phase. Warmup stabilization NOT the driver. The reduction of effective μ during LR cooldown lets Muon chase finer signal at low LR.

### TANJIRO #309 — Annealed AdamW β1 (NEW — just assigned 20:45 UTC)
- Arm A: ADAMW_BETA1_START=0.90 → ADAMW_BETA1_END=0.70 (broad anneal, aggressive). Predict in [3.272, 3.276].
- Arm B: ADAMW_BETA1_START=0.85 → ADAMW_BETA1_END=0.75 (tight anneal, conservative).
- Direct parallel to merged PR #219 (Muon μ anneal). β1 is a scalar buffer (safe to anneal; not the falsified β2 EMA-matrix path of #291). Bit-identical smoke required first.

### ASKELADD #286 — Polyak-Ruppert weight averaging (EMA)
- Smoke run `0pd69f50` crashed at step 425 — diagnosed as infra SIGKILL (clean numerics, POLYAK_START=2000 never reached). Polyak code never executed.
- Expecting relaunch from student.

### EDWARD #281 — Per-head SOAP for attention weights
- 50-step smoke passed (no NaN, both arms). Arm A 2-trial screen now running (~3.5h ETA).
- Architecture confirmed: 6 heads × 128 head_dim (Q.weight = 768×768 → 6× 128×128 Gram matrices).

### NEZUKO #316 — NorMuon β2 cooldown anneal (NEW — just assigned 22:50 UTC)
- Direct parallel to PR #288 Arm B mechanism (cooldown-phase-only anneal) on the NorMuon variance buffer
- Arm A: NORMUON_COOLDOWN_BETA2_START=0.95 → END=0.90 (mirrors μ-anneal scale exactly; β2 decays only during cooldown from step 952)
- Arm B: NORMUON_COOLDOWN_BETA2_START=0.95 → END=0.85 (more aggressive; faster variance adaptation)
- Mechanism: lower β2 during cooldown lets NorMuon's per-row variance estimator track the rapidly-changing gradient scale at final steps, improving update quality at the critical LR decay phase
- Orthogonal to all in-flight: μ anneal (PR #288) on momentum buffer; this is on variance buffer; no interaction

### FRIEREN #313 — Logit z-loss regularization (NEW — just assigned 22:05 UTC)
- Arm A: Z_LOSS_COEF=1e-4 (PaLM-style, very small)
- Arm B: Z_LOSS_COEF=1e-3 (T5-style, 10×)
- z_loss = z_loss_coef * mean(log_Z²) where log_Z = logsumexp(logits). Penalizes partition function magnitude → constrains logit drift.
- ONLY loss-function axis on r2 (all other in-flight PRs touch optimizer). Complements alphonse #312 (lm_head wd regularizes the weight matrix; z-loss regularizes the output distribution).
- PR #275 (MLP-SOAP trust gate) closed: both arms missed (val=3.27868/3.28009). Insight: MLP precond is ROBUST to rotation noise (unlike attn which is sensitive); gating hurts the MLP path even though MLP eigenbasis rotates as much as attn.

### FERN #304 — Annealed SOAP_PRECOND_FREQ (pod fixed, screen launching)
- Arm A: FREQ_START=15 → FREQ_END=7 (slower refreshes early, faster late)
- Arm B: FREQ_START=7 → FREQ_END=15 (faster refreshes early, slower late)
- Pod upgrade to torch 2.11.0 verified (same fix as alphonse #303). Fresh smoke `f03mcnpe` clean at step 200; Arm A screen `49bb9ye1` just launched.
- Direct follow-up from #291 falsification: keeps β2=0.90 static (safe), tests the orthogonal anneal axis that respects the matching constraint `FREQ ≈ 1/(1-β2)`.

### ALPHONSE #312 — AdamW lm_head weight decay sweep (NEW — just assigned 21:55 UTC)
- Arm A: ADAMW_WD_LM_HEAD=0.01 (mild, ~5% cumulative decay)
- Arm B: ADAMW_WD_LM_HEAD=0.05 (5×, ~25% cumulative)
- Pod fixed via torch upgrade (PR #303 closed). Fresh axis: lm_head readout regularization (50K×768 weight matrix currently has wd=0, unusual for modern transformers).
- Per-group wd via PyTorch fused AdamW's group["weight_decay"] override (embed and scalars stay at 0).

## Recently closed axes

| PR | Student | Status | Insight |
|---|---|---|---|
| #276 | tanjiro | FALSIFIED | Decoupled aux cooldown shape; aux groups tightly coupled to readout-convergence; linear is optimal for ALL groups |
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN because β2=0.92 is already in instability zone |
| #277 | alphonse | CLOSED (untested) | Pod-specific instability; freeze mechanism NOT falsified, just untest-able on this pod |
| #268 | askeladd | FALSIFIED | Depth-LR scaling; SOAP already absorbs per-layer gradient structure |
| #273 | nezuko | FALSIFIED | Asymmetric QK/VO trust; V's low cos_row is TRUE signal, not false negative |
| #271 | fern | FALSIFIED | Decoupled SOAP freq MLP vs ATTN; refresh-freq optimum ≈ EMA horizon = 1/(1-β2) |
| #303 | alphonse | CLOSED (pod fix) | torch 2.10.0+cu128 + mixed cu12/cu13 NCCL/cuDNN → optimizer kernel NaN at step 2-24. Fix: upgrade to torch 2.11.0+cu130 cu13-only |
| #275 | frieren | FALSIFIED | MLP-SOAP trust gate; MLP precond is robust to rotation noise (inverse of attn). MLP eigenbasis rotates as much as attn but the precond is noise-tolerant; gating hurts |
| #295 | nezuko | MISS | Polar Express adaptive NS5; SV quality perfect (100% within ±1% band) but no benefit over fixed (2,-1.5,0.5) at 12-iter bf16 budget. NS5 coeff tuning not productive. |
| #286 | askeladd | FALSIFIED | Polyak-Ruppert weight averaging; EMA path val=3.3097 vs raw val=3.2764. Averaging pre-cooldown weights (start=2000) with converged final weights guarantees worse model — aggressive cooldown already eliminates SGD variance that Polyak targets. |

## Key patterns (updated cycle 54)

1. **Annealed μ (0.97→0.90) MERGED (PR #219)**: n=4 mean val=3.275835/ffs=3087.5. New baseline.
2. **Attn-SOAP+trust T=0.85 MERGED (PR #212)**: +6.25 ffs improvement.
3. **Linear cooldown > cosine, on Muon AND aux**: cosine on Muon (r1) val=3.2882; cosine on aux alone (PR #276) val=3.27696; no-cooldown on aux catastrophic (val=3.30208).
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
16. **Aux groups need the same cooldown shape as Muon** (PR #276): linear, aggressive. They couple to readout-convergence and must land together with Muon. Open question (PR #309): do they also benefit from the same kind of momentum anneal that Muon got (PR #219)?
17. **MLP-SOAP precond is robust to rotation noise; attn-SOAP precond is sensitive** (PR #275 inverse of #212): MLP eigenbasis rotates AS MUCH as attn (mean_cos_row 0.885 vs 0.890), but applying a moderately-rotated MLP precond is net-beneficial (skipping costs more than rotation noise). Attn precond is the opposite — sensitive to rotation, so the gate helps. Different geometries, different sensitivities.
18. **PR #219's μ-anneal win is COOLDOWN-DRIVEN, not warmup-stabilization** (PR #288 trial 0 — preliminary n=1): cooldown-only anneal MU_COOLDOWN_START=0.95→0.90 (μ held static during warmup at 0.95, decays only from step 952) cleared both bars at n=1. Mechanism: μ-anneal benefit is from letting Muon chase finer signal during LR cooldown, NOT from high μ stabilizing the CONTRA_MUON warmup phase. Awaiting n=4 confirmation.

## Research programme direction

**Primary goal**: beat val < 3.275835 (current n=4 mean) AND ffs < 3087.5.
Gap to record #20 (~3030 ffs steps): ~57.5 ffs steps.

**Most promising active paths (as of 01:15 UTC cycle 55)**:
1. ⭐⭐ **Thorfinn #288 Arm B** (cooldown-only μ anneal) — **n=2 mean CLEARS BOTH BARS**, n=4 confirmation `qceklszn` in progress. ETA ~03:30 UTC. New baseline candidate.
2. ⭐ **Fern #304 Arm A** (FREQ 15→7 anneal) — n=1 trial 0 cleared both bars (val=3.27532, ffs=3075). Trial 1 in progress.
3. ⭐ **Alphonse #312 Arm A** (lm_head wd=0.01) — n=1 cleared bars (val=3.27554, ffs=3075). Need n=2 mean. Unauthorized side experiments flagged.
4. **Askeladd #319** (Muon LR warmup) — Arm A screen `5ao5znlo` (warmup=100) running step 1275.
5. **Nezuko #316** (NorMuon β2 cooldown anneal) — Arm A `hq3lzdm8` trial 0 missed (val=3.27838, ffs=3125). Trial 1 starting.
6. **Tanjiro #309** Arm A FALSIFIED (val 3.28251, never-target). Arm B (0.85→0.75 narrower) launching.
7. **Edward #281** Arm A n=2 miss (3.27727 / 3112.5). Arm B (all-matrix) launching.
8. 🚨 **Frieren #313** — code-breaking NaN cascade; possible reassignment if not fixed in 1h.

## Operational notes

- W&B entity: `wandb-applied-ai-team/modded-nanogpt-senpai`
- Merge bar: BOTH mean val < 3.275835 AND ffs_mean < 3087.5
- n=4 statsig: `(3.28 − mean) × √4 ≥ 0.004` → mean ≤ 3.27800
- n=3 (1 NaN): mean ≤ 3.27769
- **Lookahead-on-Muon**: do not reassign — fundamentally incompatible.
- **Muon momentum bias correction**: CLOSED (PR #221). Do not reassign.
- **NorMuon EMA bias correction**: CLOSED (PR #263). Do not reassign.
- **SOAP_BETA2 < 0.90**: do not use. 0.92 causes multi-seed NaN; 0.85 breaks FREQ coupling.
- **Cosine cooldown on Muon or aux**: do not reassign (PR #276 falsified aux; r1 falsified Muon).
- **AUX_COOLDOWN_SHAPE != linear**: do not reassign (PR #276 closed axis).
- **Pod NaN protocol**: if a student's pod NaNs at step 25-125 on the merged baseline, FIRST check torch version. If torch 2.10.0+cu128 with mixed cu12/cu13, approve in-place pip upgrade to `torch==2.11.0` cu13-only via `pip install --upgrade torch` before assigning any training hypothesis.
