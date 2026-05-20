# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-20 13:20 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Axes CLOSED this cycle (11:48–03:42 UTC)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#447** | fern | NS adaptive threshold | CLOSED 12:25 UTC |
| **#433** | edward | Aux AdamW β2-by-group | CLOSED 12:30 UTC |
| **#416** | askeladd | Aux AdamW β1=0.85 | CLOSED earlier |
| **#439** | thorfinn | Logit soft-cap c∈{10,30} symmetric +112.5 sr regression | CLOSED 14:10 UTC |
| **#440** | tanjiro | Embed init scale std∈{0.5,2.0} symmetric NULL | CLOSED 14:33 UTC |
| **#444** | frieren | PMuon γ_power phase ramp both directions: Δsr=+37.5 both arms | CLOSED 15:35 UTC |
| **#448** | nezuko | Decoupled cooldown_frac aux∈{0.5, 0.85} clear asymmetric NULL | CLOSED 16:13 UTC |
| **#460** | alphonse | scalar_lr fine-scan {0.020,0.030} symmetric +37.5 sr both. 0.025 confirmed. | CLOSED 19:38 UTC |
| **#463** | askeladd | Embed eps scan {1e-8, 1e-7} clean monotone NULL. eps=1e-10 confirmed. | CLOSED 20:01 UTC |
| **#466** | edward | Aux WD scan {0.001, 0.01} clean monotone NULL. aux WD=0 confirmed. | CLOSED 20:25 UTC |
| **#465** | fern | Body-Muon lr fine-scan {0.030, 0.040} symmetric NULL. lr=0.035 confirmed. | CLOSED 20:51 UTC |
| **#480** | tanjiro | Attn-scale scan {0.09, 0.15} asymmetric NULL. attn_scale=0.12 confirmed. | CLOSED 21:59 UTC |
| **#476** | thorfinn | Z-loss scan {1e-4, 1e-3} clean monotone NULL. z-loss=0 confirmed; net-harmful. | CLOSED 22:08 UTC |
| **#482** | frieren | Body-Muon WD partition (MLP=0.05, ATTN=0): n=2 mean sr=2950, Δval=−0.0002. Per-substructure WD partition NULL. | CLOSED 23:25 UTC |
| **#486** | nezuko | Skylight u/w-floor scan TARGET_UW∈{0.25, 0.45}: symmetric +87.5 sr both arms. 0.35 confirmed local optimum. fired_fraction=0.16/0.87/0.93 reveals floor amplifying cooldown-phase updates. | CLOSED 00:15 UTC |
| **#502** | askeladd | PMuon β_cov scan {0.90, 0.99}: Arm A fs=2950 val=3.264775 (marginal NULL Δsr=+12.5 Δval=+0.0005), Arm B fs=3000 val=3.269313 (clear NULL Δsr=+62.5 Δval=+0.005). β_cov=0.95 locally optimal; asymmetric loss curve rules out scheduled ramp. PMuon scalar block saturated. | CLOSED 03:25 UTC |
| **#499** | alphonse | Body-Muon LR per-type partition (MLP=0.042/ATTN=0.028 vs swap): both arms clear NULL ~Δval=+0.006 symmetric. Δsr +62.5–+87.5. Centered geomean preserved (sqrt(MLP×ATTN)=0.0343≈0.035) — *the split itself* hurts, not the effective LR. PMuon's per-matrix whitening already equalizes per-module gradient geometry. | CLOSED 03:40 UTC |
| **#503** | edward | Body-Muon WD schedule (warmup-25pct vs cooldown-25pct): Arm A fs=2950 val=3.26475 (marginal-NULL Δsr=+12.5 Δval=+0.000472), Arm B fs=2975 val=3.26681 (clear-NULL Δsr=+37.5 Δval=+0.002532). Asymmetric loss confirms WD's implicit norm-control is load-bearing during cooldown. **Schedule axis closes at uniform constant WD=0.025.** Body-Muon WD now exhaustively tested across partition (#482 NULL) and schedule (#503 NULL). | CLOSED 04:28 UTC |
| **#505** | fern | Lookahead wrapper k∈{5, 10}, α=0.5: Arm A fs=-1 val=3.28420 DNF (Δval=+0.020 clear regression), Arm B fs=-1 val=3.28618 DNF (Δval=+0.022 clear regression). Both arms DNF with monotone regression — milder k=10 is NOT better than aggressive k=5. **Wrapper-class axis closes on body-Muon.** Layered averaging on top of already-tuned PMuon stack becomes net-harmful interference. | **CLOSED 05:32 UTC** |
| **#513** | thorfinn | Body-Muon gradient clipping at {1.0, 0.5}: Arm A clip=1.0 fs=3000 val=3.27024 (clear NULL Δsr=+62.5 Δval=+0.006), Arm B clip=0.5 fs=3000 val=3.27108 (clear NULL Δsr=+62.5 Δval=+0.007). Both arms clip-activated 99.97% — natural body-grad norm ~3e4 vs proposed thresholds {0.5, 1.0} (4-5 orders too low). Uniform 30,000× downscale costs only ~2% sr regression — **PMuon's spectral whitening confirmed approximately scale-invariant.** Student suggested re-test at natural-norm regime {3e4, 1e5, 3e5}; DEFERRED — pipeline NS iter-count extension instead. | **CLOSED 06:08 UTC** |
| **#519** | frieren | PMuon γ pruning γ∈{0, 0.8} vs baseline 0.4: Arm A γ=0 val=3.282615 DNF (Δval=+0.0183 clear regression), Arm B γ=0.8 val=3.313878 DNF (Δval=+0.0496 clear regression, 2.7× Arm A damage). **γ=0.4 load-bearing AND near-optimal.** Asymmetric damage curve (over-correction worse than ablation) consistent with WD #482/#503 and LR #499 patterns — local optimum pinned by cooldown-phase preconditioner-quality demand. γ axis fully closed: {0, 0.4, 0.8} mapped, plus #444 ramp NULL. | **CLOSED 07:30 UTC** |
| **#522** | nezuko | Skylight u/w-floor cooldown phase-out: Arm A linear decay 0.35→0 fs=2975 val=3.27188 (clear NULL Δsr=+37.5 Δval=+0.0076), Arm B hard switch at cooldown_start fs=3025 val=3.27214 (clear NULL Δsr=+87.5 Δval=+0.0079, 2× Arm A regression). **Asymmetric regression** (hard worse than linear) confirms u/w-amplification continues to contribute useful work as COOLDOWN_POWER=1.4 narrows polar-map updates — floor and cooldown are complementary, not redundant. Combined with #486 (static {0.25, 0.45} NULL +87.5 both), TARGET_UW=0.35 is the local optimum on BOTH magnitude AND schedule axes. Skylight floor exhaustively pinned. | **CLOSED 08:55 UTC** |
| **#511** | tanjiro | NS_ITERS scan {10, 14} vs baseline 12: Arm A NS=10 fs=3000 val=3.273 (clear NULL Δsr=+62.5 Δval=+0.009); Arm B NS=14 seed-1 `ldezjd0y` fs=2925 val=3.2639 marginal n=1 win → seed-2 `ciusvhzo` fs=2975 val=3.2678 → n=2 mean sr=2950 (Δsr=+12.5) val=3.265846 (Δval=+0.00157) NO confirm. NS_ITERS=12 confirmed locally optimal — extra iters do NOT pay off at n=2. Scalar axis closes; combined with thorfinn #546 (NS={16,18} pipeline) maps the iteration-count axis. | **CLOSED 09:25 UTC** |
| **#535** | alphonse | Sub-MLP LR partition c_fc vs c_proj: Arm A (c_fc=1.20, c_proj=0.80) fs=3025 val=3.27030 (clear NULL Δsr=+87.5 Δval=+0.006), Arm B (c_fc=0.80, c_proj=1.20) fs=2975 val=3.26732 (clear NULL Δsr=+37.5 Δval=+0.003). **Both NULL clear**. Sub-MLP partition axis closes — PMuon's per-matrix bilateral whitening already equalizes c_fc / c_proj effective gradient at the matrix-pair level. Residual c_proj-favouring signal (50 sr / 0.003 val_loss across cooldown) noted but sub-threshold. Combined with #499 (per-type MLP-vs-ATTN NULL/NULL +62.5/+87.5), the body-Muon **LR partition family is fully closed** on every coarse subdivision: per-type, sub-MLP, depth (pending #532). | **CLOSED 11:30 UTC** |
| **#532** | askeladd | Body-Muon depth-based LR partition (early-fast vs late-fast): Arm A (blocks 0-5 × 1.10, blocks 6-11 × 0.90) `oj9miqwf` fs=3025 val=3.27130 (clear NULL Δsr=+87.5 Δval=+0.007), Arm B (blocks 0-5 × 0.90, blocks 6-11 × 1.10) `i6tfv7ry` fs=3000 val=3.26825 (clear NULL Δsr=+62.5 Δval=+0.004). **Both NULL clear**. Asymmetric NULL favouring late_fast — deeper blocks marginally prefer more LR, but signal sub-threshold. Combined with #499 (per-type NULL/NULL +62.5/+87.5) and #535 (sub-MLP NULL/NULL +87.5/+37.5), this **completes the body-Muon LR partition family closure on all three coarse subdivisions**. PMuon's per-matrix bilateral whitening neutralizes LR multipliers at every coarse partitioning. **Body-Muon LR partition permanently de-prioritized.** | **CLOSED 12:10 UTC** |
| **#540** | edward | NS coefficient scan (quintic vs aggressive-cubic): Arm A quintic published (3.4445, -4.7750, 2.0315) `y46v2liq` fs=2975 val=3.267725 (clear NULL Δsr=+37.5 Δval=+0.003), Arm B aggressive cubic (1.75, -0.75, 0.0) `zuk9fkdm` fs=2975 val=3.267596 (clear NULL Δsr=+37.5 Δval=+0.003). **Both NULL clear AND identical sr.** Polynomial perturbations cost ~37 sr in both degree-up (quintic) and magnitude-up (aggressive cubic) directions. Combined with #511 (NS_ITERS={10,14} NULL/NULL) and #546 in flight (NS_ITERS={16,18}, Arm A=16 already fs=2975), **NS-quality axis is being pinned to inherited defaults across BOTH polynomial structure AND iteration count**. NS preconditioner quality saturated for this stack at NS_ITERS=12. **NS coefficient axis closes.** | **CLOSED 13:15 UTC** |

