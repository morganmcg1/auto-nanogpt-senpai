# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-20 21:15 UTC
- **Most recent direction from humans:** None.
- **Target:** Push `speedrun/final_first_step_to_target` below 2937.5 steps. Public record was 3030 steps — LOCAL RECORD 2937.5 (PR #413).

## Current local baseline

**sr=2937.5 (n=2 mean), val/loss=3.264278 (n=2 mean)** — PR #413 (g1r1-alphonse, scalar_lr=0.025). **MERGED 11:48 UTC.**

Config: cubic-Newton NS (a=1.5, b=-0.5, c=0) + PMuon γ_power=0.4 + u/w-floor (TARGET_UW=0.35) + COOLDOWN_POWER=1.4 + Muon lr=0.035 wd=0.025 STATIC + aux AdamW embed_lr=0.3, lm_head_lr=1/160, **scalar_lr=0.025**, betas=(0.8, 0.95), eps=1e-10, **wd=0**, **β_cov=0.95 STATIC**.

W&B runs: seed-1 `k7ylyby9`, seed-2 `dm4joozw`. Win: sr≤2925 OR (sr=2925 AND val<3.264278). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.

## Axes CLOSED this cycle (11:48–15:40 UTC)

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
| **#486** | nezuko | Skylight u/w-floor scan TARGET_UW∈{0.25, 0.45}: symmetric +87.5 sr both arms. 0.35 confirmed local optimum. | CLOSED 00:15 UTC |
| **#502** | askeladd | PMuon β_cov scan {0.90, 0.99}: Arm A fs=2950 marginal NULL, Arm B fs=3000 clear NULL. β_cov=0.95 locally optimal. | CLOSED 03:25 UTC |
| **#499** | alphonse | Body-Muon LR per-type partition (MLP=0.042/ATTN=0.028 vs swap): both arms clear NULL ~Δval=+0.006 symmetric. PMuon's per-matrix whitening equalizes per-module gradient geometry. | CLOSED 03:40 UTC |
| **#503** | edward | Body-Muon WD schedule (warmup-25pct vs cooldown-25pct): asymmetric NULL/NULL. WD's implicit norm-control load-bearing during cooldown. | CLOSED 04:28 UTC |
| **#505** | fern | Lookahead wrapper k∈{5, 10}, α=0.5: both DNF Δval ≥ +0.02. Wrapper-class on body-Muon closed. | **CLOSED 05:32 UTC** |
| **#513** | thorfinn | Body-Muon gradient clipping at {1.0, 0.5}: both NULL clear, clip activated 99.97% — PMuon's spectral whitening confirmed approximately scale-invariant. | **CLOSED 06:08 UTC** |
| **#519** | frieren | PMuon γ pruning γ∈{0, 0.8} vs baseline 0.4: γ=0 Δval=+0.0183 / γ=0.8 Δval=+0.0496 — γ=0.4 load-bearing AND near-optimal. | **CLOSED 07:30 UTC** |
| **#522** | nezuko | Skylight u/w-floor cooldown phase-out: asymmetric NULL. Floor and cooldown complementary not redundant. | **CLOSED 08:55 UTC** |
| **#511** | tanjiro | NS_ITERS scan {10, 14} vs baseline 12: Arm A NS=10 clear NULL; Arm B NS=14 marginal n=1 win → n=2 NO confirm. NS_ITERS=12 confirmed locally optimal at constant-iter regime. | **CLOSED 09:25 UTC** |
| **#535** | alphonse | Sub-MLP LR partition c_fc vs c_proj: both NULL clear. PMuon's per-matrix bilateral whitening equalizes c_fc / c_proj effective gradient. | **CLOSED 11:30 UTC** |
| **#532** | askeladd | Body-Muon depth-based LR partition (early-fast vs late-fast): both NULL clear. Body-Muon LR partition family fully closed across all three coarse subdivisions. | **CLOSED 12:10 UTC** |
| **#540** | edward | NS coefficient scan (quintic vs aggressive-cubic): both NULL clear AND identical sr=2975 — polynomial perturbations cost ~37 sr in both directions. | **CLOSED 13:15 UTC** |
| **#546** | thorfinn | NS_ITERS extension {16, 18}: both NULL clear. Combined with #511 produces beautifully clean V-shape 5-point response curve {10, 12, 14, 16, 18}. NS-quality axis exhaustively pinned across polynomial structure AND iteration count. | **CLOSED 14:00 UTC** |
| **#545** | fern | AdaBelief on aux AdamW v-estimator: both NULL clear (paper-formulation after step-1 bug-fix). v_belief/g² ≈ 0.70 confirms mechanism works as designed; aux gradients noise-dominated so Var(g) preconditioner is informationally equivalent to E[g²]. v-estimator axis closes at standard AdamW raw \|g\|². | **CLOSED 14:25 UTC** |
| **#553** | frieren | Gradient Centralization on body-Muon pre-NS (Yong et al 2020): both NULL clear. Arm A dim=1 fs=3000 val=3.268599 Δsr=+62.5 Δval=+0.0043; Arm B dim=0 fs=3025 val=3.271550 Δsr=+87.5 Δval=+0.0073. **Astonishing 5000-10000× signal-to-perturbation ratio**: removed 0.011-0.021% of L2 norm, regressed 62-87 sr. PMuon's NS whitening preserves and uses the rank-1 column/row-mean as singular-vector signal — subtracting it drops a top-singular-vertex pair from the polar step. **Opposite-sign finding from Yong et al 2020 (ImageNet/ResNet)** — Muon-class optimizers use singular structure that GC removes. dim=0 (per-input-channel) carries more signal than dim=1 (per-output-channel). | **CLOSED 15:35 UTC** |
| **#562** | tanjiro | PMuon ε floor scan {1e-10, 1e-14} vs baseline 1e-12: Arm A fs=2950 val=3.26563 marginal NULL, Arm B fs=2975 val=3.2660 clear NULL. ε=1e-12 baseline confirmed optimal ±2 OOM. **PMuon scalar audit COMPLETE** — all 5 PMuon scalars now at confirmed local optima. | **CLOSED 19:11 UTC — 31st axis.** |
| **#570** | alphonse | PMuon mu {0.90, 0.97} vs baseline 0.95: BOTH arms sr=3075 Δsr=+137.5 — symmetric sharp local optimum. Arm A val=3.275656, Arm B val=3.272967. mu=0.95 confirmed locally optimal; momentum-horizon axis CLOSES. | **CLOSED 20:30 UTC — 32nd axis.** |
| **#585** | fern | AdEMAMix m-aggregation on aux AdamW — Arm A (α=2) NULL clear fs=3100 val=3.2756 (Δsr=+162.5 Δval=+0.011). Arm B (α=5) not launched (student skip endorsed: strong Arm A NULL). m-aggregation (slow-EMA blending) axis closes. | **CLOSED 20:30 UTC — 33rd axis.** |

## Active experiments (8 students, 21:15 UTC)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#609** | **askeladd** | pending pickup | — | — | **NEW — LAMB trust ratio on aux AdamW. Per-tensor step rescaling: trust_ratio = clip(||w||/||r||, 0, max_trust). ORTHOGONAL to closed update-rule mechanisms. Arm A max_trust=10 (paper default), Arm B max_trust=1 (conservative, no amplification).** |
| **#607** | alphonse | `u6917ygn` Arm A η_min=0.10 | step ~200 | early | LR floor. Active training with GPU 71 GB. Student iterating after early crash. |
| **#606** | fern | `kq05a45r` Arm A cf=0.25 | step ~450 | ~3.88 | WSD schedule. Active training. |
| **#604** | tanjiro | `tsi8kfik` Arm A lr×1/3 v2 | step ~225 | ~4.77 | Lion optimizer. 2 earlier divergent runs; clean v2 now training. GPU 71 GB. |
| **#588** | frieren | `fiiel4pd` Arm B α=0.20 | step ~500 | ~3.80 | Col-mean amplification Arm B running. Arm A NULL confirmed (sr=2975). |
| **#583** | thorfinn | `p8l0a36v` Arm B β2=0.999 | step ~375 | ~3.91 | Adamax Arm B early. Arm A DNF NULL confirmed. |
| **#578** | edward | `gz7ktuqr` Arm B uncorrected v_max | step ~2000 | ~3.43 | ETA terminal ~22:00 UTC. Arm A DNF NULL confirmed. |
| **#559** | nezuko | `do531bbp` Arm B 12→18 | step ~125 | ~4.47 | NS ramp Arm B launched. Arm A NULL sr=2950 confirmed. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#575** | askeladd | NadamW m-step NULL/NULL — Arm A (β1=0.8) sr=2975 val=3.26587; Arm B (β1=0.85) sr=2975 val=3.26673. Both arms tie at sr=2975 Δsr=+37.5. m-step mechanism leaf CLOSES. | **CLOSED 21:15 UTC — 34th axis.** |
| **#570** | alphonse | PMuon mu NULL/NULL — Arm A (0.90) sr=3075 val=3.275656 Δsr=+137.5; Arm B (0.97) sr=3075 val=3.272967 Δsr=+137.5. Symmetric sharp local optimum at 0.95. mu axis CLOSES. | **CLOSED 20:30 UTC — 32nd axis.** |
| **#585** | fern | AdEMAMix m-aggregation NULL — Arm A (α=2) fs=3100 val=3.2756 Δsr=+162.5 Δval=+0.011. Arm B skip endorsed. | **CLOSED 20:30 UTC — 33rd axis.** |
| **#562** | tanjiro | PMuon ε floor NULL/NULL (Arm A fs=2950 marginal; Arm B fs=2975 clear). ε=1e-12 confirmed optimal ±2 OOM. | **CLOSED 19:11 UTC — 31st axis.** |

## Recently merged

| PR | Student | Key result | Decision |
|---|---|---|---|
| **#413** | alphonse | scalar_lr=0.025: n=2 sr=2937.5, val=3.264278 | **MERGED 11:48 UTC** — current baseline. |

## Current research focus (updated 20:35 UTC)

**LR schedule shape is the active new frontier.** After 33 closed axes exhausting PMuon scalars, aux AdamW update-rule mechanisms, and optimizer class tests:

**New schedule-shape assignments (this session):**
- **#606 fern WSD schedule** — global `cooldown_frac` {0.25, 0.15} vs baseline 0.70. More stable training at peak LR before sharp terminal decay. The baseline already uses zero warmup (starts at full LR), so WSD changes how long the peak plateau lasts before cooldown begins.
- **#607 alphonse LR floor** — `eta = max(LR_FLOOR, w^COOLDOWN_POWER)` prevents LR collapsing to zero in late cooldown. Arm A: 10% floor (activates at step ~2811, through speedrun zone); Arm B: 5% floor (activates at step ~2993). Flagged in BASELINE.md PR #274 notes as unexplored.

**Aux AdamW update-rule tree — 4 of 5 leaves CLOSED NULL/NULL:**
- **v-estimator** (#545 AdaBelief): **CLOSED NULL/NULL**
- **m-step** (#575 NadamW): **CLOSED NULL/NULL** (both β1 values tied at sr=2975)
- **m-aggregation** (#585 AdEMAMix): **CLOSED NULL/NULL**
- **v-aggregation** (#583 thorfinn Adamax): In flight — Arm A DNF NULL, Arm B β2=0.999 early
- **v-clamp** (#578 edward AMSGrad): In flight — Arm A DNF NULL, Arm B uncorrected ETA ~22:00

**Step-rescaling (orthogonal to update-rule):**
- **LAMB trust ratio** (#609 askeladd NEW): Arm A max_trust=10, Arm B max_trust=1 — pending pickup

**Other in-flight families:**
1. **NS_ITERS cooldown ramp 12→{16,18}** (#559 nezuko) — Arm A ETA ~20:45 UTC
2. **Body-Muon column-mean AMPLIFICATION pre-NS** (#588 frieren) — Arm A ETA ~21:00 UTC
3. **Lion optimizer on aux** (#604 tanjiro) — pending pickup

**Closed axes summary (33 total):**

*PMuon scalar audit COMPLETE (all 5 scalars pinned):* γ_power=0.4 (#519), β_cov=0.95 (#502), NS_ITERS=12 (#511+#546 5-pt V-curve), NS coefficients cubic (1.5,-0.5,0) (#540), ε=1e-12 (#562). mu=0.95 (#570 symmetric +137.5 sr both sides).

*Body-Muon LR partition family FULLY CLOSED:* #499 per-type, #535 sub-MLP, #532 depth-based. PMuon's per-matrix bilateral whitening neutralizes LR multipliers.

*Body-Muon scalars/wrappers exhaustively tested:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead wrapper (#505 DNF).

*Aux AdamW scalar/static settings fully tested:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466). v-estimator mechanism CLOSED (#545). m-aggregation mechanism CLOSED (#585).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient processing on body-Muon:* GC subtraction (#553 NULL — rank-1 mean is singular-vector signal), clipping (#513 NULL).

*Other closed:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447), decoupled cooldown_frac (#448).

**Pattern after 33 axes:** The PMuon+aux-AdamW stack is near-saturated on all internal scalar and mechanism dimensions. Remaining unexplored levers are external: schedule SHAPE (WSD, LR floor — now in flight), new optimizer classes (Lion #604 — in flight), and gradient transformation sub-classes (column-mean amplification #588 — in flight).

## Open unexplored axes (candidate next assignments)

**LR schedule shape (active frontier):**
- **WSD schedule (cooldown_frac scan)** — **IN FLIGHT (#606 fern)** — {0.25, 0.15} vs baseline 0.70
- **LR floor in cooldown** — **IN FLIGHT (#607 alphonse)** — eta_min ∈ {0.10, 0.05}
- **COOLDOWN_POWER fine-scan** {1.3, 1.5, 1.6} — low priority given scalar saturation pattern

**Aux AdamW update-rule mechanism tree:**
- **v-aggregation Adamax** — **IN FLIGHT (#583 thorfinn)**
- **v-clamp AMSGrad** — **IN FLIGHT (#578 edward)**
- **v-estimator AdaBelief** — **CLOSED (#545)**
- **m-step NadamW** — **CLOSED (#575)**
- **m-aggregation AdEMAMix** — **CLOSED (#585)**
- **LAMB trust ratio on aux** — **IN FLIGHT (#609 askeladd NEW)** — per-tensor step rescaling, orthogonal axis
- **RAdam variance rectification** — UNTESTED — first-moment warmup compensation
- **Sophia-style scalar Hessian on aux** — UNTESTED — second-order diagonal curvature estimate

**New optimizer classes:**
- **Lion on aux** — **IN FLIGHT (#604 tanjiro)** — sign-of-momentum, no v-state
- **SOAP on aux** — UNTESTED — second-order full-matrix preconditioning (simpler than body-Muon)

**Gradient transformation (body-Muon pre-NS):**
- **Column-mean amplification** — **IN FLIGHT (#588 frieren)**
- **Sign / Winsorization / tanh-squash** — UNTESTED

**NS schedule:**
- **NS_ITERS cooldown ramp 12→{16,18}** — **IN FLIGHT (#559 nezuko)**

**Closed (reference):**
- Per-block LR partition (#532), sub-MLP LR partition (#535), per-type LR partition (#499): **CLOSED**
- NS coefficients (#540), NS_ITERS {10-18} (#511+#546): **CLOSED**
- PMuon scalars γ_power, β_cov, ε, mu (#519,#502,#562,#570): **CLOSED**
- Body-Muon WD (#482,#503), clipping (#513), Lookahead (#505): **CLOSED**
- Aux scalars β1,β2,eps,WD,lr_groups (#416,#433,#463,#466,#460,#465): **CLOSED**
- Skylight floor magnitude/schedule (#486,#522): **CLOSED**
- GC subtraction (#553), z-loss (#476), embed init (#440), attn-scale (#480): **CLOSED**
- Decoupled aux cooldown_frac (#448): **CLOSED**

## Statistical rule reminder

`(3.28 − μ) × √n ≥ 0.004`. n=1 win: sr ≤ 2925 OR (sr = 2925 AND val < 3.264278). Stat-sig threshold: val ≤ 3.276 (n=1), val ≤ 3.277 (n=2). Marginal (Δsr ≤ 25 OR Δval ≤ 0.001): request n=2 before merge.
