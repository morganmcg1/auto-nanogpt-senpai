# SENPAI Research State — auto-nanogpt-1gpu-r3

**Last updated:** 2026-06-02 11:05 UTC (cycle ~2700, 239 cumulative NULL/NEG/TIE closures + 1 MERGED WIN; H389 alphonse + H392 edward + H393 thorfinn all assigned; 7-PR portfolio active, 0 idle students)

## Most recent research direction from human researcher team

No new directives in current invocation. Issue #1260 strict FFS<3000 merge gate remains active. Issue #2122 Aurora research nudge fully resolved (H366 + H373 closures confirmed AURORA-MECHANISM-STACK-CONDITIONAL class). Human team last commented on Issue #1260 on 2026-05-29 confirming H266 breakthrough; subsequent advisor updates have been one-way.

## Current research focus and themes

### Baseline state
- **🏆 BASELINE**: PR #1669 H266 Polyak-Ruppert EMA all-params decay=0.05 (merged 2026-05-28)
  - val/loss = 3.26818, FFS = 3000, σ_H174 = 0.000884
  - Reproduce: `torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --train_steps 3325 --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6 --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_beta2_schedule constant --aux_beta2_start 0.99 --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05`

### Cycle ~2700 status (cumulative)
- **239 cumulative NULL/NEG/TIE closures**, 1 MERGED WIN (H266) — H381+H383+H382 closed within last ~90 min on outer-loop + PEMA-substrate mechanism axes
- **21 HARD-LOAD-BEARING family entries**: H368/H375/H282/H169/H370/H374/H376/H377/H378/H379v2/etc. (H380, H381, H382, H383 stay MILDLY-LOAD-BEARING)
- **1 U-SHAPE-CHARACTERIZED-AXIS class entry with PRODUCTIVE-BAND-EDGE LOCALIZATION** (H372 Adan β₃ axis, U-shape minimum at β₃=0.95, band edge β₃∈(0.9, 0.95), no FFS gain at any β₃)
- **1 GRADIENT-LAYOUT-CENTERING class entry** (H378 GC on BODY MuonH pre-NS5 — paper-grade NS5+scale_invariant redundancy mechanism explanation, bidirectional GC over-flattens)
- **AUX/BODY adaptive-scaling preconditioner family BROADLY CANALIZED across 6 axes** (programme-level claim post-H371_b1):
  - H371 LaProp (operation-order reorder): CANALIZED-TIE-with-MILD-POSITIVE-DRIFT at β₁=0.8, NEG on β₁ departure
  - H372 Adan β₃ (3rd-moment EMA): U-shape, productive band [0.95, 0.99], no FFS gain
  - H376 Sophia-H ρ (Hessian-diag): +16-29σ NEG
  - H369 Lion LR: CATASTROPHIC
  - H375 Schedule-Free: BILATERAL CATASTROPHIC
  - H368 AdEMAMix α (slow EMA): MONOTONE NEG
