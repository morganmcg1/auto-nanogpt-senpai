# SOAP Preconditioner Update Frequency (PRECOND_FREQ) Axis — g1r5-tanjiro

**Date:** 2026-05-28
**Student:** g1r5-tanjiro
**Prior PR closed:** #1565 (SOAP trust-gate-schedule, FFS-neutral, gate never fired at cos_sim ~0.82-0.84)

---

## Recommendation Summary (≤200 words)

Tanjiro's closing finding from #1565 is the direct motivation: SOAP↔Muon cosine similarity is geometrically stable throughout training (cos_sim ≈ 0.82–0.84), meaning the SOAP eigenspace evolves slowly. This raises a concrete question: is PRECOND_FREQ=16 (the current hardcoded default — never swept) actually optimal, or is the true optimum at a coarser cadence (32, 64) or a finer one (8)?

This is a clean parametric axis. No implementation complexity, no architecture changes, no conflict with any active experiment. The sweep {8, 16(ctrl), 32, 64, 128} samples two octaves above and below the current default with a degenerate falsifier (128, near-static curvature). If FFS improves at 32 or 64, the finding compounds directly onto Tanjiro's geometric-stability evidence. If FFS is flat across all, it closes the PRECOND_FREQ axis cleanly. Either result sharpens the research map.

**Primary metric: FFS (step at which val first crosses 3.28). Lower is better.**
Baseline: μ_4(FFS) = 2943.75, σ_4 = 12.5. Merge gate: μ_4(FFS) ≤ 2918.75.

---

## Hypothesis Title

**SOAP Preconditioner Update Frequency (PRECOND_FREQ) Axis**

---

## Mechanism

SOAP maintains a Kronecker-factor approximation of the curvature matrix by accumulating exponential moving averages of the outer-product Gram matrices (row_gg, col_gg via SOAP_BETA2=0.90 EMA). Every PRECOND_FREQ steps, it performs an eigendecomposition to refresh the projection basis (q_row, q_col). This eigendecomposition is the expensive per-step amortized cost of SOAP. The current value PRECOND_FREQ=16 was inherited from the original SOAP paper's default for tasks with rapidly changing curvature, and has never been swept in this codebase.

Tanjiro's finding in #1565 provides the direct mechanistic motivation: if SOAP and Muon agree geometrically throughout training (cos_sim ≈ 0.82–0.84 from start to finish), it implies the SOAP eigenspace itself is not rapidly rotating. In that regime, frequent re-orthoganalization (every 16 steps) may be wasteful — the curvature basis computed 32 or 64 steps ago is still approximately valid. Alternatively, very infrequent refresh (128 steps) should cause eigenspace staleness and drift, which would hurt FFS and serve as the falsifier arm. The proposed sweep tests whether the curvature structure in this specific training regime rewards less frequent but still regular basis updates. The SOAP_BETA2=0.90 EMA already smooths the Gram accumulators strongly (10% weight on new gradient each step), meaning the statistical basis changes slowly — this independently suggests that PRECOND_FREQ can likely be stretched without harm.

Note: this is structurally distinct from fern's active PR #1564 (SOAP Gram trace-norm regularization). That PR modifies the Gram accumulator update rule; this PR modifies only the eigendecomposition refresh cadence. The two mechanisms are orthogonal and non-conflicting.

---

## 5-Cell Sweep Specification

| Cell | PRECOND_FREQ | Role | Rationale |
|------|-------------|------|-----------|
| A | 16 (ctrl) | Control | Current default, never previously swept |
| B | 8 | Primary — 2× more frequent | Finer curvature tracking; tests whether current default is too coarse |
| C | 32 | 2× less frequent | Exploits stable eigenspace finding from #1565 |
| D | 64 | 4× less frequent | Stretches the refresh cadence further |
| E | 128 | Falsifier — near-static | At β2=0.90, Gram accumulator renews ~10% per step; 128-step stale basis should degrade performance |