## Active experiments (8 students, 13:20 UTC)

| PR | Student | Run | Step/3250 | bl | Status |
|---|---|---|---|---|---|
| **#545** | fern | Arm A `p3ryt23e` AdaBelief raw-m eps=1e-10 TERMINAL fs=2950; Arm B `6ft2eleu` eps=1e-8 running | ~2350 | ~3.34 | ~30-50 min to Arm B terminal. |
| **#578** | **edward** | (awaiting pickup) | — | — | **NEW — AMSGrad v-clamp on aux AdamW. Third leaf of aux-AdamW update-rule mechanism tree (alongside #545 v-estimator and #575 m-step). Arm A bias-corrected v_max; Arm B uncorrected v_max. Adds v_max = max(v_max, v) monotone clamp to prevent late-training v-shrinkage on rare-token embed/lm_head rows. Mechanism-orthogonal to all body-Muon work; complementary leaf to AdaBelief (v-estimator) and NadamW (m-step).** |
| **#570** | alphonse | `lbgxv3v4` PMuon mu=0.90 Arm A running | ~early | — | Fresh launch ~13:00 UTC after auto-recovery. ~3h to Arm A terminal. |
| **#575** | askeladd | `hqipehpg` NadamW Arm A β1=0.8 running | ~early | — | Fresh launch ~12:54 UTC after auto-recovery. ~3h to Arm A terminal. |
| **#559** | nezuko | `8v444jbv` NS_ITERS cooldown ramp running | ~early | — | Fresh launch ~12:55 UTC after auto-recovery. ~3h to Arm A terminal. |
| **#553** | frieren | Arm A `1x2u1688` dim=1 TERMINAL fs=3000; Arm B `zfdfwtk4` dim=0 running | ~1300 | ~3.62 | ~2h to Arm B terminal. |
| **#546** | thorfinn | Arm A `bqm06i25` NS_ITERS=16 TERMINAL fs=2975; Arm B `xtaiy5c7` NS=18 running | ~2400 | ~3.33 | ~30-50 min to Arm B terminal. |
| **#562** | tanjiro | `6gym4o48` PMuon eps=1e-10 Arm A running | ~early | — | Fresh launch ~13:01 UTC after earlier crash recovery. ~3h to Arm A terminal. |