- **5 INIT-side closures**: H351 + H357 + H365 (HARD-LOAD-BEARING) + H366 Aurora + H373 LSUV (TIE AURORA-STACK-CONDITIONAL)
- **4 CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entries**: H371 arm_c LaProp eps=1e-8 (CLOSEST-TO-BASELINE, −0.16σ vs H266) + H372 arm_c Adan β₃=0.95 + H373 arm_c LSUV_STRICT + **H380 arm_c PE8** (val=3.26876, +0.66σ vs H266, 32nd Pattern A +25 cluster anchor)
- **3 MONOTONE DOSE-RESPONSE NEG class entries on continuous parametric axes**: H368 AdEMAMix α + H370 QHM ν + H378 gc_mode {0,1,2}
- **2 AURORA-MECHANISM-STACK-CONDITIONAL class entries**: H366 + H373
- **1 BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis**: H375 Schedule-Free (joins H368 AdEMAMix + H282 AdaBelief in 3-leg programme finding)
- **1 K-INVARIANT STRONG NEG class entry on α-interpolation magnitude axis (H377)**: Lookahead AUX wrapper, 1st OUTER-on-AUX probe at H266 stack
- **3rd STRUCTURAL-TIMING-AXIS NEG class entry (H374 WSD)**: 4 LR-schedule axes now confirmed canalized
- ~34 candidate H266 attractor cluster anchors (H383 arm_a CTRL val=3.26926 FFS=3025 +25 = 34th post-H381; H381 arm_a CTRL val=3.26739 FFS=3000 EXACT = 33rd; H380 arm_c PE8 val=3.26876 FFS=3025 Pattern A +25 = 32nd)
- **13-axis OUTER-LOOP mechanism canalization** (joint H91/H99/H100/H101/H103/H108/H111/H113/H116 closure cluster + H379v2 LION OUTER + H381 PER-PARAMETER ALLOCATION + H382 TRAJECTORY-RESET-on-OUTER closures): MuLoCo Nesterov-SGDM(μ=0.5, outer_lr=0.7, sync_interval=30) is at-optimum across 13 mechanism axes of outer-loop variation at H266 stack. **6-axis mechanism map at H266 stack**: SCHEDULE (H289) + BLENDING (H370) + RESET-on-AUX (H377) + FORM-LION (H379v2) + PER-PARAMETER ALLOCATION (H381) + TRAJECTORY-RESET-on-OUTER (H382 — NEW). H384 tanjiro FREQUENCY axis + H387 fern periodic RESET still IN-FLIGHT.
- **PER-SHAPE PEMA DECAY axis 1st explored, BLOCKS subset CANALIZED at uniform 0.05** (H383 post-finding): 2× faster captures NS5 orthogonalization noise (mechanism-consistent with H378 GC redundancy); 2× slower below extraction floor. Future per-shape PEMA differentiation may still have headroom on embed/lm_head/scalars sub-axes (untested in H383), but BLOCKS subset closure is strong programme signal remaining axes unlikely to yield WIN.
- **TRAJECTORY-PRESERVATION dichotomy extended from AUX to OUTER scope** (H382 post-finding): TRAJECTORY-RESET on OUTER scope = TIE-on-FFS at best (mode=1 all-params) or NEG (mode=2 body-only); confirms H266 stack's outer optimizer is TRAJECTORY-PRESERVING. H387 fern periodic RESET (in-flight) tests FREQUENCY dimension of same axis; H382 TIE-at-best suggests H387 periodic variants likely TIE-or-NEG (informed-NEG prior).

### Programme-level mechanism findings (paper-grade, post-H266)

**PF#61 — AUX preconditioner FORM/wrapper axis CLOSED at 5 axes**:
- preconditioner FORM (H260/H261/H268)
- LAMB wrapper (H277)
- eps calibration (H272)
- per-group LR scale (H203)
- within-formula denominator semantics (H282 AdaBelief CATASTROPHIC)

**PF#62 — cooldown-decoupling structural rigidity at 11 mechanism categories**:
- phase-gated wrappers (H271 catastrophic)
- scope changes (H274, H290)
- gradient noise injection
- pre-NS5 sign-masking (H280)
- (and 7 others)

**3-leg H266 multi-axis averaging incompatibility finding** (H282 + H368 + H375):
H266's averaging stack (Polyak-Ruppert EMA + AUX β₁ EMA + outer momentum SGDM + scale_invariant MuonH F-norm preservation) is HARD-INCOMPATIBLE with AUX-side iterate averaging (Schedule-Free) or dual-EMA augmentation (AdEMAMix) or momentum-deviation-variance (AdaBelief). Cosine AUX cooldown is the ONLY compatible AUX cooldown mechanism explored.

**INIT-side AURORA-STACK-CONDITIONAL finding** (H366 + H373):
`scale_invariant` MuonH F-norm preservation is a STRONG canalizer for INIT-side variance/row-norm equalization mechanisms. Aurora alternating row-norm projection AND LSUV depth-cascade variance rescaling both produce TIE-on-FFS via the same canalization mechanism.

**LaProp eps=1e-8 anchor = CLOSEST-TO-BASELINE arm of cycle ~2700** (H371 arm_c, val=3.26804 = −0.16σ vs H266). Sent back for β₁ axis follow-up at LaProp eps=1e-8 anchor.

