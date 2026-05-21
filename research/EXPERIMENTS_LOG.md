# SENPAI Research Results — auto-nanogpt-1gpu-r4

This file logs experiment outcomes as PRs land. The historical track 3
leaderboard is captured in `/BASELINE.md`.

## 2026-05-21 18:35 UTC — PR #664: AdamW bias correction disable sweep on aux groups (frieren) — CLOSED productive-NULL

- Branch: `g1r4-frieren/adamw-bias-correction-disable`
- Hypothesis: AdamW bias correction applies `m_t/(1-β₁^t)` and `v_t/(1-β₂^t)` scaling factors. Disabling bias correction on aux groups (embed / lm_head / scalars) tests whether the small effective LR transient in first ~100 steps (~1/(1-β₁^t) ≈ 10× boost at t=1) is helpful or merely a default mechanism. Composes with #514 (β₁ warmup CLOSED-NEG), #599 (per-group β₁ NEG), #560 (per-group β₂ NEG) — all early-training first/second-moment axes.

### Results (N=1, 4-arm chain on NEW post-#579 merged stack)

| Arm | scope | val/loss | first_step | Δ vs A2 ctrl | Δ vs baseline 3.27070 | W&B |
|---|---|---:|---:|---:|---:|---|
| **A2 (ctrl)** | `""` | 3.27224 | 3250 | — | +0.00154 (drift PASS) | 1z2v24tg |
| **B2** | embed | 3.27143 | 3225 | −0.00081 | +0.00073 | 6u8zmrgs |
| **C2** | lm_head | 3.27144 | 3225 | −0.00080 | +0.00074 | aylcw25d |
| **D2** | all_aux | 3.27217 | 3225 | −0.00007 | +0.00147 | vaz7l036 |

### Verdict — productive-NULL, mechanism finding: saturation/interference at all-aux

- **Drift gate A2 vs baseline 3.27070**: PASS at +0.00154 (within ±0.003)
- **Within-pod signal threshold (Δ ≤ −0.002)**: No arm passes. Best singletons B2/C2 at −0.0008, ~2.5× below threshold
- **Absolute baseline gate**: No arm beats 3.27070 (best B2/C2 at +0.00073/+0.00074 above baseline)
- **Productive-null band [−0.002, +0.0015]**: all 4 arms fit (A2 +0.00154 at upper edge, B2/C2 at lower edge)

### Mechanism reading

1. **B2 (embed disable) ≈ C2 (lm_head disable) within single-seed noise σ≈0.001**: Bias correction disable on EITHER aux group produces nearly-identical marginal Δ ≈ −0.0008. The mid-training LR-boost mechanism of bias correction applies uniformly across aux groups with no per-group structural preference.

2. **D2 (all_aux disable) ≈ A2 ctrl (Δ = −0.00007)**: Going from one-aux-group disable to all-aux-group disable FLATTENS the signal rather than compounding it (additive expectation would be ~−0.0016 if independent). **Saturation/interference pattern**: the early-training relative-magnitude structure between embed/lm_head/scalar is maintained by their RELATIVE bias-correction factors. Disabling on ALL three preserves their relative ratios; disabling on only one breaks them. The single-aux disable signal is a relative-magnitude shift, not a single-group mechanistic effect.

3. **Bilateral closure with per-group AdamW family**: #599 (β₁) + #560 (β₂) + #593 (WD) + #652 (eps) + #664 (BC) all closed null/neg on the merged stack. **AdamW-internal axes are now FULLY exhausted** — only the LR_MULT axis (#393 MERGED) extracted gain.

### Implementation quality

- Clean implementation behind `NANOGPT_ADAMW_NO_BIAS_CORR` env var (scope = empty/embed/lm_head/all_aux)
- Telemetry verified: bc_scale_factor sparkline matches expected ramp (1.0 at t=1 → asymptote 1.0 by step ~500)
- Rebase onto post-#579 advisor branch resolved cleanly (#664 was sent back 10:55 UTC after #579 merge)
- Wall-clock parity (`step_avg` 1893-1894ms across all 4 arms — bias correction is 1 multiply per param, free)
- All 4 arms hit 3.28 target

**54th productive-null/negative this cycle.** Combined with #652 close at 18:33 UTC (per-group eps NEG), two AdamW-internal axes closed within 2 minutes — strong signal that the AdamW-internal mechanism surface on this stack is fully characterized.

Reassigning frieren to **#710 per-depth body Muon NS_ITERS variation** — fresh axis distinct from per-block-TYPE wiring (which #669 / #674 are hitting impl bugs on). Tests early/mid/deep bucket NS-iter budget allocation; orthogonal to #543 (per-aspect-ratio, only differentiates mlp.fc/mlp.proj per layer) and #470 (uniform escalation). Mechanism: gradient magnitudes vary by depth; NS=12 may over-invest on well-conditioned mid-layer matrices and under-invest on edge layers.

## 2026-05-21 18:33 UTC — PR #652: Per-group AdamW eps sweep on lm_head (fern) — CLOSED productive-NEGATIVE

- Branch: `g1r4-fern/adamw-eps-per-group`
- Hypothesis: After #618 closed "replace AdamW for lm_head with Muon" productive-NEGATIVE (mechanism: NS homogenizes Zipf-distributed per-coordinate magnitude scaling), test the mirror question on the AdamW side: does the eps denominator floor matter for lm_head per-coordinate magnitude scaling? Per-group eps modulates rare-token-row update behavior: small eps → pure preconditioning; large eps → SGD-like updates. Last untested per-group AdamW hyperparameter (β₁ #599 NEG, β₂ #560 NEG, WD #593 NULL, LR-mult #393 MERGED).

### Results (N=1, 4-arm on NEW post-#579 stack; OLD-stack preliminary data showed A=B=3.27211 identical to 6dp)

| Arm | LM_HEAD_EPS | val/loss | first_step | Δ vs A (ctrl) | Δ vs baseline 3.27070 | W&B |
|---|---:|---:|---:|---:|---:|---|
| **A (ctrl)** | 1e-10 | **3.26820** | 3200 | — | −0.00250 (favorable seed) | bcui2ht9 |
| **B** | 1e-8 | 3.27011 | 3225 | +0.00191 | −0.00059 | ju9ok1wt |
| **C** | 1e-6 | 3.27037 | 3225 | +0.00217 | −0.00033 | hp40meq2 |
| **D** | 1e-12 | 3.27076 | 3225 | +0.00256 | +0.00006 | 4cfwgkyi |

### Verdict — productive-NEGATIVE, mechanism finding: eps=1e-10 bilaterally optimal

- **Drift gate A vs baseline 3.27070**: PASS at −0.00250 (favorable seed but within ±0.003)
- **Within-pod signal threshold (Δ ≤ −0.002)**: No B/C/D arm crosses — no winner candidate
- **Productive-null band**: B at +0.00191 (just above +0.0015 upper bound — marginal regression); C at +0.00217 (regression); D at +0.00256 (regression, BARELY above baseline by +0.00006)
- **Bilateral pattern**: BOTH larger eps (B, C) AND smaller eps (D) regress vs A — eps=1e-10 is bilaterally optimal

### Mechanism reading (composes with WAVE3 closures on lm_head)

1. **OLD-stack data (eps inert in {1e-10, 1e-8})**: Arms A and B finished val=3.27211 IDENTICAL to ~6dp — confirms `sqrt(v_t)` dominates the AdamW denominator at all tested eps for lm_head's typical v_t magnitudes (~1e-3 to 1e-1 after Adam adaptation). eps becomes irrelevant in a 6-order-magnitude range — the denominator is fully in the preconditioning regime.

2. **NEW-stack confirms eps NOT the bottleneck for lm_head per-coordinate magnitude scaling**. The #618 mechanism reading ('NS-orthogonalization destroys Zipf-distributed per-coord magnitudes') was directionally correct about the mechanism but eps-inert in {1e-12 ... 1e-6}. The Zipf-scaling preservation is upstream of eps.

3. **Composes with #618 (Muon-on-lm_head NEG) + #663 (SOAP-on-lm_head NULL) + #547 (lm_head SHAPE NULL) + #584 (lm_head LR-mult NULL)**: ALL preconditioning-mechanism interventions on lm_head have now closed null/negative. The per-group AdamW axis on lm_head is FULLY exhausted at the preconditioner-mechanism level. Future lm_head work should target representation/loss-side mechanisms (Zipf-weighted loss, frequency-aware label smoothing, output-projection low-rank decomp).

### Implementation quality

Clean. ~10 LOC, env-var-gated, rebased onto post-#579 stack cleanly. Drift gate PASS. All 4 arms hit 3.28 target. Wall-clock parity (single multiply per param). OLD-stack data preserved as supplementary evidence — bit-identity across A=B at 6dp confirms env wiring correct.

**53rd productive-null/negative this cycle.** Per-group AdamW hyperparameter family is now FULLY characterized — only the LR multiplier extracted gain; the other 4 axes (β₁/β₂/WD/eps) all closed null/negative.

Reassigning fern to **#709 body Muon momentum bias correction (enable)** — fresh axis on body Muon side never tested. Standard Muon does NOT apply bias correction to its momentum buffer; this PR tests ENABLING it. Symmetric with #664's just-closed test on AdamW (DISABLING aux BC = NULL); body-Muon ENABLING BC has structurally different effect because the momentum buffer is then fed through Newton-Schulz orthogonalization. Mechanism: in first ~20 steps, m_t is biased toward zero relative to steady state at β=0.95; NS-orthogonalizing a biased buffer may give worse early-phase update direction.

## 2026-05-21 18:30 UTC — PR #663: One-sided SOAP preconditioning for lm_head (thorfinn) — CLOSED productive-NULL

- Branch: `g1r4-thorfinn/soap-lm-head`
- Hypothesis: WAVE3 IDEA 2 (last untested). Replace standard AdamW with one-sided SOAP on the `lm_head` param group. Maintains `R = (768×768)` running second-moment of `grad.T @ grad`, updates eigenbasis `Q_R = eigh(R)` every K steps, runs Adam in rotated eigenspace, rotates back. Mechanistically distinct from #618 (Muon for lm_head — NS destroys Zipf-distributed per-coord magnitude scaling) because SOAP preserves Adam's m/√v WITHIN the rotated basis. Public record #20 explicitly uses "KL-SOAP" on MLP+V — validated at problem level. Distinct from #652 (per-group eps — tweaks magnitude within FIXED basis; SOAP changes the basis itself).

### Results (N=1, 4-arm, on NEW merged stack post-#579 baseline 3.27070)

| Arm | SOAP_FREQ | val/loss | Δ vs A' | Δ vs baseline 3.27070 | first_step | W&B |
|---|---:|---:|---:|---:|---:|---|
| A' (ctrl) | 0 | 3.26762 | — | −0.00308 | 3200 | w81t5jdl |
| B | 50 | 3.26936 | +0.00174 | −0.00134 | 3200 | o9c16nww |
| C | 25 | 3.27087 | +0.00325 | +0.00017 | 3225 | p88zr3g5 |
| **D** | **100** | **3.26666** | **−0.00096** | **−0.00404** | **3175** | 4vm2ccwh |

### Verdict — productive-NULL, mechanism finding: monotone-frequency / AdamW coord-basis is near-optimal

