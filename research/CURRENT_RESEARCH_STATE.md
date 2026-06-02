# SENPAI Research State — auto-nanogpt-1gpu-r3

**Last updated:** 2026-06-02 06:40 UTC (cycle ~2700, 232 cumulative NULL/NEG/TIE closures + 1 MERGED WIN)

## Most recent research direction from human researcher team

No new directives in current invocation. Issue #1260 strict FFS<3000 merge gate remains active. Issue #2122 Aurora research nudge fully resolved (H366 + H373 closures confirmed AURORA-MECHANISM-STACK-CONDITIONAL class). Human team last commented on Issue #1260 on 2026-05-29 confirming H266 breakthrough; subsequent advisor updates have been one-way.

## Current research focus and themes

### Baseline state
- **🏆 BASELINE**: PR #1669 H266 Polyak-Ruppert EMA all-params decay=0.05 (merged 2026-05-28)
  - val/loss = 3.26818, FFS = 3000, σ_H174 = 0.000884
  - Reproduce: `torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --train_steps 3325 --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6 --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_beta2_schedule constant --aux_beta2_start 0.99 --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05`

### Cycle ~2700 status (cumulative)
- **232 cumulative NULL/NEG/TIE closures**, 1 MERGED WIN (H266)
- **20 HARD-LOAD-BEARING family entries**: H368/H375/H282/H169/H370/H374/H376/H377/etc.
- **1 U-SHAPE-CHARACTERIZED-AXIS class entry with PRODUCTIVE-BAND-EDGE LOCALIZATION** (H372 Adan β₃ axis, U-shape minimum at β₃=0.95, band edge β₃∈(0.9, 0.95), no FFS gain at any β₃)
- AUX/BODY adaptive-scaling preconditioner family broadly canalized: H371 LaProp eps (CLOSEST-TO-BASELINE), H372 Adan β₃ (U-shape, no FFS gain), H376 Sophia-H ρ (+16-29σ NEG), H369 Lion LR (CATASTROPHIC), H375 Schedule-Free (BILATERAL CATASTROPHIC), H368 AdEMAMix α (MONOTONE NEG)
- **5 INIT-side closures**: H351 + H357 + H365 (HARD-LOAD-BEARING) + H366 Aurora + H373 LSUV (TIE AURORA-STACK-CONDITIONAL)
- **3 CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entries**: H371 arm_c LaProp eps=1e-8 (CLOSEST-TO-BASELINE, −0.16σ vs H266) + H372 arm_c Adan β₃=0.95 + H373 arm_c LSUV_STRICT
- **2 AURORA-MECHANISM-STACK-CONDITIONAL class entries**: H366 + H373
- **1 BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis**: H375 Schedule-Free (joins H368 AdEMAMix + H282 AdaBelief in 3-leg programme finding)
- **1 K-INVARIANT STRONG NEG class entry on α-interpolation magnitude axis (H377)**: Lookahead AUX wrapper, 1st OUTER-on-AUX probe at H266 stack
- **3rd STRUCTURAL-TIMING-AXIS NEG class entry (H374 WSD)**: 4 LR-schedule axes now confirmed canalized
- ~30 candidate H266 attractor cluster anchors (arm_a CTRL from H377 = 26th; H376 = 30th)

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

### In-flight 8-PR portfolio (snapshot 2026-06-02 04:25Z)

| PR | Student | Hypothesis | Status | Notes |
|----|---------|-----------|--------|-------|
| #2157 | frieren | H371 LaProp β₁-axis at eps=1e-8 (send-back) | WIP | β₁ ∈ {0.8, 0.85, 0.9} at CLOSEST-TO-BASELINE LaProp eps=1e-8 anchor; arm_a CTRL adamw β₁=0.8 FFS=3000 val=-1.23σ (2nd observation of same mild positive signal) |
| #2242 | tanjiro | H384 WSD-Scheduled Outer Sync Interval (FREQUENCY axis) | WIP (just assigned) | NEW — varies sync_interval between stable (30) and cooldown phases (15 or 60); cooldown boundary at step 1995/3325 |
| #2228 | thorfinn | H382 Outer Velocity Reset at Cooldown Entry | WIP | ~10 LoC — reset outer_velocity buffer at cooldown onset (analogy to H170 AUX v_t reset merge-winner) |
| #2229 | edward | H383 Per-Shape Polyak-Ruppert EMA Decay (blocks vs embed/lm_head/scalars) | WIP (just assigned) | NEW — first per-shape PEMA decay probe; arm_b BLOCKS_FASTER 0.10 / arm_c BLOCKS_SLOWER 0.025 with embed/lm_head/scalars held at H266 0.05 |
| #2202 | nezuko | H378 Gradient Centralization BODY pre-NS5 | WIP | Mean-subtraction on BODY grads before polar projection |
| #2211 | fern | H379v2 Lion-form OUTER step at MuLoCo sync boundary | WIP | First test of Lion sign-only form at OUTER LOOP scope (pivot from H379 AdaBelief duplicate) |
| #2221 | askeladd | H380 Polar Express minimax-adaptive NS5 | WIP | H88 caveat comment added; runtime-adaptive vs H88's fixed-coefficient closure |
| #2224 | alphonse | H381 Per-Param Outer LR/Momentum (body vs aux) | WIP | Differentiates outer correction force between body/aux parameter groups |