**3-point monotone AUX adaptive-scaling axis gradient** (H369+H376):
- Lion CATASTROPHIC (no per-param scaling): H369
- Sophia-H STRONG NEG +16-29σ (Hessian-diag per-param): H376
- AdamW BASELINE (g²-diag per-param): H266
Finding: H266 AUX path specifically requires gradient-variance (g²-diag) per-param scaling — Hessian-diag is nearest cousin and still fails +16σ.

**4 LR-schedule structural-timing axes fully canalized** (H352+H362+H363+H374):
All 4 tested structural-timing axes of the H266 LR schedule are canalized: cooldown SHAPE (H352 cosine optimum), warmup DURATION (H362 bilateral asymmetric NEG), μ_start TIMING (H363 bilateral asymmetric NEG), cooldown DURATION (H374 monotonic-asymmetric NEG). WSD (Warmup-Stable-Decay), even at MiniCPM canonical 70/30 ratio, is catastrophically NEG at 3325-step short-budget. Further LR-schedule probes are unlikely to yield WIN candidates.

**TRAJECTORY-PRESERVATION vs TRAJECTORY-RESET dichotomy on outer-step mechanism family** (H377):
Outer-step mechanisms split at H266 stack: BODY μLoCo (Nesterov-momentum-corrected direction, fast NOT reset) = TRAJECTORY-PRESERVING → WIN load-bearing. AUX Lookahead α=0.5 (`slow += α·(fast - slow)` then `fast ← slow`, partial trajectory reset) = TRAJECTORY-RESETTING → +10σ STRONG NEG K-INVARIANT (K∈{10, 30} both fail within 0.52σ_H174). Complements H266 + H267 Polyak-Ruppert finding: AUX-side iterate averaging WINS only at terminal weights (PEMA decay=0.05 eval-time); applied throughout training (Lookahead) it drags warmed-up adaptive m/v state back toward stale slow-weight positions. H266 AUX is canalized to single-EMA AdamW with no outer reset.

**GRADIENT-LAYOUT-CENTERING canalized at H266** (H378):
Yong et al. 2020 Gradient Centralization on BODY MuonH pre-NS5 grads is mechanism-redundant + harmful at H266 stack. Three converging redundancy effects:
1. NS5 polar step orthogonalization removes the rank-1 mean component as a side effect → explicit pre-NS5 GC is mechanism-redundant
2. scale_invariant Frobenius renormalization already standardizes update magnitude → centering before this adds no benefit
3. Bidirectional GC (input AND output dim) over-flattens → arm_c GC_BOTH MID NEG +3.18σ_H174
CV-domain GC gains do NOT transfer to LM domain when the optimizer already orthogonalizes implicitly. Consistent with mixed LM-domain GC results in NaG/AdaBelief variants.

**AUX adaptive-scaling preconditioner family BROADLY CANALIZED at 6 axes** (H371_b1 closure post-finding):
No axis tested to date breaks strict FFS<3000 via per-coordinate gradient pre-conditioning alone at H266 stack. LaProp paper-default β₁=0.9 is the WORST arm of its 3-arm chain at +5.37σ vs CTRL — paper recommendation does NOT transfer to H266. Pivot AUX exploration to non-preconditioner axes: cross-scope state coupling (H385 in flight), schedule axes, 2D eps × momentum interaction probes.

**NS5/orthogonalization axis CANALIZED across STATIC + ADAPTIVE polynomial families** (H380 closure post-finding, paper-grade joint H88+H380 programme-level):
- STATIC polynomial-Schulz family `(a, 2.5−2a, a−1.5)` `a∈(2.0, 3.0)` at degree-3 cubic k=12 (H88 OLDER stack pre-H266) — no headroom
- ADAPTIVE minimax-Remez precomputed degree-5 quintic coefficients via Amsel et al. arXiv:2505.16932 (H380 H266 stack) — no headroom
Despite verified 7× lower orthogonality residue on synthetic ill-conditioned matrices, the cleaner polar factor is DOWNSTREAM-INERT at H266 stack. The H266 stack's other ingredients (scale_invariant MuonH F-norm preservation, AGC clip_ratio=0.05, outer momentum 0.5, Polyak EMA 0.05) already supply sufficient orthogonality budget. **1st observation of "polar-factor over-purification"**: within-chain monotonic ordering arm_c PE8 (k=8) < arm_a NS5/k=12 ≈ arm_b PE12 (k=12) on val/loss, with arm_c PE8 producing −1.63σ_H174 within-chain improvement vs NS5/k=12 at FFS=3025 (Pattern A +25 cluster anchor). Sub-saturation at k=8 leaves residual gradient signal that the H266 stack's downstream consolidation absorbs more productively than fully orthogonalized k=12 updates. Note: H386 nezuko's NS5 Iter Count Cooldown Schedule tests time-varying version of this insight.

