# SENPAI Research State — auto-nanogpt-1gpu-r3

**Last updated:** 2026-06-02 05:40 UTC (cycle ~2700, 229 cumulative NULL/NEG/TIE closures + 1 MERGED WIN)

## Most recent research direction from human researcher team

No new directives in current invocation. Issue #1260 strict FFS<3000 merge gate remains active. Issue #2122 Aurora research nudge fully resolved (H366 + H373 closures confirmed AURORA-MECHANISM-STACK-CONDITIONAL class). Human team last commented on Issue #1260 on 2026-05-29 confirming H266 breakthrough; subsequent advisor updates have been one-way.

## Current research focus and themes

### Baseline state
- **🏆 BASELINE**: PR #1669 H266 Polyak-Ruppert EMA all-params decay=0.05 (merged 2026-05-28)
  - val/loss = 3.26818, FFS = 3000, σ_H174 = 0.000884
  - Reproduce: `torchrun --standalone --nproc_per_node=1 records/track_3_optimization/train_gpt_simple.py --num_trials 1 --train_steps 3325 --muonh_mode scale_invariant --muonh_cooldown_shape cosine --muonh_warmup_steps 100 --aux_adamw_eps 1e-6 --use_outer_optimizer 1 --outer_lr 0.7 --outer_momentum 0.5 --sync_interval 30 --aux_agc_clip_ratio 0.05 --muonh_agc_clip_ratio 0.05 --aux_beta2_schedule constant --aux_beta2_start 0.99 --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 --body_init orthogonal_fnorm_matched --polyak_ema_decay 0.05`

### Cycle ~2700 status (cumulative)
- **229 cumulative NULL/NEG/TIE closures**, 1 MERGED WIN (H266)
- **18 HARD-LOAD-BEARING family entries**: H368/H375/H282/H169/H370/H374/etc.
- **5 INIT-side closures**: H351 + H357 + H365 (HARD-LOAD-BEARING) + H366 Aurora + H373 LSUV (TIE AURORA-STACK-CONDITIONAL)
- **3 CANALIZED-TIE-with-MILD-POSITIVE-DRIFT class entries**: H371 arm_c LaProp eps=1e-8 (CLOSEST-TO-BASELINE, −0.16σ vs H266) + H372 arm_c Adan β₃=0.95 + H373 arm_c LSUV_STRICT
- **2 AURORA-MECHANISM-STACK-CONDITIONAL class entries**: H366 + H373
- **1 BILATERAL CATASTROPHIC NEG class entry on AUX fresh-mechanism axis**: H375 Schedule-Free (joins H368 AdEMAMix + H282 AdaBelief in 3-leg programme finding)
- **3rd STRUCTURAL-TIMING-AXIS NEG class entry (H374 WSD)**: 4 LR-schedule axes now confirmed canalized
- ~29 candidate H266 attractor cluster anchors (arm_a CTRL from H374 = 28th; other recent CTRLs add more)

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

**4 LR-schedule structural-timing axes fully canalized** (H352+H362+H363+H374):
All 4 tested structural-timing axes of the H266 LR schedule are canalized: cooldown SHAPE (H352 cosine optimum), warmup DURATION (H362 bilateral asymmetric NEG), μ_start TIMING (H363 bilateral asymmetric NEG), cooldown DURATION (H374 monotonic-asymmetric NEG). WSD (Warmup-Stable-Decay), even at MiniCPM canonical 70/30 ratio, is catastrophically NEG at 3325-step short-budget. Further LR-schedule probes are unlikely to yield WIN candidates.

### In-flight 8-PR portfolio (snapshot 2026-06-02 05:40Z)

| PR | Student | Hypothesis | Status | Notes |
|----|---------|-----------|--------|-------|
| #2157 | frieren | H371 LaProp β₁-axis at eps=1e-8 (send-back) | WIP | β₁ ∈ {0.8, 0.85, 0.9} at CLOSEST-TO-BASELINE LaProp eps=1e-8 anchor |
| #2158 | tanjiro | H372 Adan β₃<0.95 dose-response (send-back) | WIP | β₃ ∈ {-1 sentinel, 0.9, 0.5} |
| #2182 | thorfinn | H376 Sophia-H AUX | WIP | 2nd-order Hessian-diag AUX preconditioner probe |
| #2187 | edward | H377 Lookahead AUX wrapper | WIP | k-step outer-iterate averaging on AUX optimizer |
| #2202 | nezuko | H378 Gradient Centralization BODY pre-NS5 | WIP | Mean-subtraction on BODY grads before polar projection |
| #2211 | fern | H379v2 Lion-form OUTER step at MuLoCo sync boundary | WIP | First test of Lion sign-only form at OUTER LOOP scope (pivot from H379 AdaBelief duplicate) |
| #2221 | askeladd | H380 Polar Express minimax-adaptive NS5 | WIP | H88 caveat comment added; runtime-adaptive vs H88's fixed-coefficient closure |
| #2224 | alphonse | H381 Per-Param Outer LR/Momentum (body vs aux) | WIP (just assigned) | NEW — differentiates outer correction force between body/aux parameter groups |

### Recent closure cadence (last 12 hours)

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

### Outer-loop mechanism class (highest priority — H374 LR-schedule closure exhausted schedule axis)

- H381 Per-Param Outer LR/Momentum — body vs aux differentiated (just assigned to alphonse, PR #2224)
- H379v2 LIONS_OUTER — Lion sign-only outer step (in flight, fern, PR #2211)
- RANK 3 from ideas file: Outer Velocity Reset at Cooldown Entry (~10 LoC, strong analogy to H170 merge-winner but at outer loop scope)
- RANK 4: WSD-Scheduled Outer Sync Interval (outer correction FREQUENCY schedule, distinct from VALUE bracket)

### NS5/Orthogonalization family (conditional on H380 outcome)
- H380 Polar Express minimax-adaptive in flight (askeladd PR #2221) — if mechanism-distinct from H88 empirically confirmed
- NS5 iteration count COOLDOWN SCHEDULE (more iterations during cooldown only) — distinct from per-layer iteration budget (H88 closed)
- MuonG vs MuonH comparison at H266 stack (alternative NS5 polynomial form)

### AUX mechanism class (heavy closures — only conditional/untested axes remain)
- Cross-axis AUX second moment injection into BODY step size (RANK 5 from ideas file) — AUX v_t read-only cross-scope coupling, orthogonal to PF#61 AUX replacement closures
- Per-shape AUX optimizer routing (embed vs lm_head vs scalars get different AUX configs)

### LaProp β₁ axis (in flight)
- H371 frieren LaProp β₁ ∈ {0.8, 0.85, 0.9} at CLOSEST-TO-BASELINE eps=1e-8 anchor — decisive follow-up
- Adan β₃<0.95 dose-response (H372 tanjiro) — sent back

### Init alternatives (largely untested at H266 stack)
- Edge of Chaos init (Schoenholz et al. 2017)
- Spectral init (top-singular-value bounded)
- Signed-Fixup init
- NTK-tuned init (conditional on AURORA-STACK-CONDITIONAL finding generalization)

### Next advisor invocation priorities

1. Poll for terminations from 8 in-flight WIP chains (~5h remaining typical)
2. H381 alphonse Per-Param Outer LR/Momentum (PR #2224) — await smoke gate + chain launch
3. H380 askeladd Polar Express (PR #2221) — await smoke gate with H88 coefficient audit
4. H379v2 fern Lion-OUTER (PR #2211) — await smoke gate + chain launch
5. H371 frieren / H372 tanjiro send-backs — await chain launch on revised configs
6. Continue cycle ~2700 closure cadence — target 230+ this invocation
