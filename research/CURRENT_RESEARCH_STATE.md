# SENPAI Research State

- 2026-05-18 06:00 UTC — Cycle 55 (continued)
- No human researcher directives this session.
- ✅ **FRIEREN #340 CLOSED**: Embed init std=0.5 FALSIFIED — NaN at step 25 (Arm B skipped per kill gate). Mechanism: embed init scale is load-bearing under adam_embed lr=0.30; joint sweep would be required. Reassigned → PR #343 AdamW β2 sweep.
- 🎯🎯 **THORFINN #288 Arm B n=2 MEAN CLEARS BOTH BARS**: val=3.27477 (Δ−0.001065), ffs=3062.5 (Δ−25.0). N=4 confirmation `qceklszn` at ~65% (~step 8302/12700 at 04:50 UTC), ETA ~07:25 UTC. **Mechanism: cooldown-only μ anneal (MU_COOLDOWN_START=0.95→END=0.90 from step 952) — cooldown reactivity is the driver, NOT warmup stabilization.**
- 🎯 **FERN #304 Arm A n=4 confirmation `xzwpijuo` running** (n=2 near-miss val=3.275851/ffs=3087.5 — off by 0.000016 on val, tied on ffs). At ~20% (step 2500/12700 at 04:50 UTC), ETA ~10:30 UTC.
- ✅ **ALPHONSE #312 Arm A n=4 confirmation `cpojpo1o` running** (n=2 mean weak: val=3.27713/ffs=3112.5 — misses both bars). Trial 2 of 4 at step 7777/12700 at 04:30 UTC. Predeclared: weak n=4 mean → close axis.
- ✅ **EDWARD #281 CLOSED**: Per-head SOAP FALSIFIED — both arms miss. Arm A (Q-only) val=3.27727/ffs=3112.5 (Δ+0.00144/+25); Arm B (all four) val=3.276245/ffs=3100 (Δ+0.00041/+12.5). Mechanism: per-head block-diagonal preconditioning loses cross-head gradient covariance signal captured by the full-matrix Gram (verified via trust-gate health — gate fully open, not a gating issue). Reassigned → PR #341 SOAP eigenbasis freeze (resurrects #277 axis closed due to pod NaN, NOT falsified; pod healthy now).
- ✅ **ASKELADD #319 Arm A FALSIFIED**: Muon LR warmup 100-step n=2 mean val=3.277545/ffs=3112.5 (Δ+0.00171/+25). Mechanism: Muon's NS5 orthogonalization at full LR from step 1 is load-bearing; warmup delays early progress (val@step125=4.64 vs ~4.17 baseline-pace). Arm B (50-step) launching.
- ✅ **FRIEREN #333 CLOSED**: AdamW eps sweep FALSIFIED — both eps=1e-8 AND eps=1e-12 NaN before step 125. Symmetric failure = finely balanced operating point. AdamW eps=1e-10 is a fourth unique stability window (alongside FREQ=10, NS_ITERS=12, SOAP_β2≥0.90). Reassigned → #340 embed init std sweep.

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

### FERN #304 — Annealed SOAP_PRECOND_FREQ ⭐ (Arm A n=4 confirm running)
- Arm A: FREQ_START=15 → FREQ_END=7. n=2 mean **val=3.275851, ffs=3087.5** — misses bar by 0.000016 on val; ffs exactly tied.
  - T0 val=3.275316/ffs=3075 (clear), T1 val=3.276385/ffs=3100 (miss).
  - n=4 confirmation requested: if n=4 mean < 3.275835 AND ffs < 3087.5 → merge; else close.
- Arm B: FREQ_START=7 → FREQ_END=15 — queued after n=4 completes.
- W&B run (Arm A): `42xkphld` (n=2 terminal)

### ALPHONSE #312 — AdamW lm_head weight decay sweep ⭐ (n=4 confirm running)
- Arm A: ADAMW_WD_LM_HEAD=0.01. n=1 cleared both bars (val=3.27554, ffs=3075).
- N=4 confirmation `cpojpo1o` running (step ~1700/3175 trial 0 at 01:25 UTC, ~8h ETA total).
- Arm B: ADAMW_WD_LM_HEAD=0.05 — run AFTER cpojpo1o completes.
- Code commit `88534381` (per-group AdamW wd, lm_head_norm telemetry).

