# SENPAI Research State

- 2026-05-18 01:35 UTC — Cycle 55 (continued)
- No human researcher directives this session.
- 🎯🎯 **THORFINN #288 Arm B n=2 MEAN CLEARS BOTH BARS**: val=3.27477 (Δ−0.001065), ffs=3062.5 (Δ−25.0). N=4 confirmation `qceklszn` launched 00:03 UTC, ETA ~03:30 UTC. **Mechanism: cooldown-only μ anneal (MU_COOLDOWN_START=0.95→END=0.90 from step 952) — cooldown reactivity is the driver, NOT warmup stabilization.**
- 🎯 **FERN #304 Arm A trial 0 cleared both bars at n=1**: val=3.27532, ffs=3075 (FREQ_START=15→END=7). Trial 1 in progress.
- ✅ **ALPHONSE #312 Arm A n=1 cleared both bars**: val=3.27554, ffs=3075 (ADAMW_WD_LM_HEAD=0.01). N=4 confirmation `cpojpo1o` running (ETA ~8h). Note: the "unauthorized" eps/lr-sweep runs flagged earlier belong to SIBLING students on r4/r5 pods (g1r4-alphonse, g1r5-alphonse) — NOT g1r2-alphonse. False alarm corrected.
- 🔻 **TANJIRO #309 Arm A FALSIFIED**: val=3.28251, reached_target=NO. Aggressive AdamW β1 anneal 0.90→0.70 hurts aux momentum stability. Arm B (0.85→0.75) `45raqb1u` now running.
- 🔻 **EDWARD #281 Arm A n=2 MISS**: mean val=3.27727 (Δ+0.00144), ffs=3112.5 (Δ+25). Per-head SOAP Q-only loses cross-head info. Arm B (all-matrix per-head) requested but NOT yet launched.
- ✅ **FRIEREN #313 CLOSED**: 4 consecutive NaN smokes on z-loss — code never pushed to branch, could not diagnose. Hypothesis not falsified; closed for unresolvable implementation bug.
- 🆕 **FRIEREN #330 ASSIGNED**: AdamW eps sweep (eps=1e-8 vs eps=1e-12 vs current 1e-10). Clean, env-var-only axis. Awaiting smoke.

## POD INFRASTRUCTURE NOTE (cycle 54)

**Two r2 pods broken on torch 2.10.0+cu128 + mixed cu12/cu13 nvidia libs**:
- alphonse #303 — FIXED by in-place pip upgrade to torch 2.11.0+cu130. PR closed.
- fern #304 — same fix confirmed; running fine now.

Root cause: mixed cu12/cu13 NCCL/cuDNN with torch 2.10.0+cu128 causes optimizer kernel divergence at steps 2-24, producing full-attention-Gram NaN by first val checkpoint at step 125. Step-1 gradients are bit-identical to healthy peers.

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
- **Mechanism insight**: μ-anneal benefit localizes to cooldown phase. Warmup stabilization NOT the driver. Lower μ during LR cooldown lets Muon chase finer signal at low LR.

### FERN #304 — Annealed SOAP_PRECOND_FREQ ⭐ (Arm A trial 1 running)
- Arm A: FREQ_START=15 → FREQ_END=7. Trial 0 val=3.27532/ffs=3075 (n=1 clear). Trial 1 in progress.
- Arm B: FREQ_START=7 → FREQ_END=15 (reversed schedule, queued after Arm A completes).
- W&B run (Arm A): `42xkphld`

### ALPHONSE #312 — AdamW lm_head weight decay sweep ⭐ (n=4 confirm running)
- Arm A: ADAMW_WD_LM_HEAD=0.01. n=1 cleared both bars (val=3.27554, ffs=3075).
- N=4 confirmation `cpojpo1o` running (step ~1700/3175 trial 0 at 01:25 UTC, ~8h ETA total).
- Arm B: ADAMW_WD_LM_HEAD=0.05 — run AFTER cpojpo1o completes.
- Code commit `88534381` (per-group AdamW wd, lm_head_norm telemetry).

