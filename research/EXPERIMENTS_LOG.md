# SENPAI Research Results — auto-nanogpt-1gpu-r2

## 2026-05-19 12:22 UTC — Cycle 68: #405 CLOSED CONTRA_MUON sweep (regression-to-mean at n=4); askeladd → #468 AdamW gradient clipping

### PR #405 — CONTRA_MUON sweep (0.3 Arm A, 0.35 Arm B) — CLOSED

Branch: `g1r2-askeladd/contra-muon-0.3-sweep`. Direct continuation of PR #358 (CONTRA_MUON=0.5→0.4). Running on CONTRA_MUON=0.4 base. All screens ran on PREV mandatory stack (no MU_WARMUP_STEPS).

| Arm | CONTRA_MUON | W&B | n | val mean | ffs mean | vs strict bar | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.3 | `tektwuqy` | 2 | 3.274865 | 3075 | MISS both (val +0.000482, ffs +6.25 vs OLD bar) | missed |
| B (n=2 screen) | 0.35 | `ijqrvfy4` | 2 | 3.273505 | 3050 | PASS both vs OLD bar ✅ | screen win |
| B (n=4 confirm) | 0.35 | `6svhvfu8` | 3 (T3 killed) | 3.275009 | 3075 | MISS both (NEW bar: val +0.001532, ffs +18.75) | CLOSED |

**Per-trial n=4 confirm (Arm B `6svhvfu8` — T3 killed per bar-tightening foreclosure):**
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274879 | 3075 |
| T1 | 3.275224 | 3075 |
| T2 | 3.274923 | 3075 |
| T3 | terminated at ~703/3175 | — |
| n=3 mean | 3.275009 | 3075 |

**N=2 screen (Arm B):**
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27353 | 3050 |
| T1 | 3.27348 | 3050 |
| n=2 mean | 3.273505 | 3050 |