**LION-AXIS FULL CLOSURE across all 3 optimizer scopes** (H379v2 closure post-finding, paper-grade programme-level):
Sign-only Lion mechanism rejected at every optimizer scope at H266 stack:
- AUX scope: H169 CATASTROPHIC + H241 NEG + H260 NEG + H369 CATASTROPHIC (cycle ~2700 round)
- BODY scope: H260 NEG
- OUTER scope: H379v2 arm_b LION_OUTER_DEFAULT_LR +3093σ CATASTROPHIC + arm_c LION_OUTER_TUNED_LR +225σ STRONG NEG
Sign-only updates discard magnitude information that all 3 optimizer scopes load-bearingly use (AUX fine per-coordinate variance signal, BODY orthogonalized polar magnitudes for NS5/scale_invariant, OUTER drift-magnitude proportional consolidation moves per H108 closure). The mechanism class is genuinely scope-invariant in its rejection direction — sign-only step is fundamentally incompatible with H266 stack across all 3 scopes. Even down-scaling outer_lr 14× (0.7 → 0.05) does not recover, confirming rejection is mechanism-driven not magnitude-driven. Cross-link to H108 closure: Lion-form OUTER is the EXTREME of magnitude collapse; rejection direction is the orthogonal complement of H108 trust-region clipping rejection (both directions reject "outer step magnitude should be limited or ignored").

### In-flight 8-PR portfolio + 0 idle students (snapshot 2026-06-02 11:05Z)

| PR | Student | Hypothesis | Status | Notes |
|----|---------|-----------|--------|-------|
| #2247 | frieren | H385 AUX→BODY v_t cross-axis coupling | WIP | First CROSS-OPTIMIZER STATE COUPLING probe. arm_b DIRECT s_t/s_anchor running, arm_c INVERSE pending. Student caught math bug: `update *= coupling_s_t` is NO-OP in scale_invariant mode; corrected to `lr *= coupling_s_t`. Smoke gate verified all 3 arms Pattern A bit-id. |
| #2242 | tanjiro | H384 WSD-Scheduled Outer Sync Interval (FREQUENCY axis) | WIP | Varies sync_interval between stable (30) and cooldown phases. RTX PRO 6000 Blackwell hardware vs H100 baseline; 0.0079 nat noise at 125 steps characterized pre-launch. |
| #2246 | nezuko | H386 NS5 Iter Count Cooldown Schedule | WIP | First SCHEDULE-DRIVEN NS5 iter count probe. arm_a CTRL FINISHED val=3.26904 FFS=3025 (+0.97σ NULL Pattern A +25 = 29th cluster anchor candidate); arm_b LATE_16 running 56% at 10:56Z; arm_c LATE_8 pending. Time-varying version of H380 "polar-factor over-purification" within-chain finding. |
| #2254 | fern | H387 Outer SGDR Warm Restarts (periodic outer_velocity reset) | WIP | Periodic outer_velocity zero-reset every N inner steps. arm_b SGDR_500 (6 events) / arm_c SGDR_1000 (3 events). Mechanism-distinct from H382 single-event RESET — informed-NEG prior. |
| #2259 | askeladd | H388 v2 Per-Aux-Group Cooldown Fraction Decoupling (lm_head independent schedule) | WIP | First per-aux-group schedule-axis intervention at H266 stack per H130 line 9584 explicit future direction. arm_b LH_EARLY cf=0.65 / arm_c LH_LATE cf=0.20. Smoke gate verified mechanism active (lm_head LR cleanly decoupled at smoke step-125). |
| #2264 | alphonse | H389 AUX AdamW Warmup Schedule (symmetric to MuonH warmup) | WIP | First WARMUP CURVE SHAPE on AUX probe at H266 stack — completely untested axis. ~10 LoC sentinel-gated branch. arm_a CTRL warmup=0 (bit-id) / arm_b warmup=100 / arm_c warmup=300. Verified novel against H262/H362 BODY warmup + H324 OUTER warmup + 6 AUX preconditioner axes. ~11% WIN. |
| **#2267** | **edward** | **H392 MuonH cooldown_shape `cosine_squared` (deferred student suggestion L7625)** | **WIP** | **NEW** — explicit student-suggested follow-up from H139 cooldown analysis never actioned. Prior 12-arm sweep (L16311) tested {linear, cosine, sqrt, quadratic}; cosine_squared = (0.5·(1−cos(πc)))² has MID-aggression profile (eta drops faster than cosine but smoother than quadratic). 5 LoC choice-list + 2 LoC formula branch. arm_a CTRL cosine (bit-id) / arm_b COSINE² / arm_c COSINE² × cooldown_frac=0.5. Assigned 2026-06-02 10:55Z. |
| **#2268** | **thorfinn** | **H393 PROJECTION-at-OUTER NS5 orthogonalization on MuLoCo step direction** | **WIP** | **NEW first PROJECTION-axis probe at OUTER scope** — verified novel (0 hits on `outer.*ns5\|orthogonalize.*outer`). 13 prior OUTER closures all on scalar/vector axes; H393 first matrix-PROJECTION axis. arm_a CTRL ortho=0 (bit-id) / arm_b ortho=1 NS5 + F-norm preserve / arm_c ortho=2 50/50 blend safety net. Body 2D weights only (`"blocks" in n`). Mechanism-distinct from H379v2 Lion sign-FORM (per-element vs whole-matrix spectral). Assigned 2026-06-02 11:00Z. |

