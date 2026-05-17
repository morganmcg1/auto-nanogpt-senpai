# SENPAI Research State

- 2026-05-17 21:55 UTC — Cycle 54 (continued)
- No human researcher directives this session.

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

### THORFINN #288 — Annealed μ finer sweep
- Arm A: MU_START=0.97 MU_END=0.92 (tighter range). 2-trial mean val=3.27670, ffs=3112.5 — **MISS** both bars.
- Arm B: cooldown-phase-only anneal MU_COOLDOWN_START=0.95→0.90 from step 952. Launching ~20:21 UTC, ETA ~23:50 UTC. **Most interesting test**: isolates whether cooldown reactivity drives PR #219's win.

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

### NEZUKO #295 — Polar Express adaptive NS5 coefficients
- Pivoted to Polar Express adaptive scheme per student's math review of original arms (sum≠1 bug).
- New arms: per-iteration adaptive (a,b,c) = [(8,-16,8), (4,-8,4), (3,-4,1.5), then (2,-1.5,0.5) for iters 4-12].
- No terminal result yet. Implementation in progress.

### FRIEREN #275 — MLP-SOAP trust gate
- Rebased onto PR #219 baseline. Killed pre-rebase invalid run. Smoke + n=4 confirmation pipeline starting.
- No terminal result yet.

### FERN #304 — Annealed SOAP_PRECOND_FREQ (BLOCKED on pod fix)
- Arm A: FREQ_START=15 → FREQ_END=7 (slower refreshes early, faster late)
- Arm B: FREQ_START=7 → FREQ_END=15 (faster refreshes early, slower late)
- **Pod broken**: bit-identical baseline NaN'd at step 25 — same torch 2.10.0+cu128 + mixed cu lib issue as alphonse. Upgrade approved 21:28 UTC, awaiting fern response.
- Direct follow-up from #291 falsification: keeps β2=0.90 static (safe), tests the orthogonal anneal axis that respects the matching constraint `FREQ ≈ 1/(1-β2)`.
- Resume hypothesis after pod fix verified.

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

## Research programme direction

**Primary goal**: beat val < 3.275835 (current n=4 mean) AND ffs < 3087.5.
Gap to record #20 (~3030 ffs steps): ~57.5 ffs steps.

**Most promising active paths**:
1. **Thorfinn #288 Arm B** (cooldown-only μ anneal) — isolates whether cooldown reactivity drives PR #219's win. High prior.
2. **Tanjiro #309** (AdamW β1 anneal) — direct parallel to merged PR #219 on the orthogonal aux-optimizer axis. High prior.
3. **Frieren #275** (MLP-SOAP trust gate) — symmetric extension of merged PR #212 win.
4. **Nezuko #295** (Polar Express adaptive NS5) — fresh axis; per-iteration adaptive coefficients.
5. **Edward #281** (per-head SOAP) — head-specific eigenbasis for attention weights.
6. **Fern #304** (annealed SOAP_PRECOND_FREQ) — orthogonal axis from #291, respects matching constraint.
7. **Askeladd #286** (Polyak-Ruppert EMA) — orthogonal post-processing; pure eval gain (pending relaunch).

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
