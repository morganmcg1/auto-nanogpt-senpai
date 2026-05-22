# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-22 19:00 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `val/loss` at 3350 steps (lower is better); `speedrun/final_first_step_to_target` secondary
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline

## Current merged baseline — post-#708

**val=3.27036 / fs=3216.67 (n=3 paired-pod mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_GRAD_CLIP_BODY=10.0
NANOGPT_GRAD_CLIP_AUX=5.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
NANOGPT_ADAMW_EMBED_LR_MULT=1.5
NANOGPT_MUON_ATTN_LR_MULT=0.80
NANOGPT_MUON_MLP_LR_MULT=1.20
```

### Merged stack history

| PR | Change | val (n) | Cumulative baseline |
|----|--------|---------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3.27434 |
| #236 | AdamW β₂=0.99 | 3.27407 (3) | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3.27352 |
| #290 | NS coef schedule=linear_ramp_down | 3.27200 (3) | 3.27200 |
| #393 | AdamW embed LR mult=1.5× | 3.27174 (3) | 3.27174 |
| #579 | Body-Muon attn=0.80× mlp=1.20× LR asymmetry | 3.27070 (3) | 3.27070 |
| **#708** | **Per-group grad-clip BODY=10/AUX=5** | **3.27036 (3)** | **3.27036** ← CURRENT |

---

## Active experiments (all on r4)

### ✅ fern #408 — Adaptive Gradient Clipping (AGC) — CLOSED 14:15 UTC productive-null

Paired-pod confirmation collapsed pod-0 signal. Final n=3 pooled: mean(val_B)=3.27271 > baseline 3.27200 → pre-staged rule triggers CLOSE. Pod-0 Δ=−0.00252 was favorable-seed luck. AGC mechanism consistent (99.4% trigger rate) but val benefit not reproducible. **16th productive-null this cycle.**
**Follow-up**: fern assigned **#477 OrthoGrad for aux groups**.

### ✅ fern #477 — OrthoGrad for aux AdamW groups — CLOSED 21:35 UTC productive-null

Arms B (embed: +0.00163), C (lm_head: +0.00285) regress; D (embed+lm_head: −0.00080) recovers. Non-monotonic: single-group breaks embed/lm_head magnitude balance; combined restores it. D Δ=−0.00080 passes stat-rule on absolute baseline but well short of −0.002 within-pod threshold — productive-null. **22nd productive-null/negative this cycle.** Key finding: aux groups co-evolve as a coupled system, resist single-axis gradient intervention.
**Follow-up**: fern assigned **#514 β₁ warmup on aux AdamW groups** — first-moment smoothing-rate schedule axis.

### ✅ fern #514 — AdamW β₁ warmup on aux groups — CLOSED 06:15 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS): A=3.27279, B=+0.00135 (null edge), C=+0.00162 (regression), D=+0.00252 (regression). Monotone-ish worsening with warmup aggressiveness. No arm passes stat-rule. **3rd consecutive "less constraint early" closure**: WD warmup (#483 NEGATIVE) + embed-LR warmup (#489 NEGATIVE) + β₁ warmup (#514 NEGATIVE) — bilateral closure across 3 aux-group AdamW schedule axes. Early-training window is uniformly well-tuned across WD/LR/β₁ at merged settings. **28th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#547 lm_head cooldown SHAPE sweep** — pivot from temporal (warmup) to shape (cooldown) axes.

### ✅ fern #584 — lm_head AdamW LR multiplier sweep around 1.0× — CLOSED 22:00 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27141−3.27174|=0.00033): A=3.27141 ctrl, B (0.70×)=+0.00028 (null), C (1.30×)=+0.00257 (regression), D (0.50×)=+0.00233 (regression). Flat→degradation profile bracketing 1.00× ctrl on both sides; no arm beats baseline. **Joint vocab-budget hypothesis falsified** at B=0.70× = 1/1.5. **Asymmetric LR cliff** — same |Δmult|=0.30 produces +0.00257 above vs +0.00028 below; lm_head sits closer to upper cliff. **Decoupling confirmed**: embed_mult=1.5 and lm_head_mult=1.0 have orthogonal optima. **40th productive-null/negative this cycle.**
**Follow-up**: fern assigned **#618 Muon² for lm_head** — replace AdamW with NS-orthogonalized momentum on the output projection (IDEA 6 from WAVE3, genuinely untested mechanism replacement vs all prior magnitude/formula/schedule/regularization perturbations).

### ✅ fern #618 — Muon² for lm_head — CLOSED 06:00 UTC productive-NEGATIVE

**Single-seed 4-arm (drift gate A PASS, |3.27313−3.27174|=0.00139)**:
| Arm | LM_HEAD_OPTIMIZER | LR | val/loss | Δ vs A | 3.28 target |
|---|---|---:|---:|---:|---|
| A | adamw (ctrl) | n/a | 3.27313 | — | ✅ pass |
| B | muon | 0.005 | 3.28460 | **+0.01147** | ❌ MISS |
| C | muon | 0.010 | 3.28043 | **+0.00730** | ❌ MISS (by 0.00043) |
| D | muon | 0.002 | 3.29285 | **+0.01972** | ❌ MISS (worst) |

**Monotonic-LR pattern**: higher Muon LR → smaller regression. No interior minimum in 0.002–0.010; optimum (if any) lies at LR ≥ 0.010 but +0.00730 gap is too wide to plausibly close. Mechanism: **NS-orthogonalization homogenizes the vocabulary-frequency Hessian structure** lm_head needs. AdamW's `m/√v` preserves Zipf-distributed per-coordinate magnitude scaling; Muon's unit-singular-value post-NS update has only LR-controlled spectral magnitude (no per-vocab-direction scaling). Block-heterogeneity analysis (Zhang et al. 2024) consistent: lm_head's Hessian is qualitatively distinct from inner-block Hessians, and spectral conditioning that helps inner blocks actively harms output projection. Implementation hygiene clean (drift +0.00139, NS transpose-trick verified for (50257, 768) tall matrix, wall-clock parity ±0.4%). **46th productive-null/negative this cycle. \"Replace AdamW for lm_head\" axis fully closed.**
**Follow-up**: fern assigned **#652 Per-group AdamW eps sweep on lm_head** — within-AdamW axis directly motivated by #618 mechanism reading. eps controls per-coordinate magnitude scaling (the exact mechanism #618 implicates as lm_head's bottleneck). Last untested per-group AdamW hyperparameter (β₁/β₂/WD/LR-mult all swept).

### ✅ fern #652 — Per-group AdamW eps sweep on lm_head — CLOSED 18:33 UTC productive-NEGATIVE

Single-seed 4-arm on NEW post-#579 stack (drift gate A PASS at favorable seed −0.00250): A eps=1e-10=**3.26820** ctrl, B eps=1e-8=+0.00191 (marginal regression), C eps=1e-6=+0.00217 (regression), D eps=1e-12=+0.00256 (regression, BARELY above baseline +0.00006). **Bilateral pattern**: both larger eps (B, C: SGD-like rare-token transitions) AND smaller eps (D: purer preconditioning) regress vs A — eps=1e-10 is bilaterally optimal on lm_head. No arm passes within-pod −0.002 threshold; best non-ctrl arm B at +0.00191 just above productive-null upper bound. OLD-stack rebase data preserved (A=B=3.27211 to 6dp) cleanly confirmed `sqrt(v_t) >> eps` dominates denominator for lm_head's typical v_t magnitudes ~1e-3 to 1e-1; eps inert across {1e-12, 1e-10, 1e-8, 1e-6} — confirming Zipf-scaling preservation is UPSTREAM of eps. Mechanism reading: per-group AdamW eps is NOT the bottleneck for lm_head per-coord magnitude scaling. Composes with #618 (Muon NEG) + #663 (SOAP NULL) + #547 (SHAPE NULL) + #584 (LR-mult NULL): ALL preconditioning-mechanism interventions on lm_head closed null/neg. **Per-group AdamW axis on lm_head is FULLY exhausted at the preconditioner level.** Future lm_head work should target representation/loss-side mechanisms. Implementation hygiene clean (10 LOC, env-var-gated, rebased cleanly, drift gate PASS, all 4 arms hit 3.28 target). **53rd productive-null/negative this cycle.** Per-group AdamW hyperparameter family is now fully characterized: β₁ #599 NEG, β₂ #560 NEG, WD #593 NULL, eps #652 NEG, BC #664 NULL — only LR-mult #393 MERGED extracted gain.
**Follow-up**: fern assigned **#709 body Muon momentum bias correction (enable)** — fresh axis on body Muon side never tested. Standard Muon does NOT apply bias correction `m_t/(1-β^t)` to its momentum buffer; this PR tests ENABLING it. Symmetric with #664's DISABLING AdamW BC (= NULL); body-Muon ENABLING BC has structurally different effect because the momentum buffer is then fed through Newton-Schulz orthogonalization. Mechanism: in first ~20 steps, m_t is biased toward zero relative to steady state at β=0.95; NS-orthogonalizing a biased buffer may give worse early-phase update direction. 4-arm sweep: A (off, ctrl), B (full training, decays naturally), C (first 50 steps only, aggressive early), D (first 200 steps, covers convergence to steady state). Mechanism: bias factor at step 1 is ~20× scaling; by step 50 ~1.05×; by step ~140 essentially 1.0.

### ✅ fern #709 — Body Muon momentum bias correction (enable) — CLOSED 02:50 UTC productive-NULL

**Branch:** `g1r4-fern/muon-momentum-bias-correction`

Single-seed 4-arm (drift gate A PASS, Δ=−0.00008):

| Arm | BC | window | val/loss | Δ_vs_A | Δ_vs_baseline |
|---|:--:|:---:|---:|---:|---:|
| A (ctrl) | 0 | — | 3.27062 | — | −0.00008 |
| B | 1 | full | **3.26918** | **−0.00144** | **−0.00152** |
| C | 1 | 50 | 3.27174 | +0.00113 | +0.00104 |
| D | 1 | 200 | 3.26958 | −0.00104 | −0.00112 |

**Mechanism reading**: BC factor 1/(1−μ^t) at μ=0.95: 20× at t=1, 1.0834× at t=50, 1.0060× at t=100, **1.0000 by step ~200**. The BC mechanism is effectively a first-200-step rescaling of the pre-NS momentum buffer. B (full) ≈ D (window=200) Δ_vs_A confirms — the BC effect is concentrated in the first ~200 steps regardless of window setting. Beyond step ~200, B and D are bit-identical to A.

**Verdict**: Sub-threshold (Δ_vs_baseline=−0.00152, below −0.002 winner threshold) AND mechanism-understood (early-step magnitude-only intervention; NS-orthogonalization absorbs the magnitude perturbation, leaving only second-order trajectory effects). Adds to "body Muon early-step magnitude rescaling" closed class (#126 Lookahead, #163 warmup-rescale, #419 init scale). NS-orthogonalization fundamentally compresses pre-NS magnitude information for body Muon. **60th productive-null/negative this cycle.**

**Follow-up**: fern assigned **#751 Cautious Optimizers** — sign-agreement mask on body Muon + aux AdamW (Liang et al. 2024). Fresh mechanism: per-coordinate update direction agreement, orthogonal to magnitude (clip, LR) and time (schedule) axes.

### ✅ fern #751 — Cautious Optimizers — CLOSED 11:10 UTC productive-NEGATIVE (65th cycle)

**Branch:** `g1r4-fern/cautious-optimizers`

**Terminal 4-arm N=1 result (drift gate A PASS Δ=+0.00086):**

| Arm | C_M / C_A | val/loss | Δ_vs_A | Verdict |
|---|:---:|---|---|---|
| A (ctrl) | 0/0 | 3.27156 | — | drift PASS |
| B (Muon-only) | 1/0 | 3.29528 | **+0.02372** | CATASTROPHIC REGRESSION |
| C (AdamW-only) | 0/1 | 3.28057 | **+0.00901** | LARGE REGRESSION |
| D (both) | 1/1 | 3.30245 | **+0.03089** | WORST (near-additive) |

**Mechanism (definitive)**: NS-orthogonalized updates have every coordinate mechanism-meaningful (unit-singular-value condition). Masking 38% and 2.3× rescaling survivors destroys spectral conditioning. Embed sub-group mask_frac≈0.43 (vs 0.65-0.71 for other groups) interacts destructively with EMBED_LR_MULT=1.5. D near-additive B+C confirming independent damage. Cautious-mask is incompatible with post-#579 stack — 3rd sign-aware update-mask mechanism to falsify (#126 element-wise, #629 layer-aggregate, #751 sign-agreement).

**Follow-up**: fern assigned **#787 Stochastic NS iter count** — variance-only uniform sampling of NS iter count per step (mean-preserving). Tests implicit regularization via NS-iter stochasticity. Fresh untested axis, mechanism-distinct from all in-flight.

### 📋 fern #787 — Stochastic NS iter count — SENT BACK 18:55 UTC for paired-pod n=3 on Arm C

**Branch:** `g1r4-fern/stochastic-ns-iter`

**Phase 1 N=1 4-arm results** (vs pre-#708 stack — student command had only GRAD_CLIP=10.0, missing per-group split):

| Arm | spread (mid, cd) | val/loss | Δ vs A (3.27080) | Δ vs new baseline 3.27036 | fs | W&B |
|:---:|:---:|---:|---:|---:|:---:|---|
| A (ctrl) | (0,0) | 3.27080 | — | +0.00044 (drift PASS) | 3225 | iydwo1yc |
| B | (2,0) | 3.27171 | +0.00091 | +0.00135 (sub-threshold regression) | 3225 | p6c1sp3k |
| **C** | **(0,2)** | **3.26906** | **−0.00174** | **−0.00130 ABS WIN n=1** | **3200** | **x0mwd2iy** |
| D | (2,2) | 3.26992 | −0.00088 | −0.00044 (sub-threshold mild gain) | 3225 | 0agxb3rj |

**Directional surprise**: PR's a-priori hypothesis predicted cooldown-stochasticity would HURT (precision argument). Arm C is in fact the BEST arm and Arm D is mildly positive. Cooldown was tolerant of iter-count jitter; mid-phase variance is mildly harmful. Note: with NS_COOLDOWN_SHAPE=late_peak, deterministic cooldown rises 12→20 across cooldown, and spread=2 on top samples across [10..22] effectively (W&B-verified).

**Sent-back protocol**: Paired-pod n=3 on Arm C (cd=2) vs Arm A (cd=0), now layered ON TOP of full post-#708 stack (adds NANOGPT_GRAD_CLIP_BODY=10.0, NANOGPT_GRAD_CLIP_AUX=5.0). 3 pods × 2 arms = 6 runs. Pre-staged merge gates: mean(C,n=3) ≤ 3.27036, stat-rule auto-passes, ≥2/3 direction-correct, drift gate ±0.003. ETA ~10.8h.

**Risk**: N=1 Δ_vs_A=−0.00174 sits exactly at the magnitude that has collapsed in 10 single-seed→paired-pod tests post-#579 on this stack. Speedrun improvement (−25 fs steps) is informative either way. If C confirms, mechanism is real and orthogonal to #708's per-group clip; if it collapses, axis closes cleanly.

### ✅ fern #547 — lm_head cooldown SHAPE sweep — CLOSED 14:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27273−3.27174|=0.00099): A linear=3.27273, B cosine=+0.00012 (null), C late_peak=+0.00179 (regression), D linear_floor=+0.00024 (null). No arm meets −0.002 threshold. **Cross-axis SHAPE transfer hypothesis falsified**: NS late_peak does NOT transfer to lm_head — lm_head wants monotonic decay (dense AdamW group with no mid-phase quality plateau analogous to NS orthogonalization). Reproduces #454 Arm B (linear_floor null). **Per-group cooldown SHAPE design space now substantially characterized**: embed=linear_floor (#235), body=linear (#520 NEG on alternatives), NS_iter=late_peak (#285), NS_coef=linear_ramp_down (#290), lm_head=linear (#547 NEG on alternatives); scalar gap untested. **35th productive-null/negative this cycle.**
**Follow-up**: fern assigned **lm_head AdamW LR ratio sweep** — denser sweep around 1.0× on post-#393 stack (untested space: #393 rejected lm_head=1.5× but <1.0× and intermediate values unexplored; joint vocab update budget mechanism predicts ~0.67×).

### 🔄 tanjiro #441 — Logit Z-loss (PaLM style) [assigned 06:49 UTC]

Loss-side: `loss += λ · Σ_t logsumexp(logits_t)²`. Arm A (control) terminal, B/C/D in progress. λ ∈ {0.0, 1e-5, 1e-4, 1e-3}.

### ✅ alphonse #442 — Adam-atan2 — CLOSED 17:53 UTC productive-NEGATIVE

b sweep {0.3, 1.0, 3.0}: all regress vs AdamW (b=0). D (b=3.0) misses 3.28 target (+0.010). Magnitude-transform of AdamW formula fully closed. **19th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#489 embed-only LR warmup**.

### ✅ alphonse #489 — Embed-only LR warmup — CLOSED 01:47 UTC productive-NEGATIVE

Monotone catastrophic worsening: A=3.27054, B=+0.01026 (frac=0.02), C=+0.01554 (frac=0.05), D=+0.02316 (frac=0.10). All 3 warmup arms fail benchmark (none reach 3.28 target). Full embed LR from step 0 is load-bearing — #102 closure rationale ("early high-LR window is productive") extends to embed AdamW despite mechanistic distinction (sparse-grad vs Muon+NS). **25th productive-null/negative this cycle.** Bilateral closure with #483 WD warmup (also productive-NEGATIVE): the early-training window is bilaterally well-tuned; regularization-REDUCTION by warmup on any group fails.
**Follow-up**: alphonse assigned **#526 embed LR step-0 boost** — inverse direction (boost above 1.5× at step 0, decay to merged 1.5×).

### ✅ alphonse #526 — Embed LR step-0 boost — CLOSED 09:30 UTC productive-NULL (bilateral with #489)

Single-seed 4-arm (drift gate A PASS, |3.27226−3.27174|=0.00052): A=3.27226, B (2.0×, 3%)=−0.00080 (null), C (2.5×, 3%)=−0.00081 (null), D (2.0×, 6%)=+0.00035 (null). B/C plateau identically (boost magnitude saturates by 2.0×); D regresses (longer 6% window mildly worse). Best arm (C) Δ_vs_A=−0.00081 far short of pre-staged −0.002 paired-pod threshold; the n=1 stat-rule "baseline beat" is partly Arm-A drift artifact. `first_step_to_target` invariant across A/B/C=3225. **Bilateral closure with #489**: combined evidence establishes embed step-0 LR at 1.5× is bilaterally optimal — neither boosting (this PR) nor reducing (#489 NEGATIVE) the early embed LR yields actionable improvement. **31st productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **#560 Per-group AdamW β₂ asymmetric sweep** — fresh axis on second-moment time constant (per-group cut of uniform-β₂=0.99 merged setting); motivated by embed-sparsity insights from #474 AdaBelief and #516 Yogi closures.

### ✅ alphonse #560 — Per-group AdamW β₂ asymmetric sweep — CLOSED 17:15 UTC productive-NULL/NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27121−3.27174|=0.00053): A=3.27121, B (β₂_embed=0.95)=+0.00089 (null), C (β₂_embed=0.999)=+0.00359 (regression), D (B + β₂_lm_head=0.999)=+0.00097 (null). No arm beats merged baseline within-pod. Longer embed memory clearly harmful (v_t anchors to early-training stats for ~700-step half-life in 3350-step run); shorter embed memory null (hypothesized sparse-row v_t reset benefit doesn't materialize). D ≈ B within ±0.0001 — lm_head β₂=0.999 inert. **AdamW-internal axis family substantially exhausted**: per-group β₂ joins #442 (magnitude), #474 (AdaBelief formulation), #516 (Yogi update rule), #490 (NAdam first-moment lookahead) as closed. Embed sparse-row gradient statistics on this benchmark are well-served by uniform β₂=0.99 in the 0.95–0.999 range. **38th productive-null/negative this cycle.**
**Follow-up**: alphonse assigned **per-group AdamW β₁ time-constant sweep** — first-moment time constant, structurally distinct from this PR's second-moment axis. Mechanism: at β₁=0.8 with sparse embed rows, momentum decays to near-zero between visits (`0.8^50 ≈ 0`), effectively scaling sparse-row step magnitude down by ~0.2 vs dense groups; ADAMW_EMBED_LR_MULT=1.5 partially compensates via LR; lowering β₁_embed tests whether it's a more principled magnitude restorer.

### ✅ alphonse #599 — Per-group AdamW β₁ time-constant sweep — CLOSED 01:10 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27208−3.27174|=0.00034): A=3.27208, B (β₁_embed=0.50)=+0.00399 (regression), C (β₁_embed=0.00, RMSProp-mode)=+0.00513 (regression), D (β₁_embed=0.90)=+0.00177 (regression marginal). All B/C/D regress past +0.0015 within-pod threshold. Magnitude-up direction (β₁ 0.80→0.50→0.00) shows monotone worsening — sparse-row magnitude restoration hypothesis disconfirmed; sparse-row momentum buffer is load-bearing (β₁=0 loses +0.005 vs ctrl). Smoothing-up direction (β₁=0.90) also marginal regression. **Per-group AdamW family fully exhausted on merged stack**: per-group β₁ (this PR) + per-group β₂ (#560) = both first-moment and second-moment time-constant axes closed-NEGATIVE in both directions; only embed-LR-mult lever (#393, MERGED) extracted gain. **44th productive-NEGATIVE this cycle.**
**Follow-up**: alphonse assigned **#632 Tunable post-NS aspect-ratio exponent** — post-NS-side modification targeting the canonical `max(1, fan_out/fan_in)**0.5` scaling in `muon_update()`. Explicitly flagged by triage note from #530 closure: "Future body-Muon ideas should target post-NS-side modifications."

### ✅ alphonse #632 — Tunable post-NS aspect-ratio exponent — CLOSED 21:00 UTC productive-NULL

**Branch:** `g1r4-alphonse/muon-post-ns-aspect-exp`

Paired-pod n=3 terminal — Pod 2 Arm D `s5argpey` finished val=3.26913 (Δ_D_vs_A=−0.00382 strong winner direction on Pod 2 alone):

| Pod | Arm A (exp=0.5 ctrl) | Arm D (exp=1.0) | Δ_D_vs_A | A-drift vs base 3.27070 |
|---|---:|---:|---:|---:|
| 0 | `f2fyfups` 3.27205 | `pvsxw7uy` 3.27203 | **−0.00002** | +0.00135 (mid, PASS) |
| 1 | `i793ei0g` 3.27049 | `zagy84ul` 3.27175 | **+0.00126** | −0.00021 (bullseye, PASS) |
| 2 | `v06cutf6` 3.27295 | `s5argpey` 3.26913 | **−0.00382** | +0.00225 (upper, PASS) |
| **mean** | **3.27183** | **3.27097** | **−0.00086** | sd=0.00264 |

**Gates**: Gate 1 (mean Δ ≤ −0.002) FAIL at −0.00086. Gate 2 (mean(val_D) ≤ 3.27070) FAIL at 3.27097 (+0.00027 above baseline). Gate 3 stat-rule (3.28−3.27097)×√3=0.01564 ≥ 0.004 PASS. **No merge.**

**Phase 1 N=1 → paired-pod collapse**: Phase 1 Δ_D_vs_A=−0.00274 → n=3 mean Δ=−0.00086 (~31% retention). 10th N=1→paired-pod collapse precedent post-#579. Pod-Δ tracks A-drift monotonically (D regresses when A favorable, D rescues when A unfavorable, D=A when A neutral) — canonical seed-coupling signature. Post-NS aspect-ratio exponent axis is **locally flat with high seed sensitivity** on post-#579 stack; default 0.5 is robust to ±0.5 perturbations on average. **Body-Muon update-magnitude-modification family uniformly null post-#579** (LR✓#579 / WD✗#669 / μ✗#674 / aspect-exp✗#632 / β₂🔄#712).

**58th productive-null/negative this cycle.**

### ✅ alphonse #719 — Pruning ablation of schedule mechanisms — CLOSED 05:15 UTC productive-NULL (64th cycle)

**Branch:** `g1r4-alphonse/prune-schedule-mechs`

Single-seed 4-arm N=1 complete; Phase 2 gate not reached (no arm Δ ≤ −0.001):

| Arm | Mechanism ablated | val/loss | Δ vs A | Verdict |
|---|---|---:|---:|---|
| A (ctrl) | none (full post-#579 stack) | 3.26943 | — | reference |
| B | NS_COOLDOWN_SHAPE=step (revert #285) | 3.27126 | **+0.00183** | confirmed essential |
| C | NS_COEF_SCHEDULE=constant (revert #290) | 3.27070 | +0.00127 | productive-null |
| D | EMBED_COOLDOWN_SHAPE=linear (revert #235) | 3.27190 | **+0.00247** | confirmed essential (largest delta) |

**Key findings**: EMBED_COOLDOWN_SHAPE=linear_floor has the LARGEST essentiality delta (+0.00247) — substantially greater than the +0.0003 predicted. NS_COEF_SCHEDULE is the least load-bearing (below essentiality threshold; productive-null candidate for future re-evaluation if stack shifts). No arm improves → no Phase 2. **Post-#579 stack is well-composed across all 3 schedule mechanism targets.** Schedule-mechanism pruning axis now FENCED (all 3 components characterized as net-positive).

**Follow-up**: alphonse assigned **#765 Soft-Muon NS/momentum blend** — Public Leaderboard #20 ingredient, convex blend of NS-orthogonalized update with normalized raw momentum direction. Fresh mechanism on r4 post-#579 stack (never tested here). W&B runs: sdbyszuw, 5gwf4x45, 49e7scir, yzrz5en6.

### ✅ alphonse #765 — Soft-Muon NS/momentum blend — CLOSED 14:00 UTC productive-NEGATIVE (69th cycle)

**Branch:** `g1r4-alphonse/soft-muon-blend`
**Result**: 4-arm terminal — A_ctrl=3.26947 (favorable drift), B α=0.95 +0.00422 REGRESSION, C α=0.90 +0.00220, D α=0.80 +0.00215. Non-monotone surface: smallest blend (5%) catastrophic local maximum; larger blends (10/20%) partially recover but never cross baseline. No arm passes merge gate. **Family closure**: body Muon "pre-NS state leakage" axis closed — NS-orthogonalization is a load-bearing one-way transform; pre-NS direction blending degrades cooldown convergence. Future body-Muon directional ideas should be fully pre-NS (gradient-side, e.g., #708) OR fully post-NS (NS-iter-count, e.g., #710/#787), not mixed.
**Follow-up**: alphonse assigned **#808 Distance-from-init weight decay for body Muon** — anchor WD at θ₀ (init snapshot) instead of zero. Fresh anchor-point axis distinct from all closed WD magnitude/schedule experiments (#483 warmup NEG, #506 cooldown NEG, #669 per-TYPE NEG, #593 per-group NULL/NEG). EWC-related but applied as plain L2 distance, not Fisher-weighted.

### 🔄 alphonse #808 — Distance-from-init weight decay for body Muon [assigned 14:00 UTC]

**Branch:** `g1r4-alphonse/distance-from-init-wd`
**Hypothesis**: Change WD anchor point from 0 to θ₀ (init snapshot). Standard WD pulls θ→0; distance-from-init pulls θ→θ₀, preserving the orthogonal-random init subspace that NS-orthogonalization relies on. All closed WD axes modify MAGNITUDE/SCHEDULE; this changes ANCHOR POINT (structurally distinct).

| Arm | NANOGPT_BODY_WD_ANCHOR | NANOGPT_BODY_MUON_WD | Description |
|:---:|:---:|:---:|:---|
| A | zero | 0.025 | Control (bit-identical merged) |
| B | init | 0.025 | Dist-from-init at baseline λ |
| C | init | 0.0125 | Dist-from-init at 0.5× λ |
| D | init | 0.05 | Dist-from-init at 2× λ |

Implementation: snapshot body Muon init weights at step 0; modify WD step from `p ← (1−lr·λ)·p` to `p ← (1−lr·λ)·p + lr·λ·p_init`. Memory: ~50MB for 24 body matrices. ETA ~7.3h.

### ✅ tanjiro #441 — Logit Z-loss sweep — CLOSED 17:00 UTC productive-NEGATIVE

Z-loss (PaLM style λ∈{1e-5,1e-4,1e-3}) regresses at all non-zero λ. D (λ=1e-3) fails benchmark (val=3.29393 > 3.28). Root cause: logit softcap c=15 already provides sufficient logit regularization — z-loss is redundant and competes at high λ. **18th productive-null/negative this cycle.** Loss-side auxiliary regularization axis fully closed.
**Follow-up**: tanjiro assigned **#487 cooldown-NS pruning ablation**.

### ✅ tanjiro #577 — NS-cooldown joint-pruning interaction test — CLOSED 09:05 UTC productive-NULL [paired-pod n=3, borderline-load-bearing]

**Phase 1 (N=1 sweep)** all four arms in null band: A=3.27312 ctrl, B=3.27278 (Δ=−0.00034 full joint drop), C=3.27184 (Δ=−0.00128 ITER-only), D=3.27217 (Δ=−0.00095 SHAPE+COEF drop). N=1 favored all drops slightly — classic favorable-seed pattern. **Phase 2 paired-pod (n=3, controlled SENPAI_SEED)**: Pod0 Δ=+0.00140, Pod1 Δ=+0.00175 (past +0.0015 threshold), Pod2 Δ=−0.00011 (favorable seed for both arms, val_A=3.27094 best across 5 Arm-A runs). **mean(Δ)=+0.00101** (null band, but 95% CI [−0.00013, +0.00215] brackets +0.0015); mean(val_B)=3.27301 > baseline 3.27174. Merge gates 1 and 2 FAIL. Formal classification: REDUNDANT (borderline) at n=3 — but seed-level evidence leans direction-incorrect (2/3 pods weakly-load-bearing). **7th cycle precedent for single-seed → paired-pod sign collapse** (joining #344, #351, #408, #487, #560, #593, #550). Combined with #487 single-component results, the merged stack's three NS-cooldown components are jointly weakly-load-bearing as a unit even though each is individually redundant; the interaction is not catastrophic but is direction-correct under controlled paired init. **49th productive-NULL this cycle.** NS-cooldown sub-stack pruning axis fully fenced; no further pruning attempts without n≥5 paired-pod evidence.
**Follow-up**: tanjiro initially assigned **#666 Lookahead optimizer wrapper for aux AdamW** — closed pre-launch as duplicate of #434 (edward, CLOSED productive-NEGATIVE; Arm B scope=adamw k=5 α=0.5 → Δ=+0.00244). Reassigned to **#668 per-row L2 gradient clip on embed and lm_head** — row-granularity magnitude bounding that operates pre-AdamW. Distinct from global clip (single norm), AGC (per-parameter), OrthoGrad (direction, not magnitude), and per-group eps (post-preconditioning). Directly tests row-level Zipf-asymmetry hypothesis from #618 mechanism reading.

### ✗ tanjiro #666 — Lookahead wrapper for aux AdamW — CLOSED-PRE-LAUNCH (duplicate of #434)

Bit-identical Arm B (k=5, α=0.5, scope=adamw) to #434 (edward, CLOSED productive-NEGATIVE 2026-05-19) which showed Δ=+0.00244 regression. Adding K=10 / α=0.8 corners (Arms C/D) would not plausibly flip from regression to merge-worthy gain per Zhang 2019 expected monotonicity. Closed before launch to avoid wasting compute.

### ✅ tanjiro #668 — Per-row L2 gradient clip on embed and lm_head — CLOSED 19:00 UTC productive-NEGATIVE

All 4 arms on post-#579 stack terminated. Drift gate Arm A PASS (val=3.27011, Δ=−0.00059 vs new baseline 3.27070). Arms B/C/D all in strong direction-incorrect band (Δ=+0.17340 / +0.17730 / +0.17592) — never reached 3.28 target. Mechanism: diagnostic row-norm percentiles showed lm_head.grad p50=13.11 vs embed.grad p50=0.0376 — ~350× magnitude asymmetry. Pre-declared threshold ladder {0.01, 0.1, 1.0} (chosen before measurement) sits 1–3 orders of magnitude below lm_head's typical row magnitude → every active arm hard-clips every lm_head row (factor 0.077 → 7.7e-3 → 7.6e-4). Under-fit feedback loop: lm_head pre-clip p50 grew 13.1 → 108–111 when clip active, confirming model adapts to under-trained lm_head by producing larger backprop errors which clip suppresses again. Strong closure of \"row-magnitude-aware intervention on aux groups\" axis composing with #408 AGC (NULL), #477 OrthoGrad (NULL), #618 Muon² lm_head (NEG), #663 SOAP-lm_head (NULL). **Pattern confirmed**: lm_head's per-row magnitude distribution carries Zipf-distributed signal that is load-bearing, not noise — any intervention that homogenizes / whitens / suppresses lm_head row magnitudes regresses training. **55th productive-null/negative this cycle.**
**Follow-up**: tanjiro assigned **#711 AggMo (Aggregated Momentum) for body Muon** — multi-timescale momentum buffers aggregated PRE-NS. Mechanism-distinct from all 500+ prior PRs (input-side body-Muon momentum-preparation axis, never tested). Tests passive damping via parallel β buffers: K=2 [0.0, 0.95], K=3 [0.0, 0.9, 0.99], K=3 [0.5, 0.9, 0.99].

### ✅ tanjiro #711 — AggMo (Aggregated Momentum) for body Muon — CLOSED 03:15 UTC productive-NEGATIVE

**Branch:** `g1r4-tanjiro/aggmo-body-muon`

Single-seed 4-arm (drift gate A PASS):

| Arm | NANOGPT_MUON_AGGMO_BETAS | K | mu_eff | val/loss | Δ_vs_A | Verdict |
|---|---|---:|---:|---:|---:|---|
| A (ctrl) | "0.95" | 1 | 0.95 | ~3.27 | — | baseline |
| B | "0.0,0.95" | 2 | 0.475 | +0.07438 | **+0.07438** | catastrophic regression |
| C | "0.0,0.9,0.99" | 3 | 0.630 | +0.05288 | **+0.05288** | strong regression |
| D | "0.5,0.9,0.99" | 3 | 0.797 | +0.02189 | **+0.02189** | hard regression |

**Monotone regression in mu_eff**: D (mu_eff=0.797 closest to baseline 0.95) is least bad but still +0.02189; B/C with low mu_eff catastrophic. **Mu_eff is the dominant lever, multi-buffer aggregation is neutral or net-harmful**. C-vs-D pair test: D−C=−0.03099 with mu_eff up by 0.167 — confirms mu_eff dominates aggregation. **Body Muon momentum buffer at β=0.95 is sharply bilaterally optimal**; AggMo's "passive damping" hypothesis falsified — Newton-Schulz already provides the stability AggMo claims to add for non-spectral optimizers (Lion/Adam).

**Pattern continuation**: 6th "complex Muon momentum modification fails" closure (#126 Contra-Soft, #530 Nesterov-Muon, #356 mu schedule, #674 per-block-TYPE mu, #717 Adan, #711 AggMo). Body Muon's pre-NS first-moment buffer is structurally fragile to any deviation from single-buffer EMA at β=0.95.

**61st productive-null/negative this cycle.**

**Follow-up**: tanjiro assigned **#752 Gradient Centralization (Yong 2020)** — per-row mean subtraction on pre-NS / pre-AdamW gradients. Fresh axis: GC orthogonalizes against constant vector (1ᵀ direction) per row, structurally distinct from NS-orthogonalization (singular-value normalization) and OrthoGrad (#477, against parameter direction). Mechanism is spatial (per-row) not temporal (momentum). ~5 LOC implementation.

### ✅ tanjiro #752 — Gradient Centralization (Yong 2020) — CLOSED 11:24 UTC productive-NEGATIVE (66th cycle)

**Branch:** `g1r4-tanjiro/gradient-centralization`

**Terminal 4-arm N=1 result (drift gate A PASS at Δ=−0.00012):**

| Arm | gc_muon / gc_adamw | val/loss | Δ_vs_A | Δ_vs_baseline | fs_to_target | Verdict |
|---|:---:|---|---|---|---|---|
| A (ctrl) | 0 / 0 | 3.27058 | — | −0.00012 | 3225 | drift PASS |
| B (Muon only) | 1 / 0 | 3.27250 | +0.00192 | +0.00180 | 3250 | **regression** |
| C (AdamW only) | 0 / 1 | 3.27167 | +0.00109 | +0.00097 | 3225 | sub-threshold null |
| D (both) | 1 / 1 | 3.27281 | +0.00223 | +0.00211 | 3250 | **regression (sub-additive)** |

W&B: A=066vqhon, B=eju4vxds, C=ivoigede, D=bh4ruhj8.

**Mechanism**: GC removes rank-1 constant-mode component from gradient before NS. NS-orthogonalization already reshapes singular structure; removing constant-mode erases signal the NS path was relying on. B/D cross regression gate; C sub-threshold null (same direction). D sub-additive vs naive B+C sum — shared information-removal pathway. **Constant-mode-per-row subspace is NOT a removable nuisance on this stack.** 'Remove rank-1 from gradient' mechanism family DEPRIORITIZED (per-column GC, layer-norm-style centralization likely share this fate). Spatial additive variants (per-row variance whitening, gradient covariance preconditioning) still open.

**Follow-up**: tanjiro assigned **#789 NS polynomial degree swap (cubic vs quintic)** — first test of NS polynomial DEGREE on this stack. 4-arm: cubic FLOP-equivalent (NS=18/24), same-iter-count (NS=12/16), 2× iters (NS=24/32) vs quintic control. Mechanism-distinct from all in-flight NS experiments (#787 stochastic, #710/#724 per-depth/type).

### 🔄 tanjiro #789 — NS polynomial degree: cubic vs quintic FLOP-equivalent sweep [assigned 11:30 UTC]

**Branch:** `g1r4-tanjiro/ns-polynomial-degree`
**Hypothesis**: Current NS uses quintic polynomial `f(s) = a + b·s + c·s²` (3 matmuls/iter). Cubic `f(s) = 1.5 − 0.5s` uses only 2 matmuls/iter. At FLOP-equivalent budget (cubic×18 = quintic×12 matmuls), cubic and quintic apply identical total compute but with different convergence trajectories. First test of NS polynomial DEGREE on this stack — all prior NS experiments vary iter count or coefficient schedule WITHIN the quintic family.

| Arm | NS_DEGREE | NS_ITERS (mid / cooldown) | Description |
|---|:---:|:---:|---|
| A (ctrl) | 5 (quintic) | 12 / 16 | Current merged baseline |
| B | 3 (cubic) | 18 / 24 | FLOP-equivalent (18×2 = 12×3 matmuls) |
| C | 3 (cubic) | 12 / 16 | Same iter-count, 33% fewer matmuls |
| D | 3 (cubic) | 24 / 32 | 2× iters, ~33% more total matmuls |

ETA ~7.3h. Implementation: ~20 LOC (cubic branch `for _ in range(ns_iters): A = X@X.T; X = 1.5*X - 0.5*(A@X)` inside `zeropower_via_newtonschulz5`). NS_COEF_SCHEDULE=linear_ramp_down inert for degree=3 (c=0). Decision gates: Δ ≤ −0.002 → paired-pod n=3; sub-threshold → productive-NULL; any Δ ≥ +0.0015 → arm regression.

### ✅ tanjiro #487 — Cooldown-NS pruning ablation — CLOSED 13:05 UTC productive-NULL [paired-pod n=3]

Sweep N=1 Arm B (drop NS_ITERS_COOLDOWN) Δ=−0.00385 winner candidate failed paired-pod confirmation: per-pod Δ split 1−/2+ around mean(Δ)=+0.00003, all three pods in productive-null/redundant band [−0.002, +0.0015]. Merge gates 1 (mean Δ) and 2 (mean val_B) fail; only stat-rule (gate 3) passes. **4th cycle precedent for single-seed → paired-pod collapse** (joining #344, #351, #408 AGC). Mechanism hypothesis (NS_ITERS_COOLDOWN over-orthogonalizes late-phase) falsified — within-pod effect is essentially zero. The N=1 winner was between-seed noise. **33rd productive-null this cycle.** All three NS-cooldown sub-stack components are now individually classified as redundant (B=redundant at n=3 paired-pod, C/D=null at N=1 sweep).
**Follow-up**: tanjiro assigned **NS-cooldown joint-pruning ablation** — joint-drop interaction test of the sub-stack.

### ✅ thorfinn #446 — Label smoothing sweep — CLOSED 15:38 UTC productive-NEGATIVE

Strictly monotone regression: A=3.27326 (ctrl), B=3.31900 (+0.046), C=3.37495 (+0.102), D=3.49666 (+0.223). B/C/D never reached 3.28 target. The merged stack already has three confidence-pressure regularizers (logit softcap=15, embed_lr_mult=1.5×, NS cooldown) — adding label smoothing subtracts gradient signal on already-regularized correct-token targets. **17th productive-null/negative this cycle.** Regularization-addition axes are fully closed.
**Follow-up**: thorfinn assigned **#483 WD warmup schedule** — first regularization-REDUCTION test this cycle.

### ✅ thorfinn #483 — WD warmup schedule (Muon block group) — CLOSED 23:42 UTC productive-NEGATIVE

Clean monotone worsening: A=3.27066, B=+0.00080 (null), C=+0.00258 (regression), D=+0.00400 (regression). Body-block WD=0.025 is load-bearing from step 0 — delaying it hurts. **24th productive-null/negative this cycle.** Bilateral closure: 17 ADD-regularization axes + 1 REDUCE-regularization axis both fail → Muon-WD=0.025 is bilaterally optimal.
**Follow-up**: thorfinn assigned **#520 Body Muon LR cooldown shape sweep** — alternative profiles over the load-bearing 30% cooldown window.

### ✅ thorfinn #520 — Body Muon LR cooldown shape sweep — CLOSED 07:55 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A linear=3.27261, B cosine=+0.00163 (marginal regression), C quadratic=+0.00864 (strong regression, fst=-1), D linear_floor=+0.01401 (strongest, fst=-1). Monotone with non-linear distortion of the final-window decay. **Mechanism**: body Muon needs (1) decay to ~zero at end, (2) linear shape (not steeper, not slower). NS-orthogonalized updates have rank-stable magnitudes — late-phase convergence requires actual zero LR to land. **Striking per-group cooldown contrast**: embed wins with linear_floor (#235), body LOSES strongest with linear_floor — different update statistics demand different profiles. Per-group cooldown-shape design axis substantially characterized (lm_head #547 in flight completes the matrix). **30th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#554 AdamW embed WD cooldown nudge** — adds small positive WD on embed during cooldown only (currently WD=0). Tests whether late-phase implicit regularization on sparse-row embed group helps; structurally distinct from edward #550 (Muon WD REDUCTION, body group, removes existing).

### ✅ thorfinn #590 — NS-cooldown START_FRAC sweep — CLOSED 23:50 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27089−3.27174|=0.00085): A=3.27089, B (0.50)=+0.00187 (regression), C (0.85)=+0.00132 (null), D (0.60)=−0.00041 (null sub-threshold). FRAC axis is **bilaterally concave at 0.70** with flat 0.60-0.70 shoulder. Mechanism reading: NS=16 only pays off in final ~25-30% of training; extending the window earlier (B) wastes compute on mid-phase steps that don't benefit from tighter orthogonalization, shortening (C) loses late-phase precision gain. The favorable A-drift (−0.00085) inflates D's apparent baseline improvement; within-pod Δ_vs_A=−0.00041 is far below the −0.002 candidate threshold. Closes off both "extended precision window" and "concentrated late NS=16 burst" follow-up directions. Full NS-cooldown sub-stack: magnitude=#176 (MERGED), shape=#285 (MERGED), coef=#290 (MERGED), timing=#590 (CLOSED). **41st productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **#624 spectral norm penalty (WAVE3 IDEA 8)** — loss-side weight conditioning regularizer, structurally fresh axis no prior experiment has touched. After 41 productive-NULLs on optimizer-state and update-direction axes, pivot to loss-formulation axis.

### ✅ thorfinn #624 — Spectral norm penalty (loss-side weight conditioning) — CLOSED 06:10 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27261−3.27174|=0.00087): A=3.27261, B (λ=1e-5 all)=3.27216 (Δ=−0.00045, null), C (λ=5e-5 all)=3.27155 (Δ=−0.00106, null sub-threshold), D (λ=1e-5 attn_only)=3.27408 (Δ=+0.00147 marginal regression). **Monotone-favorable** in λ across all-scope arms (A→B→C: +0.0 / −0.00045 / −0.00106) but best magnitude is half the −0.002 candidate threshold; D regression on attn-only narrowest-scope informs mechanism. **Mechanism findings**: (a) spectral norm penalty is benign-mild on body Muon 2D matrices — never approaches catastrophic regression even at 5e-5 (5× the working range); (b) **body MLP matrices benefit more from spectral conditioning than attention matrices** (D attn-only regresses while B all-scope improves marginally), suggesting MLP layers were closer to singular-value concentration than attention; (c) the NS-conditions-update-direction-not-weight reading was directionally validated but quantitative impact too small to merge. Implementation hygiene clean (id()-intersection filter for spectral_params shadow set works, power-iteration v persistent across steps, ~3% overhead reproducible). **47th productive-null/negative this cycle.** "Loss-side weight regularization" axis (closest analog to WD but on σ_max² vs ‖W‖_F²) now characterized — penalizes only dominant singular values rather than all uniformly; the substantive distinction from WD shows up as direction-correct sub-threshold gain not a structural win. **Durable finding (cross-experiment reusable)**: id()-intersection filter pattern for restricting param-list operations to the body Muon 2D subset works cleanly when applied to penalty/regularization-style passes — a pattern future loss-side or post-NS modifications can reuse.
**Follow-up**: thorfinn assigned **#663 one-sided SOAP for lm_head** — WAVE3 IDEA 2, last untested WAVE3 idea. Fresh preconditioner mechanism distinct from #618 Muon-for-lm_head (NS homogenizes Zipf-distributed magnitudes) because SOAP preserves Adam's m/√v in rotated eigenbasis. Complementary to fern #652 in flight.

### ✅ thorfinn #663 — One-sided SOAP preconditioning for lm_head — CLOSED 18:30 UTC productive-NULL

Single-seed 4-arm on NEW merged stack post-#579 (drift gate A' PASS, |3.26762−3.27070|=0.00308 at upper edge but within envelope): A'=3.26762, B (FREQ=50)=+0.00174 (regression), C (FREQ=25)=+0.00325 (regression, worst), **D (FREQ=100)=3.26666 (Δ_D_vs_A'=−0.00096 sub-threshold, val=−0.00404 below baseline)**. **Monotone frequency trend**: less SOAP rotation = better; optimum extrapolates to FREQ→∞ (= AdamW, no rotation). Δ_D_vs_A' = −0.00096 sub-threshold (well below −0.002 within-pod gate); single-seed magnitude inside 8+ paired-pod-collapse range this cycle. Mechanism: AdamW's coord-basis is near-optimal for lm_head — SOAP's eigenbasis rotation perturbs a basis the optimizer has already self-tuned via β₂=0.99 + LR_MULT=1.0 over Zipf-distributed vocabulary structure. **Composes with #618 NEG (full Muon for lm_head, NS destroys Zipf scaling): both spectral conditioning interventions on lm_head — orthogonalization and eigenbasis rotation — failed**. lm_head's Hessian is structurally distinct from inner-block Hessians and resists every form of spectral conditioning intervention tested. Future lm_head work should target representation/loss-side mechanisms (Zipf-weighted loss, frequency-aware label smoothing, output-projection low-rank decomp), not preconditioner replacements. Extreme aspect ratio (65:1) wrong regime for SOAP — left/right preconditioner stale-eigenvector amortization assumes near-square matrices. Implementation hygiene clean (108 LOC additive behind NANOGPT_SOAP_LM_HEAD_FREQ env var, +0.32% wall-clock at FREQ=100, all 4 arms hit 3.28 target). **52nd productive-null/negative this cycle. WAVE3 IDEA-by-IDEA portfolio fully closed** (7/8 ideas tested; only IDEA 1 Polar Express never assigned; 4 of 7 NULL/NEGATIVE, 1 of 7 MERGED via #579 — but #579 was a NEW axis discovered during WAVE3 execution, not on the WAVE3 list). Strong signal: **mechanism progress now from per-block-TYPE asymmetry family** (#669 WD / #674 momentum testing) rather than aux-group preconditioner replacements.
**Follow-up**: thorfinn assigned **#708 per-group gradient clip threshold asymmetry** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669 / #674). Tests body-Muon clip vs aux-AdamW clip split (currently uniform NANOGPT_GRAD_CLIP=10.0). Body gradients pass through NS-orthogonalization (which renormalizes spectral magnitudes); aux gradients are sparse-row Zipf-distributed and AdamW preserves per-coord magnitude — these two distributions have different "natural" outlier ranges and a single global threshold is suboptimal.

### ✅ thorfinn #708 — Per-group gradient clip threshold asymmetry — MERGED 14:31 UTC WINNER (baseline now 3.27036)

**Branch:** `g1r4-thorfinn/per-group-grad-clip-asym`
**Mean(B,n=3)=3.27036, fs=3216.67. Gates: stat-rule 0.01669≥0.004 PASS, baseline beat −0.00034 PASS, drift +0.00106 PASS.**
Pods: pod0 Δ=−0.00112, pod1 Δ=−0.00334 (STRONG), pod2 Δ=+0.00026 (sign-flip). 2/3 pods direction-correct.
Mechanism: tighter aux L2 clip bounds per-coord outlier propagation in AdamW `m/√v`. Body Muon insensitive (NS renormalizes spectral direction). Adds `NANOGPT_GRAD_CLIP_BODY=10.0 NANOGPT_GRAD_CLIP_AUX=5.0` to merged stack.

### 🔄 thorfinn #812 — Orthogonal Haar-measure init for body Muon matrices (4-arm) [assigned 14:46 UTC]

**Branch:** `g1r4-thorfinn/ortho-body-init`
**Hypothesis:** Replace `normal(std=0.33^0.5/sqrt(out_features))` init on q/k/v/mlp.fc body Muon matrices with `torch.nn.init.orthogonal_(gain)`. Orthogonal init gives well-conditioned singular value spectrum from step 0, reducing ill-conditioned early-step gradients. Gain sweep: A=0.0 (ctrl), B=0.57 (Frobenius-norm matched), C=0.33 (smaller), D=1.0 (full spectral norm). ~7.3h ETA.

### ✅ thorfinn #554 — AdamW embed WD cooldown nudge — CLOSED 15:35 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, |3.27277−3.27174|=0.00103): A=3.27277, B (0.001)=−0.00035 (null edge, fails baseline parity +0.00068), C (0.005)=+0.00657 (regression), D (0.010)=+0.01571 (regression, **FAILS 3.28 target**). Clean monotone regression — any embed WD during cooldown is harmful. Mechanism: with EMBED_COOLDOWN_SHAPE=linear_floor holding embed LR at 15% floor, embed updates are already small; adding WD uniformly shrinks rarely-updated rare-token rows whose representations depend on *accumulated information*. **Bilateral asymmetry on WD-cooldown axis** (paired with #550 winner candidate): embed group rejects added WD during cooldown (NEGATIVE), body Muon group may benefit from REDUCED WD during cooldown (#550 N=1 winner, paired-pod confirming). Both point to "do not constrain rare/sparse representations during cooldown precision window". **36th productive-null/negative this cycle.**
**Follow-up**: thorfinn assigned **NS-cooldown START_FRAC sweep** — fresh untested axis. NS_COOLDOWN_START_FRAC=0.7 was bundled at #176 merge, never independently swept on merged stack.

### ✅ askeladd #452 — Block output projection init scale — CLOSED 05:05 UTC productive-null

Paired-pod confirmation: Arm B (s=0.5) pod-0 candidate Δ=−0.00227 reversed → mean(Δ_pool)=+0.00068 across n=3 pods. 4th paired-pod false-positive caught this cycle (after #344, #351, #408 AGC). DeepNet/T-Fixup family init-scaling axis closed: NS-normalized Muon updates wash out init scaling within first ~100 steps as hypothesized — but no preserved benefit signal. **27th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **#543 per-block NS iter budget** — spatial allocation by aspect ratio (Bernstein-Newhouse). (#542 Lion-aux mis-assignment closed 05:12 UTC — Lion on aux groups already closed in #77, prior round.)

### ✅ askeladd #669 — Per-block-type WD asymmetry on body Muon — CLOSED 19:40 UTC productive-NEGATIVE

**Branch:** `g1r4-askeladd/muon-attn-mlp-wd-asym`

| Arm | attn_wd_mult | mlp_wd_mult | val/loss | Δ vs baseline | within-pod Δ vs A | Verdict | W&B |
|---|---:|---:|---:|---:|---:|---|---|
| A (ctrl) | 1.0 | 1.0 | 3.26835 | −0.00235 (drift PASS, favorable seed) | — | baseline | `ml6f98zt` |
| B | 1.0 | **0.0** | 3.28602 | **+0.01532** | **+0.01767** | **NEGATIVE** | `2a6apjqx` |
| C | **0.0** | 1.0 | 3.27007 | −0.00063 | +0.00172 | marginal-null | `uinfzkf9` |
| D | **0.0** | **0.0** | 3.28751 | **+0.01681** | **+0.01916** | **NEGATIVE** | `k7u4nli7` |

**Key finding**: mlp WD=0.025 is load-bearing (Arm B regression +0.01532); attn WD=0.025 is approximately null (Arm C marginal-null at +0.00172 within-pod). The per-block-type partition shows an asymmetry BUT in the load-bearing direction: mlp needs WD, attn is indifferent. Post-#579 with mlp_lr_mult=1.20 raising mlp effective updates, mlp WD becomes MORE load-bearing. Bilateral WD-reduction fence now closed.

**Per-block-type Muon family**: LR ✅ MERGED (#579) | WD ✗ NEGATIVE (#669) | μ ✗ NULL (#674) | β₂ 🔄 (#712 in flight) | NS_ITERS per-type: unexplored

**57th productive-null/negative this cycle.**

### ✅ askeladd #717 — Adan body Muon — CLOSED 04:30 UTC productive-NEGATIVE

**Branch:** `g1r4-askeladd/adan-body-muon`

Single-seed 4-arm result (drift gate A PASS at +0.00030):

| Arm | β₁ | β₂ | β₃ | val/loss | Δ_vs_A | Band |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl, heavy-ball+v.sqrt) | — | — | — | 3.27040 | — | drift PASS |
| B (Adan default) | 0.98 | 0.92 | 0.99 | 3.28238 | **+0.01198** | strong regression (fst=−1, miss 3.28) |
| C (β₂=0, no diff) | 0.98 | 0.00 | 0.99 | 3.28461 | **+0.01421** | worst regression (fst=−1, miss 3.28) |
| D (β₃=0.999) | 0.98 | 0.92 | 0.999 | 3.27927 | **+0.00887** | hard regression (fst=3350 at-target) |

**Mechanism reading** (student's insightful analysis):
1. **B-vs-C (+0.00223)**: gradient-difference term DOES help within Adan framework — direction-correct mechanism reading
2. **D-vs-B (+0.00311)**: β₃=0.999 (matching current Muon β₂) required — paper's 0.99 too short for this stack
3. **Best Adan (D) loses by +0.00887** — structural change from `m_nesterov/(sqrt(v)+ε)` → `(m + β₂·v_adan)/(sqrt(n)+ε)` is what costs the points; Nesterov-correction structure on the NUMERATOR (not folded inside denominator-normalizer) is load-bearing

**Pattern continuation: 7th 'complex Muon momentum modification fails' closure** — #126/#530/#356/#674/#711/#712/#717. **Pre-NS Muon momentum buffer is now FULLY FENCED**: any modification beyond `m_nesterov(β=0.95) / (sqrt(v_t, β=0.999) + ε)` regresses.

**Hygiene acknowledgement**: Arm C W&B init crash + waiter-script for re-launch handled cleanly by student. Good defensive engineering practice.

**63rd productive-null/negative this cycle.**

**Follow-up**: askeladd assigned **#755 LARS-style trust-ratio LR scaling for body Muon** — per-PARAM runtime LR adaptation via `tr = ‖θ‖_F / (‖update‖_F + ε)` clamped. Mechanism-distinct from all closed Muon momentum modifications AND all bucket-based asymmetry experiments. Distinct from #628 (cos-EMA direction-agreement, NULL) which used DIRECTION not MAGNITUDE ratio. Composes orthogonally with #579 per-block-TYPE LR (MERGED) — both layers multiplicative.

### ✅ askeladd #755 — LARS-style trust-ratio LR scaling for body Muon — CLOSED 13:13 UTC productive-NULL (68th cycle)

**Branch:** `g1r4-askeladd/lars-trust-ratio-muon`
**Result**: B (moderate clamp 0.5-2.0) Δ_vs_A=−0.00056 sub-threshold NULL. C (wide clamp 0.25-4.0) catastrophic REGRESSION (+0.01022). D (EMA β=0.9) essentially no-op (−0.00002). **3rd update-magnitude LR-adaptation closure**: #628 (cos-EMA direction) + #688 (ratio-EMA) + #755 (LARS). NS normalizes ‖update‖_F ≈ const per matrix; trust ratio variation from ‖θ‖_F growth is small/uniform at GPT-117M scale. Per-block-TYPE LR #579 already captured all per-matrix asymmetry headroom.
**Family closed**: Update-side per-matrix LR scaling (direction/magnitude/EMA) mechanism-empty post-#579. **DEPRIORITIZED**.
**Follow-up**: askeladd assigned **#801 Position-aware CE — per-position loss weighting (4-arm)** — fresh loss-side gradient redistribution. Distinct from focal loss (#791, per-example confidence), label smoothing (#446 NEG), z-loss (#441 NEG). First test on position-index axis.

### 🔄 askeladd #801 — Position-aware CE: per-position loss weighting [assigned 13:27 UTC]

**Branch:** `g1r4-askeladd/position-weighted-ce`
**Hypothesis**: Weight token-level CE by scalar w(t) that depends only on sequence position t ∈ 0..T-1. Normalized to mean(w)=1 to preserve total gradient magnitude. B: linear_up α=0.5 (late upweight, w: 0.8→1.2). C: linear_down α=0.5 (early upweight, w: 1.2→0.8). D: linear_down α=1.5 (strong early upweight, w: 1.43→0.57). Mechanism-distinct from #791 focal (per-example confidence), #446 label smoothing (target distribution), #441 z-loss (logit penalty).
| Arm | SHAPE | ALPHA | w at t=0 | w at t=1023 |
|:---:|:---:|:---:|:---:|:---:|
| A | uniform | 0.0 | 1.00 | 1.00 |
| B | linear_up | 0.5 | 0.80 | 1.20 |
| C | linear_down | 0.5 | 1.20 | 0.80 |
| D | linear_down | 1.5 | 1.43 | 0.57 |

### ✅ askeladd #579 — Body Muon LR asymmetry (attn=0.80×, mlp=1.20×) — MERGED 09:55 UTC 🏆

**Branch:** `g1r4-askeladd/muon-attn-mlp-lr-asym`

**Phase 1 single-seed 4-arm** (drift gate A PASS, |3.27189−3.27174|=0.00015): A=3.27189 ctrl, B (0.80, 1.00)=+0.00083 null, C (1.00, 1.20)=+0.00080 null, **D (0.80, 1.20)=3.27052 (Δ=−0.00137, signal sub-threshold)**. Pre-staged singleton-null/compound-signal pattern fires exactly.

**Phase 2 paired-pod n=3 confirmation** (3350 steps, locked merged-stack envs, free seeds across pods):
| Pod | A val | D val | Δ_pod |
|---|---:|---:|---:|
| 0 | 3.27286 | 3.27317 | +0.00031 (sign-flip, tiny) |
| 1 | 3.27154 | 3.26897 | −0.00257 (signal) |
| 2 | 3.27178 | 3.26996 | −0.00182 (signal) |
| **mean(n=3)** | **3.27206** | **3.27070** | **−0.00136** |

**Merge gate decision (CLAUDE.md "when in doubt, merge"; direct precedent #393 merged at near-identical paired-pod Δ=−0.00137)**:
- Gate 1 within-pod mean Δ ≤ −0.002: FAIL at −0.00136 (sub-threshold)
- Gate 2 μ_D ≤ baseline 3.27174: **PASS** at 3.27070 (−0.00104 absolute)
- Gate 3 stat-rule (3.28 − 3.27070) × √3 = 0.01611 ≥ 0.004: **PASS**
- Drift gates: pod0-A=+0.00112, pod1-A=−0.00020, pod2-A=+0.00004 — all 3 within ±0.003 ✓

Direction-correct 2/3 pods, μ_D beats baseline by 0.00104 absolute. **Merged per project-level statistical rule**, mirroring #393 precedent at virtually identical magnitude.

**Mechanism**: NS-orthogonalization normalizes spectral direction per-matrix but not relative scale across matrix-types. Attn matrices benefit from conservative effective step (less attention-routing jitter); MLP matrices benefit from larger step (better gradient signal extraction). Singletons sub-threshold but compose under combined application — a true interaction effect signature, not magnitude addition. `first_step_to_target` improved: μ_A=3233.3 → μ_D=3225.0 (−8.3 steps consistent with val improvement).

W&B group `g1r4-askeladd/muon-attn-mlp-lr-asym-paired-pod` — D runs: `xba0kue2`, `a861snwz`, `vg8dkwf3`.

**New merged envs**: `NANOGPT_MUON_ATTN_LR_MULT=0.80 NANOGPT_MUON_MLP_LR_MULT=1.20`. 9th merged improvement this cycle.

### ✅ askeladd #543 — Per-block NS iter budget — CLOSED 13:35 UTC productive-NULL

Single-seed 4-arm sweep (drift gate A PASS, |3.27243−3.27174|=0.00069): A uniform=3.27243, B aspect=+0.00077 (null), C manual_typeA=−0.00017 (null, best), D manual_typeB=+0.00056 (null). All 3 reallocation arms in productive-null band [−0.002, +0.0015]. NS=12 saturation **robust to spatial reallocation** — combined with #470 uniform escalation finding, NS-iter count is genuinely saturated at this budget. Architectural finding (student-documented): codebase uses split-qkv naming (`attn.q`/`attn.k`/`attn.v` all 768×768 square) — only 2-of-6 Muon blocks (`mlp.fc`, `mlp.proj`) have aspect > 1.0, limiting the spatial reallocation surface. **34th productive-null/negative this cycle.**
**Follow-up**: askeladd assigned **Body Muon LR asymmetry (attn vs mlp split)** — per-block-TYPE LR axis (vs #543 per-block iter), structurally distinct from #393 (AdamW per-group LR) and #409 (LLRD depth-LR).

### ✅ nezuko #454 — lm_head/scalar cooldown shape extension — CLOSED 18:05 UTC productive-null

Arms B/C/D (lm_head_floor, scalar_floor, both): best Δ=−0.00098 (arm B), half the −0.002 threshold. Arm D (stacked) regresses +0.00072 vs A, indicating cross-group interaction at end-of-cooldown. **linear_floor is embed-specific** (sparse-row coverage benefit), not aux-generic. Three prior paired-pod false-positives (#344, #351, #408 AGC) support conservative close. **20th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#490 NAdam (Nesterov-AdamW) scope sweep** — first-moment reformulation, first Adam-family axis we haven't tested.

### ✅ nezuko #490 — NAdam (Nesterov-AdamW) scope sweep — CLOSED 02:15 UTC productive-null

Arms B (embed: Δ=−0.00059, mild +), C (lm_head: Δ=+0.00063, mild −), D (all_aux: Δ=+0.00275, regression). Best arm B well within null band (need ≤−0.002); D's compounded regression suggests scalar group is bad actor under NAdam (aggressive direction-change due to normalization layers). **26th productive-null/negative this cycle.** Closes the first-moment axis of the AdamW-internal three-axis ablation (magnitude #442 NEGATIVE, first-moment #490 null/regress, second-moment #474 NEGATIVE) — **AdamW-internal axis family substantially exhausted on merged stack**.
**Follow-up**: nezuko assigned **#530 Nesterov-Muon body scope sweep** — structurally parallel test on Muon body momentum (lookahead before NS).

### ✅ nezuko #530 — Nesterov-Muon body scope sweep — CLOSED 10:15 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27253−3.27174|=0.00079): A α=0.95=3.27253, B α=0.00 (bypass)=+0.00630 (regression), C α=0.50 (half-mix)=+0.04114 (severe, target NOT reached), D α=0.99 (over-Nesterov)=+0.00060 (null). **Structural finding**: the cliff is on the *low-α* side (NS-stability breakdown when current-grad weight >>0.05); the plateau is on the *high-α* side (Arm D within noise). α=μ=0.95 sits at boundary of safety — the mix is best understood as a tiny anti-staleness injection (~5% current-grad on top of 95% EMA), small enough to stay in NS's well-behaved spectral domain. Heavier current-grad injection pushes the NS input outside the Newton-Schulz polynomial's well-conditioned regime. **5th body-Muon mechanism axis closed** (joins #102 LR warmup, #356 μ schedule, #434 Lookahead-wrap, #483 WD warmup). Body Muon algorithmic axes on the merged stack are largely exhausted — future body-Muon ideas should target architectural changes (post-NS-side modifications, NS-iteration-count interactions). **32nd productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#568 Per-group cooldown_frac decoupling** — fresh structural axis on per-group cooldown WINDOW LENGTH (vs per-group cooldown SHAPE which is largely characterized).

### ✅ nezuko #568 — Per-group cooldown_frac decoupling — CLOSED 18:40 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS, |3.27134−3.27174|=0.00040): A=3.27134, B (embed=0.80)=−0.00014 (null), C (embed=0.60)=**+0.00242 (regression)**, D (body=0.80)=−0.00067 (null, best). No arm crosses −0.002 signal threshold. Best arm D passes single-seed stat-rule at n=1 ((3.28−3.27067)×√1=0.00933 ≥ 0.004) AND beats baseline (3.27067 ≤ 3.27174), BUT within-pod Δ=−0.00067 short of pre-staged paired-pod gate. Embed direction asymmetric-monotonic with floor at 0.70 (shortening hurts; lengthening gives only sub-threshold improvement). Body direction mildly positive sub-threshold (NS-orthogonalized landing benefits *mildly* from longer precision-window but not enough at ±0.10 perturbation). **SHAPE→FRAC analogy fails at this perturbation scale**: per-group cooldown SHAPE matters (real asymmetry) but per-group cooldown WINDOW LENGTH does NOT show same asymmetry within ±0.10 of 0.70. **39th productive-null/negative this cycle.**
**Follow-up**: nezuko assigned **#603 AdamW second-moment warmstart via ghost steps** — fresh untested mechanism addressing cold-start direction problem in `exp_avg_sq` that bias correction (magnitude rescaling) explicitly does not solve. Pre-training ghost-step loop accumulates m_t, v_t without weight updates; first ~100 training steps then operate on directionally-informed second-moment estimates instead of cold-start zero.

### ✅ nezuko #603 — AdamW ghost-step warmstart — CLOSED 00:10 UTC broken-chain + productive-NEGATIVE

Chain thrashed for ~5h with 6+ crashes across arms. Student identified key implementation limitation: `proj.weight=0` init at line 828 blocks gradient flow back through model during ghost steps (zero-inits all "proj" weights so `F.linear` backward `grad_input = grad_output @ proj.weight = 0`). Ghost steps thus only warm `lm_head` AdamW second-moment, NOT embed or scalar. The single completed arm (C ghost=25) reached **val=3.3018** — a +0.030 catastrophic regression vs baseline 3.27174, indicating ghost-step warmstart of lm_head's AdamW v_t is actively harmful. **43rd productive-NULL/NEGATIVE this cycle.** WAVE3 IDEA 7 (cold-start v_t direction) axis: closed. **Key durable finding (reusable across this programme): proj.weight=0 init blocks all upstream grad flow during pre-step probes — future optimizer-state-warming experiments must account for this.**
**Follow-up**: nezuko assigned **#628 trust-region adaptive Muon LR** — per-layer cos-EMA boost on rare-aligned layers. First experiment to AMPLIFY the rare-productive-direction signal rather than suppress conflict (vs #126 Contra-Soft attenuate, #163 DMR reset, #419 Cautious mask — all closed). Mechanistically distinct from all closed gradient-direction-aware mechanisms.

### ✅ nezuko #628 — Trust-region adaptive Muon LR (per-layer cos-EMA boost) — CLOSED 21:40 UTC productive-NULL

**Branch:** `g1r4-nezuko/trust-region-muon-lr`

Paired-pod n=3 terminal (only Arm B at BOOST=0.5 advanced after Phase 1 N=1):

| Pod | A val (ctrl) | B val (BOOST=0.5) | Δ_B_vs_A | A-drift vs 3.27070 |
|---|---:|---:|---:|---:|
| 0 | `785bssa9` 3.26902 | `y4lkmh68` 3.27291 | **+0.00389** (regression, 2.6× threshold) | −0.00168 (favorable) |
| 1 | `tu2c0ipa` 3.27344 | `7z8bjifp` 3.27219 | **−0.00125** (sub-threshold) | +0.00274 (unfavorable) |
| 2 | `r3txbt4h` 3.27269 | `hbdi8w4c` 3.27205 | **−0.00064** (sub-threshold) | +0.00199 (mid) |
| **mean (n=3)** | **3.27172** | **3.27238** | **+0.00067** | sd_A=0.00224 |

**Gates** (vs NEW baseline 3.27070): Gate 1 (mean Δ ≤ −0.002) FAIL at +0.00067 (wrong sign). Gate 2 (mean(val_B) ≤ 3.27070) FAIL at 3.27238 (+0.00168). Gate 3 stat-rule (3.28−3.27238)×√3=0.01319 PASS (moot). **No merge.**

**Phase 1 → Phase 2 collapse**: Phase 1 Δ_B_vs_A=−0.00268 → n=3 mean Δ=+0.00067. **Direction-flip + sign collapse**. Phase 1 Arm A had drift +0.00221 (upper edge); the negative within-pod Δ was inflated by unfavorable A seed AND was measured against OLD baseline 3.27174 (pre-#579). **#579's merge absorbed the productive component** — same productive signal the cos-EMA boost was extracting.

**11th N=1→paired-pod collapse precedent** post-#579.

**Mechanism reading — sub-percent LR boost + favorable-seed anti-amplification**:

Trust-mechanism telemetry across 3 B pods (reproducible — failure is at val/loss, not implementation):
- Max LR amplification: **<1% mean, <0.7% peak** even at BOOST=0.5
- cos_ema_pos_frac final: 0.208 / 0.236 / 0.333 (consistent across pods)
- lr_scale_max final: 1.00641 / 1.00344 / 1.00435

**Pod 0 (favorable A seed) anti-amplification**: Arm B over-shoots into +0.00389 regression while Arm A is at 3.26902 — BOOST pushes LR HIGHER when training is already going well, accelerating into overshoot. The "rare-productive amplification" hypothesis is INVERTED on favorable seeds.

**Mechanism class fully fenced**: Direction-aware Muon update modifications joining #126 Contra-Soft, #163 DMR, #419 Cautious, #629 layer-aggregate Contra-Soft, #530 Nesterov-Muon — all NULL/NEGATIVE.

**59th productive-null/negative this cycle.**

### ✅ nezuko #724 — Per-block-TYPE NS_ITERS_COOLDOWN — CLOSED 15:15 UTC productive-NEGATIVE (72nd cycle, 10th paired-pod collapse)

**Branch:** `g1r4-nezuko/per-type-ns-cooldown`

**Phase 2 n=3 paired-pod results (vs post-#708 baseline 3.27036):**

| Pod | Arm A ctrl (12/12) | Arm D treat (12/20) | Δ_D−A |
|---|---|---|---|
| 0 | 3.26889 | 3.27124 | **+0.00235** |
| 1 | 3.26944 | 3.27101 | **+0.00157** |
| 2 | 3.26901 | 3.27241 | **+0.00340** |
| **mean** | **3.26911** | **3.27155** | **+0.00244** |

**All 3 merge gates FAIL** — mean_D > baseline, 0/3 direction-correct, t=+4.60 highly significant REGRESSION.

**Phase 1 → Phase 2 sign-flip**: N=1 Δ=−0.00192 → n=3 mean Δ=+0.00244 (full sign reversal). Monotone regression magnitude (pod2 worst at +0.00340).

**Per-TYPE Muon hparam family ledger (post-#708)**:

| Axis | Status | PR |
|------|--------|-----|
| LR | ✅ MERGED | #579 |
| WD | ❌ NEGATIVE | #669 |
| μ (momentum) | ⚪ NULL | #674 |
| aspect ratio | ⚪ NULL | #632 |
| NS_ITERS_COOLDOWN | ❌ NEGATIVE | #724 (this) |

Per-TYPE Muon axis essentially exhausted. NS_ITERS_COOLDOWN at TYPE level adds noise without precision-allocation benefit — both attn (Q/K/V/proj) and mlp (fc/proj) matrix shapes converge to similar polar factor quality at NS=12. Mirrors per-DEPTH closure (#710). Frontier shifts to fresh axes: post-NS direction modification, data ordering, anchored regularization.

**10th paired-pod collapse precedent on r4.** Baseline UNCHANGED at val=3.27036 / fs=3216.67.

**Follow-up**: nezuko assigned **#825 Cautious AdamW for aux groups** — per-group disaggregation of #751's +0.00901 aux-all regression. 4-arm sweep: A=none ctrl, B=embed only, C=lm_head only, D=all aux. Reframed hypothesis: identify per-subgroup contribution to #751 Arm C regression on post-#708 stack (aux-side clip tightening from #708 may have changed dynamics).

### 🔄 nezuko #825 — Cautious AdamW per-aux-group disaggregation (4-arm) [assigned 15:15 UTC]

**Branch:** `g1r4-nezuko/cautious-aux`
**Hypothesis**: Liao et al. 2024 Cautious masks update components where `update * grad < 0` and rescales. #751 fern tested Cautious-all-aux (Arm C: +0.00901 large regression). #825 disaggregates per sub-group on post-#708 stack to identify per-group culprit. The new per-group grad-clip asymmetry (BODY=10/AUX=5 from #708) further tightens aux-side — may change Cautious's local effect.

| Arm | NANOGPT_AUX_CAUTIOUS | Description |
|:---:|:---:|:---|
| A | `none` | Control (bit-identical to #708 baseline) |
| B | `embed` | Mask embed updates only (largest aux param) |
| C | `lm_head` | Mask lm_head updates only (output coupling) |
| D | `all` | Mask all three aux groups (replicates #751 Arm C at +0.00901) |

Implementation: CautiousAdamW subclass (fused=False) with snapshot-delta post-step masking, 4-arm paired-pod n=3 (12 runs). ETA ~7.3h.

### ✅ frieren #470 — NS iterations NORMAL phase sweep — CLOSED 20:55 UTC productive-null

Arms B=8 (+0.00235 regression), C=10 (−0.00168 null), D=14 (−0.00145 null). Wide saturation plateau NS ∈ [10, 14]; NS=8 below floor. **Critical compute finding: NS step-time is flat (±1%) across all NS values — orthogonalization is not the per-step bottleneck.** 21st productive-null/negative.
**Follow-up**: frieren assigned **#506 NS-iter warmup schedule** — ramp NS from {8,10} → 12 over first 5-10%.

### ✅ frieren #593 — Per-group AdamW WD sweep — CLOSED 00:05 UTC productive-NULL

Single-seed 4-arm (drift gate A PASS exceptional parity |3.27167−3.27174|=0.00007): A=3.27167, B (lm_head WD=0.01)=+0.00192 (regression marginal), C (scalar WD=0.01)=−0.00017 (productive-null sub-noise-floor), D (joint)=−0.00022 (productive-null sub-noise-floor). No arm clears −0.002 signal threshold. **42nd productive-NULL/NEGATIVE this cycle.** **Cross-axis WD-ADDITION pattern now fully fenced**: AdamW lm_head WD ADD (B regress), AdamW scalar WD ADD (null), AdamW embed WD ADD (#554 NEG), Muon body WD warmup ADD (#483 NEG). Only WD direction with extractable gain on merged stack is REDUCTION (#550 Muon body WD cooldown reduce, paired-pod in-flight). Strengthens "baseline is locally optimal across WD axis; cooldown handles regularization adequately".
**Follow-up**: frieren assigned **#629 Layer-aggregate Contra-Soft Muon** — fills explicit untested gap diagnosed in #126 closure (element-wise Contra-Soft attenuated ~13-50% of gradient mass uniformly across granularities; layer-aggregate operates only on whole-matrix cosine, preserving productive-direction layers entirely). Distinct from #628 (boosts via LR scaling); this attenuates via gradient scaling on conflict-layers only.

### ✅ frieren #629 — Layer-aggregate Contra-Soft Muon — CLOSED 08:30 UTC productive-NEGATIVE

Single-seed 4-arm (drift gate A PASS, exceptional parity +0.00014): A=3.27159, B (α=0.25)=3.27345 (Δ=+0.00186, regression band), C (α=0.50)=3.27185 (Δ=+0.00026, null), D (α=1.00)=**3.63287** (Δ=+0.36128, **catastrophic — FAILS 3.28 target**). W&B runs: dqssobu4 (A), h1aqkx71 (B), d4ihlim2 (C), 34ui6a23 (D). Non-monotone (regress→parity→catastrophic) but uniformly non-improving. Mechanism telemetry: scale_min D=0.426 (cos_min=−0.574), D's α=1.0 full-zero-grad on conflict layers kills gradient signal; training oscillates and val plateaus at 3.63 (never reaching 3.28). **Contra-Soft mechanism class FULLY CLOSED**: #126 element-wise + #629 layer-aggregate both falsified. The load-bearing ~11% persistent-cos<0 fraction is productive exploration, not noise. **48th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **#664 AdamW bias correction disable sweep** — genuinely fresh mechanism axis: with merged β2=0.99 (#236), bias correction scales mid-training aux updates down by sqrt(bc_v)/bc_m = 0.63–0.80× during steps 50–100; disabling it tests whether this implicit LR suppression limits mid-phase learning. Tests 3 scopes (embed-only, lm_head-only, all-aux).

### ✅ frieren #664 — AdamW bias correction disable sweep on aux groups — CLOSED 18:35 UTC productive-NULL

Single-seed 4-arm on NEW post-#579 stack (drift gate A2 PASS, +0.00154 within ±0.003): A2 ""=3.27224 ctrl, B2 embed=3.27143 (Δ=−0.00081 sub-threshold null), C2 lm_head=3.27144 (Δ=−0.00080 sub-threshold null), D2 all_aux=3.27217 (Δ=−0.00007, **saturation/interference**). No arm passes within-pod −0.002 winner threshold; best singletons B2/C2 at −0.0008 ~2.5× below threshold. **B2 ≈ C2 within single-seed noise σ≈0.001**: bias-correction disable on EITHER aux group produces nearly-identical marginal effect — the mid-training LR-boost mechanism applies uniformly across aux groups with no per-group structural preference. **D2 (all_aux) flattens to ctrl** rather than compounding additively (~−0.0016 expected if independent) — **saturation/interference**: the early-training relative-magnitude structure between embed/lm_head/scalar is maintained by their RELATIVE bias-correction factors; disabling on ALL three preserves the relative ratios while disabling on only one breaks them. The single-aux disable signal is a relative-magnitude shift, not a single-group mechanistic effect. Implementation clean (telemetry verified bc_scale_factor ramp matches expected curve, rebased onto post-#579 cleanly, wall-clock parity 1893-1894ms across all 4 arms). All 4 arms hit 3.28 target. **54th productive-null/negative this cycle.** Bilateral closure with per-group AdamW family: #599 β₁ NEG + #560 β₂ NEG + #593 WD NULL + #652 eps NEG + #664 BC NULL — AdamW-internal axes now FULLY exhausted on merged stack; only LR-mult #393 MERGED extracted gain.
**Follow-up**: frieren assigned **#710 per-depth body Muon NS_ITERS variation** — fresh axis distinct from per-block-TYPE wiring (avoids the impl-bug class seen in #669/#674). Tests early/mid/deep bucket NS-iter budget allocation; orthogonal to #543 (per-aspect-ratio, only differentiates mlp.fc/mlp.proj per layer because q/k/v/attn.proj are 1× aspect square 768×768) and #470 (uniform escalation) and #506 (time-axis warmup CLOSED-NEG). Mechanism: gradient magnitudes vary by depth (early layers diluted by backward chain depth; mid layers full backward flow / capacity bottleneck; deep layers closer to output); NS=12 uniform may over-invest on well-conditioned mid-layer matrices and under-invest on edge layers. 4-arm: A (12,12,12) ctrl, B (10,14,10) mid-heavy, C (14,12,10) front-loaded, D (10,12,14) back-loaded.

### ✅ frieren #710 — Per-depth body Muon NS_ITERS variation — CLOSED 14:09 UTC productive-NEGATIVE (70th cycle, 9th paired-pod collapse)

**Branch:** `g1r4-frieren/per-depth-muon-ns-iters`

**Phase 2 n=3 final:** mean_A=3.27060, mean_C=3.27177 — Δ=+0.00117 regression, 3/3 pods direction-wrong. Both binding gates FAIL (mean_C > baseline, 0/3 pods C<A). Phase 1 N=1 Δ=−0.00138 → Phase 2 n=3 Δ=+0.00117: classic sign-flip. **Mechanism**: NS normalizes depth-scale variation — all 12 body Muon depths converge to same polar factor quality at NS=12. DEPTH-asymmetric iter allocation provides no signal (same as #753 per-DEPTH LR NULL). Per-DEPTH bucket family fully closed. **9th paired-pod collapse precedent.**

W&B Phase 2: trdfa7c6/si0n5039, hjs2ww65/4eoi63uk, enxvvgga/f16ktn1n.

**Follow-up**: frieren assigned **#810 post-NS momentum** — temporal smoothing of NS-orthogonalized updates across steps (first post-NS axis; distinct from #356 pre-NS μ schedule NULL, #530 Nesterov-Muon NULL, #434 Lookahead NEG all of which operate pre-NS or in weight-space).

### 🔄 frieren #810 — Post-NS momentum: temporal smoothing of NS-orthogonalized updates [assigned 14:25 UTC]

**Branch:** `g1r4-frieren/post-ns-momentum`
**Hypothesis**: After NS-orthogonalization, maintain post-NS buffer w_t = α×w_{t-1} + (1-α)×u_t. Apply w_t as update instead of u_t. Mechanism: NS is nonlinear, so post-NS averaging is distinct from pre-NS EMA (β=0.95). Tests whether temporal coherence in the orthogonal subspace helps convergence.

| Arm | NANOGPT_POST_NS_ALPHA | w memory depth | Description |
|:---:|:---:|:---:|:---|
| A | 0.0 | — | Control (bit-identical merged stack) |
| B | 0.3 | ~3 steps | Mild temporal smoothing |
| C | 0.5 | ~2 steps | Moderate |
| D | 0.7 | ~3.3 steps | Strong |

### ✅ frieren #506 — NS-iter warmup schedule — CLOSED 16:15 UTC productive-NEGATIVE [paired-pod n=3]

Paired-pod n=3 confirmation: all 3 pods regress (mean Δ=+0.00087, wrong sign). Gates 1+2 fail (mean Δ above 0, mean val_B 3.27329 > baseline 3.27174). The N=1 Δ_C=−0.00119 was an Arm-A drift artifact (original Arm A drifted +0.00108 above baseline; paired-pod Arm-A controls anchor at +0.00068). **5th cycle precedent for single-seed → paired-pod collapse** (joins #344, #351, #408, #487). **NS-axis program now fully fenced**: 3/3 NS-iter schedule axes closed by frieren (warmup #506, normal-phase #470, cooldown saturation #388) + 3 cooldown-machinery components MERGED (#176, #285, #290) + sub-stack pruning #487 null + spatial #543 null. **37th productive-null/negative this cycle.**
**Follow-up**: frieren assigned **per-group AdamW WD sweep** — currently WD=0 uniformly across embed/lm_head/scalar; whether dense lm_head or small-param scalar groups benefit from WD>0 has never been tested. Structurally distinct from #554 (embed WD ADD cooldown, NEGATIVE — sparse-row mechanism), #550 (Muon body WD), #483 (Muon WD warmup, NEGATIVE).

### ✅ edward #474 — AdaBelief for aux groups — CLOSED 22:35 UTC productive-NEGATIVE

Arms B (embed: +0.04081), C (lm_head: +0.00188), D (all-aux: +0.03479). D ≈ B trajectory confirms embed group dominates catastrophic regression. Root cause: AdaBelief's `(g−m)²` fails on sparse-row embed (absent rows have g=0 but m≠0 → `(g−m)²=m²`, inflating denominator globally). lm_head: stable mild regression. **23rd productive-null/negative this cycle.** Second-moment-formulation axis fully closed.
**Follow-up**: edward assigned **#516 Yogi optimizer on aux groups** — sign-based additive second-moment update (avoids embed sparsity pathology, structurally distinct).

### ✅ edward #516 — Yogi optimizer on aux groups — CLOSED 07:00 UTC productive-NEGATIVE (embed/all-aux) + productive-NULL (lm_head)

Single-seed 4-arm (drift gate A PASS, |3.27419−3.27174|=0.00245 ≤ 0.003): A=3.27419, B embed=+0.00386 (regression), C lm_head=+0.00038 (null), D all-aux=+0.00447 (regression). D ≈ B + 0.00061 — embed regression dominates; lm_head and scalars contribute marginally. Mechanism reading: Yogi's faster-additive v_t reaction destabilizes sparse-row embed at β₂=0.99 (regression grows monotonically through cooldown); dense lm_head indistinguishable from AdamW. Independent of AdaBelief mechanism (#474): Yogi accumulates g² same as AdamW. **Closes second-moment-update-rule axis** — joined with #474 AdaBelief, #442 Adam-atan2, #490 NAdam-aux. **29th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#550 Muon WD cooldown reduction** — first late-phase WD axis (structurally distinct from #483 WD warmup which tested early reduction).

### ✅ edward #639 — Embed-stack joint redundancy ablation: linear_floor × LR_MULT=1.5 — CLOSED 11:10 UTC productive-NULL

4-arm 2×2 factorial (N=1, ran on OLD pre-#579 stack — #579 merged mid-experiment): A (full)=3.27438, B (drop floor)=3.27285 (Δ=−0.00153), **C (drop mult)=3.27222 (Δ=−0.00216 best)**, D (drop both)=3.27487 (Δ=+0.00049). **All 4 arms above NEW baseline 3.27070** — C closest at +0.00152. Mechanism finding: **mutual antagonism / saturation** — A ≈ D, single-component drops each help slightly. Effective late-phase embed LR: A=0.0675 (saturated) > C=0.045 (sweet spot) > B=0.45→0 > D=0.30→0. Both #235 and #393 push embed LR past sweet spot; stacking saturates surface. Arm C's −0.00216 within-pod signal at threshold edge but Arm A drift +0.00264 baked-in — paired-pod confirmation cannot land mean(val_C) below 3.27070. Cannot merge; stack simplification not viable. **Future embed-side experiments should target joint surface** rather than individual axes. **51st productive-null/negative this cycle.**
**Follow-up**: edward assigned **#674 per-block-type Muon momentum asymmetry** — direct extension of #579/#669 mechanism family on 3rd Muon hparam axis. 4-arm sweep (attn_mu × mlp_mu): A=(0.95,0.95) ctrl, B=(0.90,0.95) attn-faster, C=(0.95,0.99) mlp-slower, D=(0.90,0.99) compound. Mirror #579 4-arm pattern. Mechanism: attn-prefer-faster-tracking (less stale routing signal), mlp-prefer-slower-tracking (lower variance feature gradient). Completes per-block-TYPE Muon hparam family (LR ✓#579 / WD #669 / momentum #674).

### ✅ edward #674 — Per-block-type Muon momentum asymmetry — CLOSED 19:20 UTC productive-NULL/NEGATIVE

4-arm single-seed sweep (drift gate Arm A PASS at +0.00053): A=(0.95,0.95)=3.27123, B=(0.90,0.95)=3.27066 (Δ=−0.00057 sub-threshold direction-correct), **C=(0.95,0.99)=3.27986 (Δ=+0.00863 strong regression, fst=3350)**, D=(0.90,0.99)=3.27915 (Δ=+0.00792, tiny B-rescue from additive prediction +0.00806). No winner-candidate. **Per-block-TYPE momentum axis does NOT mirror #579 LR asymmetry pattern.** mlp_mu=0.99's ~100-step window staleness dominates variance reduction benefit. Mechanism refinement: #579's productive interaction is specifically about step-size magnitude (LR axis), NOT about gradient-averaging time-constant — the two per-block-TYPE Muon hparam axes are mechanistically distinct. **56th productive-null/negative this cycle.** Per-block-TYPE Muon family characterization: LR ✓#579 MERGED / WD #669 in flight / mu ✗ NULL (this) / NS_ITERS,β₂,ε unexplored.
**Follow-up**: edward assigned **#712 Per-block-TYPE body Muon β₂ asymmetry** — second-moment variance-estimator window per block type. Orthogonal to mu (first moment), LR (step magnitude), WD (regularization). β₂ already a per-group field in Muon class; trivial ~5 LOC env-var change. 4-arm: A=(0.999,0.999) ctrl, B=(0.99,0.999) attn-shorter, C=(0.999,0.99) mlp-shorter, D=(0.99,0.99) uniform-shorter control separating per-TYPE asymmetry from "just shorter everywhere". Distinct from #97 (global β₂ sweep at 0.999 optimal) and #560 (per-aux-group AdamW β₂ NEG, structurally different because no NS).

### ✅ edward #712 — Per-block-TYPE body Muon β₂ asymmetry — CLOSED 03:35 UTC productive-NULL

**Branch:** `g1r4-edward/muon-attn-mlp-beta2-asym`

Single-seed 4-arm result (drift gate A PASS at +0.00032):

| Arm | attn β₂ | mlp β₂ | val/loss | Δ_vs_A | Δ_vs_baseline | Band |
|---|---:|---:|---:|---:|---:|---|
| A (ctrl) | 0.999 | 0.999 | 3.27102 | — | +0.00032 | drift PASS |
| B (attn-shorter) | 0.99 | 0.999 | **3.27027** | −0.00075 | −0.00043 | null sub-threshold |
| C (mlp-shorter) | 0.999 | 0.99 | **3.27029** | −0.00073 | −0.00041 | null sub-threshold |
| D (uniform-shorter) | 0.99 | 0.99 | 3.27280 | **+0.00178** | **+0.00210** | regression direction-incorrect |

**Mechanism reading**: B/C symmetric magnitudes (Δ_vs_A = −0.00075 / −0.00073) confirm **no per-TYPE β₂ asymmetry sweet spot exists**. Both singleton shortenings direction-correct but ~3× below −0.002 paired-pod threshold. D compound regression (+0.00178) is informative: **non-additive failure** confirms uniform β₂=0.999 (#97 finding) is genuinely near-optimum at per-TYPE granularity. Sub-threshold-direction-correct signals (B/C at |Δ| ≈ 0.0007) sit in the same magnitude band as the 12 paired-pod-collapse precedents this cycle.

**Per-block-TYPE Muon family characterization complete**:
- LR ✓ MERGED (#579) — only productive axis
- mu ✗ NULL (#674)
- β₂ ✗ NULL (this)
- WD ✗ NEGATIVE (#669)
- aspect-exp ✗ NULL (#632)
- NS_ITERS_COOLDOWN 🔄 (#724 nezuko in-flight)

**Hygiene note from student**: 11-crash pod-environment startup window + duplicate-chain incident handled cleanly by student (killed duplicate PIDs, renamed duplicate script to `.DUPLICATE_KILLED`). Surviving runs uncontaminated. Good defensive engineering practice for future PRs.

**62nd productive-null/negative this cycle.**

**Follow-up**: edward assigned **#753 Per-block-DEPTH body Muon LR asymmetry** — extends #579 (per-block-TYPE LR MERGED) to depth axis with 3 buckets (early=L0-3, mid=L4-7, deep=L8-11). Direct parallel to #710 frieren (per-depth NS_ITERS in-flight); #710 Phase 1 showed front-loaded NS=14/12/10 wins by Δ=−0.00138 monotone front-vs-back. Per-DEPTH LR may extract gain via same early-layer signal-dilution mechanism. Distinct from #409 LLRD (geometric decay NULL pre-#579) — 3-bucket non-monotone parametrization untested.

### ✅ edward #753 — Per-block-DEPTH body Muon LR asymmetry — CLOSED 11:30 UTC productive-NULL (67th cycle)

**Branch:** `g1r4-edward/per-depth-muon-lr`

**Terminal 4-arm N=1 result (drift gate A PASS at Δ=−0.00282 within ±0.003):**

| Arm | EARLY / MID / DEEP | val/loss | Δ_vs_A | Δ_vs_baseline | fs | Verdict |
|---|:---:|---|---|---|---|---|
| A (ctrl) | 1.00/1.00/1.00 | 3.26788 | — | −0.00282 (favorable drift) | 3200 | drift PASS |
| B (front-loaded) | 1.20/1.00/0.80 | 3.26984 | +0.00196 | −0.00086 | 3225 | regression |
| C (back-loaded) | 0.80/1.00/1.20 | 3.27610 | **+0.00822** | +0.00540 | 3275 | strong regression |
| D (mid-heavy) | 0.90/1.20/0.90 | 3.27073 | +0.00285 | +0.00003 | 3225 | regression |

W&B: A=7tjjqyyl, B=7qy4wygv, C=ryghtm6f, D=j2lieopv (clean relaunch; duplicates n43vfv7y/rftykq3p disregarded).

**Mechanism (definitive closure)**: NS-orthogonalization rescales each weight matrix's update to unit spectral norm, **normalizing scale across depths**. Cross-DEPTH asymmetry does NOT survive NS because depth doesn't change matrix shape. Cross-TYPE (#579 MERGED) DOES survive NS because shape differs (768×768 square attn vs 4·768 rectangular mlp). This validates #409 LLRD closure logic on post-#579 stack with 3-bucket non-monotone parametrization. Striking contrast: front-loaded NS-iter budget (#710 Arm C Δ=−0.00138 winner) vs front-loaded LR (Arm B +0.00196 regression) — OPPOSITE directions despite analogous parametrization, confirming NS-precision and post-NS-step-size are mechanistically separate. **Per-DEPTH Muon LR axis fully closed** across both #409 geometric and #753 3-bucket parametrizations. **67th productive-null/negative this cycle.**

**Follow-up**: edward assigned **#791 Focal loss γ sweep** — pivoting to loss-side axis, first gradient-reweighting-by-difficulty mechanism on this stack.

### 🔄 edward #791 — Focal loss γ sweep — gradient reweighting by token difficulty [SENT BACK 14:31 UTC with measurement fix]

**Branch:** `g1r4-edward/focal-loss`
**Hypothesis**: Focal loss reweights per-token gradient by `(1−p_correct)^γ`. First gradient-reweighting-by-difficulty mechanism on this stack.
**Status (14:31 UTC)**: Arm A complete (val=3.27076, drift PASS). Arm B running but PAUSED — student flagged measurement issue: focal-weighted loss reported as val/loss (biased downward vs CE for B/C/D arms, confounds comparison). Advisor directed Option 1 fix: modify `forward()` to use standard CE during validation (`if NANOGPT_FOCAL_GAMMA == 0.0 or not self.training`). Kill arm B, restart B/C/D with fixed code. Arm A result (3.27076) still valid as control (γ=0 = CE). Updated baseline in PR: now 3.27036 (post-#708 merge). ETA ~5.5h remaining for B/C/D.

### ✅ edward #550 — Muon WD cooldown reduction — CLOSED 02:50 UTC productive-NULL (paired-pod collapse)

**Single-seed N=1 winner** (Arm D WD=0 Δ=−0.00337) **collapsed to paired-pod sub-threshold**:

| Pod | Arm A (WD=0.025) | Arm D (WD_final=0) | Δ |
|---|---:|---:|---:|
| pod0 | 3.27328 | 3.27238 | −0.00090 |
| pod1 | 3.27247 | 3.27119 | −0.00127 |
| pod2 | 3.27138 | 3.27085 | −0.00054 |
| **mean (n=3)** | **3.27238** | **3.27147** | **−0.00090** |

**Gates**: Gate 1 (within-pod mean Δ ≤ −0.002) **FAIL** at −0.00090 (half threshold). Gate 2 (mean val_D ≤ 3.27174) PASS at 3.27147. Gate 3 (stat-rule (3.28 − 3.27147) × √3 = 0.01477 ≥ 0.004) PASS. Drift gates: A mean 3.27238 vs baseline 3.27174 = +0.00064 (sub-drift PASS). Direction-correct 3/3 pods — real mechanism, not seed luck — but magnitude insufficient. **6th cycle precedent for single-seed→paired-pod collapse** (#344, #351, #408, #487, #506, #550). **WD-axis now bilaterally fenced** on this stack: ADDITION (#554 embed, #593 lm_head/scalar/joint, #483 Muon warmup) all NEG; REDUCTION (#550) sub-threshold NULL. Cooldown-window precision is structural, not WD-friction-bound. **45th productive-null/negative this cycle.**
**Follow-up**: edward assigned **#639 Embed-stack joint redundancy ablation** — joint ablation of EMBED_COOLDOWN_SHAPE=linear_floor (#235 merged) and ADAMW_EMBED_LR_MULT=1.5 (#393 merged); both raise late-phase embed effective LR via different mechanisms, one may be redundant given the other. Pure env var permutation (no code).

---

## Research theme — current cycle

**51 productive-null/negative results + 10 merged improvements**. The 10th merge is **#708 per-group grad-clip BODY=10/AUX=5** (paired-pod n=3 mean Δ=−0.00140; mean(B,n=3)=3.27036 beats baseline 3.27070 by 0.00034; fs improved 3225→3216.67). Aux-side mechanism confirmed: tighter aux L2 clip bounds per-coord outlier propagation in AdamW `m/√v`; body Muon insensitive (NS absorbs). The strongest confirmed findings:
1. **The cooldown phase is load-bearing signal, not noise.** Any mechanism that blends, averages, or smooths parameters/gradients during the cooldown window hurts:
   - #436 weight-EMA → productive-NEGATIVE
   - #434 Lookahead → productive-NEGATIVE (Muon wrapping 4.5× worse)
   - #399 AdEMAMix → productive-null
   - #419 Cautious AdamW → productive-null
2. **Loss-side auxiliary regularization is exhausted.** Softcap c=15 is optimal (#354) and already bounds the logit-distribution axes that z-loss (#441) and label smoothing (#446) target. Both regress monotonically.
3. **Additive regularization always fails on this stack.** AGC, GC, gradient noise, label smoothing, z-loss — all hurt.

**Current open questions** (in-flight):
1. ~~Does NS-iter warmup (low → 12 over first N%) extract benefit from early gradient noise?~~ **#506 CLOSED productive-NEGATIVE** — all 3 pods regress, 5th single-seed→paired-pod collapse precedent; NS-axis program fully fenced.
2. ~~Does per-block NS iter allocation (by aspect ratio) help over uniform NS=12?~~ **#543 CLOSED productive-NULL** — NS=12 saturation robust to spatial reallocation; codebase has limited surface (only 2-of-6 Muon blocks non-square).
3. ~~Does lm_head cooldown SHAPE (cosine / late_peak / linear_floor) matter vs default linear?~~ **#547 CLOSED productive-NULL** — lm_head wants monotonic linear; late_peak doesn't cross-axis transfer from NS.
4. Does Muon WD reduction during cooldown extract precision-window gain? (**#550, edward — N=1 Arm D WD=0 Δ=−0.00337 strong winner candidate; sent back for paired-pod n=3 confirmation, identical protocol to #487; non-linear axis response (only WD=0 extracts gain) is structurally novel; either fresh merge candidate or 5th single-seed→paired-pod collapse**)
5. ~~Does adding small WD on AdamW embed during cooldown help?~~ **#554 CLOSED productive-NEGATIVE** — clean monotone regression; embed group rejects added WD during cooldown; bilateral asymmetry with #550 (body benefits from REDUCED WD, embed rejects ADDED WD).
6. ~~Does per-group AdamW β₂ asymmetry extract per-group second-moment time-constant gains?~~ **#560 CLOSED productive-NULL/NEGATIVE** — embed β₂=0.999 regression (+0.00359), β₂=0.95 null (+0.00089), D inert; AdamW-internal axis family substantially exhausted.
7. Does per-group cooldown WINDOW LENGTH asymmetry around 0.70 baseline extract gains? (#568, nezuko — fresh structural axis paralleling SHAPE work)
8. Is the *entire* NS-cooldown sub-stack jointly load-bearing even though each component is individually redundant? (#487 follow-up, tanjiro — joint-pruning ablation, structurally novel compound subtraction)

**Stack convergence signal**: 28 productive-null/negative results. The baseline at 3.27174 is well-tuned. New wins will likely come from:
1. **"Less constraint early" schedule cluster** (in flight): NS-iter warmup (#506), β₁ warmup (#514) — early-phase schedule axes. WD warmup (#483) and embed-LR warmup (#489) both closed productive-NEGATIVE — bilateral structural finding.
2. **Late-phase cooldown shape**: body Muon LR cooldown shape (#520 thorfinn) — targeting the load-bearing 30% cooldown window.
3. **Stack simplification** — #487 paired-pod n=3 CLOSED productive-NULL (Arm B drop NS_ITERS_COOLDOWN: mean Δ=+0.00003, classified redundant but not improved). All three sub-stack components (NS_ITERS_COOLDOWN, NS_COOLDOWN_SHAPE=late_peak, NS_COEF_SCHEDULE=linear_ramp_down) are individually classified as redundant under their respective single-drop tests; **joint-drop interaction is untested** — that's the natural next step (follow-up assigned to tanjiro). If joint-drop ≈ baseline, the entire NS-cooldown machinery can be retired.
4. **Non-AdamW body-Muon mechanism axis** — Nesterov-Muon (#530, nezuko new) targets lookahead-before-NS, complementing pre-stage NS scheduling (#506) and shape (#520). The AdamW-internal three-axis ablation is closing (#442 NEGATIVE + #474 NEGATIVE + #490 null = body-side is the natural pivot).
5. **Bilateral regularization closure (from #483 + #489)**: both ADD (17 axes) and REDUCE-by-warmup (Muon-WD, embed-LR) regularization fail → early-training window is bilaterally well-tuned.
6. **Aux-group coupled system insight (from #477)**: future aux-group mechanism experiments should default to "all aux" scope; single-group regresses.
7. **Embed sparsity structural insight (from #474)**: `(g − m)²`-based second moments fail on embed group; `g²`-only formulations (AdamW, Yogi) are safe.

---

## Recently closed experiments

| PR | Student | Hypothesis | Outcome |
|---|---|---|---|
| #719 | alphonse | Pruning ablation of schedule mechanisms (NS_COOLDOWN_SHAPE / NS_COEF_SCHEDULE / EMBED_COOLDOWN_SHAPE) | CLOSED productive-NULL (64th cycle; no arm Δ ≤ −0.001; B=+0.00183 NS_COOLDOWN_SHAPE essential, C=+0.00127 NS_COEF_SCHEDULE null-band, D=+0.00247 EMBED_COOLDOWN_SHAPE most essential; post-#579 stack well-composed; schedule-mechanism pruning axis fenced) |
| #618 | fern | Muon² for lm_head (replace AdamW) | CLOSED productive-NEGATIVE (3/3 Muon arms MISS 3.28 target; monotonic-LR pattern, no interior minimum; mechanism: NS homogenizes Zipf-distributed vocab-freq Hessian structure lm_head needs; "Replace AdamW for lm_head" axis fully closed; 46th this cycle) |
| #550 | edward | Muon WD cooldown reduction (paired-pod) | CLOSED productive-NULL (mean Δ=−0.00090 FAIL Gate 1, val=3.27147 PASS Gate 2, stat-rule=0.01477 PASS Gate 3; direction-correct 3/3 pods but magnitude insufficient; 6th cycle paired-pod collapse precedent; WD-axis bilaterally fenced; 45th this cycle) |
| #599 | alphonse | Per-group AdamW β₁ time-constant sweep | CLOSED productive-NEGATIVE (B=+0.00399 regression, C β₁=0=+0.00513, D β₁=0.90=+0.00177; both directions regress; per-group AdamW family fully exhausted; 44th this cycle) |
| #560 | alphonse | Per-group AdamW β₂ asymmetric sweep (embed/lm_head decoupling) | CLOSED productive-NULL/NEGATIVE (B=+0.00089 null, C β₂_embed=0.999=+0.00359 regression, D inert; AdamW-internal family exhausted; 38th this cycle) |
| #483 | thorfinn | Muon WD warmup frac∈{0.05,0.10,0.20} | CLOSED productive-NEGATIVE (monotone: +0.00080/+0.00258/+0.00400; body WD=0.025 is load-bearing from step 0; bilateral WD-level closure) |
| #474 | edward | AdaBelief aux scope sweep | CLOSED productive-NEGATIVE (B=+0.041/D=+0.035 catastrophic embed sparsity; C=+0.002 mild; second-moment-formulation axis closed) |
| #477 | fern | OrthoGrad aux scope sweep | CLOSED productive-null (D=−0.00080 short of −0.002; non-monotonic: singles regress, combined recovers; aux groups coupled system) |
| #470 | frieren | NS iterations normal phase NS∈{8,10,12,14} | CLOSED productive-null (wide plateau [10,14]; NS=8 below floor; NS step-time flat ±1%) |
| #454 | nezuko | lm_head/scalar linear_floor cooldown | CLOSED productive-null (best Δ=−0.00098, half threshold; embed-specific mechanism, not aux-generic) |
| #442 | alphonse | Adam-atan2 b∈{0.3,1.0,3.0} | CLOSED productive-NEGATIVE (D=+0.010 missed 3.28; all worse than ε-based AdamW; magnitude-transform axis closed) |
| #441 | tanjiro | Logit Z-loss λ∈{1e-5,1e-4,1e-3} | CLOSED productive-NEGATIVE (B=+0.00211/C=+0.00151/D=+0.022 missed 3.28; softcap c=15 already bounds logits, z-loss redundant) |
| #446 | thorfinn | Label smoothing α∈{0.05,0.1,0.2} | CLOSED productive-NEGATIVE (monotone: +0.046/+0.102/+0.223; stack already well-regularized) |
| #434 | edward | Lookahead scope sweep | CLOSED productive-NEGATIVE (all arms regression-monotone; Muon wrapping 4.5× worse) |
| #436 | frieren | Weight-EMA (Polyak averaging) | CLOSED productive-NEGATIVE (damage monotone with window; cooldown is signal not noise) |
| #419 | askeladd | Cautious AdamW (all scopes) | CLOSED productive-null (regression all scopes; β₁=0.80 leaves little room for cautious mask) |
| #409 | thorfinn | Per-block LR decay (LLRD for Muon) | CLOSED productive-null (NS normalizes depth-dependent LR) |
| #411 | alphonse | Gradient noise injection | CLOSED productive-null (noise clearly hurts; stack already near noise floor) |
| #407 | tanjiro | AdamW β₂ sensitivity | CLOSED productive-null (symmetric valley around β₂=0.99) |
| #402 | frieren | Gradient Centralization scope | CLOSED productive-null (NS already mean-centers block gradients) |
| #399 | edward | AdEMAMix on AdamW groups | CLOSED productive-null (slow-EMA redundant with β₂=0.99) |

---

## Closed axes (do not re-assign)

**Optimizer-internal / Adam-family**:
- **β₁ per-group: CLOSED productive-NEGATIVE** (#599; B=+0.00399/C=+0.00513/D=+0.00177; both directions; **per-group AdamW family fully exhausted** — β₁ + β₂ + WD all closed-NEGATIVE; only embed-LR-mult #393 extracted gain)
- β₂ per-group asymmetry (embed swept 0.95/0.999, lm_head 0.999): CLOSED productive-NULL/NEGATIVE (#560; embed β₂=0.999 +0.00359 regression, β₂=0.95 +0.00089 null, D inert; AdamW-internal family substantially exhausted)
- ε per-group: all swept, β₂=0.99/ε=1e-10 confirmed
- WD per-group: **bilaterally fenced — ADDITION (#554/#593/#483) all NEG; REDUCTION (#550, n=3 paired) sub-threshold NULL at mean Δ=−0.00090; cooldown-window precision is structural, not WD-friction-bound**
- Gradient noise injection, GC, Cautious, AdEMAMix, Lookahead, Weight-EMA, AGC, OrthoGrad: all closed
- AdaBelief variance-of-prediction-error second moment: CLOSED productive-NEGATIVE (#474; embed sparsity pathology; `(g−m)²` fails on absent-row sparse groups)
- Muon-WD warmup (all fracs 5-20%): CLOSED productive-NEGATIVE (#483; monotone worsening; body WD=0.025 is bilaterally optimal)
- Lion, Adafactor on aux: closed (prior rounds)
- LLRD Muon: closed (NS normalizes depth scaling)
- AdamW LR per-group (embed=1.5× MERGED #393): embed_mult swept, scalar/lm_head confirmed optimal at 1.0×
- Adam-atan2 magnitude-transform (b∈{0.3,1.0,3.0}): CLOSED productive-NEGATIVE (#442; ε=1e-8 already optimal)
- NAdam (Nesterov-AdamW) aux scope sweep: CLOSED productive-null (#490; best arm B Δ=−0.00059 within null, joint D Δ=+0.00275 regression — scalars likely bad actor)
- Nesterov-Muon body weight sweep α∈{0.0, 0.50, 0.99}: CLOSED productive-NULL (#530; cliff on low-α side: α=0.50 catastrophic +0.04114 fst=-1, α=0.99 plateau null +0.00060; existing α=μ=0.95 is load-bearing AND optimally weighted; mechanism: tiny anti-staleness injection on top of NS-stable EMA; 5th body-Muon mechanism closure; 32nd null this cycle)

**NS precision family**:
- NS_ITERS_COOLDOWN: saturated (#388); **#487 Arm B (drop) at paired-pod n=3: mean(Δ)=+0.00003 — CLASSIFIED REDUNDANT** (not load-bearing, not improved); 4th cycle precedent for N=1 → paired-pod collapse
- NS cooldown SHAPE=late_peak: MERGED #285; #487 Arm C drop = +0.00080 null at N=1
- NS coef schedule=linear_ramp_down: MERGED #290; #487 Arm D drop = +0.00066 null at N=1
- **Joint-drop of NS-cooldown sub-stack: in-flight** (tanjiro #577, joint-pruning interaction test)
- **Per-block NS-iter spatial allocation (aspect ratio)**: CLOSED productive-NULL (#543; NS=12 saturated to spatial reallocation; codebase has only 2 non-square Muon blocks limiting surface)
- NS coef depth/center: saturated (#345, #384)
- NS=12 normal phase: CLOSED productive-null (#470; wide plateau NS ∈ [10,14]; NS=8 below floor; NS step-time flat ±1%)
- **NS-iter warmup (NS=8→12 over first 5%)**: CLOSED productive-NEGATIVE (#506; paired-pod n=3 mean Δ=+0.00087, all 3 pods regress; 5th single-seed→paired-pod collapse; NS axis fully fenced — 3/3 frieren NS schedule corners closed + sub-stack pruning + spatial reallocation also null)

**Schedule**:
- Cooldown frac (global): closed
- Embed linear_floor: MERGED #235
- lm_head steeper-decay: harmful (#315)
- lm_head + scalar floor: CLOSED productive-null (#454; embed-specific mechanism, not aux-generic)
- **lm_head cooldown SHAPE (cosine/late_peak/linear_floor)**: CLOSED productive-NULL (#547; cross-axis NS late_peak transfer falsified, +0.00179 biggest regression; lm_head wants monotonic linear; reproduces #454 linear_floor null; per-group SHAPE design space now substantially characterized — only scalar untested)
- Muon μ schedule: catastrophic; constant μ=0.95 confirmed (#356)
- Muon LR floor: monotone worse (#335)
- Embed-only LR warmup (frac∈{0.02, 0.05, 0.10}): CLOSED productive-NEGATIVE (#489; monotone catastrophic worsening; full embed LR from step 0 is load-bearing; 25th null this cycle)
- Embed LR step-0 boost (decay to 1.5×): CLOSED productive-NULL (#526; B/C plateau at Δ≈−0.0008 within noise floor; D longer window mildly worse; bilateral closure with #489; 31st null this cycle — embed step-0 LR=1.5× is bilaterally optimal)
- **Embed AdamW WD cooldown nudge (additive)**: CLOSED productive-NEGATIVE (#554; monotone regression A→D, B=+0.00068 null-edge fails baseline parity, C=+0.00657 regression, D=+0.01571 fails 3.28 target; mechanism: embed sparse-row representations depend on accumulated info not noise; WD overrides accumulation; bilateral asymmetry with #550 candidate)

**Init**:
- Embed init scale: null (#374)
- lm_head init std: monotone worse (#380)
- Block output projection init scale: in-flight (#452)

**Loss-side**:
- Logit softcap=15: confirmed optimal (#354)
- Z-loss λ∈{1e-5,1e-4,1e-3}: CLOSED productive-NEGATIVE (#441; softcap c=15 already bounds logits)
- Label smoothing α∈{0.0–0.2}: monotone catastrophic regression; closed (#446 productive-NEGATIVE)

**Clipping**:
- clip=5 → clip=10: MERGED #165
- AGC (per-parameter): productive-null per paired-pod trajectory (#408)
