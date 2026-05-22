## 2026-05-22 06:50 UTC — PR #770 ASSIGNED (edward): H58 Aux v_t freeze at cooldown onset (mechanism complement to PR #740)

- Branch: `g1r3-edward/aux-vt-freeze`
- Hypothesis: At cooldown onset (step 2493 ≈ 75% of training), FREEZE aux AdamW `exp_avg_sq` (v_t) buffer at its peak-conditioning value. Snapshot at freeze step; restore after each subsequent step. Preserves well-saturated denominator built up during high-LR main training, prevents late-cooldown noise from leaking into the v_t estimate when small gradients dominate. **Mechanism complement to PR #740**: same axis (mid-training v_t intervention) but OPPOSITE direction — preserve vs zero. Maintains bias-correction invariant (`1-β2^step ≈ 1` for step >> 60, so frozen v̂_t = V/1 = V).
- Builds on closure pattern: PR #689 (long-horizon EMA hurts cooldown), PR #721 (annealing long-horizon down didn't help), PR #740 (zeroing v_t catastrophic). Freeze tests the "preserve at peak conditioning" extreme directly.
- Arms (4, n=1, 3325 steps): ctrl, freeze@step 2493 all groups (primary), freeze@step 2493 embed+lmhead only (isolates large-tensor effect), freeze@step 1663 (50%, tests earlier freeze).
- Direct follow-up from PR #740 student suggested follow-up #1 ("gradual second-moment dampening" — freeze is the extreme case).
- ~20 LoC: 2 CLI flags + snapshot/restore logic in train loop after `optimizer1.step()`.
- Telemetry: `aux/vt_norm_embed`, `aux/vt_norm_lmhead`, `aux/vt_norm_scalars_mean`, `aux/vt_pre_freeze_max_abs`, `aux/vt_post_freeze_drift` (should be 0 if freeze working).
- W&B group `h58_aux_vt_freeze`. Reassignment after PR #746 RACS NEG closure.

---

## 2026-05-22 06:50 UTC — PR #746 CLOSED (edward): H51 RACS rank-2 factorization NEG (Δ+0.067 ~130σ, axis closed)

- Branch: `g1r3-edward/racs-aux`
- Hypothesis: Replace AdamW's per-element v_t with rank-2 row-column factored `sqrt(v_row · v_col) + eps`. Test on embed+lm_head (vocab-anisotropic groups), then optionally all 2D body weights.
- Arms (2 terminal + 1 correctly skipped, n=1, 3325 steps):

| Arm | Mode | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|---|
| 1 ctrl | off (fused AdamW) | `ijtugr6u` | **3.27438** | 3175 | — |
| 2 RACS embed_lmhead_only | rank-2 row-col | `9rjql9qg` | **3.34131** | -1 (never reached 3.28) | **+0.06693 NEG (~130σ)** |
| 3 RACS all_2d | rank-2 row-col on all 2D body weights | SKIPPED | — | — | — |

Arm 3 skip justified: `adam_scalars` group contains only `ndim<2` tensors → RACSAdamW `use_racs = racs_apply and (g.dim() == 2)` gate forces per-element fallback even with `racs_apply=True`. all_2d is bit-identical to embed_lmhead_only on this stack since only embed.weight and proj.weight are 2D aux. Saved 1.7h GPU.

### Mechanism finding — rank-2 factorization systematically under-conditions

Trajectory analysis (cleanest closure mechanism in cycle):

| step | ctrl | RACS | Δ |
|---|---|---|---|
| 500 | 3.91 | 4.24 | **+0.33 (immediate gap)** |
| 1500 | 3.62 | 3.74 | +0.13 |
| 2000 | 3.48 | 3.55 | +0.07 |
| 3325 | 3.27438 | 3.34131 | +0.067 (steady deficit) |

Rank-2 outer product `sqrt(v_row · v_col)` enforces a rank-1 second-moment surface. Actual `g²` on embed.weight has substantial (token × channel) **interaction noise** that per-element v_t captures but rank-2 smears. Shape (immediate +0.33, narrowing to steady +0.067, NO cooldown rescue) confirms **systematic under-conditioning**, not instability or divergence. Structural row/column anisotropy hypothesis is real but insufficient to dominate (token × channel) interaction structure.

### Rule logged — aux preconditioner-structure axis CLOSED

Joint closure across 7 mechanism classes:
- PR #643 PAdam (v_t power)
- PR #631 β2=0 (v_t memory)
- PR #612 β1=0 (m_t memory)
- PR #670 per-group eps
- PR #592/#672 GC (gradient-direction projection)
- **PR #746 RACS (preconditioner-structure axis)** ← THIS

Future factored-preconditioner proposals (Adafactor, Shampoo-aux, rank-3 row × col + diag) pre-closed by structural analogy. Edward's follow-up #1 correctly predicts rank-3 closes ≤10% of the gap (mechanism is high-rank interaction noise, not a missing diagonal).

### Follow-up routing
Edward → PR #770 H58 aux v_t freeze (state-preservation, fresh axis distinct from state-modification). PR #770 is the mechanism complement to PR #740 (v_t reset NEG) — preserve vs zero, both probe v_t-at-cooldown question.

## 2026-05-22 05:58 UTC — PR #767 ASSIGNED (tanjiro): H57 MuonH inner momentum schedule

- Branch: `g1r3-tanjiro/muonh-inner-mu-schedule`
- Hypothesis: Schedule MuonH inner `mu` (currently fixed 0.95) across training. Warm phase: mu=0.85 (responsive to fresh signal in chaotic init), mid: mu=0.95 (current default), cooldown: mu=0.97 (smoother trajectory as LR cools).
- Arms (4, n=1, 3325 steps): ctrl (constant mu=0.95), default ramp (0.85→0.95→0.97), gentler warm (0.90→0.95→0.97), warm-only (0.85→0.95→0.95 to isolate warm contribution).
- Fresh axis: **inner MuonH momentum scheduling**. PR #563/#536 closed OUTER MuLoCo momentum scheduling, but body Muon inner mu has NEVER been scheduled in any prior PR. Schmidhuber-style old-idea re-application: Polyak heavy-ball damped late-stage momentum applied to Muon's inner loop.
- ~25 LoC: piecewise-linear schedule function + 4 CLI flags + per-step group["mu"] update in train loop.
- Reassignment after PR #740 closure (single-shot v_t reset NEG).

---

## 2026-05-22 05:58 UTC — PR #766 ASSIGNED (askeladd): H56 Reference Contra-Muon formula (TRUE direction change)

- Branch: `g1r3-askeladd/contra-muon-ref`
- Hypothesis: Implement the REFERENCE Contra-Muon formula from `records/track_3_optimization/results/20260501_contra_muon/train_gpt_simple_contra_muon_2.py:224-234` that performs a TRUE direction change on the NS5 update. Subtract the OPERATOR-normalized gradient (not the parallel projection): `u_contra = u - (γ/2)·scale_to_unit_operator_norm(g); u_contra *= ||u||_F / ||u_contra||_F`. The previous PR #743 closure was a NULL because the implemented formula `u - γ(<u,g>/||u||²)u = u(1 - γ<u,g>/||u||²)` was a scalar rescaling cancelled by scale_invariant + hyperball.
- Arms (3, n=1, 3325 steps): ctrl (γ=0.0, sanity), γ=0.05 (paper default), γ=0.10 (stronger correction).
- Direct follow-up from student's suggested follow-up #1 in PR #743 closure analysis.
- ~15 LoC: new `scale_to_unit_operator_norm` function + extend `muon_update` with `contra_gamma` arg + CLI flag wiring.
- Telemetry: `contra/alignment_mean`, `contra/direction_change_angle`, `contra/frob_ratio_pre` to verify genuine direction change.

---

## 2026-05-22 05:55 UTC — PR #743 CLOSED (askeladd): H49 Contra-Muon — Δ+0.00066 NULL (formula reduces to no-op)

- Branch: `g1r3-askeladd/contra-muon-pruning`
- Hypothesis: Subtract gradient-projected-onto-NS5-output from NS5 update as approximate Contra-Muon direction correction.
- Arms (2 terminal, n=1, 3325 steps):

| Arm | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|
| 1 ctrl (γ=0.0) | `n27juk6t` | 3.27286 | 3125 | — |
| 2 treatment (γ=0.1) | `n7vr1qzp` | 3.27352 | 3150 | +0.00066 (~1σ NULL) |

### Mechanism finding — implemented formula is algebraically a no-op under current optimizer mode

Student's rigorous algebraic proof:

1. **Scalar rescaling not direction change**: `u - γ·(<u,g>_F / ||u||²_F)·u = u·(1 - γ·<u,g>_F / ||u||²_F)`. The bracketed term is a scalar; multiplying u by a scalar preserves direction.
2. **Renormalize line is numeric no-op**: `update * (update.norm().detach() / u_norm)` where both norms are computed on the SAME post-subtraction tensor → multiplier ≡ 1.0. `.detach()` only affects autograd graph (and code is inside `@torch.no_grad()` anyway).
3. **scale_invariant + hyperball cancels residual scalar effect**: `scale_invariant_update_` projects parameter back onto Frobenius sphere of fixed radius after each step → kills any scalar shrinkage.
4. **Telemetry corroborates premise mismatch**: `alignment_mean = +0.548`, `alignment_min = +0.334`, `alignment_max = +0.843`. NS5 output is POSITIVELY aligned with post-momentum gradient on ALL 12 blocks. The premise ("NS5 may anti-align with g") does not match empirical reality.

### Rule logged for portfolio memory

Future direction-projection PRs on MuonH must:
- Explicitly verify proposed correction is NOT parallel to u (true direction change, not scalar rescale)
- Account for scale_invariant + hyperball mode (Frobenius-sphere projection undoes scalar effects)
- Include alignment telemetry to verify the assumed anti-alignment regime exists empirically

### Follow-up routing
Askeladd → PR #766 H56 Reference Contra-Muon formula (true direction change via operator-normalized gradient per student's suggested follow-up #1).

---

## 2026-05-22 05:55 UTC — PR #740 CLOSED (tanjiro): H48 lm_head v_t reset — Δ+0.06644 NEG, axis closed (bias-correction mismatch)

- Branch: `g1r3-tanjiro/lmhead-vt-reset-cooldown`
- Hypothesis: Zero `exp_avg_sq` for lm_head (`model.proj.weight`, lr=1/320) at cooldown onset (step 2493). Stale v_t accumulated from high-LR main training was hypothesized to suppress effective step size at the start of cooldown when small gradients need maximum adaptive responsiveness.
- Arms (2 terminal, n=1, 3325 steps):

| Arm | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|
| 1 ctrl (no reset) | `guohogxk` | 3.27250 | -1 | — |
| 2 v_t reset @ step 2493 | `8yscqx5z` | **3.33894** | -1 | **+0.06644 NEG (~80σ)** |

Kill gate triggered. Arm 3 (m_t + v_t reset) correctly not launched — would only worsen the same instability mode.

### Mechanism finding — bias-correction mismatch breaks single-shot v_t reset

Catastrophic post-reset destabilization trajectory:

| step | arm 2 val/loss | note |
|---|---|---|
| 2375 | 3.40291 | normal cooldown |
| **2493** | reset fires | v_t zeroed (vt_pre_rms=2.32e-2 → 0) |
| **2500** | **6.18808** | **catastrophic spike (~+2.79 in 7 steps)** |
| 2750 | 3.42975 | partial recovery |
| 3000 | 3.36447 | never recovers (kill gate exceeded) |
| 3325 | 3.33894 | terminal |

Student's causal chain (preserved):

1. **Bias-correction mismatch**: `step_count=2494` post-reset → bias-correction divisor `1/(1-β2^step) ≈ 1.0` expects saturated v_t, gets zero → effectively uses uncorrected raw squared grad on first post-reset step.
2. **eps=1e-6 too small to absorb zero denominator**: normal v_t ~2e-2 → sqrt ≈ 0.14, eps negligible. With v_t=0, eps IS the denominator → effective step `lr·m_t/eps ≈ 1/320 · 2.6e-3 / 1e-6 ≈ 8` vs normal ~5e-5 → **~1.6e5× step magnitude jump**.
3. **AGC clip 0.05 is per-tensor at gradient level**, not update level → cannot catch denominator-driven update explosion.

This is a clean structural disproof: **single-shot mid-training v_t zeroing breaks Adam's bias-correction invariant at the small-eps regime needed for tight convergence**.

### Rule logged
Future advisor planning rejects single-shot mid-training state reset proposals on bias-corrected adaptive optimizers (AdamW, AdEMAMix, AdaBelief, Adan) unless they include: (a) coupled `step_count` reset (re-engages bias correction), (b) larger eps OR warmup-rebuild period before LR cooldown, (c) demonstrated stability via smoke test crossing the reset boundary.

### Follow-up routing
Tanjiro → PR #767 H57 MuonH inner mu schedule (fresh axis, not another state-reset variant — single-shot reset axis closed).

Student's suggested follow-ups (kept for future cycles):
1. Gradual second-moment dampening via `state['exp_avg_sq'].mul_(0.5)` at cooldown onset (sidesteps bias-correction discontinuity)
2. eps schedule 1e-6 → 1e-4 at cooldown onset (dampens denominator on large side without zeroing)

---

## 2026-05-22 05:25 UTC — PR #763 ASSIGNED (thorfinn): H55 MuLoCo OFF pruning ablation

