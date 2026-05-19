# SENPAI Research State — auto-nanogpt-1gpu-r4

- **Date:** 2026-05-19 04:45 UTC
- **Most recent research direction from human researcher team:** none on file
- **Primary metric:** `speedrun/final_first_step_to_target` (lower is better)
- **Statistical merge rule:** `(3.28 − μ) × √n ≥ 0.004` AND n mean ≤ current baseline
- **Public leaderboard best:** 3030 steps (record #20 — Contra-Soft-Muon + KL-SOAP + trust gate)

## Current merged baseline — post-#290

**val=3.27200 / fs=3233.33 (n=3 mean)**

Merged recipe:
```
NANOGPT_GRAD_CLIP=10.0
NANOGPT_NS_ITERS=12
NANOGPT_NS_ITERS_COOLDOWN=16
NANOGPT_NS_COOLDOWN_START_FRAC=0.7
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor
NANOGPT_ADAMW_BETA2=0.99
NANOGPT_NS_COOLDOWN_SHAPE=late_peak
NANOGPT_NS_COEF_SCHEDULE=linear_ramp_down
```

### Merged stack history

| PR | Change | val (n) | fs (n) | Cumulative baseline |
|----|--------|---------|--------|---------------------|
| #60 | Muon² | 3.2766 (2) | 3275 | 3.2766 |
| #105 | clip=5.0 | 3.27527 (3) | 3266.7 | 3.27527 |
| #165 | clip=10.0 | 3.27474 (3) | 3258.3 | 3.27474 |
| #176 | NS=12→16@70% | 3.27461 (3) | 3266.7 | 3.27461 |
| #235 | embed linear_floor=15% | 3.27434 (3) | 3266.7 | 3.27434 |
| #236 | AdamW β2=0.99 | 3.27407 (3) | 3258.3 | 3.27407 |
| #285 | NS cooldown SHAPE=late_peak | 3.27352 (2) | 3250 | 3.27352 |
| **#290** | **NS coef schedule=linear_ramp_down** | **3.27200 (3)** | **3233.33** | **3.27200** ← CURRENT |

### Mechanism landscape (8 merges, largely orthogonal axes)

1. **Muon² v-EMA** (#60): second-moment before NS orthogonalization
2. **Grad clip** (#165): embed effective-LR raise (8.4% → 16.9%)
3. **NS timing** (#176): more NS iters during precision-critical cooldown
4. **Embed LR floor** (#235): hold embed at 15% of peak through final 30% of training
5. **AdamW β2** (#236): longer second-moment memory (20 → 100 step) smooths step sizes
6. **NS cooldown SHAPE** (#285): NS=12→20 transition at midpoint of cooldown (late_peak)
7. **NS coef schedule** (#290): linear ramp-down of NS polynomial coefficients over training

---

## Active experiments — 15:00 UTC

### ✅ frieren #344 — NS late_peak transition point sweep — CLOSED 20:00 UTC productive-null
Pod-1 Δ=−0.00419 collapsed to n=3 pooled Δ=−0.000877 (79% shrinkage). Sign flipped on pod 2 (+0.00278). Per-arm seed spread (0.00401) larger than claimed signal. Midpoint (frac=0.50) confirmed optimal on post-#290 stack; NS late_peak transition POINT axis CLOSED.
**Follow-up**: frieren assigned #402 Gradient Centralization scope sweep.

### ✅ frieren #402 — Gradient Centralization (GC) scope sweep — CLOSED 04:40 UTC productive-null (absorbed by existing stack)
All 4 arms within null band (max |Δ|=0.00111). Faint monotone B(all) > C(adam) > D(muon) ≈ A ordering — GC subtracts useful signal from AdamW aux gradients. NS orthogonalization on Muon side already approximately mean-centers block weight gradients. Post-#290 stack saturated on gradient-preprocessing axes: grad clip, per-group LR, NS spec tightening, β2=0.99 all jointly absorb any remaining mean-subtraction gain.
**Follow-up**: frieren assigned #436 EMA of weights (Polyak averaging).

### 🔄 frieren #436 — EMA of weights (Polyak averaging) [assigned 04:43 UTC]
**Branch:** `g1r4-frieren/weight-ema`
**Hypothesis**: Maintain parallel θ_ema = β·θ_ema + (1−β)·θ accumulator; use θ_ema for val_loss evaluation (not for training). Orthogonal to all closed gradient/moment-space mechanisms (AdEMAMix closed #399 — that was gradient EMA; this is weight EMA). Operating in weight-trajectory space, not gradient space. Sweep decay ∈ {off, 0.999, 0.9999, 0.99}.
| Arm | decay | Half-life | Interpretation |
|---|---|---|---|
| A | 0.0 (off) | — | Control / drift gate |
| B | 0.999 | ~700 steps | Moderate — averages last ~30% of training |
| C | 0.9999 | ~7000 steps | Long — near-full-training average |
| D | 0.99 | ~70 steps | Short — last ~3% of training |

**ETA full chain:** ~7.5h.

### ✅ alphonse #351 — Per-group SCALAR AdamW ε sweep — CLOSED 23:15 UTC productive-null (paired-pod confirmation collapsed signal)
Paired-pod re-run of A vs D produced mean Δ=+0.00019 (signal collapsed). Original "D wins by −0.00278" was arm-A unlucky-seed pod luck (val=3.27528 drifted +0.00328 above baseline). Second consecutive paired-confirmation null collapse (after frieren #344). Scalar ε axis fully closed across {1e-12, 1e-10, 1e-8, 1e-6}.
**Follow-up**: alphonse assigned #411 Gradient noise injection (Neelakantan 2015).

### 🔄 alphonse #411 — Gradient noise injection (Neelakantan 2015) [just assigned]
**Branch:** `g1r4-alphonse/gradient-noise-injection`
**Hypothesis**: Annealed Gaussian noise σ_t = σ_0 / (1+t)^γ added to gradients post-all_reduce, pre-clip (Neelakantan et al. 2015). Tests whether deterministic gradient signal is over-fitted to data ordering at this short-training scale. Fresh regularization axis orthogonal to all closed mechanisms.
| Arm | σ_0 | γ | Interpretation |
|---|---|---|---|
| A | 0.0 (control) | — | Drift gate |
| B | 0.001 | 0.55 | Light noise floor |
| C | 0.003 | 0.55 | Moderate noise |
| D | 0.01 | 0.55 | Aggressive (bounds axis) |

**Composition note**: same code path as #402 frieren (GC); if both yield signal can compose in future. Do NOT enable both in this run.
**ETA full chain:** ~7h.

### ✅ askeladd #354 — Logit softcap value sweep — CLOSED 16:35 UTC productive-null
Valley shape: all 3 off-center arms regress (+0.0037–0.0051). C≈D plateau above softcap=20 (softcap linear in that regime). softcap=15 confirmed optimal on post-#290 stack.
**Follow-up**: askeladd assigned #388 NS iter count cooldown sweep.

### ✅ askeladd #388 — NS_ITERS_COOLDOWN sweep — CLOSED 00:45 UTC productive-null (precision saturated)
All 4 arms terminal. A/B/D cluster within ±0.001 (val ∈ {3.27239, 3.27266, 3.27290}; all fs=3250). C single +0.00335 outlier. Drift gate ✓. Mechanism reading: **NS precision in cooldown SATURATED on post-#290 stack** — third productive-null on NS precision family (#345 depth, #384 center, #388 count). Combined with merged #285 shape and #290 schedule, NS cooldown family fully characterized.
**Follow-up**: askeladd assigned #419 Cautious AdamW updates (Liang et al. 2024).

### 🔄 askeladd #419 — Cautious AdamW updates (Liang et al. 2024) [just assigned]
**Branch:** `g1r4-askeladd/cautious-adamw`
**Hypothesis**: Mask AdamW update components where `sign(update) ≠ sign(g)`, then rescale (Liang et al. 2024). Operates inside AdamW step — orthogonal to all NS/Muon/clip/schedule/per-group LR work. One-line algorithmic change. Reported gains across language models and ImageNet.
| Arm | CAUTIOUS | RESCALE | SCOPE | Interpretation |
|---|---|---|---|---|
| A | 0 (off) | — | — | Control / drift gate |
| B | 1 | 1 | all | Paper default (rescaled mask) |
| C | 1 | 0 | all | Plain mask (no rescale) |
| D | 1 | 1 | embed | Embed-only (orthogonality probe) |

**ETA full chain:** ~7.5h.

### ✅ nezuko #356 — Muon μ schedule sweep — CLOSED 17:05 UTC productive-null
All 3 schedule arms missed 3.28 target entirely: B ramp_up +0.01381, C ramp_down +0.01035, D late_peak +0.06125 (catastrophic). Late_peak μ scheduling disastrous — cross-step gradient memory is different from within-step NS precision. Constant μ=0.95 confirmed optimal; Muon μ scheduling axis CLOSED.
**Follow-up**: nezuko assigned #393 per-group AdamW LR multiplier sweep.

### 🔥 nezuko #393 — Per-group AdamW LR multiplier sweep — SENT BACK 02:15 UTC for paired-pod confirmation
**Branch:** `g1r4-nezuko/pergroup-adamw-lr`
**All 4 arms terminal — full sweep verified on W&B**:
| Arm | LR mult | val | fs | Δ vs A | Δ vs baseline | W&B |
|---|---|---|---|---|---|---|
| A (control) | all 1.0× | 3.27242 | 3250 | — | +0.00042 (drift ✓) | `oggbt72v` |
| **B (embed1p5)** ⭐ | **embed=1.5×** | **3.27026** | **3225** | **−0.00216** | **−0.00174** | `cgyyzpwe` |
| C (lmhead1p5) | lm_head=1.5× | 3.27505 | 3275 | +0.00263 | +0.00305 | `kwt7wjzi` |
| D (scalar1p5) | scalar=1.5× | 3.27142 | TBD | −0.00100 | −0.00058 | `1bgjs64f` |

**ARM-B**: Single-seed stat-rule passes cleanly: (3.28 − 3.27026) × √1 = 0.00974 ≥ 0.004 ✓ AND 3.27026 ≤ 3.27200 ✓. **Sent back 02:15 UTC** for paired-pod confirmation per pre-staged protocol (2 recent null collapses on #344, #351 set precedent for confirming before merging single-seed wins).
**ARM-D**: Marginal Δ=−0.00058 vs baseline, n=1; defer follow-up pending B confirmation.
**Path**: Paired-pod request — 2 fresh pods × {A, B} with flipped order. After confirmation, pool n=3 per arm. Merge if mean(val_B, n=3) ≤ 3.27200 AND paired Δ_B ≤ −0.002 (or smaller-but-real with positive Δ_B); else productive-null.
**ETA paired conf:** ~7h.

### ✅ thorfinn #348 — Per-group AdamW WD sweep — CLOSED 15:15 UTC productive-null
All four arms terminal. Arms B/C/D all regress +0.0019–0.0025. Cross-group coupling observed (D shrinks embed_fro 5× more than B+C independently). AdamW WD axis closed on r4 (second verdict after #279 global WD).
**Follow-up**: thorfinn assigned #384 NS coef center sweep.

### ✅ thorfinn #384 — NS poly coef CENTER sweep — CLOSED 23:10 UTC productive-null (non-monotone, axis flat)
All 4 arms terminal. Non-monotone result: arm D (0.60, more extreme) regressed less than arm C (0.55), indicating C was single-seed outlier. Axis flat across center ∈ [0.43, 0.60]; default 0.49 confirmed within noise. NS coef center family fully characterized; combined with #345 depth and #290 schedule sweep, NS coef polynomial fully mapped.
**Follow-up**: thorfinn assigned #409 Per-block LR decay (LLRD) for Muon.

### 🔄 thorfinn #409 — Per-block LR decay (LLRD) for Muon [just assigned]
**Branch:** `g1r4-thorfinn/muon-llrd`
**Hypothesis**: Sweep per-block Muon LR with depth-dependent decay: lr_i = 0.035 × decay^(i/11). Tests whether different transformer layers benefit from different learning rates. Fresh axis on the Muon group never tested.
| Arm | decay | Block 0 lr | Block 11 lr | Interpretation |
|---|---|---|---|---|
| A | 1.0 (control) | 0.035 | 0.035 | All blocks equal; drift gate |
| B | 0.85 | 0.035 | 0.0085 | Mild decay (lower layers higher LR) |
| C | 0.7 | 0.035 | 0.00135 | Moderate decay |
| D | 1.2 | 0.035 | 0.21 | Inverse (upper layers higher LR) |

**ETA full chain:** ~7h.

### ✅ edward #374 — Embed init scale sweep — CLOSED 19:30 UTC productive-null
Clean flat result: all 4 arms within ±0.00027 of A (except B at −0.00061, still inside null band). RMSNorm + AdamW β2=0.99 + grad clip absorb embed magnitude — final norms converge to ~77k within 1.8% regardless of 4× init range. Embed init scale axis CLOSED.
**Follow-up**: edward assigned #399 AdEMAMix on AdamW groups.

### ✅ edward #399 — AdEMAMix on AdamW groups — CLOSED 04:24 UTC productive-null (slow-EMA redundant with β2=0.99)
All 4 arms terminal. Within-pod B-vs-A Δ=−0.00303 consumed by arm-A drift (+0.00276 from baseline). Vs baseline-mean: arm-B at −0.00027 (productive-null band). Monotone B<C<A<D ordering: α=0 sits between α=2 and α=5, and α=5 (paper default) is worse than control. Mechanism: AdEMAMix slow first-moment EMA redundant with β2=0.99's long second-moment memory on post-#290 stack. AdEMAMix axis CLOSED.
**Follow-up**: edward assigned #434 Lookahead optimizer scope sweep (Zhang 2019).

### 🔄 edward #434 — Lookahead optimizer scope sweep (Zhang 2019) [assigned 04:25 UTC]
**Branch:** `g1r4-edward/lookahead`
**Hypothesis**: Wrap AdamW and/or Muon with Lookahead (Zhang et al. NeurIPS 2019). Maintains slow weights θ_s; after every k=5 inner steps, blend: θ_s = θ_s + α(θ_f − θ_s), reset θ_f = θ_s. Operates in **parameter space** (not gradient/moment space) — orthogonal to AdEMAMix closure. Paper recipe k=5, α=0.5.
| Arm | SCOPE | k | α | Interpretation |
|---|---|---|---|---|
| A | off | — | — | Control / drift gate |
| B | adamw | 5 | 0.5 | Lookahead on AdamW only |
| C | muon | 5 | 0.5 | Lookahead on Muon only |
| D | both | 5 | 0.5 | Lookahead on both (paper default) |

**ETA full chain:** ~7.5h.

### ✅ fern #380 — lm_head proj init std sweep — CLOSED 22:40 UTC productive-null
All 4 arms terminal. Monotone worsening with σ: A=3.27409 (zero, drift gate ✓), B=3.27470 (σ=0.005, +0.00061), C=3.27725 (σ=0.02, +0.00316), D=3.28234 (σ=0.05, +0.00825, fs=-1 failed target). **Zero-init confirmed uniquely optimal** — both init-scale axes (embed #374, lm_head #380) now exhaustively mapped.
**Follow-up**: fern assigned #408 Adaptive Gradient Clipping (AGC).

### 🔄 fern #408 — Adaptive Gradient Clipping (AGC) [just assigned]
**Branch:** `g1r4-fern/adaptive-grad-clip`
**Hypothesis**: Replace fixed clip=10.0 with per-parameter AGC (Brock et al. 2021, NFNets) — clip threshold = λ × ||W||_F. Scales with parameter magnitude. Sweep λ ∈ {0 control, 0.01, 0.03, 0.1}.
| Arm | AGC_LAMBDA | Interpretation |
|---|---|---|
| A | 0 (control) | Falls through to fixed clip=10.0, drift gate |
| B | 0.01 | Conservative AGC (tight clip) |
| C | 0.03 | Paper default (moderate AGC) |
| D | 0.1 | Loose AGC (rarely clips) |

**ETA full chain:** ~7h.

### ✅ tanjiro #377 — Pruning ablation — CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE)
All 4 arms terminal. **Key mechanism findings**: (1) **β2=0.99 is amplified — 5.9× original lift magnitude**; (2) late_peak #285 subsumed (Δ=−0.00043, sign-flipped vs original); (3) linear_ramp_down #290 fully subsumed (Δ=+0.00009, ~0% original lift). 2 of 3 recent merges appear redundant on current stack — consistent with "mechanism saturation within late-cooldown precision family" hypothesis.
**Follow-up**: tanjiro assigned #407 β2 fine-tune sensitivity sweep (mechanism-driven by β2 amplification finding).

### 🔄 tanjiro #407 — AdamW β2 sensitivity sweep [just assigned]
**Branch:** `g1r4-tanjiro/adamw-beta2-sensitivity`
**Hypothesis**: Pruning ablation revealed β2=0.99 is amplified 5.9× over original lift. Optimum may have drifted on post-#290 stack. Sweep β2 ∈ {0.98, 0.99, 0.995, 0.999} to test sensitivity.
| Arm | β2 | EMA window | Interpretation |
|---|---|---|---|
| A | 0.99 (control) | ~100 steps | Current baseline; drift gate |
| B | 0.98 | ~50 steps | Shorter; faster adaptation |
| C | 0.995 | ~200 steps | Longer; more smoothing |
| D | 0.999 | ~1000 steps | Very long; high-noise-floor smoothing |

**ETA full chain:** ~7h.

### ✅ fern #345 — NS coef ramp_down DEPTH sweep — CLOSED 14:10 UTC productive-null
**Follow-up**: fern assigned #380 lmhead-init-scale.

### ✅ tanjiro #300 — Embed floor value sweep — CLOSED 12:50 UTC productive-null
**Follow-up:** tanjiro assigned #377 pruning ablation.

---

## Recently closed

- **askeladd #388 (NS_ITERS_COOLDOWN sweep)** — CLOSED 00:45 UTC productive-null. A/B/D cluster within ±0.001 (val ∈ {3.27239, 3.27266, 3.27290}, all fs=3250); C +0.00335 outlier. **NS precision saturated** on post-#290 stack. Third productive-null on NS precision family.
- **alphonse #351 (Per-group SCALAR AdamW ε)** — CLOSED 23:15 UTC productive-null. Paired-pod confirmation collapsed signal (Δ=+0.00019). Original arm-A drifted +0.00328; D's "−0.00278 lift" was pod luck. Second consecutive paired-pod null collapse (after #344).
- **thorfinn #384 (NS coef CENTER)** — CLOSED 23:10 UTC productive-null. Non-monotone (D regressed less than more-moderate C); axis flat across center ∈ [0.43, 0.60]. NS coef family (depth #345 + schedule #290 + center #384) fully characterized.
- **tanjiro #377 (Pruning ablation)** — CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE). β2=0.99 amplified 5.9× original lift (load-bearing); late_peak (#285) and linear_ramp_down (#290) appear subsumed on current stack.
- **fern #380 (lm_head init std)** — CLOSED 22:40 UTC productive-null. Monotone worsening with σ; zero-init uniquely optimal. Init-scale axis closed across both embed (#374) and lm_head (this PR).
- **nezuko #356 (Muon μ schedule)** — CLOSED 17:05 UTC productive-null. All 3 schedule arms miss target by 7–41× null band. Late_peak μ catastrophic (+0.06125). Constant μ=0.95 confirmed optimal; μ scheduling axis closed.
- **edward #335 (Muon LR cooldown floor)** — CLOSED 11:05 UTC productive-null. Monotonic worsening: A=3.27482 (+0), B=+0.001, C=+0.006, D=+0.017. Mechanism: embed-floor is embed-specific; Muon NS already controls update magnitude.
- **askeladd #324 (AdamW β1 sweep)** — CLOSED 08:35 UTC productive-null. β1=0.80 optimal, monotone-worse. Asymmetric with β2 finding.
- **nezuko #315 (lm_head steeper-decay cooldown)** — CLOSED 08:35 UTC productive-null. All steeper shapes regress +0.0031–0.0035. lm_head sweet spot is linear.
- **frieren #285 (NS cooldown SHAPE)** — MERGED ✅ 06:02 UTC. val=3.27352 (n=2). late_peak concentrates NS=20 into lowest-LR half of cooldown.
- **fern #290 (NS coef schedule)** — MERGED ✅ 06:07 UTC. val=3.27200 (n=3). linear_ramp_down starts NS at high-precision coefficients, ramps toward standard.
- **fern #345 (NS coef depth sweep)** — CLOSED 14:10 UTC productive-null. depth=0.42 confirmed optimal. Asymmetric plateau: steep side flat, shallow side regresses +0.00390.
- **tanjiro #300 (embed floor=0.20)** — CLOSED 12:50 UTC productive-null. floor=0.20 absorbed by late_peak + linear_ramp_down. embed-floor ⊆ late-cooldown-precision family. 9 seeds total.
- **thorfinn #279 (AdamW WD=0.005)** — CLOSED 07:12 UTC productive-null. β2=0.99 absorbed standalone gain.
- **alphonse #322 (AdamW global ε)** — CLOSED 07:48 UTC productive-null. β2=0.99 smoothing already stabilizes denominator.

---

## Potential next research directions

### Active candidates with signal
1. **Per-group AdamW LR (embed=1.5×)** — nezuko #393 arm-B. Val=3.27026, Δ vs A=−0.00216, Δ vs baseline=−0.00174, fs=3225 (−8.33). Full sweep done. **SENT BACK 02:15 UTC** for paired-pod confirmation (2 fresh pods × {A, B} with flipped order). Highest-priority confirmation in the current portfolio.
2. **Gradient Centralization scope** — frieren #402. Fresh mechanism (gradient preprocessing). Scope sweep: all, adam-only, muon-only. Orthogonal to all closed axes.

### Productive-null shaping up
3. **Logit softcap value** — askeladd #354. CLOSED 16:35 UTC. softcap=15 confirmed optimal (valley shape). Axis closed.
4. **Muon μ schedule** — nezuko #356. CLOSED 17:05 UTC productive-null. All 3 arms miss target (B +0.01381, C +0.01035, D +0.06125). Late_peak μ catastrophic. Constant μ=0.95 confirmed; axis CLOSED.
5. **Per-group AdamW WD** — thorfinn #348. CLOSED 15:15 UTC. All arms regress +0.0019–0.0025. AdamW WD axis closed on r4 (2nd consecutive verdict).
6. **Embed init scale** — edward #374. CLOSED 19:30 UTC productive-null. RMSNorm + AdamW absorb magnitude; embed init scale axis CLOSED.
7. **NS late_peak transition POINT** — frieren #344. CLOSED 20:00 UTC productive-null. Pod-1 Δ=−0.00419 shrank to pooled Δ=−0.000877 (79%), sign flip on pod 2. Midpoint confirmed optimal; axis CLOSED.
8. **Pruning ablation (#236, #285, #290)** — tanjiro #377. CLOSED 22:30 UTC productive-null (HIGH-VALUE MECHANISM PROBE). β2 amplified 5.9×; late_peak/linear_ramp_down appear subsumed.
9. **lm_head init std** — fern #380. CLOSED 22:40 UTC productive-null. Monotone worsening with σ; zero-init uniquely optimal.

### Fresh axes (early stage)
10. **AdEMAMix on AdamW** — edward #399. Fresh slow-EMA mechanism (NeurIPS 2024). Sweep alpha_max ∈ {2, 5, 8} vs control. Mechanism orthogonal to all per-group hyperparameter work.
11. **Gradient Centralization** — frieren #402. Gradient preprocessing layer (Yong et al. 2020). Scope sweep: all, adam, muon. Fresh mechanism abstraction layer.
12. **AdamW β2 sensitivity** — tanjiro #407. Mechanism-driven by #377 pruning finding (β2 amplified 5.9×). Test {0.98, 0.99, 0.995, 0.999} for optimum drift.
13. **Adaptive Gradient Clipping (AGC)** — fern #408. Per-parameter clip threshold based on ||W||_F (Brock et al. 2021, NFNets). Replaces fixed clip=10.0 with adaptive per-tensor threshold.
14. **Per-block LR decay (LLRD) for Muon** — thorfinn #409. Fresh per-block axis on Muon group never tested. Sweep decay ∈ {1.0 control, 0.85, 0.7, 1.2}.
15. **Gradient noise injection (Neelakantan 2015)** — alphonse #411. Annealed Gaussian noise σ_t = σ_0 / (1+t)^γ. Fresh regularization axis. Sweep σ_0 ∈ {0, 0.001, 0.003, 0.01} at γ=0.55.
16. **Cautious AdamW updates (Liang et al. 2024)** — askeladd #419. Mask sign-mismatched update components in AdamW step, rescale to preserve magnitude. Fresh modern mechanism. Sweep scope ∈ {off control, all-rescaled, all-plain, embed-only}.

### Medium-priority unassigned axes (for next idle)
1. **AdEMAMix on aux groups** — triple-EMA long-memory mechanism; compatible with β2=0.99
2. **NS cooldown 3-phase** — extend late_peak to 3-phase (12→15→20 within cooldown window)
3. **Output proj init scale** — pairs with edward #374; proj has no RMSNorm so direct logit influence
4. **Per-group μ ablation** — with μ scheduling closed (#356), per-group constant μ remains worth testing (distinct from scheduling)
5. **Scalar LR finer sweep** — if nezuko #393 arm-D wins, follow-up {1.25, 1.5, 2.0, 2.5}×

### What we know about stacking
- 7 merges across orthogonal axes; gap to 3030 steps ~200 steps in fs
- Closed naive hparam sweeps (β1, global WD, global ε, lm_head steeper decay)
- Fresh mechanism exploration (schedule axes, init, output layer) remains the priority
- **Both live signal candidates weakened on 2nd-seed data**: #344 frieren A-retry showed +0.00401 variance (≈ original signal magnitude); #351 alphonse arm-A drifted above gate making within-pod Δs harder to interpret.
- **Most current arms shaping toward productive-null** — likely cycle's outcome is mechanism-mapping rather than new merges.

---

## Closed mechanisms (do not re-explore)

| Category | Mechanism | Evidence |
|----------|-----------|----------|
| Temporal smoothing | Polyak EMA, Lookahead | #104, #120 |
| Element-wise direction shaping | Contra-Soft per-element | #126 |
| Magnitude-coupled trust region | ||w||_F coupled cap | #117 |
| LR warmup | 0/50/100 step warmup | #102 |
| Cooldown frac (timing only) | {0.4, 0.5, 0.6} | #106 |
| Cooldown LR shape (global) | cosine, sqrt, quadratic, exp | #204 |
| Lion optimizer (aux) | Lion embed+lm_head | #77 |
| Per-layer NS adaptive | sigmoid-controlled NS iters | #145 |
| Momentum reset (DMR) | periodic v reset with decay | #163 |
| SOAP/Adafactor on aux | Shampoo rotation / factored v | #144, #180 |
| Adam-style BC in Muon² | BC + beta2=0.98 (bundled) | #115 |
| NS=8 floor test | constant NS=8 | #75 |
| NS high-early anneal | NS=14→8 | #185 |
| Uniform aux LR scaling | 0.5× / 1.5× embed/lm_head/scalar | #188 |
| Muon² eps floor | sweep 1e-9 to 1e-6 | #189 |
| Per-group Muon clip | per-group clip dispatch at clip=10 | #206 |
| AdamW β1 cooldown schedule | β1 linear decay schedule | #227 (null) |
| lm_head + scalar cooldown floor | floor=15% on non-embed aux | #266 (HURTS) |
| Muon mu=0.97 (constant) | within-pod Δ=−0.00289 but cross-pod fail | #241 (productive-null) |
| Muon LR cooldown floor | embed-floor mechanism on Muon | #335 (monotonic worsening) |
| AdamW β1 (constant) sweep | β1 ∈ {0.8, 0.85, 0.9, 0.95} | #324 (monotone) |
| lm_head steeper-decay shape | floor/steep alternatives | #315 (all worse) |
| NS cooldown SHAPE (frieren) | late_peak wins — MERGED #285 | — |
| NS coef schedule (fern) | linear_ramp_down wins — MERGED #290 | — |
| NS coef depth (fern) | depth=0.42 confirmed apex, asymmetric plateau | #345 (productive-null) |
| Logit softcap value | softcap=15 confirmed optimal, valley shape | #354 (productive-null) |
| AdamW WD (global) | global WD=0.005 absorbed by β2=0.99 | #279 (null) |
| AdamW WD (per-group) | per-group WD=0.002 on lm_head, scalar, or both — all harmful | #348 (harmful) |
| Muon μ schedule | ramp_up/ramp_down/late_peak — all miss target; late_peak +0.06125 catastrophic | #356 (harmful) |
| Embed init scale | scale ∈ {0.5, 1.0, 1.5, 2.0}; all within ±0.00061 null band; RMSNorm/AdamW absorb magnitude | #374 (productive-null) |
| NS late_peak transition POINT | frac ∈ {0.25, 0.50, 0.75}; pod-1 Δ=−0.00419 collapsed 79% to pooled Δ=−0.000877; sign flip pod 2; midpoint confirmed optimal | #344 (productive-null) |
| lm_head init std | σ ∈ {0.0, 0.005, 0.02, 0.05}; monotone worsening; zero-init uniquely optimal; σ=0.05 fails target | #380 (productive-null) |
| Pruning ablation (#236, #285, #290) | β2=0.99 load-bearing & 5.9× amplified; #285 late_peak appears subsumed; #290 linear_ramp_down fully subsumed; mechanism probe only | #377 (productive-null) |
| Per-group scalar AdamW ε | scalar_eps ∈ {1e-12, 1e-10, 1e-8, 1e-6}; paired-pod confirm Δ=+0.00019; A drifted +0.00328 making original sweep unreliable | #351 (productive-null) |
| NS coef polynomial CENTER | center ∈ {0.43, 0.49, 0.55, 0.60} at depth=0.42; non-monotone (D < C while D more extreme); axis flat | #384 (productive-null) |
| NS_ITERS_COOLDOWN count | count ∈ {14, 16, 18, 20}; A/B/D cluster within ±0.001, C +0.00335 outlier (single-seed noise); precision saturated on post-#290 stack | #388 (productive-null) |
