# Research Ideas — 2026-05-29 13:37Z

Generated for tanjiro (PR #1617 closed NO MERGE) and thorfinn (PR #1586 closed NO MERGE).
Both students returning to idle. R5 baseline: PR #1533, μ_4(FFS_ema)=2912.5, σ_4=25.
Merge gate: μ_4(FFS_ema) ≤ 2887.5. FFS-alive (n=1) gate: ≤ 2975.

Mandatory R5 stack flags for all experiments:
`--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine --ema_eval_decay 0.99`

---

## Closed axes (do not re-propose)

SOAP scalar HPs (eps, β2 static, β2 decoupled, exp_avg_sq scaling, Q_row/Q_col asym,
trust-gate static+schedule), PRECOND_FREQ static value, wd_mlp sweep, wd_attn (nezuko
#1676 in-flight), lr_attn fine-tune (frieren #1677 in-flight), mu_mlp/mu_attn decoupling,
all 5 Muon body wrappers (AGC, QHM, GC, Lookahead, Cautious), NS warm-start, NS Bernstein
coefficients, depth-adaptive NS, pre-NS grad-norm conditioning, pre-NS noise, LAMB, NS
aspect-ratio exponent, aux cooldown decoupling, aux LR warmup, body momentum decoupling,
LogitNorm, Orthogonal QKV init, SOAP low-rank eigenbasis, Schedule-Free Muon, SPAM,
per-block LR decay, body LR warmup, Heavy-Ball vs Nesterov, AdEMAMix/Lion/AdaBelief/Sophia-G
aux, multi-timescale EMA combination, LR floor, cooldown_frac axis, β1/β2 per-group aux,
per-group AdamW aux decoupling cluster.

## In-flight (do not duplicate)

- #1689 alphonse: SOAP Gram-matrix β₂ warmup schedule
- #1654 fern: SOAP adaptive eigenbasis refresh (off-diagonal staleness)
- #1664 edward: per-class Muon cooldown SHAPE (n=1 POSITIVE, Cell D in progress)
- #1659 askeladd: per-group EMA-eval decay decoupling
- #1676 nezuko: wd_attn fine re-tune
- #1677 frieren: lr_attn fine re-tune

---

## Ranked Hypotheses

Ranked by: expected FFS impact × novelty × tractability.

---

### Hypothesis 1 (HIGHEST PRIORITY): Muon body momentum VALUE sweep

**Name**: `muon-mu-value-sweep`

**Mechanism**: Shared Muon momentum coefficient `mu` controls the EMA blend of orthogonalized
gradients across both MLP and attn groups. The R5 stack inherited `mu=0.95` from earlier tuning,
but that value was never re-swept under the full R5 stack (SOAP-attn, ns_iter=6, ema_eval,
cosine cooldown, depth_init_mode musoft). Mu controls effective gradient memory length: lower
mu = shorter memory, faster adaptation, higher noise; higher mu = longer memory, slower adaptation,
lower noise. With SOAP preconditioning now active on attn, the gradient curvature landscape seen
by Muon's momentum accumulator has changed — the optimal mu may have shifted.

**Motivation**: The mu cooldown axis is closed (#1294 DOWN, #1345 UP), but that tested *scheduling*
mu during cooldown, not the absolute scalar value of mu throughout training. These are mechanistically
distinct: a schedule changes the memory length during a specific phase, a value change shifts the
entire training trajectory. The closed memory says "mu=0.95 is local optimum, cooldown
signal-limited" but does not exclude that the R5-stack-specific optimum differs from 0.95. With
edward's cooldown-SHAPE experiment showing FFS sensitivity to LR-schedule shape, there is reason
to believe the interaction between momentum and schedule shape has not been fully explored.

**5-cell sweep design**:
- Cell A (ctrl): `--mu 0.95` (baseline)
- Cell B: `--mu 0.90`
- Cell C: `--mu 0.92`
- Cell D: `--mu 0.97`
- Cell E: `--mu 0.85` (aggressive falsifier — short memory)

All cells use full R5 stack. `--mu` sets the shared `mu` arg (check train_gpt_simple.py arg
`--mu`, default 0.95, which sets `muon_momentum` for both mlp and attn Muon groups).

**Predicted FFS direction**: B or C likely FFS-positive (slightly lower mu reduces gradient
memory mismatch under SOAP-preconditioned curvature); E likely FFS-negative (too short).

**Kill gate**: If Cell B FFS_ema > 2950 and Cell C FFS_ema > 2950 at n=1, close. If any cell
shows val/loss divergence above 3.5 at step 2000, close immediately.

**Step count**: 3250 (R5 standard). n=1 screening first, n=4 only if B or C hits FFS-alive gate ≤ 2975.

---

### Hypothesis 2: EMA-eval decay VALUE fine-sweep

**Name**: `ema-eval-decay-value-sweep`

**Mechanism**: `--ema_eval_decay 0.99` sets the EMA coefficient for the shadow parameter copy
evaluated at validation time. This controls the smoothing horizon: τ = 1/(1-0.99) = 100 steps.
At 3250 training steps with validation every ~125 steps, a 100-step horizon means the EMA shadow
is dominated by the last ~3% of training. A faster decay (e.g. 0.97, τ≈33 steps) would track
recent weights more aggressively; a slower decay (e.g. 0.995, τ≈200 steps) would average across
a wider window. The FFS-positive mechanism of EMA-eval (#1533 merged) relies on the shadow model
being smoother than live params — but the optimal smoothing scale was not swept; 0.99 was chosen
heuristically.

**Motivation**: Per-group EMA-eval decay decoupling (#1659 askeladd) is in-flight and tests
*splitting* decay between groups. This is a different question: what is the optimal *global*
decay value? These are orthogonal — decoupling can be layered on top of whatever global optimum
is found here. The interaction with the cosine cooldown schedule (which compresses late-training
weight movement) makes the optimal horizon non-obvious: a slower decay might capture more
cooldown-phase smoothing, a faster one might track the sharp final descent better.

**5-cell sweep design**:
- Cell A (ctrl): `--ema_eval_decay 0.99` (baseline)
- Cell B: `--ema_eval_decay 0.995`
- Cell C: `--ema_eval_decay 0.993`
- Cell D: `--ema_eval_decay 0.97`
- Cell E: `--ema_eval_decay 0.985`

All cells use full R5 stack.

**Predicted FFS direction**: B likely FFS-positive (longer horizon captures more cooldown
smoothing); D likely FFS-negative (too fast, noisy). E is the "sweet spot" falsifier.

**Kill gate**: If Cell B FFS_ema > 2950 and Cell E FFS_ema > 2950 at n=1, close. Watch
val/loss gap between ema-eval and live-eval: if ema-eval consistently worse than live, close
(EMA is degrading rather than smoothing).

**Step count**: 3250 (R5 standard). n=1 screening first, n=4 only if a cell hits FFS-alive gate.

---

### Hypothesis 3: NS iteration count fine-sweep under SOAP context

**Name**: `ns-iter-under-soap-sweep`

**Mechanism**: Newton-Schulz orthogonalization approximates the matrix sign function iteratively.
`--ns_iter 6` was chosen in R5 stack tuning but the survey of what ns_iter does in the *presence
of SOAP preconditioning on attn* has not been done. SOAP applies a Kronecker-factor preconditioner
to attn gradients before they reach Muon's NS step; this changes the effective condition number
and spectral distribution that NS is operating on. With a well-conditioned input (already shaped
by SOAP), fewer NS iterations may suffice for attn — and the extra iterations may introduce
unnecessary numerical noise. Conversely, for MLP (no SOAP), the benefit of higher ns_iter may
be different. Since `--ns_iter` is a global flag, this sweep tests whether the combined system
favors a different global count than the R5-tuned 6.

**Motivation**: The prior ns_iter sweeps (if any) occurred before the full R5 stack was
established. Under the SOAP+Muon combined stack, the gradient spectral profile entering NS is
qualitatively different. This is a cheap, clean, single-integer sweep with a clear mechanism.

**5-cell sweep design**:
- Cell A (ctrl): `--ns_iter 6` (R5 baseline)
- Cell B: `--ns_iter 4`
- Cell C: `--ns_iter 5`
- Cell D: `--ns_iter 7`
- Cell E: `--ns_iter 3` (aggressive falsifier — under-orthogonalization)

All cells use full R5 stack.

**Predicted FFS direction**: B or C potentially FFS-positive if SOAP pre-conditions well enough
that fewer iterations suffice (lower compute per step, same effective update quality); E likely
FFS-negative (insufficient orthogonalization).

**Kill gate**: If Cell B FFS_ema > 2950 and Cell C FFS_ema > 2950 at n=1, close. If any cell
shows gradient norm explosion (global_norm > 10x baseline at step 500), close immediately.

**Step count**: 3250 (R5 standard). n=1 screening first.

---

### Hypothesis 4: SOAP PRECOND_FREQ phase-adaptive schedule

**Name**: `soap-precond-freq-schedule`

**Mechanism**: SOAP recomputes eigenbases every `PRECOND_FREQ=16` steps uniformly throughout
training. However, the Gram matrices `row_gg` and `col_gg` converge quickly early in training
(high gradient diversity, rapid spectral change) then stabilize. Late training — especially
during cosine cooldown — has much lower effective gradient diversity; the eigenbasis becomes
nearly stationary. A phase-adaptive schedule: frequent updates early (PRECOND_FREQ=8 during
first 50% of training) then less frequent (PRECOND_FREQ=32 or 64 during cooldown), could
reduce eigenbasis compute during cooldown while maintaining adaptation speed early. This is
mechanistically distinct from the static value sweep (#1617, just closed) and from the staleness
detector (#1654, in-flight) — it is a deterministic phase schedule, not a value change, not an
adaptive threshold.

**Motivation**: #1617 showed that PRECOND_FREQ=8 static was sub-σ FFS-positive at n=4 (not
mergeable). The mechanism was load-bearing but effect size small as a static change. A
*phase-adaptive* schedule might amplify the early-phase benefit of higher frequency while
avoiding the late-phase overhead cost and potential eigenbasis noise during cooldown.

**5-cell sweep design**:
- Cell A (ctrl): `PRECOND_FREQ=16` constant (baseline — hardcoded, requires code patch)
- Cell B: `PRECOND_FREQ=8` for steps 0→1625, then `PRECOND_FREQ=32` for steps 1625→3250
- Cell C: `PRECOND_FREQ=8` for steps 0→1950 (60%), then `PRECOND_FREQ=32` for remainder
- Cell D: `PRECOND_FREQ=16` for steps 0→2275 (70%), then `PRECOND_FREQ=64` for cooldown
- Cell E: `PRECOND_FREQ=8` for steps 0→1625, then `PRECOND_FREQ=16` for remainder (mild)

Implementation: requires adding `--precond_freq_early` / `--precond_freq_late` / `--precond_freq_switch_step` args and a step-conditional in the SOAP update loop. Student must implement in `train_gpt_simple.py`.

**Predicted FFS direction**: B or E likely FFS-positive (frequent early eigenbasis updates
capture fast-changing curvature; reduced late-phase refresh avoids stale-direction noise during
cooldown). D likely neutral-to-negative (cooldown at freq=64 may diverge eigenbasis too long).

**Kill gate**: If Cell B FFS_ema > 2950 and Cell E FFS_ema > 2950 at n=1, close. Inspect
val/loss vs live-param loss gap during cooldown — if ema diverges from live, the schedule is
disrupting smoothness.

**Step count**: 3250 (R5 standard). n=1 screening first.

---

### Hypothesis 5: lr_scalars VALUE fine-tune under R5 stack

**Name**: `lr-scalars-r5-fine-tune`

**Mechanism**: `--lr_scalars 0.03` was first merged in #571 and confirmed load-bearing in #1275,
but those experiments predate the full R5 stack (ema_eval, depth_init_mode musoft, cosine
cooldown, ns_iter 6, soap_attn). The AdamW auxiliary optimizer applies this LR to scalar params
(LN gains, biases) and embedding table. Under `--depth_init_mode musoft`, the residual
projection initialization is scaled down by √L, which changes the relative scale of scalar vs
body parameters throughout training. The optimal scalar LR may have shifted under this new
initialization regime. This is an exploitation sweep close to a known FFS-load-bearing axis,
with a concrete mechanism for why the optimum may have drifted.

**Motivation**: All prior lr_scalars evidence predates depth_init_mode musoft and ema_eval. The
R5 stack is the first configuration that combines all five features simultaneously. In particular,
the LN gains (controlled by lr_scalars) interact with musoft's residual scaling: if musoft
reduces residual magnitudes, LN gains must compensate more, and the optimal LR for that
compensation may be higher.

**5-cell sweep design**:
- Cell A (ctrl): `--lr_scalars 0.03` (R5 baseline)
- Cell B: `--lr_scalars 0.04`
- Cell C: `--lr_scalars 0.025`
- Cell D: `--lr_scalars 0.05`
- Cell E: `--lr_scalars 0.02`

All cells use full R5 stack.

**Predicted FFS direction**: B likely FFS-positive (LN gains need higher LR under reduced
residual magnitudes from musoft); D cautious (may overshoot LN adaptation); E likely
FFS-negative (under-adapts scalars).

**Kill gate**: If Cell B FFS_ema > 2950 and Cell C FFS_ema > 2950 at n=1, close. If any cell
shows LN collapse (weight/rms below 0.1 for LN params or above 10.0), close immediately.

**Step count**: 3250 (R5 standard). n=1 screening first, n=4 only if a cell hits FFS-alive gate.

---

### Hypothesis 6 (SPECULATIVE): SOAP Gram matrix initialization from gradient variance

**Name**: `soap-gram-warm-init`

**Mechanism**: SOAP initializes `row_gg` and `col_gg` (the Kronecker-factor Gram matrices) to
the identity matrix. This means the preconditioner starts as the identity (no preconditioning)
and only becomes informative after `PRECOND_FREQ * (1/(1-SOAP_BETA2))` = 16 * 10 = ~160 steps
of EMA accumulation. During those first ~160 steps, SOAP attn updates are effectively
unpreconditioned AdamW — wasting early curvature information. A warm initialization strategy
would set `row_gg` and `col_gg` at step 0 to diagonal matrices scaled by the per-row and
per-column gradient variance estimated over a mini-batch, giving the preconditioner a head start.
This is distinct from #1689 alphonse (β₂ warmup schedule, which controls EMA speed) and #1654
fern (staleness-based refresh, which controls refresh frequency).

**Motivation**: The first 160 steps of training under SOAP include the steepest gradient descent
(highest loss, fastest weight movement). Starting with an informed preconditioner could accelerate
this critical early phase. The mechanism is well-supported in quasi-Newton literature: Quasi-Newton
methods with good initial Hessian estimates converge faster. The risk is that a poorly chosen
initial estimate could degrade early updates.

**5-cell sweep design**:
- Cell A (ctrl): identity init (current baseline)
- Cell B: diagonal init from single-batch grad variance (row: mean of squared row-grads, col: mean of squared col-grads) computed at step 0 before first update
- Cell C: diagonal init scaled by 0.5 × grad variance (conservative warm start)
- Cell D: diagonal init scaled by 2.0 × grad variance (aggressive warm start)
- Cell E: random orthogonal init (Q,R decomposition of random Gaussian — falsifier, no prior info)

Implementation: requires modifying SOAP's `__init__` to optionally accept a pre-computed
gradient for warm init, or computing it inline during the first forward-backward pass before
the first `step()` call. Student must implement in `train_gpt_simple.py`.

**Predicted FFS direction**: B likely mildly FFS-positive (informed start shortens warm-up
transient); E likely FFS-negative (random init adds noise); C/D flanking B.

**Kill gate**: If Cell B FFS_ema > 2950 at n=1, close. If cell B shows no val/loss advantage
over ctrl in first 500 steps (where the warm-init benefit should be most visible), close.

**Step count**: 3250 (R5 standard). n=1 screening first. This is speculative (no direct prior
evidence in this repo) — apply a tighter n=1 gate.

---

## Assignment recommendation

**Tanjiro** (returning from PRECOND_FREQ static sweep): Assign **Hypothesis 4
(soap-precond-freq-schedule)**. Motivation: tanjiro just ran the static PRECOND_FREQ sweep and
has the most intuition for how SOAP eigenbasis refresh behaves. The phase-adaptive schedule is
the natural next step given that static=8 showed sub-σ positive signal. Tanjiro will understand
the mechanism immediately and implement the schedule cleanly.

**Thorfinn** (returning from wd_mlp sweep): Assign **Hypothesis 1 (muon-mu-value-sweep)**.
Motivation: mu sweep is the highest-priority hypothesis (rank 1), requires no code changes
(existing `--mu` arg), and is a clean single-integer sweep. Thorfinn can run it immediately
without implementation risk. The wd_mlp close confirmed that WD is near-optimal; momentum
is the next unexplored HP in the same parameter group.

**Backup assignments** (if either hypothesis is already claimed or conflicts arise):
- Tanjiro backup: Hypothesis 5 (lr_scalars VALUE fine-tune) — no code changes required
- Thorfinn backup: Hypothesis 2 (ema-eval decay VALUE sweep) — no code changes required

---

## Research state update

**Current best explanation for FFS plateau**: The R5 stack is well-exploited at the scalar HP
level. The remaining gains likely live in (a) schedule shape and phase interactions (edward
#1664 POSITIVE), (b) SOAP structural axes (fern #1654, alphonse #1689 in-flight), and (c)
underexplored momentum/EMA continuous-value territory. The 6 failed/sub-σ experiments since
the last merge (#1617, #1586, +4 others) suggest the local scalar neighborhood is exhausted.

**Open uncertainties**:
1. Whether edward's per-class cooldown SHAPE result (#1664, n=1 POSITIVE) survives to n=4 and
   whether Cell D (INVERT) falsifies the mechanism or confirms it is MLP-shape-load-bearing.
2. Whether the SOAP structural axes (#1654, #1689) can shift the FFS floor rather than just
   tune within the current basin.
3. Whether there exists an interaction between mu and the cosine cooldown shape that has not
   been probed (relevant to Hypotheses 1 and 4 above).

**Stop condition for this wave**: If Hypotheses 1–5 all return FFS_ema > 2950 at n=1, escalate
to a different level of abstraction — consider warmup schedule shape, joint LR-momentum
schedule (vs. decoupled schedules), or full optimizer replacement hypothesis.