**Gate (Directive #1262 — FFS-primary):**
- Phase 1 (n=1): Each cell is FFS-alive if FFS ≤ 2975. Any cell FFS > 2975 at n=1 → close that arm immediately.
- Phase 2 (n=4 confirmation): Only if at least one non-ctrl arm is FFS-alive at n=1. Run n=4 for the best arm + ctrl.
- Merge gate: n=4 μ_4(FFS) ≤ 2918.75 (= μ_4 − 2σ_4 = 2943.75 − 25) with σ_4 ≤ 12.5.
- Val secondary: report val loss at terminal step alongside FFS but do not use it as the decision gate.

**Expected directional prediction (for falsifiability):**
- Arms C and D (32, 64) are the primary hypothesis: FFS should be ≤ ctrl or within noise.
- Arm E (128) is the falsifier: expected FFS > ctrl (staleness hurts). If E ≈ ctrl, the entire axis is curvature-frequency-insensitive at this scale.
- Arm B (8): secondary test; if FFS < ctrl, faster eigenspace tracking is load-bearing (curvature does rotate faster than PRECOND_FREQ=16 can track).

---

## Implementation Notes

### Where to add the flag

File: `records/track_3_optimization/train_gpt_simple.py`

**Step 1: Add argparse flag** (inside `parse_args()`, after the `--ns_iter` argument, approximately line 70):

```python
parser.add_argument("--soap_precond_freq", type=int, default=16,
                    help="SOAP preconditioner eigendecomposition refresh frequency in optimizer steps. "
                         "Default 16 (original SOAP default). Lower = more frequent eigen-updates; "
                         "Higher = amortizes cost but risks stale curvature basis.")
```

**Step 2: Override the module-level global** (after line 109 where `NS_ITER = args.ns_iter` is already set):

```python
PRECOND_FREQ = args.soap_precond_freq
```

This pattern is already used for `NS_ITER`. Because `soap_update_preconditioner` has the default argument `precondition_frequency=PRECOND_FREQ`, Python binds the default at function-definition time — BUT since `PRECOND_FREQ` is reassigned at module level AFTER `parse_args()` is called at line 108, and the function definition at line 569 is parsed BEFORE line 109, the module-level reassignment does NOT automatically propagate into the default argument. This is a critical Python gotcha.

**Correct fix — pass the value explicitly at the call site (line 664):**

```python
# Line 664 — change from:
soap_update_preconditioner(p.grad, state)
# to:
soap_update_preconditioner(p.grad, state, precondition_frequency=PRECOND_FREQ)
```

Then the global reassignment `PRECOND_FREQ = args.soap_precond_freq` at line ~110 will correctly flow to every call. Alternatively, the student can pass `args.soap_precond_freq` directly to the call site, either approach is correct.

**Step 3: Update the hparams logging dict** (around line 771):
The logging code already logs `"soap_precond_freq": PRECOND_FREQ`. After the module-level reassignment, this will correctly reflect the runtime value. No change needed to the logging block.

### Critical gotcha: Python default-argument binding

Python evaluates default argument values ONCE at function definition time. The pattern `def foo(x=GLOBAL_VAR)` captures the value of `GLOBAL_VAR` at the moment the `def` executes, not the current value of the global when the function is called. Since `soap_update_preconditioner` is defined at module parse time (before `args = parse_args()` runs at line 108), the default `precondition_frequency=PRECOND_FREQ` is already bound to 16. The module-level reassignment at line 109+ does NOT retroactively change the default. The student MUST either pass the value explicitly at the call site (line 664) or rewrite the function signature to `precondition_frequency=None` with an `if precondition_frequency is None: precondition_frequency = PRECOND_FREQ` guard inside the function body.

The simplest correct implementation: **pass explicitly at call site**, since there is only one call site (line 664).

### Verify there are no other call sites

```bash
grep -n "soap_update_preconditioner" records/track_3_optimization/train_gpt_simple.py
```

Expected: exactly two hits — the function definition at ~line 569 and the call at ~line 664. If there are additional call sites (e.g. for the `soap_attn` branch), each must also pass `precondition_frequency=PRECOND_FREQ` explicitly.

---

## Reproduce Commands

**Mandatory R5 stack:** `--ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine`

Replace `<CELL>` with the cell label in `--wandb_name` and set `--soap_precond_freq` to the cell value.

```bash
# Cell A — ctrl (PRECOND_FREQ=16, default)
python records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --soap_precond_freq 16 \
  --wandb_group g1r5-tanjiro-precond-freq \
  --wandb_name "precond-freq-A-ctrl-pf16"

# Cell B — primary (PRECOND_FREQ=8, 2× more frequent)
python records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --soap_precond_freq 8 \
  --wandb_group g1r5-tanjiro-precond-freq \
  --wandb_name "precond-freq-B-primary-pf8"

# Cell C — 2× less frequent (PRECOND_FREQ=32)
python records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --soap_precond_freq 32 \
  --wandb_group g1r5-tanjiro-precond-freq \
  --wandb_name "precond-freq-C-pf32"

# Cell D — 4× less frequent (PRECOND_FREQ=64)
python records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --soap_precond_freq 64 \
  --wandb_group g1r5-tanjiro-precond-freq \
  --wandb_name "precond-freq-D-pf64"

# Cell E — falsifier (PRECOND_FREQ=128, near-static curvature)
python records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 \
  --ns_iter 6 --soap_attn --lr_mlp 0.055 --wd_schedule ramp_down \
  --lr_scalars 0.03 --depth_init_mode musoft --lr_cooldown_shape cosine \
  --soap_precond_freq 128 \
  --wandb_group g1r5-tanjiro-precond-freq \
  --wandb_name "precond-freq-E-falsifier-pf128"
```

---

## Predeclared Gates (Directive #1262 — FFS-primary)

| Gate | Condition | Action |
|------|-----------|--------|
| Phase 1 alive | n=1 FFS ≤ 2975 for any non-ctrl arm | Proceed to Phase 2 |
| Phase 1 dead | n=1 FFS > 2975 for ALL non-ctrl arms | Close axis, report FFS-neutral or FFS-NEG |
| Phase 2 confirm | n=4 μ_4(FFS) ≤ 2918.75 AND σ_4 ≤ 12.5 | Merge winner |
| Phase 2 borderline | n=4 2918.75 < μ_4(FFS) ≤ 2943.75 | Report inconclusive (within σ_4 noise band) |
| Phase 2 null | n=4 μ_4(FFS) > 2943.75 | Close FFS-neutral |
| Falsifier check | Cell E FFS >> ctrl | Expected; confirms curvature structure is not frequency-independent |
| Falsifier inversion | Cell E FFS ≤ ctrl | Unexpected; indicates axis is insensitive → close all arms |

**Val loss (secondary):** report at terminal step for all cells. No decision authority; contextual only. Baseline μ_4(val) = 3.270215.

---

## Research State Update

**Current best explanation of bottleneck:** After closing the SOAP trust-gate-schedule axis, the SOAP preconditioning mechanism's structural parameters remain under-explored. The geometric-stability finding (stable cos_sim) shifts attention from when/whether to use SOAP to how often SOAP updates its curvature model. The PRECOND_FREQ axis is the most direct parametric extension of Tanjiro's own finding.

**Ruled out (do not repeat without new evidence):**
- SOAP trust-gate based on cos_sim thresholding (gate never fires in this regime)
- NS-iter axis: iter=6 is the tight sharp optimum; iter>6 hurts; iter<6 catastrophic below 4
- LR floor / min_lr / cosine-to-zero asymptote (closed clean-NEG monotone, #1462 #1508 #642)
- Cooldown_frac axis: cdf=0.7 is locally optimal (#1481)
- Muon body structural wrappers: AGC, QHM, GC pre-NS, Lookahead, Cautious all closed (#1441 #1493 #1497 #1446 #1460)
- AdamW aux update-rule substitutions: Lion, Sophia-G, AdaBelief, AdEMAMix all closed (#1471 #1502 #1500 #1490)
- Per-group AdamW aux decoupling: FFS-cosmetic across β1/β2/ε/cooldown (#1368)
- Mu cooldown: two-sided rejection, mu=0.95 is local optimum (#1294 #1345)

**Open uncertainties blocking better decisions:**
1. Whether SOAP's eigendecomposition cadence is structurally load-bearing or merely a compute-accuracy tradeoff in this regime.
2. Whether the Muon body mu_mlp / mu_attn decoupling axis (currently assigned to edward, #1615) yields an FFS-alive signal — if it does, it opens per-group momentum sweeps as a new live cluster.
3. Whether fern's SOAP Gram trace-norm (#1564) produces an FFS signal beyond step-quantization noise — if it does, joint PRECOND_FREQ × trace-norm interaction becomes a candidate for a follow-up factorial experiment.

**Next discriminating experiment:** This PRECOND_FREQ sweep. Cheapest possible test (single int flag change, no architecture modification) that directly exploits Tanjiro's closing evidence. 5 cells at n=1 takes ~5 GPU-hours and produces a clean parametric profile across two octaves.

**Stop condition for this axis:** If all 5 cells land within ±σ_single of ctrl (FFS in [2931, 2957]) at n=1, declare PRECOND_FREQ axis FFS-insensitive and move to a qualitatively different axis (e.g., SOAP_BETA2 sweep or per-block SOAP application).
