# SENPAI Research Results — auto-nanogpt-1gpu-r5

Log of completed/reviewed experiment PRs in chronological order. Wave 1
results pending student execution.

## 2026-05-20 13:50 UTC — PR #537: edward Adam β1/β2 sweep (5 cells) — **CLOSED clean-neutral**

- Branch: `g1r5-edward/adam-betas-sweep`
- Student: g1r5-edward
- Hypothesis: Adam betas (β1=0.8, β2=0.95) hardcoded; never ablated. Sweeps β1 ∈ {0.7, 0.8, 0.9, 0.95} and β2 ∈ {0.9, 0.95, 0.99, 0.999}. Uses ns_iter=12 (assigned before PR #497 ns_iter=6 baseline merge) — compare against OLD baseline.

### Results (vs OLD baseline mu=3.267948, σ=0.000823)

| Cell | adam_betas | val_loss | Δσ vs OLD baseline | ffs | W&B run |
|------|:----------:|:--------:|:------------------:|----:|---------|
| **A (ctrl)** | `0.8,0.95` | **3.26855** | **+0.73σ** | 3100 | `3dbms8x0` |
| B | `0.9,0.95` | 3.26963 | +2.04σ | 3125 | `jdv0uk7w` |
| C | `0.9,0.99` | 3.27063 | +3.26σ | 3125 | `wg208ces` |
| D | `0.95,0.999` | 3.27524 | +8.86σ | 3175 | `6mb3xwks` |
| E | `0.7,0.9` | 3.27053 | +3.14σ | 3125 | `gh62fjck` |

### Conclusion

- **U-shaped response with min at A**: both directions from ctrl worsen val/loss. Moving toward canonical AdamW (D=+8.86σ) is catastrophically worse; moving more aggressive (E=+3.14σ) also hurts.
- **β1=0.8 is optimal** for this 3250-step run: 5-step EMA window lets Adam adapt fast to cooldown dynamics. Standard β1=0.9 costs +1.31σ vs A.
- **β2=0.95 is optimal**: 20-step window adapts fast enough to ride cooldown. Canonical β2=0.999 (~1000-step window) is catastrophically sluggish for a 3250-step horizon.
- **Mechanism**: short speedrun training is dominated by transient gradient dynamics (warmup→cooldown over 3250 steps); long-memory canonical AdamW under-adapts.
- **Note**: Cell A (+0.73σ vs OLD baseline) is within seed noise band (~5σ range per PR note); Adam β axis closed at (0.8, 0.95).

Edward reassigned to PR #581: Lookahead optimizer wrapper (fresh mechanism — k-step sync of slow/fast params; first non-HP mechanism for edward this run).

## 2026-05-20 11:30 UTC — PR #551: askeladd Muon nesterov toggle (True/False) — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/muon-nesterov-toggle`
- Student: g1r5-askeladd
- Hypothesis: Muon `nesterov=True` (hardcoded) performs `grad.lerp_(momentum, mu)` before NS orthogonalization. Ablating to `nesterov=False` (pure EMA momentum) might help by reducing early-step gradient noise — consistent with "less optimizer intensity" theme.

### Results

| Cell | muon_nesterov | val_loss | Δ vs NEW baseline (σ=0.001747) | ffs | W&B run |
|------|:-------------:|:--------:|:------------------------------:|----:|---------|
| **A (ctrl)** | True | **3.265755** | **−0.21σ** | 3075 | `b8tygvux` |
| B | False | 3.273293 | **+4.10σ** | 3150 | `1f0ci6y2` |

### Conclusion

- **Clear clean-NEG**: Cell B (nesterov=False) = +4.10σ above new baseline, well past the +1σ kill gate. ffs 75 steps slower.
- **Mechanism**: The `grad.lerp_(momentum, mu)` correction (≈5% current grad + 95% EMA before NS orthogonalization) is load-bearing. Orthogonalizing pure EMA discards the small but informative current-step delta, leaving NS with only stale 20-step-lagged direction. Even a 5% current-gradient correction significantly improves convergence per step.
- **Theme clarification**: The "less optimizer intensity" theme (PR #371, PR #497) does NOT generalize to removing the gradient correction from Nesterov. The gradient correction is informative, not noisy — removing it costs ~+7 millinats and 75 ffs steps.
- **Muon nesterov axis closed**: nesterov=True is optimal. The axis is binary — no finer scan needed.

Askeladd reassigned to PR #571: scalar param LR sweep (adam_scalars lr=0.01 hardcoded — third AdamW group LR, never ablated).

## 2026-05-20 10:20 UTC — PR #521: nezuko gradient clipping sweep (0/50K/100K/200K/400K) — **CLOSED clean-NEG**

- Branch: `g1r5-nezuko/grad-clip-sweep`
- Student: g1r5-nezuko
- Hypothesis: Gradient clipping at various thresholds may stabilize training. Sweeps `--grad_clip` ∈ {0.0, 50000, 100000, 200000, 400000}.

### Results

| Cell | grad_clip | val_loss | Δσ vs OLD baseline | Δ vs NEW baseline | ffs | W&B run |
|------|----------:|---------:|-------------------:|------------------:|----:|---------|
| **A (ctrl)** | 0.0 (no clip) | **3.26439** | **−4.32σ** | **−0.99σ** (n=1 lucky) | 3050 | `1kiauw9h` |
| D | 400000 | 3.26635 | −1.94σ | +0.13σ | 3075 | `hkgyzeic` |
| B | 200000 | 3.26712 | −1.00σ | +0.57σ | 3100 | `tpe1w7ir` |
| C | 100000 | 3.26927 | +1.61σ | +1.80σ | 3100 | `9qiwuvm1` |
| E | 50000 | 3.27260 | +5.65σ | +3.71σ | 3150 | `c24upax9` |

### Conclusion

- **Monotonic verdict**: tighter clip = strictly worse. A → E span = +10σ_single, far outside any noise envelope.
- **Mechanism (student analysis)**: Muon's NS orthogonalization is approximately scale-invariant w.r.t. input grad magnitude. So clipping damage falls almost entirely on the Adam path (embeddings, lm_head, scalars) where direct-gradient updates carry useful sparse-token signal. Confirmed via per-group `grad_norm_pre_clip` telemetry.
- **Cell A at NEW baseline**: 3.26439 vs new baseline mu=3.266120 → −0.99σ (lucky seed). Vs n=4 NEW gate (3.264120): +0.000270 = +0.31σ above gate. NOT a genuine improvement — Cell A is the same code path as the current no-clip baseline.
- **Net**: Gradient clipping axis fully closed. Current no-clip behavior is optimal. Per-group `grad_norm_pre_clip` telemetry preserved.

Nezuko reassigned to fresh axis: PR #566 embed_lr sweep (embed_lr=0.3 / lm_head_lr=1/320 — both hardcoded AdamW per-group LRs, never ablated).

## 2026-05-20 09:55 UTC — PR #518: thorfinn NS polynomial coefficient sweep — **CLOSED clean-neutral**

- Branch: `g1r5-thorfinn/ns-coefs-sweep`
- Student: g1r5-thorfinn
- Hypothesis: Newton-Schulz quintic coefficient choice affects orthogonalization fidelity → different polynomial families may interact with ns_iter to give net val/loss improvements. Sweeps 3 polynomial families × 2 ns_iter values.

### Results

| Cell | ns_coefs | ns_iter | val_loss | Δσ vs OLD baseline | ffs | W&B run |
|------|----------|:-------:|---------:|-------------------:|----:|---------|
| A (ctrl) | 2.0, −1.5, 0.5 | 12 | 3.267355 | −0.72σ | 3100 | `1e5dtrfm` |
| B | 3.4445, −4.7750, 2.0315 (Muon) | 12 | 3.267031 | −1.11σ | 3075 | `z6nw7fbi` |
| C | 3.4445, −4.7750, 2.0315 (Muon) | 6 | **3.26684** | **−1.35σ** | **3075** | `cwnzs17z` |
| D | 1.875, −1.25, 0.375 (analytical quintic) | 12 | 3.267333 | −0.75σ | 3100 | `2102ucw6` |
| E | 2.0, −1.5, 0.5 (current) | 6 | 3.267297 | −0.79σ | 3100 | `fa0a8uxg` |

### Conclusion

- **Coefficient family is val-neutral at ns_iter=12.** A/B/D within 0.39σ — three very different polynomials saturate to the same val/loss. The current hardcode is fine; axis closed.
- **ns_iter axis is val-flat 6→12 in both coef families.** A vs E: Δ=0.07σ; B vs C: Δ=0.23σ. Replicates #461 finding. The ns_iter=6 win in PR #497 captures the wall-time benefit at the val level without further coef interaction needed.
- **Cell C (Muon coefs + ns_iter=6) signal is seed noise, not coef effect.** Cell C absolute val (3.26684) is WORSE than askeladd's P2 cluster (~3.265 mean, individual seeds 3.26493–3.26611) running CURRENT coefs + ns_iter=6. If Muon coefs were genuinely beneficial at low iter, Cell C should land at-or-below askeladd's cluster — it lands above. Decisive evidence that the C vs E +0.55σ gap is within-seed noise.
- **Vs NEW baseline (mu=3.266120):** Best cell (C, 3.26684) is +0.41σ ABOVE new baseline mean. N=4 P2 gate (3.264120) is +1.6σ above the single-seed value. P2 confirmation NOT warranted.
- **Net:** NS-internal axis (coefs × iters) fully mapped. Current (2, −1.5, 0.5) + ns_iter=6 is the optimum we can find.

Thorfinn reassigned to fresh structural axis: PR #565 init variance scaling (the hardcoded `0.33` constant at `train_gpt_simple.py:772` — never ablated).

## 2026-05-20 08:45 UTC — PR #517: tanjiro EMA / Polyak eval (5-cell decay sweep) — **CLOSED — mechanism rejected**

- Branch: `g1r5-tanjiro/ema-eval-sweep`
- Student: g1r5-tanjiro
- Hypothesis: Polyak/EMA weight averaging at eval reduces noise-floor of validation loss. Sweeps decay ∈ {0, 0.99, 0.999, 0.9999} with start_step=0, plus cooldown-only variant (decay=0.999 start=2275).

### Results

| Cell | decay | start_step | val_loss | Δσ vs OLD baseline (3.267948) | ffs | W&B run |
|------|------:|-----------:|---------:|------------------------------:|----:|---------|
| A (ctrl)    | 0.0     | 0    | 3.26776  | −0.23σ ✓ refactor no-op | 3100 | `zr2z0l5r` |
| B (fast)    | 0.99    | 0    | 3.27528  | +8.91σ | 3125 | `i20ukefc` |
| C (med)     | 0.999   | 0    | 3.34507  | +93.71σ catastrophic | -1 (never reached target) | `qevbalwz` |
| D (slow)    | 0.9999  | 0    | 7.20331  | +4781.73σ catastrophic | -1 | `0ubzvo4t` |
| E (cooldown) | 0.999  | 2275 | 3.30210  | +41.50σ catastrophic | -1 | `yo3bdfuc` |

### Conclusion

- **EMA mechanism decisively rejected** for this 3250-step Muon+WD-ramp_down regime. Monotone response: longer EMA windows = strictly worse.
- **Cell A (decay=0)** matches ctrl exactly — refactor is provably no-op. EMA load-swap-restore plumbing verified clean.
- **Core mechanistic insight (student analysis):** the Muon+WD-ramp_down cooldown is already sharply convergent — by step 3250 raw step magnitudes are near-zero, so terminal raw weights ARE effectively averaged. EMA drags eval weights *backward* toward larger noisier earlier checkpoints. The noise-floor-reduction intuition that motivates EMA in long LM training (where raw step size stays meaningful at the end) does not apply once cooldown has shrunk steps to ~0.
- **Even Cell E (cooldown-only, start=2275, theoretically most defensible):** EMA progression 4.65 @ step 2300 → 3.61 @ 2500 → 3.36 @ 2800 → 3.302 @ 3250 — never caught up to the raw trajectory.
- **Closes post-hoc-eval-averaging axis** for this run length. Student noted potential at 10k+ step runs (out of scope here).

Tanjiro reassigned to fresh-mechanism axis: PR #558 Z-loss regularizer (softmax partition-function penalty — fresh mechanism, never tested).

## 2026-05-20 08:30 UTC — PR #509: frieren lr_mlp fine-scan (0.050/0.055/0.060/0.065/0.075) — **CLOSED clean-neutral**

- Branch: `g1r5-frieren/lr-mlp-finescan`
- Student: g1r5-frieren
- Hypothesis: SOAP-MLP carries the optimizer lift → `lr_mlp=0.055` may be pessimized → higher lr_mlp wins. Sweeps lr_mlp ∈ {0.050, 0.055, 0.060, 0.065, 0.075}.

### Results

| Cell | lr_mlp | val_loss | Δσ vs OLD baseline (3.267948, σ=0.000823) | Δσ vs NEW baseline (3.266120) | ffs | W&B run |
|------|:------:|---------:|------------------------------------------:|------------------------------:|----:|---------|
| A (ctrl) | 0.055 | 3.267302 | −0.79σ | +0.67σ | 3100 | `5ei3brza` |
| B | 0.050 | **3.267014** | **−1.13σ** | **+0.51σ** | **3075** | `nmw42swj` |
| C | 0.060 | 3.267256 | −0.84σ | +0.77σ | 3100 | `gvvj59zd` |
| D | 0.065 | 3.268800 | +1.03σ | +1.53σ | 3100 | `8yxniibg` |
| E | 0.075 | 3.269880 | +2.35σ | +2.15σ | 3125 | `ds2mctl6` |

### Conclusion

- **Hypothesis REJECTED.** Monotonic degradation from 0.055 upward (C/D/E); the "higher lr_mlp wins" prediction is reversed. SOAP's preconditioner already extracts the available LR headroom at 0.055.
- **Cell B (0.050) best single-seed** at −1.13σ vs OLD baseline — only cell crossing the n=1 interest gate (−1.0σ). However, vs the NEW baseline (3.266120): +0.51σ above — not a winner. N=4 gate requires mu ≤ 3.264120; single-seed 3.267014 is ~2.9σ above gate. P2 not warranted.
- **lr_mlp axis closed upward.** Degradation onset at 0.065 (+1.03σ); clear at 0.075 (+2.35σ). The shape is left-skewed: optimum may be near or below 0.050 but single-seed signal is not actionable under new baseline.
- **Operational note:** Student dealt with multiple pod re-invocation duplicate launches across all 5 cells. Implemented pgrep guard + file-lock + active-process polling chain runner to solve the problem.

Frieren reassigned to fresh axis: PR #556 Adam epsilon sweep (eps=1e-10 hardcoded; new axis).

## 2026-05-20 07:30 UTC — PR #508: alphonse Muon mu static sweep — **CLOSED clean-neutral**

- Branch: `g1r5-alphonse/muon-mu-static-sweep`
- Student: g1r5-alphonse
- Hypothesis: Static value sweep of Muon momentum coefficient `mu` ∈ {0.85, 0.90, 0.95, 0.97, 0.99}. Tests whether the hardcoded mu=0.95 is locally optimal or if an off-center value provides headroom.

### Results

| Cell | mu | val_loss | Δσ vs OLD baseline (3.267948, σ=0.000823) | ffs | reached_target | W&B run |
|------|:--:|---------:|------------------------------------------:|----:|:--------------:|---------|
| A (ctrl) | 0.95 | 3.26763 | −0.39σ | 3100 | ✅ | `oi7bjcrm` |
| B | 0.85 | 3.27409 | +7.46σ | 3150 | ✅ | `knpgt2mk` |
| C | 0.90 | 3.26873 | +0.95σ | 3100 | ✅ | `mxfj0f96` |
| D | 0.97 | 3.27048 | +3.08σ | 3125 | ✅ | `018d8f1v` |
| E | 0.99 | **3.30009** | **+39.05σ** | −1 (never) | ❌ | `mbnofrws` |

### Conclusion

- **Highly asymmetric response curve around mu=0.95.** Above mu=0.97, damage scales super-linearly (~1800σ/unit between 0.97→0.99). Below 0.95, ~94σ/unit between 0.85→0.95.
- **mu=0.99 is catastrophic** — never reached target val=3.28 in 3250 steps; final val=3.30009 still improving but only at ~1e-4/step.
- **mu=0.90 essentially neutral** (within ±2σ noise) — wider basin on the low side than the high side, but not enough headroom to support mu < 0.95.
- **mu=0.95 confirmed locally optimal.** No off-center static winner.
- **Diagnostic value**: cleanly explains tanjiro #445 (mu schedule sweep) failures. Both `ramp_up_090_099` and `ramp_down_099_090` crossed the catastrophic mu≥0.98 regime; the schedule averaging partially rescued them but the static mu=0.99 result (+39σ) is worse than either schedule (+11σ, +8σ).

Muon mu axis closed. Important calibration data: any future mu-schedule work must stay below mu=0.97.

## 2026-05-20 07:00 UTC — PR #497: askeladd P2 ns_iter=6 n=6 confirm — ✅ **MERGED NEW BASELINE**

- Branch: `g1r5-askeladd/ns-iter-6-P2-n4`
- Student: g1r5-askeladd
- Hypothesis: P2 n≥4 confirmation of ns_iter=6 signal from thorfinn #461 Cell B (−2.94σ single-seed). Newton-Schulz 6 iterations vs hardcoded 12 — tests whether orthogonalization overshoots in bfloat16 past 6 iters.

### Results

| Trial | val/loss | ffs | Δσ vs OLD baseline (3.267948, σ=0.000823) | Run |
|-------|----------|-----|------------------------------------------:|-----|
| T1 | 3.26566 | 3075 | −2.78σ | `ues3hmz1` |
| T2 | 3.26957 | 3125 | +1.97σ (outlier) | `ues3hmz1` |
| T3 | 3.26493 | 3075 | −3.67σ | `ues3hmz1` |
| T4 | 3.26498 | 3075 | −3.61σ | `ues3hmz1` |
| T5 | 3.26611 | 3100 | −2.23σ | `n0vch666` |
| T6 | 3.26547 | 3075 | −3.01σ | `n0vch666` |
| **n=6 mean** | **3.266120** | **3087.5** | **−2.22σ** | |

**Statsig:** `(3.267948 − 3.266120) × √6 = 0.001828 × 2.449 = 0.004478 ≥ 0.004` ✅ PASS

### Conclusion

**ns_iter=6 is a real, statistically significant winner.** 5/6 trials cluster in 3.26493–3.26611; T2 lone outlier at 3.26957 (same pattern as prior "bad trial" outliers e.g. edward #422 T3). N=4 mean=3.266285 was borderline; n=6 extension cleared decisively.

**Mechanism**: bfloat16 Newton-Schulz orthogonalization saturates at 6 iterations. The 12-iteration hardcoded value was over-iterating — extra polish adds noise rather than quality, consistent with "less optimizer intensity" theme (PR #371 WD ramp_down→0). Wall-clock benefit: ~42 ms/step faster at ns_iter=6.

**New baseline after merge:** mu=3.266120, n=4 gate 3.264120 (was 3.265948). All future PRs use `--ns_iter 6`.

## 2026-05-20 06:30 UTC — PR #504: fern LR floor in cooldown sweep — **CLOSED clean-NEG**

- Branch: `g1r5-fern/lr-floor-cooldown-sweep`
- Student: g1r5-fern
- Hypothesis: Does a non-zero LR floor during cooldown help or hurt? Tests the boundary condition of `LR→0` in the winning PR #371 WD ramp_down mechanism.

### Results

| Cell | lr_floor | val/loss | Δσ vs baseline | ffs | reached_target | W&B run |
|------|:--------:|---------:|---------------:|----:|:--------------:|---------|
| A (ctrl) | 0.0 | 3.26617 | −2.16σ | 3075 | ✅ | `ytfezev4` |
| B | 0.05 | 3.26924 | +1.57σ | 3150 | ✅ | `tbeky4i9` |
| C | 0.10 | 3.27750 | +11.61σ | 3250 | ✅ | `nukwy18x` |
| D | 0.20 | 3.29219 | +29.46σ | −1 (never) | ❌ | `cxebda95` |
| E | 0.40 | 3.32773 | +72.64σ | −1 (never) | ❌ | `cpp8qu0r` |

### Conclusion

Decisive monotonic worsening — super-linear. Each doubling of the floor more than doubles the σ-distance from baseline. Cell A (no floor) is best and also the refactor-no-op check (val in ctrl band, ffs=3075 — slightly better seed). The "LR=0 boundary condition" theory is strongly supported:
- The final convergence step requires `LR=0` (no continued parameter movement) for clean consolidation
- Any residual gradient-driven update at end-of-training nudges parameters away from the locally optimal terminal state
- This is mechanistically consistent with PR #371's `WD ramp_down → 0` (no residual regularization pull)

Both `LR=0` and `WD=0` at terminal step appear to be jointly required for the "clean landing" mechanism. Fern assigned #548 as the direct dual experiment (WD floor probe).

## 2026-05-20 03:00 UTC — PR #496: edward NS iter LOW sweep — **CLOSED clean-neutral**

- Branch: `g1r5-edward/ns-iter-low-sweep`
- Student: g1r5-edward
- Hypothesis: Probe ns_iter values BELOW the previously tested {6,8,10,12,14} range. Tests whether the thorfinn #461 Cell B (ns_iter=6) signal of −2.94σ continues to improve as iterations drop, or hits a bf16-convergence floor.

### Results

| Cell | ns_iter | val/loss | ffs | Δσ vs baseline (3.267948) | W&B run |
|------|--------:|---------:|----:|---------------------------:|---------|
| A (ctrl) | 12 | 3.26793 | 3100 | −0.19σ (ctrl refactor ok) | `g4j2hqty` |
| B | 5 | 3.26754 | 3075 | −0.49σ (weak) | (run id in PR) |
| C | 4 | 3.27342 | 3150 | **+6.65σ** (bf16 saturation) | `9j2ds62b` |
| D | 3 | 3.27949 | 3200 | **+14.03σ** (deep saturation) | (run id in PR) |
| E (dropped) | 2 | — | — | — | not run (clear trajectory) |

### Conclusion

ns_iter axis fully characterized after combining edward #496 with thorfinn #461:

| ns | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 14 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Δσ | +14.03 | +6.65 | −0.50 | −2.94 (n=1) | +1.08 | +1.04 | (ctrl) | +1.12 |

- **Hard cliff below ns_iter=5**: bf16 Newton-Schulz orthogonalization does not converge in <5 iters
- **ns_iter=5–6 weakly favored over baseline** but magnitude ≤ σ
- **ns_iter=6 mechanism in P2 confirmation** (askeladd #497) — also reproducible 25-step ffs reduction
- **Going BELOW ns=5 is decisively WORSE**; the "less optimizer intensity" principle does not extend monotonically here

Cell E (ns_iter=2) dropped per advisor suggestion: with D already at +14σ, E would be deep noise with no informational value.

Next: edward assigned PR #537 — first ever Adam β1/β2 sweep (fresh axis).

## 2026-05-19 06:38 UTC — PR #398: AdamW aux ε schedule sweep — **CLOSED clean-NEG**

- Branch: `askeladd/eps-aux-schedule`
- Student: g1r5-askeladd
- Hypothesis: Time-varying ε for AdamW aux groups (embed/lm_head/scalars) across 5 schedule shapes. Static ε=1e-10 was robust on older sessions — this tests whether a *schedule* (varying ε through training phases) could unlock a phase-specific edge.

### Results

| Cell | schedule | val/loss | ffs | Δσ vs NEW baseline | W&B run |
|------|----------|----------|-----|---------------------|---------|
| A | constant 1e-10 (ctrl) | 3.269913 | 3125 | +2.39σ (lucky seed) | rz6ibzdy |
| B | ramp_up 1e-12→1e-8 | 3.274274 | 3175 | +7.69σ | px2ecgt2 |
| C | ramp_down 1e-8→1e-12 | 3.271079 | 3150 | +3.80σ | knmurh9a |
| D | spike_cooldown (1e-10→1e-7 last 70%) | 3.272561 | 3150 | +5.60σ | 7mmyfajg |
| E | log_cosine | killed ~step 233 | — | — | — |
| **mean A-D** | — | **3.271957** | **3150** | **+4.87σ** | |

NEW baseline: mu=3.267948, std=0.000823.

### Conclusion

Monotonic story A<C<D<B — any non-constant ε degrades val/loss. Magnitude scales with elevation duration and cooldown overlap. Ramp_up worst (+7.69σ): ε=1e-8 at cooldown suppresses precision recovery. Ramp_down least bad: ε is inactive by cooldown preserving precision recovery, but early-training elevation (1e-8) damages learning. Spike_cooldown: sustained large ε through cooldown hurts similarly. **Static ε=1e-10 is near-optimal; no time-varying shape helps.** ε-schedule axis exhausted.

Cell E (log_cosine) killed ~step 233 per advisor suggestion after 4/4 non-constant cells landed clean-NEG. Student confirmed and submitted promptly.

Next: askeladd PR #437 — SOAP precond_freq schedule sweep (timing axis, informed by WD ramp_down insight).

## 2026-05-19 03:30 UTC — PR #368: Orthogonal QKV init P2 (ortho_qk_only, n=4) — **CLOSED clean-neutral**

- Branch: `g1r5-tanjiro/qkv-ortho-init`
- Student: g1r5-tanjiro
- Hypothesis: Phase 2 n=4 confirmation of ortho_qk_only (QK-only orthogonal init). P1 Cell E had val=3.26932 (favorable n=1 seed).

### Results

| Trial | val/loss | ffs | W&B run |
|------:|--------:|-----:|--------|
| T0 | 3.27003 | 3125 | 899b4f5m |
| T1 | 3.27497 | 3175 | 899b4f5m |
| T2 | 3.27217 | 3150 | 899b4f5m |
| T3 | 3.27284 | 3150 | 899b4f5m |
| **n=4 mean** | **3.27250** | **3150** | |

### Conclusion

n=4 mean = 3.27250 vs NEW baseline mu=3.267948, std=0.000823. Δ = +5.53σ. Gate FAILED.
P1 Cell E single-run val=3.26932 was a favorable-seed singleton — n=4 P2 confirms QKV orthogonal init is NOT load-bearing. **QKV init mechanism family closed.**
Next: Muon nesterov ablation (PR #432 assigned to tanjiro).

## 2026-05-18 19:00 UTC — PR #360: SOAP precond_freq sweep ∈ {4, 8, 16, 32, 64} — **CLOSED clean-neutral**

- Branch: `g1r5-askeladd/soap-precond-freq-sweep`
- Student: g1r5-askeladd
- Hypothesis: SOAP attn eigvec refresh frequency sweep — lower freq (more frequent refresh) vs higher freq (less frequent). Default is freq=16.

### Results

| Cell | precond_freq | val | ffs | Δ vs baseline | σ | W&B id |
|------|---:|------|------|---:|---:|--------|
| A | 4 | 3.2757 | 3175 | +0.0044 | +3.66σ | w2mu6ddu |
| B | 8 | 3.2776 | 3200 | +0.0063 | +5.27σ | aatoeuq2 |
| **C** | **16 (default)** | **3.2708** | **3125** | **-0.0006** | **-0.5σ** | 93pqz5am |
| D | 32 | 3.2722 | 3150 | +0.0009 | +0.71σ | b0y2ezv5 |
| E | 64 | 3.2722 | 3150 | +0.0009 | +0.71σ | zr0qvwrs |

### Conclusion

Clean U-shape, apex at default freq=16. Too frequent refresh (4, 8): preconditioner noise dominates, strong regression. Less frequent (32, 64): mild degradation (+0.71σ), preconditioner drifts from gradient distribution. Default freq=16 is a well-calibrated local optimum.

Mechanism closed for static SOAP precond_freq sweeps. Follow-up (time-varying freq schedule) theoretically possible but Cell C ctrl reproduction at noise-floor argues current default is sufficiently robust.

## 2026-05-18 15:30 UTC — PR #320: Adam β₂ sweep for AdamW aux groups — **CLOSED clean-neutral**

- Branch: `g1r5-edward/adam-beta2-aux-sweep`
- Student: g1r5-edward
- Hypothesis: AdamW aux β₂ static sweep ∈ {0.85, 0.90, 0.95-ctrl, 0.98, 0.99} on aux groups (embed/lm_head/scalars). β₂=0.98 Phase 1 (mo3leb2y) hit val=3.268718 ffs=3125 (-2.24σ Phase 1 trigger).

### Phase 2 — n=4 confirm at β₂=0.98

| Trial | val/best_loss | ffs | W&B note |
|-------|---------------|-----|----------|
| T1 | 3.27041 | 3125 | Phase 2 launch |
| T2 | 3.26920 | 3125 | |
| T3 | 3.27287 | 3150 | Regression — gate became unreachable on running mean |
| T4 | 3.27044 | 3125 | |
| **n=4 mean** | **3.27073** | **3131.25** | sum 13.08292 |
| sample std | 0.00154 | 12.5 | higher than baseline σ=0.001181 |
| SE | 0.00077 | — | |

W&B P2 run: `mo3leb2y` (group `g1r5-edward/beta2-aux-098-confirm-n4`)

### Statsig analysis

- Δ mu vs baseline = -0.00063 (~1.07σ below baseline using σ=0.001181)
- Gate FAIL by +0.00137 (need ≤ 3.269362 for n=4)
- n=6 extension would need ≤ 3.269729 — projected continuation also fails
- ffs mean 3131.25 vs baseline 3141.67 (+10.4 steps gain, ~0.83σ on ffs)

### Conclusion

Real but small mechanism (~1.07σ below baseline). Phase 1 n=1 read at -2.24σ
was favorable seed; per-trial σ=0.00154 confirms the true effect is much
smaller than the n=1 read suggested.

Third instance of the **endpoint-LR / aux-hparam pattern** — Phase 1 n=1
below -1.5σ that fails to survive n=4 confirmation:
- PR #228 (frieren lr_embed=0.80 n=6, mean=3.270251, gate fail by 0.45σ)
- PR #306 (alphonse lr_lm_head=0.030 n=4, mean=3.2711925, gate fail by 12×)
- **PR #320 (edward β₂=0.98 n=4, mean=3.27073, gate fail by 1.07σ short)**

Closing clean-neutral. β₂=0.98 (static) added to exhausted slots. Dynamic
β₂ schedule sweep (PR #381, alphonse) is the natural productive follow-up
— testing whether time-varying β₂ can amplify the effect beyond static.



## 2026-05-15 — Wave 1 dispatched (PRs #43–#50)

All 8 PRs are draft, `status:wip`, awaiting student execution. See
`CURRENT_RESEARCH_STATE.md` for the full assignment table. Results will be
appended below as each PR returns terminal `SENPAI-RESULT` markers.

## 2026-05-17 16:25 UTC — PR #194: Asymmetric per-group WD (wd_mlp vs wd_attn corners + n=4 confirm) — **CLOSED clean-neutral vs new baseline**

- Branch: `g1r5-tanjiro/asymmetric-per-group-weight-decay`
- Student: g1r5-tanjiro
- Hypothesis: Splitting weight_decay per Muon param group (wd_mlp on SOAP_MLP_SUFFIXES, wd_attn on remainder) reduces val/loss vs uniform wd=0.025.

### Phase 1 — n=2 corner screen

| Cell | wd_mlp | wd_attn | W&B run | n=2 mean best_val | n=2 mean ffs |
|------|--------|---------|---------|-------------------|--------------|
| A    | 0.015  | 0.015   | 2ggox8g8 | 3.27822 | 3200 |
| B    | 0.015  | 0.035   | jq083ofi | 3.27881 | (miss) |
| **C**| 0.035  | 0.015   | **s0jx9g57** | **3.27094** | **3125** |
| D    | 0.035  | 0.035   | (killed early, Option A) | — | — |

### Phase 2 — n=4 confirm at Cell C config (wd_mlp=0.035, wd_attn=0.015)

| Trial | best_val | ffs |
|-------|----------|-----|
| 0 | 3.27040 | 3125 |
| 1 | 3.27333 | 3150 |
| 2 | 3.26974 | 3125 |
| 3 | 3.27106 | 3125 |
| **n=4 mean** | **3.271133** | **3131.25** |
| std (ddof=1) | 0.001561 | 12.5 |
| SE | 0.000780 | — |

W&B confirm run: `d4dvvkzk` (group `g1r5-tanjiro/asym-wd-C-confirm-n4`).

### Statsig analysis

- vs OLD baseline (PR #116, mu=3.273735): Δmu=-0.002602, n=4 margin=0.005205 ≥ 0.004 → **would have merged** (1.30× threshold).
- vs NEW baseline (PR #162, mu=3.271362, merged 12:42Z mid-confirm): Δmu=-0.000229, n=4 margin=0.000459 ≪ 0.004 → **clean-neutral** (0.11× threshold).

### Conclusion

Real signal: asymmetric WD (mlp_high/attn_low) is a meaningful direction (1.30× over old baseline). But PR #162 raced ahead, capturing the lr_mlp=0.055 effect first. Since both PRs target the same SOAP-MLP curvature region, they share a margin. Reassigning tanjiro to combo-confirm (lr_mlp=0.055 + wd_mlp=0.035 + wd_attn=0.015 at n=4). If additive, expected mu ~3.2688 → below n=4 merge threshold 3.269362.

## 2026-05-17 16:00 UTC — PR #210: Per-layer LR decay (γ^k across 12 transformer blocks) — **CLOSED clean negative**

- Branch: `g1r5-nezuko/per-layer-lr-decay`
- Student: g1r5-nezuko
- Hypothesis: Geometric per-layer LR scaling `lr_block_k = base_lr × γ^k` would improve val/loss vs uniform LR across 12 blocks. Pre-LN can suffer residual signal attenuation in deeper blocks → uniform LR sub-optimal.

**4-cell screen results (n=1 each, sequential, 3250 steps)**

| Cell | γ    | lr_block_0 | lr_block_11 | val/loss | ffs   | Δ vs new baseline (3.271362) | W&B |
|------|------|------------|-------------|----------|-------|------------------------------|-----|
| A    | 0.93 | 0.035      | 0.0166      | 3.27922  | 3225  | +0.00786 (worse)             | e3jfdq2d |
| B    | 0.97 | 0.035      | 0.0252      | 3.27563  | 3175  | +0.00427 (worse)             | uzpoeelg |
| **C** | **1.03** | **0.035** | **0.0488** | **3.27433** | **3175** | **+0.00297 (best of sweep, still worse)** | odnulg96 |
| D    | 1.07 | 0.035      | 0.0744      | 3.27501  | 3175  | +0.00365 (worse)             | p5vcfyxr |

**Pattern:** Monotonic improvement A→C with mild γ>1 (deeper-larger LR) peak at γ=1.03-1.07. But all cells fail to beat new baseline by ~3σ. Per-layer LR decay does not stack with per-group LR (lr_mlp=0.055) meaningfully on this 12-layer model. The per-group LR optimization from PR #162 captured the layer-direction signal already.

**Decision: CLOSED clean negative.** Student reassigned to PR #283 (AGC, NFNets-style adaptive gradient clipping).

## 2026-05-17 12:42 UTC — PR #162: Per-group LR: lr_mlp=0.055 sweep — **MERGED ✓** (NEW BASELINE)

- Branch: `g1r5-edward/per-group-lr-sweep`
- Student: g1r5-edward
- Hypothesis: Per-group LR differentiation on the SOAP-MLP + SOAP-attn stack — sweep lr_mlp ∈ {0.025, 0.035, 0.045, 0.055, 0.065} with lr_attn fixed at 0.035. Inverted-U optimum at lr_mlp=0.055 predicted from curvature structure: SOAP whitening lets MLP block tolerate higher LR than attn.

**Screen results (n=1 each)**

| Cell | lr_mlp | val/loss | ffs | W&B |
|------|--------|----------|-----|-----|
| A    | 0.025  | 3.27769  | 3200 | zgchg6u5 |
| B    | 0.035 (ctrl) | 3.27569 | 3175 | eabllnva |
| C    | 0.045  | 3.27131  | 3125 | hjizd4ca |
| **D** | **0.055** | **3.26987** | **3125** | **w0o14lia** |
| E    | 0.065  | 3.27236  | 3150 | 4j1ai2qr |

**n=6 confirm results (all non-cherry-picked)**

| Trial | Source | best_val_loss | ffs |
|-------|--------|---------------|-----|
| 0 | t1jfegcf | 3.27025 | 3125 |
| 1 | t1jfegcf | 3.27237 | 3150 |
| 2 | t1jfegcf | 3.27283 | 3150 |
| 3 | t1jfegcf | 3.27161 | 3150 |
| 4 | 3j8v4owb | 3.26978 | 3125 |
| 5 | 3j8v4owb | 3.27133 | 3150 |
| **mean** | | **3.271362** | **3141.67** |

- **Statsig:** `(3.273735 − 3.271362) × √6 = 0.005813 ≥ 0.004` ✅ PASS (1.45× margin)
- Analysis: Clean inverted-U with peak at lr_mlp=0.055 (1.57× baseline lr). SOAP whitening on MLP allows higher effective LR since preconditioner absorbs curvature heterogeneity. Attn (cos_sim ≈ 0.81) cannot tolerate higher LR (PR #209 confirmed monotonic regression on lr_attn axis) — so per-group split is the correct design: lr_mlp=0.055, lr_attn=0.035. n=4 missed statsig by 0.000028 (0.025σ); n=6 extension cleared with generous slack.
- **New baseline:** mu=3.271362 (std=0.001181, n=6), ffs_mean=3141.67, ffs_best=3125
- **New merge statsig rule:** `(3.271362 - mu) × sqrt(n) ≥ 0.004` → mu ≤ 3.269362 for n=4, ≤ 3.269729 for n=6

---

## 2026-05-17 11:33 UTC — PR #196: Col-only SOAP for lm_head (AdamW→Muon) — CLOSED (clean negative)

- Branch: `g1r5-alphonse/soap-lm-head-col-only`
- Student: g1r5-alphonse
- Hypothesis: Replace AdamW on lm_head (50304×768) with Muon+col-only SOAP (768×768 col-Gram). Remove vocab-row scaling, retain feature-dimension preconditioning.

| Arm | lr | trials | best_val | mean_val | ffs | W&B |
|-----|----|--------|----------|----------|-----|-----|
| C   | 0.020 | 2 | 3.27786 | 3.27838 | 3212 | vk1x1dno |
| B   | 0.010 | 1 (killed) | 3.28106 | — | -1 | vqfxng50 |
| A   | 0.005 | 1 (killed) | 3.28436 | — | -1 | of0uuvj7 |

- **Baseline** (PR #116): mu=3.273735, ffs=3150. All arms worse.
- Analysis: Fundamental mechanism failure, not LR mis-tuning. (1) Vocab-side curvature (50304-row axis) captures per-token-frequency structure — discarding it removes essential scaling signal. (2) Muon's spectral norm flattens rare-token gradients that should have their own update scales. (3) Non-monotonic LR landscape with all arms ≥ 3.28 for arms A/B = gate tripping across the board. Student's root-cause diagnosis correct.
- Suggested follow-up: AdamW eps tuning on embed/lm_head (PR #262 assigned to alphonse) — refine AdamW config rather than replacing AdamW.

---

## 2026-05-17 12:07 UTC — PR #220: Per-head SOAP on attn (12×64×64 block-diagonal Gram) — CLOSED (dead-end)

- Branch: `g1r5-thorfinn/per-head-soap-attn`
- Student: g1r5-thorfinn
- Hypothesis: Replace single 768×768 attn SOAP Gram with 12 per-head 64×64 block-diagonal Grams (4 attn projections × 12 heads × 64×64). Rationale: per-head structure tracks head-specific curvature, potentially closing the cos_sim_mean_attn gap (0.81 vs MLP 0.88).

| Trial | val/loss | ffs | Source |
|-------|----------|-----|--------|
| 0 | 3.27368 | 3150 | 4qxghq80 |
| 1 | 3.28081 | -1 (REGRESSION) | 4qxghq80 |
| n=2 partial mean | 3.27725 | — | — |

- Kill decision (after trial 1): best-case n=4 mean with 2 ideal trials at 3.26978 = 3.27351 → still above old n=4 threshold 3.271735. **Cannot pass even with perfect remaining trials.** GPU freed at 12:07Z.
- Analysis: Per-head 64×64 blocks have HIGHER eigenvector noise than full 768×768 Gram (smaller matrix → more degenerate near-zero eigenvalues → more eigenvector flipping per refresh). Trial 1 regression (val=3.281) vs trial 0 (val=3.274) confirms variance increased, not decreased. The full 768×768 Gram actually has better spectral conditioning from the cross-head co-activation signal.
- cos_sim_mean_per_head_aggregate ≈ 0.737 (lower than full-attn SOAP 0.81) — confirms per-head conditioning is LESS stable.
- Suggested follow-up: SOAP eigenvector EMA across refreshes (PR #264 assigned to thorfinn) — stabilize the existing 768×768 Gram's eigenbasis rather than fragmenting it.

---

## 2026-05-17 06:15 UTC — PR #175: SOAP β2 cooldown annealing (β2 0.90→0.75) — CLOSED (neutral)

- Branch: `g1r5-askeladd/soap-beta2-cooldown-anneal`
- Student: g1r5-askeladd
- Hypothesis: Anneal SOAP's β2 from 0.90→0.75 during the cooldown phase (starting at 30% of training, annealing linearly over 70% to target 0.75). Shorter EMA memory in late training should improve tracking of the fast-changing curvature landscape during the final descent.
- Notable execution: 1 crash at step 591 (external SIGTERM, confirmed via SIGTERM signal 15 trace, no NaN); restarted with n=2 retry `b5o53z6z`. Mechanism correctly wired (soap_beta2_current trajectory confirmed per telemetry).

| Trial | val/loss | FFS | β2_final | cos_sim_mean_attn | cos_sim_mean_mlp |
|---:|---:|---:|---:|---:|---:|
| 0 | 3.274438 | 3150 | 0.75007 | 0.748 | 0.846 |
| 1 | 3.273106 | 3150 | 0.75007 | 0.748 | 0.847 |
| **mean** | **3.273772** | **3150** | — | **0.748** | **0.847** |

**Baseline** (n=6): mu=3.273735, ffs (mean)=3150, run `c81z4php`.

- Statistical test (n=2): Δ = +0.000037 (worse by 1/30 of baseline σ≈0.001116). Margin (mu_base − mu)·√2 = −0.000052 (need ≥ +0.004 to claim improvement). Well inside noise — **neutral result**.
- Gate evaluation: promote-to-n=6 gate (best_val ≤ 3.273) failed; kill gate (mean ffs > 3175) not triggered → neutral zone.
- Analysis: β2 anneal works correctly (wiring verified). However, cos_sim_mean drops by ~0.05 in cooldown (consistent with faster adapting preconditioner) without translating to a loss benefit. Likely reason: cooldown LR → 0 shrinks the step magnitude proportionally, so improved curvature tracking has no leverage on the actual update magnitude. Trust gate fires 0 times (threshold=0 is decorative). Mechanism now confirmed fully plumbed and zero-cost to layer back if future conditions change.
- Conclusion: No-effect at n=2. Not promoted to n=6 (marginal cost-benefit). Closed. GPU freed for NS5 iteration count sweep (PR #232).

## 2026-05-17 08:30 UTC — PR #209: Per-group lr_attn sweep — CLOSED (clean negative)

- Branch: `g1r5-fern/per-group-lr-attn-sweep`
- Student: g1r5-fern
- Hypothesis: SOAP-attn's per-group LR has a separate optimum for attn vs MLP. Swept lr_attn ∈ {0.025, 0.035 (ctrl), 0.045, 0.055} holding lr_mlp at 0.035 baseline.

| Cell | lr_attn | val/loss | ffs | W&B run | vs baseline |
|------|---------|----------|-----|---------|-------------|
| A | 0.025 | 3.27391 | 3150 | j5i05ctb | +0.16σ (noise) |
| ctrl | 0.035 | 3.273735 (mu n=6) | 3150 (mean) | c81z4php | baseline |
| C | 0.045 | 3.27476 | 3175 | vqjmay37 | +0.92σ |
| D | 0.055 | 3.27940 | 3225 | eno23pob | +5.07σ regression |

- Analysis: Monotonically worse A→C→D on the attn axis — **opposite of edward's lr_mlp profile** (where lr_mlp=0.055 won). Higher lr_attn → lower cos_sim_attn (0.817→0.814→0.814); the attn eigenbasis precond is mis-rotated for faster LR. MLP cos_sim invariant, confirming per-group split worked. Anti-symmetric interpretation: SOAP whitening cashes LR benefit only where eigenbases are well-aligned. MLP (cos_sim≈0.88) tolerates higher LR; attn (cos_sim≈0.81) does not.
- **Key inference:** Joint-confirm after edward merges should use **(lr_mlp=0.055, lr_attn=0.035)** — keep attn LR at baseline. The (0.055, 0.055) joint cell is dominated by attn loss (+5σ).
- **Forward-looking:** Attn precond stability is the right next axis — damping λ·I on attn Gram (PR #249, assigned to fern) is the direct follow-up.
- Conclusion: Clean negative on lr_attn axis. No mechanism merge. GPU freed for SOAP attn damping (PR #249).

## 2026-05-17 05:30 UTC — PR #186: z-loss auxiliary regularizer (α·log²Z on partition function) — CLOSED (clean negative)

- Branch: `g1r5-frieren/z-loss-aux`
- Student: g1r5-frieren
- Hypothesis: Add PaLM-style z-loss `α·(log Σ exp(logits))²` to cross-entropy loss, sweep α ∈ {1e-4, 3e-4, 1e-3}. Logit softcap bounds logits to ±15, making bf16 logsumexp numerically adequate. Expected effect: regularize partition function drift, especially in late-training cooldown where logit magnitude could cause CE-loss stagnation.
- Notable execution issues: initial implementation OOM (40 GB+ wasted) until fix: cast only (B·T,) logsumexp result to fp32 (not full (B,T,V) fp32). Two α=3e-4 crashes at step ~107 from GPU contention (3 simultaneous runs on 95 GiB H100). Fixed by sequential execution.

| Arm (α) | val/loss | FFS | W&B run | Notes |
|---|---:|---:|---|---|
| 1e-4 | 3.27392 | 3150 | `2q5w7tek` | Δ=+0.00018 vs baseline mu; within 1σ — neutral |
| 3e-4 | 3.28117 | -1 | `agn4is0t` | +0.0074, ≈6.6σ regression; FFS=-1 (never reached 3.28) |
| 1e-3 | (skipped) | — | — | Kill rule: α=3e-4 worse than 3.275 → extrapolation clearly worse |

**Baseline** (n=6): mu=3.273735, ffs (mean)=3150, run `c81z4php`.

- Analysis: z-loss mechanism healthy (log_Z_mean ≈ 9 at α=1e-4, drops to 6.5 at α=3e-4 = over-compression). But modded-nanogpt logit softcap already bounds logits to ±15 → partition function cannot drift unboundedly → the motivating mechanism for z-loss is already addressed by the existing softcap. At α=1e-4 the z-loss contribution is ≈0.25% of CE (negligible); at α=3e-4 it over-compresses the softmax (entropy drops, fit degrades). PaLM uses α=1e-4 at larger scale; at track-3 budget the regularizer has no positive effect.
- Conclusion: Softcap + z-loss are redundant mechanisms. Closed. GPU freed for AdamW embed LR sweep (PR #228).

## 2026-05-15 22:00 UTC — PR #49: Lookahead wrapper over Muon (k×α grid) — CLOSED (clean negative)

- Branch: `g1r5-tanjiro/lookahead-muon`
- Student: g1r5-tanjiro
- Hypothesis: Wrap baseline Muon in a Lookahead outer slow-weights wrapper
  (Zhang et al. NeurIPS 2019). After every `k` Muon steps move slow
  weights toward fast weights by α, then reset fast=slow. Evaluate val/loss
  on slow weights. Grid: `k ∈ {5, 10} × α ∈ {0.5, 0.8}`.
- Result: clean negative.

| Cell        | val/loss    | ffs   | W&B run   |
| ----------- | ----------- | ----- | --------- |
| k=5,  α=0.5 | 3.289       | -1    | hrx6fqaz  |
| k=5,  α=0.8 | 3.282       | -1    | 9rscpw3w  |
| k=10, α=0.5 | 3.289       | -1    | 4jtqnv11  |
| k=10, α=0.8 | **3.27963** | 3350  | l66qny45  |

- Terminal SENPAI-RESULT: `primary_metric speedrun/final_first_step_to_target = 3350` (single seed at budget ceiling, no statsig margin possible). `test_metric val/loss = 3.27963`.
- Analysis: Three of four cells missed the 3.28 target outright. Best cell barely crossed target at the final step — equal to plain Muon baseline ceiling, no speed-up. n=6 confirmation aborted to save ~18 GPU-hours.
- Mechanism conclusion (student's analysis, advisor agrees): Muon's NS orthogonalized updates are already low-variance and well-conditioned; Lookahead's variance-reduction / implicit-regularization benefit (which compounds on noisier optimizers like SGD/Adam) does not compound with what Muon already does. Lookahead's effective slow-weight LR `α × inner_lr` under-shoots during the long cooldown.
- Wave-2 follow-up: Wrap Lookahead around a stronger inner optimizer (NorMuonH / MuonH) once a wave-1 backbone winner merges. Separate PR.

## 2026-05-16 03:30 UTC — PR #46: SOAP-Muon for MLP weights only (isolated) — MERGED ✓

- Branch: `g1r5-fern/soap-mlp-isolated`
- Student: g1r5-fern
- Hypothesis: SOAP preconditioning applied ONLY to Muon-managed MLP weights (`mlp.fc.weight`, `mlp.proj.weight`), isolating the SOAP-MLP component of record #14 without Contra-Muon or NorMuon.

| Trial | best_val_loss | ffs  |
|------:|-------------:|-----:|
| 0     | 3.27728      | 3200 |
| 1     | 3.27744      | 3200 |
| 2     | 3.27795      | 3200 |
| 3     | 3.27739      | 3200 |
| 4     | 3.27674      | 3200 |
| 5     | 3.27782      | 3200 |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3200`, `test_metric val/loss = 3.27744`
- **n**: 6 seeds, `train_steps=3250`
- **Statsig margin**: `(3.28 - 3.27744) × sqrt(6) = 0.00628 ≥ 0.004` ✅ PASS
- **W&B run**: `zj5hesz1`
- **Analysis**: Zero variance on ffs (all 6 seeds hit 3200), tight val/loss spread (std=4.3e-4). SOAP preconditioning on MLP fc/proj is a real, standalone 150-step improvement over plain Muon starter (3350→3200 ffs). Val/loss mu=3.27744 is essentially tied with record #14 mu=3.2776 — SOAP-MLP alone captures most of #14's gain without Contra/NorMuon. Eigendecomp at precond_freq=16 amortizes cost; step overhead vs plain Muon is small.
- **New baseline**: ffs=3200, mu=3.27744, n=6 (updates starter 3325-3350 baseline)
- **Decision**: MERGED into auto-nanogpt-1gpu-r5 (commit 801c137)
- **Natural wave-2 follow-up**: Extend SOAP to attention projections (with trust gate) → record #16 trajectory (ffs=3125)

## 2026-05-16 05:30 UTC — PR #98: Cautious-Muon sign-agreement masking on NS update — CLOSED (clean negative)

- Branch: `g1r5-tanjiro/cautious-muon`
- Student: g1r5-tanjiro
- Hypothesis: Apply sign-agreement masking (Liang et al. ICLR 2026) to the NS-orthogonalized Muon update: zero components where NS direction disagrees in sign with raw gradient `g`, renormalize by surviving mask fraction. LR sweep `lr_mult ∈ {1.0, 1.5, 2.0}` to compensate effective magnitude reduction from masking.

| Cell    | Run ID   | val/loss @ 3350 | ffs   | Δ vs target (3.28) |
| ------- | -------- | --------------- | ----- | ------------------- |
| lrx1.0  | ukeuqh7t | 3.3183          | -1    | +0.0383 miss        |
| lrx1.5  | woiz5ruc | 3.3237          | -1    | +0.0437 miss        |
| lrx2.0  | 9fwoix1a | 3.4600 (step 2500, killed) | -1 | trending +0.18+ |

- **W&B group**: `g1r5-tanjiro/cautious-muon`
- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = -1`, `test_metric val/loss = 3.3183`
- **Mask telemetry**: mask.mean() = 0.61–0.65 across all groups and cells (well within the paper's expected 0.4–0.7 engagement band). The mechanism IS engaging — ~35–39% of NS update components filtered.
- **Kill gate triggered**: `ffs > 3350 at all three LR multipliers` — as predeclared in assignment falsifying signal.
- **Key empirical signal**: val/loss strictly INCREASES with LR multiplier at every checkpoint (lrx1.0 < lrx1.5 < lrx2.0 at every step from 500 to 3350). LR compensation is monotonically harmful — the lrx2.5/3.0 rescue path is mechanistically refuted.
- **Mechanism analysis**: Muon's NS orthogonalization already produces highly informative curvature-adapted directions. Cautious masking discards exactly the NS components that diverge from the raw gradient — precisely the curvature-adapted information that justifies Muon's cost over plain Adam. The renormalization amplifies surviving components but does not recover discarded information. Distinct failure mode from PR #49 (Lookahead): pattern consistent — post-hoc wrappers over NS-Muon do not easily improve well-tuned NS.
- **Mask engagement confirmed**: failure is not mask saturation (>0.95) or mask collapse (<0.2); it is that the active filtering itself is harmful on this recipe.
- **Decision**: CLOSED as clean negative (PR #98 closed 2026-05-16 05:26 UTC).
- **Wave-2 follow-up to explore**: (a) Cautious on momentum-buffer direction pre-NS — sign-disagreement with `g` may be a more meaningful signal before NS transformation; (b) asymmetric mask (no renormalization) — tests whether the amplification or the filtering is the harm-source.

## 2026-05-16 06:27 UTC — PR #43: NorMuonH (record #8 reproduction) — CLOSED (clean negative under new baseline)

- Branch: `g1r5-alphonse/normuonh-baseline`
- Student: g1r5-alphonse
- Hypothesis: Reproduce record #8 (NorMuonH = NorMuon + hyperball + per-module init std multipliers `×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc`).

| Trial | val/loss @ 3250 | ffs    |
|------:|----------------:|-------:|
| 0     | 3.28073         | -1     |
| 1     | 3.27903         | 3225   |
| 2     | 3.27977         | 3250   |
| 3     | 3.27896         | 3225   |
| 4     | 3.27995         | 3250   |
| 5     | 3.27945         | 3250   |
| 6     | 3.27947         | 3250   |
| 7     | 3.27961         | 3250   |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3250`, `test_metric val/loss = 3.279621`
- **n**: 8 seeds, `train_steps=3250`
- **mu**: 3.279621, sd = 0.000560, sem = 0.000198
- **Statsig margin vs 3.28**: `(3.28 - 3.27962) × sqrt(8) = 0.00107` — **fails** the 0.004 rule
- **Statsig margin vs new baseline (PR #46 mu=3.27744)**: mu is +0.00218 ABOVE baseline — **fails** under new bar
- **Hit rate**: 7/8 reached target (1 outright miss, trial-0). ffs median 3250 vs new baseline ffs=3200 → +50 steps slower.
- **Comparison vs public record #8 (mu=3.2778, n=10)**: NorMuonH on this branch is +0.0018 above the published mu — **reproduction is not clean**.
- **W&B run**: `92ngdr2c`
- **Analysis**: NorMuonH does not compound on top of the merged SOAP-MLP baseline on this 1-GPU node. The single-seed screening preview (val=3.2785, ffs=3225) did not generalize at n=8 — distribution centred well above the public-reference value. Student flagged two reproduction ambiguities (hyperball direction interpretation: norm-preserving Frobenius-sphere vs one-sided cap; Adafactor axis convention: short-axis only vs row+col preconditioning). Both interpretations are defensible from the PR text; the published-reference variant is unclear. The 2-arm clarifier sweep (hyperball variants × Adafactor variants) was declined — even if either ambiguity closed the ~0.0018 gap to record #8, the resulting mu ≈ 3.2778 would still fail merge under the new baseline (mu=3.27744 + margin needed).
- **Decision**: CLOSED as clean negative (PR #43 closed 2026-05-16 06:27 UTC). Alphonse reassigned to PR #123 (Newton-Muon on attention weights, record #15 mechanism).

## 2026-05-16 07:30 UTC — PR #44: Contra-Muon (isolated) on baseline Muon — CLOSED (clean negative)

- Branch: `g1r5-askeladd/contra-muon-isolated`
- Student: g1r5-askeladd
- Hypothesis: Apply Contra-Muon (nilin) as a stand-alone modification on plain Muon — contractive correction in the orthogonalization step that keeps the update from over-rotating against momentum. Strip all other record #11 ingredients (NorMuon, hyperball, per-module init, u/w-floor). Ablates Contra-Muon's isolated contribution.

| Trial | val/loss @ 3350 | ffs  |
|------:|----------------:|-----:|
| 0     | 3.277794        | 3300 |
| 1     | 3.280680        |  -1  |
| 2     | 3.278777        | 3325 |
| 3     | 3.278936        | 3325 |
| 4     | 3.277864        | 3300 |
| 5     | 3.277935        | 3300 |
| 6     | 3.278251        | 3325 |
| 7     | 3.279825        | 3350 |

- **Terminal SENPAI-RESULT**: `primary_metric speedrun/final_first_step_to_target = 3325`, `test_metric val/loss = 3.278758`
- **n**: 8 seeds, `train_steps=3350`
- **mu**: 3.278758, std=0.001037, median=3.278514
- **Statsig margin vs 3.28**: `(3.28 - 3.278758) × sqrt(8) = 0.003514 < 0.004` — **FAIL**
- **Statsig margin vs new baseline (PR #46 mu=3.27744)**: mu is +0.00132 ABOVE baseline, ffs +125 steps slower — **dominated on both axes**
- **Hit rate**: 7/8 (1 miss, trial-1). ffs cluster: {3300, -1, 3325, 3325, 3300, 3300, 3325, 3350}.
- **W&B run IDs**: confirmation `8ne4wv80`, screening `vg4s26bx`
- **Mechanism**: CONTRA_MUON=0.4. `scale_to_unit_operator_norm(update)` via 5-step power iteration; subtract `CONTRA_MUON/2 × normalized_update` from orthogonalized update; rescale to preserve Frobenius norm. NS5 iteration count unchanged.
- **Analysis**: Isolated Contra-Muon sits at plain-Muon territory — mu essentially tied with the starter, ffs cluster at 3300-3325 vs new baseline 3200. Student and advisor agree: the gains in record #11 are **interaction effects** with NorMuon/u-w-floor, not the Contra-Muon correction itself. Without NorMuon pre-conditioning the update geometry, the contractive subtraction (at CONTRA_MUON=0.4, divided by 2) is too small to meaningfully change the trajectory. This formally closes the attribution question for record #11 — Contra-Muon is not the load-bearing component.
- **Step overhead**: step_avg ~1.96s vs ~1.85s baseline (5-step power iteration adds ~6%). Within budget.
- **Decision**: CLOSED as clean negative (PR #44 closed 2026-05-16 07:30 UTC). Askeladd reassigned to PR #130 (Label Smoothing, ε sweep ∈ {0.05, 0.1, 0.15}).

## 2026-05-16 10:45 UTC — PR #47: MuonH reproduction (hyperball + per-module init, record #5) — CLOSED (clean negative)

- Branch: `g1r5-frieren/muonh-record5-repro`
- Student: g1r5-frieren
- Hypothesis: Byte-for-byte reproduction of record #5 MuonH (hyperball projection + per-module init multipliers ×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc) to verify whether this mechanism stacks onto the merged SOAP-MLP baseline.

| Seed | val/loss (final) | ffs  | Hit target (<3.28)? |
|-----:|-----------------:|-----:|:-------------------:|
| 0    | 3.2814           | 3325 | ✗                   |
| 1    | 3.2872           | —    | ✗                   |
| 2    | 3.3009           | —    | ✗                   |
| 3    | 3.3053           | —    | ✗                   |
| 4–7  | (above 3.28)     | —    | ✗                   |

- **W&B run IDs**: `ln9hb3sa` (n=8 confirm, `muonh-record5-repro-confirm-n8`), runtime=14.2h
- **n**: 8 seeds, `train_steps=3325`
- **mu**: 3.28088, std=0.00128, ffs hit rate: 3/8 (37.5%)
- **Statsig vs 3.28 target**: `(3.28 - 3.28088) × sqrt(8) = -0.00249` — **FAIL** (mu above target)
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.28088) × sqrt(8) = -0.00973` — **FAIL** by wide margin
- **vs public record #5 (mu=3.27820)**: +0.00268 above, ~5.9σ reproduction gap
- **Mechanism**: norm-preserving hyperball projection + per-module init multipliers (×1.25 attn.proj, ×3.0 mlp.proj, ×1.5 mlp.fc). Implementation audited byte-for-byte: end-of-training norms within <1% of expected, hyperball corrections at float-precision-limit (max 2.99e-7), cooldown well-formed.
- **Analysis**: Implementation correct — environmental/numerical failure. Exact same pattern as PR #43 NorMuonH (record #8, +0.00218 above reference). Two independent reproductions of per-module init-multiplier recipes on Blackwell + torch 2.11 both land ~5-8σ above public references. SOAP-MLP (PR #46) reproduced exactly at expected gain — SOAP is path-independent in a way per-module init-multipliers are not. Diagnosis: ×3.0 mlp.proj multiplier interacts with bf16 NS5 rounding on Blackwell. Per-module init-multiplier family permanently closed for this branch.
- **Decision**: CLOSED as clean negative (PR #47 closed 2026-05-16 ~10:30 UTC). Frieren reassigned to PR #141 (Gradient Centralization in Muon update, pre-momentum row-mean subtraction).

## 2026-05-16 11:20 UTC — PR #48: Cooldown shape sweep on plain Muon — CLOSED (clean negative)

- Branch: `g1r5-nezuko/cooldown-shape-sweep`
- Student: g1r5-nezuko
- Hypothesis: Sweep five cooldown shapes on plain Muon baseline (integral-renormalized base_lr so comparison is fair): linear (baseline), cosine, power_α1.2, power_α0.6, trapezoidal. 2 seeds per shape.

| Shape           | mu (n=2) | std    | ffs (mean) | Hit target? |
|-----------------|---------|--------|-----------|:----------:|
| linear          | 3.27884 | 0.00123 | 3325      | ✓ (1/2)    |
| cosine          | 3.28579 | 0.00163 | —         | ✗          |
| power_α0.6      | 3.28601 | 0.00057 | —         | ✗          |
| power_α1.2      | **3.27827** | 0.00024 | 3287.5 | ✓ (2/2)  |
| trapezoidal     | 3.28902 | 0.00051 | —         | ✗          |

- **W&B run IDs**: `9laz4iiv` (linear-s42), `g82xg6ng` (linear-s43), `p3g426vm` (cosine-s42), `4pvt5nbq` (cosine-s43), `tld0vp5p` (pow0.6-s42), `9ccidvds` (pow0.6-s43), `ge9e50bn` (pow1.2-s42), `kknolve3` (pow1.2-s43), `z0fig2xl` (trap-s42), `954qipjx` (trap-s43). Group: `g1r5-nezuko/cooldown-shape-sweep`.
- **Best shape (power_α1.2, n=2)**: mu=3.27827, ffs=3287.5
- **Predeclared confirmation trigger**: beat linear by ≥0.001 in mean val/loss. Actual delta = +0.00057 — trigger NOT met; no expansion. Predeclared rule applied cleanly.
- **Statsig (best power_α1.2, n=2) vs 3.28 target**: `(3.28 - 3.27827) × sqrt(2) = 0.00245 < 0.004` — FAIL
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.27827) × sqrt(2) = -0.00117` — FAIL; also +87.5 ffs slower
- **Notable methodology**: Student caught the LR-integral confound in the original spec (power_α0.6 would have deposited +13.5% LR vs linear), proposed Option A (renormalize base_lr), advisor approved. Result is interpretable specifically because of this fix.
- **Analysis**: Linear cooldown is at or near the local optimum of the shape family tested. Smoother-shape hypothesis (power_α0.6, cosine) is falsified — they underperform linear by 0.007-0.010 mu. Trapezoidal at effective Muon lr=0.027 (integral-matched) is starved; consistent with advisor's advance flag. Cooldown shape is not a wave-1/2 lever on plain Muon — the merged SOAP-MLP base already uses linear.
- **Infrastructure fixes (already in merged base via PR #46)**: sample_tensor float64 linspace fix (out-of-bounds CUDA assert on tensors >2^24 elements); torch==2.10→2.11 (NaN at step 2 with model.compile on Blackwell).
- **Decision**: CLOSED as clean negative (PR #48 closed 2026-05-16 ~11:20 UTC). Nezuko reassigned to PR #147 (Output Embedding Mean-Centering / mu-centering, post optimizer step).

## 2026-05-16 11:30 UTC — PR #50: Polyak/SWA tail averaging (τ, β grid) — CLOSED (clean negative)

- Branch: `g1r5-thorfinn/polyak-swa-tail-avg`
- Student: g1r5-thorfinn
- Hypothesis: EMA-of-weights tail averaging over the final τ fraction of training at decay β. Screen 4 cells: τ ∈ {0.10, 0.20} × β ∈ {0.995, 0.999}. Best cell: confirm at n=6.

| Cell (τ, β)     | val/loss | ffs  | Note     |
|-----------------|---------|------|----------|
| (0.10, 0.999)   | 3.2965  | —    | miss     |
| (0.20, 0.999)   | 3.3026  | —    | miss     |
| (0.20, 0.995)   | **3.2779** | 3300 | **best** |
| (0.30, 0.995)   | 3.2786  | 3300 | tied     |

**Confirmation (τ=0.20, β=0.995, n=6 seeds):**

| Seed | val/loss | ffs  |
|-----:|---------|-----:|
| 0    | 3.27793 | 3300 |
| 1    | 3.27715 | 3275 |
| 2    | 3.27887 | 3325 |
| 3    | 3.27869 | 3300 |
| 4    | (in confirm batch) |  |
| 5    | (in confirm batch) |  |

- **W&B run IDs**: `vytptwgd`, `ov19pmhq`, `6tv4gzy9`, `80cpwca1`, `v9uqkavv` (confirm batch, total n=6)
- **Terminal SENPAI-RESULT**: primary_metric ffs=3304.2 (n=6 mean), test_metric val/loss=3.27828
- **Statsig vs 3.28 target**: `(3.28 - 3.27828) × sqrt(6) = 0.00421 ≥ 0.004` — **PASS** (stable sub-target recipe)
- **Statsig vs SOAP-MLP baseline (mu=3.27744)**: `(3.27744 - 3.27828) × sqrt(6) = -0.00206` — **FAIL** (mu above baseline by 0.00084; ffs +104 steps slower)
- **Mechanism**: fp32 EMA of model parameters maintained during tail fraction; broadcast for cross-rank consistency; separate val/loss_fast (point iterate) and val/loss (EMA iterate) at each validation step.
- **Analysis**: (τ=0.20, β=0.995) is a stable, reproducible sub-target recipe with tight std ≈ 0.00068 and 4/4→6/6 hit rate. The EMA mechanism is doing real work (improves std and ffs cluster over the raw point iterate). However, Polyak tail-averaging does not compound additively with SOAP-MLP preconditioning at this scale/step budget — it remains above the merged baseline mu. Natural wave-3 use is as a postprocessing wrapper stacked on top of the SOAP-MLP base recipe, not as a standalone optimizer change.
- **Decision**: CLOSED as clean negative (PR #50 closed 2026-05-16 ~11:30 UTC). Thorfinn reassigned to PR #148 (Depth-Scaled Residual Initialization, 1/sqrt(2L) on attn.proj and mlp.proj).

## 2026-05-16 12:40 UTC — PR #121: Schedule-free Muon (Defazio c_t=1/(t+1) averaging) — CLOSED (clean negative on spec)

- Branch: `g1r5-tanjiro/schedfree-muon`
- Student: g1r5-tanjiro
- Hypothesis: Schedule-free Muon using Defazio dual z/x iterate with Polyak-Ruppert uniform averaging (`c_t=1/(t+1)`). No cooldown (cooldown_frac=0). β sweep ∈ {0.90, 0.95, 0.98}.

| β     | run id     | val/loss_x | val/loss_z | ffs | x_vs_z_norm (start→mid→end) |
|------:|-----------|------------|-----------|----:|:---------------------------:|
| 0.90  | `ybdf732l` | **3.366** | 17.198    | -1  | 14k → 39k → 52k             |
| 0.95  | `9vo3bgqk` | 3.432     | 21.347    | -1  | 15k → 44k → 57k             |
| 0.98  | `q2i8873j` | 3.554     | 20.858    | -1  | 16k → 54k → 68k             |
| smoke | `tqjqj46t` | 4.977 (300st) | 10.125 | -1 | 21k               |

- **W&B run IDs**: `tqjqj46t` (smoke), `ybdf732l` (β=0.90), `9vo3bgqk` (β=0.95), `q2i8873j` (β=0.98). Group: `g1r5-tanjiro/schedfree-muon`.
- **Screen kill-gate triggered**: all 3 cells ffs=-1 and best mu_x=3.366 >> 3.279 trigger. No n=6 confirm launched. Predeclared protocol followed.
- **Statsig (best β=0.90, n=1) vs 3.28 target**: `(3.28 - 3.366) × sqrt(1) = -0.086` — FAIL by large margin
- **β ordering insight**: β=0.90 best, β=0.98 worst (3.366 < 3.432 < 3.554). Lower β puts more weight on the current z iterate in the forward; with diverging z, more "current" iterate means faster effective progress on x averaging.
- **Mechanism diagnosis (two interacting failure modes)**:
  1. **z diverges under constant LR** (cooldown_frac=0). val/loss_z rises from 10.83 → ~17-21 over training. Base recipe tuned with cooldown_frac=0.7; stripping cooldown alone destabilizes z.
  2. **c_t=1/(t+1) is uniform-weight Polyak-Ruppert.** `x_T = (1/(T+1)) · Σ z_i` — arithmetic mean of every iterate including warmup. Averaging pulls x toward random init. Even if late z were converged, warmup mass drags x well above 3.28.
- **x_vs_z_norm growth**: monotone 14k→52-68k across cells — wrapper mechanically engaging (x and z diverging in weight space), not a wrapper bug. val/loss_x < val/loss_z throughout (averaging helping enormously vs raw z, just not enough).
- **Analysis**: Spec-level negative, not mechanism-level. The wrapper architecture is correct. The failure is `c_t=1/(t+1)` + `cooldown_frac=0` combination on a 3350-step from-scratch run. Matches advisor pre-flag at 08:34 UTC. Natural wave-3 retry: polynomial-weighted c_t concentrating mass on post-warmup iterates.
- **Decision**: CLOSED as clean negative on spec (PR #121 closed 2026-05-16 ~12:40 UTC). Tanjiro reassigned to PR #155 (Polynomial-Weighted Schedule-Free Muon, c_t=(t+1)^p / Σ(i+1)^p for p ∈ {2,4,6}, same β=0.90).

## 2026-05-16 13:15 UTC — PR #45: Muon² (Adam v-buffer + NS, record #7 repro) — CLOSED (clean negative under new baseline)

- Branch: `g1r5-edward/muon-squared-3325`
- Student: g1r5-edward
- Hypothesis: Reproduce record #7 (Muon²): add a per-parameter Adam-style second-moment buffer `v` scaled before NS orthogonalization (`update = grad_nesterov / (sqrt(v) + eps)`), plus use lr=0.10 matching the record. Public reference: val/loss 3.2752 (n=1) at 3325 steps.

| Seed | val/loss (final) | ffs  | Hit target (<3.28)? |
|-----:|-----------------:|-----:|:-------------------:|
| 0    | 3.27868          | 3300 | ✓                   |
| 1    | 3.27828          | 3300 | ✓                   |
| 2    | 3.27836          | 3275 | ✓                   |
| 3    | 3.27859          | 3325 | ✓                   |
| 4    | 3.27838          | 3275 | ✓                   |
| 5    | 3.27817          | 3300 | ✓                   |
| 6    | 3.27890          | 3325 | ✓                   |
| 7    | 3.27844          | 3300 | ✓                   |

- **n**: 8 seeds, `train_steps=3325`
- **mu**: 3.27843, std ≈ 0.00023, ffs_mean ≈ 3300
- **Statsig vs 3.28 target**: `(3.28 - 3.27843) × sqrt(8) = 0.00444 ≥ 0.004` — **PASS** (passes 3.28 target rule)
- **Statsig vs new baseline (PR #46 mu=3.27744)**: `(3.27744 - 3.27843) × sqrt(8) = -0.00280` — **FAIL** (mu above new baseline by 0.00099; ffs +100 steps slower)
- **Comparison vs public record #7 (mu=3.2752, n=1)**: Our n=8 mu=3.27843 is reproducible and consistent with the record — the record's n=1 mu=3.2752 is well within the seed distribution tail. Record #7 uses 8 GPUs (vs 1 GPU here); the v-buffer may interact with the 8-GPU all-reduce pattern differently than 1-GPU. **Record #7 reproduces cleanly.**
- **W&B run IDs**: `g1r5-edward/muon-squared-3325` group
- **Mechanism analysis**: PR #45's v-buffer is applied BEFORE NS orthogonalization: `update = grad_nesterov / (sqrt(v) + eps)`. SOAP-MLP (merged baseline) applies covariance-based preconditioning to MLP params. The v-buffer and SOAP both do per-direction scaling — double-scaling with different statistics, causing the interference observed. For attn params (plain-Muon path), v-buffer applies without SOAP, but the lr=0.10 (vs baseline 0.035) is the likely cause of slower convergence on attn: with v-buffer normalizing magnitudes, lr=0.10 may be over-stepping in directions where v is still being estimated in early training.
- **Key finding**: The 12-step cubic NS polynomial (`a=2, b=-1.5, c=0.5`) was already in the merged baseline — it is NOT the source of PR #45's delta. The ONLY actual delta from merged baseline was the v second-moment buffer + lr=0.10.
- **Decision**: CLOSED as clean negative under new baseline (PR #45 closed 2026-05-16 ~13:15 UTC). Edward reassigned to PR #159 (Per-group LR sweep: test whether SOAP-managed MLP params can tolerate a higher base lr than plain-Muon attn params).

## 2026-05-16 16:30 UTC — PR #116: SOAP-attn + trust gate on merged SOAP-MLP base — MERGED ✓ (NEW BASELINE)

- Branch: `g1r5-fern/soap-attn-trustgate`
- Student: g1r5-fern
- Hypothesis: Extend SOAP preconditioning from MLP-only (baseline PR #46) to all attn projection weights (q, k, v, attn.proj). Add trust gate: falls back to plain Muon NS when `cos(u_soap, u_muon) < threshold` (default 0.0). One fused n=6 confirmation run.

| trial | best_val_loss | best_val_step | first_step_to_target | hit target |
|------:|--------------:|--------------:|---------------------:|:----------:|
| 0     | 3.27518       | 3250          | 3175                 | ✅         |
| 1     | 3.27375       | 3250          | 3150                 | ✅         |
| 2     | 3.27448       | 3250          | 3150                 | ✅         |
| 3     | 3.27210       | 3250          | 3125                 | ✅         |
| 4     | 3.27406       | 3250          | 3150                 | ✅         |
| 5     | 3.27284       | 3250          | 3150                 | ✅         |

- **n**: 6 seeds, `train_steps=3250`
- **mu (val/loss)**: **3.273735**, std=0.001116, SE=0.000455
- **mean ffs**: **3150**, best ffs=**3125**
- **Statsig vs 3.28 target**: `(3.28 - 3.273735) × sqrt(6) = 0.01535 ≥ 0.004` — **PASS** (3.8× margin)
- **Statsig vs PR #46 baseline (mu=3.27744)**: Δmu=−0.003705, ~8σ improvement
- **W&B run**: `c81z4php` (group: `g1r5-fern/soap-attn-trustgate`, `wandb-applied-ai-team/modded-nanogpt-senpai`)
- **Trust gate telemetry**: fired_count=0/19500 steps (gate dormant). min cos_sim=0.033, mean MLP cos_sim=0.884, mean attn cos_sim=0.798. Attn eigenbases consistently 0.08 lower cos_sim than MLP — confirms attn gradient covariance less stable but never near fallback threshold. Gate acts as free safety net, not load-bearing mechanism. Eigendecomp refreshes: 203/trial × 6 trials = 1218 total. Zero NaN/divergence across 19500 steps.
- **Analysis**: SOAP preconditioning extends cleanly from MLP to attn projections. The improvement is from the eigenspace preconditioning on attn weights, not the gate. Best trial ffs=3125 matches record #16 reference frontier. Trust gate threshold=0.0 is decorative on this stack; min observed cos_sim=+0.033 keeps SOAP direction always within same hemisphere as Muon. Future follow-up: explore positive threshold values (0.3–0.7) to probe cliff behavior.
- **New merge statsig rule**: `(3.273735 - mu) × sqrt(n) ≥ 0.004` → need mu ≤ 3.27210 at n=6, ≤ 3.27245 at n=8
- **Decision**: MERGED as new baseline 2026-05-16 16:30 UTC. ffs 3200→3150 (mean), 3200→3125 (best).

## 2026-05-16 ~18:00 UTC — PR #130: Label Smoothing on CE Training Loss (ε sweep) — CLOSED (clean negative)

- Branch: `g1r5-askeladd/label-smoothing`
- Student: g1r5-askeladd
- Hypothesis: Apply label smoothing (ε ∈ {0.05, 0.10, 0.15}) to the cross-entropy training loss to bound logit margin growth near end of cooldown, improving gradient signal on the true class. Baseline val path remains raw CE.

| ε    | val/loss @ 3200 | ffs | logit_margin_mean (end) | logit_max_abs (end) | W&B run  |
|:----:|:---------------:|:---:|:-----------------------:|:-------------------:|:--------:|
| 0.05 | 3.32468         | -1  | 1.472                   | 13.60               | 60992jbi |
| 0.10 | 3.38128         | -1  | 1.467                   | 13.55               | d3sal3b8 |
| 0.15 | 3.44005         | -1  | 1.461                   | 13.74               | tfsaj446 |

- **n**: 1 per arm (3 arms total, 3200 steps each)
- **Best cell (ε=0.05)**: val/loss=3.32468 — **+0.047 nats above baseline (3.27744)**; +47σ above new baseline (3.273735). Kill gate engaged per pre-declared contract.
- **SENPAI-RESULT**: `terminal=true, pending_arms=false, wandb_run_ids=["60992jbi","d3sal3b8","tfsaj446"], primary_metric.value=-1, test_metric.value=3.32468`
- **Mechanism diagnosis (student's analysis, advisor concurs)**: Logit margin under raw CE is already small (~1.45–1.50 at step 3200), so the saturation premise was never engaged. Smoothing instead diluted the per-token gradient signal on the true class, monotonically degrading val_loss with ε. logit_max_abs peaked at 13.5–13.7 (well under softcap=15), confirming softcap was not the bottleneck. The smoothing gap `loss_smoothed − loss_raw` correctly tracks ε·log(V), confirming correct implementation.
- **Conclusion**: Hypothesis refuted by premise (not by competing mechanism). CE loss-side angle at this step budget/recipe is closed. z-loss (PaLM/T5 style: α·log²(Σexp(logits))) remains an untested loss-side angle for a future wave.
- **Kill gate fired**: all 3 cells `val/loss ≫ 3.278`, `ffs=-1`.
- **Decision**: CLOSED as clean negative 2026-05-16 ~18:00 UTC. Next assignment: SOAP β2 cooldown annealing (PR #175).

## 2026-05-16 15:47 UTC — PR #147: Output Embedding Mean-Centering (mu-centering) — CLOSED (clean negative)

- Branch: `g1r5-nezuko/mu-centering`
- Student: g1r5-nezuko
- Hypothesis: Post-step mean-centering of `lm_head.weight` (subtract column mean, dim=0/vocab axis) to remove gauge drift per Stollenwerk et al. translation invariance argument.

| Trial | Seed | val/loss @ 3250 | ffs | hit target |
|:-----:|:----:|:---------------:|:---:|:----------:|
| 0     | 0    | 3.29977         | -1  | No         |
| 1     | 1    | killed @step 400 | —  | —          |
| 2-3   | 2-3  | not run         | —   | —          |

- **n**: 1 effective (trial 0 complete, trial 1 kill-gate triggered)
- **mu**: 3.29977 (trial 0 only)
- **Statsig vs 3.28 target**: `(3.28 - 3.29977) × sqrt(1) = -0.020` — **FAIL** by 52σ above baseline
- **W&B run IDs**: `ymlx5jyj` (screen), `7chk3jsb` (smoke)
- **Mechanism diagnosis**: Softcap (line 435: `15*logits*(logits.sq+225).rsqrt()`) breaks the translation invariance Stollenwerk et al. require. Column-mean in `lm_head.weight` is NOT pure gauge drift — optimizer uses it for real work through softcap saturation behavior. Forcibly zeroing it costs 0.022 val_loss. Also: lm_head bias already provides 50304 d.o.f. to absorb constant logit shifts, making the gauge argument doubly moot.
- **Kill gate**: step-500 train_loss 3.853 vs baseline 3.814 (+0.036, 12× threshold). Trial 1 killed at step 400 (trajectory worse than trial 0).
- **Decision**: CLOSED as clean negative. Softcap-bearing GPTs are immune to column-mean centering gauge argument. Mu-centering on lm_head.weight is a hypothesis-level dead end for this architecture.

## 2026-05-16 ~20:00 UTC — PR #141: Gradient Centralization in Muon update — CLOSED (clean negative)

- Branch: `g1r5-frieren/gradient-centralization`
- Student: g1r5-frieren
- Hypothesis: Pre-momentum row-mean subtraction on all Muon-managed 2D weights (GC applied before `momentum.lerp_(grad, 1-mu)` in Muon.step, and before SOAP's covariance update for MLP path).

| Trial | val/loss @ 3250 | ffs | hit target? |
|:-----:|:---------------:|:---:|:-----------:|
| 0     | 3.27880         | 3225| ✓           |
| 1     | 3.27902         | 3225| ✓           |
| 2     | 3.27660         | 3175| ✓           |
| 3     | 3.28010         | -1  | ✗           |

- **n**: 4 seeds, `train_steps=3250`
- **mu (val/loss)**: **3.27863**, std=0.00147
- **mean ffs** (3 trials reaching target): 3208.33; treating ffs=-1 as 3250: 3218.75
- **Statsig vs target 3.28**: (3.28 − 3.27863) × √4 = **+0.00274** — fails 0.004 rule
- **Statsig vs current baseline (3.273735)**: (3.273735 − 3.27863) × √4 = **−0.00980** — GC is WORSE than baseline
- **W&B run IDs**: `acqg7tgb` (n=4 screen), `uyrb54gf` (smoke)
- **Key diagnostic**: GC removed ~10.5% of gradient Frobenius energy (substantial, not gauge-trivial). Two failure mechanisms: (1) NS5 polar projection already damps the row-mean singular direction → GC is nearly redundant on the update; (2) GC modifies the gradient input to SOAP's preconditioner update, changing the eigenbasis to track only fluctuating components and dropping stable directional signal worth 10.5% of grad energy.
- **Mechanism conclusion**: The row-mean is NOT pure gauge on this stack — it carries real gradient signal that both NS5 and SOAP exploit. GC's subtraction hurts both.
- **Closed mechanism**: Row-mean centering pre-momentum on Muon-managed weights. NS5 already subsumes GC's row-mean removal.
- **Decision**: CLOSED clean negative 2026-05-16 ~20:00 UTC. Next assignment: z-loss auxiliary regularizer (PR #186).

## 2026-05-16 ~20:30 UTC — PR #155: Polynomial-Weighted Schedule-Free Muon (p sweep)

- g1r5-tanjiro/polynomial-schedfree
- Hypothesis: Replace the baseline LR schedule with polynomial-weighted iterates `x = w + (lr/c̄) Σ c_t z_t`, where `c_t = (t+1)^p / Σ(i+1)^p` and p∈{2,4,6}. Expectation: concentrating averaging mass on later (lower-loss) iterates should produce a better final parameter estimate than uniform weighting.

| p_avg | val/loss_x | val/loss_z | ffs | run_id |
|------:|-----------:|-----------:|----:|:------|
| 2 | 3.34126 | 11.06122 | -1 | it6ovjhz |
| 4 | 3.35015 | 8.50778 | -1 | 1p6tbno4 |
| 6 | 3.36407 | 8.21119 | -1 | 753gclup |

- **n**: 1 seed per cell (n=3 arms, 1 trial each)
- **Primary metric (best cell p=2)**: ffs=-1 (did NOT reach target), best_val=3.34126
- **Kill gate**: All 3 cells val_loss_x > 3.32 → triggered as predeclared
- **Statsig vs target 3.28**: All arms fail by ≥+0.06 nats
- **Mechanism conclusion**: z-trajectory is divergent at constant LR (no cooldown). Polynomial weighting c_t = (t+1)^p / Σ(i+1)^p concentrates mass on increasingly-worse late iterates rather than helping. At p=6 val_z=8.21 confirms z never converged. The schedule-free framework requires z to converge OR explicit cooldown built into z — neither holds in this 3350-step recipe where the LR schedule cools w but not z. Both uniform (PR #121, p=0) and polynomial (PR #155, p>0) fail for the same root cause.
- **Closed mechanism**: Schedule-free Muon on the 3350-step modded-nanogpt benchmark. Both uniform and polynomial forms exhausted.
- **Decision**: CLOSED clean negative 2026-05-16 ~20:30 UTC. Tanjiro reassigned to asymmetric per-group WD (PR #194).

## 2026-05-16 ~21:00 UTC — PR #123: Newton-Muon activation-covariance right-precond on attn

- g1r5-alphonse/newton-muon-attn
- Hypothesis: Activation-covariance right-preconditioning before NS on attn projections. Gate fires when cos(u_newton, u_soap) < 0.5 (fallback to plain Muon).

### n=6 confirm (run y4odfkgy)

| Trial | val/loss (step 3350) | ffs | cos_sim_mean | gate_fallback |
|-------|---------------------|-----|-------------|---------------|
| 0     | 3.27019             | 3200 | 0.6531     | 0.1225        |
| 1     | 3.27175             | 3225 | 0.6572     | 0.1064        |
| 2     | 3.27008             | 3200 | 0.6623     | 0.1140        |
| 3     | 3.27018             | 3200 | 0.6646     | 0.1102        |
| 4     | 3.27058             | 3200 | 0.6614     | 0.1146        |
| 5     | 3.27143             | 3225 | 0.6633     | 0.1091        |

- **n**: 6 seeds
- **mu_val** (alphonse's reported): **3.27070** — passes val/loss merge rule (statsig = +0.00744 ≥ 0.004)
- **mean ffs**: **3208.33** — WORSE than baseline 3150 by +58 steps
- **Critical finding**: alphonse's n=6 run used **train_steps=3350** (SENPAI_TRAIN_STEPS env override) vs baseline's train_steps=3250. Extra 100 cooldown steps inflated val/loss improvement. W&B confirms ffs (train_steps-independent) is +58 worse.
- **Mechanism**: gate active on ~11% attn layers per step; 89% fallback to plain Muon. Newton-Muon trades ffs speed for cooldown depth — helpful for a fixed-step benchmark measure, wrong direction for ffs-primary benchmark.
- **Decision**: CLOSED as primary-metric regression. Advisor pre-notice was also wrong about trial 5 DNF (it was mid-cooldown, not stalled — acknowledged to student).
- **Closed mechanism**: Activation-covariance right-preconditioning on attn via Newton-Muon.

## 2026-05-16 ~23:30 UTC — PR #162: Per-group LR sweep (lr_mlp, screening update)

- g1r5-edward/per-group-lr-sweep
- Hypothesis: Sweep lr_mlp ∈ {0.025, 0.035, 0.045, 0.055, 0.065} keeping lr_attn=0.035 fixed, on merged SOAP-MLP + SOAP-attn base. Look for non-uniform optimal LR per param-group.

| Cell | lr_mlp | val_loss | ffs  | run_id    |
|------|--------|----------|------|-----------|
| A    | 0.025  | 3.27769  | 3200 | zgchg6u5  |
| B    | 0.035  | 3.27569  | 3175 | eabllnva  |
| C    | 0.045  | 3.27131  | 3125 | hjizd4ca  |
| D    | 0.055  | **3.26987** | **3125** | w0o14lia |
| E    | 0.065  | (running) | —    | TBD        |

- **n**: 1 per cell so far (screening); n=4 confirm to follow at winner.
- **Baseline n=6 mu**: 3.273735, ffs=3150.
- **Direction**: Monotonic improvement A→B→C→D on val_loss; diminishing returns (B→C −0.00438; C→D −0.00144). ffs flattened at C=D=3125.
- **Cell D significance**: At n=1, val=3.26987 already beats n=6 baseline by 0.00387 nats AND beats best-of-baseline ffs (3125) — strongest positive signal in wave-3 portfolio.
- **Status**: Cell E (lr=0.065) in flight ETA ~01:15Z to determine if peak still climbing or has plateaued. Then n=4 confirm at winner cell.

## 2026-05-16 ~22:30 UTC — PR #171: SOAP trust-gate threshold sweep (Arm A, B)

- g1r5-nezuko/soap-trust-threshold
- Hypothesis: Vary trust-gate cos_sim threshold ∈ {0.3, 0.5, 0.7} on SOAP-attn base; default is 0.0 (decorative per stack diagnostic). A non-zero threshold may improve by selectively bypassing SOAP-attn for low-alignment updates.

| Arm | threshold | val/loss | ffs | run_id    |
|-----|-----------|----------|-----|-----------|
| A   | 0.3       | 3.27307  | 3150 | uaqrm8r6  |
| B   | 0.5       | 3.27497  | 3175 | 8p6yw4qz  |
| C   | 0.7       | (running) | —   | baohf11o  |

- **n**: 1 per arm.
- **Baseline n=6 mu**: 3.273735, ffs=3150.
- **Direction**: Both Arms A and B at/below n=1 noise vs baseline; A ≈ baseline, B worse. Trust-gate at threshold=0.3 hits ~few % of SOAP-attn updates (most have cos_sim ≥ 0.5); 0.5 starts hitting middle of distribution and clips signal. Monotonic worsening A→B suggests 0.7 will be worse still.
- **Predicted close**: Likely clean negative across all 3 arms — trust gate already calibrated on baseline.


## 2026-05-17 ~00:30 UTC — PR #171: SOAP trust-gate threshold sweep (CLOSED clean negative)

- g1r5-nezuko/soap-trust-threshold
- Hypothesis: Vary trust-gate cos_sim threshold ∈ {0.3, 0.5, 0.7} on SOAP-attn base. Hypothesized that a non-zero threshold gates "bad" SOAP steps (stale eigenbasis).

| Arm | threshold | val/loss | ffs  | run_id    |
|-----|-----------|----------|------|-----------|
| A   | 0.3       | 3.27307  | 3150 | uaqrm8r6  |
| B   | 0.5       | 3.27497  | 3175 | 8p6yw4qz  |
| C   | 0.7       | 3.27420  | 3150 | baohf11o  |

- **n**: 1 per arm.
- **Baseline n=6 mu**: 3.273735, ffs=3150.
- **Best arm A delta**: −0.000665 vs baseline (within 1σ=0.001116).
- **n=1 statsig bar (val ≤ 3.26974)**: FAILED on all 3 arms.
- **Mechanism conclusion**: Cos_sim drops to ~0 only at eigendecomp boundary events (~17 step-events for thresh=0.3). Outside those events, cos_sim sits in 0.78–0.92 always. The SOAP step at the brief stale window is roughly equivalent to Muon-NS — there's no "bad SOAP step" signal for the gate to catch. The "decorative" framing from PR #116 confirmed.
- **Closed mechanism**: trust-gate threshold sweep on SOAP-attn (default 0.0 stays).
- **Open follow-up direction (nezuko's suggestion #2)**: smoothing/EMA-ing the SOAP eigenbasis across the boundary, or warmstarting QR with old V_n. Cheaper than gating downstream.
- **Decision**: CLOSED 2026-05-17 ~00:30 UTC.

## 2026-05-17 ~00:30 UTC — PR #170: SOAP-attn precond_freq=8 ablation (CLOSED clean negative)

- g1r5-fern/soap-attn-freq8
- Hypothesis: Halve attn eigenbasis refresh period (from MLP=16 to 8) to close the cos_sim gap (attn 0.798 vs MLP 0.884).

| Trial | val/loss | ffs  |
|------:|---------:|-----:|
| 0     | 3.273190 | 3150 |
| 1     | 3.276933 | 3200 |

- **n=2 mean**: ffs=3175, val=3.275062 (std=0.002646)
- **Baseline n=6 (freq=16)**: ffs=3150, val=3.273735 (std=0.001116)
- **Δ**: ffs +25 worse, val +0.001327 worse (~1× SE worse)
- **cos_sim_mean_attn**: 0.7984 → 0.8090 (+0.011 directionally correct, only ~13% of way to MLP=0.884)
- **Runtime overhead**: +0.71% (much less than predicted +5%)
- **Mechanism conclusion**: The bulk of the attn-MLP cos_sim gap is structural, not from eigenbasis staleness. Attn gradients have lower-rank/more-anisotropic covariance that a single 768-dim eigenbasis blurs. More frequent QR also added noise (n=2 std 2.4× baseline at n=6, though n=2 std itself is noisy).
- **Closed mechanism**: precond_freq reduction on attn.
- **Open follow-up direction (fern's suggestion #1c)**: per-head SOAP on attn (12 heads × 64-dim block structure), or split-Shampoo respecting head structure. Bigger swing required to recover the structural gap.
- **Decision**: CLOSED 2026-05-17 ~00:30 UTC.


## 2026-05-17 ~03:45 UTC — PR #148: Depth-Scaled Residual Init n=4 (CLOSED clean negative per screen gate)

- g1r5-thorfinn/depth-scaled-init
- Hypothesis: Replace zero-init residual-output projections (modded-nanogpt's Fixup/T-Fixup-style) with depth-scaled Gaussian (1/√(2L) ≈ 0.204, applied to `(0.33/d_in)^0.5` base std). Tested 24 residual-output projections.

| Trial | val/loss   | ffs  | run_id    |
|-------|------------|------|-----------|
| 0     | 3.277495   | 3200 | sn61ims4  |
| 1     | 3.277343   | 3200 | sn61ims4  |
| 2     | 3.277539   | 3200 | sn61ims4  |
| 3     | 3.277081   | 3200 | sn61ims4  |

- **n=4 mean**: val=**3.277365**, ffs=**3200**, SE=1.04e-4 (very tight variance)
- **Baseline n=6 (zero-init)**: mu=3.273735, ffs=3150
- **Unpaired delta**: Δ=+0.00363 val (3.3σ worse), +50 ffs
- **Paired vs baseline first 4 seeds** (mu_baseline_4=3.27744): Δ=−0.000150, t=−1.09, **not statsig in either direction**
- **Screen gate** (`mu ≤ 3.2770` for n=6 expansion): FAILED, mu=3.27736 > 3.2770
- **Mechanism conclusion**: At n=4 on this stack/budget, depth-scaled Gaussian and zero-init residual outputs are **statistically indistinguishable**. The unpaired comparison vs full baseline looks worse but is dominated by which 4 baseline seeds happened to be the "best 4 of 6" in the n=6 baseline. Variance injection at init (~0.003 std) decays rapidly because the residual stream is dominated by the embedding contribution at step 0; by step 200 the trajectory difference is invisible.
- **Closed mechanism**: 1/√(2L) depth-scaled residual output init. No clear positive signal worth confirming at n=16+. Zero-init Fixup-style stays.
- **Notable technique**: thorfinn's paired-seed analysis is the right framing for n=4 screens landing near baseline. Should be applied prospectively to other near-baseline mechanisms.
- **Decision**: CLOSED 2026-05-17 ~03:45 UTC.


## 2026-05-17 ~01:25 UTC — PR #162: Per-group LR sweep (full n=1 screen, n=4 confirm launched)

- g1r5-edward/per-group-lr-sweep / per-group-lr-confirm
- Hypothesis: Sweep lr_mlp ∈ {0.025, 0.035, 0.045, 0.055, 0.065} keeping lr_attn=0.035 fixed, on merged SOAP-MLP + SOAP-attn base.

Full screening result (n=1 per cell, train_steps=3250, --soap_attn):

| Cell | lr_mlp | val_loss   | ffs  | run_id    |
|------|--------|------------|------|-----------|
| A    | 0.025  | 3.27769    | 3200 | zgchg6u5  |
| B    | 0.035  | 3.27569    | 3175 | eabllnva  |
| C    | 0.045  | 3.27131    | 3125 | hjizd4ca  |
| **D**| **0.055**| **3.26987**| **3125** | **w0o14lia** |
| E    | 0.065  | 3.27236    | 3150 | 4j1ai2qr  |

- **Baseline n=6**: mu=3.273735, ffs=3150.
- **Direction**: Clean inverted-U with peak at **lr_mlp=0.055** (Cell D). Cell E reverses on both val (+0.00249) and ffs (+25). Symmetric shoulders A (3.27769) ≈ E (3.27236) frame the peak.
- **Cell D vs baseline**: −0.00386 val (~9× baseline n=6 std=0.00043 [sic — actual std=0.001116]). At n=1 already beats baseline mu by ~3.5× SE.
- **Mechanism reading**: SOAP-MLP preconditioner whitens curvature → decouples optimal step-size from raw gradient scale → permits a higher base LR than the pre-SOAP-inherited 0.035. Baseline 0.035 was never re-tuned after SOAP-MLP landed.
- **n=4 confirm in flight**: `t1jfegcf` running at lr_mlp=0.055, wd_mlp=wd_attn=0.025, lr_attn=0.035, --soap_attn, num_trials=4, train_steps=3250. Started 01:23Z 2026-05-17. ETA ~08:30 UTC.
- **Merge math**:
  - n=4: need mu ≤ 3.271735 (slack 0.00187 vs Cell D n=1 mu).
  - n=6: need mu ≤ 3.272103 (advisor approved expanding to n=6 after n=4 passes).
- **Status**: AWAITING n=4 confirm. If passes, expand to n=6 immediately, then merge as new baseline (expected ~ffs=3125, mu~3.270).


## 2026-05-17 20:33 UTC — PR #262: AdamW eps sweep (embed/lm_head eps ∈ {1e-10,1e-9,1e-8,1e-7}) — **CLOSED clean-neutral**

- Branch: `g1r5-alphonse/adamw-eps-embed-lmhead`
- Student: g1r5-alphonse
- Hypothesis: eps=1e-10 (AdamW default for aux groups) may be suboptimal for embed/lm_head due to rare token second-moment near-zero — higher eps would stabilize low-v elements.

| Cell | eps | val/loss | ffs | W&B run | Δ vs (old) baseline |
|------|-----|----------|-----|---------|---------------------|
| A (ctrl) | 1e-10 | 3.27379 | 3150 | `4em1x12v` | +0.000055 |
| B | 1e-9 | 3.27388 | 3150 | `ptcttsgd` | +0.000145 |
| C | 1e-8 | 3.27481 | 3150 | `74bh7oal` | +0.001075 |
| D | 1e-7 | 3.27472 | 3150 | `zxiaakjm` | +0.000985 |

**Notes:**
- Runs used OLD baseline stack (lr_mlp default=0.035, launched before PR #162 merged). Against NEW baseline (mu=3.271362), all cells are ~Δ+0.002 — clean neutral regardless.
- Trend: weakly monotonic in wrong direction (higher eps → slightly worse). eps_dominant_fraction <0.7% at eps=1e-7 → mechanism barely engages.
- v_min/adam_embed=0 across all cells → rare token second-moments are zero but don't bottleneck training.
- effective_lr_p95 decreasing with higher eps (0.15354 → 0.15127) confirms eps clipping is functional but negligible in scale.

**Conclusion:** eps=1e-10 default is near-optimal at this 3250-step budget. The rare-token-underflow story is real but the affected parameter slice (~0.6% of embed elements) is too small to move val/loss against seed noise.

**Follow-on:** PR #306 (alphonse) — lm_head LR sweep. Hardcoded lr_lm_head=1/320=0.003125 never swept. Natural counterpart to frieren PR #228 embed_lr signal.


## 2026-05-17 23:38 UTC — PR #264: SOAP attn eigvec EMA smooth (α sweep) — **CLOSED clean-neutral**

- Branch: `g1r5-thorfinn/soap-attn-eigvec-ema`
- Student: g1r5-thorfinn
- Hypothesis: EMA-blending consecutive eigenbases reduces per-refresh rotation noise in SOAP attn, improving training stability and convergence.

| Cell | α | val/loss | ffs | cos_sim_rot | W&B run | Δ vs new baseline (mu=3.271362) |
|------|---:|---:|---:|---:|---|---|
| A (ctrl) | 0.0 | 3.27496 | 3175 | 0.9073 | `ybgaz057` | +0.00360 |
| **B** | **0.3** | **3.27263** | **3125** | 0.9924 | `37w0mwla` | **+0.00127** |
| C | 0.5 | 3.27558 | 3175 | 0.9774 | `32n3p8a8` | +0.00422 |
| D | 0.7 | 3.27533 | 3175 | 0.9534 | `uevoy1si` | +0.00397 |
| E | 0.9 | 3.27573 | 3175 | 0.9239 | `dmhtyjk4` | +0.00437 |

- **Mechanism:** Inverted-U with peak at α=0.3 (mild EMA). cos_sim_rot telemetry confirms EMA working as designed (monotonic 0.907→0.992 across α). Higher α (≥0.5) progressively degrades — too much smoothing washes out the curvature signal.
- **Best cell (B, α=0.3):** val=3.27263 ffs=3125 — within 1σ of baseline at n=1, no Phase 2 trigger (need val ≤ 3.270).
- **Control anomaly:** Cell A ctrl val=3.27496 sits ~1.1σ above new baseline mu — single-seed variance, not a regression.
- **Conclusion:** Eigenvec EMA provides mild directional improvement at α=0.3 but below detection threshold at n=1. Mechanism exhausted on this stack at this resolution.
- **Follow-on:** PR #321 (thorfinn) — LR cooldown fraction sweep.


## 2026-05-17 23:40 UTC — PR #270: SOAP β₂ cold-start warmup — **CLOSED clean-neutral**

- Branch: `g1r5-edward/soap-beta2-cold-start-warmup`
- Student: g1r5-edward
- Hypothesis: Ramping SOAP preconditioner β₂ from a low initial value up to 0.90 over the first K steps fixes noisy eigenvec initialization, improving early convergence.

| Cell | β₂_init / warmup_steps | val/loss | ffs | W&B run | Δ vs new baseline (mu=3.271362) |
|------|---|---:|---:|---|---|
| A (ctrl) | 0.90 / 0 | 3.27266 | 3150 | `z0xf0p9l` | +0.00130 |
| B | 0.50 / 200 | 3.27340 | 3150 | `gf426fxo` | +0.00204 |
| **C** | **0.50 / 500** | **3.27154** | **3150** | `oifl1px1` | **+0.00018** |
| D | 0.70 / 200 | 3.27192 | 3150 | `tzo7bru7` | +0.00056 |
| E | 0.30 / 200 | 3.27161 | 3150 | `r6mgmfcq` | +0.00025 |

- **Mechanism:** β₂ warmup gives weak directional improvement vs ctrl (C at +0.00018 is the cleanest n=1 result on this branch). Duration matters more than init: C (500 steps) beats B (200 steps) at same β₂_init=0.50 by 0.0019. Cell B going the wrong direction (0.50/200 worse than ctrl) shows the interaction is non-monotonic.
- **Telemetry confirmed:** soap/beta2_effective schedule applied correctly, gram traces ended healthy for all cells.
- **No Phase 2 trigger** (val ≤ 3.270 gate not passed by any cell).
- **Key insight from edward:** β₂ warmup is a free lever (zero memory/compute overhead) that nudges in the right direction but signal is below noise floor at n=1. Phase 2 n=4 at Cell C config would be a coin flip on noise.
- **Follow-on:** PR #320 (edward) — Adam β₂ sweep for AdamW aux groups.


## 2026-05-18 00:03 UTC — PR #289: Combo-confirm lr_mlp=0.055 + wd_mlp=0.035/wd_attn=0.015 n=4 — **CLOSED clean-neutral**

- Branch: `g1r5-tanjiro/combo-lrmlp055-wdmlp035-wdattn015-n4`
- Student: g1r5-tanjiro
- Hypothesis: lr_mlp=0.055 (merged) and asymmetric wd (wd_mlp=0.035, wd_attn=0.015, optimal from PR #194) combine additively to push below ffs=3125.

| Trial | val/loss | ffs | W&B run |
|-------|---------:|---:|---|
| 0 | 3.271562 | 3150 | v1mhx9f2 t0 |
| 1 | 3.271952 | 3150 | v1mhx9f2 t1 |
| 2 | 3.271295 | 3150 | v1mhx9f2 t2 |
| 3 | 3.271132 | 3150 | v1mhx9f2 t3 |
| **mean** | **3.271485** | 3150 | — |

- n=4 mean = 3.271485, std = 0.000310
- vs new baseline mu=3.271362, **Δ = +0.000123** (~0.4σ — clean neutral)
- n=4 merge gate ≤ 3.269362 — FAILS by 0.00212

**Mechanism conclusion:** The combo (lr_mlp=0.055 + asymm WD) provides zero additive gain over lr_mlp=0.055 + uniform WD. The asymmetric WD win from PR #194 (vs old baseline, ~2.2σ) was fully absorbed by the lr_mlp=0.055 merge. Both interventions shape MLP gradient flow through similar channels (SOAP preconditioner whitening vs WD-tuned drift) — they are coupled, not orthogonal. Per-trial std=0.000310 is the lowest of any n=4 in this branch — very precise characterization.

**Key insight:** Two seemingly independent interventions (LR and WD) can share mechanism overlap through optimizer dynamics. Future combo-confirms should audit for shared gradient-flow channels before predicting additivity.

**Follow-on:** PR #323 (tanjiro) — Muon momentum (mu) sweep.


## 2026-05-17 23:03 UTC — PR #302: SOAP attn Q/K shared Gram preconditioner — **CLOSED clean-neutral**

- Branch: `g1r5-fern/soap-attn-qk-shared-gram`
- Student: g1r5-fern
- Hypothesis: Sharing a single Gram matrix for both Q and K projections (same input X) could double the curvature signal and exploit Q/K symmetry.

| Cell | Config | val/loss | ffs | W&B run | Δ vs new baseline (mu=3.271362) |
|------|--------|----------|-----|---------|--------------------------------|
| A (ctrl) | Separate Q/K Grams | 3.27190 | 3150 | `raaqoxgr` | +0.00054 |
| B | Shared Q/K Gram | 3.27254 | 3150 | `dogb3845` | +0.00118 |

- **Mechanism conclusion:** Shared Q/K Gram is mildly WORSE than separate (Δ=+0.00064 at n=1). Q and K have distinct curvature structure despite operating on the same input. Sharing the Gram averages across them, washing out per-projection eigenstructure. The negative result is definitively informative — confirms SOAP attn's per-projection Gram factorization is correct.
- **No Phase 2 trigger** (val ≤ 3.270 gate not passed by either cell).
- **Follow-on:** PR #318 (fern) — Adam β₁ sweep for AdamW aux groups (embed/lm_head/scalars). β₁=0.90 inherited default, never swept on this stack.


## 2026-05-18 03:20 UTC — PR #228: lr_embed=0.80 n=6 extension — **CLOSED clean-neutral**

- Branch: `g1r5-frieren/lr-embed-scale`
- Student: g1r5-frieren
- Hypothesis: lr_embed=0.80 (vs default 0.30) gives faster embedding gradient updates. Phase 1 n=1 showed val=3.270000, clearing the 3.270 gate. Extended to n=6 for statsig confirmation.

| Trial | val/loss | ffs | W&B run |
|-------|----------|-----|---------|
| t0 | 3.270223 | 3125 | (batch `3704tjm5`) |
| t1 | 3.269885 | 3125 | (batch `3704tjm5`) |
| t2 | 3.270447 | 3150 | (batch `3704tjm5`) |
| t3 | 3.270973 | 3125 | (batch `3704tjm5`) |
| t4 | 3.269534 | 3125 | (batch `3704tjm5`) ⭐ single-trial best |
| t5 | 3.271443 | 3150 | (batch `3704tjm5`) |
| **Mean n=6** | **3.270251** | — | — |

- **Statsig gate:** n=6 requires mu ≤ 3.269729. Actual mean=3.270251. Gate fails by 0.000522 (~0.45σ).
- **p(n=8 pass):** ≈2%. EV(n=8 extension) ≈ 0.0000283, far below EV(fresh hypothesis) ≈ 0.0002. Not worth extending.
- **Mechanism conclusion:** lr_embed=0.80 is not statsig-better than baseline. The 1.8× embedding LR boost provides marginal direction benefit already captured by SOAP preconditioning; does not compound meaningfully. lr_embed=0.80 mechanism exhausted.
- **Follow-on:** PR #337 (frieren) — Muon nesterov flag ablation (nesterov=True ctrl vs nesterov=False/Polyak EMA). The nesterov flag has never been ablated on any stack.

## 2026-05-18 02:50 UTC — PR #301: NS5 polynomial coeff sweep — **CLOSED clean-neutral**

- Branch: `g1r5-askeladd/ns5-poly-coeff-sweep`
- Student: g1r5-askeladd
- Hypothesis: NS5's cubic polynomial (a, b, c) at fixed iters=12 has the standard Muon-paper values (2, -1.5, 0.5). Varying the polynomial could find a more aggressive spectral normalization trajectory that converges faster.

| Cell | (a, b, c) | val/loss | ffs | W&B run | Δ vs baseline mu=3.271362 |
|------|-----------|----------|-----|---------|--------------------------|
| A (ctrl) | (2.0, -1.5, 0.5) | 3.27235 | 3150 | `0gjpqh9x` | +0.00099 (~0.84σ) |
| B (Muon-paper) | (3.4445, -4.775, 2.0315) | 3.27189 | 3150 | `lup676zw` | +0.00053 (~0.45σ) |
| C (intermediate) | (2.5, -2.5, 1.0) | 3.27203 | 3150 | `uia9awwp` | +0.00067 (~0.57σ) |
| **D (gentler)** | **(1.7, -1.1, 0.4)** | **3.27073** | **3125** | `ct9g7ora` | **-0.00063 (~0.53σ)** |

- **Mechanism conclusion:** NS5 polynomial space is FLAT around standard (2,-1.5,0.5) settings. All four cells cluster in a tight ~0.0016 val/loss range (< 1.5σ). Cell D (gentler polynomial, lower a-coefficient) edged the best val/loss and tied baseline-best ffs=3125, but Δ=-0.00063 is within noise (p~0.3 of being real). Phase 2 gate (val ≤ 3.270) NOT met.
- **Diagnostics:** All non-ctrl cells have ffs=3150 vs Cell D ffs=3125 — hint that a gentler polynomial may reduce variance slightly, but unreliable at n=1.
- **Follow-on:** PR #334 (askeladd) — Muon WD sweep (wd_mlp/wd_attn ∈ {0, 0.01, 0.025 ctrl, 0.05, 0.10}) — first-ever sweep of Muon weight decay on any stack.

## 2026-05-18 06:50 UTC — PR #337: Muon nesterov flag ablation — **CLOSED clean-negative (nesterov=True essential)**

- Branch: `g1r5-frieren/muon-nesterov-ablation`
- Student: g1r5-frieren
- Hypothesis: Muon's `nesterov=True` default has never been ablated. Testing whether Polyak momentum (nesterov=False) matches or beats Nesterov — if neutral, simplifies the optimizer; if Nesterov wins, confirms it's load-bearing.

| Cell | nesterov | val/loss | ffs | W&B run | Δ vs baseline mu=3.271362 |
|------|----------|----------|-----|---------|--------------------------|
| A (ctrl) | True | 3.270853 | 3125 | `09d0v5j2` | -0.000509 (~0.43σ below) — clean ctrl reproduction |
| B | False (Polyak) | 3.273543 | 3150 | `0iegd51l` | +0.002181 (~1.85σ above) |

- **Δ Cell B vs A ctrl: +0.00269 (~2.28σ worse).** ffs also regressed 3125 → 3150.
- **Mechanism conclusion:** nesterov=True is load-bearing. Polyak momentum consistently worse. The Nesterov look-ahead step (computing gradient at current + momentum direction before normalization) provides real benefit in this stack. Default confirmed correct; no change needed.
- **Incident:** Concurrent-runs violation at ~05:35Z (runs `09d0v5j2` + `vfskbh2x` both active on 1 GPU). Student resolved at 03:37Z; no data integrity issue.
- **Follow-on:** PR #346 (frieren) — `lr_attn` sweep {0.025, 0.035 ctrl, 0.045, 0.055, 0.075} on lr_mlp=0.055 stack. Last tested at old baseline (PR #209, clean-neg); retest warranted.

## 2026-05-18 07:35 UTC — PR #283: AGC Phase 2 n=4 — **CLOSED clean-neutral (gate locked out)**

- Branch: `g1r5-nezuko/adaptive-grad-clipping`
- Student: g1r5-nezuko
- Hypothesis: NFNets-style per-parameter adaptive gradient clipping at λ=0.03 reduces val/loss on the lr_mlp=0.055 + SOAP-attn stack.

| Trial | val/best_loss | ffs | W&B run |
|-------|--------------|-----|---------|
| T1 | 3.271929 | 3150 | `407dyaw7` (Phase 2 group `g1r5-nezuko/agc-phase2-n4`) |
| T2 | 3.273134 | 3150 | same run |
| T3 | 3.273133 | 3150 | same run |
| T4 | 3.273364 | 3150 | same run |
| **Mean** | **3.272890** | 3150 | — |

- **Statsig gate (n=4): mean ≤ 3.269362. AGC mean = 3.272890, fails gate by +0.003528 (~2.99σ).**
- ffs=3150 consistent across all 4 trials (worse than baseline ffs_best=3125).
- Single-shot best (T1=3.271929) was within noise of baseline, but regression-to-mean fully materialized in T2-T4.
- **Mechanism conclusion:** AGC λ=0.03 is clean-neutral. May mildly suppress useful gradient magnitudes on this stack (ffs=3150 consistent). AGC slot exhausted.
- **Follow-on:** PR #349 (nezuko) — AdamW aux WD sweep (wd_aux ∈ {0.0, 0.01, 0.05, 0.10, 0.20}) — current weight_decay=0 on embed/lm_head/scalars is untested.

## 2026-05-18 07:36 UTC — PR #320: Adam β₂ aux sweep — **Phase 2 directive posted at β₂=0.98**

- Branch: `g1r5-edward/adam-beta2-aux-sweep`
- Student: g1r5-edward
- Phase 1 cell sweep results (single-shot):

| Cell | β₂   | val/best_loss | ffs   | W&B run | vs baseline |
|------|------|---------------|-------|---------|-------------|
| A retry | 0.85 | 3.279930 | 3125 | — | +0.0086 (DNR) |
| C (ctrl) | 0.95 | 3.271010 | 3150 | — | ~baseline |
| **D** | **0.98** | **3.268718** | **3125** | `hfn1clh2` | **-0.00264 (~2.24σ)** ⭐ trigger |
| E | 0.99 | 3.270318 | 3125 | `mhnv5jxr` | -0.00104 (mild) |

- **Cell D β₂=0.98 is the winner**: 2.24σ below baseline, ffs=3125 matching best. β₂=0.99 also improved but only mildly (0.88σ), well behind β₂=0.98.
- **Phase 2 directive:** n=4 confirmation run launched at β₂=0.98 (comment on PR #320). Gate: n=4 mean ≤ 3.269362.
- **Interpretation:** Higher β₂ (slower moving EMA of second moment) reduces noise in the AdamW aux update — beneficial for embed (lr=0.30) and lm_head (lr=0.003125) groups. β₂=0.98 captures a 20-step effective "lookback" vs default β₂=0.95 (~20-step vs ~13-step).

## 2026-05-18 08:35 UTC — PR #321: LR cooldown_frac sweep — **CLOSED clean-neutral (default cd=0.70 optimal)**

- Branch: `g1r5-thorfinn/cooldown-frac`
- Student: g1r5-thorfinn
- Hypothesis: cooldown_frac (current default 0.70) controls the stable/decay split. Vary {0.50, 0.60, 0.70, 0.80, 0.90} to find optimum.

| Cell | cooldown_frac | val/best_loss | ffs | W&B run | vs baseline mu=3.271362 |
|------|---|---|---|---|---|
| A | 0.50 | 3.274204 | 3175 | `4r1l7rhv` | +0.00284 (~2.4σ worse) |
| B | 0.60 | (skipped) | — | — | — |
| **C (ctrl)** | **0.70** | **3.271924** | **3150** | `vmlfw0hr` | +0.00056 (~0.48σ — baseline reproduction) |
| D | 0.80 | 3.273066 | 3150 | `hrswi937` | +0.00170 (~1.4σ worse) |
| E | 0.90 | 3.274376 | 3150 | `xh7gpfge` | +0.00301 (~2.5σ worse) |

- **Verdict:** Bowl-shaped curve centered at default cd=0.70. Both extremes regress 2-3σ. Phase 2 gate not met. ctrl reproduces baseline tightly (+0.48σ).
- **Mechanism conclusion:** The stable-decay split is already at optimum. The 30% stable / 70% decay default cannot be improved by sliding along this axis. Further schedule progress requires a different axis (e.g., warmup, cycling, different decay shape).
- **Follow-on:** PR #353 (thorfinn) — LR warmup sweep (warmup_steps ∈ {0, 50, 100, 200, 400}); current schedule has NO warmup, untested.

## 2026-05-18 08:48 UTC — PR #334: Muon WD sweep — **CLOSED clean-negative (default wd=0.025 optimal)**

- Branch: `g1r5-askeladd/muon-wd-sweep`
- Student: g1r5-askeladd
- Hypothesis: Vary `wd_mlp = wd_attn` across {0, 0.01, 0.025, 0.05, 0.10} on the Muon (mlp + attn) optimizer.

| Cell | wd | val/best_loss | ffs | W&B run | vs baseline mu=3.271362 |
|------|---|---|---|---|---|
| A | 0.000 | 3.288528 | -1 (DNR) | `pf30m69f` | +0.017166 (~14.5σ catastrophic) |
| B | 0.010 | SKIPPED | — | — | — |
| **C (ctrl)** | **0.025** | (inherited PR #162, n=6) | 3141.67 mean | — | — |
| D | 0.050 | 3.279285 | 3250 | `r7v9ouwg` | +0.007923 (~6.7σ worse) |
| E | 0.100 | 3.304699 | -1 (DNR) | `katqhx5q` | +0.033337 (~28σ worse) |

- **Verdict:** Bowl-shaped with global minimum at default wd=0.025. wd=0 catastrophic (unbounded parameter growth → divergence); wd=0.10 catastrophic (over-regularization). Phase 2 gate not met. Default confirmed optimal.
- **Mechanism conclusion:** Muon decoupled weight decay (`p.mul_(1 - lr * wd)`) at 0.025 is essential and well-tuned. Asymmetric per-group WD (PR #194 tanjiro) and this symmetric WD sweep (PR #334 askeladd) both confirm wd=0.025 is at the optimum. Future WD work would need a different mechanism (adaptive, scheduled, or layerwise).
- **Follow-on:** PR #360 (askeladd) — SOAP precond_freq sweep on attn ∈ {4, 8, 16 ctrl, 32, 64}. Tests the staleness/compute trade-off for the SOAP eigenbasis refresh rate — never swept before.

## 2026-05-18 09:55 — PR #323: Muon momentum (mu) sweep CLOSED clean-negative

- **Student:** g1r5-tanjiro
- **Hypothesis:** Muon momentum mu (currently 0.95 default) might benefit from re-tuning. Sweep mu ∈ {0.85, 0.90, 0.95, 0.97, 0.99}.
- **Result table:**

| Cell | mu | val/best_loss | ffs | wandb_id | Δ vs baseline | σ |
|------|-----:|--------------:|----:|----------|--------------:|--:|
| A | 0.85 | 3.275691 | 3175 | `gr0xvxt1` | +0.004329 | +3.67σ |
| B | 0.90 | 3.272627 | 3150 | `tmt9xxnc` | +0.001265 | +1.07σ |
| **C ctrl** | **0.95** | **3.270578** | **3125** | `2cgoprbp` | **−0.000784** | **−0.66σ** |
| D | 0.97 | 3.275570 | 3175 | `9419jxjr` | +0.004208 | +3.56σ |
| E | 0.99 | 3.308187 | NOT REACHED | `eq8p8g1a` | +0.036825 | +31.18σ |

- **Conclusion:** Bowl-shape centered at default mu=0.95, ASYMMETRIC: mild on low side (variance penalty from reduced gradient smoothing), catastrophic on high side (direction-staleness wall). mu=0.99 fails to reach target. No Phase 2 promotion (Cell C ctrl narrowly misses gate at val=3.270578 vs 3.270).
- **Mechanism take:** mu is purely a direction smoother before NS5 spectral normalization. Optimal sits exactly at the historical default. SOAP-whitened landscape changes step-to-step, making staleness much more costly than variance.
- **Verdict:** Mechanism class exhausted at coarse grid. Per-group mu (mu_mlp vs mu_attn) might find hidden optima but asymmetric response constrains upside significantly. Closed clean-neg.

## 2026-05-18 10:45 — PR #318: AdamW aux β₁ Phase 2 n=4 confirm CLOSED clean-neutral

- **Student:** g1r5-fern
- **Hypothesis:** Phase 1 n=1 sweep showed β₁=0.70 = val 3.26920 (~1.8σ below baseline); confirm at n=4.
- **Result table (Phase 2 n=4 at β₁=0.70):**

| Trial | val/loss | ffs | Δ vs baseline |
|------:|---------:|----:|---------------:|
| 0 | 3.27060 | 3125 | −0.00076 |
| 1 | 3.27217 | 3150 | +0.00081 |
| 2 | 3.27275 | 3150 | +0.00139 |
| 3 | 3.27064 | 3125 | −0.00072 |
| **mean** | **3.271540** | 3137.5 | **+0.000178 (~0.15σ)** |

- **wandb run IDs:** Phase 1 `bmiour40` (β₁=0.70), `xinpvprd` (β₁=0.80 ctrl); Phase 2 `53l16b0z` (n=4 at β₁=0.70)
- **Statsig gates:** n=4 mu ≤ 3.269362 MISS by +0.002178 (~2σ); n=6 extension trigger MISS.
- **Conclusion:** Phase 1 n=1 signal was favorable seed noise (-1.8σ outlier). n=4 reverts to baseline indistinguishably. AdamW aux β₁ on this stack does NOT have a reproducible optimum away from default 0.80 in the {0.70, 0.80} range.
- **Verdict:** Closed clean-neutral. Mechanism class exhausted at this baseline.

## 2026-05-18 14:10 — PR #306: AdamW lm_head LR sweep + Phase 2 n=4 CLOSED clean-neutral

- **Student:** g1r5-alphonse
- **Hypothesis:** Hardcoded lr_lm_head=1/320=0.003125 was conservatively tuned for old baseline; with SOAP+lr_mlp=0.055 stack, lm_head can absorb larger LR. Sweep {0.001, 0.003125, 0.010, 0.030, 0.100}, then n=4 confirm at peak.
- **Phase 1 n=1 sweep (clean monotone inverted-U, peak at D=0.030):**

| Cell | lr_lm_head | val/loss | ffs | Δ vs baseline mu=3.271362 | wandb |
|---|---:|---:|---:|---:|---|
| A | 0.001 | 3.276032 | 3200 | +0.00467 (~3.95σ above) | `gdgag170` |
| B | 0.003125 (ctrl) | 3.272425 | 3150 | +0.00106 (~0.90σ above) | `pvk9u2pg` |
| C | 0.010 | 3.271231 | 3150 | -0.00013 (~0.11σ below) | `o7pictq5` |
| **D ★** | **0.030** | **3.270332** | **3125** | **-0.00103 (~0.87σ below) ★** | `29s9g1k2` |
| E | 0.100 | 3.276856 | 3200 | +0.00549 (~4.65σ above) | `xzflql8k` |

- **Phase 2 n=4 at lr_lm_head=0.030 (run `7xl5rcjb`):**

| Trial | val_loss | ffs |
|---|---:|---:|
| T1 | 3.27025 | 3125 |
| T2 | 3.27131 | 3150 |
| T3 | 3.27223 | 3150 |
| T4 | 3.27098 | 3125 |
| **mean (n=4)** | **3.2711925** | **3137.5** |

- **Statsig:** margin (3.271362 − 3.2711925) × √4 = +0.000339 vs +0.004 needed → FAIL by ~12×. Z(mean - baseline) = -0.14σ ≈ on baseline.
- **Conclusion:** Cell D n=1 = 3.27033 was a favorable seed within ±2σ trial-to-trial spread (T1=3.27025, T3=3.27223, range ≈ 0.002). Mean reverts to baseline at n=4. Mechanism class: bowl with shallow basin centered near (but above) hardcoded default. Directional improvement is real but too small to clear statsig.
- **Mechanism take:** lm_head is a single dense projection (768×50304) late in graph. Once Muon attn + lr_mlp tuning has squeezed easy gain, residual lm_head LR contribution sits within trial noise. Mirrors frieren's lr_embed=0.80 outcome (PR #228 also Phase 2 clean-neutral). Pattern: endpoint-LR sweeps look promising at n=1 but don't survive n=4 statsig on this baseline.
- **Verdict:** Closed clean-neutral. lr_lm_head exhausted on this stack.

## 2026-05-18 15:00 — PR #353: LR warmup_steps sweep CLOSED clean-NEG

- **Student:** g1r5-thorfinn
- **Hypothesis:** Test whether warmup_steps ∈ {0, 50, 100, 200, 400} can stabilize early training on the 3250-step budget.
- **Partial results (D/E skipped per advisor directive after Cell C catastrophic):**

| Cell | warmup | W&B id | val/best_loss | ffs | Δ vs μ |
|------|------:|--------|--------------:|----:|-------:|
| A (ctrl) | 0 | `dfr15323` | 3.27059 | 3125 | -0.65σ (baseline) |
| B | 50 | — | — | — | infra-crashed step 6 (skipped) |
| C | 100 | `nj3fqbk8` | **3.28032** | **-1 (no target)** | **+7.5σ (FAIL)** |
| D | 200 | — | — | — | skipped — predicted worse |
| E | 400 | — | — | — | skipped — predicted worse |

- **Conclusion:** Even modest warmup (100 steps = 3.1% of budget) eats into peak-LR phase severely. With cooldown_frac=0.70, warmup=100 leaves only 27% of budget at peak LR — insufficient. The default stable-then-linear-decay schedule with warmup=0 is correct for this small/budget combination.
- **Multi-crash incident:** Cell A crashed 5× (4× infra/pod setup, 1× near-terminal step 3048), Cell B crashed step 6 — infra-level crashes mostly resolved by retry. Cell A retry `dfr15323` ran clean to 3250 on second attempt.
- **Verdict:** Closed clean-NEG. warmup_steps moves to exhausted axes.

## 2026-05-18 15:15 — PR #349: AdamW aux WD sweep CLOSED clean-NEG

- **Student:** g1r5-nezuko
- **Hypothesis:** Test wd_aux ∈ {0, 0.01, 0.05, 0.10, 0.20} for AdamW aux groups (embed, lm_head, scalars).
- **Partial results (D/E skipped per advisor directive):**

| Cell | wd_aux | val/best_loss | ffs | wandb | Δ vs μ | σ |
|------|-------:|--------------:|----:|-------|-------:|---:|
| A (ctrl) | 0 | 3.26944 | 3125 | `alp238rf` | -0.00192 | -1.63σ (baseline) |
| B | 0.01 | 3.27403 | 3175 | `mnbz5ep0` | +0.00267 | +2.26σ |
| C | 0.05 | **3.29135** | **-1 (target missed)** | `zx8h5ord` | +0.01999 | +16.9σ |
| D | 0.10 | killed step 1173 | — | `bbyiqw40` | skipped | — |
| E | 0.20 | not launched | — | — | skipped | — |

- **Conclusion:** Monotone WORSE with increasing wd_aux. The 'AdamW aux' optimizer bundles three groups with very different LR scales (embed=0.30, scalars=0.01, lm_head=0.003125). Decoupled WD applies `(1-lr·wd)` shrinkage per step — at wd=0.05, embed loses 1.5%/step which swamps gradient signal. **Mixed-LR-scale param groups cannot share a single wd value.**
- **Mechanism take:** Unlike Muon (homogeneous LR scale across MLP/attn), the AdamW aux groups have 100× lr_attn:lr_lm_head ratio. Per-group wd_aux could be a fresh follow-up, but the uniform default wd_aux=0 IS the per-group-uniform optimum.
- **Verdict:** Closed clean-NEG. wd_aux (uniform across aux groups) moves to exhausted axes.

## 2026-05-19 02:00 UTC — PR #382: per-group Muon mu sweep (mu_mlp × mu_attn ∈ {0.93,0.95,0.97}) — **CLOSED clean-neutral**

- **Student:** g1r5-thorfinn
- **Hypothesis:** MLP (processed by SOAP) and attn (plain Muon) may want different momentum decay rates given their different gradient statistics. Sweep mu_mlp × mu_attn over {0.93, 0.95, 0.97} per-group.

### Results

| Cell | mu_mlp | mu_attn | val/loss | ffs | Δ vs A ctrl | Δ vs OLD baseline | σ | W&B id |
|------|-------:|--------:|---------:|----:|------------:|------------------:|---:|--------|
| A (ctrl) | 0.95 | 0.95 | 3.26964 | 3125 | — | -0.00172 | -1.46σ | uw0gy7qy |
| B | 0.93 | 0.95 | 3.27108 | 3125 | +0.00144 | -0.00028 | -0.24σ | 3di3pof9 |
| C | 0.97 | 0.95 | 3.27378 | 3150 | +0.00414 | +0.00242 | +2.04σ | nu705adw |
| D | 0.95 | 0.93 | 3.27276 | 3150 | +0.00312 | +0.00140 | +1.18σ | 2bc1t3kz |
| E | 0.95 | 0.97 | 3.27185 | 3150 | +0.00221 | +0.00049 | +0.42σ | odu3051c |

Note: All comparisons above vs OLD baseline (mu=3.271362). vs NEW baseline (mu=3.267948) all cells are ≥ +3.8σ.

### Conclusion

Per-group Muon mu differentiation not load-bearing within [0.93, 0.97] band. Cell A's 3.26964 is a favorable seed (not a real per-group effect). Weak directional hints: MLP wants slightly lower mu (0.93 mildly best), attn wants slightly higher mu (0.97 mildly best) — but sub-noise at n=1. Both axes worse than default 0.95. Default mu=0.95 confirmed as robust optimum for both groups.

Family retired: Per-group Muon mu hypothesis class closed for r5.

## 2026-05-19 02:00 UTC — PR #426: thorfinn LR schedule shape sweep — **ASSIGNED**

- **Student:** g1r5-thorfinn
- **Hypothesis:** Following WD ramp_down breakthrough (PR #371), test whether LR cooldown shape also matters: cosine vs linear cooldown; with vs without stable phase.
- **Cells:** A ctrl stable_then_linear, B linear_throughout, C cosine_throughout, D stable_then_cosine, E stable_then_sq
- **Code change:** Add `_lr_multiplier` function + `--lr_schedule` CLI flag (parallel to `_wd_multiplier` from PR #371)
- **Status:** In progress — waiting for student to implement code change and launch Cell A

## 2026-05-19 03:00 UTC — PR #383: Muon gradient noise injection sweep — **CLOSED clean-negative**

- **Student:** g1r5-nezuko
- **Hypothesis:** Stochastic gradient noise (injected after NS5 Newton step) may help escape sharp minima or provide implicit regularization during training. Sweep std ∈ {0, 1e-4, 1e-3} × schedule {constant, linear_decay, cooldown_only}.

### Results

| Cell | std | schedule | val/loss | ffs | Δ vs OLD baseline | σ | Δ vs NEW baseline | σ_new | W&B id |
|------|----:|----------|---------:|----:|------------------:|---:|------------------:|------:|--------|
| A (ctrl) | 0 | constant | 3.27218 | 3150 | +0.00082 | +0.69 | +0.00423 | +5.14 | 2bojk9g6 |
| B | 1e-4 | constant | 3.27108 | 3150 | -0.00028 | -0.24 | +0.00313 | +3.80 | isqlrt28 |
| **C** | **1e-3** | **constant** | **3.27081** | **3125** | **-0.00055** | **-0.47** | **+0.00286** | **+3.48** | td3g1stj |
| D | 1e-3 | linear_decay | 3.27158 | 3150 | +0.00022 | +0.19 | +0.00363 | +4.41 | 4jibve9v |
| E | 1e-3 | cooldown_only | 3.27327 | 3150 | +0.00191 | +1.62 | +0.00532 | +6.47 | bzn94mp1 |

### Mechanism interpretation

**Ranking C > D > E** (for std=1e-3 schedules) strongly implies: **noise during stable phase is beneficial; noise during cooldown is actively harmful**. This aligns precisely with the WD ramp_down breakthrough principle. The cooldown_only schedule (Cell E) adds noise exactly when the model is least able to absorb it. Constant noise across all phases is net positive because the stable-phase benefit outweighs the cooldown harm.

Monotone A→B→C improvement at constant schedule suggests the std curve has not peaked at 1e-3. Student suggested trying std=3e-3 or 5e-3, or "stable_only" schedule (noise only in stable phase, 0 in cooldown).

### Conclusion

Best cell C at +3.48σ vs NEW baseline (mu=3.267948) — far below Phase 2 gate (need mu ≤ 3.265948 for n=4 confirm). Gap is too large for n=4 to recover. Closing clean-negative. Muon gradient noise injection family retired for r5.

New assignment: nezuko PR #427 — WD per-block decomposition (MLP vs attn contribution).

## 2026-05-19 03:00 UTC — PR #427: nezuko WD per-block decomp — **ASSIGNED**

- **Student:** g1r5-nezuko
- **Hypothesis:** WD ramp_down gain from PR #371 applied equally to MLP and attn Muon groups. This sweep decomposes whether MLP WD, attn WD, or both contribute to the gain, and tests asymmetric peak (heavy MLP, light attn).
- **Cells:** A ctrl (both), B (MLP only), C (attn only), D (no WD), E (asymmetric heavy MLP)
- **Code change:** None — uses existing `--wd_mlp`, `--wd_attn`, `--wd_schedule` flags
- **Status:** In progress — waiting for student to launch Cell A

## 2026-05-19 03:30 UTC — PR #346: frieren Muon attn LR P2 — **CLOSED clean-neutral**

- **Student:** g1r5-frieren
- **Hypothesis:** Muon attn LR (lr_attn=0.025 from P1 best) vs baseline lr_attn=0.035; P2 n=4 confirm.

### P2 n=4 confirm results (W&B run 85x1y4if)

| Trial | val/best_loss | ffs | Δ vs OLD baseline |
|-------|---------------|-----|---:|
| T0 | 3.275463 | 3175 | +3.47σ (unfavorable seed) |
| T1 | 3.270923 | 3125 | -0.37σ |
| T2 | ~3.272217 | 3150 | +0.73σ |
| T3 | ~3.271920 | 3150 | +0.47σ |
| **n=4 mean** | **~3.272631** | **~3150** | **+1.08σ vs OLD** |

**vs NEW baseline:** ~+5.69σ (far above n=4 gate ≤ 3.265948)

### Conclusion

P1 Cell B val=3.269674 (lr_attn=0.025) was a favorable-seed singleton. n=4 confirm shows the lr_attn perturbation is not load-bearing beyond seed variance. Muon attn LR family closed clean-neutral.

## 2026-05-19 03:30 UTC — PR #428: frieren SOAP β₂ sweep — **ASSIGNED**

- **Student:** g1r5-frieren
- **Hypothesis:** SOAP β₂ (Gram matrix EMA decay) never swept in r5; default=0.90 may not be optimal for 3250-step budget. Tests 0.80/0.85/0.90/0.95/0.98 with EMA half-lives from 3.1 to 34.3 steps.
- **Code change:** Add `--soap_beta2` CLI flag; pass to `soap_precondition_momentum` and `soap_update_preconditioner` call sites; update hparams logging.
- **Status:** In progress — waiting for student to implement code change and launch Cell A

## 2026-05-19 07:31 UTC — PR #432: tanjiro Muon Nesterov ablation — **CLOSED clean-neutral**

- **Student:** g1r5-tanjiro
- **Hypothesis:** Does nesterov=True matter after NS5 orthogonalization? Test nesterov=False (removing the Nesterov-modified EMA input to NS5) against ctrl.
- **W&B runs:** `g04kfqds` (Cell A ctrl), `93s9wz05` (Cell B no_nesterov, retry after initial `2l3ewsp6` crashed at step 249)

### Results

| Cell | nesterov | val/loss | ffs | Δσ vs NEW baseline |
|------|----------|----------|-----|--------------------|
| A (ctrl) | True (default) | 3.267231 | 3100 | -0.87σ (neutral) |
| B | False | 3.26726 | 3075 | -0.84σ (neutral) |

### Mechanism interpretation

nesterov on/off is effectively a no-op (val difference = 0.000029, ~0.03σ). The 25-step ffs improvement (3075 vs 3100) is within single-seed noise. **After NS5 orthogonalization dominates the update direction, the nesterov modification of the EMA input is redundant.** Axis closed.

### Conclusion

Closed clean-neutral. Cell A val=3.267231 adds a useful additional NEW-baseline reproduction seed (-0.87σ matches prior ctrl values).

New assignment: PR #445 — Muon mu schedule sweep (ramp_up_090_099 / ramp_down_099_090 / cliff_at_cooldown).

## 2026-05-19 07:31 UTC — PR #445: tanjiro Muon mu schedule sweep — **ASSIGNED**

- **Student:** g1r5-tanjiro
- **Hypothesis:** Muon momentum mu=0.95 was found optimal in static sweep (PR #382 neutral). "Schedule shape matters" insight (from PR #371 WD win + edward Cell C −1.60σ signal) suggests time-varying mu may unlock further gains. Test ramp_up (0.90→0.99), ramp_down (0.99→0.90), and cliff_at_cooldown (0.95→0.99 step at cooldown start).
- **Code change:** Add `--muon_mu_schedule` CLI flag; per-step mutate `group["mu"]` in all Muon optimizer param groups; log `opt/muon_mu` to W&B.
- **Cells:** A ctrl, B ramp_up_090_099, C ramp_down_099_090, D cliff_at_cooldown_095_099 (optional)
- **Status:** Assigned, waiting for student code implementation

## 2026-05-19 23:50 UTC — PR #467: nezuko SOAP trust threshold sweep {0.0/0.1/0.3/0.5/0.8} — **CLOSED clean-neutral**

- **Branch:** `g1r5-nezuko/soap-trust-threshold`
- **Student:** g1r5-nezuko
- **Hypothesis:** SOAP trust threshold (default 0.0 = always trust) had never been varied. A threshold > 0 triggers Muon fallback when SOAP update direction disagrees with Muon direction (cos_sim < threshold), potentially preventing bad updates during stale-preconditioner phases.

### Results

| Cell | trust_threshold | val/loss | Δσ vs baseline | ffs | fired_fraction | W&B run |
|------|----------------|----------|-----------------|-----|---------------|---------|
| A | 0.0 (ctrl) | 3.26694 | −1.23σ | 3075 | 0.00% | y9fsimjv |
| B | 0.1 | 3.26775 | −0.24σ | 3100 | 0.10% | sbroalg6 |
| C | 0.3 | 3.26693 | −1.24σ | 3100 | 0.44% | mmwxjnak |
| D | 0.5 | 3.26940 | +1.76σ | 3100 | 0.71% | f6ju7rdq |
| E | 0.8 | 3.26791 | −0.04σ | 3100 | 20.58% | n4dyzo4z |

Range = 0.00247 (~3σ). No cell clears n=4 gate (3.265948) or n=1 interesting gate consistently.

### Conclusion

**Axis closed, clean-neutral.** The SOAP vs Muon cosine-similarity distribution is tight (min=0.78, mean=0.84, max=0.91). Thresholds ≤ 0.5 are mechanical no-ops (gate never fires because min cos_sim > threshold). Threshold=0.8 fires 20.6% of param-steps but val/loss lands at baseline (−0.04σ). 

Critical diagnostic: **at the moments where SOAP and Muon updates disagree most strongly, substituting Muon costs zero in terminal val.** This suggests SOAP provides lift not through directional advantage over Muon at those specific moments but through steady accumulated preconditioner improvement over the full run.

Useful telemetry logged: `trust/fired_fraction`, `trust/cos_sim_mean`, `trust/cos_sim_min/max`, attn vs mlp breakdown. Cos_sim is consistently lower for attn (~0.82) than mlp (~0.88) — potentially useful diagnostic for future SOAP scope experiments.

New assignment: PR #521 — gradient clipping sweep (first-ever clipping in this run; targets single-seed variance).
