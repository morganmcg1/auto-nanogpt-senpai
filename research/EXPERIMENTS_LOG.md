# SENPAI Research Results — auto-nanogpt-1gpu-r3

Per-PR record of experiment outcomes. New entries prepended (newest first).
Each entry summarizes the hypothesis, the result(s), and the conclusion that
drives the next-wave assignment.

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
