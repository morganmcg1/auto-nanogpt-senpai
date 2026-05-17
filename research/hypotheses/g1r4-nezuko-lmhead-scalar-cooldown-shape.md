# lm_head + scalar cooldown shape — does the embed-floor mechanism generalize across aux groups?

## Hypothesis

Tanjiro #235 arm-C (embed-only `linear_floor=15%`) shows val=3.27245/fs=3250 — a **-0.00216 improvement on the merged baseline (3.27461)** at n=1, with within-pod Δ vs control of -0.00428 (well outside seed noise). **The natural mechanism question this PR tests**: is the floor-cooldown benefit **embed-specific**, or does it **generalize to other AdamW aux groups** (lm_head, scalar)?

**Three competing readings** to discriminate:

1. **Embed is uniquely sensitive** (most-clip-affected aux group per #105 telemetry, largest gradients). Floor cooldown on lm_head/scalar produces no benefit → tanjiro's mechanism is genuinely embed-specific.
2. **All aux groups benefit from sustained mid-LR pressure during cooldown.** Floor cooldown on lm_head and scalar each produce a similar (~0.002) improvement → mechanism is "aux groups benefit from a floor during cooldown" and we can **stack the floors across groups** for compound gains.
3. **Mixed**: lm_head benefits but scalar doesn't (or vice versa). Reveals which subset of aux groups is the load-bearing piece.

If readings (2) or (3) hold, **stacked floors are the next wave-5 candidate** to merge alongside tanjiro's embed floor.

## Background — baseline + closed mechanisms

- **Current merged baseline (frieren #176)**: val=3.27461/fs=3266.7 (n=3 mean). Recipe = Muon² + clip=10.0 + NS=12→16 cooldown boost (70% trigger).
- **Tanjiro #235 (in flight, awaiting n=3 confirmation)**: embed-only linear_floor=15% during cooldown wins by -0.00216 vs baseline at n=1.
- **#204 (cooldown LR shape — global)**: global cooldown shape sweep (cosine, sqrt, quadratic, exp) was closed null. **Critically**: the global sweep applied the same shape to ALL groups simultaneously. Per-group asymmetric shape was NOT tested at #204 — that's what tanjiro #235 unlocked. This PR continues that asymmetric exploration on the OTHER aux groups.
- **#188 (uniform aux LR scaling)**: closed — uniform scaling of aux LR is neutral. So the per-group asymmetry, not the magnitude, is what matters.

## Per-aux-group LR ratios in baseline

The starter script (`records/track_3_optimization/train_gpt_simple.py` line 666) sets the AdamW aux groups with `betas=(0.8, 0.95), eps=1e-10, weight_decay=0`. The aux LR multipliers per parameter group are typically:
- embed: high (highest LR multiplier)
- lm_head: lower
- scalar: even lower

These multipliers are part of the baseline recipe. This PR does NOT change per-group LR magnitudes — only the cooldown SHAPE applied per group.

## Experiment design

Implement an env-var-controlled per-group cooldown shape selector for lm_head and scalar (the embed shape selector should already exist from tanjiro #235's PR — if it lands first, rebase onto it; if not, implement embed shape too as a no-op default for the control arm).

**Env vars**:
- `NANOGPT_EMBED_COOLDOWN_SHAPE` ∈ {"linear", "linear_floor:15", "cosine", "quadratic"} (default: "linear")
- `NANOGPT_LMHEAD_COOLDOWN_SHAPE` ∈ {"linear", "linear_floor:15", "cosine", "quadratic"} (default: "linear")
- `NANOGPT_SCALAR_COOLDOWN_SHAPE` ∈ {"linear", "linear_floor:15", "cosine", "quadratic"} (default: "linear")

The `linear_floor:15` shape means: cooldown LR ramps linearly from 1.0 → 0.15 over the cooldown phase, then holds at 0.15 through the rest of training. The 15% floor matches tanjiro's winning arm.

**Arms (4 total, sequential single-pod)**:

| Arm | EMBED | LM_HEAD | SCALAR | Hypothesis tested |
|---|---|---|---|---|
| A (control) | linear | linear | linear | Baseline reproduction on this pod — ensures n=1 control |
| B | linear | **linear_floor:15** | linear | Does lm_head benefit from floor alone? |
| C | linear | linear | **linear_floor:15** | Does scalar benefit from floor alone? |
| D | linear | **linear_floor:15** | **linear_floor:15** | Do floors stack on the non-embed aux groups? |

**Note**: arms B/C/D explicitly do NOT include embed-floor — that's tanjiro's territory and we don't want to confound. The mechanism question here is purely about non-embed aux groups.

## Decision logic (pre-declared)

- **If arm-A drift gate fails** (|val_A − 3.27461| > 0.003): pod has too much drift; abort and rerun arm-A with a different seed before proceeding. Within-pod Δ is unreliable until drift settles.
- **If arm-B beats arm-A within-pod by ≥ 0.002**: lm_head floor is real → post terminal, request n=2 confirmation seeds for arm-B.
- **If arm-C beats arm-A within-pod by ≥ 0.002**: scalar floor is real → post terminal, request n=2 confirmation seeds for arm-C.
- **If arm-D beats arm-A within-pod by ≥ 0.003**: floor stacks across lm_head + scalar → post terminal, request n=2 confirmation seeds for arm-D.
- **If no arm beats arm-A by ≥ 0.002**: mechanism is embed-specific (reading 1) → post terminal with finding and close. **Important null finding** that informs wave-5 stacking strategy.
- **If multiple arms beat arm-A**: confirm the best one first; the others are valuable supplementary data points for the per-group mechanism map.

## Statistical rule

Final claim must satisfy `(3.28 - μ) × √n ≥ 0.004`. For n=3 confirmation: μ ≤ 3.27769.

The actual merge gate is **n=3 mean ≤ 3.27461** (or whatever the baseline is at the time of confirmation — tanjiro #235 may merge first, shifting the gate down). Coordinate with the advisor before launching confirmation seeds to verify the current merge gate.

## Telemetry to log

Standard W&B telemetry plus:
- `train/cooldown/embed_lr_multiplier` (should be 1.0 → 0.0 linear for all arms in this PR, since we're not testing embed)
- `train/cooldown/lmhead_lr_multiplier` (1.0 → 0.0 linear OR 1.0 → 0.15 floor depending on arm)
- `train/cooldown/scalar_lr_multiplier` (1.0 → 0.0 linear OR 1.0 → 0.15 floor depending on arm)
- `train/cooldown/global_lr_multiplier` (the underlying global cosine cooldown, for context)
- Per-group `effective_lr` = `global_lr × group_lr_multiplier × cooldown_shape_value` so we can verify the schedule is taking effect

## Run command (example for arm-B)

```bash
NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 \
NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_EMBED_COOLDOWN_SHAPE=linear \
NANOGPT_LMHEAD_COOLDOWN_SHAPE=linear_floor:15 \
NANOGPT_SCALAR_COOLDOWN_SHAPE=linear \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/lmhead_scalar_cd_runs/train_lmhead_scalar_cd.py \
  --wandb_name "g1r4-nezuko/lmhead-scalar-cd-arm-b-lmhead-floor" \
  --wandb_group "g1r4-nezuko/lmhead-scalar-cd"
```

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h additional) only if any arm triggers a positive signal.

## Smoke gate (mandatory before chain)

200-step micro-run on arm-B settings (lm_head floor=15%). Verify no divergence, telemetry populates correctly, no implementation regression in the merged baseline path (the EMBED schedule should be untouched). Posts as `g1r4-nezuko/lmhead-scalar-cd-smoke`.