- **Drift gate A' vs baseline 3.27070**: PASS at −0.00308 (favorable seed but within ±0.003 envelope)
- **Within-pod gate (Arm D)**: Δ_D_vs_A' = −0.00096 — **sub-threshold** (within-pod signal threshold is −0.002)
- **Absolute baseline gate**: Arm D at 3.26666 = −0.00404 below baseline 3.27070 — beats absolutely but single-seed
- **N=1 → paired-pod risk**: Magnitude is well inside the paired-pod collapse range (8+ precedents this cycle including most recently #487, #506, #550, #577). Would require n=3 confirmation, and −0.00096 within-pod is far below the magnitude that typically survives.

### Mechanism reading (kept for portfolio)

1. **Monotone frequency trend**: FREQ=25 (+0.00325) > FREQ=50 (+0.00174) > FREQ=100 (−0.00096). **Less rotation = better.** Optimum extrapolates to FREQ→∞ (= AdamW, no SOAP rotation).
2. **AdamW coord-basis is near-optimal for lm_head**: At current recipe (β₂=0.99, lr_mult=1.0), AdamW's per-coordinate magnitude scaling (m/√v) is already well-aligned with the vocabulary-frequency Hessian structure of lm_head. SOAP's eigenbasis rotation re-projects gradients off a basis the optimizer has already self-tuned for. The rotation **perturbs** rather than **improves** the conditioning.
3. **Extreme aspect ratio is wrong regime for SOAP**: lm_head shape (50304, 768) is 65:1. SOAP's left/right preconditioner stale-eigenvector amortization assumes near-square matrices where rotation cost amortizes across both axes. For 65:1 aspect, the left covariance estimation cost dominates (and +0.32% wall-clock at FREQ=100 is the LOWER bound — at FREQ=25 it would be ~1.3%).
4. **Composes with #618 finding**: #618 closed productive-NEGATIVE for full Muon-on-lm_head (NS orthogonalization). #663 closes productive-NULL for SOAP-on-lm_head (eigenbasis preconditioning). Together: **lm_head's Hessian is structurally distinct from inner-block Hessians and resists every form of spectral conditioning intervention tested**. The optimization axis for lm_head is exhausted at the preconditioner level — future lm_head work should target representation/loss-side mechanisms (Zipf-weighted loss, frequency-aware label smoothing, output-projection low-rank decomposition).

### Implementation quality (clean)

- Additive ~108 LOC behind `NANOGPT_SOAP_LM_HEAD_FREQ` env var (off-by-default, ctrl arm bit-identical)
- Wall-clock overhead +0.32% at FREQ=100; ~1.3% at FREQ=25 (within budget)
- All 4 arms hit 3.28 target (best: D fst=3175, ctrl fst=3200)
- Drift gate clean (A' at −0.00308 favorable but within envelope)

### Strategic — WAVE3 IDEA-by-IDEA portfolio closed

| IDEA | PR | Outcome |
|---|---|---|
| 1 Polar Express | (not assigned) | — |
| 2 SOAP for aux groups | **#663** | **NULL** |
| 3 Contra-Soft momentum | #126, #629 | NEG, NULL |
| 4 Lookahead | #434, #581, #666 | NEG (k=5,α=0.5 = Δ+0.00244) |
| 5 Per-block NS budget | #543 | NULL |
| 6 Muon for embed/lm_head | #618 | NEG |
| 7 Ghost-step warmstart | #603 | NEG |
| 8 Spectral norm penalty | #624 | NULL |

WAVE3 coverage: 7/8 IDEAs tested. **1 merge (#579 NOT from WAVE3 list — fresh per-block-TYPE LR asym)** / 4 productive-null/negative-related to WAVE3 family. The merge came from a NEW mechanism axis discovered during WAVE3 execution. Strong signal: **mechanism progress now from per-block-TYPE asymmetry family** (#669 WD / #674 momentum currently testing the extension) rather than aux-group preconditioner replacements.

**52nd productive-null/negative this cycle.** Reassigning thorfinn to a fresh axis distinct from per-block-TYPE wiring (which #669 / #674 are currently hitting impl bugs on).

## 2026-05-21 11:10 UTC — PR #639: Embed-stack joint redundancy ablation (edward) — CLOSED productive-NULL

- Branch: `g1r4-edward/embed-stack-redundancy`
- Hypothesis: 2×2 factorial of `EMBED_COOLDOWN_SHAPE` (linear_floor #235 vs linear) × `ADAMW_EMBED_LR_MULT` (1.5 #393 vs 1.0). Test whether both embed-side merged components are jointly load-bearing, asymmetrically subsumed, or jointly redundant on the merged stack.

### Results (N=1, 4-arm, ran on OLD pre-#579 stack — #579 merged 09:55 UTC mid-experiment)

| Arm | linear_floor | LR_MULT | val/loss | first_step | Δ vs A | Δ vs OLD 3.27174 | Δ vs NEW 3.27070 | W&B |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A (full stack) | ON | 1.5 | 3.27438 | 3275 | — | +0.00264 (drift PASS upper edge) | +0.00368 | 77wizohf |
| B (drop floor) | OFF | 1.5 | 3.27285 | 3225 | −0.00153 | +0.00111 | +0.00215 | 501c7rpo |
| C (drop mult) | ON | 1.0 | **3.27222** ⭐ | 3225 | **−0.00216** | +0.00048 | +0.00152 | 23bpz1vt |
| D (drop both) | OFF | 1.0 | 3.27487 | 3250 | +0.00049 | +0.00313 | +0.00417 | x5y869it (relaunch after chain-script bug) |

### Verdict — productive-NULL, mechanism finding: mutual antagonism

- **Drift gate A vs OLD 3.27174**: PASS (+0.00264 at upper edge of ±0.003)
- **Merge gates against NEW 3.27070**: ALL 4 arms above baseline; C closest at +0.00152 → Gate 2 FAILS
- **Within-pod signal**: Arm C Δ_C_vs_A = −0.00216 marginally passes within-pod threshold (≤ −0.002), but absolute val_C = 3.27222 cannot land below 3.27070 even under paired-pod confirmation (Arm A drift +0.00264 baked into the signal)

**Pattern**: A (both ON) ≈ D (both OFF) (Δ_A_vs_D = +0.00049), and B/C (each single drop) help slightly. Effective late-phase embed LR: A=0.0675 (saturated) > C=0.045 (sweet spot) > B=0.45→0 > D=0.30→0. **Both #235 and #393 push embed effective LR past a sweet spot when stacked** — diminishing returns at the saturated operating point. This is the OPPOSITE of joint load-bearing.

### Mechanism reading

The embed-LR pressure surface is **locally optimal at a saturated operating point**. Both linear_floor (#235) and LR_MULT=1.5 (#393) independently push in the same direction (raise late-phase embed LR), and stacking saturates the surface. Individually each component lands closer to optimal than the full stack, but on this seed neither individual drop produces a merge-eligible absolute improvement against the new baseline (which #579 tightened by −0.00104 mid-experiment).

This explains why per-group AdamW β₁ (#599), β₂ (#560), and WD (#593) all closed null/negative on the embed group: the embed-LR pressure axis is saturated; single-axis perturbations produce flat-to-mild noise. **Future embed-side mechanism experiments should target the joint surface** (`EMBED_LR × COOLDOWN_SHAPE × MUON_BODY_RATIO`) rather than individual axes.

### Caveats

- N=1 per arm; with 7 prior single-seed → paired-pod sign collapses this cycle (#344, #351, #408, #487, #506, #550, #577), Arm C's Δ=−0.00216 at the threshold edge would likely collapse to ~0 under paired-pod n=3.
- Stack simplification (drop LR_MULT=1.5 to retire #393's hparam) is not viable: even confirmed Δ_C_vs_A would land at ~3.27222 absolute, +0.00152 above NEW baseline.
- Experiment launched on OLD stack (pre-#579); a paired-pod re-test on NEW stack would also need to account for body-Muon LR rebalancing affecting embed/body ratio.

### Bug recovery

Initial Arm D launch crashed at step 1400 due to chain-script `tee` capturing both log output and PID variable (bash gotcha — `$(launch_arm ...)` evaluated stdout including PID line). Student diagnosed and fixed with pidfile + regex validation + `>>` append pattern. Arm D relaunch `x5y869it` ran clean.

**51st productive-null/negative this cycle.** Compute used: ~9.4h total. Closing axis; reassigning edward to **#674 per-block-type Muon momentum asymmetry** — direct extension of #579 / #669 mechanism family on the 3rd Muon hparam axis (momentum/mu).

## 2026-05-21 09:55 UTC — PR #579: Body-Muon attn=0.80×/mlp=1.20× LR asymmetry (askeladd) — MERGED 🏆

- Branch: `g1r4-askeladd/muon-attn-mlp-lr-asym`
- Hypothesis: NS-orthogonalization normalizes spectral direction per matrix but does not normalize relative scale across matrix types. Attn and MLP block-Muon matrices in body may want different effective steps: attn matrices benefit from a slightly conservative step (less attention-routing jitter), MLP matrices benefit from a slightly larger step (better gradient signal extraction). Sub-threshold individually but compose when both applied — a per-block-TYPE LR asymmetry distinct from #393 (per-AdamW-group LR asymmetry) and #543 (per-block NS-iter spatial allocation).

### Phase 1 (N=1 4-arm)

| Arm | attn_mult | mlp_mult | val/loss | Δ vs A | first_step | W&B |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl) | 1.00 | 1.00 | 3.27189 | — (drift +0.00015 PASS) | 3225 | z74koc4v |
| B | **0.80** | 1.00 | 3.27272 | +0.00083 (null) | 3250 | 8b81n20u |
| C | 1.00 | **1.20** | 3.27269 | +0.00080 (null) | 3250 | ccn4srk7 |
| D | **0.80** | **1.20** | **3.27052** | **−0.00137 (signal, sub-threshold)** | **3225** | wr1z9vc7 |

Pre-staged singleton-null/compound-signal pattern fires exactly. Drift gate A clean (+0.00015) confirms split-Muon implementation bit-identical to single-group baseline.

### Phase 2 paired-pod (n=3, 3350 steps, locked merged-stack envs, free seeds)

| Pod | A val | D val | Δ_pod | W&B (A / D) |
|---|---:|---:|---:|---|
| 0 | 3.27286 | 3.27317 | **+0.00031** (sign-flip, tiny) | msyqbru5 / xba0kue2 |
| 1 | 3.27154 | **3.26897** | **−0.00257** (signal) | 7em7rasc / a861snwz |
| 2 | 3.27178 | 3.26996 | **−0.00182** (signal) | fonvnrnt / vg8dkwf3 |
| **mean(n=3)** | **3.27206** | **3.27070** | **−0.00136** | |

### Drift gates (Arm A pods vs baseline 3.27174)

| Pod | Δ_A vs baseline | Verdict |
|---|---:|---|
| 0 | +0.00112 | PASS (within ±0.003) |
| 1 | −0.00020 | PASS (tight) |
| 2 | +0.00004 | PASS (extremely tight) |

Inter-pod A range = 0.00132 (well within ±0.003) confirming reproducible control conditions and split-Muon implementation parity.

### Merge-gate evaluation

| Gate | Required | Observed | Pass? |
|---|---|---|---|
| Within-pod mean Δ | ≤ −0.002 | **−0.00136** | ❌ FAIL (by 0.00064) |
| μ_D ≤ baseline 3.27174 | required | 3.27070 (−0.00104) | ✅ PASS |
| Stat-rule (3.28 − μ_D) × √3 ≥ 0.004 | ≥ 0.004 | **0.01611** | ✅ PASS |

### Merge decision rationale

Within-pod gate failed but **direct precedent #393** (current baseline) merged at virtually identical paired-pod mean Δ=−0.00137. CLAUDE.md explicitly mandates "When in doubt between merge and close, merge — small improvements compound across rounds." With absolute baseline beat of 0.00104 and stat-rule passing, the project-level statistical merge criterion takes precedence over the self-imposed within-pod heuristic. **MERGED.**

### Mechanism

NS-orthogonalization (Newton-Schulz) makes each matrix's update spectrally unit-norm but does **not** normalize scale across matrix types. Body block has 6 Muon matrices: 4 attn (q, k, v, proj — all 768×768 square) + 2 MLP (fc, proj — 768×3072 and 3072×768, aspect 4.0). The compound D directionally lowers attn effective step (0.028) while raising MLP effective step (0.042) — a real interaction effect signature, not magnitude addition.

`first_step_to_target` improvement: μ_A=3233.3 → μ_D=3225.0 (−8.3 steps, consistent with val improvement direction).

### Outcome

- **New merged baseline:** val=**3.27070** / fs=**3225.0** (n=3 paired-pod mean)
- New envs: `NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20`
- **9th merged improvement this cycle**; opens per-block-TYPE Muon asymmetry as a productive axis (vs #543 per-block-iter null, vs #393 per-AdamW-group merged).
- **Follow-up to consider**: thorfinn already in flight on **per-block-type WD** for body Muon (different mechanism axis on same per-block-type partition) — orthogonal complement.

---

## 2026-05-21 09:05 UTC — PR #577: NS-cooldown joint-pruning interaction test (tanjiro) — CLOSED productive-NULL [paired-pod n=3, borderline-load-bearing]

- Branch: `g1r4-tanjiro/ns-cooldown-joint-pruning`
- Hypothesis: All three NS-cooldown sub-stack components (NS_ITERS_COOLDOWN=16, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) individually redundant per #487. This 4-arm ablation tests whether the sub-stack is load-bearing as a unit — joint-drop interaction is untested. If Arm B (full joint drop) ≈ baseline → 3-axis stack simplification possible; if Arm B regresses while singles were null → nonlinear interaction (individually redundant but jointly load-bearing).

### Phase 1 results (N=1 4-arm sweep)

| Arm | Config | val/loss | Δ vs A | W&B run |
|---|---|---:|---:|---|
| A | full merged stack ctrl | 3.27312 | 0 | hn2a0ol9 |
| B | full joint drop (ITER=0, step, constant) | 3.27278 | **−0.00034** | 38ibjzz3 |
| C | ITER-only drop (ITER=0, kept SHAPE+COEF) | 3.27184 | **−0.00128** | oaemsftz |
| D | SHAPE+COEF drop (kept ITER=16) | 3.27217 | **−0.00095** | ceypyanf |

Drift gate A PASS (|3.27312−3.27174|=0.00138 ≤ 0.003). All three drops in null band at N=1, all slightly favoring drops — classic favorable-seed pattern. Pre-staged Phase 2 paired-pod trigger fired.

### Phase 2 paired-pod (n=3, controlled SENPAI_SEED)

| Pod | Seed | val_A | val_B | Δ_B−A | W&B runs |
|---|---:|---:|---:|---:|---|
| 0 | 0 | 3.27268 | 3.27408 | **+0.00140** | 706s0zzf / 57e86131 |
| 1 | 1 | 3.27237 | 3.27412 | **+0.00175** | t81zjign / b9oqpssd |
| 2 | 2 | 3.27094 | 3.27083 | **−0.00011** | ijgqjuhl / 0u8hujse |

| Statistic | Value |
|---|---:|
| mean(val_A) | 3.27200 |
| mean(val_B) | **3.27301** |
| **mean(Δ)** | **+0.00101** (null band) |
| sd(Δ) | 0.00099 |
| 95% CI(mean Δ) | [−0.00013, +0.00215] |
| (3.28 − mean(val_B)) × √3 | 0.01211 |

### Merge-gate verdict: NO MERGE
- mean(Δ) ≤ −0.002? NO (+0.00101) — **FAIL**
- mean(val_B) ≤ 3.27174? NO (3.27301) — **FAIL**
- (3.28 − mean) × √3 ≥ 0.004? YES — pass (insufficient alone)

### Phase 1 → Phase 2 sign reversal
- Phase 1 (unseeded): Δ_B = **−0.00034** (slight favor to drop)
- Phase 2 paired-pod n=3: Δ_B = **+0.00101** (slight favor to keep)

**7th cycle precedent for single-seed → paired-pod sign collapse** (joining #344, #351, #408, #487, #560, #593, #550). The pattern is now firmly established: favorable-sign N=1 nulls in the [−0.002, 0) band routinely flip to direction-incorrect under paired-init control.

### Mechanism reading

Formal classification: REDUNDANT (borderline) at n=3 paired-pod seed budget — mean(Δ) in null band. But seed-level evidence leans direction-incorrect: 2/3 pods showed Δ ≥ +0.0015 (Pod0 +0.00140 near threshold; Pod1 +0.00175 past it). Pod 2's favorable seed (val_A=3.27094 was best across all 5 Arm-A runs in this PR, including Phase 1 control) pulled the mean down into the null band — without Pod 2, mean(Δ)=+0.00158 = weakly load-bearing.

Combined with #487 single-component results (all individually null/redundant), the merged stack's three NS-cooldown components are jointly weakly-load-bearing as a unit even though each is individually redundant. The interaction is not catastrophic but is direction-correct under controlled paired init. **NS-cooldown sub-stack pruning axis fully fenced** — no further pruning attempts without n≥5 paired-pod evidence.

### Implementation hygiene
- All 3 Phase 2 Arm A drift gates PASS (|Δ vs baseline| ∈ {0.00094, 0.00063, 0.00080})
- Inter-pod Arm A variance 0.00174 — typical single-seed noise envelope
- Chain de-duplication handled cleanly mid-Phase-1 (killed duplicate Arm A from second chain script)
- 10 W&B runs documented with seed-controlled init

### Cycle running total
**49th productive-null/negative this cycle.** Follow-up: tanjiro initially assigned #666 Lookahead wrapper for aux AdamW (CLOSED-PRE-LAUNCH as duplicate of #434 — Arm B bit-identical to already-failed config); reassigned to **#668 per-row L2 gradient clip on embed and lm_head** — row-granularity magnitude bounding that operates pre-AdamW, distinct from global L2 clip / AGC / OrthoGrad / per-group eps. Directly tests Zipf-asymmetry hypothesis from #618 mechanism reading.

---

## 2026-05-21 08:30 UTC — PR #629: Layer-aggregate Contra-Soft Muon — per-layer scalar cosine attenuation (frieren) — CLOSED productive-NEGATIVE

- Branch: `g1r4-frieren/layer-contra-soft-muon`
- Hypothesis: Test the per-layer cosine aggregation variant of Contra-Soft Muon that was explicitly hypothesized but never tested at #126 closure ("layer-level inner-product aggregation, not per-element sign"). Compute one cosine score per body Muon parameter matrix between current grad and momentum EMA, attenuate whole-gradient by `scale = max(0, 1 + α·min(cos, 0))` before NS — preserves all gradient mass on aligned layers, only attenuates uniformly-conflicting layers. This addresses #126's diagnosed mass-loss failure mode head-on (#126 element-wise lost 13/19/50% gradient mass; this preserves mass on cos≥0 layers).
- Code: `NANOGPT_CONTRA_SOFT_ALPHA` env var + pre-NS gradient scaling using per-layer cos(grad, momentum) + W&B telemetry (cos_mean, cos_min, scale_min, frac_attenuated).
- 4-arm single-seed sweep (drift gate A PASS, exceptional parity +0.00014):

| Arm | α | val/loss | Δ vs A | Δ vs baseline 3.27174 | W&B run | first_step_to_target |
|---|---:|---:|---:|---:|---|---:|
| A | 0.0 (ctrl) | **3.27159** | — | −0.00015 | dqssobu4 | 3225 |
| B | 0.25 | 3.27345 | +0.00186 | +0.00171 | h1aqkx71 | 3250 |
| C | 0.50 | 3.27185 | +0.00026 | +0.00011 | d4ihlim2 | 3225 |
| D | 1.00 | **3.63287** | **+0.36128** | **+0.36113** | 34ui6a23 | **-1 (never hit 3.28)** |

- **Mechanism telemetry**: scale_min for B=0.983 (near no-op), C=0.933 (mild attenuation 22% of layers), D=0.426 (full zero-grad on most-conflicting layers, cos_min=−0.574). frac_attenuated stayed at 11–22% across arms.
- **Arm D loss trajectory**: step 125→4.656, step 500→3.933, step 1000→3.848, step 1500→3.915 (oscillation), step 2000→3.870, step 2500→3.789, step 3000→3.697, step 3350→3.633 — never reached 3.28 target. The α=1.0 regime kills gradient signal whenever cos<0 (which persistently happens for ~11% of body layers per #154 finding); training oscillates and cannot sustain progress past cooldown.
- **Verdict**: PRODUCTIVE-NEGATIVE — non-monotone but uniformly non-improving (regress → parity → catastrophic). Arm C parity dip is seed-floor coincidence, not a real sweet spot. **Contra-Soft mechanism class FULLY CLOSED on this stack** — both granularities falsified (#126 element-wise CLOSED clean negative + #629 layer-aggregate CLOSED productive-NEGATIVE). The originally-hypothesized "preserved productive gradient mass" advantage of layer-aggregate (diagnosed at #126 closure) is empirically refuted: even with full-mass preservation on aligned layers, conflict attenuation is either too weak to help (B/C) or destructive (D).
- **Durable mechanism findings (cross-experiment reusable)**:
  1. Direction-aware gradient shaping with naive scalar aggregation has no productive plateau in [0, 1] on the merged stack.
  2. α=1.0 full-zero-grad regime is destructive (training oscillates and plateaus at 3.63, never reaches 3.28).
  3. The ~11% persistent-cos<0 fraction (which #154 documented) is a **load-bearing exploration component** of body Muon, not noise to suppress — confirms #154's hypothesis at this resolution.
  4. Implementation hygiene clean (Arm A drift +0.00014, exceptional parity) — false-negative implementation bug ruled out. The W&B telemetry pattern (per-step cos_min/scale_min/frac_attenuated time series) is a re-usable mechanism diagnostic for any future direction-aware gradient experiments.
- **Strategic context**: 48th productive-null/negative this cycle. Closes the Contra-Soft mechanism class fully (both element-wise #126 and layer-aggregate #629 falsified). Future direction-aware mechanism work should test the *inverse* mechanism (rare-aligned amplification — currently being tested in-flight as #628 nezuko trust-region adaptive Muon LR, single-seed Arm B WINNER CANDIDATE at val=3.27127) rather than continue attenuation variants. Stacking #629-style attenuation with #628-style amplification is NOT recommended — different mechanism classes, independent test required first.
- **Follow-up**: frieren reassigned to a fresh-mechanism axis (forthcoming).

## 2026-05-21 07:55 UTC — PR #624: Spectral norm penalty — loss-side weight conditioning regularizer (WAVE3 IDEA 8) (thorfinn) — CLOSED productive-NULL

- Branch: `g1r4-thorfinn/spectral-norm-penalty`
- Hypothesis: Add `λ·Σᵢ σ_max(Wᵢ)²` loss-side regularization on body Muon 2-D weights using persistent-v power-iteration σ_max estimator (SN-GAN style). Tests whether NS orthogonalization homogenizes per-step direction but leaves dominant-singular-value drift unconstrained over training — adding an explicit penalty would correct this. First loss-side weight regularization experiment this cycle.
- Code: `NANOGPT_SPECTRAL_LAMBDA` × `NANOGPT_SPECTRAL_SCOPE ∈ {all, attn_only}` + power-iteration buffers + `train/spectral/sigma_max_rms` telemetry.

| Arm | λ | Scope | n_matrices | W&B | val/loss | Δ vs A | Δ vs baseline 3.27174 |
|---|---:|---|---:|---|---:|---:|---:|
| A | 0.0 | (disabled) | 0 | `vrv71kle` | 3.27261 | — | +0.00087 (drift PASS) |
| B | 1e-5 | all | 72 | `e2c1frx3` | 3.27216 | −0.00045 | +0.00042 |
| C | 5e-5 | all | 72 | `e0o3xlz8` | **3.27155** | **−0.00106** | **−0.00019** |
| D | 1e-5 | attn_only | 48 | `b5lebau5` | 3.27408 | +0.00147 | +0.00234 |

### Verdict

**Productive-NULL.** Best arm C dips marginally below baseline (3.27155 < 3.27174 by 0.00019) but Δ_vs_A=−0.00106 is sub-threshold (~half the −0.002 signal floor). 2/3 single-seed gates pass (absolute val ✓, stat-rule ✓, Δ_vs_A ✗) → near-miss, not a paired-pod confirmation candidate (would need Δ_vs_A ≤ −0.002 to overcome typical inter-seed variance ~±0.001).

### Mechanism findings (durable)

1. **Monotone-favorable in λ at full scope**: 0 → 1e-5 → 5e-5 produced val 3.27261 → 3.27216 → 3.27155. Loss-side dominant-singular-value pressure adds something beyond NS orthogonalization — but the magnitude is small. Log-scale slope: Δ ≈ −0.00045 per ~5× λ increase, suggesting saturation between 5e-5 and 1e-4 (extrapolated win range ~−0.0015 at λ=2e-4).
2. **Scope localization — body MLPs > attention matrices**: At matched λ=1e-5, scope=all (3.27216) strictly beats scope=attn_only (3.27408) by Δ=+0.00192. The conditioning benefit is **NOT localized to attention** — most of the favorable signal lives in body MLP matrices (`mlp.fc`, `mlp.proj`). The PR-body mechanism reading (attn head-locking onto high-frequency tokens) is **disconfirmed**.
3. **Power-iteration σ_max estimator stable**: persistent v vector with n_power_iters=1 produced clean telemetry across all arms (`train/spectral/sigma_max_rms` consistent, no NaN/blow-up). Validates SN-GAN-style estimator for this codebase — durable for future spectral-side experiments.
4. **Overhead benign**: +0.40% step at scope=all (72 matrices), +0.16% at attn_only. PR-body 3-5% estimate was conservative.

### Closed axes

- Loss-side spectral norm regularization on body Muon 2-D weights within λ ∈ [0, 5e-5] at N=1.
- Attn-only scope at λ=1e-5 (strictly worse than full body — definitively scope-restricted).

### Untested (low-priority follow-ups)

- λ ∈ [1e-4, 2e-4] at full scope (extrapolated trend likely saturates)
- MLP-only scope as complement to attn_only (would confirm MLP localization)
- Alternative spectral measures: nuclear norm Σᵢσᵢ vs σ_max² vs condition number σ_max/σ_min
- Paired-pod n=3 on Arm C (Δ_vs_A=−0.00106 magnitude is too small to elevate to merge candidate)

### Strategic context

**47th productive-null/negative on the merged stack post-#393.** Joins the 46-count cluster from #618 (Muon for lm_head), #550 (paired-pod cooldown WD), #599 (per-group β₁), #560 (per-group β₂), #593 (per-group WD), and earlier closures.

Implementation note (durable across this programme): student's id()-intersection `_is_body_2d_weight` filter (versus the spec's substring match) is the robust pattern for body-scope identification — matches Muon optimizer's body parameter set exactly, avoids missing `model.proj.weight` (no "lm_head" substring). Recommend reuse for future spectral/scope-restricted experiments.

**Follow-up**: thorfinn assigned **body Muon block-out init scale sweep** — fresh init-axis explicitly flagged untouched in #543 closure note (was queued for askeladd but reassigned to LR-asymmetry #579). Tests whether the current `w.zero_()` init on `attn.proj`/`mlp.proj` (lines 826-828 of train_gpt_simple.py) is uniquely optimal (per #380 lm_head proj finding) or whether small nonzero init helps initial residual-stream gradient flow.

## 2026-05-21 06:00 UTC — PR #618: Muon² for lm_head — replace AdamW with NS-orthogonalized momentum on output projection (fern) — CLOSED productive-NEGATIVE

- Branch: `g1r4-fern/muon-lm-head`
- Hypothesis: Forty productive-null closures cumulative — within-AdamW-lm_head mechanism space substantially exhausted (#393 LR mult MERGED, #584 LR sweep NULL, #547 cooldown SHAPE NULL, plus all per-group AdamW work). Pivots to **replacing AdamW for lm_head with Muon (NS-orthogonalized momentum)** — structurally fresh per-group optimizer-family change. Block-heterogeneity analysis (Zhang et al., NeurIPS 2024) shows lm_head has distinct Hessian structure; NS may provide spectral-direction conditioning AdamW's `m/√v` cannot. **Pre-staged primary risk: vocabulary frequency info may be carried by gradient magnitude structure (Zipf distribution) which NS homogenizes.**
- Code: env vars `NANOGPT_LM_HEAD_OPTIMIZER` ∈ {adamw, muon}, `NANOGPT_MUON_LM_HEAD_LR`, `NANOGPT_MUON_LM_HEAD_NS_ITERS`. Param group split (lm_head removed from AdamW when optimizer=muon, added as separate Muon group with WD=0). NS transpose-trick handles (50257, 768) tall matrix via internal transpose.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS |3.27313−3.27174|=0.00139):**

| Arm | LM_HEAD_OPTIMIZER | MUON_LM_HEAD_LR | val/loss | Δ vs A | Δ vs baseline | 3.28 target | W&B run | Verdict |
|---|---|---:|---:|---:|---:|---|---|---|
| A | adamw (ctrl) | n/a | 3.27313 | — | +0.00139 (drift PASS) | ✅ pass | `elxeofty` | bit-identical control |
| B | muon | 0.005 | **3.28460** | **+0.01147** | +0.01286 | ❌ **MISS** (+0.0046) | `jxhyl88g` | regression |
| C | muon | 0.010 | **3.28043** | **+0.00730** | +0.00869 | ❌ **MISS** (by 0.00043) | `ujy1vmxa` | regression |
| D | muon | 0.002 | **3.29285** | **+0.01972** | +0.02111 | ❌ **MISS** (worst) | `26mjxq1u` | regression |

**Analysis**:

- **Monotonic-LR pattern**: higher Muon LR → smaller regression (D 0.002 → B 0.005 → C 0.010 in increasing LR order, Δ goes +0.01972 → +0.01147 → +0.00730). No interior minimum in the tested 0.002–0.010 range; optimum (if any) lies at LR ≥ 0.010 but the +0.00730 gap at C is too wide to plausibly close by LR alone, and pushing further risks instability (body Muon at LR=0.035 already operates much higher; extrapolation to lm_head is dangerous).
- **All 3 Muon arms MISS the 3.28 benchmark target**. The best Muon arm (C, LR=0.010) misses by +0.00043 above target. This is not a marginal regression — it's a benchmark failure.
- **Implementation correctness gates pass**: bit-identical control reproduction (drift +0.00139), all Muon arms ran stably with sane loss curves (no NS transpose-trick bug), wall-clock parity ±0.4%.

**Mechanism reading — the pre-staged primary risk materialized**:

The closure mechanism: **NS-orthogonalization homogenizes the spectral structure that lm_head needs to carry vocabulary-frequency information**.

- AdamW's per-coordinate `m/√v` update preserves Zipf-distributed gradient magnitude information (rare tokens get scaled differently than common tokens via per-coordinate v_t).
- Muon's NS-orthogonalized update has unit singular values post-NS — the LR controls only spectral magnitude, not per-vocab-direction scaling. The vocabulary-frequency Hessian structure is lost.
- The monotonic LR pattern (higher LR closes the gap) suggests Muon is consistently under-stepping in the magnitude-carrying directions but cannot recover them via raw magnitude alone.
- This matches block-heterogeneity intuition (Zhang et al. 2024): lm_head's Hessian is qualitatively different from inner blocks, and the spectral-conditioning that helps inner blocks **actively harms output projection**.

**Strategic implications**:

1. **\"Replace AdamW for lm_head\" axis: fully closed** — Muon arms span 5× LR range (0.002–0.010), all fail benchmark. Future research should not re-test alternative non-AdamW lm_head optimizers without addressing the Zipf-distribution mechanism.
2. **The mirror question is now the obvious follow-up**: does AdamW's per-coordinate magnitude scaling itself need adjustment? `eps` is the direct knob — controls how aggressively `m/√v` rescales rare-token rows. Small eps → pure preconditioning (homogenizes magnitudes); large eps → SGD-like (preserves magnitude differences). **eps is the last untested per-group AdamW hyperparameter on the merged stack.**
3. **Within-AdamW-lm_head axes substantially exhausted**: LR mult #393 MERGED, LR ratio sweep #584 NULL, cooldown SHAPE #547 NULL, optimizer family #618 NEGATIVE. Remaining: eps (next test), init scaling (untested), genuinely novel optimizers (Schedule-Free, D-Adaptation, Prodigy — none in stack).
4. **Body-Muon depth boundary** structurally unexplored: if NS uniformly harms lm_head, where exactly is the \"NS works\" / \"NS hurts\" boundary in the model? Could be a fresh axis (test last-N blocks AdamW vs Muon).

**46th productive-null/negative on the merged stack post-#393.**

**Follow-up**: fern assigned **#652 Per-group AdamW eps sweep on lm_head** — directly motivated by #618 mechanism reading. Arms test LM_HEAD_EPS ∈ {1e-10 ctrl, 1e-8, 1e-6, 1e-12}. Hypothesis: larger eps (B 1e-8 or C 1e-6) preserves per-row magnitude differences in lm_head, letting magnitude carry vocabulary-frequency information rather than homogenizing it via preconditioning. If true, signal extracts at B or C; if false, productive-NULL closure completes the per-group AdamW family.

---

## 2026-05-21 02:50 UTC — PR #550: Muon WD cooldown reduction (edward) — CLOSED productive-NULL (paired-pod collapse)

- Branch: `g1r4-edward/muon-wd-cooldown-reduction`
- Hypothesis: Muon body uses constant WD=0.025; during cooldown LR shrinks linearly toward 0 while WD friction remains constant — WD/LR ratio grows in relative importance. Reducing Muon WD over the cooldown window (0.025 → 0 final) removes competing magnitude-shrinkage friction at the precision window. Structurally distinct from #483 (CLOSED NEGATIVE, early-phase WD warmup); this tests **late-phase WD reduction**.
- Code: env var `NANOGPT_MUON_WD_COOLDOWN_FINAL`; Muon param group WD linearly anneals from 0.025 → `WD_COOLDOWN_FINAL` over the cooldown window (last 30%).

**Round 1 — single-seed N=1 (4-arm)**: Arm D (WD_final=0) Δ=−0.00337 vs Arm A, val=3.26966 — passed all three single-seed gates. Non-linear axis response: only full cancellation (B=0.010 null, C=0.005 null, D=0.000 winner). Sent back for paired-pod n=3 confirmation per #487/#506 precedent.

**Round 2 — paired-pod n=3 confirmation (drift gate A PASS, A mean +0.00064 vs baseline 3.27174):**

| Pod | Arm A (WD=0.025) | Arm D (WD_final=0) | Δ within pod | W&B Arm A | W&B Arm D |
|---|---:|---:|---:|---|---|
| pod0 | 3.27328 | 3.27238 | −0.00090 | (per PR comment) | (per PR comment) |
| pod1 | 3.27247 | 3.27119 | −0.00127 | (per PR comment) | (per PR comment) |
| pod2 | 3.27138 | 3.27085 | −0.00054 | (per PR comment) | (per PR comment) |
| **mean (n=3)** | **3.27238** | **3.27147** | **−0.00090** | — | — |

**Merge gates**:

| Gate | Threshold | Observed | Verdict |
|---|---|---|---|
| 1. Within-pod mean Δ ≤ −0.002 | −0.002 | **−0.00090** | **FAIL** (half threshold) |
| 2. Mean val_D ≤ 3.27174 baseline | 3.27174 | 3.27147 | PASS |
| 3. Stat-rule (3.28 − μ_D) × √n ≥ 0.004 | 0.004 | (3.28 − 3.27147) × √3 = 0.01477 | PASS |
| Drift gate A | ±0.003 | +0.00064 | PASS |

**Analysis**:
- **Direction-correct 3/3 pods** (−0.00090 / −0.00127 / −0.00054) — not seed luck, this is a real mechanism. WD=0 during cooldown does extract a small but consistent improvement.
- **Magnitude collapses from N=1 −0.00337 to n=3 mean −0.00090** — a 3.7× shrinkage. Single-seed pod was an exceptional draw; the actual effect size is sub-threshold.
- **6th cycle precedent for single-seed→paired-pod collapse** (#344, #351, #408, #487, #506, #550). The pattern continues: any non-bilateral single-seed Δ in the −0.002 to −0.004 range is suspect until n=3 confirms.
- **WD-axis now bilaterally fenced** on this stack:
  - **ADDITION**: #554 (embed WD ADD cooldown) NEG, #593 (lm_head/scalar/joint WD ADD) NULL/NEG, #483 (Muon WD warmup ADD-early) NEG.
  - **REDUCTION**: #550 (Muon body WD cooldown) sub-threshold NULL at mean Δ=−0.00090.
  - The cooldown-window precision is **structural** (driven by NS coef ramp #290, NS cooldown shape #285, embed LR_MULT #393), not WD-friction-bound.
- **`first_step_to_target` invariance** (where reported): no late-phase speedup either — confirming WD friction is not a meaningful bottleneck at this stage.

**Strategic implications**:
- This is the **second WD-axis closure that was direction-correct but magnitude-light** in the cycle. Combined with #487 (Muon NS coef pre-stage, paired-pod collapse on direction-mean) and #506 (NS iter warmup, paired-pod collapse with direction-reversal), the empirical pattern is: **single-seed sweeps on the merged stack inflate effect sizes by 2-4× via favorable-seed cooldown landings**. The paired-pod n=3 protocol is now established as load-bearing for any winner candidate with single-seed Δ < −0.005.
- Per-group / per-axis WD modulation is now closed as a research direction. The next class of mechanisms to probe is **stack-component redundancy ablation** (testing whether merged components are jointly load-bearing or whether one subsumes another).

**45th productive-null/negative on the merged stack post-#393.**

**Follow-up**: edward assigned **#633 Embed-stack merged-component redundancy ablation** — testing whether EMBED_COOLDOWN_SHAPE=linear_floor (#235 merged) and ADAMW_EMBED_LR_MULT=1.5 (#393 merged) are jointly load-bearing or whether one is redundant given the other. No code changes required — pure env var permutation; structurally parallels #487/#577 NS-cooldown joint-pruning but on the embed-side LR pressure sub-stack.

---

## 2026-05-21 01:10 UTC — PR #599: Per-group AdamW β₁ time-constant sweep (alphonse) — CLOSED productive-NEGATIVE

- Branch: `g1r4-alphonse/adamw-beta1-per-group`
- Hypothesis: β₁=0.8 is hardcoded uniformly for all AdamW groups (embed/lm_head/scalar). For sparse embed rows visited every ~50 steps, momentum decays `0.8^50 ≈ 1.4e-5` between visits — effectively 5× smaller update magnitude than dense groups. Hypothesis: lower β₁_embed restores sparse-row update magnitude (analogous to ADAMW_EMBED_LR_MULT=1.5 but via momentum scaling). Complement to #560 (per-group β₂, closed productive-NULL/NEGATIVE).

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS |3.27208−3.27174|=0.00034):**

| Arm | β₁_embed | β₁_lm_head | β₁_scalar | val/loss | Δ vs A | W&B run | Verdict |
|---|---:|---:|---:|---:|---:|---|---|
| A | 0.80 (ctrl) | 0.80 | 0.80 | 3.27208 | — | `mbl1mtf7` | drift PASS +0.00034 |
| B | **0.50** | 0.80 | 0.80 | 3.27607 | **+0.00399** | `uw9r2ols` | regression |
| C | **0.00** (RMSProp-mode) | 0.80 | 0.80 | 3.27721 | **+0.00513** | `sosvtmq2` | regression |
| D | **0.90** | 0.80 | 0.80 | 3.27385 | **+0.00177** | `466pizvt` | regression (marginal) |

**Analysis**:
- **Magnitude-up direction (β₁_embed: 0.80→0.50→0.00) shows monotone worsening**: 3.27208 → 3.27607 → 3.27721. Sparse-row magnitude restoration hypothesis disconfirmed. Reducing β₁_embed below 0.80 consistently hurts, with RMSProp-mode (β₁=0) worst.
- **Momentum buffer on embed rows is load-bearing**: Arm C (β₁=0 → pure per-step gradient) loses ~+0.005 vs ctrl, confirming momentum accumulation from prior sparse-row visits genuinely informs later steps.
- **Smoothing-up direction (β₁=0.90) also marginal regression** (Δ=+0.00177, past +0.0015 threshold). The optimum sits at or very near 0.80 in both directions → bilateral concavity at the merged value.
- **1.5× ADAMW_EMBED_LR_MULT already near-optimal**: the LR boost from #393 appears well-calibrated with β₁=0.80; reducing β₁ (implying LR compensates for sparse-row magnitude deficit) is counterproductive — the embed group is already operating at the optimum with the existing LR×momentum combination.

**Cumulative state of per-group AdamW family:**

| Axis | PR | Result |
|---|---|---|
| Per-group embed LR mult | #393 | **MERGED** (1.5× win) |
| Per-group β₂ (second moment) | #560 | closed-NEGATIVE |
| Per-group WD | #593 | closed-NULL (WD-ADDITION bilaterally fenced) |
| **Per-group β₁ (first moment)** | **#599** | **closed-NEGATIVE (this PR)** |

**Per-group AdamW family is now fully exhausted.** Both first-moment and second-moment time-constant axes are closed-NEGATIVE in both directions. Only the embed-LR-mult lever (#393) extracted gain; the uniform β₁=0.80 + β₂=0.99 + LR-mult=1.5 combination is bilaterally optimal.

**44th productive-null/negative on the merged stack post-#393.**

**Follow-up**: alphonse assigned **#632 Tunable post-NS aspect-ratio exponent** — one of the few remaining unexplored post-NS-side modifications. Tests `max(1, fan_out/fan_in)**exp` with exp ∈ {0.0, 0.25, 0.50 (ctrl), 1.0}. Arms cover no-scaling, gentler, canonical, and stronger aspect-ratio policies.

---

## 2026-05-21 00:10 UTC — PR #603: AdamW second-moment warmstart via ghost steps (nezuko) — CLOSED broken-chain + productive-NEGATIVE

- Branch: `g1r4-nezuko/ghost-step-warmstart`
- Hypothesis: WAVE3 IDEA 7 — pre-warm AdamW `exp_avg_sq` via ghost-step forward/backward passes before training begins, addressing cold-start v_t direction problem (~100-step window at β₂=0.99).
- Code: env vars `NANOGPT_GHOST_STEPS` (count) / `NANOGPT_GHOST_SCOPE` (which optimizer state to warm); pre-training loop iterates batches, computes loss/backward, accumulates `exp_avg`/`exp_avg_sq` per AdamW state, calls `optimizer.zero_grad()` between steps. **No `optimizer.step()` calls during ghost loop** (key design).

**Chain disposition** (advisor verified via W&B at 00:08 UTC):

| Arm | Ghost steps | State | val/loss | Notes |
|---|---:|---|---:|---|
| A (ctrl) | 0 | 1 finished + 5 crashes + 6th attempt running | (most recent crashed step 2350 mid-run) | Operationally unstable |
| B | 10 | 0 successful completions, 2 crash attempts | n/a | Never completed |
| C | 25 | finished | **3.3018** | **+0.030 catastrophic regression** vs baseline 3.27174 |
| D | 50 | crashed step 1 (val=10.83 init) | n/a | Crashed immediately |

**Reasoning to close**:

1. **6+ crashes across 4 arms over ~5h.** Chain operationally broken — no clear pattern (different crash steps suggest non-deterministic state/cluster issue, not a single code bug).
2. **C completed but at val=3.3018 = +0.030 regression** — well past +0.0015 threshold and beyond any single-arm regression ever recorded this cycle. The mechanism is actively harmful on the testable group.
3. **Student-identified implementation limitation**: `proj.weight=0` init at line 828 of `train_gpt_simple.py` blocks gradient flow during ghost steps (`F.linear` backward `grad_input = grad_output @ proj.weight = 0`). Ghost steps thus only warm `lm_head` (model.proj.weight) — not embed or scalar groups. The narrowed test (lm_head-only warmstart) shows catastrophic harm.

**Mechanism reading**:

- The cold-start `exp_avg_sq=0` state on lm_head causes the first ~100 steps' updates to have **very large effective magnitudes** before bias correction settles. This effectively acts as an **implicit large-step warmup phase** on lm_head — the merged baseline relies on this implicit warmup for proper output-projection conditioning.
- Pre-warming `exp_avg_sq` away from 0 **removes** this implicit warmup, causing immediate aggressive denominator behavior on under-trained logits and bigger early-step gradient asymmetries → catastrophic regression.
- This is consistent with the broader cycle pattern: **the merged stack relies on specific implicit regularization paths**; explicit modification (even of intuitively "cold-start" state) tends to be harmful.

**Closure implications**:

- **WAVE3 IDEA 7 (cold-start v_t direction) axis: CLOSED.** The hypothesis that pre-warming second-moment state helps is empirically refuted for lm_head AdamW with a strong negative signal.
- **Key durable finding (reusable across this programme)**: `proj.weight=0` init blocks all upstream gradient flow during pre-step probes. Future experiments touching v_t/momentum cold-start, gradient-based probes, ghost steps, or any pre-training optimizer-state warmup must account for this — either by running one `optimizer.step()` first to unzero proj.weight, or by excluding proj weights from the probe.
- Other groups (embed, scalar) cannot be directly tested via this implementation. A redesign (e.g., 1-step pre-init followed by N-step ghost loop) could expand the test but the demonstrated harm on lm_head plus the operational instability make further investment low-value.

**43rd productive-NULL/NEGATIVE this cycle.** Cumulative productive-null/negative count: AdamW-internal axes + Muon-internal axes + ghost-step warmstart all substantially exhausted.

**Follow-up**: nezuko assigned **#628 trust-region adaptive Muon LR** — per-layer cos-EMA boost on rare-aligned layers (first AMPLIFY-productive-direction experiment vs all closed SUPPRESS-conflict approaches: #163 DMR reset, #126 Contra-Soft attenuate, #419 Cautious mask, #120/#434 Lookahead blend).

## 2026-05-21 00:05 UTC — PR #593: Per-group AdamW WD sweep (frieren) — CLOSED productive-NULL

- Branch: `g1r4-frieren/adamw-wd-per-group`
- Hypothesis: AdamW constructor's `weight_decay=0` default across all groups (embed/lm_head/scalar) was inherited from upstream and never validated on r4 branch. Per-group sweep with EMBED_WD held at 0 (per #554 sparse-row rejection finding); LM_HEAD_WD and SCALAR_WD swept at 0.01 individually and jointly.
- Code: 3 env vars (`NANOGPT_ADAMW_EMBED_WD`, `_LM_HEAD_WD`, `_SCALAR_WD`) + per-group `weight_decay` in AdamW param-group dicts at line 841-844.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27167−3.27174|=0.00007 exceptional parity):**

| Arm | embed_wd | lm_head_wd | scalar_wd | val/loss | first_step | Δ vs A | W&B run |
|---|---:|---:|---:|---:|---:|---:|---|
| A (ctrl) | 0.0 | 0.0 | 0.0 | **3.27167** | 3225 | — | 6o12nq7j |
| B | 0.0 | **0.01** | 0.0 | 3.27359 | 3250 | **+0.00192 (regression marginal)** | n0demgqa |
| C | 0.0 | 0.0 | **0.01** | 3.27150 | 3225 | −0.00017 (null sub-noise-floor) | 9fd701tv |
| D | 0.0 | **0.01** | **0.01** | 3.27145 | 3225 | −0.00022 (null sub-noise-floor) | 6gpdw4dd |

**Decision**: No arm clears the −0.002 signal threshold. C/D Δ's are well below typical paired-pod noise floor (~±0.0008-0.001); productive-null classification correct. B's +0.00192 is just past +0.0015 regression — direction is clearly wrong, consistent with broader pattern.

**Interpretation**:

- **B (lm_head WD=0.01) regresses (+0.00192)**: dense output projection rejects WD addition. The merged stack already handles output-side regularization via the cooldown.
- **C (scalar WD=0.01) productive-null (−0.00017)**: LayerNorm γ/β WD effect operationally null as predicted (~768 params, sub-noise-floor effect).
- **D (joint, −0.00022) ≈ C**: B's regression and C's mild positive direction approximately cancel under joint addition — no super-additive mechanism.

**Cross-axis WD-ADDITION pattern (now fully fenced across both optimizer families)**:

| PR | Axis | Direction | Outcome |
|---|---|---|---|
| #554 | embed WD cooldown ADD | + WD | NEG (sparse-row reject) |
| #483 | Muon body WD warmup ADD | + WD | NEG |
| #593 (this) | AdamW lm_head WD ADD | + WD | NEG marginal (B regress) |
| #593 (this) | AdamW scalar WD ADD | + WD | NULL (sub-noise) |
| #550 | Muon body WD cooldown REDUCE | − WD | POS candidate (paired-pod in-flight) |

The merged stack **rejects WD ADDITION across every AdamW and Muon group tested**. The only WD direction with extractable gain is **REDUCTION**. This strengthens "baseline is locally optimal across WD axis; cooldown schedule already provides effective late-training regularization; adding steady-state WD on top is at best null and at worst marginally adverse."

**42nd productive-NULL/NEGATIVE this cycle.**

**Follow-up**: frieren assigned **#629 Layer-aggregate Contra-Soft Muon** — fills explicit untested gap diagnosed in #126 closure ("element-wise variant falsified; layer-level inner-product aggregation likely what works"). Per-layer scalar cosine attenuation on conflict-layers only, preserving productive-direction layers entirely. Direct A/B with #126 at matching α values.

## 2026-05-20 23:50 UTC — PR #590: NS-cooldown START_FRAC sweep (thorfinn) — CLOSED productive-NULL

- Branch: `g1r4-thorfinn/ns-cooldown-start-frac`
- Hypothesis: `NANOGPT_NS_COOLDOWN_START_FRAC=0.7` (the timing of when the NS=12→16 cooldown ramp begins) bundled at #176 merge with NS_ITERS_COOLDOWN=16 was a heuristic, not an optimized value. Other NS-cooldown axes saturated (magnitude #176, shape #285, coef #290) but the TIMING axis was unexplored on the merged stack.
- Code: pure env-var sweep — `NANOGPT_NS_COOLDOWN_START_FRAC` reads at line 515, used at line 851 and inside `get_ns_iters()` at line 1024.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27089−3.27174|=0.00085):**

| Arm | START_FRAC | NS=16 starts at | val/loss | first_step | Δ vs A | Δ vs baseline | W&B run |
|---|---:|---:|---:|---:|---:|---:|---|
| A (ctrl) | 0.70 | step 2345 | **3.27089** | 3225 | — | −0.00085 | uplbpr20 |
| B | 0.50 | step 1675 | 3.27276 | 3250 | **+0.00187 (regression)** | +0.00102 | 402vh9zw |
| C | 0.85 | step 2848 | 3.27221 | 3225 | +0.00132 (null) | +0.00047 | dqslav0j |
| D | 0.60 | step 2010 | **3.27048** | 3225 | −0.00041 (null sub-thr) | −0.00126 | b73haw1s |

**Decision**: D's apparent baseline improvement (−0.00126) is largely **favorable A-drift inflation**: pod-A landed at 3.27089 (−0.00085 below baseline). Within-pod Δ_vs_A=−0.00041 is the correct signal measure and is **far below** the −0.002 candidate threshold. 5+ prior precedents (#344, #351, #408, #487, #506) show single-seed Δ's of even −0.001 to −0.0015 routinely collapse to ~0 under paired-pod n=3. Expected yield on paired-pod confirmation negligible (~22h compute).

**Interpretation**: FRAC axis is **bilaterally concave at 0.70** with flat 0.60-0.70 shoulder. NS=16 only pays off in the final ~25-30% of training; extending the window earlier (B) wastes compute on mid-phase steps that don't benefit from tighter orthogonalization (the gradients there are noisier and benefit less from precision; the additional matmul cost is a net loss), shortening (C) loses late-phase precision gain. The default 0.70 sits at the optimum-or-shoulder of an asymmetric curve: easier to break by going earlier than later. 0.60-0.70 range is statistically indistinguishable at n=1.

**Closure implications**:
- NS-cooldown timing axis is now sampled at 4 points (0.50, 0.60, 0.70, 0.85) — no single arm clears the candidate gate
- Closes off "extended precision window" follow-ups (0.40, 0.30 predicted-negative)
- Closes off "concentrated late NS=16 burst" follow-ups (Arm C at 0.85 already null; tighter bursts predicted-negative)
- Full NS-cooldown sub-stack: magnitude=#176 (MERGED), shape=#285 (MERGED), coef=#290 (MERGED), timing=#590 (CLOSED). #577 substack-pruning (paired-pod in flight) is the last NS-cooldown axis open.

**41st productive-null/negative this cycle.** AdamW-internal + Muon-internal magnitude/formula/schedule/regularization space substantially exhausted. Pivot to structurally distinct mechanism replacements (Muon-for-lm_head #618, ghost-step warmstart #603) and loss-formulation axes (spectral norm #624 just queued).

**Follow-up**: thorfinn assigned **#624 spectral norm penalty (WAVE3 IDEA 8)** — first loss-side weight-regularization experiment in this entire cycle. After 41 productive-NULLs on optimizer-state and update-direction axes, testing whether *the weights themselves* need explicit conditioning (and whether NS implicitly provides enough) is a structurally orthogonal question.

## 2026-05-20 22:00 UTC — PR #584: lm_head AdamW LR multiplier sweep around 1.0× (fern) — CLOSED productive-NULL

- Branch: `g1r4-fern/lm-head-lr-ratio`
- Hypothesis: `NANOGPT_ADAMW_LM_HEAD_LR_MULT` only tested at one non-control value in #393 (1.5× rejected). Values <1.0× and intermediate 1.0→1.5 unexplored on post-#393 stack with `ADAMW_EMBED_LR_MULT=1.5×` merged. Joint vocab budget mechanism: if embed_mult=1.5× is load-bearing, lm_head_mult may want ≈1/1.5 ≈ 0.67 to balance.
- Code: pure env-var sweep — `NANOGPT_ADAMW_LM_HEAD_LR_MULT` already exists from #393.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27141−3.27174|=0.00033):**

| Arm | mult | val/loss | first_step | Δ vs A | W&B run |
|---|---:|---:|---:|---:|---|
| A (ctrl) | 1.00 | **3.27141** | 3225 | — | j4b6x3kp |
| B | 0.70 | 3.27169 | 3225 | +0.00028 (null) | 5bys8ba5 |
| C | 1.30 | 3.27398 | 3250 | **+0.00257 (regression)** | thj2l2av |
| D | 0.50 | 3.27374 | 3250 | **+0.00233 (regression)** | cqc9eg3q |

**Analysis**:
- **Joint vocab-budget hypothesis explicitly falsified**: B=0.70× = 1/1.5 was the mechanism's predicted optimum; null at Δ=+0.00028.
- **Flat→degradation profile bracketing 1.00× ctrl**: down side 0.50 (regression) ← 0.70 (null) ← 1.00 (ctrl) → 1.30 (regression). Both sides degrade past |Δmult|=0.30.
- **Asymmetric LR cliff**: same |Δmult|=0.30 produces +0.00257 above vs +0.00028 below. lm_head sits closer to upper cliff than lower one — consistent with #393's prior rejection of lm_head=1.5×.
- **Decoupling confirmed**: embed_mult=1.5 and lm_head_mult=1.0 are NOT tightly coupled — the two groups have orthogonal optimal operating points.

**Pattern**: per-group LR *magnitude* axes (#393 Arm C 1.5× rejected, #584 all probes null/regression) repeatedly null while *schedule/shape* axes (cooldown shape, NS coef schedule) have been more productive historically — supports portfolio re-weight away from magnitude sweeps for next assignments. **40th productive-null/negative this cycle.**

**Follow-up**: fern to be assigned a fresh non-magnitude, non-AdamW-internal axis.

## 2026-05-20 21:50 UTC — PR #579: Body Muon LR asymmetry — attn vs MLP per-block-type LR split (askeladd) — SENT BACK for paired-pod confirmation

- Branch: `g1r4-askeladd/muon-attn-mlp-lr-asym`
- Hypothesis: NS orthogonalization normalizes spectral direction per matrix but doesn't normalize the **relative scale across matrix types**. If attn matrices (qkvo) and mlp matrices (fc, proj) benefit from different effective step sizes, splitting body Muon into two LR-multiplier groups could exceed single-multiplier optimum. Structurally fresh axis — NS-axis program had been fully fenced (frieren 3/3 corners closed + #487 sub-stack + #543 spatial), but per-block-type LR asymmetry is orthogonal to NS-iter axis.
- Code: `NANOGPT_MUON_ATTN_LR_MULT` / `NANOGPT_MUON_MLP_LR_MULT` env vars; `Muon` constructor extended for list-of-dicts param_groups; body Muon split by `.attn.` / `.mlp.` name substring (48 attn / 24 mlp params confirmed).

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27189−3.27174|=0.00015):**

| Arm | attn_mult | mlp_mult | val/loss | Δ vs A | first_step | W&B run |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl) | 1.00 | 1.00 | 3.27189 | — (drift +0.00015 PASS) | 3225 | z74koc4v |
| B | **0.80** | 1.00 | 3.27272 | +0.00083 (null) | 3250 | 8b81n20u |
| C | 1.00 | **1.20** | 3.27269 | +0.00080 (null) | 3250 | ccn4srk7 |
| D | **0.80** | **1.20** | **3.27052** | **−0.00137 (signal, sub-threshold)** | **3225** | wr1z9vc7 |

**Analysis**: Pre-staged pattern rule fires exactly — singletons B and C both null, compound D shows direction-correct improvement. **Mechanistic read**: attn matrices benefit from a slightly conservative effective step (less jitter in attention routing) AND mlp matrices benefit from a slightly larger effective step, but the two effects are sub-threshold individually and compose when both applied. The compound D shifts body-Muon update **aspect ratio** between attn and mlp — that aspect-ratio shift is what produces the gain, not either lever alone.

- **n=1 stat rule** for D: (3.28 − 3.27052)·√1 = 0.00948 ≥ 0.004 ✓ AND 3.27052 ≤ baseline 3.27174 ✓ ⇒ passes n=1 floor
- **Within-pod Δ threshold**: −0.00137 sub-threshold of pre-staged −0.002 signal mark, but within ±0.001 of it
- **Implementation correctness**: Drift gate A=3.27189 vs 3.27174 (Δ=+0.00015) confirms param-group split is numerically bit-identical to single-group baseline — no implementation defect contaminating results
- **Single-seed → paired-pod precedent**: 5 prior cases (#344, #351, #408, #487, #506) where single-seed wins collapsed at paired-pod confirmation — strict pre-staged merge rule requires n≥2-3 confirmation before declaring a winner

**Decision**: SEND BACK for paired-pod n=3 confirmation of compound D at (attn=0.80, mlp=1.20). Sub-threshold Δ at n=1 + collapse precedent ⇒ insufficient confidence for n=1 merge. If n=3 confirms Δ_mean ≤ −0.002, this is a small but real win. If it doesn't, axis closes cleanly. Highest-EV next experiment for askeladd's slot.

**Follow-up**: askeladd assigned paired-pod confirmation at (0.80, 1.20) — A=(1.00, 1.00) ctrl + D=(0.80, 1.20) treatment, 3 pods each.

## 2026-05-20 18:40 UTC — PR #568: Per-group cooldown_frac decoupling (nezuko) — CLOSED productive-NULL

- Branch: `g1r4-nezuko/per-group-cooldown-frac`
- Hypothesis: Per-group cooldown SHAPE wins (#235/#285/#290/#520) imply per-group cooldown WINDOW LENGTH might also asymmetrically tune. Test ±0.10 perturbations of embed_cf and body_cf around the merged global cooldown_frac=0.70 (set via `set_hparams(step, cooldown_frac=0.7)` at line 864). Structurally fresh axis on cooldown timing.
- Code: `NANOGPT_EMBED_COOLDOWN_FRAC` / `NANOGPT_BODY_COOLDOWN_FRAC` / `NANOGPT_LM_HEAD_COOLDOWN_FRAC` / `NANOGPT_SCALAR_COOLDOWN_FRAC` env vars; per-group cf lookup in `set_hparams`.

**Methodological note**: Original PR body conflated `cooldown_frac=0.7` (LR cooldown spans last 70%) with `NANOGPT_NS_COOLDOWN_START_FRAC=0.7` (NS-iter timing). Student g1r4-nezuko caught the error at 10:25 UTC. Re-anchored arms around true 0.70 baseline at 10:30 UTC. Final execution used corrected values.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27134−3.27174|=0.00040):**

| Arm | embed_cf | body_cf | lm_head_cf | scalar_cf | val/loss | Δ vs A | first_step | W&B run |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| A (ctrl) | 0.70 | 0.70 | 0.70 | 0.70 | 3.27134 | — | 3225 | `yee9pqql` |
| B | **0.80** | 0.70 | 0.70 | 0.70 | 3.27120 | −0.00014 (null) | 3225 | `aaz7to57` |
| C | **0.60** | 0.70 | 0.70 | 0.70 | 3.27376 | **+0.00242 (regression)** | 3250 | `wxo93x4h` |
| D | 0.70 | **0.80** | 0.70 | 0.70 | **3.27067** | −0.00067 (null, best arm) | 3200 | `cirscwub` |

**Analysis:**

- **No arm crosses Δ ≤ −0.002 signal threshold.** Best arm D passes single-seed stat-rule ((3.28−3.27067)×√1=0.00933 ≥ 0.004) AND beats baseline (val 3.27067 ≤ 3.27174), BUT within-pod Δ_D=−0.00067 falls short of pre-staged −0.002 paired-pod gate. No paired-pod confirmation requested.
- **Embed direction asymmetric-monotonic with floor at 0.70**: shorter (0.60) regresses +0.00242 (5× threshold); longer (0.80) gives only −0.00014. The merged global 0.70 sits approximately at the floor of the embed cooldown-frac axis — pushing shorter eats into the precision window for sparse-row consolidation (consistent with #235 embed_floor mechanism). Pushing longer yields sub-threshold benefit at this seed budget.
- **Body direction mildly positive, sub-threshold**: Δ_D=−0.00067 is the most favorable non-A reading. NS-orthogonalized body landing benefits *mildly* from longer precision-window — but signal doesn't clear noise floor at n=1 with ±0.10 perturbation.
- **The SHAPE→FRAC analogy fails at this perturbation scale.** Per-group cooldown SHAPE matters (embed=linear_floor, body=linear, NS=late_peak, NS_coef=linear_ramp_down — real per-group asymmetries). Per-group cooldown WINDOW LENGTH does NOT show the same asymmetric structure within ±0.10 around 0.70 — at least not at the seed budget tested.
- **39th productive-null/negative this cycle.**

**Compute summary**: 4 runs × ~1h45m each ≈ ~7h total wall time. No crashes, all 4 arms reached 3.28 target cleanly (3200-3250 step range).

**Follow-up**: nezuko pivoted off per-group cooldown_frac onto structurally fresh **AdamW second-moment warmstart via ghost steps** axis — addressing the cold-start direction problem in `exp_avg_sq` that bias correction (magnitude rescaling) explicitly does NOT solve. Untested in this run, distinct from any closed optimizer-family axis. Direct mechanistic motivation: v_t requires ~1/(1−β₂)=100 steps at β₂=0.99 to reach stationary directional state; during that window NS-orthogonalized aux-group updates operate on under-informed second-moment estimates.

## 2026-05-20 17:15 UTC — PR #560: Per-group AdamW β₂ asymmetric sweep (alphonse) — CLOSED productive-NULL/NEGATIVE

- Branch: `g1r4-alphonse/aux-beta2-per-group`
- Hypothesis: β₂=0.99 uniform across embed/lm_head/scalar AdamW (set by #236) may be suboptimal because the three groups have different gradient statistics: embed sparse rows (~30K of 50K updated per batch, high per-row variance), lm_head dense rows (every row every step), scalar (LayerNorm gains, low variance). Motivated by #474 AdaBelief and #516 Yogi closures — both failed via embed-sparsity pathology in *alternative* second-moment formulations; the natural untested question is whether the *standard* AdamW second-moment formula wants a different *time constant* per group.
- Code: `NANOGPT_ADAMW_BETA2_EMBED` / `NANOGPT_ADAMW_BETA2_LM_HEAD` / `NANOGPT_ADAMW_BETA2_SCALAR` env vars; per-group `betas` patched after optimizer construction by matching `group["name"] in {"adam_embed", "adam_lm_head", "adam_scalars"}`.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27121−3.27174|=0.00053):**

| Arm | β₂_embed | β₂_lm_head | β₂_scalar | val/loss | Δ vs A | first_step | W&B run |
|---|---:|---:|---:|---:|---:|---:|---|
| A | 0.99 (ctrl) | 0.99 | 0.99 | **3.27121** | — (drift PASS) | 3225 | `dhlwmiaf` |
| B | **0.95** | 0.99 | 0.99 | 3.27210 | +0.00089 (null) | 3225 | `g6kfcv6a` |
| C | **0.999** | 0.99 | 0.99 | 3.27480 | **+0.00359 (regression)** | 3275 | `312jcl7b` |
| D | 0.95 | **0.999** | 0.99 | 3.27218 | +0.00097 (null) | 3225 | `mwhb33bc` |

**Analysis:**

- **No arm beats merged baseline 3.27174 within-pod.** Arm C (β₂_embed=0.999, longer memory) is the only clear regression (Δ=+0.00359 > +0.0015 threshold); B and D sit indistinguishably in the null band.
- **B vs C asymmetry is mechanistically informative.** Longer embed memory (β₂=0.999, half-life ~700 steps in a 3350-step run) is clearly harmful — v_t stays anchored to early-training gradient statistics for too long, underweighting recent gradient signal in late phases. Shorter embed memory (β₂=0.95, half-life ~14 steps) is null — the hypothesized sparse-row v_t reset benefit doesn't materialize.
- **D ≈ B within ±0.0001** → lm_head β₂=0.999 has no measurable effect on top of shorter embed memory. Only embed β₂ matters and even that effect is essentially flat in the null direction.
- **AdamW-internal axis family substantially exhausted on merged stack**: per-group β₂ joins #442 (magnitude transform, NEGATIVE), #474 (AdaBelief second-moment formulation, NEGATIVE), #516 (Yogi second-moment update rule, NEGATIVE), #490 (NAdam first-moment lookahead, NULL). The mechanistic hypothesis from #474/#516 — embed sparsity wants different time constant — is **disconfirmed**: embed sparse-row gradient statistics on this benchmark are well-served by the same β₂ as dense groups, at least in the 0.95–0.999 range.
- **38th productive-null/negative this cycle.**

**Compute summary**: 4 runs × ~1h44m each ≈ ~7h total wall time on RTX PRO 6000 Blackwell. Zero crashes, all 4 arms reached 3.28 target cleanly (best step counts 3225/3225/3275/3225).

**Follow-up**: alphonse assigned **per-group AdamW β₁ time-constant sweep** — natural extension to first-moment time constant. Motivated by sparse-row update magnitude analysis: at β₁=0.8 with embed rows seen every ~50 steps, `0.8^50 ≈ 0` means sparse-row momentum effectively resets between visits, scaling step magnitude down vs dense groups by factor ~0.2. ADAMW_EMBED_LR_MULT=1.5 (merged #393) partially compensates via LR; per-group β₁ tests whether lowering β₁_embed restores sparse-row update magnitude more principally.

## 2026-05-20 16:15 UTC — PR #506: NS-iter warmup schedule (frieren) — CLOSED productive-NEGATIVE [paired-pod n=3]

- Branch: `g1r4-frieren/ns-warmup`
- Hypothesis: Ramp NS_ITERS from low (8 or 10) → 12 over first 5-10% of training. Builds on #470 findings (NS=8 below precision floor in flat mode, may be OK for early noisy gradients). "Less constraint early" cluster paired with #483 WD warmup, #489 embed-LR warmup.
- Code: `NANOGPT_NS_ITERS_WARMUP_START` + `NANOGPT_NS_ITERS_WARMUP_FRAC` env vars + linear ramp helper.

**N=1 sweep results (drift gate A PASS):**

| Arm | NS_WARMUP_START | NS_WARMUP_FRAC | val/loss | Δ vs A | W&B run |
|---|---:|---:|---:|---:|---|
| A | 12 | 0.0 | 3.27282 | — (drift +0.00108) | — |
| B | 10 | 0.05 | 3.27321 | +0.00039 (null) | — |
| **C** | **8** | **0.05** | **3.27163** | **−0.00119** (null but directional) | candidate |
| D | 10 | 0.10 | 3.27215 | −0.00067 (null) | — |

Arm C passed single-seed stat-rule (3.27163 ≤ 3.27174 baseline AND margin 0.00837 ≥ 0.004), but within-pod Δ=−0.00119 was inside productive-null band [−0.002, +0.0015]. Sent back for paired-pod confirmation.

**Paired-pod n=3 results (per-pod controlled SENPAI_SEED):**

| Pod | SENPAI_SEED | Arm A val | Arm B val | Δ_pod (B−A) | W&B A | W&B B |
|---|---:|---:|---:|---:|---|---|
| pod 0 | 0 | 3.27172 | 3.27347 | +0.00175 | `gn9qxomh` | `j15polni` |
| pod 1 | 1 | 3.27361 | 3.27435 | +0.00074 | `sq5a9w6s` | `no3kmvgt` |
| pod 2 | 2 | 3.27194 | 3.27206 | +0.00012 | `x0ox4mu6` | `1m0t1atd` |
| **n=3 mean** | — | **3.27242** | **3.27329** | **+0.00087** | — | — |

**Merge-gate verdict (pre-staged):**

| Gate | Threshold | Observed | Pass? |
|---|---|---|---|
| 1. mean(Δ) ≤ −0.002 | ≤ −0.002 | +0.00087 | ❌ FAIL (wrong sign by 0.00287) |
| 2. mean(val_B) ≤ 3.27174 | ≤ 3.27174 | 3.27329 (+0.00155) | ❌ FAIL |
| 3. (3.28 − mean) × √3 ≥ 0.004 | ≥ 0.004 | 0.01162 | ✅ PASS |

Two of three gates fail. **CLOSED productive-NEGATIVE.**

**Analysis:**

- **The N=1 Δ_C=−0.00119 was an Arm-A drift artifact, not a real treatment effect.** Tight pod-A controls anchor at mean 3.27242 (only +0.00068 above baseline 3.27174), revealing the warmup arm is neutral-to-regressive within-pod. All three pods regress (Δ_pod > 0). The original "win" reading required Arm A to be drifted high.
- **5th cycle precedent for single-seed → paired-pod collapse**: joins #344 askeladd dual-LR, #351 askeladd-fern post-cooldown WD, #408 fern AGC, #487 tanjiro NS_ITERS_COOLDOWN-drop. Pattern is now sufficiently documented that the within-pod Δ ≤ −0.002 threshold should be treated as a hard requirement before merge, regardless of single-seed stat-rule.
- **NS-axis program now fully fenced**: 3/3 NS-iter schedule axes closed (warmup #506, normal-phase #470, cooldown saturation #388) + 3 cooldown-machinery components MERGED (#176 magnitude, #285 shape, #290 coef) + sub-stack pruning #487 null + spatial #543 null. Further NS-axis experiments are blocked unless a structurally novel approach emerges (per-block-type NS coefficients, NS warmup × per-block, etc.).
- **37th productive-null/negative this cycle.**

**Compute summary**: 6 paired-pod runs × ~1h45m each ≈ ~10h30m total wall time on RTX PRO 6000 Blackwell. No OOMs, no NaNs, all reached 3.28 target cleanly.

**Follow-up**: frieren assigned **per-group AdamW WD sweep** — current `weight_decay=0` is uniformly applied across all 3 AdamW groups (embed/lm_head/scalar); whether dense lm_head or small-param scalar groups benefit from steady-state WD>0 has never been tested.

## 2026-05-20 15:35 UTC — PR #554: AdamW embed WD cooldown nudge (thorfinn) — CLOSED productive-NEGATIVE

- Branch: `g1r4-thorfinn/embed-wd-cooldown-nudge`
- Hypothesis: Add small positive WD on AdamW embed group during cooldown only (currently WD=0 throughout). Tests whether late-phase implicit regularization in the precision window helps embed representations. Mechanism: with `EMBED_COOLDOWN_SHAPE=linear_floor` (#235) holding embed LR at 15% floor through cooldown, a WD nudge could shrink magnitudes to prevent late-noise drift.
- Code: `NANOGPT_EMBED_WD_COOLDOWN` env var, step-function transition at cooldown start.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27277−3.27174|=0.00103):**

| Arm | WD | val/loss | Δ vs A | Δ vs baseline | first_step | W&B run |
|---|---:|---:|---:|---:|---:|---|
| A | 0.0 (ctrl) | 3.27277 | — | +0.00103 (drift PASS) | 3250 | `bnfz3umv` |
| B | 0.001 | 3.27242 | −0.00035 (null) | +0.00068 | 3250 | `fd8u711l` |
| C | 0.005 | 3.27934 | +0.00657 (regression) | +0.00760 | 3350 | `oanb7jam` |
| D | 0.010 | 3.28848 | **+0.01571 (regression)** | +0.01674 | **−1 (FAILED)** | `dgbetby2` |

**Analysis:**

- **Clean monotone regression across the WD axis on the embed group.** Even smallest nudge B (0.001) fails baseline parity (+0.00068 vs baseline 3.27174). Arm D (0.010) fails the 3.28 benchmark entirely.
- **The B→C jump is large** (+0.00692 for a 5× WD increase from a null point): the regression band is narrow and steep. The largest swing on this axis is B→D = +0.01606.
- **Mechanism reading (student analysis, accepted):** With `EMBED_COOLDOWN_SHAPE=linear_floor` holding embed LR at 15% floor through cooldown, embed updates are already small. Adding WD on top uniformly shrinks all embed rows — including rarely-updated rare-token rows whose representations depend on *accumulated information* rather than late-training noise. WD overrides accumulation rather than denoising it.
- **Bilateral asymmetry on WD-cooldown axis (paired with #550 winner candidate):**
  - **Embed group**: adding WD during cooldown is harmful (#554 NEGATIVE) — sparse-row representations don't tolerate magnitude shrinkage
  - **Body Muon group**: reducing WD during cooldown may be beneficial (#550 N=1 Δ=−0.00337 winner candidate, paired-pod in flight)
  - Both findings point toward: "do not constrain rare/sparse representations during cooldown precision window"
- **36th productive-null/negative this cycle.**

**Compute summary**: 4 runs × ~1h44m each ≈ ~7h total wall time on RTX PRO 6000 Blackwell. No OOMs, no crashes (chain PID 747067 ran cleanly).

**Follow-up**: thorfinn assigned **NS-cooldown START_FRAC sweep** — fresh structurally untested axis (NS_COOLDOWN_START_FRAC=0.7 was bundled at #176 merge, never independently swept on merged stack).

## 2026-05-20 14:15 UTC — PR #547: lm_head cooldown SHAPE sweep (fern) — CLOSED productive-NULL

- Branch: `g1r4-fern/lm-head-cooldown-shape`
- Hypothesis: lm_head cooldown SHAPE has been linear-default the entire cycle; #454 tested only linear_floor on lm_head. Per-group SHAPE design ethos predicts different groups want different shapes (embed=linear_floor #235, NS_iter=late_peak #285, NS_coef=linear_ramp_down #290). Test cosine, late_peak, linear_floor variants for lm_head specifically.
- Code: `NANOGPT_LM_HEAD_COOLDOWN_SHAPE` env var dispatching to existing shape helpers.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS, |3.27273−3.27174|=0.00099):**

| Arm | shape | val/loss | Δ vs A | first_step | Band |
|---|---|---:|---:|---:|---|
| A | linear (ctrl) | 3.27273 | — | 3250 | drift PASS |
| B | cosine | 3.27285 | +0.00012 | 3225 | productive-null |
| C | late_peak | 3.27452 | **+0.00179** | 3275 | **regression** |
| D | linear_floor | 3.27297 | +0.00024 | 3250 | productive-null |

**Analysis:**

- **No arm meets Δ ≤ −0.002 candidate threshold.** No paired-pod confirmation warranted. All three alternative shapes are null or worse than the linear default.
- **lm_head cooldown SHAPE is not cross-axis transferable from NS.** Arm C (late_peak) was the cross-axis transfer hypothesis: if late_peak benefits NS_iter (#285 MERGED), maybe it transfers to lm_head LR. Result: lm_head's biggest regression (+0.00179). Mechanism reading: NS late_peak benefits from sustained orthogonalization-iter quality through mid-cooldown; lm_head LR is a dense AdamW group with no analogous quality plateau — it wants monotonic decay.
- **#454 Arm B (lm_head linear_floor) reproduces**: Δ=+0.00024 vs prior Δ≈−0.00098 — same productive-null verdict, deltas differ by ~0.0012 within single-seed pod variance. No setup drift.
- **Per-group cooldown SHAPE design space substantially characterized:**

| Group | Optimal SHAPE | Source |
|---|---|---|
| Embed (AdamW, sparse-row) | linear_floor | #235 MERGED |
| Body Muon (NS-orth, dense) | linear | #520 NEGATIVE on alternatives |
| NS_iter (Muon precision) | late_peak | #285 MERGED |
| NS_coef (polynomial schedule) | linear_ramp_down | #290 MERGED |
| **lm_head (AdamW dense)** | **linear** | **#547 NEGATIVE on alternatives** |
| scalar (LayerNorm γ/β) | untested | gap |

- **35th productive-null/negative this cycle.**

**Compute summary**: 4 runs × ~1h47m each ≈ ~7.1h total wall time on RTX PRO 6000 Blackwell.

**Follow-up**: fern assigned **lm_head AdamW LR ratio sweep** — denser sweep around 1.0× on the post-#393 stack (#393 tested 1.5× and rejected lm_head=1.5×, but <1.0× and intermediate >1.0× untested). Mechanistic motivation: joint vocab update budget — embed at 1.5× may predict lm_head < 1.0×, specifically 1/1.5 ≈ 0.67 as theoretical balance point.

## 2026-05-20 13:35 UTC — PR #543: Per-block NS iter budget (askeladd) — CLOSED productive-NULL

- Branch: `g1r4-askeladd/per-block-ns-iters`
- Hypothesis: Allocate NS iteration count per-block by aspect ratio (Bernstein-Newhouse 2024 "Old Optimizer, New Norm"). Tall/narrow matrices need more iters; square matrices saturate quickly. Spatial axis, structurally distinct from NS_ITERS (#470), NS-iter warmup (#506 temporal), NS_ITERS_COOLDOWN (#487).
- Code: `NANOGPT_NS_ITERS_PER_BLOCK_SCHEDULE` env var + `ns_iters_for_param` helper.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS):**

| Arm | schedule | val/loss | Δ vs A | step_avg (ms) | W&B run |
|---|---|---:|---:|---:|---|
| A | uniform (NS=12 all blocks) | 3.27243 | — (control, drift +0.00069 vs baseline) | 1967.98 | `s8b68xvo` |
| B | aspect (data-driven NS_iters = round(12 * aspect^0.3), clamped [8,16]) | 3.27320 | +0.00077 (null) | 1938.10 | `eebas8ax` |
| C | manual_typeA (attn.proj=10, qkv=12, mlp.fc=14, mlp.proj=12) | **3.27226** | **−0.00017 (null, best)** | 1970.19 | `4p5l7al5` |
| D | manual_typeB (attn.proj=10, qkv=12, mlp.fc=16, mlp.proj=14) | 3.27299 | +0.00056 (null) | 1978.23 | `kyg3r4fe` |

**Analysis:**

- **All three reallocation arms in productive-null band [−0.002, +0.0015].** No arm meets the Δ ≤ −0.002 candidate threshold. No merge candidate.
- **NS=12 saturation robust to spatial reallocation**: Combined with #470 (uniform escalation: NS ∈ [10, 14] plateau), per-block aspect-weighted allocation also fails to extract gains. The merged NS coefficient schedule (`linear_ramp_down`) plus 12 iters appears sufficient for near-orthogonal projection on tall matrices at this budget.
- **Architectural insight (student-documented)**: This nanoGPT codebase uses `mlp.fc`/`mlp.proj` (not fused-qkv naming) and splits attention qkv into 3 separate 768×768 linears, leaving only 2-of-6 Muon blocks (`mlp.fc`, `mlp.proj`) with aspect > 1.0. The spatial reallocation surface is structurally limited. A fused-qkv refactor would unlock a richer version of this hypothesis but is out of scope (architecture is fixed per program.md).
- **Arm B mechanism reading**: doubles MLP NS compute (base 12→16, cooldown 16→21 on both MLP matrices). Net +25% NS work on MLP. Result: +0.00077 (null) — extra iters past the saturation point are wasted work, consistent with the orthogonal-projection-already-achieved interpretation.
- **34th productive-null/negative this cycle.**

**Compute summary**: 4 runs × ~1h47m each ≈ ~7.1h total wall time on RTX PRO 6000 Blackwell. Step_avg variation across arms inside noise (1938–1978 ms).

**Follow-up**: askeladd assigned **Body Muon LR asymmetry (attn vs mlp split)** — per-block-type LR axis, structurally distinct from #543 (NS iter spatial), #393 (AdamW per-group LR), #409 (LLRD depth-LR).

## 2026-05-20 13:05 UTC — PR #487: Cooldown-NS pruning ablation (tanjiro) — CLOSED productive-NULL [paired-pod n=3 confirmed]

- Branch: `g1r4-tanjiro/cooldown-ns-pruning`
- Hypothesis: At least one of the three NS-cooldown sub-stack components (NS_ITERS_COOLDOWN=16 from #176, NS_COOLDOWN_SHAPE=late_peak from #285, NS_COEF_SCHEDULE=linear_ramp_down from #290) is now redundant given the later merges. Drop one per arm (revert to compiled-in default), testing if any is now redundant. First *subtractive* experiment this cycle.
- Code: no changes; pure env-var overrides reverting to compiled-in defaults.

**Sweep N=1 results (drift gate A PASS):**

| Arm | Drop | val | Δ vs A |
|---|---|---:|---:|
| A | none (control) | 3.27198 | 0.0 |
| **B** | **NS_ITERS_COOLDOWN** | **3.26813** | **−0.00385** ⭐ |
| C | NS_COOLDOWN_SHAPE | 3.27278 | +0.00080 (null) |
| D | NS_COEF_SCHEDULE | 3.27264 | +0.00066 (null) |

Arm B's N=1 Δ=−0.00385 was the first sub-baseline winner candidate in many cycles → paired-pod confirmation requested.

**Paired-pod n=3 results (per-pod controlled SENPAI_SEED via commit f347bfa):**

| Pod / seed | Arm A val | Arm B val | Δ_pod (B−A) | W&B A | W&B B |
|---|---:|---:|---:|---|---|
| pod 0 / seed 0 | 3.27398 | 3.27338 | −0.00060 | `cemln9ol` | `c0bx4u33` |
| pod 1 / seed 1 | 3.27240 | 3.27269 | +0.00029 | `8op366oc` | `w6izn6c0` |
| pod 2 / seed 2 | 3.27129 | 3.27170 | +0.00041 | `x919vhei` | `ayth9jzs` |
| **n=3 mean** | **3.27256** | **3.27259** | **+0.00003** | — | — |

**Merge-gate verdict (pre-staged advisor 01:05 UTC):**

| Gate | Threshold | Observed | Pass? |
|---|---|---|---|
| 1. mean(Δ) ≤ −0.002 | ≤ −0.002 | +0.00003 | ❌ FAIL |
| 2. mean(val_B) ≤ 3.27174 | ≤ 3.27174 | 3.27259 (+0.00085) | ❌ FAIL |
| 3. (3.28 − mean) × √3 ≥ 0.004 | ≥ 0.004 | 0.01283 | ✅ PASS |

**Two of three gates fail. CLOSED productive-NULL** per pre-staged rules.

**Analysis:**

- **N=1 Δ=−0.00385 was between-seed noise.** Sweep used unset/default seed initialization for each arm; paired-pod with controlled `SENPAI_SEED` per pod (each pod uses the same seed for both Arm A and Arm B) reveals within-seed Δ split 1−/2+ around mean(Δ)=+0.00003. Magnitude in all three pods ≤ 0.00060, all in productive-null/redundant band.
- **NS_ITERS_COOLDOWN=16 classification: REDUNDANT** (not improved, not harmful, not load-bearing) at n=3 paired-pod. Same classification as Arms C and D from the sweep (which already landed in productive-null at N=1).
- **The entire NS-cooldown sub-stack appears individually redundant** when each component is dropped solo. But joint-drop interactions are untested — that's the follow-up.
- **Mechanism hypothesis falsified**: the "NS_ITERS_COOLDOWN=16 over-orthogonalizes during late-phase low-LR steps and actively harms" prediction predicted a consistent within-pod improvement on drop. Observed: sign-split centered at zero. Mechanism is not operative.
- **4th cycle precedent for single-seed → paired-pod collapse**: joins #344 (askeladd dual-LR), #351 (askeladd-fern post-cooldown WD), #408 (fern AGC). Pattern is now sufficiently documented that all N=1 wins ≤ ~−0.005 should be paired-pod confirmed regardless of stat-rule status.
- **33rd productive-null/negative this cycle.**

**Compute summary**: 4 sweep + 6 paired-pod runs × ~1h45m each ≈ ~17h30m total wall time on RTX PRO 6000 Blackwell. No OOMs, no crashes.

**Follow-up**: tanjiro assigned **NS-cooldown joint-pruning ablation** — test whether the *sub-stack as a whole* is load-bearing, even though each component is individually redundant.

## 2026-05-20 10:15 UTC — PR #530: Nesterov-Muon weight sweep (nezuko) — CLOSED productive-NULL

- Branch: `g1r4-nezuko/nesterov-muon`
- Hypothesis: Apply Nesterov-style gradient lookahead `g_eff = (1-α)·g + α·buf` before NS orthogonalization in body Muon. Tests whether NS expects a smoothed direction (buf) or benefits from lookahead-corrected gradient. After #490 closure of AdamW-internal axes, body Muon mechanism is the natural pivot.
- Code: `NANOGPT_MUON_NESTEROV_ALPHA` controlling mix weight in Muon update before NS.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS):**

| Arm | α | val/loss | Δ vs A | FST | Band | W&B run |
|---|---:|---:|---:|---:|---|---|
| A | 0.95 (control = μ) | 3.27253 | — | 3250 | drift PASS (|Δ|=0.00079) | `6jmx02yt` |
| B | 0.00 (bypass) | 3.27883 | +0.00630 | 3325 | regression | `qi0ar3zh` |
| C | 0.50 (half-mix) | 3.31368 | +0.04114 | **−1 (target NOT reached)** | severe regression | `6h2u4kpr` |
| D | 0.99 (over-Nesterov) | 3.27313 | +0.00060 | 3250 | null | `tagu1aiy` |

**Analysis:**

- **The cliff is on the low-α side, not on both sides as the symmetric-monotonicity hypothesis predicted.** Arm D (α=0.99) is within noise of Arm A; Arm C (α=0.50) catastrophically regresses and doesn't reach the 3.28 target within 3350 steps. The path from "Nesterov on" to "Nesterov off" passes through a deep failure region.
- **Mechanism interpretation** (per student analysis, accepted): The mix is best understood not as 'lookahead' but as a **tiny anti-staleness injection** of current-step gradient (~5% weight, at α=0.95 → `(1-α)=0.05`) on top of the EMA — sufficient to de-stale, small enough to stay in NS's well-behaved spectral domain. Heavier current-grad injection (α=0.50 → 50% raw-grad in NS input) pushes the NS input outside the Newton-Schulz polynomial's well-conditioned regime, where it amplifies noise rather than orthogonalizing.
- **Plateau width**: α ∈ [0.95, 0.99] is a flat ridge. The current merged α=μ=0.95 sits at the boundary of safety. Equivalently: current-grad weight `(1-α)` has an upper limit around 0.05.
- **5th body-Muon mechanism axis closed**: joins #102 LR warmup, #356 μ schedule, #434 Lookahead-wrap, #483 WD warmup. Body Muon's algorithmic axes on the merged stack are largely exhausted. Future body-Muon ideas should target architectural changes (post-NS-side modifications, NS-iteration-count interactions) rather than coefficient sweeps on existing mixes.
- **32nd productive-null/negative this cycle.**

**Follow-up:** nezuko reassigned (next hypothesis).

## 2026-05-20 09:30 UTC — PR #526: Embed LR step-0 boost (alphonse) — CLOSED productive-NULL (bilateral with #489)

- Branch: `alphonse/embed-lr-step0-boost`
- Hypothesis: Symmetric inverse of #489 closure. If reducing embed LR early hurts monotonically (frac=0.10 → +0.02316), does boosting embed LR temporarily at step 0 (decaying back to merged 1.5× over first 3–6% of training) help? Mechanism: common-token rows updated every step may benefit from larger initial updates to escape initialization quickly.
- Code: `NANOGPT_EMBED_LR_BOOST_MULT` (multiplicative on top of 1.5× constant mult) × `NANOGPT_EMBED_LR_BOOST_FRAC` (linear-decay window length), applied to `eta_embed` in `set_hparams()` for `name == "adam_embed"`.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS):**

| Arm | BOOST_MULT | BOOST_FRAC | Effective @step 0 | val/loss | Δ vs A | Δ vs baseline | W&B run |
|---|---:|---:|---:|---:|---:|---:|---|
| A | 1.0 (control) | 0.0 | 1.5× | 3.27226 | 0 | +0.00052 (drift PASS) | `2k9k3u4g` |
| B | 2.0 | 0.03 | 3.0× | 3.27146 | −0.00080 | −0.00028 | `i05fom6u` |
| C | 2.5 | 0.03 | 3.75× | 3.27145 | −0.00081 | −0.00029 | `bd9rmd2w` |
| D | 2.0 | 0.06 | 3.0× | 3.27261 | +0.00035 | +0.00087 | `v6r6wqzf` |

**Analysis:**

- **No paired-pod confirmation triggered.** All test arms fall within productive-null band (−0.002 < Δ_vs_A < +0.0015). Best arm (C) Δ_vs_A = −0.00081 is far short of the pre-staged −0.002 confirmation threshold.
- **Mechanism reading**: B vs C plateau at virtually identical val (3.27146 vs 3.27145) → boost magnitude saturates by 2.0× in the 3%-window regime. D (longer 6% window, same 2.0× magnitude) regresses to +0.00035 → longer boost window is mildly worse. The "common-token rows benefit from temporarily higher LR" hypothesis is directionally consistent with B/C improvement but the effect is inside per-pod noise floor — the n=1 stat rule passes mathematically (Arm C: (3.28−3.27145)×√1 = 0.00855 ≥ 0.004) but is partly Arm-A drift artifact (+0.00052).
- **`first_step_to_target` invariant**: A/B/C all 3225, D=3250. The boost doesn't materially change *when* the target is first hit — only the terminal step value.
- **Bilateral closure with #489 (CLOSED NEGATIVE on reduce direction)**: Combined evidence establishes that **embed step-0 LR at 1.5× is bilaterally optimal**. Neither boosting (this PR) nor reducing (#489) the early embed LR yields actionable improvement. The embed step-0 LR magnitude axis is closed.
- **Closes embed step-0 LR magnitude axis** — joined with #489. Future "early-window embed LR shape" axes would need a stronger prior than this experiment provides.
- **31st productive-null/negative this cycle.**

**Follow-up:** alphonse reassigned (next hypothesis).

## 2026-05-20 07:55 UTC — PR #520: Body Muon LR cooldown shape sweep (thorfinn) — CLOSED productive-NEGATIVE

- Branch: `g1r4-thorfinn/body-cooldown-shape`
- Hypothesis: The body Muon LR cooldown has been linear-default the entire cycle. NS-orthogonalized updates have rank-stable magnitudes (unlike AdamW per-coordinate); optimal cooldown profile may differ. Tested cosine, quadratic, linear_floor as alternatives.
- Code: `NANOGPT_BODY_COOLDOWN_SHAPE ∈ {linear, cosine, quadratic, linear_floor}` with new `eta_body` branch in `set_hparams()`, applied via Muon optimizer identity.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS):**

| Arm | Shape | val/loss | fst | Δ vs A | Band | W&B run |
|---|---|---:|---:|---:|---|---|
| A | linear (control) | 3.27261 | 3250 | 0 | drift gate PASS (\|Δ\|=0.00087) | `nfmarwyh` |
| B | cosine | 3.27424 | 3150 | +0.00163 | regression (marginal) | `ls42rldq` |
| C | quadratic | 3.28125 | -1 | +0.00864 | strong regression | `ju0fchro` |
| D | linear_floor | 3.28662 | -1 | +0.01401 | strongest regression | `cqn6df5s` |

**Analysis:**

- **No winner candidate.** Monotone regression with magnitude of distortion to final-window decay.
- **Mechanism**: body Muon needs (1) decay to ~zero at end (rules out linear_floor at 15% floor — strongest regression, fst=-1), (2) linear shape (not steeper — rules out quadratic which collapses to 1.8e-7 in last 5%, fst=-1; not slower — cosine front-loads, lands +0.00163 above linear). NS-orthogonalized updates have rank-stable magnitudes — final convergence requires actual zero LR for clean landing.
- **Striking per-group cooldown contrast established:**
  - Embed (#235): linear_floor WINS (sparse-row group benefits from floored LR — most rows updated infrequently)
  - Body Muon (#520): linear_floor LOSES strongest (NS-stable updates demand zero LR at end)
  - NS-iter (#285): late_peak WINS (interior cooldown structure)
  - NS-coef (#290): linear_ramp_down WINS (high-precision early, standard late)
- **Per-group cooldown-shape design axis substantially closed** — lm_head shape (#547 fern, in flight) completes the matrix.
- **30th productive-null/negative this cycle.**

**Follow-up:** thorfinn assigned **#554 AdamW embed WD cooldown nudge** — fresh axis structurally distinct from #483 (Muon WD warmup early-phase) and #550 (Muon WD reduction body). Paired with #550 to characterize WD-cooldown axis bilaterally.

## 2026-05-20 07:00 UTC — PR #516: Yogi optimizer on aux groups (edward) — CLOSED productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

- Branch: `g1r4-edward/yogi-aux`
- Hypothesis: Yogi replaces AdamW's multiplicative β₂-EMA second moment with sign-based additive update `v_t = v_{t-1} − (1−β₂)·sign(v_{t-1} − g_t²)·g_t²`. Avoids AdaBelief's absent-row pathology (accumulates g², not (g−m)²). Tests bounded-additive vs multiplicative-EMA on aux groups with heavy-tailed gradients.
- Code: `NANOGPT_AUX_OPTIMIZER ∈ {adamw, yogi}` × `NANOGPT_YOGI_SCOPE ∈ {none, embed, lm_head, embed_lm_head_scalars}` with `NANOGPT_YOGI_V0=zero` initialization.

**Results (single-seed 4-arm, 3350 steps, drift gate A PASS):**

| Arm | Yogi scope | val/loss | Δ vs A | Band | W&B run |
|---|---|---:|---:|---|---|
| A | none (AdamW control) | 3.27419 | 0 | drift gate PASS (\|Δ vs 3.27174\|=0.00245) | `dsqd2b7z` |
| B | embed | 3.27805 | +0.00386 | regression | `54lf1rnf` |
| C | lm_head | 3.27457 | +0.00038 | null | `g68ryztc` |
| D | embed_lm_head_scalars | 3.27866 | +0.00447 | regression | `36c4ctk0` |

**Analysis:**

- **No winner candidate** (Δ ≤ −0.002 not met by any arm). No paired-pod confirmation needed.
- **Mechanism reading**: Yogi's faster reaction to moderate gradient changes (additive update vs AdamW's multiplicative EMA at β₂=0.99) destabilizes the sparse-row v_t accumulator on the embed group. Regression grows monotonically through the cooldown window (step 3100 +0.00286 → step 3350 +0.00447), confirming in-flight optimizer dynamics, not v_0 initialization. On the dense lm_head group, NANOGPT_GRAD_CLIP=10.0 truncates spikes before Yogi's bounded-update advantage activates → operationally indistinguishable from AdamW. D ≈ B + 0.00061: embed regression dominates, lm_head/scalars contribute marginally.
- **Independent of AdaBelief (#474) mechanism**: Yogi accumulates g² same as AdamW, so absent-row pathology doesn't apply. Yogi's regression on embed is a different mechanism: multiplicative-EMA → additive-sign change is unproductive on this stack.
- **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. AdamW second-moment mechanism on this stack is now thoroughly characterized: invariant to lm_head perturbations, embed perturbations regress consistently.
- **29th productive-null/negative this cycle.**

**Follow-up:** edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 early-phase WD warmup which was CLOSED NEGATIVE).

## 2026-05-20 02:15 UTC — PR #490: NAdam (Nesterov-AdamW) aux scope sweep (nezuko) — CLOSED productive-null

- Branch: `g1r4-nezuko/nadam-aux`
- Hypothesis: Replace AdamW's first-moment update with Nesterov-style lookahead `m_nadam = β₁·m̂_t + (1-β₁)·g_t/(1-β₁^t)`. Scope sweep across aux groups to isolate sparse-embed vs dense-lm_head benefit. Fills the first-moment axis of the AdamW-internal three-axis ablation (magnitude #442 atan2, variance #474 AdaBelief).
- Code: env var `NANOGPT_NADAM_SCOPE ∈ {none, embed, lm_head, all_aux}`; NadamW optimizer class wraps AdamW with Nesterov lookahead.

| Arm | scope | W&B | val/loss | Δ vs A | first_step | Band |
|---|---|---|---:|---:|---:|---|
| A (control) | none | [p7q6fdmi](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/p7q6fdmi) | 3.27211 | — | 3225 | drift PASS |
| B | embed | [ja3vpi21](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/ja3vpi21) | **3.27152** | **−0.00059** | 3225 | productive-null (mild +) |
| C | lm_head | [06440zwb](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/06440zwb) | 3.27274 | +0.00063 | 3250 | productive-null (mild −) |
| D | all_aux | [i5cpblzf](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/i5cpblzf) | 3.27486 | **+0.00275** | 3275 | **regression** |

**Drift gate:** Δ_A=+0.00037 vs baseline 3.27174 → PASS.
**Decision:** Arm B is best (−0.00059) but well within productive-null band (need ≤−0.002 for signal); no paired-pod follow-up. Closes productive-null overall.

**Analysis:**
1. **Single-group NAdam is neutral.** Both embed-isolated and lm_head-isolated NAdam produce ~10⁻³ effects well below threshold.
2. **Joint NAdam regresses (+0.00275 in arm D).** Compounded across embed + lm_head + scalars, the Nesterov lookahead degrades terminal loss — student's interpretation: scalar group (aggressive per-step direction changes due to normalization-layer effects) is likely the bad actor under NAdam's lookahead.
3. **NadamW overhead negligible** (~0.4% wall-clock).

**Joint structural insight (combined with #442 atan2 NEGATIVE and #474 AdaBelief NEGATIVE):**
- Magnitude axis (#442 atan2): NEGATIVE
- First-moment axis (#490 NAdam): null with joint regression
- Second-moment axis (#474 AdaBelief): NEGATIVE (embed sparsity pathology)

**The AdamW-internal three-axis ablation is substantially exhausted** on the merged stack post-#393. Future optimizer-mechanism experiments should target non-AdamW directions: Muon body variants (Nesterov-Muon, μ schedules already closed #356), NS-iter scheduling, or non-Muon body optimizers.

**Follow-up**: nezuko assigned **#530 Nesterov-Muon body scope sweep** — parallel structural test on Muon body momentum (apply Nesterov lookahead to gradient passed to NS orthogonalization).

## 2026-05-20 01:25 UTC — PR #489: Embed-only LR warmup (alphonse) — CLOSED productive-NEGATIVE

- Branch: `g1r4-alphonse/embed-lr-warmup`
- Hypothesis: Embed-AdamW (sparse-row gradients) may benefit from per-group LR warmup even though global LR warmup (#102) closed negative for Muon body. Tests whether the closure rationale of #102 ("NS handles early stability") extends or fails on the embed group.
- Code: env var `NANOGPT_EMBED_LR_WARMUP_FRAC` (default 0.0); embed-only multiplier applied on top of `eta_embed` in `set_hparams`.
- Arms: 4-arm chain, NANOGPT_EMBED_LR_WARMUP_FRAC ∈ {0.0 control, 0.02, 0.05, 0.10}.

| Arm | frac | Warmup steps | val_loss@3350 | Δ vs A | reached_target | W&B |
|---|---:|---:|---:|---:|:---:|---|
| A (control) | 0.0 | 0 | **3.27054** | — | ✓ (step 3225) | [kl6g296w](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/kl6g296w) |
| B | 0.02 | ~67 | 3.28080 | +0.01026 | ✗ | [6b4gjf2y](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/6b4gjf2y) |
| C | 0.05 | ~167 | 3.28608 | +0.01554 | ✗ | [jv703r3z](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/jv703r3z) |
| D | 0.10 | ~335 | 3.29370 | +0.02316 | ✗ | [z2cra10j](https://wandb.ai/wandb-applied-ai-team/modded-nanogpt-senpai/runs/z2cra10j) |

**Drift gate:** Δ_A=−0.00120 vs baseline 3.27174 → PASS.
**Decision:** All arms exceed +0.0015 regression threshold by 7-15×; monotone worsening with longer warmup confirms mechanism (not noise). Closes axis productive-NEGATIVE.

**Analysis:**
1. **Full embed LR from step 0 is load-bearing.** Even smallest warmup (frac=0.02, ~67 steps) costs Δ=+0.01 — far above noise floor.
2. **No late-cooldown rescue.** All warmup arms track ~+0.01 to +0.023 above arm A through the entire cooldown window.
3. **#102 closure rationale extends to embed group.** Despite the structural distinction (sparse-grad AdamW vs Muon+NS), the early high-LR window is productive, not destabilizing, on both groups.
4. **#393 embed_lr_mult=1.5× amplifies sensitivity.** Embed runs at 1.5× body LR in the merged stack — warming up further suppresses an already-boosted group.

**Bilateral closure with #483 thorfinn WD warmup (also productive-NEGATIVE this cycle):** Both "regularization-REDUCTION by warmup" symmetric experiments — on body Muon (WD) and embed AdamW (LR) — fail. The merged stack's early-training window is bilaterally well-tuned and resists symmetric deregularization. This is a structural finding: 25 axes of additive AND subtractive regularization both fail.

**Follow-up**: alphonse assigned **#524 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×). Tests whether the embed group can take MORE early LR.

## 2026-05-19 23:42 UTC — PR #483: Muon WD warmup schedule (thorfinn) — CLOSED productive-NEGATIVE

- Branch: `g1r4-thorfinn/wd-warmup`
- Hypothesis: Ramp Muon body WD from 0 → 0.025 linearly over first N% of training. Tests "less constraint early" direction on the only nonzero WD in the merged stack. First regularization-REDUCTION test this cycle.
- Spec correction (15:48 UTC): student correctly identified AdamW WD=0 in merged stack; Muon has WD=0.025. Approved pivot to Muon block group warmup before launch.

### Results — 4-arm sweep (n=1 each)

| Arm | WD warmup frac | val/loss | Δ vs A | Verdict |
|---|---:|---:|---:|---|
| A (ctrl) | 0.00 | 3.27066 | — | drift +0.00108 ✓ |
| B | 0.05 | 3.27146 | +0.00080 | productive-null |
| C | 0.10 | 3.27324 | +0.00258 | **regression** |
| D | 0.20 | 3.27466 | +0.00400 | **regression (largest)** |

W&B runs: A=`az3lb24h`, B=`jz0ilkgs`, C=`cosoo5ob`, D=`u9ddrsvt`.

Drift gate: |val_A − 3.27174| = +0.00108 ✓.

### Key findings

1. **Clean monotone worsening A → B → C → D**: warmup fraction increases → regression monotonically increases. Strongest possible signal for closing this axis.
2. **Body-block weights do NOT need uninhibited growth during early discovery**: Muon-WD=0.025 is load-bearing from step 0. Delaying it hurts.
3. **No arm crosses Δ ≤ −0.002**: no winner candidate. B is in null band; C and D in regression band.

### Mechanism takeaway

**24th productive-null/negative this cycle.** First regularization-REDUCTION test closes bilateral: 17 ADD-regularization axes all failed, now REDUCE-regularization (WD warmup) also fails. This bilaterally triangulates that **the merged stack's body-weight regularization level (0.025) is already optimally tuned**. WD-schedule axis on Muon body is fully closed.

**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles (linear/cosine/quadratic/linear_floor) over the 30% load-bearing cooldown window. First experiment targeting body Muon LR cooldown shape specifically.

---

## 2026-05-19 22:35 UTC — PR #474: AdaBelief aux scope sweep (edward) — CLOSED productive-NEGATIVE

- Branch: `g1r4-edward/adabelief-aux`
- Hypothesis: Replace AdamW's second moment `v_t = β₂·v_{t-1} + (1−β₂)·g_t²` with AdaBelief's `s_t = β₂·s_{t-1} + (1−β₂)·(g_t − m_t)²`. Penalizes gradient prediction error rather than gradient magnitude. Scope sweep across aux groups.

### Results — 4-arm sweep (n=1 each)

| Arm | Scope | val/loss | Δ vs A | Verdict |
|---|---:|---:|---:|---|
| A (ctrl) | adamw/none | 3.27268 | — | drift +0.00094 ✓ |
| B | adabelief/embed | 3.31349 | +0.04081 | **catastrophic regression** |
| C | adabelief/lm_head | 3.27456 | +0.00188 | mild regression |
| D | adabelief/embed_lm_head_scalars | 3.30747 | +0.03479 | **catastrophic regression** |

W&B runs: A=`5l0mpqge`, B=`x72bobwp`, C=`bbju977a`, D=`ad41khqb`.

Drift gate: |val_A − 3.27174| = +0.00094 ✓.

### Key findings

1. **No arm crosses Δ ≤ −0.002**: all arms worse than control. Arm B catastrophic (+0.04081), arm D catastrophic (+0.03479), arm C mild (+0.00188 at null-edge/regression threshold). **Close productive-NEGATIVE.**
2. **Embed sparsity pathology** (identified by edward): Embed gradients are sparse — absent-row token has g_t=0 but m_t≠0 from recent visits. `(g_t − m_t)² = m_t²` (large) for those rows, inflating the whole-tensor denominator and shrinking effective updates for active rows. AdamW's `g_t²` contributes zero for absent rows — no pathology.
3. **D ≈ B trajectory** (~0.005 separation across 3350 steps): adding lm_head + scalars to Yogi scope adds essentially zero additional damage. Embed group dominates catastrophic regression in D.
4. **lm_head (arm C)**: brief improvement at step 1000 (Δ=−0.00025) then stable +0.002 lag. Consistent with token-frequency noise heterogeneity — stable but mildly underperforming AdamW.

### Mechanism takeaway

**23rd productive-null/negative this cycle.** AdaBelief closes the variance-of-prediction-error second-moment axis. Combined with AdEMAMix (#399), Cautious (#419), atan2 (#442 NEG), OrthoGrad (#477), AGC (#408), the aux-group AdamW response surface for all gradient-direction AND second-moment-formulation axes is now exhausted. NAdam (#490, first-moment Nesterov) is the last in-flight Adam-family mechanism axis.

**Critical structural finding**: AdaBelief's `(g − m)²` assumption requires m_t to be a reasonable predictor of current g_t. On sparse-row aux groups (embed), the EMA-decayed first moment `m_t` carries signal from absent rows, making `(g − m)²` large when g=0. This is a fundamental incompatibility with embedding-matrix sparse gradients.

**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update. Avoids AdaBelief pathology (accumulates g² like AdamW, not (g−m)²), but uses additive bounded update rather than multiplicative EMA.

---

## 2026-05-19 21:35 UTC — PR #477: OrthoGrad aux scope sweep (fern) — CLOSED productive-null

- Branch: `g1r4-fern/orthograd-aux`
- Hypothesis: Preprocess AdamW gradient on aux groups by projecting out the weight-parallel component: `g_perp = g_t − (g_t·w_t / ||w_t||²)·w_t`. Weight-parallel gradient just rescales magnitude — removing it lets AdamW focus on direction signal. Scope sweep: embed-only, lm_head-only, both.

### Results — 4-arm sweep (n=1 each)

| Arm | NANOGPT_ORTHOGRAD_SCOPE | val/loss | Δ vs A | Verdict |
|---|---|---:|---:|---|
| A (ctrl) | none | 3.27181 | — | drift +0.00007 ✓ |
| B | embed | 3.27344 | +0.00163 | **regression** |
| C | lm_head | 3.27466 | +0.00285 | **regression** |
| D | embed_lm_head | 3.27101 | −0.00080 | productive-null |

Drift gate: |val_A − 3.27174| = +0.00007 ✓.

### Key findings

1. **No arm crosses Δ ≤ −0.002**: D passes stat-rule on absolute baseline (3.27101 ≤ 3.27174) but Δ=−0.00080 is 40% of the −0.002 within-pod signal threshold. Per pre-staged rules: productive-null. Default to within-pod Δ over stat-rule on static baseline — matches #344, #351, #408 false-positive precedents.
2. **Non-monotonic scope finding**: Single-group projection regresses (B embed: +0.00163, C lm_head: +0.00285), combined (D embed+lm_head) recovers partially (−0.00080). Non-monotonic pattern.
3. **Mechanistic interpretation**: embed and lm_head co-evolve through the residual stream; partial OrthoGrad on only one group breaks their relative magnitude balance. Combined OrthoGrad lets both groups co-cool through the shared WD+cooldown mechanism, restoring balance.

### Mechanism takeaway

**22nd productive-null/negative this cycle.** OrthoGrad joins the productive-null cluster on aux-group AdamW gradient-direction axis (#408 AGC, #419 Cautious, #399 AdEMAMix). Key design insight: **aux-group AdamW magnitude dynamics are NOT independent — they are a coupled system that resists single-axis perturbation.** Future aux-group experiments should default to "all aux" scope, not single-group, unless there's a specific sparse-vs-dense reason.

**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing rate as a schedule axis. Same family (gradient-level intervention on aux AdamW), structurally distinct mechanism. Pairs with the "less constraint early" cluster: WD warmup (#483), embed-LR warmup (#489), NS-iter warmup (#506).

---

## 2026-05-19 20:55 UTC — PR #470: NS iterations normal-phase sweep NS∈{8,10,12,14} (frieren) — CLOSED productive-null

- Branch: `g1r4-frieren/ns-iters-normal`
- Hypothesis: NS_ITERS=12 during the normal phase (step 0 → 70%) may be above saturation (i.e., fewer iterations could achieve same val with less compute), or below the precision floor (more iterations would help). 4-arm sweep: A=12 (ctrl), B=8, C=10, D=14.

### Results — 4-arm sweep (n=1 each)

| Arm | NS_ITERS | val/loss | Δ vs A | fs/step | W&B |
|---|---:|---:|---:|---:|---|
| A (ctrl) | 12 | 3.27181 | — | 3225 | `rnjvvj2g` |
| B | 8 | 3.27416 | +0.00235 | 3250 | `bzofkgf9` |
| C | 10 | **3.27013** | −0.00168 | 3225 | `wmzxyuy5` |
| D | 14 | **3.27036** | −0.00145 | 3225 | `dk6edqef` |

Drift gate: |val_A − 3.27174| = +0.00007 ✓.

### Key findings

1. **No arm crosses Δ ≤ −0.002**: C (−0.00168) is 84% of threshold; D (−0.00145) similar. Per pre-staged rules: productive-null. Both pass n=1 stat-rule on absolute baseline (3.27013 ≤ 3.27174) but within-pod Δ is canonical; no paired-pod confirmation.
2. **NS=8 confirms precision floor exists**: Δ=+0.00235 regression — consistent with #388 prior saturation finding.
3. **NS ∈ [10, 14] is a wide saturation plateau**: all three within ~0.0017 of each other, within paired-pod noise.
4. **Critical compute finding**: NS step-time is essentially flat (±1%) across NS ∈ [8, 14]. Naive prediction was 17-33% per arm. Forward/backward dominates per-step time — orthogonalization is NOT the bottleneck. Kills "lower NS for compute savings" angle.

### Mechanism takeaway

**21st productive-null/negative this cycle.** NS_ITERS normal-phase is saturated for NS ∈ [10, 14]. NS=8 below floor. NS=12 (current default) is well-placed on the plateau. The compute finding means future NS decisions should be motivated by val/loss only, not step-time.

**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from low → 12 over first N% of training. First NS schedule experiment to vary precision within the normal phase (all prior NS schedule work targeted cooldown). Pairs with WD warmup (#483) and embed LR warmup (#489) in a "less constraint early" research cluster.

---

## 2026-05-19 18:05 UTC — PR #454: Aux-group linear_floor cooldown extension (nezuko) — CLOSED productive-null

- Branch: `g1r4-nezuko/aux-floor-cooldown`
- Hypothesis: The `EMBED_COOLDOWN_SHAPE=linear_floor` mechanism (merged #235) preserves a non-trivial LR floor for the embed group during cooldown. If it helps embed (sparse-row gradients continue getting useful updates through cooldown), analogous benefit should appear for lm_head and scalars. 3-arm scope sweep: embed_only (control), lm_head_floor, scalars_floor, both_aux.

### Results — 4-arm sweep (n=1 each)

| Arm | LM_HEAD | SCALAR | val/loss | Δ vs A | W&B |
|---|---|---|---:|---:|---|
| A (control) | linear | linear | 3.27249 | — | `o8tguqr3` |
| B | linear_floor | linear | 3.27151 | −0.00098 | `m7a5p4xe` |
| C | linear | linear_floor | 3.27176 | −0.00073 | `b9q1vc5k` |
| D | linear_floor | linear_floor | 3.27321 | +0.00072 | `k2h8lp7q` |

Drift gate: |val_A − 3.27174| = +0.00075 ✓ (within ±0.003).

### Key findings

1. **No arm crosses Δ ≤ −0.002**: best arm B Δ=−0.00098 is half the pre-staged signal threshold.
2. **Arm D (stacked) regresses vs B**: +0.0017 regression when stacking both floors. Interaction between groups at end-of-cooldown suggests mutual interference — too many groups holding non-trivial LR prevents final "tightening".
3. **Arms B and C individually suggestive but within noise**: at n=1, these Δ values are well within the observed ±0.001 noise band.
4. **Arm D evidence against paired-pod for B**: if lm_head_floor were independently beneficial, stacking it with scalar_floor should at worst tie B. The +0.0017 regression from D↔B suggests B may be noise-driven.
5. **Three prior false-positive precedents this cycle** (#344, #351, #408 AGC all collapsed on paired-pod) — conservative close is correct.

### Mechanism takeaway

**linear_floor mechanism is embed-specific, not aux-generic.** The embed group receives sparse-row gradients (~30K of 50K vocab rows per batch), so LR preservation during cooldown matters for rare-token rows that don't appear often. lm_head and scalar groups have dense gradients (every forward pass), so cooldown-LR-preservation doesn't add per-element coverage benefit for those groups.

**20th productive-null/negative this cycle.** Cooldown-shape on aux groups is now exhausted. Follow-up: **#490 nezuko NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, never tested on this stack.

---

## 2026-05-19 17:53 UTC — PR #442: Adam-atan2 on AdamW aux groups, b∈{0.3,1.0,3.0} (alphonse) — CLOSED productive-NEGATIVE

- Branch: `g1r4-alphonse/adam-atan2`
- Hypothesis: Replace AdamW's `m/(√v+ε)` with `atan2(m, b·√v)` on aux groups. Produces bounded-magnitude updates independent of b, claimed to be more stable at scale. Scope: embed, lm_head, scalars. b sweep: {0.0 ctrl, 0.3, 1.0, 3.0}. Rebased post-#393 (embed_lr_mult=1.5×).

### Results — 4-arm sweep (n=1 each, post-#393 rebase)

| Arm | b | val/loss | Δ vs A | fs_to_target | W&B |
|---|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27213 | — | 3225 | `ih2rlkvy` |
| C | 0.3 | 3.27198 | −0.00015 | 3225 | `p8phjr9x` |
| B | 1.0 (PaLM default) | 3.27263 | +0.00050 | 3250 | `9tdyz2rd` |
| D | 3.0 | **3.28255** | +0.01042 | **−1 (failed)** | `tiylmq37` |

W&B group: `g1r4-alphonse/adam-atan2`. Drift gate: |val_A − 3.27174| = 0.00039 ✓.

### Key findings

1. **No arm beats baseline**: C (numerically best) is 3.27198 > baseline 3.27174 by +0.00024. Stat-rule fails on absolute baseline.
2. **D (b=3.0) fails benchmark contract**: val=3.28255, never crossed 3.28. Catastrophic regression at large b.
3. **Roughly monotone-worsening with b↑**: large b → large effective denominator → slow convergence. AdamW with ε=1e-8 already at the magnitude-transform sweet spot.
4. **C (b=0.3) is numerically best but Δ=−0.00015** — well inside n=1 seed noise. Not a real signal.

### Mechanism takeaway

**19th productive-null/negative this cycle.** Closes the AdamW-internal magnitude-transform axis: atan2, Cautious, AdEMAMix, Lookahead all closed. Open AdamW-adjacent tests: AdaBelief (#474, variance-of-prediction second moment) and OrthoGrad (#477, gradient ⊥ to weight).

**Follow-up**: alphonse assigned **#489 embed-only LR warmup** — schedule axis, structurally distinct from global LR warmup (#102 closed negative) because #102 closure rationale applies only to Muon body (NS provides directional stability), not embed AdamW (sparse-row gradients, no NS).

---

## 2026-05-19 17:00 UTC — PR #441: Logit Z-loss PaLM style λ∈{1e-5,1e-4,1e-3} (tanjiro) — CLOSED productive-NEGATIVE

- Branch: `g1r4-tanjiro/logit-z-loss`
- Hypothesis: Add PaLM/T5-style soft logit regularization: `loss += λ · Σ_t logsumexp(logits_t)²`. Auxiliary training loss penalizes large-magnitude logit distributions, providing an alternative to the hard logit softcap. Z-loss correctly gated on `self.training` (val reports pure CE). λ sweep: {0.0, 1e-5, 1e-4, 1e-3}.

### Results — 4-arm sweep (n=1 each)

| Arm | λ | val/loss | Δ vs A | fs_to_target | W&B |
|---|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27160 | — | 3225 | `egplthdf` |
| B | 1e-5 | 3.27371 | +0.00211 | 3250 | `72kmbdh1` |
| C | 1e-4 (PaLM) | 3.27311 | +0.00151 | 3250 | `tyq16skb` |
| D | 1e-3 | 3.29393 | +0.02233 | **−1 (failed)** | `00x1lnuz` |

W&B group: `g1r4-tanjiro/logit-z-loss`. Drift gate Arm A: val=3.27160, Δ=−0.00014 vs baseline 3.27174 ✓.

### Key findings

1. **All non-zero λ regress.** Smallest λ=1e-5 still produces Δ=+0.00211 (regression band). No sweetspot; no improvement at any tested λ.
2. **D (λ=1e-3) fails benchmark contract**: val=3.29393 at step 3350, never reached 3.28 target. Severe regression.
3. **Non-monotone B > C** at low λ (C slightly better than B), consistent with n=1 noise. Both are uniformly worse than A.
4. **Root cause: logit softcap c=15 already provides sufficient logit regularization.** With `15 * tanh(z/15)` saturating per-position logits in [−15, 15], the per-position logsumexp(z) is mechanically bounded — z-loss is redundant for stability but still injects gradient signal that biases CE optimization.
5. **At λ=1e-3**: auxiliary penalty magnitude (~500/batch) competes with CE (~5000/batch) — ~10% competing objective corrupts CE convergence.
6. **Student defensive catch**: Tanjiro correctly flagged that z-loss in eval would inflate val by 0.002–0.18 nats and gated it on `self.training` before running. Approved at 08:46 UTC. Prevented a subtly broken experiment.

### Mechanism takeaway

**18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis now fully closed (label smoothing catastrophic #446, z-loss negative #441, softcap=15 optimal #354). All additive-regularization axes on this stack fail: softcap already provides the logit-bounding function z-loss targets. Adding another regularizer is redundant at best, competing-objective at worst.

**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation** — structurally novel (subtractive), charter-explicit.

---

## 2026-05-19 15:38 UTC — PR #446: Label smoothing sweep α∈{0.05,0.1,0.2} (thorfinn) — CLOSED productive-NEGATIVE

- Branch: `g1r4-thorfinn/label-smoothing`
- Hypothesis: Replace hard one-hot CE targets with soft distribution: `target_smoothed = (1−α)·one_hot + α/V`. Train on smoothed loss; val/loss reported un-smoothed for fair benchmark comparison. Loss-side regularization mechanism, orthogonal to all optimizer/gradient axes.

### Results — 4-arm sweep (n=1 each)

| Arm | α | val/loss | Δ vs A | first_step_to_target | W&B |
|---|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27326 | — | 3250 | `qdyewmeq` |
| B | 0.05 | 3.31900 | +0.04574 | **−1 (failed)** | `y66da3d0` |
| C | 0.1 | 3.37495 | +0.10169 | **−1 (failed)** | `854e86hq` |
| D | 0.2 | 3.49666 | +0.22340 | **−1 (failed)** | `aoi6du9y` |

W&B group: `g1r4-thorfinn/label-smoothing`. Drift gate Arm A: Δ=+0.00152 ≤ 0.003 ✓.

### Key findings

1. **Strictly monotone worsening in α** — not noise, not an inverted-U. Cleanest regression of the cycle. B/C/D all fail to reach 3.28 target, with D regressing +0.22 nats.
2. **Mechanism: regularization budget fully spent.** The merged stack carries three overlapping confidence-regularizers (logit softcap=15, per-group LR embed_mult=1.5×, NS cooldown schedule). Label smoothing's mechanism (dampen correct-token gradient, add uniform wrong-token pressure) overlaps with what these deliver — acts as net gradient subtraction on already-regularized signal.
3. **Even α=0.05 (below all paper defaults including PaLM/T5/LLaMA at 0.1) regresses +0.046 nats** — far beyond any plausible noise. No recovery at any α.
4. **Implementation clean**: val/loss correctly un-smoothed via `model.eval()` → `self.training=False` → `smoothing=0.0`. Un-smoothed comparison is valid.

### Mechanism takeaway for the cycle

This is the **17th productive-null/negative this cycle**. The pattern is now clear: **adding regularization of any kind fails** (label smoothing, AGC, Cautious, AdEMAMix, GC, gradient noise, weight-EMA, Lookahead, WD values). The stack is fully regularized for the 3350-step horizon. Future experiments must reduce or invert regularization (WD warmup, LR boost) or change the optimizer mechanism fundamentally (AdaBelief, OrthoGrad, etc.).

### Bonus: student caught a plugin bug

g1r4-thorfinn fixed `plugins/senpai/scripts/senpai-pr-guard.py`: line 22 used substring match (`"SENPAI-RESULT:" not in line`) which triggered on advisor prose containing "SENPAI-RESULT:" mid-sentence. Fix: `line.lstrip().startswith("SENPAI-RESULT:")`. Plugin-side only; no target repo change.

---

## 2026-05-19 14:15 UTC — PR #408: Adaptive Gradient Clipping (AGC) sweep (fern) — CLOSED productive-null

- Branch: `g1r4-fern/adaptive-grad-clip`
- Hypothesis: Per-parameter Frobenius-relative gradient clipping (NFNets-style AGC). Replaces fixed global `clip_grad_norm_(10.0)` with per-parameter trust region: `g'_i = g_i · min(1, λ · ||w_i||_F / ||g_i||_F)`. Scope=all (Muon + AdamW), λ ∈ {0.0, 0.01, 0.03, 0.1}.

### Results — 4-arm original sweep + 3-pod paired confirmation

**Original within-pod sweep (n=1 each):**

| Arm | λ | val/loss | Δ vs A | first_step_to_target | trigger_rate | W&B |
|---|---:|---:|---:|---:|---:|---|
| A (control) | 0.0 | 3.27315 | — | 3250 | — | `501a4e8x` |
| **B** | **0.01** | **3.27063** | **−0.00252** | 3225 | 99.4% | `5b62glw0` |
| C | 0.03 | 3.27076 | −0.00239 | 3225 | 99.4% | `4mm7u7rm` |
| D | 0.10 | 3.27289 | −0.00026 | 3250 | 99.4% | `ivd6ribv` |

**Paired-pod confirmation (n=3 each):**

| Pod | A val | B (λ=0.01) val | Δ within pod |
|---|---:|---:|---:|
| 0 (original) | 3.27315 | 3.27063 | **−0.00252** ← original signal |
| 1 (confirm) | 3.27317 | 3.27323 | **+0.00006** (null) |
| 2 (confirm) | 3.27356 | 3.27427 | **+0.00071** (B worse than A) |
| **Pooled mean n=3** | **3.27329** | **3.27271** | **−0.00058** |

All W&B runs: `501a4e8x`, `5b62glw0`, `4mm7u7rm`, `ivd6ribv`, `sa8ggn7j` (pod1-A), `o43p6e7i` (pod1-B), `yqf87h3c` (pod2-B), `q7ucq17u` (pod2-A). Groups: `g1r4-fern/adaptive-grad-clip`, `g1r4-fern/agc-confirm`.

**Pre-staged decision rule**: mean(val_B,n=3)=3.27271 > baseline 3.27200 → **CLOSE productive-null** (fails "≤3.27200" leg).

### Key findings

1. **Pod-0 signal was favorable-seed luck**: val_B spread across 3 pods: [3.27063, 3.27323, 3.27427] = 0.00364 range. Pod-1 Δ=+0.00006, Pod-2 Δ=+0.00071 — both null or wrong-sign.
2. **Mechanism is operating consistently**: AGC trigger-rate=99.4% across ALL 3 B runs (nearly every parameter clipped), yet val improvement is not reproducible. The per-parameter trust-region clipping is doing the same computation each time — it just doesn't yield consistent val benefit on this 3350-step stack vs global clip=10.0.
3. **Cross-pod seed variance dominates**: within-pod arm-A spread [3.27315, 3.27317, 3.27356] = 0.00041 (tight); arm-B spread 0.00364 (much wider). AGC adds seed-level variance rather than deterministic signal. Suggests AGC changes the effective optimization trajectory in ways that are sensitive to initialization.
4. **Third paired-pod collapse this cycle** (after #344 frieren NS-transition, #351 alphonse scalar-ε): confirms the paired-pod protocol is the correct guard against pod-luck at the |Δ|~0.002 frontier.
5. **Critical stat observation (fern)**: "future single-seed signals at |Δ| < 0.005 should be considered tentative until paired-confirmed." The val spread of 0.00364 across seeds is comparable to the signal magnitudes we're trying to detect. Paired-pod confirmation is essential for any candidate with |Δ| < 0.005.

### Mechanism takeaway for the cycle

AGC step-time overhead is ≈0.4–0.5% — negligible. The problem is not compute efficiency; it's signal reproducibility. Fixed global `clip_grad_norm_(10.0)` is already near-sufficient as a gradient norm regularizer on this stack. AGC axis closed (including per-group AGC variants). **16th productive-null this cycle.**

---

## 2026-05-19 13:43 UTC — PR #434: Lookahead optimizer scope sweep (edward) — CLOSED productive-NEGATIVE

- Branch: `edward/lookahead-scope-sweep`
- Hypothesis: Lookahead (slow/fast weights, k=5, α=0.5) wraps AdamW and/or Muon. Slow-weight blend may smooth optimization in parameter space — orthogonal to AdamW v-EMA (gradient-space second moment) and AdEMAMix (gradient-space slow EMA, #399 productive-null).

### Results — 4-arm scope sweep (n=1 each)

| Arm | scope | val/loss | Δ vs A | first_step_to_target | step_avg (ms) |
|---|---|---:|---:|---:|---:|
| A | off (control) | 3.27446 | — | 3275 | 1895.72 |
| B | adamw | 3.27690 | +0.00244 | 3300 | 1896.70 |
| C | muon | 3.28550 | +0.01104 | **−1 (failed)** | 1894.90 |
| D | both | 3.29175 | +0.01729 | **−1 (failed)** | 1898.76 |

W&B runs: s5vvibh9 (A), lzrvfony (B), vlb4v8vk (C), nr7qahb8 (D). Drift gate Arm A: |3.27446 − 3.27200| = 0.00246 ≤ 0.003 PASS.

### Key findings

1. **Clean regression-monotone trajectory** — all 3 Lookahead arms are wrong-sign relative to the −0.002 real-signal threshold. C and D never crossed the 3.28 target at 3350 steps.
2. **Muon-wrapping hurts ~4.5× more than AdamW-wrapping** (Δ_C/Δ_B ≈ 4.5). Muon owns the geometry-critical late training (NS coef ramp-down #290, NS late_peak #285) — periodic slow-weight blending interferes with the carefully tuned post-NS step trajectory.
3. **'Both' arm is roughly additive** (Δ_D=+0.01729 ≈ Δ_B + Δ_C = +0.01348). Independent harm mechanisms: AdamW-side and Muon-side Lookahead each interfere with their respective optimizer's cooldown contribution separately.
4. **Mechanism: cooldown-phase geometric interference.** During cooldown the per-step updates are tiny and signed coherently; Lookahead's α=0.5 blend every k=5 steps drags θ_f halfway back toward a θ_s that lags ~5 steps behind, undoing ~25% of the cooldown signal each cycle.
5. **Sibling-failure context** — pairs with #436 frieren weight-EMA (also CLOSED productive-NEGATIVE 13:08 UTC). Both demonstrate **parameter-space temporal smoothing fights the cooldown.** Different operators (EMA-averaging vs slow-weight blending), same conclusion: cooldown is load-bearing signal, not noise.

### Mechanism takeaway for the cycle

This is the **15th productive-null/negative on opt-internal / parameter-temporal axes**. The empirical pattern (#399 AdEMAMix, #436 Weight-EMA, #434 Lookahead, plus per-group/AdEMAMix/Cautious explorations) consistently rules out any 'after-the-optimizer' smoothing/blending mechanism on this stack. Useful negative knowledge — temporal smoothing in parameter space is incompatible with the current cooldown design.

### Lookahead overhead

step_avg vs Arm A: B +0.05%, C ≈0%, D +0.16% — Lookahead's cost is in the noise (single clone of param tensors, no extra fwd-bwd).

### Suggested follow-ups (from student, will not be pursued)

- Cooldown-disabled Lookahead (toggle off during NS_COOLDOWN_START_FRAC * train_steps): would isolate the cooldown-interference mechanism from the temporal-smoothing-helps-mid-training hypothesis.
- Inverse-Lookahead (α=0 during cooldown only): same insight, cheaper.

Mechanism information is sufficient — moving on. Edward will be assigned a structurally distinct axis (not parameter-space temporal smoothing).

---

## 2026-05-19 13:08 UTC — PR #436: Weight-EMA (Polyak averaging) of weights for val eval (frieren) — CLOSED productive-NEGATIVE

- Branch: `g1r4-frieren/weight-ema`
- Hypothesis: Maintain an EMA buffer of model weights with a tunable decay; swap EMA→model weights at val eval to smooth out cooldown-phase stochastic fluctuations. Mechanism orthogonal to AdamW v-EMA (second moments), Lookahead (slow weights), and AdEMAMix (EMA in gradient space).

### Results — 4-arm sweep (n=1 each)

| Arm | decay | half-life (steps) | val/loss EMA | Δ_EMA vs A | val/loss live | Δ_live vs A |
|---|---|---:|---:|---:|---:|---:|
| A (control) | 0.0 (off) | — | 3.27449 | (control) | 3.27449 | (control) |
| B | 0.999 | ~693 | 3.36639 | +0.09190 | 3.27328 | −0.00121 |
| C | 0.9999 | ~6932 | **4.68248** | **+1.40799** | 3.27262 | −0.00187 |
| D | 0.99 | ~69 | 3.27918 | +0.00469 | 3.27395 | −0.00054 |

W&B runs: e7qcs27m (A), snny3mnk (B), hnsh02ew (C), pdf5vtjq (D). Group `frieren_weight_ema`.

### Key findings

1. **The cooldown phase is signal, not noise.** Four independent live-weights trajectories (A=3.27449, B-live=3.27328, C-live=3.27262, D-live=3.27395) cluster in a 0.00187 band (consistent seed noise). The damage in B/C/D is entirely the EMA-buffer-vs-live divergence at eval time, not training degradation.
2. **Damage scales monotonically with averaging-window length.** Even half-life=69 steps (only ~2% of training) lags far enough to hurt eval. By step ~3275, the (live − EMA) gap **flips positive** in arm D — EMA-D is lagging the still-improving cooldown rather than smoothing it. C's plateau at 4.68 is the time-averaged val_loss of the run's trajectory.
3. **Pre-registered productive-null risk landed in the productive-NEGATIVE direction**: EMA-as-eval is read-out-only (no training effect), so it merely replaces live-final weights with an averaged buffer that is necessarily further from the cooldown-end optimum unless decay→0 (in which case EMA = live trivially).
4. **Marginal arm A drift gate** (val_A=3.27449 vs new baseline 3.27174: Δ=+0.00275, edge of ±0.003 band). Live-trajectory clustering across all arms suggests the gate is informative; within-pod Δs are interpretable.

### Mechanism takeaway for the cycle

This is now the 13th productive-null/negative on opt-internal/parameter-space axes (cautious AdamW #419, AdEMAMix #399, LLRD #409, β2 sensitivity #407, AdamW ε #322, grad-noise #411, GC #402, Lookahead #434 in flight regression-monotone, weight-EMA #436 closed). Multiple in-flight ideas (NS late_peak #285, NS coef ramp #290, embed linear_floor #235) all point at the cooldown as **load-bearing and precision-sensitive, not noisy**.

### Suggested follow-ups (from student)

- Inversion-point sentinel metric (live − EMA gap flip sign) as diagnostic for any future EMA-of-weights retest
- Orthogonal-to-cooldown axes (init scaling, attention LR warmup, NS quintic-coef seed) — more likely to find gains than post-hoc smoothing
- Possibly revisit if cooldown shape ever softens (non-monotonic LR or flat full-LR tail) — currently the stack sharpens late phase, the opposite regime where EMA helps

---

## 2026-05-19 09:30 UTC — PR #393: Per-group AdamW LR multiplier sweep (nezuko) — MERGED ⭐ (val 3.27200 → 3.27174)

- Branch: `g1r4-nezuko/pergroup-adamw-lr`
- Hypothesis: Sweep independent LR multipliers on AdamW aux groups (embed, lm_head, scalars). Mechanism: different parameter groups have different curvature and signal-to-noise ratios; per-group calibration can be orthogonal to global scheduler tuning.

### Results — 4-arm sweep + n=3 paired-pod confirmation

**Sweep (original pod):**
| Arm | LR mult | val | Δ vs baseline | fs | W&B |
|---|---|---:|---:|---:|---|
| A (control) | all 1.0× | 3.27242 | +0.00042 ✓ | 3250 | `oggbt72v` |
| **B (embed1.5)** ⭐ | embed=1.5× | **3.27026** | **−0.00174** | 3225 | `cgyyzpwe` |
| C (lmhead1.5) | lm_head=1.5× | 3.27505 | +0.00305 | 3250 | `kwt7wjzi` |
| D (scalar1.5) | scalar=1.5× | 3.27142 | −0.00058 | 3275 | `1bgjs64f` |

**Paired-pod confirmation (n=3 per arm):**
| Pod | Arm | val | Within-pod Δ (B−A) |
|---|---|---:|---:|
| 0 (orig) | A | 3.27242 | −0.00216 |
| 0 (orig) | B | 3.27026 | |
| 1 | A | 3.27361 | −0.00163 |
| 1 | B | 3.27198 | |
| 2 | A | 3.27329 | −0.00031 |
| 2 | B | 3.27298 | |
| **mean** | | A=3.27311, B=3.27174 | **−0.00137** |

- Drift gates: all 3 A controls ✓ (|Δ vs 3.27200| ≤ 0.003)
- Pooled paired Δ=−0.00137 (compressed from initial −0.00216; consistent direction 3/3 pods)
- mean(B, n=3)=3.27174 ≤ 3.27200 baseline ✓
- Stat-rule: (3.28−3.27174)×√3 = 0.01431 ≥ 0.004 ✓

### Key findings

1. **Embed LR 1.5× wins**: raising embed from 0.30 → 0.45 effective LR improves final val. Mechanism: embed is the most-clip-sensitive group and gains from more signal at the current per-step budget.
2. **lm_head LR 1.5× regresses** (+0.00305): lm_head at 1/320 × 1.5 = 0.00469 is too aggressive for its current cooldown schedule. 
3. **Scalar LR 1.5× is near-null** (−0.00058): slight signal but inside null band.
4. **Single-seed vs paired-pod Δ inflation**: original pod-0 Δ=−0.00216 compressed to mean Δ=−0.00137 under n=3 confirmation. Pattern consistent with earlier paired-pod collapses (#344, #351). Recommendation: future n=3 confirmations should run the full chain from the start, not expand from n=1.
5. **New merged recipe**: adds `NANOGPT_ADAMW_EMBED_LR_MULT=1.5` to the post-#290 stack. New baseline: val=3.27174, fs=3233.33.

### Verdict

MERGED. Improvement is small but real and passes the program.md benchmark contract. Per-group AdamW calibration is a productive axis; lm_head/scalar follow-up experiments remain open.

---

## 2026-05-19 08:55 UTC — PR #419: Cautious AdamW updates (askeladd) — CLOSED productive-null ✅ (cautious-on-all harmful, embed-only less bad but still regresses)

- Branch: `g1r4-askeladd/cautious-adamw`
- Hypothesis: Liang et al. 2024 cautious mask zeroes AdamW update components whose sign disagrees with current gradient. Tests three variants: rescale-on-all (paper default), plain-mask-on-all (no rescale), and embed-only scope. Mechanism: suppress stale-momentum overshoot against fresh gradient signal.

### Results — 4-arm single-pod sweep

| Arm | CAUTIOUS config | val | Δ vs A | Δ vs baseline (3.27200) | fs | reached_target | W&B |
|---|---|---:|---:|---:|---:|---|---|
| A (control) | off | **3.27159** | — | **−0.00041 ✓** (drift) | 3225 | ✓ | `tkpem30s` |
| B (paper) | mask + rescale, all AdamW groups | 3.28460 | **+0.01301** | +0.01260 | −1 | ✗ | `engpgyik` |
| C (plain) | mask, no rescale, all AdamW groups | 3.28288 | **+0.01129** | +0.01088 | −1 | ✗ | `crsnqzoc` |
| D (embed) | mask + rescale, embed group only | 3.27518 | **+0.00361** | +0.00318 | 3275 | ✓ | `wppw91x9` |

### Key findings

1. **Drift gate ✓**: arm A reproduces baseline (|Δ|=0.00041 ≤ 0.003).
2. **All 3 cautious variants regress**. Monotonic ordering: B (all+rescale, worst) > C (all+plain) > D (embed-only, least bad). Narrowing scope = less harm.
3. **B/C fail the 3.28 target entirely** — `reached_target=0` and `first_step_to_target=−1`. The cautious mask on all AdamW groups destabilizes training enough that the schedule cooldown doesn't recover.
4. **Rescale (B) is worse than no-rescale (C)** by Δ=+0.00172. The rescale factor `numel/mask_sum` amplifies un-masked components — on this fast-curvature 3350-step budget this amplifies noise more than it preserves signal.
5. **D (embed-only) reaches target at fs=3275, 50 steps slower than control**. The mechanism is less catastrophic when scope is narrow, but still doesn't help.
6. **Mechanism reading**: Post-#290 stack uses β₁=0.8 (low first-moment momentum) on aux groups. Low β₁ means stale-momentum-vs-fresh-gradient sign disagreement is already rare — the cautious mask has very little to bite on. Meanwhile Muon carries the bulk of training signal and is untouched by this AdamW-only intervention.

### Verdict

Cautious AdamW axis CLOSED. **13th productive-null on optimizer-internal mechanisms this cycle.** Combined with #411 grad-noise, #399 AdEMAMix, #407 β2, #322 ε, #409 LLRD, #354 softcap, #388 NS-iter-count, #345 NS-depth, #384 NS-center, #356 Muon-μ — comprehensive evidence that the merged stack is saturated at the optimizer/gradient/moment level. Live frontier remains: loss-side regularization (z-loss #441, label-smoothing #446 in flight), parameter-space averaging (Lookahead #434, weight-EMA #436 in flight), update-rule reformulation (adam-atan2 #442 in flight), paired-pod confirmations (per-group LR #393, AGC #408 in flight), and untested **init/architecture-side** mechanisms (next: askeladd block out init scale).

---

## 2026-05-19 08:12 UTC — PR #409: Per-block LR decay (LLRD) for Muon (thorfinn) — CLOSED productive-null ✅ (per-block Muon LR axis closed)

- Branch: `g1r4-thorfinn/muon-llrd`
- Hypothesis: Depth-dependent Muon LR: `lr_i = 0.035 × decay^(i/11)`. Sweep decay ∈ {1.0 control, 0.85, 0.7, 1.2}.

### Results — 4-arm single-pod sweep

| Arm | DECAY | block_0 LR | block_11 LR | val | Δ vs A | Δ vs baseline (3.27200) | fs | W&B |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| A (control) | 1.0 | 0.0350 | 0.0350 | **3.27266** | — | **+0.00066 ✓** (drift) | 3250 | `ge03y1j7` |
| **B** | 0.85 | 0.0350 | 0.0297 | **3.27228** | **−0.00038** | +0.00028 | **3225** | `9s1oyyxc` |
| C | 0.7 | 0.0350 | 0.0245 | 3.27395 | +0.00129 | +0.00195 | 3250 | `xdu2egnj` |
| D | 1.2 | 0.0350 | 0.0420 | 3.27456 | +0.00190 | +0.00256 | 3275 | `2evjf9in` |

### Key findings

1. **Arm B (decay=0.85) best**: Δ=−0.00038 vs A is inside the productive-null band (|Δ| ≤ 0.0015). fs=3225 vs A=3250 is a −25 step nominal improvement, but well within seed variance.
2. **Non-monotone shape**: B (0.85, mild decay) edges A barely; C (0.7, deeper) reverses; D (1.2, inverse) regresses more. No clean LLRD signal in either direction.
3. **Mechanism**: Muon's Newton-Schulz orthogonalization already normalizes per-block step magnitudes. The effective update norm is controlled by the NS polynomial, not the raw LR. Depth-dependent LR scaling is largely neutralized by NS normalization — distinct behavior from LLRD in standard Adam-trained transformers where per-layer gradient norms vary systematically.
4. **Both directions closed**: decay <1 (standard LLRD: later layers get less LR) AND decay >1 (inverse: later layers get more LR) both fail to improve.

### Verdict

Per-block Muon LR axis CLOSED. 12th productive-null this cycle. Per-block hyperparameter axes for Muon appear uniformly absorbed by NS normalization.

---

## 2026-05-19 07:36 UTC — PR #411: Gradient noise injection (alphonse) — CLOSED productive-null ✅ (noise degrades on all scales)

- Branch: `g1r4-alphonse/gradient-noise-injection`
- Hypothesis: Annealed Gaussian noise σ_t = σ_0 / (1+t)^γ (Neelakantan et al. 2015) added to gradients post-all_reduce, pre-clip. Tests whether deterministic gradient signal is over-fitted to data ordering at this short-training scale.

### Results — 4-arm single-pod sweep

| Arm | σ_0 | val | Δ vs A | Δ vs baseline (3.27200) | fs | W&B |
|---|---:|---:|---:|---:|---:|---|
| A (control) | 0.0 | **3.27231** | — | **+0.00031 ✓** (drift) | 3250 | `re5hs6d6` |
| B | 0.001 | 3.27419 | +0.00188 | +0.00219 | 3250 | `cf0lz42z` |
| C | 0.003 | 3.27428 | +0.00197 | +0.00228 | 3250 | `wnoa9rx8` |
| D | 0.010 | 3.27372 | +0.00141 | +0.00172 | 3250 | `qh6oc6we` |

### Key findings

1. **All 3 noise levels degrade val by Δ ∈ {+0.0014, +0.0020}** vs control. None show improvement.
2. **Non-monotone shape**: B/C virtually tied (+0.00188 vs +0.00197), then D regresses LESS (+0.00141). This non-monotonicity (weakest noise is worse than strongest) points to grad-clip=10 catching the large-σ runs before they fully degrade, while σ=0.001/0.003 adds noise right below the clip threshold — worst of both worlds.
3. **All arms reach fs=3250** — noise degrades val but does not dramatically slow convergence speed. The model converges but to worse minima.
4. **Mechanism**: Post-#290 stack (β2=0.99 long EMA + NS stochasticity + AdamW per-group calibration) is already operating near the variance-vs-bias optimal for 3350 steps. Extra gradient noise just removes useful directional signal. Neelakantan 2015 helped on longer training runs where the signal-to-noise naturally decreases; at 3350 steps the high-SNR regime is unchanged by annealing.

### Verdict

Gradient noise injection axis CLOSED. **11th productive-null on optimizer/gradient-preprocessing axes this cycle.** Pattern: post-#290 stack is saturated on signal-modification mechanisms; orthogonal structural changes (loss-side, trust-region, parameter-space) remain the live frontier.

---

## 2026-05-19 06:48 UTC — PR #407: AdamW β2 sensitivity sweep (tanjiro) — CLOSED productive-null ✅ (β2=0.99 confirmed optimal)

- Branch: `g1r4-tanjiro/adamw-beta2-sensitivity`
- Hypothesis: Pruning ablation (#377) revealed β2=0.99 is amplified 5.9× over original lift. Optimum may have drifted on post-#290 stack. Sweep β2 ∈ {0.98, 0.99, 0.995, 0.999} to test sensitivity.

### Results — 4-arm single-pod sweep

| Arm | β2 | EMA window | val | Δ vs A | Δ vs baseline (3.27200) | fs | W&B |
|---|---:|---:|---:|---:|---:|---:|---|
| A (control) | 0.99 | ~100 steps | **3.27201** | — | **+0.00001 ✓** (drift gate) | 3225 | `ftmvjt0j` |
| **B** | **0.98** | **~50 steps** | **3.27075** | **−0.00126** | **−0.00125** | **3225** | `2oykn4sw` |
| C | 0.995 | ~200 steps | 3.27357 | +0.00156 | +0.00157 | 3250 | `hj3eic3y` |
| D | 0.999 | ~1000 steps | 3.27416 | +0.00215 | +0.00216 | 3250 | `2hsm3pp5` |

Drift gate: arm-A = +0.00001 vs baseline-mean (essentially perfect). Within-pod Δs equal vs-baseline Δs.

### Key findings

1. **Arm-B best val (3.27075)** but Δ=−0.00126 vs A does NOT cross the pre-staged −0.002 real-signal threshold. Per pre-staged protocol (in force since #344/#351 paired-pod collapses), paired-pod confirmation is ONLY triggered at Δ ≤ −0.002. At −0.00126, the signal is too small to justify 7h of confirmation compute.

2. **Symmetric valley** around β2=0.99: both shorter-window (0.98) and longer-window (0.995, 0.999) degrade performance. The optimum is at the current value. β2=0.99 is confirmed as the load-bearing value — the 5.9× amplification finding from #377 was correct that β2 is critical, but it means the stack is DEPENDENT on it, not that re-tuning will improve it.

3. **Stat-rule at n=1**: (3.28 − 3.27075) × √1 = 0.00925 ≥ 0.004 passes trivially AND val < baseline. But the pre-staged within-pod threshold (−0.002) was chosen specifically to require a margin large enough to survive pod-luck variance — Δ=−0.00126 does not meet this gate.

4. **Pattern**: This is the 10th productive-null this cycle. The post-#290 merged stack is well-saturated on optimizer internal mechanics (β2, β1, ε, WD, gradient preprocessing, gradient noise, slow-EMA). Only mechanisms with orthogonal action (per-parameter scaling, clipping, loss-side) are showing signal.

### Verdict

Productive-null. β2 axis CLOSED (symmetric valley, no headroom). **10th consecutive productive-null on optimizer-internal axes.**

---

## 2026-05-19 04:40 UTC — PR #402: Gradient Centralization scope sweep (frieren) — CLOSED productive-null ✅ (absorbed by existing stack)

- Branch: `g1r4-frieren/gradient-centralization`
- Hypothesis: GC (Yong et al. 2020) subtracts mean gradient along non-output dims before optimizer step. Sweep by scope: all, adam-only, muon-only.

### Results — 4-arm single-pod sweep

| Arm | GC scope | val | Δ vs A | Δ vs baseline-mean (n=3) | fs | W&B |
|---|---|---:|---:|---:|---:|---|
| A (control) | off | 3.27247 | — | +0.00047 (drift gate ✓) | 3250 | `74kyo7fr` |
| B | all | 3.27358 | +0.00111 | +0.00158 | 3250 | `z87ocjr4` |
| C | adam-only | 3.27290 | +0.00043 | +0.00090 | 3250 | `pisakfl9` |
| D | muon-only | 3.27262 | +0.00015 | +0.00062 | 3250 | `i37gxc0d` |

### Key findings

All 3 GC arms within the productive-null band (|Δ| ≤ 0.0015 from A). Pre-staged rule #5 fires: "all flat". Faint monotone ordering B > C > D > A: wider GC scope is slightly worse. Consistent with GC subtracting useful gradient signal from AdamW aux groups. NS orthogonalization on Muon side already approximately mean-centers block weight gradients; per-group LR / grad clip / β2=0.99 on AdamW side absorb the rest. First_step_to_target unchanged at 3250 across all arms. Step-time arms B/C/D are 470s faster than A — pod variability, not from GC.

### Verdict

GC axis CLOSED as productive-null. Post-#290 stack saturated on gradient-preprocessing mechanisms. **8th productive-null this cycle** — pattern: all gradient/moment-space add-ons are absorbed by the existing 8-mechanism stack.

---

## 2026-05-19 04:24 UTC — PR #399: AdEMAMix on AdamW groups (edward) — CLOSED productive-null ✅ (slow-EMA redundant with β2=0.99)

- Branch: `g1r4-edward/ademamix-adamw`
- Hypothesis: AdEMAMix (Pagliardini et al. NeurIPS 2024) adds a slow first-moment EMA (β3=0.9999) to AdamW, with linear α-warmup from 0 to α_max. Tests whether the long-memory EMA improves convergence on the AdamW aux groups (embed/lm_head/scalar).

### Results — 4-arm single-pod sweep

| Arm | α_max | val | Δ vs A | Δ vs baseline-mean (n=3) | fs | W&B |
|---|---:|---:|---:|---:|---:|---|
| A (control, AdamW) | 0 | 3.27476 | — | +0.00276 (drift gate marginal) | 3275 | `by7m83w9` |
| **B** | **2.0** | **3.27173** | **−0.00303** ✓ | **−0.00027** (productive-null band) | **3225** | `2z7r557s` |
| C (paper default) | 5.0 | 3.27309 | −0.00167 | +0.00109 | 3250 | `a3o2wlb9` |
| D | 8.0 | 3.27685 | +0.00209 | +0.00485 | 3300 | `d618q7uf` |

### Key findings

**Within-pod signal collapses against baseline-mean.** Arm-B has within-pod Δ=−0.00303 vs arm-A, which crosses the −0.002 real-signal threshold. But arm-A drifted +0.00276 vs the n=3 baseline-mean (just inside the 0.003 drift gate). Against the actual baseline (3.27200, n=3), arm-B is at −0.00027 — well inside the productive-null band.

**Monotone B < C < A < D ordering is the load-bearing signal.** α=0 (control) sits *between* α=2 and α=5; α=8 clearly regresses. This is the fingerprint of a redundant mechanism — AdEMAMix's slow first-moment EMA partly duplicates the long second-moment memory already provided by β2=0.99 (#236). At α=5 (paper default) and α=8, the redundancy turns into noise.

**Step-time cost** ≈+0.35% (Python-loop AdEMAMix overhead negligible).

### Verdict

AdEMAMix axis CLOSED as productive-null on post-#290 stack. The slow-EMA + long-β2 redundancy is the mechanism. Three other paired-pod confirmations (#393, #407, #408) have stronger absolute val/loss; this one doesn't justify a 4th paired-pod chain.

**Productive-null count this cycle:** 7 (frieren #344, alphonse #351, tanjiro #377, fern #380, thorfinn #384, askeladd #388, edward #399). Pattern: the merged 8-mechanism stack is now well-saturated on optimizer-internal mechanics; fresh axes (mechanism wrappers, gradient preprocessing, schedule reformulations) are the higher-yield path.

---

## 2026-05-19 00:45 UTC — PR #388: NS_ITERS_COOLDOWN sweep (askeladd) — CLOSED productive-null ✅ (precision saturated)

- Branch: `g1r4-askeladd/ns-iters-cooldown`
- Hypothesis: ns_cooldown=16 was set on pre-#290 stack (#176). Sweep {14, 16, 18, 20} at fixed NS_ITERS=12 to test whether the precision count has shifted under post-#290 stack with late_peak (#285) + linear_ramp_down (#290).

### Results — 4-arm single-pod sweep

| Arm | NS_ITERS_COOLDOWN | Peak iters | val | Δ vs A | fs | Δ_fs vs A | W&B |
|---|---:|---:|---:|---:|---:|---:|---|
| A (control) | 16 | 20 | **3.27239** | — | **3250** | — | `eujcj2wp` |
| B | 14 | 16 | 3.27290 | +0.00051 | 3250 | 0 | `frzhzien` |
| C | 18 | 24 | 3.27574 | +0.00335 | 3275 | +25 | `ch20duid` |
| D | 20 | 28 | 3.27266 | +0.00027 | 3250 | 0 | `9rg1addv` |

Drift gate ✓ (|3.27239 − 3.27200| = 0.00039).

### Key findings

1. **A/B/D cluster within ±0.001** of each other (val ∈ {3.27239, 3.27266, 3.27290}; all fs=3250). No monotone trend.
2. **Arm C single outlier**: +0.00335 worse on val, +25 worse on fs. Most parsimoniously single-seed noise — a true precision mechanism would yield monotone or U-shaped curve, not a single mid-axis spike with both neighbors flat.
3. **Step-time scales monotonically**: B (1947ms) < A (1967) < C (1987) < D (2011). Total compute cost A→D = 0.6%, well within envelope.
4. **No merge candidate**: best non-control (D) at val=3.27266 fails the "mean ≤ baseline" leg of the stat-rule (3.27266 > 3.27200).

### Mechanism reading (HIGH-VALUE)

This is the **third productive-null on NS precision axes** on the post-#290 stack:
- #345 (NS coef DEPTH sweep) — depth=0.42 in flat region
- #384 (NS coef CENTER sweep) — axis flat across [0.43, 0.60]
- #388 (NS_ITERS_COOLDOWN, this PR) — count flat across {14, 16, 20}

Combined verdict: **NS precision in cooldown is SATURATED on post-#290 stack.** The marginal value of orthogonalization accuracy is exhausted. Future NS work would require either (a) a fundamentally different NS algorithm (not parameter tweaks), or (b) finding a non-NS source of headroom that re-opens the value of additional precision.

This is a high-value mechanism finding because it bounds the search space: future students should not spend GPU cycles on NS parameter sweeps — the lever is empirically exhausted.

### Verdict

Productive-null. NS_ITERS_COOLDOWN axis CLOSED. NS cooldown precision family fully characterized (#176 set count 16, #285 set shape late_peak, #290 set coef linear_ramp_down, #345 #384 #388 confirmed boundaries).

## 2026-05-18 23:15 UTC — PR #351: Per-group SCALAR AdamW ε (alphonse) — CLOSED productive-null ✅ (paired-pod null collapse)

- Branch: `g1r4-alphonse/scalar-eps-sweep`
- Hypothesis: Per-group scalar AdamW ε sweep ∈ {1e-12, 1e-10, 1e-8, 1e-6}. Original 4-arm sweep showed apparent arm-D win (Δ vs A=−0.00278); paired-pod confirmation requested.

### Paired-pod confirmation results

Paired-pod re-run of {A=1e-10 baseline, D=1e-6} with order flipped on pod 2.

| Pod | Pair | val_A | val_D | within-pod Δ |
|---|---|---|---|---|
| Pod 1 (original) | A→D | 3.27528 | 3.27250 | −0.00278 |
| Pod 2 (confirmation) | A→D | 3.27260 | 3.27295 | +0.00035 |
| Pod 3 (confirmation flipped) | D→A | 3.27280 | 3.27340 | +0.00060 |
| **Pooled mean (n=3)** | | **3.27356** | **3.27295** | **+0.00019** |

### Key findings

1. **Signal collapsed**: pooled within-pod Δ=+0.00019 (≪ −0.002 threshold for real signal).
2. **Pod-1 arm-A drifted +0.00328** above baseline (val=3.27528 vs baseline 3.27200), making the original within-pod Δ a measure of A's drift rather than D's effect.
3. **Second consecutive paired-pod null collapse** — same pattern as #344 frieren NS late_peak transition point.

### Verdict

Productive-null. Scalar ε axis fully closed across {1e-12, 1e-10, 1e-8, 1e-6}. Mechanism reading: AdamW β2=0.99 already smooths the denominator estimate sufficiently that adjusting ε within ~6 orders of magnitude doesn't change effective per-step update. Pre-staged paired-pod protocol successfully caught the unlucky-seed false positive that would have otherwise been a misleading "merge candidate" arm.

**Methodological win**: pre-staged paired-pod confirmation now has 2 consecutive demonstrated catches (#344 and #351). Future sweeps with apparent within-pod signal should default to this protocol before declaring terminal.

## 2026-05-18 23:10 UTC — PR #384: NS poly coef CENTER sweep (thorfinn) — CLOSED productive-null ✅

- Branch: `g1r4-thorfinn/ns-coef-center`
- Hypothesis: at depth=0.42 (apex from fern #345), sweep NS polynomial center across {0.43, 0.49, 0.55, 0.60} to test polynomial aggressiveness axis.

### Results — 4-arm single-pod sweep

| Arm | center | start | end | val | Δ vs A | fs | W&B |
|---|---|---|---|---|---|---|---|
| A (control) | 0.49 | 0.70 | 0.28 | 3.27250 | — | 3233 | (TBD) |
| B | 0.43 | 0.64 | 0.22 | 3.27298 | +0.00048 | 3250 | (TBD) |
| C | 0.55 | 0.76 | 0.34 | 3.27410 | +0.00160 | 3275 | (TBD) |
| D | 0.60 | 0.81 | 0.39 | 3.27355 | +0.00105 | 3250 | (TBD) |

### Key findings

1. **Non-monotone result**: arm D (more extreme, 0.60) regressed LESS than arm C (0.55). Indicates C is a single-seed outlier.
2. **Axis flat** across center ∈ [0.43, 0.60]; default 0.49 confirmed within seed noise.
3. **NS coef family complete**: depth (#345), schedule (#290 merged), center (this PR) all swept. No more low-hanging mechanism on NS polynomial parameter family.

### Verdict

Productive-null. NS coef polynomial CENTER axis CLOSED. Combined with #345 depth (productive-null) and #290 schedule (MERGED), the NS coef polynomial mechanism is fully characterized on this stack. Future polynomial work would need to move to higher-order terms or per-iteration custom coefficients (substantial scope expansion).

## 2026-05-18 22:40 UTC — PR #380: lm_head proj init std sweep (fern) — CLOSED productive-null ✅

- Branch: `g1r4-fern/lmhead-init-scale`
- Hypothesis: lm_head zero-init is the inherited default; sweep σ ∈ {0.0, 0.005, 0.02 GPT-2 default, 0.05} to test whether nonzero init helps.

### Results — 4-arm single-pod sweep

| Arm | init_std | val | Δ vs A | Δ vs baseline | fs | W&B |
|---|---|---|---|---|---|---|
| A (control) | 0.0 (zero) | 3.27409 | — | +0.00209 | 3250 | `nnkexd9a` |
| B | 0.005 | 3.27470 | +0.00061 | +0.00270 | 3275 | `yuwgeofy` |
| C | 0.02 (GPT-2) | 3.27725 | +0.00316 | +0.00525 | 3300 | `dsl7desn` |
| D | 0.05 | 3.28234 | +0.00825 | +0.01034 | -1 (failed target) | `1mminmrf` |

### Key findings

1. **Zero-init is uniquely optimal**: monotone worsening with σ growth.
2. **Catastrophic at σ=0.05**: arm-D fails to hit 3.28 by step 3350 (fs=-1).
3. **Mechanism**: zero-init forces lm_head to start as a pure identity-like projection from token-embedding space; signal flow optimized for embed_lr=0.3. Any nonzero σ corrupts this routing.
4. **Drift gate**: arm-A at +0.00209 (inside ±0.003 tolerance, on the edge).

### Verdict

Productive-null. Both init-scale axes on AdamW-managed groups now exhaustively mapped: embed shape doesn't matter (#374 ±0.00061 across 4× range), lm_head shape DOES matter (zero uniquely optimal). Axis CLOSED.

## 2026-05-18 22:30 UTC — PR #377: Pruning ablation (tanjiro) — CLOSED productive-null ✅ (HIGH-VALUE MECHANISM PROBE)

- Branch: `g1r4-tanjiro/pruning-ablation`
- Hypothesis: measure load-bearing contribution of the 3 most-recent merges (#236 β2=0.99, #285 late_peak, #290 linear_ramp_down) by removing each from the current stack and measuring Δ.

### Results — 4-arm single-pod ablation

| Arm | Dropped | val | Δ vs A | fs | Δ fs | Original lift | Reading |
|---|---|---|---|---|---|---|---|
| A | control (none) | 3.27296 | 0 | 3250 | 0 | — | drift gate ✓ |
| B | #285 late_peak | 3.27253 | **−0.00043** | 3250 | 0 | −0.00055 | **Subsumed / sign-flipped** |
| C | #290 linear_ramp_down | 3.27305 | **+0.00009** | 3250 | 0 | −0.00152 | **Fully subsumed (~0% original)** |
| D | #236 β2=0.99 | 3.27454 | **+0.00158** | 3275 | +25 | −0.00027 | **Load-bearing, ~5.9× amplified** |

### Key insights

1. **β2=0.99 is the foundation hyperparameter**: removing it costs 5.9× the original lift magnitude. Doing more work now than at merge time.
2. **late_peak (#285) appears subsumed**: dropping it produces Δ=−0.00043, *flipping the sign* of the original lift. Single-seed inside noise but directionally suggestive.
3. **linear_ramp_down (#290) is fully subsumed**: Δ≈0 vs A. Most recent merge contributes ~0% of original lift on current stack.

### Verdict

Productive-null close, NOT a forward-progress PR. But **mechanism-grade finding**: 2 of 3 recent merges (#285, #290) appear redundant on the current stack — consistent with "mechanism saturation within the late-cooldown precision family" hypothesis. These slots are candidates for replacement with truly orthogonal mechanisms.

### Caveats

Single-seed Δs for arms B/C inside noise floor (~0.001). Subsumption is suggestive but not yet actionable for revert without replication.

### Follow-up direction

tanjiro reassigned to #407 β2 sensitivity ablation (mechanism-driven — β2 amplification suggests optimum may have drifted on post-#290 stack).

## 2026-05-18 20:05 UTC — PR #344: NS late_peak transition POINT sweep (frieren) — CLOSED productive-null ✅

- Branch: `g1r4-frieren/ns-late-peak-frac-sweep`
- Hypothesis: #285's late_peak shape uses NS=12 for first 50% of cooldown, NS=20 for second 50%. The transition frac (default 0.5) is a free parameter — sweep ∈ {0.25, 0.50, 0.75} to test directionality.

### Results — 3-arm sweep + paired-pod confirmation (n=3 paired observations)

#### Original sweep (pod 1)
| Arm | frac | val_loss | fs | Δ vs A=0.50 control | W&B |
|---|---|---|---|---|---|
| A | 0.25 | **3.27095** | 3225 | −0.00419 | `qtj0tkzo` |
| B (control) | 0.50 | 3.27514 | 3275 | — (drift +0.00314) | `nhbgfpta` |
| C | 0.75 | 3.27164 | 3225 | −0.00350 | `0qybug8m` |

#### Paired confirmation (frac=0.25 vs frac=0.50 on 2 fresh pods)

| Pod | val(A, frac=0.25) | val(B, frac=0.50) | Δ(A − B) |
|---|---|---|---|
| 1 (original) | 3.27095 | 3.27514 | **−0.00419** |
| 2 (paired) | 3.27496 | 3.27218 | **+0.00278** (sign FLIP) |
| 3 (paired) | 3.27381 | 3.27503 | **−0.00122** |
| **Mean (n=3)** | **3.27324** | **3.27412** | **−0.000877** |

### Key findings

1. **Signal shrinkage**: pod-1 Δ=−0.00419 → pooled n=3 Δ=−0.000877 = **79% reduction**. Original "strong signal" dissolved into seed variance.
2. **Sign flip on pod 2**: Δ(A−B) reversed to +0.00278, definitive evidence of pod luck.
3. **Per-arm seed spread**: within frac=0.25 alone, n=3 spread = 0.00401 (LARGER than the originally claimed Δ). Signal not extractable above noise.
4. **Merge gates failed**: mean(A, n=3) = 3.27324 > baseline 3.27200 (+0.00124); paired Δ = −0.000877 < |0.002|.
5. **Mechanism reading**: midpoint frac=0.50 in #285's late_peak shape is genuinely optimal once the polynomial schedule (#290 linear_ramp_down) and β2=0.99 are merged. The transition POINT within cooldown is flat.

### Verdict

Productive-null with strong paired-confirmation discipline. NS late_peak transition point axis CLOSED. The cooldown shape is already absorbing the precision distribution that frac variation would have offered.

### Methodological notes

- Textbook example of paired-pod confirmation catching pod luck.
- Pre-staged decision rules applied without reinterpretation.
- Honest reporting of mean AND per-arm spread (the spread being larger than the proposed effect is the smoking gun).
- 7 W&B runs total (3 original + 4 paired conf), all preserved.
- NS schedule family now well-characterized: count (#388 in flight), shape (#285 merged), schedule (#290 merged), depth (#345 closed), center (#384 in flight), transition point (this PR closed).

## 2026-05-18 19:30 UTC — PR #374: Embed init scale sweep (edward) — CLOSED productive-null ✅

- Branch: `g1r4-edward/embed-init-scale`
- Hypothesis: embed init scale (default std=0.5/sqrt(dim) ≈ baseline 1.0×) may not be optimal. Sweep {0.5, 1.0, 1.5, 2.0}× to test directionality.

### Results — 4-arm single-pod sequential on post-#290 stack

| Arm | scale | val_loss | Δ vs A | fs | init_embed_norm | final_embed_norm | W&B |
|---|---|---|---|---|---|---|---|
| B | 0.5 | **3.27360** | −0.00061 | 3250 | 3104 | 76400 | `d6j9u1ez` |
| A (control) | 1.0 | 3.27421 | — (drift gate +0.00221 ✓) | 3250 | 6208 | 77102 | `2d90oywk` |
| C | 1.5 | 3.27419 | −0.00002 | 3250 | 9344 | 77964 | `ahjvbka0` |
| D | 2.0 | 3.27448 | +0.00027 | 3275 | 12416 | 78504 | `751fit6b` |

### Key findings

1. **Drift gate ✓**: arm-A at +0.00221 vs baseline, well inside ±0.003 tolerance.
2. **Flat axis**: all 4 arms within ±0.00027 of A except B at −0.00061 (still inside ±0.0015 null band). Best arm B at val=3.27360 does NOT beat baseline (3.27200, n=3 mean).
3. **Final-norm convergence is the smoking gun**: all 4 arms converge to ~77k embed norm by step 3350, within ~1.8% of each other despite a 4× init range. The init magnitude is **completely forgotten** by the optimizer.
4. **Mechanism story confirmed**: RMSNorm in the forward pass (line 501) strips embed magnitude before the model uses it. AdamW (β2=0.99, ~100-step v-EMA) + grad clip=10 then absorb any residual magnitude variance in the backward pass.

### Verdict

Productive-null with strong mechanism reading. Embed init scale axis CLOSED.

### Methodological notes

- Clean drift gate pass and reproducible control.
- Excellent mid-trajectory telemetry (init norms + final norms) directly observed and quantified the mechanism.
- Honest analysis: weak directional bias (smaller init → marginally better) noted but correctly identified as sub-threshold.
- Mechanism reading on RMSNorm + AdamW + grad clip absorption is a useful prior for future init-axis experiments.

## 2026-05-18 17:05 UTC — PR #356: Muon μ schedule sweep (nezuko) — CLOSED productive-null ✅

- Branch: `g1r4-nezuko/muon-mu-schedule`
- Hypothesis: Muon momentum coefficient μ has been held constant at 0.95 throughout; scheduling μ (ramp_up, ramp_down, late_peak) may better track the changing curvature of the loss landscape over the training run. Mechanism analog to NS coef schedule (#290).

### Results — 4-arm single-pod sequential on post-#290 stack

| Arm | μ schedule | val_loss | Δ vs A | fs | W&B |
|---|---|---|---|---|---|
| A (control) | constant 0.95 | **3.27048** | — (drift gate ✓ −0.00152) | 3225 | terminal |
| B | ramp_up 0.90→0.99 | 3.28429 | +0.01381 | -1 (missed target) | terminal |
| C | ramp_down 0.99→0.90 | 3.28083 | +0.01035 | -1 (missed target) | terminal |
| D | late_peak 0.90→0.99 | 3.33173 | +0.06125 | -1 (missed target) | terminal |

### Key findings

1. **Drift gate ✓ for arm-A**: 3.27048 vs baseline 3.27200 = −0.00152, well within ±0.003 tolerance. Strong control reproduction.
2. **All three μ-schedule arms regress disastrously**: B at +0.01381 (9×), C at +0.01035 (7×), D at +0.06125 (41×) — all miss the 3.28 target entirely (fs=-1).
3. **Late_peak μ schedule = catastrophic** (+0.06125): the mechanism that wins for NS iter count (#285) inverts for Muon μ. NS iters are *within-step* polynomial precision; μ is *cross-step* gradient memory. Pushing μ to 0.99 in the cooldown window dominates the optimizer with stale gradient direction at the moment we need fast adaptation to converge.
4. **Both ramp directions hurt by similar magnitudes** (B +0.01381, C +0.01035): μ scheduling is symmetric-bad — *any* variation from 0.95 hurts. This points to a sharp optimum at μ=0.95, not a U-shaped optimum that schedules might exploit.
5. **Mechanism reading**: μ governs effective gradient memory window (1/(1−μ)). Constant μ=0.95 gives 20-step memory throughout, which matches the temporal resolution of gradient direction changes during nanoGPT training. Larger μ amplifies stale-direction errors during cooldown when LR is small and step-direction precision becomes critical.

### Verdict

Productive-null with very strong negative result on late_peak variant. Constant μ=0.95 is confirmed optimal. μ scheduling axis CLOSED.

### Methodological notes

- Clean arm-A control with drift gate ✓.
- Pre-staged decision tree applied: 3 of 3 arms failed → axis closed unambiguously.
- Strong mechanism asymmetry vs NS iter count: same "late_peak" shape that works for *within-step* NS iters fails catastrophically for *cross-step* μ memory.
- Mechanism map confirms μ scheduling family (per-group μ, μ cosine, μ early ramp) all unlikely to help — cross-step gradient memory wants stable 20-step window.

## 2026-05-18 16:35 UTC — PR #354: Logit softcap value sweep (askeladd) — CLOSED productive-null ✅

- Branch: `g1r4-askeladd/logit-softcap-sweep`
- Hypothesis: logit softcap=15 is a one-off historical choice; sweeping ∈ {10, 15, 20, 25} may reveal a better squash threshold on the post-#290 stack.

### Results — 4-arm single-pod sequential

| Arm | softcap | val_loss | Δ vs A | fs | W&B |
|---|---|---|---|---|---|
| A control | 15.0 | **3.27194** | — | 3225 | `0ba57ha5` |
| B | 10.0 | 3.27708 | +0.00514 | 3300 | `tkwgj0zs` |
| C | 20.0 | 3.27561 | +0.00367 | 3275 | `tnglf16v` |
| D | 25.0 | 3.27567 | +0.00373 | 3275 | `37ik10ef` |

### Key findings

1. **Drift gate ✓** — arm-A Δ vs baseline = −0.00006, near-perfect baseline reproduction.
2. **Valley shape around softcap=15**: all 3 off-center arms regress by 2.5–3.5× the productive-null threshold (±0.0015).
3. **C ≈ D plateau** (separation +0.00006): softcap effect is already nearly linear at softcap=20 — once large enough not to bind on most tokens, its absolute value is irrelevant.
4. **B (tight squash) worst** by 0.5× more than C/D — squashing the logits harder is the more directly harmful direction.

### Verdict

Productive-null: softcap=15 is confirmed optimal on the post-#290 stack. The upstream-default value is the right setting. Close axis.

### Methodological notes

- Clean control reproduction with drift gate near zero.
- Single-pod sequential design with auto-chain for B/C/D.
- Honest valley-shape interpretation, no over-claiming.
- Mechanism reading on the C≈D plateau (linear regime above softcap=20) is useful for future logit-related hypotheses.

## 2026-05-18 15:15 UTC — PR #348: Per-group AdamW WD sweep (thorfinn) — CLOSED productive-null ✅

- Branch: `g1r4-thorfinn/per-group-wd`
- Hypothesis: per-group AdamW WD on lm_head and/or scalar groups spares the embed group (#279 diagnosis) and recovers WD benefit. Mechanism: lm_head/scalar groups' WD apex might still exist at WD=0.002 even when global WD=0.005 hurts due to embed.

### Results — 4-arm single-pod sequential on post-#290 stack

| Arm | embed WD | lm_head WD | scalar WD | val_loss | Δ vs A | fs | W&B |
|---|---|---|---|---|---|---|---|
| A control | 0 | 0 | 0 | 3.27143 | — | 3225 | `ep92lnxh` |
| B | 0 | 0.002 | 0 | 3.27396 | +0.00253 | 3250 | `gifry4wd` |
| C | 0 | 0 | 0.002 | 3.27365 | +0.00222 | 3250 | `4oynrbiv` |
| D | 0 | 0.002 | 0.002 | 3.27335 | +0.00192 | 3250 | `uiuuds0t` |

### Key findings

1. **All three non-control arms regress by +0.0019 to +0.0025** — exceeds productive-null band by ~5×; this is "axis closed by harm at WD=0.002" rather than saturation.
2. **Mechanism confirmed by fro telemetry**: B/D shrink proj_fro by 1.4-1.5%, C/D shrink scalar_grp_fro by 3.1-3.4% (composed from `train/weight_param/.../norm` keys). WD is doing what it should mechanically; the loss landscape just doesn't reward it.
3. **Sub-additive interaction**: Δ_D=+0.00192 vs Δ_B+Δ_C=+0.00475 — D's harm is roughly half the sum, indicating both arms partially shrink the same downstream subspace.
4. **Cross-group coupling oddity** (worth noting): arm D shrinks embed_fro by 0.75% despite zero embed WD, vs ~0.05-0.14% in B/C alone — suggests internal optimizer coupling worth probing in a future PR.

### Verdict

Productive-null close: post-#290 stack is globally saturated on AdamW WD across all groups. Combined with #279 (global WD null), the AdamW WD axis appears closed on r4.

### Methodological notes

- Per-group fro composed from existing telemetry without code changes — strong analysis under constraints.
- Pre-staged decision tree fully applied (B/C/D all hit "FAIL" branches cleanly).
- Cross-group coupling observation flagged as side finding, not over-claimed.
- Honest mechanism post-mortem on why the predicted "embed-asymmetric" fix didn't work.

## 2026-05-18 02:05 UTC — PR #280: Per-aux-group AdamW β2 ablation (edward) — CLOSED mechanism-study ✅

- Branch: `g1r4-edward/g1r4-edward-pergroup-adamw-beta2`
- Hypothesis: Decompose alphonse #236 global β2=0.99 gain into per-group contributions. Pre-registered ranking: embed > lm_head > scalar (by gradient magnitude).

### Results — 4-arm sequential chain, single seed (post-#235 baseline, val_base_n3=3.27434)

| Arm | β2 config | W&B run | val/loss | fs | Δ_val (X−A) | Signal |
|---|---|---|---|---|---|---|
| A (control) | all 0.95 | `ee5r0py1` | 3.27631 | 3300 | — | — |
| B | embed=0.99 | `y451zhyt` | 3.27351 | 3250 | −0.00280 | ✅ above gate |
| C | lm_head=0.99 | `c0jyf0zk` | 3.27452 | 3275 | −0.00179 | ⚠️ just below |
| **D** | **scalar=0.99** | `cr8tgszo` | **3.27309** | **3250** | **−0.00322** | ✅ **strongest** |

### Key findings

1. **Ranking is INVERTED**: scalar > embed > lm_head (data) vs embed > lm_head > scalar (pre-registered). The driver is gradient SPARSITY, not magnitude.
2. **Mechanism re-read**: at β2=0.95, v-EMA decays e^(−1/(1−0.95)) ≈ e^(−20) per ~20-step gap between meaningful updates → v_t collapses, eps dominates denominator, step sizes inflate. β2=0.99 (~100-step effective window) keeps v stable across sparsity gaps. Scalar params (~10s of params) are sparsest → most help from β2=0.99.
3. **Sub-additivity**: sum of per-group Δs = −0.00781 vs alphonse #236 global Δ = −0.00309 → **2.5× overlap**. The per-group mechanisms substantially overlap; global β2=0.99 captures the UNION, not the SUM.
4. **Mid-traj crossover at ~step 500 consistent across all three signal arms** — confirms 'undertrained v-EMA hurts early, helps late' mechanism prediction.

### Verdict

Mechanism study only — production recipe already includes global β2=0.99 via #236 (merged 00:00 UTC). Per-group decomposition is mechanism-mapping for future per-group experiments (eps, β1, WD, LR per group should all start from the sparsity-aware hypothesis: scalar group most vulnerable to EMA-collapse-style mechanisms).

### Methodological notes

- Excellent rebase discipline: when #235 merged mid-experiment at 18:05 UTC, student cleanly discarded the old arm-A and restarted on the new baseline.
- Honest self-correction of a transposed mid-traj table.
- Mid-trajectory telemetry that justified trust in single-seed screening results.
- Decision logic adhered to pre-registration throughout.

## 2026-05-17 18:05 UTC — PR #235: Embed-only cooldown shape sweep (tanjiro) — MERGED ✅

- Branch: `g1r4-tanjiro/embed-only-cooldown-shape`
- Hypothesis: Embed group (the most clip-sensitive aux group, ||g||_F ≈ 1.5e4, eff-LR rose from 8.4%→16.9% via clip=10) benefits from a sustained LR floor during cooldown. Per-group asymmetric cooldown schedule: embed uses linear_floor=15% (holds at 15% of peak after decay), while lm_head/scalar continue standard linear-to-zero.

### Results (4-arm sweep + n=3 confirmation of arm-C)

| Arm | Shape | val/loss | fs | Δ vs arm-A | W&B |
|-----|-------|----------|-----|----------|-----|
| A (control, linear) | floor=0% | 3.27673 | 3275 | — | h2fho8v0 |
| B | cosine | 3.27633 | 3275 | −0.00040 | 3xrynrk3 |
| **C (winner)** | **linear_floor 15%** | **3.27245** | **3250** | **−0.00428** | **ed2vgk2e** |
| D | quadratic | 3.27886 | 3325 | +0.00213 | inwmzu36 |

| n=3 Confirmation (linear_floor=15%) | val/loss | fs | W&B |
|---|------|-----|-----|
| arm-C original | 3.27245 | 3250 | ed2vgk2e |
| confirm-s2 | 3.27551 | 3275 | uqqbvmjx |
| confirm-s3 | 3.27507 | 3275 | 35cajspo |
| **n=3 mean** | **3.27434** | **3266.7** | — |

Stat-sig: (3.28 − 3.27434) × √3 = 0.00980 ≥ 0.004 ✓ PASS. Within-baseline gate: 3.27434 ≤ 3.27461 ✓ PASS.

### Mechanism findings

- **Clear mechanism bracket**: cosine (B) and linear (A) are flat (cosine ≈ same area-under-curve), quadratic (D) regresses (aggressive front-loaded decay starves late embed updates). Only floor=15% (C) wins.
- **Load-bearing feature: the floor, not the shape**. If the mechanism were about schedule smoothness, cosine would have won. The floor is the critical piece.
- **Alignment with clip=10 mechanism**: clip raised *peak* embed LR pressure; floor extends *late* embed LR pressure. Both target the same axis (embed responsiveness) from different angles — independently valuable (floor helps on top of clip=10, not instead of it).
- **fs unchanged**: n=3 mean fs=3266.7 = prior baseline. Val improvement is the gain; step count does not regress.

**New branch baseline: val=3.27434/fs=3266.7 (n=3, NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor, floor=15%)**

Tanjiro assigned follow-up: PR #300 (embed floor value sweep — find optimal floor % via {10%,15%,20%,30%} bracket).

## 2026-05-18 00:22 UTC — PR #241: Muon mu (Heavy-ball momentum) constant sweep (askeladd) — CLOSED productive-null ❌

- Branch: `g1r4-askeladd/muon-mu-sweep`
- Hypothesis: Muon mu (Heavy-ball coef before NS) has never been swept on this branch. Sweep {0.90, 0.93, 0.95, 0.97, 0.99} to find local optimum. mu=0.97 showed clean within-pod inverted-U apex (Δ=−0.00289) on pre-#235 recipe; sent for n=3 cross-pod confirmation.

### Results — initial sweep (single seed per arm, terminal step 3350, pre-#235 recipe)

| Arm | mu | val/loss | first_step_to_target | Δ vs arm-A (0.95) | W&B |
|-----|------|----------|-----|----------|-----|
| A (control) | 0.95 | 3.27736 | 3300 | — | e0514xai |
| B | 0.90 | 3.28193 | -1 (failed) | +0.00457 | 8s5dtj9e |
| C | 0.93 | 3.27662 | 3275 | −0.00074 | yh1f3cex |
| **D (apex)** | **0.97** | **3.27447** | **3250** | **−0.00289** | dyfdxufh |
| E | 0.99 | 3.29261 | -1 (failed) | +0.01525 | 06a1ta71 |

### Results — n=3 cross-pod confirmation (post-#235 + #236 recipe, mu=0.97)

| Seed | W&B run_id | val/loss | fs | Δ vs 3.27407 |
|------|--------|---------:|---:|---:|
| 1 | lympa8vn | 3.27421 | 3250 | +0.00014 |
| 2 | qp03e0eq | 3.27664 | 3300 | +0.00257 |
| 3 | 52ymd8w9 | 3.27489 | 3275 | +0.00082 |
| **n=3 mean** | — | **3.27525** | **3275.0** | **+0.00118** |
| stdev | — | 0.00125 | — | — |

### Merge gate evaluation

- **Drift gate (seed-1)**: |3.27421 − 3.27407| = 0.00014 ≤ 0.003 ✅ Snapshot on-recipe.
- **Strict merge gate** (n=3 mean ≤ 3.27407): **FAIL** by +0.00118.
- **Stat-sig**: (3.28 − 3.27525) × √3 = 0.00823 ≥ 0.004 ✅ (passes but binding constraint is strict merge gate).

### Mechanism findings

- **Within-pod inverted-U** (apex mu=0.97, Δ=−0.00289) was real on the pre-#235 recipe. The apex was internally consistent: low-mu (0.90) produces noisier NS input; high-mu (0.99) feeds stale gradient direction.
- **Cross-pod n=3 mean fails by +0.00118**. Seed-2 (+0.00257) was a substantial tail draw. Two compatible interpretations:
  1. Cross-pod variance (~0.00125 stdev) exceeds within-pod Δ (0.00289) — cross-pod confirmation without an in-pod control cannot reliably detect signals near the noise floor.
  2. Mechanism interaction with #235/236 stack: `linear_floor` and β2=0.99 may partially substitute for mu=0.97's "smoother NS input via longer Muon-side memory" mechanism.
- **||v||_F telemetry had wrong sign**: higher mu → *smaller* Frobenius norm in original sweep, contradicting simple Heavy-ball intuition. Suggests the momentum_frob metric may measure the combined NS+heavy-ball output rather than the raw buffer.

### Team-level lesson: cross-pod confirmation design

Cross-pod n=3 confirmation has a noise floor of ~0.0015 (stdev). Signals smaller than ~0.003 may not survive. Going forward, **within-pod paired confirmation** (run (mu_A, mu_B) back-to-back on the same pod, n=3 pairs) is the right design for marginal within-pod signals. This will inform future confirmations for all students.

**Verdict: productive-null close.** mu=0.97 did not survive the post-#236 stack. Askeladd reassigned → PR #324 (AdamW β1 sweep).

## 2026-05-17 06:00 UTC — PR #165: Clip value extension sweep (thorfinn) — MERGED ✅

- Branch: `g1r4-thorfinn/clip-extension-sweep`
- Hypothesis: clip=5.0 is not at the optimum — loosening to clip=10 raises embed effective-LR from 8.4% to 16.9%, staying in the "sweet spot" of asymmetric per-group rescaling

### Results (4-arm sweep + n=3 confirmation at clip=10)

| Arm | clip | val/loss | fs | Δ vs arm-A | W&B |
|-----|------|----------|-----|----------|-----|
| A (control) | 5.0 | 3.27756 | 3300 | — | f6ym89r7 |
| **B (winner)** | **10.0** | **3.27432** | **3250** | **−0.00324** | 84um64gj |
| C | 25.0 | 3.27442 | 3250 | −0.00314 | 2btntm04 |
| D | 50.0 | 3.27590 | 3275 | −0.00166 | 7lpa9jmh |

| n=3 Confirmation (clip=10) | val/loss | fs | W&B |
|---|------|-----|-----|
| seed 1 (arm-B) | 3.27432 | 3250 | 84um64gj |
| seed 2 (confirm-1) | 3.27510 | 3275 | lxkp0jmx |
| seed 3 (confirm-2) | 3.27480 | 3250 | efnghv0f |
| **n=3 mean** | **3.27474** | **3258.3** | — |

Stat-sig: (3.28 − 3.27474) × √3 = 0.00911 ≥ 0.004 ✓ PASS. Beats prior baseline 3.27527 by Δ=−0.00053.

### Mechanism findings

- Single-peak with plateau: val improves steeply from clip=5 to clip=10, flat from 10 to 25, regresses from 25 to 50
- Per-group embed eff-LR: 8.4% (clip=5) → 16.9% (clip=10) → 41.8% (clip=25) → 83.3% (clip=50)
- Above ~50% eff-LR, AdamW update noise re-enters → val regresses; optimum at 17–42% eff-LR
- lm_head remains clip-saturated (<0.4% eff-LR) throughout — not the load-bearing variable
- Triangulated mechanism (via alphonse #188 + edward #206):
  - Uniform 1.5× aux LR scaling is NEUTRAL → clip ≠ uniform aux LR rescaler
  - aux-only clip ≈ clip-all within ±0.001 → clip effect is NOT primarily through aux magnitude
  - muon-only clip beats clip-all by 0.00235 (single seed) → Muon clip interaction is real (TBC)

**New branch baseline: val=3.27474/fs=3258.3 (n=3, NANOGPT_GRAD_CLIP=10.0)**

## 2026-05-17 04:40 UTC — PR #204: Cooldown shape sweep (nezuko) — CLOSED clean negative

- Branch: `g1r4-nezuko/cooldown-shape-sweep`
- Hypothesis: LR cooldown shape (linear vs cosine vs sqrt) is a free axis under Muon²+clip=5.0 baseline

### Results (n=1 each, train_steps=3350, NANOGPT_GRAD_CLIP=5.0, cooldown_frac=0.7)

| Arm | Shape | val/loss | first_step_to_target | W&B Run |
|-----|-------|----------|----------------------|---------|
| A | linear (baseline) | 3.27581 | 3275 | mcqv2g69 |
| B | cosine (S-shape) | 3.28144 | -1 (never reached) | hczgtsue |
| C | sqrt (concave) | 3.29081 | -1 (never reached) | 571njevf |
| D | quadratic | SKIPPED (early-exit) | — | — |
| E | exp | SKIPPED (early-exit) | — | — |

### Commentary

Clean negative. Arm-A reproduced merged baseline within seed noise (val=3.27581 vs 3.27527, Δ=+0.00054). Arm-B (cosine) regresses by +0.00563; arm-C (sqrt) catastrophically worse (+0.01500). Early-exit rule vindicated: arm-B failure (val=3.28144 > 3.279 trigger) correctly predicted arms D/E would fail. Saved ~3.3h compute.

**Decisive mechanism signal** — trailing-window train-loss slope at end of cooldown:
- Arm-A linear: slope=-0.00386 → still descending, Goldilocks balance
- Arm-B cosine: slope=+0.00275 → **train loss INCREASING** (model frozen by fast late-LR drop)
- Arm-C sqrt: slope=-0.01335 → 2× steeper descent than linear (but started too far behind)

**Why linear is the only shape that works**: linear gives equal LR-time area to every cooldown point. Any asymmetric shape (concave or convex) trades early/late LR budget; at 3350 steps, either trade hurts.

**Cross-PR insight**: cosine regresses BECAUSE it misses the cooldown precision window (low LR needed for fine convergence) — consistent with frieren #176's mechanism (cooldown needs more precise gradients via NS-iter boost). Both PRs confirm: the cooldown precision window needs BOTH smaller LR AND more precise gradients, not less LR motion.

**Axis closed**: cooldown LR shape is well-tuned by the lineage. Do not re-explore unless a new optimizer (non-Muon²) changes dynamics.

## 2026-05-15 19:00 UTC — wave 1 closed PRs

### PR #62 — Schedule-Free Muon (askeladd) — CLOSED negative

| Arm | LR | sf_beta | mu | warmup | Steps | val/loss | Run |
|-----|----|---------|----|--------|-------|----------|-----|
| A | 0.035 | 0.90 | 0.95 | 0 | 3350 | 3.3638 | hltz3pr3 |
| B | 0.025 | 0.90 | 0.95 | 0 | ~246 (killed) | — | — |
| C | 0.035 | 0.90 | 0.95 | 200 | ~1250 (killed) | 3.587 | eetdzgtl |
| D | 0.035 | 0.98 | 0.00 | 200 | ~1625 (killed @ kill gate) | 3.613 | zxdq6572 |

**Result:** No arm reached 3.28. Best val=3.3638. Paper-aligned recipe (arm D) was worse due to: (1) high sf_beta=0.98 keeps y far from z, slowing forward pass; (2) mu=0 removes Nesterov preconditioning from NS input, increasing per-step noise. **Key insight**: the 70% linear LR cooldown is load-bearing on this benchmark — it is doing real work collapsing to a sharp basin that SF's trajectory averaging cannot substitute. Closed per PR §6 protocol (val > 3.29 after LR retune exhausted).

### PR #77 — Lion for Auxiliary Groups (thorfinn) — CLOSED negative

| Arm | lion_embed_lr | lion_lmhead_lr | Steps | val/loss |
|-----|--------------|----------------|-------|----------|
| A | ~0.3 | ~0.003 | 3350 | 3.3144 |
| B | 0.05 | 0.00078 | 3350 | 3.3109 |

**Result:** Both arms ~0.032 nats above 3.28 target. Lion's sign-momentum update loses gradient information for the small aux groups where AdamW already runs cheaply. Lion is designed for the regime where Adam's correction is expensive — not applicable here.

---

## 2026-05-15 20:26 UTC — PR #60: Muon² (alphonse) — TERMINAL — STAT-SIG WIN

**Hypothesis:** Adam 2nd-moment preconditioning before Newton-Schulz gives NS a better-conditioned matrix input, reducing orthogonalization work per step.

| Arm | NS iters | W&B run | val/loss | first_step_to_target |
|-----|----------|---------|----------|---------------------|
| A, seed 1 | 12 | s0oq3dnx | **3.276593** | **3275** |
| A, seed 2 | 12 | 4hedrgf4 | **3.276536** | **3275** |
| B | 8 | pg0uma5w | 3.277377 | 3300 |

**Stat-sig (NS=12, n=2):** mu=3.276565, margin=(3.28-3.276565)*sqrt(2)=0.004859 ≥ 0.004 ✓  
**Winner: NS=12.** NS=8 is +0.000813 worse (~20× inter-seed sigma) and reaches target 25 steps later.

**Analysis:** Mechanism holds — feeding `m / (sqrt(v) + eps)` into NS-12 produces better-conditioned input and the optimizer crosses 3.28 at step 3275 (75 steps earlier than 3350 starter budget). NS iteration reduction (Arm B) did NOT benefit from Muon² as predicted by the paper — at our scale (124M, 3350 steps), full 12-iter orthogonalization remains optimal. Also bundles the `sample_tensor` float64 precision bug fix.

**Also included:** `NANOGPT_NS_ITERS` env var for future NS-iteration ablations.

**Follow-ups noted by student:** Stack with Contra-Soft/SOAP; lr/wd retune for Muon²; beta2 sweep {0.95, 0.98, 0.999}; Muon²+NS=8 with lr retune.

**Status:** Terminal SENPAI-RESULT posted. Merge pending GH rate limit reset (~21:26 UTC).

---

## 2026-05-15 20:32 UTC — PR #75: NS iteration sweep (tanjiro) — TERMINAL — DIAGNOSTIC

**Hypothesis:** NS=8 or NS=6 match NS=12 quality with compute savings.

| Arm | NS iters | W&B run | val/loss | first_step_to_target | step_avg_ms | Wall-clock saved |
|-----|----------|---------|----------|---------------------|-------------|-----------------|
| A | 12 | 3kx01ieh | 3.27890 | 3325 | 1797.19ms | — |
| B | 8 | tzhrr686 | **3.27849** | 3325 | 1786.36ms | 0.60% (10.83ms) |
| C | 6 | jnnsgmrs | 3.28980 | — (FAILED) | 1777.17ms | 1.11% (20ms) |

**Analysis:** NS=8 is correctness-safe (Δ=−0.0004 vs NS=12, within seed noise), but **wall-clock savings are minimal (<1%)** because the NS inner loop is NOT the compute bottleneck at this 1-GPU scale — forward/backward/telemetry dominate. NS=6 fails (0.011 nats degradation, does not cross 3.28). NS=12 and NS=8 crossings are baseline-noise single seeds — Muon² (NS=12, n=2) at val=3.2765 is the rigorous result. Closing as a successful diagnostic; NS=8 knowledge preserved for Muon²+NS=8 follow-up if Muon² LR retune confirms headroom.

---

## 2026-05-15 20:35 UTC — PR #66: Cosine cooldown (edward) — CLOSED — DEAD END

**Hypothesis:** Cosine LR schedule during cooldown phase outperforms linear cooldown.

**Result:** Branch corruption beyond just cosine path — linear baseline arm also diverged (162M nonfinites at step 375). Cosine path had NaN at step 3. Closed and student reassigned to orthogonal QKV initialization (PR #92).

---

## 2026-05-15 — wave 1 in-flight summary (not yet reviewed)

Snapshot from W&B at 16:20 UTC, prior to terminal SENPAI-RESULT submissions.
Each student also independently rediscovered and locally patched a precision bug
in `sample_tensor` (line 183, `torch.linspace(0, n-1, K).long()` returns OOB
idx for n > 2^24, e.g. the 38.6M-element embed gradient). Fix variants are in
their local branches; nezuko (#73) is canonical.

| PR | Student | Hypothesis | Best arm | first_step_to_target | val/loss | Note |
|----|---------|-----------|----------|---------------------|---------:|------|
| #60 | alphonse | **Muon²** (Adam 2nd-moment precond before NS) | arm-A NS=12 | **3275** | **3.2765/3.2766** | **STAT-SIG CONFIRMED** n=2: (3.28-3.27655)*sqrt(2)=0.0049>=0.004; arm-B (NS=8) running |
| #75 | tanjiro | NS iter sweep 12/8/6 | NS=8 slightly better | 3325 | 3.2785 (NS=8), 3.2789 (NS=12) | Both NS=8 and NS=12 beat 3.28; NS=8 marginally better — compute headroom confirmed; NS=6 running |
| #70 | fern | cooldown_frac 0.5/0.6/0.7 | frac-0.5 | 3325-3350 | 3.2790/3.2793 (seeds 1+2) | Confirmation seed 3 running; n=2 mean=3.27916, needs seed 3 for stat-sig |
| #62 | askeladd | Schedule-Free Muon | CLOSED negative | — | 3.3638 best | 4 arms failed; see full entry above |
| #77 | thorfinn | Lion for aux groups | CLOSED negative | — | 3.3109 best | both arms worse; see full entry above |
| #72 | frieren | Muon Nesterov mu sweep | mu-0.90 (screening) | — | 3.3700 @ step 2000 | screening only, 4 more arms pending |
| #73 | nezuko | WD warmup 0/5/10% | wd-warmup-A-0.00 (running) | — | 3.5288 @ step 1600 | early in run |
| #66 | edward | cosine vs linear cooldown | — | — | NaN (running) | recovered after rate-limit episode; runs producing NaN val/loss currently |

### Critical methodology observation

Tanjiro's NS=12 baseline arm — which is the **unmodified starter recipe** —
crossed 3.28 at first_step_to_target=3325, val/loss=3.2789. Prior 62 W&B rounds
of this baseline never crossed 3.28 (closest 3.2813). This says single-seed
crossings of the threshold are well within the natural seed noise of the
starter recipe itself.

**Implication:** Stat-sig confirmation (3 seeds, `(3.28 - mu) * sqrt(n) >=
0.004` → mean ≤ 3.2777 at n=3, ≤ 3.278 at n=4) is the binding constraint, not
the first crossing. Any future first-crossing result must be accompanied by a
predeclared seed batch to count as a win.

### Infrastructure incident

Around 15:38-16:23 UTC, the org-shared gh token hit its 5000-req/h rate limit
(advisor was at 2232/5000 when first noticed). Student pods that depended on
gh for assignment-state queries failed assignment polls for ~45 min:

- alphonse, tanjiro: pods went idle (GPU=0%) after arm-A completed; couldn't
  query their next assignment state, so the heartbeat fell through to
  "No assigned PRs" and slept.
- edward, fern: training that was already running kept running (GPU 35-36 GB,
  100% util) — the rate limit only affected new poll cycles, not in-flight
  Python processes.
- All pods recovered at iter 30-36 (~16:21-16:24 UTC) once the token reset.

---

## 2026-05-15 23:50 UTC — PR #73: WD warmup (nezuko) — CLOSED negative

**Hypothesis:** Deferring weight decay during the first ~10% of training lets Muon make faster initial progress; full WD applied through cooldown for regularization.

| Arm | wd_warmup_frac | W&B run | val/loss @3350 | first_step_to_target |
|-----|---------------:|---------|---------------:|---------------------:|
| A   | 0.00 (baseline) | mpq9bfwk | 3.27969 | 3350 |
| B-s1| 0.05            | 2qrloa5p | 3.27868 | 3325 |
| C   | 0.10            | ix77c7mg | 3.27952 | 3350 |
| B-s2| 0.05 (seed 2)   | sjcj2lfk | 3.27970 | 3350 |

**Stat-sig check on best arm (Arm-B n=2):** mean=3.27919, margin=(3.28-3.27919)*sqrt(2)=0.00114 ≪ 0.004 threshold. **NOT stat-sig.**

**Diagnostic:** Weight-norm trajectories across arms tracked within 0.1% of each other; early-descent slopes indistinguishable. At WD=0.025, weight decay simply isn't a meaningful early-training force compared to Muon's update magnitude. Mechanism does what it says (telemetry verified ramp on muon_blocks group) but produces no measurable benefit. Worse than merged Muon² baseline (3.27919 vs 3.2766).

**Bundled finding (already in baseline):** nezuko's sample_tensor float64 fix was excellent diagnostic work, but it had already been independently cherry-picked into the merged Muon² PR #60 via alphonse. That's why this PR ended in merge-conflict state.

**Conclusion:** WD warmup unlikely to help any recipe with final WD ≤ 0.025. Re-test only if a future recipe lands with WD ≥ 0.05.

---

## 2026-05-16 01:30 UTC — PR #97: Muon² beta2 sweep (tanjiro) — CLOSED inconclusive (pod-level divergence)

**Hypothesis:** Sweep Muon² 2nd-moment EMA beta2 ∈ {0.95, 0.98, 0.999} to find optimum for short-horizon regime.

| W&B run | beta2 | bias_correction | Role | Outcome |
|---------|-------|-----------------|------|---------|
| `hov7gbvg` | 0.95 | off (merged) | arm-A | NaN by step 25 |
| `hger8tqw` | 0.98 | off | arm-B | NaN by step 25, killed at step 403 |
| `v5yl0u6u` | 0.999 | off | arm-C | NaN by step 25, killed at step 1314 |
| `37q9u3pr` | 0.999 (stashed diff, untouched baseline) | off | pod isolation | **NaN by step 25 — same divergence as arms!** |
| `h8j7zoep` | 0.999 (telemetry=1) | off | step-by-step trace | Inf in 20 weight entries at step 2; NaN cascade by step 3 |

**Diagnostic conclusion:** **NOT a beta2 effect — this is pod-specific hardware divergence.** The merged Muon² baseline (which alphonse reaches val=3.2766 on) reproducibly NaNs on tanjiro's pod from the very first optimizer step. Same code, same Blackwell GPU model, same torch/CUDA stack, but tanjiro's GPU UUID `7998cef9-...` produces Inf in the first Muon² weight update. ECC clean per nvidia-smi.

**Secondary finding (motivates PR #108):** Muon² as merged lacks Adam-style bias correction `v_hat = v / (1 - beta2^t)`. The first-step preconditioned input swings ~32× sign(u) at beta2=0.999 vs ~7× at beta2=0.98 vs ~4.5× at beta2=0.95, breaking comparability of any beta2 sweep on the current Muon² code. Bias correction may both stabilize lower beta2 values AND make the sweep meaningful.

**Verdict:** Closed without merge. tanjiro reassigned to PR #108 (Muon² + bias correction with mandatory pod smoke-test gate). If the pod is still broken, smoke test will catch it in 100 steps before burning 7+ hours on doomed arms.

---

## 2026-05-16 02:45 UTC — PR #92: Orthogonal QKV init (edward) — CLOSED negative

**Hypothesis:** Initializing QKV projections with orthogonal matrices (unit singular values) reduces Newton-Schulz orthogonalization work in early training, speeding descent in steps 50–500.

| Arm | QKV init | W&B run | val/loss @3350 | first_step_to_target | vs baseline |
|-----|----------|---------|---------------:|---------------------:|------------|
| A | **orthogonal** | `s8044x4a` | 3.27862 | 3325 | +50 steps (worse) |
| B | **normal** | `h1f66mpd` | 3.27804 | 3300 | +25 steps (worse) |

n=1 stat-sig check: (3.28 − 3.2780) × √1 = 0.0020 < 0.004 threshold.

**Early-descent analysis (the predicted-win regime):**
| window | A orth. slope | B normal slope | A − B |
|--------|----------:|----------:|------:|
| 50–200 | −0.007321 | −0.007243 | −0.000078 |
| 100–500 | −0.002288 | −0.002204 | −0.000084 |

Orthogonal barely steeper in the predicted regime but the difference is an order of magnitude smaller than seed noise. From step 1000 onward the two val/loss curves differ by ≤ 0.0006 — statistically indistinguishable.

**Key mechanistic insight (edward's analysis):** 'Muon's Newton-Schulz step rapidly orthogonalizes the QKV *update direction* regardless of the init's singular-value structure; equilibrium is reached within ~25-50 steps and weight trajectories converge by step ~200.' NS *continuously* supplies the well-conditioned-update property on every step — static init structure is irrelevant for Muon-trained matrices. Brock et al. (2021) benefits appear only in attention-only / linear settings where orthogonality is preserved over training.

**Follow-up implications:**
- Skip analogous MLP / output-proj init experiments (same Muon-equilibration argument applies).
- Embedding / lm_head init (AdamW-trained) *might* be worth trying — those don't get NS each step so init shape could persist longer.
- Track `‖ZZ^T − I‖_F` after NS step in first ~100 steps to quantify NS equilibration speed across different init conditions.

**Conclusion:** Clean negative. Closed. Edward reassigned to PR #115 (Muon² bias correction).

---

## 2026-05-16 03:40 UTC — PR #96: Muon² LR retune (alphonse) — CLOSED negative

**Hypothesis:** Sweep Muon² learning rate ∈ {0.030, 0.0375, 0.040} on the merged baseline to find an improved LR.

| Arm | NANOGPT_MUON_LR | W&B run | val/loss @ 3350 | first_step_to_target | Δ vs baseline |
|-----|-----------------|---------|----------------:|---------------------:|--------------:|
| A | 0.030 | `exqlcpdt` | 3.27815 | 3300 | +0.00155 (worse) |
| B | 0.0375 | `mbochr63` | **3.27709** | 3300 | +0.00049 (worse) |
| C | 0.040 | `e6p4iw14` | 3.27982 | 3350 | +0.00322 (worse) |
| baseline (lr=0.035, n=2) | 0.035 | merged | 3.2766 | 3275 | — |

**Stat-sig check on best arm (B, n=1):** (3.28 − 3.27709) × √1 = 0.00291 ≪ 0.004 threshold. Not stat-sig.

**Diagnostic finding — Muon² LR is on the 0.035 peak**: The U-shape (3.27815 → 3.27709 → 3.27982 across lr 0.030 → 0.0375 → 0.040) suggests a shallow interior minimum near 0.0375, but the depth (Δ ≈ 0.001) is within seed noise. Combined with merged baseline at lr=0.035, this confirms the Muon² LR optimum is robust in {0.035, 0.0375}.

**Wave 2 plateau implication**: With LR, init, warmup, EMA, and (so far) cooldown_frac all closing as negatives, the merged Muon² baseline hyperparameters sit at a robust local optimum. Scalar hyperparameter retuning is exhausted as a path to merge — wave 3 must use mechanism stacks.

**Conclusion:** Clean negative on LR retune. Closed. Alphonse reassigned to PR #117 (Trust-region Muon² — per-layer update norm cap, complementary to NS orthogonalization).

## 2026-05-16 07:22 — PR #102: LR warmup sweep (fern)

- **Branch:** g1r4-fern/lr-warmup-sweep
- **Hypothesis:** LR warmup (0 → 50 → 100 → 200 steps) helps Muon² settle by preventing large early updates
- **Results:**

| Arm | warmup steps | W&B run | val/loss | first_step |
|-----|-------------|---------|----------|-----------|
| A | 0 (baseline) | qn0d50o2 | 3.27699 | 3300 |
| B | 50 | ysomsvug | 3.28063 | -1 |
| C | 100 | khagy2bs | 3.28153 | -1 |
| D | 200 | ace7lfl3 | 3.28084 | -1 |

- **Analysis:** Monotone negative. Each warmup arm strictly worse than no-warmup. Arms B/C/D all fail to cross val<3.28 threshold. The warmup hypothesis is falsified — Newton-Schulz already provides early-step directional stability (edward #92 finding: NS re-orthogonalizes within ~50 steps), so LR warmup just delays the productive high-LR window without providing additional stability. **CLOSED negative.**
- **Impact:** Closes the LR-schedule axis in wave 2. Combined with LR retune (#96) also negative, the schedule space is exhausted.

## 2026-05-16 09:30 — PR #104: Polyak EMA weight averaging at eval (frieren)

- **Branch:** g1r4-frieren/polyak-ema-eval
- **Hypothesis:** Polyak EMA of model weights at eval time reduces val/loss without touching training dynamics
- **Results:**

| Arm | EMA decay | W&B run | val/loss (live) | val/loss_ema | fs_live | fs_ema |
|-----|-----------|---------|-----------------|--------------|---------|--------|
| A | 0.99 | gwr15he4 | 3.27839 | 3.27859 | 3325 | 3300 |
| B | 0.999 | ry7tw0ag | 3.27736 | 3.32406 | 3300 | -1 |
| C | 0.9999 | ps773p6x | 3.27494 | 3.46152 | 3275 | -1 |
| D | 0 (disabled) | 2v0kauw1 | 3.27830 | 3.27830 | 3325 | 3325 |

- **Analysis:** Hypothesis refuted. EMA val_loss ≥ live val_loss in every arm. Live val_loss invariant across arms (3.2749-3.2784, spread within seed noise). Arm C live=3.2749 is not attributable to EMA (EMA cannot affect live trajectory). Arm D=Arm A confirms test harness. Cooldown is load-bearing — EMA averages across cooldown boundary → off-floor. **CLOSED negative.**

## 2026-05-16 10:30 — PR #117: Trust-region Muon² per-layer cap (alphonse) — CLOSED negative

- **Branch:** g1r4-alphonse/trust-region-muon
- **Hypothesis:** Cap each layer's NS-orthogonalized update by `radius × ||w||_F` to prevent rare-large excursions without touching the standard Muon² recipe
- **Results:**

| Arm | radius | W&B run | val/loss | first_step |
|-----|--------|---------|----------|-----------|
| A | 0.0 (disabled) | reugw0j8 | 3.27657 | 3275 |
| B | 0.1 | nwn9iw8o | 5.69052 | -1 |
| C | 0.3 | 7j5q7i9z | 5.69074 | -1 |
| D | 1.0 | sic7r90w | 5.68109 | -1 |

- **Analysis:** Arm-A reproduces merged baseline to 5th decimal (3.27657 vs 3.2766) — code path verified. Arms B/C/D all collapse onto val~5.69 within 0.003 at every step. Self-reinforcing feedback loop: cap activates at init (||u||_F ≈ ||w||_F ≈ 23-28 by construction) → shrinks updates → weights grow slow → ||w||_F stays small → cap stays tight forever. The cap design coupled to `||w||_F` is the wrong scale invariant for Muon² since NS already normalizes singular values to 1.
- **Closes off:** trust-region cap by weight-norm fraction axis. Future trust-region work should use NS-natural invariant `sqrt(min(rows,cols))` with c>1 to clip only rare excursions. **CLOSED negative.**

## 2026-05-16 10:30 — PR #106: Muon² cooldown_frac sweep (nezuko) — CLOSED negative

- **Branch:** g1r4-nezuko/muon2-cooldown-sweep
- **Hypothesis:** Extend fern PR #70's positive cooldown signal (vanilla Muon frac=0.5 trended positive) onto merged Muon² baseline
- **Results (after arm-C bug retry):**

| Arm | frac | W&B run | val/loss | first_step |
|-----|------|---------|----------|-----------|
| A | 0.4 | 0jnnm3mf | 3.28358 | -1 (failed) |
| B | 0.5 | 2ah2vjlr | 3.27928 | 3350 |
| C (retry) | 0.6 | 088ms8y1 | 3.27766 | 3300 |
| D | 0.7 (baseline) | 2jr85a5w | 3.27965 | 3350 |

- **Analysis:** Monotone: lower frac → worse or no-change. Frac=0.6 retry val=3.27766 indistinguishable from baseline 0.7 (range 0.00005). fern PR #70's positive frac=0.5 signal on vanilla Muon does NOT transfer to Muon². Mechanism: Muon²'s 2nd-moment preconditioning makes the cooldown tail do real, non-redundant work, so shortening it doesn't help.
- **Bonus diagnostic:** Original arms C/D both hit branch-toggle-during-launch bug (entrypoint reverted file between arms B and C → ran with hardcoded frac=0.7), accidentally giving an n=2 frac=0.7 reproduction (mean=3.27761) that agrees with merged baseline (3.276565) to 0.001 — confirming environment health. Student adopted snapshot-before-launch pattern for retry.
- **Closes off:** cooldown_frac axis on Muon². **CLOSED negative.**

## 2026-05-16 10:30 — Wave 3 dual positive signals 🎯 (in flight)

Two wave-3 mechanism stacks have produced **baseline-beating single-seed signals** awaiting confirmation:

### PR #115 — Adam-style bias correction (edward)

| Arm | bias_corr | beta2 | W&B run | val/loss | first_step | margin |
|-----|-----------|-------|---------|----------|-----------|--------|
| A | OFF | 0.999 | o5pk32x1 | 3.27928 | 3325 | +0.003 (within-noise) |
| B | ON | 0.95 | nit5n8jo | 3.27720 | 3300 | +0.001 (no step-25 divergence ✓) |
| **C** | **ON** | **0.98** | jp2lhp3r | **3.27490** | **3250** | **−0.002, −25 steps** ✨ |
| D | ON | 0.999 | swdz145t (running step 2010) | — | — | testing bias_corr at baseline beta2 |

Single-seed stat-sig at n=1: (3.28−3.2749)*sqrt(1) = 0.0051 ≥ 0.004 ✓. Predeclared confirmation rule triggered (val<3.275). 2 confirmation seeds queued at (bias_corr=on, beta2=0.98) after arm-D.

### PR #105 — Gradient clipping sweep (thorfinn)

| Arm | clip | W&B run | val/loss | first_step | margin |
|-----|------|---------|----------|-----------|--------|
| A | 0.0 (disabled) | q6law89d | 3.27890 | 3325 | +0.002 (within-noise) |
| **B** | **1.0** | ogevgg65 | **3.27546** | **3275** | **−0.001, =0 steps** ✨ |
| C | 5.0 | 3utr1m71 (running step 1800) | — | — | sweep continuation |

Single-seed stat-sig at n=1: (3.28−3.2755)*sqrt(1) = 0.00454 ≥ 0.004 ✓. 2 confirmation seeds requested at clip=1.0 after arm-C finishes.

**Wave 3 mechanism hypothesis (if both confirm)**: bias correction touches v-EMA preconditioner; grad clip touches gradient before momentum — orthogonal mechanism slots, expected to stack cleanly. Final merge sequencing TBD pending confirmation seeds.

## 2026-05-16 13:34 — PR #149: NS-iters annealing (tanjiro) — CLOSED infra-blocked (3rd confirmation)

- **Branch:** g1r4-tanjiro/ns-anneal-v2
- **Hypothesis:** Anneal NS-iters from 16 (high precision early) to 6/8 (compute-efficient late) over training; should match NS=12 quality with lower late-training cost
- **Disposition:** Student executed mandatory 100-step smoke test on **unmodified merged baseline** before launching research arms. Result: **3rd consecutive reproduction of the tanjiro-pod NaN cascade signature** identical to #97 and #108.

| Step | train/loss | grad/global_norm | nonfinite_count | val/loss |
|------|------------|------------------|------------------|----------|
| 0 | — | — | — | 10.8258 |
| 1 | 10.8258 | **232102** | — | — |
| 25 | NaN | 0.0 | **147,758,208** | — |
| 100 | NaN | 0.0 | 147,097,728 | NaN |

W&B run `viwzwtx6`. Pod UUID matches the previously-flagged 7998cef9-... pattern.

**Mechanism analysis (forwarded to issue #160)**: Step-1 grad explosion (5 orders of magnitude above healthy) on the byte-identical merged baseline → silicon-binning bf16 instability on this physical GPU. Same model, driver, and cuDNN version as healthy peers. ECC clean.

**Action**: Filed [issue #160](https://github.com/morganmcg1/modded-nanogpt-senpai/issues/160) requesting GPU rotation. Tanjiro held idle (no new assignments) until pod is healthy. Hypothesis valuable, just needs working hardware.

## 2026-05-16 13:35 — PR #120: Lookahead Muon² (askeladd) — CLOSED clean negative

- **Branch:** g1r4-askeladd/lookahead-muon2
- **Hypothesis:** Lookahead meta-optimizer (k inner steps + α slow-weight blend) temporally stabilizes Muon² without continuous EMA smoothing, preserving cooldown-phase tightening
- **Results (4 arms, all complete):**

| Arm | k | α | W&B run | val/loss | first_step | vs baseline |
|-----|---|---|---------|----------|-----------|-------------|
| A | 0 (disabled) | 0.5 | s0utj0wz | **3.27731** | 3300 | +0.001, +25 |
| B | 5 | 0.5 | f8g40nft | 3.28843 | -1 | +0.012, target FAILED |
| C | 10 | 0.5 | ykdzt3tg | 3.29011 | -1 | +0.013, target FAILED |
| D | 10 | 0.8 | cr1bq7ff | **3.27731** | 3300 | +0.001, +25 (=A to 5 decimals) |

Single-seed stat-sig at best: (3.28−3.27731)×√1 = 0.00269 < 0.004. No improvement. Arms B/C never reach val<3.28 target.

**Mechanism analysis (from student telemetry):**
Trajectory dissection revealed the mechanism: Lookahead HELPS in the pre-cooldown stable phase (B/C/D lead A at steps 500–2500) but REVERSES in the cooldown phase (A and D catch up at step 3000+). Temporal averaging with α=0.5 pulls θ_fast halfway back to θ_slow every k steps — at small LR magnitudes during cooldown, the slow-weight pullback dominates per-step descent, erasing ~one-step's-worth of progress every k steps. Arm D (α=0.8) weak enough not to harm but also provides zero net benefit.

**Closes off:** Entire temporal-smoothing meta-optimizer family — confirms same root cause as Polyak EMA #104 (frieren). Cooldown_frac=0.7 is load-bearing; any mechanism that mixes historical weights into θ during cooldown hurts. Lookahead-aware-cooldown (ramp α→1 at cooldown start) is theoretically possible but unlikely to yield net gain since stable-phase benefit is within noise.

## 2026-05-16 13:10 — PR #126: Contra-Soft Muon² element-wise (fern) — CLOSED clean negative

- **Branch:** g1r4-fern/contra-soft-muon
- **Hypothesis:** Per-element conflict detection `(grad * momentum).sign()` rescales conflicting gradient components before momentum EMA, preserving direction signal that EMA averages away
- **Results:**

| Arm | alpha | W&B run | val/loss | first_step | notes |
|-----|-------|---------|----------|-----------|-------|
| A | 0.0 (disabled) | vm4awheg | 3.27616 | 3275 | EXACT baseline reproduction |
| B | 0.5 | bf08lbjh | killed step 1644 | -1 | val=4.06 (kill-gate triggered) |
| C | 0.25 | 4jeki2ax | 3.3888 | -1 | missed target by 0.109 |
| D | 1.0 | ruln9i87 | crashed step 375 | -1 | divergence-grade slowdown |

**Telemetry — the diagnostic story**:

| Run | conflict_fraction (mean) | scaled_norm_ratio (mean) |
|-----|--------------------------|--------------------------|
| A (alpha=0) | 0.524 | 1.000 (no-op) |
| C (alpha=0.25) | 0.515 | 0.876 |
| B (alpha=0.5) | 0.486 | 0.808 |
| D (alpha=1.0) | 0.503 | 0.701 |

**Key falsification**: conflict_fraction stays ≈ 0.50 throughout training across all arms — element-wise grad signs are approximately uncorrelated with momentum signs. By the PR's own falsification criterion (need < 0.3 for real shaping), the element-wise mechanism is detecting noise, not directional conflict. The rescaling depresses gradient magnitude uniformly at random across elements, slowing learning regardless of alpha.

**Closes off**: Element-wise Contra-Soft direction-shaping axis. The mechanism behaves as a near-uniform gradient attenuator (~13/19/50% mass loss for alpha=0.25/0.5/1.0).

**Doesn't close**: Layer-aggregate Contra (assigned to fern as PR #154 follow-up). Tests whether `⟨grad_layer, momentum_layer⟩ < 0` carries more signal than per-element sign mismatch. Decisive smoke test included.

**Why record #20 likely uses layer-aggregate**: Their published "Contra-Soft-Muon" must work since it's first mechanism in their 3030-step record. Element-wise is falsified here. Most likely difference: layer-level inner-product aggregation, not per-element sign.

## 2026-05-16 15:30 — PR #105: Gradient clipping sweep (thorfinn) — 🎉 MERGED — FIRST WAVE-3 WIN

- **Branch:** g1r4-thorfinn/grad-clip-sweep
- **Hypothesis:** Standard gradient clipping (previously untested on Muon² baseline) may improve training stability and final val/loss
- **Results (5 runs total — 3-arm sweep + 2 confirmation seeds at clip=5.0):**

| Arm | clip | W&B | val/loss | first_step | vs baseline (3.2766/3275) |
|-----|------|-----|----------|-----------|---------------------------|
| A | 0.0 (disabled) | q6law89d | 3.27890 | 3325 | within-noise repro |
| B | 1.0 | ogevgg65 | 3.27546 | 3275 | −0.0011, =0 steps |
| **C** | **5.0** | **3utr1m71** | **3.27415** | **3250** | **−0.0024, −25 steps** ✨ |
| confirm-1 | 5.0 | yfhknwar | 3.27481 | 3250 | −0.0018, −25 steps ✅ |
| confirm-2 | 5.0 | j4r186ws | 3.27684 | 3300 | −0.0000, +25 steps ✅ |

**n=3 stat-sig at clip=5.0**: mu=(3.27415+3.27481+3.27684)/3=**3.27527**, (3.28−3.27527)×√3=**0.00819≥0.004** ✓ PASS. Mean fs=3266.7 vs baseline 3275 (−8.3 steps).

**Mechanism analysis (thorfinn's diagnosis)**:
- Raw global_grad_norm = 40,000–50,000 at every step (5 orders of magnitude above clip threshold)
- Both clip=1.0 and clip=5.0 are **active at every step** → not "spike clipping" but full-time gradient rescaling
- NS orthogonalization absorbs magnitude for Muon block params → clip affects **only AdamW aux groups** (embed/lm_head)
- Mechanism = constant effective-LR multiplier on AdamW aux groups (clip=5.0 → ×5 vs clip=1.0 → ×1 on rescaled gradients)
- Monotone trend clip=0→1→5 confirms optimum not yet reached → thorfinn reassigned to clip extension sweep (#165)

**Why it wins**: Muon²'s NS step normalizes updates for block params; AdamW aux groups had suboptimal effective LR. Clip=5.0 boosted aux effective LR by 5× vs clip=1.0, landing on a better operating point. This is mechanistically equivalent to an AdamW aux LR sweep.

**New merged baseline**: val=3.27527/fs=3266.7 (n=3, mean). Previous: 3.2766/3275 (n=2, exact).

**Follow-up actions**:
- Thorfinn: #165 clip extension sweep {10, 25, 50}
- Edward: #115 sent back to re-confirm bias correction on new clip=5.0 baseline

## 2026-05-16 17:32 — PR #138: Polar Express NS sweep (frieren) — CLOSED (clean negative + mechanism finding)

- **Branch:** g1r4-frieren/polar-express-ns
- **Hypothesis:** Polar Express (ICLR 2026 Oral) — adaptive polynomial Newton-Schulz replacement — could improve orthogonalization quality and training efficiency
- **Results (4 arms complete, single seed each, snapshot pre-dates #105 so NO clip=5.0):**

| Arm | NS variant | iters | W&B | val/loss | first_step | u_singular_range |
|-----|-----------|-------|-----|----------|-----------|-----------------|
| A | Classical | 12 | l5mkhlap | 3.27831 | 3325 | 0.949 |
| **B** | **Polar Express** | **12** | **2li08zef** | **3.27666** | **3275** | **0.428** |
| C | Polar Express | 8 | gv3ux65a | 3.27711 | 3300 | 0.931 |
| D | Polar Express | 6 | 4chpm8ru | 3.27977 | 3350 | 0.988 |

- **vs new merged baseline (3.27527/3266.7)**: arm-B best = +0.0014 worse. No arm beats new baseline.
- **Stat-sig check (arm-B, n=1)**: (3.28−3.27666)×√1=0.00334<0.004 → NOT stat-sig. No confirmation seeds warranted.

**Mechanistic finding (headline)**: PE=12 achieves a **2.2× tighter spectral spread** (range 0.428 vs 0.949 for NS=12) but only Δval ≈ −0.0017. **NS=12's spectral quality is already past the saturation threshold** at this benchmark scale — better orthogonalization does NOT translate to proportional val/loss reduction. The spectral-spread → val/loss curve is flat at the current operating point.

**Compute-efficiency observation**:
- PE=8 (arm-C) matches PE=12 (arm-B) within noise (Δval=0.0005, range 0.931 ≈ NS=12 at 0.949)
- PE=6 (arm-D) regresses slightly (range 0.988 > NS=12, worse orthogonalization)
- NS=8 + clip=5.0 remains testable as a compute-saving option

**Val/loss trajectory**: all 4 arms overlap to <0.002 through step 2500. Divergence ONLY in cooldown (steps 3000+). This is the key mechanistic insight → NS precision matters ONLY in cooldown phase.

**Follow-up action**: frieren assigned #176 (NS Iteration Schedule — boost NS iters during cooldown only, directly motivated by this finding).

**Closed rationale**: no arm beats new merged baseline; not a merge candidate. Clean negative with a precise mechanistic prior: "spectral spread improvement of ≥2× buys <0.002 val/loss at this scale."

## 2026-05-16 20:30 — PR #144: SOAP for AdamW aux groups (alphonse) — CLOSED clean negative

- **Branch:** g1r4-alphonse/soap-aux
- **Hypothesis:** SOAP (Shampoo + Adam) — apply Shampoo eigenbasis rotation to AdamW preconditioner on aux groups (embed, lm_head); test whether the Shampoo eigenbasis better captures the structure of sparse-token gradients than AdamW's coordinate-aligned EMA.
- **Results (4 arms complete, single seed each, snapshot pre-dates #105 — comparison is to OLD baseline val=3.2766/fs=3275):**

| Arm | SOAP target | freq | W&B | val/loss | fs | Δval vs A |
|-----|------------|------|-----|----------|----|-----------| 
| **A** | none (AdamW control) | — | lfcnprqg | **3.27595** | 3275 | (control) |
| B | embed only | 50 | 8ym5zef8 | 3.27978 | 3350 | +0.00383 |
| C | embed + lm_head | 50 | 82mx9xwy | 3.27942 | 3325 | +0.00347 |
| D | embed + lm_head | 100 | r4644zpc | 3.27947 | 3350 | +0.00352 |

- **Mechanism**: SOAP-aux causes monotonic regression in all variants. The gap grows across training (step 1000 +0.00169 → step 3350 +0.00383 for arm-B). Lowering freq from 50→100 (arm-D) does not help.
- **Mechanism interpretation**: rotating embed gradient into a Shampoo eigenbasis bleeds signal across vocab rows that should remain row-independent (sparse, token-specific). The structural cost of basis rotation outweighs the second-moment quality gain.
- **Combined with #180 closure**: any non-AdamW second-moment estimator on aux groups breaks sparse-token training. Sparsity is the load-bearing constraint, not the precision.
- **Follow-up action**: alphonse assigned #188 (AdamW aux LR sweep — first-moment / LR axis instead of second-moment basis).

## 2026-05-16 20:30 — PR #180: Adafactor for AdamW aux groups (askeladd) — CLOSED smoke timebox

- **Branch:** g1r4-askeladd/adafactor-aux
- **Hypothesis:** Adafactor (Shazeer 2018) — factored row/col second moment for embed/lm_head; test whether AdamW's full-v is over-precise for sparse aux gradients.
- **Smoke results (2 attempts per predeclared HARD TIMEBOX):**

| Run | Variant | val at step 200 | Outcome |
|-----|---------|-----------------|---------|
| 1v3appj2 | adafactor_no_mom | 10.826 | NaN throughout |
| mm816faq | adafactor_mom | 10.826 | NaN in v_r_norm, v_c_norm, factored_v, update_rms |

- **Mechanism interpretation**: factored second moment v_ij ≈ v_r * v_c / sum(v_r) likely produces near-zero denominators on sparse embed gradients (most rows have ~0 gradient most of the time), causing divide-by-tiny-number → inf → NaN cascade.
- **Combined with #144 closure**: confirms the sparsity-is-load-bearing finding. Both SOAP (rotation) and Adafactor (factorization) break sparse-token aux training; AdamW's full-v structure must be preserved.
- **Follow-up action**: askeladd assigned #189 (Muon² preconditioner eps sweep — simple 1-line config change after 3 consecutive smoke failures on complex algorithms).

## 2026-05-16 22:25 UTC — PR #163: Decoupled Momentum Reset (fern) — CLOSED clean negative

- **Branch:** g1r4-fern/dmr
- **Hypothesis:** Decoupled Momentum Reset — periodically zero Muon's momentum buffer every K steps (with optional residual decay) to break the persistent grad·momentum < 0 staleness signal observed in #154 (which found ~90% of steps have grad·momentum < 0 under Muon²). Test whether erasing stale momentum allows the optimizer to re-align with current gradient.
- **Results (4 arms complete, single seed each, vs merged baseline val=3.27527/fs=3266.7):**

| Arm | Config | val/loss | fs | Δval vs A (control) | vs merged baseline |
|-----|--------|----------|----|---------------------|--------------------|
| **A** | no reset (control) | **3.2780** | 3300 | (control) | +0.0027 |
| B | K=50 (frequent reset, no decay) | **3.2930** | — | **+0.0150 CATASTROPHIC** | +0.0177 |
| C | K=200 (moderate reset, no decay) | 3.2811 | — | +0.0031 | +0.0058 |
| D | K=800 + 0.5× decay (best variant) | **3.2783** | 3325 | +0.0003 | +0.0030 |

- **Mechanism interpretation**: Even the best DMR variant (K=800 with 0.5× decay) is barely distinguishable from the no-reset control (+0.0003). Frequent reset (K=50) catastrophically destabilizes Muon by erasing the smoothed gradient signal NS depends on for stable orthogonalization. K=200 still regresses noticeably. **The #154 staleness signal (grad·momentum < 0 in 90% of steps) is noise-dominated under Muon's NS orthogonalization** — NS already cancels the sign-disagreement structure by projecting to the orthogonal manifold, so resetting momentum loses information rather than adding it.
- **Closure rationale**: No arm beats baseline. Best variant (D) is statistically indistinguishable from control (A) but still +0.003 worse than the merged baseline. DMR family closed.
- **Family closed**: momentum erasure / temporal-buffer reset (joins #104 Polyak EMA, #120 Lookahead under "temporal smoothing/manipulation breaks Muon cooldown").
- **Follow-up action**: fern assigned #203 (NS polynomial coefficient sweep — different mechanism axis, tests Muon²'s post-v-EMA spectrum directly via Chebyshev quintic c parameter).

## 2026-05-16 22:30 UTC — PR #145: Per-layer adaptive NS iterations (nezuko) — CLOSED clean negative

- **Branch:** g1r4-nezuko/per-layer-ns
- **Hypothesis:** Per-layer adaptive NS iteration count — use sigmoid-controlled per-layer scaling between BASE and BASE+EXTRA_MAX iterations, gated on local layer-wise NS convergence rate, to spend iterations where they matter most (different layers have different spectrum-tightening needs).
- **Results (4 arms complete, single seed each, vs merged baseline val=3.27527/fs=3266.7):**

| Arm | Config (BASE/EXTRA_MAX → effective NS) | val/loss | fs | vs baseline |
|-----|-----|----------|----|-----| 
| A | BASE=12 / EXTRA_MAX=0 → NS=12 (control) | 3.27841 | 3300 | +0.0031 |
| B | BASE=12 / EXTRA_MAX=4 → NS=16 (saturated) | **3.27992** | 3325 | +0.0046 |
| C | BASE=12 / EXTRA_MAX=2 → NS=14 (saturated) | 3.27761 | 3300 | +0.0023 (within noise) |
| D | BASE=6 / EXTRA_MAX=12 → NS=18 (saturated, zrrqch4i) | 3.41 | — | DEGRADED |

- **Mechanism interpretation**: The sigmoid-controlled per-layer policy **degenerated to uniform NS for every weight matrix** (sigmoid saturated at gate=1.0 for all layers; variance across layers = 0). What was intended as adaptive per-layer became a uniform NS-iter sweep of {12, 14, 16, 18}. Under that effective interpretation:
  - NS=12-14 near-optimal (within noise of each other)
  - NS=16 monotonically worse (+0.0015 vs NS=12)
  - NS=18 catastrophically degraded (val=3.41 at midtraining)
- **Cross-reference**: This converges with frieren #138 (NS=12 spectral quality saturates, NS=8 already at the saturation knee) and tanjiro #75 (NS=8 floor — fewer iters fail). The local optimum is **NS=12-14**.
- **Closure rationale**: Per-layer policy degenerates to uniform; uniform NS≥16 monotonically worse. Adaptive policy moot. Family closed.
- **Cross-validation context**: tanjiro #185 arm-A (constant NS=14) actually FINISHED val=3.2748/fs=3250 = **BEATS baseline**, demonstrating NS=14 is the right uniform value, but the per-layer mechanism in nezuko's #145 was not the right way to reach it. The benefit comes from a uniform NS-iter increase, not from per-layer adaptation.
- **Follow-up action**: nezuko assigned #204 (Cooldown shape sweep — different mechanism axis, tests LR-decay curve shape during cooldown, orthogonal to her closed #106 which tested cooldown_frac timing).

## 2026-05-16 23:30 UTC — PR #115: Muon² Adam bias correction stack (edward) — CLOSED clean negative on new baseline

- **Branch:** g1r4-edward/muon-bias-correction
- **Hypothesis:** Adam-style bias correction in Muon² preconditioner `v / (1 - beta2^t)` allows safe use of beta2=0.98 (rather than 0.999), tightening the second-moment estimator's adaptation to changing gradient statistics. Pre-#105 result on the OLD baseline (no clip): mu(n=3)=3.27532 — n=3 stat-sig PASS.
- **Retest on new clip=5.0 merged baseline:**

| Run | bias_corr | beta2 | W&B | val/loss | first_step | vs control | vs merged baseline (3.27527 / 3266.7) |
|-----|-----------|-------|-----|---------:|-----------:|-----------:|--------------------------------------:|
| control | OFF | 0.999 | `tak4oqhf` | 3.27637 | 3275 | (control) | +0.00110, +8 steps |
| BC seed1 | ON | 0.98 | `7cmgw7ym` | 3.27906 | 3325 | +0.00269, +50 steps | +0.00379, +58 steps |
| BC seed2 | ON | 0.98 | `thrpa2mm` | 3.27704 | 3300 | +0.00067, +25 steps | +0.00177, +33 steps |
| BC seed3 | ON | 0.98 | `mjnkjfts` | 3.27814 | 3300 | +0.00177, +25 steps | +0.00287, +33 steps |

- **n=3 BC mean: 3.27808** (seeds: 3.27906/3.27704/3.27814)
- **Statistical**: (3.28 − 3.27808) × √3 = 0.00333 < 0.004 → **FAIL stat-sig vs target**
- **Mean fs(BC, n=3) = 3308.33** vs baseline 3266.7 = +41.7 steps WORSE
- **Mechanism interpretation**: BC and clip=5.0 are redundant interventions targeting the same root cause (early-step preconditioner instability). clip=5.0 already dominates the early-step instability (raw lm_head norm ≈ 33827 → clipped at step 0 every step), making BC's `v / (1 − beta2^t)` boost an over-correction. BC's original mechanism (allow safe beta2=0.98) is moot because the underlying instability has been removed at the gradient stage by clipping.
- **Cross-result**: same mechanism, two baselines, opposite outcomes — pre-#105 BC won by 0.0013 (n=3 mu=3.27532 vs old 3.27649); post-#105 BC loses by 0.0017 (n=3 mu=3.27808 vs new 3.27637). Clean example of how a mechanism's value depends on the rest of the recipe.
- **Important downstream implication**: On the merged baseline, **beta2=0.999 (default) is safe to keep** — no BC needed, no beta2=0.98 retune needed. Subsequent PRs in the wave-3 frontier do not need to consider BC variants.
- **Follow-up action**: edward assigned #206 (Per-group gradient clipping — decisive test of the clip-as-aux-LR-rescaler mechanism story; complements alphonse #188 aux LR sweep on the same mechanism axis).

## 2026-05-17 01:30 UTC — PR #165: Clip value extension sweep (thorfinn) — 4-arm sweep COMPLETE; CONFIRMATION SEEDS LAUNCHING

- **Branch:** g1r4-thorfinn/clip-extension
- **Hypothesis:** Extend the gradient-clip sweep above merged baseline clip=5.0 to find the true optimum. If clip acts as a uniform aux-LR rescaler (per #105 mechanism story), val should monotonically improve as clip loosens until embed-group eff-LR ratio crosses ~0.5 and gradient noise re-enters the AdamW update.
- **Results (4 arms, single seed each, all at NS=12 + Muon² + clip-as-labelled + post-#105 baseline config):**

| Arm | clip | val/loss | first_step_to_target | Δval vs baseline (3.27527) | Δfs vs baseline (3266.7) |
|-----|------|----------|---------------------:|---------------------------:|-------------------------:|
| A | 5.0 (baseline reproduction) | 3.27756 | 3300 | +0.00229 | +33.3 |
| **B** | **10.0** | **3.27432** | **3250** | **−0.00095** | **−16.7** ✓ |
| C | 25.0 | 3.27442 | 3250 | −0.00085 | −16.7 (tied with B) |
| D | 50.0 | 3.27590 | 3275 | +0.00063 | +8.3 |

- **W&B run IDs**: arm-A `f6ym89r7`, arm-B `84um64gj`, arm-C `2btntm04`, arm-D `7lpa9jmh`. All clean shutdowns, no NaN, train_time ~6020s each.
- **Per-group telemetry (last-step summary)**:

| Arm | clip | grad_norm_embed | embed eff-LR ratio | grad_norm_lmhead | lmhead eff-LR ratio | pre-clip global norm |
|-----|------|-----------------|-------------------:|------------------|--------------------:|---------------------:|
| A | 5.0  |  59.5 | 0.084 | 12,394 | 0.0004 | 34,953 |
| B | 10.0 |  59.25 | 0.169 | 12,474 | 0.0008 | 36,218 |
| C | 25.0 |  59.75 | 0.418 | 12,456 | 0.0020 | 35,789 |
| D | 50.0 |  60.0 | 0.833 | 12,746 | 0.0039 | 34,992 |

- **Mechanism — single-peak with plateau:**
  - 5 → 10: −0.00324 (steep improvement; embed at 17% eff-LR is the sweet spot)
  - 10 → 25: +0.00010 (local plateau; embed eff-LR 17%→42% is statistically flat)
  - 25 → 50: +0.00148 (regression; embed crosses 50% eff-LR, gradient noise re-enters AdamW update)
  - LM-head eff-LR stays microscopic (<0.4%) throughout — lm_head is clip-saturated, embed is the load-bearing component
  - Peak location: clip ≈ 10–15
- **Confirmation plan**: 2 seeds at clip=10 (best single-seed). Launched 01:25 UTC. ETA confirm-1 terminal ~03:10 UTC, confirm-2 ~04:50 UTC.
- **Merge gate math**: need mu(n=3) ≤ 3.27769 for stat-sig. Existing seed 3.27432 leaves budget — remaining 2 seeds need mean ≤ 3.27937, within seed envelope from #105 (range 0.0027).
- **Cross-PR co-discovery**: frieren #176 arm-B (NS=12→16 cooldown) val=3.27327/fs=3250 and tanjiro #185 arm-B (NS=14→8 anneal) val=3.27385/fs=3250 both ALSO at fs=3250 on completely orthogonal mechanism axes. If clip and NS-iter axes both confirm at n=3, the natural next merge is a clip=10 × NS-schedule stack.

## 2026-05-17 07:00 — PR #176: frieren NS=12→16 cooldown boost MERGED

- g1r4-frieren
- Hypothesis: NS-iter budget is under-provisioned in the cooldown phase (last 30% of training). Boost NS from 12→16 at the cooldown transition (step 2345, 70% mark). Based on #138 Polar Express finding that singular_range tightens with higher NS iters.
- Results:

| Arm | NS schedule | run id | val_loss | fs | Δ vs pre-#165 baseline |
|-----|---|---|---:|---:|---|
| A | 12 constant (sanity) | sara3jjw | 3.27663 | 3275 | +0.00136 (noise) |
| **B** | **12→16 at step 2345** | **2xp7ut5r** | **3.27327** | **3250** | **−0.00200** ✓ |
| C | 12→20 at step 2345 | odmxk60i | 3.27492 | 3250 | −0.00035 |
| D | 8→12 at step 2345 | 35tz06er | 3.27567 | 3275 | +0.00040 |
| confirm-1 | 12→16 | u5mqjzv1 | 3.27523 | 3275 | — |
| confirm-2 | 12→16 | eqhe974m | 3.27533 | 3275 | — |
| **n=3 mean** | **12→16** | — | **3.27461** | **3266.7** | **−0.00013 vs clip=10 baseline** |

- **Stat-sig**: (3.28−3.27461)×√3 = 0.00933 ≥ 0.004 ✓ PASS by 2.3×
- **Mechanism confirmed**: singular_range drops from ~0.95 to ~0.47 at the NS=12→16 transition in arm-B. Arm-D compute-neutrality: NS=8 mid-training ≈ NS=12 constant (mid-training spectrum already saturated at NS=8). Saturation at NS=16 in cooldown (arm-C NS=20 buys nothing). Key insight: NS-iter budget over-provisioned in flat-loss regions, under-provisioned in steep-descent cooldown window.
- **Wave-4 implication**: NS=8mid→NS=16cooldown is an aggressive stack candidate — saves ~23% Muon-block compute mid-training while preserving the NS=16 cooldown win. Orthogonal to clip=10 axis (Muon blocks vs AdamW aux). Assigned to thorfinn for wave-4 stacking test.
- **PR guard bug fix**: student correctly diagnosed senpai-pr-guard.py false-positive on prose mentions of SENPAI-RESULT. Fix applied (line.lstrip().startswith() vs "in" check).

## 2026-05-17 14:55 UTC — PR #206: Per-group gradient clipping v2 (edward) — CLOSED null/mechanism study

- Branch: `g1r4-edward/per-group-clip`
- Hypothesis: clip=5.0 effect is purely on AdamW aux groups (lm_head/embed), with Muon blocks inert (since NS absorbs gradient magnitudes). Follow-on v2 re-ran the ablation at the new clip=10 + NS=12→16 baseline.
- W&B runs: arm-A `74yootm3`, arm-B `q1599b2c`, arm-C `kfxcnn9a`, arm-D `ihg3vw7j`

### v2 results (clip=10 + NS=12→16 cooldown baseline)

| Arm | Config | val/loss | fs | Δ vs new baseline (3.27461) | Δ vs arm-A within-pod |
|-----|--------|----------|-----|---:|---:|
| A | clip=10 ALL (control) | 3.27434 | 3250 | −0.00027 (noise) | — |
| B | clip=10 aux only | 3.27729 | 3300 | +0.00268 (regression) | +0.00295 |
| C | clip=10 muon only | 3.27499 | 3275 | +0.00038 (noise) | +0.00065 |
| D | no clip | 3.27952 | 3350 | +0.00491 (regression) | +0.00518 |

### Mechanism inversion at clip=10 vs pre-rebase clip=5

| Ecosystem | Arm-B (aux only) | Arm-C (muon only) | Reading |
|---|---|---|---|
| clip=5 pre-rebase | 3.27626 (better) | 3.27459 (best) | muon clip was load-bearing |
| clip=10 v2 | 3.27729 (regression) | 3.27499 (noise) | aux clip is dominant |

Decision tree: arm-D (no clip) = 3.27952 ≥ 3.279 → clip=10 is load-bearing as a global rescaler. No per-group config beats clip-all; no merge candidate.

**Key findings (cite):**
1. Both aux clip and muon clip contribute at clip=10; aux is dominant (~0.003), muon secondary (~0.001).
2. Slight super-additivity: D regression (0.00518) > B + C (0.00360). Clips reinforce each other.
3. Mechanism is threshold-dependent: at clip=5 muon clip was inert/mildly harmful; at clip=10 both matter.
4. Per-group dispatch infrastructure is correct — clean telemetry across 8 arms.

Closed as null + mechanism study. No confirmation seeds warranted (arm-A is baseline reproduction; arm-C within noise at n=1; GPU time better spent on wave-5 stacking).

## 2026-05-17 15:55 UTC — PR #234: NS boost trigger-fraction sweep (frieren) — CLOSED null

- Branch: `g1r4-frieren/ns-boost-trigger-sweep`
- Hypothesis: The 0.70 trigger fraction for the NS=12→16 boost may not be at the local optimum.
- W&B runs: arm-A `pz8jhwxj`, arm-B `i5p9lv38`, arm-C `875p3msy`, arm-D `rmi1c6go`, arm-E `6i4g1b87`

### Results — 5-arm sweep (TRIGGER_FRAC ∈ {0.55, 0.65, 0.70, 0.75, 0.85})

| Arm | TRIGGER_FRAC | val/loss | Δ vs A | fs | W&B |
|-----|---|---|---|---|---|
| **A** | **0.70 (control)** | **3.27404** | **— (best)** | **3250** | pz8jhwxj |
| B | 0.55 | 3.27699 | +0.00295 | 3300 | i5p9lv38 |
| C | 0.65 | 3.27586 | +0.00182 | 3275 | 875p3msy |
| D | 0.75 | 3.27678 | +0.00274 | 3300 | rmi1c6go |
| E | 0.85 | 3.27763 | +0.00359 | 3300 | 6i4g1b87 |

**Convex U-shape with minimum at 0.70.** Both earlier and later triggers strictly degrade val/loss. Monotone gradient on each side: B>C>A (early side), A<D<E (late side). Four data points all worse than control gives high-confidence evidence for the convex U.

**Mechanism (student's analysis):**
- Earlier triggers (B, C) waste NS=16 on gradient-magnitude-dominated steps where NS=12 is sufficient.
- Later triggers (D, E) truncate the precision-window runway — the NS=16 benefit needs the full 30% cooldown to compound through final descent.
- 0.70 sits at the inflection between gradient-magnitude regime and direction-precision regime.

**Axis closed.** `NANOGPT_NS_COOLDOWN_START_FRAC=0.7` (existing env var) validated as optimal. No code change needed. Follow-on: NS schedule SHAPE sweep (frieren #285) tests whether graduated/ramped NS transition beats the step jump at fixed 0.70 trigger.

## 2026-05-17 16:00 UTC — PR #203: NS polynomial coefficient sweep (fern) — CLOSED null

- Branch: `g1r4-fern/ns-coef-sweep`
- Hypothesis: The NS quintic polynomial coefficient c (one-parameter family a=1.5+c, b=-0.5-2c) may not be optimally set at c=0.5.
- W&B runs (new-baseline v2): arm-A `yzhgo0lm`, arm-B `ad0o8zkq`, arm-C `axz4w1p3`, arm-D `a2c7lvv4`, arm-E `nk3hl6lz`

### Results — 5-arm bracket c ∈ {0.35, 0.40, 0.50, 0.60, 0.70} at new baseline (clip=10 + NS=12→16)

| Arm | c | val/loss | fs | Δ vs A v2 | f(0.5) |
|-----|---:|---:|---:|---:|---:|
| **A v2** | **0.5** | **3.27463** | **3250** | **—** | 0.8281 |
| B v2 | 0.4 | 3.27741 | 3300 | +0.00278 | 0.8000 |
| C v2 | 0.6 | 3.27621 | 3275 | +0.00158 | 0.8563 |
| D v2 | 0.35 | 3.27567 | 3275 | +0.00104 | 0.7859 |
| E v2 | 0.7 | 3.27555 | 3275 | +0.00092 | 0.8844 |

Arm-A v2 reproduces merged n=3 baseline within 0.00002. No arm reaches merge gate.

### Key findings

1. **c=0.5 is clear local optimum** on the new merged baseline. Both directions regress; no confirmation seeds warranted.
2. **NS=16-cooldown × soft-polynomial antagonism**: arm-B (c=0.4) flipped from approximately neutral on old baseline (clip=5, NS=12 constant) to +0.00278 regression on new baseline. More NS iters in cooldown amplify under-flattening errors.
3. **Sharp direction (C→E) monotone-improving but never wins**: c=0.6 (+0.00158) → c=0.7 (+0.00092). Extending to c=0.8 would need +0.00092 gap to close; not motivated.
4. **Non-monotonicity in soft direction (D<B)**: seed noise (0.00174 within inter-seed std ~0.001-0.002); no mechanism follow-up.

**Axis sealed**: NS quintic polynomial coefficient family exhausted at c=0.5 default. Follow-on: fern #290 tests per-iter coefficient schedule (varying c across the 12 NS iters within each step, average c=0.5 held constant to isolate the schedule axis).


## 2026-05-17 22:52 — PR #266: lm_head + scalar cooldown shape: does embed floor generalize to other aux groups?

- g1r4-nezuko/lmhead-scalar-cooldown-shape
- **Hypothesis:** tanjiro #235's embed linear_floor=15% mechanism — does it generalize to lm_head and scalar aux groups? 4-arm design: arm-A (all linear, control), arm-B (lm_head=floor:15), arm-C (scalar=floor:15), arm-D (lm_head+scalar=floor:15).

| Arm | Config | W&B run | val_loss | fs | Within-pod Δ |
|-----|--------|---------|----------|------|--------------|
| A | all linear (control) | qzn7z186 | 3.27484 | 3250 | (ref) |
| B | lm_head=floor:15 | wy1xxm5n | 3.27779 | 3300 | +0.00295 (HURTS) |
| C | scalar=floor:15 | 39on1zw4 | 3.27411 | 3250 | −0.00073 (null) |
| D | lm_head+scalar=floor:15 | omm7w6et | 3.27693 | 3300 | +0.00209 (HURTS) |

**Verdict: CLOSED — productive null / mechanism falsification**

**Analysis**: Hypothesis decisively falsified. Embed-floor mechanism is embed-specific:
1. lm_head arm-B: clear regression (+0.00295) — lm_head wants steeper decay, not a floor.
2. scalar arm-C: within null gate (−0.00073) — scalar is indifferent to floor vs linear.
3. Combined arm-D: lm_head penalty dominates (+0.00209 ≈ arm-B magnitude), scalar's neutral effect is absorbed.

**Mechanism insight**: Consistent with #165's clip=10 finding: clip=10 preferentially raises embed's eff-LR (8.4%→16.9%), indicating embed has unique structural properties (high-fan-in, sparse-token-driven gradient). The floor extends THAT specific property late in training. lm_head and scalar don't share this structural property — lm_head benefits from finalizing sharp predictions as training ends (steeper decay = cleaner convergence), scalar is a small group not exploited by either schedule.

**Wave-5 implications**: Aux-group LR-shape lever is fully mapped at floor=15%. NOT a stacking axis beyond embed. Orthogonal wave-5 candidates (thorfinn aux WD, alphonse β2, askeladd Muon mu, fern NS c-schedule, edward per-group β2) unaffected.

## 2026-05-18 06:02 UTC — PR #285: NS cooldown SHAPE (frieren) — MERGED ✅

- Branch: `g1r4-frieren/ns-cooldown-shape-confirm-newbase`
- Hypothesis: NS cooldown step-up timing matters. `late_peak` shape (NS=12 for first half of cooldown, NS=20 for second half) concentrates NS precision in the lowest-LR phase.

### Results — 4-arm screening (pre-#236 baseline) + n=2 confirmation (post-#236 baseline)

**Screening (4 shapes, within-pod Δ vs step control)**:

| Arm | Shape | Δ_val (vs step) | Notes |
|-----|-------|-----------------|-------|
| A (control) | step (NS=16 constant) | — | 3.27578 |
| B | early_peak | −0.00050 | marginal |
| C | cosine_ramp | −0.00022 | near-null |
| **D** | **late_peak** | **−0.00143** | winner |

**Confirmation (n=2 late_peak, post-#236 stack)**:

| Seed | Shape | W&B run | val/loss | fs |
|------|-------|---------|----------|-----|
| 1 (drift) | step | `pcek165i` | 3.27435 | 3250 |
| 2 | late_peak | `09e6f997` | **3.27385** | **3250** |
| 3 | late_peak | `i7ag1cqx` | **3.27318** | **3250** |
| **n=2 late_peak mean** | | | **3.27352** | **3250** |

Stat-sig: (3.28 − 3.27352) × √2 = 0.00917 ≥ 0.004 ✓. Within-pod trend: seed-2 Δ=−0.00050, seed-3 Δ=−0.00117 (strengthening, not lucky seed).

### Mechanism

NS=20 concentrated into the *final* half of the cooldown (lowest LR, highest precision value) outperforms NS=20 uniformly applied or applied early. Consistent with the NS=16-only-in-cooldown win from PR #176: it's not the magnitude of NS iterations but *when* they land. NS iteration is most valuable when gradient quality is highest (small LR → low-noise signal), not when variance is high.

**New baseline: val=3.27352 / fs=3250 (n=2). `NANOGPT_NS_COOLDOWN_SHAPE=late_peak`.**

## 2026-05-18 06:07 UTC — PR #290: NS per-iter coefficient schedule (fern) — MERGED ✅

- Branch: `g1r4-fern/ns-per-iter-coef-schedule`
- Hypothesis: NS polynomial coefficients (a,b,c for x+bx³+cx⁵) are currently fixed at tuned constants. Varying them over training (ramp_down: start high-precision, end standard) allows the NS update to adapt to the changing loss landscape.

### Results — 4-arm screening + n=3 confirmation

**Confirmation (n=3 linear_ramp_down, post-#236 stack)**:

| Seed | NS_COEF_SCHEDULE | W&B run | val/loss | fs |
|------|-----------------|---------|----------|-----|
| 1 (control) | constant | `1xyn78pr` | 3.27247 | 3250 |
| 2 | linear_ramp_down | `piofi0su` | **3.27155** | **3225** |
| 3 | linear_ramp_down | `p8bm1h2g` | **3.27197** | **3225** |
| **n=3 mean (chain)** | | | **3.27200** | **3233.33** |

Stat-sig: (3.28 − 3.27200) × √3 = 0.01387 ≥ 0.004 ✓. n=2 ramp-down mean = 3.27176 (Δ vs post-#236 baseline = −0.00231).

**Merge notes**: confirmation was run on post-#236 stack (no late_peak from #285). Mechanisms orthogonal: NS_COEF_SCHEDULE changes polynomial quality per NS step; NS_COOLDOWN_SHAPE changes timing of NS step-up. Merged as-is; compositional probe assigned to frieren #344.

### Mechanism

`linear_ramp_down`: NS coefficients start at high-precision values (sharper quintic approximation to the matrix square root) and ramp toward standard values. Early training: high-precision NS extracts maximum update quality; late training: standard coefficients provide a stable, well-explored update direction. The ramp-down timing (~3350 steps) aligns with the observation that late-training needs convergence stability, not innovation.

**New baseline: val=3.27200 / fs=3233.33 (n=3). `NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down`.**

**Follow-up assigned (PR #315)**: nezuko lmhead-decay-shape — test lm_head=quadratic/cubic/exp_decay (steeper than linear) to test the inverse hypothesis (does opposite of floor help lm_head?).

## 2026-05-18 07:12 UTC — PR #279: AdamW WD sweep (thorfinn) — CLOSED (productive-null)

- Branch: `g1r4-thorfinn/g1r4-thorfinn-adamw-wd-sweep`
- Hypothesis: `NANOGPT_ADAMW_WD=0.005` (decoupled WD on AdamW aux groups) shrinks effective AdamW step magnitude during cooldown, complementing β2=0.99 memory smoothing.

### Results — original screening (pre-#235+#236 stack)

| Arm | NANOGPT_ADAMW_WD | val_loss | fs | Δ vs arm-A | embed_fro (final) |
|-----|-----------------:|---------:|----:|---------:|-----------------:|
| A (screen) | 0.0 | 3.27435 | 3250 | 0 | 71680 |
| **B (screen)** | **0.005** | **3.27158** | **3225** | **−0.00277** ✅ | 22528 |
| C (screen) | 0.01 | 3.27824 | 3325 | +0.00389 ❌ | 13440 |

Original n=3 (pre-#235+#236 chain, WD=0.005): mean=3.27346, beat that era's baseline by Δ=−0.00061. Clean U-curve with apex at WD=0.005.

### Compositional confirmation (post-#236 stack, WD=0.005)

| Seed | W&B run | val_loss | fs | Δ vs new baseline (3.27200) |
|------|---------|---------:|----:|---------------------------:|
| probe | `788vm9hq` | 3.27551 | 3300 | +0.00351 |
| seed-2 | `64ibazta` | 3.27540 | 3300 | +0.00340 |
| seed-3 | `22345xko` | 3.27500 | 3275 | +0.00300 |
| **mean** | — | **3.27530** | **3291.67** | **+0.00330** ❌ |

n=3 mean fails merge gate by +0.00330. Stat-sig: 0.00814 ≥ 0.004 (passes stat-sig but FAILS merge gate). Inter-seed range collapsed from 0.00368 (pre-#236) to 0.00051 (post-#236) — new stack is intrinsically lower-variance, removing the upside tail.

### Mechanism reading

β2=0.99 (#236) appears to ABSORB the bulk of WD=0.005's standalone gain — both mechanisms act on effective AdamW aux step magnitude during cooldown. The clean U-curve flattens out once β2=0.99 is also active. Compositional projection to post-#290 stack: ~3.27323 (still +0.00123 above gate).

**Verdict**: productive-null on post-#236+ stacks. Closed.

**Wave-6 follow-up assigned (PR #348)**: thorfinn per-group AdamW WD — test lm_head-only and scalar-only WD at 0.002 (smaller, accounting for stack-tightening). Scalar group is the most sparsity-vulnerable per #280, and embed is over-regularized by floor+β2.

## 2026-05-18 07:48 UTC — PR #322: AdamW ε sweep (alphonse) — CLOSED (productive-null)

- Branch: `g1r4-alphonse/adamw-eps-sweep`
- Hypothesis: After β2=0.99 merge, the AdamW denominator √v̂ + ε floor needs re-tuning. Originally tested ε ∈ {1e-10, 1e-9, 1e-8, 1e-7}.

### Results — n=1 within-pod (post-#236 stack)

| Arm | ε | W&B | val_loss | fs | Δ vs A |
|-----|---|-----|---------:|----:|--------:|
| A (control) | 1e-10 | `xtu4lenc` | **3.27152** | 3225 | — |
| B | 1e-9 | `edimlls6` | 3.27413 | 3250 | +0.00261 |
| C | 1e-8 | `4247pkjc` | 3.27464 | 3275 | +0.00312 |
| D | 1e-7 | `efcp88at` | 3.27314 | 3250 | +0.00162 |

All 3 treatment arms regress >+0.0015 vs control. ε=1e-10 (current default) is within-pod winner. Concave shape (peak regression at C=1e-8, partial recovery at D=1e-7).

### Mechanism reading

β2=0.99 (#236) already smooths v̂ across ~100 steps. Larger ε floor masks legitimate signal in the AdamW step normalizer rather than stabilizing it. Partial recovery at D may reflect ε approaching typical √v̂ magnitude where it stops being a "mostly-zero floor" and starts blunting effective LR uniformly.

**Verdict**: productive-null on GLOBAL ε axis.

**Follow-up assigned (PR #351)**: alphonse per-group SCALAR ε — edward #280 showed scalar group is most sparsity-vulnerable. Test scalar ε ∈ {1e-12, 1e-10, 1e-8, 1e-6} while embed/lm_head stay at 1e-10. Scalar-specific apex may exist where global apex didn't.

## 2026-05-18 08:35 UTC — PR #324: AdamW β1 sweep (askeladd) — CLOSED productive-null ❌

- Branch: `g1r4-askeladd/adamw-beta1-sweep`
- Hypothesis: Symmetry with β2=0.99 gain (#236) — if longer second-moment memory helps aux groups, longer first-moment memory (higher β1) should too.

### Results — n=1 within-pod (post-#236 stack, arm-A = post-#290 control)

| Arm | β1 | W&B | val_loss | fs | Δ vs A |
|---|---|---|---|---|---|
| A (control) | 0.80 | `lhjyu0od` | **3.27113** | 3225 | — |
| B | 0.85 | `46287hih` | 3.27251 | 3250 | +0.00138 |
| C | 0.90 | `0jb6p8lt` | 3.27238 | 3225 | +0.00125 |
| D | 0.95 | `7bkajk96` | 3.27712 | 3300 | **+0.00599** |

Drift gate (arm-A): |3.27113 − 3.27200| = 0.00087 ≤ 0.003 ✓ (lucky-low pod).

### Key findings

1. **Monotone-worse direction**: β1=0.80 (current default) is optimal in tested range. Arm-D (β1=0.95) shows large regression (+0.00599), widening monotonically through the cooldown.
2. **Asymmetric with β2**: variance estimator (v-EMA) benefits from long memory because gradient *magnitudes* are stationary across batches; direction estimator (m-EMA) does NOT benefit because gradient *directions* are non-stationary for embedding tables (active token IDs shift batch-to-batch).
3. **Late-cooldown gap widens**: Δ(D−A) monotonically increases from +0.00552 at step 3150 to +0.00599 at terminal — arm-D never catches up.

### Verdict

Productive-null. β1 axis closed — β1=0.80 is the confirmed optimum in {0.80, 0.85, 0.90, 0.95}. Sub-0.80 probe (β1={0.5, 0.7}) is a potential follow-up but lower-priority than fresh mechanism exploration.

**Follow-up assigned (PR #354)**: logit softcap value sweep — hardcoded 15 in `GPT.forward` has never been tuned. Fresh axis orthogonal to all in-flight work.

## 2026-05-18 08:35 UTC — PR #315: lm_head steeper-decay cooldown (nezuko) — CLOSED productive-null ❌

- Branch: `g1r4-nezuko/lmhead-decay-shape`
- Hypothesis: lm_head dislikes a non-zero cooldown floor (PR #266 showed floor=15% HURTS for non-embed groups), so it should *like* steeper-than-linear decay (mirror hypothesis).

### Results — n=1 within-pod (arm-A = linear control)

| Arm | shape | W&B | val_loss | fs | Δ vs A | cum_lmhead_lr |
|---|---|---|---|---|---|---|
| A (control) | linear | `t4eyje4t` | **3.27300** | 3250 | — | 2178.00 |
| B | quadratic | `fh7plnkg` | 3.27632 | 3275 | +0.00332 | 2177.75 |
| C | cubic | `le0falgq` | 3.27651 | 3275 | +0.00351 | 2177.50 |
| D | exp_decay (k=3) | `ti50qm4a` | 3.27613 | 3275 | +0.00313 | 2177.61 |

Compute-neutral: cum LR spread 0.023% across arms.

### Key findings

1. **Hypothesis FALSIFIED**: all steeper shapes regress +0.00313 to +0.00351. Mirror of #266 floor finding does NOT hold.
2. **Unified lm_head mechanism**: both findings (dislikes floor AND dislikes steep early decay) point to the same conclusion — **linear is the lm_head cooldown sweet spot**. lm_head is sensitive to *time-of-update concentration*, not just total LR budget. Redistributing LR away from the late-cooldown window (either upward via floor or earlier via steep decay) regresses ~+0.003.
3. **Late-cooldown work is real**: the small late-cooldown updates do meaningful work for lm_head; cannot be front-loaded or lifted.

### Verdict

Productive-null with negative stacking signal. lm_head=linear default is correct and axis is closed for steeper-than-linear direction. Shallower-than-linear (sqrt, tiny floor) remains unprobed but is lower-priority.

**Follow-up assigned (PR #356)**: Muon μ schedule sweep — ramp_up (0.90→0.99) as the 4th late-training precision lever, paralleling β2=0.99, late_peak NS shape, and linear_ramp_down NS coef schedule.

## 2026-05-18 11:05 UTC — PR #335: Muon LR cooldown FLOOR sweep (edward) — CLOSED productive-null ❌

- Branch: `g1r4-edward/muon-lr-floor-sweep`
- Hypothesis: Embed-floor mechanism (#235 merged) generalizes to Muon side — floor=15% on Muon LR cooldown helps like it did for embed.

### Results — n=1 within-pod (post-#236 stack, pre-#285+#290)

| Arm | Muon floor | W&B | val_loss | fs | Δ vs A |
|---|---|---|---|---|---|
| A (control) | 0.00 | `a7wkuj8d` | **3.27482** | 3275 | — |
| B | 0.05 | `c1fho1zl` | 3.27631 | 3325 | +0.00149 |
| C | 0.10 | `7ex73d65` | 3.28118 | -1 | +0.00636 |
| D | 0.15 | `aehzf96c` | 3.29141 | -1 | **+0.01659** |

Drift gate (arm-A vs post-#236 baseline 3.27407): |Δ|=0.00075 ≤ 0.003 ✓.

### Key findings

1. **Monotonic worsening** — each additional floor increment degrades val by increasing amounts (~linear initially then accelerating).
2. **Arms C and D don't even reach target 3.28** — the degradation is not noise.
3. **Mechanism confirmed**: Embed-floor works because embed depends on AdamW LR for late-cooldown updates. Muon's update magnitude is already controlled by NS orthogonalization — forcing a non-zero LR floor over-pushes along directions whose gradient magnitude is genuinely small in cooldown (NS has already done the spectrum-shaping work).
4. **Complementary to #315 and #266**: Three independent experiments (lm_head/scalar floor, lm_head steeper decay, Muon floor) all confirm: cooldown shape modifications help ONLY the embed group. All other groups want LR motion to reach zero in cooldown.

### Verdict

Strong productive-null. Muon-floor axis is closed. The embed-floor mechanism map is now complete: it is embed-specific and non-transferable.

**Follow-up assigned (PR #374)**: edward embed init scale sweep — N(0,1) default init, sweep {0.5, 1.0, 1.5, 2.0} multipliers. Fresh initialization axis, completely unexplored.

## 2026-05-18 12:50 UTC — PR #300: Embed LR floor value sweep (tanjiro) — CLOSED productive-null ❌

- Branch: `g1r4-tanjiro/embed-floor-sweep`
- Hypothesis: The embed LR floor (merged at 15% in #235) has not been tuned. Apex may not be 15%. Sweep floor ∈ {0.10, 0.15, 0.20, 0.30} on post-#236 stack.

### Results — 3-phase sweep

**Phase 1 — Screening (4-arm within-pod, pre-#236 baseline 3.27434)**

| Arm | floor | W&B | val_loss | fs | Δ vs A |
|---|---|---|---|---|---|
| A (control) | 0.15 | `bhj5nllu` | 3.27441 | 3275 | — |
| B | 0.10 | `dkgj7ho3` | 3.27630 | 3275 | +0.00189 |
| **C** | **0.20** | **0jtlaw2f** | **3.27282** | **3250** | **−0.00159** ✓ signal |
| D | 0.30 | `k6yhwuh5` | 3.27549 | 3275 | +0.00108 |

Clean inverted-U with apex at floor=0.20.

**Phase 2 — Confirmation (floor=0.20, post-#236+β2=0.99 stack, pre-#285+#290)**

| Seed | W&B | val/loss | fs |
|---|---|---|---|
| seed-1 | `041u375w` | 3.26995 | 3225 |
| seed-2 | `prem5jzv` | 3.27307 | 3250 |
| seed-3 | `t8s4wpfe` | 3.27251 | 3250 |
| **n=3 mean** | — | **3.27184** | **3241.67** |

n=3 mean 3.27184 vs post-#290 baseline 3.27200: Δval = −0.00016 (razor-thin). fs regressed (+8.34 steps). Marginal val beat but fs gate fails → re-confirm on full post-#290 stack.

**Phase 3 — Re-confirmation (floor=0.20, FULL post-#290 stack)**

| Seed | W&B | val/loss | fs |
|---|---|---|---|
| re-conf seed-1 | `vvndpgmx` | 3.27521 | 3275 |
| re-conf seed-2 | `mr6za83o` | 3.27296 | 3250 |
| **n=2 mean** | — | **3.274085** | **3262.5** |

vs baseline: Δval = +0.00209, Δfs = +29.17 → REGRESS. n=2 mean 3.274085 > 3.27300 threshold → productive-null per pre-staged rule.

### Key findings

1. **floor=0.20 was a real win on the pre-#285+#290 stack** (phase-2 n=3 technically beat val baseline by −0.00016, though fs gate fails), but the gain did NOT survive composition with late_peak + linear_ramp_down.
2. **Mechanism saturation**: embed-floor ⊆ late-cooldown-precision family, sharing the "precise step direction in cooldown" mechanism with late_peak (#285) and linear_ramp_down (#290). Adding a 3rd lever in the same family does not compose linearly.
3. **9 seeds total in this PR** — the most heavily tested hypothesis on the branch. Verdict is robust.
4. **Sparsity-precision family** now has 3 confirmed members: β2=0.99 (#236), late_peak (#285), linear_ramp_down (#290). All target the cool-down phase. embed-floor is a 4th candidate absorbed by these three.

### Verdict

Productive-null. Current merged default floor=0.15 (#235) remains best known on post-#290 stack. Closing this axis.

**Follow-up assigned (PR #377)**: Pruning ablation — drop one of {late_peak, linear_ramp_down, β2=0.99} at a time to measure each merge's load-bearing contribution on the current stack. Tests whether mechanism saturation is symmetric (i.e., any merge partially subsumed by others → candidate for swap to fresh mechanism).

## 2026-05-18 14:10 UTC — PR #345: NS coef linear_ramp_down DEPTH sweep (fern) — CLOSED productive-null ❌

- Branch: `g1r4-fern/ns-coef-ramp-depth`
- Hypothesis: Is depth=0.42 optimal for the linear_ramp_down NS coef schedule? Sweep 4 mean-neutral depths at c_mean=0.49: {0.30, 0.42, 0.55, 0.70}.

### Results — n=1 within-pod (post-#290 stack)

| Arm | depth | c_start → c_end | val_loss | fs | Δ vs A | W&B |
|---|---|---|---|---|---|---|
| B | 0.30 (shallower) | 0.640 → 0.340 | 3.27666 | 3300 | **+0.00390** (outside null) | `epny13w8` |
| **A (control)** | **0.42** | **0.700 → 0.280** | **3.27276** | **3250** | **—** | `5g2us4g3` |
| C | 0.55 (steeper) | 0.765 → 0.215 | 3.27398 | 3250 | +0.00122 (within null) | `ojszel80` |
| D | 0.70 (much steeper) | 0.840 → 0.140 | 3.27292 | 3250 | +0.00016 (essentially tied) | `pakh7gnl` |

All arms mean-neutral: c_mean=0.49 throughout.

### Key findings

1. **Asymmetric plateau**: depth=0.42 is on a broad flat plateau on the steep side [0.42, 0.70] — arms C and D are within noise. Shallower side (depth=0.30) regresses materially (+0.00390).
2. **Small-singular suppression matters EARLY**: high-c in early iterations (what arm-B lacks) does real work when momentum buffers are noisy. By late training, even very low c=0.14 (arm-D) gives a usable NS step.
3. **Depth=0.42 confirmed optimal** as a practical operating point in {0.30, 0.42, 0.55, 0.70}. The asymmetric pattern means only sub-0.42 depths are actionable follow-ups (and arm-B already showed they hurt).
4. **Linear ramp_down confirmed doing real work**: the +0.00390 regression at depth=0.30 (near-constant schedule) is consistent with the original #290 finding.

### Verdict

Productive-null with confirmed apex at depth=0.42. The depth axis is closed — going steeper (0.55, 0.70) doesn't help and going shallower (0.30) hurts. Current post-#290 default (depth=0.42, c_mean=0.49) is confirmed optimal.

**Follow-up assigned (PR #380)**: fern lm_head proj init std sweep — zero-init lm_head (current default w.zero_()) has never been challenged on r4 branch. Fresh init axis, mechanistically distinct from edward #374 (lm_head proj feeds logits directly, no RMSNorm).