### TANJIRO #336 — TARGET_UW sweep (cycle 55, just assigned)
- Current TARGET_UW=0.35 replaces explicit Muon weight decay — never swept since PR #78.
- Arm A: TARGET_UW=0.25 (lower floor → less implicit WD → allows smaller relative updates especially in cooldown).
- Arm B: TARGET_UW=0.50 (higher floor → more aggressive implicit WD → tighter weight norm control).
- Mechanism: SOAP-preconditioned updates have well-conditioned directions. With μ-anneal, u_fro shrinks during cooldown (smaller momentum) → floor fires more → effective implicit WD increases. Lower TARGET_UW may release over-regularization in the cooldown phase.
- 1-line implementation: `TARGET_UW = float(os.environ.get("TARGET_UW", "0.35"))`

### EDWARD #341 — SOAP eigenbasis freeze after step K (cycle 55, just assigned)
- Resurrects PR #277 axis (closed INCONCLUSIVE due to pod NaN — pod now upgraded to torch 2.11.0).
- Hypothesis: Q (eigenbasis) refreshes late in training are rotation noise that survives the trust gate; Gram EMA + per-direction second-moment scaling can continue without Q rotation.
- Arm A: SOAP_FREEZE_STEP=1000 (freeze pre-cooldown — stable-phase eigenbasis locked through all cooldown).
- Arm B: SOAP_FREEZE_STEP=2000 (freeze mid-cooldown — eigenbasis adapts through early cooldown then locks).
- ~5-line implementation: env var + guard in `soap_refresh` line 557 + W&B telemetry.
- Orthogonal to fern #304 (which sweeps refresh-frequency anneal; same underlying SOAP eigenbasis system but different mechanism).

### NEZUKO #339 — cooldown_frac sweep (cycle 55, just assigned)
- Current cooldown_frac=0.7 — static since PR #71, never swept.
- Arm A: COOLDOWN_FRAC=0.6 (40% stable / 60% cooldown — 318 more steps at full LR).
- Arm B: COOLDOWN_FRAC=0.8 (20% stable / 80% cooldown — 317 fewer steps at full LR).
- 3-line implementation: env var + set_hparams default + W&B config.

### ASKELADD #319 — Muon LR linear warmup (cycle 55)
- Arm A: MUON_WARMUP_STEPS=100 — **FALSIFIED** (n=2 mean val=3.277545/ffs=3112.5; Δ+0.00171/+25).
- Arm B: MUON_WARMUP_STEPS=50 — launching (Arm A-like miss expected; final close if Arm B also misses).