### Process incident — replacement-researcher codepath mismatch (2026-06-02 10:30Z)

Replacement researcher-agent `a85b13b2318034c34` (spawned to find 2 alternative axes for edward + thorfinn after H390 SWA + H391 AGC schedule REJECTED) returned 2 proposals targeting a **WRONG codebase**: the proposals referenced `polar_express`, `_apply_normuon_variance_reduction`, `mantissa` BF16 buffer, and `momentum_buffer` — all NorMuon-family infrastructure. Grep verification on the active H266 baseline `records/track_3_optimization/train_gpt_simple.py` returned **0 matches** for any of those identifiers (40 hits on `muonh_mode|scale_invariant|MuonH` confirms MuonH-SI is the live optimizer). The NorMuon references trace to `records/track_3_optimization/results/20260504_muloco_normuonh/` historic record artifacts, not the active code.

**Both proposals REJECTED as codepath-mismatch.** Replaced with manually-verified axes (H392 + H393) via direct codebase grep. Saved feedback memory `feedback_researcher_codepath_verification.md` to guard future cycles. Cost: ~30 min of advisor cycle wasted on the 2nd researcher round but 0 GPU-time wasted (caught at advisor side before student smoke gate).

### Recent closure cadence (last 12 hours)

- **PR #2228 H382 thorfinn Outer Velocity Reset at Cooldown Entry** — CLOSED 239th NULL/TIE (🎯 OUTER-VELOCITY RESET-AT-COOLDOWN-ENTRY axis CANALIZED at H266 stack, TIE-on-FFS at best mode=1, mode=2 body-only NEG +3.25σ, 6-mechanism-axis OUTER-LOOP family closure with TRAJECTORY-PRESERVATION dichotomy refinement extended from AUX to OUTER scope, student honestly flagged within-chain CUDA RNG drift contamination + corrected H170 misclassification in PR brief — paper-grade engineering rigor)
- **PR #2229 H383 edward Per-Shape Polyak-Ruppert EMA Decay (BLOCKS subset)** — CLOSED 238th NULL/NEG (🎯 PER-SHAPE PEMA BLOCKS-DECAY axis CANALIZED at uniform 0.05, 1st per-shape PEMA decay probe at H266 stack, programme-level link to H378 GC redundancy mechanism — 2× FASTER captures NS5 orthogonalization noise +2.50σ, 2× SLOWER below extraction floor +1.45σ INDISTINGUISHABLE from CTRL, 28th H266 cluster anchor at arm_a CTRL FFS=3025)
- **PR #2224 H381 alphonse Per-Param Outer LR/Momentum (body vs aux differentiated)** — CLOSED 237th NULL/NEG (🎯 PER-PARAMETER OUTER ALLOCATION axis CANALIZED at H266 stack with bilateral asymmetric NEG, 12-axis OUTER-LOOP mechanism canalization joint with H91-H116 + H379v2 + H381, 5-axis outer-loop mechanism map at H266 stack: SCHEDULE/BLENDING/RESET-on-AUX/FORM-LION/PER-PARAMETER ALLOCATION all closed; 1st observation of OUTER-CORRECTION OVER-DAMPING on body 2D weights — arm_b body_outer_lr=1.4 = +124.7σ STRONG NEG; asymmetric damage profile arm_c (body=0.35/aux=1.4) +43.3σ NEG << arm_b (body=1.4/aux=0.7) +124.7σ STRONG NEG suggests body MORE sensitive to outer correction than aux; arm_a CTRL val=3.26739 FFS=3000 EXACT = 33rd H266 cluster anchor)
- **PR #2221 H380 askeladd Polar Express minimax-adaptive NS5** — CLOSED 236th NULL/TIE (🎯 NS5/orthogonalization axis CANALIZED across STATIC (H88) + ADAPTIVE (H380) polynomial families joint closure, 4th CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entry on arm_c PE8 val=3.26876 FFS=3025 +0.66σ, 1st "polar-factor over-purification" observation at H266 stack via within-chain monotonic ordering PE8 < NS5/k=12 ≈ PE12, 7× lower orthogonality residue on synthetic ill-conditioned matrices verified at smoke-gate but DOWNSTREAM-INERT at H266 stack)
- **PR #2211 H379v2 fern Lion OUTER (sign-only outer-step form)** — CLOSED 235th NULL/NEG (🎯 PROGRAMME-LEVEL LION-AXIS FULL CLOSURE across all 3 optimizer scopes AUX+BODY+OUTER, 21st HARD-LOAD-BEARING family entry, 11-axis OUTER-LOOP mechanism canalization joint with H91-H116 closure cluster + H379v2, arm_b lion/0.7 +3093σ CATASTROPHIC + arm_c lion/0.05 +225σ STRONG NEG, sign-only mechanism rejection is scope-invariant and not LR-magnitude-driven, cross-link to H108 outer trust-region closure)
- **PR #2157 H371_b1 frieren LaProp β₁ axis @ eps=1e-8** — CLOSED 234th NULL/NEG (LaProp β₁ axis CLOSED on STRICT MONOTONE NEG, 6-arm 2-round combined screening complete, AUX adaptive-scaling preconditioner family BROADLY CANALIZED across 6 axes — programme-level finding)
- **PR #2202 H378 nezuko Gradient Centralization BODY pre-NS5** — CLOSED 233rd NULL/NEG (1st GRADIENT-LAYOUT-CENTERING class entry + 3rd MONOTONE DOSE-RESPONSE NEG class joining H368/H370, paper-grade NS5+scale_invariant redundancy mechanism explanation, 30th H266 cluster anchor)
- **PR #2158 H372v2 tanjiro Adan BODY β₃ dose-response extension** — CLOSED 232nd NULL/NEG (1st U-SHAPE-CHARACTERIZED AXIS with PRODUCTIVE-BAND-EDGE LOCALIZATION class entry; arm_a CTRL v2 = TIGHTEST CTRL anchor of cycle ~2700 at +0.04σ vs H266)
- **PR #2187 H377 edward Lookahead AUX wrapper** — CLOSED 231st NULL/NEG (20th HARD-LOAD-BEARING family entry, 1st K-INVARIANT STRONG NEG class on α-interpolation magnitude axis, 1st OUTER-on-AUX probe at H266 stack, 1st TRAJECTORY-PRESERVATION vs TRAJECTORY-RESET dichotomy refinement)
- **PR #2182 H376 thorfinn Sophia-H AUX** — CLOSED 230th NULL/NEG (19th HARD-LOAD-BEARING family entry, 2nd-order Hessian-diag preconditioner axis closed, 3-point monotone gradient on AUX adaptive-scaling axis: Lion CATASTROPHIC → Sophia STRONG NEG +16-29σ → AdamW BASELINE)
- **PR #2172 H374 alphonse WSD BODY MuonH** — CLOSED 229th NULL/NEG (18th HARD-LOAD-BEARING family entry, 3rd STRUCTURAL-TIMING-AXIS NEG, 4th LR-schedule axis canalized)
- **PR #2173 H375 askeladd Schedule-Free AUX** — CLOSED 228th NULL/NEG (paper-grade 1st BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis)
- **PR #2165 H373 fern LSUV BODY init** — CLOSED 227th NULL/TIE (2nd AURORA-MECHANISM-STACK-CONDITIONAL class entry)

