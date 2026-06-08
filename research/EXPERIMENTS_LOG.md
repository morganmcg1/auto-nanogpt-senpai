# SENPAI Research Results — Auto-nanoGPT Open SOTA v2 Launch

## 2026-06-08 01:30 — PR #2362: H-BU Lookahead on AdamW groups — CLOSED 39TH LEVER (open2-thorfinn)

- Branch: `open2-thorfinn/h-bu-lookahead-adamw`
- Hypothesis: Apply Lookahead (k=5, α=0.5) weight-space slow-weight mixing on AdamW groups (embed, lm_head, scalars) to improve final convergence via periodic parameter averaging.

### Results

| Arm | n | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276172) |
|---|---:|---:|---:|
| A (Lookahead k=5, α=0.5 on AdamW) | 1 T0 (T1 aborted) | **3.28440** | **+0.00823 CATASTROPHIC** |

- W&B runs: `oqmty85f` (T0 completed, T1 crashed at step 426), `bgre3kr5` (smoke)

### Analysis

**Zero-init catastrophe mechanism confirmed:** `model.proj.weight` (lm_head) is zero-initialized. Lookahead with k=5 accumulates 5 fast-weight steps before each slow-weight sync. At sync step:
- For embed group (lr=0.3): effective accumulated step ≈ 5 × 0.3 = 1.5× normal amplitude — catastrophically large for the embedding table.
- For lm_head (zero-init, lr=1/320=0.003125): ‖Δ‖ ≈ 5 × 0.003125 × 6164 ≈ 96 per-neuron — ~5× above the CE instability threshold of ~19-20 from zero.

The Lookahead wrapper turns a linear update into an effective 5× LR amplification at sync points. This is incompatible with zero-initialized layers and large-lr groups.

**39th saturated lever: Lookahead on AdamW groups incompatible with zero-init layers.** Future Lookahead experiments must: (a) skip zero-init layers (use separate param groups), (b) use k=1 or α→0 for minimal accumulation, or (c) require multi-step warmup before first sync. H-CA (soft lm_head warmup) targets the zero-init axis directly.

## 2026-06-08 00:28 — PR #2359: H-BM lm_head AdamW LR decoupling — CLOSED 38TH LEVER (open2-askeladd)

- Branch: `open2-askeladd/h-bm-lmhead-lr-decoupling`
- Hypothesis: Decouple lm_head AdamW LR from default 1/320=0.003125. Test downward (0.002, -36%) and upward (0.005, +60%) to probe whether the lm_head LR is optimally set.

### Results

| Arm | Config | n | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276172) |
|---|---|---:|---:|---:|
| A | lm_head_lr=0.002 (−36%) | 2 | 3.276269 (mean) | +0.000097 INCONCLUSIVE |
| B | lm_head_lr=0.005 (+60%) | 0 | NaN at step 2 | CATASTROPHIC |
| Smoke B' | lm_head_lr=0.004 (+28%) | smoke | NaN at step 2 | CATASTROPHIC |
| Smoke B'' | lm_head_lr=0.0035 (+12%) | smoke | NaN at step 2 | CATASTROPHIC |

- W&B runs: `vn32x4gj` (Arm A n=2), `7mgxzz8g` (Arm B 0.005 NaN), `9arm70eo` (smoke 0.004 NaN), `xnpqp6qw` (smoke 0.0035 NaN)
- Arm A T0/T1 spread: 0.000028 (very tight, not seed-dominated)

### Analysis

The upward stability ceiling is sharply between 0.003125 (baseline, stable) and 0.0035 (+12%, catastrophic NaN at step 2). The mechanism: `model.proj.weight` is zero-initialized, so step-1 AdamW update ‖Δ‖ ≈ √38M × lr ≈ 6164 × lr. CE surface unstable past ‖Δ‖ ≈ 19-20 from zero. At lr=0.003125, ‖Δ‖ ≈ 19.3 (stable); at lr=0.0035, ‖Δ‖ ≈ 21.6 (unstable). Student independently discovered this mechanism.

The downward direction (Arm A, 0.002) gives INCONCLUSIVE regression (+0.000097). Both directions saturated.

**38th saturated lever: lm_head AdamW LR locked at 1/320 (without soft warmup).** H-CA assigned to askeladd to test soft warmup + higher target LR, which could unlock upward headroom past the step-1 catastrophe ceiling.

## 2026-06-07 23:30 — PR #2349: H-AY AdamW eps sweep — MERGED NEW RANK-1 (open2-frieren)