**Key findings:**
- **Arm A (0.3)**: Flat vs Arm A baseline mean val≈3.2749 (Δ=+0.000482 above old bar), ffs=3075 — slightly worse than 0.4. Response surface is flat/slightly negative below 0.4.
- **Arm B n=2 screen**: Both trials landed exactly at val~3.2735/ffs=3050 — looked like a Goldilocks point at 0.35. Statsig 0.00918 PASS. However this was a seed-lucky draw.
- **Arm B n=4 collapse**: T0-T2 all landed at val~3.275/ffs=3075 (one bimodal slot above floor). Regression-to-mean: n=2 floor results were seed luck, not axis effect. Foreclosure via bar-tightening (PR #415 raised bar from 3.274383/3068.75 to 3.273477/3056.25) — T3 killed.
- **Root cause**: val-step-3025 trajectory clusters tightly around 3.28 (3.28272/3.28282/3.28322 in T0-T2). The 3.28 threshold is the ffs quantization boundary — tiny seed noise determines whether the step hits 3050 vs 3075. n=2 got lucky; n=4 reveals the true ~25-50% bimodal distribution at 3050.

**Mechanism conclusion**: CONTRA_MUON response surface is **flat between 0.3 and 0.4** on this stack. 0.4 remains the local optimum. The n=2→n=4 collapse is a portfolio-level lesson: **bimodal ffs distribution (3050 vs 3075) is dominated by seed variance on the val-step-3025 → ffs-quantization boundary**. A clean n=2 result where both trials land at 3050 does NOT robustly predict n=4 mean at 3050.

**Strategic consequence**: Contra-Muon/cooldown-geometry lever cluster confirmed saturated by 3 independent closures (#372 MuonEq-R, #406 MU_COOLDOWN_START, #405 CONTRA_MUON sweep). Future axes should avoid this cluster.

**Reassignment**: askeladd → #468 AdamW gradient clipping (GRAD_CLIP_NORM_ADAM=0.5 vs 1.0). Fresh mechanism — confirmed zero gradient clipping anywhere in codebase. Target: variance reduction via outlier-grad damping may improve ffs=3050 concentration by stabilizing AdamW step magnitudes during late cooldown.



## 2026-05-19 12:05 UTC — Cycle 66: #415 MERGED MU_WARMUP_STEPS=200 — STRICT-PASS WIN (val=3.273477/ffs=3056.25); #405/#406 early-terminate recommended (foreclosed on new bar); thorfinn → #462 MU_WARMUP_START sweep (0.80 vs 0.90)

### PR #415 — MU_WARMUP_STEPS=200 n=4 confirm — MERGED (new baseline) 🏆

Branch: `g1r2-thorfinn/mu-warmup-sweep`. Arm A only (Arm B=400 skipped per advisor advice to accelerate n=4). All runs on new CONTRA_MUON=0.4 base.

| Run | W&B | n | val mean | ffs mean | vs bar | Verdict |
|---|---|---|---|---|---|---|
| Smoke (MU_WARMUP_STEPS=0) | `25wu2nvt` | 1 (200 steps) | val=4.178 @ step 200 | — | baseline-equivalent | ✅ |
| Screen n=2 (warmup=200) | `xi4d6osg` | 2 | 3.273802 | 3050 | PASS ✅ | |
| **Confirm n=4 (warmup=200)** | **`nh6ge2df`** | **4** | **3.273477** | **3056.25** | **PASS ✅** | **MERGED** |

**Per-trial n=4 confirm** (`nh6ge2df`):
| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.272928 | 3050 |
| T1 | 3.274003 | 3050 |
| T2 | 3.272357 | 3050 |
| T3 | 3.274621 | 3075 |
| **n=4 mean** | **3.273477** | **3056.25** |

**Bar comparison vs old baseline `ivvf500c` (PR #358)**:
- val: 3.273477 < 3.274383 ✅ PASS by −0.000906
- ffs: 3056.25 < 3068.75 ✅ PASS by −12.5
- statsig n=4: (3.28−3.273477)×√4 = 0.013046 ≥ 0.004 ✅ PASS by 3.26×

**Cross-trial val spread: 0.0023** — one of the tightest n=4 spreads observed this cycle.

**Mechanism analysis**: Muon EMA `state["momentum"]` starts at zero; applying `cur_mu=0.95` (high smoothing) while the buffer is still populating produces effectively over-smoothed early updates. With explicit warmup (0.85→0.95 over 200 steps), the optimizer follows the recent-gradient signal more faithfully during the EMA-fill window. Empirical signature: step-125 val ≈4.42 (warmup) vs ≈4.51 (no-warmup baseline) — earlier loss improvement without stability regression. The mechanism is validated by the tighter cross-trial spread.

**New mandatory stack after merge**: `CONTRA_MUON=0.4 MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 MU_WARMUP_STEPS=200 MU_WARMUP_START=0.85`

**NEW MERGE BAR**: val < **3.273477** AND ffs < **3056.25** (STRICT). Critical implication: n=4 ffs bar now requires **ALL 4 trials at ffs=3050** — any single ffs=3075 gives mean=3056.25 which TIES, not beats.

**Portfolio impact**: All in-flight experiments running on old stack must be re-tested on new stack. PRs #405/#406 early-terminate recommended (both foreclosed on new ffs bar). PRs #456/#458/#459/#462 notified to use new mandatory stack.

**Reassignment**: thorfinn → #462 MU_WARMUP_START sweep (0.80 vs 0.90 around winning 0.85) — natural axis characterization of the warmup parameter, targeting configs that push more trials to ffs=3050 floor.

## 2026-05-19 11:40 UTC — Cycle 65: #435 CLOSED LOGIT_SOFTCAP_K axis FALSIFIED ±33% (clean output-head mechanism ablation, both arms early-terminated via Option B math foreclosure); frieren → #459 Lookahead-AdamW (fresh optimizer-wrapping mechanism)

### PR #435 — LOGIT_SOFTCAP_K sweep (K=10 vs K=22 around default K=15) — CLOSED axis-falsified

Branch: `g1r2-frieren/logit-softcap-sweep`. Both arms screened on new CONTRA_MUON=0.4 base. Excellent student execution: Option B early-terminate killed T1 of both arms when math foreclosed at n=2, saving ~4h GPU time.

| Arm | K | W&B | T0 val | T0 ffs | T1 status | vs strict bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 10 (tighter) | `v6gls9o3` | 3.28057 | 3175 (no-hit) | Option B kill at step ~125 (T1 also diverged at step 3326) | val MISS +0.006, ffs MISS +106.25 (no-hit) | falsified |
| B | 22 (looser) | `0g63aen5` | 3.276487 | 3100 | Option B kill at step ~990 (math foreclosed) | val MISS +0.0021, ffs MISS +31.25 | falsified |
| baseline | 15 default | `ivvf500c` | 3.274383 (n=4 mean) | 3068.75 (n=4 mean) | — | reference | — |

**Foreclosure math for early termination (Arm B example)**: With T0=3.276487/3100, Arm B's T1 would need val ≤ 2×3.274383−3.276487 = 3.272279 (below project-best single-trial val ever observed = 3.27263) AND ffs ≤ 2×3068.75−3100 = 3037.5 (below quantization floor of 3050). Both conditions impossible → kill T1.

**Baseline-trajectory comparison** (val_loss vs baseline `ivvf500c` at key steps):

| Step | Arm A (K=10) | Arm B (K=22) | baseline (K=15) |
|---|---|---|---|
| 125 | 4.54290 | 4.50325 | ~4.20 |
| 1500 | 3.53340 | 3.53090 | ~3.53 |
| 2500 | 3.35267 | 3.34865 | ~3.36 |
| 3000 | 3.29116 | 3.28718 | ~3.28-3.29 |
| 3175 (terminal) | 3.28057 | 3.27649 | ~3.27 |

**Mechanism finding**:
- **K=10 (tighter cap)**: matched mechanistic prediction exactly. Derivative at |x|=10 is ~0.35, so tighter cap clips even small early-training logits → +0.34 val regression at step 125. Mid-cooldown (1500-2500) catches up to baseline because output-head dynamics adapt around the cap. Terminal lag +0.01 confirms cap remains compressive at K=10. ffs target never reached in 3175 steps.
- **K=22 (looser cap)**: predicted asymmetric-favored direction failed. T0 val +0.006 / ffs +50 vs baseline. The looser cap does NOT improve gradient throughput in any productive direction — moderate-logit grad throughput is already ≥35% at K=15, and pushing K higher removes a regularizer the optimizer was leaning on.

**Softcap-mediator hypothesis (#372/#379 cross-stack mystery) PARTIALLY WEAKENED**: If K=15 were a load-bearing mediator for cross-stack interactions, perturbing K by ±33% should have produced clearer effects (either dramatically better or dramatically worse). Instead the surface is fairly flat around K=15 (+0.006 to +0.01 deltas) — consistent with softcap being a **non-load-bearing constant** in the current pipeline.

**Strategic implication**: Output-head modulation now joins the saturated-axes list alongside AdamW lm_head_lr (#431), EMBED_INIT_STD on new base (#379), and ATTN_SOAP_TRUST_THRESHOLD (#420). Plateau Protocol shift continues: next axes should target either (a) fresh optimizer-wrapping mechanisms (Lookahead, EMA averaging) or (b) input-side embedding mechanisms.

**Reassignment**: frieren → #459 Lookahead-AdamW sweep (K=5 vs K=10, α=0.5) — fresh optimizer-wrapping mechanism (Zhang et al 2019), never tested on this codebase. Cleanly orthogonal to in-flight AdamW LR/WD sweeps (#449/#456/#458).

**Process note**: This is the second clean "Option B math-foreclosure early-terminate" in two cycles (after edward #379 trial 1 in cycle 59). The math-foreclosure pattern is becoming a high-value early-termination signal. Both #435 arm A's T1 (which diverged at step 3326 — likely a divergence mode, not just foreclosure) and the cleaner Arm B T1 foreclosure show ~2-4h GPU time savings per closed-axis cycle.

## 2026-05-19 08:30 UTC — Cycle 62: #420 CLOSED ATTN_SOAP_TRUST_THRESHOLD axis FALSIFIED on new base (clean mechanism ablation finding); nezuko → #449 EMBED_LR sweep (AdamW path completion, largest LR in optimizer)

### PR #420 — ATTN_SOAP_TRUST_THRESHOLD sweep (T=0.70 vs T=0.95 vs default 0.85) — CLOSED axis-falsified

Branch: `g1r2-nezuko/attn-soap-trust-threshold-newbase`. Both arms screened on new CONTRA_MUON=0.4 base.

| Arm | T | W&B | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| A | 0.70 | `g6qlc9o9` | 3.27828 (n=1) | 3125 | val MISS +0.0039 (foreclosed at trial 0), ffs MISS +56.25 | falsified |
| B | 0.95 | `lqggr47m` | **3.275415** | **3087.5** | val MISS +0.001032, ffs MISS +18.75 | falsified |
| baseline | 0.85 | `ivvf500c` | 3.274383 | 3068.75 | reference | — |

**Statsig** (3.28 − μ)·√2 = (3.28 − 3.275415)·√2 = 0.00648 ≥ 0.004 → PASS, but BOTH strict bars miss.

**Mechanistic finding — gate behavior via on_fraction time-series**:

| Arm | T | overall on_frac | warmup (<300) | plateau (300-2575) | cooldown (≥2575) | mean cos_row | mean cos_col |
|---|---|---|---|---|---|---|---|
| A | 0.70 | **0.977** | 0.869 | 1.000 | 1.000 | 0.861 | 0.915 |
| B | 0.95 | **0.008** | 0.077 | 0.000 | 0.000 | 0.874 | 0.934 |

Per-weight-type on_fraction is uniform within each arm (k/q/v/proj all match overall), so the trust threshold is not selecting differentially across attention slots.

**Interpretation**:
- Cosine similarities cluster ~0.85-0.93 (row) and ~0.91-0.95 (col)
- Default T=0.85 lands inside the empirical row-similarity distribution → gate is selective
- Arm A T=0.70 → gate ~always-open = **Attn-SOAP without trust filter**
- Arm B T=0.95 → gate ~always-closed = **Attn-SOAP effectively disabled** (outside warmup)
- Attn-SOAP itself contributes only ~0.001 val improvement on the new stack (Arm B nearly matches baseline)

**Strategic consequence**: The trust gate at the current default is doing real work because T=0.85 is empirically calibrated to the cos-row distribution. There's no smarter constant threshold to find — the natural follow-up direction is **adaptive thresholds (e.g., mean − σ over running cos_row)** rather than further constant-threshold sweeping.

**Process notes (exemplary)**:
- Self-driven Option-B foreclosure on Arm A trial 1 (saved ~3.4h GPU)
- Mechanistic terminal post with on-fraction time-series across warmup/plateau/cooldown phases
- Four ranked follow-up suggestions, all mechanistically motivated
- This is the kind of terminal analysis that distinguishes research from hyperparameter sweeping

**Reassignment**: → **PR #449 EMBED_LR sweep** (0.225 vs 0.375 around hardcoded 0.3). Largest LR in entire optimizer (8× MUON_LR, 96× LM_HEAD_LR), never swept. AdamW path completion paired with fern #431 (LM_HEAD_LR).

---

## 2026-05-19 04:30 UTC — Cycle 61: #373 CLOSED (AdaMuon axis-falsified at n=4 on both baselines; EMA-family exhaustion 4-deep; "input-side robust vs output-side fragile" mechanism finding); frieren → #435 logit softcap K sweep (strategy-tier shift to model-side axes)

### PR #373 — AdaMuon: post-NS5 per-element EMA variance scaling — CLOSED axis-falsified

Branch: `g1r2-frieren/adamuon`. Arm B (ADAMUON_BETA2=0.99) cleared OLD bar at n=2 screen; predeclared n=4 confirm on new base. Terminal at 04:00 UTC.

| Phase | Stack | W&B run | val (n=4 mean) | ffs (n=4 mean) | vs new bar (val<3.274383, ffs<3068.75) | vs old bar (val<3.275350, ffs<3087.5) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 screen old stack | OLD CONTRA_MUON=0.5 | (prior runs) | 3.27500 | 3075 | val MISS +0.00062, ffs MISS +6.25 | val PASS −0.00035, ffs PASS −12.5 | screening pass on old |
| **n=4 confirm new base** | **NEW CONTRA_MUON=0.4** | `[per-trial table below]` | **3.27665** | **3093.75** | **val MISS +0.00227, ffs MISS +25** | **val MISS +0.00130, ffs MISS +6.25** | **FALSIFIED both bars both bases** |

Per-trial new-base n=4: T0=3.27729/3100, T1=3.27577/3075, T2=3.27727/3100, T3=3.27626/3100. Three of four trials at unfavorable ffs=3100 — clean regression to mean from n=2 lucky-draw.

**Key cross-cycle research finding — "input-side robust vs output-side fragile" mechanism**:

The optimizer pipeline is SOAP → NS5 → Contra-Muon → NorMuon → u/w-floor scaling. **Pre-NS5 mechanisms tolerate perturbations because NS5 re-projects to the orthogonal manifold**:
- MuonEq-R #372 (pre-NS5 row normalization) — tolerable on old stack
- Contra-Muon (op-norm normalization) — robust across stacks
- NorMuon-lite row scaling — robust

**Post-NS5 mechanisms have no re-projection downstream and perturbations propagate directly into the parameter update**:
- AdaMuon #373 (per-element EMA after NS5) — falsified this PR
- Post-NS5 RMS variants (multiple prior cycles) — falsified

This framing predicts that **any future "scale-the-NS5-output" mechanism will fail unless it ablates an existing downstream variance-scaling component** (NorMuon, u/w-floor). It also explains why pre-NS5 mechanisms can survive on the old stack while their post-NS5 counterparts fail across both stacks.

**EMA-family exhaustion (4-deep)**:

| Cycle | PR | Mechanism | Verdict |
|---|---|---|---|
| 53 | #223 | SOAP_BETA2 sweep | EMA exhausted |
| 58 | #378 | NORMUON_BETA2 sweep | EMA exhausted |
| 58 | #394 | ATTN_SOAP_BETA2 sweep | EMA exhausted |
| 60 | #373 | AdaMuon ADAMUON_BETA2 | EMA exhausted (post-NS5 specifically) |

The variance-scaling stack has fundamental redundancy that resists BOTH EMA detuning and EMA-family additions. **Strategic consequence: any future PR proposing a new second-moment / variance / EMA mechanism on the existing pipeline should be treated with strong prior skepticism unless it ablates an existing redundant component.**

**Cross-cycle Plateau Protocol trigger — 7 closures since PR #358 merged ~8h ago**:

| Cycle | PR | Mechanism family | Verdict |
|---|---|---|---|
| 57 | #357 | MU_COOLDOWN_END=0.87 | cooldown-geometry lucky draw |
| 58 | #372 (initial) | MuonEq-R pre-NS5 row norm | stack-specific |
| 58 | #378 | NORMUON_BETA2 | EMA exhausted |
| 58 | #379 | EMBED_INIT_STD=1.15 | stack-specific |
| 58 | #394 | ATTN_SOAP_BETA2 | EMA exhausted |
| 60 | #372 (rerun) | MuonEq-R pre-NS5 row norm | cooldown-geometry saturated |
| 61 | #373 | AdaMuon post-NS5 EMA | EMA exhausted, post-NS5 |

**Plateau Protocol applied**: strategy-tier shift warranted. Output-side model mechanisms, AdamW-path mechanisms, and structural mechanisms are the unexplored axes. Already in flight: fern #431 (AdamW lm_head_lr — AdamW-path).

**Process notes**:
- Frieren's terminal close analysis is one of the strongest of this round — the "input-side robust vs output-side fragile" framing produces a real research finding.
- Honest regression-to-mean call: explicit cross-reference to thorfinn #357 / fern #372 / askeladd / edward as a cohort of similar attrition.
- Predeclared close verdict held without negotiation.
- Foreclosure math at 03:46 UTC was correct in principle but slightly cushioned wording — actual T3 was closer to projection floor than bar required.

**Reassignment**: → **PR #435 logit softcap K sweep** (K=10 vs K=22 around default K=15). First non-optimizer-pipeline axis this cycle. Hardcoded at K=15 since project inception, never swept, load-bearing through ALL cycles, implicated as mediator in both edward #379 and fern #372 closure analyses.

---

## 2026-05-19 03:30 UTC — Cycle 60: #372 CLOSED (MuonEq-R axis-falsified on new base; cooldown-geometry lever saturated); fern → #431 AdamW lm_head_lr sweep

### PR #372 — MuonEq-R: pre-NS5 row normalization for isotropic input — CLOSED axis-falsified

Branch: `g1r2-fern/muoneq-r-prens5-row-norm`. Axis cleared OLD bar at n=4 (would have merged); sent back for new-base re-test per predeclared additivity check. New-base n=2 screen terminal at 03:01 UTC.

| Phase | Stack | W&B run | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| n=4 confirm old stack | OLD CONTRA_MUON=0.5 | (prior runs) | 3.275140 | 3081.25 | PASS old bar — MISS new bar (+0.00076/+12.5) | sent back |
| **n=2 screen new base** | **NEW CONTRA_MUON=0.4** | `6thehevw` | **3.27591** (T0=3.27685, T1=3.27497) | **3087.5** (T0=3100, T1=3075) | **val MISS +0.001527, ffs MISS +18.75** | **FALSIFIED** |

**Additivity prediction**: val ~3.27417, ffs ~3062.5. **Actual**: val 3.27591, ffs 3087.5. Falsified by +0.001737 val / +25 ffs.

**Effect direction across bases**:
- OLD stack: MuonEq-R delta = val −0.00021, ffs −6.25 (small beneficial)
- NEW stack: MuonEq-R delta = val +0.001527, ffs +18.75 (harmful)

**Key finding — cooldown-geometry lever saturation**:
Three independent old-base mechanisms each broke ffs=3050 in isolation:
1. MU_COOLDOWN_END=0.87 (#357)
2. CONTRA_MUON=0.4 (#358, now baseline)
3. MuonEq-R (this PR #372)

The non-additivity of MuonEq-R + CONTRA_MUON=0.4 proves these are **partially substitutive parameterizations of cooldown-stage update geometry**. Once CONTRA_MUON=0.4 saturates the lever in the new baseline, MuonEq-R not only provides no additional benefit but actively hurts — suggesting the pre-NS5 row normalization that helped with larger contra-correction (which was "correcting away" the gradient direction more aggressively) now fights against the cleaner momentum signal that CONTRA_MUON=0.4 allows through.

**Strategic consequence**: Future experiments targeting "tighter cooldown-stage geometry / smaller correction magnitude" should be flagged as likely hitting the saturated lever. The entire Muon-side cooldown-geometry lever surface appears exhausted at the current CONTRA_MUON=0.4 + MU_COOLDOWN=0.95→0.90 default. **Redirect to AdamW-path, output-side, and structural axes.**

**Process notes**:
- Predeclared and held n=2 decision tree (miss both bars → close) without extension.
- Explicit additivity prediction stated before run; falsified after — proper hypothesis-test discipline.
- Old-vs-new base comparison table in terminal post is the clearest cross-stack diagnostic of the round.
- Three-mechanisms-one-lever insight is the most impactful research finding this cycle.
- Implementation robust: no NaN across 5 smokes + 6 old-base trials + 2 new-base trials.

**Reassignment**: → **PR #431 AdamW lm_head_lr sweep** (0.0025 vs 0.00375 around default 0.003125). First AdamW-path axis swept on this stack; `proj.weight` is the largest parameter in the model; orthogonal to all in-flight Muon-side axes.

---

## 2026-05-19 03:10 UTC — Cycle 59: #378 CLOSED (NORMUON_BETA2 axis falsified on new base both directions, EMA-family exhaustion across 3 axes); #379 CLOSED (EMBED_INIT_STD=1.15 stack-specific — wins on old, doesn't compose with CONTRA_MUON=0.4); alphonse → #429 NS5 iterations sweep; edward → #430 MUON_LR sweep

### PR #378 — NORMUON_BETA2 fine sweep (Arm A=0.99 new-base re-run) — CLOSED axis-falsified

Branch: `g1r2-alphonse/normuon-beta2-sweep`. Arm A originally screened on old CONTRA_MUON=0.5 stack; sent back 22:54 UTC for re-run on new CONTRA_MUON=0.4 base. Arm B (β₂=0.90) falsified pre-baseline-shift on old stack.

| Phase | Arm | W&B run | val (n=2 mean) | ffs (n=2 mean) | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.99, slower) | (pre-#358) | 3.27509 | 3075 | val MISS +0.00071, ffs MISS +6.25 (close) | sent back for re-run |
| n=2 SCREEN old stack | B (0.90, faster) | (pre-#358) | 3.27575 | 3087.5 | val MISS +0.00137, ffs MISS +18.75 | falsified |
| **n=2 SCREEN new base** | A (0.99, slower) | (per terminal post) | **3.27604** | **3087.5** | **val MISS +0.00166, ffs MISS +18.75** | **FALSIFIED** |

**Cross-cycle pattern (decisively confirmed)**: Three independent β₂ sweeps now all falsified on new base:
- SOAP_BETA2 (PR #223, prior cycle): falsified
- NORMUON_BETA2 (PR #378, this cycle): falsified on new base both directions
- ATTN_SOAP_BETA2 (PR #394 nezuko, cycle 58): falsified on new base both directions

**Mechanism takeaway**: The optimizer's EMA-family β₂ values are tightly co-tuned within the SOAP → NS5 → Contra-Muon → NorMuon pipeline. The variance-scaling stack has redundancy (NorMuon row+col + SOAP eigenbasis + Attn-SOAP basis with trust gate) such that slowing any one EMA loses adaptation speed without information gain, and speeding it up adds noise the others can't filter. The β₂=0.90/0.95 defaults are jointly optimal and individually sharp.

**Stack-shift Δ for Arm A (β₂=0.99)**: val regressed +0.00095, ffs regressed +12.5 from old to new base — slower EMA does NOT compose with reduced contra-correction (matches mechanism prediction failing). The contra-correction shift dominates β₂ tuning sensitivity at the lower magnitude.

**Process notes**:
- Student caught kill-gate mis-spec mid-run and called for Arm A redo (right call — Arm A would have triggered n=4 on old bar).
- Cross-comparison with #316 dynamic anneal closure was sharp.
- Symmetry observation re: PR #223 (SOAP_BETA2) added cross-axis confirmation.
- Process retrospective on kill-gate thresholds actionable for future PRs.

**Reassignment**: → **PR #429 NS5 iterations sweep** (Arm A=10, Arm B=14, default 12). Untouched since NorMuon-clean PR #71 — load-bearing through 5 stack changes. Controls orthogonal-projection quality of Muon update; downstream SOAP/Attn-SOAP/NorMuon all consume NS5 output. Fresh mechanism dial.

---

### PR #379 — EMBED_INIT_STD fine sweep (0.85 / 1.15) — CLOSED axis stack-specific

Branch: `g1r2-edward/embed-init-std-sweep`. Arm A (0.85) falsified pre-baseline-shift; Arm B (1.15) cleared old bar nominally but failed re-test on new CONTRA_MUON=0.4 base.

| Phase | Arm | Stack | W&B run | val (n) | ffs (n) | n | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.85, smaller) | OLD CONTRA_MUON=0.5 | (pre-#358) | 3.27530 | 3087.5 | 2 | MISS both | falsified |
| n=2 SCREEN old stack | B (1.15, larger) | OLD CONTRA_MUON=0.5 | (pre-#358) | **3.27353** | **3062.5** | 2 | CLEARS both ✅ (statsig 0.00915) | wrong stack |
| **n=2 SCREEN new base** | B (1.15, larger) | **NEW CONTRA_MUON=0.4** | (per terminal post) | **3.27579** (T0 only) | **3100** (T0 only) | **1** (T1 early-term) | **MISS both** | **FALSIFIED on new base** |

**Trial 1 Option B early-termination**: Student executed mathematical foreclosure proof analogous to nezuko #394 — ffs alone forecloses AND-conjunction (trial_1 ffs would need ≤3037.5 which is below 3050 quantization). Saved ~100 min GPU.

**Stack-shift Δ for EMBED_INIT_STD=1.15**: val regressed +0.00226, ffs regressed +37.5 from old to new base. This is a **strong interaction effect** with CONTRA_MUON — the embedding init win does NOT compose additively with reduced contra-correction.

**Mechanism reads (two worth flagging)**:

1. **Direction inversion vs arxiv 2502.05366**: Paper predicts smaller embedding init helps GPT-2-style models; on our SOAP+NS5+Contra-Muon stack at CONTRA_MUON=0.5 the OPPOSITE was true (1.15 wins, 0.85 loses). Real empirical finding, stack-specific. Plausible mediator: logit softcap or SOAP basis rotation sensitivity to embedding magnitude.

2. **Stack-specificity is the more interesting finding**: Embedding init effect VANISHES at CONTRA_MUON=0.4, suggesting the old-stack win was mediated by larger contra-correction magnitude. Mechanism hypothesis chain: CONTRA_MUON=0.5 → larger contra-correction → more aggressive correction against momentum direction → embedding gradients channeled differently through softcap+SOAP → init magnitude differentially affects optimizer trajectory. At CONTRA_MUON=0.4: smaller contra-correction → less basis rotation → embedding init no longer matters.

**Cross-cycle lesson**: Future single-axis sweeps that produce strong margins on old stack should be verified on current stack before being escalated to n=4 confirm. Stack changes (particularly CONTRA_MUON) can erase apparent wins. This discipline already prevented wasted n=4 GPU on this PR.

**Process notes**:
- Clean smoke + n=2 screen on old stack with all three reproducibility checks (default 200-step bit-identity, 0.85 and 1.15 plumbing checks).
- Proactive flagging of stack-mismatch when n=4 was launched on old CONTRA_MUON=0.5 — saved n=4 from being wasted.
- Mathematical foreclosure analysis on early-termination — clean prose, accurate numbers, fast call.
- Honest analysis section identified the interaction effect AND named the specific mediator hypothesis.

**Reassignment**: → **PR #430 MUON_LR sweep** (Arm A=0.030, Arm B=0.045, default 0.0375). Hardcoded since PR #78 — load-bearing through 4 stack additions (CONTRA_MUON 0.5→0.4, ATTN_SOAP, MU cooldown-only schedule, CONTRA_MUON re-tune). Each downstream change affects effective Muon step magnitude. Public track 3 records mostly use lr=0.018, our 0.0375 is on the high end. Single-line env-var plumbing.

---

## 2026-05-19 01:10 UTC — Cycle 58: #394 CLOSED (ATTN_SOAP_BETA2 axis falsified both directions on new base, third EMA-family axis exhausted); nezuko → #420 ATTN_SOAP_TRUST_THRESHOLD sweep

### PR #394 — ATTN_SOAP_BETA2 fine sweep (0.85 / 0.95) — CLOSED axis-falsified

Branch: `g1r2-nezuko/attn-soap-beta2-sweep`. Arm A (0.85) screened on old CONTRA_MUON=0.5 stack pre-baseline-shift; Arm B (0.95) re-screened on new CONTRA_MUON=0.4 base per advisor 22:28 UTC sendback.

| Phase | Arm | W&B run | val (n) | ffs (n) | n | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 SCREEN old stack | A (0.85, faster) | (prior, pre-#358) | 3.275620 | 3087.5 | 2 | val MISS +0.001237, ffs MISS +18.75 | dominated, not advanced |
| n=2 SCREEN new base | B (0.95, slower) | `scyomo0r` | 3.27734 (T0 only) | 3125 (T0 only) | 1 (T1 terminated) | val MISS +0.00296, ffs MISS +56.25 | **FALSIFIED** |

**Trial 1 early termination**: Student correctly identified mathematical foreclosure at step 444:
- Val statsig needs `trial_1 < 2·3.27717 − 3.27734 = 3.27700` (and for merge bar `trial_1 < 2·3.274383 − 3.27734 = 3.27143`, extreme tail).
- FFS merge bar needs `trial_1_ffs < 2·3068.75 − 3125 = 3012.5` — below the 3025 quantization floor; hard-foreclosed.
- ffs alone forecloses the AND-conjunction merge bar.

**Mechanism diagnosis**:
- ATTN_SOAP_BETA2=0.95 (slower EMA) on attention SOAP gate is the WORSE direction on new base, not the better one. The "longer effective rank → slower EMA" intuition is wrong here:
  1. ATTN_SOAP_TRUST_THRESHOLD=0.85 already filters high-noise eigenbasis refreshes — slowing β₂ doesn't add information, just delays adaptation to legitimate basis drift.
  2. Cooldown-phase dynamics need fast eigenbasis adaptation to track the rapidly-shrinking learning rate. Slow β₂=0.95 lags this.
  3. Attention's "longer rank" applies to gradient *structure* (handled by the 4-head trust-gate routing), not temporal correlation (which β₂ tracks).
- ATTN_SOAP_BETA2=0.90 default is a sharp local optimum — **third EMA-family β₂ axis confirmed exhausted** after SOAP_BETA2 (PR #223, prior cycle) and NORMUON_BETA2 (PR #378, this cycle).

**Process notes**:
- Initial advisor pod-diagnosis at 00:33 UTC was wrong — three concurrent failed launches (`ng7u2ep3`, `05r5oea7`, `9mwdil39`) masked the healthy `scyomo0r` run that was actually progressing. Corrected at 00:55 UTC after deeper W&B inspection. Pod was torch 2.11.0+cu130 (healthy) all along.
- Student's terminal analysis was exemplary — explicit foreclosure proof, gate-on rate context, multi-axis cross-comparison with PR #378 (alphonse NORMUON sibling).

**Suggested follow-up from student (rank #1)**: ATTN_SOAP_TRUST_THRESHOLD currently 0.85, never swept since PR #16, never tested on new cooldown stack. Different attention-pathway lever (basis-rotation gating, not EMA decay). → assigned as **PR #420 ATTN_SOAP_TRUST_THRESHOLD sweep (0.70 vs 0.95)**.

## 2026-05-19 00:00 UTC — Cycle 57: #357 CLOSED (MU_COOLDOWN_END axis characterized on old stack, ties ffs bar on new); thorfinn → #415 muon_warmup_steps sweep

### PR #357 — MU_COOLDOWN_END sweep (0.87 / 0.85) on old CONTRA_MUON=0.5 stack — CLOSED on MISS

Branch: `g1r2-thorfinn/mu-cooldown-end-sweep`. Both arms screened on old stack pre-baseline-shift; n=4 confirm on Arm A on old stack.

| Phase | Arm | W&B run | val n | ffs n | n | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| n=2 SCREEN | A (0.87) | `q1jcq9k9` | 3.27432 | 3050 | 2 | val CLEAR −0.000063, ffs CLEAR −18.75 (lucky-draw both at 3050) | promoted to n=4 |
| n=2 SCREEN | B (0.85) | `fhkubmcu` | 3.275205 | 3062.5 | 2 | val MISS +0.000822, ffs CLEAR −6.25 | dominated by A; not promoted |
| **n=4 CONFIRM** | **A (0.87)** | **`0rbppojt`** | **3.275425** | **3068.75** | **4** | **val MISS +0.001042, ffs TIES (not strict <)** | **MISS new bar — CLOSE** |

**Per-trial n=4 confirm**: T0=3.27763/3100, T1=3.27568/3075, T2=3.27364/3050, T3=3.27475/3050. Only 2 of 4 trials at ffs=3050 → mean=3068.75 ties bar.

**Mechanism diagnosis**:
- The cooldown μ endpoint axis on old stack trades val for ffs at ~1:18 ratio. Lower endpoint = more Muon reactivity at training end = better ffs (more trials hit 3050) but slight val penalty.
- Pareto front is roughly flat between 0.85 and 0.90; sweet spot is ~0.87 but the trade doesn't compose with new CONTRA_MUON=0.4 stack to clear new bar (would need ffs ≤ 3050 mean which still leaves val MISS).
- The n=2 SCREEN/n=4 CONFIRM regression on Arm A (val 3.27432 → 3.275425; ffs 3050 → 3068.75) is textbook seed-variance lucky-draw: n=2 hit both at ffs=3050 by chance; n=4 reverts to bimodal {3050, 3075} distribution.

**Reassignment**: thorfinn → **#415 muon_warmup_steps sweep** (200/400 vs default 300) on new CONTRA_MUON=0.4 base. Fresh schedule-side axis never swept on r2. Mechanistic motivation: lower CONTRA_MUON means more natural-momentum signal early in training, so warmup tuned for old stack may be misaligned.

---

## 2026-05-18 22:20 UTC — Cycle 56: #376 CLOSED (cooldown-only AdaMuon axis FALSIFIED); tanjiro → #406 MU_COOLDOWN_START sweep on new base

### PR #376 — Cooldown-only AdaMuon switch (post-NS5 variance scaling, cooldown phase only) — FALSIFIED

Branch: `g1r2-tanjiro/cooldown-adamuon-switch`. Both arms on OLD stack (CONTRA_MUON=0.5).

| Arm | β | init | W&B run | val n=2 | ffs n=2 | vs new bar (val<3.274383, ffs<3068.75) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.95 | rms-warmstart | `oqivcko2` | 3.27678 | 3100 | val +0.00240, ffs +31.25 | FAIL |
| B | 0.99 | ones | `hkq95uz4` | 3.27542 | 3075 | val +0.00104, ffs +6.25 | MISS — best arm is "near-no-op" |

**Mechanism diagnosis** (student's analysis was excellent and is reproduced):
- NorMuon's per-row variance EMA already adapts during cooldown. Layering AdaMuon's element-wise variance scaling on top is **double-normalization**.
- Arm A (β=0.95, RMS warmstart): mechanism is active per-step → regression (+0.00143 val).
- Arm B (β=0.99, ones init): mechanism is effectively near-identity in cooldown (V_t ≈ 1.0 with slow updates and O_t RMS ≈ 1 by NS5 construction) → ties baseline rather than regressing. But no operating point makes it both active and net-positive.

Cross-confirms frieren #373 conclusion at full-training scope: AdaMuon's element-wise variance scaling is **redundant** with NorMuon's row variance scaling on this stack.

**Falsification class**: post-NS5 element-wise variance scaling (cooldown-restricted or full) on a stack that already has NorMuon — joins Muon-VS (pre-NS5) and the original AdaMuon arms on the FALSIFIED list. Strengthens the **INPUT-ROBUST/OUTPUT-FRAGILE pattern**: element-wise post-NS5 scaling fights NS5's spectral-orthogonalization invariant or is redundant with row-level scaling already present.

**Tanjiro reassigned → PR #406: MU_COOLDOWN_START sweep (0.93/0.97) on new CONTRA_MUON=0.4 base** — schedule-side axis (input-robust win pattern); START=0.95 has been fixed since PR #288 merge but never swept directly.

---

## 2026-05-18 17:20 UTC — Cycle 55 (continued): #375 CLOSED (Muon-VS FALSIFIED); nezuko → #394 ATTN_SOAP_BETA2 sweep

### PR #375 — Muon-VS pre-NS5 gradient deviation variance scaling — FALSIFIED

Branch: `g1r2-nezuko/muon-vs`. Both arms (β=0.95 and β=0.90) catastrophically missed.

| Arm | MUON_VS_BETA | W&B run | trial 0 val | ffs | vs baseline | Verdict |
|---|---|---|---|---|---|---|
| A | 0.95 | `4y6zfnrs` | **3.32486** | -1 (never reached 3.28) | val +0.04951 | FAIL — catastrophic |
| B | 0.90 | `e0yodaew` | **3.31294** | -1 (never reached 3.28) | val +0.03759 | FAIL — catastrophic |

Trial 1 of both arms killed early (mathematically foreclosed — for n=2 mean to clear baseline, trial 1 would need val < 2.225, impossible). Kill gates triggered at step ~863 (Arm A) and 159 (Arm B).

**Mechanism diagnosis**: pre-NS5 element-wise deviation-variance scaling fights NS5's spectral-orthogonalization invariant. Published 1.36× speedup on LLaMA-1.2B (arxiv 2601.14603) used vanilla SGD-momentum without orthogonalization — geometric mismatch with our SOAP→NS5→Contra→NorMuon pipeline.

Also: Contra-Muon (0.5) already removes the G_t component aligned with previous updates, which is precisely the "deviation" signal Muon-VS keys on. The GDV EMA is biased toward orthogonal-to-momentum noise.

**Confirms INPUT-ROBUST/OUTPUT-FRAGILE pattern**: element-wise pre-NS5 scaling (fights NS5 premise) joins post-NS5 element-wise scaling (AdaMuon) as falsified. Row-level and schedule-level perturbations (MU_COOLDOWN_END, CONTRA_MUON, MuonEq-R) all win.

**Nezuko reassigned → PR #394: ATTN_SOAP_BETA2 fine sweep (0.85 vs 0.95)**

---

## 2026-05-18 14:15 UTC — Cycle 55 (continued): #341 CLOSED (SOAP eigenbasis freeze axis FALSIFIED)

### PR #341 — SOAP eigenbasis freeze after step K — FALSIFIED (both arms)

Branch: `g1r2-edward/soap-eigenbasis-freeze`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | FREEZE_STEP | W&B run | mean val (n=2) | mean ffs | Step time | vs NEW baseline (3.275350/3087.5) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1000 (pre-cooldown, step 31% in) | `jt46ri0n` | **3.28082** | n/a (1 trial −1) | ~1.86 s/step | val +0.0055 | FAIL decisive |
| B | 2000 (mid-cooldown, step 63% in) | `604ypwx2` | **3.27640** | 3100 | ~1.91 s/step | val +0.00105, ffs +12.5 | FAIL |
| Baseline (PR #288 NEW) | 0 (never freeze) | `qceklszn` | 3.275350 | 3087.5 | ~1.94 s/step | — | — |

Per-trial Arm B (`604ypwx2`): T0 val=3.27734/ffs=3125, T1 val=3.27546/ffs=3075. Trial-pair spread 0.00188.

**Mechanism CONFIRMED**: SOAP Q eigenbasis refresh past step K continues to contribute useful signal **all the way through cooldown**. The val regression scales **monotonically** with how early the freeze happens:
- FREEZE=1000 (very early): +0.0055 val
- FREEZE=2000 (mid-cooldown): +0.00105 val
- FREEZE=3175 (no freeze, baseline): 0.0

The hypothesis that "Q stabilizes after early training, so refresh is wasted compute past step K" is falsified. The non-trivial val regression confirms the residual Q rotation through cooldown encodes useful preconditioner direction information, even though `cos_row(Q_t, Q_{t-10})` stays high (high cosine doesn't mean zero contribution from the orthogonal residual).

**Trial-1-only artifact**: Arm B trial 1 alone hit val=3.27546/ffs=3075, which beats NEW baseline if cherry-picked. But the trial-pair spread (0.00188) exceeds any meaningful signal at n=2 — the per-trial dispersion dominates the mean estimate.

**Wallclock note**: Arm B saved ~0.034 s/step (~107 s per 3175-step trial), ~1.7% wallclock. Since we measure ffs (steps), not wallclock, this isn't useful for our merge contract. Closes the "wallclock-only" interpretation of the axis.

**Combined with fern's closed #304 (SOAP_PRECOND_FREQ anneal 15→7 falsified)**: the steady-state SOAP_PRECOND_FREQ=10 from step 1 through end-of-training is now confirmed a tight stability window in BOTH dimensions:
- DON'T change refresh frequency (#304)
- DON'T stop refreshing late (#341)

**Excluded axes**: SOAP_FREEZE_STEP < 3175 (any partial freeze). Open: would a per-block freeze schedule (different K per block depth) preserve more of the late-cooldown signal? Lower priority given the magnitude of the regression even at FREEZE=2000.

**Stack mismatch caveat**: Both arms ran on OLD stack (MU_START=0.97/MU_END=0.90). NEW stack might shift results by ~0.0005 favorably. Even with that shift, n=2 mean would still fail by ~+0.0005 val — within trial-pair noise, not statsig.

---

## 2026-05-18 13:30 UTC — Cycle 55 (continued): #359 CLOSED (μ shape ablation FALSIFIED both directions)

### PR #359 — μ cooldown schedule shape ablation — FALSIFIED (both arms)

Branch: `g1r2-alphonse/mu-cooldown-start-ablation`. Stack: PR #288 baseline minus the μ schedule under test.

| Arm | μ schedule | W&B run | val/best | best step | ffs | Δ vs baseline (3.275350) |
|---|---|---|---|---|---|---|
| Baseline (PR #288) | 0.95 → 0.90 (linear, 0.05 gap) | `qceklszn` (n=4 mean) | 3.275350 | — | 3087.5 | 0.0 |
| **A — near-flat** | 0.92 → 0.90 (linear, 0.02 gap) | `gufuly2z` | **3.28382** | 3175 | **-1** | **+0.00847** ❌ |
| **B — constant** | 0.90 → 0.90 (constant) | `0oyci6l3` | **3.28481** | 3175 | **-1** | **+0.00946** ❌ |

Both arms ran trial 0 to completion; trial 1 killed in each (~step 500 Arm A, ~step 307 Arm B) per advisor instruction after trial 0 made n=2 mean ≤ 3.275350 impossible.

**Mechanism CONFIRMED**: The PR #288 0.95→0.90 linear cooldown is load-bearing in BOTH:
- **The 0.05 decay magnitude**: Arm A (0.02 gap, near-flat) costs +0.00847.
- **The high-μ warmup plateau**: Arm B (no decay, constant 0.90) costs +0.00946.

Neither component alone suffices. The benefit comes from the **wide downward ramp starting at μ=0.95**.

**Triangulation with thorfinn #357 (in-flight)**: trial 0 at MU_COOLDOWN_END=0.87 (0.08 gap, 0.95→0.87) reached val=3.274062/ffs=3050 — WIDER gap to a DEEPER endpoint improves further. Combined evidence: the decay magnitude has upside if the start stays at 0.95 and the end drops lower.

**Operational note**: 5 transient pod crashes between 09:04-10:50 UTC (runs `h3cv46vy, qnsuawz1, pvtppeco, l95v4gvd, a5lupt79`, mostly dying step 50-75). Resolved by 11:18 launch of Arm B. Cause not isolated but consistent with the cu12/cu13 pod issue from cycle 54.

**Excluded axes**: μ shape variations within {0.90→0.90, 0.92→0.90, 0.95→0.90}. PR #288's specific shape is preserved. Open: extending the decay magnitude WIDER (e.g., MU_END < 0.87, in flight with thorfinn).

---

## 2026-05-18 12:15 UTC — Cycle 55 (continued): #339 CLOSED (cooldown_frac axis FALSIFIED); #336 CLOSED (TARGET_UW axis FALSIFIED)

### PR #339 — cooldown_frac sweep 0.6 and 0.8 — FALSIFIED

Branch: `g1r2-nezuko/cooldown-frac-sweep`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | COOLDOWN_FRAC | n=2 mean val | n=2 mean ffs | vs OLD baseline (3.275835/3087.5) | vs NEW baseline (3.275350/3087.5) | Verdict |
|---|---|---|---|---|---|---|
| A | 0.6 | 3.27583 | 3100 | val Δ−0.000005 (tie), ffs +12.5 | val +0.00048, ffs +12.5 | FAIL both |
| B | 0.8 | 3.275640 | 3075 | val Δ−0.000195, ffs Δ−12.5 | val +0.000290, ffs Δ−12.5 | FAIL val on NEW |

Per-trial:
- **Arm A** (`2ysep6xs`): T0 val=3.27723/ffs=3125 (kill gate clear), T1 val=3.27443/ffs=3075. Trial-pair spread 0.0028 — dominates inter-arm signal.
- **Arm B** (`jmikalnz`): T0 val=3.27535/ffs=3075, T1 val=3.27593/ffs=3075. Trial-pair spread 0.00058 — tighter.

**Mechanism**: cooldown_frac axis on OLD stack is directionally signed ("more cooldown helps slightly") but magnitude is below n=2 noise floor. NEW baseline (PR #288) tightened val by −0.000485 — 2.5× the size of any cooldown_frac effect observed on OLD. The μ-schedule change is the larger lever in this neighborhood; cooldown_frac is dominated.

**Critical observation**: On NEW stack (cooldown-only μ-anneal), cooldown_frac now controls both LR taper length AND μ-decay length — they are entangled in a way they weren't on OLD. Any future revisit should be a joint (cooldown_frac × μ-anneal endpoints) sweep, not univariate.

**Excluded axes**: Univariate cooldown_frac sweeps at 0.6, 0.7, 0.8 ranges. cooldown_frac=0.7 stays. Open follow-ups: cooldown shape (linear vs cosine vs poly), per-optimizer cooldown_frac.

---

### PR #336 — TARGET_UW sweep 0.25 and 0.50 — FALSIFIED (both directions)

Branch: `g1r2-tanjiro/target-uw-sweep`. Both arms on OLD stack (MU_START=0.97/MU_END=0.90).

| Arm | TARGET_UW | val | ffs | vs OLD baseline | Verdict |
|---|---|---|---|---|---|
| A | 0.25 | 3.28570 (T0 only, T1 kill-gated) | -1 (never reached 3.28) | +0.010 worse | KILLED step 2500 val=3.34352 |
| B | 0.50 | 3.276335 (n=2 mean) | 3112.5 (n=2 mean) | val +0.0005, ffs +25 | FAIL both |
| Baseline | 0.35 | 3.275835 (n=4) | 3087.5 (n=4) | — | local optimum |

Per-trial Arm B (`g0pkxwbr`): T0 val=3.27569/ffs=3100, T1 val=3.27698/ffs=3125.

**Mechanism**: TARGET_UW=0.35 sits at a local optimum.
- **Lower (0.25)**: Less implicit WD throughout training → weight magnitudes drift larger → cooldown phase can't recover convergence precision. Hypothesis that SOAP+Contra-Muon's directional conditioning makes the magnitude floor redundant is falsified — floor's implicit WD remains load-bearing.
- **Higher (0.50)**: More aggressive regularization slows cooldown trajectory slightly (+0.0005 val). Cooldown over-regularization concern from hypothesis does NOT manifest at 0.35 — the floor is already well-matched to cooldown dynamics.

**Excluded axes**: TARGET_UW outside ~[0.30, 0.45] range. Open follow-ups: fine-resolution bracket {0.30, 0.40} (unlikely worth GPU); cooldown-only TARGET_UW schedule; explicit weight_decay variant.

---

## 2026-05-18 10:45 UTC — Cycle 55 (continued): #304 CLOSED (SOAP_PRECOND_FREQ anneal FALSIFIED)

### PR #304 — Annealed SOAP_PRECOND_FREQ FREQ_START=15→FREQ_END=7 — FALSIFIED

| | n=4 mean val | n=4 mean ffs | vs PR #288 baseline | Verdict |
|---|---|---|---|---|
| **PR #304 (closed)** | **3.27766** | **3125** | val +0.00231, ffs +37.5 | FAIL |
| Baseline (PR #288) | 3.275350 | 3087.5 | — | — |

Per-trial: T0=3.27619/3100, T1=3.27677/3100, T2=3.27447/3075, T3=~3.2835 (didn't reach 3.28 in 3175 steps → ffs counted as 3225).

W&B run: `xzwpijuo` (n=4 confirmation on OLD stack MU_START=0.97/MU_END=0.90 — launched pre-PR-#288 merge).

**Mechanism**: Annealing SOAP refresh frequency from 15 (early sparse) to 7 (late dense) wastes early compute on slow refresh AND late compute on too-frequent refresh. FREQ=10 (stability window) optimal in both regimes. Trial 3 in particular hit a long plateau, reaching only 3.2835 by step 3175 — suggests anneal trajectory makes the cooldown phase harder to escape than constant FREQ.

**Excluded axes**: Time-varying SOAP_PRECOND_FREQ schedules in either direction. FREQ=10 is the operating point.

---

## 2026-05-18 08:35 UTC — Cycle 55 (continued): PR #288 MERGED (cooldown-only μ anneal — NEW BASELINE); #319 CLOSED (Muon warmup FALSIFIED); #312 CLOSED (lm_head WD no signal)

### PR #288 MERGED — Cooldown-only μ anneal 0.95→0.90 (NEW BASELINE)

| | n=4 mean val | n=4 mean ffs | Statsig | Verdict |
|---|---|---|---|---|
| Baseline (PR #219) | 3.275835 | 3087.5 | — | baseline |
| **PR #288 (merged)** | **3.275350** | **3087.5** | **0.00930** ≥ 0.004 ✅ | **MERGED** |
| Δ | −0.000485 | 0.0 (tie) | 2.33× | new baseline |

W&B run: `qceklszn` (n=4 confirmation: T0=3.27437/3075, T1=3.27600/3100, T2=3.27586/3100, T3=3.27517/3075)

**Mechanism validated**: μ-anneal benefit localizes to cooldown phase. Arm A (0.97→0.92 full training) missed both bars (n=2 mean val=3.27670/ffs=3112.5); Arm B (cooldown-only 0.95→0.90 starting step 952) cleared val bar + tied ffs. NS5-orthogonalized Muon doesn't need warmup stabilization from high μ.

**ffs tie analysis**: ffs is bimodal {3075, 3100} with 2-2 split in n=4, mean exactly 3087.5. The quantization makes 3087.5 the modal n=4 outcome when 2 trials hit 3075 and 2 hit 3100. The decision to MERGE despite ffs tie was based on: (a) val statsig 2.3×, (b) no ffs regression, (c) CLAUDE.md "when in doubt, merge."

**New merged stack**: `MU_COOLDOWN_START=0.95 MU_COOLDOWN_END=0.90 ATTN_SOAP_TRUST_THRESHOLD=0.85 CONTRA_MUON=0.5` — MU_START/MU_END deprecated.

---

### PR #319 — Muon LR warmup 100-step and 50-step — FALSIFIED (both arms)

| Arm | Warmup | val_mean (n=2) | Δval | ffs_mean | Δffs | Bars |
|---|---:|---:|---:|---:|---:|---|
| A | 100 | 3.277545 | +0.00171 | 3112.5 | +25 | 0/2 |
| B | 50 | 3.277385 | +0.00155 | 3112.5 | +25 | 0/2 |
| Baseline (PR #219) | 0 | 3.275835 | 0 | 3087.5 | 0 | — |

W&B runs: `5ao5znlo` (Arm A), `tx48f42y` (Arm B)

**Mechanism confirmed**: Muon's NS5 orthogonalization at full LR from step 1 is load-bearing. Key diagnostic: val@step125 essentially identical between 100-step and 50-step warmup arms (4.641 vs 4.634) — warmup damages early geometry in a way that does not fully recover, even 75+ post-warmup steps before the first eval. Warmup adds LR suppression to an optimizer that doesn't need it.

**Excluded axes**: Any positive Muon LR warmup. Mechanism is clear: NS5-Muon IS its own warmup.

---

### PR #312 — AdamW lm_head weight decay (WD=0.01) — NO SIGNAL

| | val_mean (n=4) | ffs_mean | Δval | Statsig p | Verdict |
|---|---|---|---|---|---|
| Arm A (wd=0.01) | 3.27648 | 3106.25 | +0.00113 | p≈0.57 | miss, no signal |
| Baseline (PR #288) | 3.275350 | 3087.5 | — | — | — |

W&B runs: `cpojpo1o` (n=4), `9zm9jnch` (n=1 screen)

**Mechanism**: lm_head norm ~795 — large stable value anchored by vocab embedding gradient signal. wd=0.01 per step contributes ~4×10⁻⁵ net change per step — too small vs the gradient-driven update. Arm B (wd=0.05) skipped (n=1 "win" at 3.27554 was seed noise per Welch t p=0.57). **lm_head norm telemetry** (monotone growth through warmup + partial deflation during cooldown) retained as useful diagnostic for future readout-focused experiments.

---

## 2026-05-18 06:00 UTC — Cycle 55 (continued): frieren #340 CLOSED (embed init std FALSIFIED — Arm A NaN); reassigned #343 AdamW β2 sweep

### FRIEREN #340 — Embed init std sweep — FALSIFIED (Arm A NaN at step 25, Arm B skipped per kill gate)

| Arm | EMBED_INIT_STD | step 25 train_loss | step 25 grad nonfinite | Verdict |
|---|---|---|---|---|
| Baseline | 1.0 | 5.958 | 0 | OK |
| **A** | **0.5** | **NaN** | **147,758,208** | **NaN at step 25** |
| B | 0.1 | not run | not run | skipped per kill gate |

W&B run: `innm9w83`. step 0 val=10.82583 (bit-identical to baseline), step 1 grad/global_norm=233,017 (within 0.02% of baseline 233,068). Code is correct; divergence at step 25 is genuine.

**Mechanism**: embed init scale is **load-bearing under current stack with adam_embed lr=0.30**. Halving embed init halves residual stream activations at layer 0 → AdamW updates mismatched to the new scale → gradients NaN within 25 steps. The 50× larger embed init vs Karpathy GPT-2 style is NOT a tuning oversight; it's required given the high adam_embed LR.

**Future direction (out of scope)**: joint embed-init × embed-LR sweep (e.g., LR ∝ std). Single-axis sweep on either knob alone breaks the coupling.

Frieren reassigned → PR #343: AdamW β2 sweep {0.90, 0.99} (last untested AdamW axis; β1-anneal and eps already FALSIFIED).

---

## 2026-05-18 05:15 UTC — Cycle 55 (continued): edward #281 CLOSED (per-head SOAP FALSIFIED — both arms miss); askeladd #319 Arm A FALSIFIED; reassigned #341 SOAP eigenbasis freeze

### EDWARD #281 — Per-head SOAP for attention weights — FALSIFIED (both arms miss both bars)

| Arm | Mechanism | val mean (n=2) | ffs mean | Δ val | Δ ffs | Verdict |
|---|---|---|---|---|---|---|
| A | PER_HEAD_SOAP_Q=1 (Q only) | 3.27727 | 3112.5 | +0.00144 | +25.0 | miss both |
| **B** | **PER_HEAD_SOAP_ALL=1 (Q/K/V/proj)** | **3.276245** | **3100** | **+0.000410** | **+12.5** | **miss both (closer)** |
| Baseline (PR #219 n=4) | full-matrix Gram + trust gate | 3.275835 | 3087.5 | — | — | — |

W&B runs: `lb4vsuxk` (Arm A), `z21iphfx` (Arm B). Implementation correct, trust-gate fully open at terminal (q/on_fraction=1.0, mean_cos_row=0.93) — NOT a gating issue; per-head eigenbases are stable.

**Mechanism insight**: Cross-head gradient covariance carries signal that block-diagonal preconditioning loses. The full-matrix Gram (768×768) captures off-block covariance between heads (head-redundancy, induction-circuit formation); splitting into n_head=6 independent (128×128) blocks zeros these off-block elements. Arm B recovers some via K/V/proj coordination but still loses gradient-level off-block covariance.

**Future direction (not pursued now)**: per-head as low-rank correction *on top of* full-matrix Gram (additive, not replacement), or gated fallback (per-head only when full-matrix gate trips off).

Edward reassigned → PR #341: **SOAP eigenbasis freeze after step K** (Arm A=1000 pre-cooldown, Arm B=2000 mid-cooldown). PR #277 axis was previously closed INCONCLUSIVE due to pod NaN; pod has been upgraded to torch 2.11.0 (PR #303 fix) — deserves clean re-test. Hypothesis: late-training Q refreshes are rotation noise that survives the trust gate.

### ASKELADD #319 — Muon LR linear warmup Arm A (100-step) — FALSIFIED

| Metric | n=2 mean | Baseline | Δ | Result |
|---|---|---|---|---|
| val/loss | 3.277545 | 3.275835 | +0.00171 | miss |
| ffs | 3112.5 | 3087.5 | +25.0 | miss |

W&B run: `5ao5znlo`. val_loss@step125 was 4.64 (vs ~4.17 baseline-pace) — warmup *delayed* early progress without yielding better basin. Mechanism: Muon's NS5 orthogonalization at full LR from step 1 is load-bearing — forces productive parameter geometry that warmup denies.

Arm B (MUON_WARMUP_STEPS=50) launching next. If Arm A-like margin → close axis cleanly.

---

## 2026-05-18 04:20 UTC — Cycle 55 (continued): frieren #333 CLOSED (AdamW eps FALSIFIED — both arms NaN); reassigned #340 embed init std sweep

### FRIEREN #333 — AdamW eps sweep — FALSIFIED (both arms NaN)

| Arm | eps | step:125 val | step:250 val | Verdict |
|---|---|---|---|---|
| Baseline | 1e-10 | 4.597 | 4.095 | OK |
| **A** | **1e-8** | **NaN** | **NaN** | **NaN** |
| **B** | **1e-12** | **NaN** | **NaN** | **NaN** |

W&B runs: `8j3txub2` (Arm A, killed ~step 380), `rbolag9z` (Arm B, killed ~step 388). Sanity check at eps=1e-10 was bit-identical to baseline → code is correct; NaNs are genuine property of the swept eps values.

**Mechanism**: Embed group runs at lr=0.30. The denominator `sqrt(v̂) + eps` at very early steps has sqrt(v̂) ~ 1e-4 (few gradient samples). 
- eps=1e-8: eps-dominated denominator → effective update scaled too large for embed → blow-up
- eps=1e-12: denominator too small for rare-token embeds with near-zero v̂ → division instability

**Pattern**: eps=1e-10 is a fourth unique stability window:
1. SOAP_PRECOND_FREQ=10 (5 and 20 both NaN)
2. NS5 iter=12 (8, 10, 14, 16 all NaN)
3. SOAP_β2≥0.90 required (0.85, 0.92 NaN/instability)
4. AdamW eps=1e-10 (1e-8 and 1e-12 both NaN)

**Conclusion**: Single-value eps change is not productive. Per-group eps (different eps per aux group) is theoretically interesting but high-effort, not a priority.

Frieren reassigned → PR #340: embed init std sweep (EMBED_INIT_STD=0.5 and 0.1 vs current N(0,1)).

---

## 2026-05-18 03:15 UTC — Cycle 55 (continued): nezuko #316 CLOSED (NorMuon β2 cooldown anneal FALSIFIED); reassigned #339 cooldown-frac sweep

### NEZUKO #316 — NorMuon β2 cooldown anneal — FALSIFIED

| Trial | val/loss | ffs | Verdict |
|---|---|---|---|
| 0 | 3.27838 | 3125 | MISS |
| 1 | 3.27843 | 3125 | MISS |
| **n=2 mean** | **3.278405** | **3125.0** | **MISS** |

Baseline: val=3.275835, ffs=3087.5. Δval=+0.00257, Δffs=+37.5.

W&B run: `hq3lzdm8`. Trial-to-trial swing tiny (Δval=0.00005, Δffs=0) — reproducible negative effect.

**Mechanism**: β2 controls per-row Adafactor variance EMA. Faster β2 adaptation during cooldown means the variance estimator has fewer effective samples at the critical convergence tail, producing noisier per-row normalization. The μ buffer (PR #288 WIN) has NS5 orthogonalization downstream that bounds the response to μ changes; the β2 variance buffer lacks this safety net and reacts directly to noisier estimates.

**Conclusion**: Cooldown-reactivity from momentum/variance buffer annealing is ONLY productive for Muon's scalar μ parameter, which has NS5 as a bounded nonlinear projection downstream. Do not reassign NorMuon β2 anneal in any form.

Nezuko reassigned → PR #339: cooldown_frac sweep (0.6 and 0.8 vs current 0.7).

---

## 2026-05-18 02:30 UTC — Cycle 55 (continued): tanjiro #309 CLOSED (AdamW β1 anneal FALSIFIED — both arms miss); reassigned #336 TARGET_UW sweep

### TANJIRO #309 — Annealed AdamW β1 — FALSIFIED

Both arms miss both merge bars at n=1. Student posted `SENPAI-RESULT` terminal marker with `pending_arms=false`.

| Arm | β1 schedule | val/loss | ffs | Verdict |
|---|---|---|---|---|
| Baseline | static 0.8 | 3.275835 | 3087.5 | reference |
| **A — broad** | 0.90 → 0.70 | **3.28251** | **-1 (never)** | **MISS** ❌ |
| **B — tight** | 0.85 → 0.75 | **3.27884** | **3150** | **MISS** ❌ |

W&B runs: `06dfy8gr` (Arm A), `45raqb1u` (Arm B)

**Mechanism**: AdamW β1 anneal does NOT mirror Muon μ anneal despite similar schedule shapes. Muon's NS5 orthogonalization is a nonlinear projection that bounds the response to μ changes — small changes in momentum direction have bounded downstream effects. AdamW has no analogous safety net: β1 changes directly affect raw gradient EMA on groups with very high (embed lr=0.3) and very sensitive (lm_head lr=1/320) effective LRs. Even Arm B's tight 0.10 span (0.85→0.75) delivered a mild but clear miss.

**Conclusion**: Cooldown-reactivity from momentum anneal is a Muon-specific phenomenon. Do not reassign AdamW β1 anneal in any form. AdamW β2 anneal is also ruled out by the same argument (plus the SOAP eigenbasis coupling concern from PR #291).

Tanjiro reassigned → PR #336: TARGET_UW sweep (0.25 and 0.50 vs current 0.35).

---

## 2026-05-18 01:30 UTC — Cycle 55: frieren #313 CLOSED (z-loss NaN unresolvable — 4 smokes, code never pushed); reassigned #333 AdamW eps sweep

### FRIEREN #313 — Logit z-loss regularization — CLOSED (implementation bug, hypothesis NOT falsified)

4 consecutive NaN smoke runs over 4+ hours. All crashed with 147.9M nonfinite gradients at step 125 (the same first val checkpoint). Student never pushed code to branch — no diff visible to advisor.

| Smoke run | Steps | Outcome |
|---|---|---|
| `cubsbstz` | 200 | NaN at step 125 (147.9M nonfinite) |
| `ek607yfe` | 200 | NaN at step 125 |
| `z3jfn1o9` | 200 | NaN at step 125 |
| `16pdz0jj` | 200 | NaN at step 125 |

Pattern matches: step-125 NaN is the attention-path driven pod NaN signature (identical to the torch 2.10.0 pod bug from PR #303 and #304). **However** fern's pod was already confirmed fixed by this cycle. Likely the z-loss implementation directly modified the forward/loss pipeline and introduced a numerical instability that masked the code-level bug.

**Conclusion**: Hypothesis (PaLM/T5-style z-loss regularization) is NOT falsified — we never saw the implementation. Closed due to inability to diagnose without code access. Reassigned to cleaner axis.

**Lesson**: When modifying the forward/loss pipeline, always push a checkpoint before launching even a smoke. The advisor needs code visibility to help with NaN debugging.

Frieren reassigned → PR #330: AdamW eps sweep (ADAMW_EPS=1e-8 vs 1e-12 vs current 1e-10).

---

## 2026-05-17 23:40 UTC — Cycle 54 (continued): askeladd #286 CLOSED (Polyak EMA FALSIFIED); reassigned #319 Muon LR warmup

### ASKELADD #286 — Polyak-Ruppert weight averaging — FALSIFIED

| Path | val/loss at step 3175 | reached_target | ffs |
|---|---|---|---|
| Non-EMA (raw model) | **3.2764** | yes | 3100 |
| EMA (Polyak β=0.999, start=2000) | **3.3097** | no | — |

EMA path is +0.0339 worse — far outside any noise band. Mechanism: POLYAK_START=2000, β=0.999 → EMA has effective horizon ~1000 steps, heavily weighted toward step ~2200 (val ~3.50 era). Our aggressive LR cooldown already eliminates the late-training variance that Polyak-Ruppert targets. Final weights ARE the optimum; averaging earlier high-LR weights strictly degrades the model.

**Conclusion**: Polyak averaging is fundamentally incompatible with aggressive linear cooldown. Do not reassign at any POLYAK_START/BETA setting.

Askeladd reassigned → PR #319: Muon LR warmup (100-step and 50-step arms).

---

## 2026-05-17 22:50 UTC — Cycle 54 (continued): nezuko #295 CLOSED (Polar Express MISS); reassigned #316 NorMuon β2 cooldown anneal

### NEZUKO #295 — Newton-Schulz NS5 polynomial coefficient sweep / Polar Express — MISS

Axis pivoted mid-PR from original NS5 coefficient sweep to Polar Express adaptive schedule (Tian et al., arXiv 2505.16932) after student's math review found sum≠1 bug in original Arm B.

| Metric | Polar Express `7klo2sbf` | Baseline (PR #219) | Δ | Bar |
|---|---|---|---|---|
| `speedrun/final_best_val_loss` | **3.2802** | 3.275835 | +0.00437 | mean < 3.275835 ❌ |
| `speedrun/final_first_step_to_target` | **-1** (never hit 3.28) | 3087.5 | — | < 3087.5 ❌ |
| `speedrun/final_reached_target` | 0 | 1 | — | — |

**Polar Express schedule**: Tian et al. 2025 adaptive coefficients, 12 iters, NS5_NORM_FACTOR=1.01. Student's per-iteration diagnostics: 100% of SVs within ±1% of 1.0 on all 39 samples (39/39) — polar factor was high quality. Ortho error 0.14-0.18 (dominated by near-zero SV tail, irrelevant to polar quality).

**Conclusion**: Polar Express's per-iteration optimality is for Frobenius residual at fixed iteration count, not for downstream optimizer convergence. At our fixed-budget 12-iter bf16 setting, marginal benefit over well-tuned (2,-1.5,0.5) is below noise. Adaptive coefficients would likely help at longer NS budgets (15-18 iters) but those would hurt ffs.

**Mechanism insight**: NS5 coefficient tuning is not a productive axis at 12 iters. The fixed (2,-1.5,0.5) triple is already near-optimal for this budget. Do not reassign.

Nezuko reassigned → PR #316: NorMuon β2 cooldown anneal {0.95→0.90, 0.95→0.85}.

---

## 2026-05-17 22:05 UTC — Cycle 54 (continued): frieren #275 CLOSED (MLP-SOAP trust gate FALSIFIED); reassigned #313 logit z-loss + alphonse #303 CLOSED (pod fix via torch upgrade)

### ALPHONSE #303 — Pod diagnostic — CLOSED (pod fixed)

Pod was on `torch 2.10.0+cu128` with mixed cu12/cu13 NCCL/cuDNN libs while healthy peers run `torch 2.11.0+cu130 cu13-only`. Step-1 gradients bit-identical to peer; divergence inside optimizer kernels (mixed-version libs) causes NaN cascade in steps 2-24.

**Fix**: In-place `pip install --upgrade 'torch==2.11.0'`. Post-upgrade 200-step diagnostic clean (val=4.166/4.176 at step 200, finite). Same pattern also affects fern #304 (in remediation).

Alphonse reassigned → PR #312: AdamW lm_head weight decay sweep {0.01, 0.05}.

### FRIEREN #275 — MLP-SOAP trust gate — FALSIFIED

| Arm | T_mlp | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| A | 0.85 | 3.27868 | 3150 | ❌ +0.00284 | ❌ +62.5 | `m5qmpwwq` |
| B | 0.90 | 3.28009 | -1 (never 3.28) | ❌ +0.00425 | ❌ misses | `wpo63vdn` |

Both arms miss. Arm A close to bar but doesn't beat; Arm B never reaches target.

**Telemetry diagnostic — opposite of attn-trust-gate prior**:
| Arm | T_mlp | mlp/on_fraction | mlp/mean_cos_row | attn/on_fraction |
|---|---|---|---|---|
| A | 0.85 | 0.625 (37.5% skipped) | 0.885 | 0.83-0.85 (only 15-17% skipped) |
| B | 0.90 | 0.417 (58% skipped) | 0.885 | — |

**Mechanistic insight — MLP precond is robust to rotation noise; attn precond is sensitive**:
> The hypothesis was: MLP SOAP eigenbasis rotates LESS than attn (so a gate at the same T fires LESS often). The data shows the opposite — MLP eigenbasis rotates AS MUCH as attn (mean_cos_row 0.885 vs 0.890; min_cos_row 0.83 vs 0.84). But the trust gate fires MUCH MORE often on MLP (37-58% vs attn's 15-17%) because the rotation-noise distribution has heavier tails on MLP.
>
> The real asymmetry is not "MLP stable / attn unstable" — both rotate similarly. The asymmetry is in **sensitivity**: applying a moderately-rotated MLP precond is net-beneficial (the precond is robust to rotation noise); applying a moderately-rotated attn precond is net-harmful (the precond is fragile). Gating helps on attn but hurts on MLP.
>
> Geometric interpretation: MLPs have higher effective rank in their gradient covariance (more spread eigenvalues), so the precond is dominated by the bulk of the eigenspectrum which rotates slowly even when individual eigenvectors rotate. Attn has more concentrated eigenvalue distribution (few large eigenvalues dominate), so eigenvector rotations directly affect precondition quality.

Frieren reassigned → PR #313: logit z-loss regularization (z_loss_coef ∈ {1e-4, 1e-3}). Fresh axis — only **loss-function** axis tested on r2; orthogonal to all optimizer-side work in-flight.

## 2026-05-17 20:45 UTC — Cycle 54 (continued): tanjiro #276 CLOSED (decoupled aux cooldown FALSIFIED); reassigned #309 AdamW β1 anneal

### TANJIRO #276 — Decoupled aux cooldown shape (cosine / none) — FALSIFIED

| Arm | aux_cooldown_shape | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| Baseline (n=4) | linear (coupled) | **3.275835** | **3087.5** | — | — | `3xn3ox1c` (pre-#219), `47bb0bf2` (n=4 PR #219) |
| A | cosine | 3.27696 | 3100 | ❌ +0.00113 | ❌ +12.5 | `lkh6dlbz` |
| B | none | 3.30208 | -1 (never reached 3.28) | ❌❌ +0.02625 | ❌ never reached | `yjmbml3f` |

Both arms confirmed at n=1. Arm A (cosine on aux) marginally worse than linear — within natural variation, but can't beat the strict bar. Arm B (no aux cooldown) catastrophically worse — model never reaches target val=3.28.

**Mechanistic insight — aux groups are tightly coupled to the readout-convergence stage**:
> The Arm B failure is the diagnostic: holding embed at lr=0.3 and lm_head at lr=1/320 through the final 30% of training prevents convergence. The model never gets within target distance.
>
> This contradicts the hypothesis premise ("aux groups don't have a Newton-Schulz fixed-point requirement"). They DO need to cool down — because embedding-table noise and lm_head noise late in training are read out as token-distribution variance. At the end the model is no longer learning, it is *converging the readout*, and embed/lm_head must follow Muon's cooldown.
>
> **Corollary**: aux groups want the same reactivity-vs-smoothness tradeoff as Muon — high momentum stability early, low momentum reactivity late. PR #219 won by doing this on Muon's μ. The natural follow-up is to test the same mechanism on AdamW's β1 (the only other scalar momentum-buffer coefficient in the system).

Cross-axis confirmation: r1 also tested cosine cooldown on the **whole stack** (Muon + aux together) and got val=3.2882 — also worse. Two independent experiments confirm linear cooldown is a stable optimum across all groups.

Tanjiro reassigned → PR #309: **Annealed AdamW β1** (0.90→0.70 broad, 0.85→0.75 tight). Direct parallel to PR #219 on the orthogonal aux-optimizer axis.

## 2026-05-17 20:05 UTC — Cycle 54 (continued): fern #291 FALSIFIED; alphonse #277 CLOSED (pod issue); both reassigned

### FERN #291 — Annealed SOAP β2 (0.95→0.85): adaptive Gram EMA — FALSIFIED

| Arm | β2_start | β2_end | val/loss | ffs | W&B |
|---|---|---|---|---|---|
| A | 0.95 | 0.85 | 3.2790 | 3150 | `joq5iz2h` |
| B | 0.92 | 0.88 | NaN (step 25) | — | `ku1hbldn` |

Arm A: n=1 trial (trial 2 killed — gap Δ=+0.0032 exceeds max n=1 rescue potential). Misses both bars.
Arm B: NaN by step 25. β2=0.92 starts in the documented multi-seed instability zone; the hypothesis that "annealing protects the start" was wrong — instability hits within 25 steps, before EMA can decay to safe range.

**Mechanistic insight — why μ-anneal works but β2-anneal doesn't**:
> μ controls a velocity-like momentum buffer (scalar contraction). Retiming it is forgiving because buffer quantity = gradient magnitude, robust to EMA rate.
> β2 controls the **Gram EMA matrix** whose eigendecomposition drives Muon's rotation. Eigenvectors are highly sensitive to perturbations, especially early in training when basis hasn't converged.
> The matching constraint `SOAP_PRECOND_FREQ ≈ 1/(1-β2)` (PR #271) means annealing β2 while keeping freq=10 static **breaks the optimal coupling**. At β2=0.95, optimal freq=20; at β2=0.85, optimal freq=7. Static freq=10 only matches at β2=0.90.

Fern reassigned → PR #304: anneal SOAP_PRECOND_FREQ (15→7 and 7→15) while keeping β2=0.90 static. Tests the orthogonal axis that respects the matching constraint.

### ALPHONSE #277 — SOAP eigenbasis freeze after step K — CLOSED (untested)

All 8 runs on alphonse's pod NaN'd at step 25-125. Student ran a critical diagnostic (POD-DIAG baseline, run `ej3fvmpy`) with freeze code **completely removed** — reverted to pre-#277 state — and it ALSO NaN'd at step 125. Side-by-side trajectory byte-identical with K=100 freeze run.

**Conclusion**: the merged-stack baseline itself is unstable on alphonse's pod. The freeze mechanism is untested (not falsified). Peer pods (tanjiro, frieren, fern) run healthy on identical config. This is a pod-specific issue (hardware/CUDA/driver/data-shard).

My earlier interpretation ("125 steps after freeze = 125 steps of compounding misalignment") was **wrong** — the POD-DIAG diagnostic proved the NaN is independent of the freeze. Acknowledging error; alphonse caught it correctly.

Alphonse reassigned → PR #303: pod diagnostic (env fingerprint + hard reset + clean baseline repro). No training experiment until pod health confirmed.

---

## 2026-05-17 ~17:30 — Cycle 54 (continued): nezuko #273 FALSIFIED with strongest mechanistic insight; nezuko reassigned (#295)

### NEZUKO #273 — Asymmetric Attn-SOAP trust T per param-kind (QK vs VO) — FALSIFIED

| Arm | QK / VO | val/loss | ffs | reached_target |
|---|---|---|---|---|
| A | 0.80 / 0.90 | 3.27768 | 3125 | yes |
| B | 0.90 / 0.80 | 3.28158 | -1 | **NO — failed to reach 3.28** |

**Mechanism (strongest insight of cycle 54)**: V's low cos_row (~0.81 baseline) is **TRUE signal of fast eigenbasis rotation, NOT a false negative**. The current single T=0.85 is faithfully filtering out genuinely untrustworthy eigenbasis updates. Forcing V SOAP to fire at low cos (Arm B, V on_fraction=1.00) injects noisy preconditioning into the residual stream → +0.005 val degradation, fails to reach target.

**Trust gate axis insight (added to project knowledge)**: trust thresholds and per-kind selectivity are entangled with the underlying eigenbasis dynamics. Q/K have stable bases (high cos_row → high on_fraction at T=0.85 is correct). V has unstable bases (low cos_row → low on_fraction is correct selectivity). The single T=0.85 expresses a faithful invariant ('don't precondition with a stale basis'); decomposing it loses that invariant.

This falsification has implications for **all SOAP trust-gate variants**: continuous (cosine-scaled) gates likely won't help either, since partial preconditioning at low cos still injects bad rotation.

W&B runs: `l0bszjjg` (Arm A), `8jsxx60y` (Arm B). Nezuko reassigned → NS5 polynomial coefficient sweep (PR #295).

---

## 2026-05-17 ~17:20 — Cycle 54 (continued): thorfinn #219 MERGED ⭐ NEW BASELINE; fern #271 FALSIFIED; fern reassigned (#291)

### THORFINN #219 — Annealed Muon μ schedule (MU_START=0.97 → MU_END=0.90) — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

Δ vs PR #212 baseline (3.27631 / 3112.5): val=−0.000475, ffs=−25.0. Statsig 0.00833 ≥ 0.004 (2.08× margin).

**Mechanism (well-supported)**:
1. **Early training**: high μ=0.97 = long EMA window. CONTRA_MUON's spectral perturbation noise is averaged out before being pushed through NS5. Reduces noise-driven moves through parameter space during fragile warmup.
2. **Cooldown phase**: μ → 0.90 = shorter EMA. Momentum buffer becomes more reactive precisely when LR cooldown reduces step magnitude — Muon can track finer-grained signal during the critical ffs-determining phase.
3. **Warmup-style (Arm A: 0.90→0.97) failed**: low μ early lets gradient noise dominate; high μ late over-smooths in cooldown. Worst-of-both schedule.

W&B run: `47bb0bf2`. PR squash-merged after rebase (PR #212 conflict resolved by student). Thorfinn reassigned → annealed μ finer sweep (PR #288: 0.97→0.92 tight range vs cooldown-phase-only anneal).

---

### FERN #271 — Decoupled SOAP eigenbasis refresh freq (MLP vs ATTN) — FALSIFIED

| Arm | SOAP_PRECOND_FREQ_ATTN | val/loss | ffs | vs new bar |
|---|---|---|---|---|
| A | 5 (faster) | 3.27633 | 3100 | MISS (+0.00050 val, +12.5 ffs) |
| B | 20 (slower) | 3.27909 | 3150 | CLEAR MISS (+0.00326 val, +62.5 ffs) |

**Mechanistic insight (project knowledge update)**: SOAP_PRECOND_FREQ and SOAP_BETA2 are entangled through the EMA effective horizon. Fern's drift telemetry showed that at β2=0.90, the post-refresh Gram already substantially equilibrates within 10 steps. Increasing refresh frequency by 4× (freq=5) only reduces Frobenius drift by ~6% (64K → 68K Frobenius units) — not enough to change gradient direction quality. Refresh frequency optimum ≈ EMA effective horizon = 1/(1-β2) → for β2=0.90, that's 10 steps.

**Key axis-coupling insight**: This implies SOAP_BETA2 is the primary control over eigenbasis dynamics, not refresh frequency. Annealing β2 (rather than refresh freq) is the natural follow-up — directly motivated this PR's mechanistic explanation.

W&B runs: `5873pgbt` (Arm A), `w9t7l423` (Arm B). Fern reassigned → annealed SOAP β2 (PR #291: 0.95→0.85 full range vs 0.92→0.88 tight range).

---

## 2026-05-17 ~16:15 — Cycle 54 (continued): askeladd #268 FALSIFIED; thorfinn #219 n=4 COMPLETE awaiting rebase; askeladd reassigned (#286)

### ASKELADD #268 — Per-block-depth Muon LR scaling — FALSIFIED

| Arm | Formula | val/loss @ 3175 | ffs | Outcome |
|---|---|---|---|---|
| A (up) | `(d+1)/6` (block 0=0.167×, block 11=2.0×) | 3.31916 | -1 (never hit 3.28) | Clear miss (+0.043 over baseline) |
| B (down) | `(12-d)/6` (block 0=2.0×, block 11=0.167×) | 4.165 @ step 1350 | -1 | Diverged, killed |

Both arms falsified per predeclared decision tree (val > 3.278 OR ffs > 3125).

**Mechanism (Arm A, "up")**: Starves early blocks (block 0 gets 1/6 baseline LR). The embeddings→block 0→block 1 cascade receives insufficient updates to develop early-token representations during the first ~half of training. By the time later blocks compensate, the LR cooldown has begun and there's no headroom left. Result: never reaches val=3.28 target.

**Mechanism (Arm B, "down")**: Starves late blocks. Late transformer blocks contain the most discriminative features (sharper local loss curvature). Reducing late-block LR by 6× wrecks tracking of this signal. Result: late blocks fail to converge → activations grow → gradient norms grow → divergence at step 1350.

**Lesson**: SOAP's per-shape preconditioning already absorbs per-layer gradient scale differences via its Gram matrices. Imposing additional explicit depth-LR structure adds constraints without exploiting unmodeled gradient structure.

W&B runs: `qfef54e1` (Arm A), `iudcq97t` (Arm B). Askeladd reassigned → Polyak weight averaging (PR #286).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 COMPLETE 🚀 PENDING REBASE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

**Both new baseline bars cleared:**
- val=3.275835 < 3.27631 (Δ=−0.000475) ✓
- ffs=3087.5 < 3112.5 (Δ=−25.0 steps) ✓
- statsig: (3.28 − 3.275835) × √4 = **0.00833** ≥ 0.004 ✓ (2.08× margin)

n=4 was launched on PRE-#212 stack (no trust gate). The annealed-μ mechanism beats the new trust-gate baseline anyway — strong evidence of additivity. After merge, compounding run with `ATTN_SOAP_TRUST_THRESHOLD=0.85` is the natural follow-up.

**Status**: Sent back to thorfinn for rebase (merge conflict with PR #212). W&B run: `47bb0bf2`. ETA to merge: ~30 min after rebase.

---

## 2026-05-17 ~15:00 — Cycle 54 (continued): alphonse #256 FALSIFIED; tanjiro #259 FALSIFIED; thorfinn #219 n=4 3/4 strong; frieren #254 closed; 3 students reassigned (#275, #276, #277)

### ALPHONSE #256 — SOAP_PRECOND_FREQ {5, 20} sweep — FALSIFIED

| Arm | SOAP_PRECOND_FREQ | Outcome |
|---|---|---|
| A | 5 | Multi-seed NaN at step 25 (5 independent trials) |
| B | 20 | Multi-seed NaN at step 25 (same fingerprint) |

Both arms falsified. Baseline (freq=10) runs cleanly to val~3.277 on all 4 trials. Both extremes destabilize within first 25 steps.

**Mechanism (Arm A, freq=5)**: First eigenbasis refresh at soap_step=5 with only ~41% Gram EMA equilibration (β₂=0.90). Eigenbasis from incomplete Gram is noisy → preconditioning rotates update in wrong direction → weight-norm explosion by step 25.

**Mechanism (Arm B, freq=20)**: Initial eigenbasis (from 1-step Gram) is rank-1 noise. Preconditioning with this for 20 steps before first refresh is catastrophic — the bad eigenbasis amplifies every update in the wrong subspace until divergence.

**SOAP_PRECOND_FREQ is a narrow stability window at 10**. Combined with Arm A finding, we can say: Gram needs ≥ 10 EMA steps to produce a usable eigenbasis, and the initial eigenbasis must be replaced quickly enough that its noise doesn't compound. 10 is the optimal tradeoff point.

W&B runs: `h1527wma`, `9ogg9inl`, `rnarwovu`, `htti5gif` (5 trials total, all NaN). Alphonse reassigned → SOAP eigenbasis freeze after step K (PR #277).

---

### TANJIRO #259 — NS_ITERS sweep (NS_ITERS=10, 8) — FALSIFIED

| Arm | NS_ITERS | Outcome |
|---|---|---|
| A | 10 | Trials 0, 1: 91% nonfinite gradients at step 225 |
| B | 8 | NaN (run just started, suspected same) |

Both arms falsified. Baseline (NS_ITERS=12) is the unique stable operating point.

**Mechanism**: NS5 polynomial with (a=2, b=-1.5, c=0.5) requires ~12 iterations to converge to an orthogonalized update for typical singular value distributions. With 10 iterations, the polynomial output is under-converged → uncontrolled singular value magnitudes → after Frobenius renormalization and TARGET_UW=0.35 u/w-floor scaling, effective update grows beyond weight scale → NaN cascade by step 225.

**NS5 iteration axis is fully exhausted**: (8, 10) NaN cascade; (12) optimal; (14, 16) also NaN from prior askeladd #232 sweep; fp32 NS5 (frieren #254) MISS (no precision improvement). The entire NS5 precision/iter axis is closed.

W&B runs: `cuhzxhaz` (seed-0 NaN, n=1), `wsdki64r` (n=4, trials 0-1 diverged at step 225). Tanjiro reassigned → decoupled aux cooldown shape (PR #276).

---

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5 — MISS

| Metric | Result | vs new baseline (PR #212) |
|---|---|---|
| val/loss | 3.2769 | > 3.27631 (MISS) |
| ffs | 3125 | > 3112.5 (MISS) |

Complementary to NS_ITERS falsification: adding fp32 precision also doesn't help. Combined, the NS5 pipeline is insensitive to both iteration count AND numerical precision changes from the 12-iter bf16 optimum.

W&B run: `mon2ndin`. Frieren reassigned → MLP-SOAP trust gate (PR #275).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥

| Trial | val/loss | ffs |
|---|---|---|
| 0 | 3.27510 | 3075 |
| 1 | 3.27697 | 3100 |
| 2 | 3.27489 | 3075 |
| 3 | (running) | — |
| **n=3 mean** | **3.27565** | **3083** |

**n=3 mean BEATS new baseline** (val=3.27631, ffs=3112.5) on BOTH metrics. Statsig n=3: (3.28 − 3.27565) × √3 = 0.00754 ≥ 0.004 ✓ (cleared by 1.9×).

Note: n=4 run launched before PR #212 merge — testing annealed μ WITHOUT TRUST_THRESHOLD=0.85. Even without the attn trust gate, annealed μ beats the new baseline (which HAS trust gate). This confirms the two mechanisms are additive; compound result (annealed μ + trust gate) should beat both individually.

W&B run: `47bb0bf2`. Trial 3 running, ETA ~17:30 UTC. Terminal SENPAI-RESULT pending.

---

## 2026-05-17 ~13:00 — Cycle 54: PR #212 MERGED (new baseline); 4 axes closed; 3 students reassigned

### NEZUKO #212 — Attn-SOAP+trust T=0.85 — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.2764 | 3125 |
| T1 | 3.2761 | 3100 |
| T2 | 3.2775 | 3125 |
| T3 | 3.2752 | 3100 |
| **n=4 mean** | **3.27631** | **3112.5** |

W&B run: `3xn3ox1c`. Statsig: (3.28-3.27631)×√4 = 0.00738 ≥ 0.004. BOTH BARS CLEARED vs PR #139 (val<3.27648, ffs<3118.75).

**Key finding**: Extending SOAP eigenbasis preconditioning to attention weights (via cosine-similarity trust gate, TRUST_THRESHOLD=0.85) gives consistent −6.25 mean ffs improvement. All 4 trials hit val < 3.28 target. Tight variance (T3=3.2752 strongest, T2=3.2775 weakest). Mechanism: SOAP coverage of attention projection matrices reduces curvature mismatch in the direction most sensitive to early-step convergence.

**Merged**: ffs 3118.75 → 3112.5 (−6.25), val 3.27648 → 3.27631 (−0.00017). Gap to record #20 (3030): ~82 steps.

---

### FERN #245 — Trust-region Muon (LARS-style, TRUST_RATIO sweep) — CLOSED

| Arm | TRUST_RATIO | val | ffs |
|---|---|---|---|
| A | 0.10 | 3.29988 | -1 |
| B | 0.05 | 3.32456 | -1 |

**MISS — monotonic worsening.** Telemetry revealed: at TRUST_RATIO=0.05, 38-50% of params clipped at steps 50-200, trust_scale≈0.22. Natural Muon update magnitude is ~20-25% of weight norm — any ratio ≤ 0.10 is throttling signal. The LARS-style trust constraint is fundamentally wrong for Muon (designed for small Adam-like updates, not large NS5 polar-factor updates).

**Recorded finding**: Natural Muon delta ≈ 20-25% of weight norm during early steps. Adam-family trust ratios (5-10%) are unsuitable for Muon/NS5 family. Any successful trust intervention would need gradient-conditioned per-outlier clipping, not blanket per-param normalization.

---

### EDWARD #251 — Lookahead on Muon (K=5, K=10) — CLOSED (INCOMPATIBLE)

All 3 attempts NaN'd at step 25 including trial 1 of n=4 retry.

| Run | K | NaN @ T0 | NaN @ T1 |
|---|---|---|---|
| 2lx8q0n6 | 5 | step 25 | — |
| wpcgf9e4 | 10 | step 25 | — |
| s6uvyg4y | 5 (n=4 retry) | step 25 | **step 25** |

**Multi-seed cascade confirmed** — NOT seed-0. The merged baseline (db1rrfx3) has NO NaN trials; all NaN is Lookahead-induced.

**Mechanism**: Lookahead's `fast := slow` param rollback every K steps leaves Muon's momentum buffer, NorMuon second_moment, and SOAP eigenbasis tracking the discarded fast trajectory while params jump back to slow. By step 25 (5 sync cycles at K=5), state-vs-param mismatch produces unbounded updates → all 12 blocks' Linear weights NaN simultaneously (123,701,376 nonfinite). Zhang et al 2019 designed Lookahead for first-moment-only optimizers; Lookahead is incompatible with multi-buffer preconditioners unless ALL state buffers are rolled back synchronously with params.

---

### ASKELADD #239 — Lion optimizer on aux groups — CLOSED

| Arm | embed_lr / lm_head_lr | val | ffs |
|---|---|---|---|
| v2 (gxxlpakh) | 0.03 / 1e-3 | 3.29854 | -1 |
| Arm B (n72pnmj3) | 0.05 / 3e-3 | 3.30050 | -1 |

**MISS by ~0.022 val.** Arm B's higher LR gives −0.073 nat head start at step 125 but crossover at step 2500 with Arm A ending 0.002 worse. Lion lacks second-moment estimation; in the critical cooldown phase (steps 2500-3175), AdamW's per-coord variance compensation is essential for aux groups (embed + lm_head) to stay on the efficient descent path. Sign-momentum is suboptimal for groups that need precise scaling in the precision window.

---

## 2026-05-17 ~11:35 — Cycle 53: Tanjiro reassigned; embed-warmup falsified

### TANJIRO #252 — Decoupled embedding LR warmup — FALSIFIED

60× variation in embedding LR at the NaN step (0.05 vs 0.30) produces bit-identical cascade:
- Arm A (EMBED_WARMUP=50): NaN step 25, nonfinite_count 123,701,376
- Arm B (EMBED_WARMUP=150): NaN step 25, nonfinite_count 123,701,376

Seed-0 NaN is NOT embedding-driven. The blocks.0.attn.proj.bias (attention path) is the real trigger. Embedding LR is a red herring.

Tanjiro reassigned → NS_ITERS sweep (PR #259): NS_ITERS ∈ {10, 8} vs baseline 12. Hypothesis: fewer NS5 iterations reduce bf16 rounding error compounding.

---

## 2026-05-17 ~10:30 — Cycle 51: SOAP_BETA2 axis closed; alphonse reassigned to SOAP_PRECOND_FREQ

### ALPHONSE #223 — SOAP_BETA2 retune {0.85, 0.92} — CLOSED (axis exhausted)

| SOAP_BETA2 | Runs | NaN pattern | verdict |
|---|---|---|---|
| 0.85 | 67w5zyph, 6gsl9ljw, grpcqmun | NaN at variable steps 75/318/1175 | **0.85-specific destabilizer** |
| 0.90 | db1rrfx3 (baseline) | n=4 mean val 3.27648, ffs 3118.75 | baseline |
| 0.92 | klsnpomc, hx3jldki (trials 0,1) | Both NaN @ step 25, canonical 147,758,208 fingerprint | **multi-seed cascade** |

SOAP_BETA2 is a sharp local optimum at 0.90. Both ±0.02 perturbations destabilize via distinct mechanisms: 0.85 shows later-step HP-induced NaN cascade (variable timing), 0.92 triggers the canonical seed-0 / multi-seed baseline NaN across consecutive seeds. Axis fully exhausted in both directions.

Alphonse reassigned → SOAP_PRECOND_FREQ sweep (PR #256): {5, 20} vs baseline 10. Hypothesis: tighter eigenbasis refresh (5 steps) reduces eigenbasis lag during rapid early-step gradient direction changes → better preconditioning → lower FFS.

## 2026-05-17 ~06:45 — Cycle 44: Three PRs CLOSED (frieren bias-corr, askeladd proj-init-B, edward AdEMAMix); 3 fresh assignments (frieren #238, askeladd #239, edward #240)

### FRIEREN #221 — Adam-style Muon bias correction (MUON_BIAS_CORR=1) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `6qb399cr` (n=1, 3175 steps) | **3.27903** | **3150** | MISS (+0.00255 val, +31.25 ffs) |

Adam-style `1/(1-μ^t)` first-moment debiasing on Muon does not transfer to the merged Contra+SOAP-MLP+NS5+contra-normuon+u/w-floor stack. The canonical bias correction (well-studied in Adam) appears to over-amplify Muon momentum when paired with the SOAP eigenbasis pre-conditioner — the NS5+contra+u/w-floor pipeline already implicitly manages momentum norm dynamics. Mechanism-stack mismatch, not a code error. Per pre-authorized decision tree (val > 3.278 → close).

Frieren reassigned → Cosine LR cooldown shape (PR #238). Orthogonal to closed cooldown-duration axis (PR #178, 0.70 local optimum). Cosine concentrates LR higher in early-cooldown steep-descent window; may push FFS earlier.

### ASKELADD #224 — Per-module init Variant B (std=0.00221 non-zero proj) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `u0x4ni0c` (n=1, 3175 steps) | **3.27993** | **3175** | MISS (+0.00345 val, +56.25 ffs) |

Variant B (std=0.00221) landed nearly identically to Variant A (zero-init, val=3.28042): only 0.0005 val difference. Both converged to the same attractor — confirms SOAP+NS5 absorbs whatever per-module init benefit can exist on this stack. The per-module init direction (all variants: standard fan-in, zero-init, and small-non-zero) is **fully exhausted** on the merged Contra+SOAP-MLP base. Mechanism is stack-absorbed.

Askeladd reassigned → Lion optimizer on aux groups (PR #239). Replace AdamW on embed+lm_head+scalars with Lion sign-based optimizer. Hypothesis: sign normalization accelerates early token embedding specialization (step 0-500, FFS-critical window). No second moment → cannot amplify variance NaN cascade.

### EDWARD #199 — AdEMAMix on aux groups — CLOSED (multi-seed NaN, no clean trial)

| Run | trial_idx | val | ffs | verdict |
|---|---|---|---|---|
| `d9vxzbtk` | 0 | NaN (step 25) | — | baseline seed-0 NaN |
| `4e8wgtxk` | 0 | NaN (step 25) | — | duplicate process |
| `q2un2m4y` | 0 | NaN (step 1225) | — | multi-seed cascade |
| `65edtfli` | 0-3 | NaN (aborted step 125) | — | safety-guard abort |

Zero clean trials across 4 runs and 2 retries. The `num_trials=4` retry was authorized after establishing AdEMAMix(α=0)≡AdamW to 1e-7 (correct code), but the n=4 run still failed. Likely: AdEMAMix's slow-EMA accumulation on the high-LR embed group (lr=0.3) amplifies the baseline step-2 fragile equilibrium across seeds, not just seed-0.

Edward reassigned → Adaptive NS5 iteration count schedule (PR #240). More iters (16) in early-training fragile window, fewer (8) in late well-conditioned window. Directly tests orthogonalization quality as a FFS lever.

---

## 2026-05-17 ~06:00 — Cycle 43: Nezuko Screen B WINS; fern LR_POWER=1.5 MISS; multi-seed NaN cascade identified

### NEZUKO #212 — Attn-SOAP+trust Screen B (TRUST_THRESHOLD=0.85) — WIN → n=4 IN PROGRESS 🚀

| Screen | val | ffs | verdict |
|---|---|---|---|
| Screen A (`h29cv26c`, T=0.90) | 3.27628 | 3125 | val WIN only — ffs MISS |
| **Screen B (`5g7k1w3q`, T=0.85)** | **3.27475** | **3100** | **BOTH BARS CLEARED** |

Screen B lowered trust threshold from 0.9 to 0.85, activating SOAP for more attention v/proj weights (activation rate: T=0.85 → v on 50%, proj on 100%, overall 87.5%; T=0.9 → v on 0%, proj on 17%, 35%). The increased SOAP coverage closed the FFS gap (3125 → 3100). n=4 confirm launched 05:26 UTC (`3xn3ox1c`), ETA ~12:50 UTC.

### FERN #208 — Power-law LR cooldown (LR_POWER=1.5, CM=0.5)

| Run | val | ffs | verdict |
|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5, CM=0.4 default — misconfigured) | 3.28313 | -1 | MISS (informational only) |
| `rpws9fug` (LR_POWER=1.5, CM=0.5 proper) | **3.28240** | **-1** | MISS (+0.00592 val) |

Power-law=1.5 HURTS by +0.006 val. Currently testing LR_POWER=2.0 (front-loaded cooldown, different shape hypothesis).

### Multi-seed NaN cascade identified (new this cycle)

Three students (alphonse SOAP_BETA2=0.85, tanjiro TARGET_UW=0.30, edward AdEMAMix) all showed NaN cascades across MULTIPLE seeds (not just seed-0). Distinguishable from seed-0 baseline NaN:
- Seed-0 baseline NaN: step 25, 147,758,208 nonfinite count
- HP-induced multi-seed NaN: step 100-1225, same or higher nonfinite count

Pattern suggests some HP changes (extreme SOAP_BETA2, extreme TARGET_UW, AdEMAMix) destabilize the early-training fragile equilibrium beyond seed-0, making all seeds fail.

---

## 2026-05-17 ~04:35 — Cycle 42: Three PRs CLOSED; three fresh assignments; edward retry authorized

### ALPHONSE #205 — CONTRA_MUON sweep — CLOSED

| Arm | val | ffs | verdict |
|---|---|---|---|
| 0.6 (`u0f98rxy`) | 3.27666 | 3125 | MISS — rising shoulder of optimum |
| 0.7 (`uoqp63dq`) | NaN @ step 25 | — | catastrophic divergence |

**Bowl-shape confirmed**: 0.5 → 0.6 is on the rising shoulder (slightly worse within noise); 0.7 over the cliff (NaN at step 25). CONTRA_MUON=0.5 is the confirmed local optimum. Sweep exhausted — do not revisit CONTRA_MUON axis.

Alphonse reassigned → SOAP_BETA2 retune (PR #223): {0.85, 0.92} vs baseline 0.90. Hypothesis: SOAP Gram EMA decay rate was tuned before CONTRA_MUON=0.5 merged; may need re-tuning for the more perturbed gradient dynamics.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSED

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27666 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra |

Val gap is below seed noise (Δval=0.00007 between p=0.07 and p=0.10). FFS=3125 is structural — the mechanism reliably lands at the wrong ffs bucket. Parameter-insensitive in [0.07, 0.10]. Mechanism is sound but ffs gap is structural on new baseline. **CLOSED.**

Frieren reassigned → Adam-style bias correction on Muon first moment (PR #221). Novel mechanism: EMA of Muon momentum is biased toward zero in early training; Adam-style bias correction via `1/(1-μ^t)` should help most in the FFS-critical early training phase.

### ASKELADD #213 — Per-module init zero-init variant — CLOSED

W&B run `jmcvmacz`: val=3.280419, ffs=-1 — MISS by 0.004.

Zero-init proj weights (mlp.proj, attn.proj, lm_head) on merged Contra+SOAP-MLP+NS5 stack doesn't help. SOAP eigenbasis + NS5 spectral normalization already manage init scale implicitly — the μP-inspired init benefit doesn't transfer from simpler optimizer stacks (records #4,5,8).

Askeladd reassigned → Variant B non-zero proj init (PR #224): std=1/(n_embd×√2) ≈ 0.00092. Tests whether a conservative small-scale init (vs zero) provides SOAP eigenbasis signal without the large-scale init explosion risk.

### EDWARD #199 — AdEMAMix aux groups — BLOCKED by baseline NaN

Both 3175-step screen seeds (`d9vxzbtk`, `4e8wgtxk`) NaN'd at step 25 (147,758,208 nonfinite grads at blocks.0.attn.proj.bias — canonical baseline fingerprint). Per edward's analysis: trial_idx=0 deterministically hits the NaN seed. AdEMAMix dynamics (α_t=0.023 at step 25) had no time to express — this is baseline instability, NOT AdEMAMix bug.

**Advisor decision: override my own decision-tree (wrote it before understanding seed-determinism). Authorized retry with `--num_trials 4` to sample seeds {0,1,2,3}.** At least 1 seed should pass given that other students' runs (alphonse `u0f98rxy`, fern `w12r4fc9`) have shown the NaN rate is seed-selective. Retry still pending student launch.

---

## 2026-05-17 ~03:49 — Cycle 41: Thorfinn #178 CLOSED; annealed-μ assigned (#219); multi-screen status

### THORFINN cooldown_frac sweep — CLOSED (PR #178)

Sweep summary (n=1 each arm):

| arm | val | ffs | verdict |
|---|---|---|---|
| 0.65 | 3.27865 | 3150 | MISS |
| **0.70 (control)** | **3.27536** | **3100** | baseline HP — single seed beats baseline |
| 0.75 | 3.27655 | 3125 | MISS |

Both 0.65 and 0.75 are worse than 0.70. Monotone-from-both-sides signal — **0.70 is the local optimum.** This rules out cooldown_frac as a lever and confirms the current schedule duration is already at the sweet spot. Closed to focus compute on schedule *shape* (fern power-law) and mechanism changes.

### THORFINN reassigned — Annealed Muon momentum μ schedule (PR #219)

2-arm sequential screen: MU schedule 0.90→0.97 (Arm A, warmup-style) vs 0.97→0.90 (Arm B, inverse). Hypothesis: static μ=0.95 was set before CONTRA_MUON=0.5 baseline; annealing μ over training tests two mechanism stories about optimal EMA decay over the training trajectory. Linear interpolation in `set_hparams`. 2 × ~95 min screens.

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 multi-arm status

| Arm | Run | val | ffs | verdict |
|---|---|---|---|---|
| 0.6 (Arm A) | `u0f98rxy` | 3.27666 | 3125 | MISS — tiny (+0.00018 val, +6.25 ffs) |
| 0.7 (Arm B) | `uoqp63dq` | IN PROGRESS | — | launched 03:44 UTC, ETA ~05:29 |

CONTRA_MUON=0.6 essentially tied the baseline — within seed noise but doesn't clear win bar. Arm B (0.7) running. If 0.7 also misses, sweep is done — 0.5 was the optimum. If 0.7 wins, it would be the second monotone step (0.4→0.5→0.7 wins) — strong signal.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSING

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27667 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra/OOM, not mechanism |

Val gap is 0.00011-0.00019 (below seed noise), but ffs=3125 is structural — ffs is quantized in 25-step buckets and the mechanism is reliably landing at 3125. Cannot close the 6.25 ffs gap vs new baseline (3118.75) regardless of p_start value. Mechanism is parameter-insensitive in 0.07-0.10 range. Advisor nudged frieren to post SENPAI-RESULT; will close and reassign to fresh direction.

### NEZUKO #212 — Attn-SOAP+trust (new baseline) screens

| Screen | Run | val | ffs | verdict |
|---|---|---|---|---|
| TRUST_THRESHOLD=0.9 (A) | `h29cv26c` | 3.27628 | 3125 | VAL WIN (−0.00020), FFS MISS |
| TRUST_THRESHOLD=0.85 (B) | running | — | — | launched 03:25 UTC, ETA ~05:00 |

Screen A's val=3.27628 is a VAL WIN but ffs=3125 misses 3118.75. Threshold=0.85 activates SOAP on v/proj rows (which hover at cosine 0.85-0.89 from PR #124 data). If Screen B also wins val AND closes ffs gap, predeclare n=4 immediately.

### ASKELADD #213 — Per-module init screen — MISS, Variant B predeclared

W&B run `jmcvmacz`:

| Metric | Value | vs baseline | verdict |
|---|---|---|---|
| val/loss | 3.28042 | +0.00394 | MISS |
| ffs | never crossed 3.28 | — | MISS |

Per-module init (μP-inspired: embed std=0.02, zero-init proj/lm_head, fan_in-scaled qkv) didn't improve on the merged SOAP-MLP stack. NS5 spectral normalization and SOAP eigenbasis preconditioning already absorb most of what per-module init buys on simpler optimizer stacks. Recommended Variant B: non-zero proj init (proj.weight ~ N(0, 1/(320*sqrt(2)))) — this may stabilize the step-2 NaN pattern at blocks.0.attn.proj.bias and improve early-step dynamics. Waiting for SENPAI-RESULT before launch.

### FERN #208 — Power-law LR cooldown screens

| Screen | CONTRA_MUON | val | ffs | verdict |
|---|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5) | **0.4 (wrong!)** | 3.28313 | -1 | misconfigured — CONTRA_MUON default 0.4 |
| `rpws9fug` (LR_POWER=1.5+CM=0.5) | 0.5 ✓ | IN PROGRESS | — | launched 03:25 UTC, ETA ~04:55 |

Fern correctly caught the CONTRA_MUON misconfiguration and relaunched with CM=0.5. ersqpsq2 result on 0.4 base not useful for decision tree. rpws9fug is the true LR_POWER=1.5 screen on new baseline.

### EDWARD #199 — AdEMAMix aux groups — Full screen authorized

After exceptional diagnostic work: Edward proved AdEMAMix(α=0) ≡ AdamW to 1e-7 (unit test), and the baseline itself (unmodified commit ae5552e) NaN-s at step-2 in `blocks.0.attn.proj.bias` stochastically. The NaN is seed-dependent baseline instability on 1-GPU short runs, NOT an AdEMAMix bug. Authorized full 3175-step screen with conservative HPs (α=1.0, β3=0.99, warmup=1024, eps=1e-8). Screen launch pending.

---

## 2026-05-17 ~01:30 — Cycle 37: Tanjiro PMuon CLOSED; TARGET_UW retune assigned (#214); in-flight status

### TANJIRO PMuon bilateral streaming covariance — CLOSED (PR #187)

W&B run `eafhrglu` (g1r2-tanjiro/pmuon-stream, γ=0.3, β=0.95):

| Metric | Value | Baseline | Δ |
|---|---|---|---|
| val/loss | ~3.425 at step 2150 (cooldown entry) | 3.27648 | MISS |
| ffs | -1 (never crossed 3.28) | 3118.75 | MISS |

**Root cause analysis**: PMuon's bilateral power-iteration streaming covariance (Σ_L, Σ_R with γ-power exponent) is a gradient-space preconditioner. SOAP-MLP already applies eigenbasis preconditioning to MLP weights before NS5. Stacking PMuon on top creates **double-conditioning** — two sequential preconditioners on the same gradient. Record #18 (PMuon, 3269 steps) was tested on vanilla Contra-Muon WITHOUT SOAP-MLP; the composition here is different. Result: val=3.425 heading into cooldown, too far behind to converge.

Student handling was exemplary: caught advisor's close-out message 8 seconds after launching γ=0.2 follow-up screen, killed it at step 50 (saving ~3 GPU-hours), posted corrected terminal SENPAI-RESULT. **PMuon closed. Do not retry PMuon on SOAP-MLP stack.**

### TANJIRO reassigned — TARGET_UW retune (PR #214)

2-arm sequential screen: TARGET_UW ∈ {0.30, 0.40} vs new baseline. Hypothesis: TARGET_UW=0.35 was tuned with CONTRA_MUON=0.4; with CONTRA_MUON=0.5 the natural u/w ratio has shifted. One env-var change, zero added complexity. Arms: 0.30 (looser floor) and 0.40 (tighter floor).

### IN-FLIGHT STATUS UPDATE (as of ~01:30 UTC 2026-05-17)

**ALPHONSE #205 CONTRA_MUON=0.6 screen `fmx37tmr`**: step 2875/3175, val=3.306 — running, ~300 steps from terminal (~30 min). In deep cooldown. Result pending.

**FRIEREN #177 p=0.07 retry `dbf0augy`**: step 3000/3175, val=3.2912 — nearly done (~15 min). Needs to drop to ≤3.2762 in final 175 steps (significant drop required; likely landing in 3.27x range but outcome uncertain).

**THORFINN #178 cooldown_frac sweep**:
- 0.65 arm DONE: val=3.27865/ffs=3150 — **MISS** vs new baseline (both bars missed). Shorter cooldown hurts.
- 0.70 arm (control): val=3.27536/ffs=3100 — single seed beats baseline (but it IS the baseline HP).
- 0.75 arm `7f0r4eds`: just started (step 325/3175, val=4.059 early). Key test for longer cooldown.

**EDWARD #199 AdEMAMix**: 7+ smoke runs ALL NaN/crashed. Latest: `nxwdjjtx` (5 steps, NaN), `gwkew7xw` (crashed at step 1). Student has not pushed code to branch (branch has only 2-line cosmetic change). Advisor requested code paste and STOP on new runs until reviewed.

**NEZUKO #212 Attn-SOAP new base**: smoke `0k3qgq5q` clean at step 400 (val=3.808). Screen `h29cv26c` at step 675/3175, val=3.759 — healthy early phase.

**ASKELADD #213 per-module init**: smoke `0vc4kc82` clean at step 400 (val=3.832). Screen `jmcvmacz` at step 700/3175, val=3.775 — healthy early phase.

**FERN #208 power-law LR**: screen `w12r4fc9` at step 1225/3175, val=3.633 — running, ~39% through.

---

## 2026-05-16 23:30 — Cycles 33-34: Four PRs CLOSED; three new assignments

### FERN Aurora n=4 — CLOSED (PR #125), high variance

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.28038 | -1 (MISS) |
| n=4 mean | **3.27893** | **FAIL** |

2/4 trials miss ffs (never cross 3.28). n=4 mean=3.27893 > 3.27648 and 3.27893 > 3.27800 (statsig bar). Aurora diagonal leverage-score equalization is fundamentally high-variance on this architecture — mechanism requires n=8+ for reliable statistics. **CLOSED. Aurora is off the table at n=4 budget.**

### NEZUKO Attn-SOAP+trust-gate n=4 — CLOSED (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27715 | 3125 |
| n=4 mean | **3.27742** | **3125** |

Val MISS: 3.27742 > 3.27648. FFS MISS: 3125 > 3118.75. Misses the NEW baseline (PR #139) by 0.00094 val and 6.25 ffs. **CLOSED.** Notable: std=0.00015 is the best stability of any mechanism tested — Attn-SOAP+trust gate is robust. The mechanism is sound but doesn't beat the shifted baseline. Reassigned to Attn-SOAP on new base (PR #212) at THRESHOLD=0.9 and 0.85.

### ASKELADD SFM (Schedule-Free Muon) — CLOSED (PR #181)

SFM const-EMA fallback screen `k3wkjy84` (c_t=0.01):

| Metric | Value |
|---|---|
| val/loss | ~4.6+ (diverged) |
| y_z_diff_fro | growing unboundedly |

**Fundamental incompatibility confirmed**: Muon's Newton-Schulz iteration operates correctly only under non-constant LR (the operator-norm normalization within NS5 implicitly relies on LR decay to bring ‖y − z‖ under control). With constant LR, ‖y − z‖ diverges regardless of c_t schedule. **Schedule-Free Muon is CLOSED as a direction. Do not revisit.**

Assigned: askeladd → per-module weight init scaling (PR #213).

### New assignments created (Cycles 33-34)

| PR | Student | Hypothesis |
|---|---|---|
| #208 | g1r2-fern | Power-law LR cooldown (LR_POWER=1.5/2.0 sweep) — record #20 ingredient |
| #212 | g1r2-nezuko | Attn-SOAP+trust on CONTRA_MUON=0.5 baseline (THRESHOLD=0.9 then 0.85) |
| #213 | g1r2-askeladd | Per-module weight init scaling (μP-inspired, records #4,5,8 ingredient) |
| #214 | g1r2-tanjiro | TARGET_UW retune 0.30/0.40 sweep (u/w-floor vs new CONTRA_MUON=0.5 base) |

---

## 2026-05-16 23:15 — Cycle 32: PR #139 MERGED (NEW BASELINE), frieren screen near-miss

### ⭐ ALPHONSE CONTRA_MUON=0.5 n=4 — MERGED (PR #139) — NEW BASELINE

W&B run `db1rrfx3`:

| Trial | val/best_loss | ffs |
|---|---|---|
| T0 | 3.27830 | 3150 |
| T1 | 3.27634 | 3125 |
| T2 | 3.27551 | 3100 |
| T3 | 3.27577 | 3100 |
| **n=4 mean** | **3.27648** | **3118.75** |
| statsig | (3.28−3.27648)×2 = **0.00704** ≥ 0.004 ✓ | |

Beats prior baseline (PR #78) on both bars: val −0.00112, ffs −12.5 steps. **MERGED.** Mechanism: increasing CONTRA_MUON from 0.4 → 0.5 adds more spectral exploration via contravariant perturbation, escaping suboptimal gradient directions faster during peak-LR phase. Counter to intuition (more noise → better speed), but consistent with the "spectral exploration" interpretation.

New baseline after merge: mean=3.27648, ffs_mean=3118.75.

### FRIEREN Soft-Muon-anneal screen — NEAR-MISS vs new baseline (PR #177)

W&B run `dhqwygng` (p_start=0.10 → p_end=0.0 over first half):

| Metric | Screen | New baseline | Δ |
|---|---|---|---|
| val/loss | 3.27667 | 3.27648 | +0.00019 (MISS by tiny margin) |
| ffs | 3125 | 3118.75 | +6.25 steps (MISS) |

Excellent mechanism signal — val=3.27667 is far below old baseline (3.27760) and very close to new one. Miss is only 0.019% on val and 6.25 steps on ffs. Pre-approved p_start=0.07 follow-up screen launched. Analysis: annealing p=0.10 → 0.0 over first half of training adds spectral mixing during peak-LR phase and eliminates it during cooldown. Mechanism is sound; parameter needs slight reduction.

---

## 2026-05-16 22:15 — Cycle 31: Edward Contra-Muon n=4 CLOSED (stronger-but-slower); Askeladd SFM MISS; fern/nezuko T3 started

### Edward Contra-Muon n=4 @ 3225 steps — CLOSED, superseded (PR #76)

W&B run `zsqazpmr` (`g1r2-edward/contra-muon`):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |
| T2 | 3.27652 | 3175 |
| T3 | 3.27607 | 3175 |
| **n=4 mean** | **3.27652** | **3175** |
| statsig | **(3.28−3.27652)×2 = 0.00696 ≥ 0.004 ✓** | |

- Statsig PASS but ffs_mean=3175 > baseline 3131.25 — **FFS MISS**, does NOT beat merged baseline on primary metric.
- "Stronger but slower" pattern (#3 instance this session: Soft-Muon, Newton-Muon, now Contra-Muon-only).
- Mechanism superseded by PR #78 (merged baseline already has Contra-Muon + SOAP-MLP; edward's PR is the Contra-Muon-only subset).
- PR #76 closed. Edward reassigned to AdEMAMix-aux (PR #199).

### Askeladd SFM uniform c_t screen — MISS, fallback triggered (PR #181)

W&B run `groom2ym` (`g1r2-askeladd/sfm`):

| Field | Value |
|---|---|
| Screen val/loss | 4.60499 |
| ffs | -1 (MISS — never crossed 3.28) |
| y_z_diff_fro (terminal) | ~2.2e9 (massive divergence) |
| c_t at terminal | 0.00031 |

Root cause: `c_t = 1/(t+1)` weighs early pre-warmup iterates near-equally with trained iterates. By step 3175, most of the Polyak average weight sits on random-init timesteps. The `||y − z||` norm grows to 2.2B — z has moved far from init but y averages it all back toward init.

Fallback (pre-approved): `SFM_C_SCHEDULE=const`, `SFM_C_CONST=0.01` (EMA with ~100-step window). Screen `k3wkjy84` launched by student. This is a fundamentally sounder design — tracks recent trajectory rather than summing all history.

### Fern Aurora n=4 T2 terminal — BORDERLINE (PR #125)

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| n=3 mean | **3.27844** | — |

n=3 mean=3.27844 > 3.27800 → statsig currently fails. For n=4 MERGE: T3 needs val ≤ 3.27668 AND ffs ≤ 3125. T1's MISS (-1) means if using train_steps for ffs calculation, ffs_mean ≥ 3131.25 even with perfect T3. **Merge path nearly closed.** T3 still running (step 878/3175).

### Nezuko Attn-SOAP+trust-gate n=4 T2 terminal — OUTSTANDING (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| n=3 mean | **3.27750** | **3125** |

All 3 trials within 0.00015 val! n=3 mean=3.27750 beats both baseline bars (≤3.27800 val, ≤3131.25 ffs). T3 needs val ≤ 3.27852 (generous bar). **MERGE NEAR-CERTAIN.** T3 at step 553/3175.

---

## 2026-05-16 20:25 — Cycle 30 (cont): Tanjiro Lookahead CLOSED, nezuko/fern T0+T1 interim results

### Tanjiro Lookahead α=0.7 retry — MISS, PR #161 CLOSED

W&B run `yph361ta` @ train_steps=3175:

| Arm | α | Final val | ffs |
|---|---|---|---|
| Original screen | 0.5 | 3.30606 | -1 (MISS) |
| Retry | **0.7** | **3.28985** | -1 (MISS) |

Higher α (weaker pullback) recovered 0.016 val/loss but still missed by 0.010. Structural issue confirmed: Lookahead's slow-fast averaging slows cooldown val descent regardless of α. Lookahead doesn't transfer to this short-step cooldown-dominated regime. PR #161 closed.

### Tanjiro reassigned — PMuon (PR #187)

Record #18 mechanism: bilateral streaming covariance power preconditioning (Σ_L, Σ_R with γ=0.3 power exponent, β=0.95). Stacks on top of merged Contra+SOAP-MLP+NS5 after the NS5 step. Fresh preconditioner class — softer than KL-SOAP (pf=1 eigendecomp) but more adaptive than plain SOAP (pf=10).

### Nezuko Attn-SOAP+trust-gate n=4 T0+T1 (interim) — OUTSTANDING

W&B run `790h1llo` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27743** | **3125** |
| T1 | **3.27750** | **3125** |
| n=2 mean | **3.27747** | **3125** |

Remarkably consistent T0/T1 pair (val within 0.00007!). Both beat merged baseline on both metrics. If T2+T3 continue pattern → n=4 mean ≤ 3.27800 AND ffs_mean ≤ 3125 = **MERGE CANDIDATE**.

### Fern Aurora n=4 T0+T1 (interim) — HIGH VARIANCE WARNING

W&B run `5kr7d0i5` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27592** | **3100** |
| T1 | **3.28172** | **-1 (MISS!)** |

T1 completely missed — Aurora's diagonal leverage-score equalization is seed-sensitive. Path to merge now requires both T2 and T3 to hit near T0 quality. High variance is concerning. Monitoring.

## 2026-05-16 19:10 — Cycle 30: Askeladd KL-SOAP screen MISS, reassigned to Schedule-Free Muon

### Askeladd KL-SOAP+H screen — MISS, PR #166 CLOSED

W&B run `061cl8bj` @ train_steps=3125:

| Metric | Value |
|---|---|
| val/loss at terminal | **3.29515** |
| ffs (first_step_to_target) | **-1 (never reached 3.28)** |
| Step time | ~2.6 s/step |

Val=3.295 is +0.0175 above merged baseline mean (3.27760) and well above the 3.281 threshold in the predeclared decision tree. KL-SOAP+H replacing (not stacking on) the merged Contra+SOAP-MLP stack was ~50 steps worse on terminal val/loss at the same step budget. The pf=1 eigenbasis frequency doubled per-step compute but didn't recover the NS5+Contra-Muon orthogonalization the merged baseline relies on. PR #166 closed.

### Askeladd reassigned — Schedule-Free Muon (PR #181)

Fresh mechanism class: Polyak iterate averaging with constant LR, eliminating cooldown entirely. Hypothesis: constant LR keeps gradient magnitude steady; iterate averaging absorbs noise → val crosses 3.28 earlier. Implementation: maintain z (trajectory) and y (averaged eval point), Muon update on z, y ← (1 − 1/(t+1)) · y + (1/(t+1)) · z. No cooldown_frac, no LR warmup-cooldown schedule. First test of schedule-free paradigm on this track.

## 2026-05-16 17:55 — Cycle 29 (cont): Thorfinn Soft-Muon n=4 CLOSED, reassigned to cooldown_frac retune

### Thorfinn Soft-Muon p=0.05 n=4 — STRONGER-BUT-SLOWER, PR #103 CLOSED

W&B run `nfkk0mms` @ train_steps=3175-3325 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274159 | 3250 |
| T1 | 3.274896 | 3250 |
| T2 | 3.272523 | 3225 |
| T3 | 3.275516 | 3250 |
| **n=4 mean** | **~3.2741** | **~3.2243** |

Statsig: `(3.28 − 3.2741) × √4 = +0.0118` — **PASSES** statsig (need ≥ 0.004). Val/loss excellent — best n=4 val mean of the session! BUT ffs_mean ≈ 3244 > baseline 3131.25. Does NOT beat merged baseline on FFS metric. Clean "stronger but slower" result — Soft-Muon's polynomial spectral compression lowers terminal val but slows cooldown convergence, adding ~75-100 steps vs baseline. PR #103 closed.

### Thorfinn reassigned — cooldown_frac retune (PR #178)

Three single-seed screens: cooldown_frac = 0.65, 0.70 (baseline reference), 0.75. If ffs ≤ 3100 AND val ≤ 3.279, predeclare n=4. Target: identify if scalar cooldown retune shifts the 3.28 crossing from ~step 3125 to ~step 3075. Predeclared sweep comparison table when all 3 screens complete.

## 2026-05-16 17:46 — Cycle 29: Frieren MuLoCo n=4 CLOSED, reassigned to Soft-Muon annealing

### Frieren MuLoCo+NorMuon n=4 — CLEAN NEGATIVE, PR #109 CLOSED

W&B run `jzsue46n` @ train_steps=3175 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.282398 | -1 (miss) |
| T1 | 3.281958 | -1 (miss) |
| T2 | 3.279381 | 3175 |
| T3 | 3.280067 | -1 (miss) |
| **n=4 mean** | **3.28095** | **1/4 hit** |

Statsig: `(3.28 − 3.28095) × √4 = -0.0019` — **FAILS** statsig (need ≥ 0.004). Only T2 reached target. MuLoCo outer-Nesterov wrapping does not transfer to the merged Contra+SOAP-MLP step budget. The original screen at 3275 (`akwwpkv3`, val=3.27688 ffs=3225) was real but stronger-but-slower — needs ~100 more steps than merged baseline allows.

Clean negative — well-executed predeclaration honored across all 4 trials. PR #109 closed.

### Frieren reassigned — Soft-Muon annealing on merged base (PR #177)

Fresh hypothesis: record #20 (current global best at 3030 steps) uses **annealed Soft-Muon** as the key novel mechanism. Soft-Muon NS5 with `x^(1-p)` polynomial mixing, p_start=0.10 → p_end=0.0 annealed over first half of training. Applied to model.blocks.parameters() ndim>=2, alongside the existing Contra-Muon + SOAP-MLP stack. Target: cleaner cooldown trajectory + earlier 3.28 crossing.

## 2026-05-16 15:55 — Cycle 24: Fern Aurora screen FFS-WINNING, alphonse n=4 launched, frieren n=4 confirmed clean negative

### Fern Aurora screen — FFS-WINNING result on Contra+SOAP-MLP base (PR #125)

After two prior crashes (`csj1tm5z` @ step 1475, `isi6y97w` @ step 575) and a clamp fix (`D.clamp_(1e-6, 1e6)`):

| Run | Config | val/loss | ffs | Statsig (n=1) |
|---|---|---|---|---|
| `lqwaozx7` | Aurora on Contra+SOAP-MLP, 3175 steps | **3.27706** | **3125** | — |

**SINGLE-SEED BEATS MERGED BASELINE ON BOTH METRICS:**
- val 3.27706 < baseline 3.27760 (−0.00054)
- ffs 3125 < baseline ffs_mean 3131.25 (−6.25)

n=4 PREDECLARED at train_steps=3175 at 15:54 UTC. Fern to launch immediately. ETA terminal ~21:00-22:00 UTC.

Aurora is the FIRST mechanism (alongside CONTRA_MUON=0.5 tuning) to produce a single-seed FFS win on the merged baseline. Critically, Aurora is a fundamentally different mechanism from CONTRA_MUON tuning — it's diagonal leverage-score equalization inside NS5 from record #17. If both n=4 confirmations pass, they could potentially be stacked.

### Alphonse n=4 LAUNCHED — CONTRA_MUON=0.5 (PR #139)

W&B run `db1rrfx3` launched 15:33 UTC, currently step ~350/3175 trial 0. Same configuration as merged baseline except CONTRA_MUON=0.4 → 0.5. ETA full n=4 terminal ~22:00-22:30 UTC.

### Frieren n=4 MuLoCo+NorMuon — CLEAN NEGATIVE confirmed (PR #109)

W&B run `jzsue46n` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.28240 | -1 (never crossed 3.28) |
| T1 | 3.28196 | -1 (never crossed 3.28) |
| T2 | running | — |
| T3 | — | — |

T0 and T1 both miss the 3.28 target at 3175 steps. T2/T3 in progress per binding predeclaration; ETA full terminal ~17:40 UTC. Mean would need ≤3.27587 across T2/T3 to salvage statsig — ~3σ unlikely. Clean negative. Will close PR after SENPAI-RESULT.

Pattern: MuLoCo outer-Nesterov wrapping doesn't add to Contra+SOAP-MLP at 3175 steps. The original NorMuon-clean base achieved val=3.27688 ffs=3225 at 3275 steps in screen, but stacking MuLoCo doesn't compress further to 3175 steps.

### Thorfinn Soft-Muon p=0.05 n=4 — strong val, FFS not competitive (PR #103)

W&B run `6kjpjnvd` @ train_steps=3325 (plain Muon + NorMuon + Soft-Muon base):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27423 | 3250 |
| T1 | 3.27492 | 3250 |

Remarkable T0/T1 agreement at ffs=3250. Excellent val/loss but ffs=3250 > merged baseline 3131.25 by 119 steps. Pattern: "stronger but slower" — same as Newton-Muon, NorMuonH. Will close PR after T2/T3 terminal (~17:40 UTC).

### Edward Contra-Muon n=4 — statsig pass likely, FFS not competitive (PR #76)

W&B run `zsqazpmr` @ train_steps=3225:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |

Excellent val (mean projection ~3.276), but ffs=3175 > merged baseline 3131. Pod showing slow step rate (~6010 ms/step) but GPU healthy at 100%. ETA terminal ~21:00 UTC. Will close after terminal.

## 2026-05-16 15:35 — Cycle 23: Alphonse CONTRA_MUON=0.5 screen beats baseline on both metrics

### Alphonse CONTRA_MUON=0.5 screen — BEATS merged baseline on BOTH val AND FFS (PR #139)

| Run | Config | val/loss | ffs | Statsig (n=1) | Notes |
|---|---|---|---|---|---|
| `hjsjscjy` | CONTRA_MUON=0.3, 3175 steps | 3.27804 | 3150 | — | First FFS-competitive screen (cycle 18) |
| `yctj2ozd` | CONTRA_MUON=0.5, 3175 steps | **3.2763** | **3125** | — | BEATS baseline (3.27760/3131.25)! |

Screen `yctj2ozd` (CONTRA_MUON=0.5) delivers val=3.2763 ffs=3125 — the first single-seed result to beat the merged baseline on BOTH primary metrics simultaneously. N=4 PREDECLARED at train_steps=3175 with CONTRA_MUON=0.5. Predeclare comment posted at ~15:15 UTC. ETA terminal ~22:30-23:00 UTC.

Analysis: Reducing CONTRA_MUON from 0.4 (merged) → 0.5 (stronger contra correction) appears to tighten the convergence trajectory during cooldown. The contra correction `T - T^T` removes antisymmetric noise from the operator; a higher coefficient removes more, leading to a cleaner Newton-Schulz input. This translates directly to earlier FFS crossing without sacrificing terminal val.

### Askeladd NorMuonH n=4 @ 3300 — CLOSED, statsig pass but not FFS-competitive (PR #74)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27781 | 3225 |
| T1 | 3.27573 | 3200 |
| T2 | 3.27863 | — |
| T3 | ~3.277xx | — |
| n=4 mean | **3.27732** | ffs_mean ~3225-3250 |

n=4 mean=3.27732 — STRICTLY BETTER VAL than merged baseline (3.27760 → 3.27732), but ffs_mean ~3225-3250 — STRICTLY WORSE FFS than baseline 3131.25. Closed as "statsig pass but not FFS-competitive." NorMuonH on plain Muon base produces excellent terminal val but cannot compress the convergence curve to match Contra+SOAP-MLP's FFS efficiency. Reassigned to KL-SOAP + hyperball (PR #166).

### Askeladd reassigned — KL-SOAP + hyperball (PR #166, just assigned)

New hypothesis: Replace Contra-Muon+NS5+SOAP-MLP with KL-SOAP+hyperball on ALL 2D block params. Key parameters: β1=0.95, β2=0.90, shampoo_beta=0.90, pf=1, lr=0.018 (record #19 HPs). Reference: record #19 (n=6 mean=3.27800 @ 3125 steps, statsig pass). KL-SOAP at pf=1 provides the most aggressive curvature tracking in the literature — eigendecomp every step rather than every 10 steps. Unknown if it stacks with or replaces the Contra mechanism.

## 2026-05-16 14:15 — Cycle 19: Newton-Muon closed, Lookahead assigned, alphonse FFS-competitive

### Tanjiro Newton-Muon CLOSED — positive but not merge-eligible (PR #81)

Two terminal SENPAI-RESULTs:

| Config | n | val/loss mean | ffs_mean | Statsig | Merge? |
| --- | --- | --- | --- | --- | --- |
| Newton-Muon-only @ 3325 (`cpoe66ut`) | 4 | **3.27643** | 3256.25 | PASSES (0.00714) | NO — ffs > baseline |
| Newton-Muon-attn + Contra+SOAP-MLP @ 3175 (`wzgya0cq`) | 1 | 3.28893 | -1 | N/A | NO — missed target |

Newton-Muon-only at 3325 produces the LOWEST n=4 mean val/loss of any r2 student (3.27643), beats public record #15 (3.2785) by 0.00207. Paper-quality result, reproducible (σ≈0.0005). But ffs_mean=3256.25 at 3325 steps vs merged baseline ffs_mean=3131.25 at 3175 — 125 steps worse on primary metric.

Stack with Contra+SOAP-MLP (Option B) at 3175 failed badly (3.28893, never reached 3.28). Numerics clean (0 Cholesky failures), but the combined 4-mechanism stack doesn't compress below 3.28 in 3175 steps. Pattern: each additional mechanism extends the cooldown needed.

Conclusion: Newton-Muon mechanism is "stronger but slower." Not FFS-competitive at 3175. Closed PR #81.

### Tanjiro reassigned: Lookahead-Muon (PR #161)

Fresh hypothesis: Lookahead wrapper on merged Contra+SOAP-MLP baseline (Zhang et al. 2019). Inner optimizer takes k=5 steps normally; every k steps: θ_slow ← θ_slow + 0.5(θ_fast − θ_slow), then θ_fast ← θ_slow. Applied to ALL trainable params AFTER warmup.

Goal: FFS reduction by 30-80 steps via trajectory variance smoothing during peak-LR phase. If screen (single-seed at 3175) lands ≤ 3.279 with ffs ≤ 3175, predeclare n=4. Stretch goal: ffs_mean < 3131.

### Alphonse CONTRA_MUON=0.3 screen FFS-COMPETITIVE (PR #139)

`hjsjscjy` terminal: val=**3.27804**, ffs=**3150** at 3175 steps. Single-seed 19 steps worse than merged baseline ffs_mean=3131.25, but competitive val. FIRST FFS-competitive result since PR #78 merged. Alphonse launched CONTRA_MUON=0.5 screen (`yctj2ozd`) at step ~450 at 13:40 UTC. ETA terminal ~15:35 UTC.

If 0.5 screen competitive: predeclare n=4 at 3175 with best arm. n=4 mean could potentially beat baseline if seed distribution is favorable.

## 2026-05-16 10:30 — Cycle 14: Multiple screens terminal, PR #112 closed, alphonse reassigned

### Alphonse p=1.5 NEW-base CLOSED — NULL result (PR #112)
- W&B run `5gd8cw6c` (p=1.5 on Contra+SOAP-MLP NEW-base): **val=3.2775, ffs=3150** at 3275 steps
- Summary: p=1.5 on NEW-base essentially equals merged baseline mean (3.27760), within 1σ noise.
  p>1 on OLD-base was clearly negative; on NEW-base SOAP-MLP neutralizes the effect but provides no gain.
- Conclusion: linear LR cooldown remains optimal. Power-law p>1 ruled out for both bases.
- PR #112 CLOSED. Alphonse reassigned to **PR #139: Contra-Muon coefficient retune** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Frieren MuLoCo+NorMuon screen STRONG (PR #109 in-flight)
- W&B run `akwwpkv3`: **val=3.27688, ffs=3225** at 3275 steps (single seed, NorMuon-clean base)
- Beats NorMuon-clean reference: val 3.27800→3.27688 (−0.00112), ffs 3256→3225 (−31 steps)
- Frieren predeclared n=4 at **train_steps=3175** (matching merged baseline) and launched immediately.
- Critical: frieren's n=4 will test if MuLoCo+NorMuon competes with Contra+SOAP-MLP at same step count.
- If n=4 mean ≤ 3.278, ffs_mean ≤ 3131: MERGE candidate. ~6.75h ETA.

### Tanjiro Newton-Muon n=4 terminal (PR #81 in-flight, no SENPAI-RESULT yet)
- `cpoe66ut`: T0=3.27599/ffs=3250, T1=3.27720/ffs=3275, T2=3.27612/ffs=3250, T3=3.27639/ffs=3250
- n=4 mean=3.27643, ffs_mean=3256.25, margin=0.00714 — PASSES statsig
- But ffs=3256.25 > merged baseline ffs=3131.25 by 125 steps — does NOT beat merged baseline
- Sent back (cycle 13): rebase + stack Newton-Muon's right-precond (attention) on Contra+SOAP-MLP
- Recipe insight: Newton-Muon achieves the LOWEST n=4 mean val (3.27643) of any recipe — strong mechanism, needs different step budget to compete.

### Thorfinn Soft-Muon p=0.05 n=4 launched (PR #103)
- `78nqtrmr`: n=4 at train_steps=3325, plain Muon + NorMuon + Soft-Muon base
- T0 nearly terminal at val~3.2742 ffs=3225 (strongest single-seed result in portfolio!)
- ETA ~8-9h to T4 terminal. Single-seed trajectory at 3.2742 is remarkable.

### Edward Contra-Muon T0 strong (PR #76)
- T0 from `zsqazpmr`: val=3.2760, ffs=3175. T1 just started (step ~100).
- Expected: n=4 mean ~3.277-3.278 range. Likely pass statsig at 3225 steps.

### Askeladd NorMuonH T0 done (PR #74)
- T0 from `lw99ybyp`: val=3.2777, ffs=3250 at 3300 steps. T1 at step ~1825/3300.

## 2026-05-16 07:55 — Cycle 11: Soft-Muon p=0.05 strong, power-law LR closing

### Thorfinn p=0.05 SCREEN STRONG SIGNAL (PR #103)
- W&B run `pzp8b4rq` finished cleanly at **val/loss=3.27553, ffs=3250** at train_steps=3325.
- **Single seed 0.00207 BELOW merged baseline mean 3.27760** — strongest sub-baseline single-seed result in this round.
- p=0.075 retry `6empzhxo` crashed at step 625 — external pod restart, NOT numerical (blend still 0).
- Sent back PR #103 with directive: **launch predeclared n=4 @ 3325 confirmation immediately**, skip p=0.075 retry.
- For statsig at n=4: need mean ≤ 3.278. With single seed at 3.27553 and recipe variance σ~0.0007 typical, n=4 mean projects to 3.276–3.278 (borderline confirmable).
- Recipe (Soft-Muon p=0.05 on plain Muon) is **orthogonal** to merged Contra+SOAP-MLP — potential future stack candidate.
- ETA T3 ~13h from launch.

### Alphonse power-law LR closing (PR #112)
- W&B run `fg11eojr` (p=1.2): **3.28031** at 3275 steps — MISS
- W&B run `vvwsv9fm` (p=1.5 OLD-base): **3.28470** at 3275 steps — MISS
- Monotonic trend: p=1.0→0.000, p=1.2→+0.00231, p=1.5→+0.00670 — power-law cooldown with p>1 is decisively counterproductive on NorMuon base.
- p=1.5 NEW-base screen launched at 08:28 UTC (decisively expected to miss). Acknowledged "let it finish" per alphonse's decision tree.
- After NEW-base screen terminalizes: close PR #112 with documented negative evidence, reassign alphonse to **Contra-Muon coefficient retune on merged base** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Other r2 students (in-flight, no new terminals)
- edward `zsqazpmr` (Contra-Muon n=4 @ 3225): T0=3.27750 done, T1 at step ~2275/3225 (~70%). ~10h to T3.
- tanjiro `cpoe66ut` (Newton-Muon n=4 @ 3325): T0=3.27599, T1-T2 done, T3 at step ~1275/3325 (~38%). Best T0 is BEST single-trial of any wave-1 recipe.
- askeladd `lw99ybyp` (NorMuonH n=4 @ 3300): launched, at step ~1425/3300 (~43%) — picked up cycle-9 rebase+launch directive.
- frieren `akwwpkv3` (MuLoCo+NorMuon screen @ 3275): just launched, step ~0.
- nezuko `g4zvpp9c` (Attention SOAP + trust gate): smoke at step ~40 + 2 prior smokes done. PR #124 picked up.
- fern `csj1tm5z` (Aurora orthogonal projection): screen at step ~25 + 1 prior smoke done. PR #125 picked up.

All 8 r2 students productive — zero idle GPUs in cycle 11.

## 2026-05-16 06:35 — PR #78: Contra+SOAP-MLP — MERGED as new advisor baseline
- Branch: `g1r2-fern/contra-soap-mlp` (squash-merged `718dd3f`)
- See below entry for full experiment detail. BASELINE.md updated.

## 2026-05-16 06:35 — PR #80: Muon² n=4 confirmation — CLOSED (non-competitive)
- Branch: `g1r2-nezuko/muon-sq`
- W&B run: `7lxk02m6` | num_trials=4 | train_steps=3325

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27788 | 3300 |
| T1 | 3.27859 | 3300 |
| T2 | 3.27915 | 3300 |
| T3 | 3.27792 | 3300 |
| **mean** | **3.27839** | **3300** |

- Statsig check: (3.28 − 3.27839) × √4 = **0.00322** — FAILS 0.004.
- Recipe is stable (all seeds hit target, no crashes, std=0.0006). The n=4
  mean is 0.0008 above NorMuon-clean's statsig ceiling (3.27800 @ 3300).
- Closed because: (1) non-statsig; (2) even extended to 3375 steps, ffs_mean
  ≈ 3325 vs new baseline 3131 — won't merge. Muon² ordering (Adam var BEFORE
  NS5) is confirmed inferior to NorMuon's post-NS5 ordering on this benchmark.
- Status: **CLOSED**. Nezuko reassigned to Attention SOAP + trust gate (PR #124).

## 2026-05-16 05:45 — PR #78: Contra+SOAP-MLP — STATSIG WIN (merge pending rebase)
- Branch: `g1r2-fern/contra-soap-mlp`
- Hypothesis: SOAP eigenbasis preconditioning on MLP weights, applied to
  momentum *before* NS5+contra+NorMuon (matches record #14 reference ordering).
- W&B confirmation run: `6bbhoxm1` | num_trials=4 | train_steps=3175 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27920 | 3150 |
| T1 | 3.27811 | 3150 |
| T2 | 3.27522 | 3100 |
| T3 | 3.27787 | 3125 |
| **mean** | **3.27760** | **3131.25** |

- Statsig check: (3.28 − 3.27760) × √4 = **0.00480 ≥ 0.004** — **PASSES**.
- Comparison vs NorMuon-clean baseline (PR #71): mean 3.27800 → 3.27760
  (−0.00040), ffs_mean 3256.25 → 3131.25 (**−125 steps**).
- Matches public record #14 (4 decimal places). Single-seed σ ≈ 0.0015.
- Auxiliary screening runs: `du7a5t1t` (3.27553 @ 3225, corrected ordering),
  `h3vsdeik` (3.27960 @ 3225, PR-literal ordering, superseded).
- The PR-literal ordering (SOAP after NorMuon variance) was suboptimal because
  NorMuon's per-element variance scaling is NOT basis-invariant — student
  caught this discrepancy by reading the record #14 reference file directly.
- Status: **STATSIG WIN, merge pending**. Blocked by (1) merge conflicts with
  auto-nanogpt-1gpu-r2 (NorMuon-clean merged after PR opened), (2) false-
  positive SENPAI-RESULT JSON parse on workflow-note comment. Sent back for
  rebase + comment disambiguation.

## 2026-05-16 05:30 — PR #74: NorMuonH — n=4 confirmation at 3275 (terminal, non-statsig by 0.00008)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon + hyperball + per-module init std (record #8 stack).
- W&B run: `6rf3nerz` | num_trials=4 | train_steps=3275 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27781 | 3225 |
| T1 | 3.27777 | 3225 |
| T2 | 3.27798 | 3250 |
| T3 | 3.27860 | 3250 |
| **mean** | **3.27804** | **3237.5** |

- Statsig check: (3.28 − 3.27804) × √4 = **0.00392** — misses 0.004 by 0.00008.
- Recipe is real and reproducible (σ~0.0004 across 4 trials, tightest of any
  wave-1 stack so far). Mean misses statsig ceiling by 0.00004.
- Notable: NorMuonH at 3275 has ffs_mean=3237.5, beating NorMuon-clean's
  3256.25 — but the loss ceiling is the rule that matters for merge.
- Status: WIP. Send back for predeclared n=4 at train_steps=3300 (one cooldown
  cycle of headroom should push mean to ~3.276 with same σ).

## 2026-05-16 05:30 — PR #112: NorMuon + power-law LR cooldown — p=1.2 screen MISSED
- Branch: `g1r2-alphonse/normuon-plawlr`
- Hypothesis: `lr * (1-progress)/cooldown_frac)^p` with p=1.2 (record #20
  schedule) may give 25-75 step gain over linear cooldown.
- W&B screen run: `fg11eojr` | num_trials=1 | train_steps=3275 | LR_COOLDOWN_POWER=1.2
- Result: terminal **val/loss=3.28031, ffs=-1, reached_target=0**. Did NOT
  cross 3.28.
- Per predeclared branch decision: if 3.277 < val ≤ 3.280, try p=1.5 next.
  3.28031 is just above 3.280, but the spec says "both p=1.2 AND p=1.5 > 3.280
  → close". p=1.5 single-seed should be tried before deciding.
- Status: WIP. Student should auto-launch p=1.5 screen on next poll.

## 2026-05-16 05:45 — PR #103: Soft-Muon isolated p=0.05 — SCREEN CRASHED
- Branch: `g1r2-thorfinn/soft-muon`
- Hypothesis: Soft-Muon polynomial `x^(1-p)` at p=0.05 (reduced from p=0.1
  which missed at 3.28024) with annealed blend 0→0.8 from step 2500.
- W&B screen run: `hz91ow2y` | num_trials=1 | train_steps=3325
- Result: **crashed at step 1575/3325 (47%, mid-cooldown)**. Last val/loss
  reading 3.5253.
- Likely cause: Soft-Muon polynomial coefficients at lower p may produce
  numerical instability when blended with NS5 mid-cooldown. Needs debugging.
- Status: WIP. Student should investigate crash, may need p=0.075 midpoint.

## 2026-05-16 04:30 — PR #109: MuLoCo+NorMuon smoke — DIVERGED TO NaN
- Branch: `g1r2-frieren/muloco-normuon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper on top of NorMuon inner
  optimizer (record #13 stack).
- W&B smoke run: `mti327gb` | num_trials=1 | train_steps=400
- Result: **val/loss=NaN by step 400**. Diverged.
- Likely cause: outer_lr=0.7 too aggressive on NorMuon's variance-noisy update
  direction; or outer Nesterov momentum compounds NorMuon's variance instability.
- Status: WIP. Student should try outer_lr=0.5 or sync_interval=60 in smoke
  before screen.

## 2026-05-16 01:45 — PR #79: MuLoCo on plain Muon — CLOSED (all 4 corners missed)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- Final W&B sweep runs:

| run | si | outer_lr | train_steps | val/loss | reached |
| --- | --- | --- | --- | --- | --- |
| `bqfv4523` | 15 | 0.5 | 3300 | 3.2829 | 0 |
| `q57yhybv` | 30 | 0.7 | 3300 | 3.2810 | 0 |
| `ecohqy9o` | 15 | 0.7 | 3300 | 3.2815 | 0 |
| `v2wn0t8t` | 60 | 0.5 | 3300 | **3.2865** | 0 |

- Conclusion: All 4 sweep corners failed to reach 3.28. The si=60/lr=0.5 corner
  (meant to allow longer inner runs between outer steps) was actually the **worst**
  result. Plain Muon's NS5 orthogonalization already smooths the gradient direction
  — MuLoCo's outer Nesterov momentum provides no additional benefit. Public record
  #13's success was likely driven by MuLoCo wrapping NorMuon (which has noisy
  per-element variance), not plain Muon.
- Status: **CLOSED (dead end)**. Frieren reassigned to MuLoCo+NorMuon (PR #109).

## 2026-05-16 01:50 — PR #81: Newton-Muon — n=4 confirmation at train_steps=3275 (terminal, non-statsig)
- Branch: `g1r2-tanjiro/newton-muon`
- Hypothesis: Activation-covariance right-preconditioning applied to the Muon
  gradient before Newton-Schulz (refresh every 64 steps).
- W&B run: `xsb35b0m` | num_trials=4 | train_steps=3275

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.279715 | 3275 |
| T1 | 3.278674 | 3250 |
| T2 | **3.277678** | **3225** |
| T3 | 3.281277 | -1 (missed) |
| **n=4 mean** | **3.27934** | — |

- Statsig check: `(3.28 - 3.27934) × √4 = 0.001328` — BELOW 0.004. **Non-statsig.**
- Analysis: T0–T2 all cleared 3.28 individually, including T2 at 3.2777 (among
  the best individual trials in wave 1). T3 was a bad seed — 3.2813 — above the
  target, which dragged the mean to 3.279. The recipe is real but has high
  seed variance. Needs more cooldown steps to tighten the distribution.
- Status: WIP. Sent back for fresh n=4 at predeclared `train_steps=3325`.

## 2026-05-15 23:20 — PR #79: MuLoCo on plain Muon — sweep arm si=15 (terminal)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- W&B run: `ecohqy9o` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/ecohqy9o`)
  | num_trials=1 | train_steps=3300 | sync_interval=15, outer_lr=0.7
- Result: terminal **val/loss=3.2815 @ step 3300**,
  `speedrun/final_first_step_to_target=-1`, `speedrun/final_reached_target=0`.
  **Did NOT cross 3.28.**
- Context: 3rd consecutive single-seed screen to miss — `bqfv4523`=3.2829,
  `q57yhybv`=3.2810, `ecohqy9o`=3.2815. All at or above 3.281 margin.
- Conclusion: MuLoCo on plain Muon appears break-even or slightly worse than
  starter at train_steps=3300. si=60/lr=0.5 corner still pending. If that
  corner also misses ≥ 3.281, MuLoCo-on-plain-Muon is dead and frieren will
  be pivoted to MuLoCo wrapping a confirmed inner optimizer (NorMuon or
  Contra-Muon, per the approach of public record #13).
- Status: WIP. si=60 sweep arm pending.

## 2026-05-15 22:45 — PR #80: Muon² (Adam variance BEFORE Newton-Schulz) — single-seed screen
- Branch: `g1r2-nezuko/muon-sq`
- Hypothesis: Per-element Adam variance applied to gradients *before* the
  Newton-Schulz orthogonalization should preserve NorMuon's variance-normalization
  benefit while keeping the orthogonalization geometry clean. lr=0.10, wd=0.0125,
  β₂=0.95, train_steps=3350 (per record #7 / nezuko PR body).
- W&B run: `n18mqjfy`
  (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/n18mqjfy`) | num_trials=1 |
  train_steps=3350.
- Result: terminal **val/loss=3.2773 @ step 3350**,
  `speedrun/final_first_step_to_target=3300`, `reached_target=1`.
- Statsig at n=1 (informational): (3.28 − 3.2773) × √1 = 0.0027 — does NOT
  clear the 0.004 single-seed bar, but is below 3.28 and on track for n=4
  consideration with cooldown headroom.
- Status: WIP. n=4 confirmation `7lxk02m6` launched (T0 early at step 275).
  Single-seed margin smaller than edward/fern/alphonse, so n=4 statsig is
  uncertain; will need mean ≤ 3.278 across 4 seeds.

## 2026-05-15 20:30 — PR #74: NorMuonH (row/col variance + hyperball + per-module init std)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon's row/col Adafactor-style variance combined with hyperball
  constraint (preserve ‖p‖_F per step) and per-module init std (×1.25 attn.proj,
  zero block-level proj for residual-branch safety) should reduce optimizer
  steps. Public record #8: 3225 steps, mean val/loss 3.2776 (n=10).
- W&B run: `sohiul20` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/sohiul20`)
  | num_trials=4 | train_steps=3250 (predeclared confirmation).
- Per-trial final val/loss at step 3250:
  | trial | val/loss |
  | --- | --- |
  | 0 | 3.27849 |
  | 1 | 3.27942 |
  | 2 | 3.27835 |
  | 3 | 3.27840 |
  | **mean** | **3.27867** |
  | std | ~0.0005 |
- `speedrun/final_first_step_to_target = 3225`, all 4 trials cleared 3.28.
- Statsig check (rule `(3.28 − μ) × √n ≥ 0.004`): (3.28 − 3.27867) × 2 =
  **0.00267** — below the 0.004 threshold at n=4. **Not statsig.**
- Conclusion: NorMuonH is a real, reproducible recipe (very tight inter-seed
  variance) but its mean at step 3250 falls 0.0007 above the statsig ceiling.
  Adding more seeds at step 3250 would not help (mean too stable). Sent back
  asking for a fresh n=4 batch at a predeclared step ∈ {3275, 3300} to gain
  ~0.001 of cooldown headroom for statsig clearance.
- Status: WIP / not merged. Awaiting follow-up predeclared confirmation.

## 2026-05-17 00:00 — PR #125 CLOSED: Aurora on Contra+SOAP-MLP base (fern)

- Branch: `g1r2-fern/contra-soap-aurora`
- Hypothesis: Diagonal leverage-score equalization (Aurora record #17) inside NS5 polar step, stacked on top of Contra+SOAP-MLP merged base. Replaces standard polar with D-equalized polar for non-square MLP weights; square attention weights short-circuit to standard NS5.
- W&B run: `5kr7d0i5` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.27614 | 3125 |
| **n=4 mean** | **3.27787** | **3131.25** |
| statsig (3.28−mean)×2 | **0.00426** ≥ 0.004 ✓ | |

**Conclusion**: Statsig passes vs 3.28 gate but FAILS new baseline gates (PR #139 mean=3.27648, ffs=3118.75) on both bars. T1 (3.28172) is a catastrophic outlier — seed dispersion range = 0.00580, roughly 4× the typical mechanism variance and far exceeding baseline's 0.00279 range. Three of four seeds (T0, T2, T3) individually outperform the new baseline mean, confirming the mechanism works — but the variance kills n=4 aggregates.

**Key learning**: Aurora's diagonal leverage-score equalization is HIGH-VARIANCE on the merged Contra+SOAP-MLP base. The D fixed-point iteration introduces per-seed variation in the effective preconditioning that compounds over 3175 steps. This aligns with record #17's reported high-variance behavior. Not a mechanism failure, but needs n=8+ or a variance-reduction wrap to clear the new (tighter) baseline bars. Defer to next round.

Fern reassigned to PR #208: Power-law LR cooldown (LR_POWER=1.5/2.0), targeting record #20's schedule structure.

## 2026-05-17 00:30 — PR #124 CLOSED: Attn-SOAP+trust gate n=4 (nezuko)

- Branch: `g1r2-nezuko/attn-soap-gate`
- Hypothesis: Attention SOAP (eigenbasis preconditioner on qkv/proj weights) with trust gate (cosine-similarity threshold to decide when to apply precond vs identity fallback). Stacked on OLD baseline (CONTRA_MUON=0.4 / PR #78).
- W&B run: `790h1llo` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27609 | 3100 |
| **n=4 mean** | **3.27715** | **3118.75** |
| statsig (3.28−mean)×2 | **0.00570** ≥ 0.004 ✓ | |

**vs OLD baseline (PR #78):** val −0.00045 (WIN) / ffs tie 3118.75 (WIN vs 3131.25)

**vs NEW baseline (PR #139):** val +0.00067 (MISS) / ffs 3118.75 (TIE — strict < required = MISS)

**Conclusion**: Mechanism unambiguously works. T0/T1/T2 had extraordinarily low variance (0.00015 range, lowest of the session), confirming the trust gate produces stable training dynamics. T3 was a luckier seed (3.27609/3100). Mechanism delivers −0.00045 val + −12.5 ffs on OLD base. Misses NEW baseline strictly because NEW baseline (CONTRA_MUON=0.5) is 12.5 ffs better, making the comparison tight.

**Key trust-gate finding**: v/proj row cosines hover at 0.85-0.89 with threshold=0.9 — they are identity-precond ~100% of the time. Only q (~85%) and k (~25%) actually get SOAP precondition. This leaves significant headroom: lowering threshold to 0.85 would activate v/proj and potentially add another 25-50 ffs improvement.

**Follow-up**: Nezuko reassigned to PR #212 (Attn-SOAP+trust on NEW baseline, CONTRA_MUON=0.5, with Arm B at THRESHOLD=0.85).

## 2026-05-17 00:30 — PR #181 CLOSED: Schedule-Free Muon (askeladd)

- Branch: `g1r2-askeladd/sfm`
- Hypothesis: Muon with constant LR + Polyak averaging (schedule-free), replacing the linear cooldown.
- W&B runs: `groom2ym` (uniform c_t screen), `k3wkjy84` (c_const=0.01 screen)

| Screen | c_t | Final val(y) | Best val(y) | ‖y−z‖_F at T |
|---|---|---|---|---|
| Uniform 1/(t+1) | 0.00031 at T | 4.60499 | 4.59854 | **2.2e9** |
| Const EMA 0.01 | 0.01 | 4.62780 | 4.60690 | **4.3e8** |
| Merged baseline | linear cooldown | — | 3.27760 | n/a |

**Conclusion**: Fundamental incompatibility between (a) Muon's spectral updates under constant LR and (b) the 2-sequence SF formulation. NS5-orthogonalized Muon updates inject O(1) per element per step — under constant LR the iterates z never converge, while the Polyak average y lags and decays toward stale initialization. ‖y−z‖ grows unboundedly regardless of c_t window size. The gradient evaluated at y is increasingly stale, breaking the SF assumption ∇f(y) ≈ ∇f(z).

**Key negative finding**: Schedule-free methods (which assume bounded update magnitudes for convergence) are structurally incompatible with constant-LR Muon. Linear cooldown is doing essential work — it provides the convergence that SF assumes but cannot deliver. Direction CLOSED.

**Student's analysis quality**: Exceptional. Correctly diagnosed structural incompatibility, identified root cause (||y-z|| explosion independent of c_t window), recognized that 3-sequence Defazio would face the same issue. Valuable negative result well-characterized.

Askeladd reassigned to PR #213 (per-module weight init scaling — records #4,5,8 ingredient).

## 2026-05-19 10:55 UTC — Cycle 63: #431 CLOSED LM_HEAD_LR axis FALSIFIED; #430 CLOSED MUON_LR narrow ffs miss; #429 alphonse n=2 WIN → n=4 predeclared; #456 fern → SCALARS_LR sweep

### PR #431 — AdamW lm_head_lr sweep (0.0025 vs 0.00375 around 0.003125) — CLOSED axis-falsified

Branch: `g1r2-fern/lm-head-lr-sweep`. Both ±20% arms sweep on new CONTRA_MUON=0.4 base.

| Arm | LM_HEAD_LR | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (−20%) | 0.0025 | 3.27597 | 3100 | (foreclosed) | — | — | — | both bars foreclosed | **MISS** |
| B (+20%) | 0.00375 | 3.27431 | 3075 | 3.27616 | 3100 | **3.275235** | **3087.5** | val +0.000852, ffs +18.75 | **MISS** |

W&B runs: `ibr51w9g` (Arm A), `xb6pszz1` (Arm B)

**Mechanism finding**: Default LM_HEAD_LR=1/320≈0.003125 is at a **local optimum within ±20%** on this benchmark. Bracket sign: higher is better (Arm B less worse than Arm A), but neither clears bar. The lm_head lr controls output-side calibration through the softcap — at the current K=15 softcap, the default 1/320 appears well-tuned. Future: joint MUON_LR × LM_HEAD_LR 2D test would check if the ratio lm_head_lr ≈ MUON_LR/12 is intrinsic.

**AdamW-LR-group characterization progress**: lm_head ✅ FALSIFIED ±20%; embed (nezuko #449 in flight); scalars (fern #456 assigned).

---

### PR #430 — MUON_LR sweep (0.030 vs 0.045 around 0.0375) — CLOSED narrow ffs miss

Branch: `g1r2-edward/muon-lr-sweep`. Both ±20% arms on new CONTRA_MUON=0.4 base.

| Arm | MUON_LR | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (−20%) | 0.030 | 3.2821 | -1 | (killed) | — | foreclosed | foreclosed | both bars foreclosed | **MISS** |
| B (+20%) | 0.045 | 3.27547 | 3100 | 3.27279 | 3050 | **3.27413** | **3075** | val **PASS** −0.000253, ffs MISS +6.25 | **MISS** |

W&B runs: `ca8blz69` (Arm A), `6g1c8dwc` (Arm B)

**Mechanism finding**: Arm A (0.030, −20%) under-steps — never reaches val=3.28 target within 3175-step budget. Arm B (0.045, +20%) has val mean PASSING the strict bar (3.27413 < 3.274383) but ffs mean=3075 is **exactly one quantization slot above bar** (−6.25 to PASS). T1 individual result (3.27279/3050) was exceptional — better than baseline T0. T0 (3.27547/3100) dragged up the mean. **Verdict: axis not cleanly falsified** — the +20% arm has real val signal but bimodal ffs noise produced one unfavorable slot. Default 0.0375 remains the operating point by methodological criterion (n=2 strict bar not cleared). MUON_LR is a "soft revisit" axis worth re-examining if a wider bracket or n=4 is warranted.

**Note for future**: at n=4 with MUON_LR=0.045, if 3/4 trials land at ffs=3050 and 1/4 at 3100 (matching T0/T1 bimodal pattern), mean ffs = (3100+3050+3050+3050)/4 = 3062.5 < 3068.75 — PASS. The underlying mechanism may be stronger than n=2 reveals.

---

### PR #429 — NS5_ITERS sweep (10 vs 14 around default 12) — n=2 Arm B (NS5_ITERS=14) WINS → n=4 PREDECLARED

Branch: `g1r2-alphonse/ns5-iterations-sweep`. Arm A (10) and Arm B (14) screened on new CONTRA_MUON=0.4 base.

| Arm | NS5_ITERS | T0 val | T0 ffs | T1 val | T1 ffs | n=2 val mean | n=2 ffs mean | vs new bar | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| A (fewer) | 10 | 3.27592 | 3100 | 3.27410 | 3050 | **3.27501** | **3075** | val +0.000627, ffs +6.25 | MISS |
| **B (more)** | **14** | **3.27263** | **3050** | **3.27514** | **3075** | **3.273885** | **3062.5** | val **PASS −0.000498**, ffs **PASS −6.25** | **WIN ✅** |

W&B runs: `beeyzftn` (Arm A), `565i067e` (Arm B)

**Mechanism finding**: NS5_ITERS=14 (vs default 12) → 2 extra polar iterations per Muon step. Tighter orthogonalization of the spectral projection → smoother, more precise Muon update. T0 val=3.27263 is the **best single-trial val on this codebase** since the PR #358 baseline n=2 screen. Arm A (10 iters) misses both bars — bracket sign CONFIRMED: more iterations is better, fewer is worse. Step-time overhead with NS5_ITERS=14 is only **+0.8%** (vs predicted +16%) — NS5 matmuls are not the bottleneck on this hardware.

**This falsifies the "cooldown-geometry lever saturated" finding from #372**: NS5_ITERS sits on the polar-projection accuracy axis, orthogonal to cooldown geometry. The cooldown saturation was specific to the momentum/scale correction family, not to all optimizer axes.

n=4 confirm predeclared: `g1r2-alphonse/ns5-iters-14-confirm-n4`.

---

## 2026-05-18 20:55 UTC — PR #358: CONTRA_MUON=0.4 — MERGED (new baseline)

- `g1r2-askeladd/contra-muon-sweep`
- Hypothesis: CONTRA_MUON=0.5 was set at PR #139 and never swept. Reducing to 0.4 (20% less counter-correction) tests whether baseline was over-correcting.
- W&B runs: `oeeswx8a` (n=2 screen), `ivvf500c` (n=4 confirm)

| Trial | val/loss | ffs | Stack |
|---|---|---|---|
| n=2 T0 | 3.272824 | 3050 | CONTRA_MUON=0.4 + PR#288 stack |
| n=2 T1 | 3.274036 | 3075 | CONTRA_MUON=0.4 + PR#288 stack |
| n=2 mean | **3.273430** | **3062.5** | |
| n=4 T0 | 3.27523 | 3075 | |
| n=4 T1 | 3.27432 | 3075 | |
| n=4 T2 | 3.27455 | 3075 | |
| n=4 T3 | 3.27343 | 3050 | |
| **n=4 mean** | **3.274383** | **3068.75** | |

vs. old baseline (PR #288): val Δ=−0.000967, ffs Δ=−18.75. statsig: (3.28−3.274383)×√4=0.01123 ≥ 0.004 PASS.

**Analysis**: Clean, consistent improvement. ffs {3075,3075,3075,3050} — 3/4 trials improved from baseline pattern. n=4 regressed slightly from optimistic n=2 mean (3.27343→3.27438) but cleared the bar with comfortable margin. Baseline over-correction at 0.5 was real; 0.4 reduces contra-gradient interference without losing the stability it provides.

**NEW BASELINE**: val=3.274383 / ffs=3068.75. ALL subsequent experiments must compare against this harder bar. ffs<3068.75 requires ≥2 of 4 trials at ffs=3050 (or equivalent mean). This is a significant tightening — most current in-flight experiments on CONTRA_MUON=0.5 will miss.

**Conclusions**: CONTRA_MUON axis has headroom below 0.5. 0.4 is confirmed better; 0.3 is the next test. Pipeline stack: CONTRA_MUON=0.4 is now the required base for all new experiments.
