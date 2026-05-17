# NS iter schedule SHAPE during cooldown — does a graduated/ramped boost beat the step jump?

## Hypothesis

Frieren #176 won with `NS=12 mid → NS=16 step at 70%` (step jump). Frieren #234 confirmed the **trigger fraction** (0.70) is locally optimal — the timing axis is closed. But the **shape** of the NS transition has not been explored.

**Mechanism intuition**: singular_range tightening during cooldown is a gradual process — as LR cools from 1.0 → 0.0 over the last 30%, the momentum buffer's spectrum evolves continuously. A single jump at 70% applies NS=16 uniformly across the entire cooldown phase, including:
- Very early cooldown (LR ~ 0.9, large updates) where NS=14 might suffice
- Mid cooldown (LR ~ 0.5, transition regime) where NS=16 is optimal
- Very late cooldown (LR ~ 0.05, near-zero updates) where NS=20 might extract additional spectrum margin

**Three competing readings**:
1. **Step jump captures everything** (current baseline) — the precision regime is reached sharply at 70%; a single jump is sufficient.
2. **Graduated transition wins** — the spectrum evolves continuously, so a graduated NS increase tracks the LR cooldown better.
3. **Late-concentrated boost wins** — most of the precision benefit comes from very late steps; concentrate NS compute there.

This PR tests these three readings while holding **total NS-iter compute constant** across arms. The result has direct implications for wave-5 NS scheduling.

## Background

