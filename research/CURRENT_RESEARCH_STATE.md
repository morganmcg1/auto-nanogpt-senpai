# SENPAI Research State — auto-nanogpt-1gpu-r3

**Last updated:** 2026-06-02 09:00 UTC (cycle ~2700, 236 cumulative NULL/NEG/TIE closures + 1 MERGED WIN)

## Most recent research direction from human researcher team

No new directives in current invocation. Issue #1260 strict FFS<3000 merge gate remains active. Issue #2122 Aurora research nudge fully resolved (H366 + H373 closures confirmed AURORA-MECHANISM-STACK-CONDITIONAL class). Human team last commented on Issue #1260 on 2026-05-29 confirming H266 breakthrough; subsequent advisor updates have been one-way.

## Current research focus and themes

### Baseline state
- **🏆 BASELINE**: PR #1669 H266 Polyak-Ruppert EMA all-params decay=0.05 (merged 2026-05-28)
  - val/loss = 3.26818, FFS = 3000, σ_H174 = 0.000884
  - Reproduce: `torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --train_steps 3325 --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6 --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_beta2_schedule constant --aux_beta2_start 0.99 --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05`

### Cycle ~2700 status (cumulative)
- **236 cumulative NULL/NEG/TIE closures**, 1 MERGED WIN (H266)
- **21 HARD-LOAD-BEARING family entries**: H368/H375/H282/H169/H370/H374/H376/H377/H378/H379v2/etc. (H380 stays MILDLY-LOAD-BEARING)
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
- ~32 candidate H266 attractor cluster anchors (H380 arm_c PE8 val=3.26876 FFS=3025 Pattern A +25 = 32nd)
- **11-axis OUTER-LOOP mechanism canalization** (joint H91/H99/H100/H101/H103/H108/H111/H113/H116 closure cluster + H379v2 LION OUTER closure): MuLoCo Nesterov-SGDM(μ=0.5, outer_lr=0.7, sync_interval=30) is at-optimum across 11 mechanism axes of outer-loop variation at H266 stack

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

### In-flight 7-PR portfolio + 1 idle student awaiting fresh axis (snapshot 2026-06-02 09:00Z)

| PR | Student | Hypothesis | Status | Notes |
|----|---------|-----------|--------|-------|
| #2247 | frieren | H385 AUX→BODY v_t cross-axis coupling | WIP | first CROSS-OPTIMIZER STATE COUPLING probe. arm_b DIRECT s_t/s_anchor / arm_c INVERSE s_anchor/s_t modulates BODY MuonH lr. Anchor capture at step 50. Symmetric clamp [0.5, 2.0]. RANK 5 |
| #2242 | tanjiro | H384 WSD-Scheduled Outer Sync Interval (FREQUENCY axis) | WIP | Varies sync_interval between stable (30) and cooldown phases (15 or 60); cooldown boundary at step 1995/3325. RANK 4 |
| #2228 | thorfinn | H382 Outer Velocity Reset at Cooldown Entry | WIP | ~10 LoC — reset outer_velocity buffer at cooldown onset (analogy to H170 AUX v_t reset merge-winner). RANK 3 |
| #2229 | edward | H383 Per-Shape Polyak-Ruppert EMA Decay (blocks vs embed/lm_head/scalars) | WIP | First per-shape PEMA decay probe; arm_b BLOCKS_FASTER 0.10 / arm_c BLOCKS_SLOWER 0.025 with embed/lm_head/scalars held at H266 0.05 |
| #2246 | nezuko | H386 NS5 Iter Count Cooldown Schedule | WIP | first SCHEDULE-DRIVEN NS5 iter count probe. arm_b LATE_16 / arm_c LATE_8 starting at step 2328 (0.7 × 3325). Distinct from H267 STATIC iter closure. Time-varying version of H380 "polar-factor over-purification" within-chain finding |
| #2254 | fern | H387 Outer SGDR Warm Restarts (periodic outer_velocity reset) | WIP | periodic outer_velocity zero-reset every N inner steps. arm_b SGDR_500 (6 events) / arm_c SGDR_1000 (3 events). Mechanism-distinct from H382 single-event RESET and H384 FREQUENCY. RANK 6 |
| #2224 | alphonse | H381 Per-Param Outer LR/Momentum (body vs aux) | WIP | Differentiates outer correction force between body/aux parameter groups. RANK 2 |
| **(idle)** | **askeladd** | **H388 pending — researcher-agent v2 dedup refresh after H388_v1 AUX WD cooldown ramp REJECTED as H328 duplicate** | **IDLE** | **H388_v1 AUX WD ramp REJECTED — H328 paper-grade finding "AUX WD SCHEDULE pre-closed by VALUE-axis result" + embed-RMS growth load-bearing mechanism**. Awaiting alternative fresh axis proposal. |

### Recent closure cadence (last 12 hours)

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
- **Process improvement**: dedup-grep memory `feedback_dedup_grep_before_aux_optimizer_assign.md` broadened from AUX-optimizer-only to ALL mechanism families.

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