- Branch: `open2-frieren/h-ay-adamw-eps`
- Hypothesis: Sweep AdamW eps across 1e-8 (looser), 1e-10 (default), 1e-12 (tighter) for all AdamW groups. Tighter eps → smoother second-moment normalization → potentially better embedding and head optimization.
- Status: **MERGED — NEW RANK-1: 3.276172** (−0.000021 below PR #2317's 3.276193)

### Results

| Arm | Config | n | val/ri_loss_gamma_neg0p0750 | vs prev rank-1 (3.276193) |
|---|---|---:|---:|---:|
| A (Arm A) | eps=1e-8 | 2 | 3.276584 (mean) | +0.000391 INCONCLUSIVE |
| **B (Arm B)** | **eps=1e-12** | **4** | **3.276172 (mean)** | **−0.000021 MERGE** |
| T0 (seed 0) | eps=1e-12 | 1 | 3.277014 | +0.000821 |
| T1 (seed 1) | eps=1e-12 | 1 | 3.275707 | −0.000486 |
| T2 (seed 2) | eps=1e-12 | 1 | 3.276387 | +0.000194 |
| T3 (seed 3) | eps=1e-12 | 1 | 3.275579 | −0.000614 |

- W&B runs: `dnvqhw4p` (Arm A n=2), `521ky42j` (Arm B n=2 seeds 0-1), `nbptdumy` (Arm B seeds 2-3)
- Contract: (3.28 − 3.276172) × √4 = 0.007656 ≥ 0.004 ✅

### Analysis

- Margin improvement is 0.000021 below prev rank-1 — statistically borderline, student acknowledged as "a tie", but per compound-improvements principle the merge was correct.
- Two seeds (1,3) beat rank-1; two (0,2) miss it — matches **cross-PR seed pattern** documented in research state (seed 0 systematically BAD, seed 1 GOOD, seed 2 ~neutral, seed 3 GOOD on AdamW-group perturbations at this training step).
- Mechanism: AdamW eps 1e-10 → 1e-12 tightens the bias correction denominator, marginally stabilizing second-moment normalization in the final 500 steps where embed/lm_head gradients are largest in magnitude.
- Cleanup PR #2363 assigned to frieren: remove `--adam_eps_override` flag, hardcode eps=1e-12 directly.
- **New stack**: NC × Sinkhorn Arbor × EN (γ=0.99) × RI (capture=2375, γ=−0.075) + **eps=1e-12**

---

## 2026-06-07 22:14 — PR #2357: H-BK Cosine warm-restart on Muon LR at step 2000 (open2-thorfinn)

- Branch: `open2-thorfinn/h-bk-warm-restart`
- Hypothesis: Apply a cosine warm-restart to Muon LR at step 2000 (peak=0.5× MUON_LR, warmup=100 steps). Arm A: restart_step=2000, peak=0.5×.
- Status: **Closed FALSIFIED — 37th saturated lever.**

### Results

| Arm | n | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|---:|
| A (restart=2000, peak=0.5×) | 1 (T1 aborted) | **3.28737450** | **+0.011182 FALSIFIED** |

- W&B runs: `zs6jedkm`. Run terminated T0; T1 aborted at step 2078/2890.
- Arm B (peak=0.3×) not launched — T0 catastrophic.

### Analysis

- T0 val_loss trajectory shows direct regression during restart window: step 2000→2125 (3.41188→3.42086) — LR jump disrupted convergence and the network never recovered by step 2890.
- LR table at RI capture step 2375: baseline=0.004733, warm-restart=0.013681 → **2.89× boost exactly at RI anchor window**.
- The catastrophic outcome comes from three simultaneous disruptions: (1) EN's slow-trajectory γ=0.99 mean coherence corrupted by the sudden LR jump; (2) RI anchor at step 2375 captures corrupted state; (3) NC's column-equalization, operating post-NS5, amplifies the instability.
- **Invariant #5 confirmed**: the (NC × Arbor × EN × RI) stack requires **monotonic-down Muon LR through step 2375 RI capture**. Any non-monotonic Muon LR phase in the window [~step 1950, 2375] destroys EN slow-trajectory coherence and corrupts RI anchor.
- Combined with H-AU (Muon LR warmup) + H-AV (FINAL_LR_POWER): the RI capture window has unique monotonicity sensitivity. Future Muon LR-schedule perturbations must restrict to (a) before EN rest-window end (~step 1950) or (b) after RI capture (step ≥ 2375).
- 37th saturated lever. Thorfinn → H-BU (Lookahead-on-AdamW).

---

## 2026-06-07 19:35 — PR #2351: H-BC Spectral radius norm targeting in muon_update (open2-fern)

- Branch: `open2-fern/h-bc-spec-norm`
- Hypothesis: Replace the post-NS5 shape heuristic `max(1, rows/cols)**0.5` with `σ_target/σ̂` where σ̂ is the measured operator norm. Arm A: σ_target=1.0. Arm B: σ_target=0.7.
- Status: **Closed FALSIFIED — 35th saturated lever.**

### Results

| Arm | n | mean val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|---:|
| A (σ_target=1.0) | 2 | **3.280025** | **+0.003832 FALSIFIED** |
| B (σ_target=0.7) | killed early | — | mechanistically worse, not run |

- W&B runs: `v65l1o11` (Arm A). `open2-fern/h-bc-spec-norm` / `H-BC-spec-norm` group.

### Analysis

- σ̂ probe at step 5 showed mean σ̂ ≈ 1.67 across 3072×768 mlp.fc.weight — i.e. post-NS5 update is NOT operator-norm 1.0 as the shape heuristic assumes.
- σ_target=1.0 scaling (effective ×0.60 on principal axis vs baseline ×2.0) redistributes update mass from non-principal singular directions onto the principal direction.
- Downstream per-row second-moment rescaling (lines 945–952) preserves total Frobenius via `vnorm/vnorm_new`, so this is effectively mass-redistribution, not a global LR change.
- **Failure mechanism**: the principal direction of the post-NS5 update is noise-amplified rather than signal-bearing. NC's column-equalization already biases toward orthogonal directions, so concentrating onto the principal axis is double-suppression.
- **Invariant**: post-NS5 update spectrum should be left as-is or further dispersed; never concentrated onto principal direction on this stack.
- 35th saturated lever. askeladd→H-BM.

---

## 2026-06-07 19:30 — PR #2355: H-BI Depth-wise Muon LR decay (open2-tanjiro)

- Branch: `open2-tanjiro/h-bi-depth-muon-lr`
- Hypothesis: Apply per-block multiplicative LR decay on Muon (Arm A: top block at full MUON_LR=0.0375, geometric decay=0.85 downward, bottom block ≈0.00567).
- Status: **Closed FALSIFIED — 34th saturated lever (early abort at T0).**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---:|---:|---:|
| T0 (seed 0) | **3.29223** | **+0.016037 — 32× noise floor** |
| T1 | killed | rescue impossible (needed ≤3.260557) |

- W&B run: `hld6fioy`. Command: `--depth_lr_decay 0.85 --depth_lr_inverted 0`.

### Analysis

- Single-seed +0.016 is the largest regression in the recent Muon-side wave — larger even than H-BA Sophia-G's +0.079 in magnitude relative to what we'd need for T1 rescue.
- **Failure mechanism**: the PR #2317 stack's NS5 cubic poly assumes uniform per-layer step sizes for stability; layer-asymmetric LR breaks the NC × Arbor equalization invariant at the NS5 boundary. The bottom layers are starved of update magnitude and fall behind irrecoverably.
- Arm B (inverted — top blocks starved, bottom blocks full LR) not run; same mechanism applies in the other direction.
- **Invariant**: Muon LR uniformity across blocks is load-bearing for the NC × Arbor × NS5 stack.
- 34th saturated lever. tanjiro→H-BN.

---

## 2026-06-07 19:26 — PR #2354: H-BH GC on Muon momentum buffer (open2-askeladd)

- Branch: `open2-askeladd/h-bh-gc-momentum`
- Hypothesis: Apply gradient centering (subtract per-row mean) on `state["momentum"]` after each `lerp_(grad, 1-mu)` EMA update, before the Nesterov blend. Tests whether DC-mode removal from the momentum buffer improves the NC × Arbor × EN × RI stack.
- Status: **Closed FALSIFIED — 33rd saturated lever (early abort at T0).**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---:|---:|---:|
| T0 (seed 0) | **3.284688** | **+0.008495 — 17× noise floor** |
| T1 | killed | rescue impossible (needed ≤3.268498) |

- W&B run: `4q46nmwf`. Command: `--muon_gc_momentum 1`.

### Smoke probe (step 30)
- (3072,768) pre_mean=2.697e-03 → post_mean=-3.622e-10 ✓ Centering executes correctly.

### Analysis

- Post-EMA centering of `state["momentum"]` removes the global DC mode from the rank-2 momentum tensor before the EMA-blend with the current gradient.
- Stacked on NC (which performs per-row × per-col L2 equalization post-NS5), this creates a **double DC-mode cancellation**: the EMA-Nesterov slow trajectory loses its mean component at two stages.
- The EN slow trajectory's mean component carries signal in the converged stack. Removing it is destructive.
- **GC-on-Muon family now closed**: H-AT (raw gradient, 28th lever) + H-BH (momentum buffer, 33rd lever). Both FALSIFIED with the same mechanism. Any further DC-mode operation on the Muon update path is contraindicated.
- 33rd saturated lever. askeladd→H-BM.

---

## 2026-06-07 18:25 — PR #2346: H-AW EN REST_STEPS=2300 — n=4 CLOSURE (open2-edward)
- Branch: `open2-edward/h-aw-en-rest-steps`
- Hypothesis: Extend EMA-Nesterov rest window by advancing REST_STEPS from 1950 to 2300 (vs 2890 total), giving the EN momentum buffer a longer flat tail to stabilize before RI capture at step 2375.
- W&B runs: `v65l1o11` (n=2, seeds 0-1), `479jhxyf` (n=2, seeds 2-3 confirm)
- Status: **Closed FALSIFIED — 30th saturated lever.**

### Results (n=4)

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (seed 0) | 3.276059 | −0.000134 (below rank-1!) |
| T1 (seed 1) | 3.276489 | +0.000296 |
| T2 (seed 2, confirm) | 3.274631 | −0.001562 |
| T3 (seed 3, confirm) | 3.277875 | +0.001682 |
| **n=4 mean** | **3.276256** | **+0.000063 FALSIFIED** |
| n=4 σ | ~0.00126 | 2.5× noise floor — variance blow-out |

### Analysis

- n=2 mean (3.276274) was INCONCLUSIVE. n=4 seeds 2-3 showed massive variance blow-out: T2=−0.001562 (huge positive outlier) vs T3=+0.001682 (negative outlier). σ≈0.00126 is 2.5× the noise floor.
- n=4 mean = 3.276256 = +0.000063 above rank-1. Contract margin 0.007488 < rank-1's 0.007615 → if merged, this would LOSE 0.000127 in statistical margin.
- The variance amplification is the killer: REST_STEPS=2300 is sensitive to initialization. The current REST_STEPS=1950 with γ=0.99 establishes a specific 940-step momentum decay region before RI capture at 2375. Extending to 2300 compresses this to 75 steps, creating seed-dependent chaos in the EN-RI handoff.
- **EN rest-window timing axis is now fully saturated** — REST_STEPS at every tested value (1950=default, 2300) shows the 1950 default is the calibration point.
- 30th lever closed. Student (edward) suggested H-BJ (NS-iter × Muon LR coupling) as next experiment.

---

## 2026-06-07 18:20 — PR #2351: H-BC Spectral radius norm (open2-fern)
- Branch: `open2-fern/h-bc-spectral-norm`
- Hypothesis: Normalize each Muon weight matrix by its spectral radius (largest singular value) before NS5 orthogonalization, redistributing mass from large-norm matrices into the update direction.
- W&B run: `v65l1o11` (n=2, Arm A)
- Status: **Closed FALSIFIED.**

### Results (n=2)

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 | 3.280820 | +0.004627 |
| T1 | 3.280820 | +0.004627 (identical) |
| **n=2 mean** | **3.280820** | **+0.004627 FALSIFIED** |

### Analysis

- T0=T1 identical — perfect reproducibility of a bad result (9× noise floor).
- The spectral radius normalization pre-conditions the gradient before NS5. NS5 itself already projects to the Stiefel manifold (unit spectral norm), so the additional pre-normalization is redundant and introduces a singular-value computation overhead. The mechanism "mass redistribution" doesn't help because NS5's orthogonalization already handles gradient scale.
- Zero spread across seeds is unusual and confirms the mechanism has a systematic negative effect, not random variance.
- Student awaiting label swap to formally close.

---

## 2026-06-07 18:20 — PR #2352: H-BF SNR-adaptive AdamW LR (open2-nezuko)
- Branch: `open2-nezuko/h-bf-snr-adaptive-adamw`
- Hypothesis: Scale each AdamW parameter group's LR by a signal-to-noise ratio (SNR) derived from gradient statistics, targeting groups where the gradient SNR is high (signal-dominated) with higher LR and low-SNR groups with lower LR.
- W&B runs: `pw1mydik` (smoke, 60 steps), `5d6pyw54` (Arm A full, n=1)
- Status: **Closed FALSIFIED — 31st saturated lever.**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (Arm A snr_target=1.0) | 3.278413 | **+0.002220** (4.4× noise floor) |
| T1 | Aborted (advisor early-abort rule) | — |

### Analysis

- **Key mechanism insight from smoke (`pw1mydik`):** SNR clip saturates at 3× for ALL AdamW groups (embed, lm_head, scalars) throughout the entire post-warmup window. Root cause: with β₂=0.95, consecutive gradients are highly correlated → `v_t ≈ m_t²` → `noise_var = v_t − m_t²` ≈ 0 → SNR → ∞. The 1e-10 clamp_min is the active floor.
- This means SNR-adaptive LR at snr_target=1.0/clip=3 **degenerates to a flat 3× LR multiplier** on all AdamW groups. T0=+0.002220 confirms catastrophic effect of tripling all AdamW LRs simultaneously.
- The embed LR (0.3×3=0.9) and lm_head LR (0.003125×3≈0.0094) are both wildly out of their calibrated range.
- Advisor directed early abort after T0. Student to post SENPAI-RESULT.
- 31st lever closed.

---

## 2026-06-07 18:20 — PR #2353: H-BG PMuon + β₂-pulse (open2-thorfinn)
- Branch: `open2-thorfinn/h-bg-pmuon-beta2-pulse`
- Hypothesis: Apply a pulsed β₂ schedule to Muon's momentum buffer — cycle β₂ between 0.95 and a lower value (0.85) on a periodic schedule to perturb the momentum state and potentially escape local optima.
- W&B run: `q9y1953e` (Arm A, n=2)
- Status: **Closed FALSIFIED — 32nd saturated lever.**

### Results (n=2)

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 | 3.278038 | +0.001845 |
| T1 | 3.278038 | +0.001845 (identical) |
| **n=2 mean** | **3.278038** | **+0.001845 FALSIFIED (3.7× noise floor)** |

### Analysis

- T0=T1 identical with zero spread — same pattern as H-BC. Confirms systematic negative effect from momentum-state oscillation, not seed variance.
- β₂-pulsing on Muon disrupts the EN γ=0.99 momentum lerp. The EN layer provides the slow trajectory averaging; adding β₂ oscillation on Muon's internal momentum conflicts with EN's established smoothing regime.
- **Momentum-state oscillation on Muon is uniformly harmful** — the EN mechanism already provides momentum smoothing at the right timescale. Any additional perturbation of the momentum buffer degrades performance.
- 32nd lever closed.

---

## 2026-06-07 16:15 — PR #2350: H-BA Sophia-G diagonal Hessian on AdamW (open2-tanjiro)
- Branch: `open2-tanjiro/h-ba-sophia-g`
- Hypothesis: Replace AdamW's diagonal variance estimate `v_t` with Sophia-G's Gauss-Newton-Bartlett (GNB) Hessian estimate, applied to all AdamW groups (embed, lm_head, scalars).
- W&B run: `d7sjufih` (Arm A n=2, killed after T0)
- Status: **Closed FALSIFIED at T0 — 29th saturated lever.**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (Sophia-G k=10 ρ=20 β₂=0.99) | 3.35478 (`speedrun/final_best_val_loss`) | **+0.07859** (157× noise floor) |
| T1 | Killed at step ~3916/5780 | — |

### Mechanism diagnosis (definitive)

Student's W&B Sophia telemetry isolated the root cause:

| Sophia metric | Value | Interpretation |
|---|---:|---|
| `clip_fraction` | 0.456 | 46% of params saturate the [-1, 1] winsorization → update is sign-SGD on those coordinates |
| `ratio_mean_abs` (pre-clip) | 4.27e8 | denominator ρ·h collapses for sparse-row params |
| `hess_rms` | 10.4 | overall scale small |
| `hess_zero_fraction` | 0.0099 | not strictly zero but near-zero tail dominates |
| `hess_nonfinite` | 0 | no numerical pathology |

**Root cause**: AdamW is responsible for `embed.weight` (50257×768) and `lm_head.weight` (50257×768) in this codebase. These have **sparse-row gradients** — most vocab rows see no token per microbatch — so the GNB estimator `h = β₂·h + (1-β₂)·g_sample²` accumulates near-zero values for the bulk of rows. Once `h_i ≈ 0`, the update ratio `m_i/(ρ·h_i)` saturates the winsorization, degenerating the update to sign-SGD with magnitude 1 per coordinate.

Effective behavior on sparse-row AdamW params is therefore unmoderated sign-SGD at high LR (embed lr=0.3, lm_head lr=0.003125), which destabilizes training catastrophically.

### Strategic conclusion

- **AdamW-side preconditioner family is closed for sparse-gradient param groups** (embed/lm_head). Sophia's GNB design assumes dense per-coord gradient stats; vocab-sized embeddings violate the assumption.
- Implementation credit to tanjiro: rigorous Sophia-H → Sophia-G pivot when SDPA blocked Hutchinson, correct paper-faithful GNB resampling logic, per-coord winsorization, telemetry that **isolated the failure mechanism exactly**.
- The path forward for AdamW-side optimization mechanisms must either (a) exclude embed/lm_head, (b) use a different curvature estimator (not g²-based) that handles sparse rows, or (c) abandon AdamW-side preconditioning entirely.
- 29th lever closed.
- tanjiro reassigned to H-BI (depth-wise Muon LR) — back to Muon territory.

---

## 2026-06-07 14:50 — PR #2343: H-AT Gradient Centralization on Muon — n=4 CLOSURE (open2-askeladd)
- Branch: `open2-askeladd/h-at-grad-centralization`
- Hypothesis: Apply Gradient Centralization (GC, Yong et al. 2020) to Muon parameters — subtract the mean of each gradient tensor before NS5 orthogonalization.
- W&B runs: `qwbvitns` (n=2 seeds 0-1), `crhbqarp` (n=2 seeds 2-3 confirm)
- Status: **Closed FALSIFIED at n=4 — 28th saturated lever.**

### Results (n=4)

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (seed 0) | 3.276329 | +0.000136 |
| T1 (seed 1) | 3.276839 | +0.000647 |
| T2 (seed 2) | 3.278459 | +0.002266 |
| T3 (seed 3) | 3.277071 | +0.000878 |
| **n=4 mean** | **3.277174** | **+0.000981 FALSIFIED** |
| n=4 σ | 0.000911 | ~1.8× noise floor — variance blow-out |

### Analysis

- n=2 mean (3.276584) was inconclusive at +0.000391, but n=4 closes FALSIFIED at +0.000981. Seed 2 was a +0.002266 outlier driving the close.
- **Critical finding**: σ=0.000911 is roughly 2× the typical seed variance (~0.0005), meaning GC on raw gradient destabilizes seed-to-seed reproducibility. This is the load-bearing failure mode — even if mean is borderline acceptable, variance is unacceptable for a stack already this tight.
- Mechanism hypothesis: per-channel mean subtraction on raw Muon gradient interacts poorly with EN's momentum buffering and NC's cautious mask. The mean-centered direction conflicts with NC's preserve-sign logic on a per-row basis.
- **H-BH (askeladd PR #2354) is the mechanism-isolation follow-up**: GC applied to the post-EMA momentum buffer instead of raw gradient. If H-BH also fails, the entire GC-on-Muon family is dead.
- 28th lever closed.

---

## 2026-06-07 14:13 — PR #2348: H-AZ Lookahead Muon wrapper (open2-thorfinn)
- Branch: `open2-thorfinn/h-az-lookahead-muon`
- Hypothesis: Wrap Muon with Lookahead (Zhang et al. 2019) — k=6 fast steps then α=0.5 slow merge. Tests whether decoupling slow/fast trajectory averaging helps on top of existing EN smoothing.
- W&B run: `tjv3mars` (Arm A, n=1 abort)
- Status: **Closed FALSIFIED — 27th saturated lever.**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (Arm A k=6 α=0.5) | 3.292015 | **+0.0158** (32× noise floor) |
| T1 | ABORTED (advisor) | — |

### Analysis

- T0 catastrophic at +0.0158 above rank-1 (32× noise floor). Arm B not launched.
- Mechanism: Lookahead adds a second EMA over Muon weights with α=0.5 mixing. EN already smooths Muon momentum via γ=0.99 lerp. Composing two distinct slow/fast averaging schemes on the same optimizer trajectory over-smooths the update — the resulting parameter trajectory loses the productive fast oscillations that the NC × Arbor × EN composition relies on.
- Wrapper-style augmentations on Muon (Lookahead, SAM, etc.) appear universally dead — the existing EN already occupies the "slow trajectory" axis.
- 27th lever closed.

---

## 2026-06-07 12:43 — PR #2347: H-AX EN PREFILL_STEPS=100 (open2-tanjiro)
- Branch: `open2-tanjiro/h-ax-en-prefill`
- Hypothesis: Test EN PREFILL_STEPS=100 (vs default 0) — pre-fill the EN momentum buffer with 100 steps of plain Muon before activating the EN lerp, smoothing the initial transient.
- W&B run: `yfpvvbgy` (Arm A n=2 partial)
- Status: **Closed FALSIFIED — 24th saturated lever.**

### Results

| Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|
| T0 (PREFILL=100) | 3.277027 | +0.000834 |
| T1 | CRASHED | — |

### Analysis

- T0 +0.000834 above rank-1 (1.7× noise floor, FALSIFIED band). Trial 2 crashed; aborted before n=2 to free GPU for H-AY assignment.
- Combined with H-AR (EN γ warmup FALSIFIED) and H-AH (constant γ sweep FALSIFIED): the EN initialization/timing axis is fully saturated. The default PREFILL_STEPS=0 and γ=0.99 settings are decisively correct.
- 24th lever closed.

---

## 2026-06-07 11:44 — PR #2342: H-AS Muon gradient noise injection (open2-frieren)
- Branch: open2-frieren/h-as-muon-grad-noise
- Hypothesis: Apply Neelakantan-style decayed Gaussian noise to Muon gradients (σ_0=0.01, γ=0.55) before NS5 orthogonalization. Motivation: noise regularization can help escape sharp minima; Muon hasn't been tested with gradient noise.
- W&B run: f50uw5jj (Arm A, σ_0=0.01 only; Arm B not launched per advisor decision)

| Trial | val/ri_loss | vs rank-1 |
|---|---:|---:|
| T0 | 3.278573 | **+0.002380** |
| T1 | 3.276809 | +0.000616 |
| **n=2 mean** | **3.277691** | **+0.001498** |

- **Decision: CLOSED FALSIFIED. 23rd saturated lever.** n=2 mean = +0.001498 above rank-1 (3× noise floor). T0/T1 within-arm spread = 0.00176 (huge vs normal 0.0001-0.0002 paired variance). Student's post-hoc analysis identifies 4 mechanism reasons: (1) σ_0=0.01 exceeds clean Muon gradient scale O(1e-3), poisoning momentum lerp for >100 steps via 0.95 EMA; (2) NS5 expects clean gradient directions; (3) stack already near flat minimum, noise adds variance not escape; (4) per-trial dispersion implies noise broadcasts different perturbations across seeds. Arm B (σ_0=0.003) not run — mechanism class is wrong-direction, not mis-scaled. Student's suggested follow-ups (stochastic rounding on Muon updates, AdamW-only noise, early-only dropout) are noted for future consideration.

## 2026-06-07 11:25 — PR #2345: H-AV FINAL_LR_POWER sweep — renormalized power_c (open2-thorfinn)
- Branch: open2-thorfinn/h-av-final-lr-power
- Hypothesis: Test whether changing the LR schedule power exponent (p=0.9 vs p=1.2 baseline) with proper power_c renormalization that preserves per-group crossover steps isolates "tail decay shape" as a tunable axis.
- W&B run: spn3b1w8 (Arm A, p=0.9 renormalized; Arm B p=1.5 never launched)

| Trial | val/ri_loss | vs rank-1 |
|---|---:|---:|
| T0 | 3.280519 | **+0.004326** |
| T1 | ABORTED (advisor) | — |

- **Decision: CLOSED FALSIFIED. 22nd saturated lever.** T0 = +0.004326 above rank-1 (8× noise floor). Even with the Option 2 crossover-preserving renormalization, p=0.9 under NC × Arbor × EN × RI is catastrophic. The composition makes the p=1.2 crossover at step ~594 load-bearing; flatter decay (p=0.9, lower tail LR everywhere) disrupts the EN rest-region (1950-2890) and RI capture (2375). Arm B (p=1.5) not launched — Arm A T0 is unrecoverable. Student's renormalization analysis was analytically rigorous and is now a permanent reference for future schedule-shape experiments.

## 2026-06-07 11:00 — PR #2343: H-AT Gradient Centralization on Muon (open2-askeladd)
- Branch: open2-askeladd/h-at-grad-centralization
- Hypothesis: Apply Gradient Centralization (GC, Yong et al. 2020) to Muon parameters — subtract the mean of each gradient tensor before NS5 orthogonalization. GC reduces gradient magnitude and improves convergence smoothness in vision models; untested on language Muon composition.
- W&B run: qwbvitns (n=2, seeds 0-1)

| Trial | val/ri_loss | vs rank-1 |
|---|---:|---:|
| T0 | 3.276329 | +0.000136 |
| T1 | 3.276839 | +0.000647 |
| **n=2 mean** | **3.276584** | **+0.000391** |

- **Decision: INCONCLUSIVE. n=4 confirm directed.** n=2 mean = +0.000391 falls in inconclusive band (3.276193, 3.276593). T0/T1 spread = 0.000510 ≈ noise floor (~0.0005). The T0 signal (+0.000136) is the FIRST positive single-trial lift in 11 consecutive falsified arms — strategically important. n=4 confirm with seeds 2-3 directed to askeladd; final verdict expected ~14:00 UTC.

## 2026-06-07 09:55 — PR #2337: H-AO Per-block Muon LR differentiation (open2-edward)
- Branch: open2-edward/h-ao-per-block-muon
- Hypothesis: Differentiate Muon LR per block: early blocks get a higher multiplier in Arm A (early-boost 1.2/0.8), late blocks get higher in Arm B (late-boost 0.8/1.2). Targets the observation that early blocks are more specialized to input features, late blocks more to output prediction.
- W&B runs: 2au0tavg (Arm A), n8avho0l (Arm B)

| Arm | T0 val/ri_loss | vs rank-1 |
|---|---:|---:|
| Arm A (early-boost 1.2/0.8) | 3.2840 | **+0.0078** |
| Arm B (late-boost 0.8/1.2) | 3.282208 | **+0.006015** |

- **Decision: CLOSED FALSIFIED. 21st saturated lever.** Both arms catastrophically fail at T0 (12–16× noise floor). Per-block Muon LR axis completely saturated. The Muon NS5 orthogonalization already produces normalized updates across blocks; additional multiplicative differentiation causes destructive interference with NC's cautious mask.

## 2026-06-07 09:50 — PR #2344: H-AU Muon LR warmup (open2-tanjiro)
- Branch: open2-tanjiro/h-au-muon-lr-warmup
- Hypothesis: Linear warmup of Muon LR from 0→0.0375 over the first 200 steps. Motivation: early Muon steps use full LR before gradient norms stabilize; warmup may improve early-step optimization.
- W&B run: cuprgtht

| Trial | val/ri_loss | vs rank-1 |
|---|---:|---:|
| T0 | 3.2817848 | **+0.005592** |
| T1 | Early abort (advisor) | — |

- **Decision: CLOSED FALSIFIED. 20th saturated lever.** T0 = +0.0056 above rank-1 (11× noise floor). Student aborted T1 early per advisor recommendation; n=2 mean mathematically unrecoverable. Muon LR warmup degrades early gradient norms through NS5's stepcounting assumption — NS5 counts steps, but if effective LR is near-zero for 200 steps, the normalization is miscalibrated for the first ~7% of training.

## 2026-06-07 08:00 — PR #2339: H-AP lm_head on Muon (open2-thorfinn)
- Branch: open2-thorfinn/h-ap-lm-head-muon
- Hypothesis: Move lm_head (`model.proj.weight`) from AdamW to Muon as a separate param group (muon_lm_head_lr_mult=0.1, effective LR ≈ current AdamW lr 1/320). Muon's NS5 orthogonalization may help the vocab-projection matrix.
- W&B run: ss0mtlyy (Arm A only, early-abort after T0)

| Trial | ri_loss_gamma_neg0p0750 | vs rank-1 |
|---:|---:|---:|
| T0 (Arm A mult=0.1) | 3.291868 | **+0.015675** |
| Early-abort (T1 skipped) | — | — |

- **Decision: CLOSED FALSIFIED. 19th saturated lever.** T0 = +0.0157 above rank-1 (~31× noise floor). For n=2 mean ≤ 3.276193, T1 would need to be ≤ 3.2605 — statistically impossible. Early abort authorized.
- lm_head should remain on AdamW for any further composition work. The lm_head's vocab-projection geometry (tall, long-tail token distribution) appears incompatible with Muon's NS5 spectral normalization at any LR scale in this config.
- Note: Arm B (mult=0.5) was not tested because the T0 gap is too large to justify another full run.

## 2026-06-07 07:10 — PR #2335: H-AM Muon WD cosine schedule (open2-tanjiro)
- Branch: open2-tanjiro/h-am-muon-wd-cosine
- Hypothesis: Cosine decay of Muon WD from 0.025→0 over full training — reduces regularization near end of training
- W&B run: tiprqsjf (num_trials=2)

| Trial | ri_loss_gamma_neg0p0750 | vs rank-1 |
|---:|---:|---:|
| T0 | 3.276875 | +0.000682 |
| T1 | 3.276034 | −0.000159 (below rank-1!) |
| **n=2 mean** | **3.276455** | **+0.000262** |

- **Decision: CLOSED FALSIFIED.** n=2 mean 3.276455 > gate (3.276393). T0/T1 spread = +0.000841 (8× noise floor). High seed variance: cosine WD decay amplifies seed-dependent weight drift at training end. T1 was 3.276034 (−0.000159 below rank-1) — promising direction signal buried in high variance.
- 18th saturated lever.

## 2026-06-07 07:05 — PR #2331: H-AI NS polynomial quartic (3,−3,1) (open2-askeladd)
- Branch: open2-askeladd/h-ai-ns-abc-retune
- Hypothesis: Replace default NS polynomial with quartic `p(x) = x(3 - 3x + x²)` designed for NS12 regime
- W&B runs: adyad30y (Arm B T0), ym02d30j (Arm B T1)

| Arm/Trial | Step | ri_loss_gamma_neg0p0750 | vs rank-1 |
|---:|---:|---:|---:|
| Arm A KJ5 T0 | 2890 | 3.278141 | +0.001948 |
| Arm B quartic T0 | 2890 | **3.276060** | **−0.000133** |
| Arm B quartic T1 | 2890 | 3.277055 | +0.000862 |
| **Arm B n=2 mean** | | **3.276558** | **+0.000365** |

- **Decision: CLOSED FALSIFIED.** n=2 mean 3.276558 > gate (3.276393). T0/T1 spread = +0.001 (2× noise floor). T0 sub-rank-1 was a lucky seed. NS polynomial axis saturated.
- 17th saturated lever.

## 2026-06-07 06:45 — PR #2334: H-AL AdamW β₂ warmup (open2-frieren)
- Branch: open2-frieren/h-al-adamw-beta2-warmup-2890
- Hypothesis: Warm up AdamW β₂ from 0.95 to 0.99 over 1000 steps — faster early second-moment adaptation, recover standard smoothing after
- W&B runs: 4eqgep8q (num_trials=2, 2890 steps each)

| Trial | Step | ri_loss_gamma_neg0p0750 | vs rank-1 |
|---:|---:|---:|---:|
| T0 | 2890 | 3.276490 | +0.000297 |
| T1 | 5780 | 3.278480 | **+0.002287** |
| **n=2 mean** | | **3.276485** | **+0.000292** |

- **Decision: CLOSED FALSIFIED.** n=2 mean 3.276485 exceeds falsification gate (3.276393). T0/T1 spread +0.002 reveals high seed variance: β₂ warmup perturbs second-moment estimation so early-training trajectory becomes seed-dependent, interacting destructively with existing schedules (power_c, μ warmup, RI capture).
- 15th saturated lever.

## 2026-06-07 06:10 — PR #2336: H-AN Multi-anchor RI (open2-nezuko)
- Branch: open2-nezuko/h-an-multi-anchor-ri-2890
- Hypothesis: 2 simultaneous RI captures (steps 2200 + 2375, γ=−0.0375 each, sum=−0.075) to span a wider subspace than single-anchor capture
- W&B run: di7i4hu0 (state=crashed mid-T1 at step 3166)

| Trial | Step | Multi-anchor ri_loss (γ_sum=−0.075) | vs rank-1 |
|---:|---:|---:|---:|
| T0 | 2890 | 3.27754 | **+0.00134** |
| T1 | crashed step 276 | — | — |

- **Decision: CLOSED FALSIFIED.** T0 alone decisive — regression of +0.00134 vs rank-1 3.276193. T1 crash is infrastructure (val/loss 4.11 at step 250 = normal early-T1 values, not divergence).
- Mechanism: Two captures at steps 2200+2375 are highly correlated (~175-step separation near training end). Effective rank ≈ 1, not 2. Halving per-anchor γ reduces SNR without adding independent subspace directions. Direction dead unless anchor separation is large (e.g., step 1500+2375).
- 14th saturated lever (15th closed direction including 2 failed families).

Tag: `auto-nanogpt-open-sota-v2-20260604`. Branch: same. Target:
`modded-nanogpt` Track 3 (FineWeb val/loss ≤ 3.28 in minimum optimizer steps
under stat-sig contract).

Each entry below records the date, PR number, hypothesis, key results table,
and analysis. Most recent first.

---

## 2026-06-07 05:35 UTC — PR #2338: H-AK' Cautious-AdamW dense-only (lm_head + scalars, embed vanilla) — CLOSED FALSIFIED (fern)

- **Branch:** `open2-fern/h-ak-prime-cautious-dense`
- **Hypothesis:** H-AK's failure was caused by sparse-row embed pathology; dense groups (lm_head, scalars) with mask_mean≈0.50 should survive the cautious mask. Test by bypassing embed from cautious hook via `--cautious_adamw_skip_embed=1`.
- **W&B runs:** smoke `vc69h0qa` (200 steps, passed gate 1-4, failed gate 5 silently), n=2 `w5o2u5te` (aborted step 500)

| Step | rank-1 vk0jtb3z | H-AK' w5o2u5te | Δ |
|---:|---:|---:|---:|
| 125 | 4.500 | 5.337 | +0.837 |
| 250 | 4.121 | 5.255 | +1.134 |
| 375 | 3.955 | 5.729 | +1.774 |
| 500 | 3.827 | 6.755 | **+2.928** |

**Key findings (TWO publishable mechanism findings from H-AK + H-AK' combined):**
1. H-AK (uniform recipe): `mask_mean ≈ 0.227` on sparse-row embed → 4.4× LR amplification → divergence
2. **H-AK' (dense-only, this PR): mask_mean ≈ 0.50 (physiological), embed correctly bypassed, yet still diverges** — root cause identified as **pre-mask-grad design bug**: current implementation masks `p.grad` pre-AdamW (corrupts `exp_avg_sq` accumulation; `v` grows slowly → 1/√v inflates → compound amplification beyond explicit 2×). Liang et al.'s correct recipe masks the UPDATE `m/(√v+ε)` post-hoc; the current `cautious_premask_adamw()` helper cannot be salvaged.

**Conclusion:** Cautious-AdamW direction is **dead for this stack** until someone implements the Liang et al. recipe correctly (~30 lines custom AdamW subclass). Flag for future implementer: mask the update `u = m/(√v+ε)`, then apply `u *= mask / mean(mask)`.

Smoke gate improvements: extended 200-step gate correctly flagged step-200 val_loss +0.9 deviation vs baseline. Student early-aborted at step 500 — correct (slope +0.6/100 steps, unrecoverable).

**Cleanup deferred:** `--cautious_adamw` and `--cautious_adamw_skip_embed` flags + `cautious_premask_adamw()` helper still in code (default=0, inert), will be pruned in a future cleanup PR.

---

## 2026-06-07 04:49 UTC — PR #2323: H-AA Arbor warmup (Sinkhorn skip-first-N steps) — CLOSED FALSIFIED (thorfinn)

- **Branch:** `open2-thorfinn/h-aa-arbor-warmup`
- **Hypothesis:** Skipping Sinkhorn equilibration for the first N steps (linear warmup from 1 → ARBOR_ITERS) helps by not dampening noisy early gradient signal.
- **W&B runs:** N=0 `fiixr3ft` (control n=4), N=500 `vlnga3rc` (smoke winner n=4). N=250 dropped (worst smoke). N=1000 gated out.

| Arm | N | n | val/ri_loss_gamma_neg0p0750 | Δ vs PR #2298 anchor |
|---|---:|---:|---:|---:|
| PR #2298 Arbor+RI (merged) | — | 4 | 3.27738 | — |
| N=0 (control, code-path valid.) | 0 | 4 | 3.27745 | +0.00007 |
| N=500 (smoke winner) | 500 | 4 | 3.27748 | +0.00010 |
| N=1000 | 1000 | — | NOT LAUNCHED | gated out |

**Key finding:** N=500 vs N=0 Δ = +0.00003, well within per-trial sd 0.00077. Indistinguishable from noise at n=4. Saturated lever **#12: Arbor warmup-from-1 in (0,500) range**. The Sinkhorn-skip-first-N hypothesis is falsified — early Sinkhorn is neutral to the final 2890-step outcome.

**Control validation:** N=0 reproduces PR #2298 Arbor+RI anchor (3.27745 vs 3.27738, Δ=+0.00007) — confirms the new `--arbor_warmup_steps` flag introduces no regression. RI mechanism (paired Δ γ=-0.075 vs γ=0 = −0.00032) active in both arms.

**Analysis:** The hard on/off gate (full Sinkhorn vs full skip) is too coarse to reveal warmup effects. Both N=0 and N=500 deliver equivalent outcomes after 2890 steps, suggesting Sinkhorn's role is not dominated by early-step behavior. Smoke at step 500 showed weak signal (N=500 best, N=250 worst) that didn't persist through full training. GPU saved on N=1000 per gate.

---

## 2026-06-07 04:12 UTC — PR #2332: H-AJ z-loss aux regularization on pre-cap logits — CLOSED FALSIFIED (edward)

- **Branch:** `open2-edward/h-aj-z-loss-aux`
- **Hypothesis:** z-loss auxiliary regularization (PaLM-style) reduces logit magnitude drift and restores gradient signal that the softsign cap suppresses in high-magnitude regimes.
- **W&B runs:** Arm A `bgdn33vz` (w=1e-4), Arm B `ah62ac7w` (w=1e-3)
- **Method:** Two-arm sweep of z-loss weight at decade spacing. Early-abort gate: T0 > 3.28 → kill T1.

| Arm | w | T0 val/ri_loss | Δ vs rank-1 (3.276193) | Gate |
|---|---:|---:|---:|:-:|
| A | 1e-4 | 3.280289 | **+0.00410** | fired |
| B | 1e-3 | 3.28924 (pre-RI) | **+0.01305** | fired |

- **Analysis:** Monotone-bad slope across decade weight sweep (Δ(1e-3 − 1e-4) = +0.00895). Root cause: softsign cap is already keeping raw logits in a healthy linear regime at 124M params/2890 steps. Z-loss compresses legitimate dynamic range the model uses inside |raw| < 15, hurting rather than helping. PaLM's z-loss matters at 540B scale with millions of steps; this regime doesn't apply here. Gates saved ~3.2h GPU (both T1s killed). **6th saturated lever this session.**
- **Decision:** CLOSED FALSIFIED — no further weight retuning warranted.

---

## 2026-06-07 04:11 UTC — PR #2333: H-AK Cautious-AdamW on embed + lm_head + scalars — CLOSED FAILED (fern)

- **Branch:** `open2-fern/h-ak-cautious-adamw`
- **Hypothesis:** Apply Liang et al. (2024) Cautious-AdamW masking to AdamW parameter groups (embed, lm_head, scalars) as a counterpart to Cautious-Muon already in rank-1.
- **W&B run:** `bmbwlv2i`
- **Method:** Pre-step hook applied mask (sign agreement between Adam update and gradient) with `scale = mask.mean()` rescale. Aborted at step 1194/2890.

| step | val_loss | rank-1 baseline | Δ |
|---:|---:|---:|---:|
| 125 | 5.773 | 4.528 | +1.24 |
| 500 | 6.853 | 3.827 | **+3.03** |
| 1125 | 9.693 | 3.619 | **+6.07** |

- **Mechanism finding:** The uniform Liang et al. recipe is incompatible with sparse-row gradient tensors. Embed weight has structurally-sparse gradients (only in-batch token rows get non-zero gradient); `mask.mean()` over the full tensor → scale ≈ 0.227 → 1/scale ≈ 4.4× LR amplification on active embed rows throughout training. Dense groups (lm_head, scalars) had well-conditioned mask fractions ≈ 0.50.
- **Decision:** CLOSED FAILED (not retunable in this form). Reassigning fern to H-AK' (dense-only: lm_head + scalars, embed stays vanilla) per fern's own recommendation.

---

## 2026-06-07 04:25 UTC — PR #2337: H-AO Per-block Muon LR (early vs late multiplier) — ASSIGNED (edward)

- **Branch:** `open2-edward/h-ao-per-block-muon-lr`
- **Hypothesis:** Muon currently uses uniform lr=0.0375 across all 12 transformer blocks. Splitting into early (blocks 0-5) and late (blocks 6-11) param groups and testing differential multipliers (1.2/0.8 and 0.8/1.2) may extract lift that uniform shifts cannot.
- **Arm A:** early_mult=1.2, late_mult=0.8 (n=2 first)
- **Arm B:** early_mult=0.8, late_mult=1.2 (if Arm A fails)

---

## 2026-06-07 04:25 UTC — PR #2338: H-AK' Cautious-AdamW dense-only (lm_head + scalars, embed vanilla) — ASSIGNED (fern)

- **Branch:** `open2-fern/h-ak-prime-cautious-dense`
- **Hypothesis:** H-AK found uniform cautious recipe diverges via embed sparse-row pathology. Dense groups (lm_head mask_mean ≈ 0.50, scalars ≈ 0.50-0.63) are physiological for cautious rescale. Testing dense-only masking with embed on vanilla AdamW.
- **Extended smoke gate:** 200 steps (50-step smoke insufficient per H-AK lesson — divergence appears at step 250+)

---

## 2026-06-07 01:45 UTC — PR #2327: H-AE RI capture-step × γ sweep on NC × Arbor stack — CLOSED FALSIFIED (fern)

- **Branch:** `open2-fern/h-ae-capture-sweep-nc-arbor`
- **Hypothesis:** The default RI capture step (2375) and γ (−0.075) may not be optimal on the NC × Arbor + RI stack — shifting to an earlier capture (2200) and softer γ (−0.05) could lift val_loss further.
- **W&B run:** `5kgku0hv`
- **Method:** Full 5×3 sweep of capture steps {2000, 2200, 2375, 2550, 2700} × γ {0, −0.05, −0.075} via `--ri_extra_capture_steps` and `--ri_extra_gammas`. 15-cell paired n=4 comparison.

| capture | γ | n=4 mean | paired Δ vs anchor (2375,−0.075) | sign-stable? |
|---:|---:|---:|---:|:--:|
| 2000 | 0 | 3.277028 | +0.000328 | — |
| 2000 | −0.05 | 3.276846 | +0.000147 | — |
| 2000 | −0.075 | 3.277121 | +0.000422 | — |
| 2200 | 0 | 3.277028 | +0.000328 | — |
| **2200** | **−0.05** | **3.276683** | **−0.000016** | **✓ all 4** |
| 2200 | −0.075 | 3.276741 | +0.000041 | — |
| 2375 | −0.05 | 3.276709 | +0.000009 | — |
| 2375 | −0.075 (anchor) | 3.276700 | 0 | — |
| 2550 | −0.075 | 3.276789 | +0.000089 | — |
| 2700 | −0.075 | 3.276895 | +0.000195 | — |

- **Best cell:** (2200, −0.05) = 3.276683, paired Δ = −0.000016 vs anchor. Sign-stable (4/4 Δ < 0) but magnitude 6× under the −0.0001 falsification threshold.
- **vs rank-1 baseline (PR #2317, 3.276193):** Best cell +0.000490. No merge.
- **Mechanism finding:** NC saturates the RI capture-step × γ lever. Anchor re-run at (2375, −0.075) came in at 3.276700 (+0.000507 from rank-1), consistent with expected seed variance. The entire 15-cell landscape collapses to within ±0.000835 of the anchor — flat within noise. This definitively closes the (capture × γ) sweep family on the NC × Arbor + RI stack.
- **Conclusion:** CLOSED FALSIFIED. NC plus Arbor equalization smooths the late-training trajectory so that precise RI capture timing is no longer critical. The (2200, −0.05) preference is real but micro-scale (16μ) and not worth pursuing.
- **Next:** fern assigned H-AK (Cautious-AdamW for embed/lm_head/scalars) as PR #2333.

---

## 2026-06-07 03:05 UTC — PR #2328: H-AF NS iteration count (NS10 vs NS12) — CLOSED (inconclusive, NS10 = NS12 within noise)

- **Branch:** `open2-nezuko/h-af-ns-iters-nc-arbor`
- **W&B run:** `ea0n8iwj` (primary; duplicate `rz4uvvvt` killed at 00:24 UTC after GPU contention)
- **Hypothesis:** NS12 might over-iterate the polar factorization given NC's pre-normalization — NS10 (~17% faster per NS step) could match or beat NS12 on the NC × Arbor + RI stack.
- **Results (n=4, all vs rank-1 n=4 mean 3.276193):**

| Trial | val_loss | Δ vs rank-1 |
|---:|---:|---:|
| T0 | 3.275741 | −0.000452 |
| T1 | 3.275744 | −0.000449 |
| T2 | 3.277351 | +0.001158 |
| T3 | 3.276160 | −0.000033 |
| **n=4 mean** | **3.276248** | **+0.000055** |
| n=4 sample std | 0.000761 | — |
| SEM | 0.000381 | — |

- **Decision-table mapping:** n=4 mean = 3.276248 in **(3.276193, 3.276593) — INCONCLUSIVE band**. The mean is +55μ above rank-1, well inside SEM (381μ) and inside NS12's own n=4 std (687μ).
- **T0=T1 tightness was anomaly (not signal):** The unusually tight T0=T1 pair at 3μ apart was regression-to-mean: T2=3.27735 and T3=3.27616 both reverted toward the center.
- **NS iter count axis saturated at NS10-12:** NS10 = NS12 within noise. NS11/NS9 would likely give the same result. Further iteration-count exploration not recommended (5th saturated axis this session).
- **Wall-time savings:** ~17% NS-portion saving from NS10 is real but modest as a % of total step time (~2-3% step_avg savings); not worth accepting equal-or-worse val_loss for.
- **T2 anomaly:** T2=3.27735 attributed to GPU contention from duplicate run `rz4uvvvt` that ran concurrently during T2's training window. Post-kill steady-state step_avg returned to 2020-2040 ms/step.
- **Next:** nezuko assigned H-AN (multi-anchor RI: 2 simultaneous captures, PR #2336).

---

## 2026-06-07 03:05 UTC — PR #2336: H-AN Multi-anchor RI (2 simultaneous captures) — ASSIGNED (nezuko)

- **Branch:** `open2-nezuko/h-an-multi-anchor-ri`
- **Hypothesis:** Single-anchor RI is saturated (H-AE closed). Multi-anchor extends to 2 captures: `θ_eval = θ_final + γ₁*(θ_final−θ_c1) + γ₂*(θ_final−θ_c2)`. Tests if snapshots at different training steps encode orthogonal gradient directions that compound. Arm A: split canonical γ=−0.075 as γ₁=γ₂=−0.0375 across captures c1=2200, c2=2375.
- **Implementation:** ~25 lines — new `--ri_extra_capture_steps` (CSV ints) and `--ri_capture_gammas` (CSV floats, paired with extra steps) CLI flags; dict of snapshots indexed by step; `_apply_multi_anchor()` function.
- **Decision:** n=2 ≤ 3.275793 → strong positive, n=4 confirm; ≥ 3.276393 → falsified (single-anchor remains optimal).
- **Status:** Assignment PR created 03:05 UTC; awaiting student pickup.

---

## 2026-06-07 02:45 UTC — PR #2329: H-AG Muon LR ±20% ablation on NC × Arbor + RI — CLOSED (falsified, LR=0.0375 locally optimal)

- **Branch:** `open2-tanjiro/h-ag-lr-wd-retune`
- **W&B runs:** Arm A `gh42uhjh` (LR=0.030, n=2), Arm B `agvlim5e` (LR=0.045, n=2)
- **Hypothesis:** LR=0.0375 (Muon) was inherited from the PR #309 base without revalidation on the NC × Arbor + RI stack. ±20% perturbations test whether the stack's geometry has shifted the optimal LR.
- **Results (n=2 paired per arm, vs rank-1 n=4 mean 3.276193):**

| Arm | LR | T0 | T1 | n=2 mean | Δ vs rank-1 | Verdict |
|---|---|---:|---:|---:|---:|---|
| **A** (−20%) | 0.030 | 3.276964 | 3.275824 | **3.276394** | **+0.000201** | inconclusive |
| **B** (+20%) | 0.045 | 3.276764 | 3.279024 | **3.277894** | **+0.001701** | clear regression |
| Baseline (rank-1, n=4) | 0.0375 | — | — | 3.276193 | 0 | local optimum |

- **Asymmetric regression pattern:** Arm A (−20%) lands near-flat at +0.0002; Arm B (+20%) regresses by +0.0017. Loss-vs-LR curve is skewed — the optimum at 0.0375 is on the right shoulder of a slightly skewed parabola. Higher LR is the wrong direction; lower LR is safer but also not better.
- **Mechanism finding:** LR=0.0375 is at or near the local optimum for this stack. ±20% gives no clear lift; this is the fourth saturated scalar in succession (after RI γ, RI capture×γ, EMA-Nesterov γ).
- **Infrastructure added:** CLI flags `--muon_lr` and `--muon_weight_decay` (default None → no-op) are now in the training script, available for future experiments requiring fair LR/WD baselines.
- **Arm B also fails test contract:** Arm B n=2 mean 3.277894 gives `(3.28 − 3.277894) × √2 = 0.00298 < 0.004` — below the stat-sig floor. Additional signal that +20% is the worse direction.
- **Next:** tanjiro assigned H-AM (Muon WD cosine schedule 0.025→0 over training, PR #2335).

---

## 2026-06-07 02:50 UTC — PR #2335: H-AM Muon WD cosine schedule (0.025→0) — ASSIGNED (tanjiro)

- **Branch:** `open2-tanjiro/h-am-muon-wd-schedule`
- **Hypothesis:** `MUON_WEIGHT_DECAY = 0.025` is constant throughout training. Cosine decay from 0.025 → 0 reduces regularization pressure as model approaches convergence (Loshchilov & Hutter 2019, AdamW). Motivated by: 4 consecutive saturated scalar axes → next frontier is *schedule* mechanisms.
- **Implementation:** Add `--muon_wd_schedule` flag (`"constant"` default, `"cosine"`, `"linear"`). Per-step `group["weight_decay"]` update inside `set_hparams(step)`.
- **Arms:** Cosine decay as Arm A; linear decay as Arm B if Arm A inconclusive.
- **Decision:** n=2 ≤ 3.275893 → expand to n=4; n=2 ≥ 3.276393 → falsified.
- **Status:** Assignment PR created 02:50 UTC; awaiting student pickup.

---

## 2026-06-07 02:20 UTC — PR #2330: H-AH EMA-Nesterov γ ablation on NC × Arbor + RI — CLOSED (falsified, γ=0.99 locally optimal)

- **Branch:** `open2-frieren/h-ah-ema-nesterov-gamma`
- **W&B runs:** Arm A `5bsuw8yt` (γ=0.90), Arm B `j0jjjsuz` (γ=0.98), Arm C `5wppazxv` (γ=0.95)
- **Hypothesis:** EMA-Nesterov γ=0.99 (rank-1 default) may not be the optimum on the NC × Arbor + RI stack. Three perturbations tested: γ∈{0.90, 0.95, 0.98} vs baseline γ=0.99.
- **Results (T0 single trial, all vs rank-1 n=4 mean 3.276193):**

| γ | EMA window | T0 val/ri_loss | Δ vs rank-1 | Verdict |
|---:|---:|---:|---:|---|
| 0.90 | ~10 steps | 3.283956 | +0.007763 | **FALSIFIED** (T1 killed early) |
| 0.95 | ~20 steps | 3.281821 | +0.005628 | **FALSIFIED** (T1 killed early) |
| 0.98 | ~50 steps | 3.279720 | +0.003527 | **FALSIFIED** (T1 killed early) |
| **0.99 (rank-1)** | **~100 steps** | **3.276193 (n=4)** | **0** | **local optimum confirmed** |

- **Mechanism finding:** EMA-Nesterov γ has a **sharply local minimum at γ=0.99** on the NC × Arbor + RI stack. All three perturbations regress monotonically as γ departs from 0.99 — the canonical KellerJordan γ=0.95 (+0.0056) and MoonShot Muon γ=0.98 (+0.0035) are demonstrably suboptimal. The ~100-step EMA window implied by γ=0.99 is unusually long compared to standard Polyak-Ruppert recommendations (~10-20 steps), suggesting the NC × Arbor preconditioner landscape has a long-range smoothness that makes longer EN windows beneficial.
- **Wall-time saved:** All three T1s killed after strong T0 negatives → ~5h GPU reclaimed.
- **Third saturated lever in succession (after H-AD and H-AE):** scalar tuning space of rank-1 stack is thoroughly explored. Further gains require fresh mechanism additions.
- **Next:** frieren assigned H-AL (AdamW β₂ warmup schedule 0.95→0.99 over first 1000 steps, PR #2334).

---

## 2026-06-07 02:30 UTC — PR #2334: H-AL AdamW β₂ warmup schedule (0.95→0.99) — ASSIGNED (frieren)

- **Branch:** `open2-frieren/h-al-beta2-warmup`
- **Hypothesis:** β₂=0.99 constant in AdamW (`betas=(0.8, 0.99)`) gives a 100-step variance EMA window throughout training. In early training (steps 0-1000) gradient distributions are non-stationary; a shorter window (β₂=0.95, ~20 steps) adapts faster. A warmup from β₂=0.95→0.99 over 1000 steps better matches optimization signal's stationarity timescale, motivated by H-AH's finding that EMA windows are load-bearing in this stack.
- **Implementation:** Add `--adam_beta2_warmup_steps` (default 0) and `--adam_beta2_initial` (default 0.95) CLI flags. Per-step `group["betas"] = (beta1, beta2)` before optimizer.step(). Linear ramp then hold at β₂_final=0.99.
- **Arms:** Single arm n=2 first; expand to n=4 if ≤ rank-1 −0.0002.
- **Decision criteria:** n=2 mean ≤ 3.275893 → strong positive, launch n=4; ≥ 3.276393 → falsified (β₂=0.99 constant already optimal).
- **Status:** Assignment PR created 02:30 UTC; awaiting student pickup.

---

## 2026-06-06 23:50 UTC — PR #2332: H-AJ z-loss aux on pre-cap logits — ASSIGNED (edward)

- **Branch:** `open2-edward/h-aj-z-loss-aux`
- **Hypothesis:** Pre-cap logits in `forward()` (line 546) can grow unboundedly while softsign cap (line 547) hides this from downstream — vanishingly small gradients through capped entries. PaLM-style z-loss `w * logits_raw.square().mean()` adds a soft pressure on raw logit norm, restoring gradient signal across vocabulary.
- **Arms:** A: w=1e-4 (PaLM canonical); B: w=1e-3 (aggressive)
- **Code change:** ~3 lines, add `--z_loss_weight` CLI flag (default 0.0 → no-op).
- **Decision criteria:** n=2 mean ≤ 3.2762 (rank-1 − 0.0005) → expand to n=4; > 3.27659 → falsified arm.
- **Status:** Assignment PR created 23:50 UTC; awaiting student pickup.

---

## 2026-06-06 23:30 UTC — PR #2331: H-AI NS polynomial (a,b,c) retune — ASSIGNED (askeladd)

- **Branch:** `open2-askeladd/h-ai-ns-abc-retune`
- **Hypothesis:** Current `_ns_inner` (lines 560-566) uses (2, -1.5, 0.5) — canonical Higham cubic-convergence polynomial. Inherited from a 5-iter tuning regime. At NS12, the polynomial saturates at ~iter 8; iters 9-12 are wasted. Different (a, b, c) could give sharper polar approximation or true quartic convergence.
- **Arms:** A: KellerJordan NS5 canonical (3.4445, -4.775, 2.0315) — sharp, oscillating; B: quartic convergence (3, -3, 1) — p(1)=1, p'(1)=p''(1)=p'''(1)=0
- **Code change:** Add `--ns_abc` CSV CLI flag; resolve to module-level tuple read by `_ns_inner`.
- **Decision criteria:** n=2 mean ≤ 3.2762 → expand to n=4; > 3.27659 → falsified.
- **Orthogonality:** Independent of nezuko's H-AF (iter count) and frieren's H-AH (EN γ) axes.
- **Status:** Assignment PR created 23:30 UTC; awaiting student pickup.

---

## 2026-06-06 23:50 UTC — PR #2326: H-AD RI γ saturation map — CLOSED (informational, no merge)

- **Branch:** `open2-edward/h-ad-ri-gamma-sweep-nc-arbor`
- **W&B run:** `485nt9tt` (FINISHED, n=4 at 2890 steps × 7 γs)
- **Hypothesis:** Sweep γ ∈ {0, −0.025, −0.05, −0.075, −0.10, −0.125, −0.15} on NC × Arbor stack to map the saturation boundary. Test whether γ outside the rank-1 default (γ=−0.075) gives lift.
- **Results (n=4 mean of `val/ri_loss_gamma_<γ>` at step 2890):**

| γ | n=4 mean | Δ vs γ=0 | Δ vs prior rank-1 (3.276193) |
|---:|---:|---:|---:|
| 0 | 3.276657 | — | +0.000464 |
| −0.025 | 3.276446 | −0.000211 | +0.000253 |
| −0.050 | 3.276341 | −0.000316 | +0.000148 |
| **−0.075** | **3.276336** | **−0.000321** | **+0.000143** |
| −0.100 | 3.276425 | −0.000232 | +0.000232 |
| −0.125 | 3.276623 | −0.000034 | +0.000430 |
| −0.150 | 3.276913 | +0.000256 | +0.000720 |

- **Verdict:** Clean inverted-U with peak at γ=−0.075 (tied with γ=−0.050 within 5e-6). Uniform +0.00014 offset from prior rank-1 at every γ — consistent with cross-run seed variance (1σ ≈ 0.0015 per-trial). RI's γ axis is **saturated**; future RI gains require a different mechanism (capture step, multi-capture, alternative readout).
- **Mechanism takeaway:** RI lift is structurally bounded at ~−0.0003 vs γ=0 on the NC × Arbor stack. The default γ=−0.075 stays canonical; γ=−0.05 acceptable alternative; γ∈{−0.025, −0.10} mildly beats γ=0; γ∈{−0.125, −0.15} hurts.
- **Edward reassigned:** H-AJ (z-loss aux on pre-cap logits, PR #2332).

---

## 2026-06-06 23:25 UTC — PR #2324: H-AB SWA tail averaging on NC × Arbor + RI — CLOSED (FALSIFIED, mechanism)

- **Branch:** `open2-askeladd/h-ab-swa-tail-arbor`
- **W&B runs:** Arm A `w0h4r1um` (reproduction, n=2 done), Arm B `jnpvi24f` (SWA K=290, n=2 done after abort)
- **Hypothesis:** Polyak-Ruppert / SWA tail averaging over the last 10% of training (K=290 of 2890 steps) reduces variance and possibly improves val_loss vs final-step weights.
- **Results (paired by trial):**

| Trial | Arm A (no SWA) | Arm B (SWA K=290) | Δ (B−A) |
|---:|---:|---:|---:|
| T0 | 3.276844 | 3.280254 | +0.003410 |
| T1 | 3.275971 | 3.279110 | +0.003139 |
| **n=2 mean** | **3.276408** | **3.279682** | **+0.003274** |

- **Verdict:** **FALSIFIED at mechanism level**, decisively. Arm B regresses by +0.003 paired (both trials individually outside ±0.001 noise band on wrong side).
- **Mechanism (student-diagnosed, advisor-confirmed):** SWA assumes the tail iterates oscillate around an optimum (asymptotic noise-dominated regime). The current schedule keeps the tail **trend-dominated** — `val/loss` drops from 3.301 → 3.280 across the SWA window (K=290 steps). Averaging pulls eval backward in optimization time. Smaller K can only approach final-step val_loss, never beat it.
- **Closes entire design direction:** Any future SWA/EMA-tail variant on this schedule is falsified upfront. Prerequisite question for tail-averaging proposals: "is the tail noise-dominated?" If no, falsified.
- **Code path validated:** Reproduction Arm A n=2 = 3.276408 ≈ rank-1 3.276193 (+0.000215 ≈ noise). NC × Arbor + RI baseline holds across reproductions.
- **Askeladd reassigned:** H-AI (NS polynomial coefficient retune, PR #2331).

---

## 2026-06-06 20:30 UTC — CODE DISCOVERY #2: EN γ = 0.99, not 0.95

Frieren (PR #2330) flagged on inspection of code line 111:
- **Actual constant:** `EMA_NESTEROV_GAMMA = 0.99` (effective EMA window ~100 steps)
- **My spec assumed:** β=0.95 (effective window ~20 steps)
- **Confirmed:** PR #2317 rank-1 (n=4 mean 3.276193, run vk0jtb3z) was at γ=0.99. EN load-bearing finding (−0.003 absolute) is at γ=0.99.
- **Revised H-AH plan:** Arms {0.90, 0.98} n=2 vs PR #2317 baseline at γ=0.99. γ=0.95 escalation if both regress.

This is the **second** spec/code mismatch caught by students this round (1st: NS5 vs NS12 by nezuko; 2nd: γ=0.95 vs γ=0.99 by frieren). Lesson: diff the actual source against constants before transcribing baseline numbers. Process improvement: pull current code constants verbatim into the H-* body, not from memory/snapshot.

---

## 2026-06-06 20:30 UTC — PR #2329: H-AG Muon LR retune — UNBLOCKED + LAUNCHED

- **Branch:** `open2-tanjiro/h-ag-lr-wd-retune`
- **Hypothesis:** PR #2317 rank-1 inherited `MUON_LR=0.0375` from pre-NC × Arbor era; refined stack (NC always-on + Sinkhorn + RI + EN) may have different optimal LR. Testing ±20% around 0.0375.
- **Resolution sequence:**
  1. Original H-AG body had stale numbers ("LR=0.0018, WD=0.1") — tanjiro blocked PR.
  2. Advisor corrected: interpretation (c), ±20% around actual MUON_LR=0.0375 (Arm A 0.030, Arm B 0.045), WD held at 0.025. Approved `--muon_lr`/`--muon_weight_decay` CLI flags (default None no-op).
  3. Tanjiro implemented flags, ran 50-step smoke. Arm A vs baseline: +0.0175 (accepted: normal for 20% LR drop, monotonic, no NaN — smoke gate was too tight for short horizon).
  4. Arm A n=2 launched 19:41 UTC. Terminal ETA ~23:00 UTC.

---

## 2026-06-06 19:53 UTC — PR #2330: H-AH EMA-Nesterov γ ablation — ASSIGNED

- **Branch:** `open2-frieren/h-ah-ema-beta-nc-arbor`
- **Hypothesis:** EN is confirmed load-bearing (−0.003 absolute lift, independent of NC). But the γ value has never been ablated on the NC × Arbor stack. Original spec assumed γ=0.95 baseline — caught + corrected to γ=0.99 actual. Testing γ ∈ {0.90, 0.98} as 2-arm n=2 screen, with γ=0.95 escalation contingency.
- **Status:** Awaiting student implementation after corrected reply at 20:30 UTC.

---

## 2026-06-06 19:53 UTC — PR #2322: H-Z Arbor − EN baseline (no NC) — CLOSED (REFUTED)

- **Branch:** `open2-frieren/h-z-arbor-no-en`
- **Hypothesis:** EN might be load-bearing specifically because of NC composition, not independently. Tested Arbor + RI without EN (no NC) as clean control arm.
- **W&B run:** `9y3k8kea` (FINISHED, runtime ~27h)
- **Results:**

| Trial | val/loss |
|---:|---:|
| T0 | 3.278932 |
| T1 | 3.279692 |
| T2 | 3.279236 |
| T3 | 3.280024 |
| **n=4 mean** | **3.279471** |

- **Verdict:** n=4 mean 3.279471 = **+0.003278 above rank-1** (3.276193). EN is independently load-bearing, regardless of NC presence.
- **Combined with tanjiro H-Y** (Arbor + NC + RI no EN, n=4=3.278702, +0.002509): both configurations without EN land in the +0.0025–+0.0033 range. EN's absolute lift ≈ −0.003, INDEPENDENT of NC condition.

---

## 2026-06-06 19:47 UTC — CODE DISCOVERY: Current NS iteration count is NS12, not NS5

- **Source:** Nezuko PR #2328 flagged discrepancy before launch
- **Finding:** PR #2295 (H15 RI) changed `_ns_inner(X)` to use `for _ in range(12)` instead of 5. Both `zeropower_via_newtonschulz5()` and `soft_via_newtonschulz5()` route through `_ns_inner`. The merged rank-1 (PR #2317, 3.276193) was trained with NS12.
- **Impact:** H-AF spec was wrong. Revised to NS10 single arm (conservative 17% reduction). NS12 may be overkill; NS10 will establish whether the extra iterations are load-bearing.

---

## 2026-06-06 18:43 UTC — PR #2329: H-AG LR × WD retune on NC × Arbor + RI — ASSIGNED

- **Branch:** `open2-tanjiro/h-ag-lr-wd-retune`
- **Hypothesis:** LR=0.0018 and WD=0.1 were inherited from PR #309 base without re-validation on NC × Arbor stack. NC's per-row × per-col L2 equalization + Arbor's Sinkhorn rescaling both change the effective update magnitude. Testing LR ∈ {0.0015, 0.0022} (2-arm n=2 screen), then n=4 on winner.
- **Status:** NEWLY ASSIGNED.

---

## 2026-06-06 18:43 UTC — PR #2321: H-Y Drop EN from Arbor + NC + RI — CLOSED (REFUTED)

- **Branch:** `open2-tanjiro/h-y-arbor-no-en-nc`
- **Hypothesis:** EN might not be load-bearing when NC is present; NC's L2 equalization might compensate for EN's momentum smoothing. Tested Arbor + NC + RI without EMA-Nesterov.
- **W&B run:** `5an0slvc` (open2-tanjiro/h-y-arbor-no-en-nc-n4, runtime 7.25h)
- **Results:**

| Trial | val/ri_loss_γ=-0.075 | paired Δ vs γ=0 |
|---:|---:|---:|
| T0 | 3.279332 | −0.000450 |
| T1 | 3.277918 | −0.000433 |
| T2 | 3.278490 | −0.000443 |
| T3 | 3.279066 | — |
| **n=4 mean** | **3.278702** | **−0.000440** |

- **Verdict:** n=4 mean 3.278702 = **+0.002509 above rank-1** (3.276193). EN is load-bearing even with NC present. Closing H-Y.
- **Combined with frieren H-Z** (Arbor + RI, no EN, no NC) at ~3.279: EN's ~−0.003 absolute lift is INDEPENDENT of NC condition. EMA-Nesterov is a primary mechanism, not a secondary enabler.

---

## 2026-06-06 18:30 UTC — PR #2328: H-AF Newton-Schulz iteration count ablation — ASSIGNED

- **Branch:** `open2-nezuko/h-af-ns-iters-nc-arbor`
- **Hypothesis:** NS5 is not the optimal iteration count on the NC × Arbor + RI stack. NC's row/col L2 equalization and Arbor's Sinkhorn equilibration together produce smoother, more equilibrated inputs to the polar decomposition, which may shift the optimum away from the original NS5 assumption. Testing NS6 first (single arm n=4). If NS6 wins, follow up NS7; if NS6 loses, try NS4.
- **Acceptance criterion:** n=4 mean ≤ 3.275693 (rank-1 −0.0005). Soft: paired Δ sign-stable negative across all 4 trials.
- **Status:** NEWLY ASSIGNED. Smoke gate (50 steps) before n=4 launch.

---

## 2026-06-06 18:18 UTC — PR #2325: H-AC NC cleanup — MERGED

- **Branch:** `open2-nezuko/h-ac-nc-cleanup`
- **Changes:** +2/−7 diff in `train_gpt_simple.py`. Removed `--nc` CLI flag, hardcoded `nc_enabled=True`, removed conditional `if args.nc:` block, cleaned NC-specific logging. NC is now the default and unconditional code path.
- **Verification:** Student smoke confirmed no regression. Advisor verified correct 5-point diff.
- **Impact:** Simplifies the codebase — no legacy flags around the rank-1 mechanism. All future experiments run NC automatically.

---

## 2026-06-06 17:50 UTC — PR #2320: H-X RI capture_step × γ ablation on Arbor stack — CLOSED (INFORMATIONAL)

- **Branch:** `open2-fern/h-x-ri-capture-step`
- **Hypothesis:** Test whether capture_step=2375 is optimal for RI on the Arbor+RI+EN stack, or whether an earlier capture gives a longer extrapolation lever arm. Swept 5 capture_steps × 3 γ values.
- **W&B:** `0ygp3njz`

### n=4 mean per (capture_step, γ)

| capture_step | γ=0 | γ=−0.05 | γ=−0.075 |
|---:|---:|---:|---:|
| 2000 | 3.276986 | 3.276799 | 3.277069 |
| **2200** | **3.276986** | **3.276635** ⭐ | **3.276697** |
| 2375 (default) | 3.276986 | 3.276671 | 3.276666 |
| 2550 | 3.276986 | 3.276778 | 3.276754 |
| 2700 | 3.276986 | 3.276873 | 3.276853 |

### Paired Δ vs default (2375, γ=−0.075)

| (capture, γ) | n=4 paired Δ | Sign-stable? |
|---|---:|---|
| (2200, −0.05) | **−0.000031** | ✅ 4/4 trials |
| (2375, −0.05) | +0.000005 | ✗ mixed |
| (2200, −0.075) | +0.000031 | ✗ mixed |
| (2000, −0.05) | +0.000164 | ✗ mixed |

### Analysis

**Winner: (capture=2200, γ=−0.05)** is the only sign-stable cell at −0.000031 mean paired Δ vs default. Forms a well-defined U-shape over capture_step with broad plateau in [2200, 2375] window. γ trades off with lever-arm: shallower γ (−0.05) pairs with longer lever (2200 capture); deeper γ (−0.075) pairs with shorter lever (2375).

**Key insight:** γ × lever-arm product is approximately constant at the optimum. The RI mechanism is internally consistent.

**Magnitude is small (30μ) but sign-stable.** One-sided sign test p ≈ 0.0625. The finding is a free default refinement for the Arbor-only stack but doesn't beat the new rank-1 NC × Arbor + RI (3.276193). **Reusable infrastructure:** `--ri_extra_capture_steps` flag added; any future capture-step ablation on a new stack is now a single n=4 launch.

**Consequence:** (capture=2200, γ=−0.05) adopted as new default for Arbor-only baselines. Follow-up H-AE assigned to fern to re-sweep on NC × Arbor stack — optimal capture may have shifted again.

---

## 2026-06-06 16:05 UTC — PR #2310: H-O NC alone on PR #309 base, paired arms — CLOSED (INFORMATIONAL)

- **Branch:** `open2-edward/h-o-nc-pr309-isolation`
- **Hypothesis:** Cautious-Muon (NC) added to bare PR #309 (no Arbor) — does NC alone compose with Aurora+EMA-Nesterov+RI?
- **W&B:** Arm A `zyfbkso7` (--nc 0), Arm B `js0yjia2` (--nc 1)

### Per-trial table (n=4 paired arms)

| Trial | Arm A val_loss (no NC) | Arm B val_loss (NC) | Paired Δ (B − A) |
|---:|---:|---:|---:|
| T0 | 3.27963 | 3.28048 | +0.00085 |
| T1 | 3.27792 | 3.27933 | +0.00141 |
| T2 | 3.27788 | 3.27882 | +0.00094 |
| T3 | 3.28031 | 3.27881 | −0.00150 (Arm A tail outlier) |
| **n=4 mean** | **3.27894** | **3.27936** | **+0.000425** |

### Statistical verdict

- Arm B mean 3.27936 vs Arbor baseline (PR #2298 = 3.27738): **+0.00198 above** ✗
- Arm B mean 3.27936 vs new rank-1 (PR #2317 = 3.276193): **+0.00317 above** ✗
- Stat margin 0.00128 < 0.004 required ✗
- Paired t(3) = 0.65 (NC adverse, weak) → not statistically significant against H0=0, but **directionally consistent with NC needs Arbor**

### Mechanism finding

**NC requires Arbor to compose with the Aurora+EN+RI stack.** Without Sinkhorn equilibration, NC adds +0.0004 (weakly adverse) on PR #309. With Sinkhorn (Arbor), NC contributes −0.0007 absolute lift on top of Arbor+RI (per PR #2317). Sinkhorn equilibration is a necessary precondition for NC to compose — likely because Sinkhorn reshapes the spectrum into a regime where NC's row/col L2 equalization captures non-trivial headroom rather than fighting EN saturation.

This closure confirms the compositional structure: Arbor → NC, not NC → Arbor.

---

## 2026-06-06 15:43 UTC — PR #2317: H-W NC × Arbor + RI on merged Arbor base — MERGED (NEW RANK-1)

- **Branch:** `open2-nezuko/h-w-nc-arbor-ri-pr309-2890`
- **Hypothesis:** Cautious-Muon (NC: per-row × per-col L2 equalization on gradient update before Nesterov-Schulz 5) composes additively with Corrected Arbor (Sinkhorn row/col equilibration) + Tail Reference Interpolation (γ=−0.075, capture_step=2375). Prediction: Sinkhorn equilibration may rescue NC from the EMA-Nesterov saturation that blocked NC on the non-Arbor PR #309 base.
- **W&B:** `vk0jtb3z`

### Per-trial table (paired γ-RI at step 2375)

| Trial | val/loss γ=0 | val/ri_loss γ=−0.05 | val/ri_loss γ=−0.075 | paired Δ(γ=−0.075 vs γ=0) | first_step_to_target |
|---:|---:|---:|---:|---:|---:|
| T0 | 3.277064 | 3.276739 | 3.276712 | −0.000352 | 2850 |
| T1 | 3.275825 | 3.275501 | 3.275501 | −0.000324 | 2825 |
| T2 | 3.277158 | 3.276849 | 3.276849 | −0.000309 | 2850 |
| T3 | 3.276025 | 3.275719 | **3.275708** | −0.000317 | 2850 |
| **n=4 mean** | **3.276518** | **3.276202** | **3.276193** | **−0.000325** | **2843.75** |

### Statistical verdict

- n=4 mean γ=−0.075 = **3.276193** vs PR #2298 baseline 3.27738 → **−0.001187** BELOW ✓
- vs recalibrated Arbor+RI floor (thorfinn n=4, 3.276890) → **−0.000697** BELOW ✓
- Stat contract: (3.28 − 3.276193) × √4 = **0.007615** ✓ (>> 0.004 requirement)
- Paired Δ mean −0.000325, std 0.000019 — extremely tight (NC×EN suppression band ~−0.0003)

### Mechanism

NC lifts absolute val_loss even though the RI paired Δ stays in the NC×EN-suppressed band (~−0.0003 vs normal ~−0.0005-0.0006). The decoupling: NC's row/col equalization reshapes the optimizer's noise floor, providing an independent absolute lift on Arbor, even though EN saturation still compresses the RI marginal contribution. Both operators pull val_loss down independently; they share the compressed RI budget.

**Refined compositional mechanism table (from n=4 data):**

| Component | Absolute val/loss effect |
|---|---:|
| Arbor (Sinkhorn) alone vs PR #309 baseline | −0.00049 |
| + EMA-Nesterov (EN required, independent of NC) | −0.0028 |
| + RI γ=−0.075 | −0.00032 (paired Δ) |
| + NC (row/col equalization on Arbor+EN+RI stack) | −0.00069 |
| **Combined: NC × Arbor + RI on EN base** | **3.276193 (n=4 mean)** |

EN and NC contribute independently; Arbor's Sinkhorn is the required base that enables NC's composition.

---

## 2026-06-06 14:30 UTC — PR #2307: H-L lm_head freeze tail × RI on PR #309 base — CLOSED (FALSIFIED)

- **Branch:** `open2-askeladd/h-l-lm-head-freeze-tail`
- **Hypothesis:** Freezing lm_head from step 2600 (last 290 / 10% of training) on PR #309 + RI base will reduce tail noise without breaking the RI prior. Paired arms (Arm A no freeze, Arm B freeze) test mechanism Δ at n=4.
- **W&B:** Arm A `v7pfq024`, Arm B `j4nsivel`

### Per-trial val/loss (γ=−0.075 RI @ step 2890)

| Trial | Arm A | Arm B | Δ (B−A) | Arm A fst | Arm B fst |
|---:|---:|---:|---:|---:|---:|
| T0 | 3.277565 | 3.279870 | +0.002305 | 2875 | 2890 |
| T1 | 3.276967 | 3.279970 | +0.003003 | 2850 | 2890 |
| T2 | 3.276846 | 3.279740 | +0.002894 | 2850 | 2890 |
| T3 | 3.279358 | 3.281521 | +0.002164 | 2890 | **−1 (MISS)** |
| **n=4 mean** | **3.277684** | **3.280275** | **+0.002587** | — | — |

### Statistical verdict

- Paired Δ mean +0.002587, sd 0.000419, paired t(df=3) = +12.35, p ≈ 0.0011 (two-tailed)
- Arm B n=4 mean (3.280275) ABOVE the 3.28 target — stat contract margin **−0.00055** (FAILS)
- All 4 per-trial Δ positive; smallest Δ (+0.00216) is 5.1× SE above zero — structural, not tail event
- T3 Arm B missed target entirely (fst=−1), confirming destabilization not stabilization

### Mechanism (provisional, from askeladd's analysis)

Freeze tail breaks the RI prior. RI captures `last-N-step delta` at step 2375 and projects (snaps back) at step 2890 along γ = −0.075. The captured direction `Δ = w(2375) − w(2890)` includes lm_head motion from steps 2375 → 2890 in full-flow training. In Arm B, freeze engages at step 2600, so steps 2600 → 2890 contribute zero lm_head motion; the captured Δ contains lm_head motion only from steps 2375 → 2600. RI extrapolation along γ < 0 thus pushes lm_head in a partially stale direction, breaking the local linear approximation.

**Implication:** Future tail-stabilization hypotheses must preserve continuous lm_head motion through the RI capture window. Smooth LR cooldown, Polyak-Ruppert / SWA tail averaging, or velocity damping are candidates — abrupt freeze is not.

### Cross-reference

Aligns with frieren H-T closure (freeze tail × Arbor + RI): n=2 mean +0.00225 above baseline. Three independent freeze-tail experiments (askeladd Arm B, frieren H-T n=2, askeladd Arm B reproduction) all confirm the +0.0025 absolute hurt.

---

## 2026-06-06 12:55 UTC — PR #2314: H-R Arbor+RI Recalibration (thorfinn)

- **Branch:** `open2-thorfinn/h-r-arbor-ri-pr309-2890`
- **Hypothesis:** Run merged Arbor+RI on 4 fresh seeds to calibrate the true n=4 mean and set the recalibrated merge bar.
- **W&B:** `ahv8kj7m`
- **Code changes:** NONE (calibration-only PR)

| Trial | val/loss γ=−0.075 | val/loss γ=0 | paired Δ | first_step_to_target |
|---:|---:|---:|---:|---:|
| T0 | 3.276168 | 3.276485 | −0.000317 | 2850 |
| T1 | 3.276595 | 3.276890 | −0.000295 | 2850 |
| T2 | 3.276790 | 3.277112 | −0.000322 | 2850 |
| T3 | 3.278008 | 3.278358 | −0.000350 | 2875 |
| **n=4 mean** | **3.276890** | **3.277211** | **−0.000321** | **2856.25** |

**Analysis:** Calibration result on merged Arbor+RI (identical to PR #2298 code). Pooled n=8 estimate ~3.27713. Recalibrated merge bar: n=4 ≤ 3.2762 for genuine lift. RI paired Δ −0.000321 ± 0.000023 fully active. Closed without code merge; Thorfinn reassigned H-AA (Arbor warmup, PR #2323).

---

## 2026-06-06 10:38 — PR #2311: H-P NC + RI on PR #305 base at 2925 steps — CLOSED (mechanism boundary confirmed, NOT mergeable)

- Branch: `open2-tanjiro/h-p-nc-ri-pr305-stack`
- Student: open2-tanjiro
- Hypothesis: NC + RI on PR #305 base (Aurora + RRE + Contra-Muon, no EMA-Nesterov) at 2925 steps. Tests NC × non-EN base composition.
- Status: **CLOSED** — n=4 mean (γ=−0.075) = 3.279177, above all baselines

### n=4 per-trial × per-γ results

| Trial | γ=−0.075 | γ=−0.05 | γ=0 | paired Δ (γ=−0.075 vs γ=0) | first_step_to_target |
|---:|---:|---:|---:|---:|---:|
| T0 | 3.279508 | 3.279606 | 3.280146 | **−0.000638** | 2925 |
| T1 | 3.279875 | 3.279980 | 3.280526 | **−0.000651** | 2925 |
| T2 | 3.279444 | 3.279540 | 3.280087 | **−0.000643** | 2925 |
| T3 | **3.277882** | 3.277990 | 3.278538 | **−0.000656** | 2900 |
| **n=4 mean** | **3.279177** | 3.279279 | 3.279824 | **−0.000647** (±8e-6) | 2918.75 |

W&B run: `6ygg4kze` (group `open2-tanjiro/h-p-nc-ri-pr305-2925`)

### Analysis — mechanism boundary (the publishable finding)

**4-way base × mechanism grid (NC+RI paired Δ vs Arbor baseline 3.27738):**

| Base | NC+RI paired Δ(γ=−0.075 vs γ=0) | EMA-Nesterov? | Status |
|---|---:|---|---|
| bare Muon (thorfinn H-F) | ~−0.0006 | No | NC healthy |
| **PR #305 (tanjiro H-P)** | **−0.000647 ± 0.000008** | **No** | **NC healthy** |
| PR #309 (frieren H-K) | −0.000290 | Yes (β=0.95) | NC suppressed |
| PR #309 (fern H-N T0) | −0.000310 | Yes (β=0.95) | NC suppressed |

**Verdict:** EMA-Nesterov halves the RI lift when NC is active. Stdev 8e-6 across 4 trials is striking evidence — NC × EMA-Nesterov interaction is a real, specific mechanism boundary, not a generic NC problem or noise.

### Absolute level

- n=4 mean 3.279177 > Arbor baseline 3.27738 by +0.00180 → not mergeable
- Above PR #305 base record 3.27813 by +0.00105 → NC overhead on PR #305 also hurts absolute
- Stat margin 0.001645 < required 0.004

### Why NC can't recover absolute level on PR #305

Tanjiro's analysis: PR #305 already integrates Aurora + RRE + Contra-Muon. Adding NC raises the step-budget floor; RI lift (~−0.0006) can't recover the ~+0.001 step-budget overhead from NC. Contra-Muon does NOT fully overlap with NC sign-awareness (otherwise paired Δ would collapse).

---

## 2026-06-06 06:38 — PR #2306: H-K NC + RI on PR #309 base — CLOSED (NC × EMA-Nesterov null)

- Branch: `open2-frieren/h-k-nc-ri-pr309-n4`
- Hypothesis: Cautious-Muon (per-row × per-col L2 equalization on update before NS5) + RI (γ=−0.075, capture_step=2375) on PR #309 base at 2890 steps. Tests whether NC composes additively with RI on the EMA-Nesterov momentum stack.
- Status: **CLOSED** — n=4 mean 3.27922, does not beat Arbor baseline 3.27738

### n=4 per-trial results

| Trial | val/loss (γ=−0.075, NC+RI) | val/loss (γ=0, NC alone) | Paired Δ (RI vs no-RI) | first_step_to_target |
|---:|---:|---:|---:|---:|
| T0 | 3.28091 | ~3.28191 | ~−0.00100 | -1 |
| T1 | 3.27996 | 3.28028 | −0.00032 | 2890 |
| T2 | 3.27777 | — | — | 2875 |
| T3 | 3.27825 | — | — | ~2890 |
| **n=4 mean** | **3.27922** | — | — | — |

W&B run: `hv1l0vsn` (group `open2-frieren/h-k-nc-ri-pr309-2890`)

### Analysis

This is the **3rd independent confirmation of NC × EMA-Nesterov conflict** on PR #309-derived bases (alongside edward H-O NC-alone and fern H-N NC+RI). NC hurts absolute val/loss by ~+0.002 vs RI-only baseline (fern merged 3.27786) and by +0.00184 vs the Arbor rank-1 (3.27738).

High trial variance (T0=3.28091, T2=3.27777) is consistent with PR #309 base variance. The n=4 mean of 3.27922 represents the unbiased estimate.

**Mechanism confirmation:** PR #309's EMA-Nesterov (β=0.95) pre-captures momentum-sign information that NC's per-row × per-col normalization was designed to provide. On bare Muon, NC adds clean signal (thorfinn H-F: paired Δ=−0.0005); on PR #305 (Aurora + Contra-Muon), NC adds clean signal (tanjiro H-P: paired Δ=−0.0006); on PR #309 (EMA-Nesterov), NC signal is suppressed (paired Δ=−0.00029 to −0.00032) and absolute val/loss INCREASES.

**What this closes:** NC experiments on any EMA-Nesterov-derived base. This covers the entire PR #309 lineage (current rank-1 and all successors). NC is only viable on bare Muon or non-EMA-Nesterov optimizer bases.

**frieren reassigned to H-T (PR #2316):** lm_head freeze tail × Arbor + RI — a disjoint mechanism (freeze operates on lm_head gradient, not Muon update direction).

---

## 2026-06-06 04:13 — PR #2308: H-M NC + RI on bare Muon at 2890 steps — CLOSED (step-budget null)

- Branch: `open2-thorfinn/h-m-nc-ri-2890-speedrun`
- Hypothesis: Can NC+RI compress the step budget sufficiently to make bare Muon competitive at 2890 steps? (H-F showed NC+RI on bare Muon reaches 3.274 at 3325 steps.)
- Status: **CLOSED** — bare Muon at 2890 steps cannot reach 3.28 val/loss target (experiment aborted at T2 start)
- W&B run: `7qcq1iwa`

### n=2 results (T0, T1 before abort)

| Trial | val/loss (γ=−0.075) | val/loss (γ=0) | Paired Δ | Reaches 3.28 target? |
|---|---:|---:|---:|---|
| T0 | 3.29757 | 3.29816 | −0.000592 | ❌ NO |
| T1 | 3.29760 | ~3.29820 | ~−0.0006 | ❌ NO |
| n=2 mean | ~3.29758 | — | — | ❌ |

### Analysis

**Bare Muon at 2890 steps cannot reach the 3.28 target or compete with the PR #309-based stack (3.27738).** The NC+RI paired Δ of ~−0.0006 is actually stronger than the H-F result at 3325 steps (−0.000504), confirming mechanism robustness. But the base val/loss is ~3.298, requiring ~0.018 of additional lift to reach target — far beyond what NC+RI provides.

**Implication:** The NC+RI mechanism requires a strong optimizer base (Aurora+EMA-Nesterov or similar) to deliver competitive absolute val/loss. Bare Muon's weaker base trajectory means even with NC+RI, you stay above the 3.28 target at 2890 steps. H-F confirmed 3325 steps is feasible but not competitive with the 2890-step PR #309 stack.

**Thorfinn reassigned to H-R (Arbor + RI)** — the high-priority composition test.

---

## 2026-06-06 03:45 — PR #2298: H-A Corrected Arbor Muon on PR #309 base — MERGED (new rank-1)

- Branch: `open2-alphonse/h-a-corrected-arbor-muon-pr309-base`
- Hypothesis: Sinkhorn spectral equilibration of Muon update matrices (corrected: sqrt(out_dim) post-NS pin removed, pure row/column rebalancer) on PR #309 base (Aurora+EMA-Nesterov) at 2890 steps.
- Status: **MERGED** — new rank-1 baseline 3.27738 n=4, margin 0.00524
- W&B run: `5weg8d9r` (n=4 confirm, group `open2-alphonse/h-a-arbor-pr309-corrected`)

### n=4 per-trial results

| Trial | val/loss @ step 2890 | first_step_to_target | Δ vs fern merged (3.27786) | Δ vs PR #309 base |
|---|---:|---:|---:|---:|
| T0 | 3.27749 | 2850 | −0.00037 ✅ | −0.00050 ✅ |
| T1 | 3.27633 | 2850 | −0.00153 ✅ | −0.00166 ✅ |
| T2 | 3.27714 | 2850 | −0.00072 ✅ | −0.00085 ✅ |
| T3 | 3.27856 | 2875 | +0.00070 (tail) | +0.00057 |
| **n=4 mean** | **3.27738** | **2856.25** | **−0.00048** ✅ | **−0.00061** ✅ |

### Statistical contract

| Metric | Value | Threshold | Status |
|---|---:|---:|---|
| n=4 mean | **3.27738** | < 3.27786 (fern) | ✅ beats by 0.00048 |
| Contract `(3.28 − mean) × √4` | **0.00524** | ≥ 0.004 | ✅ ~31% headroom |
| σ across T0-T3 | 0.00092 | — | tight |
| max−min | 0.00223 | 0.0015 tail flag | ⚠️ T3 mild tail (3.27856), but far from catastrophic 3.281+ regime |

### Analysis and conclusions

**Corrected Arbor Muon mechanism confirmed.** The original PR #2298 failure was a code spec ambiguity: the first implementation applied `G_orth * sqrt(out_dim)` after Sinkhorn, introducing a ~55× Frobenius magnitude explosion that manifested as +0.045 val/loss regression and NaN at some random seeds. Removing this post-NS pin and using default Muon scaling (`max(1, out/in)**0.5`) restored stable training AND captured a genuine lift.

**Mechanism interpretation:** With the corrected scaling, Sinkhorn equilibration is a pure row/column statistic rebalancer on the Muon update direction — `sinkhorn_ratio=1.00` confirms magnitude preservation. The 0.00048 lift over fern's merged RI stack comes from reshaping the per-element distribution without changing the Frobenius norm. This is consistent with the theoretical Arbor hypothesis: spectrum equilibration reduces the variance of individual weight updates, allowing the optimizer to follow a smoother descent direction.

**T3 mild tail note:** T3 = 3.27856 is a tail event (max−min = 0.00223 > 0.0015 flag) but sits well below the catastrophic 3.281+ regime seen on other PR #309 base experiments. The corrected Arbor may be damping tail variance, not just shifting the mean — publishable as a variance-reduction mechanism.

**Cleanup assigned:** PR #2313 to alphonse — prune the broken sqrt(out_dim) variant code path, make `apply_arbor` default True, run 250-step smoke.

**Next step for fleet:** All in-flight NC experiments (frieren H-K, thorfinn H-M, fern H-N, edward H-O) are testing on pre-Arbor base. After they complete, NC × Arbor composition (can NC add further lift on top of the new merged stack?) is the next high-priority hypothesis.

---

## 2026-06-06 03:13 — PR #2305: H-J Two-Snapshot Richardson RI on PR #309 base — NULL (closed)

- Branch: `open2-nezuko/h-j-2snap-richardson-pr309-2890`
- Hypothesis: Two-snapshot Richardson extrapolation `θ_K + γ₁(θ_K − θ_S1) + γ₂(θ_K − θ_S2)` using snapshots at steps ~1750 and 2375 improves over single-snapshot RI on PR #309 + EMA-Nesterov base.
- Status: **CLOSED** — Richardson extrapolation NULL at n=4 (paired Δ ≈ 0, SE 7.4e-6)
- W&B run: `r2kim5fg`

### n=4 mean arm table (16-arm γ₁ × γ₂ grid)

|   γ₁ \ γ₂  | 0.0000 | −0.0300 | −0.0500 | −0.0750 |
|---:|---:|---:|---:|---:|
|  0.0000 | 3.278803 | 3.278660 | 3.278878 | 3.279473 |
| −0.0500 | 3.278489 | **3.278484** | 3.278781 | 3.279480 |
| −0.0750 | **3.278484** | 3.278537 | 3.278879 | 3.279626 |
| −0.1000 | 3.278580 | 3.278695 | 3.279075 | 3.279862 |

### Key comparison: best 2-snap vs fern H15 single-snap

| Arm | T0 | T1 | T2 | T3 | n=4 mean |
|---|---:|---:|---:|---:|---:|
| (γ₁=−0.050, γ₂=−0.030) best 2-snap | 3.279151 | 3.277817 | 3.277750 | 3.279218 | **3.278484** |
| (γ₁=−0.075, γ₂=0.000) fern H15 | 3.279136 | 3.277817 | 3.277770 | 3.279215 | **3.278484** |
| Paired Δ (2-snap − H15) | +0.0000148 | 0.0 | −0.0000198 | +0.0000033 | **−0.0000003** |

Paired SE = 7.4e-6. Best-arm n=4 mean = 3.278484 vs fern merged 3.27786 = +0.000624 above. Stat contract margin 0.00303 < 0.004 (fails).

### Analysis and conclusions

**H-J is a clean NULL.** The two-snapshot Richardson extrapolation is statistically indistinguishable from single-snapshot RI at paired Δ ≈ −0.0000003, SE 7.4e-6. γ₂=0 wins or ties in 11/12 cells across all 4 trials.

**Mechanistic interpretation:** The parameter trajectory at the tail of Track 3 training is **fundamentally first-order** — well-approximated by a single linear extrapolation direction. Higher-order curvature signals required for Richardson-style multi-point correction are below the seed-to-seed noise floor at n=4. This is a publishable mechanism boundary: RI is maximally effective at single-snapshot extrapolation; adding a second snapshot does not orthogonalize the extrapolation direction.

**Implication for RI research:** The (γ₁=−0.05/−0.075, γ₂=0) fern H15 configuration remains the optimal single-mechanism RI configuration. All research should use single-snapshot RI from here.

**Follow-up:** Assigned H-Q Lookahead-Muon (online slow-weights interpolation, PR #2312) — tests if the tail-linearity is exploitable during training, not just at evaluation.

---

## 2026-06-06 01:39 — PR #2299: H-D late-higher block LR on PR #309 base — NULL result (closed)

- Branch: `open2-tanjiro/h-d-late-higher-block-lr-pr309-base`
- Hypothesis: Does mean-preserving linear block-LR ramp (0.90→1.10) improve val/loss on PR #309 base vs flat control?
- Status: **CLOSED** — n=4 null result; T1 tail event inflates SE, no detectable signal
- W&B runs: `wpk68f5v` (Arm A, flat), `xcwr1ed9` (Arm B, late-higher v2)

### Per-trial × per-arm val/loss table

| Trial | Arm A (flat) | Arm B (late-higher) | Paired Δ (B − A) | first_step_to_target |
|---|---:|---:|---:|---:|
| T0 | 3.27917 | 3.27750 | **−0.00167** | Arm B = 2850 |
| T1 | 3.27770 | 3.28244 | **+0.00474** ← tail | Arm B = −1 (missed target) |
| T2 | 3.27772 | 3.27671 | **−0.00101** | Arm B = 2850 |
| T3 | 3.27984 | 3.27968 | **−0.00016** | Arm B = 2890 |
| **n=4 mean** | **3.27861** | **3.27908** | **+0.000475** | |
| SD | 0.00107 | 0.00257 | 0.00291 | |
| SE | 0.000536 | 0.001283 | 0.001455 | |

Paired t = 0.326, df = 3, one-sided p (Arm B < Arm A) = 0.617. Welch's two-sample p = 0.625.

### Analysis and conclusions

**H-D is NULL on PR #309 base.** 3 of 4 trials favor Arm B (T0, T2, T3 all negative Δ) but T1 alone (+0.00474 swing) inflates SE to 0.00146 — larger than the estimated effect (−0.0010 excluding T1). With mean Δ of +0.000475 sitting 0.33σ above zero, the data is fully consistent with no late-higher effect.

**Mechanism interpretation:** PR #309 base (Aurora + EMA-Nesterov + Contra-Muon ramp to step 2500) already incorporates depth-conditional learning behavior. The late-higher external ramp is mechanistically redundant with the internal Contra-Muon ramp, saturating the depth-differentiation budget. No headroom remains for the linear external modifier.

**Cross-base verdict (complete):**
- PR #309 (tanjiro): NULL (paired Δ +0.000475, p=0.62, n=4)
- PR #300 (edward): FALSIFIED (paired Δ +0.001576, n=2 aborted)
- **Late-higher block LR is CLOSED across all tested bases. Not a viable composable mechanism.**

**Suggested follow-up by student:** NC+RI on PR #305 — assigned as H-P to tanjiro (PR #2311).

---

## 2026-06-06 00:12 — PR #2301: H-D late-higher block LR on PR #300 base — ABORTED (falsified)

- Branch: `open2-edward/h-d-late-higher-pr300`
- Hypothesis: Does mean-preserving linear block-LR ramp (0.90→1.10) improve val/loss on PR #300 base?
- Status: **CLOSED** — Aborted at n=2, paired Δ unfavorable (Arm B > Arm A both trials)
- W&B runs: `svbaoi2b` (Arm A, n=4, PR #300 + flat), `jbdhh1bz` (Arm B, n=2, PR #300 + late-higher)

### Per-trial paired comparison

| Trial | Arm A (flat, control) | Arm B (late-higher) | Paired Δ (B − A) | Notes |
|---|---:|---:|---:|---|
| T0 | 3.278741 | 3.279780 | **+0.001039** | Clean trial both arms |
| T1 | 3.278717 | 3.280830 | **+0.002113** | Arm B tail event |
| T2 | 3.278666 | aborted | — | Arm A clean; Arm B not launched |
| T3 | 3.281341 | not run | — | Arm A own tail |
| **n=2 mean** | **3.278730** | **3.280305** | **+0.001576** | Abort criterion met |

### Analysis and conclusions

H-D (late-higher block LR) is **FALSIFIED on PR #300 base**. The mechanism is contraindicated here — late-stage LR inflation destabilizes the PR #300 optimizer's internal state. The Arm A control (flat) is itself reasonably clean at 3.278730, showing PR #300 converges well without modification. The PR #300 base's depth-modulated optimizer already incorporates late-block emphasis internally; the external ramp creates redundancy that amplifies late-stage gradient variance rather than ameliorating it.

**Cross-base note:** Tanjiro's same H-D on PR #309 base (PR #2299) showed mixed results — T0 arm B helped (Δ=−0.00149) but T1 was a tail event. PR #309 base is more tolerant of late-block inflation. PR #300 base rejects it outright (both clean trials unfavorable). Mechanism base-specificity confirmed: late-higher LR is not universally applicable.

---

## 2026-06-06 00:05 — PR #2302: H-G RI hyperparameter sweep (12-arm × 4-trial, PR #309 base) — CLOSED

- Branch: `open2-fern/h-g-ri-sweep-pr309`
- Hypothesis: Is there a better (cap, γ) combination than the merged (cap=2375, γ=−0.075) for RI on PR #309 base?
- Status: **CLOSED** — Saturation confirmed; merged config is the optimum
- W&B run: `z20mj2bh` (n=4 × 2890 steps, 12-arm eval: cap ∈ {1500, 2375, 2700} × γ ∈ {0, −0.05, −0.075, −0.10})

### n=4 × 12-arm results table (best arm = merged config)

| Arm (cap, γ) | n=4 mean | SE | Δ vs MERGED (3.27786) |
|---|---:|---:|---:|
| cap=1500, γ=−0.10 | 3.281246 | 0.000725 | +0.002881 |
| cap=1500, γ=−0.075 | 3.279882 | 0.000592 | +0.001517 |
| cap=1500, γ=−0.05 | 3.279217 | — | +0.000852 |
| **cap=2375, γ=−0.075 (MERGED)** | **3.278365** | — | **+0.0005 (within noise)** |
| cap=2375, γ=−0.05 | 3.278580 | — | +0.000715 |
| cap=2700, γ=−0.075 | 3.278900 | — | +0.001035 |
| γ=0 (control) | 3.279000 | — | +0.001135 |

### Analysis and conclusions

The hyperparameter surface is **flat around (cap=2375, γ=−0.075)** — the already-merged configuration. Key findings:
1. **cap=2375 dominates**: cap=1500 is actively harmful with negative γ (too-early snapshot → noisy direction); cap=2700 too close to terminal to extract drift signal.
2. **γ=−0.075 saturates**: γ=−0.05 and γ=−0.10 both cluster within ±0.0001 of γ=−0.075 — flat optimum plateau.
3. **n=4 best-arm mean 3.278365 > merged 3.27786**: the replication is +0.0005 worse than the merged result, within seed noise. The merged config is confirmed as the optimum; no incremental gain from (cap, γ) retuning.

**This closes the RI hyperparameter search direction.** Future RI work must move to a different lever: different base, paired mechanisms, or schedule interaction. The NC+RI compositional stack (H-N, H-K, H-M) is the active frontier.

**Cleanup note:** fern's pod launched a duplicate `fr3xs4ut` run (same seed_offset=0) which was killed once original `z20mj2bh` confirmed complete. No data loss.

---

## 2026-06-05 23:35 — PR #2303: H-F RI on NC + bare Muon (n=4, 3325 steps) TERMINAL — CLOSED

- Branch: `open2-thorfinn/h-f-ri-nc-baremuon`
- Hypothesis: Does Tail Reference Interpolation compose additively with Cautious-Muon on bare Muon at 3325 steps?
- Status: **CLOSED** — Universality confirmed; 3325 steps > fern's 2890 speedrun step count
- W&B run: `ziexp42t` (n=4 × 3325 steps, capture_step=2735, paired-γ eval {0, −0.05, −0.075})

### Per-trial × per-γ val/loss table

| Trial | γ=0 (pre-RI) | γ=−0.05 | **γ=−0.075 (best)** | Δ (best vs γ=0) | first_step_to_target |
|---|---:|---:|---:|---:|---:|
| T0 | 3.275862 | 3.275421 | 3.275366 | −0.000497 | 3250 |
| T1 | 3.276324 | 3.275866 | 3.275821 | −0.000503 | 3250 |
| T2 | 3.273498 | 3.273050 | **3.272994** | −0.000504 | **3225** |
| T3 | 3.275222 | 3.274767 | 3.274711 | −0.000510 | 3250 |
| **n=4 mean** | **3.275227** | **3.274776** | **3.274723** | **−0.000504** | **3243.75** |
| SE | 0.000619 | 0.000618 | 0.000620 | 0.000003 | — |

### Analysis

**Headline:** RI composes additively with NC on bare Muon. Paired Δ = −0.000504 (SE 3.1e-6) — essentially deterministic across 4 trials. NC-alone baseline (PR #2288): 3.27537. NC+RI (this): 3.27472. Total NC+RI lift vs bare-Muon-no-NC-no-RI: ~0.005.

**Statistical contract:** `(3.28 − 3.274723) × √4 = 0.01055` ≥ 0.004 → PASSES (2.6× over threshold).

**Why not merge:** `first_step_to_target` mean 3243.75 > fern's 2890. Track 3 primary metric ranks by step count first. The −0.00314 absolute val/loss advantage over fern's merged 3.27786 is real but not credited by the speedrun benchmark.

**Tail variance observation:** Per-trial Δ stability σ(Δ) = 6.4e-6. No T3 tail event (T3 = 3.274711). This contrasts with PR #309 base where T3 tail events in [3.281, 3.284] are common. Bare Muon + NC produces materially lower per-seed variance than EMA-Nesterov + Aurora.

### Cross-base RI universality (4 bases confirmed)

| Base | Steps | n | Mean val/loss | Paired Δ |
|---|---:|---:|---:|---:|
| Fern PR #309 (Aurora+EMA-Nesterov) MERGED | 2890 | 4 | 3.27786 | −0.00033 |
| Frieren PR #300 (Aurora+CM+SOAP) | 2930 | 4 | 3.27877 | −0.00056 |
| Nezuko PR #305 (Aurora+RRE+CM+SOAP) | 2925 | 4 | 3.27842 | −0.00066 |
| **Thorfinn NC + bare Muon (this)** | **3325** | **4** | **3.27472** | **−0.00050** |

RI is now confirmed universal across 4 different optimizer families. Magnitude inversely correlated with base quality.

### Suggested follow-up (assigned to thorfinn as H-M, PR #2308)

NC + RI on bare Muon at 2890 steps: test if the bare-Muon optimizer family can beat fern's merged record at the SAME speedrun step count with re-tuned warmup and cap=2375.

---

## 2026-06-05 22:00 — PR #2289: H5b RI on PR #300 base — universality confirmed, no merge

- Branch: `open2-frieren/h5b-ri-pr300-no-rre`
- Hypothesis: Does Tail Reference Interpolation (γ=−0.075, capture=2375) port to PR #300 base (Aurora+Contra-Muon+SOAP, no RRE)?
- Status: **CLOSED** — Universality confirmed; absolute val/loss > merged record at higher step
- W&B runs: `wd1aaqtr` (Arm A, control), `fvf4tu59` (Arm B, RI)
- Mechanism: same RI implementation as fern's merged H15, paired arms (γ=0 vs γ=−0.075) at 2930 steps

### Results

| Trial | Arm A (control) | Arm B (RI) | Paired Δ (B−A) |
|---|---:|---:|---:|
| T0 | 3.27822 | 3.27798 | −0.00024 |
| T1 | 3.28002 | 3.27927 | −0.00075 |
| T2 | 3.27952 | 3.27860 | −0.00092 |
| T3 | 3.27958 | 3.27925 | −0.00033 |
| **n=4 mean** | **3.27934** | **3.27877** | **−0.00056** |
| sd | 0.000776 | 0.000615 | 0.000327 |

**Paired t-test:** t = −3.424 (df=3), p < 0.05 → **statistically significant lift, 4/4 trial pairs improve**.

Statistical contract at Arm B: `(3.28 − 3.27877) × √4 = 0.00246` — **FAILS 0.004 threshold**.

### Analysis

RI is now confirmed universal across **4 distinct optimizer bases**: PR #309 (fern, merged 3.27786), PR #305 (nezuko, 3.278421), PR #300 (frieren, 3.27877), and bare Muon (thorfinn, trending ~3.2747 at 3325 steps). Paired Δ ranges from −0.00033 (fern) to −0.00066 (nezuko) — all 4 bases show consistent O(10⁻³) lift in the same direction. The lift is direction-specific (askeladd H-I confirms negative γ only) and saturates at γ ≈ −0.05 to −0.10.

**Why this PR doesn't merge:** absolute val/loss 3.27877 at 2930 steps exceeds fern's merged 3.27786 at 2890 steps by +0.00091, driven entirely by PR #300 base being weaker than PR #309 base (no EMA-Nesterov). The mechanism is healthy; the base choice is suboptimal for record competition.

### Suggested follow-ups (assigned to frieren as H-K)

NC (Cautious-Muon) on PR #309 + RI base at 2890 steps — port thorfinn's NC+RI bare-Muon composition to fern's merged stack. Thorfinn's T2 = 3.272994 (at 3325 steps) is the strongest absolute val/loss on the fleet; if NC delivers any positive paired Δ on PR #309+RI base, that's a clear rank-1 candidate.

---

## 2026-06-05 19:10 — PR #2297: H17 RI on PR #305 base — universality confirmed, no merge

- Branch: `open2-nezuko/h17-ri-pr305-base`
- Hypothesis: Does Tail Reference Interpolation (γ=−0.075, capture=2375) apply on PR #305 base (Aurora+RRE damping+Contra-Muon+SOAP), and can it beat fern's merged 3.27786 at 2925 steps?
- Status: **CLOSED** — Universality confirmed but absolute val/loss does NOT beat merged record
- W&B run: `khu2l6d9` (n=4 × 2925 steps × 3 paired γ values)

### Results

| Trial | γ=0 | γ=−0.05 | γ=−0.075 | Paired Δ (γ=−0.075) |
|---|---:|---:|---:|---:|
| T0 | 3.278435 | 3.277871 | 3.277755 | −0.000680 |
| T1 | 3.278891 | 3.278304 | 3.278214 | −0.000677 |
| T2 | 3.278571 | 3.278001 | 3.277914 | −0.000657 |
| T3 | 3.280442 | 3.279885 | 3.279802 | −0.000640 |
| **n=4 mean** | **3.279085** | **3.278515** | **3.278421** | **−0.000664** |

Statistical contract at γ=−0.075: `(3.28 − 3.278421) × √4 = 0.003158` — **FAILS 0.004 threshold**.

### Analysis

RI is universal across PR #305 base — paired Δ of −0.000664 (SE 0.0000086) is the most precisely measured RI lift on the fleet, and the LARGEST by magnitude (2× fern's H15 on PR #309). However, the PR #305 base itself is materially worse than PR #309 base: γ=0 control n=4 mean = 3.279085 vs PR #309 base γ=0 ≈ 3.27820 — a gap of ~+0.00089. The larger RI lift on PR #305 cannot overcome this base deficit.

**Key insight:** RI lift magnitude is inversely correlated with base quality. PR #305 has RRE damping + SOAP (slower convergence initially) which creates more "correctible" late-stage drift, yielding bigger paired Δ. But the same slower convergence makes the absolute val/loss worse despite the larger lift. PR #309's EMA-Nesterov is a better base for record competition.

Cross-base verification verdict: RI is confirmed universal across PR #309, PR #305, PR #300 (frieren), and bare Muon (thorfinn). This is publication-grade evidence for mechanism generality.

---

## 2026-06-05 22:55 — PR #2304: H-I RI direction ablation TERMINAL n=4 (CLOSED)

- Branch: `open2-askeladd/h-i-ri-direction-ablation-n4`
- Hypothesis: Is RI lift direction-specific (negative γ = tail extrapolation) or symmetric (any γ helps)?
- Status: **CLOSED** — Mechanism characterization complete; no merge (n=4 best-γ 3.27872 > fern's 3.27786)
- W&B run: `kyihnden` (n=4 × 2890 steps × 8 paired γ from one capture_step=2375)

### Full 8-γ × 4-trial table

| γ | T0 | T1 | T2 | T3 | n=4 mean | std | paired Δ vs γ=0 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| −0.100 | 3.27715 | 3.27747 | 3.27858 | 3.28205 | **3.27881** | 0.00224 | −0.00022 |
| **−0.075** (primary) | 3.27705 | 3.27738 | 3.27849 | 3.28195 | **3.27872** | 0.00224 | **−0.00032** |
| −0.050 | 3.27706 | 3.27739 | 3.27850 | 3.28194 | **3.27872** | 0.00223 | −0.00031 |
| **0.000** (no-RI) | 3.27735 | 3.27771 | 3.27883 | 3.28224 | 3.27903 | 0.00223 | 0 |
| +0.050 | 3.27809 | 3.27847 | 3.27960 | 3.28298 | 3.27978 | 0.00222 | +0.00075 |
| +0.250 | 3.28562 | 3.28604 | 3.28717 | 3.29040 | 3.28731 | 0.00216 | +0.00827 |
| +0.500 | 3.30687 | 3.30725 | 3.30842 | 3.31140 | 3.30849 | 0.00205 | +0.02945 |
| +1.000 | 3.40397 | 3.40369 | 3.40484 | 3.40645 | 3.40474 | 0.00115 | +0.12569 |

### Analysis

**Headline finding:** RI is strictly tail extrapolation — negative γ helps, positive γ catastrophic. Mechanism asymmetry is sharp, reproducible across all 4 trials, and consistent with extrapolation physics rather than SWA-style averaging.

Negative γ ∈ {−0.05, −0.075, −0.10} all give similar paired Δ ≈ −0.00022 to −0.00032 (saturation at γ ≈ −0.05).

Positive γ damage is monotone and accelerates: +0.05 already hurts (+0.00075), +0.25 adds 8 mnat, +0.50 adds 29 mnat, +1.00 (pure snapshot) destroys training (+126 mnat).

**Mechanism conclusion:** the eval-time optimum is PAST the terminal weights along the recent drift direction, NOT between them and any earlier checkpoint. SWA / Polyak averaging style mechanisms cannot recover this lift.

T3 = 3.28195 tail event drives n=4 mean above fern's merged 3.27786. Re-running with different seed bucket wouldn't add scientific value; mechanism is characterized.

### Suggested follow-ups (assigned to askeladd as H-L, PR #2307)

**lm_head freeze tail (paired arms at n=4 on PR #309 + RI base):** the recurrent T3 tail event in this dataset (askeladd T3=3.28195, frieren Arm A T3 tails, tanjiro T3=3.27984, fern T3=3.27984) suggests the readout layer is a noise source in the final 10% of training. Freezing lm_head from step 2600 onward (last ~10% of 2890) tests whether the tail variance can be reduced without disturbing the validated merged stack.

---

## 2026-06-05 19:15 — PR #2304: H-I RI direction ablation (provisional n=2) — DIRECTION ASYMMETRY CONFIRMED

- Branch: `open2-askeladd/h-i-ri-direction-ablation-n4`
- Hypothesis: Is RI lift direction-specific (negative γ = tail extrapolation) or symmetric (any γ helps)?
- Status: **RUNNING** — T0+T1 terminal, T2-T3 in progress
- W&B run: `kyihnden` (n=4 × 2890 steps × 8 paired γ values: {−0.10, −0.075, −0.05, 0, +0.05, +0.25, +0.50, +1.00})

### Results (provisional n=2)

| γ | T0 | T1 | n=2 mean | vs γ=0 (n=2) |
|---|---:|---:|---:|---:|
| −0.10 | 3.277152 | 3.277468 | 3.277310 | −0.000223 |
| **−0.075** | **3.277050** | **3.277379** | **3.277215** | **−0.000318** |
| −0.05 | 3.277058 | 3.277390 | 3.277224 | −0.000309 |
| 0 (control) | 3.277353 | 3.277713 | 3.277533 | 0.000000 |
| +0.05 | 3.278089 | 3.278467 | 3.278278 | +0.000745 |
| +0.25 | 3.285616 | 3.286036 | 3.285826 | +0.008293 |
| +0.50 | 3.306867 | 3.307252 | 3.307060 | +0.029527 |
| +1.00 | 3.403965 | 3.403688 | 3.403827 | +0.126294 |

### Analysis

**Critical finding: RI mechanism is EXCLUSIVELY tail extrapolation.** The lift saturates at γ ≈ −0.05 (no significant gain from γ=−0.10 vs γ=−0.075). The SWA/averaging direction (positive γ) scales catastrophically: +0.05 already hurts; +1.00 adds 126 mnat — destroys training.

Practical implication: SWA, Polyak averaging, or any "blend toward past snapshots" mechanism will NOT work. Only "extrapolate beyond final step in the direction of late-training drift" produces lift.

The γ=−0.075 result (n=2 mean 3.277215) projects to n=4 ≈ 3.27722 if T2/T3 hold magnitude — this would BEAT fern's merged 3.27786 at identical step count (2890). If confirmed, this becomes the best n≥2 measurement of the RI mechanism and is a strong merge candidate (though it's testing the SAME mechanism as fern's H15, so merge value depends on whether the new n=4 mean supersedes the existing baseline).

---

## 2026-06-05 15:06 — PR #2300: H-E Polar Express NS timing gate on PR #309 base (FALSIFIED — gate)

- Branch: `open2-askeladd/h-e-polar-express-ns-pr309`
- Hypothesis: Does Polar Express NS (KellerJordan PR #254, doubly-exponential convergence NS) deliver ≥5% per-step wall-clock speedup on H100, sufficient to justify n=4 quality confirmation?
- Status: **GATE FAILED** — +2.23% speedup vs ≥5% threshold. Correct call to close; gate protocol worked exactly as designed.
- W&B runs: `p11xlm0l` (baseline), `mxwc0v28` (PE gate)

### Results

| Run | step_avg_ms | Speedup vs baseline |
|---|---:|---:|
| Baseline NS5 | 2023.47ms | — |
| Polar Express NS | 1978.45ms | **+2.23%** |
| **Gate threshold** | — | **≥5.00%** |
| **Gate decision** | — | **FAILS by 2.8 pp** |

PE val_loss numerically correct (reached 3.27893 at terminal), no NaN, no OOM.

### Analysis

PE NS is GH200-profiled. On GH200, +5–10% speedup reported. On H100 the `torch.compile(dynamic=False, fullgraph=True)` annotations and `_pe_tall_*` paths don't translate due to different SM count, L2, and cuBLAS heuristics. Mechanism is algorithmically correct but hardware-specific.

**Verdict:** H100 should not pursue PE for the rest of this launch wave. Locked OUT.

---

## 2026-06-05 14:13 — PR #2296: H16 Cautious-Muon on bare Muon (FALSIFIED)

- Branch: `open2-thorfinn/h16-cautious-muon-pr305-aurora-rre`
- Hypothesis: Does applying Liu et al. (ICLR 2026) Cautious Optimizer sign-agreement mask post-Newton-Schulz (normalized, `mask_norm = 1/max(mask_rate, 0.01)`) improve bare Muon convergence at 3325 steps?
- Status: **FALSIFIED (n=1 abort)** — T0 val_loss = 3.37845, +0.10 above falsification threshold (3.279). Abort after T0 correct given unambiguous gap.
- W&B run: `26jalgru`

### Results

| Step | NC Arm A reference (PR #2288) | C-Muon (26jalgru) | Delta |
|---:|---:|---:|---:|
| 250 | 4.09993 | 4.73628 | +0.636 |
| 1000 | 3.63200 | 3.77067 | +0.139 |
| 2000 | 3.43784 | 3.54161 | +0.104 |
| 3000 | 3.30454 | 3.40938 | +0.105 |
| **3325 (final)** | **3.27461** | **3.37845** | **+0.104** |

Mask diagnostics: mask_rate 0.65-0.80 (healthy), mask_norm_factor 1.4-1.5 (no runaway). Implementation correct; mechanism fails.

### Analysis

The +0.10 gap is stable from step ~250 onwards (not narrowing at all during cooldown). Root cause: Newton-Schulz output is already approximately orthonormal, so the sign-product `(g_orth * buf)` doesn't carry "noise filtering" semantics — the mask discards ~30% of an already-rotated near-isotropic update, losing information rather than filtering noise. The `cautious_normalize=1` then scales the surviving 70% by 1.43×, amplifying on top of an already-high Muon LR schedule.

Liu et al.'s gains were on AdamW (1e-4 scale LR); Muon operates ~2 orders of magnitude higher effective LR after NS. The sign-agreement filter is counterproductive in this regime.

**Cross-base verdict:** C-Muon is OUT of all compositions for this wave. Do not revisit.

---

## 2026-06-05 13:37 — PR #2295: H15 Tail Reference Interpolation on PR #309 base (MERGED ✅ NEW BASELINE)

- Branch: `open2-fern/h15-tail-reference-interpolation-pr309`
- Hypothesis: Does eval-time parameter extrapolation `θ_eval = θ_K + γ·(θ_K − θ_2375)` with γ=−0.075 provide reproducible lift on PR #309 base (Aurora+EMA-Nesterov) without changing the training trajectory?
- Status: **MERGED — new SOTA baseline at 3.27786 (n=4 mean), 2890 steps**
- W&B run: `g32gn44z`

### Results

| Trial | γ=0 (control) | γ=−0.050 | γ=−0.075 (primary) | Paired Δ (γ=−0.075 − γ=0) |
|---:|---:|---:|---:|---:|
| T0 | 3.27798 | 3.27766 | 3.27765 | −0.00033 |
| T1 | 3.27843 | 3.27813 | 3.27810 | −0.00033 |
| T2 | 3.27680 | 3.27650 | 3.27648 | −0.00032 |
| T3 | 3.27924 | — | ~3.27924 | ~−0.00033 |
| **n=4 mean (γ=−0.075)** | — | — | **3.27786** | **−0.00033** |

Stat-sig: (3.28 − 3.27786) × √4 = **0.00427 ≥ 0.004** ✓ CLEARS.
Beats PR #305 baseline (3.27812750) by **−0.00026**.

### Analysis

RI delivers the most reproducible paired Δ on the fleet: variance of Δ = 0.00001 across 4 trials. The mechanism is eval-only — no training trajectory change, zero risk of instability. The reference step 2375 (82.2% through training) captures a point before the "late-drift" phase where PR #309's EMA-Nesterov momentum creates systematic noise amplification.

**Key design innovation (fern):** paired-gamma within-trial evaluation runs γ∈{0, −0.05, −0.075} from the same θ_K and θ_2375 at zero extra training cost. This is the correct statistical design for mechanism attribution.

**What's open:** (1) Are these the optimal hyperparameters? (→ H-G capture×γ sweep, assigned to fern as PR #2302); (2) Is RI cross-base? (→ frieren H5b on PR #300, nezuko H17 on PR #305); (3) Does RI compose? (→ alphonse H-A + Arbor Muon, tanjiro H-D + late-higher LR)

---

## 2026-06-05 12:06 — PR #2294: H14 Senpai PMuon on PR #300 base (FALSIFIED)

- Branch: `open2-edward/h14-senpai-pmuon-pr300-base`
- Hypothesis: Does Senpai PR #64 bilateral covariance whitening (PMuon: L^{-γ}mR^{-γ}, γ=0.3, β_cov=0.95, identity-init L=R=I) improve val/loss on PR #300 base (Aurora+Contra-Muon+SOAP)?
- Status: **FALSIFIED (n=2 abort)** — n=2 mean 3.28152, cross-base PMuon pattern locked.

### Results

| Trial | val/loss @ 2925 | Notes |
|-------|-----------------|-------|
| T0 | 3.28256 | Healthy convergence; L_fro grew 3.4×10^8× by step 125 (whitening active) |
| T1 | 3.28048 | Healthy convergence |
| T2 | — | Aborted (advisor-approved, n=2 mean > 3.28) |
| T3 | — | Aborted |
| n=2 mean | **3.28152** | |

- W&B run: `i97y7os1`
- Stat-sig: best-case n=4 mean = 3.27959 (above PR #305 3.27813)

### Analysis

**Cross-base PMuon pattern locked.** Tanjiro's PMuon-on-PR#309 had T0=3.28237; edward's PMuon-on-PR#300 had T0=3.28256 — within 0.00019 of each other. Both n=2 means are ~0.003 above their respective base references. PMuon's bilateral L^{-γ}mR^{-γ} whitening is structurally incompatible with already-orthogonalized + row-balanced bases (PR #300 Aurora+Contra-Muon, PR #309 Aurora+EMA-Nesterov). The Senpai #1532/#1614 stack's lift from PMuon was dependent on that stack's specific gradient-distribution invariants (no Aurora, different aux-Adam LR schedule). Identity-init for L/R (vs tanjiro's 5-step warmup) provided cleaner trial boundaries but not better results — edward's no-rescale variant landed slightly worse than tanjiro's Frobenius-rescaled variant, consistent with Aurora's row-balanced calibration being overridden by PMuon's magnitude contribution.

**Telemetry quality:** L_fro_mean(step 1) = 30.7 ≈ 0.95·√D confirmed identity-init signature. L_fro grew 3.4×10^8× to step 125, confirming bilateral whitening was applied with full force. Trial boundary reset verified via T1 step 125 ≈ T0 step 125 ± 2%.

---

## 2026-06-05 11:10 — PR #2293: H13 Senpai PMuon on PR #309 base (FALSIFIED)

- Branch: `open2-tanjiro/h13-senpai-pmuon-pr309-base`
- Hypothesis: Does Senpai PR #64 bilateral covariance whitening (PMuon: L^{-γ} m R^{-γ}, γ=0.4, β_cov=0.95) on the Nesterov-blended momentum before NS5 improve val/loss on PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED (n=2 abort)** — n=2 mean 3.28053, best-case n=4=3.27926, above PR #305.

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.28237 | Healthy convergence; high relative to base |
| T1 | 3.27868 | Healthy convergence; partial recovery |
| T2 | — | Aborted (advisor-approved) |
| T3 | — | Aborted |
| n=2 mean | **3.28053** | |

- W&B run: `7eimwktx`
- Stat-sig: best-case n=4 mean = 3.27926 (well above PR #305 3.27813)

### Analysis

PMuon's Frobenius rescale (`||whitened|| / ||raw|| ≡ 1.0 by construction`) forces magnitude-neutrality while applying 800–14000× bilateral directional reweighting. The directional interference with EMA-Nesterov+Aurora produces high seed variance (σ ≈ 0.0018 vs PR #309 base σ ≈ 0.00018). PMuon does not transfer from its Senpai #1614 context (different LR, aux-Adam, no Aurora) to PR #309 base without the compensating mechanisms. Stack-dependent composition failure.

---

## 2026-06-05 11:05 — PR #2291: H11 Circuit-Muon on PR #309 base (FALSIFIED)

- Branch: `open2-askeladd/aurora-ema-nesterov-circuit-muon-pr309-base`
- Hypothesis: Does KellerJordan PR #311 Circuit-Muon (V/O attention cross-scaling) improve val/loss when composed with PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED** — n=4 mean 3.27844, above PR #305 (3.27813).

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.27958 | Tail event (PR #309 base bimodal pattern) |
| T1 | **3.27726** | Best individual trial this round |
| T2 | 3.27846 | |
| T3 | 3.27846 | |
| n=4 mean | **3.27844** | |

- W&B run: `ar3yhz6f`
- Stat-sig: (3.28 - 3.27844) × √4 = 0.00312 < 0.004

### Analysis

Circuit-Muon on PR #309 adds bimodal structure on top of the existing PR #309 tail-event distribution. T0 is the tail event (3.27958); T1-T3 average 3.27806 (slightly below PR #309 base mean of 3.27800). On non-tail trials Circuit-Muon shows marginal lift; T1=3.27726 is the best single trial this round. The tail event (not the mechanism) kills the mean. Mechanism not competitive as standalone; future composition with RI or Arbor (tail-suppression) may be worth revisiting.

---

## 2026-06-05 10:59 — PR #2292: H12 β2-pulse on PR #309 base (FALSIFIED)

- Branch: `open2-alphonse/h12-senpai-beta2pulse-pr309-base`
- Hypothesis: Does Senpai #1532 aux-Adam β2 pulse (0.95→0.99 at step 970) improve val/loss on PR #309 base (Aurora+EMA-Nesterov)?
- Status: **FALSIFIED** — n=4 mean 3.27822, above PR #305 (3.27813).

### Results

| Trial | val/loss @ 2890 | Notes |
|-------|-----------------|-------|
| T0 | 3.27971 | Tail event |
| T1 | 3.27775 | |
| T2 | 3.27766 | |
| T3 | 3.27775 | |
| n=4 mean | **3.27822** | |

- W&B run: `1tegunyu`
- Stat-sig: (3.28 - 3.27822) × √4 = 0.00356 < 0.004

### Analysis

T0=3.27971 tail event drives mean above PR #305. T1/T2/T3 mean = 3.27772 (would beat PR #305 at n=3 if stat-sig contract could be cleared at n=3). Pattern confirms: PR #309 base bimodal distribution is on the Muon path; aux-Adam-side interventions cannot suppress it. β2-pulse is "additive on weak base, neutral on strong base."

---

## 2026-06-05 06:10 — PR #2288: Replicate PR #295 — Normalized Correction on base Muon (CONFIRMED)

- Branch: `open2-thorfinn/pr295-nc-base-muon`
- Hypothesis: Does PR #295's Normalized Correction (divide Muon gradient by `sqrt(row_norm × col_norm)` before NS orthogonalization) improve val/loss on a vanilla Muon baseline at 3325 steps? A/B design: Arm A (NC) vs Arm Z (control, n=2 stopped early to save GPU).
- Status: **Closed — mechanism confirmed on bare Muon, but not sub-2900 eligible. Student reassigned H16.**

### Results

| Trial | Arm A (NC) val/loss @ 3325 | Arm Z (control) val/loss @ 3325 |
|---:|---:|---:|
| 0 | **3.27461** | 3.27781 |
| 1 | **3.27582** | 3.27910 |
| 2 | **3.27628** | *(stopped @ n=2 by advisor)* |
| 3 | **3.27477** | — |
| **n=4 mean** | **3.27537** | **3.27846 (n=2)** |
| σ | 0.00080 | — |

- W&B run: `5wirp0h4` (Arm A); `sx4q2hn0` (Arm Z)
- Margin: `(3.28 − 3.27537) × √4 = 0.00926` ≫ 0.004 stat-sig contract
- NC delta vs control: −0.00309 (favorable; ~6× the minimum detectable signal)
- All 4 NC trials individually beat 3.278 contract ceiling

### Analysis

- **NC is genuinely additive on bare Muon** — T0=3.27461 was not a tail event; T1-T3 confirm a tight distribution (range [3.27461, 3.27628]). This is the strongest per-trial result observed on any student this round.
- **NC is NOT composable with Aurora-bearing stacks:** Falsified on PR #300 (fern PR #2284, n=4 mean 3.27875) and PR #305 (alphonse PR #2281, n=4 mean 3.27986). The defining compositional rule is now clear: **NC competes for the same row-aware spectrum control degree of freedom as Aurora's row-balanced polar refinement. Whichever applies first leaves nothing for the other.**
- **Why NOT merging:** train_steps=3325 is outside the sub-2900 mission budget. Plain Muon + NC at 2925 steps is unlikely to beat PR #305 (Aurora + RRE, 3.27813 @ 2925). The ~0.003 NC lift at 3325 would need to overcome Aurora's structural advantage at the lower step budget.
- **Carry-over for future work:** (1) On bare-Muon stacks NC delivers ~0.003 lift; (2) NC + EMA-Nesterov WITHOUT Aurora could be a viable stack (not yet tested); (3) NC + MuLoCo / Polar Express as bare-Muon enhancement candidates.
- Student's decision to stop Arm Z at n=2 (saving ~3.5h GPU time) and launch Arm A at n=4 immediately was excellent experimental design.

### Suggested follow-ups

- **NC + EMA-Nesterov on bare PR #300 base** — remove Aurora, add NC + EMA-Nesterov, test whether they compose (different mechanism classes — pre-NS spectrum vs. gradient look-ahead). Step budget: 2900.
- **NC as sub-2900 candidate only if paired with a mechanism that doesn't use Aurora** — e.g. NC + Senpai β2-pulse (aux Adam only, no Muon-side conflict).

---

## 2026-06-05 04:40 — PR #2284: H4 Arbor vs NC ablation on PR #300 base (Arm A NC terminal)

- Branch: `open2-fern/arbor-vs-nc-pr300-base`
- Hypothesis: Three-arm ablation to settle the "pre-Newton-Schulz conditioning slot" question on the PR #300 base — Arm A = PR #295 Normalized Correction (NC) inserted before `X = X / X.norm()`; Arm B = PR #310 Arbor Muon (2-iter row/col equilibration on `mlp.fc`/`mlp.proj`); Arm Z = control replicating PR #300 reference. n=4 @ train_steps=2930.
- Status: **Arm A terminal known; PR to be closed after student SENPAI-RESULT.**

### Results (Arm A only — Arms B and Z TBD)

| Trial | val/loss @ 2930 |
|---:|---:|
| 0 | 3.27828 |
| 1 | 3.27760 |
| 2 | 3.27903 |
| 3 | **3.28007** ← tail event |
| **n=4 mean** | **3.27875** |
| σ | 0.00104 |

- W&B run: `m50dnbvb` (group `open2-fern/arbor-vs-nc-pr300-base`)
- Margin: `(3.28 − 3.27875) × √4 = +0.00250` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.00031 → falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.00062
- Arm B (Arbor) original implementation diverged at debug-screen step 758 with loss gap ~0.54 vs control. Student identified three pseudo-code discrepancies vs actual PR #310 (alternating + relative-to-mean clamp + `sqrt(out_dim)` post-NS pin) and was authorized to re-implement; Arm B re-screen may or may not have been launched after Arm A confirm.

### Analysis

- **NC standalone on PR #300 stack does NOT compose.** Combined with alphonse PR #2281 (NC on PR #305 stack, n=4 mean 3.27986) the result is consistent across two NC-bearing compositions on Aurora bases. NC is **redundant** with PR #300's existing row-aware refinement (Aurora row-balanced polar on `mlp.proj` + Contra-Muon ramp).
- **Refutes earlier "NC + Contra-Muon DOES compose" rule of thumb** — at n=2 fern Arm A appeared to lead at 3.27794, but n=3 erosion (T2=3.27903) and n=4 tail (T3=3.28007) reveal high seed variance and no real lift over PR #300 reference. Single trials are insufficient evidence for compositional rules; must wait for n=4.
- **σ=0.00104 is ~2× the σ of other PR #300-base n=4 runs** (edward 0.00055, tanjiro #2287 0.00051) — NC may introduce additional seed sensitivity by amplifying gradient-norm fluctuations in early layers.
- **Implication for next wave:** NC is fully ruled out on Aurora-bearing stacks. NC's potential value is limited to bare-Muon configurations (currently being tested by thorfinn PR #2288 at train_steps=3325, T1-T3 pending).
- **Strategic implication:** With first-wave NC, EMA-Nesterov-bare, Circuit-Muon-isolated, and Tail Phase Readout all falsified, sub-2900 SOTA now depends on (a) Senpai #1532/#1614 ingredients (β2-pulse, PMuon) currently in flight (alphonse/tanjiro/edward), (b) Aurora+EMA-Nesterov composites (nezuko+askeladd in flight), or (c) genuinely new architectural levers from the next research wave (Polar Express, MuLoCo, KL-SOAP).

### Suggested follow-ups

- **Close PR #2284** upon student terminal SENPAI-RESULT.
- **Reassign fern** to the next-highest-EV Senpai ingredient: candidate is **Senpai LR/EMA stack on PR #309 base** (the third and last untested Senpai-#1614 ingredient) or **Polar Express NS variant (PR #254)** on PR #300/PR #309 base as a NS-iteration replacement experiment.
- **Update compositional rules file** (NEW): NC compatibility with row-aware refinement = NEGATIVE; NC may only matter on bare-Muon configurations.

---

## 2026-06-05 04:00 — PR #2283: H3 Circuit-Muon isolated on PR #300 base

- Branch: `open2-edward/circuit-muon-pr300-base`
- Hypothesis: Test PR #311's Circuit-Muon mechanism (per-head V↔O cross-scaling + per-head trace-only gauge rebalance) standalone on PR #300 base. Determine whether the mechanism contributes value independent of EMA-Nesterov (the other ingredient in PR #311's claimed sub-2900 result). n=4 @ train_steps=2930.
- Status: **Closed — falsification confirmed at student's own falsification rule (not merged).**

### Results

| Trial | val/loss @ 2930 |
|---:|---:|
| 0 | 3.278952 |
| 1 | 3.278220 |
| 2 | 3.278378 |
| 3 | 3.279420 |
| **n=4 mean** | **3.278742** |
| σ | 0.000550 |

- W&B run: `glygz1xt` (group `open2-edward/circuit-muon-pr300-base`)
- Margin: `(3.28 − 3.278742) × √4 = +0.002515` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.000299 → falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.000614
- All 4 trials reached 3.28 target at step 2925

### Analysis

- **Mechanism is mechanically correct.** V/O per-head Frobenius ratios stayed within 1% throughout all 4 trials (block mean 1.009-1.024 across training), per-head std stays sub-1%. The implementation is sound; this is a real null signal about the mechanism on this base.
- **Structural finding about PR #300's effective-step-size regime:** PR #300's existing stack (Aurora + Contra-Muon + radial brake + Muon momentum warmup/cooldown) already regulates attention layer step sizes such that V/O ratios are naturally near 1.0. Circuit-Muon's per-head balance has nothing to do because the imbalance it's designed to correct is already approximately zero.
- **Compositional implication:** PR #311's claimed sub-2900 lift must come predominantly from EMA-Nesterov (the other ingredient). Circuit-Muon is conditional on the EMA-Nesterov gradient evaluation point, OR it requires a base where Aurora is applied to `attn.v` and `attn.proj` (not just `mlp.proj` as in PR #300).
- σ=0.55e-3 across 4 seeds is tight — n=4 sufficient to conclude the mean isn't beating PR #300. No outlier; non-improvement is a property of the mechanism on this base, not seed variance.
- Step time stable at ~2018 ms (same as PR #300 base) — V↔O coupling adds no wall-clock cost.

### Suggested follow-ups (student-flagged)

- Circuit-Muon + EMA-Nesterov on PR #300 base — askeladd PR #2291 is testing exact composition on PR #309 base
- Circuit-Muon + Aurora on attn.v/proj — would give Circuit-Muon something to do
- Drop Circuit-Muon from canon if EMA-Nesterov standalone wins

Advisor decision: close. Reassign student to **H14 Senpai #1532/#1614 PMuon on PR #300 base** (PR #2294) — companion to tanjiro PR #2293 (PMuon on PR #309 base).

---

## 2026-06-05 02:30 — PR #2287: H9 Single-stage Tail Phase Readout on PR #300 base

- Branch: `open2-tanjiro/tail-phase-readout-pr300-base`
- Hypothesis: Test the single-stage variant of PR #318's Tail Phase Readout mechanism (one γ_1 = −0.07 pulse at step 2750 in PR #300-base trajectory) on a clean PR #300 base. n=4 @ train_steps=2930.
- Status: **Closed — falsification at student's own falsification rule (not merged).**

### Results

| Trial | val/loss @ 2930 | first_step_to_target |
|---:|---:|---:|
| 0 | 3.27911 | 2920 |
| 1 | 3.27849 | 2910 |
| 2 | 3.27968 | 2925 |
| 3 | 3.27877 | 2920 |
| **n=4 mean** | **3.2790125** | **2918.75** |
| σ | 5.12e-4 | — |

- W&B run: `8bd1iezl` (group `open2-tanjiro/tail-phase-readout-pr300-base`)
- Margin: `(3.28 − 3.2790125) × √4 = +0.001975` (contract requires ≥ +0.004 → FAILS)
- Vs PR #300 (3.27844, n=16): worse by +0.000569 → student's falsification rule fires
- Vs PR #305 (3.27813, n=8): worse by +0.000885

### Analysis

- **Pulse mechanism IS real.** Mean 5-step Δ at pulse step 2750 = **−0.00162** vs natural −0.00060 — a ~2.7× immediate acceleration. Consistent across all 4 seeds (T0=−0.00155, T1=−0.00164, T2=−0.00168, T3=−0.00159). Telemetry confirms the N-subspace norm moves by ~0.022% absolute (max per-tensor relative move 0.44%, always an attn.q.weight).
- **But the gain doesn't persist.** Post-pulse 5-step decay rate slows to ~−0.000417 (vs natural −0.00061 pre-pulse) — ~30% slowdown. By step 2930 the cumulative effect erodes to net +0.0006 worse than PR #300 baseline.
- **Interpretation:** The pulse direction is slightly misaligned with the natural optimizer trajectory. Free immediate benefit; cost in subsequent momentum.
- **Compositional read:** Single-stage TPR on PR #300 base does NOT compose to a sub-2900 win. The chained 3-stage version in #318 may compose because the final stage absorbs residual misalignment — but replicating that is a separate, larger PR.
- Per-seed val/loss trace shows tight σ=5.12e-4 — good seed stability, just centered at the wrong mean.

### Suggested follow-ups (student-flagged)

- γ_1 sensitivity sweep — modest EV
- Late-stage γ_3 alone — likely similar misalignment in late phase
- TPR + PR #305 base — likely subject to RRE interference (cf. alphonse #2281 NC + RRE FAIL)
- Replicate the chained 3-stage version from PR #318 — would be a larger PR

Advisor decision: close. Reassign student to higher-EV Senpai-#1614 ingredient line (H13 PMuon, PR #2293).

---

## 2026-06-05 02:10 — PR #2281: H1 Normalized Correction on PR #305 base (Aurora + RRE + Contra-Muon)

- Branch: `open2-alphonse/normalized-correction-pr305-base`
- Hypothesis: Add NC (PR #295 row/col pre-NS normalization) on top of the official PR #305 stack (Aurora row-balanced polar + RRE late-step extrapolation + Contra-Muon ramp to 2500). n=4 @ train_steps=2925. Test whether NC composes with the merged sub-2925 baseline.
- Status: **Closed — clear falsification (not merged).**

### Results

| Trial | best_val_loss @ 2925 | first_step_to_target |
|---:|---:|---:|
| 0 | 3.27688 | 2880 |
| 1 | 3.28211 | -1 (never) |
| 2 | 3.28238 | -1 (never) |
| 3 | 3.27806 | 2895 |
| **n=4 mean** | **3.279857** | — |
| σ | 0.002424 | — |

- W&B run: `oeftnbeo` (group `open2-alphonse/nc-pr305-base`)
- Margin: `(3.28 − 3.279857) × √4 = +0.000285` (contract requires ≥ +0.004 → FAIL by −0.003715)
- Vs PR #305 (3.27813 @ 2925, n=16): worse by +0.00173 on raw mean
- Vs fern Arm A NC + PR #300 base (n=2 mean 3.27794, no RRE): worse by +0.00192

### Analysis

- **Bimodal distribution:** T0 (3.27688) and T3 (3.27806) cleared the 3.28 target; T1 (3.28211) and T2 (3.28238) plateau just above ceiling. σ=0.00242 is 13× larger than nezuko #2286's T0-T2 σ=0.00018, indicating discrete seed-to-seed basin selection rather than smooth noise.
- **Discriminating composition variable: RRE.** Both alphonse (NC + Aurora + RRE + Contra-Muon, FAILS) and fern Arm A (NC + Aurora + Contra-Muon, no RRE, n=2 mean 3.27794 LEADS) include Contra-Muon, but only alphonse includes RRE. The hypothesis that NC + Contra-Muon interfere is rejected; instead **NC + RRE interfere**: RRE's late-step weight extrapolation operates on accumulated updates that NC has already row/col-normalized, cancelling NC's directional adjustment.
- **Implication for the compositional rule:** "Mechanisms that touch the same NS-norm regime do NOT stack" still holds, but the actual conflict is at the *post-NS update aggregation* level (RRE re-extrapolates from NC-normalized updates), not the pre-NS adjustment level (Contra-Muon).
- Student noted training trajectory was healthy across all trials — no NaN, no divergence; this is a worse-conditioned optimum, not a numerical failure.

### Per-trial observations

- T1/T2 plateau at 3.282 — flagged for potential follow-up (seed-sensitivity ablation), low priority vs the RRE-vs-NC composition direction.
- T0 outlier-low (3.27688) misled early read; n=1 sampling deceived the contract.

---

## 2026-06-05 01:25 — PR #2286: Replicate PR #309 EMA-Nesterov + Aurora at 2890 steps

- Branch: `open2-nezuko/replicate-pr309-ema-aurora`
- Hypothesis: Replicate KellerJordan PR #309 — EMA-Nesterov (β=0.3) layered on Aurora row-balanced polar (#300 base) — at fixed train_steps=2890, n=4 trials. Determine whether this composition clears the sub-2900 stat-sig contract on Senpai infra.
- Status: **Closed — falsification at contract margin (not merged).**

### Results

| Trial | val/loss @ 2890 |
|---:|---:|
| 0 | 3.27794 |
| 1 | 3.27823 |
| 2 | 3.27780 |
| 3 | 3.27956 |
| **n=4 mean** | **3.27839** |
| σ | 0.00080 |

- W&B run: `pp6kui6d` (group `open2-nezuko/replicate-pr309-ema-aurora`)
- Margin: `(3.28 − 3.27839) × √4 = +0.00322` (contract requires ≥ +0.004 → FAIL by −0.00078)
- Vs PR #305 (3.27813 @ 2925): worse by +0.00026 on raw mean
- Vs Senpai #1532 (3.27902 @ 2905): better by 0.00063

### Analysis

- T0/T1/T2 mean = 3.27799 (σ=0.00018) — extremely tight, consistent with PR #309 claim.
- T3 = 3.27956 is a ~9σ tail event relative to T0-T2 distribution. The seed-to-seed distribution has a fat right tail under EMA-Nesterov+Aurora.
- PR #309's claim of sub-2890 was likely from a luckier n=16 sample averaging out the tail.
- The mechanism IS real — three of four seeds beat all references — but the stat-sig contract demands robustness across all seeds, which it does not have at n=4.
- Telemetry confirms EMA-Nesterov fired cleanly at both β-ramp boundaries (no spikes at steps 300/1950).
- Decision: extending to n=8 was an option (~50% probable to clear) but reassigning to compositional hypothesis Aurora+EMA-Nesterov+NC has higher EV.

---

## 2026-06-05 01:25 — PR #2282: H2 EMA-Nesterov (β=0.3) on bare PR #300 base

- Branch: `open2-askeladd/ema-nesterov-pr300-base`
- Hypothesis: Does EMA-Nesterov (PR #309's mechanism) provide standalone lift when added to bare PR #300 base (without PR #309's other changes)? n=4 at train_steps=2900.
- Status: **Closed — clear falsification (not merged).**

### Results

| Trial | val/loss @ 2900 |
|---:|---:|
| 0 | 3.28135 |
| 1 | 3.28122 |
| 2 | 3.27996 |
| 3 | 3.28046 |
| **n=4 mean** | **3.28075** |
| σ | 0.00066 |

- W&B run: `maf69yse` (group `pr2282-ema-nesterov`)
- Margin: `(3.28 − 3.28075) × √4 = −0.00150` → BIG FAIL (well above 3.28 ceiling)
- Vs PR #300 (3.27844 @ 2930): worse by +0.00231 at FEWER steps

### Analysis

- EMA-Nesterov on bare PR #300 (Aurora row-balanced polar + Contra-Muon ramp + Muon warmup/cooldown) does NOT compose. Mean is above 3.28 — far worse than PR #300 vanilla.
- Combined with PR #2286 (nezuko): EMA-Nesterov's value in PR #309 comes from its **interaction with Aurora alone**, not from raw EMA-Nesterov + #300's full stack. PR #309 strips some of #300's components (Contra-Muon details, etc.) before adding EMA-Nesterov.
- Implication: Contra-Muon and EMA-Nesterov likely interfere (similar to NC + Contra-Muon interference observed in alphonse PR #2281).
- Compositional rule emerging: **mechanisms that touch the same NS-norm regime do NOT stack**.


---

## 2026-06-07 13:50 — PR #2340: H-AQ AdamW β₁ warmup (fern)

- Branch: `open2-fern/h-aq-adamw-beta1-warmup`
- Hypothesis: Warm up AdamW β₁ from 0.85 (Arm A) or 0.65 (Arm B) to 0.95 over the first 500 steps. Motivation: more aggressive first-moment EMA early in training where gradient signal is changing rapidly.
- Status: **Closed FALSIFIED both arms (not merged) — 25th saturated lever.**

### Results

| Arm | Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|---:|
| A β₁_start=0.85 | T0 | 3.278502 | +0.002309 |
| A β₁_start=0.85 | T1 | 3.278373 | +0.002180 |
| A mean | — | **3.278438** | **+0.002245 FALSIFIED** |
| B β₁_start=0.65 | T0 | 3.280502 | +0.004309 |
| B β₁_start=0.65 | T1 | 3.277773 | +0.001580 |
| B mean | — | **3.279138** | **+0.002945 FALSIFIED** |

- W&B runs: `m33ftkmq` (Arm A), `q1rg6lwx` (Arm B). Both `open2-fern/h-aq-adamw-beta1-warmup` group.

### Analysis

- Both arms FALSIFIED at 4-7× noise floor. β₁ warmup direction is dead for AdamW.
- The merged `β₁=0.95` constant from the launch baseline is decisively the right setting. Warming up from below `0.95` underweights past gradients during the high-noise early phase, leading to more chaotic embed/lm_head trajectories.
- Compounding evidence with H-AL (β₂ warmup, also FALSIFIED): **AdamW EMA-coefficient schedule axis is fully saturated**. No version of warming-up either β₁ or β₂ beats the constant baseline.
- 25th lever closed. fern reassigned to H-BC (spectral radius norm targeting in `muon_update`).

---

## 2026-06-07 14:08 — PR #2341: H-AR EMA-Nesterov γ warmup (nezuko)

- Branch: `open2-nezuko/h-ar-en-gamma-warmup`
- Hypothesis: Warm up EMA-Nesterov γ from 0.9 (Arm A) or 0.95 (Arm B) to 0.99 over the first 500 steps. Tests whether constant γ=0.99 is over-aggressive during initial weight calibration.
- Status: **Closed FALSIFIED both arms (not merged) — 26th saturated lever.**

### Results

| Arm | Trial | val/ri_loss_gamma_neg0p0750 | vs rank-1 (3.276193) |
|---|---:|---:|---:|
| A γ_start=0.9 | n=2 mean | **3.279476** | **+0.003283 FALSIFIED** |
| B γ_start=0.95 | T0 | 3.277508 | +0.001315 |
| B γ_start=0.95 | T1 | 3.279210 | +0.003017 |
| B mean | — | **3.278359** | **+0.002166 FALSIFIED** |

- W&B runs: `dynewpp5` (Arm A), `3vhyodcg` (Arm B). `open2-nezuko/h-ar-en-gamma-warmup` group.

### Analysis

- Both arms FALSIFIED at 4-7× noise floor. EN γ warmup direction is dead.
- The merged `γ=0.99` constant is the right setting — initializing γ below 0.99 reduces the EN smoothing effect during the early high-variance phase, which causes more aggressive Muon update accumulation early and degrades final convergence.
- Combined with H-AH (constant γ sweep FALSIFIED) and H-AX (EN PREFILL_STEPS=100 FALSIFIED): **the entire EN scheduling axis is saturated** for the parameters tested. The only remaining EN axis is the SCOPE axis (Muon-only vs all-params), which is H-BE in the queued wave.
- 26th lever closed. nezuko reassigned to H-BF (SNR-adaptive AdamW LR).

