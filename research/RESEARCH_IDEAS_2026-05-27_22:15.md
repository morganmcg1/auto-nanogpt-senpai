# Research Ideas — 2026-05-27 22:15

Generated from analysis of 279 PRs (18 merged, 216 ran). Current best: PR #1429, val_ema=3.263938, sr=2900.

In-flight (do not duplicate): PR #1475 (Muon m reset @ 2600), #1458 (pEMA β_target scan), #1459 (pEMA step LATE), #1457 (pEMA step ablation), #1456 (Muon μ pulse), #1445 (Muon WD pulse).

---

## Idea 1: Aux Adam m/v State Phase-Window Reset @ Step 2600

**Hypothesis**: Adam's m and v buffers for the aux params (embed, lm_head, scalars) carry stale momentum from the stable phase that conflicts with rapid cooldown descent. Zeroing or soft-resetting the Adam first-moment (m) and/or second-moment (v) at the cooldown boundary (step 2600) should free the aux params to follow the new loss landscape more aggressively, similar to how pEMA buffer zeroing unlocked 2900-step crossing.

**Mechanism rationale**: The pEMA-only refresh at step 2600 (PR #1429 WIN) works because the Polyak buffer had accumulated a stale weighted mean. The same logic extends to Adam's exponential moving averages — both m and v encode a "history" of the gradient distribution during stable phase, and zeroing them lets the optimizer treat the cooldown gradient sequence as a cold start with the current LR schedule. The v reset is especially potent: v² is the effective local learning rate denominator, and stale-large v suppresses step size during critical final-loss descent.

**CLI sketch**:
- Arm A: `--adam_reset_m_step 2600` (zero m only, keep v — safe warm restart)
- Arm B: `--adam_reset_mv_step 2600` (zero both m and v simultaneously)
- Arm C (optional): soft reset `--adam_scale_mv_step 2600 --adam_scale_mv_factor 0.1`
- Flag wires into the Adam group step loop: at the target step, multiply `exp_avg` by 0.0 (or factor) and `exp_avg_sq` by 0.0 (or factor)

**Why distinct from prior NULLs**:
- Aux Adam β2 phase-pulse (changing β2 transiently) = NULL. This is different: it does not change the decay rate, it erases accumulated history.
- Aux LR pulse (changing step magnitude) = NULL across all sub-axes. This changes effective step scaling indirectly (via v) without touching LR.
- pEMA refresh (PR #1429) is structurally identical but for a different buffer — provides direct analogy and prior WIN motivation.

**Risk**: Adam m-reset alone with unchanged LR may produce a transient loss spike if m flips direction. Mitigated by soft-reset variant (Arm C). v-reset alone may cause instability at high LR (v begins from zero, initial steps can be very large). Check: monitor `train/grad/rms` and `train/weight/rms` for spikes in the 2600-2615 window.

**Reward/novelty**: HIGH reward (direct analogy to PR #1429 WIN), HIGH novelty (never tried in this programme).

---

## Idea 2: Cooldown LR Shape — Cosine vs. Sigmoid vs. Two-Phase Step-Decay

**Hypothesis**: The current cooldown uses a power-law decay (`COOLDOWN_POWER=1.4`, concave). A cosine half-period or sigmoid-shaped decay concentrates learning-rate mass earlier in the cooldown (near step 2600) and decelerates faster near the end. This may allow the model to make larger corrective steps when the loss gradient is steepest and then stabilize before evaluation, hitting 3.28 at fewer steps.

**Mechanism rationale**: WSD schedules with different cooldown shapes are actively studied. The concave power-law front-loads high LR into the first portion of cooldown, but cosine front-loads even more aggressively while still smoothly reaching zero. A two-phase step decay (e.g., LR × 0.3 at step 2600, then × 0.1 at step 2900) is a simpler, empirically effective variant from classical NN training that has not been applied here. These shapes change the effective step-size budget distribution without changing total LR integral by much.

**CLI sketch**:
- Arm A: `--cooldown_shape cosine` — standard cosine half-period from lr_peak to 0
- Arm B: `--cooldown_shape sigmoid` — inverted sigmoid, parameterized by center and steepness
- Arm C: `--cooldown_shape two_phase --cooldown_phase1_frac 0.4 --cooldown_phase1_mult 0.3 --cooldown_phase2_mult 0.05`
- All arms keep `cooldown_frac=0.7` and same total steps.

**Why distinct from prior NULLs**:
- COOLDOWN_POWER variants (1.0, 1.4, 2.0) have been tried, but all are power-law monotone curves.
- No prior PR has tested cosine, sigmoid, or step-decay cooldown shapes for Muon.
- Shape change decouples from the per-block LR pattern and from phase-window pulses.

**Risk**: Medium. Cosine is the most conservative (well-tested in Adam), sigmoid shape has extra hyperparameters. Two-phase is the highest risk but most interpretable.

**Reward/novelty**: MEDIUM-HIGH reward (shape optimization is a live research area), HIGH novelty (untouched axis in this programme).

---

## Idea 3: Per-Block NS_ITERS — Late-Deeper Pattern (Block-Depth Stratification of Direction Precision)

**Hypothesis**: Applying more Newton-Schulz orthogonalization iterations to later (deeper) blocks, mirroring the winning `late-higher` per-block LR pattern, should improve the quality of the descent direction in blocks that matter most for final loss. Blocks near the output layer (block 11) see larger gradient signal and may benefit from more precisely orthogonalized updates.

**Mechanism rationale**: NS_ITERS controls how accurately the update direction approximates a true orthogonal matrix. The `late-higher` LR pattern WON because later blocks receive larger step-size multipliers. If step magnitude matters more for later blocks, so does direction quality — a larger step in an imprecise direction is worse than a larger step in a more accurate direction. The natural complement is to give later blocks NS_ITERS=14 or 16 and earlier blocks NS_ITERS=10, rather than applying always-on bilateral changes (which NULL'd). Unlike the always-on bilateral test, this test is about depth-stratified direction precision during the full training run, not a phase-window pulse.

**CLI sketch**:
- Arm A: `--block_ns_iters "10,10,10,10,10,10,11,12,13,14,14,14"` (late-higher gradient from 10 to 14)
- Arm B: `--block_ns_iters "14,13,12,11,10,10,10,10,10,10,10,10"` (early-higher, opposite direction as control)
- Baseline comparison: `--ns_iters 12` (uniform)

**Why distinct from prior NULLs**:
- Always-on bilateral NS_ITERS increase (12→14 uniform) = NULL (PR #1435).
- Always-on bilateral NS_ITERS decrease (12→10 uniform) = NULL (PR #1435).
- Per-block NS_ITERS shape has NEVER been tested. The NS_ITERS phase-window pulse also NULL'd (PR #1435), but that was uniform across all blocks. This is depth-stratified, always-on.

**Risk**: Medium. Increases compute slightly for later blocks. The LR analogy is strong but not guaranteed to generalize to direction precision. Per-block NS_ITERS requires code modification to the NS loop to accept block-indexed iters.

**Reward/novelty**: MEDIUM reward, HIGH novelty.

---

## Idea 4: Joint Multi-Buffer Reset at Step 2600 (pEMA + Muon m + Adam m, Staggered)

**Hypothesis**: PR #1429 showed that resetting pEMA @ 2600 wins. PR #1475 tests resetting Muon m @ 2600. These are designed to be orthogonal and complementary. A joint reset of both buffers simultaneously — or staggered by a few steps — should combine their individual benefits without mutual cancellation, producing a clean state transition at the cooldown boundary.

**Mechanism rationale**: At step 2600 (cooldown start), the model transitions from "stable exploration" to "aggressive descent toward target." Each optimizer buffer carries inertia from the stable phase: pEMA carries old weighted parameter states, Muon m carries old gradient directions, Adam m/v carry old auxiliary gradient history. Wiping all three simultaneously aligns the optimizer state with the new phase objective. Staggering by 5-10 steps avoids simultaneous gradient shocks.

**CLI sketch**:
- Arm A: `--paramema_refresh_only --paramema_refresh_step 2600 --muon_m_reset_step 2600 --adam_reset_m_step 2600` (all three simultaneously)
- Arm B: `--paramema_refresh_only --paramema_refresh_step 2600 --muon_m_reset_step 2605 --adam_reset_m_step 2610` (staggered by 5 steps)
- Baseline: just `--paramema_refresh_only --paramema_refresh_step 2600` (PR #1429 baseline)

**Why distinct from prior NULLs**:
- pEMA-only refresh = WIN (PR #1429).
- Muon m reset = in-flight (PR #1475), NEVER previously tested.
- Adam m reset = NEVER tested (Idea 1 above).
- Joint reset of all three simultaneously = NEVER tried anywhere in this programme.

**Risk**: HIGH — if any individual reset is harmful, the joint version will be confounded. Should run after PR #1475 and Idea 1 results are known. Staggered variant provides a safer path.

**Reward/novelty**: HIGHEST reward potential (compounds known WIN with two new mechanisms), HIGH novelty. But sequencing dependency on #1475 and Idea 1 results makes this best-run as Arm B after those PRs report.

---

## Idea 5: pEMA β Ramp Shape Variant (Concave vs. Convex Ramp During Cooldown)

**Hypothesis**: The pEMA β ramp during cooldown currently increases linearly from 0.97 to 0.99. A concave ramp (fast early rise to 0.99, then plateau) concentrates most of the Polyak weight on recent post-refresh parameters and should stabilize the eval average more quickly after the step-2600 reset. A convex ramp (slow early rise, fast finish) keeps the buffer lighter during early cooldown descent when the model is still moving fast.

**Mechanism rationale**: After the pEMA buffer is zeroed at step 2600, the β schedule governs how quickly the buffer re-stabilizes. A concave ramp reaching β=0.99 rapidly means the buffer is a "long-memory" average by step 2700, smoothing over early cooldown noise. A convex ramp keeps β low (≈0.97) until the model has nearly converged, then ramps to 0.99 for the final steps — this captures only the converged low-loss region. Neither shape has been tested; only the linear ramp and the β_target endpoint values are being varied (PR #1458 in flight).

**CLI sketch**:
- Arm A: `--ema_ramp_shape concave --ema_ramp_power 0.5` (fast early rise, beta = 0.97 + 0.02 * (frac^0.5))
- Arm B: `--ema_ramp_shape convex --ema_ramp_power 2.0` (slow early rise, beta = 0.97 + 0.02 * (frac^2.0))
- Baseline: linear ramp (current default, frac^1.0)

**Why distinct from prior NULLs**:
- PR #1458 (in flight) scans β_target endpoint values (0.985, 0.995) — this is ramp ENDPOINT, not ramp SHAPE.
- Per-block β differential and β_cov phase-pulse have been tried as always-on or bilateral — these are for the Muon momentum β, not pEMA.
- pEMA ramp shape has NEVER been tested.

**Risk**: Low — changes only the interpolation curve of an already-working mechanism (PR #1429). Implementation is a one-line change to the β schedule function. Should not interact badly with other in-flight PRs.

**Reward/novelty**: MEDIUM reward (incremental refinement of a known WIN), LOW-MEDIUM risk, MEDIUM novelty. Best run sequentially after PR #1458 to understand the endpoint sensitivity first.

---

## Idea 6: Warmup Shape Variation (Concave vs. Step Warmup)

**Hypothesis**: Warmup LR ramp is always linear in the current codebase (steps 0 to ~975). A concave warmup (fast early rise to full LR, plateau remaining warmup) may reach the productive LR region faster, effectively compressing the wasted early steps and extending the "stable phase" usable budget. A step warmup (immediate jump to 0.5× LR on step 1, then full LR on step 100) tests whether any smooth warmup is needed at all for Muon.

**Mechanism rationale**: Muon's Newton-Schulz orthogonalization makes the update direction approximately independent of gradient magnitude, which should reduce warmup sensitivity compared to Adam. If the true bottleneck is the number of steps spent at near-full LR in the stable phase, a concave warmup that reaches full LR by step 200 instead of step 975 adds ~775 "full-power" stable-phase steps at no extra cost. This is a free resource that has never been examined.

**CLI sketch**:
- Arm A: `--warmup_shape concave --warmup_power 0.5` (fast rise, reaches 95% of LR by step 200)
- Arm B: `--warmup_shape step --warmup_step_frac 0.03` (immediate 50% LR on step 1, full LR from step 100)
- Baseline: linear warmup (default)

**Why distinct from prior NULLs**:
- Warmup length variations (shorter/longer) may have been tried but warmup SHAPE has not been tested.
- The Muon NS mechanism makes warmup shape less critical than in Adam — this is a Muon-specific hypothesis.

**Risk**: Medium-low. A too-aggressive warmup can cause early training instability, which would be clearly visible as loss spikes in the first 200 steps. Early kill gates can catch this.

**Reward/novelty**: MEDIUM-LOW reward (unlikely to be as impactful as phase-boundary mechanisms), MEDIUM novelty, LOW cost (tiny change to schedule function).

---

## Idea 7: β_cov Phase-Window Pulse (Always-On Bilateral NULL → Phase-Windowed Test)

**Hypothesis**: The always-on bilateral per-block β_cov increase and decrease both NULL'd. However, transiently increasing β_cov (slower covariance EMA decay → heavier historical smoothing) ONLY during the phase window 2500-2924 may help PMuon's whitening be based on a more stable covariance estimate during the volatile cooldown descent, without paying the penalty of stale covariance during stable-phase exploration.

**Mechanism rationale**: In the stable phase, fast β_cov (high β = slow decay means MORE smoothing) is harmful because it tracks gradients too slowly. But during cooldown, the gradient distribution changes less dramatically (LR is dropping, updates are shrinking), so a more stable covariance estimate is better. The bilateral always-on null tells us the tradeoff is bad overall; a phase-windowed boost avoids the stable-phase downside. This is the same logic that motivated all the phase-window pulse experiments, but applied to the covariance EMA itself rather than the LR or momentum.

**CLI sketch**:
- Arm A: `--beta_cov_pulse_window "2500,2924" --beta_cov_pulse_value 0.99` (increase β_cov from 0.95 to 0.99 during window)
- Arm B: `--beta_cov_pulse_window "2500,2924" --beta_cov_pulse_value 0.85` (decrease β_cov from 0.95 to 0.85 during window, faster adaptation)

**Why distinct from prior NULLs**:
- Always-on bilateral β_cov increase = NULL.
- Always-on bilateral β_cov decrease = NULL.
- Phase-windowed β_cov pulse = NEVER TESTED.

**Risk**: Medium. β_cov controls the quality of the PMuon whitening preconditioner. An unstable preconditioner during cooldown could cause direction errors. However, the phase window means any damage is contained to 424 steps.

**Reward/novelty**: MEDIUM reward, MEDIUM novelty (analogous to the phase-window logic that motivated PR #1456/#1445 series, applied to a different always-on-bilateral-NULL axis).

---

## Idea 8: γ_power Phase-Window Pulse (Always-On Bilateral NULL → Phase-Windowed Test)

**Hypothesis**: Similar logic to Idea 7. The PMuon whitening exponent γ_power=0.4 (controls how aggressively the covariance is used: γ→0.5 approaches full Newton, γ→0 approaches pure Muon/Nesterov with no preconditioning). A phase-window increase toward 0.5 (more Newton-like) during cooldown 2500-2924 should improve the quality of the descent direction specifically when high-precision gradient geometry matters most.

**Mechanism rationale**: The bilateral always-on γ changes NULL because they hurt the stable phase (wrong geometry during exploration). Cooldown is different: the loss surface near a low-loss target is more quadratic, which is where Newton-style preconditioning pays off most. Increasing γ toward 0.5 only during cooldown captures Newton's advantage at the quadratic basin while avoiding its instability during chaotic stable-phase exploration.

**CLI sketch**:
- Arm A: `--gamma_power_pulse_window "2500,2924" --gamma_power_pulse_value 0.5` (full Newton during cooldown)
- Arm B: `--gamma_power_pulse_window "2500,2924" --gamma_power_pulse_value 0.35` (less aggressive, intermediate)
- Baseline: γ_power=0.4 throughout

**Why distinct from prior NULLs**:
- Always-on bilateral γ_power = NULL (per CURRENT_RESEARCH_STATE.md).
- Phase-windowed γ_power = NEVER TESTED.

**Risk**: Medium. γ_power affects whitening quality globally; a pulse could cause direction discontinuity at window entry/exit. Smooth interpolation at the window boundary (ramp over 50 steps) mitigates this.

**Reward/novelty**: MEDIUM reward, MEDIUM novelty.

---

## Idea 9: Aux Embed LR Independent Cooldown Schedule (Decoupled Cooldown Rate)

**Hypothesis**: The embed layer has LR=0.3 (much larger than body Muon lr=0.040). During cooldown, if embed LR decays at the same proportional rate as body LR, it may still be too large for the final convergence steps. Alternatively, it may be decaying too fast relative to what embeds need to fine-tune late representation alignment. Testing an independent embed cooldown schedule (decay slower or faster than the shared power-law) addresses this.

**Mechanism rationale**: Embed and lm_head are Adam-optimized aux params that have different loss-landscape curvature than the body. The standard LR ratio (embed: 0.3, body: 0.040) was tuned for the stable phase; there is no guarantee the optimal ratio at step 3200 is the same as at step 1000. Per-group cooldown decoupling is a natural generalization that is widely used in fine-tuning (LLRD — layer-wise learning rate decay) but has not been tried here for the cooldown period specifically.

**CLI sketch**:
- Arm A: `--embed_cooldown_mult 0.5` (embed LR decays at half the rate of body during cooldown, relative)
- Arm B: `--embed_cooldown_mult 2.0` (embed LR decays twice as fast, reaching near-zero earlier)
- Arm C: `--embed_cooldown_end_lr_ratio 0.01` (absolute minimum floor for embed LR at end of cooldown)

**Why distinct from prior NULLs**:
- "Per-optimizer class cooldown decoupling" is listed as NULL in CURRENT_RESEARCH_STATE.md. HOWEVER: this was likely tested as decoupling the body (Muon) cooldown from all aux (Adam) as a group. Testing just embed-specific cooldown rate as a second-order adjustment within the aux group is finer-grained.
- If the prior NULL was a body/aux coarse split, this is an intra-aux embed/lm_head split — a different axis.

**Risk**: Medium. If the prior NULL already tested embed-specific rates, this will also null. Need to check the exact PR that produced "per-optimizer class" NULL to confirm the granularity.

**Reward/novelty**: MEDIUM-LOW reward (may be a known-null axis at finer granularity), MEDIUM novelty. Recommend confirming prior null scope before running.

---

## Idea 10: NS Polynomial Coefficient Space — (a,b) ≠ Cubic-Newton, Non-Standard Fixed Points

**Hypothesis**: The Newton-Schulz polynomial is currently cubic: `p(x) = a·x + b·x³` with a=1.5, b=-0.5. This specific choice is the cubic polynomial with a fixed point at x=1 and derivative≈0 at x=1 (critical-point convergence). The polynomial space has other interesting points: a quintic (5th-order) that converges faster per iteration, or a linear-cubic hybrid with a different fixed-point structure. Changing (a,b) moves the convergence basin without increasing NS_ITERS cost.

**Mechanism rationale**: The cubic Newton-Schulz polynomial converges quadratically toward the sign/polar matrix. Different (a,b) pairs can achieve faster asymptotic convergence to the same fixed point, or slower convergence to a different fixed point. For NS_ITERS=12, the cubic is nearly exact, but a faster-converging polynomial could achieve the same accuracy at NS_ITERS=8, freeing 4 iterations of compute for other operations — or achieving better orthogonalization at the same NS_ITERS=12.

**CLI sketch**:
- Arm A: `--ns_poly_a 1.875 --ns_poly_b -0.875 --ns_poly_c 0.0` (higher-order cubic variant with steeper convergence)
- Arm B: `--ns_poly_a 1.5 --ns_poly_b -0.5 --ns_poly_c 0.0625` (add tiny c·x⁵ term for quintic acceleration at low cost)
- Baseline: a=1.5, b=-0.5, c=0.0

**Why distinct from prior NULLs**:
- Static NS_ITERS = {8, 16, 18} bilateral = NULL.
- NS_ITERS phase-window pulse = NULL (PR #1435).
- Adaptive NS (convergence detection) = NULL.
- NS coefficient (a,b) variation = NEVER TESTED directly (only specific quintic at low iters was tested; the standard (1.5, -0.5) space was never perturbed with NS_ITERS held constant at 12).

**Risk**: Medium. Wrong (a,b) can cause NS to diverge or converge to the wrong fixed point. Mathematical analysis of the specific (a,b) pairs should precede running.

**Reward/novelty**: MEDIUM reward, HIGH novelty, HIGH research interest (direct connection to spectral optimization literature).

---

## Idea 11: μP-Style Output-Layer Initialization Scaling for body Weights

**Hypothesis**: Maximal Update Parametrization (μP) prescribes that output weights should be initialized with variance ∝ 1/fan_in (scaled down relative to standard), with LR ∝ 1/fan_in for output layers. The current initialization uses a fixed scale. Applying μP-style output-weight scaling only (the cheapest μP intervention) may improve the gradient flow at initialization, allowing the optimizer to make more productive updates in the early stable phase.

**Mechanism rationale**: μP's theoretical advantage is alignment between the gradient scale and the optimizer's LR assignment, ensuring all layers update at similar effective speed. For Muon specifically, the NS orthogonalization normalizes the update direction but not the magnitude — the magnitude comes from the LR schedule. If body weight initialization is misscaled relative to the LR, early Muon steps may work with over- or under-scaled directions. A 0.5× or 2× initialization scale has been tried, but principled μP scaling (1/sqrt(fan_in) or 1/fan_in) has not.

**CLI sketch**:
- Arm A: `--init_scale mup_output` (apply μP 1/fan_in output weight scaling to transformer blocks)
- Arm B: `--init_scale mup_hidden` (apply μP 1/sqrt(fan_in) hidden weight scaling)
- Baseline: current initialization (fixed standard normal scale)

**Why distinct from prior NULLs**:
- 0.5× and 2× body init = tested (various PRs).
- Principled μP fan_in-dependent scaling = NEVER tested.
- This also naturally pairs with the LR scale for the body — could diagnose whether the current Muon LR=0.040 is in the right regime for the current init scale.

**Risk**: Medium-high. μP may require co-tuning of LR to be effective. Running without LR adjustment may confound the result. Recommend Arm C: `--init_scale mup_output --muon_lr 0.032` (scaled LR to match μP prescription).

**Reward/novelty**: MEDIUM reward, MEDIUM-HIGH novelty, HIGH research interest.

---

## Idea 12: Differential pEMA Buffer — Separate β for Body vs. Aux Params

**Hypothesis**: The current pEMA buffer uses a single shared β for all parameters (body Muon and aux Adam). Body params (trained by Muon's orthogonalized updates) converge along a different trajectory than aux params (trained by Adam). Giving the body a higher pEMA β (more smoothing over recent high-gradient movement) and aux a lower pEMA β (faster tracking of recent Adam updates) may produce a better eval-mode average.

**Mechanism rationale**: After the step-2600 reset, body params are still actively descending while aux params (especially embed) have likely nearly converged. A higher β for body provides more stable averaging over the last descent oscillations; a lower β for aux gives more weight to the final near-converged parameter values. This is a direct extension of the single-β mechanism that won in PR #1429, now differentiating by optimizer group.

**CLI sketch**:
- Arm A: `--ema_beta_body 0.99 --ema_beta_aux 0.97 --ema_warmup_steps 1750` (body heavier, aux lighter)
- Arm B: `--ema_beta_body 0.97 --ema_beta_aux 0.995 --ema_warmup_steps 1750` (aux heavier, body lighter)
- Baseline: shared β=0.97→0.99 for all params

**Why distinct from prior NULLs**:
- Per-block β differential (within body) = NULL.
- Body vs. aux differential pEMA β = NEVER TESTED (the distinction is at the optimizer-group level, not the block level).

**Risk**: Low-medium. Implementation requires splitting the pEMA buffer update by parameter group. One-parameter change with clear mechanism story.

**Reward/novelty**: MEDIUM reward, MEDIUM-HIGH novelty, LOW implementation risk.

---

## Idea 13: Stable-Phase Mid-Run LR Bump (Brief Transient Boost at Step ~1600)

**Hypothesis**: The stable phase (steps 975-2275) uses constant LR. A brief 20% LR increase for ~100 steps centered around the midpoint of stable training (step ~1600) may escape local attractor basins that form during the long flat LR period, similar to "warm restarts" (SGDR) or cyclical LR but as a single controlled pulse. This is opposite to the phase-window pulse approach (which adds energy during cooldown) — this adds energy during mid-stable exploration.

**Mechanism rationale**: Long flat LR periods can cause the optimizer to settle into a suboptimal basin that subsequent cooldown cannot escape. A brief LR bump in mid-stable re-energizes the search without the instability of a full restart. SGDR has strong empirical support in Adam settings; for Muon with NS orthogonalization (which dampens large gradient updates), a brief LR boost should be gentler than in Adam, making the stable-phase basin-escape more controlled.

**CLI sketch**:
- Arm A: `--stable_pulse_step 1600 --stable_pulse_width 100 --stable_pulse_mult 1.20`
- Arm B: `--stable_pulse_step 1600 --stable_pulse_width 200 --stable_pulse_mult 1.10`
- Baseline: constant stable-phase LR

**Why distinct from prior NULLs**:
- Phase-window pulses are all near end of training (2500-2924). This tests mid-stable (step 1600).
- SGDR-style warm restarts have not been tested in this programme.
- LR schedule during stable phase is assumed constant; this is the first violation of that assumption.

**Risk**: Medium. A poorly sized pulse could destabilize training permanently. Monitoring `train/loss` during steps 1600-1700 is essential. Early kill gate if loss spikes >5%.

**Reward/novelty**: MEDIUM reward, HIGH novelty.

---

## Idea 14: Gradient Clipping Adaptive to Running Gradient Norm

**Hypothesis**: The current gradient clipping is a fixed threshold. An adaptive threshold that tracks the running RMS of gradient norm (e.g., clip at 3× the running median) should preserve more signal during the volatile early-cooldown descent (when gradients are larger and informative) while still protecting against rare spikes.

**Mechanism rationale**: Fixed gradient clipping is conservative and symmetric — it clips early-training large-but-valid gradients the same as late-training instability spikes. An adaptive clipper that tracks the running norm and clips at a percentile boundary allows the model to take larger steps exactly when the landscape calls for them (early cooldown, large gradient toward target) and tighter steps during volatile instabilities. This is a known technique from robotics and meta-learning (adaptive gradient clipping in NFNets) that has not been applied here.

**CLI sketch**:
- Arm A: `--grad_clip_type adaptive --grad_clip_percentile 95 --grad_clip_window 100` (clip at 3× running 95th percentile of step-wise norms over last 100 steps)
- Arm B: `--grad_clip_type adaptive --grad_clip_mult 5.0` (clip at 5× running EMA of grad norm)
- Baseline: current fixed-threshold clipping

**Why distinct from prior NULLs**:
- Gradient noise / noise injection = NULL.
- Fixed gradient clipping variations (threshold changes) = likely tested.
- Adaptive gradient clipping (norm-tracking percentile) = NEVER tested in this programme.

**Risk**: Low-medium. Adaptive clipping can be miscalibrated if the warmup norm distribution is very different from stable. Warm up the window during the first 100 steps with the raw values before computing percentiles.

**Reward/novelty**: MEDIUM reward, HIGH novelty, MEDIUM research interest.

---

## Idea 15: Cooldown LR Floor (Non-Zero Minimum LR at Final Steps)

**Hypothesis**: The current cooldown decays LR to exactly 0.0 at the final step. A non-zero LR floor (e.g., `min_lr = 1e-4 × peak_lr`) during the final steps of cooldown prevents complete optimizer freeze and allows late micro-corrections during the pEMA averaging window. This is widely used in LLM pretraining (GPT-4, Llama) but has not been tested here.

**Mechanism rationale**: When LR reaches 0, all param updates stop completely — but the pEMA buffer continues averaging. If the model has not yet converged to its minimum, the frozen parameters that get averaged are already stale. A small LR floor keeps the model gently updating toward the loss basin while pEMA averages the descent, potentially reaching a slightly lower point. The interaction with pEMA refresh at step 2600 is interesting: post-refresh, the model with a non-zero LR floor continues micro-updating while pEMA re-accumulates.

**CLI sketch**:
- Arm A: `--min_lr_ratio 0.001` (LR never drops below 0.001 × peak LR ≈ 4e-5 for Muon)
- Arm B: `--min_lr_ratio 0.01` (slightly higher floor ≈ 4e-4 for Muon)
- Baseline: min_lr_ratio=0 (current default)

**Why distinct from prior NULLs**:
- Cooldown shape variants (power, cosine) all reach 0. This is about the floor, not the shape.
- LR schedules reviewed in prior PRs always reach 0 at terminal step.
- Non-zero LR floor specifically = NEVER TESTED.

**Risk**: Low. Conservative Arm A (0.001) is standard practice. Easy rollback. Main risk is that a floor that is too high interferes with pEMA averaging stability.

**Reward/novelty**: MEDIUM reward (well-motivated from external LLM practice), MEDIUM novelty, LOW implementation risk. Best first experiment to run (cheap, high-confidence prior from external literature).

---

## Priority Ranking (Expected Reward × Novelty)

| Rank | Idea | Reward | Novelty | Rationale |
|------|------|--------|---------|-----------|
| 1 | #1: Aux Adam m/v Reset @ 2600 | HIGH | HIGH | Direct analogy to PR #1429 WIN (pEMA reset). Most mechanistically grounded. |
| 2 | #4: Joint Multi-Buffer Reset | HIGHEST | HIGH | Compounds WINs, but sequencing dependency on #1475 + Idea 1. |
| 3 | #15: Cooldown LR Floor | MEDIUM-HIGH | MEDIUM | External LLM practice, low risk, untouched axis. |
| 4 | #2: Cooldown Shape (Cosine/Sigmoid/Step) | MEDIUM-HIGH | HIGH | Unexplored schedule axis, live research area. |
| 5 | #12: Differential pEMA β (Body vs. Aux) | MEDIUM | HIGH | Natural extension of WIN mechanism, low implementation risk. |
| 6 | #7: β_cov Phase-Window Pulse | MEDIUM | MEDIUM | Phase-window logic applied to always-on-null axis, testable cheaply. |
| 7 | #5: pEMA β Ramp Shape | MEDIUM | MEDIUM | Complements in-flight PR #1458, low risk. |
| 8 | #3: Per-Block NS_ITERS Late-Deeper | MEDIUM | HIGH | Novel depth-stratification, distinct from bilateral NS NULL. |
| 9 | #13: Stable-Phase Mid-Run LR Bump | MEDIUM | HIGH | SGDR-inspired, no prior attempt in this programme. |
| 10 | #8: γ_power Phase-Window Pulse | MEDIUM | MEDIUM | Same logic as Idea 7, slightly more complex. |
| 11 | #11: μP-Style Output Initialization | MEDIUM | MEDIUM | Well-motivated theoretically, requires LR co-tuning. |
| 12 | #10: NS Polynomial Coefficient Space | MEDIUM | HIGH | Mathematical clarity, distinct from prior NS NULLs. |
| 13 | #14: Adaptive Gradient Clipping | MEDIUM | HIGH | NFNet-proven technique, never tried here. |
| 14 | #6: Warmup Shape Variation | LOW-MEDIUM | MEDIUM | Low expected delta, but free to test. |
| 15 | #9: Aux Embed LR Independent Cooldown | LOW-MEDIUM | MEDIUM | May overlap prior null; needs scope confirmation. |