### TANJIRO #309 — Annealed AdamW β1
- Arm A: ADAMW_BETA1_START=0.90 → END=0.70. FALSIFIED: val=3.28251, never reached 3.28.
- Arm B: ADAMW_BETA1_START=0.85 → END=0.75. Run `45raqb1u` now running (~step 1600 at 01:35 UTC).

### EDWARD #281 — Per-head SOAP for attention weights
- Arm A: PER_HEAD_SOAP_Q=1 (Q.weight per-head, 6×128×128 Grams). n=2 mean val=3.27727/ffs=3112.5 — **MISS**.
- Arm B: PER_HEAD_SOAP_ALL=1 (Q/K/V/proj all per-head). **NOT YET LAUNCHED** — student pinged at 01:32 UTC.

### NEZUKO #316 — NorMuon β2 cooldown anneal (cycle 55)
- Arm A: NORMUON_COOLDOWN_BETA2_START=0.95 → END=0.90 (mirrors μ-anneal scale). Smoke `lpe2xbwe` clean; Arm A screen `hq3lzdm8` trial 0 MISSED (val=3.27838, ffs=3125). Trial 1 in progress.
- Arm B: NORMUON_COOLDOWN_BETA2_START=0.95 → END=0.85 (more aggressive).

### ASKELADD #319 — Muon LR linear warmup (cycle 55)
- Arm A: MUON_WARMUP_STEPS=100 (100 steps linear warmup for Muon group only). Run `5ao5znlo` ~step 1525.
- Arm B: MUON_WARMUP_STEPS=50 (shorter, faster warmup).

### FRIEREN #330 — AdamW eps sweep (cycle 55, just assigned)
- Current eps=1e-10 (AdamW aux groups: embed, lm_head/proj, scalars) — has never been swept.
- Arm A: ADAMW_EPS=1e-8 (PyTorch default — 100× larger denominator).
- Arm B: ADAMW_EPS=1e-12 (10× more extreme than current).
- Awaiting smoke and implementation push.

## Recently closed axes

| PR | Student | Status | Insight |
|---|---|---|---|
| #313 | frieren | CLOSED (implementation bug) | Z-loss — 4 NaN smokes, code never pushed; hypothesis not falsified, just unresolvable. Reassigned to #330. |
| #295 | nezuko | MISS | Polar Express adaptive NS5; SV quality perfect but no benefit at 12-iter bf16 budget. |
| #286 | askeladd | FALSIFIED | Polyak-Ruppert EMA; averaging pre-cooldown weights strictly hurts (val=3.3097). Incompatible with aggressive cooldown. |
| #276 | tanjiro | FALSIFIED | Decoupled aux cooldown shape; linear is optimal for ALL groups. |
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN at β2=0.92. |
| #277 | alphonse | CLOSED (untested) | Pod-specific instability; freeze mechanism NOT falsified. |
| #268 | askeladd | FALSIFIED | Depth-LR scaling; SOAP already absorbs per-layer gradient structure. |
| #273 | nezuko | FALSIFIED | Asymmetric QK/VO trust; V's low cos_row is TRUE signal. |
| #271 | fern | FALSIFIED | Decoupled SOAP freq MLP vs ATTN; refresh-freq optimum ≈ EMA horizon = 1/(1-β2). |
| #303 | alphonse | CLOSED (pod fix) | torch 2.10.0+cu128 + mixed cu12/cu13 NCCL/cuDNN → NaN at step 2-24. Fix: upgrade to torch 2.11.0. |
| #275 | frieren | FALSIFIED | MLP-SOAP trust gate; MLP precond is robust to rotation noise (inverse of attn). |