- **Current merged baseline (frieren #176)**: val=3.27461/fs=3266.7 (n=3 mean). Recipe = Muon² + clip=10.0 + `NS=12 mid + NS=16 cooldown` step jump at step 2345 (70%).
- **#234 (NS trigger fraction sweep)**: closed null. Convex U-shape with minimum at 0.70. Axis closed.
- **#176 arm-C (NS=20 cooldown)**: saturated — NS=20 buys nothing over NS=16. So NS≥16 in cooldown is the saturation regime.
- **#176 arm-D (NS=8 mid)**: compute-neutral with NS=12 mid (spectrum saturated mid-training at NS=8). So mid-training has substantial NS slack.
- **#138/#176 mechanism**: singular_range drops from ~0.95 to ~0.47 at the NS transition, confirming precision-window dominance.

## Experiment design

**Env var**: `NANOGPT_NS_COOLDOWN_SHAPE` ∈ {"step", "two_stage", "linear_ramp", "late_peak"} (default: "step", reproduces baseline).

The trigger fraction (when cooldown "begins" for NS purposes) is fixed at 0.70 per #234's finding. Within the cooldown phase, the NS iter count varies by shape.

**Implementation** (in the NS-iter scheduler, replace the binary `step_in_cooldown ? NS_COOLDOWN : NS_BASE`):

```python
def ns_iters_at(step, total_steps, ns_base, ns_cooldown, shape='step'):
    boost_start = int(0.70 * total_steps)  # step 2345
    if step < boost_start:
        return ns_base  # 12 in baseline
    # Inside cooldown phase (steps 2345 .. 3350)
    cd_progress = (step - boost_start) / (total_steps - boost_start)  # 0..1 over cooldown
    if shape == 'step':
        return ns_cooldown  # 16 — current baseline
    if shape == 'two_stage':
        return 14 if cd_progress < 0.5 else 18  # NS=14 first half of cd, NS=18 second half
    if shape == 'linear_ramp':
        return int(12 + cd_progress * 8 + 0.5)  # ramp 12 → 20 across cooldown
    if shape == 'late_peak':
        return 12 if cd_progress < 0.5 else 20  # delayed NS=20 in last 15%
```

**Compute-neutrality verification** (all arms must have approximately equal total NS-iters):

| Shape | Avg NS iters in cooldown | Total NS iters (cooldown phase) | Total NS iters (all training) |
|---|---|---|---|
| step (control) | 16.0 | 1005 × 16 = 16080 | 28140 + 16080 = 44220 |
| two_stage | (14+18)/2 = 16.0 | 16080 | 44220 |
| linear_ramp | (12+20)/2 = 16.0 | 16080 | 44220 |
| late_peak | (12+20)/2 = 16.0 | 16080 | 44220 |

Note: linear_ramp values rounded to integers will give slightly different actual NS iters at each step but the mean is 16.0 by construction. Verify exact total NS iters logged in telemetry.

**Arms (4 total, sequential single-pod)**:

| Arm | NANOGPT_NS_COOLDOWN_SHAPE | NS schedule across cooldown (steps 2345..3350) | Hypothesis tested |
|---|---|---|---|
| A (control) | step | 16 throughout cooldown | Current baseline reproduction |
| B | two_stage | 14 (steps 2345-2847), 18 (steps 2848-3350) | Graduated step (smooth direction) |
| C | linear_ramp | 12, 13, 14, ..., 20 linearly interpolated | Smooth ramp (continuous transition) |
| D | late_peak | 12 (steps 2345-2847), 20 (steps 2848-3350) | Late-concentrated boost (precision late) |

**Mechanism predictions**:
- If B beats A: graduated increase outperforms step — spectrum needs gradual NS scaling.
- If C beats A,B: continuous tracking beats both step and 2-stage — strong evidence for smooth schedule.
- If D beats A,C: precision benefit concentrates in last 15% of training, not the full cooldown.
- If all arms tie within noise: NS=16 fixed at 70% IS the local optimum — shape doesn't matter, only average compute.

## Decision logic (pre-declared)

- **Arm-A drift gate**: |val_A − 3.27461| > 0.003 → too much pod drift, abort and rerun arm-A on different seed.
- **Per-arm signal**: within-pod Δ (arm_X − arm_A) ≤ −0.0015 → real signal, post terminal SENPAI-RESULT, request 2 confirmation seeds for the winner.
- **All arms within ±0.0015 of arm-A**: shape axis is flat — post terminal with verdict "NS schedule shape is null when compute is matched; current step jump is correct". Important null.
- **Multiple arms beat arm-A**: rank by within-pod Δ, confirm best first.

**Compute-shift safety net**: due to integer rounding in linear_ramp, log `train/ns/iters_this_step` and `train/ns/cumulative_iters` every 50 steps. Cumulative arms should land within ±2% of baseline at terminal. If an arm is >5% over baseline compute, flag it (not a fair comparison).

## Telemetry to log

Standard W&B telemetry plus:
- `train/ns/iters_this_step` — NS iters used this step (verifies schedule shape is correct)
- `train/ns/cumulative_iters` — running total NS-iter count (verifies compute neutrality)
- `train/ns/singular_range_q50` — median singular range from Muon momentum SVD (verifies spectrum tightening)
- `train/ns/effective_shape` — string label of arm shape (verifies env var plumbing)

Log every 50 steps. The singular_range telemetry is the key mechanism signal — if graduated/ramped shapes maintain `singular_range < 0.5` more consistently than the step jump, that's mechanistic evidence for the graduated reading.

## Run command (example for arm-C linear_ramp)

```bash
mkdir -p /tmp/ns_shape_runs
cp records/track_3_optimization/train_gpt_simple.py /tmp/ns_shape_runs/train_ns_shape.py
# (Apply NS-iter scheduler modification above)

NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_NS_COOLDOWN_SHAPE=linear_ramp \
NANOGPT_NS_COOLDOWN_START_FRAC=0.7 \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/ns_shape_runs/train_ns_shape.py \
  --wandb_name "g1r4-frieren/ns-shape-arm-c-linramp" \
  --wandb_group "g1r4-frieren/ns-cooldown-shape"
```

## Smoke gate (mandatory before chain)

200-step micro-run on arm-C (linear_ramp). Note: at step 200, schedule still on NS=12 (pre-cooldown), so smoke verifies:
- No divergence (val_at_200 within ±0.5 of arm-A)
- `train/ns/iters_this_step == 12` for all 200 steps (pre-cooldown phase)
- `train/ns/effective_shape == "linear_ramp"` is logged
- Cumulative iters: 200 × 12 = 2400 ✓

A second smoke at step 2400 (just inside cooldown) would verify the schedule kicks in. But to save time, a single 200-step smoke + a post-hoc verification of arm-C at step 2500 inspection is acceptable.

Posts as `g1r4-frieren/ns-shape-smoke`.

## Statistical rule

Final claim: `(3.28 − μ) × √n ≥ 0.004`. For n=3 confirmation: μ ≤ 3.27769. Actual merge gate: n=3 mean ≤ current merged baseline (3.27461; may shift if tanjiro/alphonse confirm and merge first).

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h additional) only if any arm triggers signal.

## Context

Frieren, this is the natural follow-on to your #176 win and your #234 closure. You established that:
- NS-iter compute is the load-bearing piece in cooldown (#176)
- The trigger fraction is well-tuned at 0.70 (#234)

The remaining open question on the NS schedule axis: does the SHAPE of the transition matter when compute is matched? This PR closes that loop. The result will either:
- Find a graduated/ramped shape that wins (extending #176's mechanism with finer scheduling)
- Confirm the step jump is the right primitive (closes the NS schedule axis cleanly)

Either outcome is wave-5-relevant. The compute-neutrality constraint is critical — be precise in implementation. The cumulative NS-iter telemetry will let us audit fair-comparison.

Pod-drift: arm-A drift gate is critical — verify within ±0.003 of 3.27461 before proceeding.
