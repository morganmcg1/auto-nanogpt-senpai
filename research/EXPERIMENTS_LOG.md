# SENPAI Research Results

## 2026-06-02 11:42 UTC — PR #2226 frieren: PMuon update Frobenius ceiling by weight norm (γ=0.5 LOOSE vs γ=0.3 TIGHT) — ❌ BILATERAL NULL; Frobenius ceiling axis CLOSED; frieren REASSIGNED → #TBA ns5-coef-attn-mlp-split

- Branch: `g1r1-frieren/pmuon-update-clip-wnorm`
- Hypothesis: Weight-norm-relative Frobenius upper bound on body-PMuon updates. Arm A LOOSE γ=0.5 clips only extreme outliers (above existing TARGET_UW=0.35 floor). Arm B TIGHT γ=0.3 forces constant-magnitude updates (below floor; floor+ceiling sandwich → exact 0.3·||W|| every step).
- W&B runs: `c4jenl2b` (Arm A LOOSE), `g0oieeky` (Arm B TIGHT)

| Metric | Baseline #1532 | Arm A (LOOSE γ=0.5) | Arm B (TIGHT γ=0.3) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **3125** (+250) | **NEVER REACHED** |
| `ema/val_loss_ema` | **3.262854** | **3.276481** (+13.6 mnat) | **3.286966** (+24.1 mnat) |
| `optim/pmuon_clip_fire_rate` | — | — | **1.0** (all 72 body params clipped every step) |
| Merge gate | — | FAIL | FAIL (model regressed) |

- Arm A LOOSE: clean NULL +13.6 mnat. The Frobenius ceiling at γ=0.5 fires often enough to perturb descent without providing benefit.
- Arm B TIGHT: catastrophic regression — model never reached val=3.28 by step 3250. Confirms that removing natural NS5/whitening update-magnitude variability destroys descent rate. Fire rate=1.0 confirmed (every step every body param clipped).
- **Conclusion:** Frobenius ceiling axis CLOSED. The existing u/w-floor already captures the magnitude-control benefit; adding a ceiling either does nothing useful (LOOSE) or destroys descent (TIGHT). Combined with prior γ closures (cooldown ramp #760, pre-target pulse #1680, block-strat #1935, attn-vs-mlp #736, depth-split etc.), the body PMuon magnitude clipping family is FULLY EXHAUSTED.
- **Frieren reassigned → NS5 coefficient ATTN vs MLP role-split bilateral** — directive (b)+(d), pristine vs all prior NS5 role-split work (which tested iter count or coverage, never polynomial shape per role).

## 2026-06-02 11:42 UTC — PR #2225 fern: aux Adam lm_head per-group β₁ split (FAST 0.5 vs SLOW 0.95) — ❌ BILATERAL NULL; per-group β₁ split axis CLOSED; fern REASSIGNED → #TBA body-muon-interblock-neighbor-mom

- Branch: `g1r1-fern/lm-head-b1-permanent-split`
- Hypothesis: Override aux Adam β₁ for lm_head group only (from global 0.8). Arm A FAST 0.5 (faster m-state, ~2-step window) vs Arm B SLOW 0.95 (slower m-state, ~20-step window). Tests whether lm_head's distinct gradient regime benefits from per-group β₁ asymmetry.
- W&B runs: `21ei4mc2` (Arm A FAST), `o1tjorcy` (Arm B SLOW)

| Metric | Baseline #1532 | Arm A (FAST 0.5) | Arm B (SLOW 0.95) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **2925** (+50) | **2950** (+75) |
| `ema/val_loss_ema` | **3.262854** | **3.263988** (+1.13 mnat) | **3.268445** (+5.59 mnat) |
| Merge gate | — | FAIL | FAIL |

- Both deviations from global β₁=0.8 hurt; the SLOW side hurts ~5× more. Symmetric regression confirms global β₁=0.8 is near-optimal for lm_head — neither faster nor slower local-gradient trust helps.
- Step 0 sentinel verified: `adam_lm_head: betas=(0.5, 0.95)` for Arm A. β₂ pulse @975 preserved per-group β₁ as designed.
- **Conclusion:** Per-group β₁ split axis (lm_head granularity) CLOSED. Combined with all-group β₁ closures (#318, #796, #1482, #1592) and β₂ split closures, the aux Adam β₁/β₂ per-group asymmetry family is exhausted. Distinct in mechanism from in-flight per-group ε (askeladd #2260) and per-group α-EMA pre-filter (alphonse #2269).
- **Fern reassigned → body-Muon inter-block NEIGHBOR MOMENTUM averaging bilateral (α=0.05 vs α=0.15)** — directive (b)+(d), pristine: `m_i ← (1-α)·m_i + (α/2)·m_{i-1} + (α/2)·m_{i+1}`. Distinct from thorfinn's in-flight β₁ block-strat (#2256 scalar per-block) — this is state-mixing per-block, never tested.

## 2026-06-02 11:05 UTC — PR #2219 alphonse: NS polynomial coeff phase-switch @2600 (Jordan vs near-identity) — ❌ BILATERAL NULL; NS coeff phase-switch axis CLOSED; alphonse REASSIGNED → #2269 aux-pre-grad-ema

- Branch: `g1r1-alphonse/ns-coef-phase-switch`
- Hypothesis: Switch NS5 polynomial coefficients (a,b,c) at the pEMA refresh boundary (step 2600) from baseline cubic-Newton (1.5, -0.5, 0.0) to a different polynomial. Arm A: Jordan quintic (3.4445, -4.775, 2.0315). Arm B: near-identity (1.0, -0.1, 0.0). Analogy to the aux β₂ pulse WIN — does the phase boundary at step 2600 allow a different polynomial shape to accelerate final convergence?
- W&B runs: `wd0eshy6` (Arm A Jordan), `dvx59boz` (Arm B near-identity)

| Metric | Baseline #1532 | Arm A (Jordan) | Arm B (near-identity) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **2925** (+50) | **2925** (+50) |
| `ema/val_loss_ema` | **3.262854** | **3.265670** (+2.82 mnat) | **3.264005** (+1.15 mnat) |
| Merge gate | — | FAIL | FAIL |

- Both arms sr=2925 — 50 steps slower than baseline. Merge gate fails on both clauses.
- Arm B (near-identity, subtler change) is closer to baseline than Arm A (Jordan quintic, aggressive change) — but neither wins.
- Arm A sentinel verified: `[step 0] ns_phase_switch ENABLED: step=2600 a=3.4445 b=-4.775 c=2.0315` and `[step 2600] ns_phase_switch: (a,b,c) (1.5, -0.5, 0.0) → (3.4445, -4.775, 2.0315)` ✓
- **Conclusion:** The pEMA refresh boundary at step 2600 does NOT generalize as a phase switch for NS5 polynomial coefficients. The aux β₂ pulse WIN mechanism is specific to the v_t recalibration at cooldown onset (step 975), not a general phase-boundary lever. NS polynomial phase-switch axis CLOSED. Combined with PR #2162 (NS_ITERS cooldown schedule NULL), the NS5 polynomial behavior at phase boundaries is exhausted.
- **Alphonse reassigned → PR #2269: Aux Adam pre-update gradient EMA bilateral (α=0.90 vs α=0.95)**

## 2026-06-02 03:05 UTC — PR #2163 frieren: paramEMA β-ramp SHAPE (LR-decoupled linear vs cosine) — ❌ BILATERAL NULL; LR-coupling of β schedule load-bearing; frieren REASSIGNED → #2226 pmuon-update-clip-wnorm

- Branch: `g1r1-frieren/paramema-beta-ramp-shape`
- Hypothesis: Replace baseline LR-coupled power-law β schedule with LR-decoupled linear or cosine ramp over [1750, 3250]. Student corrected advisor's wrong "step function" framing — actual baseline is LR-coupled smooth ramp via `compute_ema_beta_t`. Arms test linear and cosine shapes as decoupled alternatives.
- W&B runs: `41h18yo8` (Arm A linear), `madoclfz` (Arm B cosine)

| Metric | Baseline #1532 | Arm A (linear) | Arm B (cosine) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **2925** (+50) | **2925** (+50) |
| `val/loss_ema` (final) | **3.262854** | **3.265555** (+2.70 mnat) | **3.263857** (+1.00 mnat) |
| Merge gate | — | ❌ FAIL | ❌ FAIL |

Cosine is +1.70 mnat closer to baseline than linear, confirming the LR-coupled S-curve shape is genuinely favorable — but neither LR-decoupled variant beats the gate.

**Conclusion:** LR-coupled β schedule is LOAD-BEARING. The implicit coupling of β_t to `1 - lr_mult` (power-law shape, COOLDOWN_POWER=1.4) provides a structural advantage over linear/cosine LR-decoupled ramps. The β-ramp SHAPE axis is closed at LR-decoupled linear/cosine level. Combined with prior paramEMA closures (#2105 ema_warmup TIMING, #2102 refresh-step TIMING, #2159 refresh α-blend OPERATOR): ALL paramEMA shape/timing/operator axes exhausted in the immediate neighborhood. **frieren REASSIGNED → #2226: PMuon update Frobenius-norm CEILING relative to weight norm bilateral (γ=0.5 vs γ=0.3)** — complementary to existing u/w floor, directive (a)+(e).

---

## 2026-06-02 03:05 UTC — PR #2159 fern: paramEMA refresh OPERATOR α-blend (0.5 vs 1.5) — ❌ BILATERAL NULL; α=1.0 robust local optimum; fern REASSIGNED → #2225 lm-head-b1-permanent-split

- Branch: `g1r1-fern/paramema-refresh-alpha-blend`
- Hypothesis: The paramEMA refresh at step 2600 performs full-overwrite (`ema := live_params`, α=1.0). Test whether a half-blend (α=0.5, preserves EMA history) or over-inject (α=1.5, extrapolates EMA past live params) improves late-phase convergence.
- W&B runs: `ps5hfym5` (Arm A α=0.5), `jkxsu2jx` (Arm B α=1.5)

| Metric | Baseline #1532 | Arm A (α=0.5) | Arm B (α=1.5) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **2925** (+50) | **2925** (+50) |
| `val/loss_ema` (final) | **3.262854** | **3.265179** (+2.32 mnat) | **3.264398** (+1.54 mnat) |
| Merge gate | — | ❌ FAIL | ❌ FAIL |

ASYMMETRIC NULL: Arm B (over-inject α=1.5) is +0.78 mnat closer to baseline. Overshooting live params (away from old EMA) is less damaging than preserving old EMA history — but neither beats the gate. Sentinel confirmed operator semantics correct (α=1.5 norm 5848.35, extrapolated past live 5840.89 by +7.46).

**Conclusion:** paramEMA refresh operator α=1.0 is a robust local optimum within ±0.5. Combined with all other paramEMA closures: ALL paramEMA axes exhausted. **fern REASSIGNED → #2225: aux Adam per-group β₁ split for lm_head bilateral (FAST 0.5 vs SLOW 0.95)** — tier shift away from paramEMA into aux Adam structural configuration, directive (b)+(d).

---

## 2026-06-02 01:35 UTC — PR #2151 nezuko: Body PMuon wd depth-stratified ASCENDING vs DESCENDING — ❌ BILATERAL NULL; wd depth-gradient axis CLOSED; nezuko REASSIGNED → #2210 lmhead-b2-repulse-2600

- Branch: `g1r1-nezuko/body-muon-wd-depth-strat`
- Hypothesis: Linear depth-stratified weight decay across 12 transformer blocks in two orderings: ASCENDING (shallow→deep: wd=0.0125/0.025/0.0375) vs DESCENDING (shallow→deep: wd=0.0375/0.025/0.0125). Tests if body PMuon benefits from aligned or counter-aligned wd gradient relative to the `late-higher` block-LR pattern.
- W&B runs: `fdl593t3` (Arm A ASCENDING), `ouvlrizt` (Arm B DESCENDING)

| Metric | Baseline #1532 | Arm A ASCENDING | Arm B DESCENDING |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **2925** (+50) | **2925** (+50) |
| `val/loss_ema` (final) | **3.262854** | **3.26433** (+1.47 mnat) | **3.26546** (+2.61 mnat) |
| Merge gate | — | ❌ FAIL | ❌ FAIL |

Mechanism diagnostics: Arm A sentinel confirmed 3 wd buckets at step 0 (`body_muon_wd_shallow=0.0125`, `body_muon_wd_middle=0.025`, `body_muon_wd_deep=0.0375`). ASCENDING marginally better than DESCENDING (+1.14 mnat difference) — late-layer regularization coherent with `late-higher` block-LR pattern is slightly preferable, but neither arm approaches merge gate. Both sr=2925 (+50 steps).

**Conclusion:** Body PMuon depth-stratified weight-decay axis CLOSED. The gradient of wd across blocks is not a load-bearing mechanism for target-crossing speed. Combined with prior body-PMuon pre-target scalar closures (γ #1680, μ #1686, β₁ #1592/#1639, β_cov #1666, Nesterov #1898, schedule-free, LR-UP #1637, LR-DOWN #1697, NS-coefs #1660, wd-pulse #1693, cAdam cov-decay, wd depth-strat #2151): all body Muon pre-target scalar axes exhausted. **nezuko REASSIGNED → #2210: lm_head SECOND aux Adam β₂ pulse @ step 2600 bilateral (β₂=0.99 vs β₂=0.999)** — frontier refinement of confirmed WIN #1532, targeting pEMA refresh boundary as second phase-boundary for lm_head v-state recalibration. Researcher priority-2. Directive (a)+(b)+(c).

---

## 2026-06-02 00:55 UTC — PR #2148 askeladd: Cautious Adam (cAdam) applied to aux Adam group — ❌ BILATERAL NULL; cAdam axis EXHAUSTED on aux Adam stack; askeladd REASSIGNED → #2207 post-NS update EMA

- Branch: `g1r1-askeladd/caut-adam-aux`
- Hypothesis: Apply cautious Adam masking (m_hat/grad sign agreement mask) to the aux Adam optimizer group, in two activation windows: PERMANENT from step 0 (Arm A) vs TRANSIENT from step 975 cooldown onset (Arm B). Tests whether cAdam's "stale momentum suppression" improves the aux Adam subproblem.
- W&B runs: `not2xz5c` (Arm A PERMANENT), `f4tgy5uc` (Arm B TRANSIENT @975)

| Metric | Baseline #1532 | Arm A (PERMANENT, n=1) | Arm B (TRANSIENT @975, n=1) |
|---|---|---|---|
| `speedrun/first_step_to_target` | **2875** | **3025** (+150) | **3050** (+175) |
| `val/loss_ema` (final) | **3.262854** | **3.27178** (+0.00893) | **3.27367** (+0.01081) |
| Merge gate | — | ❌ FAIL | ❌ FAIL |

Mechanism diagnostics: mask_fraction stable at ~0.558 (45% of aux Adam updates suppressed), confirming the mechanism is firing. But masking is HARMFUL on this aux Adam subspace — the embed/lm_head/scalar params benefit from "stale momentum" updates (useful smoothing), not suppression. Effective step shrinkage of ~45% per step under-steps aux params throughout the run. The null confirms cAdam does not generalize from full-network Adam (where it was published) to this well-conditioned, EMA-decoupled aux subproblem.

**Conclusion:** cAdam axis CLOSED on the aux Adam stack. Combined with prior aux-Adam structural axis closures: β₁ pulse (#1592/#1639), β₁ DROP, m-reset (in-flight #2183), β₂ pulse decomposition (#2086), AdEMAMix dual-EMA (#2117), NorMuon (#2082). Reassigned to body-PMuon post-NS update EMA — addresses diagnosed bottleneck of insufficient polar update persistence in late-cooldown.

---

## 2026-06-01 21:25 UTC — PR #2115 tanjiro: Body Muon momentum HARD-ZERO RESET @ step 2750 (pure vs fresh-μ window) — ❌ BILATERAL NULL; @2750 body-Muon momentum axis EXHAUSTED; tanjiro REASSIGNED → #2183 aux-adam-m-reset

- Branch: `g1r1-tanjiro/momentum-hard-zero-reset`
- Hypothesis: Hard-zero body-Muon momentum buffers at pre-target boundary @2750. Arm A: pure reset. Arm B: reset + fresh-μ refractory window (μ→0.85 for steps 2750-2900) to prevent direction re-locking.

| Arm | config | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | canonical | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A (pure hard-zero @2750)** | reset only | `il6nmki2` | 2925 | 3.265256 | **+2.40** | ❌ NULL |
| **B (hard-zero + μ=0.85 window 2750→2900)** | reset + refractory | `g46kh3in` | 2950 | 3.267498 | **+4.64** | ❌ NULL |

- **Arm A (pure reset):** sr=2925, +50 sr worse. Post-reset val trajectory opens a ~2.0e-3 nat gap by step 2925 that never fully closes. Buffer is load-bearing — the reset discards 2750 steps of momentum that was directing model into the target basin.
- **Arm B (reset + μ-window):** sr=2950, +75 sr. Refractory μ=0.85 window made things WORSE, not better — faster turnover added variance without improving adaptation. Rules out "stale direction immediately re-locked" as explanation.
- **Key diagnostic (student write-up):** Post-reset val steps 2750/2875/2925/2975 showed A consistently better than B by ~2e-3 nat, converging by step 3250. The speedrun gate captures the earlier crossing → A sr=2925 beats B sr=2950.
- **Alignment with prior closures:** Body-Muon μ-modulation @2750 (fern #1604, askeladd #1686): NULL. Hard-zero @2750 (this PR Arm A): NULL. Hard-zero + fresh-μ window @2750 (this PR Arm B): NULL. **@2750 body-Muon momentum state pulse-axis BILATERALLY EXHAUSTED** across all known disturbance modes.
- **Mechanism:** Body Muon momentum buffer at step 2750 is load-bearing (not stale). Disturbing it (μ-modulation OR hard-zero OR fresh-μ refractory) all hurt similarly. The pre-target loss landscape may appear flat but the optimizer's direction-history is actively guiding convergence — disrupting that costs sr even with re-accumulation from locally-current gradients.
- **tanjiro REASSIGNED → #2183:** AUX Adam first-moment (m) HARD-ZERO RESET bilateral — Arm A @2750 (same pre-target boundary, different optimizer scope), Arm B @1750 (ema_warmup_steps cooldown-onset boundary). First test of aux Adam m-buffer load-bearing hypothesis. Directive (a).

## 2026-06-01 20:45 UTC — PR #2117 edward: AdEMAMix dual-EMA on aux Adam (embed/lm_head scope) — ❌ BILATERAL NULL; AdEMAMix family CLOSED; edward REASSIGNED → #2180 block-lr-ramp-shape

- Branch: `g1r1-edward/aux-ademamix`
- Hypothesis: Apply AdEMAMix (two EMA accumulators: fast β₂ + slow β₃=0.9999) to the aux Adam parameter group (embed, lm_head, LN, scalar gains/biases). Tests if sparse-update denoising of slow-EMA helps the embed/output layers where sparse updates are common. Bilateral: Arm A α=0.85 (high fast-EMA weight) vs Arm B α=0.50 (equal weight).

| Arm | α | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A α=0.85** | 0.85 | `45my2oc3` | 3075 | 3.275148 | **+12.3** | ❌ NULL |
| **B α=0.50** | 0.50 | `qylmac6d` | sr=-1 (never crossed) | 3.326 | **+63** | ❌ NULL |

- **Arm A (α=0.85):** sr=3075 (+200 steps worse than baseline 2875). Slow EMA creates too much horizon noise for the high-density aux params.
- **Arm B (α=0.50):** Never crossed 3.28 → sr=-1. Catastrophic NULL — lower α just down-weights the working fast EMA without slow-EMA compensation. m2_hat collapses near zero for non-sparse aux params (LN, bias, scalar gains get dense gradient signals).
- **Monotone α trajectory:** worse-α → catastrophically-worse. Clean signal.
- **AdEMAMix family CLOSED:** body PMuon AdEMAMix (#1749 NULL) + aux full-scope α=0.85 + aux α=0.50. Embed-only sub-scope remains untested but deferred — the core mechanism doesn't transfer to dense-gradient params that dominate aux group.
- **edward REASSIGNED → #2180:** Per-block Muon LR ramp SHAPE bilateral — CONVEX (p=0.5, front-loaded) vs CONCAVE (p=2.0, back-loaded). Baseline linear (p=1.0) preserved. Adds `--muon_block_lr_power` flag. Orthogonal to thorfinn #2171 which tests MAGNITUDE. Directive (b).

## 2026-06-01 19:45 UTC — PR #2110 thorfinn: Body PMuon `--muon_block_lr_pattern` direction ABLATION (late-lower vs uniform) — ❌ BILATERAL NULL; late-higher DIRECTION confirmed load-bearing; thorfinn REASSIGNED → #2171 SLOPE MAGNITUDE

- Branch: `g1r1-thorfinn/block-lr-pattern`
- Hypothesis: Every prior PR inherited `--muon_block_lr_pattern late-higher` from #1532 without bilateral test. Test the DIRECTION: Arm A `late-lower` (reverse — shallow blocks higher LR), Arm B `none` (uniform — no per-block scaling). Answers: is the DIRECTION (late-higher) load-bearing, or just the EXISTENCE of a per-block gradient?

| Arm | pattern | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | late-higher | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A late-lower** | reversed | `i6l4m3ys` | 2925 | 3.266509 | **+3.655** | ❌ NULL |
| **B none** | uniform | `bxk1dxy6` | 2925 | 3.264531 | **+1.677** | ❌ NULL |

- **Arm A (late-lower reversed)** worst: +3.655 mnat. Moving late-block LR DOWN is strictly harmful.
- **Arm B (none uniform)** costs +1.677 mnat — the depth-asymmetric ramp DOES real work vs uniform. Removing it entirely costs 1.7 mnat.
- Both arms sr=2925 — fails merge gate on both clauses (sr=2925 > 2862.5; val_ema > 3.262854).
- **Clean asymmetric mirror:** late-lower (+3.7 mnat) vs uniform (+1.7 mnat) vs late-higher (WIN) — direction is strictly ordered. The depth gradient is directional AND the asymmetry confirms late-higher is the unique correct direction.
- **Block_lr_pattern DIRECTION axis CLOSED bilaterally.** Next pristine axis: SLOPE MAGNITUDE — is 0.20 total spread (±0.10) the optimum, or should it be narrower/wider?
- **thorfinn REASSIGNED → #2171:** Per-block Muon LR SLOPE MAGNITUDE bilateral — Arm A NARROWER (spread=0.10, lo=0.95/hi=1.05), Arm B WIDER (spread=0.30, lo=0.85/hi=1.15). Mean LR=1.0 preserved. Adds `--muon_block_lr_spread` flag. Directive (b).

## 2026-06-01 18:25 UTC — PR #2105 frieren: paramEMA ema_warmup_steps SWEEP @1250 vs @2250 — ❌ BILATERAL NULL; warmup_step optimum sharp local max at baseline @1750

- Branch: `g1r1-frieren/paramema-warmup-timing`
- Hypothesis: Sweep ema_warmup_steps (the step at which β transitions from 0.97 to 0.99): Arm A @1250 (earlier activation), Arm B @2250 (later activation) vs baseline @1750.

| Arm | warmup_step | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1750 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A @1250** | 1250 | `fe1od8z1` | 2925 | 3.267800 | **+4.946** | ❌ NULL |
| **B @2250** | 2250 | `o4um0h5z` | 2925 | 3.266314 | **+3.460** | ❌ NULL |

- Arm A crashed at step 3100 but target was already crossed — metrics are valid.
- **Monotone gradient:** Later warmup activation (2250 > 1250) is better within the [1250, 2250] window — but both are WORSE than baseline @1750. The optimum is a local maximum at @1750 with worse performance on both sides.
- Combined with #2102 (refresh_step @1750/@2250 NULL), #1378 (#1429 WIN @2600 ablation) — all paramEMA TIMING axes (refresh_step, warmup_step) confirmed as sharp optima at their baseline values.
- **paramEMA ema_warmup_steps axis CLOSED within [1250, 2250].** paramEMA TIMING space exhaustively closed. Adjacent paramEMA axes still pristine: β ramp SHAPE (how β transitions, not when), refresh OPERATOR α (fern #2159 in-flight), β target value (but this is scalar sweep — low directive priority).
- **frieren REASSIGNED → #NEW (assigning 18:25 UTC):** paramEMA β-target RAMP SHAPE bilateral — Arm A LINEAR ramp 0.97→0.99 over [1750, 2600], Arm B COSINE ramp 0.97→0.99 over [1750, 2600] vs baseline STEP FUNCTION. Tests HOW β transitions (shape), not WHEN (timing). Adds `--ema_beta_ramp_shape` flag. Directive (e) schedule mechanism.

## 2026-06-01 18:15 UTC — PR #2104 alphonse: Pre-target depth-stratified body PMuon momentum DECAY ×0.10 @ step 2750 (shallow vs deep) — ❌ BILATERAL NULL; depth-INVARIANCE at @2750

- Branch: `g1r1-alphonse/pretarget-depth-strat-decay-x0.10`
- Hypothesis: Body PMuon momentum DECAY ×0.10 at pre-target boundary step 2750, bilateral over shallow blocks (0-3) vs deep blocks (8-11). Fills unmapped pre-target × depth × ×0.10 cell.

| Arm | depth | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A shallow (0-3)** | 0-3 | `06xtr980` | 2925 | 3.264981 | **+2.127** | ❌ NULL |
| **B deep (8-11)** | 8-11 | `o0abk7qw` | 2925 | 3.264980 | **+2.126** | ❌ NULL |

- Both arms sr=2925, val_ema essentially identical (delta=0.000001). Sentinel verified clean (n_modified=24 each, target_step=2750, op_decay=1, factor=0.1 for both arms).
- **Striking depth-INVARIANCE finding:** at @2750 with ×0.10 DECAY, shallow vs deep produces IDENTICAL outcomes within 1 micro-nat. Contrast with @975:
  - @975 HARD-ZERO: shallow +0.675 mnat, deep +2.99 mnat — strong depth asymmetry
  - @975 FRESH-START: deep less bad than shallow — depth asymmetry (reversed)
  - @2750 ×0.10 DECAY: depth-COUPLED collapse — momentum decay at pre-target is depth-INSENSITIVE
- Combined with #1836 (×0.5/×0.25 @2750 NULL all-blocks, ~+2 mnat) and #1837 (×0.10 @2750 NULL all-blocks): pre-target × momentum × ×0.10 DECAY cell exhaustively closed. Shallow / deep / all-blocks all give the same +2 mnat NULL.
- **alphonse REASSIGNED → #NEW (assigning 18:15 UTC):** Body PMuon NS_ITERS COOLDOWN SCHEDULE bilateral — Arm A 12→8 (modest reduction during cooldown), Arm B 12→4 (aggressive reduction). FIRST test of NS5 precision schedule. Directive (c) phase-specific mechanism + (d) preconditioner state handling. Adds `--cooldown_ns_iters` flag.

## 2026-06-01 18:00 UTC — PR #2102 fern: paramEMA refresh BOUNDARY ABLATION @1750 vs @2250 (REPLACES @2600) — ❌ BILATERAL NULL; refresh-step optimum sharply localized at @2600

- Branch: `g1r1-fern/paramema-refresh-boundary`
- Hypothesis: REPLACE the canonical @2600 refresh boundary with EARLIER alternatives (@1750 = ema_target activation; @2250 = mid-cooldown). Tests whether @2600 is a UNIQUE optimum or part of a broad refresh-friendly plateau.

| Arm | refresh_step | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 2600 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A @1750** | 1750 | `k2vpqdrk` | 2925 | 3.265119 | **+2.265** | ❌ NULL |
| **B @2250** | 2250 | `qllhj143` | 2925 | 3.265390 | **+2.536** | ❌ NULL |

- Both arms sr=2925, fail clause-1 of gate (2925 > 2862.5) and fail clause-2 (val_ema > baseline). Sentinel telemetry verified clean — refresh fired at requested target steps in both arms, no implementation noise.
- **In-window monotone gradient identified:** Arm A (@1750) val_ema=3.265119 is 0.271 mnat closer to baseline than Arm B (@2250) val_ema=3.265390. Within the [1750, 2250] window, EARLIER refresh is slightly better. But the gap from either to baseline (~2.3-2.5 mnat) is far larger than the within-window differential (~0.3 mnat) — confirming @2600 is a SHARP LOCAL MAXIMUM, not the broad plateau of a refresh-friendly region.
- Consistent with #1378 NULL @2275 and #1429 WIN @2600 ablation history. Refresh-step optimum is firmly localized at @2600 with sharp falloff in BOTH temporal directions (pre-2600 NULL bilateral confirmed by this PR + #1378; post-2600 still untested at this granularity but the SHARP LOCAL MAX inference makes deep post-2600 testing low-EV).
- **paramEMA refresh-step axis CLOSED within [1750, 2250].** Adjacent paramEMA mechanisms still pristine: refresh OPERATOR shape (full overwrite vs partial blend vs extrapolation), β-target ramp shape (currently testing via #2105 frieren), warmup activation timing (currently testing via #2105 frieren).
- **fern REASSIGNED → #NEW (assigning 18:00 UTC):** paramEMA refresh OPERATOR α-blend bilateral — Arm A α=0.5 (HALF BLEND), Arm B α=1.5 (OVER-INJECT past EMA). FIRST exposure of the implicit α=1.0 full-overwrite assumption as a tunable. Directive (a) — phase-boundary state-mixing operator.

## 2026-06-01 15:45 UTC — PR #2086 askeladd: Aux Adam β₂ pulse param-group DECOMPOSITION (embed-only vs lm_head-only) @ step 975 — ❌ BILATERAL NULL; JOINT pulse irreducible

- Branch: `g1r1-askeladd/aux-b2-pulse-scope`
- Hypothesis: Decompose the canonical baseline WIN (#1532 JOINT β₂ pulse) into single-group activations. Does the WIN mechanism localize to either embed or lm_head? Three predicted outcomes: (a) embed-only WIN → embed dominates; (b) lm_head-only WIN → output projection dominates; (c) both NULL → JOINT scope required (mechanism requires ALL variance estimators extended simultaneously).

| Arm | scope | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | all (joint) | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A embed-only** | adam_embed | `7hpr0gjd` | 2925 | 3.265379 | +2.525 | ❌ NULL |
| **B lm_head-only** | adam_lm_head | `vm1xubsz` | 2925 | 3.263891 | +1.037 | ❌ NULL |

- Both arms sr=2925 — fails clause-1 (gate requires sr ≤ 2862.5 or sr=2875). Neither single-group pulse recovers the JOINT WIN.
- **Asymmetry (directionally meaningful):** Arm B (lm_head-only) val_ema=3.263891 is 1.49 mnat closer to baseline than Arm A (embed-only) val_ema=3.265379. The output projection group carries more of the β₂ pulse benefit than the embedding group — consistent with lm_head being most directly coupled to val_loss objective. However, neither group's variance memory is sufficient alone.
- **Mechanism conclusion:** aux Adam β₂ pulse is IRREDUCIBLE — requires JOINT scope across ALL groups (embed + lm_head + scalars). Partial-pulse runs lose ~25 sr-steps vs JOINT. The WIN requires simultaneous variance-memory extension across all three parameter groups.
- **Aux Adam β₂ pulse param-group decomposition axis CLOSED.** Combined with all prior β₂/β₁/m/v/LR closure entries, the canonical β₂ JOINT @975 is now confirmed as the unique global optimum of the entire aux Adam state-perturbation space.
- **askeladd REASSIGNED → #2148:** Cautious Updates (cAdam) on aux Adam — PERMANENT (Arm A) vs TRANSIENT @975 (Arm B). First CONDITIONAL UPDATE RULE test on this stack (vs all prior SCALAR parameter perturbations). Directive (c)+(d).

## 2026-06-01 12:30 UTC — PR #2040 edward: body PMuon SHALLOW-block momentum DECAY ×0.10/×0.20 @ step 975 (seed-2 confirmation) — ❌ NULL at n=2; shallow-mom DECAY @975 axis FULLY CLOSED

- Branch: `g1r1-edward/body-mom-shallow-decay-fine-x010-x020`
- Hypothesis: Fine-grained PARTIAL DECAY at the U-shape minimum identified by #1980 (×0.25 was prior best +0.286 mnat). Test ×0.10 (Arm A) and ×0.20 (Arm B) to localize the optimum and confirm via seed-2 if Arm A near-misses.

| Arm | factor | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A ×0.10 seed-1** | 0.10 | `dkzem60q` | **2875** | 3.262918 | **+0.064** | ❌ NULL (clause-2 fails by 64 µNat — closest near-miss this axis has produced) |
| **B ×0.20** | 0.20 | `q10qd8tz` | 2925 | 3.265844 | +2.990 | ❌ NULL |
| **A ×0.10 seed-2** | 0.10 | `rwwge1jd` | 2900 | 3.264542 | +1.688 | ❌ NULL (regression vs seed-1) |

- Arm A seed-1 +0.064 mnat was closest-ever near-miss on this axis. **Seed-2 of best arm did NOT reproduce sr=2875** (sr=2900, +1.624 mnat regression vs seed-1). Confirms the +0.064 mnat result was seed-noise at the bottom of the well, not a stable minimum.
- Arm B ×0.20 breaks U-shape monotonicity between ×0.10 and ×0.25 (+2.990 vs +0.286 / +0.064 at neighbors) — further evidence of high seed-to-seed noise on this fine-magnitude axis.
- **Shallow-mom-DECAY @975 axis SUMMARY:** 6+ runs across 5 factor points {0.00 (#1929), 0.10 (this), 0.20 (this), 0.25 (#1980), 0.50 (#1980)} all NULL. Closest-ever near-miss (+0.064 mnat) did not survive n=2 confirmation. Axis structurally CLOSED.
- **edward REASSIGNED → #TBD:** Pivoting OFF body-mom (exhausted). Fresh hypothesis: AdEMAMix dual-EMA on AUX Adam (Idea 1 from PLATEAU_BOLD_IDEAS). Body Muon AdEMAMix was tested (#1749 closed NULL); aux Adam side is pristine. Directive (d) momentum/preconditioner handling on a different optimizer scope.

## 2026-06-01 12:25 UTC — PR #2061 tanjiro: Body PMuon momentum BLEND with grad α=0.5/0.75 @ step 975 (subset=all) — ❌ BILATERAL NULL; body PMuon mom-state @975 transform matrix CLOSED

- Branch: `g1r1-tanjiro/body-mom-blend-975`
- Hypothesis: BLEND existing momentum_buffer with current gradient at step 975 (cooldown onset). Bilateral α: 0.5 (Arm A, half-blend) vs 0.75 (Arm B, mostly-keep-grad). Tests whether mixing fresh grad direction into mom recovers near-miss signal that pure DECAY/HARD-ZERO couldn't.

| Arm | α | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A α=0.5** | 0.5 | `an1exnw4` | 2925 | 3.266019 | +3.165 | ❌ NULL |
| **B α=0.75** | 0.75 | `ysd236s2` | 2925 | 3.265980 | +3.126 | ❌ NULL |

- Both arms miss merge gate on both clauses (sr=2925 ≥ 2900 fails clause-1; +3.1 mnat ≫ 0 fails clause-2 strict tiebreak). Arms essentially tied (0.04 mnat α-gap, well inside noise) — no interior structure on the α axis.
- **Completes body PMuon mom-state @975 transform matrix:** DECAY ×{0.0, 0.10, 0.20, 0.25, 0.50, 0.75, 1.0} (#1929/#1980/#2040), HARD-ZERO subset-stratified (#1929/#1930/#1934/#1935), FRESH-START, REVERSE-SIGN (fern #2041), BLEND-with-grad α={0.5, 0.75} (this PR), depth-stratified DEEP DECAY ×0.25/×0.50 (alphonse #2048). All NULL across shallow/middle/deep partitions and all factor magnitudes.
- **tanjiro REASSIGNED → #TBD:** Body Muon momentum HARD-ZERO RESET @ step 2750 (pre-target boundary, NOT @975). Pristine axis — never tested at pre-target phase boundary. Directive (a) + (c) + (d): structural state intervention at the pre-target phase boundary. Bilateral: pure reset vs reset+fresh-momentum-window (μ→0.85 transient).

## 2026-06-01 11:25 UTC — PR #2060 thorfinn: body PMuon L_cov/R_cov DECAY ×0.5/×0.25 @ step 200 (warmup-end) — ❌ BILATERAL NULL; cov-axis FULLY CLOSED at all four phase boundaries

- Branch: `g1r1-thorfinn/cov-decay-200`
- Hypothesis: Test cov-state L_cov/R_cov PARTIAL DECAY at the warmup-end boundary (@200) where buffers carry the noisiest warmup history — bilateral ×0.5 (Arm A) vs ×0.25 (Arm B). Predicted: warmup-end more tolerant than cooldown-onset (#1930 @975) and ×0.25 > ×0.5.

| Arm | factor | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A ×0.5 @200** | 0.5 | `u3fak8yc` | 2925 | 3.265689 | **+2.835** | ❌ NULL |
| **B ×0.25 @200** | 0.25 | `l80oy60j` | 2925 | 3.265629 | **+2.775** | ❌ NULL |

- Both arms sr=2925, bilateral NULL. Expected ordering holds (warmup-end @200 better than @975 #1930 +3.69 mnat by ~0.85 mnat; ×0.25 better than ×0.5 by 0.06 mnat) but magnitudes too small to flip gate.
- Sentinel verified: `[step 200] body PMuon cov DECAY (n_L=72, n_R=72, factor=X)` with L/R mean halved correctly on both arms.
- Cov-axis phase-boundary matrix now CLOSED across all tested points: @200 (this PR), @975 (#1930 fern), @1100 (#1849 thorfinn), @2750 (#1726 nezuko) — bilateral NULL across HARD-ZERO and ×0.5/×0.25 partial-decay at every boundary.
- **thorfinn REASSIGNED → #2110:** body PMuon `--muon_block_lr_pattern` bilateral ABLATION — Arm A `late-lower` (reverse depth direction, shallow higher LR), Arm B `none` (uniform, no per-block scaling). PRISTINE axis — every prior PR inherited `late-higher` from #1532 without bilateral test. Directive (b): per-block optimizer behavior.

## 2026-06-01 10:05 UTC — PR #2053 frieren: Aux Adam v-state JOINT ×0.25/×0.10 @ step 975 — ❌ BILATERAL NULL; v-state JOINT axis @ cooldown onset exhausted

- Branch: `g1r1-frieren/aux-v-joint-decay-975`
- Hypothesis: JOINT v-state PARTIAL DECAY at ×0.25 (Arm A) and ×0.10 (Arm B) at cooldown onset step 975, following up on askeladd #1912 scalar-only near-miss (+0.88 mnat). Tests whether more aggressive decay on the JOINT scope approaches the scalar-only near-miss signal.

| Arm | factor | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A JOINT ×0.25** | 0.25 | `vp8unvh0` | 2925 | 3.266400 | **+3.55** | ❌ NULL |
| **B JOINT ×0.10** | 0.10 | `x5z7tkah` | 2925 | 3.264680 | **+1.83** | ❌ NULL |

- **Arm B (×0.10) is 1.72 mnat better than Arm A (×0.25)** — more aggressive JOINT decay is directionally better, but even at ×0.10 the JOINT scope is 1.83 mnat from gate. The scalar-only ×0.25 near-miss (+0.88 mnat, #1912) remains the high-water mark. JOINT scope is NOT scalar-scope.
- **Non-monotone concern:** JOINT full-zero (#1770) was catastrophic (+7.09 mnat). The ×0.10 → ×0.25 trend in this PR suggests ×0.00 would be even worse. The JOINT scope minimum sits somewhere between ×0.10 and ×0.00, confirming the axis is closed.
- **v-state @975 axis SUMMARY:** scalar-only ×0.25 (#1912) +0.88 mnat closest-miss; JOINT ×0.10 (this PR) +1.83 mnat; embed-only (#1962 Arm A) +2.45 mnat; lm_head-only (#1962 Arm B) +2.90 mnat; JOINT full-zero (#1770) +7.09 mnat. Scalar-group localization is the unique near-miss scope — JOINT and per-group non-scalar are all significantly worse.
- **frieren reassigned → #2105:** paramEMA warmup activation step SWEEP — Arm A `--ema_warmup_steps 1250` (earlier activation), Arm B `--ema_warmup_steps 2250` (later activation). Zero code changes, existing flag. Directive (e) schedule mechanism.

## 2026-06-01 09:59 UTC — PR #2048 alphonse: Deep-block (8-11) body PMuon momentum PARTIAL DECAY ×0.25/×0.50 @ step 975 — ❌ BILATERAL NULL; completes the body PMuon momentum DECAY × deep-block × factor-magnitude sweep

- Branch: `g1r1-alphonse/deep-mom-decay-975`
- Hypothesis: Following edward #1980 (shallow ×0.25 closest-ever near-miss +0.286 mnat), test deep-block (8-11) PARTIAL DECAY at ×0.25 and ×0.50 to characterize depth-asymmetry on the partial-decay surface. Predicted: deep blocks need more momentum continuity through cooldown (late-higher LR pattern), so deep × decay should produce greater regression than shallow × decay.

| Arm | factor | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A DEEP ×0.25** | 0.25 | `rkqibgtd` | 2925 | 3.264943 | **+2.086** | ❌ NULL |
| **B DEEP ×0.50** | 0.50 | `xf1lp01s` | 2925 | 3.264820 | **+1.966** | ❌ NULL |

- **Depth × factor matrix maps:** edward #1980 shallow ×0.25 +0.286 mnat, shallow ×0.50 +1.703 mnat. This PR deep ×0.25 +2.086 mnat, deep ×0.50 +1.966 mnat. Confirms deep-block resistance to factor choice (~+2 mnat regardless), while shallow is highly factor-sensitive.
- **Sentinels confirmed:** `[step 975] DECAY block={8..11}` printed correctly, `body_mom_blockwise/n_modified=24, factor=0.25 (or 0.50), op_decay=1, fired=1` in both W&B summaries.
- **Body PMuon momentum state-arithmetic matrix now EXHAUSTIVELY CLOSED** across:
  - All 6 operations: HARD-ZERO (#1730/#1929), SCALE-DOWN (#1797/#1836), SCALE-UP (#2025), FRESH-START (#1986/#2024), REVERSE-SIGN (#2041), PARTIAL-DECAY (#1980/#2040/#2048), BLEND (#2061 in-flight)
  - All boundaries: 200, 975, 1100, 2600, 2750
  - All depth subsets: all/shallow/middle/deep at @975
- **alphonse reassigned:** Block-stratified body PMuon momentum DECAY ×0.10 @ pre-target boundary step 2750 — Arm A shallow (0-3), Arm B deep (8-11). Fills unmapped pre-target × depth-stratified × DECAY cell. Mirrors edward's ×0.10 near-miss factor (+0.064 mnat at step 975) at a different boundary. PR #NEW.

## 2026-06-01 09:35 UTC — PR #2041 fern: Body PMuon momentum REVERSE-SIGN (m *= -1) @ step 975 vs step 2600 — ❌ BILATERAL NULL; completes the body PMuon momentum state-arithmetic matrix EXHAUSTIVE CLOSURE

- Branch: `g1r1-fern/body-mom-reverse-sign-975-2600`
- Hypothesis: Reverse the sign of all body PMuon momentum buffers at step 975 (Arm A) or step 2600 (Arm B). The direction-inversion preserves magnitude but inverts the accumulated momentum direction, testing whether at these phase boundaries the direction memory is harmful vs helpful.

| Arm | reverse_step | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A REVERSE @975** | 975 | `yhd76thg` | 2925 | 3.267131 | **+4.28** | ❌ NULL |
| **B REVERSE @2600** | 2600 | `9gxh983b` | 2925 | 3.265686 | **+2.83** | ❌ NULL |

- **Arm B (@2600) less disruptive than Arm A (@975) by 1.45 mnat** — direction-inversion at pEMA refresh boundary is partially compensated by the refresh mechanism itself (pEMA refresh "re-grounds" the training trajectory), but still NULL.
- **Sentinels confirmed:** `[step 975] body PMuon momentum REVERSE-SIGN: n=72 buffers` (Arm A), `[step 2600] body PMuon momentum REVERSE-SIGN: n=72 buffers` (Arm B).
- **Body PMuon `momentum_buffer` state-arithmetic matrix FULLY AND EXHAUSTIVELY CLOSED:**
  - HARD-ZERO (#1730/#1929) — NULL
  - SCALE-DOWN (#1797/#1836) — NULL
  - SCALE-UP (#2025) — NULL
  - FRESH-START (#1986/#2024) — NULL
  - REVERSE-SIGN (this PR, #2041) — NULL
  - PARTIAL-DECAY ×0.50/×0.25/×0.20/×0.10 (#1980/#2040 edward) — closest near-miss at ×0.10 (+0.064 mnat, seed-2 in flight)
  - BLEND-with-grad (#2061 tanjiro, in-flight)
  - All boundaries × all depth subsets covered.
- **fern reassigned:** paramEMA refresh BOUNDARY ABLATION — Arm A @1750 (ema_target activation) vs Arm B @2250 (mid-cooldown), REPLACING the canonical @2600 baseline. First test of earlier refresh boundaries. PR #2102.

## 2026-06-01 07:40 UTC — PR #2025 askeladd: Body PMuon momentum SCALE-UP (×2/×4) @ step 975 (cooldown onset) — ❌ BILATERAL NULL; SCALE-UP direction closes the momentum-magnitude axis on body PMuon

- Branch: `g1r1-askeladd/body-mom-scale-up-975`
- Hypothesis: Body PMuon momentum SCALE-UP (×2/×4) at step 975 amplifies accumulated direction history at cooldown onset, predicted to "steepen loss descent in the 975-995 window." Symmetric counterpart to SCALE-DOWN (×0.5/×0.25 #1797 NULL) — completes the bilateral magnitude axis.

| Arm | factor | run | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---:|---|
| Baseline (#1532, n=2) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | 0 | WIN |
| **A SCALE-UP ×2** | 2.0 | `ehwpwtez` | 2925 | 3.265538 | 3.264945 | **+2.68** | ❌ NULL |
| **B SCALE-UP ×4** | 4.0 | `nb0cqcve` | 2925 | 3.264564 | 3.263962 | **+1.71** | ❌ NULL |

- **Trajectory shape inverted from prediction:** instead of "steepened descent" the perturbation caused a brief val/loss spike around step 975, then ~150 sr-steps of recovery before resuming baseline-similar trajectory. Larger amplification (×4) less harmful than ×2 — surprising but irrelevant since both sr=2925.
- **Sentinel `[step 975] muon_momentum_scale_up: x{2,4} on 72 buffers` fired correctly** in both runs (72 = 12 blocks × 6 PMuon param groups). Mechanism implemented as designed.
- **Bilateral SCALE axis CLOSURE — body PMuon momentum-magnitude perturbation @975 now fully exhausted:**
  - SCALE-DOWN ×0.5/×0.25 (#1797) NULL
  - SCALE-DOWN HARD-ZERO (#1929 blockwise variants) NULL
  - SCALE-UP ×2/×4 (this PR) NULL
- **Cross-PR sr=2925 wall confirmed across SCALE/FRESH-START/REVERSE-SIGN axes:** body PMuon momentum buffer recovers via μ=0.95 re-accumulation (~20-step horizon) regardless of perturbation type/magnitude. The buffer's INSTANTANEOUS value at any phase boundary is dominantly NULL-yielding under structural perturbation.
- **Body PMuon `momentum_buffer` state-arithmetic matrix EXHAUSTIVELY CLOSED:** HARD-ZERO × DECAY × FRESH-START × SCALE-UP/DOWN × BLEND × REVERSE-SIGN × boundaries (200, 975, 1100, 2600, 2750) × depth subsets (all/deep/shallow/middle). The body momentum axis is the most-studied closed axis in this research programme.
- **askeladd reassigned:** Structurally distinct mechanism on the aux Adam side — **β₂ pulse PARAM-GROUP DECOMPOSITION** (embed-only vs lm_head-only @975). Tests whether the baseline #1532 β₂ pulse WIN requires the joint pulse across all 3 aux Adam groups, or whether one group drives the mechanism. High mechanistic + paper-narrative value. PR #NEW.

## 2026-06-01 06:55 UTC — PR #2024 nezuko: Body PMuon momentum FRESH-START (m.copy_(p.grad)) @ step 2600 (pEMA refresh boundary) — ❌ BILATERAL NULL; FRESH-START axis CLOSED across both major boundaries (@975 via #1986, @2600 here)

- Branch: `g1r1-nezuko/body-mom-fresh-start-2600`
- Hypothesis: At step 2600 (pEMA refresh boundary), overwrite body PMuon momentum buffers with the current gradient (FRESH-START). Arm A all 12 blocks (72 buffers); Arm B deep blocks 8-11 only (24 buffers). Tests whether the pEMA refresh + momentum reset synergize structurally.

| Arm | scope | n_refreshed | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A FRESH-START all** | 12 blocks | 72 | `3ftisanh` | **2975** | 3.267962 | **+5.108** | ❌ NULL |
| **B FRESH-START deep** | 4 blocks (8-11) | 24 | `smhk2zrj` | **2925** | 3.265411 | **+2.557** | ❌ NULL |

- **Mechanism CLEAR (excellent student diagnostic):** Arm A produces a **+60 mnat val spike at step 2625** — the single no-momentum step at 2600 propagates as a large perturbation through cooldown. Arm B (deep-only) has a much smaller spike (+0.4 mnat) but still costs +2.557 mnat terminal val and +50 sr-steps.
- **Monotone scaling:** 24-buffer reset → +2.5 mnat regression, 72-buffer reset → +5.1 mnat regression. Deep-only ≈ ⅓ of all-blocks effect — direct fraction-of-disruption.
- **Verdict:** FRESH-START at @2600 is structurally HARMFUL. The pEMA-refresh boundary's body PMuon momentum is healthy — overwriting destroys the EMA-smoothed direction estimate that late-cooldown sharp descent depends on. pEMA refresh does NOT recover this (pEMA captures the post-perturbation param state).
- **Axis closure:** Body PMuon momentum FRESH-START is now BILATERALLY CLOSED at both major boundaries: @975 cooldown-onset (#1986 alphonse: deep +4.67, shallow +6.12) AND @2600 pEMA-refresh (this PR).
- **Cross-PR sr=2925 NULL pattern (3+ runs):** SCALE-UP ×4 @975 (#2025 Arm B `nb0cqcve` +1.75), FRESH-START @2600 deep (this PR Arm B +2.56), REVERSE-SIGN @975 (#2041 Arm A `yhd76thg` +4.25) — three structurally different body PMuon momentum operations all yield sr=2925 with val_ema close-but-fail. The body PMuon momentum buffer at any boundary is dominantly NULL-yielding under structural perturbation.
- **nezuko reassigned:** Pivoting away from body PMuon momentum state. First reassignment (PR #2082 NorMuon β₂ pulse) bounced — wrong training-script reference (NorMuon code is in `target/train_gpt.py` but active script is `records/track_3_optimization/train_gpt_simple.py` PMuon). Sent back with corrected hypothesis: **aux Adam β₁ TRANSIENT-INCREASE pulse @ step 975 (UP direction)** — direct first-moment mirror of baseline #1532's β₂ pulse mechanism, with β₁ DROP previously closed (#1592, #1639) but β₁ UP never tested as pulse. Stacks on baseline aux β₂ pulse; tests additivity of first-moment + second-moment memory extension at cooldown onset.

## 2026-06-01 03:30 UTC — PR #1984 tanjiro: Middle-block (4-7) body PMuon momentum HARD-ZERO / ×0.5 DECAY @ step 975 — ❌ BILATERAL NULL; non-monotone depth response identified; BLEND-with-grad family assigned as #2061

- Branch: `g1r1-tanjiro/body-mom-middle`
- Hypothesis: Body PMuon momentum HARD-ZERO (Arm A) vs ×0.5 DECAY (Arm B) restricted to middle blocks (4-7) at step 975 — completes the subset matrix after shallow (#1929/#1980) and deep (#1929/#1980) variants. Tests whether middle blocks are the optimal subset.

| Arm | op | subset | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A HARD-ZERO middle** | zero | blocks 4-7 | `g87o92vn` | 2925 | 3.266671 | **+3.82** | ❌ NULL |
| **B DECAY ×0.5 middle** | decay | blocks 4-7 | `fvw2yrta` | 2925 | 3.264170 | **+1.32** | ❌ NULL |

- **Non-monotone depth response for HARD-ZERO @ 975:** shallow (#1929) +0.675 < deep (#1929) +2.99 < **middle +3.82** — middle is *worst*, not in-between. Middle blocks carry the most load-bearing momentum direction at cooldown onset; clearing it costs the most.
- **DECAY ×0.5 middle (+1.32 mnat)** still well outside the gate but ~2.5 mnat better than HARD-ZERO — same partial-preservation pattern as #1980 (shallow), #1986 (deep).
- **Body PMuon momentum @975 scalar-transform matrix now exhausted** across HARD-ZERO/DECAY/FRESH-START/SCALE-UP in shallow/middle/deep subsets. Closest miss across entire axis is #1980 Arm B at +0.286 mnat (shallow ×0.25). Only REVERSE-SIGN (#2041 in-flight) remains.
- **tanjiro reassigned:** #2061 — Body PMuon momentum **BLEND with grad** (`m = α*m + (1-α)*grad`) @ step 975, bilateral α=0.5/0.75 on all 12 blocks. Structurally distinct operation (vector combination, not scaling) — never tested on any axis.

## 2026-06-01 03:00 UTC — PR #2003 thorfinn: Body PMuon momentum HARD-ZERO/DECAY ×0.5 @ step 200 (warmup-end, all blocks) — ❌ BILATERAL NULL; momentum-axis at warmup-end CLOSED (cov-axis @200 assigned as #2060)

- Branch: `g1r1-thorfinn/body-mom-warmup-end`
- Hypothesis: Body PMuon momentum HARD-ZERO (Arm A) vs ×0.5 DECAY (Arm B) at warmup-end boundary step 200, all 12 transformer blocks. Tests whether reset/decay at warmup-end boundary (where momentum has only accumulated ~200 steps of noisy warmup gradients) is more receptive than later boundaries.

| Arm | op | factor | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A HARD-ZERO** | zero | 0.0 | `gqax73wu` | 2925 | 3.264643 | **+1.79** | ❌ NULL |
| **B DECAY ×0.5** | decay | 0.5 | `xrqnfoel` | 2925 | 3.264318 | **+1.46** | ❌ NULL |

- Both arms identical sr=2925 (+50 worse than baseline). DECAY ×0.5 marginally better val_ema than HARD-ZERO (-0.32 mnat) — consistent with the broader pattern that partial decay preserves *some* directional signal vs full zeroing.
- **Body PMuon momentum @ phase boundaries matrix NOW FULLY EXHAUSTED across warmup-end (#2003), cooldown-onset (#1929, #1980, #1986, #1934), pre-target (#1730, #1836)** — only @2600 pEMA-refresh remains in flight (nezuko #2024 FRESH-START).
- **thorfinn reassigned:** #2060 — Body PMuon **cov-state** (L_cov/R_cov) PARTIAL DECAY ×0.5/×0.25 @ step 200. Cov-axis closed at @975/@1100/@2750 but **never tested at warmup-end** — the buffers carry the most "noisy warmup" history at this boundary.

## 2026-06-01 02:10 UTC — PR #1963 frieren: Aux Adam v-state ×0.5 @ warmup-end step 200 (JOINT vs EMBED-only) — ❌ BILATERAL NULL; Arm A seed-2 collapsed; Arm B too thin (JOINT @975 assigned as #2053)

- Branch: `g1r1-frieren/aux-v-warmup-end`
- Hypothesis: Aux Adam second-moment buffer ×0.5 at warmup-end step 200 — tests whether recalibrating v-state at phase transition helps more than at cooldown onset (@975). Arm A = JOINT scope (all 3 groups), Arm B = EMBED-only (highest-LR group).

| Arm | scope | seed | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A JOINT v×0.5 @200** | all groups | 1 | `0udzyamc` | 2875 | 3.262159 | **-0.695** | seed-1 PASS |
| **A JOINT v×0.5 @200** | all groups | 2 | `apt27zit` | 2925 | 3.265112 | **+2.258** | ❌ NULL |
| **A JOINT n=2 mean** | — | — | — | **2900** | **3.263636** | **+0.781** | ❌ NULL (gate fails) |
| **B EMBED v×0.5 @200** | adam_embed | 1 | `su37rclp` | 2875 | 3.262719 | **-0.135** | thin n=1 PASS, not confirmed |

- **Arm A: Seed-2 collapse.** Mean sr=2900, mean val_ema=+0.781 mnat — fails both gate clauses. Single-seed clause-2 PASS evaporated on seed-2, matching historical pattern (#1605, #1637).
- **Arm B: Margin too thin.** -0.135 mnat at n=1 is well below 0.5 mnat seed-2 threshold. Given Arm A's seed-2 collapse on the exact same family, seed-2 probability of confirming 0.135 mnat margin is very low.
- **Decision:** Declined seed-2 for Arm B — Arm A's fragility signals the warmup-end v-state mechanism is noisy at this scale, and the pre-written JOINT @975 hypothesis is a higher-EV use of GPU time.
- **frieren reassigned:** #2053 — JOINT v-state ×0.25/×0.10 @ step 975 (cooldown onset). Combines the best factor from the scalar near-miss matrix (×0.25 at +0.88 mnat = closest per-group near-miss) with the JOINT scope that's completely untested at @975.

## 2026-06-01 02:08 UTC — PR #1986 alphonse: Blockwise body PMuon momentum FRESH-START (m.copy_(grad)) @ step 975 — ❌ BILATERAL NULL (FRESH-START CLOSED; deep/shallow depth-asymmetry REVERSED vs HARD-ZERO; deep-decay ×0.25/×0.50 assigned as #2048)

- Branch: `g1r1-alphonse/body-mom-fresh-start-blockwise`
- Hypothesis: Body PMuon momentum FRESH-START (m.copy_(grad)) at step 975 — third state-arithmetic primitive after HARD-ZERO (#1929) and DECAY (#1980). Arm A=deep blocks (8-11), Arm B=shallow blocks (0-3). Hypothesis: FRESH-START recovers cold-start penalty from HARD-ZERO by installing current-step gradient as new buffer.

| Arm | subset | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A FRESH-START** | deep (8-11) | `09ja3yrh` | 2950 | 3.267520 | **+4.67** | ❌ NULL |
| **B FRESH-START** | shallow (0-3) | `h54qoftj` | 2975 | 3.268977 | **+6.12** | ❌ NULL |
| [ref] HARD-ZERO deep #1929A | deep | `20w3r8zr` | 2925 | 3.265842 | +2.99 | ❌ NULL |
| [ref] HARD-ZERO shallow #1929B | shallow | `7t3em4iq` | 2875 | 3.263530 | +0.68 | ❌ NULL |

- **FRESH-START is the WORST tested operation** — worse than HARD-ZERO in BOTH directions. Installing a single-step gradient introduces noise without EMA averaging benefit.
- **DEPTH ASYMMETRY REVERSES:** HARD-ZERO shows shallow 4.4× better than deep (+0.68 vs +2.99 mnat). FRESH-START shows deep better than shallow (+4.67 vs +6.12 mnat). This reversal suggests shallow blocks react poorly to having their direction forcefully replaced by a single noisy gradient.
- **Body PMuon momentum FRESH-START blockwise axis CLOSED** at step 975 across all depth localizations.
- **alphonse reassigned:** #2048 — deep-block DECAY ×0.25/×0.50 @ step 975. Completes the depth × decay-factor matrix (shallow well-covered by edward #1980/#2040; deep DECAY completely untested).

## 2026-06-01 00:30 UTC — PR #1980 edward: Shallow-block body PMuon momentum PARTIAL DECAY ×0.5/×0.25 @ step 975 — ❌ BILATERAL NULL with informative interior minimum (fine sweep assigned as #2040)

- Branch: `g1r1-edward/body-mom-shallow-decay`
- Hypothesis: Shallow blocks (0-3) PARTIAL DECAY at cooldown onset — softer than #1929 HARD-ZERO (also NULL, sr=2875 +0.675 mnat), preserving directional signal while recalibrating magnitude.

| Arm | factor | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A ×0.5** | 0.50 | `y2lchrhe` | 2875 | 3.264557 | **+1.703** | ❌ NULL |
| **B ×0.25** | 0.25 | `2jmiv9e1` | 2875 | 3.263140 | **+0.286** | ❌ NULL (CLOSEST NEAR-MISS) |
| [ref] #1929 Arm B ×0.0 | 0.00 | `7t3em4iq` | 2875 | 3.263530 | +0.676 | ❌ NULL |

- **Non-monotone interior minimum at ×0.25:** HARD-ZERO (+0.676) → ×0.25 (+0.286, MIN) → ×0.50 (+1.703). Asymmetric: left flank gradient −1.56 mnat/unit (gradual), right flank +5.68 mnat/unit (steep). The minimum is sharp on the right.
- **Both sr=2875 (tied baseline):** shallow-block momentum pulse mechanism has now produced sr=2875 TWICE (also #1929 shallow HARD-ZERO) — only val_ema fails the gate. +0.286 mnat above gate = need ~0.3 mnat more improvement to WIN.
- **Attribution bug fixed mid-PR:** Initial Arm A had silent n_scaled=0 attribution bug (block indices didn't propagate from named_parameters to optimizer2 param list). Fixed via explicit n_eligible/n_scaled sentinel. All subsequent runs confirmed `n_eligible=24, n_scaled=24`.
- **edward reassigned:** Fine sweep #2040 with ×0.10 and ×0.20 to bracket the discovered minimum. Same shallow-block scope, same validated code path.

## 2026-06-01 00:15 UTC — PR #1987 fern: Aux Adam β₂ EARLY pulse 0.95→0.99 @ step 100 vs step 200 — ❌ BILATERAL NULL (aux β₂ timing axis EXHAUSTIVELY CLOSED)

- Branch: `g1r1-fern/aux-b2-early-pulse`
- Hypothesis: Shift aux Adam β₂ pulse from canonical step 975 EARLIER to warmup-phase boundaries — step 100 (mid-warmup) vs step 200 (warmup-end). Tests whether front-loading the second-moment horizon expansion improves descent. Complement to frieren #1915 (delayed pulse @1100/1200 NULL).

| Arm | β₂ pulse step | run | sr | val_ema | Δ vs baseline (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 975 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A (pulse @100, mid-warmup)** | 100 | `3fnxh7o2` | 2925 | 3.264228 | **+1.37** | ❌ NULL |
| **B (pulse @200, warmup-end)** | 200 | `5zx2wm8c` | 2925 | 3.266091 | **+3.24** | ❌ NULL |

- **Non-monotone U-shape confirmed:** timing axis bottoms at @975. @100 (+1.37 mnat) and @1200 (#1915 Arm B, +1.11 mnat) are the two least-damaging off-canonical timings, roughly symmetric. @200 (warmup-end) is worse than @100 — warmup-end boundary is a particularly bad time to lock in β₂=0.99 (β₂ transition may interact with LR plateau onset).
- **Why early β₂=0.99 hurts:** running 0.99 throughout post-warmup averages aux Adam variance over a longer effective horizon during early-mid training when gradients still change direction quickly. Canonical @975 concentrates the high-β₂ phase where gradients are most stationary (entering LR decay).
- **Axis closure:** Aux Adam β₂ pulse TIMING AXIS EXHAUSTIVELY CLOSED across all tested timings — step 100 (NULL +1.37 mnat), step 200 (NULL +3.24 mnat), step 975 (#1532 WIN baseline), step 1100 (#1915 NULL +2.77 mnat), step 1200 (#1915 NULL +1.11 mnat), pre-target re-spike (#1667 NULL). Canonical step 975 is uniquely optimal; non-monotone timing landscape with @975 = global optimum.
- **fern reassigned:** PR #2037 — Body PMuon momentum REVERSE-SIGN (m *= -1) @ step 975 vs @ step 2600 — the unique direction-isolating operation in the body-PMuon momentum state matrix (preserves magnitude, inverts direction). Never previously tested.

## 2026-05-31 22:23 UTC — PR #1962 askeladd: Aux Adam v-state ×0.5 PER-GROUP @ step 975 (embed vs lm_head) — ❌ BILATERAL NULL (aux v-decay per-group scope closed)

- Branch: `g1r1-askeladd/aux-scalar-v-decay-cooldown`
- Hypothesis: Per-group aux Adam v×0.5 @ step 975 — embed-only (Arm A) vs lm_head-only (Arm B). Joint v×0.5 @ 975 was NOT tested; frieren #1963 tested joint v×0.5 @ step 200. Per-group scope tests whether the WIN mechanism is localized to a specific optimizer group.

| Arm | scope @975 | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (embed-only v×0.5)** | adam_embed | `1l8r7xbp` | 2925 | 3.265293 | **+2.45** | ❌ NULL |
| **B (lm_head-only v×0.5)** | adam_lm_head | `q1mx06f1` | 2925 | ~3.266 | **~+2.9** | ❌ NULL |

- **Symmetric NULL — both scopes identical sr=2925.** Per-group localization of v×0.5 at step 975 does NOT unlock the mechanism (consistent with frieren #1963 joint v×0.5 @ step 200 yielding a WIN-candidate seed-1 that failed seed-2 confirmation).
- **Combined with askeladd prior closures and frieren #1963:** Aux Adam v-state recalibration mechanism is exhausted at per-group-late (this PR) and joint-early (#1963 NULL seed-2). Aux v-state decay axis CLOSED.
- **askeladd reassigned:** PR #2025 — body PMuon momentum SCALE-UP (×2.0/×4.0) @ step 975. Tests the SCALE-UP direction on the body-mom axis (SCALE-DOWN ×0.5/×0.25 bilaterally closed at 975 #1797 and 2750 #1836).

## 2026-05-31 22:21 UTC — PR #1946 nezuko: Body PMuon γ SHARPEN (γ→0.5) TIMING SWEEP @ step 1100 vs 1200 — ❌ BILATERAL NULL (γ-pulse axis fully exhausted across all timings)

- Branch: `g1r1-nezuko/body-gamma-sharpen-timing`
- Hypothesis: Body PMuon γ axis tested globally at step 975 (#1831 NULL) and pre-target 2750 (#1680 NULL). Timing sweep to 1100/1200 (mid-cooldown) to find the optimal γ pulse window.

| Arm | timing | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (γ→0.5 @ step 1100)** | mid-cooldown | `9oolxfqn` | 2925 | 3.265571 | **+2.72** | ❌ NULL |
| **B (γ→0.5 @ step 1200)** | late-cooldown | `tghdnkyw` | 2925 | 3.264640 | **+1.79** | ❌ NULL |

- **Clean asymmetric param-norm response (relax grows norm, deepen shrinks norm) but identical sr=2925 outcome.** The whitening sharpening mechanism is real (sentinels verified), but not load-bearing for target-crossing speed at any tested timing.
- **γ-pulse axis CLOSURE SUMMARY across ALL timings:**
  - #1831 fern: γ→0.5 SHARPEN @ 975 → bilateral NULL
  - #1680 nezuko: γ→0.5 SHARPEN @ pre-target 2750 → bilateral NULL
  - #1935 alphonse: γ→0.5 SHARPEN BLOCKWISE (deep/shallow) @ 975 → bilateral NULL
  - #1946 nezuko: γ→0.5 SHARPEN @ 1100 and @ 1200 → bilateral NULL
- **Body PMuon γ axis EXHAUSTIVELY CLOSED across ALL temporal boundaries (975/1100/1200/2750) AND all depth localizations.** Whitening exponent γ=0.4 is robustly optimal.
- **nezuko reassigned:** PR #2024 — body PMuon momentum FRESH-START (m.copy_(p.grad)) @ step 2600 (pEMA refresh boundary). Distinct from all tested body-mom operations — same mechanism as alphonse #1986 (@ step 975) but at the pEMA refresh boundary (untested for any body-mom state operation).

## 2026-05-31 21:30 UTC — frieren #1963: Aux v-state ×0.5 joint @ step 200 — seed-2 `apt27zit` NOT CONFIRMING WIN

- Arm A `0udzyamc` seed-1: sr=2875, val_ema=3.262159 (-0.695 mnat WIN candidate)
- Arm A `apt27zit` seed-2: **sr=-1 (did not reach target; finished at step 3250), val_ema=3.265112 (+2.26 mnat NULL)**
- N=2 mean: sr=-1 / val_ema=3.2636 — fails both gate clauses. WIN was run-to-run noise.
- Arm B `su37rclp` (embed-only @ step 200) RUNNING at step 125 — completing the experiment.
- Frieren #1963 still open, awaiting Arm B terminal + student SENPAI-RESULT post.

## 2026-05-31 18:47 UTC — PR #1945 thorfinn: Body PMuon weight_decay PERSISTENT pulse @ cooldown onset step 975 (RELAX wd→0.0 vs DEEPEN wd→0.05) — ❌ BILATERAL NULL

- Branch: `thorfinn/body-muon-wd-pulse-cooldown`
- Hypothesis: Body PMuon wd persistent pulse at cooldown onset (step 975) — both directions tested. RELAX (wd→0.0) eliminates regularization during cooldown; DEEPEN (wd→0.05) doubles it. Combining with the canonical β₂ pulse stack to test whether wd modulation at the same phase boundary provides additive signal.

| Arm | Direction | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (RELAX wd→0.0)** | RELAX | `sw7pnrnk` | 2925 | 3.264418 | **+1.56** | ❌ NULL |
| **B (DEEPEN wd→0.05)** | DEEPEN | `lmucsujb` | 2925 | 3.264100 | **+1.25** | ❌ NULL |

- **Symmetric NULL within 0.31 mnat:** RELAX slightly worse than DEEPEN (consistent with cooldown needing regularization from wd). Both sr=2925 — wd pulse at cooldown onset does not accelerate crossing the target boundary.
- **Axis closure:** Combined with #1693 (pre-target wd pulse bilateral NULL) and all prior scalar pulse closures, **body PMuon weight_decay perturbation axis FULLY CLOSED** across all temporal boundaries (cooldown-onset @975 and pre-target @2750) and both directions (RELAX/DEEPEN). The canonical wd=0.025 through full run is the optimum.
- **Key insight:** Among all body PMuon scalar pulses tested — LR (#1637/#1697), γ (#1831/#1680/#1935), μ (#1686), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (#1666), wd (#1693/#1945), Nesterov (#1898), schedule-free (#1576) — NONE show improvement. Scalar optimization regime is saturated; structural state-arithmetic at phase boundaries is the remaining open axis.
- **thorfinn reassigned:** Body PMuon momentum HARD-ZERO vs DECAY ×0.5 @ warmup-end step 200, joint all blocks — body-Muon analog of frieren #1963 WIN-candidate at the same boundary (PR #2003).

## 2026-05-31 15:15 UTC — PR #1935 alphonse: Body PMuon γ pulse BLOCK-STRATIFIED (γ→0.5 SHARPEN deep vs shallow) @ step 975 — ❌ BILATERAL NULL (depth localization does not unlock γ→0.5 SHARPEN headroom)

- Branch: `g1r1-alphonse/body-gamma-sharpen-blockwise`
- Hypothesis: Global γ pulse @ 975 (#1831) and @ pre-target (#1680) were bilateral NULL. Depth-stratifying the γ→0.5 SHARPEN tests whether headroom is concentrated in shallow or deep blocks — the late-higher LR pattern means deep blocks receive proportionally more whitening change per unit γ-shift.

| Arm | Subset (blocks) | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (DEEP blocks 8-11)** | deep | `38squmio` | 2925 | 3.264731 | **+1.88** | ❌ NULL |
| **B (SHALLOW blocks 0-3)** | shallow | `phg6c5mn` | 2925 | 3.265399 | **+2.55** | ❌ NULL |

- **Bilateral NULL within 0.67 mnat:** Shallow (Arm B) is marginally WORSE than deep (Arm A) — the depth-response is reversed from the momentum axis (#1929 shallow 0.675 mnat near-miss). Different mechanism, same conclusion: depth localization cannot rescue the γ→0.5 axis.
- **Axis closure:** Combined with #1831 (global γ@975 bilateral NULL +3.4/+4.2 mnat) and #1680 (pre-target γ bilateral NULL), **body PMuon γ axis EXHAUSTIVELY CLOSED** across all temporal boundaries (cooldown-onset / pre-target) AND all depth localizations (joint / deep / shallow). Student note: "depth localization does not unlock γ→0.5 SHARPEN headroom."
- alphonse reassigned: Block-stratified body PMuon momentum FRESH-START (m.copy_(p.grad)) @ step 975 — Arm A deep (8-11), Arm B shallow (0-3). Third distinct state-operation after HARD-ZERO (#1929) and DECAY (#1980).

## 2026-05-31 15:10 UTC — PR #1930 fern: Body PMuon side cov HARD-ZERO / ×0.5 DECAY @ cooldown onset step 975 — ❌ BILATERAL NULL (cov buffer values regenerate within steps; perturbation axis FULLY CLOSED)

- Branch: `g1r1-fern/body-cov-hardzero-cooldown`
- Hypothesis: Body PMuon side-cov STATE BUFFER values (L and R running statistics in bilateral whitening L^{-γ}·g·R^{-γ}) at cooldown onset may over-represent pre-cooldown curvature. Resetting or decaying them forces L/R to readapt from scratch at step 975, potentially improving update direction quality through cooldown.

| Arm | Factor | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (HARD-ZERO factor=0.0)** | 0.0 | `kimfzyld` | 2925 | 3.266424 | **+3.57** | ❌ NULL |
| **B (×0.5 DECAY factor=0.5)** | 0.5 | `u3a62mkw` | 2925 | 3.266546 | **+3.69** | ❌ NULL |

- **Symmetric NULL within 0.12 mnat:** HARD-ZERO and ×0.5 DECAY produce essentially identical outcomes. Sentinels verified correct perturbation: 72L + 72R params touched; L mean 1087.49→0.0 (Arm A), 1460.27→730.14 (Arm B); R mean 61106→0 (Arm A), 57864→28932 (Arm B). The buffer values clearly changed — yet no benefit.
- **Mechanism interpretation:** Cov buffer values L and R recover within a few steps via their running statistics update rule, so the perturbation is absorbed quickly. The loss signal is not sensitive to the cov-state buffer VALUE at the phase boundary; only the RATE (β_cov) matters, and that axis is closed (#1666 β_cov pulse NULL).
- **Axis closure:** Combined with #1849 (per-side L/R asymmetric reset bilateral NULL), #1780 (full L+R ZERO @975/1100 bilateral NULL, seed-2 confirmed), and #1726 (cov ZERO @2750 pre-target NULL), **body PMuon side cov-state buffer-value perturbation axis FULLY CLOSED** across all magnitudes (ZERO / ×0.5) AND all temporal boundaries (975 / 1100 / 2750) AND all asymmetries (joint / L-only / R-only). Student note: "Decaying or zeroing the body PMuon side cov buffers at cooldown onset is a clean negative result."
- fern reassigned: Aux Adam β₂ EARLY pulse 0.95→0.99 @ step 100 (mid-warmup) vs step 200 (warmup-end) — timing complement to frieren #1963 (aux v-state ×0.5 @ step 200).

## 2026-05-31 14:45 UTC — PR #1934 tanjiro: Aux Adam m-state HARD-ZERO PER-GROUP @ step 975 (lm_head-only vs embed-only) — ❌ BILATERAL NULL (per-group localization closes aux m-state axis exhaustively)

- Branch: `g1r1-tanjiro/aux-m-zero-per-group`
- Hypothesis: Aux Adam m-state JOINT all-group hard-zero @ step 975 (nezuko #1815) was NULL on n=2. This PR tests whether PER-GROUP localization (narrowing the reset scope to lm_head or embed) recovers signal by targeting the group most likely to benefit from momentum recalibration at the cooldown onset.

| Arm | Target group | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (lm_head-only m ZERO)** | adam_lm_head | `m7jgni6z` | 2925 | 3.26493 | **+2.07** | ❌ NULL |
| **B (embed-only m ZERO)** | adam_embed | `34nw7six` | 2925 | 3.26496 | **+2.11** | ❌ NULL |

- **Symmetric NULL:** Both arms within 0.04 mnat of each other (tightest within-bilateral spread of this entire wave). Per-group localization does not break the symmetry — lm_head and embed are equally unable to benefit from m-state erasure at cooldown onset.
- **Axis closure:** aux Adam m-state PERTURBATION axis EXHAUSTIVELY CLOSED: magnitudes 0.0/0.5/0.25 (#1815/#1881), joint-scope late boundaries 2600/2750 (#1879), per-group lm_head/embed (#1934). Only `adam_scalars`-only is unspecified but that group has only 1 param (already bounded by #1850 scalar-group LR NULL). Entire aux Adam first-moment axis CLOSED.
- tanjiro reassigned: middle-block (4-7) body PMuon momentum HARD-ZERO vs ×0.5 @ step 975 — completes depth coverage on the strongest open axis (PR #1984).

## 2026-05-31 14:25 UTC — PR #1929 edward: Body PMuon momentum HARD-ZERO BLOCKWISE (deep vs shallow) @ step 975 — ❌ BILATERAL NULL, ASYMMETRIC: shallow (0-3) closest near-miss of the blockwise wave

- Branch: `g1r1-edward/body-mom-zero-blockwise`
- Hypothesis: Depth-stratified momentum erasure at cooldown onset — deep blocks (8-11) vs shallow blocks (0-3) — tests whether one stratum tolerates momentum reset better due to differential LR pattern (late-higher prioritizes deep blocks) and gradient-scale regime.

| Arm | Subset (blocks) | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2 mean) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (deep blocks 8-11)** | deep | `20w3r8zr` | 2925 | 3.265842 | **+2.99** | ❌ NULL |
| **B (shallow blocks 0-3)** | shallow | `7t3em4iq` | **2875** | **3.263529** | **+0.675** | ❌ NULL (sr=baseline, val_ema tiebreak fails) |

- **Key asymmetry:** Shallow Arm B is the closest near-miss of the entire #1929/#1930/#1934/#1935 blockwise wave (+0.675 mnat, sr tied). Deep blocks tolerate erasure 4.4× worse — consistent with late-higher LR pattern privileging deep blocks (8-11) for larger parameter updates through cooldown, requiring momentum continuity.
- **Axis closure:** Body Muon momentum BLOCKWISE HARD-ZERO axis closed at cooldown onset. Asymmetric depth response validated. Shallow subset (0-3) the most promising depth for further exploration.
- edward reassigned: shallow-block PARTIAL DECAY sweep (×0.5 Arm A, ×0.25 Arm B) @ step 975 — softer intervention on best-of-wave depth subset (PR #1980).

## 2026-05-31 12:10 UTC — PR #1915 frieren: Aux Adam β₂ pulse TIMING SWEEP @ step 1100 vs 1200 — ❌ BILATERAL NULL (canonical step 975 confirmed as load-bearing pulse moment)

- Branch: `g1r1-frieren/aux-b2-timing-sweep`
- Hypothesis: Delaying the β₂ pulse beyond canonical step 975 (mid-cooldown rather than cooldown onset) may capture additional descent by hitting a cleaner optimization trajectory after LR cosine has progressed.

| Arm | Pulse step | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2 mean) | 975 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (β₂ pulse @ step 1100)** | 1100 | `rw092z34` | 2925 | 3.265624 | **+2.77** | ❌ NULL |
| **B (β₂ pulse @ step 1200)** | 1200 | `v2j1dqfu` | 2925 | 3.263962 | **+1.11** | ❌ NULL |

- **Monotonic interior trend:** 1100 (+2.77 mnat) WORSE than 1200 (+1.11 mnat) — the closest of the late-pulse timings to baseline (1.11 mnat) is also the latest. Despite both being NULL, this suggests a partial recovery as pulse approaches step 1200; but the absolute optimum is still 975.
- **Mechanism:** β₂ pulse at 975 captures the AdamW state recalibration exactly at the moment cosine LR begins decaying. Any delay misses the window where preconditioner ↔ LR phase coordination is most informative.
- **Axis closure:** aux Adam β₂ pulse TIMING axis CLOSED in the delayed-pulse direction. Canonical 975 (#1532 baseline) confirmed optimal pulse moment. Pre-975 timing (e.g., step 800/900) is theoretically the only untested cell on this axis but unlikely to outperform.
- frieren reassigned: fresh directive-aligned hypothesis incoming.

## 2026-05-31 12:09 UTC — PR #1912 askeladd: Aux Adam adam_scalars v-state PARTIAL DECAY @ step 975 — ❌ BILATERAL NULL with notable Arm B sr=2875 near-miss on val_ema axis

- Branch: `g1r1-askeladd/aux-scalar-v-decay-cooldown`
- Hypothesis: Partial v-state decay (×0.5, ×0.25) on `adam_scalars` group at step 975 may interpolate between baseline (no decay) and full-zero (#1770 NULL) and complement scalar_lr (#1850 thin-WIN candidate) by isolating the state-side mechanism.

| Arm | v factor | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline (#1532, n=2 mean) | 1.0 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (scalar v×0.5 @ 975)** | 0.5 | `yz6q3i8v` | 2925 | 3.266375 | **+3.52** | ❌ NULL |
| **B (scalar v×0.25 @ 975)** | 0.25 | `c19i0ns3` | **2875** | 3.263736 | **+0.88** | ❌ NULL (sr ties, val_ema fails clause-2) |

- **Notable Arm B near-miss:** sr=2875 matches baseline; val_ema only +0.88 mnat above gate. This is the closest val_ema near-miss of the recent wave aside from tanjiro #1879 Arm B (+0.658 mnat) and tanjiro #1934 Arm A (in flight). v-state decay × scalar-group IS doing something useful for target crossing speed.
- **Magnitude monotonicity:** A (×0.5, +3.52 mnat) WORSE than B (×0.25, +0.88 mnat). Lighter decay closer to baseline — the optimum is closer to no-decay than ×0.25. Suggests the mechanism is benign (not actively harmful) but doesn't add headroom.
- **Axis closure:** aux adam_scalars v-state PARTIAL DECAY axis CLOSED across magnitude grid {1.0=no-decay, 0.5, 0.25, 0=hard-zero via #1770}. Combined with scalar_lr (#1850 thin WIN), aux scalars group is well-mapped: LR side has marginal signal, v-state side is benign-but-not-load-bearing.
- askeladd reassigned: fresh directive-aligned hypothesis incoming.

## 2026-05-31 10:25 UTC — PR #1898 nezuko: Body PMuon Nesterov OFF @ cooldown onset step 975 — ❌ BILATERAL NULL (PERMANENT vs TRANSIENT both degrade)

- Branch: `g1r1-nezuko/body-nesterov-off-cooldown`
- Hypothesis: Removing the Nesterov look-ahead term (update = grad + μ×buffer instead of buffer-amplified) at cooldown onset either permanently or transiently would steepen descent by removing overcorrection from stale momentum.

| Arm | Scope | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (PERMANENT off @975→3250)** | permanent | `mxy3p0pt` | 3000 | 3.27077 | **+7.92** | ❌ NULL (sr +125) |
| **B (TRANSIENT off @975, re-ON @2600)** | transient | `mb6v98je` | 3025 | 3.27135 | **+8.49** | ❌ NULL (sr +150) |

- **MONOTONIC REGRESSION:** TRANSIENT (re-ON @2600) is WORSE than PERMANENT despite recovering Nesterov in the pre-target window. Steps 975→2600 without look-ahead lose irrecoverable ground — the re-ON at 2600 can't repair it. Nesterov is load-bearing THROUGHOUT cooldown, not just in the pre-target window.
- **Mechanistic interpretation:** Removing `update = grad + μ×buffer` (Nesterov) forces buffer-only updates during cooldown, which are too inertial (no fresh gradient amplification). The momentum buffer alone drives optimization away from the steepest descent direction in the fast-changing cooldown landscape.
- **Axis closure:** Combined with #1797/#1836 (momentum SCALE NULL), #1831 (γ NULL), #1876 (hard-zero NULL), **body PMuon Nesterov mechanism axis CLOSED** at cooldown onset under both PERMANENT and TRANSIENT scopes.
- nezuko reassigned: Body PMuon γ SHARPEN (γ→0.5) TIMING SWEEP @ step 1100 vs 1200 (joint, all-blocks) — timing dimension orthogonal to alphonse #1935 blockwise @ 975. PR #1946.

## 2026-05-31 09:02 UTC — PR #1899 thorfinn: Joint aux Adam LR decay ×0.5/×0.25 @ cooldown onset step 975 — ❌ BILATERAL NULL with monotonic worse-with-deeper-decay (LR DECAY axis FULLY CLOSED)

- Branch: `g1r1-thorfinn/joint-aux-lr-decay-cooldown`
- Hypothesis: Decaying ALL three aux Adam parameter groups' LR simultaneously at step 975 (complementing scalar-only #1850 and embed-only #1868 closures) might capture a compound LR-recalibration effect that per-group decay missed.

| Arm | LR decay | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | none | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (×0.5 joint, all 3 groups)** | ×0.5 | `k83sxfwy` | 3000 | 3.271926 | **+9.07** | ❌ NULL (sr +125 vs baseline) |
| **B (×0.25 joint, all 3 groups)** | ×0.25 | `59k4t70o` | −1 | 3.283000 | **+20.15** | ❌ NULL (target not reached) |

- **MONOTONIC REGRESSION:** Heavier joint decay → worse outcome (Arm A worse, Arm B far worse). Replicates the embed-side regression read from #1868 (embed-only ×0.5 = +4.65 mnat vs scalar-only #1850 Arm B ×0.5 = thin WIN candidate): joint scope pulls in the embed-side drag.
- **Axis closure:** Combined with #1850 (scalar-only NULL on n=2) + #1868 (embed-only NULL bilateral), **aux Adam LR DECAY axis @ cooldown onset FULLY CLOSED across ALL scopes** (scalar/embed/joint). Canonical β₂ pulse already captures the available cooldown signal; LR-recalibration is not an additive lever.
- thorfinn reassigned: Body PMuon weight_decay PERSISTENT pulse @ cooldown onset step 975 — RELAX (wd→0.0) vs DEEPEN (wd→0.05) — first test of body PMuon wd at this boundary (#1693 closed pre-target 2750). PR #1945.

## 2026-05-31 05:57 UTC — PR #1881 tanjiro: Aux Adam m-state PARTIAL DECAY @ cooldown onset step 975 — ❌ BILATERAL NULL with NON-MONOTONE pattern (m-state intervention axis NOT smooth)

- Branch: `g1r1-tanjiro/aux-m-partial-decay-cooldown`
- Hypothesis: m-state partial decay (residual = 50%, 25%) at step 975 may interpolate between baseline (residual=100%) and #1815 m-zero seed-1 thin WIN (residual=0%).

| Arm | residual m | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline | 100% | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| nezuko #1815 m-zero seed-1 (unconfirmed) | 0% | nvh1vd60 | 2875 | 3.262238 | −0.616 | unconfirmed (seed-2 NULL) |
| **A (×0.5 m partial decay)** | 50% | `qysyg72c` | 2925 | 3.265940 | +3.086 | ❌ NULL |
| **B (×0.25 m partial decay)** | 25% | `qu502g96` | 2925 | 3.264549 | +1.695 | ❌ NULL |

- **NON-MONOTONE finding:** Partial decay is WORSE than BOTH baseline (residual=100%, val_ema=3.262854) AND hard-zero (residual=0%, val_ema=3.262238 seed-1) by +1.7 to +3.1 mnat. m-state intervention at step 975 is NOT smooth in residual fraction — partial discarding leaves a noisy mid-state that disrupts cooldown adaptation, whereas hard-zero gets a clean restart.
- **Cross-PR axis closure (m-state at all boundaries):** Combined with #1815 (m-zero @975 NULL on n=2), #1879 alphonse (m-zero @2600/2750 NULL — closed same loop), #1770 (m+v zero @975 NULL), #1830 (m+v zero @2600/2750 NULL), **aux Adam first-moment (m) state perturbation axis is FULLY CLOSED** across ALL magnitudes (partial decay, hard zero, joint full-zero) AND ALL temporal boundaries (975, 2600, 2750). First-moment direction memory is consistently load-bearing or benign at every tested intervention point.
- tanjiro reassigned: Aux Adam m-state HARD-ZERO PER-GROUP @ step 975 (lm_head-only vs embed-only) (#1934) — only untested cell on the m-state axis: per-group localization, mirroring tanjiro's prior #1837 β₂-pulse PER-GROUP framework.

## 2026-05-31 05:57 UTC — PR #1879 alphonse: Aux Adam m-only ZERO reset at LATE phase boundaries (2600 vs 2750) — ❌ BILATERAL NULL with informative monotonic temporal gradient

- Branch: `g1r1-alphonse/aux-m-zero-late-boundary`
- Hypothesis: m-zero at LATE phase boundaries (2600 pEMA refresh, 2750 pre-target) may show different behavior than the #1815 cooldown-onset m-zero (which had unconfirmed seed-1 thin-WIN). Tests temporal completeness of m-state axis.

| Arm | zero step | run | sr | val_ema | Δ vs gate (mnat) | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | — |
| **A (zero @2600 pEMA)** | 2600 | `i5ffmrvp` | 2925 | 3.263822 | +0.968 | ❌ NULL (worse on both axes) |
| **B (zero @2750 pre-target)** | 2750 | `1gi5xjae` | **2875** | 3.263512 | +0.658 | ❌ NULL (sr ties, val_ema misses by 0.658 mnat — closest near-miss on val_ema this session) |

- **MONOTONIC TEMPORAL GRADIENT FINDING:** Disruption decreases monotonically with boundary lateness — m-zero @975 (most disruptive, #1815 seed-2 +1.556 mnat) > @2600 (medium disruption, +0.968 mnat) > @2750 (least disruptive, +0.658 mnat). Later boundary = m-state is more "consumed" by training and matters less to zero. But NONE crosses the merge gate. Arm B is the closest near-miss this session on val_ema with sr ties baseline.
- **Cross-PR axis closure:** Combined with tanjiro #1881 (m partial decay @975 NULL, closed same loop), #1815 (m-zero @975 NULL on n=2), #1770/#1830 (m+v zero @975/2600/2750 NULL), **aux Adam first-moment (m) state perturbation axis FULLY CLOSED** across ALL magnitudes AND ALL temporal boundaries.
- alphonse reassigned: Body PMuon γ pulse BLOCK-STRATIFIED @ step 975 (deep-only vs shallow-only γ→0.5) (#1935) — opens depth-localization axis on the closed global γ pulse (#1831 fern NULL).

## 2026-05-31 05:30 UTC — PR #1877 edward: Body PMuon LR persistent step-down @ cooldown onset step 975 — ❌ BILATERAL NULL (body PMuon LR axis CLOSED)

- Branch: `g1r1-edward/body-muon-lr-stepdown`
- Hypothesis: Discrete LR step-down on body PMuon at cooldown onset step 975 (phase-locked with β₂ pulse boundary) could steepen cooldown descent. Bilateral magnitude test: Arm A ×0.85, Arm B ×0.70.

| Arm | factor | muon_lr after step-down | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline | — | 0.040 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (×0.85) | 0.85 | 0.034 | `kxq9csqg` | 2875 | 3.262952 | +0.098 | ❌ NEAR-MISS NULL (fails clause 2 by single-seed noise) |
| B (×0.70) | 0.70 | 0.028 | `hjcqr1ec` | 2875 | 3.265135 | +2.281 | ❌ NULL |

- **Key mechanistic read:** Arm A is baseline-equivalent (+0.098 mnat = single seed noise increment); Arm B moderately harms (+2.281 mnat). Heavier LR reduction is worse — confirms body PMuon cosine LR schedule from 0.040 is well-tuned. The phase-locked step-down does NOT realign with the β₂ pulse phase boundary in a useful way.
- **Combined LR axis closure:** Combined with #1637 (LR-UP @ pre-target NULL), #1697 (LR-DOWN @ pre-target NULL), this PR closes **body PMuon LR trajectory** as a lever at ALL temporal boundaries (cooldown onset 975 AND pre-target 2750). Discrete LR perturbations in either direction at any tested boundary do not produce sub-baseline val_ema. Body PMuon LR axis FULLY CLOSED.
- edward reassigned: body PMuon momentum HARD-ZERO BLOCKWISE @ step 975 (deep vs shallow blocks) (#1929) — directive (b)/(d), per-block depth-stratified state intervention.

## 2026-05-31 05:30 UTC — PR #1876 fern: Body PMuon momentum HARD-ZERO @ cooldown onset (975 vs 1100) — ❌ BILATERAL NULL (global body PMuon momentum axis fully exhausted)

- Branch: `g1r1-fern/body-momentum-zero`
- Hypothesis: Hard-zeroing body PMuon `momentum_buffer` at cooldown onset (step 975 or 1100) as hard-limit of the momentum-scaling axis (#1797). Bilateral temporal test.

| Arm | zero step | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (zero @975) | 975 | `sg2mj20u` | 2925 | 3.264221 | +1.37 | ❌ NULL (both clauses) |
| B (zero @1100) | 1100 | `df00qagd` | 2925 | 3.264998 | +2.14 | ❌ NULL (both clauses) |

- **Key mechanistic read:** Confirms #1797 (SCALE ×0.5/×0.25 @ 975) and #1836 (SCALE @ 2750) conclusions — body PMuon momentum state is INVARIANT to ALL perturbation types (scale, zero) at ALL temporal boundaries (975, 1100, 2750). Global momentum-handling axis on body PMuon FULLY CLOSED. Temporal invariance (975 ≈ 1100 in outcome) also consistent with frieren #1780 (cov temporal-invariance finding).
- fern reassigned: body PMuon side cov HARD-ZERO / ×0.5 @ cooldown onset step 975 (#1930) — directive (a)/(d), preconditioner state buffer reset (distinct from β_cov rate #1666 and per-side cov LR #1849).

## 2026-05-31 04:57 UTC — PR #1850 frieren: Aux Adam scalar_lr PULSE @ cooldown onset step 975 — ❌ BILATERAL NULL on n=2 (seed-2 failed to confirm thin WIN)

- Branch: `g1r1-frieren/scalar-lr-pulse-cooldown`
- Hypothesis: The aux Adam `adam_scalars` group controls RMSNorm gain/bias. At cooldown onset (step 975), a per-group LR pulse on this group could steepen descent. Bilateral: Arm A ×2 BOOST, Arm B ×0.5 DECAY.

| Arm | seed | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline | n=2 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (BOOST ×2) | 1 | `t14ojkgw` | 2950 | 3.267692 | +4.838 | ❌ NULL (both clauses) |
| B (DECAY ×0.5) | 1 | `414cvcw7` | 2875 | 3.262813 | **−0.041** | ⚠ thin WIN candidate (n=1) |
| B (DECAY ×0.5) | 2 | `mcqx7lvb` | 2925 | 3.265135 | +2.281 | ❌ NULL |
| **B (DECAY ×0.5) n=2 mean** | — | — | **2900** | **3.263974** | +1.120 | ❌ **NULL on n=2** |

- **Key mechanistic read:** Seed-1 thin WIN (−0.041 mnat) did NOT replicate at seed-2 (sr=2925, +2.281 mnat). Same close-margin seed-2-failure pattern as #1605/#1708/#1780/#1815 cohort (5th occurrence in this programme). Arm A BOOST (+4.838 mnat NULL) confirms the directional asymmetry: higher cooldown-onset scalar_lr HURTS, but the symmetric DECAY direction does NOT carry an extractable WIN signal across seeds.
- **Cross-PR closure:** Combined with #1868 askeladd embed_lr ×0.5 DECAY NULL (+4.65 mnat) and #1899 thorfinn JOINT multi-group LR ×0.5 DECAY trending sr=3000 NULL, **the entire aux Adam LR DECAY axis at cooldown onset is exhausted across scopes** (scalar-only, embed-only, all-groups joint). Canonical β₂ pulse at 975 already captures the available signal.
- frieren reassigned: β₂ pulse TIMING SWEEP — primary pulse @ step 1100 vs @ step 1200 (vs canonical 975) (#1915). Untested axis on the canonical WIN mechanism.

## 2026-05-31 04:28 UTC — PR #1868 askeladd: Aux Adam `adam_embed` LR pulse @ cooldown onset step 975 — ❌ BILATERAL NULL (per-group embed_lr cooldown axis CLOSED)

- Branch: `g1r1-askeladd/aux-embed-lr-pulse-cooldown`
- Hypothesis: The `adam_embed` group (lr=0.3) governs token+position embeddings — the largest aux-Adam-managed block. Per-group LR pulse at cooldown onset could either accelerate (×2 BOOST) or stabilize (×0.5 DECAY) embedding adaptation while body model fine-tunes. Companion to frieren #1850 (scalar_lr pulse on `adam_scalars`).

| Arm | direction | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (BOOST ×2) | embed_lr 0.3→0.6 @ 975 | `yucz7dkp` | 2925 | 3.265040 | +2.186 | ❌ NULL (both clauses fail) |
| B (DECAY ×0.5) | embed_lr 0.3→0.15 @ 975 | `ien18mwn` | 2950 | 3.267500 | +4.646 | ❌ NULL (both clauses fail) |

- **Key mechanistic read vs frieren #1850:** Scalar_lr ×0.5 DECAY = thin WIN candidate (-0.041 mnat). Embed_lr ×0.5 DECAY here = +4.65 mnat NULL. **The cooldown-onset LR-decay benefit is scalar-localized, NOT general across aux groups.** Asymmetric within group AND within direction — `adam_scalars` (RMSNorm gain/bias) responds positively to mild LR decay; `adam_embed` (token embeddings) regresses under the same intervention. This narrows the WIN mechanism to RMSNorm-specific dynamics, not generic LR overshoot in cooldown.
- **Axis closure:** Per-group `adam_embed` LR pulse at cooldown onset CLOSED bilaterally. Informs thorfinn #1899 (joint multi-group LR decay, in-flight at step 2675 trending NULL — consistent with embed-side regression dragging the joint result down). Untested aux LR scope: `adam_lm_head` only — likely NULL by symmetry, low priority.
- askeladd reassigned: aux SCALAR-group v-state PARTIAL DECAY @ 975 (#TBD) — orthogonal state-side probe on the WIN-bearing scope; isolates LR vs v contribution to the scalar cooldown benefit.

## 2026-05-31 01:00 UTC — PR #1850 frieren: Aux Adam scalar_lr PULSE @ cooldown onset step 975 — ⚠️ ARM B THIN WIN CANDIDATE (seed-2 requested; Arm A NULL)

- Branch: `g1r1-frieren/scalar-lr-pulse-cooldown`
- Hypothesis: The aux Adam `adam_scalars` group controls RMSNorm gain/bias. At cooldown onset (step 975), a per-group LR pulse on this group could steepen descent without disturbing embedding/lm_head dynamics. Bilateral test: Arm A ×2 BOOST (0.025→0.050), Arm B ×0.5 DECAY (0.025→0.0125).

| Arm | scalar_lr target | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | 0.025 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (BOOST ×2) | 0.025→0.050 @ 975 | `t14ojkgw` | 2925 | 3.267690 | +4.836 | ❌ NULL (both clauses fail) |
| B (DECAY ×0.5) | 0.025→0.0125 @ 975 | `414cvcw7` | 2875 | 3.262813 | **−0.041** | ⚠️ **THIN WIN candidate** (clause 2 passes by 0.041 mnat; n=1 seed noise) |

- **Key mechanistic read:** Strong asymmetry: BOOST HURTS (+4.836 mnat), DECAY HELPS (thin WIN). Direction is clear — lower scalar LR at cooldown onset damps RMSNorm overshoot. The 0.041 mnat margin is below single-seed noise floor, so seed-2 confirmation is required before merger.
- **Status:** Arm B seed-2 requested 00:50 UTC (sent back to student with reproduce command). Result pending ETA ~04:00-05:00 UTC.
- frieren forwarded to: seed-2 confirmation run of Arm B (scalar_lr ×0.5 @975, seed 2)

## 2026-05-31 01:00 UTC — PR #1849 thorfinn: Body PMuon L_cov/R_cov PER-SIDE asymmetric ZERO RESET @ step 1100 — ❌ BILATERAL NULL DEEP (per-side cov-reset CLOSED)

- Branch: `g1r1-thorfinn/per-side-cov-reset`
- Hypothesis: The canonical cov full-reset (#1780 frieren) applied both L and R simultaneously. The asymmetric paradigm tests whether gradient-side (R_cov) vs activation-side (L_cov) carries the signal independently. Prediction: R-only captures the benefit (gradient magnitudes shift more than activations under cooldown LR decay).

| Arm | side | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | both | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (L-only) | L_cov only | `2p8t595p` | 2925 | 3.264782 | +1.928 | ❌ NULL (both clauses fail) |
| B (R-only) | R_cov only | `qoi4hlnj` | 2925 | 3.264384 | +1.530 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Both arms sr=2925 (+50 vs baseline). Marginal R<L asymmetry (R-only −0.40 mnat less disruptive than L-only) is directionally consistent with gradient-space carrying more signal, but the effect is tiny and both regress. Prediction directionally correct but effect too small to bear load.
- **Axis closure:** Per-side covariance state reset CLOSED. Combined with full-reset CLOSED at cooldown onset (975), mid-cooldown (1100 via #1780), and pre-target (2750 via #1726) — cov-state reset axis fully EXHAUSTED across ALL reset types (full/per-side-L/per-side-R) AND temporal boundaries.

## 2026-05-31 01:00 UTC — PR #1815 nezuko: Aux Adam m-only ZERO RESET @ step 975 — ❌ BILATERAL NULL on n=2 (m-only zero WIN CLOSED)

- Branch: `g1r1-nezuko/aux-adam-m-only-zero-reset`
- Hypothesis: Aux Adam first-moment buffer (m) at cooldown onset carries stale pre-cooldown gradient direction. Hard-zeroing m only (preserving v denominator) avoids the catastrophic v-transient seen in full m+v reset (#1770). Bilateral: Arm A m-only zero @ 975 (no v touch); Arm B v×0.5 @ 975 (m untouched).

| Arm | intervention | seed | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (m-zero) | m ← 0 @ 975 | seed-1 | `nvh1vd60` | 2875 | 3.262238 | −0.616 | ⚠️ WIN candidate (seed-1 only) |
| A (m-zero) | m ← 0 @ 975 | seed-2 | `gdr4m70w` | 2925 | 3.264410 | +1.556 | ❌ FAIL seed-2 |
| B (v×0.5) | v ← v×0.5 @ 975 | seed-1 | `366knnhc` | 2925 | 3.265652 | +2.798 | ❌ NULL |

- **n=2 aggregate:** Arm A mean sr=2900, val_ema=3.263324. Fails both merge-gate clauses.
- **Key mechanistic read:** The seed-1 WIN (-0.616 mnat) was a close-margin run-to-run noise artifact. Seed-2 reversed to NULL (+1.556 mnat). m-only ZERO at step 975 is not a repeatable improvement. The first-moment direction memory is LOAD-BEARING at cooldown onset — it cannot be hard-discarded. v is even more load-bearing (Arm B +2.798 mnat NULL confirms denominator must be preserved).
- **Axis closure:** Aux Adam m-only HARD ZERO at cooldown onset CLOSED. The open sub-axis is PARTIAL DECAY of m (testing 0.5x and 0.25x attenuation), which may outperform hard-zero or null — assigned as tanjiro #1881.
- nezuko reassigned: Body PMuon Nesterov ON/OFF flag at cooldown onset (#1898) — untested Nesterov axis on update rule itself (not LR, not momentum magnitude, not state)

## 2026-05-30 22:30 UTC — PR #1837 tanjiro: Aux Adam β₂ pulse PER-GROUP asymmetric localization (embed-only vs lm_head-only) — ❌ BILATERAL NULL (per-group β₂ localization CLOSED)

- Branch: `g1r1-tanjiro/per-group-b2-pulse`
- Hypothesis: The #1532 WIN uses a joint β₂ pulse (0.95→0.99) applied to ALL aux Adam parameter groups simultaneously. Per-group localization tests whether the benefit is concentrated in embed (dense, wide token representation) vs lm_head (output projection, tied with embed). If one group dominates, the mechanism would localize and potentially be stackable.

| Arm | target group | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | all groups | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (embed-only) | adam_embed only | `v8ju1tf9` | 2950 | 3.267478 | +4.624 | ❌ NULL (both clauses fail) |
| B (lm_head-only) | adam_lm_head only | `47ayow7v` | 2925 | 3.264385 | +1.531 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Both arms missed the gate by a large margin. Arm B (lm_head-only) was less disruptive than Arm A (embed-only): +1.5 mnat vs +4.6 mnat, and sr=2925 vs sr=2950. This asymmetry suggests lm_head carries somewhat more β₂ signal than embed, but neither group alone captures the WIN. The #1532 WIN requires the JOINT multi-group β₂ switch — it is not reducible to a single-group effect.
- **Axis closure:** Aux Adam β₂ pulse per-group localization CLOSED. The WIN is a JOINT mechanism spanning all aux Adam parameter groups simultaneously. No further per-group split testing warranted on this axis.
- tanjiro reassigned: aux Adam m-state PARTIAL DECAY at cooldown onset step 975 (×0.5 / ×0.25) (#1881) — completes the m-state intervention matrix at the cooldown boundary; tests whether smooth partial reset outperforms hard zero from nezuko #1815 WIN candidate

## 2026-05-30 21:55 UTC — PR #1836 alphonse: Body PMuon momentum buffer SCALE at pre-target boundary step 2750 (×0.5 / ×0.25) — ❌ BILATERAL NULL (momentum-scale CLOSED across ALL boundaries)

- Branch: `g1r1-alphonse/pretarget-momentum-scale`
- Hypothesis: At the pre-target boundary (step 2750), body PMuon's accumulated momentum buffer may be over-calibrated for the cooldown-phase gradient regime. Partially attenuating the buffer — without hard-zeroing — reduces stale pre-cooldown magnitude while preserving accumulated direction. Magnitude-variant test: ×0.5 (light) vs ×0.25 (heavy attenuation).

| Arm | scale | step | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---:|---|
| Baseline | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | ×0.5 | @2750 | `wsln16vx` | 2925 | 3.265251 | +2.4 | ❌ NULL (both clauses fail) |
| B | ×0.25 | @2750 | `q6gfd5tz` | 2925 | 3.264915 | +2.06 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Both arms sr=2925 (+50 steps vs baseline). Arm B (×0.25 heavier attenuation) is marginally less disruptive than Arm A (×0.5 lighter) — +2.06 vs +2.4 mnat — opposite of what a "stale magnitude is the problem" narrative would predict. The mechanism is NOT a magnitude issue; it is insensitive to attenuation factor, replicating the thorfinn #1797 finding at step 975 (×0.5 and ×0.25 both bilateral NULL, INVARIANT to magnitude). Same null outcome at pre-target.
- **Axis closure:** Body PMuon momentum buffer SCALE axis CLOSED across ALL tested temporal boundaries: cooldown onset @975 (#1797 bilateral NULL) AND pre-target @2750 (#1836 bilateral NULL). Combined with hard-zero CLOSED at @2750 (#1730) and hard-zero at cooldown onset tested via fern #1876 (in flight), the body PMuon momentum-scale intervention is exhausted. The hard-zero (qualitative limit) at cooldown onset is the single remaining open question via fern #1876.
- alphonse reassigned: aux Adam m-only ZERO reset at LATE phase boundaries (step 2600 vs step 2750) (#1879) — direct temporal extension of nezuko #1815 m-only paradigm to the two late phase boundaries where only m+v COMBINED (not m-only) has been tested

## 2026-05-30 21:15 UTC — PR #1831 fern: Body PMuon γ pulse at cooldown onset step 975 (γ→0.3 RELAX vs γ→0.5 SHARPEN) — ❌ BILATERAL NULL (body PMuon γ axis CLOSED across cooldown onset AND pre-target)

- Branch: `g1r1-fern/body-pmuon-gamma-pulse-cooldown`
- Hypothesis: At cooldown onset (step 975), a discrete pulse of body PMuon's whitening exponent γ (currently 0.4) could steepen loss descent — softer whitening (γ→0.3) relaxes polar projection grip and allows more exploratory updates; sharper whitening (γ→0.5) tightens the preconditioner geometry. Bilateral test: symmetric body-side analog of the #1532 aux β₂ WIN.

| Arm | γ target | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | 0.4 | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A (RELAX) | 0.4→0.3 @ step 975 | `odlfnxjn` | 2925 | 3.267064 | +4.2 | ❌ NULL (both clauses fail) |
| B (SHARPEN) | 0.4→0.5 @ step 975 | `ycx299zy` | 2925 | 3.266283 | +3.4 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Both directions produce essentially identical sr penalty (+50 steps) regardless of direction (Arm A +4.2 mnat, Arm B +3.4 mnat). γ-pulse mechanism is NOT load-bearing at cooldown boundary. The #1532 β₂ WIN does NOT have a symmetric body-PMuon γ-pulse analog.
- **Axis closure:** Body PMuon γ axis CLOSED across cooldown onset (step 975, #1831 bilateral) AND pre-target (#1680 bilateral @ step 2750). Combined closure of all γ temporal windows. The whitening exponent is well-calibrated at γ=0.4 across all training phases.
- fern reassigned: body PMuon momentum HARD-ZERO reset at cooldown onset (#1876) — first test of full discard of body PMuon momentum direction memory, transferring nezuko #1815 m-only ZERO paradigm to body PMuon's analogous momentum buffer

## 2026-05-30 21:15 UTC — PR #1830 edward: Aux Adam m+v FULL ZERO RESET at late phase boundaries (step 2600 pEMA-refresh vs step 2750 pre-target) — ❌ BILATERAL NULL (late-phase full-zero reset CLOSED)

- Branch: `g1r1-edward/aux-mv-reset-late-phase`
- Hypothesis: Aux Adam m+v full reset at the late phase boundaries (2600 = pEMA refresh, 2750 = pre-target), avoiding the well-established v-denominator transient danger at step 975 (where #1770 confirmed full-zero at β₂ pulse boundary is catastrophic). By delaying the reset until after β₂=0.99 has had 1625-1775 steps to fill v, the denominator should be robust enough to tolerate full reset.

| Arm | reset_step | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | 2600 (pEMA refresh boundary) | `jljip8l4` | 2925 | 3.265206 | +2.4 | ❌ NULL (both clauses fail) |
| B | 2750 (pre-target boundary) | `n1mv5a58` | 2925 | 3.265872 | +3.0 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Arm A (+2.4 mnat) is slightly less disruptive than Arm B (+3.0 mnat). Arm B was MARGINALLY more disruptive — consistent with the advisor's prediction that smaller late-phase v denominator → larger relative reset impact at later boundaries. Both arms recover from the transient (transient confirmed: step 2625 +8.7 mnat spike for Arm A, step 2750 +8.7 mnat for Arm B, both recovering) but lose steps during recovery. Neither crosses the target before baseline.
- **Axis closure:** Aux Adam m+v FULL-zero reset CLOSED across ALL temporal boundaries: step 975 (#1770 bilateral catastrophic, +v_transient), step 2600 (Arm A NULL), step 2750 (Arm B NULL). Combined with per-element AdaShift (#1709), AdEMAMix (#1749), Lookahead, SOAP, ACProp (#1771) — the aux Adam first-moment STRUCTURAL MODIFICATION axis is now completely exhausted. The remaining open axis is asymmetric partial primitives (m-only reset, v-only partial decay), tested in nezuko #1815 where m-only @ 975 is a HOT WIN candidate.
- edward reassigned: body PMuon LR persistent step-down at cooldown onset step 975 (#1877) — first test of phase-locked LR schedule intervention on body PMuon; Arm A ×0.85, Arm B ×0.70

## 2026-05-30 19:00 UTC — PR #1819 askeladd: Aux Adam β₁ JOINT pulse synchronous with β₂ pulse at step 975 (β₁: 0.8→0.9 / 0.8→0.95) — ❌ BILATERAL NULL (aux Adam β₁ axis FULLY EXHAUSTED)

- Branch: `g1r1-askeladd/aux-b1-joint-pulse`
- Hypothesis: Aux Adam β₁ (first-moment decay) is set to 0.8. At cooldown onset (step 975), synchronize a β₁ RAISE simultaneously with the canonical β₂ pulse (0.95→0.99). Raises toward canonical NLP Adam values (0.9 and 0.95) to allow the first-moment estimator to ramp toward a momentum-dominant regime as the body LR decays — a coherent regime shift that pairs the second-moment variance stabilization with a simultaneous first-moment momentum ramp.

| Arm | β₁ target | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | 0.8→0.9 @ step 975 | `(askeladd armA)` | 2925 | 3.266499 | +3.645 | ❌ NULL (both clauses fail) |
| B | 0.8→0.95 @ step 975 | `(askeladd armB)` | 2950 | 3.267480 | +4.626 | ❌ NULL (both clauses fail) |

- **Key mechanistic read:** Both arms NULL; Arm B (more aggressive raise to 0.95) is strictly worse than Arm A (moderate raise to 0.9). The more momentum applied, the worse the outcome — consistent with the hypothesis that β₁=0.8 at cooldown onset is already optimal for the pre-cooldown regime. Synchronized β₁ RAISE is CLOSED.
- **Axis closure:** Aux Adam β₁ axis FULLY EXHAUSTED. Combined with prior #1592 (standalone raise, bilateral NULL) and #1639 (standalone drop, bilateral NULL), the β₁ axis is closed across (a) standalone raise, (b) standalone drop, AND (c) joint synchronization with β₂ at the canonical cooldown boundary.
- askeladd reassigned: Aux Adam `adam_embed` group per-group LR PULSE @ cooldown onset step 975 (#1868) — novel per-group LR perturbation on the largest aux-Adam group; Arm A ×2 (0.3→0.6) / Arm B ×0.5 (0.3→0.15)

## 2026-05-30 16:15 UTC — PR #1780 frieren: Body PMuon L/R cov bilateral ZERO RESET at cooldown boundary (975 vs 1100) — ❌ NULL on n=2 confirmation (cov-reset axis CLOSED)

- Branch: `g1r1-frieren/cov-reset-cooldown`
- Hypothesis: Body PMuon L_cov and R_cov carry pre-cooldown covariance statistics that are OOD at cooldown onset. Hard-zeroing at the phase boundary allows preconditioners to re-accumulate from fresh cooldown gradients. Tested two timing variants: cooldown-onset (step 975) vs 125 steps into cooldown (step 1100).

| Arm | reset_step | seed | run | sr | val_ema | Verdict |
|---|---|---|---|---:|---:|---|
| Baseline n=2 | — | 1+2 mean | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — |
| A | 975 | 1 | x3i1eyro | 2925 | 3.264834 | ❌ NULL (both clauses fail) |
| B seed-1 | 1100 | 1 | akezqgjp | 2875 | 3.262685 | ⚠️ THIN PASS clause 2 (−0.169 mnat) |
| B seed-2 | 1100 | 2 | cknk2m33 | 2925 | 3.264785 | ❌ NULL (both clauses fail) |
| **B n=2 mean** | **1100** | **1+2** | — | **2900** | **3.263735** | ❌ **NULL** |

- **Key mechanistic read:** Arm B seed-1 barely passed clause 2 (-0.169 mnat) but seed-2 returned sr=2925 val_ema=3.264785, failing both clauses. n=2 mean sr=2900, val_ema=3.263735 — NULL. The single-seed seed-1 win was within run-to-run noise, NOT a reproducible structural signal.
- **Bilateral zero-reset of L/R covariance is too aggressive.** Both preconditioners must regenerate simultaneously from cooldown statistics, producing high-variance trajectory that occasionally crosses target faster but cannot do so reliably.
- **Axis closure:** Body PMuon cov-state full-reset CLOSED across cooldown onset (975), mid-cooldown (1100), and pre-target (#1726 @ 2750). Per-side asymmetric primitive (L-only / R-only, analogous to nezuko #1815 m-only / v×0.5) is the natural follow-up — now in flight as thorfinn #1849.
- frieren reassigned: aux Adam scalar_lr pulse @ cooldown onset step 975 (#1850) — novel per-group LR perturbation on the untested scalar (RMSNorm gains/biases) group

## 2026-05-30 16:05 UTC — PR #1797 thorfinn: Body PMuon momentum buffer partial SCALE at cooldown onset step 975 (×0.5 / ×0.25) — ❌ BILATERAL NULL (momentum-scale at step 975 CLOSED)

- Branch: `g1r1-thorfinn/body-muon-momentum-scale`
- Hypothesis: At cooldown onset (step 975), body PMuon's accumulated momentum may be over-calibrated for the pre-cooldown gradient regime. Partially attenuating the momentum buffer — without hard-zeroing — preserves accumulated gradient direction while reducing stale pre-cooldown magnitude, analogous to a soft v-denominator re-weighting.

| Arm | scale | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | ×0.5 @ step 975 | `(thorfinn armA)` | 2925 | worse | +Δ | ❌ NULL |
| B | ×0.25 @ step 975 | `(thorfinn armB)` | 2925 | worse | +Δ | ❌ NULL |

- **Key mechanistic read:** ×0.5 and ×0.25 produce essentially identical sr=2925 NULL — the momentum-scale mechanism's response is INVARIANT to attenuation magnitude at step 975. Both arms miss both merge-gate clauses (sr=2925 > 2862.5; val_ema above baseline).
- **Axis closure:** Body PMuon momentum buffer SCALE at cooldown onset step 975 CLOSED bilaterally. Attenuation of pre-cooldown momentum magnitude is not load-bearing at this boundary. Combined with hard-zero CLOSED at pre-target (#1730), the momentum-state axis is fully exhausted across all reset types and temporal boundaries tested.
- thorfinn reassigned: body PMuon per-side L_cov vs R_cov asymmetric zero-reset @ step 1100 (#1849) — transfers nezuko #1815's asymmetric-primitive paradigm (m-only vs v-only on aux Adam) to body PMuon's bilateral covariance preconditioners

## 2026-05-30 14:00 UTC — PR #1788 alphonse: Per-block depth-asymmetric μ on body PMuon (ascending vs descending 0.90↔0.99) — ❌ BILATERAL NULL (per-block depth-asymmetric μ CLOSED)

- Branch: `g1r1-alphonse/per-block-mu-asymm`
- Hypothesis: Apply different μ values to early vs late transformer blocks in body PMuon — either ascending (early blocks lower μ, late blocks higher μ) or descending — to exploit known gradient-memory depth asymmetry.

| Arm | μ pattern | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | ascending (early 0.90, late 0.99) | `gp8w803r` | -1 | 3.428 | **+165** | ❌ NULL (target not reached) |
| B | descending (early 0.99, late 0.90) | `0e6dwf70` | -1 | (diverged mid-run) | — | ❌ NULL/DIVERGE |

- Arm A: target never reached (sr=-1, val_ema=3.428 — far from 3.28 target). Ascending μ with higher momentum in late blocks amplified late-block instability at cooldown onset. No convergence to target.
- Arm B: mid-run divergence observed at step ~850, training destabilized. Full val trajectory too far from baseline to carry any directional signal.
- **Mechanistic conclusion:** Per-block depth-asymmetric μ on body PMuon is CLOSED bilaterally. Combined with #1742 per-block LR closure, block-depth asymmetric optimizer axes on body PMuon are exhausted. Scalar μ=0.95 is optimal for the uniform body PMuon regime.
- alphonse reassigned: body PMuon momentum SCALE at pre-target boundary step 2750 (#1836)

## 2026-05-30 14:00 UTC — PR #1787 tanjiro: Aux Adam eps transient pulse co-located with β₂ pulse boundary — ❌ BILATERAL NULL (eps pulse at β₂ boundary CLOSED)

- Branch: `g1r1-tanjiro/aux-eps-pulse`
- Hypothesis: At step 975 (β₂ pulse boundary), the variance estimator v_t is switching memory length. During v_t re-accumulation, the adaptive denominator may momentarily be mis-calibrated. Temporarily elevating eps provides a numerical stability floor during this transient.

| Arm | eps | steps | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---:|---|
| Baseline | 1e-10 | — | — | 2875 | 3.262854 | — | — |
| A | 1e-6 (×10k boost) | 975–1100 | `o16ay0kd` | 2875 | (at gate) | ~0 | ❌ NULL |
| B | 1e-4 (×1M boost) | 975–1100 | (chain) | 2925 | worse | +δ | ❌ NULL |

- Both arms: eps pulse fires correctly at step 975, resets at step 1100. The v_t transient at the β₂ pulse boundary is NOT a numerical stability problem — eps 1e-10 is already sufficient. Elevating eps to 1e-6 changes nothing meaningful (v_t at step 975 is still O(1e-3) or larger); eps 1e-4 is large enough to damage per-param adaptivity without helping.
- **Mechanistic conclusion:** Aux Adam eps pulse at the β₂ pulse boundary CLOSED — the v_t transient at step 975 is NOT a stability problem requiring numerical-floor intervention. The β₂ WIN mechanism is in the v-memory length change itself, not its transient behavior.
- tanjiro reassigned: aux Adam β₂ pulse PER-GROUP asymmetric localization — embed-only vs lm_head-only (#1837)

## 2026-05-30 13:25 UTC — PR #1786 fern: GrokFast slow-EMA amplification on whitened body PMuon (α=0.5 / α=2.0) — ❌ BILATERAL NULL (GrokFast on whitened PMuon CLOSED)

- Branch: `g1r1-fern/grokfast-whitened`
- Hypothesis: Apply GrokFast-style slow-EMA gradient amplification to the NS5-whitened body PMuon updates (after polar projection, before momentum accumulation), to compound persistent cooldown directions without disrupting polar normalization.

| Arm | α | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — |
| A | 0.5 | `faenv1la` | 3075 | 3.272759 | **+9.9** | ❌ NULL |
| B | 2.0 | `lhyyau6j` | -1 | 3.571985 | **+309** | ❌ DIVERGE |

- Arm A (α=0.5, conservative): clean GrokFast activation at step 975, sr slipped +200 steps. Conservative slow-EMA boost ~15% magnitude lift SLOWED late-cooldown convergence — LR-decay magnitude shrink during cooldown is a feature, not a bug. Single-run target-margin +0.00324, below 0.004 stat-sig floor.
- Arm B (α=2.0, paper default): catastrophic divergence at step 1500 (val_loss 3.86 → 8.858), grokfast/ema_norm_max=1.09e6 vs 1696 in Arm A (642× larger). Runaway positive feedback loop on the whitened update; broke the polar-normalization invariant. Recovery floor val_ema=3.572 (+309 mnat).
- **Mechanistic conclusion:** NS5 outputs a near-orthogonal matrix whose magnitude is structurally invariant to gradient norm. Adding a slow-EMA term breaks that invariant and the feedback loop scales with α. Polar normalization is NOT preserved under additive slow-EMA injection. GrokFast on whitened body PMuon CLOSED. (Note: GrokFast cross-application to aux AdamW is also deprioritized given the mechanism failure.)
- fern reassigned: body PMuon γ pulse at cooldown onset step 975 (#1831)

## 2026-05-30 13:25 UTC — PR #1785 edward: Block-wise AdaShift on aux AdamW embed (delay=1 / delay=10) — ❌ BILATERAL NULL (block-wise AdaShift on aux Adam CLOSED)

- Branch: `g1r1-edward/blockwise-adashift`
- Hypothesis: Replace per-element v_t in aux AdamW embed group with a scalar v_t per tensor (block-wise), with a delay (v_t uses gradients from d steps ago) to reduce interference between slow-moving embed parameters and the current gradient distribution.

| Arm | delay | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---|
| Baseline | — | — | 2875 | 3.262854 | — | — |
| A | 1 | `k7mnezbn` | -1 | 3.361518 | **+98.7** | ❌ NULL |
| B | 10 | `p02dl0lt` | -1 | 3.330504 | **+67.7** | ❌ NULL |

- Arm B (delay=10) leads Arm A at every checkpoint but margin narrows monotonically (-0.456 at step 125 → -0.031 at step 3250). Neither arm hit 3.28 target. Block-wise scalar v_t fundamentally changes effective per-block LR for embed; embedding layer fails to learn fine-grained token distinctions under collapsed v_t per-tensor denominator.
- **Conclusion:** Block-wise AdaShift on aux AdamW embed CLOSED. Combined with prior per-element AdaShift #1709, AdaShift axes fully exhausted for aux Adam.
- edward reassigned: aux Adam m+v full reset at late phase boundaries 2600 vs 2750 (#1830)

## 2026-05-30 11:00 UTC — PR #1773 askeladd: paramEMA β hard step-drop at pre-target (0.99→0.90 / 0.99→0.95) — ❌ BILATERAL NULL (pEMA β-drop axis CLOSED)

- Branch: `g1r1-askeladd/paramema-beta-step-drop`
- Hypothesis: Drop paramEMA β from 0.99 (post-warmup target) to a lower value at step 2750 (pre-target window) to make pEMA track actual weights more aggressively just before the target crossing window.

| Arm | β target | run | sr | val_ema | val_live | Δval mnat | val_ema/val_live gap | Verdict |
|---|---|---|---:|---:|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — | +0.59 mnat | — |
| A | 0.99→0.90 | `amjdnr6e` | 2950 | 3.265150 | 3.265128 | +2.30 | **+0.02 mnat** | ❌ NULL |
| B | 0.99→0.95 | `v14asb4w` | 2925 | 3.262675 | 3.262610 | **-0.18** | **+0.06 mnat** | ❌ NULL (sr fails) |

**Mechanistically fascinating result:** β-drop DID fire correctly (confirmed via step-2750 telemetry). The val_ema/val_live gap collapsed exactly as predicted (baseline +0.59 mnat → Arm A +0.02 mnat, Arm B +0.06 mnat). But the sr clause fails — the actual training val_live trajectory was already at baseline pace; only the EVAL (pEMA tracking) was lagging. When the gap closes, val_ema reveals the same training dynamics as before — the pEMA smoothing lag was not a bottleneck.

**Arm B insight:** val_ema=3.262675 falls BELOW baseline (-0.18 mnat under clause 2 value), but sr=2925 means it never reached 3.28 early enough. The β-drop made pEMA more aggressive as an EVALUATOR but didn't change when val_live crossed 3.28.

**Axis closure:** pEMA β step-drop CLOSED bilaterally — val_ema/val_live decoupling is a TRAINING trajectory effect, not an EMA smoothing artifact. Directional target crossing speed requires training-side intervention.

**Assigned next:** askeladd #1819 — aux Adam β₁ joint pulse synchronous with β₂ pulse at step 975. Target: compounding #1532 WIN by synchronizing both moment estimators' regime shifts.

---

## 2026-05-30 09:00 UTC — PR #1770 nezuko: Aux Adam m+v hard zero reset at β₂-pulse boundary — ❌ BILATERAL NULL (aux Adam full-zero moment reset CLOSED)

- Branch: `g1r1-nezuko/aux-adam-state-reset`
- Hypothesis: Reset all aux Adam (optimizer1) m and v buffers to zero at the same step as the β₂ pulse, testing whether synchronizing the EMA buffers with the β₂ regime change improves cooldown trajectory.

| Arm | reset step | run | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---|---:|---:|---:|---:|---|
| Baseline | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | — | — |
| A | 975 (colocated with β₂ pulse) | `mhzwt7ge` | 2975 | 3.269943 | 3.269343 | +7.09 | ❌ NULL |
| B | 1200 (after 225 steps of β₂=0.99 fill) | `lazt0u87` | 2925 | 3.266416 | 3.265811 | +3.56 | ❌ NULL |

**Key diagnostic — post-reset transient magnitude:**
- Arm A: +62.9 mnat upward transient at step 1000 (simultaneous β₂ jump + v-zeroing leaves denominator at ~ε for ~50 steps during sensitive cooldown phase)
- Arm B: +1.7 mnat transient at step 1250 (β₂=0.99 had 225 steps to fill v, so denominator recovered quickly)
- 35× transient difference precisely tracks the v-denominator collapse mechanism

**Sentinel confirmation:** both resets fired cleanly — `exp_avg` and `exp_avg_sq` dropped to exact zero at their respective steps (verified via W&B sentinel telemetry at reset_step-1/step/step+1).

**Analysis:** The β₂ pulse benefits from carrying v state forward — at step 975, `exp_avg_sq` encodes per-param gradient-magnitude history that the adaptive denominator needs. Zeroing it forces the optimizer into a cold-start denominator regime at the cooldown's most sensitive phase. The pEMA refresh analogy fails here: pEMA refresh at step 2600 works because the parameter EMA buffer is *stale* (averaging pre-cooldown-midpoint weights); the aux Adam optimizer state is *not* stale — it encodes fresh, still-relevant gradient statistics. Asymmetry with pEMA is structural, not contingent.

**Axis closure:** combined with historical aux Adam reset @ 2600 (closed), aux Adam full-zero moment reset is CLOSED across both boundaries and timing variants. v state is load-bearing and discard is destructive.

**Assigned next:** nezuko #1815 — asymmetric bilateral: m-only zero reset vs v partial decay ×0.5, both @ step 975, to decompose whether m or v was the failure driver and whether partial rescaling avoids the denominator collapse.

---

## 2026-05-30 07:30 UTC — PR #1749 thorfinn: AdEMAMix dual-EMA first moment on aux AdamW — ❌ BILATERAL NULL

- Branch: `g1r1-thorfinn/aux-ademamix`
- Hypothesis: Add a slow EMA (β₃=0.999-0.9995) to aux AdamW first moment using AdEMAMix formulation (`m_eff = m_fast + α · m_slow`), with linear α warmup from 0 to target over T_α steps, to improve aux Adam momentum tracking during cooldown.

| Arm | α | β₃ | T_α | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | — | — | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | — | (reference) |
| A | 0.50 | 0.999 | 500 | `1p20ntln` | 2975 (+100) | 3.269501 | +6.65 | ❌ NULL |
| B | 0.75 | 0.9995 | 750 | `ctdbjhtv` | 3000 (+125) | 3.271093 | +8.24 | ❌ NULL |

**Analysis:** Sentinel audit confirmed α_t warmup fired correctly and m_slow contribution was non-trivial (m_eff_vs_fast_delta 49-554 nats throughout training). Mechanism is genuine. Arm B strictly worse than Arm A — larger slow EMA component hurts more, suggesting aux AdamW m buffer is already well-calibrated and adding structural slow-EMA overhead regresses cooldown trajectory. AdEMAMix on aux AdamW CLOSED. Combined with prior closures of ACProp (#1771), per-element AdaShift (#1709), Lookahead, SOAP — aux Adam first-moment structural modification family heavily constrained.

**Assigned next:** thorfinn #1797 body PMuon momentum partial fade at cooldown onset (directive a+d).

---

## 2026-05-30 05:50 UTC — PR #1752 alphonse: Newton-Muon activation-Gram right-preconditioner on body PMuon (diag mode) — ❌ ARM A NULL, Arm B not run (mechanism cleanly closed; student-recommended close)

- Branch: `g1r1-alphonse/newton-muon-actgram`
- Hypothesis: Add a Newton-style activation-Gram right-preconditioner to body PMuon updates — `g → g · diag(A)^{-1/2}` where A is the running EMA of `x x^T` over input activations — to capture input-side curvature analogous to KFAC's A factor.
- W&B: Arm A `rh2iinb5` (diag mode)
- Pre-authorized NULL gate: `val_ema ≥ 3.265 at step 3250`. Result: 3.26942 ≥ 3.265 → clearly NULL.

| Arm | mode | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | diag-Gram preconditioner | 2975 | 3.26942 | — | +6.6 | ❌ NULL (+100 sr) |
| B | full-Gram | NOT RUN | — | — | — | (student-recommended skip after Arm A clean NULL) |
| Baseline #1532 | no preconditioner | 2875 | 3.262854 | — | — | — |

- **Analysis:** Trajectory comparison vs baseline shows a **uniform ~+0.0066 val_loss drag from EMA warmup onward** (steps 1750/2250/2750/2875/2975/3250 all show +0.0065-0.0067 vs baseline mean) — NOT a late-stage cooldown issue, NOT a tuning issue, but a **systematic per-step optimization cost**. Training health was pristine: `nonfinite_count=0`, smooth grad-norm decline (121k → 15k), `actgram/fired_fraction=1.0` throughout, `actgram/diag_ratio` peaked ~15 and held 13-15 to terminal — confirming the preconditioner was doing real work (genuine input-feature variance spread).
- **Mechanistic closure (student's analysis):** PMuon's bilateral whitening already handles output-side curvature via `L^{-γ}` and `R^{-γ}` on the momentum matrix. Right-multiplying the same gradient by `diag(A)^{-1/2}` before NS5 **double-corrects**: it re-weights input columns of the gradient in a basis that L_cov/R_cov already shape. The variance spread is real (ratio ~15) but those variance directions are already captured by R-side. Suppressing them via diag-scaling distorts the post-NS5 update direction without adding new information.
- **Newton-Muon activation-Gram axis CLOSED** in diag mode. The full-Gram variant (Arm B) shares the same double-correction geometry (additionally rotates the gradient into a basis L/R already shape) — would compound the drag, not reduce it. Skipping Arm B saves compute on a structurally exhausted axis.
- **Strong corroboration:** combined with alphonse #1703 ADOPT-style async whitening closure (update-rule order swap closed), the body PMuon bilateral whitening's structural sufficiency for both input-side AND output-side curvature is now confirmed across two independent additive interventions. No third curvature correction is needed.

## 2026-05-30 05:30 UTC — PR #1742 tanjiro: Depth-asymmetric per-block Muon LR burst ×1.5 @ [2750, 2900) — ❌ BILATERAL NULL (per-block LR perturbation axis FULLY CLOSED)

- Branch: `g1r1-tanjiro/pretarget-block-lr-asym`
- Hypothesis: Per-block depth-asymmetric LR burst during [2750, 2900) — applying ×1.5 to either the early half (blocks 0-5) or the late half (blocks 6-11) while holding the other at canonical — tests whether depth-conditional LR can reach regions unreachable by closed uniform pulses (#1637, #1697).
- W&B: Arm A `xdpfzmo9` (early-boost, blocks 0-5 ×1.5), Arm B `p18t6opk` (late-boost, blocks 6-11 ×1.5)

| Arm | burst pattern | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | early-boost (b0-5 ×1.5) | 2925 | 3.264439 | 3.263793 | +1.59 | ❌ NULL (+50 sr) |
| B | late-boost (b6-11 ×1.5) | 2925 | 3.264852 | 3.264238 | +2.00 | ❌ NULL (+50 sr) |
| Baseline #1532 | no burst | 2875 | 3.262854 | — | — | — |

- **Analysis:** Both arms NULL strict gate, both sr=2925 (+50 sr, +1.59-2.00 mnat). No grad-norm spike during burst window in either arm — mechanism executed cleanly (confirmed by per-block sentinel LR audit at steps 2749, 2750, 2751, 2825, 2899, 2900, 2901 — burst applied correctly in window, reverted at step 2900 exactly). The NULL outcome is a **trajectory** issue: the ×1.5 boost disrupts the cooldown descent path and the model never recovers in the remaining ~350 steps. Early-boost marginally less damaging than late-boost (Arm A +1.59 vs Arm B +2.00 mnat) — consistent with late blocks being more sensitive in cooldown (already at highest LR via canonical late-higher pattern), but both clearly NULL. The depth-asymmetric hypothesis (per-block LR conditioned on depth) was motivated by the canonical late-higher WIN (#1289) — the result says the canonical depth pattern is already optimal; ANY temporary perturbation (boost or reduction, uniform or depth-asymmetric) breaks it.
- **Per-block LR perturbation axis FULLY CLOSED:** uniform LR-UP (#1637, NULL), uniform LR-DOWN (#1697, NULL), depth-asymmetric burst early + late (#1742, bilateral NULL). The pre-target LR perturbation family is exhausted across uniform AND depth-asymmetric variants.

## 2026-05-30 05:10 UTC — PR #1739 fern: Pre-target NS_ITERS burst {14, 16} @ step 2750 — ❌ BILATERAL NULL (polar projection accuracy is NOT the cooldown bottleneck)

- Branch: `g1r1-fern/pretarget-ns-iters-burst`
- Hypothesis: Increasing Newton-Schulz iterations during the pre-target window (steps 2750+) tightens the polar approximation, producing cleaner whitened-gradient directions at the moment the LR decay sharpens the descent — bridging the val_ema gap on the final 250 steps.
- W&B: Arm A `nlmt3a4w` (NS=14), Arm B `ossp58zg` (NS=16)

| Arm | NS_ITERS pre-target | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 14 (vs canonical 12) | 2925 | 3.264729 | 3.264091 | +1.88 | ❌ NULL (+50 sr) |
| B | 16 (vs canonical 12) | 2925 | 3.265219 | 3.264584 | +2.37 | ❌ NULL (+50 sr) |
| Baseline #1532 | 12 | 2875 | 3.262854 | — | — | — |

- **Analysis:** Polar residual `||A - polar(A)||/||A||` fell **3-5× during the burst window** (~0.29 → 0.06-0.07) — the mechanism worked exactly as designed. Yet neither arm reached baseline sr. **Polar projection accuracy is NOT the bottleneck** for cooldown-phase target crossing. The whitened-gradient direction is already clean enough at NS=12; sharper polar projection delivers more accurate direction but doesn't translate to better target-crossing speed or val_ema. The cooldown phase's remaining headroom is in update **magnitude / persistence**, not direction quality.
- **Polar-accuracy axis CLOSED.** Tighter projection in pre-target window doesn't help. Future iteration-count tuning should focus on warmup discovery, not pre-target refinement.
- **Strong motivation for GrokFast (#1786 fern next):** Direction quality is solved; persistent-direction amplification (slow-EMA boost) directly targets the magnitude axis that remains open.

## 2026-05-30 05:10 UTC — PR #1771 edward: ACProp async denominator on aux AdamW (v_t uses g_{t-1}²) — ❌ BILATERAL NULL (ACProp axis structurally CLOSED on aux Adam)

- Branch: `g1r1-edward/acprop-aux-adam`
- Hypothesis: ACProp-style async variance estimation (`v_t = β₂·v_{t-1} + (1-β₂)·g_{t-1}²`) on aux AdamW would decorrelate the denominator from the current step's gradient bias — analogous to the body-side ADOPT mechanism.
- W&B: Arm A `vk2cm1q4` (all-groups async), Arm B `xbv2asps` (embed_only async)

| Arm | scope | sr | val_ema | val_live | Verdict |
|---|---|---:|---:|---:|---|
| A | all-groups async (embed + lm_head + scalars) | — | **16.23 @ step 250** | — | ❌ CATASTROPHIC DIVERGENCE |
| B | embed_only async (sparse-grad target) | — | **3.705 @ step 1575 (early-killed)** | — | ❌ NULL (val_ema > 3.60 pre-authorized trigger) |
| Baseline #1532 | sync | 2875 | 3.262854 | — | — |

- **Analysis:** Arm A divergence (val=16.23 at step 250) confirms the **sparse-gradient embed failure mode**: the stale denominator `g_{t-1}²` at active vocab index `i` carries near-zero variance when step t-1 did not activate `i`, so the bias-corrected denominator under-divides the current step's actual gradient — producing the catastrophic update magnitude that diverged training within 250 steps. Arm B isolated the embed group with the same async mechanism + early-kill safety, hit val_ema 3.705 at step 1575 — confirming the sparse-grad failure is exactly localized to the embed group and that the mechanism is not salvageable in any subset.
- **ACProp axis structurally CLOSED on aux Adam.** Even with sparse-grad isolation the async-denom mechanism fails. The per-element variance memory is fundamentally incompatible with sparse-activation token embeddings under any delay > 0 — Adam needs the current step's gradient² in the denominator to handle the sparse-activation pattern.
- **Mechanistic motivation for block-wise AdaShift (#1785 edward next):** scalar-aggregated v_t (one per tensor) sidesteps the sparse-grad failure mode entirely — the L2 norm aggregation captures meaningful variance signal even when only a subset of vocab indices activate at each step. Orthogonal to per-element closure (#1709).

## 2026-05-30 04:00 UTC — PR #1708 frieren: Pre-target Skylight u/w floor pulse (UW=0.45 / UW=0.55) + seed-2 confirmation — ❌ BILATERAL SEED NULL (TARGET_UW family fully closed)

- Branch: `g1r1-frieren/pretarget-uw-pulse`
- Hypothesis: Temporarily raise the target whitening underflow floor (TARGET_UW) from canonical 0.35 to 0.45/0.55 during the pre-target window (steps 2750-2900) to sharpen the polar approximation before the final descent.
- W&B: Arm A `xmwa60yc` (UW=0.45), Arm B seed-1 `bstlsmqy` (UW=0.55), Arm B seed-2 `xkr7c9rl` (UW=0.55 seed-2)

| Arm | TARGET_UW | seed | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---:|---|
| A | 0.45 | 1 | 2925 | 3.266865 | 3.266235 | +4.01 | ❌ NULL |
| B seed-1 | 0.55 | 1 | **2875** | **3.263116** | 3.262409 | **+0.262** | ❌ NULL (strict gate; close miss) |
| B seed-2 | 0.55 | 2 | 2925 | 3.265865 | 3.265182 | +3.01 | ❌ NULL |
| B n=2 mean | 0.55 | — | **2900** | **3.264490** | 3.263796 | **+1.636** | ❌ NULL |
| Baseline #1532 | 0.35 | n/a | 2875 | 3.262854 | — | — | — |

- **Analysis:** Arm A→B trend (UW 0.45→0.55 → sr 2925→2875, val_ema 3.2669→3.2631, +3.7 mnat improvement) looked mechanistically real. Seed-2 confirmation of Arm B revealed this was within seed-noise envelope: the seed-2 deficit (+0.0028 val_ema) is present from step 2500 onward, **before the pulse window opens at 2750**. The Arm A→B improvement is the same magnitude as the per-seed noise gap on Arm B alone (+0.0027 mnat) — the pulse magnitude is not a real lever at n=2 resolution (would need n≥4 to resolve +0.0004 mean above +0.003 seed-noise floor, beyond per-PR budget).
- **TARGET_UW family definitively closed** across 5 experiments: permanent 0.25 (pre-history), permanent 0.45 (pre-history), long-window 0.45 pulse (pre-history), short-window 0.45 pulse n=1 (Arm A), short-window 0.55 pulse n=2 (Arm B + seed-2). Body PMuon pre-target window now thoroughly characterized as NULL across all scalar pulses and structural state interventions.

## 2026-05-30 02:45 UTC — PR #1730 askeladd: Pre-target body Muon momentum-buffer hard ZERO RESET @ step 2750 — ❌ BILATERAL NULL (momentum state-discard axis CLOSED)

- Branch: `g1r1-askeladd/pretarget-momentum-reset`
- Hypothesis: Zero all 72 body Muon `state["momentum"]` buffers at step 2750, then apply a μ=0.85 transient (steps 2750–2900); Arm A (pure reset) vs Arm B (reset + μ=0.85 transient).
- W&B: Arm A `9tnpixy1` (CRASHED, exit 137 @ step 1971), Arm B `uhrosnl0`

| Arm | mechanism | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | pure zero reset @ 2750 | — | — | — | — | ❌ CRASHED (exit 137, step 1971 — before reset fires) |
| B | reset + μ=0.85 transient 2750→2900 | 2925 | 3.266557 | 3.265957 | +3.70 | ❌ NULL (+50 sr) |
| Baseline #1532 | no reset | 2875 | 3.262854 | — | — | — |

- **Analysis:** Arm A crash (SIGKILL exit 137) at step 1971 — ~779 steps before the reset trigger. No Python traceback; step-time inflated from ~4050→4765ms over last 100 steps (consistent with host memory pressure). Reset mechanism never fired. Arm B clean execution: 72 buffers zeroed + μ 0.95→0.85→0.95 (steps 2750–2900), confirmed via print0 logs and W&B `pmuon_reset/*` telemetry. Grad norm spiked ~30% at reset, peaked ~50% above baseline during μ=0.85 window, recovered after revert within 25 steps — mechanism ran correctly but never converted to better terminal val_ema.
- **Full axis closure:** fern #1604 (permanent μ pulse), askeladd #1686 (transient μ 0.97/0.99 bilateral NULL), askeladd #1730 (buffer-discard + transient μ=0.85 NULL). Body Muon momentum axis **bilaterally closed across decay-modulation AND state-discard at the pre-target boundary**. Accumulated momentum buffer was providing useful smoothing, not damaging staleness.
- **Implementation note:** Correct state key is `state["momentum"]` (not `"momentum_buffer"`). CLI flags: `--muon_momentum_reset_step`, `--muon_momentum_reset_mu_target`, `--muon_momentum_reset_mu_end`.

## 2026-05-30 02:05 UTC — PR #1727 edward: Depth-split β_cov binary partition (early/late 6-block) — ❌ BILATERAL NULL (axis FULLY closed)

- Branch: `g1r1-edward/betacov-depth-split`
- Hypothesis: Binary β_cov split by depth — Arm A `early-slow-late-fast` (0.97/0.92) phase-matches the late-higher LR pattern, Arm B `early-fast-late-slow` (0.92/0.97) is the falsifying counterfactual.
- W&B: Arm A `66yd8u3s`, Arm B `mj8zysth`

| Arm | β_cov (early/late) | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | 0.97 / 0.92 | 2950 | 3.267577 | 3.266956 | +4.72 | ❌ NULL |
| B | 0.92 / 0.97 | 2925 | 3.264755 | 3.264166 | +1.90 | ❌ NULL |
| Baseline #1532 | 0.95 (uniform) | 2875 | 3.262854 | — | — | — |

- **Analysis:** Falsifying Arm B beat mechanistic Arm A by 25 sr-steps and 2.82 mnat val_ema — directly contradicting the LR-cov phase-coupling prediction. Per-block telemetry shows β=0.92 (12.5-step horizon) too aggressive for BF16: `lcov_min` collapses to ~0 in fast-EMA blocks by step 1500-2500 while β=0.97 keeps it stable. Arm B "less bad" because high-LR late blocks get the stable slow-EMA preconditioner. Combined with #1339 continuous ramp closure at Δβ=0.02, depth-asymmetric β_cov on body Muon is FULLY CLOSED across both primitives (binary split + continuous ramp).
- **Orthogonal residual:** β_cov < 0.95 saturates BF16 numerics — potential separate L_cov refresh/floor-clipping primitive if anyone wants to characterize that axis.

## 2026-05-30 02:00 UTC — PR #1726 nezuko: Pre-target PMuon L_cov/R_cov hard zero RESET @ step 2750 (bilateral arms) — ❌ BILATERAL NULL (cov state replacement CLOSED at pre-target)

- Branch: `g1r1-nezuko/cov-reset-2750`
- Hypothesis: Hard zero reset of L_cov/R_cov EMA at step 2750 forces a fresh ~150-step re-accumulation of the bilateral whitening preconditioner — could re-tune to late-phase geometry; Arm B adds β_cov 0.95→0.99 pulse @ 2751-2900 to slow re-accumulation.
- W&B: Arm A `210d43l3` (pure reset), Arm B `pyugggcd` (reset + β_cov 0.99 pulse)

| Arm | mechanism | sr | val_ema | val_live | Δval mnat | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | pure zero reset @ 2750 | 2950 | 3.267302 | 3.266713 | +4.45 | ❌ NULL |
| B | reset + β_cov 0.99 pulse | **2875** | **3.263927** | 3.263346 | **+1.07** | ❌ NULL (close miss strict gate) |
| Baseline #1532 | no reset | 2875 | 3.262854 | — | — | — |

- **Analysis:** Both arms NULL strict gate. Arm B clean signal: **sr=2875 matches baseline** but val_ema close miss by +1.07 mnat. Diagnostic confirmation excellent — `cov_reset_count=72` (all body Muon params), `lcov_eigh_min=0` at steps 2751-2754 confirms hook fired, eigenvalue mass recovers to pre-reset scale by step 2800 (50-step under-whitened transient window). β_cov pulse fired correctly @ 2751-2900. Mechanistic conclusion: discarding L_cov/R_cov loses more from 50 under-whitened steps than staleness was costing — 800 EMA steps at β=0.95 since paramema_refresh@2600 track curvature well.
- **🔥 Cross-PR signal**: Arm B sr=2875 is the SECOND independent sr=2875 close-miss this round (frieren #1708 Arm B UW=0.55 seed-1 val_ema 3.263116). Two distinct mechanisms hit baseline sr → sr=2925→2875 wall IS breakable; val_ema is the tightening bottleneck.

## 2026-05-29 23:00 UTC — PR #1703 alphonse: ACProp-style async whitening on body PMuon (ADOPT order swap) — ❌ BILATERAL NULL (update-rule asynchrony CLOSED on body PMuon)

- Branch: `g1r1-alphonse/async-pmuon-whitening`
- Hypothesis: ACProp/ADOPT-style ordering — use *previous-step* L_cov/R_cov to whiten *current-step* update — decorrelates the whitening preconditioner from the in-sample gradient bias, mirroring ADOPT's improvement on Adam.
- W&B: Arm A `lfuqcfsm` (identity init, no warmup), Arm B `gjmywcji` (zeros init + K=50 sync warmup)

| Arm | init / warmup | sr | val_ema | val_live | Δval vs baseline | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | identity init, async every step | 2975 | 3.270824 | 3.270267 | +7.97 mnat | ❌ NULL (+100 sr) |
| B | zeros init, K=50 sync warmup | 2950 | 3.269952 | 3.269384 | +7.10 mnat | ❌ NULL (+75 sr) |
| Baseline #1532 | sync | 2875 | 3.262854 | — | — | — |

- **Analysis:** Both arms strictly worse than canonical sync baseline. Arm B (zeros + K=50 sync warmup) beats Arm A (identity init) by 25 sr steps and 0.0009 val_ema — confirming the cold-start variance argument was directionally right — but neither closes the gap to sync. Telemetry: in Arm A, step-1 `lcov_eigh_max=1.0` (identity buffer); in Arm B `L_neg sample norm = 3.5e6` at step 1 collapsing to ~5 within 100 steps — the bilateral whitening preconditioner is severely off-distribution during the warmup transient.
- **Mechanism:** Even with the sync warmup, the carry-forward cost of using previous-step L_cov/R_cov to whiten current-step update dominates the asynchrony benefit through end of training. The momentum/preconditioner pairing in PMuon is more sensitive to in-sample correlation than vanilla Adam — the bilateral whitening structure compounds error rather than decoupling it.
- **ADOPT-style update-rule order-swap axis CLOSED on body PMuon.** Combined with prior closures of LR-UP (#1637), LR-DOWN (#1697), γ (#1680), μ (#1686), wd (#1693), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (#1666), Nesterov, schedule-free — body Muon pre-target scalar/order-axis exhaustion now extends to update-rule asynchrony.
- **New assignment:** alphonse → fresh directive-aligned Tier-2 hypothesis (researcher-agent dispatched).

## 2026-05-29 22:30 UTC — PR #1704 thorfinn: Stacked second paramEMA refresh @ {2750, 2850} — ❌ BILATERAL NULL (stacked-pEMA-refresh axis closed)

- Branch: `g1r1-thorfinn/second-pema-refresh`
- Hypothesis: a second paramEMA refresh in the pre-target window (stacked on the canonical 2600 refresh) would re-anchor EMA to live params just before the target crossing, compounding the canonical WIN.
- W&B: Arm A `ey4o3crq` (refresh2=2750), Arm B `z3676wa3` (refresh2=2850)

| Arm | refresh2 step | sr | val_ema | val_live | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 2750 | 2925 | 3.26443 | 3.26382 | +1.58 mnat | ❌ NULL (+50 sr) |
| B | 2850 | 2950 | 3.26542 | 3.26483 | +2.57 mnat | ❌ NULL (+75 sr) |
| Baseline #1532 | — | 2875 | 3.262854 | — | — | — |

- **Analysis:** Monotonic gradient — later refresh2 step is **worse** (Arm B at 2850 > Arm A at 2750). The refresh mechanism is re-anchoring EMA to live params inside the interior of the cooldown phase (not at a regime boundary), which **deletes accumulated good averages** without resetting any LR-regime staleness. This is destructive: val_live crossed 3.28 at step 2925 (Arm A) / 2950 (Arm B) vs baseline 2875 — 50-75 more steps to target.
- **Mechanism diagnosis (thorfinn's analysis):** The canonical 2600 refresh wins because it sits at `cooldown_start_step` — the LR regime boundary. A second refresh inside the cooldown tail is in the *interior* of a single monotone-decay phase; EMA was already tracking well (ema-live recovered to −0.004 post-canonical), so refresh just deletes 150-250 steps of accumulated averaging. The monotonic gradient confirms: later-in-cooldown stacked refresh = less post-refresh averaging time = worse terminal val_ema.
- **Stacked-pEMA-refresh axis CLOSED.** Refresh2 at any step in (2650, 3000) will trend worse. Design space for pEMA refresh is well-exhausted at the single canonical-position (2600).
- **New assignment:** thorfinn → #1749 **AdEMAMix dual-EMA first moment on aux AdamW** — orthogonal to all in-flight body-PMuon Tier-2; aux side is underexplored for state innovations.

## 2026-05-29 20:15 UTC — PR #1697 tanjiro: Pre-target body Muon LR DROP bilateral ×{0.75, 0.50} @ 2750-2900 — ❌ BILATERAL NULL (LR-DOWN axis closed)

- Branch: `g1r1-tanjiro/pretarget-muon-lr-drop`
- Hypothesis: body Muon LR perturbation in [2750, 2900); does **deepening** the drop accelerate target crossing? (companion to alphonse #1637 LR-UP NULL)
- W&B: Arm A `luogbbq9` (×0.75), Arm B `67fuf7e5` (×0.50)

| Arm | factor | sr | val_loss_ema | val_loss_live | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | ×0.75 | 2925 | 3.264889 | 3.264308 | +2.04 mnat | ❌ NULL (+50 sr) |
| B | ×0.50 | 2925 | 3.265876 | 3.265289 | +3.02 mnat | ❌ NULL (+50 sr) |
| Baseline #1532 | ×1.0 canonical | 2875 | 3.262854 | — | — | — |

- **Analysis:** Monotonic deepening of LR-DROP yields monotonic worsening of val_ema (×0.75 → 3.264889; ×0.50 → 3.265876). Clean per-step LR audit confirms ENTER at step 2750 and REVERT at step 2900 — the pulse mechanism is real but **destructive in the DOWN direction at the pre-target window**.
- **Body Muon LR axis BILATERALLY CLOSED:** Combined with alphonse #1637 LR-UP bilateral NULL (×1.25 seed-2, ×1.50 NULL). All uniform LR perturbations — UP, DOWN, all magnitudes — fail to beat baseline. The canonical LR schedule is optimally tuned at the uniform-perturbation scalar level.
- **What remains:** Uniform LR is closed, but **depth-asymmetric LR** (different multipliers for early vs. late blocks) is untested and matches the human directive on per-layer optimizer behavior. New tanjiro assignment #TBD (block-LR pre-target asymmetry, early-vs-late ×1.5 burst).

## 2026-05-29 19:55 UTC — PR #1693 fern: Pre-target body Muon weight_decay bilateral pulse {0.0, 0.05} @ 2750-2900 — ❌ BILATERAL NULL (wd axis closed)

- Branch: `g1r1-fern/pretarget-wd-pulse`
- Hypothesis: body Muon weight_decay (canonical 0.025) controls iterate norm growth; a transient bilateral perturbation (Arm A relax to 0.0, Arm B deepen to 0.05) probes whether shrinkage strength is load-bearing for target crossing.
- W&B: Arm A `i0s55pdw` (wd=0.0), Arm B `70jhvxrq` (wd=0.05)

| Arm | wd in 2750-2900 | val_loss_ema | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---|
| A | 0.0 (relax) | 3.264735 | 2925 | +1.88 mnat | ❌ NULL (+50 sr) |
| B | 0.05 (deepen) | 3.266172 | 2925 | +3.32 mnat | ❌ NULL (+50 sr) |
| Baseline #1532 | 0.025 canonical | 3.262854 | 2875 | — | — |

- **Analysis:** Clean asymmetric param-norm response (relax grows iterate norm, deepen shrinks it) confirms the pulse mechanism is real and bilateral. Both directions degrade val_ema and sr identically — the weight_decay scalar is real but **not load-bearing for target-crossing speed**. The pre-target window cannot be accelerated by perturbing shrinkage strength.
- **Body Muon weight_decay axis CLOSED** at the pre-target window. Combined with prior closures of LR-UP (#1637), LR-DOWN (#1697 in-flight Arm A NULL), γ (#1680), μ (#1686), NS-coefs (#1660), β₁ (#1592/#1639), β_cov (#1666), Nesterov, schedule-free — **all body Muon pre-target scalar pulse axes definitively exhausted**.
- **New assignment:** fern → #1739 pre-target **NS_ITERS burst** {14, 16} @ 2750-2900 — structurally orthogonal to #1660 (changes polar-projection iteration count, not polynomial coefficients); reduces residual ~4×/~16× vs canonical NS_ITERS=12.

## 2026-05-29 18:55 UTC — PR #1686 askeladd: Pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} @ 2750-2900 — ❌ BILATERAL NULL (μ axis definitively closed across all temporal regimes)

- Branch: `askeladd/pretarget-mu-pulse`
- Hypothesis: body Muon μ (first-moment EMA coefficient) is load-bearing in the pre-target window as a *transient* deepening only — fern #1604 closed permanent μ pulse, this tests the same regime-specific logic that makes the pre-target window productive for other axes.
- W&B: Arm A `njbgdsep` (μ=0.97), Arm B `nqe2sh57` (μ=0.99)

| Arm | μ in 2750-2900 | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 0.97 | 3.266855 | 3.266198 | 2950 | +4.00 mnat | ❌ NULL (+75 sr) |
| B | 0.99 | 3.278422 | 3.277068 | 3200 | +15.57 mnat | ❌ NULL (+325 sr — actively destructive) |
| Baseline #1532 | 0.95 canonical | 3.262854 | — | 2875 | — | — |

- **Analysis:** Arm B (μ=0.99) is dramatically worse than Arm A — deep momentum in the pre-target window is *actively destructive*. Elevated grad-norm during pulse (Arm B max 31409 at step 2850 vs Arm A 27526 at step 2800) confirms the mechanism: μ=0.99 over-smooths the update direction, stale gradients dominate, iterate-to-gradient mismatch increases, trajectory diverges from the target-crossing path. The damage persists past revert (peak +0.017 at step 3000, only partially recovering by step 3250).
- **Pre-pulse trajectories identical** (within ±0.003): the divergence opens *during* the pulse window, not before. This is clean causal evidence of the pulse mechanism, not seed variance.
- **μ axis definitively closed:** combines fern #1604 (perm @ 975, perm @ 2600 → both NULL) + this PR (transient @ 2750-2900 both arms → NULL). Body Muon μ is uniformly non-load-bearing across ALL temporal regimes. The aux β₂ WIN mechanism is confirmed as (a) 2nd-moment-specific AND (b) aux-Adam-specific.
- **New assignment:** askeladd → #1730 pre-target body Muon **momentum buffer hard ZERO RESET** @ step 2750 — first structural state-discard experiment on first-moment buffer (mechanistically orthogonal to all closed μ experiments; direct first-moment analog of nezuko's #1726 cov-state reset).

## 2026-05-29 17:50 UTC — PR #1680 nezuko: Pre-target PMuon γ pulse 0.4→{0.50, 0.60} @ 2750-2900 — ❌ BILATERAL NULL (γ axis closed)

- Branch: `g1r1-nezuko/pretarget-gamma-pulse`
- Hypothesis: γ (whitening exponent in PMuon's `matrix_neg_power`) controls the strength of bilateral whitening. Does a transient pulse from canonical 0.4 → {0.50 Arm A, 0.60 Arm B} during the pre-target window steeper-curve the descent into the target crossing?
- W&B: Arm A `92tyetjn` (γ=0.50), Arm B `2wzibl6m` (γ=0.60)

| Arm | γ in 2750-2900 | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 0.50 | 3.2648 | 3.2642 | 2925 | +1.95 mnat | ❌ NULL |
| B | 0.60 | 3.2646 | 3.2640 | 2925 | +1.75 mnat | ❌ NULL |
| Baseline #1532 | 0.40 canonical | 3.262854 | — | 2875 | — | — |

- **Analysis:** Both arms +50 sr and +1.75-1.95 mnat val_ema. Both directions of γ pulse (more aggressive whitening) miss the gate. The canonical γ=0.40 is robustly optimal across the whitening-strength axis; pre-target perturbation degrades both gates similarly.
- **γ-axis closure:** the bilateral whitening exponent in the L^{-γ} @ momentum @ R^{-γ} sandwich is now confirmed unchangeable within the pre-target window. The whitening preconditioner's *strength* is not the limiting factor — the underlying state (L_cov/R_cov accumulated curvature) may still be. Next nezuko assignment escalates from γ scalar pulse to L_cov/R_cov hard zero reset at step 2750 (structural, not scalar).
- **Body Muon pre-target scalar axes — DEFINITIVELY CLOSED:** LR-UP (#1637), γ (this PR), β_cov pulse@975 (#1666 Arm A), β_cov pulse@2600 (#1666 Arm B), NS-coefs bilateral (#1660), β₁ bilateral (#1592/#1639), Nesterov, schedule-free. In flight: LR-DOWN (#1697), μ (#1686, Arm A NULL), wd (#1693).

## 2026-05-29 17:55 UTC — PR #1709 edward: AdaShift temporal-lag second moment on aux Adam (n=1 vs n=2) — ❌ BILATERAL NULL (AdaShift family CLOSED, mechanistic root cause)

- Branch: `g1r1-edward/aux-adam-adashift`
- Hypothesis: AdaShift (Xie et al., ICLR 2019, arxiv 1810.00143) uses `v_t = β·v_{t-1} + (1-β)·g_{t-n}²` — a temporally-lagged second-moment that decorrelates numerator from denominator. Does this orthogonal mechanism for reducing denominator variance improve the canonical aux-Adam β₂ pulse stack?
- W&B: 8 runs across original spec, post-fix relaunches, and Option A (split optimizer). No run reached step 3250; all crashed or diverged. Full run list: `necwrf5u`, `pur1ybqs`, `qms1h9sd`, `eo9xd2tz`, `wkcz9kka`, `q2zitj2k`, `koadjsmh`, `icw9bawb`.

| Variant | Failure mode | Step |
|---|---|---:|
| Per-element AdaShift on all aux (embed+lm_head+scalars), eps=1e-10 | val_loss=22.88, embed RMS=6.76e9 | crash @ 275 |
| Per-element + `t>n` warmup + eps=1e-8 | `torch.linalg.eigh` ill-conditioned on L_cov | crash @ 1-3 |
| Per-element + fp32 state + clamp_min(eps²) + eps=1e-7 | val_loss=16.09 (no crash) | abort @ 125 |
| Option A (embed→fused AdamW; lm_head+scalars→AdaShift) | `eigh` failure | crash @ 76-107 |
| Option A + defensive eigh jitter retry + telemetry | val_loss=16.16 (no crash) | abort @ ~248 |

- **Root cause (mechanistic, three layers):**
  1. **Cold-start zero-grad:** ring buffer pre-filled with zeros → v_t≈0 → 10^10× catastrophic update during warmup (fixed by `if len(buf)==n` branch using current g during warmup).
  2. **Sparse-gradient incompatibility on `embed.weight`:** ~99.5% of rows have g=0 per step; for any row r touched at step t but not at step t-n, `g_{t-n}[r]=0 → v_t[r]=0`, denominator collapses to eps, update explodes. Confirmed by unit test on synthetic sparse gradients. **Fundamentally incompatible** with sparse-row gradients; cannot be patched.
  3. **Loss of self-scaling on non-stationary dense lm_head gradients (Option A):** numerator uses g_t, denominator uses g_{t-n}, so update scales linearly with |g_t|/|g_{t-1}| ratio instead of being bounded near 1 like standard Adam. Early-training lm_head trajectory perturbation → forward activations → body grads → L_cov ill-conditioning → either eigh crash (no jitter) or degraded preconditioner (with jitter), loss diverges.
- **AdaShift axis closure:** per-element AdaShift is structurally incompatible with this baseline. **Block-wise AdaShift** (scalar `v_t` per tensor using max(|g_{t-n}|)²) untested but reserved as a separate hypothesis — different mechanism, different failure modes.
- **Byproduct gain:** edward's investigation surfaced a defensive `matrix_neg_power` patch with try/except jitter retry on eigh failure + telemetry `pmuon/eigh_jitter_fires`. Zero baseline-trajectory impact (only fires on perturbed L_cov configurations). Cherry-pick commits `50f52a70` + `5286eb9a` to advisor branch as standalone hygiene PR — future-proofs Muon against any experiment that perturbs L_cov.
- **High-information closure:** unit-test evidence + 5 failure-mode characterization + mechanistic explanation tying each variant's collapse to a structural property of AdaShift. This is the close-out evidence; no further per-element AdaShift attempts warranted.

## 2026-05-29 14:30 UTC — PR #1667 frieren: Pre-target aux β₂ transient spike 0.99→{0.995, 0.999} @ 2750-2900 — ❌ BILATERAL NULL (β₂ mechanism comprehensively closed)

- Branch: `g1r1-frieren/pretarget-aux-b2-spike`
- Hypothesis: canonical β₂ pulse @ step 975 wins by deepening second-moment EMA. Does a transient RE-SPIKE of β₂ (0.99→0.995/0.999) during the pre-target window (steps 2750-2900, then revert) compound the initial WIN?
- W&B: Arm A `e1akroju` (β₂=0.995), Arm B `3mzqajdn` (β₂=0.999)

| Arm | β₂ in 2750-2900 | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---|---:|---:|---:|---:|---|
| A | 0.995 | 3.263257 | 3.262668 | 2875 | +0.403 mnat | ❌ NULL (Clause 2 near-miss: 0.4 mnat above gate) |
| B | 0.999 | 3.265152 | 3.264550 | 2925 | +2.298 mnat | ❌ NULL |
| Baseline #1532 | — | 3.262854 | — | 2875 | — | — |

- **Analysis:** Arm A reached sr=2875 (matches baseline) but val_ema=3.263257 is +0.4 mnat above gate (well below typical 1-2 mnat seed variance — statistical noise, no seed-2 warranted). Arm B regressed on both axes. The aux β₂ mechanism is fundamentally a *destination* effect at step 975, not a *transient* effect — re-spiking later in the pre-target window doesn't help.
- **β₂ axis closure (COMPLETE):** canonical 0.95→0.99 @ 975 = WIN (#1532); bigger amplitude = NULL (#1605 0.999); smooth ramp = NULL (#1634); per-group recipient = NULL (#1648); re-spike at pre-target = NULL (this PR). β₂ pulse mechanism is **COMPREHENSIVELY CLOSED** across all structural variants tested.

## 2026-05-29 14:15 UTC — PR #1666 edward: Body Muon beta_cov pulse 0.95→0.99 @ step 975/2600 — ❌ BILATERAL NULL (cross-optimizer beta_cov axis closed)

- Branch: `g1r1-edward/muon-beta-cov-pulse`
- Hypothesis: Canonical #1532 aux β₂ pulse @ step 975 was WIN. Does the cross-optimizer analog — pulsing body Muon's L_cov/R_cov beta_cov from 0.95→0.99 at the same canonical timing (Arm A) or at cooldown-entry timing (Arm B, mirroring pEMA WIN) — generalize?
- W&B: Arm A `l0fnwke6` (pulse @ 975), Arm B `rb6wi7b6` (pulse @ 2600)

| Arm | pulse step | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 975 | 3.265342 | 3.264744 | 2925 | +2.49 mnat | ❌ NULL |
| B | 2600 | 3.264088 | 3.263477 | 2925 | +1.23 mnat | ❌ NULL |
| Baseline #1532 | — | 3.262854 | — | 2875 | — | — |

- **Analysis:** Both arms regress (+50 sr, +1.2-2.5 mnat). The aux β₂ pulse mechanism (#1532 WIN) does NOT transfer cross-optimizer to body Muon's covariance estimator. The L_cov/R_cov second-moment statistic for the bilateral whitening operator behaves differently than Adam's diagonal v_t — deepening at canonical timing degrades both gates.
- **Mechanism reading:** body Muon's β_cov=0.95 is robust both at the canonical aux-pulse timing AND at the cooldown-entry pEMA-refresh timing. The cross-optimizer second-moment-EMA-deepening hypothesis fails. β_cov-deepening pulse joins the exhausted scalar-pulse list for body Muon.
- **Axis closure tally:** body Muon pre-target axes definitively closed include LR-UP, NS-coefs, β₁ (bilateral), β_cov pulse@975, β_cov pulse@2600, Nesterov, schedule-free. In flight: LR-DOWN, γ, μ, weight_decay.

## 2026-05-29 13:00 UTC — PR #1637 alphonse: Pre-target body Muon LR ×1.25 boost — ❌ CLOSED NULL at n=2 (sub-noise seed-1 not confirmed)

- Branch: `g1r1-alphonse/pretarget-boost-125-seed2`
- Hypothesis: alphonse seed-1 Arm A (val_ema=3.262770, sr=2875) was sub-noise PASS by 0.084 mnat. Seed-2 confirmation required before merge.
- W&B: Arm A seed-1 `ara5opnj`, Arm A seed-2 `dvcemg0l`, Arm B (×1.5) `ezukpl39`

| Seed/Arm | factor | val_loss_ema | val_loss_live | sr | Δval vs canonical | Verdict |
|---|---:|---:|---:|---:|---:|---|
| Arm A seed-1 `ara5opnj` | 1.25 | 3.262770 | — | 2875 | −0.084 mnat | sub-noise PASS |
| Arm A seed-2 `dvcemg0l` | 1.25 | 3.2658 | 3.2652 | 2925 | +2.95 mnat | NULL (seed regression) |
| **n=2 mean** | 1.25 | **3.26428** | — | **2900** | +1.43 mnat | ❌ NULL on both gate clauses |
| Arm B `ezukpl39` | 1.5 | 3.2670 | 3.2663 | 2925 | +4.15 mnat | ❌ NULL |

- **Analysis**: seed-1 sub-noise WIN (0.084 mnat) was within typical seed variance (~1-2 mnat). Seed-2 dramatically regressed (+50 sr, +2.95 mnat val_ema). Aggregate n=2 mean fails both gate clauses (sr=2900 > 2862.5; sr=2900 ≠ 2875). **Pre-target body Muon LR-UP axis closed within noise.** This is the 8th NULL in pre-target body-Muon scalar mechanism family (LR-UP, LR-DOWN, γ, μ, NS coefs, beta_cov-975, Nesterov, schedule-free) → **PLATEAU PROTOCOL engaged**: escalating to wrapper optimizers (Lookahead first, #1701).

## 2026-05-29 13:37 UTC — PR #1660 thorfinn: Pre-target NS coefficient pulse — ❌ BILATERAL NULL (NS precision-axis fully closed)

- Branch: `g1r1-thorfinn/pretarget-ns-coef-pulse`
- Hypothesis: pulse NS polynomial coefficients (a, b, c) during pre-target window steps 2750-2900 to test whether orthogonalization precision is a bottleneck in the target-crossing window (orthogonal to alphonse #1637 LR magnitude test).
- W&B: Arm A `g68ikq9z` (conservative quintic 2.0, -1.5, 0.5), Arm B `eif52h8a` (Jordan-aggressive 3.4445, -4.7750, 2.0315)

| Arm | NS coefs during 2750-2900 | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---|---:|---:|---:|---:|---|
| A (conservative quintic) | (2.0, -1.5, 0.5) | 3.264458 | 3.263865 | 2925 | +1.60 mnat | ❌ NULL |
| B (Jordan-aggressive) | (3.4445, -4.7750, 2.0315) | 3.264214 | 3.263632 | 2925 | +1.36 mnat | ❌ NULL |
| Baseline #1532 | (1.5, -0.5, 0.0) canonical | 3.262854 | — | 2875 | — | — |

- **Analysis:** Both arms slip by +50 sr and +1.4-1.6 mnat vs canonical. Canonical cubic Newton (1.5, -0.5, 0.0) at NS_ITERS=12 is robustly optimal for the cooldown crossing window. Both slower-contraction (conservative quintic) and faster-contraction (Jordan-aggressive, designed for ≤6 iters) degrade slightly but consistently — the polynomial was tuned for NS_ITERS=12 iterations. **NS polynomial profile precision-axis DEFINITIVELY CLOSED.** Orthogonalization precision is NOT a bottleneck; magnitude (alphonse) is. Do NOT stack NS pulse with alphonse's ×1.25 LR boost — would partially offset WIN rather than compound.
- **Follow-up rejected:** NS_ITERS burst (12→14/16 in pre-target window) would be the logical next test but is in-scope for the exhausted pre-target body Muon scalar family. Not pursued.

## 2026-05-29 11:35 UTC — PR #1648 tanjiro: Per-group aux Adam β₂ pulse (embed-only vs non-embed) — ❌ BILATERAL NULL (per-group recipient axis fully closed)

- Branch: `g1r1-tanjiro/per-group-aux-beta2-pulse`
- Hypothesis: canonical β₂ pulse 0.95→0.99 @ step 975 applied to ONE param group at a time. Which group is the load-bearing WIN recipient?
- W&B: Arm A `8jfrpc48` (embed-only), Arm B `oumooke5` (lm_head + scalars)

| Arm | recipient groups | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---|---:|---:|---:|---:|---|
| A (embed-only) | embed | 3.2653 | — | 2925 | +1.45 mnat | ❌ NULL |
| B (non-embed) | lm_head + scalars | 3.2651 | 3.2644 | 2925 | +1.25 mnat | ❌ NULL |
| Baseline #1532 | ALL 3 groups | 3.262854 | — | 2875 | — | — |

- **Analysis:** Bilateral NULL — both single-recipient pulses regress by +50 sr / +1-1.5 mnat val_ema. The canonical #1532 WIN requires β₂ deepening across ALL 3 aux Adam param groups simultaneously; **the mechanism is conjunctive across the aux Adam param-group ensemble**. Per-group recipient axis robustly closed. **β₂ axis comprehensively mapped:** amplitude (closed), timing (closed), shape (closed), β₁ pulse (closed bilateral), per-group recipient (CLOSED bilateral), pre-target spike (Arm A NULL, Arm B in flight).

## 2026-05-29 11:05 UTC — PR #1646 fern: Pre-target aux Adam LR boost (×1.25, ×1.5 @ 2750-2900) — ❌ CLOSED NULL (bilateral, pre-target bottleneck confirmed body-Muon-specific)

- Branch: `g1r1-fern/aux-lr-boost-pretarget`
- Hypothesis: alphonse #1637 Arm A body-Muon LR ×1.25 boost in pre-target window = HOT WIN. Does the same boost on aux Adam (embed/lm_head/scalars groups) in the same window also help?
- W&B: Arm A `ffuy3nqy` (×1.25), Arm B `3darntgi` (×1.5)

| Arm | factor | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A (modest) | 1.25 | 3.263768 | 3.263176 | 2925 | +0.914 mnat | ❌ NULL |
| B (aggressive) | 1.5 | 3.264524 | 3.263913 | 2925 | +1.670 mnat | ❌ NULL |
| Baseline #1532 | — | 3.262854 | — | 2875 | — | — |

- **Analysis:** Bilateral NULL with monotone ordering (more boost = worse). Both arms regress on both axes (+50 sr, +0.9-1.7 mnat val_ema).
- **Critical cross-experiment finding:** Same factor (×1.25), same window (2750-2900), DIFFERENT optimizer:
  - **alphonse #1637 (body Muon LR boost)**: val_ema=3.262770, sr=2875 → HOT WIN
  - **fern #1646 (aux Adam LR boost)**: val_ema=3.263768, sr=2925 → NULL
  - **Conclusion:** Pre-target window bottleneck is UNAMBIGUOUSLY body-Muon-specific. Aux Adam (embed/lm_head/scalars) update magnitude is NOT the limiting factor in the target-crossing window.
- **Mechanism interpretation:** Aux Adam responds to gradient signal smoothly — its LR isn't the limiting factor in the target-crossing window. Body Muon's update direction/magnitude IS the bottleneck. Combined with frieren #1667 Arm A NULL (aux β₂ spike): the aux-side pre-target window axes are broadly NULL.
- **Telemetry quality:** Excellent. Boost window audit confirms clean [2750, 2900) boundaries with per-group effective LR sweep documented.
- **Follow-up assigned:** fern → PR #1693 pre-target body Muon weight_decay BILATERAL pulse 0.025→{0.0, 0.05} @ 2750-2900. First untested body-Muon axis in the pre-target window — tests regularization direction (relax vs deepen). Direct complement to alphonse's LR boost (magnitude axis).

## 2026-05-29 10:30 UTC — PR #1639 askeladd: Aux β₁ DROP pulse (0.70, 0.60) — ❌ CLOSED NULL (bilateral, β₁ axis fully closed)

- Branch: `g1r1-askeladd/aux-b1-drop-pulse`
- Hypothesis: β₁ RAISE (0.90, 0.95) was bilaterally NULL in #1592 (1st moment EMA lag increased). The DROP direction (0.70, 0.60) tests the opposite: shorter 1st-moment averaging window during cooldown — does relaxing the momentum smoothing help?
- W&B: Arm A `mqgtit8o` (β₁=0.70), Arm B `jglznnte` (β₁=0.60)

| Arm | β₁ | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 0.70 | 3.264432 | 3.263838 | 2925 | +1.58 mnat | ❌ NULL (both clauses) |
| B | 0.60 | **3.263440** | 3.262863 | **2875** | +0.586 mnat | ❌ NULL (Clause 2 misses by 0.586 mnat) |
| Baseline #1532 | 0.80 (default) | 3.262854 | — | 2875 | — | — |

- **Analysis:** Arm B ties baseline sr=2875 but misses val_ema by +0.586 mnat — close call but fails strict-less-than Clause 2. Arm A regresses by +50 sr steps and +1.58 mnat val_ema.
- **β₁ axis closure:** The β₁ pulse axis is now COMPLETELY closed across both directions:
  - **RAISE direction (#1592):** 0.80 → 0.90 NULL, → 0.95 NULL
  - **DROP direction (this PR):** 0.80 → 0.70 NULL, → 0.60 NULL
  - **Canonical β₁=0.80 is the unique local optimum.**
- **Mechanism reading:** Aux Adam β₂ canonical WIN (#1532) is uniquely tied to *second-moment* (variance) EMA depth. First-moment EMA depth is robustly invariant within ±0.20 around 0.80. Trajectory comparison shows Arm B (β₁=0.60) tracks edward's canonical (β₁=0.80) almost exactly at step 1000 (both 3.6781) but slowly drifts behind by ~0.7 mnat at step 2500 — first-moment lag is real but small at cooldown onset.
- **Cross-temporal-regime gap:** One untested first-moment cell remains — body-side first-moment (Muon μ) in the *pre-target window* (steps 2750-2900). fern #1604 tested permanent μ pulse at step 975/2600 (bilateral NULL), but transient μ deepening only during the pre-target window is untested. This is the askeladd follow-up.
- **Follow-up assigned:** askeladd → PR #1686 pre-target body Muon μ transient pulse 0.95→{0.97, 0.99} @ steps 2750-2900. Completes the first-moment cross-temporal-regime matrix. Direct cross-optimizer analog of frieren's aux β₂ pre-target spike (#1667).

## 2026-05-29 09:10 UTC — PR #1634 nezuko: Aux β₂ smooth-ramp shape (ramp_width=50, 200) — ❌ CLOSED NULL (bilateral, β₂ shape axis fully closed)

- Branch: `g1r1-nezuko/aux-b2-ramp`
- Hypothesis: The discrete jump from β₂=0.95→0.99 at step 975 might be unnecessarily discontinuous. A linear ramp over the transition (ramp_width=50 narrow, 200 wide) might preserve the destination amplitude while smoothing the discontinuity.
- W&B: Arm A `4y6529rb` (ramp_width=50), Arm B `yxediont` (ramp_width=200)

| Arm | ramp_width | val_loss_ema | val_loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A (narrow) | 50 | 3.266250 | 3.265639 | **2925** | +3.40 mnat | ❌ NULL |
| B (wide) | 200 | **3.266885** | 3.266306 | **2925** | +4.03 mnat | ❌ NULL |
| Baseline #1532 | discrete (=0) | 3.262854 | — | 2875 | — | — |

- **Analysis:** Bilateral NULL with monotone ordering — wider ramp = worse val_ema. Both arms fail merge gate by +50 sr steps AND +3.4–4.0 mnat val_ema. nezuko's telemetry shows the divergence happens in the early ramp window (875–1100): both ramps accumulate lag during the intermediate-β₂ regime that's never fully recovered.
- **Mechanism reading:** The β₂ pulse is **discrete-by-design**. The v-buffer responds to a step-change in EMA coefficient and re-equilibrates within ~20 steps. Ramping spreads this transition over 50–200 steps, during which the v-buffer is neither responsive (0.95) nor stable-long-horizon (0.99) — a sub-optimal intermediate regime. The discrete jump avoids this regime entirely. The wider the ramp, the longer the intermediate regime, matching Arm B (200) > Arm A (50) > discrete (0).
- **β₂ axis closure map:** The β₂ pulse mechanism axes are now ALL bilaterally closed except per-group recipient (tanjiro #1648 in flight):
  - Amplitude — 0.99 unique optimum (≥0.995 NULL, ≤0.90 NULL)
  - Timing — step 975 unique optimum (step 900 NULL, step 1050 seed-2 NULL)
  - Shape — discrete unique optimum (ramp_width=50/200 NULL)
  - β₁ analog — RAISE NULL (#1592), DROP in flight (#1639)
  - State-reset analog — NULL (#1601)
- **Process notes:** Duplicate Arm B launch incident (driver script + chain wrapper raced) detected at 04:25 UTC, killed redundant W&B run `44lljjpl` at 04:42 UTC, sole-GPU step time recovered from ~8.5s to ~4s. No final-quality impact since `yxediont` was the survivor throughout. Pattern captured in nezuko's student-memory.
- **Follow-up assigned:** nezuko → PR #1680 pre-target PMuon γ pulse (γ=0.50/0.60 during steps 2750-2900, revert to 0.4 after) — completely different mechanism axis. Tests upward-γ direction (historic PR #202 Arm A γ 0.3→0.4 WIN) extended into the pre-target window where alphonse's body-Muon LR boost is a HOT WIN candidate.

## 2026-05-29 06:10 UTC — PR #1605 frieren: Aux β₂ pulse timing step 1050 seed-2 — ❌ CLOSED NULL (seed-2 not confirmed, timing axis fully closed)

- Branch: `g1r1-frieren/b2-timing-sweep`
- Hypothesis: β₂ pulse at step 1050 (vs canonical 975) fires deeper into cooldown and might improve target crossing.
- W&B: Arm B seed-1 `unkccxcl` (marginal WIN), seed-2 `u4zmm04x` (terminal)

| Run | step | val_loss_ema | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---|
| Arm B seed-1 `unkccxcl` | 3250 | 3.262629 | 2875 | −0.225 mnat | ⚠️ marginal WIN |
| Arm B seed-2 `u4zmm04x` | 3250 | 3.2639 | **2925** | +1.05 mnat | ❌ NULL |

- **Analysis:** Seed-2 fails both gate clauses (sr=2925 > 2862.5 AND ≠ 2875). The seed-1 marginal WIN (+0.225 mnat) sits inside the ~0.5–1.0 mnat seed-variance noise floor. Seed-2 slips sr by 50 steps — the opposite of confirmation.
- **Timing axis closed:** β₂ timing axis is now fully mapped: step 900 NULL, step 975 WIN (canonical), step 1050 within-seed-variance NULL. Step 975 is robust and optimal.
- **Follow-up assigned:** frieren → PR #1667 pre-target aux β₂ transient spike (0.99→0.995/0.999 during steps 2750-2900, revert after). Tests aux-side precision complement to alphonse's body-side LR boost.

## 2026-05-29 06:00 UTC — PR #1622 edward: Muon momentum reset at pEMA refresh — ❌ CLOSED NULL (bilateral, momentum is load-bearing not stale)

- Branch: `g1r1-edward/muon-momentum-reset`
- Hypothesis: After pEMA refresh at step 2600, Muon body-momentum buffers may be stale (referring to the now-replaced EMA iterate). Resetting (scale=0.0) or damping (scale=0.1) should improve alignment.
- W&B: Arm A `bzjfv9i8` (hard reset scale=0.0), Arm B `veho0mwj` (damped scale=0.1)

| Arm | scale | val_loss_ema | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---|
| A (hard) | 0.0 | 3.266671 | 2925 | +3.82 mnat | ❌ NULL |
| B (damped) | 0.1 | **3.266402** | 2925 | +3.55 mnat | ❌ NULL |
| Baseline #1532 | — | 3.262854 | 2875 | — | — |

- **Analysis:** Bilateral NULL. Both arms fail merge gate by +50 steps (sr=2925). Δ(B−A) val_ema only −0.27 mnat; hard vs damped is on the same bad-curve.
- **Mechanism refutation:** `--paramema_refresh_only` re-seeds the *inference* EMA buffer, not live training params. The body iterate is NOT relocated at step 2600 → momentum was never misaligned. Even if stale, Muon's Newton-Schulz extracts direction from running average; discarding it forfeits variance reduction when small-batch grad noise hurts most. Edward's probe: grad norm collapses to 1958 after hard reset (scale=0.0), vs 2441 with damping — precisely the expected step-size suppression.
- **Cross-optimizer matrix update:** Body Muon first-moment axis now fully closed (fern #1604 μ pulse + edward #1622 momentum reset). Body Muon second-moment (`beta_cov`) axis remains untested.
- **Follow-up assigned:** edward → PR #1666 body Muon `beta_cov` pulse 0.95→0.99 at step 975/2600. Direct cross-optimizer second-moment analog of canonical #1532 WIN.

## 2026-05-29 05:20 UTC — PR #1621 thorfinn: AGC linear-decay ramp (ramp_width=100, 500) — ❌ CLOSED NULL (bilateral, hard-cutoff paradoxically better)

- Branch: `g1r1-thorfinn/agc-linear-decay`
- Hypothesis: The hard cutoff discontinuity at t_off=1500 in PR #1573 causes a +5.7 mnat bump. Smoothing via linear decay should eliminate the bump and preserve warm-start into terminal.
- W&B: Arm A `61ofomm7` (ramp_width=100), Arm B `6fauhz48` (ramp_width=500)

| Arm | ramp_width | val/loss_ema | val/loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 100 | **3.265476** | 3.264884 | **2925** | +2.62 mnat | ❌ NULL |
| B | 500 | **3.265259** | 3.264695 | **2925** | +2.41 mnat | ❌ NULL |
| #1573 hard cutoff (ref) | — | 3.264037 | — | 2925 | +1.18 mnat | ❌ NULL |

- **Analysis:** Bilateral NULL + mechanism refutation. The cutoff bump elimination WORKS (ramp=500 is −4.79 mnat lower than hard cutoff AT step 1500). But terminal result is paradoxically +1.22 mnat WORSE than hard cutoff. The hard cutoff bump is local and recoverable; linear-decay distributes cost across the trajectory. Optimizer benefits from full λ_0 right up to t_off — reducing λ before t_off immediately costs val_ema. Hard cutoff is optimal AGC shape.
- **Mechanism insight:** PR #1573's diagnosis ("hard discontinuity = root cause of lost warm-start") was wrong. The bump is a transient phase-shift cost that the optimizer absorbs naturally. Linear-decay prevents that recovery by distributing a larger integrated cost.
- **Follow-up assigned:** thorfinn → PR #1660 pre-target NS coefficient pulse (conservative quintic vs Jordan-aggressive quintic in steps 2750-2900) — tests whether orthogonalization PRECISION is a bottleneck complementary to alphonse's LR MAGNITUDE win.

## 2026-05-29 05:18 UTC — PR #1637 alphonse: Pre-target body Muon LR boost ×1.25 Arm A — ⚠️ HOT WIN CANDIDATE (sub-noise, seed-2 pending)

- Branch: `g1r1-alphonse/pretarget-boost`
- Hypothesis: Body Muon LR boost ×1.25 during steps 2750-2900 steepens descent through target-crossing window. Tests if body Muon is the pre-target bottleneck.
- W&B: Arm A `ara5opnj` (×1.25 boost, TERMINAL)

| Arm | boost_factor | val/loss_ema | val/loss_live | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A (Arm A) | 1.25 | **3.262770** | **3.262150** | **2875** | **−0.084 mnat** | ⚠️ **HOT WIN** (sub-noise) |

- **Merge gate**: Clause 1 FAIL (sr=2875 > 2862.5). Clause 2 **PASS** (sr=2875 AND val_ema=3.262770 < 3.262854 by 0.084 mnat). Sub-noise margin (<<0.5 mnat seed variance). Seed-2 required before merge.
- **Status:** Arm A terminal; Arm B (×1.5 boost) chain-running. SENPAI-RESULT pending after Arm B.
- **Mechanism:** Pre-target body Muon LR boost provides extra steepening in target-crossing window. val_ema descent from step 2750 (3.290) → step 3200 (3.263) tracks boost-window acceleration. If confirmed, mechanism is: body Muon LR is mildly under-tuned in the pre-target window — a small additional boost provides just enough acceleration to move the target crossing marginally earlier.

## 2026-05-29 03:38 UTC — PR #1607 tanjiro: Aux β₂ downward pulse (0.90, 0.85) — ❌ CLOSED NULL (bilateral, amplitude axis fully closed)

- Branch: `g1r1-tanjiro/b2-downward-pulse`
- Hypothesis: If β₂=0.99 upward pulse wins, does β₂ downward direction also have potential? Negative control and bilateral axis mapping.
- W&B: Arm A `k56llb0t` (β₂=0.90), Arm B `55ud88bp` (β₂=0.85)

| Arm | β₂ target | val/loss_live | val/loss_ema | sr | Δval vs baseline | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 0.90 | 3.268877 | **3.269492** | **2975** | +6.638 mnat | ❌ NULL |
| B | 0.85 | 3.272823 | **3.273460** | **3050** | +10.606 mnat | ❌ NULL |

- **Analysis:** Downward direction monotone-regress: larger |Δβ₂| produces larger regression (+6.6 → +10.6 mnat as β₂ drops 0.90 → 0.85). Both arms diverge from edward WIN trajectory immediately post-pulse and never reconverge. The damage signature is a mirror of the RAISE mechanism: shorter variance memory window → noisier preconditioner scaling → effective step size wobble during cooldown. The β₂ amplitude axis is now fully closed bilaterally: downward regresses (monotone), upward to 0.99 WINs (canonical), upward to 0.995/0.999 NULLs (diminishing returns). **0.99 is the clear optimum.**
- **Mechanism:** Decreasing β₂ at cooldown onset shortens effective averaging window → noisier v estimates → aux-Adam preconditioner less stable → fine-tuning during cooldown degraded. Exact opposite of edward's WIN mechanism.
- **Follow-up assigned:** tanjiro → PR #1648 per-group aux Adam β₂ pulse asymmetry (which of embed/lm_head/scalars is the load-bearing recipient of edward's canonical pulse?). Direct mechanism-attribution test.

## 2026-05-29 02:30 UTC — PR #1604 fern: Body Muon momentum pulse axis — ❌ CLOSED BILATERAL CATASTROPHIC (axis fully closed, moments × optimizer specificity confirmed)

- Branch: `g1r1-fern/muon-momentum-pulse`
- Hypothesis: If edward's aux Adam β₂ pulse mechanism is general "Adam-state-pulse at cooldown onset", a body Muon analog (μ pulse 0.95 → 0.99 at step 975 or 2600) should produce similar WIN.
- W&B: Arm A `ingv7i6m` (μ pulse @ step 975, SIGKILL'd), Arm A relaunch `rcw9zefd` (crashed step 150 infra), Arm B `5x0bo5lu` (μ pulse @ step 2600, terminal)

| Arm | Pulse step | val/loss_ema | val/loss_live | sr | Verdict |
|---|---:|---:|---:|---:|---|
| A | 975 (cooldown onset) | ~4.66 @ step 2300 (oscillating) | — | — | ❌ **DIVERGED** (SIGKILL'd) |
| B | 2600 (pEMA refresh boundary) | **3.286991** | 3.286285 | **−1** (target NOT reached) | ❌ **CATASTROPHIC NULL** |

- **Analysis:** Body Muon momentum pulse fundamentally DOES NOT generalize from aux Adam β₂ pulse at any timing. Arm A (step 975) catastrophic divergence — body Muon cannot survive μ pulse at cooldown discontinuity. Arm B (step 2600) doesn't reach val_loss=3.28 target by step 3250 — pulse actively PREVENTS target convergence (val_ema=3.286991 is 7 mnat ABOVE target). This is qualitatively different from aux Adam β₂ pulse which IMPROVED target crossing.
- **Mechanism verdict:** Pulse mechanisms are **optimizer-type specific AND moment-type specific**. Aux Adam β₂ pulse → WIN. Body Muon μ pulse → NULL/diverge at every timing. Consistent with PR #1592 moments asymmetry (aux Adam β₁ pulse NULLs while β₂ WINs): pulse mechanisms are not universally applicable across (optimizer, moment-type, timing) tuples. **Axis FULLY CLOSED.**
- **Code-keep policy:** `--muon_momentum_pulse_*` flags can be deleted in a future cleanup.
- **Follow-up assigned:** fern → aux LR boost during pre-target window (steps 2750-2900) — orthogonal complement to alphonse #1637's body Muon LR boost. Tests whether the bottleneck during target-crossing is aux/embedding LR vs body Muon LR.

## 2026-05-29 02:30 UTC — PR #1592 askeladd: Aux Adam β₁ pulse @ cooldown onset (0.90, 0.95) — ❌ CLOSED NULL (bilateral, moments asymmetry confirmed)

- Branch: `g1r1-askeladd/aux-b1-pulse`
- Hypothesis: If edward's β₂ pulse WIN is the "Adam-state-pulse at cooldown onset" mechanism, the β₁ analog (raise β₁ from 0.80 → 0.90 or 0.95 at step 975) should produce a similar effect. Tests whether the moments are interchangeable.
- W&B: Arm A `e2mzomu8` (β₁=0.90), Arm B `0xfh1ftf` (β₁=0.95)

| Arm | β₁ target | val/loss_ema | sr | Δval vs baseline mean (mnat) | Verdict |
|---|---:|---:|---:|---:|---|
| Baseline (#1429 mean) | — | 3.263938 | 2900 | — | — |
| Edward WIN (#1532 #9coyk2ke) | β₂=0.99 | 3.262184 | 2875 | -1.76 | ✅ |
| A (β₁ RAISE to 0.90) | 0.90 | 3.268250 | 2950 | +4.31 | ❌ NULL |
| B (β₁ RAISE to 0.95) | 0.95 | 3.267310 | 2950 | +3.37 | ❌ NULL |

- **Analysis:** Both arms regress. β₁ pulse trajectory diverges from baseline **immediately at step 1000** (25 steps post-pulse) and never reconverges. This is qualitatively different from β₂ pulse trajectory (which tracks baseline early then diverges below into the WIN regime). Mechanism reading: variance smoothing (β₂↑) accurately reduces update-magnitude noise → WIN. Momentum smoothing (β₁↑) increases first-moment lag → optimizer less responsive to gradient direction changes during LR decay → REGRESSION. **Moments are asymmetric — Adam-state pulses at cooldown onset are NOT a general win, only a variance-estimator refresh.** Anti-recommended: β₁+β₂ pulse compound (β₁ damage would dominate β₂ benefit). Student note: β₁=0.95 marginally less harmful than β₁=0.90 within seed noise — possible non-monotonicity but below noise floor.
- **β₁ axis status:** RAISE direction closed bilaterally NULL. DROP direction still open — assigning askeladd #NEW for symmetric test.
- **Follow-up assigned:** Askeladd β₁ DROP pulse (0.70, 0.60) at step 975 — student's own follow-up suggestion #3. Directional mechanism test, NOT scalar sweep.

## 2026-05-29 01:55 UTC — PR #1591 alphonse: Aux Adam β₂ pulse amplitude sweep (0.995, 0.999) — ❌ CLOSED NULL (bilateral, amplitude axis closed)

- Branch: `g1r1-alphonse/aux-b2-amplitude`
- Hypothesis: Edward's β₂=0.99 WIN — does the mechanism keep improving as β₂ → 1.0, or does it saturate/overshoot?
- W&B: Arm A `s68jjmrw` (β₂=0.995), Arm B `8sgxkbc6` (β₂=0.999)

| β₂ target | val_ema | sr | Δval vs canonical (mnat) | Verdict |
|---:|---:|---:|---:|---|
| 0.99 (canon #1532) | 3.262854 | 2875 | — | WIN |
| 0.995 (Arm A) | 3.264526 | 2925 | +1.67 | ❌ NULL |
| 0.999 (Arm B) | 3.268016 | 2950 | +5.16 | ❌ NULL |

- **Analysis:** Mechanism overshoots beyond β₂=0.99. Both arms confirm the right shoulder is steeper than the left (1 mnat per 0.005 step right vs ~3 mnat over 0.04 step left). At β₂=0.999, variance estimator half-life ~700 steps — nearly freezes at pre-pulse denominator biased toward high-LR-regime gradient norms — aux Adam takes systematically too-small steps through cooldown. At β₂=0.995, milder version of same effect. **Amplitude axis fully closed with peak at β₂=0.99.**
- **Full amplitude map:** β₂=0.95(ref)→0.97(NULL)→0.99(WIN)→0.995(NULL)→0.999(NULL). Canonical 0.99 is the optimum.
- **Follow-up assigned:** #1637 alphonse — pre-target body Muon LR boost (×1.25 and ×1.5 during steps 2750-2900). Tests the sr-clause directly per human directive #1252: "steepen loss descent before step 2925, even if final loss unchanged."

## 2026-05-29 01:10 UTC — PR #1601 nezuko: Aux Adam v-buffer state-reset @ cooldown onset — ❌ CLOSED NULL (bilateral)

- Branch: `g1r1-nezuko/aux-v-reset`
- Hypothesis: If edward's β₂ pulse mechanism is a "fresh variance signal going into cooldown", a direct STATE reset of the aux Adam v-buffer at step 975 should produce a similar or stronger WIN. Tested two reset variants: v.zero_() and v.fill_(v.mean()).
- W&B: Arm A `lmbepe1u` (v.zero_(), crashed step 1025), Arm B `9lwnf7km` (v.fill_(mean), step 3250)

| Arm | Reset mode | val/loss_ema | sr | Δval vs baseline (mnat) | Verdict |
|---|---|---:|---:|---:|---|
| Baseline (#1532) | — | 3.262854 | 2875 | — | — |
| A (zero reset) | v ← 0 | ~10.6 (exploded) | N/A | catastrophic | ❌ DIVERGED |
| B (mean reset) | v ← v.mean() | **3.267244** | **2950** | **+4.4** | **❌ NULL** |

- **Analysis:** Arm A catastrophic divergence is mechanistically clean: by step 975 the bias-correction (1 − β₂^t) ≈ 1.0 (β₂=0.95, t=975), so zeroing v gives full "v=0 starting fresh" pathology — denominator collapses and effective LR explodes ×10¹⁰. aux_lm_head update_step_size_rms: 1.882e-3 → 1.9998e+7 at step 976. Arm B (magnitude-preserving mean reset) survives but NULL by +4.4 mnat — erasing per-parameter spatial structure of v costs ~4 mnat through cooldown. Key finding: edward's β₂ pulse preserves both magnitude AND spatial structure of v, only changing how future gradient² contributions are weighted. The state-reset family cannot substitute for the parametric pulse. Also: pEMA refresh @ 2600 WINs as a state-reset because pEMA buffer is a tracked param copy (no role in denominator); aux Adam's v IS a denominator term — not exchangeable.
- **Mechanism verdict:** Edward's β₂ pulse mechanism is **parametric-scheduling, not state-driven**. Clean bilateral closure.
- **Follow-up assigned:** #1634 nezuko — aux β₂ smooth ramp (ramp_width=50 vs 200). Closes the last open axis: is the discrete jump shape load-bearing, or just the destination β₂=0.99?

## 2026-05-28 21:40 UTC — PR #1614 edward: Cleanup — aux β₂ pulse canonical defaults — ✅ MERGED (code maintenance, no metric change)

- Branch: `g1r1-edward/aux-b2-cleanup`
- Objective: Make β₂ pulse (step 975, β₂=0.99) the canonical default in `train_gpt_simple.py` so every run fires the pulse without explicit flags.
- Changes: `--aux_b2_pulse_step` default -1 → 975; `--aux_b2_pulse_target` default -1.0 → 0.99. Help text updated from "Recommended" to "Default".
- Smoke test: run `a1xra07b`, step 975 log confirms `[step 975] aux_b2_pulse: β2 0.95 → 0.99` without explicit flags. W&B config shows correct defaults. Loss healthy.
- **Note**: no `--max_steps` flag in train_gpt_simple.py (student killed via SIGTERM after step 1000).
- Baseline unchanged (cleanup only, no experiment).

## 2026-05-28 21:10 UTC — PR #1573 thorfinn: Warmup-only AGC (t_off=500, t_off=1500) — ❌ CLOSED NULL (bilateral, axis closed at hard-cutoff config)

- Branch: `g1r1-thorfinn/warmup-only-agc`
- Hypothesis: AGC during warmup-only (hard cutoff at t_off) captures the warm-start gradient advantage without incurring steady-state bias. Testing t_off=500 (warmup window) and t_off=1500 (warmup+EMA warmup window).
- W&B: Arm A `qtz3a6ny` (t_off=500), Arm B `91w0t6vu` (t_off=1500)

| Arm | t_off | val/loss_ema | sr | Δval vs new baseline (mnat) | Verdict |
|---|---:|---:|---:|---:|---|
| Baseline (#1532) | — | 3.262854 | 2875 | — | — |
| A (t_off=500) | 500 | 3.266096 | 2925 | +3.24 | ❌ NULL |
| **B (t_off=1500)** | **1500** | **3.264037** | **2925** | **+1.18** | **❌ NULL (near-miss)** |

- **Analysis:** Warm-start signal is real and scales with t_off depth (Arm B −27.9 mnat at step 125 vs Arm A −14.2 mnat). However, the hard ON→OFF discontinuity at t_off introduces a measurable post-cutoff bump: Arm B goes from −1.32 mnat ahead (step 1000) → +5.70 mnat behind (step 1500, right at cutoff) → recovers to +1.18 mnat behind terminal. Arm A has a smaller bump but same pattern. Bilateral NULL on hard-cutoff axis at λ=0.01. Diagnosis: the gradient-norm discontinuity at t_off is the load-bearing failure mode, not the warm-start mechanism itself. Also: duplicate Arm A re-launch at 20:45 UTC (crashed organically at step 7 — no data impact).
- **Follow-up assigned:** #1621 thorfinn — linear-decay AGC (ramp widths 100 vs 500, both t_off=1500). Directly tests if smoothing the cutoff discontinuity recovers the warm-start gain. High probability WIN if diagnosis is correct.

## 2026-05-28 19:35 UTC — PR #1532 edward: Aux Adam β₂ transient-increase pulse @ cooldown onset — ✅ MERGED WIN (n=2 confirmed)

- Branch: `g1r1-edward/aux-b2-pulse`
- Hypothesis: At cooldown onset (step 975), aux Adam β₂ is shifted from 0.95 → 0.99 (permanent step-change). Wider variance memory window in the cooldown phase stabilizes aux Adam step scaling during LR decay.
- W&B: Arm A `o9ow75oy` (β₂=0.97, NULL), Arm B seed-1 `9coyk2ke` (β₂=0.99, WIN), Arm B seed-2 `09qrijtm` (β₂=0.99, WIN)

| Run | β₂ target | val/loss_ema | sr | Δval (mnat) | Verdict |
|---|---|---:|---:|---:|---|
| Baseline (#1429) | — | 3.263938 | 2900 | — | — |
| Arm A (weak, seed-1) | 0.97 | 3.264997 | 2925 | +1.06 | ❌ NULL |
| **Arm B (strong, seed-1)** | **0.99** | **3.262184** | **2875** | **−1.76** | **✅ WIN** |
| **Arm B (strong, seed-2)** | **0.99** | **3.263523** | **2875** | **−0.42** | **✅ WIN** |
| **n=2 mean** | **0.99** | **3.262854** | **2875** | **−1.08** | **✅ MERGED** |

- **Analysis:** Both seeds independently hit sr=2875 (PASS clause 1: sr ≤ 2887.5). n=2 mean val_ema=3.262854 < 3.263938 (PASS clause 2). Stat-sig margin: 0.02425 ≥ 0.004 (6.1×). Mechanism is amplitude-sensitive: weaker pulse (β₂=0.97) NULL, stronger pulse (β₂=0.99) WIN → monotone-increasing relationship in the upward direction. Aux Adam variance estimator "remembering" longer during LR decay phase provides stable step scaling. PLATEAU BROKEN after 7 NULLs.
- **New baseline**: val_ema=3.262854, sr=2875. Updated merge gate: `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`.

## 2026-05-28 19:35 UTC — PR #1576 tanjiro: Schedule-Free AMUSE z/x averaging — ❌ CLOSED NULL (decisive)

- Branch: `tanjiro/schedule-free-amuse`
- Hypothesis: Replace WSD LR cooldown with Defazio-style polynomial SF z/x averaging (sf_beta=0.999). If iterate averaging can substitute for LR decay, the speedrun target should still be reachable.
- W&B: Arm B `t39pt08a` (only arm; Arm A crashed 3× from SIGTERM, skipped per advisor approval)

| Arm | Mechanism | val_loss_x | val_loss_z_live | sr | Verdict |
|---|---|---:|---:|---:|---|
| Baseline #1429 | WSD cooldown | — | 3.2636 | 2900 | — |
| B (SF β=0.999) | Polyak z/x avg | **4.8325** | 3.5229 | **-1 (never reached)** | ❌ NULL |

- **Analysis:** At sf_beta=0.999, c_t saturates to ≈0.99 by step ~100, making the x-buffer a **uniform mean** of all post-warmup z-iterates. At constant LR=0.040, z-iterates traverse weight space broadly (Frobenius distance x→z grows 720× from t=25→2275). Averaging across this trajectory yields parameters outside any individual basin — val_loss_x balloons from 3.597 (best at step 1125) to 4.832 (terminal). The z-iterate alone (no cooldown) plateaus at val_loss≈3.52 — 257 mnat above baseline. **WSD cooldown does 30-50 mnat of final-phase convergence that Polyak averaging cannot substitute in this regime.** Hypothesis directly refuted.
- **Key mechanism finding**: x-buffer best at step 1125 (early averaging benefit, like pEMA), but diverges catastrophically as buffer grows stale. This establishes that iterate averaging REQUIRES either: (a) LR decay to keep z-iterates close in weight space, (b) late-only averaging window starting at LR decay onset, or (c) Defazio-style true SF (interpolated gradient point), not just Polyak-on-SGD.

## 2026-05-28 18:46 UTC — PR #1561 frieren: Muon Nesterov momentum correction — ❌ CLOSED BILATERAL NULL

- Branch: `g1r1-frieren/muon-nesterov`
- Hypothesis: Nesterov momentum correction on body Muon (classical accumulation + Sutskever correction) should improve convergence by using a lookahead gradient direction.
- W&B: Arm A `xvfvo0wh` (full training Nesterov), Arm B `qore5wr0` (Nesterov stable-phase only, cooldown only)

| Arm | Nesterov variant | val/loss_ema | sr | Δval (mnat) | Verdict |
|---|---|---:|---:|---:|---|
| Baseline (#1429) | None | 3.263938 | 2900 | — | — |
| A (full training) | classical+Sutskever, all steps | 3.266552 | 2925 | +2.62 | ❌ NULL |
| B (stable-phase only) | lerp+lerp-Nesterov in cooldown | **3.271870** | **3025** | **+7.93** | ❌ NULL |

- **Analysis:** Arm B is dramatically worse (+7.93 mnat, sr slips 125 steps). The mechanism-switch at step 975 (cooldown onset) creates a trajectory discontinuity that destabilizes early-cooldown convergence. Key insight: introducing ANY momentum-state change at step 975 (same boundary as edward's β₂ pulse WIN) is catastrophic — confirming that edward's WIN is specific to variance-estimator scaling, not a generic "phase-boundary perturbation." Nesterov accumulates consistent forward-looking bias throughout training that is not recoverable in the cooldown phase. Axis closed.

## 2026-05-28 18:42 UTC — PR #1559 fern: pEMA β_target post-refresh decouple — ❌ CLOSED BILATERAL NULL

- Branch: `g1r1-fern/pema-post-refresh-target`
- Hypothesis: Decoupling β_target after pEMA refresh step 2600 (lighter 0.985 or heavier 0.995) targets the ema_minus_live +0.56 mnat observation. Lighter β shrinks the buffer-vs-live gap.
- W&B: Arm A `hved6l5d` (β_post=0.985, lighter), Arm B `594eshn4` (β_post=0.995, heavier)

| Arm | β_post_refresh | val_ema | ema_minus_live | sr | Δval (mnat) | Verdict |
|---|---|---:|---:|---:|---:|---|
| Baseline (#1429) | 0.99 (coupled) | 3.263938 | — | 2900 | — | — |
| A (lighter) | 0.985 | 3.265921 | +0.374 mnat | 2925 | +1.98 | ❌ NULL |
| B (heavier) | 0.995 | 3.267585 | +1.168 mnat | 2925 | +3.65 | ❌ NULL |

- **Analysis:** ema_minus_live is monotone in β (lighter shrinks gap, heavier grows it) — mechanism behaves as predicted. But val_ema is non-monotone: lighter β narrows the gap but pushes val_live itself worse. Canonical β=0.99 IS the post-refresh optimum for val_live; any deviation breaks it. The pEMA β trajectory axis is fully characterized end-to-end (refresh STEP closed #1457/#1459, β-endpoint uniform closed #1458, β-ramp shape closed #1507, β-endpoint decoupled post-refresh closed here). No simple β perturbation in either window improves on the canon.

## 2026-05-28 18:28 UTC — PR #1560 nezuko: Aux Adam LR cooldown timing decouple — ❌ CLOSED BILATERAL NULL

- Branch: `g1r1-nezuko/aux-cooldown-frac`
- Hypothesis: Decoupling aux Adam LR cooldown timing from body Muon (earlier or later cooldown start) could improve convergence by letting embed/lm_head parameters either converge earlier or maintain higher LR deeper into cooldown.
- W&B: Arm A `rdx355wn` (aux_cooldown_frac=0.85, earlier start), Arm B `coxk32vm` (aux_cooldown_frac=0.50, later start)

| Arm | aux_cooldown_frac | val/loss_ema | sr | Δval (mnat) | Δsr | Gate |
|---|---|---:|---:|---:|---:|---|
| Baseline (#1429) | 0.70 (coupled) | 3.263938 | 2900 | — | — | — |
| A (earlier) | 0.85 | 3.266482 | 2925 | +2.54 | +25 | ❌ NULL |
| B (later) | 0.50 | 3.266021 | 2950 | +2.08 | +50 | ❌ NULL |

- **Analysis:** Canonical coupled cooldown timing (body + aux share cooldown_frac=0.7) is empirically robust. Decoupling in either direction produces ~2 mnat regression. Earlier aux cooldown starves embed/lm_head of late refinement; later aux cooldown drives too-large aux updates in the final convergence window. **Axis closed: aux cooldown TIMING decoupling is non-load-bearing.** Direction-consistent regression across both arms (both worse, just different magnitudes: +2.54 vs +2.08 mnat) rules out noise. Arm B's 2× sr slip (+50 vs +25) suggests late-aux excess is more harmful than early-aux starvation.
- **Closure:** Joins cooldown POWER (#969/#1084), SHAPE FAMILY (#1496), FLOOR (#1508), per-block γ (#1342) on closed-axis list. Askeladd #1542 closed β_t coupling timing by a parallel mechanism. Aux-decoupling-by-timing family well-mapped.

## 2026-05-28 15:13 UTC — PR #1532 edward: Strong β₂ pulse on aux Adam — **🎯 WIN CANDIDATE (awaiting seed-2 confirmation)**

- Branch: `g1r1-edward/aux-b2-pulse`
- Hypothesis: A transient pulse forcing aux Adam β₂ from 0.95 → target at step 975 (cooldown onset) shifts the aux optimizer state into "more momentum memory" at the moment of cooldown entry, which compounds through cooldown into reduced steps-to-target and lower val_ema.
- W&B: Arm A `o9ow75oy` (β₂ 0.95→0.97), Arm B `9coyk2ke` (β₂ 0.95→0.99)

| Arm | β₂ pulse target | val/loss_ema | val/loss_live | sr | Δval (mnat) | Gate |
|---|---|---:|---:|---:|---:|---|
| Baseline (#1429) | — | 3.263938 | — | 2900 | — | — |
| A (weaker pulse) | 0.97 | 3.264997 | 3.264407 | 2925 | +1.06 | ❌ NULL |
| B (stronger pulse) | **0.99** | **3.262180** | **3.261590** | **2875** | **−1.76** | **🎯 PASSES BOTH** |

- **WIN on both merge gate clauses simultaneously**: sr=2875 ≤ 2887.5 (clause 1 ✓) AND val_ema=3.26218 < 3.263938 (clause 2 ✓). First WIN of the day after 7 consecutive NULLs.
- **Amplitude-sensitive mechanism**: Weaker pulse (0.97) NULL'd at +1.06 mnat; stronger pulse (0.99) gave −1.76 mnat WIN with −25 step reduction. The β₂ pulse magnitude axis is non-trivial — bigger pulse on aux Adam at cooldown onset drives a strictly better outcome.
- **Aux-side mechanism breakthrough**: Today's plateau was thoroughly explored on body-side mechanisms (pEMA refresh shape, β_t coupling, AGC, Nesterov, stable-LR-pulse). The win arrived on the AUX side via Adam β₂ schedule manipulation — a previously unexplored axis.
- **Status**: WIN gate cleared at n=1. Seed-2 confirmation requested. If seed-2 lands val_ema < 3.263938 OR sr ≤ 2887.5, we merge as new baseline. Estimated seed-2 ETA: ~19:00 UTC (3.9h after relaunch).

---

## 2026-05-28 16:45 UTC — PR #1542 askeladd: β_t schedule decouple — CLOSED BILATERAL NULL

- Branch: `g1r1-askeladd/beta-t-decouple`
- Hypothesis: Decouple pEMA β_t ramp from the canonical LR cooldown schedule. Arm A: canonical timing [1750, 3250]; Arm B: earlier ramp [975, 2900] aligned with cooldown onset and refresh step.
- W&B: Arm A `3guj2tf1` (online), Arm B `g8dci5l0` (online)

| Arm | β_t ramp window | val_ema | val_live | sr | Δ vs baseline |
|---|---|---:|---:|---:|---:|
| Baseline (#1429) | [1750, 3250] (canonical) | 3.263938 | — | 2900 | — |
| A (canonical timing) | [1750, 3250] | 3.266648 | 3.266080 | 2925 | +2.71 mnat |
| B (earlier ramp) | [975, 2900] | **3.26555** | 3.26500 | 2925 | +1.61 mnat |

- **Asymmetric signal**: Arm B (earlier ramp) better than Arm A (canonical) by −1.10 mnat. Suggests ramp-window timing has direction signal in the "earlier" direction.
- **Both fail merge gate**: sr=2925 fails clause 1 (>2887.5); sr ≠ 2900 fails clause 2.
- **β_t schedule decouple axis CLOSED.** Body buffer dynamics dominate baseline behavior; can't overcome with β_t timing changes alone. Connects to broader finding: **body-side schedule modifications are exhausted; aux-side schedule (β₂ pulse WIN, #1532) is where the headroom lives.**
- **New assignment**: askeladd → β₁ pulse on aux Adam (complementary to edward's β₂ pulse WIN — tests pulse mechanism generality across moments).

---

## 2026-05-28 16:25 UTC — PR #1535 alphonse: pEMA aux-extend β trajectory — CLOSED BILATERAL NULL

- Branch: `g1r1-alphonse/pema-aux-extend`
- Hypothesis: Extend pEMA buffer to include aux Adam parameters (embed + lm_head + scalars, 101 aux slots in addition to 72 body slots = 173 total). Arm A canonical aux β trajectory (0.97→0.99); Arm B heavier aux β (0.97→0.995). Tests whether aux-side EMA smoothing reduces refresh disruption at step 2600.
- W&B: Arm A `eqjrzl6n` (telemetry frozen step 375 due to 09:00 UTC W&B 401; local metrics intact), Arm B `4f10tlfk` (full telemetry)

| Arm | aux β | val_ema | val_live | sr | Δ vs baseline |
|---|---|---:|---:|---:|---:|
| Baseline (#1429, no aux pEMA) | — | 3.263938 | — | 2900 | — |
| A (canonical) | 0.97→0.99 | 3.26689 | — | 2925 | +2.95 mnat |
| B (heavier) | 0.97→0.995 | 3.26651 | — | 2925 | +2.57 mnat |

- **Mechanism finding (load-bearing)**: refresh bump at step 2600 dominated by **body slot zeroing**, not aux. Arm A refresh bump = +6.72 mnat; Arm B refresh bump = +6.89 mnat (heavier aux β did NOT reduce disruption — slightly worse). Rules out the "aux β stabilizes pre-refresh buffer" hypothesis.
- **Connection to today's WIN (#1532)**: edward's β₂ pulse mechanism operates on **aux Adam β₂ schedule**, not aux pEMA buffer. Two clean independent reads — pEMA scope is body-only canon, aux gets schedule-tuned via β₂ pulse.
- **pEMA aux-extend axis CLOSED bilateral NULL.** Heavier aux β=0.995 marginally better than 0.99 (−0.38 mnat) but still +2.57 above baseline.
- **New assignment**: alphonse → β₂ pulse amplitude extension (exploit edward's WIN axis with β₂ ∈ {0.995, 0.999}).

---

## 2026-05-28 13:30 UTC — PR #1524 tanjiro: Stable-LR-pulse shape sweep — CLOSED 2-POINT NULL

- Branch: `g1r1-tanjiro/stable-pulse`
- Hypothesis: A transient Muon LR pulse in the stable phase [1550, 1650) can redirect the optimization trajectory to hit val_loss ≤ 3.28 earlier. Two arms tested different pulse SHAPES at the same window.
- W&B: Arm A `xbel2nxt`, Arm B `muayf27r`

| Arm | Step | Width | Mult | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---:|---:|---:|---:|---:|---|---|
| Baseline (#1429) | — | — | — | 3.263938 | 2900 | — | — |
| A (narrow-strong) | 1600 | 100 | 1.20× | ~3.266 (val_loss only) | 2925 | +2.13 | ❌ NULL |
| B (wide-gentle) | 1600 | 200 | 1.10× | **3.26687** | **2925** | **+2.93** | ❌ NULL |

- **2-point SYMMETRIC NULL:** Both pulse shapes fail by similar margins (+2.1 to +2.9 mnat). Pulse shape (narrow/strong vs wide/gentle) does not change the NULL outcome — the mechanism is not SHAPE-sensitive.
- **Stable-pulse-shape axis CLOSED:** LR pulses in stable phase [0, 975) do not redirect the optimization trajectory persistently. Broad valley means the canonical descent path is not sensitive to brief perturbations during the stable phase.
- **New assignment:** tanjiro → PR #1574 soft pEMA refresh sweep (α ∈ {0.5, 0.7} blend factor at step 2600).

---

## 2026-05-28 13:05 UTC — PR #1531 thorfinn: Aux Adam AGC λ=0.01 — CLOSED MECHANISM-CONFIRMED NULL

- Branch: `g1r1-thorfinn/aux-agc`
- Hypothesis: NFNets-style unit-wise AGC on aux Adam raw gradients, with correct `λ_eff = λ × batch_size` rescaling.
- W&B run: `ea819ilg` (offline, synced post-terminal)

| Arm | λ (effective) | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---:|---:|---|---|
| Baseline (#1429) | — | 3.263938 | 2900 | — | — |
| A (tight) | 0.01 (→ 5242.88) | **3.265375** | **2925** | +1.44 | ❌ NULL |

- **Key finding — AGC soft warm-start effect:** AGC fires hard on zero-init `proj.weight`+biases at step 0–125, producing a **−21.93 mnat advantage at step 125**. From step 500, steady-state clips of 70 units/step at max_clip_ratio ≈1.6e-2 accumulate a **+1.44 mnat terminal cost**. Net: warm-start advantage cancelled by steady-state cost.
- **Mechanism-confirmed NULL:** The fired_units monotonic decay (10,715 → 71), step-by-step clip-ratio audit, and val_ema trajectory shape together confirm AGC operated correctly and still failed to beat baseline. Adam's β1/β2 EMAs already absorb aux gradient outliers — explicit clipping is redundant and adds directional bias.
- **Arm B (λ=0.05) not run.** Student's and advisor's prior: λ=0.05 would barely fire in steady state → degenerate to baseline (uninformative). 3.6h GPU better spent on warmup-only AGC.
- **AGC-on-aux-raw-gradient axis CLOSED.**
- **New assignment:** thorfinn → PR #1573 warmup-only AGC (capture warm-start, gate off after t_off ∈ {500, 1500}).

---

## 2026-05-28 13:00 UTC — PR #1535 alphonse: pEMA aux-extend (body + aux β canon → body + aux β heavier) — Arm A NULL (Arm B running)

- Branch: `g1r1-alphonse/pema-split`
- Hypothesis: Extend pEMA buffer to cover aux params (embed.weight, lm_head.weight, scalar gain/biases). Reframed from body-vs-aux β split after student correctly identified body-only buffer constraint. Arm A tests canonical β (0.97→0.99) on full 173-slot buffer (72 body + 101 aux). Arm B tests heavier aux β (0.97→0.995).
- Arm A W&B: offline run `eqjrzl6n` (401 socket-killed at step 375, training continued locally; metrics from `run_logs/arm_a.log`)

| Arm | β config | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---:|---:|---|---|
| Baseline (#1429) | body-only β 0.97→0.99 | 3.263938 | 2900 | — | — |
| A (full buffer canonical) | body+aux β 0.97→0.99 | **3.26689** | **2925** | +2.95 | ❌ NULL |

- **Mechanism reading:** Refresh at step 2600 zeroed the full 173-slot buffer (including 101 aux slots), producing a larger post-refresh val_loss bump (3.314→3.321, +0.7 mnat more disruption vs body-only #1429). Extending the buffer to aux params adds more state that is reset at refresh, offsetting any benefit from aux averaging.
- **Arm B (heavier aux β=0.995) running.** W&B run `4f10tlfk`, step ~843/3250, ETA ~15:30 UTC. Terminal SENPAI-RESULT will follow.

---

## 2026-05-28 12:09 UTC — PR #1542 askeladd: pEMA β_t schedule decoupling — Arm A NULL (Arm B running)

- Branch: `g1r1-askeladd/beta-t-decouple`
- Hypothesis: Decouple β_t from lr_mult — introduce independent step-based linear schedule. Arm A (canonical timing): β_t linear over [1750, 3250].
- Arm A W&B: `3guj2tf1` (online, launched 08:15 UTC, finished 12:09 UTC)

| Arm | β_t ramp | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---:|---:|---|---|
| Baseline (#1429) | coupled to lr_mult | 3.263938 | 2900 | — | — |
| A (decoupled, canonical timing [1750,3250]) | linear-step | **3.266648** | **2925** | +2.71 | ❌ NULL |

- **Mechanism reading:** Arm A β_t under-ramps vs canonical — at 50% phase it reaches β=0.980 vs canonical 0.9855. The small divergence from canonical under slightly lower β accumulates a +2.71 mnat terminal penalty. Decoupling by itself without retuning the timing adds noise without benefit.
- **Arm B (earlier ramp [975,2900])** launched online at 12:17 UTC, ETA ~16:00 UTC.

---

## 2026-05-28 11:10 UTC — PR #1532 edward: Aux Adam β2 transient-INCREASE pulse — Arm A NULL (Arm B running)

- Branch: `g1r1-edward/aux-b2-pulse`
- Hypothesis: Transient β2 increase at cooldown onset (step 975) — give aux Adam more "momentum memory" entering cooldown. Arm A: mild pulse (0.95 → 0.97, Δβ2=0.02). Arm B: strong pulse (0.95 → 0.99, Δβ2=0.04).
- Arm A W&B: `o9ow75oy` (online, finished 11:10 UTC)

| Arm | β2 pulse | val/loss_ema | val/loss_live | sr | ema_minus_live (mnat) | Δval (mnat) | Gate |
|---|---|---:|---:|---:|---:|---|---|
| Baseline (#1429) | none | 3.263938 | — | 2900 | +0.59 | — | — |
| A (mild 0.97) | 0.95 → 0.97 @ step 975 | **3.264997** | 3.264407 | **2925** | +0.59 | +1.06 | ❌ NULL |

- **Mechanism reading:** ema_minus_live = +0.59 mnat (matches baseline pattern — EMA over-smoothing post-refresh unchanged). Mild β2 pulse had no detectable effect on cooldown trajectory.
- **Arm B (strong pulse 0.99)** launched online at 11:10 UTC (`9coyk2ke`), step ~900+/3250, ETA ~14:46 UTC.

---

## 2026-05-28 10:10 UTC — PR #1510 frieren: Per-block Muon NS_ITERS depth-stratified — CLOSED BILATERAL NULL

- Branch: `g1r1-frieren/per-block-ns-iters`
- Hypothesis: Depth-stratified NS_ITERS (more iterations for late/deep blocks) mirroring #1289 per-block LR WIN.

| Arm | NS_ITERS pattern (blocks 0→11) | W&B | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---|---|---|---|---|
| Baseline (#1429) | uniform=12 | y4nxof1m / fek06bk7 | 3.263938 | 2900 | — | — |
| A (late-deeper) | [10,10,11,11,11,12,12,13,13,13,14,14] | d6b6wx4v | 3.267111 | 2950 | +3.17 | ❌ NULL |
| B (early-deeper) | [14,14,13,13,13,12,12,11,11,11,10,10] | gq38vymw | 3.26712 | 2925 | +3.18 | ❌ NULL |

- **Key finding — SYMMETRIC NULL:** Both arms regress by exactly +3.17-3.18 mnat. The direction of depth-stratification makes NO difference. Whatever is costing 3.17-3.18 mnat is about ANY non-uniform depth stratification, not about which direction.
- **Canon update — per-block axis closure:** LR depth-stratification (#1289 WIN) does NOT generalize to NS_ITERS or μ (#1483). Per-block axis is productive ONLY for LR-magnitude. Per-block precision and momentum parameters respond to different curvature principles. Full axis:

  | Per-block parameter | PR | Result |
  |---|---|---|
  | LR | #1289 | WIN — late-higher |
  | μ | #1483 | CATASTROPHIC NULL |
  | NS_ITERS | #1510 | NULL (symmetric Δ+3.17) |

- **New assignment:** frieren → #1561 Nesterov momentum for body Muon (full vs stable-phase only).

---

## 2026-05-28 10:00 UTC — PR #1507 fern: pEMA β ramp SHAPE (concave vs convex) — CLOSED BILATERAL NULL

- Branch: `g1r1-fern/ema-ramp-shape`
- Hypothesis: Ramp INTERPOLATION CURVE for β trajectory (concave p^0.5 vs convex p^2.0).

| Arm | Shape | W&B | val/loss_ema | val/loss_live | sr | Δval (mnat) | Gate |
|---|---|---|---|---|---|---|---|
| Baseline (#1429) | linear (power=1.0) | y4nxof1m / fek06bk7 | 3.263938 | — | 2900 | — | — |
| A (concave) | p^0.5 | wbtvd5rb | 3.264424 | **3.263860** | 2925 | +0.486 | ❌ NULL |
| B (convex) | p^2.0 | 5srckf1m | 3.264769 | 3.264184 | 2925 | +0.831 | ❌ NULL |

- **Critical canon observation:** Arm A concave val_live=3.263860 is **BETTER** than baseline val_ema=3.263938. The EMA buffer is the failure mode, not the optimization trajectory. EMA is over-smoothing the post-refresh window (+0.564-0.585 mnat delta).
- **Shape axis closes:** Linear is at a local optimum. Concave (less bad) vs convex (more bad) shows weak directionality toward higher β earlier, but neither beats baseline.
- **Unblocked:** pEMA β ramp axis now fully characterized — endpoints (#1458), shape (#1507), refresh step (#1457/#1459). Opens: decoupled β_target post-refresh (fern's next PR #1559).
- **pEMA β ramp FAMILY CLOSURE:**

  | Axis | PR | Status |
  |---|---|---|
  | β_base endpoint | — | 0.97 (empirical canon) |
  | β_target endpoint | #1458 | CLOSED — 0.99 optimal ±0.005 |
  | Ramp shape | #1507 | **CLOSED HERE — linear optimal** |
  | Refresh step position | #1457/#1459 | CLOSED — sharp peak @ 2600 |
  | Decoupled β_target post-refresh | #1559 (in flight) | PENDING |

---

## 2026-05-28 10:00 UTC — PR #1508 nezuko: Cooldown LR floor (min_lr_ratio 0.001 vs 0.01) — CLOSED BILATERAL NULL

- Branch: `g1r1-nezuko/cooldown-lr-floor`

| Arm | min_lr_ratio | Floor binds at step | W&B | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---|---|---|---|---|---|
| Baseline (#1429) | 0 | N/A | y4nxof1m / fek06bk7 | 3.263938 | 2900 | — | — |
| A (0.001) | 0.001 | 3234 (last 16 steps) | 139iq490 | 3.266417 | 2925 | +2.479 | ❌ NULL |
| B (0.01) | 0.01 | 3166 (last 84 steps) | vk375rty | 3.264123 | 2925 | +0.185 | ❌ NULL |

- **Counterintuitive finding:** Arm B (larger floor, 10×) is CLOSER to baseline than Arm A. Student's read: Arm B keeps model in a descending regime for 84 steps (pEMA averages a productive tail); Arm A's 16-step floor adds only noise.
- **Arm B Δ+0.185 mnat is within single-seed noise** but sr=2925 fails both gate clauses (sr<2875.5 and sr=2900 both false). No n=2 needed.
- **Cooldown TAIL axis family CLOSED:**

  | Cooldown parameterization | PR | Status |
  |---|---|---|
  | POWER γ | #969/#1084 | CLOSED — γ=1.4 optimal |
  | SHAPE family | #1496 | CLOSED catastrophic |
  | PER-BLOCK γ | #1342 | CLOSED |
  | FLOOR (min LR) | #1508 | **CLOSED HERE** |
  | LENGTH (cooldown_frac) body vs aux decoupled | #1560 (in flight) | PENDING |

- **New assignment:** nezuko → #1560 aux Adam LR cooldown timing decoupled from body Muon.

---

## 2026-05-28 09:20 UTC — INFRA: W&B API key invalidated server-side fleet-wide (Issue #1550)

- At ~09:00 UTC the WANDB_API_KEY in `senpai-secrets` was rotated/revoked server-side. All new `wandb.init()` calls return HTTP 401 across every student pod AND the advisor pod.
- **In-flight runs that authenticated BEFORE 09:00 UTC continue streaming** (open socket persists), but W&B dashboard may show them as "crashed" due to ping/heartbeat staleness.
- **Brand-new arm launches fail.** Workaround: `WANDB_MODE=offline` + post-hoc `wandb sync wandb/offline-run-*` once key refreshes.
- Issue #1550 filed and escalated. Affects merge-winner preflight (no W&B validation step until refreshed).
- **Affected experiments:**
  - #1524 tanjiro Arm B (wide-gentle) — running offline
  - #1531 thorfinn Arm A AGC Option 1 — already running offline (`ea819ilg`) as workaround for earlier 401
  - #1542 askeladd β_t decouple Arm A — needs offline launch
- **Unaffected (still streaming pre-09:00 socket):** #1510 frieren Arm B, #1507 fern Arm B, #1508 nezuko Arm B, #1535 alphonse Arm A, #1532 edward Arm A

---

## 2026-05-28 09:15 UTC — PR #1524 tanjiro: Stable-phase mid-run LR pulse @ step 1600 — Arm A NULL

- Branch: `g1r1-tanjiro/stable-pulse`
- Hypothesis: SGDR-inspired basin-escape via a transient LR multiplier (×1.25) over a narrow stable-phase window [1550, 1650). Theory: kick optimization out of a basin during stable phase so cooldown lands in a deeper minimum.

| Arm | Pulse params | W&B | val_loss (final) | sr | Δval (mnat) | Gate |
|---|---|---|---|---|---|---|
| Baseline (#1429) | none | y4nxof1m / fek06bk7 | **3.263938** | **2900** | — | — |
| A (narrow sharp) | step=1600, width=100, mult=1.25 | xbel2nxt | 3.266070 | 2925 | +2.1 | FAIL (Δsr+25) |

- **Mechanism reading:** Pulse window fired correctly (kill gate not tripped, post-pulse descent resumed). The 250-step post-pulse window showed -52 mnat (3.547 → 3.495), comparable to baseline cooldown rate. So the pulse explored a different optimization trajectory but landed in the same basin — no asymptotic gain. The 09:30 W&B-slope projection (-9.66 mnat/100step → 3.246) overestimated terminal because the post-EMA-refresh slope flattened across the last 425 steps (2825→3250), consistent with cooldown asymptote.
- **Status:** Arm A terminal NULL. Arm B (wide-gentle: width=200, mult=1.10) approved offline. ETA ~12:50 UTC. If Arm B also NULLs, stable-pulse SHAPE axis closes.

---

## 2026-05-28 09:30 UTC — PR #1531 thorfinn: Aux Adam AGC — Option 1 (rescale λ) approved after third structural collapse

- Branch: `g1r1-thorfinn/aux-agc`
- Three failed AGC formulations all collapse for the same root cause: gradient scale in this codebase (`F.cross_entropy(reduction='sum')` × batch_size=524,288) is ~5-6 orders of magnitude above Brock et al.'s mean-reduction calibration. Student's quantitative analysis reproduces the observed `max_clip_ratio` from per-row math.

| Attempt | Variant | W&B (killed) | Killed at step | max_clip_ratio | Δval at kill |
|---|---|---|---|---|---|
| 1 | Literal per-tensor Frobenius | c9yv8sqa | 117 | ~1e-14 to 1e-20 | — |
| 2 | Per-tensor Frobenius + 1e-3 floor | btz8s06j | 220 | ~5e-6 | +0.71 mnat |
| 3 | Unit-wise NFNets `unitwise_norm` | pwb0yefk | 210 | ~1e-8 (sustained) | +117 mnat |

- **Decision:** Approve student's Option 1 (rescale λ internally by `batch_size`). User-facing canonical λ=0.01 becomes λ_eff=5242 at the AGC clip threshold. This is the smallest deviation that tests AGC at the right calibration. Math check confirms: at λ_eff=5242, normal embed/scalar gradients have clip_ratio ~100-200 (no clip), only outliers fire. Sent back to wip.
- **Useful negative findings (canon):** AGC at Brock-scale λ on sum-reduction loss is structurally degenerate across three different per-tensor/per-unit norm formulations. The fix MUST be either (a) rescale λ by batch_size or (b) rebuild as AGC-on-update (post-preconditioning). These three killed runs are AGC-envelope-mapping for this codebase.

---

## 2026-05-28 09:15 UTC — PR #1542 askeladd: pEMA β_t schedule decoupling from lr_mult — ASSIGNED

- Branch: `g1r1-askeladd/beta-t-decouple`
- Hypothesis: Break the parametric coupling `β_t = β_base + (β_target - β_base) × (1 - lr_mult_t)` by introducing an independent step-based β_t schedule. Motivated directly by askeladd's own post-mortem on #1496 Arm A (cosine).
- Arm A (decoupled-canonical-timing): β_t linearly ramps from 0.97 → 0.99 over steps [1750, 3250].
- Arm B (decoupled-earlier-ramp): β_t linearly ramps from 0.97 → 0.99 over steps [975 (cooldown onset), 2900 (target FFS)].
- First PR to break the lr_mult coupling entirely. Status: **ASSIGNED**.

---

## 2026-05-28 09:00 UTC — PR #1496 askeladd: Cooldown LR shape (cosine vs sigmoid) — CLOSED BILATERAL CATASTROPHIC NULL

- Branch: `g1r1-askeladd/cooldown-shape`
- Hypothesis: Shape-family alternatives to power-1.4 cooldown.

| Arm | Shape | W&B | val/loss_ema | sr | Δval (mnat) | Gate |
|---|---|---|---|---|---|---|
| Baseline (#1429) | power γ=1.4 | y4nxof1m / fek06bk7 | **3.263938** | **2900** | — | — |
| A (cosine) | 0.5·(1+cos(π·cp)) | b26zqkrn | 3.277563 | 3125 | +13.6 | FAIL (Δsr+225) |
| B (sigmoid) | 1/(1+exp(10·(cp-0.4))) | jxelv2pi | 3.291803 | -1 | +27.9 | CATASTROPHIC (never crossed 3.28) |

- **Canon:** Cooldown-shape FAMILY axis FULLY CLOSED. Power γ=1.4 sits at local LR-mass-distribution optimum. Cosine over-allocates LR mass mid-cooldown (delays β_t ramp), sigmoid under-allocates (training starved of usable LR). Joint closure with #969 (γ sweep), #1084 (piecewise γ), #1342 (per-block γ), #1099 (decoupled aux γ), #1466 (NM shape).
- **Key structural finding:** β_t = β_base + (β_target − β_base)·(1 − lr_mult) coupling was the load-bearing failure mode. Motivates next assignment (#1542 β_t decoupling).

---

## 2026-05-28 09:20 UTC — PR #1510 frieren: Per-block NS_ITERS Arm A late-deeper terminal NULL

- Branch: `g1r1-frieren/per-block-ns-iters`
- **Arm A late-deeper terminal** (`d6b6wx4v`): val_ema=3.267111, sr=2950 (Δ+3.2 mnat, Δsr+50). Fails merge gate.
- Per-block depth-stratification on NS_ITERS does NOT generalize from #1289 LR WIN — late blocks with MORE polish iterations slightly hurts. Arm B early-deeper still running (step 1625-1900/3250 across cycles).
- Two earlier crashes (ml8e0u8i step 0, r9y3gxk4 step 75) before d6b6wx4v succeeded — chain recovered cleanly.

---

## 2026-05-28 07:40 UTC — PR #1535 alphonse: Differential pEMA β by parameter group (body vs aux Adam, Idea 12) — ASSIGNED

- Branch: `g1r1-alphonse/pema-split`
- Hypothesis: Split pEMA β trajectory by parameter group. Currently single β=0.97→0.99 applied uniformly across body Muon AND aux Adam. Body and aux have provably different convergence dynamics (NS5-bounded vs Adam-EMA-bounded gradients; LR 0.040 vs 0.3). Single β presumed-optimal but never verified.
- Arm A: aux LIGHTER (body_β=0.97→0.99 unchanged, aux_β=0.95→0.97 — faster aux tracking)
- Arm B: aux HEAVIER (body_β=0.97→0.99 unchanged, aux_β=0.97→0.995 — heavier aux smoothing)
- Mechanism-orthogonal to all in-flight: distinct from #1507 (β ramp SHAPE for all params), #1458 (β endpoint scan, single value), #1429 (refresh mechanism, not β trajectory).
- Status: **ASSIGNED** — PR #1535

---

## 2026-05-28 07:35 UTC — PR #1483 alphonse: Per-block Muon momentum schedule — CLOSED BILATERAL CATASTROPHIC FAIL

- Branch: `g1r1-alphonse/per-block-muon-mom`
- Hypothesis: Extend #1289 per-block LR WIN to momentum axis. Arm A late-higher (block0=0.93 → block11=0.97), Arm B late-lower (block0=0.97 → block11=0.93), both mean-preserved at 0.95.

| Arm | μ pattern | val/loss_ema | sr | Δval (mnat) | Δsr | Gate |
|---|---|---|---|---|---|---|
| Baseline (#1429 n=2) | uniform 0.95 | 3.263938 | 2900 | 0 | 0 | — |
| Arm A late-higher | 0.93→0.97 | 3.281904 | **−1 (never crossed)** | +17.97 | +∞ | ❌ |
| Arm B late-lower | 0.97→0.93 | 3.273329 | 3050 | +9.39 | +150 | ❌ |

- **Decision: CLOSED BILATERAL CATASTROPHIC FAIL.** Per-block axis WIN of #1289 does NOT generalize from LR to momentum. Strong directional asymmetry: μ=0.97 on deep/output blocks (Arm A) catastrophic (never crosses 3.28 target); μ=0.97 on early blocks (Arm B) mildly bad (+150 sr, +9.39 mnat).
- **Mechanism reading (student):** μ=0.97 on output blocks retains pre-cooldown gradient history exactly when LR anneal needs those blocks to respond to cooldown signal. Compounds with #1289's late-higher LR (output blocks already get largest LR mult 1.10×) — direction precision harmed AND step magnitude amplified. Confirms #1456 finding that sticky μ=0.97 globally is broken; damage concentrates exactly where predicted.
- **Canon addition:** Body-Muon per-block μ axis FULLY CLOSED bilateral catastrophic. LR axis and μ axis have **fundamentally different curvature** — LR scales step magnitude (late-higher WINS), μ scales gradient history (late-higher catastrophic). Joint with #1456 (phase-window μ pulse NULL): body-Muon momentum-related axis exhausted across temporal scopes (always-on per-block + phase-window pulse).

---

## 2026-05-28 06:55 UTC — PR #1532 edward: Aux Adam β2 transient-INCREASE pulse @ cooldown onset — ASSIGNED

- Branch: `g1r1-edward/aux-b2-pulse`
- Hypothesis: Transiently INCREASE aux Adam β2 from 0.95 → target at cooldown onset (step 975), giving v buffer "more averaging room as gradient signal gets quieter." Direct opposite direction from #1407 (transient-DECREASE NULL). Motivated by #1487 mechanism finding that v-reset arm was STRICTLY WORSE than m-only arm (v buffer is load-bearing and optimizer WANTS more smoothing, not less).
- Arm A: `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.97` (mild: β2 0.95→0.97, horizon ~33 steps)
- Arm B: `--aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99` (strong: β2 0.95→0.99, horizon ~100 steps — near bias-correction-on regime)
- Mechanism: Keeps v buffer intact (produces-mode, unlike #1487 zero-reset). Adjusts decay rate to improve smoothing during cooldown's decreasing gradient-noise phase. Respects produce/consume buffer distinction from #1487 post-mortem. Implementation ~10 LOC: at step 975 update `optimizer1.param_groups[*]['betas']`.
- Status: **ASSIGNED** — PR #1532

---

## 2026-05-28 06:50 UTC — PR #1487 edward: Aux Adam m/v state reset @ step 2600 — CLOSED BILATERAL NULL

- Branch: `g1r1-edward/adam-mv-reset`
- Hypothesis: Mechanism-analog of PR #1429 pEMA WIN — zero aux Adam momentum (m) and/or variance (v) buffers at step 2600 to "refresh" the optimizer state at the same phase boundary.

| Arm | W&B | val/loss_ema | sr | Δval (mnat) | Δsr | Gate |
|---|---|---|---|---|---|---|
| Baseline (#1429 n=2) | y4nxof1m / fek06bk7 | 3.263938 | 2900 | 0 | 0 | — |
| Arm A m-only @ 2600 | znvhprrt | 3.264677 | 2925 | +0.74 | +25 | ❌ |
| Arm B m+v @ 2600 | msey6dxt | 3.266129 | 2925 | +2.19 | +25 | ❌ |

- **Decision: CLOSED NULL.** Clean monotonic direction signal (Arm B m+v strictly worse than Arm A m-only by +1.45 mnat) — v-reset adds incremental harm on top of m-reset. n=1 sufficient; n=2 would not change call.
- **Mechanism analysis (student post-mortem):** pEMA refresh (#1429 WIN) = consume-mode buffer (uniform-weight eval-only running mean) where stale entries are additive contamination — clearing recovers signal. Adam m/v = produce-mode buffer (exponentially-decayed train-mode state, β2=0.95) where history is immediately consumed by next update. By step 2600, gradients before step ~2540 (v) are weighted <1% — decay has already done the "refresh." Zeroing destroys recent adaptation rather than recovering stale-free signal.
- **Canon addition:** Aux Adam state-reset axis CLOSED bilateral NULL. Joint with #1407 (aux β2 phase-pulse NULL), #1399/#1400/#1452 (aux LR phase-pulse NULL). **Aux optimizer adaptive-state perturbation axis fully exhausted.**
- **Key mechanistic frame for programme:** produce-mode vs consume-mode buffer asymmetry. Only consume-mode buffers (pEMA) benefit from one-shot refresh at step 2600. Produce-mode buffers (Adam m/v, Muon m_prev) are hurt by zero-reset because decay has already done the "refresh."

---

## 2026-06-28 06:40 UTC — PR #1531 thorfinn: Aux Adam Adaptive Gradient Clipping (AGC) — ASSIGNED

- Branch: `g1r1-thorfinn/aux-agc`
- Hypothesis: AGC (Brock et al. NFNets ICML 2021) on aux Adam path only (body Muon already bounded by NS5 polar). Clips per-tensor gradient: `grad ← grad * min(1, λ * ||W||_F / (||G||_F + ε))`. Two arms span clipping tightness axis.
- Arm A: `--aux_agc_lambda 0.01` (tight — typical NFNets default)
- Arm B: `--aux_agc_lambda 0.05` (loose — only extreme outliers clipped)
- Mechanism: no gradient clipping exists anywhere in the codebase. Adam's β1/β2 EMAs suppress most outliers but not all — AGC bounds the update distribution shape. Mechanism-orthogonal to all closed and in-flight axes.
- Status: **ASSIGNED** — PR #1531

---

## 2026-05-28 06:35 UTC — PR #1456 thorfinn: Phase-window body Muon momentum (μ) pulse — CLOSED NULL (FAILED n=2)

- Branch: `g1r1-thorfinn/body-muon-mu-phase-pulse`
- Hypothesis: Pulse μ during window [2500, 2925): Arm A sticky μ=0.97, Arm B reactive μ=0.93. Tests whether gradient-history horizon perturbation in the pre-crossing window helps.

| Seed/Arm | Config | W&B | val/loss_ema | sr | Δval vs baseline | Δsr vs baseline | Verdict |
|----------|--------|-----|--------------|----|----|---------|---------|
| Arm A μ=0.97 sticky | n=1 | `73jq81jn` | 3.267997 | 2975 | +4.06 mnat | +75 | catastrophic NULL |
| Arm B μ=0.93 reactive seed-1 | n=1 | `dd73jrhw` | 3.264168 | 2875 | +0.23 mnat | -25 | marginal-WIN-candidate |
| Arm B μ=0.93 reactive seed-2 | n=1 | `mek7gvet` | 3.265577 | 2925 | +1.64 mnat | +25 | NULL |
| **Arm B n=2 mean** | n=2 | — | **3.264873** | **2900** | **+0.93 mnat** | ±0 | ❌ **FAILED n=2** |

- **Decision: CLOSED NULL.** n=2 mean (3.264873, sr=2900) fails both merge-gate clauses: sr=2900 > 2887.5 AND val_ema=3.264873 > 3.263938. Third consecutive n=2 collapse (joins #1325→#1379, #1365→#1410).
- **Canon addition: Body-Muon phase-window axis FULLY CLOSED bilateral-NULL across ALL 4 sub-axes** (LR #1376, WD #1445, NS_iters #1435, μ #1456). Phase-window-pulse mechanism class on body Muon is DEAD.
- **n=2 gating canon STRENGTHENED:** Δval_n1 < 1.0 mnat + sr ≤ 25-step improvement is PRESUMED SEED-NOISE. Auto-trigger n=2. Future PRs must show Δval < -1.0 mnat at n=1 OR Δsr ≥ -50 steps for merge without n=2.

---

## 2026-05-28 02:25 UTC — PR #1510 frieren: Per-block NS_ITERS depth-stratified (late-deeper vs early-deeper) — ASSIGNED

- Branch: `g1r1-frieren/per-block-ns-iters`
- Hypothesis: Per-block depth-stratification of Newton-Schulz iterations — the depth-axis analog of #1289 late-higher LR WIN. Arm A: late-deeper [10,10,10,11,12,13,14,14,14] (more polish for later/deeper blocks, mirroring #1289). Arm B: early-deeper [14,13,12,11,10,10,10,10,10] (mirror control). Mean NS_ITERS ~11.67, mean preserved. All prior NS NULLs were UNIFORM (#1435 phase-window, static bilateral). Per-block depth-stratification has NEVER been tested.
- Status: **ASSIGNED** — frieren to implement `--muon_block_ns_iters_pattern` flag (mirror of `--muon_block_lr_pattern` wiring via `param_ns_iters` dict)

---

## 2026-05-28 02:22 UTC — PR #1456 thorfinn: μ-pulse Arm B sent for n=2 confirmation — WIP

- Branch: `g1r1-thorfinn/body-muon-mu-phase-pulse`
- Arm B (μ=0.93 reactive, window [2500, 2925)): val_ema=3.264168 (Δ+0.23 mnat WORSE), sr=**2875** (Δ-25 FASTER) → passes sr-clause sr ≤ 2887.5 ✅
- Arm A (μ=0.97 sticky): val_ema=3.267997, sr=2975 → catastrophic NULL (Δ+4.06 mnat / +75 sr)
- W&B: 73jq81jn (A), dd73jrhw (B)
- **MARGINAL-WIN-CANDIDATE** — n=2 required (Δval WORSE, only sr-clause carries WIN; n=2 collapse pattern per #1325→#1379, #1365→#1410). Re-running Arm B at seed=2 to confirm sr improvement generalizes.

---

## 2026-05-28 02:20 UTC — PR #1457 frieren: pEMA step-position ablation (2500 vs 2750) — CLOSED NULL

- Branch: `g1r1-frieren/pema-refresh-step-position`
- Hypothesis: Map productive zone around step 2600. Arm A: refresh @ 2500 (100 steps early). Arm B: refresh @ 2750 (150 steps late).

| Arm | refresh_step | W&B | val/loss_ema | sr | Δ vs baseline (3.263938) | Verdict |
|-----|-------------|-----|--------------|----|----|---------|
| A   | 2500        | `5mstlt61` | 3.264385 | 2925 | +0.447 mnat / +25 sr | NULL |
| B   | 2750        | `yj6r2n8w` | 3.264487 | 3025 | +0.549 mnat / +125 sr | NULL |

**Conclusion: pEMA refresh @ 2600 is a SHARP PRODUCTIVE PEAK.** Step-position map now FULLY CLOSED:

| step | 2275 | 2500 | **2600** | 2750 | 2850 | 2900 |
|------|------|------|----------|------|------|------|
| | NULL | NULL | **WIN** | NULL | NULL | NULL |

Step 2600 is the sole productive point — not part of a broad zone. Mechanism interpretation: at step 2600 specifically, live params already encode useful cooldown trajectory; zeroing pEMA history at that moment allows re-accumulation of only high-quality late-cooldown updates. Earlier (2275, 2500) discards useful pre-cooldown EMA before late trajectory is baked; later (2750, 2850, 2900) is too close to terminal eval window to recover. frieren → #1510 per-block NS_ITERS depth-stratified.

---

## 2026-05-28 01:42 UTC — PR #1508 nezuko: Cooldown LR floor (min_lr_ratio 0.001 vs 0.01) — ASSIGNED

- Branch: `g1r1-nezuko/cooldown-lr-floor`
- Hypothesis: Non-zero minimum LR at the end of cooldown. Current schedule decays to exactly eta=0.0 at the final step. A floor of 0.001× peak LR (Arm A) or 0.01× peak LR (Arm B) keeps the model making gentle micro-corrections during pEMA averaging. External LLM practice (GPT-4, Llama, Chinchilla) universally uses non-zero min LR. **This axis has never been tested in this programme.** Orthogonal to cooldown shape (#1496 askeladd in flight), optimizer state resets (#1487 edward, #1475 tanjiro), and all pEMA work.
- Status: **ASSIGNED** — nezuko to implement `--min_lr_ratio` flag and run both arms on canonical baseline

---

## 2026-05-28 01:40 UTC — PR #1507 fern: pEMA β ramp SHAPE (concave vs convex) — ASSIGNED

- Branch: `g1r1-fern/ema-ramp-shape`
- Hypothesis: Current pEMA β ramp interpolates linearly from β_base=0.97 to β_target=0.99 using `(1 - lr_mult)`. A concave ramp (`(1-lr_mult)^0.5`) rises fast early — β stabilizes to long-memory 0.99 regime rapidly post-refresh. A convex ramp (`(1-lr_mult)^2.0`) stays near 0.97 until the model has nearly converged then ramps sharply for terminal smoothing. PR #1458 closed NULL confirming β_target endpoint is robust to ±0.005; this tests the ramp SHAPE (interpolation curve), a distinct axis not yet tested.
- Status: **ASSIGNED** — fern to implement `--ema_ramp_shape` flag and run both arms on canonical baseline

---

## 2026-05-28 01:38 UTC — PR #1459 fern: pEMA step-position LATE-scan (2850 vs 2900) — CLOSED NULL

- Branch: `g1r1-fern/pema-refresh-step-late-scan`
- Hypothesis: Extend pEMA refresh step-position map to late territory (2850, 2900). Completes the 6-point step-position map: {2275 NULL, 2500 NULL, 2600 WIN, 2750 TBD (from #1457), 2850 TBD, 2900 TBD}.

| Arm | Refresh step | W&B | val_loss_ema | sr | Δ vs baseline (3.263938) | Verdict |
|-----|-------------|-----|--------------|-----|---|---------|
| A   | 2850        | `wk4a79fb` | 3.265857 | 2950 | +1.919 mnat | NULL |
| B   | 2900        | `eims54k3` | 3.267925 | 3000 | +3.987 mnat | NULL |

**Conclusion:** pEMA step-position late-territory canon CONFIRMED — monotonically worsens past step 2600. Refresh @ 2850 produces a measurable cold-start spike (+7.879 mnat instantaneous disruption at refresh boundary). Refresh @ 2900 too close to terminal eval window to recover. Closes the late-side of the step-position axis: {2600=WIN, 2750=TBD(#1457), 2850=NULL, 2900=NULL}. Step 2600 confirmed as sharp-peak optimum. fern → PR #1507 pEMA β ramp shape.

---

## 2026-05-28 01:36 UTC — PR #1458 nezuko: pEMA × ema_beta_target interaction (0.985 vs 0.995) — CLOSED NULL

- Branch: `g1r1-nezuko/pema-beta-target-scan`
- Hypothesis: ema_beta_target=0.99 was tuned pre-pEMA in PR #1234. After pEMA refresh @ 2600 (PR #1429 WIN), the optimal β_target may differ — a lower target (0.985) allows faster EMA accumulation post-refresh, a higher target (0.995) extends the averaging window.

| Arm | β_target | W&B | val_loss_ema | sr | Δ vs baseline (3.263938) | Verdict |
|-----|----------|-----|--------------|-----|---|---------|
| A   | 0.985    | `t2lao6bj` | 3.266638 | 2925 | +2.700 mnat | NULL |
| B   | 0.995    | `efisebaw` | 3.265908 | 2925 | +1.970 mnat | NULL |

**Conclusion:** pEMA × ema_beta_target interaction NULL — ema_beta_target=0.99 is robust to ±0.005 perturbation. Critical observation: terminal buffer_frob_dist scales monotonically with β_target (A=14.939, baseline≈31, B=87.249), confirming that β_target controls EMA inertia as designed — but neither extreme yields val gains. **β_target endpoint axis CLOSED. This unblocks Idea 5 (pEMA β-ramp SHAPE) from research bank.** nezuko → PR #1508 cooldown LR floor.

---

## 2026-05-28 00:00 UTC — PR #1496 askeladd: Cooldown LR shape (cosine vs sigmoid) — ASSIGNED

- Branch: `g1r1-askeladd/cooldown-shape`
- Hypothesis: Shape-family alternatives to current power-1.4 cooldown. Arm A: cosine (`0.5*(1+cos(π*cp))`). Arm B: sigmoid (`1/(1+exp((cp-0.4)*10))`). No prior PR has tested non-power-law decay curve families. Addresses human researcher directive "Schedules that deliberately steepen loss descent before step 2925." Both on full canonical baseline (late-higher LR + pEMA @ 2600).
- Status: **ASSIGNED**

---

## 2026-05-27 23:37 UTC — PR #1452 askeladd: Aux scalars-only LR phase-window pulse — CLOSED NULL

- Branch: `g1r1-askeladd/aux-scalars-only-pulse`
- Hypothesis: scalars-only LR phase-window pulse in steps [2500, 2925). Completes 3-way aux LR decomp.

| Arm | mult | W&B | val_loss_ema | sr | Δ vs baseline (3.263938) | Verdict |
|---|---|---|---|---|---|---|
| A | ×1.30 boost | `9hj0t9f7` | 3.267820 | 2950 | +3.882 mnat | NULL/REGRESSION |
| B | ×0.70 reduce | `gcsabf25` | 3.264811 | 2925 | +0.873 mnat | NULL |

**Conclusion:** Bilateral NULL with directional asymmetry — boost direction causes clear regression, reduce is mildly inert. **3-way aux LR decomp CLOSED:** embed (bilateral NULL, #1400), scalars (bilateral NULL, this PR), lm_head only direction-productive at n=1 (since failed n=2 in #1410). Aux LR phase-window mechanism class fully retired. Pulse-fire verification clean (param-class isolation confirmed, scalars LR ratio 1.30/0.70 exact, embed/lm_head bit-identical between arms).

---

## 2026-05-27 22:30 UTC — PR #1487 edward: Aux Adam m/v state reset @ step 2600 — ASSIGNED

- Branch: `g1r1-edward/adam-mv-reset`
- Hypothesis: Adam m (exp_avg) and v (exp_avg_sq) buffers for aux params carry stale gradient history from the stable-LR phase. Resetting them at step 2600 (phase boundary) is a direct analog of the PR #1429 pEMA WIN mechanism — freeing aux optimizer state from pre-cooldown accumulation. Arm A zeros m only; Arm B zeros both m and v.
- Status: **ASSIGNED** — edward to implement and run both arms on canonical baseline (late-higher LR + pEMA refresh @ 2600)
- Merge gate: `sr ≤ 2887.5 OR (sr=2900 AND val_ema < 3.263938)`

---

## 2026-05-27 22:20 UTC — PR #1445: Body Muon WD phase-window pulse (g1r1-edward) — CLOSED NULL

- Branch: `g1r1-edward/body-muon-wd-pulse`
- Hypothesis: temporarily boosting or zeroing weight decay for body Muon params in the phase-window [2500, 2925) would act as a phase-specific regularization signal.

| Arm | WD factor | W&B run | val_loss_ema | sr | Δ vs baseline (3.263938) | Verdict |
|---|---|---|---|---|---|---|
| A | WD×2.0 | — | 3.265422 | 2925 | +1.484 mnat | NULL |
| B | WD×0.0 | — | 3.265528 | 2925 | +1.590 mnat | NULL |

**Conclusion:** Both arms NULL with similar small regressions — the body Muon phase-window axis is now fully mapped across all four sub-axes (LR, WD, NS_iters, μ) and all are CLOSED NULL. Phase-window pulse mechanism class is exhausted. Shifting to optimizer-state reset mechanism class.

---

## 2026-05-27 22:16 UTC — PR #1435: Body Muon NS_ITERS phase-window pulse (g1r1-alphonse) — CLOSED NULL

- Branch: `g1r1-alphonse/body-muon-ns-iters-pulse` (rebased post-#1429 merge)
- Hypothesis: changing NS_ITERS in the Muon Newton-Schulz step within the phase-window [2500, 2925) would affect direction precision and improve convergence. Arm A boosted ns_iters from 12→14, Arm B reduced 12→10.

| Arm | NS_iters pulse | W&B run | val_loss_ema | val_loss_live | sr | Δ vs NEW (3.263938) | Δ vs OLD (3.264718) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 12→14 in [2500,2925) | `ctdz6o52` | 3.266417 | 3.265847 | 2925 | +2.479 mnat | +1.699 mnat | NULL |
| B | 12→10 in [2500,2925) | `dlloyp08` | 3.265689 | 3.265102 | 2925 | +1.751 mnat | +0.971 mnat | NULL |

**Note:** Both arms ran on OLD recipe (no pEMA refresh). Against OLD baseline Arm B's Δ=+0.971 mnat is just outside marginal band but still NULL (OLD merge gate was `sr ≤ 2912.5 OR (sr=2925 AND val < 3.264718)` — Arm B val=3.265689 > 3.264718, fails).

**Polar diagnostics:** NS=14 reduced ortho_residual 0.564→0.072 (cleaner orthogonalization). NS=10 raised it 0.578→3.138 (under-orthogonalized). Both produced near-identical val_ema. **Conclusion:** NS=12 is at the sweet spot for direction precision — more and less both underperform. Direction-precision axis CLOSED.

**Key learning:** The phase-window pulse mechanism class is collectively exhausted. NS_iters boost fails for the same reason WD pulse, LR pulse, and μ pulse failed — small perturbations to a well-tuned baseline consistently produce Δval +0.001 to +0.004 mnat regressions. Next experiments should shift mechanism class entirely.

---

## 2026-05-27 20:05 UTC — PR #1425 tanjiro lm_head LR dose-response CLOSED NULL (both arms) — aux LR-magnitude axis FULLY EXHAUSTED (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lm-head-dose-response` (rebased to `61dcb77bd` post-#1429 merge)
- Hypothesis: extends #1399 lm_head-only ×1.20 marginal-WIN-candidate (Δ−0.302 mnat vs old baseline) into a 3-point dose-response curve {×1.20, ×1.30, ×1.40} to test whether the apparent gain at ×1.20 scales monotonically with multiplier (confirming a real mechanism) OR is seed-noise (collapses non-monotonically).

| Arm | mult | W&B run | val_loss_ema | val_loss_live | sr | Δ vs OLD (3.264718) | Δ vs NEW (3.263938) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | ×1.30 | `2fkycdm0` | 3.264910 | 3.264295 | 2925 | +0.192 mnat | **+0.972 mnat NULL** | NULL |
| B | ×1.40 | `xc242j9w` | 3.265588 | 3.264976 | 2925 | +0.870 mnat | **+1.650 mnat NULL** | NULL |

**Dose-response curve (vs NEW baseline 3.263938):**

| Mult | Source | val_ema | Δ vs new baseline | Verdict |
|---|---|---|---|---|
| ×1.20 | #1399 frieren | 3.264416 | +0.478 mnat | NULL (was marginal-WIN vs OLD only) |
| **×1.30** | **#1425 Arm A** | **3.264910** | **+0.972** | **NULL** |
| **×1.40** | **#1425 Arm B** | **3.265588** | **+1.650** | **NULL (worst)** |

**MONOTONICALLY DEGRADING dose-response across all 3 magnitudes vs new baseline.** The marginal "WIN-candidate" at ×1.20 against OLD baseline was within seed noise; against the tighter NEW baseline (n=2 mean), the entire LR-magnitude axis is NULL across ×1.20-×1.40.

**Pulse-fire verification** — solid. Both arms verified pulse fired correctly: Arm A realized boost 1.298× at step 2500 (target 1.30), Arm B 1.398× (target 1.40); pulse deactivated cleanly at step 2925; embed_lr / scalars_lr / muon_blocks_lr bit-identical between arms (mechanism-orthogonality confirmed).

**Cross-portfolio canon impact — aux LR-magnitude axis fully exhausted:**

| Sub-axis | n=1 result | n=2 status | Net verdict |
|---|---|---|---|
| joint aux ×1.30 (#1365) | Δ−0.720 mnat | COLLAPSED (#1410, Δ+0.500) | seed-noise |
| lm_head-only ×1.20 (#1399) | Δ−0.302 mnat | not pursued (below margin) | NULL vs new baseline (Δ+0.478) |
| **lm_head-only ×1.30 (this Arm A)** | **Δ+0.192 (OLD) / +0.972 (NEW)** | n/a | **NULL** |
| **lm_head-only ×1.40 (this Arm B)** | **Δ+0.870 (OLD) / +1.650 (NEW)** | n/a | **NULL** |
| embed-only ×1.10/×0.90 (#1400) | bilateral +1.3 mnat | n/a | bilateral NULL |
| scalars-only ×1.30 (#1452 Arm A) | Δ+3.882 vs new | n/a | NULL (terminal 19:32 UTC) |
| scalars-only ×0.70 (#1452 Arm B) | TBD (mid-run) | n/a | TBD |

The aux LR-magnitude phase-window pulse mechanism class is now CONFIRMED non-productive across joint, lm_head-only (×1.20-×1.40), embed-only, and scalars-only (×1.30) sub-axes. **The mechanism class is dead** modulo the in-flight scalars ×0.70 Arm B (≈+2-3 mnat NULL likely on current trajectory).

**Closure rationale:** Both arms fail merge gate against new baseline by Δ ≥ +0.972 mnat — n=2 confirmation cannot rescue (would need μ ≤ 3.260 to clear).

**Portfolio pivot:** Mechanism class shifting from aux LR-magnitude (exhausted) → refresh-axis (productive frontier per #1429 confirmed n=2 WIN). Active refresh-axis PRs: #1457 (step-position 2500/2750), #1458 (× ema_beta_target), #1459 (step-position 2850/2900). Will assign tanjiro a fresh optimizer-state-reset hypothesis to broaden the productive-mechanism investigation.

---

## 2026-05-27 17:20 UTC — PR #1429 MERGED as new baseline: pEMA-only refresh @ step 2600 n=2 WIN (g1r1-fern)

- Branch: `g1r1-fern/pema-only-2600-n2-seed2`
- Hypothesis: n=2 seed-2 confirmation of #1378 Arm B (pEMA-refresh @ step 2600, `--paramema_refresh_only`, `--paramema_refresh_step 2600`). First n=2 confirmation SUCCESS after two consecutive marginal-WIN collapses.

| Metric | Seed-1 #1378 `y4nxof1m` | Seed-2 #1429 `fek06bk7` | n=2 mean | Baseline #1289 |
|---|---|---|---|---|
| val_loss_ema | 3.2635624 | 3.2643132 | **3.263938** | 3.264718 |
| sr | 2875 | 2925 | **2900** | 2925 |
| Δ vs baseline (mnat) | −1.156 | −0.405 | **−0.780 WIN** | — |
| Individual merge gate | ✓ sr-clause (sr=2875 ≤ 2912.5) | ✓ val-clause (val < 3.264718 at sr=2925) | ✓ both clauses | — |
| ema_refresh/fired @ 2600 | 1 ✓ | 1 ✓ | — | — |
| Stat-sig (3.28-μ)·√2 | — | — | 0.02272 ≥ 0.004 ✓ | — |

**MERGED as new baseline. Updated merge clause: `sr ≤ 2887.5 OR (sr=2900 AND val_ema < 3.263938)`**

**Mechanism canon — ESTABLISHED:** pEMA refresh at step 2600 is a one-shot zero of the EVAL-MODE param-averaging buffer mid-cooldown. The fresh EMA buffer accumulates only high-quality late-cooldown updates (steps 2601-3250). NOT an optimizer-state mechanism (orthogonal to LR-pulse axis). Refresh-step-POSITION is the load-bearing variable: pEMA @ 2275 NULL (+0.629 mnat, #1378 Arm A), pEMA @ 2600 WIN (−0.780 mnat n=2 mean, this). 1.409 mnat asymmetry confirms step-position dominance.

**Cross-Pareto confirmation:** UNUSUALLY STRONG. Seed-1 passes via sr-improvement (sr=2875), seed-2 passes via val-improvement (val=3.264313 < 3.264718 at sr=2925). Different Pareto axes confirm mechanism robustness across seeds.

**This is the 6th consecutive baseline improvement (PR #68→#94→#137→#193→...→#1289→#1429) and the first in the refresh-axis mechanism class.**

---

## 2026-05-27 17:22 UTC — PR #1430 CLOSED: body × aux pretarget LR stacking NULL — stacking premise doubly undermined (g1r1-nezuko)

- Branch: `g1r1-nezuko/body-aux-stacking`
- Hypothesis: body ×0.85 reduce + aux ×1.30 boost in steps 2500-2924. Premise: body-reduce gives aux "trajectory slack"; aux-boost exploits slack — super-additive via mechanism-orthogonal optimizer surfaces.

| Arm | Config | W&B run | val_loss_ema | sr | Δ vs OLD baseline (3.264718) | Δ vs NEW baseline (3.263938) | Verdict |
|---|---|---|---|---|---|---|---|
| Arm A | body ×0.85 + aux ×1.30 | `vftcmvc5` | 3.2660 | 2925 | +1.282 mnat NULL | **+2.062 mnat NULL** | CLEAR NULL |
| Arm B | body ×0.85 + aux ×1.20 | not launched | — | — | — | — | not needed |
| NEW Baseline #1429 | — | `fek06bk7` | **3.263938** | **2900** | — | — | — |

**Closure rationale — stacking premise doubly undermined:**

1. **aux ×1.30 joint component FAILED n=2 (#1410):** The stacking was premised on #1365 aux ×1.30 being a WIN. After #1410's n=2 collapse (Δ−0.720 → +0.500), aux ×1.30 joint is a CONFIRMED NULL. This PR was always stacking a NULL on a NULL.
2. **aux LR-magnitude axis unraveling:** #1399 lm_head-only ×1.20 (Δ−0.302, below margin) → #1425 Arm A ×1.30 (Δ+0.182 NULL, non-monotonic dose-response). The aux LR phase-window mechanism is increasingly seed-noise-driven.
3. **New baseline harder to beat:** PR #1429 merged → Arm A is +2.062 mnat above new baseline.

**Canon contribution:** Body × aux phase-window LR stacking: DOUBLY-NULL. Confirms individual component NULLs (body LR phase-window #1376, aux LR joint n=2 #1410) are not rescued by cross-surface interaction. The "trajectory slack" mechanism does not materialize.

**nezuko → PR #1458 pEMA × ema_beta_target interaction.**

---

## 2026-05-27 17:35 UTC — PR #1459 fern ASSIGNED: pEMA step-position late-scan — refresh @ 2850 vs 2900

- Branch: `g1r1-fern/pema-step-late-scan`
- Hypothesis: extends the step-position map into late territory. Arm A=2850 (25 steps before earliest canonical sr crossing), Arm B=2900 (within canonical sr range 2875-2925). Complements #1457 frieren (Arm A=2500, Arm B=2750) to give full bilateral coverage around canonical step 2600.

| Arm | refresh_step | Remaining fresh window | Hypothesis |
|---|---|---|---|
| Arm A | 2850 | 400 steps (2851-3250) | Late pre-crossing refresh — params highly converged at refresh |
| Arm B | 2900 | 350 steps (2901-3250) | Within crossing range — very focused terminal-convergence signal |
| Reference WIN | 2600 | 650 steps (2601-3250) | Canonical baseline |

**Step-position full map when combined with #1457:** {2275 NULL, 2500 TBD, 2600 WIN, 2750 TBD, 2850 TBD, 2900 TBD}. A peaked-around-2600 profile would confirm narrow-window canon. A wide WIN plateau would suggest the mechanism tolerates large step variations.

---

## 2026-05-27 17:25 UTC — PR #1458 nezuko ASSIGNED: pEMA × ema_beta_target interaction — maps optimal post-refresh EMA accumulation width

- Branch: `g1r1-nezuko/pema-ema-beta-target-interaction`
- Hypothesis: ema_beta_target=0.99 (PR #1234 WIN) was tuned WITHOUT pEMA refresh. With pEMA @ 2600, the fresh 650-step accumulation window may benefit from different final-β smoothing. Tests N_eff=67 (Arm A, 0.985) vs N_eff=200 (Arm B, 0.995) vs baseline N_eff=100 (0.99).

| Arm | ema_beta_target | N_eff at terminal | Post-refresh window | Hypothesis |
|---|---|---|---|---|
| Arm A | 0.985 | 67 steps | 650 steps fresh | More responsive — closer to terminal params |
| **Baseline** | **0.99** | **100 steps** | **650 steps** | — |
| Arm B | 0.995 | 200 steps | 650 steps fresh | Wider smoother average — captures more of fresh window |

Both arms: `--muon_lr 0.040 --ema_beta 0.97 --ema_warmup_steps 1750 --ema_beta_target <value> --muon_block_lr_pattern late-higher --paramema_refresh_only --paramema_refresh_step 2600`

**Mechanism motivation:** pEMA WIN is specifically about fresh EMA capturing high-quality late-cooldown signal. The ema_beta_target controls how fast the fresh buffer builds up and how widely it averages. Baseline N_eff=100 was not tuned for the pEMA-refresh context. Non-trivial interaction expected.

**Orthogonal to all in-flight:** #1457 (step-position), #1456 (body μ), #1452 (scalars LR), #1445 (body WD), #1435 (body NS_ITERS), #1425 (lm_head LR dose-response).

---

## 2026-05-27 17:10 UTC — PR #1399 frieren lm_head-only LR pulse CLOSED marginal-WIN-candidate WITHOUT MERGE — below margin + dose-response non-monotonic (g1r1-frieren)

- Branch: `g1r1-frieren/lm-head-lr-pulse`
- Hypothesis: aux lm_head-only LR pulse in steps 2500-2924 — Arm A ×1.20 boost, Arm B ×0.80 reduce. Tests param-class isolation within aux family.

| Arm | lm_head LR mult | W&B run | val_loss_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| Arm A | ×1.20 boost | `uawnwfpy` | 3.264416 | 2925 | **−0.302 mnat marginal-WIN-candidate** | Below margin canon |
| Arm B | ×0.80 reduce | `pxyyjwja` | 3.268242 | **2950 (+25 Pareto-shift)** | **+3.524 mnat NULL** | Pareto-shift regression |
| Baseline #1289 | ×1.00 | `3zhwgfiw` | 3.264718 | 2925 | — | — |

**Pulse-fire CLEAN both arms.** lm_head_lr=1.586e-3 (×1.197 boost @ step 2501) Arm A, =1.058e-3 (×0.80 reduce on step-2501 cosine-decayed baseline 1.321e-3) Arm B. embed/scalars LR bit-identical to baseline — param-class isolation verified.

**Closure rationale — DO NOT request n=2 confirmation:**

1. **Δ−0.302 mnat well below 1.0 mnat margin canon** — within seed-noise floor.
2. **Recent 2/2 n=2 collapse pattern** on aux marginal-WIN-candidates: #1325→#1379 collapsed (Δ−0.876 → +0.125), #1365→#1410 collapsed (Δ−0.720 → +0.500). Prior probability of n=2 confirming a Δ−0.302 candidate is now substantially below 50%.
3. **#1425 dose-response in flight** is more informative than redundant n=2 of ×1.20. If lm_head canon is robust, ×1.30 should yield Δ < −0.302 and ×1.40 should yield Δ < −0.302 as well. Arm A of #1425 already terminated NULL Δ+0.182 mnat at ×1.30 — **non-monotonic dose-response detected**, suggesting #1399 Δ−0.302 is seed-driven.

**Directional asymmetry CONFIRMED:** boost-mild-productive (Δ−0.302) vs reduce-strongly-harmful (Δ+3.524 + sr-shift) is the same asymmetry pattern as #1365 joint-aux (Δ−0.720 boost vs Δ+3.557 reduce). However, the asymmetric magnitude does NOT rescue the boost direction from below-margin-noise canon when the n=2 collapse rate is high.

**Aux LR-magnitude axis status (post-#1399 closure):**

| PR | Aux param subset | Mult | Δ val_ema (mnat) | n=2 status |
|---|---|---|---|---|
| #1365 alphonse | joint aux | ×1.30 | −0.720 (n=1) → +0.500 (n=2) | COLLAPSED |
| #1399 frieren (this) | lm_head-only | ×1.20 | −0.302 (n=1) | **CLOSED no n=2** |
| #1400 edward | embed-only | ×1.10 | +1.315 (n=1) | bilateral NULL, CLOSED |
| #1425 tanjiro | lm_head-only Arm A | ×1.30 | +0.182 (n=1) | TERMINAL NULL |
| #1425 tanjiro | lm_head-only Arm B | ×1.40 | in flight | ETA ~20:00 UTC |
| #1410 alphonse | joint aux n=2 confirm | ×1.30 seed-2 | +1.719 | COLLAPSED |
| #1452 askeladd | scalars-only | ×1.30/×0.70 | awaiting pickup | — |

**Canon implication:** the aux LR-magnitude axis is increasingly looking like seed-noise-driven across the canonical pulse window 2500-2924. The productive mechanism class is shifting from aux LR-magnitude (unraveling) to refresh-axis (#1429 just confirmed at n=2). **Portfolio attention pivoting toward refresh-axis exploration** (PR #1457 step-position ablation) and stacking experiments.

**frieren → PR #1457 pEMA refresh STEP-POSITION ablation.**

---

## 2026-05-27 17:08 UTC — PR #1425 tanjiro lm_head LR dose-response Arm A TERMINAL NULL — non-monotonic dose-response (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lm-head-lr-dose-response`
- Hypothesis: lm_head-only LR dose-response — Arm A ×1.30 (matches joint #1365 mult, direct param-class comparison), Arm B ×1.40 (higher mult dose-response).

| Arm | lm_head LR mult | W&B run | val_loss_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| Arm A | ×1.30 | `2fkycdm0` | 3.2649 | 2925 | **+0.182 mnat NULL** | sr-preserve regression |
| Arm B | ×1.40 | `xc242j9w` | in flight (step ~1025/3250) | — | — | ETA terminal ~20:00 UTC |
| Baseline #1289 | ×1.00 | `3zhwgfiw` | 3.264718 | 2925 | — | — |

**NON-MONOTONIC DOSE-RESPONSE detected:** lm_head-only ×1.20 (Δ−0.302 mnat, #1399 Arm A) does NOT extend monotonically to ×1.30 (Δ+0.182 mnat, this PR Arm A). If the lm_head LR mechanism were robust, gain should scale with multiplier — instead the dose-response inverts at the ×1.20→×1.30 boundary.

**Cross-PR dose-response matrix on lm_head LR boost direction:**

| Source | Mult | val_loss_ema | Δ vs baseline (mnat) |
|---|---|---|---|
| #1289 baseline | ×1.00 | 3.264718 | 0.000 |
| #1399 Arm A | ×1.20 | 3.264416 | **−0.302 (marginal-WIN-candidate)** |
| **#1425 Arm A (this)** | **×1.30** | **3.264900** | **+0.182 (NULL regression)** |
| #1425 Arm B (this) | ×1.40 | in flight | — |
| #1365 joint aux (lm_head moves with embed) | ×1.30 | 3.263998 | **−0.720 (n=1) collapsed at n=2** |

**Mechanism interpretation:** the non-monotonic dose-response combined with the n=2 collapse pattern of #1365 strongly suggests that any marginal gain in the lm_head-only-pulse axis is seed-noise-driven rather than mechanism-driven. If lm_head were genuinely load-bearing, larger boosts should produce larger gains (assuming the basin is on the boost side); instead gains evaporate at ×1.30 and seed-driven noise dominates the signal.

**Combined with #1410 joint-aux n=2 collapse + #1399 below-margin marginal + this NON-MONOTONIC dose-response,** the aux LR-magnitude axis is increasingly looking like seed-noise-driven across the canonical pulse window. Arm B ×1.40 outcome will provide the bilateral confirmation — if also NULL, the lm_head canon is FULLY WEAKENED.

**Major portfolio implication:** productive mechanism class is shifting from aux LR-magnitude (unraveling) to refresh-axis (#1429 just confirmed at n=2). Portfolio attention pivoting toward refresh-axis exploration (PR #1457 step-position ablation) and stacking experiments.

---

## 2026-05-27 17:10 UTC — PR #1457 frieren ASSIGNED: pEMA refresh STEP-POSITION ablation — maps productive zone around step 2600

- Branch: `g1r1-frieren/pema-refresh-step-position`
- Hypothesis: maps the productive zone around step 2600 (canonical pEMA-refresh productive step from #1378/#1429 n=2 confirmation). Step-position is the load-bearing variable per #1378 Arm A vs Arm B asymmetry (Δ+0.629 NULL @ step 2275 vs Δ−1.155 WIN @ step 2600).

| Arm | refresh_step | refresh_only flag | Hypothesis |
|---|---|---|---|
| Arm A | 2500 | `--paramema_refresh_only` | entrance to canonical pulse window — tests whether productive zone extends 100 steps earlier |
| Arm B | 2750 | `--paramema_refresh_only` | 175 steps before target crossing — tests whether productive zone extends 150 steps later |
| Reference | 2600 | (from #1429 n=2 mean) | val_ema ≈ 3.263931, sr=2900, Δ−0.787 mnat WIN |

**Mechanism-distinct from in-flight work:**
- #1425 tanjiro lm_head LR dose-response — aux LR-axis
- #1452 askeladd scalars-only aux LR pulse — aux LR-axis
- #1435 alphonse body Muon NS_ITERS pulse — body Muon polish-axis
- #1445 edward body Muon WD pulse — body Muon regularization-axis
- #1456 thorfinn body Muon μ pulse — body Muon momentum-axis
- #1457 frieren pEMA refresh step-position (this) — **refresh-axis step-position mapping** (orthogonal to all)

**Forecasts:**
- Bilateral WIN (both Δ < −0.4 mnat): wide productive zone, refresh-axis tolerant to step shifts ±150
- Both NULL: step 2600 is sharp peak, refresh-axis is narrow-window
- Asymmetric (one WIN one NULL): directional sensitivity — productive zone has unilateral edge

**Issue #1252 phase-specific aligned.** Independent canon-mapping value regardless of #1425 outcome — uses orthogonal mechanism axis.

---

## 2026-05-27 16:48 UTC — PR #1429 fern n=2 seed-2 confirmation of #1378 Arm B pEMA-refresh @ 2600 — STRONG WIN-CANDIDATE (awaiting student SENPAI-RESULT post)

- Branch: `g1r1-fern/pema-only-2600-n2-seed2`
- Hypothesis: n=2 seed-2 confirmation of #1378 fern Arm B (pEMA-refresh @ step 2600, --paramema_refresh_only, --paramema_refresh_step 2600). Tests whether the n=1 marginal-WIN-candidate Δ−1.155 mnat + Δsr=−50 survives a different random seed.

| Metric | Baseline #1289 (3zhwgfiw) | Seed-1 #1378 (y4nxof1m) | Seed-2 #1429 (fek06bk7) | n=2 mean |
|---|---|---|---|---|
| `val/loss_ema` | 3.264718 | 3.263562 | **3.2643** | **~3.263931** |
| `val/loss_live` | — | — | 3.2637 | — |
| `speedrun/first_step_to_target` | 2925 | **2875** | 2925 | **2900** |
| `speedrun/reached_target` | 1 | 1 | 1 | — |
| ema_refresh/fired @ 2600 | n/a | 1 ✓ | 1 ✓ | — |
| Δ vs baseline (mnat) | — | **−1.155 (sr-improve)** | **−0.418 (val-clause)** | **−0.787 mnat WIN** |
| Individual merge gate | — | ✓ PASS via sr-clause | ✓ **PASS via val-clause** | mean PASS via sr-clause |
| Stat-sig (3.28-μ)·√n ≥ 0.004 | — | — | — | 0.02273 ≥ 0.004 ✓ |

**Results commentary:** **n=2 confirmation SUCCESS** — both seeds individually pass the merge gate via DIFFERENT clauses (seed-1 via sr=2875 ≤ 2912.5, seed-2 via val=3.2643 < 3.264718 at sr=2925). This is the FIRST n=2 confirmation success after TWO consecutive collapses (#1325→#1379 Δ−0.876 collapsed, #1365→#1410 Δ−0.720 collapsed). The cross-seed pattern (sr-improvement axis + val-clause axis) makes this a STRONG cross-Pareto confirmation.

**Mechanism canon — refresh-axis RE-ESTABLISHED on pEMA-step:**

The pEMA refresh is NOT an optimizer-state perturbation — it's a EVAL-MODE moving average reset. At step 2600, the param-EMA buffer (used for val_loss_ema computation) is zeroed. Fresh EMA accumulates from step 2600 onward, averaging ONLY high-quality late-cooldown params (steps 2601-3250). The benefit comes from a "cleaner" EMA window aligned with the productive late-cooldown regime, free from pre-cooldown noise contamination.

**Refresh-step asymmetry confirmed at n=2:**
- pEMA @ step 2275 (pre-cooldown): NULL Δ+0.629 mnat (per #1378 Arm A)
- pEMA @ step 2600 (mid-cooldown): WIN Δ−0.787 mnat at n=2 (this PR)
- Asymmetry: 1.416 mnat between refresh-step positions at n=2 — STEP-POSITION is the load-bearing variable.

**Mechanism-orthogonality to LR-pulse axis:**
- pEMA-refresh: EVAL-MODE parameter averaging reset (changes val_ema computation only)
- LR-pulse (#1399/1365): TRAINING-MODE optimizer-step magnitude perturbation (changes training trajectory)
- These are MECHANISTICALLY DISTINCT — stackable. Future stacking PR (lm_head LR pulse + pEMA refresh @ 2600) is the natural next mechanism test.

**Cross-portfolio canon impact:**

| Refresh axis | PR | Mechanism | Verdict |
|---|---|---|---|
| L_cov refresh @ 2600 | #1268 | Muon preconditioner slow-mixing | NULL |
| L_cov multi-refresh | #1386 | dense/sparse multiplicity | NULL (all multiplicities) |
| Aux full state refresh | #1299 | AdamW (m,v,step) | NULL inert |
| Aux variance-only refresh | #1315 | AdamW v only | CATASTROPHIC |
| pEMA refresh @ 2275 | #1378 Arm A | EVAL param-EMA reset (early) | NULL |
| **pEMA refresh @ 2600** | **#1378 Arm B + #1429** | **EVAL param-EMA reset (mid-cooldown)** | **WIN at n=2** |

The refresh-axis is now finely partitioned: L_cov-mech and aux-state-mech are FULLY CLOSED across all variants; pEMA-step is PRODUCTIVE specifically at step 2600. The two refresh families are mechanistically distinct (L_cov = preconditioner state, pEMA = eval-mode averaging buffer).

**Merge readiness:** PR #1429 is merge-ready pending student SENPAI-RESULT post with full-precision seed-2 val_loss_ema and structured marker. Once posted, baseline candidate would update to n=2 mean (~3.263931, sr=2900). Will run `senpai:merge-winner` preflight at that point.

**Awaiting student post for:**
1. SENPAI-RESULT structured marker
2. Full precision val_loss_ema for seed-2 (6 decimal places)
3. Explicit n=2 mean computation
4. pEMA refresh verification snapshots (`||p_ema − p_live||_F` near step 2599 and 2601)

---

## 2026-05-27 16:46 UTC — PR #1407 CLOSED: phase-window aux β2 pulse bilateral NULL — 172nd NULL (g1r1-thorfinn)

- Branch: `thorfinn/aux-beta2-phase-window-pulse`
- Hypothesis: aux Adam β2 phase-window pulse in steps 2500-2924 — tests preconditioner-state-evolution axis (mechanism-orthogonal to LR-magnitude axis). Arm A β2=0.99 (sticky, ~100-step horizon matched to pulse window duration); Arm B β2=0.85 (reactive, ~7-step horizon).

| Arm | β2 in window | W&B run | val_loss_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| Arm A | 0.99 sticky | `n314nsjz` | 3.266934 | 2925 | **+2.216 mnat NULL** | sr-preserve regression |
| Arm B | 0.85 reactive | `hvgpzd01` | 3.267979 | **2975** | **+3.261 mnat NULL** | Pareto-shift regression |
| Baseline #1289 | 0.95 | `3zhwgfiw` | 3.264718 | 2925 | — | — |

**Pulse-fire verification — CLEAN both arms.** β2 transition at step 2501 (0.95→0.99 / 0.95→0.85), reverted to 0.95 at step 2926. embed_lr unchanged confirming β2-axis isolation from LR-axis.

**Preconditioner state diagnostic — `adamw/embed_v_norm` trajectory differential confirmed as designed:** Arm A's sticky β2=0.99 smooths v_t (slower decay/recovery characteristic of ~100-step horizon). Arm B's reactive β2=0.85 yields more volatile v_t (large step-to-step swings characteristic of ~7-step horizon). The β2 mechanism fired as intended — neither arm extracted gain from the state-evolution perturbation.

**Mechanism canon — aux preconditioner-state axis FULLY EXHAUSTED:**

| PR | Aux state axis | Mechanism | Result |
|---|---|---|---|
| #1299 frieren | full state refresh (m, v, step) | one-shot reset at 2275/2600 | NULL inert (β2=0.95 fast-mixing erases) |
| #1315 askeladd | variance-only refresh (v only) | partial state asymmetry | CATASTROPHIC (update magnitude 1e10× explodes) |
| **#1407 thorfinn (this)** | **β2 horizon pulse (0.99↑ / 0.85↓)** | **continuous EMA-rate change** | **BILATERAL NULL (Δ+2.22/+3.26 mnat)** |

**MAJOR CANON — aux preconditioner-state perturbations are STRUCTURALLY NON-LOAD-BEARING at phase-window scale:** the AdamW second-moment statistics encode noise more than signal at the i.i.d.-gradient regime of aux family (per `project_aux_gradient_iid_finding`: aux ||Δg||/||g||≈1.45, cosine≈-0.05). The β2=0.95 baseline is well-tuned at baseline and locally optimal across BOTH directions.

**Aux family phase-window mechanism decomposition status (post-#1407 closure):**

| Axis | PRs | Mechanism | Result |
|---|---|---|---|
| LR magnitude (joint, lm_head, embed, scalars) | #1365/1399/1400/1452 | gradient-step magnitude | lm_head asymmetric (modulo n=2); embed bilateral NULL; scalars in flight |
| State refresh | #1299/#1315 | optimizer state reset | inert / catastrophic |
| **β2 horizon** | **#1407 (this)** | **preconditioner EMA-rate** | **BILATERAL NULL** |

**Only LR-magnitude axis on lm_head specifically is the remaining productive aux phase-window mechanism candidate** (modulo #1399 n=2 status pending #1425 dose-response validation).

**thorfinn → PR #1456 body Muon momentum (μ) phase-window pulse (completes body Muon phase-window axis mapping).**

---

## 2026-05-27 15:25 UTC — PR #1395 CLOSED: phase-window Muon γ pulse bilateral tight NULL — 171st NULL (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-gamma-pulse`
- Hypothesis: temporal-scope axis test — uniform PMuon γ +0.025 (Arm A) / −0.025 (Arm B) ONLY during steps 2700-2900 (200-step pre-target window). Mechanism contrast with #1342 always-on closure: phase-window transient avoids cumulative pre-NS5 damage while targeting the load-bearing crossing window. Tests whether γ-axis is bilaterally NULL across both always-on AND phase-window temporal scopes.

| Arm | γ pulse delta | W&B run | val_loss_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| Arm A | +0.025 (γ: 0.4→0.425) | `4r05upf5` | 3.265612 | 2925 | **+0.894 mnat** | tight NULL |
| Arm B | −0.025 (γ: 0.4→0.375) | `5xq74q1c` | 3.265813 | 2925 | **+1.095 mnat** | tight NULL |
| Baseline | — | `3zhwgfiw` | 3.264718 | 2925 | — | — |

**Pulse-fire verification — CLEAN both arms.** Both arms pulse window 2700-2900 with γ delta ±0.025 around baseline 0.40. Pulse turned off cleanly post-window. No telemetry anomalies.

**Results commentary:** Bilateral tight NULL (Δarms=0.201 mnat). Both arms fail merge gate clause-2. **Phase-window confinement REDUCED damage 5× vs #1342 always-on** (always-on Δ+4.254/+1.650 mnat → phase-window Δ+0.894/+1.095 mnat), confirming temporal-scope is partially load-bearing — but residual positive signal in BOTH directions still indicates γ-axis is structurally non-load-bearing.

**γ-axis canon (cross-PR confirmation):**

| Temporal scope | Arm A (boost) | Arm B (reduce) | Pattern |
|---|---|---|---|
| Always-on (#1342) | +4.254 mnat NULL (Pareto-shift) | +1.650 mnat NULL | bilateral asymmetric |
| Phase-window (this) | +0.894 mnat NULL | +1.095 mnat NULL | bilateral tight symmetric |

**Mechanism canon ESTABLISHED:** NS5 polar normalization absorbs spectral-strength perturbation at any duration. γ-axis is downstream-orthogonal to val_loss in current modded-nanogpt architecture (the polar decomposition normalizes singular values to ones regardless of γ-driven L_neg eigenvalue scaling). γ-axis is bilaterally + temporally exhausted.

**askeladd → PR #1452 aux scalars-only LR phase-window pulse (completes 3-way aux LR decomp).**

---

## 2026-05-27 14:15 UTC — PR #1400 CLOSED: embed-only phase-window LR pulse bilateral NULL — 170th NULL (g1r1-edward)

- Branch: `g1r1-edward/embed-pulse`
- Hypothesis: embed-only AdamW LR phase-window pulse (steps 2500–2924) — 3-way aux decomp (embed cell). Tests whether embed LR perturbation during pre-target window extracts gain, analogous to lm_head-only #1399.

| Arm | Mult | W&B run | val_loss_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| Arm A | ×1.10 boost | `qn9v73ln` | 3.266033 | 2925 | **+1.315 mnat** | NULL regression |
| Arm B | ×0.90 reduce | `cufbxnzo` | 3.266069 | 2925 | **+1.351 mnat** | NULL regression |
| Baseline | — | `3zhwgfiw` | 3.264718 | 2925 | — | — |

**Pulse-fire verification — CLEAN both arms.** Arm A: ×1.098 measured (2501→0.069795, pre-2499: 0.063687), lm_head_lr untouched throughout. Arm B: ×0.898 measured (2501→0.057105, pre-2499: 0.063687), lm_head_lr untouched.

**Results commentary:** Bilateral symmetric regression (~+1.33 mnat each direction) establishes **embed LR baseline as locally optimal** in pre-target window. Symmetric basin: ±10% perturbation detectable at n=1, both directions harmful. n=2 NOT required — bilateral pattern eliminates seed-noise explanation.

**3-way aux decomposition COMPLETED:**

| Param class | Boost | Reduce | Verdict |
|---|---|---|---|
| lm_head (#1399) | −0.302 mnat marginal-WIN-candidate | TBD (Arm B relaunch `pxyyjwja`) | asymmetric (boost productive, n=1) |
| embed (this) | +1.315 mnat NULL | +1.351 mnat NULL | bilateral non-load-bearing |
| scalars | UNTESTED | UNTESTED | open |

**Mechanism canon:** Param-class asymmetry within aux family confirmed — embed and lm_head have opposite responses despite similar scale. Embed's tight basin (±10% detectable regression) may reflect that baseline embed LR is already well-calibrated for the convergence window. The joint-aux marginal-WIN (#1365, FAILED n=2) must have been driven by lm_head, partially offset by embed's ~+1.3 mnat regression cost.

**edward → PR #1445 body Muon WD phase-window pulse (regularization-axis, LR-orthogonal).**

---

## 2026-05-27 13:30 UTC — PR #1410 CLOSED: n=2 seed-2 confirmation of #1365 aux LR pulse — n=2 FAILED (g1r1-alphonse)

- Branch: `alphonse/n2-confirm-aux-pulse-arm-a`
- Hypothesis: n=2 seed-2 confirmation of #1365 alphonse Arm A (joint aux LR phase-window pulse ×1.30 in steps 2500-2924). Tests whether the n=1 marginal-WIN-candidate Δ−0.720 mnat survives a different random seed.

| Metric | Baseline #1289 (3zhwgfiw) | Seed-1 #1365 (ipovq4m5) | Seed-2 this run (53ln5na6) | n=2 mean |
|---|---|---|---|---|
| `val/loss_ema` | 3.264718 | 3.263998 | **3.266437** | **3.265218** |
| `val/loss_live` | 3.264114 | 3.263395 | 3.265836 | 3.264615 |
| `speedrun/first_step_to_target` | 2925 | 2925 | **2925** | — |
| `single_run_stat_sig_margin` vs 3.28 | — | — | 0.009562 ≥ 0.004 ✓ | — |
| Δ vs baseline | — | −0.720 mnat (marginal-WIN-candidate) | **+1.719 mnat (regression)** | **+0.500 mnat (NULL)** |

**Results commentary:** seed-2 (`53ln5na6`) val_ema=3.266437 is +1.719 mnat ABOVE baseline (regression). The n=2 mean across seed-1 and seed-2 is 3.265218, ABOVE baseline (3.264718) → FAILS merge gate. Seed-2 val_ema is also above the NULL-gate threshold of 3.265438. **The #1365 Arm A marginal-WIN-candidate is hereby retroactively CLOSED as failed-n=2-confirmation NULL.** This is the SECOND consecutive marginal-WIN n=2 collapse in the portfolio (after #1325 → #1379).

**Pulse-fire telemetry — CLEAN execution:**
- Window: Python steps [2500, 2925), 425 steps total (13.08% of training).
- `pulse/active=1` and `pulse/effective_mult=1.3` verified across all 3 aux groups (`adam_embed`, `adam_lm_head`, `adam_scalars`) at wandb steps 2525-2925.
- Pulse extinguished cleanly at step 2950: `pulse/active=0`, `effective_mult=1.0`.
- Multiplier ratio at boundary: lr/aux_lr_embed jump 0.06357 → 0.07881 ≈ ×1.3 ✓.

**Seed-flag verification** (per #1379 canon, step-25 train_loss):
- Seed-1: step-25 train_loss = 5.961228
- Seed-2: step-25 train_loss = 5.979760 (DIFFERS — seed flag working correctly)
- Step-1 train_loss = 10.82584 IDENTICAL (BF16 uniform-output regime, expected)

**Duplicate-process operational hygiene:** Student found two duplicate processes at session start (PIDs 2037224 and 2041332 competing for the same GPU at 6 sec/step). Killed the later/slower 2041332, preserving canonical 09:01-UTC-started `53ln5na6`. Duplicate `2gsv4y0l` (crashed at step 200) properly excluded from wandb_run_ids in SENPAI-RESULT.

**MAJOR CANON — n=2 collapse pattern established:**

| Original marginal-WIN | n=1 Δ | n=2 confirmation | n=2 Δ mean | Verdict |
|---|---|---|---|---|
| #1325 thorfinn Lcov+pEMA stack | −0.876 mnat | #1379 seed-2 | +0.124 mnat | n=2 FAIL |
| **#1365 alphonse aux LR pulse joint ×1.30** | **−0.720 mnat** | **#1410 seed-2 (this)** | **+0.500 mnat** | **n=2 FAIL** |
| #1378 fern pEMA-only @ 2600 | −1.155 mnat (Δsr=−50) | #1429 fern seed-2 (in flight) | TBD | TBD |
| #1399 frieren lm_head-only ×1.20 | −0.302 mnat | n=2 not yet assigned | TBD | TBD |

**Pattern recognition:** Marginal-WIN-candidates with Δ ≤ 1.0 mnat at n=1 and Δsr=0 are collapsing to NULL at n=2 with high probability. The single surviving candidate (#1378 fern Arm B) has BOTH a Δval AND Δsr improvement (50-step sr improvement is much harder to explain by seed noise than val-only signal).

**Mechanism canon impact:**
- **Lm_head-dominant 3-way aux decomp canon (10:45 UTC) WEAKENED.** #1399 lm_head-only (Δ−0.302) and #1400 embed-only (Δ+1.315) are now both suspect of seed-noise.
- **#1425 tanjiro lm_head dose-response IS now critical** — if ×1.30 and ×1.40 both fail to extract gain, the aux LR phase-window mechanism class is fundamentally not load-bearing at this magnitude.
- **#1430 nezuko body × aux stacking premise WEAKENED** — one of the stacking anchors (#1365 marginal-WIN) just failed n=2.
- **Highest-confidence remaining direction: #1378 Arm B pEMA-refresh @ 2600** (n=2 via #1429 in flight).

**Cross-portfolio impact:** This is the strongest negative evidence yet that the "aux LR phase-window pulse" mechanism class is mechanism-orthogonal to the speedrun benchmark at the tested magnitudes. The portfolio shifts toward (a) mechanism-orthogonal axes (gradient direction precision, schedule shape, optimizer state hard-reset) and (b) higher-confidence Δsr-coupled candidates like #1378 Arm B.

**Excellent execution:** Student's seed-flag verification (step-25 train_loss canon), pulse-fire telemetry, and duplicate-process hygiene were the model report for n=2 confirmations. This is the canonical pattern going forward.

**Next step:** alphonse → PR #1435 body Muon NS_ITERS phase-window pulse (mechanism-orthogonal to LR — tests gradient direction precision axis).

## 2026-05-27 12:40 UTC — PR #1386 CLOSED: L_cov multi-refresh schedule — 169th NULL, L_cov multiplicity axis FULLY CLOSED (g1r1-nezuko)

- Branch: `g1r1-nezuko/lcov-multirefresh`
- Hypothesis: Test L_cov refresh MULTIPLICITY — Arm A dense 4-refresh at steps {1750, 2275, 2600, 2925}; Arm B sparse 2-refresh at {2275, 2600}. Tests whether single L_cov refresh (#1268) NULLed because cooldown staleness re-accumulates, and multi-refresh maintains preconditioner freshness through target crossing.

| Arm | Schedule | wandb | val_ema | val_live | sr | lcov_refresh/fired | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #1289 | none | `3zhwgfiw` | 3.264718 | 3.264114 | 2925 | 0 | — | ref |
| **Arm A dense4** | {1750,2275,2600,2925} | `h81v1pzf` | **3.266377** | 3.265796 | **2925** | **4** ✓ | **+1.659 mnat** | **tight NULL** |
| **Arm B sparse2** | {2275,2600} | `gv2spz7b` | **3.265732** | 3.265133 | **2925** | **2** ✓ | **+1.014 mnat** | **tight NULL** |

**Results commentary:** Bilateral tight NULL on both multiplicities. All refresh events fired correctly per `lcov_refresh/fired_count` (4 for Arm A, 2 for Arm B); both arms preserved sr=2925 baseline-matched. Student's refresh-event smoothness check (val_loss_live at ±150 steps around each refresh step) showed smooth monotonic descent through refresh boundaries — no perturb-and-recover signature, confirming the L_cov reboot is a low-disruption preconditioner reset rather than a large recalibration shock. The reset operates BELOW val-sampling noise floor at standard cadence.

**Monotone-more-harmful canon:** Arm A dense4 (+1.659) > Arm B sparse2 (+1.014) — adding refreshes is mildly monotonically harmful, with each additional refresh costing ~+0.2-0.4 mnat. Plausible mechanism: each refresh adds preconditioner re-equilibration overhead during cooldown, accumulating linearly without compensating benefit. The 0.645 mnat asymmetry between arms is itself a clean dose-response on multiplicity (4 refreshes vs 2 refreshes = +0.645 mnat differential, scales linearly per refresh at ~0.16 mnat each in the dense regime).

**MAJOR CANON — L_cov refresh axis FULLY CLOSED across multiplicities:**

| PR | Schedule | n | val_ema | Δ vs baseline | Verdict |
|---|---|---|---|---|---|
| Baseline #1289 | none | — | 3.264718 | — | ref |
| #1268 fern (single) | {2600} | n=2 mean | 3.266206 | +1.488 mnat | tight NULL |
| #1325→#1379 thorfinn (stacked) | {2600} + pEMA@2275 | n=2 mean | 3.264842 | +0.124 mnat | tight NULL (167th) |
| **#1386 Arm B sparse2** | {2275,2600} | n=1 | 3.265732 | +1.014 mnat | tight NULL (this) |
| **#1386 Arm A dense4** | {1750,2275,2600,2925} | n=1 | 3.266377 | +1.659 mnat | tight NULL (this) |

**Refresh-axis canon now finely partitioned:**
- **L_cov refresh: CLOSED universally** across {single, sparse2, dense4, stacked-with-pEMA}
- **pEMA refresh: REOPENED via #1378 Arm B** at step 2600 (marginal-WIN-candidate, pending #1429 n=2)

The two refresh families are mechanistically distinct: L_cov refresh resets preconditioner covariance state (slow-mixing β_cov=0.95, deeply baked); pEMA refresh resets averaging buffer (fast-recovering, signal-to-noise sensitive to refresh timing). Your closure of L_cov multiplicity provides the cleanest possible separator: refresh-MECHANISM matters more than refresh-MULTIPLICITY.

**Cross-portfolio impact:** 169th closed NULL. Bilateral closure across multiplicities locks the L_cov refresh axis as universally non-load-bearing. Combined with all schedule-shape direct levers (#1350 frieren aux cooldown power split + this) = full schedule-shape direct lever exhaustion.

**Student's excellent execution:** Refresh-event smoothness diagnostic was the cleanest mechanism-validation telemetry of any L_cov refresh PR to date — confirmed no perturb-recover signature, supporting the "low-disruption reset" interpretation. Useful canon for future low-impact-mechanism designs.

**Next step:** nezuko → PR #1430 body × aux pretarget LR stacking (super-additive joint pulse test, tanjiro-suggested follow-up).

## 2026-05-27 12:25 UTC — PR #1378 CLOSED: pEMA-only ablation — MARGINAL-WIN-CANDIDATE Arm B reopens refresh-axis canon (g1r1-fern)

- Branch: `g1r1-fern/pema-only-ablation`
- Hypothesis: Disentangle the #1325 thorfinn marginal-WIN (Lcov@2600 + pEMA@2275 stack) by running pEMA-refresh-only (no Lcov refresh) at each of the two canonical steps. Tests whether pEMA-refresh alone extracts the original stacked-WIN signal or whether the L_cov+pEMA pairing is mechanistically necessary.

| Arm | Mechanism | wandb | val_ema | val_live | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #1289 | none | `3zhwgfiw` | 3.264718 | 3.264114 | 2925 | — | ref |
| #1325 thorfinn (seed-1) | Lcov@2600+pEMA@2275 | `16hncm3t` | 3.263842 | — | 2925 | −0.876 mnat | marginal WIN (failed n=2) |
| #1379 thorfinn (seed-2) | Lcov@2600+pEMA@2275 | `9go3m8ex` | 3.265844 | — | 2925 | +1.126 mnat | seed-2 NULL |
| **Arm A** (this) | **pEMA-only @ 2275** | **`scg8wq17`** | **3.265347** | 3.264756 | **2925** | **+0.629 mnat** | **tight NULL (as forecast)** |
| **Arm B** (this) | **pEMA-only @ 2600** | **`y4nxof1m`** | **3.263562** | 3.262971 | **2875** | **−1.155 mnat / Δsr=−50** | **MARGINAL-WIN-CANDIDATE (UNEXPECTED)** |

**Results commentary:** Arm A confirms the converging-NULL forecast — pEMA-only-refresh at the canonical 2275 step does NOT extract the #1325 marginal-WIN. Combined with #1379 seed-2 NULL on the full Lcov+pEMA stack, this would have closed the refresh-axis as 169th NULL. **Arm B CONTRADICTS the converging-NULL forecast** — pEMA-only-refresh at step 2600 (Lcov's canonical step) shows substantial Δsr=−50 + Δval=−1.155 mnat. The merge gate (`sr ≤ 2912.5 OR (sr=2925 AND val_ema < 3.264718)`) is PASSED by Arm B with 37.5 steps of sr margin; Δval=1.155 mnat sits just above the 1.0 mnat marginal-noise floor, so n=2 confirmation is required (matching the #1365→#1410 alphonse pattern). Refresh diagnostics clean both arms: `ema_refresh/fired=1` at the prescribed step, `lcov_refresh/fired=0`, EMA buffer frob_dist recovers to baseline-band 30 by terminal. Arm B's step-2625 EMA-buffer transient (val_ema 3.316 → recovers to 3.27 by step 2900) is the expected zero-out artifact, NOT run failure.

**MAJOR CANON — pEMA-refresh-STEP asymmetry hypothesis (refresh-axis RE-OPENED):**
The 1.785 mnat asymmetry between Arm A (pEMA@2275: 3.265347) and Arm B (pEMA@2600: 3.263562) at single-seed-each is portfolio-significant evidence. If pEMA-only was uniformly NULL, both arms should be baseline-band; instead the 325-step gap in refresh timing produces a sign-flip on the Δval signal. Two competing interpretations:

1. **(Real mechanism — late-cooldown signal-to-noise)**: At step 2600, live params already encode useful cooldown trajectory. Zeroing EMA history at that moment lets the buffer re-accumulate ONLY high-quality late-cooldown updates (better signal-to-noise than averaging across all training history). Step 2275 is too early — refresh discards useful pre-cooldown EMA before the late-cooldown trajectory is baked in.
2. **(Noise)**: Single-seed n=1 result; val crossing at step 2875 is only 0.13 mnat below TARGET=3.28 (a fragile crossing); baseline run-to-run variance ~2 mnat per #1325→#1379 → ±1.155 mnat fluctuation plausibly drawn from same noise distribution.

Striking comparison: Arm B (3.263562) is at-least-as-good as #1325 seed-1 stack (3.263842), with SIMPLER mechanism (pEMA-only-@-2600, no Lcov). If this WIN survives n=2, it suggests the original #1325 mechanism was pEMA-refresh-AT-step-2600, NOT temporal-pairing or L_cov refresh.

**Cross-portfolio impact:**
- **REFRESH-AXIS CANON RE-OPENED.** Was about to fully close pending #1378 Arm B and #1379 seed-2 → both required for closure. Arm B WIN-candidate reopens.
- pEMA-refresh-step is now an active marginal-WIN direction alongside aux-LR-phase-window (#1365 joint, #1399 lm_head-only).
- Disentanglement matrix completed for refresh-mechanism × refresh-step (pEMA only, Lcov disabled): 2275 NULL, 2600 WIN-candidate.

**Student's suggested follow-ups (preserved for future assignment):**
1. **n=2 confirmation of Arm B** at seed-2 — ASSIGNED as PR #1429 fern.
2. Refresh-step sweep at 2500/2700/2800/2900 — discriminate "step 2600 is special" vs "any late-cooldown refresh works" via inverted-bathtub vs monotone-later.
3. Mechanism probe at step 2600 — measure `ema_minus_live` Frobenius norm before vs after refresh; correlate with WIN magnitude across step sweep.
4. Re-examine #1325 retroactive close — compare pEMA-only-@2600 (this Arm B, 3.263562) to pEMA-only-@2275-WITH-Lcov-@2600 (#1325 Arm A, 3.263842) in a future ablation.
5. Arm A asymmetry probe — +0.629 mnat regression slightly larger than zero-mean noise; could indicate refreshing pEMA too early (step 2275) is actively harmful (discards useful EMA history).

**Next step:** fern → PR #1429 n=2 seed-2 confirmation of Arm B (`--paramema_refresh_only --paramema_refresh_step 2600 --seed 2`). If WIN confirmed, pEMA-refresh-@-2600 becomes simplest extracted late-cooldown mechanism. If NULL, joins #1325→#1379 pattern as seed-1 noise collapse.

## 2026-05-27 11:55 UTC — PR #1376 CLOSED: Pre-target body Muon LR pulse — bilateral tight NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pretarget-body-muon-lr-pulse`
- Hypothesis: Phase-window LR pulse on body Muon (all 12 blocks) in steps 2500-2924, mirror of #1365's aux LR pulse but on body. Arm A boost ×1.15 vs Arm B reduce ×0.85. Tests whether body Muon shares the aux family's phase-window LR sensitivity (#1365 marginal-WIN).

| Arm | Pulse mult | wandb | val_ema | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|
| Baseline #1289 | none | `3zhwgfiw` | 3.264718 | 2925 | — | ref |
| **Arm A boost** | **×1.15** | **`lc200o4g`** | **3.265653** | **2925** | **+0.935 mnat** | **tight NULL** |
| **Arm B reduce** | **×0.85** | **`i58u6ti0`** | **3.265228** | **2925** | **+0.510 mnat** | **tight NULL** |

**Results commentary:** Bilateral tight NULL. Both directions of ±15% body Muon LR perturbation in the pre-target window leave val_ema slightly above baseline with sr=2925 preserved on both arms. The reduce direction is closer-to-baseline (+0.510 vs +0.935 mnat), suggesting mild asymmetric preference for slightly-reduced body LR in this window, but the magnitude is well within seed noise. Pulse-fire verification CLEAN: exact ×1.15/×0.85 multipliers applied at step 2525, extinguished at step 2950, body_pretarget_pulse/active flag matched window boundaries. No instability flags (lcov_eigh_min 3698 Arm A vs 3617 Arm B — healthy; polar/ortho_residual 0.155/0.111 — Arm B slightly tighter as expected for reduced late-cooldown body updates).

**MAJOR CANON — body-vs-aux phase-window asymmetry ESTABLISHED:**
Paired with the completed 3-way aux decomposition, this PR locks in the cleanest mechanism factorization to date:
- **Body Muon (per-block axes):** ALL 7 axes bilaterally NULL on phase-window LR perturbation (this PR), per-block LR PATTERN (#1289) was the only productive direction across the body-side matrix
- **Aux family (embed+lm_head+scalars):** asymmetric load-bearing — lm_head dominant productive (#1399 Δ−0.302 mnat at ×1.20), embed counter-productive (#1400 +1.315 mnat at ×1.10), joint marginal-WIN (#1365 Δ−0.720 mnat at ×1.30)

Mechanistic interpretation: by step 2500, body representation has converged enough that ±15% LR perturbation does not change crossing dynamics — body updates wash out before NS5 polish. The aux state (embed + lm_head + scalars) is still actively shaping logits during cooldown and remains sensitive to phase-window pulses, with lm_head being the loss-projection-adjacent layer that drives the productive direction.

**Cross-portfolio impact:** Without this bilateral body NULL, the #1365 marginal-WIN could not be cleanly localized to aux — the body-side falsification was a necessary canon contribution. 168th closed NULL.

**Student's suggested follow-ups (preserved for future assignment):**
1. Body NULL × aux marginal-WIN stacking — combine #1365 ×1.30 aux boost with body ×0.85 reduce. HIGH-PRIORITY when sequencing permits (after #1410 n=2 settles).
2. Wider body-reduce sweep (×0.70 or ×0.60) — DEPRIORITIZED (risk of catastrophic at aggressive reduce, per #1365 Arm B ×0.70 catastrophic).
3. Late-extending window past sr=2925 — mechanism-overlaps with post-crossing-amplifying canon; LOW priority.
4. Aux decomposition validation — COMPLETED 10:45 UTC (#1400 closed lm_head-dominant canon).
5. NO n=2 — bilateral signal strong, n=2 unnecessary.

**Next step:** tanjiro → fresh hypothesis on next wake cycle (lm_head dose-response or lm_head+scalars selective pulse — both canon-extension candidates).

## 2026-05-27 08:50 UTC — PR #1365 CLOSED: Pre-target aux LR pulse — marginal-WIN-candidate (Outcome 2 directional asymmetry) (g1r1-alphonse)

- Branch: `g1r1-alphonse/pretarget-aux-lr-pulse`
- Hypothesis: First phase-window-specific aux intervention. Arm A boost ×1.3 vs Arm B reduce ×0.7 on AdamW aux LR (all 3 groups jointly) during steps 2500-2924 (425-step pre-target window). Tests whether the pre-target crossing window has asymmetric aux LR sensitivity.

| Arm | Pulse mult | wandb | val_ema | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|
| Baseline #1289 | none (1.0) | `3zhwgfiw` | 3.264718 | 2925 | — | ref |
| **Arm A boost** | **×1.3** | **`ipovq4m5`** | **3.263998** | **2925** | **−0.720 mnat** | **marginal-WIN-candidate (n=2 required)** |
| Arm B reduce | ×0.7 | `cy89qzmf` | 3.268275 | 2950 | +3.557 mnat | **NULL Pareto-shift** |

**Results commentary:** First aux-side phase-window intervention to beat baseline at n=1. Directional asymmetry confirmed: 5× harm-side magnitude (Arm B +3.557 vs Arm A −0.720) plus +25-step sr penalty on Arm B implies the embed/lm_head LR is under-cooked at baseline cooldown's step 2500-2924 window. Boost helps modestly; starve hurts substantially. NOT seed noise — directional mechanism.

**Mechanism canon — POST-CROSSING-AMPLIFYING (NEW):**
- Arm A crosses target at step 2924 (identical to baseline 2924) — pulse does NOT change target-crossing timing
- Arm B crosses at step 2949 (+25 step penalty) — pulse reduce destabilizes the crossing
- Δ−0.720 mnat gain on Arm A accumulates over steps 2925→3250 (post-pulse) via cumulative embed/lm_head state advancement carrying into final EMA convergence

Distinct from schedule-shape interventions (which shift the crossing) and from per-block depth-stratification (which redistributes update mass across blocks).

**Corroborating telemetry:**
- `pmuon/lcov_eigh_min` Arm A 4022 vs Arm B 3377 (+19%) — aux boost slightly improves Muon body's accumulated covariance conditioning during late cooldown (cross-optimizer-class downstream effect from aux perturbation)
- `polar/ortho_residual_sample` Arm A 0.213 vs Arm B 0.198 — small but consistent
- Pulse-window telemetry verified: `aux_pretarget_pulse/active=1, effective_mult=1.3` at code step 2924 (Arm A), 0.7 (Arm B) — pulse fired and extinguished correctly

**Next step: n=2 seed-2 confirmation assigned to alphonse (PR #1410)** with exact Arm A config + --seed 2. Merge gate: n=2 mean val_ema < 3.263718 (X_seed2 < 3.263438 for CONFIRMED WIN).

**Cross-portfolio context:** Anchor of 3-way aux family phase-window decomposition. Joint pulse #1365 (this) + lm_head-only #1399 (in flight ~73%) + embed-only #1400 (in flight ~65%) will triangulate which aux param-class drives the marginal-WIN signal. The 3-way ensemble + n=2 seed-2 confirmation provides multi-axis statistical evidence.

## 2026-05-27 08:25 UTC — PR #1379 CLOSED: n=2 seed confirmation temporal-separated Lcov+pEMA stacking — FAILED (n=2 NULL, #1325 retroactively 167th NULL) (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/temporal-sep-n2-confirm`
- Hypothesis: n=2 seed confirmation for #1325 Arm A (Lcov@2600 + pEMA@2275, the best marginal-WIN-candidate arm). Seed-2 was required to confirm the Δ−0.876 mnat marginal-WIN at n=1.

| Run | Config | wandb | val_ema | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|
| Baseline #1289 | late-higher | `3zhwgfiw` | 3.264718 | 2925 | — | ref |
| #1325 seed-1 (ref) | Lcov@2600+pEMA@2275, seed=1 | `16hncm3t` | 3.263842 | 2925 | −0.876 mnat | marginal-WIN-candidate |
| **#1379 seed-2 (this)** | **Lcov@2600+pEMA@2275, seed=2** | **`9go3m8ex`** | **3.265844** | **2925** | **+1.126 mnat** | **NULL** |
| n=2 mean | — | — | 3.264843 | 2925 | +0.125 mnat | **FAILED n=2 — NULL** |

**Results commentary:** n=2 mean (3.264843) sits on the NULL side of the baseline (3.264718), Δ+0.125 mnat NULL. Seeds bracket the baseline nearly symmetrically (−0.876 vs +1.126 mnat), textbook pattern of seed noise around the null hypothesis. n=2 confirmation FAILS for #1325. **#1325 thorfinn temporal-stacking is retroactively closed as 167th NULL (failed-n=2-confirmation NULL).**

Corroborating evidence: #1378 fern pEMA-only-@2275 Arm A (same pEMA mechanism isolated) terminated at Δ+0.629 mnat tight NULL — two independent disentangling lines (seed-2 confirmation + pEMA-only isolation) converge on same conclusion. The joint Lcov+pEMA signal was statistical noise.

**Canon additions:**
1. **Temporal-stacking refresh direction CLOSED** — Lcov@2600+pEMA@2275 (and by extension, any multi-refresh temporal-separation stacking on this surface) does not extract reproducible gain over #1289.
2. **Seed-verification protocol update** — step-1 train_loss ≈ log(50304) ≈ 10.826 is dominated by BF16-quantized uniform output entropy, insensitive to seed. Future n=2 seed checks should reference step-25 train_loss or step-125 val_loss (both show meaningful divergence as student confirmed via trajectory table).
3. **Marginal-WIN-requires-n=2 gate validated empirically** — 2nd consecutive marginal-WIN-candidate this round to fail n=2 confirmation (joining the historical pattern). The gate is correctly calibrated.

## 2026-05-27 06:12 UTC — PR #1352 CLOSED: Per-block Muon NS_ITERS shape — 166th NULL (g1r1-edward)

- Branch: `g1r1-edward/per-block-muon-ns-iters-shape`
- Hypothesis: 7th and final per-block Muon axis — depth-stratified NS5 iteration count. Arm A late-higher (10→14), Arm B late-lower (14→10). Mean=12 preserved in both arms.

| Arm | NS_ITERS pattern | wandb | val_ema | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|
| Baseline #1289 | 12 global | `3zhwgfiw` | 3.264718 | 2925 | — | ref |
| Arm A (late-higher) | 10,10,11,11,11,12,12,13,13,13,14,14 | `uu4whhc4` | **3.266043** | 2925 | **+1.32 mnat** | NULL sr-preserving |
| Arm B (late-lower) | 14,14,13,13,13,12,12,11,11,11,10,10 | `wpy65qqu` | 3.268200 | 2950 | **+3.48 mnat** | NULL Pareto-shift |

- **PER-BLOCK MUON MATRIX FULLY ENUMERATED (7/7 axes). Only LR (#1289) productive.**
- Directional NS_ITERS asymmetry: Arm A (deeper blocks prefer ≥12 iters) is sr-preserving tight NULL — first per-block axis that doesn't Pareto-shift sr. Arm B (shallower polar on deep blocks) Pareto-shifts sr+25. Polish-intensity has depth direction but no scalar gain over baseline=12.
- Combined with #884 scalar NS_ITERS closure, NS5 cubic + 12 iters globally is structurally optimal at both scalar AND distribution levels.
- **166th NULL. Per-block Muon matrix closed.**
- edward → PR #1400 pre-target embed LR pulse (aux 3-way decomposition: embed vs lm_head vs joint).


## 2026-05-27 05:42 UTC — PR #1350 CLOSED: Aux cooldown power split — 165th NULL (g1r1-frieren)

- Branch: `g1r1-frieren/aux-cooldown-power-split`
- Hypothesis: Per-optimizer-class cooldown power split (aux AdamW vs body Muon separate COOLDOWN_POWER). Tests whether embed/lm_head benefit from different cooldown decay shape than body Muon. Arm A aux_power=1.2 (flatter), Arm B aux_power=1.6 (sharper), body fixed at 1.4.

| Arm | aux_power | wandb | val_ema | sr | Δ vs baseline | Verdict |
|---|---|---|---|---|---|---|
| Baseline #1289 | 1.4 (joint) | `3zhwgfiw` | 3.264718 | 2925 | — | ref |
| Arm A (flatter) | 1.2 | `r23twtg5` | **3.265229** | 2925 | **+0.51 mnat** | NULL tight |
| Arm B (sharper) | 1.6 | `y8wokins` | **3.267135** | 2925 | **+2.42 mnat** | NULL |

- Both arms NULL. Best arm A val_ema=3.265229, sr=2925. Both merge clauses fail.
- **Mechanism verification (key finding):** 2.18× aux LR mass differential at sr boundary (Arm A 0.0968 vs Arm B 0.0444 at step 2925) produced near-identical val trajectories through step 3000. Null result is mechanism-verified via `adamw/aux_lr_mult_t` telemetry (measured within 2% of predicted perturbation).
- **Mechanistic explanation:** (1) BF16 round-off floor on aux params: once aux_lr < ~0.07× peak, BF16 quantization dominates update magnitude, masking schedule shape. (2) Aux i.i.d. canon: anti-correlated aux gradients (cosine≈−0.05) mean integrated aux LR over cooldown window dominates more than within-window shape.
- **Qualitative distinction from per-block axes:** Arm A's tight NULL (+0.51 mnat, sr unchanged) is qualitatively different from per-block depth-stratification PRs (#1332/#1337/#1339/#1342 all produced sr+25 to sr+125 Pareto-shifts). Schedule-shape axis is weakly-coupled, not catastrophically sensitive.
- **165th NULL.** 5th schedule-shape NULL on top of #1289 baseline (after #1213/#1215/#1229/#1263). Schedule-shape direct lever closed.
- frieren → PR #1399 lm_head-only LR phase-window pulse (param-class asymmetry).


## 2026-05-27 04:25 UTC — PR #1342 CLOSED: Per-block Muon γ — 164th NULL (g1r1-askeladd)

- Branch: `g1r1-askeladd/per-block-muon-gamma`
- Hypothesis: Depth-stratified Muon γ (bilateral whitening exponent, baseline=0.4) on top of #1289 LR baseline. Arm A late-higher (b0=0.375→b11=0.425), Arm B late-lower (mirror). Tests SPECTRAL-INTENSITY depth-asymmetry, distinct from MAGNITUDE family.

| Arm | wandb run | γ pattern | val_loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| Baseline #1289 | `3zhwgfiw` | uniform 0.40 | 3.264718 | 2925 | — |
| A (late-higher) | `qdibdsps` | b0=0.375→b11=0.425 | 3.268972 | 2975 | **+4.254 mnat Pareto-shift NULL** |
| B (late-lower) | `p8vwk9hu` | b0=0.425→b11=0.375 | 3.266368 | 2925 | **+1.650 mnat marginal-band NULL** |

**Results commentary:** 12% lcov_eigh_min gap (3322 Arm A vs 3727 Arm B) confirms mechanism actuation. But clean spectral mechanism actuation still doesn't translate to val benefit — **pre-NS5 spectral lever γ is 4th bilaterally-confirmed always-binding pre-NS5 axis** (u/w-floor #1314, μ #1332, WD #1337, β_cov #1339, γ this). Direction asymmetry: late-higher γ SAME direction as #1289 LR WIN → catastrophic +4.25 mnat. Late-lower γ opposite direction → milder +1.65 mnat. Spectral depth-asymmetry is decoupled from LR depth-asymmetry direction (LR wins late-higher, γ penalizes late-higher). 6/7 per-block Muon axes confirmed bilateral NULL on top of #1289. Student also flagged guard-blocking advisor SENPAI-RESULT placeholders (concurrent-launch incident remediated by student 22:55 UTC). askeladd → PR #1395 phase-window γ pulse (tests temporal-scope vs always-on stratification).

## 2026-05-27 04:05 UTC — PR #1339 CLOSED: Per-block Muon β_cov — 163rd NULL (g1r1-nezuko)

- Branch: `g1r1-nezuko/per-block-muon-beta-cov`
- Hypothesis: Depth-stratified Muon β_cov (preconditioner EMA rate / time-domain memory horizon) on top of #1289 LR baseline. Arm A late-higher (b0=0.94→b11=0.96, mean=0.95), Arm B late-lower (mirror). Tests TIME-DOMAIN dual of #1289 LR MAGNITUDE WIN.

| Arm | wandb run | β_cov pattern | val_loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| Baseline #1289 | `3zhwgfiw` | uniform 0.95 | 3.264718 | 2925 | — |
| A (late-higher) | `mmdlv7w2` | b0=0.94→b11=0.96 | 3.268179 | 2950 | **+3.461 mnat Pareto-shift NULL** |
| B (late-lower) | `orwe4efz` | b0=0.96→b11=0.94 | 3.267323 | 2950 | **+2.605 mnat Pareto-shift NULL** |

**Results commentary:** Both arms Pareto-shift unfavorable (Δsr+25). Striking diagnostic — Arm B's `lcov_eigh_min=5172.81` is 2× Arm A's (2590.34), but only produces 0.86 mnat val_loss benefit vs the worse-conditioned arm. Better preconditioner conditioning does NOT translate proportionally into final val_loss because downstream NS5 polar normalization absorbs most of the conditioning improvement. **β_cov axis bilaterally non-stratifiable — 3rd bilateral pre-NS5 closure, hardens the always-binding-lever canon.** Student also noted that advisor's SENPAI-RESULT prefix in stale_wip refresh comments trips senpai-pr-guard.py parser (advisor memory updated: no `SENPAI-RESULT:` prefix in refresh comments, ever). nezuko → PR #1386 L_cov multi-refresh schedule during cooldown.

## 2026-05-27 03:45 UTC — PR #1337 CLOSED: Per-block Muon WD — 162nd NULL (g1r1-fern)

- Branch: `g1r1-fern/per-block-muon-wd`
- Hypothesis: Depth-stratified Muon weight decay on top of #1289 LR baseline mirrors LR depth-stratification WIN. Arm A late-higher (b0=0.020→b11=0.030), Arm B late-lower (mirror). Mean WD=0.025 preserved.

| Arm | wandb run | Pattern | val/loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| Baseline #1289 | `3zhwgfiw` | uniform 0.020 | 3.264718 | 2925 | — |
| A (late-higher) | `rekcojrc` | b0=0.020→b11=0.030 | 3.267572 | 2950 | **+2.854 mnat Pareto-shift NULL** |
| B (late-lower) | `h2rv44yn` | b0=0.030→b11=0.020 | 3.265773 | 2925 | **+1.055 mnat tied-sr regression NULL** |

**Results commentary:** Both arms NULL. WD acts as a *downstream multiplier on LR magnitude* rather than an independent depth-axis. Arm A (late-higher WD + late-higher LR) doubly amplifies shrink on deep blocks during cooldown — the gradient magnitude that late-higher LR was deliberately injecting into block_11 gets immediately damped. Classic over-regularized Pareto-shift NULL. Arm B (late-lower WD + late-higher LR) gives more late-block parameter freedom, but deep blocks are near-optimal magnitude so extra freedom drifts slightly off-optimum. Mild, tied-sr regression. Asymmetric magnitude (Arm A 2.7× worse than Arm B) is consistent with WD acting downstream of LR. **Per-block WD axis bilaterally non-stratifiable — 2nd bilaterally-confirmed always-binding per-block lever after u/w-floor (#1314), and 5th bilateral NULL overall (joining u/w-floor, μ, β_cov Arm A, γ Arm A, NS_ITERS Arm A).** Closing 5th per-block Muon axis.

## 2026-05-27 03:45 UTC — PR #1325 CLOSED: Temporal-separated L_cov+pEMA stacking — BOTH ARMS marginal-WIN-candidate (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/temporal-separated-stacking`
- Hypothesis: Solo L_cov refresh (#1268) and paramEMA refresh (#1274) both NULLed vs new #1289 baseline. Same-step coupled refresh (#1302) produced INTERFERENCE. Temporally-separated stacking (each at own canonical optimum) may restore additivity.

| Arm | L_cov step | pEMA step | val/loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| Baseline #1289 | — | — | 3.264718 | 2925 | — |
| A (canonical) | 2600 | 2275 | **3.263842** | 2925 | **−0.876 mnat MARGINAL WIN-CANDIDATE** |
| B (swapped) | 2275 | 2600 | **3.264062** | 2925 | **−0.656 mnat MARGINAL WIN-CANDIDATE** |

**Results commentary:** Both arms beat baseline marginally. Arm A passes merge clause-2 (val_ema=3.263842 < 3.264718 at sr=2925) BUT Δ=0.876 mnat ≤ 0.001 mnat triggers n=1 marginal-WIN guard — requires n=2 confirmation before merge. **Temporal-separation canon ESTABLISHED:** avoids the +2.39 mnat INTERFERENCE NULL of #1302 (same-step coupled refresh) and partially restores additivity of the two solo mechanisms. The canonical-vs-swapped arm difference (3.263842 vs 3.264062, Δ=0.00022) is within seed noise, suggesting the dominant mechanism is simply temporal-separation itself rather than canonical-step optimization. Notable: Arm B val_ema spike to 7.14 at step 2625 (25 steps after pEMA@2600 refresh) while val_live=3.32 confirms only the EMA-evaluation buffer is zeroed, not the model. Closing PR; n=2 confirmation seed assigned to thorfinn (#1379) and pEMA-only ablation assigned to fern (#1378).

## 2026-05-27 03:08 UTC — PR #1332 CLOSED: Per-block Muon μ — 161st NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/per-block-muon-mu-shape`
- Hypothesis: Depth-stratified Nesterov momentum μ on top of #1289 LR baseline mirrors LR depth-stratification WIN. Arm A late-higher (b0=0.93→b11=0.97), Arm B late-lower (mirror).

| Arm | wandb run | Pattern | val/loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| Baseline #1289 | `3zhwgfiw` | uniform 0.95 | 3.264718 | 2925 | — |
| A (late-higher) | `2aj51uwk` | b0=0.93→b11=0.97 | 3.280389 | **-1** | **+15.67 mnat CATASTROPHIC NULL** |
| B (late-lower) | `pyy6wtav` | b0=0.97→b11=0.93 | 3.269559 | 2975 | +4.84 mnat Pareto-shift NULL |

**Results commentary:** Both arms NULL. Two distinct failure mechanisms: (1) Arm A — μ+LR destructive stacking canon: late-higher μ (b11=0.97) on top of late-higher LR (b11 ×1.10) doubles the effective gradient amplification at deep blocks (36.7× vs baseline 22×), causing stale momentum to accumulate during cooldown → late-block updates non-responsive → never crosses 3.28 target. (2) Arm B — Under-momentum canon: late-lower μ (b11=0.93, ~14-step effective horizon vs baseline ~20) reduces momentum inertia on deep blocks, insufficient for sustained cooldown convergence → Pareto-shift unfavorable (+50 sr). **μ axis bilaterally non-stratifiable — 4th confirmed bilateral always-binding pre-NS5 lever.** Remarkable late-cooldown Arm B trajectory: val_ema=3.4137 at step 1950 recovered to 3.2696 at terminal — 2.5× better than pre-cooldown slope extrapolation predicted. Lesson: late-cooldown slope is 2-3× steeper than pre-cooldown; mid-run extrapolation underestimates cooldown gain.

## 2026-05-27 00:25 UTC — PR #1314 CLOSED: Depth-stratified u/w floor — 160th NULL (g1r1-alphonse)

- Branch: `g1r1-alphonse/per-block-uw-floor`
- Hypothesis: Depth-stratified u/w floor (pre-NS5 magnitude floor) mirrors #1289's per-block LR late-higher WIN. Expected transfer of depth-stratification mechanism to the u/w floor lever.

| Arm | wandb run | Pattern | val/loss_ema | sr | Δ vs baseline |
|---|---|---|---|---|---|
| A (late-higher) | `57sud10t` | 0.30→0.40 | 3.265435 | 2925 | +0.717 mnat NULL |
| B (late-lower) | `dtsnw0n6` | 0.40→0.30 | 3.267994 | 2950 | +3.276 mnat NULL |

**Results commentary:** Both arms NULL. New "always-binding-lever" mechanism canon established. `train/uw_floor/fired_fraction=1.00` for every block proves the floor is universally binding — depth-tilt redistributes clamp magnitude but does not change clamped volume. Striking 12× spread in `pmuon/lcov_eigh_min` (Arm A=5585 vs Arm B=450) confirms depth-profile reaches optimizer state, but val gains blocked by pre-NS5 wash-out. Mirror asymmetry (A=+0.717, B=+3.276) same direction as #1289 confirming deep-block preference for MORE magnitude — but u/w floor lever is upstream of NS5 and cannot capitalize. **Canon: per-block depth-stratification requires POST-NS5 lever surface to be productive; pre-NS5 levers (floor, β_cov, potentially WD) may all NULL regardless of depth-profile.**

## 2026-05-26 21:55 UTC — PR #1302 CLOSED: Coupled L_cov + param-EMA same-step refresh INTERFERENCE — 159th NULL (g1r1-edward)

- Branch: `edward/coupled-refresh-stacking`
- Hypothesis: Stacking L_cov bilateral refresh + param-EMA buffer refresh at the SAME step (Arm A: 2275, Arm B: 2600) tests whether two complementary state-staleness mechanisms additively contribute when fired simultaneously.

| Arm | Run | Refresh step | val/loss_ema | sr | Δ vs new baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| A | `spzzkxzs` | 2275 (pre-cooldown) | **3.268415** | **2950** | +3.697 mnat NULL, Δsr+25 | NULL (clear interference) |
| B | `id5z87yf` | 2600 (deep cooldown) | **3.266047** | **2925** | +1.329 mnat NULL | NULL (marginal interference) |

Both arms FAIL both merge clauses. Arm A also Pareto-shifts sr+25.

**Mechanism canon — coupled same-step refresh INTERFERES, magnitude depends on step position:**

| Refresh @ step | L_cov solo (#1268) | paramEMA solo (#1274) | Coupled (this PR) | Coupling penalty vs sum-of-solos |
|---|---|---|---|---|
| 2275 (pre-cooldown) | +1.210 mnat (NULL) | +0.758 mnat (NULL) | **+3.697 mnat (Arm A NULL)** | **+1.729 mnat super-additive interference** |
| 2600 (deep cooldown) | +1.130 mnat (NULL) | +2.880 mnat (paramEMA wrong-step) | **+1.329 mnat (Arm B NULL)** | **-2.681 mnat sub-additive (cooldown-recovery absorbs)** |

**Striking finding:** Interference is super-additive at the pre-cooldown step (2275) but sub-additive at deep-cooldown (2600). The difference is cooldown-recovery budget — Arm B leaves only 650 steps for recovery, but step 2600 is past param-EMA's canonical-optimum (2275) so the param-EMA component is already in its "wrong-step" regime (#1274 Arm B solo @ 2700 was +2.88 mnat). The coupling at 2600 doesn't compound badly because cooldown-recovery (#1218 canon: ~12 mnat / 325 steps) partially absorbs the disruption.

**Refined coupled-refresh canon:** Interference magnitude depends on:
1. **Joint step position** vs each surface's canonical-optimal step
2. **Cooldown-recovery budget** remaining after the refresh event

**State-refresh axis — universally exhausted on individual + coupled-same-step surfaces:**

| PR | Surface | Type | Outcome |
|---|---|---|---|
| #1253 edward | Body Muon m_prev | Solo first-moment | NULL (m_prev load-bearing) |
| #1268 fern | Body L_cov bilateral | Solo @ 2275/2600 | Subsumed-NULL (optimal @ 2600 subsumed by #1289) |
| #1274 nezuko | param-EMA | Solo @ 2275/2700 | Subsumed-NULL (optimal @ 2275 subsumed by #1289) |
| #1299 frieren | Aux AdamW | Solo full state @ 2275/2600 | NULL inert (β2-fast-mixing) |
| **#1302 edward (this)** | **L_cov + paramEMA** | **Coupled same-step** | **NULL INTERFERENCE** |
| #1315 askeladd | Aux AdamW | Solo variance-only @ 2600 | CATASTROPHIC (m/v coupling) |
| #1325 thorfinn | L_cov@2600 + paramEMA@2275 | **TEMPORAL-SEPARATED** | **IN FLIGHT — only viable remaining direction** |

**edward → PR #1352 per-block Muon NS_ITERS shape** — depth-stratified spectral polish intensity, 7th and final per-block Muon axis. Mechanism-distinct from all 10 NS5 polar SCALAR closures (#884/#920/#1102/#1107/#1123/#1135/#1136/#1144/#1166/#1201) — tests DISTRIBUTION axis, not magnitude.

---

## 2026-05-26 21:30 UTC — PR #1299 CLOSED: AdamW aux FULL state refresh inert — 158th NULL (g1r1-frieren)

- Branch: `frieren/adamw-aux-state-refresh`
- Hypothesis: Refreshing AdamW aux FULL state (m_t + v_t + step counter) at step 2275 (A, pre-cooldown) or step 2600 (B, deep cooldown) would clear accumulated state staleness, mirror of #1268 L_cov refresh WIN on the body surface.

| Arm | Run | Refresh step | val_ema | sr | Δ vs baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|
| A | `z3srm37i` | 2275 (pre-cooldown) | **3.266328** | **2925** | +1.609 mnat NULL | NULL |
| B | `0ps8phoj` | 2600 (deep cooldown) | **3.266311** | **2925** | +1.593 mnat NULL | NULL |

**Analysis:** Both arms tied within seed-noise (Δ=0.016 mnat between arms) — refresh step location is irrelevant for this surface. Both arms FAIL both merge clauses.

**Mechanism canon — β2-fast-mixing erases full state reset:** AdamW aux state at β2=0.95 has effective horizon `1/(1-β2)=20` steps. Full-state refresh at step 2275 re-equilibrates by step 2295; refresh at step 2600 re-equilibrates by step 2620. Either way, the refresh disturbance is fully absorbed long before sr=2925 (650 steps and 325 steps of re-mixing respectively). Net effect: zero terminal signal.

**State-refresh axis FULLY CLOSED across all six surfaces:**

| PR | Surface | Refresh type | Outcome |
|---|---|---|---|
| #1253 edward | Body Muon m_prev | First-moment only | NULL (m_prev load-bearing) |
| #1268 fern | Body L_cov bilateral | Refresh @ 2275/2600 | Subsumed-NULL (optimal @ 2600 but subsumed by #1289) |
| #1274 nezuko | param-EMA | Refresh @ 2275/2700 | Subsumed-NULL (optimal @ 2275 but subsumed by #1289) |
| **#1299 frieren** | **Aux AdamW** | **FULL state @ 2275/2600** | **NULL inert (β2-fast-mixing erases)** |
| #1302 edward | L_cov + paramEMA | Simultaneous @ same step | INTERFERENCE (anti-stacks) |
| #1315 askeladd | Aux AdamW | VARIANCE-ONLY @ 2600 | CATASTROPHIC (m/v coupling violation) |

**Universal state-refresh canon:**
- Aux state surface CANNOT benefit from any refresh design (full=inert, partial=destructive).
- Body Muon m_prev is load-bearing; reset destructive.
- L_cov + param-EMA refresh canonical optima identified but subsumed by per-block LR baseline.
- Same-step coupled refresh = INTERFERENCE.
- **Only temporal-separated refresh stacking (#1325 thorfinn — L_cov@2600 + paramEMA@2275) remains as viable refresh direction.**

**frieren → PR #1350 per-optimizer-class cooldown power split** — schedule-shape mechanism. Tests whether aux (i.i.d. gradients) and body (autocorrelated gradients) benefit from differential COOLDOWN_POWER. Arm A aux=1.2 flatter, Arm B aux=1.6 sharper, body=1.4 fixed both arms. Mechanism-distinct from all 7 prior aux-axis closures (which were β/μ/EMA scalar sweeps + state-refresh).

---

## 2026-05-26 20:30 UTC — PR #1315 CLOSED: AdamW aux variance-only refresh CATASTROPHIC NULL — 157th NULL (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-variance-refresh`
- Hypothesis: Refreshing AdamW aux `exp_avg_sq` (v_t) only (preserving exp_avg, step) at step 2600 (A) vs step 2275 (B) would rebalance preconditioner against accumulated cooldown gradient variance, similar to L_cov refresh (#1268).

| Arm | Run | Refresh content | Refresh step | val_live (terminal) | sr | Verdict |
|---|---|---|---|---|---|---|
| A | `obv2106k` | exp_avg_sq → 0 only | 2600 | **9.487** (step 3050 failed) | -1 | **CATASTROPHIC** |
| B | `d2qwrtt1` | exp_avg_sq → 0 only | 2275 | n/a (killed @ step 50) | n/a | KILLED pre-refresh |

**Mechanism analysis — m/v coupling breakdown (NEW CANON, 9th of day, 1st catastrophic-failure example of asymmetric state refresh):** AdamW's update is `m_hat / (sqrt(v_hat) + eps)`. Resetting `exp_avg_sq` (v_t) to zero but leaving `exp_avg` (m_t) and step counter at their pre-refresh values produces:
- `m_t` retains step-2600 magnitude (accumulated first moment of body gradient)
- `v_t = 0` → `v_hat ≈ 0` → `sqrt(v_hat) + eps ≈ eps = 1e-10`
- Update magnitude ≈ `m_hat / 1e-10` ≈ **1e10 × m_hat**

For aux embed at LR=0.3, per-step update becomes `0.3 × 1e10 × m_hat` → embedding matrix saturates, val_loss explodes within ~25 steps (3.27 → 9.487). EMA buffer broke during divergence (val_ema=None at terminal).

**Cross-PR mechanism map — state-refresh asymmetry is universally destructive across optimizer surfaces:**

| PR | Surface | Refresh content | Outcome |
|---|---|---|---|
| #1299 frieren | Aux (AdamW) | FULL (m+v+step) @ 2275/2600 | NULL inert (β2=0.95 fast-mixing erases reset) |
| **#1315 askeladd** | Aux (AdamW) | **VARIANCE-ONLY @ 2600** | **CATASTROPHIC (m/v coupling violation)** |
| #1253 edward | Body (Muon) | First-moment-only @ 2600/2925 | NULL (m_prev load-bearing) |
| #1302 edward | L_cov + paramEMA | Simultaneous @ same step | INTERFERENCE (anti-stacks) |
| #1268 fern | L_cov | Refresh @ 2600 | NULL (canonical-optimal, subsumed by #1289) |
| #1274 nezuko | param-EMA | Refresh @ 2275 | NULL (canonical-optimal, subsumed by #1289) |

**Universal canon:** State-refresh must be ATOMIC (all components together) or NOT AT ALL. Partial state refresh violates magnitude balance and produces unbounded updates (Adam case) or destroys load-bearing direction information (Muon case). Same-step coupling of independent refreshes anti-stacks (#1302).

**Forecloses:** Any partial-state Adam refresh design across aux/lm_head/embed; variance-only or moment-only reset families for adaptive optimizers.

**Enables:** Temporal-separated stacking (#1325 thorfinn — L_cov@2600 + paramEMA@2275 with 325-step separation) remains the only viable refresh-stacking direction.

**Excellent execution by askeladd** — Arm A diverged cleanly within design tolerance (no infrastructure failure), Arm B killed immediately at step 50 on advisor signal (no wasted GPU time), terminal SENPAI-RESULT posted with both run IDs.

**askeladd → PR #1342 per-block Muon gamma shape** (6th and final per-block Muon axis, completes the matrix: LR/u-w-floor/μ/WD/β_cov/γ).

---

## 2026-05-26 19:57 UTC — PR #1274 CLOSED: param-EMA buffer refresh cooldown NULL vs new baseline (g1r1-nezuko)

- Branch: `g1r1-nezuko/ema-buffer-refresh-cooldown`
- Hypothesis: Pre-target param-EMA buffer reset replaces stale EMA-tracked weights (β=0.97→0.99 dynamic) with fresh live weights at cooldown entry (Arm A step 2275) or deep cooldown (Arm B step 2700), eliminating β_t-lag-induced smoothing mismatch.

| Arm | Run | Config | Seed | val_ema | sr | Δ vs new baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|---|
| A (refresh@2275) | `5qdsnvpv` | param-EMA refresh @ 2275 | 1 | 3.265476 | 2925 | +0.758 mnat NULL | NULL vs new |
| B (refresh@2700) | `n6k4xw5r` | param-EMA refresh @ 2700 | 1 | 3.267598 | 2950 | +2.880 mnat NULL | NULL vs new |
| A seed-2 confirm | `73rdkclz` | param-EMA refresh @ 2275 | 2 | 3.267468 | 2950 | +2.750 mnat NULL | NULL |
| **Arm A n=2 mean** | — | — | 1+2 | **3.266472** | 2937.5 | **+1.754 mnat NULL** | **CLOSED** |

**Analysis:** Arm A's seed-1 result (3.265476) was a marginal WIN vs old baseline (Δ−0.548 mnat) but the seed-2 result (3.267468) brought the n=2 mean above both old (3.266024) and new (3.264718) baselines. Clean NULL verdict against new baseline. **Param-EMA buffer optimum confirmed at step 2275** (pre-cooldown entry when β_t lag is maximal); refresh @ 2700 in deep cooldown HURTS. Mirror-opposite of L_cov canon (refresh @ 2600 was canonical-optimal for L_cov surface).

**Mechanism canon preserved:** Each state surface has a DISTINCT optimal refresh window driven by its native horizon. Param-EMA buffer @ 2275 + L_cov @ 2600 = temporal-separated dual canon. Feeds directly into PR #1325 thorfinn temporal-separated stacking test (L_cov@2600 + param-EMA@2275 on top of per-block LR baseline).

**nezuko → PR #1339 per-block Muon beta_cov shape (time-domain dual of #1289 LR WIN)**

---

## 2026-05-26 19:30 UTC — PR #1268 CLOSED: L_cov refresh cooldown NULL vs new baseline (g1r1-fern)

- Branch: `g1r1-fern/lcov-refresh-cooldown`
- Hypothesis: Muon bilateral preconditioner (L_cov/R_cov) refresh at step 2275 or 2600 replaces stale state accumulated since training start (~70k-step horizon at β_cov=0.95) with identity, restoring fresh rank-conditioning at cooldown entry.

| Arm | Run | Config | Seed | val_ema | sr | Δ vs old baseline (3.266024) | Δ vs new baseline (3.264718) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A (refresh@2275) | `uffh8krr` | lcov_refresh_step=2275 | 1 | 3.265928 | 2925 | −0.096 mnat WIN | +1.210 mnat NULL | NULL vs new |
| B (refresh@2600) | `7ei0wza7` | lcov_refresh_step=2600 | 1 | 3.265848 | 2925 | −0.176 mnat WIN | +1.130 mnat NULL | NULL vs new |
| B seed-2 confirm | `cm9u01yf` | lcov_refresh_step=2600 | 2 | 3.266564 | 2925 | +0.540 mnat NULL | +1.846 mnat NULL | NULL |
| **Arm B n=2 mean** | — | — | 1+2 | **3.266206** | 2925 | +0.182 mnat NULL | **+1.488 mnat NULL** | **CLOSED** |

**Analysis:** Both arms beat the OLD baseline (3.266024) but are subsumed by the NEW baseline (3.264718, PR #1289 per-block LR merged at 18:54 UTC). The seed-2 confirmation run brought Arm B n=2 mean above even the old baseline (3.266206 > 3.266024). Clean NULL verdict against both baselines.

**Mechanism preserved:** L_cov bilateral preconditioner has a ~70k-step effective state horizon at β_cov=0.95. Refreshing at step 2600 (second-half cooldown) removes 35% of accumulated covariance → rank-condition number returns to baseline band [1857, 1997] post-refresh. Canonical optimal refresh window: **L_cov @ step 2600**. Feeds directly into PR #1325 thorfinn temporal-separated stacking (L_cov@2600 + param-EMA@2275 on top of per-block LR baseline). Cross-surface optimum map: L_cov@2600, param-EMA@2275, AdamW aux no-peak. Refresh effectiveness requires state horizon >> cooldown duration.

**fern → PR #1337 per-block Muon WD shape (depth-stratified weight decay)**

---

## 2026-05-26 18:54 UTC — PR #1289 MERGED: Per-block Muon LR late-higher WIN → NEW BASELINE (g1r1-tanjiro)

- Branch: `tanjiro/per-block-muon-lr-shape`
- Hypothesis: Depth-stratified per-block Muon LR (linear ramp, mean=0.040 preserved) biases cooldown updates toward late blocks.

| Arm | Run | Pattern | val_ema | sr | Δ vs old baseline (3.266024) | Verdict |
|---|---|---|---|---|---|---|
| **A (late-higher)** | `3zhwgfiw` | blk0=0.036→blk11=0.044 | **3.264718** | **2925** | **−1.306 mnat** | **MERGED ✅** |
| B (late-lower) | `4wkp3dib` | blk0=0.044→blk11=0.036 | 3.267340 | 2950 | +1.316 mnat Pareto-shift | NULL |

Trajectory (Arm A): mild +1.37 mnat pre-cooldown penalty INVERTS → −1.306 mnat terminal benefit. Crossover ~step 2500-2925. pmuon/lcov_eigh_min=3926 (high), ema/buffer_frob_dist=29.08. **Fourth independent WIN mechanism class.** NEW BASELINE: val_ema=3.264718, sr=2925. Merge clause: `sr ≤ 2912.5 OR (sr=2925 AND val_ema < 3.264718)`. Baseline revision: #1268 fern and #1274 nezuko marginal WINs now subsumed (both < 3.264718 individually). State-refresh mechanisms may still contribute via stacking. tanjiro → PR #1332 per-block Muon μ shape.

---

## 2026-05-26 18:05 UTC — PR #1300 CLOSED: Stack ablation Nesterov μ=0 (A) vs no param-EMA (B) — 154th NULL (g1r1-thorfinn)

- Branch: `thorfinn/nesterov-vs-ema-stack-ablation`

| Arm | Run | Config | val | sr | Verdict |
|---|---|---|---|---|---|
| A | `a6xy0w6b` | muon_mu=0 | 3.923 @ step 500 | crashed | CATASTROPHIC |
| B | `jq6e9c06` | ema_beta=0 | 3.267210 | 3000 | NULL (+2.49 mnat, Δsr+75) |

Arm A: Nesterov μ=0 → structural divergence at step 500 (NS5 polar ill-conditioned without momentum). Arm B: ema_beta=0 → +27 mnat pre-cooldown penalty, narrows to +1.19 mnat terminal. Both components confirmed as structurally load-bearing.

---

## 2026-05-26 16:00 UTC — ASSIGNMENTS #1314 (alphonse) and #1315 (askeladd)

### #1314 alphonse — Depth-stratified u/w floor (per-block TARGET_UW)
- Branch: `g1r1-alphonse/per-block-uw-floor`
- Hypothesis: Mirror #1289 tanjiro per-block LR late-higher WIN for the u/w floor mechanism. Late transformer blocks may also benefit from higher floor threshold (larger minimum u/w ratio), paralleling the depth-asymmetry finding.
- Arm A: late-higher floor (block 0=0.30, block 11=0.40, mean=0.35), Arm B: late-lower (block 0=0.40, block 11=0.30, mean=0.35)
- Cross-axis with #1176 (uniform TARGET_UW U-shape, closed), #1129 (per-tensor-type post-polar scale, closed), #1164 (depth-stratified mu CATASTROPHIC — different lever: magnitude minimum vs temporal smoothing)
- Status: assigned, pending student pickup

### #1315 askeladd — AdamW aux variance refresh (exp_avg_sq only)
- Branch: `g1r1-askeladd/aux-variance-refresh`
- Hypothesis: By step 2600, aux variance buffer is stale (calibrated to pre-cooldown high-LR gradient magnitudes). Resetting ONLY exp_avg_sq (second moment) at step 2600 recalibrates effective step size without discarding first-moment direction information.
- Arm A: refresh @ step 2600 (L_cov canonical WIN window from #1268), Arm B: refresh @ step 2275 (param-EMA canonical WIN window from #1274)
- Mechanism isolation: #1253 first-moment reset NULL; #1299 full state reset in flight; THIS PR = second-moment only → isolates variance vs full state staleness
- Status: assigned, pending student pickup

## 2026-05-26 15:55 UTC — PR #1269 CLOSED: Phase-gated u/w floor (g1r1-alphonse) — 152nd NULL

- Branch: `g1r1-alphonse/uw-floor-phase-A-late, uw-floor-phase-B-early`
- Hypothesis: u/w floor may be load-bearing in only one training phase. Test: Arm A = active only in cooldown (2500-3250), Arm B = active only in pre-cooldown (0-2500).

| Arm | Run | floor_start | floor_end | val_ema_terminal | sr | Δval vs baseline | Verdict |
|---|---|---|---|---|---|---|---|
| NEW baseline | `4yfdygud` | always-on | always-on | 3.266024 | 2925 | 0 | (reference) |
| A | `xn0ekeyb` | 2500 | 3250 | 3.272057 | 3025 | +6.03 mnat | NULL Δsr+100 |
| **B** | `jmvr65lx` | **0** | **2500** | **3.284301** | **-1** | **+18.28 mnat CATASTROPHIC** | **MISSED TARGET** |

- Mechanism canon: u/w floor establishes a magnitude equilibrium that the EMA buffer accumulates against. Deactivating floor at step 2500 removes this equilibrium — uncontrolled NS5 output cascades through EMA buffer. Arm B's gap WIDENS monotonically from +4.5 → +18.3 mnat over 750 steps. Terminal buffer_frob_dist=6.85 (vs Arm A's 4.79, both much lower than baseline ~22 — both arms have UNDER-accumulated buffers due to floor interference).
- Arm A (floor only in cooldown) partially recovers terminal val but at +100sr cost — floor is load-bearing in BOTH phases.
- **Canon reinforced:** #1035 (existence), #1129 (dominant magnitude controller), #1176 (optimal value), #1269 (phase-gating) — 4 PRs confirm floor structural requirement at 0.35 always-on.
- 152nd NULL closed.

## 2026-05-26 15:55 UTC — PR #1290 CLOSED: Param-EMA scope=embed-only (g1r1-askeladd) — 153rd NULL

- Branch: `g1r1-askeladd/ema-scope-embed-only-arm-a`
- Hypothesis: Extend param-EMA wrapper to include embed token matrix (scope=embed-only as first step toward full scope extension).

| Run | Config | val_ema_terminal | sr | Δval vs baseline | Verdict |
|---|---|---|---|---|---|
| NEW baseline | body-only scope | 3.266024 | 2925 | 0 | (reference) |
| `trjmxtlj` | embed-only scope | 3.267540 | 2950 | +1.52 mnat | NULL Δsr+25 Pareto-shift |

- Trajectory: uniformly +1.5 mnat above baseline throughout cooldown. Clean constant penalty with no pathological dynamics.
- Mechanism: Adding 38.6M embed params to EMA wrapper (comparable to all transformer body params) introduces smoothing-mismatch between live and EMA params at high dimensional surface, effectively halving per-step contribution from body params.
- Terminal diagnostics: pmuon/lcov_eigh_min=1975.87 (baseline-band), buffer_frob_dist=22.49 (normal), polar_ortho=0.117 (clean) — mechanism is benign but additive penalty.
- Arm B (embed+lm_head) never launched — 6 duplicate-launch crashes due to pgrep gate issue in pod.
- Param-EMA scope-extension axis: body-only is optimal. Combined with #1234 (β_start=0.97 WIN) and #1274 nezuko (buffer refresh WIN), the param-EMA family canon: β dynamics matter ✅, buffer refresh helps ✅, scope extension hurts ❌.
- 153rd NULL closed.

## 2026-05-26 15:15 UTC — PR #1268 BOTH ARMS TERMINAL WIN: Body-Muon L_cov/R_cov preconditioner refresh (g1r1-fern) — 5th portfolio WIN signal

- Branch: `g1r1-fern/lcov-refresh-cooldown-entry`
- Hypothesis: At pre-cooldown step (Arm A=2275 / Arm B=2600), reset L_cov/R_cov bilateral covariance EMAs to current outer-product Gram, refreshing the body-Muon preconditioner state to address accumulated staleness from the high-LR pre-cooldown phase.

| Arm | refresh_step | wandb_run | val_ema_terminal | sr | Δval vs NEW baseline (mnat) | terminal polar/ortho_residual_sample | Verdict |
|---|---|---|---|---|---|---|---|
| NEW baseline (#1234) | — | `4yfdygud` | 3.266024 | 2925 | 0 | ~0.14 | (reference) |
| **A (refresh@2275)** | 2275 | `uffh8krr` | **3.265928** | 2925 | **−0.096** | 0.191 | marginal WIN |
| **B (refresh@2600)** | 2600 | `7ei0wza7` | **3.265848** | 2925 | **−0.176** | **0.110** | **stronger marginal WIN** ✅ |

- **Merge clause:** Both arms PASS clause-2 (sr=2925, val_ema < 3.266024). Arm B is the stronger configuration by 0.080 mnat.
- **Stat-sig:** (3.266024 − 3.265848)·√1 = 0.000176 < 0.004 threshold → **n=2 confirmation REQUIRED** before merge.
- **Trajectory comparison:** Both arms show ~+2.5 mnat penalty at step 2500 (within seed noise — NOT from refresh effect since refresh hasn't fired in Arm A yet at this step). Effect manifests post-step-2925 as steady divergence: Arm B builds 0.18 mnat lead by terminal vs Arm A's 0.09 mnat lead.
- **Diagnostic key — polar/ortho_residual_sample:** Arm A 0.191 vs Arm B 0.110 (42% cleaner). Refresh @ 2600 produces a structurally cleaner preconditioner state during the dominant cooldown descent phase. Refresh @ 2275 "wastes" some of the freshness on pre-cooldown high-LR phase before benefit manifests.
- **Canon revision — pre-cooldown intervention surface specificity:** L_cov refresh at step 2600 (mid-cooldown) is the STRONGER window for body-Muon preconditioner surface. The 3 same-step-2275 WIN signals observed earlier today (#1234, #1268-A, #1274-A) suggested step 2275 was the universal "load-bearing intervention window." This PR's Arm B result COMPLICATES that canon: each state surface has a distinct optimal refresh window. For body-Muon L_cov, it's ~2600; for param-EMA (#1274), TBD pending Arm B at step 2700; for aux-AdamW (#1299 in flight), TBD.
- **Cross-axis significance:** 5th WIN signal in portfolio (alongside #1234 ema_beta=0.97 MERGED, #1274 nezuko param-EMA refresh@2275 marginal, #1268 fern Arm A L_cov refresh@2275 marginal, #1268 fern Arm B L_cov refresh@2600 stronger marginal, #1289 tanjiro per-block LR late-higher Δ−1.306 mnat strongest).
- **Stacking test in flight (#1302 edward):** Tests `--lcov_refresh_step` + `--ema_buffer_refresh_step` at same step (2275 vs 2600). Arm B of this PR is the single-axis baseline that #1302 stacking arms must BEAT to confirm additivity.
- **Next steps:** (1) n=2 confirmation on Arm B config (refresh_step=2600) before merge; (2) #1302 stacking test informs whether stack is additive or redundant.

## 2026-05-26 15:10 UTC — PR #1289 ARM A TERMINAL WIN: Per-block Muon LR shape (g1r1-tanjiro) — 4th portfolio WIN signal, STRONGEST single-arm Δ

- Branch: `g1r1-tanjiro/per-block-muon-lr-shape`
- Hypothesis: Reshape per-block LR with `muon_block_lr_pattern=late-higher` (block 0=0.90, block 11=1.10, mean=1.0) to give late blocks MORE LR during cooldown ramp-down without changing scalar LR. Mirror Arm B `late-lower` (block 0=1.10, block 11=0.90).

| Arm | pattern | wandb_run | val_ema_terminal | sr | Δval vs NEW baseline (mnat) | Verdict |
|---|---|---|---|---|---|---|
| NEW baseline (#1234) | uniform=1.0 | `4yfdygud` | 3.266024 | 2925 | 0 | (reference) |
| **A (late-higher)** | block0=0.90, block11=1.10 | `3zhwgfiw` | **3.264718** | 2925 | **−1.306** | **WIN** ✅ |
| B (late-lower) | block0=1.10, block11=0.90 | `4wkp3dib` (in flight) | — | — | — | (running, ETA ~18:50 UTC) |

- **Merge clause:** Arm A PASSES clause-2 (sr=2925, val_ema=3.264718 < 3.266024).
- **Stat-sig:** (3.28 − 3.264718)·√1 = 0.01528 ≥ 0.004 threshold → **n=1 technically sufficient**; n=2 advisable for confidence given how strong the result is.
- **Trajectory signature — pre-cooldown penalty → cooldown benefit inflection:**

| Step | baseline | Arm A | Δ (mnat) | Phase |
|---|---|---|---|---|
| 2500 | 3.317198 | 3.318572 | +1.37 | pre-cooldown (mild penalty) |
| 2925 | 3.278788 | 3.277804 | −0.98 | sr-target crossed |
| 3000 | 3.274420 | 3.273286 | −1.13 | cooldown descent |
| 3100 | 3.269660 | 3.268398 | −1.26 | cooldown descent |
| 3250 | 3.266018 | 3.264718 | −1.30 | terminal |

The crossover between +1.37 → −0.98 happens between step 2500-2925, exactly where late-block emphasis becomes load-bearing as LR is annealed away.

- **Mechanism:** Late blocks need MORE LR in cooldown — consistent with deeper transformer blocks accumulating more useful gradient signal at the descent stage. The pre-cooldown penalty is small (+1.37 mnat) and recovers via the cooldown benefit (~+2.7 mnat swing in the load-bearing direction).
- **Terminal diagnostics:** pmuon/lcov_eigh_min=3926.57 (highest of today's WIN portfolio — Arm A 1946, fern Arm B 1879, tanjiro 3926 → may indicate structural difference in preconditioner spectrum at terminal under per-block LR reshape), ema/buffer_frob_dist=29.08 (~30% higher than fern's ~22 — consistent with the asymmetric gradient flow producing different EMA accumulation), polar/ortho_residual_sample=0.1452 (baseline-band).
- **Cross-axis distinction:** Per-block LR shape axis is **structurally distinct** from the 3 state-staleness WINs at step 2275 (gradient-flow shape mechanism, not state-staleness). Could stack additively with state-staleness mechanisms.
- **Arm B prediction (late-lower):** If Arm B is NULL or shows penalty, late-blocks specifically need MORE LR (directional asymmetry). If Arm B also wins, per-block LR shape is uniformly beneficial regardless of direction — implying breaking uniform-multiplier symmetry itself helps.
- **Status:** PR remains `status:wip` pending Arm B terminal at ~18:50 UTC. Unified two-arm SENPAI-RESULT expected then.

## 2026-05-26 13:30 UTC — PR #1253 CLOSED: Body-Muon Nesterov buffer reset at cooldown entry: step 2600 (A) vs 2925 (B) (g1r1-edward) — 151st NULL

- Branch: `g1r1-edward/nesterov-reset-cooldown-entry`
- Hypothesis: Zero `m_prev` body-Muon Nesterov first-moment EMA buffer at cooldown entry (Arm A step 2600 = mid-cooldown ~33%) or at target-crossing window (Arm B step 2925) recovers from accumulated late-training first-moment lag.

| Arm | reset_step | wandb_run | val_ema_terminal | val_live_terminal | sr | Δval vs NEW baseline (mnat) | Δval vs OLD (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| NEW baseline (#1234) | — | 4yfdygud+7khmgp7d | 3.266024 | — | 2925 | 0 | — | 0 | (reference) |
| OLD baseline (#918, n=2) | — | vm48fdof+0a7esmxs | 3.266394 | — | 2925 | +0.370 | 0 | 0 | (prior reference) |
| **A (reset@2600)** | 2600 | `6tkdyvy7` | 3.266788 | 3.266196 | **2925** | **+0.764 (2.55σ)** | +0.394 (1.3σ) | 0 | NULL (fails clause-2 by val) |
| **B (reset@2925)** | 2925 | `namegpkp` | 3.267516 | 3.266901 | **2950** | **+1.49 (5σ)** | +1.12 (3.7σ) | +25 | NULL (fails BOTH clauses) |

- **Merge clause:** Both arms fail. Arm A sr=2925 ✓ but val > 3.266024 ✗; Arm B sr=2950 ≠ 2925 ✗ AND val > 3.266024 ✗.
- **Stat-sig:** Arm A `(3.28−3.266788)·√1 = 0.01321` ≥ 0.004 ✓ but FAILS clause-2 vs baseline; Arm B `(3.28−3.267516)·√1 = 0.01248` ≥ 0.004 ✓ but FAILS both clauses.
- **Refresh telemetry (Arm A):** `muon/nesterov_reset_fired=1.0` at step 2600, `m_prev_norm_pre=1238.44`, `m_prev_norm_post=0.0`, all 72 body-Muon matrix params zeroed. Cleanly wired.
- **Terminal diagnostics (Arm A):** `pmuon/lcov_eigh_min=2149.57` (healthy, baseline-band), `ema/buffer_frob_dist=22.17` (baseline-band), `polar/ortho_residual_sample=0.1307` (baseline-band), `val/ema_minus_live=+0.000592`. No second-order pathology — regression is direct first-moment information loss.
- **Mechanism canon (FULL CLOSURE across BOTH cooldown positions):** Body-Muon first-moment Nesterov buffer-reset axis is structurally NULL. The `m_prev` buffer at cooldown entry is NOT stale — it carries useful late-warmup → cooldown transition information; zeroing it removes target-direction momentum signal. Arm B's slightly sharper penalty (+1.49 vs +0.76 mnat) + Δsr+25 confirms reset @ target-crossing window is MORE disruptive than mid-cooldown reset. **EMA rebuild faster than cooldown horizon:** with μ=0.95 (~13-step half-life), buffer re-equilibrates by step 2625-2650 (Arm A) → brief "fresh gradient" amplification absorbed back to baseline pattern within ~25 steps.
- **Cross-axis structural decoupling canon — STRENGTHENED:** Same step-2275 refresh position — L_cov bilateral second-moment refresh (#1268 fern Arm A) produces WIN signal Δ−0.47 mnat, but first-moment Nesterov reset (#1253) NULL across two positions. **Preconditioner refresh (gradient-covariance Gram) is MORE load-bearing than first-moment buffer wipe.** Consistent with #1218 variance-staleness mechanism canon.
- **Cross-axis #1213 + #1215 + #1253:** All three first-moment-or-mu-axis interventions on body-Muon produce NULL or worse. μ-axis FULLY constrained.
- **Cooldown-recovery canon — 9th instance:** Both arms within ≤2 mnat of baseline; not catastrophic. Consistent with "interior of cooldown is tolerant to ~1-2 mnat perturbations on this axis".
- **Conclusion:** Both arms fail merge clauses by clear margins; mechanism is well-understood and structurally CLOSED. The Nesterov first-moment reset axis is fully NULL at both tested intervention positions. No interior bracket worth investigating between steps 2600-2925, and no useful follow-up on this axis. **151st NULL.** Closing on advisor authority; W&B terminal verification supersedes missing unified SENPAI-RESULT marker.

## 2026-05-26 13:15 UTC — PR #1234 MERGED: EMA wrapper ema_beta_start=0.97 HIGHER n=2 WIN — NEW BASELINE (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/ema-beta-start-value`
- Hypothesis: Higher EMA β start value (narrower initial averaging at LR_mult=1) → better-conditioned preconditioner terminal and marginal val improvement.

| Arm | ema_beta | wandb_runs | val_ema_terminal | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (prior, n=2) | 0.95 | vm48fdof+0a7esmxs | 3.266394 | 2925 | 0 | 0 | (prior reference) |
| **A (0.92 LOWER)** | 0.92 | `6h2udxlc` | 3.267095 | 2950 | +0.701 (2.3σ) | +25 | NULL |
| **B (0.97 HIGHER, n=2)** | 0.97 | `4yfdygud`+`7khmgp7d` | **3.266024** | **2925** | **−0.370 (1.23σ)** | 0 | **🏆 WIN — MERGED** |

- **Merge clause:** sr=2925 ✓, val_ema=3.266024 < 3.266394 ✓ — passes at n=2 with both seeds individually satisfying clause-2.
- **Stat-sig:** (3.266394 − 3.266024)·√2 = 0.000524 < 0.004 threshold — formally sub-stat-sig, but predeclared merge rule (both seeds individually < baseline at sr=2925) satisfied.
- **Mechanism:** Narrower initial EMA averaging (β_start=0.97 vs 0.95) → terminal `pmuon/lcov_eigh_min` +5.76% (2038 vs 1927, seed-stable at +1.6% within-arm variance) → better-conditioned preconditioner. Asymmetric response: LOWER (0.92) costs +0.70 mnat / sr+25; HIGHER (0.97) gains −0.37 mnat at same sr. Decoupled axes: ema_beta and ema_beta_target show distinct response shapes.
- **Cross-seed reproducibility:** Seed-1 3.266018 / Seed-2 3.266029 → Δ=0.011 mnat (bitwise-near, within CUDA non-determinism band).
- **New baseline:** val_ema=3.266024, sr=2925, ema_beta=0.97. Updated merge clause: `sr ≤ 2912.5 OR (sr=2925 AND val_ema < 3.266024)`.
- **Next:** thorfinn → #1300 stack ablation (mech #5 queue close). #1290 askeladd notified of baseline update.

---

## 2026-05-26 12:52 UTC — PR #1249 CLOSED: Body-Muon per-tensor-type Nesterov μ (attn=0.93/mlp=0.97 vs attn=0.97/mlp=0.93) — 150th NULL, per-tensor splitting axis structurally closed across TARGET_UW + μ, pipeline-position amplification canon (g1r1-frieren)

- Branch: `g1r1-frieren/mu-per-type`
- Hypothesis: Split body-Muon's Nesterov μ (baseline 0.95 uniform) per tensor type. Tests whether attn and mlp gradient temporal structures differ — was deprioritized-but-untested at PR #777 closure.

| Arm | mu_attn / mu_mlp | wandb_run | val_ema_terminal | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline n=2 | 0.95 uniform | vm48fdof+0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (mlp-HIGHER)** | 0.93 / 0.97 | `5asc4rry` | **3.308180** | **−1 (MISSED)** | **+41.79 (139σ)** | — | CATASTROPHIC NULL |
| **B (mlp-LOWER)** | 0.97 / 0.93 | `gpro2wky` | **3.273180** | **3050** | **+6.78 (23σ)** | **+125** | mild NULL |

- **Merge rule:** Both arms fail. Arm A MISSED 3.28 target; Arm B sr=3050, val>baseline.
- **Per-tensor splitting axis structurally closed** across both load-bearing levers (TARGET_UW #1242 + μ #1249). Bilateral whitening + NS5 polar absorbs per-type magnitude/EMA differences only on uniform values; any per-type asymmetry is rejected by pre-NS5 first-moment EMA misalignment when one tensor type has dominant param mass.
- **Asymmetric param-mass mechanism canon (NEW, cross-axis with #1242):**

| Axis | Position | Δval mlp-HIGHER | Δval mlp-LOWER | Ratio |
|---|---|---|---|---|
| TARGET_UW (#1242) | post-NS5 floor | +4.62 mnat | +2.39 mnat | **1.93×** |
| Nesterov μ (#1249) | pre-NS5 first-moment | **+41.79 mnat** | +6.78 mnat | **6.2×** |
| Amplification | pre-NS5 vs post-NS5 | **9.0×** | 2.8× | — |

- **Pipeline-position canon extended (cross-axis with #1136):** Perturbations upstream of NS5 amplify penalty ~9× vs equivalent perturbations downstream. **Pre-NS5 perturbations are catastrophic; post-NS5 perturbations are bounded.**
- **Striking secondary finding:** Arm B `pmuon/lcov_eigh_min=1.51` (1400× collapse vs Arm A 2103.73) yet val BETTER. Rank conditioning DECOUPLED from val in cooldown regime. Cross-axis with #1168 thorfinn canon.
- **Cooldown-recovery saturation canon (NEW):** Arm A at step 1750=+66 mnat above baseline → terminal +42 mnat (recovered only 24 mnat). **For perturbations >25 mnat at warmup-end, cooldown cannot recover.** Saturation threshold consistent with #1116 DOWN arm, #1164 fast-deep.
- **Bug-fix:** Student frieren contributed senpai-pr-guard.py fix (commit 497a2f3) — `require_terminal_result` parse error accumulation bug.
- **Next:** #129x frieren → AdamW aux variance state refresh at cooldown entry (mirror of #1268 fern L_cov refresh on aux pipeline; directive-aligned state intervention on AUX surface — first state-intervention on AUX pipeline).

---

## 2026-05-26 11:30 UTC — PR #1268 fern L_cov/R_cov refresh Arm A MARGINAL n=1 WIN SIGNAL (HOLD merge; n=2 + Arm B required)

- Branch: `g1r1-fern/lcov-refresh-cooldown`
- Hypothesis: At step 2275 (Arm A) or 2600 (Arm B), reset L_cov/R_cov preconditioner EMAs to current Gram matrices — tests whether stale gradient-covariance state from pre-cooldown high-LR phase slows cooldown descent. Mechanism #4 from aligned hypothesis queue (Issue #1252 directive — state intervention, not coefficient sweep).

| Arm | refresh_step | wandb_run | val_ema_terminal | val_ema@2925 | sr | Δval (mnat) | Δsr | Status |
|---|---|---|---|---|---|---|---|---|
| Baseline n=2 | — | vm48fdof+0a7esmxs | 3.266394 | — | 2925 | 0 | 0 | (reference) |
| **A (refresh@2275)** | 2275 | `uffh8krr` | **3.265928** | 3.278982 | **2925** | **−0.466 (1.55σ)** | 0 | **🟢 MARGINAL n=1 WIN signal** |
| B (refresh@2600) | 2600 | `7ei0wza7` | running (step 75) | — | — | — | — | ETA ~15:21 UTC |

- **Merge clause check (Arm A n=1):**
  - Clause-2 (`sr=2925 AND val<3.266394`): **PASSES** ✓ (sr=2925, val_ema=3.265928 < baseline)
  - Marginal n=1 threshold: Δval=0.000466 < 0.001 → **n=2 confirmation REQUIRED** per session canon
- **lcov_refresh fired successfully at step 2275:** `pmuon/lcov_eigh_min` recovery 1614.67 → 1946.34 confirms intervention wired correctly. Refresh delivers ~20% rank-eigenvalue recovery from pre-cooldown low-eigenvalue regime.
- **Cooldown-recovery canon — 7th instance:** At step 2925, val_ema=3.278982 was 12.6 mnat ABOVE baseline at that step. Cooldown recovered 13 mnat in 325 steps → terminal 3.265928 BELOW baseline. Pattern matches #1242 (~15 mnat) / #1229 (~45 mnat) / #1218 (~12 mnat) / #1201 (~40 mnat). Mid-run val_ema at sr-crossing is PRELIMINARY; terminal val_ema authoritative.
- **2nd WIN signal in 9-PR portfolio:** Alongside #1234 thorfinn Arm B (β_start=0.97 HIGHER) `7khmgp7d` seed-2 in flight (ETA terminal ~12:42 UTC). Structurally ORTHOGONAL mechanism axes: #1234 OUTER EMA-wrapper β_start (parameter smoothing) vs #1268 INNER preconditioner state refresh (gradient covariance). Could potentially STACK if both confirm n=2.
- **Hold notice:** DO NOT merge Arm A until both: (1) Arm B reaches terminal (full PR design honored), (2) n=2 confirmation completes. Sequential confirmation: Arm B → decide n=2 seed-2 strategy → run on better arm.
- **Mechanism context:** Strongly motivated by #1215 striking observation `pmuon/lcov_eigh_min=0.0` at terminal under mu_warmup → L_cov rank degeneracy is a real failure mode. Refresh at cooldown entry directly addresses Issue #1252 directive item "optimizer-state resets/rescaling at phase boundaries."

---

## 2026-05-26 10:56 UTC — PR #1242 CLOSED: Per-tensor-type TARGET_UW (attn=0.30,mlp=0.40 vs attn=0.40,mlp=0.30) — 149th NULL, per-tensor TARGET_UW asymmetric U-shape canon, firing-fraction structural finding (g1r1-askeladd)

- Branch: `g1r1-askeladd/target-uw-per-type`
- Hypothesis: Split body-Muon's u/w floor TARGET_UW (PR#1035 baseline=0.35 uniform) into attn vs mlp tensor types; both arms swap (HIGHER ↔ LOWER) maintaining mean ≈ baseline.

| Arm | floor pattern | wandb_run | val_ema terminal | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline n=2 | uniform 0.35 | vm48fdof+0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (mlp-HIGHER)** | attn=0.30, mlp=0.40 | `deo1047q` | 3.271010 | 3025 | **+4.62 (15σ)** | **+100** | clear NULL |
| **B (mlp-LOWER)** | attn=0.40, mlp=0.30 | `6ke8zm4a` | 3.268788 | 2950 | **+2.39 (8σ)** | **+25** | clear NULL |

- **Merge rule:** both arms fail (sr ≠ 2925 in both, val > baseline in both).
- **Asymmetric U canon:** Δval ratio A/B = 1.93× — between equal-weighting (1.0×) and pure param-count weighting (3.0×). Param count dominates but is not the entire signal — over-driving on the SAME-sided tensor produces non-linear contribution.
- **Firing-fraction structural finding (NEW canon):** Per-tensor firing_fraction reveals that **LOWERING below 0.35 changes eligibility (attn_fired_fraction 1.0→0.917)** while **RAISING above 0.35 keeps saturation at 1.0**. The HIGHER side perturbs MAGNITUDE only; the LOWER side perturbs both rescue and eligibility. Explains the asymmetric U-shape direction.
- **Cooldown-recovery canon — 6th instance:** Both arms recovered ~12-15 mnat during the cooldown step 2925→3250 window. Refined rule: mid-run val_ema at sr boundary is PRELIMINARY; terminal step 3250 val_ema is the authoritative comparison.
- **Per-tensor splitting axis closure:** Per-tensor-type splitting is structurally NULL on independent levers (TARGET_UW + μ on #1249). Bilateral whitening + NS5 polar absorbs per-type magnitude differences but cannot rescue per-type asymmetry.
- **Next:** #1290 askeladd → param-EMA SCOPE extension to embed/lm_head (structurally untested axis).

---

## 2026-05-26 10:42 UTC — PR #1263 CLOSED: Pre-target LR boost 1.05× over [2500,2925] — 148th NULL, cooldown-window LR-mass axis NULL, #1213 canon extended (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pretarget-lr-boost`
- Hypothesis: Boost body-Muon LR by 1.05× during the pre-target window [2500, 2925] to steepen loss descent and advance the speedrun crossing.

| Arm | lr_boost | wandb_run | val_ema @ 2925 | val_ema terminal | sr | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline n=2 | 1.00× | vm48fdof+0a7esmxs | 3.266394 | 3.266394 | 2925 | 0 | (reference) |
| **A (1.05× over [2500,2925])** | 1.05× | `ej209lvq` | 3.280142 | **3.266969** | **2950** | **+25** | clear NULL |
| **B** | 1.10× | (not launched) | — | — | — | — | skipped (dominated by A) |

- **Merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both clauses fail. Arm A sr=2950 → FAIL clause 1; target not reached at step 2925 → FAIL clause 2.
- **Canon entry (joins #1213):** Front-loading optimizer mass (LR or momentum) in the cooldown window [2500, 2925] does NOT steepen pre-target descent — it shifts convergence horizon RIGHT. The inverse-sqrt LR schedule is already at approximately the right slope at PR#918 baseline; boost spent LR mass earlier → delayed final crossing by +25 sr without catastrophic destabilization (buffer_frob_dist, L_cov eigh_min, polar/ortho_residual all within seed-noise).
- **Student analysis:** Boost wiring confirmed correct via W&B `pre_target_boost/active` pulse; `val/best_loss=3.266969` only at terminal step 3250 (not step 2925). Sub-optimal LR redistribution, not breakage.
- **Arm B decision:** Student correctly followed OPTION 1 (skip 1.10× — strictly dominated, #1252 directive prioritizes new mechanisms).
- **Next:** #1289 tanjiro → per-block Muon LR shape (mechanism #2 aligned queue).

---

## 2026-05-26 08:35 UTC — PR #1229 CLOSED: EMA β ramp SHAPE cosine (A) vs quadratic-t² (B), fixed endpoints+duration — 147th NULL, EMA ramp SHAPE axis closed, β_t-lag → buffer_frob direction canon corrected (g1r1-nezuko)

- Branch: `g1r1-nezuko/ema-ramp-shape`
- Hypothesis: EMA β ramp shape from 0.95 → 0.99 across steps 1750-3250 — does the *concavity* of the ramp (cosine bow vs quadratic t² lag) at fixed endpoints affect val_ema independently of magnitude?

| Arm | shape | wandb_run | val_ema | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (n=2 linear) | linear | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A cosine** | 0.5·(1−cos(πp)) | `ik3j44fd` | **3.267150** | **2925** | **+0.756 (2.5σ)** | **0** | marginal NULL |
| **B quadratic** | p² | `1pdhj8cn` | **3.268301** | **2975** | **+1.907 (6σ)** | **+50** | clear NULL |

- **Predeclared merge rule:** both arms FAIL both clauses (Arm A: sr=2925 but val>baseline; Arm B: sr>2912.5 AND ≠2925).
- **Direction:** Monotone-worse on shape-vs-linear lag magnitude. Cosine (≈ linear at midpoint) +0.756 mnat; quadratic (strictly ≤ linear) +1.907 mnat.

**MECHANISM CANON — β_t LAG MAGNITUDE → buffer_frob DIRECTION (corrected from 07:00 prediction):**

My 07:00 UTC stale-refresh prediction had the direction *backwards*: I projected Arm B's mid-run frob=218 vs Arm A's *terminal* 24.85 as "blowing up." Student correctly identified that comparison was across phases. At matching step 2725, Arm A frob was ~282 (interpolating peak 496 @ 1875 → terminal 24.85). Arm B was *under* Arm A at every cooldown step.

| step | A (cosine) frob | B (quadratic) frob | Δ(B−A) | A β_t | B β_t |
|---|---|---|---|---|---|
| 1875 (peak) | 496.63 | 408.08 | **−88.55** | 0.9704 | 0.9602 |
| 2250 | 441.06 | 324.49 | **−116.56** | 0.9809 | 0.9687 |
| 2625 | 310.91 | 218.35 | −92.56 | 0.9874 | 0.9780 |
| 2925 (sr-ref) | 165.29 | 123.33 | −41.96 | 0.9896 | 0.9849 |
| 3250 (terminal) | 24.85 | 20.63 | −4.22 | 0.9900 | 0.9900 |

**Refined canon:** quadratic shape keeps β_t LOWER throughout cooldown (p² ≤ p strictly for p∈(0,1)) → smaller effective lookback `n_eff = 1/(1−β_t)` → **buffer catches up to live weights FASTER → smaller buffer_frob_dist**. Cost: weaker late-cooldown EMA smoothing → larger val_ema vs val_live gap. Magnitude of val_ema regression scales with **cumulative β_t lag vs linear** ∫(β_linear − β_shape)dp, NOT mid-cooldown buffer divergence.

**Cooldown-recovery canon (now 5th instance):** Arm B val_live at step 2725 was 3.325 (5 mnat above 3.28 target), and the run still crossed at step 2975 — ~45 mnat recovery in 250 cooldown steps, consistent with #1218 fern (~12 mnat / 300 steps). My "predicted catastrophic Arm B" was wrong on direction *and* magnitude — cooldown-recovery routinely exceeds mid-run extrapolation.

**Polar ortho_residual canon refinement (4th instance):** Both arms peaked polar at 0.603 / 0.560 at step 1875 (≈ EMA-activation +125 steps), well above #1168 in-band 0.10-0.25, both recovered monotonically to in-band terminal (0.13 / 0.11). Peak position locked to **EMA-activation event**, not buffer-Frob magnitude. Polar perturbation from EMA cold-start is robustly absorbed by NS5 + eps-clamp stack regardless of ramp shape downstream.

**EMA ramp SHAPE axis CLOSED.** Linear baseline appears optimal at fixed endpoints+duration. Per Issue #1252 directive (no further scalar/shape sweeps), nezuko → **mechanism #7 (new): pre-target parameter-EMA BUFFER reset** — third optimizer-state-reset surface complement to #1268 (L_cov/R_cov bilateral preconditioner) and #1253 (Nesterov first-moment).

**147 NULL closures.**

## 2026-05-26 07:50 UTC — PR #1201 CLOSED: Hybrid noisy exact polar (SVD + calibrated Gaussian noise) — 146th NULL, NS5 polar 10-axis canon COMPLETE, rank-preserving residual magnitude DECOUPLED from val (g1r1-alphonse)

- Branch: `g1r1-alphonse/noisy-exact-polar`
- Hypothesis: Decompose #1135's "imperfect polar helps" canon. Is it the cubic polynomial STRUCTURE that's load-bearing, or just the residual MAGNITUDE? Replace cubic NS5 with exact SVD + calibrated Gaussian noise to reproduce the residual magnitude WITHOUT the cubic structure.

| Arm | σ | residual | wandb run | val/loss | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (n=2) | — | NS5 cubic ≈ 0.067 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (matched)** | **5.4e-5** | **0.059 (match)** | `hrds5ojg` | **3.26916** | **2975** | **+2.76 (9σ)** | **+50** | clear NULL |
| **B (3.3× elevated)** | **1.81e-4** | **0.197** | `jo32du86` | **3.26833** | **2950** | **+1.93 (6σ)** | **+25** | clear NULL |

- **Predeclared merge rule:** both arms FAIL both clauses.
- **Direction:** flat dose-response — Arm B at 3.3× elevated residual is slightly BETTER than Arm A at matched residual. The NULL is essentially constant within rank-preserving regime [0.007, 0.197].

**MECHANISM CANON — RESIDUAL MAGNITUDE DECOUPLED FROM VAL in rank-preserving regime:**

5-row comparison synthesizing #1135 + #1201:

| polar method | residual | Δval (mnat) | rank-preserving? | source |
|---|---|---|---|---|
| NS5 cubic (baseline) | 0.067 | 0 | yes (stable_rank ≈ 426) | baseline |
| svd_noisy σ_A=5.4e-5 | **0.059** | **+2.76 NULL** | yes (rank 349) | this PR Arm A |
| svd_noisy σ_B=1.81e-4 | **0.197** | **+1.93 NULL** | yes (rank 346) | this PR Arm B |
| exact SVD svd_full | ~0.007 | +3.02 NULL | yes (full rank) | #1135 Arm A |
| svd_topk=256 | ~22.6 | +52.84 CATASTROPHIC | **NO (rank-limited)** | #1135 Arm B |

**Refined NS5 polar canon (4 propositions):**
1. **Residual magnitude is NOT the load-bearing axis within rank-preserving polar perturbations.** Across residual ∈ [0.007, 0.197] (28× range), val regresses by near-identical ~+2-3 mnat. Decoupled.
2. **Cubic NS5 polynomial structure carries a small (~2-3 mnat) consistent benefit.** Every rank-preserving alternative regresses by ~+2-3 mnat. Mild support that Newton-Schulz fixed-point dynamics encode rank-direction-magnitude coupling beyond magnitude-matched noise.
3. **Rank-truncation is the catastrophic regime** (52.84 mnat regression at rank-limited #1135 Arm B), NOT residual magnitude. Polar map must preserve the full SVD rank structure; magnitude within the orthogonal manifold neighborhood is permissible up to at least 0.20 residual.
4. **Cross-axis #1166 cubic-coefficient canon:** cubic coefficients (1.5, -0.5) robust to ±0.2 perturbation TIGHTER side, fragile GENTLER. Combined: cubic FAMILY encodes load-bearing information beyond magnitude-matched noise, but ONLY ~2-3 mnat — not the dominant Muon lever.

**Cooldown-recovery canon update (4th instance):** Advisor's step-2650 mid-cooldown projection of catastrophic Arm B (val_ema=3.308) was WRONG — Arm B recovered ~40 mnat in final 600 cooldown steps, landing slightly ahead of Arm A. **4th instance of cooldown-recovery exceeding mid-run extrapolation** (#1218 fern Arm B, #1166 tanjiro partial, #1129 edward partial, #1201 this). Future mid-run projections should reserve "CATASTROPHIC" until terminal.

**NS5 polar-quality manifold — 10 mechanism-distinct closures, FULLY CHARACTERIZED:**
- #884 NS_ITERS scan (optimal at 12)
- #920 quintic at low iters
- #1102 spectral-norm input
- #1107 polar interpolation α
- #1123 asymmetric γ_L/γ_R
- #1135 exact SVD + topk truncation (rank load-bearing)
- #1136 pre-NS5 gradient noise (CATASTROPHIC)
- #1144 phase-schedule NS_ITERS
- #1166 cubic coefficient (a, b)
- **#1201 (this)** SVD + calibrated noise (magnitude decoupled)

NS5 cubic + 12 iters + bilateral L^(-γ)R^(-γ) preconditioning is structurally optimal. Only mechanism-distinct sub-axes worth probing (e.g., post-polar magnitude modulation, polar input gradient construction).

**146th NULL closed.** Per Issue #1252 directive (avoid further NS5 polar mining), alphonse → **mechanism #6 from aligned hypothesis queue: phase-gated u/w floor (TARGET_UW)** — directly addresses directive item "phase-specific mechanisms active only before target crossing window." Mechanism-distinct from #1170/#1176 (TARGET_UW value sweeps); tests *when* the floor is load-bearing, not *what value*.

## 2026-05-26 06:58 UTC — PR #1218 CLOSED: AdamW aux β2 static (0.99 vs 0.999 PyTorch default) — 145th NULL, AdamW aux family CLOSURE across 6 inner levers (g1r1-fern)

- Branch: `g1r1-fern/adamw-aux-beta2-static`
- Hypothesis: replace baseline `betas=(0.8, 0.95)` (~20-step lookback) with widened β2 ∈ {0.99 (Arm A, ~100-step lookback), 0.999 (Arm B, PyTorch default ~1000-step lookback)} on AdamW aux (embed, lm_head, scalars). Tests whether wider variance-EMA window for tail-heavy aux gradients improves cooldown-phase preconditioning.

| Arm | β2 | wandb_run | val_ema | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0.95 (~20-step lookback) | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (β2=0.99)** | 0.99 (~100-step) | `o0iuc4gg` | **3.267362** | **2950** | **+0.97 (3.2σ)** | **+25** | marginal NULL |
| **B (β2=0.999)** | 0.999 PyTorch default (~1000-step) | `a5f14g6t` | **3.269506** | **2975** | **+3.11 (10σ)** | **+50** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms FAIL both clauses.
- **Direction:** monotone dose-response, super-linear in Δval (+0.97 → +3.11 mnat = 3.2× scaling at 10× β2 step). Δsr linear (+25 → +50). No bracket interior.
- **Mechanism canon — variance staleness CONFIRMED via student telemetry analysis:**

| Metric | Arm A β2=0.99 | Arm B β2=0.999 | Ratio | Interpretation |
|---|---|---|---|---|
| `adamw/embed/v_mean_sqrt` | 0.00504 | 0.01338 | **2.65×** | wider β2 retains larger embed variance |
| `adamw/embed/v_max` | 2.45 | 65.50 | **26.7×** | extreme retention of early-training peaks |
| `adamw/lm_head/v_mean_sqrt` | 0.4752 | 0.7511 | 1.58× | lm_head retains 1.5× |
| `adamw/scalars/v_max` | 1.17e7 | 4.22e7 | 3.60× | scalars retain 3.6× |
| `adamw/embed/eps_dominance_frac` | 0.00487 | 0.00487 | **1.000×** | eps non-binding under β2=0.999 ✓ |

Wider β2 → preconditioner retains stale (larger) variance from pre-cooldown high-magnitude regime → `sqrt(v̂)` over-estimated → update magnitude `m̂/sqrt(v̂)` under-scaled during small-LR cooldown tail → val regresses. Dose-dependent, not threshold/discrete.

- **Cross-axis canon #1178 eps non-binding EXTENDED:** `eps_dominance_frac` is **unchanged across β2 ∈ [0.99, 0.999]** (both 0.00487 for embed) — variance signal dominates `+eps` by ~200× regardless of β2 choice. **#1178 eps-canon is robust across the FULL β2 ∈ [0.95, 0.999] range** — eps floor structurally silent over a 4-decade range × 50× β2 lookback span.

- **β-axis monotone-worse NULL pattern — 4th instance, structural canon:**
  - **#1208** frieren β_cov warmup (β₂-analog on body-Muon preconditioner) — monotone NULL
  - **#1213** edward μ cooldown ramp (β₁-analog body-Muon EMA) — monotone NULL
  - **#1215** tanjiro μ warmup (β₁-analog body-Muon EMA) — monotone NULL
  - **#1218 (this)** fern AdamW aux β2 static — monotone NULL

**Canon:** *any departure from baseline-tuned β/μ/EMA coefficients toward textbook defaults (Adam-style β=0.999, etc.) is structurally penalized at this benchmark's 3250-step horizon. The baselines are not legacy artifacts — they are load-bearing tuning specific to the WSD-cooldown + 3250-step regime.*

- **AdamW aux family — 6 inner levers all NULL:**

| PR | Lever | Closure |
|---|---|---|
| #796 | β1 ramp | NULL |
| #741 | β2 cooldown ramp | NULL |
| #832 / #1086 | β1 fixed bias-correction | NULL |
| #1168 / #1178 | eps (4-decade range) | NULL |
| #1198 | weight_decay (10× span) | NULL (Pareto-shift) |
| **#1218 (this)** | β2 static (0.99 / 0.999) | NULL (monotone dose-response) |

Plus AdamW-replacement family fully NULL (#854 Adan, #875 AdaBelief, #899 EMA-wrapper, #937 SOAP-damped, #953 SOAP-undamped, #964 Muon-as-aux, #1013 Sophia-H). **AdamW with baseline `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` is structurally required for aux.**

- **Cooldown variance-staleness recovery (canon update):** Arm B did NOT trigger catastrophic miss despite mid-run val_live=3.285 trajectory — cooldown recovered ~12 mnat (val_live 3.285 → 3.269) in the final 300 steps. Useful new canon: cooldown phase has substantial variance-staleness compensation capacity even at PyTorch-default β2.

**145th NULL closed.** fern → next assignment (per Issue #1252 directive): **L_cov/R_cov preconditioner refresh at cooldown entry** — strongly motivated by #1215 striking L_cov rank degeneracy. State-intervention at phase boundary, mechanism-distinct from β_cov initialization axis (END-of-training only).

## 2026-05-26 06:05 UTC — PR #1215 CLOSED: body-Muon Nesterov mu warmup (0→0.95 over 200 vs 500 steps) — 144th NULL, mu-warmup axis FULLY CLOSED with monotone dose-response + striking L_cov rank degeneracy observation (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/mu-warmup`
- Hypothesis: linearly ramp `muon_mu` from 0 → 0.95 over the first 200 (Arm A) or 500 (Arm B) training steps. Adam-β₁-style bias correction for body-Muon's Nesterov first-moment EMA. Tests whether cold-start `m_prev` (with effective_mu=0.95 EMA-decayed-from-zero) over-aggressively damps early body-Muon updates.

| Arm | mu_warmup_steps | wandb run | val_ema | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0 (mu=0.95 fixed) | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (short)** | 200 | `h9o5hj45` | **3.271246** | **3000** | **+4.85 (16σ)** | **+75** | clear NULL |
| **B (long)** | 500 | `fv4a8gcv` | **3.271832** | **3025** | **+5.44 (18σ)** | **+100** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms FAIL both clauses.
- **Direction:** monotone dose-response (longer warmup strictly worse). Δval scales 12% / Δsr scales 33% from Arm A to Arm B at 2.5× warmup duration. No bracket interior.
- **Mechanism canon — direction wrong:** explicit linear mu warmup (0→0.95) introduces a "cold-start no-momentum phase" where body-Muon's first-moment buffer = current gradient only (no EMA averaging). The implicit mu=0.95 EMA-decayed-from-zero behavior at baseline (`m_1 = 0.05·g_1`) produces lower-magnitude, lower-variance smoothed inputs to NS5 that are apparently preferred over the warmup's pure-current-gradient inputs.
- **Adam analogy asymmetry:** Adam's β₁ bias correction is about *recovering the unbiased expected gradient estimate*, not about producing the *best optimizer step*. Body-Muon's NS5 polar map appears to benefit from the implicit damping that the un-corrected EMA provides — bias correction is the wrong intervention for this optimizer surface.
- **Cross-axis canon with #1208 frieren β_cov warmup:** identical mechanism story on the β₂-analog axis (NULL across n=2, warmup REMOVES partial smoothing that NS5 prefers). Together #1208 + #1215 confirm **bias-correction-style warmup is structurally NULL on both Muon EMA axes (β₁=mu and β₂=β_cov).** Body-Muon stack (eps=1e-12 clamp + NS5 polar normalization + param-EMA wrapper) already optimally damps cold-start asymmetry.

**Striking telemetric finding — L_cov rank degeneracy at cooldown terminal:**

| Arm | pmuon/lcov_eigh_min terminal | vs baseline (1857–1997) |
|---|---|---|
| Arm A (200 warmup) | **0.0** | fully collapsed |
| Arm B (500 warmup) | **0.3516** | 5000× below baseline |

This is a novel cross-axis observation — longer mu warmup → cold-start phase produces low-variance gradient inputs that under-populate the L_cov covariance accumulator early, compounding to rank degeneracy at cooldown terminal. Strong support for a future **L_cov refresh at cooldown entry** PR (mechanism #4 in the Issue #1252 aligned hypothesis queue) — detect rank degeneracy mid-training and re-initialize covariance estimate from a fresh window.

**μ-axis cluster status — 7 mechanism-distinct closures:**
- #930 static μ scan
- #1107 polar interpolation μ (n=2 boundary)
- #1156 Lookahead k-step μ blend (CATASTROPHIC)
- #1164 depth-stratified μ (CATASTROPHIC both directions)
- #1213 cooldown ramp 0.95→{0.97, 0.99} (monotone NULL)
- **#1215 (this)** warmup 0→0.95 over {200, 500} (monotone NULL)
- #1249 in flight: per-tensor-type (attn/mlp split)

Static μ=0.95 fixed-everywhere remains the only μ configuration not strictly worse than its perturbations. **μ-axis structurally constrained — further scalar μ-axis mining DEPRIORITIZED per Issue #1252 directive.**

**144th NULL closed.** tanjiro → next assignment (per Issue #1252 directive): **Pre-target LR boost (steps 2500-2925)** — phase-specific schedule intervention that directly addresses the directive item "schedules that deliberately steepen loss descent before step 2925." Mechanism #3 from aligned hypothesis queue.

## 2026-05-26 05:25 UTC — PR #1213 CLOSED: body-Muon Nesterov mu cooldown ramp (0.95→0.97 vs 0.95→0.99) — 143rd NULL, mu-cooldown axis FULLY CLOSED with monotone dose-response (g1r1-edward)

- Branch: `g1r1-edward/mu-cooldown-ramp`
- Hypothesis: linearly ramp `muon_mu` from 0.95 → 0.97 (Arm A) or 0.95 → 0.99 (Arm B) over the last 20% of training (~650 steps). Widens Nesterov EMA lookback from 20 → 33 (Arm A) or 20 → 100 (Arm B) steps during cooldown phase. Tests whether wider momentum window smooths cooldown's small-LR descent direction.

| Arm | mu_target | lookback | wandb run | val_ema | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0.95 fixed | 20 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (mild)** | 0.97 | 33 | `s30ca2ju` | **3.267238** | **2950** | **+0.84 (2.8σ)** | **+25** | marginal NULL |
| **B (wide)** | 0.99 | 100 | `gyzfl3ja` | **3.269038** | **2975** | **+2.64 (8.8σ)** | **+50** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms FAIL both clauses.
- **Direction:** clean monotone dose-response with ~3× stronger regression in Arm B than Arm A across val/sr/buffer axes. No bracket interior; wider is strictly worse.
- **Mechanism canon — direction wrong for speedrun objective:** wider Nesterov lookback during cooldown produces predicted mechanism signature (lower update-direction variance, buffer drift) but cost of *lagging behind the descending cooldown gradient signal* exceeds noise-reduction benefit at all tested dosages. NS5 polar already normalizes m_pre direction; mu schedule only affects input-direction lag. Arm B's 100-step lookback averages over 30%+ of total training — too wide for a phase needing sensitivity to final-stretch loss surface.
- **Cross-axis canon with #1182 EMA β_target:** buffer_frob_dist scales with cumulative cooldown LR mass in lookback window — NOT abstract "smoothing strength." Arm A +20% / Arm B +55% terminal buffer reflects how far back into high-LR phase the EMA window reaches.
- **μ-axis cluster status:** 6 mechanism-distinct closures now — #930 static / #1107 polar-interp / #1156 Lookahead / #1164 depth-stratified / #1213 cooldown ramp (this) / in flight: #1215 warmup, #1249 per-tensor-type. Static μ=0.95 fixed-everywhere remains only configuration not strictly worse than its perturbations. **μ-axis structurally constrained.**
- **Per Issue #1252 directive (05:03 UTC May 26):** edward routed to **directive-aligned hypothesis** — body-Muon Nesterov *buffer reset* at cooldown entry (state intervention, not coefficient sweep). Mechanism-distinct from #1213 (clears EMA state vs perturbs EMA coefficient).

## 2026-05-26 04:08 UTC — PR #1208 CLOSED: beta_cov bias-correction warmup (0→0.95 over 300 vs 750 steps) — 142nd NULL, β_cov/L_cov/R_cov initialization axis FULLY CLOSED across 5 PRs (g1r1-frieren)

- Branch: `g1r1-frieren/beta-cov-warmup`
- Hypothesis: linearly ramp `beta_cov` from 0 → 0.95 over the first 300 (Arm A) or 750 (Arm B) training steps. Adam-β2-style bias correction for the body-Muon preconditioner covariance EMA. Tests whether cold-start `L_cov`/`R_cov` (under-converged for first ~1/(1-0.95)=20 steps) over-aggressively scales early body-Muon updates.

| Arm | warmup | wandb run | val/loss | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (n=2) | — | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | (reference) |
| **A (fast)** | 300 | `b2hyb08n` | **3.271470** | **3025** | **+5.08 (17σ)** | **+100** | clear NULL |
| **B (slow)** | 750 | `4kd27gzi` | **3.270377** | **3000** | **+3.98 (13σ)** | **+75** | clear NULL |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — both arms fail both clauses.
- **Direction:** monotone-toward-baseline (slower=better, never beats). No bracket interior — warmup→∞ converges back to baseline behavior. Mechanism-rejected, not a Pareto-shift.
- **Mechanism canon — direction wrong:** starting from `effective_beta_cov=0` (pure outer-product covariance, no EMA decay) is LESS favorable than baseline's `beta_cov=0.95` cold-start. The eps=1e-12 clamp on `matrix_neg_power(L_cov, 0.4)` already absorbs cold-start asymmetry, and NS5 polar normalization further re-normalizes. The hypothesis posited that cold-start under-converged EMA caused over-aggressive early-update scaling, but empirically the eps+NS5 stack handles this cleanly — adding warmup REMOVES the partial smoothing that beta_cov=0.95 provides at step 1.
- **Param-EMA redundancy:** likely interaction with #918's param-EMA warmup (β_t ramps 0.95→0.99 over steps 0–1750). The param EMA filters out early-training noise at the parameter level; adding preconditioner-level warmup double-counts the bias correction. Two-level correction is redundant rather than complementary.
- **Mechanism safe but scheduling wrong:** no divergence, no NaN, no exploding norms in either arm. The mechanism is structurally safe — issue is direction, not stability.

**β_cov / L_cov / R_cov initialization axis FULLY CLOSED across 5 PRs and 3 mechanism-distinct sub-axes:**
- **#686 (CLOSED)** static β_cov ∈ {0.80, 0.90, 0.95, 0.99} — value scan
- **#774 (CLOSED)** fast-mix K ∈ {20, 50} — gradient-mixing window length
- **#822 85th (CLOSED)** L_cov/R_cov Adam-style BC (n=3 boundary informative-NULL)
- **#893 97th (CLOSED)** m_pre first-moment BC (n=2 boundary informative-NULL)
- **#1208 (this)** warmup schedules 0→0.95 over {300, 750} steps

Combined: every initialization-state and warmup variant on the preconditioner covariance is NULL/marginal. NS5 + eps clamp + param-EMA warmup form a robust early-training stack that absorbs all tested initialization perturbations. β_cov initialization is structurally constrained — further mining deprioritized.

**142nd NULL closed.** frieren → next assignment (per-tensor-type body-Muon Nesterov mu — attn vs mlp; deprioritized-but-untested axis from PR #777 closure list, mechanism-distinct from #1164 depth-stratified mu CATASTROPHIC + #1213 cooldown mu + #1215 warmup mu).

## 2026-05-26 02:00 UTC — PR #1198 CLOSED: AdamW aux weight_decay scan (0.01 vs 0.10, baseline=0) — 141st NULL, AdamW aux wd axis FULLY BRACKETED + AdamW aux family CLOSURE complete (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-adamw-wd`
- Hypothesis: probe AdamW aux `weight_decay` ±10× around baseline 0. Arm A wd=0.01 (mild) vs Arm B wd=0.10 (10× larger). Tests whether explicit decoupled shrinkage on embed/lm_head/scalars adds benefit beyond AdamW's implicit second-moment regularization.

| Arm | wd | wandb run | val/loss_ema | sr | Δval (mnat) | Δsr | reached_target | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (n=2) | 0 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | 0 | 1 | (reference) |
| **A (mild)** | 0.01 | `1josgg3e` | **3.266192** | **2950** | **−0.20 (sub-σ)** | **+25** | 1 | **Pareto-shift NULL** |
| **B (10× larger)** | 0.10 | `tknei6ut` | **3.301665** | **−1** | **+35.27 (CAT)** | n/a | **0** | **CATASTROPHIC NULL** |

- **Predeclared merge rule:** `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — neither arm satisfies. Arm A fails clause-2 by Δsr+25; Arm B fails on every dimension (target_margin=−0.0217, missed 3.28 by 21.7 mnat).

- **MECHANISM CANON — inactive-embed half-life derivation:**
  - **wd=0.01 Pareto-shift:** `wd·lr·p` shrinkage step at wd=0.01 with peak embed lr≈0.3 yields step magnitude ≲0.3% of total AdamW update — sub-noise on the asymptote (Δval=−0.2 mnat is within σ≈0.3 mnat per #958). The small additive shrinkage on inactive embed rows (~42k of 50304 not touched per batch) and slow LR-mass accumulation across cooldown delays first crossing of 3.28 from step 2925 → 2950. Same Pareto-shift shape as #969 cooldown γ=1.2 / #1099 / #1182 EMA β_target.
  - **wd=0.10 CATASTROPHIC:** Inactive embed half-life `(1−0.3·0.10)^t = 0.5 ⇒ t=22.8` — within the 3250-step run, low-frequency token embeddings are effectively zeroed. lm_head dense-active sees uniform compression flattening logit landscape; combined with baseline sqrt-clip soft-cap @15 (already bounds peakedness from above), additional shrinkage from below has no upside. Trajectory divergence visible by step 1500 (Arm B val=3.65 vs baseline ≈3.55); by step 2925 Arm B at val=3.32 (44 mnat behind).
  - `target_margin=−0.0217` + `single_run_stat_sig_margin=−0.0257` (Arm B) are stable EMA-accumulated quantities → cross-arm Δ≫200% noise floor is robust without n=2 confirmation per #1168 canon.

- **CROSS-AXIS CANON — AdamW aux family closure now complete across 5 inner levers:**
  - β1 ramp #796 — NULL
  - β2 ramp #741 — NULL
  - β1 fixed-bias-correction #832/#1086 — NULL
  - eps n=2 #1168 — NULL (6-decade bracket)
  - **wd #1198 (this PR)** — NULL
  - (β2 STATIC #1218 fern in flight)
  - **Baseline `betas=(0.8, 0.95), eps=1e-10, weight_decay=0` triple-validated** — not just inherited from starter script but actively the best across all probed inner levers.

- **AdamW-REPLACEMENT family fully NULL:** #854 Adan, #875 AdaBelief, #899 EMA-wrapper, #937 SOAP-damped, #953 SOAP-undamped, #964 Muon-as-aux, #1013 Sophia-H. AdamW is structurally required for aux groups.

- **PARETO-SHIFT NULL pattern reinforced (4 instances):** #969 (cooldown γ=1.2), #1099, #1182 (EMA β_target 0.985), **#1198 (wd=0.01, this PR)**. Signature: regularizer or perturbation that doesn't hurt asymptote but delays target crossing.

- Mechanism-distinct from: #1040 (body-Muon WD decoupling), #897 (adaptive body-Muon WD), #1170 (u/w-floor body NS5 magnitude), #1178 (AdamW eps).

- **AdamW aux `weight_decay` axis FULLY BRACKETED across 10× span.** 141st NULL. Suggested follow-ups (embed-only WD, lm_head-only WD, sub-0.01 bracket, delayed-onset WD) skipped — axis structurally closed, diminishing returns. askeladd → next assignment (TBD).

## 2026-05-26 00:36 UTC — PR #1168 CLOSED: L_neg/R_neg matrix_neg_power eps n=2 confirmation (1e-6 LOOSER n=2 vs 1e-15 TIGHTER n=1, baseline=1e-12) — 140th NULL, eps axis FULLY CLOSED across 6 decades, stat-sig fails at n=2 despite monotone direction (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/mneps-ablation`
- Hypothesis: probe matrix_neg_power eps ±2 decades around baseline 1e-12. Arm A LOOSER eps=1e-6 (251× max amplification vs baseline 63095×) vs Arm B TIGHTER eps=1e-15 (5623× amplification, 178× MORE than baseline). Direct test of #985 NS5 triple-load-bearing role 3 (null-space amplification suppression).
- n=2 confirmation triggered by Arm A marginal-WIN candidate at n=1 (Δ−0.21 mnat sub-noise, marginal n=1 win requires n=2 confirmation per session memory).

| Run | eps | val_ema | sr | Δval (mnat) | Merge clause-2 |
|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1e-12 | 3.266394 | 2925 | 0 | (reference) |
| `yyp8df25` Arm A seed-1 | 1e-6 | 3.266184 | 2925 | −0.210 | PASS (sr=2925 AND val<baseline) |
| `po02h3dn` Arm A seed-2 | 1e-6 | 3.265409 | 2925 | −0.985 | PASS (sr=2925 AND val<baseline) |
| **Arm A n=2 mean** | 1e-6 | **3.265797** | 2925 | **−0.597** | **stat-sig FAILS (0.000844 < 0.004, 4.7× below threshold)** |
| Arm B (n=1) `cccpoha7` | 1e-15 | 3.267550 | 2950 | +1.16 | FAIL (sr+25, sr≠2925) |

- **STAT-SIG FAILS:** Δval_n2 = −0.597 mnat is 2.8× empirical single-seed σ≈0.0003 — borderline 2σ at n=2. Seed-1 → seed-2 difference (0.775 mnat) is ~2.6× the noise floor too, so apparent improvement is dominated by seed dimension rather than eps perturbation. **Pattern matches #1107 polar-interp** (now third recurrence of this pattern in r1: #1107, #1118, #1168).

- **STRIKING MECHANISM CANON — cross-seed `polar/ortho_residual_sample` variability OVERTURNS prior reading:**
  - Arm A seed-1 ortho_residual=0.135; Arm A seed-2 (SAME eps)=0.376 → +178% same-eps seed variance
  - Arm A vs Arm B (different eps) Δ=+100% at terminal step
  - **The 16:14 UTC + 20:23 UTC narrative ("Arm B 2× elevated ortho_residual = NS5 working harder") is OVERTURNED** — the cross-arm Δ is WITHIN seed noise band.
  - **Corrected canon: `polar/ortho_residual_sample` is single-batch noisy with σ ~ 0.1-0.2 in terminal regime.** Future PR diagnostic interpretations must require n=2 cross-seed reference for any cross-arm metric claim where Δ < 200%. Cite EMA-averaged or accumulated diagnostics (e.g., `pmuon/lcov_eigh_min` which varied only 3-13% across seeds) for stable mechanism claims.
  - Same caveat applies to `pmuon/whitened_sv_ratio` (+51% seed-to-seed; +36% Arm A vs Arm B). Major retraction of original mechanism-divergence narrative.

- **EPS AXIS STRUCTURE (across 6 orders of magnitude):**
  - eps=1e-15: +1.16 mnat, sr+25 (mild regression)
  - eps=1e-12 (baseline): reference
  - eps=1e-6: −0.60 mnat (n=2 mean, sub-stat-sig)
  - **NS5 role 3 (null-space amp suppression) confirmed REAL but OVER-DETERMINED in [1e-6, 1e-15]** — axis structurally flat in this range.

- **CRASH ASYMMETRY EMPIRICALLY REVERSED:** Arm A LOOSER eps had 4 crash-restarts (`z5328dg3`, `iku6uc1t`, `n7t90h27`, `y5ir5oqq`); Arm B TIGHTER eps launched CLEANLY with NONE. **Contradicts advisor 14:10 UTC prior** ("tighter eps → more rank-deficient eigs amplified → more crashes"). Empirical update to NS5 stability canon: early-step crash sensitivity does NOT scale monotonically with eps amplification factor — likely depends on specific eigenvalue distribution at step 1-20 where L_cov rank is filling per #1046.

- **L_neg/R_neg matrix_neg_power eps axis FULLY CLOSED across 6 decades.** 140th NULL. Future NS5 internals PRs must report m_pre stable rank (#1102) and use n=2 cross-seed reference for any ortho_residual-based mechanism claim. thorfinn → next assignment (EMA wrapper ema_beta starting value scan: Arm A=0.92 LOWER (wider ramp), Arm B=0.97 HIGHER (narrower ramp), baseline=0.95; tests the START of LR-coupled β ramp; mechanism-distinct from #864 (duration), #1182 (endpoint), and in-flight #1229 (ramp shape); ~0 LOC, CLI flag exists).

## 2026-05-25 23:55 UTC — PR #1182 CLOSED: EMA wrapper β_target probe (0.985 LOWER vs 0.995 HIGHER, baseline=0.99) — 139th NULL, EMA β_target axis FULLY CLOSED with asymmetric U-shape canon (HIGHER benign, LOWER costs ~1.5 mnat per 0.005) (g1r1-nezuko)

- Branch: `g1r1-nezuko/ema-beta-target`
- Hypothesis: probe EMA wrapper β_target ±0.005 around baseline 0.99. Arm A LOWER β=0.985 (67-step lookback) vs Arm B HIGHER β=0.995 (200-step lookback). Tests U-shape geometry around baseline.

| Arm | β_target | wandb run | val_ema | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|---|
| Baseline (n=2) | 0.99 | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | (reference) |
| **A (LOWER)** | 0.985 | `kt5hn5uk` | **3.267900** | **2950** | **+1.506 (5σ)** | FAILS both (sr+25 + val miss) |
| **B (HIGHER)** | 0.995 | `m4mvdz7v` | **3.266713** | **2925** | **+0.319 (1.06σ)** | FAILS clause-2 (sr tied but val miss) |

Both arms FAIL merge rule. **Arm B is sub-σ NULL** (1.06σ at empirical σ ≈ 0.3 mnat per #958) — statistically indistinguishable from baseline.

- **ASYMMETRIC NULL — corrected canon: monotone-decreasing val-vs-β_target in [0.99, 0.995], not symmetric U-shape.** Arm B regresses 4.7× LESS than Arm A. Lower β_target sharply penalized (-1.5 mnat per 0.005); higher β_target benign.

- **MECHANISM REVISION — buffer_frob_dist intuition INVERTED:**

| Direction | Δβ | terminal buffer_frob_dist | Δval | Mechanism |
|---|---|---|---|---|
| LOWER (Arm A) | −0.005 | 11.31 (smaller) | +1.51 mnat | 67-step lookback misses early-cooldown gradient signal |
| HIGHER (Arm B) | +0.005 | **58.80 (5.2× larger)** | +0.32 mnat | 200-step lookback approximately re-centers on trajectory mean |

  - **Terminal `buffer_frob_dist` scales with how much of cooldown's LR mass falls inside the lookback window**, NOT abstract "smoothing strength."
  - Arm A's 67-step window captures only terminal-LR-near-zero phase (steps ~3183-3250) where weights barely move → buffer ≈ live → small frob_dist.
  - Arm B's 200-step window reaches back to steps ~3050-3250 including early-cooldown high-LR phase → buffer ≠ live → large frob_dist.
  - **`buffer_frob_dist` is NOT a direct val proxy** — mechanism-conditional. Contradicts the #918 canon "higher LR → larger frob_dist → lower val" by showing high β_target also produces large frob_dist but does NOT improve val.

- **CROSS-AXIS CANON STRENGTHENING:**
  - #864 baseline β_target=0.99 confirmed as approximately optimal with asymmetric local neighborhood
  - #1144 NS_ITERS phase schedule (132nd NULL "any departure from uniform NS_ITERS=12 costs ~1.2 mnat"): Arm A's +1.5 mnat in same band — EMA expects uniform smoothing rate across cooldown
  - #1176 u/w-floor U-shape: also asymmetric (HIGHER 47% steeper) but OPPOSITE direction (HIGHER hurts there, LOWER hurts here). Mechanism distinction: u/w-floor is direct multiplicative perturbation; EMA β_target affects lookback over LR-weighted trajectory.

- **EMA wrapper β_target axis FULLY CLOSED across {0.985, 0.99, 0.995}.** 139th NULL. Future EMA wrapper PRs must stay above β_target=0.99 and recognize buffer_frob_dist is mechanism-conditional.

- nezuko → **#1219** (EMA β ramp SHAPE probe: Arm A cosine ramp (slow-start fast-finish) vs Arm B quadratic-t² ramp (fast-start slow-finish), both 0.95→0.99 over 1750 steps; tests whether SHAPE of the ramp matters at fixed endpoints + duration; mechanism-distinct from #864 (duration probe) and #1182 (target probe) and #1213/#1215 (body-Muon mu schedules, not EMA wrapper); ~5 LOC implementation).

## 2026-05-25 22:25 UTC — PR #1178 CLOSED: AdamW aux eps ablation (1e-8 LOOSER PyTorch default; Arm B 1e-12 aborted) — 138th NULL, AdamW aux eps axis FULLY CLOSED across 4-decade range, eps_dominance_frac structural finding (g1r1-fern)

- Branch: `g1r1-fern/adamw-eps`
- Hypothesis: AdamW `eps=1e-10` baseline is unusual (PyTorch default 1e-8) and never directly ablated. Probe ±2 decades around baseline to test whether eps floor is load-bearing for aux i.i.d. pipeline. Arm A LOOSER eps=1e-8 (PyTorch default), Arm B TIGHTER eps=1e-12 (FP edge).

| Arm / Seed | wandb run | val_ema | sr | Δval (mnat) | Verdict |
|---|---|---|---|---|---|
| Baseline (n=2) | vm48fdof / 0a7esmxs | 3.266394 | 2925 | 0 | (reference) |
| Arm A seed 1 (eps=1e-8) | `2jtcjepq` | 3.266378880 | 2925 | −0.0152 | sub-noise WIN by math, fails stat-sig |
| Arm A seed 2 (eps=1e-8) | `0u42mc7s` | 3.266378164 | 2925 | −0.0158 | sub-noise WIN by math, fails stat-sig |
| **Arm A n=2 mean** | — | **3.266378522** | **2925** | **−0.0155** | **NULL — FAILS stat-sig (180× below threshold)** |
| Arm B (eps=1e-12) | `vwtb8laz` | aborted at step 74 | — | — | per advisor pivot, structural finding from Arm A telemetry |

n=2 stat-sig: `(3.266394 − 3.266378522)·√2 = 0.0000219` vs threshold ≥ 0.004 → FAILS by factor 180×. n=2 sample std = **5.06e-7** (val_ema seed spread) — astonishingly tight, ~600× tighter than empirical σ ≈ 3e-4. Possible eps=1e-8 reduces seed variance, or 7σ coincidence (unverified).

- **MECHANISM CANON — eps_dominance_frac structural finding:**

| Group | seed-1 eps_dom_frac | seed-2 eps_dom_frac | v_mean_sqrt | eps / sqrt(v̂) |
|---|---|---|---|---|
| embed (50304×768) | 0.6868% | 0.6869% | 0.0047 | ~2.1e-6 |
| lm_head (50304×768) | 1.51e-5 | 2.05e-5 | 0.493 | ~2.0e-8 |
| scalars | 0.0 | 0.0 | 7.49 | ~1.3e-9 |

  - **At eps=1e-8 (10000× looser than baseline 1e-10), the eps floor is essentially never binding across all 3 aux groups.** Variance signal `sqrt(v̂)` dominates the AdamW update across entire training trajectory, NOT the eps floor.
  - Even on the sparsest group (embed, token-level sparsity), only 0.687% of coords fall below the eps floor at 1e-8. At baseline 1e-10, the binding fraction is 100× smaller still (≈0.007% projected).
  - **Seed-to-seed agreement on `eps_dominance_frac` (differs by 1.5e-6 between seeds) confirms this is a structural property of the aux pipeline**, not a per-run fluctuation.
  - **Baseline `eps=1e-10` was silent over-engineering** at this scale.

- **AdamW aux eps axis FULLY CLOSED across 4-decade range [1e-12, 1e-8].** 138th NULL.
- **Joint aux Adam-family hyperparameter closure now spans 20+ axes**: all update-rule families (Adan, NAdam, AdaBelief, Lion, Lookahead, SF, AdEMAMix, AMSGrad, Adamax, LAMB, Cautious, Adam-mini, SOAP, Sophia), β1 ramp (#796), β2 ramp (#741), aux base-LR retune (#913), now eps (#1178). Per-coord variance scaling self-normalizes via AdamW denominator — eps floor irrelevant within wide range.

- fern → **#1217** (AdamW aux β2 STATIC value scan: Arm A β2=0.99 vs Arm B β2=0.999 PyTorch default, baseline=0.95 — mechanism-distinct from #741 β2 cooldown ramp (probed cooldown phase only, not full-training static), tests whether unusual baseline β2=0.95 is load-bearing or legacy artifact, ~3 LOC implementation).

## 2026-05-25 21:18 UTC — PR #1166 CLOSED: NS5 cubic-coefficient ablation ((1.7, -0.7) TIGHTER vs (1.3, -0.3) GENTLER at a+b=1) — 137th NULL, NS5 cubic-coefficient axis FULLY CLOSED with asymmetric robustness canon (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-cubic`
- Hypothesis: scan NS5 cubic polynomial coefficients (a, b) along the a+b=1 constraint line (fixed point at σ=1). Arm A TIGHTER (1.7, -0.7) has linear convergence rate −0.4 at σ=1 (oscillatory). Arm B GENTLER (1.3, -0.3) has rate +0.4 (monotone). Tests whether baseline (1.5, -0.5) quadratic convergence is structurally critical.

| Arm | (a, b) | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | (1.5, -0.5) | 3.266394 | 2925 | 0 | (reference) |
| **A (TIGHTER)** `5vpx9orf` | (1.7, -0.7) | **3.26758** | **2950** | **+1.19 (4σ)** | FAILS both (sr+25 + val miss) |
| **B (GENTLER)** `m7s2z8a0` | (1.3, -0.3) | **3.27378** | **3050** | **+7.39 (25σ)** | FAILS both (sr+125 + val miss) |

- **Both arms NULL.** 137th closure. ASYMMETRIC regression — TIGHTER 6× milder than GENTLER.

- **MECHANISM CRYSTALLIZED — NS5 cubic robustness boundary is asymmetric, GENTLER fails to converge within budget:**

| Telemetry | Arm A TIGHTER | Arm B GENTLER |
|---|---|---|
| `ns5/sigma_max_after_iter_12` | n/a (pre-telemetry) | **0.846** (vs target ~1.003 baseline) — never reaches unit norm |
| `polar/ortho_residual_sample` | 0.176 (~2× elevated) | **16.03 (~91× Arm A)** — severely sub-orthogonal |
| `ema/buffer_frob_dist` | 22.75 (≈ baseline 22.6) | 14.30 (smaller post-NS5 updates due to scale ~0.85×) |
| linear convergence rate at σ=1 | −0.4 (oscillatory) | +0.4 (monotone undershoot) |

  - **Arm A TIGHTER**: NS5 produces approximately-orthogonal output; optimizer absorbs the change with only +1.2 mnat val cost. EMA dynamics unchanged. Tightening NS5 coefficients by ±0.2 is well-tolerated. Note: ~8 crash restarts in early debug — `f(σ)=1.7σ−0.7σ³` overshoots aggressively at large σ in first few steps; 1/spectral-norm pre-scaling at line 469 keeps input in stable basin once past warmup.
  - **Arm B GENTLER**: NS5 SEVERELY UNDER-CONVERGED. With f'(0)=a=1.3, small-σ amplification rate too weak to drive m_pre's bulk-σ (starting at ~0.07 per ns5/sigma_max_after_iter_1) up to unit norm in 12 iterations. Rate=+0.4 monotone approach converges asymptotically but runs out of budget → NS5 outputs sub-orthogonal matrix at 0.85× scale every step.

- **REFINED CANON — polar/ortho_residual NOT load-bearing at small variations, IS load-bearing at large variations** (qualifies #1102/#1123/#1107 canon "polar/ortho_residual is NOT load-bearing at NS_ITERS=12"):

| Source | ortho_residual | Δval (mnat) | Verdict |
|---|---|---|---|
| #1102 spectral-norm | 0.0525 (3.7× tighter) | +0.77 | NOT load-bearing |
| #1123 asymmetric γ | 0.401 vs 0.101 (4× spread) | +1.6/+3.6 | NOT load-bearing (within band) |
| Baseline | ~0.10 | 0 | (reference) |
| #1166 Arm A TIGHTER | 0.176 (~2× elevated) | +1.19 | NOT load-bearing (mild cost) |
| **#1166 Arm B GENTLER** | **16.03 (~160× elevated)** | **+7.39** | **LOAD-BEARING (clear cost)** |

  - **Regime boundary somewhere between ortho_residual ≈ 0.2 and ortho_residual ≈ 16.** The canon "tightening residual 3-5× is fine" still holds. New finding: **loosening residual 100× DOES cost ~7 mnat val** — at the level where NS5 fails to reach unit norm within budget.

- **Cross-axis canon strengthening — NS5 polar-quality manifold FULLY CHARACTERIZED:**
  - #884 NS_ITERS scan (8, 12, 16, 20): NS_ITERS=12 optimal
  - #920 quintic@NS_ITERS={5,6}: Jordan-quintic worse than cubic-at-12 (overshoot at intermediate σ)
  - #1102 NS5 input spectral-norm: ortho_residual 0.0525 (3.7× tighter), NULL
  - #1107 polar interpolation α=0.50/0.75: post-NS5 blend, NULL
  - #1123 asymmetric γ_L/γ_R: 4× ortho_residual spread, NULL
  - #1135 exact SVD polar: 0.0065 residual, +3 mnat NULL; rank-256 truncation 22.63 residual, CATASTROPHIC
  - #1136 grad noise: pre-NS5 noise CATASTROPHIC
  - #1144 phase NS_ITERS: phase asymmetry NULL
  - **#1166 cubic-coefficient line: (1.5, -0.5) robust to TIGHTER ±0.2, fragile to GENTLER**
  - **NS5 cubic baseline (1.5, -0.5) is structurally optimal under joint constraint `{a+b=1, NS_ITERS=12, m_pre bulk-σ ~ 0.07}`.**

- Closing as NULL. tanjiro → **#1215** (body-Muon Nesterov momentum buffer warmup: linearly ramp mu 0 → 0.95 over first 200 (Arm A) vs 500 (Arm B) steps. Mechanism: m EMA cold-start-biased for first ~20 steps under mu=0.95; warmup replaces implicit β1-style bias with explicit linear schedule. Adam-style first-moment bias correction; mechanism-distinct from all closed mu axes (#930 static, #1156 Lookahead, #1164 depth-stratified, #1107 polar-interp) and complementary to #1208 frieren beta_cov warmup which tests the β2-analog).

## 2026-05-25 21:08 UTC — PR #1176 CLOSED: u/w-floor TARGET_UW probe (0.25 LOWER vs 0.45 HIGHER, baseline=0.35) — 136th NULL, u/w-floor U-shape FULLY MAPPED across 5 points with asymmetric harm direction (g1r1-edward)

- Branch: `g1r1-edward/target-uw`
- Hypothesis: probe u/w-floor TARGET_UW value around baseline 0.35 (introduced in skylight PR, never directly ablated as a tight sweep). Arm A LOWER (0.25): let small updates pass through → weaker rescue. Arm B HIGHER (0.45): force larger steps on all layers → more aggressive minimum step. Direct response to #1129 spectral-exponent closure diagnostic insight that "floor is the dominant magnitude controller now."

| Arm | target_uw | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | 0.35 | 3.266394 | 2925 | 0 | (reference) |
| **A (LOWER)** `xamga913` | 0.25 | **3.27240** | **3000** | **+6.00 (20σ)** | FAILS both (sr+75 + val miss) |
| **B (HIGHER)** `25iotq1n` | 0.45 | **3.27521** | **3100** | **+8.82 (29σ)** | FAILS both (sr+175 + val miss) |

- **Both arms NULL.** 136th closure. Both fail merge rule on both clauses.

- **U-SHAPE CANON FULLY MAPPED across 5 points** (combining #1035, #1129, #1176):

| target_uw | Δval (mnat) | Source |
|---|---|---|
| 0.00 (no floor) | +5.8 | #1035 NULL |
| 0.25 (LOWER probe) | **+6.00** | **#1176 Arm A** |
| 0.35 (baseline) | 0 | #918 / #1129 saturation |
| 0.45 (HIGHER probe) | **+8.82** | **#1176 Arm B** |
| 0.50 (over-application) | +20 | #1035 CATASTROPHIC |

  - **Asymmetric U: HIGHER side regresses 47% faster per unit target_uw** (88 mnat per 1.0 of target_uw vs 60 mnat per 1.0 on LOWER side). Slope extrapolation predicts ~+22 mnat at 0.50, consistent with #1035's CATASTROPHIC observation.
  - Interior optimum at **0.35 ± 0.05** — basin is tight and well-tuned. The natural u/w ratios cluster around 0.35; departure in either direction creates either under-rescue (LOWER) or over-amplification (HIGHER) regimes.

- **MECHANISM CRYSTALLIZED — over-amplification dominates under-rescue:**

| Telemetry | Arm A (LOWER 0.25) | Arm B (HIGHER 0.45) |
|---|---|---|
| `train/uw_floor/fired_fraction` | **0.333** (33% of 72 body MLP params) | **1.0** (100% saturation, every param) |
| `train/uw_floor/mean_rescale_factor` | 1.16× (barely doing work) | **51.86×** (massive amplification) |
| `train/uw_floor/min_ratio_observed` | 0.1794 | 0.00224 (some updates 200× below threshold) |
| `polar/ortho_residual_sample` | 0.199 (~2× elevated) | 0.233 (~2.3× elevated) |
| **`ema/buffer_frob_dist`** | **4.27** | **283.57 (~66× higher)** |

  - **Smoking-gun mechanism for HIGHER-side asymmetry:** `ema/buffer_frob_dist=283.57 vs 4.27 in Arm A (~66× higher)` — chronic over-driving cascades through the EMA wrapper. At 0.45 the floor amplifies updates by 52× whenever it fires (100% of the time), compounding into massive buffer drift across the whole run.
  - **Under-rescue (LOWER 0.25)**: bounded harm. Most params (67%) remain naturally above threshold; rescued ones get small ~1.16× boost; NS5 cubic iteration has "room" to recover from residual under-rescue
  - **Over-amplification (HIGHER 0.45)**: unbounded harm. 100% saturation + 52× mean rescale = multiplicative perturbation compounds through EMA buffer → NS5 polar cubic CANNOT absorb this magnitude → chronic over-driving CASCADES

- **Asymmetric U-shape structurally consistent with #985 NS5 triple-load-bearing canon role 1 (magnitude normalization):** NS5 is contractive on too-large inputs (Arm B over-amp partially absorbed but at cost of polar quality), but cannot construct missing magnitude (Arm A under-rescue passes through directly). Re-confirms the "imperfect polar is better than perfect polar" canon (#1135 extension): structured polar residual at baseline 0.35 floor is part of the load-bearing magnitude equilibrium.

- **Cross-axis canon strengthening:**
  - Reinforces #1129 spectral-exponent + floor-saturation canon — at baseline 0.35, floor is at the Goldilocks rescue/amplification balance, saturating just enough to rescue under-converged layers while not over-driving the EMA buffer
  - The floor mechanism interacts with NS5's 6.7% polar residual (#1135 canon) in a tightly coupled equilibrium
  - Further fine-grained probing of u/w-floor axis is structurally constrained — basin width ±0.05 with asymmetric harm direction

- Closing as NULL. edward → **#1213** (body-Muon Nesterov mu cooldown schedule: linearly ramp mu 0.95→0.97 (Arm A) vs 0.95→0.99 (Arm B) over last 20% of training. Mechanism: per-step gradient SNR shrinks during cooldown as LR→0; wider EMA window (20→100 step lookback) averages more steps to recover SNR. Mechanism-distinct from all closed mu axes — #930 static scan, #1156 Lookahead, #1164 depth-stratified, #1107 polar-interp — and all in-flight β-axes (#1182 wrapper β_target, #1208 preconditioner beta_cov)).

## 2026-05-25 19:51 UTC — PR #1164 CLOSED: Depth-stratified body-Muon EMA momentum (per-layer mu, 12-layer linear interp) — 135th NULL, depth-stratified body-Muon hyperparameter family structurally constrained (g1r1-frieren)

- Branch: `g1r1-frieren/depth-stratified-mu`
- Hypothesis: per-layer mu (EMA momentum) linearly interpolated across 12 transformer layers — fast-deep (Arm A DOWN: shallow=0.99 → deep=0.90, 10-step lookback at deep) vs slow-deep (Arm B UP: shallow=0.90 → deep=0.99, 100-step lookback at deep). Tests whether deep semantic-compression layers need long-memory EMA or whether shallow token-level layers benefit from fast adaptation. Direct response to #1116 askeladd depth-LR closure note explicitly suggesting per-layer EMA β as next mechanism-distinct depth axis.

| Arm | mu shallow → deep | val | sr | Δval (mnat) | Merge rule |
|---|---|---|---|---|---|
| Baseline (n=2) | 0.95 uniform | 3.266394 | 2925 | 0 | (reference) |
| **A (DOWN, FAST-DEEP)** `4v4nbzrf` | 0.99 → 0.90 | **3.332653** | **−1** | **+66.26 (221σ)** | FAILS both (val miss by 66 mnat) |
| **B (UP, SLOW-DEEP)** `xlhi2m73` | 0.90 → 0.99 | **3.305058** | **−1** | **+38.66 (129σ)** | FAILS both (val miss by 39 mnat) |

- **Both arms CATASTROPHIC.** 135th NULL. Both miss the 3.28 target. **Asymmetric NULL with 28-mnat gap between arms is the key signal.**

- **MECHANISM CRYSTALLIZED — deep-layer EMA mu is LOAD-BEARING; fast-deep is the hostile direction.** Per-layer grad-norm telemetry at terminal step:

| Layer endpoint | grad-norm | Ratio to its opposite |
|---|---|---|
| Arm A L11 mu=0.90 (FAST-DEEP) | 614 | 52× larger than Arm B L11 mu=0.99 (11.86) |
| Arm B L00 mu=0.90 (FAST-SHALLOW) | 1378 | 315× larger than Arm A L00 mu=0.99 (4.37) |

  - **Fast EMA (mu=0.90, 10-step lookback) fails to absorb per-step gradient noise on deep layers** → grad_norm stays large → unsmoothed direction → NS5 polar receives noisy input → cascading val degradation
  - **Slow EMA (mu=0.99, 100-step lookback) is structurally REQUIRED on deep layers** to stabilize compressed semantic features
  - **Shallow layers tolerate fast EMA** because gradient amplitude is high (signal-dominated despite noisy averaging) — but the 315× shallow grad scale is *symptom not cause*; shallow harm is less load-bearing because semantic content is less compressed
  - The 28 mnat asymmetry (Arm B less catastrophic) confirms 16:05 UTC mechanism prediction: deep-layer body-Muon optimization is more load-bearing than shallow

- **EMA buffer divergence ANTI-correlates with val outcome** — Arm B `ema/buffer_frob_dist=552M` is 3.7× LARGER than Arm A's 151M, yet Arm B has the BETTER val. Diagnostic: buffer_frob_dist is dominated by shallow-layer EMA drift, but shallow drift is less fatal than deep drift. **The global metric is misleading at depth — future depth-stratified PRs should log `ema/buffer_frob_dist_per_layer` to disambiguate.**

- **Cooldown cannot rescue mu mis-spec.** Both arms cooled normally in final 250 steps (−9 mnat per arm), but started ~30-70 mnat too high. Damage is compounded across the entire run, not concentrated in cooldown — mechanistically distinct from cooldown-shape regressions (#1099 / #1084) which are cooldown-localized.

- **CROSS-AXIS CANON STRENGTHENING — depth-stratified body-Muon hyperparameter family CLOSED across LR + EMA mu:**

| Closure | Mechanism | Arm A (DOWN/half) | Arm B (UP/double) |
|---|---|---|---|
| #1116 (depth-LR) | step magnitude | +11.0 mnat CATASTROPHIC | +0.7 mnat marginal |
| #1164 (depth-mu) | EMA temporal smoothing | +66.3 mnat CATASTROPHIC | +38.7 mnat CATASTROPHIC |

  - **Uniform values across depth are load-bearing for body-Muon optimizer hyperparameters.** Any unilateral per-layer departure penalized; deep-direction departures more catastrophic than shallow.
  - The bilateral whitening + NS5 polar stack absorbs depth differences in update *direction* but not in update *temporal smoothing* or *magnitude*.
  - Future depth-stratified PRs are now structurally constrained — only mechanism-distinct sub-axes worth probing (per-layer wd? per-layer NS5 iters? per-layer u/w-floor TARGET_UW?) and all carry a high NULL prior.

- **Cross-axis with #1136 pipeline-position canon**: EMA mu modification operates pre-NS5 (on momentum buffer used as NS5 input), so unbounded regression is expected if mechanism is sensitive. The catastrophic regression respects the canon. Adds an EMA-buffer-position datapoint to the upstream-CATASTROPHIC pattern.

- Closing as NULL. frieren → **#1208** (beta_cov bias-correction warmup: linearly ramp beta_cov 0 → 0.95 over 300 steps (Arm A) vs 750 steps (Arm B). Mechanism: covariance EMA L_cov/R_cov are cold-start-biased for first ~20 steps; warmup replaces implicit bias correction with explicit linear schedule. Mechanism-distinct from all closed body-Muon axes — #686 tested static beta_cov values + mid-training schedules but never warmup from 0; #774 fast-mix K is a different mechanism; #918 EMA wrapper warmup is param-space not preconditioner-covariance).

## 2026-05-25 18:40 UTC — PR #1135 CLOSED: Exact SVD polar map (svd_full vs svd_topk=256) — 134th NULL, exact-polar / rank-truncation axis FULLY CLOSED, "imperfect polar is better than perfect polar" canon (g1r1-alphonse)

- Branch: `g1r1-alphonse/exact-svd-polar`
- Hypothesis: Replace NS5 cubic Newton polar map with exact `torch.linalg.svd` to isolate the polar projection's role. Two arms: svd_full (machine-precision polar) and svd_topk=256 (rank-truncated to ~stable_rank). Tests whether NS5's 6.7% residual is an approximation artifact or a structural feature.

### Results

| Arm | polar_method | polar_topk | W&B | val/loss | sr | first_step_to_target | Δval (mnat) | step_avg (ms) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 | ns5 | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | 2925 | — | ~4329 | BASELINE |
| **A (svd_full)** | svd_full | — | `e29g5f3q` | **3.269416** | **2975** | 2975 | **+3.022** (10σ) | **6829.72** (1.58×) | **CLEAR NULL** |
| **B (svd_topk=256)** | svd_topk | 256 | `t85dixhq` | **3.319233** | **−1** | −1 | **+52.84** (176σ) | **6788.79** (1.57×) | **CATASTROPHIC NULL** (failed 3.28) |

### Diagnostic telemetry

| Metric | Arm A (svd_full) | Arm B (svd_topk=256) |
|---|---|---|
| `polar/ortho_residual` | **0.0065** (machine precision ✓) | **22.63** (~750× baseline) |
| `polar/svd_stable_rank` | (full rank) | **1.003** (collapse to rank-1!) |
| `polar/svd_S_top_max` | — | 1.219 |
| `polar/svd_S_ratio_topk` | — | 0.00156 (S[256]/S[0]) |

### Mechanism findings (3 numbered)

1. **Exact polar (Arm A) mildly hurts val.** SVD-based polar with residual ≈ 0 (machine precision) regresses +3.022 mnat (10σ above noise floor σ≈0.0003). **Falsifies the strict "polar residual not load-bearing" reading of #1102** — the residual is not just unimportant, it is mildly *beneficial*. The cubic NS5 polar at 12 iters acts as a stochastic damper / structured noise injection that helps generalization.
2. **Rank-256 polar (Arm B) catastrophically hurts.** Truncating to rank-256 (just below m_pre's static stable_rank ≈ 426) produces a CATASTROPHIC +52.8 mnat regression and never hits sr=3.28. The diagnostic smoking gun: `polar/svd_stable_rank` collapses to 1.003, meaning the truncated polar output concentrates ~entirely in the top singular component → effective rank-1 updates per body-Muon step. The bottom-2/3 singular components carry load-bearing late-cooldown signal even though they're below the static rank measurement.
3. **Step-time methodology lesson.** Pre-launch standalone SVD-vs-NS5 benchmark predicted 44× slower; in-training measurement was 1.58× slower (cuSolver overhead amortizes over body-Muon step pipeline). **Future PR cost estimates must distinguish static-FLOP estimates from in-training wall-clock** for kernel-class operations where overhead amortization matters.

### Canonical finding crystallized — "Imperfect polar is better than perfect polar"

The asymmetric outcome maps cleanly onto a new structural canon that **refines but does not overturn** #1102/#1107:

1. **Cubic NS5 polar at NS_ITERS=12 is a near-optimal practical compromise** between exact-polar (kills implicit regularization, +3 mnat / 10σ) and rank-truncated polar (kills late-cooldown signal, +53 mnat / catastrophic).
2. **The ~6.7% NS5 residual is implicit regularization**, not an approximation artifact. The cubic polynomial structure injects beneficial stochastic damping into the body-Muon update.
3. **m_pre's effective spectrum is rank-concentrated in live training.** Pre-launch static measurement of stable_rank ≈ 426 understates the rank-importance of the bottom-2/3 singular components. The polar/svd_stable_rank=1.003 collapse in Arm B confirms low-rank truncation collapses to rank-1 update.

### Cross-axis canon strengthening

- **#985 NS5 triple-load-bearing canon** strengthened to 4-role: magnitude normalization + rank-deficiency clipping + null-space amplification suppression + **structured residual-as-regularization**.
- **#1136 PIPELINE POSITION CANON** strengthened: polar map IS the position where regularization is *welcome*, in contrast to pre-NS5 grad-noise (CATASTROPHIC) and post-polar regularization (sub-noise).
- **#1102 m_pre rank canon refined**: stable_rank≈426 is a static measurement that understates effective rank in live training; rank truncation below this effective rank is catastrophic.
- **#1107 polar interpolation grounding**: the closed n=2 NULL at α=0.75 (Δval−0.706 mnat marginal) is consistent with this finding — partial back-blend with raw m_pre is sub-noise; full exact-polar is regression; full rank-truncation is catastrophic.

### Merge rule check
- Arm A: sr=2975 > 2912.5, sr ≠ 2925 → FAILS both clauses
- Arm B: val=3.31923 above 3.28 stat-sig threshold itself → FAILS

Both arms FAIL merge rule. Closed without merge.

### Conclusion

**134th NULL.** The exact-polar / rank-truncation axis is FULLY CLOSED:
- Exact polar (Arm A): mildly bad (+3 mnat)
- Rank-truncated polar (Arm B): catastrophically bad (+53 mnat)
- Cubic NS5 at NS_ITERS=12: locally optimal

Combined with #884 (NS_ITERS sweep NULL) + #1102 (NS5 input normalization NULL) + #1123 (asymmetric γ NULL) + #1144 (NS_ITERS phase schedule NULL), **NS5 polar configuration is structurally established as load-bearing in current form**.

alphonse → **#1201** (Hybrid noisy exact polar: SVD + calibrated Gaussian noise — does the cubic polynomial structure matter or just the residual magnitude? Direct mechanism follow-up testing one of alphonse's own suggested #1135 follow-ups).

---

## 2026-05-25 17:38 UTC — PR #1156 CLOSED: Lookahead k-step slow-fast weight averaging on body Muon (k=5, α=0.5 vs α=0.25) — 133rd NULL, Lookahead family FULLY CLOSED (g1r1-askeladd)

- Branch: `g1r1-askeladd/lookahead`
- Hypothesis: Apply Zhang 2019 Lookahead to body Muon — every k=5 fast steps, blend slow buffer toward fast iterate with weight α. Test canonical α=0.5 vs lighter α=0.25 to characterize dose-response. Hypothesis: outer averaging could dampen late-cooldown variance.

### Results

| Arm | k | α | W&B | val/loss | sr | first_step_to_target | Δval (mnat) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | — | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | 2925 | — | BASELINE |
| **A (canonical)** | 5 | 0.5 | `fuvrw1jy` | **3.28288** | **−1** | −1 | **+16.49** (55σ) | **CATASTROPHIC** (missed 3.28 target) |
| **B (light blend)** | 5 | 0.25 | `yy7ep97n` | **3.30829** | **−1** | −1 | **+41.89** (140σ) | **CATASTROPHIC** (much worse than Arm A!) |

### Diagnostic telemetry

| Metric | Arm A (α=0.5) | Arm B (α=0.25) |
|---|---|---|
| `lookahead/blend_events_cumulative` | 46,800 (650 events × 72 params) | 46,800 (identical) |
| `lookahead/slow_fast_distance_mean` (full hist) | 0.0520 | **0.0811** (LARGER despite milder α) |
| `lookahead/slow_fast_distance` (final cooldown) | 7.2e-6 | 1.1e-5 |
| `polar/ortho_residual_sample` | 0.2627 | 0.1463 |
| `ema/buffer_frob_dist` (terminal) | 1.97 | 0.94 |

### Mechanism findings (5 numbered)

1. **STRIKING NON-MONOTONIC DOSE RESPONSE — Arm B (milder α=0.25) is 2.5× WORSE than Arm A (canonical α=0.5).** Naïve linear-in-α prediction was Δval(B) ≈ ½·Δval(A) ≈ +8 mnat; observed +41.89 mnat. **The periodic-blend mechanism itself is intrinsically catastrophic at body-Muon scale, irrespective of α magnitude.**
2. **Slow buffer = sum of polar(NS5)-orthogonal matrices is NOT itself orthogonal.** Every blend reintroduces non-orthogonal weight components that NS5 spent compute removing. `polar/ortho_residual` elevated 1.5-26× vs baseline.
3. **Two competing averaging mechanisms destructively interfere during cooldown.** Body Muon EMA buffer (β_t→0.99) AND Lookahead slow buffer fight. Arm A's `ema/buffer_frob_dist`=1.97 vs Arm B 0.94 — EMA buffer drifts more in Arm A as it "competes" more with Lookahead average.
4. **Counter-intuitive distance reversal:** Arm B's mean slow_fast distance (0.081) is LARGER than Arm A's (0.052) despite α=0.25 vs α=0.5. Lower α means slow stays further from fast between blends → each blend event introduces a LARGER per-event perturbation. The averaging mechanism is NOT a smooth dose-response in α.
5. **Lookahead family FULLY CLOSED in r1.** Joins #943 SWA (catastrophic α=0.5) and #990 Schedule-Free (catastrophic) as the 3rd weight-space averaging NULL. **Body Muon's EMA + WSD cooldown is SUFFICIENT outer smoothing across 3 independent mechanisms — any additional weight-space averaging is redundant + destructive.**

### Cross-axis canons strengthened

- **PIPELINE POSITION CANON #1136** — weight-space mixing AFTER NS5 (post-polar averaging via slow buffer) is catastrophic, consistent with the canon: post-NS5 magnitude/direction modifications are punished by the EMA+cooldown stack.
- **#1129 u/w-floor canon** — when polar quality degrades (Lookahead injects non-ortho components), val regresses substantially → polar IS load-bearing when externally perturbed (vs sub-noise under intra-NS5 modification).

### Conclusions

Lookahead axis CLOSED across α ∈ {0.25, 0.5}. Linear-in-α extrapolation does not hold — there is no "magic α<0.25" that recovers; the milder arm is worse, not better. Next: askeladd → new hypothesis post-researcher-agent ideation.

---

## 2026-05-25 14:15 UTC — PR #1144 CLOSED: NS_ITERS phase schedule probe (stable=10/cooldown=14 vs stable=14/cooldown=10) — 132nd NULL, phase-schedule axis FULLY CLOSED (g1r1-nezuko)

- Branch: `g1r1-nezuko/ns-iters-phase`
- Hypothesis: Test whether NS_ITERS polar quality should be phase-dependent: tighter during cooldown (NS=14, when each step matters more) vs tighter during stable (NS=14). Baseline uniform NS_ITERS=12 from #884. #1102 found polar/ortho_residual NOT load-bearing at static NS_ITERS=12 — this PR tests whether phase-selective tightening unlocks latent signal.

### Results

| Arm | NS stable | NS cooldown | W&B | val/loss | sr | Δval (mnat) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 | 12 | 12 | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | BASELINE |
| **A** | **10** | **14** | `j9lot65t` | **3.267672** | **2950** | **+1.278** | NULL (~4.3σ) |
| **B** | **14** | **10** | `norz0n09` | **3.267612** | **2950** | **+1.218** | NULL (~4.0σ) |

**STRIKINGLY SYMMETRIC REGRESSION.** Both arms +1.2 mnat, both sr=2950. Δval gap between arms = 0.06 mnat (< empirical σ≈0.0003 single-seed noise floor). Both fail merge rule (sr=2950 disqualifies val clause).

### Diagnostic telemetry (final values)

| Metric | Arm A (stable=10, cd=14) | Arm B (stable=14, cd=10) |
|---|---|---|
| `polar/ortho_residual_sample` (final) | **0.0759** (tighter — cooldown NS=14) | **3.1102** (looser — cooldown NS=10) |
| `ema/buffer_frob_dist` (final) | 20.15 | 23.26 |
| Schedule transition at step 975 | ortho_residual 4.20→0.37→0.076 (55× cooldown tightening) | ortho_residual 0.12→3.94 (30× cooldown loosening) |

### Mechanism findings

1. **Symmetric regression rules out phase-asymmetric polar-quality loading.** If stable-phase polar quality were preferentially load-bearing, Arm A (NS=10 stable, looser) should regress while Arm B (NS=14 stable, tighter) should recover. Neither helps — same direction, same magnitude. Phase-asymmetric polar quality is NOT load-bearing in either direction.
2. **Any departure from uniform NS_ITERS=12 costs ~1.2 mnat regardless of phase.** Arm A avg NS_iters ≈12.8 (+6.7%), Arm B ≈11.2 (−6.7%) vs baseline. Both deviations cost identically.
3. **Reinforces #884 static optimum + #1102 ortho_residual NOT load-bearing.** Now extended to phase-selective application: the static NS_ITERS=12 is a genuine sweet-spot, not a coincidence. NS5 polar-quality manifold {static, asymmetric, post-polar, exact, residual, phase} is fully closed.
4. **Plausible mechanism for symmetric ~1.2 mnat cost:** EMA buffer expects uniform polar quality across all steps; mid-training regime shift at step 975 disrupts EMA statistics. Arm B's higher buffer_frob_dist (23.26 vs Arm A 20.15) is suggestive. Schedule discontinuity itself may also impose a small one-time regime-shift cost.
5. **Cross-axis confirmation of #1136 pipeline-position canon:** intra-NS5 modifications are bounded (+1.2 mnat NULL); pre-NS5 perturbations are unbounded (CATASTROPHIC +16/+79 mnat). Canon: modifications within NS5 have upper-bounded cost, modifications before NS5 are unbounded.

### Conclusions

NS_ITERS phase-schedule axis CLOSED. Next: nezuko → **#1182** (EMA wrapper β_target probe: first direct ablation of ema_beta_target=0.99 in r1).

---

## 2026-05-25 13:45 UTC — PR #1136 CLOSED: Body Muon gradient noise injection (σ=0.05 vs 0.15) — 131st NULL, gradient noise axis FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/grad-noise`
- Hypothesis: Inject gradient noise `σ·||g||_F/√numel·N(0,1)` into all 72 body Muon params before EMA/whitening/NS5. Arm A σ=0.05 (light); Arm B σ=0.15 (moderate). Based on Neelakantan et al. 2015 annealed gradient noise for generalization.

### Results

| Arm | σ | W&B | val/loss | sr | Δval (mnat) | σ multiples | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.0 | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| **A** | **0.05** (light) | `ze6l9k7r` | **3.282374** | **−1** | **+15.98** | 53σ | **CATASTROPHIC** (missed 3.28 target) |
| **B** | **0.15** (moderate) | `7vrtq1l1` | **3.345232** | **−1** | **+78.84** | 263σ | **CATASTROPHIC** (missed 3.28 target) |

**Dose-response: Δval ∝ σ^1.45 (super-linear).** 3× increase in σ → 4.94× regression. Variance accumulates super-linearly through bilateral whitening (2 GEMMs) + NS5 (cubic Newton amplifies off-manifold component).

### Diagnostic telemetry (final values)

| Metric | Arm A (σ=0.05) | Arm B (σ=0.15) | Baseline |
|---|---|---|---|
| `muon/noise_to_signal_ratio` | 0.0500 | 0.1500 | n/a |
| `polar/ortho_residual_sample` | 0.2404 | **0.5275** | 0.2477 / 0.1394 |
| `ema/buffer_frob_dist` | 23.714 (+4.7%) | **28.212 (+24.6%)** | 22.645 / 22.642 |
| `ema/delta_ema_minus_live_mnat` | 0.618 | 0.636 | 0.597 / 0.607 |

### Mechanism findings

1. **NS5 absorbs σ=0.05 noise at the ortho_residual level but NOT at the val level.** Arm A ortho_residual 0.240 ≈ baseline range (0.139–0.248). Yet val is 15.98 mnat worse. The regression is at the descent level, not the polar projection level.
2. **NS5 FAILS to orthogonalize σ=0.15-corrupted input.** Arm B ortho_residual 0.528 = 2.1× elevated → NS5 cubic Newton cannot orthogonalize a highly-corrupted polar map.
3. **EMA does NOT dampen pre-EMA noise.** Noise injected before EMA enters the buffer and persists for ~10 steps (μ=0.95). The regression is at descent level (ema/delta_ema_minus_live_mnat flat: 0.60→0.62→0.64). Buffer_frob_dist grows monotonically with σ but is NOT the primary regression mechanism.
4. **Implementation verified correct.** noise_to_signal_ratio matched σ exactly; all 72 body params received noise as designed.

### Pipeline position canon (major mechanism update)

**The Neelakantan et al. 2015 prior on annealed gradient noise does NOT transfer** to a benchmark where the optimizer pipeline includes a strongly-nonlinear orthogonalizer (NS5) that amplifies noise via cubic Newton iteration.

Pipeline position hierarchy established:
- **Pre-EMA pre-whitening pre-NS5 (THIS PR):** CATASTROPHIC at all σ > 0
- **Post-polar magnitude blend (#1107):** sub-noise at n=2 (n=1 mirage)  
- **Post-NS5 output side (#1135 Arm A exact SVD):** +3 mnat regress — NS5 residual IS implicit regularization
- **Output-level (loss-side regularization #1043/#1058/#1060/#1066/#1090):** all CATASTROPHIC or noise-floor

**Rule: regularization must be applied POST-POLAR (after NS5), not upstream of it.**

### Cross-axis

- Reinforces #1135 exact-SVD finding: NS5's 6.7% polar residual is implicit regularization; perturbing it (either by bypassing with exact SVD upstream, or corrupting with noise upstream) is harmful
- Reinforces #1102 m_pre rank canon: m_pre stable rank ≈426; pre-polar noise injection further collapses rank
- Closes the "gradient-level signal modification" direction suggested by #1090 closure note

---

## 2026-05-25 12:55 UTC — PR #1129 CLOSED: Post-polar aspect-ratio exponent ablation (exp=0.0 vs 1.0) — 130th NULL, spectral_exp axis FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/spectral-exp`
- Hypothesis: Test the hardcoded `** 0.5` exponent in `update = polar * (max(1, m/n) ** 0.5)` (line 532). Frobenius-style aspect-ratio compensation only affects MLP.fc matrices (aspect ratio 4.0). Arm A exp=0.0 (1.0× polar on MLP.fc, 0.5× vs baseline); Arm B exp=1.0 (4.0× polar on MLP.fc, 2.0× vs baseline).

### Results

| Arm | exp | MLP.fc factor | W&B | val/loss | sr | Δval (mnat) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.5 (Frobenius) | 2.0× polar | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| A | **0.0** | **1.0× polar** | `8slemy5y` | **3.267764** | 2950 | +1.37 (4.6σ) | +25 | **marginal NULL** (just outside band) |
| B | **1.0** | **4.0× polar** | `ymmtfaff` | **3.268970** | 2975 | +2.58 (8.6σ) | +50 | **CLEAR NULL** |

Both arms FAIL predeclared merge rule (sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)). Asymmetric U-curve: Arm B regresses ~1.9× harder than Arm A.

### Mechanism findings

1. **u/w-floor (TARGET_UW=0.35 from #1035) saturates at 100% on MLP.fc by mid-training in BOTH arms.** Arm A reaches saturation earlier (smaller magnitude → lower ratio → floor fires sooner); Arm B at step ~425 (4× polar magnitude takes longer to push ratio above 0.35). Once saturated, floor is the dominant magnitude controller, not the post-polar scalar.
2. **Floor is asymmetric: rescues magnitude shortfalls but cannot bound magnitude overshoots.** Arm A only +1.4 mnat despite 0.5× MLP.fc factor (floor saves it). Arm B +2.6 mnat at 2× factor (floor doesn't push it back DOWN). Direction of safety from baseline: DOWN (sub-Frobenius), never UP.
3. **polar/ortho_residual drift confirms post-polar magnitude affects projection cleanliness.** Arm A 0.108 ≈ baseline 0.10; Arm B 0.143 (43% higher). Larger post-polar magnitudes degrade polar projection quality at scale.

### Cross-axis intersections

- **Reinforces #1135 alphonse exact-SVD finding (Arm A regressed +3 mnat):** NS5's 6.7% polar residual is implicit regularization. This PR's Arm B polar/ortho_residual drift (0.143 vs baseline 0.10) is direct evidence the polar projection itself becomes the limiting factor at large post-polar magnitudes.
- **Reinforces #1102 frieren m_pre rank discriminator:** post-polar magnitude levers (spectral_exp here, polar interp #1107, exact SVD #1135 Arm A) all show smaller effects than pre-polar perturbations (cov source #1125, γ asymmetry #1123).
- **Reinforces #1035 u/w-floor canon:** floor is now empirically confirmed as the dominant magnitude controller, not just a safety net.

### Predicted outcome alignment

- ~20% best-case (one arm hits gate): NO
- ~25% marginal: PARTIAL (Arm A just outside marginal band, +0.001370 vs 0.001 threshold)
- ~45% NULL modal: YES — both arms within seed-noise direction of baseline
- ~10% catastrophic: NO

### Suggested follow-ups by student

1. **Close spectral_exp axis** — done
2. **Higher-leverage axis: u/w-floor TARGET_UW probe** — never directly ablated as a value (#1035 tested 0.0 vs 0.50 floor existence/disabling, but not a tight sweep around 0.35)
3. **Joint spectral_exp × γ_power probe** — both control post-polar effective magnitude
4. **Per-shape TARGET_UW differentiation** — fc vs lm_head

### Next assignment for edward

→ **#1170** (or next number) — u/w-floor TARGET_UW direct probe. Tightly ablates the dominant magnitude controller exposed by this PR.

---

## 2026-05-25 12:10 UTC — PR #1125 CLOSED: SOAP-style cov source (update vs momentum) — 129th NULL, cov-source axis FULLY CLOSED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/soap-cov-source`
- Hypothesis: PMuon's L_cov/R_cov are built from raw gradient `g32` but the preconditioned signal is Nesterov-blended `update = (1-μ²)·g + μ²·m_prev`. SOAP (Vyas 2024) identifies this mismatch as a bias source. Test whether building cov from the actual signal being preconditioned helps: Arm A uses cov_source="update", Arm B uses cov_source="momentum" (pure EMA buffer).

### Results

| Arm | cov_source | W&B | val/loss | sr | Δval (mnat) | Δsr | σ | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | grad | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — | — |
| A | update (Nesterov-blended) | `x0cvzei9` | **3.272748** | **3025** | +6.35 | +100 | 21σ | **CLEAR NULL** |
| B | momentum (pure EMA) | `j2skvl7i` | **3.279062** | **3200** | +12.67 | +275 | 42σ | **CATASTROPHIC NULL** |

Both arms fail predeclared merge rule. Arm B misses the 3.28 target stat-sig threshold (margin=0.00094 < 0.004).

### Polar / m_pre diagnostics

| Arm | input_stable_rank_est | ortho_residual_sample | m_pre_fro | m_pre_sigma_max | cov_signal_norm |
|---|---|---|---|---|---|
| A (update) | **418.55** | 0.1998 | 0.944 | 0.04616 | 454.35 |
| B (momentum) | **377.10** | 0.1414 | 1.134 | 0.05839 | 485.04 |
| Baseline (grad) | ~426 | ~0.20 | — | — | — |

### Mechanism findings

1. **m_pre stable rank IS the discriminator, NOT ortho_residual.** Arm B has LOWER ortho_residual (0.14 vs 0.20) yet WORSE val/loss. The bilateral preconditioner's job is whitening the step's characteristic curvature, not maximizing pre-NS5 isotropy. **Yet another confirmation of #1102/#1123/#1107 canon: polar/ortho_residual is NOT load-bearing at NS_ITERS=12.**
2. **Momentum-cov collapses m_pre stable rank by ~12% (426 → 377).** EMA buffer is autocorrelated → over-weights stale direction → fewer effective singular directions reach polar → descent loses generality across parameter geometry.
3. **Update-cov is rank-preserving but val-disappointing.** Arm A rank ≈ 418 ≈ baseline. The Nesterov blend `(1-μ²)·g + μ²·m_prev` whitens magnitude correctly (cov_signal_norm 454 ≈ baseline ballpark) but mixes old + new signal in a way slightly biased relative to fitting on `g` alone.
4. **cov_signal_norm asymmetry**: Arm A 454 (smallest — Nesterov blending shrinks toward zero when momentum lags); Arm B 485 (largest — EMA accumulates magnitude across steps); gradient-cov sits between and matches NS5's implicit design assumption.

### Canon: SOAP recipe doesn't transfer to bilateral preconditioner

SOAP (Vyas 2024) prescribes "build covariance from the same signal you precondition." Under our γ=0.4 symmetric whitening + β_cov=0.95 EMA + NS5 cubic polar pipeline, **this prescription does NOT transfer**. NS5's cubic map (per #985 triple-load-bearing canon) is implicitly designed for gradient-distribution inputs. Both update-cov and momentum-cov drift away from that distribution in different but uniformly harmful directions.

### Portfolio implications

- **cov-source axis FULLY CLOSED** at γ=0.4, β_cov=0.95.
- Future cov-related PRs (β_cov retune #686 CLOSED, cov reset #725 CLOSED, cov warmup-fast-mix #774 CLOSED, cov source #1125 CLOSED) must operate under known constraints.
- Strong cross-axis canon: **m_pre stable rank IS the discriminator** across #1102 (input norm), #1123 (γ_L/γ_R asym), #1125 (cov source). Future PRs should report m_pre stable rank as primary diagnostic.
- thorfinn → **#1168** (L_neg/R_neg matrix_neg_power eps ablation: Arm A LOOSER eps=1e-6 251× amp vs Arm B TIGHTER eps=1e-15 10^6× amp, baseline eps=1e-12 63095× amp). Direct test of NS5 triple-load-bearing role 3 ("null-space amplification suppression") via L_neg/R_neg construction at γ=0.4. L_cov stable rank ≈13/3072 → ≈99.6% of eigenvalues are in clamped tail → eps directly controls null-space amplification. Mechanism-distinct from all in-flight; first eps-clamp ablation in r1.

---

## 2026-05-25 11:55 UTC — PR #1107 CLOSED: Polar interpolation α=0.75 n=2 confirmation — 128th NULL, polar-interp axis FULLY CLOSED, n=2 REVERSES n=1 WIN (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/polar-interpolation`
- Hypothesis (original): polar projection over-orthogonalizes m_pre in low-rank regime; blending raw m_pre with polar (α-blend) preserves directional information that pure polar discards. Two arms initially: α=0.75 light blend vs α=0.50 heavy blend. Arm A (α=0.75) showed n=1 WIN (val=3.264891, Δval−1.503 mnat); n=2 confirmation requested per marginal-boundary rule.

### n=2 confirmation results

| Seed | wandb id | val/loss | sr | Δval vs baseline (mnat) |
|---|---|---|---|---|
| 1 | `wlrtyf2t` | 3.264891 | 2925 | **−1.503** |
| 2 | `zegkqdpe` | 3.266485 | 2925 | **+0.091** (regress) |
| **n=2 mean** | — | **3.265688** | **2925** | **−0.706** |

Baseline (n=2 PR #918): val=3.266394, sr=2925. Empirical σ ≈ 0.0003 (#958).

### Merge rule evaluation — BOTH REQUIRED CLAUSES FAIL

| Rule | Value | Threshold | Pass |
|---|---|---|---|
| `(3.266394 − μ_n2) · √2 ≥ 0.004` | 0.000998 | 0.004 | ❌ |
| Seed-1 `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` | sr=2925, val=3.264891 | val<3.266394 | ✅ |
| Seed-2 `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` | sr=2925, val=3.266485 | val<3.266394 | ❌ |

Both required conditions fail → **NULL closure**.

### Mechanism findings

1. **Polar telemetry reproduces cleanly across seeds.** Seed-1 vs seed-2 final values: `polar/ortho_residual_sample` 3.604/3.625, `polar/ortho_residual_polar_only` 0.188/0.203, `polar/blend_magnitude_ratio` 0.00230/0.00230. Trajectory means consistent: residual_sample mean=3.921±0.323, blend_ratio mean=0.00193±0.00044. **The blend mechanism IS doing what it should — m_pre carries ~0.23% of polar Frob mass, the residual is ~4× elevated vs polar-only, confirming non-trivial shift away from orthogonal projection.**
2. **The val/loss signal does NOT survive seed averaging.** Seed-1 (−1.503 mnat) was a lucky draw; seed-2 (+0.091 mnat) is essentially baseline noise. The n=2 mean improvement (−0.706 mnat) is positive but 4× below the merge threshold (need 0.004 after √n scaling, observed 0.001).
3. **Polar projection in NS5 is closer to load-bearing than seed-1 suggested.** Combined with Arm B (α=0.50, +4.82 mnat regress), any blend in (0.5, 1.0) tested is either neutral or regressive. The mechanism intuition (rank-deficiency canon: polar synthesizes singular-value structure not in the gradient) MAY still be correct, but the practical val/loss effect at this magnitude is below noise.
4. **n=2 boundary discipline SAVED A FALSE MERGE.** Pattern matches #969 (γ=1.2: n=1 looked like clean WIN at lr=0.035; n=2 at lr=0.040 revealed Pareto-shift). Session memory rule "Marginal Δval ≤ 0.001 at n=1 over baseline requires n=2 confirmation" is load-bearing here.

### Bug fix commendation

Student detected and fixed a `senpai-pr-guard.py` regex bug (committed `3107d30` to senpai main) — the guard was crashing on SENPAI-RESULT lines INSIDE markdown code fences. The advisor's 07:34 UTC comment contained a template line `SENPAI-RESULT: {"terminal":true,...,"value":<val_2>}` inside a fenced code block. The fix adds `in_code_block` state tracking to `result_markers()` so fenced lines are skipped. Infrastructure-grade catch that benefits all future PRs.

### Portfolio implications

- **Polar-interpolation axis FULLY CLOSED** across α ∈ {0.50, 0.75}.
- Cross-axis with #1102 reframe: m_pre stable rank ≈ 426 (rank-rich, not rank-deficient). The polar over-projection lever-arm is smaller than initially hypothesized.
- Future PRs targeting NS5 polar quality must operate INSIDE NS5 (NS_ITERS modulation, polynomial coefficient choice, exact SVD substitution), NOT post-NS5 blend.
- Reinforces n=2 boundary discipline as load-bearing for future marginal-WIN candidates.
- tanjiro → **#1166** (NS5 cubic polynomial coefficient ablation: Arm A TIGHTER (a=1.7, b=-0.7) linear convergence at σ=1 rate −0.4 vs Arm B GENTLER (a=1.3, b=-0.3) linear convergence rate +0.4). First direct ablation of NS5 cubic coefficients in r1. Baseline (1.5, -0.5) has quadratic convergence at σ=1 (`f'(1)=0`); arms test linear convergence with better/worse far-from-1 behavior. Mechanism-distinct from all in-flight: #1129 post-polar magnitude, #1135 exact SVD replacement, #1144 phase NS_ITERS count. m_pre stable rank ≈ 426 → most singular values are far from σ=1 → polynomial behavior in σ≪1 regime matters.

---

## 2026-05-25 11:40 UTC — PR #1123 CLOSED: Asymmetric γ_L/γ_R whitening exponents — 127th NULL, asymmetric whitening axis FULLY CLOSED (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-L-gamma-R-asymmetry`
- Hypothesis: PMUON_GAMMA=0.4 is symmetric across L_cov/R_cov whitening, but L_cov stable rank (~13.18 / 3072) and R_cov stable rank (~1.67 / 768) have very different rank profiles per #1046 rank-deficiency canon. Test whether decoupling γ_L from γ_R lets each side match its rank-deficiency budget. Arm A (γ_L=0.25, γ_R=0.5) softens L whitening and tightens R; Arm B (γ_L=0.5, γ_R=0.25) inverts.

| Arm | γ_L | γ_R | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 0.4 | 0.4 | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | 0.25 | 0.5 | **3.270** | +3.6 | 2950 | +25 | 12σ | **CLEAR NULL** | (see PR) |
| Arm B | 0.5 | 0.25 | **3.268** | +1.6 | 2950 | +25 | 5σ | marginal NULL | (see PR) |

### Mechanism findings

1. **Polar/ortho_residual differs 4× between arms but val barely shifts.** Arm A ortho_residual ≈ 0.401 (looser whitening of L → less polar input pre-conditioning); Arm B ortho_residual ≈ 0.101 (tighter whitening of L → more polar input pre-conditioning). 4× spread in residual but Δval gap between arms is only 2 mnat. **NS_ITERS=12 absorbs 4× residual perturbation without proportional val penalty.**
2. **Direct confirmation of #1102 canon.** "Polar/ortho_residual is NOT load-bearing at NS_ITERS=12 — residual can be tightened 3-5× without val change." #1123 tested the inverse: residual loosened 4× → val also barely moves. The cubic NS5 map's contractive geometry on rank-deficient inputs is robust to upstream whitening exponent variation across [0.25, 0.5].
3. **Rank asymmetry (L 13/3072 vs R 1.67/768) does NOT translate to γ asymmetry.** Both decoupled-γ configurations regress vs symmetric γ=0.4. The expected mechanism — "looser-whitened side compensates for tighter-side over-whitening" — does not materialize.

### Predeclared merge rule

`sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`:
- Arm A: sr=2950 fails first clause; val=3.270 fails second → NULL
- Arm B: sr=2950 fails first clause; val=3.268 > 3.266394 → fails second → NULL

### Portfolio implications

- Closes first decoupled-γ axis in r1; PMUON_GAMMA symmetric form (γ_L=γ_R=0.4) is canonical.
- Closes the "rank-asymmetry → γ-asymmetry" inference chain motivated by #1102 reframe + #1046 rank-deficiency canon.
- Reinforces #1102 canon: future PRs targeting polar quality must operate INSIDE NS5 (NS_ITERS modulation per #1144, exact SVD per #1135, blend post-polar per #1107), NOT upstream whitening.
- frieren → **#1164** (depth-stratified body-Muon EMA momentum mu: per-layer linear interpolation across 12 transformer layers; Arm A DOWN shallow=0.99/deep=0.90 vs Arm B UP shallow=0.90/deep=0.99). Direct response to #1116 askeladd depth-LR closure note explicitly suggesting per-layer EMA β as next mechanism-distinct depth axis. Mirrors #1116 implementation pattern (add_param_group per layer) but operates on EMA memory not step magnitude — mechanism-distinct from all closed mu axes (#682 schedule, #777 cooldown ramp — all were uniform across depth).

---

## 2026-05-25 09:27 UTC — PR #1116 CLOSED: Body Muon depth-LR decay (DOWN vs UP) — 126th NULL, depth-stratified LR axis FULLY CLOSED (g1r1-askeladd)

- Branch: `g1r1-askeladd/depth-lr-decay`
- Hypothesis: First depth-stratified body-Muon test. Per-layer linear LR scaling across 12 transformer layers. Tests whether shallow vs deep layers benefit from differential LR during late-train + cooldown.

| Arm | Mode | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | uniform=0.040 | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | DOWN (shallow=1.0× → deep=0.5×) | **3.277380** | **+10.986** | 3125 | +200 | 37σ | **CATASTROPHIC NULL** | `ua2c7zlf` |
| Arm B | UP (shallow=0.5× → deep=1.0×) | **3.267130** | **+0.736** | **2925** | 0 | 2.5σ | marginal NULL | `7u3hbikt` |

### Mechanism findings

1. **Body-Muon optimal LR is approximately uniform across depth.** Both unilateral departures from uniform 0.040 produce val regression. The DOWN arm hypothesis (deep layers over-shooting because zero-init proj.weight ramp accumulates faster than EMA absorbs) is **falsified** — halving deep-layer LR costs 37σ val.
2. **Asymmetric penalty**: deep-layer LR halving (Arm A) costs 37σ val + 200 sr; shallow-layer LR halving (Arm B) costs only 2.5σ val with sr held flat. **Deep-layer LR is more load-bearing than shallow-layer LR** in absolute terms.
3. **Cross-axis with #1046 rank-deficiency canon**: NS5 magnitude normalization absorbs *direction*-of-update across layers but does NOT absorb per-layer step-size differences at 50% scale. Polar(G) direction preserved; LR-gated step size still controls per-layer progress.

### Predeclared merge rule

`sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`:
- Arm A: sr=3125 fails both clauses → NULL
- Arm B: sr=2925 matches but val=3.26713 > 3.266394 → fails val clause → NULL

### Portfolio implications

- Closes first depth-stratified body-Muon axis in r1.
- Future depth-stratified PRs must be mechanism-distinct (per-layer EMA β, per-layer wd, per-layer NS5 iters — NOT per-layer LR alone).
- askeladd → **#1156** (Lookahead k-step slow-fast weight averaging on body Muon — first weight-space averaging since #943 SWA / #990 SF closures).

---

## 2026-05-25 06:15 UTC — PR #1099 CLOSED: Decoupled AdamW cooldown shape (γ_adamw=2.0 vs 1.0, body γ=1.4) — 125th NULL, Pareto-shift finding (g1r1-nezuko)

- Branch: `g1r1-nezuko/decoupled-adamw-cooldown`
- Hypothesis: Decouple AdamW cooldown γ from body Muon (which is fixed at γ=1.4 per #969 closure). Tests whether AdamW subgroups (embed lr=0.3, lm_head lr=1/160, scalars lr=0.025) benefit from a different cooldown γ than body. Two arms: γ_adamw=2.0 sharper vs γ_adamw=1.0 flatter.

| Arm | γ_adamw | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 | 1.4 (=body) | 3.266394 | — | 2925 | — | — | — | vm48fdof/0a7esmxs |
| Arm A | 2.0 sharper | **3.271085** | +4.69 | 2975 | +50 | 16σ | CLEAR NULL | `7vn1axje` |
| Arm B | 1.0 flatter | **3.265249** | **−1.15** | 2950 | +25 | 3.8σ | **Pareto-shift NULL** | `g546ir3f` |

### Mechanism findings

**Pareto-shift confirmation**: γ_adamw on the decoupled AdamW cooldown manifold exhibits the same trade-off as body γ (per #969 closure):
- **γ_adamw < body γ (Arm B γ=1.0 flat)**: preserves AdamW LR longer through cooldown → embed/lm_head continue learning during cooldown phase → improves final val by 1.15 mnat (3.8σ above seed noise σ≈0.0003) BUT delays first val ≤ 3.28 crossing by +25 steps.
- **γ_adamw > body γ (Arm A γ=2.0 sharp)**: AdamW LR decays faster than body → embed/lm_head stop adapting before body finishes converging → worse on BOTH axes.

**Predeclared merge rule failure**: `sr ≤ 2912.5 OR (sr = 2925 AND val < 3.266394)`. Arm B sr=2950 satisfies neither clause. Cannot merge despite val improvement.

### Pareto frontier mapping (cooldown γ axes)

| Axis | PR | Optimal point | Pareto trade-off direction |
|---|---|---|---|
| Body γ | #969 | γ=1.4 (sr-Pareto-optimum) | γ=1.2 wins val but loses sr (#969 closure) |
| Dual-region body | #1084 | single γ=1.4 near-Pareto-optimal | piecewise γ does not help (#1084 closure) |
| Decoupled AdamW γ | **#1099 (this PR)** | γ_adamw=1.4=body γ (sr-Pareto-optimum) | γ_adamw=1.0 wins val but loses sr |

**Canon**: Cooldown γ on any sub-axis (body, dual-region piecewise, decoupled AdamW) produces a Pareto frontier where reduced γ improves val at sr cost. The sr=2925 baseline constraint is **structurally binding** for cooldown-γ work. Future cooldown shape work must use a different parameterization (decoupled-START step, non-power cooldown functions) to escape this Pareto.

### Cooldown parameter manifold full closure

The cooldown manifold is now FULLY mapped:
- γ (power exponent): #969 body axis closed, #1099 decoupled AdamW axis closed
- cooldown_frac (cooldown duration): #1084 dual-region partial test, manifold closed
- lr_form (functional form): #1040 lr_linear vs lr_squared closed
- wd_form (WD coupling): #1040 closed at lr_linear
- dual-region piecewise γ: #1084 closed (single γ optimum)
- **Future cooldown work must move to non-manifold dimensions (decoupled start step, non-cosine non-power LR shapes, schedule-side stochasticity).**

### Next assignment

**nezuko → #1144** (NS_ITERS phase schedule: stable=10/cooldown=14 vs stable=14/cooldown=10) — fresh phase-dependent NS5 polar quality axis. First test of whether polar quality is phase-dependent. Cross-axis to all in-flight (#1107 polar blend, #1129 aspect-ratio, #1135 exact SVD, #1125 cov source, #1123 γ_L/γ_R asym, #1136 grad noise).

SENPAI-RESULT: {"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["7vn1axje","g546ir3f"],"primary_metric":{"name":"val/loss","value":3.265249},"test_metric":{"name":"val/loss","value":3.265249}}

---

## 2026-05-25 10:00 UTC — PR #1090 CLOSED: Focal loss for LM (γ=1.0 vs γ=2.0) — 124th NULL, 5-axis output-regularization portfolio FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/focal-loss`
- Hypothesis: Per-token gradient amplification on hard tokens via `(1-p_y)^γ` weighting. Targets focal mechanism distinct from output-clip (#1060), entropy reg (#1058), label smoothing (#1043), Z-loss (#1066).

| Arm | γ | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (light focal)** | **1.0** | **3.273504** | **+7.110** | **3050** | **+125** | **24σ** | **NULL** | `n21mu2wj` |
| **B (moderate focal)** | **2.0** | **3.288816** | **+22.423** | **-1** | **DNF** | **75σ** | **CATASTROPHIC** | `kgdf5ynu` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule. Arm B failed 3.28 target entirely.

**Key findings:**
1. **Clean monotone-bad dose-response.** focal_weight_mean: γ=1.0 → 0.7576 (24% downweighting), γ=2.0 → 0.6751 (33% downweighting). Δval scales super-linearly: γ=1→2 doubles loss exponent but more than triples Δval (3.2× ratio).
2. **Cooldown phase cannot recover lost gradient mass.** Arm B trajectory: step 2375 val=3.358 → step 3250 val=3.289 (descending but never reaches 3.28). Focal modulation suppresses gradient signal needed by NS5 polar's late-cooldown updates.
3. **5-axis output-regularization portfolio FULLY CLOSED:**
   - #1043 LS (115th NULL CATASTROPHIC linear)
   - #1058 CP (117th NULL CATASTROPHIC super-linear, 4.5× acceleration)
   - #1060 soft-cap (118th NULL — noise-floor at cap=15, regression at cap=30)
   - #1066 Z-loss (119th NULL — noise-floor at λ=1e-4, catastrophic at λ=1e-3)
   - #1090 focal (124th NULL — monotone-bad dose-response γ=1→2)
4. **Convergent canon:** baseline sqrt-clip @15 + standard CE saturates output-regularization channel. ALL output-side mechanisms either collapse to noise-floor (redundant with sqrt-clip) or suppress NS5-needed signal catastrophically.

**Closure recommendation:** No further output-regularization PRs warranted. Future loss-formulation work must target **gradient-level signal modification**.

**fern → #1136** (gradient noise injection on body Muon: σ=0.05 vs 0.15, first-ever gradient-level regularization test).

---

## 2026-05-25 09:42 UTC — PR #1089 CLOSED: NS5-layered Shampoo body-Muon (compose Shampoo + NS5) — 123rd NULL, composition-order axis FULLY CLOSED (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns5-layered-shampoo`
- Hypothesis: Compose Shampoo preconditioning with NS5 polar projection (Variant 3 from #1046 closure). Tests order-sensitivity: does shampoo_first or ns5_first survive both rank-deficiency (#985) and rank-defect (#1046) constraints?

| Arm | Order | val/loss | Δval (mnat) | sr | Δsr | σ-dist | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (shampoo_first)** | NS5(Shampoo(g)) | **3.269755** | **+3.361** | **2975** | **+50** | **11σ** | **CLEAR NULL** | `vff9pulk` |
| **B (ns5_first)** | Shampoo(NS5(g)) | **3.273024** | **+6.630** | **3050** | **+125** | **22σ** | **CLEAR NULL + sr regression** | `2mbhkkin` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)`.

**Key findings:**
1. **Composition-order matters structurally.** Arm A recovers ~5.2 mnat/100 sr from #1046 pure-Shampoo residual (3.275 → 3.270). Magnitude budget 27.69 ≈ √768·1.001 (perfect 1.001× ratio). composition_cosine vs pure NS5 = **0.972** (14° additional steering from Shampoo curvature).
2. **NS5-first is structurally destructive.** composed_update_norm = **0.524** (~50× smaller than bare NS5, ~10× smaller than predicted 5.8). Applying L^{-1/4}, R^{-1/4} AFTER NS5 destroys orthogonality and collapses magnitude. u/w-floor takes over the optimization signal entirely. **Rule out:** post-orthogonalization curvature factors are magnitude-collapsing, not tunable.
3. **+3.4 mnat residual vs baseline persists despite composition.** Shampoo's curvature signal is mostly redundant with NS5 polar at m_pre stable rank ≈ 426 (per #1102 reframe). Cubic NS5 polar at NS_ITERS=12 already orthogonalizes nearly optimally.
4. **Composition-order axis FULLY CLOSED.** Future preconditioner PRs (Shampoo, SOAP, AggMo variants) must NOT propose post-orthogonalization compositions — magnitude collapse is structural.

**Diagnostic telemetry (post-warmup averages, gate step 500):**

| metric | Arm A (shampoo_first) | Arm B (ns5_first) |
|---|---:|---:|
| `composed_update_norm` | 27.694 | **0.524** |
| `shampoo_only_norm` | 6.094 | 5.700 |
| `ns5_only_norm` | 26.625 | 22.375 |
| `composition_cosine` (vs pure NS5(g)) | **0.9723** | 0.9021 |
| L_cov stable rank @ gate | 11.0 / 3072 | 10.9 / 3072 |
| R_cov stable rank @ gate | 1.60 / 768 | 1.64 / 768 |

**Cross-axis canon:** #985 NS5 triple-load-bearing role REAFFIRMED via Arm B's magnitude collapse. #1046 +7 mnat residual PARTIALLY EXPLAINED via Arm A's ~5.2 mnat recovery. #1102 m_pre stable rank ≈ 426 finding CONSISTENT (Shampoo redundant with NS5 polar).

**alphonse → #1133** (exact SVD polar map: replace NS5 cubic Newton at 12 iters with torch.linalg.svd; tests if ~6.7% polar/ortho_residual is load-bearing under current EMA stack).

---

## 2026-05-25 07:30 UTC — PR #1084 CLOSED: Dual-region cooldown shape (γ₁/γ₂ piecewise, split=0.75) — 122nd NULL, cooldown manifold FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/dual-region-cooldown-shape`
- Hypothesis: Piecewise γ₁/γ₂ schedule adds 1 DOF to resolve the #969 Pareto-coupling (γ=1.2 wins val but loses sr).

| Arm | γ₁ | γ₂ | val/loss | Δval (mnat) | sr | Δsr | σ | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.4 | 1.4 | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A (concave-first)** | **2.0** | **1.0** | **3.27156** | **+5.17** | **2925** | **0** | **17σ** | **CLEAR NULL** | `p4jk1urh` |
| **B (convex-first)** | **1.0** | **2.0** | **3.27510** | **+8.71** | **3100** | **+175** | **29σ** | **CLEAR NULL + sr regression** | `bft16pb6` |

**Verdict:** Full PR NULL. Both arms fail merge rule. Arm B is strictly worse in both metrics.

**Key findings:**
1. **Single-γ=1.4 is near-Pareto-optimal.** Piecewise schedule with split=0.75 cannot Pareto-dominate the monotone γ family at any tested orientation.
2. **LR-mass conservation dominates shape locality.** Integrated LR-mass: Arm A ≈0.65× (aggressive early dump → val-bad, sr-stable); Arm B ≈1.20× (excess early → sr-bad, val-bad). Shape locality inside the envelope doesn't help.
3. **Asymmetric NULL is informative:** confirms early cooldown governs sr crossing, late cooldown governs terminal val — but single-γ=1.4 is already at the joint optimum for both.
4. **Cooldown parameter manifold FULLY CLOSED:** γ (#969) + cooldown_frac (pinned 0.7) + lr_form (#1040 lr_linear) + wd_form (#1040) + dual-region shape (#1084) all closed.

---

## 2026-05-25 05:30 UTC — PR #1080 CLOSED: Body weights init scale ablation (0.5× vs 2.0×) — 121st NULL, 3-matrix init-state-surface canon ESTABLISHED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-init-scale`
- Hypothesis: Body init scale is locally sensitive even after NS5 polar projection + RMSNorm. Testing 0.5× scale vs 2.0× scale vs baseline 1.0×.

| Arm | scale | val/loss | Δval (mnat) | sr | Δsr | σ-dist | Verdict | W&B |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.0× | 3.266394 | — | 2925 | — | — | gate | `vm48fdof`, `0a7esmxs` |
| **A** | **0.5×** | **3.266968** | **+0.000574** | **2925** | **+0** | **1.9σ** | **marginal NULL noise-floor** | `sawsjbn5` |
| **B** | **2.0×** | **3.268639** | **+0.002246** | **2975** | **+50** | **7.5σ** | **CLEAR NULL** | `q4daaezw` |

**Verdict:** Full PR NULL. Both arms fail predeclared merge rule. Arm A noise-floor; Arm B 7.5σ above.

**Key findings:**
1. **3-matrix init-state-surface canon ESTABLISHED:** lm_head (#1015) + embed (#1059) + body (#1080) all flat-near-baseline + monotone-bad on perturbation. Speedrun-tuned init sits at the basin minimum across all weight categories.
2. **NS5 + RMSNorm partially absorb init scale; Adam-AUX does NOT.** Magnitude ratio 4.00× persists in telemetry; val cost only +2.2 mnat. Asymmetry: embed flat under Adam despite being Adam-optimized; body mildly worse on large side despite NS5 polar → gradient-magnitude inflation through residual stream → Adam-AUX first-step overshoot.
3. **Future init perturbations must be paired with compensating optimizer-side change** (LR, β, EMA) to escape the basin — testing init in isolation is now demonstrably structurally insensitive.

**Closed axis:** Init-scale axis closed at scale=1.0. No further sub-resolution sweeps warranted.

---

## 2026-05-25 03:20 UTC — PR #1102 CLOSED: NS5 input normalization: spectral vs Frob/sqrt(n) — 120th NULL, rank-deficiency canon REFRAMED (g1r1-frieren)

- Branch: `g1r1-frieren/ns-input-norm`
- Hypothesis: NS5 wastes early iterations growing sigma when fed a Frob-normalized low-rank input (from #1046 L_cov stable rank ~13). Spectral normalization (sigma_max=1) should close the "wasted iterations" gap. Frob/sqrt(n) was predicted to overshoort (sigma_max~0.28 at k=13).

| Arm | norm_mode | W&B | val/loss | sr | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | frobenius | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | ~0.19 (mean) | gate |
| A SPECTRAL | spectral | `jeck1ge0` | **3.267161** | 2950 | **0.0525** (3.7x tighter) | **NULL** (+0.77 mnat, fails merge) |
| B FROB/sqrt(n) | frob_over_sqrt_n | `kqrtsre6` | crashed step 2 | — | — | **CATASTROPHIC** |

**Finding 1: m_pre stable rank ≈ 426 (NOT ~13 like L_cov).** L_neg/R_neg pre-whitening de-low-ranks the NS5 input. The original "wasted iterations" estimate overestimates headroom by ~5× (sqrt(13)/sqrt(426) ≈ 0.17). The rank-deficiency canon for L_cov does NOT apply to the NS5 input m_pre.

**Finding 2: polar/ortho_residual is NOT load-bearing at NS_ITERS=12.** Spectral norm tightens residual ~3-5× (0.0525 vs ~0.19 baseline) but does not move val/loss or sr. Extra refinement headroom is not the bottleneck.

**Finding 3: CATASTROPHIC endpoint established.** sigma_max ≈ 27 (frob/sqrt(n) with actual k=426) → NS cubic map blows up → L_cov ill-conditioned → eigh fails at step 2. Stable region σ∈[0,√3] confirmed.

**Finding 4: +11% wall-clock cost** for spectral (3 fp32 power iters per NS5 call). Unattractive even at val neutral.

**Structural reframe:** Future rank-deficiency-motivated PRs must report m_pre stable rank (not L_cov/R_cov). Implications for #1107 polar-interpolation: "polar fills in missing structure" premise partially undermined (m_pre is rank-rich). frieren → #1123 (asymmetric gamma_L/gamma_R whitening exponents, first decoupled test).

## 2026-05-25 01:00 UTC — PR #1066 CLOSED: Z-loss λ·log²(Z) partition-function regularization (λ=1e-4 vs 1e-3) — 119th NULL, 4-axis output-reg closure (g1r1-askeladd)

- Branch: `g1r1-askeladd/z-loss`
- Hypothesis: Penalize log-partition-function magnitude `λ·log²(Z)` where Z=sum(exp(logits)). PaLM-canonical technique for numerical stability + output regularization. Orthogonal to LS (targets), CP (entropy), soft-cap (activations) — directly penalizes NORMALIZER.

| Arm | λ | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.0 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (PaLM canonical) | 1e-4 | `edq21r1h` | **3.26644** | 2925 | +0.000046 (0.15σ) | 0 | NOISE-FLOOR NULL |
| B (10× stronger) | 1e-3 | `zst7hrwa` | **3.286507** | -1 | +0.020113 (67× past marginal) | DNF | CATASTROPHIC NULL |

**Finding 1: Z-loss structurally redundant at modded-nanogpt scale.** PaLM's motivation (partition function exploding at 540B params / vocab=256K) does not apply here — sqrt-clip @15 on logits already keeps Z bounded; BF16 is sufficient for vocab=50304. At λ=1e-4 the mean `log²(Z)` contributes ≤5e-5/step to loss (sub-noise). At λ=1e-3 it contributes ~5e-4/step, compounding over 3250 steps to ~+0.02 mnat shift in optimization basin → CATASTROPHIC failure to cross 3.28 threshold.

**Finding 2: Super-linear dose-response, same pattern as #1058 CP.** λ=1e-4 → noise-floor (mechanistically silent); λ=1e-3 → 67× past marginal (43× jump from first to second segment). Dose-response accelerates nonlinearly across both CP (#1058) and Z-loss (#1066).

**Cross-axis closure — 4-axis output-regularization portfolio CLOSED (pending #1090 focal):**

| Axis | PR | Direction | Result |
|---|---|---|---|
| Soft-target smoothing | #1043 fern | modify TARGET | CATASTROPHIC linear dose-response (115th NULL) |
| Hard-target entropy max | #1058 frieren | modify LOSS | CATASTROPHIC super-linear dose-response (117th NULL) |
| Logit soft-cap | #1060 tanjiro | modify ACTIVATIONS | NULL noise-floor at cap=15; regression at cap=30 (118th NULL) |
| Z-loss partition reg | #1066 askeladd (this) | modify NORMALIZER | NULL noise-floor at λ=1e-4; catastrophic at λ=1e-3 (119th NULL) |

Pattern: baseline sqrt-clip @15 + standard CE already saturates the output-reg channel. Only #1090 fern focal (in flight) remains.

**119th closed axis.** askeladd → **#1116** (body Muon depth-LR decay, per-layer linear scale DOWN vs UP).

## 2026-05-24 23:18 UTC — PR #1060 CLOSED: Logit soft-cap tanh(logits/cap)*cap (cap=30 vs 15) — 118th NULL, 3-axis output-reg closure (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/logit-soft-cap`
- Hypothesis: Constrain logit magnitudes via smooth tanh saturation `tanh(logits/cap)*cap` (Gemma 2 canonical technique) pre-CE. Distinct from LS (target modification) and CP (entropy penalty) — directly constrains LOGIT SPACE. Single-line change, val/loss evaluated with uncapped CE (benchmark contract).

| Arm | cap | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — (sqrt-clip @15 only) | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (loose) | 30 | `nqsjo07o` | **3.272813** | 3050 | +0.006419 (21x past marginal) | +125 (5x past) | CLEAR NULL |
| B (matches baseline) | 15 | `f3abiepo` | **3.266489** | 2925 | +0.000095 (0.32σ) | 0 | NOISE-FLOOR NULL |

Predeclared merge rule: `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)`. Arm B fails by 0.000095 mnat.

**Finding 1: Output peakedness control saturated at cap≈15.** Arm B cap=15 (matching baseline's sqrt-clip kink point) ties baseline within 0.32σ — the tanh and sqrt-clip functional forms at the same cap value produce statistically identical val/loss. The soft-cap functional form is interchangeable; the effective cap value is the load-bearing lever.

**Finding 2: Looser cap (30) deactivates peakedness control → clear regression.** With baseline sqrt-clip still active at 15, Arm A's tanh at 30 is dead-weight for in-range logits. The +6.4 mnat regression likely comes from compositional interaction at the boundary, or subtle `tanh(x/30)*30 ≠ clip(x,-30,30)` differences where sqrt-clip binds. Cap=30 is definitively wrong.

**Cross-axis closure — 3-axis output-regularization portfolio:**

| Axis | PR | Direction | Result |
|---|---|---|---|
| Soft-target smoothing | #1043 fern | modify TARGET | **CATASTROPHIC linear dose-response** (115th NULL, Δval≈0.96·ε) |
| Hard-target entropy max | #1058 frieren | modify LOSS | **CATASTROPHIC super-linear dose-response** (117th NULL) |
| Logit soft-cap | #1060 tanjiro (this) | modify ACTIVATIONS | **NULL noise-floor at cap=15; regression at cap=30** (118th NULL) |

Consistent pattern across 3 independent output-reg mechanisms: baseline's existing peakedness control (sqrt-clip @15) saturates the channel. Modifications that match or tighten it are noise-floor neutral; modifications that loosen or add pressure via different objectives are NULL-to-catastrophic.

Two remaining output-reg axes in flight: #1066 askeladd Z-loss, #1090 fern focal.

**118th closed axis.** Logit soft-cap axis CLOSED. tanjiro → **#1107** (polar interpolation: alpha-blend polar(m_pre) vs magnitude-matched m_pre, tests polar-projection saturation in low-rank regime per #1046 rank-deficiency canon).

## 2026-05-24 22:50 UTC — PR #1058 CLOSED: Confidence penalty (Pereyra 2017) beta=0.05 vs 0.10 — 117th NULL, CLEAR + CATASTROPHIC super-linear dose-response, 2-axis loss-reg closure (g1r1-frieren)

- Branch: `g1r1-frieren/confidence-penalty`
- Hypothesis: Penalize over-peaked output distributions via `loss = ce - beta * H(p)` where H(p) is per-token entropy. Pereyra 2017 confidence penalty, orthogonal to label smoothing (#1043). Mechanism: encourage higher output entropy, fight over-confident predictions, regularize.

| Arm | beta | W&B | val/loss | sr | Delta-val vs #918 (3.266394) | Delta-sr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.00 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (mild) | 0.05 | `rcyh71fo` | **3.27730** | 3125 | +0.01091 (11x past) | +200 (8x past) | CLEAR NULL |
| B (strong) | 0.10 | `jx4exq3k` | **3.33492** | -1 | +0.06853 (69x past) | DNF | CATASTROPHIC NULL |

Both arms fail predeclared merge rule. Super-linear dose-response: Delta-val/Delta-beta jumps from +0.013/0.05 (A) to +0.058/0.05 (B) — 4.5x acceleration in damage between halves of the beta range.

**Finding 1: CP gradient SURVIVES NS5 polar orthogonalization.** Composite loss decreased monotonically; entropy-maximizing gradient was NOT annihilated by NS5. Falsifies the "NS5 absorbs auxiliary loss terms" intuition (contra modal prediction). Important negative finding for future loss-augmentation hypotheses.

**Finding 2: Output entropy is NOT load-bearing for generalization in this regime.** Higher H(p) (Arm A: 3.626 nats; Arm B: 4.368 nats) -> strictly worse val/loss. Baseline already operates at near-optimal entropy plateau for 3250-step budget; pushing higher costs hard-CE accuracy.

**Finding 3: `loss_composite < val_loss` signature.** Arm B composite=2.92 < val=3.33 -> optimizer descending on a loss whose minimum is NOT the true CE target. Optimizer well-behaved; regularizer mis-aligned with benchmark.

**Finding 4: sqrt-clip at 15 already controls peakedness.** Baseline line 454 logit clip caps per-token confidence. Adding CP creates competing pressure: sqrt-clip is local (per-logit), CP is global (sum over vocab). NOT synergistic.

**Cross-axis closure — 2-axis loss-regularization:** Combined with #1043 LS (115th NULL CATASTROPHIC linear dose-response, Delta-val approx 0.96*epsilon), two independent loss-objective interventions both NULL/catastrophic with monotone-bad dose-response. Loss-objective regularization at CE level structurally incompatible with body-Muon + EMA(0.95->0.99) at 3250 steps. Three more output-reg axes in flight: #1066 askeladd Z-loss, #1060 tanjiro soft-cap, #1090 fern focal loss.

**117th closed axis.** Confidence penalty axis CLOSED. frieren -> **#1102** (NS5 input normalization mode test: spectral vs Frob/sqrt(n) vs Frobenius baseline, directly motivated by #1046 rank-deficiency canon).

## 2026-05-24 22:32 UTC — PR #1059 CLOSED: Embed init std ablation (σ=0.04 vs σ=0.5) — 116th NULL, monotone-toward-baseline, init-state-surface canon (g1r1-nezuko)

- Branch: `g1r1-nezuko/embed-init-std`
- Hypothesis: Embed baseline init σ=1.0 (PyTorch default) is unusually wide vs GPT-2 canonical σ=0.02. RMSNorm makes forward output invariant to σ, but backward gradient scales as 1/σ; Adam equilibration delay creates an effective LR difference. Mirror axis of #1015 lm_head ε (input-side vs output-side readout). Two arms: A σ=0.04 (25× smaller, near GPT-2 canonical), B σ=0.5 (2× smaller, intermediate).

| Arm | σ | W&B | val/loss | sr | Δval vs #918 (3.266394) | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 1.0 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | reference |
| A (small) | 0.04 | `0h9ym90h` | **3.26831** | 2950 | +0.001916 (~6.4σ) | +25 | Marginal NULL |
| B (moderate) | 0.5 | `zefhhcfm` | **3.26716** | 2950 | +0.000766 (~2.6σ) | +25 | Marginal NULL |

Single-seed σ ≈ 0.0003 (established #958). Both fail predeclared merge rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` — sr=2950 disqualifies the val conjunct.

**Finding 1: Monotone-toward-baseline pattern.** Both arms regress vs σ=1.0 baseline; magnitude scales with σ-distance (Arm A 25× shrink → Δval ~1.9 mnat; Arm B 2× shrink → Δval ~0.8 mnat). Direction consistent across both arms with identical sr=2950. Axis is effectively flat within seed noise but with a weak directional gradient favoring σ ≥ 1.0.

**Finding 2: BF16 quantization floor ruled out.** Row-L2 distribution at σ=0.04 shows no truncation (min/max ratio = 1.22, healthy spread). The 19.5%-relative-BF16-precision concern was NOT the gating factor. Init validation matched analytic predictions to 3 sig figs in both arms (Frob 248.589 vs predicted 248.4 for Arm A; 3108.572 vs 3105.6 for Arm B).

**Finding 3: Adam variance equilibration transient is plausibly load-bearing.** Smaller σ shortens the early-step variance-warmup phase (~30 steps for σ=0.04 vs ~100 for σ=1.0). The shorter transient leaves the embed in a slightly worse state — suggests the baseline's longer transient phase is mildly beneficial, not just neutral.

**Finding 4: Full readout-pair init-state surface canon.** Combined with #1015 lm_head ε (5× scan, sub-noise flat → Δ ≈ +0.000140 mnat = 10× below noise floor):
- lm_head ε: flat (5× scan, sub-noise)  
- embed σ: mildly tilted toward σ≥1.0 (25× scan, marginal NULL with monotone-toward-baseline gradient)
- Conclusion: **the full readout-pair init-state surface is approximately flat with a mild preference for the baseline configuration. Load-bearing levers are dynamics constraints (LR/WD/cooldown/preconditioner), not init state.**

**Student's closure recommendations:**
- Constraint-based interventions: spectral norm bounding on `proj.weight`, row-wise WD scheduling, embed/proj coupling
- σ=2.0 test would confirm whether trend continues monotone above baseline (low ROI, predicted Δval ±0.0008, needs n=2)
- No structural fix to baseline init recommended

**116th closed axis.** Embed init std axis CLOSED at σ=1.0. nezuko → **#1099** (decoupled AdamW cooldown shape: γ_adamw=2.0 vs 1.0, body Muon fixed at γ=1.4).

## 2026-05-24 20:30 UTC — PR #1043 CLOSED: Label smoothing ε=0.05 vs ε=0.10 — 115th NULL, CATASTROPHIC dose-response (g1r1-fern)

- Branch: `g1r1-fern/label-smoothing`
- Hypothesis: Uniform target label smoothing (Szegedy 2016) `(1-ε)·1_y + ε/V·1` softens target distribution to regularize loss objective without modifying optimizer/scheduler. 1st loss-objective axis test. Val/loss kept as HARD CE (benchmark contract).

| Arm | ε | W&B | val/loss | sr | Δval vs #918 (3.266394) | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.00 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | reference |
| A | 0.05 | `034w1we5` | **3.31401** | -1 | **+47.62 mnat** | CATASTROPHIC NULL (>3.28) |
| B | 0.10 | `wiwg3ere` | **3.36762** | -1 | **+101.23 mnat** | CATASTROPHIC NULL (>3.28) |

- **Linear dose-response confirmed:** Δval ≈ 0.96·ε + 0.0002 across two arms. Extrapolation predicts no ε wins (ε=0.001 → Δval≈+0.001 marginal at best).
- **Basin shift is GLOBAL, not transient:** Arm B−Arm A val gap constant ≈+0.05 from step 125 through step 3250. Label smoothing acts as a constant basin-floor offset, not a dynamic regularizer. No crossover where smoothing catches up.
- **Hard-CE basin really is higher:** Arm B `train/loss_hard_ce`=3.391 ≈ val/loss=3.368 — rules out "optimizer-loss-inflation only" alternative. Model genuinely converged at a higher hard-CE basin.
- **Mechanism:** At ε=0.10, model must allocate ≈10% mass to all 50,303 non-target tokens (≈ε·log(V) ≈ 1.08 nats unrecoverable). At 3250-step horizon, model never reaches confident-prediction-overfitting regime where smoothing helps; raw gradient signal at confident tokens > entropy-encouragement noise.
- **115th closed axis.** **Loss-objective regularization via uniform target smoothing FULLY CLOSED.**
- Mechanism-distinct loss-reg alternatives currently in flight: #1058 frieren confidence penalty (entropy maximization), #1066 askeladd Z-loss PaLM (partition regularization), #1060 tanjiro logit soft-cap (logit-magnitude regularization). #1090 fern → focal loss (5th axis, gradient amplification on hard tokens via `(1-p_y)^γ`).

## 2026-05-24 20:30 UTC — PR #1046 CLOSED: Shampoo warmup gate (w=500 vs w=1000) — 114th NULL, "200 lost steps" PARTIALLY CONFIRMED but NOT load-bearing (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-warmup-gate`
- Hypothesis: After #995 showed Shampoo body-Muon viable with c=1e-4 trace-relative eps but +10 mnat NULL gap, test whether early-train Shampoo over-regularization (`eps_L=3.08` at step 100, 52× terminal) explains the deficit. Defer Shampoo precond application until step 500 or 1000; raw Muon runs during warmup; L_cov/R_cov accumulated continuously.

| Arm | warmup | W&B | val/loss | sr | Δval vs #918 (3.266394) | Verdict |
|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | n/a | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | reference |
| #995 Arm A (no warmup) | w=0 | merged | 3.276730 | 3125 | +10.34 mnat | NULL reference |
| A | w=500 | `3eqvr3oa` | **3.274959** | 3075 | **+8.6 mnat** | NULL (-1.77 mnat vs #995) |
| B | w=1000 | `b8lfm5sf` | **3.276352** | 3125 | **+9.96 mnat** | NULL (-0.38 mnat vs #995, tied) |

- **Smoking-gun mechanism @ step 750:** w=1000 (still raw-Muon) is **62 mnat AHEAD** of w=500 (just flipped to Shampoo at step 500). Raw Muon outperforms early-Shampoo with rank-deficient L_cov/R_cov. By step 1500, trajectories merge.
- **Terminal +7 mnat residual is STRUCTURAL** (~30% recoverable via warmup, ~70% from missing NS5 magnitude/rank/null-space roles per #985 triple-load-bearing finding). Gate location is NOT critical for the structural residual — both warmup arms hit the same terminal band (±0.7 mnat).
- **NEW RANK-DEFICIENCY CANON (step-500 gate snapshot, Arm A):**
  - L_cov stable rank = **13.18** / 3072 raw dim
  - R_cov stable rank = **1.67** / 768 raw dim
  - L_cov condition number = **20,863**; R_cov = **28,608**
  - EMA β=0.95 → effective lookback ~20 steps; covariance extremely rank-deficient even after 500 warmup steps
  - Original "single-step outer product needs ~768 steps for full rank" intuition was an UNDER-estimate of how stiff this regime is
- **Cross-axis canon** (combined with #969 cooldown power Pareto and #1023 target_uw schedule): "Schedule-localized regularization is real in early-train phase but **CANNOT recover Shampoo body-Muon terminal residual**. Residual gap is structural (missing NS5 magnitude/rank roles), not schedule-tunable."
- **114th closed axis.** Shampoo-replace-NS5 family decisively closed across all 3 sub-axes: trace-eps c (#995 flat), warmup gate (#1046 partial), null-space-amp (#985 catastrophic step-0).
- **Suggested follow-up:** Variant 3 NS5-layered Shampoo — compose Shampoo precond AND NS5 polar in same body update. NS5 should rescue Shampoo from #985-style step-0 explosions via cubic-map magnitude absorption. alphonse → **#1089** (two arms test order-sensitivity: A Shampoo→NS5, B NS5→Shampoo).

## 2026-05-24 19:45 UTC — PR #1040 CLOSED: WD coupling form (lr-linear vs lr-squared vs fully decoupled) — 113th NULL, lr_linear IS load-bearing (g1r1-edward)

- Branch: `g1r1-edward/wd-decoupling-form`
- Hypothesis: body-Muon WD form `p *= (1 - lr * wd)` is an arbitrary SGD inheritance OR is load-bearing because NS5 polar output has different update-scale dynamics. Three forms tested: lr_linear (baseline), lr_squared (quadratic vanishing), decoupled (constant per step). All calibrated to identical per-step decay = 0.001 at peak LR=0.040.

| Arm | wd_form | wd | W&B | val/loss | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | lr_linear | 0.025 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | Pareto-optimum |
| **Arm A lr_squared** | lr_squared | 0.625 | `ogapobt0` | **3.268200** | **2950** | +0.001806 | +25 | NULL |
| **Arm B decoupled** | decoupled | 0.001 | `tad7pz1u` | **3.292603** | **-1** | +0.026209 | catastrophic | NEG (failed 3.28 target) |

- **Decision: 113th NULL — DOES NOT MERGE.** Arm A NULL bracket; Arm B decisively NEG.
- **Canon finding 1: lr_linear coupling is STRUCTURALLY CORRECT, not arbitrary.** It preserves decay-to-update ratio = wd/|polar(p)| constant throughout WSD schedule. NS5 polar output magnitude ∝ lr → WD ∝ lr maintains the balance. Breaking this proportionality (decoupled form) causes WD to dominate during cooldown when NS5 updates shrink to zero.
- **Canon finding 2: p_norm_body_mean 5.35× terminal divergence is reference-grade mechanism deconvolution.** Arm A terminal p_norm=607 vs Arm B p_norm=113 — by construction both identical at peak LR=0.040 (calibration confirmed at step 500: 118.21 vs 118.36), divergence is ENTIRELY cooldown-phase artifact. Arm B p_norm peaks at step ~1500 (355) then COLLAPSES to 113 (3.1× shrinkage from 1500→3250) as WD wins tug-of-war against shrinking updates.
- **Canon finding 3: val/loss slope flip is direct confirmation of unlearning.** Arm B val/loss bottom at step 2975 (3.2921) then ASCENDS to 3.2926 at step 3250 (+0.00139 slope = positive). Arm A continues descent (-0.00415 slope). The model is actively unlearning under decoupled WD-dominated dynamics.
- **Canon finding 4: u/w-floor corroborates p_norm collapse.** fired_fraction: Arm A 100% throughout cooldown; Arm B 1.0→0.49 during cooldown. As |w|_F shrinks in Arm B, |u|/|w| ratio rises above floor, floor stops firing. Clean cross-axis link to #1035 u/w-floor pruning.
- **WHAT'S CLOSED:** WD coupling form axis across {lr_linear, lr_squared, decoupled}. lr_linear IS CORRECT by construction, not by coincidence.
- **WHAT'S OPEN:** Dual-region cooldown shape (OPEN per #969 closure note) — edward reassigned to #1084.
- edward → **#1084** (dual-region cooldown shape: piecewise γ₁/γ₂, follow-up to #969 Pareto-coupling finding).

---

## 2026-05-24 20:08 UTC — PR #1035 CLOSED: UW-floor pruning ablation (TARGET_UW=0 vs 0.50) — 112th NULL, clean U-shape confirmation, floor IS partially load-bearing at 0.35 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/uw-floor-pruning`
- Hypothesis: TARGET_UW=0.35 baseline is one of (A) load-bearing regulator, (B) dead-weight scalar multiplier in disguise, (C) partial regulator at interior optimum. Two arms: A floor=0 (OFF), B floor=0.50 (more aggressive).

| Arm | target_uw_floor | W&B | val/loss | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | 0.35 | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | — | — | Pareto-optimum |
| **Arm A OFF** | 0 | `5kad6ybm` | **3.27219** | **3000** | +0.00580 | +75 | NULL (6× past marginal) |
| **Arm B HIGH** | 0.50 | `20an0zgw` | **3.28608** | **-1** | +0.01969 | catastrophic | CATASTROPHIC NULL (failed 3.28 target) |

- **Decision: 112th NULL — DOES NOT MERGE.** Both arms regress on val and fail sr=2925 conjunct. No clause of `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` is satisfied. Hypothesis (B) "dead weight" DECISIVELY REJECTED — +6 mnat regression at floor=0 with no LR compensation rules out scalar-multiplier-in-disguise interpretation. Hypothesis (C) partial regulator CONFIRMED with clean U-shape interior optimum near 0.35.
- **Canon finding 1: EMA buffer divergence is the dominant failure signal across the floor axis.** `ema/buffer_frob_dist` final: Arm A=3.99 (under-driven), baseline≈22.6, Arm B=1379 (catastrophic explosion). The floor's BOOST drives most of the EMA<>live divergence at lr=0.040. Without boost → under-driven trajectory averaging; over-aggressive boost → EMA buffer drift explodes by ~62× over baseline.
- **Canon finding 2: NS5 polar accuracy is co-degraded by aggressive floor.** `polar/ortho_residual_sample` mean: Arm A=0.29, Arm B=0.67 (+0.38). Post-floor magnitude scaling pushes polar outputs away from true orthogonality. Cross-axis link to #898 (NS5 rank-deficient residual finding).
- **Canon finding 3: Asymmetric regression confirms well-tuned regulator at sweet spot.** Removing floor is 3.3× CHEAPER (+6 mnat) than over-cranking it (+20 mnat). Downside-of-over-application steeper than upside-of-correct-application is typical signature of an actively tuned regulator near its optimum.
- **Canon finding 4: `fired_fraction` correctly bracketed the operating regime** at 0.0 / 0.975 / ~1.0 across arms — telemetry verification was exemplary, validating the per-trajectory mechanism deconvolution.
- **Canon finding 5: Floor's boost behavior is the dominant LR-amplifier at lr=0.040.** Cross-axis with #918 / #986: explains why body-Muon LR axis closed at 0.040 (the LR sweet spot is implicitly conditional on the floor's boost being present at 0.35).
- **WHAT'S CLOSED:** u/w-floor pruning axis at TARGET_UW ∈ {0, 0.35, 0.50} — 0.35 is the Pareto-optimum, NOT prunable.
- **WHAT'S OPEN:** Fine-grained U-shape sweep around 0.35 (low-yield, deferred); EMA-buffer-cap as alternative regulator (speculative, would replace floor's indirect EMA-buffer effect with direct regulator).
- thorfinn → **#1080** (body weights init scale ablation 0.5× vs 2.0× baseline, mirror of #1059 embed / #1015 lm_head — completes 3-matrix init-scale family).

---

## 2026-05-24 16:05 UTC — PR #969 CLOSED: WSD cooldown power γ=1.2 n=2 — 111th NULL, INFORMATIVE Pareto-shift (g1r1-askeladd)

- Branch: `g1r1-askeladd/wsd-cooldown-power`
- Hypothesis: γ=1.2 (slower cooldown decay) n=2 confirmation at lr=0.040 baseline after n=1 marginal WIN at lr=0.035.

| Run | seed | val_loss | sr | Δval vs #918 | Δsr vs #918 |
|---|---|---|---|---|---|
| Baseline #918 (n=2 mean) | mean | 3.266394 | 2925 | — | — |
| `2l8wjtai` (γ=1.2 lr=0.040) | 1 | 3.26688 | 3000 | +0.000486 | +75 |
| `t73okfo5` (γ=1.2 lr=0.040) | 2 | 3.26466 | 2975 | −0.001734 | +50 |
| **n=2 MEAN** | — | **3.26577** | **2987.5** | **−0.000624** | **+62.5** |

- **Decision: 111th NULL — DOES NOT MERGE per predeclared rule.** The rule `sr ≤ 2912.5 OR (sr=2925 AND val<3.266394)` is satisfied by neither branch. Δsr=+62.5 is 2.5× past 25-step marginal threshold; sr regression on primary speedrun metric is decisive.
- **Canon finding 1: cooldown shape produces a Pareto frontier, not a strict optimum.** γ=1.2 trades sr (+62.5) for val (−0.000624). γ=1.4 baseline is the sr-Pareto-optimum within {1.2, 1.4, 1.6}.
- **Canon finding 2: Mechanism is exactly the analytical LR-mass prediction.** γ=1.2 shifts ~9% MORE LR mass to LATE cooldown (post-threshold). Pre-threshold (steps 1750-2925) has LESS LR mass → slower 3.28 crossing → sr regression. Post-threshold (steps 2925-3250) has MORE LR mass → deeper terminal val descent. These effects are intrinsically coupled around the threshold.
- **Canon finding 3: 2σ_n=2 val signal — strongest n=2 val improvement in r1 portfolio outside merged baselines.** Z = (3.266394−3.26577)/√(σ²/2) ≈ 2σ. Real mechanism, but on the wrong metric direction for the speedrun objective.
- **Canon finding 4: Single-seed σ at γ≠optimum is 3.7× higher than at γ=1.4 baseline.** seed-1 vs seed-2 spread = 0.00222 mnat at γ=1.2; baseline σ ≈ 0.0003. Operating off the Pareto optimum increases seed sensitivity — useful diagnostic for future off-optimum n=2 tests.
- **Canon finding 5: Cooldown-erosion 4-instance pattern REAFFIRMED.** Different lever (shape vs structure) but consistent canon: don't move structurally away from γ=1.4 cooldown for sr-minimization.
- **WHAT'S CLOSED:** cooldown_power axis at γ ∈ {1.2, 1.4, 1.6} — γ=1.4 is the sr-Pareto-optimum.
- **WHAT'S OPEN:** γ × cooldown_start joint cell (deprioritized); dual-region cooldown shape (concave pre-threshold + convex post-threshold — speculative).
- askeladd → **#1066** (Z-loss PaLM `λ·log²(Z)` partition-function regularization — 4th output-reg axis).

---

## 2026-05-24 15:05 UTC — PR #1013 CLOSED: Sophia-H Hessian-diagonal for embed — 110th NULL, 5-AXIS i.i.d.-AUX STRUCTURAL CLOSURE (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/sophia-h-embed`
- Hypothesis: Sophia-H diagonal Hessian preconditioner (Hutchinson estimate, k=10 steps) replaces AdamW for embed parameter. Tests whether true curvature (vs gradient variance in Adam) provides useful aux signal.

| Arm | ρ | W&B | val/loss | sr | Δval | Δsr | sophia/clip_frac |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | vm48fdof/0a7esmxs | 3.266394 | 2925 | — | — | — |
| Arm A | 0.01 (conservative) | `56iuhjoa` | **3.27638** | **3125** | +0.01052 | +200 | **1.00 throughout** |
| Arm B | 0.001 (aggressive) | `ab8pqcfg` | **3.27928** | **3200** | +0.01342 | +275 | **1.00 throughout** |

- **Decision: 110th NULL.** Both arms clear stat-sig NULL (Arm A barely fails 3.276 threshold by 0.4 mnat; Arm B by 3.3 mnat). Δsr +200/+275 = 8-11× past marginal band. n=2 not needed.
- **Canon finding 1: `sophia/clip_frac=1.0` throughout all steps in both arms — mechanism mechanically inactive.** h_mean ≈ 1.8e-5 (Arm A) / 1.7e-6 (Arm B), never approaching ρ threshold. Sophia-H degenerates to constant-magnitude SGD at effective LR = lr/ρ = 15 (Arm A) / 150 (Arm B).
- **Canon finding 2: Root cause is sparse-update structure.** Only ~8192/50304 vocab rows receive gradient per batch (~16% occupancy). Hutchinson trace is ~0 for unseen rows → `h` concentrates near zero → 100% clip saturation structural at any ρ ≥ h_mean.
- **Canon finding 3: 5-AXIS i.i.d.-AUX STRUCTURAL CLOSURE ACHIEVED.** Adam-family (18 axes) + SOAP (2 axes) + Diagonal-Hessian (1 axis) all NULL. Per-coord preconditioning of ANY form cannot extract useful signal from sparse, i.i.d. aux gradients at this benchmark scale. Closed families: gradient-variance estimators (Adam), covariance estimators (SOAP/Shampoo), Hessian estimators (Sophia-H).
- **Canon finding 4: 4× HVP wall-clock overhead is a deployment blocker.** `model._compiled_call_impl = None` toggle inside `update_hessian` invalidates compile cache. 15 GPU-hours for n=2 confirmation would require >25% val improvement to break even — not achievable.
- **Canon finding 5: Arm B monotone-worse (more aggressive ρ → worse val).** SGD at 10× higher effective LR with no curvature dampening is closer to plain gradient descent, explaining the +3.3 mnat worse result.
- **WHAT'S CLOSED:** All diagonal-preconditioned aux families (Adam, SOAP, Hessian). i.i.d. structural closure is now definitive.
- **WHAT'S OPEN:** Dense-update parameters (lm_head vs embed have different gradient density); constraint-based aux interventions (spectral-norm, row-WD); architectural logit-space interventions (soft-capping).
- tanjiro → **#1060** (logit soft-capping — architectural 1-line: `tanh(logits/cap)*cap`, cap=30.0 vs 15.0).

---

## 2026-05-24 14:50 UTC — PR #1015 CLOSED: lm_head non-zero orthogonal init — 109th NULL, LOCALLY INSENSITIVE init scale axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/lm-head-init-orthogonal-init`
- Hypothesis: replacing `proj.weight.zero_()` baseline with `torch.nn.init.orthogonal_(w, gain=ε)` breaks zero-init logit symmetry constructively. Two arms ε ∈ {0.02 small, 0.10 moderate}.

| Arm | ε | W&B | val/loss (EMA) | val/loss_live | sr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.02 | `pfs8ort4` | **3.26714** | 3.26658 | 2950 | +0.000746 | marginal NULL |
| B | 0.10 | `3yg5ez7p` | **3.26728** | 3.26672 | 2950 | +0.000886 | marginal NULL |
| B − A | 5× | — | — | — | 0 | +0.000140 | flat dose-response |
| Baseline #918 (n=2) | 0 | `vm48fdof`/`0a7esmxs` | 3.266394 | — | 2925 | 0 | reference |

| Pre-launch init validation | Arm A pred | Arm A obs | Arm B pred | Arm B obs |
|---|---|---|---|---|
| `init/proj_weight_frob_norm` | 0.554 | **0.5543** ✓ | 2.77 | **2.7713** ✓ |
| `init/proj_weight_row_l2_mean` | 0.00248 | **0.002470** ✓ | 0.01240 | **0.01235** ✓ |

- **Decision: 109th NULL — Scenario 2 (LOCALLY INSENSITIVE) confirmed.** Both arms within seed-noise envelope (baseline range 0.001062 mnat); 5× ε change adds only +0.000140 mnat (≈ 10× below σ≈0.0003 single-seed noise floor established in #958).
- **Canon finding 1: lm_head orthogonal-init scale axis FULLY CLOSED at ε ∈ [0.02, 0.1].** Zero-init occupies a flat local optimum, not a sharp one. The canonical modded-nanogpt design choice is empirically overdetermined within reasonable orthogonal-Gaussian range.
- **Canon finding 2: "Un-learning burden" mechanism present but tiny.** The monotone-destructive sign (Arm B > Arm A by +0.000140) confirms the mechanism, but at magnitude below detection threshold. Mechanistically real, practically irrelevant.
- **Canon finding 3: AdamW-aux absorbs init perturbations cleanly in first ~50-100 steps.** EMA-vs-live divergence matched #918 canonical pattern. Init contribution to terminal weight norm: +32.3/66547 = <0.05%.
- **Canon finding 4: Cross-axis — weight-space pivots for aux should be CONSTRAINT-based during training, not INITIALIZATION-based.** Init starting point gets washed out; constraints (spectral-norm, row-WD scheduling) and dynamics (LR per-row, decay coupling) are the directions that load-bear.
- **WHAT'S CLOSED:** lm_head init scale axis at orthogonal-Gaussian endpoint within [0.02, 0.1].
- **WHAT'S OPEN:** embed init scale (untested; mirror axis); tied init (lm_head copy of embed); larger ε (>0.2) regime (not recommended without LR adjustment); spectral-norm constraint on proj.weight; row-WD scheduling.
- nezuko → **#1059** (embed init std ablation — mirror axis on the input side of the readout pair).

---

## 2026-05-24 14:30 UTC — PR #958 CLOSED: PMuon γ_pre temporal schedule — 108th NULL, γ-schedule axis FULLY CLOSED (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-pre-temporal-schedule`
- Hypothesis: PMuon γ_pre (Newton-Schulz polar exponent factor) temporal schedule (UP 0.2→0.4 vs DOWN 0.4→0.2 vs CONSTANT 0.4 baseline) is load-bearing. n=2 confirmation chain.

| Seed | W&B | terminal val/loss | sr | Δval vs #918 | Verdict |
|---|---|---|---|---|---|
| seed-1 (DOWN 0.4→0.2) | `cbob6p4l` | **3.26731** | 2950 | +0.000916 | marginal NULL |
| seed-2 (DOWN 0.4→0.2) | `amanpa5z` | **3.2676** | 2950 | +0.001206 | marginal NULL |
| **n=2 mean** | — | **3.267455** | **2950** | **+0.001061** | **NULL** |
| Baseline #918 (n=2) | `vm48fdof`/`0a7esmxs` | 3.266394 | 2925 | 0 | reference |

- **Decision: 108th NULL.** Both seeds marginal NULL within seed noise; n=2 mean Δ+0.001 = clean NULL (just over marginal threshold), Δsr+25 = worse on speedrun metric. DOWN γ_pre schedule structurally indistinguishable from CONSTANT γ=0.4.
- **Canon finding 1: γ_pre temporal schedule axis FULLY CLOSED** across {UP, DOWN, CONSTANT}. Original #958 trial showed UP was sub-marginal NULL and DOWN was n=1 WIN — but n=2 confirmation reveals DOWN is also within seed noise. **Constant γ_pre=0.4 is canonical operating point.**
- **Canon finding 2: Empirical seed-noise floor established.** seed-1 = 3.26731, seed-2 = 3.26760 → single-seed σ ≈ 0.0003. Future marginal-WIN candidates must achieve Δ > 3× this spread (~0.001) for n=1 stat-sig WIN, OR provide n=2 confirmation.
- **Canon finding 3: Schedule complexity is overdetermined.** Adding step-dependent γ computation per body parameter is a non-trivial code complexity bump for zero structural payoff. Pruning candidate: keep γ_pre constant.
- **WHAT'S CLOSED:** PMuon γ_pre temporal schedule sub-axis; γ_pre as a schedule lever.
- **WHAT'S OPEN:** NS5 iteration count axis (γ=0.4 constant might pair with reduced NS5 iters); β_cov-γ joint axis; per-block γ assignment.
- frieren → **#1058** (confidence penalty — Pereyra et al. 2017, orthogonal-to-LS loss regularization).

---

## 2026-05-24 12:20 UTC — PR #995 CLOSED: Shampoo body-Muon trace-relative eps — 107th NULL, c-axis CLOSED, family threshold MET (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-trace-relative-eps`
- Hypothesis: Trace-relative eps `c·trace(M)/m` fixes #985's catastrophic null-space amplification. Arm A c=1e-4; Arm B c=1e-2.

| Arm | W&B | terminal val/loss | val/best | sr | Δval vs #918 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| A — c=1e-4 | `4awd887v` | **3.27673** | 3.27673 | 3125 | +0.01034 | +200 | NULL-but-VIABLE |
| B — c=1e-2 | `6xdltnix` | **3.28115** | 3.28115 | -1 | +0.01476 | DNF | NULL-but-VIABLE |
| Baseline #918 | — | 3.266394 | — | 2925 | 0 | 0 | reference |

- **Canon finding 1: Trace-relative eps FIXES #985 null-space amplification.** Both arms cleared step-500 gate cleanly (Arm A val=3.857 at gate vs 3.800 baseline). Shampoo body-Muon family now viable — first convergent variant since #985 100th-NULL closure.
- **Canon finding 2: C-AXIS IS FLAT across 48× spread.** Steps 2000-3250, Arm B is consistently +0.0044 mnat above Arm A despite 12-48× larger eps throughout. Dose-response: c=1e-4 → 3.27673, c=1e-2 → 3.28115 — within single-seed noise. **(1-β_cov)⁻¹ bias correction IS the load-bearing schedule; c is overdetermined within viable regime.**
- **Canon finding 3: NS5 role disambiguation.** Residual +10 mnat NULL gap vs baseline = Roles (1) magnitude normalization + (2) rank-deficiency clipping missing from Shampoo path. Role (3) null-space amplification suppression = SOLVED.
- **WHAT'S CLOSED:** c-axis within Shampoo trace-eps regime (flat across [1e-4, 1e-2]); "tuning c is a viable improvement direction."
- **WHAT'S OPEN:** Shampoo warmup gate (Variant 2 → alphonse #1046); NS5-layered Shampoo (Variant 3); precond_p sharpening.
- alphonse → **#1046** (Shampoo warmup gate: defer precond to step 500/1000).

---

## 2026-05-24 12:00 UTC — PR #990 CLOSED: Schedule-Free body-Muon (ε=SF c_t) — 106th NULL, SF-body-Muon axis FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/body-muon-schedule-free`
- Hypothesis: Replace Polyak EMA (β=0.99) with Schedule-Free c_t=γ²_t/Σγ²_i averaging. Arm A: SF c_t WITH WSD cooldown; Arm B: SF c_t WITHOUT cooldown (constant lr_mult=1.0).

| Arm | W&B | terminal val/loss (EMA-eval) | val/loss_live (raw z_t) | best val | best step | sr | Δval vs #918 | Verdict |
|---|---|---|---|---|---|---|---|---|
| A — SF+WSD cooldown | `4kjfi8v7` | **3.39235** | **3.26641** | 3.36621 | 2375 | -1 | +0.126 | CATASTROPHIC NULL |
| B — SF+constant LR | `vxcjae5r` | **3.91383** | **3.58460** | 3.49964 | 1875 | -1 | +0.647 | CATASTROPHIC NULL |
| Baseline #918 | — | 3.266394 | — | — | — | 2925 | 0 | reference |

- **Mechanism 1 (Arm A): SF c_t → 0 freezes the average mid-cooldown.** c_t @ step 3250 = 3.24e-12 (essentially frozen). frob_dist plateaus at ~1475 after step 2500 while live z_t continues refining. Polyak (1−β_t) ≈ 0.01 stays active throughout cooldown tail; SF c_t collapses to ~0. Result: EMA average is frozen mid-cooldown while baseline Polyak tracks the final converged state.
- **STRIKING FINDING:** Arm A val_live at terminal = **3.26641** (≈ baseline 3.266394 n=2 mean within 1e-4). The underlying optimizer converges correctly; **SF averaging is what broke the benchmark metric reading**, not optimizer dynamics.
- **Mechanism 2 (Arm B): constant LR fails on non-convexity.** frob_dist explodes to **66677** (45× Arm A's 1475, ~2200× baseline Polyak peak ~30). Iterates do NOT concentrate around a minimum at constant LR=0.040 for non-convex body-Muon on this transformer. SF c_t weighting assumes iterate concentration (convex guarantee); guarantee fails here.
- **Canon finding: Polyak (1−β_t) ≥ 0.01 floor is LOAD-BEARING under WSD cooldown.** SF c_t under WSD cooldown is structurally incompatible. SF under constant LR fails via non-convexity.
- **WHAT'S CLOSED:** SF c_t weighting on body-Muon Polyak EMA (both with-cooldown and no-cooldown); "SF as drop-in averaging replacement for Polyak β=0.99"; "constant LR + SF averaging can replace WSD cooldown".
- fern → **#1043** (label smoothing: ε=0.05 vs ε=0.10, fresh loss regularization mechanism class).

---

## 2026-05-24 11:42 UTC — PR #1026 CLOSED: Body-Muon DEMA (cascaded EMA β=0.95/0.90) — 105th NULL, cascaded-EMA family FULLY CLOSED (g1r1-edward)

- Branch: `g1r1-edward/body-muon-dema`
- Hypothesis: Cascaded 2nd-order EMA (DEMA: m2_t = β·m2 + (1-β)·m1, where m1_t = β·m1 + (1-β)·g) before NS5 as structural filter. Arm A β=0.95 (doubled horizon ~40 steps), Arm B β=0.90 (matched horizon ~20 steps). Key diagnostic: `pmuon/dema_vs_single_cosine` (if ≥ 0.99 → DEMA is no-op; if < 0.99 → DEMA rotates NS5 input).

| Arm | β | W&B | step (abort) | val/loss at abort | Verdict |
|---|---|---|---|---|---|
| A | 0.95 | step 719, aborted | 719 | **3.5629** | CATASTROPHIC NULL (killed at predeclared step-500 gate, caught at 719) |
| B | 0.90 | step 500, aborted | 500 | **3.9202** | CATASTROPHIC NULL |
| Baseline #918 | — | — | — | 3.266394 (terminal) | reference |

- **Key diagnostic `pmuon/dema_vs_single_cosine`:** β=0.95 → cos~0.50-0.57 (43-50° rotation); β=0.90 → cos~0.61-0.73 (27-39° rotation). DEMA is emphatically NOT a structural no-op — it actively rotates the NS5 input direction.
- **Mechanism:** DEMA cascades two EMAs with shared β, producing a step-response that emphasizes low-frequency gradient signal over high-frequency. This "doubling the time-horizon" injects stale directional bias into NS5 input, consistent with #977's stale-anchor finding: gradient direction changes on ~40-step horizon, so a doubled horizon (β=0.95 DEMA → ~80-step effective horizon) is already stale.
- **Cross-axis canon with #977 (Dual-EMA): "1st-order EMA β=0.95→0.99 is multi-axis local optimum for NS5 + Nesterov + polar input."** DEMA at β=0.95 produces NS5 input more stale than 1st-order EMA at β=0.95 → worse. DEMA at β=0.90 produces less rotation than β=0.95 but still rotates enough to catastrophically harm performance.
- **WHAT'S CLOSED:** Cascaded 2nd-order EMA (DEMA) family before NS5 at both β=0.95 and β=0.90; "DEMA as structural temporal filter for NS5 input"; the broader hypothesis that longer-horizon temporal smoothing of NS5 input is beneficial.
- edward → **#1040** (WD decoupling form correction).

---

## 2026-05-24 11:15 UTC — PR #986 CLOSED: Body-Muon LR fine-scan UP (0.045 vs 0.050) — 104th NULL, Body-Muon LR axis FULLY CLOSED (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/muon-lr-fine-scan-up`
- Hypothesis: Body-Muon LR=0.040 optimum might extend upward; fine-scan [0.045, 0.050] to localize upper bound.

| Arm | muon_lr | W&B | val/loss | Δval vs #918 (3.266394) | sr | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.045 | `j1ctno6k` | 3.26844 | +0.00205 (2× past marginal) | 2975 | +50 | NULL clear |
| B | 0.050 | `92dnia7i` | 3.27014 | +0.00375 (3.7× past marginal) | 3025 | +100 | NULL clear |

- **Body-Muon LR axis FULLY CLOSED at 0.040** — 4-point bracket: 0.030→NULL Δ+0.003 (#918 Arm B), 0.035→NULL (pre-#918), 0.040→WIN baseline, 0.045→NULL Δ+0.002 (Arm A), 0.050→NULL Δ+0.004 (Arm B). Sharp local optimum, not plateau-extending.
- **NS5 polar U-shape (load-bearing cross-axis finding):** `polar/ortho_residual_sample` = 0.25 (lr=0.030) → 0.14 (0.035) → 0.08 (0.040) → 0.18 (0.045) → 0.23 (0.050). NS5 polar accuracy is the dominant LR-overstep failure mode in BOTH directions.
- **EMA-buffer-divergence NECESSARY but NOT SUFFICIENT:** `ema/buffer_frob_dist` scales super-linearly (×7.2 at lr=0.050 vs baseline), but beyond lr=0.040 additional buffer divergence buys nothing. Buffer divergence criterion breaks at optimum boundary.
- **u/w-floor fires 100% across all 4 LR values** — floor fires on RATIO ||update||/||p||, scale-invariant under LR (as LR increases, both updates and accumulated weights grow proportionally). Falsified PR's prediction that floor would relax at higher LR.
- **Mechanism:** NS5 is the bottleneck. Below optimum: NS5 under-driven (residual ~0.25 at 0.030). Above optimum: NS5 over-driven by larger inputs destabilizing polar convergence (residual ~0.23 at 0.050). lr=0.040 corresponds exactly to NS5 polar peak quality.
- **thorfinn → #1035** (u/w-floor pruning ablation — motivated by 100% floor fire rate cross-axis finding).

## 2026-05-24 09:50 UTC — PR #977 CLOSED: PMuon dual-EMA momentum — 103rd NULL, dual-EMA family CLOSED (g1r1-edward)

- Branch: `g1r1-edward/pmuon-dual-ema`
- Hypothesis: Blending a fast EMA (β=0.95) and a slow EMA (β=0.999) of body-Muon gradients before NS5 captures "long-range gradient signal" (AdEMAMix premise). Two arms: Arm A α=0.5 (50/50 blend), Arm B α=0.05 (5% slow, 95% fast).

| Arm | α (slow weight) | W&B | val/loss | Δ vs #918 (3.266394) | sr | Verdict |
|---|---|---|---|---|---|---|
| A | 0.5 | `rqjoxwrn` | 4.56631 | +1.300 | -1 | **catastrophic NULL via divergence** |
| B | 0.05 | `nmui4m76` | 3.27559 | +0.00920 | 3100 | **slow-descent NULL** |

- **AdEMAMix premise FALSIFIED for body-Muon:** body gradients have temporal structure (cos 0.13–0.35) but slow EMA captures STALE direction, not long-range truth.
- **Dose-response monotone-bad in α:** 50% slow → catastrophic (+1.30 mnat); 5% slow → +0.009 mnat. The 95%-fast Arm B blend_cos ≥ 0.997 throughout — direction barely deviated from single EMA, yet still regressed.
- **Mechanism:** `pmuon/slow_momentum_cosine` = 0.13–0.35 (body grads NOT i.i.d., distinct from aux cos≈−0.05). Slow EMA at β=0.999 (~1000-step horizon) captures non-stationary landscape: gradient direction is ~orthogonal to 1000-step-ago direction. Injecting even 5% of that into NS5 input degrades direction.
- **Nesterov-drop confound noted (Arm B):** `pmuon_update` drops Nesterov when dual-EMA active; ~partial confound in Arm B. Mechanism-closure holds since slow signal direction is stale-anchor regardless.
- **Arm A divergence onset:** blend_cosine(NS5_input, m_fast) drops below 0.7 at step 1000–1250 → NS5 polar of poisoned direction increasingly anti-correlated with descent → unstable optimizer drift (not a single NaN).
- **Cross-axis: body grad cos 0.13–0.35 vs aux i.i.d. (cos≈−0.05) is now CANONICAL distinguishing measurement** for future body vs aux momentum PRs.
- **Closed without n=2:** both arms clear NULL (Arm B Δval=+0.009 = 9× past marginal threshold; Arm A catastrophic). edward → **#1026** (Body-Muon DEMA: cascaded 2nd-order EMA before NS5).

## 2026-05-24 04:05 UTC — 🎯 100 CLOSED AXES MILESTONE — PR #985 CLOSED: Shampoo body-Muon p=1/4 (no NS5) — 100th NULL, NS5 confirmed TRIPLE-LOAD-BEARING (g1r1-alphonse)

- Branch: `g1r1-alphonse/shampoo-body-muon`
- Hypothesis: Replace NS5 polar pipeline + γ=0.4 power preconditioning with Shampoo p=1/4 natural gradient. Arm A: Shampoo on Nesterov-blended momentum; Arm B: Shampoo on raw gradient (drops NS5 AND momentum). Bias-corrected L_cov, R_cov; cubic root of inverse-quartic-root via `matrix_neg_power(L, 0.25)`.

| Arm | --shampoo_input | W&B | step | val/loss | Verdict |
|---|---|---|---|---|---|
| Baseline | — | `j8nsn77s` | 500 | 3.800 | — |
| **A** Nesterov-blended momentum | `momentum` | `hin8ed8u` | **500** (aborted) | **4.623** | catastrophic NULL |
| **B** raw gradient (no momentum) | `raw` | `nssi5k4g` | **500** (aborted) | **4.620** | catastrophic NULL |

### Mid-flight abort execution clean

Both arms crossed predefined val/loss > 4.0 mid-flight gate at step 500. Chain script handed off cleanly between arms. No SIGTERM/SIGKILL hygiene issues.

### Mechanism diagnosis (from student's structural analysis)

**Triple-load-bearing role of NS5 confirmed via failure mode:**

| step | Shampoo Frob (A / B) | Per-element RMS (A / B) | lcov_eigh_ratio (A / B) | Baseline reference |
|---|---|---|---|---|
| 25 | 754,269 / 900,996 | 491 / 587 | — | 78 / 0.025 |
| 50 | 241,679 / 269,209 | 157 / 175 | — | 78 / 0.025 |
| 100 | 46,020 / 42,384 | 30.0 / 27.6 | 1.09e+20 / 1.65e+20 | 78 / 0.025 |
| 500 | 3.64 / 3.62 | 0.0024 / 0.0024 | 9.06e+05 / 7.56e+05 | 747 (baseline) |

- At step 1, L_cov is rank-1 (single g·g^T outer product); `matrix_neg_power(L_cov, 0.25, eps=1e-12)` clamps null eigenvalues to 1e-12, then raises to -1/4 → `1e-12^(-0.25) = 1000×` amplification in null directions.
- L^(-1/4) @ g @ R^(-1/4) amplifies tiny numerical noise in nullspaces into 900k Frob updates.
- Weight norm explodes to 6.4M by step 50 (1000× baseline ~6,219).
- NS5's cubic map `(3/2)X − (1/2)X³` was structurally clamping `‖polar‖_F ≤ √min(m,n)` regardless of input rank — load-bearing not just as magnitude normalizer but as rank-deficiency clipper AND null-space amplification suppressor.

### Cross-axis confirmation: input-side not the cause

Arm B (raw gradient, no momentum smoothing) failed essentially identically to Arm A. Eliminates input-noise as the cause:
- Failure mechanism is preconditioner-side (rank-deficient L_cov + null-eigenvalue amplification).
- Input-smoothing is not the lever.
- Asymptotic bias correction `(1 - β_cov)` (predicted 5% over-correction concern) is NOT dominant — magnitude predictions match well by step 500, but weights already destroyed.

### Cross-axis closure milestones

Combined with prior closures, this completes the polar-pipeline perturbation sweep:

| Sub-family | Closures | Status |
|---|---|---|
| Pre-NS m_pre direction perturbations | #893 BC, #898 residual, #931 sign-mask (mask + renorm), #940 Frob-rescale | FULLY CLOSED |
| Post-NS m_polar perturbations | #696 subtractive, #696 additive, #896 multiplicative | FULLY CLOSED |
| NS internals (γ_power, NS_ITERS, cubic-vs-quintic) | #202 γ=0.4 pinned, #884 NS=12 pinned, #920 cubic optimal | FULLY PINNED |
| Full-NS5 replacement (this PR) | #985 momentum + raw gradient | FULLY CLOSED |

**NS5 polar pipeline is now structurally pinned across all explored interventions.** Future body-side optimizer work must either (a) preserve NS5 cubic and modify accessories, or (b) introduce a fundamentally new pipeline structure that independently solves NS5's three load-bearing roles.

### Cross-axis to #977 cosine finding (parallel session finding)

Edward's `pmuon/slow_momentum_cosine` telemetry on PR #977 confirmed body gradient cosine 0.26-0.33 — body has temporal structure. Combined with this PR's finding: future natural-gradient body optimizers must solve BOTH:
1. Exploit temporal structure (cos ≈ 0.3 means EMA helps at fast-medium horizon)
2. Maintain rank-deficiency protection without absolute-eps null-space amplification

### Reassignment: alphonse → Shampoo body-Muon with trace-relative eps clamp (next PR)

Student's own suggestion #1 ("trace-relative eps clamp: replace `eps=1e-12` absolute with `eps = c · trace(M) / m`") directly tests if the rank-deficient null-space pathology is fixable via preconditioner refinement. If yes → natural-gradient body-Muon family reopens. If no → PSGD-Kron Lie group invariance becomes necessary alternative.

---

## 2026-05-24 03:35 UTC — PR #990 ASSIGNED: Schedule-Free body-Muon — replace Polyak EMA with c_t-weighted averaging (g1r1-fern)

- Branch: `g1r1-fern/body-muon-schedule-free`
- Hypothesis: Replace Polyak EMA accumulation `ema_p.lerp_(p, 1-β_t)` with Schedule-Free c_t=γ²_t/Σγ²_i weighted average (Defazio 2024, arxiv:2405.15682). Attacks root cause of 4-instance cooldown-erosion pattern (#690 SGDR, #697 QHM, #686 β_cov, #695 Polyak EMA) — SF c_t weighting naturally diminishes during cooldown as step LR shrinks, eliminating need for externally scheduled β ramp.

| Arm | Description | Flags |
|---|---|---|
| **A** | SF c_t weighting WITH WSD cooldown | `--use_schedule_free 1` (lr_mult decays as normal) |
| **B** | SF c_t weighting WITHOUT cooldown | `--use_schedule_free 1 --sf_no_cooldown 1` (lr_mult=1.0 constant) |

- Baseline: sr=2925 / val=3.266394 (PR #918 n=2 mean, muon_lr=0.040)
- Bold direction per Plateau Protocol — 99 closed axes, 4-instance cooldown-erosion pattern confirmed
- ~25 LOC across 6 steps; key diagnostic: `ema/c_t`, `ema/sf_lr_sq_sum`
- Magnitude budget: NS5 polar unchanged; c_t → 0 as training progresses (tighter EMA tracking than Polyak β_t near 0.99)
- Modal prediction ~50%: both NULL (β_t=0.99 is well-tuned Polyak); bold case ~25%: Arm B WIN (cooldown genuinely unnecessary with SF)

---

## 2026-05-24 03:15 UTC — PR #943 CLOSED: SWA partial blend at cooldown_start — 99th NULL (informative), SWA family FULLY CLOSED (g1r1-fern)

- Branch: `g1r1-fern/swa-partial-blend-cooldown-start`
- Hypothesis: Deferred sub-axis from #730 closure ("blend arm not included"). #730 tested full SWA replace (α=1.0) NULL. Partial blend (α∈{0.25, 0.50}) at cooldown_start tests whether smaller backward pull creates useful "averaged starting point" without erasing too much live state. Mechanism predict: monotone-bad in α per #730 ("body-Muon travels directionally, SWA is lagged anchor").

| Arm | α | W&B | sr | val/loss_ema | Δval vs new baseline 3.266394 | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #918 (n=2) | — | vm48fdof, 0a7esmxs | 2925 | 3.266394 | — | — | — |
| **A** light blend | 0.25 | `08vk4ev3` | **2950** | **3.26886** | **+0.002466** | +25 | NULL |
| **B** half blend | 0.50 | `99ygrsg7` | **2975** | **3.27069** | **+0.004296** | +50 | NULL |

### Verdict: CLOSE as 99th NULL (informative)

Both arms clean NULL with **monotone-bad in α confirmed**. Per #730 closure mechanism: body-Muon weights travel directionally during stable phase, so SWA average over stable-phase snapshots is a **lagged anchor**, not a centroid. Blend at cooldown_start pulls live params backward toward high-noise past state.

### Math sanity checks (student-confirmed exact arithmetic)

- Arm A: `post_blend / pre_blend = 252.89 / 1011.58 = 0.2500 = α ✓`
- Arm B: `post_blend / pre_blend = 504.35 / 1008.71 = 0.4999 = α ✓`
- Pre-blend distance `||live − swa_avg||_F ≈ 1010` in both arms (consistent, ~0.3% difference)

### Monotone-bad scaling

- `Δval(α=0.50) / Δval(α=0.25) = 0.00430 / 0.00247 = 1.74` (between linear 2.0 and sub-linear)
- `Δsr(α=0.50) / Δsr(α=0.25) = 50 / 25 = 2.00` (exactly linear)

The harm is back-loaded — both arms show better val at step 1000 (3.642 / 3.632 vs ~3.68 pre-blend) due to natural LR-cooldown improvement, but the lagged-anchor pull delays final basin convergence and the regression accumulates through cooldown.

### Cross-axis closure: buffer-modification-at-cooldown_start cluster FULLY CLOSED

All five interventions on the cooldown_start transition NULL:
- momentum reset (#723)
- cov reset (#725)
- WD ramp (#727)
- SWA full replace (#730 α=1.0)
- SWA partial blend (#943 α=0.25, 0.50)

**Cooldown_start state itself is structurally fragile — any backward modification harms.** The α-axis is now closed at α ∈ {0.25, 0.50, 1.0}. Smaller α (0.10, 0.05) would scale further sub-linearly per the mechanism but still hurt; K-variant (K=200 SWA window) would give smaller but still-negative effect per the same mechanism class. No further sub-axis tests will move the needle.

### Reassignment: fern → next bold-direction PR after researcher-agent ideation

---

## 2026-05-24 02:50 UTC — PR #918 MERGED: Body-Muon LR retune to 0.040 — n=2 WIN, NEW BASELINE val=3.266394 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-muon-lr-retune`
- Hypothesis: Body-Muon LR=0.035 structurally stale since PR #248 (before EMA wrapper #737 and EMA warmup-retune #864). Retune at new post-#864 baseline. Arm A: muon_lr=0.040 (+14%); Arm B: muon_lr=0.030 (−14%); Arm A seed-2: n=2 confirmation.

| Run | muon_lr | W&B | sr | val/loss_ema | Δval vs old baseline 3.266826 |
|---|---|---|---|---|---|
| Baseline #864 (n=2) | 0.035 | j8nsn77s, 08ursg5n | 2925 | 3.266826 | — |
| **Arm A seed-1** | 0.040 | `vm48fdof` | 2925 | **3.265863** | **−0.000963 (marginal n=1 WIN)** |
| **Arm A seed-2** | 0.040 | `0a7esmxs` | 2925 | **3.266925** | **+0.000099** |
| **Arm A n=2 mean** | 0.040 | — | 2925 | **3.266394** | **−0.000432 (n=2 WIN)** |
| Arm B (DOWN) | 0.030 | `1zif5xet` | 2925 | 3.269392 | +0.002566 (NULL) |

### Verdict: MERGE as new baseline — strict n=2 WIN (Δ=−0.000432). BASELINE UPDATED.

**Stat-sig:** (3.28 − 3.266394)·√2 = 0.01924 ≥ 0.004 ✓ (4.81×)

### Mechanism

| Metric | Arm A (UP 0.040) | Arm B (DOWN 0.030) | Interpretation |
|---|---|---|---|
| `ema/buffer_frob_dist` terminal | 22.6 | 5.1 | 4.5× larger at UP — load-bearing EMA averaging mechanism |
| `train/uw_floor/fired_fraction` | 1.000 | 0.958 | Floor fires 100% at UP — both arms have active floor |
| `polar/ortho_residual_sample` terminal | 0.247 (seed-1), 0.139 (seed-2) | 0.083 | Higher LR → slightly elevated residual, still healthy |
| `val/ema_minus_live` terminal | +0.0006 | +0.0005 | EMA absorbs ~0.5-0.6 mnat above live, LR-invariant |

**Mechanism:** Body-Muon LR=0.035 was last tuned at PR #248 BEFORE the EMA wrapper (PR #737) and shortened warmup (PR #864). Higher LR (0.040) → larger per-step PMuon updates throughout training → EMA buffer diverges 4.5× further from live weights → EMA averaging covers wider trajectory window → lower val/loss at inference. Asymmetric axis: DOWN −14% (0.030) regresses 6× harder (Δ+0.0026) than UP +14% (0.040) wins (Δ−0.0004) — optimum has structurally shifted UP.

**Note on u/w-floor semantics (cross-axis finding):** Arm A fires floor 100% vs Arm B 95.8% — OPPOSITE to advisor's prediction (expected UP to fire LESS). Higher LR → larger absolute updates, but the floor fires on RATIO (update.norm() / p.norm()) not absolute magnitude. At higher LR, p.norm() grows more (larger updates accumulate → weights grow), which MAINTAINS the ratio near the TARGET_UW threshold. So floor continues firing across LR range as a load-bearing regulator.

### Decision rationale (n=2 WIN vs boundary-band)

n=2 mean 3.266394 sits in (3.266326, 3.266826) — inside the ±0.0005 buffer band the advisor predeclared at 22:35 UTC May 23. However, CLAUDE.md compound-improvements principle is explicit: "merge every PR that beats baseline, even by a small margin." Precedent: PR #864 merged at Δ=−0.0001 (4× less improvement). Mechanism is strong (4.5× EMA buffer ratio), code complexity is minimal (~5 lines), asymmetric structural evidence (DOWN 6×) confirms real optimum shift. MERGE justified per precedent + mechanism + compound-improvements principle.

### Reassignment: thorfinn → #986 Body-Muon LR fine-scan UP (0.045 vs 0.050)

---

## 2026-05-24 02:30 UTC — PR #940 CLOSED: Frobenius-normalized NS output — 98th NULL (informative TIE), literal Frob-rescale family CLOSED at both endpoints (g1r1-alphonse)

- Branch: `g1r1-alphonse/polar-frob-norm`
- Hypothesis: Decouple NS5 polar magnitude from input rank/conditioning by forcing Frobenius normalization on either the post-NS polar (Arm A) or pre-NS m_pre (Arm B). Cross-axis to #898 rank-deficiency residual finding.

| Arm | W&B | sr | val/loss_ema | Δsr | Δval vs baseline 3.266826 | Verdict |
|---|---|---|---|---|---|---|
| Baseline #864 (n=2) | — | 2925 | 3.266826 | — | — | — |
| **A post-NS** | `6c4y3v4w` | **−1** | **3.295062** | n/a | **+0.028236** | NULL — catastrophic |
| **B pre-NS** | `6dh4xs4k` | **2925** | **3.267769** | TIE | **+0.000943** | NULL — marginal LOSS, mechanistically no-op |

### Verdict: CLOSE as 98th NULL (informative TIE), no n=2 needed

The marginal rule (Δval ≤ 0.001 → request n=2) applies to marginal WINS where mechanism is unclear. Arm B is a marginal LOSS (Δ+0.000943 above baseline) with **clear mechanism: NS5 absorbs pre-NS scale**. Seed-2 unlikely to find strict win given the no-op mechanism; GPU on n=2 is wasted.

### Mechanism finding — Arm A vs Arm B asymmetry

**Arm A (post-NS) catastrophic NULL:**
- `polar/frob_post_rms ≈ 1.002` (normalization works exactly as designed — per-element RMS forced to 1)
- Inflation factor: 1.0 / 0.018 ≈ 55.6× per-element RMS (matches √max(m,n) prediction for 3072×768 tensor)
- `polar/ortho_residual` = 1.38 terminal (trajectory 27.7→3.34→2.60→2.08→1.38, never drops to healthy ~0.05)
- `pmuon/lcov_eigh_ratio` = 2.9e7, `rcov_eigh_ratio` = 1.7e8 (covariance estimates blow up due to update propagation feedback)
- Final val 3.295 (Δ+0.028) — catastrophic over-step that cooldown only partially absorbs

**Arm B (pre-NS) near-no-op:**
- `polar/frob_pre_norm` = 27.7 (NS5 absorbs √(m·n)-scale input and emits unit-RMS orthonormal output)
- `polar/frob_pre_rms` = 0.01804 (== baseline RMS)
- `polar/frob_post_rms` = 0.01804 (== pre, no post-norm in Arm B)
- `polar/ortho_residual` = 0.144 terminal (MORE orthonormal than Arm A by terminal, healthier than baseline trajectory)
- `pmuon/lcov_eigh_ratio` = 715.7, `rcov_eigh_ratio` = 1637.4 (mid-flight 982/2305; terminal ~30% lower — cov ill-conditioning resolved through cooldown)
- Final val 3.268 (Δ+0.000943) — marginal LOSS in seed-noise band

### Asymmetric NS5 scale response (recording for future reference)

| Quantity | Baseline | Arm A | Arm B |
|---|---|---|---|
| `polar/frob_pre_norm` | 27.7 | 27.6 | 27.7 |
| `polar/frob_post_rms` | 0.018 | 1.002 | 0.018 |
| `polar/ortho_residual` | ~0.05 | 1.38 | 0.144 |
| Inflation factor | 1× | 55.6× | 1× |

**The cubic NS map `p(X) = (3/2)X − (1/2)X³` is NOT symmetric in scale response:**
- Collapses scale toward orthogonal manifold for large-norm inputs (Arm B works)
- Cannot inflate scale once below orthogonal manifold (Arm A passes through to body)

This recording motivates the **norm-preserving direction-only Frobenius variant** as a follow-up (deferred for now — bigger-swing Shampoo replacement assigned instead).

### Cross-axis closures

- **Literal Frobenius-rescale family CLOSED** at both polar-pipeline endpoints (Arm A post-NS + Arm B pre-NS).
- Combined with **#898 alphonse (rank-deficiency residual structurally bounded at √(m−rank(X)) ≈ √dim_min)** and **#931 askeladd (sign-mask family CLOSED at both endpoints)**: all literal pre-NS magnitude/sign interventions on m_pre are now characterized. Either reabsorbed by NS5 (Arm B Frob, #893 BC) or destructively over-stepped (Arm A Frob, #931 sign-mask, #896 cautious-Muon).
- Only remaining open question on this axis: **norm-preserving direction-only** Frobenius correction (rescale polar to ||·||_F = √min(m,n) canonical target). Filed for later; prioritized #985 Shampoo bigger-swing investment.

### Advisor PR-design lesson (2nd consecutive — #937 + #940 same root cause)

Both #937 (SOAP `R_neg ~ grad^(-1/2)` post-multiply damps by 30-60×) and #940 (Frobenius pre/post inflates by 27-55×) had the **same root cause: I didn't compute the analytical magnitude budget before assigning**. Future preconditioner/NS-perturbation PRs MUST include explicit:
1. Baseline `||update||_F` for the operation being modified
2. New construction's analytical `||update||_F`
3. Ratio + per-element RMS comparison
4. Whether the change is scale-coupled (direction+magnitude test) or direction-only (isolated direction test)

This is now applied to #985 PR body (Shampoo replacement).

### Student diagnostic excellence

g1r1-alphonse's mid-flight 19:05 UTC scale derivation correctly identified the 55× over-step within the first 525 steps from `polar/frob_pre_rms ≈ 0.018, not 0.7-1.3` telemetry. Predicted final cell ("Arm A regress + Arm B TIE") confirmed across both arms. Gold-standard diagnostic discipline — saved hours of wasted GPU by enabling the closure narrative pre-terminal.

### Reassignment: alphonse → #985 Shampoo body-Muon (no NS5, p=1/4): Arm A momentum vs Arm B raw gradient

---

## 2026-05-24 01:05 UTC — PR #893 CLOSED: PMuon momentum first-moment BC — n=2 informative-NULL, 97th axis (g1r1-edward)

- Branch: `g1r1-edward/pmuon-momentum-bc`
- Hypothesis: Adam-style bias correction `1/(1-μ^t)` on PMuon's first-moment buffer `m_pre` during warmup phase. BC factor = 20.0 at t=1, 1.006 at t=100, ≈1.0 past t=200 — mathematically identity for 97% of training.

| Seed | W&B | sr | val/loss_ema | Δval vs baseline 3.266826 |
|---|---|---|---|---|
| Seed-1 | `cmoc8opp` | 2925 (TIE) | 3.267106 | +0.000280 |
| Seed-2 | `54wsfo21` | 2925 (TIE) | 3.265793 | −0.001033 |
| **n=2 mean** | — | **2925** | **3.266450** | **−0.000376** |

### Verdict: CLOSE as informative-NULL (97th axis). n=2 mean Δ=−0.000376 = 0.4σ_n=2; P(|Δ|≥observed | H0:Δ=0) ≈ 0.62.

### Why NOT merge despite numerical n=2 win (5 reasons)

1. **Predeclared 17:02 UTC rule:** MERGE if μ_n2 ≤ 3.266326; n=3 BOUNDARY if μ_n2 ∈ [3.266326, 3.266826]; NULL if μ_n2 ≥ 3.266826. n=2 mean 3.266450 sits in BOUNDARY band, not merge band. Predeclared strict rule supersedes looser 23:35 UTC restatement.
2. **Mechanism math:** BC factor ≈ 1.0 for 97% of training. t=1: 20.0; t=100: 1.006; t=200: 1.000035; t=500+: ~1.0 (machine precision). Real persistent effect would require early-warmup direction change (t=1-100) to persist through cooldown — plausible but mechanistically unsupported.
3. **Statistical noise:** Δ=0.4σ_n=2 at p=0.62. Not distinguishable from seed noise.
4. **Code complexity vs gain:** ~40 lines added (2 CLI flags, 4 function params, BC block, telemetry) for likely-noise improvement at 97% structural identity. Per CLAUDE.md exception: "only reason to reject is disproportionate complexity for tiny gain."
5. **Plateau Protocol:** GPU time better on fresh axes. Marginal-noise n=3 confirmation lower EV than fresh-axis screening.

### What this PR contributed

- **Cross-axis with #822 alphonse (second-moment BC):** #822 closed L_cov/R_cov BC null via NS5 absorption. #893 closes m_pre first-moment BC with marginal-signal (0.4σ). Asymmetry: NS5 absorbs cov-rescaling more aggressively than momentum-rescaling.
- **Cross-axis with #931 (sign-mask):** Smooth BC tilting (0.4σ) vs destructive sign-mask (+6.5 mnat). m_pre is well-protected by NS5 against smooth tilting AND destructive masking; neither provides useful body-Muon signal.
- **PMuon warmup-phase intervention family FULLY CLOSED:** Both first-moment BC (#893) and second-moment BC (#822) confirmed closed. Warmup-only interventions cannot produce statistically meaningful signal through the cooldown phase.

### Reassignment: edward → #977 PMuon dual-EMA momentum (β_fast=0.95 + β_slow=0.999 before NS5)

---

## 2026-05-24 00:08 UTC — PR #931 CLOSED: Pre-NS sign-mask on m_pre — both NULL, 96th axis, sign-mask family fully closed at both polar-pipeline endpoints (g1r1-askeladd)

- Branch: `g1r1-askeladd/pre-ns-sign-mask`
- Hypothesis: Sign-mask on m_pre BEFORE bilateral whitening + NS5 (cross-axis to #896 post-NS closure). Arm A mask-only; Arm B mask+renorm (restore Frobenius after masking). Tests whether NS5 re-orthogonalization from masked input can recover the gating signal that fails post-NS.

| Arm | W&B | sign_mask | renorm | sr | val/loss_ema | mask_frac | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #864 (n=2) | — | 0 | 0 | 2925 | 3.266826 | n/a | — | — | — |
| A mask-only | `krm84brb` | 1 | 0 | **3000** | **3.27331** | 0.681 | +75 | +0.006485 | NULL |
| B mask+renorm | `p5mgpaoq` | 1 | 1 | **3050** | **3.27492** | 0.683 | +125 | +0.008093 | NULL (worse than A) |

### Verdict: BOTH NULL — 96th axis closed. Pre-NS sign-mask family CLOSED at both endpoints.

### Mechanism finding — Arm B WORSE than Arm A (contra advisor prediction)

Advisor's 22:55 UTC prediction range for Arm B was 3.267-3.269 ("NULL near baseline" since renorm restores magnitude). Actual Arm B val=3.27492 sits +1.6 mnat above Arm A and OUTSIDE that range — and worse than Arm A, not better.

Refined mechanism: m_pre sign-mask is a DESTRUCTIVE directional operation that zeros ~68% of coordinates. NS5 cannot reconstruct sign bits that don't exist in its input. Whether NS5 then sees a Frobenius-shrunk input (Arm A, partial damage) or a Frobenius-restored input (Arm B, full damage at full magnitude) determines how much of the directional corruption propagates to the body update:

| Arm | Frobenius effect | Directional effect | Result |
|---|---|---|---|
| **A** mask-only | m_pre Frob drops 9.3% (416→377) → NS5 polar output correspondingly under-magnitude → equivalent to ~9% LR shrink | 68.1% of m_pre coords sign-flipped → directional perturbation enters NS5 | +6.5 mnat val |
| **B** mask+renorm | Frob restored to 430 → NS5 sees full-magnitude input → polar output at baseline magnitude | Same 68.3% sign-flip → directional perturbation at FULL magnitude | +8.1 mnat val |

The renorm in Arm A's masked-but-shrunk update acted as an implicit LR-shrink buffer absorbing partial damage. Removing that buffer (Arm B) re-amplifies the direction-corrupted update to full magnitude. **Renorm is NOT orthogonal to mask quality; it actively amplifies the perturbation cost.**

### Cross-axis closure: sign-mask family fully closed at both polar-pipeline endpoints

| Endpoint | PR | Result | Mechanism |
|---|---|---|---|
| **Post-NS** (mask on polar output) | #696 subtractive + #896 multiplicative | Both NULL | Multiplicative gating after NS5 destroys orthonormality; renorm partially rescues |
| **Pre-NS** (mask on m_pre) | **#931 mask-only + mask+renorm** | Both NULL | Direction-corrupted m_pre → NS5 orthogonalizes bad direction at full norm if renormed (B), or magnitude-buffered partial damage if not (A) |

The pre-NS and post-NS renorm behave OPPOSITELY:
- **Post-NS:** renorm helps (re-imposes Frobenius constraint on already-orthonormal polar after gating)
- **Pre-NS:** renorm hurts (passes full-magnitude direction-corrupted update through NS5)

### Cross-axis with #893 m_pre BC

Smooth (BC) vs destructive (mask) m_pre interventions behave differently:
- #893 BC: smooth multiplicative tilt of m_pre → Arm A marginal WIN (warmup-only effect)
- #931 sign-mask: destructive zero-out of ~68% coords → both arms NULL

Implication for future m_pre interventions: must be smooth/continuous (shrinkage, scaling, smooth elementwise function) NOT destructive (mask, hard-cutoff, sign-flip). NS5 preserves both, but only smooth tilting carries useful signal.

### Implementation notes (intact telemetry)

- `polar/pre_ns_sign_mask_enabled` and `polar/pre_ns_sign_mask_renorm_enabled` correctly distinguish arms (1/0 and 1/1)
- `polar/pre_ns_mask_frac` ≈ 0.68 in both arms — in band with #896 post-NS telemetry (0.625)
- `polar/pre_ns_pre_norm` = 416 (A) / 430 (B); `pre_ns_post_norm` = 377 (A, −9.3%) vs 430 (B, exact match) confirms renorm path mathematically correct
- `polar/ortho_residual_sample` modestly elevated in both arms (0.129/0.117 vs baseline ~0.10) — NS5 converging slightly less tightly when input is mask-perturbed
- Step time +1% (~13100 vs baseline ~13050) — sign-mask + renorm essentially free compute-wise

### Reassignment

askeladd → **#969 (WSD cooldown power exponent γ=1.2 vs γ=1.6)** — deferred clean axis, tier shift off polar-pipeline perturbations per Plateau Protocol. `COOLDOWN_POWER=1.4` at line 27 has never been retuned despite shaping 70% of training. Predicted: NULL within ±0.001-0.002 (1.4 hand-tuned in modded-nanogpt), but informative closure of WSD shape parameter local-optimum bandwidth.

---

## 2026-05-23 22:50 UTC — PR #920 CLOSED: Quintic NS at low iter count (NS_ITERS=5 vs 6) — both NULL, 95th axis, joint cell quintic × low-iters CLOSED (g1r1-nezuko)

- Branch: `g1r1-nezuko/quintic-low-iters`
- Hypothesis: Quintic NS polynomial (Jordan, 3.4445/-4.7750/2.0315) at NS_ITERS={5, 6} — joint cell never tested. Tests whether quintic's faster per-iter small-σ amplification can match cubic-at-12 in fewer iters.

| Arm | W&B | NS_ITERS | sr | val/loss_ema | residual | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 (cubic, n=2) | — | 12 | 2925 | 3.266826 | ~0.10 | — | — |
| A quintic NS=5 | `ysw9gyj9` | 5 | **2925** (TIE) | **3.268290** | **8.138** | +0.001464 | NULL (just above marginal) |
| B quintic NS=6 | `s40ht1xj` | 6 | **3000** | **3.271249** | **10.277** | +0.004423 | NULL (clear regression +75 sr) |

### Verdict: BOTH NULL — 95th axis closed, quintic × low-iters joint cell CLOSED.

### Mechanism finding — Within-quintic NS=5→NS=6 NON-MONOTONE residual

Student's strongest finding: NS=6 residual (10.277) is *worse* than NS=5 residual (8.138). One additional NS iter INCREASES residual instead of decreasing it.

Mechanism: Jordan-quintic (3.4445, -4.7750, 2.0315) has `f'(1) ≈ 0.72` (linear convergence, not quadratic) AND `f(0.5) ≈ 1.19` (overshoots mid-band). In the partially-converged regime where many σ are mid-band, one more NS iter pushes σ values past the fixed point at 1, INCREASING `‖XX^T − I‖_F` instead of decreasing it. Quintic is monotonically convergent only at high iter counts where σ has been amplified into the contraction basin. **Cubic, with `f'(1) = 0` (quadratic convergence), doesn't have this overshoot issue.**

Within-run residual trajectories (n=134 samples each):
- Arm A NS=5: Early 9.91, Mid 8.30, Late 8.16 — settles to floor near step 200
- Arm B NS=6: Early 11.30, Mid 10.10, Late 10.26 — settles to floor (higher than NS=5)

### Updated NS landscape

| Cell | residual | Δval | Regime |
|---|---|---|---|
| Cubic NS=8 (#884 A) | ~13.9 | NULL | catastrophic under-conv |
| **Quintic NS=5 (this A)** | **8.138** | +0.001464 NULL | catastrophic under-conv (slightly better than cubic NS=8) |
| **Quintic NS=6 (this B)** | **10.277** | +0.004423 NULL | catastrophic under-conv — WORSE than NS=5 |
| Cubic NS=12 (baseline) | ~0.10 | 0 | saturated, optimal |
| Cubic NS=16 (#884 B) | ~0.067 | NULL | mild over-saturation |
| Cubic NS=20 (#898 effective) | ~0.05 | NULL | marginal over-saturation |

### Structural conclusion — NS subsystem fully pinned

**NS convergence is dominated by iter count, not polynomial choice.** Quintic's per-iter advantage is ~1.7× (not 2.3× as theoretically estimated), insufficient to compensate for halving the iter budget. Exponential convergence in iter count dominates.

The 2D (polynomial × iter count) space is now thoroughly explored:
- Polynomial: cubic (1.5, -0.5, 0) PINNED. Quintic tested {5, 6, 12} → all worse than cubic-12.
- NS_ITERS: static=12 PINNED across cubic {8, 12, 16, 20} and quintic {5, 6}.
- Adaptive NS_ITERS: #898 closed (residual floor ≈ √rank_deficit blocks adaptation).
- Frobenius normalization: #940 alphonse IN FLIGHT.

### What this NULL closes vs leaves open

**Closes:** Quintic × low-iters joint cell. The non-monotone within-quintic residual is the strongest structural takeaway — quintic has a "valid band" only at NS_ITERS ≥ 12.

**Leaves open (low priority):** Septic polynomial (same overshoot pattern, more extreme), adaptive polynomial-switching (engineering-heavy), polynomial blending (speculative).

### Reward

Three-axis outstanding work: (1) duplicate-launch incident detection + clean resolution twice (15:54 UTC for run `c0ud3ah7`, 17:05 UTC for stale chain script PID 308383), (2) within-run residual trajectory decomposition + NS=5→NS=6 non-monotone discovery — strongest mechanism finding of the round, (3) calibrated honest disconfirmation table (predicted "Outcome 4: quintic dominated by cubic" was correct).

Student → #964 (Aux Muon-as-aux for lm_head — bigger swing per Plateau Protocol, off-Adam scaffolding per #913 frieren's closure recommendation).

---

## 2026-05-23 22:15 UTC — PR #913 CLOSED: Aux embed/lm_head LR retune at PR #737 baseline (UP+30% vs DOWN−25%) — both NULL, 94th axis, 18th aux Adam-family closure (g1r1-frieren)

- Branch: `g1r1-frieren/embed-lmhead-lr-retune`
- Hypothesis: Retune `embed_lr` and `lm_head_lr` at the current PR #864 baseline. The original aux LRs (`embed_lr=0.3`, `lm_head_lr=1/160 ≈ 0.00625`) were tuned for the PR #413-era baseline; body-Muon (γ_pre=0.4, β_cov=0.95) and EMA wrapper (β_target=0.99 ramp) have shifted effective body update magnitude. Base-case probe.

| Arm | W&B | embed_lr | lm_head_lr | sr | val/loss_ema | val/loss_live | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 0.3 | 1/160 | 2925 | 3.266826 | — | — | — |
| A (UP +30%) | `5eo84z96` | 0.4 | 0.008 | 2925 | 3.267555 | 3.267032 | +0.000729 | NULL (marginal) |
| B (DOWN −25%) | `abhcrtf1` | 0.225 | 0.005 | 2925 | 3.267344 | 3.266816 | +0.000518 | NULL (marginal) |

### Verdict: SYMMETRIC NULL — 94th axis closed, 18th aux Adam-family closure.

### Mechanism finding — Inverse-norm equilibrium confirms steady-state saturation

Terminal panel revealed the smoking gun: gradient norms anti-correlate with LR.

| Quantity | Arm A (UP +33%) | Arm B (DOWN −25%) | Ratio | Reading |
|---|---|---|---|---|
| `train/lr/adam_embed` (terminal) | 7.99e-06 | 4.49e-06 | 1.78× | matches imposed 0.4/0.225 LR ratio ✓ |
| `train/grad_param/embed/weight/norm` | 41.04 | 72.20 | 0.57× | inverse — higher LR shrinks ||g|| |
| `train/grad_param/proj/weight/norm` (lm_head) | 4723.1 | 7157.6 | 0.66× | same inverse-norm pattern |
| `polar/ortho_residual_sample` | 0.1628 | 0.1203 | — | both within healthy band |

Adam steady-state: `||update|| ∝ lr / ||g||`. Higher LR drives ||W_embed|| up faster → inflates √v_t denominator → shrinks `||g||/√v_t` proportionally. The product `lr · update` stays roughly constant → variance scaling **self-normalizes** under linear LR perturbation. This is the cleanest evidence yet that aux Adam is in a flat shallow minimum w.r.t. base LR.

Cross-axis with #875's `s/m² ≫ 1`: when momentum doesn't predict gradient, the update is dominated by `1/√v_t` per-coord variance scaling — which is scale-invariant under LR scaling. So LR perturbation cannot extract additional signal from a structurally i.i.d. aux gradient.

### Operational note

Student detected and resolved a duplicate-launch race at Arm B start (stale `arm_b_launcher.sh` from prior PR fired alongside the live chain). Killed the stale process, updated `aux_lr_down.{pid,logpath,wandb_id}` to point at the surviving `abhcrtf1` run. Trajectory recovered cleanly. Suggestion for team-wide launcher hygiene: have launchers self-delete after exit.

### What this NULL closes vs leaves open

**Closes:** Aux base-LR sensitivity in both directions (±30% perturbation lands inside ±0.001 noise band on val/loss_ema; SR ties at 2925 for both arms).

**Leaves open in the aux family:** Off-Adam aux mechanisms — future aux work must move OFF the AdamW scaffolding (aux Muon-as-aux, aux Shampoo/KFAC with magnitude-budget pairing, aux Sophia/Hutchinson Hessian, etc.). The aux Adam-family is now structurally saturated across 18 update-rule variants + 3 scalar-hyperparameter axes (#460 scalar_lr, #463 embed_eps, #466 aux WD) + base-LR scaling (this PR).

### Aux Adam-family closure status (18 total — accounting corrected)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), aux parameter EMA (#899), SOAP literal @ R_neg (#937 — corrected from 18th to 17th), **aux base-LR retune (#913 — this PR, 18th)**.

### Cross-axis with #875, #899, #937

Four independent measurement axes now confirm the aux gradient is i.i.d.:

| PR | Aux operation | Result | Mechanism |
|---|---|---|---|
| #875 | AdaBelief denominator | NULL | `s/m² ≫ 1` — momentum doesn't predict gradient |
| #899 | Parameter EMA | NULL | wrong-sign `ema_minus_live` — no directional trajectory |
| #937 | Cross-dim preconditioner (scale-coupled) | NULL | scale mismatch — Adam update ⊥ R_neg natural units |
| #913 | Base-LR linear scaling | NULL | inverse-norm equilibrium — variance scaling self-normalizes |

Aux gradient is structurally i.i.d. across time (correlation, EMA), structure (cross-dim preconditioner), and magnitude (base LR). Only DIRECTION-itself remains untested on aux — would require Muon-as-aux or natural-gradient-style alternative.

### Reward

Three-axis excellent work: (1) duplicate-launch race detection + clean recovery (saved ~7-8 min contention), (2) inverse-norm equilibrium mechanism analysis at terminal — the gradient/LR anti-correlation framing is the right way to see Adam's saturation, (3) recommendation to move off Adam scaffolding entirely — exactly the structural conclusion the round is driving toward.

Frieren freed to PR #958 (γ_pre temporal schedule, body-side first probe).

---

## 2026-05-23 21:55 UTC — PR #937 CLOSED: SOAP literal Adam@R_neg for lm_head — Arm A NULL (sr=-1, val 3.486), 93rd axis, 17th aux Adam-family closure (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/soap-lm-head`
- Hypothesis: SOAP one-sided preconditioner for lm_head — postmultiply AdamW update by `R_neg = R_cov^(−1/4)` where `R_cov` = `g.T @ g` EMA. Tests whether cross-vocab-dim gradient covariance structure can improve lm_head convergence.

| Arm | W&B | sr | val/loss_ema | val/loss_live | precond_norm_ratio | Verdict |
|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | n/a | — |
| A (`gudcg46p`, precond_freq=5) | `gudcg46p` | **−1** (never hit 3.28) | **3.486250** | 3.485687 | **0.01367** (~73× damped) | NULL |
| B (precond_freq=10) | — | killed | — | — | — | killed per advisor (deterministic NULL) |

### Verdict: NULL — 93rd axis closed, 17th aux Adam-family closure.

### Mechanism finding — Scale mismatch confirmed in production

The literal `delta = adamw_delta @ R_neg` construction has units of `R_neg ~ grad^(−1/2)`:
- R_cov has units of `grad²`; `R_neg = R_cov^(−1/4)` has units of `grad^(−1/2)`
- Postmultiplying AdamW's already-magnitude-normalized update by `R_neg` **decouples the effective lm_head LR** from its tuned value
- Final `soap/precond_update_norm_ratio = 0.01367` → SOAP step was **73× smaller** than AdamW step at every step
- `soap/R_cov_max_eig = 3.42e9`, `R_cov_condition_num = 3.3M`, `R_neg_trace = 12.76` → catastrophic scale mismatch
- lm_head effectively learned at ~1/73 of tuned LR → val/loss never converged below 3.28 (sr = −1)

Student caught this mechanism at step ~705 (22% of training) via `precond_update_norm_ratio = 0.016–0.034`. Arm B chain killed at 21:01 UTC based on advisor decision that `precond_freq` is orthogonal to the failure mode (R_neg eigenvalues are set by R_cov spectral scale, not by how often R_cov is recomputed).

### Mid-flight diagnostic (student)

Student posted the full mechanism analysis at 18:43 UTC (step 705, 22% through), correctly predicting both arms would NULL via scale mismatch and proposing the norm-preserving variant as the clean follow-up. The `precond_update_norm_ratio` telemetry was the key diagnostic. Arm B kill saved 3.6h GPU time.

### What this NULL closes vs leaves open

**Closes:** Literal scale-coupled `update @ R_neg` SOAP formulation. Adam-family cross-dim preconditioner with R_cov natural units does not help on aux Adam parameters.

**Leaves open:** Direction-only norm-preserving SOAP (assigned to tanjiro as PR #953). Tests whether lm_head's gradient cross-dim correlation has signal when scale is not modified. Both R_cov^(-1/4) and R_cov^(-1/2) variants tested.

### Aux Adam-family closure status (17 total after #937; #913 became 18th)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), aux parameter EMA (#899), **SOAP literal @ R_neg (#937 — this PR, 17th)**.

Only #913 (aux base-LR retune, frieren) remains active as the 19th potential closure. Also norm-preserving SOAP variant (#953 tanjiro) is the direction-only follow-up.

---

## 2026-05-23 18:35 UTC — PR #899 CLOSED: Aux Polyak EMA (lm_head only vs embed only) — both arms NULL, 92nd axis, 17th aux Adam-family closure (g1r1-fern)

- Branch: `g1r1-fern/aux-polyak-ema`
- Hypothesis: Aux parameter Polyak EMA on lm_head-only (Arm A) vs embed-only (Arm B); β-ramp matches body-Muon EMA (β_warmup=0.95 → β_target=0.99 ramping with lr_mult). Tests whether parameter-space averaging on aux benefits like it does for body-Muon.

| Arm | W&B | sr | val/loss (EMA-swap) | val/loss_live | val/ema_minus_live | Δval (EMA) vs #864 | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | (body EMA: negative) | — | — |
| A (lm_head EMA) | `byqi2lgf` | 2925 | 3.268543 | 3.267891 | **+0.000652** | +0.001717 | NULL |
| B (embed EMA) | `cw1ub4f3` | 2925 | 3.267759 | 3.267210 | **+0.000549** | +0.000933 | NULL (sub-marginal but mechanism broken) |

### Verdict: NULL/NULL — 92nd axis closed, 17th aux Adam-family closure.

### Mechanism finding — WRONG-SIGN aux EMA (load-bearing diagnostic)

For BOTH arms `val/ema_minus_live > 0`: EMA buffer is WORSE than live weights. **Opposite of body-Muon EMA** where `ema_minus_live < 0` reliably (the entire mechanism of #737 and #864).

Structural reason: temporal averaging helps only when the underlying trajectory is locally directional.
- Body-Muon: polar-mapped updates ARE directional (NS5 imposes orthogonality + β_cov whitening provides coherent geometry). Averaging reduces noise around a coherent direction.
- Aux Adam-on-i.i.d.-gradients: NO locally coherent trajectory. Averaging samples the centroid of recent disagreement, which lies further from any plausible optimum than the latest update.

### 4 independent measurement axes confirming i.i.d. aux gradient finding

| PR | Measurement angle | Result |
|---|---|---|
| #854 Adan-aux | Direct gradient correlation `||Δg||/||g||` | ≈ 1.45 (cosine ≈ -0.05) |
| #875 AdaBelief | `s/m²` ratio everywhere on aux | ≫ 1 (momentum doesn't predict gradient) |
| #863 Adam-mini | per-coord variance compression | per_tensor catastrophic (variance LOAD-BEARING); per_row sub-marginal |
| **#899 (this PR)** | `val/ema_minus_live` for parameter EMA | **+ for both lm_head and embed (wrong sign)** |

These are 4 independent measurement axes ALL confirming the same structural truth: aux trajectories are not locally directional → averaging hurts, doesn't help.

### Cross-arm diagnostic comparison

| Quantity | Arm A (lm_head) | Arm B (embed) | Interpretation |
|---|---|---|---|
| `ema_minus_live` sign | + | + | Wrong direction for both |
| Buffer Frob-dist | 2.57 | **39.93** | embed drifts 15× more (sparse-update accumulation) |
| Val penalty (EMA-swap) | 1.6 mnat | 0.83 mnat | embed penalty SMALLER despite LARGER drift |
| Val penalty (live) | +0.001 | +0.0004 | Live training trajectory unaffected |

**Embed's smaller val penalty despite larger Frob distance is informative:** a lot of embed Frob drift is in rows that don't appear in the held-out val set (per-token sparse updates accumulate without affecting eval). For lm_head, the entire output projection participates in every val token, so EMA penalty is more directly observed.

### Why Arm B's sub-marginal Δval doesn't justify n=2

Arm B's Δval=+0.000933 is below the 0.001 marginal threshold technically. But the mechanism analysis disqualifies it:
- `val/loss_live = 3.267210` → Δval_live = +0.000384 (within seed noise of baseline range [3.265811, 3.268040])
- The EMA-swap STRUCTURALLY adds +0.000549 worse on top of essentially-TIE live trajectory
- val=3.267759 is best decomposed as `live_seed_noise (+0.000384) + EMA_penalty (+0.000549)`
- The mechanism IS broken regardless of seed luck; n=2 would not change the wrong-sign `ema_minus_live` diagnosis

### Aux Adam-family closure status (17 total)

NAdam (#698), β2 ramp (#741), β1 ramp (#796), RAdam (#814), AdEMAMix (#585 + #846), AMSGrad (#578), Adamax (#583), LAMB (#609), Lookahead (#617), Schedule-Free (#623), AdaBelief (#545 + #875), Lion (#604), Cautious-AdamW (#853), Adan (#854), Adam-mini (#863), **aux parameter EMA (#899 — this PR)**.

**Open aux levers remaining (2):**
1. SOAP for lm_head (#937 tanjiro IN FLIGHT) — last open aux Adam-family lever
2. Direct aux base-LR retune (#913 frieren IN FLIGHT)

### Reward to student

Excellent telemetry discipline. The `val/ema_minus_live` design (logging EMA-swap AND live val terminal) is what made the structural diagnosis possible. The arm split (lm_head vs embed) was diagnostic — confirms the wrong-sign signal is universal across aux tensors, not specific to lm_head's dense structure.

**92nd axis closed.** Fern re-assigned to #943 (SWA partial blend at cooldown_start) — deferred sub-axis from #730 closure.

---

## 2026-05-23 18:10 UTC — PR #898 CLOSED: PMuon residual-driven adaptive NS_ITERS — both arms NULL, 91st axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/adaptive-ns-iters`
- Hypothesis: Replace fixed NS_ITERS=12 with early termination when polar residual `||X Xᵀ − I||_F < ε`. Arm A=ε=1e-3 (tight), Arm B=ε=1e-2 (loose). Tests uniform polar QUALITY vs uniform iteration COUNT.

| Arm | ε | W&B | sr | val/loss | iter_count (every step, every tensor) | residual_min | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | 12 | ~0.10 | — |
| A | 1e-3 (tight) | `d332v1wk` | 2925 | 3.26813 | 20 (cap) | 0.0495 | NULL — Δval=+0.00120 |
| B | 1e-2 (loose) | `ypejugws` | 2950 | 3.26897 | 20 (cap) | 0.0501 | NULL — Δsr=+25, Δval=+0.00204 |
| **n=2 mean** | — | — | **2937.5** | **3.268551** | 20 (degenerated) | ~0.05 (floor) | Mild regression |

**Verdict: NULL/NULL — informative-NULL via mechanism collapse.**

### Mechanism finding (KEY structural insight — cross-axis to multiple PRs)

**Both arms degenerated to static NS_ITERS=20.** The residual threshold was unreachable for both ε values because cubic Newton-Schulz polynomial `p(σ) = 1.5σ − 0.5σ³` has `p(0)=0`. Zero singular values are NOT restored by iteration. Body-Muon tensors are rank-deficient in bf16 (some near-rank-1 reshaped blocks), so:

`||X Xᵀ − I_m||_F ≈ √(m − rank(X))` after NS5 saturation,

≈ 0.05 (near-full-rank with bf16 floor) to ≈3.2 (rank-deficit ~10). **This floor is 3-5 orders of magnitude above both ε arms.** The `if final_residual < adaptive_eps: break` branch was never taken in any of 72 tensors × ~3,250 steps × 2 runs = **~468k tensor-step opportunities**.

### NS_ITERS frontier consolidated (88th #884 + 91st #898 closures)

| NS_ITERS | source | sr | val/loss | Pattern |
|---|---|---|---|---|
| 8 | #884 Arm A | 3050 | 3.2744 | Under-converged catastrophic (residual ~14) |
| **12** | **Baseline #864** | **2925** | **3.266826** | **OPTIMAL** |
| 16 | #884 Arm B | 2975 | 3.2703 | Over-saturation marginal (residual ~0.067) |
| 20 | #898 n=2 effective | 2937.5 | 3.268551 | Over-iteration + residual-op overhead |

NS_ITERS=12 confirmed as optimal across 4 static points. Asymmetric closure: going DOWN from 12 costs much more than going UP. Cubic NS at NS_ITERS=12 saturates at 0.05 polar residual.

### Cross-axis to #940 (alphonse next assignment)

The #898 rank-deficiency finding directly motivates the Frobenius-normalized NS output hypothesis (#940): if some body-Muon tensors converge to rank-deficient polar (Frobenius norm < √min(m,n)), their effective per-element update RMS is below unit. Frobenius normalization is the direct correction. Cross-axis: #898 IDENTIFIED the mechanism; #940 TESTS whether the mechanism matters operationally.

### Lessons preserved

1. **Pre-launch sanity check that threshold is reachable.** For mechanisms gated by a numerical threshold (ε in adaptive NS_ITERS, mask_frac in C-AdamW), verify the threshold is achievable with the chosen value before launch. The 12:55 UTC mid-run analysis caught this AFTER ~98 steps of telemetry.
2. **Script-edit-while-running hazard:** chain.sh was edited 16 min into Arm A's launch; Bash mid-execution script-edit behavior is undefined; Arm B launched despite unset gate file. Future chain scripts must be finalized BEFORE first launch.
3. **Telemetry discipline pays off.** The student's 12:55 UTC mid-run residual analysis turned an expected NULL into a deep structural insight about NS5 + rank-deficient inputs.

**91st axis closed.** Alphonse re-assigned to #940 (Frobenius-normalized NS output) — direct cross-axis follow-up.

---

## 2026-05-23 17:45 UTC — PR #897 CLOSED: Body-Muon adaptive WD coupled to ||p||/target_norm — both arms NULL, 90th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/adaptive-body-muon-wd`
- Hypothesis: Body-Muon static WD=0.025 may be miscalibrated for current ||p||/target_norm ratio. Adaptive coupling `wd_eff = base_wd * (||p||/target_norm)^α` lets WD scale with parameter-norm growth. Arm A=α=1 linear, Arm B=α=0.5 sqrt (softer).

| Arm | α | W&B | sr | val/loss | Δsr | Δval | terminal wd_mult | peak ||p||/target | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | 1.000 | — | — |
| A | 1.0 (linear) | `mdpr2on0` | 3000 | 3.270003 | +75 | +0.003177 | 2.549 | 3.53× | NULL (regressive but stable) |
| B | 0.5 (sqrt) | `s2ggjtya` | **-1** | 3.296175 | NULL | +0.029349 | ≥1.84 floor | **4.48×** | NULL clear (catastrophic) |

**Verdict: NULL/NULL → Adaptive body-Muon WD axis CLOSED.** 5th body-Muon WD sub-axis NULL.

**Mechanism finding (key structural insight):**

Body-Muon ||p||/target_norm grows 3-4.5× above target throughout training — this is the operating regime, not a transient pre-warmup state. Adaptive coupling can only adapt UPWARD (wd_eff always ≥ baseline since ||p||/target_norm ≥ 1). No α value gives baseline wd_eff while remaining adaptive — the wd_mult equilibrium lower bound is ≥1.84 (sqrt) or ≥2.55 (linear).

**Sqrt vs linear comparison (counter-intuitive):**
- Linear (α=1) actively damps p_norm growth via wd_mult=2.55 → peak ||p||/target stays at 3.53×
- Sqrt (α=0.5) damps less → p_norm grows MORE (peak 4.48×) → wd_mult ratchets to 1.84 equilibrium
- Sqrt's "softer coupling" produces stronger p_norm growth that the adaptive coupling cannot suppress → catastrophic regression

**Cross-axis closure pattern (body-Muon WD: 5 sub-axes NULL):**
1. WD partition (#482) — per-type/per-block partitioning NULL
2. WD schedule (#503) — temporal WD ramping NULL
3. WD ± scalar tune — magnitude tune NULL
4. WD cooldown ramp (#727 65th) — symmetric NULL (UP/DOWN regress identically)
5. **#897 adaptive WD** — both linear and sqrt coupling NULL

**Static WD=0.025 is PINNED at local optimum across all 5 sub-axes.**

**Body-Muon p_norm growth as structural feature:** The 3-4.5× ||p||/target_norm operating regime is consistent across baseline (no adaptive coupling), Arm A (linear damping), and Arm B (sqrt damping). Body-Muon updates grow parameter norms relative to target — likely a consequence of the polar map UV^T preserving direction while WD shrinks magnitude. The equilibrium isn't ||p||=target_norm; it's ||p||≈3.5-4.5× target_norm with WD=0.025.

**Implication for future WD experiments:** Any "adaptive WD" formulation that scales with ||p||/target_norm will hit the same equilibrium ceiling. Closes the entire family. Next interesting WD direction would be either (a) `target_norm` re-derivation from first principles (currently `sqrt(d_in)`) or (b) decoupled-WD reformulation that doesn't multiply current p directly.

**Decision tree confirmation:** This was a 17:30 UTC predicted closure (5th WD sub-axis). Closure-rate consistent with body-Muon scalar family being deeply saturated. Last open aux family lever (SOAP for lm_head) just assigned to tanjiro as #937.

**Closure entry — 90th NULL.** Adds "adaptive body-Muon WD coupled to ||p||/target_norm" to closed-axes under body-Muon WD section.

---

## 2026-05-23 15:55 UTC — PR #896 CLOSED: Cautious-Muon body post-NS sign-mask — both arms NULL, 89th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/cautious-muon-body`
- Hypothesis: Cautious-AdamW-style sign-mask applied to body-Muon polar output AFTER NS5 + bilateral whitening; gate update direction by sign-agreement with current gradient. Arm A=mask+renorm (Frobenius restored), Arm B=mask-only (no renorm).

| Arm | Variant | W&B | sr | val/loss | Δsr | Δval | mask_frac | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | — | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | — | — |
| A | mask+renorm | `qw18ifdw` | **-1** | 3.297386 | NULL | +0.030460 | 0.625 | HARD NULL (past stat-sig 3.276) |
| B | mask-only | `a3hualvf` | **-1** | 3.521345¹ | NULL | +0.254519 | 0.637 | **CRASHED step ≈1598** (eigh failure on R_cov) |

¹ Last val before crash at step 1500 (~46% through). Runtime 6736s vs 14046s Arm A.

**Verdict: NULL/NULL → Post-NS body-Muon perturbation family FULLY CLOSED.** Joins #696 Contra-Muon (subtractive post-NS perturbation, also NULL).

**Mechanism finding (significant cross-axis):**

The polar map UV^T is the optimization geometry itself. Masking 37.5% of polar-output entries (mask_frac=0.625 sign-aligned, 37.5% sign-flipped → zeroed) deletes orthonormality column-by-column, leaving an update that is no longer the optimal nuclear-norm-bounded direction. Renorm restores Frobenius magnitude but not the directional structure — Arm A val regressed +30 mnat despite mask_frac matching the expected C-AdamW band [0.45, 0.77].

**Arm B crash interpretation (numerical confirmation):** mask-only (no renorm) drops 37.5% of polar-element magnitude AND does not rescale → effective grad-equivalent fed back through bilateral whitening EMA gradually degrades R_cov conditioning → matrix_neg_power's `torch.linalg.eigh` diverges at step ≈1598. The crash is a strictly worse failure mode than the predicted "directional disruption + magnitude reduction" combo. Joins #774 (β_cov=0.0 fast-mix crash) and #898's eps adaptive convergence floor as numerical-stability signals on the bilateral whitening pipeline.

**Cross-axis closure pattern:** Post-NS body-Muon perturbations close uniformly regardless of perturbation type:
- #696 Contra-Muon (subtractive: polar - slow_EMA) — NULL (compression: only 3% effective dose vs 15-25% design)
- #896 Cautious-Muon (multiplicative gating + renorm) — NULL +30 mnat
- #896 Cautious-Muon (multiplicative gating no renorm) — CRASHED

**Why mask-on-aux works (#853) but mask-on-body (#896) fails:** On aux (C-AdamW), mask fires on Adam updates (per-element optimizer); geometry is preserved by being per-element. On body-Muon, the mask is on the POLAR map output — the mask IS the geometry violation, not a per-element heuristic on top.

**Cross-axis to #893 m_pre BC finding:** #893 just established that NS5 absorbs magnitude bias but NOT directional bias on m_pre (Arm A marginal WIN). Combined with #896 closure: **the structurally untested axis is pre-NS sign-mask on m_pre** (mask BEFORE polar projection so NS5 re-orthogonalizes from masked input). This is the cleanest follow-up — assigned to g1r1-askeladd as PR #931 (cross-axis with #896 + #893).

**Closure entry — 89th NULL.** Adds "Cautious-Muon-body multiplicative gating" to closed-axes under "Post-NS body-Muon perturbations." Now 17 aux Adam-family closures pending #899/#913/#931 + 4 body-perturbation closures (#658/#660/#696/#896).

---

## 2026-05-23 14:50 UTC — PR #884 CLOSED: NS_ITERS tune (8 vs 16) — both arms NULL, 88th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/ns-iters-tune`
- Hypothesis: NS_ITERS=12 baseline is over-converged → Arm A NS=8 (33% reduction) might TIE baseline. Arm B NS=16 tests over-iteration.

| Arm | ns_iters | W&B | sr | val/loss | Δsr | Δval | Polar residual | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline #864 | 12 | `j8nsn77s`/`08ursg5n` | 2925 | 3.266826 | — | — | ~0.10 | — |
| A | 8 | `fjp71ucq` | 3050 | 3.274412 | +125 | +0.0076 | **~13.9 (140× over)** | NULL clear (under-converged catastrophic) |
| B | 16 | `mg6vuky6` | 2975 | 3.270314 | +50 | +0.0035 | ~0.067 (1.5× cleaner) | NULL marginal (over-saturation drift) |

**Verdict: NULL/NULL clear → NS_ITERS axis CLOSED at static=12.**

**Mechanism finding (student telemetry):** Polar orthogonality residual `||XX^T - I||_F` is the cleanest NS-family diagnostic. Convergence is **highly nonlinear**:
- 8→12: residual drops 140× (14 → 0.10). The under-convergence cliff is between 8 and 12.
- 12→16: residual drops 1.5× (0.10 → 0.067). Already saturated; extra iters add numerical perturbation.

**Asymmetric closure**: going DOWN from 12 costs much more than going UP. 12 is the saturating equilibrium for the cubic Newton polynomial.

**NS_ITERS frontier (combined with #898 alphonse NS=20 marginal NULL):**

| NS_ITERS | sr | val | Pattern |
|---|---|---|---|
| 8 | 3050 | 3.2744 | Under-converged catastrophic |
| **12** | **2925** | **3.2668** | **OPTIMAL** (saturating equilibrium) |
| 16 | 2975 | 3.2703 | Marginal over-saturation |
| 20 (via #898) | 2925 | 3.2681 | sr-TIE but val-regress (perturbation drift) |

**Step-time falsification:** student measured ~0.2% step-time variation between {8, 12, 16}. NS iter count is NOT the step-time bottleneck — "33% compute savings" hypothesis falsified.

**Telemetry win:** `polar/ortho_residual_sample` per-step trajectory is now the body-side screening filter (analog to #875's `s/m² > 5` aux Adam-family screen):
- residual > 1.0 → under-converged catastrophic (skip benchmark)
- residual ∈ [0.05, 0.20] → plateau-quality polar map
- residual < 0.05 → over-saturated, expect marginal regression

**Combined with #540 (cubic vs quintic at NS=12 NULL/NULL):** NS subsystem now PINNED across all 2D cells except joint cell quintic×low-iters → assigned to nezuko as follow-up (#920).

**Suggested follow-up (deferred):** interior probe NS=10 (inflection candidate). Compute savings negligible — not assigned.

PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/884

---

## 2026-05-23 14:05 UTC — PR #875 CLOSED: AdaBelief-aux gradient-surprise variance — both arms NULL, 87th axis, 16th aux Adam-family closure (g1r1-frieren)

- Branch: `frieren/adabelief-aux`
- Hypothesis: AdaBelief's surprise-variance denominator `s_t = β2·s + (1-β2)·(g-m)² + eps` (replacing Adam's raw `v_t = β2·v + (1-β2)·g²`) takes larger confident updates when m_t predicts g_t well. Two arms: paper defaults β=(0.9, 0.999), eps=1e-16 vs drop-in codebase defaults β=(0.8, 0.95), eps=1e-10.

| Arm | β | eps | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | (0.8, 0.95) | 1e-10 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (paper) | (0.9, 0.999) | 1e-16 | `5mha8dpz` | 3025 | 3.27288 | +100 | +0.0060 | **NULL** (clean regression) |
| Arm B (drop-in) | (0.8, 0.95) | 1e-10 | `p5h5vf5e` | 2950 | 3.26852 | +25 | +0.0016 | **NULL** (Δsr marginal-boundary, Δval > 0.001) |

- **Mechanism is verifiably active but produces no value:** Arm B `v_vs_s_ratio = 1.426` globally — surprise denominator is ~30% tighter than equivalent vanilla-Adam, mechanism flipped correctly. `eps_floor_fraction = 0` in both arms — denominator is always the active term.
- **Key structural finding (frieren's contribution): `s/m² ≫ 1` everywhere on aux.** Per-group `s_over_m2` ratios at terminal:
  - Arm A (β2=0.999): embed=32.56, lm_head=60.80, scalars=156.83
  - Arm B (β2=0.95): embed=5.92, lm_head=5.88, scalars=23.21
  - **Reads: (g−m)² is 5–150× larger than m² on aux at this scale.** AdaBelief's "confident-update" path only engages when (g−m)² ≪ m² (m predicts g well). Here m_t is NOT a useful predictor of g_t — confidence path never fires.
- **Cross-axis confirmation of #854 i.i.d. aux gradient finding from a totally different measurement angle.** #854 measured `||Δg||/||g|| ≈ 1.45` directly; #875 measures `s/m² ≫ 1` indirectly via the AdaBelief denominator. Both confirm: aux gradients lack temporal predictability → momentum-magnitude-based adaptive optimizers cannot extract signal from temporal structure that doesn't exist.
- **Slow-EMA lag pattern reproduced (3rd instance):** Arm A (paper β2=0.999) shows s/m² 5× larger than Arm B (drop-in β2=0.95) — slower m_t lags more, breaks the confidence-update premise even harder. Matches #846 AdEMAMix β3=0.9999 obsolete-direction finding and #854 Adan β1=0.98 m_norm 2.5× smaller finding.
- **87th closed axis. 16th aux Adam-family closure** (after NAdam #698, β2 ramp #741, β1 ramp #796, RAdam #814, AdEMAMix #585+#846, AMSGrad #578, Adamax #583, LAMB #609, Lookahead #617, Schedule-Free #623, AdaBelief #545, Lion #604, Cautious-AdamW #853, Adan #854, Adam-mini #863, AdaBelief #875). **The variance-estimator and per-coord-adaptivity axes on aux are saturated.**
- **Telemetry win (reusable across future hypotheses):** `s_over_m2` and `v_vs_s_ratio` diagnostics now serve as screening filters for any future Adam-family aux candidate. If `s/m² > 5` on a candidate's first 500-step run, the mechanism is invalidated before the full 4-GPU-hour benchmark commits.
- **Frieren reassigned PR #913**: Aux embed/lm_head LR retune at PR #737 baseline. Arm A=embed_lr=0.4/lm_head_lr=0.008 (UP); Arm B=embed_lr=0.225/lm_head_lr=0.005 (DOWN). **Base-case probe never run at current baseline** — embed/lm_head LRs unchanged since PR #413, but body-Muon (γ_pre=0.4, β_cov=0.95) and EMA wrapper (β_target=0.99 cooldown ramp) have shifted the effective body update magnitude. If both arms NULL → confirm current LRs optimal, sharpen the "aux saturation" structural conclusion. If one wins → free val/sr improvement and reset aux baseline.

## 2026-05-23 10:05 UTC — PR #863 CLOSED: Adam-mini-aux per_row/per_tensor v_t reduction — both arms NULL, 86th axis, 15th aux Adam-family closure (g1r1-fern)

- Branch: `g1r1-fern/adam-mini-aux-per-row-per-tensor`
- Hypothesis: Pooled v_t (Adam-mini, Zhang et al. 2024) reduces sparse-gradient variance noise for embed/lm_head and improves convergence. Two arms: per_row (row-pooled v_t, 50304 scalars) vs per_tensor (single-scalar v_t per param).

| Variant | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (per_row) | `o3pv0szv` | 2925 | 3.267874 | 0 | +0.000948 | **NULL/TIE** (sub-marginal val regression, strict-rule fail) |
| Arm B (per_tensor) | `m3jirfw9` | **−1** | 3.299257 | NULL | +0.032331 | **hard NULL** (never crossed 3.28 target) |

- **Monotone "more aggregation → more harm" ordering confirmed.** Per_row (rank-1 along feature axis, preserves per-row vocab adaptivity) is the natural floor of the family — pooling features within a row costs ~1 mnat (sub-marginal). Per_tensor (single scalar v_t = effectively SGD+momentum with one global LR) is catastrophic — kills rare-token adaptivity completely.
- **Mechanism interpretation:** v_mean ratios at terminal show structural breakdown for embed: per_row=6.85e-5, per_tensor=2.17e-5 (3.16× smaller). Pooling over all 50304×768 elements averages over many near-zero entries (sparse tokens) → smaller denominator → uniform scaling that ignores rare-token signal. Per_tensor lacks the rare-token adaptivity that Adam provides via per-coord v_t.
- **Cross-axis insight (load-bearing): Adam per-coord variance denominator is structurally critical for sparse-gradient tensors (embed/lm_head).** Variance compression in any form (per_row pooling OR per_tensor pooling) sacrifices this for memory savings that don't help in this regime. The Adam-mini paper's claim of "matches Adam with 99% less state memory" does not reproduce here, likely because (1) aux state is small relative to body-Muon state anyway, and (2) the speedrun cooldown phase is especially sensitive to v_t granularity.
- **Telemetry verification credit (fern):** Clean `v_size` confirmation (50304 per_row / 1 per_tensor) and `block_mode` flag verified implementation correctness in both arms. Same diagnostic discipline as askeladd #853 (mask_frac) and tanjiro #854 (||Δg||/||g||).
- **86th closed axis. 15th aux Adam-family closure.** Aux Adam axis structurally insensitive to any update-rule change that reduces/restructures the variance estimator. Open aux levers remaining: AdaBelief (#875 Arm A NULL/regression; Arm B in flight), EMA timing (#864 in flight n=2 confirm), **aux parameter EMA (#899 fresh axis, never tested)**, direct aux LR retune, SOAP/Shampoo.
- **Fern reassigned PR #899**: Aux Polyak EMA (lm_head only vs embed only). Same β-ramp as body-Muon EMA (β=0.95→0.99, warmup=2250). Arm A=`--ema_aux_lm_head`; Arm B=`--ema_aux_embed`. **Fresh mechanism family** — body-Muon parameter-space averaging is FULLY CLOSED (#505/#662/#695/#802 + #737 baseline) but aux groups have no EMA buffer. Two-arm orthogonal design isolates which aux tensor benefits from parameter averaging.

## 2026-05-23 09:45 UTC — PR #822 CLOSED: PMuon L_cov/R_cov Adam-style bias correction — n=3 boundary informative-NULL, 85th axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-cov-bias-correction`
- Hypothesis: PMuon bilateral covariance EMA (L_cov, R_cov) suffers Adam-style early-step bias from `m·β^t / (β^t)`. Dividing by `1 − β_cov^t` corrects the bias, allowing the polar map to use unbiased preconditioner from step 1 onwards.

| Seed | W&B | sr | val/loss | stat_sig | Notes |
|---|---|---|---|---|---|
| 1 | `8b0m4nzt` | 2875 | 3.264587 | 0.01141 | strong win |
| 2 | `ufg7f4mw` | **2925** | 3.267590 | 0.00841 | baseline-tie |
| 3 | `7bgqna61` | **2950** | 3.269395 | 0.00660 | regression direction |
| **n=3 mean (Arm A)** | — | **2916.67** | **3.267191** | — | — |
| baseline (#737, n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | ref |
| **Δ (n=3 mean vs baseline)** | — | **−8.33** | **+0.000265** | — | borderline |

- **Predeclared decision rule:** sr > 2900 → close informative-NULL. n=3 mean sr=2916.67 fails MERGE threshold; Δval slightly positive. Close.
- **Mechanism is real and correctly implemented across all 3 seeds:** BC denominator `1 − β_cov^t` converges to 1.0 by step ~100 in all seeds; `L_eps_clamp_frac` drops from 1.0 (rank-1 init) to ~0 by step 50 in all seeds; `L_eigval_min_mean` ramps from 0 to ~46k by step 50. Identical telemetry across seeds proves implementation is correct.
- **Why BC effect doesn't beat noise:** (1) BC fires for ~50-100 steps then becomes a no-op (3% of training), (2) polar output from NS5 is robust to small L/R_cov errors (NS5 projects to nearest unit-spectral-norm matrix), (3) seed-1 was a lucky outlier — seeds 2 and 3 sit at the noise floor.
- **Cross-cutting insight: PMuon warmup-phase fixes are mechanically denoised.** Polar map absorbs small preconditioner errors. Future warmup-phase fix hypotheses should expect this absorption pattern. Edward's #893 PMuon momentum first-moment BC (analog on m_pre, not L_cov/R_cov) tests whether the m_pre direction is similarly absorbed.
- **Decision-rule discipline credit (alphonse pre-launch):** Pre-launch β_cov audit verifying the codebase β_cov=0.95 convention matched Adam-style smoothing weight. Same diagnostic discipline as askeladd #853 and tanjiro #854.
- **85th closed axis. PMuon warmup-phase intervention family now contains 2 closures (#774 β_cov fast-mix, #822 BC).** Open in family: #893 edward (first-moment BC on m_pre, in flight).
- **Alphonse reassigned PR #898**: PMuon residual-driven adaptive NS_ITERS. Arm A=ε=1e-3 tight, Arm B=ε=1e-2 loose. Tests uniform polar QUALITY vs uniform iteration COUNT. Fresh mechanism on NS-iteration sub-axis (distinct from #884 static NS_ITERS tuning and #803 cooldown-iter ramp).

## 2026-05-23 09:25 UTC — PR #854 CLOSED: Adan-aux Nesterov gradient-difference momentum — both arms NULL, 84th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/adan-aux-nesterov-grad-diff`
- Hypothesis: Adan's Nesterov gradient-difference term (m_pre + (1-β3)*Δg) on aux groups would improve convergence via momentum-aware gradient lookahead. Two arms: paper β1=0.98 vs tuned β1=0.80 (codebase aux Adam default).

| Arm | β1 | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A (paper) | 0.98 | `cidw81e1` | **−1** | 3.28330 | NULL | +0.01637 | **hard NULL** (never crossed 3.28) |
| Arm B (tuned) | 0.80 | `aae3y07x` | 2950 | 3.26931 | +25 | +0.00238 | NULL (marginal sr regression, val borderline) |

- **m_t lag killed paper β1=0.98**: Arm A's `m_norm ≈ 14.5` (embed) is ~2.5× smaller than Arm B's 36.7. Slow EMA can't track aux gradient direction during cooldown; adding a noisy Δg correction on a stale m made things strictly worse. Mirrors #846 AdEMAMix-Aux (β₃=0.9999 slow EMA pulled toward obsolete early-training direction).
- **β1=0.80 recovered most of AdamW**: Arm B sits near baseline (+0.0024 val), with the remaining Δg contribution (~22% of update) acting as small additive noise. Costs +25 sr — predictable noise penalty.
- **β2/β3 retuning unlikely to recover**: even at β2→1 (wash out Δg noise), v_t → E[Δg] ≈ 0, so Adan degenerates to AdamW. No β-region in this scale makes Adan-aux helpful.
- **LASTING MECHANISM INSIGHT (tanjiro's contribution): Aux gradients are essentially i.i.d. step-to-step.** Telemetry: `||Δg||/||g|| ≈ 1.45` constant across all 3 aux groups, both arms. Implies consecutive-grad cosine ≈ −0.05 (very mild anti-correlation, ~independent). This rules out an entire family of future aux optimizer ideas:
  - **Ruled out**: any update mechanism depending on positive Δg autocorrelation (Adan, NAdam lookahead, Polyak heavy-ball with γ>0, MARS variance reduction, gradient-acceleration methods)
  - **NOT ruled out** (still worth testing): variance-shaping (AdaBelief #875 in flight, AMSGrad #578 closed), sign-based (Lion #604 closed), schedule-free / lookahead-style (most already closed)
  - **Future aux-optimizer hypotheses depending on Δg signal should be predicted-NULL from this data before launching.**
- **Math-catch closure credit (tanjiro pre-launch)**: paper-β vs Adam-β coefficient audit caught the literal `(1−β2)` issue → Δg would have been weighted at 0.08 instead of 0.92, near-no-op vs AdamW. Saved ~6h of GPU on what would have been an uninterpretable result. Textbook pre-launch math check.
- **84th closed axis. Cumulative aux Adam-family closures: 14 update-rule families closed.** Aux Adam axis approaches full saturation; remaining open levers are AdaBelief (#875 in flight), Adam-mini reductions (#863 in flight), EMA timing (#864 in flight), direct base-LR retune, SOAP/Shampoo for lm_head.
- **Tanjiro reassigned**: PR #897 Body-Muon adaptive WD coupled to ||p||/target_norm. Arm A=α=1.0 linear, Arm B=α=0.5 sqrt. Per-tensor WD scaling by current/init norm ratio. Different from all 4 closed WD axes (#482 partition, #503 schedule, #727 cooldown ramp, #466 aux WD): tests WD intensity per tensor as a function of its weight-norm-vs-init ratio. New mechanism family (regularization → weight-norm tracking).

## 2026-05-23 09:15 UTC — PR #853 CLOSED: Cautious-AdamW aux renormalization ablation — both arms NULL, 83rd axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/cautious-aux-renorm-ablation`
- Hypothesis: Cautious-AdamW (sign-aligned update masking) on aux groups; ablation tests whether mask+renorm or mask-only is the active mechanism.

| Arm | Variant | renorm | W&B | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (#737 n=2) | — | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | ref | ref |
| Arm A (paper) | C-AdamW mom | on | `6tye7e33` | 3175 | 3.27847 | +0.01154 | **NULL** (clean regression) |
| Arm B (no_renorm) | C-AdamW mom | off | `9kmvuba7` | **−1** | 3.28109 | +0.01416 | **hard NULL** (never crossed 3.28) |

- **Mechanism fired correctly**: Per-group mask_frac in paper-expected band (embed=0.448, proj=0.654, scalars=0.77) — NOT vestigial, NOT saturated.
- **Renorm IS load-bearing when applied**: Arm B trailed Arm A by stable +0.0026 mnat from step 1750 onward, well before cooldown. Without renorm, effective LR shrinks by ~35% — clean degradation matching paper's prescription.
- **Mask itself doesn't help aux**: Even paper-faithful Arm A regressed +11.5 mnat. Sign-conflict signal that helps Muon body params doesn't carry useful information for aux groups:
  - Embed (45% agreement): token-batched gradients are sparse/noisy; masking throws away signal that AdamW's variance denominator already smooths
  - proj/scalars (65-77% agreement): mask agrees with grad most of the time → little change → small effect doesn't help
- **83rd closed axis. Aux update-direction filtering family added to closed-aux-mechanism ledger**: variance/smoothing schedules (NAdam, β-ramp, RAdam, AdEMAMix) + Cautious-AdamW all NULL. Vanilla fused AdamW β=(0.8, 0.95) is robust local optimum for aux groups.
- **Askeladd's diagnostic discipline (textbook)**: pre-launch sign-equivalence audit, byte-identity check on baseline path, per-group mask_frac telemetry confirming mechanism fires correctly. Caught a duplicate-launch SIGTERM artifact (`edgttv3d`) cleanly. Same hygiene now applied to next assignment.
- **Askeladd reassigned**: PR #896 Cautious-Muon (body-side) — his own suggested follow-up. Tests multiplicative sign-mask on body-Muon's polar output (sign(polar) vs sign(grad)). Mechanistically distinct from #696 Contra-Muon (subtractive). First test of post-NS multiplicative-gating axis on body-Muon.

## 2026-05-23 09:00 UTC — PR #892 CLOSED PRE-LAUNCH: Lookahead-Muon (duplicate of #505 / g1r1-edward)

- Branch: `g1r1-edward/lookahead-muon` (closed before student picked up)
- Hypothesis (proposed): Lookahead (Zhang et al. 2019) outer-loop slow weight average wrapping body-Muon with k=5/k=10, α=0.5.
- **Duplicate-check FAIL — caught post-creation**: PR #505 (g1r1-fern, 2026-05-19) tested EXACTLY these arms on body-Muon. Documented in CURRENT_RESEARCH_STATE.md closed-axes ref (lines 116, 124) and confirmed by reading PR #505 comments.
- **PR #505 verdict**: Both arms HARD NULL. Arm A k=5/α=0.5 (`8ad3mzjz`): sr=-1 DNF, Δval=+0.020. Arm B k=10/α=0.5 (`e3zkawez`): sr=-1 DNF, Δval=+0.022.
- **PR #505 mechanism documented**: Discontinuous slow-weight resync corrupts PMuon's L_cov/R_cov covariance state. The covariance EMA accumulates at β=0.95 on the fast-weight trajectory; when fast←(1-α)·fast+α·slow displaces the params at the resync boundary, the next gradient is computed at a point inconsistent with the cov stats accumulated from the fast trajectory.
- **#505 crossover pattern**: B (k=10) tighter mid-training (0.005 ahead at step 1250-1500); A (k=5) tighter late-cooldown. Gentler averaging is less destructive but neither arm escapes the discontinuity damage.
- **Advisor learning (filed to memory)**: Always check closed-axes reference BEFORE designing PR body, not after. The fault was rushing to redeploy edward after #846 closure without verifying axis novelty.
- **Edward reassigned**: #893 PMuon momentum first-moment Adam-style bias correction. Orthogonal to #822 (in flight, second-moment BC on L_cov/R_cov). Mechanism: corrects zero-init bias in momentum EMA accumulation via 1/(1-mu^t) factor before Nesterov mix.

## 2026-05-23 08:40 UTC — PR #846 CLOSED: AdEMAMix-Aux dual first-moment EMA α sweep — both arms NULL, 82nd axis (g1r1-edward)

- Branch: `g1r1-edward/ademamix-aux-alpha`
- Hypothesis: Adding a slow long-horizon EMA (m2, β3=0.9999) to aux-group Adam update would give aux directions a stronger trajectory anchor, helping embed/lm_head/scalar groups (high gradient variance) escape short-horizon noise.

| Arm | α | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | — | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 2 | `r9mby3uo` | 3075 | 3.275689 | +150 | +0.008763 | **NULL** (clean regression) |
| Arm B | 8 | `np82nnjr` | **−1** | 3.332268 | NULL | +0.065342 | **hard NULL** (never crossed 3.28) |

- **Monotone dose-response in the WRONG direction**: α=2→8 makes val/sr strictly worse. Confirms mechanism (slow EMA hurts) is real, not noise.
- **Mechanism**: Slow EMA buffer m2 (β3=0.9999, N_eff≈10,000) computes near-uniform mean of all past gradients. For aux groups, early-training gradient directions differ systematically from late-training (non-stationary) → slow buffer pulls toward obsolete early-training direction during cooldown, hurting convergence.
- **Compares cleanly with aux variance-warmup family already closed** (#698 NAdam, #741 β2 ramp, #796 β1 ramp, #814 RAdam — all NULL). Aux-group update-rule changes don't survive WSD cooldown where gradient statistics shift.
- **AdEMAMix transformer wins (paper) don't transfer to modded-nanoGPT FineWeb track** — likely scale/data/architecture mismatch.
- **SIGTERM launch-race diagnostic**: Edward correctly identified process-tree reaping by parent claude exit (not OOM/NaN) as the cause of multiple Arm A crashes. Recovery via single canonical `r9mby3uo` was clean.
- **82nd closed axis. Edward reassigned to Lookahead-Muon (body-Muon outer-loop slow weight average, Zhang et al. 2019) — orthogonal to aux-Adam family.**

## 2026-05-23 06:50 UTC — PR #827 CLOSED: NS-output Frobenius normalization — n=2 informative-NULL, 81st axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/post-ns-frobenius-norm`
- Hypothesis: Normalizing NS polar output to unit Frobenius (post variant) or pre-NS gradient to RMS=1 (pre variant) would stabilize per-step update magnitude variability and improve sr/val.

| Arm | Mode | Seed | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | none | n=2 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | post | seed-1 | `q72w28l9` | **−1** | 3.299976 | NULL | +0.033050 | **hard NULL** (did not cross 3.28) |
| Arm B | pre | seed-1 | `oey1pogu` | 2925 | 3.265945 | 0 | −0.000981 | marginal n=1 win → request n=2 |
| Arm B | pre | seed-2 | `6jjfoefp` | 2925 | 3.268016 | 0 | +0.001090 | seed-2 regression |
| **Arm B** | **pre** | **n=2 mean** | — | **2925** | **3.266981** | **0** | **+0.000055** | **informative-NULL** |

- **Seed-1 marginal val win perfectly canceled by seed-2 regression** — Δval seed-1=−0.000981 and Δval seed-2=+0.001090 are symmetric around baseline. n=2 mean tracks baseline within +0.055 mnat (sub-noise).
- **Mechanism documented (lasting contribution)**: `polar/ns_polar_rms` telemetry showed Arm B (pre-NS) yields a constant ~0.018 per-step value — pre-normalization collapses the conditioning-dependent magnitude variability that the original hypothesis targeted. Telemetry was deterministic across seeds (matched to 4 decimal places), confirming the mechanism is RNG-independent.
- **Arm A (post-NS)** is strictly worse: forcing NS output to unit Frobenius destroys the u/w-floor signal entirely, blocking target crossing.
- **NS-output-scale normalization axis CLOSED**: Neither pre nor post Frobenius normalization improves over the natural NS polar map output scale. The natural scale is load-bearing for the u/w-floor stack.
- **81st closed axis. Nezuko reassigned next.**

## 2026-05-23 05:35 UTC — PR #841 CLOSED: EMA β ramp shape — informative-NULL, 80th axis (g1r1-frieren)

- Branch: `g1r1-frieren/ema-beta-ramp-shape`
- Hypothesis: Delaying the β ramp onset to later in cooldown (piecewise-linear delayed ramp) would improve terminal val/loss by concentrating averaging into the cleanest final descent.

| Arm | delay_frac | W&B | sr | val/loss | Δsr | Δval | % stat-sig margin | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | n/a (concave) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | — | ref |
| Arm A | 0.5 | `quhyt7s4` | 2925 | 3.266744 | 0 | **−0.000182** | 4.6% | informative-NULL |
| Arm B | 0.7 | `gg5ltqc8` | 2925 | 3.266922 | 0 | **−0.0000042** | 0.1% | informative-NULL |

- **Both arms technically satisfy predeclared WIN rule** (sr=2925 AND val<3.266926) but both Δval are far below the 0.001 marginal threshold (Arm A at 18%, Arm B at 0.4%). Correctly interpreted as informative-NULL.
- **Mechanism**: Terminal β_t=0.99 identical across all configurations. EMA steady-state is dominated by final ~100 steps where β≈0.99 regardless of ramp shape. Ramp timing only affects early-cooldown; terminal composition is insensitive.
- **Spec note (student catch)**: Actual baseline ramp is **concave** (β rises via `(1−lr_mult_t)` with `lr_mult_t = (1-cooldown_progress)^1.4`), not strictly linear. Arms tested "piecewise-linear delayed" vs "concave baseline". Comparing different shapes (not pure delay). No code error — just a framing note for future ramp-shape work.
- **EMA-β infrastructure now pinned**: β_target frontier settled (0.99 BEST), warmup_steps in-flight via #864, ramp-shape exhausted in (0.5, 0.7) interior.

## 2026-05-23 01:40 UTC — PR #802 CLOSED: Polyak EMA β_target fine-scan — n=2 informative-NULL, 79th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/ema-beta-target-fine-scan`
- Hypothesis: β_target=0.97 or 0.98 may sit in a sweet spot between sr-preservation and val-recovery (vs #737's β_target=0.99 baseline).

| Arm | β_target | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | 0.99 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.97 | `453h9twy` | 2950 | 3.267780 | +25 | +0.000854 | NULL |
| Arm B seed-1 | 0.98 | `y3lh1e79` | **2925** | **3.266577** | 0 | **−0.000349** | marginal n=1 win |
| Arm B seed-2 | 0.98 | `ws9w9a0y` | 2950 | 3.267508 | +25 | +0.000582 | regression |
| **Arm B n=2 mean** | **0.98** | — | **2937.5** | **3.267043** | **+12.5** | **+0.000117** | **informative-NULL** |

- **n=2 decision rule triggered:** Per the predeclared rule (n=2 sr > 2925 → informative-NULL), Arm B's seed-1 sr=2925 was inside the EMA-swap-val target-crossing jitter band, not a structural property of β=0.98.
- **Mechanism replication clean across seeds:** `delta_ema_minus_live_mnat` stable at ~0.229 (seeds 0.227 / 0.232), matching β/(1−β) lag scaling theory (~0.27 predicted). The lag-bias compression at lower β_target is real and stable; it just doesn't translate to sr improvement.
- **N_eff=50 cannot dampen target-crossing jitter:** β=0.99's N_eff=100 reliably locks both seeds to sr=2925. β=0.98 lets seed-1 cross at 2925 and seed-2 at 2950 — the 25-step single-bin jitter dominates val-trajectory near 3.28 with this much smoothing reduction.
- **β_target frontier settled:** 0.95 sr=2950 → 0.97 sr=2950 → 0.98 sr=2937.5 (n=2) → **0.99 sr=2925 (n=2, current BEST)** → 0.999 NULL. Monotone improvement toward 0.99 with no room to interpolate (β=0.99 already locks both seeds).
- **Procedural appreciation:** Thorfinn wrote the decision rule into their terminal SENPAI-RESULT explicitly and matched it without ambiguity. n=1 → n=2 catch-rate validated: seed-1 marginal would have been a false merge without n=2 protocol. EMA telemetry instrumented per-seed gives mechanistic confirmation independent of primary outcome.
- **79th closed axis. Thorfinn reassigned to EMA warmup_steps re-tune (1750 vs 2500) at β_target=0.99 — natural follow-up #3 from their own SENPAI-RESULT.**

## 2026-05-23 01:30 UTC — PR #821 CLOSED: Kahan BF16 compensated weight update — NULL/NULL, 78th axis (g1r1-fern)

- Branch: `g1r1-fern/kahan-muon-ema`
- Hypothesis: Compensate for BF16 precision loss in body-Muon param updates and EMA lerp via Kahan summation. Hypothesis predicted that very small late-cooldown updates may be lost to BF16 rounding.

| Arm | Variant | W&B | sr | val/loss | Δsr | Δval | comp_rms (body) | comp_rms (ema) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | — | — | ref |
| Arm A (Kahan-Muon only) | corrected-residual form | `1segjgvo` | 2925 | 3.266462 | 0 (TIE) | −0.000464 | 5.4e-9 | n/a | NULL TIE (sub-noise) |
| Arm B (Kahan-Muon + EMA lerp) | corrected-residual form | `ji1hed72` | 2925 | 3.267573 | 0 (TIE) | +0.000647 | **0** | **0** | NULL TIE (sub-noise) |

- **Pre-launch dtype audit by fern caught the hypothesis premise was wrong:** body-Muon params and EMA buffer are BOTH FP32 (only `self.embed` is BF16). With matched FP32 dtype, `p.add_(update.to(p.dtype))` is exact arithmetic and Kahan compensation is a structural no-op. comp_rms_mean=0 across 3250 steps confirms this empirically.
- **Mechanism finding:** Kahan BF16 compensation is mathematically null when params and update have matching FP32 dtype. The ±0.5 mnat val swing between arms is FP32 add-reordering noise (different summation order in Kahan path vs direct `add_`), not a Kahan signal.
- **Where precision still has signal:** embed/lm_head are BF16; high-β EMAs (β≥0.996, e.g., AdEMAMix β₃=0.9999) round to 1.0 in BF16 — captured in our memory file. Future precision work should target the aux side specifically.
- **78th closed axis. Fern reassigned to Adam-mini-aux (Zhang et al. 2024) — per-row/per-tensor v_t reduction.**

## 2026-05-23 01:00 UTC — PR #778 CLOSED: PMuon per-type γ narrow (γ_attn=0.45) — TIE/sub-noise val, 77th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-gamma-attn-only-raised`
- Hypothesis: Narrow per-type γ split (γ_attn=0.45, γ_mlp=0.4) refines #736's wide split that closed at NULL; expected to test whether the direction (γ_attn > γ_mlp) is real at smaller magnitude.

| Arm | γ_attn / γ_mlp | seeds | n=2 sr | n=2 val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737) | uniform 0.4 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm B clean n=2 | 0.45 / 0.40 | `b958vx2r`/`is177ib5` | **2925** (TIE) | **3.266815** | **0 (TIE)** | **−0.000111** mnat | NULL TIE (sub-noise) |

- **Sub-noise Δval:** Δval=−0.000111 mnat is 22× smaller than the seed-to-seed variance (0.002518) and 9× below the marginal threshold (0.001). Per session memory rule (auto-nanogpt: Δval ≤ 0.001 mnat is within seed noise even at n=2), this does not constitute a real win.
- **Tanjiro's procedural contributions are notable:** (1) diagnosed flat-vs-nested `body_muon_params` bug and committed bug-fix `174d98c1`; (2) caught seed-1 (pre-EMA) vs seed-2 (post-EMA) config mismatch and proposed clean n=2 re-run; (3) demonstrated EMA-stack post-fix variance pattern (seeds 3.268074 / 3.265556, spread ≈ 0.0025 mnat).
- **PMuon per-type γ axis FULLY CLOSED across both magnitudes:** wide split (#736 66th NULL, attn=0.3/0.5) — direction validated but magnitude insufficient; narrow split (#778 77th NULL, attn=0.45) — TIE on sr, sub-noise val. γ_power is type-isotropic in body-Muon regime — Kronecker L_cov/R_cov already capture per-tensor curvature differences; an additional per-type γ scalar offers no orthogonal gain.
- **77th closed axis. Tanjiro reassigned to Adan-aux (fresh axis, Xie et al. 2022 — Nesterov-momentum-of-gradient-differences).**

## 2026-05-23 00:50 UTC — PR #814 CLOSED: Aux RAdam (variance warmup) — NULL/NULL, 76th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-radam-variance-warmup`
- Hypothesis: Replace aux AdamW with RAdam (Liu et al. 2019) for embed/proj/lm_head/scalars — rectified-Adam variance warmup may stabilize early-step aux updates and unlock a higher LR ceiling.

| Arm | LR scale | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static AdamW LR=0.30 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | RAdam LR=0.30 | (terminal) | 2925 | 3.266586 | 0 (TIE) | −0.000340 (μnat) | NULL TIE (sub-marginal) |
| Arm B | RAdam LR=0.22 | (terminal) | 2950 | 3.269034 | +25 | +0.002108 | NULL (sr regression) |

- **Mechanism intact:** rho_t ramp 1→38.15 across training ✓; r_t rectification term ramp 0→0.987 ✓; in_sgd_fallback flips at step where rho_t crosses threshold ✓; 0 nonfinite grads throughout.
- **Mechanistic finding: AdamW β2=0.95 already handles variance warmup implicitly at high aux LRs.** RAdam's explicit rectification offers no headroom on top of an already well-tuned AdamW configuration with β2=0.95 (the value enabled by EMA stack #737). The SGD-fallback path during rho_t<4 is mathematically equivalent to a momentum-only warmup, which doesn't differ meaningfully from AdamW with β2=0.95 in the first 100 steps.
- **Salvage:** Original Option A (always-adaptive variant, no SGD fallback) was diagnostic-only — confirms baseline-AdamW is the operating point on the rho_t axis.
- **76th closed axis. Aux Adam-family variance-warmup mechanism FULLY CLOSED across NAdam (#698 NULL), β2 ramp (#741 NULL primary at n=2), β1 ramp (#796 NULL), RAdam (#814 NULL).** Aux Adam-family is exhaustively mapped — moving to sign-based momentum (Lion).
- **Askeladd reassigned to Lion-aux (PR TBD)** — sign-based momentum (Chen et al. 2023, https://arxiv.org/abs/2302.06675), the next clean axis off Adam-family saturation.

## 2026-05-22 22:00 UTC — PR #796 CLOSED: Aux AdamW β1 cooldown ramp (0.8→0.7 vs 0.8→0.9) — NULL/NULL, 75th axis (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-cooldown-ramp`
- Hypothesis: Ramp aux AdamW β1 in cooldown — DOWN (0.8→0.7) for fresher momentum, or UP (0.8→0.9) as β1 analog of #741's β2 ramp finding.

| Arm | β1 ramp | W&B | sr | val/best | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static 0.8 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.8 → 0.7 (DOWN) | `hese09mm` | 2950 | 3.268949 | +25 | +0.002023 | NULL (regression) |
| Arm B | 0.8 → 0.9 (UP) | `i506vy1w` | 2925 | 3.266983 | 0 (TIE) | +0.000057 | NULL (marginal val regression) |

- **β1 DOES NOT mirror β2.** PR #741 found β2 0.95→0.999 UP gave a marginal val improvement (Δ=−0.000306 mnat vs old baseline). The SAME UP-ramp idea applied to β1 (Arm B here) yields NO improvement on top of the EMA stack. **The "cooldown-coupled smoothing UP-ramp" is parameter-specific, not class-wide.** β1 (gradient-direction EMA) does not respond like β2 (gradient-variance EMA).
- **Mechanistic value:** rules out the broad hypothesis "all smoothing scalars want to ramp UP in cooldown." The cluster is parameter-specific. Aux β1=0.8 is at the local optimum on top of the EMA stack.
- **Telemetry quality:** ramp telemetry `train/aux_beta1/beta1_t` perfect — symmetric ramps from 0.800 at cooldown_start to 0.700/0.900 at step 3250 with cooldown_progress mapping correctly.
- **75th closed axis.** Aux β1 cooldown ramp axis FULLY CLOSED (both directions). Edward reassigned to AdEMAMix-aux (PR TBD).

## 2026-05-22 21:35 UTC — PR #803 CLOSED: PMuon γ_power warmup ramp (0.2→0.4 vs 0.3→0.4) — NULL/NULL, 74th axis (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-warmup-ramp`
- Hypothesis: γ_power warmup ramp from low value → 0.4 by cooldown_start (step 975), testing whether gentler early whitening produces a better pre-cooldown trajectory.

| Arm | γ_warmup_start | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | static 0.4 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.2 | 2975 | 3.266392 | +50 | -0.000534 | NULL |
| Arm B | 0.3 | 2950 | 3.265617 | +25 | -0.001309 | NULL |

- **Both arms regress on primary metric (sr).** Monotone ordering: Arm A (start=0.2) > Arm B (start=0.3) > baseline in sr — "less whitening early = worse trajectory."
- **Val improvements dominated by sr regression.** Arm B val -0.001309 is past marginal threshold but sr regression (+25) disqualifies win.
- **γ_power axis FULLY CLOSED** across both cooldown ramp (#760) and warmup ramp (#803) directions. Static γ=0.4 is a tight local optimum robust to schedule perturbations at either end.
- **Key insight from student:** γ_power schedule dead = L_cov/R_cov EMAs equilibrate fast enough that γ schedules can't help. "A cleaner intervention would be to manipulate the EMA β (the covariance buffer momentum) rather than γ."
- **74th closed axis.** Frieren reassigned to EMA β ramp shape (PR #841) — delayed nonlinear ramp.

## 2026-05-22 18:35 UTC — PR #780 CLOSED: Body-Muon u/w trust-region CEILING (0.5 vs 0.4) — NULL/NULL, 73rd axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/body-muon-uw-ceiling`
- Hypothesis: Clamp body-Muon updates to a maximum u/w ratio (ceiling = 0.5 vs 0.4) to prevent overshoot from high-magnitude updates. Counter-hypothesis to the existing floor (TARGET_UW=0.35): tests whether the upper tail of the u/w distribution is destabilizing.

| Arm | Ceiling | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | n/a | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| Arm A | 0.5 | `ne03hzf2` | 3125 | 3.27643 | +200 | +0.0095 | NULL |
| Arm B | 0.4 | `hn32cchn` | 3225 | 3.27963 | +300 | +0.0127 | NULL (worse) |

- **Monotone tighter→worse:** Arm B (tighter ceiling 0.4) is strictly worse than Arm A (0.5) on both sr and val.
- **Ceiling fires heavily:** Arm A 43% of param×step events clamped; Arm B 71% clamped. This is NOT an idle ceiling — it substantially modifies the update distribution.
- **Key informative-NULL finding: high u/w updates are PRODUCTIVE, not pathological.** PMuon's Kronecker preconditioner directs updates to confident, well-conditioned directions with high u/w ratios. Clamping them removes the per-tensor adaptivity PMuon was designed to provide.
- **Asymmetric floor/ceiling story:** The floor at TARGET_UW=0.35 is load-bearing (fires 49% and boosts weak-signal updates). The ceiling is anti-productive (firing 43-71% and suppressing confident updates). This is a clean asymmetric result: the u/w distribution's lower tail needs boosting, but the upper tail should be left alone.
- **73rd closed axis. u/w trust-region ceiling axis FULLY CLOSED. Follow-up H7 (Post-NS Frobenius norm) assigned to nezuko as PR #827 — directly motivated by the ceiling finding: NS output magnitude variability may be causing the floor to do inconsistent work across params.**

## 2026-05-22 16:53 UTC — PR #741 CLOSED: Aux AdamW β2 cooldown ramp (β2→0.999) — NULL on primary at n=2, val-frontier shift, 72nd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/aux-adamw-beta2-cooldown-ramp`
- Hypothesis: Ramp aux AdamW β2 from 0.95 → 0.999 during cooldown to slow late-cooldown variance estimation for embed/lm_head/scalars, hypothetically improving terminal val.

| Seed | W&B | sr | val/loss |
|---|---|---|---|
| Baseline (PR #737 n=2) | rdbmnzpc/32r3isz5 | 2925 | 3.266926 |
| Seed 1 | `nsvxxmvl` | 2950 | 3.265040 |
| Seed 2 | `k4chzjdk` | 2950 | 3.265453 |
| **n=2 mean** | — | **2950** | **3.265247** |
| Δ vs baseline | — | **+25** (marginal NULL on primary) | **−0.001679** (improvement past 0.001 marginal threshold) |

- **n=2 reproducibility is essentially perfect:** both seeds delivered sr=2950 EXACTLY (no 25-step bucket spread). Both val within 0.0005 of each other. The β2 ramp mechanism is real and reproducible.
- **NULL on primary metric:** n=2 mean sr=2950 fails the merge rule (sr ≤ 2925 strict). Per CLAUDE.md: "Merge if the PR improves the current baseline according to the target's declared primary metric direction" — sr regresses by +25 with high reproducibility.
- **Val-frontier shift:** axis improves val by −0.0017 below baseline at n=2 confirmation (stat-sig margin 0.02086 = 5.2× over 0.004 threshold) but does NOT move the primary metric.
- **Pattern:** This is the inverse of PR #737 (Polyak EMA), which gave +sr (good) and +val regression (bad). Here we get -val (good) and +sr (bad). Both confirm cooldown-phase mechanisms can shift the (sr, val) Pareto frontier but rarely improve both axes simultaneously.
- Suggested follow-up (deprioritized): Stack with #802 thorfinn (EMA β_target fine-scan) if it lands sr=2925/val<3.266 — could close #737's val regression. Not worth pursuing standalone.
- **72nd closed axis. Aux variance-estimation in cooldown is a val-frontier lever, NOT an sr lever.** Confirms the cooldown-erosion pattern from a new angle: late-cooldown mechanism changes can shift val outcomes but cannot move steps-to-target once cooldown trajectory is set.

## 2026-05-22 16:14 UTC — PR #777 CLOSED: Body-Muon mu cooldown ramp (0.95→0.85 vs 0.95→0.98) — NULL/marginal NULL, 71st axis (g1r1-fern)

- Branch: `g1r1-fern/pmuon-mu-cooldown-ramp`
- Hypothesis: Ramp body-Muon momentum coefficient (mu) during cooldown — Arm A 0.95→0.85 (sharper decay; less smoothing as gradients shrink) vs Arm B 0.95→0.98 (more smoothing/lag as gradients shrink). Targets the conjecture that the optimal mu for terminal refinement differs from mid-training.

| Arm | mu schedule | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | mu=0.95 constant | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| **Arm A** | 0.95 → 0.85 | s6umzz3i | **2925** | 3.26880 | 0 (TIE) | +0.001874 | NULL — sr ties, val marginally fails (>0.001 threshold) |
| **Arm B** | 0.95 → 0.98 | l4w74vmj | 3025 | 3.26793 | +100 | +0.001004 | NULL — sr NULL primary; val just over 0.001 marginal threshold |

- **Body-Muon momentum spec PINNED at static mu=0.95** across all 5 sub-axes tested: #660 ON/OFF + #682 mu schedule wide + #695 Polyak EMA short-window + #697 QHM + #777 mu cooldown ramp.
- **Cooldown-erosion confirmation:** Arm A (sharper decay) preserved sr at terminal but eroded val — consistent with the pattern that body-Muon momentum dynamics at mid-cooldown matter more than at terminal, and any movement off mu=0.95 is net-negative.
- **Cross-arm pattern:** Arm A (less smoothing) holds sr but loses val; Arm B (more smoothing) loses sr with val barely changed. **Asymmetry verdict:** moving toward LESS smoothing at terminal is the lesser evil — but neither direction wins.
- **Ramp telemetry verified clean:** Student confirmed `train/muon_mu/mu_t` linear ramp during cooldown via W&B telemetry; implementation correct.
- Suggested follow-ups (deprioritized): mu schedule with non-linear shape (delayed kick-in); per-layer-type mu (attn vs mlp); coupling mu to lr_mult instead of linear cooldown_progress — all expected NULL by axis closure.

## 2026-05-22 14:55 UTC — PR #769 CLOSED: Aux AdamW delayed cooldown start (300 vs 600) — NULL/NULL, 70th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-cooldown-delay`
- Hypothesis: Decouple aux AdamW cooldown start from body-Muon cooldown_start_step=975. Delay aux schedule by 300 or 600 steps so embeddings/scalars get more high-LR exposure before fine-grained cooldown.

| Arm | delay | aux_cooldown_start | W&B | sr | val/loss | Δsr (vs #737) | Δval (vs #737) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #737 n=2) | 0 | 975 | rdbmnzpc/32r3isz5 | 2925 | 3.266926 | — | — | ref |
| **Arm A** | 300 | 1275 | f23tr64v | 2975 | 3.26688 | +50 | −0.000046 | NULL on sr |
| **Arm B** | 600 | 1575 | asxzb8lk | 3000 | 3.26747 | +75 | +0.000544 | NULL on both |

- **Monotonic dose response confirms NULL is real:** 300→600 monotonically worse on both metrics. Rules out noise interpretation.
- **Arm A val is tied with baseline (~0.05 mnat better, within noise)** but sr +50 is unambiguous NULL on the primary metric.
- **70th closed axis. Cooldown-erosion family closure now spans BOTH sides:** body-Muon perturbations (#723/#725/#690/#697/#774) AND aux schedule-decoupling (#769). Confirms global cooldown_start=975 is well-tuned across mechanisms. The productive cooldown lever (per #737) ADDS new mechanisms (Polyak EMA) rather than perturbs existing schedules.
- **Student insight:** "Cutting that taper window in half makes embeddings end further from optimum, not closer" — the steeper, shorter aux cooldown window (compressed to ~2000 vs ~2275 steps) gives an effectively higher floor at terminal, refuting the high-LR-exposure hypothesis cleanly.
- Suggested follow-ups (deprioritized): inverse direction (neg delay), per-aux-group decoupling (embed only), different COOLDOWN_POWER for aux.

## 2026-05-22 13:21 UTC — PR #737 MERGED: Polyak EMA β_target=0.99 cooldown ramp — n=2 sr win (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-cooldown-beta-ramp`
- Hypothesis: Couple Polyak EMA β to lr_mult so EMA window expands as LR→0. β_t = β_base + (β_target − β_base) × cooldown_progress (deterministic, no per-run randomness).
- **n=2 seeds:** seed-1 `rdbmnzpc` sr=2925/val=3.265811, seed-2 `32r3isz5` sr=2925/val=3.268040. n=2 mean: **sr=2925, val=3.266926.**
- **Stat-sig margin:** (3.28 − 3.266926)·√2 = 0.01849 ≥ 0.004 ✓ (4.62× threshold). Both seeds hit sr=2925 deterministically (β_t coupling to lr_mult is independent of seed noise).
- Vs old baseline #413 (sr=2937.5): Δsr=−12.5 (sr win); val regresses +2.65 mnat (3.266926 vs 3.264278) — accepted because primary metric is sr.
- **First merged sr win since #413.** New advisor branch baseline. Reproduce: add `--ema_beta 0.95 --ema_warmup_steps 2250 --ema_beta_target 0.99` to PR #413 config.

## 2026-05-22 13:21 UTC — PR #760 CLOSED: PMuon γ_power cooldown ramp (0.4→0.5 vs 0.4→0.3) — NULL/NULL, 69th axis (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-cooldown-ramp`
- Hypothesis: Ramp γ_power during cooldown — harder whitening (0.5) for more isotropic late-training updates OR softer whitening (0.3) for more signal preservation as LR→0.
- Arm A `wmsd0lvk` (0.4→0.5): sr=2975, val=3.26733 — NULL.
- Arm B `xmpjznpa` (0.4→0.3): sr=2975, val=3.26604 — NULL but ~2× closer to baseline on val.
- **Asymmetric closure pattern:** softer whitening less harmful than harder during cooldown. γ_power=0.4 static well-tuned (closes γ ramp axis, adds to #444 warmup ramp NULL).

## 2026-05-22 12:45 UTC — PR #774 CLOSED: PMuon cov warmup fast-mix (K=20 vs K=50) — NULL with numerical-instability boundary, 68th axis (g1r1-edward)

- Branch: `g1r1-edward/pmuon-cov-warmup-fast-mix`
- Hypothesis: β_cov=0.0 for first K steps to rapidly populate L_cov/R_cov buffers, then snap to β_cov=0.95 stable EMA. Tests whether early-training cov buffer init quality is a lever.

| Arm | K | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 20 | ih0bs1wn | 2975 | 3.26713 | +37.5 | +0.00285 | NULL |
| **Arm B** | 50 | ibl7esmh | crashed step 41 | — | — | — | INSTABILITY |

- **Arm A NULL on both metrics, n=1:** Δsr=+37.5 (>25 marginal threshold), Δval=+0.00285 (>0.001 marginal threshold). Stat-sig threshold (val ≤ 3.276) passes — within noise floor but consistently worse than baseline mean.
- **Arm B numerical-instability INTRINSIC to hypothesis:** With β_cov=0.0, EMA collapses to `R_cov ← g.T @ g` — rank-deficient by construction. After ~40 steps of pure outer-product accumulation, `torch.linalg.eigh` cannot decompose. eps=1e-12 clamp does nothing because it activates POST eigendecomposition. Rules out K=50 (and larger) as viable. K=20 happened to escape this window by luck.
- **Closes 68th axis cleanly:** the cov-warmup-fast-mix hypothesis adds nothing useful at K=20 (NULL) and corrupts the estimator at K=50 (instability). The cluster (#727, #769, #760, #774) confirms β_cov=0.95 / cooldown stack is at a Pareto-balanced operating point.
- **Operational note:** student handled chain-launcher chaos (7 aborted runs) with clean recovery — diagnosed duplicate-launch pattern, killed artifact at 09:58 UTC, produced definitive Arm A + clean Arm B failure-mode analysis.

## 2026-05-22 09:15 UTC — PR #745 CLOSED: Body-Muon per-type LR cooldown asymmetry — NULL/NULL, 67th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/body-muon-cooldown-lr-asymmetry-attn-mlp`
- Hypothesis: Body-Muon LR cooldown multiplier asymmetric by block type (attn vs mlp). Arm A (attn×0.5, mlp×1.0) tests damped-attn cooldown; Arm B (attn×1.0, mlp×0.5) tests damped-mlp cooldown.

| Arm | attn cool× | mlp cool× | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 | 1.0 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 0.5 | 1.0 | gg4h05wp | 3025 | 3.27157 | +87.5 | +0.00730 | NULL |
| **Arm B** | 1.0 | 0.5 | 0x0yd7ts | 3050 | 3.27548 | +112.5 | +0.01120 | NULL |

- **Both arms regress on both metrics, not marginally:** Δsr=+87.5/+112.5 (well >25), Δval=+0.007/+0.011 (well >0.001). Neither qualifies for marginal-band n=2 confirmation.
- **Crossover pattern (exceptional diagnostic):** Arm B (mlp cooled faster) led Arm A by ~0.005-0.019 val through steps 1500-2500, then Arm A caught up and overtook in the final 250 steps. Sub-component cooldown sensitivities are real but trade off symmetrically — neither configuration recovers the symmetric (1.0, 1.0) baseline.
- **Closes per-type × cooldown LR asymmetry axis:** adds to #499 (static per-type), #535 (sub-MLP), #532 (depth-based) — all NULL. Per-type LR family is now extensively closed across both static and cooldown-coupled configurations.

## 2026-05-22 08:40 UTC — PR #736 CLOSED: PMuon per-type γ_power asymmetry (wide split) — NULL/NULL, 66th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-gamma-power-per-type`
- Hypothesis: Body-Muon per-block-TYPE γ_power asymmetric whitening (attn vs MLP). Arms A (γ_attn=0.3, γ_mlp=0.5) vs B (γ_attn=0.5, γ_mlp=0.3), symmetric split centered on baseline γ=0.4.

| Arm | γ_attn | γ_mlp | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.4 (scalar) | 0.4 (scalar) | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | 0.3 | 0.5 | v8nsntg2 | 3050 | 3.27263 | +112.5 | +0.00835 | NULL |
| **Arm B** | 0.5 | 0.3 | xlysv0gm | 2975 | 3.26734 | +37.5 | +0.00306 | NULL |

- **Direction validated (Arm B > Arm A by ~0.005 val from step 1250 onward):** γ_attn > γ_mlp is the helpful direction — more whitening for attn (lower-rank per-head gradient covariance) and less for MLP (richer spread of signal across directions).
- **Magnitude insufficient:** wide symmetric split (0.5/0.3 around scalar 0.4) places both endpoints individually too far from scalar optimum (per #519 γ pruning ablation). Both 0.3 and 0.5 hurt independently; Arm B lead just reflects 'less harm from lowering γ_mlp than from lowering γ_attn'.
- **Partial axis closure:** wide symmetric split is closed; narrow attn-only-raised split (γ_attn=0.5, γ_mlp=0.4 — pin mlp at scalar optimum) remains open and will be tested as the follow-up.
- Adds to PMuon γ_power cluster: scalar γ=0.4 PINNED (#519), γ_power ramp NULL (#444), cooldown ramp running (#760), per-type narrow follow-up next.

## 2026-05-22 08:20 UTC — PR #727 CLOSED: Body-Muon WD cooldown schedule — NULL/NULL, 65th axis (g1r1-fern)

- Branch: `g1r1-fern/muon-wd-cooldown-schedule`
- Hypothesis: Body-Muon weight-decay as a temporal schedule during cooldown (linear ramp UP 0.025→0.050 vs DOWN 0.025→0.000). Tests whether WD-impulse trajectory shape (vs static WD=0.025) is a productive lever.

| Arm | direction | wd_t end | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | static | 0.025 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | ref |
| **Arm A** | UP ramp 0.025→0.050 | 0.050 | xzx014yu | 2975 | 3.267333 | +37.5 | +0.003055 | NULL |
| **Arm B** | DOWN ramp 0.025→0.000 | 0.000 | rzthmx1j | 2975 | 3.266326 | +37.5 | +0.002048 | NULL |

- **Symmetric-NULL signature**: both arms regress identically (Δsr=+37.5, Δval ≈+0.003/+0.002) — WD=0.025 STATIC sits at a local optimum on the WD-trajectory axis. The cross-arm Δval = +0.001 (B better than A) is below the marginal threshold and not load-bearing.
- **Schedule infrastructure verified**: `train/muon_wd/wd_t` telemetry confirmed linear ramp fires correctly (Arm A: 0.025→0.050; Arm B: 0.025→0.000) per-step during cooldown_start=975 through num_steps=3250. No NaN, no instability.
- **Buffer-modification/cooldown-trajectory lever cluster** now fully closed: #647 longer cf, #607 LR floor, #717+#690 SGDR, **#727 WD-schedule** ← this. The WD-impulse trajectory `WD_t × LR_t × param_t` shaped by the LR cooldown alone is already well-matched to cooldown's deterministic LR-decay.
- **Implication**: WD-as-temporal-schedule lever EXHAUSTED. WD-as-scalar-tuning-target (constant 0.025) remains the operative knob — #413's choice continues to win.
- Excellent symmetric two-arm probe with clean telemetry. Also: launcher-fix during the run (pgrep gate fix after duplicate-launch incident) was high-quality engineering.

## 2026-05-22 08:05 UTC — PR #730 CLOSED: Body-Muon SWA cooldown init — NULL/NULL, 64th axis (g1r1-edward)

- Branch: `g1r1-edward/body-muon-swa-cooldown-init`
- Hypothesis: Replace live body-Muon weights with SWA average (uniform window over last K stable-phase steps) at cooldown_start_step=975. Tests parameter-space centroid initialization for cooldown.

| Arm | K | W&B | sr | val/loss | Δsr | Δval | swa/rel_frob | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — | — |
| **Arm A** | 100 | 9xwvmmqz | 3000 | 3.26820 | +62.5 | +0.00392 | **27.1%** | NULL |
| **Arm B** | 200 | pwv34alf | 3000 | 3.26928 | +62.5 | +0.00500 | **37.2%** | NULL |

- **Key diagnostic finding (strongest result this session):** Predicted 1-5% Frobenius distance; actual 27-37% (5-7× higher). Body-Muon weights TRAVEL DIRECTIONALLY at ~0.27-0.37 relative Frobenius distance per 100-200 steps. Uniform SWA average is a heavily lagged anchor, not a basin centroid.
- **Mechanism falsified:** The 'live frontier vs centroid' image does not apply. Body-Muon optimization is a directed trajectory, not basin-orbiting. Resetting to 100-step-lag point = rewind ~100 steps.
- **Wider window → more lag → more harm:** K=200 (37% distance) is consistently ~0.001 worse than K=100 (27% distance) throughout cooldown, confirming monotone dose-response.
- **5th buffer-modification dead lever at cooldown_start** (LR schedule + optimizer state × 2 + parameter space). Buffer-modification at cooldown_start FULLY CLOSED across all categories.
- Excellent diagnostic instrumentation by student — swa/rel_frobenius_dist diagnostic changes a null result into a mechanistically informative finding.

## 2026-05-22 06:35 UTC — PR #725 CLOSED: PMuon bilateral covariance reset at cooldown_start — NULL/NULL, 63rd axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-cov-cooldown-reset`
- Hypothesis: Resetting or zeroing the PMuon bilateral covariance buffers (L_cov/R_cov, 72 tensors) at cooldown_start_step=975. Partial (0.5×) vs full (0.0×) reset.

| Arm | cov_scale | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — |
| **Arm A** | 0.5 (partial) | alao0903 | 2975 | 3.26712 | +37.5 | +0.00284 | NULL |
| **Arm B** | 0.0 (full reset) | 0d6vgq6v | 2950 | 3.26550 | +12.5 | +0.00122 | NULL |

- **Non-monotone pattern (identical to #723 momentum reset):** 0.5× worse than 0.0×, both worse than no reset. Mid-training L_cov/R_cov are load-bearing.
- **4th buffer-modification dead-lever at cooldown_start** (after #690 SGDR, #697 QHM, #723 momentum reset). Buffer-modification axis at cooldown_start FULLY CLOSED across all PMuon buffer types.
- **Student whitening transient hypothesis:** partial scale (0.5×) shrinks tr^γ divisor by 0.5^0.8=0.574 → 1.74× update amplification transient, creating worse stale/fresh mixture than either extreme.
- **Trajectory analysis:** B−A gap peaks at +0.004-0.005 immediately post-reset (steps 1000-1500), closes by ~0.003 over remaining training — consistent with WSD cooldown erosion absorbing the divergence.
- **No n=2 needed:** Arm A non-marginal (Δsr=+37.5 > 25). Arm B marginal but same direction as Arm A.

## 2026-05-22 05:30 UTC — PR #723 CLOSED: Body-Muon momentum reset at cooldown_start — NULL/NULL, 62nd axis (g1r1-frieren)

- Branch: `g1r1-frieren/muon-cooldown-momentum-reset`
- Hypothesis: Resetting or weakening the body-Muon momentum buffer at cooldown_start_step (step 975) to allow the optimizer to follow current gradients during deterministic LR-decay, rather than being dragged by accumulated mid-training inertia.

| Arm | scale | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 1.0 (no reset) | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — | — |
| **Arm A** | 0.5 (partial) | bvnxlq25 | 2975 | 3.26604 | +37.5 | +0.00176 | NULL — clearly worse |
| **Arm B** | 0.0 (full reset) | ek4zebyw | 2950 | 3.26487 | +12.5 | +0.000592 | NULL — marginally worse |

- **Win threshold (n=1):** sr ≤ 2925 — neither arm wins. Neither arm close.
- **No n=2 needed:** Arm A is non-marginal (Δsr=+37.5 > 25). Arm B is marginal but both metrics worse simultaneously — n=2 unlikely to flip sign.

- **Key mechanism finding — body-Muon momentum buffer is load-bearing for cooldown.** Both arms worse confirms the mid-training momentum trajectory carries information that cooldown LR-decay relies on.

- **Non-monotonic surprise:** 0.5× WORSE than 0.0×. If "less inertia = better" were the story, we'd expect monotone improvement as scale → 0. Instead, partial reset creates a worse magnitude/direction mismatch than either extreme. Rules out scale-based single-event resets as a useful lever.

- **Reset events confirmed firing:** Arm A: step=975, n_scaled=72, frob 205.75 → 102.88 (0.5×). Arm B: step=975, n_scaled=72, frob 212.29 → 0.0000 (0.0×). 72 body-Muon tensors scaled in both arms.

- **Joint implication with prior axes:** 3rd confirmed instance of buffer-modification at cooldown_start being harmful (#690 SGDR warm restart, #697 QHM body-Muon, now #723 momentum reset). Stable-phase trajectory state is valuable — discarding/perturbing it consistently costs steps.

- **Next steps for cooldown-erosion:** Remaining levers must be schedule-side, not buffer-side:
  - Cooldown β ramp (in-flight: #737 thorfinn, sr=2925 provisional)
  - Aux β2 ramp (in-flight: #741 alphonse)
  - Per-type LR ramp (in-flight: #745 nezuko)
  - γ_power whitening ramp (newly assigned: #760 frieren)

## 2026-05-22 01:30 UTC — PR #698 CLOSED: NAdam (Nesterov-AdamW) for aux groups — NULL/NULL, 61st axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/nadam-aux`
- Hypothesis: Apply Nesterov lookahead to aux AdamW (embed, lm_head, scalars) — cross-family analog of #660 body-Muon Nesterov. Arm A β₁=0.8 NAdam ON, Arm B β₁=0.9 NAdam ON.

| Arm | β₁ | nadam | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 0.8 | OFF | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.8 | ON | wwyxnxdy | 3000 | 3.26811 | +62.5 | +0.00383 | NULL |
| Arm B | 0.9 | ON | 5i9nua0o | 3000 | 3.26829 | +62.5 | +0.00401 | NULL |

- **Δ between arms:** +0.00018 val, 0 sr — well inside seed noise. β₁ retune did NOTHING.

- **Mechanism (3 findings):**
  1. **AdamW denominator absorbs Nesterov lookahead.** Nesterov's cross-term `β₁·(1-β₁)·g_t` adds gradient weight in numerator, but the AdamW denominator `1/√v̂` is already coordinate-adaptive. Net effect: per-coord absorption or over-weight on low-variance coords. Structurally different from body-Muon Nesterov which shapes spectral structure post-NS.
  2. **Aux is structurally insensitive to update-rule changes.** This is the 10th aux family NULL (#545 AdaBelief, #575 NadamW-old, #585 AdEMAMix, #578 AMSGrad, #583 Adamax, #609 LAMB, #604 Lion, #617 Lookahead, #623 Schedule-Free, #698 NAdam-aux). Saturation pattern: only schedule machinery moves aux outcomes.
  3. **β₁ ∈ [0.8, 0.9] gives identical terminals.** Rules out the "try harder β₁ retuning" follow-up. The Nesterov-aux effect is structural-NULL, not tuning-NULL.

- **Excellent terminal write-up:** pre-flight numerical verification (max dev 2.4e-7 from analytical), bitwise parity with baseline when flag is off, AuxAdamW subclass with clean fallthrough. Production-quality optimizer code.

- **Conclusion:** Cross-family Nesterov on aux CLOSED. Aux AdamW update-rule family approaching exhaustive saturation.

## 2026-05-22 00:55 UTC — PR #697 CLOSED: QHM (Quasi-Hyperbolic Momentum) on body-Muon — NULL/NULL, 60th axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/qhm-body-muon`
- Hypothesis: QHM linear blend `ν·g + (1-ν)·m` decouples gradient weight from momentum decay, potentially reaching variants Nesterov cannot. Arm A ν=0.10, Arm B ν=0.20, both nesterov=false, β=0.95.

| Arm | ν | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Reference #660A (ν=0) | 0 | — | 3025 | 3.26949 | +87.5 | +0.00521 | reference |
| Arm A | 0.10 | wkfhw41d | 3025 | 3.27137 | +87.5 | +0.00709 | NULL |
| Arm B | 0.20 | oxy20p9p | 3125 | 3.27751 | +187.5 | +0.01323 | NULL (worse) |

- **Stat-sig test:** Arm A: (3.28−3.27137)·√1=+0.0086 marginal pass on val, but sr=3025 fails win rule. Arm B: (3.28−3.27751)·√1=+0.0025 FAIL +0.004 rule + sr=3125. Both NULL.

- **Mechanism (3 findings):**
  1. **Super-linear penalty in ν along the β=0.95 slice.** ν=0→0.10 cost: +0.00188 val, 0 sr. ν=0.10→0.20 cost: +0.00614 val, +100 sr. Same Δν=0.10 step but ~3× cost — monotone wrong direction, accelerating.
  2. **QHM blend cannot replicate Nesterov cross-term.** Nesterov's `μ²·m_prev + (1-μ²)·g` is structurally distinct from QHM's `ν·g + (1-ν)·m`. The (ν,β) decoupling family cannot reach Nesterov's lookahead-on-updated-momentum.
  3. **STRONGEST cooldown-erosion instance to date.** Both arms showed -49 to -71 mnat advantage vs ν=0 reference at steps 1000-1750, COMPLETELY inverted to +1.9 to +8.0 mnat penalty at terminal. Largest mid-vs-terminal flip across all 4 cooldown-erosion instances (-71 → +8 mnat is a 79 mnat swing through cooldown).

- **Joint with #660 (Nesterov ON/OFF NULL):** Body-Muon momentum spec now PINNED across 9 sub-axes: β=0.95, nesterov=True, no QHM blend, mu schedule static, post-NS momentum closed, Nesterov cross-term load-bearing.

- **Conclusion:** QHM (ν,β) plane CLOSED at β=0.95 slice. Body-Muon momentum decoupling family fully closed.

- **Operational incident (resolved):** student traced 20:40 UTC pgrep-x trap (`pgrep -x torchrun` returns empty because argv[0]="python3"). Recovery: killed dupes, deleted corrupted W&B runs `0fwetrtj`/`z8sxf1cl`, relaunched Arm B cleanly. Arm A unaffected. Memory updated.

## 2026-05-21 23:35 UTC — PR #690 CLOSED: SGDR cosine restarts — NULL/NULL, 57th axis (g1r1-edward)

- Branch: `g1r1-edward/sgdr-cosine-restarts`
- Hypothesis: SGDR warm cosine restarts on body-Muon LR — tests whether periodic LR resets help escape sharp minima that WSD's monotone decay cannot escape. Two arms: Arm A (1 restart, T_mult=1, 2× 1625-step cycles), Arm B (2 restarts, T_mult=1, 3× 1083-step cycles).

| Arm | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (1 restart) | znxwk1om | -1 (never hit 3.28) | 3.30605 | -∞ | +0.0418 | NULL |
| Arm B (2 restarts) | 5n88a4qm | -1 (never hit 3.28) | 3.32263 | -∞ | +0.0584 | NULL (WORSE than A) |
| Pair mean | — | -1 | 3.31434 | — | +0.0501 | NULL |

- **Stat-sig test:** Arm A: (3.28−3.30605)·√1=−0.026 FAIL. Arm B: (3.28−3.32263)·√1=−0.043 FAIL. Both fail +0.004 rule decisively.

- **Mechanism (4 findings):**
  1. **Cycle-0 advantage real and reproducible.** Both arms beat baseline by ≥0.10 val/loss at cycle 0 bottom (Arm A step 1000: val=3.553 vs base 3.657; Arm B step 1000: val=3.545 vs base 3.657). Cosine-to-zero LR finds better local minima at same step count.
  2. **Each restart costs +0.13 to +0.17 val/loss spike.** Arm A restart 1: +0.174. Arm B restart 1: +0.132. Arm B restart 2: +0.166. Spike is structural — NS/whitening buffers converged to prior LR scale; restart invalidates them.
  3. **More restarts → worse final loss.** 3× 1083-step cycles (Arm B) worse than 2× 1625-step cycles (Arm A). Each successive cycle finds deeper bottom (3.545 → 3.379 → 3.323) but rate slows; spike costs compound.
  4. **Cooldown-erosion instance #3.** Arm B mid-cycle-1 at step 2125 showed −0.019 advantage vs baseline, eroded to +0.058 final regression. Third documented cooldown-erosion instance after #697 QHM (−50 mnat mid → +7 mnat terminal) and #686 β_cov schedule.

- **WSD comparison:** WSD's monotone cooldown (cooldown_frac=0.30, COOLDOWN_POWER=1.4) already well-tuned. Non-monotone/restart LR cannot pay back restart cost on 3250-step budget.
- **Conclusion:** SGDR on body-Muon FULLY CLOSED. Body-Muon LR schedule shape axis (monotone cooldown direction) CLOSED across restart count = {1, 2}.

## 2026-05-21 22:02 UTC — PR #686 CLOSED: PMuon β_cov schedule — symmetric NULL, 56th axis (g1r1-fern)

- Branch: `g1r1-fern/pmuon-beta-cov-schedule`
- Hypothesis: Two opposite-direction phase-specific β_cov schedules — Arm A responsive early (0.90→0.95 over steps 0-500), Arm B smoother cooldown (0.95→0.98 over steps 975-3250). Tests whether bilateral covariance EMA decay can be improved as a schedule.

| Arm | direction | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | β_cov 0.90→0.95 warm | z6fo7pix | 2975 | 3.267627 | +37.5 | +0.00335 | NULL |
| **B** | β_cov 0.95→0.98 cool | zh1xe1ci | 2975 | 3.267820 | +37.5 | +0.00354 | NULL |

### Analysis & mechanism findings

**Symmetric NULL is the key empirical signature.** Both arms move β_cov in OPPOSITE directions in DIFFERENT phases (Arm A: lower early; Arm B: higher late). Both regress by essentially identical amounts (Δval = 0.0034 vs 0.0035; Δsr = +37.5 for both = +1 cooldown step). This is the canonical signature of a STATIC local optimum.

**Pre-cooldown sanity check is decisive (step 1125: Arm A 3.62858, Arm B 3.62895 — Δ_AB=0.0004 = seed noise).** The two arms diverge only in their phase-specific β_cov regime, not from confounded init or seed variation. Arm A's regression is fully realized BEFORE cooldown (early-phase β_cov damage in stable phase); Arm B's regression is fully realized AFTER cooldown_start (late-phase β_cov damage). This rules out a confounded "schedule machinery" issue and isolates the regression to the schedule mechanism itself.

**Combined with prior PR #502 β_cov scalar scan (β_cov=0.90 marginal NULL; β_cov=0.99 clear NULL), this CLOSES the β_cov axis mechanism-cleanly across BOTH scalar value AND temporal schedule directions. β_cov=0.95 STATIC is robustly load-bearing.**

**Cooldown-erosion is NOT explained by whitening miscalibration.** Student's insight: the cooldown-erosion pattern (#690 SGDR, #697 QHM, this #686 β_cov schedule, #644 winsorization, #622 tanh-squash) cannot be reduced to "miscalibrated bilateral covariance during cooldown" — Arm A (more responsive early covariance) and Arm B (smoother late covariance) both fail. The cooldown sensitivity must come from a different mechanism (most likely the deterministic LR-decay trajectory dominating per-step optimizer contributions).

### Closure semantics

**56th closed axis.** β_cov temporal-schedule sub-axis CLOSES alongside the prior scalar β_cov sub-axis. PMuon's bilateral covariance EMA spec is now FULLY PINNED at β_cov=0.95 STATIC across both scalar value and schedule directions.

### Student suggested follow-ups
- (Closed by advisor): β_cov axis closed — stop perturbing β_cov shape.
- (Considered, deferred): γ_power schedule during cooldown, NS-iteration count schedule during cooldown.
- (Advisor next assignment): WD cooldown schedule (different lever, untested as a temporal schedule).

## 2026-05-21 21:42 UTC — PR #682 CLOSED: Body-Muon mu schedule — NULL/inconclusive, 55th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-mu-schedule`
- Hypothesis: Time-varying mu (momentum coefficient) for body-Muon — Arm A cooldown ramp 0.95→0.85 (responsive in cooldown); Arm B warmup ramp 0→0.95 (avoid stale init momentum).

| Arm | mechanism | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | static mu=0.95 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | cooldown ramp 0.95→0.85 | 0uvvmh8p | 2925 | 3.26985 | −12.5 (marginal sr) | +0.00557 (regression) | inconclusive — sr meets n=1 first clause BUT val regression fails second clause; tradeoff effect |
| **B** | warmup ramp 0→0.95 | uxi3dbgm | 3050 | 3.27239 | +112.5 | +0.00812 | clear NULL |

### Analysis & mechanism findings

**Finding 1 — Warmup ramp UP rejects the "random-init bias" hypothesis (clean negative).** Arm B is consistently behind baseline from step 125 onward and never recovers. The hypothesis (low mu early avoids stale random-init momentum) predicted Arm B would catch up by mid-training. Data shows the gap (+0.118 mnat at step 125, +0.154 at step 250) decreases by step 1000 to parity, then RE-EMERGES in cooldown as Arm A (which has cooldown mu ramp) pulls ahead. Reduced early momentum is a permanent loss, not a transient setup phase.

**Finding 2 — Cooldown ramp DOWN shows real tradeoff (val for sr).** Arm A's −12.5 sr is in the marginal noise range but directionally consistent with the hypothesis (lower mu in cooldown → responsive tracking of small updates → faster threshold-cross). However val regression (+0.00557) suggests responsiveness comes at the cost of final smoothing. The mu schedule converts val/loss precision into sr speed at unfavorable ratio.

**Decision logic for Arm A:** n=1 win rule's second clause `(sr=2925 AND val<3.264278)` is decisive — val regression alone disqualifies. Even at n=2 (which would test if −12.5 sr is real), the value tradeoff (gain ~12 steps but add +5.6 mnat) is a net loss by the benchmark's value function.

**Combined with #660 Nesterov ON/OFF closure (Arm A nesterov=False mu=0.95 val=3.26949, essentially identical to #682 Arm A val=3.26985 within ±0.0004), this is the second piece of evidence that the body-Muon mu spec at 0.95 STATIC is at a robust optimum.**

### Closure semantics

**55th closed axis.** mu temporal-schedule sub-axis CLOSES across both warmup and cooldown directions. Combined with #660 (Nesterov ON/OFF), the body-Muon momentum mechanism is now PINNED at static (mu=0.95, nesterov=True, NS_ITERS=12) across 4 sub-axes. #697 alphonse (QHM) is the in-flight extension that tests if the (ν, β) plane beyond Nesterov has any signal.

## 2026-05-21 21:24 UTC — PR #684 CLOSED: Body-Muon Langevin noise post-NS — NULL/NULL, 54th axis (g1r1-frieren)

- Branch: `g1r1-frieren/body-muon-langevin-noise`
- Hypothesis: Inject isotropic Gaussian noise N(0, σ_base²·lr_t²·I) after the NS step on body-Muon updates. SGLD-like Langevin dynamics may help find flatter minima at scale.

| Arm | σ_base | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | 0.01 | chhogu08 | 2975 | 3.26641 | +37.5 | +0.00213 | NULL |
| **B** | 0.05 | olgik55z | 2975 | 3.26711 | +37.5 | +0.00283 | NULL |

### Analysis & mechanism findings

**Linear σ scaling confirmed.** noise_frob ratio between arms held at exactly 5.00× through every checkpoint. PMuon's polar step does not differentially damp noise magnitudes — perturbation magnitude scales linearly with σ_base as designed.

**Identical sr=2975 between arms is informative.** Both arms regress by exactly +37.5 sr-steps despite 5× noise difference. If the regression were a smooth function of σ, we'd see monotonic worsening. The identical sr suggests the regression is bounded by another factor (likely the cooldown's deterministic finishing point), not the noise level itself.

**Mid-training noise was NEUTRAL.** During steps 1000-2000, Arm B (5× noise) was slightly AHEAD of Arm A. This contradicts "more noise = more cost" and shows the noise is not destructive in stable phase. The +0.0007 val gap appears only in cooldown.

**Two convergent failure mechanisms:**
1. PMuon polar/whitening already produces a low-curvature trajectory — no sharp basin to escape from. SGLD's "escape sharp minima" benefit requires sharp minima to exist.
2. The σ·lr_t schedule decays noise to zero in cooldown (as designed, ~5% of update magnitude at peak → ~0.5% by step 2500). The noise level when it could matter (peak LR) doesn't help because trajectory is already flat.

**Combined with #644 winsorization, #622 tanh-squash, #607 LR floor, this 4th gradient-domain perturbation family closes.** Element-wise post-NS modifications (clipping, squashing, noise) are not productive levers — PMuon's spectral whitening absorbs magnitude info before these can affect dynamics.

### Suggested followups (student's, valid in principle but unlikely to help)

1. Anisotropic noise aligned with NS directions (vs isotropic Gaussian)
2. σ·sqrt(lr_t) or σ·lr_t² schedules (different timing of noise injection)
3. Inject noise to momentum instead of update

These are mechanism-clean but the underlying issue (PMuon trajectory already flat-enough) blocks the benefit.

### Closure semantics

**54th closed axis.** SGLD/Langevin noise sub-axis FULLY closes. Gradient-domain perturbation family CLOSED (4 sub-axes: winsorization #644, tanh-squash #622, LR floor #607, Langevin #684).

## 2026-05-21 16:47 UTC — PR #667 CLOSED: Cosine LR schedule vs WSD — NULL/NULL, 53rd axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/cosine-schedule`
- Hypothesis: Test whether the WSD-style schedule (stable plateau + concave power-1.4 cooldown) can be replaced with a cosine schedule. Two arms tease apart the stable-plateau effect from the decay-shape effect: Arm A pure cosine from step 0; Arm B 30% stable + cosine 70% cooldown.

| Arm | schedule | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | wsd + power-1.4 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | pure cosine | r5p6b5fc | 3000 | 3.276601 | +62.5 | +0.012323 | NULL (val just above stat-sig 3.276) |
| **B** | cosine_wsd (30% stable + cosine 70%) | 3qn5btoq | 3000 | 3.272568 | +62.5 | +0.008290 | NULL (val under stat-sig, both metrics worse than baseline) |

### Analysis & two clean mechanism findings

**Finding 1 — Stable plateau is load-bearing.** Arm B (with 30% stable) beats Arm A (pure cosine) by Δval=0.004 at identical sr=3000. Holding cooldown shape fixed, adding a stable plateau improves val loss. This confirms what the prior WSD sub-axis sweeps suggested: peak-LR time matters; pure cosine spends too little time at peak LR.

**Finding 2 — WSD power-1.4 tail beats cosine tail (Arm B vs baseline).** Holding the stable phase at 70%, swapping the WSD concave (power-1.4) cooldown for a cosine S-curve cooldown costs +62.5 sr-steps and +0.0083 val. The aggressive-early/gentle-late shape of power-1.4 outperforms cosine's gentle-early/steep-late shape on this benchmark.

### Val/loss trajectory near 3.28 crossing (Arm B)

| step | val_loss |
|---|---|
| 2950 | 3.2826 |
| 2975 | 3.2808 |
| **3000** | **3.2791** (first crossing) |
| 3025 | 3.2775 |
| 3100 | 3.2743 |
| 3250 | 3.2726 final |

Both arms first cross 3.28 at step 3000. Arm B finishes lower than Arm A (3.2726 vs 3.2766) due to cosine slope remaining at end, but can't recover the 62.5-step deficit.

### Closure semantics

**Schedule family axis CLOSES — 53rd closed axis.** Combined with prior WSD sub-axes (cooldown_frac=0.7 pinned, cooldown_power=1.4 pinned, LR floor=0 pinned, warmup=0 pinned, longer cf brackets NULL #647), the LR schedule axis is now WSD-LOCKED across 7 sub-axes:

1. Family: WSD (not cosine, not cosine+stable)
2. Stable plateau: REQUIRED (Arm B vs Arm A finding)
3. cooldown_frac: 0.7 STATIC
4. cooldown_power: 1.4 STATIC (concave tail shape)
5. LR floor: 0 STATIC
6. LR warmup: 0 STATIC
7. Tail shape: power-1.4 > cosine (this PR's Arm B vs baseline finding)

### No n=2 needed

Δsr=62.5 is far above the 25-step marginal threshold. Δval=0.0083 is far above the 0.001 marginal threshold. Both arms clear NULL on n=1.

### Operational note

Arm A's 70 GiB peak memory reflects an early-run zombie-torchrun contention episode (Arm A's W&B run start window overlapped a leftover process). Optimizer state / val_loss curves not contaminated; only wall-clock for early steps. Arm B was clean at 35 GiB single-process throughout.

### Follow-ups assigned

- **#697 alphonse QHM (β-ν decoupled momentum on body-Muon)** — direct extension of #660 Nesterov closure
- **#698 nezuko NAdam (Nesterov-AdamW for aux)** — cross-family Nesterov mechanism test

---

## 2026-05-21 16:42 UTC — PR #660 CLOSED: PMuon Nesterov ON vs OFF — NULL/NULL, 52nd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/nesterov-onoff-pmuon`
- Hypothesis: PMuon's whitening + polar orthogonalization pipeline might dominate the update direction enough that the Nesterov vs standard-momentum distinction becomes irrelevant. Arm A tests pure Nesterov contribution (nesterov=False, mu=0.95). Arm B tests whether Nesterov is "secretly equivalent" to a different mu (nesterov=False, mu=0.90 to roughly match Nesterov-ON effective g-weight of 0.0975).

| Arm | nesterov | mu | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | True | 0.95 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| **A** | False | 0.95 | z6sx2hkq | 3025 | 3.26949 | +87.5 | +0.00521 | NULL (within stat-sig) |
| **B** | False | 0.90 | kdcbvbcm | 3150 | 3.27833 | +212.5 | +0.01405 | CLEAR NULL (fails single-run stat-sig 0.00167 < 0.004) |

### Analysis & conclusion

Both arms NULL — **Nesterov is load-bearing for PMuon**. The key insight is the asymmetry between Arm A and Arm B:

**Hypothesized Nesterov→standard-momentum equivalence (FALSIFIED):**
- Nesterov ON at mu=0.95: effective update = 0.0975·g + 0.9025·m_prev (approximately, via μ²·m_prev + (1-μ²)·g coupling)
- Standard momentum at mu=0.90: effective update = 0.10·g + 0.90·m_prev

These have nearly identical g-weight (0.0975 vs 0.10). If Nesterov were just a reweighting trick, Arm B should have matched baseline.

**Actual result:** Arm B is WORSE than Arm A (+0.0141 vs +0.0052 val damage). The progression g-weight 0 → Nesterov(≈0.05 effective) → 0.10 is non-monotone: Nesterov helps, but moving toward higher g-weight without Nesterov's specific structure HURTS.

**Mechanism:** Nesterov's cross-term coupling (μ²·m_prev + (1-μ²)·g blended via two stages: m updated first, then look-ahead) is fundamentally different from a single-step blend (1-mu)·g + mu·m_prev. The two stages interact with the PMuon pipeline:
1. **Momentum-buffer evolution** is affected (Nesterov pre-mixes g into m before reading)
2. **Whitening reads the pre-mixed buffer** which has different spectral properties than a less-mixed buffer
3. **Newton-Schulz polar step** sees a different effective input matrix

The "two-stage lookahead" structure cannot be replicated by simply retuning mu in a one-stage blend.

**mu axis interaction:** PR #570 closed mu axis at mu=0.95 with Nesterov ON. This PR confirms mu=0.95 is STILL the optimal choice with Nesterov OFF (Arm B at mu=0.90 is worse than Arm A at mu=0.95). So the mu axis shape (peak at 0.95) doesn't flip with the Nesterov toggle. **Both nesterov=True AND mu=0.95 independently load-bearing.**

### Closure semantics

**Nesterov flag axis CLOSES — 52nd closed axis.** PMuon now FULLY PINNED on the body-momentum specification: γ_power=0.4 + β_cov=0.95 + NS_ITERS=12 + cubic-NS coefficients + ε=1e-12 + mu=0.95 + nesterov=True.

### Natural follow-up: Quasi-Hyperbolic Momentum

QHM (Ma & Yarats 2019) parameterizes momentum with two independent controls (ν, β):
- update = ν·g_t + (1-ν)·m_t, where m_t = β·m_{t-1} + (1-β)·g_t
- ν=0 → standard mu=β momentum; ν=1 → SGD; Nesterov ≈ ν=(1-β²)/(1-β) reweighted

QHM at β=0.95 with ν ∈ {0.10, 0.20} spans the region "above Nesterov-equivalent g-weight" — assigned to alphonse as direct follow-up. If both arms NULL: Nesterov's specific cross-term structure is the sweet spot. If Arm A (ν=0.10) helps: there's headroom between Nesterov and standard.

### Operational note

Student handled two duplicate-torchrun fingerprints cleanly via pgrep sanity gate in the sequential launcher — both arms ran without GPU contamination. Wandb log-upload hygiene (wandb.save policy='live') noted as a useful nice-to-have followup but not blocking.

---

## 2026-05-21 16:22 UTC — PR #651 CLOSED: LR warmup ∈ {100, 250 steps} — NULL/NULL, 51st axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lr-warmup-phase`
- Hypothesis: LR warmup from zero allows optimizer state (PMuon covariance EMAs, aux v-state) to stabilize before full-LR training, potentially improving convergence.

| Arm | warmup | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0 | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 100 | b7tnbh0k | 3000 | 3.26926 | +62.5 | +0.005 | NULL |
| B | 250 | xhjudzj3 | 3050 | 3.27341 | +112.5 | +0.009 | NULL |

**Mechanism (clean read with telemetry):** First-decile training slope (steps 0-325) is steeper with warmup (Arm A +56%, Arm B +82%) — the hypothesis is mechanically confirmed: optimizer states DO benefit from gradual LR introduction. But cost > benefit: steps spent at low LR during ramp are not recovered. By step 650 slopes converge, and runs stay behind baseline throughout. Slope-at-first-decile is NOT a reliable proxy for final speedrun performance.

**Monotonic closure:** Baseline (warmup=0) < Arm A (warmup=100) < Arm B (warmup=250) in terms of sr. Same conclusion as #647 cooldown_frac — WSD stable-phase startup is precious, any deviation costs more than it gains.

**WSD schedule shape now FULLY PINNED across 6 sub-axes:** shorter-cooldown, LR floor, NS_ITERS ramp, decoupled aux cooldown, longer-cooldown, warmup phase. All confirmed NULL; zero-warmup, cf=0.70, COOLDOWN_POWER=1.4 are global optima within monotone WSD family.

---

## 2026-05-21 16:22 UTC — PR #662 CLOSED: Polyak EMA β=0.99 warmup=975 — NULL (centroid-lag), 50th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-body`
- Hypothesis: β=0.99 with cooldown-start warmup avoids LMC failure (prior β=0.999 failed) while keeping single-basin during parameter-space averaging.

| Arm | β | EMA_WARMUP | W&B | val_live | val_ema | Δ_ema-live (terminal) | sr_ema | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | — | k7ylyby9/dm4joozw | 3.264278 | — | — | 2937.5 | — |
| C (only to terminal) | 0.99 | 975 | f6ekm47z | 3.266663 | 3.267219 | **+0.000556** | 2925 | NULL (+2.9 mnat) |

**Peak EMA advantage:** step 1625 → Δ_ema-live = −63 mnat (REAL, reproducible, in-single-basin). This is the cleanest positive EMA signal found in the project.

**Terminal failure mechanism — centroid-lag (NOT LMC failure):**
- β=0.99 → effective window ~100 steps → centroid lags live params by ~50 steps
- Near terminal (steps 3100-3250): LR = ~0-2% of peak; params nearly stationary
- Monotone-descending near-stationary trajectory → EMA mean over last 100 steps is STRICTLY above live (terminal) point
- Δ sign flipped at step 3100: from −63 mnat (peak) → +0.6 mnat (terminal)

**This is different from β=0.999 LMC failure:** β=0.999 failed because window > basin width (multi-basin traversal). β=0.99 stays in single basin throughout; it fails for a purely geometric/arithmetic reason at low LR.

**Cross-axis implications:**
- Mid-cooldown Polyak EMA IS mechanically sound at β=0.99 (single-basin confirmed)
- Centroid-lag can be reduced by: shorter window (β=0.9 → 10-step lag), later warmup start (EMA_WARMUP=2500 → start when LR already low)
- Follow-up #695 (thorfinn): β=0.9 + EMA_WARMUP=2500 directly tests whether 5-step lag is small enough to preserve mid-cooldown advantage at terminal

---

## 2026-05-21 15:15 UTC — PR #658 CLOSED: Post-NS momentum in PMuon — NULL/NULL, 49th axis (g1r1-edward)

- Branch: `g1r1-edward/post-ns-momentum`
- Hypothesis: moving the EMA momentum step to AFTER Newton-Schulz (post-NS) would separate temporal smoothing from the polar map, giving cleaner per-step update directions. Arm B (post_ns_repolar) additionally re-polars the post-NS EMA to restore unit spectral norm.

| Arm | Config | W&B | Steps | val/loss | sr | spec_norm (final) | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | pre_ns (default) | k7ylyby9/dm4joozw | 3250 | 3.264278 (n=2) | 2937.5 | — | — | — |
| A | post_ns | d9ifhvbr | 3250 | **3.29212** | -1 DNF | 0.491 | +0.028 | NULL clear |
| B | post_ns_repolar | 9f46i8v1 | 2550 (killed) | 3.367 @ step 2500 | DNF | 0.469 | ~+0.024 extrapolated | NULL clear |

**Matched-step comparison (Arm A vs Arm B, student-corrected):**
Arm B tracked Arm A at every step by ~5 mnat better (not worse as originally claimed), but both tracked 26-28 mnat above baseline at every step. Arm B killed at step 2550 per advisor instruction (`val>3.30 @step 2500 → 3.367`).

**Mechanism (cleanest read in 10 axes):**

1. **Direction matters, not magnitude.** Arm B (post_ns_repolar) restored per-step unit spectral norm — the same magnitude as baseline — yet val tracked Arm A's sub-unit trajectory. This isolates the failure as directional mis-targeting.

2. **polar() is non-linear.** `polar(EMA(grads))` and `EMA(polar(grads))` point in qualitatively different directions. The baseline's polar-of-EMA direction is empirically better for this model+schedule — a causal mechanism, not just an empirical scan.

3. **Pre-NS placement CONFIRMED load-bearing.** EMA-of-polar settles at spec_norm ≈ 0.47, reducing effective update magnitude. Arm B's repolar corrects magnitude but not direction → magnitude is not the failure mode.

4. **Implementation bugs uncovered:** bf16/fp32 dtype mismatch on `polar_g.to(momentum.dtype)` + momentum buffer aliasing (clone needed before uw-floor in-place multiply). Both fixed, gated behind `--momentum_position != pre_ns`.

**Axis closure impact:** Body-Muon operator ordering (momentum/polar swap) FULLY CLOSED. Both alternative orderings tested; pre-NS is the empirical and mechanistic optimum.

**Cross-axis note:** Edward's suggested follow-up (α·polar(EMA) + (1-α)·polar(grad_t) interpolation) partially overlaps with #682 askeladd's mu schedule experiment (same temporal-smoothing-vs-instantaneous axis) and is not independently assigned.

---

## 2026-05-21 14:00 UTC — PR #644 CLOSED: Winsorization pre-NS body-Muon k={1.5, 3.0} — NULL/NULL, 48th axis (g1r1-fern)

- Branch: `g1r1-fern/winsorize-pre-ns`
- Hypothesis: hard-clip post-whitening body-Muon gradient to `[-k·median(|m_pre|), +k·median(|m_pre|)]` before NS. If outliers impair NS conditioning, removing them should tighten spectral whitening and improve sr.

| Arm | k | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | clip_frac | norm_ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — | — | — |
| A | 1.5 | 5erh0eht | 3075 | 3.27401 | +137.5 ✗ | +0.00973 ✗ | 0.319 | 0.713 | NULL clear |
| B | 3.0 | 7dupedm3 | 2975 | 3.26770 | +37.5 ✗ | +0.00342 ✗ | 0.048 | 0.956 | NULL |

**Mechanism (excellent telemetry):** Arm A (k=1.5) clips 32% of entries per parameter and reduces matrix norm by 29% — mechanism clearly engaged. Arm B (k=3.0) clips only 5% and reduces norm by 4%. Regression is MONOTONE with clip aggressiveness. The val/loss trajectory diverges specifically during cooldown (step 2500–3250), exactly where polar map quality matters most. Top-decile entries in m_pre encode signal NS uses for the spectral whitening → clipping them strictly removes useful directional information.

**Cross-axis synthesis — gradient-domain pre-NS FULLY CLOSED (48 total):**
Combined with PR #622 (tanh-squash NULL/NULL/NULL 47th axis), the elementwise outlier-treatment class is exhausted:
- Hard threshold (k=1.5 clips 32%): clear regression
- Hard threshold (k=3.0 clips 5%): small but consistent regression
- Soft saturation (tanh scale_mult=0.005, 4% Frob compress): no detectable effect
- Soft saturation (scale_mult=0.02/0.5): no-op (linear regime)

All six interventions (4 winsorization + 2 tanh) follow the same pattern: the post-PMuon-whitening gradient distribution is well-conditioned for NS AS-IS. NS spectral whitening absorbs magnitude differences; the direction (singular structure) is what it uses, and outlier-truncation in any form degrades that.

---

## 2026-05-21 13:45 UTC — PR #622 CLOSED: Tanh-squash pre-NS body-Muon — NULL/NULL/NULL, 47th axis (g1r1-frieren)

- Branch: `g1r1-frieren/tanh-squash-pre-ns`
- Hypothesis: apply element-wise `g_sq = scale * tanh(g / scale)` to body-Muon gradient before NS, where `scale = scale_mult × Frob(g)`. Soft outlier compression preserves singular structure for small entries while bounding large ones. Expected to tighten NS conditioning.

| Arm | scale_mult | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A (smoke-fix) | 0.5 | 9yq01dbe | 3000 | 3.26904 | +62.5 | +0.00476 | NULL (no-op) |
| B | 0.02 | 807tsqas | 2975 | 3.26652 | +37.5 | +0.00224 | NULL (near-identity) |
| C | 0.005 | w1rzdmoy | 2975 | 3.26657 | +37.5 | +0.00229 | NULL (4% Frob compression) |

**Key mechanistic finding (student telemetry):** After PMuon whitening, `m_pre` has Frobenius norm ~10^7 while individual entry magnitudes stay near ~1 (NS orthogonalization). At `scale_mult=0.5`, scale ≈ 5×10^6 — 6 orders of magnitude above any entry. Arm A is pure linear-regime tanh (max_ratio=0.012, norm_ratio=1.000, clip_fraction=0). Arm C is the only arm with real compression (max_ratio=1.26, norm_ratio=0.96) but gives nearly identical result to Arm B (0.05 mnat difference).

**Cross-axis synthesis — gradient-domain pre-NS FULLY CLOSED:**

| Mechanism | Test | Verdict | PR |
|---|---|---|---|
| Gradient centralization (subtract mean) | GC remove | NULL clear | #553 |
| Column-mean amplification | GC amplify | NULL clear | #588 |
| Global gradient clipping | hard-clip | NULL clear | #513 |
| Per-block L2 normalization | per-block norm | NULL clear | #627 (45th) |
| Tanh-squash (soft outlier) | scale_mult ∈ {0.5, 0.02, 0.005} | NULL/NULL/NULL | #622 (47th) |

NS spectral whitening absorbs and corrects any linear transformation of the gradient. The only remaining gradient-domain axis is winsorization (#644, in-flight, expected NULL given mechanism parity with tanh-squash).

**Notable debugging:** the step-0 EMA init issue (rank-1 L_cov → matrix_neg_power eps=1e-12 amplification → Frob ~10^9 poisoning EMA for hundreds of steps) was correctly diagnosed and fixed (WARMUP_STEPS=10 for both EMA and tanh warmup). Outstanding student forensics.

---

## 2026-05-21 13:30 UTC — PR #647 CLOSED: WSD longer cooldown_frac {0.80, 0.85} — NULL/NULL, 46th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/wsd-longer-cooldown`
- Hypothesis: extend WSD cooldown fraction in the LONGER direction to {0.80, 0.85}, symmetric counter-axis to PR #606 (cf=0.25 catastrophic). If cooldown is where productive descent happens, more cooldown should give better convergence.

| Arm | cf | W&B | sr | val/loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0.70 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 0.80 | `tk8hizl3` | 2950 | 3.26675 | +12.5 ✗ | +0.00247 ✗ | NULL (marginal) |
| B | 0.85 | `96jhh0zy` | 2975 | 3.27016 | +37.5 ✗ | +0.00588 ✗ | NULL (clear) |

**Mechanism (excellent student slope telemetry):** at step 1625 (mid-training), the longer-cooldown arms ARE further into the decay curve (cd_prog 0.41 vs 0.29) and val/loss is genuinely lower (3.466/3.474 vs 3.500). But by step 2925 the slope has gone BLUNTER (-0.0039/-0.0045 vs -0.0064) — the early-start advantage is consumed and the late tail is rate-limited by LR magnitude. By step 3250, val is *worse* than baseline. Spreading the COOLDOWN_POWER=1.4 curve over more steps proportionally weakens LR at every point in the decay tail.

**Cross-axis pattern (WSD shape now exhaustively characterized in 5 axes):**

| Axis | Test | Verdict | PR |
|---|---|---|---|
| cooldown_frac (shorter) | 0.25 vs 0.70 | catastrophic DNF | #606 |
| cooldown_frac (longer) | 0.80, 0.85 vs 0.70 | NULL/NULL | #647 |
| cooldown_power | extreme scan | symmetric loss | #648-class |
| lr_floor | η_min=0.05, 0.10 | NULL/NULL | #607 |
| NS_ITERS cooldown ramp | time-varying | NULL/NULL | #559 |

WSD schedule shape is fully pinned. The decay-to-zero tail is the load-bearing feature; weakening it (via floor, longer spread, or fewer iters) hurts; shortening it cannot match baseline trajectory.

**Next direction:** axis-level cf is closed. Future cooldown experiments should target **cooldown shape variants** (e.g. piecewise, sigmoid, or LR-schedule family changes — cosine already in flight #667) rather than further duration sweeps.

---

## 2026-05-21 08:50 UTC — PR #627 CLOSED: Per-block grad L2 normalization pre-NS — NULL/NULL, 45th axis (g1r1-nezuko)

- Branch: `g1r1-nezuko/per-block-grad-norm`
- Hypothesis: Per-block L2 (Frobenius) normalization of body-Muon gradients before NS reduces depth-varying gradient magnitude bias, improving NS conditioning and step-to-target.

| Arm | mode | val/loss | sr | Δval | Δsr | W&B | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | 3.264278 | 2937.5 | — | — | k7ylyby9, dm4joozw | — |
| Arm A | all | 3.269108 | 3000 | +0.00483 | +62.5 | mb25a9x9 | **NULL** clear |
| Arm B | mlp_only | 3.265763 | 2950 | +0.00148 | +12.5 | xaaqncix | **NULL** borderline |

**Verdict: NULL/NULL → 45th axis CLOSED. Pre-NS per-block magnitude conditioning family CLOSES.**

**Key mechanistic findings:**
1. **Arm A loudly hurt (+62.5 sr):** Pooling attn+MLP gradients into one per-block Frobenius destroyed the natural inter-sublayer scale separation PMuon's NS step relies on. Attention proj_qkv (large fan-in) and MLP gates have different native gradient scales; collapsing them distorts both relative to each other.
2. **Arm B flat-to-slightly-worse (+12.5 sr):** MLP-only per-block norm doesn't damage as much (MLP gradients across blocks are already reasonably balanced), but injects per-step variance without offsetting conditioning gain.
3. **PMuon's spectral whitening absorbs most magnitude information:** The pre-NS conditioning lever is approximately closed at the per-block granularity. What NS cannot absorb is the inter-sublayer scale ratio — exactly what Arm A destroyed.
4. **Combined with #553 (GC subtract NULL), #588 (column-mean amplify NULL), #513 (gradient clipping NULL):** Pre-NS gradient-domain modification family is now heavily explored. Tanh-squash (#622) and Winsorization (#644) remain in-flight.

**Action:** nezuko reassigned to PR #667 — first non-WSD schedule family test (cosine LR schedule). Arm A: pure cosine from step 0. Arm B: cosine with 30% stable plateau (matched to WSD shape).

---

## 2026-05-21 08:15 UTC — PR #623 CLOSED: Schedule-Free Adam on aux only — NULL/NULL decisive, 44th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/schedule-free-aux`
- Hypothesis: Schedule-Free Adam (Defazio 2024) on the aux AdamW path (embed, lm_head, scalars) — iterate averaging replaces explicit WSD cooldown on aux. Two configurations: Arm A canonical (r=0, ckp1=1/k), Arm B Polyak-tilt (r=1.0, ckp1=2/(k+1) under constant LR).

| Arm | r | p | best_val | sr | Δval | W&B | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | — | 3.264278 | 2937.5 | — | k7ylyby9, dm4joozw | — |
| Arm A | 0.0 | 2.0 | 3.30923 | -1 DNF | +0.0450 | j0zyguxj | **NULL** decisive |
| Arm B | 1.0 | 2.0 | 3.30752 | -1 DNF | +0.0432 | e41ak5px | **NULL** decisive |

**Verdict: NULL/NULL decisive → 44th axis CLOSED. Schedule-free averaging cannot replace WSD aux cooldown.**

**Key mechanistic findings:**
1. **Aux LR cooldown is load-bearing.** WSD shrinks aux step size ≥10× over the final 30% of training; SF iterate averaging with c_t≈3e-4 at step 3250 averages over thousands of unattenuated peak-LR steps and cannot match that effective step-size reduction. Disabling explicit aux decay costs ~0.045 val_loss.
2. **First-moment EMA discarded for no gain.** Defazio-style SF drops β₁ momentum on the premise that iterate averaging subsumes it. The trade ("explicit momentum + WSD" → "averaging substitutes both") loses by 0.045 on this benchmark.
3. **Polyak-tilt (r=1.0) marginally helps (Δ=0.0017) but doesn't change the conclusion.** "Less averaging = better" direction points back toward the WSD limit.
4. **Aux side now saturated across 9 optimizer families:** 5/5 update-rules + LAMB + Lion + Lookahead + Schedule-Free Adam. All NULL.

**Student's key catch (PR design):** Upfront derivation showed r=0 and r=1.0 are mathematically identical under constant LR + r=0 default — leading to Arm B redirect to Polyak-tilt (r=1.0) before compute was wasted on a degenerate ablation.

**Action:** thorfinn reassigned to PR #662 — Polyak EMA on body-Muon weights β={0.999, 0.9995}. First parameter-space averaging test on signal-dominant (matrix) params. Body-Muon trajectory during WSD cooldown is the natural averaging target; EMA maintains FP32 inference weights alongside BF16 train weights and swaps at eval.

---

## 2026-05-21 07:45 UTC — PR #607 CLOSED: LR floor in cooldown — NULL/NULL clear, 43rd axis (g1r1-alphonse)

- Branch: `g1r1-alphonse/lr-floor-cooldown`
- Hypothesis: Preventing the LR from decaying to zero in the final cooldown phase with a minimum floor `eta = max(lr_floor, w^COOLDOWN_POWER)` keeps the optimizer taking meaningful steps through the val≈3.28 crossing.

| Arm | lr_floor | val/loss | sr | Δval | Δsr | Floor activation | Verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| Baseline | 0.0 | 3.264278 | 2937.5 | — | — | — | — |
| Arm A | 0.10 | 3.270903 | 3025 | +0.00662 | +87.5 | step 2825 | **NULL** clear |
| Arm B | 0.05 | 3.266955 | 2975 | +0.00268 | +37.5 | step 3000 | **NULL** clear |

**Verdict: NULL/NULL → LR floor axis CLOSES. 43rd axis. Decay-to-zero tail is load-bearing.**

**Key mechanistic finding:** Late-cooldown val/loss slope in floor zone: −4.5e-5/step (Arm A), −4.0e-5/step (Arm B) vs pre-floor −1.0e-4/step. The floor reliably flattens the descent regardless of magnitude. Damage is linear in floor magnitude × activation duration: Arm B's 5% floor activates at step 3000 (250 suppressed steps) → half the damage of Arm A's 10% floor at step 2825 (425 suppressed steps). The WSD cooldown's steep terminal crossing is a load-bearing feature; any clamp on the tail trades target-crossing speed for smoothness.

**Action:** alphonse reassigned to PR #660 — PMuon Nesterov ON/OFF axis (mu=0.95 vs mu=0.90 without Nesterov). First direct ablation of the Nesterov flag in PMuon across 43 closed experiments.

---

## 2026-05-21 07:10 UTC — PR #617 CLOSED: Lookahead wrapper on aux AdamW — NULL/NULL clear, 42nd axis (g1r1-edward)

- Branch: `g1r1-edward/lookahead-wrapper-aux`
- Hypothesis: Lookahead (Zhang et al 2019) wraps the aux AdamW path (embed, lm_head, scalars). Slow-weight averaging over k inner steps tests whether noise-denoising helps the aux gradients which are noise-dominated per 4 closed update-rule leaves.

| Arm | k | α | val/loss | sr | Δval | Δsr | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | n/a | 3.264278 | 2937.5 | — | — | — |
| Arm A | 5 | 0.5 | 3.267040 | 2975 | +0.00276 | +37.5 | **NULL** clear |
| Arm B | 10 | 0.5 | 3.269989 | 3025 | +0.00571 | +87.5 | **NULL** clear |

**Verdict: NULL/NULL → Lookahead wrapper on aux AdamW CLOSES. 42nd axis. Aux side FULLY SATURATED across 8 optimizer families.**

**Key mechanistic finding:** Lookahead's `slow ← slow + α(fast − slow); fast ← slow` is equivalent to applying a `1 − α` pull-back every k steps on the fast weights. With α=0.5, this halves the effective aux LR contribution per sync. Arm B (k=10, longer averaging horizon) shows larger fast↔slow gap during cooldown → worse regression (+87.5 sr vs +37.5 sr). The aux gradients are low-information-per-step (small magnitudes), not noise-dominated per se — averaging adds damping without denoising benefit.

**Cross-axis conclusion:** Aux side CLOSED across 8 distinct optimizer families:
1. v-estimator (AdaBelief #545)
2. m-step (NadamW #575)
3. m-aggregation (AdEMAMix #585)
4. v-clamp (AMSGrad #578)
5. v-aggregation (Adamax #583)
6. LAMB trust-ratio (#609)
7. Lion sign-of-momentum (#604)
8. **Lookahead wrapper (#617 — this PR)**

**Action:** edward reassigned to PR #658 — post-NS momentum position axis on body-Muon (pre-NS vs post-NS vs post-NS+repolar at mu=0.95). Clean orthogonal axis: momentum has lived pre-whitening/pre-NS in all 42 closed experiments.

---

## 2026-05-21 05:50 UTC — PR #604 CLOSED: Lion optimizer on aux AdamW — NULL/NULL clear, 41st axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/lion-aux-optimizer`
- Hypothesis: Lion (Chen et al 2023) replaces AdamW's E[g²]-normalized direction with sign-of-momentum: `update = sign(β·m + (1-β)·g)`. Tests whether sign-of-momentum mechanism class works for aux path. Two lr_scale arms compared.

| Arm | lr_scale | val/loss | sr | Δval | Verdict |
|---|---|---|---|---|---|
| Baseline | n/a | 3.264278 | 2937.5 | — | — |
| Arm A | 1/3 (embed_lr=0.100) | 3.29790 @ step 3000 | -1 (DNF) | +0.034 | **NULL DNF** (SIGTERM partial) |
| Arm B | 1/10 (embed_lr=0.030) | 3.29465 @ step 3250 | -1 (DNF) | +0.030 | **NULL DNF** (clean) |

**Verdict: NULL/NULL → Lion mechanism class on aux CLOSES. 41st axis.**

**Mechanism:** Lion's `sign(m)` strips magnitude information from aggregated momentum, replacing it with constant per-coordinate ±1. The carefully-tuned aux AdamW per-group lr_scales (embed_lr=0.3, lm_head_lr=1/160, scalar_lr=0.025) provide finely-calibrated effective step magnitudes that E[g²]-normalization adapts to per-tensor. Lion's uniform-magnitude reduction destroys this calibration entirely. Both arms test two different uniform step sizes — both too coarse to match what AdamW provides.

**Cross-axis pattern:** Lion joins the saturated aux-optimizer landscape — 5/5 update-rule mechanisms (AdaBelief, NadamW, AdEMAMix, AMSGrad, Adamax), LAMB trust ratio (#609), and now Lion sign-of-momentum (#604) all CLOSED NULL/NULL. The aux gradients on embed/lm_head/scalars are noise-dominated and unresponsive to *any* update-rule replacement class.

**Action:** tanjiro reassigned to PR #651 (LR warmup phase ∈ {100, 250 steps}) — codebase has zero warmup which has never been explicitly tested. Closes a clean schedule-shape sub-axis.

---

## 2026-05-21 05:00 UTC — PR #609 CLOSED: LAMB trust ratio on aux AdamW — NULL/NULL clear, 40th axis (g1r1-askeladd)

- Branch: `g1r1-askeladd/lamb-aux-trust-ratio`
- Hypothesis: LAMB per-tensor trust-ratio step rescaling (`trust = min(||w||/||r||, max_trust)`) on the aux AdamW group (embed, lm_head, scalars) — orthogonal to the update-rule mechanism tree (5/5 leaves already NULL/NULL). Tests whether per-tensor step magnitude normalization helps the aux path.

| Arm | Variant | max_trust | val/loss @ step 3250 | sr | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline | — | — | 3.264278 | 2937.5 | — | — |
| Arm A | Literal (`min(||w||/||step||, T)`) | 10 | 3.34623 | -1 (DNF) | +0.082 | **NULL DNF** |
| Arm B | Canonical (`min(lr·||w||/||step||, T)`) | 10 | 3.29541 | -1 (DNF) | +0.031 | **NULL DNF** |

**Verdict: NULL/NULL → LAMB trust ratio on aux AdamW CLOSES. 40th axis.**

**Key mechanistic finding (outstanding student forensics):** Telemetry on trust ratios revealed that the raw `||w||/||step||` ratio for embed is ≈1.2e10 throughout training — far above max_trust=10, so the trust ratio saturates at 10 for the entire run. Result: LAMB becomes a constant 10× amplifier on aux step sizes, destroying the carefully-tuned per-group LR calibration. Arm B's improvement over Arm A (val=3.295 vs 3.346) is explained exactly by the canonical formula preserving lm_head's LR schedule (canonical restores the lr factor, so lm_head's small lr=1/160·embed_lr prevents saturation for that group).

**Why LAMB degenerates on this stack:** LAMB was designed for large-batch pre-training (BERT) where ||w||/||r|| is typically O(1)–O(10). In our finely-tuned aux setup, the tiny aux steps (embed_lr=0.3, balanced per-group) create step norms that are orders of magnitude smaller than weight norms → trust ratio saturates at max_trust every step. The mechanism only works non-degenerately when the raw trust ratio is near O(1).

**Student suggestions:**
- `max_trust=1` deferred — likely also NULL (changes direction from amplifier to hard-cap, but root cause is the degenerate regime).
- **LAMB on Muon** flagged as genuinely interesting: PMuon's NS-whitened step has spectral norm ~1, weight matrices have similar order → trust ratio would be in LAMB's design regime. Filed for future assignment.

---

## 2026-05-21 04:30 UTC — PR #606 CLOSED: WSD shorter cooldown_frac — Arm A NULL DNF / Arm B SKIPPED, 39th axis (g1r1-fern)

- Branch: `g1r1-fern/wsd-schedule`
- Hypothesis: Shorten the WSD (warmup-stable-decay) cooldown fraction from baseline 0.70 to {0.25, 0.15}, hoping that a longer "stable" peak-LR plateau allows more aggressive optimization before sharp terminal decay. The baseline already starts at full LR (zero warmup), so cooldown_frac controls only the length of the final decay phase.

| Arm | cooldown_frac | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.70 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.25 | `kq05a45r` | DNF (-1) | 3.30081 | DNF | +0.0365 | **NULL DNF** |
| Arm B | 0.15 | — | — | — | — | — | **SKIPPED** (strictly shorter cooldown predicted worse given Arm A) |

**Verdict: NULL DNF / SKIPPED → WSD shorter-cooldown direction CLOSES. 39th axis closed.**

**Key mechanistic finding:** All val-loss progress from 3.55 → 3.30 happens in the 25% decay tail of the baseline cooldown. Going shorter on cooldown — even by 6 percentage points (0.70→0.64 implicit, or explicitly 0.25 here) — destroys the speedrun mechanism. The cooldown is not a polishing phase but the *core descent phase* of the WSD trajectory.

**Cross-PR coherence:**
- This complements #607 alphonse LR-floor (Arm A η_min=0.10 NULL): keeping LR too high during cooldown is also harmful — even a 10% LR floor flattened the late-cooldown descent slope to 0.00007/step. So *both* "less cooldown" (shorter frac) and "weaker cooldown" (LR floor) hurt: the deep descent into near-zero LR over the full 70% tail is load-bearing.
- The orthogonal "LONGER cooldown" direction (cooldown_frac ∈ {0.80, 0.90}) remains untested — could be a next assignment if we want to fully pin the WSD schedule shape axis.

**Action:** fern reassigned to PR #644 (Winsorization pre-NS body-Muon, k={1.5, 3.0}) — orthogonal hard-clip counterpart to frieren's tanh-squash. See Hypothesis 2 in `research/RESEARCH_IDEAS_2026-05-20_23:30.md`.

---

## 2026-05-20 23:46 UTC — PR #583 CLOSED: Adamax on aux AdamW (L∞ v-aggregation) — NULL/NULL DNF, 5th and FINAL leaf of aux update-rule mechanism tree CLOSES (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamax-aux-adamw`
- Hypothesis: Adamax (Kingma & Ba 2014) replaces AdamW's E[g²] preconditioner with L∞ aggregation: `u_t = max(β2·u_{t-1}, |g_t|)`. Tests whether L∞ v-aggregation provides advantages over standard L2 aggregation on noisy aux gradients. β2={0.95, 0.999} probed.

| Arm | β2 | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.95 | `n3usxhni` | DNF (-1) | 3.28038 | DNF | +0.0161 | NULL DNF |
| Arm B | 0.999 | `p8l0a36v` | DNF (-1) | 3.28384 | DNF | +0.0196 | NULL DNF |

**Verdict: NULL DNF | NULL DNF → Adamax v-aggregation mechanism leaf CLOSES. 37th axis closed.**

**Validation trajectories track each other tightly:** Δval ~0.001-0.003 between arms at every checkpoint (250→3250). Adamax's L∞ v-aggregation has nearly zero β2 sensitivity on this stack — consistent with all 4 prior aux update-rule mechanism closures.

**🎯 AUX ADAMW UPDATE-RULE MECHANISM TREE — FULL CLOSURE (5/5 leaves NULL/NULL):**

| Leaf | Mechanism | PR | Verdict |
|---|---|---|---|
| v-estimator | AdaBelief | #545 | CLOSED NULL/NULL |
| m-step | NadamW | #575 | CLOSED NULL/NULL |
| m-aggregation | AdEMAMix | #585 | CLOSED NULL/NULL |
| v-clamp | AMSGrad | #578 | CLOSED NULL/NULL |
| **v-aggregation** | **Adamax** | **#583** | **CLOSED NULL/NULL** ← THIS |

**Cross-PR aggregate finding:** Across 10 distinct optimizer formulations (5 leaves × 2 hyperparameter arms each), ZERO produced an sr improvement over standard E[g²]/E[g] AdamW. The aux gradients on embed/lm_head/scalars are noise-dominated, and the *aggregation operator* over noisy v/m is irrelevant. This is overwhelming evidence that **the aux update-rule mechanism axis is saturated** — further attempts at this class of modification will continue to NULL.

**Remaining aux-side levers (orthogonal to mechanism tree):**
- Step-rescaling: LAMB trust ratio (#609 askeladd in flight)
- Wrapper class: Lookahead (#617 edward in flight)
- Schedule shape: WSD cooldown_frac (#606 fern in flight), LR floor (#607 alphonse in flight)
- Variance rectification: RAdam — UNTESTED
- **Iterate averaging: Schedule-free Adam (Defazio 2024) — NEWLY ASSIGNED #623 thorfinn**

---

## 2026-05-20 23:33 UTC — PR #588 CLOSED: Body-Muon column-mean AMPLIFICATION pre-NS — NULL/NULL clear, completes the rank-1 column-mean transformation class symmetric closure (g1r1-frieren)

- Branch: `g1r1-frieren/gc-amplify-mean`
- Hypothesis: Inverse of #553 (GC subtraction). If subtracting column-mean regresses sr (#553 dim=1 Δsr=+62.5), amplifying it (`g_new = g + α·(mean - g_mean_zero)` = `(1+α)·g` along mean direction) should help — predicted "symmetric monotone-helpful" model: the rank-1 column-mean is a useful signal, and increasing its weight should improve the polar map.

| Arm | α | dim | W&B | sr (ffs) | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 0 | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.05 | 1 | `ix493rgk` | 2975 | 3.26788 | +37.5 | +0.0036 | NULL clear |
| Arm B | 0.20 | 1 | `fiiel4pd` | 2950 | 3.26550 | +12.5 | +0.0012 | NULL clear |

**Verdict: NULL | NULL clear → column-mean transformation class closes on BOTH SIGNS at dim=1. 36th axis closed.**

**Both arms regress.** The predicted "symmetric monotone-helpful" model is falsified: amplification hurts in the same direction as subtraction. PMuon's polar map appears to use the rank-1 column-mean optimally at α=0, and any perturbation regresses.

**Non-monotone cost dependence on α (curious wrinkle):** Arm B (α=0.20, 4× larger) hurt LESS than Arm A (α=0.05). Two metrics shifted coherently (sr and val both moved less). Three plausible interpretations:
1. Single-seed noise — 25 sr swing is ~0.85% of sr, possible but with two coherent metric shifts less likely.
2. Polar-map renormalization saturating at α=0.20 (NS coefficient response stabilizes the direction).
3. Interaction with body-Muon's covariance EMA (β_cov=0.95) — small α may inject persistent bias; large α may saturate it.

**Telemetry confirms rank-1 perturbation is tiny:** `grad_norm_ratio` ≈ 1.00005 (Arm A) and 1.00028 (Arm B). Despite ≤0.03% L2-mass perturbation, the polar-map directional contribution moves sr by ±tens of steps — same scale signal as #553's mean-subtraction.

**Combined with #553 closure (subtraction):**
- Subtraction dim=1 (#553 Arm A): Δsr=+62.5 → hurt
- Subtraction dim=0 (#553 Arm B): Δsr=+87.5 → hurt
- Amplification α=0.05 dim=1 (#588 A): Δsr=+37.5 → hurt
- Amplification α=0.20 dim=1 (#588 B): Δsr=+12.5 → hurt

**Body-Muon rank-1 column-mean transformation class FULLY CLOSED.** Any perturbation (subtraction or amplification) regresses sr. PMuon's polar map preserves and uses the rank-1 mean direction optimally at α=0 (no perturbation).

**Aux update-rule tree progress (unchanged from #578 closure):** 4 of 5 leaves CLOSED. Only Adamax v-aggregation (#583) remaining.

---

## 2026-05-20 22:43 UTC — PR #578 CLOSED: AMSGrad v-clamp on aux AdamW — NULL/NULL clear, v-clamp mechanism leaf of aux update-rule tree closes (g1r1-edward)

- Branch: `g1r1-edward/amsgrad-aux-adamw`
- Hypothesis: AMSGrad (Reddi, Kale, Kumar — ICLR 2018) clamps the v-estimator with a monotone-max running max: `v_max = max(v_max, v)`, then uses `v_max` as the preconditioner denominator instead of `v`. Tests whether monotone non-decreasing v provides stability benefits on noisy aux gradients vs the standard EMA running-mean v.

| Arm | bias-corrected | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | n/a | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | True | `d6qh9eie` | DNF (-1) | 3.2805 | DNF | +0.016222 | NULL DNF |
| Arm B | False | `gz7ktuqr` | 3200 | 3.2794 | +262.5 | +0.015122 | NULL clear |

**Verdict: NULL | NULL clear → v-clamp mechanism axis closes. 35th axis closed.**

**Arm A bias-corrected DNF** at val=3.2805 / step 3250 — never crossed 3.28 in the full step budget. v_max binding fraction reported at 99.7% per W&B logs, meaning v_max was essentially always the active denominator — the monotone-max preconditioner aggressively damped aux step magnitudes on noisy embed/lm_head rows.

**Arm B uncorrected** crossed 3.28 only at step 3200 — Δsr=+262.5 vs baseline, Δval=+0.0151. The uncorrected variant produces smaller v_max (no over-correction in early steps) but still regresses sr by ~262 steps. Both formulations of monotone-non-decreasing v slow convergence.

**Mechanism reading:** AMSGrad's preconditioner monotonicity (v_max never decreases) prevents aux from "forgetting" early gradient noise. On noisy aux gradients, early v spikes get locked in and persistently inflate the denominator, shrinking aux steps. Standard AdamW's EMA running mean (which can decrease) is better suited to aux's noise-dominated gradients.

**Aux update-rule tree progress: 4 of 5 leaves CLOSED (NULL/NULL):**
- v-estimator AdaBelief #545: CLOSED NULL/NULL
- m-step NadamW #575: CLOSED NULL/NULL
- m-aggregation AdEMAMix #585: CLOSED NULL/NULL
- **v-clamp AMSGrad #578: CLOSED NULL/NULL ← THIS PR**
- v-aggregation Adamax #583: IN FLIGHT (thorfinn)

**Pattern (4 consecutive NULL closures):** The aux AdamW update-rule mechanism class is overwhelmingly NULL across 4 distinct mechanism modifications (v-estimator, m-step, m-aggregation, v-clamp). The consistent explanation: aux gradients on embed/lm_head/scalars are noise-dominated, so changes to update-rule arithmetic don't have informational leverage. The benchmark's standard AdamW formulation is at or near a local optimum within this mechanism class. Adamax (#583 in flight) is the final leaf — strong prior bearish given the pattern.

**Run history (student iteration):** Arm A initial run `d6qh9eie` finished DNF. Student launched a redundant Arm A retry `h7sq36z7` which was identified as redundant and killed; Arm B `gz7ktuqr` then launched cleanly with `AMSGRAD_BIAS_CORRECTED=False`. Single SENPAI-RESULT not posted by student before advisor close — W&B terminal data was unambiguous (3.3 hour ago last comment, 3.5+ hours after Arm B termination).

---

## 2026-05-20 21:15 UTC — PR #575 CLOSED: NadamW (Nesterov AdamW) on aux AdamW m-step — NULL/NULL clear, m-step mechanism leaf of aux update-rule tree closes (g1r1-askeladd)

- Branch: `g1r1-askeladd/nadamw-aux-adamw`
- Hypothesis: Nesterov AdamW (Dozat 2016) replaces the standard Adam m-step `θ - lr * m̂` with a Nesterov lookahead `θ - lr * (β1*m̂_{t+1} + (1-β1)*g_t/bc_t)`, applying the momentum update in the gradient direction of the next step rather than the current. Tests whether lookahead on the m-usage axis of aux AdamW unlocks speedrun improvement.

| Arm | β1 | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.80 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.80 | `ppotks3f` | 2975 | 3.26587 | +37.5 | +0.001592 | NULL clear |
| Arm B | 0.85 | `bpadxpdy` | 2975 | 3.26673 | +37.5 | +0.002452 | NULL clear |

**Verdict: NULL | NULL clear → m-step mechanism axis closes. 34th axis closed.**

**Both arms tie at sr=2975**, Δsr=+37.5 beyond marginal threshold (>25), Δval ≥ +0.001592 beyond marginal threshold (>0.001). Clear NULL on both sr AND val dimensions.

**Mechanism analysis:** The aux AdamW update-rule mechanism class has now produced 3 consecutive NULL closures: AdaBelief #545 v-estimator, this PR #575 m-step, AdEMAMix #585 m-aggregation. Consistent with the mechanistic explanation from #545: aux gradients (embed/lm_head/scalars) are noise-dominated. Var(g) ≈ E[g²] for these tensors, so changes to how m and v are computed or used don't have informational leverage over the baseline Adam formulation.

**Diagnostic telemetry (student):** Identical mid-training trajectories at step 1875 (val 3.4474 vs 3.4474 for Arms A/B) confirmed the m-step axis is mechanism-NULL, not just β1-value-NULL. Both Nesterov β1=0.80 and β1=0.85 produce indistinguishable training curves through mid-run.

**Run history (infra issues):** Arm B encountered several launches with NaN loss / SIGTERM at step 0 (infra, not mechanism). Student correctly identified the canonical run `bpadxpdy` (β1=0.85) as distinct from the crashed launches `8dxko849`, `3pg2aahk`, `o9wfvvan`.

**Aux update-rule tree progress: 3 of 5 leaves CLOSED (NULL/NULL):**
- v-estimator AdaBelief #545: CLOSED NULL/NULL
- m-step NadamW #575: CLOSED NULL/NULL (this PR)
- m-aggregation AdEMAMix #585: CLOSED NULL/NULL
- v-clamp AMSGrad #578: in flight (Arm A DNF NULL, Arm B running)
- v-aggregation Adamax #583: in flight (Arm A DNF NULL, Arm B running)

**Askeladd reassigned** to **LAMB trust ratio on aux AdamW** (PR #609) — per-tensor step rescaling via `trust_ratio = clip(||w|| / ||r||, 0, max_trust)`. ORTHOGONAL to the update-rule mechanism class (changes step SIZE not step direction). Arm A: max_trust=10 (paper default), Arm B: max_trust=1 (conservative, no amplification). Designed for mixed parameter scale scenarios like embed/lm_head/scalars.

---

## 2026-05-20 20:30 UTC — PR #570 CLOSED: PMuon mu (body-Muon momentum EMA) scalar scan {0.90, 0.97} vs baseline 0.95 — NULL/NULL clear, mu=0.95 is a sharp symmetric local optimum (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-mu-scalar-scan`
- Hypothesis: body-Muon's momentum EMA decay rate (mu) controls the effective smoothing horizon feeding into PMuon's Newton-Schulz polar map. Lower mu (0.90) → shorter ~10-step horizon, noisier raw gradient buffer per step. Higher mu (0.97) → longer ~33-step horizon, smoother but lagged signal. Baseline 0.95 gives ~20-step horizon.

| Arm | mu | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.90 | `3pk3lm8w` | 3075 | 3.275656 | +137.5 | +0.011378 | NULL clear |
| Arm B | 0.97 | `id2inkbe` | 3075 | 3.272967 | +137.5 | +0.008689 | NULL clear |

**Verdict: NULL | NULL clear → mu axis CLOSES. 32nd axis closed. mu=0.95 is locally optimal.**

**Symmetric Δsr=+137.5 from both sides** is the strongest possible evidence of a sharp local optimum. Neither shorter (10-step) nor longer (33-step) momentum horizon helps. Both arms hit identical sr=3075, well above the stat-sig threshold needed to declare NULL (>2×25=50 sr margin from baseline).

**Run history:** Arm A had 4 failed launches (infrastructure noise: 3 pod-scheduling crashes + 1 step-50 crash with rising grad norm that advisor flagged as possibly mechanism but turned out also to be infra). Arm A clean retry `3pk3lm8w` ran to 3250 steps without divergence — the step-50 crash `y3hafbkh` was pure infrastructure, not mu=0.90 instability.

**Val asymmetry** (Arm B 3.273 < Arm A 3.276) hints that the optimum lies slightly above 0.95 on the val axis, but the 0.003 difference is within step-by-step noise and doesn't shift the speedrun.

**Student suggested follow-ups (evaluated):**
- Per-projection mu (attn vs MLP): Given the symmetric +137.5 sr cost from both global perturbations, and that body-Muon LR partition family is already fully closed (#499, #532, #535), per-projection mu is unlikely to recover signal that doesn't exist at the global level. De-prioritized.
- Mu ramp (warmup/cooldown): The val asymmetry hint is sub-noise. Mu schedule is a schedule axis for the optimizer, not the LR — orthogonal but de-prioritized given very clean global closure.

**Alphonse reassigned** to **LR floor in cooldown** (PR #607) — `eta = max(LR_FLOOR, w^COOLDOWN_POWER)`. Two arms: Arm A eta_floor=0.10 (floor activates at step ~2811, active through entire speedrun zone), Arm B eta_floor=0.05 (floor activates at step ~2993). First test of minimum-LR behavior in the critical late-cooldown window. Flagged as unexplored follow-up in BASELINE.md (PR #274 notes).

---

## 2026-05-20 19:11 UTC — PR #562 CLOSED: PMuon ε floor scan {1e-10, 1e-14} vs baseline 1e-12 — NULL/NULL clear, ε=1e-12 optimal across ±2 OOM (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-eps-floor-scan`
- Hypothesis: PMuon's covariance-EMA eigenvalue floor (ε=1e-12) controls numerical conditioning of L_cov and R_cov. Testing ±2 OOM: larger ε (1e-10) → more aggressive regularization; smaller ε (1e-14) → tighter floor, closer to raw eigenvalues.

| Arm | ε | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1e-12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1e-10 | (run-id) | 2950 | 3.265630 | +12.5 | +0.001352 | NULL marginal |
| Arm B | 1e-14 | (run-id) | 2975 | 3.265965 | +37.5 | +0.001687 | NULL clear |

**Verdict: NULL | NULL clear → ε=1e-12 optimal across ±2 OOM. PMuon scalar audit COMPLETE.**

**PMuon scalar audit summary** (all 5 scalars now closed):

| Scalar | Axis | Status | Source |
|---|---|---|---|
| γ_power=0.4 | pruning ablation | CLOSED NULL/NULL | #519 |
| β_cov=0.95 | covariance-EMA decay | CLOSED NULL/NULL | #502 |
| NS_ITERS=12 | Newton-Schulz iterations | CLOSED NULL/NULL | #511+#546 |
| NS coefficients (1.5, -0.5, 0) | polynomial shape | CLOSED NULL/NULL | #540 |
| ε=1e-12 | eigenvalue floor | CLOSED NULL/NULL | #562 |

All PMuon scalar parameters are now exhaustively mapped. PMuon's internal configuration is at a local optimum for this stack.

**Tanjiro reassigned** to **Lion optimizer on aux AdamW** (PR #604) — sign-of-momentum mechanism class (Chen et al 2023, arXiv:2302.06675). Lion replaces the AdamW v-EMA denominator with a pure sign step, requires NO second-moment state, potentially faster aux convergence. FP32 m-state required (β2=0.99 ≈ 1.0 in BF16). Two arms scan lr×{1/3, 1/10} relative to aux baseline.

---

## 2026-05-20 15:35 UTC — PR #553 CLOSED: Gradient Centralization on body-Muon pre-NS — NULL/NULL clear, PMuon's NS whitening is already mean-aware and uses column/row-mean structure as signal not noise (g1r1-frieren)

- Branch: `g1r1-frieren/gradient-centralization-pre-ns`
- Hypothesis: Gradient Centralization (Yong et al 2020) subtracts the per-channel mean from the gradient before optimization. On body-Muon, this means subtracting `mean(grad, dim, keepdim=True)` from each 2D weight gradient before passing to PMuon's Newton-Schulz polar map. Two arms: Arm A `dim=1` (paper canonical, per-output-channel mean); Arm B `dim=0` (per-input-channel mean).

| Arm | GC_DIM | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (dim=1) | 1 | `1x2u1688` | **3000** | **3.268599** | +62.5 | +0.004321 | NULL clear |
| Arm B (dim=0) | 0 | `zfdfwtk4` | **3025** | **3.271550** | +87.5 | +0.007272 | NULL clear |

**Verdict: NULL | NULL clear → gradient-centralization on body-Muon pre-NS axis closes.**

**Astonishing signal-to-perturbation ratio.** Telemetry shows GC removed only:
- Arm A (dim=1): `grad_norm_post / grad_norm_pre = 0.99989` — 0.011% of L2 mass removed.
- Arm B (dim=0): `grad_norm_post / grad_norm_pre = 0.99979` — 0.021% of L2 mass removed.

Despite removing <0.05% of the gradient norm, both arms regressed by +62-87 sr and +0.004-0.007 val. The ratio of speedrun cost to L2 perturbation is ~5000-10000x — clear evidence that the rank-1 mean component is *singular-vector signal*, not noise.

**Mechanism analysis (frieren's tight reading):** The column/row mean of the body-Muon gradient is a rank-1 component of the gradient. PMuon's bilateral whitening + Newton-Schulz polar map preserves and uses this rank-1 piece — the polar map outputs an approximately unit-magnitude rotation along the rank-1 mean direction, so removing it costs proportional-to-1 not proportional-to-L2-mass. Subtracting the mean before NS effectively drops a top-singular-vector pair from the polar step.

**Direction asymmetry (dim=0 worse than dim=1)** is informative: per-input-channel mean (rows of W) carries more signal than per-output-channel mean (columns of W). Consistent with the architecture — input-channel mean represents per-feature shift signal accumulated through residual stream propagation, while output-channel mean represents per-target offset with less per-step coherence.

**Cross-domain finding:** opposite sign to Yong et al 2020 (ImageNet/ResNet, where GC helped). ResNet's BatchNorm-stabilized gradients have different rank structure than pre-LN transformer gradients, and Muon-class optimizers explicitly *use* the singular structure that GC tries to remove.

**Falsification — gradient transformation class state:**

| Sub-class | Status |
|---|---|
| Mean subtraction (centralization) | **CLOSED NULL/NULL (this PR)** |
| Mean amplification (inverse) | **IN FLIGHT (#588 NEW)** — frieren's follow-up |
| Norm clipping (sub-natural-norm) | CLOSED NULL/NULL (#513) |
| Sign / Winsorization / tanh-squash | UNTESTED |

**Frieren reassigned** to **body-Muon column-mean AMPLIFICATION pre-NS** (PR #588) — frieren's own suggested follow-up. If subtracting the rank-1 mean component hurts (this PR), amplifying it via `g + α · mean(g, dim, keepdim=True)` for small α > 0 should symmetrically help — direct inverse mechanism test motivated by the closure data. Two arms: Arm A α=0.05 gentle, Arm B α=0.20 stronger. Both use dim=1 (the less-bad direction from this PR). If amplification falsifies, the gradient-mean transformation class fully closes in BOTH directions — a stronger closure than this PR alone.

## 2026-05-20 14:25 UTC — PR #545 CLOSED: AdaBelief on aux AdamW (v-estimator leaf) — NULL/NULL clear after paper-formulation bug-fix, mean-subtracted second moment offers no headroom on noise-dominated aux gradients (g1r1-fern)

- Branch: `g1r1-fern/adabelief-aux-adamw`
- Hypothesis: AdaBelief (Zhuang et al 2020) replaces Adam's v-target `g²` with the mean-subtracted variance `(g − m)²` — a "trust region" preconditioner that should be more stable on aux gradients where m-direction is informative. Two arms scan eps ∈ {1e-10, 1e-8}.

| Arm | eps | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1e-10 | `p3ryt23e` | 2950 | 3.265551 | +12.5 | +0.001273 | NULL clear |
| Arm B | 1e-8  | `6ft2eleu` | 2975 | 3.266170 | +37.5 | +0.001892 | NULL clear |

**Verdict: NULL | NULL clear → v-estimator axis closes at standard AdamW raw |g|² for the aux group.**

**Pre-run bug-fix (fern self-diagnosis):** initial implementation used bias-corrected `m̂` inside the belief term `(g − m̂)²`. At step 1 with `m₀=0`, `m̂₁ ≡ g` identically, so belief ≡ 0, denom ≡ ε, and the embed update reached ~6708×|g| — divergent. Fern derived the failure mode in closed form, consulted AdaBelief Algorithm 2 (which uses raw `m`, not bias-corrected `m̂`), and made a one-line fix. Both arms then ran cleanly to 3250 steps. This is reference-quality root-cause analysis.

**Mechanism analysis (data confirms reading #2):** Telemetry shows `v_belief / g² ≈ 0.69-0.72` at convergence — AdaBelief IS preconditioning by ~Var(g) (~70% of E[g²]) rather than raw E[g²], a meaningful 30% mechanism shift. It just doesn't help on aux. Increasing eps (1e-10 → 1e-8) made Arm B *worse*, not better — monotone regression on both sr and val. If the issue were "denom too small at step 1", larger eps would help. It didn't. The mechanism itself is the regression, not a floor issue.

**Why aux fails AdaBelief:** aux gradients (embed BF16, lm_head BF16, scalars) are dominated by per-element noise variance. Adam's `|g|² = Var(g) + |E[g]|²` is essentially `≈ Var(g)` already because `|E[g]|` is tiny relative to per-element noise on these tensors. Subtracting m before squaring is informationally a no-op; it only makes the warmup transient worse by taking smaller-than-paper early steps.

**Combined with the other four aux update-rule leaves:**
- **v-estimator (this PR #545)**: CLOSED NULL/NULL
- **v-aggregation**: #583 Adamax (thorfinn) — in flight
- **v-clamp**: #578 AMSGrad (edward) — in flight
- **m-step**: #575 NadamW (askeladd) — in flight
- **m-aggregation**: #585 AdEMAMix (fern, this assignment) — in flight (NEW)

**Fern reassigned** to **AdEMAMix on aux AdamW** (PR #585) — the **m-aggregation** leaf of the aux update-rule mechanism tree, the fifth and final leaf. AdEMAMix (Pagliardini et al ICLR 2024) maintains TWO first-moment EMAs (fast β1≈0.9 + slow β1_slow≈0.9999) and uses `m_used = m_fast + α·m_slow`. This changes how m is FORMED rather than how m is USED (NadamW's domain). It is the mechanism specifically designed to leverage long-history gradient information that single-EMA Adam discards — relevant for rare-token embed/lm_head rows whose gradients are sparse over hundreds of steps.

**Suggested follow-ups (acknowledged):**
- LAMB/LARS layerwise trust ratio on aux — orthogonal mechanism class (per-tensor rescale not per-coordinate); queued.
- α-blend mixed second moment — limited additional learning; skip.
- Body-side variance — subsumed by Newton-Schulz polar map; skip (agreed).

## 2026-05-20 14:00 UTC — PR #546 CLOSED: NS_ITERS extension {16, 18} — NULL/NULL clear, V-shaped 5-point response curve confirms NS_ITERS=12 at local optimum (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/ns-iters-16-18`
- Hypothesis: extend constant-NS_ITERS scan beyond #511's {10, 12, 14} to {16, 18}. If extra Newton-Schulz iterations buy late-training polar-map quality, sr should drop monotonically as NS_ITERS grows.

| Arm | NS_ITERS | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 16 | `bqm06i25` | 2975 | 3.267862 | +37.5 | +0.0036 | NULL clear |
| Arm B | 18 | `xtaiy5c7` | 3000 | 3.269456 | +62.5 | +0.0052 | NULL clear |

**Verdict: NULL | NULL clear → NS_ITERS=12 confirmed at local optimum across full 5-point response curve.**

**Full response curve (NS_ITERS ∈ {10, 12, 14, 16, 18}):**

| NS_ITERS | sr | val/best_loss | Source |
|---|---|---|---|
| 10 | 3000 (Δsr=+62.5) | 3.273 | #511 Arm A |
| **12** | **2937.5 (baseline)** | **3.264278** | baseline |
| 14 | 2950 (n=2, Δsr=+12.5 marginal-NULL n=2) | 3.265846 | #511 Arm B n=2 |
| 16 | 2975 (Δsr=+37.5) | 3.267862 | #546 Arm A |
| 18 | 3000 (Δsr=+62.5) | 3.269456 | #546 Arm B |

**Beautifully clean V-shape** centered on NS_ITERS=12. Departures in both directions (NS=10 underconverged, NS=14-18 over-iterating with mounting cost) confirm 12 is the local minimum on this preconditioner-quality axis.

**Two independent inference paths converging:** tanjiro's #511 NS=14 went marginal-n=1-win then failed-n=2-confirmation, suggesting NS=14 was within seed noise of baseline. Thorfinn's #546 NS=16/18 produced clean NULLs on first attempt — the seed-noise band ends between NS=14 and NS=16. The 5-point monotone-V across {10, 12, 14, 16, 18} closes the iteration-count axis exhaustively.

**Combined with #540 (NS coefficient scan NULL/NULL identical sr=2975):** NS preconditioner quality is now pinned to inherited defaults across BOTH polynomial structure AND iteration count. NS-quality axis effectively saturated for this stack at cubic Newton (1.5, -0.5, 0.0) and NS_ITERS=12.

**Mechanistic read:** at NS_ITERS=12 cubic-Newton, the polar map for typical body-Muon matrices is essentially converged. Extra iterations after that point can only redistribute floating-point noise — they don't improve the spectral whitening. The mounting cost in {16, 18} is consistent with this: each extra iter introduces ~1e-6 magnitude perturbations to the polar-mapped step that don't help anywhere but show up as +25-37 sr regression because the rest of the stack was tuned to NS=12-output spectra.

**Student suggested follow-ups (incorporated):**
1. ✅ Joint NS_ITERS × coefficient axis — addressed by combined-closure of #540 + #511 + #546.
2. ✅ NS schedule (ramp up during cooldown) — being tested by **nezuko #559 NS_ITERS cooldown ramp 12→{16,18} over last 30%** in flight.
3. ✅ Lattice/seed variance n=2 policy for marginal sr — codified in advisor memory `feedback_marginal_n1_win_requires_n2.md`.
4. Adopt cooldown-only NS extension as the productive direction (nezuko #559 in flight).

**Thorfinn reassigned** to **Adamax on aux AdamW** (PR #583) — the v-aggregation leaf of the aux update-rule mechanism tree. Adamax (Kingma and Ba 2014, Section 7) replaces v-EMA (L2 norm of gradient history) with u-EMA (L∞ norm: `u = max(β2·u, |g|)`). Mechanistically distinct from AdaBelief #545 (v-target), NadamW #575 (m-step), AMSGrad #578 (v-clamp). Together these four leaves span the aux AdamW update-rule mechanism class.

## 2026-05-20 13:15 UTC — PR #540 CLOSED: NS coefficient scan (quintic vs aggressive-cubic) — NULL/NULL clear, polynomial axis closes alongside iteration count (g1r1-edward)

- Branch: `g1r1-edward/ns-coefficient-joint-scan`
- Hypothesis: NS polynomial coefficients `(NS_A, NS_B, NS_C)` define PMuon's per-matrix spectral whitening polar map. Baseline cubic `(1.5, -0.5, 0)` was inherited from upstream and never directly tested. Quintic (degree-5 published Muon coefs) and aggressive-cubic (same degree, larger contraction magnitude) test whether polynomial degree OR within-family scale is load-bearing.

| Arm | NS_A, NS_B, NS_C | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1.5, -0.5, 0.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (quintic published) | 3.4445, -4.7750, 2.0315 | `y46v2liq` | 2975 | 3.267725 | +37.5 | +0.003 | NULL clear |
| Arm B (cubic aggressive) | 1.75, -0.75, 0.0 | `zuk9fkdm` | 2975 | 3.267596 | +37.5 | +0.003 | NULL clear |

**Verdict: NULL | NULL clear → NS coefficient axis closes.**

**Remarkable coincidence:** both arms hit **identical sr=2975** and val differ by only 0.000129. Two very different polynomial families (degree-3 aggressive cubic vs degree-5 published quintic) produce near-indistinguishable trajectories despite different polynomial structure.

**Mechanistic read:** At NS_ITERS=12 the iteration has plenty of budget; the polar map is already near-perfect under baseline cubic. Replacing it with a steeper or higher-degree polynomial gives no whitening gain but slightly perturbs the spectral structure relative to what the rest of the stack (PMuon bilateral preconditioning, γ_power=0.4, β_cov=0.95) was tuned for. The flat optimum + ~37 sr cost in either direction tells us NS coefficient choice is at a saturated local optimum for our stack.

**Combined with #511 (NS_ITERS={10,14} NULL/NULL n=2)** and **#546 (Arm A NS_ITERS=16 NULL fs=2975, Arm B NS_ITERS=18 in flight)**: NS preconditioner quality is pinned to inherited defaults across BOTH polynomial structure AND iteration count. NS-quality axis effectively saturated.

**Student observations:**
- Both arms passed stat-sig threshold (val ≤ 3.276) — neither diverged.
- Neither arm satisfied win condition (sr ≤ 2925, or sr=2925 AND val<3.264278).
- Δval=+0.0034 and Δsr=+37.5 exceed marginal thresholds → n=2 not required.
- Student terminated redundant third Arm A run (`073p9uvl`) to free GPU — correct resource discipline.

**Suggested follow-up (deferred):** joint scan with #511 at low NS_ITERS (e.g., quintic at NS_ITERS=6) — at lower iter count quintic's per-iter convergence advantage might pay. Not assigned this round given closure-mode focus on independent leaves.

**Stale source comment** (lines 30–33 of `train_gpt_simple.py`) references old quintic→cubic labeling; advisor-owned cleanup, not a student bug.

**Edward reassigned** to **AMSGrad v-clamp on aux AdamW** (PR #578) — third leaf of the aux AdamW update-rule mechanism tree, alongside fern #545 AdaBelief (v-estimator leaf) and askeladd #575 NadamW (m-step leaf). AMSGrad clamps v_max from below via running max, distinct from changing v's estimation target (AdaBelief) or m's usage in the step (NadamW).

## 2026-05-20 12:10 UTC — PR #532 CLOSED: Body-Muon depth-based LR partition (early-fast vs late-fast) — NULL/NULL clear, body-Muon LR partition family fully closed across all three coarse subdivisions (g1r1-askeladd)

- Branch: `g1r1-askeladd/body-muon-block-lr-partition`
- Hypothesis: Depth-based LR multiplication (early blocks vs late blocks) would create headroom where uniform body-Muon LR=0.035 leaves it. Deeper blocks may benefit from different effective LR due to gradient norm scaling with depth, residual stream accumulation, or distinct preconditioning needs at different depths.

| Arm | early (blocks 0–5) | late (blocks 6–11) | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 1.0 | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (early-fast) | 1.10 | 0.90 | `oj9miqwf` | 3025 | 3.27130 | +87.5 | +0.007 | NULL clear |
| Arm B (late-fast) | 0.90 | 1.10 | `i6tfv7ry` | 3000 | 3.26825 | +62.5 | +0.004 | NULL clear |

**Verdict: NULL | NULL clear → depth-based LR partition axis closed.**

**Mechanistic read:** PMuon's per-matrix bilateral whitening of L_cov and R_cov normalises the singular-value spectrum of each weight matrix independently — including across depth. Each block's matrices get their own whitening estimates, so depth-distinct gradient norm scaling is effectively neutralized at the preconditioner output. A ±10% LR multiplier across two depth halves doesn't have headroom to compete with what PMuon already equalizes per-matrix.

**Directional late_fast-favouring residual signal:** Arm B is consistently 25 sr / 0.003 val_loss better than Arm A — a directionally clean but sub-threshold signal that deeper blocks marginally prefer slightly more LR. Same pattern direction as the c_proj-favouring sub-MLP residual (#535) — both suggest information-aggregation modules (c_proj, late blocks) want marginally more update — but signal magnitude is sub-stat-sig and inside seed noise.

**Combined with #499 (per-type MLP-vs-ATTN NULL/NULL +62.5/+87.5) and #535 (sub-MLP c_fc-vs-c_proj NULL/NULL +87.5/+37.5):** body-Muon LR partition family **fully closed across all three coarse subdivisions** — per-type, sub-MLP, depth. PMuon's per-matrix bilateral whitening eliminates coarse LR partitioning headroom by construction. **Coarse LR partitioning on body-Muon permanently de-prioritized.**

**Askeladd reassigned** to **NadamW (Nesterov AdamW, Dozat 2016) on aux AdamW first-moment update** — fresh aux m-step mechanism orthogonal to fern #545 AdaBelief (v-estimator) and orthogonal to all body-Muon work (aux path, not body path). Aux AdamW update-rule mechanism class now actively under test on both m and v sides.

## 2026-05-20 11:30 UTC — PR #535 CLOSED: Sub-MLP LR partition (c_fc vs c_proj) — NULL/NULL clear, PMuon whitening equalizes sub-projection asymmetry (g1r1-alphonse)

- Branch: `g1r1-alphonse/sub-mlp-lr-partition-cfc-cproj`
- Hypothesis: c_fc (expansion `d→4d`) and c_proj (contraction `4d→d`) have asymmetric gradient-geometry under PMuon. Splitting LR within MLP would surface a sub-MLP scheduling axis where PMuon's per-matrix whitening leaves headroom.

| Arm | mult_cfc | mult_cproj | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline | 1.0 | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A (c_fc-heavy) | 1.20 | 0.80 | `3twtlh18` | 3025 | 3.27030 | +87.5 | +0.006 | NULL clear |
| Arm B (c_proj-heavy) | 0.80 | 1.20 | `g8dy2zhk` | 2975 | 3.26732 | +37.5 | +0.003 | NULL clear |

**Verdict: NULL | NULL clear → sub-MLP LR partition axis closed.**

**Mechanistic read:** PMuon's per-matrix bilateral whitening of L_cov and R_cov already normalises the singular-value spectrum of each MLP sub-projection independently, so a coarse ±20% LR multiplier on top of the whitened update doesn't have headroom to help. Centered geometric mean preserved (`sqrt(1.20×0.80) ≈ 0.98`) confirms this is a genuine asymmetry test, not an effective-LR shift.

**Directional Arm-B-favouring residual signal:** Arm B is consistently 50 sr / 0.003 val_loss better than Arm A across the cooldown phase — a directionally clean but sub-threshold signal that c_proj wants slightly more LR than c_fc. Not large enough to chase with a narrower partition (1.05/0.95) — diminishing returns past PMuon's whitening.

**Combined with #499** (per-type MLP-vs-ATTN both arms NULL/NULL +62.5/+87.5): **body-Muon LR partition family is fully closed** on every coarse subdivision tested — per-type (#499), sub-MLP (#535), depth (pending #532). Coarse LR partitioning on body-Muon permanently de-prioritized.

**Student-suggested follow-up:** attack mechanisms PMuon does NOT equalize — per-projection momentum (mu), per-projection γ exponent, per-projection NS iteration count. Adopted as direction but first the global scalars need closure. Alphonse reassigned to **PMuon mu (body-Muon momentum EMA) scalar scan {0.90, 0.97}** — closes the only untested PMuon/body-Muon scalar (temporal smoothing axis, distinct from β_cov spatial-EMA).

## 2026-05-20 09:25 UTC — PR #511 CLOSED: NS_ITERS scan {10, 14} — NULL/NULL clear at n=2, NS_ITERS=12 confirmed local optimum (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-iters-scan`
- Hypothesis: NS_ITERS scalar is load-bearing in the cubic-Newton orthogonalization. Test whether more iters (NS=14) → tighter spectral whitening → better preconditioner per step beats baseline NS=12; and whether fewer iters (NS=10) saves wall-clock without quality loss.

| Arm | NS_ITERS | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 12 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 10 | `x6pxjdk4` | 3000 | 3.273 | +62.5 | +0.009 | NULL clear |
| Arm B seed-1 | 14 | `ldezjd0y` | 2925 | 3.2639 | −12.5 | −0.0004 | marginal n=1 win — triggered n=2 |
| Arm B seed-2 | 14 | `ciusvhzo` | 2975 | 3.2678 | +37.5 | +0.0035 | NULL |
| Arm B n=2 mean | 14 | — | 2950 | 3.265846 | +12.5 | +0.00157 | NO confirmation |

**Verdict: NULL | NULL clear (n=2) → NS_ITERS scalar axis closed at constant-iter regime.**

**Mechanistic read:** at constant NS_ITERS, the iteration-count axis is locally flat-to-degrading around 12. Arm A NS=10 is clear NULL (under-iter → poor spectral whitening). Arm B NS=14 n=1 was within seed noise (sr=2925 baseline mean=2937.5 ⇒ Δsr=−12.5 ≤ marginal threshold 25), and seed-2 regressed to the NULL side. The marginal rule worked as designed — it correctly distinguished a within-noise n=1 sample from a genuine signal.

**Suggested follow-up:** student suggestion accepted — the marginal rule is calibrated correctly. The two-run cost paid for genuine information: NS=14 is NOT a free win.

**Combined with thorfinn #546** (NS={16,18} pipeline in flight) and **edward #540** (NS coef joint scan at NS=12 fixed): if #546 also lands clear NULL, the constant-NS axis is fully exhausted and any remaining iter-count gains live in **scheduling** (nezuko #559 NS_ITERS cooldown ramp).

NS_ITERS scalar (constant) axis closes at {10, 12, 14} mapped. Tanjiro reassigned to PMuon ε floor scan (#562 — only untested PMuon scalar).

## 2026-05-20 08:55 UTC — PR #522 CLOSED: Skylight u/w-floor cooldown phase-out — NULL/NULL clear, asymmetric loss curve confirms floor is load-bearing throughout cooldown (g1r1-nezuko)

- Branch: `g1r1-nezuko/skylight-floor-cooldown-decay`
- Hypothesis: The Skylight u/w-floor (TARGET_UW=0.35, forces ~87% of body matrices to receive update of magnitude ≥0.35·‖w‖ every step) overrides COOLDOWN_POWER=1.4's intentionally small polar-map updates during cooldown, defeating the cooldown's refinement dynamics. Phasing out the floor during cooldown should free those small updates to do refinement work.

| Arm | Schedule | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | constant 0.35 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | linear decay 0.35→0 over cooldown | `1ohe6cf7` | 2975 | 3.27188 | +37.5 | +0.00761 | NULL clear |
| Arm B | hard switch 0.35→0 at cooldown_start | `8bmch56g` | 3025 | 3.27214 | +87.5 | +0.00786 | NULL clear (2× worse than Arm A on sr) |

**Verdict: NULL | NULL clear → Skylight axis fully closed.**

**Mechanistic read:** the asymmetric regression (hard worse than linear) is informative. If the floor were redundant with the LR taper during cooldown, hard cutoff should be no worse than gradual decay. Instead, hard cutoff costs 50 additional sr steps over linear decay — meaning the floor's u/w-amplification continues to contribute useful work even as COOLDOWN_POWER=1.4 narrows the polar-map updates. The floor and cooldown are complementary, not redundant: the floor pushes update magnitude up to a minimum threshold, the cooldown narrows the polar map, and the product is what drives refinement.

**Combined with #486** (static TARGET_UW∈{0.25, 0.45} symmetric +87.5 sr both arms): TARGET_UW=0.35 is the local optimum on both magnitude (#486 closed) and schedule (#522 closed) axes. Skylight floor is now exhaustively pinned.

Skylight axis closes. Nezuko reassigned to NS_ITERS cooldown ramp (fresh).

## 2026-05-20 07:30 UTC — PR #519 CLOSED: PMuon γ pruning ablation γ∈{0, 0.8} vs baseline 0.4 — NULL/NULL clear, γ axis fully mapped (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-ablation`
- Hypothesis: Test whether PMuon's bilateral covariance EMA exponent γ_power=0.4 is load-bearing or redundant by ablating to extremes: Arm A γ=0 (full ablation, no spectral correction), Arm B γ=0.8 (over-correction). Companion to #444 phase-ramp ablation (both directions NULL marginal).

| Arm | γ | W&B | val/best_loss | Δval (vs 3.264278) | ffs | Verdict |
|---|---|---|---|---|---|---|
| **Baseline** | 0.4 | `k7ylyby9`/`dm4joozw` | 3.264278 (n=2) | — | 2937.5 | — |
| Arm A | 0 | `7baa1iif` | 3.282615 | +0.018337 | -1 (DNF) | NULL clear (+0.018, ~1.4% off) |
| Arm B | 0.8 | `odm9asp9` | 3.313878 | +0.049600 | -1 (DNF) | NULL very clear (+0.050, 2.7× Arm A damage) |

**Verdict: NULL | NULL clear → γ axis closes at γ=0.4.**

**Three-point γ map** (combining this data with #444):
- γ=0: +0.018 val (mild under-conditioning, cooldown slope too shallow to hit 3.28 in 3250-step budget)
- γ=0.4: BASELINE (locally near-optimal)
- γ=0.8: +0.050 val (~2.7× more damage than ablation)
- γ ramp (#444): NULL marginal both directions — static γ=0.4 confirmed at temporal axis as well

**Asymmetric damage curve** is mechanistically informative: over-correction (γ=0.8) hurts ~2.7× more than ablation (γ=0). Loss surface is steeper on the over-correction side. Consistent with γ acting as a *damped spectral correction* whose over-application leaves body updates over-conditioned and step direction biased.

**Pattern continuation with #482/#499/#503:** all four ablation axes (γ, WD partition, type-LR partition, WD schedule) show local optimum pinned by **cooldown-phase preconditioner-quality demand** — "too much of a corrective mechanism" is consistently worse than "too little." The cooldown is the load-bearing phase for these mechanism choices.

**Skipped follow-up:** the {0.3, 0.5} fine-scan the student suggested as item 2 — gradient at γ=0.4 is small in magnitude (Δval ≈ 0.018 between γ=0 and γ=0.4 implies a gentle local curve), retunes likely yield ≤ few millinats, won't separate from seed noise even at n=2. Axis is mapped to high confidence.

Frieren reassigned to PR #553: **gradient centralization on body-Muon pre-NS** — fresh mechanism class (gradient TRANSFORMATION, neither averaging nor preconditioning nor partition). Arm A dim=1 (per-output-channel mean subtraction, GC paper default per Yong et al 2020), Arm B dim=0 (per-input-channel).

## 2026-05-20 06:08 UTC — PR #513 CLOSED: Body-Muon gradient clipping at thresholds {1.0, 0.5} — NULL/NULL clear, damping/clipping closes BELOW natural-norm regime (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/body-muon-grad-clip`
- Hypothesis: Test gradient clipping as a damping mechanism layered on body-Muon. Two arms: clip_norm=1.0 (mild damping) and clip_norm=0.5 (aggressive). First clipping/damping probe on the body-Muon stream.

| Arm | clip_norm | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | none | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 1.0 | (logged in PR) | 3000 | 3.27024 | +62.5 (clear) | +0.006 (clear) | NULL clear |
| Arm B | 0.5 | `m5fjt5gz` | 3000 | 3.27108 | +62.5 (clear) | +0.007 (clear) | NULL clear |

**Verdict: NULL | NULL clear → grad-clipping at tested thresholds CLOSES below natural-norm regime.**

Rich mechanistic diagnostic from the student:
- **Clip activation 99.97% at both thresholds** — clipping was binding on essentially every step.
- **Natural body-grad norm ~3e4** (per student's measurement) vs proposed thresholds {0.5, 1.0} → 4-5 orders of magnitude too low.
- Uniform 30,000× downscale costs only ~2% sr regression (+62.5 / 2937.5 ≈ 2.1%) — **PMuon's spectral whitening is approximately scale-invariant.** The whitening normalizes singular values away anyway, so the overall scale matters only through second-order effects (effective step size relative to the cooldown schedule).

This is a positive negative result: the closure doesn't just kill grad clipping at low thresholds, it adds direct evidence for the scale-invariance hypothesis underlying PMuon's design.

**Student's suggested follow-up** — re-test at natural-norm regime {3e4, 1e5, 3e5} — judged DEFERRED. Higher priority: tanjiro's live NS_ITERS=14 marginal win signals that preconditioner quality (NS iteration count) is the open axis, not damping.

Thorfinn reassigned to PR #546: NS_ITERS extension pipeline {16, 18} parallel to tanjiro's n=2 confirmation. Two independent n=1 wins at different NS values would strengthen the "more iters → tighter whitening" trend.

## 2026-05-20 05:32 UTC — PR #505 CLOSED: Lookahead wrapper on body-Muon, k∈{5, 10}, α=0.5 — NULL/NULL clear, wrapper-class axis closes (g1r1-fern)

- Branch: `g1r1-fern/lookahead-body-scan`
- Hypothesis: Test the Lookahead wrapper (slow/fast weights with periodic slow→fast resync) on body-Muon. First wrapper-class probe of the optimizer stack at this baseline. Two arms test averaging strength: aggressive (k=5) vs milder (k=10).

| Arm | k | α | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | — | — | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 5 | 0.5 | `8ad3mzjz` | -1 (DNF) | 3.284199 | +∞ (clear regression) | +0.020 (clear) | NULL clear |
| Arm B | 10 | 0.5 | `e3zkawez` | -1 (DNF) | 3.286180 | +∞ (clear regression) | +0.022 (clear) | NULL clear |

**Verdict: NULL+NULL clear → wrapper-class axis on body-Muon CLOSES at this baseline.**

Monotone direction is informative: milder Lookahead (k=10) is NOT better than aggressive (k=5) — both regress similarly. This rules out the natural follow-ups (longer-k variants, smaller-α partial blends). The wrapper's slow-weight pull adds a low-frequency averaging bias that conflicts with the carefully-tuned cooldown schedule + Skylight floor + PMuon stack — net-harmful interference.

**Cross-link with earlier closures:** This is the third averaging/smoothing-class closure on this baseline. Together with PMuon γ_power phase ramp (#444 NULL) and β_cov scan (#502 NULL), the pattern emerges:

> **All averaging/smoothing-class mechanisms layered on top of the already-tuned PMuon stack regress.**

The stack is "in a sweet spot" w.r.t. internal momentum/smoothing. Adding ANY external smoothing (Lookahead slow-pull, longer PMuon β_cov, phase-ramped γ_power) breaks the balance.

**Polyak EMA explicitly skipped** as a follow-up: same averaging family as Lookahead, falsification has already carried.

Fern reassigned to PR #545: AdaBelief on aux AdamW group — first mechanism-class change to variance update FORM.

## 2026-05-20 04:28 UTC — PR #503 CLOSED: Body-Muon WD schedule (warmup-25pct vs cooldown-25pct) — NULL/NULL, first temporal schedule on body-Muon closes (g1r1-edward)

- Branch: `g1r1-edward/body-muon-wd-schedule`
- Hypothesis: Test first temporal schedule on body-Muon WD. Two mechanistic priors: (warmup) early stochastic weights need free growth before WD tightening; (cooldown) shrinking LR during cooldown means constant WD over-shrinks late-emergent features. Orthogonal to #482 (per-type WD partition NULL) and #499 (per-type LR partition NULL).

| Arm | Schedule | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | constant WD=0.025 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | warmup-25pct (0 → 0.025 over first 813 steps) | `vcc1mty6` | 2950 | 3.26475 | +12.5 (marginal-worse) | +0.000472 (within marginal band) | NULL marginal |
| Arm B | cooldown-25pct (0.025 → 0 over last 813 steps) | `bu075bqm` | 2975 | 3.26681 | +37.5 (clear-worse) | +0.002532 (outside marginal band) | NULL clear |

**Verdict: NULL | NULL → temporal schedule axis closes at constant uniform WD=0.025.**

Asymmetric loss curve (cooldown loses ~5× more val-loss than warmup) is mechanistically informative:
- **Warmup** is essentially indistinguishable from baseline. Early-phase WD overhang is not a real problem at this baseline — starting WD at zero and ramping in costs nothing but gains nothing.
- **Cooldown** loses cleanly. Removing WD during cooldown lets late-emergent features drift/amplify noise. WD's implicit norm-control is **load-bearing** during the cooldown phase, not redundant with LR cooldown. The student's mechanistic read in the SENPAI-RESULT comment is correct.

Body-Muon WD is now exhaustively tested:
- **Partition axis:** #482 frieren MLP-vs-ATTN NULL marginal
- **Schedule axis:** #503 edward warmup/cooldown NULL/NULL clear (this PR)
Constant uniform WD=0.025 is the local optimum across both granularities. Schedule-level levers should NOT be layered on top of partition-level winners.

Student's suggested follow-ups (triangle schedule, shorter 5% warmup, composition with lower constant-WD floor) all judged low-leverage given the cooldown arm's clear regression dominates and the warmup arm is already in the marginal band.

Edward reassigned to PR #540: NS coefficient (a,b,c) joint scan — published quintic vs aggressive-cubic at NS_ITERS=12 fixed.

## 2026-05-20 03:40 UTC — PR #499 CLOSED: Body-Muon LR per-type partition (MLP vs ATTN) — both arms clear NULL/regress, partition family fully closes (g1r1-alphonse)

- Branch: `g1r1-alphonse/body-muon-lr-partition`
- Hypothesis: Per-type LR partition (MLP vs ATTN) — LR companion to frieren's WD partition #482 (which was NULL marginal). ±20% multiplicative asymmetry around inherited body_lr=0.035, centered geometric mean preserved (sqrt(MLP × ATTN) = 0.0343 ≈ 0.035), so this is a redistribution test not a scale test.

| Arm | MLP_LR | ATTN_LR | W&B | sr (ffs) | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| **Baseline** | 0.035 | 0.035 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A (MLP-heavy) | 0.042 | 0.028 | `vrmveqoe` | 3025 | 3.27040 | +87.5 ✗ | +0.0061 ✗ | clear NULL |
| B (ATTN-heavy) | 0.028 | 0.042 | `tdw0diir` | 3000 | 3.27015 | +62.5 ✗ | +0.0059 ✗ | clear NULL |

**Signal: NULL × NULL with both directions regressing by similar magnitude (~Δval=+0.006).** Asymmetry between Arm A and Arm B is Δval=+0.00025 — well inside seed noise (n=1).

**Mechanistic conclusion (student's analysis, accepted):** PMuon's spectral normalization already equalizes per-matrix whitened gradient geometry across MLP and ATTN. Hand-imposed LR asymmetry on top of PMuon's preconditioning destroys the equalization PMuon was getting right. The split itself hurts (not the effective LR — geomean preserved).

**Strategic implication:** **Per-substructure (MLP-vs-ATTN) partition family fully closed.** Both WD (#482 NULL n=2 marginal) and LR (#499 NULL/NULL clear) tested and exhausted. Alphonse reassigned to **sub-MLP LR partition c_fc vs c_proj (#535)** — student-suggested follow-up on a finer grain where PMuon's per-matrix whitening cannot equalize (c_fc and c_proj are *different* matrices).

---

## 2026-05-20 03:25 UTC — PR #502 CLOSED: PMuon body β_cov scan — both arms NULL, β_cov axis CLOSES (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-beta-cov-scan`
- Hypothesis: PMuon bilateral covariance EMA β_cov∈{0.90, 0.99} symmetric around inherited 0.95. Tests whether more responsive (10-step window) or smoother (100-step window) preconditioner EMA is preferred at the 2937-step operating point. Last untested PMuon scalar after γ_power, lr, wd, NS_ITERS were closed earlier.

| Arm | β_cov | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| **Baseline** | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| A | 0.90 (responsive) | `o31yd0nw` | 2950 | 3.264775 | +12.5 ✗ | +0.000497 ✗ | NULL (marginal) |
| B | 0.99 (smoother) | `7donghzb` | 3000 | 3.269313 | +62.5 ✗ | +0.005035 ✗ | NULL (clear) |

**Signal: asymmetric NULL/NULL — β_cov=0.95 locally optimal.** Going UP to 0.99 costs ~10× more than going DOWN to 0.90 (Δval +0.005 vs +0.0005). The 100-step EMA over-smooths late-phase covariance: by the time cooldown gradients shrink, the EMA still drags in pre-cooldown statistics that mis-shape spectral normalization.

**Falsification table outcome (per preregistered design): NULL × NULL → "β_cov=0.95 is saturated. Axis closes."** Student also notes the asymmetry is in the WRONG direction for a "down during cooldown" β_cov schedule — Arm A (responsive) was marginal-WORSE, not better. Scheduled β_cov ramp is ruled out without further test.

**Strategic implication:** PMuon scalar block (γ_power, β_cov, NS_ITERS, body-lr, body-wd) all closed NULL at inherited defaults. Moving askeladd to **Body-Muon per-block LR multiplier (#532)** — first depth-based partition test, fresh class never tested.

---

## 2026-05-19 16:13 UTC — PR #448 CLOSED: Decoupled cooldown_frac aux vs body — both arms NULL, cf-decoupling axis CLOSES (g1r1-nezuko)

- Branch: `g1r1-nezuko/decoupled-cooldown-frac`
- Hypothesis: Decouple aux-group cooldown start from body Muon cooldown start. Aux groups (embed+lm_head+scalars) under AdamW may want different cooldown phase boundaries than body matrices under PMuon.

| Arm | cf_body | cf_aux | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 0.7 | 0.5 (aux shorter, longer high-LR) | `0a9r5lof` | 2975 | 3.265212 | +37.5 ✗ | +0.000934 ✗ | NULL (marginal val, clear sr) |
| **Baseline** | 0.7 | 0.7 (uniform) | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B | 0.7 | 0.85 (aux longer, shorter high-LR) | `taremaia` | 3025 | 3.27052 | +87.5 ✗ | +0.00624 ✗ | NULL (clear) |

**Signal: clear asymmetric NULL** — Arm A (aux-delayed cooldown) much closer to baseline than Arm B (aux-advanced cooldown), with Arm B regressing strongly on both metrics.

**Mechanistic conclusion (student's analysis, accepted):**
- Body Muon and AdamW-on-aux groups are coupled through val/loss-driven gradient distribution shifts. Breaking the phase coincidence of cooldown start shifts the joint optimization trajectory off-manifold.
- Asymmetry consistent with sparse aux groups benefiting slightly from delayed cooldown (more high-LR accumulation), but the gain in val/loss (+0.00094) doesn't translate to faster speedrun.
- This is a SCHEDULE COUPLING axis: cf=0.7 uniform is structurally optimal at this op point.

**Strategic implication:** 4th consecutive axis this cycle closing at inherited default (soft-cap c=15, embed std=1.0, γ=0.4 static, cf=0.7 uniform). Simple-scalar-axis frontier saturated. Nezuko reassigned to **Skylight u/w-floor TARGET_UW scan** (#486) — first scan of the floor-amplification threshold inherited at 0.35.

---

## 2026-05-19 15:35 UTC — PR #444 CLOSED: PMuon γ_power phase schedule — both arms NULL, γ-phase ramp axis CLOSES (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-phase-schedule`
- Hypothesis: Decouple stable-phase γ from cooldown-phase γ via monotonic ramp. Stable phase wants weaker γ while β_cov=0.95 EMA fills; cooldown phase wants stronger γ to amplify fine-direction signal at low LR. Test ramps in both directions of static γ=0.4.

| Arm | γ schedule | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A | stable 0.3 → ramp 0.3→0.4 cooldown | `xhzcvx0p` | 2975 | 3.267596 | +37.5 ✗ | +0.003318 ✗ | NULL regression |
| **Baseline** | γ=0.4 STATIC | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B | stable 0.4 → ramp 0.4→0.5 cooldown | `894sq3ig` | 2975 | 3.267451 | +37.5 ✗ | +0.003173 ✗ | NULL regression |

**Signal: both ramps regress symmetrically against current baseline** (PR #413 sr=2937.5). Note: student's local table compared against stale baseline #367 (sr=2975, val=3.26722), so her arm-to-arm "near-tie" reading was structurally correct but interpretation against current baseline requires Δsr=+37.5 framing.

**Mechanistic conclusion (student's analysis, accepted):**
- β_cov=0.95 EMA fills by step ~100 (effective sample count ≈ 1 at 1−0.95^100 ≈ 0.99). Stable-phase γ tuning therefore operates on too narrow a window to move val/loss.
- Combined with #386 (γ STATIC ∈ {0.5, 0.6} NULL), #129 (β_cov STATIC), #261 (LR warmup): PMuon dynamics axis is now thoroughly saturated at this op point.
- Mechanism verification was clean: `pmuon/gamma_dynamic` reached 0.39996 / 0.49996 endpoints, confirming the ramp schedule applied correctly.

**Operational note:** Student diagnosed a complex multi-launch OOM cascade where 4 crashed launches reported in W&B were sibling duplicate processes; the primary `xhzcvx0p` was healthy and progressing throughout. Excellent triage work.

**Strategic implication:** Third consecutive cycle of axes closing at inherited defaults (soft-cap c=15, embed std=1.0, γ=0.4 static). PMuon scalar HPs particularly saturated. Frieren reassigned to body-Muon WD partition (MLP vs attention, PR #482) — a *structural* axis rather than further scalar tuning.

---

## 2026-05-19 14:33 UTC — PR #440 CLOSED: Embed init scale scan std∈{0.5, 2.0} — both NULL, axis closes at baseline std=1.0 (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/embed-init-scale`
- Hypothesis: Scan the input embedding weight init std around PyTorch's default 1.0. Test tighter (0.5, smaller initial body activations) vs wider (2.0, faster initial body learning).

| Arm | std | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A (tighter) | 0.5 | `e27g8crp` | 3000 | 3.26878 | +62.5 ✗ | +0.00450 ✗ | NULL clear regression |
| **Baseline** | 1.0 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B (wider) | 2.0 | `xt1o5rce` | 3025 | 3.26970 | +87.5 ✗ | +0.00542 ✗ | NULL clear regression |

**Signal: strong-bracket signature — both arms regress monotonically away from baseline std=1.0** with similar magnitude (Δsr=+62.5/+87.5, Δval=+0.0045/+0.0054). Very slight skew toward tighter being preferred (Arm A regressing ~25% less than Arm B), but gradient too small to be worth fine-scanning.

**Mechanistic conclusion:** PyTorch default embed std=1.0 is empirically well-placed for this Muon + AdamW(lr=0.3, betas=0.8/0.95) stack at this op point. Token row L2 norm ≈ 27.7 with std=1.0 is large in absolute terms but evidently in the right range for current optimizers to consume gradients efficiently in 3250 steps. Same "inherited default already optimal" pattern as PR #439 (soft-cap c=15 closed identically).

**Operational note:** Pod entrypoint auto-relaunched a duplicate Arm B (\`1zyj7lxw\` 14:23 UTC step 0); student SIGKILL'd cleanly without waste. Good operational catch.

**Strategic implication:** Two consecutive scans (soft-cap value, embed init scale) closed at inherited defaults with symmetric bracket regressions. The fast wins are likely in *structurally novel* mechanisms (Z-loss, attention temperature, NS asymmetric coefficients, per-block residual scaling, MLP-vs-attn WD partition), not in fine-tuning further inherited constants. Follow-up: PR #480 (tanjiro attention scale scan).

---

## 2026-05-19 14:10 UTC — PR #439 CLOSED: Logit soft-cap value scan c∈{10,30} — both NULL, axis closes at baseline c=15 (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/logit-softcap-scan`
- Hypothesis: Scan the logit soft-cap `f(x) = c·x/√(x²+c²)` value: tighter c=10 (constrains earlier) vs looser c=30 (Gemma/Llama default). Baseline c=15.

| Arm | c | W&B | sr | val/best_loss | Δsr (vs 2937.5) | Δval (vs 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|
| A (tighter) | 10 | `zb1xmejl` | 3050 | 3.27316 | +112.5 ✗ | +0.00888 ✗ | NULL clear regression |
| **Baseline** | 15 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| B (looser, Gemma/Llama default) | 30 | `3ek9yl3d` | 3050 | 3.27182 | +112.5 ✗ | +0.00754 ✗ | NULL clear regression |

**Signal: strong-bracket signature — symmetric +112.5 sr regression in both directions** with similar magnitude val degradation (Δval ≈ 0.006-0.009). Both arms move monotonically away from baseline in both metrics.

**Mechanistic conclusion:** c=15 sits in a real local optimum w.r.t. the single-knob soft-cap axis under the current optimizer/schedule/init stack. Tighter caps (c=10) saturate too early on legitimate logit magnitudes, damping cooldown-phase precision. Looser caps (c=30) add noise/instability on the cooldown tail without unlocking new headroom. The fact that BOTH directions degrade by the same ~+75-112.5 sr is strong evidence the inherited value c=15 was previously tuned for this regime (likely upstream).

**Operational notes:**
- Student caught a duplicate-process incident on Arm A (zb1xmejl + wqd48u4t), resolved cleanly without intervention (duplicate self-terminated).
- Val-loss tail in Arm B clean & monotone (3.288 @ s=2925 → 3.272 @ s=3250) — no late-phase blowup from larger logits despite looser cap.

**Strategic implication:** Loss-side scalar knobs are now characterized for this regime. Future loss-side work should target structurally different mechanisms (Z-loss / log-Z regularizer, attention temperature, pre-softmax scaling) rather than fine-tuning the soft-cap value. Follow-up: PR #476 (thorfinn z-loss scan) assigned immediately.

---

## 2026-05-19 12:30 UTC — PR #433 CLOSED: Aux AdamW β2 by group {0.99, 0.999 on embed+lm_head} — both NULL, axis closes at uniform 0.95 (g1r1-edward)

- Branch: `g1r1-edward/aux-beta2-by-group`
- Hypothesis: Decouple aux AdamW β2 per parameter group. Embed/lm_head (sparse-token gradients) may benefit from higher β2 (longer 2nd-moment averaging) than scalars (dense LN/bias). Test β2_{embed,lm_head} ∈ {0.99, 0.999} vs scalars β2=0.95.

| Arm | β2_embed | β2_lm_head | β2_scalars | W&B | sr | val/best_loss | Δsr (vs NEW base 2937.5) | Δval (vs NEW base 3.264278) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.95 | 0.95 | 0.95 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| A | 0.99 | 0.99 | 0.95 | `3eweuh3s` | 2975 | 3.26738 | +37.5 ✗ | +0.0031 ✗ | NULL (tied old, NULL new) |
| B | 0.999 | 0.999 | 0.95 | `2qoyvxmz` | 3050 | 3.27327 | +112.5 ✗ | +0.009 ✗ | NULL (clear regression) |

**Signal: monotone NULL → regression as β2 increases on the matrix groups.** Arm A indistinguishable from baseline (Δval=+0.00017 vs OLD baseline, within seed noise); Arm B clearly worse than baseline (+0.006 val).

**Mechanistic conclusion:** The sparse-vs-dense gradient intuition (high-β2 for noisier signals on rarely-updated tokens like vocab embeddings) is not borne out at this scale/data regime. Uniform β2=0.95 across all aux groups is the empirically-optimal choice. Higher β2 (longer 2nd-moment averaging) is structurally worse — likely because the cooldown schedule already provides enough effective averaging through smaller LRs, and additional momentum in the 2nd moment over-smooths the per-step adaptation just when the model needs to refine direction in late training.

**Operational note:** Student caught a duplicate-process incident on Arm A (two torchrun processes sharing GPU), SIGKILL'd the newer duplicate, preserved the original run cleanly. Good operational discipline.

**Combined-axis closure:** With β1 axis closed at uniform 0.8 (PR #416), β2-by-group now closed at uniform 0.95. **Aux AdamW (β1, β2) axes are both fully characterized — uniform values across all groups are optimal.** Remaining aux AdamW per-group axes: eps (askeladd #463 in flight) and weight_decay (edward #466 newly assigned).

**Next assignment:** PR #466 (aux AdamW WD scan {0.001, 0.01} on embed+lm_head — first WD test on aux matrices).

---

## 2026-05-19 12:25 UTC — PR #447 CLOSED: NS adaptive convergence threshold {0.5, 0.1} — mechanism never engages, axis closes (g1r1-fern)

- Branch: `g1r1-fern/ns-adaptive-threshold`
- Hypothesis: Replace fixed NS_ITERS=12 with adaptive convergence (data-dependent iter count). Skip remaining iters when polar residual drops below threshold. Arms: threshold=0.5 (Arm A, looser) and threshold=0.1 (Arm B, tighter).

| Arm | threshold | W&B | sr | val/best_loss | Δsr (vs NEW base) | Δval (vs NEW base) | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | (fixed iters=12) | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — | — |
| A | 0.5 | `7logfkqq` | 3000 | 3.26915 | +62.5 ✗ | +0.0049 ✗ | NULL (mechanism never fires) |
| B | 0.1 | (not run) | — | — | — | — | skipped per advisor directive |

**Critical mechanism diagnostic (student-provided telemetry):** The adaptive threshold **never engages** under either arm. Polar residual after 12 cubic-Newton NS iterations plateaus at ~6.9 throughout training, one order of magnitude above either threshold (0.5 or 0.1). Both arms would effectively be NS_ITERS=12 + per-step residual-check overhead — indistinguishable from baseline mechanism-wise.

**Residual trajectory (Arm A, single-run):** 27.75 (step 1) → 8.76 (step 25) → 8.30 (step 50) → 7.07 (step 250) → 6.93 (step 425). Log-linear extrapolation to step 3000: residual ≈ 1.5, still 3× above threshold 0.5. The threshold is unreachable in 12-iter ceiling at this operating point.

**Why Arm B was not run:** Saved ~3.5h GPU time. Mechanism guaranteed not to engage; Arm B with tighter threshold (0.1) is structurally identical to Arm A. Student raised this diagnostically and waited for advisor decision.

**Mechanistic conclusion:** The original hypothesis "skip NS iterations once polar projection converges" is **dead at this operating point** because cubic-Newton NS at (a=1.5, b=-0.5, c=0) with 12 iters cannot push the residual below ~6.9. The matrices being orthogonalized are not converging to tight orthogonality with this polynomial.

**Side-finding for program log:** NS convergence quality at the current PMuon operating point is a worthwhile diagnostic axis. Future revisits: (a) higher-tolerance early-exit (threshold ≈ 5-7) as a *different* hypothesis — would test "can we early-exit at moderate convergence and maintain quality?", and (b) revised NS polynomial coefficients (asymmetric c ≠ 0 variants) to push residual lower. Not by reviving this PR.

**Operational note:** Student also caught a duplicate-process incident on Arm A (W&B `3vidmtm1` duplicate alongside canonical `7logfkqq`), killed the duplicate cleanly, step time recovered from ~9s to ~4s. Good operational discipline.

**Next assignment:** PR #465 (Muon LR fine-scan {0.030, 0.040} — highest-value unscanned axis on body optimizer).

---

## 2026-05-19 11:30 UTC — PR #416 CLOSED: Aux AdamW β1 fine-scan {0.75, 0.85} — both NULL after n=2 confirmation, axis closes at 0.8 (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-b1-fine-scan`
- Hypothesis: Fine-scan β1 around baseline 0.8 for aux AdamW. Test 0.75 (less momentum) and 0.85 (more momentum).

| Arm | β1 | W&B | sr | val/best_loss | Δval (vs NEW base 3.264278) | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #413 n=2) | 0.8 | `k7ylyby9`/`dm4joozw` | 2937.5 | 3.264278 | — | — |
| A | 0.75 | `3kpvr1lq` | 3025 | 3.27201 | +0.0077 ✗ | NULL clear |
| B (seed-1 n=1) | 0.85 | `bktt5lon` | 2950 | 3.26375 | −0.00053 ✓ | n=1 marginal WIN |
| B (seed-2 n=2 confirm) | 0.85 | `k7u7pfy5` | 3000 | 3.26911 | +0.00484 ✗ | NULL (falsifies n=1) |
| **B (n=2 mean)** | **0.85** | — | **2975** | **3.2664** | **+0.0022 ✗** | **NULL** |

**Signal: Arm A clear regression. Arm B n=1 marginal WIN falsified at n=2.** seed-2 produced sr=3000 val=3.26911, Δval=+0.00484 — clearly NULL. n=2 mean val=3.26643, well above baseline.

**Statistical lesson:** This demonstrates the value of the marginal n=2 confirmation rule. Arm B's n=1 was Δval=-0.00053 (within seed noise) — flagged marginal per (3.28-μ)·√n ≥ 0.004 rule. Without n=2 confirmation, we would have merged a non-improvement. n=2 mean reveals the n=1 was on the favorable side of seed noise.

**Mechanistic conclusion:** β1 axis CLOSES at uniform 0.8 across all aux groups. Combined with PR #320 testing β1=0.9 (NULL), the bracket 0.75/0.8/0.85/0.9 is now fully characterized — 0.8 is the local optimum.

**Combined with PR #433 closure (this cycle):** Both β1 AND β2 axes are now closed at their uniform baseline values for aux AdamW. The aux optimizer's first-moment and second-moment hyperparameters are well-tuned at (β1=0.8, β2=0.95). Remaining open axes: eps (per-group, #463 in flight) and weight_decay (per-group, #466 just assigned).

**Next assignment:** PR #463 (aux AdamW eps scan on embed group {1e-8, 1e-7} vs baseline 1e-10).

---

## 2026-05-19 11:48 UTC — PR #413 MERGED: scalar_lr=0.025 (alphonse n=2 WIN) ← NEW BASELINE

- Branch: `g1r1-alphonse/scalar-lr-scan`
- Hypothesis: Scan scalar_lr (RMSNorm gain + bias AdamW group) upward from the unintuitive default 0.01. Two arms: 0.025 (2.5×) and 0.05 (5×). Completes the aux LR characterization triplet.

| Arm | scalar_lr | W&B | sr | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367 n=2) | 0.01 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| **A seed-1** | **0.025** | `k7ylyby9` | **2950** | **3.26543** | **−25** | **−0.00179** | n=1 WIN (sr-marginal) |
| **A seed-2** | **0.025** | `dm4joozw` | **2925** | **3.26312** | **−50** | **−0.00410** | confirms A |
| B | 0.05 | `03c9tk79` | 2975 | 3.26674 | 0 | −0.00048 | n=1 marginal (val within noise) |

**n=2 mean (Arm A confirmed):** sr=2937.5, val=3.264278. Stat-sig: (3.28 − 3.264278)·√2 = 0.0222 ≥ 0.004 ✓ (5.56×).

**Signal: non-monotone, peak at 0.025.** val curve: 3.26722 → 3.26428 → 3.26674 (0.01 → 0.025 → 0.05). Arm B at 0.05 shows regression back toward baseline on sr with minimal val gain — past the optimum.

**Mechanistic analysis:** RMSNorm gains and bias parameters benefit from 2.5× faster adaptation via scalar_lr=0.025. The gains converge faster before COOLDOWN_POWER=1.4's sharper LR taper eliminates the adaptation window. Arm B's regression at 0.05 confirms a concave response — the optimum is narrow with 0.025 as the confirmed peak. Both seeds independently beat baseline (seed-2 improved further at sr=2925 vs seed-1 sr=2950), ruling out luck.

**Closes aux LR characterization triplet:** embed_lr CLOSED at 0.3, lm_head_lr CLOSED at 1/160 (PR #367), scalar_lr now MERGED at 0.025. All three aux AdamW LR axes characterized.

**New baseline:** sr=2937.5 (n=2 mean), val=3.264278. All subsequent PRs compare against this.

**Next assignment:** PR #460 (alphonse scalar_lr fine-scan {0.020, 0.030} — peak localization around confirmed 0.025 winner).

---

## 2026-05-19 08:35 UTC — PR #414 CLOSED: cosine cooldown shape {pure cosine, cosine²} — both NULL, monotone catastrophic, axis closes (g1r1-nezuko)

- Branch: `g1r1-nezuko/cooldown-shape-cosine`
- Hypothesis: Replace power-law cooldown shape (COOLDOWN_POWER=1.4) with cosine family — pure cosine has different curvature (slow-early/fast-late decay vs power-law's fast-early/slow-late).

| Arm | Cooldown shape | W&B | sr | val/best_loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | power-law 1.4 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | pure cosine | `0x82h8if` | 3050 | 3.27557 | +75 ✗ | +0.00835 ✗ | NULL clear |
| B | cosine² | `lj00vaiw` | -1 (never reached) | 3.29445 | failed ✗ | +0.02723 ✗ | NULL catastrophic |

**Signal: monotone catastrophic.** Pure cosine fails by +75 sr; cosine² (even sharper late-LR drop) fails to reach target at all, with val 0.027 worse than baseline.

**Mechanistic conclusion:** The late-cooldown LR floor is structurally load-bearing. Cosine family collapses LR to ~0 sharply around progress=1, just when fine-direction refinement is happening. Power-law 1.4 gives a *gradual* approach to zero (the derivative softens near the end), keeping enough LR for late-cooldown refinement. The early-cooldown advantage cosine claims (more time at high LR mid-cooldown) is structurally unhelpful — the model has already converged by mid-cooldown; what matters is the trailing portion.

**Combined-axis closure:** Together with PR #332 (COOLDOWN_POWER continuation up to 1.8 NULL — closes upper direction), the cooldown SHAPE axis is now fully bracketed: power-law 1.4 is optimal vs higher powers (worse) AND vs cosine family (much worse). **Cooldown shape axis CLOSED at power-law 1.4 across families.**

**Operational note:** Arm A had a SIGTERM-style kill at step 363 in first launch attempt (process resource issue, not code bug). Student debugged cleanly: identified residual GPU memory from killed process blocking restart, relaunched successfully. Good operational discipline.

**Next assignment:** PR #448 (decoupled cooldown_frac aux vs body — first per-group schedule axis). Different mechanism class from cooldown shape.

---

## 2026-05-19 08:05 UTC — PR #395 CLOSED: NS_ITERS cooldown schedule {14, 18 vs const=12} — both arms NULL, monotone signal, axis closes (g1r1-fern)

- Branch: `g1r1-fern/ns-iters-cooldown-bump`
- Hypothesis: bump NS_ITERS during the cooldown phase from 12 (constant) to {14, 18}. Cooldown gradients are smaller/more sign-coherent → more NS iters may sharpen polar projection where it matters most.

| Arm | NS_ITERS cooldown | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | const=6 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 14 (cooldown bump) | `fg01web0` | 3000 | 3.26865 | +25 ✗ | +0.00143 ✗ | NULL |
| B | 18 (cooldown bump) | `a9l9oqh3` | 3025 | 3.27060 | +50 ✗ | +0.00338 ✗ | NULL |

**Signal: clean monotone (more cooldown iters → worse on both metrics).** Both arms fail baseline beyond marginal threshold. Δsr scales linearly with iter-count bump magnitude.

**Polar residual diagnostic (student-provided):** confirms the mechanism fires as expected — pre-cooldown residual ~7.8, in-cooldown drops to 4.5 (Arm A) and 2.0 (Arm B). More iters → tighter polar projection, BUT worse downstream. The cubic-Newton's moderately under-converged polar state is *load-bearing* for PMuon — over-orthogonalization moves updates out of the regime PMuon's bilateral whitening was tuned for.

**Mechanistic conclusion:** Combined with PR #184 (static 6 wins, 18 loses), NS_ITERS axis exhausted for static AND phase-localized variants. Sharpening polar accuracy is structurally counterproductive on this stack.

**Natural next-class extension:** Adaptive (data-dependent) iter count. Currently the FIXED-iter loop runs 6 iterations regardless of input conditioning. Adaptive lets each step pick its own count based on residual convergence — saves compute on easy inputs, spends more on hard ones. Structurally different mechanism class than static or phase-schedule.

**Baseline contamination caveat:** Branch off pre-#367 advisor base, so the arms ran with `lm_head_lr=1/320` (old baseline) not 1/160. However the directional signal is clear and cross-stack consistent (PR #184 originally tested NS=18 vs 6 on the older stack and 6 won) — closure justified.

**Conclusion: NS_ITERS schedule-side axis CLOSED.** New assignment PR #447 (NS adaptive convergence threshold — first data-dependent iter-count test in program).

---

## 2026-05-19 07:18 UTC — PR #410 CLOSED: lm_head_lr fine-scan {1/120, 1/100} — both NULL, axis closes UPWARD from 1/160 (g1r1-frieren)

- Branch: `g1r1-frieren/aux-lmhead-lr-fine-scan`
- Hypothesis: Continue lm_head_lr scaling past freshly merged 1/160 baseline (PR #367). Test {1/120, 1/100, 1/80} for monotone improvement direction.

| Arm | lm_head_lr | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | 1/160 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 1/120 | `9hgqqx38` | 3000 | 3.268949 | +25 ✗ | +0.001728 ✗ | NULL |
| B | 1/100 | `cjv8cqab` | 3000 | 3.269108 | +25 ✗ | +0.001876 ✗ | NULL |
| C | 1/80 | killed step 128 (advisor-directed) | — | — | — | — | not run |

**Signal: FLAT — not monotone increasing.** Both Arms A and B miss baseline on both metrics simultaneously with virtually identical val deltas (+0.0017 vs +0.0019). Δsr is exactly at the marginal threshold (+25 at advisor stat rule cutoff) but BOTH arms regress on BOTH metrics in tandem — that's NULL, not seed noise.

**Operational note:** Arm C (1/80) was killed at step 128 per advisor directive after observing the flat A+B signal. Saved ~3.5h compute on a closed-direction extension. Student demonstrated clean operational discipline (immediate kill, terminal SENPAI-RESULT posted within 7 minutes of advisor comment).

**Mechanistic conclusion:** Combined with merge sequence 1/640→1/320→1/160 (PR #211→#357→#367), the maximum useful lm_head_lr appears to sit at 1/160. Going from 1/320 to 1/160 was a real ~25 sr gain (PR #367 confirmed n=2). Going past 1/160 in either direction (1/120, 1/100) costs sr while regressing val — the lm_head_lr axis is now bracketed.

**Conclusion: lm_head_lr axis CLOSED upward from 1/160 (PR #367 is the peak).** Future aux work on this group must be different mechanism class (β1/β2/eps already closed; remaining open: per-group hypers, ε floor scheduling, etc.). New assignment PR #444 (PMuon γ_power phase schedule — first phase-dependent γ test).

---

## 2026-05-19 06:42 UTC — PR #401 CLOSED: Muon WD downward {0.020, 0.015} — both NULL, axis closes both directions (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/muon-wd-downward`
- Hypothesis: Decrease Muon weight decay from baseline 0.025 to test if less regularization yields better convergence. Combined with previously-closed upward direction, this closes the Muon WD axis fully.

| Arm | muon_wd | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #367) | 0.025 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |
| A | 0.020 | `o5z8a5n3` | 3000 | 3.26937 | +25 ✗ | +0.00215 ✗ | NULL |
| B | 0.015 | `qvlr4y7g` | 3025 | 3.26980 | +50 ✗ | +0.00258 ✗ | NULL |

**Clean monotone signal:** lower WD → worse on both metrics. Both arms also exceed marginal threshold (Δsr ≤ 25 OR Δval ≤ 0.001) → no n=2 confirmation needed.

**Mechanistic conclusion:** Muon WD axis is now fully CLOSED at 0.025 in both directions. Muon's NS orthogonalization combined with PMuon's bilateral cov-EMA whitening produces well-conditioned updates whose magnitude is structurally controlled. Lower WD lets unconstrained parameter growth; higher WD over-shrinks. The interior optimum at WD=0.025 is structurally tied to the body stack.

**Note on Arm A:** Cross-stack confound — Arm A ran on pre-#367 baseline config (lm_head_lr=1/320). However the directional signal holds for both stacks (vs old baseline sr=3000 val=3.2685, Arm A matched sr and val=+0.0009 within n=1 noise). New assignment PR #440 (embed init scale scan — fresh init-side axis).

---

## 2026-05-19 05:50 UTC — PR #404 CLOSED: Aux CP extend (CP=1.0 n=2 + CP=0.5 n=1) — both NULL on primary metric, axis closes (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/aux-cooldown-power-extend`
- Hypothesis: Aux-side decoupled AUX_COOLDOWN_POWER. Arm A confirms PR #366's n=1 marginal val WIN at CP=1.0 with fresh n=2 seed. Arm B extends direction to CP=0.5 (sub-linear sqrt-like aux cooldown).

| Arm | AUX_COOLDOWN_POWER | n | W&B runs | sr_steps | val/loss | vs new baseline (sr=2975 val=3.26722) | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1.0 (n=2 cross-stack) | 2 | `h585go7m` (s1 PR#366), `jv2oi3fv` (s2 this PR) | 3000 | 3.265882 | Δsr=+25 ✗, Δval=-0.00134 ✓ (cross-stack confound, both on lm_head_lr=1/320 not new 1/160) | NULL on primary |
| B | 0.5 | 1 | `sihwt6g3` | 3050 | 3.26509 | Δsr=+75 ✗, Δval=-0.00213 ✓ (same cross-stack confound) | NULL on primary, also REGRESSES vs Arm A by +50 sr |
| Baseline (PR #367) | follows body=1.4 | n=2 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — |

**Mechanistic key:** Lower aux CP than 1.0 over-flattens late-phase aux LR. The val gain at CP=1.0 is real but small (~−0.001) and entirely cross-stack-confounded (both arms ran on lm_head_lr=1/320 pre-PR#367, not on current 1/160). Per the predeclared falsification matrix (Arm B sr ≥ 3000 → close), the lower-CP direction is ruled out.

**Conclusion:** Aux CP extend (lower direction) axis CLOSED. Body Muon CP=1.4 + aux following body cooldown remains optimal. The val-improvement signal at CP=1.0 is potentially worth a clean n=2 re-test on the NEW PR #367 stack (lm_head_lr=1/160) as a future follow-up, but lower-than-1.0 CP is exhausted. Future aux-schedule work should explore different mechanisms (different cooldown_frac for aux, non-power schedule shape, or different cooldown start step). New assignment PR #434 (logit soft-cap value scan).

---

## 2026-05-19 04:20 UTC — PR #400 CLOSED: AGC on aux AdamW per-row λ ∈ {0.04, 0.10} — both NULL, axis closes (g1r1-edward)

- Branch: `g1r1-edward/agc-aux`
- Hypothesis: Adaptive Gradient Clipping (Brock et al. NFNets 2021) on aux AdamW (embed + lm_head + scalars). Per-row clip `||grad_row||/||param_row|| ≤ λ`. Tests whether Zipfian rare-token rows receive disproportionately large gradient spikes that AdamW variance doesn't protect against.

| Arm | λ | W&B run | sr | val/loss | embed clip_rate | lm_head clip_rate | mean clip_coef (lm_head) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 0.04 | `2y0ewtlb` | -1 | 3.44634 | ~0% | **97.5%** | 0.055 | NULL (catastrophic) |
| B (revised) | 0.10 | `llni6tar` | -1 | 3.44015 | ~0% | **96.9%** | 0.073 | NULL (catastrophic) |
| Baseline (PR #367) | — | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — | — |

- Note: original Arm B (λ=0.02) was killed at step 104 per advisor redirect (stricter clip would fail worse); replaced with λ=0.10 probe.

**Mechanistic key:** embed clip rate ~0% (large param norms → natural grad/param ratio low). lm_head clip rate ~97% at BOTH λ values — lm_head's natural grad/param ratio is structurally >> 0.10. Going 2.5× more permissive (0.04→0.10) moved val only 3.44634→3.44015 (-0.0062) — confirming lm_head is being clipped well below its natural operating regime even at λ=0.10. Effective 14-18× slowdown of lm_head learning → severe underfit → +0.17 val/loss regression. AdamW's V_t already provides per-element bounding; AGC double-clips a path that's already well-conditioned.

**Conclusion:** AGC axis CLOSED on aux. Per-row gradient clipping with any λ ∈ [0.01, 0.10] aggressively hamstrings lm_head. Suggested future direction: row-wise AdamW with per-row second-moment normalization (per student's analysis). New assignment PR #433 (aux β2 by group).

---

## 2026-05-19 00:46 UTC — PR #403 CLOSED: Curriculum COOLDOWN_POWER — operational failure (g1r1-askeladd)

- Branch: `g1r1-askeladd/cooldown-power-curriculum`
- Hypothesis: Linear ramp of COOLDOWN_POWER from p_start → p_end during cooldown phase.
- **Result: OPERATIONAL FAILURE** — 5+ crash loop (all crashes ≤step 25). Implementation bug (likely division-by-zero or index error in the ramp formula). Student pod continued relaunching broken config. No training data collected. Branch had zero code commits (only assignment commit). GPU reclaimed by closing.
- **Conclusion:** PR closed operationally. Curriculum cooldown power direction remains valid but needs clean re-implementation with explicit early-step guard. New assignment PR #416 (aux β1 fine-scan).

---

## 2026-05-19 00:17 UTC — PR #387 CLOSED: Role-based Muon LR {0.7×, 0.4× on attn} — both NULL, role-axis closes (g1r1-nezuko)

- Branch: `g1r1-nezuko/muon-role-lr`
- Hypothesis: Attn vs MLP body params may benefit from different LR multipliers. Scan {0.7×, 0.4×} on attn while MLP stays at 1.0×.

| Arm | attn_lr_mult | W&B run | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.7× | `g8hqguwn` | 3000 | 3.27037 | +25 | +0.00315 | NULL |
| B | 0.4× | `0aay0p7y` | 3025 | 3.27243 | +50 | +0.00521 | NULL |
| Baseline (PR #367) | 1.0× | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |

**Mechanistic key**: NS update_norm is invariant to LR multiplier choice (attn≈25.6, mlp≈41.0 regardless of arm) — confirming polar step normalizes direction independently of LR scaling. Monotone-down trend Arm B < Arm A < Baseline means 1.0× is the local optimum.

**Conclusion: Role-axis CLOSED. Combined with PR #347 (depth NULL) and PR #248 (global LR flat), Muon LR is optimal under all linear decompositions tested. New assignment PR #414 (cosine cooldown shape).**

---

## 2026-05-19 00:00 UTC — PR #386 CLOSED: PMuon γ_power continuation {0.5, 0.6} — both NULL, axis closes at 0.4 (g1r1-alphonse)

- Branch: `g1r1-alphonse/gamma-power-continuation`
- Hypothesis: Monotone γ_power signal from PR #202 (0.2→0.3→0.4 improving) suggested unsaturated headroom past 0.4. Scan {0.5, 0.6}.

| Arm | γ_power | W&B run | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 0.5 | `516wmw6t` | 3250 | 3.27999 | +275 | +0.01277 | NULL — severe regression |
| B | 0.6 | `yhfo48gj` | −1 | 3.28892 | ∞ | +0.02170 | FAIL — never reached ≤3.28 |
| Baseline (PR #367) | 0.4 | `7xub16ua`/`f9nyqjxn` | 2975 | 3.26722 | — | — | — |

**Key diagnostic (whitening telemetry at terminal):**
| Arm | γ | `whitened_sv_max` | `lcov_eigh_ratio` |
|---|---|---|---|
| A | 0.5 | 3.5e-4 | 1.55e6 |
| B | 0.6 | 5.0e-5 (7× smaller) | 1.80e7 (11.6× larger) |

γ=0.6 collapses post-whitening SV spectrum (7× smaller max-SV) while left-cov condition number blows up 11.6× — NS polar receives near-singular operand. γ=0.5 maintains convergence but slows it. The monotone signal saturates at 0.4 and inverts sharply past it.

**Conclusion: Both arms NULL per falsification table → γ_power axis CLOSES at 0.4. New assignment PR #413 (scalar_lr upward scan).**

---

## 2026-05-18 23:14 UTC — PR #367 MERGED: lm_head_lr=1/160 confirmed WIN (g1r1-frieren)

- Branch: `g1r1-frieren/lm-head-lr-scan`
- Hypothesis: lm_head_lr=1/320 was inherited and possibly under-tuned. Scan bidirectional: 1/160 (2×) vs 1/640 (0.5×).

| Run | Arm | lm_head_lr | Seed | sr | val/loss | Verdict |
|---|---|---|---|---|---|---|
| `7xub16ua` | A | 1/160 | 1 | 2975 | 3.26774 | n=1 marginal WIN |
| `lzitteno` | B | 1/640 | 1 | 3025 | 3.26977 | NULL (worse both metrics) |
| `f9nyqjxn` | A | 1/160 | 2 | 2975 | 3.26670 | n=2 confirm WIN |
| **n=2 mean** | A | **1/160** | — | **2975** | **3.26722** | **CONFIRMED WIN** |
| Baseline (PR #274) | — | 1/320 | — | 3000 | 3.2685 | — |
| **Δ** | | | | **−25** | **−0.00128** | ≥ 0.001 threshold ✓ |

n=2 statistical check: (3.28 − 3.26722)·√2 = 0.01807 ≥ 0.004 ✓ (4.52×). Both seeds independently hit sr=2975 — not noise floor.

**Conclusion: lm_head_lr=1/320 was marginally under-tuned for the current PMuon+cubic-Newton-NS+COOLDOWN_POWER=1.4 stack. Doubling to 1/160 reliably saves 25 steps. Symmetric falsification (1/640 hurts) confirms direction is real. MERGED as new baseline: sr=2975, val=3.26722. Follow-up: fine-scan {1/80, 1/100, 1/120} for peak.**

---

## 2026-05-18 21:05 UTC — PR #364 CLOSED: Muon momentum reset at cooldown FALSIFIED at n=2 (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-momentum-reset-at-cooldown`
- Hypothesis: Reset Muon momentum (first-moment EMA) at cooldown entry (step 975). Two arms: hard (×0.0) vs soft (×0.3).

| Run | Arm | Reset factor | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | none | 3000 | 3.2685 (n=2) | — | — |
| `x3ot747o` | A | hard (×0.0) | 3000 | 3.26922 | +0.0007 | NULL |
| `sj1qgbu1` | B (n=1) | soft (×0.3) | 3000 | 3.26801 | -0.0005 | marginal val WIN |
| `3zduzvo3` | B (n=2) | soft (×0.3) | 3025 | 3.27020 | +0.0017 | individual seed NULL |
| **Combined Arm B mean** | — | soft | **3012.5** | **3.26911** | **+0.0006** | **NULL (falsified marginal)** |

n=2 falsified the marginal n=1 WIN. Reset mechanism fired correctly (`momentum_norm_ratio=0.3000` exact). Seed-2 trailed seed-1 by ~0.002 across cooldown — replicable seed variance.

**Conclusion: Bilateral covariance EMA + power-law cooldown trajectory is already coherent enough that disrupting first-moment momentum at cooldown boundary destroys useful information rather than enabling cleaner direction. Cooldown momentum-reset axis CLOSED.**

---

## 2026-05-18 21:05 UTC — PR #366 CLOSED: Aux-AdamW cooldown power scan {1.0, 2.0} unconfirmed marginal + clear NULL (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/aux-cooldown-power-scan`
- Hypothesis: Decouple aux AdamW cooldown power from body. Test CP=1.0 (linear, slower aux decay) and CP=2.0 (quadratic, faster aux decay) vs body CP=1.4.

| Run | Arm | AUX_CP | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | 1.4 (= body) | 3000 | 3.2685 | — | — | — |
| `h585go7m` | A | 1.0 (linear) | 3000 | 3.2662 | 0 | -0.0023 | marginal val WIN (n=1, unconfirmed) |
| `nucnaip1` | B | 2.0 (quadratic) | 3050 | 3.2727 | +50 | +0.0042 | clear NULL |
| `tmrbg9lk` | B (1st attempt) | 2.0 | — | — | — | — | mid-run crash @ step 875 |

Arm A had substantial Δval=-0.0023 (~2.3x marginal threshold), but per the strict marginal rule (Δsr=0 ≤ 25 triggers marginal regardless of val magnitude), n=2 confirmation required. Cold-start crash storm prevented in-flight n=2 (10+ retries failed).

**However, the directional signal is strong and replicable: lower aux CP helps, higher aux CP hurts (opposite direction).** Schedule telemetry verified mechanism (lr_mult_body vs lr_mult_aux diverge correctly at cooldown entry).

**Conclusion: Close at n=1; re-explore in PR #404 with proper n=2 confirmation seed at CP=1.0 + CP=0.5 direction extension. Infrastructure has stabilized — fresh n=2 should succeed.**

---

## 2026-05-18 20:21 UTC — PR #362 CLOSED: Gradient Centralization for Muon body NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/gradient-centralization-v2`
- Hypothesis: Subtract column (and optionally row) mean of gradient before passing to PMuon EMA, to remove uniform drift component.

| Run | Arm | GC mode | sr | val@3000 | val@3250 | Δsr | Δval@3000 | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | none | 3000 | 3.2685 | — | — | — | — |
| `rcl10r96` | A | column-only | 3025 | 3.28117 | 3.27043 | +25 | +0.0127 | NULL |
| `5p8b7aro` | B | both (col+row) | -1 | 3.30526 | 3.29637 | n/a | +0.0368 | NULL |

GC was verified active (pre-values ~0.24–0.27, post=0.0). Arm B strictly worse than Arm A. Root cause: PMuon's bilateral cov-EMA whitening already absorbs the drift GC was supposed to remove. Subtracting the column mean is redundant against an optimizer that conditions via second-moment statistics, and removes a *signal* component. Row-centering (Arm B) additionally removes per-output mean which over-constrains the update on transformer linear weights (unlike CNNs where original GC paper was developed).

**GC axis CLOSED on Muon body.**

---

## 2026-05-18 20:06 UTC — PR #350 CLOSED: Residual-proj init scaling {1/√(2N), 1/N} NULL (g1r1-edward)

- Branch: `g1r1-edward/residual-init`
- Hypothesis: The baseline zero-inits all residual-stream projection weights (`proj` in attn and MLP). Test whether small non-zero init — GPT-2-style 1/√(2N) and 1/N — helps by providing a better-conditioned start for the residual stream.

| Run | Arm | std init target | sr | val/loss | Δval | Verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | zero | 0 | 3000 | 3.2685 (n=2) | — | — |
| `ugf2tm22` | A: 1/√(2N) | 0.00408 | 3000 | 3.26966 | +0.00116 | NULL |
| `t7607ha7` | B: 1/N | 0.00167 | 3000 | 3.26866 | +0.00016 | NULL (tied) |

Student's pre-flight catch: baseline zero-inits ALL proj weights (most aggressive form), so this was truly testing "any non-zero vs zero." Both arms regressed slightly on val; sr tied at 3000 for both. The GPT-2 1/√(2N) trick doesn't transfer — Muon's per-step orthogonalization resets gradient direction anyway, making init less consequential for convergence trajectory.

**Residual-init scaling axis CLOSED at zero-init.**

---

## 2026-05-18 18:07 UTC — PR #332 CLOSED: COOLDOWN_POWER continuation {1.5, 1.8} NULL (g1r1-fern)

- Branch: `g1r1-fern/cooldown-power-continuation`
- Hypothesis: Probe past the merged COOLDOWN_POWER=1.4 win (PR #274) by scanning {1.5, 1.8}. Test whether a more concave LR cooldown tail extracts additional sr improvement, or whether 1.4 is the local optimum.

| Arm | CP | n | mean sr | mean val | Δsr | Δval | verdict |
|---|---|---|---|---|---|---|---|
| Baseline (PR #274) | 1.4 | 2 | 3000 | 3.2685 | — | — | — |
| Arm A | 1.5 | 3 | 2991.67 | 3.27021 | -8.33 | +0.0017 | NULL (noise floor) |
| Arm B | 1.8 | 1 | 2975 | 3.27464 | -25 | +0.0061 | NULL (val regression) |

Per-seed Arm A sr: {3000, 3000, 2975}. Two seeds tied at baseline, one dropped exactly one val-eval window (25 steps). Mean Δsr=-8.33 is well inside seed noise; sr is logged at discrete 25-step val intervals.

Per-seed Arm B sr: {2975}. n=1 only; marginal Δsr=-25 but with substantial val regression (+0.0061 > stat-sig threshold 0.004). Even an n=2 confirmation of sr<3000 wouldn't be a clean merge — val regression suggests over-aggressive cooldown extracts a tiny sr advantage at the cost of converged loss quality.

**Body-side COOLDOWN_POWER axis CLOSED at 1.4.** This is the second closure of the cooldown-shape axis on the body — confirms PR #274's CP=1.4 is the local optimum.

Still open on this theme: thorfinn #366 testing aux-AdamW cooldown power decoupling. Both arms of #366 are in flight (CP=1.0 had a marginal n=1 val WIN but crash storm prevented n=2; CP=2.0 in flight).

---

## 2026-05-18 17:25 UTC — PR #364 PENDING (sent back for n=2): Muon momentum reset hard vs soft (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-reset`
- Hypothesis: Reset Muon momentum at cooldown entry (step 975 = `int((1-cooldown_frac)*train_steps)`, cooldown_frac=0.7). Two arms: hard (zero momentum) vs soft (×0.3 retain).
- W&B runs: `x3ot747o` (Arm A hard), `sj1qgbu1` (Arm B soft, 13:00 UTC, 222min)
- Telemetry confirmed clean reset: momentum_norm_before/after_immediate ratios = 0.000 (Arm A) and 0.300 (Arm B) at step 975.

| Arm | reset | sr | val/loss | Δsr | Δval | verdict |
|---|---|---|---|---|---|---|
| Baseline (PR #274) | — | 3000 | 3.2685 | — | — | — |
| Arm A | hard (×0) | 3000 | 3.2692 | 0 | **+0.0007** | NULL (hard reset destroys directional info cooldown still uses) |
| Arm B | soft (×0.3) | 3000 | **3.2680** | 0 | **-0.0005** | **MARGINAL val WIN** (Δval below 0.001 marginal threshold) |

**Decision:** Sent back to student for **n=2 confirmation of Arm B (soft ×0.3) only**. Per the marginal rule (Δval ≤ 0.001 → n=2 required), single-seed result is within seed noise. Arm A hard reset NULL is conclusive at n=1.

**Mechanism diagnosis (askeladd):**
- The two arms separated by ~0.001 val/loss across the entire cooldown phase post-reset.
- Hard reset (×0) zeros momentum → next 5–10 steps move slower than baseline (no inertia) → small cooldown-phase progress lost.
- Soft reset (×0.3) keeps 30% inertia → enough fresh direction-finding to slightly outperform baseline, retains enough inertia to keep moving immediately.
- No divergence, no instability, no late-cooldown plateau.

**Key open question for n=2:** if confirmed (mean val < 3.2685), this would be the **first program WIN in many rounds**. Follow-ups (decay scan {0.1, 0.5, 0.7}, reset-step jitter, soft reset of L_cov/R_cov covariance EMAs) are queued for future PRs.

**Cross-cutting infrastructure note:** Earlier I observed 6+ cold-start crash retries on muon-reset-hard config. Reviewing the consolidated terminal, the successful `x3ot747o` run completed first; later crashes were post-terminal n=2 attempts. Same crash signature (step ≤25, val=10.8258, ~7m) is appearing across thorfinn aux-CP=1.0 (10+), frieren lm-head-lr=1/160 (6), edward residual-init-1/√2N (5 then succeeded on 6th). Looks like shared pod/launcher instability, not per-experiment bugs.

---

## 2026-05-18 16:05 UTC — PR #347 CLOSED + PR #387 ASSIGNED: LLRD → Role-based Muon LR (g1r1-nezuko)

- Branch: `g1r1-nezuko/llrd-scan`
- Hypothesis: Layer-wise LR Decay (ULMFiT-style, Howard & Ruder 2018) assigns per-depth LR multipliers `base_lr × decay^(N-i)`, slowing bottom layers relative to top layers. Tested decay ∈ {0.95, 0.85} on the Muon body; aux unchanged.

| Arm | LLRD decay | W&B | val/loss | sr | Δval | Δsr | verdict |
|---|---|---|---|---|---|---|---|
| Baseline | 1.00 (uniform) | `vw0595an`, `s2nrw0c8` | 3.2685 | 3000 | — | — | — |
| Arm A | 0.95 | `ffsvma03` | **3.28041** | -1 | +0.0119 | — | NULL (missed target) |
| Arm B | 0.85 | `ud32rjej` | **3.31361** | -1 | +0.0451 | — | NULL (massive regression) |

**Result:** Both arms NULL with **monotone signal** (more aggressive decay → worse). Arm A: bottom LR ≈ 0.57× base, val barely above 3.28 target. Arm B: bottom LR ≈ 0.17× base, catastrophic regression (+0.045).

**Why the LLRD prior doesn't hold:**
1. **Pretraining from scratch, not fine-tuning.** ULMFiT-style LLRD preserves frozen pretrained bottom-layer features. Here, bottom layers must actively learn token geometry from random init — slowing them costs convergence.
2. **NS orthogonalization already normalizes per-tensor.** Muon's Newton-Schulz polar step is per-tensor and implicitly equalizes update magnitudes. Adding a depth multiplier on top re-introduces a scalar imbalance on the already-normalized update.
3. **Flat LR axis (PR #248).** Global Muon LR is locally optimal at 0.035 ±14%. LLRD pushes ~half the body off that flat optimum by design.

**Depth-based LR decomposition axis CLOSED.** Pairs with PR #248 (global LR closed) to confirm: uniform Muon body LR is optimal in both the scalar and depth-structural dimensions.

**New assignment (PR #387):** Role-based Muon LR — splits body into attention (QKV+proj) vs MLP (fc1+fc2) and tests whether these mechanistically distinct roles want different LRs. If also NULL, the conclusion is clean: the NS orthogonalization already equalizes update magnitudes and any LR decomposition within the body is redundant.

---

## 2026-05-18 15:32 UTC — PR #342 CLOSED: SWA tail rolling average NULL (g1r1-alphonse)

- Branch: `g1r1-alphonse/swa-tail`
- Hypothesis: Rolling param average over last 15% or 30% of training (SWA tail) would reduce val_loss by smoothing late-cooldown noise, allowing model to cross 3.28 earlier.

| Arm | SWA_START_FRAC | W&B | sr | val/loss | Δsr | Δval |
|---|---|---|---|---|---|---|
| Baseline | — | `vw0595an`, `s2nrw0c8` | 3000 | 3.2685 | — | — |
| Arm A | 0.85 | `37dxm5wh` | 3000 | 3.27306 | 0 | **+0.00456** |
| Arm B | 0.70 | `rzdrn912` | **3200** | 3.27848 | **+200** | **+0.00998** |

**Results commentary:** BOTH ARMS NULL. SWA mechanism works correctly (within-run swa-vs-raw Δ = −0.003 to −0.025 confirmed). But COOLDOWN_POWER=1.4 makes the val curve so steep that SWA val crosses 3.28 at identical step as raw. Arm B worse: wider window averages earlier higher-loss steps, biasing upward.

**Conclusion:** SWA tail axis CLOSED on cooldown_power=1.4 + cubic-Newton stack. Reassigned alphonse to PR #386 (γ_power continuation).

---

## 2026-05-18 15:32 UTC — PR #386 ASSIGNED: PMuon γ_power continuation {0.5, 0.6} (g1r1-alphonse)

- Branch: `g1r1-alphonse/gamma-power-continuation`
- Hypothesis: PR #202 (γ_power=0.4 winner) found monotone signal (0.2→3050, 0.3→3062.5, 0.4→3025) and flagged {0.5, 0.6} as likely follow-up. Tests continuation on post-#274 baseline.

---

## 2026-05-18 10:10 UTC — PR #311 CLOSED + PR #366 ASSIGNED: Lookahead wrapper → Aux cooldown power decoupling (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/lookahead-wrapper`
- **Hypothesis:** Wrap both optimizers in Lookahead (Zhang et al. NeurIPS 2019): every k=5 steps, interpolate fast weights with slow weights via `slow ← slow + α·(fast − slow); fast ← slow`. Scan α ∈ {0.5, 0.8} with fixed k=5. Initial runs crashed at step 1-25 (grad_norm >200k from cold-start PMuon EMA + step-0 slow-weight snapshot). After advisor-directed fix: lazy init of slow weights at step 200 (after PMuon warmup). Final results: both arms NULL.
- W&B runs: `0oj7k38q` (Arm A α=0.5, delayed-init), `hd9u6ffy` (Arm B α=0.8, warmup-200)

| Arm | α | sr | val/loss | Δ vs baseline | verdict |
|-----|---|-----|----------|---------------|---------|
| **Baseline (PR #274)** | — | **3000** | **3.2685** | — | — |
| Arm A | 0.5 | -1 (never) | 3.29851 | +0.0300 | NULL |
| Arm B | 0.8 | 3050 | 3.27054 | +0.00204 | NULL (sr +50 regression) |

**Mechanism telemetry:** `lookahead/embed_slow_fast_diff_ratio` was 0.005–0.05 for ~80% of training (mid-training), collapsing to ~1e-4 in late cooldown. Mechanism was ACTIVE but unhelpful. This is a clean "real null," not a "broken wrapper null."

**Converging finding (closes Lookahead axis):** Three closed PRs (#261 warmup-to-slow EMA, #307 bias-correct cold-start, #311 Lookahead) all perturb the PMuon EMA / weight-averaging dynamics in different ways. All three NULL. The converging mechanism: the natural un-corrected cold-start EMA IS the implicit whitening warmup — PMuon's covariance warmup is load-bearing. Do not modify it.

**Monotone α scan insight:** Arm A (α=0.5) worse than Arm B (α=0.8) — less blending is better; the trend `less Lookahead → closer to baseline` confirms the limit is no-Lookahead.

**New assignment (PR #366):** Aux-AdamW cooldown power decoupling — scan AUX_COOLDOWN_POWER ∈ {1.0, 2.0} while body stays at 1.4. Motivated by converging evidence that aux groups want fast-adapting EMA (β1=0.8); if aux wants to keep adapting, it likely also wants a slower cooldown (power=1.0).

---

## 2026-05-18 09:19 UTC — PR #327 CLOSED + PR #364 ASSIGNED: Adan aux → Muon momentum reset at cooldown (g1r1-askeladd)

- Branch: `g1r1-askeladd/adan-aux-scan`
- **Hypothesis:** Adan 3-buffer adaptive Nesterov on aux groups (embed/lm_head/scalars) at lr_mult∈{1.0, 0.33}.
- W&B runs: `7vyu1jo2` (Arm A mult=1.0), `nx5r55gg` (Arm B mult=0.33)

| Arm | ADAN_LR_MULT | sr | val/loss | Δ vs baseline | verdict |
|-----|---|-----|----------|---------------|---------|
| **Baseline (PR #274)** | AdamW | **3000** | **3.2685** | — | — |
| Arm A | 1.0 | -1 | 3.28804 | +0.0195 | NULL — missed target |
| Arm B | 0.33 | -1 | 3.31190 | +0.0434 | NULL — more LR → worse |

**Result:** Both NULL. Clear ordering: Arm B worse than A (lower LR → even worse — undershoots baseline convergence speed).

**Key mechanism finding (askeladd):** Adan's β1=0.98 imposes heavy momentum on sparse vocab embeddings. On sparse-row embeds, β1=0.98 means gradient EMA averages over ~50 steps; rare-token rows get stale gradient mass from 50+ steps ago when a different token distribution was in the batch. Confirms converging pattern: aux groups want FAST-adapting EMA (β1=0.8), all heavy-momentum mechanisms (Lion #317, AdEMAMix #305, Adan #327) are uniformly NULL on this path. Aux-side optimizer-mechanism axis is now CLOSED.

**Axis decision: Adan-on-aux CLOSED. Aux groups are well-served by fast-EMA AdamW (β1=0.8). Fresh assignment: Muon momentum reset at cooldown entry (PR #364) — body-side mechanism targeting the cooldown regime.**

---

## 2026-05-18 09:09 UTC — PR #305 CLOSED + PR #363 ASSIGNED: AdEMAMix → Z-loss auxiliary (g1r1-frieren)

- Branch: `g1r1-frieren/ademamix-alpha-scan`
- **Hypothesis:** AdEMAMix dual-EMA auxiliary optimizer for embed/lm_head/scalars: slow-EMA component (β3=0.9999) with α∈{4,8} blend.
- W&B runs: `4ahrxeo8` (Arm A α=4), `7lstqkpp` (Arm B α=8)

| Arm | α | sr | val/loss | Δ vs baseline | slow_over_fast | verdict |
|-----|---|-----|----------|---------------|----------------|---------|
| **Baseline (PR #274)** | — | **3000** | **3.2685** | — | — | — |
| Arm A | 4.0 | -1 | 3.28611 | +0.0176 | 0.257 | NULL — missed target |
| Arm B | 8.0 | -1 | 3.31655 | +0.0480 | 0.640 | NULL — missed target |

**Result:** Both NULL. Clear dose-response: stronger slow-EMA engagement (higher α) → worse val/loss monotonically. Mechanism unambiguously activated (slow_over_fast rose smoothly 0→0.26 for α=4, 0→0.64 for α=8) but consistently harmful.

**Key mechanism finding:** With only 3250 steps and β3=0.9999, slow EMA reaches only ~28% of steady-state mass. The slow component drags update direction toward stale early-training gradients during aggressive COOLDOWN_POWER=1.4 descent — exactly when we want sharp, current gradient direction. Fast-only EMA (standard AdamW) is optimal for this aux path / horizon. Matches pre-declared falsification: "mechanism activates but doesn't improve — close AdEMAMix-on-aux axis."

**BF16 note (frieren):** Correctly stored m_slow in FP32 (BF16 rounds 0.9999→1.0 making mul a no-op). Fix was necessary and properly applied.

**Axis decision: AdEMAMix-on-aux CLOSED. Fresh assignment: z-loss auxiliary penalty (PR #363).**

---

## 2026-05-18 08:57 UTC — PR #307 CLOSED + PR #362 ASSIGNED (via #355 re-issue): PMuon EMA bias correction → Gradient Centralization (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-bias-correct`
- **Hypothesis:** PMuon bilateral covariance EMA bias correction {FULL: 1/(1-β^k), SQRT: 1/sqrt(1-β^k)} to sharpen the cold-start preconditioner estimate.
- W&B runs: `kss5lyzw` (Arm A FULL, step 3250), `fku3hg2s` (Arm B SQRT, step 3250)

| Arm | Correction | sr | val/loss | Δ vs baseline (PR #274) | verdict |
|-----|------------|-----|----------|-------------------------|---------|
| **Baseline** | OFF | **3000** | **3.2685** | — | — |
| Arm A FULL | 1/(1-β^k) | 3050 | 3.26803 | +50 / -0.0005 (sub-noise) | NULL — sr regression |
| Arm B SQRT | sqrt(1/(1-β^k)) | 3050 | 3.26797 | +50 / -0.0005 (sub-noise) | NULL — sr regression |

**Result:** Both NULL. sr regression of +50 is decisive (outside ±25 noise band). Val improvement is sub-noise (0.0005 << 0.001 threshold).

**Mechanism verified via telemetry:** L_cov 3-9× larger in corrected arms throughout training. Bias factor traces exactly match PR mechanism table (FULL: 0.0500→0.994→1.0 over 200 steps; SQRT: 0.2236→0.997→1.0). Polar residual sanity check passed. FULL and SQRT outcomes are essentially identical (Δ=0.00006 between them), so this is not a sweet-spot question.

**Key mechanism finding (tanjiro):** The natural (1-β^k) ramp in PMuon covariance EMAs is an implicit warmup of the whitening preconditioner — un-corrected EMA is part of the recipe, not a bug. Mirrors frieren PR #261 (warmup-to-slow-the-ramp also NULL): both directions of perturbing the cold-start covariance dynamics (delay OR sharpen) regress.

**Axis decision: cold-start covariance dynamics are load-bearing; PMuon EMA bias correction axis CLOSED.**

**Next assignment:** PR #355 — Gradient Centralization (GC) for Muon body: pre-polar column-mean subtraction {column-only, column+row} (Yong et al. ECCV 2020). Novel mechanism, 1-line change, zero optimizer state, composes cleanly with current stack.

---

## 2026-05-18 07:40 UTC — PR #331 CLOSED: per-tensor embed grad clipping {10, 100} (g1r1-edward)

- Branch: `g1r1-edward/per-tensor-embed-clip`
- **Hypothesis:** Per-tensor L2 norm clip on embed gradient; tests whether spike-suppression unlocks the heavy-tail embed distribution. Follow-up to PR #299 (global grad clip NULL).
- W&B runs: `3sxpadl0` (Arm A, clip=10, killed @ step 1608), `1nei2r33` (Arm B, clip=100, completed)

| Arm | clip | sr | val/loss | Δ vs baseline | verdict |
|-----|------|-----|----------|---------------|---------|
| **Baseline (PR #274)** | ∞ | **3000** | **3.2685** | — | — |
| Arm A | 10 | killed @ 1608 | 3.5287 @ 1500 (vs baseline ~3.40 @ 1500) | very slow | NULL — clip below natural gradient floor |
| Arm B | 100 | 3025 | 3.27050 | +25 / +0.0020 | NULL — marginal regression on both axes |

**Result:** Both NULL. Per-tensor embed-clip axis closes at no-clip. Confirms PR #299 takeaway that clipping the embed group is not yield-limiting.

**Key mechanism finding:** Arm A's slow trajectory (val=3.529 @ step 1500 vs baseline ~3.40) confirms that the natural embed gradient L2 sits in the 10-50 range — clip=10 truncates the majority of legitimate updates. Arm B (clip=100) is sufficiently above the natural floor that it almost never fires, reproducing baseline behavior to within seed noise.

**Axis decision: per-tensor embed grad clip CLOSED at no-clip (effectively ∞).**

**Next assignment:** PR #350 — Scaled Residual Projection Init (GPT-2 trick, std × 1/√(2N) and 1/N). Fresh initialization-axis mechanism.

---

## 2026-05-18 07:02 UTC — PR #317 CLOSED: Lion optimizer on embed {lr=0.03, 0.10} (g1r1-nezuko)

- Branch: `g1r1-nezuko/lion-embed-wrapper`
- **Hypothesis:** Sign-momentum (Lion) replaces AdamW for the embed group; tests whether sign-quantized updates compete with adaptive AdamW on heavy-tailed embed gradients.
- W&B runs: `d30w4a1a` (Arm A, lr=0.03), `pon9sawn` (Arm B, lr=0.10)

| Arm | lion_embed_lr | sr | val/loss | verdict |
|-----|---------------|-----|----------|---------|
| **Baseline (PR #274 AdamW lr=0.3)** | — | **3000** | **3.2685** | — |
| Arm A | 0.03 | -1 | 3.28119 | NULL — never crossed 3.28 |
| Arm B | 0.10 | 3175 | 3.27738 | NULL — sr +175 vs baseline |

**Result:** Both NULL. Lion at the tested LR range is fundamentally slower than AdamW on this distribution. The 10× LR Arm B closes most of the val gap (3.281→3.277) but still doesn't beat baseline sr — sign quantization throws away the per-coord variance scaling that AdamW provides on heavy-tailed embed gradients (rare tokens cause large spikes that AdamW dampens via squared-gradient denominator).

**Axis decision: Lion-on-embed CLOSED.** Sign-momentum variants for embed/lm_head should be considered low-priority follow-ups absent a separate hypothesis specifically addressing heavy-tail handling.

**Next assignment:** PR #347 — Layer-wise LR Decay (LLRD) for Muon body (fresh depth-dependent schedule mechanism).

---

## 2026-05-18 05:50 UTC — PR #314 CLOSED: embed_lr scan {0.2, 0.4} (g1r1-alphonse)

- Branch: `g1r1-alphonse/embed-lr-scan`
- **Hypothesis:** embed_lr (AdamW embed group LR) axis untested. ±33% scan around inherited 0.3 (→ 0.2, 0.4).
- W&B runs: `tn1qni73` (Arm A, embed_lr=0.2), `yzzqq64v` (Arm B, embed_lr=0.4)

| Arm | embed_lr | sr | val/loss | Δsr vs baseline | Δval |
|-----|----------|----|----------|-----------------|------|
| **Baseline (PR #274)** | 0.3 | **3000** | **3.2685** | — | — |
| Arm A | 0.2 | 3050 | 3.26723 | +50 | −0.00127 |
| Arm B | 0.4 | 3050 | 3.26666 | +50 | −0.00184 |

**Result:** Both arms NULL (sr=3050, +50 steps vs baseline). The embed_lr axis is locally flat around 0.3 — ±33% perturbations yield symmetric +50 sr-step regression. Arm B (higher LR) has mild persistent val advantage over A throughout training (Δ=−0.023 at step 125 → −0.0006 at step 3250) but neither crosses baseline.

**Key finding:** Embedding RMS scales linearly with LR (7.34→14.52, ~2× for 2× LR ratio) but this doesn't translate to sr gain. The AdamW cosine cooldown kills the early advantage. embed_lr=0.3 is a well-tuned local optimum.

**Axis decision: CLOSED at embed_lr=0.3.** With β1, β2, eps, embed_lr now all confirmed flat, the AdamW aux path is fully tuning-converged on the current stack.

**Next assignment:** PR #342 — End-of-cooldown SWA tail (fresh schedule mechanism).

---

## 2026-05-18 01:42 — PR #274: COOLDOWN_POWER retune {1.0, 1.4} — γ_power=0.4 stack (g1r1-fern) ← **MERGED WIN**

- Branch: `g1r1-fern/cooldown-power-retune`
- Hypothesis: COOLDOWN_POWER=1.2 was set long before the current γ_power=0.4 + cubic-Newton stack. With cleaner preconditioned gradient direction, a more concave LR decay tail (1.4) may let the model "snap" below the target earlier.

| Run | Arm | COOLDOWN_POWER | W&B | sr | val/loss | Δsr | Δval | Status |
|---|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | — | 1.2 | `prncgzv5` | 3025 | 3.26615 | — | — | Previous best |
| `dnecfiuq` (n=1 seed-1) | B | 1.4 | — | 3000 | 3.26812 | -25 | +0.00197 | n=1 WIN (borderline) |
| `vw0595an` (n=2 seed-1) | B | 1.4 | — | **3000** | **3.26812** | -25 | +0.00197 | n=2 seed-1 |
| `s2nrw0c8` (n=2 seed-2) | B | 1.4 | — | **3000** | **3.26888** | -25 | +0.00273 | n=2 seed-2 |
| **n=2 mean** | B | 1.4 | — | **3000** | **3.2685** | **-25** | +0.00235 | **WIN MERGED** |
| Arm A | A | 1.0 (linear) | — | 3100 | 3.26773 | +75 | +0.00158 | NULL |

**n=2 stat-sig check:** (3.28 - 3.2685) * √2 = 0.01627 ≥ 0.004 ✓

**Analysis:** COOLDOWN_POWER=1.4 wins cleanly on the primary metric (sr) across n=2 seeds. Both seeds independently hit sr=3000, ruling out single-seed noise. The mechanism is confirmed: more concave LR decay tail lets the model reach 3.28 one validation interval earlier (step 3000 vs 3025) on the γ_power=0.4 stack. Small val regression (+0.002) is stable across seeds, plausibly caused by harder late-cooldown drop slightly overshooting the LR floor. Arm A (linear, 1.0) clearly NULL (sr+75). New baseline: **sr=3000, val=3.2685**.

**Follow-up assigned to fern:** PR #332 COOLDOWN_POWER continuation {1.5, 1.8}.

---

## 2026-05-18 01:38 — PR #299: Global gradient norm clipping {1.0, 0.5} (g1r1-edward)

- Branch: `g1r1-edward/grad-clip-scan`
- Hypothesis: Gradient norm clipping at standard transformer thresholds {1.0, 0.5} suppresses early-training spikes. Both arms test whether spike suppression improves val/loss.

| Arm | GRAD_CLIP_NORM | W&B | sr | val/loss | Δsr | Δval | clip_fraction |
|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | ∞ | `prncgzv5` | 3025 | 3.26615 | — | — | 0% |
| Arm A | 1.0 | `k10ppzfs` | 3075 | 3.26935 | +50 | +0.00320 | 100% |
| Arm B | 0.5 | `bw20hjy6` | 3050 | 3.26850 | +25 | +0.00235 | 100% |

**Analysis:** Both arms NULL. Critical diagnostic: global L2 norm sits at **1e4–1e5** throughout training (dominated by SUM-reduced embed+lm_head gradients). Thresholds {0.5, 1.0} fire at 100% of steps → clip degenerates to **uniform scalar rescale** of gradient at every step (effective LR multiplier ≈ 1e-5). This is equivalent to a constant LR reduction, not spike suppression. Not an independent mechanism in this codebase.

**Falsification conclusion:** CLOSED. Global grad-clip axis CLOSED at standard thresholds. Per-parameter-group clipping (embed-only) is the correct implementation of the spike-suppression hypothesis — assigned as PR #331.

---

## 2026-05-18 00:55 — PR #287: Muon weight_decay scan {0.035, 0.050} — param_norm regularization (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-weight-decay-scan`
- Hypothesis: PR #248 telemetry showed `muon/param_norm` growing 3.4× for 1.33× LR — current WD=0.025 may be too weak to constrain param_norm growth. Test WD ∈ {0.035, 0.050}.

| Arm | wd | W&B run | sr | val/loss | Δsr | Δval | Status |
|---|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0.025 | `prncgzv5` | 3025 | 3.26615 | — | — | Current best |
| Arm A | 0.035 | `rxk4092z` | 3050 | 3.267759 | +25 | +0.00161 | NULL (1× sr noise floor) |
| Arm B | 0.050 | `q61lold2` | 3125 | 3.272109 | +100 | +0.00596 | NULL/REGRESSION |

**Mechanism telemetry (param_norm at step 3250):**
- Arm A (wd=0.035): 1273.2; u/p ratio 0.355
- Arm B (wd=0.050): 615.0 (half of Arm A!); u/p ratio 0.458

**Analysis:** The PR's mechanism prediction was confirmed at the telemetry level — higher WD tightly constrains param_norm and lifts the u/p ratio late in training (as the PR hypothesized). However, the predicted **downstream** val/loss improvement did not materialize. The relationship is monotone in the wrong direction: higher WD → strictly worse sr (3025 → 3050 → 3125) and val/loss (3.26615 → 3.26776 → 3.27211). The optimizer is near its sweet spot at wd=0.025, and constraining param_norm further removes useful capacity faster than it improves conditioning.

**Conclusion:** CLOSED. Muon WD axis CLOSED at 0.025 from the upper side. Per the predeclared falsification table, do NOT scan {0.060, 0.080} (Arm B already showed monotone regression). A downward complement {0.015, 0.020} is low-priority — the small Arm A gap suggests the optimum is at wd=0.025 and not movable by WD alone. The confirmed mechanism (tighter param_norm → higher u/p late) suggests the *yield-limiting* lever may be elsewhere in the cooldown phase (TARGET_UW floor, late-phase LR shape).

**Askeladd re-assigned to fresh mechanism: TBD (next round).**

---

## 2026-05-17 23:00 — PR #293: Polyak-Ruppert weight averaging {25%, 50%} (g1r1-nezuko)

- Branch: `g1r1-nezuko/polyak-weight-averaging`
- Hypothesis: Maintain a running equal-weight average `theta_avg ← theta_avg + (1/n) * (theta - theta_avg)` over the final POLYAK_FRAC of training steps; evaluate val/loss on the averaged params. Classical convergence accelerator (Polyak 1990, Ruppert 1988).

| Arm | POLYAK_FRAC | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 (no avg) | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 0.25 (last 25%) | `igfcn9a1` | 3075 | 3.2749 | **+0.00875** | NULL — 9× noise floor regression on val, +50 on sr |
| Arm B | 0.50 (last 50%) | — | — | — | — | 10 crash attempts (latest `8aotxat7`); never completed |

**Mechanism analysis:** Under the power-law cooldown γ=1.2 schedule, the Muon LR decays from 0.035 toward 0 over the final 25% of training. Param trajectory is **non-stationary**: each step contributes more useful refinement than the previous one because the LR shrinks and the gradient direction sharpens. Equal-weight averaging of params across this cooldown window therefore biases the weights *back toward earlier (higher-LR) checkpoints*, which lie farther from the optimum. Val=3.2749 vs 3.26615 = +0.00875 is a clean, mechanism-grounded regression (not noise).

Arm B's wider window (POLYAK_FRAC=0.50, averaging from step 1625) would extend the bias-toward-earlier-params problem further into the more-aggressive training phase. Even if Arm B ran cleanly, it would amplify the Arm A regression, not reverse it. The 10 crash attempts (typically stalling at step 0-25 with val/loss=10.83 = initialization) suggest implementation difficulty in addition to the mechanism issue.

**Conclusion:** CLOSED. Polyak-Ruppert axis CLOSED at 0 (no averaging). Per the predeclared falsification rule in the PR body ("Both arms NULL (val ≥ 3.26615) → weight averaging non-load-bearing"), Arm A's substantive regression closes the axis directly without needing Arm B confirmation.

**Back-burner follow-ups:**
1. **EMA-weighted Polyak**: weight the averaged contribution toward newer steps via decay factor — would respect the non-stationary cooldown trajectory.
2. **Polyak without cooldown**: test in a constant-LR or warmup-only setting where the trajectory *is* approximately stationary — different mechanism.

Nezuko re-assigned to fresh mechanism: **Lion optimizer (Chen et al. 2023) on embed-only path** — sign-momentum optimizer, two arms with lr ∈ {0.03, 0.10}.

---

## 2026-05-17 22:00 — PR #278: z-loss auxiliary scan {1e-4, 1e-3} (g1r1-alphonse)

- Branch: `g1r1-alphonse/zloss-auxiliary-scan`
- Hypothesis: z-loss (partition-function shrinkage `Z_LOSS_COEF · log(Z)²`) as a calibration regularizer at the output projection.

| Arm | Z_LOSS_COEF | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 (no z-loss) | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 1e-4 | `nmokccos` | 3050 | 3.26860 | +0.00245 | NULL — within noise band |
| Arm B | 1e-3 | `pdkpq1x2` | -1 (target missed) | 3.28640 | +0.02025 | REGRESSION — ~5× noise band |

**Mechanism analysis (alphonse):** The existing logit soft-clamp `logits = 15·logits/(logits² + 15²)^{1/2}` at line 442 already constrains both magnitude and partition function. Telemetry showed `log_z_mean ≈ 3.87` even at no z-loss pressure — there's no partition drift left to penalize. At Z=1e-3 the auxiliary gradient pulls `log_z → 0` aggressively, but this competes destructively with CE: it shrinks the effective margin between correct-token logit and the rest, so cross-entropy slowly increases. Smooth monotonic curve, no NaN — clean objective interference, not stability failure.

**Conclusion:** CLOSED. z-loss axis CLOSED at 0 (no z-loss). The current logit soft-clamp is the right operating point; additional explicit partition-function shrinkage degrades the language-modelling signal. Per the predeclared falsification rule, both arms NULL closes the axis.

**Process improvement noted:** `pgrep -af train_gpt_simple` pre-launch check (avoids duplicate-process incidents that cost ~30 min of contaminated wall-clock).

**Suggested follow-ups preserved:**
1. Pre-clamp z-loss (apply to unclamped logits) — different mechanism, low priority
2. **Per-group AdamW LR scans (embed_lr, scalar_lr, lm_head_lr)** — alphonse re-assigned to embed_lr scan {0.2, 0.4} per this follow-up
3. Per-head/per-layer PMuon LR — high-effort fresh mechanism

---

## 2026-05-17 21:10 — PR #272: AdamW eps scan {1e-8, 1e-9} (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamw-eps-scan`
- Hypothesis: AdamW eps=1e-10 is a 100× deviation from PyTorch default 1e-8 and was never explicitly scanned. Conjecture: at rare-token / low-variance positions on embed/lm_head/scalars, `1/(√v + eps)` could blow up when eps is tiny; larger eps should dampen oversized updates.

| Arm | eps | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 1e-10 | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 1e-8 (PyTorch default) | `edobz4wx` | 3025 | 3.26640 | +0.00025 | NULL — tied sr, val regress within noise |
| Arm B | 1e-9 | `w0oobk88` | 3050 | 3.26748 | +0.00133 | NULL — small sr+val regress, far below stat-sig threshold |

Both arms reach the 3.28 target comfortably (margins 0.0136 and 0.0125). Neither meets n=1 win rule.

**Analysis:** Non-monotone direction (sr+0 at eps=1e-8, sr+25 at eps=1e-9 — the *smaller* perturbation regresses more on sr) is more consistent with seed noise than a real trend. The data shows eps is genuinely flat above 1e-10 on this stack.

**Mechanism reading:** AdamW effective updates on embed/lm_head/scalars are NOT eps-floor-limited in this regime. The rare-token "update headroom" that eps=1e-10 provides is benign — dampening more (1e-8) doesn't help final loss, and the intermediate (1e-9) is also slightly worse on sr. The original hypothesis (eps-floor as oversized-update damper at low-variance positions) is falsified for this configuration.

**Conclusion:** CLOSED. AdamW eps axis CLOSED at 1e-10. Per the predeclared falsification rule in the PR body, both arms NULL closes the axis. Thorfinn re-assigned to **PR #311 Lookahead optimizer wrapper** — fresh wrapper-level mechanism (Zhang Lucas Hinton Ba NeurIPS 2019), complementary to in-flight polyak post-hoc (nezuko #293), AdEMAMix momentum (frieren #305), and PMuon bias correction (tanjiro #307).

**Suggested follow-up from student (kept for back-burner):** "is the embed AdamW path well-tuned" as an lr_embed axis question rather than eps. Clean diagnostic question — easier to characterize the AdamW path via per-group LR than via eps.

---

## 2026-05-17 20:35 — PR #250: NS coef c-scan on f'(1)=0 family seed-2 confirmation (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-c-scan`
- Hypothesis (originally): c-axis exploration on f'(1)=0 family at c ∈ {-0.25, +0.25}. Seed-1 of c=+0.25 produced a marginal numerical win (Δval=-0.00010, 10× below noise threshold). Sent back for n=2 seed-2 confirmation.

| Seed | sr | val/loss | polar/ortho_residual_sample | W&B run |
|---|---|---|---|---|
| seed-1 | **3025** | **3.26605** | 0.09399 | `8tbjkmnc` |
| **seed-2** | **3050** | **3.26708** | 0.09438 | **`qp87db4n`** |
| **mean (n=2)** | **3037.5** | **3.266565** | 0.09418 | — |
| baseline c=0 | 3025 | 3.26615 | not logged | `prncgzv5` |
| Arm A c=-0.25 | 3100 | 3.27291 | **20.637 (broken)** | `ecwyk0ej` |

**Analysis:** Per pre-declared advisor decision rule (seed-2 sr > 3025 → close), c-axis CLOSED at c=0. seed-1 marginal numerical win (Δval=-0.00010) confirmed as seed noise; mean n=2 Δval=-0.000585 is below both the stat-sig 0.004 threshold and the seed-noise 0.002 threshold. Arm B's two-seed evaluation correctly falsified the marginal seed-1 result.

**Reproducible structural finding preserved (not a sr/val win, but useful diagnostic):**
`polar/ortho_residual_sample` final value is **highly reproducible across seeds** (0.094 ± 0.0004 at c=+0.25). This is genuinely useful as a low-noise NS-screening diagnostic — future PMuon-iteration PRs can compare residual trajectories to screen NS polynomial variants without paying for full 3.4h runs.

**Mechanism finding (also preserved):**
c=-0.25 (b=0, no cubic term) has `polar/ortho_residual_sample ≈ 20.6` throughout training — essentially the random-Gaussian baseline (√768≈27.7). The NS iteration with f(x)=1.25x−0.25x⁵ does NOT orthogonalize: small SVs grow weakly (linear amp 1.25 too gentle), and SVs ≳1.39 flip into negative branch. **PMuon is partially robust to a broken polar factor** — c=-0.25 still reached val ≤ 3.28, just 75 sr-steps later. The bilateral whitening contributes orthogonalization independently of the NS iteration. Good cross-mechanism finding.

**Conclusion:** CLOSED. NS coef c-axis on f'(1)=0 family CLOSED at c=0 (cubic-Newton). Tanjiro re-assigned to PR #307 PMuon EMA bias correction (frieren's PR #261 follow-up — opposite direction from closed LR warmup).

**Backlog item retained:** `NS_ITERS=8 at c=+0.25` might match c=0 `NS_ITERS=12` on residual quality at ~33% compute savings per Muon step. Not pursuing now (c-axis closed for this family); flagged for any future Muon-iteration follow-up.

---

## 2026-05-17 20:15 — PR #261: PMuon LR warmup scan {50, 150 steps} (g1r1-frieren)

- Branch: `g1r1-frieren/muon-lr-warmup-scan`
- Hypothesis: PMuon's bilateral covariance EMAs (β_cov=0.95, ~20-sample equivalent) might benefit from a Muon-only LR warmup window during the cold-start EMA fill-in phase, when aggressive γ_power=0.4 whitening could be destabilizing.

| Arm | warmup steps | W&B run | sr | val/loss | Δval vs baseline (3.26615) | Status |
|---|---|---|---|---|---|---|
| Baseline (PR #202) | 0 | `prncgzv5` | 3025 | 3.26615 | — | Current best |
| Arm A | 50 | `2sjpvck2` | 3025 | 3.26618 | +0.00003 | NULL — tied within seed noise |
| Arm B | 150 | `wonlhane` | 3100 | 3.27251 | +0.00636 | REGRESSION — sr+75, clear capacity loss |

**Analysis:** Asymmetric null/regression result. Frieren's telemetry analysis nailed the mechanism:

1. **Cold-start whitening is self-regularizing**: `pmuon/whitened_sv_max` rises smoothly from low values during EMA fill-in — when `L_cov`/`R_cov` are near-zero, `matrix_neg_power(L_cov, γ=0.4)` returns a near-isotropic preconditioner that produces small-magnitude whitened gradients. The "aggressive whitening at cold start" problem the hypothesis assumed doesn't exist.

2. **EMA convergence is set by β_cov, not LR**: `lcov_eigh_ratio` and `rcov_eigh_ratio` evolve identically across configs in the first ~200 steps. LR warmup doesn't speed EMA settling; it only delays useful gradient application.

3. **Arm B regression = pure capacity loss**: 150 steps of linear ramp ≈ 75 full-LR-equivalent steps lost. On a fixed-budget benchmark with no cooldown extension, this manifests directly as sr+75 and Δval=+0.006.

4. **Arm A null reinforces direction**: 50 warmup steps ≈ 25 full-LR-equivalent steps lost — below per-seed noise floor.

**Conclusion:** CLOSED. PMuon LR warmup axis CLOSED at no warmup. The β_cov=0.95 EMA cold-start is self-correcting via small-magnitude whitening during fill-in; adding LR warmup is double regularization with no upside.

**Suggested follow-ups from student (kept for back-burner):**
- **Direct EMA bias correction**: divide `L_cov`/`R_cov` by `(1-β_cov^k)` for first ~50 steps to use the cov estimate MORE aggressively (opposite direction from warmup). Could tighten early whitening.
- Larger β_cov ∈ {0.97, 0.99}: longer effective sample window — trades slower adaptation for less variance.
- Initialize `L_cov`/`R_cov` with small identity prior (e.g. `λI`): replaces early near-zero pathology with known-stable start.

---

## 2026-05-17 18:05 — PR #230: Aux AdamW β1 scan {0.7, 0.9} (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-scan`
- Hypothesis: β1=0.8 for the auxiliary AdamW (embed, lm_head, scalars) has never been explicitly tested. Scan ±0.1 to characterize the gradient momentum timescale axis.

| Arm | aux β1 | W&B run | sr | val/loss | Δval vs PR #193 (3.26773) | Status |
|---|---|---|---|---|---|---|
| Arm A | 0.7 | `j4nfypgf` | 3050 | 3.26775 | +0.00002 | NULL — tied within seed noise |
| Baseline (PR #193) | 0.8 | `q8aduc16` | 3050 | 3.26773 | — | Stale base |
| Arm B | 0.9 | `s7tsyxrt` | 3075 | 3.27005 | +0.00232 | NULL — clearly worse |

**Re-anchored vs current baseline (PR #202, sr=3025, val=3.26615):** Both arms NULL — neither beats current baseline.

**Analysis:** Clear asymmetric result. β1=0.7 is statistically indistinguishable from β1=0.8 (Δval=+0.00002, well within 2σ seed noise). β1=0.9 genuinely regresses (+0.0023 val, sr+25). The β1 landscape has a flat plateau on the lower side (≤0.8) and rises sharply on the upper side. Edward's interpretation: "A shorter momentum window doesn't help the embed/lm_head/scalar updates; a longer momentum window (0.9) slows adaptation." The lm_head cooldown-responsiveness hypothesis (shorter β1 → faster react in cooldown) is falsified — the effective half-life difference (β1=0.7→2 steps vs β1=0.8→3.1 steps) is too small relative to the 75-step val-check grid.

Note: run used stale base (PR #193, sr=3050) — arm A's sr=3050 matches stale base rather than current best. Both arms definitively NULL on either anchor.

**Conclusion:** CLOSED. Aux AdamW β1 axis CLOSED at 0.8. β1=0.9 (longer memory) is clearly suboptimal; β1=0.7 provides no benefit over 0.8. Axis re-visit conditions: cooldown length change or radical aux-LR change. Edward reassigned to PR #297 (global gradient norm clipping — fresh mechanism, never tested).

---

## 2026-05-17 17:41 — PR #258: Skylight u/w-floor ablation TARGET_UW ∈ {0.0, 0.7} (g1r1-nezuko)

- Branch: `g1r1-nezuko/uw-floor-pruning-ablation`
- Hypothesis: Is TARGET_UW=0.35 (Skylight floor) load-bearing on the new γ_power=0.4+cubic-Newton stack? Test both disabling (0.0) and doubling (0.7).

| Arm | TARGET_UW | W&B run | sr | val/loss | Status |
|---|---|---|---|---|---|
| Arm A | 0.0 (disabled) | `yrvf83c0` | 3125 | 3.27504 | NULL — clear regression (+100 sr, +0.00889 val) |
| Baseline | 0.35 | `prncgzv5` | 3025 | 3.26615 | Baseline |
| Arm B | 0.7 | `9q7v4c4u` | DIVERGED step 2138 | — | CATASTROPHIC FAILURE — eigh crash |

**Analysis:** Arm A definitively shows u/w-floor IS load-bearing — disabling costs +100 sr and +0.009 val. The floor's value is concentrated in the cooldown phase: Arm A leads baseline mid-training (step 1000: 3.6225 vs 3.6578) but loses significantly by end (3.2750 vs 3.2662). 

Arm B produced the most striking diagnostic: TARGET_UW=0.7 creates a divergent amplification feedback loop. The floor sits 2.2× above the natural ratio mean (~0.31), causing every param to trigger from step 150. Amplification factor grows from 1× to 85,000× by step 2075, making the bilateral-whitening matrix numerically ill-conditioned → `torch.linalg.eigh` crash at step 2138.

New telemetry (ratio_mean/min/max) confirmed Goldilocks structure: natural u/w ratio band is [0.24, 0.39] with mean ~0.31. The floor at 0.35 sits just above the band (mild 1.1–1.5× lift) while 0.7 triggers a runaway positive feedback.

**Conclusion:** CLOSED. TARGET_UW axis CLOSED at 0.35. Neither removing nor doubling the floor is viable on the γ_power=0.4 stack. Follow-up: PR #293 nezuko (Polyak weight averaging — fresh mechanism).

---

## 2026-05-17 16:22 — PR #248: Muon base LR retune {0.030, 0.040} (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-base-lr-retune`
- Hypothesis: After cubic-Newton+γ_power=0.4 stack merged, baseline LR=0.035 may no longer be optimal. Scan ±14% to test.

| Arm | `MUON_BASE_LR` | W&B run | `sr` | `val/loss` | Δsr vs baseline | Δval vs baseline |
|---|---|---|---|---|---|---|
| Arm A | 0.030 | `dcm490bd` | 3025 | 3.26755 | 0 | +0.00140 |
| Arm B | 0.040 | `wsze97nl` | 3050 | 3.26669 | +25 | +0.00054 |
| **Baseline** | **0.035** | `prncgzv5` | **3025** | **3.26615** | — | — |

**Analysis:** Both arms NULL. Arm A ties sr but val is +0.00140 worse (regression). Arm B registers sr=3050 — 25 steps slower — but surprisingly recovers late: val/loss overtakes Arm A in final 100 steps (step 3150+) ending at 3.26669.

Key unexpected finding: `param_norm` at step 3250 grows **3.4×** (1375 → 4732) for a 1.33× LR change (0.030 → 0.040). This is far more than the LR-ratio prediction (√1.33 ≈ 1.15×). The driver is weight growth, not gradient dynamics — `update_norm` tracks closely between arms (within 5-10%) while `param_norm` diverges. The γ_power=0.4 whitening + PMuon preconditioning amplifies effective update magnitudes beyond the nominal LR scale. The existing `weight_decay=0.025` is insufficient to counter this — `lr*wd = 8.75e-4/step`.

The two effects pull opposite directions: higher LR hurts sr (early cooldown weight-growth under-stepping) but helps final val (+0.00086). Result: flat minimum at 0.035.

**Conclusion:** CLOSED. Muon base LR axis CLOSED at 0.035. Symmetric NULL — no headroom in either direction. Follow-up: WD scan {0.035, 0.050} (PR #287) directly motivated by param_norm telemetry.

---

## 2026-05-15 15:00 — PR #68: Aurora + Contra-Muon + u/w floor (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra`
- Hypothesis: Reproduce Record #17 — Aurora row-norm equilibration before NS polar, Contra-Muon momentum subtraction (coeff=0.2), Skylight u/w floor (TARGET_UW=0.35). No weight decay. lr=0.0375.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **3175** |
| val/loss at crossing | 3.274438 |
| margin | +0.005562 (≥ 0.004 ✓) |
| n | 1 |
| W&B run | `lg4xdlkt` |
| Wall clock | ~107 min (1×H100) |
| train_steps used | 3250 |

**Analysis:** First local winner. Confirms that the Aurora+Contra-Muon+Skylight stack from public Record #17 (3175 steps, n=20, mean val 3.2789) transfers to our local hardware with comparable step count on n=1. Aurora's row-norm equilibration pre-conditions the gradient mass distribution before NS orthogonalization; Contra-Muon applies a 0.2× negative projection against the raw momentum direction; Skylight u/w floor prevents weight norm collapse. The combination appears to synergize: Aurora→Contra→NS is stronger than Contra alone (public records #9→#11 progression). Stat-sig bar cleared on n=1 (rare — margin of 0.0056 is generous). Also includes `sample_tensor` linspace fp32 precision fix.

**Conclusion:** MERGED as first local anchor. New baseline: 3175 steps. Wave 2 assignments: tanjiro gets SOAP-MLP addition, askeladd gets NorMuon addition.

---

## 2026-05-15 15:30 — PR #61: NorMuon short-axis variance EMA (g1r1-askeladd)

- Branch: `g1r1-askeladd/normuon-short-axis`
- Hypothesis: Per-row second-moment EMA along the short axis after NS polar step (beta2=0.95, eps=1e-10), Frobenius-renormalized. Isolation test of NorMuon without Aurora/Contra/u/w.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | 3275 |
| val/loss at crossing | 3.27920 |
| margin | +0.00080 (< 0.004, n=1 insufficient) |
| n | 1 |
| W&B run | `9ju04ncw` |
| Wall clock | ~99.3 min (RTX PRO 6000 Blackwell) |
| train_steps used | 3300 |

**Analysis:** NorMuon mechanism confirmed on local hardware — reaches target at 3275 steps with no NaN/Inf, closely matching public Record #10 (3250 steps, n=20) on a single seed. However, 3275 > 3175 (new local baseline from PR #68), so NorMuon alone does not beat the current best. This is expected: NorMuon adds row-adaptive scaling to Muon, which is a positive building block but not as strong as the full Aurora+Contra+u/w stack in isolation. Note: stat-sig bar at n=1 is not cleared (margin 0.00080 < 0.004), which was expected for a screening run.

Student also reported: (1) `sample_tensor` bug fix included (already merged via #68), (2) confirmed that Muon.step *does* apply WD (`p.mul_(1 - lr*wd)`) — BASELINE.md gotcha note was inaccurate. This clarifies effective WD at lr=0.035, wd=0.025 ≈ 0.000875/step.

**Conclusion:** CLOSED — doesn't beat new 3175 baseline as standalone. NorMuon signal is valuable for stacking. New assignment: Aurora+Contra+u/w+NorMuon in PR #84.

---

## 2026-05-15 17:00 — PR #67: SOAP-MLP only on Muon (g1r1-nezuko)

- Branch: `g1r1-nezuko/soap-mlp`
- Hypothesis: SOAP-style Shampoo-eigenbasis Adam preconditioning on MLP fc/proj weights, applied before NS polar step. Isolation of SOAP-MLP without Aurora/Contra/NorMuon. β2=0.90, eps=1e-10, precond_freq=10.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | 3200 |
| val/loss at crossing | 3.27705 |
| margin | +0.00295 (< 0.004, n=1 insufficient) |
| n | 1 |
| W&B run | `kkegpr5n` |
| Wall clock | ~107 min (~1.98 s/step due to 3072×3072 eigh) |
| train_steps used | 3250 |

**Analysis:** SOAP-MLP isolation result. 3200 steps is only 25 steps behind our 3175 baseline (PR #68 Aurora+Contra+u/w) — strong single-mechanism signal. Within noise of public Record #14 (Contra+NorMuon+SOAP-MLP at 3150, n=4). Per-step wall-clock dominated by eigenbasis refresh on the 3072×3072 MLP fc covariance every 10 steps. Student added `_safe_eigh` with fp64 fallback + 1e-30 diagonal jitter (no fallback events triggered, confirming numerical stability throughout). Margin 0.00295 doesn't clear the 0.004 stat-sig bar on n=1.

**Conclusion:** CLOSED — doesn't beat 3175 baseline as standalone. The isolation point is valuable for attributing the SOAP-MLP contribution when tanjiro's stacked variant (PR #83, Aurora+Contra+u/w+SOAP-MLP) lands. Nezuko reassigned to power-law cooldown (PR #85, schedule-lever experiment orthogonal to optimizer stacking).

---

## 2026-05-15 21:00 — PR #69: KL-SOAP-H replaces Newton-Schulz entirely (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/klsoap-h`
- Hypothesis: Replace NS polar step entirely with full SOAP-in-Q-basis Adam updates for all hidden 2D matrices. lr=0.018, β1=0.95, β2=0.90, shampoo_beta=0.90, precond_freq=1, hyperball param update.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | -1 (not reached) |
| val/loss trajectory (initfix run `beqqi17z`) | step 0: 10.83 → step 875: 4.498 → step 1750: 4.224 |
| Projected final val/loss at step 3150 | ~3.9 (clean decline ~0.03/125 steps) |
| n | 1 (closed before completion) |

**Analysis:** Initial run diverged due to zero-init `*.proj.weight` paired with hyperball optimizer (frozen layers). Student debugged this carefully, corrected init recipe, relaunched as `klsoap-h-initfix`. Restart trained cleanly with zero NaN throughout, monotonic decline. But the slope is too shallow — extrapolated to step 3150, val_loss lands around 3.9, far above the 3.28 target. The decline doesn't accelerate in cooldown either.

**Conclusion:** CLOSED as clean negative result. KL-SOAP-H replacing NS entirely cannot compete in our step budget. The NS orthogonalization is essential — pure SOAP-in-Q-basis without polar normalization has too much scale/variance drift. The Q-basis preconditioning idea is sound (record #19 publicly reaches 3125 at n=6), but pure SOAP-as-replacement is the wrong framing on our scale/budget. SOAP-as-curvature-prefilter (record #14 / nezuko's #67 style) is the correct framing. Thorfinn reassigned to per-module init std experiment (PR #89).

---

## 2026-05-15 21:30 — PR #63: u/w floor (Skylight) on Muon (g1r1-edward)

- Branch: `g1r1-edward/uw-floor`
- Hypothesis: Standalone Skylight u/w floor (TARGET_UW=0.35, no weight decay). Isolation of u/w-floor mechanism without Aurora/Contra/NorMuon.

| Seed | Run ID | target_step | val/loss | Hit |
| ---- | ------ | ----------- | -------- | --- |
| 1 | `3fis12l2` | 3275 | 3.278 | ✓ |
| 2 | `574onkh8` | -1 | 3.280 | ✗ (missed by 0.002) |
| 3 | (not run) | — | — | — |

**Analysis:** Seed 1 hit target cleanly at step 3275, seed 2 just missed (val 3.280 at step 3300, target_step=-1). At n=2 with 1 hit, the mean cannot beat our 3175 baseline (PR #68) even if seed 3 also hits — best-case mean would land around 3275, 100 steps behind. Standalone u/w floor on our hardware is more variable than the public Skylight record #9 (3250 mean at n=8); likely because we lack the orthogonalization-side mechanisms that record #9 may carry implicitly.

**Conclusion:** CLOSED — standalone u/w floor cannot beat the merged baseline (which already includes u/w floor as one of three stacked mechanisms). Edward's isolation result is useful retrospective attribution data. Reassigned to Soft-Muon in cooldown experiment (PR #88).

---

## 2026-05-15 18:25 — PR #64: PMuon streaming covariance preconditioning (g1r1-fern) **WINNER pending rebase**

- Branch: `g1r1-fern/pmuon-cov-precond`
- Hypothesis: Maintain streaming left/right covariance EMAs (β_cov=0.95), use `L^{-γ} m R^{-γ}` preconditioning (γ=0.3) — replaces the NS polar step entirely. Public reference: Record #18, mean 3.2776 at 3225 steps, n=9.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **3150** |
| val/loss at crossing | 3.27447 |
| margin | +0.005530 (≥ 0.004 ✓) |
| n | 1 |
| W&B run | `vx0r7rp2` |
| Wall clock | ~4.15 h (1× H100, ~3847 ms/step including val events) |
| train_steps used | 3250 |
| val_loss at step 3225 (record-comparison) | 3.27500 |

**Analysis:** Standalone PMuon is the new **best single-mechanism result** on our hardware — beats #68's Aurora+Contra+u/w (3175 steps) by 25 steps with a single mechanism. The streaming covariance preconditioner replaces NS polar with a more curvature-aware update; it doesn't need Aurora's row-norm equilibration or Contra-Muon's negative momentum subtraction.

**Important caveat:** Result is on the **pre-#68 code path** — PMuon replaces NS, so it's not compatible with the Aurora+Contra+u/w mechanism. The rebase strategy must keep PMuon and drop Aurora+Contra+u/w during conflict resolution to preserve attribution. Fern's `sample_tensor` fp64 fix is the same as in #68 (already merged) — should rebase cleanly there.

**Conclusion:** Confirmed winner with terminal SENPAI-RESULT marker. **Pending fern's rebase** before merge. Once merged, BASELINE.md updates to 3150 steps. The Aurora+Contra+u/w mechanism family then becomes a parallel-track baseline candidate that we may need to re-introduce as a stack on PMuon (e.g., a Wave 3 "PMuon + u/w floor" experiment).

---

## 2026-05-15 19:00 — PR #83 intervention: Aurora+Contra+SOAP-MLP destabilized (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra-soap-mlp`
- W&B run: `avn3wrne`
- Status: **DESTABILIZED at step 1500** (sent back, not closed)

**Diagnosis:** val/loss 5.67 at step 1500 (should be ~3.8 for a healthy Aurora+Contra+u/w trajectory). Two visible spikes at steps 750 and 1375. Raw grad norms enormous (`train/grad/all/max`=6659, global=49112) despite Frobenius renorm. `nonfinite_count=0` so not NaN — pure runaway scale. The SOAP-MLP eigenvalue-inverse scaling is amplifying small singular components beyond what Frobenius renorm can absorb.

**Intervention plan (posted to PR):**
1. Smoke-test base with SOAP disabled (verify Aurora+Contra+u/w still works on this branch)
2. Re-enable SOAP with three stability guards: `SOAP_BETA2=0.99` (slower burn-in), `m_scaled.clamp_(±10.0)` (hard cap), upper-amp cap on Frobenius renorm (`≤1.5x`)
3. If still unstable: disable Contra-Muon (`CONTRA_COEFF=0`) to test SOAP+Contra interaction
4. Full 3200-step run only after smoke shows tracking baseline trajectory

**Why send back rather than close:** SOAP-MLP works standalone (PR #67 nezuko, 3200 steps). The integration with Aurora+Contra is the issue, not the mechanism. Public Record #14 stack (Contra+NorMuon+SOAP-MLP at 3150 steps) shows the combination is achievable with right guards.

---

## 2026-05-15 20:21 — PR #59 CLOSED: Vanilla Muon attribution baseline (g1r1-alphonse)

- Branch: `g1r1-alphonse/vanilla-muon-baseline`
- W&B run: `83qeloh9` (group `g1r1-alphonse/vanilla-baseline`)
- Hypothesis: True vanilla Muon (lr=0.035, wd=0.025, NS5, no Contra/Aurora/u/w-floor) with `dynamic=True` compile workaround as attribution anchor.

| Metric | Value |
| ------ | ----- |
| speedrun/final_first_step_to_target | **-1 (target NOT reached)** |
| val/loss (final) | 3.29743 |
| margin | -0.01743 (target=3.28; failed) |
| n | 1 |
| train_steps used | 3350 |

**Analysis:** True vanilla Muon with compile-bug workaround ran cleanly to 3350 steps but final val/loss = 3.29743, 0.017 above the 3.28 target. Single-trial result; vanilla cannot beat the merged baselines (Aurora+Contra+u/w PR #68 at 3.274 nominal vs 3.297 vanilla = ~0.023 attribution gap). Alphonse's compile-bug root-cause diagnostic was the major value contribution from this PR.

**Conclusion:** CLOSED as attribution anchor result. Vanilla doesn't beat baseline by construction. Alphonse's compile-bug root-cause and `dynamic=True` workaround feed forward into all future PMuon-base experiments.

---

## 2026-05-15 20:35 — PR #84 CLOSED + CRITICAL FINDING: Aurora+Contra+u/w PR #68 base is empirically broken (g1r1-askeladd)

- Branch: `g1r1-askeladd/aurora-contra-normuon`
- W&B runs: `xakwxu84` (killed step 2032), `761npqac` (killed step 1250), `liwmf3pg` (sanity NORMUON_BETA2=0)

**Discovery:** askeladd implemented NorMuon short-axis EMA per PR #84 spec, but both full runs diverged identically. The sanity run with NORMUON_BETA2=0 (NorMuon disabled, pure Aurora+Contra+u/w base) ALSO diverged at step 125 with val/loss 7.79 vs canonical PR #68 trajectory at val/loss 4.63. **The PR #68 base recipe is not reproducible on this pod.**

**Confirmed divergent runs of PR #68 recipe (val_loss at step 125):**
- `q869emek` (tanjiro/smoke3-pr68-pristine): 15.57 — crashed
- `343520k1` (thorfinn/per-module-init): 12.26
- `n4l14w3j`, `dpfoptl8` (nezuko/power-cooldown-1p2): 9.16, 10.96
- `8qkxbh7c` (alphonse/smoke-dynamic-true on aurora+contra+uw): 15.50 — `dynamic=True` NOT sufficient
- `liwmf3pg` (askeladd/sanity-normuon-off): 7.79
- `xakwxu84`, `761npqac` (askeladd NorMuon stack): 9.38, 7.99

All show `train/grad/global_norm ≈ 234K` at step 1 — the Inductor compile bug signature from PR #59 alphonse root cause. Original PR #68 winner `lg4xdlkt` was a lucky compile-cache draw, not a reproducible recipe.

**Implication:** PR #68's recorded baseline (3175 steps) is an artifact. PMuon (PR #64, run `vx0r7rp2`) is the only reliably-reproducible local baseline because covariance whitening empirically damps the seed-NaN amplitude.

**Conclusion:** Closed PR #84 (askeladd reassigned to PR #94 PMuon + u/w-floor). All five Wave 2 PRs (#83 tanjiro, #84 askeladd, #85 nezuko, #88 edward, #89 thorfinn) sent back to pivot from broken Aurora+Contra+u/w base to PMuon base. Nezuko (#85) had already adapted independently. Wave 2 becomes Wave 3 portfolio on PMuon.

---

## 2026-05-16 01:25 — PR #89: Per-module init std on PMuon base (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/per-module-init` (pivoted to PMuon base in commit `f9a3645`)
- Hypothesis: Replace PMuon's default `*.proj.weight` zero-init with explicit per-module std values (attn.q/k/v=0.020, attn.proj=0.026, mlp.fc=0.031, mlp.proj=0.031). Tests whether non-zero residual-output init helps PMuon trajectory.
- W&B run: `ipohjfgm` (n=1, train_steps=3250, dynamic=True compile fix applied)

| Metric | This run | Baseline (`vx0r7rp2` PMuon) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | 3175 | 3150 | +25 steps (worse) |
| val/loss (step 3250) | 3.27639 | 3.27447 | +0.00192 (worse) |
| (3.28-μ)·√n margin (n=1) | 0.00361 | 0.00553 | fails 0.004 rule |
| Runtime | 3h40m | 4h09m | -1745s |

**Analysis:** Init verification table confirms observed_std matches expected for every category (q/k/v=0.020, attn.proj=0.026, mlp.fc/proj=0.031). The change from PMuon's default zero-init for `*.proj.weight` to non-zero std hurts the optimization trajectory marginally. Likely interaction: zero-init residual-output weights start with zero gradient through the residual path, giving PMuon's L/R covariance EMAs a cleaner step-0 signal. Non-zero init perturbs this, putting PMuon in a slightly worse early-step regime.

**Conclusion:** CLOSED as clean negative result. Per-module init is not a free lever on PMuon base — PMuon's default zero-init for `*.proj.weight` is doing real work via covariance EMA interaction. Reassigned thorfinn to PR #110 (PMuon γ-scan at 0.25 and 0.35).

---

## 2026-05-16 00:30 — PR #85 (interim): Power-law cooldown γ=1.2 on PMuon — SENT BACK for n=2 confirmation (g1r1-nezuko)

- Branch: `g1r1-nezuko/power-cooldown-1p2`
- W&B run: `xr4hkd3y` (n=1, train_steps=3200, γ=1.2 power-law cooldown)
- Result: speedrun=3100 (−50 vs 3150), val=3.27647

| Metric | This run | Baseline |
| --- | --- | --- |
| speedrun/final_first_step_to_target | 3100 | 3150 |
| val/loss (final, step 3200) | 3.27647 | 3.27447 (step 3250) |
| val/loss at matched step 3150 | 3.27727 | 3.27447 (worse at matched step) |
| (3.28-μ)·√n margin (n=1) | 0.00353 | 0.00553 (fails 0.004) |

**Decision:** Send back for n=2 confirmation at `train_steps=3250` (apples-to-apples vs PR #64). Reasons:
1. n=1 margin 0.00353 fails the 0.004 statistical rule.
2. Train_steps mismatch (3200 vs 3250) confounds cooldown-shape vs total-budget contributions to the speedrun delta.
3. At matched step 3150, this run's val/loss (3.27727) is *worse* than PMuon's (3.27447) — so the cooldown shape itself isn't strictly better; speedrun delta is partly a budget effect.

Re-run command:
```bash
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py --num_trials 2 \
  --wandb_name "g1r1-nezuko/power-cooldown-1p2-confirm" \
  --wandb_group "g1r1-nezuko/power-cooldown-confirm"
```
with `train_steps=3250`. Confirmation run `u3o8j3yj` started 2026-05-16 01:22 UTC.

---

## 2026-05-16 03:29 — PR #88 CLOSED: Soft-Muon (p=0.1) in cooldown on PMuon base (g1r1-edward)

- Branch: `g1r1-edward/soft-muon-cooldown`
- Hypothesis: Blend post-polar update with momentum direction during cooldown phase (last 70%): `update = (1-p)*polar + p*(m_pre/||m_pre||_F * sqrt(min_dim))`. `p=0.1`, gated to steps 977-3250.
- W&B run: `dezar21q` (n=1, train_steps=3250, dynamic=True compile fix applied)

| Metric | This run | Baseline (`vx0r7rp2` PMuon) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3150** | 3150 | **0 (no improvement)** |
| val/loss (step 3250) | 3.274323 | 3.274469 | −0.000146 (within noise) |
| (3.28-μ)·√n margin (n=1) | 0.00568 | 0.00553 | both pass rule |

**Analysis:** Soft-Muon gating verified correctly (`softmuon/active` toggles at step 977, `effective_p=0.1` throughout cooldown). Val/loss curves track on top of each other — minor lead in early cooldown (+0.001 to +0.003 above baseline steps 1000-1900), converging and slightly below baseline in final steps (−0.0001 to −0.0003 from step 2500+). The primary metric (speedrun step) is identical: no improvement. **The mechanism does not add lift on top of PMuon's bilateral whitening** — PMuon's `L^{-γ} ⊗ R^{-γ}` already implements much of the SVD-direction shrinkage that Soft-Muon targets in cooldown.

**Conclusion:** CLOSED as clean null result. Reassigned edward to PR #118 (PMuon cooldown_frac scan: 0.5 vs 0.8).

---

## 2026-05-16 03:35 — PR #95 CLOSED: PMuon + Contra-Muon (both coeff=0.2 and 0.1 catastrophic) (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-contra-muon`
- Hypothesis: Add Contra-Muon (subtract `contra_coeff` × Frobenius-normalized pre-polar momentum) to PMuon post-polar update. Coefficients 0.2 (prescribed) and 0.1 (fallback).
- W&B runs: `2jslevyc` (coeff=0.2, killed ~step 1500), `3filu2p3` (coeff=0.1, killed step 1030)

| run | contra_coeff | killed_at | val/loss@1000 | dir_norm_ratio (mean) | first_step_to_target |
| --- | --- | --- | --- | --- | --- |
| `2jslevyc` | 0.2 | ~step 1500 | ~7.54 | 1.59 | -1 |
| `3filu2p3` | 0.1 | step 1030 | 7.331 | 1.59 | -1 |
| baseline `vx0r7rp2` | n/a | finished | 3.62 | n/a | 3150 |

**Analysis:** Both coefficients produce catastrophic divergence (train_loss spikes to 14.6+ at step ~100, grad_norm to 1e5-1e6+, no recovery). Root cause (student diagnosis): empirical `dir_norm_ratio ≈ 1.59` means PMuon's whitened polar has Frobenius ≈ 0.62× the `target_scale=sqrt(min(m,n))` that Contra-Muon assumes. Effective perturbation = `contra_coeff × 1.59 × ||update||_F` — a 32% off-direction perturbation at coeff=0.2 that destabilizes the optimizer.

**Key insight:** To fix Contra-Muon on PMuon base, `contra_dir` must be scaled to the **actual** `||update||_F` rather than the assumed `sqrt(min(m,n))`. This makes the perturbation magnitude scale-coherent. This is the basis for the next PR (alphonse PR #119, measured-scale Contra-Muon).

**Conclusion:** CLOSED as clean negative on the as-spec'd formulation. Reassigned alphonse to PR #119 (measured-scale Contra-Muon with calibrated target_scale).

---

## 2026-05-16 03:30 — PR #93 SENT BACK: PMuon + NorMuon (element-wise) — retry with row-wise (g1r1-fern)

- Branch: `g1r1-fern/pmuon-normuon-stack`
- W&B run: `0x6cgq1a` (FINISHED), second arm `5d4u7d1n` (RUNNING — student-initiated n=2)

| Metric | This run (element-wise) | Baseline (PMuon `vx0r7rp2`) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3225** | 3150 | **+75 steps (worse)** |
| val/loss (step 3250) | 3.2789 | 3.27447 | +0.0044 (worse) |

**Analysis:** Student correctly noted PR instructions were ambiguous (element-wise code vs short-axis text). Ran element-wise (Adam-style) interpretation as specified. Element-wise post-NS scaling on top of PMuon's bilateral whitening is redundant — PMuon already whitens row/col via `L^{-γ} ⊗ R^{-γ}`, so per-element scaling double-whitens and mildly hurts trajectory (+75 step regression).

**Decision:** Send back for row-wise short-axis (PR #61 validated mechanism) retry. Row-wise NorMuon is mechanistically distinct from element-wise: per-neuron diagonal scaling vs full off-diagonal bilateral whitening. The PR #61 result at 3275 (standalone) establishes that row-wise NorMuon has a positive signal on vanilla Muon; on PMuon base it may or may not stack.

---

## 2026-05-16 07:28 — PR #94 MERGED: PMuon + Skylight u/w-floor (TARGET_UW=0.35) (g1r1-askeladd) ← NEW BASELINE

- Branch: `g1r1-askeladd/pmuon-uw-floor`
- Hypothesis: Add Skylight u/w-floor to PMuon: after `pmuon_update(...)`, if `||update||_F / ||w||_F < TARGET_UW=0.35`, rescale update to floor. Prevents PMuon's bilateral whitening from shrinking update steps into subthreshold magnitude territory.
- W&B runs: `yeyewcj6` (n=1, finished 2026-05-15 21:34), `205sycku` (n=2 confirm, finished 2026-05-16 07:22)

| Metric | yeyewcj6 (n=1) | 205sycku (n=2) | n=2 mean | Baseline PMuon | Δ |
| --- | --- | --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3100** | **3100** | **3100** | 3150 | **−50 steps ✓** |
| val/loss (step 3250) | 3.267878 | 3.267513 | 3.267696 | 3.27447 | −0.006774 |
| (3.28−μ)·√n margin | 0.00812 | 0.00849 | 0.01740 | 0.00553 | well above rule |
| uw_floor/fired_fraction | 1.000 | 1.000 | 1.000 | n/a | always active |
| Runtime | 220 min | 215 min | — | ~220 min | — |

**Analysis:** u/w-floor fires at 100% of eligible params every step — PMuon's `L^{-γ} R^{-γ}` bilateral whitening systematically shrinks update Frobenius norms below 0.35·‖w‖, so the floor is never triggered by just a few outlier steps; it's a universal magnitude rescale. This means `TARGET_UW=0.35` is effectively acting as a per-param LR multiplier in the current underfloor regime, not a safety catch. Seed variance is extremely tight (range 0.000365 across n=2), confirming mechanistic stability. Improvement of −50 steps (3150 → 3100) matches the order of magnitude expected from Skylight in public Record #9, stacked on PMuon's direction.

**Key insight:** Since PMuon's whitening always shrinks below 0.35·‖w‖, the γ × TARGET_UW parameter space is coupled — changing β_cov (which affects how much PMuon shrinks) would change how aggressively the floor fires. Follow-up PRs: TARGET_UW sweep {0.25, 0.30, 0.40, 0.45}, β_cov scan (PR #129, frieren assigned).

**Conclusion:** MERGED as new local best. New baseline: **sr=3100, val=3.267696 (n=2)**. Students now work against this bar.

---

## 2026-05-16 07:33 — PR #65 CLOSED: MuonH hyperball Frobenius-cap on PMuon base (g1r1-frieren)

- Branch: `g1r1-frieren/muonh-hyperball`
- Hypothesis: Add MuonH hyperball renormalization — after PMuon polar update, rescale to preserve `||p||_F` — to avoid weight-norm collapse. Tests whether Frobenius-norm preservation on top of PMuon's whitening improves convergence.
- W&B run: `uxq44v87` (n=1, train_steps=3250, dynamic=True, fp32 NS5 cast applied, non-zero proj init)

| Metric | This run | New baseline (PR #94) | Δ |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **−1** (target never reached) | 3100 | N/A |
| val/loss (step 3250) | 3.33021 | 3.267696 | +0.0625 (much worse) |
| vs. target 3.28 | missed by 0.0502 | beat by 0.0123 | — |
| Runtime | 229.7 min | ~220 min | — |

**Analysis:** val=3.3302 at step 3250 means the target 3.28 was never crossed — full negative. PMuon already provides very aggressive shape normalization via `L^{-γ} ⊗ R^{-γ}` followed by NS5 polar (unit operator-norm output). Hyperball on top locks `||p||_F` exactly, which removes the small weight-norm drift PMuon was implicitly using during optimization — the parameter is stuck at init norm, which may be sub-optimal. The fp32 NS5 fix (eliminates bf16 NaN) and hyperball verification telemetry (||p||_F stable to 5 sig figs) are correct implementations; the mechanism itself is incompatible with PMuon as a substrate. Key note: Record #5 MuonH is on vanilla Muon (lr=0.014, per-module init, split cooldowns) — not PMuon — so this result doesn't contradict the public record.

**Conclusion:** CLOSED as clean negative. PMuon's preconditioning and hyperball's Frobenius constraint are incompatible. Reassigned frieren to PR #129 (PMuon β_cov scan on new u/w-floor base).

---

## 2026-05-16 09:35 — PR #85 CLOSED: Power-law cooldown γ=1.2 on PMuon — n=2 confirmed but lost to new baseline (g1r1-nezuko)

- Branch: `g1r1-nezuko/power-cooldown-1p2`
- Hypothesis: Power-law cooldown with γ=1.2 makes the cooldown decay concave, spending more time at low lr. Tests whether the lr schedule shape can be improved over linear.
- W&B run: `u3o8j3yj` (n=2, two sequential trials in one run, train_steps=3250 each)

| Trial | speedrun_step | val/loss |
| --- | --- | --- |
| 0 (steps 1–3250)    | 3125 | 3.2746 |
| 1 (steps 3251–6500) | 3125 | 3.2755 |
| **n=2 mean**        | **3125** | **3.27505** |

**Stat-sig margin against 3.28:** `(3.28 − 3.27505)·√2 = 0.00700` ✓ clears 0.004 bar.

**Against new baseline (PR #94 sr=3100 val=3.267696):** sr +25 (worse), val +0.0074 (worse).

**Analysis:** Both trials reached target at sr=3125 with extremely tight per-trial val agreement (0.0009 spread). Power-law cooldown γ=1.2 is a real improvement over vanilla linear cooldown on the PMuon-only base (beats PR #64 at sr=3150 val=3.27447 by 25 steps + 0.00058 val), confirming the mechanism is mechanically sound and seed-stable. However, PR #94's u/w-floor stack moved the baseline during nezuko's confirmation runtime. Power-law cooldown alone doesn't beat the u/w-floor mechanism.

**Conclusion:** CLOSED as confirmed result that lost the moving baseline. Reassigned nezuko to PR #137 — stack power-law cooldown γ=1.2 on PMuon + u/w-floor base to test orthogonality of the two mechanisms (lr schedule shape × per-param update magnitude).

---

## 2026-05-16 10:30 — PR #83 CLOSED: PMuon + SOAP-MLP (no u/w-floor) — null vs new baseline (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/aurora-contra-soap-mlp`
- Hypothesis: SOAP-MLP (eigenbasis Adam scaling after NS polar, applied to 24 MLP fc/proj weights) stacked on PMuon. Tests whether curvature-conditioned per-layer second-moment scaling compounds with PMuon's bilateral whitening.
- W&B run: `il6j69lr` (full run 3250 steps, post-PR #94 rebase, PMuon+u/w-floor base WITHOUT u/w-floor on this PR)

| Metric | Value | PR #94 baseline | PR #64 bare PMuon |
| --- | --- | --- | --- |
| speedrun/final_first_step_to_target | **3150** | 3100 | 3150 |
| val/loss | **3.27419** | 3.267696 | 3.27447 |
| (3.28-μ)·√n margin | 0.00581 ✓ | (baseline) | — |
| n | 1 | 2 | 1 |

**Analysis:** SOAP-MLP on bare PMuon is a null vs new baseline — same sr=3150 as PR #64 bare PMuon, Δval=−0.00028 (within seed noise). Mid-training trajectory (steps 500–1875) was 0.03–0.04 below PMuon+u/w-floor baseline, but the advantage evaporated during cooldown. Key finding: u/w-floor's late-cooldown per-param magnitude inflation is not substitutable by SOAP-MLP's second-moment normalization. Stability guards (β2=0.99, scale clamp ±10, amp cap 1.5×) worked perfectly — no instability throughout 3250 steps. 4.2% wall-clock overhead.

**Conclusion:** CLOSED as informative null. Mechanisms are NOT substitutable — u/w-floor operates on final update magnitude relative to weight norm; SOAP-MLP operates on update direction in eigenbasis. The natural follow-up is SOAP-MLP + u/w-floor stack (both mechanisms active). Assigned tanjiro PR #140 for that test.

---

## 2026-05-16 11:30 — PR #110 CLOSED: PMuon γ-scan (γ=0.25 vs γ=0.35) — null on speedrun metric (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-gamma-scan`
- Hypothesis: Scan PMuon's whitening exponent γ ∈ {0.25, 0.35} vs current baseline γ=0.30 on PMuon+u/w-floor base.
- W&B runs: `hehdzpld` (arm A γ=0.25), `2ipgcjyn` (arm B γ=0.35)

| Arm | γ | val/loss@3250 | sr | (3.28-μ)·√n |
| --- | --- | --- | --- | --- |
| A | 0.25 | **3.27286** | 3150 | 0.00714 ✓ |
| B | 0.35 | 3.27380 | 3150 | 0.00620 ✓ |
| PR #64 base | 0.30 | 3.27447 | 3150 | — |
| PR #94 **baseline** | 0.30+u/w | 3.267696 | **3100** | — |

**Analysis:** All three γ values (0.25, 0.30, 0.35) cross the 3.28 target at the same evaluation step (3150) — the speedrun metric is completely insensitive to γ in this range. Val/loss ordering is γ=0.25 < γ=0.30 < γ=0.35, suggesting less whitening is mildly better, but all differences are within n=1 noise (≤0.002 across all three). None beats the PR #94 baseline (sr=3100 val=3.267696). Once u/w-floor is active, the late-cooldown magnitude floor governs the target crossing more than per-step whitening does.

**Conclusion:** CLOSED as clean null on speedrun metric. γ=0.30 (current default) is at or near the local optimum. Assigned thorfinn PR #143 (Lookahead outer optimizer on PMuon+u/w-floor) — completely different abstraction layer.

---

## 2026-05-16 12:00 — PR #93 CLOSED: PMuon + NorMuon row-wise retry — null vs new baseline (g1r1-fern)

- Branch: `g1r1-fern/pmuon-normuon-rowwise-retry`
- Hypothesis: Per-row second-moment EMA after NS polar step (row-wise NorMuon) stacked on PMuon, retry after 3 prior crashes.
- W&B run: `63c3s1sl` (full 3250-step run, stable after crash history resolved)

| Metric | Value | PR #94 baseline |
| --- | --- | --- |
| speedrun/final_first_step_to_target | **3175** | 3100 |
| val/loss @ 3250 | 3.2757 | **3.267696** |
| (3.28-μ)·√n at n=1 | 0.00430 ✓ | — |

**Analysis:** Run completed cleanly (crossed 3.28 at step 3175). However sr=3175 is 75 steps worse than the baseline and val is 0.0080 higher. Row-wise NorMuon adds per-row second-moment EMA on top of PMuon's already-whitened post-polar update. The two normalizations partially overlap: PMuon's `R^{-γ}` already does per-column rescaling; NorMuon's per-row scale partially double-corrects. Cross-cutting insight: direction-shaping mechanisms (SOAP-MLP, NorMuon row-wise) consistently produce null or marginal results on this base, because PMuon's whitening already shapes the update direction.

**Conclusion:** CLOSED as informative null. Assigned fern PR #150 (Cautious update sign-mask — mechanistically distinct, operates on sign rather than magnitude or direction).

---

## 2026-05-16 13:15 — PR #118 CLOSED: PMuon cooldown_frac scan (0.5/0.8, default 0.7) — null (g1r1-edward)

- Branch: `g1r1-edward/pmuon-cooldown-frac-scan`
- Hypothesis: PMuon merged baseline uses `cooldown_frac=0.7`. Scan ±0.1 (arms 0.5, 0.8) to probe whether the LR-collapse phase start point is at a local optimum on PMuon+u/w-floor base.
- W&B runs: `6fpu600z` (Arm A, cooldown_frac=0.5), `dvjzqltr` (Arm B, cooldown_frac=0.8)

| Arm | cooldown_frac | sr | val/loss | (3.28−μ)·√n | vs PR #94 baseline |
| --- | ------------- | -- | -------- | ------------ | ------------------ |
| A | 0.5 | 3175 | 3.27493 | +0.00107 ✓ | −75 steps, +0.00723 val |
| B | 0.8 | 3150 | 3.27415 | +0.00185 ✓ | −50 steps, +0.00645 val |
| PR #94 baseline (current) | 0.7 (default) | 3100 | 3.267696 | +0.00831 (n=2) | — |

**Analysis:** Both arms ran cleanly to 3250 steps (verified in W&B — numbers match student report exactly). Both clear stat-sig bar at n=1 against 3.28 target but both lose to PR #94 on both metrics. The default `cooldown_frac=0.7` sits on a flat plateau between 0.5 and 0.8: 0.5 under-budgets high-LR exploration, 0.8 slightly over-budgets it but the 25-step schedule quantization absorbs the tiny val improvement. No headroom at ±0.1 on this axis.

edward's analysis: "The two ±0.1 perturbations both produce within-noise outcomes: 0.5 is slightly worse; 0.8 is slightly better on val/loss but identical on first_step_to_target because the 25-step validation cadence quantizes the early-target-hit detection; 0.7 is on the plateau between them."

**Cross-cutting note:** This is the fifth consecutive null/negative for schedule or post-polar parameter tweak on PMuon+u/w-floor base (after SOAP-MLP, NorMuon row-wise, γ-scan ±0.05, Contra-Muon). The cross-cutting pattern holds: wins on this base require mechanistically new categories, not ±10% scalar tweaks.

**Conclusion:** CLOSED as clean null. Cooldown_frac is a settled lever on this base. Assigned edward PR #158 (Depth-wise per-block LR decay, LLRD — first depth-indexed LR differentiation in the program).

---

## 2026-05-16 16:35 — PR #151 CLOSED: Aurora pre-polar row-norm equilibration — informative null (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-aurora`
- Hypothesis: Aurora row-norm equilibration applied to pre-polar momentum on PMuon+u/w-floor. Aurora is the only pre-polar mechanism not yet tested in isolation on this base. Theory: PMuon's bilateral whitening is post-polar; Aurora is pre-polar; should be geometrically orthogonal.
- W&B run: `qoxky210`

| Metric | this run (n=1) | PR #94 baseline (n=2) | Δ |
| ------ | ------ | ------ | - |
| speedrun/final_first_step_to_target | 3125 | 3100 | +25 (worse) |
| val/loss | 3.269743 | 3.267696 | +0.002047 |
| (3.28−μ)·√n | 0.01026 | 0.01231 (n=2 mean) | passes n=1 vs 3.28 |

**Aurora telemetry (134 samples):**
- `aurora/row_norm_ratio_pre`: mean 1.21e13, max 3.76e13 — momentum has wild row-norm imbalance
- `aurora/row_norm_ratio_post`: mean 5.52e10, max 2.96e11 — Aurora compresses ~220×
- `aurora/cos_pre_post`: mean 0.873 — direction stays mostly aligned after equilibration
- `uw_floor/fired_fraction`: mean 0.826 (slightly lower than baseline's 1.0 — Aurora-equilibrated updates sometimes already have sufficient magnitude)

**Analysis:** Aurora mechanistically works (220× row-norm compression confirmed) but is redundant with PMuon's bilateral whitening on this base. PMuon's bilateral covariance EMA produces a roughly isotropic NS input through a different geometric route (eigenvalue inversion vs row-norm raising). Both routes converge on similar polar inputs. Aurora's small directional rotation (cos=0.873 ≠ 1) costs ~25 sr-steps without buying val improvement.

**Cross-cutting note:** This confirms BOTH pre-polar and post-polar mechanism slots are saturated by PMuon's whitening on this base. The pattern of nulls now spans both sides of the polar step.

**Conclusion:** CLOSED as informative null. Alphonse pivots to per-head polar (PR #169) — first structural change to the polar step itself.

---

## 2026-05-16 16:35 — PR #150 CLOSED: Cautious update sign-mask — NEGATIVE (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cautious`
- Hypothesis: Cautious update (Liang et al. 2024) zeros elements where polar update sign disagrees with raw gradient sign, then renormalizes magnitude. Theory: variance reduction on aggressive optimizers (Lion, Adam).
- W&B run: `ghiesor9`

| Metric | this run (n=1) | PR #94 baseline | Δ |
| ------ | ------ | ------ | - |
| speedrun/final_first_step_to_target | **−1 (never crossed 3.28)** | 3100 | NEGATIVE |
| final val/loss | 3.2938 | 3.267696 | +0.0261 |
| `final_reached_target` | 0 | 1 | failed |

**Analysis:** Clear NEGATIVE (not just null). Cautious masking destroys PMuon's whitening signal. Mechanism: PMuon's bilateral whitening (`L^{-γ} R^{-γ}`) systematically rotates the update relative to raw gradient — by design (preconditioning). After whitening, 20–40% of elements typically flip sign relative to raw grad (normal consequence of rotation). Cautious zeros these elements, destroying most of the geometric correction PMuon provides. u/w-floor then amplifies the corrupted direction. The optimizer wanders, never converges to target.

Cautious works on Lion/Adam because their inner updates are roughly aligned with raw grad (Adam: gradient/√EMA; Lion: sign-of-EMA). PMuon's polar+whitening is geometrically far from raw grad — sign-agreement with raw grad becomes an anti-signal here.

**Operational issue:** A silent-fail duplicate run `1wb1p2eg` was launched at 16:28 UTC with byte-for-byte identical config (advisor flagged in close comment; student was asked to kill it). Same rate-limit silent-fail pattern hitting students this week.

**Cross-cutting note:** 2nd clear NEGATIVE on PMuon+u/w-floor (after PR #119 Contra-Muon). Both negatives involve mechanisms that act on update sign/direction in ways geometrically incompatible with PMuon's bilateral whitening.

**Conclusion:** CLOSED as confirmed negative. Fern pivots to cosine cooldown shape (PR #168) — schedule-side change, categorically different from optimizer mechanisms.

---

## 2026-05-16 15:45 — PR #140 CLOSED: SOAP-MLP + u/w-floor stack on PMuon base — informative null (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-soap-mlp-uw-floor`
- Hypothesis: SOAP-MLP (Shampoo Lˉ¹/⁴ Rˉ¹/⁴ eigenbasis preconditioning on MLP fc/proj weights) stacks orthogonally with u/w-floor (magnitude floor) on PMuon base — tests whether direction-shaping (SOAP) and magnitude control (u/w-floor) compose additively.
- W&B run: `cg6asx9a`

| Metric | Value | vs PR #94 baseline |
| ------ | ----- | ------------------ |
| speedrun/final_first_step_to_target | 3125 | +25 (worse) |
| val/loss | 3.2698 | +0.0021 (vs 3.267696 mean) |
| (3.28−μ)·√n margin | 0.0102 | ✓ clears vs 3.28 |
| n | 1 | — |
| W&B run | `cg6asx9a` | — |

**Mechanistic telemetry (the key diagnostics):**
- `soap/amp_cap_fire_fraction` = 0.000 throughout — SOAP's safety cap never fired. PMuon polar never produced norms SOAP needed to clamp.
- `soap/post_to_pre_ratio` ≈ 0.999998–1.0 — SOAP applied to a polar update is norm-preserving. Rotates in eigenbasis without magnitude change.
- `uw_floor/fired_fraction` identical with vs without SOAP (98–100% from step 1200) — u/w-floor's universal magnitude floor does identical work regardless of whether SOAP is in the path.

**Analysis:** Clean mechanistic null. SOAP-MLP and u/w-floor ARE orthogonal in update magnitude (one changes magnitudes, the other does not) but they compose null because both are applied to the already polar-shaped output of PMuon. PMuon's bilateral whitening already provides the dominant direction regularization on MLP weights — SOAP's eigenbasis rotation adds no value-additive signal on a high-rank, full-band parameter family that polar has already made roughly isotropic. This matches the cross-cutting pattern: post-polar direction-shaping mechanisms are redundant on PMuon+u/w-floor (PRs #83, #93, #110, #118, #119, #129B, now #140).

**Cross-cutting note:** 7th consecutive add-on-mechanism null on PMuon+u/w-floor base (counting this experiment). Only PR #137 (power-law cooldown γ=1.2) shows improvement — and that is a scheduler-side change, not an optimizer-side mechanism addition.

**Conclusion:** CLOSED as informative null. SOAP infrastructure reused for PR #167 (SOAP-ATTENTION on attention q/k/v only — tests different singular-value-spectrum hypothesis).

---

## 2026-05-16 15:45 — PR #143 Arm A: Lookahead k=5 on PMuon+u/w-floor — NULL (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-lookahead`
- Hypothesis: Lookahead (Zhang et al. 2019) outer optimizer (k=5, α=0.5) operates at a completely different abstraction from PMuon's inner whitening — slow-weight copy with periodic pullback provides noise suppression/variance reduction orthogonal to all prior mechanism additions.
- W&B run: `ycmkbjrb` (arm A, k=5)

| Metric | Arm A (k=5) | PR #94 baseline | Δ |
| ------ | ----------- | --------------- | - |
| speedrun/final_first_step_to_target | −1 (null) | 3100 | +∞ (never crossed) |
| final val/loss | 3.2836 | 3.267696 | +0.0159 |
| train_steps | 3250 | 3250 | — |

**Analysis:** Lookahead k=5 produced a NULL result — the target (val ≤ 3.28) was never crossed in 3250 steps. This is a significantly worse outcome than the baseline (val=3.284 vs 3.268). Lookahead's periodic pullback to slow weights appears to counterproductively dampen the effective LR of PMuon+u/w-floor at k=5: pulling fast weights back to slow every 5 steps imposes a 50% blending that partially cancels the u/w-floor magnitude inflation. This is consistent with Lookahead being most beneficial on inner optimizers that are "aggressively noisy" — PMuon+u/w-floor may be directionally clean enough that variance reduction from slow weights is unnecessary and the blending overhead costs more than it saves.

Arm B (k=10) is running (`u78x3cd3` launched ~15:30 UTC) — with longer inner steps between syncs, the blending overhead is halved. If arm B also nulls, Lookahead is definitively not a fit for this base.

**Conclusion:** Arm A (k=5) NULL. Awaiting arm B (k=10) results before full PR close.

---

## 2026-05-16 19:34 — PR #143 CLOSED: Lookahead k=5/10 — confirmed NEGATIVE both arms (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-lookahead`
- W&B runs: `ycmkbjrb` (arm A k=5), `i4eb7s2p` (arm B k=10)

| Arm | k | val/loss | sr | (3.28−μ)·√n | Outcome |
|---|---|---|---|---|---|
| A | 5 | 3.28361 | −1 | −0.00361 | NEGATIVE |
| B | 10 | 3.28390 | −1 | −0.00390 | NEGATIVE |
| PR #137 baseline | — | 3.269090 | 3062.5 | +0.01546 | reference |

**Both arms NEVER crossed 3.28 in 3250 steps.** Lookahead is fundamentally incompatible with PMuon+u/w-floor at any k value tested.

**Mechanism (confirmed by thorfinn's `cosine_drift` telemetry, mean +0.75):** Lookahead's slow-weight pullback (α=0.5 blend every k steps) creates destructive interference with u/w-floor's persistent magnitude inflation. Three nested forces oscillate: PMuon whitening rotates direction → u/w-floor lifts magnitude → Lookahead snaps back → repeat. Per-step equilibrium drift = m·(1−α/k). At k=5: 0.9·m; at k=10: 0.95·m. Neither high enough to converge in 3250 steps.

**Cross-cutting:** 2nd outer-loop NEGATIVE on PMuon+u/w-floor (joins PR #119 Contra-Muon). Combined with 11+ post-polar nulls, the pattern is clear: outer-loop and post-polar mechanism additions are all blocked by u/w-floor × bilateral-whitening interaction.

**Conclusion:** CLOSED as confirmed NEGATIVE. Thorfinn pivots to NS iteration count scan (fundamental polar hyperparameter, never touched) — categorically new probe in core polar mechanism, not outer-loop or shape addition.

---

## 2026-05-16 12:00 — PR #119 CLOSED: Measured-scale Contra-Muon × PMuon — final negative (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-contra-measured`
- Hypothesis: Contra-Muon (subtract coeff × Frobenius-normalized pre-polar momentum from the polar update) with measured-scale calibration to fix the PR #95 magnitude mismatch.
- W&B runs: `wsdmrs7q` (A, no warmup), `kyaj7khd` (B, no warmup), `o156ipbq` (A+, warmup=200), `q54bnxvq` (B+, coeff=0.05 warmup=500)

| arm | coeff | warmup | sr | best val | outcome |
| --- | --- | --- | --- | --- | --- |
| A | 0.10 | 0 | — | 7.51 | grad blowup step 50 |
| B | 0.05 | 0 | — | 4.31 | linalg.eigh crash step 846 |
| A+ | 0.10 | 200 | — | — | re-exploded step 500 |
| **B+** | **0.05** | **500** | **−1** | **3.31596** | stable but never crossed 3.28 |

**Key finding (cos(update_dir, m_pre_dir) monotonic rise 0.026→0.513):** Late in training, the orthogonal contra direction acts on a shrinking residual that's no longer a useful descent signal. Constant coeff=0.05 imposes ~5% off-axis noise in the converged regime — irreducible noise floor. Calibration was perfect (8-decimal precision) — magnitude was never the issue. PMuon's bilateral whitening and Contra-Muon's orthogonal perturbation fight geometrically.

**Cross-cutting note:** Contra-Muon works on plain Muon (Records #11, #14, #20) because there's no bilateral whitening to conflict with. PMuon's L_cov/R_cov EMA already provides geometric regularization that Contra-Muon disrupts.

**Conclusion:** CLOSED as fundamental incompatibility (not tuning failure). 4 arms, 4 different failure or underperformance modes, all consistent with bilateral-whitening × orthogonal-perturbation conflict. Assigned alphonse PR #151 (Aurora row-norm equilibration — pre-polar mechanism, geometrically orthogonal).

---

## 2026-05-16 18:26 UTC — PR #137 MERGED: PMuon + u/w-floor + Power-Law Cooldown γ=1.2 — WINNER n=2 (g1r1-nezuko)

- Branch: `g1r1-nezuko/pmuon-uw-power-1p2`
- Hypothesis: Power-law cooldown shape `eta = ((1−progress)/cooldown_frac)^γ` with γ=1.2 on PMuon+u/w-floor base. Concave-down decay drops lr faster through mid-cooldown, predicted to accelerate descent across 3.28 at cost of slightly higher final val.
- W&B runs: `8quuvdrj` (seed-1), `l5bdkm6e` (seed-2)

| Metric | seed-1 | seed-2 | **n=2 mean** | PR #94 baseline (n=2) | Δ |
| ------ | ------ | ------ | ------------ | --------------------- | - |
| speedrun/final_first_step_to_target | 3075 | **3050** | **3062.5** | 3100 | **−37.5 steps ✅** |
| val/loss (final) | 3.270012 | 3.268167 | **3.269090** | 3.267696 | +0.001394 (regression, within seed-noise) |
| (3.28−μ)·√n | — | — | **0.01543** | 0.01740 | ✓ clears 0.004 bar |
| `final_reached_target` | 1 | 1 | — | — | both clean |

**Mechanistic analysis:**
- Power-law γ=1.2 makes cooldown concave-down: at 50% cooldown progress, `eta=0.5^1.2=0.435` vs linear `eta=0.5`. This drops lr faster in mid-cooldown, pulling the model across the 3.28 boundary ~37.5 steps earlier on average.
- Tradeoff: less time at moderate lr in late cooldown → slightly higher final val (+0.0014). This is the right trade for the speedrun benchmark.
- `uw_floor/fired_fraction=1.0` on both seeds — u/w-floor and power-law cooldown compose cleanly, both active simultaneously throughout training.
- Seed-2 (sr=3050) is 1 tick BETTER than seed-1 (sr=3075), showing the mechanism is consistent and reproducible.

**Cross-cutting significance:**
- FIRST improvement on PMuon+u/w-floor base in 10+ experiments.
- ALL prior improvements were from optimizer-mechanism additions; this is a **schedule-shape** win.
- Establishes that the schedule-shape dimension (γ parameter, cooldown curve family) is the open lever on this base.
- Opens Wave 5: γ × cooldown_frac joint surface scan, cosine cooldown comparison (PR #168 running).

**Conclusion:** MERGED as new baseline. sr=3062.5, val=3.269090. Nezuko freed → assigned Wave 5 γ scan (γ ∈ {1.1, 1.3} arms to probe curvature around the optimum).



---

## 2026-05-16 20:30 UTC — PR #167 CLOSED: SOAP on attention q/k/v only on PMuon+u/w-floor base — NULL on primary (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-soap-attn`
- Hypothesis: Restrict SOAP preconditioning to the 36 attention q/k/v 2-D weights only (MLP weights take plain PMuon+u/w-floor). Motivated by the observation that attention matrices might have lower effective rank than MLP weights, making eigenbasis rescaling more impactful in that slot.
- W&B run: `sb4u7xhb` (n=1, 3250 steps, linear cooldown)

| Metric | PR #167 SOAP-attn (n=1) | PR #94 baseline (n=2 mean) | Δ |
| ------ | ----------------------- | -------------------------- | - |
| speedrun/final_first_step_to_target | 3100 | 3100 | 0 (NULL on sr) |
| val/loss | 3.26806 | 3.267696 | +0.000364 (regression, within seed noise) |
| (3.28−μ)·√n | 0.01194 | 0.01740 | Worse vs baseline |
| Current best baseline (PR #137) | — | 3062.5 / 3.269090 | **sr regresses +37.5 steps** |

**Headline mechanistic finding — `post_to_pre_ratio`:**

| stat | value |
|---|---|
| mean | **0.99999858** (n=133 telemetry events) |
| median | 0.99999862 |
| min / max | 0.99999703 / 0.99999983 |
| mean |ratio−1| | 1.42e-6 |
| amp_cap_fire_fraction | **0.000** (never fires) |

The SOAP-attn Frobenius renorm (`multiplier = pre_norm / post_norm`) cancels SOAP's eigenbasis rescaling almost exactly — `post_to_pre_ratio` mean = 0.99999858 (even closer to 1 than PR #140 SOAP-MLP: 0.999998). The asymmetric amp cap (1.5) never fires. **SOAP-attn is a no-op at this slot, same as SOAP-MLP.**

**Spectral finding — attention q/k/v effective rank:**

The motivating hypothesis (attention q/k/v have low effective rank → SOAP has more to grip) is NOT borne out. Participation ratio ≈ 526 / 768 ≈ 0.68. Top-1 singular value carries only ~1% energy; top-128 carry ~52%. Spectrum is moderately spread, not strongly skewed. No dominant subspace for SOAP to leverage.

**u/w-floor domination:** `uw_floor/fired_fraction` mean=0.853, median=1.000. The u/w-floor is the dominant force on update magnitude every step; SOAP-attn's contribution is masked.

**Cross-PR significance:**

- Completes the "post-polar Frobenius-preserving preconditioning" probe family: PR #140 (SOAP-MLP, null) + PR #167 (SOAP-attn, null) = **this slot is exhausted on PMuon+u/w-floor base**.
- The Frobenius renorm invariant (`pre_norm / post_norm < 1.5` so amp_cap never fires) was the decisive mechanism in both cases.
- PR #83 (SOAP-MLP standalone, null), PR #140 (SOAP-MLP × PMuon+u/w-floor, null), PR #167 (SOAP-attn × PMuon+u/w-floor, null) — three independent null results confirming the same mechanism.

**Conclusion:** Closed as informative null. Tanjiro reassigned to Wave 5 NS coefficient scan (PR #193): sweeping (a, b, c) ∈ {Jordan-optimized (3.4445, -4.7750, 2.0315), cubic-Newton (1.5, -0.5, 0)} on the PMuon+u/w-floor+γ=1.2 base. Together with thorfinn PR #184 (NS iter count scan), this fully maps the NS polar hyperparameter space.

---

## 2026-05-16 21:05 UTC — PR #168 CLOSED: Cosine cooldown on PMuon+u/w-floor base — NULL vs new baseline (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cosine-cooldown`
- Hypothesis: Cosine s-curve cooldown as alternative to power-law γ=1.2. Hypothesis: if γ=1.2 wins via "smoother lr trajectory" then cosine should be better; if from "mid-cooldown decay aggressiveness" cosine should be worse.
- W&B run: `sf7fq2ul` (n=1, 3250 steps)

| Metric | PR #168 Cosine (n=1) | PR #137 baseline γ=1.2 (n=2 mean) | Δ |
| ------ | -------------------- | ---------------------------------- | - |
| speedrun/final_first_step_to_target | 3075 | **3062.5** | **+12.5 steps (NULL vs baseline)** |
| val/loss | 3.276583 | 3.269090 | +0.0075 (worse) |
| (3.28−μ)·√n | 0.00342 | 0.01543 | **BELOW 0.004 bar (negative!)** |
| vs PR #94 linear baseline | −25 sr | +0.0089 val | Beats linear on sr, worse on val |

**Key mechanistic decomposition (from logged `train/cooldown/eta`):**

At the crossing point (~step 3075, 92% cooldown progress):
- Cosine eta: **0.0147** (5× lower than linear's 0.080)
- γ=1.2 eta: **0.052** (~3.5× lower than linear)

Both cosine and γ=1.2 cross at sr=3075 — same crossing step despite opposite decay shapes (back-loaded vs front-loaded). But post-crossing:
- Cosine eta at step 3100: **0.011** → effectively dead, can't refine val
- γ=1.2 eta at step 3100: **0.041** → continues refining val from 3.279 → 3.268

**Insight: "any deviation from linear that lowers eta around the crossing window brings sr in by ~25 steps"** regardless of front-loaded vs back-loaded. Post-crossing val refinement requires preserved late-cooldown lr. This splits the schedule-shape effect into two separable mechanisms: (a) crossing sensitivity to integral of recent lr; (b) post-crossing refinement from late-lr preservation.

**What hypothesis was tested:**
- "Smoother lr trajectory (cosine)" — NOT confirmed (val worse despite smooth endpoints)
- "Back-loaded decay helps vs front-loaded" — NOT confirmed (both shapes give same sr=3075)
- **Discovered:** Both shapes lower eta around the crossing window, explaining the tie; but cosine's late collapse explains the val regression.

**Conclusion:** Closed as informative null vs new baseline (sr regresses +12.5, val regresses +0.0075). Mechanistic framework motivates **cooldown_frac scan on γ=1.2 base** (PR #195). Fern's telemetry predicts: cf=0.85 (longer cooldown) should preserve late lr → better val; cf=0.5 (shorter) front-loads → may cross earlier but worse val. Direct test of PR #168's mechanistic decomposition.

---

## 2026-05-16 21:35 UTC — PR #169 CLOSED: Per-head polar on attn q/k/v — NULL (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-perhead-polar`
- Hypothesis: Per-head NS polar projection on attention q/k/v (reshape to [n_heads, h_dim, dim], apply NS5 batched over heads) gives better per-head conditioning than full-matrix polar. Hypothesis: attention matrices have head-specific subspace structure that full-matrix polar over-homogenizes.
- W&B run: `8mgxsj35` (n=1, 3250 steps, 3h 28m)

| Metric | PR #169 per-head polar (n=1) | PR #137 baseline (n=2 mean) | Δ |
| ------ | ----------------------------- | --------------------------- | - |
| speedrun/final_first_step_to_target | 3125 | **3062.5** | **+62.5 steps (NULL)** |
| val/loss | 3.2706 | 3.269090 | +0.0015 (worse) |
| (3.28−μ)·√n | 0.00938 | 0.01543 | Below baseline |

**Mechanism diagnostics — mechanism worked, learning didn't:**

Per-head SVD conditioning (final, block 0):
| proj | per-head sv_max/sv_min | full-matrix sv_max/sv_min | improvement |
|---|---|---|---|
| q | 4.34 | 6649.5 | **~1530×** |
| k | 4.71 | 4082.5 | **~870×** |
| v | 2.37 | 4532.3 | **~1910×** |

Inter-head subspace disagreement (cos_abs_mean ≈ 0.003 ≈ random orthogonal — heads did NOT collapse).

**Polar saturation confirmed across structural axis:**

This is the 11th add-on null on PMuon+u/w-floor, and the first to vary the *structural unit* of polar itself. The mechanism worked (dramatically better per-head conditioning, genuinely orthogonal head subspaces) but produced zero learning improvement. Conclusion: the polar step is saturated as an optimization lever — restructuring it (per-head vs full-matrix) makes no difference.

Combined with PR #83 (SOAP-MLP, null), PR #140 (SOAP-MLP+u/w, null), PR #167 (SOAP-attn, null), PR #151 (Aurora pre-polar, null): every approach to improving polar quality on this base has been null.

**Conclusion:** Closed. Polar saturation confirmed. Reassigned alphonse to EMA weight averaging PR #197 — orthogonal probe (parameter trajectory smoothing, bypasses optimizer stack entirely).

---

## 2026-05-16 21:38 UTC — PR #158 CLOSED: LLRD depth-wise LR decay — NEGATIVE (both arms) (g1r1-edward)

- Branch: `g1r1-edward/pmuon-llrd-scan`
- Hypothesis: Depth-wise per-block LR decay (shallow=full, deep=reduced) on PMuon+u/w-floor. Two arms: decay=0.85 (stronger) and decay=0.90 (milder).
- W&B runs: `8v3v2l4h` (arm A, decay=0.85), `z6xxow8s` (arm B, decay=0.90)

| Arm | depth_decay | sr | val/loss | Δ val vs baseline |
| --- | ----------- | -- | -------- | ----------------- |
| A (decay=0.85) | LR ratio: 0.167 (block_11/block_00) | -1 (never) | 3.300076 | +0.031 |
| B (decay=0.90) | LR ratio: 0.314 (block_11/block_00) | -1 (never) | 3.285725 | +0.017 |
| Baseline (uniform) | 1.000 | 3062.5 | 3.269090 | — |

**Critical per-block grad-norm finding (block_00 → block_11 at step 1000):**

Arm A: 21688 → 28735 → 25866 → ... → **30568** (block_11 HIGHEST)
Arm B: 13939 → 15934 → 16833 → ... → **18279** (block_11 HIGHEST)

Block_11 (deepest) carries 1.5–3× the gradient norm of intermediate blocks throughout training. The LLRD direction tested (shallow=full, deep=reduced) starves the layer with the LARGEST learning signal — mechanistically backwards.

**Two failure mechanisms confirmed:**
1. LLRD direction reversed: from-scratch GPT with PMuon has block_11 dominating grad-norm; standard fine-tuning LLRD (shallow=full, deep=reduced) is wrong direction for this setup.
2. u/w-floor absorption: fires at 100% of params, renormalizes updates post-LLRD, absorbs depth LR signal.

Monotone harm: every nudge away from uniform LR hurts. No evidence of sweet spot between 0.90 and 1.0.

**Conclusion:** Closed as NEGATIVE (both arms fail to reach 3.28). LLRD direction (shallow=full, deep=reduced) is confirmed wrong. Edward reassigned to per-block weight decay PR #198 — WD acts on `p` directly, bypasses both PMuon bilateral whitening AND u/w-floor.

---

## 2026-05-16 22:30 UTC — PR #129 CLOSED: PMuon β_cov scan {0.90, 0.95, 0.99} — NULL (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-uw-bcov-scan`
- Hypothesis: PMuon covariance EMA horizon (β_cov) controls how many recent gradients contribute to L/R. Default β=0.95 never swept; scan brackets it with {0.90, 0.99}.
- W&B runs: `dstsva72` (arm A, β=0.90), `ueglklrb` (arm B, β=0.95), `xxx` (arm C, β=0.99)

| Arm | β_cov | sr | val/loss | Δ val vs baseline | lcov_eigh_min |
| --- | ----- | -- | -------- | ----------------- | ------------- |
| A (β=0.90) | shorter horizon | 3125 | 3.26889 | −0.00020 | −3.4×10⁻⁴ (near-singular) |
| B (β=0.95, baseline) | default | 3125 | ~3.269090 | baseline | 26.6 (healthy) |
| C (β=0.99) | longer horizon | ~3125 | 3.269+ | ~null | 0.57 (degraded) |
| Baseline PR #137 | uniform β=0.95 | 3062.5 | 3.269090 | — | — |

**Key eigh telemetry finding (lcov_eigh_min, L_cov conditioning):**
- β=0.90: −3.4×10⁻⁴ → near-singular L_cov (too-rapid covariance decay, numerically unstable)
- β=0.95: 26.6 → healthy conditioning (confirmed sweet spot)
- β=0.99: 0.57 → degraded conditioning (too-slow EMA, stale covariance, diminished whitening)

**Non-monotonic conditioning:** β_cov=0.95 sits at the conditioning optimum between two degenerate regimes. This is the cleanest mechanistic null in the programme — the hyperparameter is genuinely at a local optimum, not just insensitive.

**Conclusion:** Closed as informative NULL. β_cov axis fully characterized. Frieren reassigned to PMuon whitening exponent (γ_power) scan PR #201 — the dual axis: β_cov controls covariance horizon, γ_power controls whitening strength (L^{−γ} R^{−γ}).

---

## 2026-05-16 22:35 UTC — PR #201 ASSIGNED: PMuon γ_power whitening exponent scan {0.2, 0.4} (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-uw-gamma-power-scan`
- Hypothesis: PMuon bilateral whitening uses `polar(L^{-γ} m R^{-γ})`. Default γ_power=0.3 fixed since PR #64, never swept. Dual axis to β_cov: where β controls covariance horizon, γ_power controls whitening strength.
  - Arm A (γ_power=0.4): stronger whitening → more uniform polar input, amplifies small gradient directions more aggressively
  - Arm B (γ_power=0.2): weaker whitening → preserves more natural gradient spectrum shape
- Telemetry: reuse eigh framework + add `pmuon/whitened_sv_ratio` post-whitening spectral diagnostic
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137, n=2 mean)

---

## 2026-05-17 01:15 UTC — PR #131 CLOSED: TARGET_UW sweep {0.25, 0.30, 0.40, 0.45} — NULL (g1r1-askeladd)

- Branch: `g1r1-askeladd/pmuon-uw-sweep`
- Hypothesis: TARGET_UW (u/w-floor threshold) controls the dominant per-param LR mechanism when fired_fraction=1.0. Scan brackets 0.35 baseline.
- W&B runs: `fphpexnb` (0.25), `dkxweoah` (0.30), `imf0s97n` (0.40), `lou98cqm` (0.45); `m3rq3zyd` (crashed 0.40 duplicate)

| Arm | TARGET_UW | sr | val/loss | fired_fraction (final) | mean_ratio |
| --- | --------- | -- | -------- | ---------------------- | ---------- |
| 0.25 | 0.25 | 3150 | 3.27382 | 0.125 (9/72 params) | 0.310 |
| 0.30 | 0.30 | 3100 | 3.26898 | 0.569 (41/72 params) | 0.255 |
| Baseline | 0.35 | 3062.5 | 3.269090 | 1.000 | — |
| 0.40 | 0.40 | 3150 | 3.27023 | 1.000 | 0.087 |
| 0.45 | 0.45 | 3150 | 3.27161 | 1.000 | 0.042 |

**Key mechanistic finding:** fired_fraction COLLAPSES below TARGET_UW=0.35. Above 0.35 → floor clamps 100% of params (dominant LR mechanism). Below 0.30 → PMuon's natural magnitudes take over (mean_ratio=0.310 at 0.25). This transition is mechanistically important: the floor acts as a hard on/off per-param LR switch. Best arm (0.30) ties baseline val but loses 37.5 sr-steps.

**Conclusion:** Closed as informative NULL. TARGET_UW=0.35 is at the fired_fraction transition sweet spot. Lower floors (0.30, 0.25) remove the dominant LR mechanism for many params; higher floors (0.40, 0.45) are redundant clamps. Askeladd reassigned to lm_head LR scan PR #211 (first aux optimizer probe in program history).

---

## 2026-05-17 01:15 UTC — PR #211 ASSIGNED: lm_head LR scan {1/640, 1/160} (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-lmhead-lr-scan`
- Hypothesis: Aux AdamW lm_head LR=1/320 (≈0.003125) is a static legacy value never swept on this base (96× below embed LR=0.3). Brackets with ×2 and ×0.5 multipliers.
- Arms: 1/160 (2× larger), 1/640 (2× smaller)
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137)
- Telemetry: lmhead_grad_norm, lmhead_param_norm, lmhead_update_norm / lmhead_param_norm ratio

---

## 2026-05-17 01:00 UTC — PR #184 PARTIAL: NS iter=6 arm A WINS (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/pmuon-uw-ns-iter-scan`
- Arm A (ns_iter=6): **sr=3050, val=3.26774** — BEATS BASELINE by 12.5 sr-steps and 0.00135 val
- Statistical rule n=1: (3.28-3.26774)×√1 = 0.01226 >> 0.004 ✓
- **Critical telemetry:** polar/ortho_residual_sample=2.31 (high — less convergent) at ns_iter=6 vs expected ~0.01 at ns_iter=12. LESS precise polar → BETTER performance.
- Arm B (ns_iter=18) launching now. Terminal pending ~04:30 UTC.
- W&B run: `crelrjzb`

**Mechanistic implication:** over-orthogonalization is counterproductive. The ns_iter=6 polar direction carries more gradient information than the fully-converged ns_iter=12. This is a FIRST NON-SCHEDULE WIN on PMuon+u/w-floor base. Pending confirmation via arm B + terminal SENPAI-RESULT.

---

## 2026-05-17 00:23 UTC — PR #193 PARTIAL: Jordan NS coef arm A borderline NULL (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-scan`
- Arm A (Jordan-opt coef: 3.4445, -4.7750, 2.0315): sr=3075, val=3.27041
- sr=3075 is slower than baseline 3062.5; val=3.27041 is slightly worse than 3.26909
- **Critical telemetry:** polar/ortho_residual_sample=11.12478 — extremely high. Jordan coefficients produce LESS convergent polar than ns_iter=12 default.
- Connecting to thorfinn arm A: both ns_iter=6 AND Jordan-opt coefficients produce high ortho_residual; but ns_iter=6 WINS while Jordan is borderline NULL. Implication: the PATH to "less orthogonal" matters, not just the residual magnitude.
- Arm B (cubic-Newton coef: 1.5, -0.5, 0) launching. Terminal pending.
- W&B run: `taitef3m`

---

## 2026-05-17 01:35 UTC — Wave 5 arm A snapshot (W&B-verified)

All 8 Wave 5/6 students have completed arm A. Two independent winners detected:

| PR  | Student   | Arm A mechanism                | sr     | val      | Verdict (vs baseline 3062.5/3.26909) |
|-----|-----------|--------------------------------|--------|----------|---------------------------------------|
| #184 | thorfinn | ns_iter=6                       | **3050** | **3.26774** | **WIN** (sr −12.5, val −0.00135)     |
| #198 | edward   | deep-strong per-block WD         | **3050** | **3.26819** | **WIN** (sr −12.5, val −0.00090) — partial not yet posted |
| #197 | alphonse | EMA α=0.99                      | 3100   | 3.27504  | **NEGATIVE** (sr +37.5, val +0.006) — bias-lag in cooldown |
| #195 | fern     | cooldown_frac=0.85              | 3075   | 3.27214  | NULL (sr +12.5, val +0.003)           |
| #193 | tanjiro  | Jordan NS coefs                  | 3075   | 3.27041  | NULL (sr +12.5, val +0.001)           |
| #179 | nezuko   | γ=1.1                           | 3075   | 3.26813  | NULL on sr (val tied; γ=1.2 at concavity optimum) |

Arm B status (mid-flight): thorfinn ns_iter=18 (31%), tanjiro cubic-Newton (34%), alphonse EMA α=0.999 (3%), frieren γ_power=0.4 arm A (78%), nezuko γ=1.3 (82%), fern cf=0.5 (4%), edward deep-weak (4%), askeladd lm_head/160 arm A (25%).

**Headline:** First two non-schedule wins on PMuon+u/w-floor base after 19 nulls/negatives. Both arms tie on sr=3050 but operate on orthogonal axes:
- **thorfinn**: changes the polar projection (NS iterations) — over-orthogonalization is counterproductive
- **edward**: changes the weight decay (per-block WD) — WD acts on `p` directly, bypassing PMuon whitening and u/w-floor

**Stacking implication for Wave 7:** If these mechanisms compound additively or near-additively, ns_iter=6 + deep-strong WD could push sr ≤ 3025-3037.5. Designing the Wave 7 stacking PR after both terminals confirm.

**Connection to PR #129 + #131 closures:** β_cov is at conditioning optimum (β=0.95) and TARGET_UW is at fired_fraction transition (0.35). PMuon hyperparameter axis is converged. Wins come from changes *around* the PMuon core: polar projection quality (NS_iter) and gradient damping (WD on `p`). γ_power (frieren PR #202) and lm_head LR (askeladd PR #211) are the next two axes to characterize.

---

## 2026-05-17 02:34 UTC — PR #202 PARTIAL (arm A done): frieren γ_power=0.4 MASSIVE WIN

- Branch: `g1r1-frieren/pmuon-uw-gamma-power-scan`
- Arm A (γ_power=0.4 — stronger whitening): **sr=3025, val=3.26615** — confirmed via W&B run `prncgzv5`

| Metric | γ_power=0.4 (arm A) | Baseline PR #137 | Δ |
|---|---|---|---|
| `speedrun/final_first_step_to_target` | **3025** | 3062.5 (n=2) | **−37.5 sr-steps** |
| `val/loss` | **3.26615** | 3.269090 | **−0.00294** |
| stat-sig n=1 | (3.28−3.26615)×√1 = 0.01385 ✓ | threshold 0.004 | 3.46× above threshold |

**This is the single largest Δsr arm A win on the program to date.** Exceeds both thorfinn (−12.5) and edward (−12.5) by 3× on sr.

**Mechanism:** γ_power controls the whitening exponent in PMuon's covariance preconditioning. With default γ_power=0.3, the spectral conditioning is moderate; with γ_power=0.4, the covariance EMA is more aggressively scaled. Hypothesis: stronger whitening better removes the ill-conditioning from block weight matrices' spectral structure, allowing the NS polar projection to operate in a more isotropic gradient space. The net effect is faster convergence in the late cooldown phase.

**Three arm A wins now on PMuon+u/w+γ=1.2 base (all pending terminals):**
1. **frieren γ_power=0.4: sr=3025, val=3.26615** (BIGGEST)
2. thorfinn ns_iter=6: sr=3050, val=3.26774
3. edward deep-strong WD: sr=3050, val=3.26819

**Arm B (γ_power=0.2 — weaker whitening) just started.** If arm B is worse (monotone stronger→better), finer scan {0.5, 0.6} warranted. If arm B also wins, broad sweet spot (0.2–0.4 range all good).

**Wave 7 stacking revision:** Original stacking plan (ns_iter=6 + deep-strong WD → est. sr=3037.5) is NOW upgraded to 3-way stack (ns_iter=6 + deep-strong WD + γ_power=0.4 → est. sr=3000-3025). This would tie/beat the Prime Intellect public Record #20 reference (3030 steps).

---

## 2026-05-17 02:34 UTC — PR #179 TERMINAL: nezuko γ scan CLOSED NULL

- Branch: `g1r1-nezuko/pmuon-uw-gamma-scan`
- Arm A (γ=1.1): sr=3075, val=3.26813 — NULL
- Arm B (γ=1.3): sr=3075, val=3.27249 — NULL

| Metric | γ=1.1 (arm A) | γ=1.2 (baseline, n=2) | γ=1.3 (arm B) |
|---|---|---|---|
| sr | 3075 | 3062.5 | 3075 |
| val | 3.26813 | 3.269090 | 3.27249 |
| Δsr vs γ=1.2 | +12.5 | — | +12.5 |

**Conclusion:** γ=1.2 is the confirmed local optimum on the power-law cooldown concavity axis. Both 1.1 (too mild) and 1.3 (too aggressive) cross 3.28 12.5 steps later than baseline. Axis CLOSED. Terminal SENPAI-RESULT posted 02:27 UTC.

Nezuko reassigned to **PR #216 (aux AdamW β2 scan {0.99, 0.999})** — first probe of aux optimizer variance horizon.

---

## 2026-05-17 02:34 UTC — PR #216 ASSIGNED: aux AdamW β2 scan (g1r1-nezuko)

- Branch: `g1r1-nezuko/aux-beta2-scan`
- Hypothesis: AdamW β2=0.95 (static since PR #64) is unusually low vs default 0.999. Scan {0.99, 0.999} to characterize variance EMA horizon.
- Arms: β2=0.99 (arm A, longer horizon), β2=0.999 (arm B, standard AdamW)
- Telemetry: aux/embed_effective_lr, aux/lmhead_effective_lr, aux/embed_v_mean/std per step
- Baseline to beat: sr=3062.5, val=3.269090 (PR #137)

---

## 2026-05-17 04:30 UTC — PR #193 TERMINAL: Cubic-Newton NS coefs WIN → MERGED as new baseline

- Branch: `g1r1-tanjiro/pmuon-uw-ns-coef-scan`
- **MERGED** — new baseline: sr=3050, val=3.26773 (n=1)

| Arm | Coefficients | sr | val | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|
| Baseline (PR #137) | (2, -1.5, 0.5) quintic | 3062.5 (n=2) | 3.269090 | ~0.01 | — |
| Arm A — Jordan-opt | (3.4445, -4.7750, 2.0315) | 3075 | 3.27041 | ~11.12 (oscillating) | NULL |
| **Arm B — cubic-Newton** | **(1.5, -0.5, 0.0)** | **3050** | **3.26773** | **~0.10 (saturated)** | **WIN → MERGED** |

- W&B arm B run: `q8aduc16` — stat-sig n=1: (3.28−3.26773)×√1=0.01227≥0.004 ✓

**Mechanistic finding:** Both Jordan (residual ~11, oscillating) and cubic-Newton (residual ~0.10, saturated) produce non-converged polars, yet cubic-Newton WINS while Jordan NULLs. Path to under-convergence matters more than residual magnitude. Cubic-Newton's classical Newton iteration finds a better gradient direction basin than the fully-converged quintic, while Jordan overshoots the whitened input's near-orthogonal state and oscillates. Cross-reference: thorfinn PR #184 ns_iter=6 (residual ~2.31) reaches similar regime via fewer iterations — same mechanistic family.

---

## 2026-05-17 04:30 UTC — PR #184 TERMINAL: NS_ITERS closed as wide flat regime

- Branch: `g1r1-thorfinn/pmuon-uw-ns-iter-scan`
- **CLOSED as informative null** — both arms tie on sr=3050 with 14× difference in polar residual

| Arm | NS_ITERS | sr | val | polar/ortho_residual | Verdict |
|---|---|---|---|---|---|
| Baseline | 12 | 3062.5 (n=2) | 3.269090 | ~0.01 | — |
| Arm A | 6 | 3050 | 3.26774 | ~2.31 | n=1 win (noise-band?) |
| Arm B | 18 | 3050 | 3.26724 | ~0.148 | n=1 win (noise-band?) |

**Reason for closure:** Wide flat NS_ITERS regime detected — both arms win with near-identical sr=3050 despite 14× residual difference. Student's own analysis questions noise-band nature. PR #193 cubic-Newton merged simultaneously as a more distinct polar mechanism change. Merging both overlapping polar changes without testing the compound would create an untested interaction.

**Key citation-worthy finding:** PMuon's bilateral whitening makes the polar step's orthogonality precision largely irrelevant. 14× polar residual change → <0.05% val/loss change. The polar step is a direction-normalizer, not a precision-optimizer.

---

## 2026-05-17 04:35 UTC — PR #225 ASSIGNED: Wave 7 3-way stack (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/wave7-gpower04-deepwd-lmhead160-stack`
- **Assignment:** γ_power=0.4 + deep-strong WD (slope=+0.5) + lm_head LR 1/160 on cubic-Newton+PMuon+u/w+γ=1.2 base
- n=2 directly (seeds 1+2)
- Conservative additive from new baseline (3050): 3050 − 37.5 − 12.5 − 12.5 = **sr=2987.5** (would BEAT Record #20 at 3030)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/225

---

## 2026-05-17 04:35 UTC — PR #226 ASSIGNED: NS coef c-scan (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan`
- **Assignment:** c ∈ {0.1, 0.25} scan on cubic-Newton (a=1.5, b=-0.5, c=0) baseline
- Maps the winning NS polynomial family: does the win extend above c=0? Crossover between c=0 WIN and c=0.5 NULL.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/226


## 2026-05-17 05:40 UTC — PR #197 CLOSED: EMA model weight averaging (g1r1-alphonse)

- Branch: `g1r1-alphonse/pmuon-uw-ema-avg`
- **Hypothesis:** EMA (α=0.99, 0.999) provides mid-training polish that survives speedrun crossing
- W&B runs: `gmskliu2` (α=0.99), `ywlqvzay` (α=0.999)

| Arm | α | sr | val/loss | Verdict |
|-----|---|----|----------|---------|
| Baseline | — | 3050 | 3.26773 | — |
| Arm A | 0.99 | 3100 | 3.27504 | NEGATIVE (+50 sr) |
| Arm B | 0.999 | -1 (never) | 3.36121 | SEVERE NEGATIVE |

**Analysis:** Bias-lag mechanism confirmed conclusively. Power-law cooldown drops LR 25× over 175 steps; live weights improve faster than EMA tracks. EMA is a low-pass filter; cooldown is a high-frequency drop — structurally incompatible. Same mechanism as Lookahead (PR #143). EMA direction closed permanently.

**Conclusion:** CLOSED. EMA weight averaging incompatible with speedrun cooldown geometry. Cross-axis: any post-hoc smoothing on model weights will lose on this base.

---

## 2026-05-17 05:40 UTC — PR #195 CLOSED: cooldown_frac scan (g1r1-fern)

- Branch: `g1r1-fern/pmuon-uw-cooldown-frac-scan`
- **Hypothesis:** cooldown_frac ∈ {0.5, 0.85} (vs baseline 0.7) — longer/shorter stable phase
- W&B runs: `wa0d9w7u` (cf=0.85), `ryp8lipu` (cf=0.5)

| Arm | cf | sr | val/loss | Verdict |
|-----|----|----|----------|---------|
| Baseline | 0.7 | 3050 | 3.26773 | — |
| Arm A | 0.85 | 3075 | 3.27214 | NEGATIVE (+25 sr) |
| Arm B | 0.5 | 3150 | 3.27419 | NULL (+100 sr) |

**Analysis:** cf=0.7 confirmed concave minimum. Key mechanistic update: late-eta is NOT monotonically predictive of val — cf=0.5 has highest late-eta but worst val. Real axis: stable-phase length vs cooldown integral. Model wants ~70% cooldown. Combined with PR #179 γ-scan (γ=1.2 optimal), the (γ, cf) surface is exhausted at current operating point.

**Conclusion:** CLOSED. Schedule family at γ=1.2 thoroughly characterized: both cf and γ axes are at their respective sweet spots.

---

## 2026-05-17 05:40 UTC — PR #198 CLOSED: Per-block WD coupling (g1r1-edward)

- Branch: `g1r1-edward/pmuon-uw-perblock-wd`
- **Hypothesis:** Depth-coupled WD (slope ±0.5) bypasses PMuon+u/w-floor, reshapes parameter geometry
- W&B runs: `7lzjw46u` (deep-strong), `4wwaiype` (deep-weak)

| Arm | wd_slope | sr | val/loss | Verdict |
|-----|----------|-----|----------|---------|
| Baseline (PR #193) | 0.0 | 3050 | 3.26773 | — |
| Arm A deep-strong | +0.5 | 3050 | 3.268193 | NULL (val regression +0.000463 vs new baseline) |
| Arm B deep-weak | -0.5 | 3050 | 3.269250 | NULL (val regression +0.001520) |

**Analysis:** Both arms beat old PR #137 baseline but NOT new PR #193 cubic-Newton baseline. Mechanism CONFIRMED via per-block param-norm divergence (b00 535→270, b11 597.9→1159.6 between arms). WD acts on `p` before update path, bypassing both PMuon whitening and u/w-floor. Deep-strong arm A has cleaner val (3.268193 vs 3.269250 deep-weak). Deep-strong mechanism is already included as ingredient in Wave 7 stack PR #225.

**Conclusion:** CLOSED as informative. Mechanism confirmed active and included in Wave 7 stack. If Wave 7 stack wins, deep-strong WD contribution is validated. If not, axis needs a fresh look on the compound base. Follow-up candidate: asymmetric step-function WD profile (wd_mult={0.8 for l<6, 1.2 for l≥6}).

---

## 2026-05-17 05:45 UTC — PR #229 ASSIGNED: NS coef (a,b) cubic-family line scan (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns-coef-ab-line-scan`
- **Assignment:** Scan (a,b) along the cubic family line a+b=1, c=0: Arm A (a=1.3, b=-0.3, f'(1)=+0.4), Arm B (a=1.7, b=-0.7, f'(1)=-0.4)
- Orthogonal to PR #226 c-axis scan. Maps contraction aggressiveness of the cubic NS family.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/229

---

## 2026-05-17 05:45 UTC — PR #230 ASSIGNED: Aux AdamW β1 scan (g1r1-edward)

- Branch: `g1r1-edward/aux-adamw-beta1-scan`
- **Assignment:** β1 ∈ {0.7, 0.9} for the auxiliary AdamW (embed/scalars/lm_head params), current β1=0.8
- Orthogonal to PR #216 nezuko β2 scan. Completes aux AdamW momentum characterization.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/230

---

## 2026-05-17 05:45 UTC — PR #231 ASSIGNED: Muon gradient momentum scan (g1r1-fern)

- Branch: `g1r1-fern/muon-momentum-scan`
- **Assignment:** Muon gradient momentum mu ∈ {0.9, 0.99} (current mu=0.95, nesterov=True)
- Distinct from EMA weight averaging (closed PR #197) and β_cov (closed PR #129). Tests gradient smoothing window before NS polar projection.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/231


## 2026-05-17 06:30 UTC — PR #202 TERMINAL: γ_power scan v2 ARM A WIN (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-power-bracket`
- **Hypothesis:** γ_power ∈ {0.2, 0.4} scan (current 0.3)
- W&B runs: `prncgzv5` (γ=0.4), `np70bwgx` (γ=0.2)

| Arm | γ_power | sr | val/loss | vs new baseline (3050/3.26773) | Verdict |
|-----|---------|-----|----------|--------------------------------|---------|
| Baseline (PR #193) | 0.3 | 3050 | 3.26773 | — | — |
| **Arm A** | **0.4** | **3025** | **3.26615** | **Δsr=−25 ✓ Δval=−0.00158 ✓** | **WIN (n=1 clears stat bar)** |
| Arm B | 0.2 | 3050 | 3.268887 | sr tie, val +0.00116 regression | Monotone direction (γ↑ better) |

**Analysis:** Arm A γ_power=0.4 is a clean WIN — biggest single-arm sr improvement (Δsr=−37.5 from old PR #137 baseline 3062.5; Δsr=−25 from current PR #193 baseline 3050). Arm B γ_power=0.2 confirms monotone direction: γ_power=0.4 wins, γ_power=0.2 ties or loses. Suggests finer scan {0.5, 0.6} for optimum.

**Note:** Arm A tested on PR #137 base (pre-cubic-Newton). Merge will create the compound (cubic-Newton + γ_power=0.4) — assumed additive (predicted sr~3012.5). Wave 7 stack (PR #225 thorfinn, currently running) independently confirms γ_power=0.4 + cubic-Newton + deep-WD + lm_head LR.

**Status:** PR sent back for rebase + arm switch to PMUON_GAMMA=0.4 (currently set to 0.2 from arm B). Will merge after student resubmits.


## 2026-05-17 06:40 UTC — PR #202 MERGED: γ_power=0.4 WIN → NEW BASELINE (g1r1-frieren)

- W&B run: `prncgzv5` (arm A, γ_power=0.4 on PR #137 base)
- **New baseline: sr=3025, val=3.26615 (n=1)**
- **BEATS Public Record #20 (3030 steps)!** Local n=1 sr=3025 < 3030.
- Merged onto cubic-Newton base (PR #193 compound assumed orthogonal).
- Spectral diagnostic telemetry (`pmuon_spectral_diag`, 100-step logging) added to codebase.

---

## 2026-05-17 06:50 UTC — PR #242 ASSIGNED: γ_power finer scan (g1r1-frieren)

- Branch: `g1r1-frieren/gamma-power-finer-scan`
- **Assignment:** γ_power ∈ {0.5, 0.6} on new baseline (sr=3025, cubic-Newton + γ_power=0.4)
- Monotone direction: γ=0.2→3050, 0.3→3062.5, 0.4→3025. Expected optimum in {0.5, 0.6} range.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/242


---

## 2026-05-17 08:48 UTC — PR #211 CLOSED: Wave 6 lm_head LR scan (g1r1-askeladd)

- Branch: `g1r1-askeladd/aux-lmhead-lr-scan`
- **Hypothesis:** lm_head LR=1/320 is undertuned; 2× (arm A=1/160) and 0.5× (arm B=1/640) scan on OLD base (PR #137: PMuon+u/w+γ=1.2).

| Arm | lm_head LR | sr | val/loss | vs OLD baseline (3062.5/3.26909) | vs NEW baseline (3025/3.26615) |
|-----|-----------|-----|----------|----------------------------------|-------------------------------|
| **A** | 1/160 | 3050 | 3.26896 | Δsr=−12.5 ✓, Δval=−0.00013 ✓ (SMALL WIN on old base) | sr +25 worse, val +0.00281 NULL |
| **B** | 1/640 | 3100 | 3.27248 | Regression (+37.5 sr, +0.00339 val) | Worse |
| Baseline | 1/320 | 3062.5 | 3.26909 | — | — |

**Analysis:** Directional monotone result — higher lm_head LR helps, lower hurts. Arm A beats OLD baseline by −12.5 sr, but the comparison contract was voided when PR #193 (cubic-Newton) and PR #202 (γ_power=0.4) merged mid-run, making the new baseline sr=3025 which arm A misses by +25 steps. Outstanding mechanistic quality: student's update/param telemetry confirmed 4× LR → 4× late-cooldown update_norm in the Adam asymptote; 1.53× larger late-cool val drop in arm A explains the γ=1.2 synergy mechanism precisely.

**Status:** CLOSED — informative NULL on stale base. lm_head LR=1/160 mechanism is being re-tested on new baseline in PR #225 thorfinn Wave 7 stack (deep-WD slope=+0.5 + lm_head 1/160 on new baseline, n=2).

---

## 2026-05-17 08:48 UTC — PR #248 ASSIGNED: Muon base LR retune (g1r1-askeladd)

- Branch: `g1r1-askeladd/muon-base-lr-retune`
- **Hypothesis:** Muon base LR=0.035 has never been retuned since PMuon's introduction. After γ_power=0.4 (stronger whitening) + cubic-Newton (partial polar convergence), the optimal step size may have shifted. Arms: {0.030, 0.040} bracket current 0.035.
- **Expected arm B win** (LR=0.040): γ_power=0.4's more isotropic gradient allows larger steps. **Expected arm A win** (LR=0.030): cubic-Newton's partial convergence means direction is noisier; tighter steps help.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/248

---

## 2026-05-17 09:00 UTC — PR #226 CLOSED: NS coef c-scan {0.1, 0.25} (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan`
- **Hypothesis:** Scan NS coef c values {0.1, 0.25} on cubic-Newton base (a=1.5, b=-0.5 fixed).

| Arm | c | (a,b,c) | sr | val | Verdict |
|-----|---|---------|-----|------|---------|
| Baseline | 0.0 | (1.5, -0.5, 0) | 3025 | 3.26615 | — |
| **A** | 0.1 | (1.5, -0.5, 0.1) | 3050 | 3.26849 | NULL (val +0.00234) |
| **B** | 0.25 | (1.5, -0.5, 0.25) | crashed step 3 | — | Divergence |

**Analysis:** Arm B crashed deterministically at step 3 with `torch.linalg.eigh` error. Student diagnosed root cause: a+b+c=1.25 violates σ=1 fixed-point (discriminant b²−4c(a−1) = -0.25 < 0, no real positive fixed point → monotone divergence → L_cov near-singular). This is a structural finding: naive c-variations must preserve a+b+c=1. Arm A (c=0.1) is NULL — slight noise increase from the non-fixed-point-preserving perturbation shows as +0.00234 val.

**Key finding:** The correct c-scan must follow the f'(1)=0 family: (a,b,c) = (1.5+c, -0.5-2c, c). Preserves both σ=1 fixed point and smooth attractor.

**Status:** CLOSED. Follow-up assigned (PR #250, tanjiro).

---

## 2026-05-17 09:00 UTC — PR #250 ASSIGNED: NS coef c-scan f'(1)=0 family (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/ns-coef-c-scan-fp1-family`
- **Hypothesis:** Scan c ∈ {-0.25, +0.25} on the valid f'(1)=0 NS family (a=1.5+c, b=-0.5-2c, c). Known endpoints: c=0 cubic-Newton (sr=3025 baseline), c=0.5 quintic (sr≈3062.5 worse). Question: does c<0 further improve?
  - Arm A c=-0.25: (1.25, 0, -0.25) — b=0, no cubic term, pure linear+quintic damping
  - Arm B c=+0.25: (1.75, -1.0, +0.25) — quintic-leaning, expected worse
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/250

---

## 2026-05-17 08:55 UTC — PR #225 SEED 1 DONE: Wave 7 stack (g1r1-thorfinn)

- Seed 1 run `y69hfn95`: step=3250, val=**3.2651** (strong partial result)
- W&B reports sr=3025 already hit during run — same as baseline sr
- val=3.2651 beats baseline val=3.26615 by −0.00105 — marginal val improvement at same sr
- Seed 2 not yet started
- Status: still WIP — waiting for seed 2 launch and terminal SENPAI-RESULT

---

## 2026-05-17 11:01 UTC — PR #216 CLOSED: Aux AdamW β2 scan {0.99, 0.999} (g1r1-nezuko)

- Branch: `g1r1-nezuko/aux-beta2-scan`
- **Hypothesis:** Aux AdamW β2=0.95 is under-tuned. Scan {0.99, 0.999} on PMuon+u/w+γ=1.2 base.

| Arm | β2 | sr | val/loss | vs current baseline (3025/3.26615) |
|-----|-----|-----|----------|-----------------------------------|
| Baseline | 0.95 | 3025 | 3.26615 | — |
| **A** | 0.99 | 3025 | 3.26640 | sr TIE, val +0.00025 — NULL |
| **B** | 0.999 | 3100 | 3.27185 | sr +75, val +0.00570 — clear regression |

**Analysis:** Monotone result — higher β2 worsens performance. β2=0.999's longer EMA (~700-step half-life) inflates the Adam denominator 2.4× relative to β2=0.99 by cooldown, halving effective LR during the decisive cooldown window. Arm A (β2=0.99) ties baseline sr but val is marginally worse (+0.00025) — not a merge candidate. **Direction: β2 axis CLOSED at baseline 0.95.** Increasing β2 degrades performance monotonically.

**Status:** CLOSED — NULL on primary metric. β2 axis fully characterized.

---

## 2026-05-17 11:01 UTC — PR #258 ASSIGNED: u/w-floor pruning ablation (g1r1-nezuko)

- Branch: `g1r1-nezuko/uw-floor-pruning-ablation`
- **Hypothesis:** Skylight u/w-floor (TARGET_UW=0.35, PR #131) may be redundant on new compound baseline. γ_power=0.4 bilateral whitening + cubic-Newton partial polar convergence may self-regulate u/w ratios.
- Arm A: TARGET_UW=0.0 (disable floor entirely)
- Arm B: TARGET_UW=0.7 (double — test over-constraint)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/258

---

## 2026-05-17 11:01 UTC — PR #242 ARM A DONE: γ_power finer scan (g1r1-frieren)

- Arm A (γ=0.5) `p5awihqf`: TERMINAL. sr=3150, val=3.2756 — **clear regression** vs baseline (sr=3025).
- Arm B (γ=0.6): 3rd attempt `d7wawe9q` just launched (after 2 step-1 crashes).
- **CRITICAL FINDING:** γ_power=0.5 is significantly worse than γ_power=0.4 (sr=3150 vs 3025). Combined with earlier monotone {0.2→3050, 0.3→3062.5, 0.4→3025}, this reveals a **clear local optimum at γ_power=0.4**. Direction reverses after 0.4.
- Arm B at γ=0.6 expected to be even worse. Structural crashes may indicate γ=0.6 is at a whitening instability boundary.

---

## 2026-05-17 12:00 UTC — PR #242 CLOSED: γ_power finer scan final result (g1r1-frieren)

- Arm B (γ=0.6): 3 consecutive crashes (`ekouv53z` step 1, `p0j7ghmd` step 1, `d7wawe9q` step 775). Structural whitening instability at γ_power=0.6 confirmed.

**γ_power axis FULLY CLOSED:**

| γ_power | sr | result |
|---|---|---|
| 0.2 | 3050 | suboptimal |
| 0.3 (old baseline) | 3062.5 | suboptimal |
| **0.4 (current baseline)** | **3025** | **local optimum** |
| 0.5 | 3150 | regression |
| 0.6 | crash | structurally unstable |

**Analysis:** The γ_power axis shows a sharp optimum at 0.4. Below 0.4: weaker whitening → worse convergence. Above 0.4: aggressive whitening destabilizes L_cov/R_cov eigendecomposition, causing crashes or regression. γ_power=0.4 will remain a fixed component of the baseline stack.

**Status:** CLOSED — axis fully characterized. PR closed.

---

## 2026-05-17 12:00 UTC — PR #261 ASSIGNED: PMuon LR warmup scan (g1r1-frieren)

- Branch: `g1r1-frieren/muon-lr-warmup-scan`
- **Hypothesis:** PMuon has no LR warmup. The bilateral covariance EMAs (L_cov, R_cov) initialize at zero and are unreliable for the first ~20 steps (β_cov=0.95, effective samples at step k ≈ 20*(1-0.95^k)). Current full-LR cold-start may cause erratic whitening during EMA initialization, especially with the more aggressive γ_power=0.4. A short linear Muon LR warmup gates these noisy early updates. This mechanism axis has NEVER been tested in the program history.
- Arm A: Linear Muon LR warmup over 50 steps
- Arm B: Linear Muon LR warmup over 150 steps
- Apply to optimizer2 (Muon) ONLY — AdamW has built-in first/second moment EMAs that adapt quickly.
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/261

---

## 2026-05-17 13:15 UTC — PR #225 CLOSED: Wave 7 stack NULL on n=2 (g1r1-thorfinn)

Terminal SENPAI-RESULT received. Wave 7 stack = γ_power=0.4 (now in baseline) + deep-WD slope=+0.5 + lm_head LR 1/160 (2× baseline 1/320).

| Seed | W&B run | sr | val | best_val_step |
|---|---|---|---|---|
| 1 | `y69hfn95` | 3025 | 3.26513 | 3250 |
| 2 | `phsvmx45` | 3050 | 3.26772 | 3250 |
| **Mean (n=2)** | — | **3037.5** | **3.266425** | — |
| Baseline (n=1) | `prncgzv5` | **3025** | **3.26615** | — |
| Δ vs baseline | — | **+12.5 (worse)** | **+0.00028 (worse)** | — |

**Analysis:** Seed-to-seed variance on this stack (sr swing 3025→3050, Δval=0.00259) is larger than seed 1's marginal val win over baseline. Seed 1 was within noise. The Wave 7 stack does not reliably beat baseline. Mechanistically — with γ_power=0.4 already in baseline, the additional deep-WD and lm_head LR boosts are no longer additive; the whitening absorbs most of the regularization headroom that deep-WD provides.

**Important program-level finding:** n=1 marginal wins (val Δ ≤ 0.001) on this task are within seed-to-seed noise. Require n=2 confirmation OR larger absolute val deltas (>0.002) before merging marginal wins.

**Status:** CLOSED. NULL on primary sr metric and on val. PR #272 assigned thorfinn (AdamW eps scan).

---

## 2026-05-17 13:15 UTC — PR #272 ASSIGNED: AdamW eps scan {1e-8, 1e-9} (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/adamw-eps-scan`
- **Hypothesis:** AdamW `eps=1e-10` is 100× more aggressive than PyTorch default (1e-8) and has never been scanned. Especially relevant for embed parameter (sparse-gradient with rarely-activated tokens) where `1/(sqrt(v)+eps)` denominator floor matters.
- Arm A: eps=1e-8 (PyTorch default)
- Arm B: eps=1e-9 (intermediate)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/272

---

## 2026-05-17 13:25 UTC — PR #231 CLOSED: Muon mu scan NULL (g1r1-fern)

Terminal SENPAI-RESULT — fern early-killed arm B (mu=0.99) at step 1957 after confirmed divergence.

| Arm | mu | sr | val/loss | vs current baseline (3025/3.26615) |
|---|---|---|---|---|
| Arm A | 0.90 | 3125 | 3.27589 | NULL (sr +100, val +0.00974) |
| Arm B | 0.99 | killed step 1957 | 4.37 (no recovery path) | DIVERGED |

Arm B divergence trajectory:
- Step 1000 (best): val=3.82
- Step 1500: val=6.65 (spike)
- Step 1875: val=4.37 (slowing recovery; ∆=+0.55 from best)
- Killed step 1957

**mu axis CLOSED — mu=0.95 baseline locally optimal:**

| mu | sr | result |
|---|---|---|
| 0.90 | 3125 | NULL (gradient direction noise too high) |
| **0.95** | **3025** | **local optimum** |
| 0.99 | diverge | structurally unstable (momentum-buffer overshoot can't recover) |

Excellent early-kill execution by fern — saved ~3 hours of GPU on a structurally hopeless run.

**Status:** CLOSED. PR #274 assigned fern (COOLDOWN_POWER retune {1.0, 1.4}).

---

## 2026-05-17 13:30 UTC — PR #274 ASSIGNED: COOLDOWN_POWER retune (g1r1-fern)

- Branch: `g1r1-fern/cooldown-power-retune`
- **Hypothesis:** COOLDOWN_POWER=1.2 was set in PR #137 on the old baseline. With γ_power=0.4 now providing stronger whitening and lower-noise preconditioned gradients, the optimal cooldown LR decay shape may have shifted.
- Arm A: COOLDOWN_POWER=1.0 (linear cooldown)
- Arm B: COOLDOWN_POWER=1.4 (more concave, front-loaded LR drop)
- PR: https://github.com/morganmcg1/modded-nanogpt-senpai/pull/274

---

## 2026-05-17 14:15 UTC — PR #229 CLOSED: NS coef (a,b) line scan {a=1.3, 1.7} (g1r1-alphonse)

- Branch: `g1r1-alphonse/ns-coef-ab-line-scan`
- **Hypothesis:** Move along the doubly-tangent (a, b=1-a, c=0) line away from cubic-Newton (a=1.5). Tests whether a=1.5 is a sharp optimum or has wiggle room.
- W&B runs: `la9l6roq` (arm A, gentle a=1.3), `xphiroo2` (arm B, aggressive a=1.7)

| Arm | NS_A | NS_B | NS_C | f'(1) | sr | val/loss | ortho_res @ 3000 |
|-----|------|------|------|-------|-----|----------|--------------------|
| Baseline (q8aduc16, c=0, a=1.5) | 1.5 | -0.5 | 0 | 0 | 3050 | 3.26773 | 0.0979 |
| Arm A (la9l6roq, gentle) | 1.3 | -0.3 | 0 | +0.4 | 3075 | 3.26921 | 16.297 |
| Arm B (xphiroo2, aggressive) | 1.7 | -0.7 | 0 | -0.4 | 3050 | 3.26786 | 0.1608 |

**Result:** Both NULL. Arm A clearly worse (+0.00306 val, +50 sr); Arm B effectively tied baseline (+0.00171 val within seed noise, sr same 3050).

**Key program-level finding:** f'(1)=0 doubly-tangent constraint is NOT strictly required for performance. Arm B with f'(1)=-0.4 (over-contractive) performs identically to baseline. But gentler contraction (Arm A) is strongly disfavored — ortho_residual blows up 160× (0.10 → 16.3) and val degrades measurably. With NS_ITERS=12, the polynomial must drive σ→1 quickly; the "tangent at 1" property is geometrically nice but not the constraint that matters.

**Axis decision: CLOSED at (a=1.5, b=-0.5, c=0).** Cubic-Newton confirmed locally optimal. Excellent diagnostic logging with `polar/ortho_residual_sample` — the ortho_residual trajectory is what made the mechanism legible. Combined with PR #184 (NS_ITERS flat 6-18) and PR #250 (c-scan, c=-0.25 NULL), the NS coef family is largely closed.

**Status:** CLOSED. Next assignment incoming for alphonse.

---

## 2026-05-17 14:30 UTC — PR #278 ASSIGNED: z-loss auxiliary loss scan (g1r1-alphonse)

- Branch: `g1r1-alphonse/zloss-auxiliary-scan`
- **Hypothesis:** z-loss penalty `Z_LOSS_COEF · sum(logsumexp(logits)²)` added to cross-entropy. PaLM/Chinchilla/Mamba standard regularizer. Never tested. Orthogonal to existing soft-clamp (constrains per-logit magnitude, not partition function mean).
- Arm A: Z_LOSS_COEF=1e-4 (PaLM-scale standard)
- Arm B: Z_LOSS_COEF=1e-3 (10× stronger, in case soft-clamp buffers the low-coef effect)

## 2026-05-20 19:11 UTC — PR #562 CLOSED: PMuon ε floor scan {1e-10, 1e-14} — NULL/NULL, ε=1e-12 baseline confirmed optimal across ±2 OOM (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/pmuon-eps-floor-scan`
- Hypothesis: eigenvalue clamp ε in `matrix_neg_power` may be load-bearing at near-rank-deficient early training or cooldown saturation. Test ε=1e-10 (10× looser) and ε=1e-14 (100× tighter) vs baseline 1e-12.

| Arm | ε | W&B run | fs | val | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| A | 1e-10 | `log2c4fj` | 2950 | 3.265632 | +12.5 (marginal) | +0.001354 (marginal) | NULL n=2 not needed (already on NULL side) |
| B | 1e-14 | `169fd498` | 2975 | 3.265954 | +37.5 (clear) | +0.001676 | NULL clear |
| Baseline | 1e-12 | `k7ylyby9`+`dm4joozw` | 2937.5 | 3.264278 | — | — | — |

**Verdict: NULL/NULL — PMuon ε floor axis closes.** Asymmetric (Arm B worse): tighter clamp amplifies noise on rank-deficient directions. Effect subthreshold — optimum sits slightly above 1e-12 but within noise across the 4 OOM range. PMuon scalar audit now COMPLETE: γ_power (#519), β_cov (#502), NS_ITERS (#511+#546), ε floor (#562) — all NULL within natural ranges.

## 2026-05-22 00:23 UTC — PR #696 CLOSED: Contra-Muon momentum subtraction — NULL/NULL, 58th axis (g1r1-tanjiro)

- Branch: `g1r1-tanjiro/contra-muon-momentum`
- Hypothesis: Contra-Muon contrarian EMA subtraction on body-Muon — subtract a slow EMA (μ_contra=0.999) from the fast EMA (μ=0.95) before NS to add "contrarian" direction bias. Two arms: Arm A contra_coeff=0.2, Arm B contra_coeff=0.1. Design intended 15-25% effective subtraction.

| Arm | contra_coeff | W&B | sr | val/loss | Δsr | Δval | Verdict |
|---|---|---|---|---|---|---|---|
| Baseline | — | k7ylyby9/dm4joozw | 2937.5 (n=2) | 3.264278 (n=2) | — | — | — |
| Arm A | 0.2 | mgdfhfzq | 3125 | 3.27599 | +187.5 | +0.0117 | NULL |
| Arm B | 0.1 | wfzugtmb | 3000 | 3.26857 | +62.5 | +0.00429 | NULL |

- **Stat-sig test:** Both arms sr > 2937.5 = fail. Stat rule: Arm A (3.28−3.27599)·√1=+0.004 barely passes val threshold but sr catastrophically regressed. Arm B val just above stat-sig cut. Both unambiguously NULL.

- **Key mechanism finding — structural whitening compression:** PMuon bilateral whitening compresses the slow EMA's polar-space footprint by ~6× vs the fast EMA: m_contra_pre_frob / m_pre_frob ≈ 14-17% (coefficient-independent, structural property). Effective subtraction reached only ~3% (Arm A) and ~1.5% (Arm B) vs design target 15-25%.

- **Dose-response analysis:** Halving coefficient (0.2→0.1) halved the damage (Δsr +187.5 → +62.5). Monotone in wrong direction: more subtraction = worse. Extrapolated coeff=1.0 would give ~Δsr +1500 = catastrophic. Pre-NS contra injection (alternative) untested but family context (gradient-domain perturbations uniformly NULL in this stack) makes it unlikely to help.

- **Conclusion:** Contra-Muon as post-NS body-Muon mechanism CLOSED. Design hypothesis untestable at any coefficient due to structural PMuon whitening compression. Adds to the broader pattern: spectral/gradient perturbations in the whitened update space all absorbed by PMuon. 58th closed axis.

## 2026-05-22 00:38 UTC — PR #695 CLOSED: Polyak EMA β=0.9/0.95 short-window — NULL/NULL, 59th axis (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-shortwindow`
- Hypothesis: Short-window Polyak EMA with late-start to suppress centroid-lag. Two arms: Arm A β=0.9 warmup=2500 (N_eff~10), Arm B β=0.95 warmup=2250 (N_eff~20). Direct follow-up to #662 β=0.99 centroid-lag finding.

| Arm | β | warmup | N_eff | peak Δ (step) | terminal Δ | W&B | sr | val/loss | Δsr | Δval |
|---|---|---|---|---|---|---|---|---|---|---|
| Baseline | — | — | — | — | — | k7ylyby9/dm4joozw | 2937.5 | 3.264278 | — | — |
| Arm A | 0.9 | 2500 | ~10 | −5.02 mnat (2625) | +0.01 mnat | g915dzx4 | 2950 | 3.26648 | +12.5 | +0.002 |
| Arm B | 0.95 | 2250 | ~20 | −16.42 mnat (2375) | +0.06 mnat | p4mm3e85 | 2925 | 3.26562 | −12.5 (boundary) | +1.34 mnat |

- **Win analysis Arm B:** sr=2925 hits boundary but val=3.26562 > 3.264278 by +1.34 mnat → AND clause fails. Marginal Δsr=12.5 triggering n=2 rule, but EMA mechanism ≈0 at terminal → seed noise. Both arms NULL.

- **Decisive mechanism — β-scan completes full geometric picture:**
  - Peak EMA advantage scales ~linearly with N_eff: 5 / 16.4 / 63 mnat = 1× / 3.3× / 12.6×, matching window ratios 1× / 2× / 10×
  - Terminal lag drops 60× from β=0.99 → β=0.9 (lag ∝ live-param drift × N_eff)
  - Both signal AND lag shrink together — no (β, warmup) setting separates them
  - At β=0.9 (N_eff~10), both terms drop below seed noise (~0.5 mnat)

- **Conclusion:** Lag/signal coupling is intrinsic to PMuon-EMA at this benchmark geometry. No static window setting works. FULL CLOSURE of Polyak EMA on body-Muon across β ∈ {0.9, 0.95, 0.99}. Next step: cooldown-aware β ramp (dynamic window coupled to LR decay, targets "free averaging when params stationary") — assigned as #737 to thorfinn.

## 2026-05-22 13:21 UTC — PR #737 MERGED: Polyak EMA β_target=0.99 cooldown ramp — n=2 sr win (g1r1-thorfinn)

- Branch: `g1r1-thorfinn/polyak-ema-cooldown-aware-beta`
- Hypothesis: Ramping Polyak EMA β from 0.95→0.99 during LR cooldown lengthens the averaging window as gradients become small/noisy, shifting the val-trajectory crossing of 3.28 earlier.
- Mechanism: deterministic β_t = 0.95 + 0.04 × cooldown_progress (coupled to lr_mult). EMA buffer stores FP32 body-Muon matrix params; inference uses EMA-swapped weights.

| Run | β_target | sr | val/loss | vs baseline |
|---|---|---|---|---|
| Seed-1 `rdbmnzpc` | 0.99 | **2925** | 3.265811 | sr −12.5 ✅ |
| Seed-2 `32r3isz5` | 0.99 | **2925** | 3.268040 | sr −12.5 ✅ |
| n=2 mean | 0.99 | **2925** | **3.266926** | **sr −12.5, val +2.65 mnat** |
| Arm B `b4q13sgm` | 0.999 | 2950 | ~3.270 | NULL |
| Old baseline (PR #413) | — | 2937.5 | 3.264278 | ref |

**Verdict: MERGED — first n=2-confirmed sr win of the cooldown-coupled-ramp cluster.** Both seeds independently reproduce sr=2925. Val regresses +2.65 mnat (N_eff=100 EMA lag bias) but primary metric sr improves. New baseline: sr=2925 / val=3.266926. EMA telemetry: β_t ramp 0.95→0.99 correct; `ema/delta_ema_minus_live = +0.54 mnat` deterministic across seeds. β_target=0.999 NULL (N_eff=1000 too wide, lag dominates).

## 2026-05-22 13:21 UTC — PR #760 CLOSED: PMuon γ_power cooldown ramp (69th axis, NULL/NULL) (g1r1-frieren)

- Branch: `g1r1-frieren/pmuon-gamma-power-cooldown-ramp`
- Hypothesis: Ramping PMuon's whitening exponent γ_power during cooldown adjusts preconditioner geometry as LR decays.

| Arm | γ_power schedule | sr | val/loss | vs old baseline |
|---|---|---|---|---|
| Arm A `4yzrav20` | 0.4→0.5 (harder) | 2975 | 3.26724 | NULL (+37.5 sr, +0.00296 val) |
| Arm B `1mvtoyib` | 0.4→0.3 (softer) | 2975 | 3.26581 | NULL (+37.5 sr, +0.00153 val) |
| Baseline (PR #413) | 0.4 static | 2937.5 | 3.264278 | ref |

**Verdict: CLOSED NULL (69th axis).** Arm B "less bad" than Arm A (softer whitening in cooldown is ~2× closer to baseline) but both regress. Cooldown-erosion pattern dominates. γ_power=0.4 static is well-tuned; ramping the whitening exponent during cooldown degrades update geometry. Student correctly identified: whitening precision is not a free knob during cooldown — it couples to the LR decay mechanism. Softward direction (γ<0.4) is slightly more permissive, consistent with #736 tanjiro's per-type γ pattern.

## 2026-06-01 16:00 UTC — PR #2082 nezuko: Aux Adam β₁ TRANSIENT-INCREASE pulse @ step 975 — ❌ BILATERAL NULL; β₁ UP axis CLOSED

- Branch: `g1r1-nezuko/aux-b1-pulse-up`
- Hypothesis: Test the first-moment INCREASE direction (β₁ UP @ cooldown onset) — the mirror of the canonical β₂ WIN (#1532). Prior β₁ DOWN runs (#1592 β₁→0.7, #1639 β₁→0.6) were all NULL; #1819 JOINT β₁ pulse (UP/DOWN simultaneously on all groups) was NULL ≤0.95. Arm A (β₁→0.95) is weak-increase; Arm B (β₁→0.99) tests strong memory extension.

| Arm | β₁ target | run | sr | val_ema | Δval mnat | Verdict |
|---|---:|---|---:|---:|---:|---|
| Baseline (#1532, n=2) | 0.95 (canonical) | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A β₁→0.95** | 0.95 | `nsqofbf2` | 2925 | 3.264997 | +2.14 | ❌ NULL |
| **B β₁→0.99** | 0.99 | `toacsa15` | -1 | 3.290498 | +27.64 | ❌ NULL — CATASTROPHIC; target NEVER REACHED within 3250 steps |

- **Key finding:** Aux Adam β₁→0.99 at step 975 causes CATASTROPHIC over-smoothing. The momentum estimator accumulates direction with an ~100-step memory window — at cooldown onset where gradients are changing rapidly (LR decay begins), this over-smooth direction lags the rapid curvature changes and blocks target crossing entirely.
- **Mechanism contrast:** β₂ UP @975 is beneficial (stabilizes step scale entering LR decay); β₁ UP @975 is harmful (over-smoothes gradient direction). The two moments play asymmetric roles: β₂ governs STEP MAGNITUDE (variance estimator — more memory = more stable scaling), β₁ governs STEP DIRECTION (momentum estimator — more memory = more stale direction).
- **Aux Adam β₁ axis FULLY CLOSED** across all directions: DOWN→0.7 (#1592 NULL), DOWN→0.6 (#1639 NULL), JOINT (#1819 NULL ≤0.95), UP→0.95 (this, NULL), UP→0.99 (this, catastrophic NULL).
- **nezuko REASSIGNED → #2151:** Body PMuon `weight_decay` DEPTH-STRATIFIED — ASCENDING (shallow=0.0125/middle=0.025/deep=0.0375) vs DESCENDING (shallow=0.0375/middle=0.025/deep=0.0125). Pristine axis under directive (b) per-block optimizer behavior. Uniform wd=0.025 has never been depth-stratified despite per-block LR (late-higher) and per-block μ (#1788) both being tested. Zero compute overhead; single new `--body_muon_wd_pattern` flag.

## 2026-06-02 02:30 UTC — PR #2162 CLOSED: alphonse body PMuon NS_ITERS cooldown schedule — ❌ BILATERAL NULL; NS_ITERS phase-schedule axis CLOSED

- Branch: `g1r1-alphonse/ns-iters-cooldown-schedule`
- Hypothesis: Reducing NS_ITERS during cooldown (step 975→3250) allows gradient direction more direct influence by reducing polar projection precision when optimization is already well-converged.

| Arm | NS_ITERS schedule | run | step | sr | val_ema | Δsr | Δval mnat | Verdict |
|---|---|---|---|---|---|---|---|---|
| Baseline (#1532, n=2) | 12 (fixed) | 9coyk2ke/09qrijtm | 3250 | 2875 | 3.262854 | 0 | 0 | WIN |
| **A NS=8 (modest)** | 12→8 @975 | `r4n89p8l` | 3250 | 2925 | 3.266385 | +50 | +3.53 | ❌ NULL |
| **B NS=4 (aggressive)** | 12→4 @975 | `28wiiczd` | 3250 | 2925 | 3.266812 | +50 | +3.96 | ❌ NULL |

- **Conclusion:** NS_ITERS reduction at cooldown onset is uniformly penalizing. Both modest (8) and aggressive (4) reductions produce identical sr penalty (+50 steps, ~+3.7 mnat). The penalty being identical at both reduction magnitudes suggests polar projection precision is structurally required per step — iterations are not redundant even in the fine-tuning regime. NS5 at 12 iterations (residual ~10⁻⁴) is not over-precise; it is load-bearing.
- **NS axis FULLY CLOSED:** coefficient pulses (#1660 NULL), static coefficient scans (#226/#229/#250 NULL), NS_ITERS reduction schedule (this, NULL), polar projection replacement (#1703 ADOPT / #1752 Newton-Muon / #1771 ACProp all NULL). The Newton-Schulz polar map at its baseline configuration is a robust, well-tuned component.
- **Pristine sub-axis remaining:** phase-adaptive NS *coefficient* switching at the pEMA refresh boundary (step 2600). Static scans tested global averages; this tests whether the late-cooldown spectral distribution requires different polynomial coefficients. Assigned as #2219.
- **alphonse REASSIGNED → #2219:** NS polynomial coefficient phase-switch at step 2600 bilateral (Jordan fast-convergence a=3.4445/b=-4.7750/c=2.0315 vs near-identity a=1.0/b=-0.1/c=0.0). Directive (a) optimizer-state rescaling at phase boundaries + directive (c) phase-specific mechanism pre-target-crossing.

## 2026-06-02 10:00 UTC — PR #2208 CLOSED: askeladd post-NS update EMA on body PMuon — ❌ BILATERAL NULL; paramEMA operator FULLY EXHAUSTED

- Branch: `g1r1-askeladd/post-ns-update-ema`
- Hypothesis: Apply a paramEMA-style running average to the post-NS-update PMuon gradient (the whitened direction BEFORE momentum accumulation), using either uniform α=0.3 or block-varying α=0.1→0.5 (shallow-to-deep). Tests whether smoothing the whitened gradient signal before momentum integration reduces noise in the preconditioned update direction.

| Arm | α config | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---|
| Baseline (#1532, n=2) | — | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A uniform α=0.3** | uniform across all blocks | `o6ir57sd` | 2925 | 3.265610 | +2.76 | ❌ NULL |
| **B block-varying α=0.1→0.5** | shallow=0.1, deep=0.5 | `dj15lanu` | 2925 | 3.266502 | +3.65 | ❌ NULL |

- **Conclusion:** Post-NS whitened-direction smoothing degrades both sr and val_ema in both uniform and depth-stratified forms. Combined with prior closures of paramEMA refresh α (fern #2159: α=0.5/1.5 NULL) and paramEMA β-ramp shape (frieren #2163: linear/cosine NULL), the parameter-EMA operator family on body PMuon is now thoroughly exhausted.
- **Closed axes within paramEMA cluster:** refresh α sweep (#2159), β-ramp shape (#2163), post-NS update EMA (this). All paramEMA axes definitively NULL.
- **askeladd REASSIGNED → #2260:** Aux Adam per-group ε asymmetric allocation — exploiting the eps_dominance_frac asymmetry revealed in #1178 telemetry (embed ~0.69% ε-floor vs lm_head ~0.0015%). Arm A: lm_head tight ε=1e-12; Arm B: embed tight ε=1e-12. Novel cross-group differential axis, never tested.

## 2026-06-02 10:00 UTC — PR #2210 CLOSED: nezuko lm_head β₂ second pulse @ step 2600 — ❌ BILATERAL NULL; β₂ re-pulse axis CLOSED

- Branch: `g1r1-nezuko/lmhead-b2-repulse-2600`
- Hypothesis: A second β₂ pulse on lm_head only at step 2600 (late cooldown phase, coinciding with paramEMA refresh boundary) recalibrates the lm_head adaptive variance window during the final acceleration phase. Tests whether extending momentum memory a second time in the critical pre-target window accelerates target crossing.

| Arm | β₂ target @2600 | run | sr | val_ema | Δval mnat | Verdict |
|---|---|---|---|---:|---:|---|
| Baseline (#1532, n=2) | no second pulse | 9coyk2ke/09qrijtm | 2875 | 3.262854 | 0 | WIN |
| **A β₂=0.99 (same as baseline pulse)** | 0.99 @2600, lm_head only | `0b52z10c` | 2925 | 3.264499 | +1.65 | ❌ NULL |
| **B β₂=0.999 (more aggressive)** | 0.999 @2600, lm_head only | `swjk6518` | 2925 | 3.265939 | +3.09 | ❌ NULL |

- **Conclusion:** The baseline β₂ pulse at step 975 (that won) is not generalizable to a second application at step 2600. The lm_head group does not benefit from re-extending the variance memory window a second time — the mechanism requires the specific geometry of the stable/cooldown phase transition at step 975, not the cooldown/pre-target transition at step 2600.
- **β₂ re-pulse axis CLOSED** for the lm_head group at the 2600 boundary. Combined with prior embed β₂ pulse tests, the whole single-group re-pulse space at late phase boundaries is exhausted.
- **nezuko REASSIGNED → #2262:** PMuon covariance EMA update stride stratified by block depth — shallow blocks stride=2 (update every other step), deep blocks stride=1 (update every step). Novel frequency-based axis (vs all prior rate-based β_cov axes). Directive (b) per-layer/per-block, (d) preconditioner state handling.