## Key patterns (updated cycle 55)

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
11. **SOAP_PRECOND_FREQ ≈ EMA horizon = 1/(1-β2)** (PR #271): refresh optimum coupled to β2. At β2=0.90, FREQ=10 ≈ 1/(1-0.90) = 10.
12. **V's low cos_row is TRUE signal** (PR #273): 12% on_fraction for V at T=0.85 reflects genuinely fast eigenbasis rotation; forcing SOAP on unstable V eigenbasis → +0.005 val degradation.
13. **μ-anneal works; β2-anneal doesn't** (PR #291): μ controls scalar momentum buffer (robust to rate changes); β2 controls Gram EMA matrix (eigenvectors highly sensitive to perturbations, especially early in training). β2 also coupled to FREQ via matching constraint.
14. **Aux groups need the same cooldown shape as Muon** (PR #276): linear, aggressive. They couple to readout-convergence.
15. **MLP-SOAP precond is robust to rotation noise; attn-SOAP precond is sensitive** (PR #275): different geometries, different sensitivities.
16. **PR #219's μ-anneal win is COOLDOWN-DRIVEN, not warmup-stabilization** (PR #288 Arm B, n=2 confirmed): cooldown-only anneal MU_COOLDOWN_START=0.95→0.90 (μ held static during warmup at 0.95, decays only from step 952) cleared both bars with n=2 mean val=3.27477/ffs=3062.5. Mechanism: lower μ during LR cooldown lets Muon chase finer signal at low LR. Arm A (tight 0.97→0.92 over full training, n=2 mean 3.27670/3112.5) missed both bars.
17. **Polyak EMA strictly incompatible with aggressive LR cooldown** (PR #286): weight averaging during cooldown captures mid-decay weights; the aggressive linear cooldown already eliminates SGD variance that Polyak targets.
18. **AdamW β1 anneal on aux groups is fragile**: PR #309 Arm A (β1 0.90→0.70, broad) val=3.28251 — significantly worse. High effective LR on embed (0.3) + fragile lm_head (1/320) makes aux momentum more sensitive to β1 perturbations than Muon.

## Research programme direction

**Primary goal**: beat val < 3.275835 AND ffs < 3087.5 (current n=4 mean).
Gap to public record #20 (~3030 ffs steps): ~57.5 ffs steps.

**Most promising active paths (as of 01:35 UTC cycle 55)**:
1. ⭐⭐ **Thorfinn #288 Arm B** (cooldown-only μ anneal) — **n=2 mean CLEARS BOTH BARS**, n=4 confirmation `qceklszn` ETA ~03:30 UTC.
2. ⭐ **Fern #304 Arm A** (FREQ 15→7 anneal) — n=1 trial 0 cleared both bars (val=3.27532, ffs=3075). Awaiting trial 1.
3. ⭐ **Alphonse #312 Arm A** (lm_head wd=0.01) — n=1 cleared bars, n=4 confirm running (8h ETA).
4. **Askeladd #319** (Muon LR warmup 100/50 steps) — screen in progress.
5. **Nezuko #316** (NorMuon β2 cooldown anneal) — Arm A trial 0 miss, trial 1 in progress.
6. **Tanjiro #309** Arm B (β1 0.85→0.75) — narrower anneal in progress.
7. **Edward #281** Arm B (all-matrix per-head SOAP) — not yet launched; student pinged.
8. **Frieren #330** (AdamW eps sweep) — just assigned.

**Next research themes to explore after in-flight settles**:
- If thorfinn and fern both win: stack both (cooldown-only μ anneal + FREQ 15→7 anneal)
- AdamW eps is untested on this baseline (#330 in progress)
- Embed or lm_head init std (zero init for proj layers is unusual; non-zero may help early convergence)
- SOAP β2 warm-start (start lower, ramp up) — different from β2 anneal (which was falsified)
- Gradient clipping threshold sweep (currently relies on default or disabled)

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
- **Pod NaN protocol**: if a student's pod NaNs at step 25-125 on the merged baseline, FIRST check torch version. If torch 2.10.0+cu128 with mixed cu12/cu13, approve in-place pip upgrade to `torch==2.11.0` cu13-only before assigning any hypothesis.