### Recent advisor process incidents
- **2026-06-02 ~01:28Z**: assigned fern H379 AdaBelief AUX as "fresh AUX mechanism" — duplicate of H282 paper-grade closure. Aborted at T+45min, pivoted to H379v2 LIONS_OUTER.
- **2026-06-02 ~02:30Z**: researcher-agent assigned H380 Polar Express without addressing H88 PR #889 (polynomial-Schulz polar-map family closure at older stack). H88 closure is at PRE-H266 stack (permissible to re-test), mechanism distinction is genuine (runtime-adaptive vs static-fixed). Added H88 caveat comment to PR #2221.
- **2026-06-02 ~10:20Z**: 3fresh_axes researcher-agent (`a338cb49462eb4c73`) proposed H389 (NOVEL ✓ AUX AdamW warmup), H390 (REJECTED — SWA-style uniform window averaging duplicates H153 strategy-tier EMA closure "Strategy-tier shift away from any EMA/averaging variant warranted", K-monotone harm scaling 3.6×, + 6-level weight-averaging family closures H53/H75/H77/H85/H101/H104), H391 (REJECTED — AGC clip_ratio SCHEDULE duplicates H149 full-trajectory linear ramp 0.10→0.02 BILATERAL NULL + H157 cooldown-confined ramp end=0.01-0.02 BILATERAL NULL with explicit "AGC clip_ratio schedule axis closed; mechanism saturated"). Researcher's orthogonality table listed H323/H267/H332/H383 (related EMA family) for H390 but MISSED the strategy-tier H153 closure, and listed H361/H353 (static VALUE axes) for H391 but MISSED H149+H157 schedule axes. H389 assigned to alphonse as PR #2264. Spawned replacement researcher `a85b13b2318034c34` with explicit reject list including H153 + H75/H77/H85/H101/H104/H120/H125/H127/H136/H144 weight-averaging family + H149/H157 AGC schedule + 8 untested mechanism categories (PROJECTION, MEMORY-at-outer, NUMERICS, GRADIENT NOISE at OUTER, CROSS-AXIS COUPLING beyond AUX→BODY, PER-SHAPE PEMA embed/lm_head/scalars, GRADIENT TRANSFORMATIONS pre-AUX/pre-OUTER, MUONH INNER-STATE recycling) for edward + thorfinn rank-1/rank-2.
- **Process improvement**: dedup-grep memory `feedback_dedup_grep_before_aux_optimizer_assign.md` broadened from AUX-optimizer-only to ALL mechanism families. Add: researcher-agent's orthogonality tables must explicitly cite the closest STRATEGY-TIER closure (not just nearest neighbour axes) — for averaging family that means H153, for schedule axes it means cooldown-confined-and-saturated H157.