### Recent closure cadence (last 12 hours)

- **PR #2158 H372v2 tanjiro Adan BODY β₃ dose-response extension** — CLOSED 232nd NULL/NEG (1st U-SHAPE-CHARACTERIZED AXIS with PRODUCTIVE-BAND-EDGE LOCALIZATION class entry, AUX/BODY adaptive-scaling preconditioner family broadly canalized at 6 dose-response points β₃ ∈ {0.5, 0.9, 0.95, 0.99, -1.0 sentinel × 2}, even best arm doesn't clear H266 baseline; arm_a CTRL v2 = TIGHTEST CTRL anchor of cycle ~2700 at +0.04σ vs H266)
- **PR #2187 H377 edward Lookahead AUX wrapper** — CLOSED 231st NULL/NEG (20th HARD-LOAD-BEARING family entry, 1st K-INVARIANT STRONG NEG class on α-interpolation magnitude axis, 1st OUTER-on-AUX probe at H266 stack, 1st TRAJECTORY-PRESERVATION vs TRAJECTORY-RESET dichotomy refinement; arm_a CTRL = 26th H266 cluster anchor)
- **PR #2182 H376 thorfinn Sophia-H AUX** — CLOSED 230th NULL/NEG (19th HARD-LOAD-BEARING family entry, 2nd-order Hessian-diag preconditioner axis closed, 3-point monotone gradient on AUX adaptive-scaling axis: Lion CATASTROPHIC → Sophia STRONG NEG +16-29σ → AdamW BASELINE)
- **PR #2172 H374 alphonse WSD BODY MuonH** — CLOSED 229th NULL/NEG (18th HARD-LOAD-BEARING family entry, 3rd STRUCTURAL-TIMING-AXIS NEG, 4th LR-schedule axis canalized, arm_a CTRL = 28th H266 cluster anchor)
- **PR #2173 H375 askeladd Schedule-Free AUX** — CLOSED 228th NULL/NEG (paper-grade 1st BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis)
- **PR #2165 H373 fern LSUV BODY init** — CLOSED 227th NULL/TIE (2nd AURORA-MECHANISM-STACK-CONDITIONAL class entry)
- **PR #2157 H371 frieren LaProp** — SENT BACK 226th cumulative (CLOSEST-TO-BASELINE arm of cycle ~2700)
- **PR #2158 H372 tanjiro Adan BODY pre-NS5** — SENT BACK 225th cumulative (1st CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entry)

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

1. Poll for next round of arm_a terminations: H381 alphonse (~05:55Z ETA), H382 thorfinn / H383 edward (~06:15Z ETA), H371 frieren arm_c (~06:30Z ETA), H372v2 closed 06:35Z (this invocation)
2. H378 nezuko arm_c GC_BOTH (~07:00Z ETA — last arm of 3)
3. H380 askeladd arm_b PE_DEFAULT (~06:54Z ETA), arm_c PE8 (~08:48Z ETA)
4. H379v2 fern arm_b LION_DEFAULT_LR likely-DIVERGENT (val=6.06 at step 1620 of audit) — monitor for early-kill or wait through; arm_c LION_TUNED_LR (lr=0.05) is the real test
5. H384 tanjiro WSD-Scheduled Outer Sync Interval (PR #2242) — await smoke gate + chain launch
6. **Flag for follow-up — TWO-INSTANCE adamw β₁=0.8 mild positive signal**: frieren PR #2157 arm_a CTRL adamw β₁=0.8 val=3.26710 FFS=3000 was −1.23σ vs H266 (1st observation in v1 round-2, 2nd observation in v2 round — same arm_a config). If arm_b LAPROP_B1_MID and arm_c LAPROP_B1_PAPER also produce FFS<3000 STRICT with similar val gain, the β₁=0.8 anchor across adamw AND LaProp would be load-bearing on a new axis.
