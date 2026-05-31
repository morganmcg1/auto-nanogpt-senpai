# Body PMuon γ SHARPEN (γ→0.5) TIMING SWEEP — @ step 1100 vs 1200 (vs canonical 975 NULL)

## Hypothesis

**The joint γ pulse at cooldown onset step 975 is bilateral NULL (#1831). Alphonse #1935 tests blockwise scope @ step 975. A third untested dimension: TIMING. If the γ pulse mechanism is timing-sensitive, mid-cooldown or deeper-cooldown activation may capture headroom that step 975 misses.**

Joint γ pulse scope is confirmed closed at 975 (#1831) and at pre-target 2750 (#1680). The timing sweep at MID-COOLDOWN (step 1100 or 1200) is the last unexplored cell on the (scope=joint, direction=SHARPEN, timing=mid-cooldown) grid.

Direction held at SHARPEN (γ→0.5) — the less-bad direction in #1831 (SHARPEN +3.4 mnat, RELAX +4.2 mnat). Magnitude held at 0.5 for direct comparability with #1831 and #1935.

Mechanistic framing: At step 975 (cooldown onset), the γ change may be overwhelmed by the simultaneous LR decay and β₂ pulse (which marks exactly this boundary). At step 1100 or 1200, the LR cosine decay is more advanced, the β₂-refreshed variance estimator has stabilized, and the γ change operates on a cleaner optimization trajectory. If the timing argument is correct, the mechanism should show signal at mid-cooldown that the 975 window masks.

## Why now (complementary to #1935 alphonse)

| Experiment | Scope | Direction | Timing | Status |
|---|---|---|---|---|
| #1831 fern | JOINT (all 12 blocks) | both RELAX + SHARPEN | @ 975 | bilateral NULL |
| #1680 fern | JOINT | SHARPEN/RELAX (pre-target) | @ 2750 | bilateral NULL |
| **#1935 alphonse** | **BLOCKWISE** (deep vs shallow) | **SHARPEN** | **@ 975** | **IN FLIGHT** |
| **#THIS nezuko** | **JOINT** (all blocks) | **SHARPEN** | **@ 1100 vs 1200** | **← UNTESTED** |

Orthogonal to alphonse #1935 — scope is joint (not blockwise), timing is mid-cooldown (not 975). If both #1935 AND #THIS are NULL, γ axis is exhausted. If timing shows signal while scope doesn't (or vice versa), we get a clean separation of scope vs timing contributions.

## Alignment with directive #1252

- (e) **Schedules that steepen loss descent before step 2925** ✓ — shifting γ activation deeper into cooldown is a schedule-shape hypothesis on the loss trajectory
- (c) **Short phase-specific mechanisms** ✓ — γ pulse is a targeted one-step intervention at a specific cooldown phase boundary
- (a) **Optimizer-state at phase boundaries** ✓ — steps 1100 and 1200 are mid-cooldown sub-boundaries (LR at ~70-80% of cooldown decay)

## Two arms (bilateral timing sweep)

| Arm | Timing | γ_target | Hypothesis |
|---|---|---|---|
| **A** | **@ step 1100** | **0.5** | Mid-cooldown: LR decayed ~24% from peak; β₂-refreshed variance stabilized after 125 steps at β₂=0.99. |
| **B** | **@ step 1200** | **0.5** | Deeper cooldown: LR decayed ~44% from peak; deeper into cooldown trajectory. |

If Arm A wins, follow up with timing sweep [975, 1050, 1100, 1150].
If Arm B wins, follow up with timing sweep [1150, 1200, 1300].
If both NULL: γ timing axis exhausted; γ axis FULLY CLOSED across joint scope + timing + direction (pending #1935 blockwise).

## Implementation

The `--body_muon_gamma_pulse_step` and `--body_muon_gamma_pulse_target` flags should already be implemented from #1831. No new code required — just change the step argument.

Verify the pulse fires at the correct step: `[step 1100] body_muon_gamma_pulse: gamma X -> 0.5` should appear in logs.

**Arm A (SHARPEN @ step 1100, joint, seed 1):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --body_muon_gamma_pulse_step 1100 \
  --body_muon_gamma_pulse_target 0.5 \
  --wandb_group nezuko-body-gamma-sharpen-timing \
  --wandb_name nezuko-gamma-sharpen-step1100 \
  --seed 1
```

**Arm B (SHARPEN @ step 1200, joint, seed 1):**
```bash
uv run records/track_3_optimization/train_gpt_simple.py \
  --body_muon_gamma_pulse_step 1200 \
  --body_muon_gamma_pulse_target 0.5 \
  --wandb_group nezuko-body-gamma-sharpen-timing \
  --wandb_name nezuko-gamma-sharpen-step1200 \
  --seed 1
```

## Baseline

Current best metrics — PR #1532:
- **speedrun/final_first_step_to_target (sr):** 2875 (n=2 mean, seed-1 `9coyk2ke` 2875, seed-2 `09qrijtm` 2875)
- **val/loss_ema:** 3.262854 (n=2 mean)
- **Reproduce (baseline):** `uv run records/track_3_optimization/train_gpt_simple.py --aux_b2_pulse_step 975 --aux_b2_pulse_target 0.99 --seed 1`

**Merge gate:** `sr ≤ 2862.5 OR (sr=2875 AND val_ema < 3.262854)`

If thin-margin val_ema pass (< 0.5 mnat improvement, sr ties baseline), run seed-2 before declaring WIN.

## Suggested follow-ups

- If Arm A (@1100) wins: sweep timing ∈ {1050, 1100, 1150} and test block-stratified @1100
- If Arm B (@1200) wins: sweep timing ∈ {1200, 1300} and test block-stratified @1200
- If bilateral NULL: γ timing axis closed; γ axis fully exhausted (joint scope all timings + direction + #1935 pending blockwise)