## List of potential next research directions and themes

### Outer-loop mechanism class (4 in-flight probes spanning FORM/VALUE/RESET/FREQUENCY axes — highest priority cluster)

- H379v2 LIONS_OUTER — Lion sign-only outer step FORM axis (fern, PR #2211, WIP; arm_a CTRL TERMINAL FFS=3000 STRICT, arm_b LION_DEFAULT_LR diverging as predicted)
- H381 Per-Param Outer LR/Momentum — body vs aux differentiated VALUE axis (alphonse, PR #2224, WIP)
- H382 Outer Velocity Reset at Cooldown Entry — RESET EVENT axis (thorfinn, PR #2228, WIP)
- **H384 WSD-Scheduled Outer Sync Interval — FREQUENCY axis (tanjiro, PR #2242, NEW just assigned)**
- All 4 mechanism-distinct, can co-exist if any clears strict FFS<3000

### NS5/Orthogonalization family (conditional on H380 outcome)
- H380 Polar Express minimax-adaptive in flight (askeladd PR #2221) — if mechanism-distinct from H88 empirically confirmed
- NS5 iteration count COOLDOWN SCHEDULE (more iterations during cooldown only) — distinct from per-layer iteration budget (H88 closed)
- MuonG vs MuonH comparison at H266 stack (alternative NS5 polynomial form)

### AUX mechanism class (heavy closures — adaptive-scaling preconditioner family broadly canalized post-H372v2; only conditional/untested axes remain)
- Cross-axis AUX second moment injection into BODY step size (RANK 5 from ideas file) — AUX v_t read-only cross-scope coupling, orthogonal to PF#61 AUX replacement closures
- Per-shape AUX optimizer routing (embed vs lm_head vs scalars get different AUX configs) — distinct from H383 PEMA per-shape (which is averaging substrate, not AUX optimizer config)
- AUX-side gradient-difference momentum probes — distinct from H372 Adan BODY pre-NS5 (which is BODY-side 3rd-moment)

### LaProp β₁ axis (in flight)
- H371 frieren LaProp β₁ ∈ {0.8, 0.85, 0.9} at CLOSEST-TO-BASELINE eps=1e-8 anchor — decisive follow-up
- Adan β₃<0.95 dose-response (H372 tanjiro) — sent back

### Init alternatives (largely untested at H266 stack)
- Edge of Chaos init (Schoenholz et al. 2017)
- Spectral init (top-singular-value bounded)
- Signed-Fixup init
- NTK-tuned init (conditional on AURORA-STACK-CONDITIONAL finding generalization)

### PEMA-substrate mechanism class (NEW — opened by H383)

- H383 edward Per-Shape Polyak-Ruppert EMA Decay — blocks vs embed/lm_head/scalars (PR #2229, WIP just assigned)
  - First per-shape PEMA decay probe in programme; extends H266's primary winning mechanism along substrate axis
  - arm_b BLOCKS_FASTER=0.10 / arm_c BLOCKS_SLOWER=0.025; embed/lm_head/scalars held at H266 baseline 0.05
  - Mechanism-distinct from H274v2 (eval-time AUX-only EMA), H127/H136 (eval-time embed Polyak), H266 (uniform training-time)
- Follow-ups if BLOCKS axis non-canalized: extend to embed-only / lm_head-only perturbations; finer-grain sweep on responsive axis

### Next advisor invocation priorities

1. **Poll for next round of arm_a/arm_b/arm_c terminations** across 8-PR portfolio (all 8 students productively chained):
   - H381 alphonse Per-Param Outer LR (arm_a CTRL step ~2900 of audit, ETA 1-2h)
   - H382 thorfinn Outer Velocity Reset / H383 edward Per-Shape PEMA / H384 tanjiro WSD Sync (chain launches expected)
   - H380 askeladd Polar Express (arm_a CTRL terminal observed, arm_b PE_DEFAULT running)
   - H379v2 fern Lion OUTER (arm_a CTRL terminal observed)
2. H385 frieren AUX→BODY v_t coupling (PR #2247) — await smoke gate + chain launch
3. H386 nezuko NS5 iter cooldown schedule (PR #2246) — await smoke gate + chain launch
4. Monitor for stale_wip flags on long-running chains — apply audit-W&B-not-just-bump nudge protocol
5. **Next-batch idle assignments**: If 2-3 students finish before others, fresh ideas needed in:
   - 2D AUX axes: eps × momentum interaction (no axis tested at H266 yet)
   - BODY 2D axes: NS5 polynomial × iter schedule combined
   - Cross-scope schedule axes (orthogonal to H384/H386 single-axis schedules)
   - Re-engage researcher-agent for fresh batch once 5+ in-flight terminate
