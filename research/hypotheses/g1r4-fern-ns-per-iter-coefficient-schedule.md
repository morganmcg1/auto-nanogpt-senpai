# Per-iter NS coefficient schedule — does varying c across the 12 NS iters beat the constant c=0.5?

## Hypothesis

Fern #203 swept the **global** NS polynomial coefficient `c` (one value applied to all 12 NS iters per step) and found c=0.5 is a clear local optimum at the merged baseline. The (a, b, c) family preserves f(1)=1, f'(1)=0 with a=1.5+c, b=−0.5−2c, c. Both directions (c<0.5 and c>0.5) regress.

**The remaining open question**: NS iter k operates on a matrix that has a DIFFERENT singular value distribution than iter k+1 (the polynomial flattens the spectrum monotonically across iters). A constant c=0.5 may be the right OPERATING POINT on average but not the right value at every iter position.

**Mechanism intuition**:
- **Early NS iters** (k=0,1,2): input matrix is the raw momentum buffer, singular values can be **far from 1** (`singular_range ~ 0.9` per #138 telemetry). An aggressive polynomial (high c, larger quintic term) compresses the spectrum toward 1 more rapidly per iter.
- **Late NS iters** (k=10,11): matrix is near-orthogonal, singular values **close to 1**. A gentle polynomial (low c, smaller quintic term) preserves the near-orthogonal state without overshoot.

A constant c=0.5 schedule **trades off** between the two regimes. A SCHEDULED c may better track the evolving spectrum dynamics, even when the average c value is held at 0.5.

**Three competing readings**:
1. **Aggressive→Gentle wins** (mechanism above): start with high c, cool down to low c. Each iter operates with c matched to the current spectrum state.
2. **Gentle→Aggressive wins** (opposite intuition): early iters apply mild compression to avoid disrupting magnitude info; late iters apply aggressive final compression. Less likely but possible if early aggressive coefficients introduce numerical noise.
3. **Schedule is null** — constant c=0.5 captures the optimal at every iter position (the polynomial is robust to spectrum state variation). Fern #203 result extends to per-iter as well.

This PR discriminates these readings while preserving the family constraint (f(1)=1, f'(1)=0 at every iter) and the total NS=12 iter count.

## Background

- **Current merged baseline (frieren #176)**: val=3.27461/fs=3266.7 (n=3 mean). NS=12 (mid) + NS=16 (cooldown).
- **Fern #203 (closed null)**: 5-arm bracket of constant c showed all non-0.5 values regress. c=0.5 is the empirical global optimum. **Per-iter schedule was NOT tested.**
- **#138 telemetry**: `singular_range` drops from ~0.95 to ~0.47 at the NS=12→16 cooldown transition. This is across STEPS, not across NS iters within a step. Within a step, NS iters monotonically flatten the spectrum.
- **#176 finding**: NS=8 mid-training is compute-neutral with NS=12 (spectrum saturates at NS=8 mid). NS=16 cooldown is load-bearing. This is mid-training spectrum behavior, separate from within-step iter evolution.

## Mathematical setup

Polynomial family: f(x) = a*x + b*x^3 + c*x^5 with constraint f(1)=1, f'(1)=0.

Single-parameter family: a = 1.5+c, b = -0.5-2c, c = c. Baseline c=0.5 gives (a, b, c) = (2.0, -1.5, 0.5).

**Per-iter NS schedule** sets c_k for each iter k ∈ {0, ..., 11}, with (a_k, b_k) derived from c_k via the same constraints. Each iter is still a valid NS step (preserves the fixed point at sigma=1).

## Experiment design

**Env var**: `NANOGPT_NS_COEF_SCHEDULE` ∈ {"constant", "aggressive_to_gentle", "gentle_to_aggressive", "linear_ramp_down"} (default: "constant", reproduces baseline at c=0.5).

**Per-iter c values per arm** (each (a_k, b_k) derived via a=1.5+c_k, b=-0.5-2c_k):

| Arm | NANOGPT_NS_COEF_SCHEDULE | c values across iters 0..11 | Average c |
|---|---|---|---|
| A (control) | constant | 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5 | 0.5 |
| B | aggressive_to_gentle | 0.7, 0.7, 0.7, 0.6, 0.6, 0.5, 0.5, 0.4, 0.4, 0.3, 0.3, 0.3 | 0.5 |
| C | gentle_to_aggressive | 0.3, 0.3, 0.3, 0.4, 0.4, 0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.7 | 0.5 |
| D | linear_ramp_down | 0.7, 0.66, 0.62, 0.58, 0.54, 0.51, 0.47, 0.43, 0.39, 0.35, 0.31, 0.28 | 0.49 |

**Critical design constraint**: every arm has **average c ≈ 0.5** so the comparison is purely about iter-position assignment, not about global c shift. This isolates the schedule axis from #203's already-tested global axis.

**Implementation** in `muon_update` (or wherever NS iters are applied):

```python
import os
NS_COEF_SCHEDULE = os.environ.get('NANOGPT_NS_COEF_SCHEDULE', 'constant')

def get_ns_coefs_at_iter(iter_idx, total_iters=12, schedule='constant'):
    if schedule == 'constant':
        c = 0.5
    elif schedule == 'aggressive_to_gentle':
        c_values = [0.7, 0.7, 0.7, 0.6, 0.6, 0.5, 0.5, 0.4, 0.4, 0.3, 0.3, 0.3]
        c = c_values[iter_idx % total_iters]
    elif schedule == 'gentle_to_aggressive':
        c_values = [0.3, 0.3, 0.3, 0.4, 0.4, 0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.7]
        c = c_values[iter_idx % total_iters]
    elif schedule == 'linear_ramp_down':
        c = 0.7 - (0.7 - 0.28) * iter_idx / (total_iters - 1)
    a = 1.5 + c
    b = -0.5 - 2 * c
    return a, b, c

# In NS loop:
for k in range(num_ns_iters):  # num_ns_iters may be 12 mid or 16 cooldown
    a, b, c = get_ns_coefs_at_iter(k, num_ns_iters, NS_COEF_SCHEDULE)
    # NS iter step using (a, b, c)
    X = a * X + b * (X @ X.T @ X) + c * (X @ X.T @ X @ X.T @ X)
```

**Schedule extension for cooldown NS=16**: when NS iter count is 16 (cooldown), the schedule needs 16 c-values not 12. Two options:
- (a) Stretch the 12-value schedule to 16 indices (linear interpolation): `c_at_iter[k] = c_at_iter_12[k * 12/16]`
- (b) Hold the last value: iters 0-11 use the 12-value schedule, iters 12-15 hold the iter-11 value

**Recommended**: option (a), linear interpolation — preserves the schedule shape across NS iter counts. Implementation:
```python
def get_ns_coefs_at_iter(iter_idx, total_iters, schedule):
    if schedule == 'constant':
        c = 0.5
    else:
        # Map iter_idx to position in 12-value schedule
        norm_idx = iter_idx * 11 / max(total_iters - 1, 1)  # 0..11
        # ... interpolate c_values[norm_idx]
```

**Arms (4 total, sequential single-pod)**:

| Arm | Schedule | Hypothesis tested |
|---|---|---|
| A (control) | constant (c=0.5 everywhere) | Baseline reproduction (verifies implementation neutrality) |
| B | aggressive_to_gentle | Spectrum-tracking hypothesis: aggressive early, gentle late |
| C | gentle_to_aggressive | Opposite-direction discriminator |
| D | linear_ramp_down | Smooth schedule discriminator |

## Decision logic (pre-declared)

- **Arm-A drift gate**: |val_A − 3.27461| > 0.003 → abort and rerun arm-A with different seed. Verify arm-A reproduces #203's arm-A v2 (val=3.27463) for cross-PR sanity.
- **Per-arm signal**: within-pod Δ (arm_X − arm_A) ≤ −0.0015 → real signal; post terminal SENPAI-RESULT, request 2 confirmation seeds.
- **All within ±0.0015**: per-iter NS coefficient schedule is null when average c is fixed. Constant c=0.5 captures everything. Important null. Close axis.
- **Schedule-direction asymmetry** (B≪A but C≫A, or vice versa): mechanism is real; the winning direction discriminates the spectrum-tracking story.

## Telemetry to log

Standard W&B telemetry plus per-NS-step (every 50 training steps):
- `train/ns/c_at_iter_0`, `train/ns/c_at_iter_5`, `train/ns/c_at_iter_11` — verify per-iter coefs match the arm's schedule
- `train/ns/avg_c_per_step` — verify average c ≈ 0.5 across the NS step
- `train/ns/singular_range_after_iter_0`, `..._after_iter_5`, `..._after_iter_11` — measure how the spectrum evolves WITHIN a single NS step. This is the key mechanism signal. If arm-B (aggressive_to_gentle) reaches `singular_range < 0.5` after iter 5 while arm-A does not, that's mechanistic evidence for the spectrum-tracking story.

The within-step singular_range trajectory is the most diagnostic telemetry for this PR.

## Run command (example for arm-B)

```bash
mkdir -p /tmp/ns_coef_sched_runs
cp records/track_3_optimization/train_gpt_simple.py /tmp/ns_coef_sched_runs/train_ns_coef_sched.py
# (Apply per-iter schedule modification to NS loop)

NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COEF_SCHEDULE=aggressive_to_gentle \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/ns_coef_sched_runs/train_ns_coef_sched.py \
  --wandb_name "g1r4-fern/ns-coef-sched-arm-b-agg2gentle" \
  --wandb_group "g1r4-fern/ns-coef-schedule"
```

## Smoke gate (mandatory before chain)

200-step micro-run on arm-B (aggressive_to_gentle). Verify:
- No divergence (val_at_200 within ±0.5 of arm-A)
- `train/ns/c_at_iter_0 == 0.7`, `train/ns/c_at_iter_11 == 0.3` (verifies per-iter coef plumbing)
- `train/ns/avg_c_per_step ≈ 0.5` (verifies average is matched to baseline)
- Within-step `singular_range_after_iter_11` is in similar range to constant c=0.5 baseline (verifies polynomial still converges to near-orthogonal)

Posts as `g1r4-fern/ns-coef-sched-smoke`.

## Statistical rule

Final claim: `(3.28 − μ) × √n ≥ 0.004`. For n=3 confirmation: μ ≤ 3.27769. Actual merge gate: n=3 mean ≤ current merged baseline (3.27461; may shift if tanjiro/alphonse confirm).

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h) only if signal triggered.

## Context

Fern, your #203 closure was excellent — the cross-baseline contrast showing NS=16-cooldown × soft-polynomial antagonism is the strongest mechanism finding to come out of the polynomial axis. This PR is the natural mathematical follow-on: you've established that constant c=0.5 is optimal across the spectrum-flattening trajectory ON AVERAGE; this asks whether varying c WITHIN that trajectory (matching iter-position to spectrum state) can extract additional headroom.

The average-c constraint isolates this from your #203 result — every arm has avg c ≈ 0.5. Whatever effect we measure is purely about iter-position assignment, not about global polynomial sharpness.

The within-step `singular_range_after_iter_k` telemetry is the diagnostic key. If aggressive_to_gentle outperforms constant by flattening the spectrum faster in the first 6 iters, the mechanism story is clean.

Pod-drift: arm-A drift gate is critical. Verify within ±0.003 of 3.27461 AND consistent with your #203 arm-A v2 (val=3.27463) for cross-PR reproducibility.
