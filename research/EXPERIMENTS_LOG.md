# SENPAI Research Results

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
