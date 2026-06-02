# SENPAI Research State — auto-nanogpt-1gpu-r3

**Last updated:** 2026-06-02 02:30 UTC (cycle ~2700, 228 cumulative NULL/NEG closures + 1 MERGED WIN)

## Most recent research direction from human researcher team

No new directives in current invocation. Issue #1260 strict FFS<3000 merge gate remains active. Issue #2122 Aurora research nudge fully resolved (H366 + H373 closures confirmed AURORA-MECHANISM-STACK-CONDITIONAL class). Human team last commented on Issue #1260 on 2026-05-29 confirming H266 breakthrough; subsequent advisor updates have been one-way.

## Current research focus and themes

### Baseline state
- **🏆 BASELINE**: PR #1669 H266 Polyak-Ruppert EMA all-params decay=0.05 (merged 2026-05-28)
  - val/loss = 3.26818, FFS = 3000, σ_H174 = 0.000884
  - Reproduce: `torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --train_steps 3325 --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6 --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_beta2_schedule constant --aux_beta2_start 0.99 --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05`

### Cycle ~2700 status (cumulative)
- **228 cumulative NULL/NEG/TIE closures**, 1 MERGED WIN (H266)
- **17 HARD-LOAD-BEARING family entries**: H368/H375/H282/H169/H370/etc.
- **5 INIT-side closures**: H351 + H357 + H365 (HARD-LOAD-BEARING) + H366 Aurora + H373 LSUV (TIE AURORA-STACK-CONDITIONAL)
- **3 CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entries**: H371 arm_c LaProp eps=1e-8 (CLOSEST-TO-BASELINE, −0.16σ vs H266) + H372 arm_c Adan β₃=0.95 + H373 arm_c LSUV_STRICT
- **2 AURORA-MECHANISM-STACK-CONDITIONAL class entries**: H366 + H373
- **1 BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis**: H375 Schedule-Free (joins H368 AdEMAMix + H282 AdaBelief in 3-leg programme finding)
- ~37 candidate H266 attractor cluster anchors (mostly Pattern A +25/+50 FFS envelope)

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

### In-flight 8-PR portfolio (snapshot 2026-06-02 02:30Z)

| PR | Student | Hypothesis | Status | Notes |
|----|---------|-----------|--------|-------|
| #2157 | frieren | H371 LaProp β₁-axis at eps=1e-8 (send-back) | WIP | β₁ ∈ {0.8, 0.85, 0.9} at CLOSEST-TO-BASELINE LaProp eps=1e-8 anchor |
| #2158 | tanjiro | H372 Adan β₃<0.95 dose-response (send-back) | WIP | β₃ ∈ {-1 sentinel, 0.9, 0.5} |
| #2172 | alphonse | H374 WSD BODY cooldown frac | WIP | arm_a/b TERMINAL (CTRL +25, WSD_50 CATASTROPHIC), arm_c WSD_30 in flight |
| #2182 | thorfinn | H376 Sophia-H AUX | WIP | 2nd-order Hessian-diag AUX preconditioner probe |
| #2187 | edward | H377 Lookahead AUX wrapper | WIP | k-step outer-iterate averaging on AUX optimizer |
| #2202 | nezuko | H378 Gradient Centralization BODY pre-NS5 | WIP | Mean-subtraction on BODY grads before polar projection |
| #2211 | fern | H379v2 Lion-form OUTER step at MuLoCo sync boundary | WIP (just aborted H379 AdaBelief duplicate; pivoted to LIONS_OUTER) | First test of Lion sign-only form at OUTER LOOP scope |
| (askeladd) | askeladd | Pending — researcher-agent ideation in-flight | IDLE | H375 Schedule-Free just closed CATASTROPHIC NEG |

### Recent closure cadence (last 6 hours)

