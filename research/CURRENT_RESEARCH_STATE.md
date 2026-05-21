# SENPAI Research State — auto-nanogpt-1gpu-r1

- **Last update:** 2026-05-21 07:10 UTC
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

## Active experiments (8 students, 07:10 UTC — 0 idle)

| PR | Student | Run | Step/3250 | val | Status |
|---|---|---|---|---|---|
| **#658** | edward | pending pickup | — | — | **NEW (07:10 UTC) — Post-NS momentum position in PMuon. Arm A: post_ns (momentum on polar outputs, no repolar). Arm B: post_ns_repolar (momentum on polar outputs + re-apply polar to restore unit spectral norm). Both at mu=0.95. Clean orthogonal axis: momentum has lived pre-whitening/pre-NS in all 42 closed experiments.** |
| **#651** | tanjiro | `8m6903wo` Arm A warmup=100 | running ~step 275 | early | LR warmup phase — Arm A warmup_steps=100. Arm B warmup_steps=250 queued. |
| **#647** | askeladd | `tk8hizl3` Arm A cf=0.80 | running ~step 944 | early | WSD LONGER cooldown_frac — Arm A cf=0.80. Concurrent torchrun duplicate self-cleaned (06:32 UTC). Arm B cf=0.85 queued after Arm A. |
| **#644** | fern | `5erh0eht` Arm A k=1.5 warmup100-fix | running ~step 625 | early | Winsorization pre-NS — EMA fix iteration 2 (warmup extended 10→100 steps for L_cov transient). |
| **#607** | alphonse | `0d0waydp` Arm B η_min=0.05 | running ~step 2350 | 3.376 | LR floor — Arm B, ETA ~07:26 UTC. |
| **#622** | frieren | `w1rzdmoy` Arm C scale_mult=0.005 | running ~step 650 | early | tanh-squash follow-up. Arm A 0.5 = near-identity (confirmed). Arm C 0.005 actually exercises squash (per-frieren analysis). |
| **#623** | thorfinn | `e41ak5px` Arm B r=1.0 | running ~step 2175 | 3.42 | Schedule-Free Adam Arm B (Polyak-tilt r=1.0). Arm A r=0 DNF val=3.31. Arm B likely DNF trajectory (val 3.42 at step 2175). |
| **#627** | nezuko | `xaaqncix` Arm B mlp-only | running ~step 1275 | 3.59 | Per-block grad L2 norm pre-NS. Arm A all-body finished (sr=3000 NULL). Arm B MLP-only running. |

## Recently closed (this session)

| PR | Student | Result | Decision |
|---|---|---|---|
| **#617** | edward | Lookahead wrapper on aux NULL/NULL — Arm A k=5 val=3.267040 sr=2975 Δval=+0.00276 Δsr=+37.5; Arm B k=10 val=3.269989 sr=3025 Δval=+0.00571 Δsr=+87.5. Mechanism: Lookahead's pull-back (1-α) per sync halves effective aux LR. Longer k→worse. Aux side FULLY SATURATED across 8 optimizer families. | **CLOSED 07:10 UTC — 42nd axis.** |
| **#604** | tanjiro | Lion optimizer on aux NULL/NULL DNF — Arm A lr_scale=1/3 val=3.29790 (DNF SIGTERM partial); Arm B lr_scale=1/10 val=3.29465 (DNF clean). Lion's sign-of-momentum strips magnitude info from the finely-calibrated aux per-group LRs (embed=0.3, lm_head=1/160, scalar=0.025). Both arms test two uniform step sizes — both too coarse to match what E[g²]-normalized AdamW provides. Lion mechanism class on aux CLOSES. | **CLOSED 05:50 UTC — 41st axis.** |
| **#609** | askeladd | LAMB trust ratio on aux NULL/NULL DNF — Arm A literal val=3.34623 (Δval=+0.082); Arm B canonical val=3.29541 (Δval=+0.031). Trust ratio saturates at max_trust=10 entire run (||w||/||step|| ≈ 1e10 on embed) → LAMB becomes constant 10× amplifier outside its design domain. Aux gradients on embed/lm_head/scalars don't respond to per-tensor step normalization. | **CLOSED 05:00 UTC — 40th axis.** |
| **#606** | fern | WSD shorter cooldown_frac NULL DNF / Arm B SKIPPED. Arm A cf=0.25 val=3.30081 sr=-1 DNF (1.10pp worse than baseline val=3.264). Arm B cf=0.15 (strictly shorter cooldown) skipped — predicted worse given Arm A's clear regression. Confirms cooldown_frac=0.70 baseline is load-bearing: all val-loss progress 3.55→3.30 happens in the 25% decay tail. Going *shorter* on cooldown — even by 6pp — destroys the speedrun mechanism. **WSD shorter-cooldown direction CLOSED.** | **CLOSED 04:30 UTC — 39th axis.** |
| **#559** | nezuko | NS_ITERS cooldown ramp 12→{16,18} NULL/NULL — Arm A 12→16 sr=2950 val=3.2650 Δsr=+12.5; Arm B 12→18 sr=2975 val=3.2670 Δsr=+37.5. NS-quality axis FULLY PINNED across schedule shape (combined with #511 constant-NS=10 and #546 constant-NS={16,18}). NS_ITERS=12 STATIC confirmed optimal at every schedule shape tested. | **CLOSED 00:00 UTC — 38th axis.** |
| **#583** | thorfinn | Adamax NULL DNF/NULL DNF — Arm A β2=0.95 val=3.28038; Arm B β2=0.999 val=3.28384. Both DNF (never reached 3.28). Trajectories tracked tightly throughout. v-aggregation leaf CLOSES. **🎯 AUX UPDATE-RULE MECHANISM TREE FULLY EXHAUSTED — 5/5 leaves NULL/NULL.** | **CLOSED 23:46 UTC — 37th axis.** |
| **#588** | frieren | Body-Muon column-mean AMPLIFICATION NULL/NULL — Arm A α=0.05 dim=1 sr=2975 val=3.26788 Δsr=+37.5; Arm B α=0.20 dim=1 sr=2950 val=3.26550 Δsr=+12.5. Rank-1 column-mean transformation class CLOSES symmetrically (combined with #553 subtraction). Non-monotone cost in α (Arm B hurt less) — likely polar-map renormalization at large α. | **CLOSED 23:33 UTC — 36th axis.** |
| **#578** | edward | AMSGrad v-clamp NULL/NULL — Arm A (bias-corrected) DNF val=3.2805; Arm B (uncorrected) sr=3200 val=3.2794 Δsr=+262.5 Δval=+0.0151. v-clamp mechanism leaf CLOSES. 4th aux update-rule leaf NULL/NULL. | **CLOSED 22:43 UTC — 35th axis.** |
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

