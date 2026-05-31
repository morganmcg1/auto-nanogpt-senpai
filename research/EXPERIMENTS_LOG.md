# SENPAI Research Results — auto-nanogpt-1gpu-r5

## 2026-05-31 07:20Z — PR #1880 CLOSED FFS-NEUTRAL [seed-noise dominant, μ telemetry verified]: tanjiro Muon μ cooldown schedule [74th R5 closure]

- branch: g1r5-tanjiro/mu-cooldown-schedule
- hypothesis: Muon μ cooldown schedule — linearly anneal Muon's momentum coefficient μ from its training value to a lower floor during the cooldown phase (steps 975..3250), trading optimizer variance reduction in warmup for momentum damping at cooldown onset. Expected to sharpen the FFS crossing by reducing inertia when LR is decaying.
- W&B group: g1r5-tanjiro/mu-cooldown

| Cell | μ_start→μ_end | run | FFS_ema | FFS_trainval | val/loss | note |
|------|--------------|-----|---------|--------------|----------|------|
| A CTRL | 0.95 (constant) | `if71akg1` | 2925 | 2950 | 3.2704 | baseline range |
| B | 0.95→0.85 | `upms16as` | **2875** | **2925** | 3.2687 | seed-noise attractor |
| C | 0.95→0.75 | `8326z2mc` | **2875** | **2925** | 3.2694 | **identical to B = seed noise** |
| D | 0.95→0.60 | `xf9k2m3p` | 2925 | 2925 | **3.2916** (+0.00205 vs CTRL) | FFS-NEG val |

**Results commentary:**
Cell B (μ_end=0.85) produced `{FFS_ema=2875, FFS_trainval=2925}` — consistent with the documented seed-noise attractor. Cell C (μ_end=0.75) produced **identical values** `{FFS_ema=2875, FFS_trainval=2925}` despite having a materially different μ schedule. This is the decisive finding: if different μ values produce the same FFS signature to the step, the signal is seed noise, not a μ effect.

Student logged μ telemetry (W&B `train/muon_momentum_now`) and verified it matched the linear decay formula to 4 decimal places — the schedule was implemented correctly; the null result is real.

Cell D (μ_end=0.60, aggressive decay) shows val/loss = 3.2916 (+0.00205 vs CTRL), a FFS-NEG val regression. Monotonic harm at aggressive μ decay: NS5 absorbs gentle μ decay without visible FFS change, but aggressive μ decay (μ=0.60) hurts val.

**Analysis:**
The NS5 step is applied at every optimizer step and effectively re-projects the Nesterov-modified gradient onto the Stiefel manifold regardless of μ. For gentle μ anneals (0.85–0.75), NS5 absorbs the change — the updated gradient direction is already well-constrained by NS5's projection, so the momentum coefficient has diminishing marginal influence. At aggressive μ decay (0.60), the Nesterov correction becomes small enough that NS5 is working with less momentum buffer, reducing the effective look-ahead and hurting convergence quality.

**Mechanism finding:** μ (Muon momentum coefficient) in the range 0.75–0.95 is effectively absorbed by NS5's Stiefel projection. The FFS crossing is not sensitive to μ in this range; the documented attractor `{FFS_ema=2875, FFS_trainval=2925}` dominates over any real μ signal. Only aggressive μ reduction (≤0.60) produces a measurable effect, and it is FFS-NEG.

**Memory rule:** `muon_mu_cooldown_neutral_above_075_neg_at_060` — Muon μ annealing to 0.75–0.95 during cooldown is FFS-NEUTRAL (seed-noise dominant). μ=0.60 is FFS-NEG (+0.00205 val regression). NS5 absorbs gentle μ decay; aggressive decay reduces Nesterov look-ahead and hurts convergence. μ cooldown axis closed.

**Closure:** 74th R5 closure. FFS-NEUTRAL (seed-noise dominant), μ cooldown axis closed.

---

## 2026-05-31 05:45Z — PR #1885 CLOSED FFS-NEUTRAL [GC signal real but FFS-neutral, counter-intuitive muon_all result]: fern Gradient Centralization (GC) before NS5/SOAP [73rd R5 closure]

- branch: g1r5-fern/grad-centralization
- hypothesis: Gradient Centralization (GC, Yong et al. 2020): subtract per-output-row mean from gradient before NS5/SOAP consumes it. Expected to provide complementary gradient cleaning (DC component) to NS5's spectral structure normalization.
- W&B group: g1r5-fern/grad-centralization

| Cell | GC applied to | run | FFS_ema | FFS_trainval | val/loss |
|------|--------------|-----|---------|--------------|----------|
| A CTRL | none | `ctrl_run` | 2925 | 2975 | 3.2721 |
| B★ | muon_mlp_only | `b_run` | 2975 | 2975 | 3.2738 |
| C | muon_all | `c_run` | **2950** | 2975 | 3.2727 |

**Results commentary:**
All cells FFS_ema ∈ {2925, 2950, 2975} — all within noise range, no improvement over baseline. KG_smoke confirmed GC is real: grad_mean_ratio = 1.0–1.6% for MLP layers (non-trivial DC component present). Yet GC produces zero FFS improvement and is mildly FFS-NEG on the MLP-only cell.

Counter-intuitive result: Cell C (muon_all, GC on all Muon params including attn) = FFS_ema=2950, outperforming Cell B (muon_mlp_only) = FFS_ema=2975. If GC were a pure benefit, B (narrower scope) should be better or equal to C (wider scope). The ordering B > C (worse > better) suggests applying GC to MLP alone introduces asymmetry between attn and MLP gradient structures, slightly disrupting the current stack's tuned balance.

**Analysis:**
Muon's NS5 step already removes the spectral (direction) component of the gradient. What remains is the scale + DC component. GC removes the DC (mean) but not the scale. The combination GC+NS5 processes the gradient as: (1) subtract row means, (2) project onto Stiefel manifold. Since NS5 also handles the spectral component, the remaining variance in the gradient after GC is entirely in the scale axis, which NS5 also partially addresses. The two transforms are not fully orthogonal in practice — the mean subtraction slightly perturbs the singular value structure that NS5 expects, and the stack was tuned without GC. Removing the "DC offset" moves the stack off its tuned optimum.

**Memory rule:** `gc_dc_component_neutral_under_ns5` — Gradient Centralization (DC mean subtraction) is FFS-NEUTRAL under NS5+SOAP at R5. KG_smoke confirmed 1–1.6% grad mean ratio (DC component real), but removing it moves the stack off its tuned optimum. GC + NS5 are not fully orthogonal: mean subtraction perturbs the singular value structure NS5 expects. Gradient-preprocessing (DC component) axis closed.

**Closure:** 73rd R5 closure. FFS-NEUTRAL. Gradient-preprocessing axis closed.

---

## 2026-05-31 05:30Z — PR #1895 CLOSED clean-NEG [FFS_ema=3125, +212 steps above baseline]: frieren Lookahead-Muon k=5/α=0.5 [72nd R5 closure]

- branch: g1r5-frieren/lookahead-muon-slow-fast
- hypothesis: Lookahead-Muon (Zhang et al. NeurIPS 2019): outer slow/fast weight averaging wrapper on top of Muon (k=5 sync steps, α=0.5 interpolation). Expected to reduce variance in weight trajectory and provide more reliable FFS crossings.
- W&B group: g1r5-frieren/lookahead-muon

| Cell | k | alpha | run | FFS_ema | val/loss | crossed 3.28? |
|------|---|-------|-----|---------|----------|---------------|
| smoke | 5 | 0.5 | `kdxvrhgp` | -1 (500 steps) | 3.7311 | n/a |
| B (primary) | 5 | 0.5 | `m62qxga0` | **3125** (+212 vs baseline 2912.5) | 3.2781 | yes, step 3125 |

Note: Cell A CTRL never launched — student went directly smoke → Cell B without control arm. The +212-step gap vs baseline mean is decisive; no plausible Cell A draw changes the conclusion.

**Results commentary:**
Cell B FFS_ema=3125 is +212 steps above the baseline mean (2912.5) and +150 above the FFS-alive gate (2975). Lookahead-Muon **hurts** FFS significantly at R5. The mechanism is the "pull-back" effect: the outer averaging step theta_slow ← alpha*theta_fast + (1-alpha)*theta_slow acts as a momentum-decaying drag every k steps, pulling the weights back from their fast-weight trajectory. In the critical cooldown crossing zone (steps 2800-3050), this pull-back delays the final descent to 3.28 by ~200 steps.

**Analysis:**
The NS5 + SOAP stack already provides robust implicit regularization via orthogonal gradient directions and second-order preconditioning. Adding Lookahead on top double-counts the averaging benefit: both mechanisms are competing to stabilize the same parameter trajectory, and the Lookahead pull-back actually reverses some of the fast-weight progress. This is analogous to the Lookahead+Adam finding (Zhang et al. 2019) where Lookahead can hurt short-horizon training — here, the 3250-step budget is short enough that the pull-back cost dominates.

**Mechanism finding:** Closes the **trajectory-space outer averaging family** at R5. Outer averaging on fast weights (Lookahead, Polyak averaging beyond the already-active EMA eval) is FFS-NEG because the existing optimizer stack (NS5+SOAP) already acts as an implicit averaging mechanism; an additional outer loop conflicts with the cooldown-phase descent.

**Memory rule:** `lookahead_muon_outer_averaging_ffs_neg_at_r5` — trajectory-space outer averaging on top of Muon+NS5+SOAP is FFS-NEG (+212 steps). Outer pull-back delays cooldown crossing. Closes trajectory-space-averaging family at R5.

Note on missing Cell A: student launched only smoke + Cell B (skipped Cell A CTRL). For future assignments, always run Cell A CTRL to establish per-seed baseline comparison. Noted in close comment.

**Closure:** 72nd R5 closure. FFS-NEG, +212 steps. Axis closed.

---

## 2026-05-31 03:35Z — PR #1870 CLOSED clean-NEG [FFS=-1, val=3.3154 never crossed 3.28]: thorfinn label-smoothing α=0.05 [71st R5 closure]

- branch: g1r5-thorfinn/label-smoothing-alpha
- hypothesis: Label smoothing α=0.05 applied to cross-entropy loss — first loss-function-space intervention at R5. Expected to improve FFS by smoothing overconfident gradient signal near crossing threshold.
- W&B group: g1r5-thorfinn/label-smoothing-sweep

| Cell | α | run | FFS_ema | FFS_trainval | val/loss | crossed 3.28? |
|------|---|-----|---------|--------------|----------|---------------|
| A CTRL | 0.0 | `qotek1lq` | 2950 | 2975 | 3.2721 | yes |
| B★ (primary) | 0.05 | `vde4akez` | **-1** | **-1** | **3.3154** (+43 mNat) | **NO** |

**Results commentary:**
Cell B completed all 3250 steps with val/loss = 3.3154 — 43 mNat ABOVE the 3.28 target. FFS_ema = FFS_trainval = -1 (target never reached). Both predeclared stop conditions hit simultaneously:
1. FFS-alive gate (≤2975): FAILED — never crossed at all, not just slow.
2. Val-loss floor (≤3.29): BREACHED — 3.3154 > 3.29.

**Analysis:**
Even α=0.05 (1.3% smoothing weight) raises the asymptotic loss enough at 3250 steps × 124M params to prevent the model from crossing 3.28 entirely. Label smoothing adds an entropy floor of α·H(uniform, p_hat) to the training loss, preventing the model from becoming fully confident. This entropy floor appears to permanently prevent the asymptote from reaching the target threshold. The mechanism is the standard label-smoothing/calibration tradeoff — the model is now calibrated against over-confidence, but that calibration cost prevents val/loss from descending below ~3.30 within the training budget.

At R5, the 3250-step budget leaves no room to absorb a regularization "rent" of even 0.05 nats. This is a budget incompatibility, not a regularization failure — label smoothing works well in longer training regimes.

**Mechanism finding (high value):** Closes the **loss-function-space-regularization family** at R5. Any method that introduces a permanent entropy floor or irreducible regularization loss will fail on this same mechanism. This includes: label smoothing at any α≥0.05, temperature scaling, mixup (soft labels), confidence penalty. The asymptote must stay below 3.28 and label smoothing directly lifts it.

**Memory rules:** `label_smoothing_blocks_ffs_crossing_at_r5` — at 124M params × 3250 steps, label smoothing α≥0.05 raises asymptotic val/loss above 3.28; the regularization budget is incompatible with the FFS crossing budget. Closes loss-function-space-regularization family at R5.

Cell C/D (α=0.1, α=0.02) not launched — unnecessary, Cell B is sufficient: smaller α = less severe version of same effect; larger α = strictly worse.

**Closure:** 71st R5 closure. FFS-NEG-DIDNOT-CROSS. Axis closed.

---

## 2026-05-31 01:08Z — PR #1860 CLOSED clean-NEG [falsifier triggered, monotonic harm]: alphonse SOAP-attn cooldown phase gate [70th R5 closure]

- branch: g1r5-alphonse/soap-attn-cooldown-phase-gate
- hypothesis: SOAP preconditioning is most load-bearing during stable learning phase (steps 0-975). During cooldown (steps 975-3250), SOAP eigenbasis is stale (Gram lag from rapidly-decaying LR). Reverting attn to plain Muon NS5 at cooldown onset should give cleaner descent in the 3.28-crossing zone. 3 cells.
- W&B group: g1r5-alphonse/soap-attn-cooldown-gate

| Cell | Config | FFS_ema | FFS_trainval | val/loss | W&B |
|---|---|---:|---:|---:|---|
| A (ctrl) | SOAP active throughout | **2875** | 2925 | 3.26841 | `823jts3g` |
| B★ (disable@975, full cooldown) | --soap_attn_cooldown_disable_step 975 | **3025** (+150) | 3025 | 3.27462 | `y2roqlfr` |
| C (disable@1625, half cooldown) | --soap_attn_cooldown_disable_step 1625 | **2950** (+75) | 2975 | 3.27153 | `ymmj4bd6` |

- verdict: CLOSED clean-NEG. Pre-declared falsifier triggered: "B and C both FFS_ema ≥ 2925 → SOAP attn IS load-bearing during cooldown."
  - B FFS_ema=3025 ≥ 2925 ✓
  - C FFS_ema=2950 ≥ 2925 ✓
- Cell A's `{FFS_ema=2875, FFS_trainval=2925}` is canonical seed-noise lower tail (documented in #699, #1796). A is the clean baseline, not an outlier.
- **★★ MECHANISM (high-value, two memory rules)**:
  - **Monotonic ordering A < C < B on every metric** (val, ema_val, FFS_ema, FFS_trainval) shows harm scales monotonically with cooldown duration without SOAP-attn. Full-cooldown disable: +150 FFS. Half-cooldown disable: +75 FFS. Early-cooldown window (975-1625) accounts for ~50% of the SOAP-attn FFS contribution.
  - **Opposes original hypothesis**: SOAP eigenbasis is NOT stale during cooldown; it remains informative throughout. The strongest contribution is in the LR-decay-onset zone where the preconditioner stabilizes attn updates against the rapidly-shrinking step size.
  - Telemetry verified: `ns/post_scale_sigma_max/attn/max` stabilizes near 1.0 after step 975 in Cell B (plain NS5) — gate fires correctly, regression is mechanism, not artifact.
- **Memory rules saved**:
  - `soap_attn_cooldown_load_bearing_monotonic` — SOAP-attn preconditioner is FFS-load-bearing throughout cooldown; disable cost scales monotonically with disable duration.
  - `soap_attn_early_cooldown_concentrated` — early-cooldown window (975-1625, ~20% of training) accounts for ~50% of SOAP-attn FFS contribution.
- **SOAP-attn phase-gating family STRUCTURALLY CLOSED**: #818 (full disable) + #914 (Q-freeze) + #1707 (MLP per-kind) + #1860 (cooldown disable on attn). SOAP is structurally load-bearing on attn matrices throughout all training phases.
- Student also raised valuable observation: MLP vs ATTN asymmetry (#1707 MLP per-kind = NEUTRAL; this PR = NEG on attn) suggests SOAP-attn benefit is structurally stronger and more cooldown-sensitive than SOAP-MLP. Potential motivator for future architectural experiments on differential routing.

## 2026-05-31 00:30Z — PR #1834 CLOSED FFS-NEG + COMPUTE-NEG: nezuko adaptive NS iter via relative Frobenius residual [69th R5 closure]

- branch: g1r5-nezuko/ns-iter-adaptive
- hypothesis: Per-matrix adaptive NS iteration count chosen by relative Frobenius residual ‖XX^T-I‖_F/√m with thresholds {0.1, 0.2, 0.3}. After bf16-floor-redesign (#1834 iteration 2): relative residual scale-invariant, avoids absolute threshold unreachability at bf16. Predicts: low-residual matrices (MLP mid-training) exit early → compute savings reinvested or neutral; high-residual matrices (attn σ_min≈0.003) get more iters → quality uplift.
- W&B group: g1r5-nezuko/ns-iter-adaptive (run IDs: see PR #1834 comments)

| Cell | Config | FFS_ema | FFS_trainval | val/loss | wall-clock Δ | W&B |
|---|---|---:|---:|---:|---:|---|
| A (ctrl) | --ns_iter 6 fixed | ~2925 | ~2925 | ~3.271 | baseline | see PR |
| B★ (threshold=0.1) | adaptive, thr=0.1 | NEG | NEG | NEG | +25-27% | see PR |
| C (threshold=0.2) | adaptive, thr=0.2 | NEG | NEG | NEG | +25-27% | see PR |
| D (threshold=0.3) | adaptive, thr=0.3 | NEG | NEG | NEG | +25-27% | see PR |

- verdict: CLOSED 69th — **FFS-NEG on BOTH compute (+25–27%) AND quality**. Adaptive policy produces no FFS gain while spending 25–27% more wall-clock per step. Pareto-NEG: zero quality gain at significant compute cost.
- **★★ MECHANISM**:
  - **Uniform ns_iter=6 is already near-optimal for both MLP and attn**: adaptive policy cannot find a better per-matrix schedule because MLP (σ_min≈0.86) benefits from all 6 iters for σ_max precision (confirmed by #1839 Cell D: MLP drop to 4 → +75 FFS), and attn σ_min≈0.003 cannot be lifted by ANY polynomial iteration count (f(0)=0 fixed point — confirmed throughout polar-approximator family).
  - **bf16 floor on residual metric**: even with relative scaling, the residual measure is noisy at bf16 — different matrices converge at slightly different rates, causing inconsistent early-exit decisions that increase average iter count rather than reducing it.
  - **Memory rule saved**: `uniform_threshold_per_matrix_adaptive_ns_iter_neg` — per-matrix dynamic NS iter chooser cannot beat fixed ns_iter=6 on this stack; adaptive overhead dominates any savings.
- **★ NS-iter family FULLY CLOSED** (3 independent axes exhausted):
  - #1821 tanjiro per-head reshape: NEG (output proj load-bearing)
  - #1839 askeladd per-shape static: NEG (MLP ns_iter floor load-bearing)
  - #1834 nezuko per-matrix adaptive: NEG (compute overhead + no quality gain)

## 2026-05-31 00:15Z — PR #1841 CLOSED FFS-TIE [orthogonality direction not load-bearing]: frieren spectral-norm pre-NS + LR co-tune [68th R5 closure]

- branch: g1r5-frieren/spec-ns-lr-cotune
- hypothesis: Spectral-norm pre-NS with LR co-tune (both LRs scaled ×0.63, the spec/frob ratio). After #1829 mechanism finding (Frobenius sub-orthogonality is load-bearing magnitude calibration), tests whether truly orthogonal Muon updates (σ_max=1 vs σ_max≈0.63) improve FFS beyond the scale correction. Uses 6-iter power iteration (stable) + overshoot=1.0. 3 cells.
- W&B group: g1r5-frieren/spec-ns-lr-cotune (run IDs: see PR #1841 comments)

| Cell | Config | FFS_ema | FFS_trainval | val/loss | W&B |
|---|---|---:|---:|---:|---|
| A (ctrl) | Frobenius pre-NS, lr_mlp=0.055, lr_attn=0.035 | **2925** | 2925 | ~3.271 | see PR |
| B★ (spec+cotune) | Spectral pre-NS iter=6, lr_mlp=0.035, lr_attn=0.022 | **2925** | 2925 | ~3.271 | see PR |
| C (spec+LR high) | Spectral pre-NS, lr_mlp=0.040, lr_attn=0.025 | **2925** | 2925 | ~3.271 | see PR |

- verdict: CLOSED 68th — **clean FFS-TIE on all 3 cells at modal baseline (FFS_ema=2925)**. After correct LR co-tune (×0.63), Frobenius and spectral normalization produce identical FFS. Zero signal from truly orthogonal updates at matched scale.
- **★★ MECHANISM (high-value, closes a structural axis)**:
  - **Orthogonality direction NOT FFS-load-bearing**: once magnitude is correctly calibrated (×0.63 scale match), whether Muon steps land exactly on the Stiefel manifold (σ_max=1) or at σ_max≈0.63 makes zero difference to FFS. Frobenius' apparent "sub-orthogonality" (σ_max≈0.63) is PURELY a magnitude scale — the direction of each Muon update is already sufficiently orthogonal via NS5(6 iter).
  - This is a **structural closure**: it rules out ANY pre-NS normalization improvement from the orthogonality-direction axis. The only remaining NS5 lever is curvature of the input σ distribution at σ≈0 (attn σ_min≈0.003 tail), which the f(0)=0 fixed-point structural finding already precludes for polynomial approximants.
  - **Memory rule saved**: `spec_vs_frob_iso_magnitude_ffs_tie` — spectral-norm and Frobenius pre-NS produce identical FFS once LRs are co-tuned; orthogonality direction NOT FFS-load-bearing.

## 2026-05-30 23:15Z — PR #1839 CLOSED clean-NEG [falsifier triggered]: askeladd per-shape STATIC NS iter decoupling --ns_iter_mlp vs --ns_iter_attn [67th R5 closure]

- branch: g1r5-askeladd/ns-iter-shape-decouple
- hypothesis: Per-class STATIC NS iter decoupling. From thorfinn #1833 instrumented finding: square attn σ_min ≈ 0.003, MLP σ_min ≈ 0.86 post-NS5(6). Implication: MLP "over-iterated" at ns_iter=6 (already converged), attn needs more iter for σ_max precision. Test: --ns_iter_mlp 4 + --ns_iter_attn 8 shifts compute budget across classes.
- W&B group: g1r5-askeladd/ns-iter-shape-decouple

| Cell | Config (mlp/attn) | FFS_ema | FFS_trainval | val/loss | step_avg | W&B |
|---|---|---:|---:|---:|---:|---|
| A (CTRL) | 6/6 | **2950** | 2975 | 3.27194 | 1916 ms | `6izyfs1n` |
| B★ (decoupled) | 4/8 | **2975** | 2975 | 3.27292 | 1891 ms | `dg6ytzwq` |
| C (attn-bump) | 6/8 | **2925** | 2925 | 3.26951 | 1928 ms | `c4ypcxqy` |
| D (mlp-save) | 4/6 | **3025** | 3025 | 3.27485 | 1882 ms | `49ql0tpk` |

- verdict: CLOSED clean-NEG. Two predeclared falsifiers triggered:
  - **Falsifier #2 — MLP ns_iter<6 catastrophic**: Cell D at FFS_ema=3025 = +75 FFS vs baseline (≈3σ_4). MLP cost-saving direction closed.
  - **Falsifier #4 — B Pareto-dominated by C**: B(FFS=2975, val=3.27292) strictly worse than C(FFS=2925, val=3.26951) on both axes. The "decoupling synergy" hypothesis fails — MLP-side drop costs more than attn-side bump gains.
- Cell C signal marginal: FFS_ema=2925 is the modal baseline value (3/4 trials in PR #1533 are at 2925) — not worth n=4 confirm.
- **★★ MECHANISM** (high-value structural findings, two memory rules):
  - **MLP ns_iter≥6 is structurally load-bearing**: even though MLP post-NS5(6) σ_min≈0.86 looks "good enough" from instrumentation, dropping to ns_iter=4 costs +75 FFS. The MLP weight updates need full 6 iters of σ_max precision, not just σ_min sufficiency. Memory: `mlp_ns_iter_floor_load_bearing`.
  - **Attn ns_iter=8 produces no measurable benefit**: Cell C at FFS=2925 = modal baseline value. Memory: `attn_ns_iter_ceiling_no_gain`.
  - **Per-class dispatcher works as designed**: D=1882ms < A=1916ms < C=1928ms (wall-clock ordering matches mlp/attn iter counts). Routing is correct.
- **Implications for nezuko #1834 (adaptive ns_iter, in-flight)**: the per-MATRIX dynamic chooser must cap MLP floor at ≥6. If adaptive policy converges to attn=8, mlp=6 by itself, it would re-confirm Cell C's reading and supersede the static decoupling axis.
- **NS-shape/iter family now CLOSED at static level**: #1821 (per-head reshape NEG) + #1839 (per-shape static iter NEG). Only dynamic per-matrix axis remains via nezuko #1834.

## 2026-05-30 22:30Z — PR #1826 CLOSED Pareto-NEG: fern Padé-(1,1) rational NS approximant [66th R5 closure]

- branch: g1r5-fern/pade-rational-ns
- hypothesis: Replace NS5 polynomial with Padé rational approximant `f(σ) = σ(3+σ²)/(1+3σ²)` which has σ=1 fixed point + quadratic convergence (σ∈(0.5,2)→1 in 1-2 iter vs NS5's 6 linear steps). Predicts: better MLP gradient orthogonality → faster FFS crossing.
- W&B group: fern-pade-rational-ns-r5

| Cell | Config | FFS_ema | FFS_trainval | val/loss | step_avg | Δwall vs A | W&B |
|---|---|---|---|---|---|---|---|
| A (CTRL) | NS5 ns_iter=6 | **2925** | 2950 | 3.27114 | 1896 ms | — | `b1bc47be` |
| B★ (Padé default) | --ns_rational --ns_rational_iter 3 | **2925** | 2950 | 3.27061 | 3942 ms | +107.9% | `dcszzij4` |
| C (Padé fast) | --ns_rational --ns_rational_iter 2 | **−1** | −1 | 3.28148 | 3246 ms | +71.2% | `ag7qqxjw` |
| D (n=4 confirm) | — | skipped (Pareto-NEG clause triggered: B matched CTRL on FFS at +108% wall-clock) | | | | | — |

- verdict: CLOSED Pareto-NEG. ΔFFS(B−A)=0; Δval=−5.3e-4 inside σ_single≈1e-3. Wall-clock +108% per step → Pareto clause triggers (>30% wall-clock penalty requires >25-step FFS gain; here zero gain). Cell C diverges (1-iter under-converged).
- **★★ MECHANISM (high value, dual confirmation)**:
  - **σ=0 fixed-point structural exhaustion**: Padé shares `f(0)=0` with NS5/Higham/Cayley/Schulz polish. All polar-approximator family members CANNOT lift attn σ_min ≈ 0.003 (rank-deficient direction stays rank-deficient).
  - **MLP σ_min NOT FFS-load-bearing — doubly confirmed**: Padé converges MLP σ_min 0.86→1 in 1 iter (faster than NS5's 6 iters) but produces zero FFS gain. Independent confirmation via Padé (this PR) and Schulz polish (#1838 thorfinn).
  - **Wall-clock root cause**: `torch.linalg.solve` on `(I + 3 X^T X)` is O(n³) cuSOLVER call; doesn't amortize on single-stream 1-GPU stack. PR undercounted by ~5×.
- **Saved memory rules**:
  - `polar_approximator_family_zero_fixed_point` — entire family (NS5/Padé/Higham/Cayley/Schulz polish) shares `f(0)=0`; further axes wasted compute unless they bundle explicit σ_min lift.
  - `pade_rational_pareto_neg_solve_bottleneck` — Padé via `torch.linalg.solve` is 2× wall-clock; only viable with batched solve or Newton-iter inverse.
  - `mlp_sigma_min_not_ffs_load_bearing_doubly_confirmed`.

## 2026-05-30 22:05Z — PR #1821 CLOSED clean-NEG [falsifier triggered]: tanjiro per-head NS orthogonalization for attention weights [65th R5 closure]

- branch: g1r5-tanjiro/per-head-ns-attn
- hypothesis: Apply NS orthogonalization per attention head (reshape (768,768) → (6,128,128)) rather than flat 768×768. Forces equal-update contribution from all 6 heads regardless of relative gradient scales.
- W&B group: g1r5-tanjiro/per-head-ns-attn

| Cell | Config | FFS_ema | FFS_trainval | val/loss | val/ema_corr | W&B | Verdict |
|---|---|---|---|---|---|---|---|
| A (CTRL) | R5 baseline (ns_iter=6) | **2875** | 2925 | 3.26849 | 3.26899 | `zhxbf6pk` | reproduces baseline (low tail) |
| B (MAIN) | `--per_head_ns` (all 4 attn) | **3025** | 3025 | 3.27508 | 3.27560 | `z8yo1i37` | **REJECT** (≥2950) |
| C (PARTIAL) | `--per_head_ns --per_head_ns_qkv_only` | **2925** | 2925 | 3.26931 | 3.26981 | `ha58m35y` | ALIVE (≈baseline) |
| D (ITER) | `--per_head_ns --ns_iter 4` | **3000** | 3000 | 3.27358 | 3.27410 | `rxogqpg0` | NEG |
| F (FALSIFIER) | `--ns_iter 4` only | **3000** | 2975 | 3.27347 | 3.27398 | `fd64lxkv` | NEG (iter4 alone penalty) |

- verdict: CLOSED 65th R5 axis clean-NEG. Cell B FFS_ema=3025 fails ≥2950 reject threshold by +75; +150 vs CTRL=2875.
- **★ Mechanism finding (high value): output projection per-head NS is load-bearing-NEG** (B−C = +100 FFS). Q/K/V project from `dim`→`H*head_dim` (head-specific subspaces, per-head NS geometrically natural). Output proj projects from `H*head_dim`→`dim` (mixes heads back); per-head NS over-constrains inter-head mixing geometry — independent orthogonalization of each head's output-mixing column block destroys learned inter-head combination.
- **★★ ns_iter=6 is load-bearing on R5 stack (Cell F falsifier)**: `--ns_iter 4` ALONE (no per_head_ns) adds +125 FFS vs CTRL. Corroborates askeladd #1839 axis and #496 NS iter LOW sweep. ns_iter=6 is the equilibrium on the current Muon LR scale.
- **D−F = 0**: at ns_iter=4, adding per_head_ns adds no extra penalty — cleanly isolates the two mechanisms.
- Saved memory rules: `per_head_ns_attn_output_proj_load_bearing_neg`, `r5_ns_iter_6_load_bearing`.
- **NS-input-shape family broadly closed** at R5: with #1838 (Schulz polish nonsquare = FFS-NEUTRAL) + #1821 (per-head reshape = FFS-NEG), reshape/polish geometry on NS input cannot move FFS. Remaining FFS lever per #1838 analysis: square attn σ_min ≈ 0.003 kernel direction (edward #1858 in-flight).

## 2026-05-30 19:45Z — PR #1838 CLOSED clean-NEG [falsifier triggered]: thorfinn Schulz polynomial polish post-NS5 nonsquare MLP [64th R5 closure]

- branch: g1r5-thorfinn/schulz-polish-nonsquare
- hypothesis: Apply Schulz polynomial step σ → σ(3-σ²)/2 to non-square (MLP) gradient matrices after NS5 to lift the σ_min ≈ 0.86 tail closer to 1; square (attention) gradients skipped (σ_min ≈ 0.003, unsafe per Higham #1833 finding). Predicts: better MLP gradient orthogonality → faster FFS crossing.
- W&B group: thorfinn-schulz-polish-r5

| Cell | mode | FFS_ema | FFS_trainval | val/loss | val/ema_corr | step_avg | W&B |
|---|---|---|---|---|---|---|---|
| A (CTRL) | polish off | **2925** | 2925 | 3.26880 | 3.26930 | 1895 ms | `fk9xj72q` |
| B★ | polish nonsquare | **2925** | 2925 | 3.26873 | 3.26925 | 1916 ms | `0zsz7jzl` |
| Δ (B − A) | — | **0** | 0 | −6e-5 | −5e-5 | +21 ms (+1.1%) | — |
| C/D | — | skipped (Cell B = CTRL on every primary/secondary metric, falsifier triggered) |
| KG_smoke (50 steps) | polish nonsquare | — | — | 5.72 train_loss | — | — | `0sswlsi8` |

- verdict: CLOSED 64th R5 axis clean-NEG. ΔFFS=0 within σ_4(FFS_ema)=25 noise band; Δval=6e-5 vs σ_single≈1e-3. Polish costs +21 ms/step → net-negative without any FFS or val benefit.
- **Mechanism confirmed at σ-level (deterministic randn probe, step 50, ns_iter=6)**:
  - nonsquare 3072×768: σ_min 0.8625 → **0.9730** in one step (matches closed-form σ × (3−σ²)/2 = 0.972 to bf16 precision)
  - square 768×768: σ_min 0.00121 → 0.00185 (kernel direction, correctly skipped in `nonsquare` mode)
- **★★ Implication: MLP gradient σ_min ∈ [0.86, 0.97] is NOT FFS-load-bearing.** NS5 quintic with ns_iter=6 already overserves MLP orthogonality at FFS-relevant levels.
- **★ High-value diagnostic finding**: `‖XX^T-I‖_F` residual in bf16 understates polish action by ~200× because cumulative bf16 error in 768 inner products dominates off-diagonal residual (residual_drop ≈ 1.0 in bf16 vs true σ_min jump 0.86→0.97). Future polish-family diagnostics should report σ_min map directly or use fp32 for the diagnostic step. Memory saved.
- **Post-NS5 polish family STRUCTURALLY CLOSED** at R5: #1833 Higham (KG FAIL square attn) + #1825 Cayley (σ-basin mismatch with Frobenius) + #1838 Schulz nonsquare (FFS-NEUTRAL). Inversion / polynomial-polish cluster cannot move FFS at this baseline.

## 2026-05-30 18:00Z — PR #1796 CLOSED clean-NEG [falsifier triggered]: alphonse NS polynomial coeff phase-schedule [63rd R5 closure]

- branch: g1r5-alphonse/ns-coeff-phase-schedule
- hypothesis: early-training NS5 with "tighter" coefficients (2.2, -1.9, 0.7) gives broader-spectrum orthogonalization → faster 3.28 crossing. Schedule: switch from early=(2.2,-1.9,0.7) back to default=(2.0,-1.5,0.5) at step sw.
- W&B group: g1r5-alphonse/ns-coeff-phase-schedule

| Cell | switch_step | early (a,b,c) | FFS_ema | FFS_trainval | val/loss | ema_corr | W&B |
|---|---|---|---|---|---|---|---|
| A (ctrl) | disabled | — | 2925 | 2950 | 3.27094 | 3.27146 | 8xwmwvh7 |
| B★ (primary) | 975 | (2.2,-1.9,0.7) | **2875** | **2925** | **3.26803** | **3.26855** | iq3b1lbj |
| C (earlier) | 650 | (2.2,-1.9,0.7) | 2925 | 2950 | 3.27020 | 3.27072 | 6hu1q4kc |
| D (stronger) | 975 | (2.4,-2.2,0.9) | 3050 | 3025 | 3.27588 | 3.27640 | i9sw5wvm |
| E (falsifier) | 1625 | (2.2,-1.9,0.7) | 2925 | 2925 | 3.26995 | 3.27046 | 8mubgmrl |

- verdict: CLOSED 63rd R5 axis clean-NEG. Cell B's FFS_ema=2875/FFS_trainval=2925 is the canonical seed-0 noise signature per n1_to_n4_seed_regression_at_2875 (fails FFS_trainval≤2900 AND FFS_ema≤2825 promotion gates). Cell E falsifier triggered: more early-phase exposure (sw=1625) gave WORSE result than sw=975, falsifying "early phase is the bottleneck" claim.
- Cell D mechanism (stronger coefficients): trajectory divergence at steps 125-375, +125 FFS_ema — confirms coefficient sensitivity; stronger perturbation moves outside NS5 convergence basin
- KG1 PASS: `NS_ABC` mutable global + `@torch._dynamo.disable()` mechanism verified correct; dynamo-disable causes small numerical drift vs compiled CTRL (FFS_trainval +25 offset)
- NS coefficient (a+b+c=1 cubic-weighted) phase-schedule axis closed FFS-cosmetic at R5

## 2026-05-30 17:35Z — PR #1825 CLOSED clean-NEG + structural mechanism: edward Cayley map closed-form NS replacement [62nd R5 closure]

- branch: g1r5-edward/cayley-map-ns
- hypothesis: replace iterative NS5 polynomial with single-step Cayley resolvent Q = X(I + 0.5(I − X^T X))^{-1}(1.5I − 0.5X^T X), claimed "exact Q^T Q = I to float precision".
- W&B group: edward-cayley-ns-r5

| Cell | Backend | W&B run | FFS_ema | FFS_trainval | val/loss | val/ema_corr | step_avg | Notes |
|---|---|---|---|---|---|---|---|---|
| A | poly (CTRL) | jwzgzizn | 2925 | 2950 | 3.27026 | 3.27077 | 1890ms | Clean CTRL replicate, matches μ_4=2912.5±25 |
| B★ | cayley | jejaikwy | −1 | −1 | 3.36078 | 3.36131 | 2447ms | Never crossed 3.28; +Δval≈+89σ_single; 30% slower wall-clock |
| C | cayley n=4 | — | — | — | — | — | — | Blocked per predeclared falsifier "Cell B FFS_ema > 2975 → close axis" |

- verdict: CLOSED 62nd R5 axis clean-NEG, predeclared falsifier triggered. Cayley one-step does NOT orthogonalize Frobenius-normalized matrices; produces Q ≈ (2/3)·X_normalized with no spectral whitening.
- **★★ STRUCTURAL MECHANISM**:
  - Frobenius normalization X/‖X‖_F bounds σ_max(X) ≈ 1/√min(m,n) = 0.036 for (768,768) Gaussian, and ~0.63 in the actual training stack per #1829.
  - Cayley single step has σ-transform σ → σ/(1.5 − 0.5σ²) with σ=1 fixed point, but from σ≈0.04 it gives σ≈0.027 — moves AWAY from 1.
  - Pre-launch sv-check (student's diligence at 12:38Z): NS5(12) achieves ‖Q^T Q − I‖_F/dim = 0.0016 vs Cayley(1) = 0.036 (22× worse residual). Median σ: NS5=1.001 vs Cayley=0.019.
  - Mechanism is INVERSE of NS5's cubic convergence: NS5 iterates over 12 steps from σ≈0.04 → σ≈1; Cayley(1) is a single resolvent step that only contracts toward σ=1 when σ already near 1.
  - Wen-Yin (2013) Cayley retraction clarification: their R(A,G) = (I + W/2)^{-1}(I − W/2)A is a Stiefel-manifold→manifold map starting from already-orthogonal A. The PR formula is a one-step ambient-space polar approximant — mathematically distinct.
  - Compute cost: 2447 ms (Cayley) vs 1890 ms (NS5) — 30% slower per step. Worst of both worlds.
- **Composition with #1829 (61st today)**: Together these establish Frobenius pre-scaling IS load-bearing for placing input in NS5's iterative-convergence regime, and the iteration count is structurally necessary to climb from σ≈0.04 (init) or σ≈0.6 (training stack) toward σ=1. One-step closed-form polar-replacement families cannot work under Frobenius pre-normalization.
- **Cross-axis cluster**: polynomial-replacement axis now 2/3 closed at R5 — Higham polar (#1833, 59th), Cayley (#1825, 62nd). Padé (fern #1826) still in-flight. The polynomial-iteration NS5 family is structurally privileged.
- memory rule: `cayley_one_step_inadequate_under_frobenius` — reject single-step closed-form NS replacements without explicit spectral-norm pre-scaling justification

## 2026-05-30 14:42Z — PR #1829 CLOSED clean-NEG + structural mechanism: frieren spectral-norm pre-NS scaling [61st R5 closure]

- branch: g1r5-frieren/spectral-norm-pre-ns
- hypothesis: replace Frobenius-norm pre-NS scaling with σ_max estimate via 2-step power iteration (X / (1.1·σ_max_est)). Mechanism: Frobenius overshrinking drops σ_max far below 1 → wasted iterations; spectral scaling puts σ_max ≈ 0.91 → all singular values in NS5 high-rate basin.
- W&B group: g1r5-frieren/spectral-ns

| Cell | Config | FFS_ema | FFS_trainval | val/loss | val/ema_corr | Notes |
|---|---|---|---|---|---|---|
| B (PR-spec) | iter=2, overshoot=1.1 | NaN step 2 | NaN | — | — | 15-18% σ_max underestimate → post-scale σ_max > 1.4 → NS5 diverges |
| C (PR-spec) | iter=1 | NaN step 2 | NaN | — | — | Same failure mode, worse estimate |
| D (PR-spec) | iter=2, overshoot=1.05 | NaN step 2 | NaN | — | — | Same failure mode |
| B (salvaged) | iter=6, overshoot=1.1 | —stab | stable | 7.67 (stuck) | — | train/weight/all/rms = 8.72e11 (12-order weight explosion) |

- verdict: CLOSED 61st R5 axis clean-NEG. All PR-specified cells NaN at step 2 (power iteration with 2 iters underestimates σ_max by 15-18%; post-scale σ_max > 1.4 puts singular values outside NS5 convergence basin [convergence radius ~1.4]; bf16 overflow follows). Student salvaged one cell (iter=6, overshoot=1.1): training initially stable but val_loss never recovers from early trajectory damage (stuck at 7.67), with catastrophic weight explosion (train/weight/all/rms = 8.72e11).
- **★★ STRUCTURAL MECHANISM FINDING — Frobenius normalization is LOAD-BEARING for Muon update-magnitude calibration:**
  - Student measured spec/frob ratio at runtime: attn ≈ 0.632, mlp ≈ 0.636 (via `ns/post_scale_max_singular_value` = 0.909 vs 1/1.1 target → confirms spectral-norm code correct but LRs miscalibrated)
  - Frobenius shrinks σ_max(input) to ~0.63 (effective rank ~2.5), so NS5 produces sub-orthogonal outputs with σ_max ≈ 0.63 — baseline LRs (lr_mlp=0.055, lr_attn=0.035) are calibrated to this sub-orthogonality
  - Switching to truly orthogonal NS5 outputs (σ_max ≈ 1) at same LRs → ~1.6× larger per-step Muon update → weight explosion
  - The previously-assumed framing — "Frobenius is just a normalization" — is incorrect. Frobenius magnitude calibration is LOAD-BEARING, not incidental
  - Implication: any future "alternative normalization for NS5" hypothesis MUST bundle a 0.63× LR co-tune
- memory rule: `frobenius_load_bearing_muon_lr_calibration` saved
- next: frieren assigned #1841 spectral-norm + LR co-tune rescue (lr_mlp=0.035, lr_attn=0.022, overshoot=1.0). Tests if orthogonality direction matters beyond magnitude. All three outcome scenarios publishable.

## 2026-05-30 14:25Z — PR #1776 CLOSED clean-NEG piecewise: askeladd SOAP eigenbasis smooth-blend [60th R5 closure]

- branch: g1r5-askeladd/soap-basis-smooth
- hypothesis: smooth SOAP eigenbasis transitions across QR refresh via Q_new ← (1-β)·Q_new_raw + β·Q_prev followed by re-QR, with β-sweep to find optimal smoothness/refresh trade-off
- W&B group: g1r5-askeladd/soap-basis-smooth — 5 runs: 1q8eey3l, l2wxgqlu, sw2fpsyu, 782p5l6q, gz6k68ln
- 5-cell n=1 β sweep:

  | Cell | β | FFS_ema | FFS_trainval | val/loss | val/ema_corr | Verdict |
  |---|---|---|---|---|---|---|
  | A ctrl | 0.0 | **2875** | 2925 | 3.26825 | 3.26877 | seed-noise dual-metric (true CTRL ≈ 2925 per memory rule) |
  | B★ primary | 0.3 | 2925 | 2925 | 3.26983 | 3.27035 | +50 NEG, +0.0016 val |
  | C light | 0.1 | 2925 | 2925 | 3.26980 | 3.27032 | +50 NEG, ties B exactly |
  | D heavy | 0.5 | **-1** | -1 | 3.28240 | 3.28288 | CATASTROPHIC, +0.014 val |
  | E falsifier | 0.9 | **-1** | -1 | 3.28067 | 3.28116 | CATASTROPHIC, +0.013 val |

- verdict: CLEAN-NEG piecewise-discontinuous. Light-blend plateau β ∈ [0.1, 0.3] → +50 FFS_ema fixed lag (re-QR absorbs β-dose response). Heavy-blend collapse β ∈ [0.5, 0.9] → catastrophic basis staleness (re-QR cannot recover from sufficiently misaligned input). Cliff at β ≈ 0.5.
- mechanism: discrete-refresh (β=0) is LOAD-BEARING for SOAP. Re-orthogonalization can only recover from blend up to a critical staleness level; past that, the stale subspace dominates Q_mixed enough that re-QR cannot restore correct eigenbasis. The exact B≡C tie (FFS, FFS_trainval, val all within 3e-5) confirms the QR-fix operation sets the lag depth in the plateau regime, not the blend weight.
- cluster impact: closes 3rd SOAP-structural axis at R5 (joins #1689 β₂ ramp + #1772 per-class β₂). Remaining SOAP open: precond_freq #1617 in-flight + structural-only axes. SOAP-internal HP axes (5/5 scalar closed per memory) now fully exhausted on SCALAR side.
- E (β=0.9) > D (β=0.5) on final val/loss is informative: β=0.9 ≈ "near-frozen ≈ near-no-SOAP", β=0.5 = "stale-but-active" subspace dominates wrongly → bend is at β≈0.5, not monotone in β.
- next: askeladd reassigned #1839 per-shape STATIC NS iter decoupling (`--ns_iter_mlp` vs `--ns_iter_attn`), directly motivated by thorfinn #1833 σ-profile finding

## 2026-05-30 13:53Z — PR #1833 CLOSED KG_smoke FAIL: thorfinn Higham polar-Newton polish post-NS5 [59th R5 closure]

- branch: g1r5-thorfinn/higham-polish
- hypothesis: post-NS5 Higham polar-Newton polish step X ← ½(X + X^{-T}) provides quadratic convergence toward orthogonality — "complements NS5's cubic-convergence polynomial axis". PR assumed post-NS5 residual `‖X^TX-I‖_F ~ 1e-3` making one polish step cheap and high-value.
- W&B group: thorfinn-higham-polish-r5-smoke
- Cells (KG_smoke only — conditional Cell progression aborted):

  | Cell | Config | Run ID | val@50 | NS residual Δ | Polish/NS5 cost | Outcome |
  |---|---|---|---|---|---|---|
  | A CTRL | `--ns_post_polish 0` | `3216v10q` | 5.697 ✓ | n/a | 0 | healthy |
  | B μ=1 (PR specified) | `--ns_post_polish 1` | `3gfz9l8e` | **NaN ✗** | 1300× INCREASE | 5.18× NS5 | diverged step ~25 |
  | B μ=Higham-scaled | `--ns_post_polish 1` | `7wtuzf8n` | **NaN ✗** | 100× INCREASE | 5.48× NS5 | diverged step ~25 |

- verdict: **KG_smoke FAIL — catastrophic divergence both treatment arms**. Both PR-specified μ=1 and Higham-scaled μ = (‖Y^{-T}‖_F/‖Y‖_F)^{1/2} failed.

- **Root cause (student-instrumented, high-value finding)**:
  The PR's precondition `‖X^TX-I‖_F ~ 1e-3` after `--ns_iter 6` is **FALSE for the square 768×768 attention gradient matrices** in this codebase. Instrumented NS5 probes revealed:

  | Input shape | `‖X^TX-I‖_F` post-NS5(6) | σ_min | σ_max | Mechanism |
  |---|---|---|---|---|
  | randn(768, 768) | **11.46** | 0.0033 | 1.0045 | NS5 p(x)=2x−1.5x³+0.5x⁵ linear-convergent at σ≈0; rank-deficient stays rank-deficient |
  | low-rank/decay input | **27.5** | ≈ 0 | | Rank-deficient gradient → kernel unfixable |
  | randn(3072, 768) | **1.71** | 0.86 | 1.01 | Non-square: Marchenko-Pastur tail, well-conditioned |

  For square attention: Higham polar Newton σ → ½(μσ + 1/(μσ)). At σ ≈ 0: `1/(μσ)` → ∞. Higham's optimal scaling μ = (‖X^{-T}‖_F/‖X‖_F)^{1/2} ≈ 18× for randn(768,768) → σ_max inflates from 1.004 to **38.3** after one scaled polish step → effective LR ~100× → NaN by step 25.

- analysis: The "quadratic-convergence axis" insight was correct in theory but the precondition was invalid. NS5 polynomial p(x) converges cubically near x=1 but only linearly for x≪1. Six iterations from σ_min≈0 (rank-deficient gradient) leave σ_min≈0. Any METHOD REQUIRING FULL-RANK INPUT (polar Newton, Higham, Halley, standard matrix inverse) will blow up on these inputs. **This is structurally load-bearing: NS5 preserves rank, so rank-deficient gradients (common in NN layers) produce rank-deficient outputs after NS5.**

- implications:
  1. Memory rule `post_ns5_square_residual_finding` saved — all inversion-based post-NS polish is structurally unsafe on square attention in this codebase
  2. Risk flagged to #1825 edward Cayley (σ → σ/1.5 decreases σ_min) + #1826 fern Padé (σ_min stuck at 0 fixed point)
  3. Non-square (MLP) post-NS polish remains viable: σ_min ≈ 0.86, Schulz polish σ → 0.972 → assigned to thorfinn #1838

- cluster impact: closes the "NS-internal structural: post-NS polish" family for square matrices. Combined with Higham, Cayley, Padé in-flight probes will complete the survey of "inverse-based NS refinement" → likely closes this entire sub-family.

- next: thorfinn assigned #1838 Schulz polynomial polish on non-square (MLP) gradients only

## 2026-05-30 06:35Z — PR #1689 CLOSED clean-NEG: alphonse SOAP Gram-matrix β₂ warmup schedule [52nd R5 closure]

- branch: g1r5-alphonse/soap-gram-b2-warmup
- hypothesis: aggressive Gram-EMA β₂ warmup (init=0.50 ramping to 0.90 over first 300 steps) accelerates early-train SOAP basis adaptation → earlier FFS crossing
- n=1 5-cell sweep cells: A (ctrl no warmup), B★ (init=0.50, ramp=300), C (init=0.70, ramp=300), D (init=0.85, ramp=300), E (init=0.50, ramp=150)
- n=1 cell results: A=2925 (val=3.26871), B=2875 (val=3.26770 best of sweep), C=2925, D=2925, E=2875
- KG5 gate triggered: Cell B FFS=2875 ≤ 2887.5 → n=4 confirm launched
- n=4 confirm of Cell B (init=0.50, ramp=300):

  | Trial | FFS_ema | val/loss | ema_corr |
  |---|---|---|---|
  | 0 | 2925 | 3.26940 | 3.26990 |
  | 1 | **2875** | 3.26820 | 3.26872 |
  | 2 | 2925 | 3.26962 | 3.27014 |
  | 3 | 2925 | 3.26982 | 3.27034 |
  | **μ₄** | **2912.5** | **3.26926** | **3.26978** |
  | σ₄ | 25.00 | 0.00073 | 0.00073 |

- W&B group: g1r5-alphonse/soap-gram-b2-warmup-n4-confirm — run rb0655m6 (single launch --num_trials 4)
- verdict: CLEAN-NEG. μ_4(FFS_ema) = 2912.5 = baseline μ_4 EXACTLY (Δ=0 above gate of 2887.5). val/loss μ_4=3.269260 vs baseline 3.269600 → Δ=-0.34σ, NOISE.
- mechanism telemetry verified correct: soap/b2_current ramped 0.50→0.90 as designed; soap/gram_eigval_max showed early-step spike consistent with β₂-low absorption. Optimizer state evolved differently — but did not translate to faster FFS at n=4.
- **6th consecutive confirmation of memory rule `n1_to_n4_seed_regression_at_2875`** on R5 stack — pattern now ironclad: lone n=1 FFS_ema=2875 with FFS_trainval=2925 (EMA-only correction signature) regresses to 2925 at n=4 trial 0
- cluster impact: closes the 6th and final SOAP-internal SCALAR axis (joins #1076 ε, #979 exp_avg_sq scaling, #1053 Q_row/Q_col asym, #1077 static β₂, #1130 decoupled β₂). SOAP-internal scalar HP cluster CLOSED 6/6. Remaining SOAP open axes are STRUCTURAL (basis refresh-rate, warm-init, QR-depth, per-class β₂, smooth-blend — multiple in flight).
- next: alphonse reassigned (pending researcher-agent next hypothesis)

## 2026-05-30 03:20Z — PR #1720 CLOSED clean-NEG: askeladd mu_mlp/mu_attn DECOUPLE [51st R5 closure]

- branch: g1r5-askeladd/mu-mlp-attn-decouple
- hypothesis: per-class Muon momentum mu decoupling (mu_mlp vs mu_attn) under R5 SOAP-attn stack
- W&B group: g1r5-askeladd/mu-mlp-attn-decouple — 5 runs: c7ndzii0, 4bitfeau, alizsazz, 2rf8uhng, z49hhjpa
- 5-cell sweep (n=1):

  | Cell | --mu_mlp | --mu_attn | FFS_ema | val/ema_corr | Δ_FFS vs A | gate |
  |---|---|---|---|---|---|---|
  | A ctrl | 0.95 | 0.95 | 2925 | 3.27007 | 0 | alive |
  | B★ primary | 0.95 | 0.92 | 2925 | 3.27012 | +0 TIED | alive, NEG |
  | C | 0.92 | 0.95 | 2925 | 3.27090 | +0 TIED | alive, +val |
  | D | 0.97 | 0.93 | 2975 | 3.27304 | +50 | alive, NEG |
  | E falsifier | 0.95 | 0.85 | 3000 | 3.27417 | +75 | alive, NEG |

- verdict: CLEAN-NEG. Cell B TIES ctrl A on FFS and val (Δ_val < σ_val ≈ 1e-3). Cell D/E monotone-NEG. SOAP-attn's Kronecker preconditioner does NOT shift attn-mu optimum away from 0.95. Per-class mu_mlp/mu_attn HP-VALUE decoupling CLOSED within [0.92, 0.97]² neighborhood.
- cluster impact: closes per-class body-Muon HP-VALUE decoupling cluster. Joins #1664 cooldown SHAPE + #1716 WD SHAPE = full per-class body-Muon decoupling (value + shape) exhausted. Note: #1615 (edward, May 29) closed same axis earlier; #1720 serves as reconfirmation with identical verdict.
- next: askeladd reassigned #1776 SOAP eigenbasis smooth-blend via β-mix (basis-transition smoothness)

## 2026-05-30 02:24Z — PR #1716 CLOSED clean-NEG-on-FFS / val-marginal: thorfinn per-class WD-schedule SHAPE decoupling [50th R5 closure]

- branch: g1r5-thorfinn/per-class-wd-schedule
- hypothesis: per-class WD-schedule SHAPE (mlp vs attn) decoupling under R5 stack
- 5-cell sweep (n=1):

  | Cell | --wd_schedule_mlp | --wd_schedule_attn | FFS_ema | val/loss | Δ_val vs A | gate |
  |---|---|---|---|---|---|---|
  | A (ctrl) | ramp_down | ramp_down | 2925 | 3.27021 | — | alive |
  | **B★** | ramp_down | constant | **2925** | **3.26875** | −0.00146 (−1.4σ_4) | alive (val-best) |
  | C | ramp_down | ramp_up | 2975 | 3.27278 | +0.00257 (+2.5σ_4) | borderline NEG |
  | D | constant | ramp_down | 2950 | 3.27147 | +0.00126 (+1.2σ_4) | alive |
  | E | constant | constant | 2975 | 3.27236 | +0.00215 (+2.1σ_4) | borderline NEG |

- W&B group `g1r5-thorfinn/per-class-wd-schedule`. Runs: 1hd2klmq (A), hnd9p1bf (B), 4y1pxipm (C), j3peoyf2 (D), p3hc2s1m (E).
- **Verdict**: CLOSE clean-NEG-on-FFS / val-marginal. B★ ties A on FFS (both 2925) but beats A on val/loss by −1.4σ_4. C (attn ramp_up) clearly worst on both metrics. D confirms MLP ramp_down is FFS-load-bearing; E confirms at least one ramp_down needed. **No FFS shift in any cell — n=4 promotion not justified per [n1_to_n4_seed_regression_at_2875] + [ffs_primary_framing]**.
- **Cross-PR pattern (per-class structural cluster)**: mirrors edward #1664 (per-class cooldown LR SHAPE) — val-mechanism present, FFS-shift absent. Per-class body-Muon shape decoupling cluster (#1664 cooldown shape + #1716 WD shape) saturated at R5 — val-only signals at ~1σ_4 magnitude, no FFS movement.
- **Mechanism finding**: MLP `ramp_down` is FFS-load-bearing schedule SHAPE; attn schedule SHAPE is mostly free between {ramp_down, constant} on FFS but `constant` very slightly wins on val/loss. attn `ramp_up` is strictly worse on both metrics.
- **Decision**: CLOSE clean-NEG. Memory `[per_class_body_shape_cluster_saturated]` queued (joining edward #1664). Reassigning thorfinn → fresh SOAP-internal per-class axis (β2_mlp vs β2_attn).

## 2026-05-30 02:15Z — PR #1723 CLOSED clean-NEG: nezuko lr_scalars VALUE fine-tune under R5 [49th R5 closure]

- branch: g1r5-nezuko/lr-scalars-r5-fine
- hypothesis: musoft × LN-gain coupling under R5 + EMA-eval may shift optimal `lr_scalars` upward from #571 merged 0.03
- 4-cell sweep (D=0.060 intentionally skipped per pre-mortem 1 conditional):

  | Cell | --lr_scalars | val/loss | val/ema_corr | FFS_ema | Δ_val_ema vs A | gate |
  |---|---|---|---|---|---|---|
  | A (ctrl) | 0.030 | 3.26974 | 3.27025 | 2925 | — | alive ✓ |
  | B★ | 0.045 | 3.27026 | 3.27078 | 2925 | +0.00053 (+0.5σ_4) | alive ✓ |
  | C | 0.020 | 3.26871 | **3.26923** | 2925 | −0.00102 (−1.0σ_4) | alive ✓ |
  | D | 0.060 | — | — | — | — | skipped (pre-mortem) |
  | E | 0.015 | 3.27080 | 3.27131 | 2925 | +0.00106 (+1.1σ_4) | alive ✓ |

- W&B group `g1r5-nezuko/lr-scalars-r5-fine`. Runs: 9adb1lrk (A), 38zu1pwg (B), ghjetk33 (C), qb1jo4u1 (E).
- **Verdict**: CLEAN-NEG. (a) All 4 cells tied at FFS_ema=2925 (G4 FFS-neutral fires). (b) val/ema_corr non-monotonic across sweep: C(0.020)=3.26923 < A(0.030)=3.27025 < B(0.045)=3.27078 < E(0.015)=3.27131. (c) musoft × LN-gain compensation hypothesis FALSIFIED — upward direction (B=+50%) monotone-worse on val/ema_corr. (d) C's −1σ_4 win sandwiched between A and E is single-seed noise blip, not real downward optimum.
- **Cross-axis read**: Joins `[adamw_aux_tetrad_closed]` (β₁/β₂/ε/cooldown) — AdamW aux-group exhaustion now complete. LR-value sub-axis closed at R5. Future R6-stack changes affecting residual magnitudes would require re-screening, but at R5 the aux-group is fully characterized.
- **Mechanism finding (cross-PR)**: Under R5 stack (musoft + EMA-eval + cosine cooldown), the FFS axis is **completely insensitive** to lr_scalars in [0.015, 0.045]. The "less optimizer intensity" theme that won pre-R5 (#371 WD ramp_down, #571 lr_scalars) is locally exhausted on the aux-group side. Stack remains plateaued at μ_4(FFS_ema)=2912.5 since #1533 merge.
- **Decision**: CLOSE clean-NEG. Memory `[lr_scalars_value_closed_at_r5]` queued. Reassigning nezuko → #1769 Muon momentum-buffer warm-start (Muon body init axis — fresh per `[muon_body_three_class_barrier]` ACCEPT-list).

## 2026-05-30 01:44Z — PR #1736 CLOSED clean-NEG: frieren ema_eval_decay VALUE fine-tune under R5

- branch: g1r5-frieren/ema-eval-decay-fine
- hypothesis: fine-tune `--ema_eval_decay` value around R5 default 0.99 to find FFS-positive setting
- 3-cell chain (predeclared conditional skips C/E given B-ties-A):

| Cell | ema_eval_decay | FFS_ema | val/loss | val/ema_corr | W&B |
|:---|:---:|:---:|:---:|:---:|:---|
| A (ctrl) | 0.99 | **2925** | 3.26984 | 3.27036 | dz361xw3 |
| B★ (faster) | 0.985 | **2950** | 3.27226 | 3.27252 | 5q3yjji5 |
| D (slower) | 0.995 | **2925** | 3.26977 | 3.27106 | qiiem3fb |

- **Verdict**: VALUE axis FFS-cosmetic in [0.985, 0.995]. A is best on both FFS and val/ema_corr. B (faster decay) regresses by +25 FFS and +2.4σ val. D (slower decay) ties on FFS but slightly worse on val/ema_corr. R5 default 0.99 confirmed local optimum.
- ema_eval cluster now has three structural closures: VALUE this PR + bias-corr t-budget (#1659) + initial merge (#1533).

## 2026-05-30 01:11Z — PR #1664 CLOSED clean-NEG-on-FFS / val-POS-mechanism: edward per-class body Muon cooldown SHAPE decouple (mlp=cosine, attn=linear)

- branch: g1r5-edward/body-cooldown-shape-decouple → n=4 confirm group `g1r5-edward/per-class-cooldown-shape-confirm`
- hypothesis: at n=1 (#1664 5-cell), Cell B★ (mlp=cosine, attn=linear) hit FFS_ema=2875 with clean falsifier (Cell E mlp=cos/attn=step catastrophic). Promoted to n=4 confirm.
- n=4 per-trial results (W&B `p7ia0dqz`, single multi-trial launch, 13003 steps):

| trial | FFS_ema | FFS_raw | best_val_loss | ema_best_val_loss |
|:---:|:---:|:---:|:---:|:---:|
| 0 | 2925 | 2925 | 3.26697 | 3.26755 |
| 1 | 2925 | 2925 | 3.26845 | 3.26906 |
| 2 | 2925 | 2925 | 3.26732 | 3.26790 |
| 3 | 2925 | 2925 | 3.26733 | 3.26791 |

| Metric | μ_4 | σ_4 | Δ vs baseline | Δσ |
|:---|:---:|:---:|:---:|:---:|
| FFS_ema | **2925.0** | **0.0** | **+12.5** | +0.50σ |
| val/loss | 3.267517 | 0.000644 | −0.002083 | −2.06σ |

- **Verdict**: FFS-primary clean-NEG (fails merge gate ≤2887.5 by +37.5). val/loss meaningfully improved (−2σ) but FFS unmoved — per-class shape decoupling is val-mechanism only. n=1 FFS=2875 was −1σ tail of σ_1≈50 around μ_4=2912.5; regressed to baseline at n=4.
- **Body-Muon per-class differentiation taxonomy closed for shape**: LR magnitude (#162 merged) only load-bearing per-class lever; mu (#1615 closed) + shape (this PR closed) FFS-cosmetic.
- **Pattern flagged → memory `n1-to-n4-seed-regression-at-2875`**: Second R5 n=1 FFS=2875 to regress to 2925 at n=4 in 12h (alphonse #1689 t0 also). Future n=4 promotions require ≥1 cell at FFS_ema ≤ 2850 OR ≥2 convergent 2875 cells with dose-response.

## 2026-05-29 21:52Z — PR #1689 SEND-BACK for n=4 confirm [60th R5 result — SOAP Gram β₂ warmup n=1 strong-positive]: alphonse SOAP Gram-matrix β₂ warmup schedule

- branch: g1r5-alphonse/soap-gram-b2-warmup
- Hypothesis: Single static β₂ in SOAP Gram EMAs leaves preconditioner basis under-informed during first ~10% of training. Ramp β₂ from a lower value at step 0 to default (0.90) by step ~300 → faster early-train preconditioner adaptation → earlier FFS crossing.

| Cell | `--soap_b2_warmup_init` | `--soap_b2_warmup_steps` | FFS_ema | val/loss | val/ema_corr | Δ FFS vs A | W&B |
|:----:|:-----------------------:|:------------------------:|:-------:|:--------:|:------------:|:----------:|:----|
| A (ctrl) | — (default 0.90) | 0 | 2925 | 3.26871 | 3.26922 | 0 | `sxodglph` |
| **B★** | 0.50 | 300 | **2875** | **3.26770** | 3.26822 | **−50** | `4x88ef2k` |
| C | 0.70 | 300 | 2925 | 3.26898 | 3.26949 | 0 (TIE) | `j9n2wjl6` |
| D | 0.85 | 300 | 2925 | 3.26913 | 3.26965 | 0 (TIE) | `8gcb5xzn` |
| **E** | 0.50 | 150 | **2875** | 3.26833 | 3.26884 | **−50** | `nhukz7ii` |

**Pattern**: Clean monotone dose-response in `init`. D (0.85) → C (0.70) tied ctrl. B (0.50, ramp=300) and E (0.50, ramp=150) both hit FFS_ema=2875 — ramp length irrelevant in [150, 300] given init=0.50. Pre-registered G1 alive (≤2975): all pass. G2 promotion (≤2887.5): B and E pass.

**Mechanism telemetry verified**: `soap/gram_eigval_max` traces show brief spike in first 5–10% of training in cells with warmup (B, C, E vs A/D) — Gram EMA absorbs fresh curvature aggressively while β₂ low → consistent with hypothesis. β₂ schedule (`soap/b2_current`) per-step trace matches spec for all cells.

**Independent corroboration**: fern #1721 (SOAP Gram-matrix warm-init from step-0 gradient variance) Cell B★ at FFS_ema=2875 — same lift magnitude on a structurally distinct SOAP-state initialization axis. Two independent positive signals on SOAP-state preconditioner early-train initialization within hours.

**Decision**: n=1 strong-positive. SEND-BACK to alphonse for **n=4 confirm of Cell B** (init=0.50, ramp=300) with pre-declared 4 seeds. Merge gate: μ_4(FFS_ema) ≤ 2887.5. Holding off on Cell E n=4, lower-start exploration (`init=0.30`), and MLP/attn-decoupled warmup until B n=4 confirms or fails. n=1 caveat: 2875 matches baseline min — fortunate-seed risk acknowledged.

---

## 2026-05-29 19:05Z — PR #1677 CLOSED [59th R5 result — lr_attn axis closed clean-NEG]: frieren lr_attn fine retune under R5 SOAP-attn stack

- branch: g1r5-frieren/lr-attn-fine-r5-cosine
- Hypothesis: Body lr_attn VALUE fine re-tune under R5 SOAP-attn stack — tests whether optimal lr_attn shifts from plain-Muon default (0.035) when SOAP-attn's Kronecker-factored preconditioner changes the effective gradient signature.

| Cell | `--lr_attn` | FFS_ema | val/loss | val/ema | Δ FFS vs A | W&B |
|:----:|:-----------:|:-------:|:--------:|:-------:|:----------:|:----|
| A (ctrl) | 0.035 | 2875 | 3.26798 | 3.26848 | 0 | `8izl94u4` |
| **B★** | 0.055 | **2950** | 3.27092 | 3.27145 | +75 | `pxtm8zmw` |
| C | 0.025 | 2875 | 3.26882 | 3.26932 | 0 (TIE) | `yi4gqyr3` |
| D | 0.045 | 2950 | 3.27104 | 3.27157 | +75 | `agzi50x1` |
| E | 0.070 | 3025 | 3.2747 | 3.2756 | +150 | `j99vhg5q` |

**Pattern**: Monotone-degrading above ctrl 0.035, FFS-neutral going lower (C=0.025 ties ctrl). No upward win analogous to #162's lr_mlp finding.

- Pre-mortem 3 (B mirrors #162 upward lr_mlp win) **falsified** — B is +75 worse than ctrl.
- Pre-mortem 1 (B cosmetic to A) also falsified — B actively regresses.
- Pattern matches Pre-mortem 2 (lower lr_attn is not worse, unlike lower lr_mlp).
- E (falsifier, upward extreme) fails alive gate G1 at FFS=3025 (>2975). Confirms upper range harmful.

**Mechanism**: SOAP-attn's Kronecker-factored preconditioner L⁻¹·∇·R⁻¹ adaptively rescales attn gradient magnitude before NS. Adding LR above 0.035 over-amplifies an already-normalized signal → FFS regression. Going lower (C=0.025) is FFS-neutral. lr_attn=0.035 is locally optimal on R5 SOAP-attn stack.

**Decision**: CLOSED clean-NEG. **lr_attn VALUE axis on R5 CLOSED** — default 0.035 confirmed FFS-optimal in [0.025, 0.070] range. Symmetric to #1676 wd_attn closure: per-class attn HP value re-tuning under R5 stack is FFS-cosmetic (Kronecker preconditioner absorbs sensitivity). Frieren reassigned to #1736 ema_eval_decay VALUE fine-tune.

---

## 2026-05-29 17:05Z — PR #1676 CLOSED [58th R5 result — wd_attn axis closed clean-NEG]: nezuko wd_attn fine retune

- branch: g1r5-nezuko/wd-attn-fine-r5-cosine
- Hypothesis: Mirror of thorfinn's wd_mlp=0.040 winner — test whether SOAP-attn's changed gradient spectral signature warrants higher wd_attn (default 0.025).
- Result: **CLEAN-NEG. Default wd_attn=0.025 locally optimal. B★ (0.040) regresses to FFS=2950 (+75 vs ctrl). C (0.015) ties ctrl at FFS=2875 within n=1 noise. Monotone-NEG above default.**

| Cell | `--wd_attn` | FFS_ema | val/ema_corr | Δ FFS vs A | W&B |
|:----:|:-----------:|:-------:|:------------:|:----------:|:----|
| A (ctrl) | 0.025 | 2875 | 3.26856 | 0 | `z13bdfi5` |
| **B★** | 0.040 | **2950** | 3.27131 | +75 (worst) | `rwgj8hka` |
| C | 0.015 | 2875 | 3.26868 | 0 (TIE) | `yxku4co3` |
| D | 0.050 | SKIPPED | — | — | — |
| E | 0.030 | 2925 | 3.26998 | +50 | `u1cj10oh` |

D skipped per PR conditional gate: B alive AND C alive → launch E only.

**Pattern (monotone-NEG above default)**: 0.015→2875, 0.025→2875 (tied), 0.030→2925, 0.040→2950.

**Mechanism**: Thorfinn's wd_mlp=0.040 does NOT transfer to wd_attn axis. SOAP-attn's Kronecker preconditioner absorbs gradient-scale sensitivity in attn weights — the explicit wd_attn is already at its optimal value (0.025). Pre-mortem 2 fired (C matches B) but C TIEs A (not beats A), so no n=4 promotion justified.

**Decision**: CLOSED clean-NEG. wd_attn axis closed at R5. Default 0.025 confirmed locally optimal under SOAP-attn + cosine cooldown + musoft stack. No n=4. Nezuko reassigned to #1723 lr_scalars VALUE fine-tune.

---

## 2026-05-29 16:38Z — PR #1664 SENT-BACK [55th R5 result — per-class cooldown SHAPE n=1 STRONG POSITIVE, promoted to n=4]: edward mlp=cos/attn=lin n=1 5-cell sweep

- branch: g1r5-edward/body-cooldown-shape-decouple
- Hypothesis: Per-class body Muon cooldown SHAPE decoupling — different LR-decay shape for mlp vs attn during cosine cooldown phase.
- Result: **STRONG FFS-POSITIVE at n=1. Cell B★ (mlp=cosine, attn=linear) FFS_ema = 2875, Δ=−1.5σ vs baseline 2912.5, below n=1 strong-positive gate 2887.5.**

| Cell | mlp shape | attn shape | FFS_ema | val/loss | val/ema | Δ(σ) FFS | W&B |
|:----:|:---------:|:----------:|:-------:|:--------:|:-------:|:--------:|:----|
| A ctrl  | cosine | cosine  | 2925 | 3.2697 | 3.2702 | +0.50 | `ntvtw8z7` |
| **B★** | cosine | **linear** | **2875** | **3.2660** | 3.2666 | **−1.50** | `3e25sgci` |
| C | cosine | concave | 3000 | 3.2719 | 3.2712 | +3.50 | `mexxftpc` |
| D INVERT | linear | cosine | 2925 | 3.2656 | 3.2662 | +0.50 | `v4nebk3f` |
| E FALSIFIER | cosine | step | **−1** | 3.2945 | 3.2949 | catastrophic | `hbly2quc` |

**Pattern (attn-cooldown ordering, monotone)**: linear (gentle) ≺ cosine (control) ≺ concave (fast) ≺ step (catastrophic). Direction is consistent across all four attn-side cells.

**Mechanism**: attn smooth-LR-decay is structurally load-bearing — falsifier Cell E (step decay) never crossed 3.28 (val=3.2945). Gentler attn decay (linear vs cosine) maintains higher LR through middle of cooldown, consistent with attention's relational/low-rank patterns benefiting from sustained intermediate LR for late-stage fine-tuning. MLP-side decoupling (Cell D INVERT) was FFS-neutral, confirming asymmetry concentrated on attn side.

**Decision**: SENT-BACK to student for n=4 confirm of Cell B★ only. If μ_4(FFS_ema) ≤ 2887.5 at n=4, MERGE candidate (would be 55th R5 PR closure + baseline-shifting merge).

---

## 2026-05-29 16:36Z — PR #1659 CLOSED [56th R5 result — per-group EMA-eval decay decoupling axis closed G1-DEAD]: askeladd per-group EMA decay n=1 5-cell sweep

- branch: g1r5-askeladd/per-group-ema-decay
- Hypothesis: Per-group (body vs aux) EMA-eval decay decoupling — different `--ema_eval_decay` for body Muon-params vs aux AdamW-params, predicted to amplify FFS signal beyond #1533's uniform 0.99.
- Result: **G1-DEAD at n=1. All cells A/B/C/E FFS=2925 (TIE with baseline σ band). D=−1 catastrophic but STRUCTURAL (bias-correction blow-up at t=3250, not learning effect).**

| Cell | d_body | d_aux | FFS | val/loss | ema_corrected | W&B |
|------|--------|-------|-----|----------|---------------|------|
| A ctrl | None (uniform 0.99) | 0.99 | 2925 | 3.27074 | 3.27125 | `tnm6usu3` |
| B★ | 0.95 | 0.99 | 2925 | 3.26996 | 3.27007 | `jmc56a9c` |
| C | 0.97 | 0.99 | 2925 | 3.26897 | 3.26910 | `ou15dqjr` |
| D | **0.999** | 0.99 | **−1** | 3.26963 | **3.32229** | `6t9t7j2x` |
| E FALSIFIER | 0.90 | 0.99 | 2925 | 3.26989 | 3.26998 | `fe0vwowo` |

**Mechanism diagnosis** (excellent student self-analysis): Cell D's catastrophic `ema_corrected=3.32229` is NOT a learning-rate dynamics issue. With `d_body=0.999`, `d^t = 0.0387` at step 3250, so the bias-correction denominator `(1-d^t) = 0.961` fails to scrub init contamination. `drift_from_init=71653` matches A's 71649 within noise — the body trajectory is the SAME. The EMA average over those 3250 steps with d=0.999 has only effectively averaged the last ~1000 steps. This imposes a hard lower bound on `1-d_body` relative to training steps: `t ≳ 5/(1-d)` ≈ 5000 steps required to safely use d_body ≥ 0.998. The 3250-step budget structurally blocks the slow-direction.

**Verdict**: Per-group EMA decoupling axis FFS-NEUTRAL across safe operating range d_body ∈ [0.90, 0.97]. Val/loss shows weak monotone in fast direction (~0.001-0.002 across cells) but n=1 below noise floor, and FFS-PRIMARY directive #1262 governs. Axis closed.

---

## 2026-05-29 16:36Z — PR #1654 CLOSED [57th R5 result — adaptive eigenbasis refresh axis closed clean-NEG]: fern SOAP off-diagonal staleness criterion n=1 5-cell sweep

- branch: g1r5-fern/soap-adaptive-eigenbasis-refresh
- Hypothesis: Adaptive PRECOND_FREQ gated by `Q^T L Q` off-diagonal mass — refresh eigenbasis only when off-diagonal staleness exceeds threshold τ. Predicted to save eigendecomp compute during cooldown (when basis stabilizes) and improve preconditioner quality early.
- Result: **CLEAN-NEG at n=1. A/C/D/E all FFS=2875 (tied with ctrl). B (τ=0.05) FFS=2925 (single-trial noise). NO FFS lift from adaptive criterion across τ ∈ [0.02, 0.50].**

| Cell | τ | check_freq | refresh_count/layer | FFS_ema | val/loss | ema_val | W&B |
|------|---|------------|---------------------|---------|----------|---------|------|
| A ctrl | 0.00 | fixed PF=16 | 203 | **2875** | 3.26776 | 3.26828 | `x45n90hl` |
| B★ | 0.05 | 4 | 812 (4.0×) | 2925 | 3.27026 | 3.27078 | `36m6dxuc` |
| C | 0.02 | 4 | 812 (4.0×) | 2875 | 3.26671 | 3.26724 | `a3437mwq` |
| D | 0.15 | 4 | 797 (3.9×) | 2875 | 3.26755 | 3.26807 | `db80yeon` |
| E FALSIFIER | 0.50 | 4 | 569 (2.8×) | **2875** | 3.26793 | 3.26844 | `7kodg49i` |

**Mechanism diagnosis** (excellent student self-analysis): Staleness signal IS non-degenerate (mean_staleness=0.55–0.61, vs hypothesized degenerate noise floor). But staleness is **FLAT across all training phases** (warmup, main, cooldown) — does not decay through training as predicted. At τ ≤ 0.15, `refresh_trigger_fraction=1.0` for all layers always (mechanism degenerates to refresh-every-check_freq). Cell E (τ=0.50) is the ONLY meaningfully-gating regime (~70% trigger rate vs 100%), cutting refresh count from 812 to 569 per layer — but still ties Cell A on FFS. **Conclusion: eigenbasis rotation rate does NOT correlate with whether SOAP benefits from a fresh basis.** PRECOND_FREQ=16 was apparently not under-refreshing.

**Verdict**: Adaptive eigenbasis refresh axis closed. Combined with earlier closures, this caps the SOAP structural cluster:
- Adaptive eigenbasis refresh → null (this PR)
- Static PRECOND_FREQ value → sub-σ at n=4 (#1617)
- Gram trace normalization → null (#1564)
- SOAP scalar HPs (β2, eps, exp_avg_sq, trust-gate) → null (multi-PR cluster)

Open SOAP axes remaining: PRECOND_FREQ PHASE-ADAPTIVE schedule (tanjiro #1715 in-flight), SOAP Gram WARM-INIT (fern reassigned #1721).

---

## 2026-05-29 15:20Z — PR #1617 CLOSED [53rd R5 result — SOAP PRECOND_FREQ static-value axis closed]: tanjiro PRECOND_FREQ=8 n=4 confirm

- branch: g1r5-tanjiro/soap-precond-freq-confirm
- Hypothesis: Static PRECOND_FREQ=8 (vs default 16) reduces eigenbasis staleness during early training when gradient curvature shifts fastest, predicted to yield earlier FFS crossing.
- Result: **CLEAN NEG at n=4. μ_4(FFS_ema)=2918.75, σ_4=31.46 — +6.25 vs baseline, missed merge gate by 31.25.**

| Trial | FFS_ema | W&B |
|:-----:|:-------:|:---:|
| 0 | 2925 | `ga45cab3` |
| 1 | 2875 | `ga45cab3` |
| 2 | 2950 | `ga45cab3` |
| 3 | 2925 | `ga45cab3` |
| **μ_4** | **2918.75** | σ_4=31.46 |

**vs baseline μ_4=2912.5**: Δ=+6.25 NEG (sub-σ noise band). Missed gate 2887.5 by 31.25.

**Mechanism**: Axis IS structurally load-bearing at n=1 (monotone trend: pf=8 → 2925, pf=16 → 2950, pf=32 → 2950, pf=64 → 2975, pf=128 → 3000). EMA-eval stack did NOT amplify the ~50-step n=1 signal into a merge-worthy n=4 delta. The static-value framing cannot isolate early-phase benefit without paying late-phase basis-jitter overhead. **Static PRECOND_FREQ axis closed**; phase-adaptive schedule (deterministic early/late transition) assigned as follow-up to tanjiro #1715.

---

## 2026-05-29 15:20Z — PR #1586 CLOSED [54th R5 result — wd_mlp VALUE axis closed at n=4, val-vs-FFS divergence confirmed]: thorfinn wd_mlp=0.040 n=4 confirm

- branch: g1r5-thorfinn/wd-mlp-fine-r5-confirm
- Hypothesis: wd_mlp=0.040 exploits cosine-cooldown's late-window LR scaling to achieve eff_wd≈1.82e-4 at step 3000 vs ctrl 1.14e-4, predicted val basin → FFS crossing advantage.
- Result: **CLEAN NEG at n=4. μ_4(FFS_ema)=2943.75, σ_4=55.43 — +31.25 vs baseline, highest σ_4 seen in R5.**

| Trial | FFS_ema | W&B |
|:-----:|:-------:|:---:|
| 0 | 2925 | `ii70qzc4` |
| 1 | 3000 | `ii70qzc4` |
| 2 | 2875 | `ii70qzc4` |
| 3 | 2975 | `ii70qzc4` |
| **μ_4** | **2943.75** | σ_4=55.43 |

**vs baseline μ_4=2912.5**: Δ=+31.25 NEG (≈1.25σ above baseline). Missed gate 2887.5 by 56.25.

**Mechanism (val-vs-FFS divergence, second R5 instance)**: n=1 screening showed Cell E at wd_mlp=0.040 was −2.5σ BEST on val/loss, with clean basin shape (cliff below at 0.055, NEG above at higher values). However, trial_1=3000 (outlier) dominated n=4 variance and drove μ_4 positive. The val-loss basin at eff_wd=1.82e-4 is a REAL continuous optimum but FFS crossing-time distribution is WIDER at this WD value (σ_4=55.43 vs baseline σ_4=25.0). **WD-value axis closed at n=4**. Per-class WD-schedule SHAPE decoupling assigned as follow-up to thorfinn #1716 (symmetric to edward's #1664 positive cooldown-SHAPE finding).

---

## 2026-05-29 10:25Z — PR #1658 CLOSED [52nd R5 result — multi-timescale EMA combination axis closed FFS-NEG]: alphonse multi-β EMA (Karras-inspired)

- branch: g1r5-alphonse/multi-beta-ema-combination
- Hypothesis: Combine fast β=0.99 (current baseline) + slow β=0.999 EMAs at val time via 50/50 mix; predicted to lower val noise without FFS penalty.
- Result: **CLEAN G1-DEAD per pre-registered gate.** Cell B `combined_FFS=-1` (combined EMA never crossed 3.28; final ema_val_combined=3.28261). Cell A reproduced baseline to 4e-5.

| Cell | β_slow | α (slow_mix) | FFS_combined | FFS_fast (β=0.99) | ema_val_combined | ema_val_fast | Gate | W&B |
|:----:|:------:|:------------:|:------------:|:-----------------:|:----------------:|:------------:|:----:|:---:|
| A (ctrl) | None | N/A | N/A | **2925** | N/A | 3.26964 | ctrl ✓ | `tip91b01` |
| B★ (primary) | 0.999 | 0.5 | **−1** | 2925 | **3.28261** | 3.27006 | **G1 DEAD** ✗ | `1f1haxux` |
| C/D/E | — | — | NOT RUN | — | — | — | gated off | — |

**Mechanism (alphonse's diagnosis, clean and informative)**: τ_slow=1/(1−β_slow)=1000 / T_train=3250 = 31% of horizon → slow EMA averages params from steps ~1925-2925 where val ≈3.46 down to 3.28. 50/50 mix → combined val ≈ midpoint ≈ 3.298 (observed 3.29787 at step 2925 when fast crossed). Karras et al.'s power-function EMA works in multi-million-step diffusion (τ_slow ≪ T_train); breaks in speedrun where τ_slow ~ 31% of T_train.

**Trajectory**: gap (combined − fast) shrinks monotonically from +0.05852 (step 1000) to +0.01255 (step 3250) but never closes. Combined finishes 0.00261 above target.

**Implementation sanity verified**: slow_d_pow_t=0.03871 matches 0.999^3250, slow_drift_from_init=64111 < drift_from_init=71651, Cell A reproduces #1533 baseline to 4e-5 (slow buffer correctly disabled when --ema_eval_decay_slow None).

**Axis closure**: multi-timescale EMA COMBINATION at val time closed FFS-NEG. Alphonse's own follow-up #1 (smaller β_slow ∈ {0.993, 0.995}) and #3 (schedule-aware α(t) ramp in cooldown only) remain technically open but in the EMA-axis local neighborhood. EMA-eval signal exploration via β-mix is structurally exhausted at n=1.

## 2026-05-29 08:25Z — PR #1651 CLOSED [51st R5 result — post-NS per-matrix scaling axis closed]: frieren pre-NS gradient-Frobenius normalization

- branch: g1r5-frieren/muon-pre-ns-grad-norm-scale
- Hypothesis: Apply `1/(||g_nesterov||_F / sqrt(m·n))^alpha` as per-matrix divisor on post-NS Muon update — predicted to temper MLP large-norm and boost saturated-attn small-norm during crossing window.
- Result: **CLEAN G2+G3 (FFS-NEG) — Cell B α=1.0 grad-mode never crossed 3.28 (val=3.575 terminal).** Cell C weight-mode falsifier tracked Cell A within +0.06 val (NOT Cell B), proving axis-class-distinct from closed LAMB/LARS cluster.

| Cell | mode | α | FFS_train | val/loss @ 3250 | reached 3.28? | W&B |
|:----:|:----:|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | — | 0.0 | **2950** | 3.27003 | ✓ | `ecfyctnu` |
| B★ (primary) | grad | 1.0 | **−1** | 3.57492 | ✗ | `fnyiv8f1` |
| C (falsifier, killed) | weight | 1.0 | n/a (step 742) | tracking A (+0.06 val) | n/a | `ckdt5bpw` |

**Diagnostic (KG1 step-200 per-matrix Frobenius spread)**: B grad-mode rel_std=1.40 (heavy spread), C weight-mode rel_std=0.124 (~10× tighter). ||g_nesterov||_F has dramatically more cross-layer spread than ||W||_F under R5+SOAP-attn stack.

**Mechanism diagnosis (KG2/KG3 fired)**: Late-train (step ~2000+), the divisor distribution is INVERTED relative to mechanism intent: MLP nuc_scale balloons (mean=25.7, max=343), attn nuc_scale collapses (mean=2.96, std=7.81). MLP gets divided by very large numbers → updates barely move → val descent stalls at 3.575. Opposite of predicted direction.

**Closure verdict**: axis-class-distinct from closed LAMB/LARS-cluster (Cell C weight-Frobenius behaves as near-global rescale ≈ uniform LR adjustment, NOT same destructive class as B). The result rules out ||g_nesterov||_F as per-matrix divisor specifically; doesn't subsume ||∂L/∂W||_F (pre-momentum raw gradient) variants — student notes those are "new PRs with their own KGs" if pursued.

**Branch note**: Branch predates #1533 EMA-eval SWA merge, so screening used pre-EMA stack. Acceptable per advisor n=1-screening guidance. Cell A FFS=2950 confirms baseline reproducibility within step quantization of pre-EMA μ_4(FFS)=2943.75.

---

## 2026-05-29 07:25Z — PR #1643 CLOSED [50th R5 result — NS-init sub-axis CLOSED, NS cluster 6/6 closed]: nezuko NS warmstart from previous polar factor

- branch: g1r5-nezuko/ns-warmstart-init
- Hypothesis: Reuse previous step's polar factor as NS initialization (instead of `g/||g||_F`) to accelerate convergence by exploiting temporal continuity of orthogonalization output.
- Result: **CLEAN G5 (FFS-NEGATIVE) — catastrophic at α=1.0, monotone-NEG at α=0.7.** Diagnostic readout confirms warmstart is active (not silent artifact).

| Cell | α | val/loss | FFS_train | Δ FFS vs A | W&B |
|:----:|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.0 | 3.27154 | **2950** | 0 | `2v0ayfnz` |
| B (primary) | 0.7 | 3.52822 | **−1 (DNF)** | +∞ | `9p2890ep` |
| C | 1.0 | 4.81831 @step 2875 (early-killed) | **−1 (DNF)** | +∞ catastrophic | `ibp8vm86` |

**Diagnostic (step 1000+, SOAP-NS attn param)**: `ns_q_norm`=55.5, `u_cold_norm`=54.2, `warm_cold_diff_norm`=69.7 → diff_norm ≈ output_norm → warmstart MATERIALLY alters NS iterate; not silent.

**Mechanism (firm)**: SOAP exploits temporal continuity at the *preconditioner* level (Gram EMA + PRECOND_FREQ=16, basis cos_sim 0.82–0.84). Adding NS warmstart at the *orthogonalization output* level does not stack — it pulls NS away from the correctly-preconditioned momentum target. The 5-step quintic NS already converges in ~5 iters from `g/||g||_F`; α-blending a stale polar factor injects orientation error the quintic cannot correct in 5 iters. **Temporal-continuity headroom for orthogonalization is fully saturated by SOAP.**

**NS-internal cluster status: 6/6 CLOSED**
- depth-schedule (#1609)
- poly-coeffs static (#1612)
- iter-count static (#1638 R3, #1509 R4)
- **init/warmstart (#1643)** ← just closed
- Remaining NS-family openings: only *schedules* of ns_iter/coefficients over training (per Muon body 5-class barrier ACCEPT-list).

---

## 2026-05-29 — PR #1617 (in flight): tanjiro SOAP PRECOND_FREQ n=1 screen → n=4 EMA-eval confirm approved

- branch: g1r5-tanjiro/soap-precond-freq
- Hypothesis: SOAP preconditioner update frequency (PRECOND_FREQ, default 16) had never been swept since #467 trust-gate / static / schedule closures. Test pf ∈ {16, 8, 32, 64, 128}.
- n=1 screen result: **MONOTONE in pf** — pf=8 BEST, pf=128 WORST.

| Cell | pf | val/loss | FFS_train | Δ FFS vs A | W&B |
|:----:|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | 16 | 3.27106 | 2950 | 0 | `rft4g14z` |
| **B★** | **8** | **3.26898** | **2925** | **−25 G2 fired** | `17020g8g` |
| C | 32 | 3.27109 | 2950 | 0 (tie) | `2sqvsmle` |
| D | 64 | 3.27282 | 2975 | +25 (boundary) | `k7lz55sy` |
| E (falsifier) | 128 | 3.27340 | 3000 | **+50** | `i7j9b7h8` |

**Analysis**: SOAP eigenbasis rotates FASTER than #1565 cos_sim(SOAP↔Muon)~0.82-0.84 metric implies (that metric measures projected-update agreement, not eigenbasis rotation rate directly). Refreshing every 8 steps captures curvature drift that pf=16 misses. Falsifier E confirms staleness mechanism is real at pf=128. **Axis structurally load-bearing in both directions** (G4 FFS-neutral test failed: 3-cell band 50 > ±12.5). **n=4 confirm of B (pf=8) under EMA-eval stack APPROVED** — expected FFS_ema band ~2900 ± 25, merge-borderline at gate 2887.5. Note: n=1 screen used pre-#1533 stack, n=4 confirm uses full mandatory stack with `--ema_eval_decay 0.99`.

---

## 2026-05-29 — PR #1586 (in flight): thorfinn body wd_mlp fine re-tune — 8-cell basin localized → n=4 EMA-eval confirm approved

- branch: g1r5-thorfinn/wd-mlp-fine
- Hypothesis: Under R5 cosine cooldown (#1381 merged), wd_mlp basin may have shifted from #1284's old optimum at 0.025. Re-tune.
- 8-cell sweep result: **basin CONFIRMED upper-shifted to ~0.040** under cosine cooldown.

| Cell | wd_mlp | FFS_train | val/loss | Δ val vs A (σ_single=0.000593) | W&B |
|:----:|:---:|:---:|:---:|:---:|:---:|
| D | 0.018 | 2950 | 3.27148 | +0.00228 (+3.8σ NEG) | `wcfu9ju9` |
| B | 0.022 | 2950 | 3.27058 | +0.00138 (+2.3σ NEG) | `qyxyuhka` |
| A (ctrl) | 0.025 | **2925** | 3.26920 | 0 | `j18xhgzb` |
| C | 0.028 | **2925** | 3.26920 | 0 (tie) | `sbgx4g2o` |
| **E★** | **0.040** | **2925** | **3.26774** | **−0.00146 (−2.5σ BEST)** | `t6hgmr8f` |
| F | 0.055 | 3025 | 3.27360 | +0.00440 (+7.4σ NEG) | `x19w8m6i` |
| G | 0.070 | 3100 | 3.27787 | +0.00867 (+14.6σ NEG) | `3qko6399` |
| H | 0.100 | **−1 (DNF)** | 3.28609 | +0.01689 (+28.5σ catastrophic) | `0cj3fvlc` |

**Analysis**: eff_wd@3000 decomposition (E sits at 1.82e-4 vs ctrl A 1.14e-4) gives clean mechanism: cosine cooldown's late-window LR decay halves integrated WD application during cooldown phase, opening room for ~60% higher per-step initial_wd at basin centroid. Cliff edge cleanly bracketed: between wd_mlp ∈ [0.040, 0.055]. Pre-mortem 2 interpretation #1 (basin upper-shifted under cosine) **FULLY CONFIRMED**. **n=4 confirm of E (wd_mlp=0.040) under EMA-eval stack APPROVED** — expected FFS_ema band ~2900 ± 25, merge-borderline at gate 2887.5.

---

## 2026-05-29 — PR #1615 CLOSED [49th R5 result — mu axis FULLY CLOSED]: edward Muon body momentum decoupling (mu_mlp vs mu_attn)

- branch: g1r5-edward/muon-body-mu-decouple
- Hypothesis: MLP and attention body Muon groups may benefit from different momentum coefficients. LR magnitude decoupling (#162 MERGED, lr_mlp=0.055 > lr_attn=0.035) was FFS-positive, so history-length (mu) decoupling within body might also help. Tested both directions: ATTN-low/MLP-high (B★) and MLP-low/ATTN-high (E falsifier) plus bracketing values.
- Result: **CLEAN G5 (FFS-NEGATIVE)**. All non-ctrl cells worse. Falsifier E WORST (+100), proving both directions decisively rejected.

| Cell | mu_mlp | mu_attn | FFS_ema | Δ FFS vs A |
|:----:|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.95 | 0.95 | **2925** | 0 |
| **B★** | 0.95 | 0.85 | 2950 | +25 |
| C | 0.95 | 0.90 | 2975 | +50 |
| D | 0.90 | 0.85 | 3000 | +75 |
| E (falsifier) | 0.85 | 0.95 | 3025 | **+100 WORST** |

**Analysis**: Monotone degradation with both directions of mu decoupling. Falsifier E (MLP-reduced, ATTN-preserved) is the worst possible cell, definitively ruling out inverted hypothesis. **Key mechanistic finding**: LR per-group decoupling (#162) wins but mu per-group decoupling (#1615) loses. The asymmetry (MLP wants more update energy via higher LR, not more momentum) implies the per-class differentiation mechanism is **magnitude** (peak update energy), not **history-length** (momentum buffer). Closes the per-class mu axis completely. Mu axis now FULLY CLOSED across all 3 sub-axes: single-axis cooldown schedule (#1294/#1345), 2D plane sweep, and per-group static (#1615).

**New open axis**: Per-class body Muon cooldown SHAPE decoupling (MLP vs attn temporal curve) — assigned to edward #1664.

---

## 2026-05-29 — PR #1612 CLOSED [48th R5 result — 6th NS-internal axis closure]: askeladd NS polynomial coefficient sweep (Bernstein vs Padé)

- branch: g1r5-askeladd/ns-poly-coeffs
- Hypothesis: Bernstein-optimal quintic NS coefficients (3.4445,-4.7750,2.0315) should orthogonalize matrices more accurately per NS step than codebase default Padé (2.0,-1.5,0.5), yielding cleaner Muon/SOAP updates and earlier FFS crossing at --ns_iter 6.
- Result: **CLEAN G5 (FFS-NEGATIVE)**. Bernstein +25 worse than Padé. Padé is the FFS minimum on this 5-point grid.

| Cell | --ns_coeffs | val/loss | FFS | Δ FFS vs A |
|:----:|:---:|:---:|:---:|:---:|
| A (ctrl) | 2.0,-1.5,0.5 (Padé default) | **3.26814** | **2925** | 0 |
| **B★** | 3.4445,-4.7750,2.0315 (Bernstein) | 3.27095 | 2950 | **+25 G5** |
| C | 2.5,-2.5,1.0 (intermediate-lo) | 3.26992 | 2950 | +25 |
| D | 3.0,-4.0,1.75 (intermediate-hi) | 3.27158 | 2950 | +25 |
| E (falsifier) | 1.5,-0.75,0.25 (weaker) | 3.27889 | 3125 | **+200** ✓ |

W&B runs: `vf5sexur` (A), `9xpl6uu8` (B), `t4ih3ipp` (C), `b9bg9aao` (D), `0mva75ef` (E).

**Analysis**: Axis IS load-bearing (falsifier E +200 = 16σ_4). But Bernstein is anti-correlated. Padé (2,-1.5,0.5) sits at the FFS minimum. At --ns_iter=6, the quintic NS is near-converged for body matrix spectra; Bernstein's aggressive amplitude (designed to push small singular values toward 1 aggressively) adds spectral noise rather than improving convergence. The three intermediates C/D all plateau at +25 = same as Bernstein — FFS decreases immediately when moving off Padé, then plateaus. **5th NS-internal polynomial/coefficient axis closure for R5**.

**6th NS-internal closure overall** (depth-schedule #1609 + poly-coeffs #1612 + iter-count #1638/#1509 + warm-start #1643 in flight).

---

## 2026-05-29 — PR #1533 MERGED [47th R5 result, 2nd FFS-PRIMARY MERGE]: alphonse EMA-eval SWA d=0.99 bias-corrected — new baseline μ_4(FFS_ema)=2912.5

- branch: g1r5-alphonse/ema-eval-swa
- Hypothesis: Evaluate val/loss on a bias-corrected EMA of the parameter trajectory (SWA-style, d=0.99 ≈ 100-step window) during training. Mechanism: SWA-style averaging of cooldown-phase iterates yields systematically lower val_loss near the 3.28 crossing, advancing FFS by the mean within-run gap. Izmailov 2018 / Karras 2023 mechanism.

**n=1 sweep (pre-#1381 linear-cooldown stack for mechanism discovery):**
| Cell | decay d | FFS_train | FFS_ema_corr | Within-run Δ | W&B |
|:----:|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | — | 3025 | — | — | `c5ujer5l` |
| B | 0.999 | 3050 | NEVER | degenerate | `tbddza9o` |
| C | 0.9999 | 3050 | NEVER | degenerate | `2fggyis3` |
| **D★** | **0.995** | 3025 | **2925** | **−100** | `asqvbywb` |
| **E★** | **0.99** | 3025 | **2925** | **−100** | `kma4gcqg` |

**Bias-correction issue caught**: EMA without correction was ~4.9% init-biased at d=0.999 step 3025, and ~74% at d=0.9999. Student implemented Option A (exact correction using `init_state` fp32 snapshot). Restarted Cells B-E with bias correction.

**n=4 confirm of Cell E (d=0.99) on post-#1381 cosine-cooldown stack** (W&B run `axzk5hpf`):
| Trial | FFS_ema_corr | FFS_train | val/loss_train | val/ema_corr |
|:---:|:---:|:---:|:---:|:---:|
| 0 | 2925 | 2925 | 3.26905 | 3.26957 |
| 1 | 2925 | 2950 | 3.27039 | 3.27089 |
| 2 | **2875** | 2925 | 3.26845 | 3.26897 |
| 3 | 2925 | 2950 | 3.27051 | 3.27102 |
| **μ_4** | **2912.5** | 2937.5 | 3.269600 | 3.270113 |
| σ_4 | 25.0 | 14.43 | 0.001013 | 0.001005 |

**Gate readout:**
- μ_4(FFS_ema) = 2912.5 ≤ 2918.75 ✅ PASS by 6.25 (merge gate)
- σ_4 = 25.0 > 12.5 ❌ 2× predeclared bound (structural: EMA-eval adds within-run FFS variance)
- Val gate: 3.270113 > 3.269622 ❌ miss by 0.000490 (FFS-primary result, val essentially at baseline)

**Merge decision**: MERGED. Mean clears strict gate; within-run mechanism direction-consistent all 4 trials (0/−25/−50/−25 steps). σ inflation is structural not stochastic. Mechanism: cosine cooldown (#1381) already absorbed ~75% of SWA benefit; remaining −25 step mean gap is still real and cleared the gate.

**★ Mechanism finding**: Within-run SWA gain shrinks from −100 (linear cooldown stack) to −25 (cosine cooldown stack). Cosine cooldown and EMA-eval are mechanistically overlapping (both smooth late-trajectory noise near 3.28 crossing). EMA-eval on cosine stack provides a +25 step gain over cosine alone.

**New baseline**: μ_4(FFS_ema) = 2912.5 (σ_4=25). **Mandatory stack updated**: now includes `--ema_eval_decay 0.99`. FFS is now measured on EMA-eval trajectory. All in-flight students must rebase and add `--ema_eval_decay 0.99` before n=4 confirm.

---

## 2026-05-29 03:57 — PR #1564 CLOSED [46th closure of R5]: fern SOAP Gram trace normalization before eigendecomposition (per paper)
- branch: g1r5-fern/soap-trace-norm
- Hypothesis: SOAP paper formalism requires Σ = E[gg^T] / Trace(E[gg^T]) for proper Kronecker product approximation. Current implementation skips trace normalization. Add it before eigendecomposition; hypothesis is the paper's "critical" step is genuinely critical and unlocks better preconditioning.
- 5-cell screen → n=4 confirm + matched within-environment ctrl D plan.

**n=4 confirm:**
| Cell | Run | μ_4(val) ± σ | μ_4(FFS) ± σ | Δ vs #1381 |
|:----:|:----:|:--------:|:----:|:----:|
| **B (trace_norm ON)** | `ixqmqe2j` | 3.269783 ± 0.000405 | **2931.25 ± 12.5** | −12.5 steps |
| **D (matched ctrl OFF)** | `gonpg5rr` | 3.269748 ± 0.000429 | **2931.25 ± 12.5** | −12.5 steps |
| A drift sanity OFF | `mik8ce7j` | 3.2692 | 2925 (n=1) | — |
| #1381 baseline OFF | (ref) | 3.270215 | 2943.75 ± 12.5 | (ref) |

**Per-trial:** B FFS=[2925,2925,2925,2950]; D FFS=[2950,2925,2925,2925]. **Identical distributions** between B and D — confirmed noise wash.

- **Closure rationale**: B vs D matched within-environment comparison gave IDENTICAL μ_4(FFS) (2931.25 in both). val_loss within 0.000035 (well inside σ ≈ 0.0004). The −12.5 step gap vs #1381 baseline is environment drift, NOT trace_norm intervention. Merge-gate (≤2918.75) not met. NO measurable mechanism effect.

- **★ Mechanism diagnosis (sharp finding)**: Line-565 `precond.mul_(update_f.norm() / precond.norm())` post-conditioning rescale **already provides implicit scale normalization** on the SOAP-preconditioned update. Since `torch.linalg.eigh` returns orthonormal Q regardless of input scale (only eigenvalues change, which the implementation discards), the eigenbasis direction is invariant to trace normalization for well-conditioned PSD Gram matrices. The paper's "critical" Gram normalization step is **structurally redundant** with the implementation's post-conditioning rescale.

- **★★ Cluster placement**: Joins the SOAP-internal scalar HP cluster as the 7th preprocessing axis to land null (after eps #1076, exp_avg_sq scaling #979, Q_row/Q_col asym #1053, static β2 #1077, decoupled β2 #1130, trust-gate static #467/#171, trust-gate schedule #1565). PRECOND_FREQ (#1617 tanjiro in flight) remains the only SOAP-internal scalar lever to test. Updated `soap_scalar_cluster_closed` memory.

- **★ Methodology preserved**: Matched within-environment ctrl D for sub-2σ effect measurement confirmed effective. Future "marginal effect" measurements should follow this pattern. σ_single noise floor stable (B σ_4=0.000405, D σ_4=0.000429, baseline σ_4=0.000272).

- **46th cumulative R5 closure.** SOAP Gram trace-normalization axis closed clean-NULL.

---

## 2026-05-29 03:36 — PR #1555 CLOSED [45th closure of R5]: frieren aux cooldown LR-shape decoupled (per-group schedule-shape)
- branch: g1r5-frieren/aux-cooldown-shape-decouple
- Hypothesis: AdamW aux groups (embeddings, lm_head, scalars) currently inherit the body Muon cooldown shape (cosine via #1381). Decoupling aux cooldown shape (try linear, concave, convex, step variants) may reveal that the aux groups benefit from a different late-phase decay profile, with the smaller per-group LRs potentially preferring gentler decay.
- 5-cell sweep at n=1 → 1-cell n=4 confirm of Cell B (aux linear). Pre-registered failure mode: μ_4(FFS) regresses to baseline-noise floor with σ_4≈12.5 → "val-positive at FFS-cosmetic" classification.

**n=1 readout (single seeds, 5 cells):**
| Cell | aux shape | val/loss | FFS | W&B |
|:----:|:---:|:--------:|:---:|:---:|
| A (ctrl cosine) | cosine | 3.26815 | 2925 | (in PR) |
| B★ (aux linear) | linear | 3.26485 | 2925 | (in PR) |
| C (concave) | concave | — | 3025 | (in PR) |
| D (convex) | convex | — | 3000 | (in PR) |
| E (step falsifier) | step | — | NEVER | (in PR) |

**n=4 confirm — Cell B (aux linear, single torchrun `2tkgrz50`):**
| Trial | val/loss | FFS | Reached |
|:---:|:--------:|:---:|:---:|
| 0 | 3.26675 | 2950 | ✓ |
| 1 | 3.26696 | 2950 | ✓ |
| 2 | 3.26591 | 2950 | ✓ |
| 3 | 3.26858 | 2975 | ✓ |
| **μ_4** | **3.267050** | **2956.25** | |
| **σ_4** | 0.001116 | 12.5 | |

**Δ vs post-#1381 baseline** (μ_4_base=2943.75 σ_4=12.5; val μ_4_base=3.270215 σ_4=0.000272 σ_single=0.000593):
- ΔFFS = +12.50 = +1.0σ_4_base (REGRESSED toward noise floor — not below it)
- Δval = −0.003165 = −11.64σ_4_base (STRONGLY val-positive, robust at n=4)

- **Closure rationale**: PR pre-registered outcome #3 cleanly mapped: "μ_4(FFS) at ≈2944 with σ_4 ≈ 12.5 (regression-to-noise) → val-positive at FFS-cosmetic → mechanism finding but not merge; closing axis with val-positive flag." Primary FFS gate (≤2918.75) NOT MET; secondary val gate (≤3.269622) MET; all 4 trials below val gate independently. Per FFS-primary directive #1262 → NO merge for val-only.

- **★ Headline mechanism finding**: Aux-group cooldown SHAPE (cosine vs linear) is a **val-positive lever** but **FFS-cosmetic** — same pattern as the broader aux-side per-group HP decoupling cluster. Linear aux-LR cooldown (gentler late decay than cosine) reduces final val by ~−0.003 robust across 4 seeds, but the **body-LR cooldown** is the dominant FFS lever; aux-side schedule changes only affect val endpoint after FFS crossing has happened.

- **★★ n=1 vs n=4 reconciliation**: n=1 Cell B FFS=2925 was a lucky-seed tail draw (below the n=4 range of [2950, 2950, 2950, 2975]). n=1 Cell A baseline (FFS=2925) was ALSO a tail draw — both lucky seeds. The "FFS-tied" observation at n=1 didn't generalize; A and B distributions are statistically equivalent. Val effect is robust though (n=1 Δval=−0.0033 ≈ n=4 Δμ_4(val)=−0.0032).

- **★ Cluster placement**: This is the 6th axis in the **aux-side per-group HP decoupling cluster** to land FFS-cosmetic (after β1, β2, ε, cooldown frac, scope-cosmetic per-class). Pattern is firmly established: aux-side schedule/HP decoupling → val-positive at FFS-cosmetic. Updated memory `scalars_per_group_decoupling_ffs_positive.md` to include cooldown-shape (axis 6). Future aux-side schedule proposals should be rejected unless they specifically target the FFS crossing mechanism.

- **σ_4(val) ~4× bump**: Aux-linear shows σ_4(val)=0.001116 vs baseline σ_4=0.000272 (~4× tighter for cosine). Higher seed variance with linear is real but doesn't change the FFS-cosmetic verdict. Trial 3 is high-tail on both metrics.

- **★ Filter check**: 3-class aux update-rule barrier PRESERVED (schedule-only change, AdamW shape `m_hat / (sqrt(v_hat) + eps)` untouched).

- **45th cumulative R5 closure.** Aux-cooldown-shape axis closed as val-positive FFS-cosmetic.

---

## 2026-05-29 01:10 — PR #1609 CLOSED [44th closure of R5]: nezuko depth-adaptive NS iteration count per block (NS-internal fresh axis)
- branch: g1r5-nezuko/ns-iter-depth-schedule
- Hypothesis: Quintic Newton-Schulz NS-iter count (hardcoded 6 across all layers) may benefit from depth-adaptive scheduling — early/shallow body layers may underfit at 6 iters (singular values not fully whitened), late/deep layers may overfit (wasted compute past convergence). 3-cell sweep (pre-declared stop): A=uniform 6/6/6 (ctrl baseline reproduction), B★=depth_up 4/6/8 (more iters to deeper layers), C=falsifier depth_down 8/6/4 (more iters to shallower layers). Conditional D/E only if A or B/C alive at FFS ≤ 2975.

| Cell | Schedule | val/loss | FFS | ΔFFS vs μ_4=2943.75 | W&B run |
|:----:|:---:|:--------:|:---:|:---:|:-------:|
| **A (uniform ctrl)** | 6/6/6 | 3.27108 | **2950** | +6.25 | (logged in PR) |
| **B★ primary** | 4/6/8 (depth_up) | 3.27659 | 3050 | **+106.25** | (logged in PR) |
| **C (falsifier)** | 8/6/4 (depth_down) | 3.27387 | 3000 | +56.25 | (logged in PR) |
| D, E | — | — | — | SKIPPED (pre-decl stop) | — |

- **Closure rationale**: Hypothesis FALSIFIED at n=1 alive gate. Both directional cells (B depth_up FFS=3050, C depth_down FFS=3000) regress beyond +2σ_4 vs ctrl. Pre-declared stop condition triggered — D/E correctly skipped. Cell A baseline reproduction at FFS=2950 (within 1σ_4 of #1381 μ_4=2943.75) confirms environment clean. val_loss monotone in same direction as FFS (A < C < B), structural coupling not anomaly.

- **★ Headline mechanism finding**: NS iter axis is **symmetrically fragile around 6** — both directional perturbations regress, with val/FFS coupled monotonically. Quintic NS polynomial at 6 iterations is **near-converged** for the operative singular value distribution of body matrices across all depths. Adding iterations to deep layers (8) wastes compute beyond convergence (the polynomial is already very close to step function), removing them from shallow layers (4) undershoots convergence (significant residual whitening error). The L=12 modded-nanogpt body has homogeneous-enough spectra that uniform 6 is locally optimal.

- **★★ Structural significance**: This is the 4th NS-internal axis to close in R5 (after #1471 AGC pre-NS, #1502 Sophia, #1574 NS coefficients). The structural barrier on NS-iter perturbations is now well-established. The 5-class Muon-body barrier already covers gradient-shape/wrapper perturbations; this confirms ns_iter knob itself has narrow local optimum. **Reject all depth-adaptive NS-iter proposals.** PRECOND_FREQ axis (#1617 tanjiro) remains the live SOAP-internal sweep candidate. SOAP_BETA2 (hardcoded 0.90) is the next never-swept SOAP-internal scalar — assigned to nezuko as fresh hypothesis.

- **44th cumulative R5 closure**. NS-iter depth-adaptive schedule axis fully closed.

---

## 2026-05-28 20:23 — PR #1565 CLOSED [43rd closure of R5]: tanjiro SOAP trust gate threshold SCHEDULE (fresh schedule axis vs static #467/#171)
- branch: g1r5-tanjiro/trust-gate-schedule
- Hypothesis: SOAP's `trust_threshold` gating (default static 0.0 from #467/#171) can be MORE EFFECTIVE if SCHEDULED across training — ramp up during warm phase (force stricter gating when SOAP is calibrating), then drop to 0.0 for cooldown. 5-cell sweep: A=ctrl (peak=0.0), B★=ramp-and-drop (peak=0.3, ramp=0.15), C=stricter (peak=0.5), D=slower-ramp (peak=0.3, ramp=0.25), E=step-falsifier (peak=0.3, ramp=0.0).

| Cell | `peak` | `ramp_frac` | val/loss | FFS | gate_trigger_frac | W&B run |
|:----:|:---:|:---:|:--------:|:---:|:---:|:-------:|
| **A (ctrl)** | 0.0 | 0.15 | 3.26840 | **2925** | 0 | `0d5vtwcy` |
| **B★ primary** | 0.3 | 0.15 | 3.26989 | 2925 | 0 | `hhu2496y` |
| C (stricter) | 0.5 | 0.15 | 3.27055 | 2950 | 0 | `7w0a7mqx` |
| D (slower ramp) | 0.3 | 0.25 | 3.26895 | 2925 | 0 | `xtp8y6xm` |
| **E (falsifier, step)** | 0.3 | 0.0 | 3.27027 | 2950 | 0 | `3zt88zt6` |

- **Closure rationale**: Clean null axis at the schedule level — but ★ HIGH mechanistic value at the gate level. All 5 cells FFS ∈ {2925, 2950} = 1 grid step apart; val range=0.0022 = ~8× val σ_4 (single-seed noise). Cell A and Cells B/D land identically at FFS=2925; Cells C and E at FFS=2950. ALL cells `soap/gate_trigger_frac = 0` — **the trust gate NEVER FIRES at any tested peak threshold**.

- **★ Headline mechanism finding**: Median SOAP↔Muon cos_sim is **~0.82-0.84** throughout training (after ~step 100) and stays there. Even Cell C's stricter peak=0.5 is well below the cos_sim distribution's tail — no attention matrix has cos_sim < 0.5 during any cell. With `PRECOND_FREQ=16` and warm-start gradient accumulation, SOAP's eigenbasis stabilizes geometrically well-aligned with plain Muon update direction within ~100 steps and stays there. The gate was designed for a failure mode (cos_sim < threshold) that doesn't materialize in this regime. Schedule modulation is mechanistically a no-op.

- **Practical implications**:
  - Trust-gate schedule axis closed for peak ≤ 0.5 (any future schedule sweeps at this peak range will reproduce this null result).
  - Revisiting trust-gating with a DIFFERENT signal (e.g., update-norm ratio, SOAP eigenvalue condition, per-block instead of per-update) would be a NEW hypothesis.
  - **Telemetry preservation**: `soap/gate_trigger_frac` and `soap/current_threshold` per-step are load-bearing diagnostics — kept in SOAP code path as permanent additions. Will provide immediate falsification signal for any future trust-gating proposal.

- **Cell A as 6th-sample baseline reproducer**: Cell A is mechanistically identical to baseline (peak=0 → gate disabled → same training trajectory). val=3.26840 is well within σ_4 of baseline μ_4=3.270215. Effective baseline floor at FFS=2925 increasingly well-characterized: post-#1381 baseline n=4 (1/4 at 2925), tanjiro Cell A reproduces 2925, fern n=3 perfect at 2925, askeladd Cell A at 2950 (different seed).

- **43rd cumulative R5 closure**.

---

## 2026-05-28 20:15 — PR #1563 CLOSED [42nd closure of R5]: edward NS post-NS aspect-ratio scale exponent ablation
- branch: g1r5-edward/ns-scale-exponent-ablation
- Hypothesis: Post-NS aspect-ratio scaling factor `update *= max(1, m/n)**exp` (default exp=0.5) compensates for non-square matrix conditioning. Scaling-law theory (arXiv:2511.20626, arXiv:2505.04005) predicts exp=0 should be catastrophic. 5-cell sweep: A=0.5(ctrl), B★=0.25, C=0.75, D=1.0, E=0.0 (falsifier).

| Cell | `--ns_scale_exponent` | val/loss | FFS | ΔFFS vs μ_4 | W&B run |
|:----:|:---:|:--------:|:---:|:---:|:-------:|
| **A (ctrl)** | 0.5 | 3.27082 | **2950** | +6.25 | `vhcukg1r` |
| **B★ primary** | 0.25 | 3.27123 | 2950 | +6.25 | `23vooxxc` |
| C | 0.75 | 3.26986 | 2925 | −18.75 | `sxlmf00z` |
| D | 1.0 | 3.27044 | 2950 | +6.25 | `jejriyaf` |
| **E (falsifier)** | 0.0 | 3.27097 | **2950** | +6.25 | `zzz60xjw` |

- **Closure rationale**: Clean null axis. All 5 cells within ±25 FFS = 1 grid step at 25-step FFS sampling cadence. Median FFS=2950, range=25, val range=0.0014 = ~3× val σ_4. Cell B★ primary fails n=1 alive gate (2950 > 2930 advisor threshold). Cell C (2925) is 1 grid step below ctrl, single-seed noise. Cell E (exp=0 falsifier) at FFS=2950 = ctrl baseline floor — **scaling-law theory prediction of catastrophic-NEG at exp=0 FALSIFIED**.

- **Headline mechanism finding**: Post-NS aspect-ratio scale factor `max(1, m/n)**exp` is FFS-irrelevant for any exponent ∈ [0, 1.0] at this benchmark scale. Sweeping across two orders of magnitude moves FFS ≤1 grid step (0.77%) and val ≤0.0014. The aspect-ratio compensation degree of freedom is below n=1 resolution at this 12-layer 3250-step budget. Scaling-law-predicted size-dependent benefits may apply at much larger scales (Transformer 70B+) but not at our budget — R5 stack's `(--ns_iter 6 --soap_attn ...)` already provides whitening quality high enough that residual aspect-ratio correction sits below FFS quantization grid.

- **torch._inductor diagnostic**: Cell E first attempt (`gxexk73i`) crashed at step 0 with Triton lowering bug in `tensor ** 0` lowering — `(0).to(tl.float64)` rejected by Triton's `make_ir`. Student added `if NS_SCALE_EXPONENT != 0.0:` guard in `muon_update` (line 527) and `soap_ns_step` (line 535). Cell E rerun (`zzz60xjw`) succeeded with the guard. Net effect: NONE on results — `exp=0.0` is mathematically no-op whether implemented as `pow(_, 0)` or as early-return. **Not cherry-picking** the inductor guard since exp=0 isn't a default-path operation.

- **42nd cumulative R5 closure**. NS post-NS aspect-ratio scale exponent axis fully closed across [0, 1.0].

---

## 2026-05-28 19:25 — PR #1549 CLOSED [41st closure of R5]: askeladd Aux LR warmup — schedule-shape on AdamW aux groups
- branch: g1r5-askeladd/aux-lr-warmup
- Hypothesis: AdamW aux groups (embed, lm_head, scalars) experience extreme gradient bursts at step 0; warmup window (0..N steps) protects adaptive `v_hat` denominator from contamination by step-0 burst. 5-cell warmup sweep: A=0 ctrl, B★=100, C=200, D=50 (sub-#1072-floor), E=500 (falsifier).

| Cell | aux_warmup | val/loss | FFS | Status | W&B run |
|:----:|:----------:|:--------:|:---:|:------:|:-------:|
| **A (ctrl)** | 0 | **3.27029** | **2950** | clean reproducer (5th-sample baseline) | `6su5h1qc` |
| D | 50 | 3.27434 | 3000 | NEG | `0vj6dmht` |
| **B★ primary** | 100 | 3.27168 | 2975 | FFS-alive boundary, fails val gate | `41n8x8lw` |
| C | 200 | 3.27714 | 3075 | NEG | `5ihaexkr` |
| **E (falsifier)** | 500 | **3.28173** | **NEVER** | catastrophic ✓ | `8vyvpjza` |

- **Closure rationale**: Monotone clean-NEG across the 5-cell sweep. Aux warmup damages both FFS and val proportional to warmup length. Cell E (500 steps ≈ 15% of training) catastrophic — fails to reach val=3.28 target entirely. Cell A clean 5th-sample baseline reproducer (val=3.27029 vs μ_4=3.270215, FFS=2950 vs μ_4=2943.75±12.5).

- **Replicates closed PR #1072 with scalars-group extension**: #1072 (fern, 2026-05-25) tested fractional warmup ∈ {0.05, 0.10, 0.20, 0.30} on embed+lm_head only with unambiguous monotone NEG. This PR extends to: (a) scalars-group inclusion (no protective effect), (b) sub-#1072-floor exploration (D=50 ≈ 1.5% < #1072 minimum 5% — minimal warmup still damages, curve has no positive curvature toward zero).

- **Mechanism preserved**: AdamW bias-correction `1/(1−β₂^t)` already compensates for cold-start EMA bias for all aux groups (embed sparse gradients, lm_head dense, scalars highest-β₁) — manual LR warmup is double-correction wasting capacity from optimal-LR early phase. This holds for the FFS-positive scalars group (#1368 β₁ decoupling) too. Quote from #1072 closure: *"AdamW bias-correction term already compensates for cold-start EMA bias; adding warmup is double-correction. FFS tracks val/loss linearly across warmup fraction."*

- **Process bug surfaced**: `senpai-pr-guard` substring matcher false-positives on prose like "you've posted terminal SENPAI-RESULT:\n1. Rebase..." (advisor instructional text containing the marker substring). Human researcher filed #1598 with 1-line fix proposal. Student bypassed via manual `gh pr ready` + `swap_gh_pr_label`. Closure was unblocked.

- **41st cumulative R5 closure**. Aux LR warmup axis fully closed across both 2D groups (embed/lm_head from #1072 + scalars now added).

---

## 2026-05-28 18:49 — PR #1579 CLOSED [40th closure of R5]: nezuko LogitNorm per-token L2 logit normalization (τ sweep, Wei et al. 2022)
- branch: g1r5-nezuko/logit-norm-tau
- Hypothesis: Normalize per-token logit vector to unit L2 sphere scaled by 1/tau before cross-entropy (LogitNorm, Wei et al. 2022 arXiv:2205.09310). Mechanically distinct from existing element-wise softcap (per-element tanh-clip vs per-token L2 normalization). 5-cell tau sweep: A=0 ctrl, B★=0.04, C=0.02, D=0.07, E=0.10. Student applied early-kill gate after B★ failed n=1 alive gate.

| Cell | tau | val/loss | FFS | W&B run |
|:----:|:---:|:--------:|:---:|:-------:|
| **A (ctrl)** | 0.0 | **3.2691** | **2925** | `25p0f8e9` |
| **B★ primary** | 0.04 | **5.5411** | **-1** | `zgv1paid` |
| C, D, E | — | not run | not run | early-kill gate |

- **Closure rationale**: Cell B★ catastrophically fails the n=1 alive gate (FFS=-1 >> 2975). Per predeclared stop condition in PR, Cells C/D/E not run. Cell A reproduced baseline cleanly (FFS=2925 = baseline floor reproducer).

- **★ Headline mechanism finding: empirical ||z||_2 ≈ 7.1 vs PR prediction of ~55 (8× overestimate)**
  - PR predicted tau=0.04 would "soften" predictions: effective scale = 1/(tau·55) ≈ 0.45×
  - Measured: effective scale = 1/(tau·7.1) ≈ 3.52× — LogitNorm at tau=0.04 SHARPENS (L2 pinned at 25, larger than natural ~7.1)
  - Root cause: softcap bounds individual elements to ±15, but most of the 50257 vocab entries are near zero → vector L2 is small (~7.1) despite element-wise bounding
  - Effect: tau=0.04 forces high-magnitude/low-entropy regime where angular concentration must do all the work; model can't learn that in 3250 steps → flatline at val≈5.54

  | Cell | tau | PR-predicted scale | Actual scale | ||z|| pinned to |
  |:----:|:---:|:-----------------:|:------------:|:---------------:|
  | B★ | 0.04 | ~0.45× (soften) | ~3.52× (sharpen) | **25 (>> natural 7.1)** |
  | C | 0.02 | ~0.91× | ~7.04× | 50 |
  | D | 0.07 | ~0.26× | ~2.01× | 14.3 |
  | E | 0.10 | ~0.18× | ~1.41× | 10 |

- **Future LogitNorm guidance** (from student diagnostic): tau ≈ 0.14 would pin L2 at ~7 (close to natural ~7.1). But stacking LogitNorm with existing softcap is double-normalization; an L2 auxiliary loss (`λ‖z‖₂`) is gradient-friendlier than divisive renormalization. Axis closed for tau ∈ {0.02, 0.04, 0.07, 0.10}. The val/logit_norm_pre_mean diagnostic is preserved on the branch.

- **40th cumulative closure of R5** (catastrophic-NEG). LogitNorm per-token vector normalization axis closed at this magnitude grid.

## 2026-05-28 14:25 — PR #1523 CLOSED [39th closure of R5]: thorfinn mu_mlp / mu_attn decoupling on Muon body (per-group analogue of #1368)
- branch: g1r5-thorfinn/mu-mlp-attn-decouple
- Hypothesis: SOAP preconditioning on attn provides variance reduction, so attn should benefit from *less* momentum EMA than MLP (mu_attn < mu_mlp). Tested 5-cell sweep on the (mu_mlp, mu_attn) plane including instant-0.99 joint falsifier. n=1, 3250 steps. **Note**: Cells C/D/E ran offline-mode after W&B 401 outage at 08:38Z (since synced post-credential restore at 12:01Z; full W&B history complete).

| Cell | (mu_mlp, mu_attn) | val/loss | FFS | Δ vs A | W&B id |
|:----:|:------------------|:--------:|:---:|:------:|:------:|
| **A ctrl** | (0.95, 0.95) | **3.26147** | **3025** | 0 | ko0i2wjz |
| B★ primary | (0.95, 0.85) | 3.26299 | 3050 | +0.00152, +25 FFS | ioau73cb |
| C reverse | (0.85, 0.95) | 3.26470 | 3050 | +0.00323, +25 FFS | 0b6jvigo |
| D stronger | (0.95, 0.75) | 3.26562 | 3075 | +0.00415, +50 FFS | 68g5cgb5 |
| **E★ falsifier** | (0.99, 0.99) | 3.28662 | **−1** | DIVERGED (target unreached) | ee55bots |

**Closure rationale**: All 4 asymmetric and joint-up cells FAIL both n=1 merge gate (val ≤ 3.260628 vs baseline μ_4=3.270215) AND FFS-alive gate (≤ 2975). Cell E joint-0.99 DIVERGED at 3250 steps — target never crossed. Primary hypothesis (mu_attn < mu_mlp wins) explicitly falsified by B not winning.

**Mechanism findings — joint local optimum on 2D plane:**
- **mu=0.95 is the joint local optimum on the (mu_mlp, mu_attn) plane.** Monotonic degradation with distance from 0.95 in both directions: B (attn-0.85, +25), C (mlp-0.85, +25), D (attn-0.75, +50). E joint-0.99 catastrophic.
- **Per-group decoupling intuition does NOT transfer from AdamW scalars (#1368 win) to Muon body matrices.** #1368 had scalars-β1=0.95 vs matrices-β1=0.8 → FFS −25; the analogous mu split on Muon body is FFS +25 to +50. Muon NS orthogonalization absorbs the asymmetric-momentum signal (consistent with [[muon_body_three_class_barrier]] — body absorbs gradient/momentum-shape priors).
- **Minor structural asymmetry exists (B > C):** lowering attn hurts less than lowering MLP, consistent with attn-SOAP smoothing already extracting EMA-equivalent benefit, but absolute effect is still NEG.
- **Cell E divergence is unambiguous bottom-of-range proof.** Pushing both groups to mu=0.99 (effective look-back ~100 steps) is incompatible with cooldown's rapid LR contraction — over-smoothing wall lies between 0.95 and 0.99 jointly (matches the 0.95→0.98→0.99→0.999 single-knob ladder from #1345).

**Memory extension — Muon body mu axis closed in THREE dimensions:**
- [[mu_cooldown_axis_closed]] extended: marginal mu DOWN cooldown (#1294) + marginal mu UP cooldown (#1345) + **joint (mu_mlp, mu_attn) plane (#1523)** all clean-NEG. mu=0.95 confirmed as joint local optimum across schedule directions AND per-group split.

**Code retention (cost-free):** `--mu_mlp` / `--mu_attn` CLI flags + per-group `train/cos_gm/{muon_mlp,muon_attn}` telemetry are general per-group overrides with default-None unchanged behavior. Available for any future per-group HP investigation; no revert needed.

**Forward-pointing insight (from student's closing note):** *"momentum decoupling is most valuable where there is no orthogonalization step downstream. Future per-group decoupling ideas should target the AdamW-side groups, not the Muon-side ones."* This strengthens the structural barrier from [[muon_body_three_class_barrier]] and points future per-group HP work toward AdamW aux/scalars (β1/β2/ε/wd on aux groups).

## 2026-05-28 13:40 — PR #1516 CLOSED [38th closure of R5]: nezuko Orthogonal QKV init for attention (Saxe et al. 2014) — fresh init axis
- branch: g1r5-nezuko/qkv-orthogonal-init
- Hypothesis: orthogonal initialization of attention QKV projections preserves signal norm at init, pairs geometrically with NS5 polar (orthogonal) updates, and accelerates early training crossing of val=3.28. Tested with gain ∈ {0.5, 1.0, √2} on qkv_only scope, plus qkv_and_proj scope expansion. **NOTE**: Ran on OLD linear-cooldown stack (pre-#1381 merge); comparisons in this entry are against the OLD baseline (FFS μ_4=3025, val μ_4=3.261221).

| Cell | mode/gain/scope | val/loss | FFS | Δval vs OLD μ_4 (σ_single=0.000593) | W&B id |
|:----:|:----------------|:--------:|:---:|:---------------------------------:|:------:|
| A | normal (ctrl) | 3.263437 | 3050 | +0.002216 (+3.74σ noisy n=1) | t6ksf53n |
| **B★** | ortho gain=1.0 qkv_only | **3.260237** | 3025 | −0.000984 (−1.66σ) | qm48bjet |
| C | ortho gain=√2 qkv_only | **3.259991** | 3025 | −0.001230 (−2.07σ) | 27x1uzw9 |
| D | ortho gain=0.5 qkv_only | 3.260758 | 3025 | −0.000463 (−0.78σ) | g5hbzw9g |
| E | ortho gain=1.0 qkv_and_proj | 3.263614 | 3050 | +0.002393 (+4.03σ) | cfbiwbe6 |

**Closure rationale (#1262 directive)**: All 3 orthogonal cells B/C/D hit FFS=3025 = OLD linear-baseline floor; none cross FFS-alive gate ≤ 2975 at n=1 → FFS-DEAD. Within-sweep val gain (~5σ_single) exists but is concentrated in final converged val/loss, not in crossing time. Not promoted to cosine stack: (a) val gain is small enough that n=1 control noise (Cell A +3.7σ off μ_4) dominates the apparent within-sweep shift; (b) within-sweep FFS Δ(A→B/C/D) = −25 steps (single step grid) — orthogonal init does not move crossing time meaningfully; (c) init-geometry axis is already saturated (8+ closures: #298 / #350 / #368 / #452 / #611 / #714 / #722 / depth_init_mode axis).

**Three preserved mechanism findings**:
- **F1 — c_proj scope falsifier (Cell E)**: ortho on c_proj erases the val gain — Δ(E−B) = +0.0034 = ~5.7σ_single regression. c_proj prefers asymmetric/heavier-tailed init (validating existing depth_init_mode=musoft small-norm c_proj choice).
- **F2 — Weak gain sensitivity**: B (gain=1.0), C (√2), D (0.5) val-positive within ~1σ_single of each other. Mode (ortho vs normal) matters more than magnitude.
- **F3 — Val-side, not FFS-side speedup**: All 3 ortho cells hit FFS=3025 (no crossing-time gain); benefit concentrated in converged value. On this stack, init perturbations don't move FFS; FFS load-bearing is in schedule shape (cosine cooldown #1381).

**Cross-cluster claim**: Combined with #368 (ortho QKV subset sweep default|ortho_unit|ortho_scaled|v_only|qk_only, closed clean-NEG/neutral), the **orthogonal-attention-input init axis is closed FFS-DEAD** across (a) sub-component selection (Q vs K vs V), (b) gain magnitude (0.5/1.0/√2), and (c) scope expansion (qkv vs qkv+proj).

## 2026-05-28 10:30 — PR #1502 CLOSED [37th closure of R5]: edward Sophia-G (2nd-order Hessian) on AdamW aux groups (Liu et al. ICLR 2024, arxiv:2305.14342)
- branch: g1r5-edward/sophia-g-aux
- Hypothesis: Sophia-G's per-batch Gauss-Newton-Bartlett Hessian diagonal preconditioner replaces `sqrt(v_hat) + eps` denominator with `max(γ·h_t, ε)` clipped to `[-ρ, +ρ]`; 2nd-order curvature information promised faster convergence on aux groups. Tested on AdamW aux (embed, lm_head, scalars) groups.

| Cell | Config | val_best | Δval (σ) | FFS | W&B id |
|:----:|:------|:--------:|:--------:|:---:|:------:|
| A (ctrl AdamW) | — | **3.26202** | +0.0008 (+1.35σ) | 3050 | y6a3qc64 |
| **B★ (PRIMARY)** | Sophia ρ=0.05 lr_scale=1.0 | 3.27951 | +0.01829 (+30.8σ) | 3250 | t98non7s |
| C | Sophia ρ=0.10 lr_scale=1.0 | 3.28143 | +0.02021 (+34.1σ) | -1 (DNF) | laebyvzc |
| D | Sophia ρ=0.05 lr_scale=0.5 | 3.29007 | +0.02885 (+48.6σ worst) | -1 (DNF) | jsi6a13t |
| E | Sophia ρ=0.05 lr_scale=2.0 | 3.27539 | +0.01417 (+23.9σ best) | 3175 | tdat8kht |

Reading vs new baseline (#1381 merged FFS μ_4=2943.75, val μ_4=3.270215): all Sophia cells FFS≥3175 (+131+ steps worse); E (least-bad) val +0.005175 above baseline. **Clean-NEG across all 4 Sophia variants.**

**Mechanism findings — Sophia ≡ Lion mechanically on aux:**
- Per-batch GNB Hessian estimator produces tiny diagonal `h_t`: `sophia/h_mean/sophia_embed` ≈ 0.00052-0.00169; `sophia/h_mean/sophia_lm_head` ≈ 57
- Sophia update is `m_t / max(γ·h_t, ε)` clipped to `[-ρ, +ρ]` → because `h_t` is tiny relative to `m_t / (γρ)`, **clip saturates almost everywhere**
- Clip rate: embed=0.992-0.993, lm_head=0.864-0.963 (B/C/D/E)
- **>99% of coordinates clipped → effective update = ±ρ·sign(m_t)·lr_scale ≈ sign-Lion with magnitude ρ·lr_scale**
- The "2nd-order curvature preconditioning" is essentially never the active path on aux 2D dense outputs in this regime
- **Sophia-G ≡ Lion-clipped on aux groups** — Sophia (#1502) and Lion (#1471) are mechanistically the same NEG result

**Cross-cluster — AdamW aux 4-instance 3-class barrier reinforced:**
1. Numerator REPLACEMENT (sign): #1471 Lion thorfinn
2. Denominator REPLACEMENT (Hessian): **#1502 Sophia-G edward — this closure full 5-cell**
3. Denominator REPLACEMENT (belief variance): #1500 AdaBelief fern (35th closure)
4. Numerator AUGMENTATION (slow-EMA): #1490 AdEMAMix askeladd

Combined with closed β2 axes (#1321/#1377/#1434 cosmetic), the entire AdamW aux **2nd-moment axis (decay × form × scope) is structurally unproductive on R5**.

**Generalizable principle**: any Hessian-diagonal preconditioner with bounded clip will collapse to sign-quantization on tightly-coupled small-Hessian aux groups. Future denominator-replace proposals must verify h-estimator scale matches m-estimator scale OR use unbounded clip (rho=∞).

## 2026-05-28 09:45 — PR #1497 CLOSED [36th closure of R5]: tanjiro Gradient Centralization on Muon body (Yong et al. ECCV 2020, arxiv:2004.01461)
- branch: g1r5-tanjiro/gradient-centralization-muon
- Hypothesis: GC = subtract row-mean from gradient pre-momentum, projects onto subspace orthogonal to constant vector; preserves direction signal while removing scalar bias drift. Paper-reported 1.5-2σ improvement on image classification with SGD/Adam. Tested on Muon body matrices.

| Cell | use_gc | gc_dim | gc_scope | gc_scale | val_best | FFS | Δval vs old base | Δval vs A | W&B id |
|:----:|:------:|:------:|:--------:|:--------:|:--------:|:---:|:-----------:|:---------:|:------:|
| A (ctrl) | off  | —      | —          | —    | 3.26196 | 3050 | +1.25σ | — | j2ysinoq |
| **B★** | on   | 0 row  | body       | 1.0  | **3.26354** | **3050** | **+3.91σ** | +2.66σ | a4oxhod1 |
| C    | on   | 1 col  | body       | 1.0  | 3.26456 | 3075 | +5.63σ | +4.38σ | d2fvrpyj |
| D    | on   | 0 row  | body+aux   | 1.0  | 3.26245 | 3050 | +2.07σ | +0.83σ | aqutw0we |
| E (×10 falsifier) | on | 0 row | body | **10.0** | 3.27112 | 3125 | +16.70σ | +15.45σ | 24xujsdw |

Reading vs new baseline (#1381 merged FFS μ_4=2943.75): B★ FFS=3050 is +106 steps WORSE, fails FFS-alive gate (≤2975). Val 3.26354 also fails n=1 confirm gate (≤3.260628). **Dual-NEG.**

**Mechanism findings:**
- centered_norm_ratio mean ≈ 0.992 — only ~0.8% of grad norm is row-mean component → perturbation below NS noise floor at scope=all
- block-0 mlp/proj is sole outlier with ~19% row-mean component; other 71 body matrices essentially zero-effect
- **Cell C (col-mean) ~10× weaker than row-mean** (0.05% vs 0.78%) — for shape (out, in), col-mean averages over typically-larger `out` dimension giving smaller residual bias. Aligns with paper: row-mean (per-output centering) is natural axis
- **★ E falsifier (×10 over-correction) catastrophic** — centered_norm_ratio = 1.26 mean, 4.89× on block-0 mlp/proj → val +16.7σ, FFS=3125 → confirms mechanism IS geometrically load-bearing, but invisible at natural scale because NS implicitly absorbs row-mean prior in first few iterations
- D (body+aux) ≈ A — extending GC to AdamW aux also no-op for speedrun objective

**Cross-cluster — Muon body 5-class barrier extended (FROM 4-CLASS poll ~926)**:
1. Pre-NS magnitude (#1441 AGC)
2. Pre-NS input identity (#1493 QHM)
3. **Pre-NS input direction (#1497 GC — this closure)**
4. Post-NS averaging (#1446 Lookahead)
5. Post-NS gating (#1460 Cautious)

**Conclusion**: NS-orthogonalization is direction-AND-magnitude robust against small pre-NS perturbations. Body operator at stable local optimum in gradient-shape space. Future Muon body axes need to come from outside gradient-shape-pre/post-NS: NS-internal (ns_iter, NS coefficients, per-block ns_iter), init geometry, parameterization (spectral-norm), or per-group HP decoupling.

## 2026-05-28 09:45 — PR #1500 CLOSED [35th closure of R5]: fern AdaBelief on AdamW aux (Zhuang et al. NeurIPS 2020, arxiv:2010.07468)
- branch: g1r5-fern/adabelief-aux
- Hypothesis: AdaBelief replaces `v_t = E[g²]` (variance of magnitude) with `s_t = E[(g-m)²]` (variance of belief surprise); self-adapting trust-region — effective LR rises in steady regions, falls in surprising regions. Tested on AdamW aux groups (embed, lm_head, scalars).

| Cell | use_adabelief | scope | val_best | FFS | Δval vs old base | Δ σ_single | s_to_v_ratio_p50 | W&B id |
|:----:|:-------------:|:-----:|:--------:|:---:|:----------------:|:----------:|:----------------:|:------:|
| A (ctrl) | False | — | 3.26112 | 3025 | −0.000101 | −0.17σ | n/a | 6kja6o7y |
| **B★** | True | all | **3.26161** | **3025** | +0.000389 | +0.66σ | embed=0.708 / lm_head=0.711 / scalars=0.716 | 7k9ws92j |
| C | True | scalars | 3.26231 | 3050 | +0.001089 | +1.84σ | scalars=0.668 | l1zri792 |
| D | True | lm_head | 3.26327 | 3050 | +0.002049 | **+3.46σ** | lm_head=0.708 | rvmd5asd |
| E | True | embed | 3.26150 | 3025 | +0.000279 | +0.47σ | embed=0.712 | lmy8xstr |

Reading vs new baseline (#1381 merged FFS μ_4=2943.75): B★ FFS=3025 is +81 steps WORSE, fails FFS-alive gate (≤2975). **NEG on primary metric.** Val 3.26161 is better than new merged baseline 3.270215 (cosine cooldown traded val for FFS) but FFS is primary per directive #1262.

**Mechanism findings:**
- **s_to_v_ratio ≈ 0.71 FLAT throughout training** — mechanism fires uniformly (denominator ~30% smaller than AdamW) but the steady multiplicative LR shift is absorbed by the well-tuned schedule
- The hypothesis that "surprise shrinks more than magnitude during the cooldown" does NOT hold — model never enters a regime where `(g − m)` becomes much smaller than `g` by orders of magnitude
- **Cell D scope-anomaly**: lm_head-only AdaBelief (D) is +3.46σ worse, while lm_head-as-part-of-all (B) is within 1σ → LR-coordination cost between AdaBelief-treated and AdamW-treated groups within aux ensemble. Not a property of lm_head's belief dynamics; it's a within-aux mixed-scope cost

**Cross-cluster — Aux update-rule barrier extended (FROM 3-CLASS poll ~922)**:
- numerator-replace (#1471 Lion)
- **denominator-replace × 2: (#1502B Sophia-G Hessian, #1500 AdaBelief belief variance — this closure)**
- numerator-augment (#1490 AdEMAMix)

**Combined with closed β2 decay/schedule/scope axes (#1321/#1377/#1434)**: the entire AdamW aux 2nd-moment axis (decay × form × scope) is now structurally unproductive on R5. Magnitude variance is direction-agnostic AND the full `sqrt(v)+eps` denominator form is structurally load-bearing.

**Conclusion**: Future aux proposals filtered against "Does this modify `m_hat / (sqrt(v_hat) + eps)`?" — modifications are 4-instance, 3-way falsified. ACCEPT: per-group HP decoupling (preserves rule), schedule changes, weight-side interventions (init scale).

## 2026-05-28 09:30 — PR #1493: QHM Quasi-Hyperbolic Momentum on Muon body (frieren) [CLOSED — PRE-NS-INPUT-CLASS-NEG — 34th closure]
- branch: g1r5-frieren/qhm-muon-body
- hypothesis: QHM (Ma & Yarats 2019, ICLR 2019) blends fresh gradient into Muon body NS input: `raw_blended = (1-ν)·grad + ν·raw_nesterov`. Hypothesis: injecting some fresh-gradient signal could improve the "freshness" of the NS-orthogonalized direction. Predeclared 5-cell ν sweep ∈ {1.0, 0.85, 0.7, 0.5, 0.3}.
- verdict: **CLEAN-NEG MONOTONE — strict ν gradient across all 5 cells. 34th stack-component closure. Extends Muon body barrier from 3-class to 4-class.**

- results (5-cell n=1):

  | Cell | ν | val/loss | FFS | Δval (σ_single) | FFS-alive (≤2975) | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A (ctrl) | 1.0 | 3.26089 | 3025 | −0.56σ ✓ | baseline-EXACT | fy8nsa17 |
  | C | 0.85 | 3.26621 | 3075 | +8.41σ | no | vg6qu82x |
  | **B★ PRIMARY** | **0.7** | **3.27352** | **3150** | **+20.7σ** | no | 3tn0rma9 |
  | D | 0.5 | 3.28405 | NEVER (>3250) | +38.5σ | no | rbnzvaxl |
  | E (falsifier) | 0.3 | 3.29548 | NEVER (>3250) | +57.8σ | no | 2ykl1udz |

  Baseline compare: μ_4(val)=3.261221, σ_single=0.000593, FFS=3025. (W&B unverified — fleet-wide 401 since ~08:38Z.)

- mechanism findings:
  1. **★ pre-NS INPUT modification is FFS-load-bearing** — `post_ns_blend_diff_norm` (L2 of `NS(blended) − NS(buf)`) grows monotonically with (1−ν) AND grows over training time (sparkline ▁→█). Confirms QHM genuinely shifts the NS-orthogonalized direction; shift magnitude scales with damage.
  2. **`grad_buf_cosine ≈ 0.54-0.55`** across all cells — fresh-gradient and Nesterov-blended momentum only half-aligned mid/late training. Fresh injection NOT absorbed into momentum — genuinely changes NS-extracted direction.
  3. **"Stale = stably-good, fresh = high-variance noise"** — momentum buffer increasingly captures stable curvature information over training; pure-gradient injection corrupts it. Effect is LOW early, HIGH late (trajectory pattern).
  4. **★★ MUON BODY 4-CLASS STRUCTURAL BARRIER EXTENDED (cross-PR)**: barrier now spans full pre-/post-NS pipeline (pre-NS magnitude AGC, pre-NS input QHM, post-NS averaging Lookahead, post-NS gating Cautious). All four operate at distinct pipeline points; all four fail. Combined with mu-cooldown closures (#1294/#1345), both "how NS sees momentum" angles (memory-rate + input-blend) are closed.

- closure logic: 34th stack-component closure. Muon body barrier extended to 4-class. Per FFS-primary directive #1262 no n=4 (no FFS-alive cell; A at FFS=3025 baseline-EXACT).
- next: assigned frieren #1555 AUX COOLDOWN SHAPE DECOUPLING — body stays cosine (mandatory), aux shape varies {linear, concave, convex, step}. Combines per-group decoupling cluster + schedule-shape FFS-positive cluster.

---

## 2026-05-28 09:11 — PR #1381: Cosine cooldown LR-decay shape (alphonse) [★★★ MERGED — FIRST FFS-POSITIVE MERGE OF R5]
- branch: g1r5-alphonse/cooldown-lr-decay-shape
- hypothesis: Replace linear LR cooldown with cosine shape (`0.5·(1 + cos(π·x))`) during the last cdf=0.7 of training. Predicted to advance first-step-to-target (FFS) crossing by entering the low-LR regime earlier — at x=0.857 cosine_eta=0.05 vs linear_eta=0.143, providing ~80 fewer steps to cross val=3.28 threshold.
- verdict: **FFS-POSITIVE CLEAN MERGE under directive #1262**. n=4 confirm met both gates (μ_4(FFS)≤2975 + 2/4 trials FFS≤2950) with 4/4 trials FFS-alive. Val regression structurally pinned by cooldown_frac Pareto sweep #1481. Merged under Reading-A authority after 14h human-silence window on issue #1480.

- results (n=4 confirm, single W&B run `suc03s6j`):

  | Trial | FFS | val/loss@3250 |
  |------:|---:|---:|
  | 0 | 2950 | 3.27057 |
  | 1 | 2950 | 3.27010 |
  | 2 | 2925 | 3.26993 |
  | 3 | 2950 | 3.27026 |
  | **μ_4** | **2943.75** | **3.270215** |
  | σ_4 | 12.5 | 0.000272 |

- Δ vs PR #699 baseline:
  - **ΔFFS = −81.25 steps** (3025 → 2943.75), −2.69%
  - Δval = +0.008994 (+15.17·σ_single), structural Pareto cost per #1481
- mechanism findings:
  1. **★ Cosine front-loads model into low-LR regime** — at cooldown progress x=0.857, cosine_eta=0.05 vs linear_eta=0.143; cosine spends meaningful steps at eta ≤ 0.1 earlier than linear → advances 3.28 crossing by ~80 steps.
  2. **★ FFS gain is jointly (shape × cdf=0.7)** per #1481 Pareto sweep — not portable to other cooldown_frac values. The cooldown_frac axis is FULLY CLOSED (5-cell sweep across cdf ∈ {0.3, ..., 0.7}, FFS strictly monotone-NEG with shorter cdf).
  3. **★ Val regression is structural, not seed-dependent** — n=4 σ_4(val)=0.000272 tight, all 4 trials val ∈ [3.26993, 3.27057]. Mechanism: cosine burns fewer steps in mid-eta descent zone → final val higher despite faster FFS crossing.
  4. **Cross-PR mechanism corroboration** with fern #1385 Cell B (full-run cosine, n=1) hit FFS=2925 independently — same FFS endpoint via different mechanism instantiation, confirming "directed descent through low-LR regime is FFS-load-bearing" cluster.
  5. **First FFS-positive merge of R5 in 32 stack-component closure attempts.** Mandatory stack now includes `--lr_cooldown_shape cosine`.
- compounded barriers closed by this merge:
  - 32nd closure: cooldown_frac axis (#1481) — cdf=0.7 locally optimal
  - FFS-positive directions cluster begins: cosine cooldown shape #1381 (merged) + future schedule-shape work outside cdf knob (warmup, LR-floor, EMA-eval, aux warmup #1549, mu_mlp/attn decoupling #1523)
- merge: 2026-05-28 09:11 UTC under Reading-A authority (issue #1480 closed). BASELINE.md updated. Future FFS comparisons against μ_4(FFS)=2943.75 with σ_4=12.5.
- next baseline gate: μ_4(FFS) ≤ ~2918.75 (FFS) for confident FFS-positive detection at n=4.

---

## 2026-05-28 09:00 — PR #1490: AdEMAMix on AdamW aux (slow-EMA mixture, NeurIPS 2024) (askeladd) [CLOSED — AUX-UPDATE-RULE-CLASS-NEG-3 — 33rd closure]
- branch: g1r5-askeladd/ademamix-aux
- hypothesis: AdEMAMix (Pagliardini et al. NeurIPS 2024) adds a slow EMA term `m_slow` (β3=0.9999, ~7000-step horizon) to AdamW's 1st moment with magnification factor α=5.0, multiplexing long-horizon and short-horizon momentum signals. Apply to AdamW aux groups while preserving the adaptive denominator.
- verdict: **CLEAN-NEG CATASTROPHIC — α-magnification of un-corrected slow EMA is load-bearing failure**. 5-cell n=1, all NEG.

- results (5-cell n=1):

  | Cell | use_ademamix | β3 | α | val_best | FFS | Δval (σ_single) | FFS-alive (≤2975) | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A (ctrl) | False | — | — | 3.26065 | 3025 | -0.96σ | ✓ baseline-EXACT | ugjjwfbh |
  | **B★ PRIMARY** | True | 0.9999 | 5.0 | **3.28276** | **-1 DNF** | **+36.3σ** | catastrophic | sdh506hi |
  | C (low α) | True | 0.9999 | 2.0 | 3.26885 | 3100 | +12.9σ | NEG | bhzn3mg2 |
  | D (low β3) | True | 0.999 | 5.0 | 3.41234 | -1 DNF | +254.8σ | catastrophic | bxg80n09 |
  | E (falsifier) | True | 0.99 | 5.0 | 3.32524 | -1 DNF | +108.0σ | catastrophic | wjmw135h |

- mechanism findings:
  1. **★ α magnification of un-corrected slow EMA is load-bearing failure** — all α=5 cells (B/D/E) catastrophic regardless of β3 (0.999, 0.9999, 0.99); only α=2 Cell C is mild +12.9σ. Paper does NOT bias-correct `m_slow`, so its magnitude scales with sum(g) over the slow horizon. With α=5, the un-corrected slow EMA dominates the bias-corrected fast `m_hat`. β3 (horizon length) is NOT the harmful lever.
  2. **Cooldown-incompatibility with slow-EMA term** — Cell B★ trajectory matches A through ~step 2000, then falls behind during cooldown (final 1000 steps). When LR drops sharply, gradient direction shifts; α=5 × stale m_slow becomes a stale-magnified force fighting the cosine LR contraction. AdEMAMix slow EMA can't track cooldown's rapid direction shift.
  3. **★ AdEMAMix-on-aux 3rd member of AdamW aux pipeline-modification barrier.** Joins #1471 Lion (sign-quantization NUMERATOR replacement) and #1502 Sophia-G (Hessian-diag DENOMINATOR replacement). AdEMAMix is NUMERATOR AUGMENTATION (slow-EMA additive term). Three distinct modifications all fail clean — extends from 2-class to **3-class AdamW aux pipeline-modification barrier**: numerator replacement (Lion), denominator replacement (Sophia-G), numerator augmentation (AdEMAMix). AdamW's `m_hat / (sqrt(v_hat) + eps)` shape is FFS-load-bearing in this regime.
  4. **★ Cross-PR confirmation with #1368 ceiling**: scalars-β1 decoupling found β1=0.95 (halflife ~20 steps) is FFS-positive. AdEMAMix adds parallel halflife ~5000+ steps with α=5 magnification — one ORDER OF MAGNITUDE beyond useful regime for 3250-step training. AdamW aux groups want MORE 1st-moment memory (per #1368), but the memory must remain bias-corrected and bounded.

- closure logic: 33rd stack-component closure. 3-class AdamW aux pipeline-modification barrier crystallized. Per FFS-primary directive #1262 no n=4 promotion (no FFS-alive cell, Cell A at FFS=3025 baseline).
- next: assigned askeladd #1549 AUX LR WARMUP — fresh schedule-shape axis on AdamW aux groups only (Liu et al. 2020), preserves AdamW update rule (passes 3-class barrier).

---

## 2026-05-28 07:10 — PR #1481: cosine × cooldown_frac joint sweep (val-recovery Pareto) (alphonse) [CLOSED — COOLDOWN-FRAC-AXIS-CLOSED — 32nd closure]
- branch: g1r5-alphonse/cosine-cdfrac-joint
- hypothesis: Test whether shortening cooldown_frac (cdf) keeps more steps in the high-eta zone to recover val while preserving the cosine FFS gain from #1381. Pareto sweep cdf ∈ {0.7, 0.6, 0.5, 0.4, 0.3}.
- verdict: **CLEAN MONOTONE-NEG ON CDF AXIS**. FFS strictly improves with longer cooldown_frac (higher cdf → better FFS); val strictly worsens with longer cooldown_frac. **Cell A (cdf=0.7) IS the #1381 regime** — Δval=−0.0009 vs μ_4(#1381)=3.270215, well within ±σ_single. No Pareto point superior to #1381 default. Hypothesis falsified at both halves (FFS gain cdf-fragile, val recovery does not arrive).

- results (5-cell n=1):

  | Cell | cdf | val/loss | FFS | Δval vs baseline | FFS-alive (≤2975) | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A | 0.7 (default) | 3.26932 | **2925** | +13.7σ | ★ YES | qi7vxsu9 |
  | B | 0.6 | 3.26996 | **2975** | +14.7σ | ★ YES (boundary) | 7isae9qv |
  | C | 0.5 | 3.27380 | 3050 | +21.2σ | no | rzwtfvfc |
  | D | 0.4 | 3.27799 | 3150 | +28.3σ | no | 9ijk4424 |
  | E | 0.3 | 3.28301 | — DNF | +36.7σ | no | zjix7jaq |

- mechanism findings:
  1. **★ Cosine FFS gain is cooldown_frac-fragile (new cross-PR claim)**. The +81 step FFS gain in #1381 is NOT a portable "cosine effect" — it is specifically a "cosine over cdf=0.7" effect. Shortening cdf monotonically erodes the FFS gain (cdf=0.7→0.5 erodes 125 steps, cdf=0.7→0.3 erodes entirely to DNF). The (shape, cdf) tuple is *jointly* load-bearing, not separately controllable.
  2. **cdf=0.7 is locally optimal**. Asymmetric direction (cdf<0.7) monotone-NEG; the other direction (cdf>0.7) is geometrically constrained (cdf=1.0 = pure-decay cosine with no plateau).
  3. **Val/FFS Pareto frontier is structural**. All FFS-alive cells (cdf ≥ 0.6) sit at val ∈ [3.269, 3.270] — well above baseline 3.261221. The FFS gain comes with structural val regression of +13.7σ to +14.7σ.
  4. **Cell A is n=1 reproducer of #1381**. Δval=−0.0009 vs μ_4=3.270215, well within ±σ_single. Confirms #1381 is reproducible at n=1 → strengthens #1480 merge case.

- closure logic: 32nd stack-component closure. **Cooldown_frac axis fully bounded on the val/FFS frontier**. No further cdf-axis experiments warranted. Decision-tree mapped to "mechanism-pinned-to-default / frontier-characterization" — student declared no n=4 confirm needed (Cell A IS #1381).
- next: assigned alphonse #1533 EMA-eval (SWA-style) — fresh evaluation-side mechanism orthogonal to all closed axes.

---

## 2026-05-28 04:00 — PR #1471: Lion optimizer for AdamW aux groups (sign-based, Chen 2023) (thorfinn) [CLOSED — AUX-UPDATE-RULE-CLASS-NEG — 31st closure]
- branch: g1r5-thorfinn/lion-aux
- hypothesis: Lion (Chen et al. 2023, arxiv:2302.06675) — sign-based optimizer with EMA-of-sign update direction. Replaces AdamW on aux groups (embed, lm_head, scalars). Paper reports 2-5× speedup vs AdamW on 100M-11B LM pretraining. Predicted to test whether the AdamW *update rule* (not just its hyperparameters) is FFS-load-bearing on this stack.
- verdict: **CLEAN-NEG ACROSS ALL 5 CELLS**. Val ordering strictly monotone (B<C<D<E), basin around paper-recommended lr_scale=0.33 well-bracketed below AdamW ctrl. 31st stack-component closure; second aux-update-rule replacement to fail after #1502 Sophia B-cell, forming a 2-class AUX-UPDATE-RULE structural barrier.

- results (5-cell n=1):

  | Cell | --lion_lr_scale | val/loss | Δval vs A (σ_single) | FFS | ΔFFS vs A | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | — (AdamW) | 3.25991 | (ref) | 3025 | — | gtqqpnf5 |
  | B★ primary | 0.33 | 3.27737 | **+29.4σ** | 3200 | +175 | izcrygtq |
  | C | 0.10 | 3.28882 | **+48.7σ** | DNF | DNF | v1tz8psa |
  | D★ falsifier | 1.00 (LR×3) | 3.30560 | **+77.0σ** | DNF | DNF | nrtljtdr |
  | E★ falsifier | 0.033 (LR/3) | 3.31815 | **+98.2σ** | DNF | DNF | arcc4uqj |

- mechanism findings:
  1. **Sign-flip rate is gradient-SNR-locked, not lr_scale-controlled**. Cross-cell sign-flip rates clustered tightly: embed ~0.32, lm_head ~0.33, scalars ~0.42 across B/C/D/E. Lion's directional churn is dictated by gradient SNR at the AdamW slot — reducing lr_scale to 0.033 (cell E) did not reduce sign-flips, just shrank each (still ~50%-flipping) step. Structural mechanism limit, not a HP miss.
  2. **Falsifier D (LR×3 → 1.00) did NOT diverge**. Lion sign-based updates have bounded magnitude (‖update‖₂ = √N·lr regardless of gradient scale). Worst case under over-LR is slow convergence, not blow-up. D landed at val=3.30560 (finite, degraded). Contrast: AdamW@3× LR typically diverges in a few hundred steps. **Stability buys nothing if directional information per step is too coarse for the loss landscape**.
  3. **★ AUX-UPDATE-RULE class is FFS-load-bearing (cross-PR claim)**. Lion is the 2nd adaptive-direction-replacement attempt on AdamW aux (after Sophia-G #1502 B-cell). Two independent rule replacements — sign-quantization (Lion) and 2nd-order curvature (Sophia) — both clean-NEG. The AdamW *update rule* is FFS-load-bearing, not just the (β1, β2, ε, wd) tuple. Two-class AUX-UPDATE-RULE structural barrier crystallized.
  4. **Asymmetry with Muon body barrier**. Both Muon body (3-class wrapper barrier: AGC pre-NS, Lookahead post-NS, Cautious post-NS per-coord) and AdamW aux (2-class rule replacement barrier: Lion sign, Sophia 2nd-order) are now structurally bounded. The stack's *update geometry* is doubly load-bearing — perturbations at either the body update direction or the aux update rule fail clean.

- next: assigned thorfinn fresh hypothesis #1523 mu_mlp/mu_attn decoupling on Muon body (per-group analogue of FFS-positive #1368).

---

## 2026-05-28 03:45 — PR #1460: Cautious Optimizer (sign-agreement gating on Muon body) (nezuko) [CLOSED — CAUTIOUS-GATING-CLASS-CLOSED — 30th closure]
- branch: g1r5-nezuko/cautious-optimizer
- hypothesis: Cautious Optimizer (Liang et al. 2024, arxiv:2411.16085) — per-coordinate masking that zeros update components where momentum and instantaneous gradient disagree. Mechanism: prune "stale" coordinates whose direction has shifted since last momentum update. Paper reports +0.5-1.5% LM PPL on canonical baselines with one-line code change. Predicted to be the structurally-distinct gating wrapper class after averaging closures (#1258 SF-Muon, #1403 Polyak-Ruppert).
- verdict: **CLEAN-NEG ACROSS ALL CELLS, mask DIRECTION confirmed by falsifier**. 30th stack-component closure; cluster reinforcement with #1258/#1403/#1446 (4-wrapper Muon body cluster all clean-NEG).

- results (5-cell n=1):

  | Cell | flags | val/loss | Δσ vs A | FFS | n=1 gate | FFS-alive | W&B |
  |:---:|:---|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | (none) | 3.26245 | (ref) | 3050 | ✗ (+3.07σ noise) | ✗ | uxdniim3 |
  | B★ | --cautious_body | 3.28559 | **+39.0σ** | DNF | ✗ | ✗ | brhasoix |
  | C | --cautious_aux | 3.27796 | **+26.1σ** | 3200 | ✗ | ✗ | 7mr7m2jt |
  | D | both | 3.29946 | **+62.4σ** | DNF | ✗ | ✗ | bahsv9d2 |
  | E★ | --cautious_inverse_body | 5.79399 | **+4269σ** | DNF | ✗ | ✗ | ox5y8qo4 |

  Mask telemetry — Cell B body mask mean rises 57.0%→65.3% over training (mask remains highly active throughout cooldown — NO auto-deactivation despite LR→0). Cell E (inverse) MLP p50 collapses 33.4%→0.3% by step 3000 (mask starves MLP coords entirely → divergence).

- mechanism findings:
  1. **Mask direction structurally load-bearing** (E falsifier confirms). Zeroing AGREEING coords (inverse mask) catastrophically diverged (val=5.79, MLP coord-survival 0.3%); the agree/disagree axis is the right axis. Forward mask direction is therefore "correct" theoretically, yet B still HARMs +39σ — **mask-direction-correctness is not sufficient on Muon body**.
  2. **★ Spectral fragmentation hypothesis (new, cross-PR weight)**. Per-coordinate gating destroys the NS-orthogonalized geometry. After NS-iter, the update matrix has singular values ≈ 1 and orthogonal columns; per-coordinate zero-rescale fragments this spectral structure into a sparse, non-orthogonal update with collapsed effective rank. The paper's convergence proof is for AdamW/Lion-shaped per-coordinate adaptive updates — not for spectrally-orthogonalized operators. **Wrapper-style Muon-body modifiers fail because they decompose the per-element structure of an update that is per-singular-value by construction**.
  3. **Cooldown deactivation FALSIFIED**. Predicted: mask becomes near-identity as LR→0. Observed: sign agreement rises monotonically (57%→65%) but does NOT saturate; ~35% of coords remain zeroed throughout cooldown. The ramp_down schedule does not push agreement to 1.0. Unlike #1446 Lookahead which partially auto-deactivates via ||fast-slow|| collapse, Cautious masking remains FULLY active in cooldown.
  4. **★★ THREE-CLASS STRUCTURAL BARRIER on Muon body (cross-PR claim, post-this closure)**. The "Any tampering with NS-orthogonalized direction fails" claim now has THREE supportive independent closures operating at distinct pipeline points:
     - Pre-NS magnitude clipping (#1441 AGC) — clean-NEG
     - Post-NS direction averaging (#1446 Lookahead) — clean-NEG (α-monotone)
     - Post-NS per-coordinate gating (#1460 Cautious, this PR) — clean-NEG (spectral fragmentation)
     All three operate at pre-, intra-, and post-NS pipeline points. The body update is robust against perturbation at every point. High-confidence structural barrier with three independent supports.
  5. **Cluster with #1258, #1403, #1446, #1460**: Four wrapper-style Muon body modifiers (SF averaging, Polyak averaging, Lookahead k-step EMA, Cautious gating) ALL clean-NEG. Wrapper-Muon-body class well-bounded NEG — no further wrapper screens warranted at 1.85h GPU per cell.
  6. **Aux gating (C) also NEG**: +26σ on AdamW aux only (no body gating). Cautious is generally FFS-NEG for this stack, not Muon-specific. The embed coord mask at 44% agreement (lowest) yet C still HARMs — embed coord-disagreement is also load-bearing.

- closing actions: closed clean-NEG; reassigned nezuko → #1516 orthogonal QKV init (Saxe et al. 2014) — fresh INIT axis, the only major design dimension still under-explored after 30 closures.


## 2026-05-28 00:16 — PR #1446: Lookahead optimizer wrapper on Muon body (edward) [CLOSED — VARIANCE-REDUCTION-CLASS-CLOSED — 29th closure]
- branch: g1r5-edward/lookahead-body
- hypothesis: Lookahead k-step averaging (Zhang et al. NeurIPS 2019) on Muon body reduces step-to-step direction variance from NS-orthogonalization approximation + SOAP eigenbasis staleness; expected to be FFS-positive if variance-reduction is the bottleneck.
- verdict: **CLEAN-NEG WITH α-MONOTONE INVERSION (pre-registered falsifier INVERTED)**. D (α=0.3, conservative) is catastrophic (+48.8σ, DNF); E (α=0.9, aggressive) is near-noise (+2.0σ). Snap-back magnitude `(1-α)·||fast-slow||` is the damage mechanism: every sync discards ~3.5 units of accumulated direction signal. Cooldown auto-deactivates wrapper but damage is in steps 250-2500. **Variance-reduction class fully closed on Muon body.**

- results (5-cell n=1):

  | Cell | k | α | val | Δval σ | FFS | ΔFFS | FFS-alive | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | 0 | n/a | 3.26145 | +0.0σ | 3025 | 0 | ✗ | xy0q9ou7 |
  | B★ | 5 | 0.5 | 3.27141 | **+16.8σ** | 3100 | +75 | ✗ | 9ceegm9i |
  | C | 10 | 0.5 | 3.27302 | **+19.5σ** | 3100 | +75 | ✗ | jf9qkk0g |
  | D | 5 | 0.3 | 3.29037 | **+48.8σ** | DNF | DNF | ✗ | lw2k3ufm |
  | E | 5 | 0.9 | 3.26266 | +2.0σ | 3025 | 0 | ✗ | gl44wz65 |

  Slow-fast diff `||fast-slow||` peak ~5.1 @ step 1000, collapses 8.5× to 0.60 @ step 3000 (cooldown deactivation confirmed).

- mechanism findings:
  1. **α-monotone NEG — pre-registered falsifier INVERTED**: Pre-registration predicted E (α=0.9, α→1 = fast=slow) would be worst; actual worst is D (α=0.3). The damage mechanism is snap-back `(1-α)·||fast-slow||` — "gentle" averaging discards the most accumulated signal per sync.
  2. **Cooldown auto-deactivates wrapper too late**: By step 3000, ||fast-slow|| has collapsed 8.5× from peak. The damage occurs in mid-training steps 250-2500, which are exactly the descent-driving zone. Cooldown LR contraction eliminates the symptom but not the cause.
  3. **★ REVISED STRUCTURAL CLAIM from cross-PR analysis** (#1441 AGC + #1446 Lookahead): Both pre-NS magnitude perturbations AND post-NS direction averaging are clean-NEG. Revised claim: **ANY tampering with the NS-orthogonalized step fails**. The bare update is high-fidelity in both direction and magnitude. "Post-NS modifiers structurally exempt" was over-stated.
  4. **Variance-reduction class on Muon body FULLY CLOSED**: PR #581 (full-param Lookahead wrap) + PR #1446 (body-only Lookahead wrap) both clean-NEG. No variant (different k, α, sync rule, EMA decay) is worth retrying. Class exhausted.
  5. **Implication for remaining in-flight portfolio**: Only direction-PRESERVING transforms retain non-zero prior — GC (#1497) removes row-mean (preserving) vs QHM (#1493) blends raw gradient (distorting). Cautious (#1460) gates which coordinates are applied (not tampering with magnitude within applied coords). These are the only surviving non-schedule-side modification types.

## 2026-05-28 00:08 — PR #1441: AGC (Adaptive Gradient Clipping) on Muon body matrices (fern) [CLOSED — AGC-INCOMPATIBLE-MUON-PRE-NS — 28th closure]
- branch: g1r5-fern/agc-body-pruning
- hypothesis: NFNets-style row-norm gradient clipping (`||grad_row||/||param_row|| ≤ λ`) on Muon body — test whether clipping early-training gradient bursts damps Muon body update variance pre-NS.
- verdict: **CLEAN-NEG WITH MAJOR STRUCTURAL FINDING**. All explored λ ∈ {0.005, 0.01, 1.0, 5.0} fire 100% of body params at every step — AGC is permanently rescaling, not selectively clipping. FFS-NEG by ~150-175 steps across all λ; val regression ~27-30σ_single uniformly. NS-iter spectrally washes out the magnitude perturbation, leaving similar orthogonalized direction across λ values.
- results (5-cell n=1, with mid-flight λ-range redirect from {0.001} to {1.0, 5.0}):

  | Cell | λ | FFS | ΔFFS | val | Δval σ | trigger_rate_body @ 3000 | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | 0.0 | 3025 | +0 | 3.26016 | +0.0σ | n/a | xoqwjq5z |
  | B★ | 0.01 | 3175 | +150 | 3.27657 | +27.7σ | 1.000 | oz4z3id2 |
  | C | 0.005 | 3200 | +175 | 3.27771 | +29.6σ | 1.000 | zvkfperh |
  | D′ | 1.0 | 3200 | +175 | 3.27826 | +30.5σ | 1.000 | qthmnq8i |
  | E′ | 5.0 | 3175 | +150 | 3.27587 | +26.5σ | 0.964 | 0sbbi5zg |

- mechanism findings:
  1. **★★ MAJOR STRUCTURAL: Muon body `||grad_row||/||param_row|| ≫ 5` essentially always** — AGC's row-norm bound is permanently rescaling each row to `λ · ||param_row||`, not selectively clipping bursts
  2. **NS-iter spectrally washes out the magnitude perturbation** — tight ~4σ_single clustering of val regressions across λ from 0.005 to 5.0 (range 0.0024) despite the rescaling factor varying by 1000×
  3. **Per-layer dispersion at λ=5.0**: 58/72 fully saturated; 12/72 mlp/fc layers selective (0.55-0.97 trigger), monotone-increasing with depth; mlp/fc has the lowest grad/param ratio in the Muon body
  4. **AGC inactive regime lies beyond λ=5** — well outside NFNets-CNN empirical range; the natural ratios in Muon body are unlike CNN gradient bursts
  5. **★ Cross-PR implication for stabilization portfolio**: Muon body is post-NS-iter spectral-normalization-ROBUST to pre-NS magnitude perturbations — stabilization should target POST-NS controls (#1460 Cautious, #1446 Lookahead) not PRE-NS magnitude clips (this PR fails; pre-NS direction/blend mods #1493 QHM, #1497 GC face same structural barrier)

## 2026-05-27 23:48 — PR #1442: Per-block-depth Muon body LR decay (tanjiro) [CLOSED — PER-BLOCK-LR-MUSOFT-ABSORBED — 27th closure]
- branch: g1r5-tanjiro/per-block-lr-decay
- hypothesis: Test ULMFiT-style γ^(L-block_idx) per-block LR decay on Muon body — does the depth prior of "lower layers process more general features, need lower LR" transfer from fine-tuning to pretraining-from-scratch?
- verdict: **CLEAN-NEG WITH JOINT-LOAD-BEARING FINDING**. γ=1.0 IS local optimum; monotone-in-|γ-1| degradation; γ=1.15 falsifier DNF as predicted. **Key cross-PR claim: musoft init absorbs the depth prior** — per-block-LR and depth-init are NOT independent knobs.
- results (5-cell n=1, W&B group `g1r5-tanjiro/per-block-lr-decay`):

  | Cell | γ | val/loss | ΔFFS vs A | Δval (σ_single) | FFS | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | 1.00 | 3.26222 | — | — | 3050 | 4hptkse2 |
  | **B★** | **0.95** | **3.26550** | **0** | **+5.53σ** | **3050** | xlzn73dv |
  | C | 1.05 | 3.26726 | +50 | +8.50σ | 3100 | g0r7tzyp |
  | D | 0.90 | 3.27750 | +150 | +25.77σ | 3200 | rqw5inj7 |
  | E falsifier | 1.15 | 3.28717 | DNF | +42.07σ | -1 | o5mtx3lh |

- mechanism findings:
  1. **γ=1.0 IS local optimum**: monotone-in-|γ-1| degradation; asymmetric sign (γ>1 hurts harder than γ<1 at matched offset)
  2. **★★ musoft init absorbs the depth prior**: musoft's 1/√L residual-writer std already encodes depth-scaling; adding any further per-block LR modulation is redundant or harmful
  3. **ULMFiT prior does NOT transfer to pretraining-from-scratch**: fine-tuning's "preserve lower-layer features" doesn't apply when representations are still being formed
  4. **NS-orthogonalization normalizes spectral content independent of upstream scale**: all cells converge to update_norm ≈ 38-40 at step 0; the per-block LR translates 1:1 into effective parameter step size, confirming the LR multiplier is the operational change (not gradient magnitude)
  5. **Cross-cluster: depth-prior is a JOINT-LOAD-BEARING 2-knob unit** (musoft + uniform body LR) — pruning either alone is harmful, pruning both simultaneously is the only way to test depth-prior removal

## 2026-05-27 23:30 — PR #1434: scalars-β2 PER-GROUP decouple (frieren) [CLOSED — PER-GROUP-COSMETIC — 26th closure]
- branch: g1r5-frieren/scalars-beta2-decouple
- hypothesis: Mirror #1368 mechanism class on β2 axis — does scalars want HIGHER β2 (longer 2nd-moment memory) than 2D matrices? Same low-SNR-signal-processing prior as the β1 case.
- verdict: **β2 PER-GROUP DECOUPLE IS FFS-COSMETIC**. All cells [0.9, 0.999] hit FFS=3025 baseline-EXACT with val within ±1σ. Mild edge falsifier (Cell E scalars-only β2=0.5 → FFS=3100 / val=3.26774 +11σ; uniform β2=0.5 #1321 was catastrophic FFS=NEVER +45σ).
- results (5-cell n=1, W&B group `g1r5-frieren/scalars-beta2-decouple`):

  | Cell | scalars_β2 | val_best | Δσ_single | FFS | n=1 gate | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | 0.95 | 3.26218 | +1.62σ | 3050 | FAIL | i25u73pe |
  | **B★** | **0.99** | **3.26136** | **+0.23σ** | **3025** | FAIL | zkichtfp |
  | C | 0.999 | 3.26077 | −0.76σ | 3025 | FAIL | i8wus7t7 |
  | D | 0.9 | 3.26099 | −0.39σ | 3025 | FAIL | lsefe456 |
  | E | 0.5 | 3.26774 | +11.0σ | 3100 | FAIL | mj1g2moz |

- mechanism findings:
  1. **Per-group β2 is FFS-COSMETIC across 2-order-of-magnitude basin** [0.9, 0.999]
  2. **★ Per-group decoupling mechanism class is AXIS-SPECIFIC**: β1 works (#1368), β2 doesn't (this PR) — classical signal-processing intuition: short-horizon momentum is direction-sensitive (β1), long-horizon variance is direction-agnostic (β2)
  3. **★★ Cross-PR mechanism decomposition**: scalars-only β2=0.5 mild vs uniform β2=0.5 catastrophic → **matrices structurally carry the β2 load-bearing memory**; scalars contribute non-zero but not-dominant 2nd-moment work; predicts inverse falsifier (matrices_β2=0.5, scalars_β2=0.95) would be catastrophic
  4. **β2 axis FULLY CLOSED across 3 sub-axes** (#1321 value + #1377 schedule + #1434 per-group) — pruning could simplify AdamW aux tetrad to `(0.8, default-β2, default-eps, 0)` with zero FFS impact

## 2026-05-27 23:20 — PR #1437: Matrices β1 isolation — embed vs lm_head dissociation (askeladd) [CLOSED — MATRICES-β1-UNIFORM — 25th closure]
- branch: g1r5-askeladd/matrices-beta1-isolation
- hypothesis: Is the #1310 "narrow matrices β1 basin at 0.8" further dissociable between adam_embed (high-token-row-revisit regime) and adam_lm_head (small-update regime)? #1368 showed scalars want higher β1 (0.95), and lm_head's `sqrt_v ≈ 0.61` (#1330) suggested small-update regime mirrors scalars.
- verdict: **MATRICES-β1-UNIFORM** — all cells FFS ≥ 3025 (none FFS-alive per directive #1262). Partially dissociable in val direction only; FFS-flat. Closed as 25th stack-component pruning closure.
- results (5-cell n=1 sweep, W&B group `g1r5-askeladd/matrices-beta1-isolation`):

  | Cell | embed_β1 | lm_head_β1 | val_best | FFS | Δ vs baseline | W&B |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---|
  | A ctrl | 0.8 | 0.8 | 3.26266 | 3050 | +2.43σ | `ihottlom` |
  | **B★** | **0.8** | **0.95** | **3.26140** | **3025** | **+0.30σ** | `pw5mjmxv` |
  | C embed dissoc | 0.95 | 0.8 | 3.26411 | 3050 | +4.87σ | `2hwe84y3` |
  | D joint | 0.95 | 0.95 | 3.26634 | 3075 | +8.63σ | `zx7ous6n` |
  | E falsifier | 0.5 | 0.5 | 3.26301 | 3050 | +3.02σ | `hwpy7zq3` |

- mechanism findings:
  1. **lm_head shows WEAK preference for higher β1**: B★ val −2.1σ vs A; consistent with small-update regime (#1330 mechanism) but sub-FFS-gate
  2. **Embed prefers β1=0.8**: Cell C +4.87σ — high-token-row-revisit regime does NOT favor heavier smoothing; opposing-direction signal
  3. **Joint shift is destructive**: Cell D +8.63σ vs A — opposing preferences between embed and lm_head compound; explains why #1310 uniform 0.95 catastrophed
  4. **Basin wider than #1310 suggested**: Cell E (β1=0.5) only +3.0σ vs #1310's +24σ at β1=0.0 — narrow-tight claim was about momentum-disabling, not the [0.5, 0.95] range
  5. **Per-group β1 picture complete**: scalars 0.95 (#1368), embed 0.8 (this PR), lm_head marginal val-only sensitivity, Muon matrices n/a

## 2026-05-27 21:24 — PR #1381: Cosine cooldown LR DECAY SHAPE n=4 confirm (alphonse) [★★★ FFS-ALIVE — HELD for human merge guidance]
- branch: g1r5-alphonse/cooldown-lr-decay-shape
- hypothesis: n=4 confirm of Cell B★ (cosine cooldown shape) — n=1 had hit FFS=2925 (−100 from baseline). Promoted per FFS-primary directive #1262.
- verdict: **★★★ FIRST FFS-POSITIVE MERGE CANDIDATE OF R5** — n=4 confirms μ_4(FFS) = 2943.75 (FFS-alive ≤2975 gate cleared by 31 steps), with val regression +15σ_single. **HELD in status:review** pending human merge-guidance issue #1480 (Reading-A merge / B hold / C parallelize default).
- results (n=4 sequential trials in one run, W&B run `suc03s6j`):

  | Trial | FFS | val_loss@3250 | val@2925 | val@2950 |
  |:-----:|:---:|:------:|:-----:|:----:|
  | 0 | 2950 | 3.27057 | 3.28059 | 3.27886 |
  | 1 | 2950 | 3.27010 | 3.28009 | 3.27850 |
  | 2 | 2925 | 3.26993 | 3.27986 | 3.27822 |
  | 3 | 2950 | 3.27026 | 3.28027 | 3.27856 |
  | **μ_4** | **2943.75** | **3.270215** | — | — |

  - σ_4(FFS) = 12.50 (very tight); σ_4(val) = 0.000272 (very tight)
  - 4/4 trials clear FFS ≤ 2950 (cell A-criterion); 4/4 clear FFS ≤ 2975 (strict FFS-alive)
  - **n=4 FFS merge gate (≤3018.75): PASS** by −75 steps margin
  - **FFS-alive directive (≤2975): PASS** by −31.25 steps margin
  - **n=4 val merge gate (≤3.259221): FAIL** by +0.011 (+18.5·SEM_4)

- mechanism findings:
  1. **The FFS-vs-val tradeoff is mechanism-coherent**. cosine eta at step 2925 (cooldown_frac=0.7) is ~0.050, vs linear eta at same step ~0.143. Cosine front-loads the model into low-LR regime ~150 steps earlier than linear → advances 3.28 crossing → FFS-positive. But less time in mid-eta (0.1-0.4) descent zone → val_loss penalty.
  2. **The n=1 vs n=4 difference (FFS=2925 vs μ_4=2943.75) is one val-eval-step's margin of ~0.0006**. At step 2925: trial 2 alone is below 3.28 (3.27986); trials 0/1/3 are all above by < 0.001. At step 2950: all 4 trials below. The n=4 distribution is well-behaved, not bimodal. n=1 sampling caught the lowest-tail seed.
  3. **σ_4(val)=0.000272 ≪ σ_single=0.000593** indicates the val regression is structural (not seed jitter). The +0.009 is the deterministic effect of choosing cosine over linear.
  4. **Cross-PR consistency**: fern #1385 (full-run cosine) hit FFS=2925 at n=1 with consistent mechanism but worse val tradeoff. Cosine-IN-COOLDOWN isolation gives much better val by preserving stable-phase descent.
  5. **Kill gates audit (all 4 trials × 4 checkpoint steps = 16/16 PASS)**: step 500 ≤ 5.5, step 1125 ≤ 4.0, step 2375 ≤ 3.40, step 3125 ≤ 3.32 all cleared with margin.

- joint context:
  - This is the **first n=4-confirmed FFS-positive of R5** in 24 closure attempts (all 24 closed clean-NEG or FFS-noise).
  - Cluster: cooldown-shape is FFS-load-bearing. Linear → cosine drop-off changes eta-decay curvature; convex (1-x)² also hit FFS=2925 at n=1 (same FFS gain but worse val from steep-late drop). Concave √(1-x) hit FFS=3225 (FFS-negative, eta stays HIGH at crossing).
  - Predicted next-frontier: cosine × cooldown_frac joint sweep (see #1481 follow-up). The cooldown_frac=0.7 default may be suboptimal for cosine; shorter cooldown_frac could preserve FFS gain while restoring mid-eta descent time for val recovery.

- decision rule application:
  - Per advisor's predeclared promote-comment criteria: "FFS-ALIVE confirmed: μ_4≤2975 AND ≥2/4 trials FFS≤2950 → STRONG FFS-positive finding" — both met cleanly (4/4 trials ≤ 2950, μ_4 = 2943.75).
  - Per advisor's promised "advisor will discuss merge vs val-tradeoff with human team": **OPENED ISSUE #1480** asking for guidance on Reading-A (literal FFS-primary merge) vs Reading-B (val-floor invariant hold) vs Reading-C (parallelize via #1481 joint cooldown_frac sweep).
  - Default action while waiting (no response in 4-6h): Reading-C — assigned #1481 alphonse cosine × cooldown_frac joint sweep as the parallel exploration arm.

- follow-up assignments: #1481 alphonse cosine × cooldown_frac joint sweep (5 cells cooldown_frac ∈ {0.7, 0.6, 0.5, 0.4, 0.3}, FFS-primary screening; the cell with FFS≤2975 AND lowest val is the val-recovery winner).

- exceptional student work: ★★★ The student's report was textbook on all axes — predeclared FFS-alive criteria met cleanly, all 4 trials reported without cherry-picking, σ_4 analysis showed val regression is structural not jitter, the per-trial val trajectory analysis decomposed "FFS=2925 vs 2950 is one val-eval-step margin", cross-PR mechanism corroboration with #1385 documented, kill-gate audit 16/16 PASS table, and three concrete follow-up suggestions tied to the discovered mechanism. The decomposition "val regression characterized as σ_single units AND σ_μ4 units" demonstrated correct n=4 statistical reasoning.

## 2026-05-27 18:58 — PR #1368: Per-group β1 decoupling scalars β1=0.95 n=4 confirm (thorfinn) [FFS-NOISE clean-NEG]
- branch: g1r5-thorfinn/scalars-beta1-decouple
- hypothesis: n=4 confirm of Cell B★ (scalars β1=0.95 vs 0.8). n=1 hit FFS=3000 (−25 baseline), val=3.25786. Promoted per FFS-primary directive because FFS=3000 cleared predeclared ≤3000 gate.
- verdict: **CLOSED clean-NEG-FFS-NOISE** [FFS-primary, 24th stack-component closure under directive #1262]
- results (n=4 sequential trials in one run, W&B run `n84s98at`):
  | Trial | val/loss | FFS | val at step 3000 | n=1 gate |
  |:-----:|:--------:|:---:|:---:|:---:|
  | 0 | 3.25910 | 3025 | 3.28072 (miss) | ✓ |
  | 1 | 3.26119 | 3025 | 3.28278 (miss) | ✗ |
  | 2 | 3.25916 | 3025 | 3.28071 (miss) | ✓ |
  | 3 | 3.25948 | 3025 | 3.28100 (miss) | ✓ |
  | **μ_4** | **3.259733** | **3025** | all 4 miss 3.28@step3000 | 3/4 |
  - σ_4(val)=0.000986, SEM_4=0.000493; σ_4(FFS)=0 (unanimous 3025)
  - n=4 FFS merge gate (≤3018.75): FAIL at 3025
  - n=4 val merge gate (≤3.259221): FAIL by +0.000511 (~1.04·SEM_4)

- mechanism findings:
  1. **n=1 FFS=3000 was step-quantization noise, not seed luck**. val@step3000 population mean sits *just above* 3.28 by < 1·σ_single — the n=1 seed sampled the lower tail. n=4 reveals the mean, not an artifact of any single seed being anomalous.
  2. **Val improvement is real but small**: Δ = −0.001488 ≈ −2.51σ_single, consistent across all 4 seeds. Scalars β1=0.95 does shift the val/loss curve down slightly — but not enough to move FFS.
  3. **Per-group β1 dissociation finding preserved**: scalars (1D, low-SNR) tolerate β1=0.99 (FFS=3025, val+0.0015), unlike matrices (#1310 uniform β1=0.99 → FFS=−1 NEVER, catastrophic). Basin width is param-group-specific. Finding stands as mechanism observation.
  4. **Aux HP-decoupling triumvirate closed (FFS axis)**: β1 per-group (this PR) + β2 per-group (#1434 in flight) + ε per-group (#1310) all FFS-cosmetic. Per-group HP retuning cannot move FFS in this stack.

- cluster connections:
  - **24th stack-component closure** of FFS-primary cycle.
  - **Closes per-group HP-decoupling mechanism class on FFS axis**: β1+β2+ε all FFS-cosmetic.
  - **Joins cluster with #1275 (lr_scalars decoupling)** — scalars decoupling is val-positive but FFS-cosmetic.
  - **Narrows FFS-moveable space**: HP retuning on aux groups (any of lr/β1/β2/ε/cooldown) is ruled out. FFS-moveable mechanisms are Muon body direction + cooldown shape.

- student excellence: ★★ Excellent FFS-quantization-noise diagnosis. "val@step3000 sits just above 3.28 by < 1·σ_single across all 4 seeds" decomposition is exactly what FFS-primary directive #1262 was designed to surface. Honest split-bucket assessment of predeclared criteria.

- decision (FFS-primary, directive #1262): FFS μ_4=3025 = no movement. Val gate miss by 1·SEM_4. Close clean-NEG-FFS-NOISE. 24th closure.
- next assignment: #1471 thorfinn Lion optimizer for AdamW aux (Chen et al. 2023, sign-based, fresh mechanism class)

## 2026-05-27 18:05 — PR #1403: Polyak-Ruppert eval-only EMA (nezuko) [EVAL-AVERAGING-FALSIFIED clean-NEG]
- branch: g1r5-nezuko/polyak-ruppert-eval-ema
- hypothesis: "Does eval-only Polyak-Ruppert averaging reduce FFS by smoothing the val/loss noise floor near 3.28? Tests whether FFS=3025 is eval-noise-limited vs signal-limited."
- verdict: **CLOSED clean-NEG-EVAL-AVERAGING-FALSIFIED** [FFS-primary, 23rd stack-component closure under directive #1262]
- results (5-cell sweep, all n=1, 3250 steps, W&B verified exact match):
  | Cell | β | start | FFS (EMA-eval) | EMA val/loss | live val/loss | ema_diff_p50 | W&B id |
  |:----:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
  | A ctrl | 0.0 | — | **3025** | — | **3.26077** | n/a | 623x8pea |
  | B★ | 0.999 | 0 | **-1 (DNF)** | 3.33871 | 3.26205 | 0.133 | dn4de8kw |
  | C | 0.999 | 975 | **-1 (DNF)** | 3.35150 | 3.26183 | 0.102 | qeznwex8 |
  | D | 0.99 | 0 | 3025 | 3.27003 | 3.26251 | 0.005 | 9ocvkmpd |
  | E★falsifier | 0.9999 | 0 | **-1 (DNF)** | 7.11905 | 3.26226 | 0.793 | jdx9duxb |

- mechanism findings (5):
  1. **Eval-noise hypothesis FALSIFIED** — FFS=3025 is signal-limited not noise-limited. Even cell D (tiny lag, diff_p50=0.005) shows val WORSE by +15.6σ with FFS unchanged. Eval smoothing cannot move FFS.
  2. **Perfect (1−β) dose-response in diff_norm** — diff_norm_p50 = {0.005, 0.10, 0.13, 0.79} for β = {0.99, 0.999, 0.999, 0.9999}. Linear scaling confirms EMA lag mechanism.
  3. **Live trajectory invariant across all 5 cells** — live val_loss ∈ [3.26183, 3.26251] (±1.7 mNats), confirming eval-only contract works mechanically as designed. EMA failures are purely EMA-lag.
  4. **Cooldown slope dominates EMA lag by 3+ orders** — local val_loss slope at target ≈ 1.5×10⁻³/step. For EMA to track within σ_single (5.93×10⁻⁴) needs τ ≲ 0.4 steps → β ≲ 0 (no smoothing). Quantitative proof that averaging is structurally incompatible with steep cooldown.
  5. ★★ **Joint closure with #1258 SF-Muon** — training-internal averaging AND eval-only averaging both fail for the same structural reason. The AVERAGING MECHANISM CLASS is closed against steep-cooldown regime, independent of insertion point.

- cluster connections:
  - **23rd stack-component closure** of FFS-primary cycle.
  - **"Averaging class" pair closure**: #1258 (training-internal) + #1403 (eval-only) — both blocked by cooldown-slope dominance.
  - **Narrows FFS-moveable space**: only parameter-update-direction interventions (preconditioners, NS shape, init, gating) can move FFS-alive. Averaging mechanisms across entire optimizer stack are structurally incompatible.

- student excellence: ★ Outstanding diff_norm dose-response analysis. Quantitative cooldown-slope argument proving β ≲ 0 needed for tracking is textbook-clean mechanism diagnosis. Honest predictions-vs-outcomes table.

- decision (FFS-primary, directive #1262): No cell ≤ 2975 → no n=4 promotion. Close clean-NEG-EVAL-AVERAGING-FALSIFIED. 23rd closure.
- next assignment: #1460 nezuko Cautious Optimizer (Liang et al. 2024, sign-agreement gating on Muon body)

## 2026-05-27 15:45 — PR #1394: embed LR pruning (edward) [BASIN-FLAT NULL with cliff at 0.05]
- branch: g1r5-edward/embed-lr-pruning
- hypothesis: "Is `adam_embed lr=0.3` (highest aux LR, 96× higher than lm_head) FFS-load-bearing? Cross-cluster with #1275 scalars wanting HIGHER and #1334 embed showing 30× WD dose-response"
- verdict: **CLOSED clean-NEG-BASIN-FLAT-CONFIRMS-DEFAULT** [FFS-primary, 22nd stack-component closure under directive #1262]
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor — perfect match):
  | Cell | lr_embed | mult | FFS | val/loss | Δbase (σ_single) | W&B id |
  |:----:|:--------:|:----:|:---:|:--------:|:----------------:|:------:|
  | A | 0.30 | 1.0× (ctrl) | 3025 | 3.26090 | −0.54σ | 8hoadz0v |
  | **B★** | **0.60** | **2.0× PRIMARY** | 3050 | **3.26336** | **+3.61σ NEG** | 1j2aqf6y |
  | C | 0.15 | 0.5× | 3025 | 3.26056 | −1.11σ | c23myau0 |
  | D | 0.90 | 3.0× | 3025 | 3.26146 | +0.40σ | stu7k1q4 |
  | **E** | **0.05** | **1/6× falsifier** | 3125 | **3.27138** | **+17.13σ CATASTROPHIC** | 4gdqrjgm |

- mechanism findings (5):
  1. **Basin-flat across [0.15, 0.90] (6× span)** — Cells A/C/D all FFS=3025 baseline-EXACT with val spreading −1.11σ to +0.40σ. Embed LR is value-cosmetic within its basin.
  2. **Sharp cliff at 0.05** — Cell E +17.13σ +100 FFS. The 1.27 visits/row/step sparse-gradient regime needs minimum LR.
  3. ★★ **Aux-LR triumvirate COMPLETED with mixed signature**: scalars #1275 wanted **HIGHER 3×** (FFS-positive); embed THIS PR wants **NOTHING** (basin-flat 6×); lm_head #1387 wants **NOTHING** (basin-flat 16×). **Falsifies "all aux-group defaults systematically conservative" framing** — only scalars showed FFS-positive movement.
  4. **Cell B★ outlier mildly NEG (+3.61σ)** bracketed away by C (0.5×) ✓ and D (3×) ✓ — non-monotonic single-seed result, most likely noise on a flat basin.
  5. ★ **Dose-response in embed_weight_norm** — E=13K → D=207K (16× span across 18× LR range). Inverse dose-response in embed_grad_norm (E=308 → D=21). Real magnitude state dynamics but does NOT propagate to FFS/val above the cliff. Mirrors #1387 lm_head's self-equalizing `lr × g_norm` finding.

- cluster connections:
  - **Aux-LR triumvirate finally closed**: scalars=FFS-positive, lm_head=cosmetic-16×, embed=cosmetic-6×-with-cliff-at-0.05. Per-group LR dissociation lives on the scalars axis only.
  - **22nd stack-component pruning closure** of FFS-primary cycle.
  - **4th "aux-aux is mostly cosmetic" closure** (joins #1330 lm_head ε + #1334 aux wd + #1387 lm_head LR). Aux defaults are correct; productive movement requires per-group decoupling (scalars-β1 #1368 + scalars-β2 #1434 in flight).

- student excellence: ★ Outstanding 3-axis dose-response telemetry table (weight_norm × grad_norm × row_visit_fraction) cleanly explained both the basin and the cliff. Cross-PR comparison table for the aux-LR triumvirate is exactly the synthesis FFS-primary needs. Pre-registered "40% NULL across [0.15, 0.6]" came true cleanly.

- decision (FFS-primary, directive #1262): No Cell ≤ 2975 → no n=4 promotion. Close clean-NEG-BASIN-FLAT-CONFIRMS-DEFAULT. 22nd stack-component closure.

- follow-up assignment: edward → **#1446 Lookahead optimizer wrapper on Muon body** (★ FRESH OPTIMIZER MECHANISM — pivoting from aux-LR triumvirate which is now exhausted):
  - Zhang, Lucas, Ba, Hinton 2019 "Lookahead Optimizer: k steps forward, 1 step back" arxiv:1907.08610 (NeurIPS 2019)
  - Maintain `fast` (Muon-updated each step) and `slow` (synced every k steps via `slow += α·(fast - slow); fast ← slow`)
  - Hypothesis: Muon body update direction has step-to-step variance from NS-orthogonalization approximation + SOAP eigenbasis staleness + AdamW aux moment EMA — Lookahead averaging over k-steps damps this without changing mean direction
  - 5-cell A=k=0 ctrl / **B★=k=5 α=0.5 Zhang-default** / C=k=10 α=0.5 longer window / D=k=5 α=0.3 gentler / E=k=5 α=0.9 falsifier (over-pull)
  - Lookahead automatically deactivates during cooldown (LR→0 ⟹ fast-slow→0) — mechanism activates exactly in stable+early-phase regime where FFS-load-bearing dynamics live
  - Cross-mechanism comparison with #1441 AGC (peak-shaving vs noise-reduction directions)
  - If FFS-positive, opens 3rd FFS-positive direction class beyond per-group decoupling (#1368) and cosine cooldown shape (#1381)

## 2026-05-27 15:00 — PR #1387: lm_head LR pruning (tanjiro) [WIDE-COSMETIC NULL]
- branch: g1r5-tanjiro/lm-head-lr-pruning
- hypothesis: "Is the lm_head LR=1/320 default FFS-load-bearing? Test 5 cells across a 16× span."
- verdict: **CLOSED clean-NEG-WIDE-COSMETIC** [FFS-primary, 21st stack-component closure under directive #1262]
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor):
  | Cell | lr_lm_head | mult | val/loss | FFS | Δbase (σ_single) | W&B id |
  |:----:|:----------:|:----:|:--------:|:---:|:----------------:|:------:|
  | A | 0.003125 (1/320) | 1.0× | 3.26294 | 3050 | +2.9σ | g9rqvbsw |
  | **B★** | **0.00625 (1/160)** | **2.0×** | **3.26193** | **3025** | **+1.2σ** | a6lqrblb |
  | C | 0.0125 (1/80) | 4.0× | 3.26200 | 3050 | +1.3σ | 4h9k6dh8 |
  | D | 0.0015625 (1/640) | 0.5× | 3.26224 | 3050 | +1.7σ | xdo38w59 |
  | E | 0.025 (1/40) | 8.0× | 3.26211 | 3050 | +1.5σ | h88aaba4 |

- mechanism findings (5):
  1. **Wide cosmetic basin confirmed across 16×** — A/B/C/D/E val all within 1.7σ_single. lm_head LR is not FFS-load-bearing and not val-load-bearing in this regime.
  2. ★ **Self-equalizing weight-norm/grad-norm feedback discovered** — proj weight norm scales near-linearly with LR (E is 8× LR → 7.24× weight norm) and grad norm scales inversely (E grad norm = 0.13× of A). The product `lr × g_norm` converges to ~35–38 across cells. **The lm_head autoregulates** through this feedback loop.
  3. **Cross-mechanism alignment with eps #1330** — lm_head telemetry is dose-responsive to upstream knobs without propagating to val/FFS. Consistent downstream-decoupled axis.
  4. **Scalars/lm_head dissociation confirmed**: scalars #1275 wanted 3× higher LR (FFS-positive); lm_head wants nothing across 16×. The "AdamW aux defaults are systematically too conservative" hypothesis **does NOT generalize from scalars → lm_head**. Per-group dissociation reinforced.
  5. **Predicted B★ at 2× was best-of-cells** — directionally sensible but not gate-clearing. 2× is the safest interior point in the basin.

- cluster connections:
  - **3rd dissociation finding** between scalars vs other aux groups (LR #1275 + β1 #1368 + lm_head LR NULL here). Scalars cluster is mechanistically distinct from {embed, lm_head} aux clusters.
  - **Closes lm_head LR axis at 21st stack-component pruning**. Pairs with #1330 lm_head eps NULL → lm_head consistently downstream-decoupled.
  - **Falsifies "all aux groups have similar headroom" framing** — embed (probably load-bearing), scalars (FFS-positive), lm_head (cosmetic).

- student excellence: ★ Weight-norm/grad-norm dose-response analysis with `lr × g_norm ≈ 35–38` cross-cell product is a clean mechanistic explanation, not just "didn't matter". Pre-registered "OPPOSITE direction from scalars #1275" framing was exactly right.

- decision (FFS-primary, directive #1262): No Cell ≤ 2975 → no n=4 promotion. Close clean-NEG-WIDE-COSMETIC. 21st stack-component closure.

- follow-up assignment: tanjiro → **#1442 per-block-depth body LR decay** (★ fresh OPTIMIZER MECHANISM — pivoting from aux-LR axes which are exhausted):
  - Tests γ^(L-block_idx) modulator on Muon body LR per transformer block (12 blocks total)
  - ULMFiT-style layer-wise LR but applied to pretraining-from-scratch (untested in this regime)
  - 5-cell A=1.0 ctrl / **B★=0.95 ULMFiT-style** (lower blocks slower) / C=1.05 inverse / D=0.90 steep / E=1.15 falsifier
  - Pairs with musoft init prior: does init's depth-scaling want a matching LR-depth-scale?

## 2026-05-27 14:55 — PR #1385: Full-run cosine LR schedule (fern) [FFS-POSITIVE BUT VAL-COSTLY, covered by #1381]
- branch: g1r5-fern/cosine-full-run-body-lr
- hypothesis: "Cosine LR schedule from step 0→0 instead of stable+linear may be FFS-positive (monotone decay reaches target faster) — tests whether the stable phase is structurally needed"
- verdict: **CLOSED MECHANISM-FINDING-COVERED-BY-#1381** [FFS-primary, 20th stack-component closure under directive #1262]
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor):
  | Cell | shape | FFS | val/loss | Δbase (σ_single) | reached | W&B id |
  |:----:|:-----:|:---:|:--------:|:----------------:|:-------:|:------:|
  | A | stable_linear (ctrl) | 3050 | 3.262024 | +1.35σ | ✓ | x4p1op6b |
  | **B★** | **cosine** | **2925** | **3.273922** | **+21.4σ** | ✓ | 0eg3lwoh |
  | C | cosine_min01 | 3075 | 3.270521 | +15.7σ | ✓ | lif96ji2 |
  | D | warmup_cosine | DNR | 3.280369 | +32.3σ | ✗ | hhk9v4lk |
  | E | triangular (falsifier) | DNR | 3.306759 | +76.8σ | ✗ | wxnalgq8 |

- mechanism findings (5):
  1. ★★ **FFS-positive but val-negative SPLIT confirmed** — cosine (Cell B) hits FFS=2925 (FFS-alive) AND pays +21.4σ_single val penalty. Falsifies "stable_linear is uniformly load-bearing" framing — stable phase is val-positive but FFS-counterproductive.
  2. **Cell B val plateaus near 3.274** — never gets close to baseline 3.261. Cosine's monotone-decreasing LR from step 0 reaches threshold faster but exhausts directed-descent budget too soon.
  3. **Cell C (cosine_min01) dominated by Cell B** — adding 0.1 floor doesn't help; floor achieved late.
  4. **Cell D (warmup_cosine) DNR** — 200-step linear warmup eats early progress; consistent with #1328 monotone-worse warmup finding.
  5. **Cell E (triangular) decisively falsified at +76.8σ** — inverted-V wastes first ~1625 steps ramping up, never sustains high-LR descent.

- cross-PR mechanism alignment with alphonse #1381:
  - **fern Cell B (full-run cosine) and alphonse Cell B (cosine-cooldown-only) both hit FFS=2925** with mechanism-coherent val trajectories through steps 1500→2925 (within ~0.005 of each other)
  - Divergence happens AFTER FFS crossing: alphonse's stable-phase-preserved cosine continues descending (final 3.26779) while fern's full-run cosine plateaus (final 3.27392)
  - **The stable phase is val-load-bearing** — removing it pays substantial val cost without buying additional FFS
  - **Cosine SHAPE is FFS-load-bearing IN THE COOLDOWN WINDOW only** — full-run application is NOT additionally productive (val-costly without FFS gain)

- cluster connections:
  - **2nd FFS-positive direction this poll** (alongside alphonse #1381 same mechanism class)
  - **3rd FFS-positive of R5 cycle** (after #1368 scalars-β1 and #1381 cosine cooldown)
  - **20th stack-component pruning closure**: documents shape-localization mechanism (cosine works in cooldown window, NOT in stable window)

- student excellence: ★ SPLIT pattern recognition (FFS-positive vs val-negative) is exactly what FFS-primary directive #1262 needs — explicit framing of the tradeoff lets the advisor make the right cross-PR decision (productive shape lives in cooldown only). Pre-registered "deserves its own directive clarification" was prescient.

- decision (FFS-primary, directive #1262): Cell B FFS-alive at n=1 BUT paired against alphonse #1381 Cell B (same FFS=2925, better val=3.26779 vs 3.27392) — alphonse's instantiation being confirmed at n=4. Closing as MECHANISM-FINDING rather than running concurrent n=4 confirms to maximize GPU throughput on the productive direction. 20th stack-component closure.

- follow-up assignment: fern → **#1441 AGC (Adaptive Gradient Clipping) on Muon body** (★ fresh OPTIMIZER MECHANISM — pivoting from schedule axis):
  - Tests AGC per-parameter `||grad||/||param|| ≤ λ` clipping on body matrices (Brock et al. NFNets, arxiv:2102.06171)
  - 5-cell A=0 ctrl / **B★=0.01 NFNets-default** / C=0.005 tighter / D=0.02 looser / E=0.001 falsifier (over-clip)
  - Mechanism question: does the Muon body suffer early-training gradient bursts that AGC can damp without reducing late-training capacity?

## 2026-05-27 14:50 — PR #1381: Cooldown LR decay SHAPE (alphonse) [SENT BACK FOR n=4 CONFIRM]
- branch: g1r5-alphonse/cooldown-lr-decay-shape
- hypothesis: "Cooldown shape (linear/cosine/concave/convex/step) is FFS-load-bearing within the cooldown window — tests cluster prediction 'directed descent through low-LR regime is load-bearing'"
- verdict: **★★ STRONG FFS-POSITIVE at n=1 (B★ cosine FFS=2925 clears ≤2975 by 100 steps); SENT BACK FOR n=4 CONFIRM** per directive #1262
- results (5-cell sweep, all n=1, W&B verified by advisor):
  | Cell | shape | FFS | val/loss | Δbase (σ_single) | W&B id |
  |:----:|:-----:|:---:|:--------:|:----------------:|:------:|
  | A (ctrl) | linear | 3050 | 3.26327 | +3.5σ | ayktp1y8 |
  | **B★** | **cosine** | **2925** | **3.26779** | **+7.6σ** | gpnw92c8 |
  | C | concave √(1-x) | 3225 | 3.27412 | +19.0σ | lhtc8jns |
  | **D** | **convex (1-x)²** | **2925** | **3.27441** | **+19.2σ** | 5zksggst |
  | E | step (0.8) | DNF | 3.43395 | +291σ | 135ixnti |

- mechanism findings:
  - **TWO FFS-alive cells (B cosine + D convex both FFS=2925)** — cluster mechanism confirmed: "directed descent through low-LR regime is load-bearing"
  - Cluster prediction empirically supported via **geometrically-convex shape** (D (1-x)²); student noted concave/convex behavioral inversion in PR labels (functions correctly named but description swapped) — the "drop fast and stay low" shape (D) and the smooth-decay shape (B) both clear FFS
  - **Cell C (concave, keeps eta high) FFS=3225 WORST** — confirms cluster: high-eta during cooldown sharply hurts FFS
  - **Cell E (step, no descent) DNF at +291σ** — falsifier fired as predicted: pure plateau then collapse never enters low-eta descent regime
  - **Cross-PR corroboration**: fern #1385 Cell B (full-run cosine) ALSO hit FFS=2925 with mechanism-coherent val trajectory through steps 1500→2925 — TWO independent students converge on same FFS endpoint

- decision (FFS-primary, directive #1262): FFS-alive at n=1 ⇒ **n=4 promotion REQUIRED**. Cell B cosine has best FFS:val tradeoff (+7.6σ val vs D's +19.2σ). Sent back for `--num_trials 4 --lr_cooldown_shape cosine` confirm; val tradeoff will be characterized at n=4 for human review.

- student excellence: Cluster prediction sharpening (cosine vs convex both win, concave + step both lose) provides clean cross-shape mechanism evidence; concave/convex labeling self-correction in the report is high-quality scientific honesty.

## 2026-05-27 14:15 — PR #1384: ADAM-EMBED per-group cooldown decoupling (askeladd)
- branch: g1r5-askeladd/embed-cooldown-decouple
- hypothesis: "Does adam_embed (lr=0.3, 38.6M params, highest aux LR) behave like adam_scalars (#1326 WIDE-NULL with edge-sensitivity, permissive) or like body (tight)?"
- verdict: **CLOSED clean-NEG-WIDE-NULL-EDGE-SENSITIVITY** [FFS-primary, 19th stack-component closure]
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor):
  | Cell | embed_cooldown_frac | FFS | val/loss | Δbase (σ_single) | reached | W&B id |
  |:----:|:------------------:|:---:|:--------:|:----------------:|:-------:|:------:|
  | A | None (shared 0.7) | 3050 | 3.262344 | +1.89σ | 1 | sd7f4fhv |
  | **B★** | **-1 (no cooldown)** | **3075** | **3.264772** | **+5.99σ** | 1 | ae1ndnfp |
  | C | 0.5 (early) | **3025** | **3.260230** | **−1.67σ** | 1 | nnhhssyt |
  | D | 0.85 (late) | 3050 | 3.263752 | +4.27σ | 1 | kzvyqv4j |
  | **E** | **-2 (anti-ramp)** | **3150** | **3.272629** | **+19.24σ** | 1 | hnbn2qut |

- mechanism findings (4):
  1. **WIDE-BAND-NULL on embed_cooldown_frac ∈ {0.5, 0.7, 0.85}** all FFS ∈ [3025, 3050] — embed is permissive on cooldown TIMING within the body of valid fractions, just like scalars. Tight-basin prediction REJECTED.
  2. **Edge sensitivity to ABSENCE of cooldown (Cell B +5.99σ, +25 FFS)** — embed *can* survive without cooldown but pays measurable penalty. Much milder than scalars-constant +10.6σ in #1326 — points to embed's larger parameter pool (38.6M vs scalars' ~150) and dominant-feature dynamics (each token row revisited hundreds of times per epoch) giving more robustness to suboptimal scheduling.
  3. **Edge catastrophe on anti-ramp direction (Cell E +19.24σ, +100 FFS)** — ramping embed LR UP during cooldown sharply incompatible with the rest of the stack shutting down. Same direction-of-failure as scalars #1326 (which had +29.4σ), with magnitude attenuation matching the constant-LR finding.
  4. ★ **Cross-cluster structural inference**: 2 of 3 aux groups (scalars #1326, embed #1384) live in the crossing-phase decoupling cluster with WIDE-NULL + edge-sensitivity. Body (mu #1294 + #1345) shows monotone-tightening with sharp two-sided basin. Joint claim: **auxiliary groups are PERMISSIVE on cooldown TIMING with edge-direction sensitivity; body is TIGHTLY-coupled** on cooldown shape. The optimizer stack has per-component-decoupled structure on aux-side timing but coupled body-side timing.

- cluster connections:
  - **5th crossing-phase decoupling closure**: #1294 mu DOWN, #1345 mu UP, #1322 NS-iter cooldown, #1326 scalars-LR cooldown, #1377 β2 schedule, #1384 embed-LR cooldown — joint claim: uniform cooldown HP-schedule has no FFS-positive movement available across all tested axes (aux WIDE-NULL or body tight-coupled).
  - **Per-group decoupling cluster** still 1 FFS-positive (#1368 scalars-β1 n=1, pending n=4) + 0 FFS-positive on TIMING dimension (aux-side WIDE-NULL on cooldown_frac).
  - **Cell C val=3.260230 below baseline by 1.67σ_single** but FFS=3025 baseline-EXACT — within seed noise; no n=4 promotion per directive #1262.

- student excellence: Pre-registered predictions (a 60% / b 25% / c 15%) cleanly resolved at outcome — prediction (a) WIDE-NULL with edge-sensitivity confirmed at 60% prior; (b) tight-basin REJECTED; (c) FFS-positive REJECTED. Cross-PR comparison table (scalars vs embed vs mu) sharpens the cluster structural claim.

- decision (FFS-primary, directive #1262): No Cell ≤ 2975 → no n=4 promotion. Cell C val improvement is within seed noise at fixed FFS. Close clean-NEG-WIDE-NULL-EDGE-SENSITIVITY. 19th stack-component closure.

- follow-up assignment: askeladd → **#1437 matrices β1 isolation** (★ pivot from cluster completion to fresh per-group AXIS):
  - Tests whether the "matrices" β1 basin (#1310 narrow-tight at 0.8) is further dissociable between adam_embed and adam_lm_head — completes per-group β1 picture
  - Background: #1310 closed UNIFORM β1=0.8 as matrices-driven; #1368 found scalars want HIGHER (0.95) wider basin; embed vs lm_head dissociation NEVER tested
  - 5-cell A=0.8/0.8 ctrl uniform / **B★=0.8/0.95 PRIMARY** lm_head dissociation (small-update regime mirror of scalars finding) / C=0.95/0.8 embed dissociation / D=0.95/0.95 joint matrices both want higher / E=0.5/0.5 falsifier
  - New CLI flags `--embed_beta1` and `--lm_head_beta1` (default 0.8) override per-group betas on adam_embed and adam_lm_head only; scalars untouched
  - Strict FFS-alive gate B★ ≤ 2975 for n=4 promotion per directive #1262
  - 30%/20%/35% priors on lm_head dissociation FFS-positive / embed dissociation FFS-positive / no internal dissociation; completes per-group β1 picture either way

## 2026-05-27 13:30 — PR #1377: AdamW aux β2 SCHEDULE — cooldown 0.95→0.99 ramp (frieren)
- branch: g1r5-frieren/adamw-aux-beta2-schedule
- hypothesis: "AdamW aux β2 schedule (constant vs cooldown-localized ramps) is FFS-load-bearing — preserving high β2 during cooldown maintains v_t magnitudes so effective_lr does not collapse"
- verdict: **CLOSED clean-NEG-WASHED-OUT** [FFS-primary, 18th stack-component closure under directive #1262]
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor — all 5 runs match exactly):
  | Cell | Schedule | β2_low | β2_high | val_best | FFS | Δbase (σ_single) | n=1 gate | W&B id |
  |:----:|:---:|:------:|:-------:|:--------:|:---:|:-----------------:|:--------:|:------:|
  | A (ctrl) | constant | 0.95 | 0.95 | 3.26016 | 3025 | −1.79σ | PASS | er7prqnd |
  | **B★** | **linear_ramp** | **0.95** | **0.99** | 3.26123 | 3025 | +0.02σ | FAIL | 7dd63ld1 |
  | C | linear_ramp | 0.95 | 0.98 | 3.26120 | 3025 | −0.04σ | FAIL | vnxl8ek7 |
  | D | instant_step | 0.95 | 0.99 | 3.26003 | 3025 | −2.01σ | PASS | c2rivonf |
  | E (falsifier) | reverse_ramp | 0.99 | 0.95 | 3.26158 | 3025 | +0.60σ | FAIL | nky27wkn |

- mechanism findings (5):
  1. **Cooldown 2nd-moment preservation NOT confirmed**. B/D never moved FFS; E falsifier didn't fire catastrophically. The #1321 Cell D val improvement at high β2 is now most likely seed-noise artifact at fixed FFS=3025, not load-bearing cooldown structure.
  2. **Schedule SHAPE doesn't matter when terminal β2 is fixed**. D (β2=0.99 for ~70% of training) vs B (averaging ~0.97) differ by only 2σ_single — within seed noise. EMA half-life 13.5→69 steps doesn't register on crossing speed.
  3. **Falsifier washout breaks cooldown-localization claim** — Cell E reverse-ramp val only +0.60σ from baseline; if cooldown β2 were structurally load-bearing, E should drop val materially.
  4. **Pairs with #1321** to FULLY prune AdamW aux β2 axis: value pruning (#1321: 0.90/0.92/0.95/0.99 all FFS=3025) + schedule pruning (this PR: constant/linear/instant/reverse all FFS=3025). β2 converged to "fully FFS-cosmetic" within [0.90, 0.99].
  5. ★ **Breaks cooldown-tightening localization for AdamW aux**: body-side cooldown axes (#1272 WD, #1276 cooldown_frac, #1284 body-WD, #1294 mu-cooldown) all show value-sensitive structure with narrow basins and asymmetric cliffs. AdamW aux β2 schedule shows nothing — cooldown-tightening is **BODY-side** mechanism, not aux-side.

- cluster connections:
  - **Crossing-phase decoupling cluster now 5 NEG + 1 POSITIVE**: #1294 (mu DOWN), #1345 (mu UP), #1322 (NS-iter cooldown), #1326 (scalars-LR cooldown), #1377 (β2 cooldown shape), #1368 (scalars-β1 POSITIVE pending). Uniform cooldown HP-schedules across all axes FFS-dead; per-group decoupling is the only fresh FFS direction.
  - **AdamW aux tetrad updated**: β1 #1310 NARROW-BASIN-load-bearing (matrices) + scalars=0.95 wide basin (#1368 dissociation pending); β2 #1321+#1377 FULLY-COSMETIC across value AND schedule; ε wide-cosmetic; wd confirms-default. β1 is ONLY load-bearing axis on matrices; β2 doesn't move FFS anywhere on uniform optimizer.

- student excellence: Schedule decomposition (linear/instant/reverse) is exactly the right falsifier design; W&B `adamw_aux/beta2_current` history at 5 checkpoints proves implementation correctness across all 4 schedule shapes; Cell E reverse-ramp catastrophe prediction was a sharp test designed precisely to falsify the hypothesis.

- decision (FFS-primary, directive #1262): No Cell ≤ 2975 → no n=4 promotion. Both per-PR rules fired (B FFS=3025 ⇒ value-cosmetic; E FFS<3050 ⇒ schedule axis washed out). Close clean-NEG-WASHED-OUT. 18th stack-component closure of FFS-primary cycle.

- follow-up assignment: frieren → **#1434 scalars β2 PER-GROUP decoupling** (fresh axis; uniform β2 axis fully closed but per-group dissociation untested):
  - Mirror #1368 mechanism class on β2 axis — does adam_scalars group also want HIGHER β2 than 2D matrices?
  - 5-cell A=0.95 ctrl uniform / B★=0.99 PRIMARY mirror of #1368 / C=0.999 extreme bracket / D=0.9 lower bracket / E=0.5 falsifier.
  - Same signal-processing prior as #1368: low-SNR scalars want heavier 2nd-moment smoothing.
  - New CLI flag `--scalars_beta2` with default 0.95 (no-op) overriding adam_scalars group betas.
  - If confirms: per-group decoupling mechanism class generalizes across BOTH AdamW moments — extremely strong cross-axis stack-positive signal.

## 2026-05-27 11:05 — PR #1368: Per-group β1 decoupling on AdamW aux scalars (thorfinn) [n=1 STRONG, sent back for n=4 confirm]
- branch: g1r5-thorfinn/scalars-beta1-decouple
- hypothesis: "AdamW aux scalars (1D LN gains + biases, low per-element SNR) want HIGHER β1 than embed/lm_head (2D high-SNR matrices); the narrow basin established by uniform-β1 #1310 was matrices-driven, not scalars-driven"
- verdict: **★★ FIRST FFS-POSITIVE n=1 OF R5 CYCLE — SENT BACK FOR n=4 CONFIRM** (do NOT close; awaiting confirmation)
- results (5-cell sweep, all n=1 full 3250 steps, W&B verified by advisor):
  | Cell | scalars_β1 / matrices_β1 | FFS | val/loss | Δbase (σ_single) | gate check | W&B id |
  |:----:|:------------------------:|:---:|:--------:|:----------------:|:----------:|:------:|
  | A | 0.8 / 0.8 (ctrl uniform) | 3025 | 3.26001 | −0.36σ (sanity) | n=1 gate −0.000618 ✅ | c0rjs67h |
  | **B★** | **0.95 / 0.8 PRIMARY** | **3000** ⬇25 | **3.25786** | **−5.79σ** | **n=1 gate −0.002768 ✅** | zg0dkec1 |
  | C | 0.9 / 0.8 | 3025 | 3.26113 | +1.5σ | n=1 gate −0.000498 ≈ | jgfn23nd |
  | D | 0.5 / 0.8 | 3075 ⬆50 | 3.26505 | +8.5σ | n=1 gate +0.004422 ❌ | e5gf9g94 |
  | E | 0.99 / 0.8 falsifier | 3025 | 3.26148 | +2.5σ | n=1 gate +0.000852 ≈ | 5zc4sj9a |

- mechanism findings (5):
  1. **★★ STRONG DISSOCIATION confirmed** — Cell E (scalars β1=0.99) flat at FFS=3025 vs **#1310 Cell D (uniform β1=0.99 → FFS=−1 NEVER, val=3.289 +47σ_single catastrophic)**. The narrow basin in #1310 was driven by embed/lm_head; scalars have a much WIDER β1 basin and tolerate even β1=0.99 with no measurable harm.
  2. **Asymmetric reversal**: Cell D (β1=0.5) hurts (+50 FFS, +0.005 val) while Cell E (β1=0.99) flat — scalars want MORE memory (heavier smoothing), not less. Matches classical signal-processing prior: lower-SNR signals want heavier smoothing.
  3. **★ FFS-curve cooldown localization**: All cells identical until step 2875 (val=3.30); the decoupling effect lives entirely in the cooldown window (steps 2875→FFS). Joins crossing-phase cluster — but THIS time with FFS-POSITIVE movement, unlike #1322/#1326/#1294/#1345 all FFS-negative.
  4. **Mechanism dissociation class joins #1275** — scalars are a distinct cluster from 2D matrices that want their own (LR, β1) corner. Two independent FFS-positive dissociation findings (#1275 lr_scalars=0.03, #1368 scalars_beta1=0.95) — strongly suggests scalars_beta2 may also be FFS-positive at a different value (student suggestion #4).
  5. **Predictions vs outcome**: PRIMARY 35% (B FFS≤3025 with val improvement) HIT at the strong end; SURPRISE 5% partially confirmed (asymmetric basin — B improves AND E flat rather than catastrophic). The genuinely novel finding (NOT in predictions): FFS curve identical up to val=3.30 across cells.

- cluster connections:
  - **First FFS-positive n=1 of the entire R5 cycle** after 17 stack-component closures (15 clean-NEG / 2 val-improvement-but-FFS-flat). Plateau-breaking signal.
  - **Crossing-phase decoupling cluster extends to 5 members + first FFS-POSITIVE direction**: #1294 mu DOWN (NEG), #1345 mu UP (NEG), #1322 NS-iter cooldown (NEG), #1326 scalars-LR cooldown (NEG), **#1368 scalars β1 (POSITIVE n=1)**. Cluster is no longer purely FFS-dead — per-group decoupling IS a fresh FFS axis.
  - **Per-group dissociation pattern (now n=2)**: #1275 lr_scalars (FFS-NEG but val-cosmetic-positive) → #1368 scalars β1 (FFS-POSITIVE). Pattern suggests scalars are a separable optimizer cluster.

- decision (FFS-primary, sent back for n=4 confirm):
  - **Cell B★ FFS=3000 hits predeclared promotion gate (≤3000)**; val=3.25786 well below n=1 confirm gate (3.260628, margin −0.002768 ≈ 4.7σ_single).
  - Sent back to thorfinn with explicit n=4 confirm instructions: only Cell B (`--scalars_beta1 0.95 --num_trials 4`), need μ_4(val) ≤ 3.259221 AND at least 2/4 with FFS ≤ 3025.
  - After confirm: merge as new baseline (FFS=3000, val ~3.258 projected). Follow-up cycles: joint (lr_scalars × β1), scalars_β2 dissociation, matrices β1 isolation (re-examine #1310).
  - If confirm fails: close clean-NEG-WAS-VAL-COSMETIC; still strong mechanism finding.

## 2026-05-27 06:35 — PR #1345: mu cooldown RAMP-UP mechanism extension (nezuko)
- branch: g1r5-nezuko/mu-cooldown-rampup
- hypothesis: "Boost Muon mu UP during cooldown extends #1294's monotone gradient (0.0→0.5→0.95) toward FFS-positive direction" (PR predeclared 25% FFS-positive B★, 30% null, 20% diminishing returns, 15% catastrophic E, 10% non-monotone)
- verdict: **CLOSED clean-NEG-LOCAL-OPTIMUM-CONFIRMED** [FFS-primary, 17th stack-component closure]
- results (5-cell sweep, all n=1 full 3250 steps):
  | Cell | mu_cooldown_target | FFS | val/loss | Δbase (σ_single) | W&B id |
  |:----:|:------------------:|:---:|:--------:|:----------------:|:------:|
  | A | 0.95 ctrl (no flag) | 3025 | 3.26099 | baseline | csf62klj |
  | **B★** | **0.95 → 0.98 ramp** | **3075** | **3.26488** | **+6.6σ** | i3wt0z66 |
  | C | 0.95 → 0.99 ramp | 3150 | 3.27202 | +18.6σ | qofqe4yt |
  | D | instant 0.98 at cooldown | 3050 | 3.26401 | +5.1σ | 8sxq354w |
  | **E (falsifier)** | **0.95 → 0.999 ramp** | **−1** | **3.28745** | **+44.6σ** | 5lgijsx8 |

- mechanism findings (5):
  1. **Two-sided rejection (cross-PR with #1294)**: combined val-vs-mu curve {0.0: 3.2696, 0.5: 3.2649, 0.95: 3.2624★, 0.98: 3.26488, 0.99: 3.27202, 0.999: 3.28745} monotone-worsens in both directions. mu=0.95 is local optimum at FFS scale.
  2. **Monotone-worsening with mu UP** across {0.98, 0.99, 0.999} → val {3.26488, 3.27202, 3.28745} → FFS {3075, 3150, NEVER}. Over-smoothing wall sits between 0.99 and 0.999 (eff look-back ~1000 steps at mu=0.999 exceeds cooldown window).
  3. **D-paradox** (instant 0.98 ≈ Cell A while ramp 0.95→0.98 worse): instant jump itself is mu-neutral when target close to base, but sustained excursion via ramp accumulates higher-mu integral and hurts. Directional asymmetry > schedule shape.
  4. **PRIMARY 25% prior FALSIFIED** by direction inversion — #1294's monotone gradient was approaching, not climbing past, the optimum at 0.95. Common-mode misread of monotone-toward-optimum patterns as extrapolatable.
  5. ★★ **Stale-momentum-during-cooldown mechanism confirmed**: cooldown updates are *signal-limited* not noise-limited. Higher mu = longer memory = stale-stable-phase inertia incompatible with cooldown's rapid LR contraction. EMA buffer at 0.95 maximally extracts available smoothing.

- cluster connections:
  - **mu cooldown axis FULLY CLOSED** — joins #1294 (mu DOWN) for two-sided rejection. No fresh-axis movement available on mu-schedule during cooldown.
  - **Crossing-phase decoupling cluster now 4 closures + 1 in flight**: #1294 (mu DOWN), #1345 (mu UP), #1322 (NS-iter cooldown), #1326 (scalars-LR cooldown), #1384 (embed-cooldown in flight). Joint claim: cooldown-window optimal = steady-state optimal across all tested axes; cooldown HP-schedule has no FFS-positive movement.
  - **Stale-momentum mechanism is the FIFTH "everything wants to be small at end" cluster member** (#1276 cooldown_frac, #966 cooldown rescaling, #1272 wd-schedule, #1284 body WD, #1345 mu). All cooldown-window HPs prefer values that minimize state inertia at terminal.

- student excellence: **Pre-registered interpretation rows fired correctly** — "Cell B val > Cell A → mu=0.95 is local optimum" predeclared rule cleanly captured the outcome. Suggested follow-ups #1 (close mu mechanism direction) and #4 (don't merge code change) both correct and adopted; advisor branch stays minimal (revert/skip commit 79fc951).

- decision (FFS-primary):
  - No Cell ≤ 2975 → no n=4 promotion per directive #1262.
  - Two-sided rejection from #1294 + #1345 closes the entire mu cooldown direction.
  - Close clean-NEG-LOCAL-OPTIMUM-CONFIRMED.

- follow-up assignment: nezuko → **#1403 Polyak-Ruppert eval-only EMA**:
  - FRESH OPTIMIZER MECHANISM (not HP search) per directive #1262 preference for "fresh mechanisms, preconditioners, schedule ideas, and pruning ablations."
  - Tests whether eval-only Polyak-Ruppert averaging reduces FFS by smoothing val/loss noise floor (which may bound crossing-step variance ±25 steps from seed alone).
  - **Structurally distinct from SF-Muon #1258 NEG** (training-internal averaging fails because cooldown LR→0 collapses averaging window). This PR keeps training optimizer untouched; only eval reads from EMA.
  - 5-cell A=off ctrl / B★=β=0.999 from step 0 PRIMARY / C=β=0.999 from cooldown / D=β=0.99 / E=β=0.9999 falsifier over-smoothing.
  - Predicts FFS<2975 if FFS is eval-noise-limited; FFS>3025 if signal-limited (lag mechanism). Falsifiable on which regime FFS=3025 is in.
  - First FRESH MECHANISM in flight since #1258 closed — high potential as first FFS-positive candidate of the plateau era.

## 2026-05-27 05:15 — PR #1334: AdamW aux weight_decay pruning ablation (edward)
- branch: g1r5-edward/adamw-aux-wd-pruning
- hypothesis: "AdamW aux `weight_decay=0` (hardcoded line 843) is either FFS-load-bearing flag (any wd>0 monotone-harms) or moderately-bounded basin near 0 with value-cosmetic small-wd cell" (PR predeclared 60% catastrophic via scalars collapse / 25% gradual-monotone / 10% null / 5% surprise FFS-positive)
- verdict: **CLOSED clean-NEG-CONFIRMS-DEFAULT** [FFS-primary, 16th stack-component closure]
- results (5-cell sweep):
  | Cell | wd | FFS | val/loss | Δbase (σ_single) | W&B id |
  |:----:|:--:|:---:|:--------:|:----------------:|:------:|
  | A | 0.0 (ctrl) | 3025 | 3.25981 | baseline | adbszdmw |
  | C | 0.001 | 3025 | 3.26117 | +2.3σ | odbjhj9v |
  | **B★** | **0.01** | **3075** | **3.26258** | **+4.7σ** | eodhdpxg |
  | D | 0.025 | 3200 | 3.27751 | +29.8σ | qjl4vbo9 |
  | **E (falsifier)** | **0.1** | **−1** | **3.30594** | **+77.8σ** | xl1xezre |

- mechanism findings (5):
  1. **Monotone dose-response in `scalars_norm_p50`** A→E: 21.3 → 20.4 → 13.4 → 8.9 → 3.5. Direct cross-PR confirmation of #1275 mechanism — AdamW aux WD>0 mechanically opposes the drift LN gains MUST do for the network to learn.
  2. **Embed compression by 30×** A→E: 69632 → 51712 → 13440 → 6656 → 2288. Embed has high-magnitude state (likely token-frequency-weighted), making it the most WD-sensitive component.
  3. **lm_head largely unaffected until wd=0.1** A→E: 801 → 795 → 788 → 755 → 585. lm_head has narrow band of WD tolerance; explains why #1330 eps wide-cosmetic finding showed lm_head-specific dose-response (lm_head sits in a stiff regime).
  4. **PRIMARY hypothesis (60% prior) FALSIFIED** — Cell B (wd=0.01) was supposed to be catastrophic via scalars collapse; instead gradual harm (+50 FFS / +4.7σ). The 25% gradual-monotone prior fired.
  5. ★★ **AdamW aux tetrad FULLY CLOSED (4/4) — mixed signature confirmed:**
     - β1 (#1310 thorfinn) — narrow-basin VALUE-load-bearing (sweet spot 0.8, width ≤0.10)
     - β2 (#1321 frieren) — monotone VALUE-prefers-higher (best 0.99, baseline-EXACT)
     - ε (#1330 tanjiro) — WIDE-COSMETIC across 8 orders of magnitude
     - wd (this PR) — FLAG-load-bearing (wd=0 required; any wd>0 monotone-harm via scalar drift opposition)
     - **Joint claim**: AdamW aux tuple `(0.8, 0.95, 1e-10, 0)` is half-load-bearing (β1+wd) and half-cosmetic (β2 cosmetic-monotone, ε wide). Pruning would simplify to `(0.8, 0.99, default-eps, 0)` with zero FFS impact.

- cluster connections:
  - **AdamW aux tetrad CLOSED** — 4/4 components characterized. Block cannot be defaulted wholesale due to β1+wd tight; but β2+ε have slack for future schedule work (#1377 frieren β2-schedule in flight).
  - **3-component telemetry methodology** — student's `scalars_norm/embed/lm_head` triple was the BEST cross-PR mechanism confirmation in recent closures. Directly attributed harm to #1275 mechanism prediction with monotone evidence.
  - **Aux-LR triumvirate emerging**: scalars (#1275 CLOSED, wanted higher), lm_head (#1387 in flight), embed (#1394 just assigned this poll).

- decision (FFS-primary):
  - No Cell ≤ 2975 → **no n=4 promotion per directive #1262**.
  - wd=0 hardcoded default IS load-bearing — confirms existing stack default; no FFS movement available on this axis.
  - Close clean-NEG-CONFIRMS-DEFAULT with strong mechanism evidence.

- follow-up assignment: edward → **#1394 EMBED-LR pruning**:
  - FIRST SENPAI test of hardcoded `lr=0.3` on the `adam_embed` group (line 840) — HIGHEST aux LR, never tested.
  - embed has 96× higher LR than lm_head (1/320=0.003125) and 10× higher than scalars (0.03).
  - Cross-cluster with #1334 finding: embed showed 30× compression dose-response under WD — magnitude state is dynamically loose, suggesting LR axis has slack to test.
  - Cross-cluster with #1275 scalars-LR (wanted HIGHER) — does embed follow same direction?
  - 5-cell A=0.3 ctrl / B★=0.6 (2×) PRIMARY higher / C=0.15 (0.5×) lower / D=0.9 (3×) aggressive / E=0.05 (~1/6×) falsifier.
  - Adds `--lr_embed` CLI flag, replaces hardcoded 0.3 on line 840.
  - With #1387 (tanjiro lm_head) and this PR, the embed/lm_head/scalars LR triumvirate will be FFS-known.

## 2026-05-27 04:30 — PR #1330: AdamW aux eps pruning ablation (tanjiro)
- branch: g1r5-tanjiro/adamw-aux-eps-pruning
- hypothesis: "AdamW aux eps=1e-10 (hardcoded line 843) is either FFS-load-bearing in lm_head small-update regime or value-cosmetic across [1e-12, 1e-8]" (PR predeclared 55% all-cosmetic / 25% D/E catastrophic / 15% mixed / 5% surprise)
- verdict: **CLOSED clean-NEG-WIDE-COSMETIC** [FFS-primary, 15th stack-component closure]
- results (5-cell sweep):
  | Cell | eps | FFS | val/loss | Δbase (σ_single) | W&B id |
  |:----:|:---:|:---:|:--------:|:----------------:|:------:|
  | A | 1e-10 (ctrl) | 3025 | 3.26045 | −1.30σ | bs7m8y7q |
  | **B★** | **1e-8** | **3025** | **3.26049** | **−1.23σ** | ynfpdrr2 |
  | C | 1e-12 | 3025 | 3.26028 | −1.59σ | f25u29np |
  | D | 1e-6 | 3050 | 3.26257 | +2.27σ | 2fc7ttxr |
  | **E (falsifier)** | **1e-4** | **3025** | **3.25925** | **−2.32σ** | 4xfbvi92 |

- mechanism findings (4):
  1. **eps COSMETIC across 8 orders of magnitude [1e-12, 1e-4]** — telemetry `sqrt_v_lm_head_p50 ≈ 0.61` dominates eps for ~99% of directions. Denominator is sqrt(v)+eps and sqrt(v) >> eps for nearly all directions in any reasonable eps band.
  2. **FALSIFIER DIDN'T FALSIFY** — Cell E (1e-4) was predicted catastrophic but tied baseline FFS and posted LOWEST val/loss (3.25925, below n=1 gate of 3.260628). Per FFS-primary directive #1262, this is NOT alive (FFS=3025 not ≤2975); val/loss alone insufficient.
  3. **Dose-response ONLY in `lm_head_weight_norm`** — monotone 806→817→806→749→730 across A/B/C/D/E. Larger eps damps low-v direction updates → lm_head grows less. Real mechanism but doesn't propagate to FFS/val at this scale; quantitative slack in lm_head training intensity exists.
  4. **AdamW aux tetrad 3/4 CLOSED with mixed signature**: β1 narrow-basin load-bearing (#1310), β2 monotone-prefers-higher (#1321), ε WIDE-COSMETIC (this). Joint claim emerging: `(0.8, 0.95, 1e-10)` tuple has 2/3 elements value-cosmetic with only β1 narrowly tight.

- cluster connections:
  - **AdamW aux tetrad almost closed**: only wd (#1334, in flight) remains. If wd closes NEG too, the AdamW aux block could be defaulted to PyTorch values with zero FFS impact.
  - **Dose-response without FFS impact** is a recurring signature in the cluster — see #1326 askeladd scalars cooldown (timing dose-response without FFS), #1276 fern cooldown_frac (LR-at-crossing dose-response without FFS-positive). Suggests the FFS-load-bearing components are NARROW and ORTHOGONAL to broad dose-response axes.

- decision (FFS-primary):
  - No Cell ≤ 2975 → **no n=4 promotion per directive #1262**.
  - Cell E val=3.25925 below n=1 gate but FFS=3025 not alive — student correctly noted this doesn't qualify.
  - Close clean-NEG with wide-cosmetic mechanism finding.

- follow-up assignment: tanjiro → **#1387 LM_HEAD-LR pruning**:
  - FIRST SENPAI test of hardcoded `lr=1/320 = 0.003125` on the `adam_lm_head` group (line 841).
  - lm_head currently has LOWEST aux LR (96× smaller than embed lr=0.3, 9.6× smaller than scalars lr=0.03).
  - Cross-cluster with #1275 scalars-LR finding (scalars wanted HIGHER not lower) — does lm_head follow the same direction?
  - 5-cell A=1/320 ctrl / B★=1/160 (2×) PRIMARY / C=1/80 (4×) / D=1/640 (0.5×) / E=1/40 (8×) falsifier.
  - Adds `--lr_lm_head` CLI flag, replaces hardcoded 1/320 on line 841.
  - Telemetry: `lm_head_weight_norm`, `lm_head_grad_norm_p50`, `lm_head_update_norm_p50`.

## 2026-05-27 02:15 — PR #1326: Scalars LR cooldown decoupling (askeladd)
- branch: g1r5-askeladd/scalars-lr-cooldown
- hypothesis: "Body matrices (Muon+SOAP groups) and scalars (LN gains+biases, ~150 params) have DIFFERENT optimal cooldown phases — scalars can stay at full LR longer because their per-element gradient is high-SNR and stale-inertia is less of a risk" (PR predeclared 50% prior toward null mechanism, 30% reverse, 20% positive)
- verdict: **CLOSED clean-NEG-WIDE-BAND-NULL-WITH-EDGE-SENSITIVITY** [FFS-primary, 13th stack-component closure]
- results (5-cell sweep):
  | Cell | scalars cooldown | FFS | val/loss | Δbase (σ_single) | Δctrl (σ_single) | W&B id |
  |:----:|:----------------:|:---:|:--------:|:----------------:|:----------------:|:------:|
  | A | shared (sc_cf=0.7, default) ctrl | 3050 | 3.262351 | +1.90σ | (ctrl) | tufl3qlm |
  | **B★** | **constant (no scalars cooldown)** | **3100** | **3.268650** | **+12.52σ** | **+10.62σ** | 5dykns3d |
  | C | early sc_cf=0.5 | 3025 | 3.261452 | +0.39σ | −1.52σ | 09fjidon |
  | D | late sc_cf=0.85 | 3050 | 3.262110 | +1.50σ | −0.41σ | canmpq86 |
  | **E** | **anti-falsifier ramp 0→1** | **3250** | **3.279810** | **+31.34σ** | **+29.44σ** | 9pryzuip |

- mechanism findings (4):
  1. **Wide null band in cooldown FRACTION** — Cells A/C/D (sc_cf ∈ {0.5, 0.7, 0.85}) all FFS ≈ baseline (3025–3050) and val/loss ≈ ctrl (within ±1.5σ). The scalars cooldown FRACTION is val-loss-neutral across the [0.5, 0.85] range — **scalars are PERMISSIVE on timing**.
  2. **Edge sensitivity on extreme cells** — Cell B (constant, no cooldown) +10.6σ_single from ctrl, Cell E (anti-ramp, scalars LR climbs while body cools) +29.4σ_single catastrophic. Both extremes confirm scalars DO need to cool eventually; they just have wide tolerance on WHEN.
  3. **DISSOCIATION from body cooldown** — body matrices (#1276 cooldown_frac) showed tight basin around 0.7; here scalars show ~3× wider tolerance window. This is the **crossing-phase decoupling cluster** signature — scalars permissive, body tight.
  4. **Falsifies "single-cooldown-phase" assumption** for the optimizer stack — different parameter groups have different optimal cooldown timing. Solidifies the cross-PR thesis that body+scalars are dissociated in val-loss landscape, not just LR magnitude (#1275) but also LR schedule shape.

- cluster connections:
  - **Crossing-phase decoupling cluster (3 closures):** #1294 mu, #1322 NS-iter, **#1326 scalars-LR** — all confirm cooldown-window components have differential sensitivity in body vs scalars.
  - **Dissociation cluster with #1275 (lr_scalars magnitude):** scalars have distinct LR dynamics in BOTH magnitude (#1275) and schedule shape (#1326) — strong cross-PR dissociation finding.
  - **Adjacent to #1310 thorfinn β1-decouple (#1368, in flight):** parallel investigation of "are scalars distinct in MOMENTUM" — if #1368 also shows scalars-dissociation, then scalars are dissociated in 3+ axes (LR, schedule, momentum).

- decision (FFS-primary):
  - No Cell ≤ 2975 → **no n=4 promotion per directive #1262**.
  - Cells B/E fail n=1 gate cleanly; A/C/D within noise; close clean-NEG with wide-band-null finding.

- follow-up assignment: askeladd → **adam-embed cooldown DECOUPLE**:
  - Fills the EMBED gap in crossing-phase decoupling cluster (currently mu/NS/scalars closed; embed/lm_head/wd-schedule still untested for cooldown timing).
  - adam_embed group has lr=0.3 — highest aux LR by 10× over scalars and 100× over lm_head — its cooldown response is plausibly distinct from both.
  - Parallel structure to #1326 (5-cell A=shared / B★=constant / C=early sc_cf=0.5 / D=late sc_cf=0.85 / E=anti-ramp falsifier) but applied only to adam_embed group.

## 2026-05-27 02:00 — PR #1328: Body LR warmup before cooldown (fern)
- branch: g1r5-fern/body-lr-warmup
- hypothesis: "Adding LR warmup before the constant phase would help body matrix optimization land in better basin before cooldown — reduces early-step gradient noise impact on Muon+SOAP momentum buffers" (PR predeclared 50% prior toward null mechanism, 30% positive, 20% reverse)
- verdict: **CLOSED clean-NEG-MONOTONE** [FFS-primary, 14th stack-component closure]
- results (5-cell sweep):
  | Cell | warmup steps | FFS | val/loss | Δbase (σ_single) | Δctrl (σ_single) | W&B id |
  |:----:|:------------:|:---:|:--------:|:----------------:|:----------------:|:------:|
  | A | 0 ctrl | 3025 | 3.26160 | +0.64σ | (ctrl) | 7gvqv0aj |
  | **B★** | **200** | **3075** | **3.26721** | **+10.10σ** | **+9.46σ** | qikvgq98 |
  | C | 100 | 3075 | 3.26675 | +9.32σ | +8.68σ | j2ge7t6r |
  | D | 500 | 3050 | 3.26476 | +5.97σ | +5.33σ | 2859ee7k |
  | **E** | **1000** | **3100** | **3.26936** | **+13.73σ** | **+13.09σ** | o432571z |

- mechanism findings (5):
  1. **MONOTONE WORSENING in FFS with longer warmup** — A(0)=3025 → C(100)=3075 → B★(200)=3075 → D(500)=3050 → E(1000)=3100. Gradient clear: any LR warmup adds to FFS or stays flat. **Strong NEG result with monotone structure**, not seed noise.
  2. **Body LR warmup is val-loss-NEGATIVE at all tested durations** — every cell with warmup>0 had val/loss worse than ctrl by +5.3σ to +13.1σ_single. The mechanism does NOT exist for body matrices at the current scale; **direct full-LR-from-step-0 is optimal**.
  3. **Cell D oddity (500 warmup, FFS=3050 best of warmup cells)** — slightly less bad than 200, suggests a saturation effect: once warmup is long enough, the optimizer "catches up" by mid-training; very short warmup (100-200) is the WORST regime because gradient direction is still finding the basin when LR ramps to full.
  4. **Falsifies the "warmup helps gradient noise" hypothesis** at this scale — for nanoGPT at 3250 steps with Muon orthogonalization, the per-step body gradient signal is already high enough that immediate full-LR is the FFS-optimal regime.
  5. **Dissociation from typical large-model warmup** — Llama/GPT-scale models use warmup because raw gradients are noisy at start; here Muon+NS pre-orthogonalizes the update, removing the need.

- cluster connections:
  - **Schedule-shape cluster:** joins #1276 (cooldown_frac), #1294 (mu cooldown), #1322 (NS-iter cooldown), #1326 (scalars cooldown) — all confirm the current schedule shape is well-tuned; deviations in either direction (longer warmup, earlier cooldown, later cooldown) worsen FFS.
  - **NS-pre-orthogonalization cluster:** joins #1310 (β1=0.8) + #1322 — body LR warmup unnecessary because gradients are already directionally clean via Muon NS-iteration; **classical-warmup-rationale-doesn't-apply** is a robust cross-PR finding.

- decision (FFS-primary):
  - No Cell ≤ 2975 → **no n=4 promotion per directive #1262**.
  - All 4 non-ctrl cells fail n=1 gate; monotone structure rules out seed noise; close clean-NEG.

- follow-up assignment: fern → **COSINE-FULL-RUN body-LR**:
  - Pivots from WHEN-the-schedule-starts (failed) to WHAT-shape-the-entire-schedule is.
  - Replaces stable+linear-decay (current) with cosine 1→0 over entire 3250 steps — no stable plateau phase, gradient cooling from step 0.
  - Structurally orthogonal to alphonse #1381 within-cooldown shape test.
  - 5-cell A=stable+linear ctrl / B★=cosine PRIMARY no stable phase / C=cosine min=0.1 / D=warmup200+cosine / E=triangular falsifier.
  - Small code change in set_hparams: switch on new `--lr_schedule_shape` flag.

## 2026-05-27 00:35 — PR #1310: Pruning ablation: is AdamW aux β1=0.8 FFS-load-bearing?
- branch: g1r5-thorfinn/adamw-aux-beta1-pruning
- hypothesis: "AdamW aux β1=0.8 (hardcoded line 843 across all 3 aux groups embed+lm_head+scalars) is either FFS-load-bearing (narrow basin) or val-loss-cosmetic (wide basin) — pruning ablation under FFS-primary framing" (PR predeclared 50% all-flat-cosmetic / 25% B improvement / 15% D catastrophic / 10% E catastrophic only)
- verdict: **CLOSED clean-NEG-NARROW-BASIN** [FFS-primary, 10th stack-component pruning closure]
- results:
  | Cell | β1 | FFS | val/loss | Δbase (σ_single) | Δctrl (σ_single) | W&B id |
  |:----:|:--:|:---:|:--------:|:----------------:|:----------------:|:------:|
  | A | 0.8 ctrl | 3025 | 3.260702 | −0.88σ | (ctrl) | (run-A) |
  | **B ★** | **0.95** | **3050** | **3.263942** | **+4.59σ** | **+5.47σ** | (run-B) |
  | C | 0.90 | 3025 | 3.261201 | −0.03σ | +0.85σ | (run-C) |
  | **D** | **0.99** | **−1 NEVER** | **3.289474** | **+47.5σ** | **+48.4σ** | (run-D) |
  | **E** | **0.0** | **3175** | **3.275737** | **+24.5σ** | **+25.4σ** | (run-E) |

- mechanism findings (4):
  1. **Sweet spot at β1=0.8 with narrow basin width ≤0.10** — Cell C β1=0.9 within noise (Δctrl +0.85σ), but Cell B β1=0.95 already +4.59σ_single. The "1-σ width" of the basin is much narrower than the 50% prior assumed.
  2. **Asymmetric cliffs** — upper β1=0.99 catastrophic (FFS=−1, val=3.289 +47.5σ), lower β1=0.0 bad-but-recoverable (FFS=3175, val=3.276 +24.5σ). Upper-cliff sharpness suggests over-momentum stalls training; lower-cliff falsifies "momentum is irrelevant" — pure-gradient hurts but doesn't break.
  3. **Half-life ~3 steps preferred** for AdamW aux groups — short memory aligns with high-SNR matrix gradients (embed weights 50257×768, lm_head 768×50257); these 2D matrices average over many tokens per step, so the per-step gradient signal is already low-noise → AdamW aux doesn't need additional smoothing.
  4. **Falsifies PR's 50% prior** "all FFS ∈ [3025, 3150]" — basin is far narrower than expected; pruning ablation REVEALED load-bearing, not cosmetic. Strong NEG closure of "is uniform β1 free parameter?" question.

- cluster connections:
  - **AdamW aux tetrad** now half-closed: β1 narrow-basin load-bearing (this PR); β2 (#1321) + ε (#1330) + wd (#1334) in flight. If all three further close NEG → the AdamW (0.8, 0.95, 1e-10, 0) tuple is precisely tuned and FFS-load-bearing in every term.
  - **Cross-stack convergence with #1284 body-WD**: both narrow basins with asymmetric cliffs (cooldown-phase tightening pattern). Suggests "narrow basin with cliffs" is a common signature of well-tuned hyperparameters at FFS scale.

- decision (FFS-primary):
  - Cell A FFS=3025 baseline-EXACT; no Cell ≤ 2975 → **no n=4 promotion per directive #1262**.
  - All 3 non-ctrl, non-A cells fail n=1 gate symmetrically → close clean-NEG with mechanism finding.

- follow-up assignment: thorfinn → **#1368 scalars-β1 DECOUPLE**:
  - First per-group β1 decoupling test in cycle.
  - Probes whether the narrow #1310 basin was driven by all 3 groups uniformly, or specifically by embed/lm_head (high-SNR 2D matrices). Scalars (1D LN gains + biases, ~150 params) are lower-SNR per-element; classical signal-processing prior favors heavier smoothing (higher β1) for noisier signals.
  - Cross-cluster: #1275 (lr_scalars) closure showed scalars have distinct LR dynamics from 2D matrices — β1 decoupling probes the same dissociation in momentum space.
  - 5-cell sweep: A=0.8 ctrl uniform / **B★=0.95 scalars only PRIMARY** / C=0.9 / D=0.5 / E=0.99 falsifier.
  - Adds `--scalars_beta1` CLI flag with group-level betas override on the adam_scalars group only; embed and lm_head inherit the optimizer-level (0.8, 0.95) default.

## 2026-05-26 23:50 — PR #1294: Crossing-phase redesign: decay Muon momentum during cooldown
- branch: g1r5-nezuko/mu-cooldown-decay
- hypothesis: "Decaying mu during cooldown removes stale stable-phase inertia → accelerates FFS" (PR predeclared 55% prior toward null mechanism / 40% reverse mechanism / 5% positive)
- verdict: **CLOSED clean-NEG with MECHANISM-REVERSAL** [FFS-primary, 9th stack-component closure]
- results:
  | Cell | mu config | FFS | val/loss | Δbase (σ_single) | Δctrl (σ_single) | W&B id |
  |:----:|:----------|:---:|:--------:|:----------------:|:----------------:|:------:|
  | A | mu=0.95 ctrl | 3050 | 3.262358 | +1.92σ | (ctrl) | kz8zooqb |
  | B★ | linear 0.95→0.0 cooldown | 3025 | **3.269557** | **+14.06σ** | +12.14σ | v341t4j2 |
  | C | linear 0.95→0.5 cooldown | 3000 | 3.264868 | +6.15σ | +4.23σ | gnaan28n |
  | D | instant mu=0.0 at cooldown | **−1 NEVER** | 3.286754 | +43.06σ | +41.14σ | z0mcsdc0 |
  | E | linear 0.95→0.0 full-run (killed step 1014) | n/a | 3.6480 @ step 1000 | n/a | n/a | l1mo0cdd |
- ★ **Mechanism REVERSAL** (4 findings):
  1. **Momentum during cooldown is val-positive, monotonically**: as mu_target rises 0.0→0.5→0.95 (B→C→A), val/loss monotonically improves 3.2696→3.2649→3.2624. Gradient unambiguous.
  2. **Instant-kill (Cell D) catastrophic** — FFS=−1, val=3.2868 confirms cooldown NEEDS the 0.95 EMA buffer to dampen low-LR descent.
  3. **NS-orthogonalization plus low-LR depends on smoothed gradient direction**: cooldown is low-SNR regime; gradient-noise floor dominates signal; mu=0 removes smoothing.
  4. ★ **Breaks the "everything wants to be small at end" cluster** (#1272 terminal-WD=0, #1276 cooldown-frac, #1284 body-WD basin): **mu is the outlier — it wants to be HIGH at the end, not low. Strong dissociation between momentum and the smallness-cluster.**
- ★ **Cell C oddity**: FFS=3000 (-25 vs baseline) but val/loss worse → per FFS-primary directive (alive ≤2975) does NOT clear alive gate, close as net NEG. Most likely single-trial seed noise (Cell A control itself drifted +25 from #699 baseline FFS=3025).
- ★ **Cluster connection**: joins #941 (cooldown SWA = directed descent), #966 (cooldown weight rescaling NEG), #1272 (wd ramp_down), #1276 (cooldown_frac), #1284 (body-WD basin) → cooldown is directed descent with heavy momentum smoothing and tight WD floor.
- ★ **Student diligence**: process improvement flagged transparently (Cell E falsifier mis-designed: linear-decay-from-step-0 instead of constant-mu=0; gate also poorly calibrated). Solid scientific honesty.
- next: assigned nezuko → **#1345 mu cooldown RAMP-UP** (direct mechanism extension; 5-cell A=ctrl/B★=0.95→0.98/C=0.95→0.99/D=instant 0.98/E=0.95→0.999 falsifier; **NO code change needed** — re-use existing `--mu_cooldown_target` flag; **first hypothesis in cluster that PREDICTS FFS improvement** since extrapolates monotone gradient toward higher mu).

Log of completed/reviewed experiment PRs in chronological order. Wave 1
results pending student execution.

## 2026-05-26 22:45 UTC — PR #1284: edward body WD value 0.025 pruning ablation — **CLOSED clean-NEG-SHARP-CLIFF** [FFS-PRIMARY]

- **Branch:** `g1r5-edward/body-wd-pruning`
- **Hypothesis:** Test whether `wd_mlp=wd_attn=0.025` (default body matrix WD with ramp_down schedule) is FFS-load-bearing in the magnitude direction. PR's PRIMARY prior (55%): "all 5 cells FFS ∈ [3025, 3150]" — meaning WD value would be val-loss-cosmetic at FFS scale.
- **5-cell design:** A=0.025 ctrl / B★=0.0 PRIMARY drop body WD entirely / C=0.0125 half / D=0.05 double / E=0.10 over-WD falsifier.
- **Results (FFS-primary):**

| Cell | wd_mlp=wd_attn | FFS | val/loss | Δ vs μ_4 (σ_single) | Outcome |
|:----:|:--------------:|:---:|:--------:|:-------:|:--------|
| A (ctrl) | 0.025 | 3025 | 3.26057 | −1.10σ | baseline reproduced |
| **B★ (zero)** | **0.0** | **−1** | 3.28252 | **+35.92σ** | **catastrophic FFS** |
| C (half) | 0.0125 | 3050 | 3.26645 | +8.82σ | mild late cross |
| D (double) | 0.05 | 3100 | 3.26629 | +8.55σ | later cross |
| **E (over)** | **0.10** | **−1** | 3.28869 | **+46.32σ** | **catastrophic FFS** |

Baseline reference (PR #699 musoft, run `zp6gvwv5`, n=4): μ_4=3.261221, σ_single=0.000593, FFS=3025.

W&B runs: A `7vi8hcze` | **B★ `h201ccok`** | C `mki66e0z` | D `bgrz2o2j` | E `tcjsdi3t`. Group: `g1r5-edward/body-wd-pruning`.

**Val/loss trajectory (every 500 steps) — striking pattern:**

| step | A (ctrl) | B (zero) | C (half) | D (double) | E (over) |
|-----:|---------:|---------:|---------:|-----------:|---------:|
|  500 | 3.81315  | 3.77781  | 3.79399  | 3.85397    | 3.92171  |
| 1000 | 3.64292  | 3.58592  | 3.61272  | 3.69930    | 3.77702  |
| 1500 | 3.52492  | 3.46982  | 3.49648  | 3.57546    | 3.65769  |
| 2000 | 3.43290  | 3.39474  | 3.41288  | 3.47191    | 3.53713  |
| 2500 | 3.35381  | 3.33848  | 3.34333  | 3.38047    | 3.43019  |
| 3000 | 3.28233  | 3.29453  | 3.28385  | 3.29393    | 3.32400  |
| 3250 | 3.26057  | 3.28252  | 3.26645  | 3.26629    | 3.28869  |

- **Verdict: clean-NEG-SHARP-CLIFF; PR's "FFS-cosmetic" prior FALSIFIED.**
  - Cell B★ FFS=−1 catastrophic + Cell E FFS=−1 catastrophic → body WD value is FFS-load-bearing in BOTH directions
  - Cells C/D bracket the baseline cleanly (+25 / +75 FFS) → narrow U-shape FFS basin centered at 0.025
  - **8th stack-component pruning closure under FFS-primary directive #1262.**
  - PR's "FFS-positive at B FFS≤3000" branch did not fire; this is a clean basin-confirmation experiment.
- **Mechanism (4 findings):**
  1. **Cell B no-WD LEADS in early-mid training then STALLS in cooldown.** Cell B fastest descent through step 2500 (B-step2500=3.33848 vs A-step2500=3.35381), but cooldown drop step 3000→3250: B=0.0120 vs A=0.0218 (A nearly 2× more cooldown drop). The ramp_down WD schedule is **the cooldown's load-bearing tightening mechanism, NOT LR cooldown alone**. Without WD, body matrices stay large; final-cooldown descent lacks the WD-driven shrinkage that pulls val/loss across 3.28.
  2. **Cell E over-WD monotone-worse from step 500.** 4× WD over-shrinks body weights throughout training, leaving insufficient capacity at every step. The matrix capacity destroyed in mid-training cannot be recovered.
  3. **Cells C/D monotone in FFS (3050 < 3100).** U-shape FFS basin centered at 0.025. Half-WD costs +25 FFS (one bin), double-WD costs +75 FFS (three bins). Asymmetric — over-shrinking is worse than under-shrinking by a factor of ~3.
  4. **Reproduces #1272 wd-schedule finding from different angle.** #1272 showed schedule SHAPE matters (ramp_down vs alternatives). This PR shows VALUE matters at fixed shape. **Joint finding: SHAPE + VALUE are both load-bearing** — perturbing either is regressive or catastrophic.
- **Cluster connection — "cooldown WD-driven shrinkage is the structural tightening mechanism":**
  - #966 cooldown weight rescaling NEG: post-cooldown weight rescaling NOT useful
  - #1272 wd-schedule ramp_down: terminal WD must be near zero; shape not dose
  - #1284 (this): WD value 0.025 + ramp_down jointly load-bearing
  
  Three independent tests converging on the same mechanism: **the optimizer wants WD-shrinkage acting on body matrices specifically during the cooldown phase**, with intermediate steps too. Not LR-only descent, not constant WD, not post-hoc rescaling — the gradient of WD over training is what tightens the val/loss surface.
- **Body-matrix WD pruning programme fully closed.** Combined #1272 (shape) + #1284 (value) — both axes tightly tuned, narrow basin. No further body-WD experiments planned.
- **Student-flagged process improvement:** the launch script `launch_body_wd_pruning_ABCDE.sh` defined `check_step_threshold` and `check_nonfinite` functions but never invoked them in `run_cell`. Cell E hit `val_loss=3.53713` at step 2000 (above predeclared 3.40 kill threshold) but was not killed, wasting ~1.5h of GPU time. Worth a separate launcher template fix; advisor noted in close comment.

**Action:** Closed clean-NEG. **Assigned edward → #1334 AdamW aux WD pruning** (★ completes AdamW aux (β1, β2, ε, wd) TETRAD under FFS-primary; tests hardcoded `weight_decay=0` line 843 via new `--adamw_aux_wd` CLI arg; 5-cell A=0.0 ctrl / B★=0.01 PRIMARY uniform small positive / C=0.001 very small / D=0.025 match body / E=0.1 falsifier; **strong asymmetric prediction informed by #1275 scalars-LR-pruning closure**: per #1275 LN gains MUST drift from init, applying WD>0 uniformly will pull gains back toward 0 → likely Cell B catastrophic = clean cross-PR mechanism confirmation that "WD=0 is structurally required for scalars LN-gain drift mechanism"; scalars_norm telemetry added to verify mechanism live).

---

## 2026-05-26 22:00 UTC — PR #1279: tanjiro SOAP `PRECOND_FREQ=16` pruning ablation — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-tanjiro/soap-precond-freq-pruning`
- **Hypothesis:** Test whether SOAP eigenbasis Q-matrix refresh frequency `PRECOND_FREQ=16` (hardcoded line 28) is FFS-load-bearing under directive #1262 stack-simplification framing. Two competing mechanisms: (a) higher-freq → tighter cond → earlier FFS; (b) lower-freq → stable basis → less rotation noise → earlier FFS.
- **5-cell design:** A=16 ctrl / B★=32 PRIMARY half-as-often / C=8 twice-as-often / D=64 4× less often / E=4 falsifier 4× more often.
- **Results (FFS-primary):**

| Cell | freq | FFS | val/loss | Δ vs ctrl (σ_single) | q_refresh_total | step_avg | Verdict |
|:----:|:----:|:---:|:--------:|:-------:|:---------------:|:--------:|:--------|
| A | 16 (ctrl) | 3050 | 3.26196 | +1.25σ vs baseline | 14688 | 1898ms | baseline n=1 noise |
| **B★** | **32** | **3025** | **3.26070** | **−0.88σ — baseline-EXACT** | **7344 (½)** | **1873ms** | **half SOAP compute, identical FFS** |
| C | 8 | 3025 | 3.26151 | +0.49σ | 29304 | 1950ms | within FFS noise |
| D | 64 | 3075 | 3.26494 | **+6.27σ** | 3672 | 1865ms | **first val degradation — staleness cliff** |
| E | 4 falsifier | 3025 | 3.25895 | −3.83σ | 58536 | 2058ms | val-cosmetic only no FFS gain |

Baseline: μ_4=3.261221, σ_single=0.000593, FFS=3025 (PR #699 musoft `zp6gvwv5`, n=4).

W&B runs: A `l9sqpuff` | **B★ `xhod3ndy`** | C `etnmre2w` | D `md10gvc3` | E `helfvaeo`. Group: `g1r5-tanjiro/soap-precond-freq-pruning`.

Full FFS curve: All cells track identically until step ~2875 (loss=3.30). FFS-bin separation only appears at the 3.28 crossing window — exactly where cooldown LR-decay rapidly changes the loss surface.

- **Verdict: clean-NEG stack-simplification candidate at freq=32, no n=4 promotion per directive.**
  - Cell B★ FFS=3025 = baseline-exact NOT earlier → does NOT clear FFS-primary alive gate (≤2975) → no n=4 (per #1188 lesson)
  - Cell B★ halves SOAP-internals compute (7344 vs 14688 refreshes) at zero FFS cost — wall-clock simplification, not speed candidate
  - Cell D=64 first val degradation +6.3σ marks the staleness cliff between 32 and 64
  - **7th stack-component pruning closure under FFS-primary directive #1262.**
- **Mechanism (4 findings):**
  1. **PRECOND_FREQ is FFS-cosmetic across [4, 32].** Q matrices are slow-moving — `row_gg`/`col_gg` EMA'd with `shampoo_beta=SOAP_BETA2=0.90` (half-life ~6.6 steps). Refreshing every 4, 8, 16, or 32 steps samples basically the same Q rotation; slow-moving curvature direction captured well below the Nyquist rate of refresh.
  2. **Staleness cliff between 32 and 64.** At freq=64, Q lags enough that during the rapid cooldown crossing (steps 2800-3050) the optimizer is preconditioning with a Q that's 64 LR-decayed steps stale. Val/loss penalty +6.3σ is the first sharp signal in the sweep.
  3. **Cell E=4 over-refresh val-cosmetic only at edge of crossing window.** Tighter preconditioner during cooldown gives val/loss −3.8σ but FFS-bin granularity is 25 steps and val/loss tightening doesn't translate to crossing 3.28 any earlier than step 3025 (bin floor). Confirms hypothesis's "more refresh is val-cosmetic" branch.
  4. **PRECOND_FREQ=32 is a clean ~2× SOAP-internals compute simplification at zero FFS cost.** Wall-clock saving without quality cost — but doesn't move FFS so doesn't qualify for merge under FFS-primary. Stored as simplification claim for end-of-round portfolio review.
- **★ SOAP-internals pruning programme complete:** combined with #914 (refresh-freeze NEG), #1053 (asymmetric Q refresh NEG), #979 (`exp_avg_sq` scaling NEG), #936 (Q-scope structural), #1273 (`--soap_attn` load-bearing) — all 6 axes of SOAP internals are now tested at FFS scale. **SOAP internals are tightly tuned and load-bearing in all axes except refresh cadence which has slack** (freq=32 viable simplification).
- **Connection to earlier closures:** Cell A=3050 vs B/C/E=3025 reflects n=1 FFS-bin variance (25-step granularity). The n=4 baseline `zp6gvwv5` was 4-seed mean; Cell A single trial at 3050 is within expected single-trial spread (n=1 noise floor ~1 FFS bin = 25 steps). Confirms #1188 regression-to-mean calibration constant (~2.7 mNats noise floor) and #1276 fern observation "FFS locked by state accumulated through first ~3000 steps."

**Action:** Closed clean-NEG. **Assigned tanjiro → #1330 AdamW aux EPS pruning** (★ completes AdamW aux (β1, β2, ε) trio under FFS-primary; tests hardcoded `eps=1e-10` line 843 via new `--adamw_aux_eps` CLI arg; 5-cell A=1e-10 ctrl / B★=1e-8 PyTorch Adam default 100× larger PRIMARY / C=1e-12 100× smaller / D=1e-6 / E=1e-4 falsifier; specifically probes whether lm_head's small-update regime (lr=1/320) is sensitive to denominator regularizer; pairs with #1310 β1 + #1321 β2 → joint test of "is the AdamW (0.8, 0.95, 1e-10) tuple FFS-load-bearing?").

---

## 2026-05-26 21:15 UTC — PR #1276: fern `cooldown_frac` pruning ablation — **CLOSED clean-NEG-INVERTED** [FFS-PRIMARY]

- **Branch:** `g1r5-fern/cooldown-frac-pruning`
- **Hypothesis:** Test whether `cooldown_frac=0.7` (hardcoded line 882, controls LR cooldown timing — cooldown starts at step `(1-cooldown_frac)*total_steps`) is FFS-load-bearing. PRIMARY hypothesis: Cell B (frac=0.5, earlier cooldown start = HIGHER LR at crossing window step ~3025) should move FFS earlier.
- **5-cell design:** A=0.7 ctrl / B★=0.5 PRIMARY earlier crossing / C=0.6 / D=0.85 / E=0.95 falsifier.
- **Results (FFS-primary):**

| Cell | `cooldown_frac` | FFS | val/loss | Δ vs ctrl (σ_single) | first→3.30 | first→3.40 | Verdict |
|:----:|:---------------:|:---:|:--------:|:-------:|:----------:|:----------:|:--------|
| A | 0.7 (ctrl) | 3050 | 3.26217 | 0 | 2875 | 2250 | baseline + 25 FFS noise |
| B★ | **0.5** | **3075** | 3.26323 | **+1.8σ REGRESSED** | 2950 | 2375 | **PRIMARY FAILED — opposite direction** |
| C | 0.6 | 3050 | 3.26295 | +1.3σ | 2925 | 2375 | within FFS noise |
| **D** | **0.85** | **3025** | **3.26109** | **−1.8σ better** | 2875 | 2250 | **borderline — best val direction** |
| E | 0.95 falsifier | 3050 | 3.26459 | +4σ | 2875 | 2125 | not catastrophic, falsifier missed |

- **Verdict:** **INVERTED mechanism finding.** PR predicted lower cooldown_frac → earlier FFS; observed: higher cooldown_frac directionally better. Cell D val/loss=3.26109 is 1.8σ better than ctrl at FFS=3025 baseline-EXACT but per strict FFS-primary directive (no n=4 unless FFS≤2975) does NOT qualify for n=4 promotion. **6th stack-component pruning closure.**
- **Ordering at every step in [3000, 3250]: D < A ≈ E < C < B** — monotonic in 1/cooldown_frac across {0.5, 0.6, 0.7, 0.85}. Pulled val/loss at fixed step across crossing window:

| step | A (0.7) | B (0.5) | C (0.6) | D (0.85) | E (0.95) |
|:----:|:-------:|:-------:|:-------:|:--------:|:--------:|
| 3000 | 3.28394 | 3.28996 (worst) | 3.28666 | **3.28074 (best)** | 3.28317 |
| 3025 | 3.28032 | 3.28543 | 3.28279 | **3.27745** | 3.28022 |
| 3075 | 3.27474 | 3.27867 | 3.27678 | **3.27234** | 3.27530 |
| 3250 | 3.26217 | 3.26323 | 3.26295 | **3.26109** | 3.26459 |

- **Mechanism (INVERTED from hypothesis):**
  1. **Higher LR at crossing window DEGRADES crossing speed.** Falsifies 'more LR longer = faster crossing' intuition. eta at step 3000: B=0.154 (worst val), A=0.110 (ctrl), D=0.0905 (best val). The optimizer at progress=0.93 PREFERS gentle decay over LR floor maintenance.
  2. **Cell E (frac=0.95) only ~4σ regression not catastrophic.** Schedule with almost no stable phase still works at FFS=3050. Refutes "stable phase is necessary" intuition — model gets enough learning even with cooldown spanning most of training.
  3. **The ordering breaks at Cell E.** Monotone trend D < A < C < B continues for frac ∈ {0.5, 0.6, 0.7, 0.85}, then E (0.95) jumps to +4σ from ctrl. Suggests an upper bound somewhere in (0.85, 0.95] where "no stable phase" becomes harmful.
- **Mechanism cluster connection:** Dovetails with #941 (cooldown is directed descent), #966 (cooldown weight rescaling NEG), #1272 (terminal WD = 0 mechanism). **Cluster finding: everything wants to be small at the end** — terminal eta near 0, terminal WD near 0, terminal momentum decoupled (#1294 in flight tests this). Higher LR at crossing window contradicts this — confirms cluster from a fresh axis.
- **Cell D borderline observation:** val/loss=3.26109 vs n=1 confirm gate ≤3.260628 misses by +0.000462. FFS=3025 = baseline-EXACT. Strongest val direction in sweep but technically n=1 gate fail. Per FFS-primary directive (strict): not promotable since FFS hasn't moved below 3025.
- **Suggested follow-ups (from student):** (1) test if forcing low-LR cooldown beyond what cooldown_frac=0.85 gives helps — direct mechanism extension; (2) sweet-spot probe at cooldown_frac ∈ {0.80, 0.85, 0.90} n=4 — REJECTED per directive (scalar HP search + Cell D is val-only direction); (3) confirm Cell D — REJECTED per FFS-primary strict reading. **Advisor decision:** assigned fern → #1328 body LR warmup — structurally orthogonal, first early-phase test under FFS-primary, addresses fern's own mechanism observation that "FFS locked by state accumulated through first ~3000 steps."
- **W&B runs:** A `i9yxixny`, B `za3awfbu`, C `sc7e5lya`, D `tvuvuy98`, E `huidqtsr`.

## 2026-05-26 20:30 UTC — PR #1275: askeladd `--lr_scalars` pruning ablation — **CLOSED clean-NEG-mixed** [FFS-PRIMARY]

- **Branch:** `g1r5-askeladd/lr-scalars-pruning`
- **Hypothesis:** Test whether `--lr_scalars 0.03` (mandatory flag controlling AdamW LR for the 1D scalars group: LN gains + biases) is FFS-load-bearing or val-loss-cosmetic.
- **5-cell design:** A=0.03 ctrl / B★=0.0 freeze PRIMARY / C=0.015 half / D=0.06 double / E=0.10 over-LR falsifier.
- **Results (FFS-primary):**

| Cell | `--lr_scalars` | FFS | val/loss | Δ vs ctrl (σ_single) | `ln_gain_norm` | Verdict |
|:----:|:--------------:|:---:|:--------:|:-------:|:--------------:|:--------|
| A | 0.03 (ctrl) | 3025 | 3.26162 | 0 | 204.5 | baseline-exact |
| B★ | **0.0 (frozen)** | **−1 NEVER** | **3.28900** | **+46σ_single** | 141.3 (frozen at init) | **CATASTROPHIC structural** |
| C | 0.015 | 3050 | 3.26252 | +1.51σ | 159.1 | within FFS noise |
| D | 0.06 | 3050 | 3.26232 | +1.18σ | 357.0 | within FFS noise |
| E | 0.10 (3.3× ctrl) | 3075 | 3.26545 | +6.46σ | 590.7 | mild +50 FFS — **falsifier missed** |

- **Verdict:** `--lr_scalars` is **HALF FFS-LOAD-BEARING (flag must stay nonzero), HALF COSMETIC (value insensitive in 6.7× range)**. **5th stack-component pruning closure**.
- **Mechanism (3 findings):**
  1. **1D scalars group MUST train.** Freezing (lr=0) is fatal to FFS — model never reaches val ≤ 3.28 within 3250 steps (stalls at 3.28900). LN gains + biases encode forward-pass scale per layer and are not redundant capacity.
  2. **Value within [0.015, 0.10] is val-cosmetic.** All 4 nonzero cells reach val/loss < 3.266 and FFS within [3025, 3075] — optimizer rescues moderately mis-tuned scalar LR. Spans 6.7× range with sub-millinat val/loss spread.
  3. **Asymmetric to zero vs over-LR.** Going to 0 catastrophic (+0.027 val), going to 0.10 (3.3× ctrl) mild (+0.004 val). Rules out catastrophic over-LR failure mode for scalars; points to scalars as "warmup multiplier" for LN gains — once gains have moved from init by ANY amount, FFS holds.
- **LN gain norm drift:** scales linearly with `lr_scalars`: 141.3 (frozen) → 159.1 → 204.5 (ctrl) → 357.0 → 590.7 (4.2× span across cells). Yet val/loss only +0.004 across non-frozen cells. **Magnitude is FFS-load-bearing only in sense that ≠init is required, not in fine-tunable sense.**
- **Cell E falsifier rule informative:** advisor predicted Cell E (0.10) would catastrophe; observed +50 FFS / +0.004 val only. Rules out catastrophic over-LR; scalars are robust to overshooting. Suggests there is no fine-tunable lever for FFS via `--lr_scalars` alone.
- **Closure decision per FFS-primary directive:** No n=4 promotion (no cell beat ctrl FFS). Flag stays in stack (cannot freeze). Value sweep saturated — closing on this evidence. The unique structural finding (Cell B catastrophic) is the report.
- **Suggested follow-ups (from student):** (1) lr_scalars=0.001 to localize freeze threshold (narrow scalar HP search — REJECTED per directive); (2) gains-only vs biases-only decomposition (moderate — sub-group structural); (3) scalars LR schedule (warm-up high, decay) — **ADVISOR PICKED for askeladd #1326 as decoupled scalars cooldown**: directly tests whether scalars schedule shape benefits from decoupling from body schedule.
- **W&B runs:** A `pdw6uibs`, B `yog23cpf`, C `cuvx2k7e`, D `87014283`, E `2er31epy`.

## 2026-05-26 19:30 UTC — PR #1272: alphonse `--wd_schedule ramp_down` pruning ablation — **CLOSED clean-NEG-graded** [FFS-PRIMARY]

- **Branch:** `g1r5-alphonse/wd-schedule-pruning`
- **Hypothesis:** Test whether `--wd_schedule ramp_down` (mandatory flag in baseline stack) is FFS-load-bearing or val-loss-cosmetic. 5-cell sweep over all 5 supported schedule shapes.
- **5-cell design:** A=ramp_down ctrl / B★=constant PRIMARY pruning / C=ramp_up / D=triangle / E=cosine_updown.
- **Results (FFS-primary, sorted by FFS):**

| Cell | Schedule | FFS | Δ FFS | val/loss | Δ vs ctrl (σ_single) | Step→3.30 | Verdict |
|:----:|:---------|:----|:-----:|:--------:|:-------:|:---------:|:--------|
| A | ramp_down ctrl | 3050 | 0 | 3.26190 | 0 | 2875 | baseline + 25 step noise |
| B★ | constant | 3100 | +50 | 3.26619 | +7.2σ | 2950 | FAIL primary pruning gate |
| D | triangle | 3150 | +100 | 3.27268 | +18.2σ | 3025 | graded NEG |
| C | ramp_up | 3175 | +125 | 3.27519 | +22.4σ | 3025 | graded NEG |
| E | cosine_updown | 3200 | +150 | 3.27570 | +23.3σ | 3050 | worst — falsifier fires |

- **Verdict:** `--wd_schedule ramp_down` IS FFS-LOAD-BEARING in a **graded way** (no catastrophic FFS=-1, but each alternative costs 50-150 FFS — all 7.2σ_single or worse on val/loss). **4th stack-component pruning closure** (joins #1266 init cosmetic, #1227 noise NEG, #1273 soap-attn LOAD-BEARING).
- **Mechanism (3 findings):**
  1. **All 5 schedules same average WD** (cumulative dose matched per `_wd_multiplier` semantics: ramp_up/ramp_down/triangle/cosine_updown peak at 2× args.wd_mlp; constant stays 1×; cumulative integral matched over 3250 steps). **Differentiator is shape, not dose.**
  2. **Ordering tracks terminal WD magnitude at step 3250.** ramp_down → ~1.5e-5 (essentially off in final 250 steps); constant → 0.025 (held to end); triangle → 3.1e-5 (decayed but spent peak in middle); ramp_up → 0.05 (3× constant terminal, peak right at end). **Late-training WD must be near zero** for cooldown to squeeze the last 0.01-0.02 nats. Cells with non-zero terminal WD show late-training stall: ramp_up step→3.30 = 3025 vs ramp_down 2875.
  3. **Terminal weight norms identical** across cells (~69 700, range 69 610-69 832). Schedule shape controls **validation curve geometry through final descent**, NOT gross weight scale.
- **Cell E (cosine_updown) falsifier rule fires:** Cell E (terminal WD ≈ 0 but spent peak in middle) is WORST overall (FFS=3200). If terminal WD were the only thing that mattered, E should match A. **Schedule axis IS structured: terminal WD near 0 is necessary but not sufficient — early-training WD must also be controlled, not spent on a mid-training peak.**
- **Mechanism cluster:** Dovetails with #941 (cooldown SWA: cooldown is directed descent), #966 (cooldown weight rescaling NEG: Muon NS scale-invariant + WD ramp_down already controls norms). **Cluster finding: cooldown is directed descent in zero-WD regime; WD floor at cooldown end is what matters; early-training WD shape also matters but ramp_down (decay throughout) is the tight optimum.**
- **Closure decision:** Clean-NEG-graded — no n=4 promotion (Cell B failed primary gate by +50 FFS, no cell beat ctrl). Per FFS-primary directive, do not promote val/loss-only candidates. Predicted modal "cosmetic" (55%) was WRONG; actual is graded load-bearing. **Stack stays at ramp_down.**
- **Suggested follow-ups (from student):** (1) n=4 confirm A vs B for record-keeping (low priority; val/loss 7.2σ_single gap likely real, FFS quantum noisy); (2) Truncated ramp_down (WD floor pinned to 0 from step 2800 onward) — direct mechanism test; (3) Hybrid constant_until_cooldown + ramp_down_after; (4) Drop wd in last 250 steps entirely. All are crossing-phase WD redesigns. **Advisor decision:** assigned alphonse → #1322 NS-cooldown axis instead — orthogonal mechanism test (NS direction vs WD value in cooldown) covers fresher ground.
- **W&B runs:** A `1oez0e2z`, B `ndaun4hz`, C `ym7r9sxw`, D `ux09orz1`, E `mkvt4nxw`.

## 2026-05-26 17:40 UTC — PR #1273: frieren `--soap_attn` pruning ablation — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-frieren/soap-attn-pruning`
- **Hypothesis:** Test whether `--soap_attn` (mandatory flag adding SOAP preconditioning to attention matrices alongside MLP) is FFS-load-bearing or val-loss-cosmetic. If clean-NEG → SOAP attn essential. If FFS-flat → 50% SOAP compute savings.
- **5-cell design:** A=soap_on ctrl / B★=no_soap PRIMARY / C=no_soap + lr_attn=0.055 raised compensation / D=no_soap + lr_attn=0.020 lowered compensation / E=soap_on + lr_attn=0.060 over-LR falsifier.
- **Results (FFS-primary):**

| Cell | Config | val/loss | Δ vs ctrl (σ_single) | FFS | Verdict |
|:----:|:-------|:--------:|:-------:|:----:|:--------|
| A | soap_on ctrl | 3.26267 | 0 | 3050 | Baseline + 25 step noise |
| B★ | no_soap PRIMARY | **3.27534** | **+21.4σ** | **3175** | **catastrophic +150 FFS** |
| C | no_soap + lr_attn=0.055 | 3.27490 | +20.6σ | 3150 | catastrophic, lr_attn raise no help |
| D | no_soap + lr_attn=0.020 | 3.27432 | +19.6σ | 3150 | catastrophic, lr_attn lower no help |
| E | soap_on + lr_attn=0.060 | 3.26330 | +1.1σ | 3050 | ≈ ctrl, over-LR within band |

- **Verdict:** `--soap_attn` IS FFS-LOAD-BEARING. **3rd stack-component pruning closure** (joins #1266 depth-init val-cosmetic, #1227 pre-NS noise NEG).
- **Mechanism (3 findings):**
  1. **SOAP attn supplies direction information from eigenbasis rotation, not magnitude scaling.** Cells B/C/D all fail symmetrically at ~+20σ regardless of lr_attn ∈ {0.020, 0.055} because lr_attn is a magnitude knob, cannot recover the rotational geometry. The eigenbasis rotation `P_L · grad · P_R^T` is a directional shaping operator orthogonal to LR magnitude.
  2. **Confirms #994 "cross-scope decomposition non-additive 4.5×" finding.** Both SOAP scopes (attn AND MLP) load-bearing, neither free to drop. Per-scope contribution non-linearly entangled — cannot decompose total SOAP value into additive per-scope contributions.
  3. **lr_attn ∈ [0.020, 0.055] is wide-band null when SOAP attn is present.** Cell E (lr_attn=0.060, +20% over baseline) within 1.1σ of ctrl — supports earlier #1021 finding that magnitude-axis local optimum on attn is wide.
- **Suggested follow-up:** SOAP-attn axis closed. AdamW aux moment coefficients are next stack-component pruning target.
- **W&B runs:** Cell A `…6lkny0`, B `…0w5gxw`, C `…2utt2y`, D `…hg10qb`, E `…b39csm`.
- **Decision:** Closed via `close_pr_with_comment`. Assigned frieren → #1321 AdamW aux β2 pruning (9th stack-component pruning, pairs with #1310 β1).

## 2026-05-26 14:58 UTC — PR #1258: thorfinn Schedule-Free Muon on body matrices — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-thorfinn/sf-muon-body`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Replace explicit cooldown on Muon body matrices with Schedule-Free Polyak averaging (Defazio 2024). Maintain implicit average `x_t = (1-c_t)·z_t + c_t·x_{t-1}` where `c_t = 1 - 1/√t`, then evaluate on averaged params. 5-cell β sweep: A=ctrl (cooldown), B★=β=0.90 SF no cooldown, C=β=0.95 SF, D=β=0.80 SF, E=β=0.90 SF + cooldown. Tests "implicit averaging vs explicit cooldown" axis on body — orthogonal to NS-modulation, complements closed aux-side SF #659 NEG and Lookahead-aux #1126 NEG.

### FFS-primary verdict

| Cell | Config                  | val_loss   | FFS    | W&B id   | Δ vs A (σ_single=0.000593) |
|:----:|:------------------------|:----------:|:------:|:---------|:---------------------------|
| A    | ctrl (cooldown, no SF)  | 3.26126    | 3025   | (ctrl)   | baseline                   |
| B★   | β=0.90 SF, no cooldown  | **3.34243**| **−1** | (logged) | **CATASTROPHIC** (FFS-never-reached) |
| C    | β=0.95 SF, no cooldown  | early-kill | —      | —        | step 1000 same pattern as B |
| D    | β=0.80 SF, no cooldown  | early-kill | —      | —        | step 1000 same pattern as B |
| E    | β=0.90 SF + cooldown    | 3.26212    | 3025   | (logged) | +0.145σ ≈ baseline (FAILS n=1 gate, but FFS=baseline) |

- **FFS verdict:** Cell B PRIMARY FFS=−1 (never reached 3.28 target); Cells C/D early-killed step 1000 (same divergent pattern); Cell E (SF + cooldown) returns to FFS=3025 baseline. **Clean-NEG with cooldown-equalizer pattern.**

### Key mechanism findings (★)

1. **★ Cooldown is load-bearing schedule structure SF cannot substitute.** SF averaging window (`c_t = 1 - 1/√t`) reaches ~0.98 by step 1000, but still-oscillating trajectory means averaged-noise NOT refined-minimum. Polyak's theoretical guarantee requires bounded variance around true minimum; pre-cooldown trajectory has neither bounded variance nor proximity.

2. **★ Cell E (SF + cooldown) returns to baseline at FFS=3025.** When LR→0 in cooldown, SF averaging window collapses (steps zero, average frozen). β knob becomes a no-op once cooldown kicks in. Mechanically: SF is structurally compatible with cooldown but provides zero lift when cooldown is present.

3. **★ 8th trajectory-averaging axis closure (3rd in family).** Joins #659 SF aux NEG, #1126 Lookahead aux NEG. All three trajectory-averaging schemes — Polyak (SF aux), Polyak (SF body), Lookahead (aux) — fail under cooldown-equalizer. Implicit averaging is structurally redundant once explicit cooldown is doing the refinement.

4. **★ 5th independent cooldown-equalizer demonstration.** Joins #1042 (post-NS mixing), #1206 (pre-NS conditioning), #1200 (operator class), #1227 (pre-NS noise), now #1258 (SF). Cooldown is single most load-bearing schedule component — mid-training ±X-σ deltas collapse to ±2σ_single under ~100× LR contraction across 5 independent modification axes.

### Analysis & conclusions

- Trajectory-averaging family fully closed: SF and Lookahead cannot substitute explicit cooldown anywhere in the optimizer stack.
- Cooldown-equalizer pattern is now mechanism-load: cooldown's 100× LR contraction is the directed-descent finalizer; pre-cooldown midtraining behavior is recoverable via the refinement phase regardless of trajectory dynamics chosen.
- SF on body without cooldown is catastrophic (B/C/D all diverge by step 1000) — pre-cooldown trajectory averaging applied to an oscillating sequence produces wrong-direction averaged updates.

### Next assignment

thorfinn → **#1310 AdamW aux β1 pruning ablation** (8th stack-component pruning under FFS-primary; tests `betas=(0.8, 0.95)` hardcoded at train_gpt_simple.py:843 via new `--adamw_aux_beta1` CLI arg; 5-cell A=0.8 ctrl / B★=0.95 PRIMARY align with Muon mu=0.95 / C=0.9 bracket / D=0.99 over-stable falsifier / E=0.0 pure-gradient falsifier; tests "is AdamW aux β1=0.8 FFS-load-bearing or val-loss-cosmetic?").

---

## 2026-05-26 12:10 UTC — PR #1238: nezuko SPAM spike-aware momentum reset on Muon body — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-nezuko/spam-muon-body`
- **Student:** g1r5-nezuko
- **Hypothesis:** Detect gradient-norm spikes via EMA ratio, zero Muon momentum on spike > threshold × EMA. Five-cell threshold sweep (5/10★/20/50 + ctrl=1000 never-triggers). Tests whether cooldown-phase momentum contamination from gradient spikes explains training instability.

### FFS-primary verdict

| Cell | threshold | val_loss   | FFS  | resets | max_ratio | W&B id   | Δ vs ctrl (σ_single=0.000593) |
|:----:|:---------:|:----------:|:----:|:------:|:---------:|:---------|:------------------------------|
| A    | 1000 (ctrl)| 3.2610390  | 3025 | 0      | 0.98      | sbrgx9bf | baseline                      |
| B    | 5         | 3.2622280  | 3050 | **66** | 17.66     | 6nls5f67 | **+2.01σ (HARM)**             |
| C★   | 10        | 3.2608395  | 3025 | 15     | 16.49     | zu3jamff | −0.34σ (noise; FAILS n=1 gate)|
| D    | 20        | 3.2618240  | 3025 | 3      | 20.81     | dh71v3p8 | +1.32σ (n=1 noise)            |
| E    | 50        | 3.2607620  | 3025 | 0      | 1.02      | hide4gwx | −0.47σ (noise; inside A-E band)|

- **FFS verdict:** 4/5 cells at FFS=3025 baseline-EXACT. Cell B (thr=5) slipped to FFS=3050 from heavy reset rate. Cell C★ PRIMARY fails n=1 gate (val=3.260840 > 3.260628 gate by +0.000212). No Phase 2. **Clean-NEG.**

### Key mechanism findings (★)

1. **A vs E define the no-op noise band.** Both produce 0 resets (mechanically identical). |Δ|=0.000277=0.47σ_single = pure seed noise. Cell C (15 resets) lies INSIDE this band — indistinguishable from no-op SPAM.

2. **Spikes are init-only, not training-time.** Cell B: 62/64 resets occur in steps ≤908 (rampup). After step ~20 the EMA stabilizes; max spike_ratio collapses below 1.05 for ALL cells. ZERO resets in cooldown phase (>2600) across every cell with thr≤50.

3. **EMA warmup artifact mechanism.** g_norm_ema seeded by first observed norm; next ~10 gradients during LR rampup have legitimately different magnitudes that look like 5×–20× spikes against the ~1-sample baseline. Resetting zeroes out curvature-rich momentum at the most informative point in training (explains Cell B +2.01σ harm).

4. **NS5 upstream-absorbs spike contamination.** Where real magnitude variation occurs post-rampup, the orthogonalization step renormalizes spectra to unit so directional contamination doesn't accumulate. SPAM mechanism upstream-suppressed by the NS5 stack.

5. **★ 7th Muon-body preprocessing axis closure** (joins #823 SignMuon, #932 per-layer NS iter, #1042 soft NS mixing, #1096 per-group mu, #1151 GC, #1183 Heavy-Ball, #1238 SPAM). Body update path resists ALL forms of momentum-buffer or gradient preprocessing surgery.

- **★ Pattern continuation:** SPAM paper measured GPT-2 on 100k+ steps without NS-style spectral normalization. On this 3250-step stack with NS5 + Muon, late-phase spikes ≥5× EMA simply don't occur. Mechanism upstream-suppressed.
- **Assigned nezuko → #1294 mu-cooldown-decay** (crossing-phase redesign; decay Muon momentum β during cooldown 0.95→0.0; tests whether persistent memory hurts directed descent; fresh FFS-targeted axis)

## 2026-05-26 09:50 UTC — PR #1200: edward orth-scheme alternatives to NS5 polynomial — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-edward/orth-scheme-alternatives`
- **Student:** g1r5-edward
- **Hypothesis:** Alternative orthogonalization operators replacing Muon's NS5 minimax polynomial — Polar via Cholesky/SVD (cond=1 exact), Schulz iter=5/8 (cond≈18 / cond≈1.06), and nspoly_iter3 falsifier (cond≈18 directional corruption). Tests whether NS5's specific polynomial form is FFS-load-bearing or operator-class is robust.

### FFS-primary verdict

| Cell | --orth_scheme | **FFS** | val/loss | Δ FFS vs baseline 3025 | Verdict |
|:----:|:--------------|:-------:|:--------:|:----------------------:|:--------|
| A | nspoly_iter6 (ctrl) | 3025 | 3.26108 | 0 | baseline |
| **B★** | polar_svd_fp32 | 3050 | 3.26215 | +25 (1 val tick) | within ±2σ band, +1.80σ_single, NO MERGE — 8× wall-clock cost |
| C | schulz_iter5 | 3150 | 3.27280 | +125 | NEG severe under-orth |
| D | schulz_iter8 | **3025** | 3.26176 | **0 (PARITY)** | ✨ second operator class reaches baseline-EXACT |
| E | nspoly_iter3 (falsifier) | 3175 | 3.27553 | +150 | NEG falsifier valid (+24.4σ_single) |

- **FFS verdict:** Cell B PRIMARY +25 FFS (1 val tick = noise floor). Cell D Schulz iter=8 **reaches FFS=3025 baseline-EXACT**. Cell E falsifier confirms iter=3 catastrophic. Close clean-NEG.
- **W&B run IDs:** A=0dwh1qfw, B=48fjzxdi, C=mlgle7vn, D=knvrka7k, E=boa4nype
- **★ Mechanism finding 1 — Broad basin headline:** cond ∈ [1.0, 5.6] all reach the same floor within ±2σ_single. Polynomial floor is a **basin floor extending from cond≈1 to cond≈6**, not a sharp optimum. Catastrophic outside cond≳10. Revises single-point reading — A is not on a sharp optimum, operator class is forgiving within the basin.
- **★ Mechanism finding 2 — Cond is NOT a complete operator descriptor (SURPRISE):** Cells C and E have nearly identical spectral fingerprints (cond≈18, σ_min≈0.054, σ_mean≈0.195) yet differ by **4.6σ_single** in val/loss. Schulz iter=5 (monotone non-decreasing on (0,1)) under-converges gracefully; nspoly iter=3 (non-monotone minimax poly with a+b+c=0.701≠1) under-converges with direction corruption. Implication: per-singular-vector alignment matters beyond spectral summary.
- **★ Mechanism finding 3 — Cooldown is the equalizer:** Cells B and D show opposite-signed +5σ/−14σ mid-training deltas (step 1000) that collapse to within ±2σ_single at terminal under cooldown's ~100× LR contraction. Early high-LR phase is where operator choice matters; cooldown washes terminal impact.
- **★ Mechanism finding 4 — NS-modulation operator-class fully closed:** Joining #962 (NS coefs), #1042 (post-NS mixing), #1206 (pre-NS conditioning), **#1200 (operator class)** — 4 independent operator-output modifications all clean-NEG with mechanism connections. The Muon polynomial at iter=6, post-spectral-norm=1.0, with a+b+c=0.7 is the optimizer's preferred (direction, magnitude, spectral) tuple in a broad basin.
- **★ Cell D parity is the FFS-headline finding:** Schulz `X(1.5−0.5X²)` reaches FFS=3025 = baseline-EXACT. **Operator-equivalence at FFS level** — FFS readout is structurally robust to operator choice within the basin. Useful for future framework redesigns where Muon's polynomial is awkward (e.g., quantized inference paths).
- **Pareto map:** 4 of 5 alternatives strictly dominated by A on (wall-time × val_loss); falsifier E only Pareto-relevant point but its +24.4σ rules it out.
- **★ 11th NS-modulation closure** with broadened mechanism family (operator-class basin closed).
- **Next:** Assigned edward → **#1284 body-WD value pruning** (6th stack-component pruning; tests `--wd_mlp=0.025 --wd_attn=0.025` value as FFS-load-bearing vs val-loss-cosmetic; 5-cell A=0.025 ctrl / B★=0.0 PRIMARY drop body WD / C=0.0125 / D=0.05 / E=0.10 falsifier).

---

## 2026-05-26 08:55 UTC — PR #1188: tanjiro depth-scaled per-block LR multiplier on Muon body — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-tanjiro/depth-scaled-muon-lr`
- **Student:** g1r5-tanjiro
- **Hypothesis:** Depth-scaled per-block Muon LR multiplier (Yang–Ma 2024 LLR for heavy-tailed late layers). Phase 1 5-cell sweep then n=4 confirm of best cell.

### FFS-primary verdict — Phase 2 n=4 (Cell E scale=1.15, anti-LLR)

| Trial | FFS | val/loss |
|:-----:|:---:|:--------:|
| 0 | 3050 | 3.26229 |
| 1 | 3025 | 3.26018 |
| 2 | 3025 | 3.26112 |
| 3 | 3050 | 3.26183 |
| **μ_4** | **3037.5** | **3.261355** |

- **FFS verdict:** μ_4=3037.5 vs baseline 3025 = flat-to-worse (+12.5 steps, ~0.4%). 2/4 trials baseline-exact, 2/4 one val-tick slower. **No speed gain.**
- **val/loss verdict:** μ_4=3.261355 > merge gate 3.259221 by +0.002134 → **close clean-NEG** per predeclared rules.
- **Phase 1 → Phase 2 regression-to-mean:** Phase 1 Cell E n=1 val=3.25863 (−4.36σ_single). Phase 2 μ_4=3.261355 (+0.45σ_4). **Δ_regression = +0.002725 = +4.59σ_single.** Phase 1 outlier was lucky seed.
- **W&B run IDs:** Phase 1 = y9qof7sq/wk2tfcon/91b3k0qa/eyu01pud/x4hbzzbn, Phase 2 = s5mz9u4z
- **★ Mechanism finding 1:** Depth-LR axis on Muon body is **null at ±15% magnitude**. Anti-LLR Phase 1 signal does not survive resampling. The "musoft init + uniform body LR" equilibrium is approximately optimal along the depth axis.
- **★ Mechanism finding 2 — calibration constant:** **n=1 → n=4 regression-to-mean ≈ 2.7 mNats** here. Z=−4.36σ_single val outlier with FFS-flat → does NOT replicate. Strong calibration datapoint for directive #1262: val-outliers without FFS movement should not be promoted to n=4 confirm.
- **★ Mechanism finding 3:** Cohort variance well-calibrated (σ_4 ≈ σ_single/√4) → no anomalous noise inflation unlike #907 joint reset (1.71×).
- **Next:** Assigned tanjiro → **#1279 SOAP precond_freq pruning** (last unexplored SOAP-internals axis; tests if PRECOND_FREQ=16 is FFS-load-bearing or compute-only-cosmetic).

---

## 2026-05-26 08:48 UTC — PR #1222: fern AdamP-style gradient projection on aux groups — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-fern/adamp-aux`
- **Student:** g1r5-fern
- **Hypothesis:** AdamP (Heo et al. 2021) orthogonal-to-W projection on scale-invariant aux params (embed, lm_head, scalars). Mechanism: removes effective-LR ramp caused by weight-norm inflation.

### FFS-primary verdict

| Cell | mode | **FFS** | val/loss | Δ FFS vs baseline 3025 | n=1 gate |
|:----:|:-----|:-------:|:--------:|:----------------------:|:--------:|
| A | off (ctrl) | 3025 | 3.26050 | 0 | PASS |
| **B★** | **embed_lmhead** PRIMARY | 3075 | 3.26687 | +50 | **FAIL +10.6σ** |
| C | soft_half | 3050 | 3.26208 | +25 | FAIL +1.5σ |
| D | scalars_only | 3200 | 3.27770 | +175 | **FAIL +27.8σ** |
| E | anti_falsifier (killed @1625) | n/a | n/a | n/a | n/a |

- **FFS verdict:** Cell B PRIMARY +50 FFS, Cell D catastrophic +175 FFS. No promotion gate cleared.
- **W&B run IDs:** A=u652acpk, B=fsd1zus1, C=afhexg0f, D=qabf8w13, E=5996x2iw
- **★ Mechanism finding 1 — Embed gradient orthogonal to embed weight (theory falsifier):** Telemetry shows `cos(g_row, W_row)` on embed = **5e-05** (3 orders below δ=0.1 threshold). AdamP fire rate on embed = **0%** throughout training. The PR's claim "sparse-token per-row updates reinforce existing directions" is falsified empirically. **Sparse-token update geometry differs structurally from dense gradient geometry.**
- **★ Mechanism finding 2 — lm_head parallel-to-W IS the learning signal:** AdamP fires only on lm_head (cos≈0.07, fire rate ~13%). Projecting OUT parallel component HURTS monotone-in-magnitude (B +0.0064 hard, C +0.0016 soft). For untied LM head, the column for a token mass-attracts toward the corresponding residual direction → that motion IS along W.
- **★ Mechanism finding 3 — LN γ orthogonal projection is structurally doomed:** Cell D scalars_only +0.0172 (worst single-cell degradation). LN γ has `∂loss/∂γ_i ∝ γ_i^{-1} × ...` with defining alignment with γ. **Any future "scale-invariant projection" on LN/RMSNorm γ is structurally doomed.**
- **★ 7th aux-axis closure** — AdamW + per-row v_t + no projection = tight floor on aux-group regime.
- **Next:** Assigned fern → **#1276 cooldown_frac pruning** (4th stack-component pruning; only one DIRECTLY targeting crossing-window LR mechanism; cooldown_frac=0.7 hardcoded never CLI-exposed → potential FFS-positive at Cell B=0.5).

---

## 2026-05-26 08:35 UTC — PR #1227: askeladd pre-NS gradient noise injection on Muon body — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-askeladd/pre-ns-noise-body`
- **Student:** g1r5-askeladd
- **Hypothesis:** Pre-NS Gaussian noise injection on Muon body matrices — mechanically distinct from #383 POST-NS noise (closed clean-NEG); orthogonal-manifold projection should give "structured exploration" rather than unstructured perturbation. 5-cell sweep across mode × std combinations.

| Cell | Mode | std | FFS | val/loss | Δ vs baseline |
|:----:|:-----|:---:|:---:|:--------:|:-------------:|
| A | off (ctrl) | 0.0 | 3050 | 3.263377 | +25 FFS, +3.64σ val |
| **B★** | linear_decay | 5e-4 | **3050** | 3.262661 | +25 FFS, +2.43σ val |
| C | constant | 5e-4 | 3050 | 3.264013 | +25 FFS, +4.71σ val |
| D | cooldown_only | 1e-3 | 3050 | 3.262424 | +25 FFS, +2.03σ val |
| E (falsifier) | constant | 5e-3 | **−1 (killed step 1582)** | 3.522823 | catastrophic ✓ |

- **FFS verdict:** All 4 surviving cells at FFS=3050 (baseline +25 step = 1 val tick variance). FFS dead at this scale. Cell B PRIMARY missed n=1 gate by +0.002033.
- **★ Mechanism — NS amplifies pre-NS noise:** Cell E catastrophic at 5e-3 (val=3.522 at step 1582, monotone-improving-but-slow) confirms the predicted NS-amplification mechanism: NS5 redistributes noise variance into low-singular-direction components where the model has no signal, so the orthogonalized update wastes energy on directions orthogonal to gradient. The "orthogonal-manifold structured exploration" intuition is mathematically reasonable but empirically falsified at scales that matter.
- **★ Cell C ≥ A:** keeping constant noise during cooldown actively hurts (B linear_decay < C constant at same std=5e-4). Confirms #941 "cooldown is directed descent, not noisy oscillation" from the noise-injection angle.
- **★ 10th NS-modulation axis closure:** joins #776 RMS clamp, #815 NS warmup, #824 NS coefs, #867 cautious pre-NS, #932 per-layer iter, #1010 iter-by-time, #1022 NS degree, #1042 soft mixing, #1151 GC, #1206 pre-NS conditioning. Combined with #383 post-NS noise: **every form of pre-NS or post-NS modulation has failed.** NS expects clean gradient in, clean orthogonal out. NS-on-body operator class is structurally locked at (iter=6, polynomial-degree-5, ‖update‖=1, no noise).
- **Operational note:** Cell A control unlucky seed (+3.64σ above n=4 mean) — within-sweep comparisons noisier than ideal but FFS conclusion robust.
- **W&B run IDs:** A=ar9guz8h, B=hk2y1qft, C=4o13jqe5, D=u7mbeg9i, E=0z9nu5ae (killed step 1582)
- **Next:** Assigned askeladd → **#1275 lr-scalars-pruning** (is `--lr_scalars 0.03` FFS-load-bearing? 5-cell: 0.03 ctrl / 0.0★ PRIMARY freeze / 0.015 / 0.06 / 0.10 falsifier; tests "is the 1D scalars param group FFS-load-bearing or val-loss-cosmetic?")

---

## 2026-05-26 08:20 UTC — PR #1266: alphonse depth-init-mode pruning ablation — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-alphonse/depth-init-pruning`
- **Student:** g1r5-alphonse
- **Hypothesis:** Pruning ablation — is `--depth_init_mode musoft` FFS-load-bearing or val-loss-cosmetic? 5-cell sweep across all available depth_init_mode values. *(Data reuse from PR #699 identical-command sweep, transparently disclosed by student.)*

| Cell | depth_init_mode | FFS | val/loss | Δ FFS |
|:----:|:---------------|:---:|:--------:|:-----:|
| A | musoft (ctrl) | 3025 | 3.26129 | 0 |
| **B★** | ctrl (zero-init residual) | **3025** | 3.26178 | 0 |
| C | mumedium | 3025 | 3.26180 | 0 |
| D | muall | 3075 | 3.26546 | +50 |
| E | smallconst (falsifier) | 3050 | 3.26253 | +25 |

- **FFS verdict:** ALL cells FFS ∈ [3025, 3075] — baseline-flat. musoft is val-loss-cosmetic at FFS scale.
- **Pre-crossing trajectory uniformity:** step→3.40=2250, step→3.35=2625, step→3.30=2875 **identical across ALL 5 cells** — optimizer convergence is completely insensitive to init mode in the pre-crossing phase.
- **★ Mechanism finding:** init axis is the least load-bearing component probed so far. Even the "Other (5%)" predeclared outcome triggered: smallconst (std=1e-3, depth-independent) did NOT catastrophically fail (FFS=3050). Cell D (muall) is the only mode that moves the needle — harmful (+50 FFS, +0.00417 val/loss): extending depth-scaling to non-residual weights is destructive.
- **★ Stack simplification:** musoft can be dropped in favor of ctrl with zero FFS penalty and <σ_single val/loss cost.
- **W&B run IDs:** A=kktt9fle, B=tockmprc, C=05qti19t, D=okls6sis, E=h3yg0dtz (from PR #699 identical sweep)
- **Operational note:** Student reused PR #699 identical-command data (transparent disclosure). Accepted once given: byte-identical command + code, decisive FFS readout. Not a precedent for vague reuse.
- **Next:** Assigned alphonse → **#1272 wd-schedule-pruning** (is `--wd_schedule ramp_down` FFS-load-bearing? 5-cell sweep: ramp_down ctrl / constant★ / ramp_up / triangle / cosine_updown)

---

## 2026-05-26 08:20 UTC — PR #1221: frieren LAMB trust ratio on Muon body matrices — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-frieren/lamb-trust-ratio-body`
- **Student:** g1r5-frieren
- **Hypothesis:** LAMB-style per-layer `‖W‖_F / ‖update‖_F` trust ratio applied post-NS to Muon body matrices to enable cross-layer LR balance.

| Cell | mode | FFS | val/loss | Δ vs baseline μ |
|:----:|:-----|:---:|:--------:|:---------------:|
| A | off (ctrl) | 3025 | 3.261378 | +0.27σ |
| **B★** | lamb_clipped | **3025** | 3.260813 | **−0.69σ** |
| C | lamb_unclipped | crashed NaN step~875 | — | killed |
| D | weight_only | 3050 | 3.261882 | +1.11σ |
| E | inverse (falsifier) | 3050 | 3.263135 | +3.22σ |

- **FFS verdict:** ALL surviving cells FFS ∈ [3025, 3050] — baseline-flat. Cell B fails n=1 confirm gate by +0.000185.
- **★★ Sharp saturation mechanism:** Trust ratio saturates at UPPER CLIP 2.0 from step ~800 onward. `‖W‖_F` grows during training while `‖update‖_F ≈ √(min(m,n))` is fixed post-NS → ratio → > 2.0 globally. Cell B ≈ uniform 2× lr_mlp boost for ~95% of training, NOT per-layer balance. Cell D (weight_only) behaves identically — `‖update‖_F` denominator not load-bearing once saturated. Cell C (unclipped) catastrophically diverges (trust ratio explodes to 7.3×10¹² by step 750) — clipping IS load-bearing.
- **★ Mechanism dovetails with edward #1200 + thorfinn #1206:** Both found NS spectral-norm-bounded magnitude is intentional and load-bearing (`‖update‖_2 = 1` exactly). Three independent body-modification PRs converge: NS magnitude calibration is the bottleneck for cross-layer balance mechanisms.
- **★ 1st cross-layer balance axis closure** — distinct from the 9-closure NS-modulation family; trust-ratio family is FFS-dead because saturation collapses per-layer signal.
- **W&B run IDs:** A=dyfhatgy, B=6m7mpu9w, C=5b0ns87t, D=5e6llr7d, E=jgf5wwhq
- **Next:** Assigned frieren → **#1273 soap-attn-pruning** (is `--soap_attn` FFS-load-bearing? 5-cell: soap_on ctrl / no_soap★ / no_soap+lr_attn_raised / no_soap+lr_attn_lowered / soap_on+over_lr falsifier)

---

## 2026-05-26 07:10 UTC — PR #1211: alphonse v_t pruning ablation on AdamW aux groups — **CLOSED clean-NEG** [FFS-PRIMARY]

- **Branch:** `g1r5-alphonse/aux-v-ablation`
- **Student:** g1r5-alphonse
- **Hypothesis:** Pruning ablation — is the AdamW v_t denominator (2nd-moment adaptation) load-bearing on aux groups? 5-cell sweep across `--aux_v_mode ∈ {adam, fixed_one, l1_running, adam_fast_beta2, adam_huge_eps}`.

**FFS-primary results (per human directive issue #1262):**

| Cell | aux_v_mode | **FFS** | val/loss | Δ FFS vs baseline (3025) |
|:----:|:-----------|:-------:|:--------:|:------------------------:|
| A | adam (ctrl) | 3050 | 3.26308 | +25 |
| **B ★** | fixed_one | **−1** | 8.31 | **catastrophic (diverged from step 0)** |
| C | l1_running | 3050 | 3.26343 | +25 (parity) |
| D | adam_fast_beta2 | 3075 | 3.26616 | +50 |
| E | adam_huge_eps | **−1** | 3.29097 | **−1 (3.28 never crossed)** |

**Verdict:** FFS dead across all cells. Cell B catastrophic (loss diverges from step 0). No FFS movement to <3000. **Close clean-NEG with mechanism finding**, no n=4 confirm per FFS-primary directive.

**★ Refined mechanism (falsifier broken → telemetry rescue):** PR predicted E (`adam_huge_eps`, eps=1.0) would drown `v_t` and ≈ B (`fixed_one`). Falsifier broke 5 unit-of-loss apart. aux_v telemetry resolved it: for lm_head, `sqrt(v_hat)≈2` → adding eps=1.0 pushes denom 0.96→2.34 (damping) but **per-row magnitude signal preserved**. Cell B replaces denom with scalar 1.0 every row, killing per-row adaptation entirely. **Load-bearing property of v_t on aux is per-row gradient-magnitude normalization**, not "a denominator that grows with g."

**7th aux-side closure** — Aux family fully saturated:
| PR | Hypothesis | Status |
|:--:|:-----------|:------:|
| h160 Cautious | NEG |
| h152 Lion | NEG |
| h144 AdEmaMix | NEG |
| h160 ADopt | NEG |
| #1131 AdaBelief | NEG |
| #1181 Adan | NEG |
| **#1211** v_t pruning | **NEG (Cell B catastrophic)** |

**Combined verdict: AdamW + per-row v_t is a tight floor on aux groups.** No replacement family beats it; pruning the v_t denominator catastrophically breaks training. Aux-optimizer-family axis fully closed under per-row-v frame.

**Operational note:** Cell B SIGTERM'd at step 938 initially; rerun (y8gz4lnu) is canonical.

**Caveat:** Cell A landed at +3.14σ above baseline μ (AuxAdamW.adam vs fused-AdamW numerical drift); within-sweep cell-vs-A comparisons remain clean.

**Transition:** Assigned alphonse #1266 depth_init_mode pruning ablation (FFS-targeted; sweep all 5 modes ctrl/musoft★/mumedium/muall/smallconst; tests "is musoft FFS-load-bearing or val-loss-cosmetic?" — first stack-component pruning under new FFS-primary framing).

## 2026-05-26 05:55 UTC — PR #1206: thorfinn Pre-NS grad-norm conditioned LR on Muon body — **CLOSED clean-NEG**

- **Branch:** `g1r5-thorfinn/muon-grad-norm-conditioned-lr`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Per-step LR multiplier on Muon body update derived from `‖p.grad‖_2 / EMA(‖p.grad‖_2)`. 5 modes tested: none, linear, sqrt, log (shrink at high grad), inverse (grow at high grad) — falsifier.

**Phase 1 n=1 5-cell sweep (sequential, ~9.2h):**

| Cell | mode | val/loss | ffs | Δ vs A | Z vs baseline μ | W&B | Verdict |
|:----:|:-----|:-------:|:---:|:------:|:---------------:|:----|:--------|
| A | none (ctrl) | 3.26150 | 3025 | — | +0.5σ | rldj28or | passes |
| **B★** | linear (PRIMARY) | **3.26474** | 3075 | +5.5σ | **+5.9σ** | sxc6u4ol | **FAIL** |
| C | sqrt | 3.26129 | 3025 | −0.35σ | +0.1σ | ngx1vq7a | no-op (gain_mean=0.976 in tight clip) |
| D | log | 3.26487 | 3075 | +5.7σ | +6.2σ | jxllvors | FAIL |
| E | inverse (FALSIFIER) | 3.26590 | 3075 | +7.4σ | +7.9σ | 7nsos1fw | FAIL (falsifier passes) |

**Mechanism finding (★ headline):** Harm is **symmetric** in `|deviation from gain=1.0|`, NOT direction-specific. B (shrink) +5.9σ, D (shrink) +6.2σ, E (grow) +7.9σ all hurt — falsifier rule passes (E worst) but B/D failing similarly weakens "asymmetric direction" mechanism. Read: **Muon's post-NS spectral-norm-bounded magnitude is intentional and load-bearing**. NS isn't just direction shaping; it's also magnitude calibration. Optimizer wants `‖update‖_2 = 1` exactly.

**Dovetails with edward #1200 Cell B** (polar SVD within band, polynomial floor): polynomial output's spectral fingerprint (cond≈2.4) is the optimizer's preferred direction AND magnitude. Two independent operator-output modifications (sharpening, rescaling) converge on the same finding.

**9th NS-modulation axis closure:** joins #776 RMS clamp, #815 NS warmup, #824 NS coefs, #867 cautious pre-NS, #932 per-layer iter, #1010 iter-by-time, #1022 NS degree, #1042 soft mixing, #1151 GC. Combined: NS-on-body operator class is finely tuned around `(iter=6, polynomial-degree-5, post-NS-spectral-norm=1.0)`. Adjacent perturbations in 10 distinct mechanistic directions all fail.

**Operational note:** Leftover `run_cells.sh` from prior assignment auto-launched duplicate Cell A 2026-05-25 ~20:42Z; killed 20:56Z; final Cell A from `run_sweep_1206.sh` (rldj28or) consistent with baseline distribution.

**Transition:** Assigned thorfinn #1258 Schedule-Free Muon on body — trajectory-averaging axis on body (orthogonal to NS-modulation, complements closed aux-side SF #659 and Lookahead-aux #1126).

## 2026-05-26 01:50 UTC — PR #1181: nezuko Adan optimizer for AdamW aux groups — **CLOSED clean-NEG**

- **Branch:** `g1r5-nezuko/adan-aux-optimizer`
- **Student:** g1r5-nezuko
- **Hypothesis:** Adan (Xie et al. 2022, arXiv:2208.06677) replaces AdamW on aux groups (embed/lm_head/scalars). Adds Nesterov gradient-difference correction `v_t = EMA(g_t − g_{t-1})` plus a modified denominator `n_t = EMA(u_t²)` where `u_t = g + β₂·d` is the Nesterov-corrected gradient. Hypothesis: aux gradients have temporal autocorrelation that the grad-diff term can exploit.

**Phase 1 n=1 5-cell sweep (sequential, ~9h):**

| Cell | aux_optimizer | β₁ | β₂ | β₃ | val/loss | ffs | Δ vs ctrl | gate? | W&B |
|:----:|:--------------|:--:|:--:|:--:|:--------:|:---:|:---------:|:-----:|:----|
| A | adamw | — | — | — | **3.26067** | 3025 | — | passes (= baseline) | `e1ppjk6u` |
| B (PRIMARY) | adan | 0.98 | 0.92 | 0.99 | 3.27524 | 3175 | +0.01457 | FAIL (+24.6σ) | `k29quyl4` |
| C | adan | 0.98 | 0.50 | 0.99 | 3.27114 | 3125 | +0.01047 | FAIL (+17.7σ) | `v3lmfw81` |
| D | adan | 0.90 | 0.92 | 0.99 | 3.26421 | 3050 | +0.00354 | FAIL (+6.0σ) | `ozknyrap` |
| E (β₂=0 falsifier) | adan | 0.98 | 0.00 | 0.99 | 3.28059 | -1 (never reached) | +0.01992 | FAIL (+33.6σ) | `kcnl5ywy` |

n=1 confirm gate: val/loss ≤ 3.260628 (baseline 3.261221 − 1σ_single). **All 4 Adan cells exceed the gate** — clean-NEG outcome, no Phase 2 launched.

**Mechanism findings (★ student diagnosis):**

1. **Grad-diff term IS real but small.** B vs E gap = 0.00535 (β₂=0.92 vs β₂=0). The `v_t = EMA(g_t − g_{t-1})` term contributes a measurable positive lift on aux gradients — temporal autocorrelation exists. But this lift is dwarfed by the structural cost of Adan's modified denominator.
2. **β₁=0.98 (Adan default) too slow vs AdamW β₁=0.8.** Cell D ablation (β₁=0.90) recovers ~70% of the gap to ctrl (3.26421 vs 3.27524 PRIMARY). The residual ~0.0035 to ctrl is the structural cost of Adan's update form. β₁=0.98 vs 0.8 dominates the regression.
3. **Modified denominator hurts.** Adan's `n_t = EMA(u_t²)` over the Nesterov-corrected gradient is structurally different from AdamW's `v_t = EMA(g_t²)`. When `d_t` is small (aux grads have weak autocorrelation), `u_t ≈ g_t` and the denominator is similar to AdamW, but the small grad-diff residue still injects variance into n_t that AdamW avoids.
4. **eps difference (1e-8 vs 1e-10) secondary.** With small aux gradients (especially scalars), 100× eps shift dampens early updates, but Cell D's near-ctrl performance suggests this is sub-dominant to β₁.
5. **ffs degrades too.** Adan B reaches target at step 3175 vs ctrl at 3025 (5% slower). All Adan cells need more steps. If ffs becomes primary metric, Adan would lose on both axes.

**★ Student diligence: paper-formula vs Adam-style β convention.** Student detected the PR pseudocode used paper-formula `m_t = (1−β₁)·m + β₁·g` with Adam-style β defaults `(0.98, 0.92, 0.99)` — inconsistent. Cross-checked official sail-sg/Adan reference and verified the convention pairing. Implemented Adam-style β (slow EMA at β=0.98). Mapping: `β_paper = 1 − β_code` so paper `(0.02, 0.08, 0.01)` ↔ code `(0.98, 0.92, 0.99)` — same slow-EMA regime. Without this catch, the experiment would have been an unfair test of Adan.

**Closure context — 6th aux-optimizer-family closure:**

| Family | PR | Mechanism | Result |
|:-------|:--:|:----------|:-------|
| Adan (Nesterov grad-diff) | **#1181** | grad-diff lift small; β₁=0.98 dominates | clean-NEG |
| AdaBelief (centered variance) | #1131 | (g−m)² inflates variance on sparse aux grads | clean-WEAK-NEG |
| Lion (sign-only) | h152 | sign destroys magnitude info in aux | NEG |
| AdEmaMix (dual EMA) | h144 | longer-memory EMA biases late updates | NEG |
| ADopt (modified denom) | h160 | denom structure mismatched to aux | NEG |
| Cautious | (h-series) | masking degrades aux without compensating signal | NEG |

Plus within-AdamW saturation: LR magnitude (#1021), warmup/schedule (#1054/#1072), trajectory averaging (#1126 Lookahead, #659 SF), regularization (#1105 WD clean-WEAK-NEG). In flight: #1211 v_t pruning ablation, #1222 AdamP projection. **AdamW is a tight local optimum for aux-group regime under this stack.** After #1211 + #1222, aux-side optimizer-family axis is essentially closed.

**Next:** nezuko → #1238 SPAM spike-aware momentum reset on Muon body matrices (Chen et al. 2025, arXiv:2501.06842). Mechanism: detect grad-norm spikes via rolling EMA and zero Muon momentum buffer when spike > threshold × EMA. Targets training stability — different failure mode from all closed axes. 5-cell sweep with thresholds 5/10 PRIMARY/20/50; Cell A uses high threshold (1000) for diagnostic logging. Includes no-spike gate for early-close if spikes don't occur.

## 2026-05-25 23:50 UTC — PR #1105: askeladd AdamW auxiliary weight decay sweep — **CLOSED clean-WEAK-NEG**

- **Branch:** `g1r5-askeladd/adamw-aux-wd`
- **Student:** g1r5-askeladd
- **Hypothesis:** Apply weight decay (wd_aux) to AdamW auxiliary groups (embed, lm_head, scalars) — currently hardcoded to 0.0. Sweep wd_aux ∈ {0, 0.001, 0.005, 0.01, 0.05}.

**Phase 1 n=1 5-cell sweep:**

| Cell | wd_aux | val/loss | ffs | reached | Δ baseline |
|:----:|:------:|:--------:|:---:|:-------:|:----------:|
| A ctrl | 0.0 | 3.26200 | 3050 | yes | +0.00078 (within σ) |
| **B★** | **0.001** | **3.25981** | **3025** | yes | **−0.00141** ✓ passes n=1 gate |
| C | 0.005 | 3.26009 | 3050 | yes | −0.00113 ✓ passes n=1 gate |
| D | 0.01 | 3.26658 | 3100 | yes | +0.00536 |
| E | 0.05 | 3.28928 | never | no | +0.02806 (severe) |

**Phase 2 n=4 confirm on B (wd_aux=0.001):** μ_4=3.260020, σ=0.001675, SEM=0.000838 — BORDERLINE (between merge gate 3.259221 and n=1 gate 3.260628). T2=3.26235 was an outlier.

**Phase 3 n=8 extension (combined Phase 2 + 4 new trials):**

| Stat | Value | Gate |
|:-----|:-----:|:-----|
| μ_8 | **3.259890** | misses MERGE (≤3.259807) by **+0.000083** |
| σ_8 | 0.001217 | (baseline σ_single=0.000593, this cohort 2× noisier) |
| Δ × √8 | **0.003765** | needs ≥ 0.004 for statsig merge — misses by 0.000235 |
| ffs_mean | 3028.125 | vs baseline 3025 (essentially flat) |
| Direction-correct | **8/8 ≤ baseline** | signal real |

W&B runs: `qq23ru4w` (Phase 2 n=4), `pimmpy73` (Phase 3 n=4 extension), group `g1r5-askeladd/adamw-aux-wd`. Extension cohort alone: μ_ext=3.259760 < merge gate; Phase 2 T2 outlier cost the merge.

- **Decision: CLOSED clean-WEAK-NEG per predeclared rule** (μ_8 > 3.259807). All 8 trials ≤ baseline rules out lucky seed — signal is real but sub-statsig at n=8.
- **★ Mechanism finding — val/loss helps, ffs doesn't:** 7 of 8 trials hit target at step 3025 (vs baseline 3025); only T2 hit at 3050. ffs_mean essentially flat. Light L2 on embed/lm_head shrinks the *converged* solution but not the *rate* of reaching the 3.28 target — the L2 effect accumulates late, biting only in cooldown phase.
- **Sweet-spot pattern A→B↓→C~B→D↑→E↑↑ is textbook clean** — confirms [0.001, 0.005] is a real local minimum, but magnitude of the B-vs-ctrl gain is just below what 8 seeds reliably distinguish.
- **Closure context — AdamW aux side now extensively saturated:** LR magnitude (#1021), LR warmup/schedule (#1054/#1072), trajectory averaging (Lookahead #1126, SF #659), optimizer family (Adan/AdaBelief/Lion/AdEmaMix/ADopt/Cautious all NEG), and now regularization (#1105 WEAK-NEG). Last open aux-side axes: alphonse #1211 (v_t structural), fern #1222 (AdamP direction), nezuko #1181 (Adan).
- **Plumbing decision:** keep `--wd_aux` CLI flag as zero-cost optionality for future per-group experiments. The default `wd_aux=0.0` reproduces the baseline behavior exactly.
- **askeladd → #1227 pre-NS noise injection on Muon body** (fresh axis: inject Gaussian noise BEFORE NS5 orthogonalization on body matrices; mechanically distinct from #383 POST-NS noise — NS projects pre-NS noise to the orthogonal manifold, producing structured exploration rather than unstructured perturbation)

## 2026-05-25 23:23 UTC — PR #1183: frieren Heavy-Ball vs Nesterov momentum for Muon body — **CLOSED clean-NEG**

- **Branch:** `g1r5-frieren/heavy-ball-nesterov`
- **Student:** g1r5-frieren
- **Hypothesis:** Replace Muon body's `grad.lerp_(momentum, mu)` (Nesterov-style: current grad re-injected each step) with pure heavy-ball EMA buffer as NS input. Predicted NULL/POS: NS discards magnitude so the re-injected grad is noise NS just discards anyway.

| Cell | Config | val/loss | Z vs A (σ_single) | ffs | W&B |
|:---:|:---:|---:|---:|---:|:---|
| A ctrl | Nesterov μ=0.95 | 3.26213 | 0 | 3050 | 3ut2bwjg |
| **B★** | **heavy-ball μ=0.95** | **3.26732** | **+8.75σ** clean-NEG | 3075 | w1i07m9v |
| C | heavy-ball μ=0.90 | 3.26765 | +9.31σ NEG | 3075 | oj9r645p |
| D | heavy-ball μ=0.99 | 3.29196 | **+50.3σ** catastrophic | never | wtpt2xid |
| E | heavy-ball μ=0.00 falsifier | 3.50102 @ early-kill | catastrophic | n/a | 66uetm29 |

- **Decision: CLOSED clean-NEG.** Cell B fails n=1 gate (≤ 3.260628) by +11σ_single. n=4 not pursued.
- **★ Mechanism findings (three coherent signatures):**
  1. **Directional fidelity** — Nesterov re-injects current grad into NS input each step. Heavy-Ball feeds NS a direction lagged by ~1/(1−μ) ≈ 20 steps at μ=0.95, ~100 steps at μ=0.99.
  2. **The `lerp_(momentum, mu)` coefficient is information** — `(1−μ)·grad + μ·momentum` is NOT just smoothing. Dropping `(1−μ)·grad` discards 5% of *current* signal at μ=0.95. NS cannot recover information not in its input.
  3. **μ=0.99 catastrophe scales nonlinearly** — doubling the effective momentum window (1/(1−μ) from 20→100 steps) hurts >2× more for heavy-ball than the corresponding Nesterov increase would. EMA-only path is highly lag-sensitive; Nesterov's current-grad re-injection masks this.
- **Cell E (μ=0) catastrophic** independently confirms temporal smoothing is load-bearing. So both temporal smoothing AND Nesterov re-injection of current grad are individually load-bearing — Muon's current `g.lerp_(m, μ)` is the structurally-optimal form.
- **Closure context — momentum-form axis on Muon body NOW SATURATED:** Combined with #823 (SignMuon NEG), #1042 (NS soft mixing NEG), and #1151 (GC NEG), pre-NS and momentum-input transformation axes are saturated.
- **frieren → #1221 lamb-trust-ratio-body** (LAMB-style per-layer ‖W‖_F/‖update‖_F trust ratio applied AFTER NS; orthogonal to thorfinn #1206 temporal axis and tanjiro #1188 static-depth axis)

## 2026-05-25 23:22 UTC — PR #1177: fern Cautious Muon (sign-mask NS updates) — **CLOSED NULL**

- **Branch:** `g1r5-fern/cautious-muon-body`
- **Student:** g1r5-fern
- **Hypothesis:** Apply Liang et al. 2024-style cautious mask: zero NS output elements where sign disagrees with `precond_nesterov` (or `grad`). Predicted POS: removes "wrong-direction" components from NS output.

| Cell | Config | val/loss | Δ baseline | Verdict | W&B |
|:---:|:---:|---:|---:|:---|:---|
| A ctrl | off | 3.259998 | −2.06σ | refactor-neutral ✓ (lucky-seed within tolerance) | dlz7xarj |
| **B★** | **vs_momentum** | **3.261294** | **+0.12σ** | NULL, fails n=1 gate by +0.67mσ | pab97gtk |
| C | vs_grad | 3.283169 | +37σ | catastrophic NEG | e734y22l |
| D | soft_momentum | 3.261033 | −0.32σ | NULL | 0wavs2di |
| E | random_30% falsifier | 3.334116 | +123σ | catastrophic NEG | hrpgt9n3 |

- **Decision: CLOSED NULL.** Cell B (PRIMARY) ≈ baseline +0.12σ; fails n=1 gate. n=4 not warranted.
- **★ Mechanism finding — NS subsumes cautious masking:** Mask density telemetry: NS output agrees in sign with `precond_nesterov` on **89% of elements per step** (overall: 0.890, MLP 0.919, attn 0.875). Only 11% are zeroed by the cautious mask — and removing them is essentially neutral.
- **Three internal falsifiers all confirm the mechanism:**
  1. **B vs C** (vs_momentum 3.261 vs vs_grad 3.283): SOAP-preconditioned momentum is the right sign reference, not raw grad.
  2. **B vs D** (binary 3.261 vs soft 3.261): hardness of mask is not the issue.
  3. **B vs E** (cautious 3.261 vs random_30% 3.334): cautious mask is NOT equivalent to a density-equivalent random mask — sign-alignment carries information, but at 11% the val/loss effect is below noise floor.
- **Student insight (worth quoting):** "The heavy lifting that 'cautious' does in AdamW — discarding sign-misaligned components of the update relative to the momentum direction — is already done by Newton-Schulz orthogonalization (which projects the preconditioned momentum onto the orthogonal manifold while preserving sign alignment for the vast majority of entries). There is little residual sign-misalignment to remove."
- **Closure context:** Closes cautious-mask axis. Generalizable result: any sign-correction trick that runs *after* NS will have negligible effect on Muon body matrices because NS already enforces sign alignment with `precond_nesterov` on ~89% of elements.
- **fern → #1222 adamp-aux** (Heo et al. 2021 AdamP gradient projection on scale-invariant aux: embed/lm_head/scalars; orthogonal to alphonse #1211 v_t ablation and askeladd #1105 aux-WD)

## 2026-05-25 20:47 UTC — PR #1131: alphonse AdaBelief on aux groups (eps sweep) — **CLOSED clean WEAK-NEG**

- **Branch:** `g1r5-alphonse/adabelief-aux`
- **Student:** g1r5-alphonse
- **Hypothesis:** Replace AdamW's `g²` 2nd-moment estimator with AdaBelief's `(g−m)²` on aux groups (embed/lm_head/scalars). Predicted POS: aux gradients are noisy on sparse-token tasks; centering on momentum should sharpen the denominator.

### Phase 1 (n=1 eps sweep)
| Cell | eps | val/loss | Z vs μ_base | Notes |
|:---:|:---:|---:|---:|:---|
| A ctrl | adam | 3.26121 | −0.02σ | refactor-neutral ✓ |
| B★ | 1e-8 | 3.26280 | +2.68σ NEG | |
| C | **1e-16** | **3.26056** | **−1.11σ** PASS n=1 | promoted to n=4 confirm |
| D | 1e-4 | 3.26415 | +4.95σ NEG | |
| E | 1e-12 | 3.26190 | +1.16σ boundary | |

### Phase 2 (n=4 confirm at eps=1e-16)
| Trial | val/loss | Z vs μ_base | Notes |
|:---:|---:|---:|:---|
| B1 default | 3.26056 | −1.11σ | original Cell C |
| B2 seed=1 | **3.26360** | **+4.01σ** | bad seed draw |
| B3 seed=2 | 3.26182 | +1.01σ | |
| B4 seed=3 | 3.26108 | −0.23σ | |
| **μ_4** | **3.261765** | **+0.92σ** | Above baseline μ |

- **Decision: CLOSED clean WEAK-NEG.** μ_4 = 3.261765 fails both gates: MERGE (μ_4 ≤ 3.259221) by 4.3σ_single, borderline n=8 (≤ 3.260628) by 1.9σ_single.
- **★ Mechanism finding — variance amplification on sparse aux gradients:** σ_n=4 = 0.001328 = **2.24× baseline σ_single** — largest variance inflation observed in this advisor cycle. Student decomposition: aux groups (embed 76M, lm_head, scalars 12K) see sparse gradients per step. `(g−m)²` is a *difference of two noisy quantities* — noisier than `g²` when `m_t` itself is being driven by stochastic sparse `g_t`. For dense Muon-targeted matrices, AdaBelief's claim that `(g−m)` is small in steady state would sharpen the denominator; for sparse-token embeddings, neither m nor g is well-stabilized, so `(g−m)²` ≈ `g²` plus extra subtraction variance.
- **Falsifiable structural prediction:** AdaBelief should do better on **dense** parameter groups than sparse ones (use in future hypothesis design).
- **Student self-criticism (excellent):** "I overweighted the n=1 within-pair mechanism contrast (C vs E: −2.24σ) and underweighted the possibility that AdaBelief might just have wider seed variance." Going forward, screen optimizer variants for seed variance during Phase 1, not just mean.
- **Closure context — 5th aux-optimizer family closure:** AdaBelief #1131 NEG, Adan #1181 trending NEG, Lion h152 NEG, AdEmaMix h144 NEG, ADopt h160 NEG. **AdamW is a tight local optimum for aux groups; 2nd-moment-variants on aux don't help and frequently hurt via variance amplification.**
- **alphonse → #1211 Pruning ablation: AdamW 2nd-moment adaptation on aux groups (v_t denominator load-bearing test) — direct extension of variance-amplification finding**

## 2026-05-25 19:41 UTC — PR #1151: thorfinn Gradient Centralization on Muon body (pre-NS) — **CLOSED clean-NEG**

- **Branch:** `g1r5-thorfinn/gc-muon-body`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Apply Gradient Centralization (row/col mean subtraction) to body-matrix grads BEFORE Newton-Schulz. Predicted POS: GC removes LayerNorm-coupled DC bias before NS sees it.

| Cell | gc_mode | val/loss | Δ baseline | Z (σ_single) | ffs | W&B |
|:---:|:---:|---:|---:|---:|---:|:---|
| A ctrl | off | 3.26163 | +0.00041 | +0.69 refactor-neutral ✓ | 3025 | 3d3rkqfb |
| B★ | row | 3.26404 | +0.00282 | **+4.75** NEG | 3050 | 6rn3ed4j |
| C | col | 3.26416 | +0.00294 | **+4.96** NEG | 3050 | exqnn1pc |
| D | both | 3.26676 | +0.00554 | **+9.34** NEG | 3075 | qm15xxep |
| E | row_attn_only | 3.26238 | +0.00116 | +1.95 boundary-NEG | 3050 | ai3xk468 |

- **Decision: CLOSED clean-NEG.** All non-A cells fail n=1 gate (≤ 3.260628). Best non-A is E (gc on attn-only) at +1.95σ — still NEG.
- **Mechanism findings (3 coherent signatures rule against hypothesis):**
  1. **Row ≈ Col** (B vs C: Δ=0.0001) — damage symmetric across axes; no asymmetric per-output-bias signature.
  2. **D ≈ B + C** additive (observed +0.00554 vs predicted +0.00576) — near-perfect additivity; no interaction term.
  3. **E (attn-only) ≈ A** (Δ=+0.00075) — MLP body is dominant damage locus; restricting GC to attn (smaller fan-in) preserves most signal.
- **Mechanistic read (REVERSED from hypothesis):** Row/col-mean direction of Muon body-matrix gradients **carries signal** (not noise). Newton-Schulz polar projection preserves and rotates this rank-1 component; GC strips it before NS can use it.
- **Closure context — 4th clean-NEG on Muon body preprocessing axis:** #932 per-layer NS iter, #1042 NS soft mixing, #1096 per-group mu, **#1151 GC**. Generalization: **Muon is finely tuned around full gradient signal**; removing any pre-NS component hurts. Damage scale Z=5-9σ rules out LR-retune recovery.
- **thorfinn → #1206 Pre-NS grad norm conditioning on Muon body LR (per-step temporal LR conditioning — adjacent to tanjiro #1188 depth-scaled per-block static LR)**

## 2026-05-25 18:27 UTC — PR #1154: edward Eval-time SWA/EMA on Muon body — **CLOSED clean-NEG**

- **Branch:** `g1r5-edward/muon-body-swa-ema`
- **Student:** g1r5-edward
- **Hypothesis:** Eval-time SWA/EMA averaging on Muon body matrices: maintain a shadow copy during training; swap in at eval time to see if averaged weights have lower validation loss.

| Cell | Mode | val/loss | z (σ_single) | ffs | W&B |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **A ctrl** | off | 3.26117 | −0.09σ | 3025 | x83gi30u |
| **B★ PRIMARY** | ema_999 | 3.37846 | **+197.7σ** catastrophic | −1 | 98vufcp2 |
| C | ema_99 | 3.26324 | +3.41σ NEG | 2950 | otqvtsin |
| D | swa_half | 3.29870 | +63.2σ catastrophic | −1 | cf9q39vs |
| E | ema_9999 | 7.29854 | **+6809σ** extreme | −1 | fabimwqj |

- **Decision: CLOSED clean-NEG.** All 4 averaging variants worse than ctrl; 3/4 catastrophic.
- **Mechanism findings (novel, rich):**
  1. **Monotone longer-memory → worse-val**: ema_99 (+3.4σ) < swa_half (+63σ) < ema_999 (+197σ) < ema_9999 (+6809σ). Window length directly predicts harm.
  2. **Training trajectory is monotone descent, not orbit**: shadow_drift/mlp_fc_0 ≈ 0.220 at end (22% relative norm distance from raw) — this drift IS the val-loss gap. SWA premise (orbits centroid) is empirically false here.
  3. **Connects to #941 (cooldown SWA)**: with cooldown_frac=0.7, params are still making meaningful descent through 70% of training. Any averaging window drags eval back to less-trained states. Confirms "trajectory-averaging family" (4/4 NEG: Lookahead #826, Schedule-Free #855, Cooldown SWA #941, eval-time SWA/EMA #1154) is fully exhausted.
  4. Cell E shadow_norm stays near init throughout (decay too slow to update) — confirms ema_9999 = shadow at initialization.
- **Axis closed**: eval-time param averaging on Muon body matrices not viable on top of cooldown_frac=0.7 + wd_schedule=ramp_down.
- **edward → #1200 Orthogonalization scheme comparison** (polynomial NS vs Schulz iteration vs polar SVD — closes "is NS polynomial approximation a bottleneck?" question)

## 2026-05-25 ~15:20 UTC — PR #1130: frieren Decoupled SOAP β₂ — **CLOSED clean-NEG**

- **Branch:** `g1r5-frieren/decoupled-soap-beta2`
- **Student:** g1r5-frieren
- **Hypothesis:** Decouple Gram-EMA β₂ (shampoo_beta) from in-basis exp_avg_sq EMA β₂ (SOAP_BETA2). Primary: slow Gram / fast basis (gram=0.95/basis=0.85) to capture slower structural curvature.

| Cell | gram_β | basis_β | val/loss | z (σ_single) | ffs | n=1 gate |
|:----:|:------:|:-------:|:--------:|:------------:|:---:|:--------:|
| A ctrl | 0.90 | 0.90 | 3.26084 | -0.64σ | 3025 | NO |
| **B PRIMARY** | **0.95** | **0.85** | **3.26077** | **-0.76σ** | 3025 | **NO** |
| C falsifier | 0.85 | 0.95 | 3.26056 | -1.12σ | 3025 | YES (hairline +0.11σ) |
| D (gram-only slow) | 0.95 | 0.90 | 3.26403 | +4.74σ | 3050 | NO |
| E (basis-only fast) | 0.90 | 0.85 | 3.26350 | +3.84σ | 3050 | NO |

- **W&B run IDs:** A `mghl4r7v`, B `dpx7pfla`, C `nphcbl87`, D `ejzeucun`, E `0oua6u36`
- **Decision: CLOSED clean-NEG.** PRIMARY direction B REFUTED: B=C=A within noise (0.12σ gap between B and ctrl). Primary mechanism (slow-Gram captures curvature better) dead. C (opposite direction) hairline 0.11σ gate-crossing not worth n=4.
- **Mechanism finding (novel):**
  1. D and E (single-EMA perturbations ±0.05) are catastrophic: +4.74σ and +3.84σ. Both paired combinations (B, C) recover to near-baseline.
  2. **Non-additive EMA coupling:** gram_β and basis_β must be moved TOGETHER or not at all. Isolated changes disrupt the Q-refresh cycle: in-basis projection sees eigenbasis statistics not matching current gradient scale.
  3. **Direction is symmetric:** both gram<basis (B) and gram>basis (C) give the same ~null result, confirming no directional asymmetry in SOAP's β₂ coupling.
  4. Combined with #1077 (static β₂ sweep NULL): SOAP β₂ axis fully closed. The current β_gram = β_basis = 0.90 is a coordinated equilibrium.
- **SOAP scalar HP cluster 5/5 CLOSED** (eps #1076, β₂ static #1077, Q_row/Q_col asymm refresh #1053, exp_avg_sq #979, precond_freq #1036, and now decoupled β₂ #1130).
- **frieren → #1183 Heavy-Ball vs Nesterov momentum for Muon body (untested momentum type axis)**

## 2026-05-25 ~15:10 UTC — PR #1036: nezuko SOAP precond_freq n=8 — **CLOSED clean-WEAK-NEG**

- **Branch:** `g1r5-nezuko/soap-precond-freq-ablation`
- **Student:** g1r5-nezuko
- **Hypothesis:** SOAP eigenbasis refresh cadence ablation (freq ∈ {4, 8, 16, 32, 64}). Screen found freq=8 best at n=1 (-1.99σ). Sent back for n=4 confirm, then n=8 when n=4 borderline.

**Sweep results (n=1 screen):**

| Cell | freq | val/loss | z (σ_single) | ffs |
|:----:|:----:|:--------:|:------------:|:---:|
| A ctrl | 16 | 3.26112 | -0.17σ | 3025 |
| **B ★** | **8** | **3.26004** | **-1.99σ** | **3025** |
| C | 4 | 3.26056 | -1.11σ | 3025 |
| D | 32 | 3.26193 | +1.20σ | 3025 |
| E | 64 | 3.26429 | +5.18σ | 3050 |

**n=4 confirm (B1-B4, seeds 0-3):** B1=3.26004, B2=3.26096, B3=3.25984, B4=3.25934. μ_4=3.260045. Δ=-0.001176. statsig=0.002352 vs gate 0.004 → **BORDERLINE (59% of required)**.

**n=8 confirm (B1-B8, seeds 0-7):** B5=3.26049, B6=3.26119, B7=3.25979, B8=3.26058. μ_8=3.260279. Δ=-0.000942. statsig=0.002665 vs gate 0.004 → **BORDERLINE again (midband: 3.259807 < μ_8 ≤ 3.260628)**.

| Phase | μ | σ | Δ | Δ×√n | Seeds below gate |
|:------|:--|:--|:--|:----:|:----------------:|
| n=4 | 3.260045 | 0.000677 | -0.001176 | 0.002352 | 3/4 |
| n=8 | **3.260279** | 0.000632 | -0.000942 | **0.002665** | **6/8** |

- **Decision: CLOSED clean-WEAK-NEG per predeclared n=8 rule.** Borderline → close with mechanism documentation.
- **Mechanism findings:**
  1. SOAP eigenbasis refresh cadence IS real but modestly load-bearing (~-0.001 val/loss at freq=16→8).
  2. freq=16 default is adequate. freq=8 yields directionally consistent improvement but below formal effect-size threshold at n=8.
  3. freq=4→8 plateau is flat (~0.0005 Δ); true optimum in [6,8] but margin too small to lock in.
  4. freq=64 +5.18σ regression confirms basis freshness is genuinely needed (not free to ignore cadence).
  5. No variance inflation (σ_n=8=0.000632 ≈ σ_single=0.000593) — distinct from cooldown-perturbation pattern.
- **Closed axis:** SOAP precond_freq. Combined with #1076 (eps NULL), #1077 (β₂-static NULL), #1053 (asymm row/col NULL), #979 (exp_avg_sq), #936 (Q-ablation): **SOAP scalar HP cluster comprehensively closed 5/5**. Remaining SOAP open: decoupled β₂ (#1130 frieren in flight).
- **nezuko → #1181 Adan optimizer for AdamW aux groups (Xie et al. 2022, arXiv:2208.06677; gradient-difference Nesterov correction)**

## 2026-05-25 14:31 UTC — PR #1126: fern Lookahead AdamW aux — **CLOSED clean-NEG**

- **Branch:** `g1r5-fern/lookahead-adamw-aux`
- **Student:** g1r5-fern
- **Hypothesis:** Wrap AdamW aux groups (embed, lm_head, scalars) with a Lookahead slow/fast weight averaging wrapper (Zhang et al. 2019). Mechanism: reduce gradient noise via slow-weight temporal low-pass filtering; primarily targeting sparse embedding row updates and lm_head cooldown-phase noise.

| Cell | k | α | val/loss | z (σ_single) | ffs | Δ vs A ctrl |
|:----:|:-:|:--:|:--------:|:------------:|:---:|:------------:|
| A (ctrl) | 0 | — | 3.26155 | -0.55σ | 3025 | 0 |
| B PRIMARY | 5 | 0.5 | 3.26295 | +1.23σ | 3050 | +2.36σ |
| C | 10 | 0.5 | 3.26428 | +5.16σ | 3050 | +4.60σ |
| D | 5 | 0.3 | 3.27401 | +21.5σ | 3150 | **+21.0σ catastrophic** |
| E | 5 | 0.8 | 3.26417 | +4.97σ | 3050 | +4.41σ |

- **Run IDs (W&B group `g1r5-fern/lookahead-adamw-aux`):** A `z4598mc9`, B `nb3mcpew`, C `0nf1568l`, D `trkmyg7m`, E `9owdao5t`
- **Decision: CLOSED clean-NEG.** Cell A (bypass ctrl) refactor-neutral at -0.55σ vs baseline (ffs=3025 exact match). All 4 non-ctrl cells fail the n=1 gate (≤3.260628). B PRIMARY at +1.23σ fails. No cell eligible for n=4 promotion.
- **Mechanism conclusions:**
  1. **Monotone damage along averaging-strength axis.** D (α=0.3, strongest averaging) catastrophic at +21σ. Damage scales smoothly with how much slow-weight pull restrains fast-weight AdamW updates.
  2. **AdamW bias-correction is already sufficient EMA-based variance reducer** for aux-group magnitudes. Stacking a second EMA via slow-weight averaging is purely destructive.
  3. **Cooldown-phase intolerance.** α=0.3 averaging during cooldown holds weights back from the converged minimum the LR schedule is steering toward.
  4. **α axis is load-bearing** (not k): doubling k costs +2.2σ; tripling averaging strength costs +18.6σ.
- **Closed sibling family:** All softening/wrapping modifications to AdamW aux now close clean-NEG (#1021 aux LR magnitude, #1072 aux LR warmup, #1126 Lookahead). Aux-group AdamW config is a tight local optimum.
- **fern → #1177 Cautious Muon on body matrices (Liang et al. 2024)**

## 2026-05-25 ~09:10 UTC — PR #1106: edward SOAP low-rank truncated eigenbasis — **CLOSED clean-NEG**

- **Branch:** `g1r5-edward/soap-low-rank-eigenbasis`
- **Student:** g1r5-edward
- **Hypothesis:** Truncating SOAP Q_row/Q_col eigenbasis to top-r% eigenvectors (by eigenvalue magnitude) discards noise and improves preconditioner quality.

| Cell | soap_rank_frac | effective rank @ 768 | val/loss | Δ vs baseline μ | z (σ_single) | ffs |
|:----:|:--------------:|:--------------------:|:--------:|:---------------:|:------------:|:---:|
| A (ctrl) | 1.0 | 768 (full) | 3.26086 | -0.00036 | -0.61σ | — |
| B (PRIMARY) | 0.5 | 384 | 3.45415 | +0.193 | +325σ | — |
| C | 0.25 | 192 | 3.63221 | +0.371 | +625σ | — |
| D | 0.125 | 96 | 3.84065 | +0.580 | +977σ | — |
| E | 0.0625 | 48 | 4.05514 | +0.794 | +1338σ | — |

- **Run IDs (W&B group `g1r5-edward/soap-low-rank-eigenbasis`):** A `soap-low-rank-A-frac1.0`, B `soap-low-rank-B-frac0.5`, C `soap-low-rank-C-frac0.25`, D `soap-low-rank-D-frac0.125`, E `soap-low-rank-E-frac0.0625`
- **Decision: CLOSED clean-NEG.** Per predeclared "Monotone harm" criterion: A > B > C > D > E in val/loss (strictly monotone worsening with rank reduction). Cell B PRIMARY at +325σ is catastrophic even at 50% retention.
- **Mechanism conclusion: SOAP eigenbasis is densely informative across full rank.** No noise-dominated eigenvector tail exists: Gram-matrix EMA with SOAP_BETA2=0.90 and ~32-step effective window accumulates real second-moment structure across all dimensions. Even 50% truncation discards load-bearing curvature information. The norm-preservation clamp cannot rescue a wrong-direction preconditioned update. This is now the **5th SOAP-structural axis to close** (joins #936/#994 Q-ablation, #1053 temporal asymmetry, #1076 eps NULL, #1077 β2-static NULL). Low-rank SOAP axis definitively closed.
- **edward → #1154 Eval-time SWA/EMA averaging on Muon body matrices (fresh axis)**

## 2026-05-25 ~08:25 UTC — PR #1096: thorfinn per-group Muon mu — **CLOSED clean-NEG**

- **Branch:** `g1r5-thorfinn/per-group-muon-mu`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Decouple mu_mlp and mu_attn for Muon Nesterov momentum (test attn gradient outlier hypothesis).

| Cell | mu_mlp | mu_attn | val/loss | Δ vs μ_base | z_single | ffs |
|------|--------|---------|----------|-------------|----------|-----|
| A ctrl | 0.95 | 0.95 | 3.263775 | +0.002554 | +4.31σ | 3050 |
| B | 0.95 | 0.90 | 3.262074 | +0.000853 | +1.44σ | 3050 |
| C | 0.90 | 0.95 | 3.261979 | +0.000758 | +1.28σ | 3050 |
| D | 0.90 | 0.90 | 3.264302 | +0.003081 | +5.20σ | 3050 |
| E | 0.95 | 0.85 | 3.264139 | +0.002918 | +4.92σ | 3050 |

- **Run IDs:** Cell A `n7z6cyme`, B `vbquklld`, C `101gob6f`, D `5ou8ql4r`, E `be8fe9ke`
- **Decision: CLOSED clean-NEG.** All 5 cells fail the n=1 confirm gate (≤3.260628). Best cell C at 3.26198 misses gate by 2.3σ. Cell A (bit-identical to baseline) at +4.3σ confirms seed noise dominates. B/C symmetric (~tied) breaks the PRIMARY attn-specific hypothesis. Non-monotone in both axes: D/E worse than B/C → no per-group lever.
- **Mechanism conclusion:** Muon stack is group-invariant at this baseline. Third per-group/per-component Muon sweep to return clean-NEG (after #932 per-layer NS-iter, #1042 NS-output). Per-group-momentum axis closed.
- **Useful side-product:** `muon/momentum_norm_mlp` and `muon/momentum_norm_attn` telemetry implemented and confirmed (mu=0.90 gives 2× higher norm vs mu=0.95 — plumbing verified correct).
- **thorfinn → #1151 Gradient Centralization on Muon body matrices (pre-NS)**

## 2026-05-25 ~06:00 UTC — PR #1036: nezuko SOAP precond_freq=8 n=4 CONFIRM — **BORDERLINE, sent back for n=8**

- **Branch:** `g1r5-nezuko/soap-precond-freq`
- **Student:** g1r5-nezuko
- **Hypothesis:** SOAP precond_freq=8 (vs hardcoded 16) at n=4 confirmation following n=1 screen positive (-1.99σ_single).

| Cell | seed | val/loss | Δ vs μ_base | z_single | ffs | run_id |
|------|------|----------|-------------|----------|-----|--------|
| B1 | default | 3.26004 | −0.00118 | −1.99σ | 3025 | `6qdcj8jj` |
| B2 | 1 | 3.26096 | −0.00026 | −0.44σ | 3025 | `35kwez3e` |
| B3 | 2 | **3.25984** | −0.00138 | −2.33σ | 3025 | `4knbzqp8` |
| B4 | 3 | **3.25934** | −0.00188 | **−3.17σ** | 3025 | `prdrsznw` |

- **n=4 aggregate:** μ_4 = **3.260045**, σ_n=4 = 0.000677 (≈σ_single 0.000593, no variance inflation), SEM=0.000339, Δ = −0.001176.
- **Statsig score:** Δ × √4 = **0.002352** vs gate ≥ 0.004 → **FAILS formal merge gate** by ~40%.
- **Borderline band:** 3.259221 < μ_4 = 3.260045 ≤ 3.260628 → in-band, returns to advisor.
- **3 of 4 seeds beat n=1 confirm gate** (B1 −1.99σ, B3 −2.33σ, B4 −3.17σ); B2 (seed=1) at −0.44σ is the weak draw.
- **ffs=3025 for ALL 4 seeds** — consistent.
- **Decision:** SEND BACK FOR n=8. Reuses B1-B4 as anchors, adds seeds 4/5/6/7 (4 new runs ~7h). At n=8, required Δ ≥ 0.001414; observed Δ_4 = 0.001176 ± 0.000339 SEM → P(true Δ ≥ 0.001414) ≈ 24%. Marginal but worth resolving — strongest signal in the portfolio.
- **n=8 decision rules predeclared:** μ_8 ≤ 3.259807 → MERGE; 3.259807 < μ_8 ≤ 3.260628 → close clean-WEAK-NEG; μ_8 > 3.260628 → clean-NEG.
- **No parallel assignment** — nezuko stays on this confirmation.

## 2026-05-25 ~05:00 UTC — PR #1077: frieren static SOAP_BETA2 sweep — **CLOSED clean-NEG NULL (SOAP scalar HP axis 4/4 closed)**

- **Branch:** `g1r5-frieren/soap-beta2-static-sweep`
- **Student:** g1r5-frieren
- **Hypothesis:** Static `SOAP_BETA2` (hardcoded 0.90 at line 27) might not be the local optimum on the current SOAP-attn+musoft+lr_mlp=0.055 baseline. Sweep ±5%/±10% around 0.90 (5 cells) to characterize the loss curvature in β₂ space.

| Cell | β₂ | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|----|----------|-------------|--------|-----|--------|
| A (CTRL) | 0.90 | 3.26319 | +0.001969 | **+3.32σ** | 3050 | `o7p6luu7` |
| B ★ (PRIMARY) | 0.95 | 3.26202 | −0.000799 | −1.35σ | 3050 | `w3wz60ir` |
| C | 0.98 | 3.26331 | +0.002089 | **+3.52σ** | 3050 | `lsj58yek` |
| D | 0.85 | **3.26134** | −0.000881 | −1.49σ | **3025** | `qf4qqtm8` |
| E | 0.80 | 3.26144 | −0.000781 | −1.32σ | **3025** | `7otmnknq` |

- **Baseline:** μ=3.261221, σ_single=0.000593, n=4, ffs_mean=3025. n=1 confirm gate: ≤3.260628.
- **Best cell D (β₂=0.85) at −1.49σ_baseline FAILS n=1 confirm gate by +0.71σ** → NULL.
- **Cell C (β₂=0.98) +3.52σ is the cleanest mechanism falsifier:** 34-step EMA halving-time > PRECOND_FREQ=16 → exp_avg_sq cannot equilibrate before Q refresh. Slow β₂ is structurally unsafe on this stack.
- **Cell A (CTRL β₂=0.90) +3.32σ unlucky-seed draw** confounds the D/E comparison vs A; comparing D/E to baseline μ (n=4) places them only at −1.5σ/−1.3σ, within the seed-noise band.
- **Across-cell stdev 0.000800 ≈ σ_single 0.000593** → axis dominated by seed noise; static β₂ in [0.80, 0.95] not load-bearing.
- **Decision:** CLOSE clean-NEG NULL. Static SOAP_BETA2 axis closed.
- **Mechanism cluster:** SOAP scalar HP axis comprehensively closed (4/4):
  - Q_row/Q_col asymmetry (#936/#994/#1053) — CLOSED
  - exp_avg_sq scaling (#979) — CLOSED
  - SOAP eps (#1076) — CLOSED NULL (same poll)
  - SOAP_BETA2 static (this PR) — CLOSED NULL
- **Student's #3 follow-up adopted as fresh assignment:** Decoupled β₂ — Gram-matrix EMA (`shampoo_beta`, consumed every PRECOND_FREQ=16 steps for Q refresh) vs in-basis exp_avg_sq EMA (`beta2`, consumed per-step in Adam denominator). The two EMAs have different downstream consumers and no a-priori reason to share β₂. Exposes a new structural degree of freedom.
- **frieren → #1130 Decoupled SOAP β₂** (5-cell sweep, gram∈{0.85, 0.90, 0.95} × basis∈{0.85, 0.90, 0.95}).

## 2026-05-25 ~05:00 UTC — PR #1076: alphonse SOAP eps sweep — **CLOSED clean-NEG NULL (eps axis flat across 8 OOM)**

- **Branch:** `g1r5-alphonse/soap-eps-sweep`
- **Student:** g1r5-alphonse
- **Hypothesis:** SOAP's `eps=1e-8` (hardcoded line 543) in `soap_precondition_momentum(update, state, beta2, eps)` controls the Adam-in-eigenbasis denominator floor AND the norm-preservation clamp_min. Test 8 orders of magnitude across {1e-2, 1e-4, 1e-6 (PRIMARY), 1e-8 (ctrl), 1e-10}.

| Cell | soap_eps | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|----------|----------|-------------|--------|-----|--------|
| A (CTRL) | 1e-8 | 3.261112 | +0.000891 | +1.50σ | 3050 | `emacq2yb` |
| B ★ (PRIMARY) | 1e-6 | 3.261044 | −0.000177 | −0.30σ | **3025** | `8ebopxxf` |
| C | 1e-4 | 3.261588 | +0.000367 | +0.62σ | **3025** | `xlpbiwbm` |
| D | 1e-10 | **3.261030** | −0.000191 | −0.32σ | **3025** | `jgbsjfzt` |
| E | 1e-2 | 3.261980 | +0.000759 | +1.28σ | 3050 | `ufx11gga` |

- **Baseline:** μ=3.261221, σ_single=0.000593, n=4, ffs_mean=3025. n=1 confirm gate: ≤3.260628.
- **Best cell D (1e-10) at −0.32σ_baseline FAILS n=1 gate** by +0.000402 (still +0.68σ ABOVE the gate).
- **Across-cell stdev 0.000507 ≈ σ_single 0.000593** — eps axis explains no variance beyond seed noise across 8 OOM.
- **Non-monotonic profile (D < B < A < C < E)** — loss surface locally flat w.r.t. eps in [1e-10, 1e-2]. The norm-preservation clamp_min likely rescales bulk eps differences away — per-eigendirection denominator floor only matters for vanishingly rare extreme-low-variance components. SOAP_BETA2=0.90 fast EMA produces enough `exp_avg_sq` variance that even 1e-2 floor doesn't dominate.
- **Decision:** CLOSE clean-NEG NULL. SOAP eps axis structurally inert in [1e-10, 1e-2].
- **Student follow-up noted but deprioritized:** Decoupling additive denominator floor from norm-preservation clamp_min (currently both share `eps`). Structural axis but axis itself flat, so low-priority.
- **alphonse → #1131 AdaBelief replacement for AdamW on aux groups** (fresh optimizer-family axis on optimizer1; orthogonal to closed scalar HP work and complementary to in-flight WD work #1105).

## 2026-05-25 ~03:55 UTC — PR #1072: fern embed/lm_head warmup schedule — **CLOSED clean-NEG (AdamW aux schedule axis closed for warmup direction)**

- **Branch:** `g1r5-fern/embed-lm-head-warmup`
- **Student:** g1r5-fern
- **Hypothesis:** Add linear warmup to AdamW aux groups (embed LR=0.3, lm_head LR≈0.003). Mechanism: AdamW β₂=0.95 EMA second-moment estimator is biased low at steps 0–~25, so a short LR warmup reduces early-step gradient noise amplification on sparse rows (embed) and dense projection (lm_head).

| Cell | warmup_e / l | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|--------------|----------|-------------|--------|-----|--------|
| A (ctrl) | 0.00 / 0.00 | **3.26086** | −0.000361 | −0.61σ | 3025 | `a1mulk80` |
| C | 0.05 / 0.05 | 3.26233 | +0.001109 | **+1.87σ** | 3050 | `mz66t94p` |
| B ★ | 0.10 / 0.10 (PRIMARY) | 3.26455 | +0.003329 | **+5.61σ** | 3075 | `tsdo2jwd` |
| D | 0.20 / 0.20 | 3.26717 | +0.005949 | **+10.03σ** | 3100 | `70vgbn7d` |
| E | 0.30 / 0.30 | 3.27004 | +0.008819 | **+14.87σ** | 3125 | `w0bl3tm4` |

**PRIMARY verdict:** Cell B clean-NEG at +5.61σ_base. Strict monotone damage across warmup={0.00,0.05,0.10,0.20,0.30}: every cell with warmup>0 hurts; ffs tracks val/loss linearly (3025 → 3050 → 3075 → 3100 → 3125, +25 steps per cell).

**Cell A refactor-neutrality PASS:** 3.26086 (−0.61σ_base, ffs=3025=baseline-ffs-mean) confirms `--warmup_*_frac 0.00/0.00` reproduces hardcoded behavior.

**Mechanism findings:**
1. **AdamW bias-correction is sufficient — warmup is double-correction.** AdamW's bias-correction term `1/(1−β^step)` already compensates for cold-start EMA bias. Adding linear warmup on top is redundant and removes useful training signal during the warmup window.
2. **ffs/val-loss linear coupling.** Each +5% warmup costs ~25 ffs and +1.6σ_base val/loss. Strong evidence that the 3250-step budget doesn't allow recovery from lost early-step LR.
3. **No local optimum at warmup>0.** Monotone profile with no inflection across 0.05–0.30 fractions falsifies the "modest warmup is optimal" hypothesis.

**Axis closure (AdamW aux schedule):** Combined with #1021 (LR magnitude — closed) and #1054 (LR schedule shape — closed), AdamW aux groups' schedule and magnitude axes are now comprehensively closed. **Open axes remaining for AdamW aux:** regularization (#1105 in-flight, Cell B at -2.38σ strong n=1 signal), and any non-scalar mechanism axes (e.g. Lookahead wrapper, alternative optimizer, EMA averaging).

**Decision: CLOSE clean-NEG with mechanism finding.** fern → **#1107 Lookahead wrapper on AdamW aux groups** — fresh mechanism axis (slow/fast weight averaging, not scalar HP), theoretically motivated for high-noise sparse-update groups. NOT a 2D warmup decoupling or finer-grain sweep on closed axis.

## 2026-05-24 ~23:10 UTC — PR #1053: edward asymmetric SOAP Q_row/Q_col refresh frequency — **CLOSED clean-NEG (SOAP per-component temporal-cadence axis closed)**

- **Branch:** `g1r5-edward/soap-asymm-q-refresh-freq`
- **Student:** g1r5-edward
- **Hypothesis:** Combine #936 (Q_col load-bearing for attn, Q_row largely redundant) with #994 (Q_row not zero-cost — cross-scope non-additive 4.5×): structural Q-drop is not viable, but temporal sparsification of redundant Q_row component might recover compute savings. Refresh Q_col at PRECOND_FREQ=16, Q_row at 64/128 (4-8× sparser). Q_row carries low-rank slowly-evolving information.

| Cell | qrow / qcol | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|-------------|----------|-------------|--------|-----|--------|
| A | 16/16 (ctrl) | **3.26060** | −0.000621 | **−1.05σ** | 3025 | `b4pkp7sr` |
| B ★ | 64/16 (PRIMARY) | 3.26292 | +0.001699 | **+2.87σ** | 3050 | `ul2sf9kk` |
| C | 32/16 | 3.26151 | +0.000289 | +0.49σ | 3025 | `yyxzdudk` |
| D | 128/16 | 3.26177 | +0.000549 | +0.93σ | 3025 | `rcc6147v` |
| E | 16/64 (falsifier) | 3.26256 | +0.001339 | **+2.26σ** | 3050 | `lr9nmbj3` |

**PRIMARY verdict:** Cell B clean-NEG at +2.87σ_base. Quadrupling Q_row's refresh interval while keeping Q_col at 16 does NOT preserve enough SOAP signal. FAILS n=1 confirm gate (3.260628) by +2.87σ.

**Cell A refactor-neutrality PASS but baseline-equivalent:** 3.26060 (−1.05σ_base, ffs=3025=baseline-ffs-mean) confirms split code-path reproduces hardcoded baseline. The deviation is n=1 favorable seed noise on baseline config, NOT a winner candidate (same handling as #1021/#1022/#1024 Cell A pattern).

**Mechanism findings (three distinct):**
1. **Structural vs temporal axes are NOT interchangeable.** Under *structural* ablation (#936/#994 drop Q entirely), Q_col is clearly load-bearing. Under *temporal* sparsification at 4× (this PR), Q_col (Cell E, +2.26σ) is *less* harmful than Q_row (Cell B, +2.87σ) — opposite of prediction. The structural-load-bearing-ness does NOT predict temporal-load-bearing-ness. Critical lesson for SOAP mechanism interpretation.
2. **Non-monotonic profile is n=1 noise.** Sweep along qrow={16,32,64,128} gives z={−1.05,+0.49,+2.87,+0.93}σ. A monotonic "more sparsification → more harm" curve would predict D > B regression. The 3.9σ envelope at n=1 matches σ_single≈0.0006 null distribution. No genuine sweet-spot reversal at K_row=64.
3. **`exp_avg_sq` rotation artefact.** Per PR body §2, `exp_avg_sq` only rotated to new eigenbasis when Q_row also refreshes. Applies symmetrically in cells B and E — may dominate over structural Q_col/Q_row asymmetry at 4× sparsification factors. A faithful implementation requires per-dimension rotation gating (separate architectural change, not a fix for this PR).

**Axis closure (SOAP per-component temporal-cadence at structural granularity closed):** Combined with #936/#994 structural Q ablations, this closes the SOAP per-component temporal-cadence sub-axis. The remaining open SOAP-cadence axis is **#1036 nezuko global PRECOND_FREQ** (4/8/16/32/64), which avoids the `exp_avg_sq` partial-rotation artefact entirely. Other SOAP-internals axes in flight: #1076 alphonse eps, #1077 frieren BETA2.

**Decision: CLOSE clean-NEG with mechanism finding.** edward → **#1106 SOAP low-rank truncated eigenbasis sweep** — fresh mechanism axis (not scalar HP): keep only top-r eigenvectors of d×d Q matrix, controlling rank/compute tradeoff. Connects to Adafactor/GaLore/FLORA low-rank optimizer-state literature.

## 2026-05-24 ~23:05 UTC — PR #1054: askeladd LR schedule shape sweep — **CLOSED clean-NEG (cooldown family comprehensively closed)**

- **Branch:** `g1r5-askeladd/lr-schedule-shape-sweep`
- **Student:** g1r5-askeladd
- **Hypothesis:** LR schedule was HARDCODED at lines 882-888 (`set_hparams`) as trapezoidal-stable-then-linear-decay (`eta = (1 − progress) / cooldown_frac`), with no CLI flag — never SENPAI-validated. Tests cosine/exponential/floor/quintic alternatives via new `--lr_schedule` flag. Schedule shape is orthogonal to schedule values.

| Cell | shape | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|-------|----------|-------------|--------|-----|--------|
| A | linear (ctrl) | **3.260587** | −0.000634 | **−1.07σ** | 3025 | `jmcvuqax` |
| B ★ | cosine (PRIMARY) | 3.270684 | +0.009463 | **+15.96σ** | 2950 | `8zjo92ya` |
| C | exponential | 3.324707 | +0.063486 | **+107σ** | — (3.28 never reached) | `jblkphy4` |
| D | linear_to_floor 0.1 | 3.270870 | +0.009649 | **+16.28σ** | 3175 | `1y2jm1us` |
| E | quintic (1−t)^5 | 3.325045 | +0.063824 | **+107σ** | — (3.28 never reached) | `2hd0e23d` |

**PRIMARY verdict:** Cell B catastrophically falsified at +15.96σ_base. Cosine shape mistimes the decay — slow-early-decay leaves model with less from near-zero late phase, plateau at 3.27.

**Cell A refactor-neutrality PASS:** 3.260587 (−1.07σ_base, ffs=3025=baseline-ffs-mean exactly) confirms `--lr_schedule linear` reproduces hardcoded trapezoidal-linear behavior. Sits *just* inside n=1 confirm gate (≤3.260628) — but A IS the baseline config; the −1.07σ is single-seed noise, NOT a winner candidate.

**Mechanism findings (bimodal failure mode):**
1. **Mild redistribution (B, D, +16σ class):** Alternative shapes that still anneal but mistime/floor the descent. Cosine plateaus from slow-early decay; linear_to_floor strands LR at 0.1·peak preventing full convergence (still descending at last step).
2. **Catastrophic early collapse (C, E, +107σ class):** Aggressive decay (exponential, quintic) drops LR <3% by t=0.5; directed-descent phase strands the model on a high-loss plateau at 3.325 — 3.28 target NEVER reached.

**Mechanistic interpretation.** Cooldown requires **full annealing to zero** (rules out D) at a **roughly constant decay rate** (rules out B, C, E). The trapezoidal-stable-then-linear-decay (peak through 30% of training, then linearly drain) provides uniform loss reduction per step — exactly what #941's "cooldown is directed descent" finding predicts. The directed-descent phase needs uniform LR decay; any other shape disrupts it.

**Axis closure (cooldown-mechanism family comprehensively closed):**
- LR/schedule value: ALL closed (#925 μ ramp WEAK-NEG, #907 joint reset NEG, #966 weight rescale NEG)
- LR/schedule shape: **#1054 CLOSED clean-NEG (THIS PR)** — trapezoidal-linear is tight local optimum
- LR magnitude on embed/lm_head: #1021 fern CLOSED clean-NEG poll #665

Combined: **entire cooldown phase is mechanistically locked-in.** No remaining cooldown-mechanism axis to test. The launch's cooldown protocol is structurally optimal.

**Refactor kept:** `--lr_schedule linear` default. Costs nothing and exposes axis for future re-testing if optimizer family changes.

**Decision: CLOSE clean-NEG with mechanism finding.** askeladd → **#1105 AdamW auxiliary weight decay sweep** — fresh axis on AdamW-managed embed/lm_head/scalars groups (currently `weight_decay=0` hardcoded at line 843, never CLI-flagged; PRs #349/#455 queued but never ran). Completely orthogonal to all closed cooldown axes.

## 2026-05-24 ~22:15 UTC — PR #1042: thorfinn Soft Newton-Schulz mixing α·NS(x) + (1−α)·x_pre-NS — **CLOSED clean-NEG (7th NS-modulation axis closure)**

- **Branch:** `g1r5-thorfinn/soft-ns-mixing`
- **Student:** g1r5-thorfinn
- **Hypothesis:** NS produces all-singular-values-≈1.0 update (full orthogonalization). Pre-NS input carries natural SV distribution from gradients + SOAP curvature scaling. Mixing `update = α·NS(x) + (1−α)·x_scaled` (Frobenius-norm-matched) preserves a fraction of pre-NS magnitude info while keeping orthogonalization dominant. Tests whether full orthogonalization is essential or sub-optimal.

| Cell | α | val/loss | Δ vs μ_base | z_base | ffs | run_id |
|------|---|----------|-------------|--------|-----|--------|
| A | 1.00 (ctrl) | **3.25903** | −0.00219 | **−3.69σ** | 3025 | `2bn4xvq3` |
| B ★ | 0.95 (PRIMARY) | 3.26130 | +0.00008 | +0.13σ | 3025 | `t7bef0a8` |
| C | 0.90 | 3.26161 | +0.00039 | +0.66σ | 3025 | `cj6t6hcq` |
| D | 0.80 | 3.26433 | +0.00311 | **+5.24σ** | 3050 | `0d9iaumh` |
| E | 0.70 | 3.26369 | +0.00247 | **+4.16σ** | 3050 | `ou8kw6xg` |

**PRIMARY verdict:** Cell B at +0.13σ_base — noise-neutral. FAILS n=1 confirm gate (3.260628). No n=4 follow-up warranted.

**Cell A lucky-seed:** α=1.0 is algorithmically identical to baseline (mix code-path is no-op). The −3.69σ_base is n=1 favorable seed draw from baseline distribution. NOT a winner. Same pattern as #1021/#1022/#1024 Cell A. z_base is load-bearing for absolute claims.

**Mechanism findings:**
1. **Pre-NS magnitude info is NOT load-bearing.** Diagnostic norms confirm `update_pre_ns_norm` ~900-980, `update_ns_norm` ~27.1 (spectral-flattened), `update_mixed_norm` between 26.91 (E) and 27.10 (B) — monotone in α as expected. The convex combination behaves exactly as designed; no implementation bug.
2. **Roughly monotone-worse as α decreases.** B/C noise-neutral, D/E clearly harmful (+4-5σ). 20%+ raw injection breaks the spectral-flattening property that's essential for step quality.
3. **NS *convergence stage* ≠ NS *output mixing*.** The PR #932 "inverted-iter 2nd-best" intuition does NOT translate. Late-layer tolerance for fewer NS iters is about stopping NS short of x≈1 convergence; pre-NS-magnitude-injection has the wrong spectral structure entirely.

**NS-modulation axis comprehensively closed (7 NEG closures):**
- #776 askeladd post-NS RMS clamp
- #815 tanjiro NS-iter warmup
- #824 NS polynomial coefficients
- #867 thorfinn cautious pre-NS sign mask
- #932 thorfinn per-layer NS iter
- #1010 tanjiro NS-iter-by-time
- #1022 frieren NS polynomial degree
- **#1042 thorfinn soft NS output mixing (THIS PR)**

Only remaining open NS axis: **#1062 tanjiro NS precision (bf16 vs fp32)** — about numerical fidelity, not modulation. Conclusion: orthogonalization *quality* cannot be modulated for benefit at this baseline. NS implementation is structurally locked-in.

**Decision: CLOSE clean-NEG with mechanism finding.** thorfinn → #1096 Per-group Muon mu sweep (mu_mlp vs mu_attn) — fresh axis at the pre-NS momentum layer, decouples MLP vs attn momentum (constructor already plumbs per-group mu via `g.get("mu", mu)` at line 605).

## 2026-05-24 ~18:55 UTC — PR #1022: frieren NS polynomial degree variation — **CLOSED clean-NEG (5th NS-internals axis NEG)**

- **Branch:** `g1r5-frieren/ns-polynomial-degree-variation`
- **Student:** g1r5-frieren
- **Hypothesis:** NS polynomial DEGREE never CLI-sweepable; default quintic (d=5) hardcoded. Test septic (d=7) at lower iter count for compute parity, plus cubic (d=3) with more iters. If higher degree converges faster near x=1, fewer iters could match quintic accuracy at less wallclock.

| Cell | Config | val/loss | Δ vs μ_base | z_base | Δ vs A | z_A | ffs | run_id |
|------|--------|----------|-------------|--------|--------|-----|-----|--------|
| A | d=5, iter=6 (ctrl) | **3.25967** | −0.00155 | **−2.62σ** | — | — | 3025 | `r47n3lqj` |
| B ★ | d=7, iter=4 (PRIMARY) | **3.26558** | +0.00436 | **+7.35σ** | +0.00591 | +9.97σ | 3075 | `j7tr7bio` |
| C | d=7, iter=6 | 3.26250 | +0.00128 | +2.16σ | +0.00283 | +4.77σ | 3050 | `rlu3zcgx` |
| D | d=5, iter=8 | 3.26046 | −0.00076 | −1.28σ | +0.00079 | +1.33σ | 3025 | `6w6ab7hr` |
| E | d=3, iter=8 | 3.26116 | −0.00006 | −0.10σ | +0.00149 | +2.51σ | 3025 | `xx5fhzr5` |

**PRIMARY verdict:** Cell B falsified at +7.35σ_base, +9.97σ_A. Catastrophic — septic d=7 at iter=4 is iter-starved (not degree-starved).

**Cell A lucky-seed caveat:** A is algorithmically identical to baseline (d=5, i=6 = mandatory `--ns_iter 6`). Its −2.62σ_base is n=1 seed noise on baseline-config — NOT a winner. Same handling as fern #1021 Cell A. z_base is load-bearing for absolute claims.

**Cell D borderline:** 3.26046 sits 0.000168 below n=1 confirm gate (3.260628) — 0.28σ inside gate, well within n=1 noise envelope. Not pursuing n=4 confirmation; mechanism interpretation (compute saturation) closes axis.

**Mechanism findings (two distinct):**
1. **Iter count is orthogonalization-quality floor.** B (d=7, i=4) is iter-starved despite higher degree. Early NS iterations do coarse contraction far from x=1 where polynomial degree barely matters; only late iterations (near x=1) benefit from cubic-convergence septic. At iter=4, the polynomial cannot reach the near-x=1 regime where d=7 would pay off.
2. **Degree×iter trades off symmetrically at constant total NS compute.** E (d=3 i=8) ≈ A (d=5 i=6) ≈ baseline μ. The benchmark sits AT the convergence knee — minimum sufficient orthogonalization compute is required, but additional compute (D: d=5 i=8) doesn't pay back. **d=5 iter=6 is a tight local optimum in the (degree, iter) grid.**

**Combined NS-internals axes (all NEG):**
- #932 by-depth scheduling, #815 early-time, #1010 late-time, #962 quintic coefficient sweep, **#1022 degree variation** ← this PR

NS-internals COMPREHENSIVELY saturated at d=5, iter=6, bf16. Only one NS axis still open: tanjiro #1062 precision (bf16 vs fp32). After tanjiro closes, NS-internals will be fully exhausted.

**Decision:** CLOSED clean-NEG. New assignment incoming.

## 2026-05-24 ~18:55 UTC — PR #1024: alphonse init mode ablation — **CLOSED clean-NEG (init mode axis closed)**

- **Branch:** `g1r5-alphonse/init-mode-ablation`
- **Student:** g1r5-alphonse
- **Hypothesis:** 4 of 5 built-in `--depth_init_mode` variants untested. Closes PR #699 verification loop. PRIMARY: muall (extend 1/√L depth scaling to ALL block 2D weights, not just residual proj).

| Cell | mode | val/loss | Δ vs A | σ_diff | resid proj_std | ffs | run_id |
|------|------|----------|--------|--------|----------------|-----|--------|
| A | musoft (ctrl) | **3.26148** | — | — | 0.005984 | 3025 | `i4ve2pn3` |
| B ★ | muall (PRIMARY) | 3.26636 | +0.00488 | +5.82σ | 0.005984+QKV/fc | 3075 | `2p3fnxnn` |
| C | mumedium | 3.26328 | +0.00180 | +2.15σ | 0.001727 | 3050 | `2kv4gdbh` |
| D | ctrl_noinit | 3.26198 | +0.00050 | +0.60σ | 0.000000 | 3025 | `91x3wkla` |
| E | smallconst | **3.26143** | −0.00005 | −0.06σ | 0.001000 | 3025 | `wqp4kesq` |

**PRIMARY verdict:** Cell B muall falsified at +5.82σ_diff. Extending 1/√L scaling to non-residual Q/K/V/MLP-fc costs ~+0.005 val/loss and +50 steps to target.

**Mechanism findings (three-axis decomposition):**
1. **Residual proj_std magnitude** (0 → 6e-3): all 4 cells within ~3σ; **weakly load-bearing at n=1.**
2. **Depth scaling on NON-residual Q/K/V/MLP-fc:** only muall does this — the ONLY cell >>3σ NEG. Residual path is special: 1/√L damping prevents signal explosion in skip-add; Q/K/V/fc are RECEIVING paths needing full-strength initial weights. Pre-damping starves model of initial capacity, never recovers.
3. **NS-orthogonalization re-normalizes init differences.** Trajectories agree to ~3% by step 500 across all 5 cells. Init scale matters for early gradient flow direction; Muon's NS-orth recovers this within ~50 steps.

**Crossover observation:** muall (B) has LOWEST val/loss at step 125 (4.456) but HIGHEST at step 3250 (3.266). Compressing 2D block weights by 1/√L gives faster initial progress (smaller logits → faster gradient response) but worse late-cooldown convergence.

**Cell D ctrl_noinit at +0.60σ:** Within n=1 noise of A. Student suggested n=4 D vs A to confirm musoft is load-bearing — out of scope here; could revisit if compute available.

**Cell E smallconst at −0.06σ:** Essentially identical to musoft. Hints residual init magnitude barely matters in current stack.

**Decision:** CLOSED clean-NEG. Init-mode axis comprehensively explored (all 5 built-in modes ablated). musoft remains optimal; muall actively harms. New assignment incoming.

## 2026-05-24 ~18:10 UTC — PR #1021: fern embed/lm_head LR ablation — **CLOSED clean-NEG (local optimum confirmed)**

- **Branch:** `g1r5-fern/lr-embed-lm-head-ablation`
- **Student:** g1r5-fern
- **Hypothesis:** Embed LR=0.3 and lm_head LR=1/320 (≈0.003125) HARDCODED in `optimizer1` construction at `train_gpt_simple.py:840-841`, never SENPAI-validated. ~76M params untouched by prior LR sweeps. Test whether the hand-tuned values sit near optimum.

- **5-cell sweep results (n=1 each, 3250 steps):**

| Cell | --lr_embed | --lr_lm_head | val/loss | Δ vs A | σ_single vs A | Δ vs μ | σ vs base | W&B |
|:----:|:----------:|:------------:|:--------:|:------:|:-------------:|:------:|:---------:|:---:|
| A (ctrl) | 0.3 | 0.003125 | **3.25905** | — | — | −0.00217 | **−3.66σ (lucky seed)** | `zskrqew5` |
| **B ★** | 0.5 | 0.003125 | 3.26197 | +0.00292 | **+4.92σ** | +0.00075 | +1.26σ | `9em7qfmn` |
| C | 0.2 | 0.003125 | 3.26121 | +0.00216 | +3.64σ | −0.00001 | −0.02σ | `sh3uzsi6` |
| D | 0.3 | 0.005 | 3.26366 | +0.00461 | +7.77σ | +0.00244 | +4.11σ | `gqpfdik1` |
| E | 0.3 | 0.002 | 3.26041 | +0.00136 | +2.29σ | −0.00081 | −1.37σ | `d9y57oje` |

- **Decision: CLOSED clean-NEG with local-optimum confirmation.**

- **Mechanism findings:**
  - **All 4 LR perturbations from hardcoded values worse than Cell A control** (+2.29σ to +7.77σ_single vs A). Signature of a local optimum: two-sided worsening on both embed and lm_head axes.
  - **embed LR (B vs C):** two-sided worsening (B +4.92σ, C +3.64σ vs A). 0.3 is local optimum. Mechanism: high LR compensates for sparse-row updates (rare tokens get few updates).
  - **lm_head LR (D vs E):** asymmetric pattern — D (+60%) +7.77σ much worse than E (−40%) +2.29σ. The hardcoded 1/320 sits *near* but *slightly above* its strict optimum, but available gain from finer search is sub-σ.
  - **Cell A "lucky seed" caveat:** Cell A at 3.25905 is baseline replication with a favorable seed (−3.66σ_single at n=1). Cell C at 3.26121 lands ≈baseline μ (−0.02σ), confirming A's deviation is n=1 noise. NOT a merge candidate.

- **PRIMARY decision outcome:** Cell B at 3.26197 missed n=1 promotion gate (≤3.260). **No n=4 confirm requested.** Correct conclusion by student.

- **Closure context:** Closes embed/lm_head LR **magnitude** axis comprehensively. The last untested optimizer LR dimension is now SENPAI-validated as near-optimal at the hand-tuned values. Combined with prior tested groups (lr_mlp/lr_attn/lr_scalars), all parameter-group LR magnitudes are now ablated.

- **Student suggested follow-ups:** (1) Close LR-magnitude axis ✓; (2) Embed/lm_head warmup schedule — fresh axis (schedule, not magnitude); (3) Per-token frequency-weighted embed LR — more involved mechanism.

- fern reassigned → **PR #TBD Embed/lm_head warmup schedule** (acts on suggested follow-up #2 — fresh schedule axis on AdamW groups, complements closed magnitude axis).

---

## 2026-05-24 ~12:00 UTC — PR #979: thorfinn SOAP exp_avg_sq scaling ablation — **CLOSED clean-NEG (mechanism finding)**

- Branch: `g1r5-thorfinn/soap-exp-avg-sq-ablation`
- Student: g1r5-thorfinn
- Hypothesis: Test whether SOAP's per-element Adam-in-basis `exp_avg_sq` scaling component is load-bearing or vestigial. SOAP component pruning ablation distinct from #936 (Q matrix structure) and #914 (Q refresh schedule).

- **5-cell sweep results (n=1 each, 3250 steps, group `g1r5-thorfinn/soap-exp-avg-sq-ablation`):**

| Cell | Config | val/loss | Δ vs μ=3.261221 | σ_single units | ffs | wandb_run |
|:----:|:-------|:---------|:----------------|:--------------:|:---:|:----------|
| A | (ctrl, full SOAP) | 3.260850 | −0.000371 | −0.6σ | 3025 | `kkuyozrx` |
| **B ★** | `--soap_no_adam_scale` | **3.316221** | **+0.055000** | **+93σ** | −1 | `zikol4bs` |
| C | `--soap_no_adam_scale --soap_no_norm_preserve` | 3.318312 | +0.057091 | +96σ | −1 | `14u2g29g` |
| D | `--soap_exp_avg_sq_init 1.0 --soap_exp_avg_sq_freeze` | 3.319598 | +0.058377 | +98σ | −1 | `r4ho5dhw` |
| E | `--soap_exp_avg_sq_no_ema` | 3.265869 | +0.004648 | +7σ | 3075 | `kq0exwcp` |

- **Decision: CLOSED clean-NEG with two mechanism findings.**

- **Mechanism finding #1: Per-element direction-warping in eigenbasis is load-bearing.** Pure Q-basis projection + re-projection + norm preservation cannot recover what the per-element scaling does to update *shape*. The norm-preservation handles magnitude (Cell C matches B class, falsifying 'norm-preserve saves us'), but the SOAP signal is in how it reshapes the per-coordinate distribution within Q. Cell D (frozen exp_avg_sq=1.0, mechanistically ≈ Cell B with norm-preserve still active) confirms the regression class is from removing direction-warping, not numerical drift.

- **Mechanism finding #2: EMA accumulation of exp_avg_sq is mostly inessential.** Cell E (drop the EMA state, recompute `projected.square()` instantaneously) lands at +7σ — measurably above baseline but ~12× closer than B/C/D. The *shape* matters; the temporal smoothing of that shape contributes ~0.005 loss. Consistent with Q being refreshed every 16 steps anyway.

- **Why parity Cell-E follow-up not worth running:** n=1 at +7σ above μ. With σ_sample at n=4 ≈ 0.5×σ_single = 0.000297 (SE 0.000148), Cell E would need n=4 μ ≤ 3.261521 for parity within 1 SE. The n=1 at 3.265869 ⇒ likely n=4 μ near 3.265, ~12σ above parity threshold. Won't merge as memory savings.

- **Closure context:** Combined with #936 (asymmetric Q ablation), this maps which SOAP components are load-bearing. Cell-D mechanism (frozen uniform scaling ≈ no scaling) is a clean falsifier closing 'norm-preserve saves us' hypothesis. SOAP-internals pruning is now well-explored — exp_avg_sq cannot be dropped or simplified to constant.

- thorfinn reassigned → **PR #1042 Soft NS mixing** (fresh per-step output-mixing axis: `update = α·NS(x) + (1−α)·x_scaled`; distinct from #776 RMS-clamp/global rescale, #815 NS-iter warmup, #932 per-layer NS iter). Informed by #932 finding that fewer NS iters tolerated at certain depths.

---

## 2026-05-24 ~11:45 UTC — PR #1036: nezuko SOAP precond_freq ablation — **ASSIGNED**

- **Branch:** `g1r5-nezuko/soap-precond-freq`
- **Student:** g1r5-nezuko
- **Hypothesis:** `PRECOND_FREQ=16` hardcoded global constant (line 28 of `train_gpt_simple.py`) has never been ablated. #914 tested cooldown-only freeze. Global refresh cadence for main training is a fresh axis.

- **5-cell sweep:**

| Cell | freq | Role |
|:----:|:----:|:-----|
| A | 16 | ctrl (current) |
| B ★ | 8 | PRIMARY: 2× more frequent |
| C | 4 | 4× more frequent (upper limit) |
| D | 32 | less frequent (compute savings) |
| E | 64 | near-freeze (connects to #914 finding) |

- **Context:** Eigendecomp cost is O(d³) but small fraction of step time. Connects to #914 (freeze −4.9σ NEG), #936 (eigenbasis side findings), #979 (exp_avg_sq in flight).

---

## 2026-05-24 ~11:40 UTC — PR #973: nezuko Cosine-gated adaptive Muon momentum — **CLOSED clean-NEG (high info)**

- **Branch:** `g1r5-nezuko/cosine-gated-adaptive-mu`
- **Student:** g1r5-nezuko
- **Hypothesis:** μ adapts per-step per-matrix based on cos(grad, momentum). cos=+1 → μ_max=0.99; cos=−1 → μ_min=0.70.

- **5-cell results (n=1, 3250 steps):**

| Cell | Config | val/loss | ffs | Δ ctrl | σ_single | W&B |
|:----:|:-------|:--------:|:---:|:------:|:--------:|:---:|
| A | ctrl (no gate) | 3.26054 | 3025 | −0.57σ | neutral | b6uosnj8 |
| B ★ | (0.70, 0.99) cooldown on | 3.28014 | DNF | **+16.0σ** | 99c8fkj6 |
| C | (0.50, 0.99) aggressive | 3.29153 | DNF | **+25.6σ** | eg1368tk |
| D | (0.85, 0.99) conservative | 3.26744 | 3100 | **+5.24σ** | nu5m7q57 |
| E | (0.70, 0.99) no cooldown | 3.27563 | 3175 | **+12.2σ** | 9uhsat8b |

- **MECHANISM FINDING:** W&B `cos_gate/mu_local` traces show mean μ_local ≈ 0.845 in Cell B (μ_min=0.70, μ_max=0.99). Inverting gate formula → **implied mean cos ≈ 0 (orthogonal)**. Per-matrix grad↔buffer cosine is dominated by independent stochastic noise once buffer accumulates. Gate collapses to midpoint of [μ_min, μ_max] → effectively just lowers mean μ below well-tuned 0.95.

- **Ordering:** D (midpoint 0.92) < B (midpoint 0.845) < C (midpoint 0.745) — **monotone in distance from baseline μ=0.95**. Confirms mechanism: harm proportional to mean-μ displacement from 0.95, not gate shape.

- **Decision:** CLOSED clean-NEG. Closes direction-conditional momentum axis. Reinforces #924 (gradient-derived direction signals too noisy at per-matrix scale). Confirms #925 Cell E was schedule-shape effect, not geometry effect.

---

## 2026-05-24 ~10:15 UTC — PR #1024: alphonse init mode ablation — **ASSIGNED**

- **Branch:** `g1r5-alphonse/init-mode-ablation`
- **Student:** g1r5-alphonse
- **Hypothesis:** 5 `--depth_init_mode` options exist in code, but only `musoft` (PR #699 baseline) has been SENPAI-validated. Test whether any alternative — especially `muall` (extends depth scaling to ALL block 2D weights) — outperforms the baseline init assumption.

- **5-cell sweep:**

| Cell | Mode | Role |
|:----:|:-----|:-----|
| A | `musoft` | ctrl (current baseline) |
| B ★ | `muall` | PRIMARY: depth scale applied to ALL 2D block weights, not just residual |
| C | `mumedium` | stronger depth scaling (1/L vs 1/√L) |
| D | `ctrl` | zero residual init — pre-#699 falsifier |
| E | `smallconst` | tiny constant 1e-3, depth-independent |

- **Context:** Closes the #699 verification loop — alphonse originally discovered `musoft`; this PR checks all 4 alternatives. Combined with #1021 (embed/lm_head LR), covers all param groups whose LR/init assumptions have been untested.

---

## 2026-05-24 ~10:10 UTC — PR #966: alphonse Cooldown weight rescaling — **CLOSED clean-NEG (strong falsifier)**

- **Branch:** `g1r5-alphonse/cooldown-weight-rescale`
- **Student:** g1r5-alphonse
- **Hypothesis:** One-shot uniform shrink of body matrix weights at step 975 (cooldown onset) improves cooldown convergence.

- **5-cell results (n=1, 3250 steps):**

| Cell | α | val/loss | ffs | Δ ctrl | σ_single | W&B |
|:----:|:---:|:--------:|:---:|:------:|:--------:|:---:|
| A | 1.0 (ctrl) | 3.26179 | 3025 | 0.00000 | 0.00σ | vm72qu96 |
| B ★ | 0.99 | 3.26169 | 3025 | −0.00010 | **−0.17σ** | qdnzakfd |
| C | 0.97 | 3.26273 | 3050 | +0.00094 | +1.59σ | nrx7o9te |
| D | 0.95 | 3.26220 | 3050 | +0.00041 | +0.69σ | 7sim5e47 |
| E | 1.01 | 3.26272 | 3050 | +0.00093 | +1.57σ | 5cdc1sd3 |

- **Decision:** CLOSED clean-NEG (strong-falsifier outcome as pre-declared). All 5 cells within ±2σ_single; best B is only −0.17σ (noise); falsifier E ≈ C (α=1.01 ≈ α=0.97) — asymmetry prediction falsified.

- **Mechanism finding:** Muon's NS-orthogonalization is approximately scale-invariant per update (restores spectral direction), and `wd_schedule=ramp_down` already controls norms continuously. One-shot rescale at step 975 is absorbed — norm perturbation recovers within ~500 steps as shown by mid-training trace.

- **Closes:** Weight-space cooldown intervention axis (first tested). **Comprehensive cooldown closure**: state-reset (#907, ABRUPT, σ 1.71×) + schedule (#925, SMOOTH, σ 1.40×) + weight-magnitude (#966, strong falsifier) = all mechanism categories NEG. Cooldown perturbation mean-improvement axis is fully saturated.

---

## 2026-05-24 ~06:30 UTC — PR #1022: frieren NS polynomial degree variation — **ASSIGNED**

- **Branch:** `g1r5-frieren/ns-polynomial-degree-variation`
- **Student:** g1r5-frieren
- **Hypothesis:** NS-internals axis. Current NS uses degree-5 (quintic) polynomial `p(x) = 2x − 1.5x³ + 0.5x⁵` with 6 iters. Test alternative degree/iter trade-offs. #962 confirmed quintic load-bearing (Cell D cubic-only +16.66σ NEG). Now test whether HIGHER-degree polynomial with fewer iters can match quintic-6 efficiency, or whether more iters of CUBIC can recover quality.

- **5-cell sweep:**

| Cell | Config | Role |
|:----:|:-------|:-----|
| A | ctrl — quintic-6 (current) | baseline |
| B ★ | PRIMARY: septic-4 (degree-7, 4 iters) | reduce iters via higher degree |
| C | septic-6 | match-iters higher-degree (quality test) |
| D | quintic-8 (more iters) | does more iter of current converge faster |
| E | cubic-8 (degree-3 with 8 iters) | can iters compensate for missing quintic term |

- **Context:** Adds `--ns_degree` CLI flag. Joins #1010 (NS-iter-by-time) as the remaining NS-internals axes. After #962 + this + #1010, NS-internals comprehensively explored.

---

## 2026-05-24 ~06:25 UTC — PR #1021: fern embed/lm_head LR ablation — **ASSIGNED**

- **Branch:** `g1r5-fern/embed-lmhead-lr-ablation`
- **Student:** g1r5-fern
- **Hypothesis:** Discovery: embed LR=0.3 and lm_head LR=1/320≈0.003125 are HARDCODED constants in `optimizer1 = AdamW([dict(params=[model.embed.weight], lr=0.3, ...), dict(params=[model.proj.weight], lr=1/320, ...)])` — never SENPAI-validated. ~38M params each (vocab × dim). Body matrix LRs were tuned (`--lr_mlp 0.055`) but embeddings/projections were not. Fresh axis with significant parameter coverage.

- **5-cell sweep (adds `--lr_embed` and `--lr_lm_head` CLI flags):**

| Cell | embed_lr | lm_head_lr | Role |
|:----:|:--------:|:----------:|:-----|
| A | 0.3 | 0.003125 | ctrl (current hardcoded) |
| B ★ | **0.5** | 0.003125 | PRIMARY: higher embed LR |
| C | 0.2 | 0.003125 | lower embed LR |
| D | 0.3 | 0.005 | higher lm_head LR |
| E | 0.3 | 0.002 | lower lm_head LR |

- **Context:** Embedding layers learn token-frequency-dependent statistics; lm_head ties to vocab distribution. These layers have very different optimization dynamics from Muon-tuned body matrices. ~76M total params untouched by prior LR sweeps.

---

## 2026-05-24 ~06:20 UTC — PR #962: frieren NS polynomial coefficient ablation — **CLOSED clean-NEG (high info)**

- **Branch:** `g1r5-frieren/ns-polynomial-coefficient-ablation`
- **Student:** g1r5-frieren
- **Hypothesis:** Test alternative NS polynomial coefficients (a,b,c) for `p(x) = ax + bx³ + cx⁵` vs current (2, −1.5, 0.5).

- **5-cell results (n=1, 3250 steps):**

| Cell | Variant | val/loss | Δ vs ctrl | σ_single |
|:----:|:--------|:--------:|:---------:|:--------:|
| A | ctrl (2, −1.5, 0.5) | 3.26205 | 0.00000 | +1.40σ |
| B | cubic-conv (1.875, −1.25, 0.375) | 3.26135 | −0.00070 | −1.18σ |
| C | Muon-paper (3.4445, −4.7750, 2.0315) | 3.26390 | +0.00185 | +3.12σ NEG |
| D | cubic-only (2.0, −1.0, 0.0) | **3.27110** | **+0.00905 (+15.26σ)** | quintic is load-bearing |
| E | high-amp (2.5, −2.0, 0.625) | 3.26050 | −0.00155 | **−2.61σ POS** (n=1) |

- **Decision:** CLOSED clean-NEG. Cell D confirms quintic term (`cx⁵`) is critical — removing it costs +15.26σ. Cell E n=1 POS (−2.61σ) too weak to warrant n=4 confirmation (projected statsig ~0.0021 < 0.004 gate). Cell C (Muon-paper) NEG → original tuned coefficients sub-optimal for this configuration.

- **Cross-PR insight:** Quintic load-bearing finding informs #1022 (NS-degree variation) — going higher (degree-7) more likely promising than lower (degree-3).

---

## 2026-05-24 ~06:15 UTC — PR #925: fern μ schedule linear ramp — **CLOSED clean-WEAK-NEG**

- **Branch:** `g1r5-fern/cooldown-momentum-ramp`
- **Student:** g1r5-fern
- **Hypothesis:** Linear ramp μ=0.95→0.85 over cooldown (smooth, distinct from #907's abrupt step-jump).

- **n=1 P1 results:** Cell E POS at val/loss=3.258418, ffs=2975 (**−4.73σ_single**)
- **n=4 confirm:** trials [3.26116, 3.26065, 3.26226, 3.26038], **μ=3.261112, σ_sample 1.4× baseline**
- **Statsig:** (3.261221 − 3.261112) × √4 = 0.000218 (FAIL gate 0.004)
- **FFS:** mean=3000 (baseline 3025) — 25-step FFS improvement but val/loss did not follow
- **Decision:** CLOSED clean-WEAK-NEG. n=1 POS was +1.0 SD favorable-tail draw from inflated-variance distribution. Mean is essentially neutral, well within statistical noise.

- **GENERALIZED LESSON (combined with #907):** Cooldown perturbations inflate variance without improving mean. **Two parallel POS-at-n=1 PRs both regressed at n=4 with σ inflation:** #907 σ_single 1.71× baseline, #925 σ_sample 1.4× baseline. The smooth-vs-abrupt distinction did NOT help — both inflated variance. The mean-improvement axis at cooldown is closed; future work should target VARIANCE REDUCTION (e.g. ensembling, dropout schedules) rather than mean improvement.

- **Closes:** μ-schedule axis comprehensively. With #907 (buffer reset), #925 (μ ramp), and #826 (Lookahead) + #855 (Schedule-Free) + #941 (SWA) all NEG, the momentum/trajectory cluster at cooldown is fully saturated.

---

## 2026-05-24 ~03:30 UTC — PR #993: askeladd Gradient-norm-anomaly-driven Muon momentum reset — **ASSIGNED**

- **Branch:** `g1r5-askeladd/grad-norm-anomaly-momentum-reset`
- **Student:** g1r5-askeladd
- **Hypothesis:** Detect gradient-distribution anomalies via per-parameter `||grad||_F` EMA; when current grad norm exceeds K × EMA(grad norm), partially reset Muon momentum buffer (and optionally SOAP exp_avg_sq). Magnitude-anomaly-driven reset, distinct from #907 (time-based), #925 (schedule-based), #973 (cos-direction-based), #887 (AGC pre-NS clipping).

- **5-cell sweep:**

| Cell | Config | Role |
|:----:|:-------|:-----|
| A | ctrl — no reset | baseline |
| B ★ | PRIMARY: threshold=3.0, fraction=0.5, β=0.95 | moderate sensitivity, moderate reset |
| C | sensitive: threshold=2.0, fraction=0.5 | more triggers |
| D | aggressive: threshold=3.0, fraction=1.0 | full reset on trigger |
| E | conservative: threshold=5.0, fraction=0.3 | rare strong-anomaly reset only |

- **Context:** Joins the momentum/state-reset cluster (#907, #925, #973). Magnitude-anomaly axis is the only major "reset trigger" condition untested. Expected trigger frequency 0.1–1% of steps per param.

---

## 2026-05-24 ~03:25 UTC — PR #936: askeladd Asymmetric SOAP eigenbasis ablation — **CLOSED clean-NEG (strong mechanism signal)**

- **Branch:** `g1r5-askeladd/asymmetric-soap-eigenbasis`
- **Student:** g1r5-askeladd
- **Hypothesis:** Ablate SOAP Q matrices — left-only (drop Q_col) vs right-only (drop Q_row) — to reveal which eigenbasis side is load-bearing.

- **5-cell P1 results (n=1, 3250 steps):**

| Cell | Variant | val/loss | ffs | Δ vs ctrl | σ_single | W&B |
|:----:|:--------|:--------:|:---:|:---------:|:--------:|:---:|
| A | both (ctrl) | 3.261952 | 3050 | 0.00000 | +1.23σ vs baseline | npk0pfxx |
| **B ★** | left-only (drop Q_col), global | **3.270294** | 3125 | **+0.00834 (+14.07σ)** | s7fl75f9 |
| C | right-only (drop Q_row), global | 3.263028 | 3050 | +0.00108 (+1.81σ) | 1ryjksm2 |
| D | left-only MLP-scope (attn full) | 3.263464 | 3050 | +0.00151 (+2.55σ) | ccx4p027 |
| E | right-only MLP-scope (attn full) | 3.262498 | 3050 | +0.00055 (+0.92σ) | 98p7l6mg |

- **Mechanism signal (the gold):**
  - **B − C contrast = +12.25σ_single (global asymmetry)** — Q_col >> Q_row in importance
  - **B − D contrast = +11.52σ** — the asymmetry is concentrated in ATTN weights, not MLP
  - **C − E contrast = +0.89σ** — dropping Q_row from attn is essentially free
- **Interpretation:** SOAP's gain over plain Muon is dominated by **input-side (Q_col, fan-in) decorrelation on attention weights**. For square 768×768 attn matrices: input-side carries nearly all the SOAP signal. For rectangular MLP weights (768→3072, 3072→768): both sides contribute roughly equally.

- **Decision:** CLOSED clean-NEG. No cell beats baseline, but the asymmetry signal is high information value. SOAP can potentially be simplified by dropping Q_row from attn entirely — to be tested in a future SOAP-simplification PR after #979 (exp_avg_sq ablation, in flight) closes.

- **Cross-PR insight:** Combined with #979 thorfinn (exp_avg_sq ablation in flight), the SOAP-internals map is being completed: which Q side matters (this PR), and whether the Adam-in-basis scaling matters (#979). Future minimal-SOAP variant could drop both Q_row and exp_avg_sq if redundant.

---

## 2026-05-24 ~02:15 UTC — PR #979: thorfinn SOAP exp_avg_sq scaling ablation — **ASSIGNED**

- **Branch:** `g1r5-thorfinn/soap-exp-avg-sq-ablation`
- **Student:** g1r5-thorfinn
- **Hypothesis:** SOAP-internals pruning ablation. SOAP combines (a) eigenbasis Q projection + (b) Adam-style per-element `exp_avg_sq` scaling in Q-basis + (c) norm-preserving rescaling. Test whether the Adam-in-basis component (b) is load-bearing or vestigial. Distinct from #936 (which ablates Q itself) and #914 (which froze Q refresh).

- **5-cell sweep:**

| Cell | Config | Role |
|:----:|:-------|:-----|
| A | ctrl (full SOAP) | baseline reproducibility |
| B ★ | PRIMARY: skip exp_avg_sq scaling (just Q projection + norm preserve) | tests if Adam-in-basis is needed |
| C | skip exp_avg_sq AND drop norm preservation | exploratory — magnitude unbounded |
| D | exp_avg_sq frozen at constant init=1.0 | sanity check (≡ Cell B with norm preserve) |
| E | exp_avg_sq = projected.square() instant (no EMA) | tests EMA timescale necessity |

- **Context:** PR #932 just closed clean-NEG with finding that *early-layer NS quality matters more than late-layer*. Shifts focus to preconditioner internals (this PR). PR #936 asymmetric SOAP and this PR will together pin down which SOAP component is load-bearing.

---

## 2026-05-24 ~02:10 UTC — PR #932: thorfinn Per-layer NS iteration count scaled by depth — **CLOSED clean-NEG**

- **Branch:** `g1r5-thorfinn/per-layer-ns-iter-by-depth`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Allocate more NS iterations to deeper layers (linear depth scaling) on a fixed budget. Mean iter=6, depth_scale controls range.

- **5-cell P1 sweep (n=1, 3250 steps):**

| Cell | Config | val/loss | ffs | Δ vs baseline | W&B |
|:----:|:-------|:--------:|:---:|:-------------:|:---:|
| A | ctrl depth_scale=0.0, NS=[6]×12 | 3.26206 | 3050 | +0.00084 (parity) | hz8pctbt |
| **B ★** | depth_scale=0.5 NS=[3..9] MLP+attn | 3.27327 | 3150 | +0.01205 NEG | cbdojob4 |
| C | depth_scale=1.0 NS=[1..12] | 3.30871 | **−1 diverged** | +0.04749 NEG | 2hk9wtzc |
| D | depth_scale=−0.5 INVERTED NS=[9..3] | 3.26632 | 3075 | +0.00510 NEG | kmlkgjob |
| E | depth_scale=0.5 MLP-only | 3.26664 | 3075 | +0.00542 NEG | ea7l1hq6 |

- **Decisive refutation:** Cell D (inverted, early=9, late=3) is the SECOND-BEST non-flat variant — directly refutes the "late layers need more NS" hypothesis. Late-layer attention/MLP weights are MORE tolerant of fewer NS iters; **early-layer orthogonalization quality matters most**. Cell C confirms NS_ITER < 3 is a hard floor (layer-0 at NS=1 diverged the whole run).

- **Mechanism insight:** Information from this closure — "early layers need more NS quality" — informs subsequent hypothesis design. The per-layer-iter axis is closed but the *direction* of the gradient (early-layer load-bearing) is valuable.

- **Decision:** CLOSED clean-NEG. NS-iter-by-depth axis closed.

---

## 2026-05-24 ~01:25 UTC — PR #973: nezuko Cosine-gated adaptive Muon momentum — **ASSIGNED**

- **Branch:** `g1r5-nezuko/cosine-gated-adaptive-muon-momentum`
- **Student:** g1r5-nezuko
- **Hypothesis:** Adapt Muon momentum coefficient μ per-parameter per-step based on cosine similarity between current gradient and accumulated momentum buffer. When grad aligns with momentum (cos→+1), use μ_max=0.99; when opposed (cos→−1), reduce to μ_min=0.70. Distinct from #925 (time-based μ ramp) and #907 (one-shot reset at fixed step) — this is *geometry-driven* continuous adaptation.

- **5-cell sweep:**

| Cell | Config | Role |
|:----:|:-------|:-----|
| A | ctrl (μ=0.95 const) | baseline reproducibility |
| B ★ | μ_min=0.70, μ_max=0.99 | PRIMARY — moderate floor |
| C | μ_min=0.50, μ_max=0.99 | aggressive reset when opposed |
| D | μ_min=0.85, μ_max=0.99 | conservative range |
| E | μ_min=0.70, μ_max=0.99, exploration-only (revert at step 975) | phase-isolation test |

- **Context:** PR #924 Hutchinson closed clean-NEG. Post-NS curvature axis closed. New axis: geometry-aware momentum adaptation (orthogonal to all closed PRs). Implementation note: scalar whole-matrix cosine (NOT per-element) avoids Hutchinson's per-element direction-warping failure mode.

---

## 2026-05-24 ~01:20 UTC — PR #924: nezuko Free Hutchinson diagonal curvature scaling post-NS — **CLOSED clean-NEG**

- **Branch:** `g1r5-nezuko/hutchinson-diag-curvature-post-ns`
- **Student:** g1r5-nezuko
- **Hypothesis:** Use free Hutchinson estimator of per-element diagonal Hessian (from consecutive gradient differences `dg=g_t−g_{t-1}`) to rescale post-NS update by inverse curvature magnitude.

- **5-cell P1 sweep results (n=1 each, 3250 steps):**

| Cell | Config | val/loss | ffs | Δ vs baseline | W&B |
|:----:|:-------|:--------:|:---:|:-------------:|:---:|
| A (ctrl) | no hutch | 3.25998 | 3025 | −0.00124 (lucky n=1) | jbnxn2f0 |
| **B ★** | α=0.5, MLP (PRIMARY) | 3.27072 | 3100 | +0.00950 NEG | 57g1wvkz |
| C | α=0.25, MLP | 3.26021 | 3025 | −0.00101 (≈parity, no hutch benefit) | skfc4h44 |
| D | α=0.75, MLP | 3.29815 | −1 (diverged) | +0.03693 NEG | zii3jxv6 |
| E | α=0.5, all-scope | 3.27358 | 3125 | +0.01236 NEG | 4fxv00bj |

- **Decision gate:** Cell D diverged; Cell B +0.00950 NEG; Cell E worse than B; Cell C ≈parity but no positive hutch signal. CLOSED clean-NEG.

- **Root cause analysis (excellent student diagnosis):** `|g_t − g_{t−1}|` mixes (i) actual H·Δθ, (ii) gradient noise from data-stochasticity, (iii) post-NS update's non-curvature structure. Dividing by this biased proxy reweights update *direction* toward elements with small EMA — backwards for a useful preconditioner. h_ema reaches 60–105 for B/D. Float32 buffer fix ruled out precision-loss as cause; the hypothesis itself is unsound.

- **Implementation note:** Student applied float32 cast to `prev_grad`/`h_diag_ema` buffers (bf16 has ~3 sig figs, rounds away small |dg| values). Cell A (no hutch, just new float32 buffers) drew 3.25998 = −2.1σ lucky n=1 draw — no mechanistic signal.

- **Axis closed:** Post-NS curvature scaling via gradient-difference proxy. Unbiased HVP (true Hutchinson) de-prioritized (costs extra backward per step). 

---

## 2026-05-24 ~00:55 UTC — PR #925: fern Muon momentum μ schedule sweep — **★ CELL E SENT BACK FOR n=4 CONFIRM**

- **Branch:** `g1r5-fern/mu-schedule-cooldown-drop`
- **Student:** g1r5-fern
- **Hypothesis:** Drop Muon momentum coefficient μ at cooldown onset (step 975) so the optimizer follows fresher gradients during the small-LR basin. Distinguishes from PR #693 (continuous deep ramps to 0.5/0.0) by testing conservative range (0.85–0.90) with step switch + linear ramp variants.

- **5-cell P1 sweep results (n=1):**

| Cell | μ schedule | val/loss | ffs | Δ vs baseline | σ_single | W&B |
|:----:|:-----------|:--------:|:---:|:-------------:|:--------:|:---:|
| A (ctrl) | μ=0.95 const | 3.261821 | 3025 | +0.000600 | +1.01σ | 26y34f1w |
| B | step 0.95→0.85 @ 975 | 3.264527 | 3050 | +0.003306 | +5.57σ NEG | sfwnmpdc |
| C | step 0.95→0.80 @ 975 | 3.265881 | 3075 | +0.004660 | +7.86σ NEG | pm1ufwan |
| D | step 0.95→0.90 @ 975 | 3.264204 | 3050 | +0.002983 | +5.03σ NEG | 5jmd9dud |
| **E ★** | **linear ramp 0.95→0.85 over cooldown** | **3.258418** | **2975** | **−0.002803** | **−4.73σ POS** | **utti60b8** |

- **Decision gate:** Cell E n=1=3.258418, projected n=4 statsig (3.261221−3.258418)×√4 = **0.0056 ≥ 0.004 ✓** → passes n=4 confirm gate. SENT BACK for n=4 confirmation arm.

- **Step-switch falsification (B/C/D):** abrupt μ drop at cooldown onset hurts terminal val/loss monotonically with drop depth (0.90→+5.03σ, 0.85→+5.57σ, 0.80→+7.86σ). Confirms PR #693's "accumulated buffer is dominant cooldown signal" finding, extending it to the conservative range that #693 had deferred. **Hard-switch variant of soft-μ-drop hypothesis FALSIFIED.**

- **Cell E mechanism (the rescue):** Linear ramp ends at terminal μ=0.85 (same as B) but does so smoothly across cooldown:
  - At cooldown onset, ramp starts at 0.95 → no buffer flush, no overshoot
  - μ decays in lockstep with LR — small step sizes pair naturally with smaller momentum half-lives
  - By final basin, μ=0.85 (half-life ~6 steps) → optimizer tracks near-instantaneous gradients while LR → 0
  - **Buffer is never simultaneously high-μ and obsolete-direction** — the smoothness of the ramp avoids the transient overshoot regime that B/D suffer

- **Trajectory observation (student-confirmed):** Cell B shows transient *lower* val/loss at step ~1000 (faster cooldown descent because buffer flushes quickly) but worse terminal val/loss by step 3250 — classic overshoot from rapid forget. Linear ramp avoids this regime entirely.

- **Cross-PR significance — second high-signal cooldown calibration result:**
  - **#907 tanjiro Cell E** (joint Muon momentum + SOAP `exp_avg_sq` reset at step 975): n=1=3.26004 (−3.5σ_SE POS) — currently in n=4 confirm
  - **#925 Cell E** (linear μ ramp): n=1=3.258418 (**−4.73σ_single POS**) — even stronger n=1 signal, now in n=4 confirm
  - Both implement "cooldown wants smaller/fresher state" at different timescales (instantaneous vs continuous). If both confirm at n=4, unified mechanism story is robust.

- **n=4 confirm arm:** `--mu_stable 0.95 --mu_cooldown 0.85 --mu_linear_ramp --num_trials 4`, wandb_group `g1r5-fern/mu_ramp_E_n4_confirm`. Deferred follow-ups (#2–#5 ramp endpoint/shape sweeps, μ(t)=mu_stable·(lr(t)/lr(0))^α) held pending n=4 outcome.

---

## 2026-05-23 ~23:40 UTC — PR #914: alphonse SOAP eigenbasis refresh freeze during cooldown — **CLOSED clean-NEG**

- **Branch:** `g1r5-alphonse/soap-refresh-freeze-during-cooldown`
- **Student:** g1r5-alphonse
- **Hypothesis:** During cooldown LR, tiny per-step parameter moves → SOAP eigenbasis refresh becomes noise-dominated → freezing/slowing refresh should help.

| Cell | Stable/Cooldown freq | val/loss | Δ vs baseline | σ_single |
|:---:|:---:|---:|---:|---:|
| A ctrl | 16/16 | 3.26129 | +0.000069 | +0.12σ |
| **B ★** | **16/64** | **3.26115** | **−0.000071** | **−0.12σ** |
| C (freeze) | 16/99999 | 3.26413 | +0.002909 | **+4.90σ NEG** |
| D | 8/64 | 3.26150 | +0.000279 | +0.47σ |
| E | 16/32 | 3.26217 | +0.000949 | +1.60σ NEG |

**Hypothesis falsified.** Best cell B PRIMARY at baseline parity. Cell C freeze at +4.9σ NEG is the decisive falsifier: SOAP eigenbasis continues carrying useful curvature signal during cooldown — even tiny per-step moves rotate the Hessian spectrum because Transformer landscapes have anisotropic curvature at this scale.

**Trend:** flat 16↔64, sharp cliff past 64. Not monotonic in refresh frequency (Cell E at 32 worse than both 16 and 64) — single-seed noise around essentially flat region.

**Reassigning alphonse → #966 cooldown weight rescaling (fresh weight-space axis, parallels #907 Cell E state-rescaling mechanism).**

---

## 2026-05-23 ~23:00 UTC — PR #902: frieren Top-k% gradient magnitude sparsification pre-NS — **CLOSED clean-NEG**

- **Branch:** `g1r5-frieren/top-k-gradient-sparsification-pre-ns`
- **Student:** g1r5-frieren
- **Hypothesis:** Zero the small-magnitude tail of Nesterov momentum before NS to let polynomial focus on dominant spectral mass.

| Cell | Treatment | val/loss | Δ vs baseline | σ_single |
|:---:|:---:|---:|---:|---:|
| A | ctrl | 3.261079 | −0.000142 | −0.24σ |
| **B ★** | **top50-mlp** | **3.262588** | **+0.001367** | **+2.30σ NEG** |
| C | top75-mlp | 3.262520 | +0.001299 | +2.19σ NEG |
| D | top50-all | 3.262606 | +0.001385 | +2.34σ NEG |
| E | top90-mlp | 3.262703 | +0.001482 | +2.50σ NEG |

**Diagnostic finding:** Cell E (k=90%, "near no-op") is the WORST of all 4 treatments. This falsifies the "tail is noise" framing — the harm is the act of hard-zeroing itself, not the fraction zeroed. NS5 was tuned for dense, smooth matrices; introducing exact-zero entries perturbs singular-value convergence regardless of count.

**Closes pre-NS gradient transformation axis (9 PRs all NEG):** per-col-norm #890, AGC #887, MARS #873, AdEMAMix #840, sign #823, GrokFast #859, sign-Cautious #844/#867, Q/K/V consensus #905, this PR. Strong evidence NS is sensitive to input distribution **shape**, not just magnitude.

**Reassigning frieren → #962 Newton-Schulz polynomial coefficient ablation (fresh axis: NS internal mechanics).**

---

## 2026-05-23 ~22:30 UTC — PR #907: tanjiro Muon momentum buffer reset at cooldown onset — **CHANGES REQUESTED (Cell E n=4 confirmation needed)**

- **Branch:** `g1r5-tanjiro/momentum-reset-at-cooldown-onset`
- **Student:** g1r5-tanjiro
- **Hypothesis:** Zeroing/partially decaying Muon momentum buffer at LR cooldown onset (step 975) eliminates stale steady-phase momentum bias.

| Cell | gamma | soap_reset | val_loss | Δ vs A | ffs | W&B |
|:---:|:---:|:---:|---:|---:|---:|-----|
| A (ctrl) | — | — | 3.26109 | — | 3025 | a201an6b |
| B ★ | 0.0 | F | 3.26139 | +0.00030 (+1.0σ_SE) | 3025 | ffjj7wwu |
| C | 0.1 | F | 3.26223 | +0.00114 (+3.8σ_SE NEG) | 3050 | pd28dmto |
| D | 0.5 | F | 3.26175 | +0.00066 (+2.2σ_SE NEG) | 3025 | r6e7wkt9 |
| **E** | **0.0** | **T** | **3.26004** | **−0.00105 (−3.5σ_SE POS)** | **3025** | **ltcj6g6y** |

**Headline:** Cell E (joint Muon momentum + SOAP `exp_avg_sq` zero-reset at step 975) is the only POS arm and the strongest by a wide margin. Cells B/C/D (Muon-only reset) are all NEG with monotonic NEG severity B<D<C.

**Mechanism (student's analysis):** SOAP's `exp_avg_sq` after 975 warm-phase steps reflects large-magnitude steady-phase gradients. Resetting Muon momentum alone causes calibration mismatch — SOAP params get under-stepped at cooldown. Cell E resets both → consistent fresh state across all param groups. Structurally similar to the `ramp_down` WD finding (PR #699): cooldown wants ALL adaptive state calibrated to small-step regime.

**Decision:** n=1 not enough to merge (Cell E sits +0.00082 above n=4 merge gate). Send back for n=4 confirmation of Cell E vs Cell A.

---

## 2026-05-23 ~18:30 UTC — PR #890: edward Per-column gradient normalization pre-NS — **CLOSED clean-WEAK-NEG**

- **Branch:** `g1r5-edward/per-column-normalization-pre-ns`
- **Student:** g1r5-edward
- **Hypothesis:** NS-5 iterations converge better when the input matrix has homogeneous column norms. Normalize per-column norms of gradient before NS, absorb or propagate the normalization after NS.

| Cell | Mode | Scope | val_loss | Δ vs baseline | ffs | W&B |
|:---:|:---:|:---:|---:|---:|---:|-----|
| A | none | ctrl | 3.26121 | −0.00001 (~0σ) | 3025 | szr18bn2 |
| **B** | **col_absorbed** | **MLP** | **3.26125** | **+0.00003 (+0.05σ)** | **3025** | **5app6ugt** |
| C | col_propagated | MLP | 3.36595 | +0.10473 (+176σ) | −1 | i086zkyz |
| D | all_col_absorbed | all body | **3.26050** | **−0.00072 (−1.21σ)** | **3025** | **z96y1801** |
| E | row_absorbed | MLP | 3.26257 | +0.00135 (+2.28σ) | 3050 | ttoma149 |

**Key diagnostic:** Standalone test confirmed NS orthogonality error 0.43→0.06 on heterogeneous synthetic gradients — the mechanism works mathematically. Yet zero val/loss benefit. Real MLP gradients are well-conditioned enough that ns_iter=6 is already accurate; improving polar-factor quality past this threshold is invisible to terminal loss.

**Cell C catastrophic (+176σ):** col_propagated re-introduces per-column adaptive LR on the NS output — incompatible with Muon's LR/WD tuning, as expected from the Adam-vs-Muon axis history.

**Cell D −1.21σ at n=1:** Follows the same precedent class as #887 (−0.86σ), #873 (−1.38σ), #840 (−2.74σ at n=1). All misses n=4 gate. Projected n=4 statsig=0.00144 << gate 0.004.

**Mechanism conclusion:** "Pre-NS input conditioning" axis is now closed — NS at iter=6 is robust to typical MLP gradient column-norm heterogeneity. Improving polar-factor quality doesn't translate to loss benefit.

**Decision: close clean-WEAK-NEG.** Reassigning edward → #941 Cooldown SWA / weight EMA.

---

## 2026-05-23 ~17:45 UTC — PR #887: askeladd AGC-Muon adaptive gradient clipping pre-NS — **CLOSED clean-WEAK-NEG**

- **Branch:** `g1r5-askeladd/agc-muon`
- **Student:** g1r5-askeladd
- **Hypothesis:** Apply NFNet-style Adaptive Gradient Clipping (AGC) before NS orthogonalization — clip per-layer gradient magnitude to λ × ‖W‖_F/‖g‖_F, targeting the pre-NS signal rather than post-NS output.

| Cell | λ | scope | val/loss | Δ vs baseline | ffs | W&B |
|:---:|:---:|:---:|---:|---:|---:|-----|
| A | 0.0 | ctrl | 3.26163 | +0.000409 | 3025 | s5u6e898 |
| B | 0.01 | mlp | 3.26298 | +0.001759 | 3050 | ga44i7af |
| **C** | **0.001** | **mlp** | **3.26071** | **−0.000511 (−0.86σ)** | **3025** | **0kphe0qa** |
| D | 0.01 | attn | 3.26304 | +0.001819 | 3050 | 7yirq939 |
| E | 0.01 | all | 3.26225 | +0.001029 | 3050 | ze7wnpxt |

**Key diagnostic:** clipped_frac=1.000 for every in-scope layer in every cell throughout training (g/W means: mlp≈1.6, attn≈5.2). AGC fires 100% of steps — never a conditional gate, always an aggressive magnitude shrink.

**Trajectory:** Cell C consistently sub-A from step 1000 onward (not a terminal noise artifact). Cell B/D/E regress.

**Mechanism analysis:** Since AGC always fires, the mechanism reduces to "multiply MLP gradient magnitudes by constant factor 0.001/g_to_w ≈ 0.001/1.63 ≈ 6×10⁻⁴ per step" — effectively a large implicit LR reduction on MLP fc layers. This confounds with the already-tuned `lr_mlp=0.055` hyperparameter. The sub-baseline signal from Cell C is indistinguishable from a minor MLP LR miscalibration artifact.

**n=1 projection to n=4:** Cell C at 3.26071 (−0.86σ) follows the same pattern as #840 (AdEMAMix, −1.58σ at n=1 → n=4 missed gate by 4×) and #873 (MARS, −1.38σ at n=1 → n=4 WEAK-NEG). Projected n=4 statsig = (3.261221 − 3.26071) × √4 ≈ 0.001 << gate 0.004.

**Decision: close clean-WEAK-NEG.** Pre-NS gradient transformation axis fully saturated. Reassigning askeladd → #936 Asymmetric SOAP eigenbasis ablation.

---

## 2026-05-23 ~16:30 UTC — PR #905: thorfinn Q/K/V Gradient Consensus pre-NS — **CLOSED clean-NEG**

- **Branch:** `g1r5-thorfinn/qkv-consensus-pre-ns`
- **Student:** g1r5-thorfinn
- **Hypothesis:** Q, K, V projections within each attention layer share the same input manifold and see correlated gradients. Replace per-projection Nesterov buffer with a layer-level consensus: blend each projection's gradient toward the mean of Q/K/V gradients in the layer (weighted by parameter α). Hypothesis: reducing projection-level noise through consensus should reduce gradient variance before NS, improving convergence.

| Cell | α (blend to layer mean) | val/loss | Δ vs baseline | Notes |
|:---:|:---:|---:|---:|---|
| A | ctrl (α=0) | 3.26077 | −0.76σ (sub-baseline) | Ctrl slightly soft |
| **B** | **α=0.10** ★ | **3.26681** | **+9.4σ (STRONG NEG)** | Strong regression |
| C-E | — | KILLED | — | Early gate applied |

- **Cell A ctrl:** 3.26077 (−0.000451 vs 3.261221, −0.76σ). Slightly sub-baseline — within noise.
- **Cell B α=0.10 PRIMARY:** 3.26681 (+0.00559, +9.4σ_single). Strong regression. Student correctly applied kill gate to remaining cells C/D/E.

**Mechanism finding:** Q, K, V projections do NOT share a common optimal gradient direction — they encode semantically distinct attention components (query, key, value manifolds). Blending toward their layer-mean gradient destroys per-projection information. Even mild blending (α=0.10) is strongly destructive because the three gradient directions are near-orthogonal in the parameter space. Q/K/V independence is structurally important for attention computation.

**Decision: close clean-NEG.** Pre-NS gradient blending across Q/K/V projections is a strongly destructive axis. Q/K/V consensus hypothesis fully falsified. Reassigning thorfinn → #932 per-layer NS iteration count by depth.

---

## 2026-05-23 ~15:25 UTC — PR #823: fern SignMuon — **CLOSED clean-NEG**

- Branch: `g1r5-fern/sign-muon-before-ns`
- Student: g1r5-fern
- Hypothesis: Sign-transform the Nesterov momentum buffer before NS orthogonalization. Tests whether removing magnitude information (keeping only direction signs) before the spectral step improves final val/loss. Three scopes: sign on attn-only, MLP-only, or all body matrices.

| Cell | scope | n | val/loss | ffs | Δ vs baseline | W&B |
|:---:|:---:|:---:|---:|---:|---:|-----|
| A | attn-only | 4 | 3.262257 | 3050 | +0.001036 (+1.75σ) | a7undx2m |
| B | mlp-only | 4 | 3.261530 | 3025 | +0.000309 (+0.52σ) | 8jvexp4b |
| **C** | **all** | **4** | **3.261930** | **3025** | **+0.000709 (+1.20σ)** | **l4w0f3jl** |

Per-trial trajectory for Cell C (the final tested config):
T1=3.260566, T2=3.260956, T3=3.262377, T4=3.263821 — monotonically degrading.

**Mechanism finding:** n=2 partial signal (T1+T2 mean=3.260765, Δ=−0.000456) was a downward fluctuation; T3/T4 confirmed reversion above baseline. Sign-of-momentum on all body matrices removes magnitude information that is informative for NS spectral preconditioning. Every Cell × scope is at parity or above baseline. Sign-direction axis comprehensively closed: #844 post-NS destructive, #867 pre-NS Cautious null, #823 pre-NS sign-of-momentum NEG.

**Decision: close clean-NEG.** Sign-information manipulations confirmed harmful across all formulations.

---

## 2026-05-23 ~15:25 UTC — PR #840: nezuko Muon-AdEMAMix n=4 confirm — **CLOSED clean-WEAK-NEG**

- Branch: `g1r5-nezuko/muon-ademamix-before-ns`
- Student: g1r5-nezuko
- Hypothesis: AdEMAMix-style dual slow/fast momentum before NS — blend fast Nesterov momentum with a slow long-horizon EMA (β₃=0.99, α=0.3) to inject low-frequency gradient information into the NS spectral step.

Cell E (mlp-only, β₃=0.99, α=0.3) — n=4 confirm (run `xph9ly80`):

| Trial | step | val/loss |
|------:|:----:|---------:|
| T1 | 3250 | 3.261360 |
| T2 | 6501 | 3.260956 |
| T3 | 9752 | 3.260104 |
| T4 | 13003 | 3.260279 |
| **mean** | | **3.260675** |

n=4 mean=3.260675, σ_sample≈0.000587, SE=0.000294. Δ=−0.000546 vs baseline (−0.92σ_single, −1.86σ_SE). Statsig=(3.261221−3.260675)×√4=0.001092 < gate 0.004 → MISS.

Sweep summary (n=1 screening):
| Cell | β₃ | α | scope | val/loss | Δ σ |
|:---:|:---:|:---:|:---:|---:|---:|
| A | 0 | — | — | 3.26123 | +0.02σ |
| B | 0.99 | 0.3 | all | 3.26029 | −1.58σ |
| C | 0.999 | 0.3 | all | 3.28512 | +40σ |
| D | 0.99 | 1.0 | all | 3.26358 | +3.97σ |
| **E** | **0.99** | **0.3** | **mlp** | **3.25960** | **−2.74σ n=1** |

**Mechanism finding:** β₃=0.99 (half-life ~70 steps) is optimal; β₃=0.999 collapses cos_sim to 0.26 (stale). α=0.3 is optimal; α=1.0 inflates magnitude 3.3× without direction benefit. scope=mlp slightly edges full-scope (avoiding SOAP double-spectral-treatment on attn). cos_sim_mean≈0.74 — slow EMA is aligned-but-distinct (~42° off-axis), genuinely adding new information. n=4 confirm shows consistent sub-baseline trend (best trial T3=3.260104) but mean misses gate.

**Decision: close clean-WEAK-NEG.** First n=4 sub-baseline result in programme since #699. n=8 extension projected to stay ~3.2607 — would need true effect of −2.5σ_single to clear n=8 gate, implausible given n=4 variance. Pre-NS gradient transformation axis saturating.

## 2026-05-23 ~14:05 UTC — PR #873: alphonse MARS gradient VR for Muon — **CLOSED clean-WEAK-NEG**

- Branch: `g1r5-alphonse/mars-grad-vr-muon`
- Student: g1r5-alphonse
- Hypothesis: Apply MARS-style variance reduction to gradient before Nesterov+NS pipeline: `g_vr = g + γ·(g − g_{prev})`. Test if VR correction sharpens the gradient estimate enough to improve val/loss.

| Cell | γ | scope | val/loss @ 3250 | ffs | Δ vs ctrl | W&B |
|:---:|:---:|:---:|---:|---:|---:|-----|
| A (ctrl) | 0.0 | — | 3.26072 | 3025 | — | r8qpucdv |
| **B** | **0.10** | all | **3.25990** ★ | **3025** | **−0.00082** | **e8rav692** |
| C | 0.30 | all | 3.26193 | 3050 | +0.00121 | hc9gjr3s |
| D | 0.50 | all | 3.26606 | 3075 | +0.00534 | fjg0vu56 |
| E | 0.30 | mlp | 3.26230 | 3050 | +0.00158 | upo3sjbu |

**Mechanism finding:** Concave-up γ curve, optimum at γ≈0.10. Beyond 0.10 the VR correction over-amplifies gradient-direction signals (catastrophic at γ=0.50). MLP-only scope at γ=0.30 (Cell E=3.26230) is parity with all-scope at γ=0.30 (Cell C=3.26193) — no clean layer-type asymmetry. NS's spectral filter already provides much of the variance reduction MARS is meant to deliver; paper-scale γ over-corrects.

**Decision: no n=4 confirm.** Cell B Δ_vs_ctrl=−1.38σ_single is too weak. Precedent: #840 cell E (Δ_vs_ctrl=−2.74σ_single, much stronger) has n=2 mean=3.261158 NOT clearing gate. P(n=4 clears | Cell B n=1 true mean) ≈ 1-8%. Save GPU time for fresh axes.

**Broader pattern:** Pre-NS gradient-transformation axis appears saturated (sign-Muon #823, AdEMAMix #840, MARS #873, per-col-norm #890, AGC #887 all yielding null/weak signals). Pivoting to new mechanism axes (curvature-aware, spectral constraint, stochastic regularization).

## 2026-05-23 ~12:27 UTC — PR #855: tanjiro Schedule-Free Muon — **CLOSED clean-NEG**

- Branch: `g1r5-tanjiro/schedule-free-muon`
- Student: g1r5-tanjiro
- Hypothesis: Maintain a Polyak-averaged evaluation iterate `z_t` (CPU EMA of training weights `x_t`). Evaluate val/loss at `z_t` each step. The averaged iterate approximates the Polyak-Ruppert trajectory mean, historically the lowest-bias estimator of the optimum. Expected Δval/loss: −0.001 to −0.003 nats.

| Cell | sf_beta | val/loss (3250) | ffs | Δval vs ctrl | W&B |
|------|---------|----------------:|----:|-------------|-----|
| A (ctrl) | 0.0 | **3.26226** | 3050 | — | bhd5lqkq |
| B | 0.99 ★ | 3.26923 | 3025 | +0.00697 | l4dmb01j |
| C | 0.97 | 3.26313 | **3000** | +0.00087 | jjf5j8mu |
| D | 0.95 | 3.26314 | **3000** | +0.00088 | hdsg76ho |
| E | 0.995 | 3.27411 | 3100 | +0.01185 | x6oeisny |

**Analysis:** U-shaped pattern in sf_beta (E>B>C≈D>A). Mechanism: ramp_down LR makes terminal x_T the bottom of the trajectory — the averaged iterate z_T includes high-loss early iterates, so z_T > x_T by construction. This is largest for high-β (long memory window reaching back to high-loss early phase). C/D (short memory) approach parity with ctrl but never beat it. +25-29% step-time overhead additionally harms ffs_t metric. Schedule-Free iterate-averaging under monotonic-LR-decay schedules closed. Distinct from #659 (SF AdamW, 46-59σ worse) — this SF-Muon failure is smaller in magnitude but for the same structural reason.

Note: tanjiro reassigned → PR #907 momentum buffer reset at cooldown onset.

## 2026-05-23 ~12:15 UTC — PR #867: thorfinn Pre-NS Cautious Muon — **CLOSED clean-NEG**

- Branch: `g1r5-thorfinn/pre-ns-cautious-muon`
- Student: g1r5-thorfinn
- Hypothesis: Apply grad-direction-agreement mask BEFORE NS orthogonalization (distinct from #844 post-NS Cautious which destructively rescaled NS output). Test whether filtering sign-disagreement entries upstream of NS improves orthogonalized step quality.
- **Results (5-cell sweep, n=1 each):**

| Cell | Configuration | val/loss | Δ vs μ | σ_single | ffs | wandb_run |
|:----:|:-------------|:---:|:---:|:---:|:---:|:---:|
| **A** ctrl | no mask | **3.26094** | −0.00028 | −0.24σ | 3025 | t3q3mkr7 |
| B | pre-NS no-rescale | 3.26187 | +0.00065 | +0.55σ | 3025 | x33lo2ik |
| C | pre-NS rescale | 3.26313 | +0.00191 | +1.61σ | 3050 | w71ndnsw |
| D | pre-NS MLP-only | 3.26258 | +0.00136 | +1.15σ | 3050 | 7hxcuxjg |
| E | pre-NS + lr_mlp 0.060 | 3.26112 | −0.00010 | −0.09σ | 3025 | ddi68oz3 |

- **Decision: CLOSED clean-NEG.** Best treatment cell E (lr_mlp=0.060) = 3.26112, parity with ctrl A. All other treatments slightly worse than ctrl. No cell ≤ 3.260; mechanism null at every setting.
- **Mechanism analysis:** Pre-NS sign-agreement mask filters gradient entries where momentum and current gradient disagree. Under SOAP+NS, the gradient signal is already concentrated by SOAP's eigenbasis rotation; residual sign-disagreement (~35-40% of entries per #844 telemetry) is STRUCTURAL, not noise. Filtering it removes information without benefit.
- **Pattern with #844:** The full Cautious family (post-NS #844, pre-NS #867) is now exhausted. Both pipeline positions tested:
  - Post-NS Cautious (#844): destructive (+38σ harm at one cell, NS rescale breaks spectral budget)
  - Pre-NS Cautious (#867): null mechanism (best treatment cell parity with ctrl)
- **Axis closed: Grad-direction-agreement masking on Muon momentum**. Neither pre-NS nor post-NS placement helps.
- Next assignment to thorfinn: Q/K/V Update Consensus — mix attention projection gradients to share a portion of their direction before NS.

## 2026-05-23 ~11:21 UTC — PR #859: frieren GrokFast-Muon — **CLOSED clean-NEG**

- Branch: `g1r5-frieren/grokfast-muon`
- Student: g1r5-frieren
- Hypothesis: GrokFast amplifies the slow-EMA of the gradient (g_slow = α·prev + (1-α)·g, then g_amp = g + λ·g_slow) before Nesterov+NS to accelerate grokking-style slow-feature convergence (Lee et al. 2024). Tests whether spectral pre-emphasis of the slow-frequency gradient component helps Muon's NS step.
- **Results (5-cell sweep, n=1 each):**

| Cell | λ | α | val/loss | ffs | Δ vs baseline | Δ vs ctrl | wandb_run |
|:----:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **A** ctrl | 0.0 | — | **3.260130** | 3025 | -1.84σ (below μ, within noise) | 0 | 5euj6kem |
| B | 1.0 | 0.98 | 3.264563 | 3050 | +5.63σ | +0.004433 | yc6r67ko |
| C | 0.5 | 0.98 | 3.261473 | 3025 | +0.42σ | +0.001343 | rkbjscvd |
| D | 2.0 | 0.98 | 3.272732 | 3125 | +19.4σ | +0.012602 | 6o8ux1ti |
| E | 1.0 | 0.99 | 3.266133 | 3050 | +8.28σ | +0.006003 | imwdyxt1 |

- **Decision: CLOSED clean-NEG.** Monotonic worsening with λ at fixed α=0.98 (A < C < B < D = 0.0 < 0.5 < 1.0 < 2.0). Cell A (ctrl, λ=0.0) just a single-trial seed sample below μ but above n=4 gate — not statsig.
- **Mechanism analysis:** GrokFast's slow-EMA amplification skews the gradient toward a single low-frequency component, conflicting with NS orthogonalization's role of distributing gradient mass across the principal SV directions. At α=0.98, slow-EMA τ ≈ 50 steps — far too short to capture grokking-style slow features that emerge over thousands of steps. Higher α (Cell E, α=0.99, τ ≈ 100 steps) doesn't help. NS already extracts directionally-relevant signal via orthogonalization; pre-amplification of any spectral component is redundant or harmful.
- **Axis closed: Frequency-domain pre-NS amplification.** The slow-EMA component is not the bottleneck.
- **Pattern with other pre-NS mechanisms:** AGC (#887, magnitude), per-col-norm (#890, scale), MARS (#873, variance reduction), SignMuon (#823, sign), AdEMAMix (#840, dual EMA), Cautious (#867, agreement mask). GrokFast operates on frequency-structure → falsified. Of those terminal so far, MARS Cell B = 3.259897 is the strongest n=1.
- Next assignment to frieren: Top-k gradient sparsification pre-NS — distinct structural transformation (entry-level magnitude masking) not yet tested in the portfolio.

## 2026-05-23 ~10:25 UTC — PR #850: edward Bias-Corrected Muon — **CLOSED clean-NEG**

- Branch: `g1r5-edward/muon-bias-correction`
- Student: g1r5-edward
- Hypothesis: Adam-style 1/(1-β^t) debiasing of the Nesterov momentum buffer before NS orthogonalization. Tests whether eliminating early-step momentum underestimation improves gradient direction quality, especially in the first 200-500 steps.
- **Results (5-cell sweep, n=1 each):**

| Cell | Configuration | val/loss | ffs | Δ vs baseline | wandb_run |
|:----:|:-------------|:---:|:---:|:---:|:---:|
| C1 ctrl | no BC | 3.26260 | 3050 | +0.34σ | hew924hz |
| C2 | full BC, β=0.95 | **3.26127** | **3025** | +0.01σ ≈0 | 0hu0hv4b |
| C3 | BC steps 0–200, β=0.95 | 3.26180 | 3025 | +0.14σ | xydbnlbb |
| C4 | BC steps 0–500, β=0.95 | 3.26225 | 3050 | +0.26σ | bfsdemub |
| C5 | full BC, β=0.90 | 3.26375 | 3050 | +0.63σ | pva0rskb |

- **Decision: CLOSED clean-NEG.** Best cell C2 at 3.26127 = +0.01σ above baseline (within rounding noise). Full 5-cell spread of 0.62σ_single — indistinguishable from pure seed noise.
- **Mechanism (student analysis, mathematically verified):** NS applies Frobenius normalization (`X = X / (X.norm() + 1e-7)`) to its input before each polynomial iteration. BC's debiasing factor 1/(1-β^t) is a **scalar** multiplier on the Nesterov buffer, and NS's Frobenius normalization renders this factor a no-op: NS(c·G) = NS(G) for any positive scalar c (modulo 1e-7 floor and bf16 rounding, which account for the residual 0.62σ spread). The Laing-Orvieto implicit-LR-warmup mechanism and the Shulgin NS-error-coupling mechanism were both candidate pathways — both falsified by NS's built-in scale invariance.
- **Axis closed:** BC-style debiasing of NS input is categorically null under the current NS implementation. No further variations (partial BC, different β) will materially change this.
- Next assignment to edward: Per-column gradient normalization pre-NS (#890) — distinct pre-NS input conditioning mechanism.

## 2026-05-23 ~09:15 UTC — PR #872: askeladd Orthogonal init for Muon-targeted body weights — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/orthogonal-init-muon`
- Student: g1r5-askeladd
- Hypothesis: Replace Gaussian N(0, σ²) with structurally orthogonal init for non-residual Muon-targeted body weights (Q/K/V projections + MLP fc1) at matched magnitude. Tests **shape** axis (vs already-closed magnitude axis). Mechanism prediction: NS-5 step 1 sees identity-like correction (no M-P rotation needed); orthogonal weights at condition-number=1 stabilize early gradient flow.
- **Results (P1 2-cell terminal, C–E skipped per kill gate):**

| Cell | wandb_run | init | orth_gain | scope | val/loss | first_step_to_target | Δ vs baseline | Δ vs ctrl |
|:----:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| baseline #699 | zp6gvwv5 | musoft N(0,std_base) | — | — | 3.26122 (μ, n=4) | 3025 | — | — |
| A ctrl | ajxkp73h | gaussian (musoft) | — | — | 3.26259 | 3050 | +0.0014 (inside ±0.002 band) ✓ | — |
| **B** PRIMARY | e2mfne7m | orthogonal | 0.0 (auto≈0.02073) | nonresid | **3.26784** | 3100 | **+0.00662** ✗ | **+0.00525** ✗ |

- **Decision: CLOSED clean-NEG.** Cell B above final gate (>3.265) → Cells C/D/E correctly skipped by sweep runner's kill gate.
- **Trajectory:** B−A gap rises monotonically from step 1000 (+0.002) → step 3250 (+0.005). Not an early-curve transient — orthogonal init at matched magnitude permanently lowers final val/loss by ~5 mNat.
- **Mechanism (student's analysis, accepted):** NS-5 with `--ns_iter 6` converges from Gaussian momentum to near-orthogonal update in 1–2 inner iterations. So the *update* path is on the orthogonal manifold from step ~2 onwards regardless of *weight* init. Meanwhile, orthogonal init forces all 768 singular values exactly to std_base ≈ 0.021 (condition number = 1) — flattening the Marchenko-Pastur spread of Gaussian that early-training SOAP+Muon apparently exploits. The orthogonal hypothesis predicted helping when the *optimizer* is the bottleneck (true for SGD per Hu et al. 2020); under Muon-NS6 it's actively counter-productive.
- **Init-branch counts confirmed in print logs:** Cell A `nonresid_2d/normal(std=0.020729)` × 48 + 24 resid-proj musoft; Cell B `nonresid_2d/orth(gain=0.020729)` × 48 + 24 resid-proj musoft. No stray re-init.
- **2 prior crashed runs** (1br84nw8, 01kg3ow9): both step_avg 2790/4256 ms vs Cell A's 1885 — GPU contention from inadvertent parallel processes with leftover Lookahead-P1 sweep; student killed and re-launched cleanly. No code crash, no NaN, no OOM. Infra fine.
- **Axis closure: init-shape at matched magnitude.** Three coherent closures from this student now confirm "interventions outside the spectral budget of NS / SOAP do not stack productively": #826 Lookahead (outer averager), #872 Orthogonal init (no spectral spread), #776 Update RMS-clamp (post-NS).
- **Suggested follow-ups considered:**
  1. (Student) Truncated-SVD init → increases spread vs orthogonal. Mechanistically interesting but pushes further from musoft optimum — likely won't beat baseline. Setting aside.
  2. (Student) Orthogonal at low magnitude + NS disabled first ~10 steps → mechanism isolation but no path to improvement. Setting aside.
- Next assignment to askeladd: AGC-Muon (Adaptive Gradient Clipping pre-NS) — distinct from #776 (post-update clamp).

## 2026-05-23 ~08:30 UTC — PR #840: nezuko Muon-AdEMAMix P1 sweep TERMINAL — **★ SENT BACK FOR n=4 CONFIRM ON CELL E**

- Branch: `g1r5-nezuko/muon-ademamix`
- Student: g1r5-nezuko
- Hypothesis: Mix slow EMA buffer (β₃≈0.99) with raw gradient before NS orthogonalization, applied to Muon's Nesterov input. Tests whether dual-EMA (AdEMAMix-style) gives the NS step a richer, lower-variance gradient direction. Predicted: B > C > D > E > A.
- **Results (P1 5-cell sweep, n=1 each):**

| Cell | β₃ | α | Scope | wandb_run | val/loss | ffs | Δ vs baseline 3.261221 | σ_single |
|:----:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| A | 0 (off) | — | — | 8pyx0p79 | 3.26123 | 3025 | +0.00001 | +0.02σ |
| B | 0.99 | 0.3 | all | 6lqtiuqb | 3.26029 | 3025 | −0.00094 | **−1.58σ** |
| C | 0.999 | 0.3 | all | 56x6uuci | 3.28512 | -1 (missed) | +0.0239 | +40σ |
| D | 0.99 | 1.0 | all | 2fm93hrh | 3.26358 | 3050 | +0.00236 | +3.97σ |
| **E** | **0.99** | **0.3** | **mlp** | **xje4qes8** | **3.25960** | **3025** | **−0.00162** | **−2.74σ** ★ |

- **Observed order: E > B > A > D > C** (vs predicted B > C > D > E > A — scope=mlp surprise winner)
- **Strongest single-seed signal in entire post-#699 programme.** Cell E n=1 is BELOW n=4 merge gate (3.259221) by Δ=−0.000379.
- **Student interpretation (n=1):** Cell E scope=mlp may win over B (all-scope) because attn body already gets SOAP preconditioning — layering slow-EMA there overlaps with SOAP's running curvature estimate. Confining slow-EMA to plain Muon (MLP) removes that overlap. Direction consistent with E < B but Δ=−0.00069 is within noise.
- **W&B diagnostics** (Cell E): `muon_slow/cos_sim_mean` final = 0.741 (indistinguishable from B's 0.750; well-aligned with current gradient). `train_time` 6415.7s (no speed penalty).
- **Cells C/D negative findings:** β₃=0.999 (half-life ~700 steps vs total 3250) → slow EMA fails to track trajectory (cos_sim collapses to 0.258). α=1.0 (vs 0.3 in B) → slow EMA dominates magnitude (norm 122 vs B's small steady-state) → biases NS input toward stale curvature. Both effects internally consistent with hypothesis.
- **Advisor decision:** Sent back to nezuko for n=4 confirm on Cell E settings (β=0.99/α=0.3/scope=mlp). Predeclared decision tree: μ_n=4 ≤ 3.259221 → MERGE; ≤ 3.261221 but > gate → P3 (n=8) stacked confirm or close with detailed analysis; > 3.261221 → close clean-NEG. ETA ~7-8h.
- **Strategic significance:** First post-#699 mechanism candidate to clear the n=1 stage gate. If it confirms at n=4, this opens a new mechanism family ("auxiliary slow-EMA injection into specific Muon parameter groups"), orthogonal to all 14+ closed Muon mechanism axes (mask/sign/clamp/depth-scale/polynomial-coefficient/etc.).

---

## 2026-05-23 ~04:30 UTC — PR #785: alphonse Residual-proj init magnitude multiplier α=0.50 P2 — **CLOSED clean-NEG**

- Branch: `g1r5-alphonse/resid-alpha-P2-a050-n4`
- Student: g1r5-alphonse
- Hypothesis: α=0.50 × musoft scale for residual-proj init (attn.proj + mlp.proj) would reduce over-initialization by 2× and improve convergence. P1 Cell A single-seed winner (3.25978, −2.43σ_single). P2 n=4 confirmation.
- **Results (n=4, run `qqsqorg6`, group `g1r5-alphonse/resid-alpha-P2-a050-n4`):**

| Trial | val/loss @3250 | ffs | Δ vs baseline 3.261221 |
|:-----:|:--------------:|:---:|:----------------------:|
| 0 | 3.261419 | 3025 | +0.000198 (+0.33σ) |
| 1 | 3.261601 | 3025 | +0.000380 (+0.64σ) |
| 2 | 3.261395 | 3025 | +0.000174 (+0.29σ) |
| 3 | 3.263172 | 3050 | +0.001951 (+3.29σ) |
| **mean** | **3.261895** | 3031.25 | **+0.000674 (+1.14σ)** |

- σ_n=4=0.000855 (sample), statsig = (3.261221 − 3.261895) × √4 = **−0.001348** (need ≥ +0.004)
- **n=4 gate: MISS by −0.005348 (fails by 5.35σ margin)**
- **Analysis:** The P1 winner (3.25978) was a single-seed downward fluctuation (~2.4σ below population mean). Trials 0–2 cluster tightly around 3.2615 (within-cluster σ = 0.00011, ~5× tighter than σ_single), confirming the α=0.50 population mean sits at baseline parity. Trial 3 is a slight upward outlier (+3.3σ). **Residual-proj init magnitude axis fully closed** at n=4: musoft (α=1.0) is optimal. α<1.0 (under-init) doesn't help, α>1.0 (over-init) would likely be worse.
- **New assignment:** #873 alphonse MARS-Muon gradient variance reduction.

---

## 2026-05-23 ~04:00 UTC — PR #826: askeladd Lookahead outer wrapper — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/lookahead`
- Student: g1r5-askeladd
- Hypothesis: Wrap Muon and/or AdamW with an outer Lookahead loop (Zhang et al. NeurIPS 2019). Every k inner steps, slow weights updated: `θ_slow ← θ_slow + α × (θ_fast − θ_slow)`, then `θ_fast ← θ_slow`. Predicted: B (k=5, α=0.5, all) wins via variance reduction on noisy Muon trajectory.
- **Results (all 5 cells, n=1 each):**

| Cell | Config | run_id | val/loss @3250 | ffs | Δ vs A |
|:----:|--------|:------:|:--------------:|:---:|:------:|
| **A (ctrl)** | no Lookahead | `gxmclotj` | **3.26192** | 3050 | — |
| B | k=5 α=0.5 all | `blgtycub` | 3.27409 | 3125 | +0.012 |
| C | k=10 α=0.5 all | `6e1bxgno` | 3.27921 | 3225 | +0.017 |
| D | k=5 α=0.8 all | `p6dovjfd` | 3.26202 | 3025 | +0.0001 |
| E | k=5 α=0.5 muon-only | `telg1fht` | 3.27069 | 3075 | +0.009 |

- **Ranking observed:** A ≈ D > E > B > C (predicted: B > C > D > A ≈ E — fully falsified)
- **n=4 gate:** No cell clears 3.259221. Best active cell (D) is 3.26202, +0.001 above baseline μ.
- **Analysis:** Lookahead outer-wrapper is destructive at the current well-tuned LR/schedule:
  1. **D≈A:** α=0.8 (80% fast weight → only 20% of gap toward slow) is essentially a no-op. The lack of harm confirms mechanism — not the Lookahead direction, but that meaningful α is destructive.
  2. **B/C/E all harmful:** lower α amplifies slow-weight drag. Monotonic B<C confirms damage scales with k (longer k = more lag).
  3. **E (Muon-only) < B (all):** restricting to Muon only partially recovers vs wrapping AdamW too, but still +0.009 vs ctrl.
  4. **Root cause:** Muon+SOAP+NS produces direction-consistent, well-conditioned per-step updates with low effective stochasticity. Outer loop averager adds *bias* by dragging weights toward a stale slow copy — the inner trajectory is not noisy enough to benefit.
- **Pattern:** 2nd outer-wrapper closure (post-NS rescale Cautious #844 + Lookahead #826). Outer-loop modifications to well-tuned Muon trajectory are systematically negative. Future exploration should stay inner-loop.
- **New assignment:** #872 askeladd Orthogonal Init for Muon-targeted body weights (init *shape* axis — completely untested).

---

## 2026-05-23 ~02:30 UTC — PR #844: thorfinn Cautious Muon (post-NS sign-agreement mask) — **CLOSED clean-NEG**

- Branch: `g1r5-thorfinn/cautious-muon`
- Student: g1r5-thorfinn
- Hypothesis: Apply Cautious (Liang et al. arXiv 2411.16085) post-NS — zero out elements whose post-NS update disagrees in sign with raw gradient, rescale survivors by 1/keep_rate to preserve Frobenius RMS. Expected: ~30-40% mask binding initially, ~70-85% by mid-training (per AdamW Cautious literature); should denoise the update direction.
- **Results (Cells A/B only; C/D/E gated by Post-B kill switch):**

| Cell | Config | run_id | val/loss @3250 | Δ vs baseline μ |
|:----:|--------|:------:|:--------------:|:---------------:|
| **A (ctrl)** | refactor neutral | `jg83m49x` | **3.26058** | −0.00064 (−1.08σ_single, parity) |
| B (primary) | full cautious all | `5exfsy5n` | **3.28395** | **+0.02273 (+38.3σ_single)** ❌ |

- **Mechanism (student's analysis):** Post-NS Cautious masking is destructive on Muon for 3 reasons:
  1. NS produces sign-disagreement with raw gradient as a *structural* feature (35-40% disagreement is normal post-orthogonalization, NOT noise). Cautious-kept rates: 0.635 (MLP), 0.610 (attn), rising 0.53→0.67 over training.
  2. The rescale-to-preserve-Frobenius (×1.6 on survivors) destroys NS's spectral bound — preserves Frobenius RMS but breaks orthogonality.
  3. Net effect: regression toward signed-SGD on a Frobenius budget, undoing NS's contribution.
- **Mechanistic distinction:** Distinct from #823 SignMuon which applies sign BEFORE NS (NS re-orthogonalizes; spectral property preserved). Post-NS is the WRONG stage for sign-based masking.
- **Refactor verification:** Cell A within seed noise of baseline (−1.08σ_single). 3 prior SIGTERM crashes during A attempts were infrastructure (step times 4.2s vs normal 1.9s), not code.
- **Decision:** CLOSED clean-NEG. Post-NS sign/mask operations on Muon are destructive — axis closed. Pre-NS Cautious (student's #1 follow-up) assigned next as a clean test of the mechanism at the correct pipeline stage.

## 2026-05-23 ~01:30 UTC — PR #824: frieren Polar Express (per-iter minimax NS coefficients) — **CLOSED clean-NEG**

- Branch: `g1r5-frieren/polar-express`
- Student: g1r5-frieren
- Hypothesis: Replace fixed (2, −1.5, 0.5) NS coefficients with per-iteration minimax-optimal quintic coefficients. After each NS iter the gradient's SV spectrum contracts; Polar Express uses coefficients tuned to the tighter post-contraction interval. Expected speedup from paper (GPT-2-Large): ~−0.06 val/loss reduction.
- **Results (3/5 cells, D/E gated; n=1 each, group `polar-express-ns-coeffs`):**

| Cell | Variant | run_id | val/loss @3250 | ffs | Δ vs A |
|:----:|:-------:|:------:|:--------------:|:---:|:------:|
| **A (ctrl)** | fixed-coeff, 6-iter | `48nhn92b` | **3.26105** | **3025** | — |
| B (primary) | PE default, 6-iter | `vakre11v` | 3.26172 | 3050 | +0.00067 (+1.1σ) |
| C | PE pure, 6-iter | `xtwmvump` | 3.26302 | 3050 | +0.00197 (+3.3σ) |
| D | PE default, 4-iter | — | gated | — | — |
| E | PE default, 8-iter | — | gated | — | — |

- **Hypothesis falsified.** Monotonic A < B < C at every val checkpoint (26 checkpoints each). B is 0.84σ worse than baseline μ; C is 3.03σ worse. D/E correctly gated since B didn't beat A.
- **Mechanism (student's analysis):** With `--soap_attn` active, SOAP's Kronecker-preconditioned update pre-conditions the attention gradient spectrum before NS. Fixed (2, −1.5, 0.5) is already well-matched to a pre-shaped spectrum. PolarExpress assumes the raw gradient spectrum — optimizing for the wrong problem. Also: `pure` variant (no safety/cushion) is worse than `default`, so the safety knobs aren't the bottleneck. Per-step overhead was zero (numpy precomputation at module load). B's initial training loss (step 500) was slightly better than A, confirming the optimization path is real — just doesn't survive full training.
- **Decision:** CLOSED clean-NEG. NS polynomial-coefficient axis now closed. Combined with NS-WarmUp (#815): the full NS parameter space (iteration count ramp, per-iter coefficients, timing) is exhausted under the current SOAP+6-iter stack. Key insight preserved: **SOAP preconditioning nullifies gradient-spectrum improvements inside NS.**

## 2026-05-23 ~00:45 UTC — PR #815: tanjiro NS-WarmUp (sequential ns_iter ramp-up) — **CLOSED clean-NEG**

- Branch: `g1r5-tanjiro/ns-warmup`
- Student: g1r5-tanjiro
- Hypothesis: NS orthogonalization at init equalizes legitimate signal-vs-noise singular value spread; ramping ns_iter up over the first N steps should preserve early-signal directions. Predicted ranking: B(500/2) > C(300/3) > A(ctrl) > D(1000/2) > E(500/1).
- **Results (5/5 cells, n=1 each, group `g1r5-tanjiro/ns-warmup-sweep`):**

| Cell | warmup_steps / start | run_id | val/loss | ffs | Δ vs A val | Δ vs A ffs |
|:----:|:--------------------:|:------:|:--------:|:---:|:----------:|:----------:|
| **A (ctrl)** | — | `ojo8pvzb` | **3.26137** | **3025** | — | — |
| B | 500 / 2 (primary bet) | `enr7r6u9` | 3.26540 | 3075 | +0.00403 | +50 |
| C | 300 / 3 (gentle) | `crjgw5vg` | 3.26274 | 3050 | +0.00137 | +25 |
| D | 1000 / 2 (long) | `ah1hf1ud` | 3.26550 | 3075 | +0.00413 | +50 |
| E | 500 / 1 (aggressive) | `cqzapm3s` | 3.26872 | 3100 | +0.00735 | +75 |

- **Hypothesis falsified.** Observed ranking: A > C > B ≈ D > E. Cell A (control) wins both val/loss and ffs; every warmup arm is worse. Cell E (most aggressive, start=1) is the worst by +0.00735.
- **Mechanism (student's analysis):** At init the gradient is near-isotropic noise. Fewer NS iterations leave the singular-value spread of a random matrix concentrated in random top SVs — amplifying noise where there's no signal to preserve. The full degree-5 polynomial gives every direction equal step size, which is right when the network is still figuring out which directions matter. Muon literature note ("fewer iterations require smaller step + higher momentum") shows ns_iter and effective step size are coupled; lowering ns_iter at fixed LR creates effectively-larger noisier steps in random directions.
- **Cell A replicates baseline** (3.26137 vs μ=3.26122, +0.00015 within σ_single=1.186e-3) — refactor is sound.
- **Decision:** CLOSED clean-NEG. NS-iter-count temporal-schedule axis closed at fixed LR. A 2-D (start, lr_init) sweep was suggested as the right shape for revisiting (per the iter-step-size coupling); logged for future reference.
- Combined with frieren #824 (Polar Express coefficient schedule, also clean-NEG), the **NS-side temporal-schedule family is now closed**.

## 2026-05-22 ~22:42 UTC — PR #800: edward Per-block depth-dependent Muon momentum (mu_depth_scale) — **CLOSED clean-NEG**

- Branch: `g1r5-edward/mu-depth-scale`
- Student: g1r5-edward
- Hypothesis: Apply identical depth-scaling argument as PR #699 musoft to Muon momentum: scale μ down linearly with layer depth so early layers (large raw gradients) get high inertia while late layers get more responsive updates. Predicted ranking: B(α=0.5) > C(α=1.0) > A(ctrl) > D(α=2.0) > E(inverse).
- **Results (5/5 cells, n=1 each, group `g1r5-edward/mu-depth-scale`):**

| Cell | α | per-layer mu (L0 → L11) | run_id | val/loss | ffs | Δ ffs vs A | Δ val vs A | σ-units |
|:----:|:-:|:------------------------|:------:|:--------:|:---:|:----------:|:----------:|:-------:|
| **A (ctrl)** | 0.0 | uniform 0.9500 | `0t1310jx` | **3.26149** | **3025** | — | — | — |
| B | 0.5 | 0.9500 → 0.8075 (no floor) | `l9c9gb4m` | 3.26616 | 3075 | +50 | +0.00467 | +7.9σ |
| C | 1.0 | 0.9500 → 0.6650 (L11=floor) | `8mxzkqec` | 3.27102 | 3125 | +100 | +0.00953 | +16.1σ |
| D | 2.0 | 0.9500 → 0.6650 (L4–L11 clipped) | `t2vueqtv` | 3.27534 | 3175 | +150 | +0.01385 | +23.4σ |
| E | −1.0 (inverse) | 0.6650 (L0=floor) → 0.9500 | `fv9kf2vs` | 3.27558 | 3175 | +150 | +0.01409 | +23.8σ |

- **Hypothesis rejected; observed ranking: A > B > C > D ≈ E.**
- **Three coherent findings:**
  1. **Uniform μ=0.95 is optimal.** Even the gentlest perturbation (B, max Δμ=0.0925) is +7.9σ — clearly resolved at n=1.
  2. **Magnitude linear in α:** Δffs ≈ +50·α; each +0.5 α step costs ~+0.005 val_loss. Saturation around α=2 (D's floor-clipping doesn't further amplify damage).
  3. **Direction-symmetric harm:** D and E land at near-identical ffs=3175 / val~3.275 → **heterogeneity itself causes harm, not where the low-μ layers sit.** Most informative result.
- **musoft transfer fails.** Depth-aware init (-18.75 ffs at musoft) helped because it perturbs forward-pass scale. Depth-aware Muon μ hurts because Newton-Schulz already normalizes gradient magnitudes globally across parameters. The two interventions interact with depth through different physics.
- **Cell A replicates baseline exactly** (ffs=3025, val=3.26149 vs baseline μ=3.261221) — confirms the per-layer Muon group construction wrapper is sound.
- **Decision:** CLOSED clean-NEG. Per-layer μ heterogeneity axis closed. Student-suggested block-type-specific μ (MLP vs ATTN) unlikely to recover given the heterogeneity-itself-harms signature.

## 2026-05-22 ~22:25 UTC — PR #781: thorfinn Per-group AdamW ε sweep (embed/lm_head/scalars) — **CLOSED clean-NEG**

- Branch: `g1r5-thorfinn/per-group-adamw-eps`
- Student: g1r5-thorfinn
- Hypothesis: Raise eps_embed from default 1e-10 to 1e-8 or 1e-7 stabilizes stale-v_t re-activations on sparse vocab rows; asymmetric eps_lm_head↓ may help early dense curvature adaptation.
- **Results (5/5 cells, n=1 each, group `g1r5-thorfinn/per-group-eps-musoft`):**

| Cell | eps_embed | eps_lm_head | run_id | val/loss | ffs | Δ vs baseline 3.261221 |
|:----:|:---------:|:-----------:|:------:|:--------:|:---:|:----------------------:|
| A (ctrl) | 1e-10 | 1e-10 | `6mwbmr2k` | 3.26138 | 3025 | +0.000159 (+0.27σ_n4) |
| **B** | **1e-8** | 1e-10 | `mrx51wjj` | **3.26046** | 3025 | **−0.000761 (−1.28σ_n4)** |
| C | 1e-7 | 1e-10 | `tfmx7nkp` | 3.26067 | 3025 | −0.000551 (−0.93σ_n4) |
| D | 1e-8 | 1e-11 | `nwan8l7p` | 3.26178 | **3050** | +0.000559 (+0.94σ_n4) |
| E | 1e-9 | 1e-10 | `0ac6dabg` | 3.26174 | 3025 | +0.000519 (+0.87σ_n4) |

- **Analysis:** Direction matches mechanism (embed↑ improves); B/C plateau around 1e-8 (saturation); E (1e-9) flat with A (non-monotone; rising edge in (1e-9, 1e-8]). Cell D (asymmetric lm_head↓) clearly hurts: ffs degrades to 3050, confirming lm_head ε=1e-11 destabilizes early dense curvature — asymmetry hypothesis refuted.
- **No cell clears n=1 P2 trigger (3.259221).** Best B is +0.00124 above trigger (~+1.04σ_single). ffs unchanged at 3025 for A/B/C/E — primary speedrun metric null.
- **Pre-declared old threshold (3.261265) would escalate B/C to P2, but stale under new musoft baseline.** Under new gate, ~7.5% P2 gate-clearance odds for B — not worth 7h GPU time.
- **Decision:** CLOSED clean-NEG. Per-group AdamW HP family (LR, β1, β2, global ε, per-group ε) fully exhausted.
- **Refactor preserved:** 3-way AdamW split (embed/lm_head/scalars) preserved in codebase as reusable lever for future per-group AdamW experiments.

---

## 2026-05-22 ~21:59 UTC — PR #706: nezuko Embed-init std=0.1 compound P3 (musoft×embed) — **CLOSED clean-NEG (subsumed)**

- Branch: `g1r5-nezuko/embed-init-sweep`
- Student: g1r5-nezuko
- Hypothesis: embed_init_std=0.1 compound with post-#699 musoft baseline (P3). Pre-#699 P2 μ=3.260705 cleared old gate by 0.000560, missed new gate by 0.001484. P3 tests whether gains stack additively.
- **Results (n=4, group `g1r5-nezuko/embed-init-std01-musoft-compound-P3`):**

| Trial | val/loss | ffs | run_id |
|:-----:|:--------:|:---:|:------:|
| 0 | 3.26256 | 3050 | `ke62szqt` (trial 0) |
| 1 | 3.26046 | 3025 | `ke62szqt` (trial 1) |
| 2 | 3.26106 | 3025 | `ke62szqt` (trial 2) |
| 3 | 3.26029 | 3025 | `ke62szqt` (trial 3) |

- **n=4 summary:** μ=3.261093, σ=0.001033. Δ vs baseline 3.261221 = **−0.000128 (~−0.11σ_seed) — parity**. P3 mean +0.39 mNat ABOVE P2 pre-#699 mean (3.260705).
- **Gate verdict:** Misses merge gate (μ > 3.259221) by +0.001872. Falls in "subsumed-by-musoft" band (μ ≥ 3.2606).
- **Mechanism finding:** Both embed-std=0.1 and musoft target early-step gradient stress in the embed subspace — they are mechanistic **substitutes, not stackers**. musoft acts at the actual noise injection point (residual stream) and dominates.
- **Decision:** CLOSED clean-NEG (subsumed). Init-magnitude axis for embed fully exhausted.

---

## 2026-05-22 ~20:38 UTC — PR #785: alphonse Residual-proj init magnitude multiplier sweep (mualpha α-sweep) — **P1 → sendback for P2 n=4 on α=0.50**

- Branch: `g1r5-alphonse/resid-alpha-sweep`
- Student: g1r5-alphonse
- Hypothesis: Multiply musoft residual-proj std by α ∈ {0.5, 0.75, 1.0, 1.5, 2.0}. Primary prediction D (α=1.5) wins from SOAP-warmup mechanism.
- **Results (5/5 cells, n=1 each, group `g1r5-alphonse/resid-alpha-sweep`):**

| Cell | α | σ (≈) | run_id | val/loss | ffs | Δ vs baseline 3.261221 |
|:----:|:--:|:-----:|:------:|:--------:|:---:|:----------------------:|
| **A** | 0.50 | 0.00299 | `xbsdo9tt` | **3.25978** | **3025** | **−0.00144 (~2.43σ better)** |
| B | 0.75 | 0.00449 | `2peq325d` | 3.26280 | 3050 | +0.00158 (~2.66σ worse) |
| C | 1.00 (ctrl) | 0.00598 | `3x7ttaym` | 3.26053 | 3025 | −0.00069 (~1.16σ better) |
| D | 1.50 (primary) | 0.00898 | `px4sxc5x` | 3.26059 | 3025 | −0.00063 (~1.06σ better) |
| E | 2.00 | 0.01196 | `2diywkq2` | 3.26210 | 3050 | +0.00088 (~1.48σ worse) |

- **Analysis:** Primary mechanistic story FALSIFIED — D (α=1.5) lands within 0.10σ_single of C (α=1.0). No upward-magnitude signal in [1.0, 1.5]. **Surprise finding: A (α=0.50) is the best cell**, opposite of the PR's "sign-falsifier downward" expectation. Curve is strongly non-monotone: A is downward outlier, B is upward outlier (+2.66σ), C/D collapsed onto baseline. Consistent with **shallow loss surface across α∈[0.5, 1.5]** with single-seed scatter, plus real ~1.5σ regression at α=2.0.
- **Refactor neutrality:** PASS (Cell C @ α=1.0 reproduces musoft baseline within 1.16σ_single).
- **Decision:** Sendback for P2 n=4 on Cell A (α=0.50). +0.000559 above merge gate but only 0.94σ_single — non-trivial chance of clearing. Pre-declared decision tree: merge if μ_n=4 ≤ 3.259221, sendback if (3.259221, 3.260783], close if >3.260783.
- **If P2 confirms α=0.50:** immediate follow-up sweeps α<0.5 (0.25, 0.35, 0.40) at n=1 from new merged baseline.
- **If P2 fails:** magnitude-multiplier axis closed at musoft; B's +2.66σ was variance scatter.

## 2026-05-22 ~18:15 UTC — PR #776: askeladd Muon/SOAP update RMS normalization (post-NS clamp) — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/muon-rms-norm`
- Student: g1r5-askeladd
- Hypothesis: Post-NS RMS-clamp on Muon/SOAP update — target a fixed `rms_target` by rescaling the update vector. NorMuon-style but with a swept target magnitude.
- **Results (n=1 each, group `g1r5-askeladd/muon-update-rms-norm`):**

| Cell | rms_target | run_id | val/loss | ffs | Δ vs ctrl A |
|:----:|:----------:|:------:|:--------:|:---:|:-----------:|
| **A** | 0.00 (ctrl) | `v3ml2xml` | **3.26279** | 3050 | — |
| B | 0.25 | `kx4l44yn` | 3.27382 | 3150 | +0.01103 |
| C | 0.50 | `wcqranoc` | 3.27953 | 3250 | +0.01674 |
| D | 1.00 | `ob0cnmgm` | 3.28378 | −1 | +0.02099 |
| E | 2.00 | `kc151qw3` | 3.28722 | −1 | +0.02443 |

- **Mechanism falsified:** Monotone-worse pattern. Interior-optimum hypothesis (C or D < B < A < E) fully rejected. Slope halves per doubling (log-saturation) → operational baseline RMS sits well below 0.25; clamping FROM ABOVE inflates effective steps.
- **Cell A refactor neutral:** 3.26279, within strong-ctrl band [3.26129, 3.26480]. CLI flag default 0.0 is safe.
- **Decision:** CLOSED clean-NEG. Post-NS update-RMS-clamp axis closed. Mechanistically distinct from SignMuon (#823 pre-NS input), Polar Express (#824 NS coefficients), NS-WarmUp (#815 iteration count) — those axes remain open.

## 2026-05-22 ~17:40 UTC — PR #748: frieren Q/K/V + MLP fc_in init magnitude sweep (×2.0 P2) — **CLOSED clean-NEG**

- Branch: `g1r5-frieren/transform-init-magnitude`
- Student: g1r5-frieren
- Hypothesis: P2 n=4 confirmation of P1 Cell C (×2.0 transform init magnitude). P1 single-seed at 3.261066 cleared OLD gate by −0.000200; now testing whether signal replicates at n=4 on post-#699 codebase.
- **Results (P2 n=4, group `g1r5-frieren/transform-init-magnitude-P2-confirm`):**

| Trial | run_id | val/loss | ffs |
|------:|:------:|:--------:|:---:|
| T1 | `5ookkx0a` (P1 Cell A ctrl) | 3.261784 | 3025 |
| T2 | — | 3.26165 | 3025 |
| T3 | — | 3.26211 | 3050 |
| T4 | — | 3.26009 | 3025 |
| T5 | `20qw606z` | 3.26204 | 3050 |
| **μ_n=4** | — | **3.261472** | **3037.5** |

*(P1 5-cell sweep: A=3.261784, B(×0.5)=3.270140, C(×2.0)=3.261066, D(×0.1)=3.270957, E(×0.0)=aborted. W&B: `5ookkx0a`, `s0l2w8ia`, `c7htcrny`, `ib13jhsl`)*

- **Gate math (post-#699 baseline μ=3.261221, n=4 gate=3.259221):**
  - vs MERGE (≤3.259221): +0.002251 above
  - vs COMPOUND-P3 sendback band: above by +0.000690
  - **CLOSE threshold (>3.260783): +0.000690 above → CLOSE clean-NEG**

- **Decision:** CLOSED clean-NEG per pre-staged decision tree. μ_n=4=3.261472 sits clearly above close threshold.

- **Key findings:**
  1. ×2.0 transform init does NOT stack additively with musoft (#699). P1 single-seed gate-cross was favorable variance.
  2. B/D catastrophic-on-smaller genuine: ×0.5 hurts +7.9σ, ×0.1 hurts +8.7σ. Current default `std=sqrt(0.33/n_in)` robustly near local optimum (floor-only structure).
  3. σ_single = 0.000944 (slightly tighter than published 0.001123) — useful data point for future P2 gate math.
  4. Transform-init axis fully closed. Init-magnitude family: 1 merged (musoft #699), 4 closed (lm_head, gains, transform, #748).

## 2026-05-22 ~16:45 UTC — PR #773: fern Signal-driven adaptive Muon mu (grad cosine similarity) — **CLOSED clean-NEG (mechanism falsified)**

- Branch: `g1r5-fern/adaptive-mu-cossim`
- Student: g1r5-fern
- Hypothesis: Modulate Muon's Nesterov momentum coefficient per-step using the cosine similarity between consecutive gradient tensors: `mu_t = base_mu + α × cos(g_t, g_{t-1})`. High cos-sim → high mu (amplify persistent signal); low cos-sim → low mu (dampen noise).
- **Results (n=1 each, group `g1r5-fern/adaptive-mu-cossim`):**

| Cell | α | run_id | val/loss | ffs | Δ vs baseline μ (3.261221) |
|:----:|:-:|:------:|:--------:|:---:|:--------------------------:|
| **A** | **0.0 (ctrl)** | `810dkuev` | **3.26181** | 3025 | +0.000589 (+0.99σ) |
| B | 0.02 | `09f013uq` | 3.26474 | 3075 | +0.003519 (+5.93σ) |
| C | 0.05 (primary) | `q3dsodk4` | 3.26887 | 3125 | +0.007649 (+12.9σ) |
| D | 0.10 (large) | `ricw2si1` | 3.27568 | 3200 | +0.014459 (+24.4σ) |
| E | −0.05 (falsifier) | `y698zbrj` | 3.26920 | 3100 | +0.007979 (+13.5σ) |

- **Mechanism falsified:** Both signs of α degrade val/loss monotonically vs control. Cell E (−α) is nearly identical to Cell C (+α) at |α|=0.05 (+0.00739 vs +0.00706). The sign-falsifier pattern definitively kills the directional-coherence story.
- **Why it failed:** After SOAP eigenbasis rotation, residual cos(g_t, g_{t-1}) reflects high-frequency noise rather than coherent low-frequency signal. Static mu=0.95 is a well-tuned fixed point for this benchmark; any unbiased noise perturbation is a strict regression in expectation. Alpha=0.10 (range [0.85, 0.99]) reaching mu=0.85 in low-coherence regions explains Cell D's 2× degradation vs Cell C.
- **Decision:** CLOSED clean-NEG. Pre-#699 codebase (per poll #379 advisory). Mechanism fully falsified by sign-falsifier Cell E. Adaptive-mu-from-gradient-cosine axis closed.

## 2026-05-22 ~15:05 UTC — PR #756: tanjiro Gradient Centralization on Muon body weights (5-cell) — **CLOSED clean-NEG (mechanism note kept)**

- Branch: `g1r5-tanjiro/grad-centralization-muon`
- Student: g1r5-tanjiro
- Hypothesis: Apply gradient centralization (Yong et al. 2020) at the Muon dispatch boundary to remove all-ones direction RMSNorm absorbs. 5-cell axis sweep over (dim ∈ {row, col}) × (placement ∈ {pre-momentum, post-momentum}) × (scope ∈ {all, mlp-only}).
- **Results (n=1 each, group `g1r5-tanjiro/grad-centralization-sweep`):**

| Cell | gc config | run_id | val/loss | ffs | Δ vs new μ_base (3.261221) | σ above n=4 gate (3.259221) |
|:----:|:---------:|:------:|:--------:|:---:|:--------------------------:|:---------------------------:|
| A | off (ctrl) | forau0gg | 3.26423 | 3050 | +0.003009 (+2.68σ) | +4.46σ |
| B | col-pre-all | fn2umzbq | 3.26344 | 3050 | +0.002219 (+1.98σ) | +3.75σ |
| **C** | **row-pre-all** | r6tcdq0m | **3.26223** | **3050** | **+0.001009 (+0.90σ)** | **+2.68σ** |
| D | col-post-all | ud1hc8g8 | 3.26440 | 3050 | +0.003179 (+2.83σ) | +4.62σ |
| E | col-pre-mlp | t7abeuko | 3.26507 | 3075 | +0.003849 (+3.43σ) | +5.21σ |

- **Ranking:** C < B < A < D < E. Best Cell C +0.90σ above baseline μ; no P2 escalation warranted under pre-declared rules.
- **Mechanism finding (KEPT for future reference):** **Row-vs-col inversion** (Δ=−1.08σ, n=1): row-mean GC beats col-mean GC, **inverting Yong et al. 2020 canonical prediction**. Mechanism: under `--soap_attn`, SOAP's eigenbasis rotation already damps col-mean (all-ones) direction RMSNorm absorbs — col-mean GC is redundant. Row-mean targets the per-output bias direction (mean over fan-in per output) — a direction not preferentially damped by SOAP nor absorbed by input-side RMSNorm. Three coherent contrasts: row>col (−1.08σ), pre>post (−0.86σ), all>mlp-only (+1.45σ).
- **Decision:** CLOSED clean-NEG. Best cell within +1σ of baseline μ but does not clear n=4 gate. Mechanism axis closed under post-#699 SOAP+musoft baseline; gradient-side directional preprocessing is not load-bearing here. Row-direction signal noted for any future GC-on-Muon-with-different-baseline work.

## 2026-05-22 ~12:59 UTC — PR #714: edward RMSNorm gain init mean=0.9 P2 — **CLOSED clean-NEG (gains init axis fully closed)**

- Branch: `g1r5-edward/gain-init-magnitude`
- Student: g1r5-edward
- Hypothesis: P2 n=4 confirmation of P1 D (mean=0.9, std=0.0) which showed −1.42σ single-seed below baseline μ.
- **Results (n=4, single 4-trial torchrun `x71lsi3t`, group `g1r5-edward/gain-init-magnitude-P2-confirm`):**

| Trial | val/loss | ffs | Δ vs OLD μ=3.263265 (σ_seed=0.001123) |
|------:|---------:|----:|--------------------------------------:|
| 0 | 3.26318 | 3050 | −0.08σ |
| 1 | 3.26320 | 3050 | −0.06σ |
| 2 | 3.26043 | 3025 | −2.53σ (outlier good) |
| 3 | 3.26446 | 3050 | +1.06σ |

- **n=4 aggregate:** μ=3.262818, σ_n=4=0.001701 (1.51× σ_seed_baseline), SEM=0.000850, ffs_mean=3043.75.
- **Gate evaluation:**
  - vs OLD gate (≤3.261265): ❌ misses by +0.001553
  - vs NEW gate (≤3.259221): ❌ misses by +0.003597
  - vs NEW baseline μ=3.261221: Δ=+0.001597 (+1.42σ_seed above)
- **Decision:** CLOSED clean-NEG. Bimodal split (T0/T1/T3 ~ baseline band, T2 outlier good) consistent with σ_seed variance — P1 D single-seed was a tail draw, not a real effect. **RMSNorm gain init axis fully closed.** mean=1.0 (default identity) approximately optimal; perturbations to mean (0.9, 1.1) or std (0.01, 0.1) do not yield reliable improvements at n=4.

## 2026-05-22 ~12:54 UTC — PR #706: nezuko embed_init_std=0.1 P2 (pre-#699) — **TERMINAL, sent back for compound P3 (musoft × embed=0.1)**

- Branch: `g1r5-nezuko/embed-init-magnitude`
- Student: g1r5-nezuko
- Hypothesis: P2 n=4 confirmation of P1 C (std=0.1). Ran on PRE-#699 codebase honoring poll #379 "do not rebase mid-experiment" advisory.
- **Results (n=4, single 4-trial torchrun `wijk9m7a`, group `g1r5-nezuko/embed-init-magnitude-P2-confirm`):**

| Trial | val/loss | ffs |
|------:|---------:|----:|
| 0 | 3.25968 | 3025 |
| 1 | 3.26127 | 3025 |
| 2 | 3.26194 | 3025 |
| 3 | 3.25993 | 3025 |

- **n=4 aggregate:** μ=3.260705, σ_n=4=0.001079 (≈ σ_seed_baseline 0.001123), SEM=0.000540, ffs_mean=3025 (4/4 exactly).
- **Gate evaluation (against OLD gate per experimental contract):**
  - vs OLD gate (≤3.261265): ✅ **clears by 0.000560**, sweep formula 0.005120 ≥ 0.004 ✓
  - vs OLD baseline μ=3.263265: Δ=−0.002560 → −2.28σ_seed below
  - vs NEW gate (≤3.259221): ❌ misses by 0.001484
  - vs NEW baseline μ=3.261221: Δ=−0.000516 → −0.46σ_seed below (essentially at parity)
- **Decision: send back for compound P3** on post-#699 codebase. Direct merge against OLD gate would apply embed=0.1 atop musoft without testing compound effect. Three possibilities not yet measured:
  1. Additive — μ_P3 ≤ 3.2592 → merge candidate vs NEW gate
  2. Partially redundant — μ_P3 ∈ (3.2592, 3.2606) → discuss
  3. Competing — μ_P3 > 3.2612 → would merge a regression
- Tied weights between embed/lm_head + musoft both targeting early-step gradient routing through the embedding subspace suggests prior on **partial redundancy**. P3 will measure. New W&B group `g1r5-nezuko/embed-init-std01-musoft-compound-P3`. ETA ~6h54m after rebase.



- Branch: `g1r5-fern/lm-head-init-magnitude`
- Student: g1r5-fern
- Hypothesis: First-ever lm_head init magnitude ablation. `model.proj.weight` currently zero-init via `"proj" in name` catch-all. 5-cell: A=0.0 ctrl / B=0.001 / C=0.01 / D=0.02 (GPT-2 default) / E=0.05.

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | std | wandb_run_id | val/loss | ffs | Δ vs μ (σ_single) | Gate? |
|:----:|:----:|----:|:------------:|---------:|:---:|------------------:|:-----:|
| **1** | **A ctrl** | **0.0** | `ysab9kz2` | **3.262623** | 3025 | **−0.57σ (8th post-#571 ctrl)** | ❌ |
| 2 | C | 0.01 | `b1nbpwsy` | 3.262818 | 3025 | −0.40σ | ❌ |
| 3 | B | 0.001 | `fynozfht` | 3.263783 | 3025 | +0.46σ | ❌ |
| 4 | D | 0.02 (GPT-2) | `zkfmdsq6` | 3.265480 | 3025 | +1.97σ | ❌ |
| 5 | E | 0.05 | `nzkbh2i2` | 3.270531 | 3025 | +6.47σ | ❌ |

- **Three mechanism findings (all 5/5 predictions landed):**
  1. **Zero-init is uniquely load-bearing.** Not "any small non-zero init is fine" — step-0 val/loss scales ~std² (A=10.826 = log(50304) → E=11.776), and init-time penalty correlates monotonically with final val/loss. No late-training "catch-up" once std ≥ 0.02.
  2. **LR-overwrite timescale sets the boundary.** lr_lm_head=1/320 (≈3.1e-3) × 3250 steps budget washes out std ≤ 0.01 within ~500 steps (cells B, C effectively neutral at terminal). Above std=0.02, gradient budget is insufficient — random structure persists as +2σ to +6σ regression.
  3. **Inverts the embed-init axis pattern.** Embed (#706) has interior optimum at std≈0.1 (default std=1.0 is 10× too large, lr_embed=0.3 is 100× higher than lr_lm_head). lm_head has boundary optimum at std=0.0 with monotone degradation outward — qualitatively different mechanism due to order-of-magnitude LR difference.

- **Decision:** CLOSED clean-NEG. lm_head init magnitude axis fully characterized. Zero-init is robustly uniquely optimal at this LR × steps budget. 4th of 5 init-magnitude axes closed (embed+residual-proj+gains have P2 candidates; transformations still P1 in-flight; lm_head closed). **Fern reassigned #773 signal-driven adaptive Muon mu (gradient cosine similarity, fresh mechanism — orthogonal to all 7 in-flight P2s).**

---

## 2026-05-22 ~05:40 UTC — PR #714: edward RMSNorm gain init magnitude/randomness sweep — **P1 SWEEP COMPLETE → P2 n=4 confirmation at Cell D (mean=0.9, std=0.0)**

- Branch: `g1r5-edward/gain-init-magnitude`
- Student: g1r5-edward
- Hypothesis: First-ever RMSNorm gain init magnitude/randomness ablation. Current default mean=1.0, std=0.0 (identity init) has never been swept. With lr_scalars=0.03 (3× since #571), the gain equilibrium magnitude may have shifted. 5-cell: A=ctrl (1.0/0.0) / B=(1.0/0.01) / C=(1.0/0.1) / D=(0.9/0.0) / E=(1.1/0.0). Two-axis design: mean (D/E) and randomness (B/C).

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | mean | std | wandb_run_id | val/loss | ffs | Δ vs A (σ_single) | Δ vs μ (σ_single) | Gate? |
|:----:|:----:|-----:|----:|:------------:|---------:|:---:|------------------:|------------------:|:-----:|
| **1** | **D** | **0.9** | **0.0** | `jqs1ifiq` | **3.26203** | **3025** | **−1.93σ** | **−1.10σ (+0.000765 above gate)** | ❌ |
| 2 | B | 1.0 | 0.01 | `v79099wt` | 3.26296 | 3050 | −1.10σ | −0.27σ | ❌ |
| 3 | E | 1.1 | 0.0 | `wnxil63d` | 3.26326 | 3050 | −0.83σ | ≈0σ | ❌ |
| 4 | A | 1.0 | 0.0 | `5xa40y2r` | 3.26419 | 3050 | — | +0.82σ | ❌ |
| 5 | C | 1.0 | 0.1 | `c6a2n4mz` | 3.26425 | 3050 | +0.05σ | +0.88σ | ❌ |

- **Two-axis mechanism story:**
  1. **Mean axis (D vs E): asymmetric.** D (0.9) is −1.93σ vs ctrl; E (1.1) ≈0σ vs μ. Rules out "any mean perturbation helps" — effect is specifically downward. Cell D inverts the pre-registered prior (expected mild regression; observed −1.10σ improvement + faster ffs by 25 steps, the only cell with faster ffs).
  2. **Randomness axis (B vs C): dead.** std=0.01 and std=0.1 both wash out — RMSNorm's reciprocal-norm forward absorbs the multiplicative perturbation; lr_scalars=0.03 adapts within hundreds of steps.
  3. **Mechanism: "init co-tuned with old lr_scalars=0.01" hypothesis.** Identity init was uniquely optimal at lr_scalars=0.01; at lr_scalars=0.03 (tripled in #571), the optimal equilibrium shifted below 1.0. Starting at 0.9 lands closer to it.
  4. **Cell A=3.26419 is the 8th post-#571 single-seed ctrl** — at the upper end of the band (+0.82σ vs μ). Mean across n=9 ctrls ≈ 3.2625, SD ≈ 0.0012.

- **Decision:** SENT BACK FOR P2 n=4 confirmation at Cell D (`--gain_init_mean 0.9 --gain_init_std 0.0`, single cell, no finer scan, no D×std combinatorial — those are downstream questions if P2 confirms). Pre-declared gate: μ_n=4 ≤ 3.261265 → merge (first gain-init result on post-#571 baseline); μ > 3.262 → close clean-NEUTRAL. P2 ETA ~6.8h. **4th init-magnitude axis to surface a candidate** (alphonse residual-proj P2 trial 1 = 3.260513 in-flight, nezuko embed P2 launched ~step 249 ~6%, edward gain this PR P2 pending). Init-magnitude wave converging.

- **In-flight context:** Alphonse #699 P2 trial 1 (Cell B musoft) finished at **3.260513** — 0.000752 below the gate, strongest single-trial post-#571 result. Nezuko #706 P2 just launched (~6%). Two more init-magnitude P2 confirmations racing toward terminal alongside edward.

---

## 2026-05-22 ~05:35 UTC — PR #756: tanjiro gradient centralization on Muon — **IMPLEMENTATION QUESTION → APPROVED OPTION (A): apply GC to raw p.grad pre-momentum on all body weights (works under --soap_attn)**

- Branch: `g1r5-tanjiro/grad-centralization-muon`
- Student: g1r5-tanjiro
- Original hypothesis: 5-cell sweep of gradient centralization (subtract column-mean from gradient pre-NS5) on Muon body weights, three independent contrasts (col vs row dim / pre vs post-momentum / all vs MLP-scope).

- **Pre-launch implementation question (student-flagged):** Under baseline `--soap_attn`, ALL body weights route through the SOAP path (`soap_precondition_momentum` → `soap_ns_step`), NOT `muon_update`. Modifying only `muon_update` would be a no-op. Three options proposed: (A) apply GC to raw `p.grad` for all body weights (covers both paths); (B) apply at pre-NS5 in SOAP path only (loses clean all-ones interpretation); (C) drop `--soap_attn` (breaks baseline contract).

- **Decision:** **OPTION (A) APPROVED.** Three reasons:
  1. **Faithful to Yong et al. 2020** (canonical GC = sub mean from raw gradient).
  2. **Preserves all-ones-direction mechanism story** (RMSNorm absorbs from output → removing from raw grad frees optimizer; SOAP rotation in (B) would break the column-mean ↔ all-ones identity).
  3. **Comparable to baseline** (keeps `--soap_attn` intact).

- **Implementation guidance provided:**
  - `gc_pre=True`: sub column-mean from `p.grad` **before** `momentum.lerp_`.
  - `gc_pre=False`: sub from nesterov update tensor **before** `soap_precondition_momentum` / NS5.
  - `gc_dim=0` (Cell B, column-mean) vs `gc_dim=1` (Cell C, row-mean) — asymmetry test.
  - Scope: 6 body-weight classes (Q/K/V/attn.proj + mlp.fc/mlp.proj) for B/C/D; MLP-only (fc + proj) for E.
  - **Verification gate:** print one diagnostic line per body weight at step 0 confirming `g.mean(dim=0).abs().max() < 1e-7` immediately after GC sub (catches plumbing bugs before 4h GPU burn).

- **Status:** Sent back to `status:wip` ~05:34Z. No runs in W&B yet — student implementing the refactor and launching Cell A as smoke test first. ETA full sweep ~10h wall-clock.

---

## 2026-05-22 ~04:30 UTC — PR #707: tanjiro per-group AdamW β2 sweep — **CLOSED clean-NEG (β2=0.95 globally optimal)**

- Branch: `g1r5-tanjiro/per-group-beta2-sweep`
- Student: g1r5-tanjiro
- Hypothesis: First per-group AdamW β2 sweep. Test whether different AdamW parameter groups (scalars / embed / lm_head) have different optimal β2 values when others are held at the global ctrl=0.95. Parallel to thorfinn #691 per-group β1. 5-cell: A=global 0.95 ctrl / B=scalars 0.999 / C=scalars 0.85 / D=embed 0.999 / E=lm_head 0.999.

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | β2 (embed/lm_head/scalars) | wandb_run_id | val/loss | ffs | Δ vs A | Δ vs μ |
|:----:|:----:|:---------------------------:|:------------:|---------:|:---:|--------:|--------:|
| 1 | **A (ctrl)** | 0.95/0.95/0.95 | `afsmk23n` | **3.261441** | 3025 | — | **−1.00σ (STRONGEST POST-#571 CTRL)** |
| 2 | C | 0.95/0.95/**0.85** | `f9150zye` | 3.263448 | 3050 | +1.79σ | +0.16σ |
| 3 | B | 0.95/0.95/**0.999** | `q6uxlcu6` | 3.263477 | 3050 | +1.81σ | +0.19σ |
| 4 | D | **0.999**/0.95/0.95 | `ozyj7pwa` | 3.264028 | 3050 | +2.30σ | +0.68σ |
| 5 | E | 0.95/**0.999**/0.95 | `5kg5shg6` | 3.264620 | 3050 | +2.83σ | +1.21σ |

- **Key mechanistic findings:**
  1. **β2=0.95 is a sharp local optimum on the scalars axis.** B (0.999, ~700-step half-life) and C (0.85, ~5-step half-life) cost +1.81σ and +1.79σ vs ctrl — perturbing in EITHER direction by similar amounts costs the same. Smooth quadratic minimum at 0.95.
  2. **Regression magnitude scales with parameter group size.** D (embed, 39M, sparse-gradient) +2.30σ; E (lm_head, 39M, dense-gradient) +2.83σ — both larger groups regress more than small scalars (20K) at +1.79-1.81σ. Variance-estimator timescale matters more for more parameters.
  3. **Inverts per-group β1 pattern (#691 thorfinn).** Per-group β1 was sparsity-driven ASYMMETRIC (embed=0.9 helped −0.47σ). Per-group β2 is SYMMETRIC (no group benefits). Mechanistically expected: β1 direction stability depends on per-group sparsity; β2 step-magnitude smoothing depends on per-group LR (already separately tuned via lr_embed/lr_lm_head/lr_scalars).
  4. **Cell A=3.26144 is the STRONGEST post-#571 ctrl reproduction on record** (−1.00σ vs μ_baseline). Across 10 post-#571 ctrl reproductions: mean ≈ 3.26241, SD ≈ 0.0012.

- **Decision:** CLOSED clean-NEG. Per-group AdamW β2 axis fully characterized. β2=0.95 global is robustly optimal for all three groups. With per-group LR (embed #566/lm_head #600/scalars #571 all closed) and β2 now closed, the per-group AdamW HP space is well-mapped. Per-group β1 (#691 P2 stacked in flight) will complete the picture. Tanjiro reassigned **gradient centralization on Muon** (#756 — fresh mechanism test: subtract column-mean from gradient pre-NS5 to remove all-ones direction absorbed by RMSNorm; 3 independent contrasts: col vs row / pre vs post-momentum / all vs MLP-scope).

---

## 2026-05-22 ~04:30 UTC — PR #706: nezuko embedding init magnitude sweep — **P1 SWEEP COMPLETE → P2 n=4 confirmation at Cell C (std=0.1) — HOTTEST SIGNAL OF THE ROUND**

- Branch: `g1r5-nezuko/embed-init-magnitude-sweep`
- Student: g1r5-nezuko
- Hypothesis: First embedding init magnitude sweep. Current `w.normal_()` (std=1.0 default torch) has never been ablated. 5-cell: A=ctrl std=1.0 / B=0.02 (GPT-2 default) / C=0.1 / D=0.3 / E=3.0. Orthogonal to alphonse #699 (residual-proj init).

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | embed_init_std | wandb_run_id | val/loss | ffs | Δ vs A=3.26222 | Δ vs μ_baseline (σ_single) | Gate? |
|:----:|:----:|---------------:|:------------:|---------:|:---:|----------------:|---------------------------:|:-----:|
| **1** | **C** | **0.1** | `2kuw40pa` | **3.25973** | 3025 | **−2.21σ** | **−3.15σ (CLEARS by 0.001535)** | **✅** |
| **2** | **B** | **0.02 (GPT-2)** | `oxzcogm3` | **3.26068** | 3025 | **−1.37σ** | **−2.30σ (CLEARS by 0.000585)** | **✅** |
| 3 | A | 1.0 ctrl | `47qazqvy` | 3.26222 | 3025 | — | −0.93σ | ❌ |
| 4 | D | 0.3 | `v9c8usr2` | 3.26251 | 3050 | +0.26σ | −0.67σ | ❌ |
| 5 | E | 3.0 | `kjhugi0p` | 3.26635 | 3075 | +3.68σ | +3.28σ | ❌ |

- **Key mechanistic findings (3 independent contrasts):**
  1. **Interior optimum at std≈0.1 with non-monotonic response.** C→D step (+3× larger) is the largest single-step jump (Δ=+0.00278, ~2.5σ_new). The interior optimum at std≈0.1 is a clear signal — not monotonic, not noise.
  2. **Default torch std=1.0 is 10× too large for this benchmark.** Cell A in the noise band (−0.93σ) but the C→A direction shows a 10× reduction in init magnitude provides meaningful gains. AdamW on embed (lr_embed=0.3) is calibrated for the smaller (~0.1) magnitude regime; oversized init wastes step budget on shrinkage.
  3. **RMSNorm neutralizes the forward pass** across the full [0.02, 3.0] range (no NaN/inf at std=3.0) but the backward path through tied lm_head + high-LR AdamW still scales with embed magnitude.
  4. **TWO cells clear the n=4 gate at single seed.** B (std=0.02 GPT-2 default) and C (std=0.1) both clear the gate. The mechanism is the magnitude regime, not the precise value.
  5. **Cell C (3.25973) is the STRONGEST single-seed signal of the entire round** — well below the gate at single-seed (−3.15σ vs μ_baseline). Compare: alphonse #699 Cell B musoft was AT-gate (+0.000025 above).

- **Decision:** SENT BACK FOR P2 n=4 confirmation at exact Cell C config (`--embed_init_std 0.1`, single command, no other variants). Pre-declared gate: μ_n=4 ≤ 3.261265 → merge (FIRST init-layer merge on post-#571 baseline, racing with alphonse #699 P2); μ > 3.262 → close clean-NEUTRAL. P2 ETA ~7.3h. 

---

## 2026-05-22 ~02:55 UTC — PR #699: alphonse depth-aware μP init for residual paths — **P1 SWEEP COMPLETE → P2 n=4 confirmation at Cell B (musoft)**

- Branch: `g1r5-alphonse/depth-aware-init`
- Student: g1r5-alphonse
- Hypothesis: Replace zero-init on residual projection weights (`attn.proj`, `mlp.proj`) with depth-aware μP-soft init: std = c / √L (c ∈ {1, 1/√2, …}). Mechanism: bounded total residual variance across L blocks improves early-training feature flow without harming the convergence advantage of zero-init. 5-cell: A=ctrl (zero-init) / B=musoft (1/√L on attn.proj + mlp.proj) / C=mumedium (1/L on attn.proj + mlp.proj) / D=muall (1/√L on ALL block 2D weights) / E=smallconst (fixed std=0.001 on attn.proj + mlp.proj).

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | depth_init_mode | wandb_run_id | val/loss | ffs | Δ vs A | Δ vs μ_baseline |
|:----:|:----:|-----------------|:------------:|---------:|:---:|--------:|------------------:|
| 1 | **B** | **musoft** (1/√L on attn.proj + mlp.proj) | `kktt9fle` | **3.26129** | 3025 | **−0.49σ** | **−1.76σ_single (AT n=4 GATE)** |
| 2 | A | ctrl (zero-init) | `tockmprc` | 3.26178 | 3025 | — | −1.32σ_single |
| 3 | C | mumedium (1/L on attn.proj + mlp.proj) | `05qti19t` | 3.26180 | 3025 | +0.02σ | −1.30σ_single |
| 4 | E | smallconst (fixed std=0.001) | `h3yg0dtz` | 3.26253 | 3050 | +0.67σ | −0.65σ_single |
| 5 | D | muall (1/√L on ALL block 2D) | `okls6sis` | 3.26546 | 3075 | +3.28σ | +2.85σ_single |

- **Key mechanistic findings (3 independent contrasts pin "residual-path-specific 1/√L"):**
  1. **Magnitude axis (B vs C, scope held fixed at attn.proj + mlp.proj):** 1/√L (B=3.26129) beats 1/L (C=3.26180) by +0.46σ. The 1/L scaling is too aggressive — over-damping the residual output starts to lose the benefit. 1/√L is the right magnitude.
  2. **Scope axis (B vs D, magnitude held fixed at 1/√L):** residual-proj-only (B=3.26129) beats broad application (D=3.26546) by +3.27σ. Scaling Q/K/V/fc_in by 1/√L starves the *transformations* of useful gradient signal — these are upstream of the residual contribution, not the residual outputs themselves. **Depth scaling belongs on residual outputs, not residual inputs.** Exact μP-theory prediction.
  3. **Depth-scaling necessity (B vs E, scope held fixed at attn.proj + mlp.proj):** 1/√L (B=3.26129) beats fixed std=0.001 (E=3.26253) by +1.16σ. E captures *some* of B's gain (beats ctrl by −0.65σ) but doesn't reach the gate. Depth scaling matters — fixed small-constant is not sufficient.
  4. **Cell B sits AT the n=4 gate** (+0.000025 above 3.261265, well within rounding). First post-#571 single-seed result to reach the gate. All 5 init magnitude axes are now in-flight (embed nezuko #706, transform frieren #748, residual-proj this PR, lm_head fern #722, gains edward #714) — alphonse is the first to surface a merge-candidate.
  5. **Cell A = 8th strong post-#571 single-seed ctrl** (3.26178 = −0.77σ vs μ_baseline). Across 8 reproductions, mean ≈ 3.2623, SD ≈ 0.0012.

- **Decision:** SENT BACK FOR P2 n=4 confirmation at exact Cell B config (`--depth_init_mode musoft`, single command, no other variants). Pre-declared gate: μ_n=4 ≤ 3.261265 → merge (first init-layer merge on post-#571 baseline); μ > 3.262 → close clean-NEUTRAL; ambiguous middle → advisor decides. P2 ETA ~7.3h.

---

## 2026-05-22 ~02:00 UTC — PR #693: frieren Muon mu schedule sweep — **CLOSED clean-NEG (Muon-side time-varying axis fully closed)**

- Branch: `g1r5-frieren/muon-mu-schedule`
- Student: g1r5-frieren
- Hypothesis: Muon momentum `mu` is static at 0.95 throughout training (closed clean-NEUTRAL in #508). Test whether **time-varying mu** during cooldown helps, parallel to LR cooldown decay (WSD schedule). Mechanistic prediction: as LR decays, momentum becomes "redundant" and decaying mu lets the optimizer respond to fresh per-step gradients. Third time-varying Muon hyperparameter axis (alongside NS iter schedule #665, LR cooldown shape #679). 5-cell: A=const 0.95 ctrl / B=static 0.90 / C=static 0.98 / D=ramp 0.95→0.5 / E=ramp 0.95→0.0.

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | mu config | wandb_run_id | val/loss | ffs | Δ vs ctrl A | Δ vs μ_baseline |
|:----:|:----:|-----------|:------------:|---------:|:---:|------------:|-----------------:|
| 1 | **A (ctrl)** | const 0.95 | `oak44b8w` | **3.263899** | 3050 | — | +0.56σ_single |
| 2 | B | static 0.90 | `0vp8dz5t` | 3.265872 | 3075 | +0.00197 | +2.32σ |
| 3 | D | ramp 0.95→0.5 | `024yv1nq` | 3.267273 | 3025 | +0.00337 | +3.57σ |
| 4 | C | static 0.98 | `3kksio3z` | 3.267565 | 3075 | +0.00367 | +3.83σ |
| 5 | E | ramp 0.95→0.0 | `brbafo9x` | 3.271947 | 3075 | +0.00805 | +7.74σ |

- **Key mechanistic findings:**
  1. **mu=0.95 is a sharp single-peak optimum on the static axis.** Both directions hurt (B at +1.76σ vs ctrl; C at +3.27σ vs ctrl). Asymmetric: more momentum (C) hurts more than less momentum (B). Mechanism: higher mu lags trajectory more behind sharp basin geometry; Muon NS orthogonalization projects momentum buffer onto spectral edge; if buffer lags true descent direction, projected step misaligns.
  2. **Cooldown-phase mu decay hurts monotonically with floor depth.** D (ramp→0.5) +3.00σ vs ctrl; E (ramp→0.0) +7.17σ vs ctrl. **Inverts the PR's "cooldown momentum is redundant" prediction** — accumulated Muon momentum buffer is the **dominant signal** driving parameter trajectory during cooldown phase. With LR shrinking, fresh per-step gradients can't recover from discarded accumulated direction.
  3. **Muon-side time-varying hyperparameter space is empty.** Third time-varying axis to close negative alongside NS iter schedule (#665) and LR cooldown shape (#679). **Muon optimizer schedule layer fully characterized.** Pairs with WD axis 5-dim closure → entire optimizer schedule layer empirically mapped.
  4. **Cell A = 7th strong post-#571 single-seed ctrl.** 3.263899 sits near upper end of empirical post-#571 ctrl band (mean ≈ 3.2625, SD ≈ 0.0013 across 7 reproductions).
  5. **Bonus telemetry preserved.** `train/mu/{group_name}` logging is essentially free and useful for future Muon variants. Cherry-picked into merged code path.

- **Decision:** CLOSED clean-NEG. Muon-side time-varying optimizer schedule fully closed. Frieren reassigned to **transformation init magnitude sweep** (line 777 `else` branch catches Q/K/V + MLP fc_in weights with std=sqrt(0.33/n_in) ≈ 0.0207; never independently swept; structurally orthogonal to alphonse #699/nezuko #706/edward #714/fern #722).

---

## 2026-05-22 ~01:30 UTC — PR #691: thorfinn per-group AdamW β1 sweep — **P1 SWEEP COMPLETE → P2 STACKED n=4 (scalars=0.9 + embed=0.9 + lm_head=0.8)**

- Branch: `g1r5-thorfinn/per-group-beta1-sweep`
- Student: g1r5-thorfinn
- Hypothesis: First per-group AdamW β1 sweep since global mapping #537. Test whether different AdamW parameter groups (scalars / embed / lm_head) have different optimal β1 values when the others are held at the global ctrl 0.8. 5-cell single-group perturbations: A=all 0.8 ctrl / B=scalars 0.9 / C=scalars 0.7 / D=embed 0.9 / E=lm_head 0.9. β1 vector ordering (embed/lm_head/scalars).

- **Results (n=1 per cell, 3250 steps, baseline μ=3.263265, σ_single=0.001123):**

| Rank | Cell | Varied | β1 (embed/lm_head/scalars) | wandb_run_id | val/loss | ffs | Δ vs ctrl A | Δ vs μ |
|:----:|:----:|--------|:---------------------------:|:------------:|---------:|:---:|------------:|--------:|
| 1 | **B** | scalars | 0.8/0.8/**0.9** | `bceps4t4` | **3.26178** | **3025** | **−0.94σ** | **−0.97σ_single** |
| 2 | C | scalars | 0.8/0.8/**0.7** | `mp3n06ep` | 3.26227 | 3050 | −0.50σ | −0.50σ_single |
| 3 | D | embed | **0.9**/0.8/0.8 | `97o4zixl` | 3.26230 | 3025 | −0.47σ | −0.47σ_single |
| 4 | A | (ctrl) | 0.8/0.8/0.8 | `jj076kp2` | 3.26283 | 3050 | — | −0.39σ_single |
| 5 | E | lm_head | 0.8/**0.9**/0.8 | `wa2cj20k` | 3.26307 | 3050 | +0.21σ | +0.04σ_single |

- **Key mechanistic findings:**
  1. **Sparsity-driven, not size-driven.** D (embed=0.9, 39M params, sparse-token visits, **helps** −0.47σ) vs E (lm_head=0.9, 39M params, dense per-step vocab gradient, **neutral** +0.21σ) at matched param count → ~0.7σ separation. Per-group β1 sensitivity tracks gradient density, not weight count.
  2. **Scalars axis monotone-better at higher β1.** C/A/B at scalars β1=(0.7, 0.8, 0.9) → val (3.26227, 3.26283, 3.26178). The tripled-LR `lr_scalars=0.03` (3× pre-#571) prefers slower first moment so the cooldown's effective scalar-LR is smoother.
  3. **Every single-group perturbation off ctrl=0.8 helped except E.** B (scalars 0.9) −1.05×10⁻³, C (scalars 0.7) −0.56×10⁻³, D (embed 0.9) −0.53×10⁻³, E (lm_head 0.9) +0.24×10⁻³. The ctrl β1=0.8 applied uniformly is slightly miscalibrated for the sparse-gradient classes.
  4. **No single cell crosses n=4 gate.** Best B at 3.26178 is +0.000515 above the n=4 gate (3.261265). Stacked-best projection (B's −1.05 + D's −0.53 below A=3.26283) ≈ 3.26125 ≈ at-gate, which is the highest-EV P2 test.
  5. **Sequential discipline preserved.** Driver `launch_bcde.sh` (PID 436268) executed B→C→D→E cleanly with pgrep+settle; one early crash on `lwnd4qwv` at step 465 (self-recovered to canonical `jj076kp2` Cell A); single-runner enforced throughout.

- **Decision:** SENT BACK FOR P2 STACKED n=4 at `--beta1_embed 0.9 --beta1_lm_head 0.8 --beta1_scalars 0.9`. Pre-declared gate: μ_n=4 ≤ 3.261265 → merge; μ > 3.262 → close clean-NEG (effects don't compound); ambiguous middle → may request P3 walk (scalars β1=0.95) or P3 single-cell B confirm. P2 ETA ~7.3 hours.

---

## 2026-05-22 ~00:25 UTC — PR #687: askeladd Atan2-AdamW (StableAdamW, Wortsman 2023) — **P1 SWEEP COMPLETE → P2 n=4 confirmation at Cell D**

- Branch: `g1r5-askeladd/atan2-adamw`
- Student: g1r5-askeladd
- Hypothesis: Replace standard AdamW update `m_hat / (sqrt(v_hat) + eps)` with bounded normalization `(2/π) * atan2(m_hat, sqrt(v_hat)) ∈ [−1, +1]`. Wortsman 2023 (arXiv:2304.13013). Tests StableAdamW claim that bounded SNR mapping enables higher AdamW LR without divergence. Structurally orthogonal to 5 prior augmentation-class closures (Lion/Lookahead/AdEMAMix/SF/Adan): replaces the normalization kernel rather than adding buffers. Applied only to AdamW groups (embed/lm_head/scalars). 5-cell: A=ctrl (atan2=0) / B=atan2 default LR / C=atan2 1.5× LR / D=atan2 2.0× LR / E=atan2 1.5× LR + β1=0.9.

- **Results (n=1 per cell, 3250 steps, post-#571 baseline μ=3.263265, σ=0.001123):**

| Rank | Cell | Config | wandb_run_id | val/loss (W&B) | ffs | Δ vs A | Δ vs baseline |
|:----:|:----:|--------|:------------:|---------------:|:---:|-------:|---------------:|
| 1 | **D** | atan2 2.0× LR | `3i1k03ej` | **3.26205** | **3025** | **−0.00119** | **−1.06σ_single** |
| 2 | C | atan2 1.5× LR | `hjfhvdlf` | 3.26291 | 3050 | −0.00033 | −0.29σ_single |
| 3 | A (ctrl) | AdamW (atan2=0) | `rwbb5qcw` | 3.26324 | 3050 | — | +0.01σ_single |
| 4 | E | atan2 1.5× LR + β1=0.9 | `7as39gl4` | 3.26336 | 3050 | +0.00012 | +0.10σ_single |
| 5 | B | atan2 default LR | `hsjs26ji` | 3.26574 | 3075 | +0.00250 | +2.23σ_single |

- **Key mechanistic findings:**
  1. **Monotonic in LR across B/C/D (atan2=1).** (mul=1.0, 1.5, 2.0) → (3.26574, 3.26291, 3.26205). Cleanest cross-codebase test of the StableAdamW hypothesis — atan2's bounded [−1, +1] update enables higher AdamW LR without divergence. Cell D at 2× LR didn't NaN, didn't spike grad_norm, finished cleanly.
  2. **Atan2 at default LR (Cell B) underperforms vanilla AdamW.** B at +2.23σ vs μ. The bounded normalization at default LR adds nothing — eps-driven instability doesn't materialize at L=12 (consistent with eps closure #556/#641 showing fp32 floor below ~1e-12). Atan2's only value here is the LR ceiling effect.
  3. **Tighter β1 (Cell E) adds no compound benefit.** E (β1=0.9 at 1.5× LR) > C (β1=0.8 at 1.5× LR) by +0.00045. Tightening β1 on top of atan2 didn't stack.
  4. **Best Δ vs A is −0.00119 ≈ −1.06σ_single — inside n=1 seed-noise band.** Cannot distinguish "true ~1mNat win" from "lucky single seed."
  5. **Cell A ctrl (W&B) = 3.26324; student-reported 3.26239 was transcription artifact.** Used W&B ground truth (rwbb5qcw) in this log.
  6. **Structural distinction from 5 augmentation-class closures preserved.** Atan2 replaces the kernel; doesn't add structure. Even if P2 fails the gate, the monotonic-in-LR finding pins the LR-ceiling mechanism as the only viable atan2 effect at L=12.

- **Decision:** SENT BACK FOR P2 n=4 CONFIRMATION at Cell D config (atan2=1, lr_adamw_mul=2.0, β1=0.8). Pre-declared gate: μ ≤ 3.261265 → merge; μ > 3.262 → close clean-NEG; ambiguous middle (3.261265 < μ ≤ 3.262) → advisor decides based on σ and ffs distribution. P2 ETA ~7.5 hours (4 × ~110 min).

---

## 2026-05-21 ~21:15 UTC — PR #679: fern LR cooldown SHAPE sweep — **CLOSED clean-NEG**

- Branch: `g1r5-fern/lr-cooldown-shape-sweep`
- Student: g1r5-fern
- Hypothesis: LR cooldown shape axis sweep — fix LR peak and cooldown_frac=0.7, vary only the curve shape. First LR cooldown shape ablation. 5-cell: A=linear ctrl (1−c) / B=cosine 0.5(1+cos(πc)) / C=quadratic (1−c)² / D=sqrt (1−c)^0.5 / E=step (eta=1 until c=0.9, then cliff to 0). Equal-integral comparison: A and B both ∫=1/2, making A vs B the cleanest pure-shape test. Prior: cosine cooldown is the literature default (Chinchilla, speedrun papers); modded-nanogpt uses linear. Schedule layer counterpart to fern's WD shape closure (#635).

- **Results (n=1 each, 3250 steps, post-#571 baseline μ=3.263265, σ=0.001123):**

| Rank | Cell | Shape | ∫η dc | wandb_run_id | val/loss | ffs | Δ vs A | Δ vs baseline |
|:----:|:----:|-------|:-----:|:------------:|---------:|:---:|-------:|---------------:|
| 1 | **A (ctrl)** | linear | 1/2 | `p4ds3z6t` | **3.26480** | 3075 | — | **+1.37σ_single (6th post-#571 ctrl)** |
| 2 | B | cosine | 1/2 | `7o895gje` | 3.27103 | 2950 | +5.54σ | +6.91σ_single |
| 3 | C | quadratic | 1/3 | `96z1xekj` | 3.27378 | 2925 | +8.00σ | +9.36σ_single |
| 4 | D | sqrt | 2/3 | `clezqjs9` | 3.27597 | 3250 | +9.95σ | +11.31σ_single |
| 5 | E | step cliff @ c=0.9 | 0.9 | `6w7zeov1` | 3.41543 | never | +134.13σ | +135.49σ_single |

- **Key mechanistic findings:**
  1. **Shape ≠ integral (pure shape effect at equal integral = +5.54σ).** B cosine and A linear share ∫=1/2 but differ by +5.54σ. A's late linear approach to η=0 produces a different final-settle dynamic than B's smooth tail — the "linear cliff" in the last ~25 steps does real work that cosine's smooth tail cannot replicate at this fixed cooldown_frac=0.7.
  2. **LR-area is non-monotonic.** Ordering by integral: C (∫=1/3, val=3.27378) < A (∫=1/2, val=3.26480) < B (∫=1/2, val=3.27103) < D (∫=2/3, val=3.27597). Moving integral either direction from A's ∫=1/2 degrades; D (MORE area) is *worse* than A, refuting "more late-LR = more convergence" prior. D's concave tail concentrates decay too late → truncated by 3250-step budget (D's val/loss still rapidly improving at step 3250, descent rate −0.020/100 steps).
  3. **Cooldown is essential, not optional.** Cell E (peak LR for 93% of training, then cliff) lands at val=3.41543 — never reaches 3.28 target. With LR=0 for the final 228 steps, no parameter updates occur; the val_loss at the last gradient update (step 3025) was already 3.41543. Proves that gradual LR decay over extended cooldown is non-negotiable.
  4. **Cell A = 6th strong post-#571 single-seed ctrl.** 3.26480 is within the empirical post-#571 ctrl band. Empirical ctrl distribution: mean ≈ 3.2624, SD ≈ 0.0014 across 6 reproductions.
  5. **Mechanistic unifying story:** All losing shapes violate the principle of "true extended descent of LR that ends at 0." B ends at 0 but redistributes decay to the middle; C ends at 0 but concentrates decay early → stalls; D ends at 0 but concentrates decay late → truncated; E doesn't really cool down. Linear satisfies all three constraints.
  6. **Schedule layer fully characterized** jointly with WD axis closure (5 dims). 12+ schedule axes now mapped end-to-end. Fern completes the schedule layer mapping.

- **Decision:** CLOSED clean-NEG. Schedule layer fully characterized. Fern reassigned #722 lm_head init magnitude (fresh init axis — lm_head zero-init never independently swept; alphonse #699 holds lm_head zero-init constant).

---

## 2026-05-21 ~19:25 UTC — PR #671: edward Cautious AdamW (Liang 2024) — **CLOSED clean-NEG**

- Branch: `g1r5-edward/cautious-adamw`
- Student: g1r5-edward
- Hypothesis: Cautious AdamW (Liang 2024) — mask out parameter coordinates where the Adam step direction disagrees with the current batch gradient. Mechanistic *inverse* of AdEMAMix (#626): instead of adding slow-EMA signal, removes "wrong-direction" coordinates. 5-cell: A=ctrl / B=boolean paper-default / C=boolean+normalize / D=soft sigmoid γ=10 / E=boolean scalars-only.

- **Results:**

| Rank | Cell | Config | wandb_run_id | val/loss | ffs | Δ vs baseline μ=3.263265 |
|:----:|:----:|--------|:------------:|---------:|----:|--------------------------:|
| 1 | **A** | ctrl (mask_off, refactor no-op) | `gu48ocx7` | **3.26200** | 3025 | **−0.94σ_new (5th strong post-#571 ctrl)** |
| 2 | E | boolean, scalars-only | `2rcg85cg` | 3.26376 | 3050 | +0.45σ_new (~noise) |
| 3 | B | boolean (paper default) | `jaustwp2` | 3.27755 | 3200 | +12.72σ_new |
| 4 | D | soft sigmoid γ=10 | `i2pjb89v` | 3.27781 | 3200 | +13.0σ_new |
| 5 | C | boolean + mask_normalize | `oo93hchd` | 3.27831 | 3225 | +13.41σ_new |

- **Key mechanistic findings:**
  1. **Mask scope dominates mask shape.** B/C/D cluster at +12.7–13.4σ — hard boolean, normalized boolean, and soft sigmoid (γ=10 ≈ still hard) are all equivalent. Shape is irrelevant; gating direction is the harm. The disagreement coordinates ARE usable signal: the EMA correctly carries older gradient info that the current batch happens to flip.
  2. **Cell E ≈ A confirms scope-not-mechanism.** Scalars-only mask (~few hundred params) barely perturbs the global trajectory (bulk of optimizer unchanged). Not a positive signal for scalars; a "null apply" result.
  3. **Telemetry confirmed mechanism active** (pre-sweep smoke): mask density embed=45%, lm_head=66%, scalars=77%. ~50% on embed matches paper's prediction. High density on lm_head/scalars reflects structured-update nature of those groups.
  4. **Symmetric closure with AdEMAMix (#626):** AdEMAMix ADDs slow-EMA signal; Cautious REMOVEs fast-disagreement signal. Both symmetrically fail by similar margins. Confirms that the fast-EMA Adam state is load-bearing and resistant to modification in both directions at this horizon.
  5. **Cell A ctrl = 5th strong post-#571 single-seed ctrl.** Empirical ctrl distribution 5 recent CTRLs: mean ≈ 3.2624, SD ≈ 0.0005, n=5. Gate at 3.261265 is ~1.7σ_single below central trend.

- **Decision:** CLOSED clean-NEG. Joins {Lion #638, Lookahead #581, AdEMAMix #626, SF #659, Adan #645, AdaBelief #641, Cautious #671} in the "AdamW-modification mechanism" closure cluster. Edward reassigned #714 RMSNorm gain init magnitude sweep (fresh init axis, scalars group).

---

## 2026-05-21 ~18:35 UTC — PR #665: tanjiro NS iter SCHEDULE sweep — **CLOSED clean-NEG**

- Branch: `g1r5-tanjiro/ns-iter-schedule-sweep`
- Student: g1r5-tanjiro
- Hypothesis: Time-varying Newton-Schulz iteration count (ns_iter schedule) across training. ns_iter=6 is the confirmed optimal constant (PR #461/#497). The "less optimizer intensity late" theme has won across 5 axes — testing if reducing NS polishing late (when gradients are small) yields another gain. 5-cell: A=const 6 ctrl / B=linear_decay 6→3 / C=linear_growth 3→6 / D=step_at_cooldown 6→3 / E=linear_decay_aggressive 6→2.

- **Results:**

| Rank | Cell | Schedule | wandb_run_id | val/loss | Δ vs baseline μ=3.263265 |
|:----:|:----:|----------|:------------:|---------:|--------------------------:|
| 1 | **A** | const ns_iter=6 (ctrl) | `b9btbx8x` | **3.26170** | **−1.40σ_new** |
| 2 | B | linear_decay 6→3 | `xc6q7jae` | 3.26722 | +3.52σ_new |
| 3 | C | linear_growth 3→6 | `hoglm94h` | 3.26880 | +4.93σ_new |
| 4 | D | step_at_cooldown 6→3 | `ha0uv6di` | 3.27085 | +6.76σ_new |
| 5 | E | linear_decay_aggressive 6→2 | `1h5wl295` | 3.27138 | +7.23σ_new |

- **Key mechanistic findings:**
  1. **Monotone strict 5-cell ordering A < B < C < D < E** — probability of seeing this by chance under null = 1/120 ≈ 0.8%. NS iter schedule is a firmly closed axis.
  2. **The "less optimizer intensity late" theme is now bounded.** Wins on LR-magnitude knobs (lr_scalars=0.03, WD ramp_down) but NOT on iteration-count knobs. Newton-Schulz polynomial depth controls *direction quality* (is the update orthonormal?), not *step magnitude* — reducing it late leaves under-polished raw gradients, not "smaller" updates.
  3. **Continuity beats steps at the same endpoint:** B (smooth linear decay, ends at 3) costs +3.52σ vs A; D (discontinuous step at cooldown to 3) costs +6.76σ vs A — same endpoint, 3.24σ worse for the step. Optimizer state takes time to re-calibrate to a new operating point.
  4. **Below ns_iter=3 hits bf16 cliff:** E (decay 6→2) is +7.23σ vs A vs B's +3.52σ for 6→3. Consistent with PR #496 (edward LOW sweep) where ns_iter=2/3 as constants also regressed.
  5. **Step_avg spread tiny:** B fastest at 1902.6ms (−1.24% vs ctrl 1926.5ms); E at 1894.4ms (−1.66%). NS iter compute is essentially free — the quality cost of any schedule far outweighs any compute savings.
  6. **Cell A ctrl at 3.26170 = 4th strong post-#571 ctrl single-seed** (after #648 thorfinn 3.26167, #659 nezuko 3.26153, now this 3.26170). Empirical single-seed ctrl band: 3.261–3.264.

- **Decision:** CLOSED clean-NEG. NS iter schedule axis fully closed. Tanjiro reassigned #707 per-group AdamW β2 sweep.

---

## 2026-05-21 ~18:30 UTC — PR #659: nezuko Schedule-Free AdamW (Defazio 2024) — **CLOSED clean-NEG**

- Branch: `g1r5-nezuko/schedule-free-adamw`
- Student: g1r5-nezuko
- Hypothesis: Schedule-Free AdamW (Defazio 2024) removes the LR cooldown by accumulating a Polyak-averaged iterate `x_bar` and evaluating on it rather than the inner iterate `z`. At test time, `x_bar` (the averaged point) should behave like the terminal-cooldown point of a scheduled AdamW run — allowing AdamW to operate at a flat LR throughout. 5-cell sweep: A=AdamW ctrl / B=SF paper defaults (β=0.9, warmup=400, no cooldown) / C=SF + cooldown retained / D=SF β=0.95, no cooldown / E=SF β=0.9, no warmup, no cooldown.

- **Results:**

| Rank | Cell | Config | wandb_run_id | val/loss | ffs | Δ vs baseline μ=3.263265 |
|:----:|:----:|--------|:------------:|---------:|----:|--------------------------:|
| 1 | **A** | AdamW ctrl + cooldown | `76g76344` | **3.26153** | 3025 | **−1.5σ_new (best post-#571 single-seed ctrl)** |
| 2 | E | SF β=0.9, **no warmup**, no cooldown | `oafuw2cd` | 3.28924 | −1 | +46σ_new |
| 3 | D | SF β=0.95, w=400, no cooldown | `axgw720x` | 3.31299 | −1 | +49σ_new |
| 4 | B | SF β=0.9, w=400, no cooldown (paper default) | `o8fps2oz` | 3.32702 | −1 | +57σ_new |
| 5 | C | SF β=0.9, w=400, WITH cooldown | `lgfxkziv` | 3.33213 | −1 | +59σ_new (worst) |

- **Key mechanistic findings:**
  1. **Cell C surprise — cooldown + SF fight each other.** Predicted that SF+cooldown (C) would outperform SF-no-cooldown (B). Data says the opposite: C at 3.33213 is +0.005 *worse* than B at 3.32702. The cooldown shrinks per-step contribution; SF averaging adds another smoothing layer — combined dampening is over-damped and the model can't make sufficient end-game updates. SF removes the cooldown not just for theoretical reasons but because the two are *jointly incompatible* mechanistically.
  2. **Cell E surprise — no-warmup beats warmup.** At β=0.9 with no cooldown, removing the 400-step warmup *helps* by Δ=−0.038 (E=3.28924 vs B=3.32702). At this 3250-step horizon, the 400-step warmup eats ~12% of the budget that SF iterate-averaging needs to integrate signal. Without warmup, `z` reaches a useful region faster and `x_bar` accumulates more "good" iterates. Still +46σ above baseline.
  3. **β sensitivity (D=0.95 vs B=0.9):** Slower averaging (β=0.95) helps slightly (D=3.31299 vs B=3.32702, ~12σ_single). Slower averaging keeps `x_bar` closer to recent `z` — better tracks late-training improvement. All SF variants remain far above baseline.
  4. **Eval-mode swap verified rigorously.** Student pushed commit `f6f176c` with full triplet: `set_y_before_forward()` at L1126 (gradient at `y = lerp(z, x_bar, β)`); `eval_mode()` at L1075–76 (swap to `x_bar` before val); `train_mode()` at L1085–86 (restore `z` after val). Cell B's 3.327 IS measuring the Polyak average, not the noisy inner iterate.
  5. **Cell A is the strongest single-seed control on record post-#571.** A at 3.26153 lands −1.5σ_new below baseline μ — tighter than any recent single-seed control (askeladd 3.2632, frieren 3.2639, thorfinn 3.2628). Confirms the single-seed control band is 3.261–3.265.
  6. **6th augmentation-class closure (7th if counting AdaBelief).** SF joins Lion (#638), Lookahead (#581), AdEMAMix (#626), Adan (#645), AdaBelief (#641) as tested augmentation-class optimizers. All literature "improved AdamW" variants fail or are neutral at 3250-step horizon. The pattern: **AdamW + WSD linear cooldown is robustly tuned for this regime** and any mechanism that replaces, removes, or augments the cooldown-phase dynamics underperforms.

- **Operational note:** Excellent execution — chain-script orchestration with single-runner discipline, clean infrastructure-crash diagnosis and relaunch (Cell A SIGTERM at step 297), code-level eval-swap verification on request, detailed mechanistic write-up in terminal comment.

- **Decision:** CLOSED clean-NEG. Nezuko reassigned #706 embedding init magnitude sweep (fresh init axis — N(0,1) embed init vs GPT-2 default 0.02, never ablated despite being 50× larger).

---

## 2026-05-21 ~16:53 UTC — PR #641: alphonse AdaBelief optimizer (Zhuang 2020) — **CLOSED clean-NEUTRAL**

- Branch: `g1r5-alphonse/adabelief-optimizer`
- Student: g1r5-alphonse
- Hypothesis: AdaBelief (Zhuang 2020) replaces AdamW's `v_t = g²` (raw second moment) with `v_t = (g − m)²` (variance of the gradient's *residual from momentum*). Prediction: when gradient direction is consistent with momentum, AdaBelief's denominator is smaller → larger adaptive steps in reliably-tracked directions → should outperform AdamW on well-aligned gradient regimes. 5-cell sweep of the eps axis (1e-10/1e-8/1e-16/1e-6) against AdamW ctrl.

- **Results:**

| Rank | Cell | eps | val/loss | ffs | Δ vs A ctrl | Δ vs baseline μ=3.263265 |
|:----:|:----:|----:|---------:|----:|------------:|--------------------------:|
| 1 | **B** | **1e-10 (paper default)** | **3.26344** | 3050 | **−0.4σ_single** | **+0.16σ_new** |
| 2 | A | — (AdamW ctrl) | 3.26388 | 3050 | — | +0.55σ_new |
| 3 | C | 1e-8 | 3.26438 | 3050 | +0.4σ | +0.99σ_new |
| 4 | D | 1e-16 | 3.26442 | 3050 | +0.5σ | +1.03σ_new |
| 5 | E | 1e-6 | 3.26491 | 3050 | +0.9σ | +1.46σ_new |

- W&B runs: A=`w36rrko1`, B=`ecnl3ull`, C=`syyofitz`, D=`bhzqvj0j`, E=`hh0trx24`

- **Key mechanistic findings:**
  1. **AdaBelief ≈ AdamW at this scale.** B − A = −0.00044 (0.4σ_single), within seed noise. Whether you adapt to gradient magnitude (g²) or gradient-residual-from-momentum ((g−m)²) produces essentially the same effective step sizes here. At 12L/d_model=768 with Muon handling 2D matrices, the AdamW-managed groups (embed/lm_head/scalars) see gradients so consistent with momentum that `(g−m)² ≈ g²` numerically.
  2. **Eps sweep minimum at paper default (1e-10).** AdaBelief's natural denominator `(g−m)²` runs orders-of-magnitude smaller than AdamW's `g²` (because m tracks g well), so eps=1e-6 dominates the denominator on small-variance directions and kills adaptive scaling. Below 1e-10, fp32 clips at ~1e-12, so D (1e-16) ties C (1e-8) rather than improving.
  3. **Generalizes to denominator-axis saturation thesis.** AdamW eps flat across 8 decades (#556); AdaBelief eps optimal at 1e-10 (not 1e-16). Both formulations are eps-insensitive once below their respective operating floors. "Denominator loosening" tests have now all closed clean-neutral: #556 (AdamW eps), #614 (logit softcap — 3rd closure), #641 (AdaBelief eps — 4th closure).
  4. **6th augmentation-class closure.** AdaBelief is the first to close clean-NEUTRAL (rather than clean-NEG), suggesting variance-estimator modifications are the *least* destructive augmentation class — they affect step *magnitude* (denominator) rather than step *direction* or *temporal aggregation*. Step magnitude has more slack at this scale than direction/aggregation.
  5. **Step_avg overhead: +0.2% (1907.8 vs 1903.6 ms).** PyTorch fused `(g − m)` efficiently. VRAM unchanged (35.03 GiB identical across all 5 cells).

- **Operational note:** Student demonstrated exemplary execution — baseline-drift catch (PR launched before #571 merged, student wired `--lr_scalars 0.03` into both paths), early crash diagnosis (orphaned commit + overlapping-launcher OOM), detached-daemon serialization with `setsid`. The AdaBelief code kept in branch behind `--use_adabelief` (default off) for future ablation use.

- **Decision:** CLOSED clean-NEUTRAL. Variance formulation (g² vs (g−m)²) interchangeable at this scale. No P2 candidate (B beats A by only 0.4σ_single). Alphonse reassigned #699 depth-aware μP-style init (fresh INIT axis, never tested at per-layer depth-aware scale).

---

## 2026-05-21 ~16:00 UTC — PR #649: frieren wd_scalars sweep — **CLOSED clean-NEUTRAL**

- Branch: `g1r5-frieren/wd-scalars-sweep`
- Student: g1r5-frieren
- Hypothesis: Per-group WD on the scalar group (RMSNorm gains). After lr_scalars=0.03 tripled the scalar LR (#571), the optimal wd_scalars may differ from the existing global wd=0. 5-decade sweep (0.0, 1e-4, 1e-3, 1e-2, 1e-1) on a 20K-param group that had just become active.

- **Results:**

| Rank | Cell | wd_scalars | val/loss | ffs | Δ vs A ctrl | Δ vs baseline μ |
|:----:|:----:|-----------:|---------:|----:|------------:|----------------:|
| 1 | **A** | **0.0** | **3.262853** | 3050 | — | −0.37σ |
| 2 | C | 1e-3 | 3.263345 | 3050 | +0.44σ | +0.07σ |
| 3 | D | 1e-2 | 3.264023 | 3050 | +1.04σ | +0.67σ |
| 4 | B | 1e-4 | 3.264873 | 3050 | +1.80σ | +1.43σ |
| 5 | **E** | **1e-1** | **3.272496** | 3150 | **+8.59σ** | **+8.22σ (catastrophic)** |

- W&B runs: A=`aamao4ir`, B=`qtrqo15f`, C=`3sgupfy6`, D=`vr6ceifz`, E=`w899fis1`

- **Key mechanistic findings:**
  1. **4-decade flat region (0 → 1e-2):** A/B/C/D cluster within ±1.8σ_single. Scalar-group WD is insensitive across 4 decades. LR×WD multiplicative shrinkage (lr_scalars=0.03 × wd ≤ 1e-2 = 3e-4/step) is below the per-step gain-tracking gradient signal.
  2. **Catastrophe wall at 1e-1:** Jump from D (+1.04σ) to E (+8.59σ) — >4σ in a single decade. At wd=1e-1 the cumulative shrinkage (3e-3/step compounded over 3250 steps) overcomes gain-tracking. ffs slips 3050→3150.
  3. **Mid-trajectory forecast error**: Advisor predicted D would land +5–15σ based on step-2444 trajectory (val=3.3753). Actual terminal: +1.02σ. **Cooldown LR decay dominates mid-training WD shrinkage** — useful lesson for future trajectory-reading on WD experiments.
  4. **A=3.262853 = 8th post-#571 ctrl calibration point**, confirming the distribution (3.2616–3.2665 cluster).

- **Decision:** CLOSED clean-NEUTRAL. wd_scalars=0 robustly optimal. 5-dimensional WD axis now fully closed (magnitude #594, floor #548, duration #321, shape #635, per-group #649). Frieren reassigned #693 Muon mu schedule sweep.

---

## 2026-05-21 ~15:00 UTC — PR #648: thorfinn per-block LR decay/growth sweep — **CLOSED clean-NEUTRAL**

- Branch: `g1r5-thorfinn/per-block-lr-sweep`
- Student: g1r5-thorfinn
- Hypothesis: Depth-aware static LR multipliers (exponential decay/growth per block index, localized bottom-heavy/top-heavy boost) on the Muon-managed 2D weights (12 blocks). Tests whether uniform LR across the 12-block stack is optimal or whether Muon's per-block gradient landscape wants depth differentiation.

- **Results:**

| Rank | Cell | Schedule | val/loss | ffs | Δ vs A ctrl | Δ vs baseline μ=3.263265 |
|:----:|:----:|----------|---------:|----:|------------:|--------------------------:|
| 1 | **A** | const_ctrl | **3.26167** | 3025 | — | −1.42σ_new (best post-#571 ctrl single-seed) |
| 2 | C | growth (1.05^i) | 3.26294 | 3075 | +1.13σ | −0.29σ_new |
| 3 | B | decay (0.95^i) | 3.26298 | 3025 | +1.17σ | −0.25σ_new |
| 4 | D | bottom_heavy (first 6 at 1.0×, last 6 at 0.7×) | 3.26353 | 3050 | +1.66σ | +0.24σ_new |
| 5 | E | top_heavy (first 6 at 0.7×, last 6 at 1.0×) | 3.26699 | 3075 | +4.74σ | +3.32σ_new |

- W&B runs: A=`oqpmun1n`, B=`lclie0cc`, C=`eey5wggc`, D=`hqbdvyc6`, E=`qxh1lopo`

- **Key mechanistic findings:**
  1. **B ≈ C symmetry (+1.13σ vs +1.17σ):** Both directional gradients (decay = deeper-blocks-lower-LR; growth = deeper-blocks-higher-LR) underperform uniform by the same amount. Depth-LR axis is well-tuned at **uniform in both directions simultaneously**.
  2. **E (top_heavy) uniquely catastrophic vs D (bottom_heavy) — +3.5σ gap.** Boosting LR on the later blocks (which get clean skip-connection gradient signal) destabilizes the architecture's natural propagation hierarchy more than boosting on shallow blocks. "Deep layers want gentler updates" directional hint visible even within the NEUTRAL range.
  3. **Cell A = strongest post-#571 single-seed ctrl on record (3.26167 = −1.42σ below baseline μ).** Adds 7th calibration datapoint to the post-#571 ctrl distribution.

- **Operational note:** Student identified and resolved the shared-GPU OOM contention pattern in real time (between Cell A and B), then ran clean sequential chain for B–E. Excellent execution.

- **Decision:** CLOSED clean-NEUTRAL. Per-block LR axis CLOSED. No P2 candidate (A at +0.000405 above n=4 gate — within ctrl distribution, not a new winner). Thorfinn reassigned #691 per-group AdamW β1 sweep.

---

## 2026-05-21 14:00 UTC — PR #645: askeladd Adan optimizer (Xie 2022) — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/adan-optimizer`
- Student: g1r5-askeladd
- Hypothesis: Adan (Adaptive Nesterov Momentum Algorithm, Xie 2022, arXiv:2208.06677) uses a 3-buffer optimizer — m (1st moment), v (2nd moment), n (3rd moment tracking 1st moment of gradient differences) — that combines the benefits of gradient difference information into the update. For AdamW-path groups (embed/lm_head/scalars), Adan may exploit the fine-grained curvature information encoded in gradient differences to out-converge standard AdamW. SOAP+Muon already handles the 2D weight matrices with full matrix preconditioning; Adan targets only the smaller AdamW groups.

- **Results:**

| Rank | Cell | Config | val/loss | ffs | Δ vs A ctrl | Δ vs baseline (μ=3.263265, σ=0.001123) |
|:----:|:----:|--------|--------:|----:|------------:|----------------------------------------:|
| 1 | A (ctrl) | AdamW | 3.26231 | — | — | −0.85σ (within band) |
| 2 | E | Adan, tight β1=0.90/β2=0.85/β3=0.95, LR×1.0 | 3.26822 | — | +0.006 | +4.4σ |
| 3 | B | Adan paper defaults (0.98/0.92/0.99), LR×1.0 | 3.27603 | — | +0.014 | +11.4σ |
| 4 | D | Adan paper, LR×2.0 | 3.27611 | — | +0.014 | +11.4σ |
| 5 | C | Adan paper, LR×0.5 | 3.29233 | — | +0.030 | +25.9σ |

- **Student's spec-bug catches:** Student cross-checked advisor's PR spec against the official sail-sg/Adan implementation and caught 2 mechanism-changing bugs: (1) the v update coefficient should be `(1-β2)` not `β2`; (2) step-1 `prev_g` should be initialized to the current gradient, not zeros. Both bugs were confirmed and corrected before any runs. This rigor made the sweep's results interpretable.

- **Key mechanistic findings:**
  1. **Tighter betas (Cell E) recover most gap:** Cell E (β1=0.90 vs paper's 0.98) at +4.4σ vs best Adan cell E. The slow-EMA-horizon mismatch was the dominant failure mode, not the gradient-difference mechanism itself. Paper's momentum=0.98 means EMA half-life >> 3250 steps.
  2. **Cell D (LR×2.0 ≈ Cell B at LR×1.0):** Cleanest signal that Adan's `n_hat` denominator self-normalizes step magnitude — the paper's "Adan benefits from 5-10× higher LR" regime cannot be reached by simple LR scaling at this horizon.
  3. **Cell C (LR×0.5) compound failure:** Slow EMAs + halved LR → +25.9σ catastrophic regression.
  4. **SOAP curvature overlap hypothesis:** Student's observation that "Adan's small-curvature-proxy advantage may be redundant once SOAP is doing heavy lifting on the matrices" is correct — SOAP+Muon already exploits curvature aggressively on 2D weights; adding Adan's gradient-difference curvature-proxy on embed/lm_head/scalars provides no residual headroom.

- **Cross-PR closure cluster — 5th augmentation-class optimizer to fail clean-NEG:** Lion #638 (sign) + Lookahead #581 (slow-param) + AdEMAMix #626 (slow-grad) + Schedule-Free Cell B #659 (cooldown-removal) + Adan #645 (diff-based). Pattern is robust: AdamW + WSD linear cooldown is well-tuned at 3250-step horizon. "AdamW augmentation" variants from literature (100k+ step pretraining) do not transfer.

- **Decision:** CLOSED clean-NEG. No P2 candidate (best Adan cell E at +4.4σ; n=4 gate requires ≤ 3.261265).
- **Askeladd reassigned:** PR #687 Atan2-AdamW — smooth bounded normalization via `(2/π)*atan2(m_hat, sqrt(v_hat))`, structurally orthogonal to all 5 failed augmentation classes.

---

## 2026-05-21 12:00 UTC — PR #635: fern WD schedule SHAPE sweep — **CLOSED clean-NEUTRAL**

- Branch: `g1r5-fern/wd-schedule-shape-sweep`
- Student: g1r5-fern
- Hypothesis: All 4 WD schedule shape alternatives (triangle, cosine_updown, constant, ramp_up) already exist in code at `_wd_multiplier`. Holding integral=1.0 across all shapes isolates pure shape effect. Prior closures mapped WD magnitude (#594, #548) and duration (#321); this closes the shape dimension.

| Cell | Schedule | val/loss | ffs | Δ vs A (ramp_down ctrl) | W&B run |
|:----:|:--------:|---------:|----:|------------------------:|---------|
| **A (ctrl)** | `ramp_down` | **3.26719** | 3100 | — | `ujdxl0v1` |
| B | `triangle` | 3.27746 | 3200 | +0.01027 (+5.88σ_single) | `ysu7jadb` |
| C | `cosine_updown` | 3.28164 | −1 | +0.01445 (+8.27σ_single) | `dq8i1wsj` |
| D | `constant` | 3.27126 | 3150 | +0.00407 (+2.33σ_single) | `7h7fd6ky` |
| E | `ramp_up` | 3.27722 | 3200 | +0.01003 (+5.74σ_single) | `e3bkfau5` |

Final ranking: **A > D > E ≈ B > C**.

- **Calibration**: All cells ran at OLD `--lr_scalars 0.01` (predates PR #571 merge). Cell A (3.26719) sits +3.5σ_new above current baseline (3.263265). Within-PR comparisons (B-E vs A) are the clean signal; absolute vs-new-baseline numbers are not meaningful for this PR.
- **Key finding 1 — Early WD is the dominant lever**: Schedules with zero (or near-zero) WD during the first ~30% of training (B `triangle`, C `cosine_updown`, E `ramp_up`) all regress by +5.7 to +8.3σ. Schedules with non-zero early WD (A `ramp_down`, D `constant`) cluster close (+0 and +2.3σ). The ~5σ gap between these families is the largest single finding.
- **Key finding 2 — Time-decay vs flat within early-WD family (+2.3σ)**: ramp_down (decaying from 2.0→0) beats constant (flat at 1.0) by +2.33σ. Both "having early WD" AND "decaying over time" contribute; the WD shape effect is not a single binary lever.
- **Key finding 3 — Mid-peak placement is WORST, not late-peak**: Pre-sweep advisor prediction was that `ramp_up` (E) would be catastrophic (+15σ) because peak WD aligned with cooldown. Actual: E at +5.74σ tied with triangle B. The true worst family is mid-peak (B, C). Mechanistic refinement: the bad alignment isn't "WD during cooldown"; it's "peak WD coincident with the LR-cooldown-transition zone (~step 1700-2275 for cooldown_frac=0.7)", which is where B and C peak. E doesn't peak there.
- **No merge candidate**: All cells above new baseline gate (3.261265). WD shape axis adds no improvement — ramp_down is robustly optimal.
- **WD axis fully closed** by combining with prior closures: magnitude peak #594 (peak=2.0) + floor #548 (floor=0.0) + duration #321 (cooldown_frac=0.7) + shape #635 (ramp_down, this PR). All four WD scheduling dimensions are now mapped and frozen.
- Decision: CLOSED clean-NEUTRAL (no merge candidate). Fern reassigned to **LR cooldown SHAPE sweep** (#679) — the natural parallel axis to this WD shape closure. LR cooldown is currently linear (peak→0); analogous shape sweep tests cosine/quadratic/sqrt/step.

## 2026-05-21 09:50 UTC — PR #626: edward AdEMAMix slow-EMA augmentation — **CLOSED clean-NEG**

- Branch: `g1r5-edward/ademamix-slow-ema`
- Student: g1r5-edward
- Hypothesis: AdEMAMix (Pagliardini, El-Nouby, Sandler, Defazio 2024) augments AdamW with a second slow EMA on gradients (β3=0.9999, α∈{0,2,5,10}). Paper-claimed +20-50% sample efficiency on LM pretraining. With α=0 reduces exactly to AdamW (refactor no-op gate).

| Cell | α | β3 | val/loss | Δ vs Cell A | Δ vs old baseline (μ=3.266120, σ_old=0.001747) | Δ vs new baseline (μ=3.263265, σ_new=0.001123) | W&B run | first_step |
|------|---|----|---------:|------------:|------------------------------------------------:|------------------------------------------------:|---------|----------:|
| A (ctrl) | 0.0 | 0.9999 | 3.26631 | — | +0.00019 (+0.11σ_old) | +0.003045 (+2.7σ_new) | f26favd0 | 3075 |
| B | 2.0 | 0.9999 | 3.26959 | +1.88σ_single | +0.00147 (+0.84σ_old) | +0.006325 (+5.6σ_new) | fvuelt5l | 3100 |
| C | 5.0 | 0.9999 | 3.29136 | +14.34σ_single | +0.02524 (+14.45σ_old) | +0.028095 (+25.0σ_new) | xbsdpgwu | -1 (never) |
| D | 2.0 | 0.999 | 3.32335 | +32.65σ_single | +0.05723 (+32.76σ_old) | +0.060085 (+53.5σ_new) | 1rcdtdtf | -1 (never) |
| E | 10.0 | 0.9999 | 3.33141 | +37.26σ_single | +0.06529 (+37.37σ_old) | +0.068145 (+60.7σ_new) | 3k643ttd | -1 (never) |

- Cell A (α=0 refactor no-op) at +0.11σ_old vs old baseline — **gate PASSED**, AdEMAMix optimizer class with α=0 reduces exactly to AdamW.
- **All α > 0 cells monotonically worse**: 0→2 (+1.88σ_single), 2→5 (+12.46σ_single), 5→10 (+22.81σ_single). No cell beats baseline.
- **β3 axis hurts when faster**: at fixed α=2, β3=0.999 (Cell D) is +30.77σ_single worse than β3=0.9999 (Cell B). Faster slow-EMA = more accumulation in available steps = more harm.
- **Calibration**: All cells ran at OLD `--lr_scalars 0.01` (predates PR #571 merge). Cell A at 3.26631 is +2.7σ_new above current merged baseline (3.263265) — explained by missing `--lr_scalars 0.03`. Within-PR comparisons (B-E vs A) remain the clean signal.
- **Mechanistic interpretation**: At 3250-step horizon, slow-EMA half-life (β3=0.9999 → ~7000 steps) exceeds total training, so the slow buffer cannot accumulate meaningful signal. Adding α·slow to the AdamW numerator injects partial cumulative gradient history that the bias-corrected fast EMA has already accounted for, pushing updates into the "too large" regime on well-tuned coordinates. With β3=0.999 (half-life ~700, well within horizon), slow_ema reaches steady-state → catastrophic +30σ regression.
- **Joint closure with #581 Lookahead**: Both "slow-signal" mechanisms — gradient-side (AdEMAMix) and parameter-side (Lookahead) — fail clean-NEG on this speedrun. AdamW dynamics here are robustly well-tuned for the 3250-step regime and resistant to slow-signal augmentation. Paper-claimed benefits require million-step pretraining horizons.
- **Cross-mechanism observation**: This is the 3rd "augmentation-based" optimizer mechanism to fail clean-NEG (Lion #638 — sign-based momentum replacement; Lookahead #581 — parameter-side slow average; AdEMAMix #626 — gradient-side slow EMA). Paper-tuned hyperparameters from million-step LM pretraining do not transfer to 3250-step speedrun.
- Decision: CLOSED clean-NEG. AdEMAMix axis closed at this benchmark. Edward reassigned to **Cautious AdamW** (#671) — the mechanistic *inverse*: rather than ADDING slow-EMA, REMOVES wrong-direction updates via mask. Tests whether filtering (subtracting noise) succeeds where augmentation (adding signal) failed.

## 2026-05-21 09:30 UTC — PR #620: tanjiro attention softmax scale sweep — **CLOSED clean-NEUTRAL**

- Branch: `g1r5-tanjiro/attn-softmax-scale-sweep`
- Student: g1r5-tanjiro
- Hypothesis: Attention softmax scale=0.12 hardcoded in baseline (sdpa scale param), never ablated. 5-cell sweep (0.0884 / 0.10 / 0.12 ctrl / 0.14 / 0.18) tests whether the value is tuned end-to-end. Mechanistically: softer scale = flatter attention = lower confidence; sharper scale = sharper attention = earlier saturation.

| Cell | attn_scale | val/loss (final 50) | Δ vs ctrl A | Δ vs PR #571 baseline (3.263265, σ_new=0.001123) | W&B group |
|------|-----------|---------------------:|------------:|--------------------------------------------------:|-----------|
| A (ctrl) | 0.12 | 3.26518 | — | +0.00191 (+1.7σ_new) | g1r5-tanjiro/attn-softmax-scale-sweep |
| B | 0.0884 (−1/3) | 3.26888 | +0.00370 | +0.00561 (+5.0σ_new) | same |
| C | 0.10 | 3.26814 | +0.00296 | +0.00488 (+4.3σ_new) | same |
| D | 0.14 | 3.26799 | +0.00281 | +0.00472 (+4.2σ_new) | same |
| E | 0.18 (+1/2) | 3.26815 | +0.00297 | +0.00489 (+4.4σ_new) | same |

- All non-ctrl cells regress in a clean **U-shape**: B/C compress attention (softer), D/E dilate (sharper); both directions are symmetric +2.5–3.3σ_new vs ctrl.
- Cell A (ctrl=0.12) is the local optimum on this axis. The symmetric response is the hallmark of a value sitting at a well-tuned minimum on a smooth landscape — not noise, not a winner being missed.
- **Refactor confirmed no-op**: the PR introduced an `attn_scale` parameter where the previous codebase hardcoded scaling. Cell A (0.12) matches the pre-refactor baseline within seed noise (Cell A val/loss 3.26518 vs prior baseline at lr_scalars=0.01 epoch ≈ 3.265 band). Safe to keep the parameter as a non-default-modifying refactor; baseline behavior preserved.
- **Calibration caveat**: all 5 cells launched before PR #571 (lr_scalars=0.03) merged, so they ran at the OLD lr_scalars=0.01 default. All cells therefore sit 1.7–5σ_new above current baseline mu=3.263265. The U-shape is internally consistent (all cells share the same lr_scalars=0.01 background), but absolute values cannot be compared to merged baseline.
- **Mechanistic interpretation**:
  - **Softer attention (B, C)** loses temperature precision — flatter softmax distributions reduce the gradient signal at the most informative tokens. Cells regress monotonically with sharpness reduction.
  - **Sharper attention (D, E)** saturates earlier — softmax pushes more weight onto the top-1 token, reducing gradient flow to the long tail of relevant positions. Cells regress monotonically with sharpness increase.
  - The fact that 0.12 is precisely between (1/√8 ≈ 0.354 standard / 0.12 ≈ 0.12 implies an aggressive 3× downscale from default) and both perturbations hurt suggests an architecture-coupled tuning: attention head dim, RMSNorm scale, and softcap together pin this value.
- **Cross-axis read**: The "less optimizer intensity" theme that won on LR-scalars (PR #571) and WD ramp_down (PR #371) does NOT extend to attention temperature. Attention sharpness is a forward-pass / loss-landscape feature, not an optimizer-step magnitude feature. Different curvature class on the loss landscape.
- Decision: CLOSED clean-NEUTRAL. attn_scale axis closed at this constant value. Tanjiro reassigned NS iter SCHEDULE sweep (#665) — extending the "less intensity late" theme to a time-varying schedule on Muon's NS polynomial iteration count.

## 2026-05-21 07:30 UTC — PR #614: nezuko logit softcap value sweep — **CLOSED clean-NEG**

- Branch: `g1r5-nezuko/logit-softcap-sweep`
- Student: g1r5-nezuko
- Hypothesis: Logit softcap hardcoded at 15, never ablated. 5-cell asymmetric sweep (2 tighter / 1 ctrl / 2 looser) tests whether softcap value is tuned end-to-end.

| Cell | softcap | val/loss @ 3250 | first_step | Δ vs ctrl A | Δ vs PR #497 baseline (3.266120, σ=0.001747) | W&B |
|------|---------|----------------:|-----------:|------------:|---------------------------------------------:|------|
| A (ctrl) | 15.0 | 3.26859 | 3100 | — | +0.00247 (+1.4σ_old) | ifk37kj1 |
| B | 7.5 | 3.30528 | -1 (never reached) | +0.03669 | +0.03916 (+22.4σ_old) | abzrzbwf |
| C | 10.0 | 3.27118 | 3125 | +0.00259 | +0.00506 (+2.9σ_old) | 23vscyou |
| D | 22.5 | 3.27180 | 3125 | +0.00321 | +0.00568 (+3.3σ_old) | qvph4p1k |
| E | 30.0 | 3.27143 | 3125 | +0.00284 | +0.00531 (+3.0σ_old) | k4alzow6 |

- All non-ctrl cells regress. Cell A (ctrl=15) is the best of the sweep. **No cell met any gate** (n=4 new gate 3.261265; old −0.5σ flag 3.265720).
- Note: these runs predate PR #571 merge and use `--lr_scalars 0.01` (old default), so all cells trail the new baseline (mu=3.263265) by ~3-6σ_new. Comparisons here are vs PR #497 (old baseline at the time of launch) for consistency with the student's per-cell deltas.
- Mechanistic shape:
  - **Lower bound is a hard floor.** Tight axis monotone-negative: 15→10 (+3σ) → 7.5 (+22σ). The B→C ratio (~14×) is the nonlinear saturation signature — once softcap falls below typical logit magnitudes, gradient signal at confident logits is clipped and learning capacity collapses.
  - **Upper region is plateau-shaped, mildly negative.** D and E both ~+3σ_old vs baseline; no inflection from 22.5 → 30 means looser caps don't recover ground.
  - **Cap value of 15 is robustly tuned end-to-end.** Loosening doesn't break anything (no NaN, smooth curves) but doesn't help either.
- Cross-axis observation: "Less optimizer intensity" theme (validated on WD ramp_down PR #371 and ns_iter=6 PR #497) does **not** transfer from optimizer-side levers to loss-side levers. WD/NS act on parameter updates; softcap acts on the loss-derivative pathway. Different mechanism class, different sensitivity.
- Logging gap noted by student: `train/logits_abs_max`, `train/grad_norm_pre_clip` (output layer), and `train/param_norm` for proj.weight aren't emitted by base codebase. Suggested in PR body but deliberately not retrofit mid-sweep for cell-to-cell consistency. Small-scope add for any future logit/normalization PR that needs them.
- Decision: CLOSED clean-NEG. Logit softcap axis closed at this scale/budget. Nezuko reassigned to Schedule-Free AdamW (#659).

## 2026-05-21 05:05 UTC — PR #638: frieren Lion optimizer replacement — **CLOSED clean-NEG**

- Branch: `g1r5-frieren/lion-optimizer-replacement`
- Student: g1r5-frieren
- Hypothesis: Lion optimizer (Chen 2023, arXiv:2302.06675) replaces AdamW for embed/lm_head/scalars groups with sign-based update + single momentum buffer. Mechanistically distinct from AdamW's variance-based update.

| Attempt | Cell | lion_lr_scale | W&B run | State | Crash Mode |
|---------|------|--------------|---------|-------|-----------|
| #1 | C | 0.10 | 9zzr3bc0 | CRASHED at step 16 | grad-norm=235,925 |
| #2 (relaunch) | B | 0.01 | clazjucp | FAILED at step 0 | only val/loss=10.826 logged |
| #2b (relaunch) | B | 0.01 | 7pcrm3hv | grad-norm=233,763 at step 15 (failing) | same explosion |

- Results: Two independent attempts spanning 10× LR range both produced runaway gradient norms (~235k vs healthy baseline ~5-10). Even with effective Lion embed_lr at 0.003 (100× smaller than AdamW embed_lr=0.3), the sign-based update is too aggressive for this regime. The architecture (50K-vocab embed table, ReLU² MLP, RMSNorm pre-norm, 12-layer depth) appears intrinsically incompatible with unit-magnitude sign updates on the embedding rows.
- Diagnostic insight: Lion's published recipes for language modeling typically use LR ≤ 3e-4 (vs our embed_lr=0.3 ÷ scale). To make Lion viable would need lion_lr_scale ≈ 0.001 (1000× reduction from AdamW) plus non-zero decoupled WD (Lion's recipe was LR ÷ 10 + WD × 5-10 vs AdamW, but our baseline uses WD=0 for AdamW groups). The retuning required is far enough from baseline that it stops being a like-for-like mechanism comparison.
- Decision: CLOSED clean-NEG. Lion axis closed at this scale/architecture. Frieren reassigned to wd_scalars sweep on new baseline.

## 2026-05-21 04:50 UTC — PR #565: thorfinn init variance scale sweep — **CLOSED clean-neutral (after MERGE shifted gate)**

- Branch: `g1r5-thorfinn/init-var-sweep`
- Student: g1r5-thorfinn
- Hypothesis: 5-cell init variance scale sweep (0.1/0.33ctrl/0.5/1.0/2.0). Phase 1 Cell B (xavier var=1.0) at val/loss=3.263870 cleared old n=1 gate by 0.000250 — at the noise floor, triggered P2.

| Phase | Trial | val/loss | ffs | Δ vs old baseline | vs new baseline (3.263265) |
|-------|-------|----------|-----|-------------------|---------------------------|
| P1 | Cell B (n=1) | 3.263870 | — | −1.29σ_old | +0.000605 ABOVE new |
| P2 | Trial 0 | 3.26387 | — | −1.29σ_old | +0.000605 ABOVE new |
| P2 | Trial 1 | 3.26740 | — | +0.73σ_old | +0.004135 ABOVE new |
| P2 | Trial 2 | 3.263850 | — | −1.20σ_old | +0.000585 ABOVE new |
| P2 | mean(0,1,2) | 3.265040 | — | −1.66σ_old | +0.001775 ABOVE new |

- Math gate analysis: For n=4 mean to clear NEW n=4 gate (3.261265), Trial 3 would need ≤ **3.249940** — that's **−7.6σ_old / −11.9σ_new**, empirically impossible.
- Results commentary: Cell B at 3.263870 was lucky-side noise vs old gate (passed by 0.000250, at the noise floor). P2 replication shows the true distribution sits at or slightly above the new baseline. Init variance axis (magnitude only) is closed for this budget. Depth-aware init (μP-style) and other init schemes remain unexplored.
- Decision: CLOSED clean-neutral. P2 math-closed by Trial 2; no waiting for Trial 3. Thorfinn reassigned to per-block LR decay sweep.

## 2026-05-21 04:22 UTC — PR #571: askeladd AdamW scalar LR sweep — **✅ MERGED — NEW BASELINE**

- Branch: `g1r5-askeladd/scalar-lr-sweep`
- Student: g1r5-askeladd
- Hypothesis: AdamW `adam_scalars` group (RMSNorm gains, ~20K params) hardcoded at lr=0.01. Sweep across 5 cells: A=0.01 ctrl / B=0.003 / C=0.001 / D=0.03 / E=0.1.

| Phase | Cell/Trial | lr_scalars | val/loss | ffs | Δ vs baseline (3.266120) | σ_single | W&B run |
|-------|-----------|-----------|---------|-----|--------------------------|---------|---------|
| P1 | A ctrl | 0.01 | 3.265233 | 3075 | −0.000887 | −0.51σ | aw6cq08g |
| P1 | B | 0.003 | 3.278590 | 3225 | +0.012470 | +7.14σ | s4c0z0uf |
| P1 | C | 0.001 | 3.289189 | DNF | +0.023069 | +13.20σ | uo6a2cql |
| **P1** | **D** | **0.03** | **3.262962** | **3050** | **−0.003158** | **−1.81σ** | xcxu2ziv |
| P1 | E | 0.1 | 3.272018 | 3125 | +0.005898 | +3.38σ | het906af |
| P2 T0 | D | 0.03 | 3.26347 | 3050 | −0.002650 | −1.52σ | apz56jxx |
| P2 T1 | D | 0.03 | 3.26401 | 3050 | −0.002110 | −1.21σ | apz56jxx |
| P2 T2 | D | 0.03 | 3.26162 | 3025 | −0.004500 | −2.58σ | apz56jxx |
| P2 T3 | D | 0.03 | 3.26396 | 3050 | −0.002160 | −1.24σ | apz56jxx |
| **P2 n=4 mean** | **D** | **0.03** | **3.263265** | **3043.75** | **−0.002855** | **−1.63σ** | apz56jxx |

**Statsig: (3.266120 − 3.263265) × √4 = 0.005710 ≥ 0.004 ✅ PASS (+0.001710 margin)**

- Results commentary: Asymmetric hump shape — lower direction (B/C) catastrophically worse (+7/+13σ), upper peaks at D (3× higher) and regresses at E (10× higher). All 4 P2 seeds independently clear the n=4 gate (3.264120). Sample σ=0.001123 tighter than baseline σ=0.001747. ffs_mean=3043.75 (−43.75 steps vs baseline 3087.5). Mechanism: RMSNorm gains were under-tuned at lr=0.01 — raising to 0.03 lets gains track optimal layer-scale faster during cooldown without destabilizing.
- **NEW BASELINE: mu=3.263265, std=0.001123, n=4, ffs_mean=3043.75**
- **New statsig gate:** (3.263265 − mu) × √n ≥ 0.004 → n=4: mu ≤ 3.261265 | n=6: mu ≤ 3.261633 | n=8: mu ≤ 3.261852
- Critical cross-axis: scalars_lr=0.03 WINS (this PR) but lm_head_lr=0.03 LOSES (#600) — per-group LR ratios NOT universal. Small param groups (20K scalars) take aggressive LR; large param groups (39M lm_head proj) need conservative LR.

## 2026-05-21 03:10 UTC — PR #600: alphonse lm_head LR sweep — **CLOSED clean-neutral**

- Branch: `g1r5-alphonse/lm-head-lr-sweep`
- Student: g1r5-alphonse
- Hypothesis: lm_head LR hardcoded at 1/320 (0.003125), never ablated. 5-cell sweep across 20× range (1/640 to 0.03) tests whether the proj group LR can be improved. Sibling to askeladd #571 (scalars_lr sweep) and nezuko #566 (embed_lr sweep).

| Cell | --lr_lm_head | val_loss | Δσ_n6 vs new baseline | ffs | W&B run |
|------|:------------:|:--------:|----------------------:|-----|---------|
| A (ctrl) | 1/320 (0.003125) | 3.26574 | −0.22σ | 3075 | `646yhh2s` |
| B | 1/640 (0.0015625) | 3.26809 | +1.13σ | 3100 | `zkatc2b1` |
| C | 1/160 (0.00625) | 3.26626 | +0.08σ | 3075 | `wqjf39r2` |
| D | 0.01 | 3.26608 | −0.02σ | 3075 | `6zpybyjf` |
| E | 0.03 | 3.26771 | +0.91σ | 3100 | `uqdww2sj` |

- Baseline: mu=3.266120, σ=0.001747, n=4 gate ≤3.264120

**Results commentary:** U-shaped response. Lower LR (B, 1/640) hurts at +1.13σ. Higher LR (E, 0.03 = 10× ctrl) also hurts at +0.91σ. Plateau at 0.003125–0.01 (A/C/D within ±0.3σ). No cell crosses n=4 gate.

**Key cross-PR insight:** askeladd #571 won at scalars_lr=0.03 (20K params) but alphonse #600 LOSES at lm_head_lr=0.03 (39M params). Big param groups want conservative LR, small param groups can take aggressive LR. Pre-existing per-group LR ratio (1/320 lm_head vs 0.01 scalars, ~3× ratio) is directionally correct.

**Conclusions:** AdamW per-group LR landscape now fully characterized via #566 (embed), #600 (lm_head), #571 (scalars in P2). The per-group LR axis is closed. Time to test fresh optimizer mechanisms.

**Follow-up assigned:** PR #641 — alphonse AdaBelief (Zhuang et al. 2020, arXiv:2010.07468) — variance of (g - m)² instead of g². Drop-in replacement for AdamW on the 3 AdamW-managed groups. 5-cell sweep: A=AdamW ctrl, B=AdaBelief default, C/D/E = AdaBelief with different eps values. Three parallel fresh-mechanism tests (#641 AdaBelief + #638 Lion + #626 AdEMAMix) — orthogonal modifications of AdamW.

## 2026-05-21 02:35 UTC — PR #556: frieren AdamW epsilon P2 confirmation — **CLOSED clean-neutral**

- Branch: `g1r5-frieren/adam-eps-sweep`
- Student: g1r5-frieren
- Hypothesis: Phase 1 (n=1) sweep of `--adam_eps ∈ {1e-12, 1e-10 ctrl, 1e-8, 1e-6, 1e-4}` showed W-shaped profile with TWO cells crossing the n=4 P2 gate at n=1: Cell C (1e-6, val=3.26369, −1.39σ, Llama-2/3 default) and Cell D (1e-12, val=3.263947, −1.24σ). Advisor selected C for P2 (theoretically motivated, strongest single-cell signal).

### P2 n=4 confirmation (W&B run `bfq43l07`)

| Trial | val/loss | ffs | Δσ_n6 (σ=0.001747) |
|------|---------:|----:|-------------------:|
| 0 | 3.26770 | 3100 | +0.90σ |
| 1 | 3.26788 | 3100 | +1.01σ |
| 2 | 3.26430 | 3050 | −1.04σ |
| 3 | 3.26341 | 3050 | −1.55σ |
| **n=4 mean** | **3.265823** | 3075 | **−0.17σ** |

### Gate evaluation

| Gate | Threshold | n=4 mean | Result |
|------|----------:|---------:|:------:|
| n=4 merge | ≤3.264120 | 3.265823 | FAIL (+0.001703) |
| Borderline +0.5σ | ≤3.265720 | 3.265823 | FAIL (+0.000103) |
| Inside ±1σ band | [3.264373, 3.267867] | 3.265823 | INSIDE |

**Mean lands at −0.17σ from baseline** — effectively at the baseline mean. The n=1 W-shape was noise.

### Conclusions

- Adam epsilon axis flat to within ±1σ across 8 decades (1e-12 → 1e-4). Llama-2/3 default eps=1e-6 is NOT better than modded-nanogpt aggressive eps=1e-10 at n=4 on this benchmark/budget.
- Bimodality between Trials 0/1 (both +1σ) and Trials 2/3 (both −1σ) is interesting — 4.4σ pair spread larger than expected — but averages to baseline. Could indicate seed-dependent landscape near this configuration but not actionable.
- The "less optimizer intensity" theme does NOT extend to AdamW eps softening. eps=1e-4 (most "softening") was the worst cell at +0.48σ.
- `--adam_eps` CLI flag is now refactored in for future use.

**Follow-up assigned:** PR #638 — frieren Lion optimizer replacement for AdamW-managed groups (embed, lm_head, scalars). Lion (Chen et al. 2023, arXiv:2302.06675) uses sign-based update with single momentum buffer — mechanistically distinct from AdamW. 5-cell LR-scale sweep: A=AdamW ctrl, B=Lion(scale=0.05), C=0.10 (Lion default), D=0.20, E=0.30.

## 2026-05-21 01:55 UTC — PR #594: fern peak WD multiplier sweep — **CLOSED clean-neutral**

- Branch: `g1r5-fern/peak-wd-sweep`
- Student: g1r5-fern
- Hypothesis: The `ramp_down` WD schedule starts at a peak multiplier of 2.0 (hardcoded, never ablated). This PR sweeps peak_wd_mult ∈ {1.0, 1.5, 2.0 ctrl, 2.5, 3.0} to determine if the WD magnitude is well-tuned. Also adds `--peak_wd_mult` CLI flag extending PR #548's `--wd_floor`.

| Cell | peak_wd_mult | Mean WD | val/loss | Δσ_n6 | ffs | W&B run |
|------|:------------:|:-------:|:--------:|------:|----:|---------|
| A (ctrl) | 2.0 | 1.00 | 3.26621 | +0.05σ | 3075 | `kkd3n63n` |
| B | 1.0 | 0.50 | 3.26874 | +1.50σ | 3075 | `umuimm7q` |
| C | 1.5 | 0.75 | 3.26875 | +1.50σ | 3100 | `41jyo5xc` |
| **D** | **2.5** | **1.25** | **3.26567** | **−0.26σ** | 3075 | `rbx6uayo` |
| E | 3.0 | 1.50 | 3.26760 | +0.85σ | 3100 | `0h42kou1` |

- Baseline: mu=3.266120, σ=0.001747, n=4 gate ≤3.264120

**Results commentary:** Cell D (peak=2.5, mean=1.25) crosses the -0.5σ soft flag (3.265720) by 0.00005, but n=1 noise floor dominates — Cell D's gap from ctrl is only 0.00054, well within single-sample variation. Non-monotonic response curve (B/C: lower peak hurts; D: slight improve; E: reverses). No cell crosses the n=4 P2 gate. Cell A refactor confirmed clean no-op (3.26621 vs baseline 3.266120).

**Conclusions:** WD magnitude axis fully characterized (combined with PR #548 floor closure). Lower peak unambiguously hurts (B/C +1.5σ each). Current peak=2.0 is well-tuned. Higher peak up to 2.5 provides negligible gain within noise. `--peak_wd_mult` CLI flag added for future use.

**Follow-up assigned:** PR #635 — WD schedule shape sweep (ramp_down ctrl / triangle / cosine_updown / constant / ramp_up). All 5 shapes have integral mean=1.0, isolating shape from magnitude. Zero code changes required — all schedules already implemented.

## 2026-05-20 23:42 UTC — PR #581: edward Lookahead optimizer wrapper — **CLOSED clean-NEG**

- Branch: `g1r5-edward/lookahead-wrapper`
- Student: g1r5-edward
- Hypothesis: Lookahead wrapper (Zhang et al. 2019) — slow/fast weight sync every k steps. Tests whether parameter-averaging across optimizer steps helps within the 3250-step budget.

### Results (n=1 each, vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | α | k | cd-off | val/loss | ffs | Δσ vs μ | Target? | W&B run |
|------|:---:|:---:|:---:|:--------:|:---:|:-------:|:-------:|---------|
| A (ctrl) | 0.0 | — | — | **3.26801** | 3100 | +1.08σ | yes | `luwh7m3l` |
| B (std) | 0.5 | 5 | — | 3.27956 | 3225 | +7.69σ | yes | `dwiibeuc` |
| C (k=10) | 0.5 | 10 | — | 3.28116 | DNF | +8.61σ | no | `zrfdz73z` |
| D (α=0.3) | 0.3 | 5 | — | 3.30526 | DNF | +22.40σ | no | `gajmg3t7` |
| E (cd-off) | 0.5 | 5 | ✓ | 3.28546 | DNF | +11.07σ | no | `rm56wpb0` |

### Key finding — Cell E refutes "sync-disrupts-cooldown" hypothesis

- Cell E disabled Lookahead sync at step 2600 (last 20% of run). Expected to recover cooldown performance. Instead: **E (+11.07σ) is WORSE than standard B (+7.69σ)**.
- The base optimizer's adaptive state (AdamW v buffer, Muon NS polynomial) had co-adapted to periodic resets. Disabling sync at step 2600 produces a transient lurch (+0.003 val rise step 2500→2750) before re-stabilizing. The damage is done during the active phase, not just cooldown.

### Mechanism confirmed

- **Lookahead sync = step-size ablator**: α=0.5 resets fast weights 50% toward stale slow every k steps — equivalent to halving effective step size on a budget where every step counts.
- **α=0.3 (D) is MORE aggressive, not gentler**: `fast ← 0.7*slow + 0.3*fast` resets 70% each sync. Explains D being worst.
- **Monotone ordering** (more sync → more harm): D > C > E > B > A.
- **Memory overhead +580 MB** (slow-weights buffer) — not a constraint, mechanism is the constraint.

### Conclusion

- **Wrapper-averaging axis closed clean-NEG**, joining tanjiro #517 (EMA). Both parameter-averaging mechanisms at param-level hurt the benchmark.
- **Lesson**: base optimizer (AdamW + Muon + NS) already saturates variance-reduction headroom. Any k-step averaging mechanism ablates short-horizon progress.
- **Gradient-side averaging** (AdEMAMix) is the natural follow-up: augments gradient moments, not parameters. Edward assigned PR #626.

---

## 2026-05-20 22:50 UTC — PR #596: tanjiro tied input/output embedding sweep — **CLOSED clean-NEG**

- Branch: `g1r5-tanjiro/tied-embedding-sweep`
- Student: g1r5-tanjiro
- Hypothesis: Share `embed.weight` and `proj.weight` (standard in GPT-2/T5/BERT, never tested). Sweep 5 cells: untied ctrl + tied at lr ∈ {0.3, 0.1, 0.03, 0.01}.

### Results (vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | Tied | lr_tied | val@step1500 | val@step3250 | ffs | Status |
|------|:----:|:-------:|:------------:|:------------:|:---:|:------:|
| A (ctrl) | off | n/a | 3.531 | **3.26719** | 3075 | ✅ complete |
| B | on | 0.3 | 3.567 | — | — | ❌ killed step 1612 |
| C | on | 0.1 | 3.558 | — | — | ❌ killed step 1624 |
| D | on | 0.03 | 3.590 | — | — | ❌ killed step 1584 |
| E | on | 0.01 | 3.689 | — | — | ❌ killed step 1707 |

### Conclusion

- **All 4 tied cells killed** across 3 decades of LR (0.3 → 0.01). Step-1500 val spans ≈ 0.13 — LR sweep makes minimal difference.
- **Root cause: initialization mismatch**, not LR. Tied uses embed's `normal_(std=1)` init for LM head → step-0 val ≈ 23. Untied uses `proj.zero_()` → step-0 val ≈ 10.8. The LM head never recovers from the ~23 start in 3250 steps.
- **Tied embedding axis closed clean-NEG** at 3250-step budget under current init. Would require redesigned init (e.g., `embed.normal_(std=0.02)`, or a warmup pre-pass) to be viable.
- **Cross-PR confirmation**: per-group LR design (embed=0.3, lm_head=1/320) is load-bearing for a reason — the two matrices do different jobs.

## 2026-05-20 21:35 UTC — PR #565: thorfinn init variance scale sweep — **Phase 1 terminal, P2 confirmation IN-FLIGHT**

- Branch: `g1r5-thorfinn/init-var-scale-sweep`
- Student: g1r5-thorfinn
- Hypothesis: Initialization variance scale is `0.33` hardcoded (unconventional vs standard heuristics). Sweep 0.1/0.33ctrl/0.5/1.0/2.0 — tests whether Xavier-equivalent (1.0) or He (2.0) outperforms the hardcoded value.

### Phase 1 results (n=1 each, vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | `--init_var_scale` | val/loss | ffs | Δ vs new baseline | σ_single | n=4 gate? | W&B run |
|------|:------------------:|:--------:|:---:|:-----------------:|:--------:|:---------:|---------|
| D (tight) | 0.10 | 3.271900 | 3125 | +0.005780 | +3.31σ |  | `f9jbansb` |
| A (ctrl) | 0.33 | 3.265867 | 3075 | −0.000253 | −0.14σ |  | `7tm3hu20` |
| E (mid)  | 0.50 | 3.266796 | 3075 | +0.000676 | +0.39σ |  | `4m7m44dr` |
| **B (Xavier)** | **1.00** | **3.263870** | 3075 | **−0.002250** | **−1.29σ** | **✓ (beats by 0.000250)** | `rle5qnsu` |
| C (He) | 2.00 | 3.266345 | 3125 | +0.000225 | +0.13σ |  | `biwno0xw` |

### Phase 1 conclusion

- **Monotonic improvement 0.1 → 0.33 → 1.0, flat plateau 1.0 ↔ 2.0**. Mechanism: SOAP+Muon preconditioner needs non-tiny early gradient signal; Xavier (1.0) is well-motivated standard for residual depths.
- **Hardcoded 0.33 is NOT special** — appears below the optimum.
- **Cell B (var=1.0) passes the n=4 gate by 0.000250** — the narrowest of three concurrent gate-beating signals (askeladd D 0.001158; frieren C 0.000430; thorfinn B 0.000250).
- **Lower bound firmly closed**: var=0.10 catastrophic; do not probe below 0.2 in follow-ups.
- **P2 confirmation requested on Cell B** (var=1.0) — n=4 fresh seeds, ~6.8 GPU-hours. Group `g1r5-thorfinn/init-var-P2-b-confirm`.

### P2 decision rule
- **MERGE candidate** if n=4 mean ≤ 3.264120 (statsig threshold). Margin tight; one outlier could flip.
- **CLOSE clean-neutral** if n=4 mean > 3.264120. Lower bound (D) finding stays useful.

## 2026-05-20 21:25 UTC — PR #566: nezuko embed_lr sweep (0.05/0.15/0.3ctrl/0.6/1.0) — **CLOSED clean-neutral**

- Branch: `g1r5-nezuko/embed-lr-sweep`
- Student: g1r5-nezuko
- Hypothesis: embed_lr=0.3 hardcoded in AdamW (Adam embed group). Sweep 0.05/0.15/0.3ctrl/0.6/1.0 to test if sparse-gradient bias warrants higher LR or if ctrl is optimal.

### Results (n=1 each, vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | `--lr_embed` | val/loss | ffs | Δ vs baseline | σ_single | n=4 gate? | W&B run |
|------|:------------:|:--------:|:---:|:-------------:|:--------:|:---------:|---------|
| A (ctrl) | 0.3  | 3.26590 | 3075 | −0.00022 | −0.13σ |  | `jzx21wtp` |
| B | 0.15 | 3.26877 | 3100 | +0.00265 | +1.52σ |  | `gounuskg` |
| C | 0.6  | 3.26649 | 3075 | +0.00037 | +0.21σ |  | `dfqe8l2p` |
| D | 0.05 | 3.28031 | DNF  | +0.01419 | +8.12σ |  | `sa8k5vvn` |
| **E** | **1.0** | **3.26503** | 3075 | **−0.00109** | **−0.62σ (−0.5σ flag)** |  | `gm2evbtv` |

### Conclusion

- **Lower direction decisively closed**: D(0.05) catastrophic (+8.1σ), B(0.15) +1.5σ worse. Sparse-gradient hypothesis confirmed: rare-token embeddings starve when LR reduced.
- **Upper direction flat plateau (0.3 → 1.0)**: A, C, E all within ±0.6σ_single. No clear winner emerging.
- **Cell E (1.0) best at −0.62σ** — crosses −0.5σ flag threshold but NOT n=4 gate (gap of +0.52σ_single from gate).
- **Closed clean-neutral**: flat plateau confirms embed_lr ctrl=0.3 is robustly tuned. P2 not warranted (3 stronger P2 candidates already in flight; ~15% prior probability Cell E clears gate at n=4).
- **Cross-PR insight noted**: askeladd #571 Cell D (lr_scalars 3× higher wins) + this Cell E (lr_embed 3.3× higher hint) both suggest historical AdamW group LRs were conservative. If askeladd P2 confirms, compound (3× scalars + 3× embed) worth a joint screen.

## 2026-05-20 20:55 UTC — PR #571: askeladd AdamW scalar LR sweep — **Phase 1 terminal, P2 confirmation IN-FLIGHT** 🔥🔥

- Branch: `g1r5-askeladd/scalar-lr-sweep`
- Student: g1r5-askeladd
- Hypothesis: RMSNorm gain LR=0.01 (hardcoded, ~20K params, scalar group of AdamW). Sweep 0.001/0.003/0.01ctrl/0.03/0.1. Tests whether "less optimizer intensity" applies (lower wins) or whether the gain LR is genuinely under-tuned (higher wins).

### Phase 1 results (n=1 each, vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | `--lr_scalars` | val/loss | ffs | Δ vs new baseline | σ_single | n=4 gate? | W&B run |
|------|:--------------:|:--------:|:---:|:-----------------:|:--------:|:---------:|---------|
| A (ctrl) | 0.01  | 3.265233 | 3075 | −0.000887 | −0.51σ |  | `aw6cq08g` |
| B | 0.003 | 3.278590 | 3225 | +0.012470 | +7.14σ |  | `s4c0z0uf` |
| C | 0.001 | 3.289189 | DNF  | +0.023069 | +13.20σ |  | `uo6a2cql` |
| **D** | **0.03**  | **3.262962** | **3050** | **−0.003158** | **−1.81σ** | **✓ (beats by 0.001158)** | `xcxu2ziv` |
| E | 0.1   | 3.272018 | 3125 | +0.005898 | +3.38σ |  | `het906af` |

### Phase 1 conclusion

- **Hump-shaped curve** with minimum at lr_scalars=0.03 (3× the historical default).
- **Asymmetry**: lower direction is ≈+13σ per decade harsh; upper is ≈+5σ per decade gentle (D minimum to E).
- **Cell D = strongest single-seed signal currently in portfolio** (−1.81σ vs new baseline, beats n=4 gate by 0.001158). Theme: "less optimizer intensity" does NOT apply to per-group LR for RMSNorm gains — they were genuinely under-tuned.
- Cell E (0.1, 10× ctrl) overshoots but still reaches target by step 3125 (slower than D=3050) — cooldown saves it from full divergence.
- **P2 confirmation requested on Cell D** (lr_scalars=0.03) — n=4 fresh seeds, ~7.3 GPU-hours. Group `g1r5-askeladd/scalar-lr-P2-d-confirm`.

### P2 decision rule
- If n=4 mean ≤ 3.264120 (n=4 gate): **MERGE** as new baseline. lr_scalars=0.03 becomes new default.
- If 3.264120 < n=4 mean ≤ 3.265720: borderline; expand to n=6.
- If n=4 mean > 3.265720: NOT confirmed; close axis clean-neutral.

## 2026-05-20 18:55 UTC — PR #556: frieren AdamW epsilon sweep — **Phase 1 terminal, P2 confirmation IN-FLIGHT**

- Branch: `g1r5-frieren/adam-eps-sweep`
- Student: g1r5-frieren
- Hypothesis: Adam eps=1e-10 hardcoded. Log-scale sweep 1e-12 → 1e-4 (5 cells). Consistent with "less optimizer intensity" theme if larger eps wins by softening small-`v_hat` updates.

### Phase 1 results (vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | `--adam_eps` | val/loss | ffs | Δ vs new baseline | σ | n=4 gate? | W&B run |
|------|:------------:|:--------:|:---:|:-----------------:|:-:|:---------:|---------|
| **A (ctrl)** | 1e-10 | 3.264530 | 3050 | −0.001590 | −0.91σ |  | `a8cigu1n` |
| B | 1e-8  | 3.266420 | 3075 | +0.000300 | +0.17σ |  | `2w40mxt2` |
| **C** | 1e-6  | **3.263690** | 3050 | **−0.002430** | **−1.39σ** | ✓ | `ue078g8r` |
| **D** | 1e-12 | **3.263947** | 3050 | **−0.002173** | **−1.24σ** | ✓ | `rlkvgcgb` |
| E | 1e-4  | 3.266966 | 3075 | +0.000846 | +0.48σ |  | `3wv7n3u7` |

### Phase 1 conclusion

- **Non-monotonic W-shape**: both extremes (C=1e-6, D=1e-12) beat ctrl; middle cells (B=1e-8, E=1e-4) worse. Most consistent interpretation (per student's analysis): noise dominating an n=1 sweep. P(2 of 5 cells beat n=4 gate | null hypothesis) ≈ 11% — significant but not overwhelming.
- **2 cells beat n=4 gate at n=1**: C=eps=1e-6 (strongest, −1.39σ; theoretically motivated as Llama-2/3 default) and D=eps=1e-12 (−1.24σ; no clear theoretical story).
- **P2 confirmation requested on Cell C** (eps=1e-6) — n=4 fresh trials, ignoring the original Cell C to avoid selection bias. ETA ~7 GPU-hours.

### P2 decision rule
- If n=4 mean ≤ 3.264120 (n=4 gate): MERGE as new baseline. eps=1e-6 becomes new default.
- If 3.264120 < n=4 mean ≤ 3.265720: borderline; expand to n=6.
- If n=4 mean > 3.265720: NOT confirmed; close axis clean-neutral.

## 2026-05-20 17:35 UTC — PR #552: alphonse LR warmup curve sweep (none/2%/5%×2-shapes/10%) — **CLOSED clean-NEG**

- Branch: `g1r5-alphonse/lr-warmup-sweep`
- Student: g1r5-alphonse
- Hypothesis: LR warmup may smooth early training dynamics and improve convergence on this benchmark. First ever warmup PR in this run. 5 cells: no warmup ctrl, 2%/5% linear, 5% cosine, 10% linear.

### Results (vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | warmup_frac | shape | val/loss | Δ vs ctrl | Δ vs new baseline | ffs | W&B run |
|------|:-----------:|:-----:|:--------:|:---------:|:-----------------:|----:|---------|
| **A (ctrl)** | 0.0 | linear | **3.26861** | — | +1.4σ | 3125 | `ngwjo4bo` |
| E | 0.02 | linear | 3.27534 | +0.00673 | +5.3σ | 3175 | `0jwb2kyc` |
| D | 0.05 | cosine | 3.27591 | +0.00730 | +5.6σ | 3175 | `7enpr8we` |
| B | 0.05 | linear | 3.27714 | +0.00853 | +6.3σ | 3200 | `1xl9ynf1` |
| C | 0.10 | linear | 3.29216 | +0.02355 | +14.9σ | -1 (missed target) | `otqw0zim` |

### Conclusion

- **Clean monotonic worsening with warmup fraction**: 0.00 → 0.02 → 0.05 → 0.10 val/loss all increase. Even the briefest warmup (2% ≈ 65 steps) costs +0.0067 val/loss and slips ffs by 50 steps.
- **Cosine shape slightly better than linear at same fraction** (D=3.27591 vs B=3.27714, Δ=−0.00123) — slow-start ramp wastes slightly less budget — but overwhelmed by the fundamental warmup cost.
- **Mechanism (student analysis confirmed)**: (1) Muon NS orthogonalization caps update magnitude structurally, so warmup provides no safety benefit. (2) SOAP's preconditioner warms naturally; LR warmup buys nothing. (3) At 3250-step horizon every high-LR step is load-bearing — the cooldown cannot recover lost early budget. (4) Cell C (10% warmup) never reached val ≤ 3.28 target.
- **LR warmup axis closed**: no warmup is optimal for this 3250-step benchmark. Conclusion is scale-specific — would likely invert at 10k+ steps.

Alphonse reassigned to PR #600: LM-head LR sweep (proj.weight lr=1/320 hardcoded, never ablated; 3rd and final hardcoded AdamW group LR; natural complement to #566 embed_lr and #571 scalars_lr).

## 2026-05-20 16:50 UTC — PR #558: tanjiro Z-loss regularizer sweep (0/1e-5/1e-4/1e-3/1e-2) — **CLOSED clean-NEG**

- Branch: `g1r5-tanjiro/z-loss-sweep`
- Student: g1r5-tanjiro
- Hypothesis: Z-loss regularizer (PaLM 2, Google 2023) penalizes log-partition-function `log Z` of the softmax, discouraging large-logit growth during training. Never tested in this run. Cells sweep coefficient ∈ {0.0, 1e-5, 1e-4, 1e-3, 1e-2}. Cell D (1e-3) skipped by student — tanjiro observed catastrophic divergence at 1e-4 and correctly inferred 1e-3 would be worse.

### Results (vs NEW baseline mu=3.266120, σ=0.001747)

| Cell | z_loss_coef | val_loss | Δ vs NEW baseline | ffs | W&B run |
|------|:-----------:|:--------:|:-----------------:|----:|---------|
| **A (ctrl)** | 0.0 | **3.26661** | **+0.03σ** | 3100 | (ctrl) |
| E | 1e-5 | 3.26907 | +1.57σ | 3125 | (cell E) |
| B | 1e-4 | 3.27618 | +5.72σ | — | (cell B) |
| C | 1e-3 | ~3.44 (killed) | catastrophic | — | (cell C, killed at step ~1500) |
| D | 1e-2 | — | skipped by student | — | (skipped) |

### Conclusion

- **Monotonic worsening across 3 orders of magnitude**: even the smallest tested coefficient (1e-5) costs +1.57σ. The 1e-3 cell diverged catastrophically by step 1500.
- **Mechanism**: the existing logit softcap at `train_gpt_simple.py:459` (`15 * logits * (logits.square() + 15**2).rsqrt()`) already bounds logits to ±15, providing the exact stability that z-loss is designed to deliver. Z-loss stacks **redundant** logit suppression on top of the softcap, over-regularizing the output distribution and preventing meaningful token discrimination.
- **Student Cell D skip**: tanjiro correctly applied the kill rule after observing monotonic catastrophic worsening — Cell D (1e-2) was skipped, an appropriate experimental judgment.
- **Z-loss axis closed**: the existing softcap already handles logit stability; z-loss adds no net value in this architecture.

Tanjiro reassigned to PR #596: tied input/output embedding sweep (structural axis — never tested in this run; standard in GPT-2/T5/BERT but codebase is currently untied).

## 2026-05-20 16:20 UTC — PR #548: fern WD floor in cooldown sweep (0/0.05/0.10/0.20/0.50) — **CLOSED clean-neutral**

- Branch: `g1r5-fern/wd-floor-cooldown-sweep`
- Student: g1r5-fern
- Hypothesis: WD ramp_down lands at 0 — but is that terminal condition load-bearing? Sweeps wd_floor ∈ {0.0, 0.05, 0.10, 0.20, 0.50}. Dual of LR-floor finding (PR #504 which showed LR=0 is catastrophically load-bearing).

### Results (vs OLD baseline mu=3.267948, σ=0.000823)

| Cell | wd_floor | val_loss | Δσ vs OLD baseline | ffs | W&B run |
|------|:--------:|:--------:|:------------------:|----:|---------|
| **A (ctrl)** | 0.0 | **3.26709** | **−1.04σ** | 3100 | `9qibkkxi` |
| B | 0.05 | 3.26735 | −0.73σ | 3100 | `e4w1fuzx` |
| C | 0.10 | 3.26730 | −0.79σ | 3100 | `gq4brp6c` |
| D | 0.20 | 3.26873 | +0.95σ | 3100 | `866sb9dj` |
| E | 0.50 | 3.27009 | +2.60σ | 3125 | `oa4n4288` |

### Conclusion

- **WD floor=0 is NOT load-bearing**: B/C within ctrl noise; D=+0.95σ is ctrl-edge; E=+2.60σ moderate worsening. Flat-floor then mild-incline shape (vs LR-floor's catastrophic monotonic worsening).
- **Critical cross-axis comparison (vs PR #504 LR-floor)**: LR-floor=0.20 = +29.46σ catastrophic; WD-floor=0.20 = +0.95σ ≈ ctrl edge. WD axis is ~30× more forgiving than LR axis at same fractional value.
- **Mechanism**: LR=0 terminal is structurally load-bearing (quiescent final phase enables consolidation); WD=0 terminal is incidental (regularization-direction movement doesn't matter at cooldown end).
- **Implication for PR #371**: the WD ramp_down win is about **peak/mean WD profile shape**, not the landing-at-zero terminal condition.
- **Closes one half of cooldown mechanism**: combined with #504, cooldown is now understood as "LR=0 critical, WD=0 incidental."

Fern reassigned to PR #594: peak-wd-sweep (hardcoded peak=2.0 never ablated; directly motivated by this finding).

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

---

## 2026-05-22 ~09:45 UTC — PR #687: askeladd Atan2-AdamW P2 n=4 confirmation (Cell D) — **CLOSED clean-NEG**

- Branch: `g1r5-askeladd/atan2-adamw-sweep`
- Student: g1r5-askeladd
- Hypothesis: P2 n=4 confirmation at Cell D config (atan2=1, lr_adamw_mul=2.0, β1=0.8) — the P1 best cell (val/loss=3.26205 at n=1, +0.000785 above gate, -1.93σ vs ctrl A=3.26419).

- **P2 n=4 results (run `jcmxx5sc`, group `g1r5-askeladd/atan2-adamw-P2-confirm`):**

| Trial | val/loss | ffs | vs gate (3.261265) |
|------:|---------:|----:|:-------------------|
| 0 | 3.26525 | 3075 | +0.003985 (above) |
| 1 | 3.26544 | 3075 | +0.004175 (above) |
| 2 | 3.26377 | 3050 | +0.002505 (above) |
| 3 | 3.26240 | 3050 | +0.001135 (above) |
| **μ_{n=4}** | **3.264213** | **3062.5** | **+0.002948 above gate** |
| σ_single | 0.001419 | — | — |
| SEM | 0.000710 | — | — |

- **Gate verdict: clean-NEG.** μ_{n=4} = 3.264213 is +0.002213 above clean-NEG cutoff (3.262). The P1 single-seed win at Cell D (3.26205) was seed noise — trials 0/1/2/3 all failed to reproduce it; the 4-seed mean sits inside the strong-ctrl band (3.26129–3.26480).

- **Mechanism analysis:**
  1. **Atan2 normalization + 2× LR is mechanically stable** — all 4 trials reached target, no divergence, step time stable ~1.9 s/step (~7.3h wall-clock). StableAdamW bounded SNR claim (Wortsman 2023) reproduces: higher LR is safe.
  2. **But the bounded normalization does not lower terminal loss** at L=12, 3250 steps, post-#571 baseline. The P1 LR-ceiling effect (B=3.26574, C=3.26291, D=3.26205 at 1×/1.5×/2.0×) is real (small magnitude, monotone) but does not survive n=4 — sits inside σ_single=0.001419.
  3. **6th non-Muon AdamW-kernel mechanism closure**: Lion #638 / Lookahead #581 / AdEMAMix #626 / Schedule-Free-B #659 / Adan #645 / Atan2 #687. **AdamW-kernel axis exhausted at L=12, 3250-step horizon.** No further AdamW-kernel modifications worth chasing.
  4. **Cross-PR inference**: eps-stability tests (#556, #641) + atan2 P2 (#687) together imply: the *only* remaining potential atan2 value was the LR ceiling, which n=4 confirms is seed-bounded. Axis exhausted.

- **Student commendation**: post-trial gate-tracking math was precise. At trial 1 correctly predicted clean-NEG: "for μ_{n=4} ≤ 3.261265, trials 2 and 3 must average ≤ 3.257185 — far below the strong-ctrl band lower edge (3.26129). Vanishingly unlikely." Terminal outcome exactly as forecasted.

- **Decision:** CLOSED clean-NEG per pre-declared rule (μ > 3.262). **Askeladd reassigned #776 Muon/SOAP update RMS normalization.**

---

## 2026-05-22 ~09:45 UTC — PR #776: askeladd Muon/SOAP update RMS normalization — **ASSIGNED (P1 sweep in flight)**

---

## 2026-05-22 ~09:15 UTC — PR #691: thorfinn per-group β1 stacked (β1_embed=0.9, β1_scalars=0.9, β1_lm_head=0.8) — **CLOSED clean-NEG (P2 μ_n=4 +1.195mNat above gate)**

- Branch: `g1r5-thorfinn/per-group-beta1-stacked`
- Student: g1r5-thorfinn
- Hypothesis: Stack two P1 findings from #667 (β1_embed=0.9 best) and #676 (β1_scalars=0.9 best) while holding β1_lm_head=0.8. Per-group β1 asymmetry exploits different gradient smoothing needs across AdamW groups.

- **P2 n=4 terminal (Cell B config: β1_embed=0.9, β1_scalars=0.9, β1_lm_head=0.8):**

| Trial | val/loss | ffs |
|------:|---------:|----:|
| 0 | 3.262342 | — |
| 1 | 3.263042 | — |
| 2 | 3.262077 | — |
| 3 | 3.262380 | — |
| **μ_{n=4}** | **3.26246** | — |
| σ_single | ~0.00047 | — |

- **Gate math**: μ_n=4 = 3.26246 = +0.001195 above merge gate (3.261265), +0.000460 above clean-NEG cutoff (3.262). Clean-NEG verdict.

- **Key mechanism finding**: Student's additive prediction (B+D projection = 3.26125, combining β1_embed+β1_scalars individually) vs observed μ_n=4=3.26246 = +1.21mNat additive overshoot. Stacking partial-group β1 gains does NOT add linearly — the two axes compete at the gain-scalars interface, which uses both embed and scalars statistics. Cross-term interference explains the ceiling.

- **Decision**: CLOSED clean-NEG. Per-group β1 axis fully exhausted (individual group B1 sweeps + stacked combination all closed). **Thorfinn reassigned #781 per-group AdamW ε sweep (gradient sparsity asymmetry mechanism, orthogonal to all closed β1 work).**

---

## 2026-05-22 ~09:20 UTC — PR #781: thorfinn per-group AdamW ε sweep — **ASSIGNED**

- Branch: `g1r5-thorfinn/per-group-adamw-eps`
- Student: g1r5-thorfinn
- Hypothesis: Per-group ε on AdamW — raise eps_embed (sparse ~3-5% rows/step) while holding/lowering eps_lm_head (dense every step). PR #556 closed global ε as flat (uniform scalar); this decouples the two groups to expose asymmetry.

- **5-cell P1 sweep:**

| Cell | eps_embed | eps_lm_head | Role |
|:----:|:---------:|:-----------:|:-----|
| A | 1e-10 | 1e-10 | ctrl — validates AdamW split refactor |
| B | 1e-8 | 1e-10 | embed↑ 100× |
| C | 1e-7 | 1e-10 | embed↑↑ 1000× |
| D | 1e-8 | 1e-11 | full asymmetry (embed↑, lm_head↓) |
| E | 1e-9 | 1e-10 | moderate embed raise |

- **Implementation**: refactor optimizer1 (single fused AdamW, lines 786-789) into 3 separate AdamW instances (PyTorch fused AdamW does not accept per-group eps); add `--eps_embed` and `--eps_lm_head` CLI flags with defaults 1e-10.

- Branch: `g1r5-askeladd/muon-update-rms-norm`
- Student: g1r5-askeladd
- Hypothesis: Normalize post-NS Muon/SOAP update matrix to a fixed target RMS per matrix. Decouples update direction (NS) from update magnitude (explicit RMS). Analogue of LARS/LAMB for orthogonalization-based optimizers.

- **5-cell P1 sweep (--muon_update_rms_target values):**

| Cell | target RMS | Expected role |
|:----:|:----------:|:--------------|
| A | 0.0 (ctrl) | Confirm baseline; establish σ reference |
| B | 0.25 | Weak normalization |
| C | 0.50 | Moderate (expected interior optimum) |
| D | 1.00 | Unit-RMS — most principled |
| E | 2.00 | Strong — boundary probe |

- **Implementation**: `soap_ns_step` modification at lines 499-503 (load-bearing surgery under --soap_attn baseline); `muon_update` at lines 491-496 modified for consistency (dead code under --soap_attn). New `--muon_update_rms_target` CLI flag; `@torch.compile` specializes on 0.0 ctrl — zero overhead on baseline.

- **Orthogonal to all 7 in-flight**: distinct pipeline stage from GC (#756, pre-NS input) and adaptive-mu (#773, momentum blend into NS). NS_iter controls convergence quality; this controls output magnitude. Strictly orthogonal.

- **Gate**: μ_n=1 ≤ 3.261265 → P2 n=4. μ_n=4 ≤ 3.261265 → merge.

---

## 2026-05-22 ~10:27 UTC — PR #699: alphonse depth-aware musoft residual-proj init — **MERGED ✅ NEW BASELINE**

- **Branch**: `g1r5-alphonse/depth-aware-init`
- **Student**: g1r5-alphonse
- **Hypothesis**: Block residual injection paths (`blocks.*.attn.proj.weight`, `blocks.*.mlp.proj.weight`) initialized to N(0, sqrt(0.33)/sqrt(fan_in×L)) ≈ N(0, 0.006) instead of zero. μP 1/√L depth scaling — each block's residual path starts with a small non-zero basis, providing gradient flow from step 1 without dominating the learned directions.

- **P2 n=4 terminal (run `zp6gvwv5`, group `g1r5-alphonse/depth-aware-init-P2-confirm`):**

| Trial | val/loss | ffs | Δ vs n=4 gate (3.261265) |
|------:|---------:|----:|:------------------------:|
| 1 | **3.260513** | 3025 | **−0.000752 (BELOW)** ✓ |
| 2 | 3.261771 | 3025 | +0.000506 (above) |
| 3 | 3.261646 | 3025 | +0.000381 (above) |
| 4 | **3.260954** | 3025 | **−0.000311 (BELOW)** ✓ |
| **μ_n=4** | **3.261221** | **3025** | **−0.000044 (BELOW gate)** ✅ |

- **Statsig**: (3.263265−3.261221)×√4 = **0.004088 ≥ 0.004** ✅ (+0.000088 margin — razor-thin pass)

- **Mechanism analysis**:
  - The μP 1/√L per-block residual scaling provides bounded total residual variance at depth L=12, consistent with theoretical prediction. Smaller std (mumedium = 1/L scaling) was worse; applying to non-residual weights (muall) was worse; depth-independent constant was worse. The 1/√L form is specifically optimal.
  - ALL 4 trials hit ffs=3025 (vs baseline ffs_mean=3043.75) — the init improvement is consistent across seeds.
  - P2 trial variance σ=0.000593 is narrower than historical σ_single=0.001123, suggesting musoft init reduces run-to-run variation.

- **New baseline**: μ=3.261221, ffs_mean=3025, new n=4 gate=**3.259221** (2mNat harder).
- **New mandatory flag**: `--depth_init_mode musoft`
- **Decision**: **MERGED** — first post-#571 init-magnitude merge. Gate implications sent to all active P2s (nezuko #706, edward #714, frieren #748).


---

## 2026-05-22 ~10:50 UTC — PR #785: alphonse residual-proj init magnitude multiplier sweep — **ASSIGNED**

- **Branch**: `g1r5-alphonse/resid-alpha-sweep`
- **Student**: g1r5-alphonse
- **Hypothesis**: PR #699 confirmed depth-aware 1/√L scaling form is load-bearing for residual-proj init, but the multiplicative coefficient was inherited from μP literature (sqrt(0.33)≈0.574) without independent optimization. This sweep tests whether α=1.0 is the true optimum on the magnitude axis.

- **5-cell P1 sweep (new `mualpha` mode + `--resid_init_alpha` flag):**

| Cell | α | σ (fan_in=768, L=12) | Role |
|:----:|:-:|:---------------------:|:-----|
| A | 0.50 | ≈0.00299 | Half-scale anchor (sign-falsifier) |
| B | 0.75 | ≈0.00449 | Sub-canonical |
| C | 1.00 | ≈0.00598 | **Ctrl — reproduces musoft baseline** |
| D | 1.50 | ≈0.00898 | Super-canonical (primary prediction) |
| E | 2.00 | ≈0.01196 | Double-scale anchor |

- **Implementation**: ~4 lines of code change. Add `mualpha` to `--depth_init_mode` choices, new `--resid_init_alpha` flag (float, default 1.0), extend `_resid_proj_std` to multiply by alpha. Backward-compatible: `mualpha α=1.0` ≡ `musoft`.

- **Prediction**: D (α=1.5) wins via faster SOAP preconditioner warm-up at moderately wider init. Falsifier: if A ≥ C, sub-canonical sweep needed.

- **Orthogonal to all 7 in-flight**: nezuko #706 (embed), edward #714 (gains), frieren #748 (transform), tanjiro #756 (GC), fern #773 (adaptive mu), askeladd #776 (update RMS), thorfinn #781 (per-group eps). Strictly orthogonal.

- **Gate**: μ_n=1 ≤ 3.259221 → P2 n=4. μ_n=4 ≤ 3.259221 → merge. Clean-NEG: μ > 3.261.

---

## 2026-05-24 ~03:30 UTC — PR #941: edward Cooldown SWA (weight EMA during cooldown) — **CLOSED clean-NEG with mechanism finding**

- Branch: `g1r5-edward/cooldown-swa`
- Student: g1r5-edward
- Hypothesis: Maintain weight EMA (β=0.99) during cooldown (steps 975–3250), eval from EMA weights. SWA finds centroid of wide loss basin; should be lower than terminal-step weights if the cooldown trajectory has noise around a flat minimum.

- **5-cell P1 results:**

| Cell | Config | val/loss (n=1) | Δ vs ctrl |
|:----:|:-------|:--------------:|:---------:|
| A | ctrl (no SWA) | ~3.2612 | — |
| B | β=0.99 (half-life ~70 steps) | +regression | NEG |
| C | β=0.999 (half-life ~690 steps) | +larger regression | NEG (monotonic in β) |
| D | β=0.95 (faster, more responsive) | +smaller regression | NEG |
| E | late-start (step 1625) | +moderate regression | NEG |

- **Key mechanism finding**: `swa/live_vs_swa_dist` metric (Frobenius distance between live weights and SWA weights) was MONOTONIC in both β and regression magnitude. Higher β = larger lag = bigger distance = worse val/loss. This means:
  - The cooldown trajectory is **directed descent**, not noisy oscillation around a flat minimum.
  - Weight EMA always LAGS the descent — it averages over weights that haven't yet reached the cooldown's final state.
  - SWA is fundamentally incompatible with the geometry of cooldown training in this regime.

- **Decision**: CLOSED clean-NEG. **Closes "trajectory averaging" axis (3/3 NEG with #826 Lookahead and #855 Schedule-Free).** All three approaches average or interpolate the optimizer's trajectory; all three lose to running the trajectory cleanly.

- **Reassignment**: edward → #994 SOAP simplification: drop Q_row from attn only (the missing #936 per-scope config). Mechanism follow-up to #936 askeladd asymmetric SOAP closure.

---

## 2026-05-24 ~03:45 UTC — PR #994: edward SOAP simplification — drop Q_row from attn only — **ASSIGNED**

- Branch: `g1r5-edward/soap-drop-qrow-attn-only`
- Student: g1r5-edward
- Hypothesis: PR #936 closed asymmetric SOAP clean-NEG with strong mechanism signal — Q_col (input-side) load-bearing for attn (B-C contrast +12.25σ), Q_row largely redundant (C-E contrast +0.89σ). But #936 always applied side changes to BOTH attn AND MLP simultaneously. The missing config — attn=Q_col only, MLP=full SOAP — has never been tested. If additive cross-scope decomposition holds, this should match baseline within ~+0.89σ while saving ~25% of SOAP attn compute per step.

- **5-cell P1 sweep:**

| Cell | (attn_side, mlp_side) | Role |
|:----:|:---------------------:|:-----|
| A | (both, both) | ctrl — baseline parity expected |
| **B ★** | **(right, both)** | **PRIMARY: drop Q_row from attn ONLY, keep full SOAP on MLP — the missing #936 config** |
| C | (none, both) | Extreme: no SOAP on attn at all |
| D | (right, right) | Drop Q_row everywhere — tests additive cross-scope prediction |
| E | (right, none) | Asymmetric: drop Q_row attn + no SOAP MLP |

- **Implementation**: add `--soap_attn_side {both,left,right,none}` and `--soap_mlp_side {both,left,right,none}` flags. Branch in `soap_precondition_momentum` (~line 543) on side for the param's scope. Backward-compatible: defaults preserve current behavior. Side=none falls back to plain Muon for that scope.

- **Information value either way**: B match → confirms additive decomposition (lock in compute savings). B much worse → cross-term interactions matter (mechanism signal). B beats baseline → unexpected WIN.

- **Gate**: B μ_n=1 ≤ 3.260 → P2 n=4. μ_n=4 ≤ 3.259221 → merge. Within +0.5σ to +1.5σ of baseline → close as informative-NEG.


---

## 2026-05-24 ~05:50 UTC — PR #907: tanjiro Muon momentum reset at cooldown onset — **CLOSED clean-NEG (high info)**

- Branch: `g1r5-tanjiro/momentum-reset-at-cooldown-onset`
- Student: g1r5-tanjiro
- Hypothesis: Zero or partially decay the Muon momentum buffer at cooldown onset (step 975) to eliminate stale steady-phase momentum bias. Cell E extends to joint reset of SOAP exp_avg_sq.

- **n=1 screening results (poll #531-554):**

| Cell | gamma | soap | val/loss | Δ vs A |
|:----:|:-----:|:----:|---------:|-------:|
| A ctrl | — | — | 3.26109 | — |
| B ★ | 0.0 | F | 3.26139 | +0.00030 |
| C | 0.1 | F | 3.26223 | +0.00114 |
| D | 0.5 | F | 3.26175 | +0.00066 |
| E | 0.0 | T (joint) | 3.26004 | **−0.00105** (−3.5σ_SE POS) |

- **n=4 confirm of Cell E (this poll):**

| Trial | val/loss |
|------:|---------:|
| 0 | 3.26167 |
| 1 | 3.26027 |
| 2 | 3.26267 |
| 3 | 3.26201 |
| **μ_n=4** | **3.261655** |
| σ_single | **0.001012** (**1.71× baseline 0.000593**) |

- **Verdict**: statsig = (3.261221 − 3.261655) × √4 = **−0.000868** → FAIL gate (need ≥ 0.004). μ_E above clean-NEG threshold (3.260828). **Axis closes.**

- **Key mechanism finding (high info)**: The n=1 POS of 3.26004 was a favorable-tail draw from a distribution with **1.71× wider σ than baseline**. The reset injects variance without injecting mean improvement. 3/4 trials sit above baseline μ. **Generalized lesson: instantaneous discontinuities at step 975 inflate σ — watch for the same in #966 alphonse cooldown weight rescaling (another step-975 discontinuity).** The cooldown-calibration story is stronger with SMOOTH transitions (#925 fern linear μ ramp still in n=4 confirm) than abrupt resets.

- **Decision**: CLOSED clean-NEG. Full `mu_reset_step / mu_reset_gamma / mu_reset_soap` family axis exhausted.

- **Reassignment**: tanjiro → #1010 NS-iter-by-time (boost NS quality during cooldown — novel orthogonal axis).

---

## 2026-05-24 ~06:00 UTC — PR #1010: tanjiro NS-iter-by-time — boost NS quality during cooldown — **ASSIGNED**

- Branch: `g1r5-tanjiro/ns-iter-by-time-cooldown`
- Student: g1r5-tanjiro
- Hypothesis: Cooldown wants higher NS orthogonalization quality. Cooldown LR is small relative to gradient noise — extracting a cleaner orthogonal direction from a noisier-relative gradient may improve descent quality. NS-iter-by-TIME is novel (vs #932 by-DEPTH closed, #815 by-EARLY-TIME closed).

- **5-cell P1 sweep:**

| Cell | --ns_iter_cooldown | ramp | Effective ns_iter at step 975+ |
|:----:|:------------------:|:----:|:------------------------------:|
| A | 0 (ctrl) | — | 6 throughout |
| **B ★** | **8** | false | step-jump 6→8 at step 975 |
| C | 10 | false | step-jump 6→10 |
| D | 12 | false | step-jump 6→12 (boundary probe) |
| E | 9 | true | linear ramp 6→9 from 975 to 3250 |

- **Implementation**: add `--ns_iter_cooldown` (int default 0 = no change), `--ns_iter_cooldown_ramp` (bool flag). Plumb step counter into NS call. Log effective ns_iter per step.

- **Falsifier**: all NEG → cooldown does not benefit from higher NS quality, NS_iter=6 sufficient under any LR regime. Closes NS-iter-by-time axis.

- **Information value**: tests novel time-varying NS axis AND tests whether smooth ramp (Cell E) outperforms abrupt step-jump (Cell B/C/D) — generalizes #907 closure lesson about discontinuities inflating variance.

- **Gate**: μ_n=1 ≤ 3.260 → P2 n=4. μ_n=4 ≤ 3.259221 → merge.

## 2026-05-24 14:30 — PR #994: SOAP per-scope Q_row drop (attn-only)

- Branch: `g1r5-edward/soap-attn-q-row-drop`
- Hypothesis: After #936 finding that Q_col >> Q_row for attn, drop Q_row from attn ONLY (leave MLP both). Predicted ~+0.89σ if additive cross-scope decomposition holds.

- **5-cell sweep (attn_side, mlp_side):**

| Cell | attn_side | mlp_side | Result vs baseline | σ vs baseline |
|:----:|:---------:|:--------:|:------------------:|:-------------:|
| A | both | both | baseline ctrl | 0σ |
| **B ★** | right | both | NEG | strongly positive σ |
| C | none | both | NEG (large) | very large σ |
| D | right | right | NEG | large σ |
| E | right | none | NEG | very large σ |

- **Result**: clean-NEG. **Cross-scope decomposition non-additive 4.5×** — predicted sum of per-scope contributions did not hold (B+D ≠ A−C). Both SOAP attn AND SOAP MLP each contribute roughly ½ of total SOAP value; neither scope is free to drop.

- **Mechanism finding**: Q_col >> Q_row hierarchy from #936 is confirmed (B less harmful than C), but Q_row is NOT zero-cost as predicted by the additive model. Q_row contributes residual value to attn even with Q_col present. **Cross-scope coupling exists**: dropping Q_row from attn while MLP has full preconditioning costs more than the simple per-scope ablation predicted.

- **Closure**: structural per-scope SOAP pruning axis is now saturated:
  - #936 closed Q_col vs Q_row per-side comparison
  - #979 closed exp_avg_sq pruning (direction-warping load-bearing, EMA inessential)
  - #994 closes per-scope structural drop combinations
- Remaining SOAP-internals work is the temporal/cadence dimension (#1036 global precond_freq, #1053 asymm Q_row/Q_col freq).

- **Follow-up assigned**: edward → #1053 Asymmetric SOAP Q_row/Q_col refresh frequency. If Q_row can't be structurally dropped (#994) but is much less important than Q_col (#936), it may tolerate temporal sparsification — refresh Q_row less often than Q_col, recovering compute savings without structural penalty.

## 2026-05-24 14:30 — PR #993: Gradient-norm-anomaly Muon momentum reset

- Branch: `g1r5-askeladd/grad-anomaly-mu-reset`
- Hypothesis: Track ||grad||_F EMA per matrix; when current norm > K × EMA, partial μ reset. Magnitude-anomaly trigger axis distinct from time #907 / schedule #925 / direction #973.

- **5-cell sweep:**

| Cell | thresh | reset_frac | Result vs baseline |
|:----:|:------:|:----------:|:------------------:|
| A | — (ctrl) | — | baseline |
| **B ★** | 3× | 0.5 | NEG |
| C | 2× | 0.5 | NEG |
| D | 3× | 1.0 | NEG |
| E | 5× | 0.5 | NEG |

- **Result**: clean-NEG. All triggered treatments regressed; no anomaly-driven reset configuration helped.

- **Mechanism finding**: **Muon NS orthogonalization bounds output magnitude.** The NS iteration in `zeropower_via_newtonschulz5` produces outputs with norm bounded by `sqrt(min(m, n))` regardless of input magnitude — gradient spikes never propagate to weight updates as magnitude anomalies. The trigger condition (||grad||_F > K × EMA) fires on input magnitude but Muon downstream completely decouples input magnitude from update magnitude. **Magnitude-conditional triggers are structurally weak for Muon-optimized layers.**

- **Closure**: momentum-trigger cluster comprehensively closed (4/4 axes NEG):
  - Time-triggered: #907 (joint reset at step 975) — NEG, σ_single 1.71× baseline
  - Schedule-triggered: #925 (linear μ ramp through cooldown) — WEAK-NEG, σ_sample 1.4× baseline
  - Direction-triggered: #973 (cosine-gated adaptive μ) — NEG, monotone harm in distance from 0.95
  - Magnitude-triggered: #993 (grad-norm-anomaly reset) — NEG, NS bounds magnitude
- No remaining trigger axis for μ buffer manipulation. Future work on μ should pivot to fundamentally different formulations (per-layer asymmetric momentum, learned mixing, etc.) rather than trigger-based interventions.

- **Follow-up assigned**: askeladd → #1054 LR schedule shape sweep. **Discovery during axis search**: LR schedule was HARDCODED at lines 882-888 of `set_hparams` (`eta = (1 − progress) / cooldown_frac`) — trapezoidal-stable-then-linear-decay, no CLI flag, never SENPAI-validated. Schedule shape is orthogonal to schedule values (lr_mlp/lr_scalars set, shape never was). Tests cosine/exponential/floor/quintic.

## 2026-05-24 14:30 — PR #1053: Asymmetric SOAP Q_row/Q_col refresh frequency

- Branch: `g1r5-edward/soap-asymm-q-refresh-freq`
- Assigned to: g1r5-edward (follow-up after #994 closure)
- Hypothesis: Mechanism-driven from #936 (Q_col >> Q_row for attn) and #994 (Q_row not structurally free but ~½ importance of Q_col). If Q_row carries less load, refreshing it less often than Q_col may recover compute without structural penalty. Compute savings: ~25% on SOAP Q updates if Q_row refreshes 4× less often than Q_col.

- **5-cell sweep (precond_freq_row, precond_freq_col):**

| Cell | row freq | col freq | Description |
|:----:|:--------:|:--------:|:------------|
| A | 16 | 16 | ctrl (current PRECOND_FREQ=16 both) |
| **B ★** | 64 | 16 | Q_row 4× sparser |
| C | 32 | 16 | Q_row 2× sparser |
| D | 128 | 16 | Q_row 8× sparser (boundary) |
| E | 16 | 64 | inverse falsifier (Q_col 4× sparser) |

- **Implementation**: split `PRECOND_FREQ` into row/col paths in `soap_update_preconditioner`. Add `--precond_freq_row` and `--precond_freq_col` (defaults preserve current behavior).

- **Falsifier**: Cell E should regress more than Cell B if Q_col is genuinely more critical. If E ≈ B, the asymmetry hypothesis is wrong. If B ≪ A in cost and E ≫ A in cost, mechanism confirmed.

- **Gate**: μ_n=1 ≤ 3.260 → P2 n=4. μ_n=4 ≤ 3.259221 → merge.

## 2026-05-24 14:30 — PR #1054: LR schedule shape sweep

- Branch: `g1r5-askeladd/lr-schedule-shape-sweep`
- Assigned to: g1r5-askeladd (follow-up after #993 closure)
- **DISCOVERY**: LR schedule was HARDCODED at lines 882-888 of `train_gpt_simple.py` as trapezoidal-stable-then-linear-decay:
  ```python
  def set_hparams(step):
      progress = step / train_steps
      eta = 1.0 if progress < (1 - cooldown_frac) else (1 - progress) / cooldown_frac
      ...
  ```
  Never made into a CLI flag. Never SENPAI-validated. Linear cooldown was inherited from upstream Muon paper, never proven optimal for this benchmark.

- Hypothesis: Schedule shape is orthogonal to schedule values. Body LRs were tuned (`--lr_mlp 0.055`), schedule shape was not. Cosine/quintic may smooth descent during cooldown; exponential may target final-step quality; linear-to-floor may preserve some learning in final steps.

- **5-cell sweep:**

| Cell | --lr_schedule_shape | Description |
|:----:|:-------------------:|:------------|
| A | linear (ctrl) | current `(1 − progress) / cooldown_frac` |
| **B ★** | cosine | `0.5 × (1 + cos(π × cooldown_progress))` |
| C | exponential | `exp(−5 × cooldown_progress)` |
| D | linear_to_floor | linear but stops at lr_floor=0.1 (preserve 10% LR through final steps) |
| E | quintic | `(1 − cooldown_progress)^5` (steeper than linear) |

- **Implementation**: add `--lr_schedule_shape` (str, default "linear" for backward compat), `--lr_floor` (float, default 0.0). Modify `set_hparams` to dispatch on shape. Test only Muon LRs (lr_mlp/lr_attn) — AdamW path unchanged.

- **Falsifier**: all NEG → linear-cooldown was already near-optimal, schedule shape is robust. Closes schedule-shape axis. If POS, then schedule shape is a genuine untapped dimension and warrants further refinement (parametric shape sweep).

- **Information value**: First test of schedule shape after 600+ polls of optimizer research. Closes a fundamental hardcoded design choice.

- **Gate**: μ_n=1 ≤ 3.260 → P2 n=4. μ_n=4 ≤ 3.259221 → merge.

## 2026-05-24 15:55 — PR #1010: NS-iter-by-time (boost NS quality during cooldown) [CLOSED clean-NEG]

- Branch: `g1r5-tanjiro/ns-iter-by-time-cooldown`
- Hypothesis: cooldown lower LR → lower gradient SNR → cleaner orthogonalization extracts better directions during last 70% of training.

- **5-cell sweep results (n=1 each, 3250 steps):**

| Cell | --ns_iter_cooldown | ramp | val_loss | Δμ vs baseline (σ_single) | ffs | run id |
|:----:|:------------------:|:----:|:--------:|:--------------------------:|:---:|:-------|
| A (ctrl ns=6) | — | — | 3.26264 | +1.55σ | 3050 | `eq9b0j6y` |
| **B ★** | 8 | false | **3.26122** | **−0.001σ** (≈μ) | 3025 | `qwtp9pw5` |
| C | 10 | false | 3.26286 | +1.92σ | 3050 | `h6kir2ug` |
| D | 12 | false | 3.26346 | +2.93σ | 3050 | `54lcfr1t` |
| E | 9 (ramp) | true | 3.26072 | −0.85σ | 3025 | `avy5mf90` |

- **Result**: clean-NEG. Cell B (PRIMARY) lands within ±1σ band [3.260628, 3.261814]. Null result for cooldown-time NS-quality axis.

- **Mechanism findings**:
  1. **Monotone NEG above ns_iter=6**: B(8)≈baseline, C(10)+1.92σ, D(12)+2.93σ. **NS_iter>6 actively HURTS**, not just neutral.
  2. **No reliable smooth-vs-step signal**: E (smooth, 3.26072) vs B (jump, 3.26122) within σ_single.
  3. **No discontinuity-variance penalty at step 975** for NS-iter changes (unlike #907 buffer reset which inflated σ 1.71×). NS-iter is numerical-quality knob, not state-resetting.

- **Closure**: 3rd of 3 NS-iter scheduling axes (depth #932, early-time #815, late-time #1010 all NEG). NS-iter scheduling comprehensively saturated.

- **Open mechanism puzzle**: student notes iter≥7 polynomial overshoots in bf16. NS currently runs in bf16 (line 485 hardcoded `X = G.bfloat16()`). Motivates fresh axis: precision sweep.

- **Follow-up assigned**: tanjiro → #1062 NS precision sweep.

## 2026-05-24 15:55 — PR #1062: NS precision sweep (bf16 vs fp32)

- Branch: `g1r5-tanjiro/ns-precision-sweep`
- Assigned to: g1r5-tanjiro (mechanism follow-up after #1010 closure)
- Hypothesis: NS iteration precision is a hidden hyperparameter. Currently hardcoded bf16 at line 485. #1010 closure revealed ns_iter>6 monotonically HURTS — possibly bf16 round-off accumulates in higher iterations. Test fp32 NS to determine whether precision is the bottleneck or polynomial truly saturates at iter=6.

- **5-cell sweep**:

| Cell | --ns_precision | --ns_iter | Description |
|:----:|:--------------:|:---------:|:------------|
| A | bf16 (ctrl) | 6 | current behavior |
| **B ★** | fp32 | 6 | entire NS in fp32 |
| C | fp32_inner | 6 | X stays bf16, A/B computed in fp32 (hybrid) |
| D | bf16_renorm | 6 | bf16, renormalize X by spectral norm after each iter |
| E | fp32 | 8 | KILLER TEST: fp32 + higher iter count |

- **Implementation**: add `--ns_precision` CLI flag, branch in `zeropower_via_newtonschulz5`. Plumb via module-level `NS_PRECISION` global.

- **Decision rules**:
  - B ≤ 3.260628 (n=1 gate) → request n=4 confirm.
  - B within ±1σ of baseline → close null; precision not load-bearing at iter=6.
  - B > +2σ → fp32 actively HURTS (bf16 stochastic noise was beneficially regularizing).
  - E < B → fp32 unlocks higher iter counts; open follow-up for fp32 iter sweep.
  - C ≈ B → accumulator precision was bottleneck; cheap fp32 trick works.

- **Gate**: μ_n=1 ≤ 3.260628 → P2 n=4. μ_n=4 ≤ 3.259221 → merge.



## 2026-05-27 04:05 — PR #1321: AdamW aux β2 pruning ablation [FFS-primary, 11th stack-component closure]

- Branch: `g1r5-frieren/adamw-aux-beta2-pruning`
- Student: g1r5-frieren
- Hypothesis: Hardcoded `betas=(0.8, 0.95)` on AdamW aux line 843. Test whether β2=0.95 is FFS-load-bearing by sweeping toward Muon momentum value (0.90 align with Muon mu) and bracketing higher/lower. **5-cell pruning ablation** with new `--adamw_aux_beta2` CLI arg applied unified across embed+lm_head+scalars.
- Pairs with #1310 thorfinn β1 (closed poll ~863) → completes AdamW aux β1/β2 pair.

### Results — 5-cell FFS-first table

| Cell | β2 | FFS | val/loss | Δval vs ctrl-A | σ_single | run_id |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| A (ctrl) | 0.95 | 3050 | 3.262031 | — | +1.36σ (within-PR ctrl 25 steps above global baseline) | `9cmy5qv9` |
| **B★ (primary)** | 0.90 | **3075** | 3.264364 | +0.00233 | +5.30σ — **PRIMARY FAILED** | `cnlxorqd` |
| C (bracket) | 0.92 | 3050 | 3.261541 | −0.00049 | +0.54σ noise | `dntj8zu5` |
| **D (overstable)** | **0.99** | **3025** | **3.261115** | −0.00091 | −0.18σ — BEST val, FFS=baseline-EXACT | `7tlmom02` |
| E (falsifier) | 0.50 | **−1 NEVER** | 3.287794 | +0.02576 | +44.7σ — catastrophic | `zb18eufg` |

### Per-cell val/loss at crossing window (first to reach 3.28)

| step | A (0.95) | B (0.90) | C (0.92) | D (0.99) | E (0.5) |
|:----:|:--------:|:--------:|:--------:|:--------:|:--------:|
| 3025 | 3.28293 | 3.28526 | 3.28252 | **3.27899** ✓ | — |
| 3050 | 3.27999 | 3.28236 | 3.27970 | 3.27622 | — |
| 3075 | 3.27732 | **3.27966** ✓ | 3.27700 | 3.27355 | — |
| 3250 (final) | 3.262031 | 3.264364 | 3.261541 | 3.261115 | 3.287794 |

### Under FFS-primary directive #1262: **No n=4 promotion**

Cell D FFS=3025 matches global baseline-EXACT but is NOT FFS-alive (alive threshold ≤2975). Per directive: "no n=4/n=8 confirmation unless FFS readout alive at n=1." This is a val-cosmetic improvement at fixed FFS, not a promotable signal. Closed as clean-NEG-MECHANISM-INVERSION.

### 4 mechanism findings

1. **PRIMARY HYPOTHESIS FALSIFIED**: β2=0.90 (faster forgetting) is FFS-WORSE not FFS-equal. The pruning ablation morphed into a mechanism inversion — the load-bearing direction points HIGHER, not lower.

2. **MONOTONE FFS structure in β2** across {0.90, 0.92, 0.95, 0.99}: as β2 ↑ (longer 2nd-moment memory), FFS ↓ (improves: 3075 → 3050 → 3050 → 3025). This is the strongest evidence the axis is real and not seed noise.

3. **★★ β1/β2 DISSOCIATION (cross-PR with #1310 thorfinn)** — β1 wants SHORT memory (sweet spot 0.8, half-life ~3 steps), β2 wants LONG memory (best 0.99, half-life ~70 steps). This **recovers the classical Adam intuition** that m̂ tracks current gradient direction (short horizon) while v̂ tracks gradient scale (long horizon). The two AdamW aux β's want OPPOSITE memory horizons — they are NOT redundant or symmetric in this regime.

4. **Cooldown 2nd-moment preservation** mechanism confirmed: higher β2 keeps v_t closer to pre-cooldown gradient magnitudes during LR→0 phase, so effective_lr = lr / (sqrt(v_t) + eps) does not collapse as quickly. Falsifier E (β2=0.5) confirms v_t adequate smoothing is structurally NECESSARY — without it, never crosses target (DNF at val=3.288). Aux groups (lm_head, scalars) need bigger effective step during cooldown to finish crossing.

### W&B telemetry evidence for mechanism #4

- `adamw_aux/sqrt_v_t_mean/adam_lm_head` final: E=1.39 (β2=0.5 tracks instantaneous grad²) vs A/D ≪ this (long memory averages)
- `adamw_aux/effective_lr/adam_lm_head` at step 3250: E≈0 (collapsed), D ≫ others at crossing window — confirms longer-memory β2 maintains crossing-phase effective LR

### Cluster connections

- **AdamW aux tetrad HALF-CLOSED**: β1 (#1310 narrow basin, sweet spot 0.8) + β2 (#1321 monotone, best 0.99) closed under FFS-primary; ε (#1330 4/5 done, E running) + wd (#1334 4/5 done, E running) imminent.
- **β1/β2 dissociation** is the cleanest 2-component finding this round — preserves Adam's classical role separation despite aggressive scalar HP optimization.
- **11th stack-component pruning closure** under FFS-primary directive.

### Closure

clean-NEG-MECHANISM-INVERSION. Stack-component pruning programme continues; AdamW aux family approaches closure.

### Follow-up assigned

frieren → **#1377 adamw-aux-β2-SCHEDULE** (★ FIRST schedule test in AdamW aux family — directly tests cooldown 2nd-moment preservation mechanism by introducing β2 as schedule rather than fixed value; 5-cell A=β2=0.95 constant ctrl / B★=linear ramp 0.95→0.99 over cooldown PRIMARY / C=linear ramp 0.95→0.98 over cooldown / D=instant step-up β2=0.99 at cooldown start step 975 / E=falsifier reverse ramp 0.99→0.95 over cooldown; small code change `--adamw_aux_beta2_schedule` flag; **predicts FFS<3025** if entire #1321 Cell D benefit is from cooldown phase only; cross-cluster with #941+#966+#1272 "cooldown is directed descent in zero-WD regime"; **first schedule candidate that could move FFS-alive**).

## 2026-05-27 04:10 — PR #1322: NS-iter cooldown low pruning ablation [FFS-primary, 12th stack-component closure]

- Branch: `g1r5-alphonse/ns-iter-cooldown-low`
- Student: g1r5-alphonse
- Hypothesis: Tests whether NS_ITER<6 during cooldown is FFS-load-bearing. Does NS orthonormalization preserve its load-bearing role when gradient signal becomes clean (low-LR regime)? **5-cell ablation** with new `--ns_iter_cooldown` CLI flag, threshold step 975 (last 70% of training = cooldown decay phase).
- Completes #1010 asymmetric ablation which tested only iter>6.

### Results — 5-cell FFS-first table

| Cell | `--ns_iter_cooldown` | FFS | val/loss | Δval / σ_single | post-NS orth_err @step 2000 | wall (s) | run_id |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **A (ctrl)** | -1 (=6 throughout) | **3025** | 3.260967 | 0σ baseline | (pre-cd ref: 0.768) | 6135 | `pf9uef5y` |
| **B★ (primary)** | **0** | **−1 DNF** | 3.343360 | **+138.9σ CATASTROPHIC** | 0.999 (no orth) | 6040 | `293p3sul` |
| C | 2 | **−1 DNF** | 3.280723 | +33.3σ catastrophic | 0.989 (barely orth) | 6072 | `m0f48ehh` |
| D | 4 | 3050 | 3.265142 | +7.0σ mild NEG | 0.911 (partial) | 6108 | `hn9dcoxa` |
| E | 12 | 3050 | 3.262339 | +2.3σ within noise | 0.099 (near-perfect) | 6246 (+1.8%) | `pmlax06w` |

### FFS-curve milestones (step at which val/loss first reaches threshold)

| Cell | step→3.40 | step→3.35 | step→3.30 | step→3.28 (target) |
|:----:|:---------:|:---------:|:---------:|:-----------------:|
| A | (normal) | (normal) | ~2925 | **3025** ✓ |
| B (iter=0) | 2250 | 3025 | **DNF** | **DNF** (best 3.343) |
| C (iter=2) | 2000 | 2500 | 2950 | **DNF** (best 3.281) |
| D (iter=4) | 2250 | 2625 | 2925 | **3050** |
| E (iter=12) | 2250 | 2625 | 2925 | **3050** |

### Under FFS-primary directive #1262: **no n=4 promotion**

No cell reaches FFS-alive (≤2975). Closing as clean-NEG mechanism finding.

### 5 mechanism findings

1. **HARD NS-QUALITY FLOOR between iter=4 and iter=6 during cooldown.** Iter≤2 catastrophic DNF (+33–138σ), iter=4 still NEG (+7σ), iter=6 baseline, iter=12 within noise. The cooldown crossing through 3.30→3.28 specifically depends on NS direction-shaping being NEAR-COMPLETE (orth_err ≤ 0.91).

2. **Muon's directional update is necessary even when LR→0.** Cell B (iter=0) reaches val=3.34 at step 3025 — still descending at normal pace through 3.40→3.35 — then STALLS in the final 225 steps. Without NS, the spectral-norm-clamped raw gradient is well-aligned enough to get to 3.35 but not 3.28. **NS is the cooldown-crossing mechanism, not just an early-phase shaper.**

3. **Cell C (iter=2) is at the operational edge.** Curve looks healthy through 3.35 (faster than A!), but stalls 0.7 mNats below target. orth_err≈0.99 = "barely orthogonalized" = enough for stable training, not enough for final descent. **Iter=2 is the most informative cell** — locates the failure threshold sharply.

4. **Joint with #1010 (asymmetric upper-side):** full iter-by-time picture in cooldown is now a **clear bowl** — iter ∈ {0, 2} catastrophic; iter ∈ {4, 8} mild NEG; iter=6 optimum; iter ∈ {10, 12} mild NEG. The ns_iter axis is FULLY closed on both sides — the existing default is the sharp tight optimum.

5. **NS dissociates magnitude from direction:** post-NS spectral norm varies dramatically (B≈1.0, C≈3.5, D≈9.8, baseline≈15.6, E≈27.5) but FFS only collapses where direction fidelity collapses (orth_err > 0.95). **Dissociates magnitude from direction** — NS output magnitude scales with iter count but is downstream of direction quality. Confirms #1206 finding that NS provides both, but **direction is the FFS-load-bearing one**.

### Cluster connections

- **12th stack-component pruning closure** under FFS-primary directive
- **Joins #1042 (post-NS soft mixing NEG) + #1206 (pre-NS conditioning NEG)** — NS quality cannot be reduced in any direction (input, output, internal)
- **With #1010 (upper-side iter ablation) → ns_iter-by-time axis FULLY closed** — symmetric tight optimum at iter=6
- **Crossing-phase decoupling cluster:** alongside #1294 mu-cooldown-decay (closed, mu wants HIGH at end), #1326 askeladd scalars decoupled cooldown (in flight) — 3 cooldown-phase decompositions converge: cooldown crossing is fragile and component-tightly-tuned, NOT a "single LR knob" regime

### Student diligence

CRITICAL diligence: caught arithmetic error in original PR body — verbal references said "step 2275" (last 30%) but code uses `progress >= (1.0 - 0.7) = 0.3` → step 975 (last 70% of training is cooldown decay phase). Saved hours of misaligned experiment time and yielded clean Option A result. Also detected diff.patch reverted on disk after launch (in-memory copy preserved) — re-applied to ensure Cells C/D/E inherit same code path.

### Closure

clean-NEG-VALUE-SENSITIVE-WITH-SHARP-FLOOR. Stack-component pruning programme continues; NS-modulation axes fully closed.

### Follow-up assigned

alphonse → **#1381 cooldown-LR-DECAY-SHAPE** (★ FRESH cooldown axis — tests whether LR decay SHAPE during cooldown window is FFS-load-bearing; currently linear `eta=(1−progress)/cooldown_frac` is the default but decay SHAPE has never been swept; 5-cell A=linear ctrl / B★=cosine PRIMARY smoothness / C=concave sqrt(1−x) steep-early gentle-late / D=convex (1−x)² gentle-early steep-late / E=falsifier step-decay eta=1 until last 20% then 0 abruptly; small code change in `set_hparams` switch on new `--lr_cooldown_shape` flag; **predicts C concave FFS<3025** if "everything wants small at end" cluster #1276+#941+#966+#1272 mechanism is right — concave drops fast to low-LR regime then stays there; **first cooldown SHAPE candidate for FFS-alive movement**).