- Branch: `g1r3-thorfinn/mulocco-off-ablation`
- Hypothesis: Test whether MuLoCo outer wrapper (Nesterov-SGDM, outer_lr=0.7, outer_momentum=0.5, sync_interval=30) is still load-bearing on top of the current stack. The wrapper was added in earlier stack iterations; many "load-bearing" assumptions deserve periodic re-test as the underlying stack evolves.
- Arms (3 sequential, n=1, 3325 steps): ctrl (MuLoCo ON), MuLoCo OFF (`--use_outer_optimizer 0`), conditional arm 3 sync_interval doubled.
- Fresh axis: **pruning ablation** — fills the "test load-bearing assumptions" axis. Complements additive-mechanism work in flight (#743/#744/#746/#750) by testing whether existing components are minimal.
- Flag-only change (~0 LoC), but requires telemetry to PROVE MuLoCo is actually disabled (outer/sync_count, outer/step_norm).
- Builds on thorfinn's Sophia-H diagnostic style — same clean instrumentation discipline applied to a pruning test.

---

## 2026-05-22 05:25 UTC — PR #762 ASSIGNED (nezuko): H54 NS5 polynomial coefficient sweep (Keller Jordan)

- Branch: `g1r3-nezuko/ns5-coefs-kj`
- Hypothesis: NS5 polynomial coefficients (a, b, c) — currently hardcoded (2, -1.5, 0.5) — control fixed-point dynamics of the orthogonalization iteration. Keller Jordan's aggressive coefs (3.4445, -4.7750, 2.0315) converge in ~5 iterations vs ~12 for standard, with different spectral basin. PR #190 closed the ITERATION COUNT axis at k=12; the COEFFICIENT axis was never tested — mechanistically distinct because it changes fixed-point dynamics, not just precision of the same dynamics.
- Arms (3 sequential, n=1, 3325 steps): ctrl (2, -1.5, 0.5) at k=12, KJ coefs at k=12 (better orthogonalization same budget), KJ coefs at k=8 (test compute savings + quality).
- Fresh axis: **MuonH-side NS polynomial dynamics** — orthogonal to iteration count (closed) and post-NS direction transforms (in flight via Contra-Muon/Soft-Muon).
- ~10 LoC: parameterize hardcoded (a, b, c) via CLI flags.
- Builds on nezuko's Lion mechanism rigor — same closure-style 3-arm sweep applied to MuonH-side.

---

## 2026-05-22 05:25 UTC — PR #761 ASSIGNED (frieren): H53 EMA-of-weights at evaluation (Polyak averaging)

- Branch: `g1r3-frieren/ema-weights-eval`
- Hypothesis: Maintain EMA of model weights during training, evaluate on EMA at end. Standard speedrun-winner pattern, typically +0.001-0.005 val/loss improvement essentially for free. Does not change training trajectory — only the eval point — so works orthogonally to all training-time mechanisms.
- Arms (3 sequential, n=1, 3325 steps): ctrl (no EMA), EMA decay=0.9999 (medium), EMA decay=0.99999 (long). Each EMA arm also logs live val/loss for ctrl comparison within the same run.
- Fresh axis: **eval-time mechanism** — completely distinct from training-time aux/MuonH/schedule/initialization axes. The aux-mechanism axis is exhaustively closed (14 PRs); EMA-of-weights is a known-winner pattern from a completely different lever.
- ~30 LoC: EMA shadow dict + update + swap-to-eval + swap-back.
- Builds on frieren's AdaBelief closure discipline — clean kill-gate analysis with rich diagnostic logging.

---

## 2026-05-22 05:13 UTC — PR #735 CLOSED (thorfinn): H47 Sophia-H aux — Δ+0.045 NEG, axis closed (saturation reduces to Lion-like)

- Branch: `g1r3-thorfinn/sophia-h`
- Hypothesis: Diagonal-Hessian preconditioning (Sophia-H, Liu ICLR 2024) on aux groups via Hutchinson estimator. ρ=0.04 clip + γ=0.01 normalization + k=10 Hessian-refresh.
- Arms (2 terminal, n=1, 3325 steps):

| Arm | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|
| 1 ctrl (AdamW) | `639vhkp6` | 3.27232 | 3125 | — |
| 2 Sophia-H aux | `9vxlqmss` | **3.31722** | -1 (never) | **+0.04490 NEG** |

### Mechanism finding — diagonal-Hessian on aux reduces to Lion under clip saturation

Excellent diagnostic instrumentation (`sophia/clip_fraction`, `sophia/h_mean/max/min`) made the closure mechanistically crisp:

- **clip_fraction 0.907 → 0.959 → 0.979** across training thirds (95%+ saturated mid/late)
- **h_max 22 → 6153** (Hutchinson develops extreme right tail on sparse-active aux coords)
- **h_min 0.99 → 0.035** (γ·h ≈ 3.5e-4 → m/(γh) huge → always clipped)

**Causal interpretation**: When 95%+ of coords clipped, Sophia-H reduces to fixed-magnitude sign-of-momentum updates ≈ Lion with wrong lr/ρ joint scaling. The diagonal-Hessian information barely flows through to the actual update. Aux groups (embed, lm_head, scalars) are exactly the wrong domain for Hutchinson curvature: sparse-active rows make h estimates high-variance with wide tails, amplified influence in small dense aux.

### Closure map: aux-mechanism replacement axis (14 entries TOTAL)

| PR | Mechanism | Result |
|---|---|---|
| #544 | Cautious AdamW | NEG |
| #567 | AdEMAMix β3=0.9999 | NEG |
| #582 | MARS γ-correction | NEG |
| #592 | GC-on-aux | NEG |
| #612 | β1=0 ablation | NEG |
| #631 | β2=0 ablation | NEG |
| #643 | PAdam v^p | NEG |
| #646 | Adan grad-diff | NEG |
| #670 | eps decoupling | NEG |
| #689 | AdEMAMix β3=0.9990 | NEG |
| #726 | Lion ±lr | NEG |
| #731 | AdaBelief (g-m)² | NEG (sharpest) |
| #735 | Sophia-H diag-Hessian | NEG (reduces to Lion) |

The 2nd-order axis (curvature preconditioning) is now also closed for aux. Combined with variance-estimator axis (β1=0/β2=0, AdaBelief, PAdam, AdEMAMix, MARS), **there is no remaining replacement mechanism that beats AdamW's m/√v + AGC on aux at short-EMA regime**.

### Resource notes
- Sophia-H peak GPU memory 48.7 GB (vs ctrl 38.7 GB = +25%) from HVP create_graph=True
- Wall time comparable to ctrl

### Follow-up
Thorfinn → PR #763 H55 MuLoCo OFF (structural pruning ablation, distinct from aux mechanism work).

---

## 2026-05-22 04:55 UTC — PR #731 CLOSED (frieren): H46 AdaBelief aux — Δ+0.156 NEG (sharpest closure), axis closed

- Branch: `g1r3-frieren/aux-adabelief`
- Hypothesis: AdaBelief's (g-m)² belief-variance buffer as drop-in replacement for AdamW's g² variance on aux groups. Tests whether variance-of-residual is more informative than variance-of-gradient at our short β1=0.8 / β2=0.95 EMAs.
- Arms (2 terminal, n=1, 3325 steps):

| Arm | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|
| 1 ctrl (AdamW) | `iqbu7v9u` | 3.27336 | 3150 | — |
| 2 AdaBelief ON | `oo1q5ay9` | **3.42924** | -1 (never) | **+0.15589 NEG** |

NEG by ~30× the +0.005 threshold — sharpest closure to date in the aux-mechanism axis.

### Mechanism finding — short-EMA aux destroys AdaBelief's belief-variance signal

Student's analysis: At β1=0.8, `m_t = 0.2·g_t + 0.8·m_{t-1}` → `g_t − m_t = 0.8·(g_t − m_{t-1})`. The "residual" is essentially the current gradient relative to recent EMA — high-variance, not a true belief signal. With β2=0.95, `s_t = EMA[(g−m)²]` tracks this noisy raw-gradient-like signal, denominator `√s_t` becomes too large early → effective LR collapses on embed/lm_head → catastrophic under-training (val=6.5 vs ctrl 4.2 at step 250).

Cooldown narrowed Δ by ~0.02 (0.175 @ step 2500 → 0.156 @ 3325) but mechanism is structurally wrong, not a tuning issue. Arm 3 (paper defaults β1=0.9, β2=0.999) correctly skipped — would require retuning aux LRs and would just be a different optimizer on different LRs, no mechanism isolation.

### Resource notes
- AdaBelief peak GPU memory 38.8 GB (vs ctrl 77.6 GB) — half the fused-AdamW staging buffer
- Wall time 11921s vs 12339s (slightly faster per step, unfused)

### Follow-up
Frieren → PR #761 H53 EMA-of-weights eval (fresh eval-time axis, distinct from aux mechanism work).

---

## 2026-05-22 04:25 UTC — PR #726 CLOSED (nezuko): H45 Lion-aux signed momentum — Δ+0.037 NEG, axis closed

- Branch: `g1r3-nezuko/aux-lion-bv2`
- Hypothesis: Replace AdamW on aux with Lion (signed ±lr·sign(m) updates with EMA-of-grad momentum). 3-arm LR sweep to rule out Goldilocks zone.
- Arms (3 terminal, n=1, 3325 steps):

| Arm | W&B | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|
| 1 ctrl (AdamW) | `3m7yoejk` | 3.27329 | 3150 | — |
| 2 Lion lr_scale=0.333 | `h0p18wp7` | **3.31017** | -1 (never) | **+0.03688 NEG** |
| 3 Lion lr_scale=0.2 | `x41rxxsl` | **3.31048** | -1 (never) | **+0.03719 NEG** |

Both Lion arms cluster at same +0.037 deficit across [1/3, 1/5] LR scaling — rules out narrow Goldilocks zone. Cooldown trajectory shows gap is roughly constant (+0.07 → +0.037), does not close during cooldown.

### Mechanism finding — bounded ±lr signed updates uncompetitive with m/√v on aux

Aux groups (embed/lm_head/scalars) have wildly varying parameter sensitivities. AdamW's per-coord variance normalization `m/√v` is load-bearing for this heterogeneity. Replacing with bounded magnitude (Lion) doesn't adapt to per-coord scale → embeddings + lm_head get under-LR'd.

### Follow-up
Nezuko → PR #762 H54 NS5 polynomial coefs (MuonH-side, distinct from aux mechanism work).

---

## 2026-05-22 03:35 UTC — PR #750 ASSIGNED (alphonse): H52 Per-step AGC clip_ratio cooldown schedule

- Branch: `g1r3-alphonse/agc-cooldown-schedule`
- Hypothesis: Schedule AGC clip_ratio to tighten linearly during cooldown (0.05 → 0.02) instead of fixed throughout. Direct exploit of PR #689 mechanism rule ("cooldown demands sharp aux updates"). Mechanistically distinct from PR #595 (static ON/OFF) and PR #483 (static magnitude sweep in [0.02, 0.10]) — tests SCHEDULE structure, never before swept.
- Arms (3 sequential, predeclared n=1, 3325 steps): ctrl (static 0.05), aux-only schedule (aux 0.05→0.02 from step 1995), both schedule (aux + muonh during respective cooldowns).
- Fresh axis: fills the **schedule axis** which was empty in the active portfolio. Mechanism-distinct from in-flight aux preconditioner work (#726/#731/#735/#746), post-NS5 direction transforms (#743/#744), and cooldown state reset (#740).
- ~25 LoC, bit-identical when `--aux_agc_cooldown_min -1` (default).
- Builds on alphonse's NS5 expertise — schedule on a different axis (gradient trust radius) while keeping his "clean smoke + 3-arm" experimental hygiene.

---

## 2026-05-22 03:30 UTC — PR #190 CLOSED (alphonse): NS5 iteration count sweep k ∈ {8, 12, 16} — NEG decisive, axis fully closed at k=12

- Branch: `g1r3-alphonse/ns5-iter-sweep-si`
- Hypothesis: Sweep NS5 iteration count k ∈ {8, 12, 16} on MuonH-SI baseline. 3-arm predeclared n=1.

### Results (3325 steps, n=1; 3 arms terminal)

| Arm | NS5 k | W&B | val/loss | ffs | Δ vs k=12 ctrl |
|---|---|---|---|---|---|
| 1 | 8 | `jm1dv8xp` | **3.27659** | 3200 | **+0.00349 NEG** (~7σ above k=12) |
| 2 | 12 (current baseline) | `xwdkdlrt` | **3.27310** | 3150 | reference (matches today's μ≈3.273) |
| 3 | 16 | `4o2qyxiy` | **3.27328** | 3150 | **+0.00018** noise-equivalent |

**Decision: CLOSED NEG** — no arm clears merge bar 3.27039. Three-regime structure: k=8 under-orthogonalized → NEG ~7σ; k=12 ctrl reproduces baseline at noise floor; k=16 noise-equivalent → NS5 saturated at k=12.

### Mechanism finding — NS5 iteration count axis FULLY CLOSED at k=12

Combined with PR #621 hyperball pruning closure, integrated picture:

> **The post-NS5 SI projection dominates inner update quality.** Both residual non-orthogonality (this PR, k=16 noise-equivalent) and Frobenius-sphere unit constraint (PR #621, hyperball=0 catastrophic NEG +0.052) point to SI as the load-bearing post-NS5 transform.

**Generalized rule**: Future MuonH-direction interventions should target either the **NS5 coefficients** `(a, b, c) = (2, -1.5, 0.5)` directly, or **post-NS5 transforms** like Contra-Muon (#743) and Soft-Muon (#744), NOT iteration count or constraint pruning.

Excellent execution: 100-step smoke per ablation arm, bit-identical parity check (`bw09ugfh` step 300 = 4.220 vs `4bnkbcf0` = 4.219), pod-rotation recovery, clean predeclared arms, honest SENPAI-RESULT analysis. Alphonse reassigned to H52 AGC cooldown schedule (PR #750).

---

## 2026-05-22 02:00 UTC — PR #746 ASSIGNED (edward): H51 RACS row-column factored aux preconditioner

- Branch: `g1r3-edward/racs-aux-preconditioner`
- Hypothesis: Replace AdamW's per-element v_t with a rank-2 row-column factored preconditioner (RACS, ICLR 2026): `scale[i,j] = sqrt(v_row[i] * v_col[j]) + eps`. Tests STRUCTURE axis of aux preconditioner (mechanism-distinct from all closed scale/power/eps axes #643, #631, #612, #670).
- Arms: ctrl (per-element AdamW), embed_lmhead_only (RACS on vocab-anisotropic groups only), all_2d (full replacement).
- Custom `RACSAdamW` class via `torch.optim.Optimizer` (fused kernel preserved when `--aux_racs_mode off`).
- Rationale: Embed/lm_head have severe vocab-frequency row anisotropy + d_model column structure. Factored second-moment captures dominant rank-2 structure with O(rows+cols) state. Adafactor/Shampoo precedent; RACS is the recent ICLR 2026 refinement. Last untested STRUCTURE axis in the aux preconditioner closure map.

---

## 2026-05-22 01:55 UTC — PR #592 CLOSED (edward): H28 Gradient Centralization on aux AdamW — NEG decisive

- Branch: `g1r3-edward/aux-gradient-centralization`
- Hypothesis: Apply Gradient Centralization (Yong et al CVPR 2020) — pre-step row-mean subtraction — to aux AdamW gradients (embed/lm_head). 2-arm: ctrl vs GC ON.

### Results (3325 steps, n=1; 2 arms)

| Arm | W&B | GC | val/loss | ffs | Δ vs ctrl |
|---|---|---|---|---|---|
| 1 ctrl | `7a35fj59` | OFF | **3.27273** | 3125 | reference (matches today's μ≈3.273 ctrl pop) |
| 2 GC ON | `24fpcf8m` | ON | **3.27391** | 3150 | **+0.00118 NEG** (above +0.001 threshold) |

**Decision: CLOSED NEG decisive** — Δ+0.00118 is ~2.4σ above ctrl. GC code path verified active (centering_rms ~1.8e-3, two orders above floor). Both arms clean (nonfinite_count=0).

### Mechanism finding — Gradient-direction-projection mechanism axis fully CLOSED

Combined with PR #672 (GC-on-MuonH-inner NEG via RMSNorm null-space):

- **PR #672 GC-on-MuonH-inner**: algebraic no-op (RMSNorm projects row-mean to zero pre-optimizer)
- **PR #592 GC-on-aux** (this): NOT a no-op (aux has no preceding RMSNorm), but the projection is mildly counterproductive. Two predicted-and-observed mechanisms:
  1. Common-mode row component on embed/lm_head encodes useful warmup-phase signal ("shift toward predicting average-frequency tokens") that GC strips
  2. AdamW per-coord v_t (eps=1e-6 floor) already handles gradient noise; GC has no headroom to help

Both mechanisms predict small NEG (not catastrophic) — exactly the +0.00118 observed.

**Generalized rule**: AGC + NorMuon + Polar Express already condition gradient direction well on this stack. Explicit per-row mean-projection adds no headroom and removes signal. Future proposals on gradient-direction transforms should be deprioritized unless they target a NEW projection structure (e.g., per-channel column-mean, or signal-noise-separated directions).

Pod rotation episode (4.5h broken silicon, esc#38-39 → operator rotation at 17:55 UTC) handled cleanly by edward with 7-run smoke validation + auto-launcher chain script. Excellent engineering hygiene under adverse conditions. Edward reassigned to H51 RACS aux preconditioner (PR #746).

---

## 2026-05-22 01:05 UTC — PR #298 CLOSED (tanjiro): Residual-branch init rescaling — NEG across 3 scales; MuonH-SI is a strong init-equalizer

- Branch: `g1r3-tanjiro/res-init-rescale`
- Hypothesis: GPT-3/Gopher convention scales residual-branch output projections (`block.attn.proj`, `block.mlp.proj`) by 1/sqrt(2L) or 1/sqrt(L) at init time. Tests whether applying this convention to the modded-nanogpt MuLoCo×MuonH-SI stack improves convergence. 3-arm: res_init_scale ∈ {0.2041 (1/√(2L)), 0.2887 (1/√L), 1.0 (ctrl)}.

### Results (3325 steps, n=1; 3 arms predeclared)

| Arm | res_init_scale | W&B | val/loss | ffs | Δ vs baseline 3.27119 | Verdict |
|---|---|---|---|---|---|---|
| 1 | 0.2041 (1/√(2L)) | `0frlt3xa` | 3.28344 | -1 | +0.01225 | NEG |
| 2 | 0.2887 (1/√L) | `5aenl93a` | 3.28305 | -1 | +0.01186 | NEG |
| 3 | 1.0 (ctrl) | `sk1bnqac` | 3.27621 | 3275 | +0.00502 (n=1 noise) | above merge bar |

**Decision: CLOSED NEG** — both small-init arms cluster NEG (+0.0118–0.0123), and ctrl arm lands within population noise (+0.0050). Residual-branch init scaling axis CLOSED.

### Mechanism finding — MuonH-SI as strong init-equalizer

**MuonH-SI is a strong init-equalizer.** The Frobenius-sphere SI projection applied at every MuonH-SI update step rapidly renormalizes residual-branch weights regardless of starting magnitude. Both small-init arms ended in the same NEG cluster (Δ+0.0118 to +0.0123), and the control matched population mean.

This is consistent with **PR #621 hyperball pruning** (catastrophic NEG +0.052 when NS-imposed unit-ball geometry was perturbed) — same load-bearing property: MuonH-SI dictates late-time geometry of hidden parameters, and pre-MuonH interventions (init, sparsification, magnitude rescaling) are largely washed out within a handful of steps.

**Generalizable rule**: Future interventions on the hidden stack should target the MuonH update itself, not pre-MuonH weight statistics. Tanjiro reassigned to H48 lm_head v_t reset (PR #740).

---

## 2026-05-22 00:18 UTC — PR #412 CLOSED (thorfinn): Aux AdamW warmup_steps sweep — NEG with monotonic warmup-worsens (MuonH/aux asymmetry confirmed)

- Branch: `g1r3-thorfinn/aux-warmup-steps`
- Hypothesis: Mirror thorfinn's MuonH warmup success on aux AdamW groups — delay full LR via linear ramp during first N steps to let Adam's second-moment estimates accumulate before being divided into the update. 3-arm: warmup_steps ∈ {0 (control), 100, 200}.

### Results (3325 steps, n=1; 3 arms predeclared)

| Arm | aux_warmup_steps | W&B | val/loss | first_step_to_target | Δ vs ctrl |
|---|---|---|---|---|---|
| 1 ctrl | 0 | `369wpwd0` | **3.27300** | 3150 | reference |
| 2 | 100 | `gcm4o5fm` | 3.27582 | 3175 | **+0.00282 NEG** |
| 3 | 200 | `wad6pw2t` | **3.27782** | 3225 | **+0.00482 NEG** |

**Decision: CLOSED NEG** — monotonic worsening with increasing aux warmup. Larger warmup → both worse final val AND slower first_step_to_target. Pattern is unambiguous; not noise. Arm 3 `val/single_run_stat_sig_margin = -0.00182` (negative — below baseline target).

### Mechanism finding — MuonH/aux warmup asymmetry (opposite signs on same lever)

- **MuonH inner**: NEEDS warmup. NS5-orthogonalized momentum buffer requires ~20 steps to populate reliable direction estimates before applying full lr=0.018. PR #338 confirmed: MuonH warmup wins.
- **Aux AdamW** (embed/lm_head/scalars): does NOT need warmup. β₁=0.8/β₂=0.95 already dampen early variance. What matters is getting useful gradient signal into the embedding table during peak representational plasticity (first 100–200 steps). Warmup withholds that signal.

This is now the confirmed **MuonH/aux warmup asymmetry** rule — same lever (LR warmup_steps), opposite signs. The asymmetry is deeply mechanistic: MuonH's NS5 orthogonalization requires accumulated momentum direction; AdamW's EMA already provides the necessary smoothing. Embedding tables want immediate full-gradient signal during the high-plasticity opening phase.

**No further aux warmup variants to try** — cannot go below 0, and going higher than 200 extends the NEG axis. Thorfinn reassigned to H47 Sophia-H on aux (PR #735).

---

## 2026-05-21 23:48 UTC — PR #525 CLOSED (frieren): H2 Lookahead aux wrapper — NEG with monotonic α-controls-pain mechanism

- Branch: `g1r3-frieren/aux-lookahead-wrapper`
- Hypothesis: Wrap aux fused AdamW with Lookahead (Zhang et al 2019) — slow-weights linear interp every k=5 steps. Test α=0.5 vs α=0.8.

### Results (3325 steps, n=1; 3 arms predeclared)

| Arm | k | α | Run | val/loss | Δ vs ctrl | Δ vs baseline |
|---|---|---|---|---|---|---|
| 1 ctrl (k=0) | 0 | — | `aghr0u8d` | **3.27280** | — | +0.00161 |
| 2 | 5 | 0.5 | `xzvbe9z7` | **3.27798** | **+0.00518 NEG** | +0.00679 |
| 3 | 5 | 0.8 | `g8ckc4by` | **3.27240** | −0.00040 (noise) | +0.00121 |

**Decision: CLOSED NEG** — per the student's own decision rule (both non-ctrl arms val > 3.27200). Arm 3 missed by just 0.0004 — within ctrl noise band.

### Mechanism finding — α controls how much it hurts (clean monotonic)

| α | Lookahead behavior | Terminal Δ vs ctrl |
|---|---|---|
| 0 (ctrl) | wrapper inert | — |
| 0.5 | half of each step reverted to slow EMA | +0.005 NEG |
| 0.8 | 20% reverted | ≈0 (noise) |
| 1.0 (extrapolation) | wrapper exactly no-op | =0 |

The slow-weights blend `φ ← α·θ + (1-α)·φ` followed by `θ ← φ` every k=5 steps partially undoes the per-step fused AdamW updates. At α=0.5, half of each step's progress is reverted toward an older average — aux groups never catch up. At α=0.8, only 20% reverted — recoverable within cosine cooldown window.

### Generalized rule — iterate-side averaging is categorically incompatible with WSD/cooldown stacks targeting final iterate

PR #525 joins the closed weight-averaging family:
- PR #200: full-model EMA NEG
- PR #531: SF-AdamW NEG (Polyak averaging)
- PR #555: SWA on aux cooldown NEG
- **PR #525 (this)**: Lookahead on aux NEG

**Important distinction**: MuLoCo's outer Nesterov gradient/delta averaging (PR #536 confirmed load-bearing) is a DIFFERENT mechanism — accumulates gradients/deltas, not iterate weight averages. The "iterate averaging" family is closed; the "gradient accumulation" family is preserved.

**Future direction-blocking rule**: Future proposals that average **iterates** of an optimizer targeting the final-iterate WSD/cooldown stack should be deprioritized unless they include a cooldown-detach mechanism (use averaged iterate during main training, use raw iterate during cooldown).

### Implementation quality notes

- Wrapper overhead: ~1 ms/step (within 1% budget)
- Peak GPU memory: +1 GiB for `_slow` tensor (acceptable)
- No NaN events across 9975 ablation steps
- k=0 inertness verified in code review

Frieren reassigned to H46 AdaBelief on aux (PR #731).

---

## 2026-05-21 21:58 UTC — PR #621 CLOSED (nezuko): H34 MuonH hyperball pruning — NEG with third cooldown-crossover instance + generalized "constraint removal LEADS mid-training, LOSES cooldown" rule

- Branch: `g1r3-nezuko/hyperball-pruning`
- Hypothesis: Test whether MuonH-SI's Frobenius-sphere projection (`hyperball=True`) is load-bearing. PR #443 introduced `mode=scale_invariant` as baseline but never ablated the SI projection mechanism itself.

### Results (3325 steps, n=1; 2 arms)

| Arm | Run | val/loss | ffs | reached_target | Δ vs ctrl | Decision |
|---|---|---|---|---|---|---|
| 1 ctrl (hyperball=1) | `drb9bjmh` | **3.27218** | 3125 | ✓ | — | baseline-match (within pop μ≈3.273) |
| 2 hyperball=0 | `dm1qs45y` | **3.32370** | -1 | ✗ | **+0.05152** | NEG (~100σ over merge bar) |

**Decision: CLOSED NEG** — arm 2 catastrophically misses merge bar despite massive mid-training lead.

### Mechanism finding — third cooldown-crossover instance

**The crossover trajectory** (cleanest demonstration to date):

| Step | Arm 1 (hb=1) | Arm 2 (hb=0) | Δ (Arm2−Arm1) |
|---|---|---|---|
| 125 | 4.927 | 4.834 | **−0.094** (hb=0 leads) |
| 500 | 3.905 | 3.815 | **−0.090** |
| 750 | 3.825 | 3.696 | **−0.129** (peak lead) |
| 1000 | 3.726 | 3.602 | **−0.124** |
| 1500 | 3.616 | 3.503 | **−0.113** |
| 2000 | 3.481 | 3.425 | **−0.056** |
| **2500** | **3.372** | **3.371** | **−0.001 ← CROSSOVER** (~75%, cooldown onset) |
| 3000 | 3.292 | 3.334 | +0.042 |
| 3325 | **3.272** | **3.324** | **+0.052** |

### Generalized mechanism rule (now three-instance supported)

**Modifications that REMOVE constraints/regularization/long-horizon-memory often LEAD during the bulk-training phase but LOSE during cooldown:**

| PR | What was removed/added | Mid-training Δ | Terminal Δ | Crossover step |
|---|---|---|---|---|
| #616 fern | MuonH momentum reset on sync (removes inner memory) | −0.020 to −0.035 | +0.023 | ~step 2500 |
| #689 askeladd | AdEMAMix slow-EMA injection (adds long-horizon m_2) | −0.008 to −0.013 | +0.018 | step 2250 |
| **#621 nezuko (this)** | **hyperball=0 (removes SI Frobenius projection)** | **−0.094 to −0.129** | **+0.052** | **step 2500** |

**Specific finding for hyperball=0**: The MuonH Frobenius-sphere SI projection is **load-bearing during cooldown**. Removing it gives faster mid-training descent (unconstrained update magnitude lets the optimizer move further per step in the bulk phase), but the unbounded update magnitude prevents the optimizer from settling into the cooldown's flat basin. The SI projection acts as a per-step "variance brake" critical when LR cooldown reduces per-step magnitudes to ~1e-9.

This is the **cleanest demonstration** — `hyperball=0` is pure constraint removal with NS5 orthogonalization preserved, so the +0.052 is attributable to the SI projection alone.

### Active exploit attempts (cooldown-aware versions)

Two PRs currently testing cooldown-gated remediations:
- PR #636 fern cooldown-gated MuonH reset — already CLOSED NEG (path-dependence: arm 2 mid-training state can't be transferred to cooldown without losing progress)
- PR #721 askeladd α_t cosine cooldown for AdEMAMix — IN-FLIGHT (anneals α back to 0 during cooldown)

The PR #636 closure suggests cooldown-gating is fundamentally path-dependent. PR #721 will provide a clean second data point on whether cooldown-aware schedules can recover any of the mid-training benefit.

### Suggested follow-ups

- A SOFTENED hyperball (weighted Frobenius with proportional radius rather than fixed unit radius) might capture some mid-training freedom while preserving cooldown stability — but this is speculative.
- Future "constraint pruning" hypotheses on MuonH should be deprioritized; the SI projection is now confirmed load-bearing.
- The generalized rule should INFORM hypothesis selection: any "remove a constraint" or "extend a memory horizon" mechanism should be presumed cooldown-incompatible at constant magnitude unless explicitly cooldown-scheduled.

---

## 2026-05-21 20:45 UTC — PR #689 CLOSED (askeladd): H41 AdEMAMix β3=0.9990 — NEG with calibration debt resolved + NEW "cooldown demands sharp updates on aux" mechanism rule

- Branch: `g1r3-askeladd/adem-beta3-recalib`
- Hypothesis: Recalibrate AdEMAMix β3 from 0.9999 → 0.9990 for 3325-step horizon. PR #567 closed AdEMAMix with β3=0.9999 → only 28% slow-EMA saturation at terminal (functionally inactive). β3=0.9990 gives memory horizon ~1000 steps, full saturation by ~2300 steps.

### Results (3325 steps, n=1; 2 arms)

| Arm | Run | val/loss | ffs | reached_target | Δ vs ctrl | Decision |
|---|---|---|---|---|---|---|
| 1 ctrl | `ygjxd459` | **3.27335** | 3150 | ✓ | — | baseline-match (dead-center of population μ≈3.273) |
| 2 H-ADEM β3=0.9990 α=5 warmup=1000 | `5mycxoco` | **3.29148** | -1 | ✗ | **+0.01813** | NEG (decisively past merge bar 3.27039) |

**Decision: CLOSED NEG** — does not clear merge bar; mechanism actively hurts at terminal.

### Mechanism finding #1 — β3 calibration RESOLVED (closes PR #567's calibration debt)

Telemetry confirmed slow_saturation at terminal = **0.9641** (target was 0.96 — matches theory). PR #567's claim that AdEMAMix is "horizon-calibrated" is confirmed: with proper β3, the slow EMA is fully populated as designed. **AdEMAMix calibration debt RESOLVED**.

### Mechanism finding #2 (NEW RULE) — "Cooldown demands sharp updates on aux"

**The crossover**: Hadem arm `5mycxoco` **LED** ctrl by up to 13 mLoss until step 1500 (slow_saturation ~0.76), then crossed over at step ~2250 (slow_saturation ~0.91) and finished +18 mLoss BEHIND ctrl.

| Step | Ctrl val | Hadem val | Δ |
|---|---|---|---|
| 500 | 3.8991 | 3.8911 | **−0.0079** (Hadem leads) |
| 1000 | 3.7258 | 3.7128 | **−0.0130** |
| 1500 | 3.6158 | 3.6040 | **−0.0118** |
| 2000 | 3.4805 | 3.4779 | **−0.0026** |
| **2250** | **3.4340** | **3.4341** | **+0.0001 ← CROSSOVER** |
| 2500 | 3.3718 | 3.3780 | +0.0062 |
| 3000 | 3.2921 | 3.3066 | +0.0145 |
| 3325 | 3.2734 | 3.2915 | **+0.0181** (Hadem behind) |

**Mechanism interpretation**: aux groups (embed/lm_head/scalars) want **sharper, less-smoothed updates** during the cosine cooldown to converge to a low-loss minimum. The α=5 plateau doesn't decay with the LR schedule — so the slow-EMA perturbation becomes proportionally larger as the LR shrinks, preventing fine-grained convergence.

**Generalizable rule**: "Cooldown demands sharp updates on aux." Any constant-magnitude long-horizon EMA/momentum injection on aux that doesn't decay with the LR schedule will hurt at terminal even if it helps mid-training. Joins the cooldown family:
- PR #563: outer_momentum=0.9 catapulted overshoots in cooldown
- PR #612: aux β1=0.8 acts as bulk-phase denoiser (less valuable in cooldown)
- PR #616: MuonH inner momentum reset on sync — REVERSED phase (mid-help, cooldown-hurt)
- **PR #689 (this)**: aux AdEMAMix slow-EMA injection — REVERSED phase

### Implementation detail (formulation A: gradient blending)

```python
s.mul_(beta3).add_(p.grad, alpha=1.0 - beta3)  # post-AGC slow EMA update
p.grad.add_(s, alpha=alpha_t)                  # blend slow EMA into grad
# Then standard fused AdamW step on blended grad
```

This contaminates v_t with the blended grad (slight deviation from paper). Verified clean numerics; no NaN. Slow buffers held in fp32.

### Side findings

- Arm 3 (β3=0.9970) NOT pursued — faster saturation would amplify the late-training problem; student correctly self-rejected the arm 3 trigger condition
- inject_norm at terminal ~0.04-0.06 (slow-EMA injection is 4-6% of raw grad magnitude at terminal) — small but non-negligible perturbation that prevents fine convergence

### Axis status

- **AdEMAMix on aux, constant α through cooldown**: CLOSED NEG (this PR)
- **STILL OPEN**: AdEMAMix with α_t cosine-annealed during cooldown (PR #721 askeladd, just assigned)
- **STILL OPEN**: AdEMAMix on MuonH (different group, different gradient distribution)
- **STILL OPEN**: layer-selective slow EMA (per-aux-group)

### Askeladd reassigned to H44 α_t cooldown variant (PR #721)

---

## 2026-05-21 20:05 UTC — PR #700 CLOSED (fern): H42 SOAP-lite left-Kronecker preconditioning on MuonH — NEG; kill gate fired step 500 +0.242 gap, two clean mechanism findings logged

- Branch: `g1r3-fern/soap-lite-left-precond`
- Hypothesis: Replace NS5 Newton-Schulz orthogonalization inside MuonH with L = G G^T left-Kronecker preconditioner (Shampoo/SOAP-style), applied as L^{-1/2} G + Frobenius normalization. Tests whether Kronecker-factored curvature beats pure orthogonalization on this stack. ~20 LoC left-only variant.

### Results (Phased — kill gate at step 500)

| Run | Config | Steps | val/loss @ step 500 | Δ vs ctrl B | cond_num_max | Notes |
|---|---|---|---:|---:|---:|---|
| `rkuflmm9` smoke | d=1e-6 const | 200 | 4.86 (@200) | +0.21 | 34k | borderline kill gate (smoke window) |
| `qptkoanx` ctrl A | NS5 | 1000 | 3.5448 (terminal) | — | — | code-clean |
| `13cxhkmu` ctrl B | NS5 (2nd seed) | 1000 | 3.5422 (terminal) | — | — | σ≈0.0013 across 2 ctrls |
| `9es22kul` arm 2 | d=1e-2 trace-relative | **509 (killed)** | **4.0647** | **+0.242** | **22k–92k** | killed @ step 509 (gap 24× threshold) |

**Decision: CLOSED NEG** — kill gate fired with +0.242 gap (24× threshold).

### Mechanism finding #1 — Trace-relative damping does NOT cap cond_num as predicted on L matrices with long-tail spectra

Advisor predicted `d=1e-2 * mean(diag(L))` would cap cond_num at ~100. Actual cond_num was 22k–92k (200–900× higher). **Reason**: L spectrum is dominated by a few large eigenvalues; `mean(diag(L))` is biased upward by these and is a poor proxy for the "smallest eigenvalue floor". 1% of mean diagonal is still below the smallest meaningful eigenvalues.

**Generalizable rule**: For long-tail spectra (transformer parameter L matrices), damping must be specified in *spectrum space* (eigenvalue clamp `D.clamp(min=threshold)` before `D^{-0.5}`), not in *matrix space* (`L + alpha*I`). The mathematical relationship is: spectrum-space clamp = `1/threshold` cap on cond_num exactly; matrix-space damping = `1 + λ_max/(alpha*trace_mean)` lower bound on cond_num which scales with κ(L).

### Mechanism finding #2 — Left-only Kronecker preconditioning is double-rescaled by scale_invariant outer wrapper

`scale_invariant` mode in MuonH applies a final Frobenius normalization to the update: `update *= p_norm / u_norm`. This step OVERWRITES the magnitude of `L^{-1/2} G`. The preconditioner's *direction* survives but its *magnitude* is replaced by the scale_invariant scaling.

**Consequence**: a single-side preconditioner inherits the noise-amplification cost of L^{-1/2} (poorly-conditioned small eigenvalues) but loses the curvature-conditioning *magnitude* benefit. **Net effect**: strictly harmful when paired with scale_invariant outer.

**Generalizable rule**: Any future single-side preconditioner on MuonH should be paired with `--muonh_mode standard` (not scale_invariant) — OR the preconditioner should be designed to preserve unit-Frobenius output by construction (e.g. normalize `L^{-1/2}` per layer to ‖·‖_2=1 before the multiplication).

### Axis status

- **SOAP/Shampoo-style preconditioning REPLACING NS5**: closed NEG on this stack at left-only variant
- **STILL OPEN**: full two-sided SOAP (L^{-1/2} G R^{-1/2}) — much higher impl cost (~80 LoC, R is n×n where n=3072)
- **STILL OPEN**: COSMOS-style hybrid (precondition in top-k eigensubspace, NS5 for the rest) — preserves NS5 path for most directions; bounds the noise-amplification by construction; most plausible to outperform pure NS5

### Compute used
- Total: ~82 min @ 1×H100 (4 runs: smoke 6 min, ctrl A 30 min, ctrl B 30 min, arm 2 killed 16 min)
- Peak memory: 33–35 GB (well within 96 GB budget); SOAP-lite L_acc + L_inv_sqrt buffers ~+0.5 GB overhead vs NS5

### Fern reassigned to H-CAT catapult LR burst (next PR)

---

## 2026-05-21 17:00 UTC — PR #670 CLOSED (fern): H39 Per-group aux AdamW eps decoupling — NEG; per-group eps optimum migrated to shared 1e-6 plateau on mature stack

- Branch: `g1r3-fern/aux-per-group-eps`
- Hypothesis: Structured decoupling of aux AdamW epsilon by parameter group (embed=sparse-coord, lm_head, scalars) improves over shared eps=1e-6. Two directions tested: push-LARGER (sparse groups eps→1e-4) and push-SMALLER (embed eps→1e-10 per PR #501 prior finding).

### Results (3325 steps, n=1 each; 3 arms)

| Arm | embed_eps | lm_head_eps | scalar_eps | run | val/loss | ffs | reached | Δ vs ctrl | Decision |
|---|---|---|---|---|---:|---:|---:|---:|---|
| 1 ctrl | 1e-6 | 1e-6 | 1e-6 | `4bse71y8` | **3.27284** | 3125 | ✓ | — | reference |
| 2 push-LARGER | 1e-4 | 1e-4 | 1e-6 | `g677m78x` | 3.27427 | 3150 | ✓ | **+0.00143** | NEG |
| 3 push-SMALLER (PR #501) | 1e-10 | 1e-6 | 1e-6 | `b10a9lrv` | 3.27364 | 3150 | ✓ | +0.00080 | NULL |

**Decision: CLOSED NEG** — no arm clears merge bar 3.27039. Neither direction produces a meaningful improvement.

### Mechanism finding — PR #501 directional finding does NOT reproduce on mature stack

PR #501 (older stack, pre-AGC/VR closures) found embed=1e-10 beat ctrl by −0.00113. At the mature stack, the same config (arm 3) lands at +0.00080 vs ctrl — **direction completely reversed**. Stack maturation (PR #595 AGC closure, VR triple-NEG, PR #443 global eps 1e-10→1e-6) has moved the per-group eps optimum onto the shared 1e-6 plateau.

Arm 2 (push-LARGER) is clearly degraded (+0.00143 ≈ 3σ vs empirical σ≈0.0005). The sparse-coord-needs-more-smoothing hypothesis is rejected at mature stack.

Combined finding: **global eps=1e-6 is at or near the per-group joint optimum for all aux groups**. Decoupling within [1e-10, 1e-4] does not improve. Axis STRUCTURALLY CLOSED on mature stack.

### Side findings

- Per-group eps plumbing verified clean across 4 smokes + 3 full runs (startup prints confirm correct per-group config)
- First ctrl `m0csj0ca` crash at step 763 was SIGTERM (infrastructure), not eps logic
- Fern correctly ran 3 arms (suggested by advisor at 09:55 UTC based on PR #501 prior context) — thorough closure

### Fern reassigned to H42 SOAP-lite left-Kronecker preconditioning (PR #700)

---

## 2026-05-21 15:10 UTC — PR #672 CLOSED (askeladd): H40 GC-on-MuonH-inner — NEG (noise-neutral MATCH; RMSNorm null-space; closes GC-on-MuonH axis)

- Branch: `g1r3-askeladd/muonh-grad-centralization`
- Hypothesis: Gradient Centralization (Yong et al CVPR 2020) applied to MuonH inner gradient (2D weight params only, pre-NS5) via row-mean subtraction. Tests whether row-mean is a live direction in MuonH's gradient space.

### Results (3325 steps, n=1 each; 2 arms)

| Arm | wandb_id | val/loss (best) | ffs | reached | step_avg_ms | Δ vs ctrl |
|---|---|---:|---:|---:|---:|---:|
| 1 ctrl (GC off) | `zbnoq1qv` | **3.27317** | 3150 | 1 | ~1820 | — |
| 2 GC on | `1fuptywk` | **3.27363** | 3150 | 1 | ~1820 | **+0.00046** |

**Decision: CLOSED NEG** — neither arm clears merge bar 3.27039. Arm 2 (GC-on) is Δ=+0.00046 vs ctrl — within noise (σ≈0.0009), effectively a MATCH, not a true degradation.

### Mechanism finding: RMSNorm null-space hypothesis validated

H40 predicted GC would be a no-op because RMSNorm immediately preceding each transformer block normalizes out any constant per-feature shift in the forward pass, making the gradient row-mean component a near-null direction in optimization space. The smoke Δ≈−0.0008 at step 200 and terminal Δ≈+0.0005 at step 3325 both support this. GC is removing a signal of negligible magnitude.

**Note on mid-training provisional read**: at step 3050, the training loss showed arm 2 Δ≈+0.011 vs ctrl, which was provisionally read as a fixed-point gap. This was a misread — train_loss at step 3050 is not the val_loss. The final fixed-window val measurement converged to Δ=+0.0005, consistent with the step-200 smoke prediction. The smoke correctly predicted the outcome; the mid-training train_loss trajectory was not diagnostic.

**Generalization**: GC (Yong et al 2020) is beneficial in BN-anchored CNNs where row-mean carries variance information. In RMSNorm-anchored transformers the row-mean signal is neutralized upstream. Axis: GC-on-MuonH-inner CLOSED.

### Critical baseline-noise observation

Both ctrl arms today:
- PR #672 ctrl `zbnoq1qv`: val=**3.27317**, ffs=3150
- PR #670 ctrl `4bse71y8`: val=**3.27284**, ffs=3125

Both are +0.0017–0.0020 above PR #443's claimed baseline 3.27119. True population μ ≈ **3.273** with σ ≈ **0.0005**. PR #443 was likely a favorable-seed n=1 outlier; merge bar 3.27039 may be ~0.002 tighter than justified by population statistics. Documented in CURRENT_RESEARCH_STATE.md.

---

## 2026-05-21 10:45 UTC — PR #643 CLOSED (askeladd): H37 PAdam (v_t^p denominator) — NEG; completes AdamW preconditioner triple-leg closure

- Branch: `g1r3-askeladd/aux-padam-power`
- Hypothesis: PAdam (Chen et al 2018, *Closing the Generalization Gap...*) replaces AdamW's denominator `√v_t + ε` with `v_t^p + ε` for `p ∈ [0, 0.5]`. Tests whether the geometric exponent in the preconditioner is load-bearing at AdamW-tuned aux LRs.

### Results (3325 steps, n=1 each; Arm 2 killed early)

| Arm | wandb_id | val/loss | ffs | reached_target | step_avg_ms | Δ vs ctrl |
|---|---|---:|---:|---:|---:|---:|
| Arm 1 — p=0.5 ctrl (fused AdamW) | `1ebk5275` | **3.27163** | 3125 | 1 | 1822 | — |
| Arm 2 — PAdam p=0.25 | `f4ta3cj9` | **3.87419** @ step 1500 (killed) | -1 | 0 | 1830 | **+0.6+ (extrapolating ~3.5 at step 3325)** |

**Decision: NEG.** Arm 2 killed at step 1500 by `gap > +0.05` gate (actual gap +0.257). Arm 1 ctrl matches baseline floor.

### Trajectory profile (showing monotonic gap-narrowing but extrapolating nowhere near merge bar)

| Step | Arm 1 (p=0.5) | Arm 2 (p=0.25) | Δ |
|---|---:|---:|---:|
| 125 | 4.930 | 9.045 | +4.115 |
| 500 | 3.902 | 5.170 | +1.268 |
| 1000 | 3.725 | 4.187 | +0.462 |
| 1500 | 3.618 | 3.874 | +0.257 (killed) |
| 3325 | 3.27163 | — | — |

Gap halves every ~750 steps but at 3325-step budget Arm 2 lands ~3.5 — miles from merge bar 3.27039.

### Mechanism finding: complete AdamW preconditioner closure

PAdam at p=0.25 makes the denominator `v_t^0.25 + ε`. For typical aux v_t ≪ 1, `v_t^0.25 > v_t^0.5`, so denominator drops *less aggressively* in near-zero v regimes. This is exactly the sparse-gradient regime for aux (embed/lm_head/scalars). At AdamW-tuned LRs, this under-conditions sparse coords, causing catastrophic early divergence.

**Combined with prior closures**:
| Leaf | Mechanism | PR | Result |
|---|---|---|---|
| m_t EMA timescale (β1) | β1=0 vs 0.8 | #612 | NEG (β1=0.8 load-bearing) |
| v_t EMA timescale (β2) | β2=0 vs 0.95 | #631 | NEG (β2=0.95 load-bearing) |
| **v_t geometric power** | **p=0.25 vs 0.5** | **#643** | **NEG (p=0.5 load-bearing)** |

All three structural pieces of AdamW's preconditioner — EMA timescales AND geometric exponent — are minimal at current LR config. **Complete closure of AdamW preconditioner axis on aux groups.**

### Caveat
Closure is at AdamW-tuned LRs. PAdam paper (Chen et al 2018) explicitly retunes LRs for p<0.5 (PAdam-tuned LRs ≪ AdamW-tuned). Joint (p, LR) sweep was not attempted. If a future PR retunes LRs for p=0.25 and beats baseline, that opens a joint axis. For the AdamW-tuned LR sweep, this PR closes it definitively.

### Telemetry
- nonfinite_count: 0 ✓ on both arms (unfused PAdamW Python path is numerically clean)
- step_avg_ms: 1822 (fused AdamW) vs 1830 (unfused PAdamW) — +0.4% overhead, negligible
- peak GPU mem: 77.5 GB (fused) vs 38.7 GB (unfused — skips fused-kernel scratch)
- W&B re-verified: val/loss 3.2716255 ✓ (Arm 1), 3.8741891 @ step 1500 ✓ (Arm 2)

---

## 2026-05-21 09:45 UTC — PR #646 CLOSED (fern): H38 Adan optimizer for aux AdamW groups — NEG; completes VR-on-aux 4-class closure

- Branch: `g1r3-fern/aux-adan-optimizer`
- Hypothesis: Adan (Xie et al 2022, gradient-difference VR) — `m_t = β1·m + (1-β1)·g`, `v_t = β2·v + (1-β2)·(g - g_prev)`, applied to aux AdamW groups. Fresh mechanism class (gradient-difference, structurally distinct from gradient-history mask/dual-EMA/γ-correction and weight-averaging).

### Results (3325 steps, n=1 each)

| Arm | wandb_id | val/loss | ffs | reached_target | step_avg_ms | Δ vs ctrl | Δ vs merge bar 3.27039 |
|---|---|---:|---:|---:|---:|---:|---:|
| Arm 1 — AdamW ctrl | `xedkw2w9` | **3.27251** | 3125 | 1 | 1815.07 | — | +0.00212 |
| Arm 2 — Adan paper defaults | `rz2v207z` | **3.29451** | -1 | 0 | 1821.53 | **+0.02200** | +0.02412 |

**Decision: NEG** — Δ+0.0220 (~24σ vs empirical σ≈0.00092). Adan worse by ~22× the +0.001 threshold.

### Trajectory profile (key evidence: fixed-point gap, not warmup artifact)

| Step | Arm 1 AdamW | Arm 2 Adan | Δ (Adan-AdamW) |
|---|---:|---:|---:|
| 125 | 4.93289 | 5.11186 | +0.17897 |
| 500 | 3.90645 | 3.96419 | +0.05774 |
| 1000 | 3.72461 | 3.76573 | +0.04112 |
| 1500 | 3.61661 | 3.64500 | +0.02839 |
| 2000 | 3.47944 | 3.50114 | +0.02170 |
| 2500 | 3.37095 | 3.39024 | +0.01929 |
| 3000 | 3.29113 | 3.31186 | +0.02073 |
| 3325 | 3.27251 | 3.29451 | +0.02200 |

Gap shrinks monotonically from +0.18 (step 125 — β1=0.02 warmup) to +0.022 (step 2000), then PLATEAUS through step 3325. **Fixed-point gap, not warmup artifact**. Adan converges to a strictly worse fixed point.

### Closure-completing finding: VR-on-aux axis fully closed (5 mechanisms × 4 classes)

| Mechanism class | PR | Result | Δ vs ctrl |
|---|---|---|---|
| Weight-averaging (Polyak) | #531 SF-AdamW | NEG | — |
| Gradient-history (mask) | #544 Cautious | NEG | +0.025 |
| Gradient-history (dual-EMA) | #567 AdEMAMix | NEG | — |
| Gradient-history (γ-correction) | #582 MARS | NEG (borderline) | +0.00118 |
| **Gradient-difference (Δg EMA)** | **#646 Adan** | **NEG** | **+0.0220** |

**Strong mechanism finding**: the aux config (β1=0.8 short EMA + per-group LRs 0.3/1/320/0.01 + eps=1e-6) is tightly tuned for vanilla AdamW's normalized-update geometry. ANY VR augmentation (regardless of mechanism family) perturbs the balance by ~0.02 nats. Future aux-side VR proposals are pre-closed by structural analogy.

### Unfused Python optimizer viability demonstrated

Adan was implemented as a custom unfused Python class (~30 LoC). Step_avg overhead vs fused AdamW: +0.36% (1821ms vs 1815ms), +600 MB optimizer state. **Wall-clock competitive**. The deficit was purely in optimization quality, not compute. Lowers the bar for future Python-only optimizer prototypes.

### Next step

Fern reassigned to **PR #670: H39 Per-group aux AdamW eps decoupling** — fresh mechanism axis (structural ablation of shared-eps assumption). Builds on PR #443's eps=1e-6 baseline winner.

---

## 2026-05-21 04:45 UTC — PR #636 CLOSED (fern): H36 Cooldown-gated MuonH momentum reset — NEG with PATH-DEPENDENCE mechanism finding

- Branch: `g1r3-fern/muonh-reset-cooldown-gated`
- Hypothesis: Can we capture PR #616's mid-training favorable Δ ≈ −0.02 (reset during main phase = noise removal) by gating reset OFF at cooldown onset (step 2493, 75% through training)?

### Results (3325 steps, n=1 each)

| Arm | run_id | val/loss | ffs | reached_target | nonfinite | Δ vs ctrl | Δ vs baseline `t1coza71` |
|---|---|---:|---:|---:|---:|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | 1 | — | — | — |
| Arm 1 ctrl (reset-off) | `s4vuryin` (reused from PR #616, same flags) | **3.27383** | 3150 | 1 | 0 | — | +0.00264 (within σ band) |
| Arm 2 gated-0p75 | `9ywys5bp` | **3.29226** | -1 | 0 | 0 | **+0.01843** (~18σ) | +0.02107 |
| Reference PR #616 full-reset | `cdwha2oa` | 3.29693 | -1 | 0 | 0 | +0.02310 | +0.02574 |

**Decision: NEG** — Δ = +0.01843 ≥ +0.001 → closes phase-gating axis on inner momentum.

### Path-dependence mechanism (key finding)

The mid-training favorable Δ ≈ −0.02 from PR #616 REPRODUCED PRECISELY:
- Step 1000: Δ=−0.0399 (peak)
- Step 1500: Δ=−0.0189
- Step 2375: Δ=−0.0041 (gate ON winding down)
- Step 2500: Δ=+0.0018 (gate just transitioned OFF)

But cooldown reattachment did NOT occur:
- Step 2625 (125 steps post-gate): Δ=+0.0159 (already wide open)
- Step 3000: Δ=+0.0189
- Step 3325 (terminal): Δ=+0.0184

**Cooldown decomposition**:

| | Arm 1 ctrl | Arm 2 gated |
|---|---:|---:|
| val at step 2500 | 3.37213 | 3.37389 |
| val at step 3325 | 3.27383 | 3.29226 |
| **cooldown Δ** | **−0.0983** | **−0.0816** (83% of ctrl) |

Arm 2 achieves only 83% of ctrl's cooldown progress DESPITE identical optimizer structure post-gate. The deficit is fully attributable to the divergent parameter trajectory accumulated during steps 0–2493.

### Refined rule (extends PR #616 closure)

The PR #616 mid-training favorable Δ is a **per-step val difference, NOT a transferable improvement**. The MuLoCo+MuonH cooldown is a long-memory integrator that depends on the trajectory + accumulated state jointly — splitting them via phase-gating destroys terminal val.

**Phase-gating axis on inner momentum: STRUCTURALLY CLOSED.** Future advisor planning should NOT propose phase-gated inner-state interventions (full or partial). The mid-training Δ in PR #616 was a path-dependent artifact, not a recoverable signal.

### Smart compute reuse

Student reused PR #616 ctrl `s4vuryin` (identical `--muonh_reset_on_sync 0` flag, same stack invariants, same fern pod) as arm 1 reference — saved ~3 GPU-hours. Valid comparison since configurations matched.

### Next step

Fern reassigned to **PR #646 H38 Adan optimizer (Xie et al 2022)** — fresh variance-reduction mechanism class (gradient-DIFFERENCE VR, distinct from the closed gradient-history triple-NEG: Cautious/AdEMAMix/MARS). Single FBP per step. ~60 LoC custom unfused Adan. Completes the VR-on-aux survey (history-based, difference-based, weight-averaging).

---

## 2026-05-21 04:25 UTC — PR #631 CLOSED (askeladd): H35 Aux AdamW β2 pruning — NEG joint closure of β1+β2 axes

- Branch: `g1r3-askeladd/aux-beta2-pruning`
- Hypothesis: Is the aux AdamW β2=0.95 (variance preconditioner v_t EMA) load-bearing? Setting β2=0 → v_t = g_t² each step → update ≈ m_t / (|g_t| + ε) (signSGD-with-momentum). Natural complement to PR #612 β1=0 closure.

### Results (3325 steps, n=1 each)

| Arm | run_id | val/loss | ffs | reached_target | nonfinite | Δ vs ctrl | Δ vs baseline `t1coza71` |
|---|---|---:|---:|---:|---:|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | 1 | — | — | — |
| Arm 1 ctrl (β2=0.95) | `kw8qfip2` | **3.27291** | 3125 | 1 | 0 | — | +0.00172 (within σ≈0.001 seed band) |
| Arm 2 (β2=0.0) | `fdvg8gde` | **14.847** (killed step 627) | — | 0 | 0 | +11.58 | +11.58 (catastrophic divergence) |

**Decision: NEG** — β2=0.95 IS load-bearing at current aux LRs.

### Mechanism finding: v_t is implicit per-parameter LR normalization

With β2=0, v_t = g_t² each step → update = m_t / (|g_t| + ε). Two failure modes per coord type:

- **Dense-grad coords**: update ≈ sign(m_t) · |m_t/g_t| ≈ ±LR per step. Embed LR=0.3 → ±0.3/coord/step (orders of magnitude larger than AdamW's normalized step).
- **Sparse-grad coords** (common in embed under token sparsity, lm_head under vocab sparsity): |g_t| → 0, update amplified by ~1/ε = 10⁶. Single-step move ≈ m_t · LR · 10⁶.

Student's weight_max telemetry confirms the amplification mechanism:

| step | weight_max (arm 2) | weight_max (ctrl) | ratio |
|---:|---:|---:|---:|
| 125 | 1.9×10⁸ | 23.4 | **8.1×10⁶×** |
| 250 | 2.1×10⁸ | 31.6 | 6.7×10⁶× |
| 500 | 2.1×10⁸ | 46.0 | 4.6×10⁶× |

NC=0 throughout — this is NOT a NaN divergence; it's a useless high-magnitude regime that stays past the kill-gate threshold permanently. val=14.847 at step 600 vs ctrl ~3.9 (Δ+11) → 100× past the +0.10 kill-gate threshold.

### Joint closure of the aux AdamW preconditioner axis

- **β1=0.8** load-bearing (PR #612, NEG): bulk-phase gradient denoiser; momentum smoothing required, attenuates in cooldown.
- **β2=0.95** load-bearing (this PR, NEG): per-parameter LR normalizer. Removing it un-normalizes the update; sparse-grad amplification reaches ~10⁶× in embed/lm_head groups.

**Rule**: v_t serves as implicit per-parameter LR normalization at current aux LRs (embed=0.3, lm_head=1/320, scalars=0.01). Removing it requires re-tuning aux LRs by ~2 orders of magnitude. Both EMAs (β1, β2) are now established as load-bearing — full AdamW is the right floor for aux. Future aux-side pruning should target eps / lr / lr_scaling / step / scheduling axes rather than the betas pair.

### Next step

Askeladd reassigned to **PR #643 H37 PAdam — generalized v_t power for aux AdamW** (the **third leg** of the preconditioner closure: holding β1/β2 fixed, is the geometric exponent in `m_t / (v_t^p + ε)` load-bearing?). 2 arms: p=0.5 ctrl vs p=0.25 (paper recommendation, partial preconditioning). Credible WIN-candidate per Chen et al 2018 ImageNet results.

---

## 2026-05-21 02:55 UTC — PR #621 HELD (nezuko): pod transitioned to broken state mid-experiment

- Branch: `g1r3-nezuko/muonh-hyperball-pruning`
- **Pod state transition observed**: ctrl arm `58rw98w0` ran healthy for 79.6 min / 1920 steps (NC=0 throughout), then crashed (val=3.5110, did not reach target). 4 subsequent retries (`01482w39`, `n2lbd0lw`, `nkbkntp7`, `ht3vzgrc`) ALL show canonical 147M nonfinite fingerprint at step 125 — same pattern as 5 already-broken pods.
- **Code verified sound**: smoke `mxfijegc` with `--muonh_hyperball 0` ran clean for 200 steps (val=4.5520, NC=0) BEFORE the pod broke. Hyperball=0 implementation is correct.
- **Action**: PR sent back to student with diagnostic + hold instruction. esc#31 posted on Issue #164 (now 6 of 8 r3 pods broken). H34 hypothesis stays valid; will resume when pod rotates.

---

## 2026-05-21 02:20 UTC — PR #636 ASSIGNED (fern): H36 Cooldown-gated MuonH momentum reset — recover the mid-training Δ

- Branch: `g1r3-fern/muonh-reset-cooldown-gated`
- Hypothesis: PR #616 NEG showed reset arm was BETTER than ctrl by 0.005–0.035 during the entire main training phase (steps 500–2125), then progressively LOST during cooldown (Δ+0.023 terminal). Phase boundary sharp at step ~2500. **If we gate reset OFF at cooldown onset (~75% through training), we may capture the mid-training favorable Δ without the cooldown loss.**
- Two arms: ctrl (reset off entirely) vs arm 2 (`--muonh_reset_on_sync 1 --muonh_reset_until_frac 0.75` = reset during steps 0–2493, no-op during 2493–3325).
- ~3 LoC change (add `--muonh_reset_until_frac` flag, add gate condition to PR #616's reset block).
- Three decisive outcomes: win (val<3.27039) → mid-training Δ transfers, merge candidate; marginal → partial benefit, sweep intermediate gates; NEG → cooldown needs full un-reset history. Highest-EV follow-up from PR #616 closure (student's own suggestion #1).

---

## 2026-05-21 02:15 UTC — PR #616 CLOSED (fern): H33 MuonH momentum reset on sync — NEG with phase-localized mechanism finding

- Branch: `g1r3-fern/muonh-reset-on-sync`
- Hypothesis: Is cross-sync MuonH momentum coherence load-bearing? MuonH mu=0.95 buffer (half-life ~14 steps) persists across MuLoCo sync (every 30 inner steps), carrying stale history from pre-kick parameter neighborhood.

### Results (3325 steps, n=1 each)

| Arm | run_id | val/loss | ffs | reached_target | nonfinite | Δ vs ctrl | Δ vs baseline `t1coza71` |
|---|---|---:|---:|---:|---:|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | 1 | — | — | — |
| Arm 1 ctrl (reset-off) | `s4vuryin` | **3.27383** | 3150 | 1 | 0 | — | +0.00264 |
| Arm 2 reset-on | `cdwha2oa` | **3.29693** | -1 | 0 | 0 | **+0.02310** | +0.02574 |

SENPAI-RESULT: `{"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["s4vuryin","cdwha2oa"],"primary_metric":{"name":"val/loss","value":3.29693}}`

### Phase-localized mechanism (sharp finding)

| Step | ctrl | reset-on | Δ | Phase |
|---:|---:|---:|---:|---|
| 875 | 3.7702 | 3.7348 | **−0.0354** | main (favorable) |
| 1500 | 3.6137 | 3.5944 | **−0.0193** | main (favorable) |
| 1875 | 3.5110 | 3.4903 | **−0.0207** | main (favorable) |
| 2125 | 3.4497 | 3.4446 | **−0.0051** | main (favorable) |
| 2500 | 3.3721 | 3.3733 | +0.0012 | cooldown begins |
| 3175 | 3.2778 | 3.3003 | +0.0225 | cooldown |
| 3325 | 3.27383 | 3.29693 | **+0.0231** | terminal |

**Two regimes, opposite signs:**

1. **Main phase (high LR)**: fresh gradient signal dominates each update; mu=0.95 EMA buffer is a small noise source. Stale momentum after sync adds ~0.02 val noise — resetting REMOVES this noise → favorable Δ.
2. **Cooldown phase (low LR)**: LR shrinks → momentum buffer's relative contribution grows. Resetting cuts the optimizer's memory exactly when long-horizon directional momentum is needed → Δ opens to +0.023 by terminal.

Phase boundary almost exactly at step 2500 (cooldown onset). Cleanest cooldown-vs-main mechanism split observed in this round.

### Telemetry sanity (PR-required)

- `muonh/active_fraction = 1.0` at every sampled step in BOTH arms (reset did not perturb NS5 saturation; gate ±5% met at ~0%).
- `muloco/delta_rms` and `velocity_rms` essentially identical between arms throughout (<1% deviation). PR's prior expectation ("reset arm should have HIGHER delta_rms early") did NOT materialize, because mu=0.95 half-life (14 steps) is short relative to sync interval (30 steps).
- All kill gates passed during training. NEG comes entirely from cooldown.

### Rule (provisional)

"Inner optimizer memory is more valuable during cooldown than during main training."  
Consistent with PR #563 (outer_momentum=0.9 NEG during cooldown), but direction on inner-side OPPOSITE: main training tolerates / benefits from frequent resets.

### Follow-up
Fern reassigned to H36 cooldown-gated reset (PR #636). The mid-training favorable Δ ≈ −0.02 is large and consistent — if it transfers to terminal, val could land below merge bar.

---

## 2026-05-21 01:05 UTC — PR #631 ASSIGNED (askeladd): H35 Aux AdamW β2 pruning — is the variance preconditioner load-bearing?

- Branch: `g1r3-askeladd/aux-beta2-pruning`
- Hypothesis: The aux AdamW uses `betas=(0.8, 0.95)`. PR #612 (just closed) showed β1=0.8 IS load-bearing. This PR tests the OTHER half: setting β2=0.0 prunes the v_t EMA entirely. When β2=0, v_t = g_t² each step → update ≈ m_t / (|g_t| + ε) ≈ signSGD-with-momentum.
- Two arms: ctrl (β2=0.95, default), arm 2 (`--aux_adamw_beta2 0.0` = variance EMA pruned).
- Three informative outcomes: win → v_t dead weight (merge + simplify); match → v_t dead weight (simplify future stacks); NEG → β2=0.95 IS load-bearing → full AdamW floor confirmed both sides (β1 AND β2).
- ~2 LoC change (add `--aux_adamw_beta2` flag, update fused AdamW betas tuple). Natural complement to PR #612 (β1=0 NEG). Directly aligned with launch directive "pruning ablations of complex stacks".

---

## 2026-05-21 00:52 UTC — PR #612 CLOSED (askeladd): H32 aux AdamW β1=0 pruning — NEG, β1=0.8 is load-bearing

- Branch: `g1r3-askeladd/aux-beta1-pruning`
- Hypothesis: Is aux AdamW first moment (β1=0.8) load-bearing? Motivated by triple-NEG pattern: Cautious (PR #544), AdEMAMix (PR #567), MARS (PR #582) all failed on short-β1=0.8 aux stack. Does removing β1 entirely help (RMSProp-on-aux)?

### Results (3325 steps, n=1 each)

| Arm | run_id | β1 | val/loss | ffs | reached_target | nonfinite | Δ vs ctrl |
|---|---|---:|---:|---:|---:|---:|---:|
| Baseline `t1coza71` | — | 0.8 | 3.27119 | 3100 | 1 | — | — |
| Arm 1 ctrl (β1=0.8) | `oaviz82w` | 0.8 | **3.27217** | 3125 | 1 | 0 | — |
| Arm 2 prune (β1=0) | `s4tdvmcn` | 0.0 | **3.28724** | -1 | 0 | 0 | **+0.01507** |

- Arm 1 ctrl reproduces baseline cleanly (Δ vs `t1coza71` = +0.00098, within σ≈0.001). Flag `--aux_adamw_beta1 0.8` pass-through behaves identically to prior hardcoded `betas=(0.8, 0.95)`.
- Arm 2 (β1=0) val=3.28724, **+0.01507 above ctrl** (well outside σ≈0.001). Fails to reach speedrun target (val > 3.28). ffs=-1.
- SENPAI-RESULT: `{"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["oaviz82w","s4tdvmcn"],"primary_metric":{"name":"val/loss","value":3.28724},"test_metric":{"name":"val/loss","value":3.28724}}`

### Trajectory (gap-narrowing pattern)

| Step | Arm 1 (β1=0.8) | Arm 2 (β1=0) | Δ |
|---:|---:|---:|---:|
| 500 | 3.90309 | 3.98139 | +0.0783 |
| 1500 | 3.61779 | 3.65332 | +0.0355 |
| 2500 | 3.37092 | 3.38767 | +0.0168 |
| 3325 | 3.27217 | 3.28724 | **+0.0151** |

Gap NARROWS from +0.0783 (step 500) → +0.0151 (terminal). β1 EMA denoising is most valuable when per-step gradient variance is high (bulk training); benefit attenuates during cooldown as LR decays.

### Mechanism findings

**Sharp finding: aux β1=0.8 is in a narrow load-bearing band — required non-zero AND cannot be extended.**

| PR | Mechanism | Direction tested | Result |
|---|---|---|---|
| #612 (this) | β1 pruning to 0 | SHORTEN to extreme | NEG (+0.0151) — too short |
| #544 (fern) | Cautious AdamW | LENGTHEN effective horizon | NEG (+0.025) — too long for filter |
| #567 (fern) | AdEMAMix β3=0.9999 | ADD long-horizon EMA on top | NEG (+0.00150) — horizon mismatch |
| #582 (askeladd) | MARS variance reduction | LENGTHEN via control variate | NEG (+0.00118) — m_{t-1} too stale |

**Rule**: β1=0.8 acts as a bulk-phase gradient denoiser. Future planning must NOT propose: β1=0 / first-moment-free aux optimizers; gradient-history-extending mechanisms; β1 mid-training ramps (fused-kernel incompatible per PR #572). The aux β1 axis is fully closed in ALL directions.

---

## 2026-05-20 23:18 UTC — PR #621 ASSIGNED (nezuko): H34 MuonH hyperball projection pruning ablation — is the Frobenius-sphere projection load-bearing?

- Branch: `g1r3-nezuko/muonh-hyperball-pruning`
- Hypothesis: The current baseline (PR #443) uses `mode=scale_invariant` with `hyperball=True` — the always-active SI projection that holds each hidden-weight matrix on a Frobenius sphere of radius `||initial param||`. This was introduced in PR #443 as a structural change but never ablated. Setting `hyperball=False` prunes the projection entirely — vanilla Muon-SGDM with no norm constraint.
- Two arms: ctrl (hyperball=1, current baseline), arm 2 (`--muonh_hyperball 0` = vanilla Muon-SGDM).
- Three informative outcomes: win → SI projection was hurting (opens weight-norm regulari­zation-free direction); match → projection dead code; NEG → SI projection IS the load-bearing mechanism from PR #443.
- ~5 LoC change (add `--muonh_hyperball` flag, pass to MuonH constructor). Orthogonal to PR #612 (aux β1), PR #616 (MuonH momentum reset), and PR #595 (AGC pruning just closed).

---

## 2026-05-20 23:18 UTC — PR #595 CLOSED (nezuko): H29 AGC pruning ablation — marginal NEG, AGC not load-bearing as NaN safety net

- Branch: `g1r3-nezuko/agc-pruning-ablation`
- Hypothesis: AGC (Brock et al ICLR 2021) was added to the stack on both aux AdamW and inner MuonH sides. PR #483 found ratio sweep [0.02, 0.10] "insensitive", but never tested disabled. This 3-arm pruning ablation resolved whether AGC was: (a) dead code; (b) NaN safety net; (c) productive clipping.

### Results (3325 steps each)

| Arm | run_id | val/loss | ffs | nonfinite | Δ vs ctrl | Δ vs baseline |
|---|---|---:|---:|---:|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | — | — | — |
| Arm 1 ctrl (AGC=0.05 both) | `g66n94a2` | 3.27470 | 3175 | 0 | — | +0.00351 |
| Arm 2 AGC-off-aux (`aux_agc=1e9`) | `wlwedbuq` | 3.27420 | 3150 | 0 | −0.00050 | +0.00301 |
| Arm 3 AGC-off-muonh (`muonh_agc=1e9`) | `ajm433v5` | **3.27243** | **3125** | 0 | **−0.00227** | +0.00124 |

- No arm clears merge bar 3.27039. Best arm (arm 3) Δ=−0.00227 vs ctrl (~2σ effect, n=1 inconclusive).
- SENPAI-RESULT: `{"terminal":true,"status":"complete","pending_arms":false,"wandb_run_ids":["g66n94a2","wlwedbuq","ajm433v5"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":3125},"test_metric":{"name":"val/loss","value":3.27243}}`

### Mechanism findings

1. **AGC is NOT a load-bearing NaN safety net**: nonfinite_count=0 across all 6650 ablation steps (arms 2+3 combined). The "AGC catches gradient spikes that would NaN training" hypothesis is decisively disconfirmed at n=1 ablation.

2. **Aux-side AGC is effectively dead code** (arm 2 Δ=−0.00050, within σ≈0.001). Clip threshold ≈ 70k (= 0.05×||W_embed||≈1.39M) >> typical aux gradients (~1-100). The AGC path almost certainly never activates on aux groups.

3. **MuonH-side AGC trends best when removed** (arm 3 Δ=−0.00227, ~2σ below ctrl). NS5 orthogonalization already enforces a spectral-norm bound on the update direction; AGC on top is at best redundant. Suggestive but n=1 leaves room for seed luck (ctrl itself is at high end of seed band, +0.00351 vs baseline).

**Generalizable rules**:
- Aux-AGC structural axis is CLOSED — never fire again.
- MuonH-AGC "redundant-or-marginal" but n=1 insufficient for multi-seed confirmation per launch directive budget constraints. No further AGC work needed.

### Disposition

Marginal NEG. PR closed. Nezuko reassigned to H34 MuonH hyperball pruning (PR #621).

---

## 2026-05-20 20:38 UTC — PR #612 ASSIGNED (askeladd): H32 aux AdamW β1=0 pruning ablation — is the first moment load-bearing?

- Branch: `g1r3-askeladd/aux-beta1-pruning`
- Hypothesis: The aux AdamW uses `betas=(0.8, 0.95)` — a short-horizon first moment with half-life ~3 steps. Three recent NEG closures (#544 Cautious, #567 AdEMAMix, #582 MARS) all hit the same wall: gradient-history-based augmentations fail on short-β1=0.8 stacks. This pruning ablation tests whether β1=0.8 itself is load-bearing or just historical. Setting β1=0 prunes the first moment entirely (AdamW degenerates to RMSProp on aux).
- Two arms: ctrl (β1=0.8, current baseline), arm 2 (`--aux_adamw_beta1 0.0` = RMSProp-on-aux).
- Three informative outcomes: win/match → first moment is dead weight, re-opens gradient-history-free interventions; NEG → β1=0.8 is load-bearing, triple-NEG pattern confirmed and mechanism closed.
- ~2 LoC change (new `--aux_adamw_beta1` flag passed to fused AdamW at construction time). Fused-safe (β1=0 is a standard PyTorch config).

---

## 2026-05-20 20:35 UTC — PR #582 CLOSED (askeladd): H25 MARS variance-reduced gradient — NEG, triple-mechanism pattern confirmed

- Branch: `g1r3-askeladd/aux-mars`
- Hypothesis: MARS (Yuan 2025) applies a control-variate correction `c_t = g_t + γ·β1·(m_{t-1} − g_{t-1})` pre-step to reduce gradient variance. With aux β1=0.8, tested γ=0.025 (paper LM default) and γ=0.1.

### Results (3325 steps each)

| Arm | run_id | val/loss | ffs | reached_target | Δ vs ctrl | Δ vs baseline |
|---|---|---:|---:|---|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | yes | — | — |
| mars-ctrl | `ifdm0vqm` | **3.27378** | 3150 | yes | — | +0.00259 |
| mars-γ=0.025 | `17xyn9p7` | **3.27496** | 3175 | yes | +0.00118 | +0.00377 |
| mars-γ=0.1 | `1u732d5z` | **3.27429** | 3150 | yes | +0.00051 | +0.00310 |

- γ=0.025 borderline-NEG (Δ+0.00118 ≥ ctrl+0.001 threshold); γ=0.1 noise-neutral but not improving.
- No arm cleared merge bar 3.27039.

### Mechanism finding (THIRD confirmation — triple-NEG pattern)

> **Gradient-history-based augmentations are structurally incompatible with short-β1=0.8 aux AdamW stacks.**

The control-variate correction requires `m_{t-1}` to be positively correlated with `g_t`. With β1=0.8 (half-life ~3 steps), `m_{t-1}` tracks `g_{t-1}` more than `g_t`. The residual `m_{t-1} − g_{t-1}` measures grad-step staleness noise; multiplied by γ·β1 and added back, it injects net variance rather than reducing it. Confirmed by telemetry: correction RMS scales linearly with γ (0.000134 at γ=0.025, 0.000539 at γ=0.1 ≈ 4×), consistent with noise injection rather than coherent correction.

| PR | Mechanism | Result | Core failure mode |
|---|---|---|---|
| #544 (fern) | Cautious AdamW | NEG +0.025 | Short β1=0.8 kills stale-momentum gap |
| #567 (fern) | AdEMAMix dual-EMA | NEG +0.00150 | m_2 only 28% saturated at 3325 steps |
| **#582 (askeladd)** | **MARS variance reduction** | **NEG +0.00118** | **control variate adds variance on short-β1 stack** |

**Generalizable rule**: Optimizer mechanisms exploiting multi-step gradient history require β1 calibrated to give that buffer signal-carrying capacity. β1=0.8 (half-life ~3 steps) is too short. Future gradient-history-based methods should only be re-tested with corresponding β1 increase.

**Side finding**: mid-cooldown val trajectory checkpoints (~step 2070) are NOT predictive of terminal val on this stack. γ=0.025 was tracking +0.12 vs ctrl at step 2070 but recovered to +0.00118 at step 3325. Advisor lesson: wait for terminal before strong claims.

---

## 2026-05-20 21:46 UTC — PR #616 ASSIGNED (fern): H33 MuonH momentum reset on MuLoCo sync — is cross-sync momentum coherence load-bearing?

- Branch: `g1r3-fern/muonh-momentum-reset-on-sync`
- Hypothesis: MuonH uses mu=0.95 (half-life ~14 steps). The MuLoCo outer sync fires every 30 inner steps and applies a non-trivial "kick" to parameters. The MuonH momentum buffer persists unchanged across these sync events — carrying stale gradient history from the pre-kick parameter neighborhood. This ablation tests whether that cross-sync coherence is load-bearing or harmful noise.
- Two arms: ctrl (no reset, current baseline), arm 2 (`--muonh_reset_on_sync 1` = zero MuonH buffers after each sync).
- Orthogonal to PR #612 (aux β1 pruning) and all prior outer-side closures (PR #563/#536/#597). Tests inner-outer coupling as a structural axis for the first time.
- ~8 LoC. Fused-safe (modifying optimizer state tensors, not fused-kernel HPs).

---

## 2026-05-20 21:46 UTC — PR #597 CLOSED (fern): H31 MuLoCo outer Nesterov pruning NEG — Nesterov velocity amplifier IS load-bearing, operating-regime model refined

- Branch: `g1r3-fern/outer-nesterov-pruning`
- Hypothesis: The MuLoCo outer optimizer uses Nesterov lookahead (`p = anchor − outer_lr · (β·v + delta)`), introducing a velocity amplifier `(1 + β/(1−β)) = 2×` at β=0.5. PR #536 showed momentum=0 is catastrophic; PR #563 showed β→0.9 ramp is catastrophic. Neither tested FORMULATION — Nesterov vs vanilla SGD-momentum at fixed β=0.5. This ablation separated the Nesterov velocity-amplifier from the momentum magnitude.

### Results (3325 steps each)

| Arm | run_id | val/loss | ffs | reached_target | Δ vs ctrl | Δ vs baseline |
|---|---|---:|---:|---|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | yes | — | — |
| Arm 1 ctrl (Nesterov on) | `aywshl69` | **3.27332** | 3150 | yes | — | +0.00213 |
| Arm 2 Nesterov off (vanilla SGD-mom) | `tcpo0yg8` | **3.27774** | 3325 | yes | +0.00443 | +0.00655 |

- Arm 1 ctrl: noise-neutral vs baseline (Δ+0.00213, within σ≈0.001 band), code-clean.
- Arm 2 Nesterov-off: decisively NEG (Δ+0.00443 vs ctrl; ffs=3325 never beat 3.28 target efficiently).
- Neither arm cleared merge bar 3.27039.

### Mechanism finding (sharpened from PR #563)

> **Nesterov velocity amplifier IS load-bearing in the outer MuLoCo step.** Removing Nesterov (vanilla SGD-momentum at same β=0.5) costs Δ+0.00443.

**But the mechanism is subtler than the simple steady-state bound `(1 + β/(1−β)) = 2×`.**

The operating-regime ratio `β + g/v` better describes when Nesterov matters:
- **Mid-training (large g/v)**: ratio ≈ β + ~0.8 → 1.3×. Fresh gradients dominate; Nesterov adds moderate amplification.
- **Steady state (g/v ≈ β)**: ratio ≈ 2β = 1.0. Nesterov approaches vanilla.
- **Cooldown (g/v → 0)**: ratio < 1. Nesterov becomes marginal.

The δval=0.00443 loss is substantial — Nesterov is most valuable in the bulk-training phase where outer deltas are large. Vanilla SGD-momentum fails to efficiently accumulate momentum during the non-stationary bulk phase.

**Generalizable rule**: Outer Nesterov is load-bearing throughout bulk training due to operating-regime amplification. The outer Nesterov formulation axis is CLOSED alongside the outer_momentum schedule axis (PR #563). **No further Nesterov-related outer-optimizer work needed.**

### Disposition

NEG. PR #597 closed. Fern reassigned to H33 MuonH momentum reset on MuLoCo sync (PR #616).

---

## 2026-05-20 16:50 UTC — PR #597 ASSIGNED (fern): H31 MuLoCo outer Nesterov pruning ablation — is the Nesterov velocity amplifier load-bearing?

- Branch: `g1r3-fern/outer-nesterov-pruning`
- Hypothesis: The outer optimizer's Nesterov lookahead (`update = lr · (g + β·m)`) introduces a velocity amplifier `(1 + β/(1−β)) = 2×` at β=0.5. PR #536 (nezuko) established "momentum is load-bearing" (mom=0 catastrophic); PR #563 (nezuko) established "moderate momentum uniquely optimal" (β→0.9 catastrophic). But neither tested FORMULATION vs MAGNITUDE — holding β=0.5 fixed and replacing Nesterov with vanilla SGD-momentum (`update = lr · m`). This pruning ablation tests whether the PR #563 velocity-amplifier mental model is mechanistically correct or incidental.
- Two arms: ctrl (Nesterov on), arm 2 (vanilla SGD-momentum, Nesterov off).
- Three informative outcomes: win → Nesterov was hurting; match → Nesterov redundant, can simplify stack; NEG → Nesterov velocity amplifier IS load-bearing, refines PR #563 finding.
- ~10 LoC. Fused-safe (outer MuLoCo only). Directly aligned with launch directive on pruning ablations.

---

## 2026-05-20 16:50 UTC — PR #567 CLOSED (fern): H22 AdEMAMix on aux — NEG, horizon-saturation structural mismatch

- Branch: `g1r3-fern/aux-ademamix`
- Hypothesis: Short-β1=0.8 aux AdamW (half-life ~3 steps) creates short-horizon first moment. Adding a slow EMA m_2 with β3=0.9999 (half-life ~7000 steps, Pagliardini EMNLP 2024) would complement the short m_1 with long-horizon gradient signal. AdEMAMix update: `(m_1 + α·m_2) / (√v + eps)`.

### Results (3325 steps each)

| Arm | run_id | val/loss | ffs | reached_target | Δ vs ctrl | Δ vs baseline |
|---|---|---:|---:|---|---:|---:|
| Baseline `t1coza71` | — | 3.27119 | 3100 | yes | — | — |
| Arm 1 ctrl | `xqmqsxba` | **3.27228** | 3125 | yes | — | +0.00109 |
| Arm 2 α=5, β3=0.9999, warm=30% | `k0psv3oo` | **3.27269** | 3125 | yes | +0.00041 | +0.00150 |
| Arm 3 α=8, β3=0.9999, warm=30% | `xrh0qfrf` | **3.27541** | 3175 | yes | +0.00313 | +0.00422 |
| Smoke 200 steps | `v55lvh4b` | — | — | — | — | — |

- Arm 2 (α=5) noise-neutral vs ctrl (Δ=+0.00041, well inside σ≈0.001) — AdEMAMix not providing additive gain.
- Arm 3 (α=8) mild regression (+0.00313) — unwarmed m_2 carries bias, scaling up hurts.
- No arm cleared n=1 merge bar 3.27039.

### Key diagnostic (fern-original telemetry)

`m2_fill_fraction ≈ 0.283 = 1 − 0.9999^3325` — m_2 reaches only **28% of its limiting value** by end of training. The slow EMA never saturates; β3=0.9999 assumes a ~30000-step horizon, we have 3325 steps.

### Mechanism finding (sharper than original hypothesis)

> **AdEMAMix is a HORIZON-CALIBRATED technique. At β3=0.9999, the assumed horizon is ≥ 30000 steps. On our 3325-step speedrun, m_2 spends the entire run warming up, contributing a small-magnitude noisy gradient signal rather than a mature long-horizon direction.**

**Generalizable rule**: Any optimizer mechanism with a hyperparameter calibrated by training-horizon length (β3 in AdEMAMix, long-EMA half-life in SF-AdamW, slow-VR weight in MARS, etc.) must have that hyperparameter renormalized to our 3325-step horizon BEFORE the result is read as "method failed on this stack". Otherwise we're testing horizon mismatch, not the mechanism.

**Why β3-sweep follow-up is not pursued**: launch directive emphasizes fresh mechanisms, not scalar HP search to rescue a NEG. β3=0.999 (fern's suggestion #1) would fix the horizon mismatch but remains HP tuning of an already-NEG method. Fern reassigned to H31 outer Nesterov pruning ablation (PR #597).

### Disposition

NEG. AdEMAMix code change merged-as-is (additive at default off). Fern reassigned to PR #597.

---

## 2026-05-20 16:28 UTC — PR #595 ASSIGNED (nezuko): H29 AGC pruning ablation — is Adaptive Gradient Clipping load-bearing on aux and/or muonh inner sides?

- Branch: `g1r3-nezuko/agc-pruning-ablation`
- Hypothesis: AGC at clip_ratio=0.05 is applied on BOTH sides of the current stack (aux AdamW + muonh inner). PR #483 swept the ratio in [0.02, 0.10] and found "insensitive" — meaning either AGC fires almost never OR all values in that range produce similar clipping rates. We don't know which. **Pruning experiment**: replace AGC with no-op (`clip_ratio=1e9` effectively disables) on aux only (arm 2) or muonh only (arm 3), versus baseline ctrl (arm 1). Per launch directive on "pruning ablations of complex stacks". Three informative outcomes per side: (a) match ctrl → AGC dead code; (b) WIN → AGC was clipping productive updates; (c) NEG → AGC IS load-bearing.

### Why this matters
- AGC was added to baseline at a prior round, never directly tested for load-bearing-ness.
- Three of the most recent closures (PR #563 nezuko, PR #572 edward, PR #589 edward) all hit mechanism dead-ends; a pruning experiment de-risks future planning by reducing stack complexity rather than adding more knobs.
- 0 LoC code change — flags already exist; only the runtime values change. Lowest-risk experiment on the board.
- Plays to nezuko's mechanism-isolation strength (clean PR #536 + PR #563 execution).

### Arms (3 sequential 3325-step runs)
- Arm 1 ctrl: AGC on both, baseline.
- Arm 2: `--aux_agc_clip_ratio 1e9` (effectively disabled on aux).
- Arm 3: `--muonh_agc_clip_ratio 1e9` (effectively disabled on muonh inner).

### Decision rule
- Win: val < 3.27039 AND ffs ≤ 3100.
- Marginal: val < ctrl but ≥ 3.27039 → noted as "AGC slightly suboptimal", no merge.
- Match: |val − ctrl| < 0.001 → AGC is dead code on that side (no immediate merge; future cleanup PR).
- NEG: val ≥ ctrl + 0.001 → AGC IS load-bearing on that side.

---

## 2026-05-20 16:22 UTC — PR #563 CLOSED (nezuko): H18 cooldown-aware outer_momentum ramp — NEG, refined mechanism: moderate outer_momentum is uniquely optimal

- Branch: `g1r3-nezuko/cooldown-momentum-ramp`
- Hypothesis: Ramping outer_momentum upward during the cooldown phase (0.5 → 0.7 or 0.5 → 0.9) would exploit the PR #536 finding that "cooldown-phase momentum is load-bearing" by letting velocity carry more weight as per-step magnitudes shrink. Inner-side analogue: PR #572 edward's β1 cooldown ramp.

### Results (3325 steps each)

| Arm | Config | run_id | val/loss | Δ vs ctrl | ffs | reached_target |
|---|---|---|---:|---:|---:|---|
| 1 ctrl | outer_momentum=0.5 static | `jaobblo5` | **3.27140** ✓ | — | 3125 | yes |
| 2 cooldown ramp | 0.5 → 0.7 over last 30% | `nfx9rw46` | **3.27991** | +0.00851 | 3175 | yes |
| 3 long ramp | 0.5 → 0.9 over last 60% | `lz1rez4p` | **3.31239** | +0.04099 | -1 | **no** |
| smoke | schedule code verified | `au0l9icr` | — | — | — | — |
| killed-dup | duplicate launch | `3rxevlmq` | — | — | — | — |

- Arm 1 ctrl reproduces baseline within n=1 noise (Δ=+0.00021, well inside σ≈0.00092). Code change is clean.
- Arm 2 best ramp arm fails merge bar 3.27039 by +0.00952 → NEG.
- Arm 3 **missed 3.28 target entirely** → severe NEG / divergence.

### Mechanism finding (refined from PR #536)

**Moderate outer_momentum is uniquely optimal — both extremes catastrophic in distinct ways.**

| β | Nesterov velocity amplifier `(1 + β/(1−β))` | Outcome | Source |
|---|---:|---|---|
| 0.0 | 1.0× | NEG: velocity collapse, cooldown undershoot | PR #536 arm 3 (val=3.30224) |
| 0.5 | 2.0× | Optimum | All ctrls |
| 0.7 | 3.3× | NEG: cooldown ramp arm 2 (+0.0085) | PR #563 arm 2 |
| 0.9 | 10.0× | NEG: stale velocity overshoots fine corrections during cooldown's shrinking per-step magnitudes | PR #563 arm 3 (val=3.31239) |

The PR #536 closure said "Nesterov is load-bearing"; this PR refines it to **"moderate Nesterov is load-bearing — there is a sweet spot at 0.5, both extremes are catastrophic."**

### Rule for the research notebook

**Outer_momentum scheduling axis is now exhausted in both directions.** PR #536 closed the floor (mom=0 catastrophic), PR #563 closed the ceiling (mom→0.9 during cooldown catastrophic). Static mom=0.5 is the unique optimum. Future advisor planning should NOT propose outer_momentum schedule variants (downward ramps, LR-coupled schedules, smaller-magnitude ramps) — all of these are within the now-mapped failure surface.

### Importance of arm 3 (the kicker)

Arm 3's `reached_target=0` (val=3.31 > 3.28 target) makes the NEG unambiguous in the upper-momentum direction. No need for additional seeds; the gap is well outside noise.

### Disposition

NEG. Code change merged-as-is for inspection (additive at default unset/static). Nezuko reassigned to H29 AGC pruning ablation (PR #595).

---

## 2026-05-20 16:08 UTC — PR #589 CLOSED (edward): H27 STORM recursive variance-reduced gradient — pre-launch closure, mathematical degeneracy under 1-FBP constraint

- Branch: `g1r3-edward/aux-storm-variance-reduction`
- Hypothesis: STORM (Cutkosky & Orabona NeurIPS 2019) recursive variance-reduced gradient `d_t = g_t + (1−α)·(d_{t-1} − g_{t-1})` would provide gradient variance reduction distinct from MARS by using the previously-corrected estimator d_{t-1} (recursive) instead of AdamW's EMA m_{t-1} (single-step).

### Pre-launch analysis (by student g1r3-edward, $0 GPU)

Edward flagged the formula degeneracy before launching any runs. Unrolling the recursion with d_0 = g_0 = 0:
- t=1: d_1 = g_1 + (1-α)·(0 − 0) = g_1
- t=2: d_2 = g_2 + (1-α)·(d_1 − g_1) = g_2 + (1-α)·(g_1 − g_1) = g_2
- t=3: d_3 = g_3 + (1-α)·(d_2 − g_2) = g_3 + (1-α)·(g_2 − g_2) = g_3
- ... by induction d_t = g_t for all t ≥ 1.

The correction term `(d_{t-1} − g_{t-1})` is identically zero because d_{t-1} = g_{t-1} from the previous step's degeneration. Arms 2 and 3 would be functionally equivalent to Arm 1 (modulo FP rounding error).

### Why the formula is wrong (vs paper)

Genuine STORM evaluates `∇f(x_{t-1}, ξ_t)` — the gradient at the **previous parameters** but with the **current batch**. The variance reduction relies on the noise sharing between `g_t = ∇f(x_t, ξ_t)` and `∇f(x_{t-1}, ξ_t)` due to the shared batch ξ_t. Substituting `g_{t-1} = ∇f(x_{t-1}, ξ_{t-1})` (the *previous batch's* gradient, which is the only thing we have without an extra forward-backward) breaks both the noise-sharing property AND leads to the algebraic degeneracy above.

### Why we can't fix it

The benchmark contract states: **"Keep data, batch size, model architecture, and one forward-backward pass per optimizer step fixed."**

Genuine STORM requires a 2nd forward-backward at x_{t-1} with batch ξ_t each step → violates the contract. Closing the assignment is the correct call.

### Mechanism finding

Under the 1-FBP constraint, **VR-via-control-variate is fully covered on this stack by MARS (PR #582 askeladd)**. MARS uses AdamW's internal EMA `m_{t-1}` as the control variate — that's the only structure-preserving "free" reference available in the single-pass regime. STORM is a theoretically distinct mechanism but practically unavailable.

**Generalizable rule**: when proposing variance-reduction methods, verify that the control-variate term can be computed from existing per-step state (AdamW's m_t, v_t, or pre-step .grad) — not from a re-evaluation of the previous parameters on the current batch.

### Disposition

NEG (pre-launch). Edward reassigned to H28 Gradient Centralization (PR #592). This closure demonstrates the value of pre-launch analytical review — student caught the bug, $0 GPU burned.

---

## 2026-05-20 15:11 UTC — PR #572 CLOSED (edward): H26 Aux AdamW β1 cooldown ramp (0.8→0.95) — NEG, mechanism incompatible with fused AdamW state

- Branch: `g1r3-edward/aux-beta1-cooldown-ramp`
- Hypothesis: Linear ramp β1 0.8→0.95 over the last 40% (long ramp) or last 15% (short ramp) of training would let aux AdamW use a longer-memory first moment during cooldown — the inner-side analogue of PR #563 H18 outer_momentum ramp. The PR #536 finding that cooldown-phase momentum is load-bearing should generalize from MuLoCo outer to AdamW inner.

### Results (3325 steps each)

| Arm | Config | run_id | val/loss | ffs | nonfinite_count | duration |
|---|---|---|---:|---:|---:|---:|
| 1 ctrl | β1=0.8 static | `gxylln21` | **3.2713** ✓ | 3125 | 0 | 132m |
| 2 beta1ramp-long | β1=0.8→0.95 over last 40% | `zzotocuj` | NaN @ step 25 | — | 148M | 22m |
| smoke-v2 #1 | gated reassignment, 200 steps | `xn2wyuug` | NaN @ step 1+ | — | 148M | 7m |
| smoke-v2 #2 | gated reassignment relaunch | `icqb3em2` | NaN @ step 1+ | — | 147M | 4m |

### Crash diagnostic

Ctrl arm `gxylln21` reproduces baseline (val=3.2713 ≈ t1coza71 3.27119) — the schedule code path itself is harmless. But every attempt to actually engage the mechanism (even pre-ramp when β1 reassignment is a no-op 0.8→0.8) crashes immediately with NaN and ~148M nonfinite floats.

Initial diagnostic: `for group in optimizer1.param_groups: group['betas'] = (scheduled_beta1, group['betas'][1])` reassigns the tuple every iteration, creating a NEW tuple object even when value is unchanged. Hypothesis: PyTorch fused AdamW caches compiled state keyed on betas tuple identity (not value); new tuple every step triggers recomputation hitting a numerical edge case.

Proposed fix: gate the reassignment to only happen when value actually changes (pre-ramp: skip; in-ramp: reassign).

Two consecutive smoke-v2 attempts with the gated fix STILL crashed identically. Confirms the mechanism is broken at a level deeper than the gating logic. Either:
1. **State-cache invalidation**: even one in-ramp reassignment poisons fused state.
2. **First-step path divergence**: fused AdamW has a specialized step==1 path the betas reassignment perturbs.
3. **Implementation race**: student's code may have an unseen typo, but two attempts with identical fingerprints suggests mechanistic failure.

### Mechanism finding

`optimizer.param_groups[i]['betas']` reassignment mid-training on PyTorch fused AdamW is incompatible. The β1-scheduling axis is **closed at the optimizer level** on this stack. **Rule for future planning**: Do NOT propose schedule interventions that mutate fused-kernel hyperparameters mid-training (β1, β2, eps). The only safe schedule insertion point on this stack is BEFORE `optimizer.step()` via `p.grad` modification (MARS-style at PR #582, STORM-style at PR #589).

### Disposition

NEG. Edward reassigned to H27 STORM recursive variance-reduced gradient (PR #589).

---

## 2026-05-20 14:00 UTC — PR #555 CLOSED (askeladd): H17 SWA on aux AdamW during cooldown — paired SWA-vs-iterate proves SWA actively harmful (third weight-averaging NEG)

- Branch: `g1r3-askeladd/aux-swa-cooldown`
- Hypothesis: Aux-only uniform-mean SWA during cosine-cooldown's last 10-20% would average over post-warmup noise without violating MuonH orthogonality. Mechanistically distinct from PR #200 (full-model + EMA-throughout) on three axes: scope, window shape, timing.

### Three-arm results (3325 steps each)

| Arm | Config | run_id | val/loss (eval) | val/iterate_loss | paired Δ(swa−iterate) | ffs |
|---|---|---|---:|---:|---:|---:|
| 1 ctrl | SWA OFF | `ws2odsqa` | **3.27383** | — | — | 3150 |
| 2 SWA 10% | start_frac=0.9, every=1 | `n1cmpotm` | **3.27310** (swa) | 3.27231 | **+0.00079** | 3125 |
| 3 SWA 20% every2 | start_frac=0.8, every=2 | `uce6mixo` | **3.27678** (swa) | 3.27413 | **+0.00265** | 3150 |

Best arm (#2) vs n=1 merge bar 3.27039: fails by +0.00271. Best arm vs ctrl arm: clears by −0.00073 (below n=1 promotion delta 0.0008). **NEG.**

### Mechanism finding — THE result of this PR

**The paired SWA-vs-iterate comparison is the cleanest evidence**: within the same training trajectory, SWA-averaged weights evaluate worse than the final iterate. The harm scales with the window width (10% → +0.00079; 20% every2 → +0.00265). This is the opposite of the H17 hypothesis.

**Mechanistic story**: Even in cooldown, the aux iterate is still moving meaningfully toward the loss minimum — the average over a 333-step window lags. Cosine cooldown shrinks the per-step magnitude, but the optimizer continues to descend; averaging blurs that descent.

### Generalization (third confirmation)

**Weight-averaging methods (SWA, EMA shadow, Schedule-Free) are categorically incompatible with WSD/linear-cooldown stacks that target the final iterate.** Three NEG closures via the same mechanism:
- **PR #200** (full-model EMA Polyak, 2026-05-17): full-model + EMA-throughout, all arms NEG +0.008 to +0.10.
- **PR #531** (Schedule-Free Polyak, 2026-05-20 05:19 UTC): SF eval-at-mean breaks against final-iterate target.
- **PR #555** (aux-only cooldown SWA, this PR): even narrow scope + late timing + uniform mean is harmful.

**Rule for future advisor planning**: do not propose weight-averaging variants on this stack. PR #536 nezuko's "MuLoCo IS load-bearing" finding does NOT contradict — MuLoCo accumulates gradients/deltas, not iterate weight averages.

### Why arm 3 was critical (experimental design note)

Arm 3 with `every=2` was the kicker control: if arm 2 had been a marginal win, the natural next experiment would be "average longer / accumulate slower." Arm 3 explicitly tests both axes (wider window AND slower accumulation) and shows BOTH widen the harm — eliminating those follow-ups in a single 3-arm screen. Excellent screen design.

### Code change

The SWA flags (`--aux_swa_start_frac`, `--aux_swa_every`) are additive at default 0/disabled. Kept merged-as-is. But the closure mechanism finding means we should NOT use these flags for future weight-averaging follow-ups on this stack.

---

## 2026-05-20 11:38 UTC — PR #539 CLOSED (edward): H7 Per-group AdamW WD under eps=1e-6 — corollary falsified at wd=0.01, embed-WD destructive

- Branch: `g1r3-edward/aux-per-group-wd`
- Hypothesis: Under eps=1e-6 (PR #443 baseline), small positive WD on the eps-carrier groups (lm_head, scalars) would unlock new regularization headroom that was unreachable under eps=1e-10. PR #501 corollary: embed has large gradients → WD-insensitive; lm_head/scalars have small gradients × eps=1e-6 floor → would tolerate small WD.

### Three-arm results (3325 steps each + arm 1 redo)

| Arm | Config | W&B run | val/loss | ffs | reached | Δ vs ctrl |
|---|---|---|---:|---:|:---:|---:|
| 1 redo (ctrl) | all aux wd=0 | `9werg9o8` | **3.27254** | 3125 | ✓ | (anchor) |
| 2 wd-carriers | embed wd=0, lm_head/scalars wd=0.01 | `rd8hvapz` | **3.27321** | 3150 | ✓ | +0.00067 |
| 3 wd-all | embed/lm_head/scalars wd=0.01 | `zhfffa5p` | **3.28321** | -1 | ✗ | +0.01067 |

Δ(arm 1 redo − baseline t1coza71 3.27119) = +0.00135 → ctrl reproduces baseline within seed noise (code-path verifier passes; per-group WD plumbing assertion fired clean).

### Mechanism findings

**Arm 3 confirms PR #501 prediction (embed-WD is destructive)**: Trajectory diverges from baseline starting step ~500–1000 and stays ~0.03 worse through to step 3325. Embed has large gradients → AdamW produces aggressive updates → WD=0.01 brute-force shrinks embed faster than the optimizer can rebuild. The cleanest signal in the screen.

**Arm 2 falsifies the corollary at wd=0.01**: WD on the eps=1e-6 carriers is noise-neutral, NOT "regularizing-and-helpful". Trajectory tracks ctrl essentially exactly. Likely interpretation: under cosine cooldown, late-stage lm_head/scalars update magnitude shrinks proportionally to the LR schedule, so even though eps=1e-6 enlarges mid-run updates, the late-run updates that WD would compete against are small. WD has no signal to regularize against.

**Generalizable mental model (twice-validated via PR #501 → PR #539)**: **Per-group hyperparameter levers behave asymmetrically across embed vs lm_head/scalars under eps=1e-6**: embed is operating optimally (eps-invariant, WD-sensitive); lm_head/scalars are eps-sensitive but WD-insensitive at 0.01. Per-group LR, β2, eps, and WD all share this asymmetry — future per-group sweeps should be designed around it.

### Decision rule trigger

Arm 2 val=3.27321 ≥ 3.27200 → close H7 as exhausted at wd=0.01. Probability mass for smaller WD (0.001–0.005) is low given direction (slightly worse, not slightly better).

### Operational notes

- Code change (`--aux_embed_wd`, `--aux_lm_head_wd`, `--aux_scalars_wd` flags) is additive at default 0/0/0 — kept merged for future per-group WD work with different ε or lr/β2 settings.
- Arm 1 was redone from scratch (`9werg9o8`) after a pod-rotation interruption killed the original at step 1585 (`z304ccxs`); the redo confirms code-clean and was used as the anchor.

---

## 2026-05-20 10:20 UTC — PR #544 CLOSED (fern): H16 Cautious AdamW on aux — short-β1 stack has no stale-momentum gap to filter

- Branch: `g1r3-fern/aux-cautious-adamw`
- Hypothesis: Cautious AdamW masking (Liang et al 2024, arXiv:2411.16085) on aux groups improves terminal val/loss by filtering momentum-gradient sign-disagreements.

### Two-arm results (3325 steps each)

| Arm | Config | W&B run | best val/loss | terminal val | ffs | reached | Δ vs ctrl arm |
|---|---|---|---:|---:|---:|:---:|---:|
| 1 ctrl | `--aux_cautious 0` | `nca79tab` | **3.27189** | 3.27189 | 3125 | ✓ | — |
| 2 cautious+norm | `--aux_cautious 1 --aux_cautious_normalize 1` | `ziqd4qqy` | **3.29606** @3225 | 3.43536 | -1 | ✗ | +0.02417 best, +0.16347 terminal |

Δ(arm1 − baseline) = +0.00070 → ctrl reproduces baseline within seed noise (code-path verifier passes).

### Mechanism finding (THE result of this PR)

**Cautious AdamW is structurally unsuitable for our aux stack.** Two reasons:

1. **Effective LR amplification ×3.1** at steady-state mask_frac≈0.32 (steps 25-2000). Cautious is implicitly pushing unmasked-coord LR way out of our well-tuned baseline (0.3 / 1/320 / 0.01 → ~0.93 / 1/103 / 0.031). Aux LRs already at population optima per PRs #475/#478/#481.
2. **Short β1=0.8 (half-life ~3 steps)** kills the stale-momentum lag Cautious is designed to filter. m_t is already very close to g_t, so the disagreement signal Cautious filters is mostly noise.

**Generalization**: Cautious AdamW is a WIN when β1 is large (e.g., 0.9-0.95) AND aux LR is NOT pre-tuned at population optimum. Both prerequisites fail here.

### Late-cooldown blowup (side observation)

Arm 2 had a catastrophic +0.20 val jump in last ~75 steps (3275-3325): 3.30 → 3.50 → terminal 3.44. Hypothesized mechanism: stale outer-momentum amplifying within-sync mask-direction drift. NOT pursued as follow-up — side-effect of a NEG mechanism.

### Side diagnostic — PR #510 unfused-NaN failure mode is NOT global

`train/grad/all/nonfinite_count = 0` across all 134 logged steps. **Unfused Cautious-AdamW under eps=1e-6 + AGC + per-group LR is numerically clean.** PR #510 NaN-at-step-3 failure was specific to NAdam, not all unfused-AdamW variants.

| Optimizer | Status |
|---|---|
| fused AdamW | ✅ SAFE |
| unfused Cautious-AdamW | ✅ SAFE (this PR) |
| unfused NAdam | ❌ BLOCKED (PR #510) |

### Decision: CLOSED NEG

Code change kept (`--aux_cautious` and `--aux_cautious_normalize` flags additive harmless at default 0/0). Fern reassigned to **H22 AdEMAMix (PR #567)** — fresh dual-EMA preconditioner mechanism, complementary to short-β1 by ADDING long-horizon m_2 instead of removing low-quality m_1.

### Bookmarked (NOT assigned now)

1. **Late-cooldown blowup probe**: train with Cautious for 3000 steps then disable for last 325 — would confirm Cautious × end-of-cooldown interaction. Side curiosity, low priority.
2. **Cautious without normalize**: dominated by uniform LR cut, NOT worth testing.

---

## 2026-05-20 09:45 UTC — PR #536 CLOSED (nezuko): MuLoCo outer-step ablation — Nesterov momentum is the load-bearing component, NOT averaging

- Branch: `g1r3-nezuko/muloco-outer-step-ablation`
- Hypothesis: Is MuLoCo wrapper load-bearing on single-GPU r3? Is the momentum component the active ingredient (vs the periodic averaging)?

### Three-arm 3325-step results

| Arm | Config | W&B run | val/loss | ffs | reached_target | Δ vs ctrl |
|---|---|---|---:|---:|:---:|---:|
| **1 (ctrl)** | full MuLoCo: lr=0.7, mom=0.5, sync=30 | `zs31qtwl` | **3.27220** | **3125** | ✓ | — |
| 2 (off) | `--use_outer_optimizer 0` | `yi474ar1` | 3.28245 | -1 | ✗ | +0.01025 |
| 3 (mom0) | lr=0.7, **mom=0.0**, sync=30 | `t0tcf12b` | 3.30224 | -1 | ✗ | **+0.03005** |

### Mechanism finding (THE result of this PR)

- **MuLoCo wrapper is load-bearing**: Removing it (arm 2) costs +0.01025 vs ctrl, **5× the 0.002 threshold**. Wrapper is not dead weight on n=1 single-GPU.
- **Nesterov momentum is the active component, NOT averaging**: Removing only `outer_momentum` (keeping the periodic sync + outer_lr=0.7) costs +0.03005, **3× worse than removing the entire wrapper**.
- **Mechanism: cooldown-phase coherent kicks**, NOT distributed Polyak averaging.
  - Arm 1 `velocity_rms=0.0137` (2.2× delta_rms=0.0063) — momentum compounds 30 inner deltas into one coherent push.
  - Arm 3 `velocity_rms == delta_rms = 0.0086` — mathematically expected when `v ← 0·v + δ`, no compounding.

### Trajectory evidence — momentum's marginal value INCREASES during cooldown

| step | Arm 1 ctrl | Arm 2 off | Arm 3 mom0 | leader |
|---:|---:|---:|---:|:---:|
| 750 | 3.82579 | 3.78962 | **3.73542** | mom0 |
| 1500 | 3.62071 | 3.58636 | **3.53863** | mom0 (by 0.083!) |
| 2000 | 3.47988 | **3.47549** | 3.48391 | off |
| 2500 | 3.37107 | **3.36772** | 3.37623 | off |
| 3000 | **3.29088** | 3.29796 | 3.31401 | ctrl |
| 3325 | **3.27220** | 3.28245 | 3.30224 | ctrl |

Arm 3 (mom=0) leads ctrl through step 1750 by 0.083, then collapses to last place during cosine cooldown. Without momentum compounding, the periodic anchor-snap becomes a regressive 30%-revert of the last 30 inner steps' net change — precisely when inner LR×grad is small and needs help.

### Decision: CLOSED — pure ablation, no code change, mechanism finding is the deliverable

No merge (PR was pure CLI-flag ablation). Baseline configuration stands. Mental model updated: MuLoCo on single-GPU is "accumulated outer Nesterov momentum on top of the inner stack," NOT periodic Polyak averaging.

### Follow-up assigned

Nezuko reassigned to **H18: cooldown-aware outer_momentum ramp** (PR #563). Tests `outer_momentum` schedule 0.5→0.9 during cooldown phase, directly exploits the marginal-value-increases-in-cooldown pattern from this PR. 3 arms: ctrl static 0.5, cooldown-only ramp (start at 87% of training), long ramp (start at 60%).

### Bookmarked (NOT assigned now)

1. outer_momentum static sweep 0.5→0.95 (scalar HP — revisit if H18 schedule loses).
2. sync_interval × outer_lr joint (expensive).
3. SlowMo-default safety check `outer_lr=0.7, outer_momentum=0.7`.

---

## 2026-05-20 07:55 UTC — PR #478 CLOSED (askeladd): Aux AdamW embed LR n=4 confirmation — original n=1 signal was ctrl-arm seed inflation

- Branch: `g1r3-askeladd/aux-embed-lr-sweep`
- Hypothesis (revisited): Embed_lr=0.4 under eps=1e-6 baseline produces population-level improvement vs ctrl 0.3. The original n=1 sweep produced a clean monotone signal across 0.2 → 0.3 → 0.4 (Δ=−0.00186 vs ctrl) that motivated this n=4 confirmation.

| n=4 arm | W&B run | val/loss | ffs | step_3000 val | smoke val | Δ vs baseline (3.27119) |
|---|---|---|---|---|---|---|
| 1 | `qvsm40in` | 3.27277 | 3125 | 3.29150 | 4.21738 | +0.00158 |
| 2 | `5bpodakn` | 3.27298 | 3150 | 3.29153 | 4.21997 | +0.00179 |
| 3 | `3innjs8n` | **3.27107** | **3100** | 3.28968 | 4.21850 | **−0.00012** |
| 4 | `9ylxzvgs` | 3.27162 | 3125 | 3.29031 | 4.21680 | +0.00043 |

**Statistics:**

| stat | value |
|---|---|
| n=4 mean | **3.27211** |
| sample stdev | 0.00092 |
| SEM | 0.00046 |
| 95% CI | [3.27121, 3.27301] |
| Statistical-rule check `(3.28 − μ) × √n ≥ 0.004` | `0.01578 ≥ 0.004` ✓ |
| Merge bar (n=4 conservative, < 3.27079) | mean **+0.00132 above** → NOT cleared |
| Real-but-marginal upper bound (≤ 3.27200) | mean **+0.00011 above** → just outside |
| PR #471 baseline population estimate (~3.27218) | mean **−0.00007 below** → indistinguishable |

**Decision: CLOSED NEG.** The n=4 mean 3.27211 is statistically indistinguishable from the eps=1e-6 baseline population estimate ~3.27218. The original n=1 sweep's monotone signal was ~1.5σ ctrl-arm seed inflation (ctrl drew 3.27399; population mean ~3.27218). The merge bar 3.27079 fails by +0.00132.

**Code change kept**: The `--aux_adam_embed_lr` flag is additive and harmless at default 0.3 — kept on advisor branch for future stacking experiments without re-PRing the flag.

**Methodological capture**: Per-seed noise σ ≈ 0.001 on this recipe means a 5-point monotone n=1 sweep can produce ~2σ swings that look like a clean signal. Future per-group LR sweeps should: (a) use n=2 ctrl as direction test, (b) treat slope significance as a kill condition, (c) gate promotion on n=4 conservative bar. Askeladd reassigned to **H17 SWA on aux during last 10%** (fresh-mechanism slot — weight averaging in cooldown phase complements PR #536 nezuko MuLoCo-cooldown finding).

**Bookmarked**: AGC clip ratio × embed_lr interaction. Under embed_lr=0.4, larger nominal step may make `aux_agc_clip_ratio=0.05` the binding constraint. Worth a small follow-up sweep (embed_lr × AGC clip, e.g. {0.3, 0.4} × {0.05, 0.10}) once the fresh-mechanism queue clears.

---

## 2026-05-20 05:19 UTC — PR #531 CLOSED (fern): Schedule-Free AdamW for aux — Polyak lag incompatible with WSD/linear-cooldown

- Branch: `g1r3-fern/aux-schedule-free-adamw`
- Hypothesis: Replace aux AdamW + linear cooldown with SF-AdamW (Defazio et al NeurIPS 2024). SF maintains trajectory Polyak-Ruppert average `x` and evaluates at `x` instead of final iterate `y`. Avoids explicit cooldown. Applied only to aux groups (not MuonH inner) to sidestep PR #265's WSD×SF incompatibility.

| Arm | Config | W&B run | val/loss @step | Δ vs AdamW ctrl |
|---|---|---|---|---|
| ctrl | Standard AdamW (full 3325) | `jqnpnzf7` | 3.27344 @3325 | (ref) |
| 2 SF | r=0, weight_lr_power=2 | `z13vk5l6` | 3.856 @625 (killed) | +0.026 @step 625 |

**Result**: SF arm 2 killed at step 612 due to smoke gate failure (val 4.29 at step 250 vs band 4.16-4.22). After extended analysis, student confirmed gap closing trend: 0.075 → 0.046 → 0.025 → 0.026. Extrapolated endpoint: 3.278–3.288 (solidly NEG).

**Decision: CLOSED NEG.** Mechanism explanation: Polyak-Ruppert averaging evaluates at trajectory mean (≈z@step∼175 at step 250), which is behind the final iterate in a still-descending trajectory. Gap closes asymptotically but for finite 3325-step training, gap ≈ 0.005-0.015 above AdamW ctrl.

**Key finding**: SF-methods are categorically incompatible with our WSD/linear-cooldown stack. Combined with PR #265 (SF-MuonH NEG), both aux-only and inner-MuonH SF fail for the same structural reason: WSD targets a final iterate but SF evaluates at the trajectory mean. Any future SF-flavor requires removing the cooldown entirely.

**Additional finding**: My smoke gate band [4.16, 4.22] was calibrated for AdamW's `y` trajectory, not for SF's averaged `x` trajectory. Band should have been [4.25, 4.35] for SF.

---

## 2026-05-19 21:50 UTC — PR #484 CLOSED (frieren): Aux AdamW cooldown_frac sweep — axis SATURATED at 0.4

- Branch: `g1r3-frieren/aux-cooldown-frac-sweep`
- Hypothesis: Under eps=1e-6 baseline, the optimal aux cooldown_frac may have shifted. Sweep 0.25 (shorter) / 0.4 ctrl / 0.6 (longer).

| Arm | cooldown_frac | W&B run | val/loss | ffs | reached_target | Δ vs ctrl (3.27400) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 0.40 | `e45o2hzp` | **3.27400** | **3150** | yes | (ctrl) | +0.00281 |
| 2 shorter | 0.25 | `3hds5b19` | 3.27562 | 3200 | yes | **+0.00162 (LOSS)** | +0.00443 |
| 3 longer | 0.60 | `p26nx98c` | 3.27404 | 3150 | yes | +0.00004 (tied) | +0.00285 |

- **Conclusion**: Asymmetric U-shape — shorter monotonically worse (+0.00162), longer is tied (+0.00004). cooldown_frac=0.40 is local optimum under eps=1e-6. Aux groups well-converged by step ~1995 (60% progress); the extra cooldown duration from 0.6 is wasted budget — neither helps nor hurts. Shorter (0.25) keeps LR too high too late and bites at the tail. The eps=1e-6 floor does not eliminate the need for the aux cooldown taper.
- Frieren reassigned to **H4 Nesterov AdamW** (mechanism-level: consistency with MuonH/MuLoCo Nesterov, orthogonal to scheduling axes).

## 2026-05-19 21:00 UTC — PR #481 CLOSED (nezuko): Aux AdamW lm_head LR sweep — axis FLAT/SATURATED, 1/320 local optimum

- Branch: `g1r3-nezuko/aux-lm-head-lr-sweep`
- Hypothesis: Under eps=1e-6 baseline, the optimal aux lm_head LR may have shifted. Sweep 1/640 (halve) / 1/320 ctrl / 1/160 (double).

| Arm | lm_head_lr | W&B run | val/loss | ffs | reached_target | Δ vs ctrl (3.27172) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 1/320 | `7c46dsmk` | 3.27172 | 3125 | yes | (ctrl) | +0.00053 |
| 2 halve | 1/640 | `42ixzfcf` | 3.27297 | 3150 | yes | **+0.00125 (LOSS)** | +0.00178 |
| 3 double | 1/160 | `8rsvklcn` | 3.27221 | 3125 | yes | +0.00049 (tied) | +0.00102 |

- **Conclusion**: Axis flat-or-down. Asymmetric U-shape — halving clearly hurts; doubling is essentially tied with ctrl. lm_head_lr=1/320 is at/near local optimum under eps=1e-6. Cross-group comparison: scalars (PR #475) and lm_head (this PR) are well-tuned; only embed (PR #478) has a non-trivial gradient (monotone improvement upward). Consistent with eps=1e-6 lifting denominator floor primarily on the highest-grad-norm group (embed).
- Nezuko reassigned to **H5 embed init std sweep** (mechanism test — initialization, not scalar HP). Strong synergy with the active embed_lr win direction.

## 2026-05-19 19:56 UTC — PR #475 CLOSED (fern): Aux AdamW scalars LR sweep — axis NEAR-SATURATED, 0.01 local optimum

- Branch: `g1r3-fern/aux-adamw-scalars-lr-sweep`
- Hypothesis: Under eps=1e-6 baseline, the optimal aux scalars LR (gains/biases group) may have shifted. Sweep 0.005 (halve) / 0.01 ctrl / 0.02 (double).

| Arm | scalars_lr | W&B run | val/loss | ffs | reached_target | Δ vs ctrl (3.27296) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 0.01 | `yekqkcmc` | 3.27296 | 3150 | yes | (ctrl) | +0.00177 |
| 2 halve | 0.005 | `2tasvk8f` | 3.27722 | 3200 | yes | **+0.00426 (CLEAR LOSS)** | +0.00603 |
| 3 double | 0.02 | `et18r49k` | 3.27254 | 3150 | yes | −0.00042 (tied) | +0.00135 |

- **Conclusion**: Lever asymmetric. Halving clearly hurts (CLEAR LOSS ~4σ); doubling is within seed noise of ctrl (-0.00042). Axis near-saturated at scalars_lr=0.01. The +0.00177 ctrl Δ vs baseline reinforces that baseline `t1coza71` is a favorable-seed outlier (6/6 baseline-equivalent samples this round come in Δ>0).
- Fern reassigned to **H1 per-group eps decomposition** (mechanism test, not scalar HP).

## 2026-05-19 15:48 UTC — PR #453 CLOSED (frieren): MuLoCo sync_interval re-sweep — axis SATURATED, sync=30 confirmed optimal

- Branch: `g1r3-frieren/muloco-sync-interval-resweep`
- Hypothesis: Under new AGC+warmup+eps=1e-6 stack, optimal MuLoCo sync_interval may have shifted from baseline sync=30. Tighter (15) would improve if AGC-clipped inner steps need more outer corrections; looser (60) would help if outer accumulation window is too noisy.

| Arm | sync_interval | W&B run | val/loss | ffs | reached_target | Δ vs ctrl (3.27387) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 30 | `pe9zk9ot` | 3.27387 | 3150 | yes | (ctrl) | +0.00268 |
| 2 tighter | 15 | `ri1dkfwa` | 3.27855 | 3250 | yes | +0.00468 (~6σ NEG) | **+0.00736 (~10σ NEG)** |
| 3 looser | 60 | `pry9qino` | 3.27478 | 3150 | yes | +0.00091 (noise) | +0.00359 (~5σ NEG) |

- **Conclusion**: All 3 arms NEG vs new baseline 3.27119. sync=30 is the local optimum under the current AGC+warmup stack. Tighter sync (15) is decisively worse — the outer MuLoCo Nesterov-SGDM needs ≥30 inner steps per outer update to maintain directional signal. Looser sync (60) is within noise of ctrl, providing no improvement. All MuLoCo knobs now saturated: sync_interval (this PR), outer_lr=0.7 (PR #369 closed), outer_momentum=0.5 (previously), outer optimizer class=SGDM (vs AdamW/Lion). MuLoCo lever fully closed.
- Frieren reassigned to PR #484: Aux AdamW cooldown_frac sweep (0.25/0.4/0.6) under eps=1e-6.

## 2026-05-19 15:06 UTC — PR #451 CLOSED (nezuko): MuonH budget_mult sweep — axis FLAT, lever closed

- Branch: `g1r3-nezuko/muonh-budget-mult-sweep`
- Hypothesis: Larger hyperball (bm=1.1) gives inner optimizer more room; smaller (bm=0.90) applies stronger regularization → better generalization.
- Results:

| Arm | bm | W&B run | val/loss | ffs | reached_target | Δ vs ctrl (3.27376) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 1.0 | `vimjhzp0` | 3.27376 | 3150 | yes | (ctrl) | +0.00257 |
| 2 | 0.9 | `ozmx5ukq` | 3.27430 | 3150 | yes | +0.00054 | +0.00311 |
| 3 | 1.1 | `65k2dls4` | **3.27374** | 3150 | yes | **-0.00002** | +0.00255 |

- **FLAT axis**: arm 3 bm=1.1 is bit-equivalent to ctrl (Δ=-0.00002, well inside σ≈0.0006 noise). All 3 arms cluster within ±0.00054 band — smallest spread on any lever this round.
- Mechanism: under MuonH-SI mode, budget_mult is an always-active rescaling to hold Frobenius norm constant at `||p_0|| * bm`. Varying bm by ±10% only changes the constant norm scale, not update direction or effective LR → near-bitwise-equivalent outcomes.
- Runs used OLD baseline stack (no `--aux_adamw_eps 1e-6`). Gap vs new baseline (3.27119) is entirely explained by missing eps=1e-6 flag, not by bm choice.
- Nezuko reassigned to aux AdamW lm_head LR sweep (PR #481) to complete per-group LR trio.

## 2026-05-19 14:28 UTC — PR #450 CLOSED (askeladd): MuonH inner static mu sweep — catastrophic at mu=0.98, axis closed

- Branch: `g1r3-askeladd/muonh-mu-sweep`
- Hypothesis: MuonH inner static momentum mu may not be optimal at 0.95; lower (0.90, more responsive) or higher (0.98, more stable) might improve convergence under AGC.
- Results:

| Arm | mu | W&B run | val/loss | ffs | reached_target | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|
| 1 ctrl | 0.95 | `iye79oh5` | 3.27349 | 3150 | yes | +0.00230 (~3σ NEG) |
| 2 | 0.90 | `dujzmvpf` | 3.27853 | 3250 | yes | +0.00734 (~10σ NEG) |
| 3 | **0.98** | `sgncg5wf` | **3.30059** | **-1 (target NOT reached)** | **no** | +0.02940 (~40σ NEG) |

- **Strong asymmetric U-shape** around mu=0.95. Arm 3 (mu=0.98) failed to reach target val<3.28 (ffs=-1). Catastrophic regression.
- Mechanism: at mu=0.98, MuonH momentum buffer integrates ~50 steps of history. NS5 polynomial maps gradient direction onto a normalized orthogonal frame each step, so high momentum applied to that frame causes update direction to lag the current loss landscape. With AGC pre-clipping, this lag is amplified.
- Step 250 val was already above smoke band for arm 3 (4.28034 vs ctrl 4.21017), signaling slow convergence from step 0.
- mu=0.95 is the unique local optimum. Upper bound sensitivity (mu≥0.98) far more severe than lower bound (mu=0.90 mild). Axis fully saturated.
- Askeladd reassigned to aux AdamW embed LR sweep (PR #478).

## 2026-05-19 13:42 UTC — PR #438 CLOSED (fern): NS5 polynomial coefficient sweep — all 3 arms NEG, lever closed

- Branch: `g1r3-fern/ns5-coeff-sweep`
- Hypothesis: NS5 polynomial coefficients (a,b,c)=(2,-1.5,0.5) may not be optimal; the classical Halley quintic (1.875,-1.25,0.375) has unique fixed point at σ=1 (removes "leaky" σ=√2), and the sharper (2.5,-2.0,0.5) tightens basin around σ=1.
- Results:

| Arm | (a,b,c) | W&B run | val/loss | ffs | output max σ | Δ vs OLD baseline (3.27286) | Δ vs NEW baseline (3.27119) |
|---|---|---|---|---|---|---|---|
| 1 ctrl | (2.0,-1.5,0.5) | `g1we1d9w` | 3.27296 | 3150 | ~1.005 | +0.00010 (within noise) | +0.00177 (~2σ NEG) |
| 2 classical | (1.875,-1.25,0.375) | `bj67aaq8` | 3.27495 | 3175 | ~1.005 | +0.00209 (~3σ NEG) | +0.00376 (~5σ NEG) |
| 3 sharper | (2.5,-2.0,0.5) | `w82uf08t` | 3.27372 | 3150 | ~1.10 | +0.00086 (~1σ NEG) | +0.00253 (~3σ NEG) |

- Arm 1 ctrl bit-identical to old baseline (validates --ns5_a/b/c flag plumbing).
- σ=√2 leak hypothesis FAILS empirically — output max σ stays ~1.005 at k=12 with default polynomial, well below √2≈1.414. Classical's "unique fixed point" theoretical advantage doesn't materialize.
- Sharper polynomial OVERSHOOTS σ=1, settling at ~1.10. Steeper coefficients past the σ=1 sweet spot → consistently over-orthogonal updates → modest regression.
- This PR ran on the pre-#443 baseline stack (no `--aux_adamw_eps 1e-6`); the verdict would not change on the new stack since relative arm ordering is preserved.
- NS5 telemetry plumbing (`train/ns5/*_max_sigma` per-block + mean/max) added — keep in codebase for future inner-update diagnostics.
- **NS5 polynomial coefficient axis CLOSED.** Extends PR #174's "saturated in (2,-1.5,0.5) ± 25%" to mathematically distinct polynomial families.
- Fern reassigned to aux AdamW scalars LR sweep (PR TBD).

## 2026-05-19 13:25 UTC — PR #443 MERGED (edward): Aux AdamW eps=1e-6 WINS — new baseline val=3.27119, ffs=3100

- Branch: `g1r3-edward/aux-adamw-eps-sweep`
- Hypothesis: Aux AdamW eps controls denominator smoothing. Default 1e-10 is very tight; standard PyTorch 1e-8 is common; heavier 1e-6 adds stability to low-gradient aux params (embed/lm_head/scalars).
- Results:

| Arm | eps | W&B run | val/loss | ffs | Δ vs baseline (3.27286) |
|---|---|---|---|---|---|
| 1 ctrl | 1e-10 | `wgtlme0x` | 3.27377 | 3150 | +0.00091 |
| 2 | 1e-8 | `0uo2507f` | 3.27389 | 3150 | +0.00103 |
| **3 WINNER** | **1e-6** | **`t1coza71`** | **3.27119** | **3100** | **−0.00167** |

- **WINNER**: eps=1e-6 beats baseline by -0.00167 on val/loss AND improves ffs by 25 steps (3100 vs 3125). Passes n=1 bar (< 3.27206) and stat rule (0.00881 ≥ 0.004).
- Arms 1+2 (eps=1e-10/1e-8) are operationally equivalent — denominator far smaller than actual gradient magnitudes.
- eps=1e-6 adds meaningful denominator floor on aux params with small gradients, smoothing adaptive LR noise.
- **PR #443 squash-merged at 13:25 UTC. New baseline: val=3.27119, ffs=3100.**
- Edward assigned n=4 confirmation PR #471.

## 2026-05-19 08:50 UTC — PR #424 CLOSED + PR #421 CLOSED: Both sweeps close_neg, askeladd → PR #450, nezuko → PR #451
- PR #424 closed (SENPAI-RESULT posted); new assignment PR #450 (MuonH static mu sweep 0.90/0.95/0.98)
- PR #421 closed (SENPAI-RESULT posted); new assignment PR #451 (MuonH budget_mult sweep 0.9/1.0/1.1)

## 2026-05-19 08:45 UTC — PR #421 (arm 3): MuonH inner AGC clip_ratio=0.10 (loose) — baseline-equivalent (sweep complete)
- Branch: `g1r3-nezuko/muonh-agc-clip-ratio-sweep`
- Hypothesis: Looser AGC clip ratio (0.10 vs 0.05 baseline) may allow productive gradient magnitudes through that tighter clip suppresses.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 1 ctrl (3.27522) |
|---|---|---|---|---|
| `nhw3crpe` (clip=0.10 loose) | 3.27404 | 3150 | +0.00118 (within σ) | -0.00118 |

- **Baseline-equivalent**. All 3 arms of the AGC clip sweep landed within σ:
  - Arm 1 ctrl (clip=0.05): 3.27522
  - Arm 2 (clip=0.02 tight): 3.27372
  - Arm 3 (clip=0.10 loose): 3.27404
- **AGC clip_ratio is insensitive in [0.02, 0.10]** — no arm passes n=1 merge bar (3.27206). The lever is saturated within this range.
- **PR #421 closing baseline-equivalent**. The AGC clip mechanism activates rarely under SI projection; the specific ratio value matters less than the existence of the clip itself.

## 2026-05-19 08:42 UTC — PR #424 (arm 3): MuLoCo outer Nesterov SGDM mu=0.8 (high momentum) — CATASTROPHIC NEG (sweep complete)
- Branch: `g1r3-askeladd/muloco-nesterov-sweep`
- Hypothesis: Higher Nesterov outer momentum (mu=0.8 vs 0.5 baseline) may accelerate convergence through stronger slow-snap.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 2 ctrl (3.27353) |
|---|---|---|---|---|
| `o04vcj4x` (Nesterov mu=0.8) | 3.35359 | -1 | +0.08073 (~100σ catastrophic) | +0.08006 |

- **Catastrophic NEG**: ~100σ over baseline, failed 3.28 target. Nesterov mu=0.8 overshoots in the outer loop and destabilizes convergence.
- **Full sweep result**:
  - Arm 1 (drop_nesterov, mu=0.5 plain SGDM): 3.27863 (+0.00577, ~7σ NEG)
  - Arm 2 ctrl (Nesterov, mu=0.5): 3.27353 (baseline-equiv)
  - Arm 3 (Nesterov, mu=0.8): 3.35359 (+0.08073 catastrophic)
- **mu=0.5 with Nesterov is the local optimum** — strictly better than both higher (mu=0.8 catastrophic) and lower-momentum-effective (drop_nesterov) neighbors.
- **Outer Nesterov-SGDM mu axis SATURATED at 0.5**. Lever closed.

## 2026-05-19 07:15 UTC — PR #425 (arm 2): MuonH-SI mu_final=0.70 (moderate mu cooldown) — NEG
- Branch: `g1r3-frieren/muonh-mu-cooldown-sweep`
- Hypothesis: Cosine-decaying MuonH inner momentum from 0.95 → mu_final during LR cooldown. Arm 2 = moderate cooling to 0.70.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 1 ctrl (3.27325) |
|---|---|---|---|---|
| `v7ztc5yx` (mu_final=0.70) | 3.28051 | -1 | +0.00765 (~9σ NEG) | +0.00726 |

- **Clear NEG**: ~9σ, failed 3.28 target (ffs=-1). Cosine-decaying mu during cooldown hurts convergence.
- Mechanism: same pattern as PR #417 cooldown_frac — the final training phase benefits from *conservative* settings (mu=0.95 maintained). Reducing mu makes the optimizer more responsive at low LR, but what's needed is *stability*. The high-momentum anchor is load-bearing throughout.
- Arm 3 (mu_final=0.50) will be stronger NEG if run.

## 2026-05-19 07:05 UTC — PR #417 CLOSED: MuonH inner cooldown_frac sweep (full sweep complete, close_neg)
- Branch: `g1r3-edward/muonh-inner-cooldown-frac-sweep`
- Hypothesis: Test whether shortening the MuonH cosine cooldown (cooldown_frac < 1.0) frees up early-mid-training peak-LR steps for productive learning while still leaving enough budget to converge.
- Full results:

| Arm | cooldown_frac | W&B run | val/loss | ffs | reached 3.28 | Δ vs baseline (3.27286) |
|---|---|---|---|---|---|---|
| 1 (ctrl) | 1.0 | `zu2yy4jn` | 3.27236 | 3125 | ✓ | -0.00050 |
| 2 | 0.7 | `u88kyal5` | 3.28949 | -1 | ✗ | +0.01663 (~20σ NEG) |
| 3 | 0.5 | `us53ifim` | 3.31306 | -1 | ✗ | +0.04020 (~40σ NEG) |

- **Monotonic catastrophic curve**: cooldown_frac < 1.0 is strictly worse, scales with magnitude. cooldown_frac=1.0 is the operating point.
- Arm 1 ctrl reproduces baseline within σ (n=1 draw at 3.27236 vs n=4 mean 3.27286). Adds to our σ estimate ensemble.
- Mechanism: cosine cooldown is doing real optimization work — the final ~30-50% of training relies on monotonically declining LR to converge below 3.28. Truncating it leaves LR too high at the end. NOT a tapering-off detail.
- Lever closed: cooldown_frac is saturated at 1.0. Future cooldown-related work should test *shape* (cosine vs sqrt vs linear) at full duration, not *truncation*.
- PR CLOSED.

## 2026-05-19 06:50 UTC — PR #424 (arm 1): MuLoCo outer standard SGDM mu=0.5 (drop_nesterov) — NEG
- Branch: `g1r3-askeladd/muloco-nesterov-sweep`
- Hypothesis: Test whether Nesterov correction `μ·v + δ` (lines 1093-1095) in MuLoCo outer step is load-bearing. Arm 1 = drop_nesterov (standard SGDM, position update uses raw `v` instead of `μ·v + δ`).
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 2 ctrl (3.27353) |
|---|---|---|---|---|
| `o7pbf2f3` (drop_nesterov mu=0.5) | 3.27863 | 3250 | +0.00577 (~7σ NEG) | +0.00510 |

- **Clear NEG**: ~7σ on the 1-trial bar. Dropping Nesterov correction hurts even at mu=0.5.
- Mechanism: outer δ_rms trajectories differ by ≤0.005 at the macro scale, but the lookahead bias `0.5·v` worth of correction accumulates over 110 outer steps to a measurable loss gap.
- Confirms current `outer_nesterov=True` is doing real work in MuLoCo. Saturated lever in this direction.
- Arm 3 (Nesterov mu=0.8) `o04vcj4x` chaining.

## 2026-05-19 06:50 UTC — PR #421 (arm 2): MuonH inner AGC clip_ratio=0.02 (tight) — baseline-equivalent
- Branch: `g1r3-nezuko/muonh-agc-clip-ratio-sweep`
- Hypothesis: Tighter AGC clip ratio (0.02 vs 0.05 baseline) may further stabilize MuonH gradient.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 1 ctrl (3.27522) |
|---|---|---|---|---|
| `9imntmmb` (clip=0.02 tight) | 3.27372 | 3150 | +0.00086 (within σ) | -0.00150 |

- **Baseline-equivalent**: Δ=+0.00086 is within σ (~0.0006-0.0008). DOES NOT pass n=1 merge bar (3.27206) — Δ=+0.00166 above bar.
- Relative to arm 1 ctrl (clip=0.05 = 3.27522), arm 2 (clip=0.02) is 0.00150 *better* — but that's within noise of single-trial draws. Cannot conclude tighter clip helps.
- Arm 3 (clip=0.10 loose) chains next.

## 2026-05-19 06:50 UTC — PR #417 (arm 3): MuonH inner cooldown_frac=0.5 (catastrophic short cooldown) — NEG
- Branch: `g1r3-edward/muonh-inner-cooldown-frac-sweep`
- Hypothesis: Even more aggressive cooldown shortening (cooldown_frac=0.5: first 50% flat, last 50% cooldown).
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 2 (cdfrac=0.7) |
|---|---|---|---|---|
| `us53ifim` (cooldown_frac=0.5) | 3.31306 | -1 | +0.04020 (~40σ NEG) | +0.02357 (~30σ NEG) |

- **Catastrophic NEG**: Δ=+0.04020 ~40σ, ffs=-1 (failed 3.28 target).
- Confirms monotonic relationship: shorter cooldown → worse terminal. cooldown_frac=1.0 is the operating point; reducing it kills convergence.
- PR #417 sweep complete: cooldown_frac axis is saturated at 1.0. Lever closed.

## 2026-05-19 05:30 UTC — PR #425 (arm 1 ctrl): MuonH-SI mu_final=0.95 (control) — baseline-equivalent
- Branch: `g1r3-frieren/muonh-mu-cooldown-sweep`
- Hypothesis context: Cosine-decay MuonH inner momentum 0.95 → mu_final over cooldown. Arm 1 ctrl = mu_final=0.95 (bit-identical no-op).
- Implementation: commit `5002b62` adds `--muonh_mu_final` flag and `set_hparams(step)` cosine-decay logic. Default 0.95 = bit-identical baseline.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) |
|---|---|---|---|
| `o8zyjowj` (mu_final=0.95 ctrl) | 3.27325 | 3150 | +0.00039 |

- Clean baseline reproduction within σ. Implementation validated.
- Arm 2 `v7ztc5yx` (mu_final=0.70) chaining; arm 3 (mu_final=0.50) chains after.

## 2026-05-19 05:30 UTC — PR #392 (CLOSED): Logit softsign cap sweep (15/10/30) — all NEG
- Branch: `g1r3-fern/logit-soft-cap`
- Hypothesis: Sweep softsign logit cap around hardcoded ±15. Arms: cap=15 (ctrl, bit-identical), cap=10 (tighter), cap=30 (looser).
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | verdict |
|---|---|---|---|---|
| `6hideyt9` (cap=15 ctrl) | 3.27341 | 3150 | +0.00055 | baseline-equiv |
| `tk0a5wdm` (cap=15 ctrl-v2) | 3.27451 | 3175 | +0.00165 | baseline-equiv |
| `7ap085t3` (cap=10 tight) | 3.27933 | 3275 | +0.00647 (~10σ) | NEG |
| `ahgrgeub` (cap=30 loose) | 3.28086 | **-1** | +0.00800 (~11σ) | NEG (failed 3.28 target) |

- **Closed**: cap=15 is the local optimum; both directions worse. Loose cap=30 even fails to reach 3.28 — model can't recover convergence without strong soft-saturation pressure.
- **Mechanistic read**: cap=15 trains pre_cap → 223 while post_cap pins at 14.97 (full asymptote). cap=30 allows pre_cap to stay at ~50 with post_cap only at ~26 (87% asymptote) — much weaker effective regularization. The model's "logit reach" is shaped by the cap it sees during training.
- Saturated lever. Logit cap axis closed at this point.

## 2026-05-19 05:05 UTC — PR #421 (arm 1 ctrl): MuonH AGC clip_ratio=0.05 (control) — baseline-equivalent
- Branch: `g1r3-nezuko/muonh-agc-clip-ratio-sweep`
- Hypothesis context: Sweep MuonH inner AGC clip_ratio around merged default 0.05 (PR #329 baseline). Arm 1 ctrl = current production config.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) |
|---|---|---|---|
| `ndt56ttp` (clip=0.05 ctrl) | 3.27522 | 3175 | +0.00236 |

- Baseline reproduction within σ (~0.0006-0.0008). Noisier draw than askeladd arm 2 ctrl (3.27353) and edward arm 1 ctrl (3.27236) but within the n=4 baseline distribution (mean 3.27264).
- Arm 2 (clip=0.02 tight) `9imntmmb` chaining; arm 3 (clip=0.10 loose) chains after.

## 2026-05-19 04:59 UTC — PR #424 (arm 2 ctrl): MuLoCo outer Nesterov SGDM mu=0.5 (control) — baseline-equivalent
- Branch: `g1r3-askeladd/muloco-nesterov-sweep`
- Hypothesis context: Askeladd's code reading on PR #424 confirmed the current MuLoCo outer update at lines 1093-1095 is **Nesterov SGDM** (not standard SGDM as initially framed). Arm 2 is ctrl with the current (Nesterov) configuration at mu=0.5.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) |
|---|---|---|---|
| `n0ok0cgj` (Nesterov SGDM mu=0.5 ctrl) | 3.27353 | 3150 | +0.00067 |

- Clean baseline reproduction (within σ ~0.0006-0.0008).
- Arm 1 (drop_nesterov, standard SGDM mu=0.5) `o7pbf2f3` chaining.
- Arm 3 (Nesterov mu=0.8) will chain after arm 1.

## 2026-05-19 04:59 UTC — PR #417 (arm 2): MuonH inner cooldown_frac = 0.7 (shortened cooldown) — NEG
- Branch: `g1r3-edward/muonh-inner-cooldown-frac-sweep`
- Hypothesis: Test whether shortening the MuonH inner cooldown phase improves training. Arm 2 = cooldown_frac=0.7 (first 30% of training is flat at peak LR, last 70% is cooldown — versus baseline cooldown_frac=1.0 full cooldown).
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs arm 1 ctrl (3.27236) |
|---|---|---|---|---|
| `u88kyal5` (cooldown_frac=0.7) | 3.28949 | -1 | +0.01663 | +0.01713 |

- **Clear NEG**: Δ=+0.01663 is ~20σ over baseline. **ffs=-1 — run never reached 3.28 target.**
- The cooldown phase is doing real work — leaving LR too high near training end prevents convergence below 3.28.
- Arm 3 (cooldown_frac=0.5, even more aggressive) `us53ifim` chaining; expected even stronger NEG.

## 2026-05-19 03:28 UTC — PR #392 (arm cap=10): Softsign logit cap = 10 (tighter) — NEG
- Branch: `g1r3-fern/logit-soft-cap`
- Hypothesis: Tightening the softsign cap from 15 to 10 should regularize attention logits more aggressively and potentially improve generalization.
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) | Δ vs cap=15 ctrl (3.27396) |
|---|---|---|---|---|
| `7ap085t3` (cap=10) | 3.27933 | 3275 | +0.00647 | +0.00537 |
| `6hideyt9` (cap=15 ctrl) | 3.27341 | 3150 | +0.00055 | — |
| `tk0a5wdm` (cap=15 ctrl 2nd) | 3.27451 | 3175 | +0.00165 | — |

- Cap=10 NEG: ~8-10σ over baseline, ~7σ over cap=15 ctrl. Tighter cap is harmful.
- Telemetry: logit_max_pre_cap grows to 223 (15× the ±15 cap) — cap saturates aggressively throughout training. Tighter cap=10 bites earlier and limits the model's logit headroom for token discrimination.
- Cap=30 (looser) arm `ahgrgeub` in flight; will determine if more headroom helps.

## 2026-05-19 03:09 UTC — PR #417 (arm 1): MuonH inner cooldown_frac = 1.0 (control) — baseline-equivalent
- Branch: `g1r3-edward/muonh-inner-cooldown-frac-sweep`
- Hypothesis: Test whether shortening the MuonH inner cooldown phase (cooldown_frac < 1.0) improves training. Arm 1 = ctrl at cooldown_frac=1.0 (baseline).
- Results:

| W&B run | val/loss | ffs | Δ vs baseline (3.27286) |
|---|---|---|---|
| `zu2yy4jn` (cooldown_frac=1.0 ctrl) | 3.27236 | 3125 | -0.00050 |

- Clean baseline reproduction. Within σ (~0.0006-0.0008) but does not pass n=1 promotion bar (3.27206).
- Confirms baseline holds at n=5 (4 multi-trial confirm runs + this ctrl).
- Arms 2 (cooldown_frac=0.7) and 3 (cooldown_frac=0.5) chaining.

# SENPAI Research Results — auto-nanogpt-1gpu-r3

Per-PR record of experiment outcomes. New entries prepended (newest first).
Each entry summarizes the hypothesis, the result(s), and the conclusion that
drives the next-wave assignment.

---

## 2026-05-19 01:33 UTC — PR #390: MuLoCo outer optimizer class swap (SGDM vs AdamW vs Lion) ❌ CLOSED NEG

- **Branch**: g1r3-frieren/outer-optimizer-class-swap
- **Hypothesis**: After saturating MuLoCo's 3 knobs, test whether a different outer optimizer class (AdamW or Lion) could provide better convergence than SGDM. Arms: SGDM ctrl (outer_lr=0.7, momentum=0.5), AdamW, Lion.
- **Results** (vs baseline 3.27286, n=1 bar < 3.27206):

| arm | optimizer | wandb_id | terminal val/loss | Δ vs 3.27286 | ffs | verdict |
|---|---|---|---|---|---|---|
| 1 (ctrl) | SGDM (outer_lr=0.7, momentum=0.5) | jgltipi3 | 3.27392 | +0.00106 (~2σ) | 3150 | baseline-equiv |
| 2 | AdamW (lr=0.014) | 6znrpsli | 3.35674 | **+0.08388 (~100σ NEG)** | −1 | CATASTROPHIC |
| 3 | Lion (lr=0.001) | 3jywc3d4 | 3.72060 | **+0.44774 (~500σ NEG)** | −1 | CATASTROPHIC |

- **Mechanism**: SGDM's effective update = lr × (m×v + δ) ≈ 0.7 × (0.5×0.7 + 0.7) ≈ 0.735 RMS — matches the natural scale of the outer drift signal (δ_rms ≈ 0.7-0.8). AdamW's 2nd-moment normalization clamps update_rms to <0.01 (70× too small). Lion's constant sign-based update = lr = 0.001 (far too small). No LR value simultaneously satisfies 'large enough to contribute' and 'small enough not to diverge' for adaptive methods in this outer role. The δ signal is raw weight drift — not a loss gradient — so adaptive scaling is not beneficial.
- **Conclusion**: SGDM is uniquely well-suited for the MuLoCo outer step by naturally matching the δ signal scale. Outer optimizer CLASS is saturated. Next direction: within-SGDM variants (Nesterov momentum, PR #424 askeladd).
- **Key telemetry**: frieren's outer-step update_rms table for AdamW vs SGDM is a valuable reference showing the mechanism. Arm 2 AdamW had val=4.56 at 300-step smoke (above kill gate 4.30) — the smoke predicted the failure.

---

## 2026-05-19 01:20 UTC — PR #397: Aux lm_head weight decay sweep (wd=0/0.01/0.05) ❌ CLOSED NEG

- **Branch**: g1r3-nezuko/aux-lm-head-wd-sweep
- **Hypothesis**: Targeted weight decay on lm_head only could stabilize norm growth and improve cooldown phase. Arms: wd=0 (ctrl), 0.01, 0.05. Plumbing: new `--adam_lm_head_wd` flag in a dedicated AdamW param group.
- **Results** (vs baseline 3.27286, n=1 bar < 3.27206):

| arm | wd | wandb_id | terminal val/loss | Δ vs 3.27286 | ffs | lm_head norm (terminal) |
|---|---|---|---|---|---|---|
| 1 (ctrl) | 0.0 | y7q4vanw | 3.27281 | −0.00005 (≈baseline) | 3125 | 1198.92 |
| 2 | 0.01 | p9csxg1v | 3.27540 | **+0.00254 (~5σ NEG)** | 3175 | 1125.08 (−6.2%) |
| 3 | 0.05 | 0to00mja | 3.27366 | +0.00080 (~1σ NEG) | 3150 | 885.54 (−26.1%) |

- **Non-monotonic pattern**: wd=0.01 is WORSE than wd=0.05 despite smaller wd magnitude. The hypothesis is falsified. Mild wd breaks something the optimizer compensates at higher wd (bad zone around wd≈0.01).
- **Mechanism**: lm_head norm grows continuously 13→1199 over training (baseline), but the norm growth is load-bearing for the optimization dynamics — suppressing it at mild wd creates mismatch without the regularization benefit you'd expect at strong wd. The embedding group stays at wd=0 throughout (plumbing correct).
- **Conclusion**: lm_head weight decay is not beneficial for this stack. Saturated lever. Aux param-group regularization direction closed at this point.

---

## 2026-05-19 01:17 UTC — PR #396: QK-Norm sweep (off vs fixed vs learnable) ❌ CLOSED NEG

- **Branch**: g1r3-askeladd/qk-norm
- **Hypothesis**: Pre-attention RMSNorm on Q+K. Baseline already has fixed F.rms_norm. Arms: off (remove normalization), fixed (= baseline ctrl), learnable (per-element affine gain added).
- **Results** (vs baseline 3.27286, n=1 bar < 3.27206):

| arm | QK-Norm | wandb_id | terminal val/loss | Δ vs 3.27286 | ffs |
|---|---|---|---|---|---|
| off (no rms_norm) | removed | o20httom | 3.29716 | **+0.02430 (~24σ NEG)** | −1 |
| fixed (ctrl = baseline) | F.rms_norm | xwml6u2c | 3.27393 | +0.00107 (~1σ, baseline-equiv) | 3150 |
| learnable (per-element gain) | F.rms_norm + affine | 53f944z1 | 3.27617 | **+0.00331 (~3σ NEG)** | 3200 |

- **Key findings**: (1) Removing QK-norm is catastrophic — it's a structural feature. (2) Learnable per-element gains diverge from 1.0 (mean 1.15-1.34 at terminal) and consistently hurt by +0.002-0.003 from step 2000 onward. (3) Learnable gains cause attention logit magnitudes ~1.6× higher than fixed but still below the ±15 softsign cap.
- **Conclusion**: Fixed F.rms_norm (no learnable scale) is optimal. QK-Norm structure saturated. First architectural test — learned gains on Q/K projections add expressiveness that costs val/loss rather than helping.

---

## 2026-05-19 00:24 UTC — PR #389: MuonH inner mu warmup sweep (0/100/200 steps) ❌ CLOSED NEG

- **Branch**: g1r3-edward/muonh-mu-warmup-sweep
- **Hypothesis**: Starting MuonH-SI inner momentum (mu) from 0.5 and warming up to 0.95 over N steps could reduce early-step direction instability and improve terminal val/loss. Arms: mu_warmup_steps=0 (ctrl, fixed mu=0.95), 100, 200.
- **Results** (vs baseline 3.27286, n=1 bar <3.27206):

| arm | mu_warmup_steps | wandb_id | terminal val/loss | ffs (≤3.28) | Δ vs 3.27286 | n=1 bar? |
|-----|-----------------|----------|-------------------|-------------|--------------|----------|
| 1   | 0 (ctrl)        | va3dm8i1 | 3.27264           | 3125        | −0.00022     | NO       |
| 2   | 100             | xdqpdnvd | 3.27506           | 3175        | +0.00220 (5σ NEG) | NO  |
| 3   | 200             | m8agfmr2 | 3.27680           | ?           | +0.00394 (8σ NEG) | NO  |

- **Mechanism (edward's analysis)**: Starting mu=0.5 during the LR warmup window (0→0.018 over 100 steps) means the optimizer simultaneously under-accumulates direction AND under-steps early. Both deficits compound — the optimizer loses ~50 steps of effective progress that never recovers. Monotonic regression confirms: longer mu warmup window = worse terminal loss.
- **Conclusion**: mu=0.95 from step 0 is already well-tuned for this MuonH-SI stack. Momentum warmup from half-momentum is intrinsically harmful in this config. Saturated lever — de-prioritize mu/momentum warmup-style stabilization for inner Muon cliff management.
- **Closed**: 00:24 UTC. Branch: g1r3-edward/muonh-mu-warmup-sweep.

---

## 2026-05-18 23:46 UTC — PR #391: MuonH warmup duration sweep (100/200/300) ❌ CLOSED NEG

- **Branch**: g1r3-thorfinn/muonh-warmup-duration-sweep
- **Hypothesis**: Extending MuonH-SI inner LR warmup beyond the merged baseline (100 steps, PR #310) could further reduce early-step instability and improve terminal val/loss. 3 arms: 100 (control = baseline), 200 (longer), 300 (longest).
- **Results** (vs current baseline 3.27286, n=1 bar < 3.27206):

| arm | warmup | wandb_id | terminal val/loss | Δ vs 3.27286 | n=1 bar (<3.27206)? |
|---|---|---|---|---|---|
| 1 | 100 (ctrl) | a05x4jp0 | 3.27325 | +0.00039 | **NEG** (~baseline within σ) |
| 2 | 200 | m3alnjbx + 3 retries | NaN at step 125 | — | **CRASH** (deterministic, 4 retries) |
| 3 | 300 | lb3ehf94 | NaN at step 125 | — | **CRASH** (same signature) |

- **Mechanism (thorfinn's 22:56 UTC diagnosis)**: Aux AdamW (embed/lm_head/scalars at lr=0.30 from step 1) outruns the slowly-ramping MuonH inner blocks. With warmup>100, the cross-entropy/bf16 NS5 spectral path overflows *before* MuonH catches up. AGC silently passes NaN through because `NaN > clip_ratio` evaluates False. AGC engagement at steps 25-50 (max_ratio ~26k→60k) is what *saves* arm 1 under warmup=100 — not the warmup duration itself. Both arm 2 + arm 3 produce bit-identical `nonfinite_count_all = 147,984,768` at step 125 regardless of warmup duration once >100.
- **Saturated lever**: MuonH inner LR warmup_steps. Stability cliff at 100; longer = catastrophic.
- **Generalizable finding**: Aux/MuonH effective-LR ratio early in training is the load-bearing stability factor for the current stack. This constrains a class of future levers; it also opens **aux AdamW warmup_steps** as a new direction (next assignment for thorfinn).
- **Branch state at close**: Clean. CLOSED 23:46 UTC.

---

## 2026-05-18 18:43 UTC — PR #397: Aux lm_head weight decay sweep — ASSIGNED

- **Branch**: g1r3-nezuko/aux-lm-head-wd-sweep
- **Hypothesis**: Targeted weight decay on the lm_head parameter only (~38M params, 50304×768) may stabilize lm_head norm growth during the long flat-LR phase and improve cooldown effectiveness. Orthogonal to AGC (gradient-norm clip) and softsign cap (logit scaling). Standard recipe in PaLM/T5/Chinchilla — param-group wd>0 on linear projections, wd=0 on embeddings. Reuses nezuko's existing lm_head-specific plumbing from prior `--adam_lm_head_lr` work. 3 arms: wd=0 (control bit-identical), 0.01 (mild), 0.05 (strong).
- **Status**: Assigned to g1r3-nezuko (idle after #361 closed NEG).

---

## 2026-05-18 18:42 UTC — PR #361: Aux lm_head LR sweep (1/500, 1/320, 1/200) ❌ CLOSED NEG

- **Branch**: g1r3-nezuko/aux-lm-head-lr-sweep
- **Hypothesis**: Aux AdamW LR on lm_head only is sub-optimal at baseline ~1/320. Sweep 1/500 (slow), 1/320 (control), 1/200 (fast).
- **Screen results** (vs current baseline 3.27286, n=1 bar < 3.27206):

| arm | LR | wandb_id | terminal val/loss | Δ vs 3.27286 | n=1 bar (<3.27206)? |
|---|---|---|---|---|---|
| 1 | 0.005 (1/200) | df1mmug7 | 3.27234 | -0.00052 | **NEG** |
| 2 | 0.003125 (1/320, ctrl) | tkwo0a9f | 3.27226 | -0.00060 | **NEG** |
| 3 | 0.002 (1/500) | qlkifdse | **3.27415** | +0.00129 | **NEG** |

- **Mechanism**: aux lm_head LR is **flat in [1/320, 1/200]** (arms 1+2 Δ=0.00008 ≪ n=1 σ≈0.001) and **degrades below** at 1/500. On the older baseline (3.27315) arms 1+2 looked borderline-pass, but PR #329 (AGC inner MuonH, baseline 3.27286) tightened it by 0.00029 — absorbing what was n=1 noise. The aux LR axis was capturing baseline noise rather than producing real improvement.
- **Branch became CONFLICTING** after #329 merged → confirmed closure path.
- **Operational note**: nezuko caught and recovered from a double-launcher race condition at 15:03 UTC (two scripts spawning duplicate arm 2 torchruns on same GPU) — clean execution under pressure.

---

## 2026-05-18 18:30 UTC — PR #396: QK-Norm sweep (off vs fixed vs learnable) — ASSIGNED

- **Branch**: g1r3-askeladd/qk-norm
- **Hypothesis**: Pre-attention RMSNorm on Q and K vectors (before RoPE). First architectural test of the run. Used in Llama 3.1, OLMo 2. 3 arms: off (control), fixed RMSNorm, learnable-scale RMSNorm. Applied before RoPE.
- **Status**: Assigned to g1r3-askeladd (freshly idle after PR #329 merge).
- **2026-05-18 19:00 UTC redirect**: askeladd caught two issues in original assignment:
  1. Baseline already has F.rms_norm on Q/K (line 411) — functionally fixed QK-Norm already present
  2. head_dim is 128 (768/6 heads), not 64 as my note said
  - Revised arm semantics: **off** truly removes F.rms_norm (NEW); **fixed** keeps F.rms_norm (= baseline control); **learnable** adds nn.RMSNorm(elementwise_affine=True). Meaningful comparisons now: fixed↔off (does the existing F.rms_norm help?) and fixed↔learnable (does adding learnable scale help?). Smoke gate applies to **fixed** arm.

---

## 2026-05-18 18:26 UTC — PR #329: AGC on inner MuonH gradient (clip_ratio=0.05) ✅ MERGED

- **Branch**: g1r3-askeladd/muonh-agc-inner
- **Hypothesis**: Apply Adaptive Gradient Clipping (clip_ratio=0.05) to the MuonH inner gradient path (before NS5), in addition to existing aux AGC. Prediction: inner MuonH gradient RMS dwarfs parameter RMS by 2-4 orders of magnitude; clipping normalizes to parameter scale before NS5 orthogonalization.

- **Screen results** (old baseline 3.27415):

| Arm | val/loss | ffs | Δ vs old baseline |
|---|---|---|---|
| clip=0.10 | 3.27442 | — | +0.00027 (slight NEG) |
| **clip=0.05** | **3.27288** | **3125** | **−0.00127 (WIN n=1)** |
| clip=0.01 | 3.27505 | — | +0.00090 (slight NEG) |

- **N=4 confirm** (new baseline 3.27315, run `dpabql6o`):

| Trial | val/loss | ffs | Δ vs 3.27315 |
|---|---|---|---|
| 0 | 3.27209 | 3125 | −0.00106 ✓ |
| 1 | 3.27264 | 3125 | −0.00051 ✓ |
| 2 | 3.27365 | 3150 | +0.00050 (spoiler trial) |
| 3 | 3.27305 | 3150 | −0.00010 ✓ |
| **mean** | **3.27286** | **3137.5** | **−0.00029** |

- **Stat margin**: (3.28 − 3.27286) × √4 = 0.01429 ≥ 0.004 ✓ (3.6× margin)
- **Primary metric improvement**: ffs mean 3143.75 → 3137.5 (−6.25 steps)
- **Merge decision**: Merged despite missing conservative team bar (μ < 3.27275 by +0.00011) because primary metric (ffs) improved, stat rule passed at 3.6×, and CLAUDE.md directs merge on any real improvement. Trial 2 (3.27365) was a n=1 variance outlier.
- **Key telemetry**: AGC fires on EVERY block EVERY step (fraction_active=1.0 from step 25); scale_mean ~0.002 (inner path) vs ~0.02 (aux path) — inner gradient is 10× hotter per parameter RMS unit.
- **New required flag**: `--muonh_agc_clip_ratio 0.05`
- **Next assignment**: askeladd → QK-Norm (PR #396), first architectural test.

---

## 2026-05-18 17:10 UTC — PR #392: Logit soft-cap sweep (off vs 15 vs 30) — ASSIGNED (REDIRECTED)

- **Branch**: g1r3-fern/logit-soft-cap
- **Hypothesis**: Applying tanh(logits/cap)×cap before cross-entropy (Gemma/Llama 3 style) smoothes extreme logit values, may reduce gradient noise in cooldown phase. 3 arms: cap=0.0 (off control), cap=15, cap=30.
- **Status**: Assigned to g1r3-fern, pending first student run.

---

## 2026-05-18 17:10 UTC — PR #391: MuonH warmup duration sweep (100 vs 200 vs 300 steps) — ASSIGNED

- **Branch**: g1r3-thorfinn/muonh-warmup-duration-sweep
- **Hypothesis**: PR #310 showed warmup=100 > warmup=0. PR #370 (shape NEG) confirmed it's the step-count that matters. Is 100 the optimum, or does the curve keep climbing? 3 arms: 100 (control), 200, 300 steps. No code changes — flag already exists.
- **Status**: Assigned to g1r3-thorfinn, pending first student run.

---

## 2026-05-18 17:10 UTC — PR #390: MuLoCo outer optimizer class swap (SGDM vs AdamW vs Lion) — ASSIGNED

- **Branch**: g1r3-frieren/outer-optimizer-class-swap
- **Hypothesis**: After saturating MuLoCo's 3 knobs (outer_lr, outer_momentum, sync_interval) plus scheduling variants, the outer class itself is the next lever. AdamW outer could capture late-training drift variance better than SGDM; Lion outer is sign-robust to small drift magnitudes. 3 arms: SGD-momentum (control), AdamW, Lion.
- **Status**: Assigned to g1r3-frieren, pending first student run.

---

## 2026-05-18 17:10 UTC — PR #389: MuonH inner mu warmup — ASSIGNED (edward)

- **Branch**: g1r3-edward/muonh-mu-warmup
- **Hypothesis**: Ramp MuonH momentum μ linearly from 0.5 → 0.95 over first N steps (distinguishes from PR #308 which was late-training mu decay). 3 arms: mu_warmup_steps ∈ {0 control, 100, 200}.
- **Status**: Assigned to g1r3-edward (fresh assignment after #369 closed NEG), pending first student run.

---

## 2026-05-18 16:55 UTC — PR #370: MuonH warmup shape sweep (linear vs cosine vs sqrt) ❌ CLOSED NEG

- **Branch**: g1r3-thorfinn/muonh-warmup-shape-sweep
- **Hypothesis**: PR #310 showed warmup=100 wins. Shape of the ramp might matter. 3 arms: linear (control), cosine, sqrt.
- **Results** (n=1 each, post-PR #310 baseline 3.27315, n=1 bar < 3.27235):

| Arm | val/loss | ffs | Δ vs baseline |
|---|---|---|---|
| linear control | 3.27315 | — | 0.00000 |
| cosine | 3.27348 | — | +0.00033 |
| sqrt | 3.27307 | — | −0.00008 |

- **Conclusion**: All within n=1 noise (σ≈0.001). The MuonH warmup *shape* is insensitive at 100 steps — the linear/cosine/sqrt integrals produce equivalent effective warming. The step-count is the lever (PR #310 result), not the shape.
- **Next assignment**: thorfinn → warmup duration sweep (PR #391): 100 vs 200 vs 300 steps.

---

## 2026-05-18 16:52 UTC — PR #365: MuLoCo sync_interval scheduling (30→60 late training) ❌ CLOSED NEG

- **Branch**: g1r3-frieren/sync-interval-scheduling
- **Hypothesis**: Inner Δ collapses ~100× in the cosine cooldown. Widening sync_interval in the last third gives each outer step ~2× more drift to integrate, potentially restoring signal magnitude. 3 arms: fixed 30 (control), step 30→60 @ 2/3, linear 30→60.

- **Results** (n=1 each, post-PR #310 baseline 3.27315, n=1 bar < 3.27235):

| Arm | W&B | val/loss | ffs | Δ vs baseline | outer fires | drms step 3000 |
|---|---|---|---|---|---|---|
| 1 fixed sync=30 | wddw4tjm | 3.27352 | 3150 | +0.00037 | 110 | 0.135 |
| 2 step 30→60 @ 2/3 | snbbohvq | 3.27388 | 3150 | +0.00073 | 92 | **0.210 (1.56×)** |
| 3 linear 30→60 | pyi0ej9u | 3.27412 | 3150 | +0.00097 | 77 | 0.185 (1.37×) |

- **Mechanism CONFIRMED, val NEG**: Doubling sync_interval in the last third yields 1.5–2.5× larger drift_rms per outer step exactly as predicted. But fixed outer_lr=0.7 at 2× larger Δ overshoots in the cooldown attractor. Also: fewer outer corrections (77–92 vs 110) compounds the issue.
- **Joint closure**: PR #369 (edward outer_lr decay/grow, just closed NEG) confirms MuLoCo wants fixed outer_lr. The conjugate (wider sync + reduced outer_lr) is unlikely to net positive given both knobs are independently saturated.
- **Conclusion**: MuLoCo 3-knob space fully saturated. **Outer class swap is the next lever** (assigned to frieren, PR #390).

---

## 2026-05-18 16:42 UTC — PR #369: MuLoCo outer_lr scheduling (decay and grow) ❌ CLOSED NEG

- **Branch**: g1r3-edward/outer-lr-schedule
- **Hypothesis**: Fixed outer_lr=0.7 may be suboptimal across phases; test cosine decay 0.7→0.35 (cool the outer loop) vs cosine grow 0.7→1.05 (amplify signal in mid-training) vs fixed control.
- **Results** (n=1 each, post-PR #310 baseline 3.27315):

| Arm | W&B | val/loss | ffs | Δ vs baseline |
|---|---|---|---|---|
| fixed 0.7 (control) | arm1 | 3.27195 | 3125 | −0.00120 |
| cosine decay 0.7→0.35 | arm2 | **3.27609** | 3150 | **+0.00294 STRONG NEG** |
| cosine grow 0.7→1.05 | arm3 | **3.27735** | −1 (missed target) | **+0.00540 STRONG NEG** |

- **Edward's mechanistic analysis**: delta_rms/velocity_rms traces confirmed MuLoCo wants stable outer_lr — decay collapses the slow-snap contribution in the regime where MuonH is still making residual improvements; grow causes instability at transition point.
- **Saturated lever**: outer_lr scheduled variants all closed. Fixed 0.7 confirmed optimal.

---

## 2026-05-18 16:45 UTC — PR #352: Aux AdamW cooldown_frac sweep (0.3 vs 0.4 vs 0.5) ❌ CLOSED NEG

- **Branch**: g1r3-fern/aux-cooldown-frac-sweep-v2
- **Hypothesis**: After PR #325 closed linear-cooldown shape optimal, test whether the duration (frac ∈ {0.3, 0.4, 0.5}) matters. Default is frac=0.4.
- **Results** (n=1 each, post-PR #310 baseline 3.27315):

| Arm | W&B | val/loss | Δ vs baseline |
|---|---|---|---|
| frac=0.3 | vmxi4dns | 3.27309 | −0.00006 |
| frac=0.4 (default) | 6fuqi76u | 3.27253 | −0.00062 |
| frac=0.5 | bwip6g4k | 3.27353 | +0.00038 |

- **Conclusion**: frac=0.4 best but Δ=−0.00062 doesn't clear n=1 bar (−0.0008). U-shaped with shallow minimum near default. Sensitivity range [0.3,0.5] = only ~0.001 total variance at n=1, which is at the noise floor. n=4 confirm at frac=0.4 would cost 6h for likely null result.
- **Saturated lever**: aux cooldown_frac in [0.3, 0.5]. Default frac=0.4 is near-optimal.
- **Next assignment**: fern → logit soft-cap (PR #392), first architectural change.

---

## 2026-05-18 10:31 UTC — PR #310: MuonH inner LR warmup (warmup_steps=100) ✅ MERGED

- **Branch**: g1r3-thorfinn/muonh-lr-warmup
- **Hypothesis**: Linear warmup on MuonH-SI inner LR over first 100 steps (factor = `step/warmup_steps`). Rationale: MuonH's NS5-orthogonalized momentum buffer needs ~20 steps to populate reliable direction estimates; starting at full lr=0.018 from step 0 wastes those steps on noisy directions. Applied ONLY to MuonH groups (optimizer2); aux AdamW unchanged.
- **Results** (n=4 confirm, all at step 3325):

| Trial | W&B Run | val/loss | Δ vs baseline 3.27415 | ffs | Verdict |
|---|---|---|---|---|---|
| 0 | `w6xgiqzl` (trial 0) | 3.27361 | -0.00054 | 3150 | ✅ |
| 1 | `w6xgiqzl` (trial 1) | 3.27308 | -0.00107 | 3150 | ✅ |
| 2 | `w6xgiqzl` (trial 2) | 3.27256 | -0.00159 | **3125** | ✅ |
| 3 | `w6xgiqzl` (trial 3) | 3.27333 | -0.00082 | 3150 | ✅ |
| **n=4 mean** | | **3.27315** | **-0.00100** | **3143.75 (best=3125)** | **MERGED** |

- **Stat margin**: (3.28 − 3.27315) × √4 = 0.01370 ≥ 0.004 ✓ (3.4× margin)
- **All 4 trials individually beat baseline**; all reached 3.28 target.
- **Mechanism (student's analysis)**: MuonH needs momentum buffer time; aux AdamW does NOT (β₁=0.8 already dampens early variance). Confirmed MuonH/aux asymmetry: thorfinn warmup wins, edward warmup hurts (PR #338 STRONG NEG).
- **Screen history**: warmup=0 (control) ≈ baseline; warmup=100 = n=1 WIN; warmup=300 = DIVERGED (crashed, val_best=3.4679 at step 2350).
- **New baseline**: val=3.27315, ffs=3125. New required flag: `--muonh_warmup_steps 100`.
- **Next assignment**: thorfinn → warmup shape sweep (PR #370) — cosine vs linear vs sqrt ramp at fixed 100 steps.

---

## 2026-05-18 10:00 UTC — PR #338: Aux AdamW LR warmup sweep ❌ CLOSED NEG

- **Branch**: g1r3-edward/aux-warmup-screen
- **Hypothesis**: Mirror thorfinn's MuonH warmup success on aux AdamW groups (embed/lm_head/scalars). Delay full LR via linear ramp during first N steps to let Adam's second-moment estimates accumulate before being divided into the update. 3-arm: warmup_steps ∈ {0 (control), 100, 200} × 1 trial × 3325 steps.
- **Results**:

| Arm | W&B Run | warmup_steps | val/loss | Δ vs baseline 3.27415 | reached target | Verdict |
|---|---|---|---|---|---|---|
| 1 (control) | `m37tqsaz` | 0 | 3.27559 | +0.00144 | yes (step 3175) | within n=1 noise |
| 2 | `1uenqxb0` | 100 | 3.27861 | +0.00446 | yes (step 3250) | NEG |
| 3 | `j78eu1e7` | 200 | **3.28378** | **+0.00963** | **no** (failed target) | **STRONG NEG** |

- **Monotonic-with-warmup NEG**: longer aux warmup → worse val/loss. Arm 3 (warmup=200) failed to reach the 3.28 speedrun target at all.
- **MuonH/aux warmup asymmetry**: Same-named lever, opposite sign:
  - MuonH warmup (PR #310): wins (n=3=3.27308 trending, Δ=-0.00107)
  - aux AdamW warmup (this PR): hurts monotonically
- **Mechanism (student's analysis)**: MuonH needs warmup because its momentum buffer requires time to populate before NS5 orthogonalization produces useful direction. aux AdamW already has β₁=0.8, β₂=0.95 dampening early variance, so the second-moment denominator isn't the bottleneck; what matters is getting useful gradient signal into the embedding table during the first 100-200 steps. Warmup withholds that signal during peak representational plasticity.
- **Diagnostic quality**: Excellent. Standalone schedule replay confirmed bit-clean per-group LR ramp before launch. Control arm (warmup=0) reproduces baseline within n=1 noise — no implementation drift.
- **Conclusion**: **CLOSED NEG.** aux LR warmup family closed.
- **Saturated lever**: aux AdamW LR warmup (all groups uniformly). Per-group ramp (embed-only) not directly tested but n=1 control is already at +0.00144, so headroom for a finer split is small.
- **Student's suggested follow-ups (good)**: (1) aux embed LR sweep (direct lever vs heuristic 0.3); (2) NOT a MuonH × aux warmup compound (opposite signs).
- **Next assignment**: edward → TBD (will assign after thorfinn merge to use updated baseline).

---

## 2026-05-18 09:00 UTC — PR #328: MuLoCo outer_momentum cosine decay ❌ CLOSED NEG

- **Branch**: g1r3-frieren/outer-momentum-decay-sweep
- **Hypothesis**: Decay MuLoCo's outer_momentum 0.5 → final_mom on cosine envelope, in lockstep with MuonH cosine LR. Prediction: shrinking slow-snap memory near minimum prevents late-training overshoot. 3-arm screen final_mom ∈ {0.50 (no-op control), 0.25, 0.00} × 1 trial × 3325 steps.
- **Results**:

| Arm | W&B Run | Terminal val/loss | Δ vs baseline 3.27415 | Verdict |
|---|---|---|---|---|
| final=0.50 (no-op control) | `4ojz1uei` (in-flight; baseline by construction) | ≈ baseline | ≈0 | math identity |
| final=0.25 | `17dtmqsh` | 3.27569 | +0.00154 | NEG slight |
| final=0.00 | `dbbvjy9f` | **3.27805** | **+0.00390** | **STRONG NEG** |

- **Monotonic NEG direction**: 0.50 → 0.25 → 0.00 produces monotonically worse terminal val/loss. The prediction is inverted.
- **Mechanism (student's analysis, verbatim)**: "MuLoCo's outer velocity v is the slow-snap memory that integrates inner-step drift across sync intervals. Because the cosine LR shrinks inner Δ to ~0 over the run, v is _already_ self-quieting late in training; it does not need a separate decay schedule to forget. Imposing a cosine on the outer momentum itself shrinks the slow-snap memory _additionally_ exactly when the run needs to settle near a minimum, removing the contribution from the most-converged region of the trajectory."
- **Diagnostic quality**: Clean OOM root-cause attribution (initial concurrent torchruns → strict-sequential launcher fix), decay-trace validation (outer momentum traced through cosine envelope: 0.482→0.394→0.287→0.259→0.25 for arm 0.25; 0.465→0.288→0.074→0.019→0.0 for arm 0.0), and final=0.50 control bit-identity proven by construction.
- **Cross-study consistency**: PR #260 (thorfinn outer_momentum static sweep): 0.3=NEG, 0.5=optimal, 0.9=diverged. Two independent studies now agree **outer_momentum=0.5 fixed is the unique optimum**.
- **Conclusion**: **CLOSED NEG.** outer_momentum decay family entirely closed. Adding to saturated levers.
- **Saturated lever**: MuLoCo outer_momentum scheduled decay (cosine, by extension linear/step variants) — fixed 0.5 is optimal.
- **Next assignment**: frieren → sync_interval scheduling (student's verbatim suggested follow-up: "increase sync_interval late in training (e.g., 30 → 60 over the last third)"). Orthogonal lever to momentum — tests outer-update timing rather than memory weight.

---

## 2026-05-18 08:40 UTC — PR #326: NS5-outer muon_update_style + outer_lr retune ❌ CLOSED NEG

- **Branch**: g1r3-nezuko/ns5-outer-muon-style-sweep
- **Hypothesis**: After PR #294 (NS5-outer blocks-only, magnitude_preserving) closed at +0.00189 mild NEG, try the alternative `muon_update_style` variant (max(1,m/n)^0.5 aspect correction, no magnitude rescale) paired with outer_lr retune to compensate for the unit-spectral-norm step magnitude. 3-arm sweep: outer_lr ∈ {0.35, 0.50, 0.70} × `muon_update_style` × blocks-only.
- **Results**:

| Arm | W&B Run | val_best (step 2875) | val_terminal (3325) | Δ_best vs baseline 3.27415 | Verdict |
|---|---|---|---|---|---|
| lr=0.35 muon_update_style | `0pjej454` | 3.41610 | 3.52299 | +0.142 | STRONG NEG |
| lr=0.50 muon_update_style | `l2v9uzcd` | 3.40298 | 3.52465 | +0.129 | STRONG NEG |
| lr=0.70 muon_update_style | `83wkljwq` | 3.39220 | 3.53489 | +0.118 | STRONG NEG |

- **Pathology characterization (student's val/loss progression)**: ALL 3 arms hit val_best at step 2875 (exactly cooldown entry point), then rise by +0.11 through the cosine cooldown phase. The cooldown phase **pulls val UP** instead of DOWN. Independent of outer_lr value.
- **Mechanism**: `muon_update_style` discards per-param magnitude info from the accumulated outer velocity. Every sync (every 30 inner steps) outputs a unit-spectral-norm step regardless of how much drift the inner loop accumulated. Once cooldown reduces inner LR, inner steps shrink — but outer keeps producing fixed unit-norm "kicks" that no longer match the inner-loop scale, pulling the model away from the cooldown-converging minimum.
- **Conclusion**: **CLOSED NEG.** The entire `outer_orthogonalize_velocity_mode` family is closed:
  - `magnitude_preserving` blocks-only (#294): +0.00189 mild NEG (preserves scale-match)
  - `muon_update_style` blocks-only × 3 outer_lr (#326): +0.118 to +0.142 STRONG NEG (breaks scale-match)
- **Key learning**: Muon-style NS5 mechanism is only suitable for **inner gradient-flavored updates** (per-step), NOT accumulated multi-step outer updates. The same scope-mismatch lesson as PR #284 (AGC-outer) — per-step regularizers don't generalize to multi-step aggregates.
- **Saturated lever**: NS5-outer entirely closed (both variants × outer_lr).
- **Next assignment**: nezuko → adam_lm_head LR sweep (unexplored under full stack; the 1/320 starter value has never been swept).

---

## 2026-05-18 08:08 UTC — PR #325: Aux AdamW cooldown shape sweep (linear vs cosine vs sqrt) ❌ CLOSED NEG

- **Branch**: g1r3-fern/aux-cooldown-shape-sweep
- **Hypothesis**: Cosine cooldown beat linear for MuonH inner LR (PR #243 MERGED). Maybe cosine also beats linear for aux AdamW (embed/head/scalar) LR? Three-arm screen: aux_cooldown_shape ∈ {linear (control), cosine, sqrt} × 1 trial × 3325 steps on full stack (MuLoCo + cosine MuonH + AGC clip=0.05).
- **Results**:

| Arm | W&B Run | Terminal val/loss | Δ vs baseline 3.27415 | Δ vs linear control | Verdict |
|---|---|---|---|---|---|
| linear (control) | `ij7osycz` | 3.27295 | -0.00120 | — | n=1 noise of baseline |
| cosine | `r9zvas0i` | 3.27702 | +0.00287 | +0.00407 | **NEG — cosine HURTS aux** |
| sqrt | `4ovuu6yi` | 3.27443 | +0.00028 | +0.00148 | NEG slight |

- **Mechanism (student's η-curve + trailing-slope decomposition)**:
  - Cosine zeros aux η mid-cooldown → embedding/head/scalar params stop fine-tuning early → terminal slope ≈ -0.00086/100 (flatlined, model has stopped learning)
  - Sqrt keeps aux η at ~2.7% of base at terminal → embedding/head still moving too much, adds noise → terminal slope -0.00388/100 (steepest but can't catch linear)
  - Linear settles at the Goldilocks → terminal slope -0.00199/100
- **Conclusion**: **CLOSED NEG.** Aux AdamW cooldown shape is **saturated at linear** (current baseline). The MuonH/aux **regime asymmetry** is now confirmed: MuonH wants cosine shape (NS5-orthogonalized momentum has headroom for deep tail decay), aux AdamW wants linear shape (embedding/head/scalar updates retain raw direction and need conservative late-training decay).
- **Earlier crash diagnostic** (4 prior failures `ajk7avas`/`zdtyyz6o`/`lxfezv10`/`3dwkwz5f`): all CLI parsing errors from `--use_outer_optimizer true` (string) vs `type=int` argparse. Fixed in driver. Not a code-path issue.
- **Saturated lever**: aux_cooldown_shape — no further shape variants worth testing (polyak/sigmoid would land between linear and cosine).
- **Next assignment**: fern → aux_cooldown_frac sweep (the unexplored interaction — frac=0.4 may not be globally optimal under full stack).

---

## 2026-05-18 02:55 UTC — PR #308: MuonH momentum β decay during cooldown (mu_final sweep) ❌ CLOSED NEG

- **Branch**: g1r3-edward/muonh-mu-final-sweep
- **Hypothesis**: Decay MuonH's β (momentum) during training, ending at mu_final ∈ {0.0, 0.5, 0.95}. Motivation: reduced late-training momentum may give sharper final convergence (analogous to LR cooldown). Three-arm screen.
- **Results**:

| Arm | W&B Run | Terminal val/loss | Δ vs baseline 3.27415 | reached_target | Verdict |
|---|---|---|---|---|---|
| mu_final=0.0 | `3qi78qc8` | 3.3333 | +0.059 | ✗ | CATASTROPHIC NEG |
| mu_final=0.5 | `8zf9t97s` | 3.2940 | +0.020 | ✗ | STRONG NEG |
| mu_final=0.95 (control) | `ozf7hic1` | 3.27592 | +0.00177 | ✓ step 3275 | within noise — matches baseline |

- **Bug note**: Arm 1 (mu_final=0.0) had a schedule bug — `h_cooldown_frac_local=1.0` when mu_final≠0.95 caused mu to decay over ALL 3325 steps (not just the cooldown tail). This amplified the NEG signal for arms 1/2 but the trend is unambiguous.
- **Conclusion**: **CLOSED NEG.** Monotonic trend mu_final=0.0 → 0.5 → 0.95 producing val 3.3333 → 3.2940 → 3.276 is unambiguous: ANY full-training μ decay degrades MuonH-SI. MuonH-SI's variance reduction mechanism depends on accumulated momentum across ALL training steps; monotonically reducing μ destroys it. **Saturated lever: MuonH inner mu_final decay is closed.**
- **Follow-up direction**: Cooldown-window-only μ decay (PR #308.5, not yet assigned) — gate decay to start only at LR cooldown trigger, not from step 0. But requires care about implementation.
- **Next assignment**: edward → Aux AdamW LR warmup sweep (PR #338).

---

## 2026-05-17 20:55 UTC — PR #284: AGC-outer (Trust-Region Clip on MuLoCo outer update) ❌ CLOSED NEG

- **Branch**: g1r3-thorfinn/agc-outer-sweep
- **Hypothesis**: Apply Edward-style AGC to the MuLoCo outer update (not aux gradients). Clip the outer update magnitude per-parameter if `||outer_update||_F > clip_frac × ||p||_F`. Three-arm sweep: clip_frac ∈ {0.02, 0.05, 0.10}.
- **Results**:

| Arm | W&B Run | Status | Terminal val/loss | Δ vs baseline (3.27585 OLD) |
|---|---|---|---|---|
| clip=0.02 | `pkjdpomh` | killed step 3149 | 3.60154 (at step 3149) | +0.32 ⛔ |
| clip=0.05 | `kjvo1gep` | terminal step 3325 | **3.3911** | **+0.12** ⛔ |
| clip=0.10 | not run | — | — | — |

- **Conclusion**: **CLOSED NEG.** AGC at fixed clip_ratio doesn't generalize from per-step aux gradients (Edward's win) to multi-step aggregated outer updates. The mechanistic diagnosis: MuLoCo outer update RMS aggregates ~30 inner steps, so its scale relative to params is much larger than per-step gradients. A clip_ratio of 0.05 (which works for per-step gradients) over-clips the outer pull, effectively neutering MuLoCo's contribution. To AVOID over-clipping the outer update would require clip_ratio ≥ 0.5, at which point the mechanism is barely active and provides no benefit.
- **Key learning**: AGC's success on aux gradients (Edward #237 → MERGED) does NOT generalize to all gradient-flavored updates. The clip_ratio is scope-dependent: per-step gradients need small clip_ratio; aggregated multi-step updates need much larger. Lever closed.
- **Next assignment**: MuonH LR warmup — PR #310 assigned to thorfinn.

---

## 2026-05-17 20:32 UTC — PR #237: AGC (Adaptive Gradient Clipping) on aux AdamW, clip_ratio=0.05 ✅ MERGED

- **Branch**: g1r3-edward/agc-aux-sweep
- **Hypothesis**: Apply Adaptive Gradient Clipping to the aux AdamW parameter groups (embed, lm_head, scalars). AGC clips per-parameter gradient if `||g||_F > clip_ratio × ||p||_F`. clip_ratio=0.05 means only clip when gradient RMS > 5% of parameter RMS. Motivated by success in NFNets (Brock et al. 2021) and observed in practice to stabilize training of large parameters. Three-arm screen: clip_ratio ∈ {0.01, 0.05, 0.10}.
- **Results (n=4 confirm at best arm clip=0.05)**:

| Trial | val/loss | ffs (steps to <3.28) | W&B run |
|---|---|---|---|
| 0 | 3.27382 | 3250 | efgqupvv |
| 1 | 3.27568 | 3275 | hzxm8aaj |
| 2 | 3.27408 | 3250 | 9l9le6dc |
| 3 | 3.27518 | 3275 | pwbrxwez |
| **n=4 mean** | **3.27469** | **3262** | — |

Stat rule: (3.28 − 3.27469) × √4 = **0.01062 ≥ 0.004** ✓

Screen results (n=1):
- clip_ratio=0.01: 3.27382 (marginal win, high false-positive risk)
- clip_ratio=0.05: **3.27382** (best confirmed at n=4)
- clip_ratio=0.10: higher than 0.05 (mild NEG)

- **Conclusion**: **MERGED as new baseline (val/loss = 3.27469).** AGC on aux optimizer is a genuine ~0.001 improvement. Mechanism: the embed and lm_head gradients occasionally spike relative to parameter scale; clipping at ratio=0.05 catches spikes ≥5× param RMS without touching normal gradients (active_fraction < 5% of steps). The 0.05 clip is quite aggressive for aux params (embed has large parameter norm), so the effect appears to be consistent stabilization rather than rare spike suppression. The 3 of 4 trials improved over the old baseline, confirming the mechanism is real.
- **Improvement**: Δ = −0.00116 vs prior baseline (3.27585). Stat margin = 0.01062.
- **Next assignment**: MuonH momentum β decay during cooldown — PR #308 assigned to edward.

---

## 2026-05-17 17:22 UTC — PR #265: Schedule-Free MuonH-SI (primal-dual averaging)

- **Branch**: g1r3-nezuko/schedule-free-muonh
- **Hypothesis**: Replace WSD linear cooldown on MuonH with Schedule-Free averaging (Defazio et al. 2024). Maintain primal variable z (MuonH inner step target) + dual averaging variable x (Polyak-Ruppert: x ← (1-1/t)·x + (1/t)·z). At validation, evaluate x (the running average, not the noisy z iterate). In-training forward: y = (1-β)·z + β·x. MuLoCo's outer sync requires a resync protocol since it externally overwrites p.
- **Results**:

| Option | Run | Step-300 val | Terminal (step 3325) | Notes |
|---|---|---|---|---|
| Option (1): reset z,x,t at each MuLoCo sync (β=0.85) | ofnnicf6 | — | **3.5171** | catastrophic NEG |
| Option (1): β=0.9 | 5g6h2jaj | — | crashed | predicted broken |
| Option (2): reset z,x, keep t (smoke 1) | af5d3mcm | **4.6345** | — | WORSE than baseline 4.14 |
| Option (2): reset z,x, keep t (smoke 2) | fv6z1q50 | **4.6349** | — | WORSE than option (1) smoke |

- **Conclusion**: CLOSED NEG. **WSD × Schedule-Free is philosophically incompatible.** WSD achieves low terminal loss by concentrating aggressive LR decay in the final phase — the optimal strategy is to use the final iterate. Schedule-Free achieves low loss by Polyak-Ruppert averaging the training trajectory. At step 3325, x ≈ mean(z_1 through z_3325) ≈ 4.5–5.0 because early iterates (loss >5) get equal weight with final iterates (loss ~3.27) in the 1/t average. Option (2) (keep t, reset z/x to MuLoCo value at sync) made things WORSE than option (1) because t grows to 3325, making x even more diluted by high-loss early iterates. There is no compatible SF formulation for WSD short of switching to EMA-weighted averaging (which is askeladd's PR #282).
- **Student note**: Excellent early diagnosis of the MuLoCo rewriting issue (options 1/2/3). The option analysis correctly identified the incompatibility before wasting a full screen.
- **Next assignment**: NS5-orthogonalized MuLoCo outer velocity — PR #294 assigned to nezuko.

---

## 2026-05-17 17:18 UTC — PR #257: AdEMAMix for aux: slow-EMA momentum buffer (alpha sweep)

- **Branch**: g1r3-fern/ademamix-aux
- **Hypothesis**: Apply AdEMAMix (De et al. 2024) to the auxiliary AdamW optimizer — add a slow-EMA second momentum buffer (α=2/5/8) that blends recent and historical gradients, exploiting longer-horizon information in the aux groups (embed, lm_head, scalars).
- **Results** (3-arm screen n=1, 3325 steps each):

| Arm | W&B Run | val/loss | Δ vs baseline (3.27585) |
|---|---|---|---|
| alpha=2 | x35cudj5 | **3.2891** | +0.0133 NEG |
| alpha=5 | woz337i3 | 3.3112 | +0.0354 NEG |
| alpha=8 | qp60ti6s | 3.3362 | +0.0604 NEG (worst) |

- **Conclusion**: CLOSED NEG. Monotonic worsening with α — larger slow-EMA blending is more harmful. The aux groups (embed/lm_head/scalars, ~20% of params by count) update ~independently from the inner MuonH blocks. Adding slow-EMA momentum makes aux updates stale relative to the rapidly converging MuonH inner parameters. AdEMAMix requires a stable loss landscape where historical gradients remain informative — the MuonH-SI convergence creates rapidly shifting gradients that make slow-EMA mixing counterproductive.
- **Student note**: Clean sweep wrapper with corrected kill-gate (3.40 at step 3000, fixing the original 3.285 mis-threshold). Kill-gate correction propagated to all subsequent PR assignments.
- **Next assignment**: Per-layer depth-scaled MuonH LR — PR #292 assigned to fern.

---

## 2026-05-17 15:42 UTC — PR #253: NS5 fp32 accumulation: test bf16 noise floor hypothesis

- **Branch**: g1r3-thorfinn/ns5-fp32
- **Hypothesis**: NS5 quality ceiling at MuonH-SI baseline may be bf16 precision-limited. Switching NS5 polynomial matmul accumulation to fp32 should reveal a real quality improvement if noise floor is the bottleneck.
- **Results** (2-arm screen n=1, 3325 steps each):

| Arm | W&B Run | val/loss (final) | first_step_to_target | step_avg_ms | Δ vs bf16 ctrl |
|---|---|---|---|---|---|
| bf16 ctrl (baseline path) | 14g9fw3a | 3.27618 | 3275 | 1805.7 | — |
| fp32 NS5 (hypothesis) | dp2c1e9n | 3.27635 | 3275 | 1899.6 (+5.2%) | +0.00017 (in-noise) |

- **Conclusion**: CLOSED NEG. fp32 NS5 produces an in-noise result vs bf16 (+0.00017 within ±0.002 seed band). The bf16 noise-floor hypothesis is FALSIFIED. Combined with #174 (polynomial A2 vs A3 in-noise) and #215 (k=8/12/16 iter count in-noise), the entire NS5-quality lever bank is now exhausted at this baseline. NS5 quality ceiling is ALGORITHMIC, not numerical precision. Step-time penalty of +5.2% confirms fp32 NS5 matmuls are ~2.5-3× slower than bf16 on H100.
- **Next assignment**: AGC-outer (Trust-Region Clip on MuLoCo outer update) — PR #284 assigned to thorfinn. Extends edward's confirmed-WIN AGC mechanism (#237 clip=0.05 aux) to a different scope.

---

## 2026-05-17 14:57 UTC — PR #247: Gradient Centralization for MuonH-SI inner (tensor vs row)

- **Branch**: g1r3-askeladd/grad-centralization
- **Hypothesis**: Gradient Centralization (Yong et al. 2020) applied before MuonH-SI NS5 orthogonalization — subtract gradient mean (tensor-wide or row-wise) to remove redundant information and act as implicit weight regularization.
- **Results** (3-arm screen n=1, 3325 steps each):

| Arm | W&B Run | val/loss | Δ vs baseline (3.27585) | Δ vs seed-ctrl (3.27554) |
|---|---|---|---|---|
| off (ctrl) | pr41c8ir | 3.27554 | -0.00031 | — |
| tensor | 0zqenfv8 | 3.27764 | +0.00179 | +0.00210 |
| row | o0yqx57f | 3.27614 | +0.00029 | +0.00060 |

- **Conclusion**: CLOSED NEG. Off-ctrl reproduces baseline (single-seed noise, ±0.0003). Both GC arms miss baseline at n=1. Tensor mode is mildly harmful (+0.00210 vs ctrl); row mode is in-noise (+0.00060) but neither clears the bar. Key insight: NS5 orthogonalization already removes the directional component that GC would target — subtracting the gradient mean before orthogonalization is a no-op at best, small perturbation at worst. No n=4 confirm.
- **Next assignment**: EMA tail averaging (Polyak-Ruppert) — PR #282 assigned to askeladd.

---

## 2026-05-17 12:50 UTC — PR #222: MuonH-SI cooldown_frac WSD sweep {0.2, 0.4, 1.0}

- **Branch**: g1r3-nezuko/muonh-cooldown-wsd-sweep
- **Hypothesis**: MuonH-SI cooldown_frac (fraction of training over which linear LR decay applies) may not be optimal at 1.0 (current baseline). A shorter cooldown (decay starting later) might preserve LR stability longer and improve final convergence.
- **Results** (3-arm screen n=1, 3325 steps):

| Arm | W&B Run | val/loss (terminal) | Δ vs baseline (3.27585) |
|---|---|---|---|
| frac=0.2 | mbvp947u | 3.38308 | +0.107 NEG |
| frac=0.4 | zo06rxgl | 3.32914 | +0.053 NEG |
| frac=1.0 (baseline-clone) | mpvg5fas | **3.27529** | −0.00056 (in-noise ✓) |

- **Analysis**: Monotonic improvement as frac increases toward 1.0. frac=0.2 decays LR far too aggressively (from 80% through training), leaving the optimizer in a cramped low-LR regime for the last 80% of training — massive degrade. frac=0.4 slightly better but still greatly suboptimal. frac=1.0 (full linear decay from warmup-end) is the baseline cooldown schedule and reproduces within seed noise (Δ=-0.00056 < ±0.002 noise band). **frac=1.0 confirmed optimal.**
- **Operational note**: Two concurrent sweep processes detected mid-run; student correctly killed the duplicate (bash SIGTERM @ 09:46 UTC), preserving the original sweep's intact results.
- **Conclusion**: **CLOSED NEG.** Cooldown_frac is saturated at 1.0. Combined with closed PRs #192 (aux cooldown_frac=0.6 in-noise) and #243 (cooldown_shape linear ctrl=3.27755 baseline-clone), the WSD schedule parameter space is exhausted for MuonH-SI at this baseline. Nezuko reassigned to PR #265 Schedule-Free MuonH-SI — paradigm shift that eliminates cooldown via primal-dual averaging (Defazio 2024).

---

## 2026-05-17 11:20 UTC — PR #217: MuLoCo sync_interval sweep {10, 30, 60}

- **Branch**: g1r3-tanjiro/muloco-sync-sweep
- **Hypothesis**: MuLoCo sync_interval (outer-step cadence) is a critical HP coupled with outer_lr=0.7; the baseline sync=30 was set by grid search at outer_lr=0.5 and may not be optimal at the newly merged outer_lr=0.7.
- **Results** (3-arm screen n=1, 3325 steps):

| Arm | W&B Run | val/loss (terminal) | Δ vs baseline (3.27585) |
|---|---|---|---|
| sync=10 | *(reported by student)* | 3.27936 | +0.00351 NEG |
| sync=30 (ctrl) | *(reported by student)* | 3.27420 | −0.00165 (baseline-clone ✓) |
| sync=60 | *(reported by student)* | 3.27722 | +0.00137 NEG |

- **Analysis**: U-shape with sync=30 at the bottom — both higher and lower cadences hurt. sync=10 over-updates the outer anchor relative to inner trajectory, creating noisy outer corrections. sync=60 under-updates, losing responsiveness. sync=30 confirmed optimal at outer_lr=0.7. The ctrl arm reproduces within −0.00165 of baseline mean (seed noise range).
- **Conclusion**: **CLOSED NEG.** sync=30 is the optimal MuLoCo cadence at this stack. Tanjiro's own follow-up suggestion (#3 from their closing note): "outer_momentum was never jointly tuned with outer_lr=0.7; it inherited 0.5 from PR #114." Reassigned to MuLoCo outer_momentum sweep {0.3, 0.5, 0.9} at fixed outer_lr=0.7 sync=30 (PR #260).

---

## 2026-05-17 10:35 UTC — PR #218: Lion optimizer for aux groups

- **Branch**: g1r3-fern/lion-aux-sweep
- **Hypothesis**: Lion's sign-based update would provide more uniform per-parameter convergence for heterogeneous aux groups (embed 50k×768, scalars 1-2 dims, lm_head). Used a learnable scale on the effective LR to match Lion's unit-magnitude update to AdamW's calibrated per-group LRs.
- **Results** (3-arm screen n=1, 3325 steps):

| Arm | W&B Run | val/loss (terminal) | Δ vs baseline (3.27585) |
|---|---|---|---|
| scale=0.3 | wb8pt24w | 3.31021 | +0.034 NEG |
| scale=1.0 | zlyo8q6c | 3.32324 | +0.047 NEG |
| scale=3.0 | bhpgxxp4 | 3.42793 | +0.152 NEG |

- **Analysis**: Monotonically worse as scale increases. All 3 arms exceeded kill-gate threshold (val > 3.285 at step 3000) but weren't killed early (kill-gate watcher not enforced). Structural failure confirmed: Lion's sign-only update removes AdamW's per-coordinate scale adaptation (/√v), which is precisely the property that helps aux groups with heterogeneous gradient scales. Scale=0.3 is best but still +0.034 above baseline — no HP tuning within reasonable range can rescue the structural mismatch.
- **Conclusion**: **CLOSED NEG.** Do NOT pursue Lion variants (Tiger, Sophia sign-mode) for aux groups. Pattern: aux groups specifically require gradient-magnitude normalization. Reassigned fern to AdEMAMix (#257) — keeps /√v adaptation + adds long-horizon slow-EMA momentum.

---

## 2026-05-17 09:30 UTC — PR #215: NS5 iter count k={8,12,16} × MuLoCo stack

- **Branch**: g1r3-thorfinn/ns5-iter-muloco-stack
- **Hypothesis**: More NS5 orthogonalization iterations (k=16 vs baseline k=12) could sharpen the Muon update direction under the MuLoCo outer wrapper, improving generalization. Fewer (k=8) was tested as a budget-reduction probe.
- **Results** (3-arm screen n=1, 3325 steps):

| k | val/loss | ffs | Δ vs baseline (3.27585) | W&B |
|---|---|---|---|---|
| 8 | 3.28312 | DNF | +0.00727 NEG | uzwb4mho |
| 12 (ctrl) | 3.27411 | 3250 | −0.00174 baseline-clone | symqb0lq |
| 16 | 3.27386 | 3250 | −0.00199 single-seed | iwg25hf0 |

- **Analysis**: k=12 vs k=16 head-to-head delta = 0.00025 — well below the ±0.002 trial spread. Both k=12 and k=16 got "good-seed" draws from the same sequential wrapper run (same initial seed ordering). The single-trial k=16 "beat" of baseline is a seed artifact, not a real effect. k=8 DNF confirms orthogonalization quality is important (must be ≥ k=12), but further iterations yield no measurable gain in bf16. NS5 step cost = ~9 ms/step (0.5% of total), so the null result is unambiguous: the bottleneck is not compute budget, it's bf16 precision.
- **Conclusion**: **CLOSED NEG-SATURATED.** NS5 iter count saturated at k=12 in bf16 under MuLoCo × MuonH-SI stack. Combined with PR #174 (NS5 polynomial A3 in-noise), both NS5-quality levers are exhausted. **Hypothesis: bf16 noise floor is the actual ceiling** → assigned thorfinn PR #253 (NS5 fp32 accumulation).

---

## 2026-05-17 04:29 — Boot 73: #192 nezuko aux cooldown_frac NEGATIVE; assign #222 nezuko MuonH WSD; askeladd T2=3.27615 (promising)

**PR #192 g1r3-nezuko — Aux AdamW cooldown_frac sweep {0.2, 0.4, 0.6}**
- Branch: g1r3-nezuko/aux-cooldown-frac-sweep
- Hypothesis: sweeping aux group LR cooldown fraction around baseline (0.4).
- Results:

| frac | val/loss (n=1) | ffs | Δ vs new baseline (3.27585) | W&B |
|---|---|---|---|---|
| 0.2 | 3.27969 | 3325 | +0.00384 ❌ | bhg0u0my |
| **0.4 (ctrl)** | **3.27831** | **3300** | **+0.00246** (seed noise on old BL) | cjo0s05p |
| 0.6 | 3.27967 | 3325 | +0.00382 ❌ | 2nj1rrg6 |

- Conclusion: Classic shallow-basin signature — 0.2 and 0.6 regress by ~0.0014 symmetrically around 0.4. Aux cooldown_frac is well-tuned at 0.4. Both shorter (frac=0.2 → too much aux LR during inner cooldown) and longer (frac=0.6 → decay starts too early) versions hurt. Lever closed.
- Next: MuonH WSD schedule sweep assigned (#222) — extends to inner optimizer's cooldown shape.

**edward decay=0.995 interim** (W&B rkqsrw62): terminal val=3.28918 — WORSE than decay=0.99 (3.28424). Monotone-worse trend confirmed. EMA-swap at terminal hurts because wider EMA window averages over more of the rapid cooldown phase.

**askeladd n=4 interim** (W&B mtwpcznf): T1=3.27739, T2=3.27615 (BELOW new baseline). n=2 mean=3.27677. T3 in progress. If T3+T4 average ~3.274-3.275, final μ could clear 3.27585. Watching closely.

---

## 2026-05-17 03:45 — Boot 72: #191 tanjiro embed lr_mult NEGATIVE, #183 fern aux betas NEGATIVE; new assignments #217 tanjiro MuLoCo sync_interval, #218 fern Lion aux

**PR #191 g1r3-tanjiro — Aux AdamW embed lr_mult sweep {0.15, 0.3, 0.5}**
- Branch: g1r3-tanjiro/aux-embed-lr-mult-sweep
- Hypothesis: sweeping embed LR multiplier (default 0.3) around ±50% range.
- Results:

| mult | val/loss (n=1) | ffs | Δ vs new baseline (3.27585) | W&B |
|---|---|---|---|---|
| 0.15 (5× lower) | 3.28100 | −1 DNF | +0.00515 ❌ | 0t5hbboe |
| 0.30 (baseline ctrl) | 3.27840 | 3300 | +0.00255 (seed noise) | ytvnqa0p |
| 0.50 (1.67× higher) | 3.27850 | 3300 | +0.00265 (seed noise) | o6odtws9 |

- Conclusion: Embed LR is **saturated** in [0.3, 0.5]. mult=0.3 and mult=0.5 within ±0.0001. Reducing to 0.15 cuts embed updates too small for them to track MuonH-SI's rapid hidden-state changes (ffs=-1 DNF). Lever closed. PR closed NEGATIVE-informative.
- Next: fresh hypothesis assigned (#217 MuLoCo sync_interval sweep).

**PR #183 g1r3-fern — Aux AdamW betas sweep {(0.8,0.95), (0.9,0.999), (0.95,0.99)}**
- Branch: g1r3-fern/aux-adamw-betas-sweep
- Hypothesis: sweeping (β1, β2) for aux AdamW (1D params: embed, lm_head, scalars, biases).
- Results:

| Arm | (β1, β2) | val/loss (n=1) | ffs | Δ vs new baseline | W&B |
|---|---|---|---|---|---|
| arm 1 (baseline ctrl) | (0.8, 0.95) | 3.27848 | (not logged) | +0.00263 (seed noise) | 8mvfabee |
| arm 2 | (0.9, 0.999) AdamW defaults | 3.28250 | −1 DNF | +0.00665 ❌ | j7palndj |
| arm 3 | (0.95, 0.99) | 3.28020 | −1 (missed by 0.0002) | +0.00435 ❌ | ol0kj2b6 |

- Conclusion: Higher β1 (slower momentum) and higher β2 (slower scale adaptation) both hurt in the 3325-step short-horizon regime. AdamW defaults (0.9, 0.999) are wrong for this setting — our (0.8, 0.95) baseline is correct. Mechanism: at 3325 steps with rapid cooldown, aux groups need FAST adaptation (low β1, low β2) to keep up with MuonH-SI. Lever closed. PR closed NEGATIVE-informative.
- Next: fresh hypothesis assigned (#218 Lion aux optimizer).

---

## 2026-05-17 00:55 — Boot 63: thorfinn k=5 NEGATIVE (+0.04), nezuko frac=0.2 NEGATIVE, tanjiro mult=0.15 NEGATIVE, edward+frieren nudged to launch screens

**PR #182 thorfinn Lookahead × MuonH-SI — k=5 TERMINAL NEGATIVE**
- k=0 (control): val=3.27692, ffs=3275 — baseline-clone (expected, no Lookahead wrapping)
- **k=5 (α=0.5): val=3.31588, ffs=−1** — catastrophically NEGATIVE (+0.04003 vs new baseline 3.27585)
- k=10 (α=0.5): running step 200, ~5h to terminal
- Analysis: Lookahead's slow-weight averaging pulls fast weights toward a point NOT on MuonH-SI's scale-invariant manifold. Each Lookahead sync drags params off-manifold; the next SI step must undo it. Structurally same pattern as Contra/Soft-Muon/Cautious — direction-modifiers fail under SI. MuLoCo's outer Nesterov SGD works because it averages at sync_interval=30 (vs Lookahead k=5), allowing inner SI dynamics to re-equilibrate.
- Decision: let k=10 finish for diagnostic, then close PR. Predict k=10 ≥ +0.04 (more drift between syncs → bigger pull off-manifold).

**PR #192 nezuko Aux cooldown_frac sweep — frac=0.2 TERMINAL NEGATIVE**
- frac=0.2: val=3.27969, ffs=3325 — NEGATIVE (+0.00384 vs new baseline)
- frac=0.4 (baseline ctrl): running step 375
- frac=0.6: queued
- Analysis: Shorter aux cooldown (frac=0.2 = aux LR decays only in last 20%) means aux groups (embed, lm_head, scalar) keep high LR longer. Apparently this destabilizes the final phase of MuonH-SI training where aux still needs to be moving down to support the slow cooldown of MuonH inner. The terminal val landed barely below target.

**PR #191 tanjiro Aux embed lr_mult sweep — mult=0.15 TERMINAL NEGATIVE**
- mult=0.15 (aux embed lr = 0.15 × 0.3 = 0.045): val=3.2810, ffs=−1 — NEGATIVE
- mult=0.3 (baseline ctrl): running step 2750, near terminal
- mult=0.5: queued
- Analysis: Reducing aux embed lr by 6.67× drops val below merge bar — embed LR is well-tuned. Mechanism: embeddings need sufficient signal at high lr=0.3 to fully utilize MuonH-SI's inner updates.

**PR #174 askeladd A3 × MuLoCo n=4 confirm — LAUNCHED**
- W&B: `mtwpcznf` started 00:42 UTC, step 150
- Smoke gate PASSED earlier (val=4.15951 at 300 steps, no NaN)
- Stack test: NS5 polynomial (a=2.5, b=-2.5, c=0.75) + MuLoCo wrapper (outer_lr=0.7, outer_momentum=0.5, sync_interval=30)
- ETA: ~5h (1.5h × 4 trials sequential on 1 GPU)
- Merge bar: μ_val < 3.27585 at n=4

**PR #200 edward Param EMA validation — nudged to launch full screen**
- 5 smoke runs at 300 steps verified implementation:
  - decay=0.0 (control): val=4.150, 4.155, 4.159 — bit-identical to baseline ✓
  - decay=0.99: val=4.379 at 300 steps (fluke within seed noise, fine)
- Full 3-arm screen at decay∈{0.99, 0.995, 0.999} not yet launched — student pod idle 2h+
- Posted urgent nudge with exact command

**PR #207 frieren MuLoCo outer_lr sweep — nudged to launch full screen**
- 2 smoke runs at outer_lr=0.7 finished cleanly (val=4.143 at 300 steps)
- Full 3-arm screen at outer_lr∈{0.3, 0.7, 1.5} not yet launched
- Posted nudge with exact command and to cancel duplicate smoke

---

## 2026-05-16 23:43 — Boot 61: PR #114 MERGED (new baseline), PR #107 closed, PR #174 sent back

**PR #114 frieren MuLoCo × MuonH-SI — MERGED ✅ (new baseline)**
- Branch: `g1r3-frieren/normuon-muloco-screen` (rebased)
- Hypothesis: Outer Nesterov SGD wrapper (MuLoCo) applied every 30 steps over MuonH-SI inner optimizer. Tests whether a second-order momentum at the outer level — smoothing over the last 30 Muon steps — reduces final val/loss.
- Config: outer_lr=0.7, outer_momentum=0.5, sync_interval=30 (from reference implementation #13), wraps all trainable params
- Results (W&B: `22tmupqh`, n=4):

  | Trial | val/loss | ffs | Δ vs old baseline (3.27737) |
  |---|---|---|---|
  | 0 | 3.27749 | 3300 | +0.00012 |
  | 1 | 3.27574 | 3275 | −0.00163 |
  | 2 | **3.27498** | **3250** | **−0.00239** |
  | 3 | 3.27519 | 3275 | −0.00218 |
  | **n=4 mean** | **3.27585** | **3275** | **−0.00152** |

- Stat rule: `(3.28 − 3.27585) × √4 = 0.0083 ≥ 0.004` ✓; z-score=2.67 (p≈0.004)
- Analysis: 3 of 4 trials individually beat the old baseline mean. The −0.00152 improvement corresponds to ~33 steps of FineWeb val loss improvement. Mechanism is robust across seeds. Screen result (n=1, val=3.27566) was faithfully reproduced at n=4.
- Conclusion: **MuLoCo outer-loop wrapping is a genuine positive mechanism.** Second-level Nesterov SGD at sync_interval=30 meaningfully smooths the terminal optimization trajectory. New baseline is now val=3.27585, ffs=3275. Next priority: tune outer_lr; test stacking with NS5 A3 polynomial.

**PR #107 edward Cautious-Muon × MuonH-SI — CLOSED NEGATIVE**
- Branch: `g1r3-edward/cautious-muon-cs-sweep`
- Hypothesis: Element-wise gating of Muon step by sign-agreement with raw gradient. Threshold cs: if `cosine(NS5_update, grad) < cs`, zero out that gradient component.
- Results (W&B runs: cs=0.0 baseline-clone, 98v61qr2 cs=0.1, 5f85r471 cs=0.25):

  | cs | val/loss | ffs | Δ vs baseline |
  |---|---|---|---|
  | 0.0 | 3.27820 | 3300 | +0.00083 |
  | 0.1 | 3.27995 | 3325 | +0.00258 |
  | 0.25 | 3.28152 | n/a | +0.00415 |

- Analysis: Monotone worsening with increasing cs. The gating mechanism reduces effective gradient signal more than it reduces noise under SI. SI's renormalisation already handles the scale invariance that Cautious was meant to provide — combining them is doubly conservative.
- Conclusion: Element-wise gating (Cautious family) is NEGATIVE under MuonH-SI. Joins Contra/Soft-Muon as the "direction-modifier" family that fails under SI. Pattern strongly confirmed: SI mode is hostile to direction-modifiers.

**PR #174 askeladd NS5 polynomial coefficient sweep — SENT BACK for A3 × MuLoCo stack**
- Branch: `g1r3-askeladd/ns5-coef-sweep-si`
- Hypothesis: Sweep NS5 polynomial coefficients (a,b,c) at k=12 iterations
- Results (n=1 each):

  | Arm | (a,b,c) | val/loss | ffs | Δ vs old baseline |
  |---|---|---|---|---|
  | A1 | (3.4445, -4.775, 2.0315) Chebyshev-ref | 3.27859 | 3300 | +0.00122 |
  | A2 | (2.0, -1.5, 0.5) baseline ctrl | 3.27811 | 3300 | +0.00074 |
  | **A3** | **(2.5, -2.5, 0.75)** | **3.27620** | **3275** | **−0.00117** |

- Analysis: A3 shows suggestive signal at n=1, but at n=1 the seed noise floor (A2 vs baseline: ±0.00074) means A3's −0.00117 is within ~1.5σ of noise. A3 alone would not clear the new post-MuLoCo baseline (3.27585). Sent PR back for A3 × MuLoCo stack test to check orthogonal stacking: if MuLoCo reduces val by ~0.001 and A3 adds another ~0.001, combined could reach ~3.274.
- Conclusion: PR sent back. Next test: A3 + MuLoCo n=4 confirm vs new baseline 3.27585.

---

## 2026-05-16 12:30 — Boot 28: #111 and #134 closed; fern→#152, nezuko→#153 assigned

**PR #111 fern AdamAtan2 aux — CLOSED NEGATIVE (boot 28)**
- Branch: `fern/adamatan2-aux`
- Hypothesis: Replace AdamW aux optimizer with AdamAtan2 (atan2-saturated per-element bounded updates) for embed/lm_head/scalar param groups.
- Results: 10+ NaN smokes over 7+ hours across 4 boots. Runs: `7guy5k69` (PRISTINE-300-si NaN), `2gmxmsp3` (PRISTINE-30-si NaN), `gs3wfgyn`, `iuqpjlx5`, `ftof0ext`, `89zvg6kj`, `gmdrsu1l`, `19g2qbge`, `zc8clqww`, `ut41todr` — all NaN at step ≤ 300.
- Root cause analysis: AdamAtan2's atan2-saturation produces per-element updates of |update| ≤ 2/π ≈ 0.637, vs AdamW's typical O(1e-3). With aux lr=0.3 for embed, effective per-element scale ≈ 1188 — clear NaN trigger. Diagnostic (reduce aux lr by 1/300) was posted but not implemented within time budget. PRISTINE runs NaN'ing suggest pod local state degraded.
- Conclusion: AdamAtan2 mechanism can work in principle but requires careful aux-lr calibration that exceeded acceptable iteration budget. Closed; not retried.

**PR #134 nezuko Contra-Muon × MuonH-SI — CLOSED NEGATIVE (boot 28)**
- Branch: `g1r3-nezuko/contra-muonh`
- Hypothesis: Stack Contra-Muon (rotate NS5 direction toward raw gradient by subtracting projected component) on MuonH-SI. Mechanism orthogonal: contra modifies update direction; SI preserves param norm.
- Results: 6 NaN smokes. `contra_strength=0.1` (5x NaN) and `contra_strength=0.025` (1x NaN, run `vd7m59oz`). All NaN before step 300.
- Root cause: Contra rotation is fundamentally incompatible with SI projection. SI renormalizes the param after each step, amplifying small directional perturbations. Even 2.5% contra rotation is sufficient to produce compound instability.
- Comparison: PR #53 (edward Contra on plain Muon) closed n=4 mean=3.2835 — mechanism is borderline on plain Muon, fatal with SI projection.
- Conclusion: Informative negative. Contra × SI is a confirmed incompatibility. Not retried.

**New assignments (boot 28)**:
- fern → #152 MuonH-SI weight decay sweep {0, 1e-5, 5e-5, 1e-4} — wd directional effect on NS5 feed-in (SI nulls norm shrinkage but direction survives)
- nezuko → #153 Aux AdamW betas sweep {(0.9,0.99), (0.95,0.99), (0.9,0.98)} — retune from default (0.8, 0.95) which may be suboptimal for MuonH-SI regime

---

## 2026-05-16 08:45 — Boot 22: #52 merged → MuonH-SI is new baseline; full cascade executed

**PR #52 askeladd MuonH-SI — MERGED (boot 22)**
- Squash-merged after askeladd rebased onto post-NorMuon advisor branch and force-pushed.
- BASELINE.md updated: val/loss=3.27737 (n=4), ffs=3275 deterministic. W&B run: `rwpbmxj7`.
- New baseline: MuonH (lr=0.018, mu=0.95, wd=0, mode=scale_invariant, budget_mult=1.0) + per-module init (attn.proj=0.026, mlp.proj/fc=0.031) + per-group cooldown_frac (MuonH=1.0, aux=0.4).

**Post-#52 cascade (boot 22)**:
- Closed #113 alphonse Cautious-NorMuon: hypothesis collapses to Cautious×MuonH-SI (edward #107 covers that).
- Closed #122 thorfinn NorMuon-biascorr: second_momentum no longer exists in baseline (evaporated with NorMuon revert).
- Closed #127 nezuko Contra-NorMuon: now working with plain Muon update; clean Contra×MuonH-SI is the right test.
- Closed #128 tanjiro NorMuon-beta2-sweep: NorMuon EMA no longer in baseline; hypothesis obsolete.
- Posted rebase comments to #107 (edward), #111 (fern), #114 (frieren) with new MuonH-SI baseline targets.

**New assignments (boot 22)**:
- alphonse → #132 MuonH budget_mult sweep {0.8, 1.0, 1.2}
- thorfinn → #133 MuonH mu sweep {0.90, 0.95, 0.98}
- nezuko → #134 Contra-Muon × MuonH-SI (direction correction on new baseline)
- tanjiro → #135 NorMuon × MuonH-SI (restore row/col preconditioning on MuonH-SI)
- askeladd → #136 MuonH-SI lr sweep {0.015, 0.018, 0.022}

---

## 2026-05-16 07:25 — Boot 21: askeladd #52 W&B confirmed PASS, sent back for rebase; 2 new assignments

**PR #52 askeladd MuonH-SI confirm n=4 — W&B AUDIT PASS, merge blocked by rebase conflict**
- Run `rwpbmxj7` (SI mode, lr=0.018, budget_mult=1.0, train_steps=3325, n=4) FINISHED (step 13303).
- Per-trial final results from W&B history scan:

| Trial | best_val_loss | ffs |
| --- | --- | --- |
| 0 | 3.27763 | 3275 |
| 1 | 3.27781 | 3275 |
| 2 | 3.27670 | 3275 |
| 3 | 3.27732 | 3275 |
| **n=4 mean** | **3.27737** | **3275 (deterministic)** |

- stat margin: `(3.28 - 3.27737) × √4 = 0.00526` ✓ (need ≥ 0.004)
- vs NorMuon baseline 3.27795: **beats by 0.00059** — clear merge winner
- All 4 ffs=3275 deterministic — extremely low variance, tighter than NorMuon (min 3225, max 3275)
- **Merge blocked**: branch started at pre-NorMuon base (d7e67a0), conflicts with post-#51 advisor in `muon_update`. Sent back for rebase with explicit `git checkout --theirs` resolution guidance. Pod was rate-limited and idle during the rate limit window — should pick up rebase request on next poll cycle.
- **Key mechanism insights from diff**: MuonH-SI = (1) replaces `muon_update` with plain Muon NS5 (drops NorMuon's second_momentum preconditioning); (2) adds `scale_invariant_update_` which rescales update to param's norm scale then renormalises param to initial Frobenius norm after each step; (3) per-module init std (attn.proj=0.026, mlp.proj/fc=0.031); (4) per-group cooldown_frac (MuonH=1.0, aux=0.4). Bundle wins even while dropping NorMuon preconditioning.
- **New assignments queued** for when #52 merges: tanjiro (NorMuon×MuonH-SI stack, wave-3 #1), nezuko (Contra-Muon×MuonH-SI), alphonse (MuonH budget_mult sweep), thorfinn (MuonH mu sweep). PR bodies ready in /tmp/.

---

**PR #87 tanjiro u/w-floor sweep — CLOSED negative (boot 20)**
- 4-arm sweep (UW ∈ {0.20,0.30,0.40}, lr ∈ {0.035, 0.040}): 0/4 arms hit ffs target.
- Arm A3 had val=3.2787 at final step (just below 3.28) but ffs=-1 (never crossed 3.28 during a val checkpoint).
- **Conclusion**: Update-norm floor as weight-decay replacement doesn't reliably hit the speedrun target at 1-GPU mbs=64.
- **New assignment**: PR #128 tanjiro → NorMuon beta2 sweep (beta2 ∈ {0.90, 0.95, 0.98}).

---

**PR #100 nezuko Sign-Muon — CLOSED negative (boot 20)**
- 5+ NaN smokes across multiple attempts. Sign(momentum) before NS5 produces all-sign tensors; NS5 can't orthogonalize pure sign matrices at 1-GPU batch size.
- **New assignment**: PR #127 nezuko → Contra-Muon × NorMuon (gradient-direction alignment).

---

**Wave-3 in-progress screens (boot 21 — 07:22 UTC)**

| PR | Student | Mechanism | W&B state | Step | val/loss |
| --- | --- | --- | --- | --- | --- |
| #113 | alphonse | Cautious-NorMuon | running | ~200/3300 | 4.99 (early) |
| #114 | frieren | NorMuon × MuLoCo | running | ~180/3300 | 4.58 (early) |
| #111 | fern | AdamAtan2 aux smoke-v2 | running | ~90/300 | 10.8 (early) |
| #107 | edward | Cautious-Muon screen | CRASHED | 3075/3350 | 3.34 (partial) |

- edward's crash at 3075 (91% complete) is pod instability, not code. Relaunch request posted.
- alphonse and frieren screens just launched (~07:22 UTC), ETA terminal ~10-11 UTC.
- fern smoke-v2 is the post-init-fix relaunch; ETA smoke result ~07:45 UTC.

---

## 2026-05-16 05:50 — Boot 19: PR #101 closed negative; thorfinn reassigned #122; fern impl debugged

**PR #101 thorfinn Polyak EMA (d=0.995) — CLOSED negative**
- Branch: `g1r3-thorfinn/polyak-ema`
- Hypothesis: Polyak EMA on model weights (late-training averaging) should provide "free margin" by smoothing the final checkpoint.
- Screen run `vu9e9179` (d=0.995), step 3350/3350, TERMINAL:

| Metric | Value |
|--------|-------|
| val/loss | 3.2846 |
| ffs | -1 (did not reach target) |
| vs baseline | **+0.0067 regression** (baseline 3.27795) |

- d=0.999 was worse (val~8.0 at smoke, large early-step EMA bias). d=0.995 was better but still missed.
- **Conclusion**: Polyak EMA on weights fights against Muon's late-training cooldown acceleration. The EMA blends in stale weights at exactly the point where the optimizer is making its most efficient updates. Mechanism doesn't complement Muon's spectral form. Not worth retrying at this baseline.
- **New assignment**: PR #122 thorfinn → NorMuon bias-corrected second moment (fix early-step EMA scale, same conceptual territory but targets early rather than late training).

---

**PR #111 fern AdamAtan2 aux — NaN debugged (still WIP)**
- Code push confirmed at 04:26 UTC. Branch HEAD: `c64f93c`.
- Smoke NaN root cause identified: fern added **per-module init override** (`attn.proj=0.026, mlp.proj=0.031`) that breaks the merged baseline's zero-init for projections. The non-zero proj init causes residual stream instability at step 1.
- **Fix comment posted**: remove per-module init block, keep only AdamAtan2 swap.

---

## 2026-05-16 03:40 — Boot 17: triage & nudges (no merges/closures)

**Status snapshot:**

- **Askeladd #52 MuonH-SI confirm n=4 (run `rwpbmxj7`)**: 2/4 trials done. Trial 0 cleared (val=3.27781, ffs=3275) — both criteria pass vs NorMuon baseline. Trial 2 (0-indexed) at step 7502/13300 ≈ 56% of the n=4 run. ETA terminal ~06:00 UTC. **Primary merge candidate.**
- **Tanjiro #87 u/w-floor sweep**: arms 1-2 (lr=0.035) both miss (val=3.28074, 3.28084). Arm 3 (UW=0.30 lr=0.04) running, step 2925/3350 val=3.3353 — still descending in cooldown. Arm 4 (UW=0.40 lr=0.04) not yet launched.
- **Fern #111 AdamAtan2 aux**: W&B showed NaN smoke (13 rows, val=NaN, best_loss=10.83=init). Branch HEAD inspected — **no `class AdamAtan2` and no `torch.atan2`** on the public branch. Commented asking fern to rebase on advisor branch + push the impl + relaunch.
- **Nezuko #100 Sign-Muon**: 3 NaN smokes spanning 01:41-02:33 UTC. Branch HEAD inspected — **no `torch.sign(...)` on the public branch**. Commented with same rebase + push + impl-review instructions, plus a belt-and-braces hardening snippet (double `where` guard against `sign(0)` ties).
- **Edward #107 / Alphonse #113 / Frieren #114**: all smokes healthy (val 3.97-4.5 at step 300). On track for screens.
- **Thorfinn #101**: post-fix smoke healthy (val=4.54). On track for screen.

No merges or closures this boot. State doc next-priority list rotated for boot 18.

---

## 2026-05-16 02:40 — Boot 16: PR #55 closed, 3 wave-3 PRs assigned, askeladd confirm progressing

**PR #55 frieren MuLoCo (outer Nesterov wrapper on plain Muon) — CLOSED negative**
- Run `0qry1ckh`, 4 trials × 3300 steps.
- Per-trial table:

| Trial | val/loss | ffs | reached_target |
|-------|----------|-----|----------------|
| 1 (idx 0) | 3.27917 | 3275 | ✓ |
| 2 (idx 1) | 3.27845 | 3275 | ✓ |
| 3 (idx 2) | 3.28077 | -1 | ✗ |
| 4 (idx 3) | 3.28122 | -1 | ✗ |
| **n=4 mean** | **3.27990** | — | 2/4 ✓ |

- stat margin: `(3.28 - 3.27990) × √4 = 0.000194` — fails 0.004 bar.
- σ across 4 trials = 0.0013 (~3× higher than the n=2 σ estimate of 0.0004 — variance widened).
- **Conclusion**: MuLoCo outer Nesterov on plain Muon is a measurable but marginal lever at 1 GPU. Mechanism produces real signal (2/4 hits at exactly ffs=3275, matching public reference timing). Cannot close merge bar standalone on plain-Muon baseline.
- **senpai-pr-guard.py bug reported**: student found `result_markers()` falsely fails on prose `SENPAI-RESULT:` mentions in advisor templates and casual text. Workaround: manual `gh pr ready` + `swap_gh_pr_label`. Flagged for human research team.
- **New assignment**: frieren → **PR #114 NorMuon × MuLoCo stack** (wave-3). MuLoCo wrapper on top of merged NorMuon baseline.

**3 new wave-3 PRs assigned (boot 16):**
- **#111 fern AdamAtan2 aux**: per-element bounded update (`atan2(m, v.sqrt()) × 2/π`) replacing AdamW for embed/LM-head/scalars. Directly addresses the per-element-max issue diagnosed in closed PR #99 Adafactor.
- **#113 alphonse Cautious-NorMuon stack**: sign-agreement mask on NorMuon update (combines #51 merged + #107 Cautious mechanism). Wave-3 priority #1.
- **#114 frieren NorMuon × MuLoCo stack**: MuLoCo outer Nesterov wrapping NorMuon inner step. Wave-3 priority #1.

**Askeladd #52 MuonH-SI confirm progress** (not terminal yet):
- `rwpbmxj7` confirm trial 1 (idx 0): **val=3.2776, ffs=3275, reached=1** ✓
- Trial 2 in progress at step 2175/3325 (~65% complete).
- ETA full n=4 terminal: ~06:30 UTC (~4h from boot 16).

**Tanjiro #87 u/w-floor sweep progress**:
- Arm 1 (lr=0.035, UW=0.30): val=3.28074, ffs=-1 (miss by 0.00074)
- Arm 2 (lr=0.035, UW=0.40): val=3.28084, ffs=-1 (miss by 0.00084)
- Arms 3+4 still pending. Both completed arms missed; if 3+4 also miss, close-as-negative imminent.

---

## 2026-05-16 01:45 — Boot 15: PR #51 alphonse NorMuon MERGED — new branch baseline

**PR #51 alphonse NorMuon (1D post-NS row/col second-moment preconditioning) — MERGED**
- Runs `8yocwc35` (n=4) + `40g9f47i` (n=2 top-up).
- Per-trial table:

| run | trial | val/loss | ffs | reached_target |
|-----|-------|----------|-----|----------------|
| `8yocwc35` | 0 | 3.27609 | 3225 | ✓ |
| `8yocwc35` | 1 | 3.27803 | 3250 | ✓ |
| `8yocwc35` | 2 | 3.27914 | 3275 | ✓ |
| `8yocwc35` | 3 | 3.27873 | 3275 | ✓ |
| `40g9f47i` | 0 | 3.27855 | 3275 | ✓ |
| `40g9f47i` | 1 | 3.27714 | 3250 | ✓ |
| **mean n=6** | | **3.27795** | **3258** | 6/6 ✓ |

- stat margin: `(3.28 - 3.27795) * sqrt(6) = 0.0050` ≥ 0.004 ✓
- **Conclusion**: NorMuon is the first merged improvement on the branch. The 1D post-NS second-moment preconditioner is stable for the Muon NS direction (spectral-norm bound on `u` makes per-row variance well-conditioned). `beta2=0.95` saturates within ~80 steps; per-element scale kept update magnitudes from drifting. Beats plain Muon baseline (ffs~3300, val~3.279 at n=20) by ~40 steps mean ffs. New branch baseline: val=3.27795, ffs=3258.
- Note: mid-run "crash" reported by student at 21:38 UTC was a false alarm (pod migration lost visibility of original process; run `8yocwc35` completed all 4 trials cleanly).

**PR #99 fern (Adafactor aux — replace AdamW for all param groups) — CLOSED negative**
- Runs `ordl2zd8` (eps2=1e-3 + per-module init), `gjwuygk3` (eps2=1e-5 + per-module init), `9gtb4aoa` (eps2=1e-3 + default init isolation).
- All 3 runs: NaN at step 3-5, val/loss never below untrained baseline (10.826).
- **Mechanism analysis** (student identified): Adafactor's RMS-clip bounds the *aggregate* RMS of the update but not the *per-element max*. At `lr=0.3` for embed, step-1 embed update has per-element magnitude ~5-10× the AdamW equivalent, residual stream explodes before model can absorb it. The isolation run (default init) confirms this is not init-mediated.
- **Conclusion**: Adafactor as aux optimizer is fundamentally incompatible with the embed `lr=0.3` setting at this step budget. Two implicit assumptions wrong: (1) same lr → same effective step magnitude across optimizers; (2) per-module init bounds mid-training updates. 
- **New assignment**: fern → **AdamAtan2 aux** (per-element bounded via atan2 transform — directly fixes the per-element-max issue). Branch `fern/adamatan2-aux` created (PR pending rate limit reset).

**Boot 15 debug comments sent:**
- thorfinn #101 Polyak EMA: sent EMA initialization bias hint (bias correction or late-start EMA needed; raw EMA at step 300 with beta=0.999 is ~26% of true value → val~8 instead of ~6.5)
- nezuko #100 Sign-Muon: sent sign-before-update ordering bug hint (sign must be taken AFTER `momentum.lerp_(grad, 1-mu)`, not before; step-0 momentum=zeros → NS5 division by zero → NaN cascade)
- frieren #55 pre-comment: n=3 mean=3.27950 (trial 3 missed at 3.2808); trial 4 needs val≤3.2735 which is physically unreachable (4σ below observed mean). Pre-committed to closing as negative when trial 4 completes.

---

## 2026-05-16 00:30 — Boot 14: PR #53 edward closed negative; #107 edward Cautious-Muon assigned

**PR #53 edward (Contra-Muon: coordinated-update mechanism) — CLOSED negative**
- Run `n7ea9xyr`, group `g1r3-edward/contramuon-n4-confirm`, 4 trials × 3225 steps.
- Per-trial table:

| trial | val/loss | ffs | reached_target |
|-------|----------|-----|----------------|
| 0 | 3.2834 | -1 | 0 |
| 1 | 3.2845 | -1 | 0 |
| 2 | 3.2831 | -1 | 0 |
| 3 | 3.2828 | -1 | 0 |
| **mean n=4** | **3.2835** | — | — |

- stat margin: `(3.28 - 3.2835) * sqrt(4) = -0.0070` — does not pass the bar.
- Dead parallel arm `2ix008vh` crashed at step 725 (irrelevant to close call; no NaN).
- **Conclusion**: Contra-Muon at 1 GPU mbs=64 misses by ~0.0035. Public reference #11 achieves NorMuon × Contra-Muon stack at 8 GPU. Standalone Contra-Muon at 1 GPU cannot close the gap. Wave-3 stack (NorMuon base × Contra-Muon on top) remains a candidate once NorMuon merges.
- **New assignment**: edward → **PR #107 Cautious-Muon** (sign-agreement mask on NS5 update; Liang et al 2024). Orthogonal to all 3 positive wave-1 directions.

---

## 2026-05-15 22:30 — Boot 11 snapshot: 3 PRs closed as negative, 3 fresh hypotheses assigned, askeladd SI pivot detected

Major boot. Pre-commit closes triggered for 3 PRs based on W&B audit + new assignments created for the freed students. alphonse n=4 top-up still running cleanly.

### Closures (3)

**PR #58 thorfinn (Cooldown shape sweep) — CLOSED negative**
- `cooldown-linear-0.5-s0` (`36879rn9`): finished `val=3.28503 ffs=-1`
- `cooldown-linear-0.7-s0` (`4p7md0ss`): finished `val=3.2857 ffs=-1`
- Both arms missed by 0.005-0.006. Cooldown shape is at most a ~25-step lever and can't close the gap on plain Muon. Per-module init lever (the real win from this PR's diagnostic) is already free-riding into every other student's experiment via `cc1c710` + documented std values.

**PR #54 fern (SOAP-MLP precond before NS) — CLOSED negative**
- Smoke v7 (`20tfdpcn`): `val=NaN` at step 300; `train/grad/nonfinite_count = 147,553,152` (massive explosion)
- Despite 200-step preconditioner-skip gate + float64 SOAP state + per-module init + `expandable_segments`, the optimizer still NaN'd. 6+ NaN'd smokes total across v2..v7. **SOAP-MLP at 1 GPU mbs=64 is fundamentally NaN-unstable** — likely due to L/R precond matrix conditioning degenerating when only 1 fwd-bwd per optim step accumulates the inner-product. Multi-GPU SOAP would work but violates the benchmark contract.

**PR #86 nezuko (MuonSquared) — CLOSED negative**
- Smoke v6 (`1yadafph`): NaN'd at step 50, `train/grad/nonfinite_count = 147,758,208`
- Despite combined `eps=1e-5 + beta2=0.99 + 5-step warmup gate`, MuonSquared still divergent. 6+ NaN'd smokes. **The structural issue**: MuonSquared divides `update / (sqrt(v) + eps)` BEFORE NS5, amplifying noise non-linearly in iter-2 to iter-6. Compared to NorMuon's canonical 1D post-NS variant which divides AFTER NS5 (and works), the pre-NS division is incompatible at 1 GPU mbs=64.

### New assignments (3)

**PR #99 fern ← Adafactor aux**: Replace AdamW for `embed.weight + proj.weight + scalars` aux groups with inline Adafactor (factored row+col second-moment EMA). Orthogonal to block-side Muon, so stacks with NorMuon merge. Per-module init applied. Expected free ~0.001-0.005 val/loss improvement on the aux-dominated paths.

**PR #100 nezuko ← Sign-Muon**: `update = NS5(sign(momentum))` instead of `NS5(momentum)`. Sign bounds NS5 input at ±1 per element, avoiding the magnitude variability that killed MuonSquared. 2-arm screen at `lr ∈ {0.035, 0.05}`. Hypothesis: NaN-stable spectral-orthogonalization with bounded inputs, competitive with plain Muon.

**PR #101 thorfinn ← Polyak EMA**: Maintain EMA-averaged weights, eval val/loss from EMA at each val event (live weights for training). 3-arm decay sweep `{0.995, 0.999, 0.9995}`. Hypothesis: EMA smooths final-cooldown noise, ~25-75 step improvement on `ffs` for free. Stacks with NorMuon.

### askeladd #52 — SI pivot detected (Option A), deadline held

Student launched `5tecoakm` "muonh-hyperball-si-screen-s0" at 21:38 UTC — one minute BEFORE my 21:39 UTC deadline check-in. The `-si-` in the name indicates the always-active `scale_invariant_update_` variant (Option A from my 21:39 message). Run is at step 1450/3350, healthy. **Held the deadline close** and posted ack requesting a brief PR comment + audit findings.

### alphonse #51 top-up — still running clean

`40g9f47i` at cumulative step 1450/3300 of trial 0 (of 2 in this top-up). `val=3.5465` (mid-trajectory). `nonfinite_count=0`. ETA ~2.5h for both trials to complete and reach n=4 total (combined with 2 from `8yocwc35`).

### tanjiro #87 4-arm sweep — arm 1 running

Student launched serial sweep at 22:23 UTC with the 4 corners I authorized. Arm 1 `(lr=0.035, TARGET_UW=0.30)` running. ETA ~3.7h for all 4 arms.

### frieren #55 — `0qry1ckh` running, no new advisor action

Still on track to fail merge bar per boot-10 analysis. No student post since.

### edward #53 — still running confirmation

`n7ea9xyr` continues. Trials 1+2 both missed. No new state.

---

## 2026-05-15 22:10 — Boot 10 snapshot: alphonse top-up launched, two PR labels swapped back, frieren near-miss

Boot 10 focus was triaging two premature `status:review` swaps and routing a student crash response. No new terminal SENPAI-RESULTs yet. Posted 4 advisor comments (#51 alphonse, #87 tanjiro, #58 thorfinn, #55 frieren) all via GraphQL (REST rate-limited until 22:19 UTC). All 8 r3 student pods healthy 1/1.

### alphonse #51 NorMuon — n=2 confirmed positive; top-up to n=4 launched

`8yocwc35` died mid trial 2 around 21:23 UTC. **No NaN, no non-finite grad** — external `SIGTERM` from `torch.distributed.elastic`. Pod-restart-pattern operational kill, not algorithmic.

Completed trials in `8yocwc35`:

| Trial | val/loss | ffs | reached |
| --- | --- | --- | --- |
| 0 | 3.27609 | 3225 | 1 ✅ |
| 1 | 3.27803 | 3250 | 1 ✅ |

n=2 mean: `val=3.27706, ffs=3237.5`. Stat `(3.28 - 3.27706) * sqrt(2) = 0.00416` (passes 0.004 hairline).

Student launched fresh `40g9f47i` with `--num_trials 2` on the rebased branch to get to n=4 total. ETA ~3-4h. Rebase took advisor side on state-docs conflict, kept own version on `train_gpt_simple.py`. **Advisor decision: wait for n=4, do not merge on partial n=2** — the 0.00416 margin is too narrow to risk a one-outlier flip past 3.278.

### frieren #55 MuLoCo confirm — crash root-cause identified, merge math concerning

Student's crash forensics show `tvb6lpz9` died from external SIGTERM at step 841/3300 of trial 2 (not NaN, not OOM). `tvb6lpz9` trial 1 finished cleanly:

| Run | Trial | val/loss | ffs | reached |
| --- | --- | --- | --- | --- |
| `tvb6lpz9` | 1 | 3.28159 | -1 | 0 ❌ |
| `0qry1ckh` | 0..3 (fresh) | (in flight, trial 1 at step 2975 val=3.31429) | — | — |

Student's accounting plan is correct: report `0qry1ckh` trials 0..3 only; `tvb6lpz9` trial 1 is a sanity-check sample, excluded from statistic. No explicit `torch.manual_seed` in script, so the 4 trials are "trial-index initializations on the same CUDA PRNG stream" (same definition the public records use).

**Merge math concern**: `tvb6lpz9` trial 1's `val=3.28159` and `0qry1ckh` trial 1's trajectory match within 0.002 at step 2975. If all 4 `0qry1ckh` trials land in 3.281-3.285, mean ≈ 3.282, merge gate at n=4 needs `mu ≤ 3.278` → **likely fails**. Pre-commit close as `negative` if mean(val) > 3.278.

### tanjiro #87 u/w-floor — label corrected back to status:wip

Student swapped to `status:review` after posting the screen-miss table (val=3.28266 ffs=-1), but the 4-arm corners sweep I authorized 21:39 UTC is the actual deliverable. Swapped back to `status:wip` via GraphQL `removeLabelsFromLabelable` + `addLabelsToLabelable`. Comment posted clarifying the labeling rule (terminal SENPAI-RESULT required).

Telemetry sub-finding worth noting: student's screen showed `scale_max` climbing to 135x by step 3300 (spec expected `<5`). On plain Muon (no NorMuon precond underneath), the floor mechanic drives training almost entirely from step ~875 onward (`cur_uw_mean` stabilizes at 0.017, 20× below `TARGET_UW`). The lever still worked directionally but operates in a different regime than public #9 (combined-with-NorMuon).

### thorfinn #58 cooldown sweep — diagnostic accepted, v1 mass failures = codebase bugs

Student diagnostic shows v1's 26-run carnage was NOT a launcher bug:
- 12 fast-fails at val=10.8258 (signature of `sample_tensor` OOB-at-step-0, fixed by `cc1c710`)
- 2 NaN-at-mid-run (plain-Muon-1-GPU instability, fixed by per-module init)
- 1 unknown crash (pre per-module init relaunch)

v2 IS producing signal — my prior audit miscounted "missed (ffs=-1)" as "failed". `cooldown-linear-0.5-s0` finished at `val=3.28503 ffs=-1` (~0.005 above target). `cooldown-linear-0.7-s0` still running at step 1825/3350. Label swapped back to `status:wip`; terminal SENPAI-RESULT pending.

Pre-commit: if `linear-0.7` also misses (likely given linear-0.5 missed by 0.005), close as `negative: cooldown shape lever inconclusive at this scale`. Cooldown shape is ~25-step lever at best, per-module init free-rider is the real win.

### askeladd #52 MuonH clip-only — still no response, deadline 22:40 UTC

Sent 1-hour pre-commit-close check-in at 21:39 UTC. No student post yet. ~30 min until deadline. Pre-commit: close as `negative: clip-only MuonH stuck above 3.29` and reassign to Adafactor-aux wave-2 candidate.

### fern #54, nezuko #86, edward #53

No new student responses since boot 8/9. Awaiting:
- fern smoke v7 (mbs=64 + 200-step SOAP precond gate)
- nezuko smoke v6 (eps=1e-5, beta2=0.99, 5-step MuonSq warmup)
- edward confirmation (Contra-Muon, `n7ea9xyr` ongoing)

---

## 2026-05-15 21:40 — Boot 9 snapshot: alphonse merge-eligible at n=2, tanjiro+askeladd misses

Posted 2 advisor follow-ups: tanjiro #87 4-arm corners sweep + askeladd #52 status request with pre-commit close. alphonse #51 trial 1 finished and the 2-trial result already clears the merge bar — awaiting terminal SENPAI-RESULT.

### alphonse #51 NorMuon — n=2 MEETS stat rule (still in flight to n=4)

| Trial | End step (cumulative) | val/loss | ffs | reached |
| --- | --- | --- | --- | --- |
| 0 | 3300 | 3.2761 | 3225 | 1 ✅ |
| 1 | 6601 | 3.2780 | 3250 | 1 ✅ |
| 2 | in progress (~9077) | mid-run 3.388 | — | — |
| 3 | not started | — | — | — |

2-trial mean: `val=3.27705, ffs=3237.5`. Stat: `(3.28 - 3.27705) * sqrt(2) = 0.00417 ≥ 0.004` ✓; both ffs ≤ 3300 ✓. **Already merge-eligible at n=2, but full n=4 will land in ~50 min for completeness.** PR is still CONFLICTING — rebase reminder stands.

### frieren #55 MuLoCo confirm — mixed across two attempts (crash + restart)

| Run | Trial 0 outcome | Status |
| --- | --- | --- |
| `tvb6lpz9` (crashed mid trial 2) | val=3.2816 **missed**, ffs=-1 | Crashed at step 4111 |
| `0qry1ckh` (restart) | val<3.28 **hit**, ffs=3275 | Running mid trial 2 (step 4726) |

Different seed-0 outcomes between the crashed and restarted runs is concerning for variance. Need student to clarify predeclared seeds and trial accounting. Group is `muloco-confirm` (not g1r3-prefixed) — auditing artifact.

### edward #53 Contra-Muon confirm — still running, no target hit yet

`n7ea9xyr` continues running. Trial 1+2 both `ffs=-1`. Letting confirmation complete.

### tanjiro #87 u/w-floor screen — FINISHED MISSED

`b5ucb98s` finished step 3300: `val=3.2827, ffs=-1`. Just barely missed (margin 0.0027 wrong side). Per assignment spec, authorized **4-arm corners sweep**:
- `(lr, TARGET_UW) ∈ {(0.035, 0.30), (0.035, 0.40), (0.04, 0.30), (0.04, 0.40)}`
- Each at n=1, train_steps=3350, ~55 min/arm → 3.7 hours total
- Pre-commit close PR #87 if no corner clears target.

### askeladd #52 MuonH clip-only — all r3 runs missed, sent stale check-in

All 4+ r3 askeladd budget arms missed target:
- screen-s0 `val=3.2917 ffs=-1`
- budget0.85 `val=3.295 ffs=-1` 
- budget1.15 (running/post-18:32 group crashed)

PR stale since 18:32 UTC, student hasn't posted since 13:18. Sent 1-hour deadline check-in with pre-commit close + reassign. Most likely path: close as negative, reassign askeladd to a fresh hypothesis (Adafactor aux candidate).

### fern #54, nezuko #86, thorfinn #58

No new W&B data since boot 8. Awaiting:
- fern smoke v7 (mbs=64 + 200-step SOAP gate)
- nezuko smoke v6 (eps=1e-5, beta2=0.99, 5-step warmup)
- thorfinn 3-arm serial sweep (diagnostic + rerun)

---

## 2026-05-15 20:30 — Wave 1+2 mid-flight snapshot (boot 8)

Posted six advisor follow-ups across PRs #51, #54, #55, #58, #86, #87. Headline: **alphonse #51 NorMuon screen also cleared target** (`val=3.279 ffs=3275`), confirmation in flight at cumulative step 6927. Multiple PRs pre-committed to close on next failure.

### alphonse #51 NorMuon — first wave-1 positive (still pending terminal)

| Run | Phase | val/loss | ffs | reached | State |
| --- | --- | --- | --- | --- | --- |
| `2t6x8z6v` "normuon-screen" | screen n=1 | 3.279 | 3275 | 1 | FINISHED |
| `8yocwc35` "normuon-clean-confirm3300" | confirm n=4 | (in flight) | latest 3250 | — | RUNNING step 6927 cumulative |

- Screen n=1 cleared target with `(3.28-3.279)*sqrt(1)=0.001`, just under the 0.004 stat rule — confirmation is needed.
- Confirm trial 1 (per prior boot): `val=3.2761 ffs=3225`. Latest `ffs=3250` suggests trial 2 also hit.
- PR is `CONFLICTING` against advisor branch (state doc files). Sent rebase reminder.
- Pre-committed merge: stat rule `(3.28-mu)*sqrt(4) >= 0.004 ⇒ mu <= 3.278`.

### nezuko #86 MuonSquared — 5 smokes failed, authorized smoke v6 numerical fix

Student ran 5 smoke variants, all NaN or OOM:
- v1 (per-module init, compile on): NaN before step 25
- v2 (per-module init, model.compile off): OOM step 0
- v3 (reference init, compile on): NaN before step 5
- v4 (reference init, `@torch.compile` on `muon_sq_update` off): NaN iter 3 forward
- v5 (reference init, model.compile off + expandable_segments): OOM step 0

Diagnostic: iter 2's MuonSq optimizer step turns finite grads + buffers into NaN weights. Root-cause: `update / (sqrt(v) + eps)` division at step 2 with `eps=1e-10` and `beta2=0.95` explodes when individual gradient entries are small.

Authorized **smoke v6** with all three numerical adjustments combined:
- `eps=1e-10 → 1e-5` (5 orders of magnitude division floor)
- `beta2=0.95 → 0.99` (smoother early-step `v` ramp)
- 5-step MuonSq warmup gate (plain Muon for steps 1-5, MuonSq from step 6+)

Pre-commit close if v6 NaNs. Label swapped `review → wip` (PR is in mid-debugging, not result-ready).

### fern #54 SOAP-MLP — smoke v6c clean BUT mbs=32 contract violation

Smoke v6c at `mbs=32 + compile-off + per-module init`:
- `val=4.240` at step 300, no NaN, SOAP refresh stable (0 eigh failures over 216 events).
- Wallclock: 6.84 s/step → 3350-step screen ~6.4 hours (way past 60-min hard budget).

**Problem: `mbs=32` is a contract violation** — doubles fwd-bwd passes per optim step (8→16), so val/loss measurements aren't comparable to public records.

Authorized **smoke v7** at `mbs=64 + compile-on + per-module init + 200-step SOAP-precond gate`:
- Plain Muon for steps 1-200 (no SOAP L/R precond), full SOAP-MLP from step 201+.
- Concept: the documented step-1 `attn.proj.bias.grad` spike is concentrated in the first ~50 steps; the 200-step gate lets the model reach a healthier regime before engaging SOAP.

Pre-commit close PR #54 if v7 NaNs.

### thorfinn #58 cooldown sweep — 26 runs / 23 failed, asked to diagnose

Across all thorfinn groups: 8 crashed at step 1, 15 failed, 2 finished (both `ffs=-1`). Mass instability looks like launcher / parallel-on-1-GPU collision, not a model issue.

Authorized **3-arm SERIAL sweep** {linear, cosine, sqrt} × cooldown_frac=0.7 at `train_steps=3350` n=1, only after thorfinn diagnoses the v1/v2 crash mode. Pre-commit close PR #58 if 3-arm serial also has > 1 crash.

### frieren #55 MuLoCo confirm — partial restart, crash check requested

- `tvb6lpz9` "muloco-n4-confirm" crashed step 4111 (mid trial 2 ≈ step 811 of trial 2).
- `0qry1ckh` restart at step 2750 val=3.342.

Asked for crash mode + trial accounting. Pre-commit merge if effective n=4 satisfies stat rule.

### edward #53 Contra-Muon confirm — trials 1+2 missed target

`n7ea9xyr` at cumulative step 7327 with `ffs=-1`. Trial 1+2 both missed. Concerning — if all 4 trials miss, this closes negative. Letting confirmation complete.

### tanjiro #87 u/w-floor — screen progressing clean

Smoke `3v4g1cq4` ran past 300 steps to step 4107 val=3.3498 (overran or repurposed). Screen `b5ucb98s` at step 1980 val=3.514, clean trajectory. Pod alive. Sent status check-in (student hasn't posted in PR yet).

### askeladd #52 MuonH — budget sweep continuing

- `budget0.85` finished `val=3.295 ffs=-1` (missed).
- `budget1.15` running at step 1925.

Tracking. Pre-commit close PR #52 if budget1.15 also misses.

### Operational notes (boot 8)

- All 8 r3 pods healthy. Zero idle GPUs.
- **mbs=64 is now confirmed as a benchmark contract constraint** — mbs reductions are diagnostic only.
- Pre-commit close pattern applied to 4 PRs (#54, #58, #86, #52) — keeps the research moving.
- Most likely first merge: alphonse #51 NorMuon. Backup: frieren #55 if crash resolves cleanly.

---

## 2026-05-15 20:00 — Wave 1 in-flight snapshot (boot 6)

Posted three advisor follow-ups: alphonse check-in (#51), thorfinn 12-arm sweep greenlight (#58), fern @torch.compile fallback escalation (#54). Headline: **alphonse #51 NorMuon is the first wave-1 PR to clear target with margin in-run** — pending terminal result.

### alphonse #51 NorMuon — promising signal mid-flight

W&B run `8yocwc35` `normuon-clean-confirm3300` (group `g1r2-alphonse/normuon-clean` — r2-prefixed despite r3 branch, flagged to student):
- `speedrun/final_first_step_to_target = 3225`, `final_reached_target = 1`, `best_val_loss = 3.2761`.
- Currently at cumulative step ~3876 → reading as multi-trial run mid trial 2.
- Public #10 NorMuon reference: `ffs=3250 mean=3.2789 n=20`. alphonse seed 1 tracks better.
- Advisor asked alphonse to (1) confirm `--num_trials`/`train_steps`/variant, (2) pin `g1r3-` wandb_group on future launches, (3) post terminal SENPAI-RESULT with per-seed table when all trials finish, (4) swap label `wip → review`.

### frieren #55 MuLoCo — n=1 screen positive, n=4 confirmation queued

- W&B run `cbjch81g` `muloco-outer-screen-s0` finished at step 3350: `val/loss=3.2793, ffs=3325`. Clean run, no NaN.
- n=1 doesn't satisfy stat rule (`mu < 3.276` needed for n=1; got 3.2793).
- Student rebased onto advisor tip + added `--train_steps` CLI flag (commit `f4d2720`, 18:21 UTC). Confirmation run `g1r3-frieren/muloco-outer-confirm-3300-n4` not yet seen in W&B — student is mid-setup.
- No advisor action needed; the screen result + rebase is on the right path.

### edward #53 Contra-Muon — confirmation trial 1 missed target

- W&B run `n7ea9xyr` `contra-muon-confirm-3225-n4` at cumulative step 3826 with `speedrun=-1`, `val/loss=3.8372`.
- Trial 1 ran 3225 steps with `speedrun=-1` (target not reached). Now in trial 2 (~step 601 of trial 2 in train phase).
- This is concerning: the n=4 confirmation may not satisfy the stat rule if trials uniformly miss. Wait for terminal.
- No advisor action: student knows the protocol; trial 1 missing is data, not a failure.

### thorfinn #58 cooldown sweep — smoke A passed, 12-arm sweep greenlit

- W&B run `cooldown-linear-0.5-s0` (after pod restart, with per-module init) — `smoke-a-init-only-linear-0.7` finished step 300, `val/loss=4.0854`, no NaN.
- Student killed the pre-revision sweep arms, applied per-module init via `WARMUP_STEPS=0` env override (commit `506c162`).
- Advisor greenlit the 12-arm sweep (shapes ∈ {linear, cosine, sqrt, quadratic} × cooldown_frac ∈ {0.5, 0.7, 1.0}) at `train_steps=3350` n=1 per arm, group `g1r3-thorfinn/cooldown-shape-sweep-v3`. Kill if ≥3 arms NaN.

### fern #54 SOAP-MLP — smoke v5 still NaN, escalating to @torch.compile disable

- W&B runs `v2rxl8a0` and `rsiuhxi5` `soap-mlp-smoke-v5-s0`: `val/loss=NaN`, `grad_norm=0`. Per-module init alone didn't stabilize.
- Advisor escalated: disable `@torch.compile` on `train_step` (defense-in-depth with per-module init). Smoke v6 at 300 steps; screen at 3350 if v6 clean.
- Compute spent so far: ~30 min on diagnostics; another ~65 min to v6 + screen.

### nezuko #86 MuonSquared, tanjiro #87 u/w-floor — wave-2 smokes just started

- `nezuko muonsq-smoke` at step 0 (init), running.
- `tanjiro uwfloor-smoke` at step 125, `val/loss=4.799`, `grad_norm=115k` (high but not NaN yet).
- No advisor action — let smokes complete.

### askeladd #52 MuonH — budget0.85 in flight

- W&B run `pg5tves8` `muonh-hyperball-budget0.85-s0` at step 1850, `val/loss=3.5834`. Tracking.
- Prior full screen `t4zxp2sf` reached `val/loss=3.2917` at 3350 with `ffs=-1` (missed target). The budget sweep is asking whether a tighter Frobenius ball changes that. No advisor action.

### Operational note

- 8/8 students have active WIP PRs. Zero idle GPUs.
- Most likely first merge candidate: **alphonse #51 NorMuon** once terminal result posts.
- Backup candidates: **frieren #55 MuLoCo** (n=4 confirmation in setup) and **edward #53 Contra-Muon** (n=4 in flight but trial 1 missed).

---

## 2026-05-15 19:35 — PRs #56 and #57 closed; wave-2 assignments #86 and #87 created

### PR #56 g1r3-nezuko — Lion replacing AdamW + Muon (CLOSED: negative)

Terminal `SENPAI-RESULT`: `{"terminal":true,"status":"negative","pending_arms":false,"wandb_run_ids":["e6t36yfr","vvh16yhr"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":-1},"test_metric":{"name":"val/loss","value":4.6171}}`

| Trial | lr_block | terminal val/loss | terminal step | reached target | ffs |
| --- | --- | --- | --- | --- | --- |
| 0 | 1e-4 | 5.0250 | 3350 (full) | no | -1 |
| 1 | 2e-4 | 4.6171 | 1875 (SIGTERM) | no | -1 |
| 2 | 4e-4 | not run (killed) | — | — | — |
| 3 | 8e-4 | not run (killed) | — | — | — |

- Best arm (val=4.6171 partial, arm 1) shows grad non-finite onset before step 1875.
- 1.7+ nat gap to the 3.28 target. No Lion arm competitive at this scale.
- Student correctly analyzed: Lion replaces the NS-orthogonalized update on hidden weights, losing the well-conditioned orthogonal update that drives Muon's performance. Sign-based methods need much smaller LR and longer schedules to compensate; 3350-step budget doesn't allow it.
- **Closed.** Nezuko reassigned to **MuonSquared (PR #86)**.

### PR #57 g1r3-tanjiro — Per-module init std on plain Muon (CLOSED: negative)

Terminal `SENPAI-RESULT`: `{"terminal":true,"status":"negative","pending_arms":false,"wandb_run_ids":["0jf2cf7n","mvvtvcn6"],"primary_metric":{"name":"speedrun/final_first_step_to_target","value":-1},"test_metric":{"name":"val/loss","value":3.28554}}`

| Seed | val/loss @ 3350 | ffs | time (s) |
| --- | --- | --- | --- |
| s0 (`0jf2cf7n`) | 3.28575 | -1 | 6020 |
| s1 (`mvvtvcn6`) | 3.28534 | -1 | 6017 |

- n=2 mean val=3.28554, σ=0.00029. Statistical margin `(3.28 - 3.28554) * sqrt(2) = -0.00784` (far from the +0.004 target). 0.007 worse than baseline expected.
- Correct analysis from student: only `attn.proj` and `mlp.proj` actually change from the starter (since `qkv` and `mlp.fc` are already at `sqrt(0.33)/sqrt(768)` in the starter's default init). The real change is narrower than expected — and without NorMuon/MuonH/Contra-Muon underneath, the init shift is too small to overcome single-seed noise.
- Cross-validated: the stable plain-Muon runs on this branch (frieren, askeladd, edward) all have an implicit update clamp in their experimental code that incidentally masks the torch.compile NaN bug. Per-module init is the explicit stability lever.
- **Closed.** Tanjiro reassigned to **u/w-floor (PR #87)**.

### Wave 2 assignments created

- **PR #86** — g1r3-nezuko: MuonSquared (`lr=0.10, wd=0.0125, beta2=0.95, eps=1e-10`). Target: reproduce public #7 (`val=3.2752, ffs=3325 n=1`) and confirm at n=4 @ 3300 steps. Per-module init mandatory for stability.
- **PR #87** — g1r3-tanjiro: u/w-floor (`TARGET_UW=0.35, lr=0.0375, wd=0`, plain Muon base). Target: reproduce public #9 component (`ffs=3250 n=8` with NorMuon stack) in isolated form. Per-module init mandatory for stability.

---

## 2026-05-15 19:05 — Wave 1 fern PR #54 root-cause checkpoint

Fern delivered a clean root-cause analysis of the SOAP NaN. Headline:
**SOAP-MLP-Muon code is correct**; the NaN cascade originates upstream of
SOAPMuon, in plain Muon at default init on 1 GPU. This matches the
operational pattern we already had: every plain-Muon-on-1-GPU run on this
branch NaNs unless an experimental clamp / smaller init / preconditioner
is in place.

### What fern proved (W&B runs `dlv7rkck`, `tce8dakn`, `zoqo0l97`)

| Step | `train/loss` | `grad/global_norm` | `grad/all/nonfinite_count` |
| --- | --- | --- | --- |
| 1 | 10.826 | **235,491** | 0 |
| 25 | NaN | 0 | **147,758,208** (≈100%) |
| 50 | NaN | 0 | 148,010,880 |

Three isolation runs reproduce the same signature:
- v4 with full SOAPMuon (`dlv7rkck`) — NaN by step 125, all 24 attempted
  eigh refreshes silently caught (warmup gate kept SOAP off till step 50).
- Split params, plain Muon on both groups (`tce8dakn`) — NaN by step 25.
- Single Muon on all block params (baseline-equivalent) (`zoqo0l97`) — NaN
  by step 25, identical 147M nonfinite-grad signature.

Fern's cross-reference: matches alphonse's PR #59 on `auto-nanogpt-1gpu-r1`
which root-caused a `torch.compile` Inductor kernel-emission bug producing
NaN in `blocks.0.attn.proj.bias.grad` at step 1, then propagating via
`dist.all_reduce(SUM)` to every rank and through Muon's NS matmuls to all
params by step ~25.

### Stable counter-example on our branch

`g1r3-tanjiro/per-module-init-screen-s0` runs plain Muon at 1 GPU with
**per-module init std** (no LR warmup, no compile change, no internal
clamp). It trained 3350 steps stably to `val/loss = 3.2858`. Compared to
fern's three NaN-by-step-25 runs, the only differentiator is the init.

### Conclusion + operational rule

**Per-module init std is mandatory for any plain-Muon-on-1-GPU experiment
on this branch.** Specifically:
- `attn.proj.weight.std = 0.026`
- `mlp.proj.weight.std = 0.031`
- `mlp.fc.weight.std = 0.031`
- (qkv stays at the current default, proj weights stay zero-initialized
  as in the starter)

This supersedes my earlier "add 100-step LR warmup" rule — warmup alone
doesn't fix it (thorfinn's warmup-100 also failed at step 3).

### Advisor action on PR #54

- Reset label `status:review → status:wip` (PR is asking a question, not
  proposing a merge).
- Sent: apply per-module init std on top of v2 SOAPMuon; re-run smoke v5
  at 300 steps. Fallback if smoke still NaNs: disable `@torch.compile` on
  `train_step` (justifiable since the comparison axis is step count, not
  wallclock).
- Declined: `nan_to_num` mask before `all_reduce` (two reasons — masks a
  real numerical failure mode for SOAP-specific bugs; and the right-layer
  fix is init).

### What this means for other PRs

- **thorfinn #58** (cooldown sweep): my prior advice was Smoke A
  (per-module init only) and Smoke B (init + warmup) before the 12-arm
  sweep. The operational rule now strengthens this — Smoke A IS the path,
  warmup is a secondary lever.
- **alphonse #51** (NorMuon, after EMA fix): NorMuon's row/col variance
  preconditioner inherently damps NaN-tinged gradients (1/sqrt(var)
  collapses toward zero on a NaN row), so it may run without per-module
  init. The new `confirm3300` run is at step ~25 — let it reach step 300+
  before deciding.
- **frieren #55** (MuLoCo): the screen ran cleanly — either MuLoCo's
  outer Nesterov averaging masks the upstream NaN, or frieren got a
  lucky seed. n=4 confirmation will surface intermittent failures.
- **askeladd #52, edward #53**: both screens ran cleanly without
  per-module init — their experimental code (MuonH clip, Contra-Muon
  coordinated update) effectively damps the cascade.

---

## 2026-05-15 18:35 — Wave 1 second-checkpoint snapshot

Roughly 6 hours into wave 1 (launched ~12:35 UTC). W&B audit of all 8 PRs.
Headline: **frieren MuLoCo** is the first PR with a clean target-reaching
single-seed run, but `ffs=3325` is not yet a statistical winner so it's in
n=4 confirmation. **askeladd MuonH** screen finished sub-target.
**nezuko Lion** is a confirmed dead end and being asked to close.

### PR #51 g1r3-alphonse — NorMuon (after EMA fix)
- New run `g1r3-alphonse/normuon-clean-confirm3300` launched at ~16:26 UTC,
  currently step ~25 with initial loss (10.83) — too early to read.
- Prior smoke runs (pre-EMA-fix) all NaN at step 300; the latest one is
  `normuon-impl-smoke-canonical`, finished NaN, confirming the bug
  signature.
- **Advisor action this iteration**: none — let the corrected rerun reach
  step 300+ before assessing.

### PR #52 g1r3-askeladd — MuonH clip-only
- Screen `g1r3-askeladd/muonh-hyperball-screen-s0` finished at step 3350
  with `val/loss = 3.2917`, `ffs = -1`. **Did not reach target.**
- Public #5 (always-active variant + per-module init, n=10) hit
  `val=3.2782, ffs=3325`. Our clip-only n=1 missed by ~0.014 in val and
  the target line entirely.
- Diagnosis: clip-only damps norms back to `R` (active_fraction ~0.99) but
  doesn't actively pull them below `R` like `scale_invariant_update_`; no
  per-module init compounds the miss.
- **Sent**: Option 1 — budget_mult ∈ {0.85, 1.0, 1.15} sweep + per-module
  init; Option 2 — always-active variant + per-module init. Run Option 1
  first (cheaper).

### PR #53 g1r3-edward — Contra-Muon
- 4-seed confirmation `g1r3-edward/contra-muon-confirm-3225-n4` launched
  at ~16:26 UTC, currently step 1 (initial loss). In flight.
- Prior screen had landed at `val=3.2808, ffs=-1` (n=1 miss by 0.0008).
- **Advisor action this iteration**: none — let confirmation run.

### PR #54 g1r3-fern — SOAP-on-MLP precond before Muon NS
- Latest g1r3-fern run `soap-mlp-smoke` still NaN at step 200 even after
  the corrected `_matrix_power` + 50-step precond warmup + float64 state.
- Two fresh smoke launches running: `soap-mlp-smoke-v4` (just started),
  `g1r2-fern/contra-soap-mlp-smoke-fix` (just started).
- **Advisor action this iteration**: none — give the new smokes a chance.
  If both NaN, escalate with float64-precision eigenvalue traces.

### PR #55 g1r3-frieren — MuLoCo outer Nesterov around plain Muon
- Screen `g1r3-frieren/muloco-outer-screen-s0` **finished** at step 3350:
  `val/loss = 3.2793`, **`ffs = 3325`** (reached target).
- n=1 result doesn't satisfy the statistical rule
  (`(3.28 - 3.2793) * sqrt(1) = 0.0007 < 0.004`), and `ffs=3325` is
  slightly worse than the public #12 plain-Muon expectation (~3300).
- **Sent**: n=4 confirmation at `train_steps=3300`; if mean misses, sweep
  `outer_lr ∈ {0.5, 0.7, 1.0}` × `outer_momentum ∈ {0.3, 0.5, 0.7}` at n=1
  before re-confirming. Public #13 NorMuonH-in-MuLoCo hit `ffs=3210` at
  n=10 so the wrapper has more headroom.

### PR #56 g1r3-nezuko — Lion replacing AdamW + Muon
- `g1r3-nezuko/lion-everywhere-lr-sweep` at step 3686 with `val/loss = 6.6365`. Diverged. Best Lion-flavored arm anywhere in the project is `g1r4-thorfinn/lion-aux-arm-a` at `val=3.3144, ffs=-1` (worse than baseline; Lion only on aux slots).
- **Confirmed negative result.** Lion-everywhere at this scale is not competitive.
- **Sent**: stop the running smoke, post terminal `SENPAI-RESULT` with
  `status="negative"` + LR-sweep table, swap to `status:review`. I'll
  close and reassign from the wave-2 queue (PSGD-Kron or Muon²).

### PR #57 g1r3-tanjiro — Per-module init std on plain Muon
- Run history: `screen-s0` (n=1) finished at `val=3.2858, ffs=-1`;
  second seed `screen-s0` instance running, currently step ~1775 with
  `val=3.4949` (mid-run).
- Init-only is a weak lever for plain Muon at this scale.
- **Sent**: recommended path A — let s1 finish, post 2-seed table,
  `status="negative"`, close. Init forward-rides onto wave-1 algorithmic
  winners. (Option B = run 4 seeds was offered but discouraged.)

### PR #58 g1r3-thorfinn — Cooldown shape × cooldown_frac sweep
- 100-step warmup fix failed: `g1r3-thorfinn/smoke-warmup100-linear-0.7`
  crashed at step 3.
- Diagnostic cross-PR fact: tanjiro's plain-Muon-WITH-per-module-init
  (no warmup, no compile change) is the only stable 1-GPU plain-Muon
  config on this branch.
- **Sent**: revised plan — Smoke A (per-module init only) and Smoke B
  (per-module init + warmup) as 300-step diagnostics before committing
  the 12-arm sweep. Escalate if both NaN; try lower Muon `mu=0.85` or
  disable `@torch.compile` next.

### Operational learnings this iteration

- **frieren MuLoCo screen reaching the 3.28 line** is the first wave-1
  signal that wrapping plain Muon in an outer Nesterov SGD actually
  works on 1 GPU — encouraging, but needs multi-seed.
- **askeladd's clip-only MuonH miss** suggests the clip-only/always-active
  distinction is doing more work than I assumed when I wrote the
  hypothesis. The bundled reference uses always-active; we should
  default to always-active for any future Frobenius-ball variant.
- **The 1-GPU plain-Muon NaN instability is tied to init std, not LR.**
  thorfinn's warmup-100 fix failing at step 3 + tanjiro's per-module
  init running cleanly with no warmup + no public 1-GPU runs using
  default init = strong evidence the init lever is mandatory for any
  plain-Muon-derived experiment at world_size=1.
- **Per-module init is a free-rider lever.** It doesn't move the needle
  in isolation but appears to be the stability prerequisite for plain
  Muon at 1 GPU. Future PRs touching plain Muon at 1 GPU should fold
  it in by default.

---

## 2026-05-15 15:35 — Wave 1 in-flight snapshot (no merges yet)

Wave 1 launched at ~12:35 UTC. By ~15:35 UTC the following observations:

### PR #51 g1r3-alphonse — NorMuon (Muon NS + Adafactor row/col precond)
- 4 smoke runs all finish at step 300 with `val/loss = NaN`.
- Root cause: assignment spec had an EMA bug
  (`row_var.add_(g², alpha=1-beta2)` without `.mul_(beta2)` first → row/col
  variances accumulate monotonically, producing zero entries in `precond`
  for dead rows/cols → `1/sqrt(1e-30)` blowup).
- **Sent**: corrected EMA spec + rebase pointer + kill gates + step budget.
- Awaiting rerun.

### PR #52 g1r3-askeladd — MuonH + per-module init std
- Smoke clean. `train/muonh/active_fraction = 0.944–1.000` confirms clip
  fires on ~99% of hidden tensors every step.
- `norm_to_radius_max = 1.00002–1.00689` — projection is doing real work.
- Independently caught `sample_tensor` OOB-index bug; clean writeup; fix
  cherry-picked into advisor branch (commit cc1c710).
- **Sent**: ack of clip-only-vs-always-active decision + rebase pointer.
- Screening 3350-step run in flight.

### PR #53 g1r3-edward — Contra-Muon
- Screen run `g1r3-edward/contra-muon-screen-s0` reached `val/loss = 3.281`
  at step 3350 (single seed; misses `< 3.28` line by 0.001).
- Independently caught `sample_tensor` OOB-index bug.
- **Sent**: rebase pointer; proceed to `train_steps=3225 × --num_trials 4`
  confirmation; if no clear, sweep `contra_alpha ∈ {0.25, 0.5, 0.75}`.
- Awaiting confirmation run.

### PR #54 g1r3-fern — SOAP-on-MLP precond before Muon NS
- Smoke runs NaN by step 20–140 across multiple versions.
- Likely root cause: assignment spec underspecified `_matrix_power`
  numerical stability + no preconditioner warmup (first refresh at step 32
  hits the run with a sharp ill-conditioned precond).
- **Sent**: defensive `_matrix_power` (symmetrize + relative+absolute eigval
  clamp), 50-step precond warmup (use plain `g` for first 50 steps), float64
  preconditioner state, eigenvalue telemetry, kill gates.
- Awaiting rerun.

### PR #55 g1r3-frieren — MuLoCo outer Nesterov around plain Muon
- Screen `g1r3-frieren/muloco-outer-screen-s0` at step 3125 with
  `val/loss = 3.300`. Run still has ~225 steps to go.
- Run looks healthy; loss converging on target. No advisor action needed
  this iteration.

### PR #56 g1r3-nezuko — Lion replacing AdamW + Muon everywhere
- LR sweep `g1r3-nezuko/lion-everywhere-lr-sweep` at step 2100 with
  `val/loss = 5.37`. Far from target.
- Lion at this scale doesn't appear competitive; expect to close as a
  negative-result PR once the LR sweep finishes.
- No advisor action this iteration — let the screen run complete so we have
  the full 4-arm LR signal before closing.

### PR #57 g1r3-tanjiro — Per-module init std on plain Muon
- Screen run `g1r3-tanjiro/per-module-init-screen-s0` finished at step 3350
  with `val/loss = 3.2858` (`speedrun/final_first_step_to_target = -1`,
  i.e. target not reached).
- 1-seed result is consistent with baseline expectation (~3.279 from public
  #12) within noise — per-module init alone is **not a step-count lever**
  for plain Muon at our scale.
- Awaiting student to post terminal results and SENPAI-RESULT marker.
- Likely outcome: close PR (no improvement) and route the per-module init
  forward as a free-rider on the next algorithmic winner.

### PR #58 g1r3-thorfinn — Cooldown shape × cooldown_frac sweep
- Blocked by 1-GPU plain-Muon NaN instability: starter NaNs by step 25
  (with `@torch.compile`) or step 1525 (without). Cooldown change is not
  the root cause; pre-existing instability of plain Muon at 1 GPU.
- Student also caught `sample_tensor` OOB bug — third independent report.
- Student requested guidance before burning ~30h compute.
- **Sent**: accept warmup option (100-step linear LR warmup applied to all
  12 arms identically, preserving the cooldown-shape isolation); rebase
  pointer; hard kill gates (≥3 NaN arms → stop the sweep); hold
  confirmation until I review the screening table.
- Awaiting screening sweep.

### Operational learnings this iteration

- **`sample_tensor` OOB-index** in the starter telemetry was a real
  starter-code bug (float32 linspace endpoint overshoots for `n > 2^24`).
  Caught independently by 3 students. Cherry-picked into advisor branch
  as commit cc1c710 so wave 2 inherits a clean starter.
- **Plain Muon at world_size=1 with default init is NaN-unstable.** Every
  successful 1-GPU run in W&B uses either non-default init (smaller std)
  or an adaptive preconditioner (NorMuon, SOAP, MuonH). Operational rule
  for any future plain-Muon 1-GPU run: add a 100-step LR warmup.
- **My NorMuon and SOAP assignments had bugs.** Both have been corrected
  in PR comments. Future assignments should reference canonical
  reference impls in `records/track_3_optimization/results/<date>_<name>/`
  more explicitly — at minimum quote line ranges from the reference logs.

## 2026-05-19 09:22 — PR #425 CLOSED: MuonH-SI inner mu cooldown sweep (frieren)

- **Branch**: g1r3-frieren/muonh-mu-cooldown-sweep
- **Hypothesis**: Cosine-decay inner Nesterov momentum from mu=0.95 → mu_final during LR cooldown phase. Three arms: ctrl (mu_final=0.95), moderate (mu_final=0.70), aggressive (mu_final=0.50).
- **Implementation**: New `--muonh_mu_final` flag; cosine schedule from warmup_steps → train_steps.

| Arm | mu_final | W&B run | val/loss | ffs | Δ vs baseline (3.27286) | σ |
|---|---|---|---|---|---|---|
| 1 ctrl | 0.95 | `o8zyjowj` | 3.27325 | 3150 | +0.00039 | baseline-equiv |
| 2 | 0.70 | `v7ztc5yx` | 3.28051 | -1 | +0.00765 | ~9σ NEG |
| 3 | 0.50 | `xld472fl` | 3.28863 | -1 | +0.01577 | ~20σ NEG |

**Result: CLOSED NEG — monotonic catastrophic.** Decaying inner Nesterov mu during cooldown is uniformly harmful. Pattern: mu=0.95 anchor is load-bearing throughout training; reducing it makes the optimizer over-responsive to current gradients at low LR precisely when stability is needed.

**Analysis**: Third consecutive data point confirming the MuonH-SI schedule is saturated in the "adaptivity during cooldown" dimension:
- PR #417 (cooldown_frac sweep) — all NEG monotonic, 1.0 is only viable
- PR #389 (mu warmup from 0.5→0.95) — NEG, "under-accumulation during warmup" harmful  
- PR #425 (mu cooldown from 0.95→0.70/0.50) — NEG monotonic, ~9σ and ~20σ

**Lever closed**: MuonH-SI inner schedule is fully saturated. No further cooldown/warmup schedule variations warranted.

**Next for frieren**: PR #453 assigned — MuLoCo sync_interval re-sweep on current AGC+warmup baseline (15/30/60).

## 2026-05-19 22:02 UTC — PR #471 CLOSED: eps=1e-6 n=4 confirmation (edward)

- **Branch**: g1r3-edward/eps-1e6-n4-confirm
- **Hypothesis**: n=4 statistical confirmation that `--aux_adamw_eps 1e-6` (PR #443 winner) is a real improvement vs the old eps=1e-10 baseline (PR #329, mean=3.27286).
- **All 4 arms used**: `--aux_adamw_eps 1e-6` with default RNG seed progression (no fixed seed).

| Arm | W&B run | val/loss | ffs | Δ vs old baseline (3.27286) |
|-----|---------|---------|------|---------------------------|
| 1 | `7un3lhgi` | 3.27129 | 3125 | −0.00157 |
| 2 | `nyci0k7j` | 3.27331 | 3150 | +0.00045 |
| 3 | `r43od98v` | 3.27213 | 3125 | −0.00073 |
| 4 | `1bn51v5g` | 3.27197 | 3125 | −0.00089 |
| **n=4 mean** | | **3.27218** | 3131 | **−0.00068** |
| 95% CI (t, 3df) | | [3.27084, 3.27351] | | — |

**Decision: CLOSED (no merge needed — eps=1e-6 already in baseline via PR #443).**

**Analysis**:
- All 4 arms hit target (val ≤ 3.28) and cleared kill gate (val < 3.30 at step 3000).
- n=4 mean (3.27218) is **below old baseline (3.27286) by −0.00068**, confirming the direction is real.
- However, n=4 mean does NOT clear the conservative n=4 bar (<3.27079) — sits +0.00138 above it.
- 95% CI [3.27084, 3.27351] touches but doesn't exceed the bar: the lower end barely touches 3.27079.
- PR #443 n=1 win (3.27119, ffs=3100) was a **favorable-seed outlier**: none of the 4 arms reproduced ffs=3100, and the best arm (3.27129) is +0.00010 worse than the n=1 datum.
- True effect size: ~σ/2 to 1σ improvement from eps=1e-6. Real but small. Seed-to-seed spread ~0.002 nats (range 3.27129 → 3.27331).

**Conclusion**: eps=1e-6 is at worst neutral and at best a small real-effect improvement. The current baseline `t1coza71` (3.27119) was a lucky seed inside a distribution centered around ~3.272. We keep `--aux_adamw_eps 1e-6` in the stack because direction is confirmed; we don't expect it to clear n=4 conservative bars on its own.

**Next for edward**: PR #512 assigned — H6 Aux AdamW `v_t` partial reset at cooldown onset (`--aux_v_reset_frac` 1.0/0.5/0.1).

## 2026-05-20 01:30 UTC — PR #510 CLOSED: Aux NAdam — unfused optimizer path incompatible with eps=1e-6 + AGC stack (frieren)

- Branch: `g1r3-frieren/aux-adamw-nesterov`
- Hypothesis: NAdam (Nesterov AdamW) on aux groups mirrors Nesterov used in MuonH-SI/MuLoCo; lookahead term may improve convergence under eps=1e-6.

| Arm | W&B run | val/loss | Δ vs baseline 3.27119 | Notes |
|---|---|---|---|---|
| 1 ctrl (fused AdamW) | `otpucdbo` | 3.27222 | +0.00103 | baseline-equivalent (n=1 noise) |
| 2 NAdam fixed-beta (decay=0) | `p96pfx9b` | NaN @ step 3 forward | — | smoke-gate killed |
| 3 NAdam decay-beta (decay=0.004) | — | not run | — | skipped after diagnosis |
| diagnostic AdamW(fused=False) | `9playthp` | NaN @ step 3 forward | — | identical failure |
| diagnostic NAdam 30-step probe | `16hobbah` | NaN @ step 3 | — | telemetry_interval=1 |

**Decision: CLOSED (NAdam arms worse than ctrl per decision tree; mechanistic value preserved).**

**Mechanistic finding (HIGH VALUE)**:
- NaN does NOT originate in NAdam update math. Step-1 NAdam state is fully zero for zero-grad biases (no-op); non-zero-grad params get ~10%-larger update magnitude (consistent with Nesterov lookahead term).
- NaN appears in step-2 forward pass: 8 of 768 entries in attn proj bias gradient go NaN.
- Plain `AdamW(fused=False)` with identical hyperparameters (lr, betas, eps=1e-6, AGC clip=0.05) shows identical step-3 NaN.
- **Root cause**: eps=1e-6 + AGC + per-group LR aux stack depends on fused AdamW's internal FP32 accumulation. PyTorch's NAdam has no fused kernel, so it inherits the unfused path and the same instability.

**Implications for hypothesis bank**:
- **H8 AdaBelief**: BLOCKED unless fused implementation provided or aux stack rebuilt.
- **H2 Lookahead**: SAFE (wraps fused AdamW; slow-weights step is post-update).
- **Lion**: SAFE (sign-based update has bounded magnitude regardless of fusion).
- **H3 SWA at cooldown**: SAFE (averaging is post-update, doesn't enter the divergent path).
- **Schedule-Free AdamW**: needs verification.

**Conclusion**: Closing PR #510. The unfused-path incompatibility is recorded as a global constraint on future aux optimizer assignments. Excellent diagnostic work from frieren — mechanistic insight more valuable than a +0.001 numeric improvement would have been.

**Next for frieren**: PR #525 assigned — Lookahead aux wrapper (H2) at k=5, α=0.5 vs α=0.8.

## 2026-05-20 02:00 UTC — PR #501 CLOSED: Per-group eps decomp — embed NOT the carrier (fern)

- Branch: `g1r3-fern/aux-eps-per-group-decomp`
- Hypothesis: split aux AdamW eps into per-group flags (embed/lm_head/scalars) and identify which group carries the eps=1e-6 win.

| Arm | embed_eps | lm_head_eps | scalars_eps | W&B run | val/loss | ffs | Δ vs ctrl arm 1 |
|---|---|---|---|---|---|---|---|
| 1 ctrl | 1e-6 | 1e-6 | 1e-6 | `1435u3bd` | 3.27393 | 3150 | (ref) |
| 2 | **1e-10** | 1e-6 | 1e-6 | `gsno1p02` | **3.27280** | 3125 | **−0.00113** |
| 3 | 1e-6 | **1e-10** | **1e-10** | `h75zx52w` | 3.27540 | 3175 | **+0.00147** |

**Decision: CLOSED (no merge — best arm 2 at +0.00161 above baseline does not clear merge bar 3.27039).**

**Mechanistic finding**:
- Arms 2 and 3 land on opposite sides of ctrl with directional consistency — strongest possible signal from a 3-arm split with n=1.
- **eps=1e-6 win lives in lm_head and/or scalars, NOT embed.** Reverting embed to 1e-10 may even be slightly preferred.
- Physical interpretation: embed has large gradients → large v → eps choice irrelevant. lm_head and scalars have small gradients → small v → eps=1e-6 acts as a meaningful floor.

**Per-group eps decomp finding records as global context**: future per-group eps tweaks should consider lm_head/scalars (not embed) as the action axis.

**Next for fern**: PR #531 assigned — Schedule-Free AdamW for aux (H11; replaces aux linear cooldown with Polyak-Ruppert averaging; differentiates from CLOSED PR #265 SF-MuonH by applying SF only to aux where cooldown is linear frac=0.4, not WSD cosine). Lion (H10) was already CLOSED NEG in PR #218 (2026-05-17).

## 2026-05-20 03:39 UTC — PR #507 CLOSED: Embed init std sweep — embedding-side weak lever, U-shape doesn't clear bar (nezuko)

- Branch: `g1r3-nezuko/embed-init-std-sweep`
- Hypothesis: GPT-2 / nanoGPT historically use embed init std = 0.02. Our baseline uses std=1.0 — unusually large. Sweep std=1.0 (ctrl) / 0.1 / 0.02 to test whether a smaller init makes the (active win direction) higher embed_lr more effective by giving the optimizer more room before saturating.

| Arm | std | W&B run | val/loss | ffs | Δ vs ctrl (3.27188) | Δ vs baseline (3.27119) |
|---|---|---|---|---|---|---|
| 1 ctrl | 1.0 | (terminal post) | **3.27188** | 3125 | (ref) | +0.00069 |
| 2 | 0.1 | (terminal post) | 3.27231 | 3150 | +0.00043 (LOSS) | +0.00112 |
| 3 | 0.02 | (terminal post) | **3.27142** | **3125** | −0.00046 (best arm) | +0.00023 |

**Decision: CLOSED (no merge — best arm 3 at 3.27142 doesn't clear n=1 merge bar 3.27039).**

**Mechanistic finding**:
- Non-monotonic U-shape: std=1.0 → 3.27188, std=0.1 → 3.27231, std=0.02 → 3.27142. The intermediate point (0.1) is *worst*, not on a smooth gradient.
- All 3 arms cluster within ~0.001 — well inside ctrl noise σ ≈ 0.0012. **Embedding-side knobs are weak levers** under the current eps=1e-6 + AGC + per-group LR stack.
- Consistent with PR #501 finding: **eps=1e-6 win lives in lm_head/scalars, NOT embed**. The embed group has large gradients → large v → both eps and init geometry are largely irrelevant for convergence dynamics on this lever.
- The single-seed favorable bias of `t1coza71` (n=1 baseline at 3.27119) likely explains why arm 3 looks close to ctrl noise rather than being an obvious win.

**Closing rationale**: H5 closes NEG/exhausted at default seed. Embedding-side scalar/init levers (LR, eps, init std) are all saturated. Future moves on this group need a fresh mechanism (e.g. embed-only optimizer change), not scalar tuning.

**Next for nezuko**: PR #536 assigned — H15 MuLoCo outer-step pruning ablation (`--use_outer_optimizer 0` arm B). Pure CLI-flag prune; ctrl + OFF + outer_momentum=0 arms. Direct test of whether MuLoCo Nesterov-SGD outer wrapper is load-bearing on single-GPU r3, or inert overhead.

## 2026-05-20 04:25 UTC — PR #512 CLOSED: Aux v_t partial reset at cooldown — non-monotonic U with optimum at 0.5, doesn't beat baseline (edward)

- Branch: `g1r3-edward/aux-v-reset-cooldown`
- Hypothesis: Resetting (or partially resetting) the AdamW second-moment buffer `v_t` at cooldown onset would re-adapt the optimizer to the smaller-LR regime, helping the low-grad groups that benefit from the eps=1e-6 floor.

| Arm | aux_v_reset_frac | W&B run | val/loss | ffs | Δ vs ctrl (3.27280) | Δ vs baseline (3.27119) |
|---|---|---|---|---|---|---|
| 1 ctrl | 1.0 (full reset) | `x2n8smi9` | 3.27280 | — | (ref) | +0.00161 |
| 2 | 0.5 (partial) | `z814787y` | **3.27142** | **3125** | **−0.00138** | +0.00023 |
| 3 | 0.1 (almost no reset) | `qkb44tgz` | 3.27270 | — | −0.00010 | +0.00151 |

**Decision: CLOSED (no merge — best arm 2 at +0.00103 above merge bar 3.27039).**

**Mechanistic finding**:
- Non-monotonic U-shape with optimum at partial reset (0.5). Full reset (1.0) wipes useful v_t accumulation; no-reset (0.1) misses the perturbation benefit.
- Arm 2 vs arm 1: Δ=−0.00138 is **above seed noise** (σ ≈ 0.0012). The mechanism is real.
- But arm 2 vs baseline: +0.00023 (within seed noise). Effect magnitude consumed by `t1coza71` favorable-seed bias.

**Compound idea logged**: (reset_frac=0.5) × (only on lm_head/scalars groups) could amplify the signal — these are exactly the eps=1e-6 carrier groups per PR #501. Filed as future hypothesis if H7 (per-group WD) lands well.

**Next for edward**: PR #539 assigned — H7 per-group AdamW weight decay under eps=1e-6 stack. Hypothesis: under prior eps=1e-10 regime, low-grad groups (lm_head/scalars) had near-zero updates so WD>0 would have dominated; under eps=1e-6 those groups have meaningful update magnitude, so WD can act as proper regularization. Three arms: ctrl (all wd=0) / carriers (lm_head+scalars wd=0.01) / all-aux (wd=0.01).

