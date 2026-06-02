# RESEARCH IDEAS — 2026-06-02 (post H375/H282 dedup)
# Cycle ~2700 | 227+ NULL/NEG closures | Current best: H266/PR#1669 val=3.26818 FFS=3000
# Strict merge gate: FFS < 3000 STRICTLY (Issue #1260)
# AUX optimizer family FULLY CLOSED — all fresh ideas must be mechanism-orthogonal

---

## RANKED IDEAS

---

### RANK 1 — Polar Express: Minimax-Adaptive Polar Decomposition replacing NS5

**Mechanism summary**

Replace `zeropower_via_newtonschulz5()` at lines 552-569 with the Polar Express
minimax-adaptive polar decomposition from Amsel, Persson, Musco & Gower (arxiv
2505.16932). NS5 uses fixed polynomial coefficients a=2, b=-1.5, c=0.5 across
all 12 iterations regardless of the conditioning of G. Polar Express adapts
those coefficients at each iteration via minimax optimization over the current
spectral interval, dramatically reducing residual at the same iteration count
and eliminating the fixed-coefficient assumption that underlies H287 HALLEY
(which used a different polynomial family — Halley's cubic — and is CLOSED).

The key distinction from H287 HALLEY: HALLEY replaced NS5 with a FIXED cubic
iteration. Polar Express uses ADAPTIVE coefficients at each of k iterations,
solving a minimax problem online. These are categorically different families.
HALLEY tests "can a different fixed polynomial beat NS5?" Polar Express tests
"can adapting the polynomial to the current gradient matrix beat fixed
coefficients?" The mechanism is orthogonal.

**Why it might help**

NS5's fixed a/b/c were hand-tuned for a "typical" gradient conditioning regime.
Block attention and MLP projection matrices develop distinct singular-value
structures as training progresses — especially under the H266 stack with AGC +
scale_invariant mode. Adaptive coefficients respond to actual spectral structure
per step, potentially producing a cleaner polar factor (closer to true orthogonal
projection) with fewer wasted iterations. The paper shows direct validation loss
improvement on GPT-2 training with Muon using Polar Express vs NS5.

**Orthogonality reasoning**

This is a DROP-IN replacement at lines 552-569 only. It does not touch:
- AUX optimizer (AdamW) — zero change
- MuLoCo outer loop — zero change
- Polyak EMA — zero change
- AGC — zero change
- scale_invariant_update_ — zero change
- muon_update() momentum integration — only line 575 (the call) changes

H287 HALLEY is the closest closed relative and tested a different polynomial
family with fixed coefficients. That closure rules out "a different fixed-
coefficient polynomial" but does NOT rule out "a polynomial whose coefficients
adapt to the current matrix." The mechanisms are logically distinct.

**LoC estimate**

- New function `zeropower_via_polar_express()`: ~35 lines replacing lines 552-569
  (18 lines). Net +17 lines.
- Modify `muon_update()` at line 575: change `zeropower_via_newtonschulz5(update)`
  to call the new function. 1 line change.
- Add 3 parse_args entries (lines 31-122): `--polar_express_iters` (default=12
  to match NS5), `--polar_express_mode` (choices=["ns5","polar_express"],
  default="ns5" for arm_a control), `--polar_express_epsilon` (default=1e-7).
  ~6 lines.
- TOTAL: ~24 net new lines across 3 sections.

**3-arm chain design**

- arm_a: CTRL — sentinel `polar_express_mode=ns5` (default), val=baseline, FFS=3000
- arm_b: POLAR_EXPRESS_DEFAULT — `polar_express_mode=polar_express`,
  `polar_express_iters=12` (same iteration budget as NS5)
- arm_c: POLAR_EXPRESS_FEWER — `polar_express_mode=polar_express`,
  `polar_express_iters=8` (same quality at lower compute — tests if adaptive
  convergence is faster than fixed 12 iterations)

**Decision rules**

- arm_b or arm_c beats FFS < 3000 STRICTLY → merge arm_b or best arm
- arm_b/arm_c TIE FFS=3000 but val improves > 0.001 (> 1σ) → SEND BACK for
  iteration count / epsilon sweep at winning config
- arm_b/arm_c TIE FFS=3000 and val neutral → CLOSE (mechanism doesn't help
  this stack)
- arm_b catastrophic (FFS=-1 or val ≥ 3.28+0.01) → implies polar express
  instability in bfloat16 — CLOSE; note bfloat16 finite-precision issue

**Risks**

1. H287 HALLEY was catastrophic (+5.9σ, FFS=-1). If Polar Express also diverges
   in bfloat16, it may be a deeper NS5-family issue. Mitigation: arm_b/c use
   epsilon=1e-7 matching NS5's current normalization guard. Also the paper
   specifically addresses bfloat16 stability.
2. Wall-clock cost: adaptive minimax requires solving a small 2x2 optimization
   per iteration. Should be negligible vs matmul cost but the torch.compile
   boundary at `muon_update()` (line 571) may need adjustment if the adaptive
   step uses Python-level branching.
3. The paper's GPT-2 result may not transfer directly if the H266 stack's
   scale_invariant mode + F-norm preservation changes the conditioning structure
   that Polar Express was designed to exploit.

**WIN probability: 30%**

H287 HALLEY closed "fixed polynomial variant" but left "adaptive polynomial"
open. External paper shows improvement specifically on Muon+GPT. The mechanism
is clean and well-grounded. Lower probability because cycle ~2700 is heavily
saturated and NS5 alternatives have a mixed track record in this stack.

**Implementation reference**

Amsel, Persson, Musco, Gower (2025). "Polar Express: Minimax Optimal Polynomial
Approximation for Scaling Muon." arXiv:2505.16932.
Key equations: Section 3 (minimax polynomial), Section 4 (algorithm), Appendix A
(bfloat16 analysis). The core update per iteration:
  - Compute optimal (a_k, b_k) by solving 1D minimax on spectral interval [l, u]
  - Apply: A = X @ X.T; B = b_k * A + c_k * A @ A; X = a_k * X + B @ X
  - Update spectral bounds via recurrence

---

### RANK 2 — Per-Param Outer Momentum: Body vs Aux Differentiated Outer LR/Momentum

**Mechanism summary**

The MuLoCo outer step at lines 1327-1354 applies a SINGLE global `args.outer_lr`
(0.7) and `args.outer_momentum` (0.5) uniformly to ALL named parameters: embed
weights, lm_head, scalar params, AND block 2D weights (body). This is a
confirmed untested axis — the outer loop iterates `for n, p in
model.named_parameters()` and uses the same scalar values regardless of which
parameter group the parameter belongs to.

The body params (block 2D weights, updated by MuonH with scale_invariant mode
and F-norm preservation) have fundamentally different geometry from aux params
(embed, lm_head, scalars updated by AdamW). Applying the same outer trajectory
force to both ignores their different update scales and dynamics. This hypothesis
tests whether giving each group an appropriate outer correction improves FFS.

**Orthogonality reasoning**

The closed outer-loop axes are:
- H289: outer momentum SCHEDULE (time-varying scalar) — still open but orthogonal
- H374: WSD schedule for sync_interval — orthogonal (applies to scheduling, not
  per-group values)
- All other closed outer axes (momentum bracket, outer_lr test, LoCo-Adam FORM,
  anchor smoothing, etc.) tested GLOBAL scalar values or FORM changes

Per-group outer (body vs aux with different lr/momentum) is orthogonal to all
of these because it changes the PER-PARAMETER ALLOCATION of outer correction
force, not the global schedule or form. It has never been tested at any cycle.

**LoC estimate**

- 4 new parse_args entries at lines 31-122:
  `--body_outer_lr` (default=-1.0 sentinel, -1 means use outer_lr),
  `--body_outer_momentum` (default=-1.0 sentinel),
  `--aux_outer_lr` (default=-1.0 sentinel),
  `--aux_outer_momentum` (default=-1.0 sentinel)
  ~8 lines

- Build body param name set before outer loop (near line 1054):
  `_body_param_names = {n for n, p in model.blocks.named_parameters()
   if p.ndim >= 2}` then add a set comprehension with "blocks." prefix fix.
  ~4 lines

- Modify the inner loop at lines 1333-1343:
  Add 2 lines to look up per-group lr/momentum based on whether `n` is in
  body set, then use those values instead of `args.outer_lr`/`args.outer_momentum`.
  ~8 lines, replacing the existing 4-line update block

- TOTAL: ~20 net new lines across 2 sections.

**3-arm chain design**

arm_a: CTRL — sentinel `body_outer_lr=-1, body_outer_momentum=-1,
  aux_outer_lr=-1, aux_outer_momentum=-1` → all use defaults outer_lr=0.7,
  outer_momentum=0.5. Bitwise-identical to H266.

arm_b: BODY_STRONGER — `body_outer_lr=1.4, body_outer_momentum=0.5,
  aux_outer_lr=0.7, aux_outer_momentum=0.5`. Body gets 2× the outer correction
  force; aux unchanged. Hypothesis: body 2D weights with scale_invariant mode
  benefit from stronger outer trajectory pull since MuonH inner dynamics are
  more aggressive (AGC + F-norm preservation).

arm_c: BODY_LIGHTER_AUX_STRONGER — `body_outer_lr=0.35, body_outer_momentum=0.5,
  aux_outer_lr=1.4, aux_outer_momentum=0.5`. Inverted allocation. Tests whether
  the outer correction is currently over-correcting body (F-norm preservation
  already controls body geometry) and under-correcting aux (AdamW can drift
  without outer regularization).

**Decision rules**

- Either arm beats FFS < 3000 STRICTLY → merge; SEND BACK for orthogonal sweep
  of the other per-param axis (momentum ratio)
- TIE FFS=3000 but val improves > 1σ on better arm → SEND BACK for
  interpolation between arm_b and arm_c allocation ratios
- Both arms TIE FFS=3000, val neutral → extend to momentum differentiation
  arm (body_outer_momentum vs aux_outer_momentum sweep); 30% probability this
  matters even when lr split doesn't
- Both arms clearly worse (val ≥ 3.271, FFS ≥ 3050) → CLOSE; record that
  per-param outer gradient force is not the differentiating factor for body/aux
- Catastrophic (val ≥ 3.29 or FFS=-1) → very unlikely given the sentinel
  arm_a guard; if catastrophic, implies a param-name set bug — review code

**Risks**

1. The body 2D params include all block attention and MLP projection matrices.
   The "body" set construction must correctly include `blocks.N.attn.proj.weight`,
   `blocks.N.mlp.fc.weight`, `blocks.N.mlp.proj.weight` etc. Param name
   enumeration bug would silently fall back to aux treatment.
2. MuonH scale_invariant mode already preserves F-norm after each inner step.
   The outer step (which happens every 30 steps) TEMPORARILY breaks the sphere
   constraint — this is existing behavior. A stronger body outer_lr would
   increase this perturbation frequency. The next MuonH-SI step re-normalizes,
   which is expected behavior per the code comment at line 1323-1326 ("Acceptable
   behavior — the goal is trajectory smoothing, not strict norm invariance").
3. The outer loop also processes embed, lm_head, and scalar params. These use
   AdamW inner dynamics and have no F-norm constraint. If aux_outer_lr is raised
   too high, it can destabilize embed training. arm_c uses 1.4× which is within
   the range of the outer_lr bracket tests (CLOSED at H266 stack).

**WIN probability: 25%**

The mechanism is untested and well-grounded in the different geometric dynamics
of body vs aux params. However, the outer loop already shows mild signal
(delta_rms / velocity_rms logged) and its global scalar was tuned empirically
as H266's outer_lr=0.7. The saturation of the cycle ~2700 portfolio makes any
further improvement unlikely but non-zero. Per-param differentiation is a
genuine untested axis with a clear physical motivation.

---

### RANK 3 — Outer Velocity Reset at Cooldown Entry

**Mechanism summary**

Reset `outer_velocity` buffer to zeros when training enters the cooldown phase
(step >= train_steps - cooldown_steps). Analogous to H170 which reset the AUX
AdamW v_t (second moment) buffer at cooldown entry and was a MERGED winner.
The outer velocity buffer accumulates momentum over the full 3325-step training
run. At cooldown entry, the LR begins decreasing rapidly; a stale high-velocity
outer buffer fights the cooldown's intent to sharpen toward a narrow minimum.

**Orthogonality reasoning**

H170 reset the AUX inner optimizer state (v_t second moment). This proposal
resets the OUTER optimizer state (outer_velocity momentum buffer). Different
optimizer, different buffer, different mechanism (outer trajectory vs inner
curvature estimate). Genuinely untested. The outer velocity buffer is initialized
at line 1059 (`outer_velocity = {n: torch.zeros_like(p) for n...}`) and is
never reset during training in the current code.

**LoC estimate**

- 1 parse_args entry: `--outer_reset_at_cooldown` bool flag default=False. ~2 lines.
- ~6 lines in the outer step block: detect cooldown_entry flag and zero the
  outer_velocity buffers once. Add a cooldown_entered tracking bool near line
  1054.
- TOTAL: ~10 lines.

**3-arm chain design**

arm_a: CTRL — `outer_reset_at_cooldown=False`, baseline H266 behavior
arm_b: OUTER_RESET — `outer_reset_at_cooldown=True`, reset all outer_velocity
  buffers when step crosses (train_steps - cooldown_steps)
arm_c: OUTER_RESET_PARTIAL — reset only body (2D block) velocity, keep aux
  velocity. Tests whether body cooldown sharpening is the primary beneficiary.

**Decision rules**

- FFS < 3000 STRICTLY on arm_b or c → merge
- TIE but val improves → SEND BACK to test cooldown onset timing (reset at
  -steps earlier)
- Both arms neutral → CLOSE; cooldown reset doesn't matter for outer dynamics

**Risks**

1. H170 (AUX v_t reset) was a merge winner at an earlier stack. But the
   mechanism has already been partially absorbed — the current H266 stack was
   built on top of it. Adding outer reset may compound with already-optimal
   cooldown tuning and produce a diminishing-returns null.
2. Outer velocity reset is a 1-event intervention. If the outer loop fires every
   30 steps and cooldown is ~662 steps, the reset affects ~22 outer sync events.
   If the outer velocity was benign throughout cooldown, resetting adds noise.

**WIN probability: 20%**

Strong mechanistic analogy to H170 (a merge winner), but the outer loop is
lower-amplitude and the cooldown sharpening mechanisms are already well-tuned.
Low LoC with clean diagnostic value.

---

### RANK 4 — WSD-Scheduled Outer Sync Interval

**Mechanism summary**

Schedule the outer sync_interval using a warmup-stable-decay pattern: start
at sync_interval=60 (sparse outer corrections during early unstable training),
hold at 30 (baseline) during the stable phase, then tighten to sync_interval=15
during cooldown (denser outer corrections during the sharp convergence phase).

H374 WSD schedule was applied to the BODY inner MuonH LR and is CLOSED. This
applies WSD scheduling to the OUTER sync_interval, which is a categorically
different axis: it controls the FREQUENCY of outer trajectory corrections, not
the learning rate.

**Orthogonality reasoning**

sync_interval VALUE tests (various scalar values) were closed. The TIME-VARYING
schedule of sync_interval has not been tested. The mechanism is: early training
benefits from less outer interference (model is far from optimum, outer
corrections can add noise); late training/cooldown benefits from more frequent
outer corrections (trajectory smoothing during the convergence phase). This
is a scheduling idea, not a value idea.

**LoC estimate**

- 3 parse_args entries: `--sync_interval_warmup` (default=60),
  `--sync_interval_stable` (default=30, matches current),
  `--sync_interval_cooldown` (default=15).
  ~6 lines.
- Replace the fixed `args.sync_interval` in the outer step condition at line
  1327 with a computed value based on current step/phase. ~5 lines.
- TOTAL: ~12 lines.

**3-arm chain design**

arm_a: CTRL — sync_interval_warmup=30, sync_interval_stable=30,
  sync_interval_cooldown=30 (baseline)
arm_b: WSD_SYNC — warmup=60, stable=30, cooldown=15 (hypothesis direction)
arm_c: WSD_SYNC_EXTREME — warmup=90, stable=30, cooldown=10 (more aggressive)

**WIN probability: 18%**

Mechanism is plausible but the outer loop's magnitude is already small and the
sync_interval VALUE axis was explored without much signal. The frequency schedule
is orthogonal but may not be load-bearing.

---

### RANK 5 — Cross-Axis AUX Second Moment Injection into BODY Step Size

**Mechanism summary**

Inject the AUX AdamW's per-parameter second moment estimate (v_t, the
exponential moving average of squared gradients) as a scaling signal into
the BODY MuonH step size. Concretely: instead of MuonH applying a fixed
`scale_invariant_update_()` at a uniform lr=args.muonh_lr, use the AUX v_t
(for embed, lm_head, scalars) or a derived signal to adaptively scale the
body update.

More concretely: for each body 2D weight matrix, compute the mean v_t from
the corresponding AUX group (or use a shared running scalar) and use
sqrt(v_t) to scale the polar-factor step. This creates a cross-axis adaptive
signal that links AUX curvature information into BODY update magnitude.

**Orthogonality reasoning**

All AUX optimizer family axes are CLOSED (AdaBelief, AdEMAMix, Lion etc), but
those closures were about REPLACING AdamW with a different optimizer in the
AUX role. This hypothesis keeps AdamW as AUX unchanged and only reads v_t from
the AUX state to inform the BODY step. The mechanism is a CROSS-AXIS COUPLING,
not an AUX replacement. This axis has never been tested.

**LoC estimate**

The AUX optimizer state (v_t) lives in `optimizer1.state[p]["exp_avg_sq"]` after
the first step. The body update is applied inside MuonH.step() at lines 664-753.
The cleanest injection point is after `muon_update()` returns the polar factor
update and before `scale_invariant_update_()` applies it. This requires threading
a scalar signal from optimizer1 state into optimizer2.step(). ~30 LoC.

**3-arm chain design**

arm_a: CTRL
arm_b: CROSS_AUX_INJECT_GLOBAL — compute mean sqrt(v_t) across all AUX params
  at each step and pass as a scaling multiplier to MuonH update
arm_c: CROSS_AUX_INJECT_LAYERWISE — use per-layer (block-level) AUX v_t signal

**WIN probability: 15%**

The mechanism is novel and orthogonal but the AUX optimizer governs fundamentally
different parameter types (embed/lm_head/scalars) from BODY (2D block weights).
The signal transfer may be noisy or misleading. High implementation risk (cross-
optimizer state access during training loop). The scale_invariant mode already
handles step-size normalization for body, reducing the need for external scaling.

---

### RANK 6 — Outer Nesterov Warm Restart (SGDR-style for Outer Velocity)

**Mechanism summary**

Periodically reset the outer_velocity buffers on a cosine-restart schedule
(e.g., every 500 steps), analogous to SGDR (Loshchilov & Hutter 2017) applied
to the outer loop momentum rather than the inner LR. Each restart allows the
outer trajectory to take a fresh direction. Between restarts, outer momentum
accumulates and provides trajectory smoothing.

**Orthogonality reasoning**

SGDR has been tested for the INNER optimizer LR schedule (schedule axes all
closed). Applying SGDR-style restarts to the OUTER momentum buffer is distinct:
it's not a LR schedule but a MOMENTUM STATE reset schedule. No outer momentum
restart axis has been tested.

**LoC estimate**

- 2 parse_args entries: `--outer_restart_period` (default=0 to disable),
  `--outer_restart_decay` (default=1.0, multiplier on restart amplitude)
- ~8 lines to add restart detection and zero outer_velocity at restart points.
- TOTAL: ~12 lines.

**WIN probability: 12%**

Warm restarts for inner LR had limited impact in this stack. The outer loop
is already sparse (every 30 steps). Restarts may not survive the heavy
canalization pressure of the H266 stack.

---

## SUMMARY TABLE

| Rank | Hypothesis | Mechanism axis | LoC | WIN% | FFS gate path |
|------|-----------|---------------|-----|------|--------------|
| 1 | Polar Express NS5 replacement | BODY preconditioner quality | ~24 | 30% | Direct improvement in polar factor → faster convergence → lower FFS |
| 2 | Per-param outer LR/momentum | OUTER per-group allocation | ~20 | 25% | Better body/aux-differentiated trajectory smoothing → lower FFS |
| 3 | Outer velocity reset at cooldown | OUTER state management | ~10 | 20% | Stale outer momentum removal → cleaner cooldown convergence |
| 4 | WSD-scheduled sync_interval | OUTER frequency scheduling | ~12 | 18% | Adaptive outer correction frequency → less interference early, more late |
| 5 | Cross-axis AUX→BODY injection | CROSS-AXIS coupling | ~30 | 15% | AUX curvature information improves BODY step scaling |
| 6 | Outer SGDR warm restarts | OUTER momentum restart | ~12 | 12% | Periodic trajectory reset prevents outer momentum stagnation |

---

## ASSIGNMENT RECOMMENDATION

**Student 1 (fern, currently assigned H379 AdaBelief AUX):** After H379 closes,
assign Rank 1 — Polar Express. This is the highest-probability fresh mechanism
with strong external paper evidence directly on Muon+GPT and clean orthogonality
from H287 HALLEY.

**Student 2 (next idle student):** Assign Rank 2 — Per-param outer LR/momentum.
Confirmed untested axis, low LoC, clean 3-arm design, directly testable.

**Contingency:** If fern's H379 AdaBelief AUX produces a surprising positive
result (TIE or better), the Rank 5 cross-axis injection idea becomes more
interesting as a follow-up. If H379 is catastrophic (as predicted by the
H282/H368/H375 AUX family pattern), that further closes the AUX-replacement
space and confirms Ranks 1-4 (all OUTER/BODY/preconditioner axes) as the
remaining productive territory.

---
## GENERATION METADATA
Generated: 2026-06-02
Cycle: ~2700
Closed axes verified against: experiment_log/results_table_2026-06-02_02-20.md (456 PRs)
Primary metric contract: speedrun/final_first_step_to_target (FFS), lower is better, strict gate FFS < 3000
Baseline: PR #1669 H266, val=3.26818, FFS=3000
BANNED: primeintellect.ai/auto-nanogpt and github.com/PrimeIntellect-ai/experiments-autonomous-speedrunning
