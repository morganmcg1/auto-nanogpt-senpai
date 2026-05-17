# Embed LR floor value sweep — what is the optimal linear_floor percentage?

## Hypothesis

Tanjiro #235 confirmed that `NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor` with floor=15% beats all other embed cooldown shapes (n=3 mean val=3.27434, Δ=−0.00027 vs prior baseline). The 15% was a prior-driven choice. The win is now the **merged baseline** (val=3.27434/fs=3266.7).

**The open question**: is 15% the optimal floor? The mechanism is "embed wants sustained late-training LR pressure." This maps to a U-shaped or monotone response:
- If higher floor wins (e.g., 25%): more sustained pressure is better; the optimum is above 15%.
- If lower floor wins (e.g., 10%): the benefit comes from preventing near-zero embed updates at the very end, but too much floor causes instability or over-regularization.
- If 15% is at the optimum: the sweep confirms the current recipe and closes this axis.

The sweep brackets both directions from the merged winner in equal-ratio steps.

## Background

- **Merged baseline (post-#235)**: val=3.27434/fs=3266.7 (n=3). Recipe = Muon² + clip=10.0 + NS=12→16 cooldown + `NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor` (floor=15%).
- **#235 arm discrimination**: linear (floor=0%) and cosine (floor≈0%) are flat vs control; linear_floor=15% wins by Δ=−0.00428 within-pod; quadratic (aggressive front-loaded decay) loses by Δ=+0.00213. The floor is the load-bearing feature; the SHAPE does not matter as long as there IS a floor.
- **Mechanism**: embed group has the largest gradient magnitudes (||g_embed||_F ≈ 1.5e4 per #206 telemetry) and is most sensitive to clip (clip=10 raised embed eff-LR from 8.4%→16.9%). Sustained late-LR pressure on embed preserves responsiveness during cooldown while lm_head/scalar still cool to zero.

## Experiment design

**Env var**: `NANOGPT_EMBED_COOLDOWN_FLOOR` ∈ {0.05, 0.10, 0.15, 0.20, 0.30} (float; 0.15 reproduces baseline).

**Implementation**: Modify the embed-group LR scheduler to apply `lr_floor = base_lr * floor_frac` as a minimum during cooldown (the scheduler from #235 already supports this via the existing `linear_floor` shape; just change the floor parameter).

**Arms (4 total, sequential single-pod)**:

| Arm | NANOGPT_EMBED_COOLDOWN_FLOOR | Hypothesis tested |
|---|---|---|
| A (control) | 0.15 | Reproduces merged baseline (verifies implementation neutrality) |
| B | 0.10 | Lower floor — near-zero protection only |
| C | 0.20 | Higher floor — more sustained pressure |
| D | 0.30 | Significantly higher floor — approaching half peak LR throughout cooldown |

**Note**: arm-A = current merged baseline (floor=15%). The result is interpretable at n=1 per-arm if within-pod Δs are clear. The floor parameter is a monotone lever — a clean U-shape or monotone response is expected.

**Rationale for arm selection**: floor values below 10% are functionally similar to floor=0% (the previous closed baselines arm-A); floor values above 30% would mean the embed LR never drops below 30% of peak throughout training, which risks instability during the final convergence window. The {10%, 15%, 20%, 30%} bracket gives equal coverage of low/current/high/very-high.

## Decision logic (pre-declared)

- **Arm-A drift gate**: |val_A − 3.27434| > 0.003 → abort and rerun arm-A on fresh seed. Verify arm-A reproduces the merged baseline (post-#235) within normal seed noise (σ ≈ 0.002).
- **Per-arm signal**: within-pod Δ (arm_X − arm_A) ≤ −0.0015 → real signal; post terminal status comment and request 2 confirmation seeds.
- **All within ±0.0015**: floor=15% is at or near the local optimum; axis closed. Important confirmation.
- **Monotone pattern (e.g., C>A>B or D>C>A>B)**: report direction and identify winner; consider extending in the winning direction with a follow-up if D wins (floor > 30%?).

## Telemetry to log

Standard W&B telemetry plus:
- `train/adamw/embed/lr` — confirm embed LR floor is being enforced (should hold at `peak_lr × floor_frac` throughout the cooldown window)
- `train/adamw/embed/v_hat_mean` — variance estimator under different floor regimes
- `train/adamw/embed/step_norm` — per-tensor step magnitude (does higher floor correlate with larger embed step norms late in training?)

Log every 50 steps.

## Run command (example for arm-C)

```bash
mkdir -p /tmp/embed_floor_sweep
cp records/track_3_optimization/train_gpt_simple.py /tmp/embed_floor_sweep/train_embed_floor.py
# (Modify floor parameter in existing linear_floor scheduler; one-line change)

NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear_floor \
NANOGPT_EMBED_COOLDOWN_FLOOR=0.20 \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/embed_floor_sweep/train_embed_floor.py \
  --wandb_name "g1r4-tanjiro/embed-floor-arm-c-20pct" \
  --wandb_group "g1r4-tanjiro/embed-floor-sweep"
```

## Smoke gate (mandatory before chain)

200-step micro-run on arm-A (control, floor=0.15). Verify:
- No divergence (val_at_200 within ±0.5 of baseline arm-A)
- `train/adamw/embed/lr` holds exactly at `peak_lr × 0.15` throughout the 200 steps (confirms floor plumbing before cooldown kicks in — floor should be pre-enforced from step 0 since all steps are pre-cooldown in a 200-step smoke, unless the scheduler applies floor only during cooldown phase)
- W&B run tagged with group `g1r4-tanjiro/embed-floor-sweep`

Posts as `g1r4-tanjiro/embed-floor-smoke`.

## Statistical rule

Final claim: `(3.28 − μ) × √n ≥ 0.004`. For n=3 confirmation: μ ≤ 3.27769. **Actual merge gate: n=3 mean ≤ current merged baseline (3.27434)** — updated post-#235 merge; coordinate with advisor before launching confirmation seeds to check for any intervening merges.

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h) only if any arm triggers signal.

## Context

Tanjiro, your #235 was the cleanest wave-4 win: within-pod Δ=−0.00428, 4-arm mechanism fully bracketed (cosine/linear flat, linear_floor wins, quadratic loses), n=3 both gates pass. The linear_floor=15% is now the merged baseline.

This PR is the direct follow-on: you've established that a floor helps, now find the optimal floor value. The implementation delta from your #235 training script is minimal — just parametrize the floor fraction via `NANOGPT_EMBED_COOLDOWN_FLOOR` and sweep {0.10, 0.15, 0.20, 0.30}.

The monotone lever expectation: if higher floor is better, you'll see a clean D>C>A>B pattern; if there's a true interior optimum, you'll see a U-shape. Either outcome is wave-5 actionable.

The new merged baseline after #235 is val=3.27434/fs=3266.7. Arm-A must reproduce this (within seed noise) as your control.