**🎯 Aux AdamW update-rule tree — 5/5 leaves CLOSED NULL/NULL (FULL EXHAUSTION):**
- **v-estimator** (#545 AdaBelief): **CLOSED NULL/NULL**
- **m-step** (#575 NadamW): **CLOSED NULL/NULL** (both β1 values tied at sr=2975)
- **m-aggregation** (#585 AdEMAMix): **CLOSED NULL/NULL**
- **v-clamp** (#578 AMSGrad): **CLOSED NULL/NULL** — Arm A bias-corrected DNF; Arm B uncorrected sr=3200 Δsr=+262.5
- **v-aggregation** (#583 Adamax): **CLOSED NULL/NULL** — Arm A β2=0.95 DNF val=3.28038; Arm B β2=0.999 DNF val=3.28384. Trajectories track tightly throughout. 5th and final leaf.

**Step-rescaling (orthogonal to update-rule):**
- **WSD LONGER cooldown_frac** (#647 askeladd): {0.80, 0.85} — pending pickup
- **LR warmup phase** (#651 tanjiro NEW): {100, 250 steps} — codebase has zero warmup, never tested

**Other in-flight families:**
1. **Per-block grad L2 norm pre-NS** (#627 nezuko) — Arm B MLP-only running
2. **tanh-squash pre-NS** (#622 frieren) — follow-up arms after scale_mult={0.5} baseline
3. **Winsorization pre-NS** (#644 fern) — Arm A k=1.5 running
4. **Schedule-Free Adam** (#623 thorfinn) — Arm A r=0 p=2.0 training
5. **LR floor cooldown** (#607 alphonse) — Arm B η_min=0.05 running
6. **Lookahead wrapper on aux AdamW** (#617 edward) — Arm B k=10 running

**Closed axes summary (37 total):**

*PMuon scalar audit COMPLETE (all 5 scalars pinned):* γ_power=0.4 (#519), β_cov=0.95 (#502), NS_ITERS=12 (#511+#546 5-pt V-curve), NS coefficients cubic (1.5,-0.5,0) (#540), ε=1e-12 (#562). mu=0.95 (#570 symmetric +137.5 sr both sides).

*Body-Muon LR partition family FULLY CLOSED:* #499 per-type, #535 sub-MLP, #532 depth-based. PMuon's per-matrix bilateral whitening neutralizes LR multipliers.

*Body-Muon scalars/wrappers exhaustively tested:* WD partition (#482), WD schedule (#503), grad clipping (#513), γ_power ramp (#444), lr fine-scan (#465), Lookahead wrapper (#505 DNF).

*Aux AdamW scalar/static settings fully tested:* scalar_lr (#460), β1 (#416), β2 by-group (#433), embed eps (#463), aux WD (#466). v-estimator mechanism CLOSED (#545). m-aggregation mechanism CLOSED (#585).

*Skylight u/w-floor:* magnitude (#486), phase-out (#522). TARGET_UW=0.35 confirmed.

*Gradient processing on body-Muon:* GC subtraction (#553 NULL — rank-1 mean is singular-vector signal), clipping (#513 NULL).

*Other closed:* z-loss (#476), embed init (#440), attn-scale (#480), logit soft-cap (#439), NS adaptive threshold (#447), decoupled cooldown_frac (#448).

**Pattern after 42 axes:** The PMuon+aux-AdamW stack is fully saturated on all internal scalar and mechanism dimensions. **Aux side FULLY SATURATED across 8 distinct optimizer families:** 5/5 update-rule mechanisms (AdaBelief #545, NadamW #575, AdEMAMix #585, AMSGrad #578, Adamax #583) + LAMB trust-ratio (#609) + Lion sign-of-momentum (#604) + Lookahead wrapper (#617) — all NULL/NULL. The aux gradients on embed/lm_head/scalars are low-information and unresponsive to ANY update-rule, wrapper, or averaging class. **WSD shorter-cooldown direction CLOSED** (#606, 39th axis). New body-Muon axis opened: PMuon momentum position (pre-NS vs post-NS) — momentum has lived pre-whitening/pre-NS in all 42 closed experiments. Remaining unexplored levers: post-NS momentum (#658 edward NEW), WSD longer-cooldown (#647), LR warmup phase (#651), LR-floor (#607), schedule-free aux (#623), gradient-element transformation (#622 tanh-squash, #644 Winsorization), block-level grad normalization (#627 per-block-norm).

## Open unexplored axes (candidate next assignments)

**LR schedule shape (mostly closed):**
- **WSD shorter cooldown_frac** — **CLOSED (#606 fern, 39th axis)** — Arm A cf=0.25 NULL DNF val=3.30081, Arm B cf=0.15 SKIPPED. Cooldown=0.70 load-bearing.
- **LR floor in cooldown** — **IN FLIGHT (#607 alphonse)** — eta_min ∈ {0.10, 0.05}; Arm A NULL (floor too aggressive), Arm B running.
- **WSD LONGER cooldown_frac** — **IN FLIGHT (#647 askeladd)** — {0.80, 0.85} vs baseline 0.70. Symmetric to #606 closure.
- **LR warmup phase** — **IN FLIGHT (#651 tanjiro NEW)** — warmup_steps ∈ {100, 250} vs baseline 0. Codebase starts at full LR — never tested.
- **COOLDOWN_POWER fine-scan** {1.3, 1.5, 1.6} — low priority given scalar saturation pattern

**Aux AdamW update-rule mechanism tree:**
- **v-aggregation Adamax** — **IN FLIGHT (#583 thorfinn)**
- **v-clamp AMSGrad** — **CLOSED (#578)** — 35th axis, NULL/NULL
- **v-estimator AdaBelief** — **CLOSED (#545)**
- **m-step NadamW** — **CLOSED (#575)**
- **m-aggregation AdEMAMix** — **CLOSED (#585)**
- **LAMB trust ratio on aux** — **CLOSED (#609 askeladd, 40th axis)** — trust saturates at max_trust=10 entire run (||w||/||step|| ≈ 1e10); degenerate amplifier. Arm A NULL DNF val=3.346, Arm B NULL DNF val=3.295.
- **Lookahead wrapper on aux** — **IN FLIGHT (#617 edward NEW)** — slow-weights averaging, ORTHOGONAL class to update-rule
- **RAdam variance rectification** — UNTESTED — first-moment warmup compensation
- **Sophia-style scalar Hessian on aux** — UNTESTED — second-order diagonal curvature estimate

**New optimizer classes on aux — FULLY SATURATED:**
- **Lion on aux** — **CLOSED (#604, 41st axis)** — sign-of-momentum strips magnitude; both lr_scale arms {1/3, 1/10} NULL DNF.
- **Lookahead wrapper on aux** — **CLOSED (#617, 42nd axis)** — effective LR damping by α/k per sync; k=5 Δsr=+37.5, k=10 Δsr=+87.5.
- **SOAP on aux** — deferred — given full aux saturation, body-Muon is higher priority

**Body-Muon mechanism (NEW axis):**
- **PMuon momentum position (pre-NS vs post-NS)** — **IN FLIGHT (#658 edward NEW)** — Arm A post_ns, Arm B post_ns_repolar. First time operator ordering in PMuon pipeline is tested.

**Gradient transformation (body-Muon pre-NS):**
- **Column-mean amplification** — **CLOSED (#588 frieren)** — rank-1 transformation class closed.
- **tanh-squash** — **IN FLIGHT (#622 frieren)** — element-wise smooth compression; telemetry shows scale_mult={0.5,1.0} near-identity, follow-up arms planned at {0.005, 0.02}.
- **Winsorization (hard-clip)** — **IN FLIGHT (#644 fern NEW)** — orthogonal hard-clip counterpart to tanh-squash.
- **Sign-only / RMS-normalized** — UNTESTED

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
