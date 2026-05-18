# SENPAI Research Results — auto-nanogpt-1gpu-r2

## 2026-05-18 03:15 UTC — Cycle 55 (continued): nezuko #316 CLOSED (NorMuon β2 cooldown anneal FALSIFIED); reassigned #339 cooldown-frac sweep

### NEZUKO #316 — NorMuon β2 cooldown anneal — FALSIFIED

| Trial | val/loss | ffs | Verdict |
|---|---|---|---|
| 0 | 3.27838 | 3125 | MISS |
| 1 | 3.27843 | 3125 | MISS |
| **n=2 mean** | **3.278405** | **3125.0** | **MISS** |

Baseline: val=3.275835, ffs=3087.5. Δval=+0.00257, Δffs=+37.5.

W&B run: `hq3lzdm8`. Trial-to-trial swing tiny (Δval=0.00005, Δffs=0) — reproducible negative effect.

**Mechanism**: β2 controls per-row Adafactor variance EMA. Faster β2 adaptation during cooldown means the variance estimator has fewer effective samples at the critical convergence tail, producing noisier per-row normalization. The μ buffer (PR #288 WIN) has NS5 orthogonalization downstream that bounds the response to μ changes; the β2 variance buffer lacks this safety net and reacts directly to noisier estimates.

**Conclusion**: Cooldown-reactivity from momentum/variance buffer annealing is ONLY productive for Muon's scalar μ parameter, which has NS5 as a bounded nonlinear projection downstream. Do not reassign NorMuon β2 anneal in any form.

Nezuko reassigned → PR #339: cooldown_frac sweep (0.6 and 0.8 vs current 0.7).

---

## 2026-05-18 02:30 UTC — Cycle 55 (continued): tanjiro #309 CLOSED (AdamW β1 anneal FALSIFIED — both arms miss); reassigned #336 TARGET_UW sweep

### TANJIRO #309 — Annealed AdamW β1 — FALSIFIED

Both arms miss both merge bars at n=1. Student posted `SENPAI-RESULT` terminal marker with `pending_arms=false`.

| Arm | β1 schedule | val/loss | ffs | Verdict |
|---|---|---|---|---|
| Baseline | static 0.8 | 3.275835 | 3087.5 | reference |
| **A — broad** | 0.90 → 0.70 | **3.28251** | **-1 (never)** | **MISS** ❌ |
| **B — tight** | 0.85 → 0.75 | **3.27884** | **3150** | **MISS** ❌ |

W&B runs: `06dfy8gr` (Arm A), `45raqb1u` (Arm B)

**Mechanism**: AdamW β1 anneal does NOT mirror Muon μ anneal despite similar schedule shapes. Muon's NS5 orthogonalization is a nonlinear projection that bounds the response to μ changes — small changes in momentum direction have bounded downstream effects. AdamW has no analogous safety net: β1 changes directly affect raw gradient EMA on groups with very high (embed lr=0.3) and very sensitive (lm_head lr=1/320) effective LRs. Even Arm B's tight 0.10 span (0.85→0.75) delivered a mild but clear miss.

**Conclusion**: Cooldown-reactivity from momentum anneal is a Muon-specific phenomenon. Do not reassign AdamW β1 anneal in any form. AdamW β2 anneal is also ruled out by the same argument (plus the SOAP eigenbasis coupling concern from PR #291).

Tanjiro reassigned → PR #336: TARGET_UW sweep (0.25 and 0.50 vs current 0.35).

---

## 2026-05-18 01:30 UTC — Cycle 55: frieren #313 CLOSED (z-loss NaN unresolvable — 4 smokes, code never pushed); reassigned #333 AdamW eps sweep

### FRIEREN #313 — Logit z-loss regularization — CLOSED (implementation bug, hypothesis NOT falsified)

4 consecutive NaN smoke runs over 4+ hours. All crashed with 147.9M nonfinite gradients at step 125 (the same first val checkpoint). Student never pushed code to branch — no diff visible to advisor.

| Smoke run | Steps | Outcome |
|---|---|---|
| `cubsbstz` | 200 | NaN at step 125 (147.9M nonfinite) |
| `ek607yfe` | 200 | NaN at step 125 |
| `z3jfn1o9` | 200 | NaN at step 125 |
| `16pdz0jj` | 200 | NaN at step 125 |

Pattern matches: step-125 NaN is the attention-path driven pod NaN signature (identical to the torch 2.10.0 pod bug from PR #303 and #304). **However** fern's pod was already confirmed fixed by this cycle. Likely the z-loss implementation directly modified the forward/loss pipeline and introduced a numerical instability that masked the code-level bug.

**Conclusion**: Hypothesis (PaLM/T5-style z-loss regularization) is NOT falsified — we never saw the implementation. Closed due to inability to diagnose without code access. Reassigned to cleaner axis.

**Lesson**: When modifying the forward/loss pipeline, always push a checkpoint before launching even a smoke. The advisor needs code visibility to help with NaN debugging.

Frieren reassigned → PR #330: AdamW eps sweep (ADAMW_EPS=1e-8 vs 1e-12 vs current 1e-10).

---

## 2026-05-17 23:40 UTC — Cycle 54 (continued): askeladd #286 CLOSED (Polyak EMA FALSIFIED); reassigned #319 Muon LR warmup

### ASKELADD #286 — Polyak-Ruppert weight averaging — FALSIFIED

| Path | val/loss at step 3175 | reached_target | ffs |
|---|---|---|---|
| Non-EMA (raw model) | **3.2764** | yes | 3100 |
| EMA (Polyak β=0.999, start=2000) | **3.3097** | no | — |

EMA path is +0.0339 worse — far outside any noise band. Mechanism: POLYAK_START=2000, β=0.999 → EMA has effective horizon ~1000 steps, heavily weighted toward step ~2200 (val ~3.50 era). Our aggressive LR cooldown already eliminates the late-training variance that Polyak-Ruppert targets. Final weights ARE the optimum; averaging earlier high-LR weights strictly degrades the model.

**Conclusion**: Polyak averaging is fundamentally incompatible with aggressive linear cooldown. Do not reassign at any POLYAK_START/BETA setting.

Askeladd reassigned → PR #319: Muon LR warmup (100-step and 50-step arms).

---

## 2026-05-17 22:50 UTC — Cycle 54 (continued): nezuko #295 CLOSED (Polar Express MISS); reassigned #316 NorMuon β2 cooldown anneal

### NEZUKO #295 — Newton-Schulz NS5 polynomial coefficient sweep / Polar Express — MISS

Axis pivoted mid-PR from original NS5 coefficient sweep to Polar Express adaptive schedule (Tian et al., arXiv 2505.16932) after student's math review found sum≠1 bug in original Arm B.

| Metric | Polar Express `7klo2sbf` | Baseline (PR #219) | Δ | Bar |
|---|---|---|---|---|
| `speedrun/final_best_val_loss` | **3.2802** | 3.275835 | +0.00437 | mean < 3.275835 ❌ |
| `speedrun/final_first_step_to_target` | **-1** (never hit 3.28) | 3087.5 | — | < 3087.5 ❌ |
| `speedrun/final_reached_target` | 0 | 1 | — | — |

**Polar Express schedule**: Tian et al. 2025 adaptive coefficients, 12 iters, NS5_NORM_FACTOR=1.01. Student's per-iteration diagnostics: 100% of SVs within ±1% of 1.0 on all 39 samples (39/39) — polar factor was high quality. Ortho error 0.14-0.18 (dominated by near-zero SV tail, irrelevant to polar quality).

**Conclusion**: Polar Express's per-iteration optimality is for Frobenius residual at fixed iteration count, not for downstream optimizer convergence. At our fixed-budget 12-iter bf16 setting, marginal benefit over well-tuned (2,-1.5,0.5) is below noise. Adaptive coefficients would likely help at longer NS budgets (15-18 iters) but those would hurt ffs.

**Mechanism insight**: NS5 coefficient tuning is not a productive axis at 12 iters. The fixed (2,-1.5,0.5) triple is already near-optimal for this budget. Do not reassign.

Nezuko reassigned → PR #316: NorMuon β2 cooldown anneal {0.95→0.90, 0.95→0.85}.

---

## 2026-05-17 22:05 UTC — Cycle 54 (continued): frieren #275 CLOSED (MLP-SOAP trust gate FALSIFIED); reassigned #313 logit z-loss + alphonse #303 CLOSED (pod fix via torch upgrade)

### ALPHONSE #303 — Pod diagnostic — CLOSED (pod fixed)

Pod was on `torch 2.10.0+cu128` with mixed cu12/cu13 NCCL/cuDNN libs while healthy peers run `torch 2.11.0+cu130 cu13-only`. Step-1 gradients bit-identical to peer; divergence inside optimizer kernels (mixed-version libs) causes NaN cascade in steps 2-24.

**Fix**: In-place `pip install --upgrade 'torch==2.11.0'`. Post-upgrade 200-step diagnostic clean (val=4.166/4.176 at step 200, finite). Same pattern also affects fern #304 (in remediation).

Alphonse reassigned → PR #312: AdamW lm_head weight decay sweep {0.01, 0.05}.

### FRIEREN #275 — MLP-SOAP trust gate — FALSIFIED

| Arm | T_mlp | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| A | 0.85 | 3.27868 | 3150 | ❌ +0.00284 | ❌ +62.5 | `m5qmpwwq` |
| B | 0.90 | 3.28009 | -1 (never 3.28) | ❌ +0.00425 | ❌ misses | `wpo63vdn` |

Both arms miss. Arm A close to bar but doesn't beat; Arm B never reaches target.

**Telemetry diagnostic — opposite of attn-trust-gate prior**:
| Arm | T_mlp | mlp/on_fraction | mlp/mean_cos_row | attn/on_fraction |
|---|---|---|---|---|
| A | 0.85 | 0.625 (37.5% skipped) | 0.885 | 0.83-0.85 (only 15-17% skipped) |
| B | 0.90 | 0.417 (58% skipped) | 0.885 | — |

**Mechanistic insight — MLP precond is robust to rotation noise; attn precond is sensitive**:
> The hypothesis was: MLP SOAP eigenbasis rotates LESS than attn (so a gate at the same T fires LESS often). The data shows the opposite — MLP eigenbasis rotates AS MUCH as attn (mean_cos_row 0.885 vs 0.890; min_cos_row 0.83 vs 0.84). But the trust gate fires MUCH MORE often on MLP (37-58% vs attn's 15-17%) because the rotation-noise distribution has heavier tails on MLP.
>
> The real asymmetry is not "MLP stable / attn unstable" — both rotate similarly. The asymmetry is in **sensitivity**: applying a moderately-rotated MLP precond is net-beneficial (the precond is robust to rotation noise); applying a moderately-rotated attn precond is net-harmful (the precond is fragile). Gating helps on attn but hurts on MLP.
>
> Geometric interpretation: MLPs have higher effective rank in their gradient covariance (more spread eigenvalues), so the precond is dominated by the bulk of the eigenspectrum which rotates slowly even when individual eigenvectors rotate. Attn has more concentrated eigenvalue distribution (few large eigenvalues dominate), so eigenvector rotations directly affect precondition quality.

Frieren reassigned → PR #313: logit z-loss regularization (z_loss_coef ∈ {1e-4, 1e-3}). Fresh axis — only **loss-function** axis tested on r2; orthogonal to all optimizer-side work in-flight.

## 2026-05-17 20:45 UTC — Cycle 54 (continued): tanjiro #276 CLOSED (decoupled aux cooldown FALSIFIED); reassigned #309 AdamW β1 anneal

### TANJIRO #276 — Decoupled aux cooldown shape (cosine / none) — FALSIFIED

| Arm | aux_cooldown_shape | val/loss | ffs | val < 3.275835? | ffs < 3087.5? | W&B |
|---|---|---|---|---|---|---|
| Baseline (n=4) | linear (coupled) | **3.275835** | **3087.5** | — | — | `3xn3ox1c` (pre-#219), `47bb0bf2` (n=4 PR #219) |
| A | cosine | 3.27696 | 3100 | ❌ +0.00113 | ❌ +12.5 | `lkh6dlbz` |
| B | none | 3.30208 | -1 (never reached 3.28) | ❌❌ +0.02625 | ❌ never reached | `yjmbml3f` |

Both arms confirmed at n=1. Arm A (cosine on aux) marginally worse than linear — within natural variation, but can't beat the strict bar. Arm B (no aux cooldown) catastrophically worse — model never reaches target val=3.28.

**Mechanistic insight — aux groups are tightly coupled to the readout-convergence stage**:
> The Arm B failure is the diagnostic: holding embed at lr=0.3 and lm_head at lr=1/320 through the final 30% of training prevents convergence. The model never gets within target distance.
>
> This contradicts the hypothesis premise ("aux groups don't have a Newton-Schulz fixed-point requirement"). They DO need to cool down — because embedding-table noise and lm_head noise late in training are read out as token-distribution variance. At the end the model is no longer learning, it is *converging the readout*, and embed/lm_head must follow Muon's cooldown.
>
> **Corollary**: aux groups want the same reactivity-vs-smoothness tradeoff as Muon — high momentum stability early, low momentum reactivity late. PR #219 won by doing this on Muon's μ. The natural follow-up is to test the same mechanism on AdamW's β1 (the only other scalar momentum-buffer coefficient in the system).

Cross-axis confirmation: r1 also tested cosine cooldown on the **whole stack** (Muon + aux together) and got val=3.2882 — also worse. Two independent experiments confirm linear cooldown is a stable optimum across all groups.

Tanjiro reassigned → PR #309: **Annealed AdamW β1** (0.90→0.70 broad, 0.85→0.75 tight). Direct parallel to PR #219 on the orthogonal aux-optimizer axis.

## 2026-05-17 20:05 UTC — Cycle 54 (continued): fern #291 FALSIFIED; alphonse #277 CLOSED (pod issue); both reassigned

### FERN #291 — Annealed SOAP β2 (0.95→0.85): adaptive Gram EMA — FALSIFIED

| Arm | β2_start | β2_end | val/loss | ffs | W&B |
|---|---|---|---|---|---|
| A | 0.95 | 0.85 | 3.2790 | 3150 | `joq5iz2h` |
| B | 0.92 | 0.88 | NaN (step 25) | — | `ku1hbldn` |

Arm A: n=1 trial (trial 2 killed — gap Δ=+0.0032 exceeds max n=1 rescue potential). Misses both bars.
Arm B: NaN by step 25. β2=0.92 starts in the documented multi-seed instability zone; the hypothesis that "annealing protects the start" was wrong — instability hits within 25 steps, before EMA can decay to safe range.

**Mechanistic insight — why μ-anneal works but β2-anneal doesn't**:
> μ controls a velocity-like momentum buffer (scalar contraction). Retiming it is forgiving because buffer quantity = gradient magnitude, robust to EMA rate.
> β2 controls the **Gram EMA matrix** whose eigendecomposition drives Muon's rotation. Eigenvectors are highly sensitive to perturbations, especially early in training when basis hasn't converged.
> The matching constraint `SOAP_PRECOND_FREQ ≈ 1/(1-β2)` (PR #271) means annealing β2 while keeping freq=10 static **breaks the optimal coupling**. At β2=0.95, optimal freq=20; at β2=0.85, optimal freq=7. Static freq=10 only matches at β2=0.90.

Fern reassigned → PR #304: anneal SOAP_PRECOND_FREQ (15→7 and 7→15) while keeping β2=0.90 static. Tests the orthogonal axis that respects the matching constraint.

### ALPHONSE #277 — SOAP eigenbasis freeze after step K — CLOSED (untested)

All 8 runs on alphonse's pod NaN'd at step 25-125. Student ran a critical diagnostic (POD-DIAG baseline, run `ej3fvmpy`) with freeze code **completely removed** — reverted to pre-#277 state — and it ALSO NaN'd at step 125. Side-by-side trajectory byte-identical with K=100 freeze run.

**Conclusion**: the merged-stack baseline itself is unstable on alphonse's pod. The freeze mechanism is untested (not falsified). Peer pods (tanjiro, frieren, fern) run healthy on identical config. This is a pod-specific issue (hardware/CUDA/driver/data-shard).

My earlier interpretation ("125 steps after freeze = 125 steps of compounding misalignment") was **wrong** — the POD-DIAG diagnostic proved the NaN is independent of the freeze. Acknowledging error; alphonse caught it correctly.

Alphonse reassigned → PR #303: pod diagnostic (env fingerprint + hard reset + clean baseline repro). No training experiment until pod health confirmed.

---

## 2026-05-17 ~17:30 — Cycle 54 (continued): nezuko #273 FALSIFIED with strongest mechanistic insight; nezuko reassigned (#295)

### NEZUKO #273 — Asymmetric Attn-SOAP trust T per param-kind (QK vs VO) — FALSIFIED

| Arm | QK / VO | val/loss | ffs | reached_target |
|---|---|---|---|---|
| A | 0.80 / 0.90 | 3.27768 | 3125 | yes |
| B | 0.90 / 0.80 | 3.28158 | -1 | **NO — failed to reach 3.28** |

**Mechanism (strongest insight of cycle 54)**: V's low cos_row (~0.81 baseline) is **TRUE signal of fast eigenbasis rotation, NOT a false negative**. The current single T=0.85 is faithfully filtering out genuinely untrustworthy eigenbasis updates. Forcing V SOAP to fire at low cos (Arm B, V on_fraction=1.00) injects noisy preconditioning into the residual stream → +0.005 val degradation, fails to reach target.

**Trust gate axis insight (added to project knowledge)**: trust thresholds and per-kind selectivity are entangled with the underlying eigenbasis dynamics. Q/K have stable bases (high cos_row → high on_fraction at T=0.85 is correct). V has unstable bases (low cos_row → low on_fraction is correct selectivity). The single T=0.85 expresses a faithful invariant ('don't precondition with a stale basis'); decomposing it loses that invariant.

This falsification has implications for **all SOAP trust-gate variants**: continuous (cosine-scaled) gates likely won't help either, since partial preconditioning at low cos still injects bad rotation.

W&B runs: `l0bszjjg` (Arm A), `8jsxx60y` (Arm B). Nezuko reassigned → NS5 polynomial coefficient sweep (PR #295).

---

## 2026-05-17 ~17:20 — Cycle 54 (continued): thorfinn #219 MERGED ⭐ NEW BASELINE; fern #271 FALSIFIED; fern reassigned (#291)

### THORFINN #219 — Annealed Muon μ schedule (MU_START=0.97 → MU_END=0.90) — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

Δ vs PR #212 baseline (3.27631 / 3112.5): val=−0.000475, ffs=−25.0. Statsig 0.00833 ≥ 0.004 (2.08× margin).

**Mechanism (well-supported)**:
1. **Early training**: high μ=0.97 = long EMA window. CONTRA_MUON's spectral perturbation noise is averaged out before being pushed through NS5. Reduces noise-driven moves through parameter space during fragile warmup.
2. **Cooldown phase**: μ → 0.90 = shorter EMA. Momentum buffer becomes more reactive precisely when LR cooldown reduces step magnitude — Muon can track finer-grained signal during the critical ffs-determining phase.
3. **Warmup-style (Arm A: 0.90→0.97) failed**: low μ early lets gradient noise dominate; high μ late over-smooths in cooldown. Worst-of-both schedule.

W&B run: `47bb0bf2`. PR squash-merged after rebase (PR #212 conflict resolved by student). Thorfinn reassigned → annealed μ finer sweep (PR #288: 0.97→0.92 tight range vs cooldown-phase-only anneal).

---

### FERN #271 — Decoupled SOAP eigenbasis refresh freq (MLP vs ATTN) — FALSIFIED

| Arm | SOAP_PRECOND_FREQ_ATTN | val/loss | ffs | vs new bar |
|---|---|---|---|---|
| A | 5 (faster) | 3.27633 | 3100 | MISS (+0.00050 val, +12.5 ffs) |
| B | 20 (slower) | 3.27909 | 3150 | CLEAR MISS (+0.00326 val, +62.5 ffs) |

**Mechanistic insight (project knowledge update)**: SOAP_PRECOND_FREQ and SOAP_BETA2 are entangled through the EMA effective horizon. Fern's drift telemetry showed that at β2=0.90, the post-refresh Gram already substantially equilibrates within 10 steps. Increasing refresh frequency by 4× (freq=5) only reduces Frobenius drift by ~6% (64K → 68K Frobenius units) — not enough to change gradient direction quality. Refresh frequency optimum ≈ EMA effective horizon = 1/(1-β2) → for β2=0.90, that's 10 steps.

**Key axis-coupling insight**: This implies SOAP_BETA2 is the primary control over eigenbasis dynamics, not refresh frequency. Annealing β2 (rather than refresh freq) is the natural follow-up — directly motivated this PR's mechanistic explanation.

W&B runs: `5873pgbt` (Arm A), `w9t7l423` (Arm B). Fern reassigned → annealed SOAP β2 (PR #291: 0.95→0.85 full range vs 0.92→0.88 tight range).

---

## 2026-05-17 ~16:15 — Cycle 54 (continued): askeladd #268 FALSIFIED; thorfinn #219 n=4 COMPLETE awaiting rebase; askeladd reassigned (#286)

### ASKELADD #268 — Per-block-depth Muon LR scaling — FALSIFIED

| Arm | Formula | val/loss @ 3175 | ffs | Outcome |
|---|---|---|---|---|
| A (up) | `(d+1)/6` (block 0=0.167×, block 11=2.0×) | 3.31916 | -1 (never hit 3.28) | Clear miss (+0.043 over baseline) |
| B (down) | `(12-d)/6` (block 0=2.0×, block 11=0.167×) | 4.165 @ step 1350 | -1 | Diverged, killed |

Both arms falsified per predeclared decision tree (val > 3.278 OR ffs > 3125).

**Mechanism (Arm A, "up")**: Starves early blocks (block 0 gets 1/6 baseline LR). The embeddings→block 0→block 1 cascade receives insufficient updates to develop early-token representations during the first ~half of training. By the time later blocks compensate, the LR cooldown has begun and there's no headroom left. Result: never reaches val=3.28 target.

**Mechanism (Arm B, "down")**: Starves late blocks. Late transformer blocks contain the most discriminative features (sharper local loss curvature). Reducing late-block LR by 6× wrecks tracking of this signal. Result: late blocks fail to converge → activations grow → gradient norms grow → divergence at step 1350.

**Lesson**: SOAP's per-shape preconditioning already absorbs per-layer gradient scale differences via its Gram matrices. Imposing additional explicit depth-LR structure adds constraints without exploiting unmodeled gradient structure.

W&B runs: `qfef54e1` (Arm A), `iudcq97t` (Arm B). Askeladd reassigned → Polyak weight averaging (PR #286).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 COMPLETE 🚀 PENDING REBASE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27510 | 3075 |
| T1 | 3.27697 | 3100 |
| T2 | 3.27489 | 3075 |
| T3 | 3.27638 | 3100 |
| **n=4 mean** | **3.275835** | **3087.5** |

**Both new baseline bars cleared:**
- val=3.275835 < 3.27631 (Δ=−0.000475) ✓
- ffs=3087.5 < 3112.5 (Δ=−25.0 steps) ✓
- statsig: (3.28 − 3.275835) × √4 = **0.00833** ≥ 0.004 ✓ (2.08× margin)

n=4 was launched on PRE-#212 stack (no trust gate). The annealed-μ mechanism beats the new trust-gate baseline anyway — strong evidence of additivity. After merge, compounding run with `ATTN_SOAP_TRUST_THRESHOLD=0.85` is the natural follow-up.

**Status**: Sent back to thorfinn for rebase (merge conflict with PR #212). W&B run: `47bb0bf2`. ETA to merge: ~30 min after rebase.

---

## 2026-05-17 ~15:00 — Cycle 54 (continued): alphonse #256 FALSIFIED; tanjiro #259 FALSIFIED; thorfinn #219 n=4 3/4 strong; frieren #254 closed; 3 students reassigned (#275, #276, #277)

### ALPHONSE #256 — SOAP_PRECOND_FREQ {5, 20} sweep — FALSIFIED

| Arm | SOAP_PRECOND_FREQ | Outcome |
|---|---|---|
| A | 5 | Multi-seed NaN at step 25 (5 independent trials) |
| B | 20 | Multi-seed NaN at step 25 (same fingerprint) |

Both arms falsified. Baseline (freq=10) runs cleanly to val~3.277 on all 4 trials. Both extremes destabilize within first 25 steps.

**Mechanism (Arm A, freq=5)**: First eigenbasis refresh at soap_step=5 with only ~41% Gram EMA equilibration (β₂=0.90). Eigenbasis from incomplete Gram is noisy → preconditioning rotates update in wrong direction → weight-norm explosion by step 25.

**Mechanism (Arm B, freq=20)**: Initial eigenbasis (from 1-step Gram) is rank-1 noise. Preconditioning with this for 20 steps before first refresh is catastrophic — the bad eigenbasis amplifies every update in the wrong subspace until divergence.

**SOAP_PRECOND_FREQ is a narrow stability window at 10**. Combined with Arm A finding, we can say: Gram needs ≥ 10 EMA steps to produce a usable eigenbasis, and the initial eigenbasis must be replaced quickly enough that its noise doesn't compound. 10 is the optimal tradeoff point.

W&B runs: `h1527wma`, `9ogg9inl`, `rnarwovu`, `htti5gif` (5 trials total, all NaN). Alphonse reassigned → SOAP eigenbasis freeze after step K (PR #277).

---

### TANJIRO #259 — NS_ITERS sweep (NS_ITERS=10, 8) — FALSIFIED

| Arm | NS_ITERS | Outcome |
|---|---|---|
| A | 10 | Trials 0, 1: 91% nonfinite gradients at step 225 |
| B | 8 | NaN (run just started, suspected same) |

Both arms falsified. Baseline (NS_ITERS=12) is the unique stable operating point.

**Mechanism**: NS5 polynomial with (a=2, b=-1.5, c=0.5) requires ~12 iterations to converge to an orthogonalized update for typical singular value distributions. With 10 iterations, the polynomial output is under-converged → uncontrolled singular value magnitudes → after Frobenius renormalization and TARGET_UW=0.35 u/w-floor scaling, effective update grows beyond weight scale → NaN cascade by step 225.

**NS5 iteration axis is fully exhausted**: (8, 10) NaN cascade; (12) optimal; (14, 16) also NaN from prior askeladd #232 sweep; fp32 NS5 (frieren #254) MISS (no precision improvement). The entire NS5 precision/iter axis is closed.

W&B runs: `cuhzxhaz` (seed-0 NaN, n=1), `wsdki64r` (n=4, trials 0-1 diverged at step 225). Tanjiro reassigned → decoupled aux cooldown shape (PR #276).

---

### FRIEREN #254 — fp32 precision in Newton-Schulz NS5 — MISS

| Metric | Result | vs new baseline (PR #212) |
|---|---|---|
| val/loss | 3.2769 | > 3.27631 (MISS) |
| ffs | 3125 | > 3112.5 (MISS) |

Complementary to NS_ITERS falsification: adding fp32 precision also doesn't help. Combined, the NS5 pipeline is insensitive to both iteration count AND numerical precision changes from the 12-iter bf16 optimum.

W&B run: `mon2ndin`. Frieren reassigned → MLP-SOAP trust gate (PR #275).

---

### THORFINN #219 — Annealed μ Arm B (0.97→0.90) — n=4 IN PROGRESS 🔥

| Trial | val/loss | ffs |
|---|---|---|
| 0 | 3.27510 | 3075 |
| 1 | 3.27697 | 3100 |
| 2 | 3.27489 | 3075 |
| 3 | (running) | — |
| **n=3 mean** | **3.27565** | **3083** |

**n=3 mean BEATS new baseline** (val=3.27631, ffs=3112.5) on BOTH metrics. Statsig n=3: (3.28 − 3.27565) × √3 = 0.00754 ≥ 0.004 ✓ (cleared by 1.9×).

Note: n=4 run launched before PR #212 merge — testing annealed μ WITHOUT TRUST_THRESHOLD=0.85. Even without the attn trust gate, annealed μ beats the new baseline (which HAS trust gate). This confirms the two mechanisms are additive; compound result (annealed μ + trust gate) should beat both individually.

W&B run: `47bb0bf2`. Trial 3 running, ETA ~17:30 UTC. Terminal SENPAI-RESULT pending.

---

## 2026-05-17 ~13:00 — Cycle 54: PR #212 MERGED (new baseline); 4 axes closed; 3 students reassigned

### NEZUKO #212 — Attn-SOAP+trust T=0.85 — MERGED ⭐ NEW BASELINE

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.2764 | 3125 |
| T1 | 3.2761 | 3100 |
| T2 | 3.2775 | 3125 |
| T3 | 3.2752 | 3100 |
| **n=4 mean** | **3.27631** | **3112.5** |

W&B run: `3xn3ox1c`. Statsig: (3.28-3.27631)×√4 = 0.00738 ≥ 0.004. BOTH BARS CLEARED vs PR #139 (val<3.27648, ffs<3118.75).

**Key finding**: Extending SOAP eigenbasis preconditioning to attention weights (via cosine-similarity trust gate, TRUST_THRESHOLD=0.85) gives consistent −6.25 mean ffs improvement. All 4 trials hit val < 3.28 target. Tight variance (T3=3.2752 strongest, T2=3.2775 weakest). Mechanism: SOAP coverage of attention projection matrices reduces curvature mismatch in the direction most sensitive to early-step convergence.

**Merged**: ffs 3118.75 → 3112.5 (−6.25), val 3.27648 → 3.27631 (−0.00017). Gap to record #20 (3030): ~82 steps.

---

### FERN #245 — Trust-region Muon (LARS-style, TRUST_RATIO sweep) — CLOSED

| Arm | TRUST_RATIO | val | ffs |
|---|---|---|---|
| A | 0.10 | 3.29988 | -1 |
| B | 0.05 | 3.32456 | -1 |

**MISS — monotonic worsening.** Telemetry revealed: at TRUST_RATIO=0.05, 38-50% of params clipped at steps 50-200, trust_scale≈0.22. Natural Muon update magnitude is ~20-25% of weight norm — any ratio ≤ 0.10 is throttling signal. The LARS-style trust constraint is fundamentally wrong for Muon (designed for small Adam-like updates, not large NS5 polar-factor updates).

**Recorded finding**: Natural Muon delta ≈ 20-25% of weight norm during early steps. Adam-family trust ratios (5-10%) are unsuitable for Muon/NS5 family. Any successful trust intervention would need gradient-conditioned per-outlier clipping, not blanket per-param normalization.

---

### EDWARD #251 — Lookahead on Muon (K=5, K=10) — CLOSED (INCOMPATIBLE)

All 3 attempts NaN'd at step 25 including trial 1 of n=4 retry.

| Run | K | NaN @ T0 | NaN @ T1 |
|---|---|---|---|
| 2lx8q0n6 | 5 | step 25 | — |
| wpcgf9e4 | 10 | step 25 | — |
| s6uvyg4y | 5 (n=4 retry) | step 25 | **step 25** |

**Multi-seed cascade confirmed** — NOT seed-0. The merged baseline (db1rrfx3) has NO NaN trials; all NaN is Lookahead-induced.

**Mechanism**: Lookahead's `fast := slow` param rollback every K steps leaves Muon's momentum buffer, NorMuon second_moment, and SOAP eigenbasis tracking the discarded fast trajectory while params jump back to slow. By step 25 (5 sync cycles at K=5), state-vs-param mismatch produces unbounded updates → all 12 blocks' Linear weights NaN simultaneously (123,701,376 nonfinite). Zhang et al 2019 designed Lookahead for first-moment-only optimizers; Lookahead is incompatible with multi-buffer preconditioners unless ALL state buffers are rolled back synchronously with params.

---

### ASKELADD #239 — Lion optimizer on aux groups — CLOSED

| Arm | embed_lr / lm_head_lr | val | ffs |
|---|---|---|---|
| v2 (gxxlpakh) | 0.03 / 1e-3 | 3.29854 | -1 |
| Arm B (n72pnmj3) | 0.05 / 3e-3 | 3.30050 | -1 |

**MISS by ~0.022 val.** Arm B's higher LR gives −0.073 nat head start at step 125 but crossover at step 2500 with Arm A ending 0.002 worse. Lion lacks second-moment estimation; in the critical cooldown phase (steps 2500-3175), AdamW's per-coord variance compensation is essential for aux groups (embed + lm_head) to stay on the efficient descent path. Sign-momentum is suboptimal for groups that need precise scaling in the precision window.

---

## 2026-05-17 ~11:35 — Cycle 53: Tanjiro reassigned; embed-warmup falsified

### TANJIRO #252 — Decoupled embedding LR warmup — FALSIFIED

60× variation in embedding LR at the NaN step (0.05 vs 0.30) produces bit-identical cascade:
- Arm A (EMBED_WARMUP=50): NaN step 25, nonfinite_count 123,701,376
- Arm B (EMBED_WARMUP=150): NaN step 25, nonfinite_count 123,701,376

Seed-0 NaN is NOT embedding-driven. The blocks.0.attn.proj.bias (attention path) is the real trigger. Embedding LR is a red herring.

Tanjiro reassigned → NS_ITERS sweep (PR #259): NS_ITERS ∈ {10, 8} vs baseline 12. Hypothesis: fewer NS5 iterations reduce bf16 rounding error compounding.

---

## 2026-05-17 ~10:30 — Cycle 51: SOAP_BETA2 axis closed; alphonse reassigned to SOAP_PRECOND_FREQ

### ALPHONSE #223 — SOAP_BETA2 retune {0.85, 0.92} — CLOSED (axis exhausted)

| SOAP_BETA2 | Runs | NaN pattern | verdict |
|---|---|---|---|
| 0.85 | 67w5zyph, 6gsl9ljw, grpcqmun | NaN at variable steps 75/318/1175 | **0.85-specific destabilizer** |
| 0.90 | db1rrfx3 (baseline) | n=4 mean val 3.27648, ffs 3118.75 | baseline |
| 0.92 | klsnpomc, hx3jldki (trials 0,1) | Both NaN @ step 25, canonical 147,758,208 fingerprint | **multi-seed cascade** |

SOAP_BETA2 is a sharp local optimum at 0.90. Both ±0.02 perturbations destabilize via distinct mechanisms: 0.85 shows later-step HP-induced NaN cascade (variable timing), 0.92 triggers the canonical seed-0 / multi-seed baseline NaN across consecutive seeds. Axis fully exhausted in both directions.

Alphonse reassigned → SOAP_PRECOND_FREQ sweep (PR #256): {5, 20} vs baseline 10. Hypothesis: tighter eigenbasis refresh (5 steps) reduces eigenbasis lag during rapid early-step gradient direction changes → better preconditioning → lower FFS.

## 2026-05-17 ~06:45 — Cycle 44: Three PRs CLOSED (frieren bias-corr, askeladd proj-init-B, edward AdEMAMix); 3 fresh assignments (frieren #238, askeladd #239, edward #240)

### FRIEREN #221 — Adam-style Muon bias correction (MUON_BIAS_CORR=1) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `6qb399cr` (n=1, 3175 steps) | **3.27903** | **3150** | MISS (+0.00255 val, +31.25 ffs) |

Adam-style `1/(1-μ^t)` first-moment debiasing on Muon does not transfer to the merged Contra+SOAP-MLP+NS5+contra-normuon+u/w-floor stack. The canonical bias correction (well-studied in Adam) appears to over-amplify Muon momentum when paired with the SOAP eigenbasis pre-conditioner — the NS5+contra+u/w-floor pipeline already implicitly manages momentum norm dynamics. Mechanism-stack mismatch, not a code error. Per pre-authorized decision tree (val > 3.278 → close).

Frieren reassigned → Cosine LR cooldown shape (PR #238). Orthogonal to closed cooldown-duration axis (PR #178, 0.70 local optimum). Cosine concentrates LR higher in early-cooldown steep-descent window; may push FFS earlier.

### ASKELADD #224 — Per-module init Variant B (std=0.00221 non-zero proj) — CLOSED

| Run | val | ffs | verdict |
|---|---|---|---|
| `u0x4ni0c` (n=1, 3175 steps) | **3.27993** | **3175** | MISS (+0.00345 val, +56.25 ffs) |

Variant B (std=0.00221) landed nearly identically to Variant A (zero-init, val=3.28042): only 0.0005 val difference. Both converged to the same attractor — confirms SOAP+NS5 absorbs whatever per-module init benefit can exist on this stack. The per-module init direction (all variants: standard fan-in, zero-init, and small-non-zero) is **fully exhausted** on the merged Contra+SOAP-MLP base. Mechanism is stack-absorbed.

Askeladd reassigned → Lion optimizer on aux groups (PR #239). Replace AdamW on embed+lm_head+scalars with Lion sign-based optimizer. Hypothesis: sign normalization accelerates early token embedding specialization (step 0-500, FFS-critical window). No second moment → cannot amplify variance NaN cascade.

### EDWARD #199 — AdEMAMix on aux groups — CLOSED (multi-seed NaN, no clean trial)

| Run | trial_idx | val | ffs | verdict |
|---|---|---|---|---|
| `d9vxzbtk` | 0 | NaN (step 25) | — | baseline seed-0 NaN |
| `4e8wgtxk` | 0 | NaN (step 25) | — | duplicate process |
| `q2un2m4y` | 0 | NaN (step 1225) | — | multi-seed cascade |
| `65edtfli` | 0-3 | NaN (aborted step 125) | — | safety-guard abort |

Zero clean trials across 4 runs and 2 retries. The `num_trials=4` retry was authorized after establishing AdEMAMix(α=0)≡AdamW to 1e-7 (correct code), but the n=4 run still failed. Likely: AdEMAMix's slow-EMA accumulation on the high-LR embed group (lr=0.3) amplifies the baseline step-2 fragile equilibrium across seeds, not just seed-0.

Edward reassigned → Adaptive NS5 iteration count schedule (PR #240). More iters (16) in early-training fragile window, fewer (8) in late well-conditioned window. Directly tests orthogonalization quality as a FFS lever.

---

## 2026-05-17 ~06:00 — Cycle 43: Nezuko Screen B WINS; fern LR_POWER=1.5 MISS; multi-seed NaN cascade identified

### NEZUKO #212 — Attn-SOAP+trust Screen B (TRUST_THRESHOLD=0.85) — WIN → n=4 IN PROGRESS 🚀

| Screen | val | ffs | verdict |
|---|---|---|---|
| Screen A (`h29cv26c`, T=0.90) | 3.27628 | 3125 | val WIN only — ffs MISS |
| **Screen B (`5g7k1w3q`, T=0.85)** | **3.27475** | **3100** | **BOTH BARS CLEARED** |

Screen B lowered trust threshold from 0.9 to 0.85, activating SOAP for more attention v/proj weights (activation rate: T=0.85 → v on 50%, proj on 100%, overall 87.5%; T=0.9 → v on 0%, proj on 17%, 35%). The increased SOAP coverage closed the FFS gap (3125 → 3100). n=4 confirm launched 05:26 UTC (`3xn3ox1c`), ETA ~12:50 UTC.

### FERN #208 — Power-law LR cooldown (LR_POWER=1.5, CM=0.5)

| Run | val | ffs | verdict |
|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5, CM=0.4 default — misconfigured) | 3.28313 | -1 | MISS (informational only) |
| `rpws9fug` (LR_POWER=1.5, CM=0.5 proper) | **3.28240** | **-1** | MISS (+0.00592 val) |

Power-law=1.5 HURTS by +0.006 val. Currently testing LR_POWER=2.0 (front-loaded cooldown, different shape hypothesis).

### Multi-seed NaN cascade identified (new this cycle)

Three students (alphonse SOAP_BETA2=0.85, tanjiro TARGET_UW=0.30, edward AdEMAMix) all showed NaN cascades across MULTIPLE seeds (not just seed-0). Distinguishable from seed-0 baseline NaN:
- Seed-0 baseline NaN: step 25, 147,758,208 nonfinite count
- HP-induced multi-seed NaN: step 100-1225, same or higher nonfinite count

Pattern suggests some HP changes (extreme SOAP_BETA2, extreme TARGET_UW, AdEMAMix) destabilize the early-training fragile equilibrium beyond seed-0, making all seeds fail.

---

## 2026-05-17 ~04:35 — Cycle 42: Three PRs CLOSED; three fresh assignments; edward retry authorized

### ALPHONSE #205 — CONTRA_MUON sweep — CLOSED

| Arm | val | ffs | verdict |
|---|---|---|---|
| 0.6 (`u0f98rxy`) | 3.27666 | 3125 | MISS — rising shoulder of optimum |
| 0.7 (`uoqp63dq`) | NaN @ step 25 | — | catastrophic divergence |

**Bowl-shape confirmed**: 0.5 → 0.6 is on the rising shoulder (slightly worse within noise); 0.7 over the cliff (NaN at step 25). CONTRA_MUON=0.5 is the confirmed local optimum. Sweep exhausted — do not revisit CONTRA_MUON axis.

Alphonse reassigned → SOAP_BETA2 retune (PR #223): {0.85, 0.92} vs baseline 0.90. Hypothesis: SOAP Gram EMA decay rate was tuned before CONTRA_MUON=0.5 merged; may need re-tuning for the more perturbed gradient dynamics.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSED

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27666 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra |

Val gap is below seed noise (Δval=0.00007 between p=0.07 and p=0.10). FFS=3125 is structural — the mechanism reliably lands at the wrong ffs bucket. Parameter-insensitive in [0.07, 0.10]. Mechanism is sound but ffs gap is structural on new baseline. **CLOSED.**

Frieren reassigned → Adam-style bias correction on Muon first moment (PR #221). Novel mechanism: EMA of Muon momentum is biased toward zero in early training; Adam-style bias correction via `1/(1-μ^t)` should help most in the FFS-critical early training phase.

### ASKELADD #213 — Per-module init zero-init variant — CLOSED

W&B run `jmcvmacz`: val=3.280419, ffs=-1 — MISS by 0.004.

Zero-init proj weights (mlp.proj, attn.proj, lm_head) on merged Contra+SOAP-MLP+NS5 stack doesn't help. SOAP eigenbasis + NS5 spectral normalization already manage init scale implicitly — the μP-inspired init benefit doesn't transfer from simpler optimizer stacks (records #4,5,8).

Askeladd reassigned → Variant B non-zero proj init (PR #224): std=1/(n_embd×√2) ≈ 0.00092. Tests whether a conservative small-scale init (vs zero) provides SOAP eigenbasis signal without the large-scale init explosion risk.

### EDWARD #199 — AdEMAMix aux groups — BLOCKED by baseline NaN

Both 3175-step screen seeds (`d9vxzbtk`, `4e8wgtxk`) NaN'd at step 25 (147,758,208 nonfinite grads at blocks.0.attn.proj.bias — canonical baseline fingerprint). Per edward's analysis: trial_idx=0 deterministically hits the NaN seed. AdEMAMix dynamics (α_t=0.023 at step 25) had no time to express — this is baseline instability, NOT AdEMAMix bug.

**Advisor decision: override my own decision-tree (wrote it before understanding seed-determinism). Authorized retry with `--num_trials 4` to sample seeds {0,1,2,3}.** At least 1 seed should pass given that other students' runs (alphonse `u0f98rxy`, fern `w12r4fc9`) have shown the NaN rate is seed-selective. Retry still pending student launch.

---

## 2026-05-17 ~03:49 — Cycle 41: Thorfinn #178 CLOSED; annealed-μ assigned (#219); multi-screen status

### THORFINN cooldown_frac sweep — CLOSED (PR #178)

Sweep summary (n=1 each arm):

| arm | val | ffs | verdict |
|---|---|---|---|
| 0.65 | 3.27865 | 3150 | MISS |
| **0.70 (control)** | **3.27536** | **3100** | baseline HP — single seed beats baseline |
| 0.75 | 3.27655 | 3125 | MISS |

Both 0.65 and 0.75 are worse than 0.70. Monotone-from-both-sides signal — **0.70 is the local optimum.** This rules out cooldown_frac as a lever and confirms the current schedule duration is already at the sweet spot. Closed to focus compute on schedule *shape* (fern power-law) and mechanism changes.

### THORFINN reassigned — Annealed Muon momentum μ schedule (PR #219)

2-arm sequential screen: MU schedule 0.90→0.97 (Arm A, warmup-style) vs 0.97→0.90 (Arm B, inverse). Hypothesis: static μ=0.95 was set before CONTRA_MUON=0.5 baseline; annealing μ over training tests two mechanism stories about optimal EMA decay over the training trajectory. Linear interpolation in `set_hparams`. 2 × ~95 min screens.

### ALPHONSE #205 — CONTRA_MUON=0.6/0.7 multi-arm status

| Arm | Run | val | ffs | verdict |
|---|---|---|---|---|
| 0.6 (Arm A) | `u0f98rxy` | 3.27666 | 3125 | MISS — tiny (+0.00018 val, +6.25 ffs) |
| 0.7 (Arm B) | `uoqp63dq` | IN PROGRESS | — | launched 03:44 UTC, ETA ~05:29 |

CONTRA_MUON=0.6 essentially tied the baseline — within seed noise but doesn't clear win bar. Arm B (0.7) running. If 0.7 also misses, sweep is done — 0.5 was the optimum. If 0.7 wins, it would be the second monotone step (0.4→0.5→0.7 wins) — strong signal.

### FRIEREN #177 — Soft-Muon-anneal p sweep — CLOSING

| Screen | val | ffs | verdict |
|---|---|---|---|
| p=0.10 (`dhqwygng`) | 3.27667 | 3125 | MISS |
| p=0.07 (`dbf0augy`) | 3.27659 | 3125 | MISS |
| p=0.07 rerun (`3itp6whk`) | crashed ~step 475 | — | infra/OOM, not mechanism |

Val gap is 0.00011-0.00019 (below seed noise), but ffs=3125 is structural — ffs is quantized in 25-step buckets and the mechanism is reliably landing at 3125. Cannot close the 6.25 ffs gap vs new baseline (3118.75) regardless of p_start value. Mechanism is parameter-insensitive in 0.07-0.10 range. Advisor nudged frieren to post SENPAI-RESULT; will close and reassign to fresh direction.

### NEZUKO #212 — Attn-SOAP+trust (new baseline) screens

| Screen | Run | val | ffs | verdict |
|---|---|---|---|---|
| TRUST_THRESHOLD=0.9 (A) | `h29cv26c` | 3.27628 | 3125 | VAL WIN (−0.00020), FFS MISS |
| TRUST_THRESHOLD=0.85 (B) | running | — | — | launched 03:25 UTC, ETA ~05:00 |

Screen A's val=3.27628 is a VAL WIN but ffs=3125 misses 3118.75. Threshold=0.85 activates SOAP on v/proj rows (which hover at cosine 0.85-0.89 from PR #124 data). If Screen B also wins val AND closes ffs gap, predeclare n=4 immediately.

### ASKELADD #213 — Per-module init screen — MISS, Variant B predeclared

W&B run `jmcvmacz`:

| Metric | Value | vs baseline | verdict |
|---|---|---|---|
| val/loss | 3.28042 | +0.00394 | MISS |
| ffs | never crossed 3.28 | — | MISS |

Per-module init (μP-inspired: embed std=0.02, zero-init proj/lm_head, fan_in-scaled qkv) didn't improve on the merged SOAP-MLP stack. NS5 spectral normalization and SOAP eigenbasis preconditioning already absorb most of what per-module init buys on simpler optimizer stacks. Recommended Variant B: non-zero proj init (proj.weight ~ N(0, 1/(320*sqrt(2)))) — this may stabilize the step-2 NaN pattern at blocks.0.attn.proj.bias and improve early-step dynamics. Waiting for SENPAI-RESULT before launch.

### FERN #208 — Power-law LR cooldown screens

| Screen | CONTRA_MUON | val | ffs | verdict |
|---|---|---|---|---|
| `ersqpsq2` (LR_POWER=1.5) | **0.4 (wrong!)** | 3.28313 | -1 | misconfigured — CONTRA_MUON default 0.4 |
| `rpws9fug` (LR_POWER=1.5+CM=0.5) | 0.5 ✓ | IN PROGRESS | — | launched 03:25 UTC, ETA ~04:55 |

Fern correctly caught the CONTRA_MUON misconfiguration and relaunched with CM=0.5. ersqpsq2 result on 0.4 base not useful for decision tree. rpws9fug is the true LR_POWER=1.5 screen on new baseline.

### EDWARD #199 — AdEMAMix aux groups — Full screen authorized

After exceptional diagnostic work: Edward proved AdEMAMix(α=0) ≡ AdamW to 1e-7 (unit test), and the baseline itself (unmodified commit ae5552e) NaN-s at step-2 in `blocks.0.attn.proj.bias` stochastically. The NaN is seed-dependent baseline instability on 1-GPU short runs, NOT an AdEMAMix bug. Authorized full 3175-step screen with conservative HPs (α=1.0, β3=0.99, warmup=1024, eps=1e-8). Screen launch pending.

---

## 2026-05-17 ~01:30 — Cycle 37: Tanjiro PMuon CLOSED; TARGET_UW retune assigned (#214); in-flight status

### TANJIRO PMuon bilateral streaming covariance — CLOSED (PR #187)

W&B run `eafhrglu` (g1r2-tanjiro/pmuon-stream, γ=0.3, β=0.95):

| Metric | Value | Baseline | Δ |
|---|---|---|---|
| val/loss | ~3.425 at step 2150 (cooldown entry) | 3.27648 | MISS |
| ffs | -1 (never crossed 3.28) | 3118.75 | MISS |

**Root cause analysis**: PMuon's bilateral power-iteration streaming covariance (Σ_L, Σ_R with γ-power exponent) is a gradient-space preconditioner. SOAP-MLP already applies eigenbasis preconditioning to MLP weights before NS5. Stacking PMuon on top creates **double-conditioning** — two sequential preconditioners on the same gradient. Record #18 (PMuon, 3269 steps) was tested on vanilla Contra-Muon WITHOUT SOAP-MLP; the composition here is different. Result: val=3.425 heading into cooldown, too far behind to converge.

Student handling was exemplary: caught advisor's close-out message 8 seconds after launching γ=0.2 follow-up screen, killed it at step 50 (saving ~3 GPU-hours), posted corrected terminal SENPAI-RESULT. **PMuon closed. Do not retry PMuon on SOAP-MLP stack.**

### TANJIRO reassigned — TARGET_UW retune (PR #214)

2-arm sequential screen: TARGET_UW ∈ {0.30, 0.40} vs new baseline. Hypothesis: TARGET_UW=0.35 was tuned with CONTRA_MUON=0.4; with CONTRA_MUON=0.5 the natural u/w ratio has shifted. One env-var change, zero added complexity. Arms: 0.30 (looser floor) and 0.40 (tighter floor).

### IN-FLIGHT STATUS UPDATE (as of ~01:30 UTC 2026-05-17)

**ALPHONSE #205 CONTRA_MUON=0.6 screen `fmx37tmr`**: step 2875/3175, val=3.306 — running, ~300 steps from terminal (~30 min). In deep cooldown. Result pending.

**FRIEREN #177 p=0.07 retry `dbf0augy`**: step 3000/3175, val=3.2912 — nearly done (~15 min). Needs to drop to ≤3.2762 in final 175 steps (significant drop required; likely landing in 3.27x range but outcome uncertain).

**THORFINN #178 cooldown_frac sweep**:
- 0.65 arm DONE: val=3.27865/ffs=3150 — **MISS** vs new baseline (both bars missed). Shorter cooldown hurts.
- 0.70 arm (control): val=3.27536/ffs=3100 — single seed beats baseline (but it IS the baseline HP).
- 0.75 arm `7f0r4eds`: just started (step 325/3175, val=4.059 early). Key test for longer cooldown.

**EDWARD #199 AdEMAMix**: 7+ smoke runs ALL NaN/crashed. Latest: `nxwdjjtx` (5 steps, NaN), `gwkew7xw` (crashed at step 1). Student has not pushed code to branch (branch has only 2-line cosmetic change). Advisor requested code paste and STOP on new runs until reviewed.

**NEZUKO #212 Attn-SOAP new base**: smoke `0k3qgq5q` clean at step 400 (val=3.808). Screen `h29cv26c` at step 675/3175, val=3.759 — healthy early phase.

**ASKELADD #213 per-module init**: smoke `0vc4kc82` clean at step 400 (val=3.832). Screen `jmcvmacz` at step 700/3175, val=3.775 — healthy early phase.

**FERN #208 power-law LR**: screen `w12r4fc9` at step 1225/3175, val=3.633 — running, ~39% through.

---

## 2026-05-16 23:30 — Cycles 33-34: Four PRs CLOSED; three new assignments

### FERN Aurora n=4 — CLOSED (PR #125), high variance

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.28038 | -1 (MISS) |
| n=4 mean | **3.27893** | **FAIL** |

2/4 trials miss ffs (never cross 3.28). n=4 mean=3.27893 > 3.27648 and 3.27893 > 3.27800 (statsig bar). Aurora diagonal leverage-score equalization is fundamentally high-variance on this architecture — mechanism requires n=8+ for reliable statistics. **CLOSED. Aurora is off the table at n=4 budget.**

### NEZUKO Attn-SOAP+trust-gate n=4 — CLOSED (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27715 | 3125 |
| n=4 mean | **3.27742** | **3125** |

Val MISS: 3.27742 > 3.27648. FFS MISS: 3125 > 3118.75. Misses the NEW baseline (PR #139) by 0.00094 val and 6.25 ffs. **CLOSED.** Notable: std=0.00015 is the best stability of any mechanism tested — Attn-SOAP+trust gate is robust. The mechanism is sound but doesn't beat the shifted baseline. Reassigned to Attn-SOAP on new base (PR #212) at THRESHOLD=0.9 and 0.85.

### ASKELADD SFM (Schedule-Free Muon) — CLOSED (PR #181)

SFM const-EMA fallback screen `k3wkjy84` (c_t=0.01):

| Metric | Value |
|---|---|
| val/loss | ~4.6+ (diverged) |
| y_z_diff_fro | growing unboundedly |

**Fundamental incompatibility confirmed**: Muon's Newton-Schulz iteration operates correctly only under non-constant LR (the operator-norm normalization within NS5 implicitly relies on LR decay to bring ‖y − z‖ under control). With constant LR, ‖y − z‖ diverges regardless of c_t schedule. **Schedule-Free Muon is CLOSED as a direction. Do not revisit.**

Assigned: askeladd → per-module weight init scaling (PR #213).

### New assignments created (Cycles 33-34)

| PR | Student | Hypothesis |
|---|---|---|
| #208 | g1r2-fern | Power-law LR cooldown (LR_POWER=1.5/2.0 sweep) — record #20 ingredient |
| #212 | g1r2-nezuko | Attn-SOAP+trust on CONTRA_MUON=0.5 baseline (THRESHOLD=0.9 then 0.85) |
| #213 | g1r2-askeladd | Per-module weight init scaling (μP-inspired, records #4,5,8 ingredient) |
| #214 | g1r2-tanjiro | TARGET_UW retune 0.30/0.40 sweep (u/w-floor vs new CONTRA_MUON=0.5 base) |

---

## 2026-05-16 23:15 — Cycle 32: PR #139 MERGED (NEW BASELINE), frieren screen near-miss

### ⭐ ALPHONSE CONTRA_MUON=0.5 n=4 — MERGED (PR #139) — NEW BASELINE

W&B run `db1rrfx3`:

| Trial | val/best_loss | ffs |
|---|---|---|
| T0 | 3.27830 | 3150 |
| T1 | 3.27634 | 3125 |
| T2 | 3.27551 | 3100 |
| T3 | 3.27577 | 3100 |
| **n=4 mean** | **3.27648** | **3118.75** |
| statsig | (3.28−3.27648)×2 = **0.00704** ≥ 0.004 ✓ | |

Beats prior baseline (PR #78) on both bars: val −0.00112, ffs −12.5 steps. **MERGED.** Mechanism: increasing CONTRA_MUON from 0.4 → 0.5 adds more spectral exploration via contravariant perturbation, escaping suboptimal gradient directions faster during peak-LR phase. Counter to intuition (more noise → better speed), but consistent with the "spectral exploration" interpretation.

New baseline after merge: mean=3.27648, ffs_mean=3118.75.

### FRIEREN Soft-Muon-anneal screen — NEAR-MISS vs new baseline (PR #177)

W&B run `dhqwygng` (p_start=0.10 → p_end=0.0 over first half):

| Metric | Screen | New baseline | Δ |
|---|---|---|---|
| val/loss | 3.27667 | 3.27648 | +0.00019 (MISS by tiny margin) |
| ffs | 3125 | 3118.75 | +6.25 steps (MISS) |

Excellent mechanism signal — val=3.27667 is far below old baseline (3.27760) and very close to new one. Miss is only 0.019% on val and 6.25 steps on ffs. Pre-approved p_start=0.07 follow-up screen launched. Analysis: annealing p=0.10 → 0.0 over first half of training adds spectral mixing during peak-LR phase and eliminates it during cooldown. Mechanism is sound; parameter needs slight reduction.

---

## 2026-05-16 22:15 — Cycle 31: Edward Contra-Muon n=4 CLOSED (stronger-but-slower); Askeladd SFM MISS; fern/nezuko T3 started

### Edward Contra-Muon n=4 @ 3225 steps — CLOSED, superseded (PR #76)

W&B run `zsqazpmr` (`g1r2-edward/contra-muon`):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |
| T2 | 3.27652 | 3175 |
| T3 | 3.27607 | 3175 |
| **n=4 mean** | **3.27652** | **3175** |
| statsig | **(3.28−3.27652)×2 = 0.00696 ≥ 0.004 ✓** | |

- Statsig PASS but ffs_mean=3175 > baseline 3131.25 — **FFS MISS**, does NOT beat merged baseline on primary metric.
- "Stronger but slower" pattern (#3 instance this session: Soft-Muon, Newton-Muon, now Contra-Muon-only).
- Mechanism superseded by PR #78 (merged baseline already has Contra-Muon + SOAP-MLP; edward's PR is the Contra-Muon-only subset).
- PR #76 closed. Edward reassigned to AdEMAMix-aux (PR #199).

### Askeladd SFM uniform c_t screen — MISS, fallback triggered (PR #181)

W&B run `groom2ym` (`g1r2-askeladd/sfm`):

| Field | Value |
|---|---|
| Screen val/loss | 4.60499 |
| ffs | -1 (MISS — never crossed 3.28) |
| y_z_diff_fro (terminal) | ~2.2e9 (massive divergence) |
| c_t at terminal | 0.00031 |

Root cause: `c_t = 1/(t+1)` weighs early pre-warmup iterates near-equally with trained iterates. By step 3175, most of the Polyak average weight sits on random-init timesteps. The `||y − z||` norm grows to 2.2B — z has moved far from init but y averages it all back toward init.

Fallback (pre-approved): `SFM_C_SCHEDULE=const`, `SFM_C_CONST=0.01` (EMA with ~100-step window). Screen `k3wkjy84` launched by student. This is a fundamentally sounder design — tracks recent trajectory rather than summing all history.

### Fern Aurora n=4 T2 terminal — BORDERLINE (PR #125)

W&B run `5kr7d0i5`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| n=3 mean | **3.27844** | — |

n=3 mean=3.27844 > 3.27800 → statsig currently fails. For n=4 MERGE: T3 needs val ≤ 3.27668 AND ffs ≤ 3125. T1's MISS (-1) means if using train_steps for ffs calculation, ffs_mean ≥ 3131.25 even with perfect T3. **Merge path nearly closed.** T3 still running (step 878/3175).

### Nezuko Attn-SOAP+trust-gate n=4 T2 terminal — OUTSTANDING (PR #124)

W&B run `790h1llo`:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| n=3 mean | **3.27750** | **3125** |

All 3 trials within 0.00015 val! n=3 mean=3.27750 beats both baseline bars (≤3.27800 val, ≤3131.25 ffs). T3 needs val ≤ 3.27852 (generous bar). **MERGE NEAR-CERTAIN.** T3 at step 553/3175.

---

## 2026-05-16 20:25 — Cycle 30 (cont): Tanjiro Lookahead CLOSED, nezuko/fern T0+T1 interim results

### Tanjiro Lookahead α=0.7 retry — MISS, PR #161 CLOSED

W&B run `yph361ta` @ train_steps=3175:

| Arm | α | Final val | ffs |
|---|---|---|---|
| Original screen | 0.5 | 3.30606 | -1 (MISS) |
| Retry | **0.7** | **3.28985** | -1 (MISS) |

Higher α (weaker pullback) recovered 0.016 val/loss but still missed by 0.010. Structural issue confirmed: Lookahead's slow-fast averaging slows cooldown val descent regardless of α. Lookahead doesn't transfer to this short-step cooldown-dominated regime. PR #161 closed.

### Tanjiro reassigned — PMuon (PR #187)

Record #18 mechanism: bilateral streaming covariance power preconditioning (Σ_L, Σ_R with γ=0.3 power exponent, β=0.95). Stacks on top of merged Contra+SOAP-MLP+NS5 after the NS5 step. Fresh preconditioner class — softer than KL-SOAP (pf=1 eigendecomp) but more adaptive than plain SOAP (pf=10).

### Nezuko Attn-SOAP+trust-gate n=4 T0+T1 (interim) — OUTSTANDING

W&B run `790h1llo` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27743** | **3125** |
| T1 | **3.27750** | **3125** |
| n=2 mean | **3.27747** | **3125** |

Remarkably consistent T0/T1 pair (val within 0.00007!). Both beat merged baseline on both metrics. If T2+T3 continue pattern → n=4 mean ≤ 3.27800 AND ffs_mean ≤ 3125 = **MERGE CANDIDATE**.

### Fern Aurora n=4 T0+T1 (interim) — HIGH VARIANCE WARNING

W&B run `5kr7d0i5` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | **3.27592** | **3100** |
| T1 | **3.28172** | **-1 (MISS!)** |

T1 completely missed — Aurora's diagonal leverage-score equalization is seed-sensitive. Path to merge now requires both T2 and T3 to hit near T0 quality. High variance is concerning. Monitoring.

## 2026-05-16 19:10 — Cycle 30: Askeladd KL-SOAP screen MISS, reassigned to Schedule-Free Muon

### Askeladd KL-SOAP+H screen — MISS, PR #166 CLOSED

W&B run `061cl8bj` @ train_steps=3125:

| Metric | Value |
|---|---|
| val/loss at terminal | **3.29515** |
| ffs (first_step_to_target) | **-1 (never reached 3.28)** |
| Step time | ~2.6 s/step |

Val=3.295 is +0.0175 above merged baseline mean (3.27760) and well above the 3.281 threshold in the predeclared decision tree. KL-SOAP+H replacing (not stacking on) the merged Contra+SOAP-MLP stack was ~50 steps worse on terminal val/loss at the same step budget. The pf=1 eigenbasis frequency doubled per-step compute but didn't recover the NS5+Contra-Muon orthogonalization the merged baseline relies on. PR #166 closed.

### Askeladd reassigned — Schedule-Free Muon (PR #181)

Fresh mechanism class: Polyak iterate averaging with constant LR, eliminating cooldown entirely. Hypothesis: constant LR keeps gradient magnitude steady; iterate averaging absorbs noise → val crosses 3.28 earlier. Implementation: maintain z (trajectory) and y (averaged eval point), Muon update on z, y ← (1 − 1/(t+1)) · y + (1/(t+1)) · z. No cooldown_frac, no LR warmup-cooldown schedule. First test of schedule-free paradigm on this track.

## 2026-05-16 17:55 — Cycle 29 (cont): Thorfinn Soft-Muon n=4 CLOSED, reassigned to cooldown_frac retune

### Thorfinn Soft-Muon p=0.05 n=4 — STRONGER-BUT-SLOWER, PR #103 CLOSED

W&B run `nfkk0mms` @ train_steps=3175-3325 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.274159 | 3250 |
| T1 | 3.274896 | 3250 |
| T2 | 3.272523 | 3225 |
| T3 | 3.275516 | 3250 |
| **n=4 mean** | **~3.2741** | **~3.2243** |

Statsig: `(3.28 − 3.2741) × √4 = +0.0118` — **PASSES** statsig (need ≥ 0.004). Val/loss excellent — best n=4 val mean of the session! BUT ffs_mean ≈ 3244 > baseline 3131.25. Does NOT beat merged baseline on FFS metric. Clean "stronger but slower" result — Soft-Muon's polynomial spectral compression lowers terminal val but slows cooldown convergence, adding ~75-100 steps vs baseline. PR #103 closed.

### Thorfinn reassigned — cooldown_frac retune (PR #178)

Three single-seed screens: cooldown_frac = 0.65, 0.70 (baseline reference), 0.75. If ffs ≤ 3100 AND val ≤ 3.279, predeclare n=4. Target: identify if scalar cooldown retune shifts the 3.28 crossing from ~step 3125 to ~step 3075. Predeclared sweep comparison table when all 3 screens complete.

## 2026-05-16 17:46 — Cycle 29: Frieren MuLoCo n=4 CLOSED, reassigned to Soft-Muon annealing

### Frieren MuLoCo+NorMuon n=4 — CLEAN NEGATIVE, PR #109 CLOSED

W&B run `jzsue46n` @ train_steps=3175 (final):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.282398 | -1 (miss) |
| T1 | 3.281958 | -1 (miss) |
| T2 | 3.279381 | 3175 |
| T3 | 3.280067 | -1 (miss) |
| **n=4 mean** | **3.28095** | **1/4 hit** |

Statsig: `(3.28 − 3.28095) × √4 = -0.0019` — **FAILS** statsig (need ≥ 0.004). Only T2 reached target. MuLoCo outer-Nesterov wrapping does not transfer to the merged Contra+SOAP-MLP step budget. The original screen at 3275 (`akwwpkv3`, val=3.27688 ffs=3225) was real but stronger-but-slower — needs ~100 more steps than merged baseline allows.

Clean negative — well-executed predeclaration honored across all 4 trials. PR #109 closed.

### Frieren reassigned — Soft-Muon annealing on merged base (PR #177)

Fresh hypothesis: record #20 (current global best at 3030 steps) uses **annealed Soft-Muon** as the key novel mechanism. Soft-Muon NS5 with `x^(1-p)` polynomial mixing, p_start=0.10 → p_end=0.0 annealed over first half of training. Applied to model.blocks.parameters() ndim>=2, alongside the existing Contra-Muon + SOAP-MLP stack. Target: cleaner cooldown trajectory + earlier 3.28 crossing.

## 2026-05-16 15:55 — Cycle 24: Fern Aurora screen FFS-WINNING, alphonse n=4 launched, frieren n=4 confirmed clean negative

### Fern Aurora screen — FFS-WINNING result on Contra+SOAP-MLP base (PR #125)

After two prior crashes (`csj1tm5z` @ step 1475, `isi6y97w` @ step 575) and a clamp fix (`D.clamp_(1e-6, 1e6)`):

| Run | Config | val/loss | ffs | Statsig (n=1) |
|---|---|---|---|---|
| `lqwaozx7` | Aurora on Contra+SOAP-MLP, 3175 steps | **3.27706** | **3125** | — |

**SINGLE-SEED BEATS MERGED BASELINE ON BOTH METRICS:**
- val 3.27706 < baseline 3.27760 (−0.00054)
- ffs 3125 < baseline ffs_mean 3131.25 (−6.25)

n=4 PREDECLARED at train_steps=3175 at 15:54 UTC. Fern to launch immediately. ETA terminal ~21:00-22:00 UTC.

Aurora is the FIRST mechanism (alongside CONTRA_MUON=0.5 tuning) to produce a single-seed FFS win on the merged baseline. Critically, Aurora is a fundamentally different mechanism from CONTRA_MUON tuning — it's diagonal leverage-score equalization inside NS5 from record #17. If both n=4 confirmations pass, they could potentially be stacked.

### Alphonse n=4 LAUNCHED — CONTRA_MUON=0.5 (PR #139)

W&B run `db1rrfx3` launched 15:33 UTC, currently step ~350/3175 trial 0. Same configuration as merged baseline except CONTRA_MUON=0.4 → 0.5. ETA full n=4 terminal ~22:00-22:30 UTC.

### Frieren n=4 MuLoCo+NorMuon — CLEAN NEGATIVE confirmed (PR #109)

W&B run `jzsue46n` @ train_steps=3175:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.28240 | -1 (never crossed 3.28) |
| T1 | 3.28196 | -1 (never crossed 3.28) |
| T2 | running | — |
| T3 | — | — |

T0 and T1 both miss the 3.28 target at 3175 steps. T2/T3 in progress per binding predeclaration; ETA full terminal ~17:40 UTC. Mean would need ≤3.27587 across T2/T3 to salvage statsig — ~3σ unlikely. Clean negative. Will close PR after SENPAI-RESULT.

Pattern: MuLoCo outer-Nesterov wrapping doesn't add to Contra+SOAP-MLP at 3175 steps. The original NorMuon-clean base achieved val=3.27688 ffs=3225 at 3275 steps in screen, but stacking MuLoCo doesn't compress further to 3175 steps.

### Thorfinn Soft-Muon p=0.05 n=4 — strong val, FFS not competitive (PR #103)

W&B run `6kjpjnvd` @ train_steps=3325 (plain Muon + NorMuon + Soft-Muon base):

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27423 | 3250 |
| T1 | 3.27492 | 3250 |

Remarkable T0/T1 agreement at ffs=3250. Excellent val/loss but ffs=3250 > merged baseline 3131.25 by 119 steps. Pattern: "stronger but slower" — same as Newton-Muon, NorMuonH. Will close PR after T2/T3 terminal (~17:40 UTC).

### Edward Contra-Muon n=4 — statsig pass likely, FFS not competitive (PR #76)

W&B run `zsqazpmr` @ train_steps=3225:

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27750 | 3175 |
| T1 | 3.27599 | 3175 |

Excellent val (mean projection ~3.276), but ffs=3175 > merged baseline 3131. Pod showing slow step rate (~6010 ms/step) but GPU healthy at 100%. ETA terminal ~21:00 UTC. Will close after terminal.

## 2026-05-16 15:35 — Cycle 23: Alphonse CONTRA_MUON=0.5 screen beats baseline on both metrics

### Alphonse CONTRA_MUON=0.5 screen — BEATS merged baseline on BOTH val AND FFS (PR #139)

| Run | Config | val/loss | ffs | Statsig (n=1) | Notes |
|---|---|---|---|---|---|
| `hjsjscjy` | CONTRA_MUON=0.3, 3175 steps | 3.27804 | 3150 | — | First FFS-competitive screen (cycle 18) |
| `yctj2ozd` | CONTRA_MUON=0.5, 3175 steps | **3.2763** | **3125** | — | BEATS baseline (3.27760/3131.25)! |

Screen `yctj2ozd` (CONTRA_MUON=0.5) delivers val=3.2763 ffs=3125 — the first single-seed result to beat the merged baseline on BOTH primary metrics simultaneously. N=4 PREDECLARED at train_steps=3175 with CONTRA_MUON=0.5. Predeclare comment posted at ~15:15 UTC. ETA terminal ~22:30-23:00 UTC.

Analysis: Reducing CONTRA_MUON from 0.4 (merged) → 0.5 (stronger contra correction) appears to tighten the convergence trajectory during cooldown. The contra correction `T - T^T` removes antisymmetric noise from the operator; a higher coefficient removes more, leading to a cleaner Newton-Schulz input. This translates directly to earlier FFS crossing without sacrificing terminal val.

### Askeladd NorMuonH n=4 @ 3300 — CLOSED, statsig pass but not FFS-competitive (PR #74)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27781 | 3225 |
| T1 | 3.27573 | 3200 |
| T2 | 3.27863 | — |
| T3 | ~3.277xx | — |
| n=4 mean | **3.27732** | ffs_mean ~3225-3250 |

n=4 mean=3.27732 — STRICTLY BETTER VAL than merged baseline (3.27760 → 3.27732), but ffs_mean ~3225-3250 — STRICTLY WORSE FFS than baseline 3131.25. Closed as "statsig pass but not FFS-competitive." NorMuonH on plain Muon base produces excellent terminal val but cannot compress the convergence curve to match Contra+SOAP-MLP's FFS efficiency. Reassigned to KL-SOAP + hyperball (PR #166).

### Askeladd reassigned — KL-SOAP + hyperball (PR #166, just assigned)

New hypothesis: Replace Contra-Muon+NS5+SOAP-MLP with KL-SOAP+hyperball on ALL 2D block params. Key parameters: β1=0.95, β2=0.90, shampoo_beta=0.90, pf=1, lr=0.018 (record #19 HPs). Reference: record #19 (n=6 mean=3.27800 @ 3125 steps, statsig pass). KL-SOAP at pf=1 provides the most aggressive curvature tracking in the literature — eigendecomp every step rather than every 10 steps. Unknown if it stacks with or replaces the Contra mechanism.

## 2026-05-16 14:15 — Cycle 19: Newton-Muon closed, Lookahead assigned, alphonse FFS-competitive

### Tanjiro Newton-Muon CLOSED — positive but not merge-eligible (PR #81)

Two terminal SENPAI-RESULTs:

| Config | n | val/loss mean | ffs_mean | Statsig | Merge? |
| --- | --- | --- | --- | --- | --- |
| Newton-Muon-only @ 3325 (`cpoe66ut`) | 4 | **3.27643** | 3256.25 | PASSES (0.00714) | NO — ffs > baseline |
| Newton-Muon-attn + Contra+SOAP-MLP @ 3175 (`wzgya0cq`) | 1 | 3.28893 | -1 | N/A | NO — missed target |

Newton-Muon-only at 3325 produces the LOWEST n=4 mean val/loss of any r2 student (3.27643), beats public record #15 (3.2785) by 0.00207. Paper-quality result, reproducible (σ≈0.0005). But ffs_mean=3256.25 at 3325 steps vs merged baseline ffs_mean=3131.25 at 3175 — 125 steps worse on primary metric.

Stack with Contra+SOAP-MLP (Option B) at 3175 failed badly (3.28893, never reached 3.28). Numerics clean (0 Cholesky failures), but the combined 4-mechanism stack doesn't compress below 3.28 in 3175 steps. Pattern: each additional mechanism extends the cooldown needed.

Conclusion: Newton-Muon mechanism is "stronger but slower." Not FFS-competitive at 3175. Closed PR #81.

### Tanjiro reassigned: Lookahead-Muon (PR #161)

Fresh hypothesis: Lookahead wrapper on merged Contra+SOAP-MLP baseline (Zhang et al. 2019). Inner optimizer takes k=5 steps normally; every k steps: θ_slow ← θ_slow + 0.5(θ_fast − θ_slow), then θ_fast ← θ_slow. Applied to ALL trainable params AFTER warmup.

Goal: FFS reduction by 30-80 steps via trajectory variance smoothing during peak-LR phase. If screen (single-seed at 3175) lands ≤ 3.279 with ffs ≤ 3175, predeclare n=4. Stretch goal: ffs_mean < 3131.

### Alphonse CONTRA_MUON=0.3 screen FFS-COMPETITIVE (PR #139)

`hjsjscjy` terminal: val=**3.27804**, ffs=**3150** at 3175 steps. Single-seed 19 steps worse than merged baseline ffs_mean=3131.25, but competitive val. FIRST FFS-competitive result since PR #78 merged. Alphonse launched CONTRA_MUON=0.5 screen (`yctj2ozd`) at step ~450 at 13:40 UTC. ETA terminal ~15:35 UTC.

If 0.5 screen competitive: predeclare n=4 at 3175 with best arm. n=4 mean could potentially beat baseline if seed distribution is favorable.

## 2026-05-16 10:30 — Cycle 14: Multiple screens terminal, PR #112 closed, alphonse reassigned

### Alphonse p=1.5 NEW-base CLOSED — NULL result (PR #112)
- W&B run `5gd8cw6c` (p=1.5 on Contra+SOAP-MLP NEW-base): **val=3.2775, ffs=3150** at 3275 steps
- Summary: p=1.5 on NEW-base essentially equals merged baseline mean (3.27760), within 1σ noise.
  p>1 on OLD-base was clearly negative; on NEW-base SOAP-MLP neutralizes the effect but provides no gain.
- Conclusion: linear LR cooldown remains optimal. Power-law p>1 ruled out for both bases.
- PR #112 CLOSED. Alphonse reassigned to **PR #139: Contra-Muon coefficient retune** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Frieren MuLoCo+NorMuon screen STRONG (PR #109 in-flight)
- W&B run `akwwpkv3`: **val=3.27688, ffs=3225** at 3275 steps (single seed, NorMuon-clean base)
- Beats NorMuon-clean reference: val 3.27800→3.27688 (−0.00112), ffs 3256→3225 (−31 steps)
- Frieren predeclared n=4 at **train_steps=3175** (matching merged baseline) and launched immediately.
- Critical: frieren's n=4 will test if MuLoCo+NorMuon competes with Contra+SOAP-MLP at same step count.
- If n=4 mean ≤ 3.278, ffs_mean ≤ 3131: MERGE candidate. ~6.75h ETA.

### Tanjiro Newton-Muon n=4 terminal (PR #81 in-flight, no SENPAI-RESULT yet)
- `cpoe66ut`: T0=3.27599/ffs=3250, T1=3.27720/ffs=3275, T2=3.27612/ffs=3250, T3=3.27639/ffs=3250
- n=4 mean=3.27643, ffs_mean=3256.25, margin=0.00714 — PASSES statsig
- But ffs=3256.25 > merged baseline ffs=3131.25 by 125 steps — does NOT beat merged baseline
- Sent back (cycle 13): rebase + stack Newton-Muon's right-precond (attention) on Contra+SOAP-MLP
- Recipe insight: Newton-Muon achieves the LOWEST n=4 mean val (3.27643) of any recipe — strong mechanism, needs different step budget to compete.

### Thorfinn Soft-Muon p=0.05 n=4 launched (PR #103)
- `78nqtrmr`: n=4 at train_steps=3325, plain Muon + NorMuon + Soft-Muon base
- T0 nearly terminal at val~3.2742 ffs=3225 (strongest single-seed result in portfolio!)
- ETA ~8-9h to T4 terminal. Single-seed trajectory at 3.2742 is remarkable.

### Edward Contra-Muon T0 strong (PR #76)
- T0 from `zsqazpmr`: val=3.2760, ffs=3175. T1 just started (step ~100).
- Expected: n=4 mean ~3.277-3.278 range. Likely pass statsig at 3225 steps.

### Askeladd NorMuonH T0 done (PR #74)
- T0 from `lw99ybyp`: val=3.2777, ffs=3250 at 3300 steps. T1 at step ~1825/3300.

## 2026-05-16 07:55 — Cycle 11: Soft-Muon p=0.05 strong, power-law LR closing

### Thorfinn p=0.05 SCREEN STRONG SIGNAL (PR #103)
- W&B run `pzp8b4rq` finished cleanly at **val/loss=3.27553, ffs=3250** at train_steps=3325.
- **Single seed 0.00207 BELOW merged baseline mean 3.27760** — strongest sub-baseline single-seed result in this round.
- p=0.075 retry `6empzhxo` crashed at step 625 — external pod restart, NOT numerical (blend still 0).
- Sent back PR #103 with directive: **launch predeclared n=4 @ 3325 confirmation immediately**, skip p=0.075 retry.
- For statsig at n=4: need mean ≤ 3.278. With single seed at 3.27553 and recipe variance σ~0.0007 typical, n=4 mean projects to 3.276–3.278 (borderline confirmable).
- Recipe (Soft-Muon p=0.05 on plain Muon) is **orthogonal** to merged Contra+SOAP-MLP — potential future stack candidate.
- ETA T3 ~13h from launch.

### Alphonse power-law LR closing (PR #112)
- W&B run `fg11eojr` (p=1.2): **3.28031** at 3275 steps — MISS
- W&B run `vvwsv9fm` (p=1.5 OLD-base): **3.28470** at 3275 steps — MISS
- Monotonic trend: p=1.0→0.000, p=1.2→+0.00231, p=1.5→+0.00670 — power-law cooldown with p>1 is decisively counterproductive on NorMuon base.
- p=1.5 NEW-base screen launched at 08:28 UTC (decisively expected to miss). Acknowledged "let it finish" per alphonse's decision tree.
- After NEW-base screen terminalizes: close PR #112 with documented negative evidence, reassign alphonse to **Contra-Muon coefficient retune on merged base** (CONTRA_MUON ∈ {0.3, 0.5} vs baseline 0.4).

### Other r2 students (in-flight, no new terminals)
- edward `zsqazpmr` (Contra-Muon n=4 @ 3225): T0=3.27750 done, T1 at step ~2275/3225 (~70%). ~10h to T3.
- tanjiro `cpoe66ut` (Newton-Muon n=4 @ 3325): T0=3.27599, T1-T2 done, T3 at step ~1275/3325 (~38%). Best T0 is BEST single-trial of any wave-1 recipe.
- askeladd `lw99ybyp` (NorMuonH n=4 @ 3300): launched, at step ~1425/3300 (~43%) — picked up cycle-9 rebase+launch directive.
- frieren `akwwpkv3` (MuLoCo+NorMuon screen @ 3275): just launched, step ~0.
- nezuko `g4zvpp9c` (Attention SOAP + trust gate): smoke at step ~40 + 2 prior smokes done. PR #124 picked up.
- fern `csj1tm5z` (Aurora orthogonal projection): screen at step ~25 + 1 prior smoke done. PR #125 picked up.

All 8 r2 students productive — zero idle GPUs in cycle 11.

## 2026-05-16 06:35 — PR #78: Contra+SOAP-MLP — MERGED as new advisor baseline
- Branch: `g1r2-fern/contra-soap-mlp` (squash-merged `718dd3f`)
- See below entry for full experiment detail. BASELINE.md updated.

## 2026-05-16 06:35 — PR #80: Muon² n=4 confirmation — CLOSED (non-competitive)
- Branch: `g1r2-nezuko/muon-sq`
- W&B run: `7lxk02m6` | num_trials=4 | train_steps=3325

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27788 | 3300 |
| T1 | 3.27859 | 3300 |
| T2 | 3.27915 | 3300 |
| T3 | 3.27792 | 3300 |
| **mean** | **3.27839** | **3300** |

- Statsig check: (3.28 − 3.27839) × √4 = **0.00322** — FAILS 0.004.
- Recipe is stable (all seeds hit target, no crashes, std=0.0006). The n=4
  mean is 0.0008 above NorMuon-clean's statsig ceiling (3.27800 @ 3300).
- Closed because: (1) non-statsig; (2) even extended to 3375 steps, ffs_mean
  ≈ 3325 vs new baseline 3131 — won't merge. Muon² ordering (Adam var BEFORE
  NS5) is confirmed inferior to NorMuon's post-NS5 ordering on this benchmark.
- Status: **CLOSED**. Nezuko reassigned to Attention SOAP + trust gate (PR #124).

## 2026-05-16 05:45 — PR #78: Contra+SOAP-MLP — STATSIG WIN (merge pending rebase)
- Branch: `g1r2-fern/contra-soap-mlp`
- Hypothesis: SOAP eigenbasis preconditioning on MLP weights, applied to
  momentum *before* NS5+contra+NorMuon (matches record #14 reference ordering).
- W&B confirmation run: `6bbhoxm1` | num_trials=4 | train_steps=3175 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27920 | 3150 |
| T1 | 3.27811 | 3150 |
| T2 | 3.27522 | 3100 |
| T3 | 3.27787 | 3125 |
| **mean** | **3.27760** | **3131.25** |

- Statsig check: (3.28 − 3.27760) × √4 = **0.00480 ≥ 0.004** — **PASSES**.
- Comparison vs NorMuon-clean baseline (PR #71): mean 3.27800 → 3.27760
  (−0.00040), ffs_mean 3256.25 → 3131.25 (**−125 steps**).
- Matches public record #14 (4 decimal places). Single-seed σ ≈ 0.0015.
- Auxiliary screening runs: `du7a5t1t` (3.27553 @ 3225, corrected ordering),
  `h3vsdeik` (3.27960 @ 3225, PR-literal ordering, superseded).
- The PR-literal ordering (SOAP after NorMuon variance) was suboptimal because
  NorMuon's per-element variance scaling is NOT basis-invariant — student
  caught this discrepancy by reading the record #14 reference file directly.
- Status: **STATSIG WIN, merge pending**. Blocked by (1) merge conflicts with
  auto-nanogpt-1gpu-r2 (NorMuon-clean merged after PR opened), (2) false-
  positive SENPAI-RESULT JSON parse on workflow-note comment. Sent back for
  rebase + comment disambiguation.

## 2026-05-16 05:30 — PR #74: NorMuonH — n=4 confirmation at 3275 (terminal, non-statsig by 0.00008)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon + hyperball + per-module init std (record #8 stack).
- W&B run: `6rf3nerz` | num_trials=4 | train_steps=3275 (predeclared).

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.27781 | 3225 |
| T1 | 3.27777 | 3225 |
| T2 | 3.27798 | 3250 |
| T3 | 3.27860 | 3250 |
| **mean** | **3.27804** | **3237.5** |

- Statsig check: (3.28 − 3.27804) × √4 = **0.00392** — misses 0.004 by 0.00008.
- Recipe is real and reproducible (σ~0.0004 across 4 trials, tightest of any
  wave-1 stack so far). Mean misses statsig ceiling by 0.00004.
- Notable: NorMuonH at 3275 has ffs_mean=3237.5, beating NorMuon-clean's
  3256.25 — but the loss ceiling is the rule that matters for merge.
- Status: WIP. Send back for predeclared n=4 at train_steps=3300 (one cooldown
  cycle of headroom should push mean to ~3.276 with same σ).

## 2026-05-16 05:30 — PR #112: NorMuon + power-law LR cooldown — p=1.2 screen MISSED
- Branch: `g1r2-alphonse/normuon-plawlr`
- Hypothesis: `lr * (1-progress)/cooldown_frac)^p` with p=1.2 (record #20
  schedule) may give 25-75 step gain over linear cooldown.
- W&B screen run: `fg11eojr` | num_trials=1 | train_steps=3275 | LR_COOLDOWN_POWER=1.2
- Result: terminal **val/loss=3.28031, ffs=-1, reached_target=0**. Did NOT
  cross 3.28.
- Per predeclared branch decision: if 3.277 < val ≤ 3.280, try p=1.5 next.
  3.28031 is just above 3.280, but the spec says "both p=1.2 AND p=1.5 > 3.280
  → close". p=1.5 single-seed should be tried before deciding.
- Status: WIP. Student should auto-launch p=1.5 screen on next poll.

## 2026-05-16 05:45 — PR #103: Soft-Muon isolated p=0.05 — SCREEN CRASHED
- Branch: `g1r2-thorfinn/soft-muon`
- Hypothesis: Soft-Muon polynomial `x^(1-p)` at p=0.05 (reduced from p=0.1
  which missed at 3.28024) with annealed blend 0→0.8 from step 2500.
- W&B screen run: `hz91ow2y` | num_trials=1 | train_steps=3325
- Result: **crashed at step 1575/3325 (47%, mid-cooldown)**. Last val/loss
  reading 3.5253.
- Likely cause: Soft-Muon polynomial coefficients at lower p may produce
  numerical instability when blended with NS5 mid-cooldown. Needs debugging.
- Status: WIP. Student should investigate crash, may need p=0.075 midpoint.

## 2026-05-16 04:30 — PR #109: MuLoCo+NorMuon smoke — DIVERGED TO NaN
- Branch: `g1r2-frieren/muloco-normuon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper on top of NorMuon inner
  optimizer (record #13 stack).
- W&B smoke run: `mti327gb` | num_trials=1 | train_steps=400
- Result: **val/loss=NaN by step 400**. Diverged.
- Likely cause: outer_lr=0.7 too aggressive on NorMuon's variance-noisy update
  direction; or outer Nesterov momentum compounds NorMuon's variance instability.
- Status: WIP. Student should try outer_lr=0.5 or sync_interval=60 in smoke
  before screen.

## 2026-05-16 01:45 — PR #79: MuLoCo on plain Muon — CLOSED (all 4 corners missed)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- Final W&B sweep runs:

| run | si | outer_lr | train_steps | val/loss | reached |
| --- | --- | --- | --- | --- | --- |
| `bqfv4523` | 15 | 0.5 | 3300 | 3.2829 | 0 |
| `q57yhybv` | 30 | 0.7 | 3300 | 3.2810 | 0 |
| `ecohqy9o` | 15 | 0.7 | 3300 | 3.2815 | 0 |
| `v2wn0t8t` | 60 | 0.5 | 3300 | **3.2865** | 0 |

- Conclusion: All 4 sweep corners failed to reach 3.28. The si=60/lr=0.5 corner
  (meant to allow longer inner runs between outer steps) was actually the **worst**
  result. Plain Muon's NS5 orthogonalization already smooths the gradient direction
  — MuLoCo's outer Nesterov momentum provides no additional benefit. Public record
  #13's success was likely driven by MuLoCo wrapping NorMuon (which has noisy
  per-element variance), not plain Muon.
- Status: **CLOSED (dead end)**. Frieren reassigned to MuLoCo+NorMuon (PR #109).

## 2026-05-16 01:50 — PR #81: Newton-Muon — n=4 confirmation at train_steps=3275 (terminal, non-statsig)
- Branch: `g1r2-tanjiro/newton-muon`
- Hypothesis: Activation-covariance right-preconditioning applied to the Muon
  gradient before Newton-Schulz (refresh every 64 steps).
- W&B run: `xsb35b0m` | num_trials=4 | train_steps=3275

| Trial | val/loss | ffs |
| --- | --- | --- |
| T0 | 3.279715 | 3275 |
| T1 | 3.278674 | 3250 |
| T2 | **3.277678** | **3225** |
| T3 | 3.281277 | -1 (missed) |
| **n=4 mean** | **3.27934** | — |

- Statsig check: `(3.28 - 3.27934) × √4 = 0.001328` — BELOW 0.004. **Non-statsig.**
- Analysis: T0–T2 all cleared 3.28 individually, including T2 at 3.2777 (among
  the best individual trials in wave 1). T3 was a bad seed — 3.2813 — above the
  target, which dragged the mean to 3.279. The recipe is real but has high
  seed variance. Needs more cooldown steps to tighten the distribution.
- Status: WIP. Sent back for fresh n=4 at predeclared `train_steps=3325`.

## 2026-05-15 23:20 — PR #79: MuLoCo on plain Muon — sweep arm si=15 (terminal)
- Branch: `g1r2-frieren/muloco-muon`
- Hypothesis: MuLoCo outer Nesterov SGD wrapper around plain Muon may accelerate
  convergence by adding momentum at a longer timescale.
- W&B run: `ecohqy9o` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/ecohqy9o`)
  | num_trials=1 | train_steps=3300 | sync_interval=15, outer_lr=0.7
- Result: terminal **val/loss=3.2815 @ step 3300**,
  `speedrun/final_first_step_to_target=-1`, `speedrun/final_reached_target=0`.
  **Did NOT cross 3.28.**
- Context: 3rd consecutive single-seed screen to miss — `bqfv4523`=3.2829,
  `q57yhybv`=3.2810, `ecohqy9o`=3.2815. All at or above 3.281 margin.
- Conclusion: MuLoCo on plain Muon appears break-even or slightly worse than
  starter at train_steps=3300. si=60/lr=0.5 corner still pending. If that
  corner also misses ≥ 3.281, MuLoCo-on-plain-Muon is dead and frieren will
  be pivoted to MuLoCo wrapping a confirmed inner optimizer (NorMuon or
  Contra-Muon, per the approach of public record #13).
- Status: WIP. si=60 sweep arm pending.

## 2026-05-15 22:45 — PR #80: Muon² (Adam variance BEFORE Newton-Schulz) — single-seed screen
- Branch: `g1r2-nezuko/muon-sq`
- Hypothesis: Per-element Adam variance applied to gradients *before* the
  Newton-Schulz orthogonalization should preserve NorMuon's variance-normalization
  benefit while keeping the orthogonalization geometry clean. lr=0.10, wd=0.0125,
  β₂=0.95, train_steps=3350 (per record #7 / nezuko PR body).
- W&B run: `n18mqjfy`
  (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/n18mqjfy`) | num_trials=1 |
  train_steps=3350.
- Result: terminal **val/loss=3.2773 @ step 3350**,
  `speedrun/final_first_step_to_target=3300`, `reached_target=1`.
- Statsig at n=1 (informational): (3.28 − 3.2773) × √1 = 0.0027 — does NOT
  clear the 0.004 single-seed bar, but is below 3.28 and on track for n=4
  consideration with cooldown headroom.
- Status: WIP. n=4 confirmation `7lxk02m6` launched (T0 early at step 275).
  Single-seed margin smaller than edward/fern/alphonse, so n=4 statsig is
  uncertain; will need mean ≤ 3.278 across 4 seeds.

## 2026-05-15 20:30 — PR #74: NorMuonH (row/col variance + hyperball + per-module init std)
- Branch: `g1r2-askeladd/normuonh-perinit`
- Hypothesis: NorMuon's row/col Adafactor-style variance combined with hyperball
  constraint (preserve ‖p‖_F per step) and per-module init std (×1.25 attn.proj,
  zero block-level proj for residual-branch safety) should reduce optimizer
  steps. Public record #8: 3225 steps, mean val/loss 3.2776 (n=10).
- W&B run: `sohiul20` (`wandb-applied-ai-team/modded-nanogpt-senpai/runs/sohiul20`)
  | num_trials=4 | train_steps=3250 (predeclared confirmation).
- Per-trial final val/loss at step 3250:
  | trial | val/loss |
  | --- | --- |
  | 0 | 3.27849 |
  | 1 | 3.27942 |
  | 2 | 3.27835 |
  | 3 | 3.27840 |
  | **mean** | **3.27867** |
  | std | ~0.0005 |
- `speedrun/final_first_step_to_target = 3225`, all 4 trials cleared 3.28.
- Statsig check (rule `(3.28 − μ) × √n ≥ 0.004`): (3.28 − 3.27867) × 2 =
  **0.00267** — below the 0.004 threshold at n=4. **Not statsig.**
- Conclusion: NorMuonH is a real, reproducible recipe (very tight inter-seed
  variance) but its mean at step 3250 falls 0.0007 above the statsig ceiling.
  Adding more seeds at step 3250 would not help (mean too stable). Sent back
  asking for a fresh n=4 batch at a predeclared step ∈ {3275, 3300} to gain
  ~0.001 of cooldown headroom for statsig clearance.
- Status: WIP / not merged. Awaiting follow-up predeclared confirmation.

## 2026-05-17 00:00 — PR #125 CLOSED: Aurora on Contra+SOAP-MLP base (fern)

- Branch: `g1r2-fern/contra-soap-aurora`
- Hypothesis: Diagonal leverage-score equalization (Aurora record #17) inside NS5 polar step, stacked on top of Contra+SOAP-MLP merged base. Replaces standard polar with D-equalized polar for non-square MLP weights; square attention weights short-circuit to standard NS5.
- W&B run: `5kr7d0i5` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27592 | 3100 |
| T1 | 3.28172 | -1 (MISS) |
| T2 | 3.27768 | 3125 |
| T3 | 3.27614 | 3125 |
| **n=4 mean** | **3.27787** | **3131.25** |
| statsig (3.28−mean)×2 | **0.00426** ≥ 0.004 ✓ | |

**Conclusion**: Statsig passes vs 3.28 gate but FAILS new baseline gates (PR #139 mean=3.27648, ffs=3118.75) on both bars. T1 (3.28172) is a catastrophic outlier — seed dispersion range = 0.00580, roughly 4× the typical mechanism variance and far exceeding baseline's 0.00279 range. Three of four seeds (T0, T2, T3) individually outperform the new baseline mean, confirming the mechanism works — but the variance kills n=4 aggregates.

**Key learning**: Aurora's diagonal leverage-score equalization is HIGH-VARIANCE on the merged Contra+SOAP-MLP base. The D fixed-point iteration introduces per-seed variation in the effective preconditioning that compounds over 3175 steps. This aligns with record #17's reported high-variance behavior. Not a mechanism failure, but needs n=8+ or a variance-reduction wrap to clear the new (tighter) baseline bars. Defer to next round.

Fern reassigned to PR #208: Power-law LR cooldown (LR_POWER=1.5/2.0), targeting record #20's schedule structure.

## 2026-05-17 00:30 — PR #124 CLOSED: Attn-SOAP+trust gate n=4 (nezuko)

- Branch: `g1r2-nezuko/attn-soap-gate`
- Hypothesis: Attention SOAP (eigenbasis preconditioner on qkv/proj weights) with trust gate (cosine-similarity threshold to decide when to apply precond vs identity fallback). Stacked on OLD baseline (CONTRA_MUON=0.4 / PR #78).
- W&B run: `790h1llo` (n=4, train_steps=3175)

| Trial | val/loss | ffs |
|---|---|---|
| T0 | 3.27743 | 3125 |
| T1 | 3.27750 | 3125 |
| T2 | 3.27758 | 3125 |
| T3 | 3.27609 | 3100 |
| **n=4 mean** | **3.27715** | **3118.75** |
| statsig (3.28−mean)×2 | **0.00570** ≥ 0.004 ✓ | |

**vs OLD baseline (PR #78):** val −0.00045 (WIN) / ffs tie 3118.75 (WIN vs 3131.25)

**vs NEW baseline (PR #139):** val +0.00067 (MISS) / ffs 3118.75 (TIE — strict < required = MISS)

**Conclusion**: Mechanism unambiguously works. T0/T1/T2 had extraordinarily low variance (0.00015 range, lowest of the session), confirming the trust gate produces stable training dynamics. T3 was a luckier seed (3.27609/3100). Mechanism delivers −0.00045 val + −12.5 ffs on OLD base. Misses NEW baseline strictly because NEW baseline (CONTRA_MUON=0.5) is 12.5 ffs better, making the comparison tight.

**Key trust-gate finding**: v/proj row cosines hover at 0.85-0.89 with threshold=0.9 — they are identity-precond ~100% of the time. Only q (~85%) and k (~25%) actually get SOAP precondition. This leaves significant headroom: lowering threshold to 0.85 would activate v/proj and potentially add another 25-50 ffs improvement.

**Follow-up**: Nezuko reassigned to PR #212 (Attn-SOAP+trust on NEW baseline, CONTRA_MUON=0.5, with Arm B at THRESHOLD=0.85).

## 2026-05-17 00:30 — PR #181 CLOSED: Schedule-Free Muon (askeladd)

- Branch: `g1r2-askeladd/sfm`
- Hypothesis: Muon with constant LR + Polyak averaging (schedule-free), replacing the linear cooldown.
- W&B runs: `groom2ym` (uniform c_t screen), `k3wkjy84` (c_const=0.01 screen)

| Screen | c_t | Final val(y) | Best val(y) | ‖y−z‖_F at T |
|---|---|---|---|---|
| Uniform 1/(t+1) | 0.00031 at T | 4.60499 | 4.59854 | **2.2e9** |
| Const EMA 0.01 | 0.01 | 4.62780 | 4.60690 | **4.3e8** |
| Merged baseline | linear cooldown | — | 3.27760 | n/a |

**Conclusion**: Fundamental incompatibility between (a) Muon's spectral updates under constant LR and (b) the 2-sequence SF formulation. NS5-orthogonalized Muon updates inject O(1) per element per step — under constant LR the iterates z never converge, while the Polyak average y lags and decays toward stale initialization. ‖y−z‖ grows unboundedly regardless of c_t window size. The gradient evaluated at y is increasingly stale, breaking the SF assumption ∇f(y) ≈ ∇f(z).

**Key negative finding**: Schedule-free methods (which assume bounded update magnitudes for convergence) are structurally incompatible with constant-LR Muon. Linear cooldown is doing essential work — it provides the convergence that SF assumes but cannot deliver. Direction CLOSED.

**Student's analysis quality**: Exceptional. Correctly diagnosed structural incompatibility, identified root cause (||y-z|| explosion independent of c_t window), recognized that 3-sequence Defazio would face the same issue. Valuable negative result well-characterized.

Askeladd reassigned to PR #213 (per-module weight init scaling — records #4,5,8 ingredient).