### FRIEREN #343 — AdamW β2 sweep (cycle 55, just assigned)
- Current AdamW betas=(0.8, 0.95) — β2=0.95 is unusually fast vs Adam-default 0.999. Never swept.
- Arm A: ADAMW_BETA2=0.99 (Adam default — slower variance EMA, ~100-step window).
- Arm B: ADAMW_BETA2=0.90 (faster — ~10-step window; higher NaN risk).
- 2-line implementation: env var + `betas=(0.8, ADAMW_BETA2)` in AdamW init.
- Last untested AdamW axis (β1-anneal #309 FALSIFIED, eps #333 FALSIFIED, lm_head wd #312 in flight).

## Recently closed axes

| PR | Student | Status | Insight |
|---|---|---|---|
| #316 | nezuko | FALSIFIED | NorMuon β2 cooldown anneal; n=2 mean val=3.278405/ffs=3125 (Δ+0.00257/+37.5). β2 variance buffer ≠ μ: faster variance adaptation at cooldown tail degrades re-normalization quality; NS5 safety net absent. |
| #333 | frieren | FALSIFIED | AdamW eps sweep — both eps=1e-8 AND eps=1e-12 NaN before step 125. Symmetric failure = finely balanced operating point. eps=1e-10 is a fourth unique stability window. |
| #313 | frieren | CLOSED (bug) | Z-loss — 4 NaN smokes, code never pushed; hypothesis not falsified. Reassigned to #333→#340. |
| #309 | tanjiro | FALSIFIED | AdamW β1 anneal; Arm A (0.90→0.70) val=3.28251/ffs=-1, Arm B (0.85→0.75) val=3.27884/ffs=3150. β1 anneal does NOT mirror Muon μ anneal — AdamW has no NS5 orthogonalization safety net. |
| #295 | nezuko | MISS | Polar Express adaptive NS5; SV quality perfect but no benefit at 12-iter bf16 budget. |
| #286 | askeladd | FALSIFIED | Polyak-Ruppert EMA; averaging pre-cooldown weights strictly hurts (val=3.3097). Incompatible with aggressive cooldown. |
| #276 | tanjiro | FALSIFIED | Decoupled aux cooldown shape; linear is optimal for ALL groups. |
| #291 | fern | FALSIFIED | β2-anneal breaks FREQ/β2 coupling; Arm B NaN at β2=0.92. |
| #277 | alphonse | CLOSED (untested) | Pod-specific instability; freeze mechanism NOT falsified. Resurrected as PR #341 for edward. |
| #281 | edward | FALSIFIED | Per-head SOAP both arms miss (Arm A val=3.27727/ffs=3112.5, Arm B val=3.276245/ffs=3100). Cross-head gradient covariance lost in block-diagonal preconditioning. Trust gate fully open at terminal = mechanism issue, not gating. |
| #319(A) | askeladd | FALSIFIED | Muon LR warmup 100-step; n=2 mean val=3.277545/ffs=3112.5. Muon's NS5 at full LR is load-bearing; warmup delays early progress without better basin. Arm B (50-step) still pending. |
| #340 | frieren | FALSIFIED | Embed init std=0.5 NaN at step 25 (Arm B skipped per kill gate). Embed init scale load-bearing under adam_embed lr=0.30; joint init×LR sweep would be required. |
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
18. **AdamW β1 anneal does NOT mirror Muon μ anneal** (PR #309 FALSIFIED): both arms miss — Arm A (0.90→0.70) val=3.28251; Arm B (0.85→0.75) val=3.27884/ffs=3150. Muon's NS5 orthogonalization acts as a safety net that bounds the response to μ changes; AdamW has no analogous layer — β1 changes directly affect raw gradient EMA on high-LR (embed lr=0.3) and delicate (lm_head lr=1/320) groups. Cooldown-reactivity from momentum anneal is Muon-specific. Do NOT reassign any form of AdamW β1 or β2 anneal.

## Research programme direction

**Primary goal**: beat val < 3.275835 AND ffs < 3087.5 (current n=4 mean).
Gap to public record #20 (~3030 ffs steps): ~57.5 ffs steps.

**Most promising active paths (as of 05:15 UTC cycle 55)**:
1. ⭐⭐ **Thorfinn #288 Arm B** (cooldown-only μ anneal) — **n=2 mean CLEARS BOTH BARS**, n=4 confirmation `qceklszn` at ~65%, ETA ~07:25 UTC. **Highest-priority candidate.**
2. ⭐ **Fern #304 Arm A** (FREQ 15→7 anneal) — n=2 near-miss (val Δ +0.000016, ffs tied); n=4 confirm `xzwpijuo` at ~20%, ETA ~10:30 UTC.
3. ⭐ **Alphonse #312 Arm A** (lm_head wd=0.01) — n=2 weak (val=3.27713/ffs=3112.5 misses bars); n=4 confirm `cpojpo1o` at ~61%, ETA ~07:45 UTC. Predeclared: weak mean → close.
4. **Tanjiro #336** (TARGET_UW sweep 0.25/0.50) — just assigned (~2.5h silent, GPU idle — heartbeat sent).
5. **Nezuko #339** (cooldown_frac sweep 0.6/0.8) — actively running smoke.
6. **Frieren #343** (AdamW β2 sweep 0.90/0.99) — just assigned, implementing.
7. **Edward #341** (SOAP eigenbasis freeze 1000/2000) — just assigned.
8. **Askeladd #319** Arm B (MUON_WARMUP_STEPS=50) — pending launch after Arm A close.

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
