# Per-aux-group AdamW β2 ablation — which aux group is the load-bearing piece?

## Hypothesis

Alphonse #236 single-seed sweep shows AdamW aux β2=0.99 outperforms baseline β2=0.95 (val=3.27439 vs baseline 3.27461; within-pod Δ=−0.00309). Confirmation seeds are in flight. The mechanism story is "v-EMA stability in the precision window" — variance estimate with longer memory smooths per-coordinate step sizes during cooldown.

**The natural triangulation**: alphonse #236 uses GLOBAL β2 (applied to all three aux groups — embed, lm_head, scalar). The mechanism may not be uniform across aux groups. Three competing readings:

1. **Embed-driven**: embed has the largest gradients (`||g_embed||_F ≈ 1.5e4` per #206 telemetry) and the most-clip-sensitive responses (per thorfinn #105). β2=0.99 helps most on embed → per-group β2 finds embed-only β2=0.99 captures most of the gain.
2. **lm_head-driven**: lm_head's outputs feed logits, so gradient noise on lm_head directly perturbs the per-token loss. β2=0.99 helps most on lm_head → per-group finds lm_head-only β2=0.99 captures most of the gain.
3. **Scalar-driven**: scalar (gain/bias) gradients are tiny and sparse, so eps and v-EMA stability matter most there. β2=0.99 helps most on scalar → per-group finds scalar-only captures most of the gain.
4. **All groups contribute additively**: per-group sweep gives ~similar gains from each, and the global win is approximately the sum.

This PR discriminates between these readings via per-aux-group β2. The result has direct wave-5 stacking implications:
- If one group dominates, future stacking can use group-specific β2 (e.g., embed=0.99, others=0.95) without paying the cost of changing groups where β2=0.99 may be neutral or mildly hurtful.
- If gains stack additively, the global β2=0.99 is correctly capturing all of them, and the recipe is settled.

**Why edward**: PR #206 demonstrated clean per-group dispatch infra and per-group grad-norm telemetry. This PR uses the same instrumentation pattern on AdamW per-group config.

## Background — baseline + closed mechanisms

- **Current merged baseline (frieren #176)**: val=3.27461/fs=3266.7 (n=3 mean). Recipe = Muon² + clip=10.0 + NS=12→16 cooldown boost (70% trigger).
- **Alphonse #236 (in flight, confirmation seeds running)**: global β2=0.99 wins single-seed val=3.27439 / within-pod Δ=−0.00309. n=3 confirmation expected ~18:00 UTC.
- **#227 (β1 cooldown decay)**: closed, null axis (arm-A=arm-C within ±0.0001). β1 schedule is not load-bearing on aux.
- **#188 (uniform aux LR scaling)**: closed neutral. Uniform multiplier is not the mechanism — asymmetric per-group is.
- **#189 (Muon² eps sweep)**: closed null. eps never binds on the Muon side. AdamW aux eps is a SEPARATE axis (different gradient distribution).

## AdamW aux group structure

In `records/track_3_optimization/train_gpt_simple.py` line ~666, AdamW aux groups are instantiated with `betas=(0.8, 0.95), eps=1e-10, weight_decay=0`. The aux param groups are:
- `embed`: token embedding matrix (largest gradients)
- `lm_head`: output projection (medium gradients)
- `scalar`: gains / biases (smallest gradients)

Each group has its own `param_group` entry in the AdamW optimizer's `param_groups` list. β2 is currently shared across all three. This PR makes β2 per-group.

## Experiment design

**Env vars (per-group β2)**:
- `NANOGPT_ADAMW_BETA2_EMBED` (float, default 0.95)
- `NANOGPT_ADAMW_BETA2_LMHEAD` (float, default 0.95)
- `NANOGPT_ADAMW_BETA2_SCALAR` (float, default 0.95)

The default of 0.95 reproduces baseline exactly when all three are unset. The arm config sets these env vars to 0.99 for the group(s) being tested.

**Implementation**: in the AdamW aux optimizer creation, instead of passing a single `beta2`, create three param groups (one per aux group) and set per-group `betas=(0.8, β2_group)` based on env vars. Verify implementation neutrality in arm-A (all 0.95).

**Arms (4 total, sequential single-pod)**:

| Arm | EMBED β2 | LM_HEAD β2 | SCALAR β2 | Hypothesis tested |
|---|---|---|---|---|
| A (control) | 0.95 | 0.95 | 0.95 | Baseline reproduction (verifies implementation neutrality) |
| B | **0.99** | 0.95 | 0.95 | Does embed alone capture the β2 win? |
| C | 0.95 | **0.99** | 0.95 | Does lm_head alone capture the β2 win? |
| D | 0.95 | 0.95 | **0.99** | Does scalar alone capture the β2 win? |

**Note**: arm A,B,C,D run AT THE CURRENT BASELINE β2=0.95, not at alphonse's post-confirmation winner. This makes the experiment robust to alphonse #236's outcome — even if alphonse fails to confirm, this triangulation still tells us per-group sensitivity to β2.

A natural follow-up if any group wins: stack the winners (e.g., embed+lm_head=0.99, scalar=0.95) and re-test against alphonse's global 0.99.

## Decision logic (pre-declared)

- **Arm-A drift gate**: |val_A − 3.27461| > 0.003 → too much pod drift, abort and rerun arm-A with different seed.
- **Per-arm signal**: within-pod Δ (arm_X − arm_A) ≤ −0.002 → real signal, post terminal, request 2 confirmation seeds for the winning arm.
- **All arms within noise**: post terminal with verdict "per-group β2 effect is diffuse — global β2 captures the mechanism uniformly". Important null.
- **Multiple arms beat arm-A**: rank by Δ; confirm best first. Note relative magnitudes for stacking design.

**Diagnostic interpretation guide**:
- If arm-B wins (embed): the high-magnitude gradients on embed benefit most from v-EMA smoothing. Mechanism: β2=0.99 reduces per-coord step jitter on the largest-gradient group.
- If arm-C wins (lm_head): logit-feeding gradients benefit; mechanism is about cleaner per-token loss propagation.
- If arm-D wins (scalar): the small-sample regime on scalar gradients benefits most from longer EMA memory.
- If no arm wins individually but multiple are slightly below noise: gains stack and global β2=0.99 is the right choice. Per-group asymmetric β2 has no additional headroom.

## Telemetry to log

Standard W&B telemetry plus per-group:
- `train/adamw/embed/v_hat_mean`, `train/adamw/embed/v_hat_std` — variance estimator stability per group
- `train/adamw/lmhead/v_hat_mean`, `train/adamw/lmhead/v_hat_std`
- `train/adamw/scalar/v_hat_mean`, `train/adamw/scalar/v_hat_std`
- `train/adamw/embed/step_norm`, `train/adamw/lmhead/step_norm`, `train/adamw/scalar/step_norm` — per-tensor step magnitude (`||m_hat / (sqrt(v_hat) + eps)||_F`)
- `train/adamw/embed/effective_beta2`, etc. — verify env vars are correctly plumbed

Log every 50 steps. The per-group step_norm comparison across arms is the mechanistic key — higher β2 should reduce step_norm variance during cooldown.

## Run command (example for arm-B)

```bash
NANOGPT_GRAD_CLIP=10.0 \
NANOGPT_NS_ITERS=12 NANOGPT_NS_ITERS_COOLDOWN=16 \
NANOGPT_ADAMW_BETA2_EMBED=0.99 \
NANOGPT_ADAMW_BETA2_LMHEAD=0.95 \
NANOGPT_ADAMW_BETA2_SCALAR=0.95 \
  torchrun --standalone --nproc_per_node=$(nvidia-smi -L | wc -l) \
  /tmp/pergroup_b2_runs/train_pergroup_b2.py \
  --wandb_name "g1r4-edward/pergroup-b2-arm-b-embed" \
  --wandb_group "g1r4-edward/pergroup-b2"
```

## Smoke gate (mandatory before chain)

200-step micro-run on arm-B (embed β2=0.99). Verify:
- No divergence (val_at_200 within ±0.5 of arm-A's val_at_200)
- Per-group `effective_beta2` logs the correct values (0.99 for embed, 0.95 for others)
- `train/adamw/embed/v_hat_mean` ≠ `train/adamw/lmhead/v_hat_mean` (verifies per-group state separation)

Posts as `g1r4-edward/pergroup-b2-smoke`.

## Statistical rule

Final claim: `(3.28 − μ) × √n ≥ 0.004`. For n=3 confirmation: μ ≤ 3.27769. Actual merge gate is **n=3 mean ≤ current merged baseline at time of confirmation** (3.27461 now; may shift if alphonse #236 confirms and merges first, in which case the gate becomes the new baseline). Coordinate with advisor before launching confirmation seeds.

## ETAs

Each arm ≈ 101 minutes. Sequential chain: arm-A → arm-B → arm-C → arm-D ≈ 6.7h end-to-end. Confirmation seeds (2× ≈ 3.4h additional) only if any arm triggers signal.

## Context

Edward, your PR #206 was a clean mechanism inversion finding. The per-group dispatch and grad-norm telemetry you built is the right pattern for this experiment. The mechanism story here is even cleaner than #206: alphonse #236 already provides the global win signal; this PR's job is to localize the mechanism to a specific aux group (or confirm it's diffuse).

Pod-drift: arm-A reproduces the merged baseline. The arm-A drift gate is critical — verify within ±0.003 of 3.27461 before proceeding. If alphonse #236 has merged by the time you start, rebase first; arm-A will then reproduce the new (lower) baseline and you compare per-group Δs against that.