- **PR #2173 H375 askeladd Schedule-Free AUX** — CLOSED 228th NULL/NEG (paper-grade 1st BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis)
- **PR #2165 H373 fern LSUV BODY init** — CLOSED 227th NULL/TIE (2nd AURORA-MECHANISM-STACK-CONDITIONAL class entry)
- **PR #2157 H371 frieren LaProp** — SENT BACK 226th cumulative (2nd CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entry, CLOSEST-TO-BASELINE arm of cycle ~2700)
- **PR #2158 H372 tanjiro Adan BODY pre-NS5** — SENT BACK 225th cumulative (1st CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entry, monotone β₃ dose-response)
- **PR (H370) tanjiro QHM BODY ν-axis** — CLOSED 224th NULL/NEG (17th HARD-LOAD-BEARING family entry, 2nd MONOTONE DOSE-RESPONSE NEG class)
- **PR (H368) thorfinn AdEMAMix AUX α-axis** — CLOSED 223rd NULL/NEG (16th HARD-LOAD-BEARING family entry, 1st MONOTONE DOSE-RESPONSE NEG class on continuous α-axis)

### Recent advisor process incident
- **2026-06-02 ~01:28Z**: assigned fern H379 AdaBelief AUX as "fresh AUX mechanism". fern implemented (~52 LoC), passed smoke gate (10.82583 EXACT both arms), and launched 3-arm chain.
- **2026-06-02 ~02:10Z**: discovered PR #1745 H282 askeladd "AdaBelief on aux" closed 2026-05-30 as 136th NULL/NEG with paper-grade PF#61 5-axis CLOSURE-GRADE. H379 was a duplicate.
- **Action**: aborted fern's chain at T+45min (saved ~5h GPU). Pivoted to H379v2 LIONS_OUTER (Lion-form OUTER LOOP optimizer step at MuLoCo sync boundary — mechanism-distinct from H169/H241/H260 Lion AUX/BODY closures).
- **Process improvement**: new feedback memory `feedback_dedup_grep_before_aux_optimizer_assign.md` requires Grep EXPERIMENTS_LOG for mechanism name BEFORE writing AUX optimizer assignment PR.

## List of potential next research directions and themes

### Promising mechanism-distinct fresh axes (preliminary — researcher-agent in flight for askeladd)

**Outer-loop mechanism class** (only H289 outer momentum schedule + H103 outer Nesterov-vs-HB at older stack tested):
- H379v2 LIONS_OUTER — Lion sign-only outer step (assigned to fern)
- Outer-AdamW: adaptive LR per outer-param state at sync boundary
- Outer-Schedule-Free at OUTER LOOP (despite H375 inner-SF CATASTROPHIC, outer-loop dynamics may differ)
- Outer optimizer state reset at cooldown onset

**Per-shape/per-layer scaling mechanisms** (largely untested at H266 stack):
- Per-shape AUX optimizer routing (different optimizers for embed vs lm_head vs scalars)
- Per-shape BODY MuonH inner LR scaling (attn vs MLP projections)
- Per-layer Polyak EMA decay (uniform 0.05 currently)
- Per-layer LR decay (Zhang-style discriminative)

**NS5 polynomial coefficient family alternatives** (H287 HALLEY closed):
- Other polynomial forms within NS5 family (Schultz, Newton-2nd-order, MuonG vs MuonH)
- Different NS5 iteration count COOLDOWN SCHEDULE (more iter during cooldown)

**Init alternatives beyond closed family**:
- Edge of Chaos init (Schoenholz et al. 2017)
- Spectral init (top-singular-value bounded)
- Signed-Fixup init
- NTK-tuned init

**Cross-axis interaction mechanisms**:
- AUX preconditioner state injection into BODY MuonH (cross-scope coupling)
- BODY/AUX scope partition mechanisms (e.g., apply mechanism to half-and-half scope)

### Plateau protocol candidates (per CLAUDE.md)

- Bigger architectural swings: replace MuonH with alternative orthogonalization (QR, SVD, Cayley transform)
- Loss reformulation: distillation-style auxiliary loss, focal-style focus loss
- Data-axis explorations are OUT per launch constraint (keep data fixed)

### Next advisor invocation priorities

1. Receive researcher-agent output → assign askeladd a fresh hypothesis
2. Continue polling for in-flight PR terminations (~5h 30m each)
3. Verify fern picks up H379v2 LIONS_OUTER pivot
4. Continue Cycle ~2700 closure cadence — target 230+ cumulative entries this week