## Next terminal events (from 13:20 UTC)

1. **thorfinn #546 NS=18 Arm B `xtaiy5c7`** — step ~2400/3250, ~30-50 min to terminal.
2. **fern #545 AdaBelief Arm B `6ft2eleu` eps=1e-8** — step ~2350/3250, ~30-50 min to terminal.
3. **frieren #553 Arm B `zfdfwtk4` GC dim=0** — step ~1300/3250, ~2h to terminal.
4. **nezuko/tanjiro/alphonse/askeladd** — fresh runs ~13:00 UTC after auto-recovery, ~3h each.
5. **edward #578 AMSGrad** — newly assigned, will pick up at next polling cycle.

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 13:20 UTC)

**Body-Muon LR partition family FULLY CLOSED:** #499 per-type (MLP vs ATTN, +62.5/+87.5 NULL/NULL), #535 sub-MLP (c_fc vs c_proj, +87.5/+37.5 NULL/NULL), **#532 depth-based (early-fast vs late-fast, +87.5/+62.5 NULL/NULL — CLOSED 12:10 UTC)**. All three coarse partitionings on body-Muon LR converge to NULL because PMuon's per-matrix bilateral whitening already equalizes gradient geometry at the matrix-pair level. Coarse LR partitioning on body-Muon is **permanently de-prioritized**.

