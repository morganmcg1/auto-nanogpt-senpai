# RESEARCH IDEAS — 2026-06-09 18:30 UTC

**Generated at the 58-lever plateau.** The gap to close is ~0.0016 in n=4 mean val/loss at step 2825
(rank-1 = 3.277780 at step 2850; target for 2825 validity = n=4 mean ≤ 3.278000).

**Rank-1 stack (PR #2405, step=2850, n=4 mean=3.277780):**
NC (Cautious-Muon pre-NS5) × Sinkhorn Arbor × EMA-Nesterov (EN, γ=0.99) × RI (γ=−0.075, capture_step=2375) × AdamW eps=1e-12 × β₂ pulse (start=0.95 → target=0.995 @ step 820).

**Do NOT duplicate in-flight:** H-EZ, H-FA, H-FB, H-FD, H-FE (AMSGrad), H-EW, H-EX, H-EU.

**Do NOT re-propose falsified mechanisms:** H-FC (v-reset/warm-restart class), H-EY (amp=0.997), H-EM (amp=0.999), H-DJ/H-BU (Lookahead on any optimizer), H-EG continuous β₂ rule arms, H-DK ARBOR_CLAMP_K, H-DL EN_lookahead_stepsize, H-DM MUON_POWER_C, H-DR Soft-Muon CEIL, H-DH SWA-EMA, H-DI SOAP_BETA2, H-DP SOAP MLP+V, H-BL Embed-only LR ±50%, all previous wave H-DX through H-EE.

---

## Hypothesis H-FF — β₁ × β₂ JOINT PULSE (dual-moment coordinated reset)

**Mechanism:** The rank-1 stack pulses β₂ from 0.95 → 0.995 at step 820, widening the second-moment EMA window. An unexplored complementary lever is to SIMULTANEOUSLY narrow the first-moment EMA window (lower β₁) at the same step. This creates a coordinated "clarify direction, stabilize magnitude" moment: β₁ drop → first moment forgets stale directions faster; β₂ rise → denominator becomes more stable. The two effects are geometrically complementary in Adam: direction uncertainty is reduced by lower β₁ while magnitude noise is smoothed by higher β₂.

**Hypothesis:** Joint pulse β₁: 0.95 → 0.85 (for AdamW optimizer1 aux group) simultaneous with β₂: 0.95 → 0.995 at step 820 outperforms rank-1 by pushing 3/4 seeds to ≤ 3.277780 at step 2825.

**Implementation:**
- Base: rank-1 flags `--aux_b2_start 0.95 --aux_b2_target 0.995 --aux_b2_pulse_step 820`
- Add analogous β₁ pulse: `--aux_b1_start 0.95 --aux_b1_target 0.85 --aux_b1_pulse_step 820`
- Both pulses apply at the SAME step 820; β₁ reverts to default (or stays at 0.85) after the pulse
- Screen: β₁ target values {0.85, 0.80, 0.90} — run n=2 each at step 2850; pick best for n=4 confirm
- Only modify AdamW optimizer1 aux group (same group as β₂ pulse); leave Muon momentum unchanged
- Implementation: in the aux AdamW `step()` logic, add a parallel `beta1_t = beta1_schedule(step)` alongside existing `beta2_t` pulse schedule

**Decision gate:**
- n=2 mean at step 2850 ≤ 3.277780 → continue to n=4
- n=2 mean > 3.279000 → ABORT (β₁ perturbation destabilizes direction EMA)
- n=4 mean at step 2825 ≤ 3.278000 → WINNER (earliest official-valid step = 2825)

**Tier: 1** — Mechanistically sound extension of a confirmed active ingredient. Joint β₁/β₂ coordination in Adam is well-studied (Apollo, Adan, AdaFactor schedule literature). Falsifiable, cheap (same step count as rank-1, one additional flag), and the result sharpens understanding of WHICH moment drives rank-1's benefit regardless of outcome.

---

## Hypothesis H-FG — NS5 INPUT WHITENING via Gram-Schmidt pre-normalization

**Mechanism:** NS5 (5-iteration Schulz polynomial) receives raw momentum gradients as input. The quality of NS5 convergence depends on how close the input matrix is to the identity. Currently, NC (Cautious-Muon) applies per-row × per-col L2 normalization BEFORE NS5, which partially conditions the input. A stronger conditioner is to apply a single step of Gram-Schmidt orthogonalization to the momentum matrix before NS5: this directly pushes singular values toward 1, making NS5 start closer to its fixed point. This is different from MUD (H-DX) which replaces NS5 entirely — here NS5 is preserved but its input is better conditioned.

**Hypothesis:** Applying a lightweight (1-step) Gram-Schmidt pass on the Muon momentum matrix before NC pre-normalization → NS5, then discarding the GS output and letting NS5 run normally, reduces training loss by making NS5 converge faster within its 5 iterations, yielding a better approximation to true matrix orthogonalization and improving the final n=4 mean by ~0.0005.

**Implementation:**
- After accumulating the Muon momentum update (post-EN Nesterov step), apply 1-step QR (torch.linalg.qr) to get Q (orthogonal), then blend: `momentum_in = alpha * Q + (1-alpha) * momentum_raw`, with alpha swept in {0.2, 0.4, 0.6} — lower alpha = lighter conditioning
- This blended matrix then passes through NC → NS5 as normal
- NOTE: torch.linalg.qr is O(min(m,n)^2 * max(m,n)) — profile memory and wall time before full run; if too slow, try gram_schmidtify on only the first k singular directions
- Alternative lighter version: use only 1 power-iteration step (M ← M @ M.T @ M, renormalize) as a pre-conditioner — no QR needed
- Run Arm A: alpha=0.3 (light), Arm B: alpha=0.6 (strong) on 1-seed screens at 2890 steps

**Decision gate:**
- Either arm n=1 step 2890 ≤ 3.276000 → run n=4 with winning alpha
- Either arm n=1 step 2890 > 3.279000 → ABORT (GS conditioning is harming NS5 convergence)
- If wall time per step increases > 15% → investigate cheaper alternative (power-iter version)

**Tier: 2** — Plausible mechanism that targets a known suboptimality (NS5 convergence quality), grounded in numerical linear algebra. The 1-step QR pre-conditioner is well-studied in Krylov and orthogonal iterations literature. Connection to this codebase is indirect (NS5 is already working well), but the gap between NC pre-normalization and exact orthogonal initialization of NS5 is real and untested.

---

## Hypothesis H-FH — ADAPTIVE COOLDOWN FRACTION (val-loss-slope triggered)

**Mechanism:** The current cooldown fraction is fixed at `cooldown_frac=0.30` (cd_start ≈ step 1156/2023 depending on variant). However, the optimal cooldown length depends on whether the loss trajectory has plateaued: if the model is still descending steeply at cd_start, a longer cooldown wastes capacity; if it has flattened, a longer cooldown allows the LR to shepherd the weights into a sharper minimum. The training script already logs `train/slope/loss_per_step` — this telemetry can be used to SET the cooldown fraction adaptively based on measured loss slope at a fixed intermediate checkpoint (e.g., step 600).

**Hypothesis:** Triggering the LR cooldown at the measured inflection point (where train/slope crosses a threshold) rather than a fixed fraction yields an earlier first-step-to-target by ensuring the LR is still large enough to provide meaningful descent through step 2700.

**Implementation:**
- At step 600, log `train/slope/loss_per_step` (already computed)
- If slope magnitude ≤ threshold_steep (e.g., −0.0008/step), model is still descending fast → DELAY cooldown start by 150 steps (cd_start += 150)
- If slope magnitude ≥ threshold_flat (e.g., −0.0003/step), model has plateaued early → ADVANCE cooldown by 100 steps (cd_start −= 100)
- Screen threshold_steep and threshold_flat values: run 2 seeds each for {early, neutral, late} trigger cases
- Note: this is NOT val-loss peeking for cherry-picking (the schedule is determined mechanically by slope, not by comparing seeds) — it is a single per-run adaptive rule applied uniformly
- Benchmark contract: adaptive schedule determined by training-loss telemetry only, no external cherry-pick → COMPLIANT

**Decision gate:**
- n=2 mean with winning trigger thresholds at step 2825 ≤ 3.277172 → run n=4
- n=2 mean > 3.279000 → ABORT (adaptive trigger introduces variance / destabilizes)
- Inspect: do seeds show tighter or wider loss dispersion with adaptive vs fixed cd_start?

**Tier: 2** — Novel adaptive scheduling mechanism not tried in this stack. The observation that val/slope telemetry is already logged makes this cheap to implement. Risk: the adaptive rule may add seed variance (different trigger thresholds across seeds due to gradient noise at step 600). This is testable and would be revealed immediately in n=2 screens.

---

## Hypothesis H-FI — EMA-NESTEROV γ ANNEAL (γ: 0.99 → 0.95 during cooldown)

**Mechanism:** EMA-Nesterov (EN, γ=0.99) is the single largest contributor to the stack (Δ = −0.0028). It applies a Nesterov-style lookahead: the gradient step uses `momentum_corrected = γ * m_prev + (1-γ) * g_now`, which with γ=0.99 heavily weights the accumulated momentum direction. During cooldown (LR shrinking), the model is in fine-grained local descent — a shorter momentum horizon (lower γ) lets the model react to local geometry more accurately. This is analogous to momentum annealing in SGD (e.g., the 1cycle policy's momentum schedule).

**Hypothesis:** Annealing EN γ from 0.99 → 0.95 linearly over the cooldown phase (steps 1156→2890) improves final val/loss by ~0.0003 and allows step 2825 to pass n=4, by improving gradient alignment in the final descent phase.

**Implementation:**
- During steps < cd_start: γ = 0.99 (unchanged)
- During steps cd_start → total_steps: γ linearly interpolates from 0.99 to gamma_final
- Sweep gamma_final: {0.97, 0.95, 0.90} at n=2 each
- Implementation: `gamma_t = 0.99 - (0.99 - gamma_final) * max(0, (step - cd_start) / (total_steps - cd_start))`
- Only change γ in EN Nesterov step; leave all other EN parameters unchanged
- If gamma_final sweep shows non-monotone response, test higher γ values (0.995) too — the anneal direction might be reversed

**Decision gate:**
- n=2 mean with best gamma_final at step 2825 ≤ 3.277172 → run n=4
- n=2 mean > 3.279000 for all gamma_final values → ABORT (EN is robust to γ, not a live lever)
- If γ anneal hurts: confirms EN γ during plateau phase is critical → test γ anneal during WARMUP instead (H-FI-B variant)

**Tier: 2** — EN γ is confirmed active but has never been scheduled. The 1cycle momentum schedule analogy from SGD is strong. The cooldown phase is the most geometrically sensitive (LR shrinking), making this the most plausible time for a momentum adjustment to matter. Mechanism is specific and falsifiable in 2 seeds.

---

## Hypothesis H-FJ — AdamW eps ADAPTIVE SCHEDULE (eps: 1e-12 → 1e-10 during warmup, then reset)

**Mechanism:** AdamW eps=1e-12 (H-AY, Δ = −0.000021) tightens the normalization floor. However, the benefit of tight eps may be phase-dependent: during early training (steps 0–500), the second moment `v` is small and variable — tight eps reduces noise tolerance and may cause early instability. During late training (steps 1500+), `v` is large and stable — tight eps provides accurate normalization. An adaptive eps schedule: start at 1e-10 (looser), anneal to 1e-12 by step 820 (when β₂ pulse fires and v stabilizes), could get the best of both phases.

**Hypothesis:** Running eps: 1e-10 (steps 0–500) → 1e-12 (steps 500–820, linear interpolation in log-space) → 1e-12 (steps 820+) improves early stability and allows slightly more aggressive β₂ pulse, yielding n=4 mean at step 2825 ≤ 3.278000.

**Implementation:**
- AdamW `step()`: `eps_t = 10 ** (-10 + (-12 - -10) * min(1.0, max(0.0, (step - 500) / (820 - 500))))` 
- So: eps=1e-10 at step 0, linearly annealing to eps=1e-12 in log-space by step 820, then fixed at 1e-12
- Apply to ALL AdamW groups (embed, lm_head, scalars) — same as current fixed eps=1e-12 scope
- Optionally: also test eps annealing on the β₂ pulse group only (aux AdamW) and fixed 1e-12 elsewhere
- n=1 smoke screen at step 2890 to verify no early divergence

**Decision gate:**
- n=1 step 2890 ≤ 3.278000 (single-run threshold ≤ 3.276000) — first check
- n=2 mean step 2850 ≤ 3.277172 → run n=4 at step 2825
- If n=1 diverges in first 600 steps: ABORT immediately (eps annealing destabilizing early optimization)
- If n=4 mean improves by < 0.0001 → close (eps is already saturated; annealing adds complexity for noise)

**Tier: 2** — The eps-phase-dependency argument is real (documented in AdaFactor, Amos & Steinhardt 2020). However, eps=1e-12 fixed is already confirmed working; the adaptive version may not add signal over already-good eps tuning. Useful as a diagnostic: if it helps, eps matters early; if not, eps tuning is fully saturated.

---

## Hypothesis H-FK — STOCHASTIC WEIGHT AVERAGING (SWA) ON MUON ONLY, last 150 steps

**Mechanism:** Stochastic Weight Averaging (SWA) averages weight snapshots during the cooldown phase, pushing toward wider minima with better test generalization. Prior H-DH tested SWA-EMA globally and failed. The key question is whether MUON-side weight averaging in isolation is harmful: Muon applies orthogonal updates, and the average of two orthogonal weight configurations may lie in a better-shaped basin than either endpoint. The specific design here is to average only transformer block weights (Muon's domain), not embed/lm_head (AdamW's domain).

**Hypothesis:** Applying Polyak averaging (uniform snapshot averaging, not exponential) over the last 150 training steps exclusively on Muon-updated parameters (all `weight` params of attention + MLP blocks) improves n=4 mean by ~0.0003 at step 2850, without the instability that global SWA caused in H-DH.

**Implementation:**
- Maintain a shadow copy of Muon-param weights initialized at step cd_end − 150 = step 2740
- Every step from 2740 to 2890, accumulate: `shadow = shadow * (k-1)/k + param.data * 1/k`
- At evaluation (steps 2825/2850/2875/2890), temporarily swap to shadow weights for val loss computation, then restore
- This is an EVAL-ONLY modification — training continues normally with live weights
- Key difference from H-DH: NO exponential moving average, pure Polyak; NO global application, Muon params only
- Benchmark contract: does NOT change optimizer updates or add fwd/bwd passes — COMPLIANT

**Decision gate:**
- n=1 screen: compare val/loss at steps 2825/2850/2875/2890 with and without shadow weights
- If shadow improves ANY eval step by > 0.0002 → run n=4
- If shadow DEGRADES any eval step: ABORT (Muon-SWA is also harmful)
- If shadow improves final-2890 but not 2825/2850 → adjust window start (try 2640 for 250-step window)

**Tier: 2** — SWA on orthogonal-update weights is mechanistically different from standard SWA. H-DH's global failure may have been driven by embed/lm_head averaging (AdamW domain, which uses scale-dependent updates incompatible with uniform averaging). Muon-only averaging is a cleaner test. Well-studied in the SWA literature (Izmailov et al. 2018, Kaddour et al. 2022). Requires eval-only modification — low implementation risk.

---

## Hypothesis H-FL — NS5 COEFFICIENT TUNE via LANDSCAPE-SPECIFIC POLYNOMIAL FIT

**Mechanism:** The NS5 polynomial coefficients (3.4445, −4.7750, 2.0315) were derived for general matrix approximation in the Schulz iteration. Our gradient matrices have a specific spectral distribution (shaped by our architecture, batch size, and FineWeb data). Offline fitting the 5th-degree polynomial coefficients to minimize `|f(M) - M^{-1/2}|` on a sample of actual Muon gradient matrices from mid-training (steps 400–800) may yield coefficients that converge faster on our specific input distribution, providing better NS5 approximation quality within the same 5 iterations.

**Hypothesis:** Replacing the fixed NS5 coefficients with distribution-specific coefficients fit on 100 actual Muon gradient samples from a single reference run improves Muon update quality, reducing n=4 mean val/loss by ~0.0003 at step 2850.

**Implementation:**
- Phase 1 (offline, run once): run a single full training run, log Muon gradient matrices at steps 400, 500, 600, 700, 800 (pre-NS5 input matrices). Extract ~20 matrices per step = 100 samples.
- Phase 2 (fit): for each sample matrix M, compute M^{-1/2} via SVD (ground truth), then fit 5 polynomial coefficients c₁..c₅ to minimize `||c₅M^5 + c₄M^4 + c₃M^3 + c₂M^2 + c₁M - M^{-1/2}||_F²` via least squares
- Phase 3 (test): hardcode the fitted coefficients into the training script and run n=4
- Implementation note: the spectral distribution of Muon gradient matrices at steps 400-800 (mid-training) is the most relevant, as this is when NS5 convergence quality matters most (early warmup gradients are noisy; late cooldown gradients are small)
- Add flags `--ns5_c1 ... --ns5_c5` to make this testable without code changes

**Decision gate:**
- Phase 2 output: fitted coefficients should have F-norm error on held-out matrices < current coefficients; if not, ABORT before Phase 3
- n=4 mean step 2850 improvement > 0.0002 → keep new coefficients; otherwise revert to default

**Tier: 2** — Principled tuning of the NS5 approximation. H-ED (IFNSO offline-optimized coefficients) was in a prior wave but never run. The specific implementation above is more targeted: using actual distribution samples from THIS training setup rather than a generic optimization, which makes the fitted coefficients more likely to generalize. Medium implementation complexity (Phase 1 logging is easy; Phase 2 fitting is offline).

---

## Hypothesis H-FM — NESTEROV LOOKAHEAD ON RI (Reference Interpolation pre-fetch)

**Mechanism:** Reference Interpolation (RI, γ=−0.075, capture_step=2375) is currently applied as a POST-training readout modification: at step 2375 the live weights are captured, and final weights are interpolated toward this captured anchor. This is applied at EVALUATION only. An alternative mechanism: apply a Nesterov-style "pre-fetch" step where, during the LAST 150 training steps (2740→2890), the gradient computation uses interpolated weights `θ_lookahead = θ_live + γ * (θ_anchor - θ_live)` instead of `θ_live`. This modifies the gradient landscape the optimizer sees in the final descent phase, potentially providing a better loss curvature estimate if the anchor direction correlates with the true minimum.

**Hypothesis:** Replacing the eval-only RI readout with a training-active Nesterov pre-fetch in the last 150 steps (applied only to grad computation, not to weight updates directly) improves final val/loss by ~0.0003 by providing better gradient information in the final phase.

**Implementation:**
- At step cd_end − 150 = step 2740: capture `θ_anchor = deepcopy(model.state_dict())` (Muon params only)
- During forward/backward for steps 2740→2890: before forward pass, compute `θ_lookahead = θ_live + gamma_ri * (θ_anchor - θ_live)` and swap to these for gradient computation only
- After backward: restore to `θ_live`, apply normal Muon + AdamW update to `θ_live`
- Evaluation at 2825/2850/2875/2890: still use original RI readout (or compare both: RI vs Nesterov-RI)
- gamma_ri sweep: {−0.10, −0.075, −0.05} — lower magnitude = lighter lookahead toward anchor
- Note: this adds 1 forward pass overhead (doubles wall-time for last 150 steps) — profile first; if > 2min overhead, implement in-place blend instead

**Decision gate:**
- n=1 screen with gamma=−0.075: val/loss at step 2890 ≤ 3.277000 (below current rank-1 final-2890) → run n=4
- If val/loss at step 2890 > 3.279000 → ABORT (Nesterov-RI perturbs the gradient too strongly)
- Compute cost: if forward pass overhead > 15% → test in-place blend variant (no extra memory copy)

**Tier: 3** — Mechanistically interesting but speculative. The captured anchor at step 2375 is a stable low-loss weight configuration; using it as a Nesterov pre-fetch point during final descent is conceptually sound (analogous to Lookahead optimizer, which was CATASTROPHIC globally, but here applied only to the RI anchor direction in the last 150 steps). Risk: this is close to the Lookahead mechanism that failed in H-DJ. Must be careful to apply only in LAST 150 steps and only in gradient computation (not as a full optimizer state change). Decision gate is strict.

---

## Public-Source Ports — KellerJordan PRs and Prime Intellect

### KellerJordan PR #307 (Contra-Muon removal + Aurora warmup extension)

**Summary:** PR #307 extended the Muon momentum warmup from 300 to 500 steps and removed Contra-Muon entirely. Currently H-DQ (nezuko) is testing Contra-Muon re-enablement. The complementary experiment is testing momentum warmup extension to 500 steps on our stack — not in-flight.

**Port hypothesis (H-FN, not assigned):** Extend Muon momentum warmup from 300 → 500 steps. Implementation: change the `muon_momentum_warmup` flag from 300 to 500 (or add a linear warmup schedule). Screen at n=2.

### KellerJordan PR #309 (Aurora + EMA-Nesterov baseline)

**Summary:** PR #309 introduced the Aurora LR schedule and EMA-Nesterov Muon momentum that our stack inherits. EN (γ=0.99) is already merged. No additional ports needed.

### KellerJordan PR #311 (Sinkhorn equilibration + Contra-Muon ramp)

**Summary:** Sinkhorn equilibration is already merged (Arbor). Contra-Muon ramp (linear 0→coeff over first 1000 steps) is the specific detail we have NOT tested. Currently H-DQ tests a fixed Contra-Muon coefficient. The ramp variant is different and worth testing if H-DQ returns negative.

### KellerJordan PR #318 (Muon momentum anneal during cooldown, not warmup)

**Summary:** PR #318 introduced momentum COOLDOWN — reducing Muon momentum γ during LR cooldown. This is mechanistically similar to H-FI (EN γ anneal) but applied to the base Muon momentum (β parameter), not to EN's γ. If H-FI returns positive, port this as a follow-up H-FI-B.

### Prime Intellect public run material (from prior web search, limited)

No new public Prime Intellect speedrun material was found beyond what was already incorporated into our stack (Aurora, EMA-Nesterov, Sinkhorn, RI). The PI autonomous agent results that were visible are consistent with our rank-1 stack being near the 2850-step frontier. No unincorporated mechanisms identified.

---

## What NOT to Try

### Saturated / fully closed axes (58 total)

**β₂ pulse amplitude axis:** 0.99 (INFERIOR x2), 0.995 (RANK-1 LOCKED), 0.997 (FALSIFIED), 0.999 (FALSIFIED). Inverted-U peak at 0.995 — no further amplitude search.

**β₂ pulse step axis with amp=0.99:** step=820 (INFERIOR at amp=0.99), step=970 (H-EO INFERIOR), step=1156 (H-EQ INFERIOR). The step axis at amp=0.99 is fully closed — every tested step fails relative to rank-1 (amp=0.995 @ step=820).

**v-reset / warm-restart class (H-FC):** CATASTROPHIC (+6.33 spike). Zeroing `exp_avg_sq` makes effective step ≈ 1000× → instant divergence. This ENTIRE mechanism class is closed.

**Lookahead on any optimizer:** H-DJ (Muon, +0.019 CATASTROPHIC), H-BU (AdamW, +0.008). Global Lookahead is harmful. Only RI-direction Nesterov (H-FM, above) is potentially safe because it is applied only in final 150 steps.

**SOAP Kronecker preconditioner (H-DP):** closed. AdamW second-order on our parameter shapes was harmful.

**Soft-Muon CEIL (H-DR):** closed. Clamping NS5 output norms was harmful.

**Continuous β₂ scheduling rules (H-EG arms):** all continuous β₂ schedule variants closed. Only step-function pulses are supported by the mechanism.

**Per-axis AdamW LR changes (H-BL, H-BF):** embed-only and uniform multi-group LR boosts both closed.

**MUON_POWER_C (H-DM), ARBOR_CLAMP_K (H-DK), EN_lookahead_stepsize (H-DL):** all hyperparameter levers on existing mechanism variants closed.

**SWA-EMA globally (H-DH):** global Stochastic Weight Averaging failed. Only Muon-only Polyak (H-FK, above) is a candidate.

**SOAP on MLP+V params (H-DP):** harmful. SOAP class closed for this stack.

**NorMuon pre-NS5 normalization variants (H-DU):** saturated alongside NC.

**RI single-anchor capture step axis:** step=2375 CONFIRMED; any other capture steps not worth testing without evidence that the current capture is suboptimal.

**DC-mode operations on Muon update path:** hard constraint 2 (H-AT/H-BH). Do not attempt mean-subtraction, batch-norm, or DC-component removal on the Muon gradient.

**AdamW multi-group LR scaling beyond default:** hard constraint 4 (H-BF). No multi-group LR boosts.

**Muon LR variation between blocks:** hard constraint 1 (H-BI).

**Any LR reductions to lm_head below 1/320 of base:** hard constraint 6 (H-CA).

---

## Decision Tree

```
┌── H-FF (β₁ × β₂ JOINT PULSE, step 820)
│   ├── n=2 ≤ 3.277172 at 2850 → H-FF n=4 at 2825 → if ≤ 3.278000 → WINNER (2825)
│   └── n=2 > 3.279000 → CLOSE; check if direction=reversed (β₁ rise + β₂ rise?)
│
├── H-FI (EN γ ANNEAL 0.99→gamma_final during cooldown)
│   ├── gamma_final sweep {0.97, 0.95, 0.90} n=2 each
│   ├── best n=2 ≤ 3.277172 at 2850 → H-FI n=4 at 2825
│   └── all arms > 3.279000 → CLOSE; confirms EN γ not a live lever
│
├── H-FK (Muon-only SWA last 150 steps)
│   ├── n=1 screen: if any step improves by > 0.0002 → n=4
│   └── no improvement → CLOSE; global SWA failure extends to Muon-only
│
├── H-FL (NS5 coefficient distribution-specific fit)
│   ├── Phase 1 offline fit: if F-norm error improves on holdout → Phase 2 n=4
│   └── No F-norm improvement on holdout → ABORT before training run
│
├── H-FG (GS pre-whitening before NC → NS5)
│   ├── Arm A alpha=0.3 n=1: ≤ 3.276000 → sweep alpha n=2
│   └── > 3.279000 → CLOSE (GS conditioning harms NS5 fixed-point convergence)
│
├── H-FH (adaptive cooldown trigger on slope telemetry)
│   ├── n=2 with winning thresholds ≤ 3.277172 at 2825 → n=4
│   └── n=2 > 3.279000 → CLOSE (adaptive trigger adds seed variance, not benefit)
│
├── H-FJ (AdamW eps annealed 1e-10 → 1e-12 by step 820)
│   ├── n=2 ≤ 3.277172 at 2850 → n=4 at 2825
│   └── Divergence in first 600 steps → ABORT (eps too loose early)
│
└── H-FM (Nesterov-RI pre-fetch last 150 steps)
    ├── n=1 ≤ 3.277000 at 2890 → n=4 at 2825
    └── > 3.279000 OR overhead > 15% → CLOSE (Lookahead-adjacent risk)
```

**Priority order for assignment:** H-FF (Tier 1, cleanest mechanism, cheapest implementation) → H-FI (Tier 2, EN γ is load-bearing, anneal is principled) → H-FK (Tier 2, well-supported SWA variant with cheaper eval-only mod) → H-FG (Tier 2, NS5 input conditioning) → H-FH (Tier 2, adaptive schedule) → H-FJ (Tier 2, eps phase dependency) → H-FL (Tier 2, offline fit required) → H-FM (Tier 3, Lookahead-adjacent risk).