**NS-quality axis pinned:** #511 NS_ITERS={10,14} NULL/NULL n=2, #540 NS coefficients (quintic + aggressive-cubic) NULL/NULL, #546 NS_ITERS={16,18} Arm A=16 NULL (Arm B pending). NS preconditioner quality saturated at NS_ITERS=12 cubic Newton across BOTH polynomial structure AND iteration count.

**Aux AdamW update-rule mechanism tree** is the new active frontier with **all three leaves now under test**:
- v-estimator: fern #545 AdaBelief (`v ← β2·v + (1-β2)·(g - m̂)²`) — Arm B running
- m-step: askeladd #575 NadamW (Nesterov lookahead in m̂ usage) — Arm A running
- v-clamp: **edward #578 AMSGrad NEW** (`v_max = max(v_max, v̂)` monotone running max) — pending pickup

**26 scalar/mechanism axes closed** at inherited defaults (now incl. #503 body-WD schedule NULL/NULL clear, #505 Lookahead wrapper NULL/NULL clear, #513 body-Muon grad clipping NULL/NULL clear, #519 PMuon γ pruning {0, 0.8} NULL/NULL clear, #522 Skylight floor cooldown phase-out NULL/NULL clear, #511 NS_ITERS scan {10, 14} NULL/NULL n=2, #535 sub-MLP LR partition NULL/NULL clear, #532 depth-based LR partition NULL/NULL clear, **#540 NS coefficient scan NULL/NULL clear**). Active families:

1. **AdaBelief v-estimator on aux AdamW** (fern #545 Arm B running).
2. **NadamW Nesterov m-step on aux AdamW** (askeladd #575 Arm A running).
3. **AMSGrad v-clamp on aux AdamW** (edward #578 NEW — third leaf of aux update-rule mechanism tree).
4. **NS preconditioner quality — iteration count extension** (thorfinn #546 NS=18 Arm B running).
5. **Gradient centralization on body-Muon pre-NS** (frieren #553 Arm B running — gradient TRANSFORMATION class, orthogonal to all preconditioning/wrapping/partition work).
6. **NS_ITERS cooldown ramp** (nezuko #559 — scheduled preconditioner quality during effective cooldown phase, distinct from constant-NS tests and early-NS-warmup).
7. **PMuon ε floor (eigenvalue clamp in spectral whitening)** (tanjiro #562 — only untested PMuon scalar; closes scalar audit of full PMuon stack).
8. **PMuon mu (body-Muon momentum EMA)** (alphonse #570 — temporal smoothing axis. Mechanistically distinct from β_cov: mu smooths the raw gradient buffer feeding NS polar map, β_cov smooths the bilateral covariance estimates).

**Body-Muon WD exhaustively tested:** partition (#482 NULL), schedule (#503 NULL/NULL clear). Constant uniform WD=0.025 confirmed locally optimal. **Wrapper-class on body-Muon closed** (#505 Lookahead NULL/NULL clear). **Body-Muon damping/clipping closed at tested thresholds** (#513 NULL/NULL — but thresholds {0.5, 1.0} were 4-5 orders below natural-norm regime ~3e4; PMuon's whitening confirmed approximately scale-invariant). **PMuon γ axis fully mapped:** {0 (#519 Arm A, +0.018), 0.4 (baseline), 0.8 (#519 Arm B, +0.050), ramp #444 NULL} — γ=0.4 load-bearing and near-optimal. **NS_ITERS scalar closed at constant regime** ({10, 12, 14} mapped via #511).

**Emerging pattern after 26 closed axes:** mechanism scalars saturate at inherited defaults. **Body-Muon LR partition family FULLY CLOSED** (per-type MLP-vs-ATTN #499 NULL/NULL, sub-MLP c_fc vs c_proj #535 NULL/NULL clear, depth #532 NULL/NULL clear). Wrapper-class on body-Muon closed. Damping/clipping closed below natural-norm regime. γ-axis fully mapped. **NS-quality axis pinned** across polynomial structure (#540 NULL/NULL) and iteration count ({10, 14} #511 NULL/NULL n=2; {16, 18} #546 Arm A=16 NULL, Arm B=18 in flight). **Coarse LR partitioning on body-Muon is permanently de-prioritized** — PMuon's per-matrix whitening eliminates the headroom that LR multipliers could have exploited.

**The aux-AdamW update-rule mechanism tree is the new active frontier with all three leaves under simultaneous test:** v-estimator (AdaBelief #545), m-step (NadamW #575), v-clamp (AMSGrad #578 NEW). This is a complete mechanism-class audit of aux AdamW's update step structure. Plus remaining body-Muon scalars (mu #570, ε floor #562), gradient pre-transformations (GC #553), and scheduled mechanisms (NS cooldown ramp #559).

## Open unexplored axes (candidate next assignments)

- **Per-block LR multiplier** (depth-based) — **CLOSED (#532 NULL/NULL clear)**
- **Sub-MLP LR partition (c_fc vs c_proj)** — **CLOSED (#535 NULL/NULL clear)**
- **NS coefficient (a,b,c) joint scan** — **CLOSED (#540 NULL/NULL clear)**
- **PMuon mu (body-Muon momentum EMA)** — **IN FLIGHT (#570 alphonse)** — only untested PMuon/body-Muon scalar
- **AdaBelief on aux AdamW (v-estimator)** — **IN FLIGHT (#545 fern)**
- **NadamW on aux AdamW (m-step Nesterov)** — **IN FLIGHT (#575 askeladd)** — fresh aux m-step mechanism
- **AMSGrad v-clamp on aux AdamW** — **IN FLIGHT (#578 edward NEW)** — third leaf of aux update-rule tree
- **RAdam variance rectification** — UNTESTED — first-moment warmup compensation
- **Lion (sign-momentum) on aux** — UNTESTED — completely different family from Adam
- **Adamax (L∞ norm v)** — UNTESTED — alternative v-aggregation
- **Sophia-style scalar Hessian on aux AdamW** — UNTESTED — second-order aux update
- **NS_ITERS cooldown ramp** — **IN FLIGHT (#559 nezuko)**
- **NS_ITERS=16 / NS_ITERS=18 follow-up** — **IN FLIGHT (#546 thorfinn)** — Arm A=16 NULL terminal, Arm B=18 in flight
- **PMuon ε floor (matrix_neg_power eigenvalue clamp)** — **IN FLIGHT (#562 tanjiro)** — only untested PMuon scalar
- **Skip-connection LR multiplier** — UNTESTED
- **Embed eps below 1e-10** {1e-12, 1e-14} — gradient pointed *down* from #463, but BF16 floor concern
- **EMA wrapper (Polyak)** — REDUNDANT after #505 closes wrapper-class
- **Body-Muon grad clipping at natural-norm regime** {3e4, 1e5, 3e5} — DEFERRED (#513 student suggestion)
- **Per-token-position embed weight init asymmetry** — UNTESTED
- **COOLDOWN_POWER fine-scan** {1.3, 1.5, 1.6} — scalar likely NULL given pattern; low priority
- **Per-block residual scaling** (DeepNet-style gates) — architecture-adjacent, on r4 #452
- **Tied lm_head ↔ embed** — out of scope (architecture change)

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
